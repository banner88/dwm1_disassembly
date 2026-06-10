# DWM1 Disassembly Project — Handoff to Next Claude Instance

## What This Project Is

This is a **reverse-engineering / disassembly project** for **Dragon Warrior Monsters** (DWM1), a Game Boy Color RPG from 1998. The user wants "total control" over the game — the ability to create custom rooms, place NPCs, edit tile layouts, modify game events, and eventually build a GUI editor for all of this.

The ROM was auto-disassembled using **mgbdis** (a GB/GBC disassembler) which produces functional but unreadable assembly — raw hex bytes with auto-generated labels like `Call_003_4461`. Our job is to systematically convert this into **properly labeled, human-readable RGBDS assembly** where data tables are `db`/`dw` blocks with meaningful labels, code is annotated, and the game's systems are documented.

**The toolchain:**
- **RGBDS** (v0.6.1, built from source at `~/.local/bin/`) — the assembler/linker
- **mgbdis** — produced the initial disassembly (already done, we're cleaning it up)
- **SameBoy** / **Emulicious** — GBC emulators the user runs for debugging
- Python tools in `tools/` — data extraction, tile decompression/compression, rendering

## The User's Working Style

- The user is the **ultimate authority** on game mechanics. They know the game deeply.
- **Do NOT jump ahead.** Priority is DISASSEMBLY and ANNOTATION, not building custom content.
- **Verify before claiming done.** Always build and check MD5 after changes.
- **Show visual evidence.** The tile renderer can produce room images for verification.

## Critical Build Rules

```bash
cd disassembly
rm -f game.o game.gbc game.sym game.map
make
md5sum game.gbc
# MUST output: 1ca6579359f21d8e27b446f865bf6b83
```
- **NEVER run `make clean`** — deletes .2bpp graphics files that cannot be regenerated
- RGBDS v0.6.1 is at `/home/claude/.local/bin/` — needs `export PATH` or full path

## Project Setup

- **Repo:** `https://github.com/banner88/dwm1_disassembly.git` → `/home/claude/dwm1_disassembly/`
- **ROM:** user uploads `DWM-original.gbc` → copy to `data/DWM-original.gbc`
- Build RGBDS: `cd /tmp && git clone https://github.com/gbdev/rgbds.git && cd rgbds && git checkout v0.6.1 && make -j4 && cp rgb{asm,link,fix} ~/.local/bin/`
- Read: `documentation/SESSION_HANDOFF.md`, `documentation/ARCHITECTURE.md`

## What's Been Done (All Sessions Combined)

### Fully Annotated Data Banks
| Bank | Contents | Labels | Status |
|------|----------|--------|--------|
| $03 | Monster info table (221×43B) | ~250 | ✅ Complete |
| $0B | Room data system ($4B43-$7FFF) | ~800 | ✅ Complete |
| $13 | EXP curves + growth tables | ~100 | ✅ Complete |
| $14 | Enemy stats (487×25B) + boss redirect | ~500 | ✅ Complete |
| $17 | Palette/attribute pointer tables | ~120 | ✅ Ptr tables done, per-room entries still raw |
| $41 | ALL name/text tables + strings | 933 | ✅ **Complete** (this session) |
| $52 | Skill functions + battle system | 912 | ✅ Handler labels done (this session) |
| 14 tileset banks | LZSS tile data pointer tables | ~500 | ✅ Complete |

### Key Systems Documented
- **Room data format** — fully decoded, debug-verified (ROOM_DATA_FORMAT.md)
- **Breeding system** — special/family recipe tables decoded (BREEDING_SYSTEM.md)
- **Text system** — control codes, charmap encoding (TEXT_SYSTEM.md)
- **Tile rendering pipeline** — LZSS decompress/compress, color rendering
- **Cross-bank room system** — working editor code for custom rooms

### Generator Tools (in `tools/`)
| Tool | Generates | Idempotent? |
|------|-----------|-------------|
| `gen_monster_db.py` | Bank $03 monster info | Yes |
| `gen_enemy_stats_db.py` | Bank $14 enemy stats | Yes |
| `gen_encounter_db.py` | Bank $01 encounter pools | Yes |
| `gen_skill_table_db.py` | Bank $52 skill function table | Yes |
| `gen_name_tables_db.py` | Bank $41 monster/skill name tables | Yes |
| `gen_bank41_remaining_db.py` | Bank $41 all remaining tables | Yes (`--apply`) |
| `gen_room_data_db.py` | Bank $0B room data | Yes (`--apply`) |
| `gen_tileset_banks.py` | 14 tileset banks | Yes (`--apply`) |
| `gen_growth_tables_db.py` | Bank $13 growth tables | Yes |
| `annotate_bank052.py` | Bank $52 skill handler labels | **No** (one-time) |

## NOT Done — Priority Work for Next Session

### HIGH PRIORITY
1. **More Bank $00 function naming** — 466 Call_ labels remain. Next tier
   (3-4 refs) includes ~80 more functions. Data tables at $0515/$0aea/$2bcc
   need investigation (misinterpreted as code by mgbdis).
2. **Bank $17 per-room attribute entries** — pointer tables are labeled but the
   per-room/per-step data blocks between them are still raw hex.
3. **Bank $04 script engine** — 100 opcodes documented but code still
   has auto-generated labels throughout.

### MEDIUM PRIORITY
4. **Bank $52 skill handler code annotation** — handlers labeled but the
   actual damage calc, resistance check, and effect code is uncommented.
5. **Code bank annotations** — $51 (battle init), $56 (text engine), $57 (battle)
6. **More WRAM expansion** — 81 symbols / 4676 refs done. More $C8xx/$C9xx
   game state variables can be decoded from context.

### LOWER PRIORITY
7. NPC behavior values (lower nibble specific meanings)
8. Collision data system (what makes tiles walkable)
9. GUI editor

## Bank $41 Complete Structure Reference

```
$4000-$4338  Code + dispatch table (73 entries, bank byte $41 at $4000)
$4339-$4538  MonsterNamePtrTable (256 × dw)
$4539-$4738  SkillNamePtrTable (256 × dw)
$4739-$48E6  FamilyCodePtrTable (215 × dw)
$48E7-$493E  ItemNamePtrTable (44 × dw)
$493F-$4996  ItemDescPtrTable (44 × dw)
$4997-$49CC  PersonalityNamePtrTable (27 × dw)
$49CD-$4A16  MiscTextPtrTable (37 × dw)
$4A17-$4A1A  WatabouTextPtrTable (2 × dw)
$4A1B-$4A7A  ItemUseTextPtrTable (48 × dw)
$4A7B-$4A92  SpellUseTextPtrTable (12 × dw)
$4A93-$4AA7  Code functions (3 × 7 bytes)
$4AA8-$5B1E  Dispatch text (raw hex with labels at referenced addrs)
$5B1F-$628D  MonsterNameStrings (222 unique, $F0 terminated)
$628E-$69F1  SkillNameStrings (222 unique + 1 empty, $F0 terminated)
$69F2-$6C77  FamilyCodeStrings (215 entries, 2 chars + $F0)
$6C78-$6DF7  ItemNameStrings (43 entries + 1 empty)
$6DF8-$7158  ItemDescStrings (43 entries with $F1=newline)
$7159-$7228  PersonalityNameStrings (27 entries)
$7229-$7FFF  Game text (raw hex with labels for misc/itemuse/spelluse)
```

All pointer tables use label references — editing a string's length auto-updates
its pointer on rebuild. Bank is exactly full (no free space).

## Bank $52 Skill Handler Reference

Function table at $4011 has 222 valid entries (0-221). Entries 222-255 overlap
with handler code. Every handler has a named label (SkillBlaze, SkillSleep, etc.).
Family check functions (CheckIsSlime..CheckIsMaterial) and math helpers
(BCsrl3..HLsrl1) are also labeled.

## ROM Map Intel Available

An external ROM map document with community research was provided. Key data not
yet applied to the disassembly:
- Bank $16: encounter/gate tables with exact formats
- Bank $13: experience table structure (32×297B)
- Bank $50: personality adjustment tables (5 plan types × 4×8 matrices)
- Bank $00: math function signatures (Mul/Div with register conventions)
- Bank $01: gate floor threshold system
- Bank $0B: labyrinth exit coordinate system

See `documentation/SESSION_HANDOFF.md` "ROM Map Intel" section for details.
