# DWM1 Breeding System — Complete Technical Reference

> **Custom breeding PROVEN (v31, Session 12).** A special-recipe override —
> Anteater × BattleRex → GoldSlime — was applied as a same-size, in-place edit
> of two provably-dead table entries (zero vanilla collateral) and confirmed
> in-game in SameBoy. Tool: `tools/patch_breeding_recipe.py`; patch:
> `patches/bank_016.asm` (bank $16 now in the verifier's patch set). A
> romhack-scale overhaul + extension is specced below ("Planned: Overhaul &
> Extension").
>
> **B1/B2/B3 DONE (Sessions 13, 15).** B1: round-trip encoder
> (`tools/build_breeding.py`). B2: special scan relocated to free bank `$69` via
> `rst $10`. **B3 (Session 15): special-table capacity 1×–2×** — the bank `$69`
> table now grows past the 825 vanilla entries by appending from
> `extracted/breeding_extra_recipes.json` (cap `SPECIAL_CAPACITY_MAX = 1650`);
> BattleRex×MadCat→DracoLord at index 825 confirmed in-game. **B4 (Session 16):
> family-defaults rewrite in place** (`--emit-family`). **B5 (Session 17): full
> special-table authoring** — `build_breeding.py --emit-special` now OWNS the whole
> special table as authored data: 825 vanilla base (decoded from the ROM) + in-place
> `overrides` (edit any entry, by index or by parents) + `appends`, from
> `extracted/breeding_special.json`, with a whole-table first-match-wins shadow
> validator; bank `$16`'s special table is left byte-identical to the ROM forever
> (single source = JSON → bank `$69`). User-confirmed in SameBoy: MadCat×BattleRex→
> DracoLord (in-place edit of entry 187, was Yeti), Darkdrium×BattleRex→Armorpion
> (unshadowed append), Anteater×BattleRex→GoldSlime both orders (S12 carried forward).
> The verified ??? / family-reassignment mechanics and the user's full romhack plan
> are in "Planned" below.

## Overview

Breeding is handled in **Bank $16**. The offspring determination function `Call_016_456e` (entry 2) executes three steps in priority order:

1. **Special recipe table** at `$16:$4B30` — 825 entries × 5 bytes, checked FIRST
2. **Family recipe table** at `$16:$4974` — **222 entries** × 2-byte pair, checked
   SECOND (the table runs `$4974`–`$4B2F`, ending exactly where SpecialRecipeTable
   begins at `$4B30`; species 0–221 only)
3. **Fallback** — offspring = parent 1 (pedigree) species

### New species and the recipe tables (id ≥ 222)

`FamilyRecipeTable` is **222 entries**, so any species id ≥ 222 overshoots it. The
encyclopedia detail's "how to breed this" lookup `label16_485c` (bank `$16`
entry 1) does `FamilyRecipeTable + id*2` with **no bounds check** — for id 224 it
read `$4B34` (inside `SpecialRecipeTable`) and showed bogus breeding parents.

**Fix (current):** `label16_485c`'s 8-byte base-add block is byte-neutrally
replaced by `call FamilyRecipeResolve` + `ds 5,$00`; the resolver (bank `$16` free
space) returns a pointer to a static `$FF,$FF` ("no recipe") for id ≥ 222, else the
normal `FamilyRecipeTable` slot. New species are therefore **wild-only** and
correctly show no breeding recipe (same as vanilla unbreedable id 220).

**Can new species be made breedable later? Yes.** Two independent directions:
- *As a RESULT* (breed X+Y → new species): add an entry to `SpecialRecipeTable`.
  This table **already grows past its 825 vanilla entries by appending** (the B3
  mechanism, see below / `extracted/breeding_extra_recipes.json`), and the
  result-species decode supports ids beyond the vanilla range. This is the clean
  path and needs no in-place table edits.
- *As a PARENT / shown in its own encyclopedia recipe* (breed new species + Z):
  give id ≥ 222 a real `FamilyRecipeTable`-style pair instead of the `$FF,$FF`
  sentinel — extend the `FamilyRecipeResolve` lookup (a small per-high-id table in
  free space, same pattern as `HighLine2Ptrs` for the description). No shift risk.

Neither is done yet (Gorbunok is intentionally wild-only for now), but both are
straightforward given the resolver fork is already in place.

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
  **B3 DONE (Session 15):** capacity raised to 1×–2× by appending recipes from
  `extracted/breeding_extra_recipes.json` AFTER the 825 base entries (scanner
  walks to `$FF`, no count). `SPECIAL_CAPACITY_MAX = 1650`; bank `$69` fits with
  headroom. The emit self-check now asserts the **first 825** entries == patched
  bank_016 table (not full equality), that appended bytes are placed + `$FF`-
  terminated, and runs a **shadow check** that FAILS the build if an appended
  cross is already matched by an earlier (base) entry — i.e. a dead recipe. Proof
  recipe (index 825): `BattleRex($2A,Pedigree) × MadCat($44,Mate) → DracoLord
  ($C8)`, `min_plus 0`; user-confirmed DracoLord in SameBoy. **Order matters:**
  the forward MadCat × BattleRex is the vanilla → Yeti ($3B) recipe at index 187,
  so only the reverse (unshadowed) order demonstrates >824 capacity.
  **B5 DONE (Session 17, SameBoy-confirmed):** `build_breeding.py --emit-special`
  now OWNS the whole special table as authored data and emits it to bank `$69`.
  The base is the 825 vanilla entries decoded from the **ROM** (canonical, not the
  bank_016 mirror); `extracted/breeding_special.json` supplies in-place `overrides`
  (edit any base entry — addressed by `{"index":N}` or by `{"match":{p1,p2}}` =
  the first base entry that fires for that cross; absent fields inherit) and
  `appends` (new entries past 824, the B3 mechanism). A **whole-table
  first-match-wins shadow validator** replaces B3's append-only check: it FAILS the
  build if an append is shadowed by an earlier entry or an override is itself
  shadowed, and WARNS when an edit newly precedes a later different-result entry or
  when an override changes a result species that **other entries still produce**
  (so "edited a cross" is never mistaken for "removed a monster"). Single source of
  truth: bank `$16`'s special table stays **byte-identical to the ROM forever**
  (already runtime-dead via the B2 redirect), so nothing in the shift-sensitive bank
  moves and there is exactly one authored source + one emit target. Self-checks:
  emitted table == authored bytes + `$FF`; every non-overridden base entry ==
  vanilla; each override present at its index; capacity ≤ 1650. Proof set
  (user-confirmed): entry 187 edited in place MadCat×BattleRex → **DracoLord** (id
  200, was Yeti); appended **Darkdrium×BattleRex → Armorpion** (unshadowed — no
  vanilla special or family default for that cross); S12 Anteater×BattleRex→GoldSlime
  carried forward in both orders (overrides at the same dead entries 693/803).
  Patched ROM `c95f62ce…`; clean build still `1ca6579…`. Method + precedence:
  KEY_LESSONS "Session 17 — Breeding B5". **B5 supersedes the B3 `--emit-relocation`
  + `breeding_extra_recipes.json` path** as the canonical bank `$69` emitter; the old
  index-825 DracoLord append is replaced by the cleaner in-place entry-187 edit (the
  DracoLord result is still reachable, now via a base edit, so no confirmed
  capability is lost).
  so no extension needed. Same-length rewrite in bank $16 = zero shift.
  Because result = slot index (see Step 2), the compiler must **invert** the
  author's `A×B→C` into slot order and **reject** two pairs claiming the same
  result species (positional conflict → move one to `special`). Preserve the
  `$FA` "any family" wildcard and the two-pass search.
  **B4 DONE (Session 16, SameBoy-confirmed):** `tools/build_breeding.py --emit-family`
  reads `extracted/breeding_family_defaults.json` — a list of positional
  `{result, p1, p2}` overrides (result = offspring species id = slot; p1/p2 = a
  family name/`$F0`–`$FA`/species name|id; `$FA` mate-side only). It starts from the
  vanilla family decode, applies only the overrides, then rewrites the
  `FamilyRecipeTable` db block in `patches/bank_016.asm` IN PLACE. Validations:
  positional 1:1 (reject duplicate `result`), 444-byte zero-shift invariant, and two
  shadow classes — a SPECIAL entry that matches the same parents by family code, and a
  duplicate family-code matcher at a higher slot (family scan is last-family-wins).
  Self-checks: every untouched slot stays vanilla-identical; each override is present at
  its slot. Confirmed precedence (grepped, do not re-trust): special → family → fallback;
  within family, exact-parent-1-species returns immediately, family-code match keeps
  scanning (last wins), search runs twice (parent2 specific, then as family). Note: `$FA`
  is scanner-supported but used ZERO times in vanilla data. **Caveat surfaced in test:** a
  species-specific SPECIAL masks the family default for that exact pair regardless of the
  family edit (e.g. MadCat×BattleRex → Yeti via special 187, so Beast×Dragon→Wyvern can't
  surface through MadCat) — choose proof crosses with no special, or expect the special's
  result. Proof set (zero-collateral permutation + 1 new recipe at empty slot 37):
  Bird×Dragon→DrakSlime, Slime×Dragon→Almiraj, Beast×Dragon→Wyvern, Dragon×Dragon→GreatDrak;
  5 changed bytes; patched ROM `caa597d1…`, clean build still `1ca6579…`. See KEY_LESSONS
  "Session 16 — Breeding B4".
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

### User romhack plan + verified ??? mechanics (Session 15)

**Goal (user):** rename the **??? family ($F9) → "Spirit"**; shuffle monsters OUT
of ??? into other families and Spirit-looking monsters INTO Spirit; fundamentally
rewrite all recipes (incl. making Spirit a normally-breedable family). Monster
count stays **221** — shuffle + rename are same-size byte edits, **no table
expansion** (expansion shifts every species-ID-indexed table: both breeding
tables, enemy stats, encounters, sprites — not worth it and not needed). DWM2
sprite swaps are an independent same-size graphics job, orthogonal to this logic.

**Verified resolver (grepped S15, do not re-trust docs):** offspring =
special → family → **fallback = parent 1** (`$16` Step 4 is literally
`ld a,[$da6f]; ld [$da71],a`). The ??? family has **zero family-table defaults**
and appears as a matcher in only **2 of 825** special entries (both as the
*mate*: Slime×Boss→KingSlime idx 740, Dragon×Boss→sp$29 idx 751). So
"??? × anything → itself" is the **universal parent-1 fallback** showing through,
**not** a ???-specific rule. Implication: making Spirit breed into new things is
pure authoring (add Spirit-as-pedigree specials and/or `$F9` family defaults);
there is no special-case to dismantle.

**Family "name" = an ICON, not a string (TRACED, Session 20 — user-confirmed):**
the family identity shown to the player is **not text at all** — it is a graphical
**icon** (slime, dragon face, paw, feather, tree, insect head, hammer/axe, two
faces, "?"). It is rendered as an ordinary **font tile**:

- The 10 icons are 8×8 2bpp font tiles in **bank `$4F` at `$4110`–`$41A0`**
  (the disassembly block labeled `;mgsBox monster types`, now annotated
  `FamilyTypeIcons` with the per-byte map).
- They are addressed by **text bytes `$10`–`$19`**, via the font formula in
  `ComputeTileDataAddr` (bank `$00`): `tile_addr = $4010 + byte*16`. So byte
  `$10`→`$4110` (icon 0) … byte `$19`→`$41A0` (icon 9). The `dwm.tbl` charmap's
  commented `10=[slime] … 19=[???]` hints are exactly this, now ROM-verified.
- Both screens use the same tiles: the **Library/Encyclopedia tab strip** blits
  them, and the **monster-detail screen** prints them inline as the text sequence
  `<$F0><$1x>"family"` (an `$F0` control byte + the icon byte + the word "family").
  The per-family detail lines live in bank `$4D` (`…$F0 $10 "family"`, one per
  family, `$F0 $10`…`$F0 $18`); the breeding/library flavor sentence ("…Slimes…
  Beasts… and ???") is separate running text in bank `$1A` (`$6A46`).

So there is **no name string to edit** for a rename — `FamilyTextPtrTable`
(`$04:$60F4`) remains a red herring (it is per-family monster **dialogue**, opcode
`$2D`). The rename/add work is **graphics**: edit/add an icon tile.

**Icon order (user-confirmed S20, by VISUAL; this is glyph order $10–$19, NOT the
family-code order):** `$10` slime, `$11` dragon face, `$12` animal paw (Beast),
`$13` feather (Bird), `$14` tree (Plant), `$15` insect head (Bug), `$16` hammer/axe,
`$17` black face (Zombie), `$18` red face (Material), `$19` "?" (??? / Boss).

**11th-family (Spirit) icon — free slot found:** the tile right after the icons,
**byte `$1A` → `$41B0`**, is a blank `$ff/$00` filler (charmap "20-23 are blank");
there are ~10 free font slots there. Adding the Spirit icon is a **same-size 16-byte
tile insert, zero shift** — `patches/bank_04f.asm` does exactly this (Variant A:
"Fire Whip Spirit" art, head on palette index 0). See "Family icons (B8/B9)" below.


**Reassignment = family byte (offset $00 of each 43-byte entry `$03:$4461`).**
**B6 GATE — CLEARED in S18** (see "Family-byte reader trace (the B6 gate —
CLEARED)" below; this S15 signpost predates that and is kept only for the trace
list). The family byte is read OUTSIDE breeding — confirmed readers in bank `$01`
(battle: loads both party monsters' family), bank `$04` (FamilyTextPtrTable =
per-family monster-**dialogue** text dispatch via opcode `$2D`, display-only — NOT
the family-name string), and skill/AI banks `$07/$09/$52–$58`. The S18 trace
confirmed none gate **scout/breed eligibility or resistance/AI grouping** on
family==9: true boss-ness comes from the boss table `$14:$4897` + the enemy-stats
joinability byte (`$14 +$3`), separate from the family byte. Concrete
risk: a former boss moved out of ??? could become breedable/scoutable, and a
monster moved in could lose those. Confirm in SameBoy; don't assume.

**Phasing:** B4 (family defaults) + B5 (full special authoring incl. replace
Yeti = entry-187 result byte) are proven/low-risk and independent of the family
byte → do first. B6 (reassignment + rename) last, gated on the reader trace.

Phased plan (B1–B6) with per-part acceptance tests lives in ROADMAP.md (Phase 2B).

---

## B6 — family reassignment: VERIFIED MECHANICS (Session 18)

**Reassignment works. Monsters can be moved between ANY families** (incl. in/out
of ??? / Boss=9) via a **same-size family-byte edit** at `$03:$4461 + id*43`
(offset $00). Tool: `tools/build_family_reassign.py` (spec
`extracted/breeding_family_reassign.json`, a `{id,name,from,to}` list; `from` is
validated against the vanilla ROM; emits `patches/bank_003.asm` as an exact-line
db edit, zero shift). User-confirmed in SameBoy with 8 monsters across in/out of
??? and between ordinary families.

### Three family representations (grepped S18 — do not re-trust)
The family byte is the single source of truth, but it reaches three consumers
DIFFERENTLY, which is why a naive edit appears partly applied:

1. **Breeding match** — reads the LIVE family byte each cross (`$DA33` after the
   species load, and `$DA73/$DA74` family codes `$F0+fam`). Honors reassignment
   immediately. (Proof S18: Anteater→Plant × BattleRex→Boss hit the vanilla
   family-table default slot 108 `[Plant,Boss]→Rosevine` — a cross impossible
   before the reassignment.)
2. **Status / detail menus + name + symbol** — read the per-monster **party/
   storage struct byte at +$0A** (`$CACB` for slot 0). That byte is STAMPED from
   the live family byte at **creation time** (breed: bank `$16` ~$408x writes
   `[$DA33]`→struct +$0A; recruit/catch: bank `$14` ~$0316 same). So a monster
   obtained AFTER the patch shows the new family; monsters that predate the patch
   (or a savestate) keep the old stamped value. This is snapshot semantics, not a
   bug — correct for a fresh hack where players obtain monsters post-patch.
3. **Library / Encyclopedia tabs** — group by **species-id RANGE**, NOT the family
   byte. Routine `SetItem_6242` (`$12:$6242`) reads `LibraryFamilyTabBounds`
   (`$12:$6294`, 11 bytes `[0,20,45,70,90,110,130,155,175,200,215]`): family index
   = `wOPTN_and_Item_selection*5 + (wMenu_selection & $7F)` (2-col×5-row tab grid,
   0..9), then scans the contiguous id range `[bounds[i], bounds[i+1])`. **This is
   the ONLY id-range family assumption in the whole ROM** (audited S18: every `cp`
   against the boundary ids checked; breeding/menus key off the family byte or
   species id, never an id-range→family map).

### Family-byte reader trace (the B6 gate — CLEARED)
Confirmed readers of the family byte gate **nothing** outside display/copy:
bank `$01` battle (copies into battle struct), `$04` FamilyTextPtrTable (text
dispatch / display), `$07` farm/scout sprite+icon (display), `$09` VRAM tile
index (display), `$14` recruit (stamps struct +$0A). **Scout/recruit eligibility
is the enemy-stats joinability byte (`$14 +$3`) + boss table (`$14:$4897`),
independent of the family byte.** So reassignment cannot accidentally make a wild
monster recruitable or strip a boss's join behavior. (Annotated inline at the
bank `$03` MonsterInfoLoad header, `label443f`.)

## Dynamic library — PROOF OF CONCEPT (Session 18) → SUPERSEDED by B7 (Session 19)

The S18 POC (`tools/build_dynamic_library.py`) redirected `SetItem_6242`
(`jp LibScanByFamily`, zero-shift) to a routine in bank `$12` trailing free space
(`$7B9B+`) that scanned ALL species 0..220, read each one's family byte via the
`$0301` far-loader, and listed those matching the current tab whose "seen" bit
(`$CA94`) was set. User-confirmed in SameBoy (all 8 reassigned monsters grouped
correctly), but PROOF OF CONCEPT only: ~221 far-loads per tab-change/A-press →
visible lag (each far-load = bank switch + `id*43` multiply + 43-byte copy to read
1 byte); one scratch byte `$D470`; a `PAGE_SIZE=30` cap; and it dropped the vanilla
blank-slot semantics (it listed seen-only and compacted). It proved the family byte
is the sole grouping source. **`build_dynamic_library.py` is retained as a reference
only; the patch it produced is replaced by B7 below.**

### Why the POC lagged and vanilla didn't
Vanilla scans a CONTIGUOUS id range (cheap, no cross-bank reads) precisely because
families were id-contiguous. Arbitrary membership forces a per-species "what family
are you?" lookup, and the family byte lives in bank `$03` which the library
(executing in bank `$12` ROMX) can't page in — hence the per-species far-loader.
The cost is intrinsic to doing it AT RUNTIME — so B7 does it at BUILD time instead.

## Dynamic library → PRODUCTION (B7, Session 19, DONE, SameBoy-confirmed)

`tools/build_library_table.py` emits a build-time precomputed **family→members**
table into bank `$12` trailing free space (`$7B9B+`) and rewrites `SetItem_6242`
zero-shift (`jp LibScanByFamily`; original 82-byte body → `jp` + 79 `nop`). The
walker reads the table directly: **zero far-loads, zero scratch RAM**, vanilla
blank-slot semantics restored. User-confirmed in SameBoy (zero lag; reassigned
monsters under correct tabs). Test ROM `065943f6…`; clean build still `1ca6579…`.

**Table format** (placed in the free region, all label-based / repointable):
```
LibFamilyPtrTable:                 ; NUM_FAMILIES 2-byte pointers (one per tab)
    dw LibFamily_00 ... LibFamily_{N-1}
LibFamily_00:
    db <count>, <id>, <id>, ...    ; length-prefixed member list (species-id order)
...
```
Adding an 11th family (B9) is purely additive: one more `dw` + one more list. The
walker is family-count agnostic — the ONLY 10-bound in it is the 2×5 tab-grid →
flat-index formula (`wOPTN*5 + (wMenu_selection & $7F)`), which is the menu/UI's
concern and changes with the B9 tab UI, not the data path.

**Walker contract** (matches vanilla `SetItem_6242`): blanks the `$C0D8` buffer
(`$20` bytes) to `$FF`; for each member writes the **unseen-marker `$FE`** if its
seen-bit (`$CA94`) is clear, else the species id; stores `$C8E9` = member count
(total slots) and `$C8E8` = seen count. ROM0 helpers only (`FillNBytesWithRegA`,
`TestBitInArray`). Capacity: the emitter guarantees every family ≤ buffer capacity
(32), so no runtime overflow check is needed.

> **Unseen-marker = `$FE`, not `$E0` (Phase N change).** Vanilla used `$E0` (224) as
> the "not yet discovered" sentinel — safe only while id 224 was an empty slot. Adding
> a real species at id 224 (Gorbunok) made `$E0` collide, so `build_library_table.py`
> moves the marker to **`$FE`** (`UNSEEN_MARKER` constant; above the 224–253 new-species
> budget, with a blank name at MonsterName id 254). The marker is written in ONE place
> (the walker) and READ in two: `jr_012_6369` (skip-select a blank slot → `Jump_012_639d`)
> and `LoadItem_6544` (blank-test, returns Z). The tool rewrites all three sites together
> (`ld [hl],$fe` + 2× `cp $fe`), count-validated; if new species ever reach 254, raise
> `UNSEEN_MARKER` and re-point the name slot. `$FF` stays the buffer-fill blank.

**Source of truth (single):** family assignment = the vanilla family byte
(`$03:$4461+$00`, raw 0..9) with `breeding_family_reassign.json` overrides applied —
the SAME spec `patches/bank_003.asm` (B6) consumes. Library grouping and family
bytes therefore stay in lock-step; `from` is validated == vanilla, exactly as B6.

**New species (Phase N, ids ≥ 224):** they have no ROM info entry, so their library
family comes from `new_species.json` (cloned base family + `info.overrides.family`).
`build_library_table.py --new-species extracted/new_species.json` adds them to their
family's member list (appended after the 0..214 ids), so the encyclopedia lists them
reproducibly. This replaced an earlier hand-edit of `$e0` into the Slime list — the
data is now tool-owned (Gorbunok, id 224 = `$e0`, lists under Slime).

**Build-time validation:** `--selftest` proves the no-reassign grouping reproduces
the vanilla bounds table exactly for ids 0..214 (parity); every family ≤ 32; all
ids ≤ 255; content fits the free region. Data deliverable:
`extracted/library_grouping.json` (`_generator` stamped).

**COLLECTIBLE vs SPECIAL (user-confirmed S19 — do NOT re-derive from "looks empty"):**
ids 0..214 are the collectible monsters the encyclopedia lists. Ids 215..220 are
REAL but NON-collectible combat-only entities and are PROTECTED (excluded from the
library, never a reassignment target, never overwritten):
- 215 `TERRY?` — scripted story enemy (Durran fight); fightable, not recruitable/breedable
- 216 `Tatsu`, 217 `Diago`, 218 `Samsi`, 219 `Bazoo` — the four tiers of a summon skill
- 220 — reserved/blank, left strictly untouched

Their stats read empty (lvl cap 0, Blaze×3, no growth) only because they need no
recruit/breed/growth data. Vanilla's id-range bounds table stops at 214 for exactly
this reason. Grouping ids 0..214 by family byte == the vanilla bounds ranges (proven),
so the specials stay out the same way vanilla keeps them out.

### EXTENSION TO 255 / 11th family (design knobs, no hardcoded 221)
Species id is 1 byte → architectural ceiling 256 (ids 0..255). The only knobs in
`build_library_table.py`:
- `COLLECTIBLE_MAX` (214) — raise toward 255 as new collectible monsters are added.
- `NUM_FAMILIES` (10) — set to 11 for B9; the table format + walker need no change.
- `BUFFER_CAPACITY` (32) — the per-family display-buffer limit ($C0D8 size).
Count-expansion past 221 is a separate larger project (relocate the 221×43 monster
table via its single labeled reader `SaveMon_4446`, fill the 256-slot name pointer
table at `$41:$4339`, add enemy-stats/sprite/breeding entries, grep-and-bump the
hardcoded count loops); B7's library side is already ready for it.

### Rejected alternative (kept for the record)
A runtime 221-byte WRAM family cache removes the POC's lag but claims standing custom
WRAM solely for one menu and needs coherence. The build-time table is strictly better
on RAM, speed, and editor-alignment — so B7 replaced the POC rather than optimizing it.

## Future — 11th family (keep ??? AND add "Spirit")

Adding an 11th family is a SEPARATE, larger feature (the reassignment + dynamic
library above keep 10 families). Conceptual scope, captured so a fresh instance
knows the terrain:

- **Family code space.** Codes are `$F0`–`$F9` (10). A new family wants `$FA`, but
  `$FA` is the breeding scanner's "AnyFamily" wildcard (mate-side) — so an 11th
  family can't cleanly be `$FA`; either repurpose `$FA` (give up the wildcard,
  which has ZERO vanilla data uses) or extend the scanner's family-code range.
- **Family icon (the "name")** — TRACED S20: it is a font tile (`$4F:$4110+`,
  bytes `$10`–`$19`), NOT a string and NOT `FamilyTextPtrTable`. An 11th family's
  icon goes in the free slot at byte `$1A`/`$4F:$41B0` (same-size 16-byte tile,
  zero shift; done in `patches/bank_04f.asm` for Spirit). The detail-screen line
  is `<$F0><icon><"family">` in bank `$4D`, so an 11th family adds a `$F0 $1A
  "family"` entry there; the library tab strip blits the same tile.
- **FamilyTextPtrTable** (`$04:$60F4`, 10 entries) — add an 11th entry for the
  per-family monster-**dialogue** text group (opcode `$2D`). This is unrelated to
  the icon/name above (it was the historical red herring).
- **Library tab strip** — today a 2-col×5-row grid (10 tabs); 11 doesn't fit
  cleanly → the tab navigation (`b=5,c=10` grid in `LoadItem_4241`) + tab-strip
  graphics + a new family ICON need real layout work. With the precomputed
  grouping table done, the DATA side of an 11th family is free; the cost is UI.
- **Any family-indexed array sized to 10** must gain a slot. The dynamic library
  (POC or production) already handles family index 10 in its scan logic.

**Decision (user, S19/S20):** "Spirit" is **ADDED as an 11th family** (not a
rename-only replace of ???), then families reshuffled. So B9 is the target.

---

## Family icons (B8/B9 "name" path) — TRACED + Spirit icon half-built (Session 20)

> **CORRECTION (2026-06-19):** the Spirit icon SHIPS on font byte **$19 (`$4F:$41A0`)**,
> overwriting the vanilla ??? glyph (??? + Spirit share the whip). The S20 text in this
> section that places it on the free slot **$1A (`$41B0`)** is SUPERSEDED — $1A is blanked
> by the menu at runtime (not fill-immune). The art is the option-5 whip; it is verified
> rederivable from `extracted/family_icons.json` via `build_family_icon.py --selftest`
> (no PNG). See PROJECT_STATE (2026-06-19 block) + KEY_LESSONS "Spirit B9 Lessons".

The family identity the player sees is an **icon font tile**, fully traced this
session (see the corrected "Family name = an ICON" block above for the mechanism).
Summary for builders:

| Thing | Location |
|-------|----------|
| 10 family icon tiles | `$4F:$4110`–`$41A0`, addressed by text bytes `$10`–`$19` |
| Byte→tile formula | `ComputeTileDataAddr` (`$00`): `$4010 + byte*16` |
| Detail-screen line | `<$F0><icon $1x>"family"` per family, in bank `$4D` |
| Library tab strip | blits the same `$10`–`$19` tiles |
| Tile index→shade convention | idx 1 = menu background, idx 2/3 = ink, idx 0 = lightest (a few icons use it) |
| 11th icon slot (SHIPPED) | byte `$19` → `$4F:$41A0` (overwrites vanilla ???; $1A was not fill-immune) |
| ~~FREE slot for an 11th icon~~ (abandoned) | byte `$1A` → `$4F:$41B0` (blank; menu blanks it at runtime) |

**Spirit icon — DONE as a same-size insert (`patches/bank_04f.asm`).** User art
("Fire Whip Spirit"); encoded to a 16-byte 2bpp tile and dropped into `$41B0` (byte
`$1A`), zero shift, bank `$4F` otherwise byte-identical to vanilla. Two encodings
were built: **Variant A** (the whip "head" on palette **index 0**, the lightest
slot — shows **yellow** iff that menu's BG palette index-0 is yellow) and **Variant
B** (head on index 2, a safe mid-shade fallback). Variant A is the shipped default.
Tool: `tools/build_family_icon.py` (PNG/grid → 2bpp → patch line); data deliverable
`extracted/family_icons.json` (the 10 vanilla icon grids + the Spirit design + byte
map, `_generator` stamped).

**OPEN (next session, the rest of B9 — NOT done here):**
1. **Palette / "yellow head" is a SameBoy question.** The menu BG palette that
   colors these tiles is loaded via `LoadGBCPalettes` (`$00`) → `rst $10` bank `$17`
   entry `$03`; the actual RGB15 set + which palette index the library/detail menus
   bind to the font area was NOT chased (palette attribution is historically a
   SameBoy-verified area here — see PROJECT_STATE "Palette Index 1 Forced"). Confirm
   in SameBoy whether index 0 in that palette is yellow; if not, either switch to
   Variant B or edit the palette entry (separate same-size edit).
2. **Wiring Spirit as family 11**: the `$4D` detail line (`$F0 $1A "family"`), the
   tab-strip 11th cell (`LoadItem_4241` `b=5,c=10` grid + tab graphics), the
   family-code (`$FA` wildcard question), `NUM_FAMILIES`→11 in
   `build_library_table.py`, and the family reshuffle. None done this session.
3. **Viewing the icon now**: byte `$1A` is not referenced by any family yet, so it
   won't appear in normal play — inspect `$4F:$41B0` via SameBoy's VRAM/tile viewer
   (it pages into VRAM when any text uses byte `$1A`), or wait for the `$4D` wiring.

Method: KEY_LESSONS "Session 20 — Family icons (B8/B9 name path)".
