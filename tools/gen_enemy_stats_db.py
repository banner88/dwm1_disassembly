#!/usr/bin/env python3
"""Generate db statements for bank $14 data tables.

Covers:
  - Boss redirect table at $4893 (35 entries × 4 bytes, terminated by $FFFF)
  - Unknown data at $491F-$4C1C (766 bytes)
  - Enemy stats table at $4C1D (487 entries × 25 bytes)
"""
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(SCRIPT_DIR, '..', 'data', 'DWM-original.gbc')
ENEMIES_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'enemy_stats.json')
BOSSES_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'boss_table.json')
MONSTERS_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'monsters_full.json')
SKILL_RECORDS_PATH = os.path.join(SCRIPT_DIR, '..', 'extracted', 'skill_records.json')

BANK = 0x14
BOSS_TABLE_ADDR = 0x4893
UNKNOWN_DATA_ADDR = 0x491F
ENEMY_TABLE_ADDR = 0x4C1D
ENEMY_ENTRY_SIZE = 25
NUM_ENEMIES = 487

JOIN_NAMES = {0: "always", 1: "1", 2: "2", 3: "3", 4: "4", 5: "standard", 6: "6", 7: "never"}


def main():
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    with open(ENEMIES_PATH) as f:
        enemies = json.load(f)
    with open(BOSSES_PATH) as f:
        bosses = json.load(f)
    with open(MONSTERS_PATH) as f:
        mon_names = {m['id']: m['name'] for m in json.load(f)}
    with open(SKILL_RECORDS_PATH) as f:
        skill_names = {s['id']: s['name'] for s in json.load(f)['records']}

    base = BANK * 0x4000
    lines = []

    # ===== BOSS REDIRECT TABLE =====
    lines.append("; ---------------------------------------------------------------")
    lines.append("; Boss Redirect Table ($4893)")
    lines.append("; Scanned by label14_4869 (entry 6) to redirect fight EIDs to join EIDs")
    lines.append("; Format: dw fight_eid, join_eid  (16-bit LE pairs)")
    lines.append("; Terminated by $FFFF")
    lines.append("; ---------------------------------------------------------------")
    lines.append("")
    lines.append("BossRedirectTable:")

    offset = base + (BOSS_TABLE_ADDR - 0x4000)
    entry_idx = 0
    while True:
        fight = rom[offset] | (rom[offset + 1] << 8)
        join = rom[offset + 2] | (rom[offset + 3] << 8)

        if fight == 0xFFFF:
            lines.append(f"    dw $FFFF, ${join:04X}  ; Terminator")
            offset += 4
            break

        # Find boss info from JSON
        boss_info = None
        for b in bosses:
            if b['fight_eid'] == fight:
                boss_info = b
                break

        if entry_idx == 0:
            comment = f"Non-boss redirect (EID {fight} -> {join})"
        elif boss_info:
            gate_name = boss_info.get('gate_name', f'Gate {boss_info["gate"]}')
            species = boss_info.get('fight_species', '?')
            comment = f"{gate_name}: {species} (fight={fight}, join={join})"
        else:
            comment = f"fight={fight}, join={join}"

        lines.append(f"    dw {fight}, {join}  ; [{entry_idx}] {comment}")
        offset += 4
        entry_idx += 1

    lines.append("")

    # ===== UNKNOWN GAP DATA =====
    gap_start = base + (UNKNOWN_DATA_ADDR - 0x4000)
    gap_end = base + (ENEMY_TABLE_ADDR - 0x4000)
    gap_size = gap_end - gap_start
    gap_data = rom[gap_start:gap_end]

    lines.append("; ---------------------------------------------------------------")
    lines.append(f"; Unknown data block ($491F-$4C1C, {gap_size} bytes)")
    lines.append("; Purpose not yet identified — possibly EID lookup table or")
    lines.append("; encounter-related mapping. Sequential single-byte values.")
    lines.append("; ---------------------------------------------------------------")
    lines.append("")
    lines.append("UnknownData_491F:")

    for i in range(0, gap_size, 16):
        chunk = gap_data[i:min(i + 16, gap_size)]
        vals = ", ".join(f"${b:02X}" for b in chunk)
        addr = UNKNOWN_DATA_ADDR + i
        lines.append(f"    db {vals}  ; ${addr:04X}")

    lines.append("")

    # ===== ENEMY STATS TABLE =====
    lines.append("; ---------------------------------------------------------------")
    lines.append("; Enemy Stats Table ($4C1D)")
    lines.append("; 487 entries x 25 bytes = 12175 bytes")
    lines.append(";")
    lines.append("; Format (25 bytes per entry):")
    lines.append(";   +$00    Species ID")
    lines.append(";   +$01-02 EXP reward (16-bit LE)")
    lines.append(";   +$03    Joinability (0=always..5=standard..7=never)")
    lines.append(";   +$04    Level")
    lines.append(";   +$05-06 HP (16-bit LE)")
    lines.append(";   +$07-08 MP (16-bit LE)")
    lines.append(";   +$09-0A ATK (16-bit LE)")
    lines.append(";   +$0B-0C DEF (16-bit LE)")
    lines.append(";   +$0D-0E AGL (16-bit LE)")
    lines.append(";   +$0F-10 INT (16-bit LE)")
    lines.append(";   +$11-14 AI weights (4 bytes)")
    lines.append(";   +$15-18 Skills (4 bytes, $FF = none)")
    lines.append("; ---------------------------------------------------------------")
    lines.append("")
    lines.append("EnemyStatsTable:")

    es_base = base + (ENEMY_TABLE_ADDR - 0x4000)

    for i in range(NUM_ENEMIES):
        offset = es_base + i * ENEMY_ENTRY_SIZE
        raw = rom[offset:offset + ENEMY_ENTRY_SIZE]

        species = raw[0]
        exp = raw[1] | (raw[2] << 8)
        join = raw[3]
        level = raw[4]
        hp = raw[5] | (raw[6] << 8)
        mp = raw[7] | (raw[8] << 8)
        atk = raw[9] | (raw[10] << 8)
        defn = raw[11] | (raw[12] << 8)
        agl = raw[13] | (raw[14] << 8)
        intn = raw[15] | (raw[16] << 8)
        ai = list(raw[17:21])
        skills = list(raw[21:25])

        species_name = mon_names.get(species, f"?{species}")
        join_str = JOIN_NAMES.get(join, str(join))

        # Skill names
        sk_strs = []
        for s in skills:
            if s == 0xFF:
                sk_strs.append("none")
            else:
                sk_strs.append(skill_names.get(s, f"?{s}"))

        lines.append(f"; --- EID {i} ({i:#x}): {species_name} Lv{level} ---")
        lines.append(f"EnemyStats_{i:03d}:")
        lines.append(f"    db {species}  ; Species: {species_name}")
        lines.append(f"    dw {exp}  ; EXP reward")
        lines.append(f"    db {join}  ; Joinability ({join_str})")
        lines.append(f"    db {level}  ; Level")
        lines.append(f"    dw {hp}, {mp}, {atk}, {defn}, {agl}, {intn}  ; HP, MP, ATK, DEF, AGL, INT")
        ai_str = ", ".join(str(v) for v in ai)
        lines.append(f"    db {ai_str}  ; AI weights")
        sk_vals = ", ".join(f"${s:02X}" for s in skills)
        sk_names = ", ".join(sk_strs)
        lines.append(f"    db {sk_vals}  ; Skills: {sk_names}")
        lines.append("")

    output = "\n".join(lines) + "\n"
    sys.stdout.write(output)


if __name__ == '__main__':
    main()
