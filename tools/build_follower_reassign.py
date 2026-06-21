#!/usr/bin/env python3
"""
build_follower_reassign.py  --  DWM1 follower-layout REASSIGNMENT primitive (GFX-4).

Reassigns a monster's overworld follower to a different LAYOUT (and optionally a
different ART), so the editor can drop arbitrary directional art on any monster and
have it render cleanly on a non-sharing layout (the GFX-3 DarkDrium-dragon result).

CORRECTION over the pre-GFX-4 plan: the docs claimed reassignment is "a same-size
[$caca] edit". [$caca] is the SPECIES (party struct +$09) -- you cannot change a
monster's species to restyle it. Reassignment is instead two same-size 2-byte
repoints:

  (1) LAYOUT  -- the monster's LEVEL-1 entry in the routed bank's $407f table:
        bank $10 (species 0..127) or bank $11 (species 128..) at $407f + sub*2,
        repointed to the target layout's level-2 table.
  (2) ART     -- the monster's follower gfx-ID in ScreenTransDataTable ($01:$49DF,
        indexed species+$10), repointed to the desired 16-tile art stream.

SAME-BANK CONSTRAINT (ROM-enforced): the level-2 pointer is dereferenced while the
routed bank is mapped, so a species can only point at a level-2 table that lives in
ITS OWN bank. --clone-from therefore requires source and target to route to the same
bank ($10 with $10, or $11 with $11). The tool checks this and refuses otherwise.

This produces a FOCUSED TEST ROM: the canonical clean build + ONLY these same-size
binary edits (+ checksum fix), exactly like build_sprite_swap.py --palette. For
PERMANENT integration the same two edits go into patches/bank_001.asm (the
ScreenTransDataTable dw) and patches/bank_010.asm / bank_011.asm (the $407f dw).

Usage:
  python3 tools/build_follower_reassign.py --species Healer --clone-from Dragon --out test.gbc
  python3 tools/build_follower_reassign.py --species 9 --layout-l2 0x4e33 --art-gfxid 0x380c --out test.gbc
  python3 tools/build_follower_reassign.py --species Healer --clone-from Dragon --layout-only --out test.gbc
"""
import os
import sys
import json
import argparse
import hashlib
import subprocess
import shutil

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from dwm import sprite_codec as sc
from dwm import sprite_bank as sb

REPO = os.path.join(os.path.dirname(__file__), "..")
DIS = os.path.join(REPO, "disassembly")
MAP = os.path.join(REPO, "extracted", "monster_follower_layouts.json")
MONSTERS = os.path.join(REPO, "extracted", "monsters_full.json")
CANON_MD5 = "1ca6579359f21d8e27b446f865bf6b83"

BANK_SIZE = 0x4000
STDT_BANK, STDT_ADDR = 0x01, 0x49DF      # ScreenTransDataTable (follower gfx-IDs)
L1_ADDR = 0x407F                          # level-1 table addr in bank $10/$11
ATTR_ADDR = 0x417F                        # per-species attr/palette byte table


def flat(bank, addr):
    return bank * BANK_SIZE + (addr - 0x4000)


def load_map():
    return {m["species"]: m for m in json.load(open(MAP))["monsters"]}


def species_id(s):
    if str(s).isdigit():
        return int(s)
    d = json.load(open(MONSTERS))
    ms = d["monsters"] if isinstance(d, dict) and "monsters" in d else (d if isinstance(d, list) else list(d.values()))
    for m in ms:
        if isinstance(m, dict) and m.get("name", "").lower() == str(s).lower():
            return m["id"]
    sys.exit(f"Unknown species: {s}")


def stdt_offset(sp):
    return flat(STDT_BANK, STDT_ADDR) + (sp + 0x10) * 2


def l1_offset(rec):
    return flat(rec["bank"], L1_ADDR) + rec["l1_index"] * 2


def build_clean():
    """Build the canonical clean game.gbc (never `make clean`)."""
    for f in ("game.o", "game.gbc", "game.sym", "game.map"):
        p = os.path.join(DIS, f)
        if os.path.exists(p):
            os.remove(p)
    r = subprocess.run("make", cwd=DIS, shell=True, capture_output=True, text=True)
    gbc = os.path.join(DIS, "game.gbc")
    if r.returncode != 0 or not os.path.exists(gbc):
        sys.exit("CLEAN BUILD FAILED:\n" + r.stdout[-1500:] + r.stderr[-1500:])
    data = bytearray(open(gbc, "rb").read())
    md5 = hashlib.md5(data).hexdigest()
    if md5 != CANON_MD5:
        sys.exit(f"Clean build MD5 {md5} != canonical {CANON_MD5} -- aborting.")
    return data


def build_with_overflow(new_banks):
    """Build clean tree + extra overflow bank(s) holding new sprite art.

    Returns the built ROM bytes. Mirrors build_sprite_swap.build_focused_rom but
    makes NO disassembly edits (all repoints are applied as binary patches after).
    """
    game = os.path.join(DIS, "game.asm")
    backup = open(game).read()
    added = []
    try:
        gtext = backup
        for bnk, txt in new_banks.items():
            fn = f"bank_{bnk:03x}.asm"
            open(os.path.join(DIS, fn), "w").write(txt)
            added.append(fn)
            gtext = gtext.replace(f'INCLUDE "blank/Empty_bank_{bnk:03x}.asm"',
                                  f'INCLUDE "bank_{bnk:03x}.asm"')
        open(game, "w").write(gtext)
        for f in ("game.o", "game.gbc", "game.sym", "game.map"):
            p = os.path.join(DIS, f)
            if os.path.exists(p):
                os.remove(p)
        r = subprocess.run("make", cwd=DIS, shell=True, capture_output=True, text=True)
        gbc = os.path.join(DIS, "game.gbc")
        if r.returncode != 0 or not os.path.exists(gbc):
            sys.exit("OVERFLOW BUILD FAILED:\n" + r.stdout[-1500:] + r.stderr[-1500:])
        return bytearray(open(gbc, "rb").read())
    finally:
        open(game, "w").write(backup)
        for fn in added:
            p = os.path.join(DIS, fn)
            if os.path.exists(p):
                os.remove(p)
        for f in ("game.o", "game.gbc", "game.sym", "game.map"):
            p = os.path.join(DIS, f)
            if os.path.exists(p):
                os.remove(p)


# layout-0 (the workhorse non-sharing directional layout, used by Dragon sp28 + 13
# others) packs the 16 follower tiles as straight 2x2 slices:
#   tiles  0..3  = DOWN-a  (down_B is the engine's auto horizontal-mirror)
#   tiles  4..7  = SIDE-a  (right walk frame A; LEFT = engine global X-flip)
#   tiles  8..11 = SIDE-b  (right walk frame B -> real side walk animation)
#   tiles 12..15 = UP-a    (up_B is the engine's auto horizontal-mirror)
LAYOUT0_ORDER = ["DOWN-a", "SIDE-a", "SIDE-b", "UP-a"]


def pack_png_layout0(png_path, frames, transparent_rgb):
    """PNG sprite sheet + 6-frame coords -> 256-byte (16-tile) 2bpp follower payload,
    tiled for layout 0. `frames` = {label:{x,y,w,h}}; only the 4 layout-0 frames used.
    Luminance-bucketed per-frame into idx 1/2/3 (idx0 = transparent bg)."""
    from PIL import Image
    import numpy as np
    a = np.array(Image.open(png_path).convert("RGB"))
    bg = tuple(transparent_rgb)

    def frame_idx(fr):
        x, y, w, h = fr["x"], fr["y"], fr.get("w", 16), fr.get("h", 16)
        sub = a[y:y + 16, x:x + 16].astype(float)
        isbg = (sub[:, :, 0] == bg[0]) & (sub[:, :, 1] == bg[1]) & (sub[:, :, 2] == bg[2])
        lum = 0.299 * sub[:, :, 0] + 0.587 * sub[:, :, 1] + 0.114 * sub[:, :, 2]
        fg = lum[~isbg]
        lo, hi = (float(fg.min()), float(fg.max())) if fg.size else (0.0, 1.0)
        t1, t2 = lo + (hi - lo) * 0.66, lo + (hi - lo) * 0.33
        idx = [[0] * 16 for _ in range(16)]
        for yy in range(16):
            for xx in range(16):
                if isbg[yy, xx]:
                    idx[yy][xx] = 0
                else:
                    L = lum[yy, xx]
                    idx[yy][xx] = 1 if L >= t1 else (2 if L >= t2 else 3)
        return idx

    def quads(idx):  # TL, TR, BL, BR
        return [
            [row[0:8] for row in idx[0:8]],
            [row[8:16] for row in idx[0:8]],
            [row[0:8] for row in idx[8:16]],
            [row[8:16] for row in idx[8:16]],
        ]

    tiles = []
    for lab in LAYOUT0_ORDER:
        tiles += quads(frame_idx(frames[lab]))
    payload = bytearray()
    for t in tiles:
        for yy in range(8):
            lo = hi = 0
            for xx in range(8):
                v = int(t[yy][xx])
                lo = (lo << 1) | (v & 1)
                hi = (hi << 1) | ((v >> 1) & 1)
            payload += bytes([lo, hi])
    assert len(payload) == 256
    return bytes(payload)


def fix_header_checksum(data):
    cs = 0
    for i in range(0x134, 0x14D):
        cs = (cs - data[i] - 1) & 0xFF
    data[0x14D] = cs


def fix_global_checksum(data):
    cs = 0
    for i, b in enumerate(data):
        if i in (0x14E, 0x14F):
            continue
        cs = (cs + b) & 0xFFFF
    data[0x14E] = (cs >> 8) & 0xFF
    data[0x14F] = cs & 0xFF


def w16(data, off, val):
    old = data[off] | (data[off + 1] << 8)
    data[off] = val & 0xFF
    data[off + 1] = (val >> 8) & 0xFF
    return old


def find_art_table_copies(data):
    """Discover every copy of the per-species follower-art gfx-ID table.

    The ROM keeps EIGHT parallel copies (overworld ScreenTransDataTable in bank $01,
    plus menu/library/battle/cutscene copies in banks $06/$07/$09/$0b/$12/$18/$59).
    Each is indexed so that the species-0 entry sits at the returned offset. A complete
    follower-art swap must repoint the target species in ALL of them (GFX-3 repointed
    only the bank-$01 copy, which is why menus/library kept the old art).

    Returns a list of (species0_file_offset, bank, local_addr). Discovered by the
    species-0..4 = $2f01..$2f05 signature, validated by >=200/221 species matching the
    bank-$01 ScreenTransDataTable species range so coincidental matches are excluded.
    """
    sig = bytes([0x01, 0x2F, 0x02, 0x2F, 0x03, 0x2F, 0x04, 0x2F, 0x05, 0x2F])
    # reference species sequence from the canonical ScreenTransDataTable (bank $01)
    ref0 = data.find(sig)
    ref = [data[ref0 + i * 2] | (data[ref0 + i * 2 + 1] << 8) for i in range(221)]
    copies, i = [], 0
    while True:
        j = data.find(sig, i)
        if j < 0:
            break
        i = j + 1
        vals = [data[j + k * 2] | (data[j + k * 2 + 1] << 8) for k in range(221)]
        if sum(1 for a, b in zip(ref, vals) if a == b) >= 200:
            bank = j // BANK_SIZE
            local = 0x4000 + j % BANK_SIZE if bank else j
            copies.append((j, bank, local))
    return copies


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--species", required=True, help="target monster to reassign (id or name)")
    ap.add_argument("--clone-from", help="source monster: copy its layout + art (same bank required)")
    ap.add_argument("--layout-l2", help="explicit level-2 table addr (e.g. 0x4e33)")
    ap.add_argument("--art-gfxid", help="explicit follower gfx-ID (e.g. 0x380c)")
    ap.add_argument("--art-payload", help="256-byte raw 2bpp follower art -> placed in an overflow bank")
    ap.add_argument("--art-png", help="PNG sprite sheet for custom art (with --frames-json)")
    ap.add_argument("--frames-json", help="picker frame-coords JSON (transparent_rgb + frames)")
    ap.add_argument("--attr", help="explicit attr/palette byte (e.g. 0x02 = OBJ palette 2)")
    ap.add_argument("--overflow-banks", help="comma hex overflow banks (default $7e,$7f,...)")
    ap.add_argument("--layout-only", action="store_true", help="repoint layout only")
    ap.add_argument("--art-only", action="store_true", help="repoint art only")
    ap.add_argument("--out", default="follower_reassign_test.gbc")
    args = ap.parse_args()

    mp = load_map()
    sp = species_id(args.species)
    if sp not in mp:
        sys.exit(f"species {sp} not in {os.path.relpath(MAP)}")
    tgt = mp[sp]

    new_l2 = None
    new_art = None
    new_attr = None
    if args.clone_from:
        src = mp[species_id(args.clone_from)]
        if src["bank"] != tgt["bank"]:
            sys.exit(f"SAME-BANK CONSTRAINT: target {tgt['name']} is bank ${tgt['bank']:02x} "
                     f"but source {src['name']} is bank ${src['bank']:02x}. The level-2 pointer "
                     f"is read with the target's bank mapped, so pick a same-bank source.")
        new_l2 = src["l2_addr"]
        new_attr = src["attr_base"]
        # source's follower gfx-ID from ScreenTransDataTable (read from a clean build later)
        new_art = ("clone", src["species"])
    if args.layout_l2:
        new_l2 = int(args.layout_l2, 0)
    if args.art_gfxid:
        new_art = int(args.art_gfxid, 0)
    if args.attr:
        new_attr = int(args.attr, 0)
    if args.art_only:
        new_l2 = None; new_attr = None
    if args.layout_only:
        new_art = None; new_attr = None

    # Custom art: build the 256-byte payload, place it in an overflow bank, and
    # repoint ALL follower-art copies to the resulting gfx-ID.
    custom_payload = None
    if args.art_payload:
        custom_payload = open(args.art_payload, "rb").read()
    elif args.art_png:
        fj = json.load(open(args.frames_json))
        custom_payload = pack_png_layout0(args.art_png, fj["frames"], fj["transparent_rgb"])
    if custom_payload is not None and (args.layout_only):
        sys.exit("--layout-only conflicts with custom art")

    if new_l2 is None and new_art is None and new_attr is None and custom_payload is None:
        sys.exit("nothing to do: give --clone-from / --layout-l2 / --art-gfxid / --art-payload / --art-png")

    overflow_gid = None
    if custom_payload is not None:
        if len(custom_payload) != 256:
            sys.exit(f"custom art payload must be 256 bytes, got {len(custom_payload)}")
        banks = [int(x, 16) for x in args.overflow_banks.split(",")] if args.overflow_banks else None
        alloc = sb.SpriteOverflowAllocator(banks)
        stream = sc.encode_safe(custom_payload, literal_only=True)
        overflow_gid = alloc.add(stream, f"FollowerCustom_sp{sp}")
        new_banks = {b: alloc.emit_asm(b) for b in alloc.used_banks()}
        data = build_with_overflow(new_banks)
        new_art = overflow_gid
    else:
        data = build_clean()

    # resolve a cloned art gfx-ID now that we have the clean ROM bytes
    if isinstance(new_art, tuple) and new_art[0] == "clone":
        soff = stdt_offset(new_art[1])
        new_art = data[soff] | (data[soff + 1] << 8)

    changes = []
    if new_l2 is not None:
        off = l1_offset(tgt)
        old = w16(data, off, new_l2)
        changes.append((f"layout  $%02x:%04x (level-1[%d])" % (tgt['bank'], L1_ADDR + tgt['l1_index']*2, tgt['l1_index']),
                        old, new_l2))
    if new_art is not None:
        copies = find_art_table_copies(data)
        for sp0_off, bank, local in copies:
            off = sp0_off + sp * 2
            old = w16(data, off, new_art)
            changes.append((f"art     $%02x:%04x (follower-gfxid copy, sp%d)" % (bank, local + sp * 2, sp),
                            old, new_art))
    if new_attr is not None:
        off = flat(tgt["bank"], ATTR_ADDR) + tgt["l1_index"]
        old = data[off]
        data[off] = new_attr & 0xFF
        changes.append((f"attr    $%02x:%04x (attr/palette byte)" % (tgt['bank'], ATTR_ADDR + tgt['l1_index']),
                        old, new_attr & 0xFF))

    fix_header_checksum(data)
    fix_global_checksum(data)
    out = args.out if os.path.isabs(args.out) else os.path.join(REPO, args.out)
    open(out, "wb").write(data)
    md5 = hashlib.md5(data).hexdigest()

    print(f"Follower reassignment: {tgt['name']} (sp{sp}, bank ${tgt['bank']:02x})")
    if args.clone_from:
        print(f"  cloned from: {mp[species_id(args.clone_from)]['name']}")
    if overflow_gid is not None:
        print(f"  custom art placed: overflow bank ${overflow_gid>>8:02x} idx {overflow_gid&0xff} "
              f"(gfx-ID ${overflow_gid:04x}); repointed in all {len(find_art_table_copies(data))} art copies")
    for label, old, new in changes:
        print(f"  {label}: ${old:04x} -> ${new:04x}")
    print(f"  wrote {os.path.relpath(out, REPO)}  md5 {md5}")
    print(f"  (canonical clean build still {CANON_MD5})")


if __name__ == "__main__":
    main()
