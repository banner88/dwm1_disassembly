"""anim_import.py — S173 r3: animation frames from a PNG onto selected cells
(EDITOR_DESIGN §5.1 "As built S173 r3"; help 15_animated_tiles "Import frames from a PNG").

The user (S173): "Allow the editor to import them then, please, rather than fiddling with my
project." — the Animate tab only had frames painted by hand.

  read_frames(img, cells_w, cells_h)   the frames of a strip: side by side or stacked, each
                                       the selection's size (16 px a cell), at any whole zoom
                                       (1-8×; every block one colour). S173 r5 transparency
                                       (user: "because you drew OVER other tiles I am concerned
                                       the background wont fit together"): a pixel with alpha 0
                                       keeps what the map shows there; a HALF-transparent pixel
                                       is LIGHT — its colour, except where the map is black
                                       (the wall's grain shows through); opaque = drawn
  plan(doc, renderer, room, key, state, lid, attr_lid, rect, frames)
                                       every 8×8 piece's palette row: a row of the room's
                                       palette that holds all its colours (across every frame;
                                       the piece's own row first), else a NEW row on a row
                                       nothing using this palette draws (several pieces share
                                       one when their colours fit 4; own colour 1 turned on
                                       only when a row needs a colour 1 that is not the cream),
                                       else the nearest row's colours (counted, said)
  apply(doc, room_id, plan, speed, order, name, own_sheet)
                                       one Document change: the rows, frame 1 as tiles (a free
                                       slot on the same wall / walkable side as the tile it
                                       replaces; a piece that never changes reuses an identical
                                       tile), the colour rows of the cells, the cells' metatiles
                                       in My metatiles, and (2+ frames) the flip animation
                                       (`add_tile_anim`, private) — so every place later painted
                                       with those metatiles moves too, for no extra tiles

Pure logic (PIL only, no Qt). The Game Boy Color loads palette rows 0-3 of a room (KEY_LESSONS
S8); colour 3 is always black, colour 1 the cream unless the palette has its own colour 1
(`free_color1`, S96).
"""
from PIL import Image

from editor2.core import page2 as P2
from editor2.core import png_import as PI

CELL = 16
MAX_SCALE = 8


class ImportError_(RuntimeError):
    pass


# ------------------------------------------------------------------ the picture
def read_frames(img, cells_w, cells_h):
    """-> (frames: [PIL RGB, native size], info {'n', 'layout', 'scale'})."""
    img = img.convert('RGBA')
    W, H = img.size
    fw, fh = cells_w * CELL, cells_h * CELL
    for s in range(1, MAX_SCALE + 1):
        if W % s or H % s:
            continue
        w, h = W // s, H // s
        if h == fh and w % fw == 0:
            layout, n = 'side by side', w // fw
        elif w == fw and h % fh == 0:
            layout, n = 'stacked', h // fh
        else:
            continue
        if s > 1:
            px = img.load()
            if any(px[x, y] != px[(x // s) * s, (y // s) * s] for y in range(H) for x in range(W)):
                continue
            img = img.resize((w, h), Image.NEAREST)
        if n < 1:
            continue
        frames = []
        for i in range(n):
            box = (i * fw, 0, i * fw + fw, fh) if layout == 'side by side' else \
                (0, i * fh, fw, i * fh + fh)
            fr = img.crop(box)
            fr.putdata([(0, 0, 0, 0) if c[3] == 0 else PI.snap(c[:3]) + (c[3],)
                        for c in fr.getdata()])
            frames.append(fr)
        alpha = any(c[3] < 255 for f in frames for c in f.getdata())
        return frames, {'n': n, 'layout': layout, 'scale': s, 'alpha': alpha}
    raise ImportError_(
        f'the picture is {W}×{H}; for {cells_w}×{cells_h} cell'
        f'{"s" if cells_w * cells_h > 1 else ""} each frame is {fw}×{fh} pixels — put the frames '
        f'side by side ({fw}·n × {fh}) or one under the other ({fw} × {fh}·n), at 1× or a whole '
        f'zoom (2×, 3× … each block one colour)')


# ------------------------------------------------------------------ the plan
def _rows_drawn(doc, renderer, pid):
    """Palette rows (0-3) drawn by any screen / state of any room using palette `pid`."""
    out = set()
    for room in doc.rooms:
        for k in doc.screen_keys(room):
            for si in range(len(doc.states(room, k))):
                if doc.effective_palette(room, k, si) != pid:
                    continue
                a, _n = renderer.attr_grid(room, int(k), si)
                if a:
                    out |= {v & 7 for row in a for v in row}
                else:
                    out.add(0)
    return {r for r in out if r < 4}


def plan(doc, renderer, room, key, state, lid, attr_lid, rect, frames, taken=None, attr=None):
    """`taken` (S174 stamps, the editor's preview of what a build will do): rows earlier stamps
    are given on this palette — {'rows': {row: [4 RGB]}, 'free1': bool} — counted as drawn
    rows with those colours. `attr` (S174): the colour grid to read when the screen has no
    writable one yet (lid / attr_lid None: the plan is only looked at, never applied)."""
    c0, r0, c1, r1 = rect
    cw, ch = c1 - c0 + 1, r1 - r0 + 1
    if attr is None:
        if lid is None or lid not in doc._room_layout_ids(room):
            raise ImportError_('the canvas does not show an editable layout of this room — paint '
                               'once (or "Make editable") first')
        if attr_lid is None:
            raise ImportError_('this screen has no colour grid of its own to write the palette '
                               'rows into (Palettes → give the screen its own colours first)')
    pid = doc.effective_palette(room, key, state)
    shown = renderer.room_palettes(room, key, state)            # 8 x 4 RGB (forced 1/3 applied)
    pal = doc.palette(pid) if pid else None
    free1 = bool(pal and pal.get('free_color1')) or bool(taken and taken.get('free1'))
    drawn = _rows_drawn(doc, renderer, pid) if pid else {0, 1, 2, 3}
    A = attr if attr is not None else doc.layout(attr_lid)['attr']
    # the pieces (absolute subtile positions of the layout) and their pixels per frame;
    # see-through pixels take what the map shows now (alpha 0) or light it (half-transparent)
    pieces = [(r0 * 2 + j, c0 * 2 + i) for j in range(ch * 2) for i in range(cw * 2)]
    under = renderer.render_screen(room, key, state).convert('RGB').load()

    def comp(c, X, Y):
        if len(c) == 3 or c[3] == 255:
            return tuple(c[:3])
        u = tuple(under[X, Y])
        if c[3] == 0 or u == PI.BLACK:
            return u
        return tuple(c[:3])
    px = []                                             # px[f][piece] = 64 RGB
    for fr in frames:
        f_px = fr.load()
        px.append({(r, c): [comp(f_px[(c - c0 * 2) * 8 + x, (r - r0 * 2) * 8 + y],
                                 c * 8 + x, r * 8 + y)
                            for y in range(8) for x in range(8)] for (r, c) in pieces})
    colours = {p: set() for p in pieces}
    for f in px:
        for p in pieces:
            colours[p] |= set(f[p])
    rows = {r: [PI.snap(tuple(c)) for c in shown[r]] for r in range(4)}
    if taken:
        for r, cs in (taken.get('rows') or {}).items():
            rows[r] = [PI.snap(tuple(c)) for c in cs]
            drawn = set(drawn) | {r}
    rowsets = {r: set(rows[r]) for r in range(4)}
    assign, new_rows, notes = {}, {}, []
    # 1. a row that holds every colour of the piece (its own row first)
    for p in pieces:
        own = A[p[0]][p[1]] & 7
        order = ([own] if own < 4 else []) + [r for r in range(4) if r != own]
        hit = next((r for r in order if colours[p] <= rowsets[r]), None)
        if hit is not None:
            assign[p] = hit
    # 2. new rows on rows nothing draws (pieces share a row when their colours fit)
    left = [p for p in pieces if p not in assign]
    free_rows = [r for r in range(4) if r not in drawn]
    groups = []                                         # [colour set (no black)]
    need_free1 = False
    for p in sorted(left, key=lambda q: -len(colours[q])):
        cs = colours[p] - {PI.BLACK}
        placed = False
        for g in groups:
            if len(g['set'] | cs) <= 3:
                g['set'] |= cs
                g['pieces'].append(p)
                placed = True
                break
        if not placed:
            if len(cs) > 3:
                notes.append(f'piece ({p[1]},{p[0]}) has {len(cs) + (PI.BLACK in colours[p])} '
                             'colours — at most 4 (one of them black) in an 8×8 piece')
                continue
            groups.append({'set': set(cs), 'pieces': [p]})
    for g in groups:
        if not free_rows:
            break
        r = free_rows.pop(0)
        others = sorted(g['set'] - {PI.CREAM}, key=PI.luma)
        if len(others) <= 2:
            c1 = PI.CREAM                               # the engine's own colour 1: no hook needed
        else:                                           # 3 colours besides black, none cream
            c1 = others.pop()                           # the lightest becomes colour 1
            need_free1 = True
        while len(others) < 2:
            others.append(others[-1] if others else PI.BLACK)
        new_rows[r] = [others[0], c1, others[1], PI.BLACK]
        rows[r] = new_rows[r]
        rowsets[r] = set(new_rows[r])
        for p in g['pieces']:
            assign[p] = r
    # 3. the nearest row (counted)
    off = 0
    for p in pieces:
        if p in assign:
            continue
        best = min(range(4), key=lambda r: sum(min(PI.cdist(c, k) for k in rows[r])
                                               for f in px for c in f[p]))
        assign[p] = best
        off += sum(1 for f in px for c in f[p] if c not in rowsets[best])
    if need_free1 and pal is not None and not free1:
        # turning own colour 1 on must not change rows already drawn
        for r in drawn:
            c1 = pal['colors_rgb555'][r][1]
            if (int(c1, 16) if isinstance(c1, str) else int(c1)) & 0x7FFF != 0x6BFF:
                notes.append(f'row {r}\'s colour 1 is not the cream — turning own colour 1 on '
                             'would recolour what it draws')
    # the graphics: every frame quantized to the piece's row
    gfx = []
    for f in px:
        g = {}
        for p in pieces:
            row = rows[assign[p]]
            idx = [min(range(4), key=lambda i: PI.cdist(c, row[i])) for c in f[p]]
            g[p] = PI.encode_2bpp(idx)
        gfx.append(g)
    moving = [p for p in pieces if any(g[p] != gfx[0][p] for g in gfx[1:])]
    return {'room': room['id'], 'key': key, 'state': state, 'lid': lid, 'attr_lid': attr_lid,
            'rect': rect, 'pieces': pieces, 'assign': assign, 'new_rows': new_rows,
            'rows': rows, 'pid': pid, 'free1': need_free1 and not free1, 'off_px': off,
            'notes': notes, 'gfx': gfx, 'moving': moving, 'n': len(frames), 'rgb': px}


def preview(plan_, scale=4):
    """PIL pictures of the frames as the game will draw them."""
    c0, r0, c1, r1 = plan_['rect']
    W, H = (c1 - c0 + 1) * CELL, (r1 - r0 + 1) * CELL
    out = []
    for g in plan_['gfx']:
        im = Image.new('RGB', (W, H))
        for (r, c), b in g.items():
            row = plan_['rows'][plan_['assign'][(r, c)]]
            ix = PI.decode_2bpp(b)
            for y in range(8):
                for x in range(8):
                    im.putpixel(((c - c0 * 2) * 8 + x, (r - r0 * 2) * 8 + y), tuple(row[ix[y * 8 + x]]))
        out.append(im.resize((W * scale, H * scale), Image.NEAREST))
    return out


def tiles_needed(plan_):
    """New tileset slots at most (a piece that never changes may reuse an identical tile)."""
    return len(plan_['pieces'])


# ------------------------------------------------------------------ the change
def apply(doc, plan_, speed=32, order='loop', name='imported', own_sheet=None):
    room = doc.room(plan_['room'])
    rec = room['record']
    if 'tileset' not in rec:
        if own_sheet is None:
            own_sheet = doc._room_sheet_bytes(room)
        doc.localize_tileset(room, own_sheet)
    tid = rec['tileset']
    thr = int(str(rec['collision_threshold']), 0) if not isinstance(rec['collision_threshold'], int) \
        else rec['collision_threshold']
    # 1. the palette rows
    pid = plan_['pid']
    if plan_['new_rows']:
        if not pid:
            cur = doc.vanilla.room_palettes(room, plan_['key'], plan_['state'])
            words = [[PI.to555(c) for c in row] for row in cur[:8]]
            pid = doc.localize_palette(room, plan_['key'], plan_['state'], words)
        rows = doc.palette(pid)['colors_rgb555']
        for r, cs in plan_['new_rows'].items():
            rows[r] = [f'0x{PI.to555(c):04X}' for c in cs[:3]] + ['0x0000']
        if plan_['free1']:
            doc.palette(pid)['free_color1'] = True
    # 2. frame 1 as tiles: a free slot on the same side; a still piece reuses an identical tile
    sheet = bytearray(P2.pad_sheet(doc.read_sheet(tid)))
    used = doc.used_tiles(tid)
    avoid = doc.animated_slots(tid) | doc.service_slots(tid) | doc.own_anim_slots_tileset(tid)
    free = [s for s in range(P2.SLOTS) if s not in used and s not in avoid]
    T = doc.layout(plan_['lid'])['tiles']
    A = doc.layout(plan_['attr_lid'])['attr']
    took = []
    reused = 0
    for p in plan_['pieces']:
        r, c = p
        g = plan_['gfx'][0][p]
        wall = P2.is_wall(P2.slot_key(T[r][c]), thr)
        slot = None
        if p not in plan_['moving']:
            slot = next((s for s in sorted(used) if s not in avoid and P2.is_wall(s, thr) == wall
                         and bytes(sheet[s * 16:s * 16 + 16]) == g), None)
            if slot is not None:
                reused += 1
        if slot is None:
            cand = [s for s in free if P2.is_wall(s, thr) == wall]
            if not cand:
                raise ImportError_(f"no free {'wall' if wall else 'walkable'} tile left on the "
                                   'tileset — free some (Tileset tab: release / purge) and try '
                                   'again')
            slot = cand[0]
            free.remove(slot)
            sheet[slot * 16:slot * 16 + 16] = g
            used.add(slot)
            took.append(slot)
        T[r][c] = P2.value_of(slot)
        A[r][c] = (A[r][c] & ~7) | plan_['assign'][p]
    doc.write_sheet(tid, bytes(sheet))
    # 3. the cells' metatiles in My metatiles
    c0, r0, c1, r1 = plan_['rect']
    have = {tuple(m['tiles']) + (str(m.get('pal')),) for m in doc.metatiles(tid)}
    for cy in range(r0, r1 + 1):
        for cx in range(c0, c1 + 1):
            ps = [(cy * 2, cx * 2), (cy * 2, cx * 2 + 1), (cy * 2 + 1, cx * 2), (cy * 2 + 1, cx * 2 + 1)]
            tiles = [T[r][c] for r, c in ps]
            pals = [plan_['assign'][q] for q in ps]
            pal = pals[0] if len(set(pals)) == 1 else pals
            if tuple(tiles) + (str(pal),) not in have:
                doc.add_metatile(tid, f'{name} {cx - c0 + 1},{cy - r0 + 1}', tiles, pal)
    doc.touch()
    # 4. the animation
    item = None
    if plan_['n'] > 1:
        fr = []
        for g in plan_['gfx'][1:]:
            fr.append([[g[(r, c)] for c in range(c0 * 2, c1 * 2 + 2)]
                       for r in range(r0 * 2, r1 * 2 + 2)])
        item = doc.add_tile_anim(room['id'], plan_['lid'], plan_['rect'], 'flip', speed,
                                 frames=fr, order=order, name=name, private=True,
                                 own_sheet=own_sheet)
    rows_txt = ', '.join(f'row {r}' for r in sorted(plan_['new_rows']))
    doc.last_import_note = (
        f"{plan_['n']} frame{'s' if plan_['n'] != 1 else ''} on {len(plan_['pieces']) // 4} cell"
        f"{'s' if len(plan_['pieces']) > 4 else ''}: {len(took)} new tile{'s' if len(took) != 1 else ''}"
        + (f', {reused} reused' if reused else '')
        + (f'; new colours on {rows_txt}' if rows_txt else '')
        + ('; own colour 1 turned on' if plan_['free1'] else '')
        + (f'; {plan_["off_px"]} pixel(s) in the nearest colour' if plan_['off_px'] else '')
        + (f'; one step every {speed} frames' if item else ''))
    return item
