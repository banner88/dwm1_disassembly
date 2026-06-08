"""Compare original vs hacked ROM at a specific text location.
Run after any edit to confirm it actually made it into the ROM file."""
import sys
from pathlib import Path
from dwm.rom import ROM, BANK_SIZE
from dwm.text import decode


def main():
    if len(sys.argv) < 2:
        print("Usage: verify_edit.py BB:OOOO   e.g.  verify_edit.py 42:4142")
        sys.exit(1)

    bank_s, off_s = sys.argv[1].split(":")
    bank, off = int(bank_s, 16), int(off_s, 16)
    flat = bank * BANK_SIZE + (off - 0x4000 if bank else off)

    orig = Path("data/DWM-original.gbc").read_bytes()
    hack = Path("data/DWM-hacked.gbc").read_bytes()

    def read_to_term(data, start, max_len=1024):
        end = start
        while end < len(data) and end - start < max_len and data[end] != 0xF0:
            end += 1
        return data[start:end + 1]

    ob = read_to_term(orig, flat)
    hb = read_to_term(hack, flat)

    print(f"Location: {sys.argv[1]} (flat 0x{flat:06X})")
    print(f"Diff bytes: {sum(1 for a,b in zip(ob, hb) if a != b)} / {len(ob)}")
    print(f"\nOriginal ({len(ob)}B):")
    print(f"  {decode(bytes(ob))[0][:200]}")
    print(f"\nHacked ({len(hb)}B):")
    print(f"  {decode(bytes(hb))[0][:200]}")

if __name__ == "__main__":
    main()
