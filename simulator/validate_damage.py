#!/usr/bin/env python3
"""Differential validator for simulator/damage.py (S78).

Replays every event chain captured by simulator/measure_rig.py through the
Python damage model and diffs against the engine's own $db56 / outcome at
matching waypoints.  Exact-match by construction: the model reproduces the
RNG (LCG state*5+$1357) and every integer operation.

Usage: python3 simulator/validate_damage.py <events.json>

S78 result: 698 comparisons, 0 mismatches across 13 categories (physical
roll incl. all three regimes, record rolls, side selection, ladder A /
breath ladder at res 0-3 with guard bits, Beat hit ladder + boss gate,
MegaMagic, WindBeast, Vacuum, Kamikaze both paths, Ramming, elemental
slashes, physical multipliers).
"""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import damage as D

SKILL_INFO = None

def load_records():
    global SKILL_INFO
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    d = json.load(open(os.path.join(root, 'extracted',
                       'skill_records.json')))['records']
    SKILL_INFO = {r['id']: r for r in d}

# skill id -> (rtype, ladder) for record-driven damage cores
SPELL_LADDER = {}
for ids, rt in [((0, 1, 2), 0), ((3, 4, 5), 1), ((6, 7, 8), 2),
                ((9, 10, 11), 3), ((15, 16, 17, 90, 100), 4),
                ((12, 13, 14), 5), ((217,), 25)]:
    for i in ids:
        SPELL_LADDER[i] = (rt, 'A')
for ids, rt in [((92, 93, 94, 95), 16), ((96, 97, 98, 99), 17),
                ((101,), 0), ((91,), 24)]:
    for i in ids:
        SPELL_LADDER[i] = (rt, 'BREATH')


def run(events):
    load_records()
    stats = {}
    fails = []

    def tally(kind, ok, detail=None):
        s = stats.setdefault(kind, [0, 0])
        s[0 if ok else 1] += 1
        if not ok:
            fails.append((kind, detail))

    i = 0
    n = len(events)
    while i < n:
        e = events[i]
        t = e['tag']
        if t == 'calcdef_in':
            out = next((events[j] for j in range(i + 1, min(i + 4, n))
                        if events[j]['tag'] == 'calcdef_out'
                        and events[j]['frame'] == e['frame']), None)
            if out:
                st = (e['rng1'] << 8) | e['rng2']
                pred, ns = D.calc_skill_defense(
                    e['atk'], e['dfn'], st, target_idx=e['ti'],
                    arena=bool(e['c86c']), zero_floor=False)
                rng_ok = (D.rng1(ns), D.rng2(ns)) == (out['rng1'], out['rng2'])
                tally('physical', pred == out['db56'] and rng_ok,
                      dict(sc=e['sc'], atk=e['atk'], dfn=e['dfn'],
                           rng=(e['rng1'], e['rng2']), got=out['db56'],
                           pred=pred, rng_ok=rng_ok))
        elif t == 'roll_in':
            # $db4c/4d = power min word, $db4e = range byte (bank $54 reader
            # already ran).  Validate the roll and the side selection.
            out = next((events[j] for j in range(i + 1, min(i + 4, n))
                        if events[j]['tag'] == 'roll_out'
                        and events[j]['frame'] == e['frame']), None)
            if out:
                pmin = e['db4c'] | (e['db4d'] << 8)
                prng = e['db4e']
                st = (e['rng1'] << 8) | e['rng2']
                pred, _ = D.record_roll(pmin, prng, st)
                tally('record_roll', pred == out['db56'],
                      dict(sc=e['sc'], pmin=pmin, prng=prng,
                           rng1=e['rng1'], got=out['db56'], pred=pred))
                # side selection: party caster (ai<4, bit2 clear) -> +11/+13
                r = SKILL_INFO.get(e['skill'])
                if r and not e['c86c']:
                    f = r['battle_record']['fields']
                    if e['ai'] & 4:
                        want = (f['power_enemy_min'], f['power_enemy_range'])
                    else:
                        want = (f['power_party_min'], f['power_party_range'])
                    if want != (0, 0):
                        tally('side_select', (pmin, prng) == want,
                              dict(sc=e['sc'], skill=e['skill'],
                                   got=(pmin, prng), want=want,
                                   ai=e['ai']))
                # ladder: find the final_54e7 on this frame
                fin = next((events[j] for j in range(i + 1, min(i + 6, n))
                            if events[j]['tag'] == 'final_54e7'
                            and events[j]['frame'] == e['frame']), None)
                if fin and e['skill'] in SPELL_LADDER:
                    rt, lad = SPELL_LADDER[e['skill']]
                    lev = D.res_level(e['res_t'], rt)
                    ladder = D.LADDER_A if lad == 'A' else D.LADDER_BREATH
                    predf = D.apply_ladder(out['db56'], ladder,
                                           e['st_t'], lev)
                    tally('ladder_' + lad,
                          predf == fin['db56'],
                          dict(sc=e['sc'], skill=e['skill'], rt=rt, lev=lev,
                               st=e['st_t'], roll=out['db56'],
                               got=fin['db56'], pred=predf))
        elif t == 'calcdef_out':
            # multiplier handlers: final_54ea on the same frame
            fin = next((events[j] for j in range(i + 1, min(i + 5, n))
                        if events[j]['tag'] == 'final_54ea'
                        and events[j]['frame'] == e['frame']), None)
            MULT = {58: lambda d: d, 59: D.PHYS_MULT['TwinSlash'],
                    61: D.PHYS_MULT['Beserker'],
                    85: D.PHYS_MULT['SquallHit'],
                    103: lambda d: d, 104: lambda d: d, 105: lambda d: d}
            SLASH = {68: 0, 69: 4, 70: 3, 71: 5}
            if fin and e['skill'] in SLASH:
                d = e['db56']
                if d == 0:
                    d = e['rng2'] & 1
                lev = D.res_level(e['res_t'], SLASH[e['skill']])
                pred = D.elemental_slash(d, e['st_t'], lev)
                tally('slash', pred == fin['db56'],
                      dict(sc=e['sc'], skill=e['skill'], base=d, lev=lev,
                           got=fin['db56'], pred=pred))
            elif fin and e['skill'] in MULT:
                # e['db56'] here is the pre-floor value at 61EC; apply the
                # floor (RNG2&1) then the handler multiplier
                d = e['db56']
                if d == 0:
                    d = e['rng2'] & 1
                pred = MULT[e['skill']](d)
                tally('phys_mult', pred == fin['db56'],
                      dict(sc=e['sc'], skill=e['skill'], base=d,
                           got=fin['db56'], pred=pred))
        elif t == 'megamagic_in':
            fin = next((events[j] for j in range(i + 1, min(i + 6, n))
                        if events[j]['tag'] == 'final_54e7'
                        and events[j]['frame'] == e['frame']), None)
            if fin:
                st = (e['rng1'] << 8) | e['rng2']
                lev = D.res_level(e['res_t'], 15)
                pred, _ = D.megamagic(e['mp_a'], e['lvl_a'], st,
                                      e['st_t'], lev)
                tally('megamagic', pred == fin['db56'],
                      dict(sc=e['sc'], mp=e['mp_a'], lvl=e['lvl_a'],
                           got=fin['db56'], pred=pred))
        elif t in ('windbeast_in', 'vacuum_in'):
            fin = next((events[j] for j in range(i + 1, min(i + 6, n))
                        if events[j]['tag'] == 'final_54e7'
                        and events[j]['frame'] == e['frame']), None)
            if fin:
                st = (e['rng1'] << 8) | e['rng2']
                fn = D.windbeast if t == 'windbeast_in' else D.vacuum
                pred, _ = fn(e['lvl_a'], st, enemy_side=bool(e['ai'] & 4),
                             arena=bool(e['c86c']))
                tally(t[:-3], pred == fin['db56'],
                      dict(sc=e['sc'], lvl=e['lvl_a'], got=fin['db56'],
                           pred=pred, ai=e['ai']))
        elif t == 'kamikaze_in':
            fin = next((events[j] for j in range(i + 1, min(i + 6, n))
                        if events[j]['tag'] == 'final_54e7'
                        and events[j]['frame'] == e['frame']), None)
            if fin and fin['db56']:
                pred = D.kamikaze_damage(e['hp_a'], e['hp_t'],
                                         arena=bool(e['c86c']),
                                         db73=e.get('db73', 1))
                tally('kamikaze', fin['db56'] == pred,
                      dict(sc=e['sc'], hp=e['hp_a'], got=fin['db56'],
                           pred=pred))
        elif t == 'ramming_in':
            fin = next((events[j] for j in range(i + 1, min(i + 6, n))
                        if events[j]['tag'] == 'final_54e7'
                        and events[j]['frame'] == e['frame']), None)
            if fin:
                lev = D.res_level(e['res_t'], 14)
                pred = D.apply_ladder(D.ramming_damage(e['hp_t']),
                                      D.LADDER_A, e['st_t'], lev)
                tally('ramming', pred == fin['db56'],
                      dict(sc=e['sc'], hp_t=e['hp_t'], got=fin['db56'],
                           pred=pred))
        elif t == 'beat_in':
            # outcome hook: beat_hit or beat_miss on the same frame
            outc = next((events[j] for j in range(i + 1, min(i + 6, n))
                         if events[j]['tag'] in ('beat_hit', 'beat_miss')
                         and events[j]['frame'] == e['frame']), None)
            if outc:
                st = (e['rng1'] << 8) | e['rng2']
                lev = D.res_level(e['res_t'], 8)
                if D.boss_gate_blocks(0x12, e['ti'] >= 4,
                                      e.get('db73', 1),
                                      arena=bool(e['c86c'])):
                    hit = False
                else:
                    # Beat routes through BitCheck_6749 (id < $72)
                    hit, _ = D.hit_roll(D.LADDER_HIT_STATUS, e['st_t'],
                                        lev, st)
                tally('beat', hit == (outc['tag'] == 'beat_hit'),
                      dict(sc=e['sc'], lev=lev, st=e['st_t'],
                           rng=(e['rng1'], e['rng2']),
                           got=outc['tag'], pred=hit))
        i += 1

    for k in sorted(stats):
        ok, bad = stats[k]
        print(f'{k:14s}: {ok:4d} exact, {bad:3d} mismatch')
    for k, d in fails[:14]:
        print('  FAIL', k, d)
    return sum(b for _, b in stats.values())


if __name__ == '__main__':
    ev = json.load(open(sys.argv[1]))
    sys.exit(1 if run(ev) else 0)
