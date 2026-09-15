#!/usr/bin/env python3
"""S86 AGGREGATE validation of the pacing layer (battle.simulate_round as
a DRIVER + IdlePolicy). Exact replay is impossible by construction
(KEY_LESSONS S85: the live RNG idle-steps a frame-timing-dependent
count), so the driver is validated STATISTICALLY, two levels:

LEVEL 1 — round-level PIT over the S85 corpus (the rigorous check).
For every pair of consecutive round_start events in a scenario, the
engine's own pre-round board + committed queue are replayed through
simulate_round N times under the idle policy; the engine's actual
outcome (per-side HP delta, KO set) is ranked inside the simulated
distribution. If the driver's per-round outcome distribution matches
the engine's, those ranks are ~Uniform(0,1) (probability integral
transform): reported as decile histogram + central-interval coverage +
a KS statistic. Rounds whose captured stream contains an engine-taken
stand-in (confusion action, status-rider proc) are counted separately.
Run for BOTH policies ('empirical', 'uniform') — S86 finding: they are
statistically indistinguishable here, i.e. pacing is policy-insensitive.

LEVEL 2 — battle-level comparison on complete captures. For each battle
events file (or corpus scenario) the round-1 board is simulated to
completion `--trials` times with the FULL commit model
(pacing.commit_round: validated category machine + chains, lightweight
picker, tactics bias) and the engine's actual (winner, rounds-to-end)
is located in the simulated distribution. This inherits the commit
stand-ins (party bases, obedience mid-band) and is a sanity envelope,
not a proof; level 1 is the proof for what S80 asked.

Usage:
  python3 simulator/validate_pacing.py --level1 [--policy empirical|uniform]
      [--trials 400] [--corpus F]
  python3 simulator/validate_pacing.py --level2 FILE [FILE..]
      [--pskills 0xe9,0xe5,0xe4,0x09] [--trials 1000]
Exit 1 if level-1 coverage falls outside its binomial envelope.
"""
import json, os, sys, argparse, random, math

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import battle as B
from simulator import pacing as P

RECORDS = P.load_records()
DUP = P.load_dup_flags()

# patched-ROM custom skill records (same table validate_battle.py uses)
try:
    from simulator.validate_battle import RECORDS as VB_RECORDS
    RECORDS = VB_RECORDS
except Exception:
    pass


def st16(e):
    return (e['rng1'] << 8) | e['rng2']


def rounds_of(corpus_path):
    ev = json.load(open(corpus_path))
    per = {}
    for e in ev:
        per.setdefault(e['sc'], []).append(e)
    out = []
    for sc, es in per.items():
        starts = [i for i, e in enumerate(es) if e['tag'] == 'round_start']
        for a, b in zip(starts, starts[1:]):
            seg = es[a:b]
            out.append((sc, es[a], es[b], seg))
    return out


ENGINE_TAKEN = ('curse_hit',)      # segment tags that force engine-taken
                                   # stand-in behaviour in the model


def seg_has_standin(seg, b0):
    if any(e['tag'] in ENGINE_TAKEN for e in seg):
        return True
    # confusion pending on any ready combatant (+2 bit4)
    for s in range(8):
        if b0.dd13[s] == 2 and b0.dd1b[s] == 0 and (b0.stb(s, 2) & 0x10):
            return True
    return False


def outcome(pre_hp, pre_dd1b, post_hp, post_dd1b):
    dmg_party = sum(max(a - c, 0) for a, c in zip(pre_hp[:3], post_hp[:3]))
    dmg_enemy = sum(max(a - c, 0) for a, c in zip(pre_hp[4:7], post_hp[4:7]))
    kos = tuple(1 if (x == 0 and y != 0) else 0
                for x, y in zip(pre_dd1b, post_dd1b))
    return dmg_party + dmg_enemy, dmg_party, dmg_enemy, kos


def pit_rank(engine_v, sim_vs, rnd):
    """Rank with random tie-breaking (discrete-safe PIT)."""
    lo = sum(1 for v in sim_vs if v < engine_v)
    eq = sum(1 for v in sim_vs if v == engine_v)
    return (lo + rnd.random() * (eq + 1)) / (len(sim_vs) + 1)


def level1(corpus, policy, trials, seed):
    idle = P.IdlePolicy(policy, seed=seed)
    rnd = random.Random(seed ^ 0xC0DE)
    ranks, ranks_standin = [], []
    ko_hits = ko_total = 0
    for sc, e0, e1, seg in rounds_of(corpus):
        b0 = B.Board.from_event(e0)
        eng_total, eng_p, eng_e, eng_kos = outcome(
            e0['hp'], e0['dd1b'], e1['hp'], e1['dd1b'])
        standin = seg_has_standin(seg, b0)
        sims = []
        sim_ko_match = 0
        for t in range(trials):
            b = B.Board.from_event(e0)
            st, _ = B.simulate_round(b, st16(e0), RECORDS, DUP, idle)
            tot, dp, de, kos = outcome(e0['hp'], e0['dd1b'], b.hp, b.dd1b)
            sims.append(tot)
            if kos == eng_kos:
                sim_ko_match += 1
        r = pit_rank(eng_total, sims, rnd)
        (ranks_standin if standin else ranks).append(r)
        if not standin:
            ko_total += 1
            if sim_ko_match / trials >= 0.05 or eng_kos == (0,) * 8:
                # engine KO set is a >=5% event under the model (or no KO)
                ko_hits += 1
    return ranks, ranks_standin, ko_hits, ko_total


def summarize(name, ranks):
    n = len(ranks)
    if not n:
        print(f"  {name}: (none)")
        return None
    dec = [0] * 10
    for r in ranks:
        dec[min(int(r * 10), 9)] += 1
    inner = sum(1 for r in ranks if 0.05 <= r <= 0.95)
    # KS vs uniform
    rs = sorted(ranks)
    ks = max(max(abs((i + 1) / n - r), abs(i / n - r))
             for i, r in enumerate(rs))
    ks_crit = 1.36 / math.sqrt(n)          # alpha = 0.05
    print(f"  {name}: n={n} decile-hist={dec} "
          f"coverage[5,95]={inner}/{n} ({inner/n:.1%}) "
          f"KS={ks:.3f} (crit@5% {ks_crit:.3f})")
    return inner, n, ks, ks_crit


def run_level1(a):
    ok = True
    for policy in (a.policy,) if a.policy else ('empirical', 'uniform'):
        print(f"[level 1] policy={policy} trials/round={a.trials}")
        ranks, ranks_si, ko_hits, ko_total = level1(
            a.corpus, policy, a.trials, a.seed)
        res = summarize('clean rounds', ranks)
        summarize('stand-in rounds', ranks_si)
        print(f"  KO-set: engine's KO outcome is a >=5% model event in "
              f"{ko_hits}/{ko_total} clean rounds")
        if res:
            inner, n, ks, ks_crit = res
            # binomial envelope for 90% central coverage (3.5 sigma)
            mu, sd = 0.90 * n, math.sqrt(n * 0.90 * 0.10)
            if not (mu - 3.5 * sd <= inner <= mu + 3.5 * sd):
                print("  FAIL: coverage outside the binomial envelope")
                ok = False
            if ks > 1.63 / math.sqrt(n):   # alpha = 0.01
                print("  FAIL: KS rejects uniform ranks at 1%")
                ok = False
    return ok


def run_level2(a):
    idle = P.IdlePolicy('empirical', seed=a.seed)
    skl = [int(x, 0) for x in a.pskills.split(',')] if a.pskills else None
    es = P.load_enemy_stats()
    for path in a.files:
        raw = json.load(open(path))
        groups = {}
        for e in raw:
            groups.setdefault(e.get('sc', os.path.basename(path)),
                              []).append(e)
        for sc, ev in groups.items():
            _level2_one(sc, ev, a, idle, skl, es)
    return True


def _level2_one(name, ev, a, idle, skl, es):
    starts = [e for e in ev if e['tag'] == 'round_start']
    e0 = starts[0]
    eng_rounds = len(starts)
    last = ev[-1]
    party_alive = any(l == 0 for l in last['dd1b'][:3])
    enemy_alive = any(l == 0 for l in last['dd1b'][4:7])
    eng_win = 'party' if party_alive and not enemy_alive else \
              'enemy' if enemy_alive and not party_alive else 'open'
    er = {4 + i: es[eid] for i, eid in enumerate(e0['eid'])
          if 4 + i < 7 and e0['dd1b'][4 + i] != 0xFF}
    rnd = random.Random(a.seed)
    rounds, wins = [], {'party': 0, 'enemy': 0, 'timeout': 0}
    for t in range(a.trials):
        b = P.board_from_event(e0)
        b.party_skills = [skl, None, None] if skl else [None] * 3
        if a.pbases:
            b.party_bases[0] = tuple(int(x, 0) for x in a.pbases.split(','))
        r = P.simulate_battle(b, RECORDS, DUP, idle, rnd,
                              party_policy=a.party_policy,
                              enemy_recs=er)
        rounds.append(r['rounds']); wins[r['winner']] += 1
    rs = sorted(rounds)
    n = len(rs)
    lo = sum(1 for v in rs if v < eng_rounds)
    eq = sum(1 for v in rs if v == eng_rounds)
    print(f"{name}: engine {eng_win} in {eng_rounds} "
          f"rounds | sim({a.party_policy}) wins={wins} "
          f"rounds p10/med/p90 = {rs[n//10]}/{rs[n//2]}/{rs[9*n//10]} "
          f"| engine-rounds percentile ~{(lo + eq/2)/n:.0%}")


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--level1', action='store_true')
    ap.add_argument('--level2', action='store_true')
    ap.add_argument('files', nargs='*')
    ap.add_argument('--policy')
    ap.add_argument('--trials', type=int, default=400)
    ap.add_argument('--seed', type=int, default=7)
    ap.add_argument('--pskills')
    ap.add_argument('--party-policy', default='tactics')
    ap.add_argument('--pbases', default='80,85,186,189', help='slot-0 '
                    '(c1,c2,c3,w3) battle bases; default = the hacked-'
                    'sav Slib record +$5B/+$5E/+$5C/+$5D (measured S87). '
                    'Pass "" to use PARTY_FALLBACK_BASES.')
    ap.add_argument('--corpus', default=os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        's85_battle_events.json'))
    a = ap.parse_args(argv)
    ok = True
    if a.level1:
        ok = run_level1(a) and ok
    if a.level2:
        ok = run_level2(a) and ok
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
