"""breed_gen.py — propose a whole breeding tree to a DEPTH PROFILE (ROADMAP P3.12
(c), S113; BREEDING_SYSTEM "Depth is a function of matcher SPECIFICITY").

The randomizer's tree builder (randomizer/breeding.py, S77 — user-tested on
the randomizer) lifted onto a PROJECT: the project's own species (0-214 + new
species, 11 families with Spirit), its own obtainable set (breeding.obtainable)
and level caps, its current tables as the starting shape. Unchanged rules:

  * depth = how specific a recipe's parents are: family x family can only be
    one step deep, so deep targets get specific parents;
  * targets are dealt by LEVEL CAP (deeper = better), into the profile;
  * tiers are built in ascending order, each recipe for a depth-d target
    forced onto parents measured at exactly d-1; best of N attempts;
  * monsters first met at level <= 6 never get a species x species recipe.

New for the editor: PINNED species keep every recipe that makes them; the
result is a candidate `gamedata.breeding` (the full family slot map + the
special table as `special.table`) that the user reviews in the Breeding tab —
nothing is written until they apply it. The compiler auto-orders the special
table, so the randomizer's "keep the specificity blocks" step is not needed.
Never imports Qt.
"""

import random
from collections import Counter, defaultdict

from .breeding import Analysis, is_family, matcher_kind

F0 = 0xF0
SEP = (0xFF, 0xFF)
DEFAULT_PROFILE = {1: 0.20, 2: 0.20, 3: 0.22, 4: 0.18, 5: 0.14, 6: 0.06}
DEFAULT_MAX_DEPTH = 6
EASY_LEVEL = 6


class Proposal:
    def __init__(self, family, special, report, depth):
        self.family = family          # [(b, c)] x 222 (slot = offspring)
        self.special = special        # [[p1, p2, min_plus, result, plus_mod]]
        self.report = report          # lines
        self.depth = depth            # {species: depth} measured by the resolver


def easy_species(an):
    """Species met wild at level <= EASY_LEVEL (vanilla: 0 of 15 has an SS recipe)."""
    g = an.g
    out = set()
    for r in g.pool:
        for k in range(5):
            if r[5 + k] == 0:
                continue
            eid = r[10 + 2 * k] | r[11 + 2 * k] << 8
            if 0 <= eid < len(g.enemy) and g.enemy[eid][4] <= EASY_LEVEL:
                out.add(g.enemy[eid][0])
    return out


def _recipe_depth(fam, species, family, special, roots):
    """The randomizer's fast fixpoint (recipe rows, family matchers satisfied by
    the shallowest member) — used while building; the proposal's final numbers
    come from the real resolver (breeding.Analysis)."""
    INF = 99
    prod = defaultdict(list)
    for slot, (a, b) in enumerate(family):
        if (a, b) == SEP or (a, b) == (0, 0) or slot not in fam:
            continue
        prod[slot].append((a, b))
    for p1, p2, _mp, res, _m in special:
        if res in fam:
            prod[res].append((p1, p2))
    depth = {s: (0 if s in roots else INF) for s in species}
    by_family = defaultdict(list)
    for s in species:
        by_family[fam[s]].append(s)

    def md(m):
        if is_family(m):
            return min((depth[s] for s in by_family.get(m - F0, ())), default=INF)
        return depth.get(m, INF)
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


MAX_DEPTH_LIMIT = 40          # no engine limit; the tree is bounded by how many
                              # monsters are NOT obtainable without breeding


def default_profile(max_depth):
    """The share per depth 1..max_depth: the randomizer's front-loaded profile
    up to 6 (S77, user-tested); deeper trees taper evenly from 1 to max_depth
    (each depth a little smaller than the one before, every depth populated)."""
    if max_depth == DEFAULT_MAX_DEPTH:
        return dict(DEFAULT_PROFILE)
    w = {d: max_depth + 1 - d * 0.5 for d in range(1, max_depth + 1)}
    t = sum(w.values())
    return {d: v / t for d, v in w.items()}


def propose(prj, seed=113, profile=None, max_depth=DEFAULT_MAX_DEPTH, pins=(),
            attempts=None):
    """-> Proposal. `profile` = {depth: share of the breedable species} (any
    scale — normalised; depths above max_depth ignored). Any max_depth up to
    MAX_DEPTH_LIMIT; deep trees get more attempts (best of N)."""
    max_depth = max(1, min(int(max_depth), MAX_DEPTH_LIMIT))
    profile = {d: v for d, v in (profile or default_profile(max_depth)).items()
               if 1 <= d <= max_depth and v > 0}
    tot = sum(profile.values()) or 1.0
    profile = {d: v / tot for d, v in profile.items()}
    if attempts is None:
        attempts = max(5, 2 * max_depth)
    an = Analysis(prj)
    rng = random.Random(seed)
    species = [s for s in an.species]
    fam = {s: an.fast.fam(s) - F0 for s in species}
    roots = {s for s in an.roots if s in fam}
    pins = {int(s) for s in pins}
    easy = easy_species(an)
    families = sorted({fam[s] for s in species})
    base_family = [tuple(r) for r in an.br.family]
    base_special = [list(e) for e in an.br.special]

    # targets: rank the breedable species by level cap, deal into the profile
    breedable = [s for s in species if s not in roots and s not in pins]
    pinned_depth = {s: an.depth[s] for s in pins if s in an.depth}

    def targets_for():
        order = sorted(breedable, key=lambda s: (an.level_cap.get(s, 0), rng.random()))
        t = {s: 0 for s in roots}
        t.update(pinned_depth)
        n, i = len(order), 0
        for d in sorted(profile):
            if d > max_depth:
                continue
            take = round(n * profile[d])
            for s in order[i:i + take]:
                t[s] = d
            i += take
        for s in order[i:]:
            t[s] = max_depth
        return t

    def pick(by_depth, want, exclude):
        for d in range(want, -1, -1):
            c = [s for s in by_depth.get(d, ()) if s not in exclude]
            if c:
                return rng.choice(c)
        return None

    def once():
        family = list(base_family)
        special = [list(e) for e in base_special]
        targets = targets_for()
        by_depth = defaultdict(list)
        for s, d in targets.items():
            by_depth[d].append(s)
        keep_rows = {i for i, e in enumerate(special) if e[3] in pins}
        # family slots: the slot's matcher kind is kept (shape), its parents redrawn
        for slot, (a, b) in enumerate(base_family):
            if (a, b) in (SEP, (0, 0)) or slot not in fam or slot in pins:
                continue
            want = targets.get(slot, 1)
            kind = matcher_kind(a, b)
            if slot in easy and kind == 'SS':
                kind = 'FS'
            if kind == 'FF':
                p = (F0 + rng.choice(families), F0 + rng.choice(families))
            else:
                spec = pick(by_depth, max(0, want - 1), {slot})
                if spec is None:
                    spec = rng.choice(species)
                other = pick(by_depth, max(0, want - 2), {slot, spec})
                of = F0 + fam[other if other is not None else rng.choice(species)]
                if kind == 'SS':
                    sec = pick(by_depth, max(0, want - 1), {slot, spec})
                    p = (spec, sec if sec is not None else rng.choice(species))
                elif kind == 'FS':
                    p = (of, spec)
                else:
                    p = (spec, of)
            family[slot] = p
        # special rows: SS rows carry the deep targets, family rows the shallow
        deep = [s for s in species if targets.get(s, 0) >= 2 and s not in pins]
        rng.shuffle(deep)
        shallow = [s for s in species if targets.get(s, 0) == 1 and s not in pins]
        used = {(e[0], e[1], e[2]) for i, e in enumerate(special) if i in keep_rows}
        n_by_kind = Counter()
        for i, e in enumerate(base_special):
            if i in keep_rows:
                continue
            kind = matcher_kind(e[0], e[1])
            n = n_by_kind[kind]
            n_by_kind[kind] += 1
            if kind == 'SS' and deep:
                res = deep[n % len(deep)]
            elif shallow:
                res = shallow[n % len(shallow)]
            else:
                res = rng.choice(species)
            want = targets.get(res, 1)
            for _ in range(12):
                p = []
                for side in (0, 1):
                    src = pick(by_depth, max(0, want - 1), {res})
                    if src is None:
                        src = rng.choice(species)
                    p.append(F0 + fam[src] if kind[side] == 'F' else src)
                if (p[0], p[1], e[2]) not in used:
                    break
            used.add((p[0], p[1], e[2]))
            special[i] = [p[0], p[1], e[2], res, e[4]]
        got = _recipe_depth(fam, species, family, special, roots)

        # constructive tiers: every recipe of a short target onto parents at want-1
        def redraw(s, want, pool):
            exact = [x for x in pool.get(want - 1, ()) if x != s]
            if not exact:
                return False
            lower = [x for d in range(want) for x in pool.get(d, ()) if x != s] or exact
            placed = False
            for i, e in enumerate(special):
                if e[3] != s or i in keep_rows:
                    continue
                kind = matcher_kind(base_special[i][0], base_special[i][1])
                if s in easy and kind == 'SS':
                    kind = 'SF'
                a = rng.choice(exact)
                b = rng.choice(exact if rng.random() < 0.5 else lower)
                e[0] = F0 + fam[a] if kind[0] == 'F' else a
                e[1] = F0 + fam[b] if kind[1] == 'F' else b
                placed = True
            if s in fam and s <= 214 and base_family[s] not in (SEP, (0, 0)) and s not in pins:
                kind = matcher_kind(*base_family[s])
                if s in easy and kind == 'SS':
                    kind = 'FS'
                if kind == 'FF':
                    kind = 'SS'
                a = rng.choice(exact)
                b = rng.choice(exact if rng.random() < 0.5 else lower)
                family[s] = (a if kind[0] == 'S' else F0 + fam[a],
                             b if kind[1] == 'S' else F0 + fam[b])
                placed = True
            return placed
        for want in range(1, max_depth + 1):
            for _ in range(6):
                pool = defaultdict(list)
                for x, d in got.items():
                    pool[d if d < 99 else max_depth].append(x)
                short = [x for x in species if targets.get(x, 0) == want
                         and got.get(x, 99) != want]
                if not short:
                    break
                progress = any([redraw(x, want, pool) for x in short])
                got = _recipe_depth(fam, species, family, special, roots)
                if not progress:
                    break
        # the compiler refuses two rows with the same parents + min plus: keep
        # the first of each (pinned rows first)
        seen, out = set(), []
        for i, e in sorted(enumerate(special), key=lambda t: (t[0] not in keep_rows, t[0])):
            k = (e[0], e[1], e[2])
            if k in seen:
                continue
            seen.add(k)
            out.append(e)
        return family, out, got

    best = None
    for _ in range(attempts):
        family, special, got = once()
        reach = max((d for d in got.values() if d < 99), default=0)
        deep = sum(1 for d in got.values() if 3 <= d < 99)
        score = (reach >= max_depth, reach, deep)
        if best is None or score > best[0]:
            best = (score, family, special)
        if score[0]:
            break
    _score, family, special = best
    rep = [f"seed {seed}, max depth {max_depth} (reached {_score[1]}), "
           f"{len(pins)} pinned species, {len(roots)} obtainable without breeding"]
    return Proposal(family, special, rep, None)


def to_gamedata(proposal, repo=None):
    """The proposal as `gamedata.breeding`: every family slot 0-214 that differs
    from vanilla (null = no recipe) and the whole special table as `table`.
    Species are written as ids, families by name (a bare "Slime" would be the
    family)."""
    from . import gamedata as G
    vrows = [tuple(r) for r in G._rows(G.vanilla(repo or _repo()), 'family_recipes')]

    def m(x):
        return G.FAMILY_CODES[x] if is_family(x) else int(x)
    fam_out = {}
    for slot in range(G.COLLECTIBLE_MAX + 1):
        p = tuple(proposal.family[slot])
        if p == vrows[slot]:
            continue
        fam_out[str(slot)] = None if p == SEP else {'p1': m(p[0]), 'p2': m(p[1])}
    table = [{'p1': m(e[0]), 'p2': m(e[1]), 'min_plus': e[2], 'result': e[3],
              'plus_mod': e[4]} for e in proposal.special]
    return {'family': fam_out, 'special': {'table': table}}


def apply_to(data, breeding_gd):
    """A copy of project data with `gamedata.breeding` replaced."""
    import copy
    d = copy.deepcopy(data)
    d.setdefault('gamedata', {})['breeding'] = breeding_gd
    return d


def _repo():
    import os
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
