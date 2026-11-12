"""parking.py — parked metatiles: only tiles placed on screens hold tileset slots
(S171 r5, ROADMAP P3.3j; no Qt).

User (S171): "I added 38 metatiles and immediately get 'The tileset has no free walkable
slot for the bottom-right quarter' … Does purging remove the tiles from a selection? Like
there is a difference between having more than possible tiles AVAILABLE versus ACTUALLY
HAVING THEM DOWN ON THE SCREEN."

A My metatiles entry holds its four slots (tile_usage status 'mine') whether or not a
screen shows it. A PARKED metatile holds none: it keeps its own graphics (the four 8x8
2bpp pictures), the colour row of each quarter, the side of the bottom-right quarter
(walkable / wall) and — when the editor knows them — its REAL colours (recolour truth), in

    custom._editor.parked[tileset key] = [
        {'name', 'src', 'pal', 'tiles' (the slots it had — information only), 'walk',
         'q': [{'g': 32 hex digits, 'row': 0-3, 'true': recolour.Quarter json or None} x4]}]

(the compiler ignores `_editor`). The picker shows parked metatiles after My metatiles;
painting with one brings it back (`unpark`: identical graphics already in the sheet are
reused, the others take free slots — parking other unplaced metatiles first when the
sheet is full). Everything that brings new tiles in parks the unplaced My metatiles when
the sheet is full (`evicting`) and, when even the placed tiles leave no room, an import is
PARKED instead of refused (`park_new`).

Kept as they are (never parked): metatiles placed on any screen / state of a room on the
tileset, and metatiles using an animated / statue / service slot or a common-sheet tile
($80-$AF) — those slots mean something by their NUMBER, not their picture.
"""

from . import page2 as P2
from .document import NoFreeSlot, metatile_pals, val


# ------------------------------------------------------------------ the store
def parked(doc, tid):
    return ((doc.custom.get('_editor') or {}).get('parked') or {}).get(tid, [])


def _parked_mut(doc, tid):
    return doc.custom.setdefault('_editor', {}).setdefault('parked', {}).setdefault(tid, [])


def _threshold(doc, tid, threshold=None):
    if threshold is not None:
        return threshold
    for r in doc.rooms_using_tileset(tid):
        return val(r['record']['collision_threshold'])
    return 0x40


def _held(doc, tid):
    """Slots whose NUMBER matters (an animation writes them, a statue / service menu draws
    there): a metatile on one of them is never parked."""
    out = set(doc.animated_slots(tid)) | set(doc.service_slots_anywhere(tid))   # S177
    try:
        out |= set(doc.statue_slots(tid))
    except Exception:                                            # noqa: BLE001
        pass
    return out


def parkable(doc, tid):
    """Indices into doc.metatiles(tid) that may be parked: placed nowhere, no animated /
    statue / service slot, no common-sheet tile."""
    if ':' in str(tid):
        return []
    placed = doc.placed_metatile_keys(tid)
    held = _held(doc, tid)
    out = []
    for i, mt in enumerate(doc.metatiles(tid)):
        if any(P2.is_common(t) for t in mt['tiles']):
            continue
        keys = tuple(P2.slot_key(t) for t in mt['tiles'])
        if keys in placed or any(k in held for k in keys):
            continue
        out.append(i)
    return out


def preview(doc, tid, threshold=None):
    """(n parkable, slots freed {'wall', 'walkable'}) — nothing changes."""
    idx = set(parkable(doc, tid))
    if not idx:
        return 0, {'wall': 0, 'walkable': 0}
    thr = _threshold(doc, tid, threshold)
    before = doc.free_counts(tid, thr)
    lst = doc._metatiles_mut(tid)
    keep = list(lst)
    lst[:] = [m for i, m in enumerate(keep) if i not in idx]
    try:
        after = doc.free_counts(tid, thr)
    finally:
        lst[:] = keep
    return len(idx), {'wall': after['wall'] - before['wall'],
                      'walkable': after['walkable'] - before['walkable']}


def as_if_parked(doc, tid, fn):
    """(fn() computed as if the unplaced My metatiles were parked, how many) — nothing
    changes (the Draw tab's "new metatile" preview)."""
    idx = set(parkable(doc, tid))
    if not idx:
        return fn(), 0
    lst = doc._metatiles_mut(tid)
    keep = list(lst)
    lst[:] = [m for i, m in enumerate(keep) if i not in idx]
    try:
        return fn(), len(idx)
    finally:
        lst[:] = keep


def _sig(e):
    return (tuple((q['g'], int(q['row'])) for q in e['q']), bool(e.get('walk')))


def _entry(doc, tid, mt, sheet, rows, threshold):
    from . import recolour as RC
    from . import tile_draw as TD
    sheet = P2.pad_sheet(sheet)
    pals = TD.quarter_pals(mt)
    known = RC.truth_of_metatile(mt) or [None] * 4
    qs = []
    for q, t in enumerate(mt['tiles']):
        s = P2.slot_key(t)
        g = bytes(sheet[s * 16:s * 16 + 16])
        row = int(pals[q]) & 7
        tr = known[q] or RC.truth_at(doc, tid, t, row, sheet)
        if tr is None and rows is not None and row < len(rows):
            tr = RC.quarter_from_indices(TD.decode_tile(g), rows[row])
        qs.append({'g': g.hex(), 'row': row, 'true': tr.to_json() if tr is not None else None})
    e = {'name': mt.get('name', 'metatile'), 'tiles': [int(t) for t in mt['tiles']],
         'pal': mt.get('pal', 0), 'walk': P2.walkable(mt['tiles'][3], threshold), 'q': qs}
    if mt.get('src'):
        e['src'] = mt['src']
    return e


def park(doc, tid, indices, rows=None, threshold=None):
    """Move My metatiles `indices` of tileset `tid` to the parked list (their slots are
    free afterwards unless something else uses them). An identical parked one is not
    added twice. Returns the number parked."""
    idx = sorted(set(indices))
    if not idx:
        return 0
    thr = _threshold(doc, tid, threshold)
    sheet = doc.read_sheet(tid)
    lst = doc._metatiles_mut(tid)
    pk = _parked_mut(doc, tid)
    have = {_sig(e) for e in pk}
    for i in idx:
        e = _entry(doc, tid, lst[i], sheet, rows, thr)
        if _sig(e) not in have:
            have.add(_sig(e))
            pk.append(e)
    drop = set(idx)
    lst[:] = [m for i, m in enumerate(lst) if i not in drop]
    doc.touch()
    return len(idx)


def park_unplaced(doc, tid, rows=None, threshold=None):
    return park(doc, tid, parkable(doc, tid), rows, threshold)


def delete_parked(doc, tid, indices=None):
    """Forget parked metatiles (all when indices is None). Returns the number deleted."""
    pk = _parked_mut(doc, tid)
    drop = set(range(len(pk))) if indices is None else set(indices)
    n = sum(1 for i in drop if 0 <= i < len(pk))
    pk[:] = [e for i, e in enumerate(pk) if i not in drop]
    if n:
        doc.touch()
    return n


def copy_in_row(doc, tid, index, row):
    """S171 r6: a twin of parked entry `index` drawn in `row` (colour numbers kept — the same
    shapes in that row's colours). Returns the new entry's index."""
    pk = _parked_mut(doc, tid)
    e = {k: (list(v) if isinstance(v, list) else v) for k, v in pk[index].items() if k != 'q'}
    e['q'] = [{'g': q['g'], 'row': int(row), 'true': None} for q in pk[index]['q']]
    e['name'] = f"{pk[index].get('name', 'metatile')} (row {row})"
    e['pal'] = int(row)
    for i, x in enumerate(pk):
        if _sig(x) == _sig(e):
            return i
    pk.append(e)
    doc.touch()
    return len(pk) - 1


def park_new(doc, tid, name, px, pals, walk, truths=None, src='borrowed'):
    """An import with no room even after parking: it goes straight to the parked list
    (4 x 64 colour numbers, the row of each quarter, its walkable side). Returns the
    parked entry."""
    from . import tile_draw as TD
    qs = []
    for q in range(4):
        tr = (truths or [None] * 4)[q]
        qs.append({'g': TD.encode_tile(px[q]).hex(), 'row': int(pals[q]) & 7,
                   'true': tr.to_json() if tr is not None else None})
    e = {'name': name, 'tiles': [], 'pal': pals[0] if len(set(pals)) == 1 else list(pals),
         'walk': bool(walk), 'q': qs, 'src': src}
    pk = _parked_mut(doc, tid)
    if _sig(e) not in {_sig(x) for x in pk}:
        pk.append(e)
    doc.touch()
    e = dict(e)
    e['parked'] = True
    return e


# ------------------------------------------------------------------ pictures
def entry_pixels(e):
    """The parked metatile's 4 quarters as colour numbers."""
    from . import tile_draw as TD
    return [TD.decode_tile(bytes.fromhex(q['g'])) for q in e['q']]


def entry_rows(e):
    return [int(q['row']) for q in e['q']]


def _fit(e, rows):
    """(4 x 64 colour numbers, 4 rows, 4 truths) for bringing `e` back with `rows` (this
    screen's 4 rows of RGB): each quarter stays in its row; one whose real colours are
    known is matched to that row again when that beats its stored colour numbers (the
    row's colours changed since it was parked); otherwise it comes back exactly as it was."""
    from . import recolour as RC
    px, prow, truths = entry_pixels(e), entry_rows(e), []
    for q, d in enumerate(e['q']):
        tr = None
        if d.get('true'):
            try:
                tr = RC.Quarter.from_json(d['true'])
            except (KeyError, ValueError, TypeError):
                tr = None
        truths.append(tr)
        if tr is None or rows is None or len(rows) < 4:
            continue
        if prow[q] >= len(rows):
            continue
        # S171 r6: the row stays (it may have been chosen on purpose — "into row N", a copy
        # in another row); only the colour numbers are matched again when the row's colours
        # changed since (one-to-one: shapes kept)
        keep = RC.fixed_error(tr, px[q], rows[prow[q]])
        r, idx, err = RC.best_row(tr, rows, allowed=(prow[q],))
        if err < keep - 1e-6:
            px[q], prow[q] = idx, r
    return px, prow, truths


# ------------------------------------------------------------------ making room
def evicting(doc, room_id, rows, fn, threshold=None):
    """fn() — and when it finds no free slot: park the unplaced My metatiles of the room's
    tileset and try once more (NoFreeSlot again = the placed tiles fill the sheet)."""
    try:
        return fn()
    except NoFreeSlot:
        tid = doc.tileset_key(doc.room(room_id))
        if ':' in str(tid) or not park_unplaced(doc, tid, rows, threshold):
            raise
        return fn()


def full_message(doc, tid, threshold):
    u = doc.tile_usage(tid)
    c = {}
    for x in u:
        c[x['status']] = c.get(x['status'], 0) + 1
    fc = doc.free_counts(tid, threshold)
    return (f"The tiles placed on the screens fill this tileset — {c.get('placed', 0)} slots "
            f"placed, {c.get('mine', 0)} held by My metatiles that are placed or animated, "
            f"{c.get('vocab', 0)} vocabulary, {c.get('animated', 0)} animated; free: "
            f"{fc['wall']} wall / {fc['walkable']} walkable. Remove some tiles from the "
            'screens (or release unused vocabulary on the Tileset tab) to make room.')


def unpark(doc, room_id, index, rows, threshold, own_sheet=None):
    """Bring parked metatile `index` of the room's tileset back into the tileset (it joins
    My metatiles and can be painted). Returns (metatile, sentence). Raises NoFreeSlot when
    the PLACED tiles leave no room."""
    from . import recolour as RC
    from . import tile_draw as TD
    room = doc.room(room_id)
    tid0 = doc.tileset_key(room)
    pk = _parked_mut(doc, tid0)
    e = pk.pop(index)
    px, prow, truths = _fit(e, rows)
    pal = prow[0] if len(set(prow)) == 1 else list(prow)
    mt = {'tiles': list(e.get('tiles') or [0, 0, 0, 0]), 'pal': list(prow), 'name': e['name']}
    n_parked = [0]

    def go():
        return TD.apply_new(doc, room_id, mt, px, threshold, bool(e.get('walk')),
                            own_sheet=own_sheet, pal=pal, name=e['name'])
    try:
        new, _msg = go()
    except NoFreeSlot:
        tid = doc.tileset_key(doc.room(room_id))
        n_parked[0] = park_unplaced(doc, tid, rows, threshold) if ':' not in str(tid) else 0
        if not n_parked[0]:
            raise NoFreeSlot(full_message(doc, tid, threshold))
        try:
            new, _msg = go()
        except NoFreeSlot:
            raise NoFreeSlot(full_message(doc, tid, threshold)) from None
    tid = doc.tileset_key(doc.room(room_id))
    lst = doc._metatiles_mut(tid)
    if lst and lst[-1].get('tiles') == list(new['tiles']):
        if e.get('src'):
            lst[-1]['src'] = e['src']
        # the same metatile (slots + rows) already in My metatiles: keep one
        mine = [(list(m['tiles']), metatile_pals(m)) for m in lst[:-1]]
        if (list(new['tiles']), metatile_pals(lst[-1])) in mine:
            lst.pop()
    sheet = doc.read_sheet(tid)
    for tr, t, r in zip(truths, new['tiles'], prow):
        if tr is not None:
            RC.record_truth(doc, tid, t, r, tr, sheet)
    doc.touch()
    msg = f"'{e['name']}' is back in the tileset (slots {', '.join(P2.label(t) for t in new['tiles'])})"
    if n_parked[0]:
        msg += f' — {n_parked[0]} unplaced metatile(s) parked to make room'
    return new, msg


__all__ = ['parked', 'parkable', 'preview', 'as_if_parked', 'park', 'park_unplaced', 'delete_parked',
           'park_new', 'copy_in_row', 'entry_pixels', 'entry_rows', 'evicting', 'unpark', 'full_message']
