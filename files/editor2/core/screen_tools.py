"""screen_tools.py — screen COPY / PASTE and SHIFT OBJECTS (S175, ROADMAP P3.3n).

Headless Document mixin (no Qt). User S175: "On multi screen rooms I need the ability to
copy-paste a whole room into a different screen. That way I can keep backups of the
rooms I have" → conferred: "Copying should ONLY work on the same screen of multi-screen
rooms for now. It's a way to bank a room somewhere else. Should copy sprites + tiles but
nothing else. If you paste you should keep underlying cutscenes, triggers, entries,
doors, scripts, etc. It's just a visual thing" ("sprites" = the STAMPS; "Also keeps
walkability etc.") and "I assume I am able to shift all the scripts left/right and
up/down easily in case tiles adjust?" → Shift objects.

COPY takes the VISUAL layer of one screen in the state shown — its tile grid (walkability
is the tiles' own: the bottom-right subtile, ROOM_DATA_FORMAT "Walkability"), its colour
(attr) grid, the palette it shows, and the stamps placed on the screen — as a snapshot
(later edits of the source do not change what was copied). PASTE writes it over another
screen of the SAME room in the state shown: a new layout item of its own (tiles + attr),
the palette, the stamps of that screen replaced (stamps are per screen, every state); the
target keeps everything else (NPCs, spots, triggers, jumps, doors, exits, cutscenes,
scripts, states, counters). The target's previous layout items go when nothing else uses
them (they would still take ROM space).

SHIFT OBJECTS moves everything placed on a screen one cell (dx, dy) — and every ARRIVAL
into the screen from anywhere, so a door still lands where it did relative to the art:
  on the screen (every state): NPCs (typed + raw), examine spots, step-on triggers,
    statues, monuments, archives, jumps, exit rows / door objects — EXCEPT the edge exits
    (x = 0 / 9 or y = 0: they fire on a push into the screen's edge, ROOM_DATA_FORMAT
    "Exit Checker Block"; they belong to the edge, not to the art);
  the screen's stamps; its cutscenes (trigger cell, player start, walk / appear / fly
    targets, tile pieces); the room's gate arrival / arena return on that screen;
  arrivals: exit rows into it from any room (spawn_x / spawn_y; entrance_redirects,
    vanilla_exit_extensions), every {dest | room, screen, x, y} anywhere (talk / cutscene
    moves, helpers + their `land`, the Milly arrival, the new game's start, the hub, a
    world's start, the arena's "then", credits …), raw script ops map_transition /
    warp_fade into it (absolute pixels), jumps from the screen above (their landing row;
    their column is the jump's own, so a sideways shift leaves it — said in the result).
Anything that would leave the screen (or turn an exit into an edge exit) refuses the
whole shift and is named. Raw script walks to absolute pixels (`$10` / `$11`) are not
moved — reported.
"""

import copy

from . import formats as F
from . import jumps as JU

CELLS_W, CELLS_H = 10, 8
GRID_COLS = 4


def _states(scr):
    sts = scr.get('states')
    if isinstance(sts, list) and sts:
        return sts
    return [scr]


def _v(x):
    return F.val(x)


def is_edge_exit(e):
    """An exit matched by Entry 9 (a push into the screen's edge): x = 0 / 9 or y = 0."""
    try:
        x, y = _v(e.get('x')), _v(e.get('y'))
    except Exception:                                           # noqa: BLE001
        return False
    return x in (0, CELLS_W - 1) or y == 0


class ShiftBlocked(ValueError):
    pass


class ScreenToolsMixin:
    # ------------------------------------------------------------------ copy / paste
    def screen_visual(self, room, key, state_idx, renderer):
        """A snapshot of (screen, state)'s visual layer: tiles, attr, palette, stamps."""
        st = renderer.screen_state(room, key, state_idx)
        grid, _lid = renderer.layout_grid(st['layout'])
        attr, _note = renderer.attr_grid(room, key, state_idx)
        stamps = [copy.deepcopy(pl) for pl in room.get('stamps') or []
                  if int(pl.get('screen', -1)) == int(key)]
        return {'room': room['id'], 'screen': int(key), 'state': int(state_idx),
                'tiles': [list(r) for r in grid],
                'attr': [list(r) for r in attr] if attr else None,
                'palette': self.effective_palette(room, key, state_idx),
                'stamps': stamps}

    def _layout_id_used(self, lid):
        """Is layout item `lid` referenced anywhere outside custom.layouts?"""
        for r in self.rooms:
            if lid in self._room_layout_refs(r):
                return True
        hit = [False]

        def walk(o, under_layouts=False):
            if hit[0]:
                return
            if isinstance(o, dict):
                for k, v in o.items():
                    if k == 'layouts' and o is self.custom:
                        continue
                    walk(v)
            elif isinstance(o, list):
                for v in o:
                    walk(v)
            elif o == lid:
                hit[0] = True
        walk(self.data)
        return hit[0]

    def paste_screen_visual(self, room, key, state_idx, clip, repo=None):
        """Write `clip` (screen_visual) over (key, state) of the same room. -> notes."""
        if clip is None:
            raise ValueError('nothing copied — Copy screen first')
        if clip['room'] != room['id']:
            raise ValueError('a screen pastes only into another screen of the room it was '
                             'copied from')
        if str(key) not in (room.get('screens') or {}):
            raise ValueError(f'screen {key} does not exist — add it first')
        notes = []
        scr = self.screen(room, key)
        sts = scr.get('states') or []
        target = sts[state_idx] if sts else scr
        old_refs = {(target.get('layout') or {}).get('id'), (target.get('attr') or {}).get('id')}
        if not sts:
            old_refs |= set()
        lid = self.unique_layout_id(f"{room['id']}_s{key}")
        self.add_layout(lid, tiles=clip['tiles'], attr=clip.get('attr'),
                        comment=f"{room['id']} screen {key}: pasted from screen "
                                f"{clip['screen']} (state {clip['state']})")
        target['layout'] = {'id': lid}
        if clip.get('attr') is not None:
            target['attr'] = {'id': lid}
        # the palette the copy showed
        if self.effective_palette(room, key, state_idx) != clip.get('palette'):
            self.set_state_palette(room, key, state_idx, clip.get('palette'))
        # stamps: per screen (every state)
        keep = [pl for pl in room.get('stamps') or [] if int(pl.get('screen', -1)) != int(key)]
        n_old = len(room.get('stamps') or []) - len(keep)
        new = []
        for pl in clip.get('stamps') or []:
            q = copy.deepcopy(pl)
            q['screen'] = int(key)
            new.append(q)
        if keep or new:
            room['stamps'] = keep + new
        else:
            room.pop('stamps', None)
        if repo is not None and new:
            from . import stamps as ST
            for j in range(len(keep), len(keep) + len(new)):
                w = ST.claim(self, repo, room['id'], j)
                if w:
                    notes.append(w)
        if n_old or new:
            notes.append(f'stamps: {n_old} removed, {len(new)} pasted')
        # drop the target's previous layout items when nothing uses them any more
        for old in old_refs:
            if old and old != lid and self.has_layout(old) and not self._layout_id_used(old):
                self.remove_layout(old)
        base = f"{room['id']}_s{key}"
        if lid != base and not self.has_layout(base):          # the old one went: its name back
            self.layout(lid)['id'] = base
            for fld in ('layout', 'attr'):
                if (target.get(fld) or {}).get('id') == lid:
                    target[fld] = {'id': base}
        self.touch()
        return notes

    # ------------------------------------------------------------------ shift objects
    def _mid_of(self, room):
        return _v(room['mapID']) if room.get('mapID') is not None else None

    def _names_room(self, d, room):
        """Does dict d name `room` as its destination ('dest' room:$xx / 'room' id or map id)?"""
        mid = self._mid_of(room)
        dest = d.get('dest')
        if isinstance(dest, str) and dest.startswith('room:'):
            try:
                return _v(dest[5:]) == mid
            except Exception:                                   # noqa: BLE001
                return False
        r = d.get('room')
        if isinstance(r, str) and r:
            if r == room['id']:
                return True
            try:
                return r.lower().startswith(('0x', '$')) and _v(r) == mid
            except Exception:                                   # noqa: BLE001
                return False
        return False

    def shift_screen_objects(self, room, key, dx, dy):
        """Move every object on screen `key` and every arrival into it by (dx, dy) cells.
        Raises ShiftBlocked (nothing changed) naming what would leave the screen.
        -> {'moved': [words], 'notes': [words], 'stamps': [indices moved — their colour rows
        are re-claimed by the caller over the tiles now under them (stamps.claim)]}."""
        dx, dy, key = int(dx), int(dy), int(key)
        if (dx, dy) == (0, 0):
            return {'moved': [], 'notes': [], 'stamps': []}
        if str(key) not in (room.get('screens') or {}):
            raise ValueError(f'no screen {key}')
        moves = []          # (setter, new value) applied only when nothing blocks
        stamp_idx = []
        blocked = []
        counts = {}
        notes = []

        def cnt(what):
            counts[what] = counts.get(what, 0) + 1

        def ok(x, y, lo_x=0, hi_x=CELLS_W - 1, lo_y=0, hi_y=CELLS_H - 1):
            return lo_x <= x <= hi_x and lo_y <= y <= hi_y

        def plan_xy(d, what, kx='x', ky='y', cat=None, **lim):
            x, y = _v(d[kx]) + dx, _v(d[ky]) + dy
            # something already outside the screen (a cast NPC parked below it) just moves
            if not ok(x, y, **lim) and ok(x - dx, y - dy, **lim):
                blocked.append(f"{what} at ({_v(d[kx])},{_v(d[ky])})")
                return
            moves.append((d, kx, x))
            moves.append((d, ky, y))
            cnt(cat or what.split(' (')[0])

        def plan_pair(lst, what, lo=-3, hix=12, hiy=10):
            x, y = int(lst[0]) + dx, int(lst[1]) + dy
            if not ok(x, y, lo, hix, lo, hiy):
                blocked.append(f"{what} to ({lst[0]},{lst[1]})")
                return
            moves.append((lst, 0, x))
            moves.append((lst, 1, y))
            cnt('cutscene place')

        scr = self.screen(room, key)
        # --- 1. the screen's own objects (every state)
        for s, st in enumerate(_states(scr)):
            tag = f' (state {s})' if len(_states(scr)) > 1 else ''
            for e in st.get('npcs') or []:
                if not isinstance(e, dict):
                    continue
                k = e.get('kind')
                if k == 'raw':
                    b = e['bytes']
                    x, y = _v(b[2]) + dx, _v(b[3]) + dy
                    kind = 'NPC' if _v(b[0]) < 0x80 else 'spot'
                    if not ok(x, y) and ok(x - dx, y - dy):
                        blocked.append(f"{kind} at ({_v(b[2])},{_v(b[3])}){tag}")
                        continue
                    moves.append((b, 2, f'0x{x:02X}' if isinstance(b[2], str) else x))
                    moves.append((b, 3, f'0x{y:02X}' if isinstance(b[3], str) else y))
                    cnt(kind)
                    continue
                if 'x' not in e or 'y' not in e:
                    continue
                name = {'npc': 'NPC', 'examine': 'examine spot', 'step': 'step-on trigger',
                        'spawn': 'examine spot', 'statue': 'statue', 'monument': 'monument',
                        'archive': 'archive', 'jump': 'jump'}.get(k, k or 'entry')
                if k == 'statue':
                    plan_xy(e, f'statue{tag}', cat='statue', lo_y=1)        # its monster sits on the cell above
                else:
                    plan_xy(e, f'{name}{tag}', cat=name)
                tf = e.get('talks_for')             # S177: a podium's NPC moves with it
                if isinstance(tf, dict) and 'x' in tf and 'y' in tf:
                    moves.append((tf, 'x', _v(tf['x']) + dx))
                    moves.append((tf, 'y', _v(tf['y']) + dy))
            for e in st.get('exits') or []:
                if not isinstance(e, dict) or 'x' not in e:
                    continue
                if is_edge_exit(e):
                    cnt('edge exit (kept on the edge)')
                    continue
                what = (f"door '{e.get('name') or e.get('door')}'" if e.get('door')
                        else 'exit') + tag
                plan_xy(e, what, cat='door / exit', lo_x=1, hi_x=CELLS_W - 2, lo_y=1)
        # --- 2. stamps on the screen
        from . import stamps as ST
        for pl in room.get('stamps') or []:
            if int(pl.get('screen', -1)) != key:
                continue
            st_ = ST.stamp_of(self.custom, pl.get('stamp'))
            new = dict(pl, x=int(pl['x']) + dx, y=int(pl['y']) + dy)
            if st_ is not None:
                on = {(c, r) for c in range(CELLS_W) for r in range(CELLS_H)}
                if len(ST.footprint(new, st_) & on) < len(ST.footprint(pl, st_) & on):
                    blocked.append(f"stamp '{st_.get('name')}' at ({pl['x']},{pl['y']})")
                    continue
            moves.append((pl, 'x', new['x']))
            moves.append((pl, 'y', new['y']))
            stamp_idx.append(room['stamps'].index(pl))
            cnt('stamp')
        # --- 3. cutscenes of the screen
        from . import cutscene_build as CB
        for cs in room.get('cutscenes') or []:
            if int(cs.get('screen', 0)) != key:
                continue
            nm = cs.get('name') or cs.get('id')
            trg = cs.get('trigger') or {}
            if trg.get('on') in ('examine', 'stepon') and 'x' in trg:
                plan_xy(trg, f"cutscene '{nm}' spot", cat='cutscene place')
            ps = cs.get('player_start')
            if isinstance(ps, dict) and 'x' in ps:
                plan_xy(ps, f"cutscene '{nm}' player start", cat='cutscene place')
            for _p, step in CB.walk_steps(cs.get('steps') or []):
                k = CB.step_kind(step)
                v = step.get(k) if k else None
                if not isinstance(v, dict):
                    continue
                for fld in ('to', 'at'):
                    if isinstance(v.get(fld), list) and len(v[fld]) == 2:
                        plan_pair(v[fld], f"cutscene '{nm}' {k}")
                if k == 'tiles' and 'x' in v:
                    plan_xy(v, f"cutscene '{nm}' tiles", cat='cutscene place', lo_x=-9, lo_y=-7)
        # --- 4. the room's own arrivals on this screen
        ga = room.get('gate_arrival')
        if isinstance(ga, dict) and int(ga.get('screen', 0)) == key and 'x' in ga:
            plan_xy(ga, 'gate arrival', cat='arrival')
        arena = self.custom.get('arena') if isinstance(self.custom.get('arena'), dict) else None
        if arena and arena.get('lobby') == room['id']:
            ret = arena.get('return')
            if isinstance(ret, dict) and int(ret.get('screen', -1)) == key:
                plan_xy(ret, 'arena return', cat='arrival')
        # --- 5. arrivals from anywhere
        mid = self._mid_of(room)

        def walk(o, ctx):
            if isinstance(o, dict):
                if 'screen_byte' in o and 'spawn_x' in o and self._names_room(o, room):
                    try:
                        sk = _v(o['screen_byte']) & 0x0F
                    except Exception:                           # noqa: BLE001
                        sk = None
                    if sk == key:
                        plan_xy(o, 'arrival (a door / exit into this screen)',
                                kx='spawn_x', ky='spawn_y', cat='arrival')
                elif 'screen' in o and 'x' in o and 'y' in o and 'screen_byte' not in o \
                        and self._names_room(o, room):
                    try:
                        sk = int(_v(o['screen']))
                    except Exception:                           # noqa: BLE001
                        sk = None
                    if sk == key:
                        plan_xy(o, f'arrival ({ctx})', cat='arrival')
                        land = o.get('land')
                        if isinstance(land, dict) and 'x' in land:
                            plan_xy(land, 'helper landing', cat='arrival')
                for kk, vv in o.items():
                    if kk in ('rooms', 'layouts', 'tilesets', 'palettes', '_editor'):
                        if kk == 'rooms':
                            for rr in vv or []:
                                if isinstance(rr, dict):
                                    for sk2, scr2 in (rr.get('screens') or {}).items():
                                        walk(scr2, 'exit')
                                    for cs in rr.get('cutscenes') or []:
                                        walk(cs, 'cutscene move')
                        continue
                    walk(vv, kk)
            elif isinstance(o, list):
                if o and o[0] == 'op' and len(o) >= 5 and str(o[1]).lower() in (
                        'map_transition', '0x0f', 'warp_fade', '0x3b'):
                    try:
                        m, px, py = _v(o[2]), _v(o[3]), _v(o[4])
                    except Exception:                           # noqa: BLE001
                        return
                    if str(o[1]).lower() in ('warp_fade', '0x3b'):
                        m &= 0xFF
                    if m != mid:
                        return
                    if (px // 160) + (py // 128) * GRID_COLS != key:
                        return
                    cx, cy = (px % 160) // 16 + dx, (py % 128) // 16 + dy
                    if not ok(cx, cy):
                        blocked.append(f'script warp to cell ({cx - dx},{cy - dy})')
                        return
                    moves.append((o, 3, f'0x{px + 16 * dx:04X}'))
                    moves.append((o, 4, f'0x{py + 16 * dy:04X}'))
                    cnt('script warp')
                    return
                if o and o[0] == 'op' and str(o[1]).lower() in ('walk_to_x', 'walk_to_y',
                                                                 '0x10', '0x11'):
                    counts.setdefault('_raw_walks', 0)
                    counts['_raw_walks'] += 1
                for vv in o:
                    walk(vv, ctx)
        walk(self.custom, 'custom')
        walk(self.data.get('progression') or {}, 'progression')
        # jumps from the screen above land here
        above = key - GRID_COLS
        if above >= 0 and str(above) in room['screens']:
            for st in _states(room['screens'][str(above)]):
                for e in st.get('npcs') or []:
                    if JU.is_jump(e):
                        ly = int(e['land_y']) + dy
                        if not 0 <= ly < CELLS_H:
                            blocked.append(f"landing of the jump from screen {above} "
                                           f"({e['x']},{e['y']})")
                            continue
                        moves.append((e, 'land_y', ly))
                        cnt('jump landing')
                        if dx:
                            n = f"the jump from screen {above} ({e['x']},{e['y']}) still lands " \
                                f"in column {e['x']} (a jump falls straight down)"
                            if n not in notes:
                                notes.append(n)
        if blocked:
            uniq = []
            for b in blocked:
                if b not in uniq:
                    uniq.append(b)
            raise ShiftBlocked('nothing moved — these would leave the screen (or turn into an '
                               'edge exit): ' + '; '.join(uniq[:8])
                               + (f' … and {len(uniq) - 8} more' if len(uniq) > 8 else ''))
        seen = set()
        for obj, k, v in moves:
            if (id(obj), k) in seen:
                continue
            seen.add((id(obj), k))
            obj[k] = v
        self.touch()
        moved = [f"{n} × {w}" for w, n in sorted(counts.items()) if not w.startswith('_')]
        if counts.get('_raw_walks'):
            notes.append(f"{counts['_raw_walks']} raw script walk(s) to absolute pixels were not "
                         'moved (op $10 / $11 — edit those scripts by hand)')
        return {'moved': moved, 'notes': notes, 'stamps': sorted(set(stamp_idx))}
