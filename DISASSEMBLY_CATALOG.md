# DWM1 Disassembly Catalog — Complete System Reference

## Purpose
This document catalogs EVERY game system relevant to the custom hack, tracks what's understood vs unknown, and maps which systems each feature requires. This is the foundation for all modifications.

**ROM**: `DWM-original.gbc` (2MB MBC5, 128 banks, MD5 `1ca6579359f21d8e27b446f865bf6b83`)
**Disassembly**: `github.com/banner88/dwm1_disassembly` — builds byte-identical with rgbds 0.6.1

---

## 1. Memory Architecture

### ROM Banks (switchable at $4000-$7FFF)
Each bank starts with `db BANK_ID` at $4000, then a jump table at $4001 (2-byte LE pointers). Cross-bank calls use `rst $10` where H=bank, L=entry_index.

Total: 90 banks with valid jump tables, 1316 entry points.

### Key Bank Purposes

| Bank | Jump Table Entries | Primary Role |
|------|-------------------|------|
| $00 | — (ROM0, always mapped) | RST handlers, PRNG, text rendering, math, BGM |
| $01 | 14 entries | Encounters, party management, NPC text dispatch, gate data |
| $0B | 10 entries | **Room system**: loading, exits, NPCs, transitions |
| $0C-$0F | varies | Boss loading by tier |
| $13 | — | Level-up processing |
| $14 | — | Enemy stats table, boss table |
| $16 | — | Boss floor array, encounter triggering |
| $17 | — | Palette tables, room graphics support |
| $41 | — | Monster/gate/skill/item name tables |
| $50 | 10 entries | **Event system**: main state machine, story scripts |
| $51 | 16 entries | Join handler, transitions, level-up display |
| $52 | — | Post-battle transition |
| $54 | — | Join decision logic |

### WRAM Layout

| Address Range | Bank | Usage | Safe to Use? |
|---|---|---|---|
| $C000-$C0D7 | 0 (fixed) | System/UI buffers | NO — active |
| $C0D8-$C0DB | 0 | Party slot buffer | NO |
| $C800-$C8FF | 0 | Game state vars ($C8A6, $C8B5 BGM, $C8EA transition, $C8EB UI state) | NO |
| $C900-$C96F | 0 | Map state (wMapID $C968, wInGateworld $C969, transitions) | NO |
| $CA38-$CABF | 0 | Encounters, gold, items, party info | NO |
| $CAC0-$CF20 | 0 | Monster storage (monsters 1-8, 149 bytes each) | NO |
| $CF21-$CFFF | 0 | Monster storage continued (mon 8 exp at $CF21, mon 9 at $CFB6) | NO |
| $D000-$DFFF | 1-7 (switchable!) | Monster storage cont., event state, battle data | NO — BANKED! |

**CRITICAL**: $C000-$CFFF is fixed WRAM but almost entirely used by game data. $D000-$DFFF is SWITCHABLE WRAM — the game banks it during transitions, so any data placed there can disappear. There is NO safe WRAM buffer for room data.

### Empty ROM Banks (23 banks = 368KB free)
$60, $64, $67, $69-$77, $79-$7A, $7C, $7E-$7F

### Free Space in Used Banks

| Bank | Address | Flat | Bytes | Notes |
|---|---|---|---|---|
| $00 | $3FE8 | $03FE8 | 24 | Confirmed safe (FF fill at bank end) |
| $01 | $7FE0 | $07FE0 | 31 | FF fill at bank end |
| $0B | — | — | 2 | Essentially FULL |
| $51 | $7B34 | $147B34 | 1,228 | 00 fill — LARGE, investigate safety |
| $54 | $7FC0 | $153FC0 | 64 | 00 fill (24B already used by join patch) |

---

## 2. Room System (Bank $0B) — WELL UNDERSTOOD

### Entry Points (via rst $10, H=$0B)

| Entry | Address | Name | When | Reads Ptr Table? |
|---|---|---|---|---|
| 0 | $4015 | TilesetLoader | Every frame + map change | NO (uses $26DD) |
| 1 | $4088 | GraphicsLoader | Graphics refresh | NO |
| 2 | $40CE | ScreenScroll | Scroll management | NO |
| 3 | $4213 | NPCDispatch | NPC interaction setup | NO |
| 4 | $4332 | NPCMovement | NPC patrol/movement | NO |
| 5 | $43A4 | NPCRender | NPC sprite rendering | NO |
| 6 | $451D | **ExitChecker** | **EVERY STEP** | YES → exit_ptr |
| 7 | $470F | RoomInit | After transition fade | YES → interact_ptr |
| 8 | $4239 | ReadStepBlock | Step/tileset reading | YES → step_id+tileset |
| 9 | $4488 | SpecialRooms | Maze/arena handlers | YES → exit_ptr |

### The Four Pointer-Table Functions

All read from the pointer table at $4B43 with identical chase code, but extract different fields:

| Function | Address | `ld hl,$4b43` at | Skips | Returns |
|---|---|---|---|---|
| ReadStepBlock | $4239 | $4251 | 0 bytes | DE = step_id + tileset |
| ReadInteractPtr | $4274 | $4287 | 2 bytes | HL = interact_ptr |
| SpecialRoomExitRead | ~$44A7 | $44B4 | 4 bytes | HL = exit_ptr |
| ExitChecker | $451D | $4540 | 4 bytes | HL = exit_ptr (inline processing) |

**The cross-bank problem**: These functions execute FROM bank $0B. You cannot bankswitch mid-function because the code itself is in the switchable ROM space ($4000-$7FFF). Switching banks replaces the code under the PC → crash.

### Data Tables Indexed by map_type

| Table | Bank:Address | Entries | Stride | Purpose |
|---|---|---|---|---|
| Room Ptr Table | $0B:$4B43 | 107 | 2B | → screen_ptr_block → step_block → NPC/exit data |
| Tileset Table | $00:$26DD | 107 | 8B | Tile graphics pointer + spawn position |
| Gate Tileset | $00:$2A5D | ? | 8B | Gate-specific tilesets |
| Palette Ptr | $17:$476F | 107 | 2B | GBC palette data |
| Text Dispatch | $01:$6119 | 107 | 2B | Text handler function pointer |
| Screen Offset | $00:$2DE7 | 16 | 2B | Screen position lookup (X,Y offsets) |
| **BGM Selection** | **UNKNOWN** | — | — | **Needs investigation** |
| **Movement Bounds** | **UNKNOWN** | — | — | **Needs investigation** |

### Room Data Format (fully decoded)
```
ptr_table[$4B43 + mapID×2] → screen_ptr_block (8 bytes: 4 slots × 2)
  → slot[screen_index] → step_block
    step_block: [ram_flag_ptr:2] [step_entry×N] [FF]
      step_entry (6 bytes): [step_id:1][tileset:1][interact_ptr:2][exit_ptr:2]
        → interact_block: NPC entries (5B each) + FF terminator
        → exit_block: exit entries (7B each) + FF terminator
```

### Room Data in Bank $0B — Complete Layout

All room data occupies $4C13-$7FFF in bank $0B (approximately 13,293 bytes). Major blocks:

| map_type | Address | Size | Name | Notes |
|---|---|---|---|---|
| $00 | $4C13 | ~528 | Castle | Largest room, 7+ step variants |
| $01 | $4E23 | ~570 | GreatTree | 8 screens, complex |
| $02 | $505D | ~661 | Bazaar | Multi-screen |
| ... | | | | |
| $4E | $775D | 76 | Boss: DeathMore | Commandeerable |
| $4F | $77A9 | 52 | Boss: DarkDrium | Already used in PoC |
| $50/$5F | $77DD | 29 | Gate Floor: Item Shop | Shared by 2 map_types |
| $51 | $77FA | 29 | Gate Floor: Priest | |
| $52 | $7817 | 52 | Gate Floor: Coliseum | |
| $53-$64 | $784B+ | varies | Special rooms, mazes | |
| $54-$59 | $7908+ | 112 each | Conveyor/maze rooms | |
| $5E | $7CE2 | 797 | Arena Setup | Largest single room block |

### Transition State Machine

1. Exit checker (Entry 6) detects player on exit tile → sets `wIsPlayerChangingMaps` ($C96C), writes dest to $C96D-$C972
2. Entry 0: checks $C96C → copies $C96D→wMapID ($C968), loads tileset from $26DD
3. Fade animation runs (bit 7 of $C8EA)
4. Entry 7: when fade complete (bit 7 clear) → calls ReadInteractPtr, spawns NPCs
5. Game renders room, exit checker resumes

---

## 3. Text/Dialogue System — PARTIALLY UNDERSTOOD

### Text Dispatch Table ($01:$6119)
107 entries indexed by wMapID. Each points to a handler function within bank $01.

**73 rooms have no text** (handler starts with RET): $02, $03-$07, $09-$18, $1B-$1F, $22, $24-$25, $27, $2B, $31-$36, $38-$3B, $40-$42, $60-$6A, $43, $45, $4A, $4C, $4E, $50-$59, $5A-$5C, $5E-$5F, $61-$64

**34 rooms have real text handlers** across 30 unique handler functions.

### Handler Pattern (shared by most rooms)
```asm
LD A, [$C8A6]        ; read interaction state
AND $1F              ; mask lower 5 bits
CP $03               ; check if == 3 (NPC talk triggered?)
RET NZ               ; return if not talking
LD HL, $XXXX         ; pointer to text pointer table
LD DE, $YYYY         ; pointer to text data
LD B, $ZZ            ; count (max entries)
CALL $6602           ; text swap/load function
RET
```

**$C8A6 significance**: Appears to be NPC interaction state. Value AND $1F == 3 means "player has initiated conversation." This gate prevents text loading at wrong times.

### Text Data Organization
Each handler points to text pointer tables at specific ROM addresses within bank $01. Text data itself is in various banks ($18-$3F range based on known matches).

### Known Text Bank Mappings (verified with dialogue content)

| Room | Text Bank | Table Offset | Verified? |
|---|---|---|---|
| Bazaar | $3F | $4487 | ✓ |
| Farm | $3F | $44FD | ✓ |
| Stable | $22 | $4023 | ✓ |
| Arena Lobby | $21 | $403D | ✓ |
| Well | $21 | $40DF | ✓ |
| Starry Shrine | $18 | $5667 | ✓ |
| Castle | UNKNOWN | — | ✗ (matched item names, wrong) |
| GreatTree | UNKNOWN | — | ✗ (matched monster names, wrong) |

### UNKNOWN: Script_id → Text Mapping
When an NPC has script_id = N, how does the handler use N to select which dialogue to display? The handler's HL/DE pointers and B count likely define a table where script_id indexes into the text. **This needs SameBoy tracing.**

### UNKNOWN: How to Add Custom Text
Options being considered:
1. Redirect text dispatch entry for custom map_types to a handler that reads from an empty bank
2. Write a minimal handler in bank $01's 31 free bytes ($7FE0)
3. Use the 1,228 free bytes in bank $51 for a cross-bank text loader

---

## 4. Event/Trigger System — BARELY UNDERSTOOD

### Main State Machine ($D9F4)
Bank $50 has the main event dispatcher. State variable at $D9F4 indexes a jump table at $50:$401B (11 states, $00-$0A).

| State | Handler | Purpose |
|---|---|---|
| 0 | $4031 | UNKNOWN |
| 1 | $40ED | UNKNOWN |
| 2 | $4114 | UNKNOWN |
| ... | | |
| 10 | $59D6 | Script executor (loads from $DB58-$DB59) |

### Bank $50 Entry Points
10 entries ($50:$4001): main event system, post-battle states, gate scripts.

### Bank $51 Entry Points
16 entries ($51:$4001): join handler, transition coordination, level-up.
**1,228 bytes free at $7B34** — potential space for custom code.

### Step Variables
Per-room RAM bytes that track story progress within a room:
- $D92A: Castle step (story progression)
- $D95E: MedalMan step
- $D95F: Well step
- $D988: Labyrinth step
- $D997: Unused Gate step
- $D9E9: General multi-step screen variable

When a step variable changes, the room re-reads its step block and potentially shows different NPCs, exits, and tilemap.

### UNKNOWN: How Story Events Are Triggered
The game must have a mechanism for "after event X, change step variable Y." This could be:
- Direct writes in event script handlers
- A table mapping game progress flags to step values
- Inline code in bank $50/$51 state handlers

**Needs SameBoy investigation**: Watch $D92A during Castle story progression to trace what writes to it and when.

### UNKNOWN: Script Format
State 10 handler loads script pointers from $DB58-$DB59. The script data format is completely unknown. Decoding this is essential for custom story triggers.

---

## 5. Graphics System — PARTIALLY UNDERSTOOD

### Tile Graphics
- Format: Standard GB 2bpp planar
- Compression: Custom Enix LZ77 variant (marker byte $01, 4096-byte circular buffer mapped to $C000-$CFFF)
- Individual tiles don't have ROM addresses — they exist as offsets within compressed blocks

### step_id → Tilemap Mapping
step_id in the step entry controls which room LAYOUT is rendered. Known values:
- $01: OldMan Gate / Castle layout (with tileset $2A)
- $05: Copycat House layout
- $0D: MedalMan layout
- $10: Well rope-descent layout

**UNKNOWN**: Where is the step_id → tilemap lookup table? Is it a pointer table? In which bank? Understanding this is required for creating truly new room layouts (vs reusing existing ones).

### Palette System (Bank $17)
Palette pointer table at $17:$476F (107 entries × 2 bytes, indexed by map_type). Points to palette data within bank $17. GBC only.

---

## 6. Music/BGM System — BARELY UNDERSTOOD

### BGM State
- $C8B5: Current BGM offset
- $C8B7: BGM to load
- Set BGM function at $00:$1AE5

### Room → BGM Mapping: UNKNOWN
Only 1 write to $C8B5 found in bank $00. No writes found in bank $0B (room system). BGM is likely set by the EVENT system, not room loading. This means custom room BGM requires hooking the event/transition system.

Known BGM values (from RAM map):
$02=No music, $09=BigTree, $0C-$1B=Gate musics, $1E=Arena, $24=Main Menu, $27=Battle, $31=Starry Shrine

---

## 7. Feature → System Dependency Map

### Custom Rooms (cross-bank data)
**Status**: PoC working (single room, data in bank $0B). Cross-bank NOT yet working.
- Room Ptr Table ($0B:$4B43) — need to redirect entries
- Tileset Table ($00:$26DD) — need entries for custom map_types
- Palette Table ($17:$476F) — need entries for custom map_types
- **BLOCKER**: 4 pointer-chasing functions hardcoded to bank $0B
- **APPROACH**: Copy-on-transition via ROM0 helper, OR refactor in disassembly

### Custom NPC Dialogue
**Status**: NPCs appear but crash when talked to.
- Text Dispatch Table ($01:$6119) — handler for map_type $20 uses Castle-like handler
- Need custom handler that reads text from empty bank
- Need text data encoded with game codec
- **BLOCKER**: Must understand script_id → text mapping

### Custom Story/Triggers
**Status**: Not started.
- Event state machine ($D9F4, bank $50)
- Step variables (per-room story flags)
- Script format ($DB58-$DB59)
- **BLOCKER**: Script format completely unknown

### New Room Layouts
**Status**: Not started.
- step_id → tilemap mapping unknown
- LZ77 graphics format partially understood
- **BLOCKER**: Cannot create new layouts without tilemap format

### Custom Breeding Tables
**Status**: Table location known ($16:$4B30), format unknown.

---

## 8. Priority Investigation Queue

### Highest Priority (blocks multiple features)
1. **Script_id → text mapping**: Breakpoint NPC interaction in SameBoy, trace from Entry 3 through text dispatch to understand how script_id selects dialogue. Enables: custom dialogue.

2. **Step variable write tracing**: Watch $D92A during Castle story progression. Trace what code writes to it. Enables: custom story triggers, understanding event system.

3. **Bank $51 free space safety**: Play through significant gameplay with watch on $7B34-$7FFF. If never touched, it's 1,228 bytes of safe space for custom code. Enables: more room for patches.

### Medium Priority (blocks one feature)
4. **step_id → tilemap mapping**: Breakpoint the tilemap load (somewhere in bank $0B or graphics banks). Trace how step_id gets translated to a tilemap. Enables: new room layouts.

5. **BGM selection mechanism**: Watch $C8B5 during room transitions. Trace what sets it. Enables: custom room BGM.

6. **Breeding table format**: Inspect $16:$4B30 against known breeding results. Enables: custom breeding.

### Lower Priority (nice to have)
7. **$C8A6 full documentation**: What exactly is this interaction state? All values?
8. **Screen boundary system**: How are multi-screen room boundaries defined?
9. **NPC movement boundary system**: What constrains NPC patrol paths?

---

## 9. SameBoy Test Queue (For User)

### Test 1: Script_id → Text Tracing
```
breakpoint $01:$6119    ; text dispatch table entry
; Go to Starry Shrine, talk to any NPC
; When breakpoint fires:
registers
print [$C8A6]
backtrace
; Then step through the handler to see how script_id is used
```

### Test 2: Step Variable Tracing
```
watch/w $D92A          ; Castle step variable
; Start a new game, play through first few story beats
; Each time the watchpoint fires:
registers
backtrace
print [$D92A]
```

### Test 3: Bank $51 Free Space Safety
```
watch/w $51:$7B34 to $51:$7FFF inclusive
; Play for 10+ minutes with various activities
; If the watchpoint NEVER fires, the space is safe
```

### Test 4: BGM Tracing
```
watch/w $C8B5
; Walk from GreatTree into Castle
; When watchpoint fires:
registers
backtrace
; Reveals what code sets room BGM
```

---

## 10. Disassembly File Status

### Annotated (by user's fork)
- `bank_00b.asm` — FULLY annotated with comments, labels, function descriptions. Builds byte-identical.
- `hardware.inc` — Fixed SET→EQU for rgbds 0.6.x compatibility.

### Needs Annotation
- `bank_001.asm` — Text dispatch, encounters, NPC interaction (HIGH PRIORITY)
- `bank_000.asm` — RST handlers, BGM, core functions (MEDIUM)
- `bank_050.asm` — Event state machine (HIGH PRIORITY)
- `bank_051.asm` — Transitions, join handler (MEDIUM)
- `bank_017.asm` — Palette system (LOW)

### Data Sections Needing Conversion
Within bank_00b.asm, the region from approximately $49BB to $7FFF is room data auto-disassembled as instructions. Converting these to labeled `db`/`dw` declarations would enable:
- Symbolic pointer table entries (change where rooms point)
- Room data reorganization (move/relocate rooms)
- Proper size accounting for free space planning

---

## 11. Architecture Decision: Cross-Bank Room Approach

### Option A: Copy-on-Transition (smallest code change)
Put a copy routine in ROM0 ($3FE8). Hook Entry 0 to copy custom room data from bank $60 to a staging area in bank $0B. All 4 pointer-chasing functions remain unchanged.

**Pros**: Minimal code changes, low risk of breaking existing rooms.
**Cons**: Uses ROM0 safe space (24 bytes), requires staging area in bank $0B (uses boss room space), limits room data size to staging area size.

### Option B: Disassembly Refactor (cleanest long-term)
Refactor the 4 pointer-chasing functions to share a common subroutine. Add bank indirection to the shared subroutine. The subroutine calls a ROM0 helper for bank switching.

**Pros**: Clean, maintainable, no staging area size limit.
**Cons**: More code changes, must verify all existing rooms still work, requires careful ROM0 space management.

### Option C: Full Disassembly Restructure (maximum flexibility)
Convert all room data to labeled data declarations. Move data between sections freely. Add new sections for custom rooms. Let rgbasm handle all addressing.

**Pros**: Maximum flexibility, proper symbolic addressing, enables all future modifications.
**Cons**: Large upfront effort to convert misassembled data, risk of introducing bugs during conversion.

### Recommendation
Start with Option A for immediate testing, then migrate to Option C as the disassembly understanding deepens. Option C is the right long-term architecture for a hack with new story, triggers, and environments.

---

*Last updated: June 2026 — Generated from systematic disassembly analysis*
