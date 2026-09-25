"""tileset_map.py — the room tileset's 128 slots at a glance (P3.3c, S96).

One room = one 2 KB sheet = 128 tile slots (ids >= 128 are the font/HUD
half of VRAM — a hard engine limit per room, ROADMAP P3.3c). The map draws
every slot with its graphic and its status from `Document.tile_usage`:

    green   PLACED on some screen/state of a room using this sheet
    violet  used only by MY METATILES
    blue    VOCABULARY only (the vanilla source room's tiles — protected so
            the picker's "This room" entries keep their graphics)
    orange  vocabulary, RELEASED (imports / walkability twins may take it)
    grey    ANIMATED 77/78 (never used: VRAM $94D0 rotates — KL S7)
    dim     FREE
    red dot the graphic differs from the sheet the tileset was copied from

The yellow step line is the collision threshold: slots before it are WALL
tiles, slots after it walkable (the bottom-right subtile of a cell decides,
S94). Hover = who uses the slot; click = highlight it on the canvas.
"""

from PIL import Image, ImageQt
from PySide6.QtCore import QRect, Qt, Signal
from PySide6.QtGui import QColor, QPainter, QPen, QPixmap
from PySide6.QtWidgets import (QCheckBox, QComboBox, QHBoxLayout, QLabel,
                               QVBoxLayout, QWidget)

COLS = 16
PITCH = 22
TILE = 16

COLOURS = {
    'placed': QColor(70, 200, 90),
    'mine': QColor(170, 110, 240),
    'vocab': QColor(80, 150, 255),
    'released': QColor(255, 150, 40),
    'animated': QColor(120, 120, 120),
    'free': QColor(60, 60, 66),
}


class SlotGrid(QWidget):
    hovered = Signal(int)          # -1 = none
    clicked = Signal(int)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMouseTracking(True)
        self.setFixedSize(COLS * PITCH + 2, 8 * PITCH + 2)
        self.usage = None
        self.threshold = 0
        self.pix = {}
        self.hover = -1
        self.selected = -1

    def set_data(self, usage, threshold, tile_pixmaps):
        self.usage, self.threshold, self.pix = usage, threshold, tile_pixmaps
        self.update()

    def _rect(self, i):
        return QRect(1 + (i % COLS) * PITCH, 1 + (i // COLS) * PITCH, PITCH, PITCH)

    def _hit(self, pos):
        c, r = (pos.x() - 1) // PITCH, (pos.y() - 1) // PITCH
        if 0 <= c < COLS and 0 <= r < 8:
            return r * COLS + c
        return -1

    def paintEvent(self, ev):
        p = QPainter(self)
        p.fillRect(self.rect(), QColor(30, 30, 34))
        if not self.usage:
            return
        for i, u in enumerate(self.usage):
            rc = self._rect(i)
            st = 'released' if u.get('released') and u['status'] == 'free' else u['status']
            col = COLOURS[st]
            p.fillRect(rc.adjusted(1, 1, -1, -1), col.darker(260) if st == 'free' else col)
            inner = QRect(rc.x() + (PITCH - TILE) // 2, rc.y() + (PITCH - TILE) // 2, TILE, TILE)
            pm = self.pix.get(i)
            if pm is not None:
                if st == 'free':
                    p.setOpacity(0.35)
                p.drawPixmap(inner, pm)
                p.setOpacity(1.0)
            if st == 'animated':
                pen = QPen(QColor(200, 200, 200))
                p.setPen(pen)
                p.drawLine(inner.topLeft(), inner.bottomRight())
                p.drawLine(inner.topRight(), inner.bottomLeft())
            if u.get('changed'):
                p.fillRect(QRect(rc.right() - 6, rc.y() + 2, 4, 4), QColor(255, 50, 50))
            if i == self.selected:
                pen = QPen(QColor(255, 230, 0))
                pen.setWidth(2)
                p.setPen(pen)
                p.setBrush(Qt.NoBrush)
                p.drawRect(rc.adjusted(1, 1, -2, -2))
            elif i == self.hover:
                p.setPen(QPen(QColor(255, 255, 255)))
                p.setBrush(Qt.NoBrush)
                p.drawRect(rc.adjusted(0, 0, -1, -1))
        # collision threshold: a step line between slot thr-1 and thr
        thr = self.threshold
        if 0 < thr < 128:
            pen = QPen(QColor(255, 220, 0))
            pen.setWidth(3)
            p.setPen(pen)
            r, c = divmod(thr, COLS)
            y = 1 + r * PITCH
            x = 1 + c * PITCH
            if c:
                p.drawLine(x, y, x, y + PITCH)                       # vertical tick
                p.drawLine(x, y, 1 + COLS * PITCH, y)                # rest of this row top
                p.drawLine(1, y + PITCH, x, y + PITCH)               # start of next row
            else:
                p.drawLine(1, y, 1 + COLS * PITCH, y)

    def mouseMoveEvent(self, ev):
        h = self._hit(ev.position().toPoint())
        if h != self.hover:
            self.hover = h
            self.update()
            self.hovered.emit(h)

    def leaveEvent(self, ev):
        self.hover = -1
        self.update()
        self.hovered.emit(-1)

    def mousePressEvent(self, ev):
        h = self._hit(ev.position().toPoint())
        if h < 0:
            return
        self.selected = -1 if h == self.selected else h
        self.update()
        self.clicked.emit(self.selected)


class TilesetMap(QWidget):
    hoverInfo = Signal(str)
    highlightTile = Signal(int)         # -1 = clear
    releaseToggled = Signal(bool)

    def __init__(self, parent=None):
        super().__init__(parent)
        v = QVBoxLayout(self)
        v.setContentsMargins(4, 4, 4, 4)
        v.setSpacing(3)
        self.summary = QLabel('')
        self.summary.setWordWrap(True)
        v.addWidget(self.summary)
        row = QHBoxLayout()
        self.release = QCheckBox('Release unused vocabulary')
        self.release.setToolTip(
            'The vanilla source room\'s tiles are protected so "This room" keeps '
            'offering them with their real graphics. Releasing lets imports and '
            'walkability twins use the slots that are NOT placed anywhere — the '
            'picker then flags those metatiles "graphic may change". Untick to '
            'protect them again.')
        self.release.toggled.connect(self._release)
        row.addWidget(self.release)
        row.addStretch(1)
        row.addWidget(QLabel('draw with palette'))
        self.pal_box = QComboBox()
        self.pal_box.addItems(['0', '1', '2', '3'])
        self.pal_box.currentIndexChanged.connect(lambda _i: self.refresh())
        row.addWidget(self.pal_box)
        v.addLayout(row)
        self.grid = SlotGrid()
        self.grid.hovered.connect(self._hovered)
        self.grid.clicked.connect(self.highlightTile.emit)
        v.addWidget(self.grid, 0, Qt.AlignLeft)
        legend = QLabel(
            '<span style="color:#46c85a">■</span> placed '
            '<span style="color:#aa6ef0">■</span> my metatiles '
            '<span style="color:#5096ff">■</span> vocabulary '
            '<span style="color:#ff9628">■</span> released '
            '<span style="color:#787878">■</span> animated '
            '<span style="color:#ff3232">•</span> graphic changed · '
            '<span style="color:#ffdc00">▬</span> wall | walkable')
        legend.setWordWrap(True)
        v.addWidget(legend)
        v.addStretch(1)
        self._building = False
        self.doc = self.renderer = self.room = None
        self.sheet = self.pals = None

    def set_room(self, doc, renderer, room, sheet, pals, threshold):
        self.doc, self.renderer, self.room = doc, renderer, room
        self.sheet, self.pals, self.threshold = sheet, pals, threshold
        self.refresh()

    def clear(self):
        self.doc = self.room = None
        self.grid.set_data(None, 0, {})
        self.summary.setText('Vanilla room — clone it to see its slot budget as yours.')

    def refresh(self):
        if self.doc is None or self.room is None or self.sheet is None:
            return
        tid = self.doc.tileset_key(self.room)
        usage = self.doc.tile_usage(tid)
        pal = int(self.pal_box.currentIndex())
        pix = {}
        for i in range(128):
            img = self.renderer.render_tile(self.sheet, i, self.pals, pal)
            img = img.resize((TILE, TILE), Image.NEAREST)
            pix[i] = QPixmap.fromImage(ImageQt.ImageQt(img))
        self.usage = usage
        self.grid.set_data(usage, self.threshold, pix)
        fc = self.doc.free_counts(tid, self.threshold)
        counts = {}
        for u in usage:
            counts[u['status']] = counts.get(u['status'], 0) + 1
        own = 'tileset in your project' if ':' not in tid else \
            'vanilla sheet (copied into the project on the first edit)'
        self.summary.setText(
            f"<b>{tid}</b> — {own}<br>"
            f"free: <b>{fc['wall']}</b> wall / <b>{fc['walkable']}</b> walkable "
            f"(<b>{fc['total']}</b> of 128) · placed {counts.get('placed', 0)} · "
            f"my metatiles {counts.get('mine', 0)} · vocabulary {counts.get('vocab', 0)}")
        self._building = True
        self.release.setChecked(self.doc.released(tid))
        self.release.setEnabled(any(u['vocab'] for u in usage))
        self._building = False

    def _release(self, on):
        if not self._building:
            self.releaseToggled.emit(bool(on))

    def _hovered(self, i):
        if i < 0 or not getattr(self, 'usage', None):
            self.hoverInfo.emit('')
            return
        u = self.usage[i]
        side = 'WALL side' if i < self.threshold else 'walkable side'
        bits = [f'slot ${i:02X} ({i}) — {side}']
        if u['animated']:
            bits.append('ANIMATED (77/78 rotate in custom rooms) — never used')
        if u['placed']:
            where = ', '.join(f'{r} scr {k} st {s}' for r, k, s in u['placed'][:6])
            more = f' +{len(u["placed"]) - 6}' if len(u['placed']) > 6 else ''
            bits.append(f'placed: {where}{more}')
        if u['mine']:
            bits.append(f"my metatiles: {', '.join(sorted(set(u['mine']))[:4])}")
        if u['vocab']:
            bits.append('vocabulary (source room)' + (' — RELEASED' if u.get('released') else ''))
        if u['changed']:
            bits.append('graphic CHANGED vs the origin sheet')
        if u['status'] == 'free':
            bits.append('FREE')
        self.hoverInfo.emit(' · '.join(bits))
