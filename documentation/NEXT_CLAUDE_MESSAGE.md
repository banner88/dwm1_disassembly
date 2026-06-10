# DWM1 Disassembly Project — Handoff to Next Claude Instance

## What This Project Is

Reverse-engineering / disassembly of **Dragon Warrior Monsters** (DWM1), GBC RPG from 1998. Goal: total control — custom rooms, NPCs, events, cutscenes, and eventually a GUI editor.

ROM auto-disassembled via **mgbdis**, our job is converting it to properly labeled, human-readable RGBDS assembly with documented data structures.

## The User's Working Style

- **Ultimate authority** on game mechanics. Knows the game deeply.
- **Do NOT jump ahead.** Priority is DISASSEMBLY and ANNOTATION, not building custom content.
- **Verify before claiming done.** Always build and check MD5.
- End goal: **custom game editor** with custom triggers, events, quests.

## Critical Build Rules

```bash
cd disassembly && rm -f game.o game.gbc game.sym game.map && make && md5sum game.gbc
# MUST output: 1ca6579359f21d8e27b446f865bf6b83
```
- **NEVER run `make clean`** — deletes .2bpp graphics files
- RGBDS v0.6.1 at `~/.local/bin/`

## Setup

- **Repo:** `https://github.com/banner88/dwm1_disassembly.git`
- **ROM:** user uploads `DWM-original.gbc` → `data/DWM-original.gbc`
- Build RGBDS: `cd /tmp && git clone https://github.com/gbdev/rgbds.git && cd rgbds && git checkout v0.6.1 && make -j4 && cp rgb{asm,link,fix} ~/.local/bin/`
- Read: `documentation/SESSION_HANDOFF.md`, `documentation/DATA_STRUCTURES.md`
- **Read `documentation/SCRIPT_TOOLS.md` before touching any script tool or bank.**

## What's Done

### Script System — FULLY DECODED
- **530 NPC scripts** across banks $0C/$0D/$0E/$0F, 1,626 labels
- **100 opcodes**, all decoded, **0 unknowns** across 5,377 commands
- **22 opcodes verified** via SameBoy visual trace of the Warubou cutscene
- **Decompiler:** `tools/decompile_script.py --map <bank> <map_type>`
- **Custom ROM tested:** modified Watabou behavior confirmed working
- **Cutscenes = same script engine** (not a separate system)
- **Player control** is automatic ($D8D7 bit 0)
- See `CUSTOM_CUTSCENES.md` for the full creation guide

### Fully Annotated Data Banks
| Bank | Contents | Labels | Status |
|------|----------|--------|--------|
| $03 | Monster info (221×43B) | ~250 | ✅ Done |
| $0B | Room data ($4B43-$7FFF) | ~800 | ✅ Done |
| $0C-$0F | Script data (530 scripts) | 1,626 | ✅ Done, 0 unknowns |
| $13 | EXP/growth tables | ~100 | ✅ Done |
| $14 | Enemy stats (487×25B) | ~500 | ✅ Done |
| $16 | Breeding + gate + encounters | 234 | ✅ Done |
| $17 | Palette/attribute tables | ~210 | ✅ Ptr tables done |
| $41 | Name/text tables + strings | 933 | ✅ Done |
| $52 | Skill functions + battle | 912 | ✅ Done |
| 14 tileset banks | LZSS tile data | ~500 | ✅ Done |

### Generator Tools
| Tool | Generates |
|------|-----------|
| `gen_script_banks.py` | Script data banks $0C-$0F (`--apply`) |
| `decompile_script.py` | Human-readable pseudo-code (`--map`) |
| `gen_monster_db.py` | Bank $03 monster info |
| `gen_enemy_stats_db.py` | Bank $14 enemy stats |
| `gen_encounter_db.py` | Bank $01 encounter pools |
| `gen_room_data_db.py` | Bank $0B room data (`--apply`) |
| `gen_tileset_banks.py` | 14 tileset banks (`--apply`) |
| + 5 more generators | See DATA_STRUCTURES.md |

## NOT Done — Priority for Next Session

### HIGH PRIORITY
1. **Script compiler** — reverse of decompiler: pseudo-code → `dw` assembly
2. **GUI editor prototype** — web-based script editor

### MEDIUM PRIORITY
3. **Bank $00 function naming** — 466 Call_ labels remain
4. **Bank $04 code annotation** — 833 auto-labels in script VM
5. **Bank $17 per-room data** — data blocks still raw hex

### LOWER PRIORITY
6. NPC behavior values, collision data
7. Event state machine (Bank $50/$51)

## Key Map Types Identified
| Type | Name | Bank | Notes |
|------|------|------|-------|
| $00 | Castle | $0C | Main castle, throne room |
| $01 | GreatTree | $0C | Overworld hub |
| $08 | TransitionScreen | $0D | Screen transition effect |
| $09 | MonsterShrine | $0D | Starry Night intro shrine |
| $2F | Bedroom | $0E | Terry+Milayou bedroom, Warubou cutscene |
