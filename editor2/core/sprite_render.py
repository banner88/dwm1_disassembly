"""sprite_render.py — monster battle poses and walking frames as pixels
(ROADMAP P3.10 part 1, S106). Pure Python: the GUI turns the rows into
QImages, tests compare them as data.

Sources (no ROM needed at edit time):
  * original species: `extracted/monster_sprites.json` (the decoded art —
    regenerated S106 with the corrected LZ decoder, == the game's own
    decompressor for all 442 streams, PyBoy-measured), battle palettes
    `extracted/monster_palettes.json`, walking layouts + attr bytes
    `extracted/monster_follower_layouts.json` / `follower_layouts.json`.
  * the project's new species: their art streams (assets/species/*.bin),
    battle palette, OBJ palette and walk donor from custom.species.

Battle: 48x48, BG palette [c0, c1 = cream backdrop, c2, c3] (MONSTER_DATA).
Walking: the follower render engine's metasprite lists (MONSTER_DATA "Follower
/ walking-sprite render system"): entries (dy, dx, tile, xflip) relative to the
anchor; OAM attr = species attr XOR entry attr; idx0 transparent; colours =
one of the 8 global OBJ palettes ($17:$5615). LEFT = RIGHT drawn X-flipped.
"""

import json
import os

from editor2.core.sheet_import import OBJ_PALETTES, rgb888

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FRAMES = ('down_A', 'down_B', 'right_A', 'right_B', 'up_A', 'up_B')
_CACHE = {}


def _load(name):
    if name not in _CACHE:
        try:
            _CACHE[name] = json.load(open(os.path.join(REPO, 'extracted', name)))
        except (OSError, ValueError):
            _CACHE[name] = None
    return _CACHE[name]


def tiles_to_grid(data, cols, rows):
    """2bpp tiles (row-major cols x rows) -> [[index]]."""
    g = [[0] * (cols * 8) for _ in range(rows * 8)]
    for t in range(cols * rows):
        tx, ty = (t % cols) * 8, (t // cols) * 8
        for r in range(8):
            lo, hi = data[t * 16 + 2 * r], data[t * 16 + 2 * r + 1]
            for c in range(8):
                g[ty + r][tx + c] = ((lo >> (7 - c)) & 1) | (((hi >> (7 - c)) & 1) << 1)
    return g


def battle_rgb(tiles, palette):
    """576-byte battle payload + 4 RGB555 -> 48 rows of 48 (r, g, b)."""
    cols = [rgb888(w) for w in palette]
    return [[cols[v] for v in row] for row in tiles_to_grid(tiles, 6, 6)]


def vanilla_battle(sid):
    ms, pal = _load('monster_sprites.json'), _load('monster_palettes.json')
    if not ms or not pal or str(sid) not in ms['monsters']:
        return None
    t = bytes.fromhex(ms['monsters'][str(sid)]['battle']['tile_bytes_hex'])
    if len(t) != 576:
        return None
    return battle_rgb(t, pal['monsters'][str(sid)]['colors'])


def layout_frames(layout_id):
    lay = _load('follower_layouts.json')
    if not lay:
        return None
    for L in lay['layouts']:
        if L['id'] == layout_id:
            return L['frames']
    return None


def species_layout_id(sid):
    m = _load('monster_follower_layouts.json')
    for e in (m or {}).get('monsters', []):
        if e['species'] == sid:
            return e.get('layout_id'), e.get('attr_base', 0)
    return None, 0


def follower_frames(tiles, layout, palette_idx, attr=0):
    """16-tile follower art + a layout's frames -> {frame: rows of RGBA}
    (None = transparent), each frame on a 24x24 canvas, anchor bottom-centre.
    `attr` = the species attr byte (bit5 X-flip, bit6 Y-flip — vanilla
    collectible species use 0; a new species' attr is clean)."""
    pal = [None] + [rgb888(w) + (255,) for w in OBJ_PALETTES[palette_idx & 7][1:]]
    tile = []
    for t in range(16):
        g = tiles_to_grid(tiles[t * 16:(t + 1) * 16], 1, 1)
        tile.append(g)
    out = {}
    W, H = 24, 24
    for fr in FRAMES:
        canvas = [[None] * W for _ in range(H)]
        for e in layout.get(fr) or []:
            xf = bool(e.get('xflip')) ^ bool(attr & 0x20)
            yf = bool(attr & 0x40)
            g = tile[e['tile'] & 15]
            ox, oy = e['dx'] + 12, e['dy'] + 24
            for r in range(8):
                for c in range(8):
                    v = g[7 - r if yf else r][7 - c if xf else c]
                    if v:
                        x, y = ox + c, oy + r
                        if 0 <= x < W and 0 <= y < H:
                            canvas[y][x] = pal[v]
        out[fr] = canvas
    out['left_A'] = [row[::-1] for row in out['right_A']]
    out['left_B'] = [row[::-1] for row in out['right_B']]
    return out


def vanilla_follower(sid):
    ms = _load('monster_sprites.json')
    lid, attr = species_layout_id(sid)
    if not ms or lid is None or str(sid) not in ms['monsters']:
        return None
    t = bytes.fromhex(ms['monsters'][str(sid)]['follower']['tile_bytes_hex'])
    lay = layout_frames(lid)
    if len(t) != 256 or not lay:
        return None
    return follower_frames(t, lay, attr & 7, attr & 0x60)


def project_species_art(project_dir, entry):
    """(battle rows, follower frames) of a custom.species entry."""
    from dwm.sprite_codec import decode
    b = entry.get('battle') or {}
    f = entry.get('follower') or {}
    battle = fol = None
    try:
        bt = decode(open(os.path.join(project_dir, b['art']), 'rb').read())
        pal = [int(str(x).replace('$', '0x'), 0) if isinstance(x, str) else int(x)
               for x in b['palette']]
        if len(bt) == 576:
            battle = battle_rgb(bt, pal)
    except (OSError, KeyError, ValueError, TypeError):
        pass
    try:
        ft = decode(open(os.path.join(project_dir, f['art']), 'rb').read())
        lid, _attr = species_layout_id(int(f.get('walks_like', 128)))
        lay = layout_frames(lid)
        if len(ft) == 256 and lay:
            fol = follower_frames(ft, lay, int(f.get('palette', 0)), 0)
    except (OSError, KeyError, ValueError, TypeError):
        pass
    return battle, fol


def payload_preview(battle_payload, battle_palette, follower_payload, follower_palette,
                    walks_like=128):
    """Previews straight from payloads (the sheet import, before anything is
    written)."""
    battle = battle_rgb(battle_payload, battle_palette) if battle_payload else None
    fol = None
    if follower_payload:
        lid, _ = species_layout_id(int(walks_like))
        lay = layout_frames(lid)
        if lay:
            fol = follower_frames(follower_payload, lay, follower_palette, 0)
    return battle, fol
