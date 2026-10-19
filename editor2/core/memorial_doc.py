"""memorial_doc.py — editing the memorial's statues (S154).

Headless Document mixin (no Qt): custom.memorial and custom.rooms[].statues
(editor2/core/memorial.py, PROJECT_COMPILER §2.62). A STATUE (S154 r2) = two cells:
its PEDESTAL (the room's "Pedestal" metatile, ordinary editable tiles) on the
statue's cell and its MONSTER CELL above it — 4 reserved tiles of the room's sheet
holding the background that was there (the game draws the monster over them) — +
where it stands per screen state (an npcs[] entry {"kind": "statue", "x", "y",
"statue": id}, (x, y) = the pedestal). The Rooms tab reads and writes only
through these; every change is one undo step there (the tab's NpcCommand /
SnapshotCommand).
"""

import copy

from editor2.core import memorial as MM
from editor2.core.formats import val

# S154 r2 (the user: "Pedestal should be its own tile I can edit (in editor). The whole
# thing then takes up 2 tiles. Then monster sits on top (second tile)"; "Monster should
# be grey but BACKGROUND should be transparent"): a statue = TWO cells —
#   the PEDESTAL on the statue's cell (x, y): an ordinary metatile "Pedestal" of the
#     room's sheet (edit it in the Draw tab; every statue of the room shares it),
#   the MONSTER CELL above it (x, y - 1): 4 reserved tiles that start as a copy of what
#     was drawn there (the floor / the wall behind), over which the game draws the
#     monster — its colour-0 pixels let that background show, so it looks see-through.
# Both cells use the STATUE PALETTE: a slot equal to the background's palette except
# one index the background does not use, which holds GREY; the monster's middle shade is
# drawn in that index (its light / dark shades in the fixed cream / black) — a grey
# monster on an untouched background.
GREY = 0x4210                       # the statue palette's grey (RGB555 16, 16, 16)
CREAM, BLACK = 0x6BFF, 0x0000       # colours 1 / 3 the engine forces (KEY_LESSONS S7 / S39)

# The default pedestal (16 x 16): '.' = the background behind (kept), 'K' black, 'C'
# cream, 'G' the statue grey. A cap, a column, a base.
PEDESTAL_ART = (
    '..KKKKKKKKKKKK..',
    '..KCCCCCCCCCCK..',
    '..KGGGGGGGGGGK..',
    '..KKKKKKKKKKKK..',
    '...KCGGGGGGGK...',
    '...KCGGGGGGGK...',
    '...KCGGGGGGGK...',
    '...KCGGGGGGGK...',
    '...KCGGGGGGGK...',
    '...KCGGGGGGGK...',
    '...KCGGGGGGGK...',
    '..KKKKKKKKKKKK..',
    '.KCCCCCCCCCCCCK.',
    '.KGGGGGGGGGGGGK.',
    '.KGGGGGGGGGGGGK.',
    '.KKKKKKKKKKKKKK.')

PEDESTAL_NAME = 'Pedestal'

TEXT_ID = 'memorial_text'           # the project's statue words (Memorial settings)
EMPTY_ID = 'memorial_empty'


def _tile_bytes(pix, ty, tx):
    out = bytearray()
    for r in range(8):
        lo = hi = 0
        for c in range(8):
            v = pix[ty * 8 + r][tx * 8 + c]
            lo = (lo << 1) | (v & 1)
            hi = (hi << 1) | ((v >> 1) & 1)
        out += bytes((lo, hi))
    return bytes(out)


def _dist(c1, c2):
    """Squared RGB555 distance."""
    return sum((((c1 >> k) & 31) - ((c2 >> k) & 31)) ** 2 for k in (0, 5, 10))


class MemorialMixin:
    # ------------------------------------------------------------ settings
    def memorial_settings(self):
        """{'cap', 'text': boxes, 'empty': boxes} — the project's statue words
        (the compiler's defaults when the project has none)."""
        m = self.custom.get('memorial') or {}
        out = {'cap': m.get('cap', MM.CAP_DEFAULT)}
        for k, did, dflt in (('text', m.get('text'), MM.DEFAULT_TEXT),
                             ('empty', m.get('empty'), MM.DEFAULT_EMPTY)):
            d = self._dialogue_entry(did) if did else None
            out[k] = copy.deepcopy(d['boxes']) if d and d.get('boxes') else copy.deepcopy(dflt)
        return out

    def _dialogue_entry(self, did):
        for d in self.custom.get('dialogue') or []:
            if isinstance(d, dict) and d.get('id') == did:
                return d
        return None

    def _put_dialogue(self, did, boxes, comment):
        d = self._dialogue_entry(did)
        if d is None:
            self.custom.setdefault('dialogue', []).append(
                {'id': did, 'boxes': [list(b) for b in boxes], 'comment': comment})
        else:
            d['boxes'] = [list(b) for b in boxes]
            d.pop('text', None)

    def set_memorial(self, cap=None, text=None, empty=None):
        """The memorial's settings: how many monsters it remembers (8-120) and the
        statues' words (boxes; {fallen} / {fallen_level} / {fallen_species})."""
        m = self.custom.setdefault('memorial', {})
        if cap is not None:
            cap = int(cap)
            if not MM.CAP_MIN <= cap <= MM.CAP_MAX:
                raise ValueError(f'the memorial remembers {MM.CAP_MIN}-{MM.CAP_MAX} monsters')
            m['cap'] = cap
        if text is not None:
            self._put_dialogue(TEXT_ID, text, "S154: the memorial statues' words")
            m['text'] = TEXT_ID
        if empty is not None:
            self._put_dialogue(EMPTY_ID, empty, "S154: an empty memorial statue's words")
            m['empty'] = EMPTY_ID
        self.touch()
        return self.memorial_settings()

    # ------------------------------------------------------------ statues
    def statues(self, room):
        """The room's statues in fill order (statue 1 gets a monster first)."""
        return list(room.get('statues') or [])

    def statue(self, room, sid):
        for s in room.get('statues') or []:
            if s.get('id') == sid:
                return s
        return None

    def statue_slots(self, tid):
        """Sheet slots of `tid` a statue of any room drawing with it uses — the game
        draws monsters into them, so nothing else may share them (merged into
        animated_slots, the set every tile search keeps away from)."""
        out = set()
        for r in self.rooms_using_tileset(tid):
            for s in r.get('statues') or []:
                for t in s.get('tiles') or []:
                    out.add(val(t) & 0x7F)
        return out

    def statue_places(self, room, sid):
        """[(screen key, state index, x, y)] where statue `sid` stands."""
        out = []
        for k in self.screen_keys(room):
            for i, st in enumerate(self.states(room, k)):
                for e in st.get('npcs') or []:
                    if e.get('kind') == 'statue' and e.get('statue') == sid:
                        out.append((k, i, int(e['x']), int(e['y'])))
        return out

    def statue_number(self, room, sid):
        """1-based fill order (statue 1 gets a monster first)."""
        for k, s in enumerate(room.get('statues') or []):
            if s.get('id') == sid:
                return k + 1
        return None

    def _room_sheet(self, room, key, state_idx, x, y):
        """(tileset id, sheet bytearray) — the room's own sheet (a room still
        drawing with a vanilla sheet gets its own copy first)."""
        rec = room['record']
        tid = rec.get('tileset')
        if tid is None:
            _c, sheet = self._cell_tiles_and_sheet(room, key, state_idx, x, y)
            tid = self.localize_tileset(room, bytearray(sheet))
        return tid, self.read_sheet(tid)

    # ---------------------------------------------------- pixels + palette
    def _writable_cell_grids(self, room, key, state_idx):
        """(tiles grid, attr grid) of this screen state, both project items (a
        vanilla layout / attr shown is copied first, as any paint does)."""
        ref = self.state_layout_ref(room, key, state_idx)
        if ref is None:
            raise RuntimeError(f'screen {key} has no layout')
        if 'id' not in ref:
            grid = [list(r) for r in self.vanilla.layout_grid(ref)[0]]
            self.localize_layout(room, key, state_idx, grid)
            ref = self.state_layout_ref(room, key, state_idx)
        aid = self.writable_attr_id(room, key, state_idx)
        return self.layout(ref['id'])['tiles'], self.layout(aid)['attr']

    def _cell_pixels(self, tiles, attr, sheet, x, y):
        """Cell (x, y) as drawn: (16 x 16 colour indices, 16 x 16 palette slots)."""
        blocks = None
        common = None
        pix = [[0] * 16 for _ in range(16)]
        pal = [[0] * 16 for _ in range(16)]
        for dr in (0, 1):
            for dc in (0, 1):
                t = tiles[y * 2 + dr][x * 2 + dc]
                slot = attr[y * 2 + dr][x * 2 + dc] & 7
                if t < 0x80:
                    if blocks is None:
                        from editor2.core.render_project import decode_tiles
                        blocks = decode_tiles(bytes(sheet[:2048]).ljust(2048, b'\0'))
                    blk = blocks[t]
                elif self.vanilla is not None and t < 0xB0:
                    if common is None:
                        common = self.vanilla.common_blocks()
                    blk = common[t - 0x80]
                else:
                    blk = bytes(64)
                for r in range(8):
                    for c in range(8):
                        pix[dr * 8 + r][dc * 8 + c] = blk[r * 8 + c]
                        pal[dr * 8 + r][dc * 8 + c] = slot
        return pix, pal

    def _pal_rows(self, pid):
        """[slot][index] -> RGB555 as the game shows them (forced cream / black),
        or None (a vanilla palette borrowed: no project palette to give a slot)."""
        if not pid:
            return None
        try:
            p = self.palette(pid)
        except KeyError:
            return None
        free1 = bool(p.get('free_color1'))
        out = []
        for i, row in enumerate(p['colors_rgb555'][:8]):
            r = [val(c) & 0x7FFF for c in row]
            if not (free1 and i < 4):
                r[1] = CREAM
            r[3] = BLACK
            out.append(r)
        return out

    def _slots_in_use(self, pid):
        """BG palette slots any cell of any room drawing with palette `pid` uses."""
        used = set()
        for r in self.rooms:
            if not isinstance(r.get('screens'), dict):
                continue
            for k, scr in r['screens'].items():
                for i, st in enumerate(self.states(r, int(k))):
                    if self.effective_palette(r, int(k), i) != pid:
                        continue
                    grid = None
                    if self.vanilla is not None:
                        try:
                            grid = self.vanilla.attr_grid(r, int(k), i)[0]
                        except Exception:                     # noqa: BLE001
                            grid = None
                    for ref in (st.get('attr'), (st.get('layout') or {}),
                                scr.get('attr'), scr.get('layout') or {},
                                (r.get('render') or {}).get('attr')):
                        if ref and 'id' in ref and self.has_layout(ref['id']) and \
                                'attr' in self.layout(ref['id']):
                            grid = self.layout(ref['id'])['attr']
                            break
                    for row in grid or []:
                        used.update(v & 7 for v in row)
        return used

    def _statue_palette(self, room, key, state_idx, mpix, mpal, pal=None):
        """-> (slot, grey index g, note). g = an index of {0, 2} the monster cell's
        background does not use (else the least used one); slot = a BG slot whose
        colours equal the background's own slot with g = GREY (an existing one, else
        a free one is set up), or `pal` when the author names one, or — no free
        slot / no project palette — the background's own slot (the monster's middle
        shade then shows that slot's colour g, not grey; the note says so)."""
        from collections import Counter
        cnt = Counter(v for row in mpix for v in row)
        g = min((0, 2), key=lambda i: (cnt[i], i != 2))
        bslot = Counter(v for row in mpal for v in row).most_common(1)[0][0]
        if pal is not None:
            return int(pal), g, f'palette slot {int(pal)} (chosen)'
        pid = self.effective_palette(room, key, state_idx)
        rows = self._pal_rows(pid)
        if rows is None:
            return bslot, g, ('the screen borrows a game palette — the monster\'s middle '
                              f'shade shows colour {g} of slot {bslot}; give the screen its '
                              'own palette (Palettes) for a grey statue')
        free1 = bool(self.palette(pid).get('free_color1'))
        want = list(rows[bslot])
        want[g] = GREY
        keys = (0, 1, 2) if free1 else (0, 2)
        for s2 in range(4):
            if all(rows[s2][i] == want[i] for i in keys):
                return s2, g, f'palette slot {s2} (its colour {g} is the grey)'
        used = self._slots_in_use(pid)
        for s2 in range(4):
            if s2 not in used:
                for i in keys:
                    self.set_palette_color(pid, s2, i, want[i])
                return s2, g, (f'palette slot {s2} set up for the statues (the background\'s '
                               f'colours, colour {g} grey)')
        return bslot, g, (f'no free palette slot (0-3 all drawn with) — the monster\'s middle '
                          f'shade shows colour {g} of slot {bslot}; free a slot for a grey statue')

    def _remap_to(self, pix, pal, rows, slot, g):
        """Background pixels (index, their slot) -> indices of `slot` showing the same
        colour (never g, the monster's grey): the same index when it shows the same
        colour, else the nearest of the slot's colours."""
        out = [[0] * 16 for _ in range(16)]
        for y in range(16):
            for x in range(16):
                i, q = pix[y][x], pal[y][x]
                if rows is None:
                    out[y][x] = i if i != g else (2 if g == 0 else 0)
                    continue
                c = rows[q][i]
                cand = [j for j in range(4) if j != g]
                if i in cand and rows[slot][i] == c:
                    out[y][x] = i
                    continue
                out[y][x] = min(cand, key=lambda j: _dist(rows[slot][j], c))
        return out

    def _statue_paint(self, tiles_grid, attr_grid, x, y, tiles, pal):
        for j, (dr, dc) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
            tiles_grid[int(y) * 2 + dr][int(x) * 2 + dc] = tiles[j]
            if pal is not None:
                attr_grid[int(y) * 2 + dr][int(x) * 2 + dc] = int(pal)

    def add_statue(self, room, key, state_idx, x, y, pal=None, name=None):
        """A NEW statue whose PEDESTAL stands on cell (x, y) of this screen state and
        whose MONSTER CELL is (x, y - 1) above it (S154 r2). The monster cell gets 4
        reserved tiles copied from what was drawn there (the game draws the monster
        over them); the pedestal is the room's "Pedestal" metatile (made with the
        room's first statue, drawn over the floor that was on its cell; shared, editable
        in the Draw tab). Both cells: the statue palette (`_statue_palette`; `pal` = a
        slot of the author's choice). Both are solid (their bottom-right tiles on the
        wall side). An examine spot on the pedestal. Returns the statue's id;
        self.last_statue_note says which palette it got. Raises ValueError /
        RuntimeError / VocabReleaseWouldHelp."""
        if room.get('mapID') is None:
            raise ValueError('statues stand only in the project\'s own rooms')
        sts = room.get('statues') or []
        if len(sts) >= MM.STATUES_MAX:
            raise ValueError(f'a room holds at most {MM.STATUES_MAX} statues')
        x, y = int(x), int(y)
        if y < 1:
            raise ValueError('a statue takes two cells — its pedestal here and the monster '
                             'above it: pick a cell below the top row')
        self._statue_cell_free(room, key, state_idx, x, y)
        tid, sheet = self._room_sheet(room, key, state_idx, x, y)
        thr = val(room['record']['collision_threshold'])
        tg, ag = self._writable_cell_grids(room, key, state_idx)
        mpix, mpal = self._cell_pixels(tg, ag, sheet, x, y - 1)
        ppix, ppal = self._cell_pixels(tg, ag, sheet, x, y)
        slot, g, note = self._statue_palette(room, key, state_idx, mpix, mpal, pal)
        rows = self._pal_rows(self.effective_palette(room, key, state_idx))
        ped = next((s2 for s2 in sts if s2.get('pedestal') and s2.get('palette') == slot), None)
        tiles = self._statue_slots_free(tid, thr)
        ptiles = None
        if ped is not None:
            ptiles = [val(t) for t in ped['pedestal']]
        else:
            ptiles = self._statue_slots_free(tid, thr, exclude=set(tiles))
        bg = self._remap_to(mpix, mpal, rows, slot, g)
        if rows is not None:
            off = sum(1 for yy in range(16) for xx in range(16)
                      if rows[mpal[yy][xx]][mpix[yy][xx]] != rows[slot][bg[yy][xx]])
            if off:
                note += (f'; {off} of the 256 background pixels above the pedestal show the '
                         'nearest colour (the cell drew colours one palette slot cannot '
                         'hold — e.g. two slots in one cell); touch them up in the Draw tab')
        for j, (ty, tx) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
            sheet[tiles[j] * 16:tiles[j] * 16 + 16] = _tile_bytes(bg, ty, tx)
        if ped is None:
            pp = self._remap_to(ppix, ppal, rows, slot, g)
            code = {'K': 3, 'C': 1, 'G': g}
            for yy, line in enumerate(PEDESTAL_ART):
                for xx, ch in enumerate(line):
                    if ch != '.':
                        pp[yy][xx] = code[ch]
            for j, (ty, tx) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
                sheet[ptiles[j] * 16:ptiles[j] * 16 + 16] = _tile_bytes(pp, ty, tx)
        self.write_sheet(tid, sheet)
        taken = {s2.get('id') for s2 in sts}
        n = len(sts) + 1
        sid = f'statue_{n}'
        while sid in taken:
            n += 1
            sid = f'statue_{n}'
        st = {'id': sid, 'tiles': [f'0x{t:02X}' for t in tiles],
              'shades': [1, g, 3], 'pedestal': [f'0x{t:02X}' for t in ptiles],
              'palette': slot}
        if name:
            st['name'] = str(name)
        room.setdefault('statues', []).append(st)
        self.add_metatile(tid, f'Statue {n}' + (f' ({name})' if name else '') + ' — monster',
                          tiles, slot, src='statue')
        if ped is None:
            self.add_metatile(tid, PEDESTAL_NAME, ptiles, slot)
        self._statue_paint(tg, ag, x, y - 1, tiles, slot)
        self._statue_paint(tg, ag, x, y, ptiles, slot)
        self.npc_entries(room, key, state_idx).append(
            {'kind': 'statue', 'x': x, 'y': y, 'statue': sid})
        self.last_statue_note = note
        self.touch()
        return sid

    def _statue_slots_free(self, tid, thr, exclude=()):
        """4 free slots of sheet `tid` for a statue cell: the BOTTOM-RIGHT one on the
        WALL side (it decides the cell's walkability — S94; a statue is solid), the
        other three anywhere free (`exclude` = slots just taken). Raises
        VocabReleaseWouldHelp when unused vocabulary would free enough (the editor
        asks, as the metatile import does), else RuntimeError."""
        from editor2.core.document import VocabReleaseWouldHelp
        used = self.used_tiles(tid) | set(exclude)
        free = [i for i in range(128) if i not in used]
        wall = [i for i in free if i < thr]
        if wall and len(free) >= 4:
            br = wall[-1]
            rest = [i for i in free if i != br]
            rest = sorted(rest, key=lambda i: (i >= thr, -i))[:3]
            return sorted(rest) + [br]
        spare = [i for i, u in enumerate(self.tile_usage(tid)) if u['status'] == 'vocab'
                 and i not in exclude]
        if spare and len(free) + len(spare) >= 4 and (wall or any(i < thr for i in spare)):
            raise VocabReleaseWouldHelp(
                f"The tileset {tid!r} is full of this room's vocabulary — {len(spare)} of "
                "those slots hold tiles no screen of the room uses (e.g. maze tiles of a "
                "gate theme). Release the unused vocabulary and add the statue?")
        raise RuntimeError(
            f"the room's tileset {tid!r} has {len(free)} free slots ({len(wall)} on the "
            "wall side) — a statue needs 4 for its monster (and 4 more for the room's "
            "pedestal the first time), the bottom-right one of each on the wall side (a "
            "statue is solid). Open the Tileset tab: delete unused metatiles or release "
            "vocabulary")

    def _statue_cell_free(self, room, key, state_idx, x, y):
        """The pedestal (x, y) and the monster cell (x, y - 1) must not be another
        spot or another statue's cells."""
        mine = {(int(x), int(y)), (int(x), int(y) - 1)}
        for e in self.npc_entries(room, key, state_idx):
            if e.get('kind') == 'statue':
                ex, ey = int(e['x']), int(e['y'])
                if mine & {(ex, ey), (ex, ey - 1)}:
                    raise ValueError(f'the statue on ({ex},{ey}) already takes cells '
                                     f'({ex},{ey - 1}) and ({ex},{ey})')
                continue
            v = self.npc_view(room, e)
            if v['kind'] in ('examine', 'step', 'spawn') and (v['x'], v['y']) == (int(x), int(y)):
                raise ValueError(f'cell ({x},{y}) already has an {v["kind"]} here')

    def place_statue(self, room, key, state_idx, x, y, sid, pal=None):
        """An EXISTING statue stands on (x, y) of this screen state too (the same
        monster wherever it stands — e.g. a later room state with more statues): its
        pedestal on (x, y), its monster cell above, in its palette slot."""
        s = self.statue(room, sid)
        if s is None:
            raise ValueError(f'no statue {sid!r} in this room')
        x, y = int(x), int(y)
        if y < 1:
            raise ValueError('a statue takes two cells: pick a cell below the top row')
        self._statue_cell_free(room, key, state_idx, x, y)
        slot = pal if pal is not None else s.get('palette')
        tg, ag = self._writable_cell_grids(room, key, state_idx)
        self._statue_paint(tg, ag, x, y - 1, [val(t) for t in s['tiles']], slot)
        if s.get('pedestal'):
            self._statue_paint(tg, ag, x, y, [val(t) for t in s['pedestal']], slot)
        self.npc_entries(room, key, state_idx).append(
            {'kind': 'statue', 'x': x, 'y': y, 'statue': sid})
        self.touch()
        return len(self.npc_entries(room, key, state_idx)) - 1

    def remove_statue_here(self, room, key, state_idx, index):
        """Take the statue entry `index` off this screen state (the cell keeps its
        tiles). The statue itself goes when it stands nowhere any more (its tiles
        stay in the sheet as the metatile 'Statue n')."""
        lst = self.npc_entries(room, key, state_idx)
        e = lst.pop(index)
        sid = e.get('statue')
        if sid and not self.statue_places(room, sid):
            room['statues'] = [s for s in room.get('statues') or [] if s.get('id') != sid]
            if not room['statues']:
                room.pop('statues')
        self.touch()
        return e

    def move_statue_order(self, room, sid, delta):
        """Statue `sid` earlier (-1) / later (+1) in the fill order."""
        sts = room.get('statues') or []
        i = next((k for k, s in enumerate(sts) if s.get('id') == sid), None)
        if i is None:
            return
        j = max(0, min(len(sts) - 1, i + delta))
        sts.insert(j, sts.pop(i))
        self.touch()

    def set_statue_words(self, room, sid, text=None, empty=None, own=True):
        """A statue's OWN words (boxes), or own=False: back to the project's."""
        s = self.statue(room, sid)
        if s is None:
            raise ValueError(f'no statue {sid!r}')
        for k, boxes in (('text', text), ('empty', empty)):
            did = f"{room['id']}_{sid}_{k}"
            if not own:
                s.pop(k, None)
                continue
            if boxes is not None:
                self._put_dialogue(did, boxes, f"S154: statue '{sid}' of {room['id']} ({k})")
                s[k] = did
        self.touch()

    def statue_words(self, room, sid):
        """{'text': boxes, 'empty': boxes, 'own': bool} for the statue panel."""
        s = self.statue(room, sid) or {}
        base = self.memorial_settings()
        out = {'own': bool(s.get('text') or s.get('empty'))}
        for k in ('text', 'empty'):
            d = self._dialogue_entry(s.get(k)) if s.get(k) else None
            out[k] = copy.deepcopy(d['boxes']) if d and d.get('boxes') else base[k]
        return out
