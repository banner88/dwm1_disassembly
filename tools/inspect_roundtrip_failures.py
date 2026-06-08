"""Show what's actually different in failing roundtrips."""
import json
from pathlib import Path
from dwm.rom import ROM
from dwm.text import decode, encode

rom = ROM(Path("data/DWM-original.gbc"))
blobs = json.loads(Path("extracted/text_blobs.json").read_text())

for b in blobs:
    bank = int(b["bank"], 16)
    off  = int(b["offset"], 16)
    raw = rom.read(bank, off, b["length"])
    text, _ = decode(raw)
    re_enc = encode(text)
    if re_enc != raw:
        print(f"\n{b['flat']}  bank {b['bank']}:{b['offset']}  text: {text!r}")
        print(f"  original:  {raw.hex(' ')}")
        print(f"  re-encoded:{re_enc.hex(' ')}")
        if len(list(set(raw) ^ set(re_enc))) < 4:
            diff = [(i, a, c) for i, (a, c) in enumerate(zip(raw, re_enc)) if a != c]
            print(f"  diffs at positions: {diff}")
        if input("more? [enter/n] ") == "n":
            break
