#!/usr/bin/env python3
"""S86: measure the engine's RNG IDLE-STEP counts from the S85 waypoint
corpus — offline, no emulator.

The live RNG pair ($C899/9A) is a full-period 16-bit LCG
(state*5+$1357 mod 2^16, ROM0 GenerateRNG), stepped by MainWaitLoop on
every idle iteration while $C86C==0 (KEY_LESSONS S85). Between any two
captured waypoint states the step count k is therefore UNIQUE mod 65536
and recoverable by walking the chain. This script recovers k for every
consecutive event pair in simulator/s85_battle_events.json and buckets the
samples into the idle CLASSES the round loop actually exhibits:

  Measured structure (S86, 5,636 pairs over 25 battles):
  - SAME-FRAME pairs move only k in {0,1} — i.e. within a frame the only
    RNG movement is the engine's own deterministic steps, which
    simulator/battle.py already encodes. The gate block
    (actor_fetch->gates_in->curse_stage->skill_load) and the entire
    MISS->damage-core->status-core sequence are same-frame: NO idle there.
  - CROSS-FRAME pairs (text scroll, animations, actor changeover) insert
    ~10^2..10^4 steps with heavy spread; these are the idle sites.
  - Phase 9 is special: consecutive p9_slot rolls carry an IDENTICAL
    state (k=0 — the wait loop does not step the RNG in that stretch);
    an idle burst appears only before a DoT damage APPLY (the damage
    animation) and at phase entry/exit.

Output: simulator/s86_idle_model.json — per-class raw k sample pools for
battle.IdlePolicy('empirical'). Classes:

  round_gap       phase-9 end -> next round's order build
  post_order      order build -> first actor fetch
  actor_skip      actor fetch -> next actor fetch (skipped/invalid actor)
  post_action     end of an actor's action -> next actor fetch
  pre_target      skill load -> (re-resolve ->) target fetch; also
                  between-victims returns to target fetch
  pre_miss        target fetch -> MISS machine entry (attack animation)
  p9_entry        last in-round event -> first phase-9 slot
  post_dot_apply  DoT roll -> its damage apply (animation); the NEXT
                  slot's roll sees the post-idle state

Usage: python3 simulator/measure_idle.py [--corpus F] [--out F]
Selftest: --check re-derives and diffs against the existing output file.
"""
import json, os, argparse, sys

MASK = 0xFFFF

def rng_step(s):
    return (s * 5 + 0x1357) & MASK

def st16(e):
    return (e['rng1'] << 8) | e['rng2']

def steps_between(a, b):
    s = a
    for k in range(65536):
        if s == b:
            return k
        s = rng_step(s)
    raise AssertionError('full-period LCG must reach every state')

# (tag_from, tag_to) -> class; only CROSS-FRAME pairs are idle samples,
# except p9_slot->p9_slot (always k=0, recorded to prove the no-idle rule).
CLASSES = {
    ('p9_slot', 'round_start'): 'round_gap',
    ('round_start', 'actor_fetch'): 'post_order',
    ('actor_fetch', 'actor_fetch'): 'actor_skip',
    ('actor_fetch', 'round_end'): 'actor_skip',
    ('apply_in', 'actor_fetch'): 'post_action',
    ('final_54e7', 'actor_fetch'): 'post_action',
    ('miss_pass', 'actor_fetch'): 'post_action',
    ('forced', 'actor_fetch'): 'post_action',
    ('block', 'actor_fetch'): 'post_action',
    ('dodge', 'actor_fetch'): 'post_action',
    ('status_roll', 'actor_fetch'): 'post_action',
    ('curse_hit', 'target_fetch'): 'pre_target',
    ('skill_load', 'target_fetch'): 'pre_target',
    ('skill_load', 'reresolve'): 'pre_target',
    ('reresolve', 'target_fetch'): 'pre_target',
    ('apply_in', 'target_fetch'): 'pre_target',
    ('final_54e7', 'target_fetch'): 'pre_target',
    ('ko', 'target_fetch'): 'pre_target',
    ('target_fetch', 'miss_in'): 'pre_miss',
    ('apply_in', 'p9_slot'): 'p9_entry',
    ('miss_pass', 'p9_slot'): 'p9_entry',
    ('final_54e7', 'p9_slot'): 'p9_entry',
    ('round_end', 'p9_slot'): 'p9_entry',
    ('miss_path', 'p9_slot'): 'p9_entry',
    ('block', 'p9_slot'): 'p9_entry',
    ('dodge', 'p9_slot'): 'p9_entry',
    ('roll_in', 'p9_slot'): 'p9_entry',
    ('status_roll', 'p9_slot'): 'p9_entry',
    ('statchance_in', 'p9_slot'): 'p9_entry',
    ('p9_slot', 'p9_dot_apply'): 'post_dot_apply',
}


def derive(corpus_path):
    ev = json.load(open(corpus_path))
    per = {}
    for e in ev:
        per.setdefault(e['sc'], []).append(e)
    pools = {c: [] for c in set(CLASSES.values())}
    p9_consecutive = []          # proof pool: must be all zero
    same_frame_ks = {}           # k -> count over same-frame pairs (proof)
    for sc, es in per.items():
        for a, b in zip(es, es[1:]):
            k = steps_between(st16(a), st16(b))
            df = b['frame'] - a['frame']
            if (a['tag'], b['tag']) == ('p9_slot', 'p9_slot'):
                p9_consecutive.append(k)
                continue
            if df == 0:
                same_frame_ks[k] = same_frame_ks.get(k, 0) + 1
                continue
            cls = CLASSES.get((a['tag'], b['tag']))
            if cls:
                pools[cls].append(k)
    assert all(k == 0 for k in p9_consecutive), 'phase-9 no-idle rule broken'
    assert set(same_frame_ks) <= {0, 1}, \
        'same-frame pairs must only carry the deterministic steps'
    return {
        '_generator': 'simulator/measure_idle.py over '
                      'simulator/s85_battle_events.json '
                      '(patched ROM 4c8de38a, real hacked .sav)',
        '_lcg': 'state*5+0x1357 mod 2^16 (ROM0 GenerateRNG)',
        '_proof': {
            'p9_slot_consecutive_k': sorted(set(p9_consecutive)),
            'p9_slot_pairs': len(p9_consecutive),
            'same_frame_k_histogram': same_frame_ks,
        },
        'pools': pools,
    }


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--corpus', default=os.path.join(
        os.path.dirname(__file__), 's85_battle_events.json'))
    ap.add_argument('--out', default=os.path.join(
        os.path.dirname(__file__), 's86_idle_model.json'))
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args(argv)
    model = derive(a.corpus)
    if a.check:
        old = json.load(open(a.out))
        ok = old['pools'] == model['pools']
        print('CHECK', 'OK' if ok else 'MISMATCH')
        return 0 if ok else 1
    json.dump(model, open(a.out, 'w'))
    for c, v in sorted(model['pools'].items()):
        sv = sorted(v)
        print(f"{c:>16}: n={len(v):4d} med={sv[len(sv)//2] if v else '-'}")
    print('proof:', model['_proof']['p9_slot_pairs'],
          'consecutive p9 rolls, k =', model['_proof']['p9_slot_consecutive_k'],
          '| same-frame k histogram:', model['_proof']['same_frame_k_histogram'])
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
