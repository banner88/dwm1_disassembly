#!/usr/bin/env python3
"""S130 F5 differential validator — healing / revive / cures / MP economy.

Replays every F5 action of simulator/f5_events.json (captured by
simulator/measure_f5.py on the user's save) through simulator/skillfx/
f5_heal.py with the ENGINE's RNG injected at each waypoint (the S85
method — the live RNG idles between frames, KEY_LESSONS S85), from the
engine's own pre-action board, and diffs:

  veto       act-time MP veto (incl. the LifeSong 2nd-turn waiver)
  mp_spend   caster MP after LoadBtlC_4a04 (at the first target fetch)
  target     act target (queue byte / re-resolve via the bank $58 row /
             dead redirect) vs $DB89 at the first target fetch
  victims    the victim sequence (target_mode 34 sweep, single target)
  miss       MISS machine per victim (spells pass)
  outcome    per-victim handler outcome (heal / fail / revive / cure /
             drain / miss / chain ...) vs the waypoints the engine hit
  amount     $DB56 (heal amount, drain amount) at the engine's apply
  board      the whole post-action board (HP, MP, $DD1B, $DD13, the
             64-byte status area) at the next actor fetch / phase 9
  revive_rearm   a revived slot is in the NEXT round's order ($DB79)
  chain_*    the state-4 chain walk, caster roll, MP := 0

Usage: python3 simulator/validate_f5.py [simulator/f5_events.json] [-v]
"""
import copy
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import battle as B
from simulator.skillfx import f5_heal as F
from simulator.validate_battle import (split_battles, split_rounds, group_actions,
                                       victim_groups, st16)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECORDS = {r['id']: r for r in json.load(open(os.path.join(ROOT, 'extracted', 'skill_records.json')))['records']}
F5_IDS = set(F.ROWS)
VERBOSE = '-v' in sys.argv
stats, fails = {}, []


def tally(kind, ok, detail=None):
    s = stats.setdefault(kind, [0, 0])
    s[0 if ok else 1] += 1
    if not ok:
        fails.append((kind, detail))
        if VERBOSE:
            print('FAIL', kind, detail)


def fields(sk):
    r = RECORDS.get(sk)
    return r['battle_record']['fields'] if r else {}


def board_cmp(b, e, where, after_p9=False):
    """Whole-board diff against an engine event (after_p9: the event is a
    phase-9 slot read = after the sub-0 decay)."""
    m = copy.deepcopy(b)
    if after_p9:
        B.phase9_decay(m)
    for k in ('hp', 'mp', 'dd1b', 'dd13'):
        tally('board_' + k, getattr(m, k) == list(e[k]),
              dict(w=where, got=e[k], pred=getattr(m, k)))
    tally('board_st', m.st == list(e['st']), dict(w=where, got=e['st'], pred=m.st))


def nxt_tag(g, tag, start=0):
    for i in range(start, len(g)):
        if g[i]['tag'] == tag:
            return i, g[i]
    return None, None


INV5 = 52429                       # 5 * 52429 == 1 (mod 2^16)


def rng_unstep(state):
    return ((state - 0x1357) * INV5) & 0xFFFF


def driver_replay(b, a, g, after, where):
    """The DRIVER path: battle.ACTION_HANDLERS[sk] (f5_heal.sweep /
    next_victim / the chain tails) run from the engine's pre-action board,
    its act target, and a scripted idle that hands the handler the
    engine's RNG at each MISS machine and at the chain-caster roll; the
    post-action board must equal the engine's (same `after` event)."""
    tags = [e['tag'] for e in g]
    _, tf = nxt_tag(g, 'target_fetch')
    sk = b.q_skill(a)
    if tf is None or tf['dcec'][a * 2] != sk:
        return
    f = fields(sk)
    if B.act_mp_veto(b, a, sk, f.get('mp_cost_byte', 0), f.get('flags7', 0)) is not None:
        return
    B.act_mp_spend(b, a, sk, f.get('mp_cost_byte', 0), f.get('flags7', 0))
    re_ = next((e for e in g if e['tag'].startswith('row_') and e['db88'] == a), None)
    t, _ = F.act_target(b, a, sk, b.q_target(a), f, st16(re_) if re_ else st16(tf))
    script = {'pre_miss': [rng_unstep(st16(e)) for e in g if e['tag'] == 'miss_rng'],
              'chain': [st16(e) for e in g if e['tag'] == 'chain_caster']}

    def idle(state, cls):
        if cls == 'pre_miss' and script['pre_miss']:
            return script['pre_miss'].pop(0)
        if cls == 'pre_target' and script['chain'] and not script['pre_miss']:
            return script['chain'].pop(0)
        return state
    log = []
    ctx = B.ActionCtx(b=b, a=a, sk=sk, rec=RECORDS.get(sk), f=f, core=B.damage_core(sk, RECORDS.get(sk)),
                      t=t, qt=b.q_target(a), state=0, records=RECORDS, log=log, idle=idle, real_sk=sk)
    B.ACTION_HANDLERS[sk](ctx)
    b.dd13[a] = 3
    if after is not None:
        m = copy.deepcopy(b)
        if after['tag'] == 'p9_slot':
            B.phase9_decay(m)
        ok = all(getattr(m, k) == list(after[k]) for k in ('hp', 'mp', 'dd1b', 'dd13')) and m.st == list(after['st'])
        tally('driver', ok, dict(w=where, a=a, sk=hex(sk), log=log,
                                 got=dict(hp=after['hp'], mp=after['mp'], dd1b=after['dd1b']),
                                 pred=dict(hp=m.hp, mp=m.mp, dd1b=m.dd1b)))


def validate_action(b, a, g, after, where):
    """One F5 actor group g (events from actor_fetch to the next actor);
    `after` = the first event after the group (next actor_fetch / p9 /
    round_start) or None."""
    tags = [e['tag'] for e in g]
    _, sl = nxt_tag(g, 'skill_load')
    _, tf0 = nxt_tag(g, 'target_fetch')
    sk = b.q_skill(a)
    redecided = False
    if tf0 is not None and tf0['dcec'][a * 2] != sk:
        # $DD0B==2 act-time RE-DECIDE ($53:SetupSub_4692 -> state $18): the
        # AI re-commits (skill + its bank $58 row target) before the act
        redecided = True
        sk = tf0['dcec'][a * 2]
        b.queue[a * 2] = sk
        b.queue[a * 2 + 1] = tf0['dcec'][a * 2 + 1]
        if sk not in F5_IDS:
            tally('redecide_away', True)
            return
    f = fields(sk)
    # ---- veto + MP spend --------------------------------------------------
    veto = B.act_mp_veto(b, a, sk, f.get('mp_cost_byte', 0), f.get('flags7', 0))
    acted = 'target_fetch' in tags
    tally('veto', (veto is None) == acted, dict(w=where, a=a, sk=hex(sk), veto=veto, mp=b.mp[a]))
    if veto not in (None, 'mp', 0x1F):
        B.act_mp_spend(b, a, sk, f.get('mp_cost_byte', 0), f.get('flags7', 0))
    if not acted:
        b.dd13[a] = 3
        return
    B.act_mp_spend(b, a, sk, f.get('mp_cost_byte', 0), f.get('flags7', 0))
    ti, tf = nxt_tag(g, 'target_fetch')
    tally('mp_spend', tf['mp'][a] == b.mp[a], dict(w=where, a=a, sk=hex(sk), got=tf['mp'][a], pred=b.mp[a]))
    b.mp[a] = tf['mp'][a]
    # ---- act target -------------------------------------------------------
    qt = b.q_target(a)
    rr = 'reresolve' in tags
    # the row runs inside the target fetch ($520C sees $FF): RNG at its entry
    # RNG for the bank $58 row: at the row's own entry when it was hooked
    # (re-decide commit / $FF fetch / re-resolve), else at the fetch
    re_ = next((e for e in g if e['tag'].startswith('row_') and e['db88'] == a), None)
    rst = st16(re_) if re_ is not None else st16(tf)
    if redecided:
        pt, _ = F.ROWS[sk](b, a, rst)
        tally('redecide_f5', True)
    else:
        pt, _ = F.act_target(b, a, sk, qt, f, rst)
    _, mi = nxt_tag(g, 'miss_in')
    got_t = mi['db89'] if (tf['db89'] == 0xFF and mi is not None) else tf['db89']
    tally('target', pt == got_t,
          dict(w=where, a=a, sk=hex(sk), qt=qt, dd0b=b.dd0b[a], pred=pt, got=got_t,
               hp=b.hp[(a & 4):(a & 4) + 3], dd1b=b.dd1b[(a & 4):(a & 4) + 3]))
    t = got_t
    b.queue[a * 2 + 1] = t
    vgs = victim_groups(g)

    def victim_of(vg):
        # the $520C hook fires BEFORE the fetch loads wBattleTargetIdx (the
        # $714C walk and the group loop stage the queue byte): read the
        # victim at the MISS machine
        m = next((e for e in vg if e['tag'] in ('miss_in', 'miss_rng')), None)
        return m['db89'] if m is not None else (vg[0]['db89'] if vg[0]['db89'] != 0xFF else got_t)
    got_v = [victim_of(vg) for vg in vgs]
    pred_v, n = [t], 1
    # ---- per victim ---------------------------------------------------------
    eff_sk = 0x2F if sk == 0xA3 else sk
    for vg in vgs:
        v = victim_of(vg)
        cur = v
        vt = [e['tag'] for e in vg]
        _, mr = nxt_tag(vg, 'miss_rng')
        outcome = next((x for x in vt if x in ('miss', 'dodge', 'block')), 'pass')
        if mr:
            pm = B.miss_gate(b, a, v, f.get('flags7', 0), f.get('flags8', 0), st16(mr))
            tally('miss', pm == outcome, dict(w=where, a=a, v=v, pred=pm, got=outcome))
        _, ap = nxt_tag(vg, 'apply_in')
        if outcome != 'pass':
            nxt, n = F.next_victim(b, sk, f, cur, n)
            if nxt is not None:
                pred_v.append(nxt)
            continue
        if sk in F.HEAL_HANDLER:
            _, ri = nxt_tag(vg, 'roll_in')
            _, hi = nxt_tag(vg, 'heal_in')
            st = st16(ri) if ri else (st16(hi) if hi else 0)
            o, amt, _ = F.skill_heal(b, a, v, eff_sk, f, st)
            got_o = 'heal' if 'heal_607d' in vt else 'fail'
            tally('outcome_heal', o == got_o, dict(w=where, a=a, v=v, sk=hex(sk), pred=o, got=got_o))
            if o == 'heal' and ap:
                tally('amount_heal', ap['db56'] == amt, dict(w=where, a=a, v=v, sk=hex(sk), pred=amt, got=ap['db56']))
                tally('hp_heal', ap['hp'][v] == b.hp[v], dict(w=where, v=v, pred=b.hp[v], got=ap['hp'][v]))
        elif sk == F.MEDITATE:
            o, _ = F.skill_meditate(b, a)
            tally('outcome_meditate', ('meditate_in' in vt), dict(w=where, a=a, pred=o))
        elif sk in F.REVIVE_IDS:
            _, vi = nxt_tag(vg, 'vivify_in')
            o, rt, _ = F.skill_vivify(b, a, v, sk, st16(vi) if vi else 0)
            if rt is not None:
                cur = rt
            tally('outcome_vivify', vi is not None, dict(w=where, a=a, v=v, tags=vt))
            if ap:
                tally('hp_vivify', rt is None or ap['hp'][rt] == b.hp[rt],
                      dict(w=where, v=rt, o=o, pred=None if rt is None else b.hp[rt],
                           got=None if rt is None else ap['hp'][rt]))
            tally('vivify_' + o, True)
        elif sk in F.CURES:
            o = F.skill_cure(b, v, sk)
            tally('cure_' + o, 'cure_in' in vt, dict(w=where, v=v, tags=vt))
        elif sk in F.DRAIN_IDS:
            _, dr = nxt_tag(vg, 'mpdrain_roll')
            o, amt, _ = F.mp_drain(b, a, v, sk, st16(dr) if dr else 0)
            got_o = ('drain' if 'mpdrain_amt' in vt else 'miss' if dr else 'fail')
            tally('outcome_drain', o == got_o, dict(w=where, a=a, v=v, sk=hex(sk), pred=o, got=got_o,
                                                     rng=(dr['rng1'], dr['rng2']) if dr else None))
            if o == 'drain' and ap:
                tally('amount_drain', ap['db56'] == amt, dict(w=where, pred=amt, got=ap['db56']))
        elif sk in (F.MP0, F.RESTOREMP):
            o = F.skill_mp0(b, v) if sk == F.MP0 else F.skill_restoremp(b, v)
            tally('outcome_' + ('mp0' if sk == F.MP0 else 'restoremp'), True)
            tally('mpkind_' + o, True)
        elif sk in F.CHAIN_IDS:
            if sk == F.LIFESONG:
                _, ce = nxt_tag(vg, 'lifesong_in')
                o, _ = F.lifesong_cast(b, a, st16(ce))
                got_r = [e['db89'] for e in g if e['tag'] == 'vivify_in']
                tally('lifesong_' + o, True)
                if o == 'chain':
                    tally('lifesong_revived', F.lifesong_walk(b, a, v) == got_r, dict(w=where, got=got_r))
                else:
                    tally('lifesong_none', got_r == [], dict(w=where, o=o, got=got_r))
                continue
            elif sk == F.LIFEDANCE:
                _, ce = nxt_tag(vg, 'lifedance_in')
                o, _ = F.lifedance_cast(b, a, st16(ce))
            else:
                o = 'chain'
            got_o = 'chain' if 'chain_walk' in tags else 'nochain'
            tally('chain_start', (o == 'chain') == (got_o == 'chain'),
                  dict(w=where, a=a, sk=hex(sk), pred=o, got=got_o))
            tally('chain_kind_' + o, True)
            if o == 'chain' and got_o == 'chain':
                walk = F.chain_walk(b, a, v)
                got_w = [e['db89'] for e in g if e['tag'] == 'chain_walk']
                tally('chain_walk', [s for s, _ in walk] == got_w, dict(w=where, pred=walk, got=got_w))
                kinds = [k for _, k in walk]
                got_k = []
                for i, e in enumerate(g):
                    if e['tag'] == 'chain_walk':
                        nx = g[i + 1]['tag'] if i + 1 < len(g) else None
                        got_k.append({'chain_revive': 'revive', 'chain_heal': 'heal'}.get(nx, 'skip'))
                tally('chain_kinds', kinds == got_k, dict(w=where, pred=kinds, got=got_k))
                _, cc = nxt_tag(g, 'chain_caster')
                co, _ = F.chain_caster(b, a, st16(cc) if cc else 0)
                tally('chain_caster_' + co, True)
        nxt, n = F.next_victim(b, sk, f, cur, n)
        if nxt is not None:
            pred_v.append(nxt)
    tally('victims', pred_v == got_v, dict(w=where, a=a, sk=hex(sk), pred=pred_v, got=got_v))
    b.dd13[a] = 3
    if after is not None:
        board_cmp(b, after, where + f' a{a} {sk:#x}', after_p9=(after['tag'] == 'p9_slot'))


ROW_FN = {'row_heal': F.row_heal, 'row_vivify': F.row_vivify, 'row_antidote': F.row_antidote}


def check_rows(evs):
    """Every hooked bank $58 row call (commit-time entry 8, act re-resolve,
    re-decide): the row on the engine board at its entry, with its RNG, vs
    the queue target byte $DCED+2a at the next event. row_drain modes 1/2
    are not decoded (stand-in): only tallied."""
    for i, e in enumerate(evs[:-1]):
        if not e['tag'].startswith('row_'):
            continue
        nx = evs[i + 1]
        if nx['sc'] != e['sc']:
            continue
        a = e['db88']
        b = B.Board.from_event(e)
        got = nx['dcec'][a * 2 + 1]
        if got == 0xFF:                 # the uniform resolvers hand the slot back in
            mi = None                   # wBattleTargetIdx (the $FF fetch path):
            for x in evs[i + 1:]:       # read it at this actor's MISS machine
                if x['tag'] == 'round_start':
                    break               # commit-time call: the rig's forced $FF
                if x['db88'] != a:      # queue superseded it
                    continue
                if x['tag'].startswith('row_'):
                    break
                if x['tag'] == 'miss_in':
                    mi = x
                    break
            if mi is None:
                continue
            got = mi['db89']
        fn = ROW_FN.get(e['tag']) or F.ROWS[e['db8a']]      # $52A9 / $4CD1 by $DB8A
        pred, _ = fn(b, a, st16(e))
        tally(e['tag'], pred == got, dict(w=e['sc'], f=e['frame'], a=a, dd0b=b.dd0b[a], pred=pred, got=got,
                                          hp=e['hp'], maxhp=e['maxhp'], dd1b=e['dd1b'], rng=(e['rng1'], e['rng2'])))


def check_commits(sc, evs):
    """Natural AI rounds (scenarios 'ai_*': the enemies are not forced):
    the queue target an enemy committed for an F5 skill (round start,
    before any action) vs battle.COMMIT_TARGETS (pacing._commit_target's
    source). Mode-0 rows roll the RNG at commit: only tallied."""
    if not sc.startswith('ai_'):
        return
    for e in evs:
        if e['tag'] != 'round_start':
            continue
        b = B.Board.from_event(e)
        for a in range(4, 7):
            sk = b.q_skill(a)
            if sk not in F.ROWS or not b.valid(a):
                continue
            if b.dd0b[a] == 0 and F.ROWS[sk] in (F.row_heal, F.row_antidote, F.row_robmagic,
                                                 F.row_odddance):
                tally('commit_mode0_rng', True)
                continue
            pred, _ = B.COMMIT_TARGETS[sk](b, a, 0)
            tally('commit_target', pred == b.q_target(a),
                  dict(w=sc, f=e['frame'], a=a, sk=hex(sk), pred=pred, got=b.q_target(a)))


def run(events):
    for sc, evs in split_battles(events).items():
        check_rows(evs)
        check_commits(sc, evs)
        rounds = split_rounds(evs)
        for rn, rev in enumerate(rounds):
            actors, p9 = group_actions(rev)
            for gi, g in enumerate(actors):
                a = g[0]['A']
                if a == 0xFF or 'skill_load' not in [e['tag'] for e in g]:
                    continue
                _, sl = nxt_tag(g, 'skill_load')
                b = B.Board.from_event(sl)
                sk = b.q_skill(a)
                if sk not in F5_IDS or 'conf_pick' in [e['tag'] for e in g]:
                    continue
                if b.stb(a, 2) & 0x10:
                    continue                    # confused: not an F5 action
                if gi + 1 < len(actors):
                    after = actors[gi + 1][0]
                elif p9:
                    after = p9[0]
                elif rn + 1 < len(rounds):
                    after = rounds[rn + 1][0]
                else:
                    after = None
                b2 = copy.deepcopy(b)
                validate_action(b, a, g, after, f'{sc} r{rn}')
                driver_replay(b2, a, g, after, f'{sc} r{rn}')
            # revived slots must be in the next round's order
            if rn + 1 < len(rounds):
                R0, R1 = rev[0], rounds[rn + 1][0]
                for s in range(8):
                    if R0['dd1b'][s] == 1 and R1['dd1b'][s] == 0:
                        nact = [g for g in group_actions(rounds[rn + 1])[0] if g[0]['A'] == s]
                        af = next((e for e in rounds[rn + 1] if e['tag'] == 'actor_fetch'), None)
                        if af is None:
                            continue            # capture ended at the round start
                        order = af['db79']
                        tally('revive_rearm', R1['dd13'][s] == 2 and (s in order or bool(nact)),
                              dict(w=f'{sc} r{rn}', s=s, dd13=R1['dd13'][s], db79=order))


if __name__ == '__main__':
    path = next((x for x in sys.argv[1:] if not x.startswith('-')),
                os.path.join(ROOT, 'simulator', 'f5_events.json'))
    run(json.load(open(path)))
    total = sum(v[0] + v[1] for v in stats.values())
    bad = sum(v[1] for v in stats.values())
    for k, (ok, no) in sorted(stats.items()):
        print(f'{k:22s} ok={ok:5d} fail={no}')
    print(f'TOTAL {total} comparisons, {bad} mismatches')
    if not VERBOSE:
        for x in fails[:30]:
            print('  ', x)
    sys.exit(1 if bad else 0)
