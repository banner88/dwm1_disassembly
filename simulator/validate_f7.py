#!/usr/bin/env python3
"""S130 F7 differential validator — stat buffs/debuffs
(simulator/skillfx/f7_stats.py) against the engine captures of
simulator/measure_f7.py (corpus simulator/f7_events.json).

Per F7 handler call (the S85 method: the engine's RNG and board are
injected at the handler entry waypoint, the model's prediction is diffed
against the handler's post waypoint):
  outcome   ok / fail (msg $BB) / rollmiss (msg $B8) / already
  amount    $DB56 after the handler (UltraDown: per sub-state)
  stats     DEF/AGL/ATK/HP/MaxHP/MP/MaxMP of all 8 slots after
  status    the 64-byte status area + $DB40 after (markers, Surge cures,
            UltraDown Surround)
  dd13      $DD13 after (Surge's sleep/confusion 'no action' write)
  rng       the RNG after the handler (same-frame posts only)
  pre_rng   the RNG at handler entry == the MISS machine's post-step RNG
Base and propagation checks:
  base      every bank $57 entry 7/8 read ($DD72/73 after rst $10 in
            GetBaseDEF_52b1/52c6) vs the model's base source (party =
            record, enemy = enemy_stats row)
  base_src  at battle start: DEF/AGL/ATK/INT of every live slot == source
  victims   tm 18/34 sweep order vs side_victims(start=queued target)
  chain     DEF/AGL/ATK + the $DB08+8t markers at every round_start and
            actor_fetch == the model chain (nothing else writes them;
            phase 9 keeps them: no decay)
  order     $DB79 vs round_order() — tallied separately when some live
            slot's AGL differs from base ('order_buffed')
  dodge     the MISS machine (miss_gate) vs the engine's route —
            separately when the target's AGL differs from base

Usage: python3 simulator/validate_f7.py [corpus.json] [-v] [-c (branch coverage)]
"""
import json, os, sys, copy
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import battle as B
from simulator.skillfx import f7_stats as F

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECORDS = {r['id']: r for r in json.load(open(os.path.join(ROOT, 'extracted', 'skill_records.json')))['records']}
ROWS = {e['enemy_stats_id']: e for e in json.load(open(os.path.join(ROOT, 'extracted', 'enemy_stats.json')))}
VERBOSE = '-v' in sys.argv
args = [x for x in sys.argv[1:] if not x.startswith('-')]
CORPUS = args[0] if args else os.path.join(ROOT, 'simulator', 'f7_events.json')

H_TAGS = {'h_sap': F.sap_one, 'h_upper': F.upper_one, 'h_slow': F.slow_one,
          'h_speed': F.speed_one, 'h_surge': F.surge_one, 'h_ultra': F.ultradown_one,
          'h_lick': F.sicklick_one, 'h_transform': None}
KEYS = ('dfn', 'agl', 'atk', 'hp', 'maxhp', 'mp', 'maxmp')
stats, fails = {}, []
cover = {}


def classify(tag, e, b0, a, t, out):
    """Branch label of one handler call, from the PRE board (coverage
    report only — not a comparison)."""
    lab = []
    if tag in ('h_sap', 'h_slow', 'h_lick', 'h_ultra'):
        rt = {'h_sap': 12, 'h_lick': 12, 'h_slow': 13, 'h_ultra': 8}[tag]
        lev = F.D.res_level(bytes(b0.res[t * 7:t * 7 + 7]), rt)
        s5 = b0.stb(t, 5)
        row = 'b6' if s5 & 0x40 else ('b7' if s5 & 0x80 else 'b-')
        sure = 'sure' if (b0.db42[a] & 4 and tag != 'h_ultra') else ''
        lab.append(f'roll L{lev} {row} {sure}'.strip())
    if out != 'ok':
        if tag == 'h_ultra' and b0.dfn[t] == 1 and b0.agl[t] == 1 and b0.stb(t, 3) & 2:
            out += ' (6612: DEF=AGL=1+Surround)'
        if tag == 'h_upper':
            d = b0.dfn[t]; cap = b0.base['dfn'][t] * F.cap_mult(b0, t)
            out += ' (at999)' if d >= 999 else (' (atcap)' if d == cap else ' (abovecap)')
        if tag == 'h_speed':
            g = b0.agl[t]; cap = b0.base['agl'][t] * F.cap_mult(b0, t)
            out += ' (at511)' if g >= 511 else (' (atcap)' if g == cap else ' (abovecap)')
        lab.append(out)
        return lab
    if tag == 'h_sap':
        d, h = b0.dfn[t], b0.base['dfn'][t] >> 1
        lab.append('sub' if d > h else ('to0-exact' if d == h else 'floor0-borrow'))
    if tag == 'h_slow':
        g, h = b0.agl[t], b0.base['agl'][t] >> 1
        lab.append('sub' if g > h else ('eq(-1)' if g == h else 'borrow->1'))
    if tag == 'h_upper':
        d, h = b0.dfn[t], b0.base['dfn'][t] >> 1
        cap = b0.base['dfn'][t] * F.cap_mult(b0, t); n = d + h
        lab.append(f"x{F.cap_mult(b0, t)} " + ('add' if n < min(cap, 999) else
                   ('=cap' if n == cap and n < 999 else ('=999' if n == 999 else
                   ('clamp999' if n > 999 else 'clampcap')))) + (' 999>cap' if n > 999 and cap < 999 else ''))
    if tag == 'h_speed':
        g, h = b0.agl[t], b0.base['agl'][t] >> 1
        cap = b0.base['agl'][t] * F.cap_mult(b0, t); n = g + h
        lab.append(f"x{F.cap_mult(b0, t)} " + ('add' if n < min(cap, 511) else
                   ('clamp511' if n >= 511 else 'clampcap')) + (' 511>cap' if n >= 511 and cap < 511 else ''))
    if tag == 'h_ultra':
        lab.append('def->1' if b0.dfn[t] <= max(b0.base['dfn'][t] >> 1, 1) else 'def-sub')
        lab.append('agl->1' if b0.agl[t] <= max(b0.base['agl'][t] >> 1, 1) else 'agl-sub')
        lab.append('sur-set' if b0.stb(t, 3) & 2 else 'sur-new')
    if tag == 'h_surge':
        lab.append(('lowered' if F.marker(b0, t) & 0x80 else 'notlowered') +
                   (' +2' if b0.stb(t, 2) else '') + (' sleep/conf' if b0.stb(t, 2) & 0x90 else '') +
                   (' +3' if b0.stb(t, 3) & 0xC3 else '') + (' +7' if b0.stb(t, 7) & 3 else ''))
    return lab


def tally(kind, ok, detail=None):
    s = stats.setdefault(kind, [0, 0])
    s[0 if ok else 1] += 1
    if not ok:
        fails.append((kind, detail))
        if VERBOSE:
            print('FAIL', kind, detail)


def st16(e):
    return (e['rng1'] << 8) | e['rng2']


def base_of(e, s, k):
    """bank $57 entries 4-8 source: party (and slot 3/7) record, enemy row."""
    if s < 3:
        r = e['rec'][s]
        return r[k] if r else 0
    if s in (3, 7):
        return 0                                   # helper slots: not in corpus
    row = ROWS.get(e['eid'][s - 4])
    if not row:
        return 0
    return dict(maxhp=row['hp'], maxmp=row['mp'], atk=row['atk'], dfn=row['def'],
                agl=row['agl'], int=row['int'])[k]


def board(e):
    b = B.Board.from_event(e)
    b.maxmp = list(e['maxmp'])
    for k in b.base:
        b.base[k] = [base_of(e, s, k) for s in range(8)]
    b.base['maxhp'] = [min(v, 999) for v in b.base['maxhp']]
    b.ext['f7_db40'] = e['db40'][0]
    return b


def markers(st, db40):
    return [st[8 + 8 * t] & 0xC0 for t in range(7)] + [db40 & 0xC0]


def chainview(e):
    return dict(dfn=list(e['dfn']), agl=list(e['agl']), atk=list(e['atk']),
                mk=markers(e['st'], e['db40'][0]))


def bview(b):
    return dict(dfn=list(b.dfn), agl=list(b.agl), atk=list(b.atk),
                mk=markers(b.st, b.ext.get('f7_db40', 0)))


def span_end(evs, i, tag):
    """Index of the handler's post waypoint and the outcome tag seen."""
    out = 'ok'
    for j in range(i + 1, len(evs)):
        t = evs[j]['tag']
        if t in ('fail', 'rollmiss', 'already'):
            out = t
        if t == 'h_ret':
            if tag == 'h_ultra' and out == 'ok':
                for k in range(j + 1, len(evs)):
                    if evs[k]['tag'] == 'ud_end':
                        return k, out
                    if evs[k]['tag'] in ('actor_fetch', 'round_start'):
                        return None, out
            if tag == 'h_transform':
                for k in range(j + 1, len(evs)):
                    if evs[k]['tag'] == 'tf_done':
                        return k, out
                    if evs[k]['tag'] in ('actor_fetch', 'round_start'):
                        return None, out
            return j, out
    return None, out


def check_battle(sc, evs):
    chain = None
    in_span_until = -1
    pending_chain = None
    for i, e in enumerate(evs):
        tag = e['tag']
        # ---------------- battle start: base sources ---------------------
        if tag == 'round_start' and chain is None:
            poked = {(x[0], x[1]) for x in e.get('pk', [])}
            for s in range(8):
                if e['dd1b'][s] == 0 and s not in (3, 7):
                    for k, ek in (('dfn', 'dfn'), ('agl', 'agl'), ('atk', 'atk'), ('int', 'int')):
                        if (s, k) in poked:
                            continue          # rig poke (branch coverage), not a source
                        tally('base_src', e[ek][s] == base_of(e, s, k),
                              dict(sc=sc, s=s, k=k, battle=e[ek][s], src=base_of(e, s, k)))
            for s in (1, 2):                  # --php/--pmp/--ehp/--emp poke slot 0 / enemies only
                if e['dd1b'][s] == 0:
                    for k in ('maxhp', 'maxmp'):
                        tally('base_src', e[k][s] == base_of(e, s, k),
                              dict(sc=sc, s=s, k=k, battle=e[k][s], src=base_of(e, s, k)))
            chain = chainview(e)
        # ---------------- chain (persistence / no other writer) ----------
        if i > in_span_until and pending_chain is not None:
            chain = pending_chain; pending_chain = None
        if tag in ('round_start', 'actor_fetch') and chain is not None and i > in_span_until:
            got = chainview(e)
            tally('chain', got == chain, dict(sc=sc, i=i, tag=tag, got=got, pred=chain))
            chain = got                     # resync (keeps one fault from cascading)
        # ---------------- base reads -------------------------------------
        if tag in ('base_def', 'base_agl'):
            k = 'dfn' if tag == 'base_def' else 'agl'
            tally('base', e['dd72'] == base_of(e, e['db89'], k),
                  dict(sc=sc, i=i, t=e['db89'], k=k, eng=e['dd72'], src=base_of(e, e['db89'], k)))
        # ---------------- order ------------------------------------------
        if tag == 'round_start':
            af = next((x for x in evs[i + 1:] if x['tag'] in ('actor_fetch', 'round_start')), None)
            if af is not None and af['tag'] == 'actor_fetch':
                b = B.Board.from_event(e)
                got = [x for x in af['db79'] if x != 0xFF]
                pred, _ = B.round_order(b, st16(e), e['db71'], 0xFF)
                buffed = any(e['dd1b'][s] == 0 and s not in (3, 7) and e['agl'][s] != base_of(e, s, 'agl')
                             for s in range(8))
                tally('order_buffed' if buffed else 'order', pred == got,
                      dict(sc=sc, i=i, got=got, pred=pred, agl=e['agl']))
        # ---------------- dodge ------------------------------------------
        if tag == 'miss_rng':
            route = next((x['tag'] for x in evs[i + 1:] if x['tag'] in ('dodge', 'miss', 'block', 'miss_pass')), None)
            sk = e['db8a']; rec = RECORDS.get(sk)
            if route and rec and sk < 0xE4:
                f = rec['battle_record']['fields']
                a, t = e['db88'], e['db89']
                b = B.Board.from_event(e)
                if sk == 0x41 and not (b.stb(a, 6) & 3):
                    pass                       # LoadBtlC_5857 skip (not modelled here)
                else:
                    pm = B.miss_gate(b, a, t, f.get('flags7', 0), f.get('flags8', 0), st16(e))
                    pm = 'miss_pass' if pm == 'pass' else pm
                    buffed = e['agl'][t] != base_of(e, t, 'agl') or bool(e['st'][t * 8 + 3] & 2) \
                        or bool(e['st'][a * 8 + 3] & 2)
                    tally('dodge_buffed' if buffed else 'dodge', pm == route,
                          dict(sc=sc, i=i, a=a, t=t, sk=hex(sk), pred=pm, got=route, agl=e['agl'][t]))
        # ---------------- victims (tm 18/34 sweeps) ----------------------
        if tag == 'actor_fetch':
            tfs = []
            for x in evs[i + 1:]:
                if x['tag'] in ('actor_fetch', 'round_start'):
                    break
                if x['tag'] == 'target_fetch':
                    tfs.append(x)
            if tfs and tfs[0]['db8a'] in F.PER_VICTIM:
                sk = tfs[0]['db8a']
                tm = RECORDS[sk]['battle_record']['fields']['target_mode']
                if tm in (18, 34):
                    b = B.Board.from_event(tfs[0]); t0 = tfs[0]['db89']
                    pred = B.side_victims(b, t0, start=t0)
                    got = [x['db89'] for x in tfs]
                    tally('victims', pred == got, dict(sc=sc, i=i, sk=hex(sk), got=got, pred=pred))
        # ---------------- handler calls ----------------------------------
        if tag in H_TAGS:
            j, out = span_end(evs, i, tag)
            if j is None:
                continue
            post = evs[j]
            b = board(e)
            a, t, sk = e['db88'], e['db89'], e['db8a']
            where = dict(sc=sc, i=i, tag=tag, sk=hex(sk), a=a, t=t)
            # the MISS machine's stepped RNG reaches the handler untouched
            # (same frame) -> the round driver's default_victims order is right
            mr = next((x for x in reversed(evs[max(0, i - 8):i]) if x['tag'] == 'miss_rng'), None)
            if mr is not None and mr['frame'] == e['frame']:
                tally('pre_rng', st16(mr) == st16(e), dict(where, mr=hex(st16(mr)), h=hex(st16(e))))
            if tag == 'h_transform':
                F.transform_mark(b, a)
                F.transform_stats(b, a, t)
                pout, amt, state = 'ok', None, st16(e)
            else:
                pout, amt, state = H_TAGS[tag](b, a, t, st16(e))
            tally('outcome', pout == out, dict(where, pred=pout, got=out))
            for lab in classify(tag, e, board(e), a, t, out):
                key = (tag, 'enemy' if a >= 4 else 'party', lab)
                cover[key] = cover.get(key, 0) + 1
            if pout != out:
                continue
            if pout == 'ok' and tag in ('h_sap', 'h_upper', 'h_slow', 'h_speed'):
                tally('amount', post['db56'] == amt, dict(where, pred=amt, got=post['db56']))
            if pout == 'ok' and tag == 'h_ultra':
                ea = next(x for x in evs[i:j + 1] if x['tag'] == 'ud_agl')
                es = next(x for x in evs[i:j + 1] if x['tag'] == 'ud_sur')
                # subs 0/1 always write $DB56 = their BC (also when 0)
                tally('amount', (ea['db56'], es['db56']) == amt,
                      dict(where, pred=amt, got=(ea['db56'], es['db56'])))
            for k in KEYS:
                tally('stats', list(post[k]) == list(getattr(b, k)),
                      dict(where, k=k, pred=list(getattr(b, k)), got=post[k]))
            tally('status', list(post['st']) == b.st and post['db40'][0] == b.ext.get('f7_db40', 0),
                  dict(where, pred=b.st, got=post['st'],
                       diff=[(n, b.st[n], post['st'][n]) for n in range(64) if b.st[n] != post['st'][n]]))
            if tag == 'h_surge':
                tally('dd13', list(post['dd13']) == b.dd13, dict(where, pred=b.dd13, got=post['dd13']))
            if post['frame'] == e['frame'] and tag not in ('h_ultra', 'h_transform'):
                tally('rng', st16(post) == state, dict(where, pred=hex(state), got=hex(st16(post))))
            in_span_until = j
            pending_chain = bview(b)


def main():
    evs = json.load(open(CORPUS))
    by = {}
    for e in evs:
        by.setdefault(e['sc'], []).append(e)
    for sc, ev in by.items():
        check_battle(sc, ev)
    n = sum(v[0] + v[1] for v in stats.values()); m = sum(v[1] for v in stats.values())
    for k, (ok, bad) in sorted(stats.items()):
        print(f'  {k:13s} {ok:5d} ok {bad:4d} mismatch')
    hand = {}
    for e in evs:
        if e['tag'] in H_TAGS:
            hand[(e['tag'], e['db88'] >= 4)] = hand.get((e['tag'], e['db88'] >= 4), 0) + 1
    print('  handler calls (tag, enemy caster):', dict(sorted(hand.items())))
    if '-c' in sys.argv:
        for k, v in sorted(cover.items()):
            print('  cover', k, v)
    print(f'battles {len(by)}; TOTAL {n} comparisons, {m} mismatches')
    if not VERBOSE:
        for f in fails[:15]:
            print('FAIL', f)
    sys.exit(1 if m else 0)


if __name__ == '__main__':
    main()
