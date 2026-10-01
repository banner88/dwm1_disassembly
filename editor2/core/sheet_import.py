"""sheet_import.py — read a DWM2-style monster sprite sheet (ROADMAP P3.10, S106).

The sheets the user supplies (`All_DWM2_monsters.zip`: one PNG per family,
ripped by The IT) put each monster as ONE ENTRY:

    [battle pose]   [walk frames, 2 columns x 3 rows of 16x16]
                     row 0 = facing down  (a, b)
                     row 1 = facing sideways (a, b)
                     row 2 = facing up    (a, b)

on a flat background colour, entries scattered over the sheet, plus a credit
line of text. This module finds the entries (battle box + six frame boxes),
lets the editor move any box by hand, and converts an entry to the two art
payloads a new species needs (PROJECT_COMPILER §2.21):

  * battle: 48x48 = 36 tiles, 576 B, BG palette [c0, c1 = $6BFF cream
    backdrop (forced by the engine), c2, c3 = $0000 black] — the pose has FOUR
    colours: black, the cream (also drawn INSIDE the body: every original
    pose's white / cream highlights — S106 r2), and TWO free colours
    (MONSTER_DATA "battle palette"). The sheet background becomes the backdrop.
  * follower: 16 tiles, 256 B, packed for layout 0 (tools/build_follower_reassign
    pack_png_layout0: tiles 0-3 down-a, 4-7 side-a, 8-11 side-b, 12-15 up-a;
    down-b / up-b are the engine's mirror of a) — the bank-$11 layout donor
    128 (Armorpion) draws exactly this order (S105, MONSTER_DATA). Colours: 0
    = transparent, 1 / 2 / 3 = one of the 8 GLOBAL object palettes ($17:$5615:
    1 = cream skin, 2 = the palette's hue, 3 = near-black), picked by hue.

The proven reference is the S34 Gorbunok: its frames are the water sheet's
blue dragon (examples/follower_swap/gorbunok_frames.json, the same 572x381
PNG as water.png) — test_compiler checks that the reader finds those boxes.

Pure Python + Pillow (no numpy / scipy — the editor's own dependencies).
"""

import json

from PIL import Image

CELL = 16                    # a walk frame
BATTLE = 48                  # the battle tile field (6 x 6 tiles)
FRAME_KEYS = ('DOWN-a', 'DOWN-b', 'SIDE-a', 'SIDE-b', 'UP-a', 'UP-b')
LAYOUT0_ORDER = ('DOWN-a', 'SIDE-a', 'SIDE-b', 'UP-a')   # the 4 frames layout 0 stores
BACKDROP = 0x6BFF            # battle idx1 (forced)
BLACK = 0x0000               # battle idx3

# the 8 global OBJ palettes ($17:$5615, ObjectPalettes in disassembly/bank_017.asm;
# RGB555 words) — idx0 is transparent for sprites
OBJ_PALETTES = [
    (0x35AD, 0x4B7F, 0x009F, 0x0042),   # 0 red
    (0x35AD, 0x4B7F, 0x1720, 0x0042),   # 1 green
    (0x7C00, 0x4B7F, 0x7DAB, 0x0042),   # 2 blue
    (0x7C00, 0x4B7F, 0x02FF, 0x0042),   # 3 gold
    (0x36B9, 0x4B7F, 0x58B6, 0x0042),   # 4 purple
    (0x7C00, 0x4B7F, 0x420F, 0x0042),   # 5 grey
    (0x7C00, 0x4B7F, 0x021F, 0x0042),   # 6 orange
    (0x7C00, 0x4B7F, 0x2218, 0x0042),   # 7 brown
]
OBJ_PALETTE_NAMES = ['red', 'green', 'blue', 'gold', 'purple', 'grey', 'orange', 'brown']


def rgb555(c):
    """(r, g, b) 0-255 -> RGB555 word (the GBC's 5 bits per channel)."""
    r, g, b = c
    return (r >> 3) | (g >> 3) << 5 | (b >> 3) << 10


def rgb888(w):
    """RGB555 word -> (r, g, b) 0-255 as the editor shows it (x8)."""
    return ((w & 31) << 3, ((w >> 5) & 31) << 3, ((w >> 10) & 31) << 3)


def _lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


class Sheet:
    """A loaded sheet: pixels + background colour + found entries."""

    def __init__(self, path_or_image):
        im = path_or_image if isinstance(path_or_image, Image.Image) \
            else Image.open(path_or_image)
        self.im = im.convert('RGB')
        self.w, self.h = self.im.size
        self.px = list(self.im.getdata())
        self.bg = background(self)

    def at(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y * self.w + x]
        return self.bg

    def crop(self, box):
        """Pixels of box {x, y, w, h} as rows; outside the sheet = background."""
        return [[self.at(box['x'] + i, box['y'] + j) for i in range(box['w'])]
                for j in range(box['h'])]


def background(sheet):
    """The sheet's background = the most common colour on its border."""
    from collections import Counter
    w, h, px = sheet.w, sheet.h, sheet.px
    border = [px[x] for x in range(w)] + [px[(h - 1) * w + x] for x in range(w)] + \
             [px[y * w] for y in range(h)] + [px[y * w + w - 1] for y in range(h)]
    return Counter(border).most_common(1)[0][0]


# ---------------------------------------------------------------------------
# finding the entries
# ---------------------------------------------------------------------------

def _components(sheet, gap):
    """Clusters of non-background pixels: pixels closer than `gap` (Chebyshev)
    belong together. -> [[x0, y0, x1, y1, n]] (inclusive bounds)."""
    w, h, px, bg = sheet.w, sheet.h, sheet.px, sheet.bg
    fg = bytearray(1 if p != bg else 0 for p in px)
    seen = bytearray(w * h)
    out = []
    r = gap
    for start in range(w * h):
        if not fg[start] or seen[start]:
            continue
        seen[start] = 1
        stack = [start]
        x0 = x1 = start % w
        y0 = y1 = start // w
        n = 0
        while stack:
            i = stack.pop()
            n += 1
            x, y = i % w, i // w
            if x < x0: x0 = x
            if x > x1: x1 = x
            if y < y0: y0 = y
            if y > y1: y1 = y
            for yy in range(max(0, y - r), min(h, y + r + 1)):
                base = yy * w
                for xx in range(max(0, x - r), min(w, x + r + 1)):
                    j = base + xx
                    if fg[j] and not seen[j]:
                        seen[j] = 1
                        stack.append(j)
        out.append([x0, y0, x1, y1, n])
    return out


def _occupied(sheet, x0, y0, x1, y1, axis):
    """Per column (axis 0) / row (axis 1) of the rectangle: any foreground?"""
    bg = sheet.bg
    if axis == 0:
        return [any(sheet.at(x, y) != bg for y in range(y0, y1 + 1)) for x in range(x0, x1 + 1)]
    return [any(sheet.at(x, y) != bg for x in range(x0, x1 + 1)) for y in range(y0, y1 + 1)]


def _gaps(occ):
    """Runs of empty positions strictly inside: [(start, length)]."""
    out, k = [], 0
    while k < len(occ):
        if not occ[k]:
            s = k
            while k < len(occ) and not occ[k]:
                k += 1
            if s > 0 and k < len(occ):
                out.append((s, k - s))
        else:
            k += 1
    return out


def _split(occ, parts):
    """Split a run of positions into `parts` pieces at the widest inner gaps
    (cell pitch ~18 px: frames are 16 wide with 1-3 px between). -> list of
    (start, end) inclusive, or None."""
    gaps = sorted(_gaps(occ), key=lambda g: (-g[1], g[0]))[:parts - 1]
    if len(gaps) < parts - 1:
        return None
    cuts = sorted(gaps)
    out, s = [], 0
    for g0, gl in cuts:
        out.append((s, g0 - 1))
        s = g0 + gl
    out.append((s, len(occ) - 1))
    # trim empty edges of every piece
    res = []
    for a, b in out:
        while a <= b and not occ[a]:
            a += 1
        while b >= a and not occ[b]:
            b -= 1
        if a > b:
            return None
        res.append((a, b))
    return res


def _small_pieces(sheet, comps):
    """Frame candidates: clusters that fit a 16x16 cell. Tiny bits (sparkles,
    a detached tail tip) join the nearest candidate when the union still
    fits; a cluster up to 2 cells wide / 3 high is split at its inner gaps
    (two frames drawn 1-2 px apart merge at the cluster distance)."""
    small, tiny, big = [], [], []
    for c in comps:
        x0, y0, x1, y1, n = c
        w, h = x1 - x0 + 1, y1 - y0 + 1
        if w <= CELL and h <= CELL:
            (tiny if (w <= 6 and h <= 6) else small).append(list(c))
        else:
            big.append(c)
    rest = []
    for c in big:
        x0, y0, x1, y1, _n = c
        w, h = x1 - x0 + 1, y1 - y0 + 1
        pieces = None
        if w <= 2 * CELL + 6 and h <= 3 * CELL + 10:
            cols = _split(_occupied(sheet, x0, y0, x1, y1, 0), max(1, -(-w // (CELL + 1))))
            rows = _split(_occupied(sheet, x0, y0, x1, y1, 1), max(1, -(-h // (CELL + 1))))
            if cols and rows and all(b - a < CELL for a, b in cols) and \
                    all(b - a < CELL for a, b in rows):
                pieces = []
                for a, b in cols:
                    for r0, r1 in rows:
                        sub = _occupied(sheet, x0 + a, y0 + r0, x0 + b, y0 + r1, 0)
                        if any(sub):
                            pieces.append([x0 + a, y0 + r0, x0 + b, y0 + r1, 0])
        if pieces and len(pieces) > 1:
            small += pieces
        else:
            rest.append(c)
    for t in tiny:
        best = None
        for s in small:
            ux0, uy0 = min(s[0], t[0]), min(s[1], t[1])
            ux1, uy1 = max(s[2], t[2]), max(s[3], t[3])
            if ux1 - ux0 + 1 <= CELL and uy1 - uy0 + 1 <= CELL:
                d = max(0, t[0] - s[2], s[0] - t[2]) + max(0, t[1] - s[3], s[1] - t[3])
                if d <= 4 and (best is None or d < best[0]):
                    best = (d, s)
        if best:
            s = best[1]
            s[0], s[1] = min(s[0], t[0]), min(s[1], t[1])
            s[2], s[3] = max(s[2], t[2]), max(s[3], t[3])
    return small, rest


def _centre(c):
    return ((c[0] + c[2]) / 2.0, (c[1] + c[3]) / 2.0)


def _grids(small):
    """Groups of six frame candidates on a 2 x 3 grid (pitch 14-30 px):
    -> [[c00, c01, c10, c11, c20, c21]] (row-major: row = facing)."""
    used = set()
    out = []
    order = sorted(range(len(small)), key=lambda i: (_centre(small[i])[1], _centre(small[i])[0]))

    def near(cx, cy, tol):
        best = None
        for j in range(len(small)):
            if j in used or j in taken:
                continue
            x, y = _centre(small[j])
            d = abs(x - cx) + abs(y - cy)
            if abs(x - cx) <= tol and abs(y - cy) <= tol and (best is None or d < best[0]):
                best = (d, j)
        return best[1] if best else None

    for i in order:
        if i in used:
            continue
        taken = {i}
        x0, y0 = _centre(small[i])
        # right neighbour: same row, 14-30 px right
        right = None
        for dx in range(14, 31):
            j = near(x0 + dx, y0, 4)
            if j is not None and abs(_centre(small[j])[0] - x0) >= 14:
                right = j
                break
        if right is None:
            continue
        taken.add(right)
        px = _centre(small[right])[0] - x0
        cells = [i, right]
        ok = True
        cy = y0
        for _row in (1, 2):
            down = None
            for dy in range(14, 31):
                j = near(x0, cy + dy, 4)
                if j is not None and _centre(small[j])[1] - cy >= 12:
                    down = j
                    break
            if down is None:
                ok = False
                break
            taken.add(down)
            dcx, dcy = _centre(small[down])
            j2 = near(dcx + px, dcy, 5)
            if j2 is None:
                ok = False
                break
            taken.add(j2)
            cells += [down, j2]
            cy = dcy
        if ok:
            used |= taken
            out.append([small[k] for k in cells])
    return out


def _grid_boxes(cells):
    """Six 16x16 boxes from six grouped candidates. One x per COLUMN (centred
    on the column's content over all three rows) and one y per ROW (the row's
    two frames bottom-aligned together) — keeps the a/b bob and sway the
    artist drew."""
    boxes = {}
    xs = []
    for col in (0, 1):
        cs = cells[col::2]
        a, b = min(c[0] for c in cs), max(c[2] for c in cs)
        xs.append(a + ((b - a + 1) - CELL) // 2)
    for r, key in enumerate(('DOWN', 'SIDE', 'UP')):
        cs = cells[2 * r:2 * r + 2]
        y = max(c[3] for c in cs) - CELL + 1
        for k, ab in enumerate(('a', 'b')):
            boxes[f'{key}-{ab}'] = {'x': xs[k], 'y': y, 'w': CELL, 'h': CELL}
    return boxes


def find_entries(sheet):
    """-> [{'battle': box|None, 'frames': {key: box}|None}] in reading order.

    Frames: clusters (2-px merge distance) that fit a 16x16 cell, grouped six
    at a time on a 2 x 3 grid (pitch 14-30 px — the sheets space frames 1-6
    px apart). A pose = the nearest larger cluster LEFT of a grid on the same
    band. Text (credit line, captions) = wide short clusters, dropped. What
    the detector gets wrong, the user fixes by dragging the boxes (editor)."""
    comps = _components(sheet, 2)
    small, rest = _small_pieces(sheet, comps)
    grids = _grids(small)
    blocks = []
    for cells in grids:
        x0 = min(c[0] for c in cells)
        y0 = min(c[1] for c in cells)
        x1 = max(c[2] for c in cells)
        y1 = max(c[3] for c in cells)
        blocks.append(([x0, y0, x1, y1, 0], _grid_boxes(cells)))
    others = []
    for c in rest:
        x0, y0, x1, y1, n = c
        w, h = x1 - x0 + 1, y1 - y0 + 1
        if w >= 12 and h >= 12 and n >= 60 and not (h <= 14 and w > 3 * h):
            others.append(c)
    used = set()
    entries = []
    for c, fb in blocks:
        bx0, by0, bx1, by1, _ = c
        best = None
        for k, o in enumerate(others):
            if k in used:
                continue
            ox0, oy0, ox1, oy1, _ = o
            dx = bx0 - ox1
            ov = min(by1, oy1) - max(by0, oy0)
            if 0 < dx <= 32 and ov > 0:
                if best is None or dx < best[0]:
                    best = (dx, k)
        battle = None
        if best is not None:
            used.add(best[1])
            ox0, oy0, ox1, oy1, _ = others[best[1]]
            battle = {'x': ox0, 'y': oy0, 'w': ox1 - ox0 + 1, 'h': oy1 - oy0 + 1}
        entries.append({'battle': battle, 'frames': fb})
    for k, o in enumerate(others):
        if k not in used and (o[2] - o[0] + 1) >= 20 and (o[3] - o[1] + 1) >= 20:
            ox0, oy0, ox1, oy1, _ = o
            entries.append({'battle': {'x': ox0, 'y': oy0, 'w': ox1 - ox0 + 1,
                                       'h': oy1 - oy0 + 1}, 'frames': None})

    def key(e):
        b = e['battle'] or next(iter(e['frames'].values()))
        return (b['y'] // 40, b['x'])
    entries.sort(key=key)
    return entries


# ---------------------------------------------------------------------------
# converting an entry
# ---------------------------------------------------------------------------

def _kmeans1d(values, weights, k):
    """Deterministic 1-D k-means (sorted values, weighted). -> k centres."""
    vs = sorted(set(values))
    if len(vs) <= k:
        cs = vs + [vs[-1]] * (k - len(vs)) if vs else [0] * k
        return sorted(cs)
    cs = [vs[int(i * (len(vs) - 1) / (k - 1))] for i in range(k)]
    for _ in range(30):
        acc = [[0.0, 0.0] for _ in range(k)]
        for v, wt in zip(values, weights):
            j = min(range(k), key=lambda t: abs(v - cs[t]))
            acc[j][0] += v * wt
            acc[j][1] += wt
        new = [acc[j][0] / acc[j][1] if acc[j][1] else cs[j] for j in range(k)]
        if new == cs:
            break
        cs = new
    return sorted(cs)


def _hist(pixels, bg):
    from collections import Counter
    return Counter(p for row in pixels for p in row if p != bg)


def follower_colors(sheet, frames):
    """{rgb: 1|2|3} for every colour in the four stored frames (light -> 1,
    mid -> 2, dark -> 3, by weighted luminance clusters over ALL four frames
    so every frame uses the same mapping) + the suggested OBJ palette."""
    hist = {}
    for key in LAYOUT0_ORDER:
        for c, n in _hist(sheet.crop(frames[key]), sheet.bg).items():
            hist[c] = hist.get(c, 0) + n
    if not hist:
        return {}, 0
    cols = list(hist)
    lums = [_lum(c) for c in cols]
    cent = _kmeans1d(lums, [hist[c] for c in cols], 3)     # dark, mid, light
    cmap = {}
    for c, L in zip(cols, lums):
        j = min(range(3), key=lambda t: abs(L - cent[t]))
        cmap[c] = 3 - j                                      # 0 dark -> idx 3
    # palette: the mid group's average colour vs each palette's hue (idx 2)
    mid = [(c, hist[c]) for c in cols if cmap[c] == 2] or [(c, hist[c]) for c in cols]
    tot = sum(n for _c, n in mid)
    avg = tuple(sum(c[i] * n for c, n in mid) / tot for i in range(3))
    best = min(range(8), key=lambda p: sum((a - b) ** 2 for a, b in
                                           zip(avg, rgb888(OBJ_PALETTES[p][2]))))
    return cmap, best


def follower_payload(sheet, frames, cmap=None):
    """-> 256-byte 2bpp follower payload (layout 0 tile order), UN-FLIPPED
    (MONSTER_DATA follower section: orientation comes from the attr byte)."""
    if cmap is None:
        cmap, _p = follower_colors(sheet, frames)
    tiles = []
    for key in LAYOUT0_ORDER:
        px = sheet.crop(frames[key])
        idx = [[0 if p == sheet.bg else cmap.get(p, 3) for p in row] for row in px]
        for ty in (0, 8):
            for tx in (0, 8):
                tiles.append([r[tx:tx + 8] for r in idx[ty:ty + 8]])
    return _pack_tiles(tiles)


def _pack_tiles(tiles):
    out = bytearray()
    for t in tiles:
        for row in t:
            lo = hi = 0
            for v in row:
                lo = (lo << 1) | (v & 1)
                hi = (hi << 1) | ((v >> 1) & 1)
            out += bytes((lo, hi))
    return bytes(out)


def battle_fit(box):
    """How the pose fits the 48x48 field: (scale, w, h). Scale 1 unless the
    pose is bigger than the field (then it is shrunk, nearest-neighbour)."""
    w, h = box['w'], box['h']
    if w <= BATTLE and h <= BATTLE:
        return 1.0, w, h
    s = min(BATTLE / w, BATTLE / h)
    return s, max(1, int(w * s)), max(1, int(h * s))


def battle_field(sheet, box):
    """The pose placed in the 48x48 field: rows of rgb or None (= backdrop).
    Centred horizontally, standing 2 px above the bottom row — where the
    original poses stand (S106, all 215 with the corrected decoder: 115 at
    2 px, 67 at 0-1, the rest higher; centre x 23-24)."""
    s, w, h = battle_fit(box)
    src = sheet.crop(box)
    field = [[None] * BATTLE for _ in range(BATTLE)]
    ox = (BATTLE - w) // 2
    oy = BATTLE - h - min(2, BATTLE - h)
    for y in range(h):
        for x in range(w):
            sx = min(box['w'] - 1, int(x / s)) if s != 1 else x
            sy = min(box['h'] - 1, int(y / s)) if s != 1 else y
            p = src[sy][sx]
            if p != sheet.bg:
                field[oy + y][ox + x] = p
    return field


CREAM_RGB = rgb888(BACKDROP)          # (248, 248, 208)
BLACK_RGB = (0, 0, 0)


def _cdist(a, b):
    """Colour distance (weighted RGB — green counts most, blue least)."""
    return 3 * (a[0] - b[0]) ** 2 + 4 * (a[1] - b[1]) ** 2 + 2 * (a[2] - b[2]) ** 2


def battle_colors(sheet, box):
    """Suggested battle palette: {rgb: idx} and [c0, c1, c2, c3] RGB555.

    A battle pose has FOUR colours inside its body, not three: c1 is the
    cream backdrop ($6BFF, forced by the engine) and the original poses draw
    their white / cream highlights with it (all 215 have enclosed cream
    pixels — S106 r2, user: Goldhorn's white sword edge had gone gold), c3 is
    black, c0 / c2 are free. Every sheet colour goes to the nearest of
    {black, cream, c0, c2}; c0 / c2 are fitted to the colours they get
    (weighted k-means with the two fixed centres; seeded with the two most
    used colours that are neither black-ish nor white-ish). A sheet with
    black + white + 2 colours is reproduced exactly; more colours merge into
    the nearest."""
    field = battle_field(sheet, box)
    from collections import Counter
    hist = Counter(p for row in field for p in row if p is not None)
    if not hist:
        return {}, [0x7FFF, BACKDROP, 0x7FFF, BLACK]
    cols = sorted(hist, key=lambda c: (-hist[c], c))
    fixed = {3: BLACK_RGB, 1: CREAM_RGB}
    mids = [c for c in cols if min(_cdist(c, BLACK_RGB), _cdist(c, CREAM_RGB)) > 3 * 48 ** 2]
    seeds = (mids + [c for c in cols if c not in mids])[:2]
    while len(seeds) < 2:
        seeds.append(seeds[-1] if seeds else (128, 128, 128))
    free = {0: tuple(map(float, seeds[0])), 2: tuple(map(float, seeds[1]))}
    cmap = {}
    for _ in range(40):
        cent = {**fixed, **free}
        cmap = {c: min(cent, key=lambda k: (_cdist(c, cent[k]), k)) for c in cols}
        new = {}
        for k in (0, 2):
            mem = [c for c in cols if cmap[c] == k]
            if mem:
                n = sum(hist[c] for c in mem)
                new[k] = tuple(sum(c[i] * hist[c] for c in mem) / n for i in range(3))
            else:
                new[k] = free[k]
        if new == free:
            break
        free = new
    pal = [rgb555(tuple(int(round(v)) for v in free[0])), BACKDROP,
           rgb555(tuple(int(round(v)) for v in free[2])), BLACK]
    # keep the convention c0 = the darker of the two free colours
    if _lum(rgb888(pal[0])) > _lum(rgb888(pal[2])):
        pal[0], pal[2] = pal[2], pal[0]
        cmap = {c: {0: 2, 2: 0}.get(k, k) for c, k in cmap.items()}
    return cmap, pal


def battle_payload(sheet, box, cmap=None):
    """-> 576-byte 2bpp battle payload (36 tiles, row-major 6 x 6 — the order
    tools/bake_follower_overflow.pack_battle used for the in-game-proven
    Gorbunok) with the backdrop on idx 1 EVERYWHERE outside the pose (the
    whole field, not just the pose's box — MONSTER_DATA 'gotcha')."""
    if cmap is None:
        cmap, _pal = battle_colors(sheet, box)
    field = battle_field(sheet, box)
    idx = [[1 if p is None else cmap.get(p, 3) for p in row] for row in field]
    tiles = []
    for ty in range(0, BATTLE, 8):
        for tx in range(0, BATTLE, 8):
            tiles.append([r[tx:tx + 8] for r in idx[ty:ty + 8]])
    return _pack_tiles(tiles)


def literal_stream(payload):
    """The LZ stream the compiler stores: literal (marker-free) — 3 bytes
    larger than the payload, trivially decodable, the form every new species
    has used since S34."""
    from dwm.sprite_codec import encode_safe
    return encode_safe(payload, literal_only=True)


def entry_json(entry):
    """The boxes as plain data (custom.species[].source)."""
    return json.loads(json.dumps(entry))
