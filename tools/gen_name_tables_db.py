#!/usr/bin/env python3
"""Generate db statements for monster and skill name tables in bank $41.

Converts:
  - Monster name pointer table at $4339 (256 × 2 bytes)
  - Monster name strings at $5B1F ($F0 terminated)
  - Skill name strings at $628E ($F0 terminated)
  
Uses charmap-encoded strings so names are directly editable.
Pointer table uses labels so assembler recalculates on name length changes.
"""
import json, os, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(SCRIPT_DIR, '..', 'data', 'DWM-original.gbc')
MONSTERS_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'monsters_full.json')
SKILLS_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'skills.json')

BANK = 0x41
NAME_PTR_TABLE = 0x4339
NAME_DATA_START = 0x5B1F
SKILL_DATA_START = 0x628E

# Build decode map from charmap.asm
CHARMAP = {}
for i, c in enumerate('0123456789'): CHARMAP[i] = c
for i, c in enumerate('ABCDEFGHIJKLMNOPQRSTUVWXYZ'): CHARMAP[0x24 + i] = c
for i, c in enumerate('abcdefghijklmnopqrstuvwxyz'): CHARMAP[0x3e + i] = c
CHARMAP[0x5c] = "'"
CHARMAP[0x5e] = ","
CHARMAP[0x5f] = "."
CHARMAP[0x61] = ".."  # DTE pair
CHARMAP[0x62] = " "
CHARMAP[0x63] = "!"
CHARMAP[0x64] = "?"

# Characters that need escaping in db strings
NEEDS_HEX = set()  # bytes not in charmap must be output as hex


def decode_name(rom, offset):
    """Read a $F0-terminated name string, return (decoded_str, raw_bytes)."""
    raw = []
    while rom[offset] != 0xF0:
        raw.append(rom[offset])
        offset += 1
    raw.append(0xF0)
    decoded = ''.join(CHARMAP.get(b, f'\\x{b:02X}') for b in raw[:-1])
    return decoded, raw


def name_to_db(decoded, raw):
    """Convert a name to a db string expression.
    
    If all bytes are charmap-representable, output as db "String", $F0
    Otherwise output as raw hex bytes.
    """
    # Check if all bytes (except terminator) are in charmap
    all_charmap = all(b in CHARMAP for b in raw[:-1])
    
    if all_charmap and decoded:
        # Escape quotes in the string
        escaped = decoded.replace('"', '\\"')
        return f'db "{escaped}", $F0'
    elif not decoded:
        # Empty string
        return 'db $F0'
    else:
        # Has non-charmap bytes, output as hex
        hex_vals = ', '.join(f'${b:02X}' for b in raw)
        return f'db {hex_vals}  ; {decoded}'


def main():
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()

    base = BANK * 0x4000

    # ===== Read all monster names =====
    mon_names = []
    offset = base + (NAME_DATA_START - 0x4000)
    seen_offsets = {}  # ROM offset -> name index (for dedup)
    
    # Read pointer table to get all name addresses
    ptr_offset = base + (NAME_PTR_TABLE - 0x4000)
    name_ptrs = []
    for i in range(256):
        ptr = rom[ptr_offset + i * 2] | (rom[ptr_offset + i * 2 + 1] << 8)
        name_ptrs.append(ptr)
    
    # Read unique names in order of appearance
    unique_names = {}  # address -> (index, decoded, raw)
    for i in range(256):
        addr = name_ptrs[i]
        if addr not in unique_names:
            rom_offset = base + (addr - 0x4000)
            decoded, raw = decode_name(rom, rom_offset)
            unique_names[addr] = (i, decoded, raw)
    
    # ===== Read all skill names =====
    skill_names = []
    offset = base + (SKILL_DATA_START - 0x4000)
    for i in range(256):
        decoded, raw = decode_name(rom, offset)
        skill_names.append((decoded, raw))
        offset += len(raw)
    skill_data_end = offset - base + 0x4000

    # ===== Output monster name pointer table =====
    lines = []
    lines.append("; ---------------------------------------------------------------")
    lines.append("; Monster Name Pointer Table ($4339)")
    lines.append("; 256 entries x 2 bytes = 512 bytes")
    lines.append("; Points to $F0-terminated charmap-encoded strings")
    lines.append("; ---------------------------------------------------------------")
    lines.append("")
    lines.append("MonsterNamePtrTable:")
    for i in range(256):
        addr = name_ptrs[i]
        first_idx, decoded, _ = unique_names[addr]
        safe = decoded.replace("'", "").replace("?", "").replace(" ", "_") or f"Unused_{i}"
        label = f"MonsterName_{first_idx:03d}_{safe}"
        lines.append(f"    dw {label}  ; [{i}] {decoded}")
    
    # Output section 1: pointer table
    ptr_output = "\n".join(lines) + "\n"
    
    # ===== Output monster name strings =====
    lines2 = []
    lines2.append("")
    lines2.append("; ---------------------------------------------------------------")
    lines2.append("; Monster Name Strings ($5B1F)")
    lines2.append(f"; {len(unique_names)} unique names, $F0 terminated, charmap encoded")
    lines2.append("; ---------------------------------------------------------------")
    lines2.append("")
    lines2.append("MonsterNameStrings:")
    
    for addr in sorted(unique_names.keys()):
        first_idx, decoded, raw = unique_names[addr]
        safe = decoded.replace("'", "").replace("?", "").replace(" ", "_") or f"Unused_{first_idx}"
        label = f"MonsterName_{first_idx:03d}_{safe}"
        db_str = name_to_db(decoded, raw)
        lines2.append(f"{label}: {db_str}")
    
    name_output = "\n".join(lines2) + "\n"
    
    # ===== Output skill name strings =====
    lines3 = []
    lines3.append("")
    lines3.append("; ---------------------------------------------------------------")
    lines3.append(f"; Skill Name Strings ($628E)")
    lines3.append(f"; 256 entries, $F0 terminated, charmap encoded")
    lines3.append(f"; Data ends at ${skill_data_end:04X}")
    lines3.append("; ---------------------------------------------------------------")
    lines3.append("")
    lines3.append("SkillNameStrings:")
    
    for i, (decoded, raw) in enumerate(skill_names):
        safe = decoded.replace("'", "").replace("?", "").replace(" ", "_").replace(".", "") or f"Unused_{i}"
        label = f"SkillName_{i:03d}_{safe}"
        db_str = name_to_db(decoded, raw)
        lines3.append(f"{label}: {db_str}")
    
    skill_output = "\n".join(lines3) + "\n"
    
    # Write all sections
    sys.stdout.write("===PTR_TABLE===\n")
    sys.stdout.write(ptr_output)
    sys.stdout.write("===NAME_STRINGS===\n")
    sys.stdout.write(name_output)
    sys.stdout.write("===SKILL_STRINGS===\n")
    sys.stdout.write(skill_output)


if __name__ == '__main__':
    main()
