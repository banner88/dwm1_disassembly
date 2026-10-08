"""kits.py — the skill KIT a skilled player brings at a story step (S130,
ROADMAP P3.15b; the Balance service's 'player' profile, editor2/core/balance.py).

The project owner: "Which 8 skills you can bring together on 3 monsters is
almost the sole determiner of success" — one general kit per step (not per
fight), commanded in battle (simulator/planner.py), the arena on its best
tactic. Headless (never imports Qt).

  step_pool(data, tl, step, level)  what the player can have at the step:
        the species (the step's roster: wild joins, boss joins of the cleared
        gates, the starter; once breeding is open (tl.roster(step)['breeding'])
        also every species bred from obtainable parents over 2 generations —
        3 postgame — with the resolver (editor2/core/breeding.py) and the plus
        that crossing parents of that level gives), and the skill pool: the
        natural skills of every obtainable species + the skills of every join
        row, as the bases a bred monster's learn queue can hold
        (UnevolvedSkillMap; bases $FF never pass on).
  allowed_skills(data, pool, spec, m)  the skills monster m (raised by
        simulator/raising.py to the level) can carry:
          joined   its row's 4 skills + its species' natural skills and the
                   upgrades of everything it knows (learn rows: level + the six
                   stat thresholds, checked against m's stats);
          bred     every skill whose base is in the step's pool, chain by
                   chain (Blaze -> Blazemore -> Blazemost: every link's learn
                   row met by m), a skill that is its own base learned straight
                   from the queue; combination skills (several prerequisites,
                   e.g. BigBang = Explodet + WhiteFire + WhiteAir) only beside
                   all their prerequisites in the same kit (unless the skill
                   itself is in the pool).
        Skills no learn row teaches (Attack-likes, items, boss-only) come only
        from join rows — they are not in any base set.
  kit_team(data, tl, step, kit, level, t)  the kit's 3 members raised to the
        team level's EXP (the Balance service's axis; level caps hold),
        carrying the kit's skills that are learnable at THAT level (the
        others are dropped and the slots refilled with what the monster knows).
  optimize_kit(...)  local search from the best of three 'strong' rolls:
        mutate one member's species (the stronger species — member_power at
        the level — proposed first; a fresh default skill set keeping the
        skills it can still carry) or one skill (the candidates ranked by the
        planner's own value of each as an order on the hardest fights at the
        start, at 35 % HP and with a teammate down; the member's least useful
        skill replaced first) or, in the arena, the order (the tactics AI only
        sees the first 4); keep the change when the score improves. Score =
        win % + 0.15 x the enemies' HP removed, over the three fights the
        start wins least: the hardest of them (the "wall" — the one the
        candidate wins least) 60 %, their mean 40 %. Common random numbers:
        every candidate meets the same battles; an improvement is kept only
        if it holds over a second set of battles too (a lucky draw is not a
        better kit); a kit that wins everything ends the search (the level
        iteration then goes lower). Deterministic for a given
        budget (`evals` = evaluations, x4 for an arena step whose battles need
        no planner; `time_limit` stops early and is then NOT deterministic).
  step_kit(...)  the level iteration: L0 = the level where a 'strong' roll,
        commanded, wins >= 50 % of every key fight (bosses / arena matches);
        optimise there; L1 = the optimised kit's own such level; if L1 < L0,
        optimise again at L1 from that kit (a third of the budget), at most
        twice. The kit records the level it was last optimised at ('level').
  Recruitment realism: a join form is only offered when its row level is at
        most the team level + 2 (it has to be beaten to join); a bred form
        only from team level 10 (both parents need level 10+) — below that the
        kit's bred members fall back to their join form or the strongest join
        form left; a bred member stuck at its level cap is bred again with
        the plus it needs (max level = cap + 2 x plus).

A kit (JSON):
  {"step", "level", "members": [{"species", "name", "src": ["join", eid] |
   ["bred", pedigree sp, mate sp], "plus", "skills": [ids], "skill_names"}],
   "score", "evals", "seconds", "fights": {key: {"win", "tactic"}},
   "why": [one line per member], "version"}
"""
from __future__ import annotations

import random
import time

from simulator import raising as R

FF = 0xFF
KIT_VERSION = 1
MAX_SKILLS = 8
NO_KIT = frozenset(range(0x97, 0xD5)) | {0xDA, 0xDB, 0x3A, 0x8D}   # meta / item / boss-only
#                                   ids, Attack and Defence (every monster has those)
WALL_WEIGHT = 0.6
TACTIC_NAMES = ('Charge', 'Mixed', 'Cautious', 'Command')
ARENA_EVALS = 4          # an arena step's budget x this (its battles are cheap)
PLANNER_DRAWS = 2        # the kit search's planner (the Balance service's uses 3)
JOIN_MARGIN = 2          # join rows up to the team level + 2 (see StepPool)


# ---------------------------------------------------------------------------
# the step's pool
# ---------------------------------------------------------------------------
def _bonus(level_sum):
    from .breeding import LEVEL_BONUS
    for lo, bonus in LEVEL_BONUS:
        if level_sum >= lo:
            return bonus
    return 0


class StepPool:
    """Obtainable species (+ how) and skill bases at a step for a team level."""

    def __init__(self, data, tl, step, level):
        from . import balance as BL
        from .breeding import FastResolver
        T = data.T
        self.step = step
        self.level = level
        self.key = (id(data), id(tl), step, level, BL.raising_digest(data))
        ro = tl.roster(step)
        self.breeding = ro['breeding']
        # a monster that joins at a level well above the team's is not one the
        # team could have recruited (it has to be beaten first)
        self.joins = [e for e in ro['joins'] if T.enemy(e)[4] <= level + JOIN_MARGIN] or \
            [min(ro['joins'], key=lambda e: T.enemy(e)[4])]
        self.tier = tl.arena_tier(step)
        # join forms: the highest-level roster row of each species
        self.join = {}
        for e in self.joins:
            sp = T.enemy(e)[0]
            if sp not in self.join or T.enemy(e)[4] > T.enemy(self.join[sp])[4]:
                self.join[sp] = e
        # bred forms: {sp: (pedigree sp, mate sp, plus, gen)}
        self.bred = {}
        br = BL._breeder(data)
        # a bred member needs two parents of level 10+: below team level 10 the
        # player's team is what joined (the parents would outclass the kids)
        self.bred_ok = self.breeding and level >= 10
        if self.bred_ok and br is not None:
            fr = FastResolver(br)
            pl = max(level, 10)
            bon = _bonus(2 * pl)
            gens = 3 if step >= BL.POSTGAME_FROM_INDEX(tl) else 2
            plus = {sp: 0 for sp in self.join}
            for _g in range(gens):
                new = {}
                parents = sorted(plus)
                for a in parents:
                    for b2 in parents:
                        p = min(99, max(plus[a], plus[b2]) + 1 + bon)
                        sp, how, idx = fr.resolve(a, b2, p)
                        if how == 'special':
                            p = min(99, p + br.special[idx][4])
                        if sp in range(215, 221) or sp not in T.info or sp in self.bred:
                            continue
                        if sp in (a, b2) and sp not in self.join:
                            continue
                        if sp not in new or p > new[sp][2]:
                            new[sp] = (a, b2, p, _g + 1)
                for sp, v in new.items():
                    self.bred[sp] = v
                    plus[sp] = max(plus.get(sp, 0), v[2])
        self.species = sorted(set(self.join) | set(self.bred))
        # the skill bases a bred monster's queue can hold
        bases = set()
        unev = T.unevolved
        for sp in self.species:
            for s in T.info[sp][6:9]:
                if s != FF and unev[s] != FF:
                    bases.add(unev[s])
        for e in self.joins:
            for s in T.enemy(e)[21:25]:
                if s != FF and unev[s] != FF:
                    bases.add(unev[s])
        self.bases = bases

    def spec(self, sp, prefer_bred=True):
        """The member spec of species sp: its bred form once breeding is open
        (plus, WLD 0, inherits the pool), else its join row."""
        if prefer_bred and sp in self.bred:
            a, b2, p, _g = self.bred[sp]
            return {'species': sp, 'src': ['bred', a, b2], 'plus': p}
        if sp in self.join:
            return {'species': sp, 'src': ['join', self.join[sp]], 'plus': 0}
        if sp in self.bred:
            a, b2, p, _g = self.bred[sp]
            return {'species': sp, 'src': ['bred', a, b2], 'plus': p}
        return None


_POOLS = {}


def step_pool(data, tl, step, level):
    from . import balance as BL
    k = (id(data), id(tl), step, level, BL.raising_digest(data))
    if k not in _POOLS:
        if len(_POOLS) > 256:
            _POOLS.clear()
        _POOLS[k] = StepPool(data, tl, step, level)
    return _POOLS[k]


# ---------------------------------------------------------------------------
# members
# ---------------------------------------------------------------------------
def _seed(*parts):
    from . import balance as BL
    return BL._seed(*parts)


def build_member(data, pool, spec, exp, seed, depth=0):
    """The Monster of `spec` raised to `exp` (the reference exp axis): a join
    row created + raised, or two parents (their own forms, raised to the same
    exp, at least level 10) crossed + born + raised. Deterministic per seed."""
    from . import balance as BL
    T = data.T
    rng = random.Random(_seed('kitm', seed, spec['species'], tuple(spec['src']), exp))
    src = spec['src']
    if src[0] == 'join':
        m = R.create(T, src[1], rng, arena_tier=pool.tier)
        BL.raise_to(T, m, exp, rng, 'strong', data.skill_value)
        m.origin = f'eid {src[1]}'
        return m
    pexp = max(exp, BL.exp_for_level(T, 10))
    ps = []
    for k, sp in enumerate(src[1:3]):
        if sp in pool.join:
            ps2 = pool.spec(sp, prefer_bred=False)
        elif sp in pool.bred and depth < 4:
            ps2 = pool.spec(sp, prefer_bred=True)
        else:
            raise ValueError(f'no parent form for species {sp}')
        ps.append(build_member(data, pool, ps2, pexp, seed * 3 + k + 1, depth + 1))
    p1, p2 = ps
    br = BL._breeder(data)
    plus = spec.get('plus', 0)
    if br is not None:
        try:
            plus = br.resolve(p1.species, p2.species, p1.plus, p2.plus, p1.level, p2.level).plus
        except Exception:                                   # noqa: BLE001
            pass
    plus = max(plus, spec.get('plus_min', 0))
    kid = R.breed_and_birth(T, p1, p2, spec['species'], plus, rng)
    kid.origin = f'bred: {data.names.get(p1.species)} x {data.names.get(p2.species)}'
    BL.raise_to(T, kid, exp, rng, 'strong', data.skill_value)
    return kid


def _req_ok(T, c, m):
    row = T.learn.get(c)
    if row is None or row[0] == FF:
        return False
    if m.level < row[0]:
        return False
    for i in range(6):
        if m.stats[i] < (row[1 + 2 * i] | row[2 + 2 * i] << 8):
            return False
    return True


def _prereqs(T, c):
    row = T.learn.get(c)
    if row is None:
        return []
    out = []
    for x in row[13:18]:
        if x == FF:
            break
        out.append(x)
    return out


def _chain_ok(T, c, m, roots, known=(), seen=None):
    """c learnable by m from a root in `roots` (bases in its queue) or a skill
    it already `known`s: c itself a root (queue rule), or one prerequisite
    that is chain-learnable (upgrade); every link's learn row met."""
    if c in known:
        return True
    seen = seen or set()
    if c in seen or not _req_ok(T, c, m):
        return False
    if c in roots:
        return True
    pre = _prereqs(T, c)
    if len(pre) == 1:
        return _chain_ok(T, pre[0], m, roots, known, seen | {c})
    return False


def allowed_skills(data, pool, spec, m):
    """-> (allowed set, combos {skill: [prereqs]}) for member m of `spec`."""
    T = data.T
    unev = T.unevolved
    out = set()
    combos = {}
    if spec['src'][0] == 'join':
        known = [s for s in T.enemy(spec['src'][1])[21:25] if s != FF]
        out.update(s for s in known if s not in NO_KIT)
        q = [s for s in T.info[m.species][6:9] if s != FF]
        kb = {unev[s] for s in known if unev[s] != FF}
        roots = {s for s in q if s not in kb}
    else:
        roots = set(pool.bases)
        known = []
    for c in T.learn_ids:
        if c in NO_KIT or c in out:
            continue
        if spec['src'][0] == 'bred' and (unev[c] == FF or unev[c] not in pool.bases):
            if unev[c] != c:
                continue
        if _chain_ok(T, c, m, roots, known):
            out.add(c)
            continue
        pre = _prereqs(T, c)
        if len(pre) >= 2 and _req_ok(T, c, m):
            combos[c] = pre
    # a combo is possible when all its prerequisites are
    combos = {c: p for c, p in combos.items() if all(x in out for x in p)}
    return out, combos


def kit_valid_skills(skills, allowed, combos):
    """The kit's skills a member can carry (combos only beside their
    prerequisites), in kit order."""
    out = []
    for s in skills:
        if s in allowed or (s in combos and all(x in skills for x in combos[s])):
            if s not in out:
                out.append(s)
    return out[:MAX_SKILLS]


_MEMBERS = {}


def kit_member(data, pool, mspec, exp, seed):
    """(Monster raised, allowed, combos) memoised."""
    from . import balance as BL
    k = (pool.key, mspec['species'], tuple(mspec['src']), exp, seed, mspec.get('plus_min', 0))
    v = _MEMBERS.get(k)
    if v is None:
        if len(_MEMBERS) > 4000:
            _MEMBERS.clear()
        m = build_member(data, pool, mspec, exp, seed)
        al, co = allowed_skills(data, pool, mspec, m)
        v = (m, al, co)
        _MEMBERS[k] = v
    return v


def default_skills(data, allowed, have=(), n=MAX_SKILLS):
    """A sensible default set from `allowed`: the skills of `have` it can
    carry, then the strongest attacks, one heal, a revive, MetalCut."""
    from . import balance as BL
    out = [s for s in have if s in allowed][:n]
    heal = [s for s in out if BL._is_heal(data, s)]

    def val(s):
        v = data.skill_value(s)
        if s == 0x48:
            v += 40
        return v
    for s in sorted(allowed, key=lambda s: (-val(s), s)):
        if len(out) >= n:
            break
        if s in out:
            continue
        if BL._is_heal(data, s):
            if heal:
                continue
            heal.append(s)
        out.append(s)
    return out


def available_spec(data, pool, ms, level, used=(), seed=130):
    """The member spec as the player can have it at this level: a join row
    above the team level + 2 -> the species' row that is recruitable, else
    the strongest join form left; a bred form below level 10 (or before
    breeding) -> its join form, else the strongest join form left. Keeps the
    kit's skills (kit_valid_skills drops what the new form cannot carry)."""
    sub = None
    if ms['src'][0] == 'join' and ms['src'][1] not in pool.joins:
        sub = ms['species'] if ms['species'] in pool.join else None
    elif ms['src'][0] == 'bred' and not pool.bred_ok:
        sub = ms['species'] if ms['species'] in pool.join else None
    elif ms['src'][0] == 'bred' and not all(x in pool.join or x in pool.bred
                                            for x in ms['src'][1:3]):
        # a parent the kit was bred from is not obtainable at this (lower)
        # level: the same species through this level's own recipe, else its
        # join form, else the strongest join form left
        if ms['species'] in pool.bred:
            out = dict(pool.spec(ms['species'], prefer_bred=True), skills=list(ms['skills']))
            if ms.get('plus_min'):
                out['plus_min'] = ms['plus_min']
            return out
        sub = ms['species'] if ms['species'] in pool.join else None
    else:
        return ms
    if sub is None:
        sub = next((x for _p, x in rank_species(data, pool, level, seed)
                    if x not in used and x in pool.join),
                   next(iter(pool.join), ms['species']))
    return dict(pool.spec(sub, prefer_bred=False), skills=list(ms['skills']))


def kit_team(data, tl, step, kit, level, t=0, seed=130):
    """[Monster x3] — the kit raised to the team level's exp, carrying the
    kit skills learnable there (slots left filled with what it knows)."""
    from . import balance as BL
    exp = BL.exp_for_level(data.T, level)
    pool = step_pool(data, tl, step, level)
    team = []
    used = set()
    for i, ms in enumerate(kit['members']):
        ms = available_spec(data, pool, ms, level, used, seed)
        used.add(ms['species'])
        m0, al, co = kit_member(data, pool, ms, exp, _seed(seed, t, i))
        if m0.level < BL.CAP_SWAP * level and ms['src'][0] == 'bred':
            # stuck at its level cap: the player breeds it again with more
            # plus (max level = cap + 2 x plus), as the rolled profiles swap
            need = (level - data.T.info[ms['species']][1]) // 2 + 2
            ms2 = dict(ms, plus_min=min(99, max(need, ms.get('plus', 0))))
            m0, al, co = kit_member(data, pool, ms2, exp, _seed(seed, t, i))
        m = m0.copy()
        sk = kit_valid_skills(list(ms['skills']), al, co)
        for s in m0.skills:
            if len(sk) >= MAX_SKILLS:
                break
            if s not in sk and s not in NO_KIT:
                sk.append(s)
        m.skills = sk
        m.origin = m0.origin + ' (kit)'
        team.append(m)
    return team


# ---------------------------------------------------------------------------
# evaluation
# ---------------------------------------------------------------------------
def fight_policy(fight):
    return 'tactics' if fight['db73'] == 2 else 'command'


def eval_team(data, fight, team, battles, seed, usage=None, tactics=None):
    """{'win', 'ehp' (enemy HP left), 'tactic'} of one team on one fight:
    commanded (planner) or, in the arena, the best of the 4 tactics."""
    from . import balance as BL
    from simulator import pacing as P
    from simulator import planner as PL
    res = None
    tacs = ([None] if fight['db73'] != 2 else (tactics if tactics is not None else (0, 1, 2, 3)))
    for tac in tacs:
        idle = P.IdlePolicy('empirical', seed=seed)     # the same battles for each tactic
        party = [BL.party_dict(m, tac or 0) for m in team]
        pl = BL.NO_ORDER if tac == 3 else None          # the arena's "NO SP SK"
        if tac is None:
            pl = PL.make_planner(data.records, draws=PLANNER_DRAWS)
            if usage is not None:
                pl0 = pl

                def pl(b, s, _p=pl0):
                    r = _p(b, s)
                    usage[(s, r[0])] = usage.get((s, r[0]), 0) + 1
                    return r
        rnd = random.Random(seed * 7919 + 17)
        w = 0
        ehp = 0.0
        for _k in range(battles):
            eids = BL._pick_group(fight, rnd)
            o = {}
            win, _r, _a, _n, _c = BL.battle_once(data, party, eids, fight['db73'], rnd, idle,
                                                 out=o, planner=pl)
            w += win == 'party'
            ehp += o['enemy_hp_left']
        r = {'win': w / battles, 'ehp': ehp / battles, 'tactic': tac}
        if res is None or (r['win'], -r['ehp']) > (res['win'], -res['ehp']):
            res = r
    return res


def score_of(results, wall=None):
    """Win % (+ a little for the enemies' HP removed): the HARDEST fight (the
    wall — the one this kit wins least) 60 %, the mean of all 40 %."""
    def one(r):
        return r['win'] + 0.15 * (1.0 - r['ehp'])
    if not results:
        return 0.0
    vals = [one(r) for r in results.values()]
    return WALL_WEIGHT * min(vals) + (1 - WALL_WEIGHT) * sum(vals) / len(vals)


def evaluate_kit(data, tl, step, kit, level, fights, teams=2, battles=6, seed=130,
                 usage=None, tactics=None):
    """{fight key: {'win', 'ehp', 'tactic'}} — `teams` raisings x `battles`."""
    out = {}
    tlist = [kit_team(data, tl, step, kit, level, t, seed) for t in range(teams)]
    for f in fights:
        agg = {'win': 0.0, 'ehp': 0.0, 'tactic': None}
        tc = {}
        for t, team in enumerate(tlist):
            tac = (tactics or {}).get(f['key'])
            r = eval_team(data, f, team, battles, seed * 31 + t, usage,
                          tactics=None if tac is None else (tac,))
            agg['win'] += r['win'] / teams
            agg['ehp'] += r['ehp'] / teams
            tc[r['tactic']] = tc.get(r['tactic'], 0) + 1
        agg['tactic'] = max(tc, key=lambda k: tc[k]) if tc else None
        out[f['key']] = agg
    return out


# ---------------------------------------------------------------------------
# the search
# ---------------------------------------------------------------------------
def _wall(tl, step, fights):
    """The step's hardest fight by the story: its last boss fight, else its
    last arena match, else its last list."""
    bosses = [f for f in fights if f['kind'] == 'boss']
    if bosses:
        return bosses[-1]['key']
    ar = [f for f in fights if f['kind'] == 'arena']
    if ar:
        return ar[-1]['key']
    return fights[-1]['key'] if fights else None


def kit_from_team(data, pool, team):
    """A strong roll -> a kit (members as their pool forms at the level)."""
    mem = []
    for m in team:
        spec = pool.spec(m.species)
        if spec is None:
            continue
        spec['skills'] = [s for s in m.skills if s not in NO_KIT][:MAX_SKILLS]
        mem.append(spec)
    return {'members': mem}


def _norm(data, tl, step, kit, level, seed):
    """Drop skills a member cannot carry at `level`; fill free slots."""
    from . import balance as BL
    exp = BL.exp_for_level(data.T, level)
    pool = step_pool(data, tl, step, level)
    used = set()
    for i, ms0 in enumerate(list(kit['members'])):
        ms = available_spec(data, pool, ms0, level, used, seed)
        used.add(ms['species'])
        kit['members'][i] = ms
        m, al, co = kit_member(data, pool, ms, exp, _seed(seed, 0, i))
        sk = kit_valid_skills(ms['skills'], al, co)
        if len(sk) < MAX_SKILLS:
            sk = default_skills(data, al, sk)
        ms['skills'] = sk
        ms['plus'] = m.plus
    return kit


def _copy(kit):
    return {'members': [dict(m, src=list(m['src']), skills=list(m['skills']))
                        for m in kit['members']]}


# ---------------------------------------------------------------------------
# proposal rankings (what to try first)
# ---------------------------------------------------------------------------
_RANKS = {}


def rank_skills(data, tl, step, kit, level, i, cands, fights, seed=130):
    """{skill: worth} of `cands` for member i: the planner's value of each as
    an order (minus plain Attack's) on the first group of each of `fights`,
    best of three scenes — the battle's start, the party at 35 % HP, a
    teammate down (heals and revives matter there)."""
    from . import balance as BL
    from simulator import pacing as P
    from simulator import planner as PL
    ms = kit['members'][i]
    k = (id(data), id(tl), step, level, i, ms['species'], tuple(ms['src']),
         tuple(f['key'] for f in fights), seed)
    if k in _RANKS:
        return _RANKS[k]
    team = kit_team(data, tl, step, kit, level, 0, seed)
    party = [BL.party_dict(m) for m in team]
    party[i] = dict(party[i], skills=sorted(cands))
    out = {c: -1.0 for c in cands}
    pl = PL.make_planner(data.records, draws=2)
    for f in fights:
        eids = f['groups'][0][1]
        enemies = [data.enemy_rec(e) for e in eids]
        er = {4 + j: enemies[j] for j in range(len(enemies))}
        for scene in ('start', 'hurt', 'down'):
            b = BL._board(data, party, enemies, 1 if f['db73'] == 2 else f['db73'])
            b.ext['f10_optlists'] = P._f10_optlists(b, data.records, er)
            if scene == 'hurt':
                for a in range(3):
                    b.hp[a] = max(1, int(b.maxhp[a] * 0.35))
            elif scene == 'down':
                d = (i + 1) % 3
                b.hp[d] = 0
                b.dd1b[d] = 1
                b.dd13[d] = 0xFF
            vals = pl.values(b, i)
            base = vals.get((0x3A, None), 0.0)
            for (sk, _tg), v in vals.items():
                if sk in out:
                    out[sk] = max(out[sk], v - base)
    _RANKS[k] = out
    if len(_RANKS) > 2000:
        _RANKS.clear()
    return out


_SPRANK = {}


def rank_species(data, pool, level, seed=130):
    """[(power, species)] best first — member_power of each obtainable
    species' form at the level with its default skills (capped members
    count at their capped level)."""
    from . import balance as BL
    k = (pool.key, level, seed)
    if k not in _SPRANK:
        if len(_SPRANK) > 256:
            _SPRANK.clear()
        exp = BL.exp_for_level(data.T, level)
        out = []
        for sp in pool.species:
            spec = pool.spec(sp)
            try:
                m, al, _co = kit_member(data, pool, spec, exp, _seed(seed, 0, 0))
            except ValueError:
                continue
            m2 = m.copy()
            m2.skills = default_skills(data, al)
            out.append((BL.member_power(data, m2), sp))
        out.sort(reverse=True)
        _SPRANK[k] = out
    return _SPRANK[k]


def _mutate(data, tl, step, kit, level, rng, pool, arena, seed, rank_fights=()):
    from . import balance as BL
    exp = BL.exp_for_level(data.T, level)
    k2 = _copy(kit)
    i = rng.randrange(len(k2['members']))
    ms = k2['members'][i]
    r = rng.random()
    if r < 0.22:
        # a new species for member i (the stronger ones first)
        sr = rank_species(data, pool, level, seed)
        if not sr:
            return None, 'none'
        sp = sr[min(len(sr) - 1, int(rng.random() ** 2.5 * len(sr)))][1]
        spec = pool.spec(sp)
        if spec is None:
            return None, 'none'
        m, al, co = kit_member(data, pool, spec, exp, _seed(seed, 0, i))
        if m.level < 0.85 * level and rng.random() < 0.8:
            return None, 'capped'
        spec['skills'] = default_skills(data, al, ms['skills'])
        spec['plus'] = m.plus
        k2['members'][i] = spec
        return k2, f'member {i} -> {data.names.get(sp)}'
    m, al, co = kit_member(data, pool, ms, exp, _seed(seed, 0, i))
    if arena and r < 0.4 and len(ms['skills']) > 4:
        a = rng.randrange(4)
        b2 = rng.randrange(4, len(ms['skills']))
        ms['skills'][a], ms['skills'][b2] = ms['skills'][b2], ms['skills'][a]
        return k2, f'member {i} order'
    cand = sorted((al | set(co)) - set(ms['skills']))
    if not cand:
        return None, 'none'
    rk = None
    if rank_fights:
        rk = rank_skills(data, tl, step, k2, level, i, sorted(al | set(co)), rank_fights, seed)
    if rk is not None and rng.random() < 0.8:
        cand.sort(key=lambda s: (-rk.get(s, -1.0), s))
        new = cand[min(len(cand) - 1, int(rng.random() ** 3 * len(cand)))]
    elif rng.random() < 0.5:
        cand.sort(key=lambda s: -data.skill_value(s))
        new = cand[min(len(cand) - 1, int(rng.random() ** 2 * len(cand)))]
    else:
        new = rng.choice(cand)
    if new in co:
        missing = [x for x in co[new] if x not in ms['skills']]
        if len(missing) + 1 > MAX_SKILLS - 0:
            return None, 'none'
        add = missing + [new]
    else:
        add = [new]
    sk = list(ms['skills'])
    for s in add:
        if len(sk) < MAX_SKILLS:
            sk.append(s)
        else:
            j = rng.randrange(len(sk))
            if rk is not None and rng.random() < 0.7:
                order = sorted(range(len(sk)), key=lambda q: rk.get(sk[q], -1.0))
                j = order[min(len(order) - 1, int(rng.random() * 3))]
            tries = 0
            while sk[j] in add and tries < 10:
                j = rng.randrange(len(sk))
                tries += 1
            sk[j] = s
    ms['skills'] = kit_valid_skills(sk, al, co)
    return k2, f'member {i} + {data.skill_names.get(new)}'


def optimize_kit(data, tl, step, level, start=None, evals=50, teams=2, battles=6, seed=130,
                 time_limit=None, fights=None, log=None, progress=None):
    """Local search for one step's kit at `level`. Returns the kit (JSON)."""
    from . import balance as BL
    t0 = time.time()
    st = tl.steps[step]
    allf = [tl.fights[k] for k in st['fights']]
    wall = _wall(tl, step, allf)
    pool = step_pool(data, tl, step, level)
    arena = any(f['db73'] == 2 for f in allf)
    if allf and all(f['db73'] == 2 for f in allf):
        evals *= ARENA_EVALS          # tactics battles need no planner: ~10x cheaper
    n_ev = [0]

    def ev(kit, fl, tac=None, sd=seed):
        n_ev[0] += 1
        return evaluate_kit(data, tl, step, kit, level, fl, teams, battles, sd, tactics=tac)

    # the start: the given kit, else the best of 3 strong rolls
    starts = []
    if start is not None:
        starts.append(_norm(data, tl, step, _copy(start), level, seed))
    else:
        for t in range(3):
            team = BL.roll_team(data, tl, step, level,
                                random.Random(_seed(seed, 'kitstart', step, level, t)), 'strong')
            k = kit_from_team(data, pool, team)
            if len(k['members']) == 3:
                starts.append(_norm(data, tl, step, k, level, seed))
    if not starts:
        sr = [sp for _p, sp in rank_species(data, pool, level, seed)][:3]
        k = {'members': [dict(pool.spec(sp), skills=[]) for sp in sr]}
        starts.append(_norm(data, tl, step, k, level, seed))
    fl = fights if fights is not None else allf
    best, best_r = None, None
    for k in starts:
        r = ev(k, fl)
        if best is None or score_of(r, wall) > score_of(best_r, wall):
            best, best_r = k, r
    # the search works on the three fights the start wins least (the story's
    # wall — the last boss / match — among them); the others add no signal
    work = sorted(fl, key=lambda f: (best_r[f['key']]['win'] + 0.15 * (1 - best_r[f['key']]['ehp']),
                                     f['key'] != wall))[:3]
    if wall not in [f['key'] for f in work] and fl:
        work = work[:2] + [tl.fights[wall]]
    tac = None
    if arena:
        tac = {k: v['tactic'] for k, v in best_r.items()}
    cur_r = {f['key']: best_r[f['key']] for f in work}
    cur = score_of(cur_r, wall)
    rng = random.Random(_seed(seed, 'kitsearch', step, level))
    hist = []
    stale = 0
    cur2 = None                       # the incumbent on the confirmation battles
    top = score_of({'x': {'win': 1.0, 'ehp': 0.0}})
    if cur >= top - 1e-9:
        cur2 = score_of(ev(best, work, tac, seed + 1), wall)
        if cur2 >= top - 1e-9:
            evals = 0                     # the start wins everything already
    while n_ev[0] < evals:
        if time_limit is not None and time.time() - t0 > time_limit:
            break
        cand, what = _mutate(data, tl, step, best, level, rng, pool, arena, seed, work)
        if cand is None:
            stale += 1
            if stale > 200:
                break
            continue
        r = ev(cand, work, tac)
        sc = score_of(r, wall)
        if sc > cur + 1e-9:
            # confirm on a second set of battles (a lucky draw is not a better kit)
            if cur2 is None:
                cur2 = score_of(ev(best, work, tac, seed + 1), wall)
            sc2 = score_of(ev(cand, work, tac, seed + 1), wall)
            if sc + sc2 > cur + cur2 + 1e-9:
                best, cur, cur_r, cur2 = cand, sc, r, sc2
                hist.append((n_ev[0], round(sc, 4), what))
                if log:
                    log(f'  eval {n_ev[0]}: {sc:.3f}/{sc2:.3f} <- {what}')
                if cur >= top - 1e-9 and cur2 >= top - 1e-9:
                    break                 # wins everything: nothing left to learn here
        if progress:
            progress(n_ev[0], evals, cur)
        if arena and n_ev[0] % 15 == 0:
            r = ev(best, work)            # re-pick the tactics for the incumbent
            tac = {k: v['tactic'] for k, v in r.items()}
    # the final read-out over every fight, with the planner's choices
    usage = {}
    fin = evaluate_kit(data, tl, step, best, level, allf, teams, battles, seed, usage=usage)
    kit = describe(data, tl, step, best, level, fin, usage)
    hardest = min(fin, key=lambda k: (fin[k]['win'], -fin[k]['ehp'])) if fin else None
    kit.update({'score': round(score_of(fin, wall), 4), 'evals': n_ev[0],
                'seconds': round(time.time() - t0, 1), 'wall': hardest,
                'history': hist[-12:]})
    return kit


def describe(data, tl, step, kit, level, results, usage):
    """The kit as JSON + a 'why' line per member (what the planner used)."""
    mem = []
    why = []
    team = kit_team(data, tl, step, kit, level, 0)     # as fought (caps re-bred)
    for i, ms in enumerate(kit['members']):
        m = team[i]
        used = sorted(((n, s) for (slot, s), n in usage.items() if slot == i), reverse=True)
        tot = sum(n for n, _s in used) or 1
        src = ms['src']
        how = (f"joins (EID {src[1]})" if src[0] == 'join' else
               f"bred {data.names.get(src[1])} x {data.names.get(src[2])} (+{ms.get('plus', 0)})")
        mem.append({'species': ms['species'], 'name': data.names.get(ms['species'], f"#{ms['species']}"),
                    'src': list(src), 'plus': ms.get('plus', 0), 'skills': list(ms['skills']),
                    'skill_names': [data.skill_names.get(s, f'#{s}') for s in ms['skills']],
                    'level': m.level, 'wld': m.wld})
        top = ', '.join(f"{data.skill_names.get(s, s)} {100 * n // tot}%" for n, s in used[:4])
        tacs = sorted({v['tactic'] for v in results.values() if v.get('tactic') is not None})
        why.append(f"{mem[-1]['name']} L{m.level} ({how}): " +
                   (f'ordered {top}' if used else
                    f"tactics {'/'.join(TACTIC_NAMES[t] for t in tacs)}, the AI's list "
                    f"{', '.join(mem[-1]['skill_names'][:4])}"))
    return {'step': step, 'level': level, 'members': mem, 'why': why, 'version': KIT_VERSION,
            'fights': {k: {'win': round(v['win'], 3), 'tactic': v['tactic']}
                       for k, v in results.items()}}


def key_fights(tl, step):
    """The step's boss fights and arena matches (the walls are among them),
    else all its fights."""
    allf = [tl.fights[k] for k in tl.steps[step]['fights']]
    return [f for f in allf if f['kind'] != 'list'] or allf


def kit_level50(data, tl, step, kit, teams=2, battles=6, seed=130, fights=None, lo=1, hi=99):
    """The smallest level where `kit` (learnable skills only) wins >= 50 %
    of every key fight (first_level from below)."""
    from . import balance as BL
    fl = fights or key_fights(tl, step)
    memo = {}

    def ok(L):
        if L not in memo:
            r = evaluate_kit(data, tl, step, kit, L, fl, teams, battles, seed)
            memo[L] = min(v['win'] for v in r.values())
        return memo[L] >= BL.WIN_HALF
    return BL.first_level(ok, lo, hi)


def strong_level50(data, tl, step, teams=2, battles=6, seed=130):
    """The level where a 'strong' roll, commanded (the arena: its best
    tactic), wins >= 50 % of every key fight."""
    from . import balance as BL
    fl = key_fights(tl, step)
    memo = {}

    def ok(L):
        if L not in memo:
            pool = step_pool(data, tl, step, L)
            team = BL.roll_team(data, tl, step, L,
                                random.Random(_seed(seed, 'kitstart', step, L, 0)), 'strong')
            k = _norm(data, tl, step, kit_from_team(data, pool, team), L, seed)
            if len(k['members']) < 3:
                memo[L] = 0.0
            else:
                r = evaluate_kit(data, tl, step, k, L, fl, teams, battles, seed)
                memo[L] = min(v['win'] for v in r.values())
        return memo[L] >= BL.WIN_HALF
    return BL.first_level(ok)


def step_kit(data, tl, step, evals=50, teams=2, battles=6, seed=130, level=None,
             time_limit=None, log=None, progress=None):
    """The step's kit with the level iteration (module docstring)."""
    t0 = time.time()
    L0 = level or strong_level50(data, tl, step, teams, battles, seed) or 99
    if log:
        log(f'step {step}: optimise at L{L0}')
    kit = optimize_kit(data, tl, step, L0, None, evals, teams, battles, seed,
                       time_limit=time_limit, log=log, progress=progress)
    if level is None:
        Lc = L0
        for _it in range(2):
            L1 = kit_level50(data, tl, step, kit, teams, battles, seed, hi=Lc)
            if L1 is None or L1 >= Lc:
                break
            if log:
                log(f'step {step}: the kit wins at L{L1}; optimise again there')
            rest = None if time_limit is None else max(10.0, time_limit - (time.time() - t0))
            k2 = optimize_kit(data, tl, step, L1, kit, max(10, evals // 3), teams, battles,
                              seed, time_limit=rest, log=log, progress=progress)
            kit, Lc = k2, L1
    kit['seconds'] = round(time.time() - t0, 1)
    return kit
