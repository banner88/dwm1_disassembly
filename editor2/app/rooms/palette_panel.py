"""palette_panel.py — the room's 8 BG palettes (S93).

Rows 0-3 are the room environment palettes (`custom.palettes[]` 8x4
RGB555, or a vanilla palette derived from source_mapID); rows 4-7 are
the shared SYSTEM set (HUD/menus — GATE_GENERATION "BG slots 4-7").
Clicking a row selects it as the ATTR brush (paint palette slots onto
tiles). Double-clicking a colour edits it — except idx3 (forced black) and
idx1, which the engine FORCES to cream $6BFF (bank $17 LoadPal_4102) unless
the palette is marked "own colour 1" (S96 FreeColor1Hook, custom rooms):
locked colours are drawn with an L. Slots 4-7 are hidden unless "show
system 4-7" is ticked (S96 QOL).
"""

from PySide6.QtCore import QRect, QSize, Qt, Signal
from PySide6.QtGui import QColor, QPainter, QPen
from PySide6.QtWidgets import QColorDialog, QWidget

from editor2.core.render_project import rgb555, FORCED_IDX1, FORCED_IDX3

SW = 22       # swatch size
GAP = 3
LABEL_W = 26


def to555(qc):
    return (qc.red() >> 3) | ((qc.green() >> 3) << 5) | ((qc.blue() >> 3) << 10)


class PalettePanel(QWidget):
    slotSelected = Signal(int)
    colorEdited = Signal(str, int, int, int)      # pid, slot, idx, rgb555
    hoverInfo = Signal(str)
    makeEditableRequested = Signal(int, int)      # (slot, idx) double-clicked on a borrowed palette

    def __init__(self, parent=None):
        super().__init__(parent)
        self.pals = None          # 8x4 RGB tuples (display)
        self.words = None         # 8x4 RGB555 (editable) or None
        self.pid = None
        self.selected = 0
        self.free1 = False        # S96: palette keeps its own colour 1 (slots 0-3)
        self.show_system = False  # S96 QOL: slots 4-7 folded by default
        self._hover = None
        self.setMouseTracking(True)
        self.setFixedSize(self.sizeHint())

    def rows(self):
        return 8 if self.show_system else 4

    def sizeHint(self):
        return QSize(LABEL_W + 4 * (SW + GAP) + 4, self.rows() * (SW + GAP) + 4)

    def set_show_system(self, on):
        self.show_system = bool(on)
        self.setFixedSize(self.sizeHint())
        self.updateGeometry()
        self.update()

    def locked(self, s, i):
        return s < 4 and (i == 3 or (i == 1 and not self.free1))

    def set_palettes(self, pals, words=None, pid=None, free1=False):
        self.pals, self.words, self.pid, self.free1 = pals, words, pid, bool(free1)
        self.update()

    def set_selected(self, slot):
        self.selected = slot & 7
        self.update()

    def _rect(self, slot, idx):
        return QRect(LABEL_W + idx * (SW + GAP) + 2, 2 + slot * (SW + GAP),
                     SW, SW)

    def _hit(self, pos):
        for s in range(self.rows()):
            for i in range(4):
                if self._rect(s, i).contains(pos):
                    return s, i
            if QRect(0, 2 + s * (SW + GAP), LABEL_W, SW).contains(pos):
                return s, None
        return None

    def paintEvent(self, ev):
        p = QPainter(self)
        p.fillRect(self.rect(), QColor(36, 36, 40))
        if not self.pals:
            p.setPen(QColor(160, 160, 160))
            p.drawText(self.rect(), Qt.AlignCenter, 'no palette')
            return
        for s in range(self.rows()):
            y = 2 + s * (SW + GAP)
            if s == self.selected:
                p.fillRect(QRect(0, y - 1, self.width(), SW + 2),
                           QColor(255, 255, 0, 40))
            p.setPen(QColor(220, 220, 220) if s < 4 else QColor(140, 140, 140))
            p.drawText(QRect(0, y, LABEL_W - 4, SW), Qt.AlignVCenter | Qt.AlignRight,
                       f'{s}')
            for i in range(4):
                r = self._rect(s, i)
                c = self.pals[s][i]
                p.fillRect(r, QColor(*c))
                pen = QPen(QColor(0, 0, 0))
                p.setPen(pen)
                p.drawRect(r.adjusted(0, 0, -1, -1))
                if self.locked(s, i):
                    p.setPen(QColor(255, 255, 255, 200) if i == 3
                             else QColor(0, 0, 0, 200))
                    p.drawText(r, Qt.AlignCenter, 'L')
                if self._hover == (s, i):
                    p.setPen(QPen(QColor(255, 255, 255), 2))
                    p.drawRect(r.adjusted(1, 1, -2, -2))

    def mouseMoveEvent(self, ev):
        h = self._hit(ev.position().toPoint())
        if h != self._hover:
            self._hover = h
            self.update()
            if h and h[1] is not None and self.pals:
                s, i = h
                w = (self.words[s][i] if self.words and s < len(self.words)
                     else None)
                txt = f'palette {s} colour {i}'
                if w is not None:
                    txt += f'  ${w:04X}'
                if self.locked(s, i):
                    txt += ('  (engine-forced black)' if i == 3 else
                            '  (engine-forced cream — tick "own colour 1" to free it)')
                if s >= 4:
                    txt += '  (system palette, shared by HUD/menus)'
                self.hoverInfo.emit(txt)
            else:
                self.hoverInfo.emit('')

    def leaveEvent(self, ev):
        self._hover = None
        self.update()

    def mousePressEvent(self, ev):
        h = self._hit(ev.position().toPoint())
        if h is None:
            return
        self.selected = h[0]
        self.update()
        self.slotSelected.emit(h[0])

    def mouseDoubleClickEvent(self, ev):
        h = self._hit(ev.position().toPoint())
        if h is None or h[1] is None:
            return
        s, i = h
        if self.words is None or self.pid is None:
            # S94b (user report: "double-clicking a colour does nothing"):
            # the owner decides — clone the vanilla room, or copy the
            # borrowed palette into the project — then reopens the picker.
            self.makeEditableRequested.emit(s, i)
            return
        self.edit_color(s, i)

    def edit_color(self, s, i):
        from PySide6.QtWidgets import QMessageBox
        if self.words is None or self.pid is None:
            return
        if s >= 4:
            QMessageBox.information(self, 'System palette',
                                    'Slots 4-7 are the shared system palettes (HUD / menus) '
                                    'and are not part of the room.')
            return
        if self.locked(s, i):
            QMessageBox.information(self, 'Engine-forced colour',
                                    'Colour 3 is forced to black by the engine. Colour 1 is '
                                    'forced to cream ($6BFF) unless the palette has "own '
                                    'colour 1" ticked (custom rooms, S96) — tick it below '
                                    'the palettes to edit colour 1.')
            return
        cur = QColor(*rgb555(self.words[s][i]))
        qc = QColorDialog.getColor(cur, self, f'Palette {s} colour {i} (RGB555)')
        if qc.isValid():
            self.colorEdited.emit(self.pid, s, i, to555(qc))
