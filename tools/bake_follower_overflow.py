#!/usr/bin/env python3
"""
bake_follower_overflow.py -- emit a sprite-overflow bank ($7E..) as a STATIC patch
file (patches/bank_0XX.asm) from one or more follower art sources.

This is the "data" half of the new-species follower bake: the FORKS (resolvers,
clamp, layout, attr) are hand-authored static patches (the fixed infrastructure);
the ART PAYLOAD that those forks point at is generated here so it stays
reproducible. PNG-agnostic: swap the art source and re-run, the forks don't change.

Each art source is packed for layout 0, encoded as a literal LZ stream, and placed
in the overflow bank by the shared allocator (dwm/sprite_bank.py). The gfx-ID handed
back (bank<<8 | index) is what the resolver tables must hold; this tool prints it.

ORIENTATION RULE (KEY_LESSONS.md / MONSTER_DATA.md):
  Follower art is stored UN-FLIPPED. The renderer's OAM builder (SaveScr_40cd) does
  `attr = [$ffca] XOR entry_attr`; orientation is governed by the per-species attr
  byte (base [$ffca]) and the layout's per-tile entry_attr -- NOT by pre-flipping
  the tile data. New species get a CLEAN attr (no flip bits) via the forked attr
  read (NewAttrHandler @ $11:$792d), so un-flipped art renders upright. Pre-flipping
  the payload is the documented ANTI-PATTERN: it only cancels the symptom of a
  garbage/flip attr and silently couples art orientation to that byte. There is
  deliberately NO --flip-y option here -- if a sprite renders upside-down, fix the
  ATTR (NewFollowerAttrTable / the attr fork), never the art.

Usage:
  python3 tools/bake_follower_overflow.py \
      --art examples/follower_swap/W_bluedragon.png \
      --frames examples/follower_swap/bluedragon_frames.json \
      --label Follower_sp224 --out patches/bank_07e.asm

  # or feed a pre-packed 256 B layout-0 payload directly:
  python3 tools/bake_follower_overflow.py \
      --payload examples/follower_swap/bluedragon_payload.bin \
      --label Follower_sp224 --out patches/bank_07e.asm
"""
import argparse, json, os, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
sys.path.insert(0, os.path.join(REPO, "tools"))
from dwm import sprite_bank as sb, sprite_codec as sc
import importlib.util
_spec = importlib.util.spec_from_file_location(
    "bfr", os.path.join(REPO, "tools", "build_follower_reassign.py"))
bfr = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(bfr)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--art", help="follower sprite-sheet PNG")
    ap.add_argument("--frames", help="frames-json (DOWN/SIDE/UP a/b coords + transparent_rgb)")
    ap.add_argument("--payload", help="pre-packed 256 B layout-0 2bpp payload (instead of --art)")
    ap.add_argument("--label", default="Follower_sp224")
    ap.add_argument("--bank", type=lambda s: int(s, 0), default=0x7E)
    ap.add_argument("--out", default=os.path.join(REPO, "patches", "bank_07e.asm"))
    args = ap.parse_args()

    if args.payload:
        payload = open(args.payload, "rb").read()
    elif args.art and args.frames:
        fj = json.load(open(args.frames))
        payload = bfr.pack_png_layout0(args.art, fj["frames"], fj["transparent_rgb"])
    else:
        sys.exit("provide either --payload, or --art + --frames")

    # NOTE: payload is stored UN-FLIPPED on purpose -- see ORIENTATION RULE above.
    stream = sc.encode_safe(payload, literal_only=True)
    alloc = sb.SpriteOverflowAllocator(banks=[args.bank])
    gid = alloc.add(stream, args.label)
    asm = alloc.emit_asm(args.bank)

    out = args.out if os.path.isabs(args.out) else os.path.join(REPO, args.out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, "w").write(asm)
    import hashlib
    print(f"payload {len(payload)} B (md5 {hashlib.md5(payload).hexdigest()})")
    print(f"stream  {len(stream)} B (md5 {hashlib.md5(stream).hexdigest()})")
    print(f"gfx-ID  ${gid:04x}  (bank ${gid>>8:02x} index {gid & 0xff})  <-- resolver tables hold this")
    print(f"wrote   {os.path.relpath(out, REPO)}")


if __name__ == "__main__":
    main()
