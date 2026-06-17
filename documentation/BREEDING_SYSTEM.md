# DWM1 Breeding System — Complete Technical Reference

> **Custom breeding PROVEN (v31, Session 12).** A special-recipe override —
> Anteater × BattleRex → GoldSlime — was applied as a same-size, in-place edit
> of two provably-dead table entries (zero vanilla collateral) and confirmed
> in-game in SameBoy. Tool: `tools/patch_breeding_recipe.py`; patch:
> `patches/bank_016.asm` (bank $16 now in the verifier's patch set). A
> romhack-scale overhaul + extension is specced below ("Planned: Overhaul &
> Extension").

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

**CRITICAL — the result species IS the slot index.** On a match the handler
does `ld a,d; ld [$da71],a`: the offspring species equals `D`, i.e. the
positional index of the matching `[B,C]` pair (counting separators). So to
make `famA × famB → species S`, the pair `[codeA, codeB]` must live at **slot
S**. Each species therefore has **at most one** family-cross default (one slot
= one pair); species with no family default get a `$FFFF` separator at their
slot. Many-parent→one-result mappings are **not** expressible here — put those
in the special table (which has an explicit result byte). Verified decode:
slot 0 = Slime×Dragon→DrakSlime, slot 15 = Slime×Boss→KingSlime, slot 19 =
MetalKing×MetalKing→GoldSlime. Table is 221 slots (D 0–220), 197 matchers, 24
separators.

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

---

## Planned: Overhaul & Extension (specced Session 12, NOT yet built)

Goal: a romhack-scale rebuild keeping the existing 10 families — (1) defaults
(family×family) rewritten with entirely new results, (2) special recipes
extended to 1×–2× capacity (825 → up to ~1650) for iterative playtesting.

### Mechanism (all ROM-verified Session 12)
- **Special table — extend.** Result is an explicit byte; many→one is fine;
  first-match-wins; checked before the family table. No slack after it in bank
  $16 (`$FF` terminator at `$5B4D`, code follows), so **relocate** it (plus a
  ported scanner) into free **bank `$69`** and invoke via **`rst $10`**
  (`HL=(bank<<8)|entry`; ROM0 handler `SaveBankAndSwitch` saves/switches/
  restores ROMX — the proven custom-room far-call). One 16 KB bank holds 2×
  special (1650×5 = 8250 B) + family + scanner with ~7 KB headroom. Free banks:
  `$69–$77,$79–$7A,$7C,$7E–$7F`.
  **RELOCATION DONE (B2, Session 13, SameBoy-confirmed):** `patches/bank_069.asm`
  = `db $69` + jump table (`dw RelocatedSpecialScan`) + faithful port of the scan
  loop & per-entry check (`LoadBrd_471c`) + the special table; bank $16's scan at
  `$46F2–$470F` (30 B) is replaced in-place with `ld hl,$6900`+`rst $10`+26-byte
  NOP pad and falls into the unchanged plus-clamp at `$4710`. The `rst $10` ABI
  was decoded from ROM bytes ($0010 path): H=bank, L=entry (`<$80`); the far
  function ends `ret`, returning via $002A which restores the caller's bank. The
  relocated table is sourced from the **patched** `bank_016.asm` (not vanilla),
  so existing custom recipes survive — generated by
  `build_breeding.py --emit-relocation`, which self-checks relocated == patched.
  B3 now just grows this free-bank table (no shift limit).
- **Family table — rewrite in place.** It already spans the full species range,
  so no extension needed. Same-length rewrite in bank $16 = zero shift.
  Because result = slot index (see Step 2), the compiler must **invert** the
  author's `A×B→C` into slot order and **reject** two pairs claiming the same
  result species (positional conflict → move one to `special`). Preserve the
  `$FA` "any family" wildcard and the two-pass search.
- **Bank $16 is shift-sensitive** (embedded pointers at `$70A6+`): never
  insert. Leave the vanilla tables in place (dead, ~8.7 KB) and overwrite only
  the scan-entry region in-place (`ld hl,$6900; rst $10` + NOP pad to preserve
  byte length); fall through to the existing plus-clamp.
- Preserve plus computation, the ~1–5% mutation override (`$16:$44DA`→`$D9E6`),
  and precedence: special → family → fallback(parent 1) → mutation.

### Source-spec + compiler
Extend `tools/patch_breeding_recipe.py` into `tools/build_breeding.py`: a JSON
spec with `special` (list of `{p1,p2,min_plus,result,plus_mod}`) and
`family_defaults` (map `result_species → {p1,p2}`); names resolved via
`dwm/map_names` + `monsters_full.json`; emits bank `$69` data + scanner + the
same-size bank `$16` redirect; validations = capacity, shadow/unreachable
warnings, family positional-conflict rejection.

### Keystone prerequisite — DONE (Session 13)
A decoder↔encoder that re-emits **both vanilla tables byte-identical** to the
ROM (`build_breeding.py --selftest`) before feeding new data — the family
table's positional/separator encoding is subtle. **Built and proven (B1):**
`tools/build_breeding.py` decodes both tables from the ROM and re-encodes them
byte-identical (special $4B30 = 4126 B incl `$FF`; family $4974 = 444 B incl
`$0000`), with the `db`-text emission re-parsing to the same bytes and the
disassembly `db` bytes matching the ROM (`--check-disasm`). The decode
independently reconciles with `breeding_complete.json` (825/825 special,
197/197 family recipe-slots, 0 diffs). The faithful, name-annotated decode is
regenerated to `extracted/breeding_tables.json` (`_generator`-stamped, Tier A).
The family table is 222 pairs = 197 recipes + 24 separators + 1 terminator;
result species == slot index, confirmed for slots 0/15/19. B2-B6 build on
these decode/encode/emit primitives.

### Companion (same-size data/text edits, gated on a SameBoy check)
Family **reassignment** (bosses spread across families 0–8; slot-9 "Mecha"
collates cross-family monsters) = single-byte edits at offset $00 of each
43-byte monster info entry. **??? → "Mecha"** rename = family-name table +
flavor text (e.g. the library bookshelf "…and ???"). Before mass reassignment,
verify in SameBoy whether family 9 is special-cased outside breeding (battle
"boss-ness" likely comes from the boss table `$14:$4897`, separate from the
family byte — confirm, don't assume).

Phased plan (B1–B6) with acceptance tests lives in ROADMAP.md (Phase 2).
