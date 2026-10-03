#!/usr/bin/env python3
"""dump_encounters.py — every gate floor's wild-monster list, from the ROM
(REWRITTEN S114, ROADMAP P3.13a; DATA_STRUCTURES "Encounter pool entry" +
"Encounter list choice (S114)").

    python3 tools/dump_encounters.py              # writes extracted/encounters.json
    python3 tools/dump_encounters.py --selftest   # the file == the ROM (verify check 5)

Shape (unchanged keys kept for its readers — editor2/core/monsters.py,
simulator/sweep_ttk.py, tools/gen_encounter_db.py):
  {"_generator": ..., "<gate id>": {"name", "floors", "floor_groups": [
      {"floor_range": "Floors 3-5", "floors": [3, 5], "pool_index": n,
       "rate_code", "size_chance": [% of 1, 2, 3 monsters],
       "monsters": [{"slot", "enemy_stats_id", "species_id", "monster_name",
                     "level", "chance", "real_chance", "max_count"}]}]}}

What the pre-S114 dumper had wrong (DOC_AUDIT S114): floor ranges were one
floor late ("Floors 1-3" for the list that serves floors 1-2 — the walk counts
breakpoints <= the floor, the game's numbering, measured by
tools/census_encounters.py on the ORIGINAL ROM: 633 / 633), ranges ignored the
gate's floor count (lists no floor reaches were listed), only 4 of the 5 slots
were read, the "weight" it printed is the slot's MAX COUNT (+20, S103) — the
chance is the code at +5..+9 — and its own gate-name list was out of order
(names now come from extracted/gate_names.json, S100). Boss floors (the last
floor) have no maze and no list.
"""
import hashlib
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
ROM_PATH = os.path.join(REPO, 'data', 'DWM-original.gbc')
OUT = os.path.join(REPO, 'extracted', 'encounters.json')
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'


def flat(bank, addr):
    return bank * 0x4000 + (addr - 0x4000 if bank else addr)


def build(rom):
    from editor2.core import encounters as EN
    from editor2.core import gamedata as G
    v = G.vanilla(REPO)
    pct = v['chance_percent']
    gates = json.load(open(os.path.join(REPO, 'extracted', 'gate_names.json')))['gates']
    names = G.monster_names(REPO)
    pools = [rom[flat(1, 0x6AAE) + 26 * i: flat(1, 0x6AAE) + 26 * (i + 1)] for i in range(128)]
    enemy = lambda e: rom[flat(0x14, 0x4C1D) + 25 * e: flat(0x14, 0x4C1D) + 25 * (e + 1)]
    out = {'_generator': (
        'tools/dump_encounters.py (REWRITTEN S114) from data/DWM-original.gbc '
        f'{ORIGINAL_MD5}: gate floor -> list by the bank $01 LoadNextDungeonFloor rule '
        '(the game\'s floor numbering; floors 1 .. floor count - 1, the last floor is the '
        'boss), lists decoded per DATA_STRUCTURES "Encounter pool entry"; chance = the slot '
        'code\'s %, real_chance = the draw rule (first running sum >= RNG mod 100), '
        'max_count = +20. --selftest re-derives it.')}
    for g in gates:
        gid, n = g['id'], g['floors']
        groups = []
        for f in range(1, n):
            num = EN.vanilla_number(REPO, gid, f)
            if groups and groups[-1]['pool_index'] == num:
                groups[-1]['floors'][1] = f
                continue
            groups.append({'pool_index': num, 'floors': [f, f]})
        for grp in groups:
            a, b = grp['floors']
            grp['floor_range'] = f'Floor {a}' if a == b else f'Floors {a}-{b}'
            r = pools[grp['pool_index']]
            real = EN.real_chances(r[5:10], pct)
            grp['rate_code'] = r[0]
            grp['size_chance'] = [pct[c] for c in r[2:5]]
            mons = []
            for k in range(5):
                eid = r[10 + 2 * k] | r[11 + 2 * k] << 8
                if not r[5 + k] and not eid:
                    continue
                row = enemy(eid)
                mons.append({'slot': k, 'enemy_stats_id': eid, 'species_id': row[0],
                             'monster_name': names.get(row[0], f'#{row[0]}'),
                             'level': row[4], 'chance': pct[r[5 + k]],
                             'real_chance': real[k], 'max_count': r[20 + k]})
            grp['monsters'] = mons
        out[str(gid)] = {'name': g['name'], 'floors': n,
                         'floor_groups': [{k: grp[k] for k in (
                             'floor_range', 'floors', 'pool_index', 'rate_code',
                             'size_chance', 'monsters')} for grp in groups]}
    return out


def load_rom():
    rom = open(ROM_PATH, 'rb').read()
    if hashlib.md5(rom).hexdigest() != ORIGINAL_MD5:
        sys.exit('ERROR: data/DWM-original.gbc is not the original ROM')
    return rom


def main():
    if '--selftest' in sys.argv:
        if not os.path.exists(ROM_PATH):
            print('SKIP: no ROM')
            return 0
        want = build(load_rom())
        have = json.load(open(OUT))
        if want != have:
            print(f'FAIL: {OUT} differs from the ROM — regenerate')
            return 1
        lists = {fg['pool_index'] for k, g in want.items() if not k.startswith('_')
                 for fg in g['floor_groups']}
        print(f'OK: encounters.json == ROM (32 gates, {len(lists)} lists reached by a '
              'floor; floors in the game\'s numbering)')
        return 0
    data = build(load_rom())
    with open(OUT, 'w') as f:
        json.dump(data, f, indent=1)
        f.write('\n')
    print(f'wrote {OUT}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
