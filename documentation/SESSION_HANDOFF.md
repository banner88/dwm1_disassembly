# DWM1 ROM Hack — Session Handoff (Room Data & Tileset Conversion Session)

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

### 1. Bank $0B Room Data → Labeled Blocks
Converted the entire room data section ($4B43-$7FFF) from raw hex to structured,
labeled `db`/`dw` blocks using `tools/gen_room_data_db.py`.

**Output:**
- 91 sub-table labels (`RoomSub_Castle`, `RoomSub_GreatTree`, etc.)
- 177 step block labels (`StepBlk_Castle_s0`, etc.) with RAM counters and per-step fields
- 315 interact block labels with per-entry NPC/spawn comments
- 239 exit block labels with per-entry destination comments
- 1 remaining gap (24 bytes at $7883 — ForestMaze data reuse overlap)

**Key findings & fixes:**
- Sub-tables can be >8 entries: GreatTree=16, ConveyorBelt/Maze=12, LabyrinthFinal=32
- NPC facing direction: 0=down, 1=left, 2=up, 3=right (was incorrectly 1=up, 2=left)
- Castle sub-table overlaps last 3 pointer table entries (intentional data reuse)
- $4B42 interact pointer reuses code-section `rst $38` ($FF) as empty terminator
- $0000 exit pointers on ForestMaze/mt$61-64 = code-handled exits, not data
- mt$68/$69 point to step blocks, not sub-tables (0 valid screens, skipped)

**Edge cases in output:**
- 38 step entries use raw `dw $4B42` (code-section byte, no label)
- 7 step entries use raw addresses for overlapping interact/exit blocks
- 1 step entry uses `dw $0000` for code-handled exit

### 2. 14 Tileset Banks → Labeled Pointer Tables
Converted banks $23, $24, $25, $26, $28, $29, $2A, $2D, $2E, $2F, $30, $31, $37, $38
from ~200K lines of fake mgbdis instructions to 16K lines of labeled data.

Each bank now has:
- `TilesetPtrTable_XX:` with `dw TileData_XX_NN` entries
- `TileData_XX_NN:` labels for each LZSS data block
- `EQU` statements for shared pointer entries

Generator: `tools/gen_tileset_banks.py` (apply with `--apply` flag)

### 3. Bank $17 Attribute/Palette Tables → Labeled
Code section ($4000-$476E) preserved. Data section converted:
- `AttrPtrTable:` at $476F — 107 entries indexed by wMapID
- `GateAttrTable_A:` at $5215 — 256 entries (attr_idx, attr_bank) for gate mode
- `GateAttrTable_B:` at $5415 — 256 entries, alternate gate attributes
- Per-room screen/step attribute entries as raw db ($4845-$5214)
- LZSS attribute data as raw db ($5615-$7FFF)

### 4. Bank $41 Name Pointer Tables → Label-Based
- `MonsterNamePtrTable:` at $4339 — 256 × `dw MonsterName_XXX` (auto-updating!)
- `SkillNamePtrTable:` at $4539 — 256 × `dw SkillName_XXX` (auto-updating!)
- Changing a monster/skill name's LENGTH now auto-recalculates pointers on build
- Bank is exactly full — length changes require shortening another name to compensate

### 5. Renderer Improvements (`tools/render_rooms.py`)
- Added `--gate` mode with $5215/$5415 attribute lookup
- Added gate tileset validation (must decompress to 2048 bytes)
- Fixed per-room palette loading from `extracted/room_palettes.json`
- GBC 15-bit color → RGB conversion
- Added `--gate-idx` and `--gate-table` CLI options
- Expanded `TILESET_BANKS` set with gate banks ($28, $2E, $2F, $31, $38)
- Supports extended sub-tables (>8 screens) for composites

### 6. New Generator Tools
- `tools/gen_room_data_db.py` — generates bank $0B room data from ROM (regeneratable)
- `tools/gen_tileset_banks.py` — generates all 14 tileset bank files from ROM (regeneratable)

## Corrections to Previous Documentation

### Facing Direction (was WRONG, now FIXED everywhere)
Previous: $00=down, $10=up, $20=left, $30=right
**Correct: $00=down, $10=left, $20=up, $30=right**
Verified by user in-game: Castle entrance guards face left ($10), right ($30).
Fixed in: `ROOM_DATA_FORMAT.md`, `bank_00b.asm`, `gen_room_data_db.py`

### Sub-Table Size (was capped at 8, now FIXED)
Previous: "Maximum 8 entries (the full 4×2 grid)"
**Correct: Size varies — determined by gap between sub_table_ptr and first step block.**
Actual sizes found: 1, 2, 3, 4, 5, 8, 12, 16, 32 entries.
Key rooms with >8: GreatTree=16, ConveyorBelt/Maze=12, LabyrinthFinal=32.
Screen indices >7 use extended grids beyond the standard 4×2.

### Room Names (identified by user)
- mt$2F = Terry and Milayou's house / intro room (labeled `Room_2F` in code)
- mt$23 = garbage render, likely unused/debug (shares mt$16 room data, Castle tileset)

## Files Modified This Session (17 banks + 2 tools + docs)

### Assembly files (all byte-perfect, MD5 verified):
| File | Lines | What changed |
|------|-------|-------------|
| `bank_00b.asm` | 7,964 | Room data section: raw hex → 765+ labeled blocks |
| `bank_017.asm` | 2,729 | Data section: AttrPtrTable + GateAttrTables labeled |
| `bank_023.asm` | 1,132 | Full bank: fake instructions → labeled pointer table + data |
| `bank_024.asm` | 1,135 | Same |
| `bank_025.asm` | 1,132 | Same |
| `bank_026.asm` | 1,133 | Same |
| `bank_028.asm` | 1,140 | Same |
| `bank_029.asm` | 1,172 | Same |
| `bank_02a.asm` | 1,192 | Same |
| `bank_02d.asm` | 1,132 | Same |
| `bank_02e.asm` | 1,167 | Same |
| `bank_02f.asm` | 1,219 | Same |
| `bank_030.asm` | 1,141 | Same |
| `bank_031.asm` | 1,256 | Same |
| `bank_037.asm` | 1,234 | Same |
| `bank_038.asm` | 1,277 | Same |
| `bank_041.asm` | 6,338 | MonsterNamePtrTable + SkillNamePtrTable → label-based dw |

### Tools:
| File | Purpose |
|------|---------|
| `tools/gen_room_data_db.py` | Generate bank $0B room data from ROM (regeneratable) |
| `tools/gen_tileset_banks.py` | Generate all 14 tileset banks from ROM (regeneratable) |
| `tools/render_rooms.py` | Updated: gate mode, palette loading, extended sub-tables |

### Documentation updated:
- `ROOM_DATA_FORMAT.md` — facing directions fixed, sub-table size corrected
- `SESSION_HANDOFF.md` — this file

## Repo Structure
```
dwm1_disassembly/
├── data/
│   └── DWM-original.gbc          # Original ROM (MD5: 1ca6579359f21d8e27b446f865bf6b83)
├── disassembly/
│   ├── game.asm                   # Master include file
│   ├── bank_000.asm               # Bank $00 (core engine)
│   ├── bank_00b.asm               # Bank $0B (room system) ← CONVERTED THIS SESSION
│   ├── bank_001.asm               # Bank $01 (encounter pools) — prev session
│   ├── bank_003.asm               # Bank $03 (monster info table) — prev session
│   ├── bank_013.asm               # Bank $13 (exp/growth tables) — prev session
│   ├── bank_014.asm               # Bank $14 (enemy stats) — prev session
│   ├── bank_017.asm               # Bank $17 (attribute tables) ← CONVERTED THIS SESSION
│   ├── bank_023..bank_038.asm     # Tileset banks ← CONVERTED THIS SESSION (14 banks)
│   ├── bank_041.asm               # Bank $41 (name tables) ← PTR TABLES CONVERTED
│   ├── bank_052.asm               # Bank $52 (skill function table) — prev session
│   ├── charmap.asm                # Text encoding map
│   ├── wram.asm / hram.asm        # RAM definitions
│   └── Makefile
├── documentation/
│   ├── SESSION_HANDOFF.md         # This file
│   ├── ROOM_DATA_FORMAT.md        # Room data technical reference (UPDATED)
│   ├── known_ROM_map.md           # ROM address reference
│   ├── known_RAM_map.md           # RAM address reference
│   ├── ARCHITECTURE.md            # System architecture overview
│   ├── BREEDING_SYSTEM.md         # Breeding mechanics
│   ├── BANK04_SCRIPT_ENGINE.md    # NPC script engine
│   ├── EVENT_FLAGS.md             # Game progression flags
│   └── ... (15 docs total)
├── extracted/
│   ├── room_palettes.json         # Per-room GBC palettes (81 rooms, SameBoy dumps)
│   ├── map_table.json             # Room data dump
│   ├── room_connections.json      # Room exit graph
│   ├── exit_table.json            # Exit patch addresses
│   └── ... (other extracted data)
├── tools/                         # 55 Python tools
│   ├── gen_room_data_db.py        # Bank $0B generator ← NEW
│   ├── gen_tileset_banks.py       # Tileset bank generator ← NEW
│   ├── render_rooms.py            # Room renderer ← UPDATED
│   ├── decompress_tiles.py        # LZSS decompressor
│   ├── compress_tiles.py          # LZSS compressor
│   ├── gen_monster_db.py          # Monster info generator
│   ├── gen_enemy_stats_db.py      # Enemy stats generator
│   ├── gen_encounter_db.py        # Encounter pool generator
│   ├── gen_name_tables_db.py      # Name string generator
│   ├── gen_skill_table_db.py      # Skill table generator
│   ├── dump_map_table.py          # Room data dumper
│   ├── analyze_bank0b.py          # Bank $0B analysis
│   └── ... (55 total)
└── editor/
    └── editor.py                  # Legacy byte-patch editor
```

## What's Now Directly Editable

| Data | How to edit | Auto-update? |
|------|-------------|-------------|
| Room NPC positions/sprites | Edit interact block `db` entries in bank_00b.asm | N/A |
| Room exit destinations | Edit exit block `db` entries in bank_00b.asm | N/A |
| Room step layouts | Change step_id in step block entries | N/A |
| Tileset pointer tables | Edit `dw TileData_XX_NN` in tileset banks | Yes (labels) |
| Monster names | Edit `db "Name", $F0` in bank_041.asm | Yes (ptr auto-updates) |
| Skill names | Edit `db "Name", $F0` in bank_041.asm | Yes (ptr auto-updates) |
| Monster stats | Edit `db` values in bank_003.asm | N/A |
| Enemy encounter stats | Edit `db`/`dw` in bank_014.asm | N/A |
| Encounter pools | Edit EIDs in bank_001.asm | N/A |
| Skill→function mapping | Edit `dw` in bank_052.asm | N/A |

## Room Data Quick Reference

### Sub-Table Sizes (rooms with >8 entries)
| Room | mt | Entries | Active screens |
|------|-----|---------|----------------|
| GreatTree | $01 | 16 | 0,1,4,5,8,9,12,13 (8 screens) |
| ConveyorBelt 1-3 | $54-$56 | 12 | 0,1,2,4,5,6,8,9,10 (9 screens) |
| Maze 1-3 | $57-$59 | 12 | 0,1,2,4,5,6,8,9,10 (9 screens) |
| LabyrinthFinal | $60 | 32 | 21 active screens |
| Room_63 | $63 | 14 | 0,1,4,5,8,9,12,13 |
| Room_64 | $64 | 17 | 0,3,4,7,8,11,12,15,16 |

### NPC Type Byte Encoding (VERIFIED by user in-game)
```
Bit 7:   always 0 for NPCs (≥$80 = spawn/special)
Bit 6:   non-interactable flag
Bits 5-4: facing direction
  00 = down  ($00)
  01 = left  ($10)
  10 = up    ($20)
  11 = right ($30)
Bits 3-0: behavior (0=standard, 6/7=common patrol patterns)
```

### Key Addresses
| Address | Bank | Purpose |
|---------|------|---------|
| $4B43 | $0B | Room pointer table (107 entries) |
| $476F | $17 | Room attribute pointer table (107 entries) |
| $5215 | $17 | Gate attribute table A (256 entries) |
| $5415 | $17 | Gate attribute table B (256 entries) |
| $4339 | $41 | Monster name pointer table (256 × dw, label-based) |
| $4539 | $41 | Skill name pointer table (256 × dw, label-based) |
| $4001 | $23-$38 | Tileset pointer tables (per-bank, various sizes) |

## What's Next — Future Work

### Priority 1: Room Name Labels
Many rooms have generic names (Room_2F, Room_35, etc.). Known corrections:
- mt$2F = Terry/Milayou's house (intro room)
- mt$35-$41 = various gate boss/dungeon rooms
Update MAP_NAMES in gen_room_data_db.py and regenerate to rename all labels.

### Priority 2: Bank $41 Remaining Tables
- Family name pointer tables at $4739 (13 tables × 32 entries)
- Item name tables
- Personality name pointer table at $4997 (27 entries) → label-based dw
- Personality name strings at $7159 → labeled `db "Name", $F0`

### Priority 3: Bank $17 Per-Room Attribute Entries
The per-room screen/step attribute entries ($4845-$5214) are still raw db.
Could be structured as labeled entries with step-dependent attribute indices.

### Priority 4: Bank Code Annotations
| Bank | System | Status |
|------|--------|--------|
| $16 | Gate world generation, $C940 population | Code unannotated |
| $51 | Battle init, resistance packing | Key functions traced, no labels |
| $52 | Battle system, skill handlers | Skill table done, handlers unannotated |
| $56 | Text rendering engine | Identified, not annotated |
| $57 | Battle dispatch | Entry points found, not annotated |

### Priority 5: NPC Behavior Values
Lower nibble of NPC type byte (bits 3-0) controls behavior patterns.
Values 0, 6, 7 are common. Full mapping not yet determined.

### Priority 6: GUI Editor
Now that room data is labeled, a GUI editor could parse bank_00b.asm
and present NPC/exit/step data in editable forms.
