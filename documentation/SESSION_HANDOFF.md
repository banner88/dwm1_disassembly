# DWM1 ROM Hack — Session Handoff

## Build Verification
```bash
cd disassembly
rm -f game.o game.gbc game.sym game.map
make
md5sum game.gbc
# MUST output: 1ca6579359f21d8e27b446f865bf6b83
```
**NEVER run `make clean`** — deletes committed `.2bpp` graphics files that
cannot be regenerated with matching bytes.

## What Was Completed This Session

### 1. Bank $16 — All Data Tables Annotated (biggest win)
Converted ~3930 lines of misinterpreted code to properly labeled `db` blocks.
Bank went from 9092 to 5477 lines. 12 new data labels with full documentation.
See DATA_STRUCTURES.md for complete field formats.

### 2. Bank $00 — 32+ Core Functions Named
Named the most-called utility functions. ~2300 call site references updated
across all bank files. Top hits: GetMonsterDataPtr (328 refs), CheckMonsterSlot
(308), HL_AddA_x8 (270), WaitDMATransfer (128), WaitVRAM (119).

### 3. Cross-Bank Function Labels (~15 functions, ~700 refs)
Named top functions in banks $12, $50, $51, $52, $57 including battle system
(ClearBattleAction, ProcessBattleTurn, ApplySkillDamage), UI (AddCursorOffset),
and sprite management (ClearSpriteBuffer, LoadPaletteFromDE).

### 4. Banks $50/$57 — Personality Adjustment Tables
All 5 plan tables labeled: PersonalityRunTable, PersonalityChargeTable,
PersonalityMixedTable, PersonalityCautiousTable, PersonalityCommandTable.

### 5. Bank $17 — 92 Per-Room Attribute Labels
Added RoomAttr_* labels throughout per-room data ($4845-$5214).
AttrPtrTable entries converted from raw hex to label references.

### 6. ROM Map Functions Labeled (Banks $01/$04/$0B/$14)
LoadNextDungeonFloor, MapTypeDispatch, GetRoomDataPtr, SearchNPCAtFacing,
CheckExitCoords, LoadEnemyStats, LookupBossRedirect, LoadBattle, etc.

### 7. DATA_STRUCTURES.md — Comprehensive Catalog Created
Machine-readable catalog of every decoded data structure. Designed as
the schema for a future GUI editor.

## All Completed Work (All Sessions Combined)

### Fully Annotated Data Banks
| Bank | Contents | Labels | Status |
|------|----------|--------|--------|
| $03 | Monster info table (221x43B) | ~250 | Done |
| $0B | Room data system ($4B43-$7FFF) | ~800 | Done |
| $13 | EXP curves + growth tables | ~100 | Done |
| $14 | Enemy stats (487x25B) + boss redirect | ~500 | Done |
| $16 | Breeding + gate floor system | 234 | Done (this session) |
| $17 | Palette/attribute tables | ~210 | Ptr tables + 92 room attr labels (this session) |
| $41 | ALL name/text tables + strings | 933 | Done |
| $52 | Skill functions + battle system | 912 | Done |
| 14 tileset banks | LZSS tile data pointer tables | ~500 | Done |

### Named Functions by Bank
| Bank | Named | Total Call_ | Key Functions |
|------|-------|-------------|---------------|
| $00 | 89 | 545 remaining | Monster access, VRAM, math, text, SRAM |
| $01 | 5+ | | LoadNextDungeonFloor, encounter system |
| $04 | 3+ | | MapTypeDispatch, script engine |
| $0B | 5+ | | Room loading, NPC search, exits |
| $12 | 3 | | UI cursor, screen position |
| $14 | 2 | | LoadEnemyStats, LookupBossRedirect |
| $16 | 3 | | SetRandomEncounterCounter, SelectFloorType |
| $50 | 6+ | | Battle sprites, palettes, arena |
| $51 | 3 | | LoadBattle, ProcessBattleTurn |
| $52 | 5+ | | Skill damage, resistance, animation |
| $57 | 2 | | ClearBattleAction, AddBToHL16 |

## NOT Done — Priority Work for Next Session

### HIGH PRIORITY
1. **More Bank $00 function naming** — 545 Call_ labels remain. Next tier
   (~20-10 calls each) includes menu system, event handling, sprite/tile ops.
2. **Bank $17 per-room data parsing** — 92 labels added but data is still
   raw hex. Parser could decode screen tables vs attribute entries.
3. **Bank $04 script engine** — 100 opcodes documented but code still
   has auto-generated labels throughout.

### MEDIUM PRIORITY  
4. **Bank $52 skill handler code annotation** — handlers labeled but the
   actual damage calc, resistance check, and effect code is uncommented.
5. **Bank $57 battle dispatch** — core battle flow code.
6. **WRAM symbol expansion** — add floor-type, encounter, and battle vars.

### LOWER PRIORITY
7. NPC behavior values (lower nibble specific meanings)
8. Collision data system (what makes tiles walkable)
9. GUI editor (DATA_STRUCTURES.md provides the schema)

## Key Documentation
- `documentation/DATA_STRUCTURES.md` — Canonical data structure catalog
- `documentation/ROOM_DATA_FORMAT.md` — Room data format reference
- `documentation/BREEDING_SYSTEM.md` — Breeding recipe system
- `documentation/TEXT_SYSTEM.md` — Text encoding and control codes
- `documentation/SESSION_HANDOFF.md` — This file
