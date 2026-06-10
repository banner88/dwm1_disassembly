#!/usr/bin/env python3
"""Dump complete room data from ROM.

Screen indices form a 4x2 grid: [0][1][2][3] / [4][5][6][7]
Sub-table size varies per room (determined by gap to first room_data_block).
$FFFF entries = unused grid positions.

Step entry (6 bytes):
  +0: step_id    +1: tileset_bank
  +2,+3: interact_ptr (NPC + spawn mixed block, 5-byte entries)
  +4,+5: exit_ptr (exit checker block)

Usage:
  python3 -m tools.dump_room_data          # all rooms
  python3 -m tools.dump_room_data 0        # specific room
"""
import json, os, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(SCRIPT_DIR, '..', 'data', 'DWM-original.gbc')
BANK_0B = 0x0B
TILESET_BANKS = {0x23, 0x24, 0x25, 0x26, 0x29, 0x2A, 0x2D, 0x30, 0x37}
PTR_TABLE = 0x4B43

GATE_NAMES = {}
try:
    with open(os.path.join(SCRIPT_DIR, '..', 'extracted', 'gate_names.json')) as f:
        gn = json.load(f)
        if isinstance(gn, list):
            GATE_NAMES = {i: (g.get('name', f'Map_{i}') if isinstance(g, dict) else str(g))
                          for i, g in enumerate(gn)}
        elif isinstance(gn, dict):
            GATE_NAMES = {int(k): (v if isinstance(v, str) else v.get('name', f'Map_{k}'))
                          for k, v in gn.items()}
except:
    pass


def u16(rom, off):
    return rom[off] | (rom[off + 1] << 8)


def get_subtable_size(rom, base, sub_ptr):
    """Determine sub-table size by finding the first valid room_data_ptr."""
    sub_off = base + (sub_ptr - 0x4000)
    min_data = sub_ptr + 16  # default max 8 entries
    for i in range(8):
        ptr = u16(rom, sub_off + i * 2)
        if 0x4000 <= ptr < 0x7FFF and ptr != 0xFFFF and ptr > sub_ptr:
            min_data = min(min_data, ptr)
    return (min_data - sub_ptr) // 2



def read_exit_checker_block(rom, base, ptr):
    """Read exit checker block. 7-byte entries, $FF terminated."""
    entries = []
    off = base + (ptr - 0x4000)
    safety = 0
    while rom[off] != 0xFF and safety < 50:
        raw = rom[off:off + 7]
        if raw[0] == 0x00 or raw[0] == 0x09:
            entries.append(dict(kind='arrival', x=raw[0], y=raw[1], dest=raw[2],
                                gate=raw[3], scr=raw[4], sx=raw[5], sy=raw[6]))
        else:
            entries.append(dict(kind='walk_exit', x=raw[0], y=raw[1], dest=raw[2],
                                gate=raw[3], scr=raw[4], sx=raw[5], sy=raw[6]))
        off += 7
        safety += 1
    return entries

def read_interact_block(rom, base, ptr):
    """Read mixed NPC+spawn block. 5-byte entries, $FF terminated.
    Bit 7 of type: set=spawn/exit, clear=NPC."""
    entries = []
    off = base + (ptr - 0x4000)
    safety = 0
    while rom[off] != 0xFF and safety < 50:
        t = rom[off]
        raw = rom[off:off + 5]
        if t & 0x80:
            entries.append(dict(kind='spawn' if t == 0x8F else 'exit' if t == 0x90 else f'trig_{t:02X}',
                                type=t, param=raw[1], x=raw[2], y=raw[3], dest=raw[4]))
        else:
            entries.append(dict(kind='npc', type=t, sprite=raw[1],
                                x=raw[2], y=raw[3], script=raw[4]))
        off += 5
        safety += 1
    return entries


def main():
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()

    base = BANK_0B * 0x4000
    targets = [int(a) for a in sys.argv[1:]] if len(sys.argv) > 1 else range(107)

    for mid in targets:
        sub_ptr = u16(rom, base + (PTR_TABLE - 0x4000) + mid * 2)
        if sub_ptr < 0x4000 or sub_ptr > 0x7FFF:
            continue

        name = GATE_NAMES.get(mid, f'Map_{mid}')
        num_entries = get_subtable_size(rom, base, sub_ptr)

        print(f"{'='*60}")
        print(f"MAP {mid} (${mid:02X}): {name}")
        print(f"  Sub-table: ${sub_ptr:04X}, {num_entries} screen slots")

        # Build grid display
        grid = ['  '] * 8
        valid_screens = []
        sub_off = base + (sub_ptr - 0x4000)
        for scr in range(min(num_entries, 8)):
            rd_ptr = u16(rom, sub_off + scr * 2)
            if rd_ptr == 0xFFFF:
                grid[scr] = '--'
            elif 0x4000 <= rd_ptr <= 0x7FFF:
                rd = base + (rd_ptr - 0x4000)
                ram = u16(rom, rd)
                if 0xD900 <= ram <= 0xD9FF:
                    grid[scr] = f'{scr:2d}'
                    valid_screens.append((scr, rd_ptr, ram))

        print(f"  Grid: [{grid[0]}][{grid[1]}][{grid[2]}][{grid[3]}]")
        print(f"        [{grid[4]}][{grid[5]}][{grid[6]}][{grid[7]}]")
        print(f"{'='*60}")

        for scr, rd_ptr, ram in valid_screens:
            rd_off = base + (rd_ptr - 0x4000)
            print(f"\n  Screen {scr} (grid row {scr//4}, col {scr%4}):")
            print(f"    Room data: ${rd_ptr:04X}, RAM counter: ${ram:04X}")

            for step in range(20):
                se = rd_off + 2 + step * 6
                sid = rom[se]
                tbank = rom[se + 1]
                if tbank >= 0x80 or tbank == 0:
                    break

                interact_ptr = u16(rom, se + 2)  # bytes 2-3: NPC+spawn data
                exit_ptr = u16(rom, se + 4)       # bytes 4-5: exit checker data

                tile_info = ""
                if 0 < tbank < 0x80:
                    tb = tbank * 0x4000
                    td = u16(rom, tb + 1 + sid * 2)
                    tile_info = f" → tiles ${tbank:02X}:${td:04X}"

                print(f"    Step {step}: bank=${tbank:02X} step_id=${sid:02X}{tile_info}")

                if 0x4000 <= interact_ptr <= 0x7FFF:
                    entries = read_interact_block(rom, base, interact_ptr)
                    for e in entries:
                        if e['kind'] == 'npc':
                            print(f"      NPC  type=${e['type']:02X} sprite=${e['sprite']:02X} pos=({e['x']},{e['y']}) script={e['script']}")
                        elif e['kind'] == 'exit':
                            dn = GATE_NAMES.get(e['dest'], f'Map_{e["dest"]}')
                            print(f"      EXIT walk ({e['x']},{e['y']}) → {dn} (mt={e['dest']})")
                        elif e['kind'] == 'spawn':
                            dn = GATE_NAMES.get(e['dest'], f'Map_{e["dest"]}')
                            print(f"      SPAWN ({e['x']},{e['y']}) from {dn} (mt={e['dest']})")
                        else:
                            dn = GATE_NAMES.get(e['dest'], f'Map_{e["dest"]}')
                            print(f"      {e['kind']} ({e['x']},{e['y']}) dest={dn}")
                if 0x4000 <= exit_ptr <= 0x7FFF:
                    exits = read_exit_checker_block(rom, base, exit_ptr)
                    for e in exits:
                        if e['kind'] == 'walk_exit':
                            dn = GATE_NAMES.get(e['dest'], f'Map_{e["dest"]}')
                            print(f"      DOOR ({e['x']},{e['y']}) → {dn} (mt={e['dest']}) spawn=({e['sx']},{e['sy']})")
                        else:
                            print(f"      ARRIVE ({e['x']},{e['y']}) dest={e['dest']} scr={e['scr']}")
        print()


if __name__ == '__main__':
    main()
