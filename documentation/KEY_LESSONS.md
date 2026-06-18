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

---

## Session 7 Lessons — Palette Index 1 Forced Color & Animated Tile Indices

### BG palette color index 1 is FORCED by the game engine at runtime
**Symptom**: All NORDEN tiles appeared "way too white" in-game despite correct palette data in the ROM. Floor, walls, bannisters, drapes all washed out. Palette bytes in ROM verified correct. Editor/PNG showed correct colors.
**Root cause**: The game engine overwrites BG palette color index 1 in ALL 8 palette slots to a shared value (`$6BFF` = (248,248,208) light yellow-white) every frame. This is a palette refresh/animation system tied to the "source" tileset (MapIDClampForPalette returns $16=MedalMan for room $6B). The NORDEN extraction tool encoded tiles with index 0=lightest (white), index 1=second-lightest (grey-blue). At runtime, the game replaced index 1 (grey-blue) with the forced light-yellow, making everything appear washed out/white. ROM tilesets are already encoded to work with this constraint — their 2bpp data accounts for the forced color at index 1.
**Discovery method**: `>palette` command in SameBoy while inside the room. Showed `6BFF` at position 1 in all 8 BG palettes. This took 5 minutes; reasoning from hex dumps took hours and found nothing.
**Fix**: In `build_combined_tileset.py`, for EXT tilesets, swap palette colors 0↔1 so the lightest color (expendable, similar to the forced value) goes to index 1, and the second color goes to index 0 (preserved). Re-encode all EXT tile 2bpp data to match the swapped palette. ROM tileset palettes are used as-is (they already have the correct convention).
**Verification**: `>palette` in SameBoy after fix showed custom colors at indices 0, 2, 3 (preserved) and the forced `6BFF` at index 1 (acceptable — close to white). Tiles displayed with correct grey-blue stone, olive shadows, proper bannister colors.
**Rule**: BG palette color index 1 is NOT freely assignable in this game. It is forced to a shared value at runtime. All custom palette data must place expendable/lightest colors at index 1 and critical colors at indices 0, 2, 3. Always verify runtime palette state with SameBoy `>palette` — static ROM analysis cannot detect runtime overwrites.

### Castle VRAM handler animates tile indices 77-78
**Symptom**: Blue gravestone tiles in custom room were cycling/animated despite being static tiles.
**Root cause**: `MapIDClampForDispatch` returns $00 (Castle) for custom rooms. Castle's per-room VRAM handler at bank $01 `label1_61f9` does `ld hl, $94D0; call CheckVisualEffectType` which rotates pixel data at VRAM address $94D0-$94FF = tile indices 77-78 (($94D0-$9000)/16 = 77). The build tool's wall/walkable sort placed the gravestone tiles at indices 76-79, with tiles 77-78 landing exactly in the animated range.
**Fix**: `build_combined_tileset.py` now reserves indices 77-78 as "animated no-go zones." After sorting, tiles are remapped to skip those indices (blank tiles inserted at 77-78, subsequent tiles shifted to 79+). The `ANIMATED_INDICES` set is checked during GFX building, layout remapping, and palette assignment.
**Rule**: Custom rooms using Castle as their dispatch source (mapID $00) must not place tiles at indices 77-78. The build tool handles this automatically. If MapIDClampForDispatch is changed to a different source room, the animated indices may be different — check that room's VRAM handler in bank $01.

### K-means palette grouping replaced with exact-color matching
**Symptom**: NORDEN tiles had wrong colors — bookshelf black, crate black, grey tiles showing wrong tones.
**Root cause**: The original `extract_png_tileset.py` used k-means clustering to group 448 tiles into 8 palette groups by color similarity. K-means assigned tiles to groups whose averaged palette didn't contain their actual colors. A grey-toned tile could end up in an orange-dominated group, getting orange palette colors instead of grey.
**Fix**: Replaced k-means with exact-color grouping in NORDEN_palettes.json: group tiles by identical 4-color sets (26 unique sets), then merge subsets (tile with 3 colors fits in a 4-color group containing those 3). Result: 10 exact palette groups. Each group's palette IS the exact tile colors, not averages. Per-tile `color_remap` stored for tiles that need 2bpp re-encoding when merged into a superset group. TILE_PAL in editor updated to match new group numbers. localStorage key bumped to v4 to force cache clear.
**Rule**: Never use k-means or any approximate clustering for GBC palette assignment. Use exact-color matching: group tiles by identical color sets, merge strict subsets. The GBC has 4 colors per palette — there is no room for approximation.

### ROM palette data is never raw RGB15 — game engine always transforms it
**Symptom**: Editor shows wrong colors for Starry Shrine and other rooms (uniform color instead of colorful).
**Root cause**: The ROM's step entry `pal_ptr` points to palette data that the game engine transforms at runtime before writing to hardware palette registers. **No step-0 palette pointers have bit 15 set** (verified: zero out of 107 entries). The earlier claim about "bit 15 set = encoded" was wrong. The actual issue: the ROM palette bytes at `pal_ptr` are *always* in an engine-internal format, not raw RGB15, for *all* 80+ rooms — they simply do not match the runtime palette values. Additionally, BG palette slots 4-7 are dynamically set by the engine (monster display + menu text) and differ from the ROM data in all rooms.
**Fix (Session 9)**: `regenerate_tileset_pngs.py` renders all 86 editor tileset PNGs using `room_palettes.json` (runtime-dumped palette data from SameBoy). Force-preview toggle ("Frc" button) marks colour index 1 pixels with a distinctive tint. All rooms now show correct colours in the editor.
**Rule**: Never read palette colours from ROM step entry data. Always use `room_palettes.json` (runtime ground truth). The ROM palette bytes are engine-internal and cannot be decoded without running the game.

### Verify against runtime state, not static analysis
This session's two biggest bugs (forced index 1 and animated tiles) were both invisible in static ROM analysis. The palette bytes in the ROM were correct. The 2bpp encoding was correct. The tile indices were valid. Only runtime observation (SameBoy `>palette` command, visual inspection of animation) revealed the actual problems. **30 seconds of runtime observation beats hours of hex-dump theorizing.**

## Session 8 Lessons — Palette Budget, Gate Detection, SRAM

### BG palette slots 4-7 are SYSTEM-RESERVED — hard 4-slot limit for tiles
**Symptom**: Monster sprites displayed wrong colors when opening the party menu in the custom room.
**Root cause**: CustomPalCheck loaded all 8 BG palette slots (B=$08) with custom tileset colors. BG palette slots 4-7 are used by the game engine for monster display (slot 4=monster 1, 5=monster 2, 6=monster 3) and menu text (slot 7). Overwriting them with tileset colors made monsters display with tileset palette instead of standard monster colors. The menu does NOT trigger any palette reload — it uses whatever BG palette the room has.
**Verification**: SameBoy VRAM viewer on monster stats screen confirmed tile attributes: monster tiles use palette 4/5/6, text uses palette 7. `>palette` during menu confirmed custom tileset colors persisting in slots 4-7. All 85 original DWM1 tilesets use max palette group 3 — verified programmatically. Zero exceptions.
**Fix**: CustomPalCheck changed from B=$08 to B=$04 — only loads custom palette into slots 0-3. Slots 4-7 are left for the game engine's standard system palette.
**Rule**: Custom rooms may use **at most 4 unique palette groups** for tile graphics. This is a hard engine constraint, not an artificial limit. All original DWM1 rooms observe it. The NORDEN (DWM2) tileset has 10 groups — only 4 can be active at once; the user picks which 4 per room. The PalGrp toggle in the editor shows which tiles share palette groups.

### Bank $07 gate-detection blocks saving in custom rooms
**Symptom**: JOURNAL (save) option unavailable in Room $6B despite wInGateworld=0.
**Root cause**: Bank $07 at $6061 has a mapID whitelist for "normal" rooms: mapID<$30 is normal, $5A/$5B/$5C/$50/$51 are exceptions, everything else is treated as gate-like (blocks save, changes transition). MapID $6B falls through all exceptions → gate behavior.
**Fix**: Same-size 3-byte replacement: `ld a, [wMapID]` → `call MapIDClampForPalette` at bank $07 $6061. Returns $16 (MedalMan) for custom rooms, which is <$30 → normal behavior.

### Bank $06 $C905 state machine treats custom rooms as gate-like
**Symptom**: Custom room exhibited gate-like menu behavior.
**Root cause**: Bank $06 at $6B93 (`Jump_006_6b87`) has a similar mapID≥$50 check that sets $C905=$10 (gate-like state). MapID $6B triggers this.
**Fix**: Same-size 3-byte replacement: `ld a, [wMapID]` → `call MapIDClampForPalette` at bank $06 $6B93.

### Spawn point NPC entry can be "talked to" — ghost NPC
**Symptom**: Player could press A facing down from spawn position (7,6) and trigger NPC dialogue from the spawn entry.
**Root cause**: Spawn entry `db $8F, $FF, $07, $06, $01` has script_id=$01. The interaction code iterates all NPC entries including spawn points. If the player's facing direction intersects the spawn position, it triggers the spawn entry's script.
**Fix**: Changed spawn script_id from $01 to $00. Script 0 is the room entry script (no-op `dw $FFFF` for Room $6B).

### SRAM save audit confirmed — custom flags persist
**Verified**: Event flag $0158 (RAM byte $D9C6, bit 0) set via NPC script opcode $03, persists through save and reload. Flag is within SRAM save range ($C8EA–$D9E9) and unused by the original game. Tested with a purpose-built ROM: set flag → save → close → reload → flag still set.

### Session 10: Multi-screen room scrolling

### $26DD table bytes 2-5 are room dimensions (not spawn data)
**Discovery**: The $26DD tileset table has room width (bytes 2-3, LE) and height (bytes 4-5, LE) in pixels. Width = columns × 160, height = rows × 128. The movement system clamps player position to these bounds.
**Impact**: Custom Room $6B at $2A35 had height=$0080 (128 = 1 row). Changing to $0100 (256 = 2 rows) enabled vertical scrolling. Without this, the player is physically blocked at the screen edge.
**Rule**: When adding screens to a custom room, ALWAYS update the room dimensions in the $26DD table to match.

### Screen index formula was documented backwards
**Bug**: ROOM_DATA_FORMAT.md had X/$80 → column, Y/$A0 → row. Actual code: Y($FF95)/$80 → row (×4), X($FF92)/$A0 → column (×1). Grid is [0][1][2][3] / [4][5][6][7] — horizontal indices first, vertical rows in multiples of 4.
**Impact**: First attempt used indices 0+1 (horizontal neighbor), needed 0+4 (vertical neighbor below).

### Entry 6 vs Entry 9 exit handling
**Discovery**: Entry 6 (ExitChecker) handles exits at Y=1-6 only (interior positions, walk-onto trigger). Entry 9 (SpecialRooms) handles exits at Y=0 and Y=7 only (boundary positions, requires walking into screen edge). Entry 9 has INVERTED logic from Entry 6 — it skips Y=1-6 and processes Y=0/Y=7.
**Impact**: Boundary exits (Y=0, Y=7) can't coexist with scroll transitions on the same edge. For vertical scrolling between screens 0 and 4, screen 0 must NOT have Y=7 exits (the scroll takes priority).

### Per-screen palette/attr data is engine-supported
**Discovery**: Bank $17 entries 0 (palette) and 1 (attr) both index by wScreenIndex then step counter. Each screen can have its own palette colors and attr map. 11 original rooms use different palettes across screens.
**Impact**: CustomAttrCheck extended to dispatch per-screen attr entries from bank $64 (screen 0 → entry 1, screen 4 → entry 3).

### Never run `make clean`
**Reminder**: Violated the documented rule (PROJECT_STATE, SESSION_PROTOCOL, README all say never). `make clean` deletes committed .2bpp source files; regenerating from PNG produces different bytes. Only delete build artifacts: `rm -f game.o game.gbc game.sym game.map`.

### Stale palette data from `--build` restore behavior
**Discovery**: `build_combined_tileset.py --build` patches bank_017.asm palette data in-memory, builds the ROM, then RESTORES the original file. If the palette slot order changes between runs, the committed bank_017.asm has stale data. Always commit after running `--build`.

## Session 11 Lessons — Random Encounters in Custom Rooms (Strategy A)

Full mechanism in DATA_STRUCTURES.md ("Encounter Runtime Flow"); recipe + editor
spec in CROSSBANK_ROOMS.md ("Random Encounters in Custom Rooms").

### The per-step encounter whitelist is the town/encounter discriminator
**Discovery**: Random encounters are gated at `$0B:Jump_00b_4674` by a hardcoded
mapID whitelist (`$53`, `$54-$56`, `$57-$59`, `$61-$64`). Non-whitelisted normal
rooms hit `ret` before the encounter step ever runs — that is *why* towns/castle
have no encounters, not `wInGateworld`. Gate rooms reach the step via
`Jump_00b_46a7` when `wInGateworld != 0`.
**Rule**: To enable encounters in a custom (non-gate) room, add its mapID to the
`Jump_00b_4674` whitelist. That single change is sufficient to make battles fire.

### Non-gate custom rooms inherit a STALE encounter pool
**Symptom**: Encounters fired in custom Room $6B but spawned mid-game monsters
(Boneslave) instead of the intended starters.
**Root cause**: The battle pool is `GateBasePoolIndex[wGateID] + floor_subindex`,
resolved at battle time from `wGateID`/`wCurrentFloor`. A non-gate room never
sets these, so they hold whatever the last *real* gate left behind (observed:
gate 7 / floor 8 → pool 18). Runtime `examine $C935/$C939/$CA38` showed `07/08/12`
instead of the expected `00/01/00`.
**Fix**: Pin `wGateID`/`wCurrentFloor` to the desired gate/floor. Writing them
every step in the whitelist hook (`xor a; ld [wGateID],a; inc a;
ld [wCurrentFloor],a`) is safe — they are read only when a battle fires.
**Rule**: A custom room's encounter table is undefined until you pin
`wGateID`+`wCurrentFloor`. Never assume the seed "should" be 0/1; verify with
`examine` at a battle break.

### Room-entry script (index 0) is unreliable for battle-time state
**Symptom**: A `write_ram` seed of `wGateID=0` placed in the room-entry script
appeared correct (the write fired) yet `$C935` still read the stale value at
battle time. A SameBoy watchpoint on `$C935` only fired on *scroll to the next
screen* (through `$06:$66e3`), never at initial entry.
**Root cause**: Script index 0 runs on screen scroll and post-battle reload, but
not dependably at initial room entry — so state it writes is not guaranteed
present when a battle fires on the first screen.
**Fix**: Seed per-step/battle-critical state (gate/floor) in ASM at the
per-step hook; use the room-entry script only for one-shot arming that tolerates
running on reload (the encounter step counter).
**Rule**: Don't rely on the room-entry script for values that must be correct at
an arbitrary later step. `write_ram` (opcode $12) *does* work in custom rooms
(params route via `DispatchBank0F_Ext → CustomScriptRead`), but its firing
*timing* is the trap, not the write itself.

### Vanilla counter seeding skips non-gate rooms
**Discovery**: `SetRandomEncounterCounter` ($16:$6E14) is only reached via
`label16_5b4e`, which `ret z`s when `wInGateworld = 0`. So a non-gate custom
room's `wEncounterCounter` is never armed by the engine.
**Fix**: Seed `wEncounterCounter` ($CA39/$CA3A) from the custom room's entry
script; it re-arms on each post-battle room reload, giving repeatable encounters.
**Rule**: Encounters in a non-gate custom room need an explicit counter seed;
without it, timing is whatever stale value carried in.

### Win/flee return cleanly with wInGateworld=0 (Strategy A validated)
**Discovery**: A wild battle triggered in a non-gate custom room returns to the
room intact on win and flee — saving/menus keep working because the room is not
in gate mode. (Loss follows the normal DWM "back to King" flow, expected.) This
confirmed Strategy A (encounters decoupled from full gate mode) over Strategy B
(true `wInGateworld=1` gate, which suppresses saving).

## Session 12 Lessons — Custom Breeding (special-recipe edit + table format)

Full reference in BREEDING_SYSTEM.md; overhaul/extension spec there +
ROADMAP Phase 2B.

### Add a recipe without inserting bytes: overwrite a provably-dead entry
**Symptom**: Wanted Anteater × BattleRex → GoldSlime, but bank $16 has embedded
pointers (gate floor tables at $70A6+) — inserting a table entry shifts them
and corrupts the bank.
**Root cause**: The special recipe table ($16:$4B30, 825×5, $FF-terminated) is
contiguous data with real code immediately after the terminator ($5B4D). Growing
it in place is impossible without a shift.
**Fix**: Same-size overwrite of an entry that is already unreachable. Two kinds
of dead entry exist in vanilla: an exact duplicate (entry 803 == 802, both
Zombie-fam×Swordgon→Skullgon) and a shadowed entry (693 has identical matchers
to 682 but a later index, so 682 always wins first). Overwriting either changes
nothing in vanilla. A focused build (only bank_016 over the clean tree) diffed
the original ROM at EXACTLY the intended bytes (+ the 2 header-checksum bytes).
**Rule**: To add a recipe at fixed table size, target a duplicate/shadowed entry
(`patch_breeding_recipe.py --list-dead`) and verify with a focused build diff
(expect only your bytes + $014E/$014F). Never insert into bank $16.

### The family ("defaults") table encodes the result as the SLOT INDEX
**Symptom**: Plausible to assume the family table stores a result species per
entry (like the special table). It does not.
**Root cause**: `LoadBrd_45ff` walks 2-byte `[B,C]` pairs incrementing D on every
read (separators included), and on a match does `ld a,d; ld [$da71],a` — the
offspring species IS D, the positional index. `$FFFF` separators are slots that
can't match but still advance D, used to align a matcher to its result species.
**Fix/understanding**: To make `famA×famB → species S`, place `[codeA,codeB]` at
slot S. Each species has ≤1 family default (one slot = one pair); many→one must
go in the special table. Verified: slot 0 Slime×Dragon→DrakSlime, slot 19
MetalKing²→GoldSlime.
**Rule**: When rewriting defaults, author "result ← parents" and place at the
result's slot; a compiler must reject two pairs claiming the same result species
(positional conflict) and preserve the `$FA` "any family" wildcard.

### Extending past bank space: relocate + rst $10, leave the original dead
**Symptom**: Want 1×–2× more special recipes; bank $16 has no room.
**Root cause**: Breeding executes in ROMX bank $16; you can't page another bank
into ROMX mid-execution.
**Fix (design, not yet built)**: Put the extended table + a ported scanner in a
free bank ($69) and call it via `rst $10` (handler in ROM0 saves/switches/
restores ROMX — same far-call the custom rooms use). Redirect bank $16's scan
entry with a same-size `ld hl,$6900; rst $10` (+NOP pad); leave the vanilla
table in place (dead) so nothing in bank $16 shifts.
**Rule**: Cross-bank data that a ROMX routine must read goes behind a free-bank
scanner invoked via rst $10; never relocate by removing in-bank data (it shifts
embedded pointers).

## Session 14 Lessons — Bank $0B repointing (breeding-cutscene fix)

Rule also captured in SESSION_PROTOCOL §4 ("What a session must never do").

### Labelize in the byte-identical disassembly FIRST, then port to the patch
**Symptom**: Custom ROM's breeding cutscene showed the wrong parent monsters with the
correct palette ("wrong data, right palette" = a pointer reading the wrong address).
**Root cause (two layers)**: (1) three raw pointer refs into bank $0B's shift region were
never labelized (`add $74/adc $49`→`$4974` sprite table; `ld hl,$42c8`/`$4308` gate table
with raw `dw` entries), so the custom dispatch's shift left them stale — the same drift
class as the bank $04 incident. (2) Worse, the patch had *attempted* to labelize the sprite
ref but pointed it at a label (`RoomScreenPtrTable`, `$49b5`) 164 bytes off from the real
`$4974` data (`$4911`), which sat orphaned. A wrong label *looks* fixed and passes review.
**Fix**: re-section both tables into labeled `dw`/`db` in the disassembly (build stays
byte-identical to `1ca657…`), then port to `patches/bank_00b.asm` and repoint the mislabeled
sprite consumer to the correct table.
**Rule**: Always labelize a raw pointer in the disassembly first and confirm `MD5==1ca657`
(a mislabel changes bytes → fails instantly). Only then port to the patch. Patches have no
vanilla-MD5 guard, so never hand-author a pointer label directly in a patch without verifying
where it resolves — check the bytes at the label's address, not just that a label exists.

### No trampolines — finish the labelization instead
**Reminder**: A full disassembly makes WRAM/ROM0 trampolines unnecessary (KEY_LESSONS #1).
When a shift breaks a reference, the fix is to labelize the reference, not to add an
indirection layer or avoid the shift. Shifting code is fine once every reference into the
shifted region is a label.

## Session 15 Lessons — Breeding B3 (special-table capacity extension)

Full reference in BREEDING_SYSTEM.md "Planned"; phased plan + acceptance tests in
ROADMAP Phase 2B.

### An appended special recipe only fires if it is UNSHADOWED — verify against the table
**Symptom**: Chose `MadCat × BattleRex → DracoLord` as the >824 capacity-proof recipe.
Had it been appended in that order, the in-game test would have produced **Yeti**, not
DracoLord, and looked like B3 had failed.
**Root cause**: The special table is first-match-wins, checked before the family table.
`MadCat × BattleRex` is already vanilla **special entry 187 → Yeti ($3B)**, at a far lower
index, so it wins before the appended entry at index 825 is ever reached. The appended
recipe was *shadowed* (dead).
**Fix**: Append the **reverse** order `BattleRex(Pedigree) × MadCat(Mate) → DracoLord`,
which no base entry matches (checked: byte0 ∈ {p1 species, p1 family} AND byte1 ∈ {p2
species, p2 family} for all 825 entries → no hit). DracoLord can then only come from the
>824 entry, so the in-game result is an unambiguous pass. `build_breeding.py` now runs this
shadow check at emit time and FAILS the build on a dead appended recipe.
**Rule**: Before adding a special recipe, confirm no earlier entry matches the same parents
(species OR family code, ignoring plus). For a capacity/override proof, the cross MUST be
unshadowed or the test is meaningless. Remember matchers can be family codes ($F0–$FA), so
a `[$F2,$F1]` (Beast×Dragon) entry shadows every Beast×Dragon species cross. Parent ORDER
matters (p1=Pedigree `$DA6F`, p2=Mate `$DA70`); a cross can be free in one order and taken
in the other.

### Grow the relocated table by appending before the $FF — the scanner has no count
**Discovery**: The bank `$69` scanner (B2) is a pure scan-to-`$FF` loop (`cp $ff; jr z,.done`;
`add $05` per entry). It has no hardcoded entry count, so the table grows simply by writing
more 5-byte entries before the terminator. Vanilla bank `$16` tables stay dead-in-place
(zero shift). B3's whole ROM impact was **4 bytes** in bank `$69` (old `$FF` + padding →
one appended entry + new `$FF`) plus the header checksum.
**Rule**: When relocating a `$FF`/`$0000`-terminated table to a free bank, port the scan as
terminator-driven (not count-driven) so later capacity growth is data-only. Keep the base
slice byte-identical to its source (assert it) so appends can never silently corrupt the
inherited recipes.

## Session 16 Lessons — Breeding B4 (family-defaults rewrite)

Full reference in BREEDING_SYSTEM.md "Planned"; acceptance test in ROADMAP Phase 2B.
Tool: `tools/build_breeding.py --emit-family`; spec: `extracted/breeding_family_defaults.json`.

### The family table is positional, so a "recipe change" is a slot edit, not a free mapping
**Discovery**: Offspring species == slot index in the family table ($16:$4974). You cannot
"set Slime×Dragon → species X" directly; you write the matcher pair `[$F0,$F1]` into the
SLOT whose index == X. One slot = one result species (strict 1:1). Many→one must go in the
SPECIAL table. The table is exactly 222 pairs / 444 bytes and bank $16 has embedded pointers
downstream, so the rewrite is IN PLACE only (zero shift): edit matcher bytes at existing
recipe slots, convert a separator (`$FFFF`) slot to a recipe to ADD a default, or vice-versa
— never grow/shrink the pair count.
**Rule**: Author family defaults as `result_species → (p1,p2)` and place at the result's slot.
The compiler rejects two overrides claiming the same result (positional conflict) and asserts
the emitted table is still 444 bytes. A zero-collateral change = permute existing matchers
among their own slots (result set unchanged, just reached by different parents) + add new
recipes only at empty separator slots. B4 did exactly this: 5 changed bytes total.

### SPECIAL > FAMILY: a species-specific special silently masks a family default
**Symptom**: After setting Beast×Dragon → Wyvern (family slot 71), `MadCat × BattleRex`
still produced **Yeti**, not Wyvern — looked like the change failed.
**Root cause**: The resolver is special → family → fallback(parent1). `MadCat(68) × BattleRex(42)`
is vanilla SPECIAL entry **187** (`[68,42,0,59,0] → Yeti`), a SPECIES-SPECIFIC match that fires
before the family table is ever consulted. The family default was correct and present; it was
simply out-ranked for that exact pair. Crosses that hit no special (FunkyBird×BattleRex →
DrakSlime; Snaily×BattleRex → Almiraj; Dragon×Dragon → GreatDrak) showed the new family
defaults immediately.
**Rule**: Before claiming a family default works for a given pair, check the SPECIAL table for
BOTH a family-code match (`[p1fam,p2fam]`) AND a species-specific match (`[p1,p2]`) in the
player's parent ORDER (p1=Pedigree $DA6F, p2=Mate $DA70). `--emit-family` warns on family-code
shadows; species-specific shadows depend on the exact monsters and are surfaced at play-test —
so when picking a proof cross, choose parents with no special at all (Slime pedigree + any
Dragon mate is fully clear) or expect the special's result.

### Family-table internal precedence: exact-species returns immediately; family-code last-wins; two passes
**Discovery (grepped `LoadBrd_45ff`/`45d5`, do not re-trust)**: within the family scan, an EXACT
parent-1 species match (`cp b` on $DA6F) returns immediately, but a parent-1 FAMILY-code match
stores the result and KEEPS scanning (so the LAST family-code match wins). The search also runs
TWICE: pass 1 with parent 2 as its specific species, pass 2 with parent 2 converted to its
family code. So a family-code default `[Fx,$F1]` only surfaces in pass 2, and only if no exact
or higher-slot family match out-ranks it.
**Rule**: For a clean family-code default, ensure no duplicate `[b,c]` family pair exists at a
higher slot and no exact-species family entry catches the same parents first. `--emit-family`'s
shadow check flags duplicate family-code matchers; the positional 1:1 rule prevents result
collisions by construction.

### The `$FA` "AnyFamily" wildcard is supported by the scanner but used ZERO times in vanilla
**Discovery**: `LoadBrd_45ff` special-cases `cp $fa` (matches any family-coded parent 2), but
no vanilla family entry uses `$FA`. So "preserve the `$FA` wildcard" means preserve the SCANNER
capability — there is no data depending on it. `--emit-family` can still emit `$FA` (mate side
only; it rejects `$FA` on the pedigree side, matching the scanner).
**Rule**: Don't assume documented "wildcard" data exists; grep the table. The compiler keeps the
capability available for authored recipes without inventing data that was never there.
