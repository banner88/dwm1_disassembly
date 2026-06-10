# DWM1 Data Structure Catalog

Single source of truth for every decoded ROM data structure.
Covers: exact addresses, assembly labels, byte-level field formats,
entry counts, cross-references, generator tools, and decode status.

For narrative documentation on how systems work, see the referenced docs.

---

## ROM Data Tables

### Bank $03 — Monster Info Table

| | |
|-|-|
| Address | `$03:$4461` |
| Label | Per-monster labels via generator |
| Entries | 221 × 43 bytes |
| Generator | `tools/gen_monster_db.py` |
| Documentation | `MONSTER_DATA.md` |

**Entry format (43 bytes):**

| Offset | Size | Field | Notes |
|--------|------|-------|-------|
| $00 | 1 | family | 0-9: Slime/Dragon/Beast/Flying/Plant/Bug/Devil/Zombie/Material/Boss |
| $01 | 1 | level_cap | |
| $02 | 1 | exp_table_index | → Bank $13 experience tables (0-31) |
| $03 | 1 | female_ratio | $00=0%, $01≈10%, $02=50%, $03≈84% |
| $04 | 1 | can_fly | 1=floating sprite |
| $05 | 1 | metal_body | 1=Metaly/Metabble/MetalKing only |
| $06 | 3 | base_skills | 3 × skill ID → Bank $41 SkillNamePtrTable, Bank $52 SkillFunctionTable |
| $09 | 6 | growth_indices | HP/MP/ATK/DEF/AGL/INT → Bank $13 growth curves at $6706 |
| $0F | 27 | resistances | 27 types, values 0-3. Order in `MONSTER_DATA.md` |
| $2A | 1 | tier_rank | 0=starter, 3-6=normal, 7=endgame |

**Cross-refs:** `family` → Bank $41 FamilyCodePtrTable. `base_skills` → Bank $16 UnevolvedSkillMap for inheritance.

---

### Bank $13 — Experience Tables

| | |
|-|-|
| Address | `$13:$41E6` |
| Entries | 32 × 297 bytes (99 × 3-byte LE24) |
| Generator | `tools/gen_growth_tables_db.py` |

Record[level] = cumulative EXP for that level. Level 1 always 0.
Selected by monster info byte $02.

---

### Bank $14 — Enemy Stats

| | |
|-|-|
| Address | `$14:$4C1D` |
| Label | Per-enemy labels via generator |
| Entries | 487 × 25 bytes |
| Generator | `tools/gen_enemy_stats_db.py` |

**Entry format (25 bytes):**

| Offset | Size | Field |
|--------|------|-------|
| $00 | 1 | monster_id | → Bank $03 monster info |
| $01-$03 | 3 | unknown |
| $04 | 1 | level |
| $05 | 2 | hp (LE16) |
| $07 | 2 | mp (LE16) |
| $09 | 2 | atk (LE16) |
| $0B | 2 | def (LE16) |
| $0D | 2 | agl (LE16) |
| $0F | 2 | int (LE16) |
| $11-$14 | 4 | unknown |
| $15 | 1 | skill_1 |
| $16 | 1 | skill_2 |
| $17 | 1 | skill_3 |
| $18 | 1 | $FF delimiter |

**Boss redirect table** at `$14:$4893` (`LookupBossRedirect`): variable-length 2-byte ID pairs mapping current enemy → next enemy in scripted multi-monster fights. $FFFF terminated.

---

### Bank $16 — Breeding Tables

| Table | Address | Label | Size | Notes |
|-------|---------|-------|------|-------|
| Unevolved skill map | `$16:$4874` | `UnevolvedSkillMap` | 256 bytes | skill_id → base_skill_id ($FF=uninheritable) |
| Special recipe table | `$16:$4B30` | — | 825 × 5 bytes | $FF terminated |
| Family recipe table | `$16:$4974` | — | Variable | $FFFF-separated groups |

**Special recipe entry (5 bytes):** `[parent1, parent2, min_plus, result, plus_mod]`
Parents: species ID or $F0-$F9 = family code match.

Documentation: `BREEDING_SYSTEM.md`

---

### Bank $16 — Gate Floor System

| Table | Address | Label | Entries | Entry size |
|-------|---------|-------|---------|------------|
| Gate floor data | `$16:$70A6` | `GateFloorDataTable` | 32 | 8 bytes |
| Floor type selection 1 | `$16:$71A6` | `FloorTypeSelectionTable` | 16 | 16 bytes |
| Floor type selection 2 | `$16:$72A6` | `FloorTypeSelectionTable2` | 16 | 8 bytes |
| Floor type selection 3 | `$16:$7326` | `FloorTypeSelectionTable3` | 17 | 16 bytes |
| Floor layout data | `$16:$7436` | `FloorLayoutData` | — | 1120 bytes |
| Floor data ptrs 1 | `$16:$7896` | `FloorDataPtrTable1` | — | 512 bytes |
| Floor data ptrs 2 | `$16:$7A96` | `FloorDataPtrTable2` | — | to bank end |

**GateFloorDataTable entry (8 bytes):**

| Offset | Field | Notes |
|--------|-------|-------|
| 0 | floor_type_1 | → FloorTypeSelectionTable index |
| 1 | floor_type_2 | → FloorTypeSelectionTable2 index |
| 2 | floor_type_3 | → FloorTypeSelectionTable3 index |
| 3 | last_floor | Floor count before boss |
| 4 | boss_room_map_type | → Bank $0B RoomPtrTable |
| 5 | boss_spawn_x | |
| 6 | boss_spawn_y | |
| 7 | boss_tileset | |

**Gate index → name:** 0=Beginning, 1=Villager, 2=Talisman, 3=Memories, 4=Bewilder, 6=Peace, 7=Bravery, 18=Labyrinth, 22=Ambition, 29=Arena Right, 31=Unused(99 floors).

**FloorTypeSelectionTable entries:** cumulative probability thresholds 0-100 ($64). $00=skip, $64=guaranteed. Used by `SelectFloorType` ($16:$5FC0).

---

### Bank $16 — Encounter System

| Table | Address | Label | Entries | Entry size |
|-------|---------|-------|---------|------------|
| Encounter counter | `$16:$6E3D` | `RandomEncounterCounterTable` | 50 | 4 bytes |
| Encounter rate data | `$16:$6FAB` | `EncounterRateData` | 16 | 8 bytes |
| Encounter rate modifier | `$16:$702B` | `EncounterRateModifierTable` | 8 | 1 byte |

**RandomEncounterCounterTable entry (4 bytes):** `[prn_threshold, $00, step_counter_le16]`
PRNG mod 101 compared to threshold. Range: 1100-6000 steps. Last entry $FF=catch-all.

**EncounterRateModifierTable:** `$10, $15, $20, $40, $50, $60, $70, $80`. Indexed by `wC8A9` (from Bank $01 gate floor threshold lookup).

---

### Bank $01 — Encounter Pools & Gate Thresholds

| Table | Address | Label | Notes |
|-------|---------|-------|-------|
| Gate base pool index | `$01:$6A22` | `GateBasePoolIndex` | 32 bytes, gate → pool offset |
| Gate floor breakpoint ptrs | `$01:$6A42` | `GateFloorBreakpoints` | 32 × dw, → threshold lists |
| Floor breakpoint data | `$01:$6A82` | `FloorBreakpointData` | Variable, $FF terminated |
| Encounter pool data | `$01:$6AAE` | `EncounterPoolData` | 128 × 26 bytes |
| Generator | | `tools/gen_encounter_db.py` | |

**Encounter pool entry (26 bytes):** `[header:10][eid_slots:5×2B_LE16][weights:5×1B][extra:1]`

---

### Bank $0B — Room Data

| | |
|-|-|
| Address | `$0B:$4B43` |
| Label | `RoomPtrTable` |
| Entries | 107 map types × variable rooms |
| Generator | `tools/gen_room_data_db.py --apply` |
| Documentation | `ROOM_DATA_FORMAT.md` |

**Pointer chain:** `RoomPtrTable[mapID×2]` → sub-table → `[wram_ptr:2][step_ptr:2][room_entries...]`

**Exit/NPC entry (7 bytes):** `[type, behavior, x, y, gate_id, spawn_x_off, spawn_y_off]`
Upper nibble of type: $9x=exit, $0x/$Fx=NPC. Documentation: `ROOM_DATA_FORMAT.md`, `ROUTING.md`.

---

### Bank $17 — Palette/Attribute System

| Table | Address | Label | Entries |
|-------|---------|-------|---------|
| Attr ptr table | `$17:$476F` | `AttrPtrTable` | 107 × dw |
| Per-room attr data | `$17:$483F-$5214` | `RoomAttr_*` (92 labels) | Variable |
| Gate attr table A | `$17:$5215` | `GateAttrTable_A` | 256 × 2 bytes |
| Gate attr table B | `$17:$5415` | `GateAttrTable_B` | 256 × 2 bytes |

**Per-room structure:** AttrPtrTable[mapID] → screen table (pointer pairs per screen slot) → attribute entries `[wram_addr:2] + steps × [attr_idx:1, attr_bank:1, pal_ptr:2]`.

Status: pointer tables labeled, 92 RoomAttr_* labels in data section, internal byte parsing NOT done.

---

### Bank $41 — Name & Text Tables

| Table | Address | Label | Entries | Points to |
|-------|---------|-------|---------|-----------|
| Monster name ptrs | `$41:$4339` | `MonsterNamePtrTable` | 256 × dw | `MonsterNameStrings` ($5B1F) |
| Skill name ptrs | `$41:$4539` | `SkillNamePtrTable` | 256 × dw | `SkillNameStrings` ($628E) |
| Family code ptrs | `$41:$4739` | `FamilyCodePtrTable` | 215 × dw | `FamilyCodeStrings` ($69F2) |
| Item name ptrs | `$41:$48E7` | `ItemNamePtrTable` | 44 × dw | `ItemNameStrings` ($6C78) |
| Item desc ptrs | `$41:$493F` | `ItemDescPtrTable` | 44 × dw | `ItemDescStrings` ($6DF8) |
| Personality ptrs | `$41:$4997` | `PersonalityNamePtrTable` | 27 × dw | `PersonalityNameStrings` ($7159) |
| Misc text ptrs | `$41:$49CD` | `MiscTextPtrTable` | 37 × dw | Dispatch text |
| Watabou text ptrs | `$41:$4A17` | `WatabouTextPtrTable` | 2 × dw | Dispatch text |
| Item use text ptrs | `$41:$4A1B` | `ItemUseTextPtrTable` | 48 × dw | Dispatch text |
| Spell use text ptrs | `$41:$4A7B` | `SpellUseTextPtrTable` | 12 × dw | Dispatch text |
| Generator | | `tools/gen_name_tables_db.py`, `tools/gen_bank41_remaining_db.py --apply` | |

All strings $F0 terminated. 222 valid entries (0-221); entries 222-255 point to empty.
Text encoding: `charmap.asm`. Control codes/DTE: `TEXT_SYSTEM.md`.

**Personality index formula:** `id = idx(Charge)*9 + idx(Cautious)*3 + idx(Mixed)` where `idx(x) = 0 if x≥$C0, 1 if $40≤x<$C0, 2 if x<$40`.

---

### Bank $52 — Skill Function Table

| | |
|-|-|
| Address | `$52:$4011` |
| Label | `SkillFunctionTable` |
| Entries | 222 valid (256 nominal) × dw |
| Generator | `tools/gen_skill_table_db.py` |

Entries 222-255 overlap with handler code (same trick as Bank $41).
115 named handler labels (SkillBlaze, SkillSleep, etc.).
9 family checks: `CheckIsSlime` through `CheckIsMaterial` ($52:$6304-$6373).
7 math helpers: `BCsrl3`/`2`/`1`, `HLsrl4`/`3`/`2`/`1` ($52:$6B2A-$6B43).

---

### Banks $50/$57 — Personality Adjustment Tables

| Label | Address | Plan |
|-------|---------|------|
| `PersonalityRunTable` | `$50:$59B6` | Run |
| `PersonalityChargeTable` | `$57:$70A9` | Charge |
| `PersonalityMixedTable` | `$57:$70C9` | Mixed |
| `PersonalityCautiousTable` | `$57:$70E9` | Cautious |
| `PersonalityCommandTable` | `$57:$7109` | Command |

All 8 rows × 4 signed bytes: `[charge_adj, mixed_adj, cautious_adj, motivation_adj]`.
Row = `(motivation≥151 ? 4 : 0) + (level≥30 ? 3 : level≥20 ? 2 : level≥10 ? 1 : 0)`.
Fight plan makes no adjustments.

---

### Tileset Banks (14 banks)

LZSS compressed tile data with pointer tables.
Generator: `tools/gen_tileset_banks.py --apply`.
Compression: `tools/decompress_tiles.py`, `tools/compress_tiles.py`.
Renderer: `tools/render_rooms.py`.

---

## Named Functions

### Bank $00 — Core Utilities

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `GenerateRNG` | $12D0 | — | `wC899:wC89A = old × 5 + $1357` |
| `Mul8x8To16` | $1DBE | — | `HL = A × C` |
| `Mul16x8To24` | $1DE6 | — | `E:HL = BC × A` |
| `Div8x8` | $1DFB | 91 | `B = B // A; A = B % A` |
| `Div16x8To16` | $1E0D | — | `HL = HL // A; A = HL % A` |
| `Div24x8To16` | $1E1E | — | `HL = E:HL // A; A = E:HL % A` |
| `CmpHLvsBC` | $2F45 | — | Compare HL vs BC |
| `Div16x16To16` | $2F4B | — | `DE = HL // BC; BC = HL % BC` |
| `GetMonsterDataPtr` | $223B | 328 | `HL = HL + (A&$7F) × $95` — monster struct ptr |
| `GetCurrentMonsterPtr` | $2229 | 97 | Resolve context → monster struct ptr |
| `ReadMonsterByte` | $224A | 67 | Byte from current monster → A |
| `ReadMonsterWord` | $224F | 87 | Word from current monster → BC |
| `CheckMonsterSlot` | $2FA5 | 308 | Check slot A valid; CF=valid |
| `GetMonsterSlotInfo` | $2F76 | 30 | Slot lookup via CheckMonsterSlot |
| `HL_AddA_x8` | $2F6C | 270 | `HL += A × 8` |
| `WaitVRAM` | $1AA6 | 119 | LCD STAT wait for VRAM access |
| `WaitDMATransfer` | $1577 | 128 | Busy-wait $DA78 == 0 |
| `WaitLCDTransfer` | $14CF | 63 | Busy-wait LCD transfer |
| `SetupTilemapTransfer` | $096D | 114 | Store VRAM transfer source/dest |
| `SetupVRAMParams` | $097A | 56 | Store VRAM transfer params |
| `SetupVRAMCopy` | $098F | 19 | Store HL/DE as copy params |
| `Copy4Bytes` | $0C80 | 66 | Copy 4 bytes DE→HL |
| `SetGBCPalette` | $1688 | 64 | Set palette, GBC color mode |
| `EnableSRAM` | $20EE | 48 | SRAM access on |
| `DisableSRAM` | $1013 | 41 | SRAM access off |
| `RequestScreenUpdate` | $0609 | 34 | Set screen refresh flag |
| `WaitInputRelease` | $1E31 | 23 | Wait for button release |
| `UpdateOAMSprites` | $2518 | 22 | Update sprite OAM |
| `CallTextEngine` | $05B6 | 24 | Cross-bank to Bank $56 |
| `RunTextHandler` | $05F6 | 25 | Text display handler |
| `HandleTextCharacter` | $07AB | — | Process text control codes |
| `ReadNextTextByte` | $0D78 | — | Read from text stream |
| `PrintNumber` | $20AD | 16 | Format/print number |
| `ConvertNumberToText` | $1FB9 | 16 | Number → text digits |
| `ExtractDigits` | $09A4 | 16 | Decimal digit extraction |
| `PrintDigit` | $20DF | 14 | Print single digit |
| `SerialTransfer` | $1275 | 17 | Link cable transfer |
| `SetBGM` | $1AE1 | — | Store BGM offset |
| `InitBGM` | $1AE5 | — | Full BGM init with audio setup |
| `LoadSE` | $1B30 | — | Load sound effect |
| `ProcessBGMQueue` | $1BB1 | — | Process queued BGM/SE |

### Other Banks

| Label | Bank:Address | Refs | Purpose |
|-------|-------------|------|---------|
| `LoadNextDungeonFloor` | $01:$69E1 | — | Gate floor progression |
| `CopyPlayerCoordsAndGetNextRoom` | $01:$55D7 | — | Room transition |
| `MapTypeDispatch` | $04:$71EF | — | Route to script banks $0C-$0F |
| `GetRoomDataPtr` | $0B:$4274 | — | Room data pointer lookup |
| `SearchNPCAtFacing` | $0B:$43B8 | — | Find NPC at player facing pos |
| `CheckExitCoords` | $0B:$4452 | — | Coordinate match for exits |
| `AddCursorOffset` | $12:$441F | 82 | UI cursor offset calc |
| `GetScreenPos` | $12:$40E5 | 62 | Screen position from RAM |
| `ReadPtrFromDE` | $12:$40B4 | 44 | Read 2-byte ptr from [DE] |
| `LoadEnemyStats` | $14:$4849 | — | Copy enemy stats from table |
| `LookupBossRedirect` | $14:$4869 | — | Multi-monster battle redirect |
| `SetRandomEncounterCounter` | $16:$6E14 | — | PRNG → step counter |
| `SelectFloorType` | $16:$5FC0 | — | Probability threshold selection |
| `LoadFloorDataPointer` | $16:$7033 | — | Floor data table lookup |
| `ClearSpriteBuffer` | $50:$774E | 40 | Clear sprite RAM |
| `ClearTileBuffer` | $50:$768E | 33 | Clear tile RAM |
| `LoadPaletteFromDE` | $50:$75F0 | 32 | Load palette data |
| `UpdateBattleSprites` | $50:$79B4 | 31 | Battle sprite update |
| `LoadBattleGraphics` | $50:$794C | 30 | Battle gfx init |
| `LoadArenaEnemyStats` | $50:$66D3 | — | Arena enemy setup |
| `LoadBattle` | $51:$4027 | — | Full battle init |
| `LoadEnemyStatsForBattle` | $51:$4627 | — | Enemy stat load for battle |
| `ProcessBattleTurn` | $51:$736A | 32 | Battle turn processing |
| `HL_AddA_x2` | $52:$6AB8 | 62 | `HL += A × 2` |
| `SetSkillAnimFlag` | $52:$548D | 43 | Set skill animation |
| `ApplySkillDamage` | $52:$545D | 32 | Apply damage from skill |
| `CheckSkillResistance` | $52:$54EA | 30 | Check target resistance |
| `ClearBattleAction` | $57:$45E4 | 68 | Reset battle action state |
| `AddBToHL16` | $57:$455F | 65 | `[HL] += B` (16-bit) |

---

## Cross-Reference Map

```
Monster ID ($00-$DC)
  ├─ Bank $03:$4461  monster info (family, skills, resistances, growth)
  ├─ Bank $41:$4339  MonsterNamePtrTable → name string
  ├─ Bank $41:$4739  FamilyCodePtrTable → 2-char family code
  ├─ Bank $13:$41E6  exp_table_index → EXP curve
  └─ Bank $14:$4C1D  enemy stats entries (monster_id field)

Skill ID ($00-$DD)
  ├─ Bank $52:$4011  SkillFunctionTable → handler code
  ├─ Bank $41:$4539  SkillNamePtrTable → name string
  └─ Bank $16:$4874  UnevolvedSkillMap → base skill for inheritance

Gate ID ($00-$1F)
  ├─ Bank $16:$70A6  GateFloorDataTable → floor config, boss room
  ├─ Bank $01:$6A22  GateBasePoolIndex → encounter pool offset
  ├─ Bank $01:$6A42  GateFloorBreakpoints → floor thresholds
  └─ Bank $0B:$4B43  RoomPtrTable → room/exit/NPC data

Map Type → Room → Visuals
  ├─ Bank $0B:$4B43  RoomPtrTable → room data, exits, NPCs
  ├─ Bank $17:$476F  AttrPtrTable → palette/attribute data
  └─ Tileset banks   → LZSS compressed tile graphics
```

---

## Generator Tools

| Tool | Output | Bank(s) | Idempotent | Flag |
|------|--------|---------|------------|------|
| `gen_monster_db.py` | Monster info | $03 | Yes | — |
| `gen_enemy_stats_db.py` | Enemy stats | $14 | Yes | — |
| `gen_encounter_db.py` | Encounter pools | $01 | Yes | — |
| `gen_skill_table_db.py` | Skill function table | $52 | Yes | — |
| `gen_name_tables_db.py` | Monster/skill names | $41 | Yes | — |
| `gen_bank41_remaining_db.py` | Remaining Bank $41 | $41 | Yes | `--apply` |
| `gen_room_data_db.py` | Room data | $0B | Yes | `--apply` |
| `gen_tileset_banks.py` | Tileset data | 14 banks | Yes | `--apply` |
| `gen_growth_tables_db.py` | Growth/EXP tables | $13 | Yes | — |
| `annotate_bank052.py` | Skill handler labels | $52 | **No** | one-time |

---

## Decode Status

| Bank | Data | Code | Notes |
|------|------|------|-------|
| $00 | — | 89 named / 545 remaining | Core utility functions |
| $01 | ✅ | Partial | Encounters, gate thresholds done |
| $03 | ✅ | — | Monster info fully annotated |
| $04 | — | Partial | Script engine: see `BANK04_SCRIPT_ENGINE.md` |
| $0B | ✅ | Partial | Room data done |
| $13 | ✅ | — | EXP/growth tables done |
| $14 | ✅ | Partial | Enemy stats done |
| $16 | ✅ | Partial | All data tables done this session |
| $17 | Partial | Partial | Ptr tables + 92 room labels; byte parsing NOT done |
| $41 | ✅ | ✅ | 100% annotated |
| $50 | Partial | Partial | Personality Run table; battle event functions |
| $51 | — | Partial | Battle init labeled |
| $52 | ✅ | Partial | Function table + handlers labeled |
| $57 | Partial | Partial | Personality Charge/Mixed/Cautious/Command; battle |
| Tilesets | ✅ | — | 14 banks LZSS tile data |

---

## Related Documentation

| File | Covers |
|------|--------|
| `ARCHITECTURE.md` | Bank map, RST dispatch, RAM regions, free space |
| `BANK04_SCRIPT_ENGINE.md` | Script VM: 100 opcodes, state machine, data flow |
| `BREEDING_SYSTEM.md` | Recipe tables, algorithm, mutation system |
| `CROSSBANK_ROOMS.md` | Custom room creation technique |
| `EVENT_FLAGS.md` | Flag bitfield, story progression flags, script commands |
| `MONSTER_DATA.md` | Monster info fields, resistance types, growth curves |
| `ROOM_DATA_FORMAT.md` | Room pointer chains, exit/NPC entry format |
| `ROUTING.md` | Room transitions, 5 code paths, spawn table |
| `TEXT_SYSTEM.md` | Charmap encoding, DTE pairs, control codes |
| `known_RAM_map.md` | Community WRAM documentation |
| `known_ROM_map.md` | Community ROM map (source for much of this work) |
