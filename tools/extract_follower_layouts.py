#!/usr/bin/env python3
"""
extract_follower_layouts.py  -- DWM1 overworld follower (walking-sprite) layout extractor.

The overworld sprite engine (SaveScr_40cd @ $04:$40cd, GBC variant of ROM0 $0d91)
renders a character from a metasprite program:

  * a two-level pointer table selects a metasprite list by
    sprite-type ($ffc7) -> frame/direction ($ffc8),
  * each list is a run of 4-byte entries (dy, dx, tile_offset, attr) ending in $80,
  * final OAM tile  = tile_offset + [$ffc9]   (follower tile base = $20/$30/$40 per slot),
  * final OAM attr  = [$ffca] XOR attr        (X-flip = bit5 = $20).

A follower frame is a 2x2: four entries with tile_offset in 0..15. A *layout* is the
ordered set of six frames a sprite type cycles through:
    down-A, down-B, right-A, right-B, up-A, up-B    (left = right with a global X-flip).

This script scans the sprite banks ($05/$10/$11) for frame-pointer tables (six
consecutive pointers, each to a valid follower frame in the same bank), decodes each
layout, dedupes them, and classifies whether the down/up/side tile sets are disjoint
(non-sharing -> safe for distinct art) or overlap (sharing -> blob-only, art must
double-duty).

Output: extracted/follower_layouts.json
Validated anchors: Healer == sharing layout (up/right share tiles); DarkDrium == disjoint.
"""
import json, os, sys

ROM = os.path.join(os.path.dirname(__file__), "..", "data", "DWM-original.gbc")
OUT = os.path.join(os.path.dirname(__file__), "..", "extracted", "follower_layouts.json")
SPRITE_BANKS = (0x05, 0x10, 0x11)
FRAME_NAMES = ["down_A", "down_B", "right_A", "right_B", "up_A", "up_B"]


def load_rom():
    with open(ROM, "rb") as f:
        return f.read()


def fileoff(bank, addr):
    return bank * 0x4000 + (addr - 0x4000)


def read_frame(rom, bank, addr):
    """Decode a follower frame: exactly 4 entries (tile 0..15) + $80, else None."""
    o = fileoff(bank, addr)
    ents = []
    for i in range(8):
        if o + i * 4 + 3 >= len(rom):
            return None
        dy = rom[o + i * 4]
        if dy == 0x80:
            break
        dx, tile, attr = rom[o + i * 4 + 1], rom[o + i * 4 + 2], rom[o + i * 4 + 3]
        if tile > 0x0F:
            return None
        sdy = dy - 256 if dy >= 128 else dy
        sdx = dx - 256 if dx >= 128 else dx
        ents.append({"dy": sdy, "dx": sdx, "tile": tile, "xflip": bool(attr & 0x20)})
    if len(ents) != 4:
        return None
    return ents


def frame_positions(ents):
    """Return entries sorted into (TL, TR, BL, BR) by their dy/dx offsets."""
    s = sorted(ents, key=lambda e: (e["dy"], e["dx"]))
    return s  # top row first (smaller dy), then left col first (smaller dx)


def tiles_used(frames, idxs):
    out = set()
    for i in idxs:
        for e in frames[i]:
            out.add(e["tile"])
    return out


def find_layouts(rom):
    layouts = {}
    for bank in SPRITE_BANKS:
        base = bank * 0x4000
        for o in range(base, base + 0x4000 - 12):
            ptrs, frames, ok = [], [], True
            for k in range(6):
                addr = rom[o + k * 2] | (rom[o + k * 2 + 1] << 8)
                if addr < 0x4000 or addr > 0x7FFF:
                    ok = False
                    break
                fr = read_frame(rom, bank, addr)
                if fr is None:
                    ok = False
                    break
                ptrs.append(addr)
                frames.append(fr)
            if not ok:
                continue
            # signature for dedupe: ordered (tile, xflip) per entry per frame (TL,TR,BL,BR)
            sig = tuple(
                tuple((e["tile"], e["xflip"]) for e in frame_positions(fr))
                for fr in frames
            )
            tbl_addr = 0x4000 + (o % 0x4000)
            layouts.setdefault(sig, {"frames": frames, "tables": []})
            layouts[sig]["tables"].append({"bank": bank, "addr": tbl_addr})
    return layouts


def classify(frames):
    down = tiles_used(frames, [0, 1])
    right = tiles_used(frames, [2, 3])
    up = tiles_used(frames, [4, 5])
    sharing = bool((up & right) or (up & down) or (down & right))
    return {
        "down_tiles": sorted(down),
        "right_tiles": sorted(right),
        "up_tiles": sorted(up),
        "sharing": sharing,
        "tile_count": len(down | right | up),
    }


def main():
    rom = load_rom()
    layouts = find_layouts(rom)
    records = []
    for i, (sig, data) in enumerate(
        sorted(layouts.items(), key=lambda kv: -len(kv[1]["tables"]))
    ):
        frames = data["frames"]
        rec = {
            "id": i,
            "used_by_tables": len(data["tables"]),
            "example_table": data["tables"][0],
            "classification": classify(frames),
            "frames": {
                FRAME_NAMES[j]: [
                    {
                        "pos": p,
                        "tile": e["tile"],
                        "xflip": e["xflip"],
                    }
                    for p, e in zip(
                        ["TL", "TR", "BL", "BR"], frame_positions(frames[j])
                    )
                ]
                for j in range(6)
            },
        }
        records.append(rec)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        json.dump({"layout_count": len(records), "layouts": records}, f, indent=1)
    n_share = sum(1 for r in records if r["classification"]["sharing"])
    print(f"extracted {len(records)} follower layouts -> {os.path.relpath(OUT)}")
    print(f"  sharing (blob-only): {n_share}   non-sharing (safe for distinct art): {len(records) - n_share}")
    print(f"  most common layout used by {records[0]['used_by_tables']} sprite tables")


if __name__ == "__main__":
    main()
