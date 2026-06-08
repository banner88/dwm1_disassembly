"""Find exact free space locations in bank 0x00 for the cross-bank trampoline.

We need ~20 bytes contiguous for the trampoline entry point.
The rest goes in WRAM (initialized lazily).

Usage:
    python find_bank0_space.py data/DWM-original.gbc
"""
import sys
from pathlib import Path

BANK_SIZE = 0x4000

def main():
    rom_path = sys.argv[1] if len(sys.argv) > 1 else "data/DWM-original.gbc"
    d = bytearray(Path(rom_path).read_bytes())

    print("=" * 80)
    print("BANK 0x00 FREE SPACE (runs of 4+ filler bytes)")
    print("=" * 80)

    runs = []
    start = None
    val = None
    for i in range(BANK_SIZE):
        b = d[i]
        if b in (0x00, 0xFF):
            if start is None:
                start = i
                val = b
            elif b != val:
                if i - start >= 4:
                    runs.append((start, i - start, val))
                start = i
                val = b
        else:
            if start is not None and i - start >= 4:
                runs.append((start, i - start, val))
            start = None
    if start is not None and BANK_SIZE - start >= 4:
        runs.append((start, BANK_SIZE - start, val))

    print(f"\n  Found {len(runs)} runs, total {sum(r[1] for r in runs)} bytes:")
    for addr, length, filler in sorted(runs, key=lambda x: -x[1]):
        # Show context: bytes before and after
        before = ' '.join(f'{d[max(0,addr-4)+j]:02X}' for j in range(4)) if addr >= 4 else "????"
        after_start = addr + length
        after = ' '.join(f'{d[after_start+j]:02X}' for j in range(min(4, BANK_SIZE - after_start)))
        print(f"    0x{addr:04X}: {length:3d} × 0x{filler:02X}  "
              f"[before: {before}] [after: {after}]")

    # === ALSO CHECK: what does the game use for bank switching? ===
    print(f"\n{'=' * 80}")
    print("BANK SWITCHING PATTERNS IN BANK 0x00")
    print("=" * 80)
    
    # Look for writes to $2000-$3FFF (ROM bank register)
    # Common patterns: EA 00 20 (ld ($2000),a), EA 00 30, etc.
    bank_writes = []
    for i in range(BANK_SIZE - 2):
        if d[i] == 0xEA:  # ld (nn),a
            addr16 = d[i+1] | (d[i+2] << 8)
            if 0x2000 <= addr16 <= 0x3FFF:
                bank_writes.append((i, addr16))
        elif d[i] == 0xE0:  # ldh (n),a  — some games use FF00+n
            pass
    
    print(f"\n  Found {len(bank_writes)} bank switch writes (ld ($2000+),a):")
    for addr, target in bank_writes[:15]:
        # Show surrounding context
        ctx_start = max(0, addr - 6)
        ctx = ' '.join(f'{d[ctx_start+j]:02X}' for j in range(min(15, BANK_SIZE - ctx_start)))
        print(f"    0x{addr:04X}: ld (0x{target:04X}),a    context: {ctx}")

    # === CHECK: is there a bank restore / bank stack mechanism? ===
    print(f"\n{'=' * 80}")
    print("BANK MANAGEMENT: looking for bank save/restore patterns")
    print("=" * 80)
    
    # Look for a "current bank" variable - common pattern:
    # ld a, BANK_NUM / ld (bank_var),a / ld ($2000),a
    # Often the bank var is in HRAM (FF00-FFFE) or WRAM (C000-DFFF)
    
    # Search for patterns like: 3E xx EA yy C9 EA 00 20
    # (ld a,n / ld (C9yy),a / ld ($2000),a)
    for i in range(BANK_SIZE - 8):
        if (d[i] == 0x3E and  # ld a, n
            d[i+2] == 0xEA and  # ld (nn),a 
            d[i+5] == 0xEA and d[i+6] == 0x00 and d[i+7] == 0x20):  # ld ($2000),a
            bank_num = d[i+1]
            var_addr = d[i+3] | (d[i+4] << 8)
            print(f"    0x{i:04X}: ld a,0x{bank_num:02X} / ld (0x{var_addr:04X}),a / ld ($2000),a")
            print(f"            → Bank variable likely at 0x{var_addr:04X}")

    # Also look for: FA yy C9 EA 00 20 (ld a,(C9yy) / ld ($2000),a)
    # This is "restore bank from variable"
    restore_patterns = []
    for i in range(BANK_SIZE - 5):
        if (d[i] == 0xFA and  # ld a,(nn)
            d[i+3] == 0xEA and d[i+4] == 0x00 and d[i+5] == 0x20):  # ld ($2000),a
            var_addr = d[i+1] | (d[i+2] << 8)
            restore_patterns.append((i, var_addr))
    
    if restore_patterns:
        print(f"\n  Bank restore patterns (ld a,(var) / ld ($2000),a):")
        for addr, var in restore_patterns[:10]:
            print(f"    0x{addr:04X}: restore from 0x{var:04X}")

    # === WRAM/HRAM USAGE CHECK ===
    print(f"\n{'=' * 80}")
    print("RECOMMENDED WRAM REGION FOR LOADER CODE")
    print("=" * 80)
    
    # Check what's at various WRAM addresses by looking for references
    # Good candidates: $CF00-$CF3F (high WRAM, often free in GBC games)
    print("""
  WRAM $CF00-$CF3F is a common safe region for runtime code.
  The cross-bank room loader needs 40 bytes at a fixed WRAM address.
  
  To verify $CF00 is safe, check in SameBoy debugger:
    1. Boot game, load save
    2. Check memory at $CF00-$CF2F
    3. If it's zeros/unchanged during gameplay, it's safe to use
  
  Alternative: use HRAM ($FF80-$FFFE) if available, or
  find the game's WRAM allocation by tracing initialization code.
""")

if __name__ == "__main__":
    main()
