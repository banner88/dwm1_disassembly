"""tile_draw.py — draw a metatile pixel by pixel (S132, the Draw tab; no Qt).

User S132: "Allow editing tiles by pixel" → both ways of applying a drawing:

  (a) EVERYWHERE — the drawing replaces the 8×8 graphics in the tileset slots
      the metatile uses. No slot is spent, but every cell that draws those
      slots changes: on every screen / state of every room on this tileset
      (a room still on a game tileset gets its own copy first, so the game's
      other rooms keep theirs). `report()` counts the places beforehand.
  (b) AS A NEW METATILE — each quarter goes to a slot holding the same
      graphic already, else a FREE slot (the bottom-right quarter on the
      walkable / wall side asked for: it decides walkability, ROOM_DATA_FORMAT
      S94); the metatile joins My metatiles and can replace the selected cells
      or every cell of the room drawing the original.

A metatile = 4 quarters (tl, tr, bl, br) = 4 slot numbers + a palette slot per
quarter (`pal` int or list of 4). Pixels are colour numbers 0-3, 64 per
quarter, row-major. Slots $80-$AF are the common sheet every room has (font
and frames, ROM_DATA_FORMAT "Common tiles $80-$AF") — never written; a quarter
there can only be drawn as part of a new metatile. Slots a room animates are
rewritten by the game every few frames — edit those in the Animate tab.
"""

from .document import metatile_key, metatile_pals, val

QUARTERS = ('top-left', 'top-right', 'bottom-left', 'bottom-right')
COMMON_FIRST, COMMON_END = 0x80, 0xB0


def decode_tile(b16):
    """16 bytes of 2bpp -> 64 colour numbers."""
    out = []
    for y in range(8):
        lo, hi = b16[y * 2], b16[y * 2 + 1]
        for x in range(8):
            bit = 7 - x
            out.append((((hi >> bit) & 1) << 1) | ((lo >> bit) & 1))
    return out


def encode_tile(px):
    """64 colour numbers -> 16 bytes of 2bpp."""
    out = bytearray(16)
    for y in range(8):
        lo = hi = 0
        for x in range(8):
            v = px[y * 8 + x] & 3
            lo |= (v & 1) << (7 - x)
            hi |= ((v >> 1) & 1) << (7 - x)
        out[y * 2], out[y * 2 + 1] = lo, hi
    return bytes(out)


def quarter_pals(mt):
    """[tl, tr, bl, br] palette slots (0 when the metatile has none)."""
    return metatile_pals(mt) or [0, 0, 0, 0]


def metatile_pixels(sheet, mt, common_blocks=None):
    """The metatile's 4 quarters as colour numbers (common-sheet slots from
    `common_blocks`, the renderer's decoded $80-$AF tiles)."""
    out = []
    for t in mt['tiles']:
        if COMMON_FIRST <= t < COMMON_END:
            blk = (common_blocks or [])[t - COMMON_FIRST] if common_blocks else bytes(64)
            out.append(list(blk))
        else:
            t &= 0x7F
            out.append(decode_tile(bytes(sheet[t * 16:t * 16 + 16])))
    return out


def _cells_of_layout(grid):
    for cy in range(8):
        for cx in range(10):
            yield cx, cy, (grid[cy * 2][cx * 2], grid[cy * 2][cx * 2 + 1],
                           grid[cy * 2 + 1][cx * 2], grid[cy * 2 + 1][cx * 2 + 1])


def _layout_refs(doc, room):
    """[(screen, state, layout id)] of a room's editable layouts."""
    out = []
    for k in doc.screen_keys(room):
        for n in range(len(doc.states(room, k))):
            ref = doc.state_layout_ref(room, k, n) or {}
            if 'id' in ref and doc.has_layout(ref['id']):
                out.append((k, n, ref['id']))
    return out


def places_drawing(doc, rooms, slots):
    """{room id: number of cells (each layout counted once) that draw any of
    `slots`}."""
    slots = set(slots)
    out = {}
    for room in rooms:
        seen, n = set(), 0
        for _k, _n, lid in _layout_refs(doc, room):
            if lid in seen:
                continue
            seen.add(lid)
            for _cx, _cy, q in _cells_of_layout(doc.layout(lid)['tiles']):
                if any((t & 0x7F) in slots and not COMMON_FIRST <= t < COMMON_END for t in q):
                    n += 1
        if n:
            out[room['id']] = n
    return out


def cells_with_metatile(doc, room, mt):
    """[(layout id, cx, cy)] of every cell of the room drawing metatile `mt`
    (tiles AND palettes when the room has an attr grid)."""
    want = tuple(mt['tiles'])
    out, seen = [], set()
    for _k, _n, lid in _layout_refs(doc, room):
        if lid in seen:
            continue
        seen.add(lid)
        for cx, cy, q in _cells_of_layout(doc.layout(lid)['tiles']):
            if q == want:
                out.append((lid, cx, cy))
    return out


def changed_quarters(old_px, new_px):
    return [i for i in range(4) if list(old_px[i]) != list(new_px[i])]


def report(doc, room, mt, old_px, new_px, threshold, walkable=None, own_sheet=None):
    """What each way would do — the facts the tab shows before acting.
    {'changed': [quarters], 'everywhere': {...}, 'new': {...}}"""
    tid = doc.tileset_key(room)
    on_project_sheet = 'tileset' in (room.get('record') or {})
    ch = changed_quarters(old_px, new_px)
    tiles = list(mt['tiles'])
    ev = {'ok': True, 'why': '', 'cells': 0, 'rooms': {}, 'slots': []}
    if not ch:
        ev.update(ok=False, why='Nothing drawn yet — the tile is unchanged.')
    common = [i for i in ch if COMMON_FIRST <= tiles[i] < COMMON_END]
    anim = doc.animated_slots(tid) if on_project_sheet else _room_anim_slots(doc, room)
    animq = [i for i in ch if (tiles[i] & 0x7F) in anim and i not in common]
    # the same slot drawn twice with different pixels cannot be "everywhere"
    clash = []
    for i in ch:
        for j in range(4):
            if j != i and tiles[j] == tiles[i] and list(new_px[j]) != list(new_px[i]):
                clash.append(i)
    if ev['ok'] and common:
        ev.update(ok=False, why=f"The {', '.join(QUARTERS[i] for i in common)} quarter "
                                'uses the common tiles every room shares (font / frames) — '
                                'draw it as a new metatile instead.')
    elif ev['ok'] and animq:
        ev.update(ok=False, why=f"The {', '.join(QUARTERS[i] for i in animq)} quarter is "
                                'ANIMATED in this room — the game redraws it every few frames. '
                                'Change its frames in the Animate tab, or draw a new metatile.')
    elif ev['ok'] and clash:
        ev.update(ok=False, why='Two quarters share one tile but are drawn differently — '
                                'draw it as a new metatile instead.')
    if ch:
        slots = sorted({tiles[i] & 0x7F for i in ch})
        rooms = doc.rooms_using_tileset(tid) if on_project_sheet else [room]
        per = places_drawing(doc, rooms, slots)
        ev['slots'] = slots
        ev['rooms'] = {doc.room_name(doc.room(r)): n for r, n in per.items()}
        ev['cells'] = sum(per.values())
        if not on_project_sheet:
            ev['note'] = ("This room still draws with a game tileset — it gets its own copy "
                          'first (other rooms on that tileset keep the original).')
    if mt.get('blank'):
        ev.update(ok=False, why='A blank tile has no place yet — save it as a new metatile.',
                  cells=0, rooms={})
    new = plan_new(doc, room, mt, new_px, threshold, walkable, own_sheet=own_sheet)
    return {'changed': ch, 'everywhere': ev, 'new': new}


def _room_anim_slots(doc, room):
    from editor2.core import animation as A
    try:
        return set(A.room_slots(room))
    except Exception:                                            # noqa: BLE001
        return set()


def _sheet_of(doc, room, own_sheet):
    rec = room.get('record') or {}
    if 'tileset' in rec:
        return doc.read_sheet(rec['tileset'])
    return bytearray(own_sheet)


def plan_new(doc, room, mt, new_px, threshold, walkable=None, own_sheet=None, sheet=None):
    """The slots a NEW metatile would use: reuse identical graphics, else free
    slots. {'ok', 'why', 'tiles': [4 slots or None], 'reuse': n, 'take': n,
    'free': {'wall', 'walkable'}}"""
    rec = room.get('record') or {}
    tid = doc.tileset_key(room)
    if sheet is None:
        if 'tileset' in rec:
            sheet = doc.read_sheet(tid)
        elif own_sheet is not None:
            sheet = bytearray(own_sheet)
        else:
            sheet = None
    on_project = 'tileset' in rec
    used = doc.used_tiles(tid) if on_project else _vanilla_used(doc, room)
    anim = doc.animated_slots(tid) if on_project else _room_anim_slots(doc, room)
    free = [i for i in range(128) if i not in used and i not in anim]
    if walkable is None:
        walkable = (mt['tiles'][3] & 0xFF) >= threshold if mt['tiles'][3] < 0x80 else True
    gfx = [encode_tile(p) for p in new_px]
    tiles, reuse, take = [None] * 4, 0, 0
    taken = {}
    why = ''
    for q in range(4):
        g = gfx[q]
        need_wall = (q == 3) and not walkable
        cand = None
        if g in taken and (q != 3 or ((taken[g] < threshold) == need_wall)):
            cand = taken[g]
        if cand is None and sheet is not None:
            for i in range(128):
                if i in anim or bytes(sheet[i * 16:i * 16 + 16]) != g:
                    continue
                if q == 3 and ((i < threshold) != need_wall):
                    continue
                cand = i
                reuse += 1
                break
        if cand is None:
            pool = [i for i in free if (i < threshold) == need_wall] if q == 3 else (
                [i for i in free if (i >= threshold) == bool(walkable)] or free)
            if not pool:
                side = 'wall' if need_wall else 'walkable'
                why = (f'The tileset has no free {side if q == 3 else ""} slot for the '
                       f'{QUARTERS[q]} quarter — free some on the Tileset tab (Purge unused), '
                       'or draw over an existing tile with "everywhere".').replace('  ', ' ')
                break
            cand = pool[-1] if need_wall else pool[0]
            free.remove(cand)
            take += 1
        taken.setdefault(g, cand)
        tiles[q] = cand
    nwall = sum(1 for i in free if i < threshold)
    return {'ok': not why, 'why': why, 'tiles': tiles if not why else None, 'reuse': reuse,
            'take': take, 'free': {'wall': nwall, 'walkable': len(free) - nwall},
            'walkable': walkable}


def _vanilla_used(doc, room):
    """Slots a room still on a game tileset must keep (it gets its own copy of
    the sheet; the copy's usage = this room's placements + vocabulary)."""
    out = set()
    for _k, _n, lid in _layout_refs(doc, room):
        for row in doc.layout(lid)['tiles']:
            out.update(t & 0x7F for t in row if not COMMON_FIRST <= t < COMMON_END)
    try:
        out |= set(doc.room_sources_vocab(room))
    except Exception:                                            # noqa: BLE001
        pass
    return out


# ------------------------------------------------------------------ apply
def apply_everywhere(doc, room_id, mt, old_px, new_px, threshold, own_sheet=None):
    """(a): write the drawn quarters into their slots. Returns a sentence."""
    room = doc.room(room_id)
    rep = report(doc, room, mt, old_px, new_px, threshold)
    ev = rep['everywhere']
    if not ev['ok']:
        raise ValueError(ev['why'])
    rec = room['record']
    tid = rec.get('tileset')
    if tid is None:
        if own_sheet is None:
            raise RuntimeError('room borrows a game tileset — pass own_sheet')
        tid = doc.localize_tileset(room, own_sheet)
    sheet = doc.read_sheet(tid)
    for q in rep['changed']:
        t = mt['tiles'][q] & 0x7F
        sheet[t * 16:t * 16 + 16] = encode_tile(new_px[q])
    doc.write_sheet(tid, sheet)
    return (f"redrew slot(s) {', '.join(f'${t:02X}' for t in ev['slots'])} — "
            f"{ev['cells']} cell(s) changed")


def apply_new(doc, room_id, mt, new_px, threshold, walkable=None, own_sheet=None,
              pal=None, name='drawn', place=None):
    """(b): a new metatile from the drawing. place = None (only add it to My
    metatiles) | 'room' (every cell of the room drawing `mt`) | [(layout id,
    cx, cy)] (those cells). Returns (new metatile, sentence)."""
    room = doc.room(room_id)
    rec = room['record']
    tid = rec.get('tileset')
    plan = plan_new(doc, room, mt, new_px, threshold, walkable, own_sheet=own_sheet)
    if not plan['ok']:
        raise RuntimeError(plan['why'])
    if tid is None:
        if own_sheet is None:
            raise RuntimeError('room borrows a game tileset — pass own_sheet')
        tid = doc.localize_tileset(room, own_sheet)
        plan = plan_new(doc, room, mt, new_px, threshold, walkable)
        if not plan['ok']:
            raise RuntimeError(plan['why'])
    sheet = doc.read_sheet(tid)
    for q, t in enumerate(plan['tiles']):
        sheet[t * 16:t * 16 + 16] = encode_tile(new_px[q])
    doc.write_sheet(tid, sheet)
    p = pal if pal is not None else (mt.get('pal', 0) if mt.get('pal') is not None else 0)
    doc.add_metatile(tid, name, list(plan['tiles']), p, src='drawn')
    new = {'name': name, 'tiles': list(plan['tiles']), 'pal': p}
    cells = []
    if place == 'room':
        cells = cells_with_metatile(doc, room, mt)
    elif place:
        cells = list(place)
    pals4 = quarter_pals(new)
    by_lid = {}
    for lid, cx, cy in cells:
        by_lid.setdefault(lid, []).append((cx, cy))
    attr_lids = _attr_lids(doc, room)
    for lid, xy in by_lid.items():
        ch, ach = [], []
        for cx, cy in xy:
            for q, (dr, dc) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
                ch.append((cy * 2 + dr, cx * 2 + dc, new['tiles'][q]))
                ach.append((cy * 2 + dr, cx * 2 + dc, pals4[q]))
        doc.set_cells(lid, 'tiles', ch)
        alid = attr_lids.get(lid)
        if alid and 'attr' in doc.layout(alid):
            doc.set_cells(alid, 'attr', ach)
    doc.touch()
    msg = (f"new metatile '{name}' (slots {', '.join(f'${t:02X}' for t in new['tiles'])}; "
           f"{plan['reuse']} reused, {plan['take']} taken)")
    if cells:
        msg += f' placed on {len(cells)} cell(s)'
    return new, msg


def _attr_lids(doc, room):
    """{tiles layout id: the attr layout id painted with it} — the per-screen
    attr grid (render.attr / screens[k].attr / the layout's own attr)."""
    out = {}
    for k, n, lid in _layout_refs(doc, room):
        lay = doc.layout(lid)
        if 'attr' in lay:
            out[lid] = lid
            continue
        try:
            note = doc.vanilla.attr_grid(room, k, n)[1] if doc.vanilla is not None else ''
        except Exception:                                        # noqa: BLE001
            note = ''
        cand = (note or '').split(' ')[0]
        if cand and doc.has_layout(cand) and 'attr' in doc.layout(cand):
            out[lid] = cand
    return out


__all__ = ['decode_tile', 'encode_tile', 'metatile_pixels', 'report', 'plan_new',
           'apply_everywhere', 'apply_new', 'cells_with_metatile', 'quarter_pals',
           'metatile_key', 'val']
