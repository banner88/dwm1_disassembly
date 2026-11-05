"""tile_picker.py — the room's 128-tile sheet as a brush picker (S93).

S168 (page 2): 256 tiles — page 1 (rows 0-7) above PAGE 2 (rows 8-15, the 128 more
tiles in VRAM bank 1, editor2/core/page2.py); a page-2 tile is emitted as its tile VALUE
($100 + n). Page-2 tile n is a wall exactly when page-1 tile n is (the engine compares
the map byte), so both pages are tinted from the threshold.

Flat order, 16 tiles per row (KEY_LESSONS S6: PNG/2bpp/editor all index
tiles in flat scan order — never metatile order). Rendered in the palette
slot currently selected in the palette panel, so what you pick is what
you paint. The collision threshold is drawn as a red boundary: tiles
before it are WALLS (tile < threshold → blocked, KEY_LESSONS S6, user-
verified across every room), tiles after it walkable.
"""

from PIL import ImageQt
from PySide6.QtCore import QRect, QSize, Qt, Signal
from PySide6.QtGui import QColor, QPainter, QPen, QPixmap, QBrush
from PySide6.QtWidgets import QWidget

from editor2.core import page2 as P2

PER_ROW = 16
ROWS = 16                  # S168: page 1 (8 rows) + page 2 (8 rows)


class TilePicker(QWidget):
    tileSelected = Signal(int)
    hoverInfo = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.renderer = None
        self.sheet = None
        self.pals = None
        self.pal_idx = 0
        self.threshold = 0
        self.scale = 2
        self.selected = 0
        self._hover = None
        self._pix = None
        self.setMouseTracking(True)
        self.setFixedSize(self.sizeHint())

    def sizeHint(self):
        return QSize(PER_ROW * 8 * self.scale + 2, ROWS * 8 * self.scale + 2)

    def set_scale(self, s):
        self.scale = max(1, min(4, int(s)))
        self.setFixedSize(self.sizeHint())
        self._rebuild()

    def set_sheet(self, renderer, sheet, pals, threshold, pal_idx=None):
        self.renderer, self.sheet, self.pals = renderer, sheet, pals
        self.threshold = threshold
        if pal_idx is not None:
            self.pal_idx = pal_idx
        self._rebuild()

    def set_palette_index(self, p):
        self.pal_idx = p & 7
        self._rebuild()

    def set_selected(self, tile):
        self.selected = P2.slot_key(tile)
        self.update()

    def _rebuild(self):
        if self.renderer is None or self.sheet is None:
            self._pix = None
        else:
            img = self.renderer.tile_sheet_image(P2.pad_sheet(self.sheet), self.pals,
                                                 self.pal_idx, PER_ROW,
                                                 self.scale)
            self._pix = QPixmap.fromImage(ImageQt.ImageQt(img))
        self.update()

    def _tile_at(self, pos):
        c = (pos.x() - 1) // (8 * self.scale)
        r = (pos.y() - 1) // (8 * self.scale)
        if 0 <= c < PER_ROW and 0 <= r < ROWS:
            return r * PER_ROW + c
        return None

    def _rect(self, t):
        s = 8 * self.scale
        return QRect(1 + (t % PER_ROW) * s, 1 + (t // PER_ROW) * s, s, s)

    def paintEvent(self, ev):
        p = QPainter(self)
        p.fillRect(self.rect(), QColor(28, 28, 32))
        if self._pix is None:
            p.setPen(QColor(160, 160, 160))
            p.drawText(self.rect(), Qt.AlignCenter, 'no tileset')
            return
        p.drawPixmap(1, 1, self._pix)
        # wall tint + threshold boundary (both pages: page-2 tile n walks like tile n)
        thr = min(self.threshold, 128)
        for t in range(thr):
            p.fillRect(self._rect(t), QColor(255, 40, 40, 45))
            p.fillRect(self._rect(0x80 + t), QColor(255, 40, 40, 45))
        # the page-2 line
        s8 = 8 * self.scale
        p.setPen(QPen(QColor(120, 170, 255), 2))
        p.drawLine(1, 1 + 8 * s8, 1 + PER_ROW * s8, 1 + 8 * s8)
        if 0 < thr < 128:
            pen = QPen(QColor(255, 60, 60))
            pen.setWidth(2)
            p.setPen(pen)
            r = self._rect(thr)
            s = 8 * self.scale
            # boundary: vertical tick before tile `thr` plus a line under the
            # previous row segment
            p.drawLine(r.left(), r.top(), r.left(), r.bottom())
            if thr % PER_ROW:
                p.drawLine(1, r.top(), r.left(), r.top())
            p.drawLine(r.left(), r.bottom() + 1,
                       1 + PER_ROW * s, r.bottom() + 1)
        # hover
        if self._hover is not None:
            p.setPen(QPen(QColor(255, 255, 255, 160), 1))
            p.setBrush(Qt.NoBrush)
            p.drawRect(self._rect(self._hover).adjusted(0, 0, -1, -1))
        # selection
        pen = QPen(QColor(255, 255, 0))
        pen.setWidth(2)
        p.setPen(pen)
        p.setBrush(Qt.NoBrush)
        p.drawRect(self._rect(self.selected).adjusted(1, 1, -1, -1))

    def mouseMoveEvent(self, ev):
        t = self._tile_at(ev.position().toPoint())
        if t != self._hover:
            self._hover = t
            self.update()
            if t is None:
                self.hoverInfo.emit('')
            else:
                walk = 'WALL' if P2.is_wall(t, self.threshold) else 'walkable'
                page = 'page 2 ' if t >= 0x80 else ''
                self.hoverInfo.emit(f'{page}tile ${t & 0x7F:02X} ({t & 0x7F})  {walk}')

    def leaveEvent(self, ev):
        self._hover = None
        self.update()

    def mousePressEvent(self, ev):
        t = self._tile_at(ev.position().toPoint())
        if t is not None:
            self.selected = t
            self.update()
            self.tileSelected.emit(P2.value_of(t))     # S168: page 2 = $100 + n
