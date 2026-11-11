"""minimap.py — the room's screen grid (S93).

Shows the 4x2 screen grid of the custom-room schema (ROOM_DATA_FORMAT
"Overview": index = row*4 + col; the engine scrolls a 4x4 grid, the
schema exposes 4x2 today) with a live thumbnail per declared screen and
the screen in view highlighted — so "what is THE room" vs "the screen I
am editing" is always visible. Click a screen to page to it; click an
empty cell to add a screen there; right-click a screen for its menu: Copy screen /
Paste screen here (S175: the tiles, colours and stamps — editor2/core/screen_tools.py),
Shift objects ◀ ▶ ▲ ▼, Remove screen.
"""

from PIL import ImageQt
from PySide6.QtCore import QRect, QSize, Qt, Signal
from PySide6.QtGui import QColor, QPainter, QPen, QPixmap
from PySide6.QtWidgets import QMenu, QWidget

from editor2.core.document import GRID_COLS, GRID_ROWS

CW, CH = 80, 64        # thumbnail cell (0.5x)
GAP = 6


class MiniMap(QWidget):
    screenSelected = Signal(int)
    addScreenRequested = Signal(int)
    removeScreenRequested = Signal(int)
    copyScreenRequested = Signal(int)          # S175
    pasteScreenRequested = Signal(int)         # S175
    shiftRequested = Signal(int, int, int)     # S175: key, dx, dy

    def __init__(self, parent=None):
        super().__init__(parent)
        self.thumbs = {}         # key -> QPixmap
        self.current = 0
        self._hover = None
        self.can_paste = None    # S175: the copied screen's label (None = nothing copied)
        self.setMouseTracking(True)
        self.setFixedSize(self.sizeHint())

    def sizeHint(self):
        return QSize(GRID_COLS * (CW + GAP) + GAP,
                     GRID_ROWS * (CH + GAP) + GAP)

    def set_screens(self, images, current):
        """images: {key: PIL image (any size)} -> thumbnails."""
        self.thumbs = {}
        for k, im in images.items():
            th = im.resize((CW, CH))
            self.thumbs[k] = QPixmap.fromImage(ImageQt.ImageQt(th))
        self.current = current
        self.update()

    def set_current(self, key):
        self.current = key
        self.update()

    def _rect(self, key):
        c, r = key % GRID_COLS, key // GRID_COLS
        return QRect(GAP + c * (CW + GAP), GAP + r * (CH + GAP), CW, CH)

    def _key_at(self, pos):
        for k in range(GRID_COLS * GRID_ROWS):
            if self._rect(k).contains(pos):
                return k
        return None

    def paintEvent(self, ev):
        p = QPainter(self)
        p.fillRect(self.rect(), QColor(28, 28, 32))
        for k in range(GRID_COLS * GRID_ROWS):
            r = self._rect(k)
            if k in self.thumbs:
                p.drawPixmap(r, self.thumbs[k])
                pen = QPen(QColor(255, 255, 0) if k == self.current
                           else QColor(120, 120, 120))
                pen.setWidth(2 if k == self.current else 1)
                p.setPen(pen)
                p.drawRect(r.adjusted(0, 0, -1, -1))
                p.setPen(QColor(255, 255, 255))
                p.fillRect(QRect(r.left(), r.top(), 14, 12), QColor(0, 0, 0, 160))
                p.drawText(QRect(r.left(), r.top(), 14, 12), Qt.AlignCenter, str(k))
            else:
                pen = QPen(QColor(70, 70, 76))
                pen.setStyle(Qt.DashLine)
                p.setPen(pen)
                p.drawRect(r.adjusted(0, 0, -1, -1))
                p.setPen(QColor(90, 90, 96) if self._hover != k
                         else QColor(200, 200, 200))
                p.drawText(r, Qt.AlignCenter, '+')

    def mouseMoveEvent(self, ev):
        k = self._key_at(ev.position().toPoint())
        if k != self._hover:
            self._hover = k
            self.update()

    def leaveEvent(self, ev):
        self._hover = None
        self.update()

    def mousePressEvent(self, ev):
        k = self._key_at(ev.position().toPoint())
        if k is None:
            return
        if ev.button() == Qt.RightButton:
            if k in self.thumbs:
                m = QMenu(self)
                m.setToolTipsVisible(True)
                cp = m.addAction(f'Copy screen {k}  (⌘⇧C)')
                cp.setToolTip('Its tiles, colours and stamps in the state shown — to paste over '
                              'another screen of this room (a backup of the art)')
                ps = m.addAction(f'Paste over screen {k}  (⌘⇧V)'
                                 + (f' — {self.can_paste}' if self.can_paste else ''))
                ps.setEnabled(bool(self.can_paste))
                ps.setToolTip('The tiles, colours and stamps only: its NPCs, doors, triggers, '
                              'cutscenes and scripts stay')
                sm = m.addMenu('Shift objects')
                acts = {}
                for txt, d in (('◀ left', (-1, 0)), ('▶ right', (1, 0)), ('▲ up', (0, -1)),
                               ('▼ down', (0, 1))):
                    acts[sm.addAction(txt)] = d
                m.addSeparator()
                rm = m.addAction(f'Remove screen {k}')
                got = m.exec(ev.globalPosition().toPoint())
                if got == rm:
                    self.removeScreenRequested.emit(k)
                elif got == cp:
                    self.copyScreenRequested.emit(k)
                elif got == ps:
                    self.pasteScreenRequested.emit(k)
                elif got in acts:
                    self.shiftRequested.emit(k, *acts[got])
            return
        if k in self.thumbs:
            self.screenSelected.emit(k)
        else:
            self.addScreenRequested.emit(k)
