# Script Tools Reference

## Overview

Two tools handle the NPC script system. They work together:

```
ROM bytes ←→ gen_script_banks.py ←→ labeled .asm files (dw tables)
ROM bytes ←→ decompile_script.py ←→ human-readable pseudo-code
```

`gen_script_banks.py` produces **assembly** — the `dw` entries in the .asm
files that rgbasm compiles. This is what you edit to change the game.

`decompile_script.py` produces **readable output** — for understanding what
scripts do. It reads the ROM directly and is read-only.

---

## gen_script_banks.py

**Purpose:** Replace the misassembled code in banks $0C/$0D/$0E/$0F with
properly labeled `dw` data tables. The original mgbdis output decoded
script DATA bytes as CPU instructions (producing nonsense like `nop`,
`rst $38`). This tool reads the ROM and generates correct assembly.

**How it works:**
1. Reads the ROM at `data/DWM-original.gbc`
2. For each bank, keeps the code section ($4000-$41B9) from the existing
   .asm file unchanged
3. Parses the master pointer table at $41BA (indexed by ABSOLUTE map type)
4. Follows per-map script pointer tables to find all script data
5. Scans script data to find branch targets (addresses referenced in data)
6. Generates `dw` entries with labels and comments for everything from
   $41BA to end of bank

**Critical technical details:**
- Master table is indexed by `$41BA + map_type * 2`, NOT relative to bank range.
  Banks $0E/$0F use offsets $40+ into the table.
- Script data uses ODD byte alignment (scripts packed back-to-back).
  The generator tracks word boundaries per-script, not on a fixed grid.
- Labels are bank-prefixed (`Bank0C_ScriptAddr_XXXX`) to avoid duplicates
  across banks in RGBDS global namespace.
- Branch target detection is heuristic: any in-range odd-aligned address
  in the data is marked as a potential target. Some may be false positives
  (parameter values that happen to look like addresses).

**Usage:**
```bash
# Preview what would be generated (dry run)
python3 tools/gen_script_banks.py

# Apply to all 4 banks
python3 tools/gen_script_banks.py --apply

# Apply to a single bank
python3 tools/gen_script_banks.py --bank 0x0C --apply

# After applying, ALWAYS rebuild and verify:
cd disassembly && rm -f game.o game.gbc game.sym game.map && make && md5sum game.gbc
# Must output: 1ca6579359f21d8e27b446f865bf6b83
```

**When to re-run:** After any manual edit to the script data in the .asm
files, run `--apply` to regenerate from ROM. This is idempotent — running
it twice produces identical output. BUT: if you've manually edited a bank's
script data, `--apply` will OVERWRITE your edits with the original ROM data.
Only use after edits to the generator itself.

**Output format:** Each bank gets:
- Master table: `Bank0C_ScriptMasterTable:` with `dw MapName_ScriptPtrTable`
- Per-map tables: `Castle_ScriptPtrTable:` with `dw Castle_Script09`
- Script data: `Castle_Script09:` followed by `dw $XXXX  ; opcode/text/param`
- Branch targets: `Bank0C_ScriptAddr_5273:`

**Dependencies:** `data/DWM-original.gbc`, `extracted/text_id_map.json`

---

## decompile_script.py

**Purpose:** Convert raw script data into human-readable pseudo-code for
analysis. This is the "read" side of the script system — use it to
understand what any NPC or cutscene script does.

**How it works:**
1. Reads the ROM directly at `data/DWM-original.gbc`
2. Follows pointer tables to find script data
3. Parses `dw` words: `$FFxx` = opcode, `$FFFF` = end, other = text/param
4. Looks up opcode names and parameter counts from built-in tables
5. Looks up text IDs from `extracted/text_id_map.json`
6. Identifies branch targets and emits labels

**All 100 opcodes are decoded.** Key verified ones:
- `$1A` = npc_walk_x (horizontal animated walk)
- `$1B` = npc_walk_y (vertical animated walk)
- `$49` = npc_show, `$48` = npc_hide
- `$1C` = trigger_anim ($01XX = jump for NPC XX)
- `$12` = write_ram (write value to RAM address, 335 uses)
- `$19` = wait_movement (pause until NPC movement completes)
- `$22` = begin_walk (required before walk commands)
See PARAM_COUNTS dict in the source for all parameter counts.

**Usage:**
```bash
# Decompile all scripts for a map type
python3 tools/decompile_script.py --map 0x0E 0x2F
# Output: Bedroom_Script00 through Bedroom_Script14 in pseudo-code

# Decompile from a specific ROM address
python3 tools/decompile_script.py 0x0E 0x48E4
# Output: script starting at bank $0E address $48E4

# With a label
python3 tools/decompile_script.py 0x0E 0x48E4 WarubouCutscene
```

**Bank → map type routing:**
- Bank $0C: map types $00-$05 (Castle, GreatTree, Bazaar, GateHub, Farm, Stable)
- Bank $0D: map types $06-$1F (Arena, GateTileset, CopycatRoom, MedalMan, Well)
- Bank $0E: map types $20-$3F (Gate rooms, boss rooms, Bedroom=$2F)
- Bank $0F: map types $40-$5F (Late-game bosses, post-game)

**Output format example:**
```
Castle_Script10:
    if_flag_set $00F1, goto .addr_52CD
    if_flag_set $0037, goto .addr_52AF
    say $0023  ; "Terry looked at the bookshelf..."
    end
.addr_52AF:
    say $01E4  ; "We're the hosts..."
    end
```

**Dependencies:** `data/DWM-original.gbc`, `extracted/text_id_map.json`

---

## Workflow: Modifying a Script

### Method 1: Direct ROM Patch (what we tested)
1. Use `decompile_script.py` to understand the current script
2. Find the ROM offset: `bank * 0x4000 + (addr - 0x4000)`
3. Change parameter bytes directly in the ROM file
4. Test in SameBoy

Example (the Watabou modification):
```python
with open('game.gbc', 'r+b') as f:
    rom = bytearray(f.read())
    rom[0x38B0E] = 0x01  # trigger_anim: Watabou jumps first
    rom[0x38B24] = 0x90  # move_x delta: sprint 7 tiles left
    f.seek(0); f.write(rom)
```

### Method 2: Edit Assembly Source
1. Use `decompile_script.py` to find the script
2. Edit the `dw` values in `disassembly/bank_00X.asm`
3. Rebuild: `cd disassembly && make`
4. Test in SameBoy

**Constraint:** Cannot add or remove `dw` words — this shifts all
subsequent addresses and breaks branch targets. Only change VALUES.
To add new content, use an empty bank (Method 3 in CUSTOM_CUTSCENES.md).

### Method 3: Script Compiler ✅
`tools/compile_script.py` — takes decompiler pseudo-code, produces `dw` assembly with RGBDS labels.
All 100 opcodes supported. Run `--test` for built-in tests. See `compile_script.py --help`.

---

## Key Map Types (verified via SameBoy trace)

| Type | Name | Bank | Verified? |
|------|------|------|-----------|
| $00 | Castle | $0C | Trace data, not visually verified |
| $01 | GreatTree | $0C | Script00 fires on every screen transition |
| $08 | TransitionScreen | $0D | Fires during screen wave effect |
| $09 | MonsterShrine | $0D | Starry Night intro shrine |
| $2F | Bedroom | $0E | **Fully verified** — Warubou cutscene decoded |

---

## Extracted Data Files (in `extracted/`)

The tools depend on these JSON files:

| File | Used By | Contents |
|------|---------|----------|
| `text_id_map.json` | Both tools | 2,067 text IDs → English text |
| `all_scripts.json` | Reference | 209 scripts with command sequences |
| `npc_catalog.json` | Reference | NPC locations, sprites, script IDs |
| `event_flags.json` | Reference | Story flag analysis |
