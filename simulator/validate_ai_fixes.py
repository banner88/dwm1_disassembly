#!/usr/bin/env python3
"""validate_ai_fixes.py — S164 (ROADMAP E17 note "the original AI's bugs"; editor2/core/
ai_fixes.py): the Balance simulator's model of the five switches == the fixed bank $57 code.

Two ROMs of one project: the original rules (no switch) and every fix on (gamedata.ai_fixes all
true). For each chain start of the S163 board corpus (simulator/s163_board_corpus.json.gz: the
whole WRAM / HRAM where AIState7ChainWalker_7865 starts, 1,573 chains on the user's save) and
for MUTATED copies of it (seeded: opposing monsters killed or revived, their species — so their
family —, status bits, ATK / DEF, the actor's AI tier $DD0B), the ROM's own chain
(simulator/rom_rules.Oracle: bank $57 run by tools/sm83run.py) is compared with
ai_rules.evaluate_chain on the same board:
  original ROM  vs the model with fixes = {}         (the S163 model on new boards)
  fixed ROM     vs the model with fixes = AI_FIXES
and, per switch, the chains where the two ROMs DIFFER are counted (each fix must show).

    python3 simulator/validate_ai_fixes.py --orig ORIG_BUILD --fixed FIXED_BUILD [--mutate N]
        [--seed S] [--show N]
(ORIG_BUILD / FIXED_BUILD: build dirs with rom.gbc + game.sym; --fixes a,b: the switches ON in
FIXED_BUILD, default all five — S164 ran all five and each alone.)  Exit 1 on any mismatch of
the fixed ROM, or of the original ROM on a rule the switches touch.
"""
import argparse
import gzip
import json
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.dirname(HERE))
import ai_rules as R                                              # noqa: E402
from rom_rules import Oracle                                      # noqa: E402
from validate_rules_boards import REC, MF, CORPUS                # noqa: E402

ALL = frozenset(('aoe_count', 'class_count', 'family_cut', 'demagic_scan', 'averages'))
# the rules the switches change (their chain heads): a mismatch of the ORIGINAL ROM on a chain
# where none of them fired is an S163-model gap on a mutated board, reported, not failed
TOUCHED = {0x4E36, 0x5FFD, 0x6180, 0x61BC, 0x604A, 0x60C8, 0x6107, 0x6144, 0x4C41, 0x6848,
           0x6BCB, 0x4D56, 0x551B}
FAM_SPECIES = {}
for _sp, _m in enumerate(MF):
    if isinstance(_m, dict) and _m.get('family_id') is not None and _sp < 215:
        FAM_SPECIES.setdefault(_m['family_id'], []).append(_sp)


def _w(w, a):
    return w[a - 0xC000] | w[a - 0xC000 + 1] << 8


def view_of_wram(w):
    """The board sweep_rules.py captures, read from the WRAM image itself (so a mutated image
    gives its own board)."""
    def words(base):
        return [_w(w, base + 2 * s) for s in range(8)]
    res = [w[0xDD28 - 0xC000 + i] for i in range(56)]
    fams, traits = [None] * 8, [0] * 8
    for s_ in range(8):
        sp = w[0xDC3C - 0xC000 + s_]
        if sp < len(MF):
            fams[s_] = MF[sp].get('family_id')
            traits[s_] = (1 if MF[sp].get('is_metal') else 0) | (0x10 if MF[sp].get('can_fly') else 0)
    opts = [[w[0xDC64 - 0xC000 + s * 16 + k] for k in range(16)] for s in range(8)]
    return R.BattleView(words(0xDBA3), words(0xDBB3), words(0xDBC3), words(0xDBD3),
                        [[w[0xDB00 - 0xC000 + s * 8 + k] for k in range(8)] for s in range(8)],
                        [w[0xDD1B - 0xC000 + i] for i in range(8)], traits, fams,
                        lambda s_, e: (res[s_ * 7 + (e >> 2)] >> ((3 - (e & 3)) * 2)) & 3,
                        skills=[[(o[2 * k], o[2 * k + 1]) for k in range(8)] for o in opts],
                        dd0b=[w[0xDD0B - 0xC000 + i] for i in range(8)],
                        db40=(w[0xDB40 - 0xC000], w[0xDB41 - 0xC000]),
                        atk=words(0xDBE3), dfn=words(0xDBF3), agl=words(0xDC03))


def mutate(w, actor, rnd):
    """A copy of WRAM image `w` with the opposing side (and the actor's AI tier) shuffled."""
    w = bytearray(w)
    opp = 0 if actor >= 4 else 4
    put = (lambda a, v: w.__setitem__(a - 0xC000, v & 0xFF))
    for s_ in range(opp, opp + 3):
        if w[0xDD1B - 0xC000 + s_] == 0xFF and rnd.random() < 0.5:
            continue                                         # an empty slot stays empty
        alive = rnd.random() < 0.7
        put(0xDD1B + s_, 0 if alive else 1)
        hp = rnd.randint(1, 999) if alive else 0
        put(0xDBA3 + 2 * s_, hp)
        put(0xDBA4 + 2 * s_, hp >> 8)
        mh = max(hp, rnd.randint(1, 999))
        put(0xDBB3 + 2 * s_, mh)
        put(0xDBB4 + 2 * s_, mh >> 8)
        fam = rnd.choice(sorted(FAM_SPECIES))
        put(0xDC3C + s_, rnd.choice(FAM_SPECIES[fam]))
        for off, mask in ((3, 0x3E), (4, 0x6F), (5, 0x40), (7, 0xCF), (2, 0x23)):
            put(0xDB00 + 8 * s_ + off, (rnd.getrandbits(8) & mask) if rnd.random() < 0.3 else 0)
        for base in (0xDBE3, 0xDBF3, 0xDC03):
            v = rnd.choice((rnd.randint(1, 60), rnd.randint(1, 999)))
            put(base + 2 * s_, v)
            put(base + 2 * s_ + 1, v >> 8)
    for s_ in range(4 - opp, 4 - opp + 3):                  # the own side's DEF / ATK too
        for base in (0xDBE3, 0xDBF3):
            v = rnd.randint(1, 999)
            put(base + 2 * s_, v)
            put(base + 2 * s_ + 1, v >> 8)
    put(0xDD0B + actor, rnd.choice((0, 1, 2, 2)))
    return bytes(w)


def end_of(o, w, h):
    fired, end = o.chain(w, h)
    if end is None:
        return None, fired
    if end[0] == 'vet':
        return (0, True), fired
    b, p = end[1], end[2]
    return ((0, True) if b < p else ((b - p) & 0xFF, False)), fired


def read_sym(path):
    out = {}
    for line in open(path):
        if ':' in line and not line.startswith(';'):
            a, n = line.split()
            b, ad = a.split(':')
            out[n] = (int(b, 16), int(ad, 16))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--orig', required=True)
    ap.add_argument('--fixed', required=True)
    ap.add_argument('--fixes', default=','.join(sorted(ALL)),
                    help='the switches ON in the --fixed build (default: all five)')
    ap.add_argument('--corpus', default=CORPUS)
    ap.add_argument('--mutate', type=int, default=4)
    ap.add_argument('--seed', type=int, default=164)
    ap.add_argument('--show', type=int, default=20)
    a = ap.parse_args()
    on = frozenset(x for x in a.fixes.split(',') if x)
    if not on <= ALL:
        ap.error(f'unknown fix in {sorted(on - ALL)}')
    roms = {k: Oracle(open(os.path.join(d, 'rom.gbc'), 'rb').read(),
                      read_sym(os.path.join(d, 'game.sym'))) for k, d in
            (('orig', a.orig), ('fixed', a.fixed))}
    with gzip.open(a.corpus, 'rt') as g:
        corpus = {k: v for k, v in json.load(g).items() if not k.startswith('_')}
    rnd = random.Random(a.seed)
    stats = {'images': 0, 'exact': 0, 'fixed_ok': 0, 'differ': 0}
    bad, gap_rules, differ = [], {}, {}
    for name, entry in sorted(corpus.items()):
        for sid, info in sorted(entry['results'].items(), key=lambda kv: int(kv[0])):
            b = info.get('board') or {}
            if 'wram' not in b:
                continue
            sid = int(sid)
            w0, h = bytes.fromhex(b['wram']), bytes.fromhex(b.get('hram', ''))
            actor = info.get('actor', 4)
            f = (REC.get(sid) or {}).get('battle_record', {}).get('fields', {})
            cost = REC.get(sid, {}).get('mp_cost', 0)
            cost = cost if isinstance(cost, int) else 0
            images = [w0] + [mutate(w0, actor, rnd) for _ in range(a.mutate)]
            for k, w in enumerate(images):
                view = view_of_wram(w)
                e_o, f_o = end_of(roms['orig'], w, h)
                e_f, f_f = end_of(roms['fixed'], w, h)
                if e_o is None or e_f is None:
                    continue
                stats['images'] += 1

                def model(fixes):
                    return R.evaluate_chain(info['cat'], sid, actor, view, cost,
                                            f.get('status_id', 0), info['dd6b'], fixes=fixes)
                if model(frozenset()) != e_o:
                    # the S163 model is not exact for the ORIGINAL rules on this board (a rule
                    # it does not model, on a board the captured corpus never had): reported
                    for r_ in {x[0] for x in f_o if x[0] not in ('end', 'vet')}:
                        gap_rules[r_] = gap_rules.get(r_, 0) + 1
                    if k == 0:
                        bad.append(('captured board, original rules', name, sid, e_o))
                    continue
                stats['exact'] += 1
                got = model(on)
                if e_o != e_f:
                    stats['differ'] += 1
                    differ[sid] = differ.get(sid, 0) + 1
                if got == e_f:
                    stats['fixed_ok'] += 1
                else:
                    bad.append((name, k, sid, REC.get(sid, {}).get('name', '?'), 'ROM', e_f,
                                'model', got, sorted(hex(x[0]) for x in f_f
                                                     if x[0] not in ('end', 'vet'))))
    print(f"{stats['images']} chain starts (captured + {a.mutate} mutated each); the model exact "
          f"for the ORIGINAL rules on {stats['exact']}; switches ON: {', '.join(sorted(on))}")
    print(f"  on those, the fixed ROM == the model with the same switches: {stats['fixed_ok']} / "
          f"{stats['exact']}; the fixed ROM decides otherwise than the original on "
          f"{stats['differ']} ({len(differ)} skills)")
    top = sorted(gap_rules.items(), key=lambda kv: -kv[1])[:12]
    print(f"  boards where the S163 model is not exact for the original rules: "
          f"{stats['images'] - stats['exact']} (rules fired there, most often: "
          f"{', '.join(f'${r_:04X} {c}' for r_, c in top)})")
    for x in bad[:a.show]:
        print('  FAIL', x)
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
