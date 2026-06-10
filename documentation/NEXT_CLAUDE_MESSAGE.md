# DWM1 Disassembly Project — Handoff to Next Claude Instance

## What This Project Is

This is a **reverse-engineering / disassembly project** for **Dragon Warrior Monsters** (DWM1), a Game Boy Color RPG from 1998. The user wants "total control" over the game — the ability to create custom rooms, place NPCs, edit tile layouts, modify game events, and eventually build a GUI editor for all of this.

The ROM was auto-disassembled using **mgbdis** (a GB/GBC disassembler) which produces functional but unreadable assembly — raw hex bytes with auto-generated labels like `Call_003_4461`. Our job is to systematically convert this into **properly labeled, human-readable RGBDS assembly** where data tables are `db`/`dw` blocks with meaningful labels, code is annotated, and the game's systems are documented.

**The toolchain:**
- **RGBDS** (v0.6.1, built from source) — the assembler/linker. `rgbasm` + `rgblink` + `rgbfix`
- **mgbdis** — produced the initial disassembly (already done, we're cleaning it up)
- **SameBoy** / **Emulicious** — GBC emulators the user runs for debugging and verification
- Python tools in `tools/` — data extraction, tile decompression/compression, rendering

## The User's Working Style

**READ THIS CAREFULLY:**
- The user is the **ultimate authority** on game mechanics. They know the game deeply. If you're unsure, ASK rather than assume.
- **Do NOT jump ahead.** The user has repeatedly (and correctly) pushed back when Claude tries to skip verification, declare things "ready for building," or rush past annotation work. The priority is DISASSEMBLY and ANNOTATION, not building custom content yet.
- **Verify before claiming done.** When you convert a data table or decode a format, the user will verify against the actual game. Don't declare victory prematurely.
- **Show visual evidence.** The tile renderer can produce room images — show them to the user and they can instantly tell you if something is right or wrong. This is the fastest debugging method.
- **SameBoy debugger syntax:** `watch $ADDR w` (not `watchpoint`), `print [$ADDR]`, `backtrace`, `continue`. The user can set breakpoints and dump memory.

## Critical Build Rules

- **NEVER run `make clean`** — it deletes .2bpp graphics files that cannot be regenerated
- Build: `rm -f game.o game.gbc game.sym game.map && make` (from `disassembly/` directory)
- ROM MD5 must always be: `1ca6579359f21d8e27b446f865bf6b83`
- RGBDS v0.6.1 is built from source at `/home/claude/.local/bin/`

## Project Setup

- **Repo:** clone from `https://github.com/banner88/dwm1_disassembly.git` to `/home/claude/dwm1_disassembly/`
- **ROM:** user uploads `DWM-original.gbc` → copy to `data/DWM-original.gbc`
- Read these docs first: `documentation/SESSION_HANDOFF.md`, `documentation/ROOM_DATA_FORMAT.md`, `documentation/ARCHITECTURE.md`

## What's Been Done (Previous Sessions)

### Data Tables — All Converted, MD5 Verified
10 data tables converted from mgbdis fake instructions to labeled `db`/`dw` blocks:
- Monster info ($03:$4461, 221×43B entries)
- Boss redirect ($14:$4893, 35 entries)
- Enemy stats ($14:$4C1D, 487×25B entries)
- Encounter pools ($01:$6A22, 128×26B pools)
- Skill function table ($52:$4011, 256×2B pointers)
- Monster names ($41:$5B1F, charmap encoded)
- Skill names ($41:$628E, charmap encoded)
- Exp curves ($13:$41E6, 32×297B tables)
- Growth tables ($13:$6706, 32×99B tables)
- Charmap moved to line 86 in game.asm (before bank_041)

Generator tools in `tools/gen_*.py` can regenerate each table from ROM data.

### Room Data System — Fully Decoded, Debug Verified
The room system was reverse-engineered and verified via SameBoy watchpoints/breakpoints:

**Screen grid:** 4×2 positions (indices 0-7), formula: `screen = row×4 + column`

**Pointer chain:** `$4B43[mapID×2]` → sub-table → room_data_block → step entries

**Step entry (6 bytes):** `[step_id, tileset_bank, interact_ptr, exit_ptr]`
- step_id + tileset_bank index LZSS-compressed tile layouts in 9 tileset banks
- interact_ptr → mixed NPC + spawn block (5-byte entries, $FF terminated)
- exit_ptr → exit checker block (7-byte entries, $FF terminated)

**NPC entry (5 bytes):** `[type, sprite, x, y, script]`
- Type bits 5-4 = facing direction, bit 6 = non-interactable

**Exit entry (7 bytes):** `[trigger_x, trigger_y, dest_mt, gate_flag, screen, spawn_x, spawn_y]`

Full details in `documentation/ROOM_DATA_FORMAT.md`.

### Tile Rendering Pipeline — Complete
- **LZSS decompressor** (`tools/decompress_tiles.py`) — with circular buffer wrapping fix
- **LZSS compressor** (`tools/compress_tiles.py`) — roundtrip verified 10/10
- **Color renderer** (`tools/render_rooms.py`) — tiles + attributes + per-room palettes
- **Attribute lookup** has TWO paths:
  - Normal rooms: `$476F[mapID]` → screen → step-dependent entries
  - Gate rooms: `$C940[$C925]` → `$5215/$5415` table (decoded but NOT wired into renderer)
- 80 room palettes captured from SameBoy → `extracted/room_palettes.json`
- 220 room screens rendered (see `ALL_ROOMS_FINAL.png`)

### Cross-Bank Room System (in editor.py)
`editor/editor.py` has working, user-verified code for custom rooms using bank $68 + WRAM trampoline at $0B:$77A9. 128-byte room blocks, pointer table patched for mt $65+.

### Tool Fixes Applied
- `dump_map_table.py`: interact_ptr/exit_ptr labels were SWAPPED — fixed
- `find_all_transitions.py`, `find_transitions.py`: same swap — fixed
- All extracted JSONs regenerated with correct field names

## NOT Done — Priority Work for Next Session

**Do NOT start building custom rooms.** The disassembly annotation is incomplete.

### HIGH PRIORITY (core disassembly work)
- [ ] **Bank $0B room data → labeled db blocks** — the room sub-tables, step entries, interact blocks, and exit blocks are still raw mgbdis hex. Convert them to labeled `db`/`dw` format like the monster tables were. This is the single most important remaining task.
- [ ] **Gate room attribute rendering** — the $C940/$5215 lookup path is decoded but not wired into the renderer. Gate rooms on the contact sheet render with wrong colors.
- [ ] **Tileset bank pointer tables** ($23-$37 at $4001) → labeled data
- [ ] **Bank $17 attribute/palette tables** → labeled data
- [ ] **Monster name pointer table** ($41:$4339) → label-based `dw MonsterName_XXX`

### MEDIUM PRIORITY
- [ ] Bank $3C/$3D/$3E attribute data annotation
- [ ] Collision data (what makes tiles walkable — mechanism unknown)
- [ ] Palette extraction from ROM tables (currently requires SameBoy captures)
- [ ] Animated tile system (water etc.)

### LOWER PRIORITY
- [ ] Bank annotations: $51 (battle init), $56 (text engine), $57 (battle dispatch)
- [ ] NPC type lower nibble specific meanings (needs gameplay testing)
- [ ] Full sprite graphics pipeline
- [ ] GUI editor

## Key Patterns Learned

**Embedded labels:** When data tables contain addresses that mgbdis interpreted as code (creating fake labels like `Call_003_59d0`), those labels must be preserved because real code references them. Check with `grep` before removing any label.

**LZSS compression:** Used throughout the game for tile graphics, tile layouts, and attribute data. Same algorithm everywhere, with a configurable marker byte. The circular buffer wraps by subtracting $1000 from back-reference addresses.

**Step system:** Rooms change appearance based on story progression. Each screen has a RAM step counter ($D9xx), and the step value selects which tile layout, NPC set, exit set, and attribute data to use. The same screen can look completely different at different steps.

**The user can verify visually:** Render a room image and show it to them — they'll immediately tell you if it's correct or what's wrong. This is far faster than trying to verify from hex dumps.
