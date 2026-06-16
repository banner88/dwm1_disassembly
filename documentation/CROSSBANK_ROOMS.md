> **NOTE:** The files described here are EDITOR PATCHES, not repo changes. The repo always builds to the original MD5. The editor applies these patches at build time.

# Cross-Bank Room System — Working Implementation

## Status: PROVEN WORKING (June 2026)

Tested with single-screen room (MedalMan clone) and multi-screen room (3-screen Castle clone). Both rooms live in bank $60 with full functionality: correct graphics, palette, tile collision, NPC display, screen scrolling, entry/exit transitions.

---

## Architecture Overview

Custom rooms use mapID values ≥ $6B (`CUSTOM_ROOM_START`). Room data lives in bank $60 (or any free bank). Small intercept patches in banks $00, $01, $06, $07, $0B, and $17 detect custom mapIDs and redirect to bank $60 via `rst $10` or ROM0 helper functions.

### The Core Pattern: Same-Size `call` Replacements

The game uses `ld a, [wMapID]` (3 bytes: `FA 68 C9`) in many places to index tables by mapID. Custom mapIDs (≥ $6B) exceed these tables' bounds. The fix: replace `ld a, [wMapID]` with `call ROM0Helper` (3 bytes: `CD XX XX`) — **same size, zero data shifting**.

The ROM0 helper returns the real mapID for normal rooms, or a "source" mapID for custom rooms (e.g., $16 = MedalMan, $00 = Castle) so existing tables are indexed safely.

### Why NOT Insert Bytes

**CRITICAL LESSON**: Banks $01 and $17 contain data sections with raw embedded pointers (`db $BD, $48` = pointer to $48BD). These are NOT labels — the assembler cannot relocate them. Inserting even ONE byte into these banks shifts all data, breaking every embedded pointer. This was discovered the hard way (v1-v2 crashed everything).

Bank $0B is safe for insertions because its data section is pinned with a separate `SECTION` directive at $4B43.

---

## Files Modified

### Bank $60 — `bank_060.asm` (NEW)
Custom room overflow bank. Contains:
- **Dispatch table** at $4001 (4 entries for rst $10 calls)
- **CustomPtrChase** — shared pointer-chase mirroring SharedPtrChase in bank $0B, with per-room source mapID setup and $FFFF screen guard
- **CustomReadStep** (Entry 0) — returns DE = [step_id, tileset_bank]
- **CustomReadInteract** (Entry 1) — copies NPC data to wCustomNPCBuffer, returns HL
- **CustomExitCheck** (Entry 2) — copies exit data to wCustomExitBuffer, returns HL
- **CustomSourceMapTable** — maps custom room index → source mapID
- **Room data** — sub-tables, step entries, NPC data, exit data for each custom room

### Bank $00 — `bank_000.asm` (ROM0)
Two helper functions in 24 bytes of free space at $3FE8-$3FFF:

```
MapIDClampForDispatch ($3FE8, 8 bytes):
    Returns wMapID if < $6B, else $00 (Castle's VRAM handler)

MapIDClampForPalette ($3FF0, 15 bytes):
    Returns wMapID if < $6B
    Returns $16 (MedalMan) for mapID $6B
    Returns $00 (Castle) for mapID $6C+
```

Plus one same-size patch at the tile collision threshold lookup (~$1EBF).

### Bank $0B — `bank_00b.asm`
**Code section** (insertions safe — data section pinned at $4B43):
- **ReadStepBlock** ($4239): intercept for custom mapIDs → `rst $10` to bank $60 entry 0
- **ReadInteractPtr** ($4274): intercept → bank $60 entry 1
- **RoomEntry6_ExitChecker** ($4521): intercept → bank $60 entry 2
- **RoomEntry9_SpecialRooms**: intercept → bank $60 entry 2
- **Entry 0 tileset** ($4037): `call MapIDClampForPalette` (same-size)
- **Entry 1 tileset** ($4094): `call MapIDClampForPalette` (same-size)

**Data section** (only 3 bytes changed):
- GreatTree screen 8 Well exit redirected: dest_mt $18 → $6B, spawn coords updated

### Bank $01 — `bank_001.asm`
Four same-size `ld a,[wMapID]` → `call MapIDClampForPalette/Dispatch` replacements (12 bytes total, zero shifting):

| Address | Table | Purpose |
|---------|-------|---------|
| $6115 | VRAM dispatch ($6119, 107 entries) | Per-frame visual effects |
| $447C | NPCWalkDataTable ($4506, ×4) | NPC walk animation frames |
| $4C3E | Room entry script call | ScriptInit with mapID |
| $5E44 | $5E7D table (107 bytes) | Per-room special effects |

### Bank $17 — `bank_017.asm`
Two same-size replacements (6 bytes total):
- Palette lookup site 1 (~$402C): `call MapIDClampForPalette`
- Palette lookup site 2 (~$40A8): `call MapIDClampForPalette`

### WRAM — `wram.asm`
```
wCustomRoomFlag  EQU $D378    ; 1 byte: source mapID for current custom room
wCustomNPCBuffer EQU $D379    ; 128 bytes: NPC data copy buffer
wCustomExitBuffer EQU $D3F9   ; 127 bytes: exit data copy buffer
CUSTOM_ROOM_START EQU $6B     ; first custom mapID
```

---

## How Room Data Flows

### Entry (GreatTree → Custom Room)

1. Player walks onto exit tile (4,5) on GreatTree screen 8
2. **RoomEntry6_ExitChecker** reads exit data: dest_mt=$6B
3. Engine starts transition, writes $6B to wMapID
4. **Entry 0** fires: `call MapIDClampForPalette` returns $16 → loads MedalMan tileset GFX from $26DD[$16]
5. **ReadStepBlock** fires: intercept detects $6B → `rst $10` to bank $60 → CustomReadStep returns DE=(step_id=13, tileset_bank=$30)
6. Engine decompresses tile layout from bank $30 step 13 → $C300 buffer → VRAM
7. **Bank $17** palette: `call MapIDClampForPalette` returns $16 → loads MedalMan palette/attributes
8. **Entry 7** fires: calls ReadInteractPtr → intercept → bank $60 CustomReadInteract → copies NPC data to wCustomNPCBuffer → returns HL=wCustomNPCBuffer → engine processes NPCs normally
9. **Collision threshold**: ROM0 code calls MapIDClampForPalette → $16 → reads MedalMan's threshold from $26E3[$16] → correct walkability
10. **VRAM dispatch**: MapIDClampForDispatch returns $00 → Castle handler runs (harmless `ret`-equivalent for MedalMan rooms, but maintains needed VRAM state)
11. **Room entry script**: MapIDClampForPalette returns $16 → engine runs MedalMan's script 0 which is just `end`
12. Fade in, player can walk

### Per-Frame (During Gameplay)

- **Entry 2** (ScreenScroll): calls ReadStepBlock → bank $60 → decompresses correct tiles
- **RoomEntry6** (ExitChecker): calls bank $60 CustomExitCheck → copies exits to wCustomExitBuffer → engine checks normally
- **VRAM dispatch**: runs Castle handler (harmless)
- **Collision**: ROM0 reads correct threshold via clamped mapID

### Exit (Custom Room → GreatTree)

1. Player walks onto exit tile (3,7)
2. Exit checker matches → reads dest_mt=$01, screen=$08, spawn=(4,5)
3. Normal transition back to GreatTree
4. Screen byte $08 = $2DE7 table entry 8 (GreatTree screen 8 offset)

---

## Key Technical Lessons

### 1. rst $10 Clobbers Register A
The `rst $10` cross-bank call mechanism saves/restores the ROM bank via `push af / pop af`. The `pop af` on return overwrites A with the saved bank number, NOT the function's return value. Functions returning values in DE or HL work fine (rst $10 doesn't touch those).

**Impact**: Cannot use rst $10 to return values in A. Use ROM0 `call` helpers instead for mapID clamping.

### 2. NPC/Exit Data Contains $FF Bytes Inside Entries
NPC entries are 5 bytes, exit entries are 7 bytes. The $FF terminator is ONLY valid as the FIRST byte of an entry. Internal bytes (spawn param, script_id) can be $FF. A byte-by-byte copy loop that checks every byte for $FF terminates prematurely.

**Fix**: Copy N-byte entries at a time, only check the first byte for $FF.

### 3. Every Table Indexed by mapID Must Be Patched
Discovered incrementally across 19 ROM iterations. Missing even ONE table causes crashes, wrong graphics, broken collision, frozen movement, or palette corruption.

**Complete list of patched tables:**

| Location | Table/Lookup | Fix Applied |
|----------|-------------|-------------|
| $0B Entry 0/1 | Tileset GFX ($26DD, ×8) | call MapIDClampForPalette |
| $0B ReadStepBlock | Room data ($4B43, ×2) | rst $10 to bank $60 |
| $0B ReadInteractPtr | Room data ($4B43, ×2) | rst $10 to bank $60 |
| $0B ExitChecker | Room data ($4B43, ×2) | rst $10 to bank $60 |
| $0B SpecialRooms | Room data ($4B43, ×2) | rst $10 to bank $60 |
| $17 (2 sites) | AttrPtrTable ($476F, ×2) | call MapIDClampForPalette |
| $01 $6119 dispatch | VRAM effects (107 entries) | call MapIDClampForDispatch |
| $01 NPCWalkDataTable | NPC walk data ($4506, ×4) | call MapIDClampForPalette |
| $01 room entry script | ScriptInit with mapID | call MapIDClampForPalette |
| $01 $5E7D table | Per-room byte (107 entries) | call MapIDClampForPalette |
| ROM0 ~$1EBF | Collision threshold ($26E3, ×8) | call MapIDClampForPalette |

### 4. $FFFF Screen Guard Required for Multi-Screen Rooms
When scrolling to an unused screen slot ($FFFF in the sub-table), CustomPtrChase must detect this and return a safe DummyStepEntry instead of dereferencing $FFFF. The DummyStepEntry MUST reference valid tileset data (not bank $00 which contains RST handlers, not tile data).

### 5. Screen Byte Format in Exit Data
```
Bits 0-3: $2DE7 table index (0-15, maps to 4×4 screen grid offsets)
Bit 7:    Adds $08 to Y spawn position (for rooms with >2 screen rows)
```
Use the SAME screen byte as existing rooms that exit to the same destination. Example: WellStairway exits to GreatTree screen 8 with screen byte $08. Copy that exactly.

### 6. VRAM Dispatch Must Use Castle Handler ($00), Not RET-Only
MapIDClampForDispatch returns $00 (Castle), not a RET-only handler like $65. Castle's handler (`ld hl, $94D0; call CheckVisualEffectType; ret`) maintains VRAM state needed for correct palette rendering. Using a bare `ret` causes yellow palette corruption.

### 7. Bank $0B Code Section Is Safe for Insertions
Bank $0B has a pinned data section (`SECTION "Data", ROMX[$4B43]`). Inserting code in the code section ($4000-$4B42) shifts code addresses but NOT data. All code references use labels, so the assembler handles relocation. Currently ~59 bytes free in code section.

### 8. Per-Room Source MapID
Different custom rooms can reuse different existing rooms' tilesets/palettes/collision. The source mapID mapping is computed in ROM0's MapIDClampForPalette via conditional logic. For more rooms, extend to a ROM0 table or move lookup to bank $60 with WRAM caching (but ensure WRAM is set BEFORE the first MapIDClampForPalette call — Entry 0 runs before CustomPtrChase).

---

## Adding a New Custom Room

### Step 1: Assign mapID
Next available: $6D. Increment CUSTOM_ROOM_START range.

### Step 2: Choose source room
Pick an existing room whose tileset, palette, and collision you want to reuse. Update MapIDClampForPalette in ROM0 to return this mapID for your new custom room.

### Step 3: Add room data to bank $60

```asm
; In CustomSourceMapTable:
    db $XX                      ; new room → source mapID

; In CustomRoomPtrTable:
    dw CustomRoomN_SubTable     ; new entry

; Sub-table (8 entries for 4×2 screen grid):
CustomRoomN_SubTable:
    dw CustomRoomN_Screen0
    dw $FFFF                    ; unused screens
    ...

; Screen data:
CustomRoomN_Screen0:
    dw $D9XX                    ; unused RAM counter address
    db STEP_ID                  ; from source room's tileset bank
    db TILESET_BANK             ; from source room
    dw CustomRoomN_NPCs
    dw CustomRoomN_Exits

; NPC data (5-byte entries, $FF terminated):
CustomRoomN_NPCs:
    db $8F, $FF, X, Y, SRC_MT  ; spawn point
    db FACE, SPRITE, X, Y, $FF ; NPC (script_id=$FF = no script)
    db $FF                      ; terminator

; Exit data (7-byte entries, $FF terminated):
CustomRoomN_Exits:
    db TRIG_X, TRIG_Y, DEST_MT, GATE, SCREEN_BYTE, SPAWN_X, SPAWN_Y
    db $FF
```

### Step 4: Create entrance
Modify an existing room's exit data in bank $0B to point to your new mapID.

### Step 5: Build and test
`make` in the disassembly directory. No other changes needed — all intercept patches handle any mapID ≥ $6B automatically.

---

## Capacity

- **21 free banks** ($60-$74) before engine banks = 336 KB
- Average room data: ~625 bytes (step entries + NPCs + exits)
- One 16KB bank holds ~26 rooms
- **Total capacity: 500+ custom rooms**
- Custom rooms can exit to other custom rooms (just set dest_mt to another $6X mapID)

---

## Known Limitations

1. **4 palette groups max**: BG palette slots 4-7 are reserved by the game engine for monster display (slots 4/5/6) and menu text (slot 7). Custom rooms may use at most 4 unique palette groups (slots 0-3). All 85 original DWM1 tilesets observe this limit. The PalGrp toggle in the editor shows group assignments.
2. **Custom tilesets**: Currently reuses existing rooms' tilesets. New tile graphics require adding entries to the $26DD table and tileset banks.
3. **Step progression**: CustomPtrChase always uses step 0. Multi-step rooms (changing layout based on game progress) need step counter management.
4. **Source mapID scaling**: MapIDClampForPalette uses hardcoded conditionals for 2 rooms. For many rooms, extend to a ROM0 table or WRAM-cached lookup from bank $60.
5. **Random encounters**: Not yet implemented for custom rooms. wInGateworld=0 means the encounter system is inactive. Attack plans documented in ROADMAP.md.

---

*Verified working June 2026. 19 iterations, 11 table patches, 3 critical bug classes discovered and resolved.*
