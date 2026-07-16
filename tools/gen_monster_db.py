#!/usr/bin/env python3
"""Generate db statements for the monster info table (bank $03:$4461).

Reads raw bytes from the original ROM and names from extracted JSON.
Outputs asm-ready db blocks that assemble byte-identically.
Preserves labels within the data region that are referenced by code.
"""
import json
import sys
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(SCRIPT_DIR, '..', 'data', 'DWM-original.gbc')
MONSTERS_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'monsters_full.json')
SKILL_RECORDS_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'skill_records.json')

TABLE_ADDR = 0x4461
ENTRY_SIZE = 43
NUM_ENTRIES = 221

FAMILY_NAMES = {
    0: "Slime", 1: "Dragon", 2: "Beast", 3: "Flying", 4: "Plant",
    5: "Bug", 6: "Devil", 7: "Zombie", 8: "Material", 9: "Boss"
}
FEMALE_RATIO_NAMES = {0: "0%", 1: "~10%", 2: "50/50", 3: "~84%"}

# Labels within the data region that are referenced by code.
# Format: (ROM address, label_name)
# These are addresses where code does call/jp into the table.
# The labels must be preserved to keep references valid.
EMBEDDED_LABELS = {
    0x59D0: "Call_003_59d0",
    0x624E: "Call_003_624e",
    0x6473: "Jump_003_6473",
    0x648E: "Jump_003_648e",
    0x6719: "Jump_003_6719",
    0x68AB: "Jump_003_68ab",
}

# Field layout: (start_byte, end_byte_exclusive, comment_template)
# Used to group bytes into db lines
FIELDS = [
    (0, 1, "Family: {family}"),
    (1, 2, "Level cap"),
    (2, 3, "Exp table"),
    (3, 4, "Female ratio ({female_str})"),
    (4, 6, "Can fly: {fly}, Metal: {metal}"),
    (6, 9, "Skills: {sk1}, {sk2}, {sk3}"),
    (9, 15, "Growth: HP, MP, ATK, DEF, AGL, INT"),
    (15, 29, "Resist A-N: Fire..AglDown"),
    (29, 42, "Resist O-Z+unused: Sacrifice..GigaSlash+unused"),
    (42, 43, "Tier/rank"),
]


def main():
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    with open(MONSTERS_PATH) as f:
        monsters = json.load(f)
    with open(SKILL_RECORDS_PATH) as f:
        skill_names = {s['id']: s['name'] for s in json.load(f)['records']}

    base = 0x03 * 0x4000 + (TABLE_ADDR - 0x4000)

    # Build label lookup: (monster_index, byte_within_entry) -> label_name
    labels_by_pos = {}
    for addr, name in EMBEDDED_LABELS.items():
        table_offset = addr - TABLE_ADDR
        mon_idx = table_offset // ENTRY_SIZE
        byte_idx = table_offset % ENTRY_SIZE
        labels_by_pos[(mon_idx, byte_idx)] = name

    lines = []
    lines.append("; ---------------------------------------------------------------")
    lines.append("; Monster Info Table ($4461)")
    lines.append("; 221 entries x 43 bytes = 9503 bytes")
    lines.append(";")
    lines.append("; Format (43 bytes per entry):")
    lines.append(";   +$00  Family (0=Slime..9=Boss)")
    lines.append(";   +$01  Level cap")
    lines.append(";   +$02  Exp table index")
    lines.append(";   +$03  Female ratio (0=0%, 1=~10%, 2=50/50, 3=~84%)")
    lines.append(";   +$04  Can fly       +$05  Metal body")
    lines.append(";   +$06  Skill 1 ID    +$07  Skill 2 ID    +$08  Skill 3 ID")
    lines.append(";   +$09  HP growth     +$0A  MP growth")
    lines.append(";   +$0B  ATK growth    +$0C  DEF growth")
    lines.append(";   +$0D  AGL growth    +$0E  INT growth")
    lines.append(";   +$0F-$29  Resistances (27 bytes: A-Z + unused)")
    lines.append(";             0=weak, 1=some resist, 2=normal, 3=immune")
    lines.append(";   +$2A  Tier/rank")
    lines.append("; ---------------------------------------------------------------")
    lines.append("")
    lines.append("MonsterInfoTable:")

    for i in range(NUM_ENTRIES):
        offset = base + i * ENTRY_SIZE
        raw = rom[offset:offset + ENTRY_SIZE]

        if i < len(monsters):
            m = monsters[i]
            name = m['name'] if m['name'] else f"Unused_{i}"
        else:
            name = f"Unknown_{i}"

        family_id = raw[0]
        family = FAMILY_NAMES.get(family_id, f"?{family_id}")
        female_str = FEMALE_RATIO_NAMES.get(raw[3], f"?{raw[3]}")
        fly = "yes" if raw[4] else "no"
        metal = "yes" if raw[5] else "no"
        sk1_name = skill_names.get(raw[6], f"?{raw[6]}")
        sk2_name = skill_names.get(raw[7], f"?{raw[7]}")
        sk3_name = skill_names.get(raw[8], f"?{raw[8]}")

        safe_name = name.replace("'", "").replace("-", "_").replace(" ", "_").replace(".", "").replace("?", "")
        label = f"MonsterInfo_{i:03d}_{safe_name}"

        fmt_vars = dict(family=family, female_str=female_str, fly=fly, metal=metal,
                        sk1=sk1_name, sk2=sk2_name, sk3=sk3_name)

        lines.append(f"; --- Monster ${i:02X} ({i}): {name} ---")
        lines.append(f"{label}:")

        # Check if this entry has any embedded labels
        entry_labels = {b: labels_by_pos[(i, b)] for b in range(ENTRY_SIZE)
                        if (i, b) in labels_by_pos}

        for field_start, field_end, comment_tmpl in FIELDS:
            comment = comment_tmpl.format(**fmt_vars)
            field_bytes = list(raw[field_start:field_end])

            if not entry_labels or not any(field_start <= b < field_end for b in entry_labels):
                # No labels in this field — emit as single db line
                vals = ", ".join(str(v) for v in field_bytes)
                lines.append(f"    db {vals}  ; {comment}")
            else:
                # Split at label positions
                lines.append(f"    ; {comment}")
                pos = field_start
                while pos < field_end:
                    if pos in entry_labels:
                        lines.append(f"{entry_labels[pos]}:")
                    # Find next label or field end
                    next_break = field_end
                    for lb in entry_labels:
                        if lb > pos and lb < next_break:
                            next_break = lb
                    chunk = list(raw[pos:next_break])
                    vals = ", ".join(str(v) for v in chunk)
                    lines.append(f"    db {vals}")
                    pos = next_break

        lines.append("")

    output = "\n".join(lines) + "\n"
    sys.stdout.write(output)


if __name__ == '__main__':
    main()
