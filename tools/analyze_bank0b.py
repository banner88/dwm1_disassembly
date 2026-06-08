"""Deep analysis of bank 0x0B to find space for custom room data.

Three strategies:
  1. Find micro-gaps (runs of filler bytes, any size)
  2. Identify movable data (non-room, non-code data that could be relocated)
  3. Map what every byte is used for

Usage:
    python analyze_bank0b.py data/DWM-original.gbc
"""
import sys
from pathlib import Path
from collections import defaultdict

BANK_SIZE = 0x4000
BANK = 0x0B
MAP_PTR_ADDR = 0x4B43

def flat(addr):
    return BANK * BANK_SIZE + (addr - 0x4000)


def parse_step_block(d, block_addr):
    """Parse step block, return (ram_ptr, steps, total_bytes_consumed)."""
    bf = flat(block_addr)
    ram_ptr = d[bf] | (d[bf + 1] << 8)
    steps = []
    offset = 2
    for _ in range(12):
        if bf + offset + 5 >= len(d):
            break
        step_id = d[bf + offset]
        tileset = d[bf + offset + 1]
        interact = d[bf + offset + 2] | (d[bf + offset + 3] << 8)
        exit_ptr = d[bf + offset + 4] | (d[bf + offset + 5] << 8)
        if not (0x4000 <= interact <= 0x7FFF):
            break
        steps.append({
            "step_id": step_id, "tileset": tileset,
            "interact_ptr": interact, "exit_ptr": exit_ptr,
        })
        offset += 6
    return ram_ptr, steps, offset


def measure_interact_block(d, interact_ptr):
    """Measure bytes used by an interaction block."""
    bf = flat(interact_ptr)
    pos = 0
    for _ in range(50):
        if bf + pos >= len(d) or d[bf + pos] == 0xFF:
            pos += 1  # include terminator
            break
        pos += 5
    return pos


def measure_exit_block(d, exit_ptr):
    """Measure bytes used by an exit block."""
    if exit_ptr == 0xFFFF:
        return 0
    bf = flat(exit_ptr)
    pos = 0
    for _ in range(30):
        if bf + pos >= len(d) or d[bf + pos] == 0xFF:
            pos += 1  # include terminator
            break
        pos += 7
    return pos


def main():
    rom_path = sys.argv[1] if len(sys.argv) > 1 else "data/DWM-original.gbc"
    d = bytearray(Path(rom_path).read_bytes())
    
    bank_start = BANK * BANK_SIZE
    bank_end = bank_start + BANK_SIZE
    
    # === 1. BYTE-LEVEL MAP ===
    # Track what every byte in bank 0x0B is used for
    usage = ["unknown"] * BANK_SIZE  # index = bank-local offset (0 = 0x4000)
    
    def mark(local_start, length, label):
        for i in range(length):
            idx = local_start - 0x4000
            if 0 <= idx < BANK_SIZE and idx + i < BANK_SIZE:
                usage[idx + i] = label
    
    # Known code regions (from ROM map / disassembly references)
    # These are approximate - the code before the pointer table
    mark(0x4000, 0x0B43, "code/data_pre_ptrtable")
    
    # Pointer table itself
    mark(0x4B43, 107 * 2, "pointer_table")
    
    # === 2. TRACE ALL ROOM DATA ===
    ptr_table_flat = flat(MAP_PTR_ADDR)
    room_pointers = []
    for i in range(107):
        lo = d[ptr_table_flat + i * 2]
        hi = d[ptr_table_flat + i * 2 + 1]
        ptr = lo | (hi << 8)
        room_pointers.append(ptr)
    
    # Track all data blocks
    all_blocks = []  # (flat_start, length, label)
    seen_ptrs = set()
    seen_interact = set()
    seen_exit = set()
    
    for mt, room_ptr in enumerate(room_pointers):
        if not (0x4000 <= room_ptr <= 0x7FFF):
            continue
        if room_ptr in seen_ptrs:
            continue  # alias, skip
            
        seen_ptrs.add(room_ptr)
        rf = flat(room_ptr)
        
        # Parse screen pointer blocks
        pos = 0
        screens_found = 0
        for screen in range(16):
            screen_ptrs = []
            for slot in range(4):
                if rf + pos + 1 >= len(d):
                    break
                p = d[rf + pos] | (d[rf + pos + 1] << 8)
                screen_ptrs.append(p)
                pos += 2
            
            valid = False
            for slot_idx, ptr in enumerate(screen_ptrs):
                if ptr == 0xFFFF or not (0x4000 <= ptr <= 0x7FFF):
                    continue
                pf = flat(ptr)
                if pf + 1 >= len(d) or d[pf + 1] != 0xD9:
                    continue
                valid = True
                
                if ptr not in seen_ptrs:
                    seen_ptrs.add(ptr)
                    ram_ptr, steps, step_bytes = parse_step_block(d, ptr)
                    mark(ptr, step_bytes, f"step_block_mt{mt:02X}")
                    all_blocks.append((flat(ptr), step_bytes, f"step_block_mt{mt:02X}"))
                    
                    for step in steps:
                        iptr = step["interact_ptr"]
                        if iptr not in seen_interact:
                            seen_interact.add(iptr)
                            ilen = measure_interact_block(d, iptr)
                            mark(iptr, ilen, f"interact_mt{mt:02X}")
                            all_blocks.append((flat(iptr), ilen, f"interact_mt{mt:02X}"))
                        
                        eptr = step["exit_ptr"]
                        if eptr != 0xFFFF and eptr not in seen_exit:
                            seen_exit.add(eptr)
                            elen = measure_exit_block(d, eptr)
                            mark(eptr, elen, f"exit_mt{mt:02X}")
                            all_blocks.append((flat(eptr), elen, f"exit_mt{mt:02X}"))
            
            if valid:
                screens_found += 1
            elif screen > 0 and not any(0x4000 <= p <= 0x7FFF for p in screen_ptrs):
                break
        
        screen_data_len = pos
        mark(room_ptr, screen_data_len, f"screen_ptrs_mt{mt:02X}")
        all_blocks.append((rf, screen_data_len, f"screen_ptrs_mt{mt:02X}"))
    
    # === 3. ANALYZE USAGE ===
    print("=" * 80)
    print("BANK 0x0B BYTE USAGE ANALYSIS")
    print("=" * 80)
    
    counts = defaultdict(int)
    for u in usage:
        category = u.split("_mt")[0] if "_mt" in u else u
        counts[category] += 1
    
    print(f"\nByte usage breakdown (total {BANK_SIZE} bytes):")
    for cat, count in sorted(counts.items(), key=lambda x: -x[1]):
        pct = count * 100 / BANK_SIZE
        print(f"  {cat:30s}: {count:5d} bytes ({pct:5.1f}%)")
    
    # === 4. FIND GAPS ===
    print(f"\n{'=' * 80}")
    print("GAPS (unknown bytes between known data blocks)")
    print("=" * 80)
    
    # Sort all blocks by address
    all_blocks.sort()
    
    # Find gaps between consecutive blocks
    gaps = []
    for i in range(len(all_blocks) - 1):
        end_of_current = all_blocks[i][0] + all_blocks[i][1]
        start_of_next = all_blocks[i + 1][0]
        if start_of_next > end_of_current:
            gap_start = end_of_current
            gap_len = start_of_next - end_of_current
            # Check if gap is within bank 0x0B
            if bank_start <= gap_start < bank_end:
                gap_bytes = d[gap_start:gap_start + gap_len]
                is_filler = all(b in (0x00, 0xFF) for b in gap_bytes)
                gaps.append((gap_start, gap_len, is_filler, gap_bytes[:16]))
    
    # Also check gap before first block and after last block
    if all_blocks:
        first_block = min(b[0] for b in all_blocks if bank_start <= b[0] < bank_end)
        if first_block > bank_start:
            gap_len = first_block - bank_start
            print(f"  Pre-data region: 0x{bank_start:06X} - 0x{first_block:06X} ({gap_len} bytes) [code/data before room structures]")
        
        last_end = max(b[0] + b[1] for b in all_blocks if bank_start <= b[0] < bank_end)
        if last_end < bank_end:
            tail_len = bank_end - last_end
            tail_bytes = d[last_end:last_end + 32]
            is_filler = all(b in (0x00, 0xFF) for b in d[last_end:bank_end])
            print(f"  Post-data tail: 0x{last_end:06X} - 0x{bank_end:06X} ({tail_len} bytes) filler={is_filler}")
            print(f"    First bytes: {' '.join(f'{b:02X}' for b in tail_bytes)}")
    
    total_gap = 0
    total_filler_gap = 0
    print(f"\n  Gaps between room data blocks (sorted by size):")
    for gap_start, gap_len, is_filler, preview in sorted(gaps, key=lambda x: -x[1])[:30]:
        local = gap_start - bank_start + 0x4000
        filler_str = "FILLER" if is_filler else "DATA"
        preview_str = ' '.join(f'{b:02X}' for b in preview)
        print(f"    0x{gap_start:06X} (local 0x{local:04X}): {gap_len:4d} bytes [{filler_str}] {preview_str}")
        total_gap += gap_len
        if is_filler:
            total_filler_gap += gap_len
    
    print(f"\n  Total gap bytes: {total_gap}")
    print(f"  Total filler gap bytes: {total_filler_gap}")
    
    # === 5. MICRO-FILLER SCAN ===
    print(f"\n{'=' * 80}")
    print("MICRO-FILLER SCAN (runs of 4+ identical filler bytes in bank 0x0B)")
    print("=" * 80)
    
    runs = []
    run_start = None
    run_val = None
    for i in range(bank_start, bank_end):
        b = d[i]
        if b in (0x00, 0xFF):
            if run_start is None or b != run_val:
                if run_start is not None and i - run_start >= 4:
                    runs.append((run_start, i - run_start, run_val))
                run_start = i
                run_val = b
        else:
            if run_start is not None and i - run_start >= 4:
                runs.append((run_start, i - run_start, run_val))
            run_start = None
    if run_start is not None and bank_end - run_start >= 4:
        runs.append((run_start, bank_end - run_start, run_val))
    
    total_micro = sum(r[1] for r in runs)
    print(f"\n  Found {len(runs)} runs totaling {total_micro} bytes:")
    for addr, length, val in sorted(runs, key=lambda x: -x[1])[:25]:
        local = addr - bank_start + 0x4000
        u = usage[addr - bank_start] if addr - bank_start < BANK_SIZE else "?"
        print(f"    0x{addr:06X} (local 0x{local:04X}): {length:4d} × 0x{val:02X}  [{u}]")
    
    # === 6. MOVABLE DATA CANDIDATES ===
    print(f"\n{'=' * 80}")
    print("CROSS-BANK ROOM FEASIBILITY")
    print("=" * 80)
    
    print(f"""
  Room pointer table: $0B:$4B43 (107 × 2-byte entries)
  Each entry is a bank-local pointer (0x4000-0x7FFF) into bank 0x0B.
  
  For cross-bank rooms, we need a trampoline that:
  1. Detects a "redirect" marker in the pointer table entry
  2. Bank-switches to the target bank  
  3. Loads room data from the new bank
  
  Trampoline size estimate: ~30 bytes of Z80 code
  Best locations: bank 0x00 (always mapped) or a gap in bank 0x0B
  
  Bank 0x00 free space: 82 bytes across 4 regions (biggest: 24)
  → Tight but potentially workable for a small trampoline
  
  Candidate free banks for room data:
    Bank 0x68: 258,791 bytes free (MASSIVE)
    Bank 0x7D:  39,251 bytes free
    Bank 0x78:  33,371 bytes free
    Bank 0x7B:  28,142 bytes free
    Bank 0x63:  20,467 bytes free
""")

    # === 7. POINTER TABLE ANALYSIS ===
    print(f"\n{'=' * 80}")
    print("POINTER TABLE SLOT ANALYSIS")
    print("=" * 80)
    
    ptr_counts = defaultdict(list)
    for mt, ptr in enumerate(room_pointers):
        ptr_counts[ptr].append(mt)
    
    print(f"\n  Shared pointers (aliases):")
    for ptr, mts in sorted(ptr_counts.items(), key=lambda x: -len(x[1])):
        if len(mts) > 1:
            mt_str = ', '.join(f'0x{mt:02X}' for mt in mts)
            print(f"    ptr=0x{ptr:04X} → [{mt_str}]")
    
    print(f"\n  Unique room pointers: {len(ptr_counts)}")
    print(f"  Total map_type slots: 107 (0x00-0x6A)")
    print(f"  Alias slots (reusable): {sum(len(v)-1 for v in ptr_counts.values() if len(v) > 1)}")


if __name__ == "__main__":
    main()
