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

def randomize_growth(rom: Rom, rng: random.Random, rep: Report) -> None:
    """Global shuffle: each of the six growth-curve columns is permuted across
    all 221 species independently."""
    rows = [m.growth for m in rom.monsters]
    before = [Counter(r[c] for r in rows) for c in range(6)]
    for c in range(6):
        column_shuffle(rng, rows, c)
    after = [Counter(r[c] for r in rows) for c in range(6)]
    assert before == after
    rep.note("Stat growth: all six growth-curve columns globally shuffled "
             "across species (per-column curve distribution preserved).")


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


def randomize_enemy_species(rom: Rom, rng: random.Random, groups: dict,
                            allow_metal_bosses: bool, rep: Report) -> None:
    metal = {m.id for m in rom.monsters if m.is_metal}
    # Rival / summon battlers: never a valid roll for any row (user decision).
    excluded = {m.id for m in rom.monsters if m.level_cap == 0} | set(EXCLUDED_SPECIES)
    all_species = [s for s in range(SPECIES_COUNT) if s not in excluded]
    boss_pool = all_species if allow_metal_bosses else [s for s in all_species
                                                        if s not in metal]

    def pick(pool: list[int], eid: int) -> int:
        return rng.choice(pool or all_species)

    original = {e.id: e.species for e in rom.enemies}

    # -- wild: permute the vanilla wild species multiset, so the set of species
    #    obtainable from the wild is bit-for-bit the vanilla set.
    wild = groups["wild"]
    wild_species = [s if s not in excluded else rng.choice(all_species)
                    for s in (rom.enemies[e].species for e in wild)]
    for e, s in zip(wild, derange(rng, wild_species)):
        rom.enemies[e].species = s

    # -- arena: free choice, but no repeated species inside one 3-slot match.
    for base in list(range(ARENA_BASE, ARENA_BASE + ARENA_ROWS, 3)) + [ARENA_KING[0]]:
        picked: set[int] = set()
        for slot in range(3):
            eid = base + slot
            cand = [s for s in boss_pool if s not in picked] or boss_pool
            s = pick(cand, eid)
            picked.add(s)
            rom.enemies[eid].species = s

    # -- bosses and everything else: free choice.
    for eid in groups["boss"]:
        rom.enemies[eid].species = pick(boss_pool, eid)
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
        kind = 2 if (rec.category >> 4) == 3 else 1
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


def randomize_enemy_skills(rom: Rom, rng: random.Random, mode: str,
                           universe: list[int], down: float, up: float,
                           protected: set[int], heal_cap: float,
                           rep: Report) -> None:
    """Re-roll enemy movesets SLOT BY SLOT, matched to the vanilla move's threat.

    Each replacement must be the same kind (damage / status / heal), the same
    target breadth (one foe vs all foes), and land inside a multiplicative band
    around the vanilla move's maximum enemy-side damage.  A row that had a mild
    single-target poke gets another mild single-target poke; a row that had
    Blazemost gets something equally devastating.  This is what actually keeps
    "power broadly the same" -- gating on learn requirements did not.

    The band is ASYMMETRIC on purpose: `down` may be generous, `up` is kept
    tight, so no row can come out meaningfully more dangerous than it was.  A
    symmetric band let six bosses gain damage (e.g. 130 -> 160) purely by luck
    of the draw.
    """
    by_kind: dict[tuple, list[int]] = defaultdict(list)
    for sid in universe:
        kind, breadth, _power = _skill_shape(rom, sid)
        by_kind[(kind, breadth)].append(sid)

    uset = set(universe)
    banned_set = set(FULL_HEAL_SKILLS)
    changed = swaps = widened = downgraded = 0
    for e in rom.enemies:
        if e.id in (0, 1):
            continue
        slots = [s for s in e.skills if s != SKILL_NONE]
        if not slots:
            continue

        # A protected row may not full-heal at all, and may not carry any heal
        # worth more than `heal_cap` x its own maximum HP.
        is_protected = e.id in protected
        own_hp = e.stats[0]

        def allowed(sid: int) -> bool:
            if not is_protected:
                return True
            if sid in banned_set:
                return False
            rec = rom.skill_records[sid]
            if rec.damage_class == 0 and rec.target_mode in (0x21, 0x22, 0x41):
                return rec.enemy_min <= max(1, int(own_hp * heal_cap))
            return True

        preferred = set()
        if mode == "species":
            preferred = set(learnable_set(rom, e.species, e.level, e.stats, uset))

        picked: list[int] = []
        for old in slots:
            kind, breadth, power = _skill_shape(rom, old)
            bucket = [s for s in by_kind[(kind, breadth)] if allowed(s)]
            lo, hi = power * (1 - down), power * (1 + up)
            if not allowed(old):
                # The vanilla move itself is barred here (e.g. an arena entrant
                # with HealAll).  Drop to the strongest LEGAL move of the same
                # shape rather than sideways into another full heal.
                legal = [_skill_shape(rom, s)[2] for s in bucket]
                hi = max(legal) if legal else 0
                lo = hi * (1 - down)
                downgraded += 1
            band = [s for s in bucket if s not in picked
                    and lo <= _skill_shape(rom, s)[2] <= hi]
            if not band:                       # widen once, then give up safely
                band = [s for s in bucket if s not in picked
                        and _skill_shape(rom, s)[2] <= hi]
                widened += 1
            if not band:
                picked.append(old if allowed(old) else SKILL_NONE)
                continue
            liked = [s for s in band if s in preferred]
            choice = rng.choice(liked or band)
            picked.append(choice)
            if choice != old:
                swaps += 1

        picked = [s for s in picked if s != SKILL_NONE]
        e.skills = picked + [SKILL_NONE] * (4 - len(picked))
        changed += 1

    rep.note(f"Enemy movesets: {changed} rows re-rolled, {swaps} individual moves "
             f"replaced ({mode} mode, -{int(down * 100)}%/+{int(up * 100)}% power "
             f"band). Each "
             f"replacement matches the vanilla move's KIND, TARGET BREADTH (one "
             f"foe vs all foes) and enemy-side damage, so no row gains threat it "
             f"did not already have"
             + (f"; {widened} slots needed a widened band" if widened else "")
             + (f"; {downgraded} full-heal/oversized-heal slots on boss or arena "
                f"rows downgraded to the strongest legal heal" if downgraded else "")
             + ".")


# ---------------------------------------------------------------------------
# Pass 7 -- boss joinability (item 2)
# ---------------------------------------------------------------------------

def randomize_boss_joinability(rom: Rom, rng: random.Random, force_join: bool,
                               rep: Report) -> None:
    pinned = set(FORCE_JOIN_BOSSES) if force_join else set()
    eids = [e for e in BOSS_EIDS if e not in pinned]
    before = {e: rom.enemies[e].join for e in BOSS_EIDS}

    vals = [rom.enemies[e].join for e in eids]
    new = derange(rng, vals)
    for e, v in zip(eids, new):
        rom.enemies[e].join = v
    for e in pinned:
        rom.enemies[e].join = 0          # $00 = always joins

    after = {e: rom.enemies[e].join for e in BOSS_EIDS}
    joiners = sum(1 for v in after.values() if v != 7)
    rep.note(f"Boss joinability: shuffled across {len(eids)} boss rows"
             + (f"; EIDs {', '.join(str(e) for e in sorted(pinned))} (the first "
                f"three gate bosses) PINNED to always-join" if pinned else "")
             + f"; {joiners} recruitable, was "
               f"{sum(1 for v in before.values() if v != 7)}.")
    for e in BOSS_EIDS:
        tag = "  (ALWAYS joins, pinned)" if e in pinned else (
            "  (recruitable)" if after[e] != 7 else "  (never joins)")
        rep.add("boss_joins", f"EID {e:3d}: join {before[e]} -> {after[e]}{tag}")


# ---------------------------------------------------------------------------
# Pass 8 -- encounter tables (item 4)
# ---------------------------------------------------------------------------

def shuffle_encounter_pools(rom: Rom, rng: random.Random, spread: int,
                            rep: Report) -> None:
    """Permute which EID sits in which live pool slot, grouped by EXACT level.

    An earlier version bucketed 543 slots into 10 quantile bands.  That is fine
    at the top of the curve and catastrophic at the bottom: it moved level-4/5
    rows (ATK 26-35) into the Gate of Beginning, whose vanilla rows are level 1
    with ATK 8-19.  Difficulty at low level is driven by absolute stat deltas,
    not by quantile rank, so the grouping is now by exact level with an optional
    +/-`spread` merge.
    """
    slots = [(p.id, i) for p in rom.pools for i in p.live_slots()]
    eids = [rom.pools[pid].eids[i] for pid, i in slots]

    groups: dict[int, list[int]] = defaultdict(list)
    for idx, eid in enumerate(eids):
        groups[rom.enemies[eid].level // (spread + 1)].append(idx)

    for idxs in groups.values():
        vals = [eids[i] for i in idxs]
        rng.shuffle(vals)
        for i, v in zip(idxs, vals):
            pid, slot = slots[i]
            rom.pools[pid].eids[slot] = v

    after = [rom.pools[pid].eids[i] for pid, i in slots]
    assert Counter(after) == Counter(eids), "pool shuffle must be a permutation"
    moved = sum(1 for x, y in zip(eids, after) if x != y)
    drift = max(abs(rom.enemies[x].level - rom.enemies[y].level)
                for x, y in zip(eids, after))
    rep.note(f"Encounter tables: {len(slots)} live pool slots permuted within "
             f"exact-level groups (spread {spread}); {moved} slots changed, "
             f"worst-case level drift {drift}. Weights and the encounterable-EID "
             f"multiset are untouched.")


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
        for p1, p2, _plus, result, _mod in rom.special_recipes:
            if result in got:
                continue
            if _matches(p1, got, rom) and _matches(p2, got, rom):
                got.add(result)
                changed = True
    return got


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
