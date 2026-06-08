"""Find runs of identical filler bytes (0xFF or 0x00) - usable as free space."""
import json
from pathlib import Path
from dwm.rom import ROM, BANK_SIZE

MIN_RUN = 4  # minimum useful chunk

def find_runs(data: bytes, val: int, min_len: int):
    runs = []
    start = None
    for i, b in enumerate(data):
        if b == val:
            if start is None: start = i
        else:
            if start is not None and i - start >= min_len:
                runs.append((start, i - start))
            start = None
    if start is not None and len(data) - start >= min_len:
        runs.append((start, len(data) - start))
    return runs

def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    summary = {}
    for filler in (0xFF, 0x00):
        runs = find_runs(rom.data, filler, MIN_RUN)
        for start, length in runs:
            bank = start // BANK_SIZE
            local = (start % BANK_SIZE) + (0 if bank == 0 else 0x4000)
            summary.setdefault(f"{bank:02X}", []).append({
                "flat": f"0x{start:06X}",
                "bank_local_offset": f"{local:04X}",
                "length": length,
                "filler": f"0x{filler:02X}",
            })

    Path("extracted/free_space.json").write_text(json.dumps(summary, indent=2))
    total = sum(r["length"] for runs in summary.values() for r in runs)
    print(f"Total free bytes (runs >= {MIN_RUN}): {total}")
    for bank in sorted(summary):
        regions = summary[bank]
        total = sum(r["length"] for r in regions)
        print(f"  Bank {bank}: {total:5d} bytes across {len(regions)} regions  "
              f"(biggest: {max(r['length'] for r in regions)})")

if __name__ == "__main__":
    main()
