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

### 1. Bank $00 — 79 More Functions Named (149 total, 466 remaining)
Named 79 additional functions across multiple tiers (22 refs down to 4 refs). Key categories:
- **Battle stat readers** (7 functions): Fixed incorrect `ReadEventFlags2`/`3` → `GetCombatantHP`/`DEF`/`ATK`/`MaxHP`/`MaxMP`/`MP` + `IndexPtrTable`. Reads per-combatant stats from WRAM tables ($DBA3-$DBF3).
- **Event flags** (4): `SetEventFlag`, `ClearEventFlag`, `TestEventFlag`, `ComputeFlagAddress`.
- **Monster stat math** (8): `SaturatingAdd16`/`Subtract16`, `MonsterStatAdd`/`Subtract`/`Decrement`, context wrappers.
- **Active monster** (5): `GetActiveMonsterPtr`, `ReadActiveMonsterByte`/`Word`, `GetMonsterSkillData`, `GetMonsterSlotContext`.
- **LCD/Video/SGB** (15): BG map, scroll, STAT, SGB packet/tiles/delay, palette, viewport, OAM, sprites.
- **Text/Display** (11): Text bank switching, digit formatting, tilemap ops, text renderer call.
- **SRAM/Save** (4): `CopySRAMBlock`, `CopyFromSRAM`, `SavePartyToSRAM`, `SaveGameState`.
- **Audio** (3): Init, flag check, register write.
- **Script/Dispatch** (5): `RunScriptEngine`, `CallScriptByType`, `CrossBankCallRet`, `DispatchCD90`, `TextBankDispatch`.
- **Gold** (2): `AddGold`, `CompareGold`.
- **Math** (3): `DivBCbyDE`, `ExtractDigit16`, `ComputeTileDataAddr`.

### 2. WRAM Symbol Expansion — 81 unique symbols, 4676 refs
Added 60 new WRAM labels in wram.asm with 2546 hex→symbol replacements. Key additions:
- **Battle stat tables** (9): `wBattleHP` through `wBattleLVL` ($DBA3-$DC23), 16 bytes each.
- **Battle indices** (2): `wBattleAttackerIdx` (686 refs), `wBattleTargetIdx` (575 refs).
- **Script engine** (8): `wScriptMapType`, `wScriptCounter` (205 refs), `wScriptStateFlags` (114 refs), etc.
- **Gate/floor system** (8): `wFloorType1`-`3`, `wCurrentFloor`, `wLastFloor`, `wBossMapType`, `wBossTileset`.
- **Warp destination** (6): `wWarpGateId`, `wWarpSpawnXLo`/`Hi`/`YLo`/`YHi` (34 refs each).
- **Event/state** (4): `wEventStateMachineIndex` (155 refs), `wEventFlags`, `wBattlePostFlag` (86 refs).
- **Arena/encounter** (5): `wColiseumBattle`, `wArenaGroup`, `wEncounterPoolIndex`, `wScreenIndex` (62 refs).
- **Temp workspace** (8): `wTempEnemyId1` (46 refs), `wTempEnemyStatsId` (40 refs), `wTempSpeciesId` (38 refs), breeding vars.

### 3. ROM Map Cross-Reference
Applied community ROM map intelligence to name 3 additional cross-bank functions:
- `ArenaGenerateBattles` (Bank $04:$5B1B)
- `ColiseumInitPrize` (Bank $04:$6D93)
- `LoadScriptRoomData` (Bank $0F:$4007)

### 4. Documentation Updated
DATA_STRUCTURES.md Bank $00 section fully reorganized by category. All decode counts current.

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
| $00 | 149 | 466 remaining | Monster access, VRAM, math, text, SRAM, battle stats, gold, events, SGB |
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
1. **More Bank $00 function naming** — 466 Call_ labels remain. Next tier
   (3-4 refs) includes ~80 more functions. Data tables at $0515/$0aea/$2bcc
   need investigation (misinterpreted as code by mgbdis).
2. **Bank $17 per-room data parsing** — 92 labels added but data is still
   raw hex. Parser could decode screen tables vs attribute entries.
3. **Bank $04 script engine** — 100 opcodes documented but code still
   has auto-generated labels throughout.

### MEDIUM PRIORITY  
4. **Bank $52 skill handler code annotation** — handlers labeled but the
   actual damage calc, resistance check, and effect code is uncommented.
5. **Bank $57 battle dispatch** — core battle flow code.
6. **More WRAM expansion** — 81 symbols / 4676 refs done. More $C8xx/$C9xx
   game state variables can be decoded from context.

### LOWER PRIORITY
7. NPC behavior values (lower nibble specific meanings)
8. Collision data system (what makes tiles walkable)
9. GUI editor (DATA_STRUCTURES.md provides the schema)
9. GUI editor (DATA_STRUCTURES.md provides the schema)

## Key Documentation
- `documentation/DATA_STRUCTURES.md` — Canonical data structure catalog
- `documentation/ROOM_DATA_FORMAT.md` — Room data format reference
- `documentation/BREEDING_SYSTEM.md` — Breeding recipe system
- `documentation/TEXT_SYSTEM.md` — Text encoding and control codes
- `documentation/SESSION_HANDOFF.md` — This file
