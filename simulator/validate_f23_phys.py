#!/usr/bin/env python3
"""S130 F2/F3 differential validator (single-hit physical variants,
formula / HP-based specials, record-spell extras) — the S85 method.

Replays every victim of every F2/F3 action in a simulator/measure_f23_phys.py
corpus through simulator/skillfx/f23_phys.py, injecting the engine's RNG at
the waypoints (the live RNG idles between frames, KEY_LESSONS S85), each
victim from the full board snapshot the engine had at that point:

  family    LookupTargetSpecies' $DA33 vs Board.family (monsters_full) of $DC3C[t]
  miss      block/miss/dodge/pass from the RNG after the MISS machine's step
  dmg_*     the registered damage function (+ battle.post_calc) from the
            RNG at the core-entry waypoint vs $DB56 at the end of the bank
            $53 post-calc stage ($53:$5A6F) — crits (attacker +4 bit7, F4's
            stage) are counted apart, not compared
  apply     a non-zero hit is applied (HP after = HP - dmg floor 0), a zero
            one is not (no $6D56)
  driver    the REGISTERED handler (battle.ACTION_HANDLERS, tails included;
            tm-18 skills per victim) from the RNG at the MISS machine's entry
            vs the engine's damage and HP flow (target and caster); for
            flags8-bit4 skills the failed crit roll's one RNG step (F4's
            stage) is injected before the core
  tail      the state-4 caster tails (TwinSlash/Kamikaze/Ramming) vs the
            caster HP after $52:$7840/$78EA; no tail without an applied hit
  mark      Beserker's own $DB08+8a bit2 after its handler
  victims   the tm-18 sweep (from the queued target forward) per action
  sac_*     Sacrifice per target (outcome, damage) + the caster's own roll

Usage: python3 simulator/validate_f23_phys.py [events.json] [-v]
Prints 'TOTAL n comparisons, m mismatches'; exit 1 on any mismatch.
"""
import json, sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
from simulator import battle as B
from simulator import damage as D
from simulator.skillfx import f23_phys as F

RECORDS = {r['id']: r for r in json.load(open(os.path.join(ROOT, 'extracted', 'skill_records.json')))['records']}
SPECIES = {r['id']: r for r in json.load(open(os.path.join(ROOT, 'extracted', 'monsters_full.json')))}
VERBOSE = '-v' in sys.argv
ARGS = [x for x in sys.argv[1:] if not x.startswith('-')]
CORPUS = ARGS[0] if ARGS else os.path.join(ROOT, 'simulator', 'f23_phys_events.json.gz')

MINE = (set(F.DAMAGE_FN) | {F.SAC, 0x5B, 0x65, 0xD9, 0x3A} |
        set(range(0x00, 0x12)) | {0x5A, 0x64})          # + the record spells (ladder check)
ENTRY = {F.RAMMING: 'ramming_in', F.KAMIKAZE: 'kamikaze_in', F.WINDBEAST: 'windbeast_in',
         F.VACUUM: 'vacuum_in', F.MEGAMAGIC: 'megamagic_in', F.CALLEVIL: 'calcdef_in'}
NAMES = {0x37: 'StepGuard', 0x38: 'MapMagic', 0x7E: 'Whistle', 0x55: 'SquallHit', 0xDD: 'Ahhh2',
         0x3D: 'Beserker', 0xAB: 'CALLEVIL', 0x48: 'MetalCut', 0x3C: 'Ramming', 0x3E: 'Kamikaze',
         0x4F: 'MultiCut', 0x58: 'WindBeast', 0x59: 'Vacuum', 0x66: 'MegaMagic', 0x3B: 'TwinSlash',
         0x56: 'PsycheUp', 0x5B: 'RockThrow', 0x65: 'BigBang', 0xD9: 'GigaSlash', 0x14: 'Sacrifice',
         0x3A: 'Attack'}
for _s in F.SLASH_RTYPE: NAMES[_s] = 'slash'
for _s in F.FAMILY_CUT: NAMES[_s] = 'familycut'
for _s in F.BREATH_BARRIER: NAMES[_s] = 'breath'
for _s in list(range(0, 0x12)) + [0x5A, 0x64]: NAMES[_s] = 'spell'
TM18_SWEEP = {0x4F, 0x59, 0x66, 0x5B, 0x65, 0xAB} | set(F.BREATH_BARRIER)

stats, fails = {}, []
cover = {}


def tally(kind, ok, detail=None):
    s = stats.setdefault(kind, [0, 0])
    s[0 if ok else 1] += 1
    if not ok:
        fails.append((kind, detail))
        if VERBOSE:
            print('FAIL', kind, detail)


def st16(e):
    return (e['rng1'] << 8) | e['rng2']


def fam_of(species):
    sp = SPECIES.get(species)
    return sp['family_id'] if sp else 0xFF


def board(e):
    ee = dict(e)
    ee['st'] = e['st'][:64]
    b = B.Board.from_event(ee)
    b.species = list(e['dc3c'])
    b.family = [fam_of(s) for s in e['dc3c']]
    b.ext = {}
    return b


def ctx_for(b, a, sk, t, state, log):
    rec = RECORDS.get(sk)
    f = rec['battle_record']['fields'] if rec else {}
    if sk == F.MEGAMAGIC:
        # the snapshot is past the engine's act-time MP spend; the round
        # driver never spends MP, so the model takes the pre-spend MP
        b.mp[a] += f.get('mp_cost_byte', 0)
    return B.ActionCtx(b=b, a=a, sk=sk, rec=rec, f=f, core=B.damage_core(sk, rec), t=t,
                       qt=b.q_target(a), state=state, records=RECORDS, log=log,
                       idle=lambda s, _k: s, real_sk=sk)


def segments(evs):
    """Victim groups: from each target_fetch to the next target_fetch /
    actor_fetch / round_start / p9_slot."""
    out, cur = [], None
    for i, e in enumerate(evs):
        t = e['tag']
        if t in ('target_fetch', 'actor_fetch', 'round_start', 'p9_slot', 'round_end'):
            if cur:
                out.append(cur)
            cur = [i] if t == 'target_fetch' else None
        elif cur is not None:
            cur.append(i)
    if cur:
        out.append(cur)
    return out


def next_state_event(evs, i, sc):
    j = i + 1
    while j < len(evs) and evs[j]['tag'] == 'ko':
        j += 1
    return evs[j] if j < len(evs) and evs[j]['sc'] == sc else None


def check_victim(evs, seg, sc):
    g = [evs[i] for i in seg]
    tags = [e['tag'] for e in g]
    mi = next((e for e in g if e['tag'] == 'miss_in'), None)
    mr = next((e for e in g if e['tag'] == 'miss_rng'), None)
    if mi is None or mr is None:
        return None
    a, sk, t = mr['db88'], mr['db8a'], mr['db89']
    if sk not in MINE:
        return None
    name = NAMES.get(sk, hex(sk))
    rec = RECORDS.get(sk)
    f = rec['battle_record']['fields'] if rec else {}
    where = dict(sc=sc, frame=mr['frame'], a=a, t=t, sk=hex(sk))
    # ---- MISS machine --------------------------------------------------
    b = board(mr)
    outcome = next((x for x in tags if x in ('miss', 'dodge', 'block')), 'pass')
    pm = B.miss_gate(b, a, t, f.get('flags7', 0), f.get('flags8', 0), st16(mr))
    tally('miss', pm == outcome, dict(where, pred=pm, got=outcome))
    cover.setdefault(name, set()).add('side%d' % (a >> 2))
    if outcome != 'pass':
        return dict(a=a, sk=sk, t=t, applied=False)
    if sk == F.SAC:
        return dict(a=a, sk=sk, t=t, applied=False)
    # ---- core entry ----------------------------------------------------
    want = ENTRY.get(sk)
    if want is None:
        want = 'calcdef_in' if B.damage_core(sk, rec) == 'calcdef' else 'roll_in'
    ce = next((e for e in g if e['tag'] == want and e['frame'] >= mr['frame'] and e['d9ed'] == 1), None)
    pc = next((e for e in g if e['tag'] == 'postcalc_out' and ce and e['frame'] >= ce['frame']), None)
    ap = next((e for e in g if e['tag'] == 'apply_in'), None)
    if ce is None and f.get('flags8', 0) & 0x10 and 'crit_gate' in tags:
        # a CRIT ($53:$58B4): +4 bit7 set, the $52 handler never runs and
        # $53:$5941 builds the damage from ATK (then clears bit7) — F4's stage
        tally('crit_skipped', True)
        return dict(a=a, sk=sk, t=t, applied=False)
    if ce is None or pc is None:
        tally('core_entry', False, dict(where, want=want, tags=tags))
        return None
    # family lookup (LookupTargetSpecies' bank $03 answer)
    for e in g:
        if e['tag'] == 'species_fam':
            tally('family', e['da33'] == fam_of(e['dc3c'][e['db89']]),
                  dict(where, species=e['dc3c'][e['db89']], got=e['da33'], pred=fam_of(e['dc3c'][e['db89']])))
    b = board(ce)
    ctx = ctx_for(b, a, sk, t, st16(ce), [])
    fn = F.DAMAGE_FN.get(sk, B.core_damage)
    if sk == 0 and ce.get('db86', 0xFF) != 0:
        # PATCHED-BUILD ARTIFACT (u22): FarSkillFork ($72) dispatches a $DB8A==0
        # cast to the handler of skill [$DB86] (the S45 alias stash) — but $DB86
        # is wJoinability+1 (enemy 2's joinability tier), so a Blaze cast in a
        # 2-3 enemy battle runs THAT id's handler with Blaze's record power.
        if 'db86' not in ce:
            tally('blaze_unknown_db86', True)
            return None
        alias = ce['db86']
        b.elem_override = {0: D.SPELL_LADDER[alias]} if alias in D.SPELL_LADDER else {}
        name = 'blaze_db86_alias'
        cover.setdefault(name, set()).add('db86=%d' % alias)
    kind, dmg, _ = fn(ctx, t, 1, st16(ce))
    dmg, _ = B.post_calc(b, a, t, sk, f, ctx.core, dmg, 0)
    crit = False
    lv = None
    if sk in F.SLASH_RTYPE:
        lv = D.res_level(bytes(ce['res'][t*7:t*7+7]), F.SLASH_RTYPE[sk])
    elif sk in D.SPELL_LADDER:
        lv = D.res_level(bytes(ce['res'][t*7:t*7+7]), D.SPELL_LADDER[sk][0])
    elif sk in (F.RAMMING, F.KAMIKAZE):
        lv = D.res_level(bytes(ce['res'][t*7:t*7+7]), 14)
    elif sk in (F.MULTICUT, F.WINDBEAST, F.VACUUM):
        lv = D.res_level(bytes(ce['res'][t*7:t*7+7]), 3)
    elif sk == F.MEGAMAGIC:
        lv = D.res_level(bytes(ce['res'][t*7:t*7+7]), 15)
    if lv is not None:
        cover[name].add('res%d' % lv)
    row = ce['st'][t*8+5] & 0xC0
    if row:
        cover[name].add('row%02x' % row)
    if sk in F.BREATH_BARRIER and ce['st'][t*8+4] & 4:
        cover[name].add('barrier')
    if sk in F.FAMILY_CUT:
        cover[name].add('match' if b.family[t] == F.FAMILY_CUT[sk] else 'nomatch')
    if sk == 0x48:
        cover[name].add('metal' if b.db8b[t] & 1 else 'nonmetal')
    if sk == F.MULTICUT:
        cover[name].add('zombie' if b.family[t] == 7 else 'nonzombie')
    if sk in (F.KAMIKAZE, F.SAC):
        cover[name].add('db73=%d' % ce['db73'])
    if t < 7 and ce['st'][(t + 1) * 8] & 0x04 and not (ce['st'][(t + 1) * 8 + 1] & 7):
        cover[name].add('vs-beserker')
    if crit:
        tally('crit_skipped', True)
    else:
        tally('dmg_' + name, dmg == pc['db56'], dict(where, pred=dmg, got=pc['db56'],
                                                    rng=(ce['rng1'], ce['rng2']), lv=lv, row=row))
    got = pc['db56']
    # ---- apply ---------------------------------------------------------
    tally('apply', (got > 0) == (ap is not None), dict(where, dmg=got, applied=ap is not None))
    if ap is not None:
        nx = next_state_event(evs, evs.index(ap), sc)
        if nx is not None:
            tally('hp', nx['hp'][t] == max(ap['hp'][t] - got, 0),
                  dict(where, before=ap['hp'][t], dmg=got, got=nx['hp'][t]))
    if got == 0:
        cover[name].add('zero')
    # ---- Beserker / CALLEVIL marks on the caster's guard record ----------
    if sk == F.BESERKER and a < 7:
        tally('mark', bool(pc['st'][(a + 1) * 8] & 0x04), dict(where, byte=pc['st'][(a + 1) * 8]))
    if sk == F.CALLEVIL and a < 7:
        tally('mark', bool(pc['st'][(a + 1) * 8] & 0x01), dict(where, byte=pc['st'][(a + 1) * 8]))
    # ---- tails ---------------------------------------------------------
    tail_ev = [e for e in g if e['tag'] in ('twin_tail', 'kami_tail', 'ram_tail')]
    if sk in F.TAILS or sk == 0x56:
        nxa = next_state_event(evs, evs.index(ap), sc) if ap is not None else None
        tko = ap is not None and (any(e['tag'] == 'ko' for e in g) or (nxa is not None and nxa['hp'][t] == 0))
        has_tail = sk in F.TAILS and ap is not None and not tko
        tally('tail_runs', bool(tail_ev) == has_tail, dict(where, applied=ap is not None, tails=len(tail_ev)))
        if tail_ev and sk in F.TAILS:
            te = tail_ev[0]
            to = next((e for e in g if e['tag'] == 'tail_out' and e['frame'] >= te['frame']), None)
            bt = board(te)
            r, ko = F.TAILS[sk](bt, a, te['db56'])
            if to is not None:
                tally('tail_hp', to['hp'][a] == bt.hp[a], dict(where, before=te['hp'][a], dmg=te['db56'],
                                                            got=to['hp'][a], pred=bt.hp[a]))
                cover[name].add('tail-ko' if ko else 'tail')
    # ---- the registered handler, end to end from the MISS machine entry -
    if not crit and B.rng_step(st16(mi)) == st16(mr) and ap is not None and name != 'blaze_db86_alias':
        bd = board(mi)
        log = []
        cx = ctx_for(bd, a, sk, t, st16(mi), log)
        crit_step = f.get('flags8', 0) & 0x10 and not (bd.db42[a] & 1) and not (bd.stb(a, 3) & 8)
        fn0 = F.DAMAGE_FN.get(sk, B.core_damage)
        if crit_step and B.CRIT_STAGE is not None:
            # S130 F4: default_victims now runs the crit stage itself
            # (skillfx/f4_charge.crit_stage) — no injected step
            B.default_victims(cx, fn0, victims=[(t, 1)])
        elif crit_step:
            # the (failed) crit roll's ONE RNG step sits between the MISS
            # machine and the core (489/489) — F4's stage, injected here
            # (no flags8-bit4 skill has a caster tail)
            B.default_victims(cx, lambda c, v, d, st: fn0(c, v, d, B.rng_step(st)), victims=[(t, 1)])
        elif f.get('target_mode') == 18:
            B.default_victims(cx, fn0, victims=[(t, 1)])
        else:
            h = B.ACTION_HANDLERS.get(sk)
            h(cx) if h else B.default_victims(cx)
        hit = next((x for x in log if x[1] == 'hit'), None)
        tally('driver', hit is not None and hit[2][1] == got, dict(where, log=log, got=got))
        last = next((e for e in reversed(g)), None)
        nx = next_state_event(evs, evs.index(last), sc) if last else None
        if nx is not None and bd.valid(t) == (nx['dd1b'][t] == 0):
            tally('driver_hp', nx['hp'][t] == bd.hp[t] and nx['hp'][a] == bd.hp[a],
                  dict(where, got=(nx['hp'][t], nx['hp'][a]), pred=(bd.hp[t], bd.hp[a]), log=log))
    return dict(a=a, sk=sk, t=t, applied=ap is not None)


def check_sacrifice(evs, sc):
    """Per Sacrifice action: the sweep targets, each target's resolution,
    the caster's own roll."""
    i = 0
    while i < len(evs):
        e = evs[i]
        if e['tag'] == 'sacr_in':
            a = e['db88']
            ins = []
            j = i
            while j < len(evs) and evs[j]['tag'] not in ('actor_fetch', 'round_start', 'p9_slot'):
                if evs[j]['tag'] == 'sacr_in':
                    ins.append(j)
                j += 1
            seg = evs[i:j]
            # sweep: from the first resolved target to the end of its side
            t0 = e['db89']
            pred_v = [s for s in range(t0, (t0 & 4) + 3)]
            got_v = [evs[k]['db89'] for k in ins]
            bd0 = board(e)
            tally('sac_victims', got_v == [s for s in pred_v if bd0.valid(s) and not bd0.stb(s, 7) & 0xC0],
                  dict(sc=sc, pred=pred_v, got=got_v))
            for k in ins:
                se = evs[k]
                t = se['db89']
                b = board(se)
                out, dmg, _ = F.sacrifice_target(b, t, st16(se))
                nxt = evs[k + 1:j]
                cut = next((n for n, x in enumerate(nxt) if x['tag'] in ('sacr_in', 'sacr_self')), len(nxt))
                nxt = nxt[:cut]
                roll = next((x for x in nxt if x['tag'] == 'sacrifice_roll'), None)
                appl = next((x for x in nxt if x['tag'] == 'sacr_apply'), None)
                passed = out in ('kill', 'survive')
                cover.setdefault('Sacrifice', set()).update({out, 'db73=%d' % se['db73'],
                                                            'res%d' % D.res_level(bytes(se['res'][t*7:t*7+7]), 14),
                                                            'side%d' % (a >> 2)})
                tally('sac_gate', passed == (roll is not None), dict(sc=sc, t=t, out=out, db73=se['db73']))
                if appl is not None:
                    tally('sac_dmg', appl['db56'] == dmg, dict(sc=sc, t=t, out=out, pred=dmg, got=appl['db56'],
                                                             hp=se['hp'][t], rng=(se['rng1'], se['rng2'])))
                    nx = next_state_event(evs, evs.index(appl), sc)
                    if nx is not None:
                        tally('hp', nx['hp'][t] == max(appl['hp'][t] - appl['db56'], 0),
                              dict(sc=sc, t=t, got=nx['hp'][t]))
                elif passed:
                    tally('sac_dmg', False, dict(sc=sc, t=t, out=out, why='no apply'))
            ss = next((x for x in seg if x['tag'] == 'sacr_self'), None)
            sa = next((x for x in seg if x['tag'] == 'sacr_self_apply'), None)
            if ss is not None:
                b = board(ss)
                out, dmg, _ = F.sacrifice_self(b, a, st16(ss))
                cover['Sacrifice'].add('self-' + out)
                tally('sac_self', sa is not None and sa['db56'] == dmg,
                      dict(sc=sc, a=a, out=out, pred=dmg, got=sa and sa['db56'], hp=ss['hp'][a]))
                if sa is not None:
                    nx = next_state_event(evs, evs.index(sa), sc)
                    if nx is not None:
                        tally('hp', nx['hp'][a] == max(sa['hp'][a] - sa['db56'], 0),
                              dict(sc=sc, a=a, got=nx['hp'][a]))
            i = j
            continue
        i += 1


def check_sweeps(evs, sc):
    """tm-18 victim order: from the queued target (re-resolved / redirected
    first victim) forward to the end of its side, live slots only."""
    groups, cur = [], None
    for e in evs:
        if e['tag'] in ('actor_fetch', 'round_start', 'p9_slot'):
            if cur:
                groups.append(cur)
            cur = [e]
        elif cur is not None:
            cur.append(e)
    if cur:
        groups.append(cur)
    for gi, g in enumerate(groups):
        mis = [e for e in g if e['tag'] == 'miss_in']
        if mis and mis[0]['db8a'] == 0x82:
            # UltraDown: hit ladder + state-3 stat change, no HP damage part
            tally('ultradown_nodmg', not any(e['tag'] == 'apply_in' for e in g), dict(sc=sc))
        if mis and mis[0]['db8a'] == F.MEGAMAGIC:
            a = mis[0]['db88']
            nxt = groups[gi + 1][0] if gi + 1 < len(groups) and groups[gi + 1] else None
            if nxt is not None:
                tally('megamagic_mp0', nxt['mp'][a] == 0, dict(sc=sc, a=a, mp=nxt['mp'][a]))
        if not mis or mis[0]['db8a'] not in TM18_SWEEP:
            continue
        b = board(mis[0])
        pred = B.side_victims(b, mis[0]['db89'], mis[0]['db89'])
        got = [e['db89'] for e in mis]
        tally('victims', got == pred, dict(sc=sc, sk=hex(mis[0]['db8a']), pred=pred, got=got))


def check_species_flags(evs, sc):
    """$DB8B bit0 (metal) / bit4 (flying) at the first event vs the species
    facts pacing.make_board uses (monsters_full is_metal / can_fly)."""
    e = evs[0]
    for s in range(8):
        if e['dd1b'][s] != 0 or e['dc3c'][s] not in SPECIES or s in e.get('rig_db8b', ()):
            continue
        sp = SPECIES[e['dc3c'][s]]
        want = (0x01 if sp.get('is_metal') else 0) | (0x10 if sp.get('can_fly') else 0)
        tally('db8b_species', e['db8b'][s] & 0x11 == want, dict(sc=sc, s=s, species=e['dc3c'][s],
                                                              got=e['db8b'][s], want=want))


def run(events):
    by = {}
    for e in events:
        by.setdefault(e['sc'], []).append(e)
    for sc, evs in by.items():
        check_species_flags(evs, sc)
        for seg in segments(evs):
            check_victim(evs, seg, sc)
        check_sacrifice(evs, sc)
        check_sweeps(evs, sc)


if __name__ == '__main__':
    import gzip
    events = json.load(gzip.open(CORPUS, 'rt') if CORPUS.endswith('.gz') else open(CORPUS))
    run(events)
    total = sum(v[0] + v[1] for v in stats.values())
    bad = sum(v[1] for v in stats.values())
    for k, (ok, no) in sorted(stats.items()):
        print(f'{k:20s} ok={ok:5d} fail={no}')
    if '-c' in sys.argv or VERBOSE:
        for k in sorted(cover):
            print(f'  cover {k:10s} {sorted(cover[k])}')
    print(f'TOTAL {total} comparisons, {bad} mismatches')
    if not VERBOSE:
        for f in fails[:25]:
            print('  ', f)
    sys.exit(1 if bad else 0)
