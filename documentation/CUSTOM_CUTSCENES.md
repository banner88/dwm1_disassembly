# Creating Custom Cutscenes — DWM1 Script Engine Guide

## How Cutscenes Work

Every NPC interaction, room-entry event, and cutscene in DWM1 is driven by
the same 100-opcode script engine (Bank $04). Scripts are stored as arrays
of 16-bit words (`dw` entries) in banks $0C/$0D/$0E/$0F.

**Player control is automatic:** When a script starts, the player loses
control. When the script hits `end`, the player regains control. No special
lock/unlock opcodes are needed for the player — only for NPC movement timing.

## Script Data Format

Scripts are sequences of `dw` words:
- `$FFxx` (where xx ≤ $63) = opcode with xx as the command number
- `$FFFF` = script end, player regains control
- Values $0000-$FEFF (with high byte ≠ $FF) = text ID or opcode parameter
- Values $4000-$7FFF (odd-aligned) = branch target addresses

Each opcode consumes 0-4 parameter words after it. See PARAM_COUNTS in
`tools/decompile_script.py` for the exact count per opcode.

## The Verified Opcode Reference

### Movement (confirmed via Warubou cutscene trace)
```
$1A  npc_walk_x  npc, delta    Animated horizontal walk (delta in pixels, signed 16-bit)
$1B  npc_walk_y  npc, delta    Animated vertical walk
$0A  npc_move_x  npc, delta    Instant horizontal position change
$0B  npc_move_y  npc, delta    Instant vertical position change
$22  begin_walk                 Start walk-toward sequence (required before $1A/$1B)
$19  wait_movement              Pause script until all pending movement completes
$1D  lock_movement              Suppress NPC facing updates during movement
$1E  unlock_movement            Restore NPC facing updates
```

Movement values are signed 16-bit: negative = left/up, positive = right/down.
1 tile = 16 pixels. $FFE0 = -32 = 2 tiles left. $0030 = +48 = 3 tiles right.

### NPC Visibility & Animation
```
$49  npc_show    npc            Show NPC sprite
$48  npc_hide    npc            Hide NPC sprite
$47  npc_set_state npc          Set NPC sprite state/facing
$1C  trigger_anim  $XXYY        Play animation: XX=type (01=jump, 02=dresser-jump), YY=npc
$0D  npc_write   npc, field, val Write byte to NPC RAM buffer
```

NPC numbers are 0-based within the current room's NPC list.
Field $0000 with value $00 = visible, $40 = hidden (in npc_write).

### Timing
```
$09  delay       frames         Wait N frames (low byte of param)
$4C  long_delay  frames         Extended delay via secondary timer
$19  wait_movement              Wait until movement completes (0 params)
```

### Flow Control
```
$00  if_flag_clear flag, target  Branch to target if event flag NOT set
$01  if_flag_set  flag, target   Branch to target if event flag IS set
$0E  branch_by_screen scr, target Branch if current screen matches
$14  goto         target         Unconditional jump
$08  nop                         No operation
     end ($FFFF)                 End script, return player control
```

### Game State
```
$03  set_flag     flag           Set event flag in $D99B+ bitfield
$02  clear_flag   flag           Clear event flag
$12  write_ram    addr, value    Write value to any RAM address (335 uses!)
$07  init_dialog  param          Set up dialogue mode
$06  inc_counter                 Advance script dialogue counter
```

### Text Display
```
     say $XXXX                   Display text (any word with high byte ≠ $FF)
```
Text IDs route through ROM0 $0AD9 → handler banks $42-$4E → data banks.
See `extracted/text_id_map.json` for 2,067 decoded text strings.

### Screen/Map
```
$0F  map_transition  map, gate, param  Trigger room transition
$40  set_bgm         param             Change background music
$4B  restore_bgm                       Restore previous BGM
$4A  read_saved_bgm                    Read saved BGM value
$24  update_screen_vram                Call screen rendering update
$21  screen_setup    param1, param2    Visual effect setup
```

## Cutscene Construction Pattern

Every cutscene in the game follows this pattern:

```
; --- SCRIPT START (player control taken automatically) ---

; 1. Setup NPCs
npc_write npc#1, field[$0000] = $00    ; make NPC visible
npc_show npc#1                          ; show sprite

; 2. Movement sequence
begin_walk                              ; REQUIRED before walk commands
npc_walk_x npc#0, -32                   ; Terry walks left 2 tiles
npc_walk_x npc#1, +16                   ; NPC walks right 1 tile
wait_movement                           ; wait until both finish

; 3. Dialogue
say $XXXX                               ; display text box
                                        ; (script pauses until player dismisses)

; 4. More movement + effects
trigger_anim npc#0, jump                ; Terry jumps ($0100)
wait_movement
delay 8 frames

; 5. Cleanup
npc_hide npc#1                          ; hide NPC
set_flag $XXXX                          ; mark event as completed

end                                     ; player regains control
```

## How to Add a Custom Cutscene

### Method 1: Modify Existing Script (Safest)
Change parameter values in existing scripts without adding/removing words.
This is what the custom Watabou ROM demonstrates — 9 bytes changed for
completely different behavior.

**Safe changes:**
- Movement deltas (make NPCs walk further/shorter)
- Delay values (speed up/slow down timing)
- Animation params (change jump type)
- Text IDs (different dialogue)
- Flag IDs (different story triggers)
- NPC numbers (move different NPCs)

### Method 2: Replace a Script (Medium Risk)
Replace an entire script's `dw` data. The script must be the SAME SIZE or
SMALLER than the original (pad with `$FF08` NOP if needed). Branch targets
within the script must use correct absolute addresses.

### Method 3: Add New Script Bank (Advanced)
Use an empty ROM bank ($60, $64, $67, etc.) to create a new script data
bank. Redirect `MapTypeDispatch` in bank $04 to route specific map types
to the new bank. This gives unlimited space for custom scripts.

## Real Example: Custom Watabou (Verified Working)

Original behavior: Watabou appears, Terry jumps, Watabou jumps, walks left 3 tiles.
Modified behavior: Watabou jumps FIRST, then Terry, Watabou sprints 7 tiles left.

**Byte changes (ROM offsets in bank $0E):**
```
$38B02: 05 → 01    ; faster reappear (5→1 frames)
$38B0A: 05 → 01    ; faster settle (5→1 frames)
$38B0E: 00 → 01    ; trigger_anim: Watabou jumps first (was Terry)
$38B14: 04 → 01    ; gap between jumps (4→1 frames)
$38B18: 01 → 00    ; trigger_anim: Terry jumps second (was Watabou)
$38B1E: 08 → 01    ; delay before running (8→1 frames)
$38B24: D0 → 90    ; move_x delta: -48 → -112 (sprint 7 tiles left)
$38B30: 30 → 70    ; move_x delta: +48 → +112 (sprint 7 tiles right)
$38B38: 02 → 01    ; exit delay (2→1 frames)
```

## Player Control Mechanism

- ScriptInit sets `$D8D7` bit 0 → player input suppressed
- Script `end` ($FFFF) clears `$D8D7` → player regains control
- During script: `lock_movement`/`unlock_movement` controls NPC facing
- `init_dialog` ($07) sets additional dialogue mode flags
- No explicit "freeze player" opcode needed — it's automatic

## Tools

```bash
# Decompile a specific map's scripts
python3 tools/decompile_script.py --map 0x0E 0x2F        # Bedroom

# Decompile from a specific address
python3 tools/decompile_script.py 0x0E 0x48E4            # Warubou cutscene

# Regenerate script bank assembly (after manual edits)
python3 tools/gen_script_banks.py --apply

# Rebuild ROM
cd disassembly && rm -f game.o game.gbc game.sym game.map && make && md5sum game.gbc
```

## Key Addresses

| Map Type | Name | Bank | Notes |
|----------|------|------|-------|
| $00 | Castle | $0C | 20 scripts, throne room NPCs |
| $01 | GreatTree | $0C | 21 scripts, overworld NPCs + cutscenes |
| $09 | Monster Shrine | $0D | Starry Night shrine (intro) |
| $2F | Bedroom | $0E | 15 scripts, Warubou cutscene, dresser portal |
| $30-$3F | Boss rooms | $0E | Boss encounter scripts |
| $40+ | Late-game | $0F | Post-game content |

---
*Created June 2026. All opcodes verified via SameBoy debugger trace.*
*Custom Watabou ROM tested and confirmed working.*
