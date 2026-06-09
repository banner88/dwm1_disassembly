# DWM1 ROM Hack — Session Handoff (June 2026, Monster Data Session)

## What Was Completed This Session

### 1. Monster Info Table — Fully Decoded (Bank $03:$4461)
All 43 bytes mapped. 221 entries. Loader at `Call_003_4446` (entry 1).
Fields: family, level cap, exp table, female ratio, can_fly, is_metal, 3 skills,
6 growth rates (HP/MP/ATK/DEF/AGL/INT confirmed by code trace), 26 resistances
(A-Z FAQ-confirmed, 0=weak..3=immune), tier/rank (byte_2A, unverified label).

### 2. Breeding System — Fully Reverse-Engineered (Bank $16)
- **Special table** ($16:$4B30): 825 entries × 5 bytes, checked FIRST
- **Family table** ($16:$4974): 197 result species, checked SECOND
- Fallback: offspring = parent 1 species
- Mutation RNG at $16:$44DA
- All code annotated in bank_016.asm

### 3. Enemy Stats — Fully Decoded (Bank $14:$4C1D)
All 25 bytes mapped. 487 entries. Loader at `Call_014_4849`.
Species, EXP reward (16-bit, code-traced), joinability (0-7 → $DB85, code-traced),
level, HP/MP/ATK/DEF/AGL/INT, AI weights, skills.

### 4. Resistance System — Complete (26 types A-Z, FAQ-confirmed)
Packing at $51:$4404, unpacking at $52:$67BB+. 0=weak, 3=immune. Index 26 = unused.

### 5. Boss Join System — Annotated (Bank $54:$55BB)
Joinability from enemy stats byte 3 → $DB85. RNG probability. Full code annotated.

### 6. Disassembly Annotations — 5 Banks
bank_001 (encounters), bank_003 (monster info), bank_014 (enemy stats/boss),
bank_016 (breeding), bank_054 (join). All build byte-identical.

### 7. Documentation Consolidated (21 → 13 files)
### 8. Extracted Data Cleaned (37 → 32 files, superseded files deleted)
### 9. dwm Package + Tool Updates (randomize.py, dump_monsters.py, test_roundtrip.py)

## Build Verification
MD5: `1ca6579359f21d8e27b446f865bf6b83` (byte-identical)

## Remaining Unknowns (Medium Priority)
- **byte_2A** in monster info: labeled "tier/rank", not verified
- **Party struct gaps**: offsets $00-$08, $0B-$4A, $5C-$61, $63-$67 unmapped
- **AI weights** (enemy stats bytes 17-20): not code-traced
- **Skill properties**: MP costs, power, target types not extracted

## What's Next — Full Disassembly Annotation

The ROM has 128 banks. Only 9 have meaningful annotations (banks $00, $01, $03, $04,
$0B, $0C-$0F headers, $14, $16, $50, $54). The goal is a fully labeled disassembly
where ROM changes are made in .asm files, not byte patches.

### Priority 1: Annotate Remaining Game System Banks
These banks contain code that editor.py patches via raw bytes. Each needs the same
treatment banks $03/$14/$16 got this session — header comments, function labels,
data table labels, RAM variable documentation:

| Bank | System | Current Status |
|------|--------|----------------|
| $13 | Level-up, stat growth, exp tables | Growth calc partially traced, no labels |
| $41 | Monster/skill name tables | Table addresses known, no labels |
| $50 | Event state machine (11+15 states) | Header documented, no inline labels |
| $51 | Battle init, resistance packing, enemy setup | Key functions traced, no labels |
| $52 | Battle system, skill functions, SkillFunctionTable | Table found, no labels |
| $56 | Text rendering engine | Identified, not annotated |
| $57 | Battle dispatch | Entry points found, not annotated |
| $17 | Palette system | Not annotated |

### Priority 2: Convert Data Tables to db Statements
Currently, data tables (monster info at $03:$4461, boss table at $14:$4893,
encounter pools at $01:$6AAE, breeding tables at $16:$4B30/$4974, enemy stats
at $14:$4C1D, skill function table at $52:$4011) are disassembled as instructions
by mgbdis. Converting these to proper `db` statements with labels would:
- Make them editable in the .asm directly
- Allow the assembler to catch size errors
- Make the disassembly self-documenting

This is the path from "byte patches in editor.py" to "changes in .asm files."

### Priority 3: Remaining Reverse Engineering
- Party struct complete mapping (149 bytes — name, equipped skills, personality)
- Skill properties (MP cost, power, target from bank $52 functions)
- Experience curve tables (bank $13:$41E6)
- Growth rate tables (bank $13:$6706)
- byte_2A purpose

### Priority 4: Editor.py → Disassembly Migration
Once data tables are in db format, editor.py's patch systems can be replaced with
direct .asm edits:
- Encounter pools: edit db blocks at $01:$6AAE
- Boss table: edit db blocks at $14:$4897
- Enemy stats: edit db blocks at $14:$4C1D
- Monster info: edit db blocks at $03:$4461
- Breeding: edit db blocks at $16:$4B30 and $4974

## Deleted Files (this session)
```
documentation/: OLD_HANDOFF.md, NPC_AND_ROUTING_HANDOFF.md, DISASSEMBLY_STRATEGY.md,
  GRAPHICS_HANDOFF.md, DISCOVERIES_v2.md, DISASSEMBLY_CATALOG.md, TEXT_ENCODING.md,
  TEXT_SYSTEM_ARCHITECTURE.md, ROUTING_DISCOVERIES.md, ROUTING_HANDOFF.md,
  CROSSBANK_ROOMS_DESIGN.md, CROSSBANK_ROOMS_HANDOFF.md
extracted/: monsters.json, monster_names.json, breeding_recipes.json,
  always_join_patch.json, transitions.csv
```

## Repo Update Instructions
```bash
# 1. Delete stale docs
git rm documentation/OLD_HANDOFF.md documentation/NPC_AND_ROUTING_HANDOFF.md \
      documentation/DISASSEMBLY_STRATEGY.md documentation/GRAPHICS_HANDOFF.md \
      documentation/DISCOVERIES_v2.md documentation/DISASSEMBLY_CATALOG.md \
      documentation/TEXT_ENCODING.md documentation/TEXT_SYSTEM_ARCHITECTURE.md \
      documentation/ROUTING_DISCOVERIES.md documentation/ROUTING_HANDOFF.md \
      documentation/CROSSBANK_ROOMS_DESIGN.md documentation/CROSSBANK_ROOMS_HANDOFF.md

# 2. Delete superseded extracted data
git rm extracted/monsters.json extracted/monster_names.json \
      extracted/breeding_recipes.json extracted/always_join_patch.json \
      extracted/transitions.csv

# 3. Extract archive into repo root
tar xzf dwm1_session_output.tar.gz

# 4. Stage everything
git add disassembly/bank_*.asm documentation/ extracted/ dwm/ tools/

# 5. Verify build
cd disassembly && make && md5sum game.gbc

# 6. Commit
git commit -m "Monster/battle/breeding: full decode, 5 banks annotated, docs consolidated"
```
