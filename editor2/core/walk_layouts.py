"""walk_layouts.py — the 155 walking LAYOUTS (ROADMAP P3.10 part 2b, S107;
PROJECT_COMPILER §2.23 "walking layouts"; MONSTER_DATA "Follower / walking-
sprite render system").

What a layout is (ROM-measured, tools/extract_monster_follower_layouts.py):
a level-2 table of six frame pointers (down_A, down_B, right_A, right_B, up_A,
up_B — LEFT is RIGHT drawn mirrored by the engine), each frame a run of 4-byte
OAM entries (dy, dx, tile 0-15, attr: bit5 X-flip, bit6 Y-flip), $80-ended.
The 16 tiles of a monster's walking art mean nothing without its layout: the
layout says which tile goes where, mirrored or not, in each of the six
frames. 215 monsters use 155 distinct layouts (`extracted/follower_layouts.json`
— regenerated S107 with the stored bytes, the Y-flip bit, where each layout
already exists per bank and every frame each bank holds).

Why it matters (user S107 on 2a: "When you changed healer parent sprite in
library it is STILL. Vanilla behaviour is MOVING."): 2a packed every new
walking art for layout 0, whose down_B / up_B are the A frame MIRRORED — a
symmetric monster then does not move at all. The sheets have six real frames
(the B frames differ from A in 20 of the 26 bug.png monsters); the game's own
layouts animate with shared + extra tiles, 1-px bobs, distinct legs … So 2b:

  * pack(frames, layout)  — the 16 tiles that draw the sheet's six frames
    through `layout` as closely as possible (per tile pixel: the value most
    of its placements want; a placement under a higher-priority entry counts
    less), and the exact pixel error of what the game will then draw;
  * fit_all(frames)       — every layout ranked by that error (the dialog's
    "best fit" = the first; ties prefer the monster's own layout, then one
    that already exists in its follower bank);
  * copies                — a species can only use a layout of ITS follower
    bank (bank $10 = species 0-127, $11 = 128-214 and the new species; a
    level-2 pointer is read with that bank mapped). A layout that is not
    there is COPIED into the bank's free tail (bank $10 $7A83-$7FFF, 1405 B;
    bank $11 after the new-species tables): a 12-byte table + only the
    frames the bank does not already hold byte-for-byte (median 63 / 80 B).

The sheet's 16x16 frame is the OAM box x -8..7, y -16..-1 around the anchor
(layout 0's four entries exactly; the S106 packing). LEFT needs no data: it is
RIGHT mirrored about the anchor.
"""

import json
import os

FRAMES = ('down_A', 'down_B', 'right_A', 'right_B', 'up_A', 'up_B')
SHEET_KEY = {'down_A': 'DOWN-a', 'down_B': 'DOWN-b', 'right_A': 'SIDE-a',
             'right_B': 'SIDE-b', 'up_A': 'UP-a', 'up_B': 'UP-b'}
# votes: the A frames first (ties go to what the A frames want)
VOTE_ORDER = (0, 2, 4, 1, 3, 5)
LAYOUT0 = 0
BANKS = (0x10, 0x11)
# canvas for the error: anchor at (OX, OY); every layout entry lies inside
# (dy -18..-4, dx -11..3 measured over all 930 frames)
W, H, OX, OY = 32, 32, 16, 24
BOX = (OX - 8, OY - 16)          # the sheet frame's top-left on the canvas
COVERED_WEIGHT = 0.25            # a pixel under a higher-priority entry

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
_CACHE = {}


class LayoutError(ValueError):
    pass


# ---------------------------------------------------------------------------
# the catalogue
# ---------------------------------------------------------------------------

def data(repo=None):
    repo = repo or REPO
    if repo not in _CACHE:
        _CACHE[repo] = json.load(open(os.path.join(repo, 'extracted', 'follower_layouts.json')))
    return _CACHE[repo]


def count(repo=None):
    return len(data(repo)['layouts'])


def layout(lid, repo=None):
    L = data(repo)['layouts']
    if isinstance(lid, bool) or not isinstance(lid, int) or not 0 <= lid < len(L):
        raise LayoutError(f"layout {lid!r}: one of the {len(L)} walking layouts "
                          f"0-{len(L) - 1} (extracted/follower_layouts.json)")
    return L[lid]


def species_layout(sid, repo=None):
    """The original layout id of species 0-214."""
    key = ('map', repo or REPO)
    if key not in _CACHE:
        m = json.load(open(os.path.join(repo or REPO, 'extracted',
                                        'monster_follower_layouts.json')))
        _CACHE[key] = {e['species']: e.get('layout_id') for e in m['monsters']}
    return _CACHE[key].get(sid)


def users(lid, repo=None):
    """Original species (0-214) that walk with layout `lid`."""
    species_layout(0, repo)
    return sorted(s for s, l in _CACHE[('map', repo or REPO)].items()
                  if l == lid and s <= 214)


def native_l2(lid, bank, repo=None):
    """The address of layout `lid`'s level-2 table in follower bank `bank`
    (the first one if several species' tables hold it), or None."""
    inst = layout(lid, repo)['instances'].get(f'{bank:02x}')
    return inst[0] if inst else None


def entries(lid, repo=None):
    """{frame: [(dy, dx, tile, xflip, yflip)]} in OAM order (entry 0 = the
    highest priority where entries overlap)."""
    fr = layout(lid, repo)['frames']
    return {f: [(e['dy'], e['dx'], e['tile'], e['xflip'], e.get('yflip', False))
                for e in fr[f]] for f in FRAMES}


def tiles_used(lid, repo=None):
    return sorted({e[2] for es in entries(lid, repo).values() for e in es})


# ---------------------------------------------------------------------------
# packing the sheet's six frames into 16 tiles for a layout
# ---------------------------------------------------------------------------

def _plan(lid, repo=None):
    """Per layout (cached): for every tile pixel the canvas spots it lands on
    [(frame, cy, cx, weight)], and per frame the entry each canvas pixel
    shows first (priority order) — enough to vote and to render."""
    key = ('plan', repo or REPO, lid)
    if key in _CACHE:
        return _CACHE[key]
    ents = entries(lid, repo)
    spots = [[[] for _ in range(64)] for _ in range(16)]
    order = []                      # per frame: [(tile, xf, yf, cy0, cx0)] in priority
    for fi, f in enumerate(FRAMES):
        seen = set()
        lst = []
        for dy, dx, t, xf, yf in ents[f]:
            cy0, cx0 = OY + dy, OX + dx
            lst.append((t, xf, yf, cy0, cx0))
            for r in range(8):
                for c in range(8):
                    cy, cx = cy0 + r, cx0 + c
                    tr, tc = (7 - r if yf else r), (7 - c if xf else c)
                    wgt = COVERED_WEIGHT if (cy, cx) in seen else 1.0
                    spots[t][tr * 8 + tc].append((fi, cy, cx, wgt))
            for r in range(8):
                for c in range(8):
                    seen.add((cy0 + r, cx0 + c))
        order.append(lst)
    _CACHE[key] = (spots, order)
    return _CACHE[key]


def _targets(frames):
    """{frame: 16x16 rows of 0-3} -> per frame a dict {(cy, cx): v != 0}."""
    out = []
    for f in FRAMES:
        rows = frames[f]
        d = {}
        for y in range(16):
            for x in range(16):
                v = rows[y][x]
                if v:
                    d[(BOX[1] + y, BOX[0] + x)] = v
        out.append(d)
    return out


def render(tiles, lid, repo=None):
    """16 tiles (each 8 rows of 8 values 0-3) through layout `lid` -> per
    frame {(cy, cx): v != 0} as the game draws it (entry 0 on top)."""
    _spots, order = _plan(lid, repo)
    out = []
    for lst in order:
        d = {}
        for t, xf, yf, cy0, cx0 in reversed(lst):      # lowest priority first
            g = tiles[t]
            for r in range(8):
                row = g[7 - r if yf else r]
                for c in range(8):
                    v = row[7 - c if xf else c]
                    if v:
                        d[(cy0 + r, cx0 + c)] = v
        out.append(d)
    return out


def error(drawn, targets):
    """Pixels the game draws differently from the sheet, per frame."""
    errs = []
    for d, t in zip(drawn, targets):
        keys = set(d) | set(t)
        errs.append(sum(1 for k in keys if d.get(k, 0) != t.get(k, 0)))
    return errs


def pack(frames, lid, repo=None):
    """frames = {frame name: 16 rows of 16 colour indices 0-3} (0 =
    transparent) -> (tiles [16][8][8], total error, per-frame errors)."""
    spots, _order = _plan(lid, repo)
    tg = _targets(frames)
    rank = {fi: k for k, fi in enumerate(VOTE_ORDER)}
    tiles = []
    for t in range(16):
        g = [[0] * 8 for _ in range(8)]
        for p in range(64):
            sp = spots[t][p]
            if not sp:
                continue
            score = {}
            first = {}
            for fi, cy, cx, wgt in sp:
                v = tg[fi].get((cy, cx), 0)
                score[v] = score.get(v, 0) + wgt
                first[v] = min(first.get(v, 99), rank[fi])
            g[p // 8][p % 8] = max(score, key=lambda v: (score[v], -first[v]))
        tiles.append(g)
    errs = error(render(tiles, lid, repo), tg)
    return tiles, sum(errs), errs


def payload(tiles):
    """16 tiles -> the 256-byte 2bpp walking art."""
    out = bytearray()
    for g in tiles:
        for row in g:
            lo = hi = 0
            for v in row:
                lo = (lo << 1) | (v & 1)
                hi = (hi << 1) | ((v >> 1) & 1)
            out += bytes((lo, hi))
    return bytes(out)


def follower_bank(sid):
    """The follower bank of species `sid` (0-127 -> $10, the rest -> $11)."""
    return 0x10 if sid < 0x80 else 0x11


def fit_all(frames, sid=None, repo=None):
    """Every layout ranked for these frames: [(error, lid)], best first.
    Ties: the monster's own original layout, then a layout that already
    exists in its follower bank (no copy), then the lower id."""
    own = species_layout(sid, repo) if sid is not None and sid <= 214 else None
    bank = follower_bank(sid) if sid is not None else 0x11
    res = []
    for lid in range(count(repo)):
        _t, err, _e = pack(frames, lid, repo)
        res.append((err, lid != own, native_l2(lid, bank, repo) is None, lid))
    res.sort()
    return [(r[0], r[3]) for r in res]


def label(lid, sid=None, repo=None):
    """'layout 29 — like Healer, Snaily' for the pickers."""
    from . import gamedata as G
    names = G.monster_names(repo or REPO)
    us = users(lid, repo)
    who = ', '.join(names.get(s, f'#{s}') for s in us[:3]) + (' …' if len(us) > 3 else '')
    return f'layout {lid} — walks like {who}' if who else f'layout {lid}'


# ---------------------------------------------------------------------------
# copies into the other follower bank (the compiler)
# ---------------------------------------------------------------------------

# Where each bank's copy region starts and how much room it has: bank $10 =
# the original bank's zero tail ($7A83-$7FFF); bank $11 = after the
# new-species follower tables (patches/bank_011.asm, S107) up to $8000.
# test_compiler checks both against the built game.sym.
COPY_START = {0x10: 0x7A83, 0x11: 0x799E}
COPY_ROOM = {b: 0x8000 - a for b, a in COPY_START.items()}


def copy_label(bank, lid):
    return f'FollowerLayoutCopy{bank:02X}_L{lid}'


def bank_frames(bank, repo=None):
    """{stored bytes: address} of every frame the bank's species use."""
    key = ('bf', repo or REPO, bank)
    if key not in _CACHE:
        d = {}
        for a, h in data(repo)['bank_frames'][f'{bank:02x}']:
            d.setdefault(bytes.fromhex(h), a)
        _CACHE[key] = d
    return _CACHE[key]


def copies(needed, repo=None):
    """needed = {bank: set(layout ids)} -> {bank: (asm text, bytes used)}.
    Each copy = a level-2 table (6 dw) + only the frames the bank (or an
    earlier copy) does not already hold byte-for-byte. Raises LayoutError
    when a bank's free tail is too small."""
    out = {}
    for bank in BANKS:
        lids = sorted(needed.get(bank) or ())
        have = bank_frames(bank, repo)
        own = {}                    # bytes -> label of a frame stored by this region
        tables, frames_txt, used = [], [], 0
        for lid in lids:
            L = layout(lid, repo)
            raws = [bytes.fromhex(h) for h in L['raw']]
            ptrs = []
            for j in range(6):
                r = raws[L['share'][j]]
                if r in have:
                    ptrs.append(f'${have[r]:04X}')
                elif r in own:
                    ptrs.append(own[r])
                else:
                    lb = f'{copy_label(bank, lid)}_{FRAMES[j]}'
                    own[r] = lb
                    ptrs.append(lb)
                    frames_txt.append(f'{lb}:')
                    for o in range(0, len(r) - 1, 4):
                        frames_txt.append('    db ' + ', '.join(f'${x:02X}' for x in r[o:o + 4]))
                    frames_txt.append('    db $80')
                    used += len(r)
            tables.append(f'{copy_label(bank, lid)}:   ; {label(lid, repo=repo)}')
            tables.append('    dw ' + ', '.join(ptrs))
            used += 12
        if used > COPY_ROOM[bank]:
            raise LayoutError(
                f"walking layouts: the {len(lids)} layouts copied into follower bank "
                f"${bank:02X} need {used} bytes; its free tail holds {COPY_ROOM[bank]} — "
                "choose layouts that already exist in that bank for some monsters "
                "(the sheet dialog marks them)")
        out[bank] = ('\n'.join(tables + frames_txt), used)
    return out


def needed(prj):
    """{bank: set(layout ids)} the project's walking art needs copied: an
    original monster's chosen layout that its bank lacks (gamedata.art) and a
    new species' layout that bank $11 lacks (custom.species)."""
    from . import art as A
    from . import species as SP
    out = {b: set() for b in BANKS}
    repo = getattr(prj, 'repo_root', None)
    for sid, r in A.resolve(prj, with_art=False).items():
        lid = r.get('layout')
        if lid is not None:
            b = follower_bank(sid)
            if native_l2(lid, b, repo) is None:
                out[b].add(lid)
    for s in SP.resolve(prj, with_art=False):
        lid = s.get('layout')
        if lid is not None and native_l2(lid, 0x11, repo) is None:
            out[0x11].add(lid)
    return out


def l2_ref(lid, bank, repo=None):
    """What a level-1 entry holds for layout `lid` in `bank`: the native
    address (int) or the copy's label (str)."""
    a = native_l2(lid, bank, repo)
    return a if a is not None else copy_label(bank, lid)


def _emit_copies(bank):
    def emit(prj, warnings):
        txt, used = copies(needed(prj), getattr(prj, 'repo_root', None))[bank]
        head = (f"; walking layouts copied into follower bank ${bank:02X} (S107 P3.10 part 2b;"
                f" editor2/core/walk_layouts.py) — {used} of {COPY_ROOM[bank]} B\n")
        return head + (txt + '\n' if txt else '') + "    ds $8000 - @, $00   ; the bank's zero tail\n"
    emit.__name__ = f'emit_copies_{bank:02x}'
    return emit


REGIONS = [('lay_copies_10', 'patches/bank_010.asm', _emit_copies(0x10), 0x10),
           ('lay_copies_11', 'patches/bank_011.asm', _emit_copies(0x11), 0x11)]
