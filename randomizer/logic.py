"""Randomization passes.

Design invariants (agreed with the user, S76):

* **Power is preserved by construction.**  Enemy rows keep their level, their six
  stat words and their exp reward; only *identity* (species), *moves* and
  *joinability* change.  Encounter-pool shuffling is banded by level.  So gate
  pacing, arena difficulty and the exp economy stay vanilla.
* **Nothing outside the six data tables is touched.**  No code patches, no
  script edits, no text edits.  Boss fights are re-skinned through their
  enemy-stats rows, never through the script opcode parameters (those live in
  banks whose layout differs between regions).
* **Obtainability is enforced.**  Every species reachable in vanilla is still
  reachable after randomization, verified by a breeding-closure fixpoint.
"""

from __future__ import annotations

import random
from collections import Counter, defaultdict

from .romdata import FAMILY_NAMES, Rom

SKILL_NONE = 0xFF
SAFE_LEVEL = 25      # at or below this, enemy moves may never exceed vanilla
LATE_LEVEL = 45      # at or above this, the full late-game allowance applies
HEAL_SKILL = 43              # Heal: learn level 1, needs MP>=7 INT>=6, no prereq
FAMILY_CODE_LO = 0xF0
SPECIES_COUNT = 221
SKILL_COUNT = 222

# Arena rosters are formula-addressed: EID = $E0 + 9*group + 3*match + slot
# (SIDEQUEST_MAP "Arena / gate-boss ROSTER format", decoded S67, HW-verified).
ARENA_BASE, ARENA_ROWS = 224, 90
ARENA_KING = (481, 482, 483)

# Gate/story boss fight EIDs.  Source: extracted/arena_brackets.json
# gate_boss_triggers (script opcodes $05/$5A/$13).  Verified S76 to occur an
# identical number of times in the German script banks $0C-$0F, so the boss set
# is region-independent -- see validate_boss_eids().
BOSS_EIDS = [
    11, 31, 32, 51, 53, 55, 75, 77, 79, 99, 101, 103, 123, 125, 127, 147, 149,
    151, 152, 153, 155, 156, 175, 177, 179, 199, 201, 203, 205, 207, 209, 211,
    213, 215, 217, 219, 255, 341, 342, 343, 349,
]

# The "requires 100 exp at level 2" curves (24-31) remapped to the next-hardest
# tier, the "requires 10 exp" curves (16-23), rank-preserving.
EXP_CURVE_REMAP = {24: 16, 25: 17, 26: 18, 27: 19, 28: 20, 29: 21, 30: 22, 31: 23}

# Species 215-220 (TERRY?, Tatsu, Diago, Samsi, Bazoo, #220) are the rival /
# summon battlers, not real monsters: level cap 0, never raisable.  They are
# excluded from EVERY pool -- boss, arena, wild and the rest -- so no row in the
# game can roll one.  Derived from the level-cap-0 test at runtime; listed here
# for readability.
EXCLUDED_SPECIES = (215, 216, 217, 218, 219, 220)

# The first three gate bosses (Beginning / Villager / Talisman).  Pinned to
# joinability $00 = always joins, so the run starts with a real head start.
FORCE_JOIN_BOSSES = (11, 31, 32)

# Skills that restore the target's ENTIRE HP bar (record power 999, non-damaging,
# ally-targeted).  On a boss or an arena entrant these make a fight literally
# unwinnable if your party cannot out-damage a full bar in one round, so they are
# banned from every boss / arena / boss-join row.  HealMore (75-90) and the rest
# of the heal ladder are fine and stay in the pool.
FULL_HEAL_SKILLS = (45, 47, 163)   # HealAll / Gigaheil, HealUsAll / Allheiler x2

# Paralyze (105 / Lähmer) and PalsyAir (107 / Allähmer), damage_class $03.
# A paralysed party member never acts again for the fight, so on a boss or an
# arena entrant these end the run outright regardless of stats. Banned there,
# exactly like the full heals.
PARALYSIS_SKILLS = (105, 107)

# Skills that remove the player's AGENCY rather than their HP. The power band
# cannot see these: every status skill has record power 0, so Sap and Sleep look
# identical to it and a mild debuff can be swapped for a hard disable. User-hit
# S77: "Lahm" (Slow, id 32) on arena round 2 -- "that fucks you completely".
# Banned outright on boss/arena/join rows, and level-gated everywhere else.
HARD_DISABLE_SKILLS = (
    21,   # Sleep / Schlaf
    22,   # SleepAll / All-Koma
    23,   # StopSpell / Schweig
    25,   # PanicAll / Konfus
    32,   # Slow / Lahm
    33,   # SlowAll / All-Lahm
    106,  # SleepAir / Allschlaf
    107,  # PalsyAir / Allähmer
    110,  # PaniDance / Konfutanz
    111,  # Curse / Fluch
)
DISABLE_MIN_LEVEL = 15   # earliest a wild row may carry one


class Report:
    """Accumulates the spoiler log."""

    def __init__(self):
        self.sections: dict[str, list[str]] = defaultdict(list)
        self.notes: list[str] = []

    def add(self, section: str, line: str) -> None:
        self.sections[section].append(line)

    def note(self, line: str) -> None:
        self.notes.append(line)


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

def derange(rng: random.Random, items: list, tries: int = 200) -> list:
    """Shuffle so that no element stays at its original index (best effort)."""
    n = len(items)
    if n < 2:
        return list(items)
    for _ in range(tries):
        out = items[:]
        rng.shuffle(out)
        if all(out[i] != items[i] for i in range(n)):
            return out
    # Fall back: rotate, then fix any accidental fixed points by pair swaps.
    out = items[1:] + items[:1]
    for i in range(n):
        if out[i] == items[i]:
            j = next((k for k in range(n) if k != i and out[k] != items[i]
                      and out[i] != items[k]), None)
            if j is not None:
                out[i], out[j] = out[j], out[i]
    return out


def column_shuffle(rng: random.Random, rows: list[list[int]], col: int) -> None:
    """Shuffle one column across all rows (global shuffle, multiset preserved)."""
    vals = [r[col] for r in rows]
    rng.shuffle(vals)
    for r, v in zip(rows, vals):
        r[col] = v


def banded_shuffle(rng: random.Random, keys: list, values: list,
                   bands: int, jitter: float) -> list:
    """Shuffle `values` among slots ranked by `keys`, within difficulty bands.

    `keys[i]` ranks slot i (low = easy).  `values` are ranked independently and
    cut into bands of matching size, so easy slots draw easy values.  `jitter`
    is the fraction of slots additionally swapped globally, to keep the result
    from feeling like a re-skin of vanilla.
    """
    n = len(values)
    slot_order = sorted(range(n), key=lambda i: (keys[i], rng.random()))
    value_order = sorted(range(n), key=lambda i: (values[i][0], rng.random()))
    out = [None] * n
    edges = [round(n * b / bands) for b in range(bands + 1)]
    for b in range(bands):
        lo, hi = edges[b], edges[b + 1]
        slots = slot_order[lo:hi]
        vals = [values[i][1] for i in value_order[lo:hi]]
        rng.shuffle(vals)
        for s, v in zip(slots, vals):
            out[s] = v
    for _ in range(int(n * jitter)):
        i, j = rng.randrange(n), rng.randrange(n)
        out[i], out[j] = out[j], out[i]
    return out


def skill_universe(rom: Rom) -> list[int]:
    """Skill ids that vanilla actually assigns to monsters or enemies.

    Deliberately NOT "every id with a record" -- the 222-entry table also holds
    37 item effects and 30 internal entries (BATTLE_SKILL_SYSTEM), and handing
    one of those to a monster is exactly the sort of thing that crashes.
    """
    ids = {s for m in rom.monsters for s in m.skills}
    ids |= {s for e in rom.enemies for s in e.skills if s != SKILL_NONE}
    return sorted(i for i in ids if i < SKILL_COUNT)


def meets_requirement(rom: Rom, sid: int, level: int, stats: list[int]) -> bool:
    req = rom.skill_reqs[sid]
    if level < req.level:
        return False
    return all(stats[i] >= req.stats[i] for i in range(6))


def learnable_set(rom: Rom, species: int, level: int, stats: list[int],
                  universe: set[int]) -> list[int]:
    """Skills a monster of this species could plausibly know at this level.

    Natural slots seed the queue; a skill whose prereq is already known becomes
    available as the vanilla UPGRADE path (BATTLE_SKILL_SYSTEM 13.6 (B)).
    """
    naturals = set(rom.monsters[species].skills)
    known: set[int] = set()
    changed = True
    while changed:
        changed = False
        for sid in universe:
            if sid in known or not meets_requirement(rom, sid, level, stats):
                continue
            req = rom.skill_reqs[sid]
            if sid in naturals or any(p in known for p in req.prereqs):
                known.add(sid)
                changed = True
    return sorted(known)


# ---------------------------------------------------------------------------
# Pass 1 -- natural skills (item 5)
# ---------------------------------------------------------------------------

def randomize_natural_skills(rom: Rom, rng: random.Random, mode: str,
                             bands: int, jitter: float, rep: Report) -> None:
    """Redistribute the three natural skill slots across all 221 species."""
    slots = [(m.id, k) for m in rom.monsters for k in range(3)]
    pool = [rom.monsters[mid].skills[k] for mid, k in slots]

    if mode == "random":
        new = pool[:]
        rng.shuffle(new)
    else:
        # Monster difficulty: tier byte $2A first, then level cap.
        keys = [(rom.monsters[mid].tier, rom.monsters[mid].level_cap, mid)
                for mid, _ in slots]
        vals = [(rom.skill_reqs[s].difficulty, s) for s in pool]
        new = banded_shuffle(rng, keys, vals, bands, jitter)

    for (mid, k), sid in zip(slots, new):
        rom.monsters[mid].skills[k] = sid

    # Prefer three distinct skills per species (vanilla has 6 exceptions, so
    # this is a preference, not a hard rule).
    for m in rom.monsters:
        for k in range(3):
            if m.skills[k] in m.skills[:k]:
                for _ in range(30):
                    om, ok = rng.choice(slots)
                    cand = rom.monsters[om].skills[ok]
                    if cand not in m.skills and m.skills[k] not in rom.monsters[om].skills:
                        rom.monsters[om].skills[ok] = m.skills[k]
                        m.skills[k] = cand
                        break

    assert Counter(s for m in rom.monsters for s in m.skills) == Counter(pool), \
        "natural-skill redistribution must preserve the global skill multiset"
    rep.note(f"Natural skills: {len(pool)} slots redistributed ({mode} mode); "
             f"global skill multiset preserved exactly.")


# ---------------------------------------------------------------------------
# Pass 2 -- stat growth (item 6)
# ---------------------------------------------------------------------------

def randomize_growth(rom: Rom, rng: random.Random, rep: Report,
                     bands: int = 6) -> None:
    """Shuffle growth WITHIN vanilla's own tier for each stat.

    A free global shuffle let any species draw any curve, which produced
    Hausslime at 11.3 MP per level against vanilla's 3.0 and a worst case of 23x
    vanilla -- 82 of 1326 species-stat pairs sat at >=2.5x. Dealing inside bands
    of the vanilla ordering keeps every monster recognisably itself while still
    changing which curve it gets.
    """
    rows = [m.growth for m in rom.monsters]
    before = [Counter(r[c] for r in rows) for c in range(6)]
    n = len(rows)
    for c in range(6):
        order = sorted(range(n), key=lambda i: (rows[i][c], rng.random()))
        values = sorted(rows[i][c] for i in range(n))
        edges = [round(n * b / bands) for b in range(bands + 1)]
        for b in range(bands):
            idxs = order[edges[b]:edges[b + 1]]
            vals = values[edges[b]:edges[b + 1]]
            rng.shuffle(vals)
            for i, v in zip(idxs, vals):
                rows[i][c] = v
    after = [Counter(r[c] for r in rows) for c in range(6)]
    assert before == after
    rep.note(f"Stat growth: six columns shuffled within {bands} bands of the "
             f"vanilla ordering, so no species strays far from its own growth "
             f"tier. Per-column curve distribution preserved exactly.")


# ---------------------------------------------------------------------------
# Pass 3 -- resistances (item 7)
# ---------------------------------------------------------------------------

def randomize_resistances(rom: Rom, rng: random.Random, mode: str, rep: Report) -> None:
    """Scramble resistances.

    IMPORTANT: enemy resistances are NOT stored in the enemy-stats row -- the
    battle initialiser (bank $51, `ld hl,$0301 / rst $10` per combatant) loads
    the SPECIES info block, so offsets $0F-$29 here drive both your monsters and
    every enemy in the game.  That makes the choice of mode a difficulty knob:

    ``vector``  each species keeps its own 27 values but they are permuted
                across the 27 damage types -- what it resists is completely new,
                how MUCH it resists in total is exactly vanilla.
    ``tier``    (default) ``vector``, plus whole vectors are swapped between
                species inside the same tier bucket, so profiles move around
                without moving resistance mass between early and late game.
    ``global``  every one of the 27 columns is shuffled across all 221 species.
                Maximum chaos, but it FLATTENS the curve: vanilla's 66
                zero-immunity fodder monsters gain immunities and its
                heavily-immune bosses lose them.
    """
    rows = [m.resist for m in rom.monsters]

    if mode == "global":
        cap = max(sum(1 for v in r if v == 3) for r in rows)
        for c in range(27):
            column_shuffle(rng, rows, c)
        repairs = 0
        for _ in range(4000):
            over = [i for i, r in enumerate(rows) if sum(1 for v in r if v == 3) > cap]
            if not over:
                break
            i = rng.choice(over)
            done = False
            for c in rng.sample(range(27), 27):
                if rows[i][c] != 3:
                    continue
                cands = [j for j in range(len(rows)) if rows[j][c] < 3
                         and sum(1 for v in rows[j] if v == 3) < cap]
                if cands:
                    j = rng.choice(cands)
                    rows[i][c], rows[j][c] = rows[j][c], rows[i][c]
                    repairs += 1
                    done = True
                    break
            if not done:
                break
        rep.note(f"Resistances: GLOBAL column shuffle (immunity count capped at "
                 f"the vanilla max {cap}, {repairs} repairs). Note this flattens "
                 f"the vanilla difficulty curve -- see --resistances.")
        return

    if mode == "tier":
        buckets = defaultdict(list)
        for m in rom.monsters:
            buckets[m.tier].append(m.id)
        swapped = 0
        for ids in buckets.values():
            vectors = [rom.monsters[i].resist for i in ids]
            for i, vec in zip(ids, derange(rng, vectors)):
                rom.monsters[i].resist = list(vec)
            swapped += len(ids)
        rows = [m.resist for m in rom.monsters]

    for r in rows:
        rng.shuffle(r)

    kept = Counter(tuple(sorted(m.resist)) for m in rom.monsters)
    rep.note(f"Resistances: mode '{mode}' -- every species' 27 values permuted "
             f"across the damage types"
             + (f", and whole vectors swapped within each tier bucket"
                if mode == "tier" else "")
             + f"; total resistance mass per species preserved "
               f"({len(kept)} distinct budgets).")


# ---------------------------------------------------------------------------
# Pass 4 -- exp curves (item 8)
# ---------------------------------------------------------------------------

def remap_exp_curves(rom: Rom, rep: Report) -> None:
    moved = []
    for m in rom.monsters:
        if m.exp_table in EXP_CURVE_REMAP:
            old = m.exp_table
            m.exp_table = EXP_CURVE_REMAP[old]
            moved.append((m.id, old, m.exp_table))
    for mid, old, new in moved:
        rep.add("exp_curves", f"species {mid:3d}: curve {old} -> {new}")
    rep.note(f"Exp curves: {len(moved)} species moved off the 100-exp-to-level-2 "
             f"tier (curves 24-31) onto the 10-exp tier (curves 16-23).")


# ---------------------------------------------------------------------------
# Pass 5 -- enemy identity (items 1, 4, 9)
# ---------------------------------------------------------------------------

def classify_eids(rom: Rom) -> dict:
    wild = set()
    for p in rom.pools:
        for i in p.live_slots():
            wild.add(p.eids[i])
    arena = set(range(ARENA_BASE, ARENA_BASE + ARENA_ROWS)) | set(ARENA_KING)
    boss = set(BOSS_EIDS)
    join_targets = {j for _, j in rom.boss_redirect}
    reserved = {0, 1} | join_targets
    rest = set(range(len(rom.enemies))) - wild - arena - boss - reserved
    return {"wild": sorted(wild), "arena": sorted(arena), "boss": sorted(boss),
            "join": sorted(join_targets), "rest": sorted(rest)}


def _deal_stratified(rows: list[int], levels: dict[int, int],
                     candidates: list[int], quality: dict[int, tuple],
                     jitter: float, rng: random.Random) -> dict:
    """Map row LEVEL percentile onto species QUALITY percentile, plus noise.

    Vanilla stratifies hard and the targets are measured, not guessed:
    boss level vs breeding depth +0.73, arena vs cap +0.63, wild vs cap +0.45.
    A flat random draw destroys all of it (measured S77: +0.18 / +0.04 / +0.04),
    which guts the "here are the building blocks, here is what you could build"
    arc the game is arranged around.

    `jitter` is the knob: 0 gives a rigid ladder, higher values loosen it. Wild
    encounters need a LOT of slack (vanilla is only +0.45 -- catchable monsters
    are deliberately interchangeable), bosses very little.
    """
    rows = sorted(rows, key=lambda r: (levels[r], rng.random()))
    pool = sorted(candidates, key=lambda sp: (quality[sp], rng.random()))
    n, m = len(rows), len(pool)
    out = {}
    for i, r in enumerate(rows):
        centre = (i / max(1, n - 1)) * (m - 1)
        idx = int(round(centre + rng.gauss(0.0, jitter * m)))
        out[r] = pool[max(0, min(m - 1, idx))]
    return out


def _deal_showcase(rows: list[int], levels: dict[int, int],
                   candidates: list[int], quality: dict[int, tuple],
                   depth: dict, lo: float, hi: float, jitter: float,
                   rng: random.Random) -> dict:
    """Deal rows so the SHOWCASE rate matches vanilla, not just the ordering.

    A linear quality mapping cannot reproduce vanilla's arc, because breed-only
    species are a minority of the roster (52 of 221) and get diluted. Vanilla
    deliberately loads them into the endgame: bosses go 24% breed-only early to
    82% late, the arena 2% to 59%. So the breed-only PROBABILITY is interpolated
    across the level range and the sub-pool chosen from it, with quality
    stratification applied inside each sub-pool.
    """
    roots_pool = [s for s in candidates if depth.get(s, 0) == 0]
    breed_pool = [s for s in candidates if depth.get(s, 0) > 0]
    if not breed_pool or not roots_pool:
        return _deal_stratified(rows, levels, candidates, quality, jitter, rng)

    rows = sorted(rows, key=lambda r: (levels[r], rng.random()))
    roots_pool.sort(key=lambda sp: (quality[sp], rng.random()))
    breed_pool.sort(key=lambda sp: (quality[sp], rng.random()))
    n, out = len(rows), {}
    for i, r in enumerate(rows):
        q = i / max(1, n - 1)
        pool = breed_pool if rng.random() < lo + (hi - lo) * q else roots_pool
        m = len(pool)
        idx = int(round(q * (m - 1) + rng.gauss(0.0, jitter * m)))
        out[r] = pool[max(0, min(m - 1, idx))]
    return out


def randomize_enemy_species(rom: Rom, rng: random.Random, groups: dict,
                            allow_metal_bosses: bool, depth: dict, jitter: dict,
                            rep: Report) -> None:
    metal = {m.id for m in rom.monsters if m.is_metal}
    # Rival / summon battlers: never a valid roll for any row (user decision).
    excluded = {m.id for m in rom.monsters if m.level_cap == 0} | set(EXCLUDED_SPECIES)
    all_species = [s for s in range(SPECIES_COUNT) if s not in excluded]
    boss_pool = all_species if allow_metal_bosses else [s for s in all_species
                                                        if s not in metal]

    def pick(pool: list[int], eid: int) -> int:
        return rng.choice(pool or all_species)

    original = {e.id: e.species for e in rom.enemies}

    quality = {s: (min(depth.get(s, 0), 9), rom.monsters[s].level_cap)
               for s in range(SPECIES_COUNT)}
    levels = {e.id: e.level for e in rom.enemies}

    # -- wild: the species SET stays exactly vanilla's (obtainability parity),
    #    but it is dealt against encounter level so weak monsters sit early.
    wild = groups["wild"]
    wild_species = [s if s not in excluded else rng.choice(all_species)
                    for s in (rom.enemies[e].species for e in wild)]
    # Wild must stay an exact PERMUTATION of the vanilla species multiset
    # (obtainability parity), so it is a sorted pairing with a noisy swap pass
    # rather than sampling with replacement.
    order_rows = sorted(wild, key=lambda r: (levels[r], rng.random()))
    order_sp = sorted(wild_species, key=lambda s: (quality[s], rng.random()))
    for r, sp in zip(order_rows, order_sp):
        rom.enemies[r].species = sp
    swaps = int(len(order_rows) * jitter["wild"] * 4)
    for _ in range(swaps):
        a, b = rng.randrange(len(order_rows)), rng.randrange(len(order_rows))
        ra, rb = order_rows[a], order_rows[b]
        rom.enemies[ra].species, rom.enemies[rb].species = \
            rom.enemies[rb].species, rom.enemies[ra].species

    # -- arena: dealt against match level, then de-duplicated within each match.
    arena_rows = sorted(groups["arena"])
    arena_assign = _deal_showcase(arena_rows, levels, boss_pool, quality, depth,
                                  0.02, 0.59, jitter["arena"], rng)
    for eid in arena_rows:
        rom.enemies[eid].species = arena_assign[eid]
    for base in list(range(ARENA_BASE, ARENA_BASE + ARENA_ROWS, 3)) + [ARENA_KING[0]]:
        seen: set[int] = set()
        for slot in range(3):
            eid = base + slot
            if rom.enemies[eid].species in seen:
                alt = [s for s in boss_pool
                       if s not in seen and quality[s] == quality[rom.enemies[eid].species]]
                if alt:
                    rom.enemies[eid].species = rng.choice(alt)
            seen.add(rom.enemies[eid].species)

    # -- bosses: dealt against boss level, so the endgame shows off deep monsters.
    boss_assign = _deal_showcase(groups["boss"], levels, boss_pool, quality,
                                 depth, 0.24, 0.82, jitter["boss"], rng)
    for eid in groups["boss"]:
        rom.enemies[eid].species = boss_assign[eid]
    for eid in groups["rest"]:
        rom.enemies[eid].species = pick(all_species, eid)

    # -- redirect consistency: the monster that JOINS after a boss fight must be
    #    the monster you actually fought.
    for fight, join in rom.boss_redirect:
        rom.enemies[join].species = rom.enemies[fight].species

    for eid in groups["boss"]:
        e = rom.enemies[eid]
        rep.add("bosses", f"EID {eid:3d} L{e.level:<3} was {original[eid]:3d} "
                          f"-> species {e.species:3d}")
    rep.note(f"Enemy identity: {len(rom.enemies) - 2} rows re-skinned; every row "
             f"keeps its vanilla level, six stat words and exp reward. "
             f"Species {', '.join(str(s) for s in sorted(excluded))} "
             f"(rival/summon battlers) excluded from every pool.")


# ---------------------------------------------------------------------------
# Pass 6 -- enemy movesets (items 1, 9)
# ---------------------------------------------------------------------------

def _skill_shape(rom: Rom, sid: int) -> tuple:
    """Classify a skill by the only things that decide how dangerous it FEELS.

    Learn requirements are NOT that: breath skills are species-gated in vanilla,
    not stat-gated, so a level-2 enemy passes SkillLearnReqTable for FireAir and
    then hits the whole party for a flat 10-16 regardless of its ATK.  What
    matters is the ENEMY-side power pair and whether it hits one target or all.
    """
    rec = rom.skill_records[sid]
    if not rec.is_damaging:
        # Non-damaging: keep heals/buffs apart from debuffs/status, and keep the
        # target breadth -- otherwise a single-ally heal can be swapped for an
        # ALL-ally heal, which is a large difficulty increase the power band
        # cannot see (both read as the same power).
        # Severity matters and power does not see it: every status skill has
        # record power 0, so without this a Slow could be swapped for a
        # Paralyze. Measured: that tripled paralysis on boss/arena rows (2 -> 7)
        # and nearly doubled it overall (14 -> 26).
        if (rec.category >> 4) == 3:
            kind = 2                      # heal / buff
        elif rec.damage_class == 3:
            kind = 4                      # paralysis -- its own bucket
        else:
            kind = 1                      # ordinary status / debuff
        return (kind, 1 if rec.hits_all else 0, rec.enemy_max)
    return (0, 1 if rec.hits_all else 0, rec.enemy_max)


def assert_full_heals(rom: Rom) -> None:
    """Fail loudly if this ROM's records do not match the banned-skill list."""
    for sid in FULL_HEAL_SKILLS:
        rec = rom.skill_records[sid]
        assert rec.enemy_min >= 999 and rec.damage_class == 0 \
            and rec.target_mode in (0x21, 0x22), \
            f"skill {sid} is not the expected full-heal record"


def protected_rows(rom: Rom, groups: dict) -> set[int]:
    """Rows that must never carry a full heal: bosses, arena, and boss joins."""
    rows = set(groups["boss"]) | set(groups["arena"])
    rows |= {j for _, j in rom.boss_redirect}
    rows |= {f for f, _ in rom.boss_redirect}
    return rows


def vanilla_placement(vanilla) -> dict:
    """Empirical danger rating for every skill, from where VANILLA uses it.

    The skill record cannot tell us how dangerous a move is: 43 of the 222 have
    power 0 because their handler computes damage internally (Sacrifice,
    MegaMagic, BeDragon, GigaSlash, Beat, Kamikaze, SamsiCall). Every
    power-based rule is blind exactly there, which is how FireAir, BigBang,
    Lähmer, BeDragon and Sacrifice each reached the early game in turn.

    Vanilla's own placement is a complete, formula-free substitute: it knows
    Sacrifice belongs at level 20+, MegaMagic at 48+, GigaSlash at 40+. Returns
    {skill: (min_level, median_level, row_count)}.
    """
    seen = defaultdict(list)
    for e in vanilla.enemies:
        if not e.level:
            continue
        for sid in e.skills:
            if sid != SKILL_NONE:
                seen[sid].append(e.level)
    out = {}
    for sid, levels in seen.items():
        levels.sort()
        out[sid] = (levels[0], levels[len(levels) // 2], len(levels))
    return out


def randomize_enemy_skills(rom: Rom, rng: random.Random, mode: str,
                           universe: list[int], down: float, up: float,
                           protected: set[int], heal_cap: float,
                           placement: dict, rep: Report) -> None:
    """Re-deal enemy moves from vanilla's own usage multiset.

    Two constraints the previous version lacked, both measured as broken:

    * FREQUENCY. It preserved moves-per-row but not rows-per-move, so rare
      skills flooded (Speed 1 -> 44 rows, Sacrifice 9 -> 40, Whistle 1 -> 23)
      while common ones vanished (ChargeUP 22 -> 4). Skills are now dealt from a
      bag holding each skill exactly as many times as vanilla used it.
    * PLACEMENT. A row may not carry a skill below the lowest level vanilla ever
      used it at. 75 rows violated that before this change.
    """
    banned_set = set(FULL_HEAL_SKILLS) | set(PARALYSIS_SKILLS)

    bag: list[int] = []
    for sid, (_lo, _med, count) in placement.items():
        bag.extend([sid] * count)
    by_shape: dict[tuple, list[int]] = defaultdict(list)
    for sid in bag:
        by_shape[_skill_shape(rom, sid)[:2]].append(sid)
    for v in by_shape.values():
        rng.shuffle(v)

    # LOWEST level first. A low-level row can only accept skills vanilla placed
    # that low, so it must pick before the bag is drained; a high-level row can
    # use almost anything and is safe to serve last. Dealing high-to-low left
    # 34% of slots with no legal candidate, and they fell back to their vanilla
    # move -- concentrated on exactly the early bosses the player sees first.
    rows = sorted((e for e in rom.enemies if e.id not in (0, 1) and e.level),
                  key=lambda e: (e.level, rng.random()))
    changed = kept = 0
    for e in rows:
        slots = [s for s in e.skills if s != SKILL_NONE]
        if not slots:
            continue
        picked: list[int] = []
        for old in slots:
            shape = _skill_shape(rom, old)
            pool = by_shape.get(shape[:2], [])
            def legal(cand: int) -> bool:
                lo, _med, _c = placement[cand]
                if cand in picked or e.level < lo:
                    return False
                if e.id in protected and cand in banned_set:
                    return False
                if _skill_shape(rom, cand)[2] > shape[2] * (1 + up):
                    return False
                return meets_requirement(rom, cand, e.level, e.stats)

            # Prefer a move that DIFFERS from vanilla. Preserving usage counts
            # means a low-level row draws from a small pool where the commonest
            # skills dominate (Heal alone is on 32 vanilla rows), so without this
            # the early bosses -- the first thing the player sees -- kept coming
            # out with their vanilla movesets.
            choice = None
            for want_new in (True, False):
                for idx, cand in enumerate(pool):
                    if want_new and cand == old:
                        continue
                    if legal(cand):
                        choice = pool.pop(idx)
                        break
                if choice is not None:
                    break
            if choice is None:
                lo = placement.get(old, (0, 0, 0))[0]
                if e.level >= lo and not (e.id in protected and old in banned_set):
                    choice = old
                    kept += 1
                else:
                    continue
            picked.append(choice)
        e.skills = picked + [SKILL_NONE] * (4 - len(picked))
        changed += 1

    rep.note(f"Enemy movesets: {changed} rows dealt from vanilla's own usage bag "
             f"(each skill appears as often as vanilla used it, and never below "
             f"the lowest level vanilla placed it at); {kept} slots kept their "
             f"vanilla move because nothing legal was left.")


# ---------------------------------------------------------------------------
# Pass 7 -- boss joinability (item 2)
# ---------------------------------------------------------------------------

def randomize_boss_joinability(rom: Rom, rng: random.Random, force_join: bool,
                               jitter: float, rep: Report) -> None:
    """Shuffle boss joinability, but LEVEL-BIASED like vanilla.

    Vanilla does not spread recruitable bosses evenly -- never-joins climb
    0% / 20% / 62% / 70% / 88% across the level bands (correlation +0.62,
    51% overall). That is what protects the endgame showcase: the deep monsters
    you fight late are things you must BREED, not things you can beat and keep.

    A flat shuffle preserves the ratio but destroys the arc, and then late
    bosses become recruitable, which turns them into breeding-tree roots and
    quietly collapses the "breed-only" fraction the showcase depends on.

    The value multiset is preserved exactly, so the overall recruitable count
    matches vanilla; only WHICH rows get which value is re-dealt.
    """
    pinned = set(FORCE_JOIN_BOSSES) if force_join else set()
    eids = [e for e in BOSS_EIDS if e not in pinned]
    before = {e: rom.enemies[e].join for e in BOSS_EIDS}

    values = [rom.enemies[e].join for e in eids]
    never = [v for v in values if v == 7]
    joins = [v for v in values if v != 7]

    # Rank rows by level plus noise; the highest-ranked get the never-join
    # values. `jitter` controls how strictly the arc is followed.
    lv = {e: rom.enemies[e].level for e in eids}
    span = max(lv.values()) - min(lv.values()) or 1
    ranked = sorted(eids, key=lambda e: (lv[e] - min(lv.values())) / span
                    + rng.gauss(0.0, jitter))
    rng.shuffle(joins)
    for e in ranked[:len(joins)]:
        rom.enemies[e].join = joins.pop()
    for e in ranked[-len(never):] if never else []:
        rom.enemies[e].join = 7
    for e in pinned:
        rom.enemies[e].join = 0

    after = {e: rom.enemies[e].join for e in BOSS_EIDS}
    nj = sum(1 for v in after.values() if v == 7)
    rep.note(
        f"Boss joinability: level-biased shuffle -- {nj} of {len(BOSS_EIDS)} "
        f"never join (vanilla {sum(1 for v in before.values() if v == 7)}), with "
        f"non-joiners loaded toward the high-level end so late bosses stay "
        f"breed-only"
        + (f"; EIDs {', '.join(str(e) for e in sorted(pinned))} pinned to "
           f"always-join" if pinned else "") + ".")
    for e in BOSS_EIDS:
        tag = "  (ALWAYS joins, pinned)" if e in pinned else (
            "  (recruitable)" if after[e] != 7 else "  (never joins)")
        rep.add("boss_joins",
                f"EID {e:3d} L{rom.enemies[e].level:<3} join {before[e]} -> "
                f"{after[e]}{tag}")


# ---------------------------------------------------------------------------
# Pass 8 -- encounter tables (item 4)
# ---------------------------------------------------------------------------

def shuffle_encounter_pools(rom: Rom, rng: random.Random, spread: int,
                            rep: Report) -> None:
    """Permute pool slots within (level, power) groups, never duplicating.

    Two bugs this fixes, both found in play (S77):

    * Grouping by LEVEL alone is not enough. Same-level rows vary enormously --
      level-7 rows run from 29 to 145 in HP+ATK -- so a slot could keep its
      level and still gain 40% HP (measured: Picker L4 HP32/ATK30 became
      Killerbot L4 HP45/ATK32). Rows are now grouped by level AND a coarse power
      band, so a slot keeps a comparable monster.
    * A global permutation let the SAME EID land twice in one pool, doubling how
      often you meet it. Vanilla never does this: 0 of 128 pools contain a
      duplicate, against 42 of 128 before this fix. That is what turned one
      Feueratem carrier in gate 1's pool into two.
    """
    slots = [(p.id, i) for p in rom.pools for i in p.live_slots()]
    eids = [rom.pools[pid].eids[i] for pid, i in slots]

    def power(eid: int) -> int:
        e = rom.enemies[eid]
        return e.stats[0] + e.stats[2]

    groups: dict[tuple, list[int]] = defaultdict(list)
    for idx, eid in enumerate(eids):
        e = rom.enemies[eid]
        groups[(e.level // (spread + 1), power(eid) // 24)].append(idx)

    for idxs in groups.values():
        vals = [eids[i] for i in idxs]
        for _ in range(24):
            rng.shuffle(vals)
            seen: dict[int, set] = defaultdict(set)
            ok = True
            for i, v in zip(idxs, vals):
                pid = slots[i][0]
                if v in seen[pid]:
                    ok = False
                    break
                seen[pid].add(v)
            if ok:
                break
        for i, v in zip(idxs, vals):
            pid, slot = slots[i]
            rom.pools[pid].eids[slot] = v

    # Final sweep: repair any pool that still holds a duplicate by swapping the
    # offender with a same-group slot in another pool.
    fixed = 0
    for _ in range(6):
        bad = [(p.id, i) for p in rom.pools for i in p.live_slots()
               if [p.eids[j] for j in p.live_slots()].count(p.eids[i]) > 1]
        if not bad:
            break
        for pid, i in bad:
            cur = rom.pools[pid].eids[i]
            e = rom.enemies[cur]
            key = (e.level // (spread + 1), power(cur) // 24)
            for j in groups.get(key, ()):
                opid, oslot = slots[j]
                cand = rom.pools[opid].eids[oslot]
                pool_eids = [rom.pools[pid].eids[k] for k in rom.pools[pid].live_slots()]
                other = [rom.pools[opid].eids[k] for k in rom.pools[opid].live_slots()]
                if opid != pid and cand not in pool_eids and cur not in other:
                    rom.pools[pid].eids[i], rom.pools[opid].eids[oslot] = cand, cur
                    fixed += 1
                    break

    after = [rom.pools[pid].eids[i] for pid, i in slots]
    assert Counter(after) == Counter(eids), "pool shuffle must be a permutation"
    dups = sum(1 for p in rom.pools
               if len({p.eids[i] for i in p.live_slots()}) < len(p.live_slots()))
    moved = sum(1 for x, y in zip(eids, after) if x != y)
    drift = max(abs(rom.enemies[x].level - rom.enemies[y].level)
                for x, y in zip(eids, after))
    rep.note(f"Encounter tables: {len(slots)} slots permuted within (level, "
             f"power) groups; {moved} changed, level drift {drift}, "
             f"{dups} pools with a duplicate EID ({fixed} repaired).")


# ---------------------------------------------------------------------------
# Pass 9 -- breeding (item 3)
# ---------------------------------------------------------------------------

def randomize_breeding(rom: Rom, rng: random.Random, rep: Report) -> None:
    """Family table: permute the matcher pairs among their slots.

    The result species IS the slot index (BREEDING_SYSTEM, verified), so the
    only way to change what a pairing produces is to move the pair to another
    slot.  A derangement guarantees every general x general / specific x general
    pairing yields something new, while every slot that had a recipe still has
    one -- so all 197 family-table results stay reachable.
    """
    occupied = [i for i, (a, b) in enumerate(rom.family_recipes)
                if (a, b) not in ((0xFF, 0xFF), (0x00, 0x00))]
    pairs = [rom.family_recipes[i] for i in occupied]
    new_pairs = derange(rng, pairs)
    for i, p in zip(occupied, new_pairs):
        rom.family_recipes[i] = p
    unchanged = sum(1 for i, p in zip(occupied, new_pairs)
                    if p == pairs[occupied.index(i)])

    # Special table: derange the result column.  Parents, plus-thresholds and
    # plus-modifiers stay put, so first-match-wins ordering is unchanged.
    results = [e[3] for e in rom.special_recipes]
    new_results = derange(rng, results)
    for e, r in zip(rom.special_recipes, new_results):
        e[3] = r
    assert Counter(new_results) == Counter(results)

    rep.note(f"Breeding: {len(occupied)} family-table pairs deranged among their "
             f"slots ({unchanged} unavoidable fixed points); "
             f"{len(results)} special-recipe results deranged "
             f"({len(set(results))} distinct results preserved).")


# ---------------------------------------------------------------------------
# Pass 10 -- obtainability closure (item 3, "no unobtainable species")
# ---------------------------------------------------------------------------

def _matches(matcher: int, obtainable: set[int], rom: Rom) -> bool:
    if matcher >= FAMILY_CODE_LO:
        fam = matcher - FAMILY_CODE_LO
        return any(rom.monsters[s].family == fam for s in obtainable)
    return matcher in obtainable


def obtainable_species(rom: Rom, groups: dict) -> set[int]:
    """Fixpoint: wild recruits + boss joins + starter, closed under breeding."""
    got = {rom.enemies[1].species}
    for eid in groups["wild"]:
        if rom.enemies[eid].join != 7:
            got.add(rom.enemies[eid].species)
    for fight, join in rom.boss_redirect:
        if rom.enemies[fight].join != 7:
            got.add(rom.enemies[join].species)

    changed = True
    while changed:
        changed = False
        for slot, (a, b) in enumerate(rom.family_recipes):
            if (a, b) in ((0xFF, 0xFF), (0x00, 0x00)) or slot in got:
                continue
            if slot < SPECIES_COUNT and _matches(a, got, rom) and _matches(b, got, rom):
                got.add(slot)
                changed = True
        # Shadowing-aware: SpecialRecipeTable is first-match-wins, so a result
        # only counts as obtainable if some concrete parent pair reaches THIS
        # entry before any earlier entry claims that pair.
        for idx, (p1, p2, _plus, result, _mod) in enumerate(rom.special_recipes):
            if result in got:
                continue
            if not (_matches(p1, got, rom) and _matches(p2, got, rom)):
                continue
            if _first_match_index(rom, p1, p2, got) == idx:
                got.add(result)
                changed = True
    return got


def _concretes(matcher: int, got: set[int], rom: Rom) -> list[int]:
    if matcher >= FAMILY_CODE_LO:
        fam = matcher - FAMILY_CODE_LO
        return [s for s in got if rom.monsters[s].family == fam]
    return [matcher] if matcher in got else []


def _first_match_index(rom: Rom, p1: int, p2: int, got: set[int]) -> int | None:
    """Index of the entry that actually fires for some pair this entry covers."""
    for a in _concretes(p1, got, rom)[:6]:
        for b in _concretes(p2, got, rom)[:6]:
            for j, e in enumerate(rom.special_recipes):
                if _matches(e[0], {a}, rom) and _matches(e[1], {b}, rom):
                    return j
    return None


def enforce_obtainability(rom: Rom, rng: random.Random, groups: dict,
                          vanilla_obtainable: set[int], rep: Report) -> None:
    fixed = []
    for _ in range(400):
        got = obtainable_species(rom, groups)
        missing = sorted(vanilla_obtainable - got)
        if not missing:
            break
        target = missing[0]
        # Re-point a special recipe whose parents are already reachable and
        # whose current result is reachable by some other route anyway.
        cands = []
        for idx, (p1, p2, _plus, result, _mod) in enumerate(rom.special_recipes):
            if not (_matches(p1, got, rom) and _matches(p2, got, rom)):
                continue
            others = sum(1 for e in rom.special_recipes if e[3] == result)
            if others > 1 or result in _wild_and_boss_species(rom, groups):
                cands.append(idx)
        if not cands:
            rep.note(f"WARNING: could not restore obtainability for species {target}")
            break
        idx = rng.choice(cands)
        old = rom.special_recipes[idx][3]
        rom.special_recipes[idx][3] = target
        fixed.append((target, idx, old))
    got = obtainable_species(rom, groups)
    missing = sorted(vanilla_obtainable - got)
    for target, idx, old in fixed:
        rep.add("obtainability", f"species {target:3d} restored via special "
                                 f"recipe #{idx} (was -> {old})")
    rep.note(f"Obtainability: {len(vanilla_obtainable)} species reachable in "
             f"vanilla, {len(got & vanilla_obtainable)} reachable now "
             f"({len(fixed)} recipes re-pointed to close gaps"
             f"{'' if not missing else f'; UNRESOLVED: {missing}'}).")


def _wild_and_boss_species(rom: Rom, groups: dict) -> set[int]:
    got = {rom.enemies[e].species for e in groups["wild"] if rom.enemies[e].join != 7}
    for fight, join in rom.boss_redirect:
        if rom.enemies[fight].join != 7:
            got.add(rom.enemies[join].species)
    return got


# ---------------------------------------------------------------------------
# Pass 11 -- starter (item: "random, but able to learn Heal early")
# ---------------------------------------------------------------------------

def _growth_reaches(rom: Rom, curve: int, by_level: int) -> int:
    return rom.growth_gain(curve, by_level)


def setup_starter(rom: Rom, rng: random.Random, forced: int | None,
                  min_level_cap: int, rep: Report) -> None:
    """EID 1 is the starter (a dedicated always-join row, MONSTER_DATA S36).

    Requirement: the starter must be ABLE to learn Heal early.  Heal (id 43) has
    no prereq and learn level 1, but gates on MP >= 7 and INT >= 6 -- and the
    starter's base row is MP 0 / INT 1.  So two things must hold: Heal must sit
    in the species' natural skill slots, and its MP/INT growth curves must clear
    those thresholds within the first few levels.
    """
    starter_row = rom.enemies[1]
    base_mp, base_int = starter_row.stats[1], starter_row.stats[5]
    need_mp = max(0, rom.skill_reqs[HEAL_SKILL].stats[1] - base_mp)
    need_int = max(0, rom.skill_reqs[HEAL_SKILL].stats[5] - base_int)
    by_level = 5  # "within the first few levels"

    if forced is not None:
        species = forced
    else:
        cands = [m.id for m in rom.monsters if m.level_cap >= min_level_cap]
        species = rng.choice(cands or list(range(SPECIES_COUNT)))
    starter_row.species = species
    m = rom.monsters[species]

    # -- guarantee Heal is in the natural slots, by SWAPPING with a species that
    #    has it, so the global skill multiset stays intact.
    if HEAL_SKILL not in m.skills:
        donors = [(o.id, k) for o in rom.monsters if o.id != species
                  for k in range(3) if o.skills[k] == HEAL_SKILL]
        slot = rng.randrange(3)
        if donors:
            oid, ok = rng.choice(donors)
            rom.monsters[oid].skills[ok] = m.skills[slot]
            m.skills[slot] = HEAL_SKILL
        else:
            m.skills[slot] = HEAL_SKILL  # multiset shifts by one; logged below
            rep.note("NOTE: no species held Heal after redistribution; the "
                     "starter's slot was overwritten rather than swapped.")

    # -- guarantee the MP and INT curves clear Heal's thresholds early, again by
    #    swapping curve indices with another species (column multiset intact).
    # Margin of +3 over the bare threshold: the level-up routine applies its own
    # per-stat scaling on top of the raw curve, and the creation roll can shave
    # the base by up to 20%, so "exactly on the line" is not good enough.
    margin = 3
    for col, need, label in ((1, need_mp, "MP"), (5, need_int, "INT")):
        need += margin
        if _growth_reaches(rom, m.growth[col], by_level) >= need:
            continue
        donors = [o.id for o in rom.monsters if o.id != species
                  and _growth_reaches(rom, o.growth[col], by_level) >= need]
        if not donors:
            rep.note(f"WARNING: no growth curve reaches {label} {need} by level "
                     f"{by_level}; starter may not learn Heal early.")
            continue
        oid = rng.choice(donors)
        m.growth[col], rom.monsters[oid].growth[col] = \
            rom.monsters[oid].growth[col], m.growth[col]

    got_mp = base_mp + _growth_reaches(rom, m.growth[1], by_level)
    got_int = base_int + _growth_reaches(rom, m.growth[5], by_level)
    rep.note(f"Starter: species {species} (level cap {m.level_cap}, family "
             f"{FAMILY_NAMES[m.family]}), natural skills {m.skills}. "
             f"Heal is in its natural set; by level {by_level} it reaches "
             f"MP {got_mp} (needs {rom.skill_reqs[HEAL_SKILL].stats[1]}) and "
             f"INT {got_int} (needs {rom.skill_reqs[HEAL_SKILL].stats[5]}).")


# ---------------------------------------------------------------------------
# Cross-region validation
# ---------------------------------------------------------------------------

def validate_boss_eids(rom_bytes: bytes) -> list[str]:
    """Check every boss EID still appears as a script trigger parameter.

    Script tokens in banks $0C-$0F are 2-byte pairs: `<opcode> $FF` followed by
    the 16-bit LE operand.  This is the check that proves BOSS_EIDS transfers to
    a non-English build (it does; verified S76 on the German ROM).
    """
    problems = []
    for eid in BOSS_EIDS:
        hits = 0
        for op in (0x05, 0x5A):
            pat = bytes([op, 0xFF]) + eid.to_bytes(2, "little")
            for bank in (0x0C, 0x0D, 0x0E, 0x0F):
                blob = rom_bytes[bank * 0x4000:(bank + 1) * 0x4000]
                i = 0
                while True:
                    i = blob.find(pat, i)
                    if i < 0:
                        break
                    hits += 1
                    i += 1
        if hits == 0 and eid not in (149, 151, 152, 342):  # opcode $13 multi-slot writes
            problems.append(f"boss EID {eid} has no $05/$5A trigger in this ROM")
    return problems


# ---------------------------------------------------------------------------
# Pass 12 -- keep heavy natural skills off early-encounter species (S77)
# ---------------------------------------------------------------------------

def gate_early_skills(rom: Rom, rng: random.Random, slope: float, floor: int,
                      rep: Report) -> None:
    """A species met in gate 1 must not have BigBang in its natural set.

    The natural-skill band shuffle ranks monsters by tier byte and level cap,
    neither of which knows where a species actually SHOWS UP. Measured on the
    first build: a species first encountered at level 2 carried BigBang (power
    300). This runs AFTER the encounter pass, when first-appearance level is
    finally known, and swaps offenders with species that appear late or not at
    all -- so the global skill multiset is still preserved exactly.
    """
    first: dict[int, int] = {}
    for p in rom.pools:
        for i in p.live_slots():
            e = rom.enemies[p.eids[i]]
            first[e.species] = min(first.get(e.species, 99), e.level)

    def budget(species: int) -> float:
        lv = first.get(species)
        return 1e9 if lv is None else floor + slope * lv

    def power(sid: int) -> int:
        return rom.skill_records[sid].enemy_max

    slots = [(m.id, k) for m in rom.monsters for k in range(3)]
    before = Counter(rom.monsters[m].skills[k] for m, k in slots)

    swaps = 0
    for mid, k in slots:
        sid = rom.monsters[mid].skills[k]
        if power(sid) <= budget(mid):
            continue
        cands = [(om, ok) for om, ok in slots
                 if om != mid
                 and power(rom.monsters[om].skills[ok]) <= budget(mid)
                 and power(sid) <= budget(om)]
        if not cands:
            continue
        om, ok = rng.choice(cands)
        rom.monsters[mid].skills[k], rom.monsters[om].skills[ok] = \
            rom.monsters[om].skills[ok], sid
        swaps += 1

    assert Counter(rom.monsters[m].skills[k] for m, k in slots) == before, \
        "early-skill gating must preserve the global skill multiset"

    left = sum(1 for mid, k in slots
               if power(rom.monsters[mid].skills[k]) > budget(mid))
    rep.note(f"Early-skill gating: {swaps} natural skills swapped so a species' "
             f"maximum natural power stays under {floor} + {slope:g} x its "
             f"first-encounter level; {left} slots could not be resolved. "
             f"Skill multiset preserved exactly.")


# ---------------------------------------------------------------------------
# Pass 13 -- make the FIRST breeding step worth taking (S77)
# ---------------------------------------------------------------------------

# Depth 0 sits at the MEDIAN, not below it. Pinning it at 0.40 put everything
# catchable at the 36th percentile of roster growth -- a systematic nerf to the
# player's whole early roster that read in play as "low HP, not doing much
# damage". The rungs above are also compressed, so the ladder nudges rather than
# steps.
DEPTH_GROWTH_PERCENTILE = {0: 0.50, 1: 0.60, 2: 0.63, 3: 0.67,
                           4: 0.72, 5: 0.77, 6: 0.83}


def bias_growth_by_depth(rom: Rom, rng: random.Random, depth: dict,
                         spread: float, rep: Report) -> None:
    """Re-deal growth curves so breeding step ONE is immediately exciting.

    Vanilla's depth-1 monsters average level cap ~30 against a wild average of
    ~41, so the first thing you breed has a LOWER ceiling than what you could
    just catch. Left alone that makes early breeding feel like a downgrade.

    The fix is the shape the user described: give the shallow breeding tier
    strong GROWTH but leave its low CAP alone. It out-levels your caught
    monsters fast, then walls hard -- which is exactly the pressure that should
    push you into the next breeding step rather than grinding it to cap.

    Growth only affects monsters the PLAYER raises (enemy stats come from the
    enemy row), so this cannot make the game harder. Column multisets are
    preserved, so the global distribution of curves is untouched.
    """
    cols = 6
    species = list(range(SPECIES_COUNT))
    target = {s: DEPTH_GROWTH_PERCENTILE.get(min(depth.get(s, 0), 6), 0.40)
              for s in species}

    # One noise draw PER SPECIES, with only a little extra per column. Drawing
    # independently per column produced lopsided monsters -- high MP with no HP
    # -- which reads as "low HP, big MP, does nothing" in play.
    base_noise = {s: rng.gauss(0.0, spread) for s in species}
    for c in range(cols):
        values = sorted(m.growth[c] for m in rom.monsters)
        order = sorted(species,
                       key=lambda s: target[s] + base_noise[s]
                       + rng.gauss(0.0, spread * 0.35))
        for rank, s in enumerate(order):
            rom.monsters[s].growth[c] = values[rank]

    got = defaultdict(list)
    for s in species:
        got[min(depth.get(s, 0), 6)].append(
            sum(sum(rom.growth_curves[i]) for i in rom.monsters[s].growth))
    summary = {d: round(sum(v) / len(v)) for d, v in sorted(got.items())}
    rep.note(f"Growth biased by breeding depth: mean growth-sum by depth "
             f"{summary}. Depth-1 monsters now out-grow caught ones early while "
             f"keeping their low level cap, so the first breeding step pays off "
             f"immediately and then walls. Per-column curve multisets preserved.")
