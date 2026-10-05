"""cell_picker.py — pick a screen + cell ON THE PICTURE (S123 r3).

User S123 r3: "When making new world and entry coordinates, SHOW VISUALLY. How
the hell am I meant to know where in a room x/y is." Every place a world asks
for a cell (New world…, the start / landing, a portal) uses this widget: the
room's screen drawn at 2x with a grid, click a cell to choose it. The chosen
cell is outlined with its role ("LAND" / "PORTAL"), walls are refused with a
note, and the room's other doors / exits / portals are drawn as context.

`CellPicker(session)` · `set_room(room_id)` (a project room) /
`set_vanilla(mid)` (a game room, read-only context) / `set_theme(t)` (a NEW room
in gate look t that does not exist yet: its one plain-floor screen) ·
`set_cell(screen, x, y)` · `cell()` -> (screen, x, y) · signal `changed`.
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QColor, QPainter, QPen, QPixmap, QFont
from PySide6.QtWidgets import QComboBox, QHBoxLayout, QLabel, QVBoxLayout, QWidget
from PIL import ImageQt

from editor2.core import gates as G
from editor2.core.document import val

CELL_PX = 32                      # 16 px metatile cell at 2x


class _Pic(QLabel):
    clicked = Signal(int, int)

    def __init__(self):
        super().__init__()
        self.setFixedSize(320, 256)
        self.setCursor(Qt.CrossCursor)
        self.setStyleSheet('background:#202020;')
        self.img = None
        self.boxes = []           # (x, y, QColor, text, filled)
        self.walls = None         # 10 x 8 bools (True = wall) or None

    def paintEvent(self, ev):
        super().paintEvent(ev)
        p = QPainter(self)
        if self.img is not None:
            qimg = ImageQt.ImageQt(self.img.convert('RGB'))
            p.drawPixmap(0, 0, QPixmap.fromImage(qimg).scaled(320, 256))
        p.setPen(QPen(QColor(255, 255, 255, 40)))
        for i in range(1, 10):
            p.drawLine(i * CELL_PX, 0, i * CELL_PX, 256)
        for j in range(1, 8):
            p.drawLine(0, j * CELL_PX, 320, j * CELL_PX)
        f = QFont()
        f.setBold(True)
        f.setPointSize(7)
        p.setFont(f)
        for x, y, col, text, filled in self.boxes:
            if filled:
                c = QColor(col)
                c.setAlpha(90)
                p.fillRect(x * CELL_PX, y * CELL_PX, CELL_PX, CELL_PX, c)
            pen = QPen(col)
            pen.setWidth(3 if filled else 2)
            p.setPen(pen)
            p.drawRect(x * CELL_PX + 1, y * CELL_PX + 1, CELL_PX - 3, CELL_PX - 3)
            if text:
                p.fillRect(x * CELL_PX + 2, y * CELL_PX + 2, len(text) * 6 + 4, 11,
                           QColor(0, 0, 0, 170))
                p.drawText(x * CELL_PX + 4, y * CELL_PX + 11, text)
        p.end()

    def mousePressEvent(self, ev):
        x, y = int(ev.position().x() // CELL_PX), int(ev.position().y() // CELL_PX)
        if 0 <= x <= 9 and 0 <= y <= 7:
            self.clicked.emit(x, y)


class CellPicker(QWidget):
    """A room screen picture: click a cell to choose it."""
    changed = Signal()

    COLOURS = {'LAND': QColor(90, 255, 120), 'PORTAL': QColor(90, 200, 255)}

    def __init__(self, session, role='LAND', parent=None):
        super().__init__(parent)
        self.s = session
        self.role = role
        self.room_id = None
        self.mid = None
        self.theme = None
        self._cell = (0, 4, 4)
        self._grid = None
        self._thr = 0
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        row = QHBoxLayout()
        row.addWidget(QLabel('screen'))
        self.screen = QComboBox()
        self.screen.currentIndexChanged.connect(self._screen_changed)
        row.addWidget(self.screen)
        row.addStretch(1)
        self.where = QLabel('')
        row.addWidget(self.where)
        v.addLayout(row)
        self.pic = _Pic()
        self.pic.clicked.connect(self._clicked)
        v.addWidget(self.pic)
        self.note = QLabel('')
        self.note.setWordWrap(True)
        self.note.setMaximumWidth(320)
        v.addWidget(self.note)

    # ------------------------------------------------------------ sources
    def set_room(self, room_id):
        self.room_id, self.mid, self.theme = room_id, None, None
        room = self.s.doc.room(room_id)
        keys = self.s.doc.screen_keys(room) if room is not None else [0]
        self._fill_screens(keys)

    def set_vanilla(self, mid):
        self.room_id, self.mid, self.theme = None, int(mid), None
        keys = next((sc for m, _n, sc in self.s.renderer.vanilla_rooms() if m == self.mid), [0])
        self._fill_screens(keys)

    def set_theme(self, t):
        """A NEW room in gate look t (not made yet): one screen of plain floor."""
        self.room_id, self.mid, self.theme = None, None, int(t)
        self._fill_screens([0])

    def _fill_screens(self, keys):
        want = self._cell[0]
        self.screen.blockSignals(True)
        self.screen.clear()
        for k in keys:
            self.screen.addItem(str(k), int(k))
        i = self.screen.findData(want)
        self.screen.setCurrentIndex(i if i >= 0 else 0)
        self.screen.setEnabled(len(keys) > 1)
        self.screen.blockSignals(False)
        self._cell = (self.screen.currentData() if self.screen.count() else 0,
                      self._cell[1], self._cell[2])
        self._redraw()

    # ------------------------------------------------------------ cell
    def cell(self):
        return self._cell

    def set_cell(self, screen, x, y):
        self._cell = (int(screen), int(x), int(y))
        i = self.screen.findData(int(screen))
        if i >= 0 and i != self.screen.currentIndex():
            self.screen.blockSignals(True)
            self.screen.setCurrentIndex(i)
            self.screen.blockSignals(False)
        self._redraw()

    def is_wall(self, x, y):
        if self._grid is None:
            return False
        try:
            return self._grid[y * 2 + 1][x * 2 + 1] < self._thr
        except Exception:                                   # noqa: BLE001
            return False

    def _screen_changed(self, _i):
        if self.screen.currentData() is None:
            return
        self._cell = (self.screen.currentData(), self._cell[1], self._cell[2])
        self._redraw()
        self.changed.emit()

    def _clicked(self, x, y):
        self._cell = (self._cell[0], x, y)
        self._redraw()
        self.changed.emit()

    # ------------------------------------------------------------ draw
    def _redraw(self):
        rend, doc = self.s.renderer, self.s.doc
        k, cx, cy = self._cell
        img, boxes = None, []
        self._grid, self._thr = None, 0
        try:
            if self.room_id is not None:
                room = doc.room(self.room_id)
                img = rend.render_screen(room, k, 0, 1)
                st = rend.screen_state(room, k, 0)
                self._grid, _lid = rend.layout_grid(st['layout'])
                self._thr = rend.room_gfx(room).threshold
                for e in st.get('exits') or []:
                    ex, ey = int(val(e['x'])), int(val(e['y']))
                    if G.is_gate_entrance(e):
                        boxes.append((ex, ey, QColor(90, 200, 255), 'portal', False))
                    elif e.get('door'):
                        boxes.append((ex, ey, QColor(255, 170, 60), 'D', False))
                    else:
                        boxes.append((ex, ey, QColor(255, 90, 90), 'E', False))
            elif self.mid is not None:
                img = rend.render_vanilla_screen(self.mid, k, 1, 0)
                self._grid = rend.vanilla_screen_grid(self.mid, k, 0)
                self._thr = rend.vanilla_gfx(self.mid).threshold
                _n, exits = rend.vanilla_markers(self.mid, k, 0)
                for e in exits:
                    boxes.append((int(e['x']), int(e['y']), QColor(255, 90, 90), 'E', False))
            elif self.theme is not None:
                gfx = rend.theme_gfx(self.theme)
                grid = doc.blank_grid(0x33)          # Document._new_theme_room's floor
                fp = 3
                try:
                    fl = next(m for m in rend.maze_vocab()
                              if all(0x30 <= t <= 0x33 for t in m['tiles']))
                    fp = fl['pal'] if isinstance(fl['pal'], int) else fl['pal'][3]
                except Exception:                           # noqa: BLE001
                    pass
                img = rend.compose(gfx.sheet, grid, doc.blank_grid(fp),
                                   rend.theme_palettes(self.theme))
                self._grid, self._thr = grid, gfx.threshold
        except Exception as exc:                            # noqa: BLE001
            self.note.setText(f'(no picture: {exc})')
        col = self.COLOURS.get(self.role, QColor(90, 255, 120))
        boxes.append((cx, cy, col, self.role, True))
        self.pic.img = img
        self.pic.boxes = boxes
        self.pic.update()
        self.where.setText(f'cell ({cx},{cy})')
        if img is not None:
            if self.is_wall(cx, cy):
                self.note.setStyleSheet('color:#ff8060;')
                self.note.setText(f'⚠ ({cx},{cy}) is a WALL — the player would be stuck. '
                                  'Click a floor cell.')
            else:
                self.note.setStyleSheet('color:#aaa;')
                self.note.setText('Click a cell on the picture. '
                                  + ('Orange D = doors, red E = exits, blue = portals.'
                                     if self.theme is None else
                                     'The new room starts as plain floor; paint it afterwards.'))
