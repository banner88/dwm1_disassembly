#!/usr/bin/env python3
"""S86 PACING LAYER — offline full-battle simulation for TTK sweeps.

Strings the validated pieces into complete battles:
  commit  (this file: ai.py category machine + ai_rules.py chains for
           mode 1/2 actors; the decoded S84 lightweight picker for
           $dd0b==0 actors; tactics bias per §15.10.7a for party slots)
  rounds  (battle.simulate_round — differentially validated S85)
  RNG     (IdlePolicy over the MEASURED idle-step pools,
           simulator/s86_idle_model.json / measure_idle.py)

RNG POLICY (the ROADMAP S80 first question, answered S86):
The engine idle-steps the live RNG between waypoints by a frame-timing-
dependent count; measure_idle.py recovered every count in the S85 corpus.
IdlePolicy('empirical') replays k-samples from the measured per-class
pools through the exact LCG affine map; IdlePolicy('uniform') redraws a
uniform 16-bit state. Aggregate validation (validate_pacing.py) shows the
two are statistically indistinguishable at round level — the pacing
result is policy-insensitive, as ROADMAP hypothesised — so 'empirical'
is the default purely because it is the measured one.

COMMIT-MODEL stand-ins (marked, acceptable for pacing statistics, NOT
for exact per-decision replay — use validate_ai/validate_rules corpora
for that): the obedience-gate middle band is approximated (carry vs bias
uses the decoded formula with the banded RNG simplified to its range);
the mode-0 lightweight picker follows the §15.10.10 decode's main path
(implicit extra candidate always present); confusion actions, status-
rider chances and the curse MP drain inherit battle.py's stand-ins.

Party policies for sweeps:
  'attack'   always plain Attack (pessimistic TTK floor)
  'tactics'  the real commit machine under a tactic (0 Charge / 1 Mixed /
             2 Cautious), obedience-gated by level like the engine
API: simulate_battle(), ttk(), make_board(), board_from_event().
"""
import json, os, random, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator import battle as B
from simulator import ai as A
from simulator import ai_rules as R
from simulator import damage as D

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MASK = 0xFFFF


def load_records():
    d = json.load(open(os.path.join(ROOT, 'extracted', 'skill_records.json')))
    return {r['id']: r for r in d['records']}


def load_dup_flags():
    d = json.load(open(os.path.join(ROOT, 'extracted',
                                    'enemy_dupconv_flags.json')))
    return d['flags'] if isinstance(d, dict) and 'flags' in d else d


def load_enemy_stats():
    return json.load(open(os.path.join(ROOT, 'extracted',
                                       'enemy_stats.json')))


def load_species():
    d = json.load(open(os.path.join(ROOT, 'extracted', 'monsters_full.json')))
    recs = d['records'] if isinstance(d, dict) and 'records' in d else d
    return {r['id']: r for r in recs}


# --------------------------------------------------------------------------
# Idle policy
# --------------------------------------------------------------------------
_AFFINE_CACHE = {}      # k -> (a, c), shared by all IdlePolicy instances


def _affine_k(k):
    """(a_k, c_k) with state' = a_k*state + c_k mod 2^16 = k LCG steps,
    by binary composition of the affine map (O(log k))."""
    got = _AFFINE_CACHE.get(k)
    if got is not None:
        return got
    a, c = 1, 0                    # identity
    sa, sc = 5, 0x1357             # one step
    kk = k
    while kk:
        if kk & 1:
            a, c = (sa * a) & MASK, (sa * c + sc) & MASK
        sa, sc = (sa * sa) & MASK, (sa * sc + sc) & MASK
        kk >>= 1
    _AFFINE_CACHE[k] = (a, c)
    return a, c


class IdlePolicy:
    """RNG idle model. mode: 'empirical' (measured k pools, default),
    'uniform' (uniform 16-bit state redraw), 'identity' (no idling).
    Deterministic under a seed. k-steps apply through the LCG's affine
    closure (module-cached, O(log k) to build)."""

    def __init__(self, mode='empirical', seed=0, model_path=None):
        self.mode = mode
        self.rnd = random.Random(seed)
        self.pools = None
        if mode == 'empirical':
            path = model_path or os.path.join(
                os.path.dirname(os.path.abspath(__file__)),
                's86_idle_model.json')
            self.pools = json.load(open(path))['pools']

    def __call__(self, state, cls):
        if self.mode == 'identity':
            return state
        if self.mode == 'uniform':
            return self.rnd.randrange(0x10000)
        pool = self.pools.get(cls)
        if not pool:
            return state
        a, c = _affine_k(self.rnd.choice(pool))
        return (a * state + c) & MASK


# --------------------------------------------------------------------------
# Board construction
# --------------------------------------------------------------------------
def pack_res(levels27):
    """Species info 27 resistance levels -> the 7 packed $DD28 bytes
    (2-bit MSB-first, position t+1; damage.res_level is the reader)."""
    out = [0] * 7
    for t, lv in enumerate(levels27):
        pos = t + 1
        out[pos >> 2] |= (lv & 3) << ((3 - (pos & 3)) * 2)
    return out


def dd0b_mode(int_stat, enemy):
    """Per-slot AI mode from INT (§15.10.10; boundary-measured S84).
    Party: 16-bit compare <$14 / <$B3; enemy: LOW BYTE ONLY <$15 / <$B5."""
    v = (int_stat & 0xFF) if enemy else int_stat
    if enemy:
        return 0 if v < 0x15 else (1 if v < 0xB5 else 2)
    return 0 if v < 0x14 else (1 if v < 0xB3 else 2)


def make_board(party, enemies, species=None, db73=0):
    """party: list (<=3) of dicts with hp/mp/atk/dfn/agl/int/level,
    'skills' (movepool ids), optional 'species' (for resistances/flying),
    optional 'tactic' (0-3, default 0 Charge).
    enemies: list (<=3) of enemy_stats.json records.
    db73: battle type byte (0 = wild; boss gates key on it)."""
    species = species or load_species()
    b = B.Board()
    b.db73 = db73
    b.eid = [0, 0, 0]
    b.party_skills = [None] * 3
    b.tactic = [0] * 3
    b.party_bases = [None] * 3
    b.wld = [0] * 3
    for i, m in enumerate(party):
        b.hp[i] = b.maxhp[i] = m['hp']; b.mp[i] = m.get('mp', 0)
        b.atk[i] = m['atk']; b.dfn[i] = m['dfn']; b.agl[i] = m['agl']
        b.int[i] = m['int']; b.level[i] = m.get('level', 1)
        b.wld[i] = m.get('wld', default_wld(b.level[i]))
        b.dd13[i] = 2; b.dd1b[i] = 0
        b.dd0b[i] = dd0b_mode(m['int'], enemy=False)
        b.dd03[i] = m.get('tactic', 0)
        b.tactic[i] = m.get('tactic', 0)
        b.party_skills[i] = list(m.get('skills', []))
        if m.get('ai_weights'):                 # (c1,c2,c3,w3) battle
            b.party_bases[i] = tuple(m['ai_weights'])   # order, pre-rolled
        sp = species.get(m.get('species'))
        if sp:
            b.res[i * 7:(i + 1) * 7] = pack_res(sp['resistances'])
            if sp.get('can_fly'):
                b.db8b[i] |= 0x10
    for j, e in enumerate(enemies):
        s = 4 + j
        b.hp[s] = b.maxhp[s] = e['hp']; b.mp[s] = e['mp']
        b.atk[s] = e['atk']; b.dfn[s] = e['def']; b.agl[s] = e['agl']
        b.int[s] = e['int']; b.level[s] = e['level']
        b.dd13[s] = 2; b.dd1b[s] = 0
        b.dd0b[s] = dd0b_mode(e['int'], enemy=True)
        b.dd03[s] = 0xFF
        b.eid[j] = e['enemy_stats_id']
        sp = species.get(e['species_id'])
        if sp:
            b.res[s * 7:(s + 1) * 7] = pack_res(sp['resistances'])
            if sp.get('can_fly'):
                b.db8b[s] |= 0x10
    return b


def board_from_event(e):
    """Board from a measure_battle round_start event, plus the commit
    inputs the driver needs (movepools unknown from the event — caller
    supplies via attach_commit_inputs)."""
    b = B.Board.from_event(e)
    b.party_skills = [None] * 3
    b.wld = [default_wld(l) for l in list(b.level)[:3]]  # stand-in; the
    # engine value is record slot+$60 (events do not carry it)
    b.party_bases = [None] * 3      # events predate the S87 dc44-array
    # capture; callers with real record bases attach them here
    b.tactic = [v & 3 if v != 0xFF else 0 for v in list(e['dd03'])[:3]]
    return b


# --------------------------------------------------------------------------
# Commit machine (offline)
# --------------------------------------------------------------------------
def _tag(rec):
    return (rec['battle_record']['fields']['effect_category'] >> 4) & 0xF


def option_list(skills, records):
    """$DC64 list: up to 4 {tag, skill}; tag = effect_category hi-nibble."""
    out = []
    for sk in skills[:4]:
        if sk == 0xFF or sk is None:
            break
        rec = records.get(sk)
        out.append(((_tag(rec) if rec else 1), sk))
    return out


class ChainRules:
    """ai.decide rules adapter over the validated ai_rules chains."""

    def __init__(self, b, actor, records):
        st = [b.st[s * 8:(s + 1) * 8] for s in range(8)]
        # MaxMP is not tracked on the Board; use current MP (affects only
        # the own-MP-full SuckAir presumption). Families/traits: neutral.
        # resist_score: the chains' element -> resistance-index mapping is
        # NOT pinned (validate_rules validated 240/240 with a zero stub);
        # matching that configuration here — S86 residual.
        self.view = R.BattleView(b.hp, b.maxhp, b.mp, b.mp, st, b.dd1b,
                                 [0] * 8, [None] * 8,
                                 lambda s, e: 0)
        self.actor = actor
        self.records = records

    def evaluate(self, category, skill, state):
        rec = self.records.get(skill)
        f = rec['battle_record']['fields'] if rec else {}
        delta, veto = R.evaluate_chain(
            category, skill, self.actor, self.view,
            f.get('mp_cost_byte', 0), f.get('flags9'), f.get('flags7', 0))
        return delta, veto


def _mk_rng(state_ref, idle, cls_between):
    """ai.py rng_step callable over our LCG stream (state_ref = [state])."""
    def step():
        state_ref[0] = B.rng_step(state_ref[0])
        return B.rng1(state_ref[0]), B.rng2(state_ref[0])
    return step


def lightweight_pick(opts, bases, plan_adj, is_enemy, rnd, state_ref):
    """$dd0b==0 AILightweightPick_76df, §15.10.10 decode main path:
    rank-1 category from the scored cells; per matching option weight
    (RNG1&7)+1; implicit extra candidate (cat1 -> plain Attack, other ->
    weak-heal path) weight (RNG2&7)+1; argmax with later-wins ties.
    Stand-in: the implicit candidate is always present (the d==2 corner
    is self-healing in the ROM and statistically negligible), and the
    weak-heal path resolves to Defence/Attack by own-HP need."""
    step = _mk_rng(state_ref, None, None)
    scores = A.category_scores(bases, plan_adj, is_enemy, step)
    _, ids = A.rank_categories(scores)
    cat = ids[0]
    best_w, best_act = -1, None
    for tag, sk in opts:
        if tag != cat:
            continue
        r1, _ = step()
        w = (r1 & 7) + 1
        if w >= best_w:
            best_w, best_act = w, sk
    _, r2 = step()
    w = (r2 & 7) + 1
    if w >= best_w:
        best_act = A.PLAIN_ATTACK if cat == 1 else 'weakheal'
    if best_act == 'weakheal':
        return A.DEFENCE
    return best_act if best_act is not None else A.PLAIN_ATTACK


def commit_actor(b, s, movepool, bases, records, rnd, state_ref,
                 is_enemy, plan_adj=(0, 0, 0)):
    """One actor's commit: returns (skill, target_byte)."""
    opts = option_list(movepool, records)
    if b.dd0b[s] == 0:
        act = lightweight_pick(opts, bases, list(plan_adj), is_enemy,
                               rnd, state_ref)
    else:
        step = _mk_rng(state_ref, None, None)
        rules = ChainRules(b, s, records)
        act, _ = A.decide(opts, bases, list(plan_adj),
                          lambda sk: records[sk]['battle_record']['fields'][
                              'ai_weight'] if sk in records else 10,
                          step, is_enemy=is_enemy, rules=rules)
    return act, _commit_target(b, s, act, records, state_ref)


def _commit_target(b, s, act, records, state_ref):
    """Commit-time target write (entry 8 / §15.10.8): plain Attack gets a
    CONCRETE front-weighted slot; heals/self-class get own base; other
    skills get the opposite side base (act-time resolution finishes)."""
    if act == A.PLAIN_ATTACK:
        opp = b.live_side((s & 4) ^ 4)
        if not opp:
            return 0xFF
        t, state_ref[0] = B.pick_front_weighted(opp, state_ref[0])
        return t
    rec = records.get(act)
    if rec and B.damage_core(act, rec) == 'heal':
        return s & 4
    if act == A.DEFENCE:
        return s
    return (s & 4) ^ 4


# --------------------------------------------------------------------------
# Obedience gate — EXACT (S87: byte-read + differentially validated,
# simulator/validate_obedience.py vs s87_obedience_events.json)
# --------------------------------------------------------------------------
# Act/loaf threshold table $57:$7997 (4 tactics x 27; data bytes, was
# misdisassembled as code). Consumed by AIPreambleLadder_791a -> $db53,
# which is a DIRECT ADDEND in the decide inequality (the S86 "consumption
# point still to pin" residual — closed S87).
OBED_THRESH = (
    25, 25, 25, 20, 20, 25, 25, 25, 25, 20, 15, 10, 20, 20,
    20, 20, 15, 20, 5, 15, 10, 20, 10, 10, 20, 5, 5,          # 0 Charge
    20, 10, 5, 20, 5, 10, 15, 10, 5, 25, 20, 25, 25, 15,
    20, 20, 20, 10, 25, 15, 10, 20, 10, 20, 25, 15, 5,        # 1 Mixed
    20, 5, 5, 20, 5, 10, 5, 15, 5, 25, 20, 25, 25, 20,
    20, 20, 10, 10, 25, 20, 10, 15, 10, 10, 15, 25, 5,        # 2 Cautious
    20, 5, 5, 5, 5, 10, 5, 5, 5, 25, 15, 10, 25, 20,
    10, 5, 5, 5, 25, 20, 15, 20, 20, 25, 20, 25, 5)           # 3 Command


def _band_row(v, hi_steps):
    """Base -> ladder row: >=$C0 row 0, >=$40 row 1, else row 2, scaled."""
    return 0 if v >= 0xC0 else (hi_steps if v >= 0x40 else 2 * hi_steps)


def obed_thresh_index(tactic, c1, c3, c2):
    """AIPreambleLadder_791a index: 27*tactic + cat1(0/9/18) +
    cat3(0/3/6) + cat2(0/1/2)."""
    return (27 * (tactic & 3) + _band_row(c1, 9)
            + _band_row(c3, 3) + _band_row(c2, 1))


def obed_band(wld):
    """LoadBtlAI_7a16 band width b from the wBattleLVL low byte — which
    holds the monster's WLD (wildness) stat, record slot+$60, NOT the
    level (S87; display level is $db9b). Enemies are forced $00FF."""
    lv = wld & 0xFF
    for lim, b in ((0x20, 5), (0x40, 7), (0x60, 9), (0x90, 11), (0xC0, 13)):
        if lv < lim:
            return b
    return 15


def obed_band_reduce(a, b):
    """The 7a16 tail loop over a = RNG1' & $3F: repeated `sub b` — result
    is a mod b, EXCEPT nonzero multiples of b return b itself (the
    `jr nz` fallthrough loads b). 0 stays 0."""
    if a == 0:
        return 0
    r = a % b
    return b if r == 0 else r


def obedience_decide(wld, db4c, db4d, db4e, db4f, db53):
    """AIPreambleDecide_7a5d on WLD: 0 or <$15 -> no-carry (tactic-bias
    path — tame monsters FOLLOW tactics); >=$F0 -> carry (unbiased/wild
    machine; enemy init forces $00FF). Between: carry iff
    db4e+db4f > db4c+db4d+db53 (STRICT; 8-bit sums, no wrap with
    vanilla-range weights)."""
    lv = wld & 0xFF
    if lv == 0 or lv < 0x15:
        return False
    if lv >= 0xF0:
        return True
    return ((db4c + db4d + db53) & 0xFF) < ((db4e + db4f) & 0xFF)


def obedience_carries(wld, bases, tactic, state_ref):
    """Full engine chain for one party actor. wld = the monster's WLD
    stat (record slot+$60; 5*level - 10*arenaTier at creation, 0 for
    hatchlings, item-adjustable). bases=(c1,c2,c3,w3) = battle arrays
    $DC44/$DC4C/$DC54/$DC5C (= party record +$5B/+$5E/+$5C/+$5D).
    Steps the modeled live RNG once (SaveBtlAI_7f2c in LoadBtlAI_7a16).
    Returns True = carry = act UNBIASED (wild); False = +20 tactic
    bias."""
    c1, c2, c3, w3 = bases
    db4c = {0: c1, 1: c2, 2: c3, 3: 0}[tactic & 3] // 10   # CmpBtlAI_78d4
    db4d = w3 // 10                                        # AIPreambleW3_7905
    db53 = OBED_THRESH[obed_thresh_index(tactic, c1, c3, c2)]
    db4e = (wld & 0xFF) >> 2                               # LoadBtlAI_7a03
    state_ref[0] = D.rng_step(state_ref[0])
    db4f = obed_band_reduce((D.rng1(state_ref[0])) & 0x3F, obed_band(wld))
    return obedience_decide(wld, db4c, db4d, db4e, db4f, db53)


# --------------------------------------------------------------------------
# Party category bases — REAL SOURCE (S87): the party monster's own
# instance record +$5B/+$5C/+$5D/+$5E -> $DC44 (cat1) / $DC54 (cat3) /
# $DC5C (w3) / $DC4C (cat2), filled by LoadBtlS_44cb at battle init.
# Record values = source enemy-stats row ai_weights [w0,w1,w3,w2] each
# through the one-time CREATION ROLL (bank $14 SaveEnem_47fd):
# factor m256 = $CD + (RNG mod $34); m256==$100 keeps the original
# (exactly 1.0x), else value = orig*m256 >> 8 — uniform ~0.801..0.996x
# plus the 1/52 exact-1.0 case. No mid-battle drift (writers = creation
# + breeding + field item effects only).
# --------------------------------------------------------------------------
def creation_roll(rnd):
    """One SaveEnem_47fd multiplier draw: returns m256 in 205..256."""
    return 0xCD + rnd.randrange(0x34)


def roll_weight(v, rnd):
    m256 = creation_roll(rnd)
    return v if m256 == 0x100 else (v * m256) >> 8


def party_bases_from_row(ai_weights, rnd=None):
    """(c1,c2,c3,w3) battle bases from an enemy_stats ai_weights row
    [+17..+20] = [w0(cat1), w1(cat3), w2(cat2), w3]. With rnd, applies
    the per-byte creation roll (one-time, as at monster creation);
    without, returns the raw row values (upper envelope)."""
    w0, w1, w2, w3 = ai_weights[:4]
    if rnd is None:
        return (w0, w2, w1, w3)
    return (roll_weight(w0, rnd), roll_weight(w2, rnd),
            roll_weight(w1, rnd), roll_weight(w3, rnd))


def default_wld(level, arena_tier=0):
    """Creation-time WLD (constructor $14:label14_40b4): 5*level -
    10*arenaTier ($CAB4), clamped 0..255. Post-creation it drifts via
    items (Add/SubMonsterWLD) and possibly level-up (writer not yet
    traced) — pass a measured value when you have one."""
    return max(0, min(0xFF, 5 * int(level) - 10 * int(arena_tier)))


PARTY_FALLBACK_BASES = (150, 100, 100, 100)  # documented REFERENCE
# personality (attack-leaning) for boards built without real record
# bases (board_from_event; synthetic parties that don't pass
# ai_weights). The machinery around it is now exact — only this default
# tuple is a modelling choice.


def commit_round(b, records, rnd, state, party_policy='attack',
                 enemy_recs=None, idle=None):
    """Fill b.queue for one round. enemy_recs: slot->enemy_stats record."""
    idle = idle or (lambda st, cls: st)
    state_ref = [state]
    for s in range(8):
        if not b.valid(s) or b.dd13[s] != 2:
            continue
        state_ref[0] = idle(state_ref[0], 'actor_skip')
        if s < 4:                                   # party
            if party_policy == 'attack' or not getattr(
                    b, 'party_skills', [None] * 3)[s]:
                act = A.PLAIN_ATTACK
                tgt = _commit_target(b, s, act, records, state_ref)
            else:
                tactic = getattr(b, 'tactic', [0] * 3)[s]
                pb = (getattr(b, 'party_bases', [None] * 3)[s]
                      or PARTY_FALLBACK_BASES)
                wld = getattr(b, 'wld', None)
                wld = wld[s] if wld else default_wld(b.level[s])
                carries = obedience_carries(wld, pb, tactic, state_ref)
                if tactic == 3 and not carries:     # Command w/o menu,
                    act = A.PLAIN_ATTACK            # no-carry: engine
                    tgt = _commit_target(b, s, act, records, state_ref)
                else:                               # carry -> UNBIASED
                    adj = [0, 0, 0]                 # machine (even tac 3
                    if not carries:                 # — S87 corrects the
                        adj[tactic] = 0x14          # old always-Attack
                    act, tgt = commit_actor(        # shortcut); no-carry
                        b, s, b.party_skills[s],    # tac 0-2: +20 bias
                        list(pb[:3]),               # ($6F8C; $2D when
                        records, rnd, state_ref,    # plan==$81 Command,
                        is_enemy=False,             # not driven here)
                        plan_adj=adj)
        else:                                       # enemy
            er = enemy_recs.get(s) if enemy_recs else None
            if er is None:
                act = A.PLAIN_ATTACK
                tgt = _commit_target(b, s, act, records, state_ref)
            else:
                w = er['ai_weights']
                bases = [w[0], w[2], w[1]]          # +17 cat1 +19 cat2 +18 cat3
                act, tgt = commit_actor(b, s, er['skills'], bases,
                                        records, rnd, state_ref,
                                        is_enemy=True)
        b.queue[s * 2] = act
        b.queue[s * 2 + 1] = tgt
    return state_ref[0]


# --------------------------------------------------------------------------
# Full battle + TTK
# --------------------------------------------------------------------------
def simulate_battle(b, records, dup_flags, idle, rnd, state=None,
                    party_policy='attack', enemy_recs=None, max_rounds=100):
    """Runs commit+round until a side wipes. Returns dict(winner, rounds,
    party_hp, enemy_hp, log). winner: 'party' | 'enemy' | 'timeout'."""
    state = state if state is not None else rnd.randrange(0x10000)
    log = []
    for rd in range(1, max_rounds + 1):
        state = commit_round(b, records, rnd, state, party_policy,
                             enemy_recs, idle)
        rlog, state = B.simulate_round(b, state, records, dup_flags, idle)
        log.append(rlog)
        if B.side_wiped(b, 4):
            return dict(winner='party', rounds=rd, party_hp=b.hp[:3],
                        enemy_hp=b.hp[4:7], log=log)
        if B.side_wiped(b, 0):
            return dict(winner='enemy', rounds=rd, party_hp=b.hp[:3],
                        enemy_hp=b.hp[4:7], log=log)
    return dict(winner='timeout', rounds=max_rounds, party_hp=b.hp[:3],
                enemy_hp=b.hp[4:7], log=log)


def ttk(board_factory, records, dup_flags, trials=500, seed=0,
        idle_mode='empirical', party_policy='attack', enemy_recs=None,
        max_rounds=100, idle=None):
    """board_factory() -> fresh Board per trial. Returns summary stats.
    Pass `idle` to share one IdlePolicy across many calls (sweeps)."""
    idle = idle or IdlePolicy(idle_mode, seed=seed)
    rnd = random.Random(seed ^ 0x5A5A)
    rounds, wins = [], {'party': 0, 'enemy': 0, 'timeout': 0}
    for t in range(trials):
        b = board_factory()
        r = simulate_battle(b, records, dup_flags, idle, rnd,
                            party_policy=party_policy,
                            enemy_recs=enemy_recs, max_rounds=max_rounds)
        rounds.append(r['rounds']); wins[r['winner']] += 1
    rs = sorted(rounds)
    n = len(rs)
    return dict(trials=n, wins=wins,
                rounds_med=rs[n // 2], rounds_p10=rs[n // 10],
                rounds_p90=rs[(9 * n) // 10],
                rounds_mean=sum(rs) / n)
