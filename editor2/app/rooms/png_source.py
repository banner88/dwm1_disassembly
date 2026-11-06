"""png_source.py — Borrow → "A picture (PNG)": a PNG's 16x16 cells as a source of
metatiles (S171 r4, ROADMAP P3.3i).

User (S171): "importing tilesets AS IS works great for a brand new room. It does NOT work
well if you are ADDING it to an existing room. Currently also the way to do it is to first
make a new custom room, add a new tileset png, then import tiles from the secondary room."

The picture is cut on the 16-px walk-cell grid the Import art tab would propose
(png_import: key colours, panels, the best offset of the first panel; `offset` spinners
move it), identical cells are shown once, in their REAL colours. Click = import that cell
into this room (colour-matched: recolour.import_true_metatile); Ctrl / Shift + click or a
drag selects several, "Import the selected" brings them in as one undo step.
"""

from PIL import Image, ImageQt
from PySide6.QtCore import QRect, Qt, Signal
from PySide6.QtGui import QColor, QPainter, QPen, QPixmap
from PySide6.QtWidgets import QWidget

CELL = 16
THUMB = 32
GAP = 4
PER_ROW = 8


def cut_cells(img, ox=None, oy=None):
    """([(x, y, 256 RGB)], description) — the picture's 16x16 cells with no key-colour
    pixel, each graphic once. Without an offset: every panel png_import finds, each on its
    own best grid (a rip's panels sit at different offsets); with one: the whole picture
    on that grid."""
    from editor2.core import png_import as PI
    img = img.convert('RGB')
    keys = PI.guess_key_colours(img)
    km = PI.key_mask(img, keys)
    w, h = img.size
    if ox is None or oy is None:
        regions = PI.detect_regions(img, keys) or [PI.Region(0, 0, w, h, 0, 0)]
        for r in regions:
            try:
                r.ox, r.oy = PI.best_offset(img, r, keys)
            except Exception:                                     # noqa: BLE001
                pass
        what = f'{len(regions)} panel(s), each on its own grid'
    else:
        regions = [PI.Region(0, 0, w, h, ox % CELL, oy % CELL)]
        what = f'grid offset ({ox % CELL}, {oy % CELL})'
    px = img.load()
    out, seen = [], set()
    for r in regions:
        for (x, y) in PI.valid_cells(img, r, keys, km=km):
            cell = tuple(px[x + i, y + j][:3] for j in range(CELL) for i in range(CELL))
            if cell in seen:
                continue
            seen.add(cell)
            out.append((x, y, list(cell)))
    return out, what


def cell_quarters(cell):
    """256 RGB (16x16, row-major) -> the 4 quarters' 64 RGB (tl, tr, bl, br)."""
    out = []
    for q in range(4):
        qx, qy = (q % 2) * 8, (q // 2) * 8
        out.append([cell[(qy + y) * CELL + qx + x] for y in range(8) for x in range(8)])
    return out


class PngCells(QWidget):
    """The cells of a picture, in their own colours."""
    importRequested = Signal(object)          # [cell index]
    selectionChanged = Signal(int)
    hoverInfo = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.cells = []
        self.selected = set()
        self._pix = []
        self._drag = None
        self.preview_fn = None           # S171 r6: cell -> PIL picture as it would import
        self.setMouseTracking(True)
        self.setMinimumWidth(PER_ROW * (THUMB + GAP) + GAP)

    def set_preview(self, fn):
        """S171 r6: show the cells as they would look imported (None = their own colours)."""
        if fn is None and self.preview_fn is None:
            return
        self.preview_fn = fn
        self._render_all()
        self.update()

    def _render_all(self):
        self._pix = []
        for _x, _y, c in self.cells:
            im = None
            if self.preview_fn is not None:
                try:
                    im = self.preview_fn(c)
                except Exception:                                # noqa: BLE001
                    im = None
            if im is None:
                im = Image.new('RGB', (CELL, CELL))
                im.putdata([tuple(p) for p in c])
            im = im.resize((THUMB, THUMB), Image.NEAREST)
            self._pix.append(QPixmap.fromImage(ImageQt.ImageQt(im)))

    def set_cells(self, cells):
        self.cells = list(cells)
        self.selected = set()
        self._render_all()
        rows = (len(self.cells) + PER_ROW - 1) // PER_ROW
        self.setFixedHeight(max(60, rows * (THUMB + GAP) + GAP))
        self.selectionChanged.emit(0)
        self.update()

    def _rect(self, i):
        return QRect(GAP + (i % PER_ROW) * (THUMB + GAP), GAP + (i // PER_ROW) * (THUMB + GAP),
                     THUMB, THUMB)

    def _hit(self, pos):
        for i in range(len(self.cells)):
            if self._rect(i).contains(pos):
                return i
        return None

    def paintEvent(self, _ev):
        p = QPainter(self)
        p.fillRect(self.rect(), QColor(30, 30, 36))
        if not self.cells:
            p.setPen(QColor('#999'))
            p.drawText(self.rect().adjusted(8, 8, -8, -8), Qt.TextWordWrap,
                       'Open a picture (PNG): its 16x16 cells show here in their own colours.')
            return
        for i, pm in enumerate(self._pix):
            r = self._rect(i)
            p.drawPixmap(r, pm)
            if i in self.selected:
                pen = QPen(QColor('#ffe000'))
                pen.setWidth(3)
                p.setPen(pen)
                p.drawRect(r.adjusted(-1, -1, 1, 1))

    def mousePressEvent(self, ev):
        i = self._hit(ev.position().toPoint())
        if i is None:
            return
        mods = ev.modifiers()
        if mods & (Qt.ControlModifier | Qt.ShiftModifier):
            self.selected ^= {i}
            self._drag = i
            self.selectionChanged.emit(len(self.selected))
            self.update()
            return
        self.importRequested.emit([i])

    def mouseMoveEvent(self, ev):
        i = self._hit(ev.position().toPoint())
        if i is not None:
            x, y, _c = self.cells[i]
            self.hoverInfo.emit(f'picture cell at ({x}, {y}) — click = import it; '
                                'Ctrl / Shift + click = select several')
        if self._drag is not None and i is not None and (ev.buttons() & Qt.LeftButton):
            a, b = sorted((self._drag, i))
            self.selected |= set(range(a, b + 1))
            self.selectionChanged.emit(len(self.selected))
            self.update()

    def mouseReleaseEvent(self, _ev):
        self._drag = None
