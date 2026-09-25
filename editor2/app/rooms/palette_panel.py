"""palette_panel.py — the room's 8 BG palettes (S93).

Rows 0-3 are the room environment palettes (`custom.palettes[]` 8x4
RGB555, or a vanilla palette derived from source_mapID); rows 4-7 are
the shared SYSTEM set (HUD/menus — GATE_GENERATION "BG slots 4-7").
Clicking a row selects it as the ATTR brush (paint palette slots onto
tiles). Double-clicking a colour edits it — except idx1 and idx3, which the
engine FORCES to $6BFF / $0000 at runtime (KEY_LESSONS S7/S39): they are
drawn locked instead of letting the author fight the engine.
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
        self._hover = None
        self.setMouseTracking(True)
        self.setFixedSize(self.sizeHint())

    def sizeHint(self):
        return QSize(LABEL_W + 4 * (SW + GAP) + 4, 8 * (SW + GAP) + 4)

    def set_palettes(self, pals, words=None, pid=None):
        self.pals, self.words, self.pid = pals, words, pid
        self.update()

    def set_selected(self, slot):
        self.selected = slot & 7
        self.update()

    def _rect(self, slot, idx):
        return QRect(LABEL_W + idx * (SW + GAP) + 2, 2 + slot * (SW + GAP),
                     SW, SW)

    def _hit(self, pos):
        for s in range(8):
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
        for s in range(8):
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
                locked = (i in (1, 3)) and s < 4
                if locked:
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
                if i in (1, 3) and s < 4:
                    txt += '  (engine-forced: idx1=$6BFF, idx3=$0000)'
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
        if i in (1, 3):
            QMessageBox.information(self, 'Engine-forced colour',
                                    'Colour 1 is forced to $6BFF and colour 3 to $0000 by the '
                                    'engine at runtime (KEY_LESSONS S7/S39) — editing them '
                                    'would not show in-game.')
            return
        cur = QColor(*rgb555(self.words[s][i]))
        qc = QColorDialog.getColor(cur, self, f'Palette {s} colour {i} (RGB555)')
        if qc.isValid():
            self.colorEdited.emit(self.pid, s, i, to555(qc))
