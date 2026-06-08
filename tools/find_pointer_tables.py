"""Find sequences of contiguous bank-local pointers all pointing to known
text blobs in the SAME bank. Handles odd-aligned tables."""
import json
from pathlib import Path
from collections import defaultdict
from dwm.rom import ROM, BANK_SIZE

MIN_TABLE_LEN = 8


def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    blobs = json.loads(Path("extracted/text_blobs.json").read_text())

    blob_offsets: dict[int, set[int]] = defaultdict(set)
    for b in blobs:
        blob_offsets[int(b["bank"], 16)].add(int(b["offset"], 16))

    print(f"bank 0x41 has {len(blob_offsets[0x41])} unique blob offsets; "
          f"includes 0x5B1F? {0x5B1F in blob_offsets[0x41]}")

    tables = []
    num_banks = len(rom.data) // BANK_SIZE
    for bank in range(num_banks):
        valid = blob_offsets.get(bank, set())
        if not valid:
            continue
        bank_base = bank * BANK_SIZE
        local_base = 0 if bank == 0 else 0x4000

        off = 0
        run_start, run_len = None, 0
        while off < BANK_SIZE - 1:
            flat = bank_base + off
            ptr = rom.data[flat] | (rom.data[flat + 1] << 8)
            if ptr in valid:
                if run_start is None:
                    run_start = off
                run_len += 1
                off += 2                          # step to next pointer entry
            else:
                if run_len >= MIN_TABLE_LEN:
                    tables.append({
                        "bank":    f"{bank:02X}",
                        "offset":  f"{run_start + local_base:04X}",
                        "entries": run_len,
                        "first_target": None,     # filled in below
                    })
                run_start, run_len = None, 0
                off += 1                          # try other alignment

        if run_len >= MIN_TABLE_LEN:
            tables.append({
                "bank":    f"{bank:02X}",
                "offset":  f"{run_start + local_base:04X}",
                "entries": run_len,
                "first_target": None,
            })



    # Annotate each table with samples spread across the entries.
    blob_by_loc = {(int(b["bank"], 16), int(b["offset"], 16)): b["text"] for b in blobs}
    for t in tables:
        bank = int(t["bank"], 16)
        off  = int(t["offset"], 16)
        n    = t["entries"]
        # Sample at positions: 0, 1, 2, n/2, n-1 (deduped, preserves order)
        positions = sorted(set([0, 1, 2, n // 2, n - 1]))
        samples = []
        for k in positions:
            flat = bank * BANK_SIZE + (off - 0x4000 if bank else off) + k * 2
            ptr  = rom.data[flat] | (rom.data[flat + 1] << 8)
            txt  = blob_by_loc.get((bank, ptr), f"?@{ptr:04X}")
            samples.append((k, txt[:40]))
        t["samples"] = samples

    Path("extracted/pointer_tables.json").write_text(json.dumps(tables, indent=2))
    print(f"\nFound {len(tables)} candidate pointer tables\n")
    #for t in sorted(tables, key=lambda x: -x["entries"])[:20]:
    #    print(f"  Bank {t['bank']} @ {t['offset']}: {t['entries']:4d} entries  "
    #          f"→ {t['first_target']}")
    for t in sorted(tables, key=lambda x: -x["entries"])[:20]:
        print(f"\n  Bank {t['bank']} @ {t['offset']}: {t['entries']} entries")
        for pos, txt in t["samples"]:
            print(f"     [{pos:>3}] {txt}")


if __name__ == "__main__":
    main()
