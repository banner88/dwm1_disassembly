"""Search the ROM for byte sequences that encode given text.
Bypasses scan_text — finds occurrences regardless of terminator or filters.
"""
import sys
from pathlib import Path
from dwm.rom import ROM, BANK_SIZE
from dwm.text import REVERSE_SINGLE, REVERSE_MULTI

def encode_loose(text: str) -> bytes:
    """Encode literally byte-by-byte. Returns None on unencodable char."""
    out = bytearray()
    i = 0
    while i < len(text):
        if text[i] == "{":
            end = text.index("}", i)
            out.append(int(text[i+1:end], 16))
            i = end + 1
            continue
        if i + 1 < len(text) and text[i:i+2] in REVERSE_MULTI:
            out.append(REVERSE_MULTI[text[i:i+2]])
            i += 2
            continue
        if text[i] in REVERSE_SINGLE:
            out.append(REVERSE_SINGLE[text[i]])
            i += 1
        else:
            return None
    return bytes(out)


def hex_view(data: bytes, hl_start: int, hl_len: int) -> str:
    """Render hex with highlighted region."""
    parts = []
    for i, b in enumerate(data):
        if hl_start <= i < hl_start + hl_len:
            parts.append(f"\033[1;31m{b:02X}\033[0m")
        else:
            parts.append(f"{b:02X}")
    return " ".join(parts)


def main():
    if len(sys.argv) < 2:
        print('Usage: search_bytes.py "text to find" [more...]')
        print('       Use {XX} for raw bytes, e.g. "Mom{B6}Dad"')
        sys.exit(1)

    data = ROM(Path("data/DWM-original.gbc")).data

    for needle_text in sys.argv[1:]:
        needle = encode_loose(needle_text)
        if needle is None:
            print(f"Could not encode: {needle_text!r}")
            continue

        print(f"\n=== Searching for {needle_text!r} ({len(needle)} bytes: {needle.hex(' ')})")
        hits = []
        i = 0
        while True:
            idx = data.find(needle, i)
            if idx < 0: break
            hits.append(idx)
            i = idx + 1

        print(f"Found {len(hits)} occurrence(s)")
        for flat in hits[:20]:
            bank = flat // BANK_SIZE
            local = (flat % BANK_SIZE) + (0 if bank == 0 else 0x4000)
            ctx_start = max(0, flat - 16)
            ctx_end = min(len(data), flat + len(needle) + 24)
            ctx = data[ctx_start:ctx_end]
            print(f"\n  0x{flat:06X}  bank {bank:02X}:{local:04X}")
            print(f"    {hex_view(ctx, flat - ctx_start, len(needle))}")


if __name__ == "__main__":
    main()
