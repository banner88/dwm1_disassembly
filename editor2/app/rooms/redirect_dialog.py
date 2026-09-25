"""redirect_dialog.py — "Route a vanilla door here" (S94b, entrance redirects).

The fastest way to test a custom room in-game is to hook it onto a door the
player already walks through (user, S94: "make Library entrance new custom
room entry"). The dialog picks ONE vanilla door — room → screen → exit
cell — and where the player lands in the custom room (screen + cell).
It writes `custom.entrance_redirects[]`; the compiler rebuilds that
(room, screen)'s exit list per vanilla state with just that door
re-pointed (project.py `_lower_entrance_redirects`).

Left: the vanilla screen with its exits outlined; the chosen door is
highlighted. Right: the destination screen with the arrival cell.
"""

from PySide6.QtCore import Qt
from PySide6.QtGui import QColor, QImage, QPainter, QPen, QPixmap
from PySide6.QtWidgets import (QComboBox, QDialog, QDialogButtonBox,
                               QFormLayout, QGridLayout, QGroupBox, QLabel,
                               QSpinBox, QVBoxLayout)
from PIL import ImageQt

from editor2.core.document import val

CELL = 16


class _Preview(QLabel):
    """A 2× screen render with cell outlines (exits red, chosen magenta,
    arrival green)."""

    def __init__(self):
        super().__init__()
        self.setFixedSize(320, 256)
        self.setStyleSheet('background:#202020;')
        self.img = None
        self.boxes = []          # (x, y, QColor, text)

    def set_image(self, pil_img):
        self.img = pil_img
        self.update()

    def set_boxes(self, boxes):
        self.boxes = boxes
        self.update()

    def paintEvent(self, ev):
        super().paintEvent(ev)
        if self.img is None:
            return
        p = QPainter(self)
        qimg = ImageQt.ImageQt(self.img.convert('RGB'))
        p.drawPixmap(0, 0, QPixmap.fromImage(qimg).scaled(320, 256))
        for x, y, col, text in self.boxes:
            pen = QPen(col)
            pen.setWidth(2)
            p.setPen(pen)
            p.drawRect(x * 32 + 1, y * 32 + 1, 30, 30)
            p.drawText(x * 32 + 4, y * 32 + 12, text)
        p.end()


class RedirectDialog(QDialog):
    def __init__(self, session, room_id, parent=None, preset=None):
        super().__init__(parent)
        self.s = session
        self.room_id = room_id
        self.setWindowTitle('Route a vanilla door into this room')
        self.rend = session.renderer
        room = session.doc.room(room_id)
        self.room = room
        self._building = True

        lay = QVBoxLayout(self)
        intro = QLabel(
            f'Pick a vanilla door; the player walking through it will arrive in '
            f'"{session.doc.room_name(room)}" instead. The other doors of that '
            'vanilla screen keep their normal destinations in every room state.')
        intro.setWordWrap(True)
        lay.addWidget(intro)

        grid = QGridLayout()
        lay.addLayout(grid)

        # ---- source (vanilla door)
        g = QGroupBox('Vanilla door (source)')
        f = QFormLayout(g)
        self.src_room = QComboBox()
        for mid, name, _screens in self.rend.vanilla_rooms():
            self.src_room.addItem(f'${mid:02X}  {name}', mid)
        self.src_screen = QComboBox()
        self.src_door = QComboBox()
        self.src_x = QSpinBox(); self.src_x.setRange(0, 9)
        self.src_y = QSpinBox(); self.src_y.setRange(0, 7)
        f.addRow('room', self.src_room)
        f.addRow('screen', self.src_screen)
        f.addRow('door', self.src_door)
        f.addRow('door cell x', self.src_x)
        f.addRow('door cell y', self.src_y)
        self.src_prev = _Preview()
        f.addRow(self.src_prev)
        grid.addWidget(g, 0, 0)

        # ---- destination (this room)
        g = QGroupBox(f'Arrival in "{session.doc.room_name(room)}"')
        f = QFormLayout(g)
        self.dst_screen = QComboBox()
        for k in session.doc.screen_keys(room):
            self.dst_screen.addItem(f'screen {k}  (col {k % 4}, row {k // 4})', k)
        self.dst_x = QSpinBox(); self.dst_x.setRange(0, 9)
        self.dst_y = QSpinBox(); self.dst_y.setRange(0, 7)
        f.addRow('screen', self.dst_screen)
        f.addRow('arrive at cell x', self.dst_x)
        f.addRow('arrive at cell y', self.dst_y)
        self.dst_prev = _Preview()
        f.addRow(self.dst_prev)
        self.dst_note = QLabel('')
        self.dst_note.setWordWrap(True)
        self.dst_note.setStyleSheet('color:#e0b040;')
        f.addRow(self.dst_note)
        grid.addWidget(g, 0, 1)

        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        lay.addWidget(bb)

        self.src_room.currentIndexChanged.connect(self._room_changed)
        self.src_screen.currentIndexChanged.connect(self._screen_changed)
        self.src_door.currentIndexChanged.connect(self._door_changed)
        for w in (self.src_x, self.src_y):
            w.valueChanged.connect(self._src_cell_changed)
        self.dst_screen.currentIndexChanged.connect(self._dst_changed)
        for w in (self.dst_x, self.dst_y):
            w.valueChanged.connect(self._dst_changed)

        # default: GreatTree 2F Library door — the door every save can reach
        preset = preset or {'mapID': 0x01, 'screen': 8, 'x': 5, 'y': 3}
        i = self.src_room.findData(val(preset['mapID']))
        self.src_room.setCurrentIndex(max(i, 0))
        self._building = False
        self._room_changed()
        i = self.src_screen.findData(val(preset['screen']))
        if i >= 0:
            self.src_screen.setCurrentIndex(i)
        self.src_x.setValue(val(preset['x']))
        self.src_y.setValue(val(preset['y']))
        self._src_cell_changed()
        # arrival default: the room's spawn marker on the first screen
        spawn = self._room_spawn()
        if spawn:
            k, x, y = spawn
            j = self.dst_screen.findData(k)
            if j >= 0:
                self.dst_screen.setCurrentIndex(j)
            self.dst_x.setValue(x)
            self.dst_y.setValue(y)
        self._dst_changed()

    # ---------------------------------------------------------------- source
    def _mid(self):
        return self.src_room.currentData()

    def _scr(self):
        return self.src_screen.currentData()

    def _room_changed(self):
        if self._building:
            return
        mid = self._mid()
        screens = next(s for m, _n, s in self.rend.vanilla_rooms() if m == mid)
        self.src_screen.blockSignals(True)
        self.src_screen.clear()
        for k in screens:
            self.src_screen.addItem(f'screen {k}  (col {k % 4}, row {k // 4})', k)
        self.src_screen.blockSignals(False)
        self._screen_changed()

    def _doors(self):
        """Union of exit cells over the screen's valid states: [(x, y, label)]."""
        mid, scr = self._mid(), self._scr()
        seen, out = set(), []
        for st in range(len(self.rend.vanilla_steps(mid, scr))):
            _n, exits = self.rend.vanilla_markers(mid, scr, st)
            for e in exits:
                x, y = int(e['x']), int(e['y'])
                if (x, y) in seen:
                    continue
                seen.add((x, y))
                dmid = val(e['dest'].split(':')[1]) if ':' in str(e['dest']) else val(e['dest'])
                try:
                    dname = self.rend.vanilla_name(dmid)
                except Exception:
                    dname = f'${dmid:02X}'
                kind = 'edge exit' if y in (0, 7) or x in (0, 9) else 'door'
                out.append((x, y, f'({x},{y}) {kind} → {dname}'))
        return out

    def _screen_changed(self):
        if self._building or self._scr() is None:
            return
        self.src_door.blockSignals(True)
        self.src_door.clear()
        for x, y, label in self._doors():
            self.src_door.addItem(label, (x, y))
        self.src_door.addItem('custom cell (new door where none exists)', None)
        self.src_door.blockSignals(False)
        if self.src_door.count() > 1:
            self.src_door.setCurrentIndex(0)
        self._door_changed()
        try:
            self.src_prev.set_image(self.rend.render_vanilla_screen(self._mid(), self._scr(), 1, 0))
        except Exception:
            self.src_prev.set_image(None)
        self._src_cell_changed()

    def _door_changed(self):
        d = self.src_door.currentData()
        if d is None:
            return
        self.src_x.blockSignals(True); self.src_y.blockSignals(True)
        self.src_x.setValue(d[0]); self.src_y.setValue(d[1])
        self.src_x.blockSignals(False); self.src_y.blockSignals(False)
        self._src_cell_changed()

    def _src_cell_changed(self):
        x, y = self.src_x.value(), self.src_y.value()
        i = self.src_door.count() - 1          # 'custom cell'
        for k in range(self.src_door.count()):   # findData() can't compare tuples
            if self.src_door.itemData(k) == (x, y):
                i = k
                break
        if self.src_door.currentIndex() != i:
            self.src_door.blockSignals(True)
            self.src_door.setCurrentIndex(i)
            self.src_door.blockSignals(False)
        boxes = [(dx, dy, QColor(255, 70, 70), 'E') for dx, dy, _l in self._doors()]
        boxes.append((x, y, QColor(255, 0, 255), 'R'))
        self.src_prev.set_boxes(boxes)

    # ----------------------------------------------------------- destination
    def _room_spawn(self):
        for k in self.s.doc.screen_keys(self.room):
            for st in self.s.doc.states(self.room, k):
                for e in st.get('npcs', []):
                    if e.get('kind') == 'spawn':
                        return k, int(e['x']), int(e['y'])
                    if e.get('kind') == 'raw' and val(e['bytes'][0]) == 0x8F:
                        return k, val(e['bytes'][2]), val(e['bytes'][3])
        return None

    def _dst_changed(self):
        k = self.dst_screen.currentData()
        if k is None:
            return
        try:
            self.dst_prev.set_image(self.rend.render_screen(self.room, k, 0, 1))
        except Exception:
            self.dst_prev.set_image(None)
        x, y = self.dst_x.value(), self.dst_y.value()
        self.dst_prev.set_boxes([(x, y, QColor(120, 255, 120), 'IN')])
        # walkability hint (bottom-right subtile rule, S94)
        note = ''
        try:
            st = self.rend.screen_state(self.room, k, 0)
            grid, _lid = self.rend.layout_grid(st['layout'])
            gfx = self.rend.room_gfx(self.room)
            t = grid[y * 2 + 1][x * 2 + 1]
            if t < gfx.threshold:
                note = (f'Cell ({x},{y}) is a WALL (subtile ${t:02X} < ${gfx.threshold:02X}) '
                        '— the player would arrive inside it and be stuck. Pick a walkable cell.')
        except Exception:
            pass
        self.dst_note.setText(note)

    # ---------------------------------------------------------------- result
    def values(self):
        return dict(source_mid=self._mid(), screen=self._scr(),
                    x=self.src_x.value(), y=self.src_y.value(),
                    dest_screen=self.dst_screen.currentData(),
                    spawn_x=self.dst_x.value(), spawn_y=self.dst_y.value())


class ExitDialog(QDialog):
    """S95 — "Add exit at this cell": the custom-room half of routing. Picks
    the destination (custom room → screen → arrival cell, or a vanilla room)
    for a walk-on/edge exit at (cx, cy) of the current screen/state. Writes
    an ordinary `exits[]` row (dest room:/vanilla:, screen_byte, spawn)."""

    def __init__(self, session, room_id, key, cell, parent=None):
        super().__init__(parent)
        self.s = session
        self.rend = session.renderer
        self.room = session.doc.room(room_id)
        self.cell = cell
        cx, cy = cell
        edge = cy in (0, 7) or cx in (0, 9)
        self.setWindowTitle(f'Add exit at cell ({cx},{cy})')
        lay = QVBoxLayout(self)
        note = QLabel(
            (f'Cell ({cx},{cy}) is on the screen EDGE: the exit fires when the player '
             'pushes into that edge (row 7 also fires on arrival in custom rooms). '
             'An edge exit cannot share its edge with a scroll to a neighbouring screen.')
            if edge else
            f'Cell ({cx},{cy}) is interior: the exit fires when the player steps onto it '
            '(a doorway / staircase cell).')
        note.setWordWrap(True)
        lay.addWidget(note)
        g = QGroupBox('Destination')
        f = QFormLayout(g)
        self.dst_room = QComboBox()
        for r in session.doc.rooms:
            if r.get('placeholder'):
                continue
            self.dst_room.addItem(f"${val(r['mapID']):02X}  {session.doc.room_name(r)}  (custom)",
                                  ('room', r['id']))
        self.dst_room.insertSeparator(self.dst_room.count())
        for mid, name, _scr in self.rend.vanilla_rooms():
            self.dst_room.addItem(f'${mid:02X}  {name}  (vanilla)', ('vanilla', mid))
        self.dst_screen = QComboBox()
        self.dst_x = QSpinBox(); self.dst_x.setRange(0, 9)
        self.dst_y = QSpinBox(); self.dst_y.setRange(0, 7)
        f.addRow('room', self.dst_room)
        f.addRow('screen', self.dst_screen)
        f.addRow('arrive at cell x', self.dst_x)
        f.addRow('arrive at cell y', self.dst_y)
        self.prev = _Preview()
        f.addRow(self.prev)
        self.warn = QLabel('')
        self.warn.setWordWrap(True)
        self.warn.setStyleSheet('color:#e0b040;')
        f.addRow(self.warn)
        lay.addWidget(g)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        lay.addWidget(bb)
        self.dst_room.currentIndexChanged.connect(self._room_changed)
        self.dst_screen.currentIndexChanged.connect(self._refresh)
        self.dst_x.valueChanged.connect(self._refresh)
        self.dst_y.valueChanged.connect(self._refresh)
        # default: this very room (a staircase to another screen of it)
        i = self.dst_room.findData(('room', room_id))
        for k in range(self.dst_room.count()):
            if self.dst_room.itemData(k) == ('room', room_id):
                i = k
                break
        self.dst_room.setCurrentIndex(max(i, 0))
        self._room_changed()

    def _dest(self):
        return self.dst_room.currentData()

    def _room_changed(self):
        d = self._dest()
        self.dst_screen.blockSignals(True)
        self.dst_screen.clear()
        if d is None:
            self.dst_screen.blockSignals(False)
            return
        if d[0] == 'room':
            keys = self.s.doc.screen_keys(self.s.doc.room(d[1]))
        else:
            keys = next(sc for m, _n, sc in self.rend.vanilla_rooms() if m == d[1])
        for k in keys:
            self.dst_screen.addItem(f'screen {k}  (col {k % 4}, row {k // 4})', k)
        self.dst_screen.blockSignals(False)
        self._refresh()

    def _refresh(self):
        d, k = self._dest(), self.dst_screen.currentData()
        if d is None or k is None:
            return
        x, y = self.dst_x.value(), self.dst_y.value()
        img = None
        wall = None
        try:
            if d[0] == 'room':
                room = self.s.doc.room(d[1])
                img = self.rend.render_screen(room, k, 0, 1)
                st = self.rend.screen_state(room, k, 0)
                grid, _lid = self.rend.layout_grid(st['layout'])
                wall = grid[y * 2 + 1][x * 2 + 1] < self.rend.room_gfx(room).threshold
            else:
                img = self.rend.render_vanilla_screen(d[1], k, 1, 0)
                grid = self.rend.vanilla_screen_grid(d[1], k, 0)
                wall = grid[y * 2 + 1][x * 2 + 1] < self.rend.vanilla_gfx(d[1]).threshold
        except Exception:
            pass
        self.prev.set_image(img)
        self.prev.set_boxes([(x, y, QColor(120, 255, 120), 'IN')])
        self.warn.setText(f'Cell ({x},{y}) is a WALL — the player would arrive stuck.'
                          if wall else '')

    def values(self):
        d = self._dest()
        dest = f"room:${val(self.s.doc.room(d[1])['mapID']):02X}" if d[0] == 'room' \
            else f"vanilla:${d[1]:02X}"
        return dict(x=self.cell[0], y=self.cell[1], dest=dest,
                    dest_screen=self.dst_screen.currentData(),
                    spawn_x=self.dst_x.value(), spawn_y=self.dst_y.value())
