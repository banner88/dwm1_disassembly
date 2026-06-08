"""Find a 128-byte WRAM region with ZERO code references.

Scans the entire ROM for load/store opcodes targeting each 128-byte
block in WRAM ($C000-$DFFF), reports the safest candidates.

Usage:
    python find_safe_wram.py data/DWM-original.gbc
"""
import sys
from pathlib import Path
from collections import defaultdict

# GB/GBC opcodes that take a 16-bit address operand
# Format: opcode -> (name, operand_offset, operand_size)
ADDR_OPCODES = {
    0x01: "ld bc,nn",   # 3-byte: 01 lo hi
    0x11: "ld de,nn",   # 3-byte: 11 lo hi
    0x21: "ld hl,nn",   # 3-byte: 21 lo hi
    0xC3: "jp nn",      # 3-byte: C3 lo hi
    0xCA: "jp z,nn",    # 3-byte
    0xC2: "jp nz,nn",   # 3-byte
    0xD2: "jp nc,nn",   # 3-byte
    0xDA: "jp c,nn",    # 3-byte
    0xCD: "call nn",    # 3-byte
    0xCC: "call z,nn",  # 3-byte
    0xC4: "call nz,nn", # 3-byte
    0xD4: "call nc,nn", # 3-byte
    0xDC: "call c,nn",  # 3-byte
    0xEA: "ld (nn),a",  # 3-byte: EA lo hi
    0xFA: "ld a,(nn)",  # 3-byte: FA lo hi
    0x08: "ld (nn),sp", # 3-byte: 08 lo hi
}

def main():
    rom_path = sys.argv[1] if len(sys.argv) > 1 else "data/DWM-original.gbc"
    d = bytearray(Path(rom_path).read_bytes())

    # Count references to each byte address in WRAM
    wram_refs = defaultdict(list)  # addr -> [(rom_offset, opcode_name)]
    
    for i in range(len(d) - 2):
        opcode = d[i]
        if opcode in ADDR_OPCODES:
            addr16 = d[i+1] | (d[i+2] << 8)
            if 0xC000 <= addr16 <= 0xDFFF:
                bank = i // 0x4000
                wram_refs[addr16].append((i, ADDR_OPCODES[opcode], bank))

    # Score each 128-byte block
    print("=" * 80)
    print("WRAM REGION SAFETY SCAN (128-byte blocks)")
    print("=" * 80)
    
    best_blocks = []
    for block_start in range(0xC080, 0xDF80, 0x08):  # scan every 8 bytes
        block_end = block_start + 128
        total_refs = 0
        direct_rw = 0  # ld a,(nn) / ld (nn),a — most dangerous
        for addr in range(block_start, block_end):
            for rom_off, op_name, bank in wram_refs.get(addr, []):
                total_refs += 1
                if "ld a,(nn)" in op_name or "ld (nn),a" in op_name:
                    direct_rw += 1
        best_blocks.append((total_refs, direct_rw, block_start, block_end))
    
    best_blocks.sort()
    
    print(f"\n  Top 20 safest 128-byte regions (0 refs = perfect):")
    print(f"  {'Start':>7s} {'End':>7s} {'TotalRefs':>9s} {'DirectRW':>8s}")
    for total, direct, start, end in best_blocks[:20]:
        marker = " <<<" if total == 0 else ""
        print(f"  ${start:04X}  ${end:04X}    {total:4d}       {direct:4d}{marker}")

    # Also check flag byte candidates (single byte, need zero refs)
    print(f"\n  Safe single-byte locations for flag (near best block):")
    for total, direct, start, end in best_blocks[:5]:
        # Check the byte just before the block
        for flag_addr in [start - 1, end, end + 1]:
            flag_refs = len(wram_refs.get(flag_addr, []))
            if flag_refs == 0:
                print(f"    ${flag_addr:04X}: 0 refs <<<")
                break

    # Detail the best candidate
    if best_blocks[0][0] == 0:
        winner = best_blocks[0]
        print(f"\n  RECOMMENDED: ${winner[2]:04X}-${winner[3]-1:04X} (128 bytes, 0 references)")
        print(f"  Flag byte: ${winner[2]-1:04X} (check: {len(wram_refs.get(winner[2]-1, []))} refs)")

if __name__ == "__main__":
    main()
