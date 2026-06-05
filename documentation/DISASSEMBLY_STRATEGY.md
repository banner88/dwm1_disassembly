# DWM1 Custom Rooms — Disassembly-Based Strategy

## Why the Disassembly Changes Everything

The Mallos31 disassembly (`github.com/Mallos31/dwm`) is a complete, buildable
rgbds disassembly of the ROM. It eliminates the core problem that blocked custom
rooms for 2 weeks: **you can now modify the room loading code at the source level
instead of injecting trampolines into packed ROM data.**

### Key Facts
- **23 completely empty banks** (0x60, 0x64, 0x67, 0x69–0x77, 0x79–0x7A, 0x7C, 0x7E–0x7F)
  = ~368 KB of free space, already structured as proper rgbds SECTION blocks
- The assembler handles all address resolution — no more manual flat-address math
- You can add new labels, modify jump targets, insert data tables freely
- The ROM builds with `make` using `rgbasm` / `rgblink` / `rgbfix`

### What Was Blocking Before
The trampoline approach failed because:
1. The exit checker (Entry 6) reads the pointer table **every step**, including during fades
2. All 4 pointer-table functions return **different data types** (tileset vs interact_ptr vs exit_ptr)
3. WRAM pointers crash due to GBC WRAM bank switching ($D000+) or exit checker timing ($C000+)
4. Commandeering boss rooms for trampoline code was fragile and hard to debug

### What the Disassembly Enables
Instead of trampolines, we modify the actual pointer-chasing code in bank_00b.asm to
support a **bank indirection table** — a clean, maintainable solution.

---

## Architecture: Bank Indirection Table

### Concept
Add a small table that maps map_type → data_bank. When the pointer-chasing code
runs, it checks this table. If the entry is $0B (default), it reads from bank 0B
as normal. If it's a different bank (e.g., $60), it switches to that bank before
following the pointer.

### The Table (in bank 0B, ~107 bytes)
```asm
; Room data bank table — one byte per map_type (0x00–0x6A)
; Default $0B = data is in bank 0B (original behavior)
; Other values = data is in that bank (custom room)
RoomDataBank:
    ds 107, $0B    ; fill with $0B (all original rooms)

; To add a custom room at map_type $20:
;   RoomDataBank + $20 = $60   (data in bank $60)
```

### Modified Pointer-Chasing Code
The four functions that read `$4B43` all share the same pattern. Each gets a
small modification: after reading the pointer from the table, check the bank
table. If non-$0B, do a bankswitch before dereferencing.

```asm
; MODIFIED ReadStepBlock — adds ~20 bytes
ReadStepBlock:
    ld a, [wInGateworld]
    or a
    jr z, .normal_path
    ld hl, $1609
    rst $10
    ret

.normal_path:
    ; Check bank indirection table
    ld a, [wMapID]
    ld hl, RoomDataBank
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    ld a, [hl]                  ; A = data bank for this room
    cp $0B
    jr z, .bank_0b              ; original room, no switch needed

    ; Switch to custom room's bank
    ld [$2100], a               ; ROM bank switch
    push af                     ; save bank number for restore

    ; Read pointer table (now in the custom bank's address space)
    ; The custom bank has its OWN pointer table at $4B43
    ; (or at a different address — see Variant B below)
    ...normal pointer chasing code...

    ; Restore bank 0B
    pop af
    ld a, $0B
    ld [$2100], a
    ret

.bank_0b:
    ; Original code, unchanged
    ld hl, $4b43
    ...
```

### Variant A: Mirror the pointer table structure
Each custom bank ($60, $61, etc.) has its own pointer table at $4B43,
screen_ptr_blocks, step_blocks, interact_blocks, and exit_blocks — all at
addresses in $4000-$7FFF. The existing code works unchanged after the
bankswitch because the address arithmetic is identical.

**Pros:** Minimal code change (just add bankswitch). All existing room data
parsing works as-is.

**Cons:** Each custom room bank must replicate the full data chain. The pointer
table entry at offset `mapID*2` must be valid even though only one map_type
uses this bank.

### Variant B: Simplified custom room format
Custom banks use a simpler layout — a single flat data block per room.
The modified code reads a "custom room pointer" from a separate table instead
of the $4B43 table.

**Pros:** Much simpler data format for the editor to generate.
**Cons:** More code modification needed (different read path for custom rooms).

### Recommendation: Variant A (Mirror Structure)
It's the lowest-risk approach. The existing pointer-chasing code doesn't change
at all — we just add a bankswitch wrapper. The editor generates the full data
chain (pointer table entry → screen_ptr_block → step_block → interact/exit
blocks) into an empty bank. Since we have 16KB per bank and room data is tiny
(~200 bytes per room), we can fit many custom rooms per bank.

---

## Implementation Plan

### Phase 1: Set Up the Build Pipeline
1. Fork Mallos31/dwm, add your annotations to bank_00b.asm
2. Install rgbds: `apt install rgbds` or build from source
3. Verify clean build: `cd disassembly && make` → produces `game.gbc`
4. Verify byte-identical to original ROM (md5sum match)
5. Add your `edits.json` / `build.py` pipeline as a post-build step

### Phase 2: Annotate Data Sections
The disassembly treats data as instructions (mgbdis limitation). Fix this for
the room data area:
1. Find the pointer table at $4B43 in bank_00b.asm (~line 397's reference)
2. Convert the auto-disassembled instructions back to `db` / `dw` declarations
3. Label room data blocks using your existing `dump_all_npcs.py` and
   `dump_all_exits.py` output
4. Verify build still produces identical ROM

### Phase 3: Add Bank Indirection
1. Add `RoomDataBank` table to bank_00b.asm (107 bytes of $0B)
2. Modify the four pointer-chasing functions to check the table
3. Verify all original rooms still work (no regression)

### Phase 4: Create First Custom Room
1. In Empty_bank_060.asm, replace the `nop` padding with:
   - A pointer table entry at the correct offset for map_type $20
   - A screen_ptr_block
   - A step_block with RAM flag pointer, step entries
   - An interact_block with NPCs
   - An exit_block with a return exit
2. Set `RoomDataBank[$20] = $60`
3. Build and test: enter room 0x20 (Castle alias), verify NPCs and exit work

### Phase 5: Integrate with Editor
1. Update `editor.py` Custom Rooms tab to generate the full data chain
2. Export as assembly source (`.asm` file for the custom bank)
3. Build pipeline: editor → .asm → rgbasm → patched ROM
4. Or: editor → edits.json with raw_bytes targeting the custom bank

---

## Data Format Reference

### Custom Bank Layout (e.g., bank $60)
```
$4000: db $60                      ; bank ID (optional)
$4001: ds $B42                     ; padding to match $4B43 offset
$4B43: ; Pointer table entries
       ; Only the entry for our map_type(s) matters
       ; Offset = map_type * 2
       ; e.g., map_type $20 → offset $40 → address $4B83
       dw CustomRoom20_ScreenPtrs

; Screen pointer block (8 bytes = 4 slots × 2)
CustomRoom20_ScreenPtrs:
    dw CustomRoom20_StepBlock      ; screen 0
    dw CustomRoom20_StepBlock      ; screen 1 (same for single-screen rooms)
    dw CustomRoom20_StepBlock      ; screen 2
    dw CustomRoom20_StepBlock      ; screen 3

; Step block
CustomRoom20_StepBlock:
    dw $D9E9                       ; RAM flag pointer (step variable address)
    ; Step 0 entry (6 bytes):
    db $00                         ; step_id
    db $01                         ; tileset
    dw CustomRoom20_NPCs           ; interact_ptr
    dw CustomRoom20_Exits          ; exit_ptr
    db $FF                         ; terminator

; NPC data (5 bytes each + $FF terminator)
CustomRoom20_NPCs:
    db $00, $15, $03, $04, $00     ; standing NPC, sprite $15, at (3,4), script 0
    db $00, $0A, $06, $03, $01     ; standing NPC, sprite $0A, at (6,3), script 1
    db $FF                         ; terminator

; Exit data (7 bytes each + $FF terminator)  
CustomRoom20_Exits:
    db $05, $07, $00, $00, $05, $04, $07  ; exit at (5,7) → Castle, spawn (4,7)
    db $FF                         ; terminator
```

### RAM Flag Addresses for Custom Rooms
Step variables are stored in RAM at addresses like $D9E9. Each room needs a
unique address. Safe candidates for custom rooms:
- $D9E9 (general step variable — may conflict with existing rooms)
- Find unused RAM addresses via SameBoy `examine` during gameplay
- Or use a fixed step value (always 0) if the room has no state variants

---

## What to Keep from the Old Approach

### Keep: editor.py + build.py
The Streamlit editor and JSON-based patching system are excellent for:
- Monster stat editing
- Text editing
- NPC repositioning within existing rooms  
- Exit redirection between existing rooms
- Breeding table changes

### Keep: SameBoy debugging knowledge
All the breakpoint/examine techniques documented in SAMEBOY_GUIDE.md still
apply for testing and debugging.

### Keep: All extracted data
The NPC catalog, exit transitions, sprite reference, etc. are invaluable for
building the custom room data correctly.

### Replace: Raw byte patching for structural changes
Instead of calculating flat addresses and writing raw hex, modify the assembly
source and let rgbasm handle it.

### Replace: Trampoline system
The entire trampoline + WRAM copy approach is obsolete. The bank indirection
table is cleaner, faster, and doesn't have the WRAM banking issues.

---

## NiyaDev Disassembly — Useful Bits

The NiyaDev repo (`github.com/NiyaDev/DWM`) has no bank 0B content but provides:

### rst Handler Documentation (from `src/home/header.asm`)
```
rst $00: Pop HL, use A as index into jump table at return address
rst $08: Load [HL] pointer and JP to it (indirect jump)
rst $10: Cross-bank call. H=bank, L=entry_index.
         Saves current bank, switches ROM bank to H,
         also switches RAM bank (bank 0-$1F → SRAM 0, $20+ → SRAM 1),
         indexes $4001 + L*2 for jump table, calls via rst $08,
         restores original banks.
rst $38: Increment byte at [DE+1]
```

### FUN_030F: Main State Machine Dispatcher
13-entry jump table using `wUNK_START_1` ($C8??) to dispatch to different
game modes across various banks. This is the top-level game loop dispatcher.

### WRAM Labels
Some addresses labeled that overlap with our known map:
- `$C8B7` = `wUNK_START_4` (we know as BGM)  
- `$C8EE` = `wUNK_START_2` (we know as TextSpeed, init'd to 4)
- `$C81D` = `IsGBC`
- `$C846/$C847` = joypad state

These can be merged into the Mallos31 WRAM file for a more complete picture.
