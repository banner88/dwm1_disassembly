#!/usr/bin/env python3
"""
extract_monster_sprites.py — GFX-1 extraction: the editor's graphics asset layer.

Decodes every monster's BATTLE and FOLLOWER sprite from the ROM into:
  * extracted/monster_sprites.json  — manifest: species -> {name, battle, follower}
      each with gfx-ID, bank, index, stream addr/len, declen, tile count, and the
      decoded 2bpp tile bytes (hex) so the data is regenerable without the PNGs.
  * extracted/monster_sprites/<id>_<name>_battle.png   (optional, --png)
  * extracted/monster_sprites/<id>_<name>_follower.png (optional, --png)

Addressing (verified, see MONSTER_DATA.md "Monster sprite graphics system"):
  battle   gfx-ID = [$00:$2B9F + species*2]      (MonsterBattleGfxTable)
  follower gfx-ID = [$01:$49DF + (species+$10)*2] (ScreenTransDataTable)
  gfx-ID -> $<bank>:$4001 + index*2 -> LZ stream -> dwm.sprite_codec.decode

EXTENSION-AWARE: species count is a parameter (--count, default 221). Nothing here
hardcodes 221 except the default; an editor that adds monsters can raise it.

PNGs render with a neutral 4-grey ramp by default (palette is a separate subsystem,
GFX-2). Pass --battle-palette to use Dracky's probe-verified battle palette for a
truer preview. Tile grids: battle 576 B = 36 tiles = 6x6 (48x48 px);
follower 256 B = 16 tiles = 4x4 (32x32 px). Grids are derived from the tile count;
non-standard counts fall back to an N-wide strip.

Usage:
  python3 tools/extract_monster_sprites.py            # manifest only
  python3 tools/extract_monster_sprites.py --png      # + PNGs
  python3 tools/extract_monster_sprites.py --species 8,53,78 --png   # subset
"""
import os, sys, json, argparse

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from dwm import sprite_codec as sc

ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
OUT_JSON = os.path.join(REPO, 'extracted', 'monster_sprites.json')
OUT_PNG_DIR = os.path.join(REPO, 'extracted', 'monster_sprites')

BATTLE_TABLE = 0x2B9F                         # ROM0
FOLLOWER_TABLE = 0x01 * 0x4000 + (0x49DF - 0x4000)
FOLLOWER_INDEX_BIAS = 0x10                     # entries 0..$F are screen-trans

GREY = [(248, 248, 248), (168, 168, 168), (88, 88, 88), (8, 8, 8)]
# Dracky battle palette (probe-verified): 0=red 1=white/backdrop 2=gold/brown 3=black
DRACKY_BATTLE = [(200, 44, 44), (248, 248, 248), (176, 128, 48), (24, 24, 24)]


def load_names(count):
    path = os.path.join(REPO, 'extracted', 'monsters_full.json')
    names = {}
    if os.path.exists(path):
        d = json.load(open(path))
        ms = d if isinstance(d, list) else list(d.values())
        for m in ms:
            if isinstance(m, dict) and 'id' in m:
                names[m['id']] = m.get('name', f'sp{m["id"]}')
    return [names.get(i, f'sp{i}') for i in range(count)]


def battle_gfxid(rom, sp):
    o = BATTLE_TABLE + sp * 2
    return rom[o] | (rom[o + 1] << 8)


def follower_gfxid(rom, sp):
    o = FOLLOWER_TABLE + (sp + FOLLOWER_INDEX_BIAS) * 2
    return rom[o] | (rom[o + 1] << 8)


def grid_for(tile_count):
    """Pick a near-square tile grid (cols, rows) for a tile count."""
    table = {36: (6, 6), 16: (4, 4), 64: (8, 8), 9: (3, 3), 4: (2, 2), 25: (5, 5)}
    if tile_count in table:
        return table[tile_count]
    # fall back: widest factor <= sqrt
    import math
    for c in range(int(math.isqrt(tile_count)), 0, -1):
        if tile_count % c == 0:
            return (tile_count // c, c)
    return (tile_count, 1)


def decode_sprite(rom, gfxid):
    bank, index, saddr, foff = sc.gfxid_stream_offset(rom, gfxid)
    stream = sc.read_stream(rom, foff)
    payload = sc.decode(stream)
    tiles = len(payload) // 16
    cols, rows = grid_for(tiles)
    return {
        'gfx_id': f'${gfxid:04x}',
        'bank': f'${bank:02x}',
        'index': f'${index:02x}',
        'stream_addr': f'${saddr:04x}',
        'stream_len': len(stream),
        'declen': len(payload),
        'tiles': tiles,
        'grid': [cols, rows],
        'tile_bytes_hex': payload.hex(),
    }, payload, (cols, rows)


def save_png(path, payload, grid, palette):
    from PIL import Image
    cols, rows = grid
    idx = sc.tiles_to_indices(payload, cols, rows)
    h, w = rows * 8, cols * 8
    im = Image.new('RGB', (w, h))
    for y in range(h):
        for x in range(w):
            im.putpixel((x, y), palette[idx[y][x]])
    im.resize((w * 4, h * 4), Image.NEAREST).save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--count', type=int, default=221, help='species count (extension knob)')
    ap.add_argument('--species', type=str, default=None, help='comma list of ids (subset)')
    ap.add_argument('--png', action='store_true', help='also write PNGs')
    ap.add_argument('--battle-palette', action='store_true',
                    help="render battle PNGs in Dracky's battle palette instead of greys")
    args = ap.parse_args()

    rom = open(ROM, 'rb').read()
    names = load_names(args.count)
    ids = (sorted(int(x) for x in args.species.split(',')) if args.species
           else range(args.count))

    if args.png:
        os.makedirs(OUT_PNG_DIR, exist_ok=True)

    manifest = {
        '_generator': 'tools/extract_monster_sprites.py (ROM data/DWM-original.gbc)',
        '_format': 'species -> {name, battle:{...}, follower:{...}}; tile_bytes_hex = '
                   'decoded 2bpp tiles (16 B/tile), regenerable without PNGs',
        '_count': args.count,
        'monsters': {},
    }
    bat_pal = DRACKY_BATTLE if args.battle_palette else GREY
    for sp in ids:
        name = names[sp] if sp < len(names) else f'sp{sp}'
        entry = {'name': name}
        for kind, gid in (('battle', battle_gfxid(rom, sp)),
                          ('follower', follower_gfxid(rom, sp))):
            info, payload, grid = decode_sprite(rom, gid)
            entry[kind] = info
            if args.png:
                pal = bat_pal if kind == 'battle' else GREY
                safe = ''.join(c if c.isalnum() else '_' for c in name)
                save_png(os.path.join(OUT_PNG_DIR, f'{sp:03d}_{safe}_{kind}.png'),
                         payload, grid, pal)
        manifest['monsters'][str(sp)] = entry

    json.dump(manifest, open(OUT_JSON, 'w'), indent=1)
    print(f'Wrote {OUT_JSON} ({len(manifest["monsters"])} monsters'
          f'{", + PNGs in extracted/monster_sprites/" if args.png else ""}).')


if __name__ == '__main__':
    main()
