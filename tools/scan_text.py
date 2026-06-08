"""Walk backward from each 0xF0 terminator, stopping at non-text bytes.

This finds inline cutscene strings embedded between assembly code, which
v1/v2 missed because they assumed string starts are also marked by 0xF0.
"""
import json
from pathlib import Path
from collections import Counter
from dwm.rom import ROM, BANK_SIZE
from dwm.text import TABLE, END_OF_STRING, decode

# Tight set: only bytes we've actually observed inside real dialogue.
# Excludes 0x80-0xC7 (LD/CALL/JP region) so we stop at code boundaries.
KNOWN_CONTROLS: set[int] = (
    {0x9F, 0xA3, 0xB6}
    | set(range(0xE8, 0xF0))    # 0xE8-0xEF
    | set(range(0xF1, 0xFF))    # 0xF1-0xFE
)

MIN_LEN          = 5
MIN_LETTERS      = 4
MIN_LETTER_RATIO = 0.30

def is_text_byte(b: int) -> bool:
    return b in TABLE or b in KNOWN_CONTROLS

def is_letter_or_digit(b: int) -> bool:
    return (0x00 <= b <= 0x09) or (0x24 <= b <= 0x57)

def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    data = rom.data

    results = []
    last_end = -1

    for term in range(len(data)):
        if data[term] != END_OF_STRING:
            continue

        # Walk backward as long as bytes are text or known control
        start = term
        while start > 0 and is_text_byte(data[start - 1]):
            start -= 1

        # Skip if overlaps with the previous accepted string
        if start <= last_end:
            continue

        length = term - start
        if length < MIN_LEN:
            continue

        letters = sum(1 for b in data[start:term] if is_letter_or_digit(b))
        if letters < MIN_LETTERS:
            continue
        if letters / length < MIN_LETTER_RATIO:
            continue

        try:
            text, _ = decode(bytes(data[start:term]) + bytes([END_OF_STRING]))
        except Exception:
            continue

        bank = start // BANK_SIZE
        local = (start % BANK_SIZE) + (0 if bank == 0 else 0x4000)
        results.append({
            "flat":    f"0x{start:06X}",
            "bank":    f"{bank:02X}",
            "offset":  f"{local:04X}",
            "length":  length + 1,
            "letters": letters,
            "text":    text,
        })
        last_end = term

    Path("extracted/text_blobs.json").write_text(json.dumps(results, indent=2))
    print(f"Found {len(results)} text blobs (v3)")

    by_bank = Counter(r["bank"] for r in results)
    print("\nTop 20 banks by string count:")
    for bank, n in sorted(by_bank.items(), key=lambda x: -x[1])[:20]:
        print(f"  Bank {bank}: {n} strings")

    # Specific sanity check: bedroom dialogue should now be found
    bedroom = [r for r in results
               if int(r["flat"], 16) <= 0x108150
               and int(r["flat"], 16) + r["length"] >= 0x108200]
    if bedroom:
        print(f"\n✓ Bedroom dialogue captured at {bedroom[0]['bank']}:{bedroom[0]['offset']}"
              f" (length {bedroom[0]['length']}B)")
        print(f"  '{bedroom[0]['text'][:80]}...'")
    else:
        print("\n✗ Bedroom dialogue STILL missing. Inspect tighter.")


if __name__ == "__main__":
    main()
