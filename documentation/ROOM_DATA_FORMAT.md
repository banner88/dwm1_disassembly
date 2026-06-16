# Room Data Format — Technical Reference

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
| +1 | tileset_bank | ROM bank number containing compressed tile layout data |
| +2,+3 | interact_ptr | Pointer to mixed NPC + spawn block (5-byte entries, $FF terminated) |
| +4,+5 | exit_ptr | Pointer to exit checker block (read by entry 6 every step) |

**CONFIRMED by SameBoy debug**: bytes 2-3 = interact/NPC data (ReadInteractPtr),
bytes 4-5 = exit checker data. The bank_00b.asm labels are correct.

**NOTE**: dump_map_table.py has these labels SWAPPED (it calls bytes 2-3 "exit_ptr"
and bytes 4-5 "npc_ptr"). The extracted/map_table.json inherits this error.

Step entries are NOT $FF-terminated. The number of valid steps per screen
is implicit — the step value from RAM indexes directly (step × 6).
Invalid step values read garbage. Step validation uses the tileset_bank byte
(must be > 0 and < $80).

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

Custom rooms use $D478–$D47B (room $6B screen 0, room $6C screens
0/1/5). These are in the verified-unused WRAM gap ($D478–$D790),
avoiding the original step counter range ($D92A–$D99A) and the
event flag range ($D99B–$D9BA). NOTE: $D478+ is NOT in the SRAM
save range, so custom step counter values reset on power cycle.
For save-persistent state changes, use event flags ($00/$01/$03)
combined with room-entry script flag checks (opcode $15).

### Runtime NPC show/hide (opcodes $48/$49)

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

### Spawn/exit entries (type byte ≥ $80):
| Byte | Field |
|------|-------|
| 0 | Type: $8F=spawn point, $90=walk-on exit, others=special |
| 1 | Parameter (usually $FF) |
| 2 | X grid position |
| 3 | Y grid position |
| 4 | Source/destination map_type |

### NPC entries (type byte $00-$7F):
| Byte | Field |
|------|-------|
| 0 | NPC type (bits 4-5 encode facing direction: $00=down, $10=left, $20=up, $30=right) |
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
Spawn entries ($8F+) are skipped (don't consume NPC slots).

## Exit Checker Block (at bytes 4-5, "exit_ptr")

Read by Entry 6 (runs EVERY step) for walk-on exit detection.
7-byte entries, $FF terminated.

| Byte | Field |
|------|-------|
| 0 | trigger_X (screen-local coordinate, compared with player position) |
| 1 | trigger_Y (values 0 and 7 are treated as invalid and skipped) |
| 2 | dest_map_type → written to $C96D |
| 3 | gate_flag → written to $C96E (0=normal, 1=entering gate) |
| 4 | screen_byte (low nibble = spawn screen index, bit 7 = Y+8 flag) |
| 5 | spawn_X at destination (added to offset table value) |
| 6 | spawn_Y at destination (added to offset table value) |

Special type values (byte 0):
- $FF: terminator
- $00: arrival point (skipped by exit checker)
- $09: special marker (skipped)

All other byte 0 values are treated as trigger_X coordinates.
Player position is compared in screen-local coordinates (player_pos - screen_offset).

Verified example — Castle Screen 5 exits:
- (2,5) → Gate Hub (mt=3): left door
- (7,5) → Farm (mt=4): right door
- (4,7) → GreatTree (mt=1): double door (two entries for 2-tile-wide door)


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
Result: 2048 bytes = 128 tiles (8×8 pixels, 2bpp GBC format) → VRAM $9000.

All tilesets decompress to exactly 128 tiles. The same 9 tileset banks are used.

## GBC Attribute Buffer ($C200)

GBC-only. Contains tile palette/attribute data for the background map.
- Decompressed via LZSS from bank $17 (palette data tables at $5215/$5415)
- 256 bytes total, 16 bytes per row (10 used + 6 padding)
- Each byte = 2 nibbles = 2 palette indices (0-15, 4 bits each)
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

Exit handlers: Entry 6 checks exits at Y=1-6 (interior, walk-onto trigger).
Entry 9 checks exits at Y=0 and Y=7 (boundary, requires walking into edge).

Walk grid: 10 columns × 8 rows per screen. Each cell = 16×16 pixels (2×2 tiles).
$FF97 = walk X, $FF98 = walk Y. Screen offsets from $2DE7 table (indexed by
screen_index × 2): X_offset (walk units) and Y_offset (walk units).

## NPC Type Byte Encoding



Common values: $00 (down,standard), $10 (left), $20 (up), $30 (right),
$40 (down,non-interactive), $60 (up,non-interactive).
Lower nibble values 6 and 7 appear frequently — may control movement pattern.

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
## Key Constants

| Address | Purpose |
|---------|---------|
| $0B:$4B43 | Room pointer table (107 entries × 2 bytes) |
| $00:$26DD | Tileset graphics table (normal rooms) |
| $00:$2A5D | Tileset graphics table (gate rooms) |
| $00:$2DE7 | Screen offset table (per-screen X,Y pixel offsets) |
| $D7D2 | NPC RAM buffer (17 bytes per slot) |
| $C300 | Tile map buffer (512 bytes, 32×16 grid) |
| $C925 | Current screen index (0-7 in the 4×2 grid) |
| $C968 | Current map_type (wMapID) |
| $C969 | Gate flag (wInGateworld) |

## Verified Examples

Castle (mt=0):
- Screen 0 (row 0, col 0): throne area, spawn points from all gates, 2 NPCs
- Screen 1 (row 0, col 1): throne room, step-dependent NPCs for cutscenes
- Screen 5 (row 1, col 1): entrance hall, ALWAYS 3 guard NPCs (sprite $0B)
  - Confirmed via SameBoy watchpoint on $D7F4 (3rd NPC slot)
  - $C925=5, $D92C=4 (step 4) during normal gameplay
