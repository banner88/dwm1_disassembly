# Dragon Warrior Monsters (GBC) — Annotated Disassembly

A work-in-progress annotated disassembly of Dragon Warrior Monsters (1998, Game Boy Color), targeting a fully labeled ROM that assembles byte-identically to the original.

**ROM**: Dragon Warrior Monsters (USA)  
**MD5**: `1ca6579359f21d8e27b446f865bf6b83`  
**Assembler**: [rgbds](https://github.com/gbdev/rgbds) v0.6.1

## Quick Start

```bash
# Clone
git clone https://github.com/banner88/dwm1_disassembly.git
cd dwm1_disassembly

# Build rgbds 0.6.1 — ALL tools (rgbasm, rgblink, rgbfix, rgbgfx)
git clone https://github.com/gbdev/rgbds.git /tmp/rgbds
cd /tmp/rgbds && git checkout v0.6.1
sudo apt-get install -y bison
make && sudo cp rgbasm rgblink rgbfix rgbgfx /usr/local/bin/
cd -

# Build ROM
cd disassembly
rm -f game.o game.gbc game.sym game.map
make
# Output: game.gbc (MD5 must match 1ca6579359f21d8e27b446f865bf6b83)

# Run tools (need original ROM in data/)
cd ..
mkdir -p data
cp /path/to/DWM-original.gbc data/
python3 -m tools.dump_boss_table
```

> **CRITICAL: Never run `make clean`.** It deletes the 18 `.2bpp` graphics files in
> `disassembly/gfx/` which are committed binary assets. These CANNOT be regenerated
> from the `.png` files — rgbgfx produces different bytes, breaking the MD5 match.
> When rebuilding, only delete: `rm -f game.o game.gbc game.sym game.map`

## Repo Structure

```
disassembly/        The disassembly itself
  game.asm          Main file — includes all banks + charmap
  charmap.asm       Character encoding (A-Z, a-z, DTE pairs)
  bank_000.asm      ROM bank 0 (always mapped): RST dispatch, math, event flags, text
  bank_001.asm      Encounters, NPC talk handler, gate data          [ANNOTATED]
  bank_003.asm      Monster info table (221 species × 43 bytes)      [ANNOTATED]
  bank_004.asm      NPC script engine (100 opcodes)                  [ANNOTATED]
  bank_00b.asm      Room system: loading, exits, NPCs, transitions   [ANNOTATED]
  bank_00c-00f.asm  Script data banks (per map_type tier)            [HEADERS]
  bank_014.asm      Enemy stats table, boss redirect table           [ANNOTATED]
  bank_016.asm      Breeding system (two recipe tables)              [ANNOTATED]
  bank_050.asm      Event state machine                              [ANNOTATED]
  bank_054.asm      Post-battle join system                          [ANNOTATED]
  bank_0xx.asm      105 banks total, most unannotated (mgbdis output)
  Makefile

documentation/      Technical reference (13 files)
  SESSION_HANDOFF.md    Latest session status and next priorities
  ARCHITECTURE.md       Bank map, free space, RST dispatch, key RAM
  MONSTER_DATA.md       Monster info, enemy stats, resistances, join system
  BREEDING_SYSTEM.md    Complete breeding algorithm + both recipe tables
  TEXT_SYSTEM.md        Text encoding, NPC dialogue pipeline, text ID routing
  BANK04_SCRIPT_ENGINE.md  100 script opcodes, command tables
  EVENT_FLAGS.md        Story flags with SameBoy verification
  ROUTING.md            Room transitions, exit data format
  CROSSBANK_ROOMS.md    Cross-bank custom room system design
  SAMEBOY_GUIDE.md      Debugger setup and breakpoint recipes
  known_RAM_map.md      RAM variable reference
  known_ROM_map.md      ROM function/table reference (large)
  known_NOTES.md        Miscellaneous notes

extracted/          Decoded game data (32 JSON files)
  monsters_full.json     221 monsters — all 43 fields labeled
  enemy_stats.json       487 enemy stat entries — all 25 bytes decoded
  breeding_complete.json Both breeding tables (825 special + 197 family)
  resistance_types.json  26 resistance types (A-Z, FAQ-confirmed)
  skills.json            256 skill names + function addresses
  text_id_map.json       2067 text IDs → decoded English
  all_scripts.json       209 NPC scripts with command sequences
  boss_table.json        32 gate bosses with fight/join EIDs
  encounters.json        128 encounter pools decoded
  (+ 23 more: NPCs, exits, routing, text, sprites, etc.)

tools/              Analysis and dump scripts (43 Python files)
  dump_boss_table.py     Dump boss fight/join EID table
  dump_encounters.py     Dump encounter pool data
  dump_enemy_stats.py    Dump enemy stat entries
  dump_monsters.py       Dump monster info table
  dump_monster_names.py  Dump monster name table
  dump_all_npcs.py       Dump NPC data for all rooms
  dump_all_text.py       Dump all text from handler banks
  randomize.py           Randomize stats/skills/names
  (+ 35 more: routing, transitions, exits, analysis, etc.)

dwm/                Python support package for tools
  rom.py            ROM class (bank:offset addressing, read, read_until)
  text.py           Text encode/decode (charmap, DTE, control codes)

editor/             GUI ROM editor (legacy, uses byte patches)
  editor.py         Tkinter-based editor for encounters, bosses, text, NPCs
```

## What's Been Reverse-Engineered

### Fully Decoded Systems
| System | Bank(s) | Status |
|--------|---------|--------|
| Monster info table | $03 | 43-byte format fully mapped, 221 entries |
| Enemy stats table | $14 | 25-byte format fully mapped, 487 entries |
| Boss redirect table | $14 | 33 entries (fight EID → join EID) |
| Breeding engine | $16 | Algorithm traced, both recipe tables extracted |
| NPC script engine | $04 | 100 opcodes cataloged |
| NPC→dialogue pipeline | $01/$0B/$04/$0C-$0F | Complete chain traced |
| Text system | $42-$4E/$56 | Encoding, DTE, routing cascade for 2067 IDs |
| Event flags | $00 | Set/clear/check functions, major story flags mapped |
| Event state machine | $50 | 11 gameplay states + 15 post-battle states |
| Encounter system | $01 | Pool format, gate→pool→floor mapping |
| Room/exit system | $0B | Exit data, transitions, NPC lookup chain |
| Resistance system | $51/$52 | 26 types, packing/unpacking, FAQ-confirmed |
| Join system | $54 | Joinability check, RNG probability |
| Stat growth | $13 | 6 growth curves, plus-based bonus scaling |

### Resistance Types (26, confirmed A-Z)
Fire, Heat, Explosion, Wind, Lightning, Ice, Accuracy, Sleep, Death, MP Drain,
SpellBlock, Confusion, DefDown, AglDown, Sacrifice, MegaMagic, FireBreath,
IceBreath, Poison, Paralyze, Curse, MissATurn, DanceBlock, BreathBlock, Aid, GigaSlash.
Values: 0=weak, 1=some resist, 2=normal, 3=immune.

### Key RAM Regions
| Range | Purpose |
|-------|---------|
| $C800-$C9FF | System state, room/map, screen, floor, gate |
| $CA21-$CA50 | Inventory (items) |
| $CAC1-$D6B0 | Party/storage monsters (20 slots × $95 bytes each) |
| $D8D0-$D8DF | Script engine state |
| $D99B+ | Event flag bitfield |
| $DA00-$DA7F | Temp: enemy stats copy, monster info copy, breeding vars |

## How to Work With the Disassembly

### Making ROM Changes
The goal is to edit `.asm` files directly, then `make` to build a modified ROM.

**Currently possible** (annotated systems):
- Edit NPC scripts by modifying script data in banks $0C-$0F
- Edit text by modifying text data in banks $42-$4E
- Set/check event flags from scripts

**Next step** (requires converting data to `db` statements):
- Edit monster stats, resistances, skills, growth rates (bank $03)
- Edit encounter pools (bank $01)
- Edit boss table and enemy stats (bank $14)
- Edit breeding recipes (bank $16)

Currently these data tables are disassembled as fake instructions (`nop; dec l; inc b`)
by mgbdis. Converting them to labeled `db` blocks is the key remaining work to make
the disassembly fully editable.

### Using Tools
Tools require the original ROM at `data/DWM-original.gbc` and Python 3.10+:
```bash
python3 -m tools.dump_boss_table     # Dump boss table
python3 -m tools.dump_encounters     # Dump encounter pools
python3 -m tools.dump_monsters       # Dump monster info
python3 -m tools.randomize --mode chaos --seed 42  # Randomize
```

### Using the Editor (Legacy)
The Tkinter GUI editor at `editor/editor.py` applies byte patches to a ROM copy.
It works but the long-term goal is to replace it with direct `.asm` edits.

## Current Status

**9 of 105 banks** have meaningful annotations. The remaining ~96 banks are raw mgbdis
output with auto-generated labels. See `documentation/SESSION_HANDOFF.md` for detailed
next-session priorities and `documentation/ARCHITECTURE.md` for the bank map.
