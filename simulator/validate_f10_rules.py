#!/usr/bin/env python3
"""S130 F10 AI-chain validator: every bank $57 cat-2 chain run for DeMagic
$80 / ThickFog $83 captured by simulator/measure_f10_rules.py (corpus
simulator/f10_rules_events.json.gz, boards from simulator/f10_rules_recipe.py)
replayed through ai_rules.evaluate_chain with the captured board; the
(delta, veto) at the chain end ($78A2: delta = $DD26 - $DD27, borrow =
veto) or the veto ($788B) is diffed. Also reports which rule moved the
accumulators (coverage) per branch.

Usage: python3 simulator/validate_f10_rules.py [corpus.json] [-v]
"""
import gzip, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ai_rules as R

RECS = {r['id']: r for r in json.load(open(os.path.join(HERE, '..', 'extracted', 'skill_records.json')))['records']}
args = [x for x in sys.argv[1:] if not x.startswith('-')]
CORPUS = args[0] if args else os.path.join(HERE, 'f10_rules_events.json.gz')
VERBOSE = '-v' in sys.argv


def view_of(bd):
    st = bd['st']
    blocks = [st[8 * s:8 * s + 8] for s in range(8)]
    res = bd['res']
    skills = [[(bd['dc64'][16 * s + 2 * j], bd['dc64'][16 * s + 2 * j + 1]) for j in range(8)] for s in range(8)]
    return R.BattleView(bd['hp'], bd['mhp'], bd['mp'], bd['mmp'], blocks, bd['dd1b'], [0] * 8, [None] * 8,
                        lambda s, e: (res[s * 7 + (e >> 2)] >> ((3 - (e & 3)) * 2)) & 3,
                        skills=skills, dd0b=bd['dd0b'], db40=(st[64], st[65]))


def main():
    evs = json.load(gzip.open(CORPUS, 'rt') if CORPUS.endswith('.gz') else open(CORPUS))
    ok = bad = 0
    cover, fails = {}, []
    for i, e in enumerate(evs):
        if e['t'] != 'skl' or e['skill'] not in (0x80, 0x83):
            continue
        moved, out, called = [], None, set()
        cur = pre = None
        for x in evs[i + 1:]:
            if x['t'] == 'rul':
                cur, pre = x['rule'], (x['dd26'], x['dd27'])
                called.add('%04x' % cur)
            elif x['t'] == 'ret' and cur is not None and (x['dd26'], x['dd27']) != pre:
                moved.append('%04x' % cur)
            elif x['t'] == 'vet':
                out = (0, True); break
            elif x['t'] == 'end':
                out = (0, True) if x['dd26'] < x['dd27'] else ((x['dd26'] - x['dd27']) & 0xFF, False)
                break
            elif x['t'] == 'skl':
                break
        if out is None:
            continue
        sk, a = e['skill'], e['ai']
        f = RECS[sk]['battle_record']['fields']
        bd = e['board']
        # the chain is picked by the option-list TAG ($DC64 pair), not the
        # record: keep the cat-2 runs (the real tag of $80/$83 = record
        # effect_category $23 >> 4); the random lists also tag them 1/3
        tags = {bd['dc64'][16 * a + 2 * j] for j in range(8) if bd['dc64'][16 * a + 2 * j + 1] == sk}
        if tags != {2}:
            continue
        # AIRule_4c13 reads the res level at the record's +5 element (0 here):
        # it can only veto when every live opponent has level 3 at position 0
        assert all((bd['res'][s * 7] >> 6) == 0 for s in range(8)), 'res pos 0 nonzero'
        got = R.evaluate_chain(2, sk, a, view_of(bd), f['mp_cost_byte'], f['status_id'], e['dd6b'])
        key = (hex(sk), 'dd0b=%d' % bd['dd0b'][a], 'veto' if out[1] else 'pass', ','.join(moved) or '-')
        cover[key] = cover.get(key, 0) + 1
        if got == out:
            ok += 1
        else:
            bad += 1
            fails.append(dict(sc=e['sc'], rnd=e['rnd'], a=a, sk=hex(sk), exp=out, got=got, moved=moved))
    for k, v in sorted(cover.items()):
        print('  cover', k, v)
    print(f'F10 rule-chain validation: OK {ok}  MISMATCH {bad}')
    for x in fails[:20]:
        print('FAIL', x)
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
