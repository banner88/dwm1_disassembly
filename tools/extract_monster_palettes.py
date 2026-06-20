#!/usr/bin/env python3
"""
extract_monster_palettes.py — dump the per-species monster BATTLE palette table.

Table = MonsterBattlePalettes @ $17:$62FD (mgbdis-misnamed "RoomAttrDataBlocks"),
8 bytes/species = 4 RGB555 LE colours [c0, c1=$6bff backdrop, c2, c3=$0000 black].
Loaded by bank $17 entry 6 ($1706): $c81e=index(species)*8 + base, $c81f=dest CGB
slot; the enemy monster renders as BG tiles on BG palette slot 4. A recolour is a
same-size 8-byte edit of one species' entry (tools/build_sprite_swap.py --palette).

Located S23 from a SameBoy palette dump (Dracky BG4 = 007b 6bff 2a97 0000) + ROM
grep. Count is a parameter (no hardcoded 221).

Usage:
  python3 tools/extract_monster_palettes.py            # -> extracted/monster_palettes.json
"""
import os, sys, json, argparse

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
TABLE = 0x17 * 0x4000 + (0x62FD - 0x4000)   # ROM offset 0x5e2fd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--count', type=int, default=221)
    ap.add_argument('--out', default=os.path.join(REPO, 'extracted', 'monster_palettes.json'))
    args = ap.parse_args()
    rom = open(ROM, 'rb').read()
    names = {}
    try:
        mf = json.load(open(os.path.join(REPO, 'extracted', 'monsters_full.json')))
        for m in (mf if isinstance(mf, list) else mf.values()):
            if isinstance(m, dict):
                names[m['id']] = m.get('name', '')
    except Exception:
        pass
    out = {
        '_generator': 'tools/extract_monster_palettes.py (ROM data/DWM-original.gbc)',
        '_format': 'species -> {addr, colors:[4 RGB555 ints], bytes_hex}. '
                   'MonsterBattlePalettes @ $17:$62FD, 8B/species, '
                   '[c0, c1=$6bff backdrop, c2, c3=$0000 black]. BG palette slot 4.',
        '_count': args.count,
        'table_addr': '$17:$62FD',
        'monsters': {},
    }
    for sp in range(args.count):
        o = TABLE + sp * 8
        b = rom[o:o + 8]
        cols = [b[2 * i] | (b[2 * i + 1] << 8) for i in range(4)]
        out['monsters'][str(sp)] = {
            'name': names.get(sp, ''),
            'addr': '$17:$%04x' % (0x62FD + sp * 8),
            'colors': cols,
            'bytes_hex': b.hex(),
        }
    json.dump(out, open(args.out, 'w'), indent=1)
    print(f'Wrote {args.out} ({args.count} monster palettes).')


if __name__ == '__main__':
    main()
