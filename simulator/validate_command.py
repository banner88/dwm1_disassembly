#!/usr/bin/env python3
"""S130 (P3.15b) differential validator — the PLAYER'S ORDERS (battle menu
PLAN -> COMMAND) against simulator/command_events.json.gz, captured by
simulator/measure_command.py on the user's save with the real menu driven by
joypad input (BATTLE_SKILL_SYSTEM §15.10.7b).

The planner is the recorded order (the rig's per-round spec: skill + the
slot the player picked, alternatives `X|Y` in preference order); the model
is pacing.give_orders + pacing.command_commit + battle.simulate_round with
party_policy='command' semantics. With the ENGINE's RNG injected at each
waypoint (the S85 method — KEY_LESSONS S85), it diffs:

  menu      the queue pair the menu wrote per ordered monster ($DCEC/$DCED
            at the end of the command phase) and every refusal (msg via
            SaveBtl_4ca4) vs pacing.menu_order; the $DD03 := 3 / $DD13
            marks; which monsters the menu offered (pacing.plannable)
  gate      carry / no-carry of the obedience gate under tactic 3 (one RNG
            step from the band_in state)
  drift     the four bases $DC44/4C/54/5C after the commit (personality
            drift, Command row) vs pacing.personality_drift
  pick      the disobedient pick (SetBtlAI_7f5f) and the queue after the
            commit sub-state (target service for the $FF byte, RNG at the
            qfetch waypoint), $DD03 bit6
  incap     a monster the menu skipped (asleep / paralysed / confused /
            one-shot / stunned): its commit from the stale $DD03
  tension   $DB42 after the bank $58 tension rolls (battle.COMMIT_ROLL, RNG
            at the tension_in waypoint)
  round     the whole round through battle.simulate_round from the
            round_start board (oracle idle: post_order/post_action/
            actor_skip -> gates_in, pre_target -> target_fetch, pre_miss ->
            miss_in, p9_entry / post_dot_apply -> p9_slot, F8 mh_* classes)
            vs the next round_start (or the last event of a battle that
            ended): HP, MP, $DD1B, the 64-byte status area, ATK/DEF/AGL
  act       per actor: the target the engine's MISS machine entered vs the
            model's (log), Daze / fizzle outcomes

Usage: python3 simulator/validate_command.py [corpus] [-v] [-c (coverage)]
Exit 1 on any mismatch.
"""
import copy
import gzip
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import battle as B           # noqa: E402
from simulator import pacing as P           # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECORDS = {r['id']: r for r in json.load(open(os.path.join(ROOT, 'extracted', 'skill_records.json')))['records']}
SPECIES = P.load_species()
VERBOSE = '-v' in sys.argv
COVER = '-c' in sys.argv
args = [x for x in sys.argv[1:] if not x.startswith('-')]
CORPUS = args[0] if args else os.path.join(ROOT, 'simulator', 'command_events.json.gz')
stats, fails, cover = {}, [], {}


def tally(kind, ok, detail=None):
    s = stats.setdefault(kind, [0, 0])
    s[0 if ok else 1] += 1
    if not ok:
        fails.append((kind, detail))
        if VERBOSE:
            print('FAIL', kind, detail)


def cov(label):
    cover[label] = cover.get(label, 0) + 1


def st16(e):
    return (e['rng1'] << 8) | e['rng2']


def bases_of(e, s):
    ab = e['ai_bases']
    return (ab[s], ab[8 + s], ab[16 + s], ab[24 + s])


# --------------------------------------------------------------------------
# boards
# --------------------------------------------------------------------------
class Battle:
    def __init__(self, evs):
        self.init = next((e for e in evs if e['tag'] == 'battle_init'), evs[0])
        self.skills = {s: [sk for sk in self.init['dc64'][16 * s + 1:16 * s + 16:2] if sk != 0xFF]
                       for s in range(3)}

    def board(self, e):
        b = B.Board.from_event(e)
        b.maxmp = list(e['maxmp'])
        b.level = list(e['db9b'])
        b.species = list(e['dc3c'])
        for s in range(8):
            sp = SPECIES.get(b.species[s])
            if sp is not None and b.species[s] != 0xFF:
                b.family[s] = P._family_id(sp)
        i = self.init
        for k in ('maxhp', 'maxmp', 'atk', 'dfn', 'agl', 'int'):
            b.base[k] = list(i[k])
        b.ext['f7_db40'] = e['db40'][0]
        b.party_skills = [self.skills[s] for s in range(3)]
        b.party_bases = [bases_of(e, s) for s in range(3)]
        b.wld = [w & 0xFF for w in e['wld'][:3]]
        return b


# --------------------------------------------------------------------------
# the recorded planner
# --------------------------------------------------------------------------
def parse_spec(spec):
    """'FIGHT' -> None; else per-monster list of alternatives [(skill, want)]."""
    if spec == 'FIGHT':
        return None
    out = []
    for ent in spec.split('/'):
        alts = []
        for x in ent.split('|'):
            want = int(x.split('@')[1], 0) if '@' in x else None
            if x.startswith('atk'):
                alts.append((B.ATTACK, want))
            elif x.startswith('def'):
                alts.append((0x8D, None))
            elif x.startswith('sk:'):
                alts.append((int(x[3:].split('@')[0], 0), want))
            else:
                alts.append(('tac', int(x.split(':')[1])))
        out.append(alts)
    return out


# --------------------------------------------------------------------------
# commit
# --------------------------------------------------------------------------
def check_commit(bt, sc, rn, mr, menu, evs, where):
    """mr = the m_round event (end of the command phase); menu = the menu's
    m_* events of this command phase; evs = the events from mr up to (incl.)
    the round_start."""
    plan = parse_spec(mr['spec'])
    if plan is None:
        cov('round FIGHT')
        check_fight(bt, mr, evs, where)
        return
    cov('round PLAN')
    b = bt.board(mr)
    # the menu's input board = the one before any mark: undo the menu's
    # writes (queue / $DD03 / $DD13 of the party) from the round's first
    # m_* event, else from mr itself
    first = menu[0] if menu else mr
    pre = bt.board(first)
    pre.queue = [0xFF] * 6 + list(mr['dcec'][6:])
    pre.dd03 = list(first['dd03'])
    pre.dd13 = [2 if (pre.valid(s) and s < 3) else pre.dd13[s] for s in range(8)]
    refusals = [e for e in menu if e['tag'] == 'm_msg']
    menu_seq = [s for s in range(3) if P.plannable(pre, s)]
    k = 0

    def planner(bb, s):                    # the rig's spec is per party slot
        return list(plan[min(s, len(plan) - 1)])
    pre.ext['planner'] = planner
    P.give_orders(pre, RECORDS, None)
    ordered = pre.ext.get('command_ordered', set())
    for s in range(3):
        if not b.valid(s):
            continue
        got_q = (mr['dcec'][2 * s], mr['dcec'][2 * s + 1])
        if s in ordered:
            if pre.queue[2 * s] in (0x3F, 0x51, 0x52, 0x53) and got_q[0] == pre.queue[2 * s]:
                # bank $58 entry 4/5 picks the target DURING the menu (the
                # menu-time RNG is idle time): any live slot — $6379 (Massacre)
                # is side-blind, it can pick an ALLY (measured)
                pre.queue[2 * s + 1] = got_q[1] if pre.valid(got_q[1]) else 0xFE
            tally('menu_queue', (pre.queue[2 * s], pre.queue[2 * s + 1]) == got_q,
                  dict(w=where, s=s, pred=(hex(pre.queue[2 * s]), pre.queue[2 * s + 1]),
                       got=(hex(got_q[0]), got_q[1])))
            tally('menu_marks', mr['dd03'][s] == 3 and mr['dd13'][s] == 1,
                  dict(w=where, s=s, dd03=mr['dd03'][s], dd13=mr['dd13'][s]))
            sk = pre.queue[2 * s]
            if sk in (0x3F, 0x51, 0x52, 0x53):
                cov('order menu-time RNG pick %02x' % sk)
            rec = RECORDS.get(sk)
            tm = rec['battle_record']['fields']['target_mode'] if rec else 0
            cov('order ' + ('ATK' if sk == B.ATTACK else 'DEF' if sk == 0x8D else
                            ('group' if not tm & 1 else 'single-enemy' if tm & 0x10 else
                             'self' if tm & 0x40 else 'single-ally') + ' ' + B.damage_core(sk, rec)))
        else:
            cov('menu skipped (incapacitated)')
            tally('menu_skip', mr['dd03'][s] != 3 or got_q == (0xFF, 0xFF),
                  dict(w=where, s=s, q=got_q))
    pred_ref = [x for x in pre.ext.get('command_refused', []) if x[2] != 'target']   # no msg:
    for x in pre.ext.get('command_refused', []):     # the cursor skips dead slots
        if x[2] == 'target':
            cov('refused target (dead)')
    tally('menu_refusals', len(pred_ref) == len(refusals),
          dict(w=where, pred=pred_ref, got=[hex(e['HL']) for e in refusals]))
    for x in pred_ref:
        cov('refused ' + x[2])
    # ---- per-actor commit ------------------------------------------------
    rs = evs[-1]
    cur = bt.board(mr)
    cur.queue = list(mr['dcec'])
    cur.ext['plan'] = P.PLAN_COMMAND
    cur.ext['command_ordered'] = ordered
    for s in range(3):
        s0 = next((i for i, e in enumerate(evs) if e['tag'] == 'ai_s0' and e['db88'] == s
                   and e['d9ec'] == 5 and e['d9ed'] == 1), None)
        if s0 is None:
            continue
        grp = []
        for e in evs[s0 + 1:]:
            if e['tag'] == 'ai_s0' and e['db88'] != s:
                break
            if e['tag'] == 'round_start':
                break
            grp.append(e)
        tags = [e['tag'] for e in grp]
        band = next((e for e in grp if e['tag'] == 'band_in'), None)
        post = next((e for e in grp if e['tag'] == 'ai_post'), None)
        qf = next((e for e in grp if e['tag'] == 'qfetch' and e['db88'] == s), None)
        ten = next((e for e in grp if e['tag'] == 'tension_in' and e['db88'] == s), None)
        b0 = bt.board(evs[s0])
        b0.queue = list(evs[s0]['dcec'])
        b0.ext['plan'] = P.PLAN_COMMAND
        b0.ext['command_ordered'] = ordered
        gate_ran = band is not None
        pred_gate = s in ordered
        tally('gate_ran', gate_ran == pred_gate, dict(w=where, s=s, dd03=b0.dd03[s], tags=tags))
        state = st16(band) if band else st16(evs[s0])
        sr = [state]

        def oracle(st, cls):
            if cls == 'cmd_target' and qf is not None:
                return st16(qf)
            return st
        pb0 = b0.party_bases[s]
        act, tgt = P.command_commit(b0, s, RECORDS, sr, oracle, None)
        if band is not None:
            got_c = 'carry' in tags
            pred_c = bool(b0.dd03[s] & 0x40)
            tally('gate', pred_c == got_c, dict(w=where, s=s, wld=b0.wld[s], bases=pb0, pred=pred_c))
            cov('gate %s %s' % ('carry' if got_c else 'obey', 'ordered' if s in ordered else 'incap'))
        if post is not None:
            got_b = bases_of(post, s)
            tally('drift', tuple(b0.party_bases[s]) == got_b,
                  dict(w=where, s=s, pred=b0.party_bases[s], got=got_b, pre=pb0))
            if tuple(pb0) != got_b:
                cov('drift row')
        # the queue after the commit sub-state: at tension_in (written)
        if ten is not None:
            got_q = (ten['dcec'][2 * s], ten['dcec'][2 * s + 1])
            tally('commit_queue', (act, tgt) == got_q,
                  dict(w=where, s=s, pred=(hex(act), tgt), got=(hex(got_q[0]), got_q[1]), tags=tags))
            tally('dd03', b0.dd03[s] == ten['dd03'][s], dict(w=where, s=s, pred=b0.dd03[s], got=ten['dd03'][s]))
            if 'direct' in tags:
                cov('pick %02x' % act)
            # tension rolls
            if B.COMMIT_ROLL is not None:
                b0.queue[2 * s], b0.queue[2 * s + 1] = got_q
                b0.db42 = list(ten['db42'])
                B.COMMIT_ROLL(b0, s, tuple(b0.party_bases[s]), st16(ten))
                nxt = next((e for e in evs if e['frame'] > ten['frame'] or
                            (e['frame'] == ten['frame'] and evs.index(e) > evs.index(ten))), None)
                if nxt is not None:
                    tally('tension', b0.db42[s] == nxt['db42'][s],
                          dict(w=where, s=s, pred=b0.db42[s], got=nxt['db42'][s]))
    # round_start queue of the party == the commits
    for s in range(3):
        cur.queue[2 * s] = rs['dcec'][2 * s]


def check_fight(bt, mr, evs, where):
    """A FIGHT round ($DD72 = $80) for Command-tactic party monsters: the
    gate with tactic ($DD03 & 3; the command phase leaves bit6 clear); tactic
    3 no carry -> AIState0AltOutcome_6f8c queues plain Attack, whose $FF
    target the commit sub-state resolves (party $41E9 pick); a carry runs
    the category machine unbiased (not compared here: pacing 'tactics')."""
    for s in range(3):
        s0 = next((i for i, e in enumerate(evs) if e['tag'] == 'ai_s0' and e['db88'] == s
                   and e['d9ec'] == 5 and e['d9ed'] == 1), None)
        if s0 is None:
            continue
        grp = []
        for e in evs[s0 + 1:]:
            if (e['tag'] == 'ai_s0' and e['db88'] != s) or e['tag'] == 'round_start':
                break
            grp.append(e)
        tags = [e['tag'] for e in grp]
        band = next((e for e in grp if e['tag'] == 'band_in'), None)
        b0 = bt.board(evs[s0])
        tally('fight_dd03', not (b0.dd03[s] & 0x40), dict(w=where, s=s, dd03=b0.dd03[s]))
        if band is None:
            continue
        sr = [st16(band)]
        car = P.obedience_carries(b0.wld[s], b0.party_bases[s], b0.dd03[s] & 3, sr)
        tally('fight_gate', car == ('carry' in tags), dict(w=where, s=s, pred=car))
        cov('FIGHT gate %s tactic %d' % ('carry' if car else 'obey', b0.dd03[s] & 3))
        qf = next((e for e in grp if e['tag'] == 'qfetch' and e['db88'] == s), None)
        ten = next((e for e in grp if e['tag'] == 'tension_in' and e['db88'] == s), None)
        if not car and (b0.dd03[s] & 3) == 3 and qf is not None and ten is not None:
            sr = [st16(qf)]
            t = P._commit_target(b0, s, B.ATTACK, RECORDS, sr)
            tally('fight_queue', (B.ATTACK, t) == (ten['dcec'][2 * s], ten['dcec'][2 * s + 1]),
                  dict(w=where, s=s, pred=t, got=ten['dcec'][2 * s:2 * s + 2]))


# --------------------------------------------------------------------------
# round replay
# --------------------------------------------------------------------------
class Oracle:
    MAP = {'post_order': ('gates_in',), 'post_action': ('gates_in',), 'actor_skip': ('gates_in',),
           'pre_target': ('target_fetch', 'qfetch'), 'pre_miss': ('miss_in',),
           'p9_entry': ('p9_slot',), 'post_dot_apply': ('p9_slot',),
           'pre_conf': ('conf_pick',), 'pre_snap': ('snap_roll',),
           'mh_post_hit': ('mh_cont',), 'mh_pre_snap': ('snap_roll',),
           'mh_refetch': ('target_fetch',), 'mh_call_msg': ('target_fetch',)}

    def __init__(self, evs):
        self.evs, self.i = evs, 0
        self.calls = []

    def __call__(self, state, cls):
        self.calls.append(cls)
        if cls == 'round_gap':
            return st16(self.evs[0])
        tags = self.MAP.get(cls)
        if not tags:
            return state
        for j in range(self.i, len(self.evs)):
            e = self.evs[j]
            # an act-time re-resolve ($D9ED = $19) or a dead single target's
            # re-pick ($53:$47D1, $D9ED = 0) fetches (bank $58 entry 8) BEFORE
            # the target-fetch state: its pick reads that frame's RNG
            if e['tag'] in tags and (e['tag'] != 'qfetch' or e['d9ed'] != 0x01):
                self.i = j + 1
                return st16(e)
        return state


ATTACK_ROW = frozenset([0x37, 0x38, 0x3A, 0x3B, 0x3D, 0x40, 0x50, 0x55, 0xDD])


def standin_target(sk):
    """An ENEMY's act-time single-target pick the round core only
    approximates (pick_front_weighted stand-in for a skill whose bank $58
    row is a scoring service, e.g. Slow $48AB) — not part of this family:
    the replay takes the engine's target for it (counted, not compared)."""
    rec = RECORDS.get(sk)
    tm = rec['battle_record']['fields']['target_mode'] if rec else 0
    return (tm & 1) and sk not in ATTACK_ROW and sk not in B.TARGET_RESOLVERS \
        and sk not in B.RERESOLVE_PICKERS


def check_round(bt, sc, rn, rev, nxt, plan81, where):
    R = rev[0]
    b = bt.board(R)
    b.ext['plan'] = P.PLAN_COMMAND if plan81 else 0x80
    B.clear_guard_marks(b) if hasattr(B, 'clear_guard_marks') else None
    oracle = Oracle(rev)

    def engine_target(bb, a, v, sk, f):
        if a < 4 or not standin_target(sk):
            return v
        for e in rev[oracle.i:]:
            if e['tag'] == 'miss_in' and e['db88'] == a:
                if e['db89'] != v:
                    cov('enemy act-time target from the engine (stand-in row %02x)' % sk)
                return e['db89']
            if e['tag'] == 'gates_in':
                break
        return v
    B.VICTIM_HOOKS.insert(0, engine_target)
    try:
        log, _ = B.simulate_round(b, st16(R), RECORDS, P.load_dup_flags(), oracle)
    finally:
        B.VICTIM_HOOKS.remove(engine_target)
    # act-time targets: the engine's miss_in per actor (first victim)
    got_t = []
    for e in rev:
        if e['tag'] == 'miss_in':
            got_t.append((e['db88'], e['db89']))
    pred_t = [(x[0], x[2][0] if isinstance(x[2], tuple) else x[2]) for x in log
              if x[1] in ('hit', 'miss', 'dodge', 'block', 'f6', 'daze', 'heal', 'status', 'no-effect')]
    for x in log:
        if x[1] == 'daze':
            cov('act daze')
    for k, e in enumerate(rev):                  # obeyed orders on a dead target
        if e['tag'] == 'target_fetch' and e['db88'] < 3 and e['dd03'][e['db88']] == 3 \
                and e['dd1b'][e['db89'] & 7] != 0:
            nx = next((x for x in rev[k + 1:] if x['tag'] in ('miss_in', 'gates_in', 'p9_slot')), None)
            if nx is None or nx['tag'] != 'miss_in':
                cov('act fizzle (ordered target dead)')
    for e in rev:
        if e['tag'] == 'daze':
            tally('daze_reached', any(x[1] == 'daze' and x[0] == e['db88'] for x in log),
                  dict(w=where, a=e['db88']))
    if nxt is None:
        return
    end = nxt['tag'] != 'round_start'
    keys = ('hp', 'dd1b') if end else ('hp', 'mp', 'dd1b', 'atk', 'dfn', 'agl')
    diffs = {}
    for k in keys:
        mv = list(getattr(b, k))
        ev = list(nxt[k])
        if k == 'dd1b':
            mv = [1 if v == 1 else v for v in mv]
        if mv != ev:
            diffs[k] = (mv, ev)
    if not end and b.st != list(nxt['st']):
        diffs['st'] = [(i, b.st[i], nxt['st'][i]) for i in range(64) if b.st[i] != nxt['st'][i]]
    tally('round_end' if end else 'round', not diffs,
          dict(w=where, diffs=diffs, log=log, calls=oracle.calls[-6:]))


# --------------------------------------------------------------------------
def run(events):
    per = {}
    for e in events:
        per.setdefault(e['sc'], []).append(e)
    for sc, evs in per.items():
        bt = Battle(evs)
        rs_idx = [i for i, e in enumerate(evs) if e['tag'] == 'round_start']
        mrs = [i for i, e in enumerate(evs) if e['tag'] == 'm_round']
        for rn, i in enumerate(rs_idx):
            where = '%s r%d' % (sc, rn)
            mi = max((m for m in mrs if m < i), default=None)
            plan81 = False
            if mi is not None:
                mr = evs[mi]
                plan81 = mr['spec'] != 'FIGHT'
                prev = rs_idx[rn - 1] if rn else 0
                menu = [e for e in evs[prev:mi] if e['tag'] in ('m_skill', 'm_target', 'm_mark', 'm_msg')]
                check_commit(bt, sc, rn, mr, menu, evs[mi:i + 1], where)
            j = rs_idx[rn + 1] if rn + 1 < len(rs_idx) else None
            if j is not None:
                rev = evs[i:j]
                # the next command phase's events (menu) come before the next
                # round_start: cut the round at the next m_round / ai_s0
                cut = next((k for k, e in enumerate(rev) if k > 0 and (
                    e['tag'] in ('m_round', 'm_skill', 'm_target', 'm_mark', 'm_msg')
                    or (e['tag'] == 'ai_s0' and e['d9ec'] == 5))), len(rev))
                if any(e['tag'] == 'ai_s0' and e['d9ec'] != 5 for e in rev[:cut]):
                    cov('act-time re-decide ($53:$46A8, disobedient $DD0B=2)')
                check_round(bt, sc, rn, rev[:cut], evs[j], plan81, where)
            else:
                rev = evs[i:]
                last = rev[-1]
                if last['tag'] == 'battle_end':
                    check_round(bt, sc, rn, rev[:-1], last, plan81, where)


def main():
    evs = json.load(gzip.open(CORPUS, 'rt') if CORPUS.endswith('.gz') else open(CORPUS))
    run(evs)
    total = sum(v[0] + v[1] for v in stats.values())
    bad = sum(v[1] for v in stats.values())
    nb = len({e['sc'] for e in evs})
    for k, (ok, no) in sorted(stats.items()):
        print(f'{k:16s} ok={ok:5d} fail={no}')
    if COVER:
        for k, v in sorted(cover.items()):
            print(f'  cover {k:40s} {v}')
    print(f'command: {nb} battles, {total} checks, {bad} mismatches')
    if not VERBOSE:
        for f in fails[:12]:
            print('  ', str(f)[:600])
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
