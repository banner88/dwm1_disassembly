"""Investigate the 732-byte tail at end of bank 0x0B.

What is it? Is anything referencing it? Can it be moved?

Usage:
    python investigate_tail.py data/DWM-original.gbc
"""
import sys
from pathlib import Path
from collections import defaultdict

BANK_SIZE = 0x4000
BANK = 0x0B

def main():
    rom_path = sys.argv[1] if len(sys.argv) > 1 else "data/DWM-original.gbc"
    d = bytearray(Path(rom_path).read_bytes())

    bank_start = BANK * BANK_SIZE
    bank_end = bank_start + BANK_SIZE
    tail_start_flat = 0x02FD24
    tail_start_local = 0x7D24
    tail_len = bank_end - tail_start_flat

    print("=" * 80)
    print(f"TAIL REGION: flat 0x{tail_start_flat:06X} - 0x{bank_end-1:06X}")
    print(f"  Bank-local: 0x{tail_start_local:04X} - 0x7FFF")
    print(f"  Size: {tail_len} bytes")
    print("=" * 80)

    # Hex dump the tail
    print("\nHex dump (first 256 bytes):")
    for i in range(min(256, tail_len)):
        addr = tail_start_flat + i
        if i % 16 == 0:
            print(f"\n  {tail_start_local + i:04X}: ", end="")
        print(f"{d[addr]:02X} ", end="")
    print("\n")

    # Check for patterns
    tail_data = d[tail_start_flat:bank_end]
    
    # Is it graphics? (look for repeating tile-like patterns)
    # GBC tiles are 16 bytes each (8×8 pixels, 2 bits per pixel)
    print("Pattern analysis:")
    zero_count = sum(1 for b in tail_data if b == 0x00)
    ff_count = sum(1 for b in tail_data if b == 0xFF)
    unique_bytes = len(set(tail_data))
    print(f"  Zero bytes: {zero_count}/{tail_len} ({zero_count*100/tail_len:.1f}%)")
    print(f"  0xFF bytes: {ff_count}/{tail_len} ({ff_count*100/tail_len:.1f}%)")
    print(f"  Unique byte values: {unique_bytes}/256")
    
    # Check if it looks like 2bpp tile data
    # Tiles have pairs of bytes for each row, high entropy in both
    print(f"\n  Byte value histogram (top 10):")
    from collections import Counter
    hist = Counter(tail_data)
    for val, count in hist.most_common(10):
        bar = "#" * min(count, 40)
        print(f"    0x{val:02X}: {count:4d} {bar}")

    # === REFERENCE SCAN ===
    # Search ENTIRE ROM for 2-byte pointers pointing into the tail region
    # (bank-local addresses 0x7D24-0x7FFF)
    print(f"\n{'=' * 80}")
    print("REFERENCE SCAN: who points to the tail?")
    print("=" * 80)

    # Scan for bank-local references (looking for 2-byte LE pointers)
    refs_in_bank0b = []
    refs_in_bank00 = []
    refs_elsewhere = []

    for i in range(len(d) - 1):
        lo = d[i]
        hi = d[i + 1]
        ptr = lo | (hi << 8)
        if tail_start_local <= ptr <= 0x7FFF:
            bank_of_ref = i // BANK_SIZE
            local_of_ref = (i % BANK_SIZE) + (0 if bank_of_ref == 0 else 0x4000)
            if bank_of_ref == BANK:
                refs_in_bank0b.append((i, local_of_ref, ptr))
            elif bank_of_ref == 0:
                refs_in_bank00.append((i, local_of_ref, ptr))
            else:
                refs_elsewhere.append((i, local_of_ref, ptr, bank_of_ref))

    print(f"\n  References from bank 0x0B ({len(refs_in_bank0b)}):")
    for flat, local, ptr in refs_in_bank0b[:20]:
        # Check context: is this ref inside room data or code?
        region = "pre-table" if local < 0x4B43 else "ptr-table" if local < 0x4C13 else "room-data" if local < tail_start_local else "tail"
        print(f"    flat=0x{flat:06X} local=0x{local:04X} → 0x{ptr:04X}  [{region}]")
    if len(refs_in_bank0b) > 20:
        print(f"    ... +{len(refs_in_bank0b)-20} more")

    print(f"\n  References from bank 0x00 ({len(refs_in_bank00)}):")
    for flat, local, ptr in refs_in_bank00[:10]:
        print(f"    flat=0x{flat:06X} local=0x{local:04X} → 0x{ptr:04X}")

    # Filter refs_elsewhere to only show banks that commonly interact with 0x0B
    bank_counts = defaultdict(int)
    for _, _, _, bank in refs_elsewhere:
        bank_counts[bank] += 1
    print(f"\n  References from other banks: {len(refs_elsewhere)} total")
    print(f"  Top referring banks:")
    for bank, count in sorted(bank_counts.items(), key=lambda x: -x[1])[:10]:
        print(f"    Bank 0x{bank:02X}: {count} refs")

    # === CHECK IF TAIL IS REFERENCED BY ROOM LOADING CODE ===
    print(f"\n{'=' * 80}")
    print("CODE REFERENCE CHECK")
    print("=" * 80)
    
    # Look for immediate loads of addresses in the tail range
    # Common Z80/GB patterns: 
    #   21 xx 7D-7F  → ld hl, $7Dxx-$7Fxx
    #   11 xx 7D-7F  → ld de, $7Dxx-$7Fxx
    #   01 xx 7D-7F  → ld bc, $7Dxx-$7Fxx
    #   FA xx 7D-7F  → ld a, ($7Dxx-$7Fxx)
    #   CD xx 7D-7F  → call $7Dxx-$7Fxx
    #   C3 xx 7D-7F  → jp $7Dxx-$7Fxx
    
    code_refs = []
    for i in range(bank_start, bank_end - 2):
        opcode = d[i]
        if opcode in (0x21, 0x11, 0x01, 0xFA, 0xEA, 0xCD, 0xC3):
            ptr = d[i+1] | (d[i+2] << 8)
            if tail_start_local <= ptr <= 0x7FFF:
                local = (i - bank_start) + 0x4000
                names = {0x21:"ld hl", 0x11:"ld de", 0x01:"ld bc", 
                         0xFA:"ld a,(...)", 0xEA:"ld (...),a", 0xCD:"call", 0xC3:"jp"}
                code_refs.append((local, names.get(opcode, f"op_{opcode:02X}"), ptr))

    if code_refs:
        print(f"\n  Direct code references to tail from bank 0x0B:")
        for local, instr, ptr in code_refs:
            print(f"    0x{local:04X}: {instr} 0x{ptr:04X}")
    else:
        print(f"\n  No direct code references to tail from bank 0x0B code region!")
        print(f"  (This suggests the tail may be DATA referenced by pointer, not called directly)")

    # Also check bank 0 code
    code_refs_bank0 = []
    for i in range(0, BANK_SIZE - 2):
        opcode = d[i]
        if opcode in (0x21, 0x11, 0x01, 0xFA, 0xEA, 0xCD, 0xC3):
            ptr = d[i+1] | (d[i+2] << 8)
            if tail_start_local <= ptr <= 0x7FFF:
                code_refs_bank0.append((i, {0x21:"ld hl", 0x11:"ld de", 0x01:"ld bc", 
                         0xFA:"ld a,(...)", 0xEA:"ld (...),a", 0xCD:"call", 0xC3:"jp"}.get(opcode, f"op_{opcode:02X}"), ptr))

    if code_refs_bank0:
        print(f"\n  Direct code references to tail from bank 0x00:")
        for local, instr, ptr in code_refs_bank0[:10]:
            print(f"    0x{local:04X}: {instr} 0x{ptr:04X}")

    # === WHAT COULD IT BE? ===
    print(f"\n{'=' * 80}")
    print("ASSESSMENT")
    print("=" * 80)

    # Check if it looks like tilemap/collision data
    # Tilemaps are often structured with row-like patterns
    has_structure = False
    for stride in [10, 16, 20, 32]:
        rows_similar = 0
        for row in range(0, min(tail_len, 320), stride):
            if row + stride < tail_len:
                row_data = tail_data[row:row+stride]
                if len(set(row_data)) < stride // 2:
                    rows_similar += 1
        if rows_similar > 5:
            has_structure = True
            print(f"  Possible tilemap/collision structure with stride {stride}")

    if not has_structure:
        print(f"  No obvious tilemap structure detected")
    
    # Check for 2bpp tile graphics pattern
    tile_like = 0
    for i in range(0, min(tail_len, 512), 2):
        if i + 1 < tail_len:
            # In 2bpp tiles, bytes come in pairs
            # They tend to have bit-level structure
            b1, b2 = tail_data[i], tail_data[i+1]
            if b1 != 0 or b2 != 0:
                tile_like += 1
    print(f"  Non-zero byte pairs in first 256 pairs: {tile_like}")
    print(f"  (High = likely graphics data, Low = likely padding/sparse data)")


if __name__ == "__main__":
    main()
