#!/usr/bin/env python3
"""Generate db/dw statements for bank $52 header data.

Covers:
  - Bank byte at $4000
  - Jump table at $4001 (8 entries × 2 bytes)
  - Skill function table at $4011 (222 entries × 2 bytes = 444 B, $4011..$41CC)

Skill names come from extracted/skill_records.json (S44 schema; the legacy
extracted/skills.json was retired S59).

S59 — the 256-entry overrun: this tool used to emit 256 entries and read the
legacy skills.json, which dumped 256 names from the same table. The table is
only 222 entries (ids $00..$DD); it ends where the first handler begins,
SkillBlaze @ $52:$41CD (bytes CD FF 5B = `call $5BFF`). The 34 extra "entries"
were the Blaze handler's code misread as little-endian pointers (hence the
bogus $FFCD / $CD5B / $E7CD values). disassembly/bank_052.asm has been correct
at 222 all along; this tool was the stale copy.
"""
import json, os, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(SCRIPT_DIR, '..', 'data', 'DWM-original.gbc')
SKILL_RECORDS_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'skill_records.json')

BANK = 0x52

# Skill function table geometry (verified S59 against ROM + disassembly):
#   $4011 .. $41CC inclusive = 222 entries x 2 B = 444 B (ids $00..$DD)
#   $41CD = SkillBlaze, the first handler — the table's hard upper bound.
TABLE_ADDR = 0x4011
N_SKILLS = 222
TABLE_END = TABLE_ADDR + N_SKILLS * 2  # $41CD, exclusive


def main():
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    with open(SKILL_RECORDS_PATH) as f:
        skill_names = {s['id']: s['name'] for s in json.load(f)['records']}

    base = BANK * 0x4000
    lines = []

    # Bank byte
    lines.append(f"    db ${BANK:02X}")
    lines.append("")

    # Jump table
    lines.append(f"    ; Bank ${BANK:02X} jump table (8 entries)")
    offset = base + 1
    for i in range(8):
        ptr = rom[offset + i * 2] | (rom[offset + i * 2 + 1] << 8)
        lines.append(f"    dw ${ptr:04X}  ; Entry {i}")
    lines.append("")

    # Skill function table
    lines.append("; ---------------------------------------------------------------")
    lines.append(f"; Skill Function Table (${TABLE_ADDR:04X})")
    lines.append(f"; {N_SKILLS} entries x 2 bytes = {N_SKILLS * 2} bytes "
                 f"(${TABLE_ADDR:04X}..${TABLE_END - 1:04X}), then handler code begins.")
    lines.append(f"; (Table entries for ids {N_SKILLS}-255 do not exist; skills only "
                 f"run 0-{N_SKILLS - 1} = $00-${N_SKILLS - 1:02X}.)")
    lines.append("; Maps skill ID -> handler function address within bank $52")
    lines.append("; Referenced by code at $6CC7 via: ld hl, SkillFunctionTable")
    lines.append("; ---------------------------------------------------------------")
    lines.append("")
    lines.append("SkillFunctionTable:")

    offset = base + (TABLE_ADDR - 0x4000)
    for i in range(N_SKILLS):
        ptr = rom[offset + i * 2] | (rom[offset + i * 2 + 1] << 8)
        name = skill_names.get(i, f"?{i}")
        lines.append(f"    dw ${ptr:04X}  ; [{i:3d}] {name}")

    sys.stdout.write("\n".join(lines) + "\n")


if __name__ == '__main__':
    main()
