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
- **GateAwareDispatch** (Entry 6) — gate-entry regression fix. Bank `$04`'s bank-`$0F`
  script-dispatch hook (`DispatchBank0F`) redirects here; routes by **`wMapID`**:
  `< $6B` → bank `$0F` entry 0 (vanilla gate/labyrinth script); `≥ $6B` →
  `CustomScriptRead`. Replaces a broken hook that tested `wScriptMapType` (gate world
  `$70`) and froze gate entry. See `GATE_FREEZE_FIX.md`.
- **CustomSourceMapTable** — maps custom room index → source mapID
- **Room data** — sub-tables, step entries, NPC data, exit data for each custom room

**S136 (ROADMAP ARC CAP2b): bank $60 is now the FORWARDING bank + the first home bank.** The readers
above (CustomPtrChase, entries 0-2, the script / text readers, state rules, casts, tile patches) are
one pinned block (`editor2/core/templates/place_readers.asm`) that indexes its bank's tables with
`[wPlaceIdx]`; bank $60's entries 0/1/2/4/5/8/9/10 look the place up in `PlaceDirectory` on every
call and call its home bank — $60 itself or a place bank $80+ carrying its own copy of the block.
ARCHITECTURE "Place banks (S136)"; sites below ("S136 sites").
**S137 (ARC CAP2c):** + entry 13 (render row + palette → WRAM for bank $17 `CustomAttrCheck`); a
room's render rows and palettes are part of its block. ARCHITECTURE "Room colours in the place
banks (S137)"; sites below ("S137 sites").

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
| $6115 | VRAM dispatch ($6119, **112** entries — S99) | Per-frame room TILE ANIMATION (S99: no longer a clamp — custom rooms ask bank $71 entry 3 for their `animation` source; ROOM_DATA_FORMAT "Animated tiles") |
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
10. **VRAM dispatch** (historical, pre-S99): MapIDClampForDispatch returned $00 → Castle's handler ran, rolling tiles 77-78 every 32 frames in every custom room (not "harmless", and it maintains no state — DOC_AUDIT S99). S99: the room's own `animation` source (bank $71 entry 3)
11. **Room entry script**: MapIDClampForPalette returns $16 → engine runs MedalMan's script 0 which is just `end`
12. Fade in, player can walk

### Per-Frame (During Gameplay)

- **Entry 2** (ScreenScroll): calls ReadStepBlock → bank $60 → decompresses correct tiles
- **RoomEntry6** (ExitChecker): calls bank $60 CustomExitCheck → copies exits to wCustomExitBuffer → engine checks normally
- **VRAM dispatch**: runs the room's animation source's handler (S99; pre-S99 always Castle's)
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
| $04 DispatchBank0F | Script bank-$0F dispatch (≥$40 map-types) | redirect to bank $60 entry 6 (GateAwareDispatch), route by **wMapID** — NOT wScriptMapType (see GATE_FREEZE_FIX.md) |

> ⚠️ **The bank-$04 row is the one that bit hardest.** Unlike the others, its
> divert decision is on the **script** map-type, which overlaps the custom-room
> range ($6B+) with legitimate gate/labyrinth scripts (gate world = $70). The fix
> keys the divert off the **room** map-type `wMapID` instead. Testing the wrong
> "map type" variable froze gate entry for ~5 sessions (latent since 3d94ad9).

### 4. $FFFF Screen Guard Required for Multi-Screen Rooms
When scrolling to an unused screen slot ($FFFF in the sub-table), CustomPtrChase must detect this and return a safe DummyStepEntry instead of dereferencing $FFFF. The DummyStepEntry MUST reference valid tileset data (not bank $00 which contains RST handlers, not tile data).

**S135: the guard was only half of it.** The bank $17 render walk (`label17_409e`, the attr map +
palette of the screen) has NO such guard: the compiler's `RoomAttr_<mid>` row had `dw $0000` for an
undefined screen, the walk followed it into ROM0, and walking into such a screen inside the room's
size crashed (game mode `$FE`, PyBoy hang — measured with screens 0 + 5 of a 2 × 2 room). The
compiler now gives every screen inside the room's size a real row (the first screen's) and warns
(`emitters.room_holes`, PROJECT_COMPILER §2.44); the screen still draws `DummyStepEntry`.

### 5. Screen Byte Format in Exit Data
```
Bits 0-3: $2DE7 table index (0-15, maps to 4×4 screen grid offsets)
Bit 7:    Adds $08 to Y spawn position (for rooms with >2 screen rows)
```
Use the SAME screen byte as existing rooms that exit to the same destination. Example: WellStairway exits to GreatTree screen 8 with screen byte $08. Copy that exactly.

### 6. ~~VRAM Dispatch Must Use Castle Handler ($00), Not RET-Only~~ — REFUTED S99
**S99 measurement:** a bare-`ret` handler is safe (screen and palette buffer identical; only the 77-78 roll stops). Custom rooms now choose their animation (`none` = the table's `ret` row) — ROOM_DATA_FORMAT "Animated tiles", DOC_AUDIT S99. Original S1 text kept below for history:

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
    db $8F, $FF, X, Y, SCRIPT  ; examine spot (S98: not a spawn — A press runs SCRIPT)
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

## Random Encounters in Custom Rooms

**Status: PROVEN (v30, June 2026).** Random battles fire in custom Room `$6B`
from a chosen pool; win and flee return to the room intact. The full vanilla
mechanism is documented in DATA_STRUCTURES.md → "Encounter Runtime Flow"; this
section is the custom-room recipe and the editor build spec.

> **Related — putting a custom room INTO the gate floor rotation** (so it appears
> as a special room while diving a gate, like the priest/treasure/maze rooms):
> see **GATE_GENERATION.md §6**. The hook is the special-floor `rst $00` dispatch
> at `$16:$5C1C`; each handler just sets `wMapID` + `wInGateworld=0` — the same
> `wInGateworld=0` mode custom rooms (mapID ≥ `$6B`) already render in, so a
> dispatch slot pointed at a custom mapID drops it into the rotation. **Built
> differently:** S41 inserted before the vanilla gating (a fork, not a dispatch
> slot) and S100 made it data-driven — GATE_GENERATION §7.6. A room served in a
> gate must NOT use a pinned pool (this section's recipe): pinning rewrites
> `wGateID`/`wCurrentFloor` and the next floor would belong to that gate — use
> `encounters.follow_gate` (RoomEncTable gate byte $FF, S100).

### What it takes (two patches)

**Patch 1 — enable + pin the pool (`bank_00b.asm`).** Add the custom mapID to
the per-step encounter whitelist in `Jump_00b_4674`, routing it to a tiny seed
stub that pins the encounter table, then runs the per-step handler:

```
    cp $6B
    jr z, Seed6BEncounterPool
    ret
Seed6BEncounterPool:
    xor a
    ld [wGateID], a            ; $C935 = 0  (gate 0 = Gate of Beginning)
    inc a
    ld [wCurrentFloor], a      ; $C939 = 1  (floor 1)
    jp jr_00b_46d5             ; run bank $16 entry 8 (encounter step)
```

`wGateID`/`wCurrentFloor` are consumed only when a battle fires
(`EncounterMonsterSelect`), so writing them every step here is safe and makes
the resolved pool deterministic (`gate 0 / floor 1 → pool 0 =
Slime/Anteater/Dracky`). Change the two constants to point at any of the 32
gates / any floor band.

**Patch 2 — arm the step counter (`bank_060.asm`, room-entry script index 0).**
Non-gate rooms are never seeded by the vanilla counter path (it `ret z`s on
`wInGateworld=0`). Seed it from the room-entry script with `write_ram`
(opcode `$12`, writes the LOW byte of the value):

```
CustomRoom0_RoomEntry:
    dw $FF12 / dw $CA39 / dw $0064   ; wEncounterCounterLo = $64
    dw $FF12 / dw $CA3A / dw $0000   ; wEncounterCounterHi = $00 → 100 (~5 steps)
    dw $FFFF
```

### Hard-won gotchas (see KEY_LESSONS.md for full write-ups)

- **Stale gate drift.** A non-gate custom room inherits `wGateID`/`wCurrentFloor`
  from the last *real* gate the player visited. Without Patch 1, battles draw
  from that stale gate's pool (observed: gate 7/floor 8 → pool 18 = Boneslave &
  co. in a "starter" room). The table is meaningless until you pin gate+floor.
- **Room-entry script timing.** Script index 0 runs reliably on screen *scroll*
  and post-battle *reload*, but NOT dependably at initial room entry — so it is
  unsuitable for state that must be correct at battle time. Pin per-step state
  (gate/floor) in ASM (Patch 1); use the script only for one-shot arming
  (the counter, Patch 2). `write_ram` itself works in custom rooms because
  param reads route through `DispatchBank0F_Ext → GateAwareDispatch → CustomScriptRead`.

### Editor build spec

**#1 — per-room encounter toggle (generalize the hardcoded `$6B`).**
Replace the single `cp $6B` with a small per-mapID table the editor emits, e.g.
in bank $60: `RoomEncTable: db mapID, gateID, floor` rows, `$FF`-terminated.
The whitelist hook scans it: no match → `ret` (encounters OFF); match → seed
`wGateID`/`wCurrentFloor` from the row, `jp jr_00b_46d5` (ON). Counter arming
(Patch 2) becomes part of every encounter-enabled room's entry script. Editor
project fields per room: `encounters: bool`, `gate_id: 0-31`, `floor: int`.

**#2 — fully custom monster pool (not tied to a vanilla gate).** **BUILT S114** (route
(b), in a new bank $76 with a same-size bank $01 fork; rooms pick a list of their own —
no gate pin — with flag variants and a rate; PROJECT_COMPILER §2.30, DATA_STRUCTURES
"Encounter list choice (S114)"). The spec below is the pre-S114 plan, kept for the record.
Also S114: the engine DOES re-seed the step counter at every room load (bank $0B Entry 0
→ bank $16 entry 6), so "Patch 2" below is not needed (DOC_AUDIT S114).
Two viable routes, both needing a 26-byte pool in the exact format (header
selection sub-fields at +2/+5 matter — copy a working pool's header and only
swap EID slots +10 and weights +20):
  (a) **Reuse a free pool slot** if any of the 128 `EncounterPoolData` entries
      are unreferenced — must first verify which indices no gate maps to.
  (b) **Custom pool bank + intercept**: place pool table in a free bank and
      intercept `EncounterMonsterSelect`'s pool-data fetch for custom mapIDs
      (return the custom pool address instead of `EncounterPoolData +
      idx×26`). Set `wEncounterPoolIndex` directly and skip the gate/floor
      lookup. Editor fields: up to 5 `{enemy_stats_id, weight}` + the header
      template.

Both #1 and #2 must keep counter arming for non-gate rooms (Patch 2) and must
not set `wInGateworld=1` (that re-engages gate save/menu suppression — that's
Strategy B, deliberately not used here so saving keeps working).

---

## Known Limitations

1. **4 palette groups max**: BG palette slots 4-7 are reserved by the game engine for monster display (slots 4/5/6) and menu text (slot 7). Custom rooms may use at most 4 unique palette groups (slots 0-3). All 85 original DWM1 tilesets observe this limit. The PalGrp toggle in the editor shows group assignments.
2. **Custom tilesets**: Currently reuses existing rooms' tilesets. New tile graphics require adding entries to the $26DD table and tileset banks.
3. **Step progression**: CustomPtrChase always uses step 0. Multi-step rooms (changing layout based on game progress) need step counter management.
4. **Source mapID scaling**: MapIDClampForPalette uses hardcoded conditionals for 2 rooms. For many rooms, extend to a ROM0 table or WRAM-cached lookup from bank $60.
5. **Random encounters**: ✅ PROVEN for custom rooms (Strategy A, v30) — see
   "Random Encounters in Custom Rooms" below. Per-room toggle (#1) and custom
   monster pools (#2) are specced there for the editor, not yet generalized.

---

## mapID ≥$80 readiness audit (A′1, S66)

**Verdict: the engine is ≥$80-READY as patched.** No code change is needed to
cross mapID $7F except the compiler-owned BGM-table extension below (a feature
cap, not a crash). Census + per-site verdicts: `tools/audit_mapid_range.py`
(SELFTEST-pinned; 58 clean / 56 patched `ld a, [wMapID]` sites, zero
pointer-form or literal-`$C968` references in either tree, 21 writers all
constants/copies/table reads with no masking) → `extracted/mapid_range_audit.json`.

**S114 burn-down:** the nine sites added S100-S114 that `--selftest` still reported
NEEDS_REVIEW are adjudicated (`SaveAllowCheck` both trees, `CustomRoomBGMResolve#1`,
`CustomTileAnimate#1`, `GateLeaveFreePal` = CP_UNSIGNED; `CustomMonsterCast` =
IDX8_SUB6B; `CustomTileAnimate#0`, `CustomRoomFlags`, bank $76 `EncResolve` = BOUNDED);
selftest PASS (clean 58, patched 75); `extracted/mapid_range_audit.json` regenerated.

**S121 site.** Bank $71 entry 8 `TextSpriteMode` (the text-box sprite rule for copies of
$08 / $5D, ROOM_DATA_FORMAT "Text boxes and sprites (S121)"): `ld a,[wMapID]` → `cp $08` /
`cp $5d` (equality, full byte), `sub CUSTOM_ROOM_START / ret c`, `cp ROOMFLAGS_TABLE_LEN /
ret nc`, then a 16-bit add into `CustomRoomFlagsTable` — **BOUNDED** (as `CustomRoomFlags`).
Bank $79 reads no mapID (the hook's room is a `$3B` word written by the compiler).

**S123 sites (NPC colours, PROJECT_COMPILER §2.36).** Bank $60 `CopyNPCListToBuffer`
stores `wMapID` (and `wScreenIndex`) into the tag `wNpcColourMap` / `wNpcColourScr` —
**COPY** (never an index); entry 11 `NpcColourDraw` compares `wMapID` with that tag (`cp b`,
a full-byte equality) — **CP_UNSIGNED**. Neither indexes a table by mapID, so any id
$00-$FE is safe. **S123 r2:** bank $0B `CustomDescentInGate`'s `cp CUSTOM_ROOM_START / jr c`
moved into bank $60 entry 12 `CustomDescentFeel` (`cp` / `ret c`) — still **CP_UNSIGNED**
(the bank $0B key retired; the routine is a far call now).

**S126 site (service NPCs, PROJECT_COMPILER §2.39).** Bank $77 entry 6 `ServiceOpenTiles`
reads `wMapID` once: `cp CUSTOM_ROOM_START / ret c` (vanilla rooms keep the game's
behaviour, no tile save) — **CP_UNSIGNED** (`("bank_077.asm", "ServiceOpenTiles", 0)` in
`tools/audit_mapid_range.py`; `extracted/mapid_range_audit.json` regenerated: clean 58,
patched 86). `PushAttrActive` (S117b) is unchanged. No table is indexed by mapID.

**S129 site (music by flag, PROJECT_COMPILER §2.42).** Bank $71 `CustomRoomBGMResolve`'s
room path now asks `MusicRulePick` first: the first `ld a, [wMapID]` (#0, BOUNDED — `cp $80
/ ret nc`) goes to `ld c, a` for the rule scan (full-byte EQUALITY against the
`MusicRuleTable` rows' id byte — never an index), then `.noRule` reloads `wMapID` for
`.lookup` (**#1, BOUNDED**: the same value, still under that `cp $80`); the S101 `cp $61`
read moved to **#2 (CP_UNSIGNED)**. `MusicRulePick` itself reads no map id (B / C come in;
the gate rows compare `wGateID`). Keys updated in `tools/audit_mapid_range.py`;
`extracted/mapid_range_audit.json` regenerated: clean 58, patched 85. No table is indexed
by mapID.

**S128 sites (your arena, PROJECT_COMPILER §2.41).** The arena was keyed on the vanilla
ids `$06` (MAP_BATTLE1) / `$5D` (MAP_BTLDEMO) at nine `ld a, [wMapID]` /
`ld a, [wScriptMapType]` sites; each now goes through ROM0 `ArenaAlias` (the project's
`ARENA_LOBBY_MID` / `ARENA_BATTLE_MID` → `$06` / `$5D`, `$FF` = no arena): banks $01
`CheckScriptBeforeAction` + `SaveMapStateToHRAM`'s class (same size), $03 the escape skill,
$07 the lobby monsters, $50 `BattleExitHandler` + `$5730` (`ArenaScriptType50`) + the loss
mailbox (`ArenaLossWarp50`, an equality `cp ARENA_BATTLE_MID`), $51 the music +
`LoadBtlS_43c9` (`ArenaScriptType51`), the bank $71 template `BattleBGMResolve` (two reads),
bank $6E `ArenaMarkClasses` (`cp ARENA_LOBBY_MID`). New audit keys `ArenaMapID#0`,
`ArenaLossWarp50#0`, `ArenaMarkClasses#0` = **CP_UNSIGNED** (equality tests);
`BattleBGMResolve` re-keyed (0 BOUNDED, 1 CP_UNSIGNED). `extracted/mapid_range_audit.json`
regenerated: clean 58, patched 84. Deliberately NOT aliased: `CheckGateWorldMapType` (the
copies must stay gate-like, S70) and the bank $06 text-sprite rule (the copies carry
`text_keeps_sprites`).

**S127 sites (breeding NPCs, PROJECT_COMPILER §2.40).** Two reads, both **CP_UNSIGNED**:
bank $73 entry 0 `CF2WarpCommitDrain` — `cp $08` (equality: the ceremony map $08 keeps
the random-breeder slots, every other committed transition clears them); bank $77
entry 7 `BreedClose` — `cp CUSTOM_ROOM_START / jr c` (vanilla rooms keep the game's
close; custom rooms also reload the room sheet). Keys added to
`tools/audit_mapid_range.py`; `extracted/mapid_range_audit.json` regenerated: clean 58,
patched 88. No table is indexed by mapID.

**S120 burn-down (ROADMAP "audit_mapid_range re-adjudication").** The selftest had been
failing since S116 with twelve NEEDS_REVIEW sites — not the "eleven S117 shop sites" the
S118 ROADMAP note named. Read site by site:
- `ShopBuyStockFill#0`, `ShopSellPrice#0` (bank $09, both trees; `cp $50` = the
  gate-floor shop room), `ShopFill#0` (bank $77, `cp $50`), `GateBossWin#0` (bank $76,
  `cp b` against `wBossMapType`, a full-byte equality), `PushAttrActive#0` (bank $77,
  `cp CUSTOM_ROOM_START`), `CustomReadInteract#0` (bank $60 entry 1: `cp
  CUSTOM_ROOM_START` → `CustomPtrChase`, IDX8_SUB6B; else a `cp c` equality scan of
  `VanillaNPCExtTable`), `CutPatchRoute#0` (bank $60, S119: `cp CUSTOM_ROOM_START`, the
  GateAwareDispatch rule), `BattleBGMResolve#0/#1/#3` (bank $71 entry 7: `cp $5d`, `cp
  $50` / `$52` / `$5d`) = **CP_UNSIGNED**.
- `BattleBGMResolve#2` = **BOUNDED**: `cp $80 / jr nc .type` before a correct 16-bit
  `add l / ld l,a / adc h / sub l` index into the 128-entry `CustomRoomBattleBGMTable`. A
  second FEATURE cap at $7F (like the room-default music below): a room ≥ $80 gets the
  normal / boss battle song, and a gate-served room ≥ $80 does not follow the gate's
  battle song. `editor2/core/music.py` refuses `music.battle.rooms` keys ≥ $80 (loud),
  but the automatic "follow the gate" fill for served rooms skips them silently. The
  ≥ $80 extension recipe below covers both tables (widen to 256, drop both `cp $80`).
  **DONE S138** ("S138 sites" below): both tables 256 rows, no `cp $80`.
- **Four verdict keys had gone STALE** (labels renamed after they were keyed: `CmpFld_604d`
  → `SaveAllowCheck` S100, `Jump_050_640a` → `BattleExitHandler`, `jr_009_46de` →
  `ShopBuyStockFill` and `SetFld9_4bc8` → `ShopSellPrice` S117). A stale key hides
  nothing by itself, but the renamed site re-appears as NEEDS_REVIEW and a NEW load
  placed under the old label would inherit a verdict nobody gave it — the tool now FAILS
  on a key that matches no site.
- `CutPatchRoute` was missing from the S118/S119 runs because the committed
  `patches/bank_060.asm` was still the S117 file (PROJECT_COMPILER §1 "S120").

Selftest PASS (clean 58, patched 82; band raised to [50, 120]); the tool is now in
`verify_integrity.py` check 5, so the next unkeyed site fails the verifier instead of
waiting for someone to run it. `extracted/mapid_range_audit.json` regenerated.

### Why the "sign test" fear was unfounded

The SM83 **has no sign flag** — `jp m`-class patterns (ROADMAP's original
wording) cannot exist; see DOC_AUDIT addendum. Every wMapID comparison in the
ROM is an **unsigned `cp`**, so a mapID ≥$80 takes the *identical branch*
already proven by rooms $6B-$70 at every comparison site. The only `bit 7`
hits near mapID reads are on *other* variables (wInGateworld, `$c8ea`, skill
id `$db8a` in bank $53) or on the NPC-entry **type byte**, whose ≥$80 range is
the by-design NPC / interact-entry discriminator ($80-$83/$8F = examine
spot, $90 = step-on trigger — S98 names; ROOM_DATA_FORMAT), not a mapID.

### The real ≥$80 hazard classes — and why each is already handled

1. **8-bit `add a` doubling drops the $100 carry.** `add a / add l / ld l,a /
   ld a,$00 / adc h` computes `(2·mapID mod 256) + base`: the doubling carry
   is destroyed by the following `add l`. **RST_00 itself has this shape** —
   every `rst $00` jump-table dispatch is $7F-capped by construction (RST_20
   likewise caps L). Every vanilla instance is safe because:
   - the only mapID-driven `rst $00` (PerRoomDispatchEntry, bank $01) is
     patched with `call MapIDClampForDispatch` (unsigned `cp $6B / ret c /
     xor a` → all custom rooms dispatch as Castle);
   - the four bank $0B RoomPtrTable ×2 walks are diverted for **all** mapIDs
     ≥$6B by `cp CUSTOM_ROOM_START / jr c` **before** the walk (→ bank $60
     entries 0/1/2); the patched `SharedPtrChase` is therefore only reachable
     with mapID <$6B;
   - the two bank $17 AttrPtrTable ×2 walks are intercepted by
     CustomAttrCheck / MapIDClampForPalette (both unsigned);
   - FloorPalettePtrTable ($17:$51F5) and EncounterRateData ×8 ($16) run only
     in gate context, where wMapID = floortype (<$20); GateFloorDataTable ×8
     indexes wGateID (≤$1F), written from wMapID **only on the gate-entry
     path** — hence the authoring rule below;
   - RoomBGMTable ($01) is guarded by `cp $61` (≥$61 never indexes it) and,
     S64, consulted only after the bounds-checked bank $71 resolver.
2. **Fixed-size tables indexed by raw mapID.** All live ones are covered
   above. One pre-existing **WATCH** item: the bank $01 default-player-spawn
   table (auto-label `NPCWalkDataTable` — misleading; see the S66 comment at
   the site) is indexed raw-mapID ×4 with 107 entries. Custom rooms already
   overrun it today; every proven path is unaffected (v7 save-in-room →
   reload OK: position restores from the save image). Crossing $80 changes
   nothing. If the editor ever depends on non-warp default spawns in custom
   rooms, emit a custom table.

### Custom-side arithmetic ceilings

| Path | Idiom | Safe through |
|---|---|---|
| bank $60 CustomPtrChase, **CustomStateRules, CustomMonsterCast** (S133: missing from this row before), $17 CustomAttrCheck (+ its callers `label17_401d` / `label17_409e`, which double the returned index again) / CustomPalCheck — **S136: the bank $60 readers index `[wPlaceIdx]`; S137: `CustomAttrCheck` returns index 0 of a WRAM table (no doubling of `mapID − $6B` left in bank $17)** | `sub $6B` then 8-bit `add a` | index $7F → **mapID $EA** — **enforced by the compiler since S133** (`project.CUSTOM_MID_MAX`, ProjectError past it; before S133 a room at $EB+ built and read another room's tables) |
| bank $71 entry 0 (CopyCustomRoomRecord) | 16-bit `sla/rl` ×8; $70+ → Custom26DDTable[mapID−$70]; **S138: `StalePlace` first — a custom id with no place reads the Castle's record** (unbounded S100-S137) | mapID $FE |
| bank $71 entry 1 (CustomEncResolve) | `cp ENC_TABLE_LEN` bounds check | table length (compiler-emitted) |
| bank $71 entry 2 (CustomRoomBGMResolve) | `cp $80 / ret nc` bounds check (S64-S137); **S138: 256-row table, 16-bit index, no check** | every id (see below) |
| bank $71 entry 3 (CustomAnimSource, S99) | `sub $6B` + `cp ANIM_TABLE_LEN` bounds check; 16-bit `add l/adc h/sub l` | table length (compiler-emitted); the returned byte is validator-bounded to <$6B or $6B, so the bank-$01 `rst $00` (≤$7F cap) is always in range |
| bank $60 CustomScriptRead / script master table | 16-bit ×2, dense from $6B (validated) | mapID $FE |

**Ceilings: hard max mapID $FE** ($FF = exit-list terminator byte); practical
max **$EA** (8-bit sub-$6B idiom). The 75-room plan tops out at $B5 — 53 IDs
of margin.

### Room-default music is capped at $7F (feature gap, not crash) — LIFTED S138

**S138 (ROADMAP ARC CAP2e, PROJECT_COMPILER §2.47):** done as the recipe below says — both
`CustomRoomBGMTable` and `CustomRoomBattleBGMTable` have 256 rows, the three `cp $80` guards of
entries 2 / 7 are gone, `music.py` accepts every custom id up to `$EA`; PyBoy: the S138 demo's
rooms `$80-$85` play their own room and battle songs. The text below is the S66-S120 state.

`CustomRoomBGMTable` is 128 entries; the resolver's `cp $80 / ret nc` returns
"no assignment" for mapID ≥$80 (room then gets the vanilla ≥$61 fallback, same
as any unassigned custom room today), and `editor2/core/music.py:176` already
**errors loudly** on `room_defaults` with mid ≥128. Extension recipe (one
compiler session, all compiler-owned): 256-entry table in the `dispatch71`
emitter + widen/remove the `cp $80` guard in the bank $71 template head +
lift the music.py validator range + re-pin TEMPLATE_SIZE[0x71] (currently 142)
and the template hashes (`editor2/core/validators.py:23`).

### Authoring rules the audit makes explicit

1. **Exits targeting custom rooms MUST use `gate_flag=0`.** With flag=1 the
   gate-entry path (bank $16, `label16_5b4e`) writes the mapID into wGateID
   and ×8-indexes GateFloorDataTable with it — garbage floor config.
   S115: flag=1 IS the gate entrance — dest = a gate number, 0-31 vanilla or
   32-95 a project NEW gate (bank $16 `GateRowPtr`; GATE_GENERATION §7.8);
   the validator refuses a flag-1 exit to an undefined gate.
2. **`trigger_x=$FF` is forbidden** in exit entries ($FF is the list
   terminator; trigger_y 0/7 are already validator-warned).
3. **wInGateworld must be 0 while custom-room scripts run** (wScriptMapType is
   forced to the gateworld sentinel $70 when set; harmless for the S41
   transient pattern, wrong if made persistent). Room $70 itself is safe:
   GateAwareDispatch discriminates on wMapID, not wScriptMapType.
4. **Compiler validators** for rules 1 and 2 — both exist (`editor2/core/validators.py`:
   custom-destination exit with gate_flag ≠ 0 = error; exit `trigger_x` $FF = error;
   S120 re-check — this line said "not yet implemented" long after they landed).

### S133 capacity audit — every stored map id, the commit, and what a region needs

Context: ROADMAP ARC CAP / EDITOR_DESIGN §6.4 (hundreds of places → a region per
128-id range). Census by grep of BOTH trees (S133, three parallel read-only passes),
spot-verified by hand where marked ✓; runtime claims measured in PyBoy on the user's
11-room project build + `.sav`.

**RAM that holds a map id** (C = clean tree, P = patched only; "saved" = inside the
`$C8EA-$D9E9` image copied by `SaveGameState`, SRAM = WRAM − `$28C6`):

| Address | What | Writers | Readers | Custom id? | Saved |
|---|---|---|---|---|---|
| `$C968` wMapID | the current map | 21 C / 22 P sites (below) + load restore + new game | 58 C / 85 P (`mapid_range_audit.json`) | yes | `$A0A2` |
| `$C96A` / `$C96B` ✓ | **write-only mirrors** of wMapID / wInGateworld — labelled `wMapIDMirror` / `wInGateworldMirror` S133 | bank $01 `InitFieldState` (field init), bank $15 new game (`$2F`) and the link seed (`$08`) | **none** (no literal, no pointer form) | yes | `$A0A4/5` |
| `$C96D` wWarpGateId (+ `$C96E` wWarpFlag, `$C96F-$C972` spawn) | the transition mailbox | an exit row (bank $0B `jr_00b_45a8`), ops `$0F` / `$3B` / `$43` / `$4F` / `$58` / `$3A`, bank $0A breeding warps, HubWarp (P), ArenaLossWarp50 (P, a 6-byte pointer copy a grep for `ld [wWarpGateId]` misses) | the commit (bank $0B entry 0), bank $01 `SaveMapStateToHRAM`, bank $0B `jr_00b_462c`, bank $06 Castle test | yes | `$A0A7` (meaningful only mid-transition) |
| `$C8FB`-`$C902` | op `$42` / `$4E` return point (map, flag, X, Y, facing, actor) | ops `$42` / `$4E` from wMapID | ops `$43` / `$4F` → the mailbox | yes (breeders in custom rooms) | `$A035` |
| `$C93B` wBossMapType | the boss room of the dive | bank $16 from the gate row byte 4 (P: `GateRowPtr`) | bank $01 RoomBGMTable, bank $71 BGM resolve, bank $76 `GateBossWin` (`cp` wMapID) | yes | `$A075` |
| `$D8D3` wScriptMapType | the running script's map type | from wMapID at script start (4 sites); sentinels `$70` (gate world), `$54`, `$FF` (P: skill scripts) | the script bank dispatch; P bank $60 `CustomScriptRead` (index `type − $6B`) | yes | `$B00D` |
| HRAM `$FFD5` | transition class scratch | `SaveMapStateToHRAM` (source or destination) | the same routine | yes (transient) | no |
| `$C0A1` | debug-menu map | debug pages | debug warp | any | no |
| `$CD00` wCustomExitBuffer (row +2) | P | `CopyExitListToBuffer` | bank $0B exit scan → the mailbox | yes | no (CF3 window) |
| `$D138` wGateRowBuf (+4) | P | bank $76 `NewGateRowCopy` | bank $16 → wMapID / wBossMapType | yes | no |
| `$D2EB` wNpcColourMap ✓ | P, a cache tag | `CopyNPCListToBuffer` | `NpcColourDraw` (`cp` wMapID) | yes | no |
| `$D0C5` wTileAnimRoom | P, a cache tag | bank $6C `TileAnimRestart` | bank $6C (`cp`) | yes | no |
| `$DE88` wCustomRoomFlag | P; holds a VANILLA source id for an instant, then 0/1 (bank $71 re-derives it per frame) | `CustomPtrChase` | entry 3 `CustomTilesetInfo` — **no caller** | no | no |
| `$C935` wGateID / `$C936` wFloorType1 | gate namespace (gate number / floor type), not map ids | bank $16 gate entry | gate tables | no | yes |

Not map-id stores (checked): wHubReason, wAnchorGate / Floor, wGateDiveGate, `$D92B`,
wStoryFlag, wBreedSlots, wShopID, wRoomRecScratch, wCustomNPCBuffer rows, `$D9E3` (the
King's speech codes mirror vanilla boss ids but are constants). SRAM banks 1-3 hold none.

**Where wMapID is set without the mailbox** (a region must be set there too): bank $71
entry 4 `CustomGateInsert` `.hit` (`ld [wMapID], a` from the GateInsertTable row +5 ✓); bank
$16 `jr_016_5be1` (the boss floor: wMapID := gate row +4 ✓ — **8 nop bytes** follow `call
GateRowPtr`, room for a 3-byte call); bank $16 special rooms (constants `$50-$5C`, vanilla);
bank $15 new game / link (constants); bank $55 debug; the save restore.

**The commit ✓.** Bank $0B `RoomEntry0_TilesetLoader`: `ld a, [wWarpGateId] / ld [wMapID], a`
then `ld hl, $7300 / rst $10` = bank $73 entry 0 `CF2WarpCommitDrain`, whose first act is the
displaced `wInGateworld := wWarpFlag`. So the hook already sees the destination in wMapID and
can rewrite it — the place for region resolution. **wWarpFlag cannot carry a region ✓**:
besides that copy, four readers test it BEFORE the commit (bank $01 `SaveMapStateToHRAM` →
`$FFD6` `or a`; bank $06 `or a / ret nz`; bank $0B `.4601` `or a` and `jr_00b_462c` → the
temporary wInGateworld).

**Measured S133 (PyBoy, the user's build + `.sav`):**
- *The exit buffer survives from fire to commit.* Hooks on bank $0B `jr_00b_45a8` (fire),
  bank $60 `CopyExitListToBuffer`, bank $73 `CF2WarpCommitDrain`: a custom door ($6E (6,6) →
  $6B) fired at frame 81 and committed at 100; the GreatTree screen 8 redirect ((3,5) → $6E,
  `VanillaExitResolve`'s copy) fired at 89 and committed at 108; in both, **zero** list copies
  in between and `wCustomExitBuffer` byte-identical at the two hooks. A row's link slot noted
  at copy time is therefore still valid at the commit.
- *A custom script never runs across a commit.* `CustomScriptRead` hooked through the roots
  room's entry scene (`$0F` to `$70`, then `goto` / `end`): the words after the warp were
  read at frame 1090, the commit came at 1109, and the next read was `$70`'s own entry
  script with wScriptMapType = `$70` — so "the running custom script belongs to the current
  place" holds; `CustomScriptRead` can use the place cache.

**Pre-commit readers of the destination** classify only: `SaveMapStateToHRAM` →
`ArenaAlias` + class compares; `jr_00b_462c` → `CheckGateWorldMapType` (≥ `$30` = gate-like,
true for every custom id); bank $06 → `or a` (Castle). An id in `$F0-$FE` therefore
behaves as the custom room it stands for; the arena's ids must stay real ids (global ids,
never link slots).

### S136 sites (place banks, ROADMAP ARC CAP2b)

The bank $60 readers no longer load `wMapID` to index a table: `CustomPtrChase`, `CustomStateRules`,
`CustomMonsterCast` and the custom branch of entry 1 index `[wPlaceIdx]` (their four
`audit_mapid_range` keys were retired). The new loads are the forwarders' — `PlaceFwdStep`,
`PlaceFwdExit`, `PlaceFwdRules` (→ `PlaceOf`: `sub CUSTOM_ROOM_START / ret c / cp PLACE_COUNT / ccf
/ ret c`, then a 16-bit index into `PlaceDirectory` — BOUNDED) and `PlaceFwdInteract` (`cp
CUSTOM_ROOM_START` to the vanilla scan, then `PlaceOf` — CP_UNSIGNED). The ceilings are unchanged:
`PLACE_COUNT` ≤ 128 (the compiler's `$EA`), and the directory index is 16-bit. `wScriptMapType`
(the key of entries 4 / 9 / 10) goes through the same `PlaceOf`: a type past the last place (the
transient `$70` with fewer than 6 places, a sentinel `$54`) now ends the script (BC = `$FFFF`)
instead of reading past the old master table. Selftest PASS (clean 58 / patched 84).

### S137 sites (room colours, ROADMAP ARC CAP2c)

Bank $17 `CustomAttrCheck` keeps its one `ld a, [wMapID]` but only compares it (`cp
CUSTOM_ROOM_START / jr nc`) — the custom path far-calls bank $60 entry 13 and indexes nothing
(verdict IDX8_SUB6B → CP_UNSIGNED). `StateRulesHook17` (its COPY load) is gone. The new load is
`PlaceFwdRender` (→ `PlaceOf`: BOUNDED; no place → HL = 0 → the Castle fallback). Selftest PASS
(clean 58 / patched 84); `extracted/mapid_range_audit.json` regenerated. **Found, NOT fixed
(PROJECT_STATE Open defects S137):** bank $71 entry 0 `CopyCustomRoomRecord` indexes
`Custom26DDTable[mapID − $70]` with no upper bound, so a map id past the last room (a save made
in a room the project has since lost) copies junk as the room record — PyBoy: a junk tileset bank
(`$E1`), `DecompressTileLayout` overwrites WRAM, `wMapID` → `$FF`, hang — in the S136 and the
S137 build alike. The bank $60 / bank $17 paths are bounded since S136 / S137. **Fixed S138**
(next section).

### S138 sites (stale saves + room songs past $7F, ROADMAP ARC CAP2e)

New load: bank $71 `StalePlace` (`sub CUSTOM_ROOM_START / jr c`, `cp ROOMFLAGS_TABLE_LEN / jr nc`,
16-bit add into `CustomRoomFlagsTable`, `bit 7` = a placeholder) — **BOUNDED**; called by entry 0
`CopyCustomRoomRecord` (before its `$70` split: a stale id reads map 0's record) and entry 10
`ContinueCheck`. Re-keyed: `CustomRoomBGMResolve#0` = **COPY** (`ld c, a` for `MusicRulePick`'s
equality scan; the `cp $80` that followed is gone), `#1` = **IDX16** (`.lookup` into the 256-row
table), `BattleBGMResolve#0` = **IDX16** (the same, battle songs). `CustomPalCheck#0` re-read:
`cp CUSTOM_ROOM_START / jr c` and a slot-7 test only — no table index since S94b moved the render
tables out of it → **CP_UNSIGNED** (the IDX8_SUB6B key had been stale; DOC_AUDIT S138).
Everything a stale id reaches is measured by `tools/census_stale_places.py` (TOOLS_AND_DATA
S138): bank $71 entries 0 / 1 / 2 / 3 / 5 / 7 / 10, bank $60 entries 0 / 1 / 2 / 13, bank $17
entries 0 / 1 (== map 0's colours and attr map), bank $76 entry 0 and bank $6C entry 0 (they
return) — for every id past the last room AND a placeholder. Selftest PASS (clean 58 / patched
85); `extracted/mapid_range_audit.json` regenerated (`ceilings.bgm_room_default_max` = `$EA`,
`stale_ids`).

### Re-running the audit

`python3 tools/audit_mapid_range.py` after any engine-adjacent session. A
`NEEDS_REVIEW` row = new wMapID consumer since S66 → adjudicate by hand, add
its key to the tool's verdict table, and record the reasoning here.

---

*Verified working June 2026. 19 iterations, 11 table patches, 3 critical bug classes discovered and resolved.*

## S70: unified Entry-6 resolve, fast custom exits, walk-on boundaries

- **Entry 6 divert (bank $0B) is unconditional**: every step in every
  non-gate room calls bank $60 entry 7 (`VanillaExitResolve`): mapID ≥ $6B
  → `jp CustomExitCheck`; else scan `VanillaExitExtTable` (authored doors
  into vanilla rooms); no match → HL=0 → original SharedPtrChase path.
- **Custom-source transitions take the town fast path** (~18 frames): the
  Entry-6 match tail's gating window was rewritten IN PLACE (no label
  shifts) so mapID ≥ $6B skips `CheckGateWorldMapType` — whose ≥$30
  gate-like sweep is load-bearing for the step machinery (do NOT change the
  classifier; emulator-proven movement freeze) but routed custom exits
  through the ~385-frame gateworld-return ceremony since day one.
- **Walk-on boundary exits (S70v3)**: Entry 6's y=7 row skip compares
  against `wCustomY7Cmp` ($DE74), armed fresh by entry 7 before every scan:
  $07 vanilla (skip, byte-identical semantics), $FE custom (y=7 rows fire
  on ARRIVAL). Entry 9 (push) still reads the same lists as fallback; its
  caller is movement-attempt-gated and never runs while standing.
- **Entrance authoring**: entry scripts run at INITIAL entry (bank $01
  $4C3E reverted to vanilla `ld a,[wMapID]`) — arm encounters etc. at
  entry; seed the counter with `write_ram2` (drain = 100/step).

**S99 adjudication sweep (tools/audit_mapid_range.py).** The selftest had been
failing since S73 (the tool is not in verify check 5): nine sites added S73-S97
without keys. Verdicts: `BattleExitHandler` (renamed `Jump_050_640a`, cp $5d),
`FreeColor1Hook`, `VanillaExitResolve`, `AnchorField14Tail` (cp $30),
`MenuOpenFreePal`, `BoxAttrActive` = CP_UNSIGNED; `StateRulesHook17` = COPY (A
reloaded for `CustomAttrCheck`, IDX8_SUB6B); `CustomStateRules` = IDX8_SUB6B
(`sub $6B / ret c`). S99 sites: `PerRoomDispatchEntry` = RST00_CLAMPED (`cp $6B /
jr c` → `rst $00` on a vanilla mapID; custom → entry 3's validator-bounded
byte), `CustomAnimSource` = IDX8_SUB6B (bounded). Selftest PASS (clean 58 /
patched 64); `extracted/mapid_range_audit.json` regenerated.
