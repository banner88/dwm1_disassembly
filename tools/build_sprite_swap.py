#!/usr/bin/env python3
"""
build_sprite_swap.py — GFX-1 battle-sprite swap (species-agnostic, codec-based).

Replaces a monster's BATTLE sprite with new art from a PNG, by:
  1. resolving the species' gfx-ID from the ROM battle table ($00:$2B9F)
     -> (bank, pointer-table index) via dwm.sprite_codec,
  2. encoding the new art to an LZ stream (dwm.sprite_codec; greedy by default,
     or --literal for a self-contained pool-free stream),
  3. placing the stream in that bank's trailing free space and repointing the
     bank's pointer-table entry ($<bank>:$4001 + index*2) at it.

Generalises the Session-21 POC (Dracky->clam, hard-coded in bank $36). It is the
editor's battle-sprite-build backend. The pointer repoint is a same-bank,
same-size edit (zero shift); the stream lives in end-of-bank free space, so the
clean disassembly stays byte-perfect and only the targeted bank patch changes.

Battle field is 48x48 (6x6 tiles / 576 B). PNG is fit into a centred 32x32 area;
the field is filled with the backdrop palette index so the surround is not index 0.
Palette is a SEPARATE subsystem (GFX-2): this tool assigns palette INDICES only.

Usage:
  python3 tools/build_sprite_swap.py --species 78 --png art.png
  python3 tools/build_sprite_swap.py --species Dracky --png art.png --literal
  python3 tools/build_sprite_swap.py --species 78 --probe
Env: BG_INDEX (default 1), BODY_INDICES (default '2,3' light..dark)
"""
import os, sys, json, argparse

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from dwm import sprite_codec as sc

ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
BATTLE_TABLE = 0x2B9F
FIELD = 48
FIELD_TILES = (6, 6)
DECLEN = 36 * 16

# end-of-bank zero block label that the placed stream must preserve
BANK_FREE_ANCHOR = {
    0x36: 'Jump_036_7c0d',
}


def species_id(s):
    if s.isdigit():
        return int(s)
    d = json.load(open(os.path.join(REPO, 'extracted', 'monsters_full.json')))
    ms = d if isinstance(d, list) else list(d.values())
    for m in ms:
        if isinstance(m, dict) and m.get('name', '').lower() == s.lower():
            return m['id']
    sys.exit(f'Unknown species: {s}')


def battle_gfxid(rom, sp):
    o = BATTLE_TABLE + sp * 2
    return rom[o] | (rom[o + 1] << 8)


def png_to_field(png_path, bg_index, body, probe=False):
    import numpy as np
    field = np.full((FIELD, FIELD), bg_index, dtype=int)
    if probe:
        for x in range(FIELD):
            field[:, x] = min(3, x // (FIELD // 4))
        return field
    from PIL import Image
    im = Image.open(png_path).convert('RGB')
    a = np.array(im); bg = tuple(int(v) for v in a[0, 0])
    mask = ~np.all(a == bg, axis=2)
    if mask.any():
        ys, xs = np.where(mask.any(1))[0], np.where(mask.any(0))[0]
        im = im.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
    im.thumbnail((32, 32), Image.NEAREST)
    canvas = Image.new('RGB', (32, 32), bg)
    canvas.paste(im, ((32 - im.width) // 2, (32 - im.height) // 2))
    ca = np.array(canvas)
    lum = 0.299 * ca[:, :, 0] + 0.587 * ca[:, :, 1] + 0.114 * ca[:, :, 2]
    isbg = np.all(ca == bg, axis=2)
    idxmap = np.zeros((32, 32), dtype=int)
    if (~isbg).any():
        fl = lum[~isbg]; lo, hi = fl.min(), fl.max(); n = len(body)
        for yy in range(32):
            for xx in range(32):
                if isbg[yy, xx]:
                    idxmap[yy, xx] = bg_index
                else:
                    t = (lum[yy, xx] - lo) / (hi - lo + 1e-6)
                    idxmap[yy, xx] = body[min(n - 1, int((1.0 - t) * n))]
    field[8:40, 8:40] = idxmap
    return field


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--species', required=True)
    ap.add_argument('--png')
    ap.add_argument('--payload', help='raw 576-byte 2bpp tile file (direct transplant)')
    ap.add_argument('--probe', action='store_true')
    ap.add_argument('--literal', action='store_true')
    ap.add_argument('--out', default=None)
    args = ap.parse_args()
    if not args.png and not args.probe and not args.payload:
        sys.exit('need --png, --payload, or --probe')

    rom = open(ROM, 'rb').read()
    sp = species_id(args.species)
    gid = battle_gfxid(rom, sp)
    bank, index, saddr, foff = sc.gfxid_stream_offset(rom, gid)
    print(f'species {sp}: battle gfx-ID ${gid:04x} -> bank ${bank:02x} entry {index} '
          f'(ptr ${0x4001 + index*2:04x}) stream ${saddr:04x}')
    if bank not in BANK_FREE_ANCHOR:
        sys.exit(f'No free-space anchor for bank ${bank:02x}; add one to BANK_FREE_ANCHOR.')

    bg_index = int(os.environ.get('BG_INDEX', '1'))
    body = [int(x) for x in os.environ.get('BODY_INDICES', '2,3').split(',')]
    if args.payload:
        payload = open(args.payload, 'rb').read()
        if len(payload) != DECLEN:
            sys.exit(f'--payload must be {DECLEN} bytes (got {len(payload)})')
    else:
        field = png_to_field(args.png, bg_index, body, probe=args.probe)
        grid = [[int(field[y, x]) for x in range(FIELD)] for y in range(FIELD)]
        payload = sc.indices_to_tiles(grid, *FIELD_TILES)
    assert len(payload) == DECLEN, len(payload)
    stream = sc.encode_safe(payload, literal_only=args.literal)
    print(f'  {"literal" if args.literal else "greedy"} stream {len(stream)} B (declen {len(payload)})')

    clean = os.path.join(REPO, 'disassembly', f'bank_{bank:03x}.asm')
    out_path = args.out or os.path.join(REPO, 'patches', f'bank_{bank:03x}.asm')
    lines = open(clean).read().split('\n')
    label = f'CustomBattleSprite_sp{sp}'

    want = f'dw ${saddr:04x}'
    for i, l in enumerate(lines):
        if want in l.lower() and f'entry {index}' in l.lower():
            lines[i] = (f'    dw {label}                ; Entry {index} (idx ${index:02x}) '
                        f'sprite swap sp{sp} (was ${saddr:04x})')
            break
    else:
        sys.exit(f'pointer entry "{want} ; Entry {index}" not found in {clean}')

    anchor = BANK_FREE_ANCHOR[bank] + ':'
    J = next(i for i, l in enumerate(lines) if l.strip() == anchor)

    def zc(l):
        s = l.strip()
        if s == 'nop': return 1
        if s == '': return 0
        if s.startswith('db '):
            t = [x.strip() for x in s[3:].split(',')]
            return len(t) if all(x == '$00' for x in t) else None
        return None

    Z = J; total = 0; i = J - 1
    while i >= 0:
        c = zc(lines[i])
        if c is None: break
        total += c; Z = i; i -= 1
    assert ':' not in ''.join(lines[Z:J]), 'label inside target zero block'
    if total < len(stream):
        sys.exit(f'free block {total} B < stream {len(stream)} B')

    db = [f'{label}:  ; sprite swap sp{sp} battle ({len(stream)} B)']
    for o in range(0, len(stream), 16):
        db.append('    db ' + ', '.join(f'${b:02x}' for b in stream[o:o + 16]))
    db.append(f'    ds {total - len(stream)}   ; zero fill (preserve {anchor})')
    open(out_path, 'w').write('\n'.join(lines[:Z] + db + lines[J:]) + '\n')
    print(f'  wrote {out_path}: entry {index} repointed; free {total}->{total-len(stream)} B')


if __name__ == '__main__':
    main()
