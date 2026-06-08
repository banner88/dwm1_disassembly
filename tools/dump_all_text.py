"""Group every discovered string into pointer-table-aware records.
Output is the canonical 'source of truth' for text editing."""
import json
from pathlib import Path
from dwm.rom import ROM, BANK_SIZE

OUT = Path("extracted/all_text.json")

def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    blobs = json.loads(Path("extracted/text_blobs.json").read_text())
    tables = json.loads(Path("extracted/pointer_tables.json").read_text())

    # index blobs for fast lookup
    blob_by_loc = {(int(b["bank"], 16), int(b["offset"], 16)): b for b in blobs}

    catalog = {"tables": [], "orphans": []}
    referenced: set[tuple[int, int]] = set()

    # Pass 1: every entry in every pointer table → catalog record
    for t in tables:
        bank = int(t["bank"], 16)
        table_off = int(t["offset"], 16)
        entries = []
        for k in range(t["entries"]):
            flat = bank * BANK_SIZE + (table_off - 0x4000 if bank else table_off) + k * 2
            ptr = rom.data[flat] | (rom.data[flat + 1] << 8)
            blob = blob_by_loc.get((bank, ptr))
            entries.append({
                "index": k,
                "ptr_location": f"{t['bank']}:{table_off + k*2:04X}",
                "target_offset": f"{t['bank']}:{ptr:04X}",
                "text": blob["text"] if blob else None,
                "length": blob["length"] if blob else None,
            })
            if blob:
                referenced.add((bank, ptr))
        catalog["tables"].append({
            "label": f"unknown_{t['bank']}_{t['offset']}",   # human-rename later
            "bank": t["bank"],
            "table_offset": t["offset"],
            "count": t["entries"],
            "entries": entries,
        })

    # Pass 2: blobs not referenced by any table — orphans (probably inline text in code)
    for b in blobs:
        loc = (int(b["bank"], 16), int(b["offset"], 16))
        if loc not in referenced:
            catalog["orphans"].append(b)

    OUT.write_text(json.dumps(catalog, indent=2))
    print(f"Tables: {len(catalog['tables'])}, "
          f"referenced strings: {len(referenced)}, "
          f"orphan strings: {len(catalog['orphans'])}")

if __name__ == "__main__":
    main()
