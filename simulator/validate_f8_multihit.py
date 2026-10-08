#!/usr/bin/env python3
"""S130 F8 differential validator for the multi-hit loop
(simulator/skillfx/f8_multihit.py) — the S85 method: each multi-hit ACTION
captured by simulator/measure_f8_multihit.py is replayed through the model
from the engine's board at the first target fetch, with the engine's RNG
injected ONLY at the measured idle sites (the model's `idle` callback is an
oracle that returns the engine state at the next pre-MISS / continuation /
target-fetch waypoint). Everything between idle sites runs on the model's
own deterministic chain, so the same-frame step structure (state-7 step,
MISS step, crit step, handler / calcdef step, continuation RNG2 read,
re-pick step) is itself under test.

Per pass ("hit"), compared against the engine:
  passes     number of target fetches of the action
  fetch      remembered target $DCED and the pre-increment $DD69 at $520C
  state7     RNG at the MISS machine entry = fetch + 1 step (passes >= 2)
  miss_rng   RNG after the MISS step
  outcome    pass / dodge / miss / block / skip (dead target) / iron
  handler    RNG at the skill-handler entry (after the crit step)
  callhelp   CallHelp/YellHelp first-pass success / fail
  damage     $DB56 at apply ($52:$6D56) vs the model's damage
  board      all 8 HP + $DD1B at the continuation (KO handling), the
             victim's +2 byte (BIGSLEEP) and MP (MP0)
  decision   continue / end at the continuation (and why)
  repick     $642C entered at the continuation's own RNG (k=0) when the
             model re-picks, and never otherwise
Plus, per re-resolved $51/$52/$53 action: the act-time pick through
battle.RERESOLVE_PICKERS vs the engine's first target.

Also prints the measured idle-k pools per F8 class and writes them to
simulator/f8_idle_pools.json with --pools.

Usage: python3 simulator/validate_f8_multihit.py [simulator/f8_events.json] [-v] [--pools]
Exit 1 on any mismatch.
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import battle as B
from simulator.skillfx import f8_multihit as F8

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECORDS = {r['id']: r for r in json.load(open(os.path.join(ROOT, 'extracted', 'skill_records.json')))['records']}
VERBOSE = '-v' in sys.argv
args = [x for x in sys.argv[1:] if not x.startswith('-')]
CORPUS = args[0] if args else os.path.join(ROOT, 'simulator', 'f8_events.json')
F8_ALL = set(F8.F8_IDS) | {F8.BIGSLEEP, F8.MP0}
BOUNDARY = ('actor_fetch', 'round_end', 'p9_slot', 'round_start', 'side_wipe')
HANDLER_TAGS = ('h_biattack', 'h_callhelp', 'h_rainslash', 'h_meteor', 'h_bigsleep', 'h_mp0')
OUTCOME_TAGS = {'dodge': 'dodge', 'miss': 'miss', 'block': 'block', 'miss_pass': 'pass'}

stats, fails, cover = {}, [], {}
pools = {'mh_post_hit': [], 'mh_refetch': [], 'mh_call_msg': [], 'mh_pre_snap': []}


def tally(kind, ok, detail=None):
    s = stats.setdefault(kind, [0, 0])
    s[0 if ok else 1] += 1
    if not ok:
        fails.append((kind, detail))
        if VERBOSE:
            print('FAIL', kind, detail)


def st16(e):
    return (e['rng1'] << 8) | e['rng2']


def ksteps(a, b):
    s = a
    for k in range(65536):
        if s == b:
            return k
        s = B.rng_step(s)


def windows(evs):
    """(start, end) index pairs: skill_load .. next boundary (exclusive)."""
    out, i = [], 0
    while i < len(evs):
        if evs[i]['tag'] != 'skill_load':
            i += 1; continue
        j = i + 1
        while j < len(evs) and evs[j]['tag'] not in BOUNDARY:
            j += 1
        out.append((i, j))
        i = j
    return out


class Oracle:
    """The model's idle(state, cls): returns the engine state at the next
    matching waypoint (and checks the board at each continuation)."""

    def __init__(self, evs, a, b, sk, where):
        self.evs, self.i, self.a, self.b, self.sk, self.w = evs, 0, a, b, sk, where
        self.calls = []

    def _next(self, tags, stop=()):
        for j in range(self.i, len(self.evs)):
            t = self.evs[j]['tag']
            if t in tags:
                self.i = j + 1
                return self.evs[j]
            if t in stop:
                return None
        return None

    def __call__(self, state, cls):
        self.calls.append(cls)
        if cls == 'pre_miss':
            e = self._next(('miss_in',), stop=('mh_cont', 'target_fetch'))
            return st16(e) if e else state
        if cls == 'mh_post_hit':
            e = self._next(('mh_cont',), stop=('target_fetch',))
            if e is None:
                tally('cont_present', False, dict(w=self.w))
                return state
            self.check_board(e)
            pools[cls].append(ksteps(state, st16(e)))
            return st16(e)
        if cls == 'mh_pre_snap':
            e = self._next(('snap_roll',), stop=('mh_cont', 'target_fetch'))
            tally('snap_present', e is not None, dict(w=self.w))
            if e is None:
                return state
            pools[cls].append(ksteps(state, st16(e)))
            return st16(e)
        if cls in ('mh_refetch', 'mh_call_msg'):
            e = self._next(('target_fetch',))
            if e is None:
                return state
            pools[cls].append(ksteps(state, st16(e)))
            return st16(e)
        return state

    def check_board(self, e):
        b = self.b
        ok = all(b.hp[s] == e['hp'][s] for s in range(8) if e['dd1b'][s] != 0xFF or b.hp[s])
        tally('board_hp', ok, dict(w=self.w, model=b.hp, eng=e['hp']))
        ok = all((b.dd1b[s] == 1) == (e['dd1b'][s] == 1) for s in range(8))
        tally('board_ko', ok, dict(w=self.w, model=b.dd1b, eng=e['dd1b']))
        if True:   # victim status +2 (BIGSLEEP writes it; snap-out clears sleep/confusion)
            # (live slots only: a KO wipes the victim's +2 — measured $88 -> 0)
            tally('board_status', all(b.stb(s, 2) == e['st'][s * 8 + 2] for s in range(8)
                                      if e['dd1b'][s] == 0),
                  dict(w=self.w, model=[b.stb(s, 2) for s in range(8)],
                       eng=[e['st'][s * 8 + 2] for s in range(8)]))
        if self.sk == F8.MP0:
            tally('board_mp', all(b.mp[s] == e['mp'][s] for s in range(8)),
                  dict(w=self.w, model=b.mp, eng=e['mp']))


def passes_of(evs):
    """Engine passes: groups starting at each target_fetch."""
    groups, cur = [], None
    for e in evs:
        if e['tag'] == 'target_fetch':
            cur = [e]; groups.append(cur)
        elif cur is not None:
            cur.append(e)
    return groups


def model_passes(trace):
    groups, cur = [], None
    for it in trace:
        if it[0] == 'fetch':
            cur = [it]; groups.append(cur)
        elif cur is not None:
            cur.append(it)
    return groups


def first(group, tags):
    for e in group:
        if e['tag'] in tags:
            return e
    return None


def get(mp, label):
    for it in mp:
        if it[0] == label:
            return it
    return None


def replay_action(sc, evs, lo, hi):
    win = evs[lo:hi]
    nxt = evs[hi] if hi < len(evs) else None
    tf = [k for k, e in enumerate(win) if e['tag'] == 'target_fetch']
    if not tf:
        return
    if nxt is None:
        return                      # the capture ended mid-action (frame cap)
    e0 = win[tf[0]]
    sk, a = e0['db8a'], e0['db88']
    if sk not in F8_ALL or e0['dd69'] != 0:
        return
    where = f'{sc}@{e0["frame"]} a={a} sk={sk:02x}'
    cover[sk] = cover.get(sk, 0) + 1
    side = 'party' if a < 4 else 'enemy'
    cover[(sk, side)] = cover.get((sk, side), 0) + 1

    # act-time re-resolve pick (RERESOLVE_PICKERS, battle.py S130 F8 edit)
    rr = [k for k, e in enumerate(win[:tf[0]]) if e['tag'] == 'reresolve']
    if rr and sk in B.RERESOLVE_PICKERS:
        rp = next((e for e in win[rr[0]:tf[0]] if e['tag'] == 'repick'), None)
        tally('reresolve_enters_642c', rp is not None, dict(w=where))
        if rp is not None:
            b0 = B.Board.from_event(rp)
            t, _ = B.RERESOLVE_PICKERS[sk](b0, a, st16(rp))
            tally('reresolve_pick', t == e0['dcec'][2 * a + 1],
                  dict(w=where, model=t, eng=e0['dcec'][2 * a + 1]))

    b = B.Board.from_event(e0)
    b.ext['f8_trace'] = trace = []
    rec = RECORDS.get(sk)
    f = rec['battle_record']['fields'] if rec else {}
    t0 = e0['dcec'][2 * a + 1]
    oracle = Oracle(win[tf[0] + 1:], a, b, sk, where)
    ctx = B.ActionCtx(b=b, a=a, sk=sk, rec=rec, f=f, core=B.damage_core(sk, rec), t=t0,
                      qt=t0, state=st16(e0), records=RECORDS, log=[], idle=oracle, real_sk=sk)
    F8.multihit_action(ctx)

    eps = passes_of(win[tf[0]:])
    mps = model_passes(trace)
    tally('passes', len(eps) == len(mps), dict(w=where, eng=len(eps), model=len(mps),
                                               log=ctx.log))
    for n, (ep, mp) in enumerate(zip(eps, mps)):
        w = f'{where} pass{n + 1}'
        ef = ep[0]
        _, mdd, mtgt, mst = mp[0]
        tally('fetch_target', mtgt == ef['dcec'][2 * a + 1], dict(w=w, model=mtgt, eng=ef['dcec'][2 * a + 1]))
        tally('fetch_dd69', mdd == ef['dd69'], dict(w=w, model=mdd, eng=ef['dd69']))
        mi = first(ep, ('miss_in',))
        mpre = get(mp, 'miss_pre')
        tally('miss_entered', (mi is None) == (mpre is None), dict(w=w, eng=mi is not None))
        if mi is not None and mpre is not None and n > 0:
            tally('state7_step', mpre[1] == st16(mi), dict(w=w, k=ksteps(st16(ef), st16(mi))))
        mr = first(ep, ('miss_rng',))
        mpost = get(mp, 'miss_post')
        if mr is not None and mpost is not None:
            tally('miss_rng', mpost[1] == st16(mr), dict(w=w))
        eo = first(ep, tuple(OUTCOME_TAGS))
        mo = get(mp, 'outcome')
        if mi is not None:
            tally('outcome', mo is not None and eo is not None and OUTCOME_TAGS[eo['tag']] == mo[1],
                  dict(w=w, eng=eo and eo['tag'], model=mo))
            cover[('outcome', mo and mo[1])] = cover.get(('outcome', mo and mo[1]), 0) + 1
        else:
            tally('outcome', mo is not None and mo[1] in ('skip', 'iron', 'airborne'), dict(w=w, model=mo))
            cover[('outcome', mo and mo[1])] = cover.get(('outcome', mo and mo[1]), 0) + 1
        eh = first(ep, HANDLER_TAGS)
        mh = get(mp, 'handler')
        tally('handler_entered', (eh is None) == (mh is None), dict(w=w, eng=eh and eh['tag']))
        if eh is not None and mh is not None:
            tally('handler_rng', mh[1] == st16(eh), dict(w=w, k=ksteps(st16(mr), st16(eh)) if mr else None))
        mc = get(mp, 'callhelp')
        if mc is not None:
            nf = eps[n + 1][0] if n + 1 < len(eps) else None
            eng_ok = nf is not None and nf['dd69'] in (0x0F, 0x10, 0x11)
            tally('callhelp_roll', mc[1] == eng_ok, dict(w=w, model=mc, eng_next=nf and nf['dd69']))
            cover[('callhelp', side, mc[1])] = cover.get(('callhelp', side, mc[1]), 0) + 1
        ma = get(mp, 'apply')
        ea = first(ep, ('apply_in',))
        if ma is not None:
            # a 0-damage hit takes the "no damage" message route: no apply
            # waypoint ($52:$6D56 is not entered; measured)
            ok = (ea is None) if ma[2] == 0 else (ea is not None and ea['db56'] == ma[2])
            tally('damage', ok, dict(w=w, model=ma[1:], eng=ea and (ea['db89'], ea['db56'])))
            if ma[2] == 0:
                cover['zero_damage_hit'] = cover.get('zero_damage_hit', 0) + 1
                if ef['st'][ma[1] * 8 + 2] & 0x90:
                    cover['zero_damage_on_sleeper'] = cover.get('zero_damage_on_sleeper', 0) + 1
            if sk in F8.CALLHELP_IDS:
                v = ma[1]
                key = ('helper_ladder', side, B.D.res_level(bytes(ef['res'][v * 7:v * 7 + 7]), 24),
                       ef['st'][v * 8 + 5] & 0xC0)
                cover[key] = cover.get(key, 0) + 1
            if ma[3]:
                cover['ko_midloop' if n + 1 < len(eps) else 'ko_last'] = \
                    cover.get('ko_midloop' if n + 1 < len(eps) else 'ko_last', 0) + 1
        es, ms = first(ep, ('snap_roll',)), get(mp, 'snap')
        tally('snap_site', (es is None) == (ms is None), dict(w=w, eng=es is not None, model=ms))
        if ms is not None:
            cover[('snap', ms[2])] = cover.get(('snap', ms[2]), 0) + 1
        md = get(mp, 'decision')
        ec = first(ep, ('mh_cont',))
        if md is not None:
            eng_go = n + 1 < len(eps)
            tally('decision', md[1] == eng_go, dict(w=w, model=md[1:], eng_go=eng_go))
            cover[('why', sk, md[2])] = cover.get(('why', sk, md[2]), 0) + 1
            erp = first(ep, ('repick',))
            tally('repick_site', (erp is not None) == (md[2] == 'repick'),
                  dict(w=w, eng=erp is not None, why=md[2]))
            if erp is not None and ec is not None:
                tally('repick_same_frame', st16(erp) == st16(ec), dict(w=w))
    if len(eps) == len(mps) and nxt is not None:
        tally('action_end', nxt['tag'] in BOUNDARY, dict(w=where, nxt=nxt['tag']))


def main():
    evs = json.load(open(CORPUS))
    by = {}
    for e in evs:
        by.setdefault(e['sc'], []).append(e)
    for sc, ev in by.items():
        for lo, hi in windows(ev):
            replay_action(sc, ev, lo, hi)
    for k in sorted(stats):
        ok, bad = stats[k]
        print(f'  {k:24s} {ok:5d} ok {bad:3d} bad')
    print('coverage:')
    for k in sorted(cover, key=str):
        print('   ', k, cover[k])
    if '--pools' in sys.argv:
        out = os.path.join(ROOT, 'simulator', 'f8_idle_pools.json')
        json.dump(dict(_generator='simulator/validate_f8_multihit.py --pools over ' + os.path.basename(CORPUS),
                       _note='RNG idle-step pools for the F8 multi-hit loop idle classes '
                             '(skillfx/f8_multihit.py); k = LCG steps between the waypoints, '
                             'minus the deterministic re-pick / state-7 steps',
                       pools=pools), open(out, 'w'))
        print('wrote', out, {k: len(v) for k, v in pools.items()})
    n = sum(s[0] + s[1] for s in stats.values())
    m = sum(s[1] for s in stats.values())
    print(f'TOTAL {n} comparisons, {m} mismatches')
    sys.exit(1 if m else 0)


if __name__ == '__main__':
    main()
