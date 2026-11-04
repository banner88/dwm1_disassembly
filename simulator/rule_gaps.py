#!/usr/bin/env python3
"""rule_gaps.py — S165 (ROADMAP E17 note "the rule model on arbitrary boards"): where the Balance
model of the enemy AI's rule chains (ai_rules.evaluate_chain) and the ROM's own bank $57 disagree
on the ORIGINAL rules, rule by rule.

The boards are validate_ai_fixes.py's (the S163 captured corpus + N seeded mutations each — the
same seed, so the same boards). The ROM side (rom_rules.Oracle on the original build) is run once
and cached (--cache, a .pkl.gz), so the model can be re-checked in seconds while a rule is being
modelled. Per mismatching chain start it prints the ROM's fired rules [(rule, +bonus, +penalty)],
the ROM's chain end and the model's; --rule $XXXX keeps the boards where that rule fired.

    python3 simulator/rule_gaps.py --orig BUILD [--mutate 4] [--seed 164] [--cache F]
        [--rule 4AF6] [--show 10]
Exit 1 while any chain start differs.
"""
import argparse
import gzip
import json
import os
import pickle
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.dirname(HERE))
import ai_rules as R                                              # noqa: E402
from rom_rules import Oracle                                      # noqa: E402
from validate_rules_boards import REC, CORPUS                    # noqa: E402
from validate_ai_fixes import mutate, end_of, read_sym, view_of_wram, set_rom_families   # noqa: E402


def boards(corpus, n, seed):
    """[(name, k, sid, info, wram, hram, actor)] in validate_ai_fixes.py's order (same RNG use)."""
    rnd = random.Random(seed)
    out = []
    for name, entry in sorted(corpus.items()):
        for sid, info in sorted(entry['results'].items(), key=lambda kv: int(kv[0])):
            b = info.get('board') or {}
            if 'wram' not in b:
                continue
            w0, h = bytes.fromhex(b['wram']), bytes.fromhex(b.get('hram', ''))
            actor = info.get('actor', 4)
            images = [w0] + [mutate(w0, actor, rnd) for _ in range(n)]
            for k, w in enumerate(images):
                out.append((name, k, int(sid), info, w, h, actor))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--orig', required=True, help='a build dir (rom.gbc, game.sym) with the original rules')
    ap.add_argument('--corpus', default=CORPUS)
    ap.add_argument('--mutate', type=int, default=4)
    ap.add_argument('--seed', type=int, default=164)
    ap.add_argument('--cache', default='/tmp/rule_gaps_cache.pkl.gz')
    ap.add_argument('--rule', help='only boards where this rule fired (hex)')
    ap.add_argument('--show', type=int, default=10)
    a = ap.parse_args()
    with gzip.open(a.corpus, 'rt') as g:
        corpus = {k: v for k, v in json.load(g).items() if not k.startswith('_')}
    bs = boards(corpus, a.mutate, a.seed)
    key = (a.corpus, a.mutate, a.seed, os.path.getmtime(os.path.join(a.orig, 'rom.gbc')))
    cache = None
    if os.path.exists(a.cache):
        with gzip.open(a.cache, 'rb') as f:
            c = pickle.load(f)
        if c.get('key') == key:
            cache = c['rom']
    if cache is None:
        o = Oracle(open(os.path.join(a.orig, 'rom.gbc'), 'rb').read(),
                   read_sym(os.path.join(a.orig, 'game.sym')))
        cache = []
        for (_n, _k, _sid, _i, w, h, _a) in bs:
            fired, _end = o.chain(w, h)
            cache.append((end_of(o, w, h)[0], fired))
        with gzip.open(a.cache, 'wb') as f:
            pickle.dump({'key': key, 'rom': cache}, f)
    set_rom_families(open(os.path.join(a.orig, 'rom.gbc'), 'rb').read())
    rule = int(a.rule, 16) if a.rule else None
    bad, per_rule, n = [], {}, 0
    for (name, k, sid, info, w, h, actor), (e_o, fired) in zip(bs, cache):
        if e_o is None:
            continue
        n += 1
        view = view_of_wram(w)
        f = (REC.get(sid) or {}).get('battle_record', {}).get('fields', {})
        cost = REC.get(sid, {}).get('mp_cost', 0)
        cost = cost if isinstance(cost, int) else 0
        got = R.evaluate_chain(info['cat'], sid, actor, view, cost, f.get('status_id', 0),
                               info['dd6b'])
        if got == e_o:
            continue
        rules = [x for x in fired if x[0] not in ('end', 'vet')]
        for r_ in {x[0] for x in rules}:
            per_rule[r_] = per_rule.get(r_, 0) + 1
        if rule is None or any(x[0] == rule for x in rules):
            bad.append((name, k, sid, REC.get(sid, {}).get('name', '?'), actor, info['cat'],
                        'ROM', e_o, 'model', got,
                        [(f'${x[0]:04X}', x[1], x[2]) for x in rules]))
    print(f'{n} chain starts; the model differs on {len(bad) if rule is None else sum(per_rule.values()) and len([1 for _ in bad])} '
          f'(rules fired there: ' + ', '.join(f'${r_:04X} {c}' for r_, c in
                                                sorted(per_rule.items(), key=lambda kv: -kv[1])[:16]) + ')')
    for x in bad[:a.show]:
        print('  ', x)
    return 1 if per_rule else 0


if __name__ == '__main__':
    sys.exit(main())
