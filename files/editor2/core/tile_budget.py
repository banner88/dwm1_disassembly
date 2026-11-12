"""tile_budget.py — S177: where a room tileset's 256 slots went, and REPACK.

The user (S177): "Why project could not be built? … stamps: … no free walkable tile left on
room GreatLog's tileset … I barely finished 5 rooms so far is this an issue? Why am I getting
so few tiles? I thought a room could have 256 tiles at this point wtf?"

Measured on the user's project (S177): a room's tileset = 128 page-1 + 128 page-2 slots,
shared by every screen of the room. The collision threshold splits each page (tile n < the
threshold = WALL, S94; page-2 tile n walks like page-1 tile n, S168) — GreatLog's $50 (the
GreatTree copy's) leaves 48 walkable slots a page. Only a cell's BOTTOM-RIGHT quarter decides
walking (S94), yet 31 of its 42 walkable page-2 slots held top / left quarters (the import
order put a floor cell's every quarter on the walkable side), Grandpa's menu kept page 1's
$38-$7F off EVERY screen (S168 r2 — now his screen only, services.screen_reservations) and 85
page-1 slots still held GreatTree tiles nobody placed (vocabulary, until released).

  budget(doc, tid, thr, room=None, key=None) -> per side ('wall' / 'walkable'): what holds
      each slot — the words for the stamp / import errors and the Tileset tab.
  repack_plan / repack: move tiles that are never a bottom-right quarter (in any layout of a
      room on the sheet, any My metatile) off the scarcer side onto free slots of the roomier
      side — every layout and metatile follows (Document._remap_tile), nothing changes on
      screen; slots a cutscene / tile patch names, animated, statue, vocabulary and menu-kept
      slots never move.
"""
from editor2.core import page2 as P2

SIDES = ('walkable', 'wall')


def _side(slot, thr):
    return 'wall' if P2.is_wall(slot, thr) else 'walkable'


def _walk_tiles(obj, out):
    """Every tile value named in a cutscene `tiles` step / a tile patch (lists of 4 under a
    'tiles' key, or patch rows) — such slots are pinned (repack never moves them)."""
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == 'tiles' and isinstance(v, list) and v and not isinstance(v[0], list):
                for x in v:
                    try:
                        out.add(P2.slot_key(int(x, 0) if isinstance(x, str) else int(x)))
                    except (TypeError, ValueError):
                        pass
            else:
                _walk_tiles(v, out)
    elif isinstance(obj, list):
        for v in obj:
            _walk_tiles(v, out)


def pinned_slots(doc, tid):
    out = set()
    for r in doc.rooms_using_tileset(tid):
        _walk_tiles(r.get('cutscenes'), out)
        _walk_tiles(r.get('patch_data'), out)
    return out


def quarter_uses(doc, tid):
    """{slot: {'br', 'other'}} — how each slot is used: as a cell's bottom-right quarter (the
    one that decides walking) and / or another quarter (placed layouts + My metatiles)."""
    out = {}
    for lid in doc.layouts_using_tileset(tid):
        for r, row in enumerate(doc.layout(lid)['tiles']):
            for c, v in enumerate(row):
                out.setdefault(P2.slot_key(v), set()).add(
                    'br' if r % 2 == 1 and c % 2 == 1 else 'other')
    for mt in doc.metatiles(tid):
        for q, v in enumerate(mt.get('tiles') or []):
            out.setdefault(P2.slot_key(v), set()).add('br' if q == 3 else 'other')
    return out


def budget(doc, tid, thr, room=None, key=None):
    """{'walkable' | 'wall': {'total', 'free', 'placed', 'placed_br', 'placed_movable', 'mine',
    'vocab', 'animated', 'menu_here', 'menu_room', 'pinned'}} (counts; a slot counts once,
    by its status) + 'kept_screens' (the screens of the menus that keep slots)."""
    usage = doc.tile_usage(tid)
    q = quarter_uses(doc, tid)
    pinned = pinned_slots(doc, tid)
    here = doc.service_slots_on(tid, room, key) if room is not None and key is not None else set()
    out = {s: {'total': 0, 'free': 0, 'placed': 0, 'placed_br': 0, 'placed_movable': 0,
               'mine': 0, 'vocab': 0, 'animated': 0, 'menu_here': 0, 'menu_room': 0,
               'pinned': 0} for s in SIDES}
    for i, u in enumerate(usage):
        b = out[_side(i, thr)]
        b['total'] += 1
        st = u['status']
        if st == 'free':
            if i in here:
                b['menu_here'] += 1
            else:
                b['free'] += 1
        elif st in ('animated', 'statue'):
            b['animated'] += 1
        elif st == 'service':
            b['menu_room'] += 1
        elif st == 'vocab':
            b['vocab'] += 1
        elif st in ('placed', 'mine'):
            b['placed' if st == 'placed' else 'mine'] += 1
            if 'br' in q.get(i, ()):
                b['placed_br'] += 1
            elif i not in pinned:
                b['placed_movable'] += 1
            if i in pinned:
                b['pinned'] += 1
    kept = sorted({k for sl, wh in doc.service_kept_off(tid).items() for _r, k in wh})
    out['kept_screens'] = kept
    return out


def explain(doc, tid, thr, side, room=None, key=None, what='a tile'):
    """The words when no free slot is left on `side` ('wall' / 'walkable')."""
    b = budget(doc, tid, thr, room, key)
    s = b[side]
    other = 'wall' if side == 'walkable' else 'walkable'
    lines = [f"no free {side} slot left for {what} on tileset {tid!r} (one tileset = 256 slots "
             f"shared by every screen of the room; the walkability split at "
             f"${thr:02X} gives {s['total']} {side} slots)."]
    held = [f"{s['placed']} placed ({s['placed_br']} of them decide walking)",
            f"{s['mine']} in My metatiles", f"{s['vocab']} unreleased vocabulary",
            f"{s['animated']} animated"]
    if s['menu_here']:
        held.append(f"{s['menu_here']} kept free for the menu that opens on this screen")
    if s['menu_room']:
        held.append(f"{s['menu_room']} kept for a menu the room's entry script opens")
    lines.append(f"The {side} side holds: " + ', '.join(held) + '.')
    fixes = []
    plan = repack_plan(doc, tid, thr)
    n = sum(1 for a, _d in plan if _side(a, thr) == side)
    if n:
        fixes.append(f"Tileset tab → Repack: moves {n} tile(s) that never decide walking to the "
                     f"{other} side")
    if s['vocab']:
        fixes.append(f"Tileset tab → Release unused vocabulary ({s['vocab']} {side} slots hold "
                     'tiles of the room this one was copied from that no screen uses)')
    fixes.append('Park unplaced metatiles, or remove a stamp / some tiles')
    lines.append('Fix: ' + '; '.join(fixes) + '.')
    return ' '.join(lines)


def repack_plan(doc, tid, thr):
    """[(slot, new slot)] — tiles that are never a bottom-right quarter, moved from the side
    with fewer free slots to free slots of the other side (page 1 first), until the two
    sides' free counts are level. Empty when nothing would help."""
    if ':' in str(tid):
        return []
    usage = doc.tile_usage(tid)
    q = quarter_uses(doc, tid)
    pinned = pinned_slots(doc, tid)
    kept = doc.service_slots_anywhere(tid)
    free = {s: [i for i, u in enumerate(usage) if u['status'] == 'free' and _side(i, thr) == s
                and i not in kept] for s in SIDES}
    nfree = {s: sum(1 for i, u in enumerate(usage) if u['status'] == 'free'
                    and _side(i, thr) == s) for s in SIDES}
    scarce = min(SIDES, key=lambda s: nfree[s])
    roomy = 'wall' if scarce == 'walkable' else 'walkable'
    movable = [i for i, u in enumerate(usage)
               if u['status'] in ('placed', 'mine') and _side(i, thr) == scarce
               and not u['vocab'] and 'br' not in q.get(i, ()) and i not in pinned]
    # page 2 first out (page 1 is where the game's own windows and statues want room),
    # into page 1 first
    movable.sort(key=lambda i: (i < 0x80, i))
    dst = sorted(free[roomy], key=lambda i: (i >= 0x80, i))
    plan = []
    for a in movable:
        if not dst or nfree[roomy] - 1 < nfree[scarce] + 1:
            break
        d = dst.pop(0)
        plan.append((a, d))
        nfree[roomy] -= 1
        nfree[scarce] += 1
    return plan


def repack(doc, tid, thr):
    """Apply repack_plan: each tile's graphic to its new slot, every layout and My metatile
    of the sheet remapped (nothing changes on screen). -> [(old, new)]."""
    plan = repack_plan(doc, tid, thr)
    if not plan:
        return []
    sheet = doc.read_sheet(tid)
    for a, d in plan:
        sheet[d * 16:d * 16 + 16] = bytes(sheet[a * 16:a * 16 + 16])
        sheet[a * 16:a * 16 + 16] = bytes(16)
    doc.write_sheet(tid, bytes(sheet))
    for a, d in plan:
        doc._remap_tile(tid, a, d)
    doc.touch()
    return plan
