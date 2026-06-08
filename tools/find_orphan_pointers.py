"""Find pointer references to orphan strings, more aggressively.

For each orphan, scan ALL banks for the 2-byte LE address. Classify hits by
the preceding byte:
  - 0x21 / 0x11 / 0x01  : confident (LD HL/DE/BC)
  - other bytes         : raw pointers (likely script bytecode or table entries)

Also builds a histogram of the preceding bytes — if a non-LD byte dominates,
that's almost certainly the script opcode for 'print string'.
"""
import json
from pathlib import Path
from collections import defaultdict
from dwm.rom import ROM, BANK_SIZE


def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    data = rom.data
    blobs = json.loads(Path("extracted/text_blobs.json").read_text())
    tables = json.loads(Path("extracted/pointer_tables.json").read_text())

    tabled_targets = set()
    for t in tables:
        bank = int(t["bank"], 16)
        tbl_local = int(t["offset"], 16)
        tbl_flat_base = bank * BANK_SIZE + (tbl_local - 0x4000 if bank else tbl_local)
        for k in range(t["entries"]):
            f = tbl_flat_base + k * 2
            ptr = data[f] | (data[f + 1] << 8)
            tabled_targets.add((bank, ptr))

    orphan_blobs = [b for b in blobs
                    if (int(b["bank"], 16), int(b["offset"], 16)) not in tabled_targets]

    found_confident = {}      # orphans with at least one LD HL/DE/BC hit
    found_uncertain = {}      # orphans with only raw-pointer hits
    prefix_histogram = defaultdict(int)

    n = len(orphan_blobs)
    for idx, b in enumerate(orphan_blobs):
        if idx % 100 == 0:
            print(f"  scanning {idx}/{n}...", end="\r")
        bank = int(b["bank"], 16)
        off = int(b["offset"], 16)
        lo, hi = off & 0xFF, (off >> 8) & 0xFF

        ld_hits = []
        raw_hits = []

        for i in range(1, len(data) - 1):
            if data[i] != lo or data[i + 1] != hi:
                continue
            prev = data[i - 1]
            prefix_histogram[prev] += 1

            bank_loc = (i - 1) // BANK_SIZE
            local_off = ((i - 1) % BANK_SIZE) + (0 if bank_loc == 0 else 0x4000)

            entry = {
                "operand_at": f"{bank_loc:02X}:{(local_off + 1):04X}",
                "preceded_by": f"0x{prev:02X}",
            }
            if prev in (0x21, 0x11, 0x01):
                entry["register"] = {0x21: "HL", 0x11: "DE", 0x01: "BC"}[prev]
                ld_hits.append(entry)
            else:
                raw_hits.append(entry)

        key = f"{bank:02X}:{off:04X}"
        if ld_hits:
            found_confident[key] = {
                "confident": ld_hits[:5],
                "uncertain": raw_hits[:10],
            }
        elif raw_hits:
            found_uncertain[key] = raw_hits[:10]

    print(" " * 60, end="\r")

    out = Path("extracted/orphan_pointers.json")
    out.write_text(json.dumps({
        "confident": found_confident,
        "uncertain": found_uncertain,
        "prefix_histogram": {f"0x{k:02X}": v for k, v in
                             sorted(prefix_histogram.items(), key=lambda x: -x[1])[:30]},
    }, indent=2))

    total = len(orphan_blobs)
    n_conf = len(found_confident)
    n_unc = len(found_uncertain)
    n_none = total - n_conf - n_unc

    print(f"Total orphans:           {total}")
    print(f"  ✓ confident pointer:   {n_conf}  ({n_conf/total*100:.1f}%)")
    print(f"  ? raw-pointer only:    {n_unc}  ({n_unc/total*100:.1f}%)")
    print(f"  ✗ no pointer found:    {n_none}  ({n_none/total*100:.1f}%)\n")

    print("Top 15 preceding-byte values (histogram):")
    print("  byte  count  meaning if known")
    for byte_str, count in list({k: v for k, v in sorted(
            prefix_histogram.items(), key=lambda x: -x[1])}.items())[:15]:
        b = byte_str
        guess = ""
        if b == 0x21: guess = "LD HL,nnnn (confirmed)"
        elif b == 0x11: guess = "LD DE,nnnn"
        elif b == 0x01: guess = "LD BC,nnnn"
        elif b == 0xCD: guess = "CALL nnnn"
        elif b == 0xC3: guess = "JP nnnn"
        elif b == 0xC2: guess = "JP NZ"
        elif b == 0xCA: guess = "JP Z"
        elif b == 0xD2: guess = "JP NC"
        elif b == 0xDA: guess = "JP C"
        print(f"  0x{b:02X}  {count:5d}  {guess}")

    print(f"\nBedroom dialogue:")
    bk = "42:4142"
    if bk in found_confident:
        print(f"  ✓ Confident: {found_confident[bk]['confident']}")
    elif bk in found_uncertain:
        print(f"  ? Uncertain candidates: {len(found_uncertain[bk])} raw hits")
        for c in found_uncertain[bk][:5]:
            print(f"     {c}")
    else:
        print(f"  ✗ No candidates found")


if __name__ == "__main__":
    main()
