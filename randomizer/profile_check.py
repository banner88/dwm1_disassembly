#!/usr/bin/env python3
"""Per-ENTITY envelope check against vanilla.

    python3 randomizer/profile_check.py data/DWM-german.gbc out/DWM-german-rando.gbc

Why this exists (S78): every check the randomizer had was an AGGREGATE — "0 rows
harder than vanilla", correlations, depth profiles, multiset equality. All of
them passed while the game played wrong, because none of them asked whether an
INDIVIDUAL entity was plausible. Aggregates are structurally blind to outliers:
a species at 23x vanilla MP growth and a skill on 44 rows instead of 1 both
preserve every distribution we were measuring.

Everything here compares one entity against the envelope VANILLA itself defines
for comparable entities, and exits non-zero on violation so it can gate a build.
"""

from __future__ import annotations

import collections
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from randomizer import logic, names
from randomizer.romdata import Rom

STAT_LABELS = ["HP", "MP", "ATK", "DEF", "AGL", "INT"]
GROWTH_MAX_RATIO = 2.5      # a species-stat may not exceed this multiple of vanilla
GROWTH_MIN_DELTA = 60       # ...and only counts if the absolute change matters too
SKILL_COUNT_SLACK = 8       # absolute row-count drift allowed per skill
EASY_LEVEL = 6


def growth_total(rom: Rom, species: int, col: int, level: int = 30) -> int:
    return sum(rom.growth_curves[rom.monsters[species].growth[col]][1:level])


def first_seen(rom: Rom) -> dict[int, int]:
    out: dict[int, int] = {}
    for p in rom.pools:
        for i in p.live_slots():
            e = rom.enemies[p.eids[i]]
            out[e.species] = min(out.get(e.species, 99), e.level)
    return out


def check(van: Rom, new: Rom, sk: list[str], sp: list[str]) -> list[str]:
    fails: list[str] = []

    # 1. Growth: no species-stat may run far past what vanilla gave it.
    worst = []
    for s in range(221):
        for c in range(6):
            a = growth_total(van, s, c)
            b = growth_total(new, s, c)
            if a > 0:
                worst.append((b / a, s, c, a, b))
    worst.sort(reverse=True)
    bad = [w for w in worst if w[0] > GROWTH_MAX_RATIO and (w[4] - w[3]) > GROWTH_MIN_DELTA]
    print(f"[growth]   species-stat pairs over {GROWTH_MAX_RATIO}x vanilla: {len(bad)}")
    for r, s, c, a, b in worst[:5]:
        flag = "  <-- FAIL" if (r > GROWTH_MAX_RATIO and b - a > GROWTH_MIN_DELTA) else ""
        print(f"           {sp[s]:<13} {STAT_LABELS[c]:3s} by L30 {a:4d} -> {b:4d}  {r:5.2f}x{flag}")
    if bad:
        fails.append(f"{len(bad)} species-stat growth pairs exceed {GROWTH_MAX_RATIO}x vanilla")

    # 2. Skill usage frequency: rare skills must not flood.
    cv = collections.Counter(s for e in van.enemies for s in e.skills if s != 0xFF)
    cn = collections.Counter(s for e in new.enemies for s in e.skills if s != 0xFF)
    drift = sorted(((abs(cn[i] - cv[i]), i) for i in set(cv) | set(cn)), reverse=True)
    over = [(d, i) for d, i in drift if d > SKILL_COUNT_SLACK]
    novel = [i for i in cn if cv[i] == 0]
    print(f"[skills]   usage counts drifting more than {SKILL_COUNT_SLACK} rows: {len(over)}"
          f"; skills vanilla never gives an enemy: {len(novel)}")
    for d, i in drift[:5]:
        flag = "  <-- FAIL" if d > SKILL_COUNT_SLACK else ""
        print(f"           {sk[i]:<13} {cv[i]:3d} -> {cn[i]:3d}{flag}")
    if over:
        fails.append(f"{len(over)} skills drift more than {SKILL_COUNT_SLACK} rows in usage")
    if novel:
        fails.append(f"{len(novel)} skills appear on enemies that vanilla never arms")

    # 3. Skill placement: never below the lowest level vanilla used it at.
    place = logic.vanilla_placement(van)
    viol = [(e.id, e.level, sk[s]) for e in new.enemies for s in e.skills
            if s != 0xFF and e.level and s in place and e.level < place[s][0]]
    print(f"[placement] rows carrying a skill below vanilla's minimum level: {len(viol)}")
    for v in viol[:5]:
        print(f"           EID {v[0]} L{v[1]} {v[2]}")
    if viol:
        fails.append(f"{len(viol)} rows carry a skill below vanilla's minimum placement level")

    # 4. Early monsters stay base monsters.
    def kinds(rom: Rom, s: int) -> list[str]:
        out = []
        a, b = rom.family_recipes[s]
        if (a, b) not in ((0xFF, 0xFF), (0, 0)):
            out.append(("F" if a >= 0xF0 else "S") + ("F" if b >= 0xF0 else "S"))
        for p1, p2, _m, res, _x in rom.special_recipes:
            if res == s:
                out.append(("F" if p1 >= 0xF0 else "S") + ("F" if p2 >= 0xF0 else "S"))
        return out

    fs = first_seen(new)
    ss_early = [sp[s] for s, lv in fs.items() if lv <= EASY_LEVEL and "SS" in kinds(new, s)]
    print(f"[base]     species first met at L<={EASY_LEVEL} with a specific x specific "
          f"recipe: {len(ss_early)} (vanilla: 0)")
    if ss_early:
        fails.append(f"{len(ss_early)} early monsters need a specific x specific recipe")

    # 5. Per-row threat, by level band rather than in aggregate.
    def worst_dmg(rom: Rom, e) -> int:
        b = 0
        for s in e.skills:
            if s != 0xFF and rom.skill_records[s].is_damaging:
                b = max(b, rom.skill_records[s].enemy_max)
        return b

    harder = [i for i in range(len(new.enemies))
              if worst_dmg(new, new.enemies[i]) > worst_dmg(van, van.enemies[i])]
    print(f"[threat]   rows dealing more skill damage than vanilla: {len(harder)}")
    if harder:
        fails.append(f"{len(harder)} rows deal more damage than vanilla")

    # 6. Encounter pools: no duplicate EID, level preserved.
    dup = [p.id for p in new.pools
           if len({p.eids[i] for i in p.live_slots()}) < len(p.live_slots())]
    drift_lv = max((abs(van.enemies[a.eids[i]].level - new.enemies[b.eids[i]].level)
                    for a, b in zip(van.pools, new.pools) for i in a.live_slots()),
                   default=0)
    print(f"[pools]    duplicate-EID pools: {len(dup)}; worst encounter level drift: {drift_lv}")
    if dup:
        fails.append(f"{len(dup)} pools contain a duplicate EID")
    return fails


def main(argv) -> int:
    if len(argv) < 3:
        print(__doc__)
        return 2
    van, new = Rom.load(argv[1]), Rom.load(argv[2])
    nm = names.load(open(argv[2], "rb").read())
    fails = check(van, new, nm["skills"], nm["species"])
    print()
    if fails:
        print("PROFILE CHECK: FAIL")
        for f in fails:
            print(f"  - {f}")
        return 1
    print("PROFILE CHECK: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
