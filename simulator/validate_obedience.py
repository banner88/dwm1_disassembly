#!/usr/bin/env python3
"""S87 differential validator for the obedience-gate model (bank $57
state-0 preamble) against the measure_obedience.py corpus.

Checks per decision (band_in -> decide_in -> carry/nocarry triple):
  seed_4c   $db4c == tactic-category base // 10 (CmpBtlAI_78d4; tactic 3 -> 0)
  seed_4d   $db4d == w3 ($DC5C) // 10 (AIPreambleW3_7905)
  seed_4e   $db4e == LVL >> 2 (LoadBtlAI_7a03)
  thresh_53 $db53 == OBED_THRESH table lookup (AIPreambleLadder_791a)
  band_4f   $db4f == band-reduce(RNG1' & $3F) with ONE rng_step from the
            band_in pre-state (LoadBtlAI_7a16: mod b, nonzero multiples
            of b promoted to b; b from the LVL band ladder)
  decide    outcome == obedience_decide(LVL, $db4c/4d/4e/4f/53)
            (AIPreambleDecide_7a5d: 0 or <$15 nocarry; >=$F0 carry;
             else carry iff 4e+4f > 4c+4d+53, strict, 8-bit sums)

Exit 1 on any mismatch. -v prints failures.
"""
import sys, json, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator.damage import rng_step
from simulator.pacing import (OBED_THRESH, obed_band, obed_band_reduce,
                              obed_thresh_index, obedience_decide)

verbose = '-v' in sys.argv
path = next((x for x in sys.argv[1:] if not x.startswith('-')),
            os.path.join(os.path.dirname(os.path.abspath(__file__)),
                         's87_obedience_events.json'))
data = json.load(open(path))
events = data['events'] if isinstance(data, dict) else data

ok = bad = 0


def check(name, got, want, ctx):
    global ok, bad
    if got == want:
        ok += 1
    else:
        bad += 1
        if verbose:
            print('FAIL', name, 'got', got, 'want', want, ctx)


i = 0
while i + 2 < len(events) + 1:
    if i + 2 >= len(events):
        break
    b, d, o = events[i], events[i + 1], events[i + 2]
    if not (b['tag'] == 'band_in' and d['tag'] == 'decide_in'
            and o['tag'] in ('carry', 'nocarry')):
        i += 1
        continue
    i += 3
    ctx = 'lvl=%02x tac=%d' % (d['case_lvl'], d['case_tac'])
    lvl = d['lvl'] & 0xFF
    tactic = d['dd03'] & 0x03
    bases = dict(c1=d['dc44'], c2=d['dc4c'], c3=d['dc54'], w3=d['dc5c'])
    seed = {0: bases['c1'], 1: bases['c2'], 2: bases['c3'], 3: 0}[tactic]
    check('seed_4c', d['db4c'], seed // 10, ctx)
    check('seed_4d', d['db4d'], bases['w3'] // 10, ctx)
    check('seed_4e', d['db4e'], lvl >> 2, ctx)
    check('thresh_53', d['db53'],
          OBED_THRESH[obed_thresh_index(tactic, bases['c1'],
                                        bases['c3'], bases['c2'])], ctx)
    # band RNG: one step from the band_in pre-state
    pre = ((b['rng1'] << 8) | b['rng2'])
    post = rng_step(pre)
    check('band_rng_state', (d['rng1'] << 8) | d['rng2'], post, ctx)
    check('band_4f', d['db4f'],
          obed_band_reduce(((post >> 8) & 0xFF) & 0x3F, obed_band(lvl)), ctx)
    carries = obedience_decide(lvl, d['db4c'], d['db4d'], d['db4e'],
                               d['db4f'], d['db53'])
    check('decide', o['tag'], 'carry' if carries else 'nocarry', ctx)

print('obedience: %d checks, %d mismatches' % (ok + bad, bad))
sys.exit(1 if bad else 0)
