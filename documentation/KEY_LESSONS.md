# Key Lessons — Cross-Bank Room Implementation

## The Debugging Timeline (19 versions)

This document records every bug encountered and the root cause. Future implementers: READ THIS FIRST. Every one of these bugs will bite you if you don't understand why.

### v1-v2: Inserting bytes into banks with raw embedded pointers
**Symptom**: New game crashes, library has inverted colors, everything broken.
**Root cause**: Banks $01 and $17 have data sections with raw `db` pointer bytes (e.g., `db $BD, $48` = pointer to $48BD). These are NOT labels. Inserting code bytes shifts data, breaking every embedded pointer. Bank $01 had 6,601 byte diffs. Bank $17 had 9,552.
**Fix**: Use same-size `ld a,[wMapID]` → `call ROM0Helper` replacements (3 bytes each). Zero data shifting.
**Rule**: NEVER insert bytes into banks without verifying all data pointers use labels. Bank $0B is safe (pinned SECTION). Banks $01, $17 are NOT.

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
