"""door_dialog.py — door objects and one-way teleports (S98, P3.7).

S98 r2: doors are placed with "Add door" (no dialog) and set up with
DoorPropsDialog (double-click: name + which door it connects to — no
coordinates). DoorDialog below is now the ONE-WAY TELEPORT dialog only.

Original S98 r1 notes:

A DOOR is two linked ends (editor2/core/doors.py): pick the other end —
a cell in any custom room (this one included: a staircase between screens)
or a vanilla door (it gets re-pointed, S94b redirects) — and the editor
writes both exit rows. Where the player appears is computed the vanilla way
(PyBoy S98): on the door cell (S98 r2, user choice; r1 stepped out half a
cell below interior doors), the vanilla partner's own bytes for
a vanilla door. The dialog shows both arrivals before anything is written.

A ONE-WAY TELEPORT (the rare object) arrives exactly on the chosen cell.
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QColor
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox,
                               QFormLayout, QGroupBox, QHBoxLayout, QLabel,
                               QSpinBox, QVBoxLayout)

from editor2.core.document import val
from editor2.core.doors import is_edge
from editor2.app.rooms.redirect_dialog import _Preview


class ClickPreview(_Preview):
    cellClicked = Signal(int, int)

    def mousePressEvent(self, ev):
        x, y = int(ev.position().x() // 32), int(ev.position().y() // 32)
        if 0 <= x <= 9 and 0 <= y <= 7:
            self.cellClicked.emit(x, y)


def vanilla_doors(rend, mid, scr):
    """Union of exit cells over a vanilla screen's valid states:
    [(x, y, label)] (the RedirectDialog list)."""
    seen, out = set(), []
    for st in range(len(rend.vanilla_steps(mid, scr))):
        _n, exits = rend.vanilla_markers(mid, scr, st)
        for e in exits:
            x, y = int(e['x']), int(e['y'])
            if (x, y) in seen:
                continue
            seen.add((x, y))
            ds = str(e['dest'])
            dmid = int(ds.split('$')[-1], 16) if '$' in ds else val(ds)
            try:
                dname = rend.vanilla_name(dmid)
            except Exception:
                dname = f'${dmid:02X}'
            kind = 'edge exit' if is_edge(x, y) else 'door'
            out.append((x, y, f'({x},{y}) {kind} → {dname}'))
    return out


def arrival_text(doc, end):
    try:
        sb, sx, sy = doc.default_arrival(end)
    except Exception as e:                       # pragma: no cover
        return f'? ({e})'
    k = sb & 0x0F
    if sb & 0x80:
        return (f'screen {k}, stepping out of the door at ({sx},{sy}) onto ({sx},{sy + 1}) '
                '— half a cell below the door, like the vanilla doors')
    if (sx, sy) == (end['x'], end['y']):
        return f'screen {k}, standing on the door cell ({sx},{sy})'
    return f'screen {k}, cell ({sx},{sy}) next to the door'


class DoorDialog(QDialog):
    def __init__(self, session, room_id, key, state_idx, cell, parent=None, teleport=False):
        super().__init__(parent)
        self.s = session
        self.doc = session.doc
        self.rend = session.renderer
        self.room = self.doc.room(room_id)
        self.room_id, self.key, self.state_idx = room_id, int(key), int(state_idx)
        self.cell = cell
        self.teleport = teleport
        cx, cy = cell
        self.setWindowTitle(('One-way teleport' if teleport else 'Add a door')
                            + f' at cell ({cx},{cy})')
        lay = QVBoxLayout(self)
        intro = QLabel(
            ('A one-way teleport: stepping on this cell sends the player to the cell you '
             'pick, exactly there. Nothing leads back (use a door for that).')
            if teleport else
            ('A door is two linked ends: stepping on this cell takes the player to the '
             'other end, and the other end leads back here. Pick the other end: a cell in '
             'any custom room, or a vanilla door (it will lead here instead of its old '
             'destination).'))
        intro.setWordWrap(True)
        lay.addWidget(intro)
        self.here_note = QLabel('')
        self.here_note.setWordWrap(True)
        lay.addWidget(self.here_note)

        g = QGroupBox('Destination' if teleport else 'Other end')
        f = QFormLayout(g)
        self.dst_room = QComboBox()
        for r in self.doc.rooms:
            if r.get('placeholder'):
                continue
            self.dst_room.addItem(f"${val(r['mapID']):02X}  {self.doc.room_name(r)}  (custom)",
                                  ('room', r['id']))
        self.dst_room.insertSeparator(self.dst_room.count())
        for mid, name, _scr in self.rend.vanilla_rooms():
            self.dst_room.addItem(f'${mid:02X}  {name}  (vanilla)', ('vanilla', mid))
        self.dst_screen = QComboBox()
        self.dst_door = QComboBox()
        self.dst_x = QSpinBox(); self.dst_x.setRange(0, 9)
        self.dst_y = QSpinBox(); self.dst_y.setRange(0, 7)
        f.addRow('room', self.dst_room)
        f.addRow('screen', self.dst_screen)
        f.addRow('vanilla door', self.dst_door)
        f.addRow('cell x', self.dst_x)
        f.addRow('cell y', self.dst_y)
        self.prev = ClickPreview()
        self.prev.setToolTip('Click a cell to pick it')
        self.prev.cellClicked.connect(self._clicked)
        f.addRow(self.prev)
        lay.addWidget(g)
        self.arrive = QLabel('')
        self.arrive.setWordWrap(True)
        self.arrive.setStyleSheet('color:#80d080;')
        lay.addWidget(self.arrive)
        self.warn = QLabel('')
        self.warn.setWordWrap(True)
        self.warn.setStyleSheet('color:#e0b040;')
        lay.addWidget(self.warn)
        self.all_states = QCheckBox('in every state of this screen (untick: only the state '
                                    'on screen — change it later in the door panel)')
        self.all_states.setChecked(True)
        if len(self.doc.states(self.room, self.key)) > 1:
            lay.addWidget(self.all_states)
        self.bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        self.bb.accepted.connect(self.accept)
        self.bb.rejected.connect(self.reject)
        lay.addWidget(self.bb)

        self.dst_room.currentIndexChanged.connect(self._room_changed)
        self.dst_screen.currentIndexChanged.connect(self._screen_changed)
        self.dst_door.currentIndexChanged.connect(self._door_changed)
        self.dst_x.valueChanged.connect(self._refresh)
        self.dst_y.valueChanged.connect(self._refresh)
        # default: this room (a staircase / a door between its screens)
        for k in range(self.dst_room.count()):
            if self.dst_room.itemData(k) == ('room', room_id):
                self.dst_room.setCurrentIndex(k)
                break
        self._room_changed()

    # ------------------------------------------------------------ values
    def _dest(self):
        return self.dst_room.currentData()

    def _room_changed(self):
        d = self._dest()
        if d is None:
            return
        self.dst_screen.blockSignals(True)
        self.dst_screen.clear()
        if d[0] == 'room':
            keys = self.doc.screen_keys(self.doc.room(d[1]))
        else:
            keys = next(sc for m, _n, sc in self.rend.vanilla_rooms() if m == d[1])
        for k in keys:
            self.dst_screen.addItem(f'screen {k}  (col {k % 4}, row {k // 4})', k)
        self.dst_screen.blockSignals(False)
        self._screen_changed()

    def _screen_changed(self):
        d, k = self._dest(), self.dst_screen.currentData()
        if d is None or k is None:
            return
        self.dst_door.blockSignals(True)
        self.dst_door.clear()
        if d[0] == 'vanilla':
            for x, y, label in vanilla_doors(self.rend, d[1], k):
                self.dst_door.addItem(label, (x, y))
            self.dst_door.addItem('any cell (a new door where none exists)', None)
        self.dst_door.setEnabled(d[0] == 'vanilla')
        self.dst_door.blockSignals(False)
        if d[0] == 'vanilla' and self.dst_door.count() > 1:
            self._door_changed()
        self._refresh()

    def _door_changed(self):
        cxy = self.dst_door.currentData()
        if cxy is None:
            return
        for w, v in ((self.dst_x, cxy[0]), (self.dst_y, cxy[1])):
            w.blockSignals(True)
            w.setValue(v)
            w.blockSignals(False)
        self._refresh()

    def _clicked(self, x, y):
        for w, v in ((self.dst_x, x), (self.dst_y, y)):
            w.blockSignals(True)
            w.setValue(v)
            w.blockSignals(False)
        d = self._dest()
        if d and d[0] == 'vanilla':
            i = self.dst_door.count() - 1
            for k in range(self.dst_door.count()):
                if self.dst_door.itemData(k) == (x, y):
                    i = k
            self.dst_door.blockSignals(True)
            self.dst_door.setCurrentIndex(i)
            self.dst_door.blockSignals(False)
        self._refresh()

    def _ends(self):
        d, k = self._dest(), self.dst_screen.currentData()
        here = {'kind': 'room', 'room': self.room_id, 'screen': self.key,
                'x': self.cell[0], 'y': self.cell[1]}
        if d is None or k is None:
            return here, None
        x, y = self.dst_x.value(), self.dst_y.value()
        if d[0] == 'room':
            there = {'kind': 'room', 'room': d[1], 'screen': int(k), 'x': x, 'y': y}
        else:
            there = {'kind': 'vanilla', 'mapID': int(d[1]), 'screen': int(k), 'x': x, 'y': y}
        return here, there

    def _refresh(self):
        here, there = self._ends()
        if there is None:
            return
        x, y = there['x'], there['y']
        img, walk = None, None
        boxes = []
        try:
            if there['kind'] == 'room':
                room = self.doc.room(there['room'])
                img = self.rend.render_screen(room, there['screen'], 0, 1)
                st = self.rend.screen_state(room, there['screen'], 0)
                grid, _lid = self.rend.layout_grid(st['layout'])
                thr = self.rend.room_gfx(room).threshold
            else:
                img = self.rend.render_vanilla_screen(there['mapID'], there['screen'], 1, 0)
                grid = self.rend.vanilla_screen_grid(there['mapID'], there['screen'], 0)
                thr = self.rend.vanilla_gfx(there['mapID']).threshold
                boxes = [(dx, dy, QColor(255, 70, 70), 'E')
                         for dx, dy, _l in vanilla_doors(self.rend, there['mapID'], there['screen'])]

            def walk(cx, cy):
                return 0 <= cx <= 9 and 0 <= cy <= 7 and grid[cy * 2 + 1][cx * 2 + 1] >= thr
        except Exception:
            pass
        self.prev.set_image(img)
        warn, block = [], False
        # this end
        here_notes = []
        if is_edge(*self.cell):
            here_notes.append('This cell is on the screen EDGE: the exit fires when the player '
                              'walks onto it (bottom row) or pushes into the edge.')
        c = self.doc.edge_conflict(self.room, self.key, *self.cell)
        if c and c[0] != 'bottom':
            warn.append(f'This {c[0]} edge scrolls into screen {c[1]} — an exit here would '
                        'NEVER fire (PyBoy S98). Pick a cell off that edge.')
            block = True
        elif c:
            here_notes.append(f'Note: screen {c[1]} lies below — the player can never walk down '
                              'into it through this cell (the exit fires first).')
        own = self.doc.door_end_at(self.room_id, self.key, *self.cell)
        if own and not self.teleport:
            warn.append(f'This cell is already an end of {own[0]["id"]} — delete that door first.')
            block = True
        self.here_note.setText(' '.join(here_notes))
        if self.teleport:
            boxes.append((x, y, QColor(120, 255, 120), 'IN'))
            self.arrive.setText(f'The player arrives on screen {there["screen"]} cell ({x},{y}).')
            if walk and not walk(x, y):
                warn.append(f'Cell ({x},{y}) is a WALL — the player would arrive stuck.')
        else:
            if there['kind'] == 'room' and there['room'] == self.room_id and \
                    (there['screen'], x, y) == (self.key, *self.cell):
                warn.append('The other end cannot be this same cell.')
                block = True
            if there['kind'] == 'room':
                oroom = self.doc.room(there['room'])
                c2 = self.doc.edge_conflict(oroom, there['screen'], x, y)
                if c2 and c2[0] != 'bottom':
                    warn.append(f'The other end sits on a {c2[0]} edge that scrolls into screen '
                                f'{c2[1]} — it would never fire.')
                    block = True
                other = self.doc.door_end_at(there['room'], there['screen'], x, y)
                if other:
                    warn.append(f'Cell ({x},{y}) there is already an end of {other[0]["id"]}.')
                    block = True
            boxes.append((x, y, QColor(0, 220, 255), 'D'))
            try:
                sb, sx, sy = self.doc.default_arrival(there)
                ax, ay = (sx, sy + 1) if sb & 0x80 else (sx, sy)
                if (ax, ay) != (x, y):
                    boxes.append((ax, ay, QColor(120, 255, 120), 'IN'))
                if walk and not walk(ax, ay):
                    warn.append(f'Arrival cell ({ax},{ay}) there is a WALL — the player '
                                'would be stuck. Make it walkable or move the door.')
            except Exception:
                pass
            self.arrive.setText('Through this door the player arrives on '
                                + arrival_text(self.doc, there)
                                + '.\nComing back, he arrives here on '
                                + arrival_text(self.doc, here) + '.')
        self.prev.set_boxes(boxes)
        self.warn.setText('\n'.join(warn))
        self.bb.button(QDialogButtonBox.Ok).setEnabled(not block)

    # ------------------------------------------------------------ result
    def values(self):
        here, there = self._ends()
        return {'here': here, 'there': there,
                'states': None if self.all_states.isChecked() else [self.state_idx]}

    def door_specs(self):
        """(a, b, a_states) for Document.add_door."""
        v = self.values()
        a = {'room': self.room_id, 'screen': self.key, 'x': self.cell[0], 'y': self.cell[1]}
        t = v['there']
        b = ({'room': t['room'], 'screen': t['screen'], 'x': t['x'], 'y': t['y']}
             if t['kind'] == 'room' else
             {'vanilla': t['mapID'], 'screen': t['screen'], 'x': t['x'], 'y': t['y']})
        return a, b, v['states']

    def teleport_values(self):
        """kwargs for Document.add_teleport (dest, dest_screen, spawn)."""
        t = self._ends()[1]
        dest = (f"room:${val(self.doc.room(t['room'])['mapID']):02X}" if t['kind'] == 'room'
                else f"vanilla:${t['mapID']:02X}")
        n = len(self.doc.states(self.room, self.key))
        return dict(x=self.cell[0], y=self.cell[1], dest=dest, dest_screen=t['screen'],
                    spawn_x=t['x'], spawn_y=t['y'],
                    states=list(range(n)) if self.all_states.isChecked() else [self.state_idx])


# ---------------------------------------------------------------- S98 r2
# The door OBJECT dialog (user design: "click on a cell, then click 'add
# door', the door appears on that cell. Then you double-click on the door to
# set its params … namable and connected to another door object"). Nothing
# here asks for coordinates: the door's own cell is where it was placed
# (drag to move), and the other side is picked as a DOOR from a list.

_VANILLA_DOOR_CACHE = {}


def vanilla_door_list(rend):
    """[(mid, room name, [(screen, x, y, label)])] — every vanilla door
    (exit cell), the second cell of a double door folded into the first."""
    key = id(rend)
    if key in _VANILLA_DOOR_CACHE:
        return _VANILLA_DOOR_CACHE[key]
    out = []
    for mid, name, screens in rend.vanilla_rooms():
        doors = []
        for k in screens:
            try:
                cells = vanilla_doors(rend, mid, k)
            except Exception:
                continue
            by = {(x, y): lab for x, y, lab in cells}
            for x, y, lab in cells:
                dest = lab.split('→')[-1]
                if (x - 1, y) in by and by[(x - 1, y)].split('→')[-1] == dest:
                    continue                      # right half of a double door
                double = (x + 1, y) in by and by[(x + 1, y)].split('→')[-1] == dest
                doors.append((k, x, y, f"screen {k} {lab}" + ('  (double door)' if double else '')))
        if doors:
            out.append((mid, name, doors))
    _VANILLA_DOOR_CACHE[key] = out
    return out


def end_place(doc, end):
    """'Door Lab — screen 0 (4,7)' / 'GreatTree — screen 8 door (5,3)'."""
    if end is None:
        return '—'
    if end['kind'] == 'room':
        try:
            r = doc.room(end['room'])
            return f"{doc.room_name(r)} — screen {end['screen']} ({end['x']},{end['y']})"
        except KeyError:
            return f"missing room {end['room']}"
    return doc.vanilla_door_name(end['mapID'], end['screen'], end['x'], end['y'])


class DoorPropsDialog(QDialog):
    """Name + connection (+ states) of one door object. result() ->
    {'name', 'link' (door id or None), 'states' (list or None)}."""

    def __init__(self, session, door_id, parent=None):
        from PySide6.QtWidgets import (QLineEdit, QTreeWidget, QTreeWidgetItem,
                                       QSplitter, QWidget)
        super().__init__(parent)
        self.s, self.doc, self.rend = session, session.doc, session.renderer
        self.did = door_id
        self.me = self.doc.door_end(door_id)
        me = self.me
        self.vanilla = me['kind'] == 'vanilla'
        self.setWindowTitle(f"Door — {me['name']}")
        self.resize(900, 560)
        lay = QVBoxLayout(self)
        form = QFormLayout()
        self.name = QLineEdit(me['name'])
        self.name.setEnabled(not self.vanilla)
        if self.vanilla:
            self.name.setToolTip('Vanilla doors are named after their room')
        form.addRow('Name', self.name)
        form.addRow('This door', QLabel(end_place(self.doc, me)
                                        + ('' if self.vanilla else '   (drag it on the canvas to move it)')))
        self.state_boxes = []
        if not self.vanilla:
            room = self.doc.room(me['room'])
            n_st = len(self.doc.states(room, me['screen']))
            if n_st > 1:
                row = QHBoxLayout()
                for n in range(n_st):
                    cb = QCheckBox(str(n))
                    cb.setChecked(n in me['states'])
                    cb.setToolTip(f'the door exists in state {n} of this screen')
                    cb.toggled.connect(lambda _v: self._refresh())
                    row.addWidget(cb)
                    self.state_boxes.append(cb)
                row.addStretch(1)
                form.addRow('In states', row)
        lay.addLayout(form)

        split = QSplitter()
        left = QWidget()
        lv = QVBoxLayout(left)
        lv.setContentsMargins(0, 0, 0, 0)
        lv.addWidget(QLabel('Connected to (two-way):'))
        self.filter = QLineEdit()
        self.filter.setPlaceholderText('search doors / rooms…')
        self.filter.textChanged.connect(self._apply_filter)
        lv.addWidget(self.filter)
        self.tree = QTreeWidget()
        self.tree.setHeaderHidden(True)
        lv.addWidget(self.tree, 1)
        split.addWidget(left)
        right = QWidget()
        rv = QVBoxLayout(right)
        rv.setContentsMargins(0, 0, 0, 0)
        self.prev = _Preview()
        rv.addWidget(self.prev)
        self.info = QLabel('')
        self.info.setWordWrap(True)
        self.info.setStyleSheet('color:#80d080;')
        rv.addWidget(self.info)
        self.warn = QLabel('')
        self.warn.setWordWrap(True)
        self.warn.setStyleSheet('color:#e0b040;')
        rv.addWidget(self.warn)
        rv.addStretch(1)
        split.addWidget(right)
        split.setSizes([480, 340])
        lay.addWidget(split, 1)
        self.bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        self.bb.accepted.connect(self.accept)
        self.bb.rejected.connect(self.reject)
        lay.addWidget(self.bb)

        # ---- the list
        cur = me.get('link')
        none = QTreeWidgetItem(['— not connected —'])
        none.setData(0, Qt.UserRole, ('none', None))
        self.tree.addTopLevelItem(none)
        select = none
        mine = QTreeWidgetItem(['Your doors'])
        mine.setFlags(mine.flags() & ~Qt.ItemIsSelectable)
        self.tree.addTopLevelItem(mine)
        for end in self.doc.custom_doors():
            if end['id'] == door_id:
                continue
            p = self.doc.door_partner(end['id'])
            tag = ''
            if p is not None and p['id'] != door_id:
                tag = f"   [now ↔ {p['name']}]"
            elif p is None:
                tag = '   [not connected]'
            it = QTreeWidgetItem([f"{end['name']} — {end_place(self.doc, end)}{tag}"])
            it.setData(0, Qt.UserRole, ('door', end['id']))
            mine.addChild(it)
            if end['id'] == cur:
                select = it
        if mine.childCount() == 0:
            ph = QTreeWidgetItem(['(no other doors yet — add one in another room, or pick a '
                                  'vanilla door below)'])
            ph.setFlags(Qt.NoItemFlags)
            mine.addChild(ph)
        mine.setExpanded(True)
        if not self.vanilla:
            van = QTreeWidgetItem(['Vanilla doors (the vanilla door will lead here instead)'])
            van.setFlags(van.flags() & ~Qt.ItemIsSelectable)
            self.tree.addTopLevelItem(van)
            for mid, name, doors in vanilla_door_list(self.rend):
                ri = QTreeWidgetItem([f'${mid:02X} {name}'])
                ri.setFlags(ri.flags() & ~Qt.ItemIsSelectable)
                van.addChild(ri)
                for k, x, y, lab in doors:
                    vid = self.doc.vanilla_door_id(mid, k, x, y)
                    p = self.doc.door_partner(vid)
                    tag = f"   [now ↔ {p['name']}]" if p and p['id'] != door_id else ''
                    it = QTreeWidgetItem([lab + tag])
                    it.setData(0, Qt.UserRole, ('door', vid))
                    ri.addChild(it)
                    if vid == cur:
                        select = it
                        ri.setExpanded(True)
                        van.setExpanded(True)
        self.tree.currentItemChanged.connect(lambda *_a: self._refresh())
        self.tree.setCurrentItem(select)
        self._refresh()

    def _apply_filter(self, text):
        t = text.strip().lower()

        def walk(item, parent_hit=False):
            me = (not t) or parent_hit or t in item.text(0).lower()
            vis_child = False
            for i in range(item.childCount()):
                vis_child |= walk(item.child(i), me and bool(t) and item.parent() is not None)
            show = me or vis_child
            item.setHidden(not show)
            if t and vis_child:
                item.setExpanded(True)
            return show
        for i in range(self.tree.topLevelItemCount()):
            walk(self.tree.topLevelItem(i))

    def _target(self):
        it = self.tree.currentItem()
        d = it.data(0, Qt.UserRole) if it else None
        return d[1] if d and d[0] == 'door' else None

    def _refresh(self):
        tid = self._target()
        warn = []
        if tid is None:
            self.prev.set_image(None)
            self.prev.set_boxes([])
            self.info.setText('Not connected: the door does nothing in game until you connect '
                              'it to another door.')
        else:
            t = self.doc.door_end(tid)
            img, boxes = None, [(t['x'], t['y'], QColor(0, 220, 255), 'D')]
            try:
                if t['kind'] == 'room':
                    room = self.doc.room(t['room'])
                    img = self.rend.render_screen(room, t['screen'],
                                                  (t.get('states') or [0])[0], 1)
                else:
                    img = self.rend.render_vanilla_screen(t['mapID'], t['screen'], 1, 0)
                sb, sx, sy = self.doc.default_arrival(t)
                ax, ay = (sx, sy + 1) if sb & 0x80 else (sx, sy)
                if (ax, ay) != (t['x'], t['y']) and (sb & 0x0F) == t['screen']:
                    boxes.append((ax, ay, QColor(120, 255, 120), 'IN'))
            except Exception:
                pass
            self.prev.set_image(img)
            self.prev.set_boxes(boxes)
            self.info.setText('Walking through this door, the player arrives at '
                              f"'{t['name']}': " + arrival_text(self.doc, t)
                              + '.\nComing back, he arrives here: '
                              + arrival_text(self.doc, self.me) + '.')
            p = self.doc.door_partner(tid)
            if p is not None and p['id'] != self.did:
                warn.append(f"'{t['name']}' is connected to '{p['name']}' now — "
                            f"'{p['name']}' becomes unconnected.")
            old = self.doc.door_partner(self.did)
            if old is not None and old['id'] != tid:
                warn.append(f"'{old['name']}' (connected now) becomes unconnected.")
            if t['kind'] == 'room':
                c = self.doc.edge_conflict(self.doc.room(t['room']), t['screen'], t['x'], t['y'])
                if c and c[0] != 'bottom':
                    warn.append(f"'{t['name']}' sits on a {c[0]} edge that scrolls into screen "
                                f"{c[1]} — it will never fire there (move it off the edge).")
        if not self.vanilla:
            c = self.doc.edge_conflict(self.doc.room(self.me['room']), self.me['screen'],
                                       self.me['x'], self.me['y'])
            if c and c[0] != 'bottom':
                warn.append(f"This door sits on a {c[0]} edge that scrolls into screen {c[1]} — "
                            'it will never fire (drag it off the edge).')
        self.warn.setText('\n'.join(warn))
        ok = True
        if self.state_boxes and not any(cb.isChecked() for cb in self.state_boxes):
            ok = False
        if self.vanilla and tid is not None and self.doc.door_end(tid)['kind'] == 'vanilla':
            ok = False
        self.bb.button(QDialogButtonBox.Ok).setEnabled(ok)

    def result_values(self):
        return {'name': self.name.text().strip() or self.me['name'],
                'link': self._target(),
                'states': ([n for n, cb in enumerate(self.state_boxes) if cb.isChecked()]
                           if self.state_boxes else None)}
