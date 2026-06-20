#!/usr/bin/env python3
"""
build_sprite_swap.py - cross-bank monster sprite swap (battle + follower).

Supersedes the Session-22 battle-only / bank-$36-only tool. Places sprite streams
into the reserved overflow banks (dwm.sprite_bank, EDITOR_DESIGN section 8) and
repoints the monster's gfx-ID, so it works for ANY of the 221 monsters regardless
of which bank their original art lives in, and for BATTLE and (next) FOLLOWER alike.

Art sources:
  --relocate   copy the monster's EXISTING stream UNCHANGED into overflow + repoint.
               Byte-identical decode -> renders identically (regression/proof mode,
               also what the editor uses to move a sprite out of a full bank).
  --png FILE   import new art (e.g. a DWM2 rip). Heuristic luminance mapping for the
               proof; the editor's faithful quantizer is the follow-on.
  --payload F  raw 2bpp tile bytes (36 tiles battle / 16 follower).

Repoints (both are same-size 2-byte data edits = Iron-Rule-2 safe):
  battle    MonsterBattleGfxTable  $00:$2B9F  [species*2]
  follower  ScreenTransDataTable   $01:$49DF  [(species+$10)*2]   (re-section pending)

With --build-rom it assembles a FOCUSED test ROM (clean tree + ONLY these sprite
changes), restoring the clean tree afterwards.
"""
import os, sys, json, argparse, shutil, subprocess, hashlib, re

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from dwm import sprite_codec as sc
from dwm import sprite_bank as sb

ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
DIS = os.path.join(REPO, 'disassembly')
BATTLE_TABLE = 0x2B9F
FOLLOWER_TABLE_BANK = 0x01
FOLLOWER_TABLE = 0x49DF
FIELD_TILES = (6, 6)       # battle 48x48 / 36 tiles
FOLLOWER_TILES = (4, 4)    # follower 16 tiles
# Per-species battle palette table (BG palette slot 4 colours), 8 B/species =
# 4 RGB555 LE [c0, c1=$6bff backdrop(forced), c2, c3=$0000 black]. Found via
# SameBoy palette dump + ROM grep (Dracky sp78 @ $656d, Slime sp8 @ $633d).
MONSTER_PALETTE_TABLE = 0x17 * 0x4000 + (0x62FD - 0x4000)   # ROM offset 0x5e2fd


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


def patch_palette(rom_path, sp, colors):
    """Same-size 8-byte edit of MonsterBattlePalettes[sp] in a built ROM + fix
    checksums. colors = 4 ints (RGB555). Returns (old8, new8)."""
    data = bytearray(open(rom_path, 'rb').read())
    off = MONSTER_PALETTE_TABLE + sp * 8
    old = bytes(data[off:off + 8])
    new = b''.join(bytes([c & 0xFF, (c >> 8) & 0xFF]) for c in colors)
    assert len(new) == 8
    data[off:off + 8] = new
    fix_header_checksum(data)
    fix_global_checksum(data)
    open(rom_path, 'wb').write(data)
    return old, new


def species_id(s):
    if str(s).isdigit():
        return int(s)
    d = json.load(open(os.path.join(REPO, 'extracted', 'monsters_full.json')))
    ms = d if isinstance(d, list) else list(d.values())
    for m in ms:
        if isinstance(m, dict) and m.get('name', '').lower() == str(s).lower():
            return m['id']
    sys.exit(f'Unknown species: {s}')


def battle_gfxid(rom, sp):
    o = BATTLE_TABLE + sp * 2
    return rom[o] | (rom[o + 1] << 8)


def follower_gfxid(rom, sp):
    o = sb.BANK_SIZE * FOLLOWER_TABLE_BANK + (FOLLOWER_TABLE - 0x4000) + (sp + 0x10) * 2
    return rom[o] | (rom[o + 1] << 8)


def png_to_payload(png_path, tiles, bg_index=1, body=(2, 3)):
    import numpy as np
    from PIL import Image
    cols, rows = tiles
    W, H = cols * 8, rows * 8
    field = np.full((H, W), bg_index, dtype=int)
    im = Image.open(png_path).convert('RGB')
    a = np.array(im); bg = tuple(int(v) for v in a[0, 0])
    mask = ~np.all(a == bg, axis=2)
    if mask.any():
        ys, xs = np.where(mask.any(1))[0], np.where(mask.any(0))[0]
        im = im.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
    im.thumbnail((W * 4 // 6, H * 4 // 6), Image.NEAREST)
    canvas = Image.new('RGB', (W, H), bg)
    canvas.paste(im, ((W - im.width) // 2, (H - im.height) // 2))
    ca = np.array(canvas)
    lum = 0.299 * ca[:, :, 0] + 0.587 * ca[:, :, 1] + 0.114 * ca[:, :, 2]
    isbg = np.all(ca == bg, axis=2)
    if (~isbg).any():
        fl = lum[~isbg]; lo, hi = fl.min(), fl.max(); n = len(body)
        for yy in range(H):
            for xx in range(W):
                if not isbg[yy, xx]:
                    t = (lum[yy, xx] - lo) / (hi - lo + 1e-6)
                    field[yy, xx] = body[min(n - 1, int((1.0 - t) * n))]
    grid = [[int(field[y, x]) for x in range(W)] for y in range(H)]
    return sc.indices_to_tiles(grid, cols, rows)


def make_stream(rom, sp, kind, args):
    gid = battle_gfxid(rom, sp) if kind == 'battle' else follower_gfxid(rom, sp)
    bank, index, saddr, foff = sc.gfxid_stream_offset(rom, gid)
    if args.relocate:
        return sc.read_stream(rom, foff), gid
    tiles = FIELD_TILES if kind == 'battle' else FOLLOWER_TILES
    if args.payload:
        payload = open(args.payload, 'rb').read()
    else:
        payload = png_to_payload(args.png, tiles,
                                 int(os.environ.get('BG_INDEX', '1')),
                                 tuple(int(x) for x in os.environ.get('BODY_INDICES', '2,3').split(',')))
    return sc.encode_safe(payload, literal_only=True), gid


# ---- byte-accurate repoint of MonsterBattleGfxTable (mixed dw/db, preserved labels) ----
TOK = re.compile(r'^(\s*)(dw|db)\s+(.*?)(\s*;.*)?$')

def repoint_battle(text, sp, new_gid):
    """Rewrite MonsterBattleGfxTable[sp] = new_gid, walking real bytes so the
    table's embedded cross-bank labels and db-split entries are preserved."""
    a = text.index('MonsterBattleGfxTable:')
    b = text.index('TileRotatePadding:', a)
    head, body, tail = text[:a], text[a:b], text[b:]
    target_lo, target_hi = sp * 2, sp * 2 + 1
    lines = body.split('\n')
    bytepos = 0
    pend = {}  # byte offset -> replacement byte value (for db split)
    done = False
    for li, ln in enumerate(lines):
        m = TOK.match(ln)
        if not m:
            continue
        indent, kind, data, comment = m.group(1), m.group(2), m.group(3), m.group(4) or ''
        toks = [t.strip() for t in data.split(',')]
        new_toks = []
        changed = False
        for t in toks:
            if kind == 'dw':
                if bytepos == target_lo and not done:
                    new_toks.append(f'${new_gid:04x}'); changed = True; done = True
                else:
                    new_toks.append(t)
                bytepos += 2
            else:  # db, one byte
                if bytepos == target_lo:
                    new_toks.append(f'${new_gid & 0xff:02x}'); changed = True
                elif bytepos == target_hi:
                    new_toks.append(f'${(new_gid >> 8) & 0xff:02x}'); changed = True; done = True
                else:
                    new_toks.append(t)
                bytepos += 1
        if changed:
            lines[li] = f'{indent}{kind} ' + ', '.join(new_toks) + comment
    if not done:
        raise RuntimeError(f'could not locate battle table entry for sp{sp} '
                           f'(walked {bytepos} bytes)')
    return head + '\n'.join(lines) + tail


def build_focused_rom(out_rom, bank_edits, new_banks):
    backups = {}
    game = os.path.join(DIS, 'game.asm')
    backups['game.asm'] = open(game).read()
    for fn in bank_edits:
        backups[fn] = open(os.path.join(DIS, fn)).read()
    added = []
    try:
        for fn, txt in bank_edits.items():
            open(os.path.join(DIS, fn), 'w').write(txt)
        gtext = backups['game.asm']
        for bnk, txt in new_banks.items():
            fn = f'bank_{bnk:03x}.asm'
            open(os.path.join(DIS, fn), 'w').write(txt)
            added.append(fn)
            gtext = gtext.replace(f'INCLUDE "blank/Empty_bank_{bnk:03x}.asm"',
                                  f'INCLUDE "bank_{bnk:03x}.asm"')
        open(game, 'w').write(gtext)
        for f in ('game.o', 'game.gbc', 'game.sym', 'game.map'):
            p = os.path.join(DIS, f)
            if os.path.exists(p): os.remove(p)
        r = subprocess.run('make', cwd=DIS, shell=True, capture_output=True, text=True)
        gbc = os.path.join(DIS, 'game.gbc')
        if r.returncode != 0 or not os.path.exists(gbc):
            sys.exit('BUILD FAILED:\n' + r.stdout[-1500:] + r.stderr[-1500:])
        os.makedirs(os.path.dirname(out_rom), exist_ok=True)
        shutil.copy(gbc, out_rom)
        return hashlib.md5(open(out_rom, 'rb').read()).hexdigest()
    finally:
        for fn, txt in backups.items():
            open(os.path.join(DIS, fn), 'w').write(txt)
        for fn in added:
            p = os.path.join(DIS, fn)
            if os.path.exists(p): os.remove(p)
        for f in ('game.o', 'game.gbc', 'game.sym', 'game.map'):
            p = os.path.join(DIS, f)
            if os.path.exists(p): os.remove(p)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--species', required=True)
    ap.add_argument('--kind', choices=['battle', 'follower'], default='battle')
    ap.add_argument('--relocate', action='store_true')
    ap.add_argument('--png')
    ap.add_argument('--payload')
    ap.add_argument('--build-rom')
    ap.add_argument('--banks')
    ap.add_argument('--palette', help='comma 4 RGB555 hex for battle palette, e.g. 6c17,6bff,3a75,0000')
    args = ap.parse_args()
    if not (args.relocate or args.png or args.payload):
        sys.exit('need --relocate, --png, or --payload')
    if args.kind == 'follower':
        sys.exit('follower repoint needs $01:$49DF re-sectioned first (next step).')

    rom = open(ROM, 'rb').read()
    sp = species_id(args.species)
    banks = [int(x, 16) for x in args.banks.split(',')] if args.banks else None
    alloc = sb.SpriteOverflowAllocator(banks)
    stream, old_gid = make_stream(rom, sp, args.kind, args)
    new_gid = alloc.add(stream, f'SprOvf_{args.kind}_sp{sp}')
    print(f'sp{sp} {args.kind}: gfx-ID ${old_gid:04x} -> ${new_gid:04x} '
          f'(overflow bank ${new_gid>>8:02x} idx {new_gid&0xff}); stream {len(stream)} B'
          f'{" [relocated unchanged]" if args.relocate else ""}')
    new_banks = {bnk: alloc.emit_asm(bnk) for bnk in alloc.used_banks()}
    bank000 = repoint_battle(open(os.path.join(DIS, 'bank_000.asm')).read(), sp, new_gid)
    if args.build_rom:
        md5 = build_focused_rom(args.build_rom, {'bank_000.asm': bank000}, new_banks)
        if args.palette:
            cols = [int(x, 16) for x in args.palette.split(',')]
            old, new = patch_palette(args.build_rom, sp, cols)
            md5 = __import__('hashlib').md5(open(args.build_rom, 'rb').read()).hexdigest()
            print(f'  palette sp{sp}: ' + ' '.join('%02x' % b for b in old) +
                  ' -> ' + ' '.join('%02x' % b for b in new) + '  ($17:$%04x)' % (0x62FD + sp * 8))
        print(f'  built {args.build_rom}\n  md5 {md5}')
    else:
        for bnk, txt in new_banks.items():
            open(os.path.join(REPO, 'patches', f'bank_{bnk:03x}.asm'), 'w').write(txt)
            print(f'  wrote patches/bank_{bnk:03x}.asm')


if __name__ == '__main__':
    main()
