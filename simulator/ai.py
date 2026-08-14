#!/usr/bin/env python3
"""Enemy/tactics AI model — bank $57 decision machine (S80).

Traced from bank $57 and measured live (see BATTLE_SKILL_SYSTEM "AI" section
and simulator/measure_ai.py). Models phase 5 / $d9ed=1's per-actor pipeline:

  state 1  entry ($7129): plan fork, dd0b gate
  state 2  category rank (FuncBtlAI_71b9 + LoadBtlAI_7322 -> $dcfc/$dcff-$dd01)
  state 3  per-skill sum (Jump_057_7529 -> $dce4[i] = rec_ai_w + rand%16)
  state 4  tag filter + per-effect-class evaluator (Jump_057_7439, rule chains
           at $57:$4308/$4358/$4404 accumulate $dd26; NOT yet fully modelled)
  state 5  pick (Jump_057_75a2: argmax, tie coin-flip, category epilogues)
  retry    ($76a9): $dd02++ (NO bound check - the S79 stall lives here)

RNG contract: every rand here consumes exactly one GenerateRNG step and uses
the BYTE-SWAPPED 16-bit dividend (S78 lesson): r16 = (RNG2<<8)|RNG1 after the
step, result = r16 % mod. Callers supply rng_step() returning (rng1, rng2).

Verified against live traces (EIDs 34/35/51/52): category formula, weight
mapping, sort quirks incl. the +30 cat1 rank2-retention bonus, sum residuals,
tag filter, retry cursor, commit. Evaluator rule chains are stubbed as a
per-decision score delta (see RuleChainStub); loop-level validation will
surface which chains need real implementations.

S81 UPDATE: the real rule-chain model now exists in simulator/ai_rules.py
(240/240 vs the S81 sweep corpus, validate_rules.py). RuleChainStub is
SUPERSEDED but left wired here untouched so validate_ai.py's S80 26/26
result stays reproducible; swapping evaluate_chain() in belongs to the
loop-validation step (ROADMAP S81) where the swap gets its own
differential run.

Status: built S80, NOT yet user-tested.
"""

# enemy_stats ai_weights byte order (+17..+20) -> category bases.
# Measured: +17 -> cat1 ($DC44), +19 -> cat2 ($DC4C), +18 -> cat3 ($DC54).
# +20 (w[3]) feeds the state-0 act/flee preamble ($db4d = w3/10), not the
# category machine; preamble not yet modelled.
W_TO_CAT = (0, 2, 1)  # cat_base[c] = ai_weights[W_TO_CAT[c]]

PLAIN_ATTACK = 0x3A
DEFENCE = 0x8D
OVERRIDE_STATUS2_BIT4 = 0x3A   # confusion (+2 bit4) -> forced plain attack
OVERRIDE_STATUS6_BIT2 = 0x42   # +6 bit2 -> forced action $42
OVERRIDE_STATUS7_BIT4 = 0x95   # +7 bit4 -> forced action $95


def cat_mod(base, is_enemy):
    """Random modulus for the category score (SaveBtlAI_72ce ladder).
    Player slots (<3) and link battles always use 10."""
    if not is_enemy:
        return 10
    if base < 0x32:
        return 30
    if base < 0x64:
        return 25
    if base < 0x96:
        return 20
    return 10


def category_scores(bases, plan_adj, is_enemy, rng_step, seal_bump=False):
    """FuncBtlAI_71b9: score[c] = base//10 + adj[c] + r16' % mod(base).
    One RNG step per category, in order cat1, cat2, cat3.
    seal_bump: the +$1e 'prefer attack when magic-limited' heuristic on cat1
    (trigger bits on the actor's status block; pass the measured condition)."""
    scores = []
    for c in range(3):
        r1, r2 = rng_step()
        r16 = (r2 << 8) | r1
        scores.append((bases[c] // 10 + plan_adj[c] + r16 % cat_mod(bases[c], is_enemy)) & 0xFF)
    if seal_bump:
        scores[0] = (scores[0] + 0x1E) & 0xFF
    return scores


def rank_categories(scores):
    """LoadBtlAI_7322 — exact quirky partial sort. Mutates a copy of scores
    (the +30 bonus lands in the cat1 CELL). Returns (scores, ids) where
    ids = [rank1, rank2, rank3] category ids (1-based), matching
    $dcff/$dd00/$dd01, cursor $dd02 starts at 3 (rank1)."""
    s = list(scores)
    ids = [1, 2, 3]
    # step 1: rank1 vs rank2 by raw cat1 vs cat2
    winner = s[0]
    if s[0] < s[1]:
        ids[0], ids[1] = 2, 1
        winner = s[1]
    # step 2: winner vs cat3 — swaps rank1 <-> rank3 only
    if winner < s[2]:
        ids[0], ids[2] = ids[2], ids[0]
    # step 3 (LoadBtlAI_73a5 exact): +30 to cat1's CELL iff cat1 is NOT
    # rank1 after step 2 (checks rank2 then rank3) — "attack as the
    # perennial runner-up" bonus
    if ids[1] == 1 or ids[2] == 1:
        s[0] = (s[0] + 0x1E) & 0xFF
    # step 4: rank2 vs rank3 by their (possibly bumped) cells
    if s[ids[1] - 1] < s[ids[2] - 1]:
        ids[1], ids[2] = ids[2], ids[1]
    return s, ids


def skill_sums(option_list, rec_ai_weight, rng_step):
    """Jump_057_7529: for each {tag, skill} pair (skill != 0xFF terminator),
    dce4[i] = rec_ai_weight(skill) + r16' % 16, saturating at 0xFF.
    One RNG step per listed skill. Runs over ALL entries regardless of the
    chosen category (the tag filter happens afterwards)."""
    out = []
    for tag, skill in option_list:
        if skill == 0xFF:
            break
        r1, r2 = rng_step()
        r16 = (r2 << 8) | r1
        v = rec_ai_weight(skill) + r16 % 16
        out.append(min(v, 0xFF))
    return out


class RuleChainStub:
    """Placeholder for the per-effect-class evaluators ($4308/$4358/$4404
    tables; rules accumulate $dd26 in +10 steps, high byte $FF = veto).
    Observed writeback on the measured decisions: dce4[c] += 50 with
    dd26 ending at 60. Until chains are traced per effect_class, this stub
    returns a fixed delta and never vetoes; differential validation flags
    decisions where that is wrong."""
    def __init__(self, delta=50):
        self.delta = delta

    def evaluate(self, category, skill, state):
        return self.delta, False  # (score_delta, veto)


def tag_filter(option_list, sums, category, rules, state=None):
    """Jump_057_7439: zero entries whose tag != category; matched entries run
    the evaluator (delta/veto). Returns the filtered dce4 list."""
    out = []
    for (tag, skill), s in zip(option_list, sums):
        if skill == 0xFF:
            break
        if tag != category:
            out.append(0)
            continue
        delta, veto = rules.evaluate(category, skill, state)
        out.append(0 if veto else min((s + delta) & 0x1FF, 0xFF))
    return out


def pick(dce4, option_list, category, rng_step,
         attack_service=None, heal_checks=None):
    """Jump_057_75a2 core scan + epilogues. Returns (action, retry):
    action None + retry True  -> caller bumps rank cursor and reruns from the
    category stage (the $76a9 loop; NO bound check in the ROM).
    Tie rule: equal score -> one RNG step, RNG1 bit0: 0 keep current, 1 take new.
    Cat1 epilogue: bank $58 entry 11 service returns a plain-attack score in
    $dd26; if it >= best skill score -> plain Attack. Winner skill 0xFF ->
    plain Attack. Cat3 with best < 20 runs extra checks that can retry,
    fall back to plain Attack, or queue Defence ($8D)."""
    best = None
    best_i = None
    for i, v in enumerate(dce4[:7]):
        if v == 0:
            continue
        if best is None:
            best, best_i = v, i
        elif v == best:
            r1, _ = rng_step()
            if r1 & 1:
                best, best_i = v, i
        elif v > best:
            best, best_i = v, i
    if best is None:
        return None, True

    if category == 1:
        if attack_service is not None:
            atk_score = attack_service()
            if atk_score >= best:
                return PLAIN_ATTACK, False
        skill = option_list[best_i][1]
        return (PLAIN_ATTACK if skill == 0xFF else skill), False
    if category == 2:
        skill = option_list[best_i][1]
        return (PLAIN_ATTACK if skill == 0xFF else skill), False
    # category 3
    if best < 0x14 and heal_checks is not None:
        verdict = heal_checks(best)
        if verdict == 'retry':
            return None, True
        if verdict == 'attack':
            return PLAIN_ATTACK, False
        if verdict == 'defend':
            return DEFENCE, False
    skill = option_list[best_i][1]
    return (PLAIN_ATTACK if skill == 0xFF else skill), False


def decide(option_list, bases, plan_adj, rec_ai_weight, rng_step,
           is_enemy=True, seal_bump=False, rules=None,
           attack_service=None, heal_checks=None, max_retries=8):
    """Full pipeline for one actor's decision. Returns (action, trace) where
    trace holds per-stage values matching the RAM names for differential
    comparison. max_retries guards the unbounded ROM loop for the model's
    own safety; the ROM itself has no such guard (S79 stall)."""
    rules = rules or RuleChainStub()
    scores = category_scores(bases, plan_adj, is_enemy, rng_step, seal_bump)
    cells, ids = rank_categories(scores)
    trace = dict(dcfc=cells, rank_ids=ids, passes=[])
    cursor = 0
    while cursor < max_retries:
        category = ids[cursor] if cursor < 3 else None
        if category is None:
            trace['stall'] = True
            return PLAIN_ATTACK, trace  # model fallback; ROM would walk RAM
        sums = skill_sums(option_list, rec_ai_weight, rng_step)
        dce4 = tag_filter(option_list, sums, category, rules)
        action, retry = pick(dce4, option_list, category, rng_step,
                             attack_service, heal_checks)
        trace['passes'].append(dict(category=category, sums=sums, dce4=dce4,
                                    action=action))
        if not retry:
            return action, trace
        cursor += 1
    trace['stall'] = True
    return PLAIN_ATTACK, trace
