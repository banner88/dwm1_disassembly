# DWM1 ROM Hack — Session Handoff (June 2026, Data Table Conversion Session)

## What Was Completed This Session

### 1. Monster Info Table → db Blocks (Bank $03:$4461)
221 entries × 43 bytes converted from fake mgbdis instructions to labeled `db` blocks.
Each entry has: family, level cap, exp table, female ratio, fly/metal flags, 3 skills,
6 growth rates, 27 resistances, tier/rank — all with inline comments.
6 embedded labels preserved (Call_003_59d0, Call_003_624e, Jump_003_6473,
Jump_003_648e, Jump_003_6719, Jump_003_68ab — code references into data region).
Label: `MonsterInfo_000_DrakSlime:` through `MonsterInfo_220_Unused_220:`
Table label: `MonsterInfoTable:`

### 2. Boss Redirect Table → dw Blocks (Bank $14:$4893)
35 entries (34 redirects + $FFFF terminator) converted to `dw fight_eid, join_eid`
with gate names in comments. Label: `BossRedirectTable:`

### 3. Unknown Gap Data (Bank $14:$491F-$4C1C)
766 bytes of unidentified data between boss table and enemy stats, output as raw
hex `db` blocks. Purpose not yet identified — possibly EID lookup table.
Label: `UnknownData_491F:`

### 4. Enemy Stats Table → db Blocks (Bank $14:$4C1D)
487 entries × 25 bytes converted. Each entry has: species, EXP reward (dw),
joinability, level, 6 stats (dw), AI weights, 4 skills — with species/skill names.
Label: `EnemyStats_000:` through `EnemyStats_486:`
Table label: `EnemyStatsTable:`

### 5. Encounter Pool Data → db Blocks (Bank $01:$6A22-$77AD)
Gate mapping tables (base pool index, floor breakpoints, breakpoint data) and
128 encounter pools × 26 bytes converted with monster name comments.
3 embedded labels preserved (Call_001_7407, Call_001_7420, Call_001_747b).
Labels: `GateBasePoolIndex:`, `GateFloorBreakpoints:`, `FloorBreakpointData:`,
`EncounterPoolData:`, `EncounterPool_000:` through `EncounterPool_127:`

### 6. Skill Function Table → dw Blocks (Bank $52:$4011)
256 entries × 2 bytes (skill ID → handler address) converted to `dw $XXXX`
with skill names in comments. Also converted bank byte + jump table header.
Label: `SkillFunctionTable:`

### 7. Monster & Skill Name Strings → Charmap Text (Bank $41)
222 unique monster names and 256 skill names converted from fake instructions
to charmap-encoded `db "Name", $F0` statements — directly editable text.
Moved `INCLUDE "charmap.asm"` in game.asm to before bank_041.asm so the
game's text encoding is active for string literals.
Labels: `MonsterName_000_DrakSlime:` etc., `SkillName_000_Blaze:` etc.
Table labels: `MonsterNameStrings:`, `SkillNameStrings:`

### 8. Exp & Growth Tables → db Blocks (Bank $13)
32 experience curve tables (99 levels × 3 bytes each) and 32 stat growth tables
(99 levels × 1 byte each) converted from fake instructions to labeled db blocks.
Labels: `ExpCurveTables:`, `ExpCurve_00:` through `ExpCurve_31:`,
`StatGrowthTables:`, `GrowthCurve_00:` through `GrowthCurve_31:`
Bank header added with format documentation.

### 9. Bank Headers Added
Added annotation headers to banks $13, $41, $52 documenting purpose,
data formats, jump table entries, and cross-references.

### 10. Generator Tools Created
- `tools/gen_monster_db.py` — generates monster info table db blocks
- `tools/gen_enemy_stats_db.py` — generates boss table + enemy stats db blocks
- `tools/gen_encounter_db.py` — generates encounter pool db blocks
- `tools/gen_skill_table_db.py` — generates skill function table dw blocks
- `tools/gen_name_tables_db.py` — generates monster/skill name string blocks

### 9. Charmap Placement Fix
Moved `INCLUDE "charmap.asm"` from after hram.asm (line 151) to before
bank_041.asm (line 86) in game.asm. This enables `db "string"` syntax to
use the game's text encoding for banks $41+. Banks $00-$40 still use ASCII
(required for ROM header strings). Verified no other banks use string literals.

## Build Verification
```bash
cd disassembly
rm -f game.o game.gbc game.sym game.map
make
md5sum game.gbc
# MUST output: 1ca6579359f21d8e27b446f865bf6b83
```
**NEVER run `make clean`** — it deletes committed `.2bpp` graphics files that
cannot be regenerated with matching bytes. Only delete `game.o game.gbc game.sym game.map`.

## What's Now Directly Editable in .asm Files

| Data | How to edit |
|------|-------------|
| Monster stats/skills/resistances | Edit `db` values in `MonsterInfo_XXX_Name:` (bank_003.asm) |
| Monster names | Edit `db "Name", $F0` in `MonsterName_XXX_Name:` (bank_041.asm) |
| Skill names | Edit `db "Name", $F0` in `SkillName_XXX_Name:` (bank_041.asm) |
| Enemy encounter stats | Edit `db`/`dw` in `EnemyStats_XXX:` (bank_014.asm) |
| Boss gate redirects | Edit `dw fight, join` in `BossRedirectTable:` (bank_014.asm) |
| Encounter pools | Edit EIDs/weights in `EncounterPool_XXX:` (bank_001.asm) |
| Skill→function mapping | Edit `dw $XXXX` in `SkillFunctionTable:` (bank_052.asm) |

**Caveat for name changes:** Monster/skill name pointer tables ($41:$4339) still use
raw address values, not label references. If you change a name's LENGTH, you must
also update the pointer table manually (or rebuild it). Changing characters within
the same length works without pointer updates.

## Remaining Unknowns (Medium Priority)
- **byte_2A** in monster info: labeled "tier/rank", not verified
- **Party struct gaps**: offsets $00-$08, $0B-$4A, $5C-$61, $63-$67 unmapped
- **AI weights** (enemy stats bytes 17-20): not code-traced
- **Skill properties**: MP costs, power, target types not extracted
- **Unknown data $14:$491F**: 766 bytes between boss table and enemy stats
- **Encounter pool header bytes**: 10-byte header format not decoded
- **Bank $41 pointer table**: not converted to label-based (would auto-recalculate on name length changes)

## What's Next — Continued Annotation

### Priority 1: Annotate Remaining Game System Banks
| Bank | System | Status |
|------|--------|--------|
| $13 | Level-up, stat growth, exp tables | Growth calc partially traced, no labels |
| $41 | Monster/skill name tables | Names converted, pointer tables + other data unannotated |
| $51 | Battle init, resistance packing, enemy setup | Key functions traced, no labels |
| $52 | Battle system, skill functions | Skill table converted, handler code unannotated |
| $56 | Text rendering engine | Identified, not annotated |
| $57 | Battle dispatch | Entry points found, not annotated |

### Priority 2: Remaining Data Conversions
- Monster name pointer table ($41:$4339) → label-based `dw MonsterName_XXX`
- Personality name tables ($41:$4997, $41:$7159)
- Experience curve tables ($13:$41E6)
- Growth rate tables ($13:$6706)

### Priority 3: GUI Editor Foundation
Now that data tables are labeled `db` blocks, a GUI editor can:
1. Parse .asm files for labeled data blocks
2. Present fields in editable forms
3. Write changes back to .asm
4. Run `make` to build modified ROM
This replaces the legacy byte-patch editor at `editor/editor.py`.

## Repo Statistics
- **~850 new labeled symbols** in the sym file
- **5 banks modified**: bank_001, bank_003, bank_014, bank_041, bank_052
- **1 infrastructure change**: game.asm charmap placement
- **5 generator tools** created in tools/
- **Breeding tables** ($16:$4B30/$4974) were already `db` blocks from previous session

## Room Data System — Fully Decoded (SameBoy Debug Verified)

### Screen Grid Model (4×2)
Screen indices map to a 4-column × 2-row grid:
```
[0][1][2][3]   ← row 0
[4][5][6][7]   ← row 1
```
Each screen = 10 tiles wide × 8 tiles tall.
Screen offsets at $00:$2DE7: (0,0), (10,0), (20,0), (30,0), (0,8), (10,8), (20,8), (30,8).

Room layouts vary: Castle=[0,1,5] L-shape, GreatTree=[0,1,4,5] 2×2,
Bazaar/Farm=[0,1,2,4,5,6] 3×2, Well=[0] single screen.

Sub-table size varies per room (not always 8). Determined by gap between
sub_table_ptr and first room_data_block pointer. $FFFF = unused grid position.

### Step Entry (6 bytes) — CONFIRMED by SameBoy debug
```
+0: step_id (tile layout index in tileset bank)
+1: tileset_bank (ROM bank containing LZ-compressed tile data)
+2,+3: interact_ptr → NPC + spawn mixed block (5-byte entries)
+4,+5: exit_ptr → exit checker block (7-byte entries)
```
**Field ordering confirmed**: SameBoy watchpoint on $D7F4 showed NPC data
sourced from bytes 2-3 pointer. Castle screen 5 step 4 verified.
Bank_00b.asm labels were correct; dump_map_table.py had them SWAPPED (now fixed).

### Interact Block (bytes 2-3): 5-byte entries, $FF terminated
All entries are 5 bytes. Bit 7 of type byte distinguishes:
- Type ≥ $80: spawn/exit ($8F=spawn, $90=walk-on exit)
  [type, param, x, y, dest_map_type]
- Type < $80: NPC [type, sprite, x, y, script]
  - Type bits 4-5 = facing direction (via swap+mask in parser)
  - NPC position is screen-local (added to $2DE7 offset during loading)
  - Script ID links to NPC script engine in bank $04
  - Script $FF = no interaction script

### Exit Checker Block (bytes 4-5): 7-byte entries, $FF terminated
[trigger_X, trigger_Y, dest_map_type, gate_flag, screen_byte, spawn_X, spawn_Y]
- Type $00 and $09 are skipped (arrival markers)
- All other type values are trigger_X coordinates
- Runs EVERY step via Entry 6
- Verified: Castle screen 5 exits match doors to Gate Hub, Farm, GreatTree

### RAM Step Counters
Each valid screen has its own RAM counter ($D9xx range), assigned sequentially
for each valid sub-table entry across ALL rooms. Example:
- Castle screen 0 → $D92A, screen 1 → $D92B, screen 5 → $D92C
Confirmed: $C925=5 (screen index) and $D92C=4 (step value) during debug.

### Tile Layout System
- 9 tileset banks: $23, $24, $25, $26, $29, $2A, $2D, $30, $37
- Pointer table at $4001 + step_id × 2 in each bank
- LZSS-compressed tile data (512 bytes decompressed = 32×16 tile grid)
- Decompressed to $C300 buffer → written to VRAM $9800
- Decompressor implemented: tools/decompress_tiles.py (80/88 unique layouts verified)

### Castle Layout (Debug Verified)
- Screen 0 (row 0, col 0): spawn points from gates, 2 NPCs
- Screen 1 (row 0, col 1): throne room, step-dependent cutscene NPCs
- Screen 5 (row 1, col 1): entrance hall, ALWAYS 3 guards (sprite $0B)

### Tools Fixed This Session
- dump_map_table.py: bytes 2-3/4-5 labels SWAPPED → fixed
- find_all_transitions.py: same swap → fixed
- find_transitions.py: same swap → fixed
- Regenerated: map_table.json, room_connections.json, exit_table.json
- New: dump_room_data.py (correct grid model + NPC/exit parsing)
- New: decompress_tiles.py (LZSS tile layout decompressor)

### Key Reference: ROOM_DATA_FORMAT.md
Complete technical reference at documentation/ROOM_DATA_FORMAT.md

### Resolved This Session (previously unknown)
- [x] Tileset graphics decompressor — same LZSS as layouts, 2048 bytes = 128 tiles
- [x] $C200 attribute buffer — GBC palette data, nibble-packed, LZSS from bank $17
- [x] Scroll boundary — screen_index = (X÷$80)*4 + (Y÷$A0), automatic
- [x] NPC type byte — bit 6=non-interactable, bits 5-4=facing, bits 3-0=behavior
- [x] Gate room exits — fixed exit at screen bottom, always back to mt=0
- [x] $C500 buffer — secondary tile buffer for screen transitions
- [x] Sprite ID mapping — Call_00b_4839 maps sprite IDs to graphics offsets


## Tile Rendering Pipeline — Complete

### Decompressor Fix
The LZSS decompressor had a circular buffer wrapping bug: back-references with
large offsets (near 0xFFF) wrap by subtracting 0x1000 from the reference address.
This allows copying from the END of the buffer when the offset is just below the
buffer start. Fixed in decompress_tiles.py, verified against live $C200 RAM dumps.

### Color Rendering Chain
1. Tile graphics: LZSS from tileset bank (2048B = 128 tiles, 2bpp)
2. Tile layout: LZSS from tileset bank, step_id indexed (512B = 32×16 grid)
3. Attribute data: LZSS from bank $3C/$3D/$3E
4. Palette colors: runtime data, captured per-room via SameBoy  command

### Attribute Lookup — TWO PATHS
**Normal rooms** (wInGateworld == 0):
  $476F[mapID × 2] → per-room screen table
  → screen table[screen × 2] → per-screen entry
  → entry: [ram_addr:2] + step × [attr_bank_idx:2][palette_ptr:2]
  Step-dependent: each step can have different attributes AND palette!

**Gate rooms** (wInGateworld != 0):
  $C940[$C925] → index into $5215 or $5415 table (based on $C93F)
  → (bank, idx) pair for LZSS decompression

### Room Palette Database
Captured palettes for all 80 map types from SameBoy, saved in
extracted/room_palettes.json. Includes variant palettes (e.g., mt63_peace
for Servant room after defeat).

### Tools Created/Updated
- tools/decompress_tiles.py — LZSS decompressor (wrapping fix applied)
- tools/compress_tiles.py — LZSS compressor (roundtrip verified, 10/10)
- tools/render_rooms.py — Color room renderer with per-room palettes
- 220 room screen renders in rooms4/ directory

### mt23 Note
mt23 shares Copycat house (mt16) room data but uses Castle tileset (bank $2A
id $00). Renders as garbage — likely unused/debug variant.

### Still TODO
- [ ] LZSS compressor (create new tile layouts for custom rooms)
- [ ] Bank $0B room data → labeled db blocks
- [ ] Monster name pointer table ($41:$4339) → label-based dw
- [ ] Bank annotations: $51 (battle init), $56 (text engine), $57 (battle dispatch)
- [ ] GUI editor: parse labeled .asm blocks
- [ ] NPC type lower nibble values (what do 1-10 mean specifically?)
- [ ] Sprite graphics table (full mapping from sprite ID to tile data address)
