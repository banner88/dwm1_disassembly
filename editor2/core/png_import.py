"""png_import.py — background tiles from a PNG (a DWM2 map rip, a mock-up)
into a DWM1 room (S96). Pure Python + PIL, no Qt.

The author's workflow (user S96): open a PNG, line the 16-px walk-cell grid
up with the art (panels of a rip sit at arbitrary offsets), block out what
must not be gridded (the rip's key-colour background, captions, other
panels), then import the chosen cells. What this module owns:

  * GRID     — `Region`s, each with its own offset (ox, oy) in 0..15. A
               cell is the 16x16 block at (x, y) with x = ox (mod 16) inside
               the region's rectangle. `detect_regions` proposes one region
               per connected panel of non-key pixels (a rip's panels are
               separated by key colour) with the offset taken from the
               panel's top-left corner; the author nudges from there.
  * MASK     — cells containing a key-colour pixel are never gridded
               (automatic); the author's mask set adds more by cell origin.
  * FIT      — every 8x8 subtile must become 4 palette indices under the
               DWM1 engine's palette rules: a room has 4 BG palettes (slots
               0-3; 4-7 are system — KEY_LESSONS S8) and the engine FORCES
               colour 1 = $6BFF (248,248,208) and colour 3 = $0000 (black)
               in every palette at runtime (KEY_LESSONS S7/S39), so each
               slot contributes exactly TWO free colours (0 and 2). DWM2 art
               uses black + three colours per palette, so one colour per
               palette is folded onto the forced cream — `fit_palettes`
               picks which (the one closest to cream) and chooses the 4
               slot palettes that cover the most subtiles exactly; the rest
               map to their nearest colours. Locked slots (the room's
               existing palettes the author keeps) are honoured as-is.
  * ENCODE   — subtile -> 2bpp (16 bytes); identical graphics share ONE
               sheet slot whatever palette they are drawn with (the DWM1
               idiom: the gate trees and dunes are the same tiles on two
               palettes — GATE_GENERATION §7.2).

Nothing here touches project.json; `Document.import_png_cells` (document.py)
places the result into a room's tileset / palette / metatiles / layout.
"""

from dataclasses import dataclass, field

from PIL import Image

CELL = 16
SUB = 8
CREAM = (248, 248, 208)          # $6BFF, forced colour 1
BLACK = (0, 0, 0)                # $0000, forced colour 3
FORCED_IDX = {1: CREAM, 3: BLACK}
FREE_IDX = (0, 2)


# --------------------------------------------------------------- colours
def to555(rgb):
    r, g, b = rgb
    return (r >> 3) | ((g >> 3) << 5) | ((b >> 3) << 10)


def from555(v):
    return ((v & 31) * 8, ((v >> 5) & 31) * 8, ((v >> 10) & 31) * 8)


def snap(rgb):
    """Nearest exactly-representable GBC colour (8-bit value = 5-bit * 8)."""
    return tuple(min(248, (c + 4) // 8 * 8) for c in rgb)


def cdist(a, b):
    """'Redmean' perceptual distance squared — cheap and good enough to rank
    candidate colours (not a colour-science claim)."""
    rm = (a[0] + b[0]) / 2
    dr, dg, db = a[0] - b[0], a[1] - b[1], a[2] - b[2]
    return (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db


def luma(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


# ------------------------------------------------------------------ image
def load_rgb(path):
    return Image.open(path).convert('RGB')


def is_exact555(rgb):
    return rgb[0] % 8 == 0 and rgb[1] % 8 == 0 and rgb[2] % 8 == 0


def guess_key_colours(img):
    """Colours to treat as 'not art': the most common colour on the image
    border (rips frame everything in their key colour) plus every colour
    that is not exactly representable on the GBC (anti-aliased caption text
    and non-GBC key colours like (237,28,36))."""
    w, h = img.size
    px = img.load()
    border = {}
    for x in range(w):
        for y in (0, h - 1):
            border[px[x, y]] = border.get(px[x, y], 0) + 1
    for y in range(h):
        for x in (0, w - 1):
            border[px[x, y]] = border.get(px[x, y], 0) + 1
    keys = set()
    if border:
        keys.add(max(border, key=border.get))
    for _n, c in img.getcolors(1 << 24):
        if not is_exact555(c):
            keys.add(c)
    return keys


def key_mask(img, keys):
    """1-bit 'L' image: 255 where the pixel is a key colour."""
    w, h = img.size
    src = img.load()
    m = Image.new('L', (w, h), 0)
    dst = m.load()
    keys = set(keys)
    for y in range(h):
        for x in range(w):
            if src[x, y] in keys:
                dst[x, y] = 255
    return m


# ---------------------------------------------------------------- regions
@dataclass
class Region:
    x0: int
    y0: int
    x1: int          # exclusive
    y1: int
    ox: int          # grid offset, 0..15 (cells start at x = ox mod 16)
    oy: int
    name: str = ''

    def to_json(self):
        return {'rect': [self.x0, self.y0, self.x1, self.y1],
                'offset': [self.ox, self.oy], 'name': self.name}

    @classmethod
    def from_json(cls, d):
        x0, y0, x1, y1 = d['rect']
        ox, oy = d.get('offset', [0, 0])
        return cls(x0, y0, x1, y1, ox % CELL, oy % CELL, d.get('name', ''))

    def cell_origins(self):
        """Top-left pixel of every whole 16x16 cell inside the region."""
        sx = self.x0 + ((self.ox - self.x0) % CELL)
        sy = self.y0 + ((self.oy - self.y0) % CELL)
        out = []
        for y in range(sy, self.y1 - CELL + 1, CELL):
            for x in range(sx, self.x1 - CELL + 1, CELL):
                out.append((x, y))
        return out

    def contains(self, x, y):
        return self.x0 <= x < self.x1 and self.y0 <= y < self.y1


def detect_regions(img, keys, min_px=16 * 16):
    """Connected panels of non-key pixels (4-connected), by run-length
    union-find (fast in pure Python on rip-sized images). Returns Regions
    sorted top-to-bottom, left-to-right, each with offset = its own top-left
    corner mod 16 (a rip panel starts on a map metatile boundary)."""
    w, h = img.size
    px = img.load()
    keys = set(keys)
    parent = []

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[rb] = ra

    runs = []            # (y, x0, x1, id)
    prev = []
    for y in range(h):
        cur = []
        x = 0
        while x < w:
            if px[x, y] in keys:
                x += 1
                continue
            s = x
            while x < w and px[x, y] not in keys:
                x += 1
            rid = len(parent)
            parent.append(rid)
            cur.append((s, x, rid))
            runs.append((y, s, x, rid))
        # union with overlapping runs of the previous row
        i = j = 0
        while i < len(prev) and j < len(cur):
            a0, a1, aid = prev[i]
            b0, b1, bid = cur[j]
            if a0 < b1 and b0 < a1:
                union(aid, bid)
            if a1 < b1:
                i += 1
            else:
                j += 1
        prev = cur
    boxes = {}
    for y, s, e, rid in runs:
        r = find(rid)
        b = boxes.get(r)
        if b is None:
            boxes[r] = [s, y, e, y + 1, e - s]
        else:
            b[0] = min(b[0], s)
            b[1] = min(b[1], y)
            b[2] = max(b[2], e)
            b[3] = max(b[3], y + 1)
            b[4] += e - s
    regs = []
    for b in boxes.values():
        if b[4] < min_px or (b[2] - b[0]) < CELL or (b[3] - b[1]) < CELL:
            continue
        regs.append(Region(b[0], b[1], b[2], b[3], b[0] % CELL, b[1] % CELL))
    regs.sort(key=lambda r: (r.y0 // 32, r.x0))
    for i, r in enumerate(regs):
        r.name = f'panel {i + 1}'
    return regs


def best_offset(img, region, keys, masked=()):
    """Offset (ox, oy) that minimises the number of DISTINCT 8x8 graphics in
    the region's valid cells — the true grid makes repeated map tiles line
    up, a wrong one smears them (ties -> the region's corner). Advisory: the
    author's eye decides (user S96)."""
    best = None
    for oy in range(0, CELL, SUB):
        for ox in range(0, CELL, SUB):
            r = Region(region.x0, region.y0, region.x1, region.y1,
                       (region.x0 + ox) % CELL, (region.y0 + oy) % CELL)
            cells = valid_cells(img, r, keys, masked)
            if not cells:
                continue
            uniq = set()
            for (x, y) in cells:
                for sy in (0, SUB):
                    for sx in (0, SUB):
                        uniq.add(img.crop((x + sx, y + sy, x + sx + SUB,
                                           y + sy + SUB)).tobytes())
            score = len(uniq) / max(1, len(cells))
            if best is None or score < best[0] - 1e-9:
                best = (score, r.ox, r.oy)
    return (best[1], best[2]) if best else (region.ox, region.oy)


def valid_cells(img, region, keys, masked=(), km=None):
    """Cells of `region` that contain no key-colour pixel and are not in the
    author's mask set (cell origins)."""
    km = km if km is not None else key_mask(img, keys)
    masked = set(map(tuple, masked))
    out = []
    for (x, y) in region.cell_origins():
        if (x, y) in masked:
            continue
        if km.crop((x, y, x + CELL, y + CELL)).getextrema()[1] == 0:
            out.append((x, y))
    return out


# -------------------------------------------------------------- subtiles
def subtile_pixels(img, x, y):
    """64 RGB tuples, row-major."""
    return list(img.crop((x, y, x + SUB, y + SUB)).getdata())


def cell_subtiles(img, x, y):
    """TL, TR, BL, BR pixel lists of the cell at (x, y)."""
    return [subtile_pixels(img, x + dx, y + dy)
            for dy, dx in ((0, 0), (0, SUB), (SUB, 0), (SUB, SUB))]


def requirement(pixels, cream_merge=True, nfree=2):
    """The free colours a subtile needs once black and cream take their
    forced indices: black -> idx3 exactly; the remaining colours need the two
    free indices. With more than two left, the one closest to cream is folded
    onto idx1 (when cream_merge) — DWM2 palettes are black + 3 colours.
    Returns (frozenset of needed free colours, overflow list)."""
    cols = {}
    for c in pixels:
        cols[c] = cols.get(c, 0) + 1
    rest = [c for c in cols if c != BLACK and (c != CREAM or nfree > 2)]
    if nfree > 2:
        rest.sort(key=lambda c: -cols[c])
        return frozenset(rest[:nfree]), rest[nfree:]
    if len(rest) > 2 and cream_merge and CREAM not in cols:
        # fold the colour nearest cream onto the forced index 1
        k = min(rest, key=lambda c: (cdist(c, CREAM), -luma(c)))
        rest.remove(k)
    rest.sort(key=lambda c: -cols[c])
    return frozenset(rest[:2]), rest[2:]


@dataclass
class Fit:
    palettes: list            # 4 x [c0, cream, c2, black] RGB tuples
    locked: list              # slot indices kept from the room
    assign: dict = field(default_factory=dict)   # subtile key -> slot
    exact: int = 0            # subtiles whose colours all exist in their slot
    total: int = 0
    error: float = 0.0        # summed per-pixel colour distance (approx.)


def _pal_cost(pixels, pal):
    cache = {}
    tot = 0.0
    for c in pixels:
        d = cache.get(c)
        if d is None:
            d = min(cdist(c, q) for q in pal)
            cache[c] = d
        tot += d
    return tot


def fit_palettes(subtiles, locked=None, n_slots=4, slots=None, nfree=2):
    """Choose palettes for `subtiles` (list of 64-pixel lists).

    locked: {slot: [c0, c1, c2, c3]} palettes that must stay as they are
    (the room's existing colours the author keeps). slots: the slot indices
    the import may define (default: every slot not locked, of 0..n_slots-1).
    Greedy weighted set cover over the subtiles' free-colour requirements,
    then every subtile goes to its cheapest slot. Deterministic."""
    locked = dict(locked or {})
    if slots is None:
        slots = [s for s in range(n_slots) if s not in locked]
    reqs = {}
    for px in subtiles:
        need, _ov = requirement(px, nfree=nfree)
        reqs[need] = reqs.get(need, 0) + 1
    # candidates: every 2-colour requirement, and every 1-colour one padded
    uncovered = dict(reqs)
    chosen = []
    for s, pal in sorted(locked.items()):
        fr = frozenset(c for i, c in enumerate(pal)
                       if i in FREE_IDX or (nfree > 2 and i == 1))
        for need in list(uncovered):
            if need <= fr:
                uncovered.pop(need)
    cand = sorted(set(reqs),
                  key=lambda n: (-reqs[n], sorted(n)))
    for _slot in slots:
        best, gain = None, 0
        for c in cand:
            if c in chosen:
                continue
            g = sum(w for n, w in uncovered.items() if n <= c)
            # a 1-colour candidate can absorb a second colour later
            if g > gain:
                best, gain = c, g
        if best is None:
            break
        chosen.append(best)
        for need in list(uncovered):
            if need <= best:
                uncovered.pop(need)
    # pad single-colour choices with the most common co-occurring colour
    pals = {}
    for slot, need in zip(slots, chosen):
        cols = sorted(need, key=luma, reverse=True)
        if nfree > 2:
            cols = (cols + [BLACK, BLACK])[:3]
            pals[slot] = [cols[0], cols[1], cols[2], BLACK]
            continue
        if len(cols) < 2:
            extra = {}
            for n, w in reqs.items():
                if cols and cols[0] in n:
                    for c in n:
                        if c not in cols:
                            extra[c] = extra.get(c, 0) + w
            cols.append(max(extra, key=extra.get) if extra else BLACK)
        if not cols:
            cols = [CREAM, BLACK]
        # colour 0 = the lighter free colour, colour 2 = the darker
        pals[slot] = [cols[0], CREAM, cols[1], BLACK]
    for s, pal in locked.items():
        pals[s] = list(pal)
    for s in range(n_slots):
        pals.setdefault(s, [CREAM, CREAM, BLACK, BLACK])
    fit = Fit(palettes=[pals[s] for s in range(n_slots)],
              locked=sorted(locked))
    usable = sorted(set(slots) | set(locked))
    for px in subtiles:
        key = tuple(px)
        if key in fit.assign:
            continue
        costs = [(_pal_cost(px, fit.palettes[s]), s) for s in usable]
        cost, s = min(costs)
        fit.assign[key] = s
    for px in subtiles:
        fit.total += 1
        s = fit.assign[tuple(px)]
        c = _pal_cost(px, fit.palettes[s])
        fit.error += c
        if c == 0:
            fit.exact += 1
    return fit


def quantize(pixels, pal):
    """Pixel list -> 64 palette indices (nearest colour; black and cream
    keep their forced indices)."""
    cache = {}
    out = []
    for c in pixels:
        i = cache.get(c)
        if i is None:
            i = min(range(4), key=lambda k: (cdist(c, pal[k]), k))
            cache[c] = i
        out.append(i)
    return out


def encode_2bpp(indices):
    """64 colour indices -> 16 bytes (GB 2bpp: low plane then high plane
    per row, bit 7 = leftmost pixel)."""
    out = bytearray(16)
    for py in range(8):
        lo = hi = 0
        for px in range(8):
            v = indices[py * 8 + px]
            lo |= (v & 1) << (7 - px)
            hi |= ((v >> 1) & 1) << (7 - px)
        out[py * 2], out[py * 2 + 1] = lo, hi
    return bytes(out)


def decode_2bpp(b16):
    out = []
    for py in range(8):
        lo, hi = b16[py * 2], b16[py * 2 + 1]
        for px in range(8):
            bit = 7 - px
            out.append((((hi >> bit) & 1) << 1) | ((lo >> bit) & 1))
    return out


# ------------------------------------------------------------------- plan
@dataclass
class CellPlan:
    origin: tuple            # (x, y) in the PNG
    gfx: list                # 4 x 16-byte 2bpp
    pals: list               # 4 slot indices
    wall: bool = False


def plan_cells(img, origins, fit, walls=()):
    """Encode each chosen cell under `fit`. Returns [CellPlan]."""
    walls = set(map(tuple, walls))
    out = []
    for (x, y) in origins:
        gfx, pals = [], []
        for px in cell_subtiles(img, x, y):
            s = fit.assign.get(tuple(px))
            if s is None:
                s = min(range(len(fit.palettes)),
                        key=lambda k: _pal_cost(px, fit.palettes[k]))
            gfx.append(encode_2bpp(quantize(px, fit.palettes[s])))
            pals.append(s)
        out.append(CellPlan((x, y), gfx, pals, (x, y) in walls))
    return out


def slot_demand(plans, strict_walk=False):
    """Distinct sheet graphics the plan needs, split by the side of the
    collision threshold the bottom-right subtile must land on (it decides
    walkability — ROOM_DATA_FORMAT S94). Only cells marked WALL are bound
    (below the threshold) unless strict_walk also binds unmarked cells to
    the walkable side; a graphic needed on both sides costs two slots."""
    wall_br = set()
    other = set()
    for p in plans:
        for i, g in enumerate(p.gfx):
            if i == 3 and p.wall:
                wall_br.add(g)
            else:
                other.add(g)
    walk_br = {p.gfx[3] for p in plans if not p.wall} if strict_walk else set()
    return {'wall': len(wall_br), 'walkable_br': len(walk_br),
            'any': len(other - walk_br - wall_br),
            'total': len(wall_br | other) + len(wall_br & walk_br)}


def render_plan(plans, fit, scale=1, bg=(40, 40, 48), region=None):
    """Preview image of the planned cells at their PNG positions — what the
    GBC will show (decode the 2bpp, colour through the slot palette)."""
    if not plans:
        return Image.new('RGB', (CELL, CELL), bg)
    xs = [p.origin[0] for p in plans]
    ys = [p.origin[1] for p in plans]
    x0, y0 = (region[0], region[1]) if region else (min(xs), min(ys))
    x1 = (region[2] if region else max(xs) + CELL)
    y1 = (region[3] if region else max(ys) + CELL)
    im = Image.new('RGB', (x1 - x0, y1 - y0), bg)
    for p in plans:
        for i, (g, s) in enumerate(zip(p.gfx, p.pals)):
            idx = decode_2bpp(g)
            pal = fit.palettes[s]
            blk = Image.new('RGB', (SUB, SUB))
            blk.putdata([pal[k] for k in idx])
            im.paste(blk, (p.origin[0] - x0 + (i & 1) * SUB,
                           p.origin[1] - y0 + (i >> 1) * SUB))
    if scale != 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    return im
