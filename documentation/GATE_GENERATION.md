# Gate Floor Generation — Technical Reference

> **Scope.** How a gate (portal dungeon) builds each floor: the procedural maze,
> the special-room substitutions, item/master placement, tileset/depth selection,
> and rendering. Distinguishes the **truly procedural standard floors** from the
> **fixed special/boss rooms**. Last verified against the ROM: Session 39
> (palette derivation + the `$28`/`$0D` maze tileset arrangement, §7.1–7.3);
> **S122: the whole standard-floor builder (§4, §5) and how a cell is drawn (§7)
> traced, modelled (`editor2/core/maze.py`) and PROVED in PyBoy (`tools/census_maze.py`:
> 4,000 forced floors, every field equal; 64 arrival screens pixel-equal), the
> 16 floor looks usable as "gate themes" in custom rooms (§7.10).**
>
> Companion docs:
> - `ROOM_DATA_FORMAT.md` — the static room/screen/step-entry format (bank `$0B`).
> - `CROSSBANK_ROOMS.md` — custom rooms, the `GateAwareDispatch` routing, and the
>   proven random-encounter-in-custom-room work (gate/floor pinning).
> - `DATA_STRUCTURES.md` — table-of-tables index (gate floor / encounter tables).
>
> **Confidence key:** ✅ confirmed against ROM bytes/code · 🟡 mechanism understood,
> some detail unverified · ❓ open / not yet traced.

---

## 0. The two kinds of floor

A gate floor is one of:

1. **Standard procedural floor** ✅ — a maze built at runtime into a 4×4 screen
   grid (`$C940`). Variable screens, variable connectivity, a randomly-placed
   down-staircase, random ground items, occasionally a wandering master. This is
   the common case and the FAQ's "the floors are random… it's a maze."
2. **Special room** ✅ — a *fixed*, pre-authored bank-`$0B` template substituted
   for the whole floor (e.g. priest/save room, treasure room, forest maze,
   conveyor maze). Selected occasionally instead of generating a maze.
3. **Boss floor** ✅ — the gate's final floor (`wCurrentFloor+1 == last_floor`),
   a fixed boss room from `GateFloorDataTable`.

Which one you get is decided in **bank `$16`, entry 5** (`label16_5B4E`,
`$16:$5B4E`) when you descend to a new floor.

---

## 1. Per-gate configuration — `GateFloorDataTable` ✅

`$16:$70A6`, **32 entries × 8 bytes**, indexed by `wGateID` (`$C935`).

| Off | Field | Meaning |
|-----|-------|---------|
| 0 | `floor_type_1` | index into `FloorTypeSelectionTable`  → the **maze biome/shape** roll |
| 1 | `floor_type_2` | index into `FloorTypeSelectionTable2` → the **special-room** roll |
| 2 | `floor_type_3` | index into `FloorTypeSelectionTable3` → the **contents** roll |
| 3 | `last_floor` | floor count before the boss floor |
| 4 | `boss_map_type` | bank `$0B` map type for the boss room |
| 5 | `boss_spawn_x` | boss-room spawn X (nibble-packed, see §6) |
| 6 | `boss_spawn_y` | boss-room spawn Y |
| 7 | `boss_tileset` | **depth tier 1/2/3** — drives tileset *and* item tier (§5) |

The loader at `$16:$5B72` copies bytes 0–2 → `wFloorType1/2/3` (`$C936-$C938`),
byte 3 → `wLastFloor` (`$C93A`), byte 4 → `wBossMapType` (`$C93B`), byte 7 →
`wBossTileset` (`$C93C`).

**Byte 7 is a depth indicator, not a literal tileset id** — only values `$01`,
`$02`, `$03` appear (early/mid/late gates). It selects the ground-item tier in
bank `$01` (§5) and the floor's visual tier.

---

## 2. Floor-type roll — `SelectFloorType` ✅

`$16:$5FC0`. The single weighting primitive used by all three selection stages.

```
roll  = RNG16 mod 100                  ; GenerateRNG → wRNG1/wRNG2, Div16x8To16
walk the 16-byte threshold row:
  skip entries == $00
  return the index whose entry == $64 (guaranteed) OR > roll  (cumulative)
```

It returns an **index** (0–15), not the table value. Each of the three
`FloorTypeSelectionTable`s is a set of cumulative-probability rows (percent,
`$00`=skip, `$64`=guaranteed):

| Table | Address | Rows × width | Selected by | Drives |
|-------|---------|--------------|-------------|--------|
| `FloorTypeSelectionTable`  | `$16:$71A6` | 16 × 16 | `wFloorType1` | maze biome/shape |
| `FloorTypeSelectionTable2` | `$16:$72A6` | 16 × 8  | `wFloorType2` | special-room pick |
| `FloorTypeSelectionTable3` | `$16:$7326` | 17 × 16 | `wFloorType3` | contents placement |

These three tables are **pure data, same-size editable** — the primary knobs for
re-weighting what a gate produces.

**S120 — what the indices mean (read + measured; `tools/census_gate_floor_types.py` →
`extracted/gate_floor_types/`).** Table 1 rolls the **maze floor type 0-15** = `wMapID`
inside the dive (tileset via `$00:$2A5D`, palette `$17:$51F5`); the census forces each
type with a code hook after the maze path's `SelectFloorType` ($16:$5BD2, `A` := type)
on a new game, gate 1 floor 1, and keeps a picture of each (16 distinct looks: grass,
grey rock, sand, red rock, ice blocks, purple brick ×2, yellow brick, boulders, forest,
yellow + tile floor, two mountain greens, sea + islands ×2, snow). Vanilla gates use
rows 0-15 of table 1 in order of depth (row 0 = gate 0 only = type 13; row 15 = gate 31).
**The special picks** — table 2's index → `SpecialRoomTable` ($16:$5C32, labelled S120):
0 `SpecialRoom0_Treasure` (map $5A / $5B / $5C by wRNG1 mod 3; the 8 chests $D9CF-$D9D6
from `FloorLayoutData[wFloorType3 · 48]` via `SetBrd_6db0`); 1 `SpecialRoom1_OneRareChest`
(same rooms; all chests empty but one of the first four, an item of the 16 at `$16:$6E04`);
2 Forest maze $53; 3 Priest $51; 4 Item shop $50; 5 `SpecialRoom5_Coliseum` $52 (three
teams rolled into $D9D1-$D9DA first); 6 Maze 1/2/3 $57-$59; 7 Conveyor maze 1/2/3
$54-$56 (`dwm/map_names`). Table 3 (contents) rows roll feature types 0 / 7 / 8 (not
named further here). **Per gate** (PROJECT_COMPILER §2.17 "S120"): `maze_row` /
`special_row` / `contents_row` / `depth` pick bytes 0-2 / 7 — measured: gate 5 with
`maze_row` 0 rolled type 13 on every floor-1 entry tried.

---

## 3. Branch decision (standard vs special) ✅

After loading config (`$16:$5B72`), per non-boss floor:

```
if wCurrentFloor+1 == last_floor → BOSS floor   ($16:$5BE1): load boss room + spawn
else:
   [S41/S100 patched tree: GateDecisionFork — custom rooms, §7.6]
   if wGateID != 0  AND  wRNG1 bit4  AND  (wCurrentFloor mod 3 == 2):
        → SPECIAL-ROOM path   ($16:$5C1C)
   else:
        → STANDARD maze path  ($16:$5BBF):
            wFloorType1 = SelectFloorType(FloorTypeSelectionTable[wFloorType1])
            wMapID      = wFloorType1
            wInGateworld = 1          ; engine treats wMapID as a generated maze
```

So gate 0 (Gate of Beginning) **never** takes the special path, and special rooms
appear **only on floors 3, 6, 9 …** (1-based; `wCurrentFloor` = floor − 1), about
half the time (wRNG1 bit 4). ✅ **CORRECTED S100** (was "RNG mod 3 == 2"): the
test is `ld a,$03 / call Div8x8 / cp $02`, and `Div8x8` divides **B** — loaded
with `wCurrentFloor` just before the boss test (`ld a,[wCurrentFloor] / ld b,a /
inc a / cp [hl]`). PyBoy S100 on the Gate of Reflection (29 floors): specials
only on floors 3 and 6 (5 of 13 samples), never on floors 2, 4, 5, 7, 8 (39
samples). Any code inserted before this test must preserve B (§7.6).

**Floor numbering.** The first-entry branch sets `wCurrentFloor = 0`; each floor
change increments it; the boss floor is served when `wCurrentFloor + 1 ==
last_floor`. So the game's floor N is `wCurrentFloor = N − 1`, and `last_floor`
(byte 3) is the gate's floor count INCLUDING the boss floor — it equals the FAQ's
"Levels: N" for all 32 gates (`tools/map_gate_names.py` checks it).

---

## 4. Standard maze generation ✅ (fully traced + modelled S122)

Entry: `$16:$605B` **`MazeBuildFloor`** (= `label16_605b`; reached from entry 6,
`label16_5FE4` `$16:$5FE4`, which first DMAs the Select-button map-overview tiles
into VRAM `$8500-$86C0`). It ends at `$16:$63AE` (the `ret` after
`jr_016_63ac` writes the item list's `$FF`). Every step below is reproduced by
`editor2/core/maze.py` `MazeRom.generate(rng, size, contents_row, $CAB4, $C92D)`
from the RNG state at the entry; **`tools/census_maze.py` (S122) forced 4,000
floors (random RNG states, maze sizes 3-15, contents rows 0-15, `$CAB4` 0-3,
`$C92D` 0-7) in PyBoy and every field the game wrote — grid, shape mode,
stairs, NPC, arrival, item list, the RNG after — equalled the model; 4 of them
regenerated (the 64-try path); a deliberately broken model (two cells of
`MazeCellOrder` swapped) failed on 103 / 300.** The RNG is `GenerateRNG`
($00:$3795): s = wRNG1·256 + wRNG2 → s·5 + $1357.

### 4.1 The grid and the pieces (✅)

The floor is a **4×4 cell grid at `$C940-$C94F`** (16 screens max). Each cell byte:

```
high nibble = PIECE (0-15)   ; which sides of the screen are open
low  nibble = variant (0-12) ; which of the piece's 13 drawings
```

**`MazePieceTable`** (`$16:$7055`, was mislabelled `FloorTypeSortData`): 16 × 4 B
+ `$FF`, `[openings, piece, weight class, 0]`, rows in piece order. Openings:
bit 3 = up, bit 2 = down, bit 1 = left, bit 0 = right. Piece 0 = all four (class
4), pieces 1-4 three sides (class 3), 5-10 two sides (class 2), 11-14 one side
(class 1), **15 = none = an empty / wall screen** (class 0; a `$Fx` cell).
Variants 0-11 are rolled; **12 is the "plain" drawing** used by shape mode 1;
13-15 are never produced. (How a cell is DRAWN: §7.)

A paired 16-byte buffer at `$C950-$C95F` holds per-cell explored state (bank
`$0B` sets it on entry; the map overview reads it). `$C960` = the stairs screen.

### 4.2 Build strategy (✅)

1. **Shape mode** `wShapeMode` (`$C93F`) = **`MazeShapeModes`** (`$16:$6056` =
   `0,0,0,1,2`)[wRNG1 mod 5] → mode 0 (3/5), 1 (1/5), 2 (1/5). `$C950-F` := 0,
   `$C940-F` := `$FF`.
2. **Mode 2** — copy **`MazePatterns`** (`$16:$7736`, 21 ready-made 4×4 grids,
   was `FloorTilePatterns`)[wRNG1 mod 21] into `$C940`; done (→ §4.3). These
   cells draw from the mode-2 tables (§7).
3. **Modes 0 / 1 — the carve.** `MazeCellOrder` (`$16:$7096`, was
   `FloorTypeOrderTable`) = the order the 16 cells are visited:
   `5 6 10 9 8 4 0 1 2 3 7 11 15 14 13 12`. `b` = `[$C93D]` (the **maze size**,
   the floor's encounter list +25 byte, vanilla 3 / 8 / 15) + 1.
   - **First cell** (5): `MazePickPiece` with required openings B = (wRNG1 + k) & 5
     (the first k ≥ 1 making it non-zero: down and/or right) when b < 9, else
     none; repeated until the piece is not 15.
   - **The next `size` cells** of the order: `MazeCellConstraints` (was
     `SetBrd_6744`) gives B = the sides whose PLACED neighbour opens toward this
     cell and C = the sides off the grid or whose placed neighbour does not; an
     EMPTY (`$FF`) neighbour is free. B = 0 → the cell stays empty; else
     `MazePickPiece` (was `SetBrd_6800`) picks a piece with all of B and none of C.
   - **`MazePickPiece`** lists the matching rows as [piece, class] pairs at
     `$C500`, counts the rows per class 0-4 (`$C0A0+`), gives each row the share
     20·class / count-of-its-class (integer, class 0 = 0) as a running 8-bit sum,
     rolls (wRNG2:wRNG1) mod sum and returns the first piece whose sum ≥ the roll
     (`$0F` when nothing matches, or when a running sum is exactly `$FF`, which the
     scan reads as the list end).
   - **Re-fit pass** — every cell in `MazeCellOrder`, using the CURRENT grid: B = 0
     → piece 15; else exactly the piece whose openings = B (C = ~B). This closes
     every opening nobody answers and turns empty cells next to an opening into
     dead-ends, so **a carved floor is always ONE connected maze** (model sweep
     over every 7th RNG state, sizes 3-15: 0 empty, 0 split floors; 2 to size + 1
     screens).
   - **Variants**: every cell := piece·16 + (12 in mode 1, else wRNG1 mod 12, one
     roll per cell in cell order 0-15).

**Maze size limits (measured S122).** Sizes 1-2: in 623 of 7,498 carved floors
(model, every 7th RNG state) the re-fit pass closes the first cell too and the
whole grid is empty — the stairs search (§4.3) then spins forever: PyBoy, size 2,
RNG `$8192` → the builder never returns (`census_maze.py` freeze probe). Size 0
(b wraps to 0 after the first cell) and 16+ read past `MazeCellOrder` into
`GateFloorDataTable` and write past the grid. **The editor accepts 3-15 only**
(`gamedata.check_list`, Encounters tab); every vanilla list uses 3, 8 or 15.

### 4.3 Placement passes (✅) — `MazePlacements` (`$16:$616C`, was `Jump_016_616c`)

Every spot is a metatile (16 px) of one screen, chosen by random tries and
accepted by the class of its **bottom-right 8×8 tile**: `TileAtPixel` (ROM0
`$1E31`, was misnamed `WaitInputRelease`) reads the tile id at pixel (16k + 8,
16j + 8) of the screen decoded into the `$C300` shadow (bank `$0B` entry 8 → the
gate step reader → `MazeScreenTable`, §7) → `$FFAA`; class = id >> 2: `$0C` /
`$0D` / `$0E` = ids `$30-$3B` (floor, trees, mounds). The screen pick (each
`MazePick…Spot`): one `GenerateRNG`, then screens wRNG1 + 1, + 2 … (mod 16),
the first non-empty; 64 failed positions (`$FFD5`) → the next non-empty screen.

| Pass | Routine | Positions | Classes | Rules |
|---|---|---|---|---|
| **Stairs** | `MazePickStairsSpot` (was `CallBrd_66ae`) | x 2-7 (RNG1 mod 6 + 2), y 2-5 (mod 4 + 2) | `$0C-$0E` | `MazeStairsPassable` (was `LoadBrd_6afb`) must pass — the 3×3 around it stays connected (`MazePassableTest`) |
| **Wandering NPC** | `MazePickNPCSpot` (was `CallBrd_6585`) | x 1-8, y 1-6 | `$0C-$0E` | not the stairs screen; then kept or dropped (below) |
| **Arrival** | `MazePickArrivalSpot` (was `CallBrd_661b`) | x 1-8, y 1-6 | `$0C-$0D` | re-picked once if on the stairs screen; not the stairs spot; not the NPC's screen |

Each of the three gets 64 tries (`$C0A9`); running out **regenerates the whole
floor** (`jp MazeBuildFloor`, with the RNG as it stands — the model does the
same; 4 / 4,000 census floors).

Results: stairs screen `$C960`, its tile offset in the 32-wide map `$C962/3`
(bank `$0B` `Call_00b_4309` stamps tiles `$3C $3D / $3E $3F` there when that
screen loads), absolute pixels `$C964-$C967`; NPC screen `$C926` (`$FF` = none),
pixels `$C927-$C92A`, kind `$C92B`, sub-kind `$C92C`; arrival `wWarpSpawn`
(`$C96F-$C972`) and `$C0A0` (screen) / `$C0A1-$C0A4` (pixels in the screen).
Pixel origins of the 16 screens: **`ScreenOriginTable`** ROM0 `$2DA7` (16 ×
[X lo, X hi, Y lo, Y hi] = col·160, row·128; re-sectioned from fake code S122).

**The wandering NPC is kept when**: `$CAB4` (the progress tier) 0 / 1 → `$C92D`
:= 0 first; `$C92B` := `$C92D`; if that is 4-7 → kept when a new wRNG1 has bit 0
clear (kind = `$C92D`); else kept when a new wRNG1 < **`MazeNPCChance`**
(`$16:$7886`)[wFloorType3] (0 / 13 / 26 / 38 of 256 by contents row) with
`$C92C` := wRNG1 mod 5, `$C92B` := wRNG1 & 3 (two more rolls). Dropped →
`$C926` = `$FF`, `$C92B-$C92E` = 0. (`$C92D` is written by bank `$0B`
`Call_00b_46da`: 5 when every screen was explored, 6 when only 2 … — the GATE
NPC list `GatePtrTable_42c8` is indexed by `$C92B`.) Then `$C92D` := 0.

The item pass follows (§5).

### 4.4 Walking a floor — battles per floor ✅ (S130, PyBoy-measured)

A maze floor is one 40×32 grid of 16-px cells; a cell is walkable when its
bottom-right tile is ≥ `$30`. `EncounterStep` (`$16:$6F05`) runs once per step
and drains `EncounterRateData[wMapID][class−$0C] × EncounterRateModifierTable[rate code] // 64`,
where class = tile id of the ENTERED cell >> 2 (`$0C`/`$0D`/`$0E`; the stairs
`$0F` are not checked). A step that crosses a screen edge never drains (the
scroll sets wGameState bit 2), and a step onto a floor item that is picked up
runs no check. A battle fires on the step whose drain borrows — so from a
counter c it takes c // drain + 1 steps (S130: `editor2/core/encounters.py`
`steps_between` used c / drain, one step short; corrected).
`SetRandomEncounterCounter` re-seeds at every room load (floor entry and after
each battle). Measured with `tools/census_dive.py`: 12 floors (11 types, codes
2/3/4) walked with the joypad on the original ROM, every drain equal to the
model.

On 1,000 generated floors per maze size, the shortest walk from arrival to
stairs averages 14.7 steps (size 3), 23.9 (size 8) and 29.3 (size 15); about
86 % of those steps drain (the rest: screen edges 1.4–2.9, item pickups ~0.2,
the stairs step). Steps between battles on gate floors (exact mean of
floor(seed / drain) + 1):

| Floor types | code 2 | code 3 | code 4 |
|---|---|---|---|
| base 138: types 0–8, 10 | 51.6 | 26.0 | 21.0 |
| base 150: types 9, 15 | 47.7 | 24.2 | 19.4 |
| types 11–14 (floor cells 100; other cells 180 / 250) | 71.5 | 36.3 | 28.8 |

With seeds of 1,100–6,000 (mean 3,547) that is 0.2–0.7 battles per floor on
the shortest walk (Gate of Beginning 0.43 per floor; whole non-boss dives:
Beginning 1.72, Villager 1.50, Talisman 1.93, Peace 3.57, Strength 5.31,
Wisdom 7.41, Ambition 13.9). This is a LOWER bound: a player who explores
walks more — `floor_steps(...)['reachable']` (278–454 reachable cells) is the
whole-floor UPPER bound the Balance service's "sweep" dive uses (PROJECT_COMPILER
§2.43). Treasure, priest, shop and coliseum rooms count 0 random battles;
specials sit on floors 3/6/9 with 50 % chance. Read from code, not measured: the
battle-fires test (counter < drain), the post-battle re-seed (S114), opened
chests skipped by the collision test (bank `$01`).
`editor2/core/dive.py` reads the result from `extracted/dive_census.json`
(`battles_per_floor(repo, gate, floor, list_bytes, maze_row=, special_row=,
floors=)`); `--selftest` re-derives a sample (verifier check 5).

**Special rooms (S131, ROADMAP P3.15b (2); PyBoy-measured, 7 / 7 rooms == the
model).** The walkable specials are fixed bank `$0B` rooms walked as such (S130
counted them as a maze floor):

| Pick | Rooms | Spawn cell (handler) | Shortest walk |
|---|---|---|---|
| 2 forest maze | `$53` + `$61`-`$64` (one screen each; `dwm/map_names`' "Forest Maze Gate Floor 1-4" for `$61`-`$64` is a misnomer — they are the forest's other rooms, joined by edge exits, some wrapping onto the same room) | (4, 6) | 24 cells, 2 room changes (`$53` → `$63` → `$64`, stairs at `$64` (4, 4)) |
| 6 maze (wRNG1 mod 3) | Maze 1-3 `$57`-`$59` (3 × 3 screens) | (15, 11) / (1, 2) / (1, 2) | 63 / 46 / 49 |
| 7 conveyor (wRNG1 mod 3) | Conveyor maze 1-3 `$54`-`$56` (3 × 3) | (13, 13) / (4, 22) / (14, 11) | 108 / 92 / 77 |

What a step does there (bank `$0B` `Jump_00b_4674` runs bank $16 `EncounterStep`
in exactly these rooms; bank $01 `CheckSpecialMapExits` = Z for them):
- **Every cell entered drains the same** — `EncounterStep` with wInGateworld 0
  uses a flat base, 100 (`$64`) or 80 (`$50`) on `$54`-`$56`, × RateMod[code] // 64;
  the cell's class does not matter. A cell entered across a screen edge drains
  nothing (as on maze floors).
- **Belts** (bank $01 `ConveyorBeltPush`, was the misnomer `CheckGateworldForNPC`):
  the standing cell's class `$AA >> 2` = `$0F` right / `$10` left / `$11` down /
  `$12` up (tiles `$3C-$4B`; `$4F` = class `$13` = the exit hole) sets a forced
  velocity (`$A1/$A2` X, `$A3/$A4` Y, ±`$0100`) and `$FF90` bits 1:0; the player
  rides until a cell of another class, and **every cell ridden is an ordinary
  step** (measured: one tap, 17 cells ridden, 17 drains of 80 at code 3).
- **Exits**: rows 0 / 7 at the room's edge fire on a PUSH into the edge
  (Entry 9) — `EncounterStep` runs, no drain, then the room loads; other rows
  fire on entering the cell (Entry 6, walk-on), `EncounterStep` runs with
  wGameState bit 5 set — no drain. **Each room change re-seeds the counter**
  (`SetRandomEncounterCounter`), so the forest's rooms are independent walks of
  ≤ 11 cells — at code 3 never a battle (11 × 100 < the smallest seed 1,100).
- Expected battles per walk (shortest, by rate code 0-7): forest 0 / 0 / 0 / 0 /
  0.12 / 0.22 / 0.34 / 0.42; mazes 0.02 / 0.10 / 0.26 / 0.88 / 1.24 / 1.58 /
  1.89 / 2.18; conveyors 0.12 / 0.23 / 0.49 / 1.45 / 1.87 / 2.36 / 2.81 / 3.27 —
  against 0.43 for a size-8 maze floor at code 3. The sweep bound scales each
  room by its reachable cells / walk steps.

Model: `dive.special_room` (cells / exits from the ROM through
`render_project.ProjectRenderer`), `dive.special_walk` (BFS over (map, cell):
belts ride, edge exits push, walk-on exits; path chars `a` drained, `-` screen
edge, `x` onto a walk-on exit, `p` a push, `|` a room load — `expected_battles`
treats `|` as a renewal), `dive.special_battles(repo, pick, code, walk)`;
`tools/census_dive.py` writes `specials` (+ `measured_specials`: the 7 rooms
walked with the joypad on the original ROM, every EncounterStep / drain / seed
== the path; `--measure-specials`). The handlers' spawn pixels and the variant
pick are in bank $16 `SpecialRoom2_ForestMaze` / `6_Maze` / `7_Conveyor`.

## 5. Contents: items, gold, masters ✅ (placement traced + modelled S122)

**How many** (end of `MazePlacements`): count = row[9] + (wRNG1 mod (row[10] +
1)) of the gate's contents row (`FloorTypeSelectionTable3`[wFloorType3], 16 B;
wRNG1 as it stands, no new roll), halved when fewer than 6 cells are used; row[11]
= the % chance of the blocking variant. `$C100-$C10F` (items per screen) := 0.

**Each item** — **`MazePlaceItem`** (`$16:$6432`, was `SaveBrd_6432`): kind =
SelectFloorType over the contents row (bytes 0-8 used: kinds 0 / 7 / 8 in the
vanilla rows); + `$10` when (wRNG2:wRNG1) mod 100 < row[11] (such kinds must pass
`MazeItemPassable` — the same 3×3 test as the stairs). 15 tries (`$C0A9` =
`$10`, decremented first): a spot from `MazePickItemSpot` (was `CallBrd_63af`;
x 1-8, y 1-6, classes `$0C` / `$0D`, NO try limit on a screen), re-picked once
each when it lands on the stairs screen, on the arrival screen, or on a screen
that already holds an item; refused (next try) when it is the stairs spot, the
arrival spot, the **same screen and ROW** as an earlier item (`MazeItemRowTaken`
/ `MazeItemRowMatch` decode an entry back to screen + Y only — X is never
compared), the NPC's screen, or a screen with 3 items. Sub-kind =
**`MazeItemSubKind`** (`$16:$7426`, 16 B, was read as a 17th "type 16" row of
table 3)[kind & 15]; when that is 1, SelectFloorType over the 48-byte
`FloorLayoutData` row of wFloorType3 (`$16:$7436 + 48·row`, 16 rows = 768 B).
Out of tries = no item.

**The list at `$D793`**: 4 B per item `[kind, sub-kind, X, Y]` — X / Y = the
ABSOLUTE metatile (screen col·10 + x, screen row·8 + y), `$FF` after the last.
When the player's tile matches a feature
(`CheckFieldMovementAllowed`, `$01:$5A6E`-ish), it's processed by the pickup
handlers in bank `$01` (`$01:$5B68`+):

- `$D78F` = the feature id. `$FF` = empty marker; `$00` = **gold** (amount in
  `wGroundItemData`/`$D792`, formatted + added via `CompareGold`); else = an
  **item** id pushed into `wInventory`. Pickup plays SFX `$53`. ✅

**Item tier by depth** ✅ — bank `$01` (~`$5AD0`) reads `wBossTileset`:
tier `$01` → item id `RNG mod $0D + $07`; tier `$02` → `RNG mod $1E + $28`. So
late gates draw from higher item ranges. Masters/other feature types share the
same placement machinery (rarely rolled).

## 5.1 Damage tiles ✅ (resolved S37, code-derived + watchpoint-confirmed)

Late-gate floors that drain party HP per step. Fully traced:

**Detection (per tile).** The movement engine reads the tile id under the player
from the `$C300` screen tile-id shadow buffer and stores it in **HRAM `$AA`**
(`$00:$1E96`). A tile's **behavior class = `tileID >> 2`**:

| Class | Tile ids | Meaning |
|-------|----------|---------|
| `$0E` | `$38-$3B` | **damage tile** |
| `$0F` | `$3C-$3F` | staircase (down) |

(The brown tile observed in SameBoy is id `$38`; `$38 >> 2 = $0E`. The gate-exit
check `$0B:$46A7` uses the same `$AA` with `>> 2 == $0F`.)

**Application (per step).** `ApplyFloorDamage` (`$01:$5E23`) runs once per
completed step. If `($AA >> 2) == $0E`, it looks up the amount in
**`FloorDamageTable` (`$01:$5E7D`, 16 bytes, indexed by `wMapID` = the floor
type)** and applies it to the active (front-line) party — count `$CA8D`,
slots 0–2 — via `ComparePartySlotCount2`, which **skips** any monster whose
status byte (slot `+$0B` = `$CB0B`) has bit 7 set. Feedback: SFX `$6C`, BG-palette
flash `$2D`, screen-shake `$C8A8 = $08`. HP is written through the generic
monster-field writer (`$00:$22CE` → `$00:$24AD`).

**`FloorDamageTable` contents** (by floor type 0–15):

```
type:  0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
dmg:   0  0  0  5  0  0 10  0  0  0  0  0  2  0  2  0
```

So type `$03` → 5/step (**red**), type `$06` → 10/step (**blue**), types `$0C`/`$0E`
→ 2/step (**brown**), all others 0 (safe). **Amount is per floor type; colour is
the floor palette recolouring the same `$38-$3B` graphics.** Same damage-tile id
range on every damage floor — the floor type alone sets how much it hurts.

**Editing levers:** `FloorDamageTable` is same-size data (16 bytes) — retune any
floor type's damage, or zero it. To make a *new* floor type a damage floor, set
its table byte and ensure its tileset places class-`$0E` tiles (`$38-$3B`).

This is the mechanism for "insert a new special room into the rotation."

The special path (`$16:$5C1C`) rolls `wFloorType2` via `FloorTypeSelectionTable2`,
then dispatches through **`rst $00`** — a jump-table-indexed-by-A construct
(`RST_00` at `$00:$0000`: the `dw` words immediately after the `rst $00` opcode are
the table; `A` selects the entry). The `rst $00` opcode is at **`$16:$5C31`**, so the
table starts at `$16:$5C32`. **ROM-verified entries** (idx 0–7):
`$16:$5C42, $5CB9, $5CCB, $5CEC, $5D0D, $5D2E, $5ED8, $5F4C` (idx 8/9 = `$B0CD/$FA6D`
are out-of-bank — only 0–7 are real handlers). *(Correction: earlier drafts listed
idx 0 as `$5C50` and omitted idx 2 `$5CCB`; both verified wrong against the ROM.)*

Each handler is a small, uniform block:

```asm
ld a, $5A              ; <-- a SPECIAL-ROOM map type ($5A/$5B/$5C TreasureChest,
ld [wMapID], a         ;     $53 ForestMaze, $51, …)
ld a, $00
ld [wInGateworld], a   ; <-- clear gate-maze mode; render as a FIXED template
ld hl, $0048           ; spawn X (nibble-packed)
... set wWarpSpawnX/Y ...
ret
```

**Key facts for linking custom rooms:**

- A special room is just a `wMapID` value rendered with `wInGateworld = 0`.
- Custom rooms (mapID ≥ `$6B`) already render with `wInGateworld = 0` and are
  already routed by `GateAwareDispatch` / `CustomScriptRead` (see
  `CROSSBANK_ROOMS.md`). The random-encounter custom-room work runs in exactly
  this mode.
- Therefore a custom-bank room can be dropped into the gate rotation by **(a)**
  pointing a `rst $00` dispatch slot at a handler that sets `wMapID = <custom id>`,
  and **(b)** opening that outcome's probability in `FloorTypeSelectionTable2` for
  the target gate(s).

**Iron-rule note:** the `rst $00` jump table is raw embedded `dw` pointers in
bank `$16`. *Repurposing* an existing slot = a same-size 2-byte pointer edit
(safe). *Adding* a slot needs a new handler + table growth in end-of-bank `$16`
padding (no mid-bank insertion). Bank `$16` is not on the never-insert list
(`$01/$04/$17`), but the jump table itself must not be shifted.

---

## 7. Rendering a generated floor ✅ (piece → screen map decoded S122)

- **Tileset graphics**: `$0B:$4027` picks the tileset table by `wInGateworld` —
  gate rooms use `$00:$2A5D` (the 16 records: bank `$28` id = the floor type,
  640 × 512 px, collision threshold `$30`), normal rooms `$00:$26DD` (8 B/entry:
  `[gfx_ptr:2][spawn_data:6]`), indexed by `wMapID × 8`; the gfx pointer is DMA'd
  to VRAM `$9000`. Bank `$16` entry 5 (`$1605`) preps the tileset first. Each
  sheet is 128 tiles: `$00-$3B` the maze art, `$3C-$3F` the stairs, `$40-$7F`
  **blank** (S122). No ordinary room uses these 16 sheets (ROM check S122).
- **The screen's tiles — `MazeScreenTable`** (`$16:$7896`, 256 × `[layout id,
  layout bank]`, was `FloorDataPtrTable1`; shape mode 2: **`MazeScreenTableB`**
  `$16:$7A96`, was `FloorDataPtrTable2`), indexed by the cell byte
  `$C940[wScreenIndex]`: bank `$0B` `ReadStepBlock` (entry 8) sends gate rooms to
  bank `$16` entry 9 `LoadFloorDataPointer`, which returns exactly the `[step id,
  tileset bank]` pair a normal room's step entry holds — an ordinary LZ screen
  layout stream (512 B, 32 × 16). Modes 0/1 use 195 drawings (pieces 0-14 × 13
  variants; piece 15 is open water / wall), mode 2 another 60 → **254 distinct
  screens** (`extracted/maze_pieces.json`). The stairs screen gets `$3C-$3F`
  stamped in after decoding (§4.3).
- **Palette / attributes**: bank `$17` (`Jump_017_4064` / `Jump_017_40DA`) resolves
  per-screen attributes from `GateAttrTable_A` (`$17:$5215`, shape modes 0/1) — or
  `GateAttrTable_B` (`$17:$5415`) when shape mode `$C93F == 2` (S122: the bank
  $17 comments said "== 0" / "== 1" — corrected) — indexed by the same cell byte
  (256 entries × 2 B: `attr_idx, attr_bank` = an LZ attr stream, nibble per tile).
  All 275 attr streams use **palettes 0-3 only**, never the VRAM-bank-1 bit
  (census S122). The floor palette comes from `$17:$51F5[wMapID]` — **4
  palettes, slots 0-3** (`LoadPal_46a1`, b = 4); the slot-4 override this doc
  noted for gate floors is never referenced by a maze tile.

**The screens are SHARED by all 16 floor types** — a floor type changes only
the sheet and the four colours. Measured S122 (`census_maze.py` screens):
4 arrivals per floor type (all 16, 6 of them on the stairs screen) — the PyBoy
screen equals the model's picture (`MazeScreenTable` + `GateAttrTable` + the
type's sheet and palettes + the stairs stamp) on every 8×8 tile not under a
sprite.

This is why **maze tilesets are reusable in custom rooms**: they are ordinary
LZSS layouts referenced through the same tileset/attr tables the custom-room
pipeline already manipulates (§7.10).

---

## 7.1 Deriving a room's runtime palette from ROM ✅ (S39, validated 30/30 + gate)

The engine does **not** infer colours — each room supplies its real colours and a
fixed rule fills the rest. Reproduced exactly against 30 in-game SameBoy dumps plus
the gate floor. Implemented in **`tools/derive_room_palette.py`** (`--map 0xNN` /
`--gate 0xNN`).

**BG slots 0–3 — the room environment. Only colour indices 0 and 2 are real.**
The engine **overwrites colour index 1 → `$6BFF` and index 3 → `$0000`** in *every*
BG palette at runtime (this is why every dump reads `_ 6bff _ 0000`). So to derive
a palette: read colours 0 and 2 from the room's palette block; force 1 and 3.
**Where (S96, located):** bank $17 `LoadPal_4102` (entry 9, also the tail of
entries 0/1) loads the system slot-7 palette (`$5655`) into the WRAM palette
buffer `$C797` (slot n colour i at `$C797+n*8+i*2`) and copies slot 7's colour 1
(`$C7D1`) and colour 3 (`$C7D5`) into colours 1/3 of slots 0-6 — at every palette
LOAD, not per frame. **Custom rooms can opt out for colour 1** (S96
`FreeColor1Hook`, patches/bank_017.asm): a palette marked `free_color1` in
project.json carries bit 15 in colour 3 of each of slots 0-3 (hardware-ignored;
0 of the 101 vanilla room/gate palettes set it) and keeps its own colour 1 in
those slots; slots 4-6, colour 3 and every vanilla room are unchanged. The
marker is tested per slot and put back into the buffer after the colour-3
pass (S96 round 4), because `LoadPal_4102` also runs STANDALONE — the field
menu reaches it through entry 6 on every open, with no room reload before
or after (the menu-close path only pushes the buffer, $17 entry 8).

Where slots 0–3 come from:
- **normal rooms:** `AttrPtrTable` (`$17:$476F`)[mapID] → room block → **first
  non-empty screen pointer** → step entry (skip the 2-byte WRAM dest addr) →
  `pal_ptr` at `+2` → 4 palettes (8 B each). **Scan screens** — some rooms leave
  screen 0 = `$FFFF` and put the real data on a later screen (Starry Shrine `$09`
  uses screen 1 → `$577D`; the Intro `$2F` uses screen 4 → `$5ADD`).
- **gate floors:** `$17:$51F5`[floortype] → `pal_ptr` (floortype `$D` → `$629D`).

**BG slots 4–7 — shared system palettes.** Slots 5/6/7 are constant in every room
(`009b…`, `7ce1…`, `0139…`); slot 4 is usually `00ef 6bff 01d8` but a few rooms
override it as a 5th environment palette (gate floors use `64e3…`).

**Object palettes — one global block at `$17:$5615`**, identical in every room.

**Gotchas (all cost real time — see KEY_LESSONS S39):**
- A room with **no resolvable screen pointer** is either unused or set entirely by
  script. The tool **refuses** (raises) rather than return a guessed palette.
- Rooms can **share a screen**: the Intro (`$2F`) and the Library's opening
  prophecy both resolve to `$5ADD` (`64ee…`). The Library you walk into normally
  (`$12`) is a *different* palette (`$583D`, `04ed…`) on every one of its screens.
- The `AttrPtrTable` step-entry `pal_ptr` is sanity-checked to the palette region
  `$5200–$6300`; this keeps the screen-scan from latching onto adjacent-room bytes.

## 7.2 The Gate-of-Beginning maze tileset (`$28` step `$0D`, gfx-ID `$280D`) ✅

Referenced **only** by the gate tileset table (`$00:$2A5D`), absent from the normal
`$00:$26DD` table — i.e. gate-exclusive. It is the tileset for floortype `$D`, the
floortype gate 0 (Gate of Beginning) always rolls (its `FloorTypeSelectionTable`
row 0 is `$64` guaranteed at index `$D`). Tile map (LZSS, decompress via
`tools/decompress_tiles.decompress_lz(rom, 0x28, 0x0D)`):

| Tiles | What | Palette | Collision (threshold `$30`) |
|-------|------|---------|------------------------------|
| `$30-$33` | solid sand floor (`$33` cleanest) | pal0 | ≥`$30` walkable |
| `$08`, `$2C` | solid water / wall | pal1 | <`$30` **blocks** |
| `$34,$35,$36,$37` | **TREE** (2×2 leafy object) | pal3 | ≥`$30` walkable |
| `$38,$39,$3A,$3B` | **DUNE** (2×2 low mound) | pal0 | ≥`$30` walkable |
| `$3C,$3D,$3E,$3F` | **PIT / staircase** (2×2 hole) | pal0 | ≥`$30`; class `$0F` = stair (§5.1) |

Trees and dunes are **2×2 metatiles** (NPC-sized), not texture fragments — the same
two tiles `$34/$35` render as a green tree on pal3 or a brown mound on pal0. Note
`$38-$3B` doubles as the damage-tile id range (behavior class `$0E`, §5.1); in a
custom room it is decorative unless `FloorDamageTable` applies.

## 7.3 The custom gate room — Room `$6B` ✅ (Phase 2C, rendering half)

A custom-bank room rendered entirely with `$280D` and the real gate floor palette —
proves a custom room can wear the gate maze look. Pieces:
- **Graphics:** patched `$26DD[$6B]` entry (ROM0 `$2A35`) → gfx-ID `$280D`,
  collision threshold `$30`. (`patches/bank_000.asm`.)
- **Palette:** `CustomPaletteColors_6B` = the gate floor palette slots 0–3
  (`$629D`), loaded by `CustomPalCheck` with **`b=$04` (slots 0–3 ONLY)**. Loading
  all 8 slots clobbers the shared system slots 4–7 and corrupts monster/follower
  colours — a confirmed regression; never widen this load. (`patches/bank_017.asm`.)
- **Layout + attr:** `patches/bank_064.asm`, regenerated by
  **`tools/build_gate_room.py`**. Palette is assigned **per position** (each cell
  carries its pal in the attr nibble) because trees need pal3 while sharing the
  threshold split with ocean/floor — the tile-id→palette rule alone can't express
  it. Two vertical screens; a sandy island with an ocean-wall border (incl. top),
  trees, dunes, and pits.

This room is the **rendering half** of "custom room into the gate rotation"
(ROADMAP Phase 2C). The **insertion half** (a `rst $00` dispatch slot + a
`FloorTypeSelectionTable2`/gate-0-branch weight, §6) is still open.

---

## 7.4 Pillar A — table-driven custom-room rendering ✅ (S40, user-confirmed in-game)

§7.3 rendered **one** custom room with per-room values hardcoded into the bank-`$17`
render intercepts (`cp $6B` … else vanilla). Pillar A generalises that so **any** custom
mapID renders from per-room tables indexed by `mapID-$6B`, with **zero** new hardcoded
render code per room. Proven by adding a real second room, `$6C`.

**The three render inputs, now all table-driven by `mapID-$6B`:**

1. **Tileset + dimensions + collision threshold** — from each room's own `$26DD` record.
   `CustomGFXMapID` (ROM0) was widened `cp $6C`→`cp $70`, so `$6B-$6F` each return their
   **raw** mapID and index their own 8-byte `$26DD` record `[gfx_lo,gfx_hi : w_lo,hi :
   h_lo,hi : threshold : pad]`. (`$26DD` records exist only for `$6B-$6F` before the gate
   table at `$2A5D`; `$70+` will need an intercept — Pillar B follow-up.) `$6C`'s record at
   ROM0 `$2A3D` mirrors `$6B`'s (gate tileset `$280D`, 2-screen, threshold `$30`).
   **Per-room `$26DD` record addresses** (= `$26DD + mapID*8`, all ROM0 so file-offset =
   address): `$6B`=`$2A35`, `$6C`=`$2A3D`, `$6D`=`$2A45`, `$6E`=`$2A4D`, `$6F`=`$2A55`
   (`$70` would land on `$2A5D` = the gate table, hence the `cp $70` ceiling). **S94:** the
   `$6B-$6F` rows (`$2A35-$2A5C`) are a compiler-owned `@BUILD_PROJECT rom0_room_records`
   region in `patches/bank_000.asm`, emitted from `custom.rooms[].record` (undeclared /
   placeholder mapIDs keep the vanilla filler `12 24 A0 00 80 00 50 00`); the labels inside
   the window (`Data_2A38`, `DataTable_2A3D`, `DataLookup_2A40`, `Data_2A48`, `DataTable_2A56`,
   `Data_2A58`, `DataLookup_2A59`) are referenced jump targets and the emitter keeps them at
   their addresses.
2. **Palette + 3. Attr, per (screen, STATE) in the VANILLA row format (S94b).**
   `CustomAttrPtrTable`: one `dw` per custom room → `RoomAttr_<mid>` (16 `dw`, one per
   screen slot) → `ScrAttr_<mid>_<k>` = `dw <step counter>` + per state
   `db attr_entry, attr_bank` / `dw pal_ptr` — the exact shape of vanilla's
   `AttrPtrTable → screen table → [counter] + [entry, bank, pal_ptr] per step`, so
   `CustomAttrCheck` only swaps the table base (`HL = CustomAttrPtrTable, A = mapID-$6B`,
   the vanilla walk then indexes `wScreenIndex` and the step counter as it always did) and
   the palette path (`CustomPalCheck`) loads `pal_ptr` with **`b=$04` (slots 0–3 only)**,
   keeping slot 7 for custom rooms — same hard rule as §7.3. `dw $0000` in
   `CustomAttrPtrTable` = the vanilla walk (`ld hl, AttrPtrTable`). `pal_ptr` is either a
   project palette label or the vanilla source room's palette pointer
   (`derive_room_palette.normal_room_pal_ptr`). History: S40 `db bank, base_entry` with a
   hardwired `base_entry+2` per non-zero screen (gave a 6-screen clone screen 1's attrs on
   screens 2-6) → S94 17-byte per-screen map → S94b per-state rows, because vanilla varies
   attr AND palette per step (Servant room `$3F` burning → cleared). Every renderer and the
   compiler follow PROJECT_COMPILER §2.11.

Both intercepts now do `index = mapID-$6B; …` table reads instead of `cp $6B`. The vanilla
path is untouched for `mapID < $6B`, so the `$6B` regression is byte-identical (verified).

**The proof room `$6C`** reuses `$6B`'s layout (bank `$64` entries 0/2), attr (entries 1/3),
gate tileset, and Farm source-map — i.e. it is structurally `$6B` — and differs **only** in
`CustomRoomPalPtr[1]` → a coherent **moonlit-night** palette (cool slate ground, navy water,
dusk-teal trees). Same island, different time of day, entirely from the table. This is the
cheapest possible "distinct room" and the cleanest possible isolation of the palette table.

**Night palette-swap as a technique.** Recolouring an existing room via its palette-table
entry is a ~64-byte, zero-code way to make biome/time-of-day variants (night, snow,
volcanic, cave). It must **preserve the source palette's value structure** (keep idx1 light,
idx3 dark; shift only hues, keep idx0/idx2 close in value) — the gate tiles' pixel→index
mappings were authored for the gate palette, so a high-contrast recolour turns a textured
floor into glitchy stripes. Author by deriving from the source palette (§7.1), not from
scratch. (KEY_LESSONS S40.)

**Files:** `patches/bank_017.asm` (`CustomPalCheck`/`CustomAttrCheck` generalised; tables
`CustomAttrPtrTable`/`RoomAttr_*`/`ScrAttr_*`/`CustomPaletteColors_*` are compiler-emitted
into the `room_render_tables` region since S94b), `patches/bank_000.asm`
(`CustomGFXMapID` widen + `$26DD[$6C]` record), `patches/bank_060.asm` (`$6C` room data,
2-screen mirror of `$6B`; the `$6B→$6C` warp **byte-4 must be `$00`**, see KEY_LESSONS S40),
`patches/bank_064.asm` (shared layout/attr, unchanged from §7.3).

**Gotcha that cost this session** (full write-up in KEY_LESSONS S40): the `$6B→$6C` exit's
**byte-4 is the `$2DE7` spawn-screen index, not a "destination screen number".** A stale
`$01` (legit when `$6C` was a wide Castle clone) added +10 metatiles of X and dropped the
player at tile column 35 — off-map in the `$FF` padding — so the room rendered but the player
couldn't walk. Must be `$00` for a single-screen-width room.

This is the **rendering generalisation** that Pillar B (gate-aware rotation: pick *which*
custom mapID appears, by gate/flag/floor/weight) builds on. With render table-driven, the
rotation dispatcher only has to choose a mapID; rendering "just works" for whatever it picks.

---

## 7.5 Pillar B — inserting a custom room into the rotation + descent ✅ (S41, user-confirmed)

Pillar B is the **insertion** half: make a custom room actually appear as a gate floor and
descend to the next floor like a real maze floor. Done for **gate 1 (Gate of Villager)**,
custom room **`$6D`** (a dedicated 1-screen copy of `$6B`'s island, so the `$6B`/`$6C`
warp demos stay intact). The POC forces `$6D` on **every** non-boss gate-1 floor.

**Mechanism chosen — a byte-neutral fork at the gate-0 exclusion, NOT a `rst $00` slot.**
The §6 plan (repurpose a `rst $00` dispatch slot + open a `FloorTypeSelectionTable2` weight)
works, but the cleaner, lower-risk insertion point is the **gate-branch decision** itself.
In entry-5 floor setup (`label16_5b4e`) the original 6 bytes at **`$16:$5BA9`** were the
gate-0 special-room exclusion — `ld a,[wGateID] / or a / jr z, jr_016_5bbf`
(`FA 35 C9 B7 28 xx`). *(Correction: this reads `wGateID $C935`, not `wCurrentFloor` as an
earlier ROADMAP draft claimed.)* Those 6 bytes are replaced **in place** (6→6, no shift)
with `call GateDecisionFork` + 3 `nop`. `GateDecisionFork` (appended in end-of-bank `$16`
padding, `$7CB9`) routes by `wGateID`:

```asm
GateDecisionFork:
    ld a,[wGateID] / or a / jr z,.gate0      ; gate 0 -> preserved exclusion
    cp $01 / jr z,.gate1                       ; gate 1 -> custom room
    ret                                        ; gates 2-31 -> fall into RNG gating ($5BAF)
.gate0: pop hl / jp jr_016_5bbf                ; standard maze (vanilla gate-0 behaviour)
.gate1: pop hl / jp CustomGate1Setup
```

**The `pop hl` is load-bearing.** The `call` pushed a return address pointing at the 3 nops
(then the RNG gating at `$5BAF`). Gate 0/1 must NOT return there — they must unwind to
entry-5's *caller*, exactly as the vanilla `jr z` did. So those paths `pop hl` to discard the
call's return address; their downstream `ret` then unwinds one frame further, to entry-5's
caller. Gates 2–31 simply `ret` so execution continues into the untouched RNG gating —
byte-for-byte vanilla for every non-forked gate. (KEY_LESSONS S41.)

**`CustomGate1Setup`** (`$16:$7CCC`) is a byte-mirror of the vanilla `$50` special-room
handler `$5D0D`: `wMapID=$6D`, `wInGateworld=0`, spawn `$0048/$0068` (central walkable sand).

**Descent** uses the special-room primitive, not the maze staircase: `$6D`'s lone exit
(`patches/bank_060.asm`, on the island PIT at walk `(5,3)`) carries **`gate_flag=$80`**
(exit byte 3 → `wWarpFlag $C96E`; `dest_map_type=$00` → `wWarpGateId $C96D`) — byte-identical
to how `$50/$51` descend. That re-enters entry-5 floor setup (`wWarpFlag=$80` → bit 7 set →
"subsequent floor"), which increments `wCurrentFloor`, re-runs the fork, and serves `$6D`
again until `wCurrentFloor+1 == last_floor (5)` yields the vanilla boss floor.

### 7.5.1 The descent-transition feel — `wInGateworld=0` ⇒ "fresh gate entry"

First working build descended correctly but with the **wrong transition**: a slow dissolve
(the hub→gate-entry fade) and the **BGM restarting every descent**, instead of the maze-floor
feel (quick *whoosh* + BGM continuous). Both symptoms have **one root cause**: the custom room
runs with **`wInGateworld = 0`**, so the engine reads each descent as a *fresh hub→gate entry*
(slow dissolve + stop/restart music) rather than an *in-gate floor change*. Maze floors keep
`wInGateworld` nonzero (`$01` on display, set by `jr_016_5bbf`) throughout, so their descents
are smooth. The fade/BGM decision reads `wInGateworld` **during the transition window** — after
the exit fires, before the room reloads — when the leaving room's display value (`0` here) is
still live; `LoadNewBGMIdIntoA` (`$01:$4364`) only restarts via `call nz, SetBGM` when the new
id differs, and the dissolve path stops the music, so the next floor re-loads it.

**Why not just make it a real in-gate floor.** Setting `wInGateworld=$01` *during display*
was tried and **freezes the game + breaks the render**: that flag gates **every** gate/maze
branch in the room engine (tileset table `$26DD` vs `$2A5D`, exit checker vs maze staircase,
per-step maze handlers, …), and the un-intercepted ones go looking for maze state the custom
room doesn't have. No nonzero value dodges those paths — display-time `wInGateworld` must stay
`0`. (KEY_LESSONS S41.)

**The fix (surgical, transient).** Keep `wInGateworld=0` for the whole time the room is on
screen, and flip it to `$01` **only for the transition**. At the gate-flag exit transition
point `jr_00b_466b` (`$0B:$45F9`), a byte-neutral `call CustomDescentInGate` (it replaces the
`ld hl, wGameState` the site needs and restores HL before returning) sets `wInGateworld=$01`
**iff `wMapID ≥ $6B`**. The engine's own flow then resets it (Entry 0 → fork →
`CustomGate1Setup` → back to `0`) before the room redraws. So the fade/BGM logic reads
"already in the gate" during the transition, while the room never *displays* in the broken
in-gate state. Result: whoosh + BGM continuous, render and descent unchanged. Non-custom
rooms (`wMapID < $6B`) are untouched. (KEY_LESSONS S41.) **S123 r2:** only for a
Stairs-down exit (`wWarpFlag` bit 7, gate flag `$80`); a custom room's GATE ENTRANCE (flag 1
— S115 new-gate entrances, S123 world portals) keeps `wInGateworld` 0 and gets the game's
own portal whirl. The body moved to bank $60 entry 12 `CustomDescentFeel` (bank $0B is full
to `$4B42`; `CustomDescentInGate` = `ld hl, $600C / rst $10 / ld hl, wGameState / ret`).

**Production note — DONE S100 (§7.6).** The POC forced `$6D` on every non-boss
Villager floor from a hard-coded `.gate1` branch + `CustomGate1Setup`; both were
removed S100 — the fork now asks bank $71 entry 4 for a data-driven rule (gate,
floors, chance, flag terms, once per dive), and the example project expresses the
POC as `gate_rotation` on Villager floors 2-3 at 50 %.

**Files:** `patches/bank_016.asm` (fork + `CustomGate1Setup`), `patches/bank_000.asm`
(`$26DD[$6D]` gate-tileset record, 1-screen), `patches/bank_017.asm`
(`CustomRoomPalPtr[2]`/`CustomRoomAttr[2]` → borrow `$6B`), `patches/wram.asm`
(`wCustomStep_Room6D_S0 $D47D`), `patches/bank_060.asm` (`$6D` room data + descent exit),
`patches/bank_00b.asm` (`CustomDescentInGate` transition intercept).

---

## 7.6 Custom rooms on gate floors, data-driven (S100, ROADMAP P3.7b part 1) ✅ built, PyBoy-verified, NOT yet user-tested

Authoring: PROJECT_COMPILER §2.16 (`custom.gate_inserts[]` + the room's
`gate_arrival` / Stairs down / `can_save` / `encounters.follow_gate` / `music`);
editor: the Gates tab + the Rooms-tab "Inside gates" group (EDITOR_DESIGN §5.1b).

**Decision point.** `GateDecisionFork` (bank $16 tail, the S41 in-place call at
`$5BA9`) on every NON-boss floor: (1) anchor return → standard maze (S73,
unchanged); (2) `push bc` / **bank $71 entry 4 `CustomGateInsert`** / `pop bc` —
B must survive (the vanilla special-room test that follows divides it, §3); a hit
(E=1) → `pop hl` + `ret` (the room is already set up; this unwinds to entry 5's
caller exactly as the vanilla special handlers do); (3) gate 0 → standard maze;
(4) else `ret` into the vanilla gating.

**Entry 4.** Walks `GateInsertTable` in list order. A record applies when its gate
== `wGateID`, `floor_lo ≤ wCurrentFloor ≤ floor_hi`, its once bit is clear in
`wGateDiveMask`, and every flag term holds (`TestEventFlag`); only THEN is its
chance rolled — `GenerateRNG`, `RNG16 mod 100` (the `SelectFloorType` roll) `<
chance`; 100 % draws no RNG. The first hit writes `wMapID`, `wInGateworld = 0`,
`wWarpSpawnX/Y` (absolute pixels — the exact contract of the vanilla handler
`$16:$5D0D`) and sets its once bit. **A gate with no applicable record never calls
`GenerateRNG`**, so its floors are byte-for-byte vanilla (A/B S100: Gate of
Reflection, 18 floor decisions from one save — maps, spawns, special/standard
identical to the S99 build). Engine bug caught S100 before delivery: the record
walk uses E for record sizes, so the end of the table must reload E = 0 (a
stale E read as a hit and hung the floor load — KEY_LESSONS S100).

**Once per dive.** `wGateDiveGate` ($DEBC, = wGateID+1) / `wGateDiveMask`
($DEBD): entry 4 resets both on floor 0 (a new dive — the first-entry branch) or
when `wGateID+1` differs (an anchor return into another gate). They sit outside
the WRAM save image, so bank $73's main-image detectors copy them to / from SRAM
**`$BFCA/$BFCB`** (the reserved tail after the "F2" gate, inside checksum v3's
third segment) — a save made in a served room keeps them (PyBoy S100: save in the
room on floor 2 → reset → continue → dive bytes 6/1 restored → the stairs lead to
a maze floor 3, not the 100 % once-per-dive room again). Old saves hold whatever
the tail held: harmless (mismatch → reset; a stale mask can only suppress a room).

**Saving** — bank $07 `SaveAllowCheck` (field menu OPTN → JOURNAL), vanilla
verdict: allowed iff mapID < $30 or mapID ∈ {$50,$51,$5A,$5B,$5C} (treasure /
priest rooms); refused on maze floors (`wInGateworld ≠ 0`), boss rooms $30-$4F,
the forest / conveyor / maze specials $52-$59 and $5D+. The patched same-size
rewrite keeps every vanilla verdict (exhaustive byte interpretation over all 256
mapIDs, S100) and asks entry 5 for custom rooms (`can_save` false → refused,
"Cannot record in the Journal here."; default allowed — the S8 behaviour).

**Transitions + music.** Entering a served room from a maze floor and leaving by
its stairs (gate flag $80) use the in-gate style (S41 `CustomDescentInGate`,
bank $06 `MapTransitionMachine`, $C905 = $10). A served room with no music keeps
the gate's: `LoadNewBGMIdIntoA`'s gate path returns $34, or on the floor BEFORE
the boss floor the boss room's `RoomBGMTable` entry — the same as a vanilla floor
(PyBoy S100, Bazaar Gate: maze floors 7/8/9 = $34/$0C/$0C; a served room on floor
8 = $0C, also after save + reload). A room song (`music`) overrides it.

**Free-colour rooms (S100 r3, built, NOT yet user-tested).** The descent
transition draws its blank with tile `$E0` = colour 1 and never sets attrs:
state $10 fills 20×14 map rows 18 below the screen origin (`[$c90b/c]` +
$0240, what state $12's raster squeeze shows outside the room), state $13
wipes the room's columns, and states $14-$17 fade every hardware colour to
the palette BUFFER's colour 1 ($C797 + 8n + 2) while the next floor loads.
Vanilla forces colour 1 = cream, so all of it reads as a cream wipe; a room
with own colour 1 (FreeColor1Hook) showed its own colour (user S100 r3). Fix:
state $10 (after the fill base is known) → bank $73 entry 19 `GateWipeAttr`
(those rows' attrs := 7); end of state $12 → entry 20 `GateLeaveFreePal`
(marked slots: buffer colour 1 := slot 7's cream, then entry 13 pushes it to
hardware). Same-size (the $98xx store 18 → 14 B, the $c180-3 stores 12 → 7
B + nop; states $11-$13 keep $6F14/$6F3F/$6FC7). Both return at once for
vanilla rooms and unmarked palettes.

**The well graphic (S100 r3).** Vanilla's next-floor hole: special room $51
(Priest) cell (8,2) = sheet slots $2C/$2D/$2E/$2F (walkable side, threshold
$20) — black hole, colour-0 rim, a plain colour-2 surround ($50's copy at
cell (1,6), slots $24-$27, has cream colour-1 corners). The editor's "Stairs
down here" paints it with the surround replaced by the cell's own floor.

**Battles.** A served room with `encounters.follow_gate` (RoomEncTable gate byte
$FF) runs the per-step encounter handler WITHOUT pinning, so battles draw the
dive's own pool (PyBoy S100: vault on Bazaar floor 5 → pool 10, a Bazaar pool;
Villager floor 3 → pool 2) and `wGateID`/`wCurrentFloor` stay the dive's. A FIXED
pool is refused by the compiler for served rooms: entry 1 rewrites
`wGateID`/`wCurrentFloor` every step, so the next floor would belong to that gate.

**Measured end to end (PyBoy S100, the user's .sav):** real gate entry (the
pedestal exit's own bytes: dest = gate, flag 1) → floor-1 maze, dive mask 0 →
the staircase transition → rule floor 2 served at (4,6); an examine spot's YES
sets a flag → the real stairs → the flag rule serves another room on floor 3 at
its arrival, JOURNAL refused there, own song, a Villager battle; once-per-dive
suppression; flag clear → vanilla; 40-sample chance runs (50 % → 19/40 and
19/40; an out-of-range floor 0/40); `test_canvas.py` v7 --rom from a scripted
new game.

---

**Music in served rooms (S116):** a served room with no song of its own plays the gate's
own song when the gate has one (`music.gates[n].floors` — the compiler marks the room $FF
in `CustomRoomBGMTable`); without a gate song, the gate theme as before (SOUND_SYSTEM §10).

**Every gate + the chance by level (S127, ROADMAP P3.14e2; PROJECT_COMPILER §2.40):** a
record with gate byte `GATE_ANY` (`$FE`) applies in every gate (the game's 0-31 and new
ones), floors 2 to 256 (the boss floor is never a decision point). A chance byte with bit
7 set is a row index: `ScaledChance` calls bank $77 entry 9 `PartyAvgLevel` (the 1-3
party monsters' average, clamped 99) and reads `ScaledChanceTable` + row × 100 + level
(0-100 %, linear between the rule's two points, flat outside). Nothing changes for gates
without such a record (no extra RNG draw). Measured (PyBoy S127, the user's save): an
every-gate room at party level 10 (row value 57 %) → served on floor 2 of gate 0 in 50 of
84 RNG samples; with `once_per_dive` never again on floors 3-6 of that dive.

**Wandering NPCs in vanilla gates (asked S127):** they are not level-based — §4.3's
placement pass keeps one by the floor's contents row (0 / 13 / 26 / 38 of 256); the S127
"chance by level" is the project's own rule for its rooms.

## 7.7 Custom boss floors, hand-made gates (S101, ROADMAP P3.7b part 2) — built, PyBoy-verified, NOT yet user-tested

**The boss floor.** Bank $16 entry 5 serves the boss when `wCurrentFloor ==
wLastFloor − 1` from `GateFloorDataTable` ($16:$70A6, 32 × 8 B per gate id):
byte 3 = floor count (incl. the boss floor), byte 4 = boss map, bytes 5/6 =
arrival TILE (pixels = 16·b + 8), byte 7 = depth tier (only reader: the bank
$01 item tier). The path (`jr_016_5be1`) has **no RNG** — so a custom boss
floor is DATA only: byte 4 = the custom mapID, 5/6 = the room's
`gate_arrival` cell (screen-grid absolute). The table is a compiler-owned
region (`; @BUILD_PROJECT BEGIN gate_floor_table`, emitter `gates16`) fed by
`custom.gates[]` (PROJECT_COMPILER §2.17); a gate without settings keeps its
vanilla 8 bytes, so the example project's region is byte-identical to the
ROM. Bytes 0-2 (floor-type rows) and 7 (depth tier): the vanilla values unless the
gate sets `maze_row` / `special_row` / `contents_row` / `depth` (S120, §2).

**What happens in the boss room** is the room's scripts — nothing in bank
$16. Vanilla (28 boss rooms): the entry script sets `D92B = 6`; the
talk/examine script fights with `$5A` EID (single, `DA09 = 3`) or `$5B`
(preset: `DA02 = count − 1`, EIDs at `DA03/05/07`); the WIN resumes the
script (a LOSS never returns: castle, half gold); the win tail sets the
cleared flag, `D92B = 7`, then `$3B $0000,$00E8,$0058` — the wavy fade to the
Castle (map $00, pixel (232, 88) = screen 1 tile (4,5)). Rooms have state 0
(boss present) and state 1 (cleared, walk-on exit home). The "helper" who
flies in first is NPC sprite **$21**; its text box says "Watabou:" (the FAQ
agrees). Custom boss rooms express the same event as a **conversation**
(`talk.steps`, PROJECT_COMPILER §2.18): battle → (join, engine) → flags →
helper → any destination. Measured S101 on the user's save: a 3-enemy talk
battle (EIDs 520/327/327) → win → join prompt → flag → helper → a custom
room; a 1-enemy branch chosen by a flag set on the room's other screen; a
fight on ARRIVAL (entry script; the post-battle reload does not restart it).
The helper (S101 r2: Warubou $39 by default) lands on the player's LEFT and
faces them — the fly-in is a fixed +48 / +43 px move from start pixels the
compiler computes from the player's tile at run time (PROJECT_COMPILER §2.18).

**The Castle arrival** (S101 r3, PyBoy-measured on the user's save, all 33
codes): Castle_Script00 on screen 1 dispatches on **`$D92B`**: 0 / 4 → the
new-game intro / story cascade; **6** (bank $07, the gate return — S125: this
is the **WarpWing item**'s use path; the vanilla boss exits do not write 6) and **8**
(bank $50 after a lost battle: `$6559` an ordinary loss, `$64AF` the lost Starry
Night / arena final; bank $06 `$6A39` the party wiped by damage floors) → `$0C:$490A` = the priest's
GreatTree blessing + heal (HP measured 1 → 999), `$D9E3 := $FF`; **7** (the
vanilla boss win tails) → `$0C:$47E0` = the King's speech chain on
**`$D9E3`** — one speech per gate boss ($30 Healer, $31 Dragon, … $4E
DeathMore, $C7 Sidoh, $10 Copycat; `conversation.KING_SPEECHES`); every
speech ends with `$D92B := 3` (5 for post-game codes); an unknown code falls to
the priest path; 1-3 / 5 = no event. **S132 (decode + PyBoy):** the boss room's ENTRY
script writes `$D92B := 6` on arrival (Gate of Beginning: script 0 pos 0 — so a WarpWing
out of an unbeaten gate gets the priest's heal); the WIN branch writes `$D9E3` (the
speech) and then `$D92B := 7` right before the win tail (script 1 pos 69 / 74 → the tail
at `$0E:$4EF6`). `editor2/core/story_state.py` runs these tails + the Castle's speech
(`tools/census_story_state.py`: every gate == PyBoy). **S125 — the hub:** those four engine sends now
call bank $71 entry 9 `HubWarp` (same size); a project's `custom.hub` can send the
player to one of its rooms instead, the Castle path above stays byte for byte when the
hub is the Castle or unset (PROJECT_COMPILER §2.38). **S124 correction** (ROM bytes `$0C:$49F2`
`FF03 0009`; the editor's flag index, game scripts): speech **`$30`** (the
Beginning boss — "Oh, [HERO]! Did you bring back Hale…") DOES set a saved flag,
**`$0009`** ("go to the arena"), and writes `$D92C` / `$D92D` / `$D92F` / `$D93C` (the
Gate Hub door to the next rooms) — "changes NO saved flag" holds for the other
codes only (DOC_AUDIT S124).
`$D9E3` has one other reader, a castle NPC at `$0C:$5066` ($30 / $3C lines,
else the herb). The helper step's *at the Castle* option writes these
before its `$3B` warp (PROJECT_COMPILER §2.18).

**Music.** On the floor before the boss, vanilla switches to the boss song
by `RoomBGMTable[wBossMapType]`, which overruns for custom maps; bank $71
entry 2 `CustomRoomBGMResolve` now returns that custom room's own song (or
$34) when `wBossMapType ≥ $6B` and `wCurrentFloor == wLastFloor − 2`.

**Vanilla boss rooms on other gates** (`boss: "vanilla:$xx"`): byte 4 = that
map, 5/6 = the owning vanilla gate's spawn (`extracted/gate_names.json`
`boss_spawn`). Measured: Talisman (gate 2) → the Villager Dragon room at
(1,6). Its vanilla scripts run unchanged (vanilla flags included).

**Hand-made gates** (`hand_made: true`): `GateDecisionFork` already runs on
floor 0, so rules may take floor 1; every floor should be a room served
always (validator warning otherwise; the floor plan shows the maze where
none is). Measured: Gate of Beginning, 3 floors — floor 1 / floor 2 custom
rooms at 100 %, their Stairs down descend, floor 3 = a custom boss room.

**Encounters per gate floor (S114, ROADMAP P3.13a):** which LIST a gate floor draws from
(the vanilla breakpoint rule, or the gate's own per-floor plan + flag variants, or a served
room's own list) is chosen by bank $76 `EncResolve` behind the bank $01
`LoadNextDungeonFloor` fork — DATA_STRUCTURES "Encounter list choice (S114)",
PROJECT_COMPILER §2.30. Gate numbers ≥ 32 are the project's NEW gates (S115, §7.8).

## 7.8 New gates — gate numbers 32-95 (S115, ROADMAP NG1) — built, PyBoy-verified, test ROM USER-CONFIRMED 2026-10-03 12:39 ("Excellent, confirm works")

**What reads the gate row.** `GateFloorDataTable` ($16:$70A6, 32 × 8 B) has exactly two
readers, both in bank $16 entry 5 (`label16_5b4e`): `jr_016_5b72` (bytes 0-3 + 4 + 7 →
wFloorType1-3, wLastFloor, wBossMapType, wBossTileset) and `jr_016_5be1` (row + 4: the
boss map and arrival tile). Both compute `ld a,[wGateID] / add a ×3 / ld hl,X / add l /
ld l,a / ld a,0 / adc h / ld h,a` — an 8-BIT gate·8, so in the original a gate number n ≥
32 reads the row of gate n & 31. Entry 5 sets `wGateID := wMapID` on the first floor of a
dive (wInGateworld bit 7 clear) — a portal exit's dest IS the gate number, nothing reads
it as a map id before that (only bank $73 entry 0, the transition commit, runs first).
Every other gate-number user is 8-bit and table-free: `GateDecisionFork` (gate 0 = no
special rooms), bank $71 `CustomGateInsert` (`wGateDiveGate` = gate+1), the Anchor
(bank $73), bank $76 `EncResolve` / `GatePlanPtrs` (index 0-255). No vanilla script
reads `$C935` (ROM-wide search S115).

**Patched (same size, `patches/bank_016.asm`):** both readers are `call GateRowPtr` +
nops (15 → 15 B; the boss site adds `inc hl` ×4). `GateRowPtr` (bank $16 free tail,
$7CFD): gates 0-31 → `GateFloorDataTable + gate·8` (unchanged bytes); gate ≥ 32 → `ld
hl,$7601 / rst $10` = bank $76 **entry 1 `NewGateRowCopy`**: a project new gate (32 ..
32 + NEW_GATE_LEN − 1) has its 8-byte row copied from `NewGateRows` to **`wGateRowBuf`
($D138)** and returns E = 1 → HL = wGateRowBuf; any other number returns E = 0 → the old
wrap (gate & 31), byte-for-byte what the original read. `EncVanillaNumber` (bank $76)
walks the vanilla encounter rule of a new gate's SOURCE (`NewGateSource`), so its floors
with no list of their own — and the floor value (`wEncounterPoolIndex`, the tier-3 floor
gold) — are the source gate's.

**A new gate's row** = the source's row with the project's floor count (byte 3) and boss
room (bytes 4-6) — so bytes 0-2 (floor-type rows: the maze look and the special rooms on
floors 3, 6, 9 …) and byte 7 (depth tier: the item tier) are the source's unless the gate
sets its own (S120, §2 / PROJECT_COMPILER §2.17). Gate 0
as a source keeps "no special rooms" only for gate 0 itself (`GateDecisionFork` tests
`wGateID == 0`); a copy of gate 0 gets special rooms like any gate (code-read, not
measured).

**Entrance:** the vanilla portal exit row — trigger cell, dest = the gate number,
gate_flag 1, screen byte 0, spawn 0,0 (all 34 vanilla portal exits,
`extracted/all_exits.json`). The dive starts on floor 1 (the maze of the source's floor
type 1).

**Measured S115 on the user's save** (demo: new gate 32 "Ember Gate", copy of Memories,
4 floors, boss = custom room $72, entrance = a painted hole in custom room $71): the hole
→ wGateID 32, wCurrentFloor 0, wLastFloor 4, wBossMapType $72, wFloorType2/3 = 1/2,
tier 1, wGateRowBuf = `02 01 02 04 72 04 06 01`, `GateRowPtr` and `NewGateRowCopy` each
ran once, map $0D (Memories' maze); floor 1 battles from list 128 (the project's), floor
3 a special room ($50 / $51) or the maze depending on the RNG, battles from list 129;
floor 4 = $72 at tile (4,6); its conversation battle (EID 51) → join → helper → the
Castle (priest blessing). Gate 2 on the same build: its vanilla row. Stub calls of
`GateRowPtr` for gates 0-40 / 95 / 96 / 200 / 255: HL = the table row for 0-31, $D138 for
32, the wrap row for every undefined number (0 bad).

## 7.9 Gate swirls and "cleared" (S117, ROADMAP NG2) — built S117, PyBoy-verified, NOT yet user-tested

**What the game does (measured S117, PyBoy on the user's save + the scripts).** A portal
looks like a portal because of two things: (1) the **still swirl** — background art (in
room $24, the Villager / Talisman room: sheet tiles $20-$23, palette 3), always there;
(2) a **spinning swirl object** — an NPC with sprite `$4D` and no script (`$FF`) standing
on the portal cell. The objects are ordinary entries of the room's step-indexed NPC lists:
the boss's win script sets the gate's **cleared flag** and advances the portal room's
step counter, and the next step's list no longer has that swirl (room $24, counter
`$D969`: 0 = both swirls spin, 1 = only Talisman's, 2 = only Villager's, 3 = none). The
swirl NEVER blocks the portal — a cleared gate is still entered. On the user's save
Villager is cleared (`$0011` set), Talisman is not.

**Cleared flags** (`tools/map_gate_names.py` → `extracted/gate_names.json`
`cleared_flag` / `cleared_flags`, from each boss room's win script: `$FF03 F` …
`$FF12 $D92B $0007`): gate n = `$0010 + n` except Wisdom (13) `$001A`, Farm (11) `$001B`,
Joy (12) `$001C`, Anger (10) `$001D`; Medal (17) `$0021` (its boss lives in room $41),
Demolition (23) `$0027` + `$0028` (Sidoh); gate 31 (unused) none.

**What the editor needs** (user S117: "Boss cleared - no swirly. Boss cleared BUT we are
inputting new boss or redirecting to new gate - swirly"): a swirl that follows the flag
of the gate the portal ENTERS — a new gate's, or a vanilla gate's that now has a custom
boss (whose vanilla win script no longer runs), or another gate's when a vanilla portal is
re-routed.

**Engine (patched builds, all same-size forks):**

- **NPC lists for every room — bank $0B `GetRoomDataPtr`.** The only reader of a room's
  NPC / interact list (NPC load, `TalkScanExamineSpots`, `SearchStepTriggers` all come
  here). After its gate test (gate floors keep the vanilla path) a same-size 21-byte
  rewrite calls **bank $60 entry 1 `CustomReadInteract`** for EVERY non-gate room (the
  exits' entry-7 "divert" pattern): HL ≠ 0 = the list to parse, HL = 0 = the vanilla
  `SharedPtrChase` path, byte-for-byte as before.
- **`CustomReadInteract`**: custom rooms → `CustomPtrChase` → `CopyNPCListToBuffer`;
  vanilla rooms → `VanillaNPCExtTable` (compiler-generated; rows `db mapID, screen / dw
  step counter / db n_steps / dw list ×n`, `$FF` ends; variant = min([counter], n − 1))
  → `CopyNPCListToBuffer`, or HL = 0 when the room has no row (the vanilla list).
- **`CopyNPCListToBuffer`** — **condition prefixes**: a 5-byte entry `$A0` / `$A1, flag
  lo, flag hi, $FF, $FF` is not copied; it makes the NEXT NPC shown only while the flag
  is SET (`$A0`) / CLEAR (`$A1`) (`TestEventFlag`; several prefixes AND). A failed one
  sets the NPC's **hidden bit** (type bit 6: not drawn, not solid, not talkable, S97), so
  every later NPC keeps its slot. Spots (bit 7) are copied verbatim.
- **The cleared mark — bank $50 `BattleExitHandler`.** Its boss-win branch (win, `$DA09 ==
  3`: every scripted boss / conversation battle) ended `ld a,$0E / ld [$C8ED],a / ret`;
  now `ld hl,$7602 / rst $10 / ret / nop` → **bank $76 entry 2 `GateBossWin`**: performs
  the displaced store, then — only on a boss floor (`wInGateworld` 0, `wMapID ==
  wBossMapType`, `wCurrentFloor + 1 == wLastFloor`) of a gate < `GATE_CLEAR_LEN` — sets
  that gate's `GateClearTable` flags (`dw own, vanilla`; `$FFFF` = none).
- **Own cleared flags** live in the extended flag range (EVENT_FLAGS "Extended flags
  (S117)"): **`$17A0 + gate`** (gate 32 = `$17C0`). A new gate and a RE-BOSSED vanilla
  gate (a custom boss floor) use their own; GateBossWin also sets a re-bossed gate's
  vanilla flag (so the game's story checks still see it cleared). An unchanged vanilla
  gate's row is `$FFFF, $FFFF` — its own win script sets its flag, as in the game.

**Compiler (PROJECT_COMPILER §2.32):** an NPC entry's `swirl_of: N` → an `$A1` prefix on
gate N's cleared flag; `shown_when: [{flag, is}]` → `$A0` / `$A1` prefixes (≤ 8).
`Project.vanilla_swirl_overrides()` makes the `VanillaNPCExtTable` rows: for each vanilla
portal (its exit rows' valid steps, `entrance_redirects` applied) that enters a re-bossed
gate or is re-routed, every step variant of that room's list gets the swirl object on
that cell conditioned on the entered gate's cleared flag (the vanilla swirl entry gets
the prefix; with no swirl at that cell and < 8 NPCs one is appended). The example project
has none (the table is a lone `$FF`, `GateClearTable` rows all `$FFFF`).

**Editor:** "Gate entrance here…" adds the swirl object (`swirl_of`) and paints the
still swirl (`paint_swirl`: room $24's swirl metatile, its tiles borrowed into the room);
Rooms tab (vanilla room, a portal exit selected) → **Lead this portal to another gate…**
(an `entrance_redirects` row `dest gate:N, gate_flag 1`); flag pickers list
`gate:N cleared — name` (`resolve_flag_ref`); the Gates tab names each gate's cleared flag
and its re-routed portals; help 60_gates.md "Swirls and cleared".

**Measured S117 on the user's save** (demo = the user's project + "Portal Hall" $71 behind
the GreatTree 2F Library door with entrances to new gate 32 "Swirl Gate" (copy of
Beginning, 2 floors, boss room "Swirl Throne" $72), Villager and Talisman; the $24 (2,2)
Villager portal re-routed to gate 32 — NOT in their project): the hall shows the gate-32
and Talisman swirls, Villager's hidden (its `$0011` is set); room $24 shows (2,2)'s swirl
(now gate 32's) and Talisman's; gate 32 dive → the boss conversation battle → GateBossWin
hit once, `$17C0` set → back in the hall and in room $24 the gate-32 swirls are hidden,
the rest unchanged. A/B old vs new engine over the user's project: 212 vanilla screens'
NPC slots identical except room $23 (gate 0 there has the user's custom boss "SBOSS", so
its swirl now spins until that boss is beaten), the 25 custom screens identical.
**Residual (S117):** a custom boss win did not advance the vanilla portal room's step
counter. **FIXED S122 (built, PyBoy-verified, NOT yet user-tested):** the game's own
win scripts do it in their TAIL — after `write_ram $D92B 7` (the Castle return; the
S117 text "the boss script moves the portal room's step counter" was right, the tail
was simply past the window `cleared_flags` read): e.g. Villager `write_ram $D969 1`,
`write_ram $D977 1`, `if_flag_clear $0012 → end`, `write_ram $D969 3` (both portal
gates cleared), then `close_text` / the warp. `tools/map_gate_names.py` decodes every
gate's tail (branches followed, up to the first op that is not bookkeeping) into
`gate_names.json` `win_tails`; a re-bossed vanilla gate's `GateClearTable` row (now 6
B: own flag, vanilla flag, **`dw WinTail`**) points at a compiler-made copy of its
tail(s) (`encounters.win_tail_programs`: jump targets relabelled, the closing op → the
next tail; Demolition: Hargon's then Sidoh's tail + `set_flag $0028`), which
**`RunWinTail`** (bank $76) interprets: `$12` / `$13` write byte / word, `$03` / `$02`
set / clear flag, `$00` / `$01` jump when the flag is clear / set, `$14` jump, anything
else ends. Measured: stub-calling `GateBossWin` on a faked boss floor of re-bossed
gates 0 / 1 / 2 / 5 / 23 with random starting flags, 20 / 20 times the RAM and flags
equalled the tail run in Python. The Castle-return code `$D92B` and the King's speech
code `$D9E3` stay the custom boss flow's business (the conversation's Helper step).

## 7.10 Gate themes in custom rooms (S122, ROADMAP P3.7b part 2) — built S122, PyBoy-verified, NOT yet user-tested

User (S122): "can I currently use gate themes for custom room build? … I would love to
use them for custom rooms as an option for tileset, properly coloured" + "the option of
starting with gate tiles/palettes then borrowing additional tiles elsewhere".

**Engine: nothing new.** A custom room's record (`$26DD`-style row, PROJECT_COMPILER
§2.11) with `gfx_bank $28`, `gfx_id` = the type, threshold `$30` loads that floor
type's sheet; its four palettes are an ordinary project palette (custom rooms load
slots 0-3 — the same four the maze uses, §7); a screen copied from `MazeScreenTable` +
`GateAttrTable` is an ordinary layout + attr item. Outside a gate (`wInGateworld` = 0)
the theme's special tiles are inert: the damage floors (`$38-$3B`) do no damage
(`ApplyFloorDamage` runs only in gate mode or the `CheckSpecialMapExits` maze maps) and
the stairs (`$3C-$3F`) do nothing (bank `$0B` reaches the gate-exit check
`Jump_00b_46a7` only through `jp nz` on `wInGateworld`). Rooms on a theme never animate.

**Measured (PyBoy, the user's save):** a room created with *New room → gate theme 4*, a
second screen filled from a maze screen, and SBOSS switched to theme 9 + its colours —
4 / 4 screens: the game's screen == the editor's preview on every tile not under a
sprite. The S122 demo (Ice Gallery / Forest Gallery) is walked end to end (PROJECT_STATE
S122).

**What a theme room has:** sheet slots `$00-$3F` are the theme's (the room's protected
VOCABULARY — `Document.room_sources_vocab`); the 15 maze metatiles (tiles + per-subtile
palettes, harvested from the 254 screens) + the stairs are its picker vocabulary;
**`$40-$7F` (64 slots) are free — all on the walkable side** of the `$30` split. A
borrowed WALL tile therefore needs a wall slot: the maze's 48 wall slots are all
vocabulary, so the borrow offers to release the room's unused vocabulary first
(`VocabReleaseWouldHelp`, one undo step; a room built from a few maze screens leaves
a dozen or more unused). A sheet copy (own copy / a borrow) keeps its origin, so the
room stays the theme.

## 7.11 Worlds — hand-made places entered like a gate (S123, ROADMAP NG3) — built S123, PyBoy-verified, NOT yet user-tested

User (S123): "a world that can have encounters, encounter-free rooms (where you can also
save), mini-bosses, endbosses, flags and triggers. Enter via swirling portal …" +
"Entering should be JUST like entering a gate. Losing: Same as a gate."

**Engine: the game's own gate path, nothing new.** A world is a new gate (32-95) of 2
floors, hand-made: its portal is an ordinary gate entrance (exit flag 1, §1), so the entry is
the game's portal whirl (since S123 r2, below); floor 1 is served
from bank $71 `GateInsertTable` at 100 % = the world's start room.

**The entry effect (S123 r2).** Before r2, bank $0B `CustomDescentInGate` (§7.5.1) gave
EVERY gate-flag exit of a custom room the in-gate floor-change feel, so a portal in a
custom room ran the descent ladder (`$C905` states `$10-$17`, sound `$55`, the closing
whoosh) — user r2: "should be a full start-of-gate effect (screen whirling around and
slowly vanishing)". Now only a Stairs-down exit (gate flag `$80`) gets that feel (bank $60
entry 12 `CustomDescentFeel`); a gate entrance (flag 1) keeps `wInGateworld` 0 and runs the
vanilla portal flow. Measured (PyBoy, the user's save): room `$24`'s vanilla portal =
states 1 → 2 (+31 frames) → 3 (+245) → 4 (+64) → 5 → map change (+6), sound `$52`; the
Rift Gate Hall portal after the fix = the same states at the same intervals (+31 / +241 /
+64 / +1 / +5), sound `$52`; a Stairs-down cell in a world room still `$10-$17` + `$55`.
The S123 r1 claim "wave + cream fade, measured" came from a warp injected from a VANILLA
room — it never ran the custom-source path (KEY_LESSONS S123 r2). The other rooms are
reached through ordinary custom doors, which leave the gate: `wInGateworld` = 0 there (as
in any custom room). Consequences, all measured on the user's save:

- **Losing** in a world room runs bank $50 (the same handler serves every room)
  `BattleExitHandler`: Castle screen 1, the priest heals, half the gold (3800 → 1900).
- **Saving:** bank $07 `SaveAllowCheck` + the room flag byte decide (JOURNAL ok in a calm
  room, refused in a battle room, per the world's rule).
- **Battles:** each room's own list (S114, `wCustomEncList`), flag variants switch it
  (measured: list 0 before, list 9 after `gate:32`; EIDs 20 / 25 / 26).
- **Clearing:** `GateBossWin` (bank $76) needs floor 0+1 == the last floor (2) and never
  fires; the world's `gate:N` (`$17A0+N`) is set by the end boss's conversation (measured
  `$17C0` set after the Rift King).
- **The swirl:** hidden (`$A1`, S116) or — `cleared_swirl` — drawn in an OBJ palette
  through the S123 NPC colour path (measured: the hall's swirl in palette 1 after clearing).
  The still swirl tiles under it keep the room's BG colours.
- **Music:** a world room without its own song keeps whatever plays (the gate theme after
  the portal).

The 8 OBJ palettes (`$17:$5615`, by colour 2): 0 grey/red, 1 green (0,25,5), 2 blue (the
swirl's own, sprite `$4D`), 3 yellow, 4 purple, 5 grey, 6 orange, 7 brown (`$05:$4152`
holds each sprite id's own palette).

## 8. Floor completion / exit ✅

- **Down-staircase**: `Jump_00b_46A7` checks `wScreenIndex == [$C960]` and the
  player's sub-tile position; on the staircase it sets `wIsPlayerChangingMaps`,
  `wWarpGateId = 0`, `wWarpFlag = $80`, then re-enters floor setup (entry 5) which
  increments `wCurrentFloor`.
- **Per-step special handling**: `$0B:Jump_00b_4674` lists the map types that get
  per-step processing inside a maze (`$53` ForestMaze, `$54-$56` Conveyors,
  `$57-$59` Mazes, `$61-$64` the forest maze's other rooms — S131) and routes to `$16` entry 8 (`$1608`).
- `Call_00b_46DA` scans the grid (`$C940`/`$C950`) counting occupied screens — used
  for floor-clear / special completion bookkeeping (count 16 → `$C92D=5`,
  count 2 → `$C92D=6`).

---

## 9. WRAM map (gate generation) ✅

| Addr | Name | Meaning |
|------|------|---------|
| `$C935` | `wGateID` | current gate (0–31) |
| `$C936-8` | `wFloorType1/2/3` | the three rolled floor-type indices |
| `$C939` | `wCurrentFloor` | current floor number |
| `$C93A` | `wLastFloor` | floor count before boss |
| `$C93B` | `wBossMapType` | boss room map type |
| `$C93C` | `wBossTileset` | **depth tier 1/2/3** (tileset + item tier) |
| `$C93F` | `wShapeMode` | macro-shape mode (`[$6056 + RNG%5]`) |
| `$C940-F` | `wFloorGrid` | 4×4 screen grid, `(piece<<4)|variant`; `$Fx`=empty |
| `$C950-F` | — | paired per-cell state buffer |
| `$C960` | `wStaircaseScreen` | screen index holding the down-staircase |
| `$C962-$C963` | — | the stairs' tile offset in the 32-wide screen map (S122) |
| `$C964-$C967` | — | the stairs' absolute pixel X / Y (S122) |
| `$C926` | — | wandering NPC's screen (`$FF` = none); `$C927-$C92A` its pixels (S122) |
| `$C92B` / `$C92C` / `$C92D` | — | NPC kind (→ bank $0B `GatePtrTable_42c8`) / sub-kind / explored state (S122) |
| `$C93D` | — | maze size (the encounter list +25 byte; 3-15 safe, §4.2) |
| `$C0A0-$C0A4` | — | arrival screen + pixels (S122; the carve uses `$C0A0-$C0A4` for class counts first) |
| `$C0A5-$C0A8` | — | stairs pixels within the screen (S122) |
| `$C0A9` | — | try counter (64 per placement pass, 16 per item) |
| `$C0AA-$C0AF` | — | item candidate pixels / kind `$C0AE` / arrival screen `$C0AF` (S122) |
| `$C0B0-$C0B8` | — | the 3×3 "blocked" map of `MazePassableTest` (S122) |
| `$C500` | — | `MazePickPiece` candidate list [piece, running share] … `$FF $FF` (S122) |
| `$C100-F` | — | per-screen content state (placement) |
| `$C969` | `wInGateworld` | 1 = generated maze mode; 0 = fixed template / overworld |
| `$DEBC` | `wGateDiveGate` | S100 patched: wGateID+1 of the dive in progress (0 = none); SRAM `$BFCA` |
| `$DEBD` | `wGateDiveMask` | S100 patched: once-per-dive rule bits served this dive; SRAM `$BFCB` |
| `$C300` | — | screen tile-id shadow buffer (read for standing-tile lookup) |
| `$AA` (HRAM) | — | tile id under the player; behavior class = `$AA >> 2` |
| `$CB0B` | — | party slot 0 status byte (`+$0B`); bit7 set = skipped by floor damage |
| `$CA8D` | — | active (front-line) party count |
| `$D793` | — | floor item list `[kind, sub-kind, X, Y]` (absolute metatiles), `$FF` end (S122) |

---

## 10. Code map (gate generation) ✅

| Address | Label | Role |
|---------|-------|------|
| `$16:$5B4E` | `label16_5b4e` (entry 5) | descend / advance floor; first-entry init |
| `$16:$5B72` | — | load `GateFloorDataTable[wGateID]` → wFloor* |
| `$16:$5BBF` | — | STANDARD path: roll FloorType1 → `wMapID` |
| `$16:$5BE1` | — | BOSS path: load boss room + spawn |
| `$16:$5C1C` | — | SPECIAL path: roll FloorType2 → `rst $00` dispatch |
| `$16:$5C50…` | — | special-room handlers (set `wMapID`, `wInGateworld=0`) |
| `$16:$5FC0` | `SelectFloorType` | weighted threshold roll |
| `$16:$7CB9` | `GateDecisionFork` | patched tree: anchor / custom room (bank $71 entry 4) / gate 0 / vanilla (§7.6) |
| `$71` entry 4 | `CustomGateInsert` | patched tree: `GateInsertTable` rule walk (§7.6) |
| `$07:$6061` | `SaveAllowCheck` | JOURNAL permission ladder (label S100; patched same-size rewrite, §7.6) |
| `$06:$6034` | `FieldStateDispatch` | bank $06 entry 6, per-frame field router (S100; bit 5 → `MapTransitionMachine`) |
| `$16:$5FE4` | `label16_5fe4` (entry 6) | map-overview VRAM + grid build kickoff |
| `$16:$605B` | `MazeBuildFloor` (= `label16_605b`) | the floor builder (§4) |
| `$16:$616C` | `MazePlacements` | stairs / NPC / arrival / item count (§4.3) |
| `$16:$6432` | `MazePlaceItem` | one floor item (§5) |
| `$16:$63AF` / `$6585` / `$661B` / `$66AE` | `MazePickItemSpot` / `MazePickNPCSpot` / `MazePickArrivalSpot` / `MazePickStairsSpot` | screen + metatile tries (§4.3) |
| `$16:$6955` / `$6AFB` / `$6C96` | `MazeItemPassable` / `MazeStairsPassable` / `MazePassableTest` | the 3×3 passage test |
| `$16:$68C6` / `$68EA` / `$690E` | `MazeAtStairs` / `MazeAtArrival` / `MazeItemRowTaken` | spot clash tests |
| `$16:$6F05` | `label16_6f05` (entry 8) | per-step encounter decrement |
| `$16:$7033` | `LoadFloorDataPointer` (entry 9) | the cell's screen layout `[id, bank]` from `MazeScreenTable(B)` (§7) |
| `$16:$6800` | `MazePickPiece` | weighted piece with required / forbidden openings |
| `$16:$6744` | `MazeCellConstraints` | a cell's required / forbidden openings |
| `$0B:$4027` | — | tileset-table select (gate vs normal) |
| `$0B:$4674` | `Jump_00b_4674` | per-step special-room map-type list |
| `$0B:$46A7` | `Jump_00b_46a7` | down-staircase exit at `$C960` |
| `$0B:$46DA` | `Call_00b_46da` | grid scan / floor-clear count |
| `$01:$5AD0…` | — | ground content + `wBossTileset` item-tier |
| `$01:$5B68…` | — | item/gold pickup handlers (`$D78F`) |
| `$01:$5E23` | `jr_001_5e23` | **ApplyFloorDamage** (per-step damage-tile handler) |
| `$01:$5E7D` | — | **FloorDamageTable** (16 B, by floor type) |
| `$00:$1E31` | `TileAtPixel` (was `WaitInputRelease`) | tile id at pixel `$FFA5-$FFA8` → `$AA`, walkable → `$A9` (S122) |
| `$00:$1E96` | `TileBuffer_1E96` | standing-tile lookup → `$AA` (+ behavior class) |
| `$17:$4064/$40DA` | — | gate per-screen attr/palette (`GateAttrTable_A/B`) |
| `$00:$2A5D` | — | gate-room tileset table (8 B/entry) |
| `$00:$2DA7` | `ScreenOriginTable` | per-screen pixel origin, 16 × 4 B (re-sectioned S122) |

### Data tables (bank `$16`)

| Address | Label | Notes |
|---------|-------|-------|
| `$16:$6056` | `MazeShapeModes` | 5 bytes `0,0,0,1,2`, `[RNG1 % 5]` → `wShapeMode` |
| `$16:$7055` | `MazePieceTable` (was `FloorTypeSortData`) | 16 × 4 `[openings, piece, weight class, 0]` + `$FF` |
| `$16:$7096` | `MazeCellOrder` (was `FloorTypeOrderTable`) | the carve's cell visiting order |
| `$16:$70A6` | `GateFloorDataTable` | 32 × 8 (§1) |
| `$16:$71A6` | `FloorTypeSelectionTable` | 16 × 16 |
| `$16:$72A6` | `FloorTypeSelectionTable2` | 16 × 8 |
| `$16:$7326` | `FloorTypeSelectionTable3` | 16 × 16 (bytes 9-11: item count base / range / blocking %) |
| `$16:$7426` | `MazeItemSubKind` | 16 B by item kind (was read as table 3's 17th row) |
| `$16:$7436` | `FloorLayoutData` | 16 × 48 B: item sub-kind odds by contents row |
| `$16:$7736` | `MazePatterns` (was `FloorTilePatterns`) | 21 ready-made 4×4 grids (shape mode 2) |
| `$16:$7886` | `MazeNPCChance` | wandering-NPC threshold by contents row |
| `$16:$7896` / `$7A96` | `MazeScreenTable` / `MazeScreenTableB` | 256 × `[layout id, bank]` by cell byte (§7) |
| `$17:$5215` | `GateAttrTable_A` | 256 × 2 (attr_idx, attr_bank) |
| `$17:$5415` | `GateAttrTable_B` | 256 × 2 (shape mode 2) |
| `$17:$476F` | `AttrPtrTable` | normal-room palette/attr root, by mapID (§7.1) |
| `$17:$51F5` | gate floor palette table | by floortype; `$D` → `$629D` (§7.1) |
| `$17:$5615` | object palette block | 8 global object palettes, every room (§7.1) |
| `$17:$629D` | gate floortype-`$D` palette | the maze-tileset BG palette (slots 0–3) |

---

## 11. Answers to the driving questions

- **How rooms are generated** ✅ — standard floors are a runtime-carved 4×4 maze
  grid with random staircase/items + 64-retry regen; special/boss rooms are fixed
  templates substituted in.
- **Can we guide it** ✅ — three same-size data levers: `GateFloorDataTable`,
  the three `FloorTypeSelectionTable`s, and `MazePatterns` / `MazeShapeModes` (S122 names).
- **Reuse maze tilesets in custom rooms** ✅ — yes; same tileset/attr tables.
- **Insert new special rooms / link custom-bank rooms** ✅ — yes, via a `rst $00`
  dispatch slot that sets `wMapID = <custom id>` + a `FloorTypeSelectionTable2`
  weight; dovetails with the existing `wInGateworld=0` custom-room path (§6).
- **Annotation** ✅ (S122) — the whole floor builder is labelled and commented in
  both trees (`MazeBuildFloor` … `MazePassableTest`, the data tables renamed by
  what they are; ROM0 `TileAtPixel` / `ScreenOriginTable`), byte-perfect; the
  special-room handlers were labelled S120. Loop-internal `jr_016_xxxx` labels stay.

---

## 12. Open items ❓

1. **Damage tiles** ✅ **RESOLVED (S37)** — fully traced; see §5.1. Detection =
   standing-tile behavior class `$0E` (tile ids `$38-$3B`) via `$AA`; amount =
   `FloorDamageTable` (`$01:$5E7D`) by floor type (red 5 / blue 10 / brown 2).
   Routines `$00:$1E96` and `$01:$5E23` annotated.
2. **`piece_id → screen tile-layout` map** ✅ **DONE S122** — `MazeScreenTable` /
   `MazeScreenTableB` + `GateAttrTable_A/B` by cell byte (§7), pixel-proved.
   Authoring NEW pieces = new layout streams + rows of those tables (not built).
3. **Full `rst $00` dispatch enumeration** ✅ **DONE S120** — the 8 slots of
   `SpecialRoomTable` ($16:$5C32, both trees labelled): §2 "The special picks (S120)".
   No slot is free (the table holds exactly the 8 indices `FloorTypeSelectionTable2`
   rows can roll); custom rooms insert before it (§7.6).
4. **`SetBrd_6744`/`SetBrd_6800` carve algorithm** ✅ **DONE S122** — §4.2 (the
   re-fit pass is the connectivity guarantee; sizes 1-2 can empty the floor).

## §12 Town → arbitrary gate floor re-entry (S73, PyBoy-measured)

The engine happily serves ANY floor of ANY gate from a cold town start:
write `wGateID` ($C935) and `wCurrentFloor` ($C939, 0-based) = target−1, then
kick a staircase-style transition (`wWarpGateId=0`, `wWarpFlag=$80`,
`wIsPlayerChangingMaps=1`, `$C88F++`). The commit stores `wWarpFlag` →
`wInGateworld` ($80, bit7 set = "subsequent floor"), entry-5 increments the
floor, loads the gate config, rolls and builds the floor, and the placement
pass positions the player — spawn mailbox values are ignored on maze floors.
Script-side this is one `map_transition $8000,$0000,$0000` after `write_ram`s
(the S73 Anchor return does exactly this; the gate/floor installs live in the
bank $73 commit hook because scripts can only write constants). The commit
hook runs BEFORE entry-5 in the same transition (measured), which is what
makes the install ordering work. Special-vs-standard is still rolled per
arrival — Anchor forces the standard path via a `GateDecisionFork` head
branch (`wAnchorArm==3`).
