#!/usr/bin/env python3
"""build_family_icon.py — author/inspect DWM1 family ICON font tiles (B8/B9).

The family identity shown to the player (library tab strip + monster-detail
"<icon> family" line) is an 8x8 2bpp FONT TILE, not a text string. The 10 vanilla
icons live in bank $4F at $4110-$41A0 and are addressed by text bytes $10-$19 via
ComputeTileDataAddr ($00): tile_addr = $4010 + byte*16. The first free slot after
them is byte $1A -> $4F:$41B0 (blank filler), where an 11th-family (Spirit) icon
goes as a same-size 16-byte insert (zero shift).  See BREEDING_SYSTEM.md
"Family icons (B8/B9)".

This tool:
  --dump            decode the 10 vanilla icon tiles (+ the free $1A slot) from the
                    ROM and (re)write extracted/family_icons.json. Round-trip safe:
                    re-encoding the decoded grids reproduces the ROM bytes exactly.
  --png FILE        encode an 8x8 PNG (<=4 grey levels) to a 2bpp tile; prints the
                    16-byte `db` line for patches/bank_04f.asm. --head-index N sets
                    which palette index the brightest input pixels map to (default 0;
                    use 2 for the "safe mid-shade" fallback).
  --selftest        assert decode->encode of all 10 vanilla icons == ROM bytes, and
                    that the Spirit design in extracted/family_icons.json encodes to
                    the 16 bytes shipped in patches/bank_04f.asm at $41A0 (byte $19 —
                    the Spirit whip overwrites the vanilla ??? glyph; the free $1A
                    slot was abandoned because it is not fill-immune at runtime).

Generator-stamped data deliverable: extracted/family_icons.json.

NOTE: this tool emits a patch LINE; it does not itself write patches/bank_04f.asm
(that patch is a same-size copy of the clean bank with the $41B0 line replaced).
"""
import argparse, hashlib, json, os, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_PATH = os.path.join(REPO, "data", "DWM-original.gbc")
JSON_PATH = os.path.join(REPO, "extracted", "family_icons.json")
PATCH_PATH = os.path.join(REPO, "patches", "bank_04f.asm")
ORIGINAL_MD5 = "1ca6579359f21d8e27b446f865bf6b83"

ICON_BANK = 0x4F
ICON_BASE = 0x4110            # in-bank addr of icon 0 (text byte $10)
FONT_BASE = 0x4010           # ComputeTileDataAddr base: addr = $4010 + byte*16
FREE_SLOT_ADDR = 0x41B0      # text byte $1A — first free font slot (left blank)
SPIRIT_SLOT_ADDR = 0x41A0    # text byte $19 — where the Spirit whip ACTUALLY ships
SPIRIT_MARKER = "$41A0 byte $19"  # stable token in the patch comment
NUM_VANILLA = 10             # icons $10..$19

# NOTE (S-corruption-fix saga): the S20 plan put the Spirit icon on the free slot
# byte $1A ($41B0). That slot proved NOT fill-immune at runtime (the menu blanks it),
# so the shipped Spirit icon is the option-5 whip on byte $19 ($41A0), overwriting the
# vanilla ??? glyph — ??? and Spirit share the whip. The $1A slot is left blank.

# Visual labels, user-confirmed S20 (glyph order $10..$19; NOT family-code order):
ICON_LABELS = [
    "slime", "dragon face", "animal paw (Beast)", "feather (Bird)",
    "tree (Plant)", "insect head (Bug)", "hammer/axe", "black face (Zombie)",
    "red face (Material)", "? (??? / Boss)",
]


def flat(bank, local):
    return bank * 0x4000 + (local - 0x4000 if bank else local)


def read_rom():
    data = open(ROM_PATH, "rb").read()
    md5 = hashlib.md5(data).hexdigest()
    if md5 != ORIGINAL_MD5:
        sys.exit(f"ERROR: ROM md5 {md5} != original {ORIGINAL_MD5}")
    return data


def decode_tile(b16):
    """16 bytes 2bpp -> 8x8 grid of palette indices 0..3."""
    g = []
    for r in range(8):
        lo, hi = b16[r * 2], b16[r * 2 + 1]
        g.append([((lo >> (7 - c)) & 1) | (((hi >> (7 - c)) & 1) << 1)
                  for c in range(8)])
    return g


def encode_tile(grid):
    """8x8 grid of indices 0..3 -> 16 bytes 2bpp."""
    out = bytearray()
    for r in range(8):
        lo = hi = 0
        for c in range(8):
            v = grid[r][c] & 3
            lo = (lo << 1) | (v & 1)
            hi = (hi << 1) | ((v >> 1) & 1)
        out += bytes([lo, hi])
    return bytes(out)


def db_line(tile, comment):
    return ("    db " + ", ".join(f"${b:02X}" for b in tile) +
            ("\t; " + comment if comment else ""))


def png_to_grid(path, head_index):
    from PIL import Image
    im = Image.open(path).convert("RGB")
    W, H = im.size
    # Downsample/representative-sample to 8x8 by cell centres.
    cw, ch = W / 8.0, H / 8.0
    # Collect luminances, map to <=4 levels by rank so any greyscale art works.
    lums = []
    for ry in range(8):
        for cx in range(8):
            px = im.getpixel((int((cx + 0.5) * cw), int((ry + 0.5) * ch)))
            lums.append(sum(px) / 3.0)
    uniq = sorted(set(round(l) for l in lums))
    # Map luminance -> shade 0(bright)..3(dark). Brightest -> head_index.
    def shade(l):
        # nearest of the 4 canonical levels 255/170/85/0
        cand = [(255, "bright"), (170, "light"), (85, "mid"), (0, "dark")]
        name = min(cand, key=lambda c: abs(c[0] - l))[1]
        return {"bright": head_index, "light": 1, "mid": 2, "dark": 3}[name]
    grid = []
    k = 0
    for ry in range(8):
        row = []
        for cx in range(8):
            row.append(shade(lums[k])); k += 1
        grid.append(row)
    return grid


def cmd_dump():
    rom = read_rom()
    icons = []
    for i in range(NUM_VANILLA):
        off = flat(ICON_BANK, ICON_BASE) + i * 16
        b16 = rom[off:off + 16]
        grid = decode_tile(b16)
        assert encode_tile(grid) == b16, "round-trip mismatch"
        icons.append({
            "byte": f"${0x10 + i:02X}",
            "addr": f"${ICON_BASE + i*16:04X}",
            "label": ICON_LABELS[i],
            "grid": grid,
        })
    free_off = flat(ICON_BANK, FREE_SLOT_ADDR)
    free_grid = decode_tile(rom[free_off:free_off + 16])
    # Spirit design (if already present in an existing json) is preserved; else None.
    spirit = None
    if os.path.exists(JSON_PATH):
        try:
            spirit = json.load(open(JSON_PATH)).get("spirit")
        except Exception:
            spirit = None
    out = {
        "_generator": "tools/build_family_icon.py --dump",
        "_rom": "data/DWM-original.gbc",
        "_note": ("Family icons are font tiles at $4F:$4110+ (bytes $10-$19). "
                  "Byte->addr: $4010 + byte*16. Free 11th slot: byte $1A = $41B0."),
        "byte_to_addr_formula": "$4010 + textbyte*16",
        "bank": f"${ICON_BANK:02X}",
        "icons": icons,
        "free_slot": {"byte": "$1A", "addr": f"${FREE_SLOT_ADDR:04X}",
                      "vanilla_grid": free_grid},
        "spirit": spirit,
    }
    os.makedirs(os.path.dirname(JSON_PATH), exist_ok=True)
    json.dump(out, open(JSON_PATH, "w"), indent=1)
    print(f"wrote {JSON_PATH} ({NUM_VANILLA} icons + free slot"
          f"{' + spirit' if spirit else ''})")


def cmd_png(path, head_index):
    grid = png_to_grid(path, head_index)
    tile = encode_tile(grid)
    for row in grid:
        print("".join(" .:#"[v] if v != head_index else "*" for v in row))
    print(db_line(tile, f"$41B0 byte $1A = family icon (head idx {head_index})"))


def cmd_selftest():
    rom = read_rom()
    # 1) every vanilla icon round-trips
    for i in range(NUM_VANILLA):
        off = flat(ICON_BANK, ICON_BASE) + i * 16
        b16 = rom[off:off + 16]
        assert encode_tile(decode_tile(b16)) == b16, f"icon {i} round-trip"
    # 2) spirit design in json encodes to the bytes in patches/bank_04f.asm @ $41A0
    #    (byte $19 — the shipped Spirit slot; $1A was abandoned, see header note)
    if os.path.exists(JSON_PATH) and os.path.exists(PATCH_PATH):
        j = json.load(open(JSON_PATH))
        sp = j.get("spirit")
        if sp and sp.get("grid"):
            want = encode_tile(sp["grid"])
            # find the $41A0/$19 SPIRIT db line in the patch
            line = None
            for ln in open(PATCH_PATH):
                if SPIRIT_MARKER in ln and ln.strip().startswith("db"):
                    line = ln; break
            assert line, f"no {SPIRIT_MARKER} SPIRIT db line in patches/bank_04f.asm"
            got = bytes(int(tok.strip().lstrip("$"), 16)
                        for tok in line.split("db", 1)[1].split(";")[0].split(","))
            assert got == want, ("spirit json grid != patch bytes\n"
                                 f" json={want.hex()} patch={got.hex()}")
            print(f"  spirit json grid == patch {SPIRIT_MARKER} bytes: OK")
    print("SELFTEST: PASS")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dump", action="store_true")
    ap.add_argument("--png")
    ap.add_argument("--head-index", type=int, default=0)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.dump:
        cmd_dump()
    elif a.png:
        cmd_png(a.png, a.head_index)
    elif a.selftest:
        cmd_selftest()
    else:
        ap.print_help()


if __name__ == "__main__":
    main()
