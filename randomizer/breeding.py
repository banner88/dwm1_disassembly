"""Breeding tree generation with a TARGET DEPTH PROFILE.

Replaces the S76 "derange the pairs" approach, which preserved every vanilla
combo and — measured later — collapsed the tree from depth 9 to depth 2.

The governing insight (measured S77): breeding depth is a function of MATCHER
SPECIFICITY, not of which table a recipe lives in.

    family x family    ->  mean result depth 1.08   (any starter slime satisfies
                                                     [Slime], so it can only
                                                     ever be one step deep)
    family x specific  ->  mean result depth 2.00
    specific x specific->  mean result depth 3.00

So depth is controlled by choosing HOW SPECIFIC a recipe's parents are, and by
choosing parents that are themselves deep.

Design goals, per the user (S77):
  * depth 3-5 common, nothing past 6 — several parallel mid-length lines rather
    than vanilla's single 9-deep DeathMore spike
  * deeper targets are BETTER: depth correlates with level cap, which is vanilla
    data this randomizer never touches, so the progression spine survives
  * every species reachable in vanilla stays reachable
  * form ladders are shuffled like anything else (explicit user decision)

Hard structural constraints this must respect:
  * FamilyRecipeTable result species IS the slot index — a slot's result cannot
    be chosen, only its parents
  * SpecialRecipeTable is scanned FIRST and is strictly block-sorted by
    specificity (SS 0-634, SF 635-734, FS/FF 735-824); breaking that ordering
    makes specific recipes unreachable
"""

from __future__ import annotations

import random
from collections import Counter, defaultdict

FAMILY_LO = 0xF0
SPECIES_COUNT = 221
SEPARATORS = ((0xFF, 0xFF), (0x00, 0x00))
MAX_DEPTH = 6

# Fraction of breedable species placed at each depth. Front-loaded so there are
# many parallel lines to chase; nothing beyond MAX_DEPTH.
DEPTH_PROFILE = {1: 0.20, 2: 0.20, 3: 0.22, 4: 0.18, 5: 0.14, 6: 0.06}


def matcher_kind(a: int, b: int) -> str:
    return ("F" if a >= FAMILY_LO else "S") + ("F" if b >= FAMILY_LO else "S")


def resolve_depths(rom, roots: set[int]) -> dict[int, int]:
    """Fixpoint breeding depth. `roots` (wild-obtainable) are depth 0.

    A family matcher is satisfied by the SHALLOWEST obtainable member of that
    family, which is exactly why family matchers cannot create depth.
    """
    fam = {s: rom.monsters[s].family for s in range(SPECIES_COUNT)}
    prod = defaultdict(list)
    for slot, (a, b) in enumerate(rom.family_recipes):
        if (a, b) in SEPARATORS or slot >= SPECIES_COUNT:
            continue
        prod[slot].append((a, b))
    for p1, p2, _mp, res, _m in rom.special_recipes:
        prod[res].append((p1, p2))

    INF = 99
    depth = {s: (0 if s in roots else INF) for s in range(SPECIES_COUNT)}
    by_family = defaultdict(list)
    for s in range(SPECIES_COUNT):
        by_family[fam[s]].append(s)

    def md(m: int) -> int:
        if m >= FAMILY_LO:
            members = by_family.get(m - FAMILY_LO, ())
            return min((depth[s] for s in members), default=INF)
        return depth[m]

    for _ in range(80):
        changed = False
        for s, recipes in prod.items():
            best = min((max(md(a), md(b)) + 1 for a, b in recipes), default=INF)
            if best < depth[s]:
                depth[s] = best
                changed = True
        if not changed:
            break
    return depth


def assign_target_depths(rom, roots: set[int], rng: random.Random) -> dict[int, int]:
    """Deeper = better. Species are ranked by LEVEL CAP (vanilla, untouched) and
    dealt into the depth profile, so the vanilla quality spine is reproduced."""
    breedable = [s for s in range(SPECIES_COUNT) if s not in roots]
    # Rank by level cap ascending; jitter inside equal-cap groups so identical
    # caps do not always land in species-id order.
    breedable.sort(key=lambda s: (rom.monsters[s].level_cap, rng.random()))

    targets: dict[int, int] = {s: 0 for s in roots}
    n = len(breedable)
    idx = 0
    for d in sorted(DEPTH_PROFILE):
        take = round(n * DEPTH_PROFILE[d])
        for s in breedable[idx:idx + take]:
            targets[s] = d
        idx += take
    for s in breedable[idx:]:
        targets[s] = MAX_DEPTH
    return targets


def _pick_parent(pool_by_depth: dict[int, list[int]], want: int,
                 rng: random.Random, exclude: set[int]) -> int | None:
    for d in range(want, -1, -1):
        cands = [s for s in pool_by_depth.get(d, ()) if s not in exclude]
        if cands:
            return rng.choice(cands)
    return None


def regenerate(rom, rng: random.Random, roots: set[int], rep,
               attempts: int = 5, easy: set[int] | None = None) -> dict:
    """Build the tree, retrying until the requested depth is actually reached.

    Tier construction is reliable but not deterministic -- some draws stall a
    tier short. Rather than shipping whatever came out (earlier builds quietly
    delivered depth 4 when 6 was asked for), the whole build is attempted
    several times and the deepest result kept.
    """
    best = None
    snap_f = list(rom.family_recipes)
    snap_s = [list(e) for e in rom.special_recipes]
    for _ in range(attempts):
        rom.family_recipes = list(snap_f)
        rom.special_recipes = [list(e) for e in snap_s]
        st = _regenerate_once(rom, rng, roots, rep, easy or set())
        depth = st["depth"]
        reach = max((d for d in depth.values() if d < 99), default=0)
        deep = sum(1 for d in depth.values() if 3 <= d < 99)
        score = (reach >= MAX_DEPTH, reach, deep)
        if best is None or score > best[0]:
            best = (score, list(rom.family_recipes),
                    [list(e) for e in rom.special_recipes], st)
        if score[0]:
            break
    rom.family_recipes = best[1]
    rom.special_recipes = best[2]
    st = best[3]
    st["depth"] = resolve_depths(rom, roots)
    dist = Counter(min(d, 20) for d in st["depth"].values())
    reach = max((d for d in st["depth"].values() if d < 99), default=0)
    rep.note(f"Breeding tree: depth reaches {reach} (target {MAX_DEPTH}); "
             f"profile {dict(sorted((k, v) for k, v in dist.items() if k < 20))}.")
    return st


def _regenerate_once(rom, rng: random.Random, roots: set[int], rep,
                     easy: set[int]) -> dict:
    """`easy` = species met in the first gates. Vanilla never gives one of these
    a specific x specific recipe -- measured, 0 of 15 species first met at level
    <= 6 -- because the first monsters you meet are meant to read as building
    blocks. Their recipes are held to family x family / family x specific."""
    """Rebuild both recipe tables against the target depth profile."""
    fam = {s: rom.monsters[s].family for s in range(SPECIES_COUNT)}
    targets = assign_target_depths(rom, roots, rng)
    by_depth = defaultdict(list)
    for s, d in targets.items():
        by_depth[d].append(s)

    old_family = list(rom.family_recipes)
    old_special = [list(e) for e in rom.special_recipes]

    # --- Family table: slot = result, so only the PAIR is ours to choose. The
    # slot's original matcher kind is preserved to keep the table's shape, and
    # that kind caps how deep the slot's species can be.
    fam_changed = 0
    for slot, (a, b) in enumerate(old_family):
        if (a, b) in SEPARATORS or slot >= SPECIES_COUNT:
            continue
        want = targets.get(slot, 1)
        kind = matcher_kind(a, b)
        if slot in easy and kind == "SS":
            kind = "FS"
        if kind == "FF":
            # Cannot encode depth; give it two families that exist.
            fams = [f for f in range(10) if any(fam[s] == f for s in range(SPECIES_COUNT))]
            p = (FAMILY_LO + rng.choice(fams), FAMILY_LO + rng.choice(fams))
        else:
            spec = _pick_parent(by_depth, max(0, want - 1), rng, {slot})
            if spec is None:
                spec = rng.randrange(SPECIES_COUNT)
            other_f = FAMILY_LO + fam[_pick_parent(by_depth, max(0, want - 2), rng, {slot, spec})
                                     or rng.randrange(SPECIES_COUNT)]
            if kind == "SS":
                second = _pick_parent(by_depth, max(0, want - 1), rng, {slot, spec})
                p = (spec, second if second is not None else rng.randrange(SPECIES_COUNT))
            elif kind == "FS":
                p = (other_f, spec)
            else:
                p = (spec, other_f)
        if p != (a, b):
            fam_changed += 1
        rom.family_recipes[slot] = p

    # --- Special table: results AND parents are ours, but the specificity
    # blocks must keep their index ranges or first-match-wins breaks.
    blocks = defaultdict(list)
    for i, e in enumerate(old_special):
        blocks[matcher_kind(e[0], e[1])].append(i)

    deep_targets = [s for s in range(SPECIES_COUNT) if targets.get(s, 0) >= 2]
    rng.shuffle(deep_targets)
    shallow_targets = [s for s in range(SPECIES_COUNT) if targets.get(s, 0) == 1]

    used_pairs: set[tuple[int, int]] = set()
    spec_changed = 0
    for kind, idxs in blocks.items():
        for n, i in enumerate(idxs):
            # SS entries carry the deep results; F-matchers carry shallow ones.
            if kind == "SS" and deep_targets:
                result = deep_targets[n % len(deep_targets)]
            elif shallow_targets:
                result = shallow_targets[n % len(shallow_targets)]
            else:
                result = rng.randrange(SPECIES_COUNT)
            want = targets.get(result, 1)

            for _ in range(12):
                if kind[0] == "F":
                    src = _pick_parent(by_depth, max(0, want - 1), rng, {result})
                    p1 = FAMILY_LO + fam[src if src is not None else 0]
                else:
                    p1 = _pick_parent(by_depth, max(0, want - 1), rng, {result})
                    if p1 is None:
                        p1 = rng.randrange(SPECIES_COUNT)
                if kind[1] == "F":
                    src = _pick_parent(by_depth, max(0, want - 1), rng, {result})
                    p2 = FAMILY_LO + fam[src if src is not None else 0]
                else:
                    p2 = _pick_parent(by_depth, max(0, want - 1), rng, {result})
                    if p2 is None:
                        p2 = rng.randrange(SPECIES_COUNT)
                if (p1, p2) not in used_pairs:
                    break
            used_pairs.add((p1, p2))
            e = rom.special_recipes[i]
            if (e[0], e[1], e[3]) != (p1, p2, result):
                spec_changed += 1
            e[0], e[1], e[3] = p1, p2, result

    got = resolve_depths(rom, roots)

    # --- Constructive tier build.
    #
    # Depth is the MIN over every recipe producing a species, so one shallow
    # recipe collapses a deep target. Drawing parents by TARGET depth does not
    # work either: if nothing has reached depth d-1 yet, the picker falls back to
    # something shallower and the whole tier caves in. Earlier versions of this
    # loop shipped trees of depth 4 when 6 was asked for.
    #
    # So tiers are built IN ORDER. Depth 1 is fixed first against measured
    # depths, then depth 2 is fixed knowing depth 1 is real, and so on. Every
    # recipe for a target is forced to parents at EXACTLY want-1.
    fam_slots = {s for s, (a_, b_) in enumerate(old_family)
                 if (a_, b_) not in SEPARATORS and s < SPECIES_COUNT}

    def redraw(s: int, want: int, pool: dict) -> bool:
        exact = [x for x in pool.get(want - 1, ()) if x != s]
        if not exact:
            return False
        lower = [x for d2 in range(want) for x in pool.get(d2, ()) if x != s] or exact
        placed = False
        for i, e in enumerate(rom.special_recipes):
            if e[3] != s:
                continue
            kind = matcher_kind(old_special[i][0], old_special[i][1])
            if s in easy and kind == "SS":
                kind = "SF"
            p1 = rng.choice(exact)
            p2 = rng.choice(exact if rng.random() < 0.5 else lower)
            e[0] = FAMILY_LO + fam[p1] if kind[0] == "F" else p1
            e[1] = FAMILY_LO + fam[p2] if kind[1] == "F" else p2
            placed = True
        if s in fam_slots:
            a_, b_ = old_family[s]
            kind = matcher_kind(a_, b_)
            if s in easy and kind == "SS":
                kind = "FS"
            if kind == "FF":
                # A family x family pair is satisfiable by the shallowest member
                # of that family, so it can never encode depth > 1. Give the slot
                # a specific parent instead.
                kind = "SS"
            p1 = rng.choice(exact)
            p2 = rng.choice(exact if rng.random() < 0.5 else lower)
            rom.family_recipes[s] = (
                p1 if kind[0] == "S" else FAMILY_LO + fam[p1],
                p2 if kind[1] == "S" else FAMILY_LO + fam[p2])
            placed = True
        return placed

    for want in range(1, MAX_DEPTH + 1):
        for _ in range(6):
            pool = defaultdict(list)
            for sp_, dd in got.items():
                pool[dd if dd < 99 else MAX_DEPTH].append(sp_)
            short = [sp_ for sp_ in range(SPECIES_COUNT)
                     if targets.get(sp_, 0) == want and got.get(sp_, 99) != want]
            if not short:
                break
            progress = False
            for sp_ in short:
                if redraw(sp_, want, pool):
                    progress = True
            got = resolve_depths(rom, roots)
            if not progress:
                break

    dist = Counter(min(d, 20) for d in got.values())
    caps = defaultdict(list)
    for s, d in got.items():
        if d < 99:
            caps[d].append(rom.monsters[s].level_cap)

    rep.note(
        f"Breeding tree REGENERATED (not just re-pointed): {fam_changed} family "
        f"pairs and {spec_changed} special recipes rewritten, block specificity "
        f"and table ordering preserved. Depth profile now "
        f"{dict(sorted((k, v) for k, v in dist.items() if k < 20))}.")
    return {"depth": got, "dist": dist, "caps": caps,
            "fam_changed": fam_changed, "spec_changed": spec_changed}
