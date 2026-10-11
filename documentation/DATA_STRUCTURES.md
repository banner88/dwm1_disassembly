# DWM1 Data Structure Catalog

Single source of truth for every decoded ROM data structure.
Covers: exact addresses, assembly labels, byte-level field formats,
entry counts, cross-references, generator tools, and decode status.

For narrative documentation on how systems work, see the referenced docs.

---

## ROM Data Tables

### Bank $03 — Monster Info Table

| | |
|-|-|
| Address | `$03:$4461` |
| Label | Per-monster labels via generator |
| Entries | 221 × 43 bytes |
| Generator | `tools/gen_monster_db.py` |
| Documentation | `MONSTER_DATA.md` |

**Entry format (43 bytes):**

| Offset | Size | Field | Notes |
|--------|------|-------|-------|
| $00 | 1 | family | 0-9: Slime/Dragon/Beast/Flying/Plant/Bug/Devil/Zombie/Material/Boss |
| $01 | 1 | level_cap | |
| $02 | 1 | exp_table_index | → Bank $13 experience tables (0-31) |
| $03 | 1 | female_ratio | $00=0%, $01≈10%, $02=50%, $03≈84% |
| $04 | 1 | can_fly | 1=floating sprite |
| $05 | 1 | metal_body | 1=Metaly/Metabble/MetalKing only |
| $06 | 3 | base_skills | 3 × skill ID → Bank $41 SkillNamePtrTable, Bank $52 SkillFunctionTable |
| $09 | 6 | growth_indices | HP/MP/ATK/DEF/AGL/INT → Bank $13 growth curves at $6706 |
| $0F | 27 | resistances | 27 types, values 0-3. Order in `MONSTER_DATA.md` |
| $2A | 1 | tier_rank | 0=starter, 3-6=normal, 7=endgame |

**Cross-refs:** `family` → Bank $41 FamilyCodePtrTable. `base_skills` → Bank $16 UnevolvedSkillMap for inheritance.

---

### Bank $13 — Experience Tables

| | |
|-|-|
| Address | `$13:$41E6` |
| Entries | 32 × 297 bytes (99 × 3-byte LE24) |
| Generator | `tools/gen_growth_tables_db.py` |

Record[level] = cumulative EXP for that level. Level 1 always 0.
Selected by monster info byte $02.

---

### Bank $14 — Enemy Stats

| | |
|-|-|
| Address | `$14:$4C1D` |
| Label | Per-enemy labels via generator |
| Entries | 487 × 25 bytes |
| Generator | `tools/gen_enemy_stats_db.py` |

**Entry format (25 bytes):**

| Offset | Size | Field |
|--------|------|-------|
| $00 | 1 | monster_id | → Bank $03 monster info |
| $01-$03 | 3 | unknown |
| $04 | 1 | level |
| $05 | 2 | hp (LE16) |
| $07 | 2 | mp (LE16) |
| $09 | 2 | atk (LE16) |
| $0B | 2 | def (LE16) |
| $0D | 2 | agl (LE16) |
| $0F | 2 | int (LE16) |
| $11-$14 | 4 | unknown |
| $15 | 1 | skill_1 |
| $16 | 1 | skill_2 |
| $17 | 1 | skill_3 |
| $18 | 1 | $FF delimiter |

**Boss redirect table** at `$14:$4893` (`LookupBossRedirect`): 2-byte EID pairs; the FIRST pair ($0004→$01E6) is a non-boss redirect, then the **boss table proper starts at `$14:$4897`: 32 gates × 4 bytes** `[fight_eid:2][join_eid:2]` (LE). `tools/dump_boss_table.py` reads from $4897. $FFFF terminated. (DOC_AUDIT.md A.5)

---

### Bank $16 — Breeding Tables

| Table | Address | Label | Size | Notes |
|-------|---------|-------|------|-------|
| Unevolved skill map | `$16:$4874` | `UnevolvedSkillMap` | 256 bytes | skill_id → base_skill_id ($FF=uninheritable) |
| Special recipe table | `$16:$4B30` | — | 825 × 5 bytes | $FF terminated |
| Family recipe table | `$16:$4974` | — | Variable | $FFFF-separated groups |

**Special recipe entry (5 bytes):** `[parent1, parent2, min_plus, result, plus_mod]`
Parents: species ID or $F0-$F9 = family code match.

Documentation: `BREEDING_SYSTEM.md`

---

### Bank $16 — Gate Floor System

> **Full generation pipeline (how these tables are consumed end-to-end):
> GATE_GENERATION.md.** That doc covers the procedural maze grid, special-room
> substitution, content placement, tileset/depth, rendering, and damage tiles.
> The entries below are the table index.

| Table | Address | Label | Entries | Entry size |
|-------|---------|-------|---------|------------|
| Gate floor data | `$16:$70A6` | `GateFloorDataTable` | 32 | 8 bytes |
| Floor type selection 1 | `$16:$71A6` | `FloorTypeSelectionTable` | 16 | 16 bytes |
| Floor type selection 2 | `$16:$72A6` | `FloorTypeSelectionTable2` | 16 | 8 bytes |
| Floor type selection 3 | `$16:$7326` | `FloorTypeSelectionTable3` | 16 | 16 bytes (S122: 16 rows; the 17th "row" `$7426` is `MazeItemSubKind`) |
| Item sub-kind by item kind | `$16:$7426` | `MazeItemSubKind` | 16 | 1 byte (S122) |
| Floor layout data | `$16:$7436` | `FloorLayoutData` | 16 | 48 bytes (768 B; S122 — the old "1120 bytes" ran on over `MazePatterns` + `MazeNPCChance`) |
| Maze pattern floors | `$16:$7736` | `MazePatterns` (was `FloorTilePatterns`) | 21 | 16 bytes (4 × 4 cells) |
| Maze NPC chance (by contents row) | `$16:$7886` | `MazeNPCChance` | 16 | 1 byte |
| Maze cell → screen (modes 0/1) | `$16:$7896` | `MazeScreenTable` (was `FloorDataPtrTable1`) | 256 | 2 bytes [layout id, bank] (S122, GATE_GENERATION §7) |
| Maze cell → screen (mode 2) | `$16:$7A96` | `MazeScreenTableB` (was `FloorDataPtrTable2`) | 256 | 2 bytes |
| Maze pieces | `$16:$7055` | `MazePieceTable` (was `FloorTypeSortData`) | 16 + `$FF` | 4 bytes [openings, piece, weight class, 0] |
| Maze cell order | `$16:$7096` | `MazeCellOrder` (was `FloorTypeOrderTable`) | 16 | 1 byte |
| Floor damage (by type) | `$01:$5E7D` | `FloorDamageTable` | 16 | 1 byte (per-step HP dmg; class-`$0E` tiles; GATE_GENERATION.md §5.1) |

**GateFloorDataTable entry (8 bytes):**

| Offset | Field | Notes |
|--------|-------|-------|
| 0 | floor_type_1 | → FloorTypeSelectionTable index |
| 1 | floor_type_2 | → FloorTypeSelectionTable2 index |
| 2 | floor_type_3 | → FloorTypeSelectionTable3 index |
| 3 | last_floor | Floor count INCLUDING the boss floor (wLastFloor; GATE_GENERATION §7.7) |
| 4 | boss_room_map_type | → Bank $0B RoomPtrTable (wBossMapType) |
| 5 | boss_spawn_x | arrival TILE x, absolute (pixels = 16·b + 8) |
| 6 | boss_spawn_y | arrival TILE y, absolute |
| 7 | boss_tileset | depth tier 1/2/3 (wBossTileset; GATE_GENERATION §1 / §7.7) |

Readers (S115 census): only bank $16 entry 5 (`jr_016_5b72`, `jr_016_5be1`), both an
8-bit gate·8 in the original (gate n ≥ 32 reads gate n & 31). Patched: both go through
`GateRowPtr`; NEW gates 32-95 read their row from bank $76 `NewGateRows` via
`wGateRowBuf` ($D138) — GATE_GENERATION §7.8.

**Gate index → name:** 0=Beginning, 1=Villager, 2=Talisman, 3=Memories, 4=Bewilder, 6=Peace, 7=Bravery, 18=Labyrinth, 22=Ambition, 29=Arena Right, 31=Unused(99 floors).

**FloorTypeSelectionTable entries:** cumulative probability thresholds 0-100 ($64). $00=skip, $64=guaranteed. Used by `SelectFloorType` ($16:$5FC0).

---

### Bank $16 — Encounter System

| Table | Address | Label | Entries | Entry size |
|-------|---------|-------|---------|------------|
| Encounter counter | `$16:$6E3D` | `RandomEncounterCounterTable` | 50 | 4 bytes |
| Encounter rate data | `$16:$6FAB` | `EncounterRateData` | 16 | 8 bytes |
| Encounter rate modifier | `$16:$702B` | `EncounterRateModifierTable` | 8 | 1 byte |

**RandomEncounterCounterTable entry (4 bytes):** `[prn_threshold, $00, step_counter_le16]`
PRNG mod 101 compared to threshold. Range: 1100-6000 steps. Last entry $FF=catch-all.

**EncounterRateModifierTable:** `$10, $15, $20, $40, $50, $60, $70, $80`. Indexed by `wC8A9` (from Bank $01 gate floor threshold lookup).

---

### Bank $01 — Encounter Pools & Gate Thresholds

| Table | Address | Label | Notes |
|-------|---------|-------|-------|
| Gate base pool index | `$01:$6A22` | `GateBasePoolIndex` | 32 bytes, gate → pool offset |
| Gate floor breakpoint ptrs | `$01:$6A42` | `GateFloorBreakpoints` | 32 × dw, → threshold lists |
| Floor breakpoint data | `$01:$6A82` | `FloorBreakpointData` | Variable, $FF terminated |
| Encounter pool data | `$01:$6AAE` | `EncounterPoolData` | 128 × 26 bytes |
| Generator | | `tools/gen_encounter_db.py` | |

**Encounter pool entry (26 bytes) — fully decoded S103** (bank $01
`EncounterMonsterSelect` + `LoadNextDungeonFloor` + `LoadFloorAndEncounterData`,
annotated in both trees; editable as `gamedata.encounters`, PROJECT_COMPILER §2.20):

| Off | Field | Reader / meaning |
|---|---|---|
| +0 | rate code | → `wC8A9` = `EncounterRateModifierTable` index (the per-step drain) |
| +1 | — | read by no pool reader (vanilla 1-3) |
| +2..+4 | group chance codes | chance of 1 / 2 / 3 monsters → `$DA02` |
| +5..+9 | slot chance codes | chance that slot 0-4 is drawn (each monster separately) |
| +10 | 5 × EID (LE16) | `enemy_stats_id`s |
| +20..+24 | max count per slot | **not a weight**: 1 = this monster only ever comes ALONE (a first draw with 1 ends the group); otherwise the 2nd/3rd draw repeats until a slot's max ≥ its copies so far (the new one included) and ≠ 1 — so 0 = never 2nd/3rd |
| +25 | maze size | → `$C93D`, the bank $16 maze carve count (vanilla 3 / 8 / 15) |

Chance codes 0-7 are percentages via `EncounterChancePercent` ($01:$69C0 =
0, 10, 20, 30, 40, 50, 70, 100; re-sectioned S103 from 7 mis-decoded
instructions). `LookupEncounterEntry` turns the 3 (or 5) codes into running
sums at `$C0D8`; `CalcEncounterPoolIdx` draws RNG mod 100 and returns the first
entry whose sum exceeds it (a 0 % entry is never chosen; a list whose sums never
reach 100 walks past its end). Pool 0 vanilla = group `[7,0,0]` (always one
monster), slots `[3,5,2,0,0]` = Slime 30 %, Dracky 50 %, Anteater 20 %.
**Freeze measured S103 (PyBoy):** a pool that can draw 2 monsters whose first
draw has max 0 and where no slot may appear twice re-draws the 2nd monster
forever (28,257 passes, the battle never starts); every slot at max 1 is safe
(always alone). Every vanilla pool is consistent (checked over all 128).

**The draw, exactly (S114, measured — `tools/census_encounters.py`: 15,192 stub-called
battles on the ORIGINAL ROM == `editor2/core/encounters.simulate_battle`, 0 mismatches;
negative control 1,417):** `CalcEncounterPoolIdx` calls `GenerateRNG` (HL = wRNG1:wRNG2;
HL := HL·5 + $1357) and then draws **(wRNG2:wRNG1) mod 100** — L is loaded from wRNG1, H
from wRNG2 — and returns the first entry whose running sum **is 100 or ≥ the draw**
(leading 0 sums skipped; the sums are 8-bit). So the first slot with a chance also takes
draw 0 and the slot ending at 100 loses one: Slime / Dracky / Anteater 30 / 50 / 20 % are
really 31 / 50 / 19 % (the same for the 1/2/3-monster codes). (The LCG has full period, so
the 16-bit word is uniform; 65,536 mod 100 = 36 gives draws 0-35 a 1/65,536 edge.)

**Which list (S114):** see "Encounter list choice (S114)" below — in patched builds the
list a battle uses can be a project list (128+), a gate's own per-floor plan or a room's
own list, with flag variants.

---

### Encounter list choice (S114 — patched builds; ROADMAP P3.13a)

Vanilla `LoadNextDungeonFloor` (bank $01 entry $0D) is the ONE place the list number is
computed (wGateID + wCurrentFloor → `GateBasePoolIndex` + breakpoints; the floor is the
game's numbering = wCurrentFloor + 1, sub-index = how many breakpoints are ≤ it —
measured S114 for every vanilla gate floor: Gate of Villager list 1 = floors 1-2, list 2 =
floors 3-4, floor 5 = the boss; the pre-S114 `extracted/encounters.json` said "Floors 1-3"). It runs at EVERY
encounter step (bank $16 entry 8 calls `$010D` before the drain — it is what loads the
rate code into wC8A9), at floor setup (`LoadFloorAndEncounterData`, entry $0C) and when a
battle fires (`EncounterMonsterSelect`, entry $0B — also called from banks $03 / $14 / $15,
field effects that start a battle at once). Its readers re-derived
`EncounterPoolData + number·26 + offset` five times (+2 / +5 / +10 in
EncounterMonsterSelect, +20 in SaveRegsForEncounter, +25 in LoadFloorAndEncounterData);
`wEncounterPoolIndex`'s one other reader is the gold lying on depth-tier-3 gate floors
(bank $01 `$5AF8`: (number + 10) · (floor + 1) · (50-99) / 100).

**Patched (S114, all same size):** `LoadNextDungeonFloor` far-calls bank $76 entry 0
`EncResolve` (compiler-owned, PROJECT_COMPILER §2.30), which returns D = the list, E =
the floor's VALUE (always the vanilla number of the gate floor — the floor gold keeps its
value), B = a rate override ($FF = the list's own +0); a vanilla list (0-127) is then
copied from bank $01 into **`wEncListBuf` ($D11E, 26 B)**, a project list (128-255) was
copied there by bank $76; wC8A9 := B or the list's +0. The five readers read
`wEncListBuf + offset` (`ld hl` + `ld bc, $0000` — the old `Mul16x8To24` left BC = 0 and
the slot sums start from B: KEY_LESSONS S114). `EncResolve` order: (1) a CUSTOM room
(wInGateworld = 0, wMapID ≥ $6B) whose `EncRoomTable` row names a variant list → the first
variant whose flag terms hold, else its default list (the room never pins a gate: its
RoomEncTable gate byte is $FF, so it works inside a dive too); (2) otherwise the gate rule
for (wGateID, floor) — the vanilla walk on byte copies of bank $01's tables, replaced by
the gate's own plan when `GatePlanPtrs[wGateID]` has one (first variant whose flags hold →
floor runs `[last floor, list]`). A room's rate applies in either case. No RNG is drawn,
so battles roll as in vanilla. A NEW gate (32-95, S115) with no plan for a floor walks
the vanilla rule of the gate it copies (`NewGateSource`) — list and value; other numbers
≥ 32 give list 0 / value 0.

**Measured (S114):** the stub census (`tools/census_encounters.py`) — every gate floor ×
flag state + every room with encounters, list bytes / value / rate + 24 battle draws each
== the model on the ORIGINAL ROM (633 + 15,192), the example, a fixture with lists /
variants / rates (641 + 15,384), the user's project and the demo — 0 mismatches. Field,
on the user's save (demo ROM = the user's project + a room "Howling Den" behind the
GreatTree 2F Library door): its own list only (Hork / DragonKid / Golem); the keeper's YES
sets the flag → the night list (Gremlin / Spooky, a 3-group 8-7-8); rate code 7 → a
drain of 200 per step: 1,700 → 8 steps, 3,500 → 17; Gate of Beginning floors 1-2 → the
project list (DragonKid), floor 3 → the user's own list 0 (Anteater, Klamutra), with the
flag set every floor → the night list; the value (wEncounterPoolIndex) stayed 0.

---

### Shops (S117 — ROM-verified + PyBoy-measured; patched builds: ROADMAP P3.13c)

**A shop is a script opcode.** Every vanilla shopkeeper runs the same four words: text
`$0680` ("Item shop. May I help you?"), **`$FF04 $0000 $0680`** (opcode $04 =
`game_action`, handler `$04:$57A1`: `$C8EF` := type 0 = the shop, `$C8F0/1` := the text
base), text `$0682` ("Thank you. Come again!"), end. Type 0 runs bank $09's shop
machines (annotated S117 in both trees): `ShopOuterMachine` on `$C905` (0 window, 1 one
frame, 2 gold box, 3 cursor, 4 the choice — `ShopOuterStateTable` $45F7) →
`ShopMenuTable` ($46EB: BUY `$4707` / SELL `$4AEB` / QUIT `$46F1`, which also is the B
exit: `wGameState` bit 4 off, `$C905` := 0); BUY = `ShopBuyStateTable` ($470B, 11 states
on `$C906`), SELL = `ShopSellStateTable` ($4AEF, 13 states).

**The list.** BUY state 0 `ShopBuyStockFill` ($4721) says text base + 3, then fills
**`$C0D8`** (20 B cleared, the list copied up to its `$FF`) from one of five lists chosen
by the ROOM the shopkeeper stands in: **map `$50`** (the gate-floor shop room) →
`GateworldShopInventory` ($478C); any other map by **`wScreenIndex`**: 0 →
`BazaarInventory` ($476B), 2 → `StarryNightShopInventory` ($4774), 4 →
`BookstoreInventory` ($477D), anything else → `RareItemShopInventory` ($4784). Every BUY
from the menu re-runs state 0 (measured: a second BUY in one visit refills). The menu
shows 4 rows per page (`$C8E3` = page; left / right turn it), at most 20 items
(`ShopCountItems` stops at 20). Vanilla lists (price): Bazaar — Herb 8, Lovewater 80,
Antidote 10, Repellant 200, BeefJerky 20, PorkChop 80, WarpWing 100, BeastTail 400;
Starry Night — Potion 200, WorldDew 500, SageStone 1000, WorldLeaf 1000, MapHerb 70,
BookMark 100, Rib 300, MistStaff 700; Bookstore — the six books at 5000; Rare — Sirloin
1000, ShinyHarp 3000, Wind / Lava / Bolt / Snow / FireStaff 1500 / 2000 / 3000 / 4000 /
5000; gate floor — Herb, Lovewater, Antidote, MoonHerb 30, AwakeSand 50, SkyBell 50,
Laurel 80, WorldLeaf. (`extracted/gamedata_vanilla.json` tables `shop_*`.)

**Prices** live in the item records: **`ItemInfoTable` `$03:$71DA`** (44 × 12 B, index =
item id 0-43; bank $03 entry 2 copies one to `$DA62-$DA6D`) — **+$01/+$02 = the buy
price** (16-bit LE), +$00 group, +$0B bit 2 = kept after a lost battle; +$03-$0A not
decoded. The table was mgbdis fake code labelled `SpriteFrameDataTable` (DOC_AUDIT
S117); re-sectioned S117 (`tools/resection_shops.py`). **Sell price** = bank $09
`ShopSellPrice` ($4BC8): the full price in the gate-floor shop (map `$50`), a staff
(`$18-$1C`, `$25`, `$27`) price / 10, anything else price − price / 4.

**Patched (S117):** `ShopBuyStockFill`'s choice + copy ($472B-$476A, 64 B) is `ld
hl,$7700 / rst $10 / ret` + 59 nops → **bank $77 entry 0 `ShopFill`**: **`wShopID`
($D240)** ≠ 0 → list `wShopID − 1` of `ShopPtrTable` (out of range → the room rule),
else the vanilla room rule on lists 0-4 (the five vanilla lists, vanilla order); then
the same clear + copy. `wShopID` is written by a project `shop` script right before
the opcode (`write_ram wShopID, n`) and lasts the visit; the shop's close tail (after
`ShopMenuTable`, 10 B) is `ld hl,$7701 / rst $10 / ret` + 5 nops → **entry 1
`ShopClose`** (the same close + `wShopID` := 0). Every bank $09 address after the
patch is unchanged (test_compiler's address-map check). Prices = compiler region
`gd_item_info` over `ItemInfoTable`. A census of `ShopFill` (stub calls, maps $00-$6A
× screens 0-15 + custom ids) == the original's choice; schema PROJECT_COMPILER §2.32.
**S129 item sets:** `ShopFill`'s list step calls `ShopSetPick` (A = the list it picked):
`ShopSetTable` rows `[shop list, n, n × dw flag (bit 15 = must be OFF), set list]`, `$FF`
ends — the FIRST row of that list whose terms all hold (a term may be a story check, flag
`$18xx`) replaces it; the set lists follow the shop lists in `ShopPtrTable`. Read at every
BUY (PyBoy S129: the Annex stall `[$01 $07 $0D]` before the quest, `[$05 $06 $03 $1D]`
after; SM83 run in test_compiler `test_story_rom`). PROJECT_COMPILER §2.42.

**The shop screens (S117b, user: "menu glitches with background colours from custom
tiles").** Every bank $09 screen (shops, the arena class menu, the other screen effects)
is composed in WRAM — `SetFld9_4204` copies the room's tiles `$C300` (16 rows × 32) + the
HUD `$C1C0` (2 rows) to **`$C500`** (18 × 32), the windows are drawn into it
(`LoadFld9_40c9`, font / frame tiles **≥ $80**, the `$8800` block; room tiles are $00-$7F
at `$9000`) — and `LoadFld9_40fa` pushes all 18 × 32 to the BG map at `[$C909]` (the
scroll-aligned screen origin). TILE ids only: the cells keep the room's GBC attributes,
which vanilla hides because every BG colour 1 is cream; a free-colour custom room showed
its own colours in the menus. Patched: `LoadFld9_40fa` (53 B) = `ld hl,$7702 / rst $10 /
ret` + 48 nops → **bank $77 entry 2 `ScreenPush`**: the same 576 tile writes in the same
order, and — only on GBC in a custom room with a free-colour marker (the S97 r2 test) —
after each row its attributes: a tile ≥ $80 → palette 7, a room tile (rows 0-15) → its
palette from **`$C200`** (`[row·16 + col/2]`, high nibble for even columns), HUD rows' room
tiles untouched. **The dialog box after a shop:** the field dialog box goes to the TOP
(rows 0-4) when the player stands in the lower half of the screen (bank $06: player y −
scroll y ≥ $50); the shop's screens assume the BOTTOM (its close draws the box frame at
rows 13-17 and the dialog types "Thank you. Come again!" there), so the dialog's close
restored the top and left the bottom box on screen — vanilla shopkeepers never allow
that (measured S117b, PyBoy). `ShopClose` → `ShopBoxBottom`: when `[$C919]` is not the
bottom (`[$C909] + $01A0`, bank $06's wrap), the box base, the `$C100` tile backup (room
rows 13-15 from `$C300`, HUD rows from `$C1C0`) and the S97 r2 attribute save
(`wBoxAttrSave` rows 0-2 from `$C200`, `wBoxAttrMask` bits 0-2; free-colour rooms only)
are re-seated at the bottom. Checked: stub calls (test_compiler `test_screen_push_rom`) +
PyBoy on the user's save (Bazaar, a plain and a free-colour custom room: tiles and
attributes back to the room's after the dialog closes).

### Encounter Runtime Flow (verified end-to-end, June 2026)

The full chain from "player takes a step" to "wild battle starts". Every
address below was traced against ROM bytes.

**1. Per-step gating — `$0B:Jump_00b_4674` (the town/encounter discriminator).**
After the exit checker finds no exit on a step, control reaches
`Jump_00b_4674`, which compares `wMapID` against a hardcoded whitelist:
`$53` (Forest Maze), `$54–$56` (Conveyor mazes), `$57–$59` (Mazes),
`$61–$64` (sub-rooms). Match → falls to `jr_00b_46d5`; **no match → `ret`,
no encounter check this step.** This is *why towns/castle have no random
encounters*. Gate rooms (`wInGateworld != 0`) instead reach `jr_00b_46d5` via
the gate exit handler `Jump_00b_46a7`. `jr_00b_46d5` does `ld hl, $1608;
rst $10` → bank $16 entry 8.

**2. Encounter step — `$16:$6F05` (`label16_6f05`, jump-table entry 8).**
Early-outs (no encounter) on: `wGameState` bits 2/5/6 set, `$C850 != 0`, or
`$C93E` bit 1 set. Then branches on `wInGateworld`:
- non-gate: base rate `bc = $0050` for mapID `$54/$55/$56`, else `bc = $0064`.
- gate: rate from `EncounterRateData[mapID×8]`, only when player tile row
  (`[$FFAA]>>2`) is `$0C/$0D/$0E` (else `ret`).

**3. Rate + counter — `jr_016_6f62`.**
`modifier = EncounterRateModifierTable[wC8A9]` (`$10`–`$80`);
`decrement = (base_rate × modifier) / $40`. **S114:** wC8A9 is the list's rate code
(+0), reloaded by `ld hl,$010d / rst $10` (LoadNextDungeonFloor) right before this, at
every step — not a stale gate value; vanilla codes are 2-4, so a non-gate room drains
50-125 per step (measured: 100 at code 3, 200 at code 7; the old "100×16/64 = 25 per
step" assumed code 0). Subtract `decrement` from `wEncounterCounter` (`$CA39` lo /`$CA3A`
hi). No borrow → store decremented counter and `ret`. **Borrow (underflow) →
fire battle.** The counter value ≈ steps remaining (e.g. seed 100 → ~4-5 steps
at the non-gate rate).

**4. Battle fire (underflow branch).** `ld hl, $010b; rst $10` → bank $01
entry $0b = `EncounterMonsterSelect` (`label1_683e`), then `set 6, [wGameState]`
(battle-pending), `$C905 = 0`, `$DA09 = 0`. The main field loop acts on
`wGameState` bit 6 to enter battle.

**5. Pool selection — `EncounterMonsterSelect` → `LoadNextDungeonFloor`.**
`pool_index = GateBasePoolIndex[wGateID] + floor_subindex`, where
`floor_subindex` = walk `GateFloorBreakpoints[wGateID×2]`, incrementing the
sub-index while `(wCurrentFloor + 1) >= breakpoint`. Result stored to
`wEncounterPoolIndex` (`$CA38`); pool bytes fetched from
`EncounterPoolData + pool_index×26`. **So the encounter table for any battle is
fully determined by `wGateID` (`$C935`) + `wCurrentFloor` (`$C939`).** Gate 0's
breakpoint list is a lone `$FF` (catch-all) → all floors map to pool 0.

**6. Counter seeding — `SetRandomEncounterCounter` (`$16:$6E14`).** PRNG → mod
101 → `RandomEncounterCounterTable` lookup → `wEncounterCounter` (counter units
1,100-6,000, mean ≈ 3,547 — NOT steps: steps = counter / the per-step drain).
**S114 correction (grep + PyBoy):** its one caller is bank $16 entry 6
`label16_5fe4` (`call SetRandomEncounterCounter` first, THEN the `wInGateworld`
branch), and entry 6 is far-called by bank $0B Entry 0 — every room load, a
post-battle reload included, gate or not. Measured in a custom room (wInGateworld
0) on the user's save: the counter after each battle = a table value (1,700 /
1,800 / 3,500 / 4,100 …) and at entry (1,100). The old "only caller
`label16_5b4e` … never seeds when `wInGateworld = 0`" was wrong (DOC_AUDIT S114;
KEY_LESSONS S11 corrected).

Key RAM: `wGateID $C935`, `wCurrentFloor $C939`, `wEncounterPoolIndex $CA38`,
`wEncounterCounterLo/Hi $CA39/$CA3A`, `wC8A9` rate-modifier index,
`wInGateworld $C969`.

---

### Bank $0B — Room Data

| | |
|-|-|
| Address | `$0B:$4B43` |
| Label | `RoomPtrTable` |
| Entries | 107 map types × variable rooms |
| Generator | `tools/gen_room_data_db.py --apply` |
| Documentation | `ROOM_DATA_FORMAT.md`, `CROSSBANK_ROOMS.md` |

**Code section refactored:** 4 duplicated pointer-chase functions consolidated into `SharedPtrChase`. 119 bytes freed at $4ACC-$4B42. Data section pinned at $4B43 via separate SECTION directive.

**Pointer chain:** `RoomPtrTable[mapID×2]` → sub-table → `[wram_ptr:2][step_ptr:2][room_entries...]`

**Exit/NPC entry (7 bytes):** `[type, behavior, x, y, gate_id, spawn_x_off, spawn_y_off]`
Upper nibble of type: $9x=exit, $0x/$Fx=NPC. Documentation: `ROOM_DATA_FORMAT.md`, `ROUTING.md`.

---

### Bank $17 — Palette/Attribute System

| Table | Address | Label | Entries |
|-------|---------|-------|---------|
| Attr ptr table | `$17:$476F` | `AttrPtrTable` | 107 × dw |
| Per-room attr data | `$17:$483F-$5214` | `RoomAttr_*` (92 labels) | Variable |
| Gate attr table A | `$17:$5215` | `GateAttrTable_A` | 256 × 2 bytes |
| Gate attr table B | `$17:$5415` | `GateAttrTable_B` | 256 × 2 bytes |

**Per-room structure:** AttrPtrTable[mapID] → screen table (pointer pairs per screen slot) → attribute entries `[wram_addr:2] + steps × [attr_idx:1, attr_bank:1, pal_ptr:2]`.

**Per-step attribute entry (4 bytes):** `[attr_idx:1, attr_bank:1, pal_ptr:2]`
Bank $3C = primary attribute bank (239 unique maps). 89 unique palettes at $565D-$7F61.
Palette format: 32 bytes raw GBC RGB555 → WRAM $C797+ (BG) via `Call_017_46a1`.

**Parser:** `tools/analyze_bank17.py` (`--room`, `--palettes`)

---

### Bank $41 — Name & Text Tables

| Table | Address | Label | Entries | Points to |
|-------|---------|-------|---------|-----------|
| Monster name ptrs | `$41:$4339` | `MonsterNamePtrTable` | 256 × dw | `MonsterNameStrings` ($5B1F) |
| Skill name ptrs | `$41:$4539` | `SkillNamePtrTable` | 256 × dw | `SkillNameStrings` ($628E) |
| Family code ptrs | `$41:$4739` | `FamilyCodePtrTable` | 215 × dw | `FamilyCodeStrings` ($69F2) |
| Item name ptrs | `$41:$48E7` | `ItemNamePtrTable` | 44 × dw | `ItemNameStrings` ($6C78) |
| Item desc ptrs | `$41:$493F` | `ItemDescPtrTable` | 44 × dw | `ItemDescStrings` ($6DF8) |
| Personality ptrs | `$41:$4997` | `PersonalityNamePtrTable` | 27 × dw | `PersonalityNameStrings` ($7159) |
| Misc text ptrs | `$41:$49CD` | `MiscTextPtrTable` | 37 × dw | Dispatch text |
| Watabou text ptrs | `$41:$4A17` | `WatabouTextPtrTable` | 2 × dw | Dispatch text |
| Item use text ptrs | `$41:$4A1B` | `ItemUseTextPtrTable` | 48 × dw | Dispatch text |
| Spell use text ptrs | `$41:$4A7B` | `SpellUseTextPtrTable` | 12 × dw | Dispatch text |
| Generator | | `tools/gen_name_tables_db.py`, `tools/gen_bank41_remaining_db.py --apply` | |

All strings $F0 terminated. 222 valid entries (0-221); entries 222-255 point to empty.

> **Per-species text via mode×species double indirection.** Bank `$4D` (detail) and
> bank `$41` (above) each have a `$4007` mode-table read by `SaveBankAndSwitch`
> (`$00:$092F`): source = `[ [$4007 + mode*2] + id*2 ]`. The per-mode tables have
> DIFFERENT counts — bank `$4D` mode 0 (name) = 256, **mode 1 (description) = 215**;
> bank `$41` mode 5 (name) = 256, mode 7 (`FamilyCodePtrTable`) = **215**. Short
> tables overshoot for high ids (the detail-page freeze). See `TEXT_SYSTEM.md`,
> `TEXT_SYSTEM.md`, `MONSTER_DATA.md` (Species ID geography).

> **Breeding `FamilyRecipeTable`** (`$16:$4974`) is **222 entries** (0–221), ending
> at `SpecialRecipeTable` (`$16:$4B30`). Reader `label16_485c` has no bounds check;
> id ≥ 222 overshoots. Forked via `FamilyRecipeResolve` → `$FF,$FF` for new species.
> See `BREEDING_SYSTEM.md`.
Text encoding: `charmap.asm`. Control codes/DTE: `TEXT_SYSTEM.md`.

**Personality index formula:** `id = idx(Charge)*9 + idx(Cautious)*3 + idx(Mixed)` where `idx(x) = 0 if x≥$C0, 1 if $40≤x<$C0, 2 if x<$40`.

---

### Bank $52 — Skill Function Table

| | |
|-|-|
| Address | `$52:$4011` |
| Label | `SkillFunctionTable` |
| Entries | 222 valid (`$00–$DD`) × dw; ids 222–255 do not exist |
| Dispatch | `$52:$6CC7` (`ld hl, SkillFunctionTable`); the older "$4211" note was wrong — $4211 is just the first byte after the 444-byte table |
| Generator | `tools/gen_skill_records.py` (→ `skill_records.json`); legacy `gen_skill_table_db.py` over-reads to 256 |

Entries 222-255 overlap with handler code (same trick as Bank $41).
115 named handler labels (SkillBlaze, SkillSleep, etc.).
9 family checks: `CheckIsSlime` through `CheckIsMaterial` ($52:$6304-$6373).
Family codes: 0=Slime 1=Dragon 2=Beast 3=Bird 4=Plant **5=Bug** 6=Devil 7=Zombie 8=Material.
id 215 (ROM name "Sheldodge", a placeholder) is the Bug-family cut → renamed "BugCut" in
`patches/bank_041.asm`.
7 math helpers: `BCsrl3`/`2`/`1`, `HLsrl4`/`3`/`2`/`1` ($52:$6B2A-$6B43).

### Bank $07 — Skill MP Cost Table

| | |
|-|-|
| Address | `$07:$570C` (..$58C8) |
| Label | `SkillMPCostTable` (renamed S51; was the mgbdis mislabel `TilesetLookupTable`). **Re-sectioned S51**: real `dw` block with per-skill comments in both trees (`tools/resection_skill_tables.py`). |
| Format | 222 × u16 LE = MP cost to CAST; `999` ($03E7) = "All MP" (ids 50 Farewell, 102 MegaMagic) |
| Reader | `$07:$56E8` (acts as `GetSkillMPCost`; id-`$70`/Ahhh special case gated on `[$cacc]&1` picks male/female MP 1/2) |

### Bank $06 — Skill Learn-Requirement Table

| | |
|-|-|
| Address | `$06:$50E0` (..$607C) |
| Label | `SkillLearnReqTable` (annotated S44) |
| Format | 222 × 18B record |
| Record | `+0` level (u8); `+1` hp `+3` mp `+5` atk `+7` def `+9` agl `+11` int (u16 LE); `+13..17` up to 5 prereq skill ids (`$FF`=none) |

Both tables decoded/validated S44; round-trip proven by `tools/build_skill_tables.py --selftest`.
Editor source of truth: `extracted/skill_records.json` (222 records, `kind` = 155 skill /
37 item_effect ($B0–$D4) / 30 internal).

---

### Banks $0C/$0D/$0E/$0F — NPC Script Data

| Bank | Map Types | Scripts | Labels | Generator |
|------|-----------|---------|--------|-----------|
| $0C | $00–$05 (Castle, GreatTree, Bazaar, GateHub, Farm, Stable) | 129 | 452 | `tools/gen_script_banks.py --apply` |
| $0D | $06–$1F (Arena, GateTileset, CopycatRoom, MedalMan, Well, etc.) | 168 | 614 | same |
| $0E | $20–$3F (Gate entrance rooms, boss rooms for first gates) | 130 | 287 | same |
| $0F | $40–$5F (Late-game boss rooms, post-game content) | 103 | 273 | same |
| **Total** | **All 96 map types** | **530** | **1,626** | |

Documentation: `BANK04_SCRIPT_ENGINE.md`

**Data layout per bank:**

All 4 banks share identical code ($4000–$41B9). Data begins at $41BA:

| Region | Description |
|--------|-------------|
| $41BA + map_type×2 | Master pointer table (indexed by ABSOLUTE map type, not relative) |
| Per-map tables | Variable-size dw arrays: `script_id → script_data_ptr` |
| Script data | Packed sequences of dw words, one per script + branch target blocks |

**CRITICAL: Script index 0 = room entry script.** Bank $01 ($4C3D) runs
`wScriptNPCId = 0` on every room enter and screen scroll. Script pointer tables
MUST have a room entry script at index 0 (usually `dw $FFFF`). NPC scripts
start at index 1+. NPC data byte 4 (script_id) must reference 1+, never 0.

Master table indexing: the script engine reads `$41BA + $D8D3 × 2` where `$D8D3` is the raw map type. Banks $0E/$0F use offsets $40+ into the master table, not from offset 0.

**Script data word format:**

| Value | Meaning |
|-------|---------|
| `$FFxx` where xx < $64 | Script opcode (100 commands, see BANK04_SCRIPT_ENGINE.md) |
| `$FFFF` | Script end marker |
| `$4xxx`–`$7xxx` (odd-aligned) | Branch target address (label reference in assembly) |
| Other values | Text ID or opcode parameter (event flag ID, delay count, NPC index, etc.) |

**Alignment:** Script data uses odd byte alignment (scripts packed back-to-back, most start at odd addresses). The generator handles this by tracking word boundaries per-script.

**Label scheme:** `{MapName}_ScriptPtrTable`, `{MapName}_Script{NN}`, `Bank{XX}_ScriptAddr_{XXXX}` for branch targets.

**Cross-refs:** Script opcodes dispatch via bank $04's VM.

**Verified Script Opcodes (28 confirmed via SameBoy + visual trace + Session 2):**

| Opcode | Params | Name | Description |
|--------|--------|------|-------------|
| $00 | 2 | if_flag_clear | Branch if event flag NOT set (NZ = flag byte is zero) |
| $01 | 2 | if_flag_set | Branch if event flag IS set (Z = flag byte is nonzero) |
| $02 | 1 | clear_flag | Clear event flag in $D99B+ |
| $03 | 1 | set_flag | Set event flag in $D99B+ |
| $04 | 2 | game_action | **GameActionDispatch via bank $09.** $C8EF=subcommand (0=shop — every vanilla shopkeeper: `$FF04 $0000 $0680`, "Shops (S117)"), $C8F0/1 = text base. NOT give-item. Invalid indices crash. |
| $05 | 1 | trigger_battle | Set enemy in $DA03, start fight |
| $07 | 1 | init_dialog | Set dialogue mode, suppress input |
| $08 | 0 | nop | No operation (just `ret`). NOT CheckInventoryFull. |
| $09 | 1 | delay | Wait N frames (low byte) |
| $0A | 2 | npc_move_x | Instant horizontal move |
| $0B | 2 | npc_move_y | Instant vertical move |
| $0D | 3 | npc_write | Write byte to NPC buffer |
| $0E | 2 | branch_by_screen | Branch on screen index |
| $12 | 2 | **write_ram** | **Write value byte to RAM address.** Param1=addr, param2=value (low byte C written to [HL]). The wrong auto-label "ArenaGenerateBattles" was renamed `ScriptWriteRAM` in both trees (S67). |
| $15 | 3 | **check_and_branch** | **Compare [addr] to value, branch if match.** Used for YES/NO: `$FF15, $C83C, $0001, branch_target` |
| $19 | 0 | wait_movement | Pause until movement completes |
| $1A | 2 | npc_walk_x | Animated horizontal walk |
| $1B | 2 | npc_walk_y | Animated vertical walk |
| $1C | 1 | trigger_anim | Animation ($01XX=jump NPC XX) |
| $1D | 0 | lock_movement | Suppress NPC facing |
| $1E | 0 | unlock_movement | Restore NPC facing |
| $22 | 0 | begin_walk | Start walk-toward sequence |
| $2A | 1 | **give_item** | **Scan wInventory for first empty slot, write item. Needs wrapper (original uses `ret` not `jp ScriptExecContinue`).** |
| $2C | 1 | **check_inv_full** | **Branch if inventory full (20 slots used). Param = branch target.** |
| $47 | 1 | npc_buffer_write | Write to NPC RAM buffer |
| $48 | 1 | npc_hide | Hide NPC sprite |
| $49 | 1 | npc_show | Show NPC sprite |

~~All 100 opcodes decoded (0 unknowns across 5,377 commands in 530 scripts).~~
**S96: WRONG on two counts** — the table has **102** opcodes ($00-$65), and
decompile_script's parameter counts are wrong for 36 of them (its "0 unknowns"
held only because a wrong arity desynchronises the stream into other valid
opcodes). Parameter counts: **BANK04_SCRIPT_ENGINE "Parameter counts"** /
`extracted/script_param_counts.json` (handler-derived, DOC_AUDIT S96).
Full reference (names): `CUSTOM_CUTSCENES.md`.

**Player control:** Automatic. ScriptInit sets $D8D7 bit 0 (script active) →
player input suppressed. Script `end` ($FFFF) clears $D8D7 → control returns. Text IDs route through ROM0 `$0AD9` → handler banks $42–$4E → data banks $18/$1A/$1B/$1F/$21/$22/$3F. Event flags live in $D99B+ bitfield (see EVENT_FLAGS.md). NPC script_id is set in room data (Bank $0B) NPC entries.

---

### Banks $50/$57 — Personality Adjustment Tables

| Label | Address | Plan |
|-------|---------|------|
| `PersonalityRunTable` | `$50:$59B6` | Run |
| `PersonalityChargeTable` | `$57:$70A9` | Charge |
| `PersonalityMixedTable` | `$57:$70C9` | Mixed |
| `PersonalityCautiousTable` | `$57:$70E9` | Cautious |
| `PersonalityCommandTable` | `$57:$7109` | Command |

All 8 rows × 4 signed bytes: `[charge_adj, mixed_adj, cautious_adj, motivation_adj]`.
Row = `(motivation≥151 ? 4 : 0) + (level≥30 ? 3 : level≥20 ? 2 : level≥10 ? 1 : 0)`.
Fight plan makes no adjustments.

---

### Tileset Banks (14 banks)

LZSS compressed tile data with pointer tables.
Generator: `tools/gen_tileset_banks.py --apply`.
Compression: `tools/decompress_tiles.py`, `tools/compress_tiles.py`.
Renderer: `tools/render_rooms.py`.

---

### Library / family-tab menu data (bank $12)

The monster-library / family-tab menu lives in bank `$12`. mgbdis decoded its
in-bank data tables as fake instructions; Session 26 re-sectioned the directly-
referenced subset and **Session 27 finished the rest**, so the entire bank-`$12`
data is now labeled `db`/`dw` (`tools/resection_library_tables.py`, labels/comments
only — build still `1ca6579…`). All addresses are ROM-verified.

**`LibraryFamilyTabBounds` @ `$6294` — 11 bytes.** Family id-range boundaries:
`00 14 2d 46 5a 6e 82 9b af c8 d7` (= 0,20,45,70,90,110,130,155,175,200,215).
Read by `SetItem_6242`: a flat family index (column×5 + row, 0..9) selects
`entry[i]` = first species id of that family and `entry[i+1]` = one past its last;
the loop lists the *seen* species in `[start,end)`. This is **the only id-range
family assumption in the ROM** — it ignores the per-monster family byte
(`$03:$4461+$00`), so a monster reassigned to a new family (B6) still appears under
its original id-range tab unless the reader is redirected (B7 production library
table does exactly that). An 11th family (B9) needs this table (or its B7
replacement) extended.

**`LibTabColPos_564a` / `LibTabColPos_5a8e` — 3 `dw` each.** `$00a1, $00e1, $ffff`
— tab-column cursor-position words, indexed by the 0/1 column selector
(`wOPTN_and_Item_selection`) via `FuncItem_43e2` (`de = base + a*2`, reads a word);
`$ffff` terminates. Two parallel copies for two menu states.

**`LibWinLayout_*` — window-draw layout streams.** A **contiguous packed run of
29 layouts at `$710c..$7b9b`** (the bank's trailing free space begins at `$7b9b`).
Reached by `ld de,<addr>; call ReadPtrFromDE`, then drawn by the loop at `$40c3`.
Format: a 2-byte **dest-position word**, then a **tile-byte stream** where `$d8` =
newline (advance dest by `$20`) and `$d9` = terminator (`cp $d9 / ret z`); every
other byte is a literal tile written via `ld [hl+],a` (no multi-byte control
codes). Every layout is now named `LibWinLayout_<addr>` and emitted as `db`/`dw`,
so the editor can address any of them by label.

All 29 layouts are decoded to structured rows in
`extracted/library_layouts.json` (generator: `resection_library_tables.py
--dump-json`) — `{addr, pos, length, ld_de_ref, rows[]}` per layout. Of the 29,
**7 are direct `ld de,$imm` entry points** (13 reference sites, all labelized):

| Entry-point label | Addr | Bytes | Notes |
|-------|------|------|------|
| `LibWinLayout_724e` | `$724e` |  74 | std window border (`fa..fb`/`fc..fd`/`fe..ff`) |
| `LibWinLayout_7768` | `$7768` | 101 | |
| `LibWinLayout_77cd` | `$77cd` | 128 | |
| `LibWinLayout_78ab` | `$78ab` |  37 | |
| `LibWinLayout_78d0` | `$78d0` | 101 | |
| `LibWinLayout_7935` | `$7935` | 145 | |
| `LibWinLayout_79c6` | `$79c6` | 380 | full-screen 18×20 library main view; a *different* border tileset (`$01 $02..$03` top, `$04/$05` line markers). mgbdis had decorated it with fake `jr` labels (`$7a05/$7a4c/$7a7d/$7aae/$7aca`) — data bytes that look like jumps; both the `jr`s and their targets were inside the data and vanished together when the range became `db`. |

The remaining 22 layouts are part of the same packed run (e.g. parallel
sub-windows, panel variants). Their exact dispatch isn't fully traced — the `ld
de` sites only ever hit the 7 entry points above; the others are reached by menu
paths or relative draws not yet mapped — but all are byte-verified data and are
labelized for editing regardless. (S26 had converted `$710c/$71aa/$71f4`, `$759a`,
`$7b42/$7b6c`; S27 converted the two remaining contiguous gaps `$724e..$759a` and
`$75c0..$7b42`.)

**Not a data table — do not convert:** `$5605` (and similar `$6100`/`$6101`) are
reached by `ld hl,<addr>; rst $10`, i.e. **far-call descriptors** (H=bank, L=entry;
`$5605` → bank `$56` entry `$05`), NOT bank-`$12` data — 21 such descriptors remain
correctly raw. The general rule for this bank: convert `ld de`+`ReadPtrFromDE`
targets (data), leave `ld hl`+`rst $10` targets (far calls).

---

## Named Functions

### Bank $00 — Core Utilities (149 named, 466 remaining)

**Math/Comparison:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `GenerateRNG` | $12D0 | — | `wC899:wC89A = old × 5 + $1357` |
| `Mul8x8To16` | $1DBE | — | `HL = A × C` |
| `Mul16x8To24` | $1DE6 | — | `E:HL = BC × A` |
| `Div8x8` | $1DFB | 91 | `B = B // A; A = B % A` |
| `Div16x8To16` | $1E0D | — | `HL = HL // A; A = HL % A` |
| `Div24x8To16` | $1E1E | — | `HL = E:HL // A; A = E:HL % A` |
| `CmpHLvsBC` | $2F45 | — | Compare HL vs BC |
| `Div16x16To16` | $2F4B | — | `DE = HL // BC; BC = HL % BC` |
| `DivBCbyDE` | $0ABF | 7 | Repeated-subtract division: `H = BC // DE` |
| `ExtractDigit16` | $20BE | 7 | Repeated-subtract digit extraction for 16-bit |
| `SaturatingAdd16` | $2482 | — | `[HL] = min([HL]+DE, BC)` — clamped 16-bit add |
| `SaturatingSubtract16` | $2496 | — | `[HL] = max([HL]-DE, BC)` — clamped 16-bit sub |

**Monster Data Access:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `GetMonsterDataPtr` | $223B | 328 | `HL = HL + (A&$7F) × $95` — monster struct ptr |
| `GetCurrentMonsterPtr` | $2229 | 97 | Resolve context → monster struct ptr |
| `ReadMonsterByte` | $224A | 67 | Byte from current monster → A |
| `ReadMonsterWord` | $224F | 87 | Word from current monster → BC |
| `WriteMonsterWord` | $225D | 10 | Write BC to current monster struct |
| `GetActiveMonsterPtr` | $2266 | 6 | Resolve active monster ptr from party index table |
| `ReadActiveMonsterByte` | $2284 | 6 | Read byte from active monster struct |
| `ReadActiveMonsterWord` | $2289 | 5 | Read word from active monster struct → BC |
| `GetMonsterSkillData` | $22A0 | 6 | Get skill/status data for monster slot |
| `CheckMonsterSlot` | $2FA5 | 308 | Check slot A valid; CF=valid |
| `GetMonsterSlotInfo` | $2F76 | 30 | Slot lookup via CheckMonsterSlot |
| `GetMonsterSlotContext` | $2208 | 8 | Resolve monster slot for battle vs overworld |
| `MonsterStatAddContext` | $2442 | 12 | Context-aware monster stat add wrapper |
| `MonsterStatSubContext` | $2462 | 12 | Context-aware monster stat subtract wrapper |
| `MonsterStatAdd` | $2448 | 8 | Add DE to monster stat, cap at BC |
| `MonsterStatSubtract` | $2468 | 8 | Subtract DE from monster stat, floor at BC |
| `MonsterStatDecrement` | $2331 | 10 | Subtract 1 from monster stat |
| `HL_AddA_x8` | $2F6C | 270 | `HL += A × 8` |

**Battle Stat Readers:**

Six functions that read per-combatant stats from WRAM lookup tables ($DBA3-$DBF3). Each takes combatant index in A, returns stat value in HL via `IndexPtrTable`.

| Label | Address | Refs | WRAM Table | Stat |
|-------|---------|------|------------|------|
| `GetCombatantHP` | $2FE8 | 21 | $DBA3 | Current HP |
| `GetCombatantMaxHP` | $2FDA | 11 | $DBB3 | Max HP |
| `GetCombatantMP` | $2FEF | 9 | $DBC3 | Current MP |
| `GetCombatantMaxMP` | $2FE1 | 10 | $DBD3 | Max MP |
| `GetCombatantATK` | $2FCC | 14 | $DBE3 | Attack |
| `GetCombatantDEF` | $2FD3 | 20 | $DBF3 | Defense |
| `IndexPtrTable` | $2FF6 | 7 | — | `HL = [HL + A×2]` — underlying lookup |

Tables initialized by Bank $51 battle setup. Each table holds 16 bytes (up to 8 combatants × 2 bytes). HP/MaxHP and MP/MaxMP pairs start at same value; HP/MP get modified during battle.

**Gold:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `AddGold` | $2424 | 9 | **SUBTRACTS** (S109, measured): C:D:E := E:H:L, then `CompareGoldHL` does wCurrGold −= C:D:E, floor 0 (the arena fee: 3800 → 3750). Name kept (callers); was documented "Add CDE to wCurrGoldLo" |
| `CompareGold` | $241A | 5 | Compare CDE against wCurrGoldLo |

**LCD/Video:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `WaitVRAM` | $1AA6 | 119 | LCD STAT wait for VRAM access |
| `WaitDMATransfer` | $1577 | 128 | Busy-wait $DA78 == 0 |
| `WaitLCDTransfer` | $14CF | 63 | Busy-wait LCD transfer |
| `GetBGMapAddress` | $25F1 | 16 | Compute VRAM BG map addr from scroll position |
| `ApplyScrollRegisters` | $122F | 13 | Write SCX/SCY/WX/WY shadow regs to LCD |
| `ClearSTATMode` | $1264 | 10 | Clear STAT interrupt mode bits |
| `EnableLYCInterrupt` | $125D | 7 | Set STAT LYC interrupt enable |
| `SetGBCPalette` | $1688 | 64 | Set palette, GBC color mode |
| `SetViewportParams` | $164B | 7 | Store HL and HL+BC to viewport shadow regs |
| `ClearOAMBuffer` | $1417 | 7 | Clear OAM sprite buffer ($C000-$C09F) |
| `TransferSGBPacket` | $113E | 10 | SGB data packet transfer (checks wIsSGB) |
| `SetColorMode` | $1C89 | 6 | Set color mode, update SGB palette if needed |
| `LoadSGBTiles` | $10E5 | 6 | Load tile data for SGB border |
| `SGBDelay` | $10CF | 6 | SGB timing delay loop |
| `ClearPaletteBuffer` | $11BC | 6 | Clear 16-byte palette buffer at $C777 |
| `SetViewportEnd` | $1659 | 5 | Store HL to viewport end shadow regs (ff_b3/b4) |
| `WriteVRAMByte` | $1AAF | 5 | Wait STAT, write A to [HL], enable interrupts |
| `GetSpriteAddress` | $1E8D | 5 | Compute OAM sprite address from index |

**Tilemap/VRAM:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `SetupTilemapTransfer` | $096D | 114 | Store VRAM transfer source/dest |
| `SetupVRAMParams` | $097A | 56 | Store VRAM transfer params |
| `SetupVRAMCopy` | $098F | 19 | Store HL/DE as copy params |
| `Copy4Bytes` | $0C80 | 66 | Copy 4 bytes DE→HL |
| `AdjustTilemapOffset` | $0CFD | 9 | Add scroll offset to HL for tilemap |
| `TilemapNextColumn` | $0CEE | 8 | Increment L within 32-col tile row (wrapping) |
| `TilemapAdvanceColumns` | $0CE7 | 6 | Advance B columns (loop TilemapNextColumn) |
| `GetTilemapRowAddr` | $0D11 | 6 | Compute scroll-relative tilemap row address |
| `GetTilemapByte` | $0954 | 9 | Read byte from tilemap pointer, increment |
| `LookupDoublePtrTable` | $093D | 8 | 2D table lookup: A indexes row, $c823 indexes col |

**Text/Display:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `CallTextEngine` | $05B6 | 24 | Cross-bank to Bank $56 |
| `RunTextHandler` | $05F6 | 25 | Text display handler |
| `SetupTextBankSwitch` | $0632 | 8 | Set bank from $c824, enter text processing |
| `ShowTextAndWait` | $06CE | 21 | Display text box, wait for player button press |
| `HandleTextCharacter` | $07AB | — | Process text control codes |
| `ReadNextTextByte` | $0D78 | — | Read from text stream |
| `PrintNumber` | $20AD | 16 | Format/print number |
| `ConvertNumberToText` | $1FB9 | 16 | Number → text digits |
| `FormatDecimalDigits` | $0A7C | 16 | Extract digits by dividing by 1000/100/10 |
| `FormatLargeNumber` | $09C7 | 9 | Format numbers > 999 (divides by 1M/100K/10K) |
| `ExtractDigits` | $09A4 | 16 | Decimal digit extraction |
| `WriteDigitTile` | $20D3 | 8 | `Write_gfx_tile(A + $F0)` — number tile |
| `WriteBlankTile` | $20D9 | 7 | `Write_gfx_tile($E0)` — blank/space tile |
| `PrintDigit` | $20DF | 14 | Print single digit |
| `WriteByteAndTerminate` | $0AD4 | 8 | `[HL] = A; [HL+1] = $F0` — write byte + text terminator |

**Bitfield/Event Flags:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `TestBitInArray` | $267E | 15 | Test bit A in bitfield at HL; Z flag = result |
| `SetBitInArray` | $2670 | 6 | Set bit A in bitfield at HL |
| `GetBitAndMask` | $2683 | 4 | Helper: byte offset + bitmask from bit index |
| `SetEventFlag` | $26A0 | 5 | Set event flag BC in $D99B bitfield |
| `ClearEventFlag` | $26A6 | 4 | Clear event flag BC in $D99B bitfield |
| `TestEventFlag` | $26AE | 6 | Test event flag BC; Z=clear, NZ=set |
| `ComputeFlagAddress` | $26B3 | — | BC → byte addr + bitmask for event flag |

**Input:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `UpdateJoypadState` | $1364 | 10 | Read joypad with edge detection/debounce |
| `TileAtPixel` (was `WaitInputRelease`, a misnomer — S122) | $1E31 | 23 | Tile id at pixel `$FFA5-$FFA8` → `$AA`, walkable → `$A9` (GATE_GENERATION §4.3) |
| `RequestScreenUpdate` | $0609 | 34 | Set screen refresh flag |
| `UpdateOAMSprites` | $2518 | 22 | Update sprite OAM |

**SRAM:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `EnableSRAM` | $20EE | 48 | SRAM access on |
| `DisableSRAM` | $1013 | 41 | SRAM access off |
| `CopySRAMBlock` | $2184 | 7 | Enable MBC SRAM, copy BC bytes HL→DE, disable |
| `CopyFromSRAM` | $21F5 | 5 | Enable MBC SRAM, copy BC bytes DE→HL, disable |
| `SavePartyToSRAM` | $2197 | 5 | Copy party/inventory data to SRAM save area |

**Script Engine:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `RunScriptEngine` | $0B07 | 18 | Store D/E to $c822/$c823, rst $10 to bank $04 |
| `CallScriptByType` | $0B9B | 10 | Route script execution by E parameter |

**Serial/Link:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `SerialTransfer` | $1275 | 17 | Link cable transfer |
| `SetSerialByte` | $1284 | 8 | `rSB = B` — set serial byte register |

**Audio:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `SetBGM` | $1AE1 | — | Store BGM offset |
| `InitBGM` | $1AE5 | — | Full BGM init with audio setup |
| `LoadSE` | $1B30 | — | Load sound effect |
| `ProcessBGMQueue` | $1BB1 | — | Process queued BGM/SE |
| `InitAudioSystem` | $3331 | 9 | Initialize NR52, clear audio channels |
| `CheckAudioFlag` | $3A48 | 7 | Check $DE1F/$DE1C audio state flags |
| `WriteAudioRegister` | $3954 | 5 | Write A to audio I/O port indexed by C |
| `NopReturn` | $3000 | 5 | Stub — just `ret` |

### Other Banks

| Label | Bank:Address | Refs | Purpose |
|-------|-------------|------|---------|
| `LoadNextDungeonFloor` | $01:$69E1 | — | Gate floor progression |
| `CopyPlayerCoordsAndGetNextRoom` | $01:$55D7 | — | Step-trigger dispatcher (S98: runs a `$90` step-on script after a step; name kept for tools/audit_mapid_range.py) |
| `MapTypeDispatch` | $04:$71EF | — | Route to script banks $0C-$0F |
| `GetRoomDataPtr` | $0B:$4274 | — | Room data pointer lookup |
| `RoomEntry4_TalkTargetLookup` | $0B:$4332 | — | A-press target at a cell: NPC slots (`TalkScanNPCSlots` $433F via `NPCSlotAtPos` $43E5), then EXAMINE spots $8x (`TalkScanExamineSpots` $4366, `ExamineSpotMatch` $438D, facing nibble) — S98 (was `RoomEntry4_NPCMovement`) |
| `SearchStepTriggers` | $0B:$43B8 | — | STEP-ON trigger ($90) at the player's cell; entry 5 `RoomEntry5_StepTriggerLookup` $43A4 — S98 (was `SearchNPCAtFacing`) |
| `InteractEntryAtPos` | $0B:$4452 | — | Coordinate match for an interact entry ≥$80; both scans stop at the first NPC entry — S98 (was `CheckExitCoords`) |
| `ScreenEffectSay12` | $12:$441F | 82 | S126 (was `AddCursorOffset`, a misnomer): HL = a text offset + the screen effect's text base `[$C8F0]`, spoken — every menu line of the farm / Library / Namer / Medal Man; bank $0A's copy = `ScreenEffectSay0A` `$0A:$441F` (was `LoadFldA_441f`), bank $09's = `ScreenEffectSay` |
| `ScreenPush12` | $12:$40E5 | 62 | S126 (was `GetScreenPos`, a misnomer): bank $12's copy of bank $09's window push (`LoadFld9_40fa`) — now a far call to bank $77 entry 2 `ScreenPush`; bank $0A's = `ScreenPush0A` |
| `ReadPtrFromDE` | $12:$40B4 | 44 | Read 2-byte ptr from [DE] |
| `LoadEnemyStats` | $14:$4849 | — | Copy enemy stats from table |
| `LookupBossRedirect` | $14:$4869 | — | Multi-monster battle redirect |
| `SetRandomEncounterCounter` | $16:$6E14 | — | PRNG → step counter |
| `SelectFloorType` | $16:$5FC0 | — | Probability threshold selection |
| `LoadFloorDataPointer` | $16:$7033 | — | Floor data table lookup |
| `ClearSpriteBuffer` | $50:$774E | 40 | Clear sprite RAM |
| `ClearTileBuffer` | $50:$768E | 33 | Clear tile RAM |
| `LoadPaletteFromDE` | $50:$75F0 | 32 | Load palette data |
| `UpdateBattleSprites` | $50:$79B4 | 31 | Battle sprite update |
| `LoadBattleGraphics` | $50:$794C | 30 | Battle gfx init |
| `LoadArenaEnemyStats` | $50:$66D3 | — | Arena enemy setup |
| `LoadBattle` | $51:$4027 | — | Full battle init |
| `LoadEnemyStatsForBattle` | $51:$4627 | — | Enemy stat load for battle |
| `ProcessBattleTurn` | $51:$736A | 32 | Battle turn processing |
| `HL_AddA_x2` | $52:$6AB8 | 62 | `HL += A × 2` |
| `SetSkillAnimFlag` | $52:$548D | 43 | Set skill animation |
| `ApplySkillDamage` | $52:$545D | 32 | Apply damage from skill |
| `CheckSkillResistance` | $52:$54EA | 30 | Check target resistance |
| `ClearBattleAction` | $57:$45E4 | 68 | AI rule VETO: `$DD27 := $FF` (walker aborts, option cell zeroed) — S81/S82 |
| `AISatAdd_455f` | $57:$455F | 65 | Saturating 8-bit `[HL] += B`, cap $FF (AI $DD26/$DD27 accumulator writes; was mislabeled `AddBToHL16` "16-bit" — fixed S82) |

---

## Cross-Reference Map

```
Monster ID ($00-$DC)
  ├─ Bank $03:$4461  monster info (family, skills, resistances, growth)
  ├─ Bank $41:$4339  MonsterNamePtrTable → name string
  ├─ Bank $41:$4739  FamilyCodePtrTable → 2-char family code
  ├─ Bank $13:$41E6  exp_table_index → EXP curve
  └─ Bank $14:$4C1D  enemy stats entries (monster_id field)

Skill ID ($00-$DD)
  ├─ Bank $52:$4011  SkillFunctionTable → handler code
  ├─ Bank $41:$4539  SkillNamePtrTable → name string
  └─ Bank $16:$4874  UnevolvedSkillMap → base skill for inheritance

Gate ID ($00-$1F)
  ├─ Bank $16:$70A6  GateFloorDataTable → floor config, boss room
  ├─ Bank $01:$6A22  GateBasePoolIndex → encounter pool offset
  ├─ Bank $01:$6A42  GateFloorBreakpoints → floor thresholds
  └─ Bank $0B:$4B43  RoomPtrTable → room/exit/NPC data

Map Type → Room → Visuals
  ├─ Bank $0B:$4B43  RoomPtrTable → room data, exits, NPCs
  ├─ Bank $17:$476F  AttrPtrTable → palette/attribute data
  └─ Tileset banks   → LZSS compressed tile graphics

Map Type → NPC Scripts → Events
  ├─ Bank $0B NPC entries  script_id field → per-map script table index
  ├─ Bank $04:$71EF  MapTypeDispatch → route to script bank by $D8D3
  ├─ Banks $0C/$0D/$0E/$0F  master table at $41BA[$D8D3 × 2] →
  │     per-map script ptr table → script data (opcodes + text IDs)
  ├─ Bank $04  100 opcode handlers (script VM)
  ├─ ROM0 $0AD9  text ID dispatch → handler banks $42-$4E
  └─ $D99B+ bitfield  event flags (story state)

Text ID → Display
  ├─ ROM0 $0AD9  TextDispatchCascade → route by ID range
  ├─ Banks $42-$4E  text handler banks (select data bank + index)
  ├─ Banks $18/$1A/$1B/$1F/$21/$22/$3F  text data banks
  └─ Bank $41  name/item/desc string tables (direct lookup)
```

---

## Generator Tools

| Tool | Output | Bank(s) | Idempotent | Flag |
|------|--------|---------|------------|------|
| `gen_monster_db.py` | Monster info | $03 | Yes | — |
| `gen_enemy_stats_db.py` | Enemy stats | $14 | Yes | — |
| `gen_encounter_db.py` | Encounter pools | $01 | Yes | — |
| `gen_skill_table_db.py` | Skill function table | $52 | Yes | — |
| `gen_name_tables_db.py` | Monster/skill names | $41 | Yes | — |
| `gen_bank41_remaining_db.py` | Remaining Bank $41 | $41 | Yes | `--apply` |
| `gen_room_data_db.py` | Room data | $0B | Yes | `--apply` |
| `gen_tileset_banks.py` | Tileset data | 14 banks | Yes | `--apply` |
| `gen_growth_tables_db.py` | Growth/EXP tables | $13 | Yes | — |
| `gen_script_banks.py` | Script data tables | $0C/$0D/$0E/$0F | Yes | `--apply` |
| `annotate_bank052.py` | Skill handler labels | $52 | **No** | one-time |

---

### WRAM — Text Rendering State (Session 2, verified)

| Address | Size | Label | Purpose |
|---------|------|-------|---------|
| $C822 | 1 | — | Text section/page index (level 1 of pointer table) |
| $C823 | 1 | — | Text entry index within section (level 2) |
| $C824 | 1 | — | Text data bank number (async bank switching) |
| $C825 | 1 | — | Rendering state bits: 0=active, 2=waiting input, 4=inserted text |
| $C82D-$C82E | 2 | — | Text data read position (current) |
| $C831-$C832 | 2 | — | Text data base position (for $F0 reset) |
| $C83A | 1 | — | Last special control code ($FF = YES/NO active) |
| $C83C | 1 | — | **YES/NO result: 0=YES, 1=NO** |

### WRAM — Inventory ($CA51)

| | |
|-|-|
| Address | $CA51 |
| Label | `wInventory` |
| Size | 20 bytes ($CA51-$CA64) |

20 item slots. Empty slots = $00. Item IDs defined in `items.inc`.
Game initializes slots 0-7 at start. Items found go to first empty via
bank $09 function (not exposed as script opcode).

**Script item manipulation:** Use opcode $12 (WriteRAM) to write item ID
to a specific slot address. Proper "first empty slot" needs ROM0 helper (TODO).

### Bank $56 — Text Control Code Jump Table (Session 2, verified)

| | |
|-|-|
| Address | $56:$44CD (after `sub $E0` / `rst $00` at $44CB) |
| Entries | 32 × 2-byte pointers (codes $E0-$FF) |

Key handlers: $E7→$4511 (CHOICE), $EE→$45AD (NEWLINE), $EF→$4640 (PAGE),
$F0→$46FE (SECTION), $F7→$47B4 (CLEAR), $F9→$47CE (CONTINUE), $FA→$481B (WAIT),
$FF→$4855 (CHOICE2-no-flags).

---

## Decode Status

**ALL 2,404 `Call_` labels named — 0 unnamed function entry points remain.**

| Bank | Data | Code | Notes |
|------|------|------|-------|
| $00 | — | 654 named / 0 Call_ | Core engine: 396 Call_ hand-named this session |
| $01 | ✅ | 248 named / 0 Call_ | Game loop, encounters, gate data. 95 Call_ named |
| $02 | — | 44 named / 0 Call_ | Screen rendering, 6 layer flags |
| $03 | ✅ | 72 Call_ named | Monster info fully annotated |
| $04 | — | 23 Call_ named | Script VM engine |
| $05-$09 | — | All Call_ named | Field utilities, audio |
| $0A-$0B | ✅ | All Call_ named | Room data, field util |
| $0C-$0F | ✅ | Shared code | Script data: 530 scripts, 0 unknown opcodes |
| $10-$19 | Mixed | All Call_ named | Various systems |
| $13 | ✅ | — | EXP/growth tables done |
| $14 | ✅ | 11 Call_ named | Enemy stats done |
| $16 | ✅ | 50 Call_ named | Breeding + gates |
| $17 | ✅ | 18 Call_ named | Palette/attributes |
| $41 | ✅ | ✅ | 100% annotated |
| $42-$4E | ✅ headers | All Call_ named | Dialogue banks, dispatch tables |
| $50 | Partial | 131 Call_ named | Battle core |
| $51 | — | 113 Call_ named | Battle setup |
| $52 | ✅ | 190 Call_ named | Skill functions + battle helpers |
| $53-$58 | Partial | All Call_ named | Battle sub-systems |
| $55-$5F | — | All Call_ named | Battle display, field UI |
| Tilesets | ✅ | — | 14 banks LZSS tile data |
| **Total** | — | **7,881 named / 19,053 auto** | **40% named — 0 Call_ labels** |

---

## Cross-Bank Dispatch Map (rst $10)

1,028 cross-bank calls traced. Every bank's dispatch table is now documented
in the asm files as proper `db`/`dw` directives (47 banks fixed this session).
Full call data in `extracted/crossbank_calls.json`.

### Bank Role Classification (from call graph analysis)

**Core Engine (Bank $00):** 654 properly named functions, 0 Call_ remaining.
All function entry points named. ~1,200 Jump_/jr_ auto-labels remain for
internal control flow. Covers game loop, interrupts, DMA, text, audio, 
map transitions, PRNG, math, joypad.

**Overworld / Field:**
| Bank | Role | Evidence |
|------|------|----------|
| $01 | Game loop, encounters, gate data | 14 entries, called by engine+field banks |
| $02 | Screen/map rendering | 6 entries, called by engine+battle+field |
| $06 | Map state, NPC management | 7 entries, called by field banks |
| $07 | Tile/sprite loading | 4 entries; entries 1-2 called 11× each |
| $09 | Field utility | 2 entries, low call count |
| $0A | Field utility | 1 entry, called only by $09 |
| $0B | Room data + room loading | 10 entries, called by 8 banks |
| $15 | Map transition pipeline | 4 entries, called by $00 and $03 |
| $19 | Field utility | 1 entry, called only by $06 |

**Script System:**
| Bank | Role | Evidence |
|------|------|----------|
| $04 | Script VM engine | 7 entries, called by field+UI banks |
| $0C-$0F | Script data (4 map-type groups) | 3 entries each, called only by $04 |
| $10 | Script utility | 2 entries, called only by $04 |

**Data Banks (fully decoded):**
| Bank | Role | Evidence |
|------|------|----------|
| $03 | Monster info (221×43B) | 9 entries, called by 18 banks |
| $13 | EXP/growth tables | 4 entries |
| $14 | Enemy stats (487×25B) | 7 entries, called by 13 banks |
| $16 | Breeding + gates + encounters | 10 entries |
| $17 | Palette/attribute system | 14 entries, 69 calls — heavily used |
| $41 | Text/name tables | 3 entries, 50 calls — GetText/PutText/GetPutText |

**Battle System:**
| Bank | Role | Evidence |
|------|------|----------|
| $50 | Battle core / UI | 11 entries, called by battle banks + $00 |
| $51 | Battle setup / init | 19 entries, called by battle banks |
| $52 | Skill function dispatch (230 entries) | 7 used entries, called by $50/$53/$57/$58 |
| $53 | Battle sub-routines | 18 entries, called by $52/$53 |
| $54 | Battle stat tables (231 entries) | 8 used entries, monster stat lookups |
| $55 | Battle display / effects | 15 entries, called by battle+engine |
| $57 | Battle AI / personality | 9 entries, called by battle banks |
| $58 | Battle animation / effects (245 entries) | 14 used entries |

**Dialogue / Text Display Banks ($42-$4B):**
The text dispatch function at $0AEA in bank $00 routes text IDs
to banks $42-$4B via range checks. Each bank's entry 0 handles text
display; other dispatch entries are animation/rendering helpers.
Text ID passed via wram [$C823], bank ID via [$C822].

| Bank | Dispatch Entries | Animation Bank | Notes |
|------|-----------------|----------------|-------|
| $42 | 117 | $1A (158 entries) | First dialogue block |
| $43 | 147 | $1A (shared) | Castle/early game text |
| $44 | 102 | $1B (136 entries) | |
| $45 | 128 | $1F (120 entries) | |
| $46 | 148 | $1B (shared) | |
| $47 | 60 | $21 (120 entries) | |
| $48 | 112 | $1F (shared) | |
| $49 | 162 | — | |
| $4A | 293 | $22 (196 entries) | Largest dialogue block |
| $4B | 68 | $3F (11 entries) | |

**Menu/UI System:**
| Bank | Role | Evidence |
|------|------|----------|
| $56 | UI dispatch / menu router | 7 entries, called by 13 banks |
| $4C | Shared UI rendering (360 entries!) | 78 calls to entry 0 from battle+UI banks |
| $4D | Dialogue portraits / sprite data | 476 entries |
| $4E | Text rendering utility | 92 entries, called by $00 and $56 |
| $4F | Sub-UI utility | 3 entries, called only by $4E |

**Audio:**
| Bank | Role | Evidence |
|------|------|----------|
| $08 | Audio/sound engine | 3 used entries, 41 calls from 12 banks |
| $05 | Audio utility | 1 used entry, 6 calls |
| $18 | Audio data/music | 5 entries, called by $00 and $49 |

**Save/Load / Field UI:**
| Bank | Role | Evidence |
|------|------|----------|
| $59 | Save/load screens | 9 entries, called by $00/$56 |
| $5C-$5E | Field UI (2 entries each) | Called by $00 and $5F |
| $5F | Field UI router | 11 entries, called by engine+battle+field |
| $12 | Item system | 1 entry, called by $09 |

### Tileset Banks (14 banks, 100% annotated)
$23-$26, $28-$31, $37-$38: LZSS compressed tile data, 29-72 entries each.
$32-$36, $39-$3B: Tileset data with large dispatch tables (20-81 entries).
$3C-$3E: Attribute/palette map data (78-239 entries).

---

## Related Documentation

| File | Covers |
|------|--------|
| `ARCHITECTURE.md` | Bank map, RST dispatch, RAM regions, free space |
| `BANK04_SCRIPT_ENGINE.md` | Script VM: 100 opcodes, state machine, data flow |
| `QUEST_OPCODES.md` | $1F/$2C/$2D handler code analysis (arena, inventory, monster dialogue) |
| `BREEDING_SYSTEM.md` | Recipe tables, algorithm, mutation system |
| `CROSSBANK_ROOMS.md` | Custom room creation technique |
| `EVENT_FLAGS.md` | Flag bitfield, story progression flags, script commands |
| `MONSTER_DATA.md` | Monster info fields, resistance types, growth curves |
| `ROOM_DATA_FORMAT.md` | Room pointer chains, exit/NPC entry format |
| `ROUTING.md` | Room transitions, 5 code paths, spawn table |
| `TEXT_SYSTEM.md` | Charmap encoding, DTE pairs, control codes |
| `known_RAM_map.md` | Community WRAM documentation |
| `CUSTOM_CUTSCENES.md` | Custom cutscene creation guide, verified opcode reference |
| `SCRIPT_TOOLS.md` | How to use gen_script_banks.py and decompile_script.py |
| `ROUTING.md` (appendix) | First-5-minutes boot/intro SameBoy trace (merged from FIRST_5MIN_TRACE.md, 2026-06-13) |

---

## Session Progress: Jump_/jr_ Label Naming

### Bank $00 — Complete (761 labels named this session)
All 838 auto-labels (316 `Jump_000_`, 522 `jr_000_`) processed:
- **761 renamed** with descriptive names
- **77 already aliased** (had named labels at same address)
- **0 unaliased auto-labels remain**

**Key naming categories applied:**
- Interrupt handlers: VBlankSaveAF, VBlankEnableInt, VBlankProcessAudio, VBlankFinish, VBlankReturn, VBlankReentry
- Boot/Init: AfterGBCInit, InitSGBBorders, InitDisplayAndRun, MainWaitLoop, ExitWaitReinit
- Screen update system: WaitScreenUpdateDone, SetArrowTiles, DrawTextArrow, ClearTextBitsRedraw, FillTilemapRowLoop
- Text engine: LoadTextPointerHL, CopyDEtoHLByte, CheckTextTerminator, AdvanceTextPointer, HandleControlCode, RestoreBankAndReturn
- Sprite/OAM processing: SpriteCheckYBounds, SpriteWriteYCoord, SpriteFlippedWriteX, SpriteGBCMode (and 30+ related)
- Number formatting: ExtractHundredsDigit, WriteThousandsDigit, DivBCbyDELoop, FormatMillions
- Text dispatch cascade: DispatchBank42Rst through DispatchBank4E (10 labels)
- Palette/fade system: SetFadeOutSGB, FadeInStepDMG, FadeOutStepSGB, FadeDone (20+ labels)
- Audio engine: 100+ labels for note processing, channel management, frequency calculation
- Math utilities: Div8Loop/Subtract/NextBit, Div16Loop, Div24Loop, MulShiftBit1-4
- Joypad: ReadJoypadDMG, CheckAutoRepeat, SetNewJoypadState, ClearJoypad2State
- Monster data: ComputeMonsterOffset, SubtractFromMonster, CheckBattleContext
- Stat operations: SatAddCapBC, ClampedAddLow, SetMinValue1
- SRAM: EnableSRAMAccess, SavePartyData, CopySRAMLoop, CopyFromSRAMLoop
- Data tables ($26D6-$2B5F): Labeled as DataLookup_XXXX / Data_XXXX (misassembled — conversion to db/dw is Priority 3)
- Audio wave data ($3200-$33FF): Labeled as AudioWave_XXXX / AudioWaveEntry_XXXX (misassembled)

**Cross-bank impact:** 197 labels in bank $00 are referenced from other banks. All renames applied across all 105 bank files.

### Overall Project Status After This Work
- Bank $00: **0** unaliased auto-labels remaining (was 838) — 761 renamed
- Bank $04: **0** unaliased auto-labels remaining (was 253) — 253 renamed  
- Project total: ~18,039 auto-labels remaining (was 19,053)
- Dynamic repointing: **34 of 36** hardcoded address patterns converted to LOW/HIGH(Label)
- Cross-bank references: **944** `ld reg, $XXXX` → `ld reg, Label` conversions
- RoomPtrTable: **fully label-based** (gen_room_data_db.py modified)
- New data table labels: **19** (see SESSION_HANDOFF.md for full list)
- SpecialRecipeTable ($16:$4B30): label created for breeding special recipes

---

## Dynamic Repointing Status (Critical for Editor)

### What This Means
When a pointer table uses **labels** (`dw RoomSub_Castle`) instead of **hardcoded addresses** (`dw $4C13`), the assembler automatically resolves pointers when data moves. This is what makes it possible to add/remove/reorder data and rebuild a working ROM.

### Fully Repointable Systems (label-based pointers) ✓

| System | Bank | Tables | Status |
|--------|------|--------|--------|
| **Scripts** | $0C-$0F | Master tables, per-map tables, branch targets | ✓ Already labeled |
| **Room data** | $0B | RoomPtrTable (107 entries) | ✓ **FIXED this session** — gen_room_data_db.py modified |
| **Monster names** | $41 | MonsterNamePtrTable (256 entries) | ✓ Already labeled |
| **Skill names** | $41 | SkillNamePtrTable (256 entries) | ✓ Already labeled |
| **Item/desc names** | $41 | ItemNamePtrTable, ItemDescPtrTable | ✓ Already labeled |
| **Skill functions** | $52 | SkillFunctionTable (222 entries) | ✓ Already labeled |
| **Palette attributes** | $17 | AttrPtrTable (107 entries) | ✓ Already labeled |

### Hardcoded Offset Calculations Fixed This Session

These `add LOW_BYTE / adc HIGH_BYTE` patterns compute table addresses at runtime.
Each was converted to `add LOW(Label) / adc HIGH(Label)` so the table can move.

| Bank | Address | Label | Purpose |
|------|---------|-------|---------|
| $03 | $4461 | `MonsterInfoTable` | Monster info (221×43B) |
| $14 | $4C1D | `EnemyStatsTable` | Enemy stats (487×25B) |
| $13 | $41E6 | `ExpCurveTables` | EXP curves (32×99×3B) |
| $13 | $6706 | `StatGrowthTables` | Growth curves (32×99×1B) |
| $01 | $6AAE | `EncounterPoolData` | Encounter pools (128×26B) — 6 refs fixed |
| $16 | $7436 | `FloorLayoutData` | Item sub-kind odds, 16 × 48 B (S122; was "1120B") — 2 refs fixed |
| $16 | $4974 | `FamilyRecipeTable` | Breeding family recipes — label created + 2 refs fixed |
| $16 | $7736 | `MazePatterns` (was `FloorTilePatterns`, S122) | 21 ready-made 4 × 4 maze grids — label created |
| $08 | $447E | `label8_447e` | Audio instrument data |

### Remaining Hardcoded Offset References (2 total — need Priority 3 data conversion)

These still use `add $XX / adc $YY` with raw bytes. Each needs a label at the target
address and conversion to `LOW(Label)/HIGH(Label)`. Many targets fall mid-line in
`db` data, requiring line splitting. **Both are latent**: their banks are not currently
patched, so they cannot break today — but they will break the instant a patch shifts
their bank. Resolve proactively before editing banks $08 / $32.

| Bank | Target | Issue |
|------|--------|-------|
| $08 | $7751 | Audio waveform data — misassembled as instructions |
| $32 | $5A5F | Tile animation data — misassembled as instructions |

**Fixed 2026-06-18:** `$0B:$4974` (sprite pointer table) and `$0B:$42c8`/`$4308` (gate
pointer table) labelized — this closed the breeding-cutscene + gate glitches in the custom
ROM. Done in the disassembly first (build remains byte-identical to vanilla `1ca657…`), then
ported to `patches/bank_00b.asm`. In the patch the sprite ref had also been **mislabeled**
to `RoomScreenPtrTable` (`$49b5`) instead of the real `$4974` data (`$4911`) — repointed to
the correct table. Method + rule: KEY_LESSONS "Session 14 Lessons — Bank $0B repointing"; the `disassembly/bank_00b.asm` gate/sprite diff is a worked re-sectioning example.

**All other 19 targets from the original 22 have been fixed** with proper labels
and LOW/HIGH conversions. New labels created: NPCWalkDataTable, ScreenTransDataTable,
SpriteFrameDataTable (S117: really the item records — `ItemInfoTable`, "Shops (S117)"), MapNPCPosDataTable, SkillMPCostTable (×3, renamed S51), TileRefLookupTable,
FieldPtrLookupTable, ItemSlotPtrTable, EnemyGroupTable, TransitionLookupTable,
RoomAttrDataBlocks, PaletteColorData, AttrMapData, AttrMapDataB, TextDataPtrLookup,
EnemyDupConvFlagTable_41df (ex-BattleHPLookupTable, S85), SaveSlotPtrTable.

> ⚠️ **Correction (S44; renamed S51 → `SkillMPCostTable`):** the old `TilesetLookupTable` label at $07:$570C was a **mislabel** — the data
> is the `SkillMPCostTable` (222 × u16 LE; see the "Bank $07 — Skill MP Cost Table" entry
> above and DOC_AUDIT A.13). All three "×3" references are battle action-cost reads
> (keyed off `wPLAN_selection`/`wOPTN_and_Item_selection`), not tileset lookups. The label
> and its reader `$56E8` are pending a SameBoy-confirmed rename + `dw` re-section.

### Modified Generator Tool

`gen_room_data_db.py` now outputs label-based pointers in `RoomPtrTable`:
- Non-overlapping sub-tables: `dw RoomSub_Castle` instead of `dw $4C13`
- Overlapping sub-table (Castle): inline label at overlap position
- All 92 unique room data blocks are now label-referenced
- Rebuild with `python3 tools/gen_room_data_db.py > output.asm` and replace data section


---

## Opcode $2A (GiveItem) — Working Logic, Broken Flow

Handler at `$04:$5FDB` correctly scans `wInventory` for first `$00`/`$FF` slot
and writes item. Original uses `ret` not `jp ScriptExecContinue`, freezing scripts.

**Fix (proven):** Redirect jump table entry to wrapper in padding:
```asm
GiveItemWrapper:
    call ScriptCmd2A_GiveItem         ; original handler (ret returns here)
    jp Jump_004_55f5         ; ScriptExecContinue
```
Zero insertion. Use with `$FF2C` (CheckInvFull) before `$FF2A` for full pattern.

(Merged from SESSION2_CUSTOM_CONTENT.md, 2026-06-13.)

---

## Region portability — the German build (SGB Enhanced), AUDITED S76

MD5 `08bca718c62e3c2870a2df107fc0a562` (2 MB, MBC5+RAM+BATT, CGB+SGB, header and
global checksums valid). 57 of 128 banks are byte-identical to the English build.

**Every mechanical data table is at the SAME flat offset with IDENTICAL contents**
except the two in bank `$14`, which are shifted by exactly `+$70` (German text
expanded the code region ahead of them):

| Table | English | German |
|---|---|---|
| MonsterInfoTable 221×43 | `$03:$4461` | same |
| EncounterPoolData 128×26 | `$01:$6AAE` | same |
| SpecialRecipeTable 825×5 | `$16:$4B30` | same (whole bank identical) |
| FamilyRecipeTable 222×2 | `$16:$4974` | same |
| Exp curves / growth curves | `$13:$41E6` / `$13:$6706` | same (whole bank identical) |
| SkillLearnReqTable 218×18 ($00-$D9; S100 — rows $DA-$DD read bank $06 FieldStateDispatch code) | `$06:$50E0` | same |
| SkillMPCost / FnTable / RecordData | `$07:$570C` / `$52:$4011` / `$54:$41CF` | same |
| Arena sprites, Mimic, RandScaled, Coliseum bands | bank `$04` | same |
| **EnemyStatsTable 487×25** | `$14:$4C1D` | **`$14:$4C8D` (+$70)** |
| **BossRedirectTable 34×4** | `$14:$4893` | **`$14:$4903` (+$70)** |

The `+$70` shift was confirmed three ways: a 12,175-byte exact content match at
the shifted offset, the 136-byte redirect match, and bank `$14`'s `rst $10`
entry-jump words all offset by `$70` (`$4849`→`$48B9`, `$4869`→`$48D9`,
`$7BAC`→`$7C1C`, `$7D12`→`$7D82`).

**Boss trigger EIDs are region-independent.** Script tokens in banks `$0C`-`$0F`
are 2-byte pairs — `<opcode> $FF` followed by the 16-bit LE operand — and every
boss EID from the S67 census occurs the same number of times in both builds
(`randomizer/logic.py::validate_boss_eids`).

### What DOES differ

Text and name tables. Notably the pointer-table bases move by −2 in German
(monster names `$41:$4339`→`$41:$4337`, skill names `$41:$4539`→`$41:$4537`), so
a tool should locate them by scoring candidates rather than hardcoding.

German re-uses five single-byte charmap slots the English font spends on
punctuation, and uses **no DTE bytes at all** in names:

| Byte | German | English |
|---|---|---|
| `$5B` | ä | (undefined — clean region tell) |
| `$5C` | ö | apostrophe |
| `$5D` | ü | `<right>` |
| `$5E` | ß | comma |
| `$64` | space | `?` |
| `$9C` | hyphen | (DTE) |

Derived by decoding known names: `Z<5D>ngler` = Züngler (Tonguella),
`K<5D><5E>chen` = Küßchen (Lipsy), `D<5B>mon` = Dämon, `L<5C>wenhals` =
Löwenhals, `MP<9C>Klau` = MP-Klau, `K<5C>nig<64>Leo` = König Leo.

### Rule for region-portable tools

Locate bank-`$14` tables by **content signature**, not by hardcoded offset — the
25-byte all-zero EID 0 row plus the invariant head of EID 1 anchors it, and
deliberately excludes EID 1's species byte so the locator still works on an
already-edited ROM. `randomizer/romdata.py::RomLayout` does this, with an MD5
fast path for the two known builds and structural sanity checks that fail loudly
on an unrecognised image.

## Service screens — script op `$04` (S126, code-read + PyBoy)

`$04 <type> <text base>` sets `$C8EF` = type, `$C8F0/$C8F1` = the base, bit 4 of
wGameState, and the type's handler runs every frame from bank $09 `ScreenEffectTable09`
(per-bank tables in $0A / $12 for their types) with its state in `$C905`; the handler
clears bit 4 at its close. Lines = base + offset (block sizes and the speaking NPCs in
`extracted/service_lines.json`; PROJECT_COMPILER §2.39 table).

**Medal rewards** (`MedalRewardTable`, `$12:$6D29` in the original, 4 rows × 4 bytes +
`$FFFF` end): `dw medals_needed, dw EID` — 13 / ZapBird (336), 18 / Trumpeter (337), 25 /
Spikerous (339), 30 / Metabble (340). Indexed by the eggs given `[$D9E1]` (`cp $04` at
`$6B5D`, `$6B92`, `$6CC0` = the count), the medals brought in all at `$C903/$C904` (capped
999 at `$6B4B`), each reward sets flag `$0050 + [$D9E1]`. The egg is built by bank $14
entry 2 from the EID's enemy row. Reward line n = text base + 2 + n (`$0723`..`$0726`;
`$072A`, `$0727-$0729` the count / "exceeded" lines). S126: the table and the count are
the region `gd_medal_rewards` (`MEDAL_REWARD_COUNT`); the old bytes stay, unread.

**Breeding screens (S127, bank $0A):** type 5 a master's own monster (`label442d`, base
`$0600`, 10 lines; the mate = enemy row `$C8F7/8`, set by op `$42`), type 6 Grandpa's
BREED / HATCH / EXIT (`label4bc3`, base `$06F0`, 32 lines; +13 / +22 are spoken by the
ceremony), type 11 "Take … with you now?" (`label6966`), type 15 naming. Types 5 / 6 set
`$FFD4` = `$78` / `$40` and draw into BG tile slots `$40-$7F`; the confirms warp to the
ceremony map $08 with `$D951` = 4 / 0 (BANK04_SCRIPT_ENGINE "Breeding"). Patched builds:
the three close tails call bank $77 `BreedClose` (PROJECT_COMPILER §2.40). Line blocks in
`extracted/service_lines.json` (kinds `grandpa`, `breeder`).

**NPC sprite sheets and the windowed screens (S141):** the windowed screens (the shop, the Vault,
the farm, the egg appraiser, the namer, Grandpa / a master / "Take…") load
their window tiles to VRAM bank 0 `$8800+` — where a room's NPC sheets 3-5 sit — and only the full
screens call bank $06 entry 4 `ReloadNPCSheets` at the close. Patched builds keep a custom room's
sheets 3-5 in VRAM bank 1 (bank $77 entries 12-15; PROJECT_COMPILER §2.40 "S141").

**Breeding pools (patched builds, bank $77 `BreedPoolPtrs`):** per pool `db mask (1 level,
2 arena, 4 seen, 8 story), story step, milestones n` + `dw flag × n` + `db bands` + per
band `db level, arena × 12, seen / 2, story × step, mates n, total weight` + per mate `dw
enemy row, db weight` (PROJECT_COMPILER §2.40).

