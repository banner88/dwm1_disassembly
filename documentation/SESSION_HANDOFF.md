# Session Handoff — Dynamic Repointing & Label Work

## What This Session Accomplished

### The Big Picture Change
This session pivoted from cosmetic label naming to **structural work that enables the 
custom editor**. The key insight: "full disassembly" isn't about naming 18,000 branch 
labels — it's about making every data reference label-based so the assembler can 
repoint automatically when data moves.

### 1. Dynamic Repointing (PRIMARY WORK)

**36 hardcoded address computations** were found across the codebase. These are 
`add $XX / adc $YY` patterns that compute table addresses at runtime using raw bytes.
If any referenced table moves, the game breaks silently.

**34 fixed**, 2 confirmed false positives (data bytes matching the pattern).

**New labels created at data table start addresses:**

| Label | Bank | Address | Purpose | Stride |
|-------|------|---------|---------|--------|
| MonsterInfoTable | $03 | $4461 | 221 monsters × 43B | species × 43 |
| EnemyStatsTable | $14 | $4C1D | 487 enemies × 25B | eid × 25 |
| EnemyGroupTable | $14 | $4A1D | Boss group data | eid × 25 |
| ExpCurveTables | $13 | $41E6 | 32 EXP curves × 99 lvls | table × 297 |
| StatGrowthTables | $13 | $6706 | 32 growth curves | table × 99 |
| EncounterPoolData | $01 | $6AAE | 128 pools × 26B | pool × 26 |
| NPCWalkDataTable | $01 | $4506 | NPC walk frame data | index × 4 |
| ScreenTransDataTable | $01 | $49DF | Screen transition data | index × 2 |
| FamilyRecipeTable | $16 | $4974 | Breeding family recipes | 2-byte pairs |
| SpecialRecipeTable | $16 | $4B30 | Breeding special recipes | 5-byte entries |
| FloorLayoutData | $16 | $7436 | Gate floor layouts | 1120B total |
| FloorTilePatterns | $16 | $7736 | Floor tile sub-table | index × 16 |
| TilesetLookupTable | $07 | $570C | Tileset pointer data | index × 2 |
| TileRefLookupTable | $07 | $6E14 | Tile reference data | index × 2 |
| RoomScreenPtrTable | $0B | $4974 | Screen index lookup | index × 2 |
| RoomAttrDataBlocks | $17 | $62FD | Room attribute data | index × 8 |
| PaletteColorData | $17 | $69BD | Palette color blocks | index × 16 |
| AttrMapData | $17 | $6AFD | Attribute map data | index × 8 |
| AttrMapDataB | $17 | $6B0D | Attribute map alt | index × 8 |
| TextDataPtrLookup | $18 | $4123 | Text data pointers | index × 2 |
| SpriteFrameDataTable | $03 | $71DA | Monster sprite frames | index × 12 |
| MapNPCPosDataTable | $06 | $4DCC | Map NPC positions | index × 2 |
| FieldPtrLookupTable | $09 | $6B10 | Field utility pointers | index × 2 |
| ItemSlotPtrTable | $12 | $65F2 | Item slot pointers | index × 2 |
| TransitionLookupTable | $15 | $617B | Map transition data | index × 8 |
| BattleHPLookupTable | $53 | $41DF | Battle HP table | index × 2 |
| SaveSlotPtrTable | $59 | $4363 | Save data pointers | index × 2 |

### 2. ld reg, $XXXX → ld reg, Label (944 conversions)

Every `ld hl/de/bc, $XXXX` where $XXXX matched a known label was converted.
Most impactful: **884 ROM0 cross-bank references** — other banks referencing 
bank $00 functions by raw address. Now if any bank $00 function moves, the 
assembler handles it.

### 3. RoomPtrTable Label Conversion

Modified `gen_room_data_db.py` to output `dw RoomSub_Castle` instead of 
`dw $4C13` in the 107-entry RoomPtrTable. All 92 unique room data blocks 
are now label-referenced. This means rooms can be added/removed/reordered.

### 4. Label Naming (Secondary)

- Bank $00: 761 internal labels renamed (VBlank, text engine, math, audio, etc.)
- Bank $04: 253 internal labels renamed (NPC frame update, script VM, opcode handlers)

## Free Space Available for Custom Content

| Banks | Free Space | Purpose |
|-------|-----------|---------|
| $60-$7F (20 banks) | **~320 KB** | Completely empty — available for anything |
| $40 | 11,781 B | Mostly empty |
| $47 | 9,357 B | Mostly empty |
| $54 | 10,550 B | Battle stat data — lots of room |
| $0E, $0F | 3,821 + 4,238 B | Script data banks — room for new scripts |
| $17 | 5,003 B | Palette data — room for new room palettes |
| $0B | 119 B | SharedPtrChase freed space (small) |

**Total usable free space: ~350+ KB** across the ROM.

## What the Editor Needs Next

### Priority 1: Practical Workflow Documentation
Create step-by-step guides:
- "How to add a custom room with NPCs and a script"
- "How to add a new gate floor"
- "How to modify the breeding table"
- "How to edit tilesets"

The tools and data structures exist. What's missing is the glue.

### Priority 2: WRAM Symbol Definitions
Key WRAM regions still use raw addresses ($C8xx, $CAxx, $CBxx, $DBxx).
Define these as named symbols in a shared `.inc` file. This doesn't affect 
the binary but massively improves code readability for editor development.

### Priority 3: Data Table Conversion (3 remaining regions)
Three misassembled data regions need conversion from instructions to `db`:
- Bank $0B: code/data hybrid around $4940-$49A0 (jr offsets as lookup data)
- Bank $08: audio waveform data around $7740-$7780
- Bank $32: tile animation data around $5A50-$5A70

### Priority 4: Battle System Labels
Banks $50-$58 have ~3,000 auto-labels. These are important for understanding
battle mechanics but NOT blocking the editor.

## Systems Ready for Custom Content NOW

| System | Can Edit? | Tools | Notes |
|--------|-----------|-------|-------|
| **Scripts/cutscenes** | ✅ YES | compile_script.py, decompile_script.py | 530 scripts, 100 opcodes |
| **Room data** | ✅ YES | gen_room_data_db.py | All pointers label-based |
| **Monster stats** | ✅ YES | gen_monster_db.py | 221 × 43B, all labeled |
| **Enemy stats** | ✅ YES | gen_enemy_stats_db.py | 487 × 25B, all labeled |
| **Breeding recipes** | ✅ YES | Manual edit | FamilyRecipeTable + SpecialRecipeTable labeled |
| **Encounter pools** | ✅ YES | gen_encounter_db.py | 128 pools, all labeled |
| **Skill functions** | ✅ YES | gen_skill_table_db.py | 222 entries, all labeled |
| **Names/text** | ✅ YES | gen_name_tables_db.py | All pointer tables labeled |
| **EXP/growth curves** | ✅ YES | gen_growth_tables_db.py | 32 tables each |
| **Palettes** | ✅ YES | analyze_bank17.py | Attr tables all labeled |
| **Tile editing** | ⚠️ PARTIAL | decompress_tiles.py, render_rooms.py | Tools exist, workflow TBD |
| **Gate floors** | ✅ YES | Manual edit | GateFloorDataTable labeled |
| **Event flags** | ✅ YES | analyze_event_flags.py | 311 mapped, 463 free |
