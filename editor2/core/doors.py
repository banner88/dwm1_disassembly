"""doors.py — doors, one-way teleports and invisible interact spots (S98, P3.7).

A Document mixin (no Qt). Everything here writes ORDINARY schema data the
compiler already understands (PROJECT_COMPILER §2.2 exits, §2.12 entrance
redirects, §2.14 interact spots):

  * DOOR OBJECT (S98 r2, the user's design: "click a cell, Add door, the
    door appears on that cell; double-click it to set its params; namable
    and connected to another door object"). A custom door = the exit rows
    on its cell (one per state that carries it) with `"door": id`,
    `"name"` and — once connected — `"link": <other door id>` plus the
    usual dest / screen_byte / spawn bytes leading to the partner's
    arrival. An UNCONNECTED door has no dest: the compiler skips it (warns).
    A VANILLA door is an object too (`vdoor_MM_k_x_y`); connecting it
    writes `entrance_redirects` rows (S94b) tagged `door`/`link`. Links are
    always two-way; re-linking a door frees its old partner.
  * TELEPORT (one-way, the rare object): an exit row without a door id —
    it arrives exactly on the cell the author picked.

Arrival (PyBoy-measured S98; ROOM_DATA_FORMAT "Doors"):
  * the player never re-triggers the exit he arrives on (arrival is not a
    step: a staircase that lands ON its partner's cell works both ways);
  * S98 r2 (user: "arriving … puts you half a tile down, instead of ON TOP
    OF the door"): a CUSTOM door arrives ON the partner door cell (screen
    byte without bit 7) — edge or interior. (r1 used the vanilla "step out
    of the doorway": bit 7 = +8 px, half a cell below; r1 rows are migrated
    on open.)
  * a VANILLA end copies the vanilla partner's own bytes (the exit in the
    door's original destination that leads back to it) — screen bytes are
    never guessed (KEY_LESSONS v14-v18).
Edge doors on an edge that borders another screen of the room never fire
(pushing into that edge scrolls — PyBoy S98); validators warn, the dialog
refuses.

Interact spots (bank $0B RoomEntry4/5, PyBoy-measured S98): `examine`
({kind, x, y, facing any|down|left|up|right, script}) answers an A press on
or facing the cell; `step` ({kind, x, y, script}) runs when the player walks
onto the cell. Both live in the state's `npcs` list (the interact block) but
take no NPC slot.
"""

import copy

EDGE_XS, EDGE_YS = (0, 9), (0, 7)


def is_edge(x, y):
    return x in EDGE_XS or y in EDGE_YS


def _v(x):
    if isinstance(x, int):
        return x
    s = str(x).strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


class DoorsMixin:
    # ------------------------------------------------------------ helpers
    def _exit_target(self, room, key, state_idx):
        scr = self.screen(room, key)
        return scr['states'][state_idx] if scr.get('states') else scr

    def exits_of(self, room, key, state_idx):
        return self._exit_target(room, key, state_idx).setdefault('exits', [])

    def _iter_exit_rows(self, door_id=None):
        """(room, key, state_idx, row_index, row) for every custom exit row
        (optionally only those of one door)."""
        for r in self.rooms:
            if r.get('placeholder'):
                continue
            for k in self.screen_keys(r):
                for n, st in enumerate(self.states(r, k)):
                    for i, e in enumerate(st.get('exits') or []):
                        if door_id is None or e.get('door') == door_id:
                            yield r, k, n, i, e

    def door_ids(self):
        ids = {e.get('door') for *_x, e in self._iter_exit_rows() if e.get('door')}
        ids |= {rd.get('door') for rd in self.redirects() if rd.get('door')}
        return sorted(i for i in ids if i)

    def _new_door_id(self):
        taken = set(self.door_ids())
        n = 1
        while f'door_{n}' in taken:
            n += 1
        return f'door_{n}'

    # ------------------------------------------------------------ walkability
    def _walk_fn(self, end):
        """cell -> walkable? for an end, via the live renderer (Session sets
        self.vanilla); None when no renderer is attached (headless)."""
        r = getattr(self, 'vanilla', None)
        if r is None:
            return None
        try:
            if end['kind'] == 'room':
                room = self.room(end['room'])
                st = end.get('states') or [0]
                n = st[0]
                s = r.screen_state(room, end['screen'], n)
                grid, _lid = r.layout_grid(s['layout'])
                thr = r.room_gfx(room).threshold
            else:
                grid = r.vanilla_screen_grid(end['mapID'], end['screen'], 0)
                thr = r.vanilla_gfx(end['mapID']).threshold
        except Exception:
            return None
        return lambda cx, cy: (0 <= cx <= 9 and 0 <= cy <= 7
                               and grid[cy * 2 + 1][cx * 2 + 1] >= thr)

    def default_arrival(self, end):
        """(screen_byte, spawn_x, spawn_y) the player gets when arriving
        through the door INTO `end` (see the module doc)."""
        k, x, y = int(end['screen']), int(end['x']), int(end['y'])
        # S98 r3 (user: "You arrive on tile fully always"): a vanilla door
        # too — vanilla's own return bytes can carry bit 7 (+8 px: Library ->
        # GreatTree $88 lands at pixel y=320, half a cell below the door —
        # measured on the original ROM), which the user does not want.
        # S98 r2 (user: "arriving on the other side puts you half a tile down,
        # instead of ON TOP OF the door"): arrive ON the door cell — safe,
        # arrival never re-fires the exit (PyBoy S98); the player steps off
        # and back on to go through again
        return k, x, y

    def vanilla_partner_arrival(self, mid, key, x, y):
        """The bytes vanilla itself uses to put the player back at a vanilla
        door: find the door's original destination (its exit row in any
        valid step of that screen), then an exit IN that destination whose
        target is this room/screen and whose spawn lands on or next to the
        door. None when the door has no vanilla partner (a new door)."""
        r = getattr(self, 'vanilla', None)
        if r is None:
            return None
        try:
            steps = r.vanilla_steps(mid, key)
        except Exception:
            return None
        dests = []
        for n in range(len(steps)):
            try:
                _npcs, exits = r.vanilla_markers(mid, key, n)
            except Exception:
                continue
            for e in exits:
                if _v(e['x']) == x and _v(e['y']) == y:
                    ds = str(e['dest'])
                    d = int(ds.split('$')[-1], 16) if '$' in ds else _v(ds)
                    if d not in dests:
                        dests.append(d)
        best = None
        for d in dests:
            try:
                screens = next(sc for m, _n, sc in r.vanilla_rooms() if m == d)
            except StopIteration:
                continue
            for k2 in screens:
                for n in range(len(r.vanilla_steps(d, k2))):
                    try:
                        _npcs, exits = r.vanilla_markers(d, k2, n)
                    except Exception:
                        continue
                    for e in exits:
                        if str(e['dest']).upper() != f'VANILLA:${mid:02X}':
                            continue
                        sb = _v(e['screen_byte'])
                        if (sb & 0x0F) != key:
                            continue
                        sx, sy = _v(e['spawn_x']), _v(e['spawn_y'])
                        dist = abs(sx - x) + abs(sy - y)
                        if dist <= 1 and (best is None or dist < best[0]):
                            best = (dist, (sb, sx, sy))
        return best[1] if best else None

    def edge_conflict(self, room, key, x, y):
        """S98 (PyBoy-measured): an exit on a screen edge that borders
        another screen of the room (inside the record's scroll area).
        Returns (side, neighbour screen) or None. Pushing into x=0/9 or y=0
        there SCROLLS (the exit never fires); a y=7 exit fires on walk-on,
        so that column can never be walked into the screen below."""
        keys = set(self.screen_keys(room))
        rec = room.get('record') or {}
        try:
            cols, rows = _v(rec.get('width_px', 160)) // 160, _v(rec.get('height_px', 128)) // 128
        except Exception:
            cols = rows = 1
        c, rw = int(key) % 4, int(key) // 4
        for side, cond, dc, dr in (('left', x == 0, -1, 0), ('right', x == 9, 1, 0),
                                   ('top', y == 0, 0, -1), ('bottom', y == 7, 0, 1)):
            nc, nr = c + dc, rw + dr
            if cond and 0 <= nc < cols and 0 <= nr < rows and (nr * 4 + nc) in keys:
                return side, nr * 4 + nc
        return None

    def vanilla_door_twins(self, mid, key, x, y):
        """x of the other cell(s) of a vanilla double door: horizontally
        adjacent exit cells of the same screen with the same destination."""
        r = getattr(self, 'vanilla', None)
        if r is None:
            return []
        cells = {}
        try:
            for n in range(len(r.vanilla_steps(mid, key))):
                _np, exits = r.vanilla_markers(mid, key, n)
                for e in exits:
                    cells.setdefault((_v(e['x']), _v(e['y'])), str(e['dest']))
        except Exception:
            return []
        me = cells.get((x, y))
        if me is None:
            return []
        return [x + d for d in (-1, 1) if cells.get((x + d, y)) == me]

    # ---------------------------------------------------------------- ids
    @staticmethod
    def vanilla_door_id(mid, key, x, y):
        return f'vdoor_{int(mid):02X}_{int(key)}_{int(x)}_{int(y)}'

    @staticmethod
    def parse_vanilla_door_id(did):
        if not isinstance(did, str) or not did.startswith('vdoor_'):
            return None
        try:
            m, k, x, y = did[6:].split('_')
            return int(m, 16), int(k), int(x), int(y)
        except ValueError:
            return None

    def _door_rows(self, did):
        if not did:
            return []
        return [(r, k, n, e) for r, k, n, _i, e in self._iter_exit_rows(did)]

    def _vanilla_door_rows(self, did):
        return [rd for rd in (self.custom.get('entrance_redirects') or [])
                if rd.get('door') == did or rd.get('twin_of') == did]

    def door_ids(self):
        """Every door OBJECT: custom doors (exit rows with a `door` id) and
        vanilla doors that are connected (their redirect rows)."""
        ids = {e.get('door') for *_x, e in self._iter_exit_rows() if e.get('door')}
        ids |= {rd.get('door') for rd in self.redirects() if rd.get('door')}
        return sorted(i for i in ids if i)

    def _new_door_id(self):
        taken = set(self.door_ids())
        n = 1
        while f'door_{n}' in taken:
            n += 1
        return f'door_{n}'

    # ---------------------------------------------------------------- views
    def vanilla_door_name(self, mid, key, x, y):
        r = getattr(self, 'vanilla', None)
        name = ''
        if r is not None:
            try:
                name = r.vanilla_name(mid)
            except Exception:
                name = ''
        return f"{name or f'${mid:02X}'} — screen {key} door ({x},{y})"

    def door_end(self, did):
        """The door OBJECT `did`:
        custom  {'id', 'kind': 'room', 'room', 'screen', 'x', 'y', 'states',
                 'row', 'name', 'link'}
        vanilla {'id', 'kind': 'vanilla', 'mapID', 'screen', 'x', 'y', 'row'
                 (its redirect row or None), 'name', 'link'}
        None for an unknown custom id."""
        v = self.parse_vanilla_door_id(did)
        if v is not None:
            mid, k, x, y = v
            row = next((rd for rd in self.redirects() if rd.get('door') == did), None)
            return {'id': did, 'kind': 'vanilla', 'mapID': mid, 'screen': k, 'x': x, 'y': y,
                    'row': row, 'name': self.vanilla_door_name(mid, k, x, y),
                    'link': (row or {}).get('link')}
        rows = self._door_rows(did)
        if not rows:
            return None
        r, k, _n, e = rows[0]
        return {'id': did, 'kind': 'room', 'room': r['id'], 'screen': k,
                'x': _v(e['x']), 'y': _v(e['y']),
                'states': sorted({n for rr, kk, n, _e in rows if rr is r and kk == k}),
                'row': e, 'name': e.get('name') or did, 'link': e.get('link')}

    def door_partner(self, did):
        end = self.door_end(did)
        if not end or not end.get('link'):
            return None
        return self.door_end(end['link'])

    def door_name(self, did):
        end = self.door_end(did)
        return end['name'] if end else did

    def door(self, did):
        """Back-compat view {'id', 'ends': [this, partner?]}."""
        me = self.door_end(did)
        if me is None:
            return {'id': did, 'ends': []}
        p = self.door_partner(did)
        return {'id': did, 'ends': [me] + ([p] if p else [])}

    def custom_doors(self):
        """Every custom door object (the link picker's list)."""
        out = []
        for did in self.door_ids():
            if self.parse_vanilla_door_id(did) is None:
                end = self.door_end(did)
                if end:
                    out.append(end)
        return out

    def doors_touching(self, room_id):
        """Door objects in this custom room, and vanilla doors connected
        into it."""
        out = []
        for did in self.door_ids():
            end = self.door_end(did)
            if end is None:
                continue
            if end['kind'] == 'room' and end['room'] == room_id:
                out.append(end)
            elif end['kind'] == 'vanilla':
                p = self.door_partner(did)
                if p and p['kind'] == 'room' and p['room'] == room_id:
                    out.append(end)
        return out

    def door_end_at(self, room_id, key, x, y):
        """Id of the custom door on this cell, or None."""
        for r, k, _n, _i, e in self._iter_exit_rows():
            if e.get('door') and r['id'] == room_id and k == int(key) and \
                    (_v(e['x']), _v(e['y'])) == (int(x), int(y)):
                return e['door']
        return None

    @staticmethod
    def _dest_of(end, doc):
        if end['kind'] == 'room':
            return f"room:${_v(doc.room(end['room'])['mapID']):02X}"
        return f"vanilla:${end['mapID']:02X}"

    # -------------------------------------------------------------- create
    def add_door(self, room_id, key, x, y, states=None, name=None):
        """S98 r2 (user design): a door OBJECT placed on a cell — not
        connected yet (its exit rows carry no destination, the compiler
        skips them and warns). Connect it with link_doors. Returns its id."""
        room = self.room(room_id)
        key, x, y = int(key), int(x), int(y)
        if str(key) not in (room.get('screens') or {}):
            raise ValueError(f'room {room_id} has no screen {key}')
        n_st = len(self.states(room, key))
        sts = sorted(int(s) for s in (states if states is not None else range(n_st)))
        if not sts:
            raise ValueError('a door must exist in at least one state')
        for n in sts:
            for e in self.exits_of(room, key, n):
                if (_v(e['x']), _v(e['y'])) == (x, y):
                    what = f"door '{e.get('name') or e['door']}'" if e.get('door') else 'an exit'
                    raise ValueError(f'cell ({x},{y}) already holds {what} (state {n})')
        did = self._new_door_id()
        label = name or f'Door {did.split("_")[-1]}'
        for n in sts:
            self.exits_of(room, key, n).append({'x': x, 'y': y, 'door': did, 'name': label})
        self.touch()
        return did

    def rename_door(self, did, name):
        name = str(name).strip()
        if not name:
            raise ValueError('a door needs a name')
        rows = self._door_rows(did)
        if not rows:
            raise ValueError('only your own doors have names (vanilla doors are named by '
                             'their room)')
        for *_x, e in rows:
            e['name'] = name
        self.touch()

    # -------------------------------------------------------------- links
    LINK_KEYS = ('dest', 'gate_flag', 'screen_byte', 'spawn_x', 'spawn_y', 'link')

    def _clear_link(self, end):
        if end is None:
            return
        if end['kind'] == 'room':
            for *_x, e in self._door_rows(end['id']):
                for k in self.LINK_KEYS:
                    e.pop(k, None)
        else:
            lst = self.custom.get('entrance_redirects') or []
            lst[:] = [rd for rd in lst
                      if rd.get('door') != end['id'] and rd.get('twin_of') != end['id']]
            if not lst:
                self.custom.pop('entrance_redirects', None)

    def _write_link(self, end, other):
        """Make `end` lead to `other` (the player arrives where the vanilla
        rules put him — default_arrival)."""
        sb, sx, sy = self.default_arrival(other)
        dest = self._dest_of(other, self)
        if end['kind'] == 'room':
            for *_x, e in self._door_rows(end['id']):
                e.update({'dest': dest, 'gate_flag': 0, 'screen_byte': f'0x{sb:02X}',
                          'spawn_x': sx, 'spawn_y': sy, 'link': other['id']})
            return
        if not dest.startswith('room:'):
            raise ValueError('a vanilla door can only be connected to one of your doors')
        lst = self.custom.setdefault('entrance_redirects', [])
        lst[:] = [rd for rd in lst
                  if rd.get('door') != end['id'] and rd.get('twin_of') != end['id']]
        row = {'mapID': f"0x{end['mapID']:02X}", 'screen': end['screen'],
               'x': end['x'], 'y': end['y'], 'dest': dest,
               'screen_byte': f'0x{sb:02X}', 'spawn_x': sx, 'spawn_y': sy,
               'door': end['id'], 'link': other['id'],
               'comment': f"vanilla door ${end['mapID']:02X} screen {end['screen']} "
                          f"({end['x']},{end['y']}) <-> {other.get('name', other['id'])}"}
        rows = [row]
        # a vanilla DOUBLE door (Castle, Arena Lobby: two side-by-side cells
        # to the same place) is re-pointed as a whole — the other cell is a
        # 'twin_of' row, else its other half would still lead to the old room
        for tx in self.vanilla_door_twins(end['mapID'], end['screen'], end['x'], end['y']):
            twin = {k: v for k, v in row.items() if k not in ('door', 'link')}
            twin.update(x=tx, twin_of=end['id'],
                        comment='second cell of the vanilla double door')
            rows.append(twin)
        for new in rows:
            for i, rd in enumerate(lst):
                if (_v(rd['mapID']), _v(rd['screen']), _v(rd['x']), _v(rd['y'])) == \
                        (end['mapID'], end['screen'], new['x'], new['y']):
                    lst[i] = new
                    break
            else:
                lst.append(new)

    def link_doors(self, a, b):
        """Connect door objects a and b (two-way). Their previous partners
        become unconnected. A vanilla door may be one side (it is re-pointed
        through entrance_redirects); never both."""
        if a == b:
            raise ValueError('a door cannot lead to itself')
        ea, eb = self.door_end(a), self.door_end(b)
        if ea is None or eb is None:
            raise ValueError(f'unknown door {a if ea is None else b}')
        if ea['kind'] == 'vanilla' and eb['kind'] == 'vanilla':
            raise ValueError('connect a vanilla door to one of YOUR doors '
                             '(vanilla-to-vanilla links stay as the game has them)')
        for end in (ea, eb):
            p = self.door_partner(end['id'])
            if p is not None and p['id'] not in (a, b):
                self._clear_link(p)
        self._write_link(ea, eb)          # arrivals depend on geometry only
        self._write_link(eb, ea)
        self.touch()

    def unlink_door(self, did):
        end = self.door_end(did)
        if end is None:
            return
        p = self.door_partner(did)
        self._clear_link(end)
        if p is not None and p.get('link') == did:
            self._clear_link(p)
        self.touch()

    def remove_door(self, did):
        """Delete a door object; its partner stays, unconnected. (A vanilla
        door just goes back to its vanilla destination.)"""
        self.unlink_door(did)
        for r, k, n, _e in self._door_rows(did):
            rows = self.exits_of(r, k, n)
            rows[:] = [e for e in rows if e.get('door') != did]
        self.touch()

    def refresh_door(self, did):
        """Re-aim both sides (after the author repainted around a door)."""
        p = self.door_partner(did)
        if p is not None:
            self._write_link(self.door_end(did), p)
            self._write_link(p, self.door_end(did))
            self.touch()

    # -------------------------------------------------------------- edit
    def move_door(self, did, x, y):
        """Move a custom door on its screen (every state it exists in); its
        partner re-aims at the new arrival."""
        end = self.door_end(did)
        if end is None or end['kind'] != 'room':
            raise ValueError('only your own doors move (a vanilla door is fixed)')
        room = self.room(end['room'])
        x, y = int(x), int(y)
        for n in end['states']:
            for e in self.exits_of(room, end['screen'], n):
                if (_v(e['x']), _v(e['y'])) == (x, y) and e.get('door') != did:
                    raise ValueError(f'cell ({x},{y}) already holds an exit or door (state {n})')
        for *_x, e in self._door_rows(did):
            e['x'], e['y'] = x, y
        p = self.door_partner(did)
        if p is not None:
            self._write_link(p, self.door_end(did))
        self.touch()

    def move_door_end(self, door_id, end_index, x, y):          # S98 r1 name
        return self.move_door(door_id, x, y)

    def set_door_states(self, did, states):
        """The states of the door's screen that carry it."""
        states = sorted(int(s) for s in states)
        if not states:
            raise ValueError('a door must exist in at least one state (delete it instead)')
        end = self.door_end(did)
        if end is None or end['kind'] != 'room':
            raise ValueError('vanilla doors have no states to choose')
        room = self.room(end['room'])
        tmpl = {k: v for k, v in end['row'].items()}
        for n in range(len(self.states(room, end['screen']))):
            rows = self.exits_of(room, end['screen'], n)
            has = any(e.get('door') == did for e in rows)
            if n in states and not has:
                if any((_v(e['x']), _v(e['y'])) == (end['x'], end['y']) for e in rows):
                    raise ValueError(f"state {n} already has an exit on ({end['x']},{end['y']})")
                rows.append(dict(tmpl))
            elif n not in states and has:
                rows[:] = [e for e in rows if e.get('door') != did]
        self.touch()

    # ------------------------------------------------------ migration
    def _migrate_door_arrivals(self, notes):
        """S98 r2: rows written with the r1 default "step out of the
        doorway" (screen_byte bit 7 on the partner's own cell) now arrive ON
        the partner door (vanilla partners keep their own bytes)."""
        n = 0
        for did in self.door_ids():
            me, p = self.door_end(did), self.door_partner(did)
            if me is None or p is None or not me.get('row'):
                continue
            rows = ([e for *_x, e in self._door_rows(did)] if me['kind'] == 'room'
                    else self._vanilla_door_rows(did))
            for e in rows:
                sb = _v(e.get('screen_byte', 0))
                if sb & 0x80 and (sb & 0x0F) == p['screen'] and \
                        (_v(e.get('spawn_x', -1)), _v(e.get('spawn_y', -1))) == (p['x'], p['y']):
                    e['screen_byte'] = f'0x{sb & 0x7F:02X}'
                    n += 1
        if n:
            notes.append(f'{n} door row(s): arrive ON the partner door now (was half a cell '
                         'below — S98 r2/r3)')

    def _migrate_doors(self, notes):
        """S98 r1 wrote a door as TWO ends sharing one id; S98 r2 has one
        named object per end, linked by `link`. Split legacy pairs."""
        for did in list(self.door_ids()):
            rows = self._door_rows(did)
            reds = [rd for rd in self.redirects() if rd.get('door') == did]
            if any(e.get('link') for *_x, e in rows) or any(rd.get('link') for rd in reds):
                continue
            cells = []
            for r, k, _n, e in rows:
                c = ('room', r['id'], k, _v(e['x']), _v(e['y']))
                if c not in cells:
                    cells.append(c)
            if len(cells) + len(reds) != 2:
                continue
            ids = [did]
            if len(cells) == 2:
                new = self._new_door_id()
                for r, k, _n, e in rows:
                    if ('room', r['id'], k, _v(e['x']), _v(e['y'])) == cells[1]:
                        e['door'] = new
                ids.append(new)
            else:
                rd = reds[0]
                vid = self.vanilla_door_id(_v(rd['mapID']), _v(rd['screen']),
                                           _v(rd['x']), _v(rd['y']))
                for r2 in self.custom.get('entrance_redirects') or []:
                    if r2.get('door') == did:
                        r2['door'] = vid
                    if r2.get('twin_of') == did:
                        r2['twin_of'] = vid
                ids.append(vid)
            for me, other in ((ids[0], ids[1]), (ids[1], ids[0])):
                if self.parse_vanilla_door_id(me) is None:
                    for *_x, e in self._door_rows(me):
                        e.setdefault('name', f"Door {me.split('_')[-1]}")
                        e['link'] = other
                else:
                    for r2 in self.custom.get('entrance_redirects') or []:
                        if r2.get('door') == me:
                            r2['link'] = other
            notes.append(f'door {did}: split into two linked door objects ({ids[0]} <-> '
                         f'{ids[1]}; same bytes)')

    # ---------------------------------------------------------- teleports
    def add_teleport(self, room, key, state_idx, x, y, dest, dest_screen,
                     spawn_x, spawn_y, states=None):
        """A ONE-WAY exit row (no door id) arriving exactly on the chosen
        cell. states=None: the state on screen only."""
        for n in (states if states is not None else [state_idx]):
            for e in self.exits_of(room, key, n):
                if (_v(e['x']), _v(e['y'])) == (int(x), int(y)) and e.get('door'):
                    raise ValueError(f"cell ({x},{y}) holds door {e['door']} in state {n}")
            self.add_exit(room, key, n, x, y, dest, dest_screen, spawn_x, spawn_y)
        return None

    def exit_signature(self, e):
        return (_v(e['x']), _v(e['y']), str(e.get('dest')), _v(e.get('screen_byte', 0)),
                _v(e.get('spawn_x', 0)), _v(e.get('spawn_y', 0)), e.get('door'))

    def exit_presence(self, room, key, state_idx, index):
        sig = self.exit_signature(self.exits_of(room, key, state_idx)[index])
        return [any(self.exit_signature(e) == sig for e in self.exits_of(room, key, n))
                for n in range(len(self.states(room, key)))]

    def set_exit_presence(self, room, key, state_idx, index, target, present):
        """Copy / remove this (one-way) exit row in another state."""
        src = self.exits_of(room, key, state_idx)[index]
        if src.get('door'):
            sts = set(self.door_end(src['door'])['states'])
            (sts.add if present else sts.discard)(int(target))
            return self.set_door_states(src['door'], sts)
        sig = self.exit_signature(src)
        rows = self.exits_of(room, key, target)
        hit = [i for i, e in enumerate(rows) if self.exit_signature(e) == sig]
        if present and not hit:
            for i, e in enumerate(rows):
                if (_v(e['x']), _v(e['y'])) == (_v(src['x']), _v(src['y'])):
                    if e.get('door'):
                        raise ValueError(f"state {target} holds door {e['door']} on that cell")
                    rows[i] = copy.deepcopy(src)
                    break
            else:
                rows.append(copy.deepcopy(src))
        elif not present:
            for i in reversed(hit):
                rows.pop(i)
        self.touch()

    # ------------------------------------------------------ interact spots
    def add_spot(self, room, key, state_idx, kind, x, y, script, facing='any'):
        """An EXAMINE spot ($8x) or STEP-ON trigger ($90) in the interact
        block of one state (formats.examine_entry / step_trigger_entry).
        Takes no NPC slot. Returns its index in npcs[]."""
        if kind not in ('examine', 'step'):
            raise ValueError(kind)
        lst = self.npc_entries(room, key, state_idx)
        for e in lst:
            v = self.npc_view(room, e)
            if v['kind'] in ('examine', 'step', 'spawn') and (v['x'], v['y']) == (int(x), int(y)):
                raise ValueError(f'cell ({x},{y}) already has an {v["kind"]} spot')
        e = {'kind': kind, 'x': int(x), 'y': int(y), 'script': script}
        if kind == 'examine':
            e['facing'] = facing
        lst.append(e)
        self.touch()
        return len(lst) - 1

    def update_spot(self, room, key, state_idx, index, **fields):
        """x / y / facing / script of an examine or step spot (a legacy
        'spawn' or a cloned raw $8x/$90 entry becomes the typed form with
        the same bytes)."""
        lst = self.npc_entries(room, key, state_idx)
        old = lst[index]
        v = self.npc_view(room, old)
        if v['kind'] not in ('examine', 'step', 'spawn'):
            raise ValueError('not an examine/step spot')
        kind = 'examine' if v['kind'] in ('examine', 'spawn') else 'step'
        e = {'kind': kind, 'x': int(fields.get('x', v['x'])), 'y': int(fields.get('y', v['y'])),
             'script': fields.get('script', v.get('script'))}
        if kind == 'examine':
            e['facing'] = fields.get('facing', v.get('facing', 'any'))
        if e['script'] in (None, 'none'):
            raise ValueError('a spot needs a script')
        lst[index] = e
        self.touch()
        return old
