#!/usr/bin/env python3
"""dump_flying_flags.py — export every species' "can fly" flag to JSON. [S74]

The flying flag is monster-info byte +$04 (table $03:$4461, 221 records x 43
bytes). In battle, init (bank $51) packs (fly<<4)|metal into $db8b[slot] for
all 8 combatants; it gates LegSweep ($4E) and the custom Earthquake tiers
($E5-$E8), which skip flying combatants entirely.

Output: extracted/flying_flags.json —
  {
    "_generator": "...",
    "flag_location": "monster info +$04 ($03:$4461 + species*43 + 4)",
    "species": [ {"id", "name", "can_fly", "rom_offset"} ... ],
    "flying_species": [names...]           (the quick-read list)
  }
`rom_offset` is the ABSOLUTE file offset of that species' flying byte in the
ROM image, so an editor (or a hex editor) can read/write the stat directly:
0 = grounded, 1 = flying. Rebuilding from source instead: the byte lives in
disassembly/bank_003.asm's info table (+$04 of each 43-byte record).

Usage: python3 tools/dump_flying_flags.py [rom] [out.json]
"""
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO, "data", "DWM-original.gbc")
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(REPO, "extracted", "flying_flags.json")

INFO_BASE = 0x03 * 0x4000 + (0x4461 - 0x4000)   # file offset of species 0
REC = 43
FLY_OFF = 0x04
N_SPECIES = 221

def main():
    rom = open(ROM, "rb").read()
    names = {m["id"]: m["name"]
             for m in json.load(open(os.path.join(REPO, "extracted", "monsters_full.json")))}
    species = []
    for sp in range(N_SPECIES):
        off = INFO_BASE + sp * REC + FLY_OFF
        fly = rom[off]
        species.append({
            "id": sp,
            "name": names.get(sp, f"species_{sp}"),
            "can_fly": bool(fly),
            "rom_offset": f"0x{off:06X}",
        })
    out = {
        "_generator": "tools/dump_flying_flags.py (S74); rom=%s" % os.path.basename(ROM),
        "flag_location": "monster info +$04 ($03:$4461 + species*43 + 4); "
                         "battle copy = $db8b[slot] bit4 (packed by bank $51 init); "
                         "gates LegSweep ($4E) and Earthquake ($E5-$E8)",
        "edit_note": "0 = grounded, 1 = flying. Patch rom_offset directly, or edit "
                     "the +$04 byte of the species' record in bank_003.asm and rebuild.",
        "count_flying": sum(1 for s in species if s["can_fly"]),
        "species": species,
        "flying_species": [s["name"] for s in species if s["can_fly"]],
    }
    json.dump(out, open(OUT, "w"), indent=1)
    print("wrote %s: %d species, %d flying" % (OUT, len(species), out["count_flying"]))
    print("flying:", ", ".join(out["flying_species"]))

if __name__ == "__main__":
    main()
