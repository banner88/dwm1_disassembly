"""stamps.py — S174 (ROADMAP P3.3m): pictures STAMPED on top of a room's tiles.

The user (S174): "Allow me to 'stamp' these types of things (torches but there might be more in
the future so we need this TYPE of image) on top of any tiles. This should automatically use
the tiles behind to deal with transparency etc. I should be able to remove this stamp and put it
elsewhere or copy and paste etc. When I remove it put the tiles back as before and don't create
a million random crappy broken tiles as a result of this." Conferred: "Nearest should be fine
but warn"; 16-pixel cells; "only that screen"; an unlit option; the halo colour can be set.

A stamp is NOT paint. project.json keeps
  custom.stamps[]       the library: {"id", "name", "png" (project-relative), "w", "h" (cells
                        of one frame), "frames", "speed" (game frames per step; 32 = the
                        game's torches)}
  rooms[].stamps[]      the placements: {"stamp", "screen", "x", "y" (the top-left cell; may
                        hang off the screen — the part off it is dropped), "lit" (default
                        true), "light" ("#rrggbb" or absent = as drawn)}
and the colour rows it needs (S174 r2, below: written into the project's palette when it is
placed — visible, reusable by tiles — and recorded on the placement as "rows"); the room's
layouts, colour grids, tiles, animations and tileset files are never touched by placing,
moving or removing one. The BUILD bakes the stamps into a COPY of the project
(`baked_dir` → compiler.compile_project / measure_banks, capacity.measure): per screen state,
its own layout + colour grid (copied only when shared — "only that screen"), the picture
composited over the tiles as they are (anim_import.plan: clear = the tiles stay, half-clear =
light, solid = drawn), the colour rows planned (existing / new free rows / nearest — counted and
warned), the pieces as tiles (a piece identical to an existing one reuses it; an animated piece
identical to one this room already animates reuses that slot too) and one flip animation per
placement. Removing a stamp therefore leaves exactly the tiles there were — nothing to clean up.

The PNG: frames side by side (or stacked), each `w` × `h` cells (16 px a cell), at 1× or a whole
zoom. Alpha 0 = the tiles behind stay; half-transparent = LIGHT (the colour over the tiles,
except where they are black — the grain shows through); opaque = drawn as is. `lit` off: the
half-transparent pixels are left out (the stamp drawn without its light). `light`: the
half-transparent pixels take this colour instead of the PNG's.

Pure logic (PIL only, no Qt).
"""
import atexit
import json
import os
import re
import shutil
import tempfile

from PIL import Image

from editor2.core import anim_import as AI
from editor2.core import page2 as P2
from editor2.core import png_import as PI

CELL = 16
CELLS_W, CELLS_H = 10, 8                    # one screen: 10 x 8 cells (20 x 16 tiles)
SPEED_DEFAULT = 32                          # the game's torches (a swap every 32 frames)
MAX_FRAMES = 8                              # tileanim.MAX_FRAMES
ANIM_CHUNK = 32                             # tileanim.MAX_SLOTS: tiles per animation item

# the light colours the editor offers (the PNG's own first); GBC-exact (5 bits a channel)
LIGHTS = [
    ('As drawn', None),
    ('Amber', (240, 192, 72)),
    ('Gold', (248, 216, 120)),
    ('Orange', (248, 152, 48)),
    ('Red', (240, 96, 72)),
    ('Pale blue', (136, 184, 248)),
    ('Green', (136, 216, 112)),
    ('Violet', (192, 144, 248)),
]


class StampError(RuntimeError):
    pass


# ------------------------------------------------------------------ the library
def library(custom):
    return list(custom.get('stamps') or [])


def stamp_of(custom, sid):
    return next((s for s in custom.get('stamps') or [] if s.get('id') == sid), None)


def placements(room):
    return list(room.get('stamps') or [])


def has_stamps(data):
    c = data.get('custom') or {}
    return bool(c.get('stamps')) or any(r.get('stamps') for r in c.get('rooms') or []
                                        if isinstance(r, dict))


def guess_size(img, name=''):
    """(w, h) cells of ONE frame: "3x2" in the file name, else one frame of the whole picture
    (at the smallest zoom that makes it whole cells)."""
    m = re.search(r'(\d+)\s*[x×]\s*(\d+)', os.path.basename(name or ''))
    if m:
        w, h = int(m.group(1)), int(m.group(2))
        if 1 <= w <= CELLS_W and 1 <= h <= CELLS_H:
            return w, h
    W, H = img.size
    for s in range(1, AI.MAX_SCALE + 1):
        if W % (CELL * s) == 0 and H % (CELL * s) == 0:
            return max(1, min(CELLS_W, W // (CELL * s))), max(1, min(CELLS_H, H // (CELL * s)))
    return 1, 1


def read_png(path, w, h):
    """-> (frames [PIL RGBA at 1×], info) — anim_import.read_frames' rules."""
    frames, info = AI.read_frames(Image.open(path), w, h)
    if len(frames) > MAX_FRAMES:
        raise StampError(f'{len(frames)} frames — a stamp can have at most {MAX_FRAMES}')
    return frames, info


_FRAME_CACHE = {}


def stamp_frames(project_dir, st):
    """The library stamp's frames (RGBA, 1×), cached by file + mtime."""
    path = os.path.join(project_dir, st['png'])
    try:
        mt = os.path.getmtime(path)
    except OSError:
        raise StampError(f"stamp {st.get('name') or st.get('id')}: its picture "
                         f"{st['png']} is missing from the project")
    key = (path, mt, int(st['w']), int(st['h']))
    if key not in _FRAME_CACHE:
        _FRAME_CACHE[key] = read_png(path, int(st['w']), int(st['h']))[0]
    return _FRAME_CACHE[key]


def parse_colour(v):
    if not v:
        return None
    if isinstance(v, (list, tuple)):
        return PI.snap(tuple(int(x) for x in v[:3]))
    s = str(v).lstrip('#')
    return PI.snap((int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)))


def colour_text(rgb):
    return '#%02x%02x%02x' % tuple(rgb)


def own_light(frames):
    """The stamp's own light colour: the commonest colour of its half-transparent pixels."""
    n = {}
    for fr in frames:
        for c in fr.getdata():
            if 0 < c[3] < 255:
                n[c[:3]] = n.get(c[:3], 0) + 1
    return max(n, key=n.get) if n else None


def dressed(frames, pl):
    """The frames as this placement draws them: unlit = no light; `light` = its colour — the
    half-transparent pixels AND the drawn pixels of the stamp's own light colour (a torch's hot
    core is its light: changing one alone would put 5 colours in the flame's 8×8 pieces)."""
    lit = pl.get('lit', True)
    light = parse_colour(pl.get('light'))
    if lit and light is None:
        return frames
    old = own_light(frames)

    def px(c):
        if c[3] == 0:
            return c
        if c[3] == 255:
            return light + (255,) if (lit and light is not None and c[:3] == old) else c
        return (0, 0, 0, 0) if not lit else (light or c[:3]) + (c[3],)
    out = []
    for fr in frames:
        im = fr.copy()
        im.putdata([px(c) for c in fr.getdata()])
        out.append(im)
    return out


def visible(pl, st, frames=None):
    """(rect (c0, r0, c1, r1) of the cells on the screen, the frames cropped to it) or
    (None, None) when nothing of it is on the screen."""
    x, y, w, h = int(pl['x']), int(pl['y']), int(st['w']), int(st['h'])
    c0, r0 = max(0, x), max(0, y)
    c1, r1 = min(CELLS_W - 1, x + w - 1), min(CELLS_H - 1, y + h - 1)
    if c0 > c1 or r0 > r1:
        return None, None
    if frames is None:
        return (c0, r0, c1, r1), None
    box = ((c0 - x) * CELL, (r0 - y) * CELL, (c1 - x + 1) * CELL, (r1 - y + 1) * CELL)
    return (c0, r0, c1, r1), [f.crop(box) for f in frames]


def footprint(pl, st):
    """Every cell the stamp covers (on or off the screen)."""
    x, y = int(pl['x']), int(pl['y'])
    return {(x + i, y + j) for j in range(int(st['h'])) for i in range(int(st['w']))}


def clash(custom, room, key, pl, st, skip=None):
    """The index of another stamp on this screen whose cells overlap, else None. (Overlapping
    stamps would bake one over the other's first frame — they are kept apart.)"""
    mine = footprint(pl, st) & {(c, r) for c in range(CELLS_W) for r in range(CELLS_H)}
    for i, o in enumerate(placements(room)):
        if i == skip or int(o.get('screen', -1)) != int(key):
            continue
        ost = stamp_of(custom, o.get('stamp'))
        if ost and mine & footprint(o, ost):
            return i
    return None


def at_cell(custom, room, key, cell):
    """Index of the stamp covering this cell of screen `key` (the last one drawn), else None."""
    for i in range(len(placements(room)) - 1, -1, -1):
        o = room['stamps'][i]
        if int(o.get('screen', -1)) != int(key):
            continue
        st = stamp_of(custom, o.get('stamp'))
        if st and tuple(cell) in footprint(o, st):
            return i
    return None


def hold_row(frames):
    """The cell row a stamp is HELD by (S176): the first row with a solid pixel in any frame —
    a wall torch's flame, whatever glow is drawn above it. 0 when nothing is solid."""
    top = None
    for fr in frames:
        a = fr.getchannel('A').point(lambda v: 255 if v == 255 else 0)
        box = a.getbbox()
        if box is not None:
            top = box[1] if top is None else min(top, box[1])
    return (top or 0) // CELL


def anchor(st, cell):
    """Top-left cell for a stamp held by the cursor at `cell`: the cursor on its middle column
    and on its `hold` row (S176: the first row with solid pixels — a wall torch: the flame
    under the cursor, the top of its glow above it, off the screen on the top row)."""
    return (int(cell[0]) - (int(st['w']) - 1) // 2,
            int(cell[1]) - int(st.get('hold') or 0))


# ------------------------------------------------------------------ editing (one undo step each)
def _slug(name):
    s = ''.join(ch if ch.isalnum() else '_' for ch in (name or 'stamp').lower()).strip('_')
    return s[:24] or 'stamp'


def add_to_library(doc, path, name, w, h, speed=SPEED_DEFAULT):
    """Copy the PNG into the project (assets/stamps/<id>.png) and list it. -> the new id."""
    frames, _info = read_png(path, int(w), int(h))
    lib = doc.custom.setdefault('stamps', [])
    ids = {x.get('id') for x in lib}
    base = _slug(name)
    sid, n = base, 2
    while sid in ids or os.path.exists(os.path.join(doc.project_dir, 'assets', 'stamps',
                                                    f'{sid}.png')):
        sid = f'{base}_{n}'
        n += 1
    rel = os.path.join('assets', 'stamps', f'{sid}.png')
    os.makedirs(os.path.join(doc.project_dir, 'assets', 'stamps'), exist_ok=True)
    shutil.copyfile(path, os.path.join(doc.project_dir, rel))
    lib.append({'id': sid, 'name': (name or sid).strip()[:40], 'png': rel.replace(os.sep, '/'),
                'w': int(w), 'h': int(h), 'frames': len(frames),
                'speed': int(speed or SPEED_DEFAULT)})
    hold = hold_row(frames)
    if hold:
        lib[-1]['hold'] = hold
    doc.touch()
    return sid


def replace_picture(doc, sid, path, w, h):
    """S176 (user: the torch's glow was cut flat — its PNG ended at the flame's tip): swap a
    library stamp's picture for another PNG (any size / frame count) and KEEP every placement:
    each stays where its solid part is — the cell under its hold row (the first row with solid
    pixels) and its middle column do not move, so a picture that grew a row of glow above the
    flame leaves every torch where it was. The new file is a new name in assets/stamps/ (the
    old one stays for undo). Refused, nothing changed, when a placement would leave its screen
    or overlap another stamp. -> [(room id, index)] of the placements (their colour rows must
    be claimed again by the caller)."""
    st = stamp_of(doc.custom, sid)
    if st is None:
        raise StampError(f'no stamp {sid!r} in the library')
    frames, _info = read_png(path, int(w), int(h))
    new_hold = hold_row(frames)
    dx = (int(st['w']) - 1) // 2 - (int(w) - 1) // 2
    dy = int(st.get('hold') or 0) - new_hold
    new_st = dict(st, w=int(w), h=int(h), frames=len(frames))
    was, now = f"{st['w']}x{st['h']}", f'{int(w)}x{int(h)}'
    if was != now and was in str(st.get('name') or ''):       # "Wall torch 3x2" -> "… 3x3"
        new_st['name'] = st['name'].replace(was, now)
    new_st.pop('hold', None)
    if new_hold:
        new_st['hold'] = new_hold
    moved = []
    for r in doc.rooms:
        if not isinstance(r, dict):
            continue
        for i, pl in enumerate(r.get('stamps') or []):
            if pl.get('stamp') == sid:
                moved.append((r, i, dict(pl, x=int(pl['x']) + dx, y=int(pl['y']) + dy)))
    name = st.get('name') or sid
    for r, i, pl in moved:
        where = f"{r.get('name') or r['id']} screen {pl['screen']}"
        if visible(pl, new_st)[0] is None:
            raise StampError(f'with the new picture the {name} on {where} would be off the '
                             'screen — move it first')
        mine = footprint(pl, new_st) & {(c, rr) for c in range(CELLS_W) for rr in range(CELLS_H)}
        for j, o in enumerate(r.get('stamps') or []):
            if j == i or int(o.get('screen', -1)) != int(pl['screen']):
                continue
            ost = new_st if o.get('stamp') == sid else stamp_of(doc.custom, o.get('stamp'))
            opl = next((m[2] for m in moved if m[0] is r and m[1] == j), o)
            if ost and mine & footprint(opl, ost):
                raise StampError(f'with the new picture two stamps on {where} would overlap — '
                                 'move one of them first')
    n = 2
    while True:
        rel = os.path.join('assets', 'stamps', f'{sid}_v{n}.png')
        if not os.path.exists(os.path.join(doc.project_dir, rel)):
            break
        n += 1
    os.makedirs(os.path.join(doc.project_dir, 'assets', 'stamps'), exist_ok=True)
    shutil.copyfile(path, os.path.join(doc.project_dir, rel))
    st.clear()
    st.update(new_st)
    st['png'] = rel.replace(os.sep, '/')
    for r, i, pl in moved:
        pl.pop('rows', None)
        r['stamps'][i] = pl
    doc.touch()
    return [(r['id'], i) for r, i, _pl in moved]


def uses(doc, sid):
    """[(room id, placement index)] of a library stamp."""
    return [(r['id'], i) for r in doc.rooms if isinstance(r, dict)
            for i, pl in enumerate(r.get('stamps') or []) if pl.get('stamp') == sid]


def remove_from_library(doc, sid):
    """The stamp and every placement of it (its PNG stays in assets/ — undo needs it)."""
    for r in doc.rooms:
        if isinstance(r, dict) and r.get('stamps'):
            r['stamps'] = [pl for pl in r['stamps'] if pl.get('stamp') != sid]
            if not r['stamps']:
                r.pop('stamps')
    doc.custom['stamps'] = [x for x in doc.custom.get('stamps') or [] if x.get('id') != sid]
    if not doc.custom['stamps']:
        doc.custom.pop('stamps')
    doc.touch()


def set_library(doc, sid, **kw):
    st = stamp_of(doc.custom, sid)
    if st is None:
        raise StampError(f'no stamp {sid!r}')
    for k, v in kw.items():
        st[k] = v
    doc.touch()


def place(doc, room_id, sid, key, x, y, lit=True, light=None):
    """A placement; refused when it overlaps another stamp on the screen. -> its index."""
    room = doc.room(room_id)
    st = stamp_of(doc.custom, sid)
    if st is None:
        raise StampError(f'no stamp {sid!r} in the library')
    pl = {'stamp': sid, 'screen': int(key), 'x': int(x), 'y': int(y)}
    if not lit:
        pl['lit'] = False
    if light:
        pl['light'] = light if isinstance(light, str) else colour_text(light)
    if visible(pl, st)[0] is None:
        raise StampError('the stamp would be off the screen')
    j = clash(doc.custom, room, key, pl, st)
    if j is not None:
        raise StampError('it would overlap another stamp on this screen — stamps cannot overlap '
                         '(move it, or move the other one first)')
    room.setdefault('stamps', []).append(pl)
    doc.touch()
    return len(room['stamps']) - 1


def move(doc, room_id, idx, x, y, key=None):
    room = doc.room(room_id)
    pl = room['stamps'][idx]
    st = stamp_of(doc.custom, pl['stamp'])
    new = dict(pl, x=int(x), y=int(y), screen=int(pl['screen'] if key is None else key))
    if visible(new, st)[0] is None:
        raise StampError('the stamp would be off the screen')
    if clash(doc.custom, room, new['screen'], new, st, skip=idx) is not None:
        raise StampError('it would overlap another stamp on this screen — stamps cannot overlap')
    room['stamps'][idx] = new
    doc.touch()


def remove(doc, room_id, idx):
    room = doc.room(room_id)
    room['stamps'].pop(idx)
    if not room['stamps']:
        room.pop('stamps')
    doc.touch()


def set_light(doc, room_id, idx, lit=None, light=False):
    """lit: True / False / None (unchanged); light: a colour, None (= as drawn) or False
    (unchanged)."""
    pl = doc.room(room_id)['stamps'][idx]
    if lit is not None:
        if lit:
            pl.pop('lit', None)
        else:
            pl['lit'] = False
    if light is not False:
        if light:
            pl['light'] = light if isinstance(light, str) else colour_text(light)
        else:
            pl.pop('light', None)
    doc.touch()


# ------------------------------------------------------------------ the rows a stamp owns (r2)
# S174 r2 (user: "Make the fucking torches explicit and populate the fucking palette so that it
# reflects what the torches do then I can use that colour combination in specific tiles
# currently it just fucking pretends its not there."): placing (moving, re-lighting) a stamp
# WRITES the colour rows it needs into the project's palette — they show on the Palettes page
# and any tile can be painted with them — and the placement records them
# (`"rows": {palette id: [rows]}`). A row a stamp records counts as used: no other stamp (and no
# build) takes it for other colours. Removing the stamp leaves the colours in the palette.
def claimed_rows(doc, pid, skip=None):
    """Rows of palette `pid` that placements record (except `skip` = (room id, index))."""
    out = set()
    for r in doc.rooms:
        if not isinstance(r, dict):
            continue
        for i, pl in enumerate(r.get('stamps') or []):
            if (r['id'], i) == skip:
                continue
            out |= set((pl.get('rows') or {}).get(pid) or [])
    return out


def rows_report(doc, pid):
    """{row: [stamp names]} — which stamps use which rows of palette `pid` (Palettes page)."""
    out = {}
    for r in doc.rooms:
        if not isinstance(r, dict):
            continue
        for pl in r.get('stamps') or []:
            st = stamp_of(doc.custom, pl.get('stamp'))
            for row in (pl.get('rows') or {}).get(pid) or []:
                nm = st['name'] if st else pl.get('stamp')
                if nm not in out.setdefault(int(row), []):
                    out[int(row)].append(nm)
    return out


def _protected(doc, renderer, room, key, s, pid, skip):
    """plan(taken=…): the rows other stamps own on this palette, as they are, counted drawn."""
    shown = renderer.room_palettes(room, key, s)
    return {'rows': {r: shown[r] for r in claimed_rows(doc, pid, skip) if r < 4}, 'free1': False}


def claim(doc, repo, room_id, idx):
    """Write the colour rows placement `idx` needs into the project's palette (rows no tile and
    no other stamp uses), record them on the placement. -> warning text ('' = it fits)."""
    from editor2.core.render_project import ProjectRenderer
    room = doc.room(room_id)
    pl = room['stamps'][idx]
    st = stamp_of(doc.custom, pl.get('stamp'))
    key = int(pl.get('screen', -1))
    pl['rows'] = {}
    if st is None or str(key) not in (room.get('screens') or {}):
        doc.touch()
        return ''
    rect, fr = visible(pl, st, dressed(stamp_frames(doc.project_dir, st), pl))
    if rect is None:
        doc.touch()
        return ''
    warns = []
    old_vanilla = getattr(doc, 'vanilla', None)
    try:
        _claim_states(doc, repo, room, room_id, idx, pl, key, rect, fr, warns)
    finally:
        doc.vanilla = old_vanilla
    doc.touch()
    return '; '.join(warns)


def _claim_states(doc, repo, room, room_id, idx, pl, key, rect, fr, warns):
    from editor2.core.render_project import ProjectRenderer
    for s in range(len(doc.states(room, key))):
        r = ProjectRenderer(repo, doc.project_dir, doc.data)
        doc.vanilla = r
        pid = doc.effective_palette(room, key, s)
        if not pid:
            cur = r.room_palettes(room, key, s)
            pid = doc.localize_palette(room, key, s, [[PI.to555(c) for c in row] for row in cur[:8]])
            r = ProjectRenderer(repo, doc.project_dir, doc.data)
            doc.vanilla = r
        A, _n = r.attr_grid(room, key, s)
        p = AI.plan(doc, r, room, key, s, None, None, rect, fr,
                    taken=_protected(doc, r, room, key, s, pid, (room_id, idx)),
                    attr=[list(x) for x in (A or _zero_attr())])
        pal = doc.palette(pid)
        for rr, cs in p['new_rows'].items():
            pal['colors_rgb555'][rr] = [f'0x{PI.to555(c):04X}' for c in cs[:3]] + ['0x0000']
        if p['free1']:
            pal['free_color1'] = True
        # the rows it uses that no TILE draws (yet) — its own; a tile row it shares (the bark's
        # row 0 under a clear corner) stays the tiles'
        tiles_rows = AI._rows_drawn(doc, r, pid)
        mine = set((pl['rows'].get(pid) or [])) | {int(v) for v in p['assign'].values()
                                                    if int(v) not in tiles_rows}
        pl['rows'][pid] = sorted(mine)
        w = warn_text(p)
        if w and w not in warns:
            warns.append(w)


def unclaimed(doc):
    """[(room id, index)] of placements without recorded rows (placed before S174 r2)."""
    return [(r['id'], i) for r in doc.rooms if isinstance(r, dict)
            for i, pl in enumerate(r.get('stamps') or []) if 'rows' not in pl]


# ------------------------------------------------------------------ editor preview
def _zero_attr():
    return [[0] * (CELLS_W * 2) for _ in range(CELLS_H * 2)]


def simulate(doc, renderer):
    """What a build will draw: {(room id, placement index, state): {'rect', 'frames' [PIL RGB,
    as the game draws them], 'speed', 'n', 'warn' (text or ''), 'error' (text or '')}}.
    Every stamp in build order (rooms, then placements, then states), the colour rows the
    earlier ones take counted (`anim_import.plan(taken=…)`), nothing changed."""
    out = {}
    taken = {}
    custom = doc.custom
    for room in doc.rooms:
        if not isinstance(room, dict) or not room.get('stamps'):
            continue
        for i, pl in enumerate(room['stamps']):
            st = stamp_of(custom, pl.get('stamp'))
            key = int(pl.get('screen', -1))
            if st is None or str(key) not in (room.get('screens') or {}):
                continue
            try:
                frames = dressed(stamp_frames(doc.project_dir, st), pl)
            except (StampError, AI.ImportError_, OSError) as e:
                for s in range(len(doc.states(room, key))):
                    out[(room['id'], i, s)] = {'rect': None, 'frames': [], 'speed': 32, 'n': 0,
                                               'warn': '', 'error': str(e)}
                continue
            rect, fr = visible(pl, st, frames)
            for s in range(len(doc.states(room, key))):
                if rect is None:
                    continue
                pid = doc.effective_palette(room, key, s)
                tk = taken.setdefault(pid or ('own', room['id'], key, s), {'rows': {}, 'free1': False})
                A, _n = renderer.attr_grid(room, key, s)
                prot = _protected(doc, renderer, room, key, s, pid, (room['id'], i))  # r2
                tk2 = {'rows': {**prot['rows'], **tk['rows']}, 'free1': tk['free1']}
                try:
                    p = AI.plan(doc, renderer, room, key, s, None, None, rect, fr, taken=tk2,
                                attr=[list(r) for r in (A or _zero_attr())])
                except Exception as e:                       # noqa: BLE001 — shown, never fatal
                    out[(room['id'], i, s)] = {'rect': rect, 'frames': [], 'speed': 32, 'n': 0,
                                               'warn': '', 'error': str(e)}
                    continue
                tk['rows'].update(p['new_rows'])
                tk['free1'] = tk['free1'] or p['free1']
                out[(room['id'], i, s)] = {
                    'rect': rect, 'frames': AI.preview(p, scale=1),
                    'speed': int(st.get('speed') or SPEED_DEFAULT), 'n': p['n'],
                    'warn': warn_text(p), 'error': '', 'new_rows': sorted(p['new_rows']),
                    # S176: the rows its cells are baked with (screen_palettes.rows_drawn)
                    'rows': sorted({int(v) for v in p['assign'].values()})}
    return out


def warn_text(p):
    bits = []
    many = [n for n in p['notes'] if n.startswith('piece ')]
    if p['off_px']:
        why = (f"{len(many)} of its 8×8 pieces would need more than 4 colours over these tiles"
               if many else 'the palette has no free colour row left for its colours')
        bits.append(f"{p['off_px']} pixel{'s' if p['off_px'] != 1 else ''} drawn in the nearest "
                    f"colour ({why})")
    bits += [n for n in p['notes'] if n not in many]
    return '; '.join(bits)


# ------------------------------------------------------------------ the bake
def _attr_id(renderer, room, key, s):
    """The custom.layouts item whose attr grid is in effect for (screen, state), or None."""
    _a, note = renderer.attr_grid(room, key, s)
    if note and not note.startswith(('WARNING', 'vanilla', 'no ')):
        cand = note.split(' ')[0]
        if cand in renderer.layout_by_id and 'attr' in renderer.layout_by_id[cand]:
            return cand
    return None


def _users(doc, renderer):
    """{layout id: {(room id, key, state)} drawing its TILES}, {layout id: {… using its ATTR}}."""
    tiles, attrs = {}, {}
    for r in doc.rooms:
        if not isinstance(r, dict) or r.get('placeholder'):
            continue
        for k in doc.screen_keys(r):
            for s in range(len(doc.states(r, k))):
                ref = doc.state_layout_ref(r, k, s)
                if ref and 'id' in ref:
                    tiles.setdefault(ref['id'], set()).add((r['id'], k, s))
                a = _attr_id(renderer, r, k, s)
                if a:
                    attrs.setdefault(a, set()).add((r['id'], k, s))
    return tiles, attrs


def _set_state_ref(doc, room, key, s, field, ref):
    scr = doc.screen(room, key)
    if scr.get('states'):
        scr['states'][s][field] = ref
    else:
        scr[field] = ref


def _targets(doc, repo, room, key):
    """The screen's states grouped by what they draw (layout, colour grid, palette); each
    group given a layout + colour grid of its own (copied only when something else uses
    them). -> [(state indices, layout id, attr layout id)]."""
    from editor2.core.render_project import ProjectRenderer
    r = ProjectRenderer(repo, doc.project_dir, doc.data)
    groups = {}
    for s in range(len(doc.states(room, key))):
        ref = doc.state_layout_ref(room, key, s)
        a, _n = r.attr_grid(room, key, s)
        gk = (json.dumps(ref, sort_keys=True), json.dumps(a), str(doc.effective_palette(room, key, s)))
        groups.setdefault(gk, []).append(s)
    out = []
    for _gk, sts in groups.items():
        r = ProjectRenderer(repo, doc.project_dir, doc.data)
        doc.vanilla = r
        mine = {(room['id'], key, s) for s in sts}
        tusers, ausers = _users(doc, r)
        ref = doc.state_layout_ref(room, key, sts[0])
        grid, lid = r.layout_grid(ref)
        if lid is None or not tusers.get(lid, set()) <= mine or not ausers.get(lid, set()) <= mine:
            new = doc.unique_layout_id(f"{room['id']}_s{key}_stamps")
            doc.add_layout(new, tiles=grid, comment=f"{room['id']} screen {key}: stamps (build)")
            for s in sts:
                _set_state_ref(doc, room, key, s, 'layout', {'id': new})
            lid = new
            r = ProjectRenderer(repo, doc.project_dir, doc.data)
            tusers, ausers = _users(doc, r)
        aid = _attr_id(r, room, key, sts[0])
        if aid != lid or not ausers.get(lid, set()) <= mine:
            a, _n = r.attr_grid(room, key, sts[0])
            doc.layout(lid)['attr'] = [list(x) for x in (a or _zero_attr())]
            for s in sts:
                _set_state_ref(doc, room, key, s, 'attr', {'id': lid})
        out.append((sts, lid, lid))
    return out


def _apply(doc, room, p, speed, name, cache):
    """One placement onto one state group: the rows, the tiles (reusing identical ones), the
    colour grid, and a flip animation for the moving tiles nothing animates yet."""
    from editor2.core import tileanim as TA
    rec = room['record']
    if 'tileset' not in rec:
        doc.localize_tileset(room, doc._room_sheet_bytes(room))
    tid = rec['tileset']
    thr = int(str(rec['collision_threshold']), 0) if not isinstance(rec['collision_threshold'], int) \
        else rec['collision_threshold']
    pid = p['pid']
    if p['new_rows']:
        if not pid:
            cur = doc.vanilla.room_palettes(room, p['key'], p['state'])
            words = [[PI.to555(c) for c in row] for row in cur[:8]]
            pid = doc.localize_palette(room, p['key'], p['state'], words)
        rows = doc.palette(pid)['colors_rgb555']
        for r, cs in p['new_rows'].items():
            rows[r] = [f'0x{PI.to555(c):04X}' for c in cs[:3]] + ['0x0000']
        if p['free1']:
            doc.palette(pid)['free_color1'] = True
    sheet = bytearray(P2.pad_sheet(doc.read_sheet(tid)))
    used = doc.used_tiles(tid)
    avoid = doc.animated_slots(tid) | doc.service_slots(tid) | doc.own_anim_slots_tileset(tid)
    free = [s for s in range(P2.SLOTS) if s not in used and s not in avoid]
    T = doc.layout(p['lid'])['tiles']
    A = doc.layout(p['attr_lid'])['attr']
    moving_new = []                                   # [(slot, (frame bytes …))]
    took = reused = 0
    for q in p['pieces']:
        r, c = q
        g = tuple(gx[q] for gx in p['gfx'])
        wall = P2.is_wall(P2.slot_key(T[r][c]), thr)
        # only a cell's bottom-right tile decides walking (S94): it keeps its side; the
        # others may take any slot (page2.pick_order — their own side first)
        br = r % 2 == 1 and c % 2 == 1
        side_ok = (lambda s_: P2.is_wall(s_, thr) == wall) if br else (lambda s_: True)
        slot = None
        if q in p['moving']:
            slot = next((s_ for (rid, t_, g_, w_), s_ in cache.items()
                         if rid == room['id'] and t_ == tid and g_ == g and side_ok(s_)), None)
            if slot is not None:
                reused += 1
        else:
            slot = next((s for s in sorted(used) if s not in avoid and side_ok(s)
                         and bytes(sheet[s * 16:s * 16 + 16]) == g[0]), None)
            if slot is not None:
                reused += 1
        if slot is None:
            cand = P2.pick_order(free, thr, wall, br)
            if not cand:
                raise StampError(f"stamp {name}: no free {'wall' if wall else 'walkable'} tile left "
                                 f"on room {room.get('name') or room['id']}'s tileset — free some "
                                 '(Tileset tab: release / purge) or remove a stamp')
            slot = cand[0]
            free.remove(slot)
            sheet[slot * 16:slot * 16 + 16] = g[0]
            used.add(slot)
            took += 1
            if q in p['moving']:
                cache[(room['id'], tid, g, wall)] = slot
                moving_new.append((slot, g))
        T[r][c] = P2.value_of(slot)
        A[r][c] = (A[r][c] & ~7) | p['assign'][q]
    doc.write_sheet(tid, bytes(sheet))
    c0, r0, c1, r1 = p['rect']
    for k in range(0, len(moving_new), ANIM_CHUNK):
        chunk = moving_new[k:k + ANIM_CHUNK]
        item = {'id': doc._new_anim_id(room, f'stamp {name}'), 'name': f'stamp {name}',
                'motion': 'flip', 'speed': int(speed),
                'rows': [[s for s, _g in chunk]],
                'frames': [[g[f].hex() for _s, g in chunk] for f in range(1, p['n'])],
                'order': 'loop',
                'where': {'layout': p['lid'], 'x': c0, 'y': r0, 'w': c1 - c0 + 1, 'h': r1 - r0 + 1},
                'scope': 'here'}
        errs = TA.problems(room, doc.tile_anims(room) + [item], bytes(sheet),
                           doc.room_animation(room)['slots'])
        if errs:
            raise StampError(f"stamp {name} in room {room.get('name') or room['id']}: {errs[0]}")
        room.setdefault('tile_anims', []).append(item)
    doc.touch()
    return took, reused


def bake(doc, repo):
    """Every stamp of the (copied!) document into its tiles; the stamps removed. -> warnings."""
    from editor2.core.render_project import ProjectRenderer
    warnings = []
    custom = doc.custom
    cache = {}
    # r2: the rows each placement owns, kept from other stamps' new rows during the bake
    owned = {(r['id'], i): dict(pl.get('rows') or {}) for r in doc.rooms if isinstance(r, dict)
             for i, pl in enumerate(r.get('stamps') or [])}
    for room in doc.rooms:
        if not isinstance(room, dict) or not room.get('stamps'):
            continue
        pls = room.pop('stamps')
        rname = room.get('name') or room['id']
        for i, pl in enumerate(pls):
            st = stamp_of(custom, pl.get('stamp'))
            key = int(pl.get('screen', -1))
            if st is None:
                warnings.append(f"room {rname}: a stamp {pl.get('stamp')!r} that is not in the "
                                'library — left out')
                continue
            if str(key) not in (room.get('screens') or {}):
                warnings.append(f"room {rname}: stamp {st['name']} on screen {key}, which the room "
                                'does not have — left out')
                continue
            frames = dressed(stamp_frames(doc.project_dir, st), pl)
            rect, fr = visible(pl, st, frames)
            if rect is None:
                continue
            for sts, lid, alid in _targets(doc, repo, room, key):
                r = ProjectRenderer(repo, doc.project_dir, doc.data)
                doc.vanilla = r
                pid = doc.effective_palette(room, key, sts[0])
                shown = r.room_palettes(room, key, sts[0])
                prot = {x for k_, rows_ in owned.items() if k_ != (room['id'], i)
                        for x in (rows_.get(pid) or [])}
                p = AI.plan(doc, r, room, key, sts[0], lid, alid, rect, fr,
                            taken={'rows': {x: shown[x] for x in prot if x < 4}, 'free1': False})
                w = warn_text(p)
                if w:
                    warnings.append(f"room {rname} screen {key}: stamp {st['name']} at "
                                    f"({pl['x']},{pl['y']}): {w}")
                _apply(doc, room, p, int(st.get('speed') or SPEED_DEFAULT), st['name'], cache)
    custom.pop('stamps', None)
    for room in doc.rooms:
        if isinstance(room, dict):
            room.pop('stamps', None)
    return warnings


_TEMP = []


def _cleanup():
    for d in _TEMP:
        shutil.rmtree(d, ignore_errors=True)


atexit.register(_cleanup)


def baked_dir(data, project_dir, repo):
    """A COPY of the project (`data` + the project folder's files, not build/) with every stamp
    baked in. -> (folder, warnings). The folder lives until the process ends."""
    from editor2.core.document import Document
    dest = tempfile.mkdtemp(prefix='dwm_stamps_')
    _TEMP.append(dest)
    for f in os.listdir(project_dir):
        if f in ('build', 'project.json') or f.endswith('.tmp'):
            continue
        src = os.path.join(project_dir, f)
        if os.path.isdir(src):
            shutil.copytree(src, os.path.join(dest, f), ignore=shutil.ignore_patterns('build'))
        else:
            shutil.copy2(src, os.path.join(dest, f))
    with open(os.path.join(dest, 'project.json'), 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=1)
    doc = Document(os.path.join(dest, 'project.json'))
    warnings = bake(doc, repo)
    doc.save()
    return dest, warnings


def stamped(data, project_dir, repo):
    """(data, folder, warnings) to compile: the project itself when it has no stamps (the
    build is then byte-identical to before S174), else the baked copy."""
    if not has_stamps(data):
        return data, project_dir, []
    dest, warnings = baked_dir(data, project_dir, repo)
    return json.load(open(os.path.join(dest, 'project.json'), encoding='utf-8')), dest, warnings
