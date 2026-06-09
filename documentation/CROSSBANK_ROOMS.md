# Cross-Bank Custom Rooms — Technical Reference
---

## PROJECT OVERVIEW

Dragon Warrior Monsters 1 (GBC) ROM editor built with Streamlit. The goal is adding
**custom rooms** to the game — new rooms with custom NPCs, exits, and tilesets stored
in free ROM banks (0x68+), loaded at runtime via patched room-loading code.

**Key files:**
- `/mnt/user-data/uploads/editor.py` — Streamlit editor (has Custom Rooms tab, partially working)
- `/mnt/user-data/uploads/build.py` — Build system (applies edits.json patches to ROM)
- `extracted/edits.json` — Patch data (NOT `edits.json` in root — user confirmed path)
- `/home/claude/dwm/disassembly/` — Cloned from https://github.com/Mallos31/dwm
- Bank 0x0B disassembly: `bank_00b.asm` — THE critical file for room system
- Previous session transcripts: `/mnt/transcripts/` and `journal.txt`

**ROM:** `data/DWM-original.gbc` (2MB, MBC5, 128 banks)

---

## ARCHITECTURE: HOW THE GAME LOADS ROOMS

### Jump Table Dispatch (Bank 0x51 → Bank 0x0B)
The game uses `rst $10` with H=bank, L=entry to dispatch functions via jump tables.
Bank 0x0B's jump table at $4001:

| Entry | Label | Address | Purpose | Reads from ptr table? |
|-------|-------|---------|---------|----------------------|
| 0 | labelb_4015 | $4015 | Tileset/graphics loader | NO — uses table $26DD |
| 1 | labelb_4088 | $4088 | Graphics loader variant | NO — uses $26DD |
| 6 | labelb_451d | $451D | Exit checker (RUNS EVERY STEP) | YES → exit_ptr |
| 7 | labelb_470f | $470F | Room initializer (transition) | YES → interact_ptr |
| 8 | Call_00b_4239 | $4239 | Tileset/step reader | YES → step_id+tileset |

### The Pointer Table ($4B43)
107 entries × 2 bytes at bank 0x0B local $4B43. Indexed by `wMapID` ($C968).
Each entry points to a room's screen pointer block within bank 0x0B ($4000-$7FFF).

### Room Data Chain
```
Pointer table[$4B43 + mapID*2] → screen_ptr_block (8 bytes: 4 slots × 2)
  → slot[screen_index] → step_block (ram_flag_ptr + step_entries)
    → step_entry[step_value × 6] = [step_id][tileset][interact_ptr][exit_ptr]
      → interact_block: NPC entries (5 bytes each) + FF terminator
      → exit_block: exit entries (7 bytes each) + FF terminator
```

### Four Functions Read the Pointer Table ($4B43)
All four have IDENTICAL pointer-read code (`ld hl,$4B43 / ld a,[wMapID] / ...`)
but return DIFFERENT data from the step entry:

| Function | `2A 66 6F` addr | Flat addr | Skips | Returns |
|----------|----------------|-----------|-------|---------|
| Call_00b_4239 | $4251 | $02C251 | 0 bytes | DE = step_id + tileset |
| Call_00b_4274 | $4287 | $02C287 | 2 bytes (id+tileset) | HL = interact_ptr |
| ~$44A7 func | $44B4 | $02C4B4 | 4 bytes (id+tileset+interact) | HL = exit_ptr |
| labelb_451d | $4540 | $02C540 | 4 bytes (all above) | HL = exit_ptr |

### Transition State Machine
Controlled by `$C8EA` (transition phase) and `$d9f4` (game state):

1. Exit checker (entry 6) detects exit match → sets `wIsPlayerChangingMaps` ($C96C)
2. Entry 0 (`labelb_4015`): checks $C96C → copies $C96D→wMapID, loads tileset from $26DD
3. Fade animation runs (controlled by $C8EA bit 7)
4. Entry 7 (`labelb_470f`): checks $C8EA bit 7:
   - If SET → calls bank 6 entry 4 (fade handler), returns
   - If CLEAR → calls `Call_00b_4274` (room init with interact_ptr)
5. Game renders room, exit checker resumes on every step

---

## KEY DISCOVERIES (PROVEN BY TESTING)

### What Works ✓
1. **Trampoline at $4287 works** for normal rooms (passthrough verified)
2. **Bank switching** from trampoline → $3FE8 copy routine works (DI/EI protected)
3. **Copy from bank 0x68 to WRAM** works mechanically
4. **Map_type 0x20** (Castle alias) uses the normal room loader path
5. **$3FE8** (last 24 bytes of bank 0x00) is safe to overwrite — doesn't crash normal gameplay
6. **ROM pointers ($4000-$7FFF) work** — aliasing to Copycat House via pointer table loads correctly

### What Fails ✗
1. **WRAM pointers in $D000-$DFFF crash** — "Illegal Opcode" because GBC switchable WRAM banking
2. **WRAM pointers in $C000-$CFFF cause white screen** — the exit checker (entry 6) reads the pointer table DURING the fade transition, before room init runs, gets garbage from unpopulated WRAM, blocks the state machine
3. **Map_type 0x65-0x69** (Labyrinth aliases) use the GATE path, completely bypassing our trampoline
4. **Patching all 4 functions** with the same trampoline breaks exits because they return different data types

### The Root Problem
The game engine assumes ALL room data pointers are in **$4000-$7FFF** (bank 0x0B ROM).
WRAM pointers fail because:
- $D000+ : GBC WRAM bank switching corrupts data
- $C000+ : Exit checker reads from pointer table DURING fade (before copy runs), gets garbage, blocks state machine from advancing to room init phase

---

## KEY MISTAKES MADE (LEARN FROM THESE)

1. **Wrong patch address ($4287 vs $4289)**: Miscounted the search output format. The search printed the address of the `21` byte, with context starting 2 bytes before. I counted from the context start instead of the label. Cost: several debugging rounds.

2. **Patching all 4 functions identically**: Each function returns different data (interact_ptr vs exit_ptr vs tileset). A universal trampoline that always returns interact_ptr broke exit detection.

3. **Using bank 0x00 "free space" at $3A83**: The 24×0x00 bytes were part of a data table, not free space. Overwriting them crashed on every step. Rule: **runs of 0x00 in bank 0x00 are DATA, not padding.** Only $3FE8 (24×0xFF at bank end) is safe.

4. **Assuming the trampoline fires for destination rooms**: It only fires for the CURRENT room during normal gameplay. The destination room is loaded by entry 7 (labelb_470f) which only runs AFTER the fade completes. If the fade gets stuck (because of WRAM garbage), entry 7 never runs.

5. **WRAM buffer in switchable WRAM ($D378)**: GBC has switchable WRAM at $D000-$DFFF. The game switches WRAM banks during transitions, making our data disappear.

6. **Jr offset miscalculation**: The first trampoline had `jr z, +5` instead of `+9`, jumping into the middle of an instruction. Always verify jr offsets by counting bytes explicitly.

7. **save_edits data loss bug**: `k.startswith("0")` matched ALL keys, wiping edits. Now has .bak backup.

---

## THE SOLUTION: MULTI-TRAMPOLINE SYSTEM

### Concept
Commandeer 2-3 boss rooms in bank 0x0B for trampoline code space. Each of the 4 pointer-table functions gets its own trampoline that:
1. Reads pointer from table
2. Detects cross-bank marker (bit 7 of high byte)
3. Copies room data from bank 0x68 to WRAM $CF00 (bank 0, non-switchable) — ONCE via flag
4. Returns the CORRECT data type for that specific function

### Space Budget
| Room | Address | Bytes | Use |
|------|---------|-------|-----|
| 0x4F DarkDrium | $77A9 | 52 | Trampoline A (interact_ptr) — ALREADY DONE |
| 0x4E DeathMore | $775D | 76 | Trampoline B (exit_ptr) |
| Pick another | varies | 47+ | Trampoline C (tileset) or shared copy routine |

### Trampoline Design (per function)
Each ~45 bytes:
```
; Read pointer from table
ld a,[hl+] / ld h,[hl] / ld l,a        ; 3 bytes
; Check cross-bank
bit 7,h                                  ; 2 bytes
jr z, .normal                            ; 2 bytes
; Copy if not yet done (check flag at $CEFF or similar)
ld a,($CEFF) / or a / jr nz, .skip_copy ; 5 bytes
push hl / ld a,$68 / ld hl,$4000        ; 6 bytes
call $3FE8 / pop hl                      ; 4 bytes
ld a,1 / ld ($CEFF),a                   ; 4 bytes (set "copied" flag)
.skip_copy:
; Function-specific data reading:
;   Trampoline A: inc hl / inc hl / ld a,[hl+] / ld h,[hl] / ld l,a (interact)
;   Trampoline B: inc hl ×4 / ld a,[hl+] / ld h,[hl] / ld l,a (exit)
;   Trampoline C: ld e,[hl] / inc hl / ld d,[hl] (tileset)
; Plus remaining Steps 2-4 code
.normal:
; Original Steps 2-4 code for this function's return type
ret
```

### Copy Routine at $3FE8 (22 bytes, already working)
```
DI / ld ($2100),a / ld de,$CF00 / ld b,128
.loop: ld a,[hl+] / ld [de],a / inc de / dec b / jr nz,.loop
ld a,$0B / ld ($2100),a / EI / ret
```

### Room Data Format (128 bytes at bank 0x68 $4000)
All internal pointers use $CF00-$CF7F addresses (WRAM bank 0, non-switchable):
```
+$00: screen_ptrs (8 bytes) — all slots point to $CF08
+$08: step_block (14 bytes) — RAM flag self-refs to $CF0A (=0x00)
+$20: interact_block_0 (24 bytes max)
+$38: interact_block_1 (24 bytes max)
+$50: exit_block_0 (24 bytes max)
+$68: exit_block_1 (24 bytes max)
```

### Flag Management
- Copy flag at $CEFF (or nearby WRAM bank 0 address with 0 refs)
- Set to 1 after first copy, prevents redundant copies
- Must be cleared during TRANSITION START (before any function reads the new room)
- Could be cleared by the transition handler hook (if we add one) or by the
  trampoline itself (clear on map_type change detection)

---

## PLAN FOR NEXT SESSION

### Phase 1: Study the Disassembly (Claude does this, no user testing needed)
1. Read `bank_00b.asm` fully — map ALL functions, labels, cross-references
2. Read the exit checker (`labelb_451d`) completely — understand exit scanning loop
3. Read the transition handler (`labelb_470f` and its callers) — understand state machine
4. Read bank 6 fade handler (`$0604`) — understand what clears $C8EA bit 7
5. Read bank 51 game loop — understand dispatch order and state machine ($d9f4)
6. Document: which functions read pointer table, when they run, what they expect

### Phase 2: Design Multi-Trampoline (Claude does this)
1. Determine exact bytes needed per trampoline
2. Determine which boss rooms to commandeer (need exact byte counts)
3. Design the flag management (copy-once + clear-on-transition)
4. Design each trampoline variant (interact/exit/tileset)
5. Handle the "Steps 2-4 divergence" — each function has different code after step resolution

### Phase 3: Implement and Test (needs user)
1. User provides ROM for analysis if needed
2. Build the multi-trampoline patches
3. Test: normal rooms still work (Library, Well, Castle transitions)
4. Test: custom room loads (enter via Well → map_type 0x20)
5. Test: exits work in custom room (can leave back to Castle)
6. Test: NPCs appear correctly
7. Test: screen doesn't glitch

### Phase 4: Integrate into Editor
1. Update editor.py Custom Rooms tab with working infrastructure
2. Room designer generates correct 128-byte data format
3. Build system applies all patches correctly
4. Test end-to-end: design room in editor → build → play

---

## DISASSEMBLY ANNOTATION PLAN

### Available Resources
- Mallos31 disassembly: `https://github.com/Mallos31/dwm/tree/master/disassembly`
  (already cloned to `/home/claude/dwm/disassembly/`)
- Original ROM: `data/DWM-original.gbc` (user can upload)
- User's existing analysis tools: dump_steps.py, dump_all_npcs.py, dump_all_exits.py

### Key Files to Annotate
1. **bank_00b.asm** (CRITICAL): Room system, exits, transitions, NPCs
   - Functions: $4015, $4088, $40ce, $4213, $4239, $4274, $4332, $43a4, $451d, $470f, $4488
   - Pointer table at $4B43
   - Exit scanning loop
   - Room initialization
   - Step block resolution

2. **bank_000.asm**: Core engine, rst handlers, bank switching
   - rst $10 dispatcher (cross-bank call mechanism)
   - Bank management patterns

3. **bank_051.asm**: Game main loop, state machine dispatcher
   - $d9f4 state machine
   - Which entries are called when
   - Transition flow control

4. **bank_006.asm**: Fade/transition animation
   - $0604 handler
   - What controls $C8EA

5. **bank_015.asm**: Writes to $C8EA (multiple locations)
   - Transition phase management

### Annotation Method
- Read disassembly files systematically
- Cross-reference with known RAM addresses (wMapID=$C968, wInGateworld=$C969, etc.)
- User can upload ROM for hex verification when disassembly is ambiguous
- Focus on the ROOM LOADING PIPELINE, not the entire game

---

## WHAT THE USER NEEDS TO TEST (Future Sessions)

1. **Breakpoint at $470F** with the $CF00 build — does entry 7 ever fire? Check `$C8EA`:
   ```
   breakpoint $470F
   (enter well)
   print [$c8ea]
   ```

2. **Breakpoint at $451D** (exit checker entry) — does it run during transition with new mapID?
   ```
   breakpoint $451D
   (enter well, continue until $451D fires)
   print [$c968]    ; what mapID?
   ```

3. **Once multi-trampoline is built**: test all room transitions (Castle↔GreatTree↔custom)

4. **Verify WRAM bank 0 safety**: play for 5+ minutes with various activities,
   check if $CF00-$CF7F gets corrupted

---

## IMPORTANT CONSTANTS

```
wMapID          = $C968   ; current room map type
wInGateworld    = $C969   ; flag: in gate/labyrinth
wIsPlayerChangingMaps = $C96C  ; transition pending flag
dest_map_type   = $C96D   ; destination map type (from exit)
gate_flag       = $C96E   ; gate transition flag
screen_index    = $C925   ; current screen within room
ptr_table       = $4B43   ; room pointer table (bank 0x0B)
tileset_table   = $26DD   ; tileset graphics table (bank 0x00)
transition_phase = $C8EA  ; bit 7 controls fade state
game_state      = $d9f4   ; main loop state machine
```

## SAFE ROM LOCATIONS FOR PATCHES
- **$3FE8** (bank 0x00, 24 bytes): confirmed safe, used for copy routine
- **$77A9** (bank 0x0B, 52 bytes): DarkDrium room data, confirmed unused
- **$775D** (bank 0x0B, 76 bytes): DeathMore room data, available to commandeer
- **$3A83** (bank 0x00, 24 bytes): **UNSAFE** — active data table, DO NOT USE

## MAP TYPES FOR CUSTOM ROOMS
- **0x20-0x22**: Castle aliases, use NORMAL room loader path ✓
- **0x65-0x69**: Labyrinth aliases, use GATE path ✗ (bypasses trampoline)
- **0x0B, 0x0E, 0x11, 0x14, 0x15**: Castle aliases, likely normal path (untested)
