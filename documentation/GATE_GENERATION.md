# Gate Floor Generation — Technical Reference

> **Scope.** How a gate (portal dungeon) builds each floor: the procedural maze,
> the special-room substitutions, item/master placement, tileset/depth selection,
> and rendering. Distinguishes the **truly procedural standard floors** from the
> **fixed special/boss rooms**. Last verified against the ROM: Session 39
> (palette derivation + the `$28`/`$0D` maze tileset arrangement, §7.1–7.3).
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

## 7.1 Deriving a room's runtime palette from ROM ✅ (S39, validated 30/30 + gate)

The engine does **not** infer colours — each room supplies its real colours and a
fixed rule fills the rest. Reproduced exactly against 30 in-game SameBoy dumps plus
the gate floor. Implemented in **`tools/derive_room_palette.py`** (`--map 0xNN` /
`--gate 0xNN`).

**BG slots 0–3 — the room environment. Only colour indices 0 and 2 are real.**
The engine **overwrites colour index 1 → `$6BFF` and index 3 → `$0000`** in *every*
BG palette at runtime (this is why every dump reads `_ 6bff _ 0000`). So to derive
a palette: read colours 0 and 2 from the room's palette block; force 1 and 3.

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
2. **Palette** — `CustomRoomPalPtr` (bank `$17` filler tail): one `dw` per room → a 64-byte
   palette. `$0000` = borrow vanilla; a real pointer is loaded by `CustomPalCheck` with
   **`b=$04` (slots 0–3 only)** — same hard rule as §7.3.
3. **Attr (per-position palette map)** — `CustomRoomAttr`: `db bank, base_entry` per room.
   `CustomAttrCheck` reads it, picks `base_entry` for screen 0 or `base_entry+2` for the
   second vertical screen, and decompresses from `bank` to `$C200`. `bank=$00` = vanilla
   fallback.

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

**Files:** `patches/bank_017.asm` (`CustomPalCheck`/`CustomAttrCheck` generalised +
`CustomRoomPalPtr`/`CustomRoomAttr`/`CustomPaletteColors_6C`), `patches/bank_000.asm`
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
