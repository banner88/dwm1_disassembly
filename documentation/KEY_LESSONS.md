> **NOTE:** The files described here are EDITOR PATCHES, not repo changes. The repo always builds to the original MD5. The editor applies these patches at build time.

# Key Lessons — Cross-Bank Room Implementation

## The Debugging Timeline (19 versions)

This document records every bug encountered and the root cause. Future implementers: READ THIS FIRST. Every one of these bugs will bite you if you don't understand why.

### v1-v2: Inserting bytes into banks with raw embedded pointers
**Symptom**: New game crashes, library has inverted colors, everything broken.
**Root cause**: Banks $01 and $17 have data sections with raw `db` pointer bytes (e.g., `db $BD, $48` = pointer to $48BD). These are NOT labels. Inserting code bytes shifts data, breaking every embedded pointer. Bank $01 had 6,601 byte diffs. Bank $17 had 9,552.
**Fix**: Use same-size `ld a,[wMapID]` → `call ROM0Helper` replacements (3 bytes each). Zero data shifting.
**Rule**: NEVER insert bytes into banks without verifying all data pointers use labels. Bank $0B tolerates insertions IN PATCHES ONLY (its data section is pinned at $4B43). Banks $01, $17 (and $04) are NOT safe anywhere. And `disassembly/` itself admits ZERO byte-changing edits of any kind — a bank-$0B 'safe' refactor there is what broke byte-perfection for several sessions (DOC_AUDIT.md A.9).

### v3: rst $10 clobbers register A
**Symptom**: Tileset graphics completely scrambled (wrong tileset loaded).
**Root cause**: `rst $10` return sequence does `pop af`, restoring A to the saved bank number ($0B), not the function's return value. My Entry 0 patch expected A to contain the source mapID from bank $60.
**Fix**: Return values via DE or HL (preserved by rst $10), or use ROM0 `call` helpers that don't clobber A.
**Rule**: rst $10 destroys A on return. Use DE/HL for return values, or avoid rst $10 entirely.

### v3-v4: NPC/exit copy terminates on internal $FF bytes
**Symptom**: Room crashes on entry, or only partial NPC data loaded.
**Root cause**: Copy loop checked every byte for $FF terminator. NPC entries have $FF in the spawn param byte (byte 1) and script_id byte (byte 4). The copy stopped after 2 bytes.
**Fix**: Copy 5-byte (NPC) or 7-byte (exit) entries at a time. Only check the FIRST byte for $FF.
**Rule**: The $FF terminator is the first byte of an ENTRY, not any byte in the stream.

### v5-v7: Movement completely frozen (correct graphics)
**Symptom**: Room renders perfectly, NPCs visible, but player cannot move at all. Can change facing direction and see walk animation, but character stays in place.
**Root cause**: THREE unpatched mapID table lookups:
1. **ROM0 collision threshold** ($26E3, ×8) — reading past 107-entry table gave wrong threshold, classifying ALL tiles as walls
2. **Room entry script** (bank $01) — ScriptInit with mapID $6B routed to bank $0F which had no valid entry → script engine read garbage → hung with script-active flag set → input suppressed
3. **NPCWalkDataTable** (bank $01, $4506, ×4) — reading past table bounds

**Fix**: Same-size `call MapIDClampForPalette` for all three sites, plus the $5E7D table.
**Rule**: EVERY table indexed by mapID must be found and patched. Search ALL banks for `ld a, [wMapID]` followed by table arithmetic.

### v8: Yellow palette
**Symptom**: Entire room palette turns yellow.
**Root cause**: MapIDClampForDispatch was returning $65 (RET-only handler) instead of $00 (Castle handler). Castle's VRAM handler maintains display state needed for correct palette. Without it, palette corrupts.
**Fix**: Return $00 (Castle) from MapIDClampForDispatch, not a bare RET handler.
**Rule**: The VRAM dispatch handler for custom rooms must be Castle's ($00), not a no-op.

### v11-v12: Wrong source mapID (WRAM timing)
**Symptom**: Tileset scrambled when entering MedalMan room (showed Castle tiles).
**Root cause**: MapIDClampForPalette read wCustomRoomFlag which was set by CustomPtrChase. But Entry 0 calls MapIDClampForPalette BEFORE CustomPtrChase runs. wCustomRoomFlag was 0 (uninitialized) → returned $00 (Castle) instead of $16 (MedalMan).
**Fix**: Compute source mapID directly in ROM0 via conditional logic, not WRAM.
**Rule**: MapIDClampForPalette is called BEFORE bank $60 functions. It cannot depend on WRAM values set by bank $60.

### v14-v17: $FFFF screen crash in multi-screen rooms
**Symptom**: Crash when scrolling to non-existent screen in Castle clone.
**Root cause**: CustomPtrChase read $FFFF from sub-table for unused screens, then dereferenced it. Initial fix used DummyStepEntry with tileset_bank=$00 — the decompressor then read RST handler bytes as tile data.
**Fix**: DummyStepEntry must use VALID tileset data (e.g., step_id=1, tileset_bank=$2A). DummyExits must have actual exit entries so the player can leave.
**Rule**: Every dummy/fallback entry must reference valid data in valid banks.

### v14-v18: Spawn position and screen byte confusion
**Symptom**: Player spawns at wrong position, or in wrong GreatTree screen, or can't move sideways.
**Root cause**: Screen byte in exit data indexes the $2DE7 table AND has a bit 7 flag. Using $88 (entry 8 + bit 7) gave different results than $80 (entry 0 + bit 7). Different existing rooms use different screen bytes for the same destination.
**Fix**: Copy the EXACT screen byte from an existing room that exits to the same destination. WellStairway uses $08 for GreatTree screen 8.
**Rule**: Don't guess screen bytes. Find an existing exit to the same destination and copy its screen byte + spawn coordinates exactly.

---

## Method: Finding ALL mapID Table Lookups

Run this search across all bank files:
```bash
grep -rn "ld a, \[wMapID\]" bank_*.asm | grep -v "^.*:;"
```

Then for each hit, check if the next few lines use A as a table index:
```bash
# Look for: add, ld l/a, add hl, rst $00 after wMapID load
```

Every table lookup with mapID must be patched for custom rooms (mapID ≥ $6B).

**Complete list found (11 sites across 4 banks):**
- Bank $0B: 6 sites (4 reader functions + 2 tileset entries)
- Bank $01: 4 sites (dispatch, walk data, script, special effects)
- Bank $17: 2 sites (palette lookups)  
- Bank $00: 1 site (collision threshold)

---

## What NOT To Do

1. **Don't use WRAM trampolines** — the original plan was to copy room data to WRAM buffers via a ROM0 trampoline. This is unnecessary. rst $10 calls to bank $60 work directly.

2. **Don't try SharedPtrChase overrides** — modifying SharedPtrChase to check a WRAM flag was another early plan. The 4-caller intercept approach is simpler and more maintainable.

3. **Don't insert bytes into bank $01 or $17** — use same-size call replacements only.

4. **Don't assume rst $10 preserves A** — it doesn't. Use DE/HL or ROM0 calls.

5. **Don't use byte-by-byte copy for NPC/exit data** — use entry-sized copies (5 or 7 bytes).

6. **Don't guess screen bytes or spawn coordinates** — find an existing exit to the same destination and copy exactly.

---

## Session 2 Lessons — Custom NPC Scripts, Text & Items

### rst $10 entry index: L = entry NUMBER, not byte offset
**Symptom**: Every custom dispatch call crashed (white screen).
**Root cause**: rst $10 does `add hl,hl` internally (ROM0 $0020). L is the entry NUMBER. Entry 4 = `$6004`, NOT `$6008`. Entry 5 = `$6005`, NOT `$600A`.
**Rule**: Always use entry number for L. The ×2 multiplication happens inside rst $10.

### Script index 0 = room entry script
**Symptom**: Every screen scroll in custom Castle room froze the game.
**Root cause**: Bank $01 ($4C3D) runs wScriptNPCId=0 on every room enter and scroll. Script table index 0 had NPC dialogue → text queued during scroll → freeze.
**Fix**: Index 0 must be `dw $FFFF` (no-op). NPC scripts at index 1+. NPC data byte 4 must reference 1+.
**Rule**: Script pointer table index 0 is RESERVED for room entry. Never put NPC dialogue there.

### $E7 is CHOICE, not END
**Symptom**: Text displayed but YES/NO boxes appeared after every message.
**Root cause**: TEXT_SYSTEM.md documented $E7 as "END". It's actually the CHOICE control code (shows YES/NO box, sets $C83C). Text strings actually end with `$F7 $F0`.
**Rule**: Don't trust documentation labels. Verify against ROM data. `grep` for the byte in actual text data before assuming.

### $EE needs $EF before it
**Symptom**: Second line overwrites first line instead of appearing below.
**Root cause**: $EE (NEWLINE) alone resets cursor position. Must use `$EF $EE` (PAGE + NEWLINE) for proper line break.
**Rule**: Line breaks = `$EF $EE`, never `$EE` alone.

### YES/NO is two-part: text + script
**Symptom**: YES/NO box appeared but no follow-up message regardless of choice.
**Root cause**: Spent 6 iterations guessing at text-engine-internal mechanisms. The answer: original scripts use opcode $15 to check $C83C after text. Found immediately by `grep -rn "c83c" bank_0*.asm`.
**Fix**: Text ends with `$E7 $F0`, script uses `$FF15 / $C83C / $0001 / branch_target`.
**Rule**: When you don't know how something works, **grep for how the original game does it**. Don't theorize about engine internals.

### Opcode $04 is NOT "give item"
**Symptom**: White screen crash when trying to give Beef Jerky.
**Root cause**: Opcode $04 is GameActionDispatch (dispatches through bank $09 jump table). Index $13 (Beef Jerky) was past the table bounds → jumped to garbage.
**Fix**: Use opcode $12 (WriteRAM) to write item ID directly to inventory address.
**Rule**: Always verify opcode behavior against actual handler code, not comment labels.

### Text pointer table needs two levels
**Symptom**: Text displayed garbage or crashed.
**Root cause**: `SaveBankAndSwitch` (ROM0 $0940) does two-level indexing: `table[$C822*2]` → section, `section[$C823*2]` → text address. A flat pointer table causes the engine to read text bytes as pointers.
**Rule**: Custom text pointer table structure must be: top-level table of section pointers, each section is a table of text data pointers.

### Method: finding script patterns
When implementing new behavior (YES/NO, item give, etc.):
```bash
# 1. Find the RAM variable involved
grep -rn "c83c" disassembly/bank_0*.asm

# 2. Find scripts that USE that variable
grep "C83C" extracted/all_scripts.json

# 3. Copy the exact opcode pattern from the original script
```
This takes 30 seconds. Guessing takes hours.

### NEVER insert bytes into bank $04
**Symptom**: Visual glitches EVERYWHERE (corrupted sprites, unreadable text, broken menus) even in unmodified areas of the game.
**Root cause**: Something outside bank $04 references bank $04 addresses by hardcoded value (not labels). Inserting 3 bytes shifted all subsequent addresses → global corruption.
**Fix**: Use wrapper in padding area. Redirect jump table entry to wrapper. Zero bytes inserted in existing code. Original handler completely untouched.
**Rule**: Add banks $04 to the "NEVER insert bytes" list alongside $01 and $17. Use same-size replacements or wrappers in free space only.

---

## Session 3 Lessons — Monster Give, Teleport, BGM

### Opcode handlers that use bare `ret` freeze in custom scripts
**Symptom**: Game freezes after opcode $29 (AddMonster) executes from a custom NPC script.
**Root cause**: The script engine dispatches opcodes via `rst $00` → `jp hl` (NOT `call`). Handlers must end with `jp Jump_004_55f5` (ScriptExecContinue) to return to the script loop. Handlers ending with bare `ret` pop a stale return address and crash. Opcodes $29 (AddMonster) and $2A (GiveItem) both have this bug.
**Fix**: Redirect jump table entry to a wrapper: `call original_handler; jp Jump_004_55f5`. GiveItem already had this fix. AddMonster now shares the `jp` via `SharedScriptContinue` to save space.
**Rule**: Any new opcode used in custom scripts that ends with `ret` instead of `jp Jump_004_55f5` needs a wrapper. Check the handler's last instruction before using it.

### Opcode $0E is NOT teleport — $0F is
**Symptom**: Would have been "NPC talks, nothing happens" if anyone used $0E for teleport.
**Root cause**: Bank $04 inline comment at $59D2 said "$0E = SetMapTransition". BANK04_SCRIPT_ENGINE.md also said $0E = SetMapTransition and $0F = SetScreenScroll. Both wrong. $0E = BranchByScreen (branches if wScreenIndex matches param). $0F = MapTransitionFull (the real teleport).
**Fix**: Corrected all three docs (bank_004.asm comment, BANK04_SCRIPT_ENGINE.md, ROADMAP.md).
**Rule**: Always verify opcode behavior against the HANDLER CODE, not against comments or doc labels. Comments have been wrong multiple times ($E7, $04, $29, $0E).

### Bank $04 end-of-bank padding is exhausted
**Space accounting**: Original ROM had 40 bytes free at $7FD8-$7FFF. After all patches: DispatchBank0F_Ext (10 bytes) + TextQueueCheck_Ext (19 bytes) + AddMonsterWrapper (3 bytes) + SharedScriptContinue (3 bytes) + GiveItemWrapper (3 bytes) + jr (2 bytes) = 40 bytes. Zero bytes remaining. Any future bank $04 wrapper needs space from elsewhere (optimize existing code, or use a different bank's padding).
**Rule**: Track free space in bank $04 — it's a critical, shared resource.

---

## Session 4 Lessons — Custom Tile Layouts

### Player spawn comes from the SOURCE room's exit data, not the destination
**Symptom**: Changing $8F NPC spawn marker and MapTransitionFull script coordinates in bank $60 had no effect on player spawn position.
**Root cause**: The player enters Room $6B via `Exit_GreatTree_s8` in bank_00b.asm: `db $04, $05, $6B, $00, $00, $07, $06`. Bytes 5-6 of the exit data ($07, $06) are the spawn position in the DESTINATION room. The $8F marker in the destination room's NPC table and any teleport script coordinates are separate mechanisms — the exit data takes priority for normal room transitions.
**Fix**: Change bytes 5-6 of `Exit_GreatTree_s8`'s Room $6B exit entry.
**Rule**: To move the player spawn for Room $6B, edit the exit in `Exit_GreatTree_s8` (bank_00b.asm), not bank_060.asm. The source room's exit controls where the player appears.

### MapIDClampForPalette is hardcoded in ROM0, not table-driven
**Symptom**: Changing `CustomSourceMapTable` in bank $60 from $16 to $04 had no effect — room still loaded MedalMan tileset.
**Root cause**: `MapIDClampForPalette` at ROM0 $3FE8 has a hardcoded `ld a, $XX` instruction per custom room. It does NOT read from `CustomSourceMapTable` in bank $60. The table in bank $60 is dead code for this purpose.
**Fix**: Change the `ld a, $XX` byte directly in `patches/bank_000.asm`.
**Rule**: To change which tileset a custom room uses, edit `MapIDClampForPalette` in `patches/bank_000.asm`. The `CustomSourceMapTable` in bank_060.asm is not wired to GFX/palette loading.

### GBC palette attributes are per-position, causing color mismatches in custom layouts
**Symptom**: Tiles placed at new positions in a custom layout show wrong colors (e.g., blue instead of brown). Tiles that happen to be at the same position as the source room look correct.
**Root cause**: The GBC BG attribute map (256 bytes, loaded from bank $17 via the source mapID) assigns a palette to each SCREEN POSITION, not each tile index. When a custom layout moves tiles to different positions, the palette assignment doesn't follow.
**Fix path (not yet implemented)**: Generate custom attribute data using the tile→palette mapping (75 bytes compressed, stored in bank $64 entry 1). Redirect bank $17's attribute lookup for custom rooms using the ~8KB free space at $60DB and unused mapID slot $65. Palette color data ($56DD) stays the same — only the position→palette mapping changes.
**Rule**: Changing a tile layout without changing the attribute map produces palette mismatches. Full custom room support requires custom attribute data alongside the layout.

### Bank $17 has ~8KB free space at $60DB-$7FF7
Contrary to initial analysis ("bank $17 is full"), the LZSS attribute data ends well before the bank boundary. Addresses $60DB-$7FF7 are all nops — available for custom attribute entries, intercept code, and future expansion.

---

## Session 5 Lessons — Palette Attributes & Collision Thresholds

### GBC palette attribute format is nibble-packed, not byte-per-tile
**Symptom**: Initial attr data analysis assumed each byte was one tile's attribute (like standard GBC VRAM attribute bytes). Produced 512-byte maps that didn't match the game's 256-byte format.
**Root cause**: The game uses a custom compressed format: 256 bytes = 8 rows × 32 bytes. Each row covers 2 tile rows. Each 32-byte row: [10 bytes for even row][6 padding][10 bytes for odd row][6 padding]. Each byte is nibble-packed: high nibble = left tile's palette (0-7), low nibble = right tile's palette (0-7). Total: 10×2 nibbles × 8 rows × 2 halves = 320 palette assignments = 20 cols × 16 rows.
**Fix**: `tools/generate_attr_map.py` generates correct 256-byte nibble-packed format. Verified by decompressing vanilla Farm attr data and cross-referencing with tile layouts from the HTML editor.
**Rule**: The attr map is NOT standard GBC VRAM attributes. It's a custom nibble-packed format decompressed to $C200, then the engine copies it to VRAM BG attributes.

### Collision threshold table uses ×8 stride, not ×1
**Symptom**: Reading ROM0 $26E3 as consecutive bytes gave threshold=0 for MedalMan (mapID $16), implying all tiles are walls — clearly wrong since the player walks in that room.
**Root cause**: The code does `add hl,hl; add hl,hl; add hl,hl` (×8) before indexing. Each mapID's entry is 8 bytes apart, not 1. The first byte at each 8-byte entry is the threshold.
**Fix**: Read `rom[$26E3 + mapID * 8]` instead of `rom[$26E3 + mapID]`. MedalMan's correct threshold is 64 (tiles <64 walkable, ≥64 wall).
**Rule**: Collision table: ROM0 $26E3, stride 8 bytes per mapID. Threshold = first byte. Tile index < threshold = WALL (blocked). Tile index ≥ threshold = WALKABLE. `jr c` after `cp [hl]` means tile < threshold → B=$FF (BLOCKED); tile ≥ threshold → B=$0F (passable). **CORRECTION** (Session 6): Previous version had walkable/blocked swapped. User verified across every room with overlay: floor tiles always have index ≥ threshold, walls always < threshold. $FF = blocked, $0F = walkable.

### CustomAttrCheck must match exact mapID, not range
**Symptom**: Room $6C (Castle tileset) showed scrambled palettes after the attr intercept was added.
**Root cause**: `cp CUSTOM_ROOM_START / jr nc` caught ALL custom rooms (≥ $6B), including $6C. Room $6C got Room $6B's Farm attr data instead of its own Castle attrs.
**Fix**: Changed to `cp $6B / jr z` — only exact match. Room $6C+ falls through to MapIDClampForPalette as before.
**Rule**: Per-room intercepts must match exactly. When adding more custom rooms with custom attr data, extend with additional `cp $6C / jr z` etc., not a range check.

### Bank $17 free space starts at $6C75, not $60DB
**Symptom**: KEY_LESSONS.md previously stated "~8KB free space at $60DB-$7FF7".
**Root cause**: The $60DB figure came from early analysis of the LZSS attribute data endpoint. Actual measurement: last non-zero byte is at offset $2C74 (addr $6C74), so free space starts at $6C75.
**Fix**: CustomAttrCheck placed at $6C75 (22 bytes). Remaining free: ~4981 bytes at $6C8B-$7FFF.
**Rule**: Always verify free space boundaries against the ROM, not previous documentation.


---

## Session 6 Lessons — Tileset Mashup & Editor

### CORRECTION: Collision threshold direction was documented backwards
**Symptom**: Editor walkability overlay showed walkable tiles as walls and vice versa, confirmed by user across EVERY room.
**Root cause**: Session 5 documented "tile < threshold = walkable, $FF = passable." This is BACKWARDS. In bank $01, `cp $FF; jp nz, $51B2` — when B=$FF the code does NOT jump (continues to clear movement flag = BLOCKED). When B=$0F, it JUMPS to the movement handler (ALLOWED).
**Fix**: `isWalkable` in editor changed to `tileIdx >= threshold`. Build tool sorts WALL tiles first (low indices), walkable after. Threshold = wall count.
**Rule**: tile < threshold → $FF → BLOCKED. tile ≥ threshold → $0F → WALKABLE. This was proven empirically by the user across every room with blue/orange overlay.

### Tileset PNG and tile data MUST use identical flat indexing
**Symptom**: 84% of NORDEN tiles showed wrong colors in ROM — grey stone appeared orange, floor appeared solid white, bookshelf tiles were completely different.
**Root cause**: The NORDEN tileset PNG was organized in 2×2 meta-tile groups (tiles 0,1 = top of meta-tile 0; tiles 2,3 = bottom). But the editor draws tiles using flat left-to-right indexing: `x=(idx%16)*8, y=(idx//16)*8`. This meant tile index 2 read from PNG position (16,0) but the actual tile 2 was at (0,8). The editor showed one tile, the build tool read a different one.
**Fix**: Rebuild tileset PNG, 2bpp, and palette JSON all in flat scan order (left-to-right, top-to-bottom, 16 tiles per row). Verify with: `for each tile, PNG colors at flat position ⊆ JSON stored colors`.
**Rule**: The tileset PNG, 2bpp file, and palette JSON must ALL index tiles in the same order. The editor uses flat order. NEVER use meta-tile-internal ordering for tile indices.

### 2bpp re-encoding required when merging subset palettes
**Symptom**: Tiles with 3 unique colors sharing a 4-color palette slot rendered wrong — grey pixels appeared white.
**Root cause**: A 3-color tile [grey, brown, black] encodes grey as index 0 (lightest of its own palette). When placed in a 4-color palette [white, grey, brown, black], index 0 maps to white, not grey. The pixel indices are relative to the tile's own sorted palette, not the shared palette.
**Fix**: At build time, for each EXT: tile, compute a remap table from tile-local indices to palette-slot indices. Re-encode the 2bpp data using the remapped indices.
**Rule**: When merging a tile into a palette with more colors than the tile uses, the 2bpp data must be re-encoded. Index alignment is NOT automatic.

### Claude's upload system silently converts PNG to JPEG
**Symptom**: Analysis showed 41,003 unique colors in a "PNG" that should have had 41 (Mode P indexed palette).
**Root cause**: The upload system converts PNG→JPEG while keeping the .png extension. `file` command reveals "JPEG image data, JFIF standard 1.01." JPEG compression introduces thousands of artifact colors, destroying pixel-perfect tile data.
**Fix**: Upload PNGs inside a .zip file. The zip bypasses the JPEG conversion.
**Rule**: Never trust uploaded PNG files. Always verify with `file` command. Use zip for pixel-perfect data.

### NORDEN map extraction parameters
**Verified values**: Grid offset (3,3), bottom separator at y=579 (3-pixel green band), background color (0,128,0), content area 320×576 pixels = 20×36 meta-tiles → 106 unique meta-tiles (448 tiles in flat order). Image is RGB with exactly 36 unique colors. User confirmed (3,3) offset visually.
**Rule**: Any re-extraction must use these exact parameters. Different offsets produce misaligned tiles with green background bleed.

### Palette regex must write exactly 8 db lines
**Symptom**: Dialog boxes rendered as solid black in custom room. All other rooms fine.
**Root cause**: The Python regex replacing palette data in bank_017.asm silently dropped the 8th line (palette 7). The game read garbage bytes past the 7th palette entry, corrupting palette slot 7's colors.
**Fix**: Always count db lines after replacement. Assert exactly 8 lines between `CustomPaletteColors_6B:` and the next code.
**Rule**: After every palette update in bank_017.asm, verify: `grep -c 'db \$' | == 8`. Missing palette lines cause garbage colors AND break dialog rendering.
