# DWM1 ROM Hack — Session Handoff

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

### 1. Script Data Banks $0C/$0D/$0E/$0F — Full Conversion
Converted all 4 NPC script data banks from ~58,000 lines of misassembled
garbage into properly labeled, annotated `dw` data tables.

- **530 NPC scripts** across 96 map types, fully delineated
- **1,626 labels** (pointer tables, script starts, branch targets)
- Every `dw` word annotated with opcode names, text previews, branch refs
- Generator: `tools/gen_script_banks.py --apply`

Key technical discovery: script data uses ODD byte alignment (packed
back-to-back). Master table indexed by ABSOLUTE map type value.

### 2. Script Decompiler
Built `tools/decompile_script.py` — converts raw `dw` script data into
human-readable pseudo-code. All 100 opcodes decoded, **0 unknowns** across
5,377 commands.

### 3. SameBoy Debugger Trace — First 5 Minutes
Traced the game's opening sequence with breakpoints:
- Identified Bedroom = map_type $2F (bank $0E), Monster Shrine = $09
- Confirmed cutscenes use the NPC script engine (not a separate system)
- Warubou cutscene = branch within Bedroom_Script00 at screen 5

### 4. Opcode Verification — 22 Confirmed via Visual Trace
Cross-referenced decompiled scripts against observed gameplay:
- **walk_x ($1A) = horizontal, walk_y ($1B) = vertical** (confirmed via chase)
- **npc_show ($49), npc_hide ($48)** (confirmed via Warubou appear/disappear)
- **trigger_anim ($1C) with $01XX = jump** (confirmed: Terry/Watabou jump)
- **write_ram ($12)** = write value to RAM (335 uses, was mislabeled)
- **Player control** = automatic via $D8D7 bit 0 (script active flag)

### 5. Custom ROM — Modified Watabou Cutscene (Verified Working!)
Created and tested custom ROM with 9 byte changes:
- Watabou jumps first (before Terry)
- Frantic timing (1-frame delays instead of 4-8)
- Sprints 7 tiles left/right (instead of 3)
- Confirmed working in SameBoy — proves full round-trip capability

### 6. Custom Cutscene Documentation
Created `CUSTOM_CUTSCENES.md` — comprehensive guide to creating custom
cutscenes including verified opcode reference, construction patterns,
three modification methods, and the Watabou example.

### 7. All Documentation Updated
- `DATA_STRUCTURES.md` — script banks, verified opcodes, decompiler tool
- `CUSTOM_CUTSCENES.md` — NEW: cutscene creation guide
- `FIRST_5MIN_TRACE.md` — NEW: SameBoy trace instructions
- `BANK04_SCRIPT_ENGINE.md` — script bank annotation reference
- `ARCHITECTURE.md` — script bank description expanded
- `SESSION_HANDOFF.md` — this file
- `NEXT_CLAUDE_MESSAGE.md` — updated for next instance

## All Completed Work (All Sessions Combined)

### Fully Annotated Data Banks
| Bank | Contents | Labels | Status |
|------|----------|--------|--------|
| $03 | Monster info table (221×43B) | ~250 | Done |
| $0B | Room data system ($4B43-$7FFF) | ~800 | Done |
| $0C | Script data (Castle/GreatTree/Bazaar/GateHub/Farm/Stable) | 452 | Done |
| $0D | Script data (Arena/GateTileset/CopycatRoom/MedalMan/Well) | 614 | Done |
| $0E | Script data (Gate rooms, boss rooms, Bedroom) | 287 | Done |
| $0F | Script data (Late-game boss rooms, post-game) | 273 | Done |
| $13 | EXP curves + growth tables | ~100 | Done |
| $14 | Enemy stats (487×25B) + boss redirect | ~500 | Done |
| $16 | Breeding + gate floor + encounter system | 234 | Done |
| $17 | Palette/attribute tables | ~210 | Ptr tables + 92 room attr labels |
| $41 | ALL name/text tables + strings | 933 | Done |
| $52 | Skill functions + battle system | 912 | Done |
| 14 tileset banks | LZSS tile data pointer tables | ~500 | Done |

### Script System — Fully Decoded
- 530 scripts, 5,377 commands, 0 unknown opcodes
- 22 opcodes verified via SameBoy visual trace
- Custom ROM modification tested and confirmed working
- Decompiler produces accurate readable output
- Cutscene creation guide written

### Named Functions: 149 in Bank $00, plus others across banks
### WRAM Symbols: 81 unique, 4,676 replacements

## NOT Done — Priority Work for Next Session

### HIGH PRIORITY (toward custom event editor)
1. **Script compiler tool** — reverse of decompiler: human-readable →
   `dw` assembly. This completes the read/write loop for custom events.
2. **GUI editor prototype** — web-based editor using the decompiler/compiler
   tools to create scripts visually.

### MEDIUM PRIORITY
3. **Bank $00 function naming** — 466 Call_ labels remain.
4. **Bank $04 code annotation** — 833 auto-labels in VM code.
5. **Bank $17 per-room data parsing** — data blocks still raw hex.
6. **More WRAM expansion** — 81 symbols done, more to decode.

### LOWER PRIORITY
7. NPC behavior values (lower nibble specific meanings)
8. Collision data system
9. Event state machine (Bank $50/$51) — for non-script-based events

## Key Documentation
- `DATA_STRUCTURES.md` — Canonical data structure catalog
- `SCRIPT_TOOLS.md` — **How to use gen_script_banks.py and decompile_script.py**
- `CUSTOM_CUTSCENES.md` — Custom cutscene creation guide
- `BANK04_SCRIPT_ENGINE.md` — Script VM: 100 opcodes, state machine
- `ROOM_DATA_FORMAT.md` — Room data format reference
- `BREEDING_SYSTEM.md` — Breeding recipe system
- `TEXT_SYSTEM.md` — Text encoding and control codes
- `EVENT_FLAGS.md` — Flag bitfield, story progression
