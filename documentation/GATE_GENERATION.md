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
  (place/link a piece). The carve count comes from `$C93D` = the floor's
  encounter pool +25 byte ("maze size", vanilla 3 / 8 / 15; S103 static read —
  DATA_STRUCTURES "Encounter pool entry", `gamedata.encounters[].maze_size`). The exact carve algorithm (how connectivity is guaranteed)
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
rooms (`wMapID < $6B`) are untouched. (KEY_LESSONS S41.)

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
ROM. Bytes 0-2 (floor-type rows) are still the vanilla values — private rows
per gate are open (ROADMAP P3.7b part 2).

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
new-game intro / story cascade; **6** (bank $07, the gate return) and **8**
(bank $50 after a lost battle, bank $06) → `$0C:$490A` = the priest's
GreatTree blessing + heal (HP measured 1 → 999), `$D9E3 := $FF`; **7** (the
vanilla boss win tails) → `$0C:$47E0` = the King's speech chain on
**`$D9E3`** — one speech per gate boss ($30 Healer, $31 Dragon, … $4E
DeathMore, $C7 Sidoh, $10 Copycat; `conversation.KING_SPEECHES`); every
speech ends with `$D92B := 3` (5 for post-game codes) and changes NO saved
flag; an unknown code falls to the priest path; 1-3 / 5 = no event.
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
floors 3, 6, 9 …) and byte 7 (depth tier: tileset + item tier) are the source's. Gate 0
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
| `$DEBC` | `wGateDiveGate` | S100 patched: wGateID+1 of the dive in progress (0 = none); SRAM `$BFCA` |
| `$DEBD` | `wGateDiveMask` | S100 patched: once-per-dive rule bits served this dive; SRAM `$BFCB` |
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
| `$16:$7CB9` | `GateDecisionFork` | patched tree: anchor / custom room (bank $71 entry 4) / gate 0 / vanilla (§7.6) |
| `$71` entry 4 | `CustomGateInsert` | patched tree: `GateInsertTable` rule walk (§7.6) |
| `$07:$6061` | `SaveAllowCheck` | JOURNAL permission ladder (label S100; patched same-size rewrite, §7.6) |
| `$06:$6034` | `FieldStateDispatch` | bank $06 entry 6, per-frame field router (S100; bit 5 → `MapTransitionMachine`) |
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
3. **Full `rst $00` dispatch enumeration** 🟡 (S100: custom rooms no longer need a
   dispatch slot — §7.6 inserts before the vanilla gating) — mechanism + ~7 handlers confirmed;
   enumerate every slot so reusable slots are known precisely.
4. **`SetBrd_6744`/`SetBrd_6800` carve algorithm** 🟡 — outline understood;
   step-trace pending for guaranteed-connectivity guarantees.

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
