#!/usr/bin/env python3
"""Dump the two bank $53 tables behind the enemy DUPLICATE-GROUP-CAST
conversion rule (LoadBtlC_4e63, decoded + measured S85):

  $53:$41DF  per-EID flag byte (487 rows, 0/1; row 486 = $FE is the
             table's end marker / next data) — an enemy with flag 0 never
             converts;
  $53:$4EE4  $FF-terminated list of the 77 skill ids the rule applies to.

Output: extracted/enemy_dupconv_flags.json
  { "flag_table_rom": "0x14D1DF", "flags": [487 ints],
    "flagged_eids": [...], "dup_skill_list_rom": "0x14EEE4",
    "dup_skills": [77 ints] }
Self-test (--check): re-reads the ROM and compares to the JSON.
"""
import json, os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, 'data', 'DWM-original.gbc')
OUT = os.path.join(ROOT, 'extracted', 'enemy_dupconv_flags.json')
BANK = 0x53
FLAG_ADDR, FLAG_ROWS = 0x41DF, 487
LIST_ADDR = 0x4EE4


def rom_off(addr):
    return BANK * 0x4000 + addr - 0x4000


def build():
    rom = open(ROM, 'rb').read()
    flags = list(rom[rom_off(FLAG_ADDR):rom_off(FLAG_ADDR) + FLAG_ROWS])
    lst = []
    for x in rom[rom_off(LIST_ADDR):rom_off(LIST_ADDR) + 256]:
        if x == 0xFF:
            break
        lst.append(x)
    return {
        'flag_table_rom': hex(rom_off(FLAG_ADDR)), 'flag_table_addr': '$53:$41DF',
        'flags': flags,
        'flagged_eids': [i for i, v in enumerate(flags) if v == 1],
        'dup_skill_list_rom': hex(rom_off(LIST_ADDR)), 'dup_skill_list_addr': '$53:$4EE4',
        'dup_skills': lst,
    }


if __name__ == '__main__':
    d = build()
    if '--check' in sys.argv:
        old = json.load(open(OUT))
        assert old == d, 'enemy_dupconv_flags.json is stale'
        print('OK: enemy_dupconv_flags.json matches ROM')
    else:
        json.dump(d, open(OUT, 'w'), indent=1)
        print(f"wrote {OUT}: {len(d['flagged_eids'])} flagged EIDs, {len(d['dup_skills'])} skills")
