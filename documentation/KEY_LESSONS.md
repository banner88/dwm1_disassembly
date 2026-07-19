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

### Never run `make clean` (CANONICAL entry; violated TWICE — now structurally fixed)
**Reminder**: Violated the documented rule (PROJECT_STATE, SESSION_PROTOCOL, README all say never). `make clean` deletes committed .2bpp source files; regenerating from PNG produces different bytes. Only delete build artifacts: `rm -f game.o game.gbc game.sym game.map`.
**Violated AGAIN in S51** (a session-authored tool called `make clean` without
checking the rules — the second recorded violation by a different instance, and
the violator then wrongly told the user no such rule existed; grep the docs
before making claims about the docs). Two violations proved the prose rule
doesn't reliably prevent the accident, so S51 removed the hazard itself:
the Makefile `clean` target no longer touches gfx, the `%.2bpp: %.png` pattern
rules are deleted (measured: **17 of 18 committed .2bpp are not PNG-regenerable**,
regen builds MD5 `91609a37…`), and `disassembly/gfx/README.md` sits at the
hazard point. The rule stands; it just can't be violated by `make clean` anymore.

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

## Session 17 Lessons — Breeding B5 (full special-table authoring)

Full reference in BREEDING_SYSTEM.md "Planned"; acceptance test in ROADMAP Phase 2B.
Tool: `tools/build_breeding.py --emit-special`; spec: `extracted/breeding_special.json`.

### Author from the ROM, not from the patched mirror — one source of truth
**Symptom**: B3's relocation sourced the bank `$69` table from the **patched** `bank_016.asm`
(so custom recipes survived a re-emit). That works, but it means a recipe lives in two places
(the dead bank `$16` db block AND bank `$69`), and editing a base entry would require touching a
shift-sensitive bank for zero runtime benefit (bank `$16`'s special table is already dead — B2
redirects the scan via `rst $10`).
**Root cause**: Dual bookkeeping is exactly the loophole that caused the historical byte-perfect
drift. The patched mirror was a crutch for "preserve existing edits across a re-emit," but once a
JSON spec owns the edits, the mirror is redundant.
**Fix**: B5 decodes the 825 base entries from the **vanilla ROM** and applies authored
`overrides`/`appends` from `breeding_special.json`. Bank `$16`'s special table stays
byte-identical to the ROM forever; the ONLY authored source is the JSON, the ONLY emit target is
bank `$69`. Existing custom recipes (e.g. the S12 GoldSlime cross) are re-expressed as overrides
at their dead entries (693/803), so behavior is preserved without inheriting from the mirror.
**Rule**: When a table is relocated to a free bank and the original is left dead, AUTHOR from the
canonical ROM decode + an explicit override list, not from the patched copy. The dead in-bank
table must equal vanilla (assert it: "untouched base entries == vanilla"); a single authored
source can't silently diverge from two places.

### A first-match-wins table needs a WHOLE-table validator, not an append-only one
**Symptom**: B3 only checked whether an *appended* recipe was shadowed. With B5 able to edit any
base entry, two more failure modes appear: an *override* can be shadowed by an earlier entry (its
edit never surfaces), and an edit can newly *shadow a later* entry for the same parents (silent
collateral).
**Root cause**: Precedence in a first-match-wins table is global. Any edit's effect depends on
every earlier entry (does something win first?) and every later entry (do I now win before it?).
Checking only the tail misses both.
**Fix**: `special_shadow_report` runs the precedence analysis across the full authored table.
ERRORS (build-failing): a shadowed append or a shadowed override. WARNINGS: an edit that now
precedes a later different-result entry, and — when an override CHANGES a result species — a list
of the OTHER surviving entries that still produce the old result.
**Rule**: For first-match-wins data, the validator must consider the whole table both before AND
after each edit. "Edit fired in my one test" is not proof it's globally correct; "no earlier entry
shadows it AND it doesn't shadow a different later result" is.

### Editing one cross's result ≠ removing that monster from breeding
**Symptom**: Plausible to think "change entry 187 MadCat×BattleRex from Yeti to DracoLord" removes
Yeti from the game. It does not — **23 other entries still produce Yeti** as offspring of other
crosses (Yeti is a frequent result, and is also a parent *matcher* in entries 166–188, which is a
different thing again).
**Root cause**: The special table is many→one: a result species typically appears as the result
byte of many entries. Editing one entry's result byte only changes that one cross.
**Fix**: The validator emits a "residual result" note whenever an override changes a result
species, listing the other entries that still yield the old result. This keeps the editor honest:
"recolor this recipe" is not "delete this monster."
**Rule**: Before claiming an edit removes a species/outcome, grep the result column for every other
producer. To truly remove an outcome you must edit (or shadow) ALL of its producers, not one.

### Duplicate species NAMES require id-based disambiguation
**Symptom**: `"result": "DracoLord"` resolved to species **201**, not the intended **200** — two
distinct species share the name "DracoLord" (id 200 = level_cap 50 base form, id 201 = level_cap
80 second form), and the name→id map let the later id win.
**Root cause**: `monsters_full.json` has non-unique names; a name→id reverse map is lossy for
collisions (last write wins).
**Fix**: The B5 proof spec uses the numeric id `200` explicitly. The resolver still accepts names
for convenience, but ambiguous ones must be given by id.
**Rule**: When authoring against a name table that has duplicate names, prefer numeric ids for the
colliding entries; the future editor should disambiguate by id (and show level_cap/form) rather
than trust the name string.

## Session 18 Lessons — Breeding B6 (family reassignment + dynamic library)

Full reference in BREEDING_SYSTEM.md "B6 — family reassignment" + "Dynamic library".
Tools: `tools/build_family_reassign.py`, `tools/build_dynamic_library.py`.

### One value, three readers: a family edit looks half-applied until you trace all consumers
**Symptom**: Changed a monster's family byte ($03:$4461+$00). Breeding behaved as
the new family (bred new offspring), but the status menu and the library showed the
OLD family — and the library and menu disagreed with each other.
**Root cause**: The family byte reaches three systems by three different paths.
(1) Breeding reads it LIVE every cross. (2) Status/menus read the per-monster party/
storage struct byte at +$0A ($CACB), which is STAMPED from the live byte only at
CREATION (breed: bank $16; recruit/catch: bank $14) — so pre-existing monsters keep
the old stamp (snapshot semantics). (3) The library groups by species-id RANGE, not
the family byte at all.
**Fix**: Verify each path separately. Snapshot semantics are correct for a fresh hack
(obtain the monster after patching → correct). The library needed a code change.
**Rule**: When one byte feeds multiple subsystems, a partial-looking result means
DIFFERENT READ PATHS, not a failed write. Grep every reader and classify it
(live / snapshot-at-creation / independent representation) before concluding.

### The library groups by id-range, the single id-range family assumption in the ROM
**Discovery (grepped S18, do not re-trust)**: `SetItem_6242` ($12:$6242) populates a
family tab by scanning a CONTIGUOUS species-id range from `LibraryFamilyTabBounds`
($12:$6294 = [0,20,45,70,90,110,130,155,175,200,215]). It works in vanilla only
because families are id-contiguous. Audit confirmed this is the ONLY place a family
is derived from an id range (checked every `cp` against the boundary ids; all other
family uses read the family byte or take a species id directly).
**Rule**: Before a "dynamic family" feature, confirm the id-range assumption is
isolated — one routine + one table here. Reassignment is then safe everywhere except
that routine, which must be made to scan by family byte.

### The library tab index is a flat 2-col×5-row cell, not the column var alone
**Symptom**: First dynamic-library attempt put whole families under the wrong tab and
made other families vanish from the library entirely.
**Root cause**: The tab strip is a 2-column×5-row grid. The FAMILY index is
`wOPTN_and_Item_selection*5 + (wMenu_selection & $7F)` (the value the original stores
into $cac0). `wOPTN_and_Item_selection` ALONE is just the column (0..1) — using it as
the family meant only families 0 and 1 were ever scanned; 2..9 never matched.
**Fix**: Compute the flat index exactly as the original did. Confirmed by simulation
against the patched ROM (each reassigned monster maps to the right tab) before
re-testing in SameBoy.
**Rule**: When replacing a menu routine, reproduce the EXACT selection-index math the
original used (the `*5 + row` flat-cell encoding here), don't assume a selection var
maps 1:1 to the logical item. Simulate the index→result map before building a ROM.

### Reassignment doesn't gate eligibility — that's the joinability byte + boss table
**Discovery**: Every family-byte reader outside breeding is display or struct-copy
(bank $01 battle copy, $04 text dispatch, $07 sprite/icon, $09 VRAM index, $14 recruit
stamp). NONE gate scout/recruit/AI/resistance on family==9. Recruit eligibility is the
enemy-stats joinability byte ($14 +$3) + boss table ($14:$4897).
**Rule**: "Is this a boss/unbreedable?" is NOT the family byte. Moving a monster in/out
of ??? changes its family label/grouping/breeding, not its recruitability — those are
separate tables. Don't assume family==9 means "boss-locked".

### Don't optimize a runtime path that the editor should precompute
**Symptom**: The dynamic-library POC lags (~221 cross-bank family reads per render).
Tempting to add a 221-byte WRAM family cache to speed it up.
**Root cause**: The lag is intrinsic to computing static data at runtime. In a shipped
hack, family membership never changes — so it should be precomputed at BUILD time.
**Fix**: Keep the runtime POC as a proof that dynamic grouping works; plan the
production library to read a build-time-emitted family→members table (zero runtime RAM,
zero far-loads). A runtime WRAM cache was rejected: it claims standing RAM for one menu
and needs coherence.
**Rule**: Before optimizing runtime code, ask whether the data is static in the shipped
product. If yes, move the work to the build tool (the editor) — don't spend RAM or
cycles recomputing at runtime what can be a baked table.

## Session 19 Lessons — Breeding B7 (production library grouping)

### "Looks empty" is not "junk" — verify a slot's ROLE before treating it as free
**Symptom**: Auditing the library, ids 215–220 are excluded by the vanilla id-range
bounds table and read as empty (level cap 0, all skills "Blaze", no growth, id 220
blank). The natural inference: dead placeholder slots, free to repurpose for new
monsters.
**Root cause**: Empty-looking STATS only mean a monster needs no recruit/breed/growth
data — not that it is unused. 215 `TERRY?` is a scripted story enemy (Durran fight);
216–219 (`Tatsu`/`Diago`/`Samsi`/`Bazoo`) are the four tiers of a summon skill. They are
real, functional combat entities; overwriting any of them would break that fight or the
summon. The vanilla bounds table stops at 214 because the library is the COLLECTION
register (recruitable monsters), not a bestiary — so non-collectible combat entities are
correctly omitted, not "missing".
**Fix**: Treat the collectible set as authored data (`COLLECTIBLE_MAX = 214`), enumerate
215–220 explicitly as PROTECTED special entries in `build_library_table.py`, and make the
tool REFUSE any reassignment that targets them. Confirmed with the user (who knows the
game) rather than inferred from stats.
**Rule**: Before calling a data slot free/unused, confirm its in-game ROLE (grep its
usage, or ask the user). "Empty stats" can mean "special-cased elsewhere", not "garbage".
A wrong "it's a free slot" assumption corrupts live content silently.

### Replacing a POC with a build-time table — keep one source of truth
**Symptom**: Two consumers of family membership (bank_003 family bytes via B6; the new
library table via B7) could drift if each derived membership independently.
**Root cause**: Duplicated derivation = divergence risk (the status menu would show one
family, the library another).
**Fix**: `build_library_table.py` sources family assignment from the vanilla family byte
plus the SAME `breeding_family_reassign.json` spec that B6 feeds to bank_003, and
validates each `from` == vanilla (same guard as B6). One spec → two consistent artifacts.
A `--selftest` proves the no-reassign path reproduces the vanilla bounds table exactly,
so the default build is provably behavior-identical to vanilla.
**Rule**: When two emitted artifacts depend on the same fact, both must derive it from one
source file, not re-derive it independently. Add a self-check that the no-op case
reproduces vanilla byte/behavior, so "I didn't break the default" is machine-verified.

## Session 20 Lessons — Family icons (B8/B9 "name" path)

Full reference: BREEDING_SYSTEM.md "Family icons (B8/B9)". Tool:
`tools/build_family_icon.py`; data `extracted/family_icons.json`; patch
`patches/bank_04f.asm`; annotation in `disassembly/bank_04f.asm`.

### The "family name" we hunted for two sessions was never a string — it's a font tile
**Symptom**: B8/B9 were blocked on "trace the family-NAME string render path." Three
prior sessions correctly ruled out `FamilyTextPtrTable` ($04:$60F4) but left the real
path "untraced," and earlier searches for the family-name TEXT (Slime/Beast/…) only
found a flavor-text SENTENCE (bank $1A $6A46, "…Slimes… Beasts… and ???"), never a
short tab-label table.
**Root cause**: There is no family-name string. The family identity shown to the
player is a graphical ICON: 10 font tiles at $4F:$4110-$41A0, addressed by text bytes
$10-$19 (ComputeTileDataAddr in $00: addr = $4010 + byte*16). The detail screen prints
`<$F0><icon $1x>"family"` (bank $4D); the library tab strip blits the same tiles. The
charmap (dwm.tbl) literally hinted this with commented `10=[slime] … 19=[???]`.
**Fix**: Confirm the render medium with the USER before hunting (they said "it has
symbols, not text" in one line — slime, dragon face, paw, feather, …). Then verify the
byte→tile formula from ROM code, not docs. A rename/add becomes a GRAPHICS edit.
**Rule**: Before tracing a "text/name" render path, confirm it IS text. A one-line
question to the user ("is that label text or a graphic?") can redirect an entire
multi-session hunt. Charmap comments naming non-ASCII glyphs (`[slime]`) are a tell
that the "name" is a tile.

### A "blank filler" tile is genuine free space — but verify it's filler, not a used blank
**Symptom**: Needed a slot for an 11th-family icon. The tile right after the 10 icons
(byte $1A / $4F:$41B0) reads `$ff,$00` repeated — looks free.
**Root cause/check**: `$ff,$00`×8 is the font's blank-tile pattern (every pixel index
1 = menu background). The charmap independently documents "20-23 are blank," and bytes
$1A-$23 are 10 such tiles. Confirmed it's unreferenced filler, not a space/used glyph,
before claiming it. (Contrast S19: "empty-looking" monster stat slots 215-220 were NOT
free — they were special combat entities. Same discipline, opposite outcome.)
**Fix**: Same-size 16-byte tile insert at $41B0, zero shift; bank $4F stays byte-
identical to vanilla everywhere else. `build_family_icon.py --selftest` asserts the
shipped Spirit grid encodes to exactly the bytes in the patch.
**Rule**: "Looks blank" needs the same role-check as "looks empty" (S19). A blank font
tile IS reusable, but prove it's filler (charmap + no references) first.

### Tile graphics are palette-independent; "make it yellow" is a separate palette question
**Symptom**: User asked for the new icon's "head" to be yellow. A 2bpp tile can't carry
colour — it carries 4 palette INDICES; colour comes from the menu's CGB BG palette.
**Fix**: Build the shape now (done), and encode the head on palette index 0 (Variant A)
so it shows yellow IF that menu palette's index-0 is yellow; ship a Variant B (head on
index 2) as a fallback. Leave the actual palette confirmation to SameBoy (the menu
palette loads via LoadGBCPalettes → rst $10 bank $17 entry $03; palette attribution is
a historically SameBoy-verified area here — see PROJECT_STATE "Palette Index 1 Forced").
**Rule**: Separate the tile (shape, palette-independent, deliver now) from the palette
(colour, menu-bound, SameBoy-verified). Don't guess palette behaviour from the tile;
encode against the index and confirm the colour in the emulator.

## Spirit B9 Lessons — family-10 VRAM corruption + icon slot

Tools/patches: `patches/bank_000.asm` (ClampFamIdx), `patches/bank_001.asm` (lookup
routing), `patches/bank_04f.asm` (Spirit icon), `tools/build_family_icon.py`.
This work sits ON TOP of the gate-entry-freeze fix (GateAwareDispatch / CustomGFXMapID
in ROM0); the two ROM0 routines coexist (ClampFamIdx immediately follows CustomGFXMapID
in the same end-of-bank padding). Clean build stays `1ca6579…`; integrity PASS.

### A family-indexed graphics table sized to 10 runs off the end for family 10
**Symptom**: Catching a family-10 (Spirit) monster (Dracky sp.78 / DarkDrium sp.214),
adding it to the party, then returning to the map corrupted ALL of VRAM (tileset +
tilemap turned to garbage). Live SameBoy watchpoint on a garbage tilemap address
($9863) broke with BC=$2196 (an 8598-byte runaway copy), DE=$55fc (source), HL=$9864,
backtrace through the ROM0 copy ($1ac3←$159a←$1581) ← 01:$49da ← 01:$497f ← 01:$4865.
**Root cause**: `bank_01:$49C0` builds a graphics source pointer by indexing a
**10-entry, family-indexed pointer table at `01:$4BAD`** (families 0–9 → clean
`$2E03..$2E0C`; entry[10] and beyond = garbage). `ReadActiveMonsterByte` ($2284) returns
family=10 for a Spirit monster, so `$4BAD[10]` is read out of bounds → a garbage source
pointer AND a garbage copy length → the copy loop overruns the whole VRAM region.
**Fix**: 8-byte `ClampFamIdx::` in ROM0 end-of-bank padding (it replaced 8 `rst $38`
filler bytes, landing at ROM0 $3BCB): `call ReadActiveMonsterByte / cp $0a / ret c /
dec a / ret` (any family ≥ 10 clamps to 9). `patches/bank_001.asm` routes ONLY the
`$4BAD` lookup ($49C0) through `call ClampFamIdx` — a same-size `CD xx xx` replacement
(Iron-Rule-2 compliant for bank $01: zero byte shift). User-confirmed in SameBoy: no
corruption, correct follower sprites, library correct, family attribution correct.
**Rule**: Before letting an 11th family (index 10) reach the renderer, grep every
family-INDEXED array/pointer table (not just the breeding/library ones) and confirm its
length. A 10-entry GFX pointer table indexed by a now-possible family value 10 reads OOB
and a bad length turns one bad index into a whole-VRAM wipe. Clamp at the read, in ROM0,
same-size.

### Clamp the FAMILY-indexed table, not the SPECIES-indexed one next to it
**Symptom**: A first fix also clamped a SECOND lookup at `01:$499D` and broke every
follower sprite ("BigEye shows MadCat" — all followers shifted by one).
**Root cause**: `$499D` is NOT family-indexed. It uses the species byte ($caca) to index
the **215-entry per-species follower table at `01:$49DF`** ($10→$2F01 … $1A→$2F0B, all
valid). Clamping a species index corrupts a perfectly in-range lookup. ($cacb = family →
$4BAD; $caca = species → $49DF — two different bytes, two different tables.)
**Fix**: Reverted the $499D clamp; only the family-table lookup at $49C0/$4BAD is routed
through ClampFamIdx.
**Rule**: "Indexed near the same code" ≠ "indexed by the same thing." Identify the index
SOURCE byte (family vs species) and the TABLE LENGTH before clamping. Clamping the wrong
one silently corrupts valid data.

### The Spirit icon ships on byte $19, not the "free" $1A slot ($1A is not fill-immune)
**Symptom**: The S20 plan placed the Spirit family icon on the first free font slot,
byte $1A ($4F:$41B0). In practice that tile rendered blank — the menu blanks $1A at
runtime, so the icon never showed.
**Root cause**: $1A is not fill-immune; the library/detail menu clears it. Byte $19
($4F:$41A0, the vanilla ??? glyph) survives.
**Fix**: Ship the option-5 whip on byte **$19**, overwriting the vanilla ??? glyph (??? and
Spirit now share the whip — acceptable, ??? is rare). The free $1A slot is left blank.
`extracted/family_icons.json` `spirit` grid + `tools/build_family_icon.py --selftest`
were reconciled to verify the JSON grid against the $19 patch bytes, so the icon is
rederivable from tracked data with NO PNG. PROJECT_STATE/ROADMAP/BREEDING_SYSTEM that
still say "$1A" predate this and are corrected here.
**Rule**: A "free/blank" font slot is not necessarily a usable one — confirm a candidate
tile survives the menu's runtime fill before committing art to it (same family as the
S19 "looks empty ≠ free" lesson, applied to tiles instead of species ids).

## Session 22 Lessons — GFX-1 (sprite codec + re-sectioning a misassembled data table)

Full reference: MONSTER_DATA.md "Monster sprite graphics system". Tools:
`tools/resection_battle_gfx_table.py`, `tools/extract_monster_sprites.py`,
`tools/build_sprite_swap.py`; codec `dwm/sprite_codec.py`; data
`extracted/monster_sprites.json`; annotation in `disassembly/bank_000.asm`
(`MonsterBattleGfxTable` @ `$2B9F`).

**Re-sectioning a mgbdis-misassembled data table without breaking the build.**
The battle gfx-ID table at `$00:$2B9F` was decoded by mgbdis as fake instructions,
with 27 hallucinated labels on data bytes. **23 of those fake labels are referenced
from OTHER banks** (themselves misassembled data whose bytes happen to encode
`jp/jr/ld` to those addresses). Two traps bit, in order:
1. **Naive `dw` re-section dropped the labels → link errors.** Converting to `dw`
   deletes the fake labels; the cross-bank fake-instructions then fail to assemble
   ("Unknown symbol"). **Rule:** before re-sectioning, grep the WHOLE tree for every
   label in range; any that's referenced must be re-created at its exact address.
2. **Opcode-size line-mapping drifted by 2 bytes → a downstream shift.** Computing
   the replaced span's end by summing instruction sizes is fragile; a single
   mis-sized line shifted everything after the table by −2 (first visible as a real
   `jp $2EEA → $2EE8`). **Rule:** don't size instructions to find boundaries. Anchor
   the replacement between two REAL label lines whose addresses come from the linker
   `.sym`, and emit the EXACT ROM bytes for the whole inter-label range
   (`ROM[start_addr:end_addr]`), attaching preserved labels at `addr-start` offsets.
   Then byte-perfectness is structural, not arithmetic. Verify with verify_integrity.

**LZ encode is many-to-one; pick the right round-trip contract.** `decode()` is
deterministic and byte-exact, but `encode(decode(vanilla))` is NOT byte-identical to
the vanilla stream — many valid streams decode to the same payload and the game's
encoder made different greedy choices. The editor never re-emits originals, so the
correct, sufficient guarantee is SEMANTIC: `decode(encode(x)) == x` (verified on all
442 streams). **Rule:** don't chase vanilla-byte-identical re-encoding — zero editor
value, and it's a research rabbit hole. Documented in `dwm/sprite_codec.py` so a
future session doesn't "fix" it.

**Shared-pool back-refs mean cross-monster transplants must be self-contained.**
All 221 battle streams back-reference a shared VRAM pool. A swapped sprite encoded
non-literally inherits the TARGET monster's pool state, not the source's. Encode new
art with `--literal` (self-contained) for transplants. Standalone extraction decodes
pool refs as zero-fill, which happens to be correct for display because meaningful
refs are self-covered (Slime/Dracky/Anteater verified visually).

**Palette is a separate slot+colour system (GFX-2 lead).** User VRAM data: the enemy
monster uses ONE shared OBJ palette slot (slot 4 — Dracky and a blue slime both show
attr `04`); per-species colours are loaded into slot 4 at battle-init. So a tile swap
keeps the target's colours (Anteater-on-Dracky rendered mostly RED, = Dracky index-0).
Recolour = edit the per-species colour data, entry `FuncFld_6942`/`SetGBCPalette`
(bank `$07`, `ld h,$04`). **Rule:** tile swaps and recolours are independent jobs;
don't expect a sprite swap to change colours.

## Session 23 Lessons — GFX-2 (cross-bank sprite backbone + monster palette recolour)

Full reference: MONSTER_DATA.md "Monster sprite graphics system" + "Monster battle
palette system". Tools: `dwm/sprite_bank.py` (cross-bank allocator),
`tools/build_sprite_swap.py` (rewritten battle swap, cross-bank + `--palette`),
`tools/extract_monster_palettes.py`; data `extracted/monster_palettes.json`,
`extracted/monster_sprites.json` (regenerated, all 221). Disassembly annotation in
`bank_017.asm` (`MonsterBattlePalettes` @ `$62FD`, loader `label17_41d0`).

### The cross-bank allocator is the fundamental enabler for bulk DWM2 swaps
**Symptom**: the S22 swap tool only handled monsters whose battle art is in bank `$36`
(~40 of 221) and only same-bank free space — useless for swapping arbitrary or many
monsters. **Root cause**: battle sprites are spread across 6 banks (`$2F,$32–$36`),
followers across 5 (`$2E,$2F,$38–$3A`), each with tiny trailing free space.
**Fix**: a cross-bank allocator (`dwm/sprite_bank.py`) that places streams into the
reserved overflow region (`$7E–$7F`, then `$7C/$7A/$79`) with a pointer table at
`$4001`, and repoints the species→gfx-ID entry. **Verified the resolver supports
this**: `DecompressTileLayout` ($00:$1627) reads the stream pointer from
`$<bank>:$4001 + index*2` with NO bank-validity gating — so any monster can point at
any bank, including a fresh one you lay a pointer table into. **Rule**: never place
swaps in the original bank; the editor's sprite backend is overflow-bank allocation +
repoint, identical for battle (`$00:$2B9F`) and follower (`$01:$49DF`).

### Prove the plumbing with a lossless relocation before touching art
**Fix**: the cleanest regression proof of "cross-bank place + repoint" is to copy a
monster's EXISTING stream bytes unchanged into overflow and repoint — decode is
byte-identical, so it renders identically (Slime, user-confirmed). Back-refs are
ABSOLUTE into the VRAM output base, so a stream is position-independent — relocating
the bytes changes nothing. **Rule**: separate "does the plumbing work" (relocate
unchanged) from "is the new art right" (literal-encode new art); debug them apart.

### The monster battle palette: BG slot 4, table `$17:$62FD`, found via SameBoy + grep
**Symptom**: a swapped sprite rendered in the TARGET monster's colours; the
per-monster palette source would not surface in static tracing (the GFX-2 "semi-
speculative" gap). Two things hid it: (1) the monster renders as **BG tiles on BG
palette slot 4**, not OBJ — so an OBJ-buffer (`$c7f7`) watchpoint was a red herring;
the live BG buffer is `$c797`, slot 4 = `$c7b7`. (2) The ROM table was **mislabeled
`RoomAttrDataBlocks`**, so grepping for a "palette" label found nothing.
**Fix**: a SameBoy palette dump gave the exact bytes (Dracky BG4 = `007b 6bff 2a97
0000`); grepping the ROM for those bytes landed on `0x5e56d`, and Dracky(78)/Slime(8)
being 560 B / 70 species apart proved an 8-B/species table at **`$17:$62FD`**
(`MonsterBattlePalettes`), loaded by **entry 6** (`label17_41d0` / far-call `$1706`:
`$c81e`=species index ×8 + base, `$c81f`=dest slot). **Rules**: when a static trace
stalls, a SameBoy slot dump + ROM grep of the *exact* bytes beats hours of tracing;
always check existing labels — a misnomer can be sitting on the table you're hunting;
and confirm OBJ-vs-BG before chasing the wrong buffer.

### Per-monster vs shared: dump the slot for two monsters
**Fix**: Dracky BG4 (`007b 6bff 2a97 0000`, red) vs Slime BG4 (`5c0f 6bff 7ea0
0000`, blue) differed while every other slot was identical → per-monster, settled in
one comparison. **Rule**: to decide per-monster-vs-shared for any palette/asset, read
the slot for two different subjects; identical-except-the-one-slot = per-subject.

### Recolour = a same-size 8-byte edit of one species' entry (Iron-Rule-2 safe)
Each entry is `[c0, c1=$6bff backdrop(forced), c2, c3=$0000 black]`; only c0/c2 vary.
Editing Dracky's entry (`$17:$656d`) to the clam's colours touched 4 bytes, recoloured
ONLY Dracky (per-species), and is a same-size edit in bank `$17` (no insertion →
Iron-Rule-2 OK). `build_sprite_swap.py --palette` does it. **Rule**: a same-size data
edit in a no-insert bank is allowed; the insert ban is about *shifting* bytes.

### Corrected GFX-2 doc leads (were wrong)
`FuncFld_6942`'s `ld h,$04` is a pointer high byte for VRAM **tile** streaming, NOT
"OBJ slot 4"; the bank `$07` `SetGBCPalette` calls are scene palettes; and
`SetGBCPalette($04)` is the constant battle-palette REFRESH — the per-monster colours
come from `MonsterBattlePalettes` via entry 6, not from that call. **Rule**: trace
palette colour to the per-index TABLE LOADER, not the upload/fade/refresh path.

### The sprite/palette system is orthogonal to all prior custom work
The combined ROM (custom rooms + encounters + breeding + library + Spirit family +
clam swap + Dracky→Spirit) ran clean. The swap lives entirely in bank `$7e` (art) +
2 bytes in `$00` (repoint) + one entry in `$17` (palette) — none of the breeding
(`$69`), library (`$12`), custom-content (`$60/$64/$67`), or family (`$03`) banks.
**Rule**: graphics swaps and the content/data systems don't interact; they can be
developed and tested independently.

## Session 24 Lessons — GFX-3 (follower walking-sprite swap + metasprite engine)

**1. A symmetric test subject masks layout bugs — pick an asymmetric one.** The first
follower swap used a DWM2 *clam* (a near radially-symmetric blob). It rendered correctly in
all four directions and we believed the tile→direction layout was solved. It was not: a blob
looks identical whether or not subtiles are swapped, flipped, or mis-mapped, so it validated
the *mechanism* but silently passed a wrong *layout*. Switching to a directional *dragon*
(distinct head / back / profile) immediately exposed the errors. **Rule:** validate any
spatial/sprite layout with the most asymmetric subject available; a symmetric one gives false
confidence. (Cost us several rebuild cycles before we changed subjects.)

**2. OBJ index 0 is hardware-transparent — the opposite of the battle BG path.** Battle
sprites render as BG tiles where the backdrop is colour index 1 (GFX-2). Followers are OBJ
sprites where **index 0 is transparent by hardware**. Empty pixels MUST be idx0 or the sprite
gets an opaque box. Carrying the battle assumption (idx1 backdrop) into the follower path was
the first wrong turn. **Rule:** transparency convention is per sprite category — confirm it,
don't inherit it.

**3. Numbered-tile calibration beats screenshot-decoding.** We first tried to read the layout
from screenshots of bar-coded tiles and decode pixel patterns programmatically — noisy and
self-contradictory. The fix: build a calibration ROM where **each of the 16 VRAM tiles renders
its own hex index (0–F) plus a small "foot" in one corner** (foot on the left = unflipped, on
the right = X-flipped). The user then just *reads the numbers* off-screen per direction — zero
decoding, zero ambiguity. (Force black-digit/red-foot by overwriting the 8 OBJ palettes so the
glyphs are legible against terrain.) **Rule:** when you need ground truth from a running game,
make the game spell out the answer rather than inferring it from pixels.

**4. The follower render is a metasprite engine — recover the FORMAT from code, the VALUES by
calibration.** `SaveScr_40cd` walks 4-byte `(dy, dx, tile_offset, attr)` entries; tile =
offset + base (`$ffc9`), attr = `$ffca XOR` entry (X-flip bit5), `$80`-terminated, selected by
`$ffc7`→`$ffc8`. Static analysis cleanly recovered this *format* but NOT the literal per-monster
tile tables (they sit behind a type-byte/bank-routing indirection). Once the format was known,
calibration filled the values in a single clean pass — and any reading that didn't fit
`(position, tile 0–15, flip)` was rejected as a misread. **Rule:** code gives you the schema;
the running game gives you the data — use each for what it's good at instead of forcing one to
do both.

**5. Followers use PER-MONSTER layouts (118 of them), not one universal arrangement.** When the
dragon scrambled on Dracky but was perfect on DarkDrium with identical art, the cause was that
`$ffc7` (the monster's sprite-class) selects one of **118 distinct layouts**. ~64% are
**non-sharing** (down/up/side use disjoint tiles → any distinct art renders clean) and ~36% are
**sharing** (up/side reuse tiles — tile-budget-efficient for blobs, wrong for directional art).
The user's instinct ("the game has 200+ *distinct* monsters, so reuse can't be universal") was
exactly right and is what prompted testing a second monster. **Rule:** don't generalize a
layout from one sample; if the data model *could* be per-entity, test a second, deliberately
different entity before declaring it universal.

**6. Decouple art from layout in the editor.** Because art (16 tiles) and layout (metasprite)
are orthogonal, the editor should treat them as two independently-stored, independently-editable
things, and **default every import to a non-sharing layout** (reassigning the host's sprite-class
if needed) so arbitrary art always renders clean — the blob-sharing layouts only matter for
original-game fidelity or tile budget.

## Session 25 Lessons — GFX-4 (monster→layout map, custom-art import, multi-context consistency)

**1. The same datum can be duplicated N times across the ROM — find ALL copies before declaring a
swap "done."** GFX-3 repointed the overworld follower-art table (`$01:$49DF`) and looked complete.
But the per-species follower gfx-ID table is copied **eight** times (`$01 $06 $07 $09 $0b $12 $18
$59`), one per UI context (overworld, menu, library, battle-adjacent, cutscene…). The menu loaded
its own copy, so a "swapped" monster kept its old art there while rendering on the *new* (shared)
layout — broken subtiles + wrong palette. The user caught it instantly by opening the menu.
**Rule:** when a swap is correct in one place and wrong in another, the wrongly-rendered place is
reading a *different copy* of the same table. Grep the whole ROM for the table signature (a
distinctive ~10-byte run of the first few entries) and validate hits by comparing the full record
against the canonical copy — don't assume one table.

**2. A field's NAME in the docs is a hypothesis, not a fact — re-derive it from the struct.** The
docs called `[$caca]` a "sprite-class byte" that selects the layout. It is actually the party
struct's **species** field (`$cac1 + $09`). That single correction collapsed the whole GFX-4
"sprite-class extraction" sub-task: the layout is indexed by species directly, so there was nothing
extra to extract — and it killed the planned "reassign by a same-size `[$caca]` edit" (you can't
change a monster's species to restyle it; you repoint its `$407f` level-1 entry instead).
**Rule:** before building on a named field, confirm the name against the structure definition; a
wrong name can invent or hide entire subsystems.

**3. "Located via brute-force pattern match" ≠ "located on the real code path."** S24's layout
extractor scanned banks `$05/$10/$11` for any six-pointer table and deduped by signature, then the
docs recorded bank-`$05` example addresses. The *actual* follower path never touches bank `$05`
(that's the ObjTest viewer); the real level-1 tables are at fixed `$10/$11:$407f`, reached by
`ld de,$407f; call $0d91` in bank `$10`/`$11` entry 0. Dedup-by-signature hid the discrepancy
because identical layouts appear in multiple banks. **Rule:** to locate a table the game uses,
trace the code that reads it (here: the `$0402` dispatch → `$407f`), don't pattern-match the data
and hope; verify by reproducing a known runtime result (Healer + DarkDrium reproduced byte-for-byte
through `$10`/`$11`).

**4. An over-strict decoder silently shrinks your dataset.** The S24 extractor required each frame
to be exactly 4 metasprite entries and `return None` otherwise — so every small/blob monster (Slime,
Metaly, …), whose frames are 3 entries (one head tile + two mirrored body halves), was dropped. The
"118 distinct layouts" was really "118 of the 4-entry layouts"; the true count is **155**. The
authoritative species-indexed walk (which must decode *every* species) naturally exposed the gap.
**Rule:** a "complete" library built by filtering is only as complete as its acceptance test;
prefer driving extraction from the authoritative index (every entry must decode) over a permissive
scan that's allowed to skip.

**5. Don't trust a tool's baked-in packing — pack to the target layout's actual geometry.** The
`follower_frame_picker.html` `copyp` payload samples only the `-a` walk frames and uses a fixed
16-tile arrangement that matches no single in-game layout (its side view would mis-render). Packing
the imported art to the *chosen* layout's real tile→quadrant mapping (layout 0: 0–3=DOWN-a, 4–7=
SIDE-a, 8–11=SIDE-b, 12–15=UP-a, with engine auto-mirror for down_B/up_B and LEFT) is correct by
construction and uses both side walk frames. The user's DOWN/SIDE/UP × a/b frames map directly.
**Rule:** when art and layout are separate, slice the art to the layout you're assigning, not to a
tool's hardcoded template — and verify with an engine-accurate render (tiles + layout + OBJ palette)
before building the ROM.

---

## New-Monster / Encyclopedia Detail Freeze (Gorbunok id 224, 2026-06-22)

### Per-species table entry counts VARY — there is no global "monster count"
The biggest structural lesson. Different systems size their per-species tables
differently (monster info 221, FamilyRecipeTable 222, detail-description 215,
name 256, FamilyCode 215, …). There is **no runtime bounds check** anywhere: every
reader does `base + id*stride` blind. A high new id silently overshoots any table
shorter than the id and reads whatever follows. **Before wiring a new species into
any system, look up that system's table size** — see `MONSTER_DATA.md` (Species ID geography).
**Rule:** treat every `base + id*stride` as a potential overshoot; verify the count.

### Text source is a mode×species double indirection, not a direct pointer
`SaveBankAndSwitch` (`$00:$092F`) resolves the text source as
`[ [$4007 + mode*2] + species*2 ]`. Assuming `de=$4007` was the source (it is the
*mode-table base*) wasted time. When a render's source looks like garbage, trace
**both** indirections and check which mode's table you landed in and its size.
**Rule:** for `$4007`-based text, the source = mode-table[mode] then [..][species].

### Overshoot into CODE reads opcodes as a pointer → renders code as glyphs → spin
The description table ended exactly at routine code; id 224's slot was *inside*
`SetB4d_43b9`, so the "pointer" was the opcode bytes `09 06` = `$0609`. The text VM
then rendered ROM0 code as text endlessly and the screen-update wait spun. The
freeze address `$0609`/`$0617` in the crash dump **was** the overshoot value — match
dump pointers against table-plus-index arithmetic early.

### Cosmetic glitches downstream of a freeze are usually abort artifacts
The "material" family icon and stale "Healer" info were **not** separate bugs — the
page froze mid-draw so later refreshes never ran. They vanished when the freeze was
fixed. **Rule:** fix the hang first; don't chase secondary visual oddities that sit
*after* the hang in the draw order until the hang is gone.

### Fix shape that keeps working: byte-neutral reader fork → free-space resolver
Every fix this session followed the proven pattern: replace the reader's index
math in place with `call Resolver` + `ds`-pad (same length), and put the
species-gated logic in trailing free space, padding the bank with `ds $8000-@,$00`.
Diff vs the prior ROM must show only the intended regions + header checksum.

### Build hygiene: copy generated banks with a plain shell loop
The recurring build break was `bank_064/067/069/06a.asm` not reaching
`disassembly/` because a Python one-liner that imported `PATCH_FILES` errored on
`__file__`. **Rule:** copy the patch + generated banks with a hardcoded bash `for`
loop (or `cp patches/*.asm disassembly/`), never an `exec`-of-the-verify-script.

### A table-index overshoot can inject a hardware FLIP, not just wrong data
New-species follower (id 224): the per-species attr read `[$412d + (species-$80)]` overshot
its 87-entry table into live layout data at `$418d = $41`. That ONE garbage byte produced TWO
"separate" cosmetic bugs at once — **bit6 ($40) = OBJ Y-flip** (every tile rendered upside-down
in place) and **low3 = 1 = green palette**. The OAM builder (`SaveScr_40cd`) does
`attr = [$ffca] XOR entry_attr`, so any flip bit in the overshoot byte flips the whole sprite.
**Rule:** when an overshoot is in play, "upside-down/mirrored sprite" and "wrong palette" are
often the SAME root cause — decode the stray byte's bits before treating them as independent
problems. The clean fix is to fork the READ (supply a correct attr), not to pre-flip the art
(which only cancels the symptom and silently couples art orientation to a garbage byte).

### Sanitising a base attr: clear ONLY the garbage bits, never the X-flip the engine drives
Follow-on from the above. After forking the new-species attr read, the clean attr must be built
with a SURGICAL mask. `[$ffca]` is the **engine's** base OBJ attr, and the engine sets **bit5
($20 = X-flip) every frame for the LEFT facing** — in layout-0, LEFT and RIGHT share the SIDE
frames and LEFT is produced by a global X-flip carried in `[$ffca]` bit5 (the vanilla
`[$ffca] |= attr` preserved it, which is why an existing-monster reassign mirrors LEFT
correctly). Two builds in a row had the follower face RIGHT while walking LEFT (up/down/right
fine) because the fork used `and $98` (`1001_1000`), which clears bit6 (Y-flip, correct) **and
bit5 (X-flip, WRONG)** — wiping the engine's left-facing flip each frame. The fix is `and $B8`
(`1011_1000`): clear only the genuine garbage — **bit6 (Y-flip) + low3 (palette)** — and
preserve bit5. **Rule:** a "clean attr" mask must touch ONLY the bits that are actually garbage
(Y-flip + the palette you're overriding). Bit5 is the engine's per-direction X-flip; clearing it
is a silent directional bug that static byte-tracing won't surface (it only manifests for the
one mirrored facing). Decode every bit of a mask against what the engine writes before using it.

### Static byte-tracing can "prove" a fix that the emulator disproves — use a numbered-tile ROM
The overworld follower stayed wrong across several builds while every byte I checked (clamp,
fork, overflow pointer, layout index, engine dy-sign) said it should be right. The gap was a
prior-session placeholder clamp that I'd verified as "narrowed" but whose EFFECT I'd mis-modeled,
plus the attr overshoot the static read never surfaced. **Rule:** after 2 builds that "should
work" but don't, stop re-deriving and ship a calibration ROM (follower tiles replaced by glyphs
0–F). Reading back which digits land where, and whether they're flipped, collapses "is the art
loading?" vs "is the layout/flip wrong?" into one decisive user report.

### Bank $10 and bank $11 follower tables are NOT at twin addresses
Long-standing doc error: attr table listed as `$10/$11:$417f`. Real: bank `$10` = `$417f`
(128 entries) but bank `$11` = `$412d` (87 entries), because bank `$11`'s level-1 pointer table
is shorter so its attr table packs lower. Any "covers 0–255 symmetrically" assumption about the
follower tables is wrong — bank `$11` only has rows for species 128–214, so 215+ overshoot.

## Session 35 Lesson — G2 (new-species BATTLE sprite + palette baked)

### Two sibling species-indexed tables can need OPPOSITE mechanisms at the top of the id range
The battle GFX table (`MonsterBattleGfxTable $00:$2B9F`, 256 real slots — ids 216–255 are uniform
`$320f` placeholder padding) and the battle PALETTE table (`MonsterBattlePalettes $17:$62FD`, only
~216 slots) sit next to each other conceptually but behave oppositely for a NEW species (id 224):
- **Gfx = a same-size 2-byte table write, NO fork.** id 224's slot `$2b9f+224*2 = $2d5f` exists (it
  holds the `$320f` placeholder), so repointing it to the overflow gfx-ID (`$7e01`) is a direct edit.
- **Palette = a fork, NOT a table write.** `$62fd+224*8 = $69fd` overshoots into `PaletteColorData`,
  so there is no slot to write — the reader's add-base (`label17_41d0`) must be intercepted
  byte-neutral and a resolver returns a custom palette for id ≥ 224.

**Rule:** never assume "it's a species table, so a new species is always either a write or always a
fork." Check each table's real length against the target id independently — `slot exists` vs
`overshoots` is per-table, and it decides write-vs-fork. (The contrast with G1, where ALL 8 follower
gfx tables overshoot and every one needed an id-indexed fork, is the tell: same "new species, new
art" goal, completely different edit shape per table.)

### Re-expressing a mgbdis-misassembled data slot as `db` is byte-neutral and unlocks the edit
The `patches/bank_000.asm` copy predates the S22 re-section, so the battle gfx table reads there as
fake `ld [hl-],a`/`rrca` instructions. To repoint one entry, replace just the label-bounded span
covering it with explicit `db` (bytes copied from the ROM, one word changed). The build stays
byte-identical except the intended 2 bytes; all 23 mgbdis cross-ref labels in the region keep their
addresses because they bound the span rather than sit inside it. Verify by diffing the patched build
against the *previous* patched build — the G2 delta should be exactly: the 2-byte repoint, the
byte-neutral palette fork, the resolver in bank `$17` filler, the overflow-bank growth, and the auto
header checksum. Nothing else.

### Adding a 2nd overflow entry shifts the 1st stream's address but not its gfx-ID
Putting the battle stream at index 1 grows the bank `$7e` pointer table from 1 to 2 `dw`s, so the
follower stream (index 0) slides 2 bytes — but its gfx-ID `$7e00` still resolves, because the
resolver dereferences the pointer table (`$<bank>:$4001+index*2`), it never hardcodes the stream
address. Confirm by decoding both gfx-IDs back to their payload md5s after the rebuild.

### A write-watchpoint on the affected RAM beats grepping for an unknown mechanism (S37, damage tiles)
**Symptom**: "Where does floor-tile damage get applied?" Static search was fruitless — `cp $38`
(the known brown damage-tile id) appears 30+ times across banks, all unrelated (animation counters,
skill dispatch, misassembled data); the ground-feature list (`$D793`), the per-step encounter
handler, and the `$D7D2` NPC scan were all dead ends.
**Root cause**: detection is NOT a raw tile-id compare. The engine reads the standing tile id into
HRAM `$AA` (`$00:$1E96`) and tests its **behavior class** `$AA>>2` (`$0E` = damage, ids `$38-$3B`).
A grep for the *mechanism* can't find a routine that never names the constant you're searching for.
**Fix**: one SameBoy write-watchpoint on the party leader's current HP (`$CB11`) + a single step
onto the tile broke exactly at the HP store; the backtrace (`$01:$5E23 ← ... ← $00:$1E96`) handed
over the whole routine chain in one shot. Mechanism fully documented in minutes after hours of grep.
**Rule**: when hunting "where does X happen to Y" and the code may not name any constant you know,
set a write-watchpoint on Y and trigger X once — the break PC + backtrace is the answer. Reserve
grep for when you already know a label/constant the target code must contain. (Behavior class =
`tile_id >> 2` is the unifying trick: `$0E`=damage, `$0F`=staircase share one `$AA` lookup.)

---

## Session 39 Lesson — custom gate room + room-palette derivation

### Every BG palette has two engine-forced colours — derive only indices 0 and 2
**Symptom**: ROM palette bytes read straight from a room's pointer didn't match the
SameBoy dump for several rooms (Stable, Well), even though others (GreatTree) matched.
**Root cause**: the engine **overwrites BG colour index 1 → `$6BFF` and index 3 →
`$0000`** in every palette at runtime. Rooms whose ROM bytes already hold those values
matched by luck; rooms that don't got "corrected" on load. So only indices 0 and 2 are
real palette data.
**Fix**: read colours 0 and 2 from the room's palette block; force 1=`$6bff`, 3=`$0000`.
30/30 dumps + the gate floor then reproduced exactly (`tools/derive_room_palette.py`).
**Rule**: when derived data is right for some inputs and wrong for others, look for a
runtime normalisation that makes the wrong ones *look* right by coincidence — don't
trust a partial match. (Object palettes are a global block at `$17:$5615`; BG slots 4–7
are a shared system set; only slots 0–3 are per-room.)

### A room's palette can live on a screen other than screen 0 — scan, don't assume
**Symptom**: Starry Shrine (`$09`) "had no palette"; the Intro (`$2F`) looked
script-driven; both seemed like underivable special cases.
**Root cause**: a room's attr block is a list of screen pointers, and **screen 0 can be
`$FFFF` (empty)** with the real data on a later screen (Starry Shrine → screen 1;
Intro → screen 4). Reading only screen 0 finds nothing or the wrong block.
**Fix**: scan screens for the first whose step-0 `pal_ptr` lands in the palette region
(`$5200–$6300`); refuse only if none resolves. Both rooms then derived correctly — no
script path involved. The Intro and the Library's opening cutscene even **share a
screen** (`$5ADD`), which is why their dumps were identical; the normal Library (`$12`)
is a different palette (`$583D`) on every screen.
**Rule**: before declaring a room "script-driven / special", scan all its screens — an
empty screen 0 is normal. And a tool that can't resolve a palette must **refuse, not
guess**: a plausible-but-wrong palette is worse than an honest failure.

### User-facing room labels were DECIMAL; mapIDs are hex
**Symptom**: "Well (mt24)" derived garbage at mapID `$24`.
**Root cause**: the human's `mtNN` labels are **decimal** (Well mt24 = mapID `$18`,
Library mt18 = `$12`, boss rooms mt49–60 = `$31–$3C`). Feeding the label as hex hit the
wrong room entirely — which masqueraded as a derivation bug.
**Rule**: pin the radix of any externally-supplied index before trusting a mismatch;
a "wrong output" is often a wrong *input* in the wrong base. (`mtNN` decimal → `$NN` hex.)

### Maze "trees/dunes" are 2×2 metatiles, and need per-position palette
**Symptom**: arranging gate-tileset fragments into green/sand blobs didn't read as the
trees/dunes the user knew were in the tileset.
**Root cause**: trees/dunes are **specific 2×2 object metatiles** (`$34-$37` tree,
`$38-$3B` dune in bank `$28` step `$0D`), not free-form texture. The *same* tiles are a
green tree on pal3 or a sand dune on pal0 — palette, not tile, distinguishes them. A
pure tile-id→palette threshold rule can't express this (trees and ocean both sit on the
same side of the `$30` collision threshold yet need different palettes).
**Fix**: assign palette **per position** in the attr nibbles (`tools/build_gate_room.py`).
**Rule**: in a shared maze tileset, "what is this" is set by tile **and** palette
together; author decorative objects as metatiles with explicit per-cell palette, and
keep the custom-room palette load to slots 0–3 only (widening it clobbers the shared
system slots and corrupts monster colours).

## Session 40 Lessons — Pillar A (table-driven custom-room rendering, 2nd custom room)

### Warp screen-byte must be $00 for a single-width custom room (off-map spawn reads as "can't move")
**Symptom**: Second custom room ($6C) loads and renders fine; player can change facing but
cannot walk in **any** direction; tiles/area around the player look like garbage.
**Root cause**: the 7-byte exit's **byte-4 is the `screen_byte` that indexes the `$2DE7`
spawn-offset table** (documented in the bank `$0B` warp parser at `$0B:$45A8`), NOT a
"destination screen number". `$2DE7[idx]` is an (X,Y) metatile base for horizontally-tiled
screens: idx 0→X+0, 1→X+10, 2→X+20, 3→X+30 (idx 4-7 add Y+8). The exit carried
`screen_byte=$01` — a **stale value from when `$6C` was a wide multi-screen Castle clone**,
where `$01` was legitimate. For the 20-tile-wide gate room `$01` adds +10 metatiles →
final spawn at tile **column 35**, far outside the room in the off-map `$FF` padding. The
player is stranded off-map, so every step is blocked. (This is the exact failure the
v14-v18 lesson warns about; I carried a guessed field label and even *dismissed* the
`$01`/`$00` difference because my wrong label made it look like a harmless facing flag.)
**Fix**: `screen_byte=$00`. Player lands at metatile (7,6) = tile (15,13), inside the room.
**Rule**: (reinforces v14-v18) Decode a binary format from the code that **consumes** it
before editing data in that format — never infer a field's meaning from its struct
position. For a single-screen-width custom room, exit byte-4 must be `$00`. Verify in
SameBoy: `wWarpSpawnXLo` must compute to the intended pixel X, not +160 (= +10 metatiles).

### Night palette-swap: a cheap, powerful room variant via the per-room palette table
**Idea**: once rendering is table-driven (`CustomRoomPalPtr[mapID-$6B]`), a second *distinct*
room can be made by reusing an existing room's layout + tileset + attr and pointing only its
palette-table entry at a new 64-byte palette. `$6C` is `$6B`'s sandy island recolored to a
coherent **moonlit-night** palette (cool slate ground, navy water, dusk-teal trees) — same
layout, ~64 bytes of new data, zero new render code.
**Why it must preserve value structure**: the gate tiles' pixel→index mappings were authored
for the gate palette, so a recolor must keep **idx1 light, idx3 dark** and shift only hues,
keeping idx0/idx2 close in value — otherwise a textured floor tile renders as high-contrast
**stripes** instead of a smooth surface. A first attempt with saturated magenta/green/cyan
read as "glitchy" for exactly this reason (it broke the value relationships, and the player
was simultaneously stranded off-map by the warp bug above, compounding the "it's broken"
impression).
**Use**: day/night and biome variants (snow, volcanic, cave) of one room cost ~64 bytes each
and no new code — strong tool for campaign-room variety.
**Rule**: recolor = hue-shift inside a **preserved value structure**; derive the new palette
from the source palette, not from scratch; keep the custom-room palette load to slots 0–3.

### Renderer/tooling: custom layouts are 32-wide VRAM format, not 20-wide
**Symptom**: a standalone preview-renderer produced scrambled output — 2×2 tree/hole
metatiles split apart, objects misplaced, "coordinates all screwed up".
**Root cause**: a decompressed layout is **512 bytes = 32 columns × 16 rows** (GB BG width):
visible columns 0-19, columns 20-31 = `$FF` padding (see
`tools/tile_layout_compiler.py:pad_layout` docstring). Reading it with a 20-stride offsets
every row.
**Fix**: stride **32**, render columns 0-19. Attr is unpacked separately (nibble-packed,
`base = attr_row*32 + half*16`).
**Rule**: read a format from the tool that **produces** it before consuming its output. A
wrong coordinate model is more expensive than a wrong byte — this one silently invalidated
several rounds of "the spawn tile is walkable" reasoning during the warp-bug hunt.

### Tooling: ROM0 (bank $00) file offset = address, NOT address − $4000
**Symptom**: a byte known to be non-zero (e.g. the `$26DD[$6C]` record at ROM0 `$2A3D`) read
as zeros when dumped by a tool, sending the debug down a false path.
**Root cause**: for **ROM0 addresses (`< $4000`)** the flat file offset **equals the address**
(`$2A3D` → file `$2A3D`). The `bank*$4000 + (addr−$4000)` formula is only for banked addresses
(`≥ $4000`). Applying `addr−$4000` to a ROM0 address reads from the wrong place.
**Rule**: `file_off = addr if addr < $4000 else bank*$4000 + (addr − $4000)`. Most `$26DD`/
`$2A5D` gate tables and ROM0 helpers live below `$4000` — get this wrong and every ROM0 dump
lies to you.

---

## Session 41 Lessons — Pillar B (custom room inserted into the gate rotation + descent)

### A `call`-based fork can stay byte-neutral if the handler `pop`s the return address
**Context**: inserting a custom room into gate 1's floor rotation, the cleanest hook is the
6-byte gate-0 exclusion at `$16:$5BA9` (`ld a,[wGateID]/or a/jr z,jr_016_5bbf`). Replacing it
**in place** with `call GateDecisionFork`+3 nop keeps the byte count (6→6) so nothing in the
bank shifts — but a naive `call`/`ret` returns to *just past the call* (into the RNG gating
that the original `jr z` skipped), which re-runs the standard path and clobbers `wMapID`.
**Fix**: in the fork, the branches that must behave like the original `jr z` (`gate 0` →
maze, `gate 1` → custom) do `pop hl` to **discard the call's return address**, then `jp` to
their target. Their downstream `ret` then unwinds one frame further — to entry-5's *caller* —
exactly as the vanilla `jr z` did. The fall-through branch (other gates) just `ret`s normally
to continue into the code after the call. `HL` is dead at that point (reloaded on every
downstream path), so popping into it is safe.
**Rule**: a mid-routine `jr/jp z, X` can be converted to `call Fork`+pad **only** if the fork
discards the pushed return address (`pop`) on the paths that emulate the original jump.
Verify the target labels resolve and decode the built ROM (`call` operand + each `pop/jp`).

### `wInGateworld = 0` makes the engine treat a descent as a *fresh hub→gate entry*
**Symptom**: a custom gate room descended to the next floor correctly, but with the **slow
dissolve** (the hub→gate-entry fade) and the **BGM restarting every descent**, instead of the
maze-floor **whoosh + continuous BGM**.
**Root cause (one cause, both symptoms)**: the custom room runs with `wInGateworld = 0`
(special-room render mode). The fade-style and BGM decisions read `wInGateworld` *during the
transition window* (after the exit fires, before the room reloads), when the leaving room's
display value (`0`) is still live → "we are entering a gate from outside" → dissolve + the
gate-entry path stops the music, so `LoadNewBGMIdIntoA` (`$01:$4364`, restarts only on
`call nz, SetBGM` when the id differs) re-loads it. Maze floors keep `wInGateworld` nonzero
(`$01`) the whole time, so their descents read as in-gate floor changes → whoosh, BGM kept.
**Rule**: in-gate-vs-fresh-entry transition feel is gated on `wInGateworld` at transition
time, not on the warp flags (both maze and special-room descents set `wWarpFlag=$80`).

### Don't make a custom room a "real in-gate floor" by setting `wInGateworld` during display
**Symptom (regression)**: setting `wInGateworld=$01` while the custom room is on screen (to
get the smooth descent) **froze the game and stopped the room rendering**.
**Root cause**: `wInGateworld` is the master gate/maze selector — it gates the tileset table
(`$26DD` vs `$2A5D`), the exit checker (exit-list vs maze staircase), per-step maze handlers,
and more. Flipping it nonzero routes the custom room through **all** of those, and the ones
not intercepted go reading maze state (staircase screen `$C960`, grid buffers) the custom
room never set up. There is **no** nonzero value that avoids the maze paths (they test
`or a / jr nz`).
**Rule**: a table-driven custom room must keep `wInGateworld = 0` for the entire time it is
displayed. Anything that needs the in-gate value must be **transient**.

### Transient-flag-during-transition: flip a master flag only in the warp window, let the engine reset it
**Technique**: to get the in-gate descent feel without the freeze, set `wInGateworld=$01`
**only at the gate-flag exit transition point** (`$0B` `jr_00b_466b`/`$45F9`), gated on
`wMapID ≥ $6B`, via a byte-neutral `call CustomDescentInGate` (it also restores the
`ld hl, wGameState` it displaced). The engine's own reload flow then resets the flag (Entry 0
sets it from `wWarpFlag`, then the fork → `CustomGate1Setup` sets it back to `0`) **before the
room redraws** — so the fade/BGM read "in gate" during the transition, while the room never
*displays* in the broken in-gate state. Non-custom rooms (`wMapID < $6B`) are untouched.
**Why it works**: the symptom-causing read and the freeze-causing reads happen at *different
times* (transition window vs display/room-load). A flag that is wrong for one and right for
the other can be satisfied by toggling it across that boundary rather than holding one value.
**Rule**: when a single flag is read at two phases needing opposite values, set it transiently
in the phase that needs the exception and rely on the engine's existing reset for the other —
don't hold the exceptional value through both phases.

## Session 42 Lessons — Keystone (table-driven dispatch, $26DD ceiling lifted)

### Empty-bank-as-logic-home: dodge dense-bank fragmentation entirely
**Problem**: the three remaining hardcoded intercepts live in dense banks (ROM0, `$0B`) with
no contiguous free space — the largest genuine runs were ~9 B (`$0B`) and the only big ROM0
run was inside audio data (see next lesson). Scattering ~40 B of interdependent helpers across
6-12 B fragments with `jr`-range constraints is fragile.
**Technique**: put **all new logic + data in a previously-empty reserved bank** (here `$71`)
and reach it via `rst $10`. Each in-bank edit then collapses to a **≤10-byte byte-neutral
stub** (`ld hl,$71xx / rst $10 / ld hl,wScratch` + nops). No ROM0/`$0B` free space needed;
no shifting of dense code/audio.
**Rule**: when an edit needs more contiguous free bytes than a dense bank offers, don't
fragment — move the body to an empty bank behind `rst $10` and leave a fixed-size trampoline
in place. The far-call **far-COPY** contract (routine writes WRAM scratch, caller reads it; DE
preserved) is the reliable shape — mirror `bank_06a`/`NewSpeciesInfoCopy`, don't rely on
returning a pointer in HL.

### `push bc`/`pop bc` survives an `rst $10` round trip — use it to protect a live register
**Context**: the ROM0 collision-threshold reader holds the player's tile value in `C` across
the record lookup (`ld c,[hl]` before, `ld a,c` after). `rst $10` clobbers `BC`, so routing
that site through bank `$71` looked impossible.
**Technique**: wrap the far call as `push bc / ld hl,$7100 / rst $10 / pop bc`. `rst $10` is
stack-balanced (the whole game relies on it returning), so a value pushed before it is intact
after — `C` is preserved.
**Rule**: `rst $10` clobbers A/BC and is unreliable for HL-return, but it does **not** corrupt
the caller's stack; `push`/`pop` around it protects any register the routine would otherwise
destroy.

### The free-space scanner lies inside data regions — runs of $00/$FF can be live data
**Symptom**: `tools/find_free_space.py`-style scans reported "free" runs at ROM0 `$318E`,
`$3A83`, and an `AudioNOPBlock` — but these sit **inside decoded audio wave/song data**
(`cp $fe` = `$FE` samples, `ld bc,$0101` = `$01` samples, NOP runs = rests). Overwriting them
would corrupt sound, not reclaim space.
**Rule**: a filler-valued run is only *safe* free space if it is end-of-bank fill or
explicitly-known padding (e.g. the `$3BC1` "unreferenced rst $38" run prior patches used).
Verify against labels/section boundaries before trusting a scan; in pinned data banks, a
`$00`/`$FF` byte may be meaningful. This is what pushed S42 to the empty-bank approach above.

### Recognise when a "hardcoded" thing is already O(1) — don't add a table for its own sake
**Context**: `MapIDClampForPalette` looked like a hardcoded `cp`-chain, but it already returned
`$00` for *every* mapID `≥ $6C` — only the lone `$6B→$16` case was special, and that fallback
was dead (overridden by `CustomRoomAttr`/`CustomRoomPalPtr`). Adding rooms never required
editing it.
**Rule**: before "table-ifying" an intercept, check its actual scaling. If it's already O(1),
the systematic move is to remove the one special case (here: make it uniform `$00`), not to
build a per-room table that costs scarce space for no benefit.

### Staircase tiles ($3C-$3F) are inert outside gates — safe as visible exit markers
**Context**: edge exits were invisible walk-on triggers on plain sand. The gate tileset's
PIT/staircase quad (`$3C-$3F`, behavior class `$0F`) is the natural "step here to transition"
visual.
**Why safe**: class `$0F` is auto-detected **only** by the gate-world exit handler
(`$0B:$46A7`, `$AA>>2==$0F`). In a non-gate room that handler is inactive, so a staircase tile
is purely cosmetic + walkable; the warp is still driven by the coordinate-based exit record.
**Rule**: you can place a class-`$0F` staircase on any exit metatile to mark it, as long as the
room isn't running the gate exit handler — it won't auto-trigger anything; the exit record does
the work. (Shared layouts mean the marker also appears in sibling rooms that reuse the entry;
it only warps where a record exists.)

## Session 45 Lessons — Custom skill EFFECTS (ROADMAP S2, alias framework)

Full RE + framework: see `BATTLE_SKILL_SYSTEM.md`. Shipped patched ROM (md5
`6e8b8337805d020ca6cdbf878c21f1c6`, **patched** not original) verified in-game:
Scorch = Blaze 14 dmg, Smite = 80 dmg, attacks fine.

### ⚠️ TRUST CALIBRATION — this took 9 test iterations; my confidence was often wrong
Multiple times this session I stated a fix was correct, and in-game testing
proved it broke something (enemy stat corruption, wrong targeting, no
animation). **Do not accept a "this is correct" claim about the battle engine
without a build + live test.** Items I label INFERRED in the docs are
hypotheses. The only things that are truly settled are the ones a human watched
work on hardware/emulator.

### id-range bucketing is pervasive — there is no single "current skill" variable
The engine buckets the skill id by NUMERIC RANGE in many independent places
(targeting, animation, cast message, MP, per-skill record), each with its own
`cp`-chain or 222-entry table bound, spread across banks $50/$52/$53/$58. A
net-new high id ($DE) overshoots/falls through ALL of them, so it presents wrong
everywhere at once. Fixing buckets one at a time is endless whack-a-mole.

### Alias > re-implement: make the new id masquerade as a template skill
Instead of teaching every bucket about the new id, templatize it to an existing
skill (Blaze=0) for the whole engine and peel off the real id only for the
custom effect + the name. The leverage point is the **action queue `$dcec`** —
the single source every bucket re-derives from. Templatize the queue and the
engine inherits the template for free.

### Templatize at the COMMIT, not at cast-setup — TIMING is load-bearing
Targeting is locked in at the selection readback ($50:1866), which runs BEFORE
the cast-time attacker setup ($53:943). Templatizing at 943 was too late — the
caster hit himself with no animation. Templatizing at the commit (before 1866)
fixed presentation completely. Same byte, different line = pass/fail.

### `$db4c` is re-derived FROM `$db8a` during the cast — propagation works in our favour
The record/targeting index `$db4c` is repeatedly set from `$db8a` mid-cast
($53:1433/1778/2018/5054). So templatizing the queue → `$db8a`=template →
`$db4c`=template → correct record/targeting, with no separate `$db4c` patch.

### The literal-reference "free RAM" scan LIES for base+offset arrays (cost: 3 corruptions)
I picked "0 literal references" bytes ($ddf0, $ddfe, $de36) as scratch — all
three were inside the per-combatant battle struct array ($dd80 + 26*k), accessed
via a base pointer, so the scan never saw them. Each corrupted live enemy
stats / status / damage. **A scalar `ds` gap between two NAMED vars** (we used
$db86, between $db85 and $db88) is far safer, and you MUST confirm freeness by
in-game test, not by grep. Updated `known_RAM_map.md` accordingly.

### The `$db8a == 0` dispatch guard avoids needing the (unreliable) attacker index
`wBattleAttackerIdx` is repurposed during target processing, so it's wrong at
effect-dispatch time — a per-combatant stash indexed by it read the wrong slot.
The guard "use the stash only when the working id is 0 (templatized/Blaze)"
distinguishes the aliased cast from normal casts (which carry a nonzero id)
without ever needing the caster index at dispatch. Caveat: a real Blaze cast is
also id 0, so the guard has one unclosed edge (enemy casts real Blaze with a
player custom pending, enemy first) — see BATTLE_SKILL_SYSTEM.md §"Limitations".

### Tooling: a SM83 disassembler-at-address (`tools/sm83dis.py`) was essential
mgbdis renders routines that are jumped-to from data tables as raw `db`/`nop`,
so the real instructions are invisible in the .asm. `sm83dis.py <bank> <addr>
[n]` decodes live bytes at any address. Validated against SkillBlaze + the
dispatch only — spot-check exotic shapes.

## Session 48 Lessons — Skill-ID bucketing audit (S2d foundation, RE)

### Classify the id-reads before counting them — a huge surface can be mostly inert
**Symptom:** the working skill id `$db8a` is read at 254 sites across 9 banks (148 in
enemy AI alone). That looks like "endless whack-a-mole" (S45's words) and is why S45
aliased instead of de-aliasing.
**Root cause:** raw counts conflate kinds of reads. 204 of the 254 are *equality* checks
against specific skill ids, and the highest value compared is `$C5`.
**Fix:** a custom id (`≥ $DE`) matches none of them, so all 204 are auto-safe; the real
surface is the handful of fixed-size *table indexers* + a few range gates.
**Rule:** before concluding a bucketing surface is intractable, classify each read
(equality vs range vs table-index). An equality check against a value below the new id
is inert by construction — assert the max-equality invariant and move on.

### A dramatic-looking gate can be a symptom, not the root cause — trace the hot path
**Symptom:** I first flagged `$54:$535F` (which zeroes the record index for ids `≥ $d6`)
as the "critical divert" that breaks custom-skill magnitude.
**Root cause:** `$535F` is only ONE of four record readers, and a minor one. The MAIN
magnitude path is `$52:$66D6` → record reader entry 1, which *indexes the record table by
the id* and overshoots. SameBoy proved it: casting Scorching hit `$66D9`; `$535F` never
fired for Scorch/Zap/IceStorm.
**Fix:** the keystone is the shared record-table indexer fork, not the `$535F` special-case;
`$535F` can be deferred.
**Rule:** when a gate looks load-bearing, confirm it's actually on the live path (hardware
breakpoint) before designing around it. The root cause is usually the boring shared indexer.

### Verify a command's dispatch path before using it as a probe (RUN ≠ menu Flee)
**Symptom:** a breakpoint on skill `$DB`'s handler (`$52:$4E3A`) never fired when the user
chose Flee/Run from the battle menu.
**Root cause:** the menu Flee is a top-level battle command; skill id `$DB` "RUN" is a
separate skill-system entry, reached only when the skill machinery needs a flee effect.
**Fix:** don't use menu Flee to probe skill-id dispatch; high-id function dispatch is
already proven by the shipped S45 patch (Scorch `$DE`/Smite `$DF`).
**Rule:** a name match in a table (skill `$DB` = "RUN") does not mean the obvious UI action
routes through it. Trace the dispatch before spending a hardware breakpoint on it.

### Prove a fork is byte-neutrally *implementable*, not just *enumerated*
**Symptom:** enumerating the fork points doesn't tell you they can be built without inserting
bytes (the iron rule).
**Fix:** for the keystone, the 3 indexer sites are identical 5-byte windows
(`21 13 40 09 09`); checked there are no interior branch-targets; confirmed bank `$54` has
~10550 free in-bank bytes; then RGBDS-assembled a `call Fork`+nop+nop trampoline and
byte-executed it (mini SM83 interp) to show normal ids stay vanilla-identical and custom
ids index a high table.
**Rule:** a foundation session that gates an authoring session should end by proving the
fork *assembles 5-for-5 and behaves*, not just by listing addresses. Cheap, zero ROM risk,
and it catches "the window isn't replaceable" before the patch session discovers it the hard way.

---

## S49 (2026-06-29) — custom-skill PRESENTATION, end to end

### Missing presentation is empty DATA, not broken code
**Symptom:** custom skill `$E0` dealt damage + showed result text but had no
announcement, no animation, no hit-flash, no cast sound.
**Root cause:** every presentation layer reads a *per-skill data slot* indexed by
skill id, and `$E0`'s slots were empty/sentinel or overshot: announce
`AnnounceTemplateTable[$E0]=$FF` (silent), and the `$5f` anim-command tables
(`$56ed`/`$57d5`) overshoot past their valid range for `$E0` → garbage command →
the script never finishes → `$52:$6c4d` spins on `$da82` (hang).
**Fix:** fill the announce slot; for animation, fork the skill-id reads to a proxy
(below).
**Rule:** when a custom id is silent/invisible/hangs, look for an empty or
overshot per-skill table slot before suspecting logic. The engine is data-driven.

### Full-proxy the skill id; don't "trigger" a custom animation
**Symptom:** an earlier naive attempt to *trigger* `$E0`'s animation hung; `$E0`
has no script.
**Root cause:** the script VM keys off the skill id only at *selection* time
(bank `$5f`, 12 reads of `$db8a`); the renderers (`$5c`/`$5d`/`$5e`) read the id
**zero** times — they consume the `$da81` command stream. So a half-substituted id
desyncs and hangs.
**Fix:** `GetPresentId` — identity for stock ids, a per-skill PROXY id for custom
ids — forked into ALL 12 `$5f` reads (byte-neutral `ld a,[$db8a]`→`call`). The
custom skill then plays a real skill's *entire* script to completion. Flash + SFX
ride along because they are commands inside that script.
**Rule:** to borrow a behavior keyed by an id, repoint the id at every selection
read consistently — partial substitution is worse than none. Verify the diff is
confined to exactly the intended sites + free-space routine before trusting it.

### Re-disassembling a misdisassembled data table: clean form in patches/, label in disassembly/
**Symptom:** a per-skill data table (`$58:$5806`) is disassembled as fake code
(`inc hl`/`rst $38`/…); a one-byte data edit looked like poking a magic byte into
opcodes.
**Fix:** the clean labeled `db` table lives in `patches/bank_058.asm` (byte-identical
to the original except the one intended slot — verified by diffing the built bank);
`disassembly/` gets only a label-pointer comment (zero byte impact, integrity stays
`1ca6579…`).
**Rule:** representation fixes that change how bytes are *expressed* (code→data) are
functional changes → they belong in `patches/`; `disassembly/` gets a comment that
points at the clean form. Never "improve" `disassembly/` past labels/comments.

## Session 50 (S2e) Lesson — sequencing a note-then-hit custom skill (Tame)

**Symptom**: Tame's recruitment heart and its "takes X damage" sound/message played at the same
time; the enemy never blinked. Several "obvious" fixes did nothing.

**Root cause (a chain of wrong assumptions, each settled only by an emulator test)**:
1. The heart (note) and the hit-flash are BOTH layer-2 animation commands (`$56ed`→`$da81`),
   one slot per presentation → they cannot co-exist. A proxy "split" (anim on one id, flash on
   another) fails because the note IS the layer-2 command, not a layer-1 sprite.
2. Swapping the descriptor `$a8`→`$a0` changed nothing — both are bit6-clear, same state-machine
   path. The descriptor byte was never the timing lever.
3. The real timing lever is `$53:$5b07`: only ids `$84`–`$87` WAIT for the animation done-flag
   `$da82` before the message. But gating Tame on `$da82` STILL didn't separate them — the
   note's done-flag fires before the note visually finishes.

**Fix**: a FIXED FRAME DELAY in the effect state machine (fork `$5b07`→`TameGateHook`, counter
`wTameDelay`) holds the message N frames so the heart plays first; suppress the early damage
sound (`$5501`/`$5502` at `$5add`/`$5afa`) and re-fire it near the text. Damage `ATK/2`→`ATK/4`
(ATK/2 equalled a normal hit). Full detail: BATTLE_SKILL_SYSTEM §11.7 + §13.5.

**Rule**: For battle-presentation timing, the lever is the effect state machine's per-id
animation-wait gate (`$53:$5b07`) plus a frame counter — NOT the descriptor byte and NOT the
animation done-flag (it can fire before the sprite visually finishes). Two visually distinct
animations on one hit need two beats or a delay, never one presentation. Verify every
presentation hypothesis on the emulator — static reading of this control flow was wrong 4+ times
in one session (see the §11 warning banner).

**Still open**: the per-enemy-sprite blink (normal-ATK style) — not `wBGPalette` (whole screen),
not OBP-only; likely an OAM visibility toggle of the enemy sprite, not yet found. Deferred
(BATTLE_SKILL_SYSTEM §11.7).

## Session 51 — `make clean` violation #2 (see the CANONICAL entry above) + new hazards

1. **`make clean`: see the canonical "Never run `make clean`" entry earlier in
   this file** — S51 was the SECOND violation of that four-doc rule, and the
   session then falsely claimed the rule didn't pre-exist. Grep the docs before
   asserting what the docs say. The hazard is now structurally removed
   (Makefile fixed; gfx/README.md added; 17/18 .2bpp measured non-regenerable).
2. **Never `git checkout -- disassembly/` (or any broad path) mid-session.** It
   restores EVERYTHING under the path, silently reverting the session's
   uncommitted label/comment work (it undid the S51 rename once). Recover
   single files surgically (`git show HEAD:path > path`) and re-apply edits, or
   check `git status` first and checkout only the files you mean.
3. **Probe-build re-section works and is now a reusable pattern** —
   `tools/resection_skill_tables.py` (after `resection_library_tables.py`):
   zero-size `Lprobe_N:` labels before every code line, one build, read real
   line addresses from `game.sym`. Two traps it now handles: (a) a pre-existing
   bare `Label:` line above the splice must be absorbed or you emit a duplicate
   label; (b) fake-decode artifact labels inside the region that are referenced
   by OTHER fake-decoded regions must be kept at their exact byte offsets
   (splitting a `db` row), not deleted — bank `$06` had two (`DispMapS_566b`,
   `label6_6034`). An "entry-point-looking" name inside a proven data table is
   not evidence of code: check what the referencing site actually is.

## Session 52 (Stage 2) Lessons — evolve chain, three forks, and the blink hunt

**1. Verify the RENDER LAYER before designing a visual effect.** Three blink fixes in a row
targeted layers the battle enemy doesn't use (OBP0/1 — it isn't OBJ; whole-BGP — that's the
PLAYER-hit flash; `$ffc3` — that's the PLAYER-hit shake). One static check would have
prevented all three: `LoadBtl_7627` writes the enemy to the BG map. When an effect "does
nothing", suspect the layer, not the values.

**2. SameBoy `watch $a-$b` is SUBTRACTION, not a range.** `watch $c000-$c03f` silently set
one watchpoint at `$ffc1` (= $c000-$c03f as arithmetic). Give users single-address watch
lists. Also: buffers rewritten every frame (shadow OAM) are unusable watch targets — anchor
on a value that changes once (e.g. enemy HP `$dbab`) or a stable VRAM cell (the `$9929`
tilemap watch cracked the blink in one run: value alternates `$14`⇄`$e0`, backtrace names
the writer).

**3. rgbasm reports section overflow at the FIRST excess byte** ("reached 0x4001"), not the
total. Don't "fix one byte" and rebuild — count the bytes you appended.

**4. Loop-bound splices extend vanilla scanners cheaply.** The natural-learn loop's
`ld a,c / cp $da` (3 bytes) → `call LearnLoopFork` lets the SAME loop walk a custom table —
no engine duplication, vanilla semantics (incl. the code-1 UPGRADE/replace path) for free.
Pattern generalizes: any `cp BOUND / jp nz,LOOP` is a fork point.

**5. "256-wide" tables may physically END early.** The announce table's byte for id `$E2`
is the first OPCODE of `Jump_058_58e8`. Editing "the table" would corrupt code — check
what the bytes AT your target index actually are before writing (a lookup fork is the fix).

**6. `ld hl,$0bXX` constants can be mgbdis-mislabeled as ROM0 labels.** `$0b03` (a text
(mode,idx) pair) rendered as `ld hl, DispatchAboveE2`. When a "label load" makes no sense
as an address, decode it as data.

## Session 53 Lessons — project compiler (headless editor backend)

Full reference: PROJECT_COMPILER.md (schema, pipeline, regions, pinning).

### The room-entry script has TWO trigger paths with DIFFERENT map-type sources
**Symptom (resolves the S11 mystery)**: the room-entry script (index 0) "runs on
scroll and post-battle reload but not dependably at initial room entry" — S11
recorded the behavior; the mechanism was never traced.
**Root cause (grep-verified S53, engine untouched)**: two independent trigger
sites set `wScriptMapType` differently. The scroll/reload path (bank `$06`
`$66e3`) stores **raw `wMapID`** → dispatch ≥`$40` → `GateAwareDispatch` →
`CustomScriptRead` — this is what reaches bank-`$60` scripts. The initial-entry
path (bank `$01` `$4C3E`) stores **`call MapIDClampForPalette`**, which post-S42
returns `$00` for ALL custom rooms → bank `$0C` → **Castle's script 0** runs at
initial entry of every custom room (benign: its actions are flag/var-guarded).
The inline comment "`$16` for custom rooms" at that site is stale (pre-S42).
**Rule**: "script 0 timing is unreliable" is really "two paths, two map-type
sources". Anything that must run at initial entry cannot live in the custom
room-entry script; per-step ASM (the S11 pattern) remains the correct home.
When a clamp helper changes (S42 made it uniform `$00`), re-audit every CALLER
for semantic drift — the comment at a call site is not the behavior.

### A latent table overshoot only surfaces when data becomes code-generated
**Symptom**: `CustomScriptMasterTable` had 3 entries; rooms extend to index 5
(`$70`). On the scroll path a high room indexes past the table into following
data and executes a garbage "script". Never fired in play ONLY because `$6E/$6F`
are unreachable and `$70` is single-screen (cannot scroll).
**Fix (compiler, built S53, NOT yet user-tested)**: default emit = full-width
master table + shared `CustomScriptNoop_PtrTable → dw $FFFF` (+10 bytes);
`build.compat.master_table_rooms` reproduces the legacy narrow bytes for the
byte-identity regression and WARNS at compile time.
**Rule**: when acceptance is byte-identity to a proven artifact, inherited
defects must be reproduced — make each one an EXPLICIT, warned compat switch,
ship the fix as the default, and prove the fix build's delta is exactly the
intended bytes (here: bank `$60` `$4010–$45B8` + header checksums, nothing
else). "Byte-identical" and "fixed" are two builds, not one argument.

### Verify opcode param counts against the HANDLER, even when a tool asserts them
**Symptom**: `tools/compile_script.py` declares `set_bgm` (`$41`) with 2 params;
the proven hand-authored script passes ONE and works.
**Root cause**: the handler (`$04:$669D`) advances the script counter once and
consumes one word (`ld a, c / call SetBGM`). The tool's table is wrong — the
same failure class as the wrong comments of S2/S3 (`$E7`, `$04`, `$0E`), now in
a TOOL's data table, which reads as more authoritative than a comment.
**Rule**: a tool's opcode table is a claim, not a verification. Before encoding
an opcode in a new emitter, read the handler (the bank_004 per-opcode reference
block + code). Log tool-table defects where the next session will look
(TOOLS_AND_DATA row + owning doc) instead of silently diverging — and don't
"fix" the tool without re-testing its decompiler twin's round-trip.

## Session 54 Lessons — WRAM collision root cause (egg-give room corruption)

### "No literal refs" is NOT "unclaimed WRAM" — indexed arrays are invisible to grep
**Symptom**: `$FF29` (AddMonster) egg give in custom room `$6B` → bottom exit
dead + crash on scroll-up. Pre-existing across builds; only on a full save.
**Root cause**: the party/storage monster array is accessed EXCLUSIVELY through
`GetMonsterDataPtr` (`HL = field + slot×$95`, 20 slots) so it spans
**`$CAC1-$D664` with zero literal `$D3xx/$D4xx` refs**. The Phase-0 grep audit
therefore declared `$D378-$D477` "unclaimed", and ALL custom WRAM was placed
inside monster slots 14-16. The give writes a 149-byte record into the first
empty slot: for slot 16 that lands SkyDragon's 27 resistance bytes on
`$D479-$D493` = the live step counters + `wRoomRecScratch` → garbage step-entry
pointer (dead exit) + garbage tileset/collision record read on the next screen
load (crash). Party+farm+eggs share the one 20-slot limit (user-confirmed), so
"how full is the save" is the trigger variable — which is why it "used to work"
on early saves and why party size changes don't help.
**The reverse direction is the silent killer**: `CopyCustomRoomRecord` rewrites
`wRoomRecScratch` on EVERY room transition (since S42), and custom-room
NPC/exit buffer copies spray `$D379-$D477` — stored monsters #15-17 get
corrupted by NORMAL PLAY, and saving persists it.
**This is the THIRD instance of the class**: `$D95E` (MedalMan collision) and
`$D9A0-$D9A2` (inside `wEventFlags`) were the first two — both "fixed" by
moving to `$D478+`, i.e. deeper into the same unaudited hole.
**Rule**: never claim WRAM is free from literal-grep evidence. Free-space
claims need POSITIVE evidence covering all three access classes: literal refs,
indexed arrays (base + index×stride helpers like `GetMonsterDataPtr` /
`Mul8x8To16` users), and pointer-walked buffers (literal base + loop, e.g.
library seen-bits `$CA94-$CAB1` scanned to bit `$EF`). `tools/audit_wram.py`
now encodes this; its gaps are reported as "UNVETTED", never "free", and its
`--selftest` pins the detection of this exact collision.

### A "mixed up the gates" report can hide a refutable suspect — kill suspects statically before designing probes
The S53 anomaly (a) ("Pillar B $6D absent in Gate of Villager") dissolved as a
user misread, but its recorded suspect ("story-step-dependent hub exit data")
was ALSO statically false: room `$24`'s four step variants carry byte-identical
exits (pedestal (2,2) → dest 1 / gate_flag 1 in every step; steps only toggle
the sprite-77 pedestal objects). Ten minutes of `map_table.json` reading
removed both a phantom bug and a phantom mechanism.
**Rule**: before handing the user a runtime probe, spend the grep/extract pass
that could make the probe unnecessary — and when an anomaly is closed as
user-error, still check whether its written-down suspect would have survived;
delete it from the docs if not, or it will be chased again.

### Per-frame-refreshed state masks its own corruption — probe the non-refreshed neighbors
**Symptom (S54 probe)**: after the corrupting give, `wRoomRecScratch` read back
byte-identical to its pre-give value, which could be misread as "the scratch
was never hit". It WAS hit — the ROM0 collision-threshold reader re-populates
it via bank $71 entry 0 on essentially every movement frame, so any corruption
self-heals before a human can `examine` it. The step counters have no
refresher and held the garbage (`$D478=$c8`, `$D479=$22`), which is why they —
not the scratch — are the persistent crash vector. Same pattern: the
NPC/exit buffers self-heal per read (re-copied by every
CustomReadInteract/CustomExitCheck call), so a slot-14/15 give is transient
while a slot-16 give is persistent.
**Rule**: when probing for memory corruption, know each variable's refresh
cadence first; an unchanged read of frequently-rewritten state proves nothing.
Probe the neighbors that nothing rewrites. And when relocating such state,
verify the NEW addresses for both the refreshed and non-refreshed vars — the
self-heal will hide a botched move of the refreshed ones.

## Session 55 Lessons — WRAM relocation vetting (why the gap list lied)

### A "gap" below a decompression destination is the buffer, not free space
**Symptom**: audit_wram's two largest relocation candidates ($C20D-$C2C2 182 B,
$C42B-$C4C3 153 B) had zero real literal refs and looked placeable.
**Root cause**: both sit inside STAGING BUFFERS whose writes are invisible to
literal-ref scanning: $C200 is the attr decompression destination (the stream
HEADER declares the write length — every attr stream in the ROM declares 256),
and $C300-$C4FF is a 512-byte screen staging unit (proven by a bank $06 bulk
copy `$C500→$C300 ×$0200`, and by the save routine copying both blocks to SRAM
whole). Ten more "gaps" sat inside the $C500 battle tile buffer the tool's
curated list lacked.
**Fix**: curated arrays added (attr staging, screen staging ×$200, battle tile
buffer, audio channels, battle stat tables); wram_usage.json regenerated
(51→34 gaps).
**Rule**: before trusting any WRAM gap, find the nearest decompression/copy
DESTINATION below it and bound that buffer from its own evidence (declared
declen in the stream header, bulk-copy length, save-block length). A gap's
edges as drawn by junk literals mean nothing.

### Read the loop bound, not the doc label — the "battle struct array" was the audio engine
**Symptom**: known_RAM_map called $DD80-$DE4F an "(INFERRED) per-combatant
battle struct array, ~8 slots", making all of $DExx battle territory.
**Root cause**: the inference came from observed stride-26 bases. The actual
init loop (`ClearAudioChannels`, bank $00) reads `ld hl,$dd80 / ld b,$06` —
SIX channels × 26 B = $DD80-$DE1B, with audio scalars enumerating to $DE2B.
It's the sound engine. (S45's "battle corruption" when poking $DDF0/$DDFE was
audio channel bytes.)
**Rule**: when an array's extent matters, find its INIT/CLEAR loop and read
the bound register — a `ld b,$06` beats any inferred "~8 slots". Corollary
proven same session: the sleep pool's extent came free from SRAM save-map
arithmetic ($BCC8−$B124 = $BA4 = exactly 20×$95).

### Big feature ≠ big WRAM — measure exclusivity before proposing a sacrifice
**Symptom**: debug mode (a whole wGameMode dispatch family: banks $55/$56/$59)
looked like a sacrificial WRAM donor for the romhack.
**Root cause**: debug menus DRIVE the real engine (real anim vars, real audio,
real game state) and borrow shared menu scratch. A full cross-bank exclusivity
scan found ~10 exclusive bytes.
**Rule**: to cost a feature-sacrifice, compute the set of addresses referenced
ONLY by that feature's banks — in a codebase this shared, expect near-zero.
The scarce resource is runtime-mutable memory, and vanilla already shares it
aggressively; the real donors are ARRAYS with negotiable bounds (monster
slots, counter pools), not features.


### Vetted-unclaimed is NOT initialized — relocation must audit init AND restore paths
**Symptom (S55, user hardware test)**: after relocating custom state
$D478->$DE74, hard crash ON ENTRY to room $6B (previously the crash was on a
give); and loading a save made inside the room crashed on the first scroll.
**Root cause**: the vetting proved nobody CLAIMS $DE74-$DEDD — which also
means nobody INITIALIZES it. The old location was defined entirely by
accident of address: inside the boot clear (ClearAllWRAM zeroes only
$C000-$DDFF — it stops short of the stack zone) AND inside the SRAM save
image ($C8EA-$D9E9, so new-game init zeroed it and load restored it). The new
location had neither: SameBoy/hardware randomize WRAM at power-on -> garbage
step counter -> garbage step-entry pointer -> entry crash (the S53 crash
mechanism, resurrected by the fix that was supposed to bury it). And
wCustomRoomFlag, silently load-bearing on save-image restoration, read $00
after loading in-room -> bank $0B readers took the vanilla path for a custom
mapID -> garbage walk on scroll.
**Fix**: ClearAllWRAM $1E00->$1EE0 (same-size operand edit; single call site,
early boot); flag DERIVED from wMapID every movement frame at
CopyCustomRoomRecord head (template re-pinned per PROJECT_COMPILER §5,
TEMPLATE_SIZE 0x71: 103->116). Counters after load-in-room legitimately read
step 0 (transient semantics, documented).
**Rule**: when moving ANY WRAM, audit three things, not one: (1) who claims
the destination, (2) who INITIALIZES the source region today (boot clears,
save-image init, implicit zeroing) and whether the destination inherits any
of it, (3) who RESTORES the source on load and what breaks when restoration
stops. A variable can be load-bearing through pure address accident.

### One variable per test ROM
**Symptom (S55)**: the first S55 test ROM shipped the relocation ON TOP OF
the S53 master-table fix — which itself had never been user-tested (the S53
user loop ran the compat config). Two untested changes, one crash report.
**Rule**: a test ROM tests ONE change against the last USER-TESTED
configuration. Check PROJECT_STATE for which config the user actually ran —
"built SN, NOT yet user-tested" in the docs means it does not count as a
baseline. Deliver the isolating build first; stack configs only after each
passes alone.

## Session 56 Lessons — CF1 boundary RE (the access map)

### Never record a count without its method — "44 walkers" cost an hour to re-derive
**Symptom**: S55 recorded "44 read-walkers" as the size of the proxy problem;
no list, no method. S56 had to reverse the number before it could do the
actual work (it is the count of `ld [$cac0], a` sites — the slot-select
writer sites, one per access path).
**Rule**: any quantified claim in the docs carries its generator: the grep
pattern, the tool, or the enumeration itself. A bare count is a puzzle for
the next session, not a fact.

### Classify the selection funnel, not the readers
**Symptom**: 326 GetMonsterDataPtr call sites looked like the classification
universe. Nearly all take their slot from `[$CAC0]`; classifying the 44
writer sites (+ the register/stride loops that bypass $CAC0) classified
everything in one pass.
**Rule**: for base+index×stride structures, find where the INDEX is chosen
before enumerating where the pointer is used. The writers of the index
variable are the access map; the readers are fan-out.

### An index helper that masks its argument defines a LARGER address space than the array
**Symptom**: GetMonsterDataPtr does `and $7F` — indices $14/$15 are valid and
vanilla USES them ($D665/$D6FA staging pseudo-slots for breeding parents,
trade transit, menu scratch). known_RAM_map's "20 slots, end $D664" was true
for the logical array and still hid 298 live bytes from the audit.
**Rule**: when documenting an indexed structure, state the ADDRESSABLE
extent implied by the helper's mask/bounds, then enumerate which indices are
actually used and by whom. audit_wram now carries the staging slots as their
own curated entry ($D665-$D78E pinned in its selftest).

## Session 57 Lessons — CF2 (pending farm exp + drain)

### "Safe flag ranges" from script analysis alone are NOT safe — audit engine literals too
**Symptom**: CF2 needed 3 persistent bytes; EVENT_FLAGS' "broader safe ranges"
offered $01E0-$023F, and the first pick ($D9E0-$D9E2, flags $0228-$023F)
looked ideal — until a routine literal-grep found live engine refs in banks
$01/$04/$12, and all_scripts.json showed $D9E0/$D9E2 script-referenced. The
compiler's `FLAG_SAFE_RANGES` carried the same lie, so the flag ALLOCATOR
could have written onto live engine variables the first time a project
declared enough flags.
**Root cause**: the flag analysis enumerated flags used BY SCRIPTS (via the
flag opcodes) and WriteRAM collisions; it never checked whether the engine
names the underlying BYTES directly. Same failure class as the S54 "no
literal refs ≠ unclaimed", inverted: here the claim was derived from one
access class (script flag ops) while another (engine literals) was live.
**Fix**: per-byte audit of every byte in every claimed range (engine literal
grep across disassembly/ + patches/, plus all_scripts.json full-text). Truly
clean: $D9C6-$D9C7 + $D9D7-$D9D8 (+$D9C8-$D9CA, taken by wPendingFarmExp).
EVENT_FLAGS rewritten in place; FLAG_SAFE_RANGES corrected; DOC_AUDIT row.
**Rule**: a WRAM byte is only allocatable when EVERY access class is clean:
literal refs (disassembly AND patches), script references (all_scripts.json),
indexed-array coverage, and pointer-walked buffers. A "safe range" claim in a
doc names its evidence classes or it is a hypothesis.

### Persistence requirements come from the GAME's save model, not the variable's lifetime
**Symptom**: the obvious home for a "transient" accumulator was the vetted
$DE89+ block (outside the save image) — pending exp only lives between a
battle and the next town visit, so transient "felt" right.
**Root cause**: DWM1 allows saving INSIDE gates (small save rooms — FAQ
line ~560), so "between battle and town" can span a save+reload. A transient
accumulator silently loses a run's farm exp on every in-gate save+reload.
**Fix**: put the accumulator INSIDE the save image ($D9C8-$D9CA) — save/load
then carries it for free, no extra hooks, and pre-CF2 saves migrate as 0
(bytes were never written). The alternative (drain-before-save hook) costs a
second engine hook and still misses force-save paths.
**Rule**: before classifying custom state transient vs persistent, enumerate
the save points the PLAYER can reach while the state is nonzero (the FAQ is
the fastest source). If any exist, the state goes in the save image or every
save site needs a hook.

### Zero the INPUT of a vanilla loop instead of patching the loop
**Technique (CF2's core trick)**: the exp walker reads the farm share from
HRAM $DB-$DD, computed once at the walker head. Zeroing that input (and
banking the real value elsewhere) made the walker's farm branch AND the
downstream all-20 level scan farm-inert with ZERO edits to either loop —
one same-size 14-byte window instead of surgery on branch logic, and party
behavior stays byte-identical by construction.
**Rule**: when a vanilla loop must stop affecting a subset, look for a
loop-invariant input that is zero-neutral for that subset (share=0 → adds 0 →
downstream scans see no change). Patching the head beats patching the body.

## Session 58 Lessons — CF3 party-first sort (v1 defect + phantom investigation)

### A doc's description of a WRAM cell is its role in ONE flow, not its contract
**Symptom (S58 v1)**: the sort exchange-fixed `$CA40` across record swaps,
justified by MONSTER_DATA's (accurate) S56 note "`$CA40` = offspring
first-empty slot persist". Reading the farm UI during the phantom-monster
investigation showed `$CA40` is ALSO the drop/pick flow's live candidate
register (written per selection at `$0A:~$5CC4` with `$CAC0`/`$C908`;
consumed by `SetFldA_6ad5` + the direct-pick list append) — so the fixup
rewrote UI state behind the flow's back, feeding paths that force-mark
in-use flags with NO validity guard.
**Rule**: before writing to any engine WRAM cell from custom code, enumerate
ALL its writers and readers (grep, not docs) — a doc names the roles a past
session needed, not the cell's full contract. Selection registers
(`$CAC0`, `$CA40`, `$C908`, cursor caches) are written fresh by each flow
and must never be "helpfully" remapped.

### Straight-line audits cannot clear state machines
**Symptom (S58)**: "no caller consumes the `$C0D8` map after canonicalize"
was concluded from a 20-line scan below each call site. Menu state machines
resume in a LATER FRAME, far beyond any static window — the farm UI reads
`$C0D8` display lists across canonicalize boundaries as a matter of course
(vanilla survives because it rebuilds and because vanilla's leftover map is
self-consistent where the sort's is stale-by-one-permutation).
**Rule**: an "unconsumed after X" claim needs the consumer TYPE stated:
straight-line callers (static scan suffices) vs state machines / interrupt
readers (need flow tracing or a runtime watchpoint). Say which one was
checked.

### Unreproducible corruption: date the fossils before hunting the ghost
**Symptom (S58)**: phantom farm monsters (garbage species, 0 HP/MP, paired
junk names, level 1→cap spread) first appeared only in an old save; every
clean-save reproduction attempt failed — until the user found the trigger
(enter/exit a custom room), and the byte trace closed it: the NPC/exit
buffer copies spray monster slot 15/16 IN-USE FLAG bytes ($D37C = NPC
buffer byte 3, $D411 = exit buffer byte 24 — a documented-but-incomplete
S55 hazard: the <=14 rule protects occupied slots, not empty ones), and the
next canonicalize mints the spray into real farm records. CF2's drain then
leveled the old save's fossils into that 1→cap spread (0 HP because
level-ups don't heal). The NEW patch (the sort) was blamed first and was
innocent.
**Rule**: when corruption appears only in an old save, the first split is
Test 0 = same save on the PREVIOUS build, and the first suspects are prior
bug classes archived in the docs — not the newest patch. Keep the corrupt
save as evidence; record hypotheses as hypotheses until a repro + byte
trace closes them — a user-found reproduction beats any amount of static
theorizing.

## Session 59 Lessons — Phase 0 close-out (verifier check 5; skills.json retired)

### A table with no terminator is bounded by the next thing in the bank — read that, not a round number

**Symptom**: `extracted/skills.json` carried 34 junk records (ids 222–255):
blank names, "handler addresses" like `$FFCD` / `$CD5B` / `$E7CD`. Three
generators consumed the file and emitted them as table entries with blank
comments.

**Root cause**: `dump_skills.py` read the skill function table as **256**
entries because 256 is the size of a byte's id space — a plausible round
number, never verified. The table is **222** entries (ids `$00..$DD`,
`$52:$4011..$41CC`, 444 B). It has no terminator; its bound is simply where
the next thing starts — `SkillBlaze` @ `$52:$41CD`. The 34 phantom entries
were 68 bytes of that handler's CODE decoded as little-endian pointers. The
tell was in the data all along: `$CD` is the `call` opcode, so `call $5BFF`
(`CD FF 5B`) surfaces as the "pointer" `$FFCD`.

**Fix**: ported the three real readers to `skill_records.json` (which stops
correctly at 221), fixed `gen_skill_table_db.py` to emit 222, deleted
`skills.json`, and made `dump_skills.py` an inert tombstone that exits
non-zero rather than silently recreating the retired file.

**Rule**: when a table's length is a suspiciously round number (256, 128,
100), treat it as unverified until you find the byte that ends the table.
For an unterminated table that means locating the next label/handler and
proving adjacency — `table_start + n*stride == next_symbol` is the proof.
Corollary: garbage decodes are evidence, not noise. Pointer values dense in
`$CD`/`$C9`/`$21` are opcodes wearing a pointer's clothes, and they tell you
you have run off the end.

### The doc naming a stale dependency can be the one that is stale

**Symptom**: ROADMAP and PROJECT_STATE both said `skills.json` was "still read
by `gen_name_tables_db.py`" — the item's entire scope.

**Root cause**: exactly backwards. `gen_name_tables_db.py` declared
`SKILLS_PATH` and **never opened it** (a dead constant, one occurrence). The
three tools that *did* read it — `gen_skill_table_db.py`,
`gen_enemy_stats_db.py`, `gen_monster_db.py` — went unmentioned in both docs.
A one-line grep for the *reads* rather than the *name* would have caught it at
any point. The same row also miscounted the junk entries as 33 (it is 34:
256 − 222).

**Rule**: a roadmap item's stated scope is a claim like any other — grep it
before costing the work. Verify a dependency by its **use** (`open(`, the
call site), never by the presence of a path constant or an import; declaring
a path is not reading a file. Rule of thumb: if a doc names exactly one
consumer, count them yourself — the count is cheap and the doc's is stale.


## S60 — CF3: dispatcher contracts, split-tier persistence, and the vanilla oracle

**`rst $10` clobbers BC — validate dispatcher contracts by execution, not by
reading.** The cross-bank dispatcher preserves DE only; its `RST_20` tail
(`ld bc,$4001`) destroys BC, and A/HL/flags go with it. Forty-eight walker
patches initially assumed BC survived; every live loop counter died. The
interpreter battery caught it pre-ship because it EXECUTED the emitted bytes.
**Rule**: a helper's register contract is a claim about machine behavior —
prove it by running the real bytes (a 200-line interpreter suffices), not by
reading the helper's happy path. Corollary: `ld hl,$NNNN` costs 3 bytes where
`ld h,$NN / ld l,$NN` costs 4 — the freed byte funded the `push bc/pop bc`
everywhere.

**Split-tier storage must have a uniform persistence policy.** Moving the
farm to live SRAM while the party stayed save-time-lazy WRAM worked until an
operation SWAPPED records across the boundary: the SRAM half committed
instantly, the WRAM half waited for a save, and reload-without-save
duplicated one record and destroyed the other. The fix made the whole roster
one tier (eager: checksum exclusion + canonicalize-time mirror). **Rule**:
when state spans storage tiers with different commit semantics, any operation
that MOVES data across the boundary is a distributed transaction — either
make the tiers' policies uniform for that data, or never let records cross.

**Differential simulation against the vanilla oracle ends speculation.**
Three sessions of hypothesis-grinding about the sleep flow's semantics were
settled in minutes by loading the ORIGINAL ROM into the interpreter next to
the patched one, feeding both identical synthetic states, and diffing
outcomes. The oracle also decoded the flag convention ($02=party-protected)
that no amount of code-reading had pinned down. **Rule**: when a mod must
preserve behavior, the original binary is an executable specification — diff
against it instead of arguing with yourself. And when synthetic states all
pass but the field bug persists, STOP GUESSING STATES and get the user's real
save file; two fingerprints from it (checksum format, record hashes) solved
what a day of simulation could not.

**A save's checksum format fingerprints the build that wrote it.** The
"third field bug" dissolved when the user's saves showed v1-formula stored
checksums — proof they were running the recalled first build, since v2 stamps
its own formula on every save. **Rule**: give every save-format revision a
distinguishable stored signature; it turns "which binary touched this file?"
from an interrogation into an arithmetic check.

**Save states do not survive storage-architecture migrations.** An emulator
state snapshots WRAM+SRAM atomically UNDER ONE BUILD'S LAYOUT. Loading a
pre-migration state under the post-migration build splices two timelines
(state WRAM has the old layout; new code reads the moved region from the
state's older SRAM) — no code can reconcile it, and the symptom masquerades
perfectly as data corruption. **Rule**: when a mod moves persistent state
between memory tiers, declare old save STATES (not saves — those migrate)
invalid across the boundary, loudly, in the hand-off notes.

## S62 — M2 codec + DWM2 port: grammar from instructions, translation with proof

### Data-pattern grammar is a hypothesis; the handler's instructions are the grammar
S61 inferred a standalone 3-byte `$FC lo hi` jump token from stream data. It
doesn't exist: `AudioCheckFC` inspects the **Bn pair's own param byte**, and
`$FC` there makes the *next pair* a jump target — 4 bytes, pair-aligned, no
odd-length token anywhere. The mislabel survived a whole session because the
byte-accounting happened to align either way. A byte-identical round-trip
selftest catches *carriage* errors but not *labeling* errors; only reading
the dispatch instruction-by-instruction nailed the real shapes. **Rule: for
any interpreter, grammar claims cite the handler's instructions, not
patterns in the data it consumes.**

### "Same engine family" ≠ "same language" — translate with an equivalence proof, don't feed raw
DWM2's driver shares DWM1's pitch table, fetch model, and header fields — and
still broke playback three separate ways when its bytes were fed raw: a
call/return pair (`$AC`/`$AD`) whose phrases live PAST the `$FF` terminator
(naive extraction truncates them), per-slot mark loops that collapse onto
DWM1's single mark, and a DWM1 elapse path that eats the pair after any
foreign-param loop. The fix that worked: a **translation layer to
DWM1-native constructs** plus a **static trace-equivalence prover** — execute
the original bytes under source-driver semantics and the translated bytes
under target-driver semantics, require identical event traces before
shipping. The prover caught nothing on the final build *because* the
translator was built against RE'd handler semantics; its value is that "it
sounds right" stopped being the only evidence. **Rule: porting data between
engine dialects gets a translator + machine-checked equivalence, never
"unknown commands are probably no-ops."**

### A script in a table is not a feature until an entity is wired to it
S61's docs said a custom-room NPC "currently sets BGM $1E". The script
existed in the script-pointer table; **no NPC record referenced it**, so it
was unreachable dead data — found only when the user reported no such NPC
in-game. Placement lives in a different structure (screen NPC records) than
behavior (script table); documenting the second without grepping the first
asserted an in-game behavior that had never existed. **Rule: any "X happens
in-game" doc claim needs the full wiring chain verified — script AND the
entity/trigger that invokes it — or it's marked as unwired.**

## S63 — M3a: the ROM0 space was hiding in our own patches

### "No free space" audits must re-audit the CLAIMED space — duplicates and dead code are free bytes
**Symptom**: M3a was blocked on "ROM0 has NO 17-byte free run" (S62 audit,
correct on its own terms: every vanilla filler run was already patch-claimed
or live data). The extended master table looked homeless; the first design
(WRAM-resident table + boot-path rewrite) was invasive and spent the
custom-room WRAM reserve — the user rejected it.
**Root cause**: the audit counted *unclaimed* bytes only. Auditing the
*claims* found 17 bytes inside them: `MapIDClampForDispatch` and
`MapIDClampForPalette` were byte-identical 8-byte twins authored in
different sessions (merge → 8 bytes), and `CustomGFXMapID` had been dead
since S42 (bank $71 Entry 0 replaced all consumers — its own header still
said "used by"; 9 bytes).
**Fix**: merge the twins (one body, both exported labels — every `call`
site relinks automatically), delete the dead function, host
`AudioMasterTableExt` in the freed 24-byte $3FE8 slot; one 2-byte operand
repoint in `AudioProcess`. Zero WRAM, zero boot changes, zero net ROM0
bytes.
**Rule**: when a free-space audit comes up empty, audit the existing claims
next: grep every patch-owned ROM0 symbol for (a) zero remaining call sites
and (b) byte-identical siblings. In a multi-session codebase both
accumulate silently, and they are the cheapest bytes available.

### A hand edit to a compiler-owned file is invisible until something rebuilds from source
**Symptom**: S63 ran `test_compiler.py --rom` (mandatory: the session
changed patches) and the regression failed BEFORE any S63 change was
relevant — the committed S62 tree already failed it.
**Root cause**: S62 hand-edited compiler-owned `bank_060.asm` (BGM NPC +
`SetBGM $9E` + text) without updating the example project or the pin — the
exact hazard PROJECT_COMPILER warns about. CI runs only
`verify_integrity.py`, which assembles the hand files and stays green; only
a from-source compile exposes the divergence.
**Fix**: S62's content ported into `project.json` (three edits: NPC record,
`set_bgm 0x9E`, dialogue line); compat build == hand-staged tree again
(`c23beed7…`); pin re-pinned with the S60→S63 lineage in its comment.
**Rule**: any session that touches a compiler-owned bank runs
`test_compiler.py --rom` at wrap-up even if it "only" hand-verified the
ASM — and CI should run it too (ROADMAP box added S63) so the next
violation fails in public, not two sessions later.

### The tick model was inferred from a control byte, not the countdown — note lengths are FRAMES
**Context (S64)**: SOUND_SYSTEM (S61) said `$A3` sets "frames per tick" and
note lengths are "in ticks" — an inference from the `$A3` handler alone
(`(xx&$0F)*2 → $FA/$FB`). Building the MIDI converter forced the question:
what does `$FB` actually gate?
**Finding**: reading the per-frame driver's countdown (bank_000 ~11110):
BOTH branches of the `$FB` check fall into `dec [hl]` on `$FFEC` — the note
length decrements unconditionally EVERY FRAME; `$FB` only gates the groove
stepper (`AudioProcessChannel` early-`ret`, groove table $3B83). Lengths
are frames (~59.73/s). Duration cross-check: the 0:01 jingles are ~1 s at
frame semantics, ~12 s at tick semantics. Bonus finding: every groove row
is a live vibrato/detune shape (no all-zero row), so `$A3 $80` (bit7=1 →
`$E5 &= $0F`, groove OFF) is the only deterministic straight form.
**Rule**: a control register's WRITER tells you what a value is; only the
READER tells you what it does. Verify the consuming loop before building
timing math on a doc's model — the S61 reading survived two sessions
because byte carriage never depends on semantics.

### Same-size rewrites can be self-funding: audit the function's own fat before hunting free space
**Context (S64)**: the room-BGM hook needed 7 bytes inside a 70-byte
function in dense bank $01 with its padding already consumed (S63).
**Technique**: the function itself paid: a vestigial `ld b,[hl] / ld a,b /
cp $09 / ret nz / ret` tail whose flags the single caller immediately
overwrites (`cp b` before acting) collapses to `ld a,[hl] / ret` (−4); a
second `ld a,[wMapID]` was redundant because A survives a pure `cp` chain
(−3); `ld a,$00 / adc h` → `adc h / sub l` at two table lookups (−2).
Net −9 funded the 7-byte `rst $10` prologue with 2 bytes to pad.
**Rule**: before declaring "no room", disassemble the exact footprint being
replaced: vestigial compare-tails (flags nobody reads), redundant reloads
across flag-only instructions, and the `adc h / sub l` idiom are recurring
free bytes inside vanilla functions — and a same-size rewrite keeps every
address stable, which is the whole game in banks $01/$04/$17.

## S65 — WRAM migration: freed ≠ persistent, and $CD mints phantom operands

### A decision doc and the shipped architecture can silently diverge — re-verify DECISIONS, not just facts, before building on them
**Symptom**: the S58 layout rule said the CF3-freed window's save semantics =
"EXPLOIT the vanilla block copy" (persistent), and planned the bulk as the
editor's persistent-state pool. S65 started from that plan.
**Root cause**: S60's v2 architecture put the LIVE farm at exactly the
window's save-image address ($A3BA-$AD9E) and therefore skips the window in
BOTH copy directions (bank $73 entries 5/6) — the EXPLOIT trick is not
"unimplemented", it is UNIMPLEMENTABLE without evicting the farm. No doc
recorded the refutation; the S58 decision text stood for five sessions after
the build had foreclosed it.
**Fix**: window documented TRANSIENT-permanently everywhere it's described;
persistent state = flags + entry scripts now, SRAM expansion later (E3);
refutation annotated at the S58 decision text itself (ROADMAP) + DOC_AUDIT.
**Rule**: when an architecture session lands, re-read the standing DECISIONS
that touch its memory/semantics and annotate any it forecloses, at the place
the decision is written. A refuted fact gets fixed in place; a refuted
decision must be too — otherwise the next session builds on it (this one
nearly did).

### $CD is the CALL opcode — misassembled data mints fake $CDxx operand refs in dense clusters
**Symptom**: a literal-ref census of the freed window showed 136 referenced
addresses, with a dense, real-looking cluster at $CCB4-$CDFF — including
named "code" (PaletteStoreCD80) in FULLY ANNOTATED banks 000/003 — casting
doubt on the window being free at all.
**Root cause**: any data run containing $CD bytes decodes as `call $XXCD`/
`... $CDxx` when misassembled; annotated banks still contain misassembled
DATA regions (bank 000's groove/audio tables, bank 003's info sub-tables),
and auto-named labels on them look like real functions. The structural
disproof: the vanilla monster array OCCUPIED the window — a live gameplay
writer would have corrupted monsters, a live reader would have consumed
monster bytes as its input; vanilla working IS the proof no live claimant
exists. (Boot-time residue is a separate, real concern — see next lesson.)
**Rule**: inside any range a vanilla structure verifiably occupied, treat
interior literal refs as data-as-code artifacts until a coherent-code
reading proves otherwise — and expect $CDxx (and $C3xx/jp, $C9/ret-adjacent)
clusters specifically. "Fully annotated bank" does not mean "no misassembled
data"; a plausible auto-name on top of instruction soup is still soup.

### State that was masked by a restore-copy loses its initialization when the copy is skipped
**Symptom (designed-out, not debugged)**: pre-CF3, any boot-time scribble
into the window was invisible — the save-load image copy overwrote the whole
window before gameplay. The CF3 skip removed that masking: boot residue (or
a previous session-segment's live values, or another save's) would now reach
gameplay in the migrated counters — a garbage step counter indexes past the
step sub-table into a garbage step-entry pointer (the S53 crash mechanism).
**Fix**: deterministic init at every gameplay entry route — ClearAllWRAM
(power-on) + CF3NewGameClear (new game, already covered $C8EA-$D9E9) + a
NEW bank $73 entry 6 tail-clear after the main-image restore copy (gated on
its unique source end $B124; callers enumerated in the entry header).
Reload-in-room now deterministically shows step 0 (also closes the
S55-accepted cross-save staleness).
**Rule**: when a mod stops a restore path from writing a region, list what
that write was silently INITIALIZING and re-provide it explicitly. S55's
init lesson ("vetted-unclaimed is NOT initialized") has a copy-skip
corollary: skipped-on-restore is uninitialized-on-restore.

### An 8 KB cart makes every RAM-bank write a dead store — audit them before declaring SRAM expansion "free"
**Symptom**: 32 KB SRAM expansion looked header-only ($0149 $02→$03; no
physical cart constraints).
**Root cause**: vanilla writes the MBC5 RAMB register constantly — RST_18
(`rst $10` tail) sets RAMB:=rom_bank>>5 as a quadrant convention with an
HRAM shadow ($FFA3), and bank $40 carries a genuine `di`-bracketed
multi-bank 32 KB SRAM wipe — all no-ops on the 8 KB cart (only bank 0
exists), all LIVE at 32 KB. Under expansion: CF3 (bank $73) would run on
RAMB=3, and the audio ISR's bank $74 dispatch flips RAMB every vblank while
music plays, tearing any non-`di`-bracketed access.
**Fix (this session)**: expansion NOT layered in; full audit banked into
ARCHITECTURE "SRAM banking" + E3 so the implementing session lands RAMB
discipline first.
**Rule**: before widening any hardware resource a mapper masks (SRAM banks,
ROM bank high bits), census every write to its register range and classify
each as real code vs data-as-code — dead stores under the old mask are the
whole hazard, and the ISR is part of the census (a register the vblank
handler touches is not yours between di/ei).

---

## Session 66 Lessons — mapID ≥$80 audit

### mapID is unsigned EVERYWHERE — the SM83 cannot sign-test it
The SM83 has no sign flag (`jp m`/`jp p` are Z80, not GB). Every wMapID
comparison in the ROM is an unsigned `cp`, so a mapID ≥$80 takes the same
branch as $6B-$70 at every compare site. When auditing for range hazards,
look for these instead:
1. **8-bit `add a` doubling** — `add a / add l / … / adc h` loses the $100
   carry (the `add l` overwrites it before `adc h`). **RST_00 has exactly
   this shape**: every `rst $00` jump-table dispatch is $7F-capped by
   construction (RST_20 likewise caps L). Any mapID-driven `rst $00` must be
   clamped (`MapIDClampForDispatch`) or diverted first.
2. **Fixed-size tables** indexed by raw mapID.
Custom code must `sub CUSTOM_ROOM_START` BEFORE any 8-bit doubling (safe to
mapID $EA); 16-bit `sla/rl` or `add hl,hl` walks are safe to $FE.

### `bit 7` near a mapID read is usually NOT a mapID test
All census hits were on other variables (wInGateworld, $c8ea, skill id
$db8a) or on the NPC-entry TYPE byte, whose ≥$80 range is the by-design
spawn/exit discriminator ($8F/$90 — ROOM_DATA_FORMAT). Read the operand, not
the pattern.

### Exits to custom rooms must carry gate_flag=0
The gate-entry path (bank $16 label16_5b4e) copies wMapID into wGateID and
×8-indexes GateFloorDataTable with it — fine for gate ids ≤$1F, garbage for
a custom mapID. trigger_x=$FF is likewise forbidden (exit-list terminator).
Both are recommended compiler validators (ROADMAP A′1 follow-up).


## S67: Script opcode words are `op | $FF00` — byte-search accordingly
Script streams in banks $0C-$0F are WORD streams; opcode words carry $FF in
the high byte (`5A FF`, `05 FF`, `13 FF`…), params are plain words. A byte
search built from the decompiler's decimal view (`5a 00`…) finds nothing and
can "prove" a trigger doesn't exist. The Durran chain hid this way: the
decompiler also mis-types some opcodes' params (`$05`'s EID shows as
`text_or_param`, `$20` grabs the NEXT command's bytes as fake params), so
filter-by-opcode scans over all_scripts.json miss anything not in the filter
list. When a battle/effect has no visible trigger: (1) raw-scan `op|$FF`
patterns across banks $0C-$0F, (2) list ALL writers of the target RAM with a
ROM-wide `EA lo hi` scan, (3) only then conclude "engine-side".

## S67: "Zero doc hits" needs synonym greps before it justifies a session
E1 was pitched as a from-scratch RE gap ("no roster doc hits"), but the core
arena formula sat in QUEST_OPCODES under the name ArenaBattleSetup. Half the
session's value was in the OTHER half (boss triggers, coliseum RNG, victory
cascade) — but the framing was wrong and a less careful session could have
re-derived the formula at length. Grep the concept's synonyms (setup,
bracket, opponent, $-addresses you already know) across documentation/
before accepting any "not documented" premise, including the ROADMAP's own.
