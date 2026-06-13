#!/usr/bin/env python3
"""
analyze_bank17.py — Parse Bank $17 palette and attribute data.

Bank $17 contains the GBC-specific per-room color system:
  - Tile attribute data pointers (which LZSS-compressed attribute map to load)
  - Palette color data (raw GBC RGB555, 8 bytes per palette)

Structure mirrors Bank $0B's room data:
  AttrPtrTable[$476F + mapID*2] → screen_table
    screen_table[screen*2] → attr_block
      attr_block: [ram_flag_addr:2] + steps × [attr_idx:1, attr_bank:1, pal_ptr:2]

Usage:
    python3 tools/analyze_bank17.py              # Full summary
    python3 tools/analyze_bank17.py --room 0x00  # Single room detail
    python3 tools/analyze_bank17.py --palettes   # Palette color dump
"""
import os, sys, json
from collections import defaultdict

ROM_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data', 'DWM-original.gbc')

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dwm.map_names import MAP_NAMES  # canonical room names (97 entries)

ATTR_PTR_TABLE = 0x476F
BANK_0B_PTR_TABLE = 0x4B43


def rw(rom, bank, addr):
    off = bank * 0x4000 + (addr - 0x4000)
    if off + 1 >= len(rom):
        return 0xFFFF
    return rom[off] | (rom[off+1] << 8)


def get_step_counts(rom):
    """Get step counts from Bank $0B for cross-reference."""
    counts = {}
    for mapid in range(107):
        screen_ptr = rw(rom, 0x0B, BANK_0B_PTR_TABLE + mapid * 2)
        if screen_ptr < 0x4000 or screen_ptr >= 0x8000:
            continue
        min_data = 0x8000
        for screen in range(32):
            a = screen_ptr + screen * 2
            if a >= 0x8000:
                break
            step_block = rw(rom, 0x0B, a)
            if step_block < 0x4000 or step_block >= 0x8000 or step_block == 0xFFFF:
                continue
            if step_block < min_data:
                min_data = step_block
            off = 0x0B * 0x4000 + step_block - 0x4000 + 2
            count = 0
            while count < 30:
                tb = rom[off + count * 6 + 1]
                if tb == 0 or tb >= 0x80 or tb == 0xFF:
                    break
                count += 1
            counts[(mapid, screen)] = count
            if screen_ptr + (screen + 1) * 2 >= min_data:
                break
    return counts


def rgb555_to_rgb(val):
    """Convert GBC RGB555 (little-endian) to (R,G,B) 0-255."""
    r = (val & 0x1F) * 8
    g = ((val >> 5) & 0x1F) * 8
    b = ((val >> 10) & 0x1F) * 8
    return (r, g, b)


def parse_palette(rom, bank, addr, count=4):
    """Parse count×4-color GBC palettes at bank:addr."""
    palettes = []
    off = bank * 0x4000 + (addr - 0x4000)
    for p in range(count):
        colors = []
        for c in range(4):
            val = rom[off] | (rom[off+1] << 8)
            colors.append(rgb555_to_rgb(val))
            off += 2
        palettes.append(colors)
    return palettes


def parse_room_attrs(rom, mapid, step_counts):
    """Parse all attribute data for a room."""
    screen_table = rw(rom, 0x17, ATTR_PTR_TABLE + mapid * 2)
    if screen_table < 0x4000 or screen_table >= 0x8000:
        return None

    screens = []
    for screen in range(32):
        a = screen_table + screen * 2
        if a >= 0x8000:
            break
        entry = rw(rom, 0x17, a)
        if entry == 0xFFFF or entry < 0x4000 or entry >= 0x8000:
            screens.append(None)
            continue

        nsteps = step_counts.get((mapid, screen), 0)
        if nsteps == 0:
            screens.append(None)
            continue

        off = 0x17 * 0x4000 + entry - 0x4000
        ram_addr = rom[off] | (rom[off+1] << 8)

        steps = []
        for step in range(nsteps):
            pos = off + 2 + step * 4
            attr_idx = rom[pos]
            attr_bank = rom[pos + 1]
            pal_ptr = rom[pos + 2] | (rom[pos + 3] << 8)
            steps.append({
                'attr_idx': attr_idx,
                'attr_bank': attr_bank,
                'pal_ptr': pal_ptr,
            })

        screens.append({
            'ptr': entry,
            'ram_addr': ram_addr,
            'steps': steps,
        })

    return screens


def print_room_detail(rom, mapid, step_counts):
    """Print detailed attr data for one room."""
    name = MAP_NAMES.get(mapid, f'Map_{mapid:02X}')
    screens = parse_room_attrs(rom, mapid, step_counts)
    if screens is None:
        print(f"{name} (${mapid:02X}): no attribute data")
        return

    print(f"\n=== {name} (map_type=${mapid:02X}) ===")
    for s, scr in enumerate(screens):
        if scr is None:
            continue
        print(f"  Screen {s} (ptr=${scr['ptr']:04X}, ram=${scr['ram_addr']:04X}):")
        for i, step in enumerate(scr['steps']):
            pal_valid = 0x4000 <= step['pal_ptr'] < 0x8000
            pal_str = f"${step['pal_ptr']:04X}"
            if pal_valid:
                pals = parse_palette(rom, 0x17, step['pal_ptr'])
                col_str = ' | '.join(
                    ','.join(f'({r},{g},{b})' for r, g, b in p)
                    for p in pals
                )
                pal_str += f"  [{col_str}]"
            print(f"    Step {i}: attr=${step['attr_idx']:02X} @ bank ${step['attr_bank']:02X}, pal={pal_str}")


def print_summary(rom, step_counts):
    """Print summary of all rooms."""
    pal_ptrs = set()
    attr_combos = set()
    total = 0

    for mapid in range(107):
        screens = parse_room_attrs(rom, mapid, step_counts)
        if screens is None:
            continue
        for scr in screens:
            if scr is None:
                continue
            for step in scr['steps']:
                total += 1
                if 0x4000 <= step['pal_ptr'] < 0x8000:
                    pal_ptrs.add(step['pal_ptr'])
                if 0x17 <= step['attr_bank'] < 0x80:
                    attr_combos.add((step['attr_idx'], step['attr_bank']))

    print(f"=== BANK $17 ATTRIBUTE/PALETTE SUMMARY ===")
    print(f"Total step attr entries: {total}")
    print(f"Unique valid palette ptrs: {len(pal_ptrs)}")
    print(f"Unique valid attr combos: {len(attr_combos)}")
    print()

    # Palette pointer ranges
    valid_pals = sorted(p for p in pal_ptrs if p >= 0x5000)
    if valid_pals:
        print(f"Palette data range: ${min(valid_pals):04X}-${max(valid_pals)+0x1F:04X}")
        print(f"  ({len(valid_pals)} unique × 32 bytes = {len(valid_pals)*32} bytes)")
    print()

    # Attr bank distribution
    banks = defaultdict(int)
    for _, b in attr_combos:
        banks[b] += 1
    print("Attribute data banks:")
    for b in sorted(banks.keys()):
        indices = sorted(i for i, bb in attr_combos if bb == b)
        print(f"  Bank ${b:02X}: {banks[b]} unique indices (${min(indices):02X}-${max(indices):02X})")

    print()
    print("Key data structures for custom rooms:")
    print("  1. Attribute map: LZSS-compressed 256-byte tile palette map")
    print("     - Loaded from attr_bank at ptr_table[$4001 + attr_idx*2]")
    print("     - Same LZSS decompressor as tile layouts")
    print("     - Each byte = palette assignment for one tile")
    print("  2. Palette colors: 32 bytes of raw GBC RGB555 data")
    print("     - 4 BG palettes × 4 colors × 2 bytes = 32 bytes")
    print("     - Written to $C797+ via Call_017_46a1")
    print("  3. Custom room needs: one attr entry per step, one palette block")


if __name__ == '__main__':
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()

    step_counts = get_step_counts(rom)

    if '--room' in sys.argv:
        idx = sys.argv.index('--room')
        mapid = int(sys.argv[idx + 1], 0)
        print_room_detail(rom, mapid, step_counts)
    elif '--palettes' in sys.argv:
        # Dump all unique palette colors
        pal_ptrs = set()
        for mapid in range(107):
            screens = parse_room_attrs(rom, mapid, step_counts)
            if not screens:
                continue
            for scr in screens:
                if not scr:
                    continue
                for step in scr['steps']:
                    if 0x5000 <= step['pal_ptr'] < 0x8000:
                        pal_ptrs.add(step['pal_ptr'])
        for ptr in sorted(pal_ptrs):
            pals = parse_palette(rom, 0x17, ptr)
            print(f"${ptr:04X}: ", end="")
            for p_idx, p in enumerate(pals):
                colors = ' '.join(f'#{r:02X}{g:02X}{b:02X}' for r, g, b in p)
                print(f"P{p_idx}=[{colors}] ", end="")
            print()
    else:
        print_summary(rom, step_counts)
        print()
        # Show a few representative rooms
        for mapid in [0x00, 0x01, 0x02, 0x05, 0x2F]:
            print_room_detail(rom, mapid, step_counts)
