#!/usr/bin/env python3
"""S163 rule-chain validator on BOARDS OF 1-3 OPPONENTS (ROADMAP E17 note "the S81 rule model
on 3-opponent boards").

The S81 sweep (s81_sweep_corpus.json, validate_rules.py) had ONE party monster: membership
sets that a rule's condition withheld on that board looked like "not a member" (S161 found
Sleep +40 / Sap +30 / BoltSlash +25 / PsycheUp vetoed in the ROM where the model said 0 / 0 /
+35 / +35). simulator/sweep_rules.py (S163: --party-live / --party-act, and the BOARD the
rules read captured at each chain start) ran every cat-1/2/3 skill through the real chains on
the user's save (three party monsters) with 3 / 2 / 1 of them alive, defending or attacking:
simulator/s163_board_corpus.json.gz. This replays each chain end through
ai_rules.evaluate_chain on the captured board and diffs (delta, veto); exit 1 on any mismatch.

    python3 simulator/validate_rules_boards.py [--corpus FILE] [--show N]
    python3 simulator/validate_rules_boards.py --build DIR...   # (re)make the corpus from
                                                                #  sweep_rules.py outputs
"""
import argparse
import gzip
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ai_rules as R                                              # noqa: E402

CORPUS = os.path.join(HERE, 's163_board_corpus.json.gz')
recs = json.load(open(os.path.join(HERE, '..', 'extracted', 'skill_records.json')))
recs = recs if isinstance(recs, list) else recs['records']
REC = {r['id']: r for r in recs}


MF = json.load(open(os.path.join(HERE, '..', 'extracted', 'monsters_full.json')))


def _words(w, base):
    return [w[base - 0xC000 + 2 * s] | w[base - 0xC000 + 2 * s + 1] << 8 for s in range(8)]


def view_of(b):
    """The rules' board: the captured fields; with the WRAM image (S163 --wram) also the
    battle stats ATK $DBE3 / DEF $DBF3 / AGL $DC03 and each slot's species $DC3C -> its
    family / traits (monsters_full: family_id; metal bit 0, flying bit 4)."""
    res = b['res']
    atk = dfn = agl = None
    fams, traits = [None] * 8, [0] * 8
    if 'wram' in b:
        w = bytes.fromhex(b['wram'])
        atk, dfn, agl = _words(w, 0xDBE3), _words(w, 0xDBF3), _words(w, 0xDC03)
        for s_ in range(8):
            sp = w[0xDC3C - 0xC000 + s_]
            if sp < len(MF):
                fams[s_] = MF[sp].get('family_id')
                traits[s_] = (1 if MF[sp].get('is_metal') else 0) | (0x10 if MF[sp].get('can_fly') else 0)
    return R.BattleView(b['hp'], b['mhp'], b['mp'], b['mmp'], [row[:8] for row in b['st']],
                        b['dd1b'], traits, fams,
                        lambda s_, e: (res[s_ * 7 + (e >> 2)] >> ((3 - (e & 3)) * 2)) & 3,
                        skills=[[(o[2 * k], o[2 * k + 1]) for k in range(8)] for o in b['opts']],
                        dd0b=b['dd0b'], db40=tuple(b['db40']), atk=atk, dfn=dfn, agl=agl)


def expected(fired):
    last = fired[-1]
    if last[0] == 'vet':
        return (0, True)
    b, p = last[1], last[2]
    return (0, True) if b < p else ((b - p) & 0xFF, False)


def replay(corpus):
    ok, bad = 0, []
    for name, entry in sorted(corpus.items()):
        for sid, info in sorted(entry['results'].items(), key=lambda kv: int(kv[0])):
            sid = int(sid)
            fired = info['fired']
            if not fired or fired[-1][0] not in ('end', 'vet') or 'board' not in info:
                continue
            exp = expected(fired)
            f = (REC.get(sid) or {}).get('battle_record', {}).get('fields', {})
            cost = REC.get(sid, {}).get('mp_cost', 0)
            cost = cost if isinstance(cost, int) else 0
            got = R.evaluate_chain(info['cat'], sid, info.get('actor', 4), view_of(info['board']),
                                   cost, f.get('status_id', 0), info['dd6b'])
            if got == exp:
                ok += 1
            else:
                bad.append((name, sid, REC.get(sid, {}).get('name', '?'), exp, got,
                            [x for x in fired if x[0] not in ('end', 'vet')]))
    return ok, bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--corpus', default=CORPUS)
    ap.add_argument('--build', nargs='*', help='sweep_rules.py outputs -> the corpus')
    ap.add_argument('--show', type=int, default=40)
    a = ap.parse_args()
    if a.build:
        corpus = {}
        for f in a.build:
            d = json.load(open(f))
            corpus[f"live{d['party_live']}_{d['party_act']}_{d['board']}"] = d
        with gzip.open(a.corpus, 'wt') as g:
            json.dump({'_generator': 'simulator/sweep_rules.py (S163: --party-live / --party-act, '
                                     'the board captured) on the S163 echo build + the user\'s '
                                     'save; merged by simulator/validate_rules_boards.py --build',
                       **corpus}, g)
        print(f'{len(corpus)} boards -> {a.corpus}')
    with gzip.open(a.corpus, 'rt') as g:
        corpus = {k: v for k, v in json.load(g).items() if not k.startswith('_')}
    ok, bad = replay(corpus)
    print(f'S163 rule chains on 1-3 opponent boards: OK {ok}  MISMATCH {len(bad)}')
    for x in bad[:a.show]:
        print(' ', x)
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
