#!/usr/bin/env python3
"""S130 F10 differential validator — DeMagic $80 / ThickFog $83 / FILTHZONE
$A5 (simulator/skillfx/f10_dispel.py) against the engine captures of
simulator/measure_f10.py (corpus simulator/f10_events.json.gz).

Per dispel action (the S85 method: the engine's board and RNG are injected at
the handler entry waypoint $52:$4BA1; the model's prediction is diffed against
the machine's end waypoint $53:$6252, after every sub-state has run):
  pre_rng   the RNG at the handler == the MISS machine's post-step RNG
            (same frame), and the MISS machine passed
  visits    the slots the machine visits, in order (dm_s0 / dm_s6 targets
            and the second pass of ThickFog/FILTHZONE) and the path of each
            (skip / base = DispelBaseDefAgl_647c / revert =
            DispelRevertStats_626b / dismiss = DispelDismissHelper_650c)
  status    the 64-byte status area + $DB40/$DB41 at the end
  stats     HP/MaxHP/MP/MaxMP/ATK/DEF/AGL/INT of all 8 slots at the end
  dd13      $DD13 (iron / revert 'loses the turn' writes, dismiss $FF)
  dd1b      $DD1B (dismiss $FF)
  res       the resistance array is untouched (also across a revert)
  driver    battle.ACTION_HANDLERS[sk] (default_victims: one MISS step on the
            resolved target, then the machine) from the pre-step RNG gives the
            same board and the MISS machine's RNG
  level     $DB9B (the party revert writes the source level at slot 2t)
  aiw       the AI weights $DC44/$DC4C/$DC54/$DC5C (likewise at slot 2t)
Propagation:
  chain     the side bytes' bit3 (the ThickFog seal) at every round_start /
            actor_fetch == the model chain (phase 9 never clears it; only the
            machine's s7 writes it)
  seal_veto a live actor whose queued skill has record flags7 bit6 while its
            side is sealed does not act (no target fetch) and PAYS the cost,
            floor 0 (SaveBtlC_4b4f on the $1F path; battle.act_mp_veto -> $1F)
  seal_redecide  ... unless its $DD0B == 2: LoadBtlC_490a re-decides (it
            acts with another skill, MP kept)
  lost_turn a slot the machine set to $DD13 = 3 before its turn does not act
            later in that round
  t4_80     the act-state-4 row for $80 ($52:$7A49) is never reached
  resolve   a re-resolving caster (battle.reresolves) acts on its bank $58
            row (RERESOLVE_PICKERS: $80 $62BF, $83/$A5 $62FD)

Usage: python3 simulator/validate_f10.py [corpus.json] [-v]
"""
import gzip, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import battle as B
from simulator.skillfx import f10_dispel as F

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECORDS = {r['id']: r for r in json.load(open(os.path.join(ROOT, 'extracted', 'skill_records.json')))['records']}
ROWS = {e['enemy_stats_id']: e for e in json.load(open(os.path.join(ROOT, 'extracted', 'enemy_stats.json')))}
VERBOSE = '-v' in sys.argv
args = [x for x in sys.argv[1:] if not x.startswith('-')]
CORPUS = args[0] if args else os.path.join(ROOT, 'simulator', 'f10_events.json.gz')
STATS = ('hp', 'maxhp', 'mp', 'maxmp', 'atk', 'dfn', 'agl', 'int')
PATH_TAGS = {'dm_basedef': 'base', 'dm_revert': 'revert', 'dm_dismiss': 'dismiss'}
stats, fails, cover = {}, [], {}


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
    """the revert / DEF-AGL reset source: party record, enemy_stats row."""
    if s < 3:
        r = e['rec'][s]
        return r[k] if r else 0
    if s in (3, 7):
        return 0                    # helper slots: never reach s3 (walk ends at t&3 == 2)
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
    b.ext['f7_db40'] = e['db40'][0]
    b.ext['f10_db41'] = e['db40'][1]
    # the revert's level / AI-weight source: party record (+$4B, +$64..$67),
    # enemy row (the battle-start values; the enemy path is a no-op)
    lv = list(e['db9b']); bases = [None] * 3
    for s in range(3):
        r = e['rec'][s]
        if r and 'level' in r:
            lv[s] = r['level']; bases[s] = tuple(r['aiw'])
    b.ext['f10_src'] = dict(level=lv, bases=bases)
    return b


AIW = ('dc44', 'dc4c', 'dc54', 'dc5c')


def pred_aiw(e, b):
    out = [list(x) for x in e['aiw']]
    for (arr, idx), v in b.ext.get('f10_aiw', {}).items():
        n, i = AIW.index(arr), idx
        while i >= 8:                       # aliases the next array (link only)
            n, i = n + 1, i - 8
        if n < 4:
            out[n][i] = v
    return out


def seals(e):
    return [(e['st'][0] >> 3) & 1, (e['st'][1] >> 3) & 1]


def machine_span(evs, i):
    """(end index, engine visits) of the dispel machine started by the
    handler at i: dm_s0 / dm_s6 targets, each with the path waypoint seen."""
    visits = []
    for j in range(i + 1, len(evs)):
        x = evs[j]; tag = x['tag']
        if tag == 'dm_s0':
            visits.append([x['db89'], 'skip'])
        elif tag == 'dm_strip' and visits:
            visits[-1][1] = 'strip'
        elif tag in PATH_TAGS and visits:
            if tag == 'dm_dismiss':
                visits.append([x['db89'], 'dismiss'])
            else:
                visits[-1][1] = PATH_TAGS[tag]
        elif tag == 'dm_end':
            return j, [tuple(v) for v in visits]
        elif tag in ('actor_fetch', 'round_start'):
            return None, visits
    return None, visits


def check_battle(sc, evs):
    chain = None            # predicted side seals
    lost = {}               # slot -> round index made to lose its turn
    rnd = -1
    acted = {}              # round -> set of attackers that reached target fetch
    rstarts = []
    for i, e in enumerate(evs):
        tag = e['tag']
        if tag == 'round_start':
            rnd += 1; rstarts.append(i)
        if tag == 'target_fetch':
            acted.setdefault(rnd, set()).add(e['db88'])
        if tag == 't4_80':
            tally('t4_80', False, dict(sc=sc, i=i))
        # ---------------- seal chain -------------------------------------
        if tag in ('round_start', 'actor_fetch'):
            got = seals(e)
            if chain is not None:
                tally('chain', got == chain, dict(sc=sc, i=i, tag=tag, got=got, pred=chain))
            chain = got
        # ---------------- the dispel action ------------------------------
        if tag == 'h_dispel':
            j, eng_visits = machine_span(evs, i)
            if j is None:
                continue
            post = evs[j]
            a, t, sk = e['db88'], e['db89'], e['db8a']
            where = dict(sc=sc, i=i, sk=hex(sk), a=a, t=t)
            mr = next((x for x in reversed(evs[max(0, i - 6):i]) if x['tag'] == 'miss_rng'), None)
            mp = next((x for x in evs[max(0, i - 6):i] if x['tag'] in ('miss_pass', 'miss', 'dodge', 'block')), None)
            tally('pre_rng', mr is not None and mr['frame'] == e['frame'] and st16(mr) == st16(e)
                  and mp is not None and mp['tag'] == 'miss_pass', dict(where, mr=mr and hex(st16(mr))))
            # the act-time target: a re-resolving caster gets its bank $58 row
            b0 = board(e)
            if b0.q_target(a) != 0xFF and B.reresolves(b0, a, sk):
                pt, _ = B.RERESOLVE_PICKERS[sk](b0, a, 0)
                tally('resolve', pt == t, dict(where, pred=pt, queued=b0.q_target(a)))
            b = board(e)
            pred = F.dispel_machine(b, a, t, sk)
            # the engine's s0 marks 'strip' before the path waypoint; the model
            # reports base/revert for a stripped slot: compare like with like
            pv = [(s, p) for s, p in pred]
            ev = [(s, ('base' if p == 'strip' else p)) for s, p in eng_visits]
            tally('visits', pv == ev, dict(where, pred=pv, got=ev))
            for s, p in pv:
                key = (hex(sk), 'enemy' if a >= 4 else 'party', p)
                cover[key] = cover.get(key, 0) + 1
            st_ok = list(post['st']) == b.st and post['db40'] == [b.ext.get('f7_db40', 0), b.ext.get('f10_db41', 0)]
            tally('status', st_ok, dict(where, diff=[(n, hex(b.st[n]), hex(post['st'][n])) for n in range(64)
                                                     if b.st[n] != post['st'][n]],
                                       db40=(post['db40'], b.ext.get('f7_db40'), b.ext.get('f10_db41'))))
            for k in STATS:
                tally('stats', list(post[k]) == list(getattr(b, k)),
                      dict(where, k=k, pred=list(getattr(b, k)), got=post[k]))
            tally('dd13', list(post['dd13']) == b.dd13, dict(where, pred=b.dd13, got=post['dd13']))
            tally('dd1b', list(post['dd1b']) == b.dd1b, dict(where, pred=b.dd1b, got=post['dd1b']))
            tally('res', post['res'] == e['res'], dict(where))
            # the round-driver wiring: ACTION_HANDLERS[sk] (MISS step on the one
            # resolved target, then the machine) from the pre-step RNG
            if mr is not None:
                bd = board(e)
                pre = ((st16(mr) - 0x1357) * 52429) & 0xFFFF       # inverse LCG step
                ctx = B.ActionCtx(b=bd, a=a, sk=sk, rec=RECORDS[sk], f=RECORDS[sk]['battle_record']['fields'],
                                  core='dispel', t=t, qt=t, state=pre, records=RECORDS, log=[],
                                  idle=lambda x, c: x, real_sk=sk)
                out = B.ACTION_HANDLERS[sk](ctx)
                tally('driver', out == st16(mr) and bd.st == b.st and bd.dfn == b.dfn and bd.agl == b.agl
                      and bd.hp == b.hp and bd.dd13 == b.dd13 and bd.dd1b == b.dd1b and bd.level == b.level,
                      dict(where, log=ctx.log))
            tally('level', post['db9b'] == b.level, dict(where, pred=b.level, got=post['db9b']))
            tally('aiw', post['aiw'] == pred_aiw(e, b), dict(where, pred=pred_aiw(e, b), got=post['aiw']))
            for s in range(8):
                if e['dd13'][s] == 2 and b.dd13[s] == 3 and s != a:
                    lost[s] = rnd
            chain = [(b.st[0] >> 3) & 1, (b.st[1] >> 3) & 1]     # the model's seals from here on
    # ---------------- per-round propagation checks ------------------------
    rstarts.append(len(evs))
    for r in range(len(rstarts) - 1):
        e0 = evs[rstarts[r]]
        seg = evs[rstarts[r]:rstarts[r + 1]]
        if not any(x['tag'] == 'round_end' for x in seg):
            continue                        # battle ended mid-round / capture cut
        did = acted.get(r, set())
        for s, rr in lost.items():
            if rr == r:
                tally('lost_turn', s not in did, dict(sc=sc, r=r, s=s))
        for s in range(8):
            if not (e0['dd1b'][s] == 0 and e0['dd13'][s] == 2):
                continue
            sk = e0['dcec'][2 * s]
            rec = RECORDS.get(sk)
            if not rec:
                continue
            f = rec['battle_record']['fields']
            if not (f['flags7'] & 0x40):
                continue
            # the seal at THIS actor's turn: the last seal snapshot before its fetch
            sealed_now = None
            for x in seg:
                if x['tag'] == 'target_fetch' and x['db88'] == s:
                    break
                sealed_now = seals(x)[(s >> 2) & 1]
            if sealed_now and e0['dd0b'][s] == 2:
                # LoadBtlC_490a: a $DD0B==2 actor RE-DECIDES ($D9ED := $16, $DD13 := 1)
                # before paying — it acts with a new (non-sealed) choice, MP kept
                tf = next((x for x in seg if x['tag'] == 'target_fetch' and x['db88'] == s), None)
                mp_at = tf['mp'][s] if tf else None
                tally('seal_redecide', tf is not None and tf['db8a'] != sk and mp_at == e0['mp'][s],
                      dict(sc=sc, r=r, s=s, sk=hex(sk), tf=tf and hex(tf['db8a'])))
            elif sealed_now:
                # SaveBtlC_4b4f PAYS the cost (floor 0), then $1F: no action
                mp_end = seg[-1]['mp'][s]
                pay = max(0, e0['mp'][s] - f['mp_cost_byte'])
                tally('seal_veto', s not in did and mp_end == pay,
                      dict(sc=sc, r=r, s=s, sk=hex(sk), did=s in did, mp=(e0['mp'][s], mp_end, pay)))
                cover[('seal_veto', 'enemy' if s >= 4 else 'party', 'sealed')] = \
                    cover.get(('seal_veto', 'enemy' if s >= 4 else 'party', 'sealed'), 0) + 1



def main():
    evs = json.load(gzip.open(CORPUS, 'rt') if CORPUS.endswith('.gz') else open(CORPUS))
    by = {}
    for e in evs:
        by.setdefault(e['sc'], []).append(e)
    for sc, ev in by.items():
        check_battle(sc, ev)
    n = sum(v[0] + v[1] for v in stats.values()); m = sum(v[1] for v in stats.values())
    for k, (ok, bad) in sorted(stats.items()):
        print(f'  {k:10s} {ok:5d} ok {bad:4d} mismatch')
    hand = {}
    for e in evs:
        if e['tag'] == 'h_dispel':
            k = (hex(e['db8a']), 'enemy' if e['db88'] >= 4 else 'party')
            hand[k] = hand.get(k, 0) + 1
    print('  dispel actions (skill, caster):', dict(sorted(hand.items())))
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
