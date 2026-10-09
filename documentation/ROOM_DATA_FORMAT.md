# Room Data Format — Technical Reference

> **Scope:** this doc covers the *static, pre-authored* rooms in bank `$0B`
> (towns, dungeons, and the gate **special/boss** rooms). The **standard random
> gate floors are NOT static** — they are procedurally generated at runtime (a
> 4×4 screen grid carved per descent). For that system see **GATE_GENERATION.md**.

## Overview

Room data lives in bank $0B. Each room (map_type) is a scrollable area
composed of screen positions in a 4×2 grid:

```
[0][1][2][3]   ← row 0
[4][5][6][7]   ← row 1
```

Not all positions are used. Unused positions are $FFFF in the sub-table.
Example layouts:
- Castle (mt=0):    [0][1][-][-] / [-][5][-][-]  (L-shape)
- GreatTree (mt=1): [0][1][-][-] / [4][5][-][-]  (2×2)
- Bazaar (mt=2):    [0][1][2][-] / [4][5][6][-]  (3×2)
- Well (mt=8):      [0]                           (single)

## Pointer Chain

```
$4B43[mapID × 2] → sub_table_ptr
  sub_table[screen_index × 2] → room_data_block  ($FFFF = unused)
    room_data_block: [ram_counter:2] + step_entries (6 bytes each)
```

Sub-table size varies per room — determined by the gap between
sub_table_ptr and the first room_data_block pointer it contains.
Size determined by gap between sub_table_ptr and first room_data_block pointer.
Common sizes: 1 (single screen), 8 (4×2 grid), 12 (conveyor/maze rooms),
16 (GreatTree), 32 (LabyrinthFinal). Screen indices >7 use extended grids.

Each valid screen has its own RAM step counter ($D9xx), assigned
sequentially across all rooms regardless of screen index.

## Step Entry (6 bytes)

| Offset | Field | Description |
|--------|-------|-------------|
| +0 | step_id | Index into tile layout pointer table at $4001 in the tileset bank |
| +1 | tileset_bank | ROM bank number containing compressed tile layout data (S135: despite the name, the LAYOUT stream's bank — any bank $01-$FF; patched builds put project layouts in $64 or an overflow bank $80+) |
| +2,+3 | interact_ptr | Pointer to mixed NPC + spawn block (5-byte entries, $FF terminated) |
| +4,+5 | exit_ptr | Pointer to exit checker block (read by entry 6 every step) |

**CONFIRMED by SameBoy debug**: bytes 2-3 = interact/NPC data (ReadInteractPtr),
bytes 4-5 = exit checker data. The bank_00b.asm labels are correct.

**NOTE**: dump_map_table.py has these labels SWAPPED (it calls bytes 2-3 "exit_ptr"
and bytes 4-5 "npc_ptr"). The extracted/map_table.json inherits this error.

Step entries are NOT $FF-terminated. The number of valid steps per screen
is implicit — the step value from RAM indexes directly (step × 6).
Invalid step values read garbage. ~~Step validation uses the tileset_bank byte
(must be > 0 and < $80).~~ **S133 correction: the engine validates nothing** — bank $0B
`ReadStepBlock` / bank $60 `CustomReadStep` hand the bank byte straight to
`DecompressTileLayout`; the `(0, $80)` test exists only in the Python dumpers
(`tools/dump_room_data.py` etc.). Layout / tileset banks $80-$FF are fine (ARCHITECTURE
"ROM banks $80-$FF (S133)").

## Room State System (Step Counters)

The step system is the game's primary mechanism for changing a room's
appearance based on story progression. Each screen can have multiple
**step entries**, each defining a different tile layout, NPC set, and exit
set. A RAM **step counter** selects which entry is active. When the
player enters a room, the engine reads the step counter to decide which
NPCs to spawn and which exits to enable.

### How it works

```
step_block:
  [ram_counter_ptr : 2]      ← e.g. $D92B (Castle screen 1)
  [step_entry_0    : 6]      ← active when [ram_counter_ptr] == 0
  [step_entry_1    : 6]      ← active when [ram_counter_ptr] == 1
  ...
```

The pointer-chase code (SharedPtrChase in bank $0B) reads the byte at
the RAM counter address and multiplies by 6 to index into the step
entries. Each step entry carries its own `interact_ptr` (NPC list) and
`exit_ptr` (exit list), so different steps show different NPCs and
different exits.

### Concrete example: Boss Villager room

```
StepBlk_Boss_Villager_s0: RAM=$D977, 2 steps
  Step 0: layout=$10  NPCs = [boss + decoration]   Exits = [none — trapped]
  Step 1: layout=$11  NPCs = [defeated boss only]   Exits = [exit to Castle]
```

When the player enters with `[$D977]=0` (boss alive), the boss NPC is
present and there is no exit. After defeating the boss, a script sets
`[$D977]=1` via opcode $12 (WriteRAM). On next room entry, step 1
loads: the boss NPC is replaced, and an exit back to Castle appears.

**Confirmed in-game (SameBoy):** Setting Castle screen 5 step counter
$D92C from 4 to 0 made a priest NPC appear that wasn't there at step 4.
Different step values load different NPC lists exactly as described above.

### How scripts control step counters

Scripts use two opcodes to interact with step counters:

- **Opcode $12 (WriteRAM):** `$FF12 <addr> <value>` — sets the step
  counter at `<addr>` to `<value>`. Example: `$FF12 $D977 $0001` sets
  Boss Villager to step 1 (defeated). Often used in cutscene scripts
  to advance multiple rooms at once (e.g., BossBeginning script 1 sets
  `$D92B`, `$D968`, `$D976` in a single script).

- **Opcode $15 (IfEqual / cond_branch):** `$FF15 <addr> <value>
  <branch>` — checks if `[addr] == value` and branches. Room-entry
  scripts (index 0) use this to decide which cutscene to play based on
  current step.

### Step counter RAM map

Step counters occupy $D92A–$D99A (113 unique addresses). Each address
corresponds to one screen of one room. Not all screens have multi-step
data — 92 screens have 2+ steps (state-dependent content), while the
rest have exactly 1. The full mapping is in the `StepBlk_*` labels in
`patches/bank_00b.asm`.

Key ranges:
- $D92A–$D92C: Castle (screens 0, 1, 5)
- $D92D–$D934: GreatTree (8 screens)
- $D935–$D93A: Bazaar (6 screens)
- $D93F–$D944: Farm (6 screens)
- $D951: Gate_08 (9 steps — most of any single screen)
- $D977–$D97A: Boss rooms (Villager, Talisman, Memories, Bewilder)
- $D998: Shared by all maze/conveyor/forest rooms (1 step each)
- $D99A: Last used address (Room_5E)

Custom rooms' counters are compiler-allocated from **$CD80** (S65, the
CF3-freed window — PROJECT_COMPILER §2.6; the old "$D478" home here was
refuted S54). The window is TRANSIENT: zeroed at every save-restore, so a
custom room's state reached by a script is lost on reload. **S97: flag
STATE RULES** (`custom.rooms[].state_rules`, PROJECT_COMPILER §2.13) make
state persistent: bank $60 entry 8 re-derives each screen's counter from
event flags (which ARE saved) at every custom (re)load.

### Runtime NPC show/hide (opcodes $48/$49) — UNVERIFIED (S97)

> S97: the bank-$04 handler table lists $48/$49 as 1-param flow ops
> (`ScriptCmd48_FaceDown` / `ScriptCmd49_FaceLeft`: read a word, `ld c,$01/$03`, jp
> CheckZeroJPEnd) — nothing in them touches the NPC slots. The hide/show
> semantics below were never measured; treat them as unconfirmed
> (DOC_AUDIT S97). The measured NPC-visibility bit is type bit 6 (see
> "NPC behaviour types").

Separate from the step system, opcodes $48 and $49 provide **runtime**
NPC visibility control within the current room visit:

- **$48 (npc_hide):** Moves an NPC to offscreen coordinates (parameter =
  NPC slot index). The NPC still exists in RAM but is not visible.
- **$49 (npc_show):** Moves an NPC back onscreen with an animation curve.

These are used for cutscene effects (boss intro animations, arena
sequences) and interaction scripts (e.g., ArenaLobby script 10 hides
NPC #1 then branches on flags). They are NOT persistent — on room
re-entry, the NPC list reloads from the current step entry, resetting
any runtime show/hide.

### Summary: which mechanism to use

| Need | Mechanism | Persistent? |
|------|-----------|-------------|
| Different NPCs/exits based on story progress | Step system (multiple step entries + opcode $12) | Yes (step counter in RAM, survives room re-entry) |
| Hide/show NPC during a cutscene or interaction | Opcodes $48/$49 | No (resets on room re-entry) |
| Conditional behavior within one NPC set | Room-entry script (index 0) with flag checks | Re-evaluated each entry |

For the editor, the step system is the primary tool: define multiple
step entries per screen, each with different NPC/exit data, and use
opcode $12 in scripts to advance the step counter when quest conditions
are met.

## Tile Layout System



1. **Tileset graphics** loaded by Entry 0 from $00:$26DD (or $00:$2A5D for gates)
   - 8 bytes per map_type: [gfx_ptr:2][spawn_data:6]
   - gfx_ptr decompressed to VRAM $9000 (tile pixel data)

2. **Tile layout** loaded from tileset_bank via step_id:
   - Call_000_1627 switches to the bank in step_entry byte 1
   - Reads pointer from $4001 + step_id × 2 in that bank
   - LZ77-compressed data (512 bytes decompressed = 32×16 tile grid)
   - Decompressed to $C300 buffer, then written to VRAM $9800 (BG map)

Tileset banks used: $23, $24, $25, $26, $29, $2A, $2D, $30, $37

### Creating Custom Tile Layouts

The engine's `DecompressTileLayout` at $1627 is completely bank-agnostic:
it takes D=bank_number, E=entry_index from the step entry, switches to
that bank, and reads from its $4001 pointer table. This means custom
layouts work in ANY bank that has the right format:

```
$4000: bank self-ID byte (e.g. $64)
$4001: pointer table — dw entries (step_id indexes these)
  Each pointer → LZSS compressed layout (512 bytes decompressed)
```

**Pipeline (tools/tile_layout_compiler.py):**
1. Design a 20×16 visible tile grid (JSON array of 16 rows × 20 cols)
2. Tile indices must be valid for the loaded tileset graphics (same source
   mapID → same GFX → same valid tile indices)
3. Compiler pads to 32×16 ($FF in columns 20-31), LZSS compresses,
   outputs ASM `db` statements with pointer table
4. Step entry byte 0 = entry index in the new bank's pointer table
5. Step entry byte 1 = new bank number

**Bank $64** is the first custom layout bank. Room $6B uses entry 0
(user-designed room with Farm tileset). Additional layouts add more `dw`
entries to the pointer table and more compressed data blocks.
**S135 (ROADMAP ARC CAP2a):** when $64 is full the compiler continues in the 4 MB ROM's overflow
banks ($80, $81, …; shared with attr maps and tilesets past $67) — `Project.stream_plan()`,
PROJECT_COMPILER §2.44; the reader rule (`$4001 + 2E` of the step's bank, ≤ 256 streams a bank, a
stream never crosses `$7FFF`, the bank's `$4000` byte = its number): ARCHITECTURE "LZ stream banks
(S135)".

**Tileset selection:** `MapIDClampForPalette` in ROM0 (patches/bank_000.asm)
returns the source mapID for GFX/palette loading. Change `ld a, $XX` to
switch tilesets. Currently $04 (Farm). This is hardcoded, not table-driven.

**Spawn position:** Player spawn when entering Room $6B is set by
`Exit_GreatTree_s8` in bank_00b.asm (bytes 5-6 of the exit entry).
Currently (7,6).

**Palette attribute caveat:** The GBC palette attributes are per-position,
loaded from bank $17 for the source mapID. Custom layouts that rearrange
tiles will have palette mismatches until custom attribute data is wired
(see ROADMAP "Custom tile GRAPHICS" for fix path).

**Editor integration:** `tile_layout_compiler.compile_layout(grid)` →
compressed bytes; `to_asm_bank(layouts, bank)` → complete bank ASM.
The editor's visual canvas produces the 20×16 grid, the compiler handles
everything from there.

**Tile index constraints:** The layout uses indices into whatever tileset
GRAPHICS are loaded for the room. The GFX are loaded by Entry 0 from the
$26DD table (indexed by the room's source mapID, set in
CustomSourceMapTable). Changing the layout does NOT change which tiles
are available — only where they're placed. For new tile graphics, see
the "Custom tile GRAPHICS" roadmap item.

## Interact Block (at bytes 2-3, "interact_ptr")

5-byte entries, $FF terminated. Entry type determined by bit 7 of first byte.

### Interact entries ≥$80 — EXAMINE spots and STEP-ON triggers (S98, PyBoy-measured)

The old "$8F = spawn point, $90 = walk-on exit" names were WRONG (DOC_AUDIT
S98). Arrival position ALWAYS comes from the exit row's bytes 4-6 (see the
Exit Checker Block); nothing reads a "spawn" entry at arrival. What the two
kinds really are:

| Byte | Field |
|------|-------|
| 0 | `$80-$83` / `$8F` = **EXAMINE spot**; `$90` = **STEP-ON trigger** |
| 1 | Parameter (vanilla always `$FF`) |
| 2 | X grid position (screen-local) |
| 3 | Y grid position |
| 4 | Script index into the room's script table (0 = the entry script) |

- **Examine spot** (`$8x`) — answers an A press. Bank $0B
  `RoomEntry4_TalkTargetLookup` (via bank $06 `Jump_006_611d`) looks up the
  player's OWN cell first, then the FACED cell (both `ld hl,$0b04` calls in
  bank $06). The low nibble is the required facing ($FF8E: 0 down, 1 left,
  2 up, 3 right) or `F` = any facing. A matching spot runs its script like
  an NPC talk (dialog mode, text boxes, YES/NO all work). Vanilla uses it
  for signs, books, shelves and the pots/barrels that "talk".
- **Step-on trigger** (`$90`) — bank $0B `RoomEntry5_StepTriggerLookup` /
  `SearchStepTriggers`, dispatched from bank $01
  `CopyPlayerCoordsAndGetNextRoom` (name kept for tools/audit_mapid_range.py)
  runs the script when the player WALKS onto the cell. Arriving on it by
  door/warp does NOT fire it (measured).
- **Both scans STOP at the first NPC entry (bit 7 clear).** A spot listed
  after an NPC is dead (measured: examine + step both silent until
  re-ordered). Vanilla orders spots first in 157/160 lists; the `$1F`
  screen-0 trailing `$81` is dead in the original game. The compiler emits
  spots before NPCs (stable partition, PROJECT_COMPILER §2.14).
- Script 0 on an examine spot re-runs the room's ENTRY script when the
  player presses A there — the legacy example "spawn" `db $8F,$FF,7,6,0`
  is exactly that (validator warning, S98). KEY_LESSONS "Spawn point NPC entry can be
  'talked to' — ghost NPC" was this mechanism.

### NPC entries (type byte $00-$7F):
| Byte | Field |
|------|-------|
| 0 | NPC type: bits 4-5 facing ($00 down, $10 left, $20 up, $30 right), bit 6 hidden, bits 0-3 behaviour — see "NPC behaviour types" (S97) |
| 1 | Sprite ID |
| 2 | X grid position (added to screen offset from $00:$2DE7) |
| 3 | Y grid position (added to screen offset) |
| 4 | Script ID (for NPC script engine in bank $04, $FF = no script) |

Parsed by Call_00b_477e during room init (Entry 7).
Each NPC gets a 32-byte ($20) slot in NPC RAM at $D7D2 (parser advances
slots with `add $20`; fields written at +$00 type, +$01 sprite, +$02/+$03
screen-adjusted X/Y, +$04 script_id area, +$11 facing-related, +$16, +$18).
An earlier version of this doc said 17 bytes — that was the +$11 field
offset misread as the stride. See DOC_AUDIT.md A.3.
Entries ≥$80 (examine spots / step-on triggers) are skipped by the NPC
parser (they don't consume NPC slots).

### Condition prefixes $A0 / $A1 and the gate swirl (S117, patched builds)

In patched builds every non-gate room's list reaches the engine through bank $60
`CopyNPCListToBuffer` (bank $0B `GetRoomDataPtr` → bank $60 entry 1 —
GATE_GENERATION §7.9). There a 5-byte entry **`$A0` / `$A1, flag lo, flag hi, $FF,
$FF`** is a CONDITION PREFIX, never copied: the next NPC entry is shown only while
that event flag is SET (`$A0`) / CLEAR (`$A1`); several prefixes AND. A failed
condition sets the NPC's hidden bit (bit 6), so the slots of later NPCs do not move.
The compiler emits them for `shown_when` and `swirl_of` (PROJECT_COMPILER §2.32);
vanilla rooms get conditioned copies of their lists only through
`VanillaNPCExtTable` (re-bossed / re-routed gate portals). `$A0`/`$A1` are not a
vanilla interact kind (the engine's ≥$80 kinds are examine `$8x` / step-on `$90`).

### Common tiles $80-$AF in every room (S123 r3, measured)

After a room's own sheet (`$9000`, ids `$00-$7F` via the signed `$8800` addressing), bank
$0B `RoomEntry0_TilesetLoader` (both copies, `$404F` / the second loader) always loads
sheet **`$29:$1D`** (768 B = 48 tiles) to `$8800` → BG ids **`$80-$AF`** are the same in
every room. The guard before it (`FA 68 C9 3E 08 20 23` = `ld a, [wMapID] / ld a, $08 /
jr nz`) is not a compare: Z comes from `WaitDMATransfer` (ends `xor a`), so the load always
runs (PyBoy: `$8800-$8AFF` == `$29:$1D` in rooms $00 / $01 / $08 / $10 / $24 / custom $74).
Vanilla `$08` (the roots room: bed, carpet) draws 53 cells with them. NPC sprite slots
load at `$8500 + c·$100` (code-read), so a 4th species would overwrite `$80-$8F`; vanilla
`$08` is special-cased (`cp $08`, banks $06 / $0B). The editor renders `$80-$AF` from this
sheet since S123 r3 (`render_project.common_blocks`, `tools/render_rooms.py`); ids ≥ `$B0`
still draw tile 0.

### Colour prefix $A2 and the NPC draw path (S123, patched builds)

**`$A2, palette, flag lo, flag hi, $FF`** (5 bytes, never copied) before an NPC entry
draws that NPC in OBJ palette 0-7 (`$17:$5615`) instead of its sprite's own — always
(flag `$FFFF`) or only while the flag is SET. `CopyNPCListToBuffer` records
`wNpcColour[slot] = $80|pal` (slot = index among the NPC entries, spots ≥ `$80` not
counted), tagged with `wMapID` / `wScreenIndex`. **The draw path:** bank $06
`NPCDrawSlot` (was `SaveMapS_4d0a`; `$C000+4·idx` OAM buffer, `$FFCB` = next free piece)
draws each NPC through bank $05 entry 0 (`NPCSpritePaletteOr`, was `HramAudE_406e`, ORs
the sprite id's own palette from `$05:$4152`); the patched build calls bank $60 entry 11
`NpcColourDraw` instead, which draws the same way and then rewrites attr bits 0-2 of
the pieces just added (`$FFCB` before → after). Monster NPCs (walking palettes) are
refused by the compiler. Cost measured ≈ 1.2 scanlines per NPC (PYBOY_DEBUGGING S123).
Emitted for `colour` and for a `cleared_swirl` gate's swirls (PROJECT_COMPILER §2.36).

**The gate swirl object** (vanilla, measured S117): NPC type `$00`, sprite **`$4D`**,
script `$FF`, standing on the portal cell — the spinning part of a portal; the still
swirl under it is background art (room $24 sheet tiles $20-$23, palette 3). Portal
rooms drop it from their step lists once the gate's boss is beaten (room $24: counter
`$D969`).

## Exit Checker Block (at bytes 4-5, "exit_ptr")

Read by Entry 6 (runs EVERY step) for walk-on exit detection.
7-byte entries, $FF terminated.

| Byte | Field |
|------|-------|
| 0 | trigger_X (screen-local coordinate, compared with player position) |
| 1 | trigger_Y (values 0 and 7 are treated as invalid and skipped) |
| 2 | dest_map_type → written to $C96D |
| 3 | gate_flag → written to $C96E (0=normal, 1=entering gate [dest = gate id], $80 = next floor of the dive [dest $00] — the special rooms' descent and the editor's Stairs down, GATE_GENERATION §7.5/§7.6) |
| 4 | screen_byte (low nibble = spawn screen index, bit 7 = Y+8 flag) |
| 5 | spawn_X at destination (added to offset table value) |
| 6 | spawn_Y at destination (added to offset table value) |

Special type values (byte 0):
- $FF: terminator
- $00 / $09: skipped by Entry 6 — they are the LEFT / RIGHT edge columns
  (x=0, x=9) and are matched by Entry 9 instead (S94b correction, DOC_AUDIT
  S94: the old "arrival point" / "special marker" names were wrong — they
  are ordinary edge exits, e.g. the Great Tree's east/west screen edges).

All other byte 0 values are treated as trigger_X coordinates.
Player position is compared in screen-local coordinates (player_pos - screen_offset).

Two scanners read the SAME list (both diverted through bank $60 entry 7 since
S70 / S94b, PROJECT_COMPILER §vanilla_exit_extensions):
- **Entry 6** (every step, walk-on): rows with 0 < x < 9 and 0 < y < 7 (the
  y=7 skip is data-driven since S70v3 — custom rooms make y=7 rows walk-on).
- **Entry 9** (push into the screen edge): rows with x ∈ {0, 9} or
  y ∈ {0, 7}; the player must walk INTO the edge.
`custom.entrance_redirects` (PROJECT_COMPILER §2.12) may re-point either kind.

Verified example — Castle Screen 5 exits:
- (2,5) → Gate Hub (mt=3): left door
- (7,5) → Farm (mt=4): right door
- (4,7) → GreatTree (mt=1): double door (two entries for 2-tile-wide door)

### Arrival and edge rules (S98, PyBoy-measured)

- **Arriving on an exit cell never re-triggers it** — Entry 6 fires on a
  STEP onto the cell, so a door's return row may land the player on the
  partner door cell itself (edge doors do exactly that).
- **screen_byte bit 7 = +8 px (half a cell down)**: the player stands in the
  doorway and the next step is onto the cell below — "step out of the
  door". Library → GreatTree uses sb `$88` spawn (5,3) and the player is
  logically on (5,4) — PIXEL-measured S98 r3 on the original ROM: pixel
  y = 320 = 20·16, i.e. y mod 16 = 0 while every standing position has
  y mod 16 = 8: the player is drawn half a cell below the door. (The editor
  used this in S98 r1; since S98 r2/r3 every door arrives ON its partner
  door cell at a whole-tile position — user choice.)
- **Edge exits vs scrolling:** an exit at x=0 / x=9 / y=0 on a screen edge
  that borders another screen of the room (inside the record's scroll
  area) NEVER fires — pushing into the edge scrolls first. A y=7 exit in a
  CUSTOM room fires on walk-on (S70v3), so it blocks walking down into the
  screen below through that cell. Validators warn on both (S98).
- A double door is two rows (one per cell) with the same destination; the
  editor's door object keeps vanilla double doors in step via `twin_of`
  redirect rows (PROJECT_COMPILER §2.14).


## Tileset Graphics System

The tileset GRAPHICS (tile pixel data) use the same LZSS decompressor as tile layouts.
Loaded by Call_000_1577 (Entry 0) from the graphics table:

- Normal rooms: $00:$26DD — 8 bytes per map_type:
  `[gfx_id:1][gfx_bank:1][room_width:2][room_height:2][collision_threshold:1][pad:1]`
  - Bytes 0-1: GFX step_id and bank (for tile pixel data loading)
  - Bytes 2-3: Room width in pixels (LE). 160 = 1 column, 320 = 2, 480 = 3
  - Bytes 4-5: Room height in pixels (LE). 128 = 1 row, 256 = 2, 512 = 4
  - Byte 6: Collision threshold (tiles < threshold = blocked)
  - Byte 7: Padding ($00)
  Room dimensions control the walkable area — the movement system clamps
  player position to (0,0)-(width-1, height-1). For multi-screen custom rooms,
  height/width must match the screen count (e.g. 2 vertical screens = height 256).
- Gate rooms: $00:$2A5D — same format

The gfx_id and gfx_bank work identically to step_id and tileset_bank:
gfx_bank selects the ROM bank, gfx_id indexes the pointer table at $4001.
(S135: the same routine, `DecompressTileLayout`, via `WaitDMATransfer`; a project tileset's
gfx_bank is $67 or an overflow bank $80+.)
Result: 2048 bytes = 128 tiles (8×8 pixels, 2bpp GBC format) → VRAM $9000.

All tilesets decompress to exactly 128 tiles. The same 9 tileset banks are used.

## GBC Attribute Buffer ($C200)

GBC-only. Contains tile palette/attribute data for the background map.
- Decompressed via LZSS from bank $17 (palette data tables at $5215/$5415)
- Selected PER (screen, step): `AttrPtrTable[map] → screen table (dw per
  screen) → [step counter addr:2] + per step [attr_entry, attr_bank,
  pal_ptr:2]` — so a room state can change its attr grid AND its BG palette
  (Servant room $3F: burning vs cleared differ in 221 attr cells and the
  palette). Custom rooms use the same shape via `CustomAttrPtrTable`
  (S94b, PROJECT_COMPILER §2.11; GATE_GENERATION §7.4) — S137: in each
  room's home bank (`PlaceRenderTable`), handed to the bank $17 walk through
  WRAM (PROJECT_COMPILER §2.46).
- 256 bytes total, 16 bytes per row (10 used + 6 padding)
- Each byte = 2 nibbles = 2 palette indices (0-15, 4 bits each); vanilla
  uses only 0-3 (S96 census over every vanilla screen/step: values {0,1,2,3}).
- The palette is per 8×8 SUBTILE, and vanilla really mixes slots inside a
  16×16 walk cell: 3,156 of 42,080 vanilla cells (7.5%; boss rooms, Arena,
  Bazaar …). The editor's metatile therefore carries one slot per subtile
  (S96, PROJECT_COMPILER §2.11).
- Written to VRAM $9800 in VRAM bank 1 (GBC attribute layer)
- Skipped entirely on DMG Game Boy

## Scroll Boundary System

Screen transitions within a room are computed from player world position:

Grid layout (screen indices):
```
          X=0  X=1  X=2  X=3
  Y=0:   [ 0] [ 1] [ 2] [ 3]
  Y=1:   [ 4] [ 5] [ 6] [ 7]
  Y=2:   [ 8] [ 9] [10] [11]
  Y=3:   [12] [13] [14] [15]
```

Handled by Entry 2 (RoomEntry2_ScreenScroll), which:
1. Divides player Y ($FF95/$FF96) by $80 (128) → row (0-3)
2. Multiplies row by 4
3. Divides player X ($FF92/$FF93) by $A0 (160) → column (0-3)
4. screen_index = row × 4 + column
5. Sets scroll offsets: $FFBB = row × 128, $FFB7 = column × 160
6. Decompresses tile layout for the current screen_index
7. Updates $C925 (wScreenIndex)

Collision boundary clamp: the collision check at ROM0 $1E96 subtracts the
scroll offset from the player position. If screen-local Y ≥ 128 or X ≥ 160,
it returns early (player at screen edge). Movement past the boundary requires
the room dimensions in $26DD bytes 2-5 to allow positions beyond one screen.

Screens OUTSIDE the record's width/height are legal and used by vanilla
(S96): Labyrinth `$42` (record 1×1, screens 0-1) and the Forest Mazes
`$53/$61-$63` keep extra screens that are never scrolled to — they are
entered through an exit whose screen_byte names them, exactly like the
GreatTree floors (KEY_LESSONS S92). The compiler warns instead of failing.

Exit handlers: Entry 6 checks exits at Y=1-6 (interior, walk-onto trigger).
Entry 9 checks exits at Y=0 and Y=7 (boundary, requires walking into edge).
(Custom rooms: y=7 rows are walk-on since S70v3; an edge exit bordering a
neighbour screen never fires — pushing scrolls first. See "Arrival and edge
rules (S98)".)

Walk grid: 10 columns × 8 rows per screen. Each cell = 16×16 pixels (2×2 tiles).
$FF97 = walk X, $FF98 = walk Y. Screen offsets from $2DE7 table (indexed by
screen_index × 2): X_offset (walk units) and Y_offset (walk units).

## Walkability: the bottom-right subtile decides (S94, emulator-measured)

Collision is decided per TILESET INDEX (tile id < the room's collision threshold
= WALL, KEY_LESSONS S6), sampled from the `$C300` screen buffer by
`TileBuffer_1E96` at the player's TARGET position — and the sampled tile is the
**bottom-right subtile of the target 16×16 cell**, from every approach direction.
Measured S94 in PyBoy (gate_rotation `$6D`, tile 0 poked into one subtile of the
neighbouring cell at a time, 16/16 trials: TL/TR/BL never block, BR always
blocks; right/down/left/up approaches identical). Consequences: a cell's
walkability can be flipped by swapping only its BR subtile for a graphic twin
on the other side of the threshold (editor "Walkability mode"); the other three
subtiles are cosmetic. The behavior class `$AA >> 2` (damage/stairs,
GATE_GENERATION §5.1) is read from the same sampled subtile.

## NPC capacity & sprite-sheet budget (S91, emulator-measured)

**Hard slot ceiling: 8 NPC entries per (screen, step-state) block.**
`RoomEntry7_RoomInit` ($0B:$470F) zero-fills exactly $101 bytes at $D7D2
(8 × 32-byte slots + the terminator cell $D8D2; `FillNBytesWithRegA`'s BC is
a plain 16-bit byte count) and the parser (`Call_00b_477e`) has **no bounds
check**. Vanilla respects the ceiling: the valid-step census over every room
maxes at exactly 8. Measured overflow (9 entries vs an 8-entry control, same
warp): the terminator no longer lands at $D8D2 and the 9th entry's fields
write into the **NPC-script state block** — $D8D9 (queued text id) and
$D8E2/$D8E3/$D8E6/$D8E7/$D8E8 changed — silently, with **no crash**. The
old bank_004.asm banner claim "up to 40 NPCs" was wrong (fixed S91,
DOC_AUDIT S91). Editor rule: hard-cap 8 per screen-state.

**Per-screen sprite-sheet VRAM budget (second, softer ceiling).** Each
*distinct* sprite id in the block loads its sheet into a shared VRAM tile
budget at room init, first-come in entry order; once exhausted, later
distinct ids render **blank** (no crash). Measured: 8 distinct "human"
sheets ($00-$0F range) all render; a batch of 8 distinct
boss_composite_fragment ids rendered 2 full + 1 partial + 5 blank. Repeats
of one id are free. Renders are deterministic (prior-VRAM priming produces
pixel-identical crops). Per-sheet tile counts are unmeasured (capacities
residual). Consequence for tooling: any per-id render census must place ids
**solo** (tools/dump_npc_sprite_catalog.py).

**Sprite-id catalog.** `extracted/npc_sprite_catalog.json` (+ thumbnail
sheet + per-id crops in `extracted/npc_field_sprites/`) is the S91 empirical
id → appearance census over $00-$7F, $E0-$E3, $F0-$F3, $FF: 72 normal ids,
17 boss-composite fragments (bosses are multi-tile composites assembled
from several NPC entries; regular monsters have single small icons — user
classification), 6 deterministic aliases of $00 ($4E/$4F/$F0-$F3), 37 empty,
5 glitch-invalid ($60/$6C/$73/$79/$7B). **No id crashes the renderer** in
vanilla rooms — the S70 "$11 hard-crashes" observation was custom-room
context (DOC_AUDIT S91), and the S70 vault-guardian "draconic" render is
$23 = a boss-composite fragment. Some vanilla-used ids ($54/$E2/$E3/$FF,
$FF = 50 uses) deterministically render nothing in field contexts.
Hand-curated names/classes live in `extracted/npc_names.json`
(`sprite_names` + `sprite_classes`) and merge into the catalog at
`--finalize`.

**Sprite limits (S117b, hardware — the user's emulator report + an OAM model of PyBoy
runs).** The field uses 8×8 objects (LCDC bit 2 = 0); a 16×16 character = 4 objects, 2 on
each screen line. The OAM is rebuilt each frame from `$C000` (HRAM `$CB` = the next
index; the metasprite writers stop at 40) in this order: the player (OAM 0-3), the 3
following monsters (4-15), then the NPC slots in list order. The PPU draws at most **10
objects per screen line** — the lowest OAM indices win — and the OAM holds **40**. So:
with the player + 3 monsters lined up on one row (8 objects per line), only **one** NPC of
that row is drawn while the party is on it (the later ones in the list vanish); and with
the party on screen (16 objects) about **6** 16×16 NPCs fit (some sprites use 3 objects).
Vanilla rooms respect this by layout. User report S117b (Portal Hall demo, 3 NPCs + the
party on one row): the bell keeper and the slime vanished. PyBoy screenshots do NOT show
the per-line drop (count objects per line instead — KEY_LESSONS S117b). The editor warns
(`formats.sprite_budget`: a row with > 1 NPC, > 6 NPCs on screen — the user chose
warnings over an engine flicker).

**Screens per room.** Engine ceiling = **16** (4×4): `RoomEntry2` scroll
math clamps row = Y/128 to 0-3 and col = X/160 to 0-3. Vanilla max = the
mt $54-$59 conveyor/maze rooms (12 declared slots, 9 valid); screen_index 8
(row 2) render + scroll verified in PyBoy S91. The custom pipeline's schema
currently accepts 4×2 = 8 (`screens` keys "0".."7", PROJECT_COMPILER);
extending to 4×4 is a schema residual, not an engine limit. Room dims in
the $26DD record must match the screen count (KEY_LESSONS S10).

**Phantom-step hazard when scanning room data.** ~~Step validation in the
engine only checks `tileset_bank ∈ (0,$80)`~~ (S133: the engine checks nothing; the
`(0,$80)` test is the dumpers' own), so tools that walk step
entries past a screen's real list decode garbage that can pass shallow
checks — `extracted/npc_catalog.json` contains such phantom rows (e.g.
"Castle screen 0 step 6, 28 NPCs" decodes to junk coordinates). Filter on
tileset_bank ∈ {$23-$31,$37,$38} + interact ptr ∈ $4000-$7FFF + sane
coords, and dedup blocks by (mt, ptr) — see
`tools/dump_npc_sprite_catalog.py --census` (DOC_AUDIT S91).

## NPC behaviour types — the type byte (S97, PyBoy-measured)

`type = facing (bits 4-5) | hidden (bit 6) | behaviour (bits 0-3)`; bit 7
set = not an NPC (examine spots $80-$83/$8F, step-on triggers $90 — S98;
skipped by the parser). Facing: 0 down, 1 left, 2 up, 3 right (the same value lands in
slot +$06).

**Bit 6 = HIDDEN (inactive entry).** Measured S97 (Bazaar slot poked
$00 → $40): the NPC is not drawn (its 4 OAM objects vanish), does not block
the player (walked through), has no behaviour/animation and cannot be
talked to. Code: bank $06 `LoadMapS_4043` returns before the behaviour
table, entry 0 `label6_4b1f` (player collision) and entry 1 `label6_4cbc`
(sprite draw) both skip bit-6 slots. Vanilla has 250 such entries (all
low nibble 0) — cutscene actors / placeholders; how vanilla reveals them
(e.g. `$0D` WriteNPCByte on field 0) is not yet measured.

**Low nibble = behaviour**: bank $06 `NPCBehaviourTable` ($4050, rst $00,
16 `dw`; re-sectioned from fake code S97). Every frame `label6_400f` walks
the 8 slots and dispatches each. Walkers step 1 px / 2 frames and pause
32 frames on every tile (timer +$07 = $10 at a tile boundary); all
behaviours freeze while any script runs. **Patterned walkers never test
tiles** — they walk through walls and off the screen edge (type 5 at x=8
walked to x=11) — but the player blocks them: bank $06 entry 0 flags the
slot (+$05 bit 5) and bank $01 `AdvanceNPCPointer` undoes the step and
pauses it $20 frames (the walker waits). Paths are tile offsets from HOME
(+$02/+$03), measured on Bazaar slot 0:

| nibble | handler | behaviour (measured) | vanilla uses |
|---|---|---|---|
| 0 (and B, C, D) | `NPCBeh0_Stand` | stands; turns to face the player when talked to and KEEPS that facing | 846 (+250 hidden) |
| 1 | `NPCBeh1_Spin` | turns 90° every 16 frames (down, left, up, right); faces the player while talked to, then resumes | 14 (Castle throne, Stable) |
| 2 | `NPCBeh2_PaceX2` | +1,+2,+1,0,−1,−2,−1,0 (starts right) | 17 |
| 3 | `NPCBeh3_Square2` | 2-tile square: down 2, right 2, up 2, left 2 | 2 (Farm) |
| 4 | `NPCBeh4_Figure8` | figure 8 of 3-tile legs: L3 U3 L3 D3 R3 U3 R3 D3 (a 7×4 area left of / above home; facing from `NPCFigure8FacingTable` $425E) | 2 (Arena Rooms) |
| 5 | `NPCBeh5_PaceRight3` | home → +3 right and back | 1 (Joy boss room) |
| 6 | `NPCBeh6_StandFixed` | stands and NEVER turns (still talkable) | 30 (Farm, Stable) |
| 7 | `NPCBeh7_StandReturn` | faces the player while talked to, then snaps back to its authored facing | 42 (GreatTree, Bazaar) |
| 8 | `NPCBeh8_PaceX1` | ±1 tile (starts right) | 1 (Goopy Room 2) |
| 9 | `NPCBeh9_PaceX2Left` | ±2 tiles (starts left) | 0 |
| A | `NPCBehA_Sway` | slides 1 px / 8 frames between +1 and −1 tile, no pauses, facing never changes | 1 (DeathMore boss) |
| E | `NPCBehE_GateWanderMeet` | GATE ONLY: acts only when `$C926` (the gate floor screen holding the wanderer; $FF outside gates, bank $16) == wScreenIndex — random walk with tile collision (classes $0C-$0E block) inside home..+7 × home..+5; when it arrives beside the player it starts its own script (wScriptMapType $70) | 0 in room data (gate generator) |
| F | `NPCBehF_GateWander` | as E without the auto-talk | 0 in room data |

In a normal room E/F never act (measured: frozen and unanimated). The
editor exposes these as `behaviour` names (PROJECT_COMPILER §2.13) and
draws the walk path of the selected NPC; the compiler warns when a path
leaves the 10×8 screen.

### What NPCs cost per frame (S125, PyBoy-measured)

User S125: "the room you made hub was laggy". Measured on the S125 demo HUB HALL
(the user's save, the player + 3 followers, walking left / right): main-loop
passes per 600 frames — 4 standing NPCs 542-556 (≈ 8 % of frames dropped while
walking, ≈ 3 % standing), 3 NPCs 580-590, 2 NPCs 599, none 600; the room's
four sway tile animations alone 600 (no cost seen); the sprite variety none
(4 NPCs of one sprite = the same). Per pass (scanlines, budget 154): the NPC
sprite draw (bank $06 entry 1) ≈ 8 per NPC, of which ≈ 1.4 is the S123 colour
path (bank $60 entry 11 via `NPCDrawSlot`; bypassed: 556 → 577 passes); the
per-frame NPC work before it (`VisualEffectsDispatch` … `CheckScriptActive`)
≈ 6 per NPC; `CheckScriptBeforeAction` a constant ≈ 30 in every room. 4 NPCs
average 110 lines with peaks of 173 → frames over budget. The vanilla throne
room (3 NPCs) 597-598. Rule of thumb: at most 3 NPCs on a screen the player
walks around in (PYBOY_DEBUGGING S125 "frame phases").

**Ten sprite pieces per line (S127, PyBoy-measured).** The hardware draws at most 10 OAM
entries on one scanline; the player alone is 8 on each of its lines (four palette layers
× two 8-pixel columns, OAM order first) and a follower / NPC 2 more. In the S127 demo
lodge (a copy of GateRoom1) three NPCs standing on the arrival's row 3 were in OAM at
the right places but not shown while the player stood on that row (row 2 = drawn). Put
NPCs one row above / below the cells the player stands on, the arrival first.

### NPC RAM slot ($D7D2 + 32·i, 8 slots) — fields known S97

| off | field | writer / reader |
|---|---|---|
| +$00 | type byte (above) | parser `$0B:Call_00b_477e` |
| +$01 | sprite id ($FF = empty slot for the per-frame loops) | parser |
| +$02/+$03 | HOME tile, absolute (entry X/Y + `$00:$2DE7[screen]`) | parser; walkers measure offsets from it |
| +$04 | script id (index into the room's script table) | parser |
| +$05 | status: bit 0 walking (walk animation), bit 5 blocked by the player, bit 6 talking (face the player), bit 7 hidden from the animation picker | bank $06 |
| +$06 | facing 0-3 | parser ((type>>4)&3), behaviours, talk |
| +$07 | pause timer (counts down per frame; $10 per tile, $20 when blocked, $08/$04 gate wanderers) | bank $06 |
| +$08 | pattern phase | walkers |
| +$10-+$15 | the animation player record (S118f, bank $02 `SeqStepper`): +$10 running (0 → restart at the first frame), +$11 row, +$12 animation id, +$13 step, +$14 shown frame (0/1 down, 2/3 side, 4/5 up; `$FF` nothing — bank_006:2466-2510), +$15 frames left | bank $06 `NPCAnimSelect` |
| +$11 | sprite id copy | parser |
| +$16 | sprite-sheet VRAM slot (`Call_00b_4839`) | parser |
| +$17 | OAM flip for the facing (`NPCFacingFlipTable`: left = X-flip) | `NPCAnimSetFlip` |
| +$18/+$1A | pixel X/Y (16-bit, tile·16+8) | walkers |
| +$1C/+$1E | previous pixel X/Y (copied each frame by bank $01 `LoadNPCDataTable`) | step undo |

## Monster NPCs — any species drawn as its follower (S101, PyBoy-measured)

The bank $0B NPC sheet resolver (`Call_00b_4839`, annotated S101) maps an NPC
entry's sprite id: $FF none; $E0 the player shape (frame id $5E = Terry's NPC frames over the player's VRAM sheet; S128 r3: $14 = Milayou's with the Milly hook on, patches/ `MillyE0Type`); **$E1-$E3 = the party
monster in party slot 0-2** (the follower sheets already in VRAM);
**$F0-$F3 = display-list entry n**: the pair at `$D7CA + 2n` = [draw id,
is_monster]; with is_monster ≠ 0 the draw id is `species + $10` and the NPC
is drawn and animated exactly like that species' follower (art from the
follower table, layout bank $10/$11, palette from its attr table). The
resolver copies the pair into the slot (+$11 draw id, +$0F is_monster). The
arena fills this list (opcode $1F); with it empty the ids alias sprite $00
(the S91 census). Behaviours (stand / spin / pace …) work as for any NPC.

Custom rooms: `npc.monster = species` (PROJECT_COMPILER §2.18) — bank $60
`CustomMonsterCast` writes the current screen's list before the NPC parse
(≤ 4 different species per screen; repeats share an entry), so scrolling
between screens swaps the cast (measured on a 2-screen room: GreatDrak on
screen 0, DragonKid on screen 1). Census (`tools/census_monster_npc_sprites.py`,
218 species, `extracted/monster_npc_sprites/`): species **216** draws blank;
**217-220 hang or crash** the game (their follower tables are not real);
221-223 do not exist — the compiler refuses 217-223, and (S105) a species ≥ 224
unless it is the project's own `custom.species` (the census's id-224 row was
captured on the pre-S105 example build = that project's Gorbunok). Heavy monster sheets
count against the per-screen sprite budget (above). ~~Observed S101, not yet
traced: after a battle started by TALKING to a monster NPC, that NPC is not
drawn again until the screen reloads~~ — **not reproducible S120** (PyBoy, the user's
save, room $70's monster NPC $F0 = MegaOgre): after a talk battle of 1 enemy (`$5A`),
of 3 enemies (`$5B`) and the user's own conversation (MegaOgre fight → helper → Castle)
the NPC's OAM entries (tiles $80-$83), its VRAM tiles ($8800-$88FF, both banks) and its
16 × 16 screen pixels are identical before the talk, after the battle and through the
helper's fly-in. What the S101 run saw is not identified (that build's helper landed on
fixed cells and could cover the monster — S101 r2 moved it beside the player).

## Animated tiles (S99, PyBoy-measured) — ROADMAP P3.3e

**One mechanism, one bank.** Every field frame, `MainFieldLoop` calls bank
$01 `PerRoomVRAMDispatch` ($60E7). After its guards it does `rst $00` on a
**112-entry** jump table at `$01:$6119` indexed by map ID `$00-$6F`
(the table ends where the first handler begins, $61F9; vanilla points
$6B-$6F at a bare `ret`; the old "107 entries" count was wrong — DOC_AUDIT
S99). The 65 distinct handlers (labels `RoomAnim_<room>` /
`RoomAnimNone_<map>`, bank_001.asm) change fixed tile SLOTS of whatever
2 KB sheet is loaded at VRAM `$9000-$97FF` (slot = (addr-$9000)/16).
Nothing else in the ROM rolls or swaps BG tile graphics (grep: every
VRAM `rrc/rlc [hl]` loop and every caller of the roll/swap helpers is in
bank $01; S102: custom rooms add their OWN animations from bank $6C — see
"Own tile animations (S102)" below). **Gate floors never animate** (the dispatch returns while
`wInGateworld` != 0; user-confirmed S99: "Gate floors do NOT have
animation").

**Guards** (return = no animation this frame): `$C850`, `$C88F` or
`wInGateworld` non-zero; any of `wGameState` ($C8EB) bits 1,2,3,5,6,7 set
(menus, text, transitions); bit 4 set with `$C8EF == $0F`. **Clock**:
`$C8A6/$C8A7`, the 16-bit field frame counter (`IncrementVisualStep`, +1
per MainFieldLoop pass, after the dispatch — a handler sees the value before
the increment).

**Effects** (helpers annotated S99):
* **ROLL** — `RollTilePairWobble` (was `CheckVisualEffectType`): HL = the
  first of 2 tiles; on counter `& $7F` = $07/$27/$47 both tiles roll 1 px
  RIGHT (`RollTileRight`: `rrc` on all 16 bytes), on $67 1 px LEFT — one
  step every 32 frames, net 2 px right per 128 (flowing water, flames).
* **SWAY** — `GreatTreeSway` (GreatTree, Secret Passage): on counter
  `& $1F` = 5, tiles 64-79 roll 1 px in 4-tile groups of alternating
  direction (R,L,R,L while `$C8A7` bit 1 is set, L,R,L,R while clear — the
  directions flip every 512 frames).
* **SWAP** — `VRAMSwapBytes` (was "VRAMCopyTile"): exchanges B bytes
  between two VRAM ranges — a shown tile trades graphics with its HIDDEN
  SECOND FRAME stored in unplaced slots of the same sheet (2-frame
  animation). Most rooms swap when counter `& $1F` = 3 (every 32 frames);
  Orochi (`$44`) every 64 on two phases; Esterk (`$4B`) two pairs on two
  phases; Coliseum (`$52`) and Arena Battle (`$5D`) use divider rhythms
  (periods 25/32 and 16/32 frames).
* Map `$08` (breeding cutscene) only pulses the DMG palette byte
  `wBGPalette` ($C89B) — not a tile effect; not offered as a source.

**Census** (`tools/census_room_animation.py` → `extracted/room_animations.json`;
method: every handler forced through the `$01:$6118` dispatch in the Bazaar
over a patterned VRAM, counter reset to 0, 1024 frames, every change
classified; "shown" = slots the vanilla room places on any screen/state,
"hidden frames" = animated but never placed; INERT = the room's own sheet
makes the effect a no-op). Maps not listed have a bare-`ret` handler.

| Map | Room | Handler | Effect (measured) | Shown | Hidden frames |
|---|---|---|---|---|---|
| $00 | Castle | `RoomAnim_Castle` $61F9 | ROLL 77-78 1 px (3 R : 1 L per 128 f) | 77-78 | — |
| $01 | GreatTree | `RoomAnim_GreatTree` $6200 | SWAY 64-79 (4-tile groups alternate, flip /512 f) | 64-79 | — |
| $08 | Starry Shrine Breeding Cutscene | `RoomAnim_StarryShrineCutscenePalette` $6220 | DMG palette pulse (wBGPalette), no tiles | — | — |
| $0A | Secret Passage | `RoomAnim_SecretPassage` $62B3 | SWAY 64-79 (4-tile groups alternate, flip /512 f) | INERT (blank slots) | — |
| $19 | Goopy Room 1 (scr8) | `RoomAnim_GoopyRoom1` $62B9 | SWAP 50-51 ↔ 61-62 /32 f | INERT (blank slots) | — |
| $1A | Goopy Room 2 (scr8) | `RoomAnim_GoopyRoom1` $62B9 | SWAP 50-51 ↔ 61-62 /32 f | INERT (blank slots) | — |
| $1C | Stable: Coffin Room | `RoomAnim_StableCoffinRoom` $62CE | SWAP 36-37 ↔ 44-45 /32 f | 36-37 | 44-45 |
| $20 | map $20 | `RoomAnim_Map20` $62E5 | SWAP 50-51 ↔ 56-57 /32 f | 50-51,56-57 | — |
| $21 | map $21 | `RoomAnim_Map20` $62E5 | SWAP 50-51 ↔ 56-57 /32 f | 50-51,56-57 | — |
| $23 | Room of Beginning | `RoomAnim_RoomOfBeginning` $62FA | SWAP 19-22 ↔ 25-28 /32 f | 19-22 | 25-28 |
| $26 | Room: Peace/Bravery | `RoomAnim_RoomPeaceBravery` $6310 | SWAP 6-7,22-23 ↔ 32-35 /32 f; ROLL 36-37 1 px (3 R : 1 L per 128 f) | 6-7,22-23,36-37 | 32-35 |
| $28 | Room: Joy/Wisdom | `RoomAnim_RoomJoyWisdom` $6336 | ROLL 37-38 1 px (3 R : 1 L per 128 f) | 37-38 | — |
| $29 | Room: Happiness/Temptation | `RoomAnim_RoomHappinessTemptation` $633D | SWAP 6-7,14-15 ↔ 12-13,22-23 /32 f; ROLL 10-11 1 px (3 R : 1 L per 128 f) | 6-7,10-11,22-23 | 12-15 |
| $2A | Room: Labyrinth/Judgment | `RoomAnim_RoomLabyrinthJudgment` $6362 | SWAP 6-9 ↔ 26-29 /32 f | 6-9 | 26-29 |
| $2C | Room: Ambition/Demolition | `RoomAnim_RoomLabyrinthJudgment` $6362 | SWAP 6-9 ↔ 26-29 /32 f | 6-9 | 26-29 |
| $2D | Room: Mastermind/Control | `RoomAnim_RoomMastermindControl` $6377 | ROLL 24-25 1 px (3 R : 1 L per 128 f) | 24-25 | — |
| $2E | Room: Extinction/Sleep | `RoomAnim_RoomExtinctionSleep` $637E | SWAP 6-7,22-23 ↔ 32-35 /32 f | 6-7,22-23 | 32-35 |
| $2F | Intro Bedroom (2-screen, crashes) | `RoomAnim_IntroBedroom` $639D | SWAP 78 ↔ 79 /32 f | 78 | 79 |
| $30 | Boss: Beginning (Healer) | `RoomAnim_BossBeginning` $63B1 | ROLL 30-31 1 px (3 R : 1 L per 128 f) | 30-31 | — |
| $37 | Boss: Bravery (BigEye) | `RoomAnim_BossBravery` $63BE | SWAP 35 ↔ 36 /32 f | 35 | 36 |
| $3C | Boss: Anger (BattleRex) | `RoomAnim_BossAnger` $63D6 | ROLL 86-87 1 px (3 R : 1 L per 128 f) | 86-87 | — |
| $3D | Boss: Arena Left (Digster) | `RoomAnim_BossArenaLeft` $63DD | ROLL 10-11 1 px (3 R : 1 L per 128 f) | 10-11 | — |
| $3E | Boss: Happiness (Jamirus) | `RoomAnim_BossBravery` $63BE | SWAP 35 ↔ 36 /32 f | 35 | 36 |
| $3F | Boss: Temptation (Servant) | `RoomAnim_BossTemptation` $63E4 | SWAP 56-59 ↔ 60-63 /32 f | 56-59 | 60-63 |
| $44 | Boss: Library (Orochi) | `RoomAnim_BossLibrary` $63FC | SWAP 14 ↔ 15 /64 f; SWAP 30 ↔ 31 /64 f | 14-15 | 30-31 |
| $46 | Boss: Ambition (DracoLord) | `RoomAnim_BossAmbition` $6423 | ROLL 70-71 1 px (3 R : 1 L per 128 f) | 70-71 | — |
| $47 | Boss: Demolition (Hargon/Sidoh) | `RoomAnim_BossDemolition` $642A | SWAP 76,78 ↔ 90-91 /32 f | 76,78 | 90-91 |
| $48 | Boss: Mastermind (Baramos) | `RoomAnim_BossMastermind` $6449 | SWAP 25 ↔ 26 /32 f | 25 | 26 |
| $49 | Boss: Control (Zoma) | `RoomAnim_BossControl` $645D | SWAP 42-43,58-59,64-65 ↔ 44-45,60-61,66-67 /32 f; ROLL 49-50 1 px (3 R : 1 L per 128 f) | 42-43,49-50,58-59,64-65 | 44-45,60-61,66-67 |
| $4B | Boss: Sleep (Esterk) | `RoomAnim_BossSleep` $648E | SWAP 12 ↔ 13 /32 f; SWAP 14 ↔ 15 /32 f | 12,14 | 13,15 |
| $4D | Boss: Arena Right (Mudou) | `RoomAnim_BossArenaRight` $64B5 | SWAP 10-11,32-33 ↔ 12-13,34-35 /32 f; ROLL 52-53 1 px (3 R : 1 L per 128 f) | 10-11,32-33,52-53 | 12-13,34-35 |
| $4F | Boss: Unused (DarkDrium) | `RoomAnim_BossUnused` $64DB | SWAP 92-93 ↔ 94-95 /32 f | 92-93 | 94-95 |
| $52 | Gate Floor: Coliseum | `RoomAnim_GateFloorColiseum` $64F0 | SWAP 13,28 ↔ 27,29 /32 f; SWAP 32-33 ↔ 34-35 /25 f | 27-28,32-33 | 13,29,34-35 |
| $5D | Arena Battle | `RoomAnim_ArenaBattle` $6543 | SWAP 60-61 ↔ 68-69 /32 f; SWAP 62-63,74-75 ↔ 70-71,82-83 /32 f; SWAP 72-73 ↔ 80-81 /16 f | (no room data) | — |

Verified three ways S99: (1) each vanilla room measured in place (warp,
real sheet, 520-1100 frames) — same slots; (2) the patterned forced-dispatch
census above; (3) `--check` walks every handler's code (branches + bank-$01
calls) and asserts each measured slot lies in the VRAM ranges it names
(verify_integrity check 5).

**Custom rooms (S99 engine).** Before S99 the dispatch called
`MapIDClampForDispatch` → $00 for every map ID ≥ $6B, so **every custom
room ran Castle's roll on slots 77-78** and clones of animated rooms stood
still. Now `custom.rooms[].animation` picks the handler (PROJECT_COMPILER
§2.15): `none` ($6B, the table's own `ret` row), `source` (the room's
`source_mapID`) or any vanilla map ID (borrow). `PerRoomVRAMDispatch` was
rewritten same-size ($60F9-$6118): the six `bit n,a / ret nz` guards became
`and $fe / jr z / cp $10 / ret nz` (equivalent for all 65,536
(wGameState, $C8EF) pairs — checked exhaustively), and the freed bytes fund
`cp CUSTOM_ROOM_START / jr c / ld hl,$7103 / rst $10 / ld a,e` → bank $71
entry 3 `CustomAnimSource` (E := `CustomAnimSrcTable[mapID-$6B]`; the
`rst $00` stays at $6118, asserted). Vanilla rooms: frame-by-frame A/B vs
the S98 build from one savestate — the final VRAM, screen and counter are
identical; the only differences are sub-frame (a multi-frame tile load a few
bytes further along at a frame edge, re-converging within 7 frames — the new
path is ~35 cycles cheaper per frame).

**A bare `ret` handler is safe** (S99, measured): forcing `rst $00`'s index
to a `ret` handler in two custom rooms left the screen pixel-identical and
the palette buffer unchanged — only tiles 77-78 stopped rolling. The S1-era
"yellow palette" (KEY_LESSONS v8) had another cause (at that time the clamp
also served the palette lookups). So "no animation" costs nothing and slots
77/78 are ordinary slots in a room whose animation is `none`.

**Which slots a custom room animates** = its handler's slots, in whatever
sheet it draws with. A clone keeps its source's sheet layout, so `source`
reproduces the vanilla animation exactly (PyBoy S99: Castle / Room of
Beginning / Digster clones — VRAM after 300 frames == the census schedule,
byte for byte, on the user's save). Borrowing onto another sheet animates
whatever graphic sits in those slots — which is why the editor's Borrow tab
(S99 r2) copies an ANIMATED vanilla tile into the same slot indices it has
in its source room (plus a swap's hidden partner frame) and switches the
room to that room's animation: a copy into any other slot is a still
picture. And a room that SWITCHES animation starts moving every slot of the
new one — so the editor's "Make animated" (S99 r3, `Document.make_animated`)
moves every tile in use in those slots (other than the one being animated)
to a free slot first; your own art becomes a slide (roll slots) or a
two-frame flip (frame A in a shown slot, the painted frame B in its
partner). The editor protects every animated
slot of a sheet (union over the rooms drawing with it) from imports and
walkability twins, outlines the animated areas on the canvas, and plays the
measured schedule (`editor2/core/animation.py` `Player`; exact within a
1024-frame cycle — every handler returns to its start over one cycle except
the Coliseum's 25-frame swap, which re-phases at the loop).

### Own tile animations (S102) — any slot, any speed, drawn frames

A custom room can also animate its OWN tiles (`custom.rooms[].tile_anims`,
PROJECT_COMPILER §2.19): bank $71 entry 3 far-calls bank $6C
`CustomTileAnimate` before choosing the vanilla handler, so both run. Each
step copies a whole authored frame from bank $6C into the tile's slot of the
loaded sheet with General-Purpose DMA at the start of HBlank — no hidden
partner slots, no relative rolls, walkability untouched (the slot index
never changes), and a reloaded sheet heals at the next step. Up to 8 tiles
per field frame (groups that do not fit wait a frame). Measured (PyBoy, the
user's save): ~1.5 scanlines per tile; SameBoy agrees frame for frame.

**Per-frame budget of the old handlers (measured S102, PyBoy)**: the field
loop tolerates ~35-45 scanlines of animation work per frame; GreatTree's
16-tile sway (~65 lines) and Zoma's 6 swaps + roll (~50) make the loop miss
one frame per 32; Room of Beginning's 4 swaps (34) and Castle's roll (9) do
not. A vanilla swap costs ~8 lines per pair (one WaitVRAM per byte).

**Hardware headroom found S102 (field only; not yet checked in battle or
cutscenes)**: the game never uses HDMA/GDMA (every `rHDMAx` operand in the
disassembly is data decoded as code); it runs at normal speed (KEY1 = 0);
its VBlank handler finishes its VRAM work at LY 148, leaving ~5 lines of
VBlank; and **VRAM bank 1's tile area ($8000-$97FF, 384 tiles) is empty**
with no BG cell using attribute bit 3 — checked in GreatTree, Castle, the
Zoma room, Room of Beginning, a Farm room, a custom room and the menu. A
room could draw up to 128 more tiles from there (ROADMAP P3.3g).

## Text boxes and sprites (S121 — PyBoy-measured)

While a text box is open (`$FFD3` = 1 top / 2 bottom, set by the bank $06 opener), ROM0
`SaveHLBC` (the metasprite builder `$0D91` / `SpriteGBCMode`) SKIPS every sprite piece
whose BG tile underneath is ≥ `$FFD4` (`$80` = the font tiles, i.e. the box). Rooms that
draw their own art with tile ids ≥ `$80` would lose every sprite while a text shows —
vanilla turns the rule off (`$FFD3 := 0`, bank $06 `jr_006_6893`) in maps **`$08`** (the
tree roots) and **`$5D`**, outside the gate world. A custom COPY of those rooms has another
mapID, so in S121's roots room Milly and Warubou vanished during his lines → the room
field **`text_keeps_sprites: true`** (`CustomRoomFlags` bit 1; `clone_vanilla` sets it for
copies of `$08` / `$5D`) and the bank $06 region `text_sprite_mode` → bank $71 entry 8
`TextSpriteMode` (the vanilla two + these rooms). PyBoy: both stay drawn through the four
boxes. A room painted with tile ids ≥ `$80` needs the field set (not offered in the
Rooms tab yet — set by the copy).
**`$FFD4` is not always `$80` (S126 r2, code-read + PyBoy):** bank $01 `ClearAnimationState`
sets `$80` at every map load, but four screens lower it and never put it back: the farm
menu `$60` (bank $12 `$44A7`, its icons sit in slots `$60-$6F`), bank $0A screen types 5
(`$78` at `$4481`), 6 (`$40` at `$4C33`) and 11 (`$40` at `$69C3`). Until the next map load, every sprite over a BG tile ≥ that value
is skipped while ANY text box is open — after a farm visit in a room whose floor is tile
`$7B`, the next talk hid every NPC, the player and the party (the user's report). Vanilla
rooms never show such tiles where the farm opens. Bank $77 `ServiceTilesBack` (the
service closes in custom rooms) sets `$FFD4` := `$80` again.

## The game's menus draw into the room's tile slots (S126 — PyBoy-measured)

The service screens (script op `$04`, PROJECT_COMPILER §2.39) borrow the ROOM's own sheet
slots (VRAM `$9000-$97FF`, ids `$00-$7F`) and the game puts back only some of them:

| Screen | Slots it writes | Put back by the game |
|---|---|---|
| farm (3) | `$60-$6F` the family icons (`$9600`, 8 sites in `FarmScreen`); also `$FFD4` := `$60` ("Text boxes and sprites") | no |
| egg appraiser (7) | `$70-$78` the egg icons (`$9700`) | no |
| Library (8), farm CHECK, egg INFO | the room sheet (full screens) | yes — the room reloads (bank $0B entries 1 / 2) |
| gate list (13) | `$38-$7F` the gate names as a bitmap | yes (room reload) |
| naming screen (15) | the room sheet | yes (room reload) |
| Grandpa (6) / a master (5) / "Take…" (11) — S127 | `$40-$7F` (the menu's icons); `$FFD4` := `$40` / `$78` / `$40` | no — S127: bank $77 `BreedClose` reloads the room sheet and sets `$80` in custom rooms |

No vanilla room shows slots `$60-$7F` where these menus open; a custom room may — before
S126 a farm visit left monster icons in its floor. Now bank $77 entry 6
`ServiceOpenTiles` saves `$9600-$97FF` (custom rooms, once per screen) and entries 4 / 5
restore them at the close. A custom room's own tile animation (bank $71
`CustomAnimSource`) pauses while any screen of `AnimPauseTypes` is open, else it would
write its frames over the menu's tiles (vanilla pauses its animation only for type 15).
In a free-colour room every pushed menu cell is palette 7 (bank $77 `ScreenPush`), so
the windows stay cream.

## Gate Room Differences

Gate rooms (wInGateworld ≠ 0) differ from normal rooms:
- Use tileset table at $00:$2A5D instead of $00:$26DD
- Exit logic bypasses the exit checker block entirely
- Fixed exit: when player is on gate exit screen ($C960) at Y position $0F,
  transition to map_type 0 (Castle) with gate_flag $80
- Entry 3 (tile refresh) patches gate portal tiles ($3C-$3F) into tile buffer

## Tile Buffers

Three RAM buffers used for tile/screen data:
- **$C200** (256 bytes): GBC palette attributes, nibble-packed (GBC-only)
- **$C300** (512 bytes): Primary tile layout (32×16 grid, 20 used + 12 pad per row)
- **$C500** (512 bytes): Secondary tile layout (used during screen transitions)

All three use the same LZSS decompressor (Call_000_14cf).
Length limit (S100 r3): an extended back-reference's length is `byte + 19`
computed in 8 bits, counted down with `dec/jr nz` — 256 max (byte 237 → 0);
`tools/compress_tiles.py` MAX_COPY = 256 (PROJECT_COMPILER).
## Key Constants

| Address | Purpose |
|---------|---------|
| $0B:$4B43 | Room pointer table (107 entries × 2 bytes) |
| $00:$26DD | Tileset graphics table (normal rooms) |
| $00:$2A5D | Tileset graphics table (gate rooms) |
| $00:$2DE7 | Screen offset table (per-screen X,Y pixel offsets) |
| $D7D2 | NPC RAM buffer (8 slots × 32 bytes — fields: "NPC RAM slot") |
| $C300 | Tile map buffer (512 bytes, 32×16 grid) |
| $C925 | Current screen index (0-15 on the 4×4 grid, row×4+col) |
| $C968 | Current map_type (wMapID) |
| $C969 | Gate flag (wInGateworld) |

## Verified Examples

Castle (mt=0):
- Screen 0 (row 0, col 0): throne area, spawn points from all gates, 2 NPCs
- Screen 1 (row 0, col 1): throne room, step-dependent NPCs for cutscenes
- Screen 5 (row 1, col 1): entrance hall, ALWAYS 3 guard NPCs (sprite $0B)
  - Confirmed via SameBoy watchpoint on $D7F4 (3rd NPC slot)
  - $C925=5, $D92C=4 (step 4) during normal gameplay
