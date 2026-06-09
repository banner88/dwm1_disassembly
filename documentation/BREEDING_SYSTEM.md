# DWM1 Breeding System — Complete Technical Reference

## Overview

Breeding is handled in **Bank $16**. The offspring determination function `Call_016_456e` (entry 2) executes three steps in priority order:

1. **Special recipe table** at `$16:$4B30` — 825 entries × 5 bytes, checked FIRST
2. **Family recipe table** at `$16:$4974` — 2-byte pair entries, checked SECOND
3. **Fallback** — offspring = parent 1 (pedigree) species

A post-recipe **mutation system** (~1-5% RNG) at `$16:$44DA` can override the result.

## RAM Variables

| Address | Name | Description |
|---------|------|-------------|
| `$DA6F` | Parent 1 species | Pedigree parent |
| `$DA70` | Parent 2 species | Mate parent (or family code $F0-$F9 after conversion) |
| `$DA71` | Result species | Output ($FF = not found) |
| `$DA72` | Parent 1 family | Family code $F0-$F9 (for family table) |
| `$DA73` | Parent 1 family | Family code (for special table) |
| `$DA74` | Parent 2 family | Family code (for special table) |
| `$DA75` | Parent 1 slot | Party slot index |
| `$DA76` | Parent 2 slot | Party slot index |
| `$DA77` | Offspring plus | Computed plus value 0-99 |
| `$D9E6` | Mutation flag | Set when mutation occurs |

## Family Codes

| Code | Family |
|------|--------|
| `$F0` | Slime |
| `$F1` | Dragon |
| `$F2` | Beast |
| `$F3` | Flying |
| `$F4` | Plant |
| `$F5` | Bug |
| `$F6` | Devil |
| `$F7` | Zombie |
| `$F8` | Material |
| `$F9` | Boss |

## Step 1: Special Recipe Table ($4B30)

**Function**: `Call_016_4653` → scan loop at `jr_016_46f5`

**Table format**: 5 bytes per entry, `$FF` terminated

| Offset | Size | Description |
|--------|------|-------------|
| +0 | 1 | Parent 1 matcher (species ID or family code $F0-$F9) |
| +1 | 1 | Parent 2 matcher (species ID or family code $F0-$F9) |
| +2 | 1 | Minimum plus threshold |
| +3 | 1 | Result species ID |
| +4 | 1 | Plus modifier (added to offspring plus) |

**Match logic** (`Call_016_471c`):
- Byte 0 matches if equal to parent 1 species (`$DA6F`) OR parent 1 family (`$DA73`)
- Byte 1 matches if equal to parent 2 species (`$DA70`) OR parent 2 family (`$DA74`)
- Byte 2: offspring plus (`$DA77`) must be >= this threshold

**825 entries** producing 106 distinct species. The table contains:
- Species-specific combinations (e.g., DragonKid × DragonKid with plus>=4 → GreatDrak)
- Family-based overrides (e.g., Grizzly × [Dragon] → GulpBeast)
- Plus-gated evolutions (e.g., Slime × Slime with plus>=5 → KingSlime)

## Step 2: Family Recipe Table ($4974)

**Function**: `Call_016_45d5` → `Call_016_45ff`

**Table format**: 2-byte pairs `[B, C]`, `$FFFF` separators, `$0000` terminator

The result species index `D` starts at -1 and increments at every 2-byte read (including separators). So `$FFFF` entries advance D without storing a recipe.

**Match logic** (critical — order matters):
- **Exact species match** on parent 1: returns IMMEDIATELY
- **Family match** on parent 1: stores result but CONTINUES SCANNING (last family match wins)
- Parent 2 must match C exactly (or C matches parent 2's family code if parent 2 is family-coded)

**Two-pass search** (`Call_016_45d5`):
1. First pass: parent 2 as specific species → only exact C matches possible
2. Second pass: parent 2 converted to family code → family C matches possible

**197 result species** covering the basic family × family cross and species-specific recipes.

## Step 3: Fallback

If neither table produces a result, offspring = parent 1 species (`$DA6F`). This is how breeding the same species works (e.g., Anteater + Beast → Anteater).

## Plus Value Computation

Before table searches, `Call_016_4653` computes the offspring's plus value:

1. Read both parents' plus values from party struct offset `$CB23` (via `Call_000_223b`)
2. Take the higher of the two, increment by 1
3. Add a bonus based on sum of parent levels:
   - Sum >= 100: +4
   - Sum >= 76: +3
   - Sum >= 60: +2
   - Sum >= 40: +1
   - Otherwise: +0
4. Clamp to max 99

## Data Files

- `extracted/breeding_complete.json` — both tables fully decoded
- `extracted/breeding_recipes.json` — family table only
