"""Convert tileset bank pointer tables ($4001) to labeled dw blocks.

Each tileset bank has:
  $4000: db bank_number (header byte)
  $4001: pointer table (N × 2B dw entries → LZSS data)
  $4001+N*2: LZSS compressed tile layouts/graphics

Usage:
    python -m tools.gen_tileset_banks          # generate all banks
    python -m tools.gen_tileset_banks 0x2A     # single bank
    python -m tools.gen_tileset_banks --apply   # write directly to asm files
"""
import argparse, os, sys
from pathlib import Path

BANK_SIZE = 0x4000

# Banks that have pointer tables at $4001
TILESET_BANKS = [0x23, 0x24, 0x25, 0x26, 0x28, 0x29, 0x2A, 0x2D,
                 0x2E, 0x2F, 0x30, 0x31, 0x37, 0x38]

# Which rooms use each bank (for comments)
BANK_USAGE = {
    0x23: "gate dungeon tileset A",
    0x24: "gate dungeon tileset B",
    0x25: "gate dungeon tileset C",
    0x26: "gate dungeon tileset D",
    0x28: "gate dungeon tileset E",
    0x29: "overworld tileset (Gate_08, Gate_0C, ArenaRooms)",
    0x2A: "Castle/GreatTree/Bazaar tileset",
    0x2D: "gate boss room tileset",
    0x2E: "gate dungeon tileset F",
    0x2F: "gate dungeon tileset G",
    0x30: "gate dungeon tileset H",
    0x31: "gate dungeon tileset I",
    0x37: "special room tileset (conveyor, maze, treasure)",
    0x38: "gate dungeon tileset J",
}


def u16(rom, off):
    return rom[off] | (rom[off + 1] << 8)


def generate_bank(rom, bank):
    """Generate labeled asm for one tileset bank."""
    base = bank * BANK_SIZE
    lines = []
    
    # Bank header
    usage = BANK_USAGE.get(bank, "tileset data")
    lines.append(f'; Tileset bank ${bank:02X} — {usage}')
    lines.append(f'; Pointer table at $4001: step_id → LZSS compressed tile data')
    lines.append(f'; Each pointer references LZSS data within this bank.')
    lines.append(f'; Decompressed data: 512B tile layouts (32×16 grid) or 2048B tile graphics (128 tiles)')
    lines.append(f'')
    lines.append(f'SECTION "ROM Bank ${bank:03x}", ROMX[$4000], BANK[${bank:02X}]')
    
    # Header byte at $4000
    header = rom[base]
    lines.append(f'    db ${header:02X}  ; bank ID')
    lines.append(f'')
    
    # Determine pointer table size
    ptrs = []
    for i in range(128):
        ptr = u16(rom, base + 1 + i * 2)
        if 0x4000 <= ptr <= 0x7FFF:
            ptrs.append(ptr)
        else:
            break
    
    if not ptrs:
        # No pointer table — just dump as raw db
        lines.append('; No pointer table detected')
        emit_raw(rom, base + 1, BANK_SIZE - 1, lines)
        return "\n".join(lines)
    
    num_entries = len(ptrs)
    table_end = 0x4001 + num_entries * 2
    
    # Pointer table
    lines.append(f'TilesetPtrTable_{bank:02X}:  ; {num_entries} entries')
    for i, ptr in enumerate(ptrs):
        lines.append(f'    dw TileData_{bank:02X}_{i:02X}'
                    f'  ; [{i:2d}] → ${ptr:04X}')
    lines.append(f'')
    
    # Sort pointers to determine data block boundaries
    sorted_ptrs = sorted(set(ptrs))
    ptr_to_labels = {}
    for i, ptr in enumerate(ptrs):
        if ptr not in ptr_to_labels:
            ptr_to_labels[ptr] = []
        ptr_to_labels[ptr].append(i)
    
    # Emit data blocks
    for idx, ptr in enumerate(sorted_ptrs):
        # Determine block size (gap to next pointer or end of bank)
        if idx + 1 < len(sorted_ptrs):
            next_ptr = sorted_ptrs[idx + 1]
        else:
            next_ptr = 0x4000 + BANK_SIZE
        block_size = next_ptr - ptr
        
        # Find which step_ids use this pointer
        step_ids = ptr_to_labels.get(ptr, [])
        step_str = ", ".join(f"${s:02X}" for s in step_ids)
        
        # Label — use first step_id
        first_id = step_ids[0]
        label = f'TileData_{bank:02X}_{first_id:02X}'
        
        # Add alias labels for shared pointers
        if len(step_ids) > 1:
            for sid in step_ids[1:]:
                lines.append(f'TileData_{bank:02X}_{sid:02X} EQU TileData_{bank:02X}_{first_id:02X}'
                           f'  ; shared with step ${first_id:02X}')
        
        lines.append(f'{label}:  ; ${ptr:04X} ({block_size} bytes, step=[{step_str}])')
        
        # Emit raw data
        f = base + (ptr - 0x4000)
        pos = 0
        while pos < block_size:
            chunk = min(16, block_size - pos)
            hex_vals = ", ".join(f"${rom[f + pos + i]:02X}" for i in range(chunk))
            lines.append(f'    db {hex_vals}')
            pos += chunk
        lines.append(f'')
    
    return "\n".join(lines)


def emit_raw(rom, start, size, lines):
    """Emit raw db bytes."""
    pos = 0
    while pos < size:
        chunk = min(16, size - pos)
        hex_vals = ", ".join(f"${rom[start + pos + i]:02X}" for i in range(chunk))
        lines.append(f'    db {hex_vals}')
        pos += chunk


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('banks', nargs='*', type=lambda x: int(x, 0),
                   help="Banks to convert (hex, e.g. 0x2A)")
    ap.add_argument('--apply', action='store_true',
                   help="Write directly to disassembly/*.asm files")
    ap.add_argument('--rom', default='data/DWM-original.gbc')
    args = ap.parse_args()
    
    rom = bytearray(Path(args.rom).read_bytes())
    banks = args.banks if args.banks else TILESET_BANKS
    
    for bank in banks:
        if bank not in TILESET_BANKS:
            print(f"Warning: bank ${bank:02X} not in known tileset banks, skipping")
            continue
        
        asm = generate_bank(rom, bank)
        
        if args.apply:
            asm_path = Path(f"disassembly/bank_{bank:03x}.asm")
            asm_path.write_text(asm + "\n")
            print(f"Wrote {asm_path} ({len(asm.splitlines())} lines)")
        else:
            if len(banks) > 1:
                print(f"=== Bank ${bank:02X} ===")
            print(asm)
            print()


if __name__ == "__main__":
    main()
