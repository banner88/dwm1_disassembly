"""breeding.py — the game's breeding resolver in Python + the project's breeding
analysis (ROADMAP P3.12, S113; BREEDING_SYSTEM "The resolver as measured (S113)").

`Breeding(g)` takes a resolved `gamedata.Gamedata` (the EFFECTIVE family table
and the effective special table in the order the compiler emits it) and
answers what the game answers:

  resolve(p1, p2, plus1, plus2, lvl1, lvl2) -> Cross(species, plus, how, index)

It is a line-for-line model of bank $16 BreedResolveOffspring (entry 2) /
BreedResolvePreview (entry 3) in the PATCHED build (special scan relocated to
bank $69, Spirit = $FA compared exactly). tools/census_breeding.py stub-calls
the real routine in PyBoy for every pair of parents and compares.

Never imports Qt.
"""

from collections import defaultdict, namedtuple

F0 = 0xF0
SPIRIT_CODE = 0xFA
PLUS_CAP = 99
# level-sum bonus of BreedPlusAndSpecial: (minimum sum, bonus), first hit wins
LEVEL_BONUS = ((100, 4), (76, 3), (60, 2), (40, 1))

Cross = namedtuple('Cross', 'species plus how index')
# how: 'special' (index = row of the special table), 'family' (index = slot =
# the offspring), 'parent' (no recipe: the pedigree's species, index None)


def is_family(m):
    return F0 <= m <= SPIRIT_CODE


def matcher_kind(a, b):
    """'SS' / 'SF' / 'FS' / 'FF' — S = a species, F = a family code."""
    return ('F' if is_family(a) else 'S') + ('F' if is_family(b) else 'S')


def offspring_plus(plus1, plus2, lvl1, lvl2, link=False):
    """BreedPlusAndSpecial's plus before the special table: the higher plus + 1
    (link session: the pedigree's + 1), + the bonus for the parents' level sum,
    capped at 99."""
    p = (plus1 if link else max(plus1, plus2)) + 1
    s = (lvl1 + lvl2) & 0xFF
    for lo, bonus in LEVEL_BONUS:
        if s >= lo:
            p += bonus
            break
    return min(p & 0xFF, PLUS_CAP)


class Breeding:
    def __init__(self, g):
        self.g = g
        self.family = [tuple(r) for r in g.family]
        self.special = [tuple(e) for e in g.special]

    # ------------------------------------------------------------ the game
    def fam_code(self, sp):
        return self.g.fam_code(sp)

    def special_hit(self, p1, p2, plus):
        """Index of the first special row that fires, or None."""
        f1, f2 = self.fam_code(p1), self.fam_code(p2)
        for i, e in enumerate(self.special):
            if (e[0] == p1 or e[0] == f1) and (e[1] == p2 or e[1] == f2) \
                    and plus >= e[2]:
                return i
        return None

    def _family_pass(self, p1, f1, mate):
        found = None
        for d, (b, c) in enumerate(self.family):
            if b == 0 and c == 0:
                break                              # $0000 = end of table
            if b == 0xFF and c == 0xFF:
                continue                           # $FFFF = no recipe for slot d
            if mate != c:
                continue
            if p1 == b:
                return d                           # exact pedigree: wins at once
            if f1 == b:
                found = d                          # family pedigree: last one wins
        return found

    def family_hit(self, p1, p2):
        """Slot (= offspring) the family table gives, or None (two passes)."""
        f1 = self.fam_code(p1)
        hit = self._family_pass(p1, f1, p2)
        if hit is None:
            hit = self._family_pass(p1, f1, self.fam_code(p2))
        return hit

    def resolve(self, p1, p2, plus1=0, plus2=0, lvl1=1, lvl2=1, link=False):
        plus = offspring_plus(plus1, plus2, lvl1, lvl2, link)
        i = self.special_hit(p1, p2, plus)
        if i is not None:
            e = self.special[i]
            return Cross(e[3], min((plus + e[4]) & 0xFF, PLUS_CAP), 'special', i)
        d = self.family_hit(p1, p2)
        if d is not None:
            return Cross(d, plus, 'family', d)
        return Cross(p1, plus, 'parent', None)


# ---------------------------------------------------------------------------
# fast resolution (the same rules, indexed) — for the whole-table analyses
# ---------------------------------------------------------------------------

class FastResolver:
    """Breeding.resolve's species answer, indexed for speed: the first special
    row for (pedigree, mate) is the lowest row index among the rows keyed
    (p1|f1, p2|f2) whose min plus <= the offspring plus; the family table is
    pre-split by mate matcher. Same answers as Breeding.resolve (tested)."""

    def __init__(self, br):
        self.br = br
        self.by_key = defaultdict(list)            # (m1, m2) -> [(row, min_plus)]
        for i, e in enumerate(br.special):
            self.by_key[(e[0], e[1])].append((i, e[2]))
        self.fam_rows = defaultdict(list)          # mate matcher -> [(slot, ped matcher)]
        for d, (b, c) in enumerate(br.family):
            if (b, c) == (0, 0):
                break
            if (b, c) == (0xFF, 0xFF):
                continue
            self.fam_rows[c].append((d, b))
        self.fc = {}

    def fam(self, sp):
        if sp not in self.fc:
            self.fc[sp] = self.br.fam_code(sp)
        return self.fc[sp]

    def special_hit(self, p1, p2, plus):
        f1, f2 = self.fam(p1), self.fam(p2)
        best = None
        for k in {(p1, p2), (p1, f2), (f1, p2), (f1, f2)}:
            for i, mp in self.by_key.get(k, ()):
                if plus >= mp:
                    if best is None or i < best:
                        best = i
                    break                          # rows are in index order
        return best

    def _pass(self, p1, f1, mate):
        found = None
        for d, b in self.fam_rows.get(mate, ()):
            if b == p1:
                return d
            if b == f1:
                found = d
        return found

    def family_hit(self, p1, p2):
        f1 = self.fam(p1)
        d = self._pass(p1, f1, p2)
        if d is None:
            d = self._pass(p1, f1, self.fam(p2))
        return d

    def resolve(self, p1, p2, plus):
        """-> (species, how, index) at an offspring plus (after the level bonus)."""
        i = self.special_hit(p1, p2, plus)
        if i is not None:
            return self.br.special[i][3], 'special', i
        d = self.family_hit(p1, p2)
        if d is not None:
            return d, 'family', d
        return p1, 'parent', None


# ---------------------------------------------------------------------------
# the project's breeding analysis (the Breeding tab's read-outs)
# ---------------------------------------------------------------------------

UNREACHABLE = 99


def plus_levels(special):
    """The offspring plus values at which results can differ: 0 and every min
    plus a row asks for (capped at 99)."""
    return sorted({0} | {min(e[2], PLUS_CAP) for e in special})


def obtainable(prj, g=None):
    """{species: [how, ...]} — what a player can get WITHOUT breeding (the
    breeding tree's roots), from the project's own data:
      * wild: a monster row in an encounter list slot with a chance, that can
        join (joinability != 7) — vanilla lists as edited + project enemies;
      * the starter (EID 1);
      * a boss / story fight's join version (the 34 vanilla fight -> join rows
        when the fight row can join; project enemies' `join_as`);
      * vanilla script gifts (AddMonster, op $29: the starter, the SkyDragon
        egg, the farm's Slime eggs, the stable's Watabou, the restaurant's
        StoneMan — extracted/all_scripts.json) and the project's own scripts'
        `add_monster` ops (egg rewards)."""
    import json
    import os
    from . import gamedata as G
    g = g or prj.gamedata()
    out = defaultdict(list)

    def row(eid):
        if 0 <= eid < len(g.enemy):
            r = g.enemy[eid]
            return r[0], r[3]
        for e in prj.quest_enemies.values():
            if e['_eid'] == eid:
                return int(e.get('species', 0)), int(e.get('joinability', 0))
        return None, None

    def add(sp, how):
        if sp is not None and how not in out[sp]:
            out[sp].append(how)

    for pi, r in enumerate(g.pool):
        for k in range(5):
            if r[5 + k] == 0:
                continue
            eid = r[10 + 2 * k] | r[11 + 2 * k] << 8
            sp, join = row(eid)
            if sp is not None and join != 7:
                add(sp, f'wild (encounter list {pi})')
    sp, _j = row(1)
    add(sp, 'the starter')
    for f, j in g.redirects:
        _fs, fj = row(f)
        if fj is not None and fj != 7:
            sp, _ = row(j)
            add(sp, f'joins after its boss fight (EID {f})')
    for e in prj.quest_enemies.values():
        if e.get('join_as') is not None:
            try:
                sp, _ = row(prj.enemy_ref(e['join_as'], 'join_as'))
            except Exception:
                sp = None
            add(sp, f"joins after the project fight '{e['id']}'")
    try:
        d = json.load(open(os.path.join(g.repo, 'extracted', 'all_scripts.json')))
        for s in d.get('scripts', []):
            w = s.get('words', [])
            for i, x in enumerate(w[:-1]):
                if x == '$FF29':
                    sp, _ = row(int(w[i + 1][1:], 16))
                    add(sp, f"gift in the story ({s.get('map_name')} script {s.get('script_id')})")
    except (OSError, ValueError):
        pass

    def walk(o):
        if isinstance(o, list):
            if len(o) >= 2 and o[0] == 'add_monster':
                yield o[1]
            elif len(o) >= 3 and o[0] == 'op' and o[1] == 'add_monster':
                yield o[2]
            for x in o:
                yield from walk(x)
        elif isinstance(o, dict):
            for x in o.values():
                yield from walk(x)
    for ref in walk(prj.data.get('custom') or {}):
        try:
            eid = prj.enemy_ref(ref, 'add_monster')
        except Exception:
            continue
        sp, _ = row(eid)
        add(sp, 'egg / gift from a project script')
    return dict(out)


class Analysis:
    """Everything the Breeding tab shows, computed from the RESOLVER (not from
    the recipe rows alone, so a row that is beaten for some parents counts only
    where it really fires)."""

    def __init__(self, prj, g=None):
        from . import gamedata as G
        from . import species as SP
        self.prj = prj
        self.g = g = g or prj.gamedata()
        self.br = Breeding(g)
        self.fast = FastResolver(self.br)
        self.names = dict(g.names)
        new = {}
        try:
            for s in SP.resolve(prj, with_art=False):
                new[s['id']] = s
        except Exception:
            pass
        self.new_ids = sorted(new)
        self.species = list(range(G.COLLECTIBLE_MAX + 1)) + self.new_ids
        self.ratio = {s: g.monster[s][3] for s in range(G.COLLECTIBLE_MAX + 1)}
        for sid, s in new.items():
            self.ratio[sid] = s['info'][3]
        self.level_cap = {s: g.monster[s][1] for s in range(G.COLLECTIBLE_MAX + 1)}
        for sid, s in new.items():
            self.level_cap[sid] = s['info'][1]
        self.roots = obtainable(prj, g)
        self.plus = plus_levels(self.br.special)
        self._table()
        self._depth()

    def _table(self):
        """produce[s] = {(p1, p2): (how, index, min offspring plus)};
        row_use[i] = number of (pedigree, mate) pairs special row i decides;
        slot_use[d] = same for family slots."""
        self.produce = defaultdict(dict)
        self.row_use = defaultdict(int)
        self.slot_use = defaultdict(int)
        sp = self.species
        for p1 in sp:
            for p2 in sp:
                seen = set()
                for plus in self.plus:
                    res, how, idx = self.fast.resolve(p1, p2, plus)
                    if (res, how, idx) in seen:
                        continue
                    seen.add((res, how, idx))
                    if how == 'special':
                        self.row_use[idx] += 1
                    elif how == 'family':
                        self.slot_use[idx] += 1
                    if how != 'parent' and (p1, p2) not in self.produce[res]:
                        self.produce[res][(p1, p2)] = (how, idx, plus)

    def _depth(self):
        """Breeding depth: 0 for what can be obtained without breeding, else
        1 + the deeper parent of the shallowest pair that makes it (any plus —
        a + route is labelled, not charged; PLUS needs ~1 breed of level-50
        parents per +5). 99 = cannot be obtained at all."""
        depth = {s: (0 if s in self.roots else UNREACHABLE) for s in self.species}
        via = {}
        for _ in range(64):
            changed = False
            for s, pairs in self.produce.items():
                if s not in depth:
                    continue
                for (a, b), info in pairs.items():
                    d = max(depth.get(a, UNREACHABLE), depth.get(b, UNREACHABLE)) + 1
                    if d < depth[s]:
                        depth[s] = d
                        via[s] = ((a, b), info)
                        changed = True
            if not changed:
                break
        self.depth = depth
        self.via = via

    # ----------------------------------------------------------- read-outs
    def name(self, m):
        from . import gamedata as G
        return G.matcher_name(m, self.names)

    def histogram(self, depth=None):
        from collections import Counter
        depth = depth or self.depth
        return dict(sorted(Counter(min(depth[s], UNREACHABLE) for s in self.species
                                   if s <= 214 or s in self.new_ids).items()))

    def unreachable(self):
        return [s for s in self.species if self.depth[s] >= UNREACHABLE]

    def never_fires(self):
        """Special rows that decide no possible pair (beaten everywhere, or
        naming parents no one can breed); family slots likewise."""
        rows = [i for i in range(len(self.br.special)) if not self.row_use.get(i)]
        slots = [d for d, (b, c) in enumerate(self.br.family)
                 if (b, c) not in ((0xFF, 0xFF), (0, 0)) and d <= 214
                 and not self.slot_use.get(d)]
        return rows, slots

    def makes(self, s):
        """How species s is bred: {(how, index): [pairs]} (pairs (p1, p2, plus))."""
        out = defaultdict(list)
        for (a, b), (how, idx, plus) in self.produce.get(s, {}).items():
            out[(how, idx)].append((a, b, plus))
        return dict(out)

    def breeds_into(self, s):
        """What s makes as pedigree or mate: {offspring: [(p1, p2, plus)]}."""
        out = defaultdict(list)
        for res, pairs in self.produce.items():
            for (a, b), (_h, _i, plus) in pairs.items():
                if a == s or b == s:
                    out[res].append((a, b, plus))
        return dict(out)

    def members(self, m):
        """The breedable species a matcher stands for."""
        if is_family(m):
            return [s for s in self.species if self.fast.fam(s) == m]
        return [m] if m in self.depth else []

    def library_mismatch(self):
        """{species: (pairs, giving)} for every library page whose recipe (the
        family slot's pair) does NOT give that species for some of the parents it
        names (giving = how many of the pairs do). The page is the only recipe
        the game shows; the special table is scanned first (BREEDING_SYSTEM
        "Library recipe TEXT")."""
        out = {}
        for d, (b, c) in enumerate(self.br.family):
            if d > 214 or (b, c) in ((0xFF, 0xFF), (0, 0)):
                continue
            pairs = [(x, y) for x in self.members(b) for y in self.members(c)]
            give = sum(1 for x, y in pairs if (x, y) in self.produce.get(d, {}))
            if give < len(pairs):
                out[d] = (len(pairs), give)
        return out
