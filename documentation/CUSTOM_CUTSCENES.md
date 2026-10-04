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
- `$FFxx` (where xx ≤ $65 — 102 opcodes, S96) = opcode with xx as the command number; parameter counts: BANK04_SCRIPT_ENGINE "Parameter counts"
- `$FFFF` = script end, player regains control
- Values $0000-$FEFF (with high byte ≠ $FF) = text ID or opcode parameter
- Values $4000-$7FFF (odd-aligned) = branch target addresses

Each opcode consumes 0-3 parameter words after it: `extracted/script_param_counts.json`
(`tools/script_param_counts.py`, handler-derived; S118: $24 / $61 = 1, read through the
script bank). The old PARAM_COUNTS table in `tools/decompile_script.py` is wrong for 36
opcodes (DOC_AUDIT S96).

## The Verified Opcode Reference (S118 rewrite)

**Every opcode, with the editor's names: BANK04_SCRIPT_ENGINE "Script Command Reference
— S118 rewrite" and "Script opcodes as measured (S118)"; in code
`editor2/core/script_ops.py`.** The names this guide used before S118 were partly wrong
(DOC_AUDIT S118): `$47-$4A` are FACE up/down/left/right (not buffer write / hide /
show), `$22` is "walk fast" (not a required "begin walk"), `$0A/$0B` are walks the
script waits for (not instant moves), `$4C` waits for the D-pad.

### Movement (actor 0 = the player, n ≥ 1 = the n-th NPC of the screen)
```
$1A  npc_walk_x  actor, px     Queue a left/right walk (actors walk together)
$1B  npc_walk_y  actor, px     Queue an up/down walk
$19  wait_movement             Wait until every queued walk / program has finished
$22  walk_fast                 The next queued walks run at double speed
$0A  walk_x_wait actor, px     One actor walks; the SCRIPT WAITS for it
$0B  walk_y_wait actor, px
$10  walk_to_x   actor, x      One actor walks to an absolute pixel X (script waits)
$11  walk_to_y   actor, y
$1C  trigger_anim $PPNN        Movement program PP on actor NN: $01 hop, $04 jump,
                               $09 spin jump, $08 appear (flicker in), $0D vanish,
                               $15/$16 fly in, $17/$18 fly off, $02/$0F leap up,
                               $10-$12 drop … (the measured table: BANK04 S118)
$1D  lock_movement             Walks no longer turn the actors (walk backwards)
$1E  unlock_movement
```
Movement values are signed 16-bit pixels: negative = left / up. 1 tile = 16 px.
Speed: 1 px on 3 frames of 4 (32 px ≈ 44 frames), double after `$22`.

### Facing and visibility
```
$47/$48/$49/$4A  face_up/down/left/right  actor
$0C  face        actor, dir      0 down, 1 left, 2 up, 3 right
$0D  npc_write   actor, field, value
                 field 0 = the type byte: $00 shown, $40 hidden (bit 6)
                 actor 0: field = an ADDRESS — $FF90 = the player ($40 hides him)
```
The vanilla way to make someone appear: place the NPC HIDDEN in the room's step list
(type bit 6), then `npc_write n,0,0` (or program $08 for a flicker-in). These run-time
changes reset when the room reloads (the step entry's own bytes come back); for a
lasting change use the step system / flag state rules (ROOM_DATA_FORMAT "Room State
System").

### Timing
```
$09  delay       ticks          Wait; one tick = 8 frames in the field
$4D  long_delay  frames         Wait; counts every frame
$19  wait_movement
$4C  wait_dpad                  Wait for a D-pad press
```

### Flow control, game state, text, screen / map
```
$00  if_flag_clear flag, target  $01 if_flag_set flag, target
$0E  branch_screen scr, target   $15 check_and_branch addr, value, target ([addr] == value)
$14  goto target                 $FFFF end (the player gets control back)
$03  set_flag  $02 clear_flag    $12 write_ram addr, byte   $13 write_ram2 addr, word
$07  init_dialog (before text in a script that did not start by talking)
     text $XXXX (any word with high byte != $FF)    $06 close_text
$3C / $3D  the next text box at the bottom / top
$0F  map_transition map, x, y    $3B warp_fade map, x, y (the wavy boss-exit fade)
$41  set_bgm song   $4B restore_bgm   $21 sound effect
$24 / $61  draw a tile patch (1 param: an address in the script bank)
```

## Cutscene Construction Pattern (as the game does it)

```
; the room's entry script (script 0) or an NPC's talk script
npc_write 1, 0, $00        ; reveal NPC 1 (placed hidden in the step list)
face_left 0                ; Terry faces left
walk_fast                  ; (optional) the next batch at double speed
npc_walk_x 0, -32          ; Terry and NPC 1 walk left 2 tiles together
npc_walk_x 1, -32
wait_movement
init_dialog                ; only in a script that did not start by talking
text $XXXX                 ; a text box (the script waits for A)
close_text
trigger_anim $0401         ; NPC 1 jumps (program $04)
wait_movement
delay 8
npc_write 1, 0, $40        ; hide NPC 1
set_flag $XXXX             ; mark the event done (the entry script tests it first)
end                        ; the player gets control back
```

## The editor: the Cutscenes tab (S118, ROADMAP P3.8 part A)

Every scene of the game and of the project is listed, readable and PLAYABLE in the
editor (EDITOR_DESIGN §5.1d): the storyboard shows each step as a sentence, the
picture of every step is recorded from the real game, and ▶ Play runs the scene in the
game (PyBoy) set up automatically — the recipe is in BANK04_SCRIPT_ENGINE "Playing a
scene". The intro is a chain of three scenes: bedtime ($2F script 0 step 7), the east
room ($2F script 0 step 727, Warubou / Watabou) and the dresser ($2F script 10), which
runs through the tree tunnel ($08), the Starry Shrine ($09), the old man's walk up
GreatTree ($01 script 0, legs keyed on `$D951 = $FF` and the screen) and the Castle
minister ($00) without stopping. Writing new cutscenes in the editor = part B.

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
- During script: `lock_movement`/`unlock_movement` stop / restore walks turning the actors
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
