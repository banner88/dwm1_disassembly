"""recolour.py — colour-true tiles: matching, the palette planner, re-plan (S171 r4, P3.3i).

User (S171): "the palette for a room is fixed and if you import a sort of similar looking
tileset the colours are fairly random and there is no way to re-roll the colour allocation
or change it … It's when I started pulling together diverse tilesets for the master room";
"importing tilesets AS IS works great for a brand new room. It does NOT work well if you
are ADDING it to an existing room"; "Now please … Do the whole thing".

The hardware rule (KEY_LESSONS S8, png_import): a screen has 4 BG palette ROWS for its
tiles (slots 0-3; 4-7 are the game's), 4 colours each; colour 3 is always black and colour 1
is the game's cream unless the palette is `free_color1` (then 3 colours of your own per
row). Every 8x8 quarter of a metatile is drawn in ONE row; its pixels are colour NUMBERS
0-3 into that row (2bpp tile data + the attr grid's row).

Before S171 r4 a tile borrowed from another room kept its colour numbers and its row number
(`Document.import_metatile`) — the colours were whatever this room has there. Here:

  * TRUTH — the colours a tile really has (in its source: a game room's / your room's
    palette, a PNG's pixels). `truth_of_metatile` keeps them on the My metatiles entry
    (`'true'`: per quarter a colour list + 64 indices) so the planner can always start
    from the real art, not from a mangled copy;
  * MATCH — `best_row` / `quantize` put a quarter into the row whose colours look closest
    (OKLab, the perceptual colour space) and renumber its pixels to those colours;
  * PLAN — `plan_rows` finds the 4 rows (3 free colours each, or 2 with the game's cream)
    that draw a whole set of quarters best: weighted k-medoids over the quarters' real
    colours, seeded — `propose` returns several different good answers ("re-roll") with
    locked rows kept as they are;
  * RE-PLAN — `Scope` (the screens / states of a room drawing with one palette + the
    tileset's My metatiles) and `apply_plan` write the new rows, give each quarter its best
    row and renumbered graphic (a slot shared with art outside the scope, or needed in two
    colourings, gets a new slot: the same wall / walkable side), repoint the cells (tile
    grid + attr grid) and the My metatiles — one undo step (a SnapshotCommand).

Pure data, no Qt.
"""

import math
import random

from . import page2 as P2

BLACK = (0, 0, 0)
CREAM = (248, 248, 208)                 # $6BFF, the engine's colour 1
CREAM555 = 0x6BFF
COMMON_FIRST, COMMON_END = 0x80, 0xB0   # the font / frame tiles every room shares


# ------------------------------------------------------------------ colour maths
def rgb555(v):
    """RGB555 word -> the RGB the editor draws (5 bits x 8, as render_project / png_import)."""
    v = int(v) & 0x7FFF
    return ((v & 31) * 8, ((v >> 5) & 31) * 8, ((v >> 10) & 31) * 8)


def to555(rgb):
    """RGB -> the nearest RGB555 word."""
    r, g, b = (min(31, (max(0, int(c)) + 4) >> 3) for c in rgb[:3])
    return r | (g << 5) | (b << 10)


def snap(rgb):
    """The GBC colour drawn for `rgb`."""
    return rgb555(to555(rgb))


_LAB = {}


def oklab(rgb):
    c = _LAB.get(rgb)
    if c is not None:
        return c

    def lin(u):
        u /= 255.0
        return u / 12.92 if u <= 0.04045 else ((u + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(x) for x in rgb[:3])
    l_ = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m_ = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s_ = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_, m_, s_ = (math.copysign(abs(x) ** (1 / 3), x) for x in (l_, m_, s_))
    c = (0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
         1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
         0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_)
    _LAB[tuple(rgb[:3])] = c
    return c


def dist(a, b):
    """Perceptual distance (OKLab, x100: 1 ≈ just noticeable)."""
    x, y = oklab(tuple(a[:3])), oklab(tuple(b[:3]))
    return 100.0 * math.sqrt((x[0] - y[0]) ** 2 + (x[1] - y[1]) ** 2 + (x[2] - y[2]) ** 2)


def displayed_rows(words_rows, free_color1):
    """4 rows of RGB555 words -> the RGB the game shows (colour 3 black, colour 1 cream
    unless the palette keeps its own colour 1)."""
    out = []
    for row in words_rows[:4]:
        r = [rgb555(v) for v in row]
        if not free_color1:
            r[1] = CREAM
        r[3] = BLACK
        out.append(r)
    return out


# ------------------------------------------------------------------ quarters
class Quarter:
    """An 8x8 quarter's real colours: `cols` (distinct RGB) + 64 indices into them."""
    __slots__ = ('cols', 'idx', 'w')

    def __init__(self, cols, idx, w=1):
        self.cols = [tuple(c) for c in cols]
        self.idx = list(idx)
        self.w = w

    @classmethod
    def from_rgb(cls, px, w=1):
        cols, idx, seen = [], [], {}
        for c in px:
            c = snap(c)
            k = seen.get(c)
            if k is None:
                k = seen[c] = len(cols)
                cols.append(c)
            idx.append(k)
        return cls(cols, idx, w)

    def rgb(self):
        return [self.cols[i] for i in self.idx]

    def key(self):
        return (tuple(self.cols), tuple(self.idx))

    def hist(self):
        h = {}
        for i in self.idx:
            h[self.cols[i]] = h.get(self.cols[i], 0) + 1
        return h

    # the project file form (My metatiles 'true')
    def to_json(self):
        return {'cols': ['0x%04X' % to555(c) for c in self.cols],
                'idx': ''.join('0123456789abcdefghijklmnopqrstuvwxyz'[min(i, 35)]
                               for i in self.idx)}

    @classmethod
    def from_json(cls, d):
        cols = [rgb555(int(str(c), 16) if isinstance(c, str) else int(c)) for c in d['cols']]
        idx = [int(ch, 36) for ch in d['idx']]
        return cls(cols, [min(i, len(cols) - 1) for i in idx])


def quarter_from_indices(px64, row_rgb):
    return Quarter.from_rgb([row_rgb[i & 3] for i in px64])


def quantize(q, row):
    """(64 colour numbers, error) — every pixel of `q` to its closest colour of `row`."""
    row = [snap(c) for c in row]
    best = {}
    err = 0.0
    for c, n in q.hist().items():
        d, k = min((dist(c, row[i]), i) for i in range(4))
        best[c] = k
        err += d * n
    return [best[q.cols[i]] for i in q.idx], err


def fixed_error(q, idx64, row):
    """Error of drawing `q` with fixed colour numbers (a tile that cannot be renumbered:
    the shared font tiles, an animated slot) in `row`."""
    row = [snap(c) for c in row]
    return sum(dist(q.cols[q.idx[p]], row[idx64[p] & 3]) for p in range(64))


def best_row(q, rows, allowed=None, fixed_idx=None):
    """(row number, 64 colour numbers, error) — the row that draws `q` closest."""
    best = None
    for r in (allowed if allowed is not None else range(len(rows))):
        if fixed_idx is not None:
            e, idx = fixed_error(q, fixed_idx, rows[r]), list(fixed_idx)
        else:
            idx, e = quantize(q, rows[r])
        if best is None or e < best[2] - 1e-9:
            best = (r, idx, e)
    return best


# ------------------------------------------------------------------ the planner
class Plan:
    def __init__(self, rows, error, exact, total, seed):
        self.rows = rows            # 4 rows x 4 RGB
        self.error = error          # mean perceptual error per pixel
        self.exact = exact          # quarters drawn with no error
        self.total = total
        self.seed = seed

    def score_text(self):
        pct = 100.0 * self.exact / max(1, self.total)
        return f'{pct:.0f} % of tiles exact · error {self.error:.2f}'


def _row_template(nfree):
    """Which indices of a row are free (the planner's), the rest fixed."""
    return (0, 1, 2) if nfree == 3 else (0, 2)


def _row_cost(hist, row):
    row = [snap(c) for c in row]
    return sum(w * min(dist(c, m) for m in row) for c, w in hist.items())


def _fit_row_keep(hist, nfree, rng, prev):
    """_fit_row, but never worse than the row it replaces (the plan only improves)."""
    new = _fit_row(hist, nfree, rng)
    if prev is not None and _row_cost(hist, prev) <= _row_cost(hist, new) + 1e-6:
        return list(prev)
    return new


def _fit_row(hist, nfree, rng=None):
    """The `nfree` free colours (+ black, + cream when nfree == 2) that draw the colour
    histogram `hist` {rgb: weight} best: weighted k-medoids over its distinct colours."""
    fixed = [BLACK] + ([CREAM] if nfree == 2 else [])
    # colours already drawn well by a fixed colour need no free colour
    cand = {c: w for c, w in hist.items() if min(dist(c, f) for f in fixed) > 2.0}
    cols = sorted(cand, key=lambda c: -cand[c])
    if not cols:
        free = [CREAM] * nfree
    elif len(cols) <= nfree:
        free = cols + [cols[-1]] * (nfree - len(cols))
    else:
        # k-medoids: start from the heaviest (or seeded), swap while it improves
        pool = cols[:48]
        if rng is None:
            med = [pool[0]]
            while len(med) < nfree:                     # farthest-first by weight
                med.append(max((c for c in pool if c not in med),
                               key=lambda c: cand[c] * min(dist(c, m) for m in med)))
        else:
            med = rng.sample(pool[:max(nfree, min(len(pool), 12))], nfree)

        def cost(meds):
            ms = list(meds) + fixed
            return sum(w * min(dist(c, m) for m in ms) for c, w in hist.items())
        cur = cost(med)
        improved = True
        while improved:
            improved = False
            for i in range(nfree):
                for c in pool:
                    if c in med:
                        continue
                    trial = med[:i] + [c] + med[i + 1:]
                    t = cost(trial)
                    if t < cur - 1e-6:
                        med, cur, improved = trial, t, True
        free = med
    free = sorted(free, key=lambda c: -oklab(c)[0])      # light to dark
    if nfree == 3:
        return [free[0], free[1], free[2], BLACK]
    return [free[0], CREAM, free[1], BLACK]


def plan_rows(quarters, nfree=3, locked=None, seed=0, iters=20, start_rows=None):
    """4 rows drawing `quarters` (list of (Quarter, fixed_idx or None)) best.
    locked = {row: [4 RGB]} kept as they are. seed 0 = start from `start_rows` (the
    palette as it is) or a deterministic split; other seeds = random starts. Returns a
    Plan."""
    locked = dict(locked or {})
    free_rows = [r for r in range(4) if r not in locked]
    rng = random.Random(seed) if seed else None
    qs = [(q, f) for q, f in quarters if q is not None]
    # seed 0: the rows as they are; seeds 1, 2 (mod 3): those rows with 1 or 2 rows started
    # again from random tiles (good alternatives close to the best); seed 0 (mod 3) > 0: a
    # fresh random start (a different look altogether)
    perturb = bool(seed) and start_rows is not None and seed % 3 != 0
    if start_rows is not None and (not seed or perturb):
        rows = [list(locked.get(r, start_rows[r])) for r in range(4)]
    else:
        rows = [list(locked.get(r, [CREAM, CREAM, CREAM, BLACK])) for r in range(4)]
    if not qs:
        return Plan(rows, 0.0, 0, 0, seed)
    if perturb and free_rows:
        colourful_qs = [q for q, f in qs if f is None and len(q.hist()) > 1]
        for r in rng.sample(free_rows, min(len(free_rows), 1 + (seed % 3 == 2))):
            if not colourful_qs:
                break
            h = {}
            for q in rng.sample(colourful_qs, min(len(colourful_qs), 3)):
                for c, n in q.hist().items():
                    h[c] = h.get(c, 0) + n
            rows[r] = _fit_row(h, nfree, rng)

    def sig(q):
        h = q.hist()
        c = max((c for c in h if c != BLACK), key=lambda c: h[c], default=BLACK)
        return oklab(c)
    if free_rows and not perturb and (start_rows is None or seed):
        if rng is None:
            order = sorted(range(len(qs)), key=lambda i: (sig(qs[i][0])[1], sig(qs[i][0])[2]))
            groups = {r: [] for r in free_rows}
            for n, i in enumerate(order):
                groups[free_rows[min(len(free_rows) - 1, n * len(free_rows) // len(order))]].append(i)
        else:
            centres = [sig(qs[i][0]) for i in rng.sample(range(len(qs)),
                                                          min(len(qs), len(free_rows)))]
            while len(centres) < len(free_rows):
                centres.append(centres[-1])
            groups = {r: [] for r in free_rows}
            for i, (q, _f) in enumerate(qs):
                s_ = sig(q)
                k = min(range(len(centres)),
                        key=lambda j: sum((s_[t] - centres[j][t]) ** 2 for t in range(3)))
                groups[free_rows[k]].append(i)
        for r, members in groups.items():
            h = {}
            for i in members:
                if qs[i][1] is None:
                    for c, n in qs[i][0].hist().items():
                        h[c] = h.get(c, 0) + n * qs[i][0].w
            if h:
                rows[r] = _fit_row(h, nfree, rng)

    def colourful(hist):
        return any(dist(c, BLACK) > 2.0 for c in hist)
    for _ in range(iters if free_rows else 0):
        assign, errs = {}, {}
        for i, (q, f) in enumerate(qs):
            r, _idx, e = best_row(q, rows, fixed_idx=f)
            assign[i] = r
            errs[i] = e * q.w
        old = [list(r) for r in rows]
        useful = set()
        for r in free_rows:
            h = {}
            for i, (q, f) in enumerate(qs):
                if assign[i] == r and f is None:
                    for c, n in q.hist().items():
                        h[c] = h.get(c, 0) + n * q.w
            if h and colourful(h):
                rows[r] = _fit_row_keep(h, nfree, rng, rows[r])
                useful.add(r)
        # a row nobody needs is wasted: give it to the worst-drawn tiles
        for r in free_rows:
            if r in useful:
                continue
            worst = sorted((i for i in errs if qs[i][1] is None and errs[i] > 1e-6),
                           key=lambda i: -errs[i])
            if not worst:
                break
            pick = worst[:max(1, len(worst) // 3)]
            h = {}
            for i in pick:
                for c, n in qs[i][0].hist().items():
                    h[c] = h.get(c, 0) + n * qs[i][0].w
                errs.pop(i, None)
            rows[r] = _fit_row(h, nfree, rng)
        if rows == old:
            break
    err = tot = 0.0
    exact = 0
    for q, f in qs:
        _r, _idx, e = best_row(q, rows, fixed_idx=f)
        err += e * q.w
        tot += 64 * q.w
        exact += (e < 1e-6) * q.w
    return Plan([list(r) for r in rows], err / max(1.0, tot), exact, sum(q.w for q, _ in qs),
                seed)


def _plan_sig(p):
    """A plan's rows as a set (the same rows in another order draw the same)."""
    return tuple(sorted(tuple(to555(c) for c in row) for row in p.rows))


def align_rows(rows, old_rows, locked=(), nfree=3):
    """The same rows, put in the order (and colour numbers) closest to the palette as it is
    — fewer cells and tile graphics change when the plan is applied."""
    if old_rows is None:
        return rows
    rows = [list(r) for r in rows]
    free_rows = [r for r in range(4) if r not in locked]
    pool = [rows[r] for r in free_rows]
    out = [list(r) for r in rows]
    taken = set()
    pairs = sorted(((sum(min(dist(c, o) for o in old_rows[r]) for c in pool[j]), r, j)
                    for r in free_rows for j in range(len(pool))))
    for _cost, r, j in pairs:
        if r in taken or ('j', j) in taken:
            continue
        taken.add(r)
        taken.add(('j', j))
        new = list(pool[j])
        free_idx = [0, 1, 2] if nfree == 3 else [0, 2]
        cols = [new[i] for i in free_idx]
        placed = {}
        for i in sorted(free_idx, key=lambda i: min(dist(c, old_rows[r][i]) for c in cols)):
            c = min((c for c in cols if c not in placed.values()),
                    key=lambda c: dist(c, old_rows[r][i]), default=None)
            if c is None:
                c = cols[0]
            placed[i] = c
        for i in free_idx:
            new[i] = placed[i]
        out[r] = new
    return out


def propose(quarters, nfree=3, locked=None, start_seed=0, n=4, tries=10, start_rows=None,
            exclude=()):
    """Up to `n` DIFFERENT good plans (best first): seed `start_seed` (0 = improve the
    palette as it is, `start_rows`) and the next `tries - 1` seeds; a re-roll asks with
    the next start_seed; `exclude` = plans already shown (their _plan_sig)."""
    plans = []
    for s in range(start_seed, start_seed + tries):
        p = plan_rows(quarters, nfree, locked, seed=s, start_rows=start_rows)
        p.rows = align_rows(p.rows, start_rows, locked or {}, nfree)
        if _plan_sig(p) in exclude or any(_plan_sig(o) == _plan_sig(p) for o in plans):
            continue
        plans.append(p)
    plans.sort(key=lambda p: (p.error, -p.exact))
    return plans[:n]


# ------------------------------------------------------------------ truth of metatiles
def truth_of_metatile(mt):
    """[4 Quarter or None] stored on a My metatiles entry."""
    t = mt.get('true')
    if not t or len(t) != 4:
        return None
    try:
        return [Quarter.from_json(q) if q else None for q in t]
    except (KeyError, ValueError, TypeError):
        return None


def set_truth(mt, quarters):
    mt['true'] = [q.to_json() if q is not None else None for q in quarters]


# ------------------------------------------------------------------ the truth store
# custom._editor.truth[tileset key]['<slot>:<row>'] = {'cols', 'idx', 'g'}: the real
# colours of the art drawn by tile SLOT in palette ROW (the compiler ignores _editor).
# 'g' = the slot's 2bpp graphic when recorded — an entry whose slot was redrawn since
# (Draw, another import) no longer matches and is ignored.
def _truth_map(doc, tid, create=False):
    ed = doc.custom.setdefault('_editor', {}) if create else (doc.custom.get('_editor') or {})
    if create:
        return ed.setdefault('truth', {}).setdefault(tid, {})
    return (ed.get('truth') or {}).get(tid) or {}


def record_truth(doc, tid, slot, row, q, sheet):
    if q is None or P2.is_common(slot):
        return
    s = P2.slot_key(slot)
    d = q.to_json()
    d['g'] = bytes(sheet[s * 16:s * 16 + 16]).hex()
    _truth_map(doc, tid, create=True)[f'{s}:{int(row)}'] = d


def truth_at(doc, tid, slot, row, sheet):
    """The recorded real colours of slot `slot` drawn in `row`, or None."""
    s = P2.slot_key(slot)
    d = _truth_map(doc, tid).get(f'{s}:{int(row)}')
    if not d or d.get('g') != bytes(sheet[s * 16:s * 16 + 16]).hex():
        return None
    try:
        return Quarter.from_json(d)
    except (KeyError, ValueError, TypeError):
        return None


def rename_truth(doc, old_tid, new_tid):
    """A tileset copied into the project (localize) keeps its truth."""
    ed = doc.custom.get('_editor') or {}
    t = ed.get('truth') or {}
    if old_tid in t and old_tid != new_tid:
        t.setdefault(new_tid, {}).update(t.pop(old_tid))


# ------------------------------------------------------------------ colour-matched import
def import_true_metatile(doc, room_id, quarters, rows, threshold, walkable=True,
                         name='imported', own_sheet=None, allowed_rows=(0, 1, 2, 3),
                         src='borrowed'):
    """A metatile from REAL colours (S171 r4): each quarter (a Quarter) goes to the row of
    `rows` (this screen's 4 rows, RGB) that draws it closest, its pixels renumbered to
    those colours; the graphics reuse identical tiles / take free slots (tile_draw.apply_new:
    the bottom-right on the walkable / wall side asked for); the truth is recorded. Returns
    (new metatile, sentence, [error per quarter])."""
    from . import tile_draw as TD
    from . import parking as PK
    from .document import NoFreeSlot
    room = doc.room(room_id)
    picks = [best_row(q, rows, allowed=allowed_rows) for q in quarters]
    px = [p[1] for p in picks]
    pals = [p[0] for p in picks]
    errs = [p[2] / 64.0 for p in picks]
    mt = {'tiles': [0, 0, 0, 0], 'pal': pals, 'name': name}
    # S171 r5: the room's own tileset first (parked metatiles live with it), then — when
    # the sheet is full — the unplaced My metatiles are parked; when the PLACED tiles fill
    # it, the import itself is parked (it takes slots when painted)
    if 'tileset' not in room['record'] and own_sheet is not None:
        old_key = doc.tileset_key(room)
        rename_truth(doc, old_key, doc.localize_tileset(room, own_sheet))
    try:
        new, msg = PK.evicting(
            doc, room_id, rows,
            lambda: TD.apply_new(doc, room_id, mt, px, threshold, walkable, own_sheet=own_sheet,
                                 pal=pals if len(set(pals)) > 1 else pals[0], name=name),
            threshold)
    except NoFreeSlot:
        tid = doc.tileset_key(doc.room(room_id))
        if ':' in str(tid):
            raise
        new = PK.park_new(doc, tid, name, px, pals, walkable, list(quarters), src=src)
        return new, f"'{name}' parked — the tiles on the screens fill the tileset", errs
    tid = doc.tileset_key(doc.room(room_id))
    lst = doc._metatiles_mut(tid)
    if lst and lst[-1].get('tiles') == list(new['tiles']):
        lst[-1]['src'] = src
    sheet = doc.read_sheet(tid)
    for q, t, r in zip(quarters, new['tiles'], pals):
        record_truth(doc, tid, t, r, q, sheet)
    return new, msg, errs


def match_words(errs):
    """'exact' / 'close' / 'rough' for a list of per-pixel errors."""
    worst = max(errs) if errs else 0
    return 'exact' if worst < 0.01 else ('close' if worst < 6 else 'rough')


# ------------------------------------------------------------------ the re-plan scope
def _grid_cells(grid):
    for r in range(len(grid)):
        for c in range(len(grid[r])):
            yield r, c, grid[r][c]


def palette_states(doc, pid):
    """[(room id, key, state)] of every screen / state drawing with palette `pid`."""
    out = []
    for room in doc.rooms:
        if not room.get('screens'):
            continue
        for k in doc.screen_keys(room):
            for n in range(len(doc.states(room, k))):
                if doc.effective_palette(room, k, n) == pid:
                    out.append((room['id'], k, n))
    return out


def _attr_id_in_effect(doc, room, key, n):
    """The project layout id whose attr grid is in effect (writable_attr_id without
    creating one), or None."""
    scr = doc.screen(room, key)
    sts = scr.get('states') or []
    cands = []
    if n < len(sts):
        st = sts[n]
        cands += [(st.get('attr'), True), (st.get('layout'), False)]
    cands += [(scr.get('attr'), True), (scr.get('layout'), False),
              ((room.get('render') or {}).get('attr'), True)]
    for c, is_attr in cands:
        if not c:
            continue
        if 'id' in c and doc.has_layout(c['id']) and 'attr' in doc.layout(c['id']):
            return c['id']
        if is_attr:
            break
    return None


class Scope:
    """What a re-plan touches: the screens / states of ONE room drawing with the palette
    of (key, state), their cells, and the My metatiles of the room's tileset."""

    def __init__(self, doc, room, key, state, rows_old, sheet, common_blocks=None,
                 anim=()):
        from . import tile_draw as TD
        self.room_id = room['id']
        self.pid = doc.effective_palette(room, key, state)
        self.tid = doc.tileset_key(room)
        self.rows_old = [list(r) for r in rows_old[:4]]
        self.sheet = bytearray(P2.pad_sheet(sheet))
        self.anim = set(anim)
        self.states = [(k, n) for k in doc.screen_keys(room)
                       for n in range(len(doc.states(room, k)))
                       if doc.effective_palette(room, k, n) == self.pid]
        self.problems = []
        self.lids, self.attrs, self.tiles = {}, {}, {}   # (k, n) -> lid / attr / tile grid
        for k, n in self.states:
            ref = doc.state_layout_ref(room, k, n) or {}
            if 'id' not in ref or not doc.has_layout(ref['id']):
                self.problems.append(f'screen {k} state {n} has no layout of its own')
                continue
            grid = None
            if doc.vanilla is not None:
                grid, _note = doc.vanilla.attr_grid(room, k, n)
            self.lids[(k, n)] = ref['id']
            self.attrs[(k, n)] = [list(r) for r in (grid or doc.blank_grid(0))]
            self.tiles[(k, n)] = [list(r) for r in doc.layout(ref['id'])['tiles']]
        # units: (tile value, row) placed / in My metatiles -> weight + its truth
        self.units = {}
        self._common = common_blocks

        def add(v, a, w=1):
            if a > 3:
                return
            u = (int(v), int(a))
            if u in self.units:
                self.units[u]['w'] += w
                return
            fixed = None
            if P2.is_common(v):
                blk = (common_blocks or [])
                fixed = list(blk[int(v) - COMMON_FIRST]) if COMMON_FIRST <= int(v) < COMMON_END \
                    and blk else [0] * 64
            s = P2.slot_key(v)
            if fixed is None and s in self.anim:
                fixed = TD.decode_tile(bytes(self.sheet[s * 16:s * 16 + 16]))
            q = None if P2.is_common(v) else truth_at(doc, self.tid, v, a, self.sheet)
            if q is None:
                idx = fixed if fixed is not None else \
                    TD.decode_tile(bytes(self.sheet[s * 16:s * 16 + 16]))
                q = quarter_from_indices(idx, self.rows_old[a])
            self.units[u] = {'w': w, 'q': q, 'fixed': fixed}
        for (k, n), lid in self.lids.items():
            attr = self.attrs[(k, n)]
            for r, c, v in _grid_cells(self.tiles[(k, n)]):
                add(v, attr[r][c] & 7)
        for mt in doc.metatiles(self.tid):
            pals = TD.quarter_pals(mt)
            for t, a in zip(mt['tiles'], pals):
                add(t, a, 0)                 # kept consistent, no weight in the plan
        # where else each slot is drawn (other rooms, this room's other palettes)
        mine = set(self.lids.values())
        self.outside = set()
        for lid in doc.layouts_using_tileset(self.tid):
            if lid in mine:
                continue
            for row in doc.layout(lid)['tiles']:
                self.outside.update(P2.slot_key(v) for v in row if not P2.is_common(v))
        # a layout / attr grid shared with a screen OUTSIDE the scope cannot be changed
        mine_attr = {_attr_id_in_effect(doc, room, kk, nn) for kk, nn in self.lids} - {None}
        others = []
        for rm in doc.rooms:
            if not rm.get('screens'):
                continue
            for k in doc.screen_keys(rm):
                for n in range(len(doc.states(rm, k))):
                    if rm['id'] == self.room_id and (k, n) in self.lids:
                        continue
                    ref = doc.state_layout_ref(rm, k, n) or {}
                    if ref.get('id') in mine:
                        others.append(f"{doc.room_name(rm)} screen {k} state {n}")
                    elif rm['id'] == self.room_id and mine_attr:
                        a = _attr_id_in_effect(doc, rm, k, n)
                        if a is not None and a in mine_attr:
                            others.append(f"{doc.room_name(rm)} screen {k} state {n} "
                                          '(its colour grid)')
        if others:
            self.problems.append('shares its drawing with ' + ', '.join(sorted(set(others))[:4])
                                 + ' — which uses other colours')

    def quarters(self):
        """[(Quarter, fixed indices or None)] weighted, for the planner."""
        out = []
        for u in self.units.values():
            if u['w'] <= 0:
                continue
            q = Quarter(u['q'].cols, u['q'].idx, u['w'])
            out.append((q, u['fixed']))
        return out

    def summary(self):
        cells = sum(u['w'] for u in self.units.values())
        return {'states': len(self.lids), 'quarters': cells,
                'distinct': sum(1 for u in self.units.values() if u['w'] > 0)}

    def preview(self, doc, rows, key, state):
        """The screen (key, state) drawn with `rows` the way apply_plan would draw it:
        [16][20] of 64 RGB pixels per quarter -> a PIL image 160x128."""
        from PIL import Image
        lid = self.lids.get((key, state))
        img = Image.new('RGB', (160, 128))
        if lid is None:
            return img
        tiles = self.tiles[(key, state)]
        attr = self.attrs[(key, state)]
        cache = {}
        data = img.load()
        for r, c, v in _grid_cells(tiles):
            a = attr[r][c] & 7
            u = self.units.get((int(v), a))
            if u is None:
                continue
            ck = (int(v), a)
            px = cache.get(ck)
            if px is None:
                row, idx, _e = best_row(u['q'], rows, fixed_idx=u['fixed'])
                px = cache[ck] = [rows[row][i & 3] for i in idx]
            for p in range(64):
                data[c * 8 + p % 8, r * 8 + p // 8] = tuple(px[p])
        return img


def apply_plan(doc, room_id, key, state, rows_new, nfree, rows_old, sheet,
               common_blocks=None, anim=(), threshold=0, own_sheet=None,
               vanilla_words=None):
    """Write a re-plan (inside a SnapshotCommand): the room's palette rows 0-3 = rows_new,
    every quarter of the scope in its best row with renumbered graphics (new slots where a
    slot is shared with art outside the scope or needed twice), the cells and the My
    metatiles repointed. Returns a sentence."""
    from . import tile_draw as TD
    room = doc.room(room_id)
    # 0. the room's own tileset and palette
    rec = room['record']
    if 'tileset' not in rec:
        old_key = doc.tileset_key(room)
        if own_sheet is None:
            raise RuntimeError('the room still draws with a game tileset — pass own_sheet')
        new_key = doc.localize_tileset(room, own_sheet)
        rename_truth(doc, old_key, new_key)
    scope = Scope(doc, room, key, state, rows_old, doc.read_sheet(doc.tileset_key(room)),
                  common_blocks, anim)
    if scope.problems:
        raise RuntimeError('Cannot re-plan: ' + '; '.join(scope.problems))
    pid = scope.pid
    if pid is None:
        if vanilla_words is None:
            raise RuntimeError('the room still draws with a game palette — pass its words')
        pid = doc.add_palette_from_words(f"pal_{room['id']}", vanilla_words,
                                         'made by Re-plan colours (S171 r4)')
        for k, n in scope.states:
            doc.set_state_palette(room, k, n, pid)
    else:
        users = palette_states(doc, pid)
        if any(rid != room['id'] or (k, n) not in scope.lids for rid, k, n in users):
            words = [[int(str(c), 16) for c in row] for row in doc.palette(pid)['colors_rgb555']]
            pid2 = doc.add_palette_from_words(f'{pid}_replan', words,
                                              f'copy of {pid} made by Re-plan colours')
            if doc.palette(pid).get('free_color1'):
                doc.set_palette_free1(pid2, True)
            for k, n in scope.states:
                doc.set_state_palette(room, k, n, pid2)
            pid = pid2
    tid = scope.tid
    sh = doc.read_sheet(tid)
    # 1. each unit's new row and graphic
    plan = {}
    for u, d in scope.units.items():
        r, idx, _e = best_row(d['q'], rows_new, fixed_idx=d['fixed'])
        plan[u] = (r, idx)
    # 2. slots: one graphic per slot; a second colouring / an outside user -> a new slot
    used = doc.used_tiles(tid)
    blocked = set(scope.anim) | doc.service_slots(tid)
    free = [i for i in range(P2.SLOTS) if i not in used and i not in blocked]
    claimed = {}                       # slot -> 16 bytes it will hold
    newval = {}
    by_slot = {}
    for (v, a), (r, idx) in plan.items():
        if P2.is_common(v) or scope.units[(v, a)]['fixed'] is not None:
            newval[(v, a)] = v
            continue
        g = TD.encode_tile(idx)
        by_slot.setdefault(P2.slot_key(v), {}).setdefault(g, []).append((v, a))
    need_more = {'wall': 0, 'walkable': 0}
    for s in sorted(by_slot):
        variants = sorted(by_slot[s].items(),
                          key=lambda kv: -sum(scope.units[u]['w'] for u in kv[1]))
        cur = bytes(sh[s * 16:s * 16 + 16])
        for g, us in variants:
            target = None
            if g == cur and claimed.get(s, g) == g:
                target = s
            elif s not in scope.outside and s not in claimed:
                target = s
            if target is None:                # same graphic elsewhere, same side
                for i in sorted(range(P2.SLOTS), key=lambda i: (i >= 0x80, i)):
                    if i in blocked or P2.is_wall(i, threshold) != P2.is_wall(s, threshold):
                        continue
                    have = claimed.get(i, bytes(sh[i * 16:i * 16 + 16]))
                    if have == g and (i in claimed or i in used):
                        target = i
                        break
            if target is None:
                pool = [i for i in free if i not in claimed
                        and P2.is_wall(i, threshold) == P2.is_wall(s, threshold)]
                if not pool:
                    need_more['wall' if P2.is_wall(s, threshold) else 'walkable'] += 1
                    continue
                pool.sort(key=lambda i: (i >= 0x80, i))
                target = pool[0]
            claimed[target] = g
            for u in us:
                newval[u] = P2.value_of(target)
    if need_more['wall'] or need_more['walkable']:
        from .document import NoFreeSlot
        raise NoFreeSlot('Re-plan needs more free tile slots: '
                         f"{need_more['wall']} wall, {need_more['walkable']} walkable "
                         '(the same tile drawn in two colourings needs two slots). Remove '
                         'some tiles from the screens, or lock a row.')
    for i, g in claimed.items():
        sh[i * 16:i * 16 + 16] = g
    doc.write_sheet(tid, sh)
    # 3. the palette
    row_words = doc.palette(pid)['colors_rgb555']
    for r in range(4):
        for i in range(4):
            c = rows_new[r][i]
            if i == 3:
                w = 0
            elif i == 1 and nfree == 2:
                w = CREAM555
            else:
                w = to555(c)
            row_words[r][i] = '0x%04X' % w
    doc.set_palette_free1(pid, nfree == 3)
    # 4. cells (tile grid + attr grid) and My metatiles
    done = set()
    changed = 0
    for (k, n), lid in scope.lids.items():
        tiles = doc.layout(lid)['tiles']
        old_attr = scope.attrs[(k, n)]
        alid = doc.writable_attr_id(room, k, n)
        attr = doc.layout(alid)['attr']
        for r, c, v in _grid_cells(scope.tiles[(k, n)]):
            a0 = old_attr[r][c]
            u = (int(v), a0 & 7)
            if u not in plan:
                continue
            nv, nr = newval.get(u, v), plan[u][0]
            if lid not in done and nv != v:
                tiles[r][c] = nv
                changed += 1
            attr[r][c] = (a0 & ~7) | nr
        done.add(lid)
    for mt in doc._metatiles_mut(tid):
        pals = TD.quarter_pals(mt)
        nt, npl = [], []
        for t, a in zip(mt['tiles'], pals):
            u = (int(t), int(a))
            nt.append(newval.get(u, t) if u in plan else t)
            npl.append(plan[u][0] if u in plan else a)
        mt['tiles'] = nt
        mt['pal'] = npl[0] if len(set(npl)) == 1 else npl
    # 5. the truth follows the art
    sh = doc.read_sheet(tid)
    for u, (r, _idx) in plan.items():
        if scope.units[u]['fixed'] is None:
            record_truth(doc, tid, newval.get(u, u[0]), r, scope.units[u]['q'], sh)
    doc.touch()
    return (f're-planned palette {pid}: {len(scope.lids)} screen state(s), '
            f'{sum(1 for u in plan if scope.units[u]["w"] > 0)} distinct tiles; '
            f'{len([i for i in claimed if i not in by_slot])} new tile slot(s) used')


__all__ = ['Quarter', 'Plan', 'quantize', 'best_row', 'plan_rows', 'propose', 'dist',
           'oklab', 'rgb555', 'to555', 'snap', 'displayed_rows', 'truth_of_metatile',
           'set_truth', 'quarter_from_indices', 'Scope', 'apply_plan',
           'import_true_metatile', 'record_truth', 'truth_at', 'match_words',
           'palette_states']
