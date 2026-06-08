"""Dump all 256 monster names by following the pointer table at 41:4339."""
import json
from pathlib import Path
from dwm.rom import ROM
from dwm.text import decode

rom = ROM(Path("data/DWM-original.gbc"))
NAME_PTR_TABLE_BANK = 0x41
NAME_PTR_TABLE_OFFSET = 0x4339  # 256 × 2 bytes of little-endian pointers within bank 41

results = []
for i in range(256):
    # Read 2-byte pointer
    ptr_bytes = rom.read(NAME_PTR_TABLE_BANK, NAME_PTR_TABLE_OFFSET + i * 2, 2)
    ptr = ptr_bytes[0] | (ptr_bytes[1] << 8)
    if ptr < 0x4000 or ptr > 0x7FFF:
        continue  # invalid pointer = unused slot
    raw = rom.read_until(NAME_PTR_TABLE_BANK, ptr, 0xF0)
    name, _ = decode(raw)
    results.append({
        "id": i,
        "name": name,
        "ptr_location": f"41:{NAME_PTR_TABLE_OFFSET + i*2:04X}",
        "name_offset":  f"41:{ptr:04X}",
        "byte_length":  len(raw),  # includes terminator
    })

out = Path("extracted/monster_names.json")
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(results, indent=2))
print(f"Dumped {len(results)} names to {out}")
for r in results[:20]:
    print(f"  {r['id']:3d}  {r['name']:<12s}  @ {r['name_offset']}")
