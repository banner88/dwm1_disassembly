"""tileanim_doc.py — Document operations for a room's OWN animated tiles
(S102; the data format and engine: editor2/core/tileanim.py).

User S102: "I just want animated tiles and for the UI to tell me wtf is
happening". So the model is: select cells on the canvas, say how they move
(flip through frames you draw / drift / sway) and how fast. The editor works
out which 8x8 tiles change, and — because the game animates a TILE SLOT, so
every cell drawn with that slot changes — gives the selected cells their own
copies when the same tiles are drawn elsewhere and you asked for only these
cells (that is the one thing that costs free tiles on the tileset).

Pure document logic (no Qt) — mixed into editor2.core.document.Document.
"""
from editor2.core import tileanim as TA


def _val(v):
    if isinstance(v, int):
        return v
    s = str(v).strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


def _uniform(tile):
    """True when all 64 pixels share one colour (rolling it changes nothing)."""
    lo, hi = tile[0::2], tile[1::2]
    return (all(b == 0 for b in lo) or all(b == 0xFF for b in lo)) and \
        (all(b == 0 for b in hi) or all(b == 0xFF for b in hi))


def _moving(grid, cur, motion, frames, strip):
    """Subtile positions of the selection that actually change: flip — a
    frame differs from the art now; strip drift/sway — every tile of a row,
    except rows that are one flat colour (they look the same rolled); per-
    tile drift/sway — tiles that are not one flat colour."""
    r0, c0 = grid[0][0]
    if motion == 'flip':
        return [p for row in grid for p in row
                if any(f[p[0] - r0][p[1] - c0] != cur[p] for f in frames)]
    if strip:
        out = []
        for row in grid:
            tiles = [cur[p] for p in row]
            if all(_uniform(t) for t in tiles) and len(set(tiles)) == 1:
                continue
            out += row
        return out
    return [p for row in grid for p in row if not _uniform(cur[p])]


class TileAnimMixin:
    # ------------------------------------------------------------ queries
    def tile_anims(self, room):
        return list(room.get('tile_anims') or [])

    def tile_anim(self, room, aid):
        return next((a for a in room.get('tile_anims') or [] if a.get('id') == aid), None)

    def own_anim_slots(self, room):
        out = set()
        for it in room.get('tile_anims') or []:
            out |= set(TA.slots_of(it))
        return out

    def own_anim_slots_tileset(self, tid):
        out = set()
        for r in self.rooms_using_tileset(tid):
            out |= self.own_anim_slots(r)
        return out

    def anim_of_slot(self, room, slot):
        for it in room.get('tile_anims') or []:
            if slot in TA.slots_of(it):
                return it
        return None

    def _free_anim_tiles(self, tid):
        """Free slots an own copy may take (the same count before and after
        a vanilla sheet is copied into the project — the vocabulary stays
        protected either way)."""
        try:
            used = self.used_tiles(tid) | self.own_anim_slots_tileset(tid)
        except Exception:
            return 0
        return sum(1 for i in range(128) if i not in used)

    def _room_positions(self, room):
        """{slot: [(layout id, row, col)]} over every layout this room draws."""
        out = {}
        for lid in self._room_layout_ids(room):
            T = self.layout(lid)['tiles']
            for r, row in enumerate(T):
                for c, v in enumerate(row):
                    out.setdefault(v & 0x7F, []).append((lid, r, c))
        return out

    def _room_sheet_bytes(self, room):
        rec = room['record']
        if 'tileset' in rec:
            return bytes(self.read_sheet(rec['tileset']))
        return bytes(self.vanilla.room_gfx(room).sheet)

    @staticmethod
    def _sel_positions(rect):
        """(c0, r0, c1, r1) cells inclusive -> subtile (row, col) grid rows."""
        c0, r0, c1, r1 = rect
        return [[(r, c) for c in range(c0 * 2, c1 * 2 + 2)] for r in range(r0 * 2, r1 * 2 + 2)]

    def anim_selection(self, room, lid, rect, motion='flip', frames=None, strip=True,
                       private=True):
        """What animating these cells would do — the plain facts the UI
        shows before anything changes. `frames` (flip): list of frames, each
        a grid (rows x cols of the selection's subtiles) of 16-byte tiles.
        Returns {'moving': [(r, c)], 'slots': rows of slots after copies,
        'copies': n free tiles needed, 'free': n free tiles on the tileset,
        'elsewhere': n other subtiles in this room drawn with the moving
        tiles, 'problem': text or None, 'strip_w': tiles per row}."""
        sheet = self._room_sheet_bytes(room)
        T = self.layout(lid)['tiles']
        grid = self._sel_positions(rect)
        h, w = len(grid), len(grid[0])
        out = {'moving': [], 'slots': [], 'copies': 0, 'free': 0, 'elsewhere': 0,
               'problem': None, 'strip_w': w, 'cells': (rect[2] - rect[0] + 1) * (rect[3] - rect[1] + 1)}
        tid = self.tileset_key(room)
        out['free'] = self._free_anim_tiles(tid)
        thr = _val(room['record']['collision_threshold'])
        slot = lambda p: T[p[0]][p[1]] & 0x7F
        cur = {p: bytes(sheet[slot(p) * 16:slot(p) * 16 + 16]) for row in grid for p in row}
        fr = frames or []
        moving = _moving(grid, cur, motion, fr, strip)
        if motion != 'flip' and strip and w > TA.MAX_STRIP:
            out['problem'] = (f'A drifting strip can be at most {TA.MAX_STRIP} tiles '
                              f'({TA.MAX_STRIP // 2} cells) wide — select fewer cells, or '
                              'untick "pixels flow from tile to tile"')
        out['moving'] = moving
        if not moving:
            out['problem'] = out['problem'] or (
                'Nothing would change: paint something different in another frame'
                if motion == 'flip' else 'These cells are one flat colour — nothing to move')
            return out
        # which positions need their own slot
        pos_all = self._room_positions(room)
        sel = {p for row in grid for p in row}
        vanilla = self.room_animation(room)['slots']
        taken = {}
        for it in room.get('tile_anims') or []:
            for s in TA.slots_of(it):
                taken[s] = it
        key_of = {}
        for p in moving:
            if motion == 'flip':
                k = (slot(p), tuple(f[p[0] - grid[0][0][0]][p[1] - grid[0][0][1]] for f in fr))
            elif strip:
                k = (slot(p), p)                  # every strip position shows its own pixels
            else:
                k = (slot(p),)
            key_of[p] = k
        keys = list(dict.fromkeys(key_of[p] for p in moving))
        first_key = {}
        need = 0
        elsewhere = 0
        for k in keys:
            s = k[0]
            outside = [q for q in pos_all.get(s, []) if not (q[0] == lid and (q[1], q[2]) in sel)]
            inside_other = [p for p in sel if slot(p) == s and p not in moving]
            clash = s in first_key                # another key already uses this slot
            first_key.setdefault(s, k)
            must = clash or s in vanilla or (s in taken) or bool(inside_other)
            if must or (private and outside):
                need += 1
            elif outside:
                elsewhere += len(outside)
        out['copies'] = need
        out['elsewhere'] = elsewhere
        if need > out['free']:
            out['problem'] = (f'This needs {need} free tile(s) on the tileset (own copies, so '
                              f'only these cells move) and it has {out["free"]} — free some '
                              '(Tileset tab: purge unused), or choose "every place these tiles '
                              'are drawn"')
        del thr
        return out

    def tile_anim_budget(self, room):
        """The numbers the UI shows (plain)."""
        items = self.tile_anims(room)
        tid = self.tileset_key(room)
        free = self._free_anim_tiles(tid)
        rom = 0
        room_rom = 0
        for r in self.rooms:
            for it in r.get('tile_anims') or []:
                try:
                    b = TA.rom_bytes(it)
                except Exception:
                    continue
                rom += b
                if r.get('id') == room.get('id'):
                    room_rom += b
        # S139 (ARC CAP2d): bank $6C first, then animation banks $80+ — the
        # project has no frame-storage ceiling short of the ROM; ONE room's
        # animations must fit one animation bank
        from . import validators as V
        cap = TA.BANK_BYTES - V.ANIM_TEMPLATE_SIZE - TA.ALIGN_PAD - TA.TABLE_ROW_BYTES
        groups = sum(-(-len(TA.slots_of(it)) // TA.CAP) for it in items)
        L = TA.load(items) if items else {'pct': 0.0, 'per_frame': 0, 'peak': 0, 'changes_s': 0}
        return {'items': len(items), 'tiles': sum(len(TA.slots_of(it)) for it in items),
                'free_tiles': free, 'rom_used': rom, 'rom_cap': cap, 'rom_room': room_rom,
                'groups': groups, 'groups_cap': TA.MAX_GROUPS,
                'load_pct': L['pct'], 'load_words': TA.load_words(items),
                'peak': L['peak']}

    # ------------------------------------------------------------ edits
    def _new_anim_id(self, room, base):
        ids = {a.get('id') for a in room.get('tile_anims') or []}
        base = ''.join(ch if ch.isalnum() else '_' for ch in (base or 'anim').lower()).strip('_') \
            or 'anim'
        aid, n = base, 2
        while aid in ids:
            aid = f'{base}_{n}'
            n += 1
        return aid

    def add_tile_anim(self, room_id, lid, rect, motion, speed, frames=None, order='loop',
                      strip=True, amplitude=1, name=None, private=True, own_sheet=None):
        """Animate the selected cells (rect = c0, r0, c1, r1 of layout `lid`).
        Returns the new item; `self.last_import_note` says what happened."""
        room = self.room(room_id)
        if motion not in TA.MOTIONS:
            raise RuntimeError(f'unknown motion {motion!r}')
        if lid not in self._room_layout_ids(room):
            raise RuntimeError(f'layout {lid!r} is not drawn by this room — reopen the room '
                               'and select the cells again')
        info = self.anim_selection(room, lid, rect, motion, frames, strip, private)
        if info['problem']:
            raise RuntimeError(info['problem'])
        rec = room['record']
        if 'tileset' not in rec:
            if own_sheet is None:
                own_sheet = self._room_sheet_bytes(room)
            self.localize_tileset(room, own_sheet)
        tid = rec['tileset']
        thr = _val(rec['collision_threshold'])
        sheet = self.read_sheet(tid)
        T = self.layout(lid)['tiles']
        grid = self._sel_positions(rect)
        r0, c0 = grid[0][0]
        slot = lambda p: T[p[0]][p[1]] & 0x7F
        cur = {p: bytes(sheet[slot(p) * 16:slot(p) * 16 + 16]) for row in grid for p in row}
        moving = info['moving']
        fr = frames or []
        assert moving == _moving(grid, cur, motion, fr, strip)
        sel = {p for row in grid for p in row}
        pos_all = self._room_positions(room)
        vanilla = self.room_animation(room)['slots']
        taken = self.own_anim_slots(room)
        used = self.used_tiles(tid) | self.own_anim_slots_tileset(tid)
        free = [i for i in range(128) if i not in used]

        def keyf(p):
            if motion == 'flip':
                return (slot(p), tuple(f[p[0] - r0][p[1] - c0] for f in fr))
            if strip:
                return (slot(p), p)
            return (slot(p),)
        key_of = {p: keyf(p) for p in moving}      # frozen before any slot moves
        keys = list(dict.fromkeys(key_of[p] for p in moving))
        new_slot = {}
        first = {}
        copies = []
        for k in keys:
            s = k[0]
            outside = [q for q in pos_all.get(s, []) if not (q[0] == lid and (q[1], q[2]) in sel)]
            inside_other = [p for p in sel if slot(p) == s and p not in moving]
            clash = s in first
            first.setdefault(s, k)
            if clash or s in vanilla or s in taken or inside_other or (private and outside):
                ps = [p for p in moving if key_of[p] == k]
                br = any(p[0] % 2 == 1 and p[1] % 2 == 1 for p in ps)
                cand = [f for f in free if not br or (f < thr) == (s < thr)]
                if not cand:
                    raise RuntimeError('no free tile left on the tileset for an own copy'
                                       + (' on the right wall/walkable side' if br else ''))
                f = cand[-1] if s < thr else cand[0]
                free.remove(f)
                sheet[f * 16:f * 16 + 16] = sheet[s * 16:s * 16 + 16]
                new_slot[k] = f
                copies.append((s, f))
            else:
                new_slot[k] = s
        self.write_sheet(tid, sheet)
        for p in moving:
            v = T[p[0]][p[1]]
            T[p[0]][p[1]] = (v & 0x80) | new_slot[key_of[p]]
        # the item: rows of slots (selection rows, moving positions, unique)
        rows, seen = [], set()
        for row in grid:
            rr = []
            for p in row:
                if p in moving:
                    s = new_slot[key_of[p]]
                    if s not in seen:
                        seen.add(s)
                        rr.append(s)
            if rr:
                rows.append(rr)
        item = {'id': self._new_anim_id(room, name or TA.MOTION_LABEL[motion]),
                'name': name or TA.MOTION_LABEL[motion], 'motion': motion,
                'speed': int(speed), 'rows': rows,
                'where': {'layout': lid, 'x': rect[0], 'y': rect[1],
                          'w': rect[2] - rect[0] + 1, 'h': rect[3] - rect[1] + 1},
                'scope': 'here' if private else 'everywhere'}
        if motion == 'flip':
            order_slots = [s for row in rows for s in row]
            pos_of = {}
            for p in moving:
                pos_of.setdefault(new_slot[key_of[p]], p)
            item['frames'] = [[f[pos_of[s][0] - r0][pos_of[s][1] - c0].hex() for s in order_slots]
                              for f in fr]
            item['order'] = order
        else:
            item['strip'] = bool(strip)
            if motion == 'sway':
                item['amplitude'] = int(amplitude)
        errs = TA.problems(room, self.tile_anims(room) + [item], bytes(sheet), vanilla)
        if errs:
            raise RuntimeError(errs[0])
        room.setdefault('tile_anims', []).append(item)
        n = len(TA.slots_of(item))
        note = [f"{item['name']}: {n} tile(s) {TA.MOTION_LABEL[motion].lower()}, "
                f"{TA.speed_words(int(speed))}"]
        if copies:
            note.append(f'{len(copies)} own cop{"y" if len(copies) == 1 else "ies"} made so only '
                        'these cells move')
        if info['elsewhere'] and not private:
            note.append(f"{info['elsewhere']} other place(s) in this room drawn with the same "
                        'tiles move too')
        self.last_import_note = '; '.join(note)
        self.touch()
        return item

    def update_tile_anim(self, room_id, aid, **fields):
        """Change speed / order / amplitude / strip / name / frames (flip)
        of an existing animation in place."""
        room = self.room(room_id)
        it = self.tile_anim(room, aid)
        if it is None:
            raise RuntimeError(f'no animation {aid!r} in this room')
        new = dict(it)
        for k, v in fields.items():
            if v is None:
                continue
            if k == 'frames':
                new['frames'] = [[b.hex() if isinstance(b, (bytes, bytearray)) else b for b in f]
                                 for f in v]
            elif k in ('speed', 'amplitude'):
                new[k] = int(v)
            elif k == 'strip':
                new[k] = bool(v)
            else:
                new[k] = v
        others = [a for a in self.tile_anims(room) if a.get('id') != aid]
        errs = TA.problems(room, others + [new], self._room_sheet_bytes(room),
                           self.room_animation(room)['slots'])
        if errs:
            raise RuntimeError(errs[0])
        it.clear()
        it.update(new)
        self.touch()
        return it

    def remove_tile_anim(self, room_id, aid):
        """Stop an animation: its tiles show their first frame again."""
        room = self.room(room_id)
        lst = room.get('tile_anims') or []
        keep = [a for a in lst if a.get('id') != aid]
        if len(keep) == len(lst):
            raise RuntimeError(f'no animation {aid!r} in this room')
        if keep:
            room['tile_anims'] = keep
        else:
            room.pop('tile_anims', None)
        self.touch()

    def tile_anim_player(self, room):
        """The game's playback of this room's own animations (canvas preview)."""
        return TA.Player(self.tile_anims(room), self._room_sheet_bytes(room))
