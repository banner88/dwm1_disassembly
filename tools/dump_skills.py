"""Dump the skill table: 256 skill names + battle function addresses.

Regenerates extracted/skills.json (previously frozen-source — produced by
in-session code that was never committed; this tool replaces it).

Sources:
  Bank $41 SkillNamePtrTable at $4539 — 256 × dw → name strings ($F0-terminated)
  Bank $52 SkillFunctionTable at $4011 — 256 × dw → handler addresses

Usage:
  python3 -m tools.dump_skills
"""
import json
from pathlib import Path
from dwm.rom import ROM
from dwm.text import decode

NAME_BANK, NAME_TABLE = 0x41, 0x4539
FUNC_BANK, FUNC_TABLE = 0x52, 0x4011

rom = ROM(Path("data/DWM-original.gbc"))

skills = []
for i in range(256):
    np = rom.read(NAME_BANK, NAME_TABLE + i * 2, 2)
    name_ptr = np[0] | (np[1] << 8)
    raw = rom.read_until(NAME_BANK, name_ptr, 0xF0)
    name, _ = decode(raw)

    fp = rom.read(FUNC_BANK, FUNC_TABLE + i * 2, 2)
    func = fp[0] | (fp[1] << 8)

    skills.append({"id": i, "name": name, "function_addr": f"${func:04X}"})

out = Path("extracted/skills.json")
out.write_text(json.dumps(skills, indent=2))
print(f"Saved {out} ({len(skills)} skills)")
