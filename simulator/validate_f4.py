#!/usr/bin/env python3
"""S130 F4 differential validator (charge, critical hits, the bank $53
post-calc stage, the command-phase $DB42 roll) — the S85 method.

Replays a simulator/measure_f4.py corpus through simulator/skillfx/
f4_charge.py, injecting the engine's RNG at the waypoints (the live RNG
idles between frames, KEY_LESSONS S85), each check from the board snapshot
the engine had at that point:

  crit_step   the crit roll's ONE LoadBtlC_4e33 step: RNG after the MISS
              machine's step -> RNG at $58AF
  crit_path   per passed MISS machine: roll / sure (no step) / none (flags8
              & $70 == 0, bit4 clear, or TwinHits armed) — crit_stage()
  crit_roll   the outcome vs crit_threshold() of the attacker's $DC3C row
              and the RNG1 LoadBtlC_5ed9 read (natural or injected)
  crit_atk    HL before SaveBtlC_5d73 = ATK (QuadHits ATK>>1)
  crit_dmg    crit_damage(ATK, RNG at $5966) vs $DB56 at $59C3
  crit_idle   the RNG at the crit damage == the RNG of the crit decision
              (no idle stepping during the $79/$7A message wait)
  twin_x2 / charge_x / suck_x   the $5912-$59C2 multiplies vs $DB56 at $59C3
  postcalc    battle.post_calc (F4 order 10 + $DB42 x1.5 + Beserker) from
              the handler's $DB56 at $5912 vs $DB56 at $5A6F (targets with a
              defence-level nibble — F6 — are skipped and counted)
  set_*       the setters' bytes after the handler (ChargeUP/SuckAir/Focus
              own +6, TwinHits target +3, ALLCHANGE side +3)
  massacre    Massacre/EvilSlash crit vs msg $78 (incapacitated / RNG1)
  evil_noapply  a failed EvilSlash never reaches the apply
  hj_*        HighJump take-off (no MISS step, +6 |= $0C, no apply), landing
              (+6 &= $F3, calcdef x1.5), airborne targets (state-7 'doesn't
              reach' for flags9 bit5 / MISS gate 1 block for flags7 bit7)
  followup    Focus: +6 bit6 consumed at the end of the action; the same
              actor acts again iff flags9 bit4 and a live opposing slot
  db42_roll   LoadBtlFX_5a40 / _5ba1 per party actor: $DB42 bits and the
              two RNG steps (natural and injected RNG, poked AI bases)
  p9_rot6     the phase-9 +6 rotate (ChargeUP $03->$01, SuckAir $30->$10,
              Focus $80->$40, HighJump $0C->$04)
  driver      the registered handler / default_victims from the RNG before
              the MISS step (inverse LCG of the post-step snapshot) through
              the crit stage, the core and the post-calc stage vs the
              engine's $DB56 at $5A6F (single-victim actions)

Usage: python3 simulator/validate_f4.py [corpus.json[.gz] ...] [-v]
Prints 'TOTAL n comparisons, m mismatches'; exit 1 on any mismatch.
"""
import gzip, json, os, sys
from collections import Counter
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
from simulator import battle as B
from simulator import damage as D
from simulator.skillfx import f4_charge as F

RECORDS = {r['id']: r for r in json.load(open(os.path.join(ROOT, 'extracted', 'skill_records.json')))['records']}
FAMILY = {m['id']: m['family_id'] for m in json.load(open(os.path.join(ROOT, 'extracted', 'monsters_full.json')))}
VERBOSE = '-v' in sys.argv
ARGS = [x for x in sys.argv[1:] if not x.startswith('-')]
CORPORA = ARGS or [os.path.join(ROOT, 'simulator', 'f4_events.json.gz')]

stats, fails, cover = {}, [], Counter()
idle_k = Counter()


def tally(kind, ok, detail=None):
    s = stats.setdefault(kind, [0, 0])
    s[0 if ok else 1] += 1
    if not ok:
        fails.append((kind, detail))
        if VERBOSE:
            print('FAIL', kind, detail)


def st16(e):
    return (e['rng1'] << 8) | e['rng2']


def unstep(s):
    """Inverse of GenerateRNG (5^-1 mod 2^16 = 52429)."""
    return ((s - 0x1357) * 52429) & 0xFFFF


def flags(e):
    return {'flags7': e['dcfd'], 'flags8': e['dcfe'], 'flags9': e['dcff'],
            'target_mode': (RECORDS.get(e['db8a']) or {}).get('battle_record', {}).get('fields', {}).get('target_mode', 0)}


def board(e):
    b = B.Board()
    for k in ('hp', 'maxhp', 'mp', 'maxmp', 'atk', 'dfn', 'agl', 'int', 'dd13', 'dd1b', 'dd03', 'dd0b', 'db8b', 'db42'):
        if k in e:
            setattr(b, k, list(e[k]))
    b.st = list(e['st'][:64])
    if 'res' in e:
        b.res = list(e['res'])
    b.queue = list(e['dcec'])
    b.species = list(e['dc3c'])
    b.family = [FAMILY.get(x, 0xFF) for x in b.species]
    b.link = bool(e['c86c'])
    b.db73 = e['db73']
    b.side_seal = [(b.st[0] >> 3) & 1, (b.st[1] >> 3) & 1]
    if 'db9b' in e:
        b.level = list(e['db9b'])
    return b


def load(path):
    op = gzip.open if path.endswith('.gz') else open
    with op(path, 'rt') as f:
        return json.load(f)


def battles(events):
    out = {}
    for e in events:
        out.setdefault(e['sc'], []).append(e)
    return out


def actions(evs):
    """Split a battle into per-action groups starting at each target_fetch
    (multi-hit later passes have their own target_fetch: one group per
    pass) and ending before the next target_fetch / round_start / p9."""
    groups, cur = [], None
    for i, e in enumerate(evs):
        if e['tag'] == 'target_fetch':
            cur = [i]
            groups.append(cur)
        elif e['tag'] in ('round_start', 'p9_slot', 'db42_roll1', 'db42_roll1_raw'):
            cur = None
        elif cur is not None:
            cur.append(i)
    return groups


SETTERS = {'chargeup_in': F.CHARGEUP, 'suckair_in': F.SUCKAIR, 'focus_in': F.FOCUS,
           'twinhits_in': F.TWINHITS, 'allchange_in': F.ALLCHANGE}


def check_action(evs, idx, sc):
    g = [evs[i] for i in idx]
    tags = [e['tag'] for e in g]
    tf = g[0]
    a, sk = tf['db88'], tf['db8a']
    f = flags(tf)
    w = dict(sc=sc, frame=tf['frame'], a=a, sk=hex(sk))
    # ---- airborne target / block ---------------------------------------
    t = tf['db89']
    if 0 <= t < 8 and (tf['st'][t * 8 + 6] & 0x0C) and 'highjump_in' not in tags:
        if f['flags9'] & 0x20:
            tally('hj_air_noreach', 'miss_rng' not in tags and 'apply_in' not in tags, dict(w, t=t, tags=tags))
            cover['air_noreach'] += 1
        elif (f['flags7'] & 0x80) and (tf['st'][t * 8 + 6] & 0x04) and 'miss_in' in tags:
            tally('hj_air_block', 'block' in tags and 'miss_rng' not in tags, dict(w, t=t, tags=tags))
            cover['air_block'] += 1
    # ---- MISS pass -> crit stage ----------------------------------------
    mi = next((j for j, x in enumerate(tags) if x == 'miss_rng'), None)
    if mi is not None:
        mr = g[mi]
        rest = tags[mi + 1:]
        failed = bool(rest) and rest[0] in ('miss', 'dodge', 'block')
        if not failed:
            nxt = g[mi + 1:]
            got_path = 'none'
            for x in nxt:
                if x['tag'] in ('crit_rng', 'crit_rng_raw'):
                    got_path = 'roll'; break
                if x['tag'] == 'crit_yes':
                    got_path = 'sure'; break
                if x['tag'] in ('postcalc_in', 'calcdef_in', 'act_end', 'massacre_in', 'hj_land', 'roll_in'):
                    break
            bm = board(mr)
            fm = flags(mr)
            st_before = bm.stb(a, 4)
            out, s_after = F.crit_stage(bm, a, fm, st16(mr))
            if out is True and s_after == st16(mr):
                pred_path = 'sure'
            elif out is None or out == 'twin' or (out is False and s_after == st16(mr)):
                pred_path = 'none'
            else:
                pred_path = 'roll'
            tally('crit_path', pred_path == got_path, dict(w, pred=pred_path, got=got_path, out=out))
            cover['path_' + got_path + ('_twin' if out == 'twin' else '')] += 1
            cr = next((x for x in nxt if x['tag'] == 'crit_rng'), None)
            raw = next((x for x in nxt if x['tag'] == 'crit_rng_raw'), None)
            if got_path == 'roll' and cr is not None:
                tally('crit_step', B.rng_step(st16(mr)) == st16(raw or cr), dict(w))
                bc = board(cr)                          # (poked $DC3C, if any)
                thr = F.crit_threshold(bc, a)
                ci = g.index(cr)
                got = g[ci + 1]['tag'] == 'crit_yes' if ci + 1 < len(g) else None
                pred = cr['rng1'] < thr
                tally('crit_roll', pred == got, dict(w, thr=thr, r1=cr['rng1'], got=got))
                cover['roll_%s_thr%d_%s' % ('P' if a < 4 else 'E', thr, 'crit' if got else 'no')] += 1
                if raw is None:
                    tally('crit_stage', (out is True) == got and s_after == st16(cr), dict(w))
    # ---- post-calc pieces -----------------------------------------------
    for j, e in enumerate(g):
        tg = e['tag']
        nx = next((x for x in g[j + 1:] if x['tag'] == 'db42_stage'), None)
        if tg == 'crit_atk' and nx is not None:
            bb = board(e)
            pa = F.crit_atk(bb, a, e['db8a'])
            tally('crit_atk', pa == e['HL'], dict(w, pred=pa, got=e['HL']))
            pd = F.crit_damage(e['HL'], st16(e))
            tally('crit_dmg', pd == nx['db56'], dict(w, atk=e['HL'], pred=pd, got=nx['db56']))
            cover['crit_dmg_' + ('q0' if e['HL'] < 10 else 'quad' if e['db8a'] == 0x51 else
                                 'massacre' if e['db8a'] in (0x3F, 0x40) else 'atk')] += 1
            dec = next((x for x in reversed(g[:j]) if x['tag'] in ('crit_yes', 'crit_rng', 'massacre_in')), None)
            if dec is not None:
                k = 0; s = st16(dec)
                while s != st16(e) and k < 2000:
                    s = B.rng_step(s); k += 1
                idle_k[k] += 1
                tally('crit_idle', k == 0, dict(w, k=k))
        if tg == 'twin_x2' and nx is not None:
            tally('twin_x2', ((e['db56'] << 1) & 0xFFFF) == nx['db56'], dict(w, got=nx['db56'], d=e['db56']))
            cover['twin_' + hex(e['db8a'])] += 1
        if tg in ('charge_x', 'suck_x'):
            xi = next((x for x in g[j + 1:] if x['tag'] == 'x2_in'), None)
            if xi is not None and nx is not None:
                pd, _ = F.charge_mult(xi['db56'], st16(xi))
                tally(tg, pd == nx['db56'], dict(w, d=xi['db56'], pred=pd, got=nx['db56']))
                cover[tg + '_' + hex(e['db8a'])] += 1
        if tg == 'postcalc_in':
            po = next((x for x in g[j + 1:] if x['tag'] == 'postcalc_out'), None)
            if po is None:
                continue
            t2 = e['db89']
            if 0 <= t2 < 8 and (e['st'][t2 * 8 + 9] & 0x07):
                cover['postcalc_skip_defence'] += 1
                continue
            bb = board(e)
            fe = flags(e)
            core = B.damage_core(e['db8a'], RECORDS.get(e['db8a']))
            pd, _ = B.post_calc(bb, a, t2, e['db8a'], fe, core, e['db56'], st16(e))
            tally('postcalc', pd == po['db56'], dict(w, pred=pd, got=po['db56'], d=e['db56']))
            if bb.db42[a] & 0x40:
                cover['postcalc_db42x1.5'] += 1
        if tg in SETTERS:
            pc = next((x for x in g[j + 1:] if x['tag'] in ('postcalc_in', 'act_end')), None)
            if pc is None:
                continue
            bb = board(e)
            ctx = B.ActionCtx(b=bb, a=a, sk=SETTERS[tg], log=[], t=e['db89'])
            sk2 = SETTERS[tg]
            if sk2 == F.TWINHITS:
                F.dmg_twinhits(ctx, e['db89'], 1, 0)
                slots = [e['db89']]; off = 3
            elif sk2 == F.ALLCHANGE:
                F.dmg_allchange(ctx, e['db89'], 1, 0)
                slots = [s for s in range(a & 4, (a & 4) + 3)]; off = 3
            else:
                F._self_or({F.CHARGEUP: 3, F.SUCKAIR: 0x30, F.FOCUS: 0x80}[sk2])(ctx, a, 1, 0)
                slots = [a]; off = 6
            ok = all(bb.stb(s, off) == pc['st'][s * 8 + off] for s in slots)
            tally('set_' + tg[:-3], ok, dict(w, pred=[bb.stb(s, off) for s in slots],
                                             got=[pc['st'][s * 8 + off] for s in slots]))
        if tg == 'massacre_in':
            bb = board(e)
            ctx = B.ActionCtx(b=bb, a=a, sk=e['db8a'], log=[], t=e['db89'])
            kind, _, _ = F.dmg_massacre(ctx, e['db89'], 1, st16(e))
            got = 'crit' if 'massacre_crit' in tags else 'fail' if 'evil_fail' in tags else 'dead'
            pred = 'crit' if kind == 'dmg' else ('fail' if any(x[1] == 'evilslash-fail' for x in ctx.log) else 'dead')
            tally('massacre', pred == got, dict(w, pred=pred, got=got, r1=e['rng1']))
            cover['massacre_%s_%s%s' % (hex(e['db8a']), got,
                                        '_incap' if F.incapacitated(bb, e['db89']) else '')] += 1
            if got == 'fail':
                tally('evil_noapply', 'apply_in' not in tags, dict(w, tags=tags))
        if tg == 'highjump_in':
            bb = board(e)
            if not (bb.stb(a, 6) & 0x0C):
                ae = next((x for x in g[j + 1:] if x['tag'] == 'act_end'), None)
                tally('hj_takeoff_nomiss', 'miss_rng' not in tags[:j], dict(w, tags=tags))
                if ae is not None:
                    tally('hj_takeoff_set', ae['st'][a * 8 + 6] == (bb.stb(a, 6) | 0x0C) and
                          'apply_in' not in tags, dict(w, got=ae['st'][a * 8 + 6]))
                cover['hj_takeoff_%s' % ('P' if a < 4 else 'E')] += 1
            else:
                cd = next((x for x in g[j + 1:] if x['tag'] == 'calcdef_in'), None)
                pc = next((x for x in g[j + 1:] if x['tag'] == 'postcalc_in'), None)
                if cd is not None and pc is not None:
                    bc = board(cd)
                    ctx = B.ActionCtx(b=bc, a=a, sk=0x42, log=[], t=cd['db89'])
                    bc.set_stb(a, 6, bb.stb(a, 6))
                    _, pd, _ = F.dmg_highjump_land(ctx, cd['db89'], 1, st16(cd))
                    tally('hj_land_dmg', pd == pc['db56'], dict(w, pred=pd, got=pc['db56']))
                    tally('hj_land_clear', pc['st'][a * 8 + 6] == (bb.stb(a, 6) & 0xF3), dict(w))
                    cover['hj_land_%s' % ('P' if a < 4 else 'E')] += 1


def check_resolver(evs, sc):
    """TargetSlotResolver_6379 (Massacre's bank $58 row): the slot it
    writes into $DCED+2a vs massacre_pick() from the RNG at its entry."""
    for i, e in enumerate(evs):
        if e['tag'] != 'slot_resolver':
            continue
        a = e['db88']
        if not (0 <= a < 8) or e['dcec'][2 * a] != F.MASSACRE:
            continue
        nx = next((x for x in evs[i + 1:] if x['frame'] >= e['frame'] and x['tag'] != 'slot_resolver'), None)
        if nx is None:
            continue
        pred, _ = F.massacre_pick(board(e), a, st16(e))
        got = nx['dcec'][2 * a + 1]
        tally('massacre_pick', pred == got, dict(sc=sc, frame=e['frame'], a=a, pred=pred, got=got,
                                                  r=(e['rng1'], e['rng2']), dd1b=e['dd1b']))
        cover['massacre_pick_%s_%s' % ('commit' if e['d9ec'] == 5 else 'act' if e.get('d9ec') == 7 else e.get('d9ec'),
                                       'ally' if (pred is not None and (pred & 4) == (a & 4)) else 'foe')] += 1


def check_followups(evs, sc):
    for i, e in enumerate(evs):
        if e['tag'] != 'act_end':
            continue
        a = e['db88']
        if not (e['st'][a * 8 + 6] & 0x40):
            continue
        # the skill of the action that just ended = the queue entry
        sk = e['dcec'][2 * a]
        f = flags(dict(e, db8a=sk, dcfd=0, dcfe=0, dcff=(RECORDS.get(sk) or {}).get(
            'battle_record', {}).get('fields', {}).get('flags9', 0)))
        bb = board(e)
        log = []
        bb.ext = {}
        F.followup(bb, a, sk, f, 0, log)
        pred = bb.ext.get('f4_again') == a
        fu = i + 1 < len(evs) and evs[i + 1]['tag'] == 'followup'
        again = False
        for x in evs[i + 1:]:
            if x['tag'] in ('round_start', 'p9_slot'):
                break
            if x['tag'] == 'target_fetch':
                again = x['db88'] == a
                break
        tally('followup_hook', fu, dict(sc=sc, frame=e['frame'], a=a))
        tally('followup', pred == again, dict(sc=sc, frame=e['frame'], a=a, sk=hex(sk), pred=pred, got=again))
        cover['followup_%s_%s' % (hex(sk), 'again' if again else 'spent')] += 1


def check_db42(evs, sc):
    for i, e in enumerate(evs):
        if e['tag'] != 'db42_roll1' or e['db88'] >= 3:
            continue
        a = e['db88']
        r2 = next((x for x in evs[i + 1:i + 4] if x['tag'] == 'db42_roll2'), None)
        r2raw = next((x for x in evs[i + 1:i + 4] if x['tag'] == 'db42_roll2_raw'), None)
        dn = next((x for x in evs[i + 1:i + 6] if x['tag'] == 'db42_done'), None)
        if r2 is None or dn is None:
            continue
        ab = e['ai_bases']
        bases = (ab[a], ab[8 + a], ab[16 + a], ab[24 + a])
        bb = board(e)
        s1 = F.roll_5a40(bb, a, bases, st16(e))
        tally('db42_roll', bb.db42[a] == (r2raw or r2)['db42'][a], dict(sc=sc, frame=e['frame'], a=a, which=1,
              sk=hex(e['dcec'][2 * a]), pred=bb.db42[a], got=(r2raw or r2)['db42'][a]))
        tally('db42_steps', s1 == st16(r2raw or r2), dict(sc=sc, a=a))
        b2 = board(r2)
        s2 = F.roll_5ba1(b2, a, bases, st16(r2))
        tally('db42_roll', b2.db42[a] == dn['db42'][a], dict(sc=sc, frame=e['frame'], a=a, which=2,
              sk=hex(e['dcec'][2 * a]), pred=b2.db42[a], got=dn['db42'][a]))
        tally('db42_steps', s2 == st16(dn), dict(sc=sc, a=a))
        for bit in range(8):
            if dn['db42'][a] & (1 << bit) and not (e['db42'][a] & (1 << bit)):
                cover['db42_set_bit%d' % bit] += 1
        cover['db42_class_%02x' % e['dcec'][2 * a]] += 1


def check_p9(evs, sc):
    for i, e in enumerate(evs):
        if e['tag'] != 'p9_slot' or i == 0 or evs[i - 1]['tag'].startswith('p9'):
            continue
        prev = evs[i - 1]
        tally('p9_db42_clear', e['db42'] == [0] * 8, dict(sc=sc, frame=e['frame'], got=e['db42']))
        bb = board(prev)
        B.phase9_decay(bb)
        pred = [bb.st[s * 8 + 6] for s in range(8)]
        got = [e['st'][s * 8 + 6] for s in range(8)]
        if any(prev['st'][s * 8 + 6] for s in range(8)):
            tally('p9_rot6', pred == got, dict(sc=sc, frame=e['frame'], pred=pred, got=got))
            for s in range(8):
                if prev['st'][s * 8 + 6]:
                    cover['p9_%02x' % prev['st'][s * 8 + 6]] += 1


DRIVER_SKIP = {0x50, 0x51, 0x52, 0x53, 0x57, 0x14, 0x3E}   # multi-hit / own machines


def check_driver(evs, idx, sc):
    """The registered handler end to end from the RNG before the MISS step."""
    g = [evs[i] for i in idx]
    tags = [e['tag'] for e in g]
    if 'miss_rng' not in tags or 'postcalc_out' not in tags:
        return
    mr = g[tags.index('miss_rng')]
    po = g[tags.index('postcalc_out')]
    a, sk, t = mr['db88'], mr['db8a'], mr['db89']
    if sk in DRIVER_SKIP or sk >= 0x99 and sk <= 0xA1:
        return
    f = flags(mr)
    rec = RECORDS.get(sk)
    if not rec or f['target_mode'] not in (17, 33, 65) and sk not in (0xA6,):
        return
    if 'crit_rng_raw' in tags or 'highjump_in' in tags and not (mr['st'][a * 8 + 6] & 0x0C):
        return
    if 0 <= t < 8 and (mr['st'][t * 8 + 9] & 0x07):
        return                                           # F6 defence levels
    bb = board(mr)
    log = []
    ctx = B.ActionCtx(b=bb, a=a, sk=sk, rec=rec, f=rec['battle_record']['fields'], core=B.damage_core(sk, rec),
                      t=t, qt=t, state=unstep(st16(mr)), records=RECORDS, log=log,
                      idle=lambda s, k: s, real_sk=sk)
    h = B.ACTION_HANDLERS.get(sk)
    h(ctx) if h else B.default_victims(ctx, victims=[(t, 1)])
    hit = next((x for x in log if x[1] == 'hit'), None)
    crit_pred = any(x[1] == 'crit' for x in log)
    crit_got = 'crit_yes' in tags or 'massacre_crit' in tags
    if hit is None:
        return                                           # non-damage actions: the setters' checks
    tally('driver', hit[2][1] == po['db56'] and (crit_pred == ('crit_yes' in tags)),
          dict(sc=sc, frame=mr['frame'], a=a, sk=hex(sk), pred=hit[2][1], got=po['db56'],
               crit=(crit_pred, crit_got), log=log))
    cover['driver_%s%s' % (hex(sk), '_crit' if crit_got else '')] += 1


def main():
    n_ev = 0
    for path in CORPORA:
        evs_all = load(path)
        n_ev += len(evs_all)
        for sc, evs in battles(evs_all).items():
            for idx in actions(evs):
                check_action(evs, idx, sc)
                check_driver(evs, idx, sc)
            check_followups(evs, sc)
            check_resolver(evs, sc)
            check_db42(evs, sc)
            check_p9(evs, sc)
    print(f'events {n_ev}')
    for k in sorted(stats):
        ok, bad = stats[k]
        print(f'  {k:18s} {ok:6d} ok {bad:4d} mismatch')
    print('coverage:', ', '.join(f'{k}={v}' for k, v in sorted(cover.items())))
    print('crit damage RNG idle k:', dict(idle_k))
    tot = sum(a + b for a, b in stats.values())
    bad = sum(b for a, b in stats.values())
    if fails and not VERBOSE:
        for kind, d in fails[:12]:
            print('FAIL', kind, d)
    print(f'TOTAL {tot} comparisons, {bad} mismatches')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
