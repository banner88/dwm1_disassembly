"""Show the decoded string that contains a given flat ROM offset."""
import sys
from pathlib import Path
from dwm.rom import ROM, BANK_SIZE
from dwm.text import TABLE

def main():
    if len(sys.argv) < 2:
        print("Usage: view_string.py <flat_offset_hex>")
        print("       e.g.  view_string.py 0x108190")
        sys.exit(1)

    flat = int(sys.argv[1], 16)
    data = ROM(Path("data/DWM-original.gbc")).data

    # Walk backward to previous 0xF0
    start = flat
    while start > 0 and data[start - 1] != 0xF0:
        start -= 1

    # Walk forward to next 0xF0
    end = flat
    while end < len(data) and data[end] != 0xF0:
        end += 1
    end_incl = end + 1

    bank = start // BANK_SIZE
    local = (start % BANK_SIZE) + (0 if bank == 0 else 0x4000)

    print(f"String: {bank:02X}:{local:04X} .. flat 0x{start:06X}-0x{end_incl-1:06X}")
    print(f"Length: {end_incl - start} bytes (incl terminator)")
    print(f"Letters: {sum(1 for b in data[start:end] if 0x24 <= b <= 0x57)}")

    parts = []
    for b in data[start:end]:
        parts.append(TABLE.get(b, f"{{{b:02X}}}"))
    print(f"\nDecoded:\n{''.join(parts)}")

    print(f"\nRaw hex:")
    for i in range(0, end_incl - start, 32):
        chunk = data[start + i:start + i + 32]
        print(f"  {start + i:06X}  {chunk.hex(' ')}")

if __name__ == "__main__":
    main()
