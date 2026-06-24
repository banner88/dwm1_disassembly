# Gate Floor Generation — Technical Reference

> **Scope.** How a gate (portal dungeon) builds each floor: the procedural maze,
> the special-room substitutions, item/master placement, tileset/depth selection,
> and rendering. Distinguishes the **truly procedural standard floors** from the
> **fixed special/boss rooms**. Last verified against the ROM: Session 37.
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

---

## 3. Branch decision (standard vs special) ✅

After loading config (`$16:$5B72`), per non-boss floor:

```
if wCurrentFloor+1 == last_floor → BOSS floor   ($16:$5BE1): load boss room + spawn
else:
   if wGateID != 0  AND  wRNG1 bit4  AND  (RNG mod 3 == 2):
        → SPECIAL-ROOM path   ($16:$5C1C)
   else:
        → STANDARD maze path  ($16:$5BBF):
            wFloorType1 = SelectFloorType(FloorTypeSelectionTable[wFloorType1])
            wMapID      = wFloorType1
            wInGateworld = 1          ; engine treats wMapID as a generated maze
```

So gate 0 (Gate of Beginning) **never** takes the special path, and special rooms
are gated behind a ~1/3 roll on top of an RNG bit — i.e. occasional. ✅

---

## 4. Standard maze generation ✅🟡

Entry: `$16:$605B` (reached from entry 6, `label16_5FE4` `$16:$5FE4`, which first
DMAs the Select-button map-overview tiles into VRAM `$8500-$86C0`).

### 4.1 The grid (✅)

The floor is a **4×4 cell grid at `$C940-$C94F`** (16 screens max). Each cell byte:

```
high nibble = screen-piece id      ; $Fx (high nibble $F) = empty / wall cell
low  nibble = variant (0–11)        ; RNG mod 12, picks a layout variant of the piece
```

A paired 16-byte buffer at `$C950-$C95F` holds per-cell state. `$C960` holds the
screen index of the **down-staircase** (the "gate to the next floor").

### 4.2 Build strategy (🟡)

A macro-shape mode is rolled first: `wShapeMode = [$6056 + (RNG mod 5)]`
(`$C93F`, 5 modes at `$16:$6056`).

- **Mode 2** ✅ — copy a ready-made 16-byte pattern from `FloorTilePatterns`
  (`$16:$7736`, RNG-selected) straight into `$C940`. (Mode 2 also selects the
  alternate attribute table `GateAttrTable_B`, see §7.)
- **Other modes** 🟡 — carve a connected layout into `$C940` using
  `FloorTypeOrderTable` (`$16:$7096`, a 16-byte permutation of piece ids) and two
  primitives: `SetBrd_6744` (neighbour/connectivity test) and `SetBrd_6800`
  (place/link a piece). The exact carve algorithm (how connectivity is guaranteed)
  is understood in outline but not step-traced.

After the grid is built, a final pass folds in the per-cell `variant` nibble
(`swap` the piece id into the high nibble, `or` the `RNG mod 12` variant) — unless
shape mode 1 fixes the variant.

### 4.3 Placement passes (🟡)

Spawn point and staircase are placed by passes that use a **64-iteration retry**
(`$C0A9 = $40`); on exhaustion the whole floor regenerates (`jp $605B`). Player/
staircase screen coordinates are resolved through a ROM0 per-screen offset table
at `$00:$2DA7` (4 bytes/screen). The staircase screen lands in `$C960`.

`FloorLayoutData` (`$16:$7436`, 1120 B, indexed `wFloorType3 × 48`) is re-walked by
`SelectFloorType` during `LoadFloorDataPointer` (entry 9, `$16:$6F..`) to drive a
sub-selection within the chosen floor-type's 48-byte block. 🟡 (role: per-floor
feature/piece sub-selection; precise output mapping not fully pinned.)

---

## 5. Contents: items, gold, masters ✅🟡

`SaveBrd_6432` (`$16:$6432`, the FloorType3 path) is the **content placement** pass.
It scatters features onto generated screens, tracking per-screen content state at
**`$C100-$C10F`** and explicitly avoiding the staircase screen (`$C960`), the spawn
screen (`$C0AF`), and already-occupied screens. It uses `FloorTypeSelectionTable3`
to pick a feature type (`$C0AE`, with a `+$10` adjust on one branch) and a
16-iteration retry per placement.

The placed feature's data lives in a per-screen list at **`$D793`** — entries of
`[type/flags, ?, tileX, tileY]`. When the player's tile matches a feature
(`CheckFieldMovementAllowed`, `$01:$5A6E`-ish), it's processed by the pickup
handlers in bank `$01` (`$01:$5B68`+):

- `$D78F` = the feature id. `$FF` = empty marker; `$00` = **gold** (amount in
  `wGroundItemData`/`$D792`, formatted + added via `CompareGold`); else = an
  **item** id pushed into `wInventory`. Pickup plays SFX `$53`. ✅

**Item tier by depth** ✅ — bank `$01` (~`$5AD0`) reads `wBossTileset`:
tier `$01` → item id `RNG mod $0D + $07`; tier `$02` → `RNG mod $1E + $28`. So
late gates draw from higher item ranges. Masters/other feature types share the
same placement machinery (rarely rolled).

---

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
the table; `A` selects the entry). The table entries point at handlers at
`$16:$5C50, $5CB9, $5CEC, $5D0D, $5D2E, $5ED8, $5F4C, …`.

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

## 7. Rendering a generated floor ✅

- **Tileset graphics**: `$0B:$4027` picks the tileset table by `wInGateworld` —
  gate rooms use `$00:$2A5D`, normal rooms `$00:$26DD` (8 B/entry:
  `[gfx_ptr:2][spawn_data:6]`), indexed by `wMapID × 8`; the gfx pointer is DMA'd
  to VRAM `$9000`. Bank `$16` entry 5 (`$1605`) preps the tileset first.
- **Palette / attributes**: bank `$17` (`Jump_017_4064` / `Jump_017_40DA`) resolves
  per-screen attributes from `GateAttrTable_A` (`$17:$5215`) — or `GateAttrTable_B`
  (`$17:$5415`) when shape mode `$C93F == 2` — indexed by the grid cell at
  `$C940[wScreenIndex]` (256 entries × 2 B: `attr_idx, attr_bank`). The floor
  palette comes from `$17:$51F5[wMapID]`.

This is why **maze tilesets are reusable in custom rooms**: they are ordinary LZSS
layouts referenced through the same tileset/attr tables the custom-room pipeline
already manipulates.

---

## 8. Floor completion / exit ✅

- **Down-staircase**: `Jump_00b_46A7` checks `wScreenIndex == [$C960]` and the
  player's sub-tile position; on the staircase it sets `wIsPlayerChangingMaps`,
  `wWarpGateId = 0`, `wWarpFlag = $80`, then re-enters floor setup (entry 5) which
  increments `wCurrentFloor`.
- **Per-step special handling**: `$0B:Jump_00b_4674` lists the map types that get
  per-step processing inside a maze (`$53` ForestMaze, `$54-$56` Conveyors,
  `$57-$59` Mazes, `$61-$64` sub-rooms) and routes to `$16` entry 8 (`$1608`).
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
| `$C100-F` | — | per-screen content state (placement) |
| `$C969` | `wInGateworld` | 1 = generated maze mode; 0 = fixed template / overworld |
| `$C300` | — | screen tile-id shadow buffer (read for standing-tile lookup) |
| `$AA` (HRAM) | — | tile id under the player; behavior class = `$AA >> 2` |
| `$CB0B` | — | party slot 0 status byte (`+$0B`); bit7 set = skipped by floor damage |
| `$CA8D` | — | active (front-line) party count |
| `$D793` | — | per-screen feature list `[type/flags, ?, tileX, tileY]` |

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
| `$16:$5FE4` | `label16_5fe4` (entry 6) | map-overview VRAM + grid build kickoff |
| `$16:$605B` | `label16_605b` | the maze grid builder |
| `$16:$6432` | `SaveBrd_6432` | content (item/master) placement |
| `$16:$6F05` | `label16_6f05` (entry 8) | per-step encounter decrement |
| `$16:$6Fxx` | `LoadFloorDataPointer` (entry 9) | FloorLayoutData sub-selection |
| `$16:$6800` | `SetBrd_6800` | place/link maze piece |
| `$16:$6744` | `SetBrd_6744` | connectivity / neighbour test |
| `$0B:$4027` | — | tileset-table select (gate vs normal) |
| `$0B:$4674` | `Jump_00b_4674` | per-step special-room map-type list |
| `$0B:$46A7` | `Jump_00b_46a7` | down-staircase exit at `$C960` |
| `$0B:$46DA` | `Call_00b_46da` | grid scan / floor-clear count |
| `$01:$5AD0…` | — | ground content + `wBossTileset` item-tier |
| `$01:$5B68…` | — | item/gold pickup handlers (`$D78F`) |
| `$01:$5E23` | `jr_001_5e23` | **ApplyFloorDamage** (per-step damage-tile handler) |
| `$01:$5E7D` | — | **FloorDamageTable** (16 B, by floor type) |
| `$00:$1E96` | `TileBuffer_1E96` | standing-tile lookup → `$AA` (+ behavior class) |
| `$17:$4064/$40DA` | — | gate per-screen attr/palette (`GateAttrTable_A/B`) |
| `$00:$2A5D` | — | gate-room tileset table (8 B/entry) |
| `$00:$2DA7` | — | per-screen coordinate offset table (4 B/entry) |

### Data tables (bank `$16`)

| Address | Label | Notes |
|---------|-------|-------|
| `$16:$6056` | shape-mode table | 5 bytes, `[ + RNG%5]` → `wShapeMode` |
| `$16:$7055` | `FloorTypeSortData` | 16 × 4 (`type, idx, weight, pad`) + `$FF` |
| `$16:$7096` | `FloorTypeOrderTable` | 16-byte piece-id permutation |
| `$16:$70A6` | `GateFloorDataTable` | 32 × 8 (§1) |
| `$16:$71A6` | `FloorTypeSelectionTable` | 16 × 16 |
| `$16:$72A6` | `FloorTypeSelectionTable2` | 16 × 8 |
| `$16:$7326` | `FloorTypeSelectionTable3` | 17 × 16 |
| `$16:$7436` | `FloorLayoutData` | 1120 B, `wFloorType3 × 48` |
| `$16:$7736` | `FloorTilePatterns` | ready-made 16-byte grid patterns (shape mode 2) |
| `$17:$5215` | `GateAttrTable_A` | 256 × 2 (attr_idx, attr_bank) |
| `$17:$5415` | `GateAttrTable_B` | 256 × 2 (shape mode 2) |

---

## 11. Answers to the driving questions

- **How rooms are generated** ✅ — standard floors are a runtime-carved 4×4 maze
  grid with random staircase/items + 64-retry regen; special/boss rooms are fixed
  templates substituted in.
- **Can we guide it** ✅ — three same-size data levers: `GateFloorDataTable`,
  the three `FloorTypeSelectionTable`s, and `FloorTilePatterns`/shape-mode table.
- **Reuse maze tilesets in custom rooms** ✅ — yes; same tileset/attr tables.
- **Insert new special rooms / link custom-bank rooms** ✅ — yes, via a `rst $00`
  dispatch slot that sets `wMapID = <custom id>` + a `FloorTypeSelectionTable2`
  weight; dovetails with the existing `wInGateworld=0` custom-room path (§6).
- **Annotation** 🟡 — bank `$16` data tables + key entries are now labelled;
  the carve primitives (`SetBrd_6744/6800`) and the `rst $00` handlers still carry
  raw `jr_016_xxxx` internals. Comment annotations added this session; full label
  rename pass is a follow-up (needs ref updates, build-sensitive).

---

## 12. Open items ❓

1. **Damage tiles** ✅ **RESOLVED (S37)** — fully traced; see §5.1. Detection =
   standing-tile behavior class `$0E` (tile ids `$38-$3B`) via `$AA`; amount =
   `FloorDamageTable` (`$01:$5E7D`) by floor type (red 5 / blue 10 / brown 2).
   Routines `$00:$1E96` and `$01:$5E23` annotated.
2. **`piece_id → screen tile-layout` map** 🟡 — the grid encodes
   `(piece<<4)|variant`, but the table turning a piece id into the rendered
   screen's tile layout isn't fully pinned. Needed to author *new* maze pieces
   (vs. reweighting existing ones).
3. **Full `rst $00` dispatch enumeration** 🟡 — mechanism + ~7 handlers confirmed;
   enumerate every slot so reusable slots are known precisely.
4. **`SetBrd_6744`/`SetBrd_6800` carve algorithm** 🟡 — outline understood;
   step-trace pending for guaranteed-connectivity guarantees.
