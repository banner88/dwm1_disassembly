#!/usr/bin/env python3
"""Generate db/dw statements for bank $52 header data.

Covers:
  - Bank byte at $4000
  - Jump table at $4001 (8 entries × 2 bytes)
  - Skill function table at $4011 (256 entries × 2 bytes)
"""
import json, os, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(SCRIPT_DIR, '..', 'data', 'DWM-original.gbc')
SKILLS_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'skills.json')

BANK = 0x52


def main():
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    with open(SKILLS_PATH) as f:
        skill_names = {s['id']: s['name'] for s in json.load(f)}

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
    lines.append("; Skill Function Table ($4011)")
    lines.append("; 256 entries x 2 bytes = 512 bytes")
    lines.append("; Maps skill ID -> handler function address within bank $52")
    lines.append("; Referenced by code at $4211 via: ld hl, $4011")
    lines.append("; ---------------------------------------------------------------")
    lines.append("")
    lines.append("SkillFunctionTable:")

    offset = base + (0x4011 - 0x4000)
    for i in range(256):
        ptr = rom[offset + i * 2] | (rom[offset + i * 2 + 1] << 8)
        name = skill_names.get(i, f"?{i}")
        lines.append(f"    dw ${ptr:04X}  ; [{i:3d}] {name}")

    sys.stdout.write("\n".join(lines) + "\n")


if __name__ == '__main__':
    main()
