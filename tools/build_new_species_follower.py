#!/usr/bin/env python3
"""
build_new_species_follower.py -- complete follower graphics for a NEW species
(ids >=224), where the per-species follower-art tables OVERSHOOT and a direct
table write is impossible. Produces a standalone TEST ROM; the canonical clean
build stays byte-perfect (1ca6579...) and patches/ is left untouched.

What it does (all on top of the full patched build):
  1. ART     -- packs the 16 follower tiles (layout 0) from a sprite sheet, encodes
                a literal stream, and places it in a sprite-overflow bank -> gfx-ID.
  2. LAYOUT  -- the new species' level-1 entry (bank $11 $407f+sub*2) currently holds
                garbage; repoint it at a real bank-$11 layout-0 level-2 table.
  3. ATTR    -- the new species' attr/palette byte (bank $11 $417f+sub) -> OBJ palette.
  4. FORKS   -- every follower-art gfx-ID READER is forked byte-neutral so id>=224
                resolves to the overflow gfx-ID. There are EIGHT copies; this routes
                all of them. Three (banks $07/$09/$18) were already forked to interim
                art and are just re-pointed; the rest get a fresh resolver placed in
                that bank's free space.

Readers come in two index conventions (auto-detected from the table base offset):
  * species+$10  (table base = species0 - $20): threshold cp $e0   (banks 01/06/07/09/0b/12)
  * raw species  (table base = species0):        threshold cp $c0   (banks 18/59)

A bank with no in-bank free space for its resolver is reported and SKIPPED (that
copy keeps overshooting) so the build still succeeds -- finish it once space is
sourced. The reader sites and free space are located in the BUILT (patched) ROM by
signature, so patched-bank shifts don't matter.

Usage:
  python3 tools/build_new_species_follower.py \
      --species 224 --art-png W.png --frames-json gorbunok_frames.json \
      --layout-l2 0x4184 --attr 0x02 --out out/DWM-Gorbunok-follower.gbc
"""
import argparse, hashlib, json, os, re, subprocess, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIS = os.path.join(REPO, "disassembly")
sys.path.insert(0, REPO)
from dwm import sprite_bank as sb, sprite_codec as sc

import importlib.util
_spec = importlib.util.spec_from_file_location("bfr", os.path.join(REPO, "tools", "build_follower_reassign.py"))
bfr = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(bfr)

CANON_MD5 = "1ca6579359f21d8e27b446f865bf6b83"
BANK = 0x4000

# The eight follower-art table copies, by reader-base address (= species0 - $20 for
# the species+$10 readers, = species0 for the raw-species readers). 'raw' flags the
# index convention. 07/09/18 are the pre-existing forks (re-pointed, not re-forked).
COPIES = {
    0x01: dict(base=0x49df, raw=False, existing=False),
    0x06: dict(base=0x4dcc, raw=False, existing=False),
    0x07: dict(base=0x6e14, raw=False, existing=True),
    0x09: dict(base=0x6b10, raw=False, existing=True),
    # $0b's follower table relocates in the patched build, so locate the reader by a
    # base-agnostic code signature and read the (relocated) base out of it.
    0x0b: dict(base=None, raw=False, existing=False,
               prefix=bytes([0x3E, 0x00, 0x8C, 0x67, 0x18, 0x0C, 0x6A, 0x26, 0x00, 0x29, 0x7D, 0xC6])),
    0x12: dict(base=0x65f2, raw=False, existing=False),
    0x18: dict(base=0x4103, raw=True,  existing=True),
    0x59: dict(base=0x4363, raw=True,  existing=False),
}


def flat(bank, addr):
    return addr if bank == 0 else bank * BANK + (addr - 0x4000)


# ---- battle sprite (48x48, 6x6 tiles, 4-colour) -----------------------------
# The enemy renders as BG tiles on a 4-colour palette (idx1 = backdrop). A
# luminance bucket would merge the merman's purple/blue/magenta, so map by hue to
# the 4 indices and ship a matching palette.
BATTLE_PALETTE = bytes([0x26, 0x48, 0xFF, 0x6B, 0xEC, 0x7E, 0x00, 0x00])
#   idx0 deep purple (fish)  idx1 cream backdrop  idx2 light blue (merman)  idx3 black
_BATTLE_MAP = [  # (art rgb) -> palette index
    ((0, 0, 0), 3), ((48, 8, 144), 0), ((96, 184, 248), 2),
    ((208, 64, 232), 0), ((248, 248, 248), 2),
]


def pack_battle_4color(png_path, transparent_rgb):
    import numpy as np
    from PIL import Image
    cols = rows = 6
    W = H = 48
    im = Image.open(png_path).convert("RGB")
    a = np.array(im)
    tr = tuple(transparent_rgb)
    mask = ~np.all(a == tr, axis=2)
    if mask.any():
        ys, xs = np.where(mask.any(1))[0], np.where(mask.any(0))[0]
        im = im.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
    im.thumbnail((W, H), Image.NEAREST)
    canvas = Image.new("RGB", (W, H), tr)
    canvas.paste(im, ((W - im.width) // 2, (H - im.height) // 2))
    ca = np.array(canvas)
    pal = np.array([c for c, _ in _BATTLE_MAP], dtype=int)
    idxs = [i for _, i in _BATTLE_MAP]
    field = [[1] * W for _ in range(H)]  # default = backdrop idx1
    for yy in range(H):
        for xx in range(W):
            px = tuple(int(v) for v in ca[yy, xx])
            if px == tr:
                continue
            d = ((pal - np.array(px)) ** 2).sum(1)
            field[yy][xx] = idxs[int(d.argmin())]
    return sc.indices_to_tiles(field, cols, rows)


def asm_pal_resolver(addr, palette8):
    """Battle-palette resolver: id>=224 (index*8 >= $700, H>=$07) -> HL=&pal8;
    else HL = $62FD + index*8 (HL already holds index*8 at the fork point)."""
    gidw = addr + 18
    body = [0x7C, 0xFE, 0x07, 0x30, 0x09,
            0x7D, 0xC6, 0xFD, 0x6F, 0x7C, 0xCE, 0x62, 0x67, 0xC9,
            0x21, gidw & 0xFF, (gidw >> 8) & 0xFF, 0xC9]
    return bytes(body) + bytes(palette8)


def build_patched_with_overflow(overflow_banks):
    """Copy patches/ over disassembly/, add the overflow bank(s) + their game.asm
    INCLUDE, build, then fully restore the clean tree. Returns ROM bytes."""
    import shutil
    sys.path.insert(0, os.path.join(REPO, "tools"))
    import verify_integrity as vi
    patch_files = vi.PATCH_FILES
    patch_new = vi.PATCH_NEW_FILES
    backups, added = {}, []
    game = os.path.join(DIS, "game.asm")
    try:
        for f in patch_files:
            src = os.path.join(DIS, f)
            backups[f] = open(src, "rb").read() if os.path.exists(src) else None
        for f in patch_files + patch_new:
            p = os.path.join(REPO, "patches", f)
            if os.path.exists(p):
                shutil.copy(p, os.path.join(DIS, f))
        # patched game.asm is now in place; swap empty overflow banks for ours
        gtext = open(game).read()
        for bnk, txt in overflow_banks.items():
            fn = f"bank_{bnk:03x}.asm"
            open(os.path.join(DIS, fn), "w").write(txt)
            added.append(fn)
            gtext = gtext.replace(f'INCLUDE "blank/Empty_bank_{bnk:03x}.asm"',
                                  f'INCLUDE "bank_{bnk:03x}.asm"')
        open(game, "w").write(gtext)
        for f in ("game.o", "game.gbc", "game.sym", "game.map"):
            pp = os.path.join(DIS, f)
            if os.path.exists(pp):
                os.remove(pp)
        r = subprocess.run("make", cwd=DIS, shell=True, capture_output=True, text=True)
        gbc = os.path.join(DIS, "game.gbc")
        if r.returncode != 0 or not os.path.exists(gbc):
            sys.exit("PATCHED+OVERFLOW BUILD FAILED:\n" + r.stdout[-1800:] + r.stderr[-1800:])
        return bytearray(open(gbc, "rb").read())
    finally:
        for f, data in backups.items():
            if data is not None:
                open(os.path.join(DIS, f), "wb").write(data)
        for fn in added + list(patch_new):
            pp = os.path.join(DIS, fn)
            if os.path.exists(pp) and (fn in added or fn in patch_new):
                # only remove files that don't exist in clean disassembly (new banks)
                if fn in added or fn in patch_new:
                    os.remove(pp)
        for f in ("game.o", "game.gbc", "game.sym", "game.map"):
            pp = os.path.join(DIS, f)
            if os.path.exists(pp):
                os.remove(pp)


def find_reader(data, bank, base=None, prefix=None):
    """Locate the reader's add-base sequence `7D C6 <blo> 6F 7C CE <bhi> 67` in the
    built ROM. With `base`, match the exact add-base via `29 7D C6 <blo>...`. With
    `prefix` (a base-agnostic code signature ending at the `C6`), match that and read
    the relocated base out of the bytes. Returns (addbase_file_offset, base) or None."""
    lo, hi = bank * BANK, bank * BANK + BANK
    if prefix is not None:
        j = data.find(prefix, lo, hi)
        if j < 0:
            return None
        ab = j + len(prefix) - 2          # offset of the `7D` (ld a,l) of the add-base
        if not (data[ab] == 0x7D and data[ab + 1] == 0xC6 and
                data[ab + 3] == 0x6F and data[ab + 4] == 0x7C and
                data[ab + 5] == 0xCE and data[ab + 7] == 0x67):
            return None
        det = data[ab + 2] | (data[ab + 6] << 8)
        return ab, det
    blo, bhi = base & 0xFF, (base >> 8) & 0xFF
    sig = bytes([0x29, 0x7D, 0xC6, blo, 0x6F, 0x7C, 0xCE, bhi, 0x67])
    j = data.find(sig, lo, hi)
    return None if j < 0 else (j + 1, base)


def find_free(data, bank, need=30):
    """First run of >=need filler bytes in the bank (built ROM). Prefers 0x00
    (zero-fill); falls back to 0xFF tail padding (`rst $38` filler), staying clear
    of the last byte (some banks keep a self-ID at $7FFF). Returns local addr."""
    base = bank * BANK
    for fill in (0x00, 0xFF):
        s = None
        for i in range(base, base + BANK - 1):   # -1: never touch $7FFF
            if data[i] == fill:
                if s is None:
                    s = i
                elif i - s + 1 >= need:
                    return 0x4000 + (s - base)
            else:
                s = None
    return None


def asm_resolver(resolver_addr, base, gid, raw):
    """Bytes for a FollowerArtResolve: id>=224 -> HL=&GidWord (caller reads the dw),
    else HL = base + index*2. `resolver_addr` is the in-bank ($4000-$7fff) address
    where these bytes will live (needed for the ld hl,GidWord operand)."""
    blo, bhi = base & 0xFF, (base >> 8) & 0xFF
    glo, ghi = gid & 0xFF, (gid >> 8) & 0xFF
    if not raw:  # species+$10, threshold cp $e0 ; GidWord at +27, len 29
        gidw = resolver_addr + 27
        b = [0x7C, 0xFE, 0x02, 0x30, 0x09, 0xFE, 0x01, 0x38, 0x09, 0x7D, 0xFE, 0xE0,
             0x38, 0x04, 0x21, gidw & 0xFF, (gidw >> 8) & 0xFF, 0xC9,
             0x7D, 0xC6, blo, 0x6F, 0x7C, 0xCE, bhi, 0x67, 0xC9, glo, ghi]
    else:        # raw species, threshold cp $c0 ; GidWord at +26, len 28
        gidw = resolver_addr + 26
        b = [0x7C, 0xFE, 0x02, 0x30, 0x08, 0xB7, 0x28, 0x09, 0x7D, 0xFE, 0xC0,
             0x38, 0x04, 0x21, gidw & 0xFF, (gidw >> 8) & 0xFF, 0xC9,
             0x7D, 0xC6, blo, 0x6F, 0x7C, 0xCE, bhi, 0x67, 0xC9, glo, ghi]
    return bytes(b)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--species", type=lambda s: int(s, 0), required=True)
    ap.add_argument("--art-png", required=True)
    ap.add_argument("--frames-json", required=True)
    ap.add_argument("--layout-l2", type=lambda s: int(s, 0), required=True)
    ap.add_argument("--attr", type=lambda s: int(s, 0), default=0x02)
    ap.add_argument("--battle-png", default=None,
                    help="optional: also swap the BATTLE sprite (4-colour) + palette")
    ap.add_argument("--out", default="out/DWM-newspecies-follower.gbc")
    ap.add_argument("--flip-y", dest="flip_y", action="store_true", default=False,
                    help="pre-Y-flip each follower tile (only needed if the attr Y-flip bit is kept)")
    ap.add_argument("--no-flip-y", dest="flip_y", action="store_false")
    args = ap.parse_args()
    sp = args.species
    if sp < 224:
        sys.exit("this tool is for new species (id>=224); existing species use build_follower_reassign.py")
    sub = (sp + 0x10) - 0x90               # bank-$11 sub-index
    if not (0 <= sub < 128):
        sys.exit(f"species {sp} does not route to bank $11")

    # 1. ART -----------------------------------------------------------------
    fj = json.load(open(args.frames_json))
    payload = bfr.pack_png_layout0(args.art_png, fj["frames"], fj["transparent_rgb"])
    if args.flip_y:
        # The follower display path Y-flips every tile in place (head stays top,
        # tail stays bottom, but each 8x8 tile's rows are mirrored). Pre-flip each
        # tile's 8 rows so the two cancel and the sprite renders upright.
        pl = bytearray(payload)
        for t in range(len(pl) // 16):
            rows = [pl[t*16 + r*2 : t*16 + r*2 + 2] for r in range(8)]
            for r in range(8):
                pl[t*16 + r*2 : t*16 + r*2 + 2] = rows[7 - r]
        payload = bytes(pl)
    stream = sc.encode_safe(payload, literal_only=True)
    alloc = sb.SpriteOverflowAllocator()
    gid = alloc.add(stream, f"Follower_sp{sp}")
    battle_gid = None
    if args.battle_png:
        bpay = pack_battle_4color(args.battle_png, fj["transparent_rgb"])
        bstream = sc.encode_safe(bpay, literal_only=True)
        battle_gid = alloc.add(bstream, f"Battle_sp{sp}")
    ovf = {b: alloc.emit_asm(b) for b in alloc.used_banks()}
    print(f"art: {len(payload)} B payload -> {len(stream)} B stream -> gfx-ID ${gid:04x} "
          f"(overflow bank ${gid>>8:02x} idx {gid&0xff})")
    if battle_gid is not None:
        print(f"battle: 576 B payload -> {len(bstream)} B stream -> gfx-ID ${battle_gid:04x}")

    data = build_patched_with_overflow(ovf)

    changes = []
    # 2/3. LAYOUT + ATTR (bank $11 is unpatched -> clean offsets) -------------
    loff = flat(0x11, 0x407f + sub * 2)
    old = data[loff] | (data[loff + 1] << 8)
    data[loff] = args.layout_l2 & 0xFF; data[loff + 1] = (args.layout_l2 >> 8) & 0xFF
    changes.append(f"layout  $11:{0x407f+sub*2:04x}: ${old:04x} -> ${args.layout_l2:04x}")
    # ATTR: the per-species follower attribute is read by HramUnk11_406e as
    # [$412d + (species-$80)]. For id 224 that index (96) overshoots the 87-entry
    # attr table and lands inside Armorpion's layout data at $418d = $41, whose
    # bit6 ($40) is the OAM Y-FLIP bit (-> upside-down tiles) and low3 = 1 (-> OBJ
    # palette 1 = green). Both prior symptoms were this one garbage byte. Writing
    # $418d is impossible (live Armorpion layout), so fork the read: redirect
    # HramUnk11_406e to free space and give id 224 a CLEAN attr (no flip, chosen
    # palette). $98 keeps priority/bank bits, clears both flip bits + palette.
    HRAM_FN = 0x406e            # HramUnk11_406e
    FREE = 0x792d              # bank $11 padding (1747 B of $00)
    orval = args.attr & 0x77
    ff = flat(0x11, FREE)
    resolver = bytes([
        0xF0, 0xC7,                         # ldh a,[$c7]   (adjusted ffc7 = species-$80)
        0xFE, sub & 0xFF,                   # cp <sub>      (224-128 = $60)
        0x20, 0x09,                         # jr nz,.normal
        0xF0, 0xCA,                         # ldh a,[$ca]
        0xE6, 0x98,                         # and $98       (clear Y/X-flip + palette)
        0xF6, orval,                        # or  <palette>
        0xE0, 0xCA,                         # ldh [$ca],a
        0xC9,                               # ret
        # .normal: original HramUnk11_406e body
        0xF0, 0xC7, 0x21, 0x2D, 0x41, 0x85, 0x6F, 0x3E, 0x00, 0x8C,
        0x67, 0xF0, 0xCA, 0xB6, 0xE0, 0xCA, 0xC9,
    ])
    data[ff:ff + len(resolver)] = resolver
    hf = flat(0x11, HRAM_FN)
    data[hf:hf + 3] = bytes([0xC3, FREE & 0xFF, (FREE >> 8) & 0xFF])  # jp $792d
    changes.append(f"attr fork: HramUnk11_406e -> ${FREE:04x}; id {sp} attr forced "
                   f"to clean ${orval:02x} (no flip, OBJ palette {orval & 7})")

    # 4. FORKS ---------------------------------------------------------------
    skipped = []
    for bank, info in sorted(COPIES.items()):
        if info["existing"]:
            # re-point the interim $2f09 GidWord to the real gid (within this bank)
            lo, hi = bank * BANK, bank * BANK + BANK
            sig = bytes([0x67, 0xC9, 0x09, 0x2F])           # ld h,a; ret; dw $2f09
            j = data.find(sig, lo, hi)
            if j < 0:
                skipped.append(f"$%02x (existing fork GidWord $2f09 not found)" % bank)
                continue
            data[j + 2] = gid & 0xFF; data[j + 3] = (gid >> 8) & 0xFF
            changes.append(f"fork    $%02x: existing resolver $2f09 -> $%04x" % (bank, gid))
            continue
        got = find_reader(data, bank, info.get("base"), info.get("prefix"))
        if got is None:
            skipped.append(f"$%02x (reader not found)" % bank)
            continue
        rd, rbase = got
        free = find_free(data, bank, 30)
        if free is None:
            skipped.append(f"$%02x (no >=30 B free space for resolver)" % bank)
            continue
        rbytes = asm_resolver(free, rbase, gid, info["raw"])
        foff = bank * BANK + (free - 0x4000)
        data[foff:foff + len(rbytes)] = rbytes
        # byte-neutral reader fork: 8-byte add-base -> call resolver + 5 nop
        call = bytes([0xCD, free & 0xFF, (free >> 8) & 0xFF, 0, 0, 0, 0, 0])
        data[rd:rd + 8] = call
        changes.append(f"fork    $%02x: reader@${0x4000+(rd-bank*BANK):04x} base=$%04x -> call $%04x "
                        f"(resolver, %s)" % (bank, rbase, free, "raw" if info["raw"] else "sp+$10"))

    # 4b. OVERWORLD CLAMP: a prior placeholder patch (ReadActiveMonsterByteSpeciesClamped
    # in bank $01) clamps species>=224 -> 214 BEFORE GetActiveMonsterStatus reads the
    # follower table, to dodge a garbage-gfx crash when no art existed. That defeats the
    # $01 fork. Now that real art exists, narrow the clamp to species>=225 (cp $e0 -> $e1)
    # so id 224 passes through to the fork; 225-255 keep the safety net.
    lo, hi = 0x01 * BANK, 0x01 * BANK + BANK
    csig = bytes([0xFE, 0xE0, 0xD8, 0x3E, 0xD6, 0xC9])  # cp $e0; ret c; ld a,$d6; ret
    j = data.find(csig, lo, hi)
    if j >= 0 and data.find(csig, j + 1, hi) < 0:
        data[j + 1] = 0xE1
        changes.append("overworld clamp $01: cp $e0 -> cp $e1 (id 224 now reaches the fork)")
    else:
        skipped.append("overworld species clamp not found/ambiguous -- overworld may stay DarkDrium")

    # 5. BATTLE (optional): gfx-ID at the safe $320f padding slot + palette fork --
    if battle_gid is not None:
        # gfx-ID: $00:$2B9F + sp*2 is uniform $320f padding for sp>=216 -> safe write
        goff = flat(0x00, 0x2B9F + sp * 2)
        cur = data[goff] | (data[goff + 1] << 8)
        if cur != 0x320f:
            skipped.append(f"battle gfx slot $%04x not $320f padding (got $%04x) -- skipped"
                           % (0x2B9F + sp * 2, cur))
        else:
            data[goff] = battle_gid & 0xFF; data[goff + 1] = (battle_gid >> 8) & 0xFF
            changes.append(f"battle  gfx  $00:{0x2B9F+sp*2:04x}: $320f -> ${battle_gid:04x}")
        # palette: id224 slot $69FD collides with PaletteColorData -> fork the reader
        lo, hi = 0x17 * BANK, 0x17 * BANK + BANK
        psig = bytes([0x29, 0x29, 0x29, 0x7D, 0xC6, 0xFD, 0x6F, 0x7C, 0xCE, 0x62, 0x67])
        j = data.find(psig, lo, hi)
        free = find_free(data, 0x17, 30)
        if j < 0:
            skipped.append("battle palette reader (label17_41d0) not found -- palette skipped")
        elif free is None:
            skipped.append("battle palette: no free space in bank $17 -- palette skipped")
        else:
            rbytes = asm_pal_resolver(free, BATTLE_PALETTE)
            foff = 0x17 * BANK + (free - 0x4000)
            data[foff:foff + len(rbytes)] = rbytes
            addbase = j + 3                       # the `7D` after the three `29`
            data[addbase:addbase + 8] = bytes([0xCD, free & 0xFF, (free >> 8) & 0xFF, 0, 0, 0, 0, 0])
            changes.append(f"battle  pal  fork label17_41d0 -> resolver $%04x "
                           f"(id>=224 -> custom palette)" % free)

    # checksums + write ------------------------------------------------------
    bfr.fix_header_checksum(data); bfr.fix_global_checksum(data)
    out = args.out if os.path.isabs(args.out) else os.path.join(REPO, args.out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, "wb").write(data)
    print("\nApplied:")
    for c in changes:
        print("  " + c)
    if skipped:
        print("\nSKIPPED (copy still overshoots -- finish later):")
        for s in skipped:
            print("  " + s)
    print(f"\nwrote {os.path.relpath(out, REPO)}  md5 {hashlib.md5(data).hexdigest()}")
    print(f"(canonical clean build still {CANON_MD5}; patches/ untouched)")


if __name__ == "__main__":
    main()
