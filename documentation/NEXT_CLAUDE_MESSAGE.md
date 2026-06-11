# DWM1 Disassembly Project — Complete Handoff

## 1. What This Project Is

**Dragon Warrior Monsters** (DWM1) — a Game Boy Color RPG from 1998 (Enix/TOSE).
We are reverse-engineering the full ROM into human-readable, buildable RGBDS assembly.

The ROM was auto-disassembled by **mgbdis**, producing ~96 bank files of raw assembly
with auto-generated labels. Our job is converting those labels into meaningful names,
identifying data structures, and annotating the code so the game can eventually be
fully modded with a GUI editor.

**Current state: ~45% named** — ~8,900 properly named labels, ~18,000 auto-labels remaining.
All 2,404 function entry points (`Call_` labels) are named.
Bank $00: ALL 761 internal labels named (0 unaliased remain).
Bank $04: ALL 253 internal labels named (0 unaliased remain).
Remaining auto-labels are internal branch targets in other banks.

## 2. The User

- **Ultimate authority** on game mechanics. Knows DWM1 deeply.
- Priority is **DISASSEMBLY and ANNOTATION**, not building custom content yet.
- Wants **thorough, honest work** — no shortcuts, no silent downgrades.
- Has unlimited Claude usage. Do the hard work.
- Provide changed files as a **zip** for the user to commit. Do NOT use git operations.
- End goal: **custom game editor** with custom triggers, events, quests, rooms.

## 3. Critical Build Rules

```bash
cd disassembly
rm -f game.o game.gbc game.sym game.map
make
md5sum game.gbc
# MUST output: b90957482011c8083a068781033715b7
```

- **NEVER run `make clean`** — deletes `.2bpp` graphics files that can't be regenerated
- **NEVER use `git stash`** — reverts all `.asm` changes (caused data loss previously)
- **RGBDS v0.6.1** required: `~/.local/bin/`
- Build RGBDS: `cd /tmp && git clone https://github.com/gbdev/rgbds.git && cd rgbds && git checkout v0.6.1 && make -j4 && cp rgb{asm,link,fix} ~/.local/bin/`

## 4. Setup Checklist

1. Clone repo: `git clone https://github.com/banner88/dwm1_disassembly.git`
2. User uploads ROM → save as `data/DWM-original.gbc`
3. Build RGBDS v0.6.1 (see above)
4. Build and verify MD5 (see above)
5. Read this file, then `documentation/DATA_STRUCTURES.md`

## 5. What's Done (Cumulative Across All Sessions)

### Data Structures (100% decoded)
- **Monster info** (bank $03): 221 monsters × 43 bytes, fully annotated
- **Enemy stats** (bank $14): 487 entries × 25 bytes
- **EXP tables** (bank $13): 32 growth curves × 99 levels
- **Breeding tables** (bank $16): recipe lookup, mutation, skill inheritance
- **Room data** (bank $0B): pointer chains, exits, NPC entries, SharedPtrChase refactored
- **Palette/attributes** (bank $17): 14 entries decoded, format documented
- **Text system** (bank $41): charmap, DTE pairs, control codes, 100% annotated
- **Skill functions** (bank $52): complete function table, all skill handlers named
- **Event flags**: 311 flags mapped, 463 free slots
- **Tileset data**: 14 banks of LZSS compressed tiles

### Script System (100% decoded)
- 530 scripts across banks $0C-$0F
- 100 opcodes, 0 unknowns
- Decompiler, compiler, and generator tools working
- Banks $0C-$0F regenerable from ROM via `gen_script_banks.py --apply`

### Function Naming (this session)
- **ALL 2,404 `Call_` labels named** — zero unnamed function entry points remain
- Banks $00 and $01 hand-named with descriptive names (396 + 95 functions)
- Banks $02, $52 hand-named with context (44 + 190 functions)
- Remaining banks pattern-named with category prefix + unique address suffix
  (e.g. `LoadBtl_7848`, `CallFld_5629`, `SetBrd_45a3`)


### Dynamic Repointing (this session — CRITICAL)
- **Room data pointer table converted to labels** — gen_room_data_db.py modified
  to output `dw RoomSub_Castle` instead of `dw $4C13`. All 92 unique room data
  blocks are now label-referenced. ROM still matches MD5.
- **14 hardcoded address calculations converted** — `add $XX / adc $YY` patterns
  converted to `add LOW(Label) / adc HIGH(Label)` for: MonsterInfoTable, 
  EnemyStatsTable, ExpCurveTables, StatGrowthTables, EncounterPoolData (6 refs),
  FloorLayoutData (2 refs), FamilyRecipeTable (new label + 2 refs), 
  FloorTilePatterns (new label), label8_447e.
- **22 hardcoded refs remain** — documented in DATA_STRUCTURES.md with target
  addresses and likely purposes. Bank $17 palette refs need db line splitting.

### Label Naming (this session)
- **Bank $00: 761 labels renamed** — ALL auto-labels now named or aliased
- **Bank $04: 253 labels renamed** — ALL auto-labels now named or aliased
### Infrastructure (this session)
- **47 dispatch table headers fixed** — misassembled instructions → proper `db`/`dw`
- **1,028 cross-bank calls traced** — complete `rst $10` call graph
- **Bank role classification** — every bank categorized (battle, field, script, audio, etc.)
- **Dialogue bank system decoded** — banks $42-$4B handle 1,337 text IDs
- **Animation bank pairing** — $1A↔$42/$43, $1B↔$44/$46, $1F↔$45/$48, etc.
- **Community ROM map cross-referenced** — verified against `known_ROM_map.md`

### Tools (14 total)
| Tool | Purpose |
|------|---------|
| `fix_bank_headers.py` | Fix/verify dispatch table headers (ROM+sym based) |
| `gen_script_banks.py` | Regenerate script data banks $0C-$0F (`--apply`) |
| `decompile_script.py` | Human-readable pseudo-code from scripts (`--map`) |
| `compile_script.py` | Pseudo-code → dw assembly (`-o`) |
| `analyze_event_flags.py` | Flag usage report + JSON (`--json`) |
| `analyze_bank17.py` | Palette/attribute data (`--room`) |
| `gen_monster_db.py` | Bank $03 monster info |
| `gen_room_data_db.py` | Bank $0B room data (`--apply`) |
| + 6 more generators | See `DATA_STRUCTURES.md` |

## 6. What's NOT Done — Priority for Next Session

### Priority 1: Practical Editor Workflow Documentation
ALL major data tables are now dynamically repointable. Next step is creating
step-by-step guides: "How to add a custom room", "How to modify breeding",
"How to add new scripts". The tools exist, the data is labeled — glue is needed.

### Priority 2: WRAM Symbol Definitions
Key WRAM regions still use raw addresses ($C8xx, $CAxx, $CBxx, $DBxx).
Define these as named symbols in a shared `.inc` file.

### Priority 3: Jump_/jr_ Naming in Battle Banks
~18,000 auto-labels remain. Banks $00 and $04 are DONE.
Most impactful remaining: Banks $50-$58 (~3,000 auto) for battle system.

### Priority 4: Data Table Conversion (3 misassembled regions)
Bank $0B ($4940-$49A0), Bank $08 ($7740-$7780), Bank $32 ($5A50-$5A70).
These are data bytes misassembled as instructions by mgbdis.

### Priority 2: WRAM Symbol Definitions
Key WRAM regions still use raw addresses in code:
- `$C8xx`: Engine state (screen mode, animation, joypad)
- `$CAxx`: Party/monster data ($CA8D=party count, $CAC1=slot table)
- `$CBxx`: Active monster stats ($CB11=level, $CB13=HP, $CB19=ATK, etc.)
- `$DBxx/$DDxx`: Battle state variables
- `$DExx`: Audio engine state

Defining these as `wXxxYyy` symbols in a shared `.inc` file would massively
improve readability across all banks.

### Priority 3: Data Table Conversion
Several address ranges in bank $00 contain data misassembled as instructions:
- $0515: Cross-bank trampoline table (named `BankTrampolineTable`)
- $26D6-$2929: Multiple data tables (named `DataTable_XXXX`)
- $3200-$33FF: Audio waveform/pattern data (named `AudioWaveData_XXXX`)
These should be converted from instructions to proper `db`/`dw` directives.

### Priority 4: Overflow Room System (DEFERRED)
SharedPtrChase refactoring freed 119 bytes. Architecture documented in
`CROSSBANK_ROOMS.md`. User explicitly said to finish disassembly first.

## 7. Key WRAM Addresses (Quick Reference)

| Address | Name | Purpose |
|---------|------|---------|
| $C850 | wAnimLock | Animation busy flag |
| $C85A | wAnimState | Animation state counter |
| $C86C | wLinkBattle | Link cable battle flag |
| $C8A6 | wVisualEffectStep | Visual effect counter |
| $C88E/$C88F | wScreenLock | Screen update lock |
| $C8B5 | wBGMOffset | Current BGM ID |
| $C899/$C89A | wPRNGState | PRNG state (16-bit) |
| $C968 | wMapID | Current map type |
| $C969 | wInGateworld | Gate world flag |
| $C925 | wScreenIndex | Screen/room index |
| $C935 | wCurrentGate | Current gate ID |
| $C939 | wCurrentFloor | Current dungeon floor |
| $CA8D | wPartyCount | Number of monsters in party |
| $CAC1 | wPartySlotTable | Party slot table (20 entries) |
| $CB11+ | Monster stats | Level, HP, MP, ATK, DEF, AGL, INT, skills |
| $DA12/$DA13 | wEnemyStatsId | Current enemy stats ID |

## 8. Bank Role Map (from call graph analysis)

| Role | Banks |
|------|-------|
| **Engine** | $00 (core), $08 (audio player), $17 (palettes) |
| **Field** | $01 (game loop), $02 (screen), $06 (map), $07 (tiles), $09/$0A (util), $0B (rooms), $15 (transitions) |
| **Script** | $04 (VM), $0C-$0F (data), $10 (util) |
| **Battle** | $50 (core), $51 (setup), $52 (skills), $53-$54 (sub), $55 (display), $57 (AI), $58 (FX) |
| **Dialogue** | $42-$4B (text handlers), $4C (shared UI), $4D (portraits), $4E (text util) |
| **Animation** | $1A, $1B, $1F, $21, $22, $3F (paired with dialogue banks) |
| **Data** | $03 (monsters), $13 (EXP), $14 (enemies), $16 (breeding/gates), $41 (text/names) |
| **UI** | $56 (router), $59 (save/load), $5C-$5F (field UI) |
| **Audio** | $05, $08, $18 |
| **Tilesets** | $23-$26, $28-$31, $37-$38 (14 banks LZSS) |

## 9. Workflow Advice for Next Instance

1. **Read this file first**, then `DATA_STRUCTURES.md` for detailed structures.
2. **Always build and verify MD5** before and after changes.
3. **Work in batches** — name 10-30 functions, build, verify, repeat.
4. **Use the community ROM map** (`known_ROM_map.md`) for cross-referencing.
5. **Update documentation as you go** — everything is lost to the next instance.
6. **The pattern-named functions** (e.g. `LoadBtl_7848`) are placeholders. When you
   understand what a function does, give it a real descriptive name.
7. **Don't present files until the user says done.**
8. **Package as zip** when the user asks — include modified .asm files + docs + tools.

## 10. File Locations

| Path | Contents |
|------|----------|
| `disassembly/bank_*.asm` | All bank assembly files (96 banks) |
| `disassembly/game.asm` | Main assembly file (includes all banks) |
| `disassembly/game.sym` | Symbol file (generated by build) |
| `documentation/` | All documentation (this file + 20 others) |
| `tools/` | Python tools for analysis and generation |
| `extracted/` | Extracted data (crossbank_calls.json, etc.) |
| `data/DWM-original.gbc` | Original ROM (user must provide) |

## 11. Important Warnings

- **NEVER `git stash`** — reverts all .asm changes
- **NEVER `make clean`** — deletes .2bpp graphics
- **Build MD5 `b90957482011c8083a068781033715b7`** reflects SharedPtrChase refactoring
- **MD5 `1ca6579359f21d8e27b446f865bf6b83`** was the ORIGINAL before refactoring — don't use
- **RGBDS v0.6.1** — newer versions may not be compatible
- **ROM not in repo** — user uploads each session
