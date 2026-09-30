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
  --selftest        assert decode->encode of all 10 vanilla icons == ROM bytes, that
                    patches/bank_04f.asm keeps the vanilla ??? glyph at $41A0 (the
                    full INCBIN), and that the Spirit design in
                    extracted/family_icons.json encodes to BOTH shipped copies: the
                    font glyph at $4F:$41B0 (text byte $1A — INFO page, library tab
                    strip, parent icons) and the bank $6D SpiritIconStream (gfx id
                    $6D04 — the HUD / list icon DMA; run marker absent from the data).
                    (S104: the B9 "$1A is not fill-immune" finding does not reproduce;
                    see KEY_LESSONS S104.)

Generator-stamped data deliverable: extracted/family_icons.json.

NOTE: this tool emits patch LINES (--png); it does not itself write
patches/bank_04f.asm / patches/bank_06d.asm (same-size 16-byte lines).
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
FREE_SLOT_ADDR = 0x41B0      # text byte $1A — the first font slot after the icons
SPIRIT_SLOT_ADDR = 0x41B0    # S104: the Spirit glyph ships HERE (byte $1A)
SPIRIT_MARKER = "$41B0 byte $1A = SPIRIT icon"  # stable token in the patch comment
STREAM_PATH = os.path.join(REPO, "patches", "bank_06d.asm")
STREAM_LABEL = "SpiritIconStream:"
NUM_VANILLA = 10             # icons $10..$19

# History: B9 (S28) shipped the whip on byte $19, overwriting the vanilla ???
# glyph, because $1A "rendered blank". S104 could not reproduce that: with the
# bank-$41 mode-4 Spirit string = "$1A" the glyph renders (PyBoy: INFO page,
# library tab strip). ??? is vanilla again.

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
                  "Byte->addr: $4010 + byte*16. The 11th family (Spirit) icon "
                  "ships on byte $1A = $41B0 (patches/bank_04f.asm) and as the "
                  "bank $6D SpiritIconStream (HUD copy, gfx id $6D04); the "
                  "vanilla ??? glyph at $41A0 is untouched (S104)."),
        "byte_to_addr_formula": "$4010 + textbyte*16",
        "bank": f"${ICON_BANK:02X}",
        "icons": icons,
        "free_slot": {"byte": "$1A", "addr": f"${FREE_SLOT_ADDR:04X}",
                      "vanilla_grid": free_grid},
        "spirit": spirit,
    }
    if spirit:
        spirit["byte"] = "$1A"
        spirit["addr"] = f"${SPIRIT_SLOT_ADDR:04X}"
    os.makedirs(os.path.dirname(JSON_PATH), exist_ok=True)
    json.dump(out, open(JSON_PATH, "w"), indent=1)
    print(f"wrote {JSON_PATH} ({NUM_VANILLA} icons + free slot"
          f"{' + spirit' if spirit else ''})")


def cmd_png(path, head_index):
    grid = png_to_grid(path, head_index)
    tile = encode_tile(grid)
    for row in grid:
        print("".join(" .:#"[v] if v != head_index else "*" for v in row))
    print("patches/bank_04f.asm:")
    print(db_line(tile, SPIRIT_MARKER))
    print("patches/bank_06d.asm SpiritIconStream (dw $0010, db marker, 16 bytes):")
    print(f"    db ${stream_marker(tile):02X}")
    print(db_line(tile, ""))


def stream_marker(tile):
    """The run marker of a raw 16-byte gfx stream: the smallest byte value the
    data does not contain (WaitDMATransfer treats the marker as a run start)."""
    return next(v for v in range(256) if v not in tile)


def parse_db(line):
    return bytes(int(tok.strip().lstrip("$"), 16)
                 for tok in line.split("db", 1)[1].split(";")[0].split(","))


def read_stream():
    """(length, marker, data) of SpiritIconStream in patches/bank_06d.asm."""
    lines = open(STREAM_PATH).read().split("\n")
    k = lines.index(STREAM_LABEL)
    body = [ln for ln in lines[k + 1:k + 6] if ln.strip().startswith(("dw", "db"))]
    length = int(body[0].split("dw", 1)[1].split(";")[0].strip().lstrip("$"), 16)
    return length, parse_db(body[1]), parse_db(body[2])


def cmd_selftest():
    rom = read_rom()
    # 1) every vanilla icon round-trips
    for i in range(NUM_VANILLA):
        off = flat(ICON_BANK, ICON_BASE) + i * 16
        b16 = rom[off:off + 16]
        assert encode_tile(decode_tile(b16)) == b16, f"icon {i} round-trip"
    # 2) the patch keeps the vanilla 10 icons (??? at $41A0 included)
    src = open(PATCH_PATH).read()
    assert 'INCBIN "gfx/image_04f_4110.2bpp"\t' in src and \
        'INCBIN "gfx/image_04f_4110.2bpp", 0' not in src, \
        "patches/bank_04f.asm must INCBIN all 10 vanilla icons (??? restored S104)"
    print("  vanilla ??? glyph at $41A0 kept (full INCBIN): OK")
    # 3) spirit design in json == the $41B0 glyph AND the bank $6D stream
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
            got = parse_db(line)
            assert got == want, ("spirit json grid != patch bytes\n"
                                 f" json={want.hex()} patch={got.hex()}")
            print(f"  spirit json grid == patch {SPIRIT_MARKER} bytes: OK")
            length, marker, data = read_stream()
            assert length == 16 and len(marker) == 1 and data == want, \
                f"SpiritIconStream != json grid (len {length}, data {data.hex()})"
            assert marker[0] not in data, "stream run marker occurs in the data"
            print("  spirit json grid == bank $6D SpiritIconStream (marker "
                  f"${marker[0]:02X} absent): OK")
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
