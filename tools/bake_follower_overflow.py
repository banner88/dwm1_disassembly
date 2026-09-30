#!/usr/bin/env python3
"""
bake_follower_overflow.py -- encode new-species art (follower + battle) into the
LZ streams a project's custom.species entries point at.

S105 (ROADMAP P3.9b): bank $7E is COMPILER-OWNED (editor2 `species7e` builds it
from project.json custom.species; PROJECT_COMPILER §2.21), so this tool no
longer writes patches/bank_07e.asm. Use --stream-dir to write
<name>_follower.bin / <name>_battle.bin into a project's assets folder (the
example project's Gorbunok assets are reproduced byte-for-byte by the command
below), or --out <file outside patches/> for a stand-alone overflow-bank .asm.

  python3 tools/bake_follower_overflow.py \
      --art examples/follower_swap/W_bluedragon.png \
      --frames examples/follower_swap/gorbunok_frames.json \
      --battle-art examples/follower_swap/W_bluedragon.png \
      --battle-spec examples/follower_swap/gorbunok_battle.json \
      --stream-dir editor2/example-project/assets/species --name gorbunok

(Historical, pre-S105: emitted a sprite-overflow bank ($7E..) as a STATIC patch
file (patches/bank_0XX.asm) from one or more follower art sources.)

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

Usage (follower only):
  python3 tools/bake_follower_overflow.py \
      --art examples/follower_swap/W_bluedragon.png \
      --frames examples/follower_swap/bluedragon_frames.json \
      --label Follower_sp224 --out patches/bank_07e.asm

Usage (follower + BATTLE, G2 -- emits both streams into bank $7E):
  python3 tools/bake_follower_overflow.py \
      --art examples/follower_swap/W_bluedragon.png \
      --frames examples/follower_swap/bluedragon_frames.json \
      --battle-art examples/follower_swap/W_bluedragon.png \
      --battle-spec examples/follower_swap/gorbunok_battle.json \
      --out patches/bank_07e.asm
  # follower -> index 0 ($7E00); battle -> index 1 ($7E01). The tool prints the
  # battle gfx-ID (-> MonsterBattleGfxTable[224]) and the 8-byte battle palette
  # (-> the bank $17 HighBattlePal fork). Those two are the STATIC infrastructure
  # in patches/bank_000.asm + patches/bank_017.asm; the streams here are the
  # reproducible art payload.

  # or feed a pre-packed 256 B layout-0 payload directly (follower):
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


# ---- battle sprite (48x48, 6x6 tiles, 4-colour) -----------------------------
# The enemy renders as BG tiles on a 4-colour palette where idx1 is forced to the
# cream backdrop ($6bff), so only idx0/idx2/idx3 are usable body colours. The
# `color_map` in the battle spec assigns each art colour to an index (merge >3 art
# colours down to <=3 body indices); the matching `palette` ships the 4 RGB555
# words. UN-FLIPPED art, same orientation rule as followers (no pre-flip).
def pack_battle(art_png, spec):
    import numpy as np
    from PIL import Image
    cols = rows = 6
    W = H = 48
    tr = tuple(spec["transparent_rgb"])
    im = Image.open(art_png).convert("RGB")
    bb = spec.get("bbox")
    if bb:
        im = im.crop((bb["x"], bb["y"], bb["x"] + bb["w"], bb["y"] + bb["h"]))
    else:  # auto-crop on transparent
        a = np.array(im); mask = ~np.all(a == tr, axis=2)
        if mask.any():
            ys, xs = np.where(mask.any(1))[0], np.where(mask.any(0))[0]
            im = im.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
    im.thumbnail((W, H), Image.NEAREST)
    canvas = Image.new("RGB", (W, H), tr)
    canvas.paste(im, ((W - im.width) // 2, (H - im.height) // 2))
    ca = np.array(canvas)
    cmap = [(tuple(e["rgb"]), e["index"]) for e in spec["color_map"]]
    pal = np.array([c for c, _ in cmap], dtype=int)
    idxs = [i for _, i in cmap]
    field = [[1] * W for _ in range(H)]  # default = backdrop idx1
    for yy in range(H):
        for xx in range(W):
            px = tuple(int(v) for v in ca[yy, xx])
            if px == tr:
                continue
            d = ((pal - np.array(px)) ** 2).sum(1)
            field[yy][xx] = idxs[int(d.argmin())]
    payload = sc.indices_to_tiles(field, cols, rows)
    pal8 = b"".join(int(x, 0).to_bytes(2, "little") for x in spec["palette"])
    return payload, pal8


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--art", help="follower sprite-sheet PNG")
    ap.add_argument("--frames", help="frames-json (DOWN/SIDE/UP a/b coords + transparent_rgb)")
    ap.add_argument("--payload", help="pre-packed 256 B layout-0 2bpp payload (instead of --art)")
    ap.add_argument("--label", default="Follower_sp224")
    ap.add_argument("--bank", type=lambda s: int(s, 0), default=0x7E)
    ap.add_argument("--battle-art", help="battle sprite-sheet PNG (adds a 2nd overflow entry)")
    ap.add_argument("--battle-spec", help="battle-spec JSON (bbox + color_map + palette)")
    ap.add_argument("--battle-label", default="Battle_sp224")
    ap.add_argument("--out", help="stand-alone overflow-bank .asm (NOT under patches/: "
                    "bank $7E is compiler-owned since S105)")
    ap.add_argument("--stream-dir", help="write <name>_follower.bin (+ <name>_battle.bin) "
                    "for a project's custom.species art (S105)")
    ap.add_argument("--name", default="species", help="file stem for --stream-dir")
    args = ap.parse_args()
    if not args.out and not args.stream_dir:
        sys.exit("give --stream-dir (project assets) or --out (a stand-alone .asm)")
    if args.out:
        o = os.path.abspath(args.out if os.path.isabs(args.out) else os.path.join(REPO, args.out))
        if o.startswith(os.path.join(REPO, "patches") + os.sep):
            sys.exit("RETIRED S105 (P3.9b): patches/bank_07e.asm is generated by the "
                     "compiler from project.json custom.species — write the streams "
                     "with --stream-dir and reference them from the project")

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
    gid = alloc.add(stream, args.label)               # index 0 -> follower

    battle = None
    if args.battle_art and args.battle_spec:
        bspec = json.load(open(args.battle_spec))
        bpay, bpal8 = pack_battle(args.battle_art, bspec)
        bstream = sc.encode_safe(bpay, literal_only=True)
        bgid = alloc.add(bstream, args.battle_label)   # index 1 -> battle
        battle = (bpay, bstream, bgid, bpal8)
    elif args.battle_art or args.battle_spec:
        sys.exit("battle needs BOTH --battle-art and --battle-spec")

    written = []
    if args.stream_dir:
        os.makedirs(args.stream_dir, exist_ok=True)
        fp = os.path.join(args.stream_dir, f"{args.name}_follower.bin")
        open(fp, "wb").write(stream)
        written.append(fp)
        if battle is not None:
            bp = os.path.join(args.stream_dir, f"{args.name}_battle.bin")
            open(bp, "wb").write(battle[1])
            written.append(bp)
    if args.out:
        asm = alloc.emit_asm(args.bank)
        out = args.out if os.path.isabs(args.out) else os.path.join(REPO, args.out)
        os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
        open(out, "w").write(asm)
        written.append(out)
    import hashlib
    print(f"follower payload {len(payload)} B (md5 {hashlib.md5(payload).hexdigest()})")
    print(f"follower stream  {len(stream)} B (md5 {hashlib.md5(stream).hexdigest()})")
    print(f"follower gfx-ID  ${gid:04x}  (bank ${gid>>8:02x} index {gid & 0xff})  <-- standalone-bank index; in a project the compiler places the stream at $7E00+(id-221)*2 (S105 G3)")
    if battle is not None:
        bpay, bstream, bgid, bpal8 = battle
        print(f"battle   payload {len(bpay)} B (md5 {hashlib.md5(bpay).hexdigest()})")
        print(f"battle   stream  {len(bstream)} B (md5 {hashlib.md5(bstream).hexdigest()})")
        print(f"battle   gfx-ID  ${bgid:04x}  (bank ${bgid>>8:02x} index {bgid & 0xff})  <-- standalone-bank index; in a project: $7E00+(id-221)*2+1")
        print(f"battle   palette {' '.join('%02x' % b for b in bpal8)}  <-- custom.species[].battle.palette")
    for w in written:
        print(f"wrote   {w}")


if __name__ == "__main__":
    main()
