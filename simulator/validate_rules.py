#!/usr/bin/env python3
"""S81 rule-chain differential validator.

Replays every decision in simulator/s81_sweep_corpus.json (the full-skill
sweep of the bank $57 evaluator chains, captured by sweep_rules.py on the
S75v4 patched build + user .sav boot state) through ai_rules.evaluate_chain
and diffs the (delta, veto) outcome against the engine's own chain-end /
veto values. Exit 1 on any mismatch.

Board synthesis mirrors the sweep driver's forces exactly: party = Slib
(slime, slot 0, 28 HP / 88 MP), enemy = Gremlin EID 7 (slot 4, 26 HP,
MP forced 250/250 by the driver; two-enemy runs add a clone at slot 5).
Two-enemy captures are actor-ambiguous (both enemies decide; first
occurrence kept), so the slot-5 profile (natural 9/9 MP) is accepted as
an alternate — see BATTLE_SKILL_SYSTEM §15.10.5.

S81 result: 240/240.
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ai_rules as R

recs = json.load(open(os.path.join(HERE, '..', 'extracted',
                                   'skill_records.json')))
recs = recs if isinstance(recs, list) else recs['records']
rec_by = {r['id']: r for r in recs}


def mkview(hp, mhp, mp, mmp, st, dd1b):
    fams = [0, None, None, None, 6, 6, None, None]
    return R.BattleView(hp, mhp, mp, mmp, st, dd1b, [0] * 8, fams,
                        lambda s, e: 0)


def board_for(board, two_enemies):
    hp = [28, 0, 0, 0, 26, 0, 0, 0]
    mhp = [28, 0, 0, 0, 26, 0, 0, 0]
    mp = [88, 0, 0, 0, 250, 0, 0, 0]
    mmp = [88, 0, 0, 0, 250, 0, 0, 0]
    st = [[0] * 8 for _ in range(8)]
    dd1b = [0, 0xFF, 0xFF, 0xFF, 0, 0xFF, 0xFF, 0xFF]
    if two_enemies:
        mhp[5] = 60; hp[5] = 60; dd1b[5] = 0
    if board == 'psleep':
        st[0][2] = 0x8C
    elif board == 'ppoison':
        st[0][2] = 0x01
    elif board == 'epoison':
        st[4][2] = 0x01
    elif board == 'eparalyze':
        st[4][2] = 0x40
    elif board == 'econfusion':
        st[4][2] = 0x10
    elif board == 'ecurse':
        st[4][2] = 0x20
    elif board == 'ehurt':
        mhp[4] = 200; hp[4] = 30
    elif board == 'elowmp':
        mp[4] = 10
    elif board == 'allydead':
        hp[5] = 0; mhp[5] = 60
    elif board == 'allypara':
        st[5][2] = 0x40
    elif board == 'allyconf':
        st[5][2] = 0x10
    elif board == 'allyhurt':
        mhp[5] = 200; hp[5] = 30
    return hp, mhp, mp, mmp, st, dd1b


def main():
    corpus = json.load(open(os.path.join(HERE, 's81_sweep_corpus.json')))
    ok = bad = 0
    fails = []
    for name, entry in sorted(corpus.items()):
        board, two = entry['board'], entry['two_enemies']
        for sid, info in entry['results'].items():
            sid = int(sid)
            fired = info['fired']
            if not fired:
                continue
            last = fired[-1]
            if last[0] == 'vet':
                exp = (0, True)
            elif last[0] == 'end':
                b, p = last[1], last[2]
                exp = (0, True) if b < p else ((b - p) & 0xFF, False)
            else:
                continue
            hp, mhp, mp, mmp, st, dd1b = board_for(board, two)
            r = rec_by.get(sid)
            cost = r.get('mp_cost', 0) if r else 0
            if not isinstance(cost, int):
                cost = 0
            args = (info['cat'], sid, 4)
            got = R.evaluate_chain(*args,
                                   mkview(hp, mhp, mp, mmp, st, dd1b),
                                   cost, 1, info['dd6b'])
            alt = got
            if two:
                mp2, mmp2 = mp[:], mmp[:]
                mp2[4] = mmp2[4] = 9
                alt = R.evaluate_chain(*args,
                                       mkview(hp, mhp, mp2, mmp2, st,
                                              dd1b),
                                       cost, 1, info['dd6b'])
            if got == exp or alt == exp:
                ok += 1
            else:
                bad += 1
                fails.append((name, sid,
                              r['name'] if r else '?', exp, got))
    print(f'S81 rule-chain validation: OK {ok}  MISMATCH {bad}')
    for x in fails[:30]:
        print(' ', x)
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
