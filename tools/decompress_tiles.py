#!/usr/bin/env python3
"""Decompress DWM1 LZ tile layouts from ROM.

The game uses LZSS compression for tile map data. Each tile layout is
stored in a tileset bank, indexed by step_id via a pointer table at $4001.

Usage:
  python3 -m tools.decompress_tiles 0x2A 0x01    # bank $2A, step_id 1 (Castle screen 0)
  python3 -m tools.decompress_tiles --room 0      # all tile layouts for map_type 0
"""
import os, sys, json

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROM_PATH = os.path.join(SCRIPT_DIR, '..', 'data', 'DWM-original.gbc')


def decompress_lz(rom, bank, step_id):
    """Decompress an LZSS tile layout.
    
    Args:
        rom: full ROM bytes
        bank: tileset bank number
        step_id: index into pointer table at $4001 in the bank
    
    Returns:
        (decompressed_bytes, data_addr) or None on error
    """
    base = bank * 0x4000
    
    # Read pointer table entry
    ptr_off = base + 1 + step_id * 2
    if ptr_off + 1 >= len(rom):
        return None
    data_addr = rom[ptr_off] | (rom[ptr_off + 1] << 8)
    
    # Read header: [length:2][marker:1]
    src = base + (data_addr - 0x4000)
    if src + 3 >= len(rom):
        return None
    
    out_len = rom[src] | (rom[src + 1] << 8)
    marker = rom[src + 2]
    src += 3
    
    if out_len == 0 or out_len > 0x2000:
        return None
    
    # Decompress
    output = bytearray(out_len)
    out_pos = 0
    
    while out_pos < out_len:
        if src >= len(rom):
            break
        
        b = rom[src]
        src += 1
        
        if b != marker:
            # Literal byte
            output[out_pos] = b
            out_pos += 1
        else:
            # LZ back-reference
            if src + 1 >= len(rom):
                break
            
            offset_low = rom[src]
            src += 1
            control = rom[src]
            src += 1
            
            # Copy length = (control & 0x0F) + 4
            copy_len = (control & 0x0F) + 4
            if copy_len == 0x13:  # extended length
                if src >= len(rom):
                    break
                copy_len = rom[src] + 0x13
                src += 1
            
            # Back-reference offset
            offset_high = (control >> 4) & 0x0F
            back_offset = (offset_high << 8) | offset_low
            
            # Copy from earlier in the output buffer
            for i in range(copy_len):
                if out_pos >= out_len:
                    break
                ref_pos = back_offset + i
                # Circular buffer wrapping (matches game's $F0/$10 logic)
                if ref_pos >= out_len:
                    ref_pos -= 0x1000  # wrap by subtracting 4096
                if 0 <= ref_pos < out_len:
                    output[out_pos] = output[ref_pos]
                else:
                    output[out_pos] = 0  # truly out of bounds
                out_pos += 1
    
    return bytes(output), data_addr


def print_tile_grid(data, width=32, height=16):
    """Print tile data as a grid."""
    for y in range(height):
        row = data[y * width:(y + 1) * width]
        # Show only the visible 10-tile-wide area for readability
        visible = row[:10]
        hex_row = ' '.join(f'{b:02X}' for b in visible)
        print(f'  row {y:2d}: {hex_row}')


def main():
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    
    if len(sys.argv) >= 3 and sys.argv[1] != '--room':
        # Direct bank + step_id mode
        bank = int(sys.argv[1], 0)
        step_id = int(sys.argv[2], 0)
        
        result = decompress_lz(rom, bank, step_id)
        if result is None:
            print(f"Failed to decompress bank ${bank:02X} step_id ${step_id:02X}")
            return
        
        data, addr = result
        print(f"Bank ${bank:02X}, step_id ${step_id:02X} → ${addr:04X}")
        print(f"Decompressed: {len(data)} bytes")
        print_tile_grid(data)
    
    elif len(sys.argv) >= 3 and sys.argv[1] == '--room':
        # Room mode — dump all tile layouts for a map_type
        mt = int(sys.argv[2], 0)
        
        base_0b = 0x0B * 0x4000
        sub_ptr = rom[base_0b + (0x4B43 - 0x4000) + mt * 2] | \
                  (rom[base_0b + (0x4B43 - 0x4000) + mt * 2 + 1] << 8)
        
        if sub_ptr < 0x4000 or sub_ptr > 0x7FFF:
            print(f"Invalid sub_table for mt={mt}")
            return
        
        # Find sub-table size
        sub_off = base_0b + (sub_ptr - 0x4000)
        min_data = sub_ptr + 16
        for i in range(8):
            p = rom[sub_off + i * 2] | (rom[sub_off + i * 2 + 1] << 8)
            if 0x4000 <= p < 0x7FFF and p != 0xFFFF and p > sub_ptr:
                min_data = min(min_data, p)
        num_entries = min((min_data - sub_ptr) // 2, 8)
        
        seen_tiles = set()
        for scr in range(num_entries):
            rd_ptr = rom[sub_off + scr * 2] | (rom[sub_off + scr * 2 + 1] << 8)
            if rd_ptr == 0xFFFF or rd_ptr < 0x4000:
                continue
            rd = base_0b + (rd_ptr - 0x4000)
            ram = rom[rd] | (rom[rd + 1] << 8)
            if ram < 0xD900 or ram > 0xD9FF:
                continue
            
            step = 0
            while True:
                se = rd + 2 + step * 6
                sid = rom[se]
                tbank = rom[se + 1]
                if tbank >= 0x80 or tbank == 0:
                    break
                
                key = (tbank, sid)
                if key not in seen_tiles:
                    seen_tiles.add(key)
                    result = decompress_lz(rom, tbank, sid)
                    if result:
                        data, addr = result
                        print(f"Screen {scr}, Step {step}: bank=${tbank:02X} step_id=${sid:02X} → ${addr:04X} ({len(data)} bytes)")
                        print_tile_grid(data)
                        print()
                step += 1
    else:
        print("Usage:")
        print("  python3 -m tools.decompress_tiles 0x2A 0x01     # bank + step_id")
        print("  python3 -m tools.decompress_tiles --room 0      # all layouts for map_type")


if __name__ == '__main__':
    main()
