"""worlds.py — WORLDS (S123, ROADMAP NG3): headless Document mixin (no Qt).

User (S123): "I want just normal rooms with set encounters, and a flag for boss
that can alter things (like encounters, NPC dialogue, things that used to block
your path) depending on whether or not you beat top boss (or side boss, etc).
Basically it doesnt need to act as a random gate, it needs to act as a world
that can have encounters, encounter-free rooms (where you can also save),
mini-bosses, endbosses, flags and triggers. Enter via swirling portal, portal
stops when boss beaten, OR portal is different colour when boss beaten" →
"Entering should be JUST like entering a gate. Losing: Same as a gate."

A world is a NEW gate (32-95) with a `world` block (gates.py "S123",
PROJECT_COMPILER §2.36): its portal is an ordinary gate entrance, the game's own
gate entry serves the world's START room as floor 1, and the rest of the world
is the author's rooms joined by doors. Its CLEARED flag is the gate's own
(`gate:N`, $17A0 + N): a boss conversation turns it ON; the portal swirl then
stops, or takes a colour (`cleared_swirl`, the S123 NPC colours).

Everything here edits the existing schema: custom.gates[] (the world), the
rooms' exits / NPCs (the portal + swirl: GatesMixin.add_gate_entrance +
paint_swirl), custom.scripts / dialogue (a boss's conversation:
ConversationMixin.new_conversation) and custom.flags.
"""

import copy

from editor2.core import gates as G


def _v(x):
    if isinstance(x, int):
        return x
    s = str(x).strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


SAVING_NAMES = {
    'calm': 'in rooms without battles',
    'everywhere': 'in every room',
    'nowhere': 'nowhere (only outside the world)',
}
WORLD_SOURCE_GATE = 0     # the gate a world's number "copies" (only its unused
                          # boss-floor bytes and the never-drawn maze look)


class WorldsMixin:
    # ------------------------------------------------------------ read
    def world_ids(self):
        return G.world_gates(self.custom)

    def world(self, gid):
        """The `world` block of gate gid (or None)."""
        return G.world_settings(self.custom, gid)

    def world_name(self, gid):
        return self.gate_name(gid)

    def world_rooms(self, gid):
        """The world's room ids, start room first."""
        w = self.world(gid) or {}
        sid = (w.get('start') or {}).get('room')
        rooms = [r for r in (w.get('rooms') or []) if r != sid]
        return ([sid] if sid else []) + rooms

    def world_of_room(self, room_id):
        return G.world_of_room(self.custom, room_id)

    def world_cleared_ref(self, gid):
        return G.gate_ref(gid)

    def world_cleared_flag(self, gid):
        info = self.gate_cleared_info(gid)
        return info['flag'] if info else None

    # ------------------------------------------------------------ write
    def new_world(self, name, start_room, screen=0, x=4, y=4, saving='calm'):
        """A world named `name` whose portal lands the player in `start_room`
        (screen, cell). Returns its gate number."""
        if self.room(start_room) is None:
            raise ValueError(f'no room {start_room!r}')
        if self.world_of_room(start_room) is not None:
            raise ValueError(f'room {start_room!r} already belongs to a world')
        gid = self.new_gate(WORLD_SOURCE_GATE, name)
        g = self.gate_setting(gid)
        g['floors'] = G.WORLD_FLOORS
        g['hand_made'] = True
        g['world'] = {'start': {'room': start_room, 'screen': int(screen),
                                'x': int(x), 'y': int(y)},
                      'rooms': [start_room], 'saving': saving}
        self._check_start(gid)
        self.touch()
        return gid

    def _check_start(self, gid):
        w = self.world(gid)
        st = w['start']
        room = self.room(st['room'])
        if str(st['screen']) not in (room.get('screens') or {}):
            raise ValueError(f"room {room.get('name', room['id'])} has no screen {st['screen']}")
        if not (0 <= st['x'] <= 9 and 0 <= st['y'] <= 7):
            raise ValueError('the start cell must be inside the 10 x 8 screen')

    def set_world_start(self, gid, room_id, screen, x, y):
        w = self.world(gid)
        if w is None:
            raise ValueError(f'gate {gid} is not a world')
        other = self.world_of_room(room_id)
        if other is not None and other != gid:
            raise ValueError('that room belongs to another world')
        old = copy.deepcopy(w['start'])
        w['start'] = {'room': room_id, 'screen': int(screen), 'x': int(x), 'y': int(y)}
        try:
            self._check_start(gid)
        except ValueError:
            w['start'] = old
            raise
        if room_id not in w.setdefault('rooms', []):
            w['rooms'].insert(0, room_id)
        self.touch()

    def add_world_room(self, gid, room_id):
        w = self.world(gid)
        if w is None:
            raise ValueError(f'gate {gid} is not a world')
        other = self.world_of_room(room_id)
        if other is not None and other != gid:
            raise ValueError(f'that room belongs to world {self.world_name(other)}')
        if room_id not in w.setdefault('rooms', []):
            w['rooms'].append(room_id)
        self.touch()

    def remove_world_room(self, gid, room_id):
        w = self.world(gid)
        if w is None:
            return
        if (w.get('start') or {}).get('room') == room_id:
            raise ValueError("that is the world's start room — pick another start first")
        w['rooms'] = [r for r in w.get('rooms') or [] if r != room_id]
        self.touch()

    def set_world_saving(self, gid, mode):
        if mode not in G.WORLD_SAVING:
            raise ValueError(f'saving must be one of {G.WORLD_SAVING}')
        w = self.world(gid)
        if mode == 'calm':
            w.pop('saving', None)
            w['saving'] = 'calm'
        else:
            w['saving'] = mode
        self.touch()

    def set_cleared_swirl(self, gid, value):
        """What gate gid's swirls do once it is cleared: None / 'stop' = vanish
        (the game's way), 0-7 = drawn in that OBJ palette (1 = green)."""
        if value in (None, '', 'stop'):
            self.set_gate_setting(gid, cleared_swirl=None)
        else:
            p = int(value)
            if not 0 <= p <= 7:
                raise ValueError('palette 0-7')
            self.set_gate_setting(gid, cleared_swirl=p)

    def delete_world(self, gid):
        """Delete the world (its gate number, portals and swirls); its rooms stay."""
        return self.delete_gate(gid)

    def new_world_room(self, gid, name, source_mid, renderer, gate_theme=None):
        rid = self.new_room(name, source_mid, renderer, gate_theme=gate_theme)
        self.add_world_room(gid, rid)
        return rid

    def add_world_entrance(self, room, key, state_idx, x, y, gid, states=None):
        """The world's PORTAL on a cell: the gate entrance (the game's gate entry
        → the start room), the still swirl art and the spinning swirl object
        (shown until the world is cleared — or, with cleared_swirl, in that
        colour afterwards). Returns the states where the swirl did not fit."""
        if self.world(gid) is None:
            raise ValueError(f'gate {gid} is not a world')
        full = self.add_gate_entrance(room, key, state_idx, x, y, gid, states=states)
        for n in (states if states is not None else [state_idx]):
            self.paint_swirl(room, key, n, x, y)
        return full

    def remove_world_entrance(self, room, key, x, y):
        """S123 r3: take a portal away — the gate-entrance exit on (x, y) and the
        spinning swirl object there, in every state of the screen (the still
        swirl picture stays painted; repaint it like any tile). Returns the
        number of rows removed."""
        n = 0
        for st in self.states(room, key):
            ex = st.get('exits') or []
            keep = [e for e in ex if not (G.is_gate_entrance(e)
                                          and (int(G._val(e['x'])), int(G._val(e['y'])))
                                          == (int(x), int(y)))]
            n += len(ex) - len(keep)
            if ex:
                st['exits'] = keep
            npcs = st.get('npcs') or []
            keepn = [e for e in npcs if not (e.get('swirl_of') is not None
                                              and (int(G._val(e.get('x', -1))),
                                                   int(G._val(e.get('y', -1))))
                                              == (int(x), int(y)))]
            n += len(npcs) - len(keepn)
            if npcs:
                st['npcs'] = keepn
        if not n:
            raise ValueError(f'no portal on ({x},{y})')
        self.touch()
        return n

    def world_portals(self, gid):
        """[(kind, room id | mapID, screen, x, y, label)] — every way into world
        gid: portals in the project's rooms (one per screen cell) and game portals
        led to it (S117 redirects)."""
        out, seen = [], set()
        for r, k, _n, e in self.gate_entrances(gid):
            c = ('room', r['id'], int(k), int(G._val(e['x'])), int(G._val(e['y'])))
            if c not in seen:
                seen.add(c)
                out.append(c + (f"{self.room_name(r)}, screen {k} ({c[3]},{c[4]})",))
        for _i, rd in self.portal_redirects(gid):
            mid = int(G._val(rd['mapID']))
            c = ('vanilla', mid, int(G._val(rd.get('screen', 0))), int(G._val(rd['x'])),
                 int(G._val(rd['y'])))
            if c not in seen:
                seen.add(c)
                out.append(c + (f"game room ${mid:02X}, screen {c[2]} ({c[3]},{c[4]})",))
        return out

    def world_room_effective_save(self, gid, room):
        """True when the JOURNAL works in this world room (the compiler rule)."""
        return self.room_can_save(room)

    def set_world_music(self, gid, song):
        """Give every room of the world without a song of its own `song`
        (a room's music value as the Rooms tab stores it). Returns the rooms changed."""
        out = []
        for rid in self.world_rooms(gid):
            r = self.room(rid)
            if r is not None and not r.get('music'):
                self.set_room_music(r, song)
                out.append(rid)
        return out

    # ------------------------------------------------------------ bosses
    def make_boss(self, room, key, state_idx, index, enemies, flag_name,
                  intro=None, outro=None, end_of_world=None, leave=None):
        """Turn NPC `index` into a boss: a conversation [Say intro] → Battle
        (1-3 enemies) → Turn ON its own `flag_name` (+ the world's cleared flag
        when `end_of_world` = a world's gate number) → Vanish (it flickers out
        at once) → [Say outro] → [leave: a helper step dict]; the NPC is shown
        only while its flag is OFF (gone for good once beaten). Returns the
        conversation's script id."""
        if not enemies or len(enemies) > 3:
            raise ValueError('a battle has 1-3 enemies')
        lst = self.npc_entries(room, key, state_idx)
        e = lst[index]
        if e.get('kind') != 'npc':
            raise ValueError('pick an NPC (a person, object or monster)')
        name = flag_name if any(f.get('name') == flag_name for f in self.flags()) \
            else self.add_flag(flag_name)
        def text(t):        # [[line, line], …] or a text dict {boxes, speaker?, voice?}
            return dict(t) if isinstance(t, dict) else {'boxes': [list(b) for b in t]}
        steps = []
        if intro:
            steps.append({'say': text(intro)})
        steps.append({'battle': {'enemies': list(enemies)}})
        sets = [name]
        if end_of_world is not None:
            sets.append(G.gate_ref(end_of_world))
        steps.append({'set': sets})
        steps.append({'vanish': {'how': 'flicker'}})      # gone now; the flag keeps it gone
        if outro:
            steps.append({'say': text(outro)})
        if leave:
            steps.append({'helper': dict(leave)})
        sid = self.new_conversation(room, {'steps': steps}, name=f'boss_{name}')
        self.update_npc(room, key, state_idx, index, script=sid)
        terms = [t for t in (lst[index].get('shown_when') or []) if t.get('flag') != name]
        terms.append({'flag': name, 'is': 'clear'})
        self.set_npc_shown_when(room, key, state_idx, index, terms)
        self.touch()
        return sid

    def world_portal_spot(self, gid):
        """(dest ref, screen, x, y) of the cell just below the world's first portal
        (where a helper / exit puts the player back in front of it), or None."""
        ent = self.gate_entrances(gid)
        if not ent:
            return None
        r, k, _n, e = ent[0]
        x, y = _v(e['x']), _v(e['y'])
        y2 = y + 1 if y < 7 else y - 1
        return (f"room:${_v(r['mapID']):02X}", int(k), x, y2)

    def bosses_in(self, room):
        """[(screen key, state, npc index, script id, flags it sets, enemies)] —
        NPCs whose conversation has a battle."""
        out = []
        for k in self.screen_keys(room):
            for n, st in enumerate(self.states(room, k)):
                for i, e in enumerate(st.get('npcs') or []):
                    sid = e.get('script')
                    if not isinstance(sid, str) or sid == 'none':
                        continue
                    t = self.conversation(sid)
                    if not t:
                        continue
                    sets, foes = [], []

                    def walk(steps):
                        for s in steps or []:
                            if 'battle' in s:
                                foes.extend((s['battle'] or {}).get('enemies') or [])
                            if 'set' in s:
                                sets.extend(s['set'] or [])
                            for kk in ('yes', 'no', 'then', 'else'):
                                walk(s.get(kk))
                    walk(t.get('steps'))
                    if foes:
                        out.append((k, n, i, sid, sets, foes))
        return out

    # ------------------------------------------------------------ report
    def world_report(self, gid):
        """What the World tab shows: per room {id, name, start, battles (list
        or None), variants, save, bosses, ways (rooms it leads to)} + problems
        [str] + whether something marks the world cleared."""
        w = self.world(gid) or {}
        ref = G.gate_ref(gid)
        members = self.world_rooms(gid)
        by_mid = {}
        for r in self.rooms:
            if not r.get('placeholder'):
                try:
                    by_mid[_v(r['mapID'])] = r['id']
                except (KeyError, ValueError, TypeError):
                    pass
        rows, problems, cleared_by, leaves, edges = [], [], [], False, {}
        for rid in members:
            r = self.room(rid)
            if r is None:
                problems.append(f'room {rid} no longer exists')
                continue
            enc = r.get('encounters') or {}
            ways = set()
            for k in self.screen_keys(r):
                for n, st in enumerate(self.states(r, k)):
                    for e in st.get('exits') or []:
                        if 'dest' not in e or G.is_stairs_down(e):
                            continue
                        if G.is_gate_entrance(e):
                            leaves = True
                            continue
                        d = str(e['dest'])
                        try:
                            mid = _v(d.split(':', 1)[1]) if ':' in d else _v(d)
                        except (ValueError, TypeError):
                            continue
                        to = by_mid.get(mid) if mid >= 0x6B else None
                        if to in members:
                            ways.add(to)
                        else:
                            leaves = True
            edges[rid] = ways
            bosses = self.bosses_in(r)
            for b in bosses:
                if ref in b[4]:
                    cleared_by.append((rid, b))
            for sid in (r.get('scripts') or {}).values():
                t = self.conversation(sid) if isinstance(sid, str) else None

                def walk(steps):
                    nonlocal leaves
                    for s in steps or []:
                        if 'helper' in s or 'move' in s:
                            leaves = True
                        for kk in ('yes', 'no', 'then', 'else'):
                            walk(s.get(kk))
                walk((t or {}).get('steps'))
            rows.append({'id': rid, 'name': r.get('name', rid),
                         'start': rid == (w.get('start') or {}).get('room'),
                         'battles': (enc.get('list') if enc.get('enabled') else None),
                         'battles_on': bool(enc.get('enabled')),
                         'variants': len(enc.get('variants') or []),
                         'save': self.world_room_effective_save(gid, r),
                         'bosses': bosses, 'ways': sorted(ways)})
            if enc.get('enabled') and 'list' not in enc:
                problems.append(f"{r.get('name', rid)}: battles are on but the room has no "
                                "battle list of its own (Encounters tab → Rooms)")
        seen, todo = set(members[:1]), list(members[:1])
        while todo:
            for nx in edges.get(todo.pop(), ()):
                if nx not in seen:
                    seen.add(nx)
                    todo.append(nx)
        for rid in members:
            if rid not in seen and self.room(rid) is not None:
                problems.append(f"{self.room(rid).get('name', rid)} cannot be reached from the "
                                "start room by the world's doors")
        if not cleared_by:
            problems.append(f'nothing turns the world\'s cleared flag ({ref}) ON — make an '
                            'end boss (NPC → Make boss…, "end boss of this world")')
        if not leaves:
            problems.append('no door, exit or warp leads out of the world (the player can '
                            'only leave by losing a battle)')
        if not self.gate_entrances(gid) and not [rd for rd in self.portal_redirects(gid)]:
            problems.append('the world has no portal yet (Rooms tab: More ▾ → World '
                            'entrance here…)')
        return {'rooms': rows, 'problems': problems, 'cleared_by': cleared_by,
                'leaves': leaves}
