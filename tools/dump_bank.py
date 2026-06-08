"""Show every string in a given bank, sorted by offset. Useful for spotting
contiguous dialogue regions."""
import sys
import json
from pathlib import Path

if len(sys.argv) < 2:
    print("Usage: dump_bank.py <bank_hex>   e.g.  dump_bank.py 4A")
    sys.exit(1)
bank_hex = sys.argv[1].upper().zfill(2)

blobs = json.loads(Path("extracted/text_blobs.json").read_text())
hits = sorted(
    [b for b in blobs if b["bank"] == bank_hex],
    key=lambda b: int(b["offset"], 16),
)
print(f"{len(hits)} strings in bank {bank_hex}\n")
for b in hits:
    txt = b["text"]
    print(f"  {b['offset']}  len={b['length']:3d}  {txt!r}")
