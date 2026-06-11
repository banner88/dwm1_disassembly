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
| Documentation | `ROOM_DATA_FORMAT.md`, `CROSSBANK_ROOMS.md` |

**Code section refactored:** 4 duplicated pointer-chase functions consolidated into `SharedPtrChase`. 119 bytes freed at $4ACC-$4B42. Data section pinned at $4B43 via separate SECTION directive.

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

**Per-step attribute entry (4 bytes):** `[attr_idx:1, attr_bank:1, pal_ptr:2]`
Bank $3C = primary attribute bank (239 unique maps). 89 unique palettes at $565D-$7F61.
Palette format: 32 bytes raw GBC RGB555 → WRAM $C797+ (BG) via `Call_017_46a1`.

**Parser:** `tools/analyze_bank17.py` (`--room`, `--palettes`)

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

### Banks $0C/$0D/$0E/$0F — NPC Script Data

| Bank | Map Types | Scripts | Labels | Generator |
|------|-----------|---------|--------|-----------|
| $0C | $00–$05 (Castle, GreatTree, Bazaar, GateHub, Farm, Stable) | 129 | 452 | `tools/gen_script_banks.py --apply` |
| $0D | $06–$1F (Arena, GateTileset, CopycatRoom, MedalMan, Well, etc.) | 168 | 614 | same |
| $0E | $20–$3F (Gate entrance rooms, boss rooms for first gates) | 130 | 287 | same |
| $0F | $40–$5F (Late-game boss rooms, post-game content) | 103 | 273 | same |
| **Total** | **All 96 map types** | **530** | **1,626** | |

Documentation: `BANK04_SCRIPT_ENGINE.md`

**Data layout per bank:**

All 4 banks share identical code ($4000–$41B9). Data begins at $41BA:

| Region | Description |
|--------|-------------|
| $41BA + map_type×2 | Master pointer table (indexed by ABSOLUTE map type, not relative) |
| Per-map tables | Variable-size dw arrays: `script_id → script_data_ptr` |
| Script data | Packed sequences of dw words, one per script + branch target blocks |

Master table indexing: the script engine reads `$41BA + $D8D3 × 2` where `$D8D3` is the raw map type. Banks $0E/$0F use offsets $40+ into the master table, not from offset 0.

**Script data word format:**

| Value | Meaning |
|-------|---------|
| `$FFxx` where xx < $64 | Script opcode (100 commands, see BANK04_SCRIPT_ENGINE.md) |
| `$FFFF` | Script end marker |
| `$4xxx`–`$7xxx` (odd-aligned) | Branch target address (label reference in assembly) |
| Other values | Text ID or opcode parameter (event flag ID, delay count, NPC index, etc.) |

**Alignment:** Script data uses odd byte alignment (scripts packed back-to-back, most start at odd addresses). The generator handles this by tracking word boundaries per-script.

**Label scheme:** `{MapName}_ScriptPtrTable`, `{MapName}_Script{NN}`, `Bank{XX}_ScriptAddr_{XXXX}` for branch targets.

**Cross-refs:** Script opcodes dispatch via bank $04's VM.

**Verified Script Opcodes (22 confirmed via SameBoy + visual trace):**

| Opcode | Params | Name | Description |
|--------|--------|------|-------------|
| $00 | 2 | if_flag_clear | Branch if event flag NOT set |
| $01 | 2 | if_flag_set | Branch if event flag IS set |
| $02 | 1 | clear_flag | Clear event flag in $D99B+ |
| $03 | 1 | set_flag | Set event flag in $D99B+ |
| $07 | 1 | init_dialog | Set dialogue mode, suppress input |
| $08 | 0 | nop | No operation |
| $09 | 1 | delay | Wait N frames (low byte) |
| $0A | 2 | npc_move_x | Instant horizontal move |
| $0B | 2 | npc_move_y | Instant vertical move |
| $0D | 3 | npc_write | Write byte to NPC buffer |
| $0E | 2 | branch_by_screen | Branch on screen index |
| $12 | 2 | write_ram | Write value to RAM address (335 uses) |
| $19 | 0 | wait_movement | Pause until movement completes |
| $1A | 2 | npc_walk_x | Animated horizontal walk |
| $1B | 2 | npc_walk_y | Animated vertical walk |
| $1C | 1 | trigger_anim | Animation ($01XX=jump NPC XX) |
| $1D | 0 | lock_movement | Suppress NPC facing |
| $1E | 0 | unlock_movement | Restore NPC facing |
| $22 | 0 | begin_walk | Start walk-toward sequence |
| $47 | 1 | npc_set_state | Set NPC sprite state |
| $48 | 1 | npc_hide | Hide NPC sprite |
| $49 | 1 | npc_show | Show NPC sprite |

All 100 opcodes decoded (0 unknowns across 5,377 commands in 530 scripts).
Full reference: `CUSTOM_CUTSCENES.md`. Parameter counts: `tools/decompile_script.py`.

**Player control:** Automatic. ScriptInit sets $D8D7 bit 0 (script active) →
player input suppressed. Script `end` ($FFFF) clears $D8D7 → control returns. Text IDs route through ROM0 `$0AD9` → handler banks $42–$4E → data banks $18/$1A/$1B/$1F/$21/$22/$3F. Event flags live in $D99B+ bitfield (see EVENT_FLAGS.md). NPC script_id is set in room data (Bank $0B) NPC entries.

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

### Bank $00 — Core Utilities (149 named, 466 remaining)

**Math/Comparison:**

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
| `DivBCbyDE` | $0ABF | 7 | Repeated-subtract division: `H = BC // DE` |
| `ExtractDigit16` | $20BE | 7 | Repeated-subtract digit extraction for 16-bit |
| `SaturatingAdd16` | $2482 | — | `[HL] = min([HL]+DE, BC)` — clamped 16-bit add |
| `SaturatingSubtract16` | $2496 | — | `[HL] = max([HL]-DE, BC)` — clamped 16-bit sub |

**Monster Data Access:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `GetMonsterDataPtr` | $223B | 328 | `HL = HL + (A&$7F) × $95` — monster struct ptr |
| `GetCurrentMonsterPtr` | $2229 | 97 | Resolve context → monster struct ptr |
| `ReadMonsterByte` | $224A | 67 | Byte from current monster → A |
| `ReadMonsterWord` | $224F | 87 | Word from current monster → BC |
| `WriteMonsterWord` | $225D | 10 | Write BC to current monster struct |
| `GetActiveMonsterPtr` | $2266 | 6 | Resolve active monster ptr from party index table |
| `ReadActiveMonsterByte` | $2284 | 6 | Read byte from active monster struct |
| `ReadActiveMonsterWord` | $2289 | 5 | Read word from active monster struct → BC |
| `GetMonsterSkillData` | $22A0 | 6 | Get skill/status data for monster slot |
| `CheckMonsterSlot` | $2FA5 | 308 | Check slot A valid; CF=valid |
| `GetMonsterSlotInfo` | $2F76 | 30 | Slot lookup via CheckMonsterSlot |
| `GetMonsterSlotContext` | $2208 | 8 | Resolve monster slot for battle vs overworld |
| `MonsterStatAddContext` | $2442 | 12 | Context-aware monster stat add wrapper |
| `MonsterStatSubContext` | $2462 | 12 | Context-aware monster stat subtract wrapper |
| `MonsterStatAdd` | $2448 | 8 | Add DE to monster stat, cap at BC |
| `MonsterStatSubtract` | $2468 | 8 | Subtract DE from monster stat, floor at BC |
| `MonsterStatDecrement` | $2331 | 10 | Subtract 1 from monster stat |
| `HL_AddA_x8` | $2F6C | 270 | `HL += A × 8` |

**Battle Stat Readers:**

Six functions that read per-combatant stats from WRAM lookup tables ($DBA3-$DBF3). Each takes combatant index in A, returns stat value in HL via `IndexPtrTable`.

| Label | Address | Refs | WRAM Table | Stat |
|-------|---------|------|------------|------|
| `GetCombatantHP` | $2FE8 | 21 | $DBA3 | Current HP |
| `GetCombatantMaxHP` | $2FDA | 11 | $DBB3 | Max HP |
| `GetCombatantMP` | $2FEF | 9 | $DBC3 | Current MP |
| `GetCombatantMaxMP` | $2FE1 | 10 | $DBD3 | Max MP |
| `GetCombatantATK` | $2FCC | 14 | $DBE3 | Attack |
| `GetCombatantDEF` | $2FD3 | 20 | $DBF3 | Defense |
| `IndexPtrTable` | $2FF6 | 7 | — | `HL = [HL + A×2]` — underlying lookup |

Tables initialized by Bank $51 battle setup. Each table holds 16 bytes (up to 8 combatants × 2 bytes). HP/MaxHP and MP/MaxMP pairs start at same value; HP/MP get modified during battle.

**Gold:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `AddGold` | $2424 | 9 | Add CDE to wCurrGoldLo (24-bit) |
| `CompareGold` | $241A | 5 | Compare CDE against wCurrGoldLo |

**LCD/Video:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `WaitVRAM` | $1AA6 | 119 | LCD STAT wait for VRAM access |
| `WaitDMATransfer` | $1577 | 128 | Busy-wait $DA78 == 0 |
| `WaitLCDTransfer` | $14CF | 63 | Busy-wait LCD transfer |
| `GetBGMapAddress` | $25F1 | 16 | Compute VRAM BG map addr from scroll position |
| `ApplyScrollRegisters` | $122F | 13 | Write SCX/SCY/WX/WY shadow regs to LCD |
| `ClearSTATMode` | $1264 | 10 | Clear STAT interrupt mode bits |
| `EnableLYCInterrupt` | $125D | 7 | Set STAT LYC interrupt enable |
| `SetGBCPalette` | $1688 | 64 | Set palette, GBC color mode |
| `SetViewportParams` | $164B | 7 | Store HL and HL+BC to viewport shadow regs |
| `ClearOAMBuffer` | $1417 | 7 | Clear OAM sprite buffer ($C000-$C09F) |
| `TransferSGBPacket` | $113E | 10 | SGB data packet transfer (checks wIsSGB) |
| `SetColorMode` | $1C89 | 6 | Set color mode, update SGB palette if needed |
| `LoadSGBTiles` | $10E5 | 6 | Load tile data for SGB border |
| `SGBDelay` | $10CF | 6 | SGB timing delay loop |
| `ClearPaletteBuffer` | $11BC | 6 | Clear 16-byte palette buffer at $C777 |
| `SetViewportEnd` | $1659 | 5 | Store HL to viewport end shadow regs (ff_b3/b4) |
| `WriteVRAMByte` | $1AAF | 5 | Wait STAT, write A to [HL], enable interrupts |
| `GetSpriteAddress` | $1E8D | 5 | Compute OAM sprite address from index |

**Tilemap/VRAM:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `SetupTilemapTransfer` | $096D | 114 | Store VRAM transfer source/dest |
| `SetupVRAMParams` | $097A | 56 | Store VRAM transfer params |
| `SetupVRAMCopy` | $098F | 19 | Store HL/DE as copy params |
| `Copy4Bytes` | $0C80 | 66 | Copy 4 bytes DE→HL |
| `AdjustTilemapOffset` | $0CFD | 9 | Add scroll offset to HL for tilemap |
| `TilemapNextColumn` | $0CEE | 8 | Increment L within 32-col tile row (wrapping) |
| `TilemapAdvanceColumns` | $0CE7 | 6 | Advance B columns (loop TilemapNextColumn) |
| `GetTilemapRowAddr` | $0D11 | 6 | Compute scroll-relative tilemap row address |
| `GetTilemapByte` | $0954 | 9 | Read byte from tilemap pointer, increment |
| `LookupDoublePtrTable` | $093D | 8 | 2D table lookup: A indexes row, $c823 indexes col |

**Text/Display:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `CallTextEngine` | $05B6 | 24 | Cross-bank to Bank $56 |
| `RunTextHandler` | $05F6 | 25 | Text display handler |
| `SetupTextBankSwitch` | $0632 | 8 | Set bank from $c824, enter text processing |
| `ShowTextAndWait` | $06CE | 21 | Display text box, wait for player button press |
| `HandleTextCharacter` | $07AB | — | Process text control codes |
| `ReadNextTextByte` | $0D78 | — | Read from text stream |
| `PrintNumber` | $20AD | 16 | Format/print number |
| `ConvertNumberToText` | $1FB9 | 16 | Number → text digits |
| `FormatDecimalDigits` | $0A7C | 16 | Extract digits by dividing by 1000/100/10 |
| `FormatLargeNumber` | $09C7 | 9 | Format numbers > 999 (divides by 1M/100K/10K) |
| `ExtractDigits` | $09A4 | 16 | Decimal digit extraction |
| `WriteDigitTile` | $20D3 | 8 | `Write_gfx_tile(A + $F0)` — number tile |
| `WriteBlankTile` | $20D9 | 7 | `Write_gfx_tile($E0)` — blank/space tile |
| `PrintDigit` | $20DF | 14 | Print single digit |
| `WriteByteAndTerminate` | $0AD4 | 8 | `[HL] = A; [HL+1] = $F0` — write byte + text terminator |

**Bitfield/Event Flags:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `TestBitInArray` | $267E | 15 | Test bit A in bitfield at HL; Z flag = result |
| `SetBitInArray` | $2670 | 6 | Set bit A in bitfield at HL |
| `GetBitAndMask` | $2683 | 4 | Helper: byte offset + bitmask from bit index |
| `SetEventFlag` | $26A0 | 5 | Set event flag BC in $D99B bitfield |
| `ClearEventFlag` | $26A6 | 4 | Clear event flag BC in $D99B bitfield |
| `TestEventFlag` | $26AE | 6 | Test event flag BC; Z=clear, NZ=set |
| `ComputeFlagAddress` | $26B3 | — | BC → byte addr + bitmask for event flag |

**Input:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `UpdateJoypadState` | $1364 | 10 | Read joypad with edge detection/debounce |
| `WaitInputRelease` | $1E31 | 23 | Wait for button release |
| `RequestScreenUpdate` | $0609 | 34 | Set screen refresh flag |
| `UpdateOAMSprites` | $2518 | 22 | Update sprite OAM |

**SRAM:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `EnableSRAM` | $20EE | 48 | SRAM access on |
| `DisableSRAM` | $1013 | 41 | SRAM access off |
| `CopySRAMBlock` | $2184 | 7 | Enable MBC SRAM, copy BC bytes HL→DE, disable |
| `CopyFromSRAM` | $21F5 | 5 | Enable MBC SRAM, copy BC bytes DE→HL, disable |
| `SavePartyToSRAM` | $2197 | 5 | Copy party/inventory data to SRAM save area |

**Script Engine:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `RunScriptEngine` | $0B07 | 18 | Store D/E to $c822/$c823, rst $10 to bank $04 |
| `CallScriptByType` | $0B9B | 10 | Route script execution by E parameter |

**Serial/Link:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `SerialTransfer` | $1275 | 17 | Link cable transfer |
| `SetSerialByte` | $1284 | 8 | `rSB = B` — set serial byte register |

**Audio:**

| Label | Address | Refs | Signature |
|-------|---------|------|-----------|
| `SetBGM` | $1AE1 | — | Store BGM offset |
| `InitBGM` | $1AE5 | — | Full BGM init with audio setup |
| `LoadSE` | $1B30 | — | Load sound effect |
| `ProcessBGMQueue` | $1BB1 | — | Process queued BGM/SE |
| `InitAudioSystem` | $3331 | 9 | Initialize NR52, clear audio channels |
| `CheckAudioFlag` | $3A48 | 7 | Check $DE1F/$DE1C audio state flags |
| `WriteAudioRegister` | $3954 | 5 | Write A to audio I/O port indexed by C |
| `NopReturn` | $3000 | 5 | Stub — just `ret` |

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

Map Type → NPC Scripts → Events
  ├─ Bank $0B NPC entries  script_id field → per-map script table index
  ├─ Bank $04:$71EF  MapTypeDispatch → route to script bank by $D8D3
  ├─ Banks $0C/$0D/$0E/$0F  master table at $41BA[$D8D3 × 2] →
  │     per-map script ptr table → script data (opcodes + text IDs)
  ├─ Bank $04  100 opcode handlers (script VM)
  ├─ ROM0 $0AD9  text ID dispatch → handler banks $42-$4E
  └─ $D99B+ bitfield  event flags (story state)

Text ID → Display
  ├─ ROM0 $0AD9  TextDispatchCascade → route by ID range
  ├─ Banks $42-$4E  text handler banks (select data bank + index)
  ├─ Banks $18/$1A/$1B/$1F/$21/$22/$3F  text data banks
  └─ Bank $41  name/item/desc string tables (direct lookup)
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
| `gen_script_banks.py` | Script data tables | $0C/$0D/$0E/$0F | Yes | `--apply` |
| `annotate_bank052.py` | Skill handler labels | $52 | **No** | one-time |

---

## Decode Status

**ALL 2,404 `Call_` labels named — 0 unnamed function entry points remain.**

| Bank | Data | Code | Notes |
|------|------|------|-------|
| $00 | — | 654 named / 0 Call_ | Core engine: 396 Call_ hand-named this session |
| $01 | ✅ | 248 named / 0 Call_ | Game loop, encounters, gate data. 95 Call_ named |
| $02 | — | 44 named / 0 Call_ | Screen rendering, 6 layer flags |
| $03 | ✅ | 72 Call_ named | Monster info fully annotated |
| $04 | — | 23 Call_ named | Script VM engine |
| $05-$09 | — | All Call_ named | Field utilities, audio |
| $0A-$0B | ✅ | All Call_ named | Room data, field util |
| $0C-$0F | ✅ | Shared code | Script data: 530 scripts, 0 unknown opcodes |
| $10-$19 | Mixed | All Call_ named | Various systems |
| $13 | ✅ | — | EXP/growth tables done |
| $14 | ✅ | 11 Call_ named | Enemy stats done |
| $16 | ✅ | 50 Call_ named | Breeding + gates |
| $17 | ✅ | 18 Call_ named | Palette/attributes |
| $41 | ✅ | ✅ | 100% annotated |
| $42-$4E | ✅ headers | All Call_ named | Dialogue banks, dispatch tables |
| $50 | Partial | 131 Call_ named | Battle core |
| $51 | — | 113 Call_ named | Battle setup |
| $52 | ✅ | 190 Call_ named | Skill functions + battle helpers |
| $53-$58 | Partial | All Call_ named | Battle sub-systems |
| $55-$5F | — | All Call_ named | Battle display, field UI |
| Tilesets | ✅ | — | 14 banks LZSS tile data |
| **Total** | — | **7,881 named / 19,053 auto** | **40% named — 0 Call_ labels** |

---

## Cross-Bank Dispatch Map (rst $10)

1,028 cross-bank calls traced. Every bank's dispatch table is now documented
in the asm files as proper `db`/`dw` directives (47 banks fixed this session).
Full call data in `extracted/crossbank_calls.json`.

### Bank Role Classification (from call graph analysis)

**Core Engine (Bank $00):** 654 properly named functions, 0 Call_ remaining.
All function entry points named. ~1,200 Jump_/jr_ auto-labels remain for
internal control flow. Covers game loop, interrupts, DMA, text, audio, 
map transitions, PRNG, math, joypad.

**Overworld / Field:**
| Bank | Role | Evidence |
|------|------|----------|
| $01 | Game loop, encounters, gate data | 14 entries, called by engine+field banks |
| $02 | Screen/map rendering | 6 entries, called by engine+battle+field |
| $06 | Map state, NPC management | 7 entries, called by field banks |
| $07 | Tile/sprite loading | 4 entries; entries 1-2 called 11× each |
| $09 | Field utility | 2 entries, low call count |
| $0A | Field utility | 1 entry, called only by $09 |
| $0B | Room data + room loading | 10 entries, called by 8 banks |
| $15 | Map transition pipeline | 4 entries, called by $00 and $03 |
| $19 | Field utility | 1 entry, called only by $06 |

**Script System:**
| Bank | Role | Evidence |
|------|------|----------|
| $04 | Script VM engine | 7 entries, called by field+UI banks |
| $0C-$0F | Script data (4 map-type groups) | 3 entries each, called only by $04 |
| $10 | Script utility | 2 entries, called only by $04 |

**Data Banks (fully decoded):**
| Bank | Role | Evidence |
|------|------|----------|
| $03 | Monster info (221×43B) | 9 entries, called by 18 banks |
| $13 | EXP/growth tables | 4 entries |
| $14 | Enemy stats (487×25B) | 7 entries, called by 13 banks |
| $16 | Breeding + gates + encounters | 10 entries |
| $17 | Palette/attribute system | 14 entries, 69 calls — heavily used |
| $41 | Text/name tables | 3 entries, 50 calls — GetText/PutText/GetPutText |

**Battle System:**
| Bank | Role | Evidence |
|------|------|----------|
| $50 | Battle core / UI | 11 entries, called by battle banks + $00 |
| $51 | Battle setup / init | 19 entries, called by battle banks |
| $52 | Skill function dispatch (230 entries) | 7 used entries, called by $50/$53/$57/$58 |
| $53 | Battle sub-routines | 18 entries, called by $52/$53 |
| $54 | Battle stat tables (231 entries) | 8 used entries, monster stat lookups |
| $55 | Battle display / effects | 15 entries, called by battle+engine |
| $57 | Battle AI / personality | 9 entries, called by battle banks |
| $58 | Battle animation / effects (245 entries) | 14 used entries |

**Dialogue / Text Display Banks ($42-$4B):**
The text dispatch function at $0AEA in bank $00 routes text IDs
to banks $42-$4B via range checks. Each bank's entry 0 handles text
display; other dispatch entries are animation/rendering helpers.
Text ID passed via wram [$C823], bank ID via [$C822].

| Bank | Dispatch Entries | Animation Bank | Notes |
|------|-----------------|----------------|-------|
| $42 | 117 | $1A (158 entries) | First dialogue block |
| $43 | 147 | $1A (shared) | Castle/early game text |
| $44 | 102 | $1B (136 entries) | |
| $45 | 128 | $1F (120 entries) | |
| $46 | 148 | $1B (shared) | |
| $47 | 60 | $21 (120 entries) | |
| $48 | 112 | $1F (shared) | |
| $49 | 162 | — | |
| $4A | 293 | $22 (196 entries) | Largest dialogue block |
| $4B | 68 | $3F (11 entries) | |

**Menu/UI System:**
| Bank | Role | Evidence |
|------|------|----------|
| $56 | UI dispatch / menu router | 7 entries, called by 13 banks |
| $4C | Shared UI rendering (360 entries!) | 78 calls to entry 0 from battle+UI banks |
| $4D | Dialogue portraits / sprite data | 476 entries |
| $4E | Text rendering utility | 92 entries, called by $00 and $56 |
| $4F | Sub-UI utility | 3 entries, called only by $4E |

**Audio:**
| Bank | Role | Evidence |
|------|------|----------|
| $08 | Audio/sound engine | 3 used entries, 41 calls from 12 banks |
| $05 | Audio utility | 1 used entry, 6 calls |
| $18 | Audio data/music | 5 entries, called by $00 and $49 |

**Save/Load / Field UI:**
| Bank | Role | Evidence |
|------|------|----------|
| $59 | Save/load screens | 9 entries, called by $00/$56 |
| $5C-$5E | Field UI (2 entries each) | Called by $00 and $5F |
| $5F | Field UI router | 11 entries, called by engine+battle+field |
| $12 | Item system | 1 entry, called by $09 |

### Tileset Banks (14 banks, 100% annotated)
$23-$26, $28-$31, $37-$38: LZSS compressed tile data, 29-72 entries each.
$32-$36, $39-$3B: Tileset data with large dispatch tables (20-81 entries).
$3C-$3E: Attribute/palette map data (78-239 entries).

---

## Related Documentation

| File | Covers |
|------|--------|
| `ARCHITECTURE.md` | Bank map, RST dispatch, RAM regions, free space |
| `BANK04_SCRIPT_ENGINE.md` | Script VM: 100 opcodes, state machine, data flow |
| `QUEST_OPCODES.md` | $1F/$2C/$2D handler code analysis (arena, inventory, monster dialogue) |
| `BREEDING_SYSTEM.md` | Recipe tables, algorithm, mutation system |
| `CROSSBANK_ROOMS.md` | Custom room creation technique |
| `EVENT_FLAGS.md` | Flag bitfield, story progression flags, script commands |
| `MONSTER_DATA.md` | Monster info fields, resistance types, growth curves |
| `ROOM_DATA_FORMAT.md` | Room pointer chains, exit/NPC entry format |
| `ROUTING.md` | Room transitions, 5 code paths, spawn table |
| `TEXT_SYSTEM.md` | Charmap encoding, DTE pairs, control codes |
| `known_RAM_map.md` | Community WRAM documentation |
| `CUSTOM_CUTSCENES.md` | Custom cutscene creation guide, verified opcode reference |
| `SCRIPT_TOOLS.md` | How to use gen_script_banks.py and decompile_script.py |
| `FIRST_5MIN_TRACE.md` | SameBoy trace guide for game opening |
| `known_ROM_map.md` | Community ROM map (source for much of this work) |

---

## Session Progress: Jump_/jr_ Label Naming

### Bank $00 — Complete (761 labels named this session)
All 838 auto-labels (316 `Jump_000_`, 522 `jr_000_`) processed:
- **761 renamed** with descriptive names
- **77 already aliased** (had named labels at same address)
- **0 unaliased auto-labels remain**

**Key naming categories applied:**
- Interrupt handlers: VBlankSaveAF, VBlankEnableInt, VBlankProcessAudio, VBlankFinish, VBlankReturn, VBlankReentry
- Boot/Init: AfterGBCInit, InitSGBBorders, InitDisplayAndRun, MainWaitLoop, ExitWaitReinit
- Screen update system: WaitScreenUpdateDone, SetArrowTiles, DrawTextArrow, ClearTextBitsRedraw, FillTilemapRowLoop
- Text engine: LoadTextPointerHL, CopyDEtoHLByte, CheckTextTerminator, AdvanceTextPointer, HandleControlCode, RestoreBankAndReturn
- Sprite/OAM processing: SpriteCheckYBounds, SpriteWriteYCoord, SpriteFlippedWriteX, SpriteGBCMode (and 30+ related)
- Number formatting: ExtractHundredsDigit, WriteThousandsDigit, DivBCbyDELoop, FormatMillions
- Text dispatch cascade: DispatchBank42Rst through DispatchBank4E (10 labels)
- Palette/fade system: SetFadeOutSGB, FadeInStepDMG, FadeOutStepSGB, FadeDone (20+ labels)
- Audio engine: 100+ labels for note processing, channel management, frequency calculation
- Math utilities: Div8Loop/Subtract/NextBit, Div16Loop, Div24Loop, MulShiftBit1-4
- Joypad: ReadJoypadDMG, CheckAutoRepeat, SetNewJoypadState, ClearJoypad2State
- Monster data: ComputeMonsterOffset, SubtractFromMonster, CheckBattleContext
- Stat operations: SatAddCapBC, ClampedAddLow, SetMinValue1
- SRAM: EnableSRAMAccess, SavePartyData, CopySRAMLoop, CopyFromSRAMLoop
- Data tables ($26D6-$2B5F): Labeled as DataLookup_XXXX / Data_XXXX (misassembled — conversion to db/dw is Priority 3)
- Audio wave data ($3200-$33FF): Labeled as AudioWave_XXXX / AudioWaveEntry_XXXX (misassembled)

**Cross-bank impact:** 197 labels in bank $00 are referenced from other banks. All renames applied across all 105 bank files.

### Overall Project Status After This Work
- Bank $00: **0** unaliased auto-labels remaining (was 838) — 761 renamed
- Bank $04: **0** unaliased auto-labels remaining (was 253) — 253 renamed  
- Project total: ~18,039 auto-labels remaining (was 19,053)
- Dynamic repointing: **34 of 36** hardcoded address patterns converted to LOW/HIGH(Label)
- Cross-bank references: **944** `ld reg, $XXXX` → `ld reg, Label` conversions
- RoomPtrTable: **fully label-based** (gen_room_data_db.py modified)
- New data table labels: **19** (see SESSION_HANDOFF.md for full list)
- SpecialRecipeTable ($16:$4B30): label created for breeding special recipes

---

## Dynamic Repointing Status (Critical for Editor)

### What This Means
When a pointer table uses **labels** (`dw RoomSub_Castle`) instead of **hardcoded addresses** (`dw $4C13`), the assembler automatically resolves pointers when data moves. This is what makes it possible to add/remove/reorder data and rebuild a working ROM.

### Fully Repointable Systems (label-based pointers) ✓

| System | Bank | Tables | Status |
|--------|------|--------|--------|
| **Scripts** | $0C-$0F | Master tables, per-map tables, branch targets | ✓ Already labeled |
| **Room data** | $0B | RoomPtrTable (107 entries) | ✓ **FIXED this session** — gen_room_data_db.py modified |
| **Monster names** | $41 | MonsterNamePtrTable (256 entries) | ✓ Already labeled |
| **Skill names** | $41 | SkillNamePtrTable (256 entries) | ✓ Already labeled |
| **Item/desc names** | $41 | ItemNamePtrTable, ItemDescPtrTable | ✓ Already labeled |
| **Skill functions** | $52 | SkillFunctionTable (222 entries) | ✓ Already labeled |
| **Palette attributes** | $17 | AttrPtrTable (107 entries) | ✓ Already labeled |

### Hardcoded Offset Calculations Fixed This Session

These `add LOW_BYTE / adc HIGH_BYTE` patterns compute table addresses at runtime.
Each was converted to `add LOW(Label) / adc HIGH(Label)` so the table can move.

| Bank | Address | Label | Purpose |
|------|---------|-------|---------|
| $03 | $4461 | `MonsterInfoTable` | Monster info (221×43B) |
| $14 | $4C1D | `EnemyStatsTable` | Enemy stats (487×25B) |
| $13 | $41E6 | `ExpCurveTables` | EXP curves (32×99×3B) |
| $13 | $6706 | `StatGrowthTables` | Growth curves (32×99×1B) |
| $01 | $6AAE | `EncounterPoolData` | Encounter pools (128×26B) — 6 refs fixed |
| $16 | $7436 | `FloorLayoutData` | Floor layouts (1120B) — 2 refs fixed |
| $16 | $4974 | `FamilyRecipeTable` | Breeding family recipes — label created + 2 refs fixed |
| $16 | $7736 | `FloorTilePatterns` | Floor tile sub-table — label created |
| $08 | $447E | `label8_447e` | Audio instrument data |

### Remaining Hardcoded Offset References (3 total — need Priority 3 data conversion)

These still use `add $XX / adc $YY` with raw bytes. Each needs a label at the target
address and conversion to `LOW(Label)/HIGH(Label)`. Many targets fall mid-line in
`db` data, requiring line splitting.

| Bank | Target | Issue |
|------|--------|-------|
| $08 | $7751 | Audio waveform data — misassembled as instructions |
| $0B | $4974 | Code/data hybrid — jr offsets form lookup table |
| $32 | $5A5F | Tile animation data — misassembled as instructions |

**All other 19 targets from the original 22 have been fixed** with proper labels
and LOW/HIGH conversions. New labels created: NPCWalkDataTable, ScreenTransDataTable,
SpriteFrameDataTable, MapNPCPosDataTable, TilesetLookupTable (×3), TileRefLookupTable,
FieldPtrLookupTable, ItemSlotPtrTable, EnemyGroupTable, TransitionLookupTable,
RoomAttrDataBlocks, PaletteColorData, AttrMapData, AttrMapDataB, TextDataPtrLookup,
BattleHPLookupTable, SaveSlotPtrTable.

### Modified Generator Tool

`gen_room_data_db.py` now outputs label-based pointers in `RoomPtrTable`:
- Non-overlapping sub-tables: `dw RoomSub_Castle` instead of `dw $4C13`
- Overlapping sub-table (Castle): inline label at overlap position
- All 92 unique room data blocks are now label-referenced
- Rebuild with `python3 tools/gen_room_data_db.py > output.asm` and replace data section
