"""import_tab.py — "Import art": background tiles from a PNG into a room (S96).

User workflow (S96): "import PNG, move the grid left/right until I am happy
with it, then block out any parts I don't want gridded". The eye decides —
the tool only proposes:

  1. Open PNG — copied into the project (assets/imports/). Key colours (the
     rip's background + anything not GBC-representable, e.g. caption text)
     and PANELS (connected non-key areas) are detected; each panel gets its
     own grid offset from its top-left corner.
  2. Line up — pick a panel, nudge its offset with the spin boxes or the
     arrow keys (Shift = 8 px), or "Auto-align" (fewest distinct tiles).
     Drag with the Panel tool to draw a panel by hand.
  3. Block out — cells touching key colour are never gridded; the Mask tool
     blocks more. The Wall tool marks cells the player may not enter (with
     "same tile everywhere", one click marks every identical cell).
  4. Select cells (drag), look at "Show as GBC" — the fitted result under
     DWM1's palette rules (4 room palettes; colours 1 and 3 are forced
     cream/black by the engine, so each palette has two free colours) —
     tick "keep" on palette slots the room already relies on, then
     "Add to My metatiles" or "Stamp onto screen".

Per-image settings persist in project.json under custom._editor.imports
(the compiler ignores underscore keys). Everything that changes the room is
one undoable SnapshotCommand; grid/mask edits are small merged commands.
"""

import copy
import os
import shutil

from PIL import Image, ImageQt
from PySide6.QtCore import QRectF, Qt, QTimer, Signal
from PySide6.QtGui import (QBrush, QColor, QKeySequence, QPainter, QPen,
                           QPixmap, QUndoCommand, QShortcut)
from PySide6.QtWidgets import (QButtonGroup, QCheckBox, QComboBox, QFileDialog,
                               QFormLayout, QGraphicsPixmapItem, QGraphicsScene,
                               QGraphicsView, QGridLayout, QGroupBox, QHBoxLayout,
                               QLabel, QListWidget, QListWidgetItem, QMessageBox,
                               QPushButton, QRadioButton, QScrollArea,
                               QSizePolicy, QSpinBox, QSplitter, QVBoxLayout,
                               QWidget)

from editor2.core import png_import as P
from editor2.core.document import val
from editor2.app.rooms import commands as C

CELL = P.CELL
# free colours per palette: 2 under the engine's forced cream/black; 3 when
# the room's palette keeps its own colour 1 (S96 FreeColor1Hook, custom rooms)
NFREE_FORCED, NFREE_OWN = 2, 3


def hexcol(c):
    return '#%02X%02X%02X' % c


def parse_col(s):
    s = s.lstrip('#')
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


# ------------------------------------------------------------ undo command
class EditImport(QUndoCommand):
    """Grid / mask / wall / key edits of one image's import settings. Small
    and mergeable: consecutive edits of the same kind become one step."""
    ID = 3001

    def __init__(self, tab, label, mutate):
        super().__init__(label)
        self.tab = tab
        self.idx = tab.entry_index
        self.before = copy.deepcopy(tab.entry())
        mutate(tab.entry())
        self.after = copy.deepcopy(tab.entry())
        self._first = True

    def id(self):
        return self.ID

    def mergeWith(self, other):
        if other.idx != self.idx or other.text() != self.text():
            return False
        self.after = other.after
        return True

    def _set(self, data):
        lst = self.tab.s.doc.custom.setdefault('_editor', {}).setdefault('imports', [])
        lst[self.idx] = copy.deepcopy(data)
        self.tab.s.doc.touch()
        self.tab.entry_changed()

    def redo(self):
        if self._first:
            self._first = False
            self.tab.entry_changed()
            return
        self._set(self.after)

    def undo(self):
        self._set(self.before)


# ---------------------------------------------------------------- canvas
class ArtView(QGraphicsView):
    hoverInfo = Signal(str)
    cellsPainted = Signal(str, list, bool)     # tool, cells, value (add/remove)
    selectionChanged = Signal()
    regionDrawn = Signal(object)               # (x0, y0, x1, y1)
    keyPicked = Signal(object)                 # rgb

    def __init__(self, parent=None):
        super().__init__(parent)
        self.scene_ = QGraphicsScene(self)
        self.setScene(self.scene_)
        self.item = QGraphicsPixmapItem()
        self.item.setTransformationMode(Qt.FastTransformation)
        self.scene_.addItem(self.item)
        self.preview = QGraphicsPixmapItem()
        self.preview.setTransformationMode(Qt.FastTransformation)
        self.preview.setVisible(False)
        self.scene_.addItem(self.preview)
        self.setBackgroundBrush(QBrush(QColor(28, 28, 32)))
        self.setMouseTracking(True)
        self.setDragMode(QGraphicsView.NoDrag)
        self.setTransformationAnchor(QGraphicsView.AnchorUnderMouse)
        self.tool = 'select'
        self.img = None
        self.regions = []
        self.active = -1
        self.cell_region = {}      # cell origin -> region index (valid cells)
        self.key_cells = set()     # cells touching key colour (per region grid)
        self.masked = set()
        self.walls = set()
        self.selected = set()
        self._drag = None
        self._paint_val = None
        self._zoom = 2
        self.set_zoom(2)

    def set_zoom(self, z):
        self._zoom = max(1, min(8, int(z)))
        self.resetTransform()
        self.scale(self._zoom, self._zoom)

    def set_image(self, img):
        self.img = img
        self.item.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(img)) if img else QPixmap())
        if img:
            self.scene_.setSceneRect(0, 0, img.width, img.height)
        self.preview.setVisible(False)
        self.viewport().update()

    def set_preview(self, pil_img, origin):
        if pil_img is None:
            self.preview.setVisible(False)
        else:
            self.preview.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(pil_img)))
            self.preview.setPos(origin[0], origin[1])
            self.preview.setVisible(True)
        self.viewport().update()

    def cell_at(self, pos):
        p = self.mapToScene(pos)
        x, y = int(p.x()), int(p.y())
        for i, r in enumerate(self.regions):
            if r.contains(x, y):
                sx = r.x0 + ((r.ox - r.x0) % CELL)
                sy = r.y0 + ((r.oy - r.y0) % CELL)
                cx = sx + (x - sx) // CELL * CELL
                cy = sy + (y - sy) // CELL * CELL
                if cx >= sx and cy >= sy and cx + CELL <= r.x1 and cy + CELL <= r.y1:
                    return (cx, cy), i
        return None, -1

    # ------------------------------------------------------------- draw
    def drawForeground(self, painter, rect):
        if self.img is None:
            return
        painter.save()
        for i, r in enumerate(self.regions):
            pen = QPen(QColor(0, 220, 255) if i == self.active else QColor(0, 160, 200, 140))
            pen.setCosmetic(True)
            pen.setWidth(2 if i == self.active else 1)
            painter.setPen(pen)
            painter.setBrush(Qt.NoBrush)
            painter.drawRect(QRectF(r.x0, r.y0, r.x1 - r.x0, r.y1 - r.y0))
            # grid lines (16 px cells, faint 8 px subtile lines when zoomed)
            sx = r.x0 + ((r.ox - r.x0) % CELL)
            sy = r.y0 + ((r.oy - r.y0) % CELL)
            gp = QPen(QColor(255, 255, 255, 150 if i == self.active else 60))
            gp.setCosmetic(True)
            painter.setPen(gp)
            x = sx
            while x <= r.x1:
                painter.drawLine(x, r.y0, x, r.y1)
                x += CELL
            y = sy
            while y <= r.y1:
                painter.drawLine(r.x0, y, r.x1, y)
                y += CELL
            if self._zoom >= 3 and i == self.active:
                sp = QPen(QColor(255, 255, 255, 40))
                sp.setCosmetic(True)
                painter.setPen(sp)
                x = sx + P.SUB
                while x <= r.x1:
                    painter.drawLine(x, r.y0, x, r.y1)
                    x += CELL
                y = sy + P.SUB
                while y <= r.y1:
                    painter.drawLine(r.x0, y, r.x1, y)
                    y += CELL
        painter.setPen(Qt.NoPen)
        for (x, y) in self.key_cells:
            painter.fillRect(QRectF(x, y, CELL, CELL), QColor(255, 0, 60, 45))
        for (x, y) in self.masked:
            painter.fillRect(QRectF(x, y, CELL, CELL), QColor(10, 10, 14, 170))
        for (x, y) in self.selected:
            painter.fillRect(QRectF(x, y, CELL, CELL), QColor(255, 230, 0, 70))
        wp = QPen(QColor(255, 60, 60))
        wp.setCosmetic(True)
        wp.setWidth(2)
        painter.setPen(wp)
        painter.setBrush(Qt.NoBrush)
        for (x, y) in self.walls:
            painter.drawRect(QRectF(x + 1, y + 1, CELL - 2, CELL - 2))
        if self._drag and self._drag[0] in ('select', 'region') and self._drag[2]:
            (x0, y0), (x1, y1) = self._drag[1], self._drag[2]
            pen = QPen(QColor(255, 230, 0))
            pen.setCosmetic(True)
            painter.setPen(pen)
            painter.drawRect(QRectF(min(x0, x1), min(y0, y1), abs(x1 - x0), abs(y1 - y0)))
        painter.restore()

    # ------------------------------------------------------------ mouse
    def wheelEvent(self, ev):
        if ev.modifiers() & (Qt.ControlModifier | Qt.MetaModifier):
            self.set_zoom(self._zoom + (1 if ev.angleDelta().y() > 0 else -1))
            ev.accept()
            return
        super().wheelEvent(ev)

    def mousePressEvent(self, ev):
        if self.img is None:
            return
        if ev.button() == Qt.MiddleButton:
            self.setDragMode(QGraphicsView.ScrollHandDrag)
            return super().mousePressEvent(ev)
        sp = self.mapToScene(ev.position().toPoint())
        pt = (int(sp.x()), int(sp.y()))
        if self.tool == 'key':
            if 0 <= pt[0] < self.img.width and 0 <= pt[1] < self.img.height:
                self.keyPicked.emit(self.img.getpixel(pt))
            return
        if self.tool in ('select', 'region'):
            if self.tool == 'select' and not (ev.modifiers() & Qt.ShiftModifier):
                self.selected = set()
            self._drag = (self.tool, pt, None)
            return
        cell, _ri = self.cell_at(ev.position().toPoint())
        if cell is None:
            return
        cur = {'mask': self.masked, 'wall': self.walls}[self.tool]
        self._paint_val = cell not in cur
        self._drag = (self.tool, pt, pt)
        self.cellsPainted.emit(self.tool, [cell], self._paint_val)

    def mouseMoveEvent(self, ev):
        cell, ri = self.cell_at(ev.position().toPoint())
        if cell is not None:
            state = ('selected ' if cell in self.selected else '') + \
                    ('MASKED ' if cell in self.masked else '') + \
                    ('WALL ' if cell in self.walls else '') + \
                    ('key colour — never gridded' if cell in self.key_cells else '')
            self.hoverInfo.emit(f'panel {ri + 1} cell at ({cell[0]},{cell[1]}) px  {state}')
        if self._drag:
            sp = self.mapToScene(ev.position().toPoint())
            pt = (int(sp.x()), int(sp.y()))
            tool, a, _b = self._drag
            self._drag = (tool, a, pt)
            if tool in ('mask', 'wall') and cell is not None:
                self.cellsPainted.emit(tool, [cell], self._paint_val)
            self.viewport().update()
        super().mouseMoveEvent(ev)

    def mouseReleaseEvent(self, ev):
        if self.dragMode() == QGraphicsView.ScrollHandDrag:
            self.setDragMode(QGraphicsView.NoDrag)
            return super().mouseReleaseEvent(ev)
        if not self._drag:
            return
        tool, a, b = self._drag
        self._drag = None
        b = b or a
        x0, x1 = sorted((a[0], b[0]))
        y0, y1 = sorted((a[1], b[1]))
        if tool == 'select':
            if x1 - x0 < 2 and y1 - y0 < 2:
                cell, _ri = self.cell_at(ev.position().toPoint())
                if cell and cell in self.cell_region:
                    self.selected ^= {cell}
            else:
                for c in self.cell_region:
                    if x0 <= c[0] + CELL and c[0] < x1 and y0 <= c[1] + CELL and c[1] < y1 \
                            and c[0] + CELL / 2 >= x0 and c[0] + CELL / 2 <= x1 \
                            and c[1] + CELL / 2 >= y0 and c[1] + CELL / 2 <= y1:
                        self.selected.add(c)
            self.selectionChanged.emit()
        elif tool == 'region' and x1 - x0 >= CELL and y1 - y0 >= CELL:
            self.regionDrawn.emit((x0, y0, x1, y1))
        self.viewport().update()


# ------------------------------------------------------------------ tab
class ImportTab(QWidget):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.entry_index = -1
        self.img = None
        self.km = None
        self.fit = None
        self.plans = None
        self._fit_timer = QTimer(self)
        self._fit_timer.setSingleShot(True)
        self._fit_timer.setInterval(250)
        self._fit_timer.timeout.connect(self.refit)
        self._build()
        self.s.structureChanged.connect(self._fill_rooms)
        self.s.structureChanged.connect(self._sync_images)
        self._fill_images()
        self._fill_rooms()

    # ------------------------------------------------------------ build
    def _build(self):
        self.view = ArtView()
        self.view.hoverInfo.connect(lambda t: self.status.setText(t))
        self.view.cellsPainted.connect(self._cells_painted)
        self.view.selectionChanged.connect(self._selection_changed)
        self.view.regionDrawn.connect(self._region_drawn)
        self.view.keyPicked.connect(self._key_picked)
        centre = QWidget()
        cv = QVBoxLayout(centre)
        cv.setContentsMargins(0, 0, 0, 0)
        bar = QHBoxLayout()
        bar.setContentsMargins(6, 4, 6, 0)
        self.tool_group = QButtonGroup(self)
        for i, (name, text, tip) in enumerate((
                ('select', 'Select (S)', 'drag a rectangle of cells to import; click toggles one; Shift adds'),
                ('mask', 'Mask (M)', 'block cells out — they are never imported'),
                ('wall', 'Wall (X)', 'mark cells the player cannot enter'),
                ('region', 'Panel (P)', 'drag a rectangle to add a panel (own grid offset)'),
                ('key', 'Key colour (K)', 'click a colour to toggle it as "background, never art"'))):
            rb = QRadioButton(text)
            rb.setToolTip(tip)
            rb.toggled.connect(lambda on, n=name: on and self._set_tool(n))
            self.tool_group.addButton(rb, i)
            bar.addWidget(rb)
            QShortcut(QKeySequence(text[text.index('(') + 1]), self,
                      activated=lambda b=rb: b.setChecked(True))
            if name == 'select':
                rb.setChecked(True)
        self.same_tile = QCheckBox('Wall: same tile everywhere')
        self.same_tile.setChecked(True)
        bar.addWidget(self.same_tile)
        bar.addStretch(1)
        bar.addWidget(QLabel('Zoom'))
        self.zoom = QComboBox()
        self.zoom.addItems([f'{z}×' for z in range(1, 9)])
        self.zoom.setCurrentIndex(1)
        self.zoom.currentIndexChanged.connect(lambda i: self.view.set_zoom(i + 1))
        bar.addWidget(self.zoom)
        cv.addLayout(bar)
        cv.addWidget(self.view, 1)
        self.status = QLabel('Open a PNG to start.')
        self.status.setSizePolicy(QSizePolicy.Ignored, QSizePolicy.Preferred)
        self.status.setStyleSheet('color: #bbb; padding: 2px 6px;')
        cv.addWidget(self.status)
        for key, dx, dy in ((Qt.Key_Left, -1, 0), (Qt.Key_Right, 1, 0),
                            (Qt.Key_Up, 0, -1), (Qt.Key_Down, 0, 1)):
            QShortcut(QKeySequence(key), self.view, activated=lambda a=dx, b=dy: self._nudge(a, b))
            QShortcut(QKeySequence(Qt.SHIFT | key), self.view,
                      activated=lambda a=dx, b=dy: self._nudge(a * 8, b * 8))

        side = QWidget()
        side.setFixedWidth(430)
        sv = QVBoxLayout(side)
        sv.setContentsMargins(4, 4, 4, 4)

        g = QGroupBox('1 · Image and target room')
        f = QFormLayout(g)
        row = QHBoxLayout()
        self.image_box = QComboBox()
        self.image_box.currentIndexChanged.connect(self._image_chosen)
        self.image_box.setToolTip('Every PNG you open stays in the project (assets/imports/) '
                                  'with its panels, masks and walls — pick one here to go back '
                                  'to it.')
        b = QPushButton('Open PNG…')
        b.setToolTip('Add another PNG — the ones already open stay in the list above.')
        b.clicked.connect(self._open_png)
        rm = QPushButton('Remove')
        rm.setToolTip('Take this PNG off the list (its settings go; tiles already imported '
                      'stay in the rooms). Undoable.')
        rm.clicked.connect(self._remove_image)
        row.addWidget(self.image_box, 1)
        row.addWidget(b)
        row.addWidget(rm)
        f.addRow('image', row)
        self.room_box = QComboBox()
        self.room_box.currentIndexChanged.connect(lambda _i: self._room_changed())
        rrow = QHBoxLayout()
        rrow.addWidget(self.room_box, 1)
        nb = QPushButton('New room…')
        nb.setToolTip('Create a new custom room with its own BLANK tileset (all 128 slots '
                      'free) for this art and make it the target.')
        nb.clicked.connect(self._new_art_room)
        rrow.addWidget(nb)
        f.addRow('into room', rrow)
        self.room_info = QLabel('')
        self.room_info.setWordWrap(True)
        f.addRow(self.room_info)
        sv.addWidget(g)

        g = QGroupBox('2 · Line up the grid (per panel)')
        gv = QVBoxLayout(g)
        self.region_list = QListWidget()
        self.region_list.setMaximumHeight(90)
        self.region_list.currentRowChanged.connect(self._region_chosen)
        gv.addWidget(self.region_list)
        row = QHBoxLayout()
        row.addWidget(QLabel('offset x'))
        self.ox = QSpinBox()
        self.ox.setRange(0, 15)
        self.ox.valueChanged.connect(lambda _v: self._offset_edited())
        row.addWidget(self.ox)
        row.addWidget(QLabel('y'))
        self.oy = QSpinBox()
        self.oy.setRange(0, 15)
        self.oy.valueChanged.connect(lambda _v: self._offset_edited())
        row.addWidget(self.oy)
        b = QPushButton('Auto-align')
        b.setToolTip('Offset with the fewest distinct 8×8 tiles in this panel (advisory — '
                     'your eye decides). Arrow keys nudge by 1 px, Shift+arrow by 8.')
        b.clicked.connect(self._auto_align)
        row.addWidget(b)
        gv.addLayout(row)
        row = QHBoxLayout()
        b = QPushButton('Re-detect panels')
        b.clicked.connect(self._redetect)
        row.addWidget(b)
        b = QPushButton('Delete panel')
        b.clicked.connect(self._delete_region)
        row.addWidget(b)
        b = QPushButton('Select whole panel')
        b.clicked.connect(self._select_region)
        row.addWidget(b)
        gv.addLayout(row)
        self.keys_label = QLabel('')
        self.keys_label.setWordWrap(True)
        gv.addWidget(self.keys_label)
        sv.addWidget(g)

        g = QGroupBox('3 · Palettes (room slots 0-3)')
        gl = QGridLayout(g)
        self.pal_rows = []
        for sl in range(4):
            cur = QLabel()
            keep = QCheckBox('keep')
            keep.setToolTip("Keep this slot's current colours (tiles already using it "
                            'stay as they are); the import fits around it.')
            keep.toggled.connect(lambda _on: self._schedule_fit())
            new = QLabel()
            gl.addWidget(QLabel(f'slot {sl}'), sl, 0)
            gl.addWidget(cur, sl, 1)
            gl.addWidget(keep, sl, 2)
            gl.addWidget(QLabel('→'), sl, 3)
            gl.addWidget(new, sl, 4)
            self.pal_rows.append((cur, keep, new))
        self.show_gbc = QCheckBox('Show as GBC (fitted result over the image)')
        self.show_gbc.toggled.connect(lambda _on: self._update_preview())
        gl.addWidget(self.show_gbc, 4, 0, 1, 5)
        self.fit_label = QLabel('')
        self.fit_label.setWordWrap(True)
        gl.addWidget(self.fit_label, 5, 0, 1, 5)
        self.own1 = QCheckBox('Own colour 1 — three colours per slot (recommended)')
        self.own1.setChecked(True)
        self.own1.setToolTip(
            'The engine normally forces colour 1 of every palette to cream ($6BFF) and '
            'colour 3 to black. Ticked, the room\'s palette is marked "own colour 1" '
            '(S96 FreeColor1Hook, custom rooms only): colour 3 stays black, colours 0-2 '
            'are yours — DWM2 art (black + three colours) then fits exactly.')
        self.own1.toggled.connect(lambda _on: self._schedule_fit())
        gl.addWidget(self.own1, 6, 0, 1, 5)
        rule = QLabel('Unticked: colour 1 is the engine\'s cream, two colours per slot — '
                      'the colour nearest cream is folded onto it.')
        rule.setWordWrap(True)
        rule.setStyleSheet('color: #999;')
        gl.addWidget(rule, 7, 0, 1, 5)
        sv.addWidget(g)

        g = QGroupBox('4 · Import')
        gv = QVBoxLayout(g)
        self.budget = QLabel('')
        self.budget.setWordWrap(True)
        gv.addWidget(self.budget)
        self.strict_walk = QCheckBox('Unmarked cells must be walkable (can cost extra slots)')
        self.strict_walk.setChecked(False)
        self.strict_walk.setToolTip(
            'Off (default): only cells you mark with the Wall tool are placed as walls; '
            'every other graphic goes wherever a slot is free (walkable side first) and '
            'you settle walkability yourself afterwards — Walkability mode on the Rooms '
            'tab, or your own tricks. On: unmarked cells are guaranteed walkable, which '
            'may need a second copy of a graphic on the other side of the threshold.')
        self.strict_walk.toggled.connect(lambda _on: self._update_budget())
        gv.addWidget(self.strict_walk)
        b = QPushButton('Add selected cells to My metatiles')
        b.clicked.connect(lambda: self._import(stamp=False))
        gv.addWidget(b)
        row = QHBoxLayout()
        row.addWidget(QLabel('stamp onto screen'))
        self.dst_screen = QComboBox()
        self.dst_screen.currentIndexChanged.connect(lambda _i: self._dst_changed())
        row.addWidget(self.dst_screen)
        row.addWidget(QLabel('at cell'))
        self.dst_x = QSpinBox()
        self.dst_x.setRange(0, 9)
        self.dst_y = QSpinBox()
        self.dst_y.setRange(0, 7)
        row.addWidget(self.dst_x)
        row.addWidget(self.dst_y)
        gv.addLayout(row)
        self.spill = QCheckBox('spill onto the neighbouring screens (adds screens, '
                               'up to the 4×4 grid)')
        self.spill.setChecked(True)
        self.spill.setToolTip('A selection bigger than one screen continues right/down '
                              'onto the next screens of the room, creating them — the '
                              'way to rebuild a whole DWM2 town. Unticked: cells beyond '
                              'the 10×8 screen are left out.')
        gv.addWidget(self.spill)
        b = QPushButton('Stamp selection onto the room (and add metatiles)')
        b.setToolTip("The selection's top-left cell lands on the chosen screen/cell.")
        b.clicked.connect(lambda: self._import(stamp=True))
        gv.addWidget(b)
        sv.addWidget(g)
        sv.addStretch(1)
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setWidget(side)
        scroll.setFixedWidth(450)

        split = QSplitter()
        split.addWidget(centre)
        split.addWidget(scroll)
        split.setStretchFactor(0, 1)
        root = QHBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.addWidget(split)

    # ------------------------------------------------------------ data
    def imports(self):
        """custom._editor.imports — READ without creating (opening a project
        must not change project.json); writers use imports_mut()."""
        return ((self.s.doc.data.get('custom') or {}).get('_editor') or {}).get('imports', [])

    def imports_mut(self):
        return self.s.doc.custom.setdefault('_editor', {}).setdefault('imports', [])

    def entry(self):
        return self.imports()[self.entry_index] if 0 <= self.entry_index < len(self.imports()) else None

    def _fill_images(self, keep=None):
        self.image_box.blockSignals(True)
        self.image_box.clear()
        for i, e in enumerate(self.imports()):
            if e.get('file'):
                self.image_box.addItem(os.path.basename(e['file']), i)
        self.image_box.blockSignals(False)
        if self.image_box.count():
            self.image_box.setCurrentIndex(min(keep if keep is not None else 0,
                                               self.image_box.count() - 1))
            self._image_chosen(self.image_box.currentIndex())
        else:
            self.entry_index = -1

    def _sync_images(self):
        """After undo/redo of a whole-document command the image list may
        differ from the combo — rebuild it when it does."""
        names = [os.path.basename(e['file']) for e in self.imports() if e.get('file')]
        cur = [self.image_box.itemText(i) for i in range(self.image_box.count())]
        if names != cur:
            keep = min(max(self.entry_index, 0), len(names) - 1) if names else None
            self._fill_images(keep=keep)

    def _fill_rooms(self):
        cur = self.room_box.currentData()
        self.room_box.blockSignals(True)
        self.room_box.clear()
        for r in self.s.doc.rooms:
            if r.get('placeholder') or not r.get('record'):
                continue
            self.room_box.addItem(f"${val(r['mapID']):02X}  {self.s.doc.room_name(r)}", r['id'])
        i = self.room_box.findData(cur)
        self.room_box.setCurrentIndex(max(i, 0))
        self.room_box.blockSignals(False)
        self._room_changed()

    def target_room(self):
        rid = self.room_box.currentData()
        try:
            return self.s.doc.room(rid) if rid else None
        except KeyError:
            return None

    def _new_art_room(self):
        from PySide6.QtWidgets import QInputDialog
        e = self.entry()
        base = os.path.splitext(os.path.basename(e['file']))[0] if e else 'Art room'
        name, ok = QInputDialog.getText(self, 'New room for imported art', 'Room name:',
                                        text=base)
        if not ok or not name.strip():
            return
        src = 0x04
        cur = self.target_room()
        if cur is not None and cur.get('source_mapID') is not None:
            src = val(cur['source_mapID'])
        rend = self.s.renderer
        cmd = C.SnapshotCommand(self.s, f'New room {name.strip()} (blank tileset)',
                                lambda doc: doc.new_room(name.strip(), src, rend,
                                                         blank_tileset=True))
        self.s.undo.push(cmd)
        if cmd.error is None:
            self._fill_rooms()
            i = self.room_box.findData(cmd.result)
            if i >= 0:
                self.room_box.setCurrentIndex(i)

    def _room_changed(self):
        room = self.target_room()
        self.dst_screen.clear()
        if room is None:
            self.room_info.setText('No custom room yet — create one on the Rooms tab '
                                   '(New → "start with a BLANK tileset" is ideal for art).')
            self._show_room_palettes(None)
            self._update_budget()
            return
        for k in self.s.doc.screen_keys(room):
            self.dst_screen.addItem(f'screen {k}', k)
        gfx = self.s.renderer.room_gfx(room)
        tid = self.s.doc.tileset_key(room)
        fc = self.s.doc.free_counts(tid, gfx.threshold)
        self.room_info.setText(
            f"tileset <b>{tid}</b>: {fc['wall']} wall / {fc['walkable']} walkable slots free "
            f"(threshold ${gfx.threshold:02X})")
        self._show_room_palettes(room)
        self._schedule_fit()

    def _dst_changed(self):
        room = self.target_room()
        if room is not None:
            self._show_room_palettes(room)
            self._schedule_fit()

    def slot_use(self, room):
        """{slot: subtiles on any screen/state of the room drawn with it}."""
        out = {}
        r = self.s.renderer
        for k in self.s.doc.screen_keys(room):
            for n in range(len(self.s.doc.states(room, k))):
                try:
                    grid, _note = r.attr_grid(room, k, n)
                except Exception:
                    grid = None
                for row in grid or []:
                    for a in row:
                        out[a & 7] = out.get(a & 7, 0) + 1
        return out

    def room_palettes(self, room):
        k = self.dst_screen.currentData() or 0
        return self.s.renderer.room_palettes(room, k, 0)

    def _show_room_palettes(self, room):
        pals = self.room_palettes(room) if room else None
        for sl, (cur, _keep, _new) in enumerate(self.pal_rows):
            cur.setPixmap(self._swatch(pals[sl]) if pals else QPixmap())

    @staticmethod
    def _swatch(cols):
        img = Image.new('RGB', (4 * 14, 14))
        for i, c in enumerate(cols[:4]):
            img.paste(tuple(c), (i * 14, 0, i * 14 + 14, 14))
        return QPixmap.fromImage(ImageQt.ImageQt(img))

    # ------------------------------------------------------------ image
    def _open_png(self):
        path, _ = QFileDialog.getOpenFileName(self, 'Open PNG', '', 'Images (*.png)')
        if path:
            self.open_png(path)

    def open_png(self, path):
        """Copy the PNG into the project and create its import entry."""
        dst_dir = os.path.join(self.s.doc.project_dir, 'assets', 'imports')
        os.makedirs(dst_dir, exist_ok=True)
        base = os.path.basename(path)
        dst = os.path.join(dst_dir, base)
        if os.path.abspath(path) != os.path.abspath(dst):
            shutil.copy(path, dst)
        rel = os.path.join('assets', 'imports', base)
        for i, e in enumerate(self.imports()):
            if e['file'] == rel:
                self._fill_images(keep=i)
                return i
        img = P.load_rgb(dst)
        keys = P.guess_key_colours(img)
        regs = P.detect_regions(img, keys)
        if not regs:
            regs = [P.Region(0, 0, img.width, img.height, 0, 0, 'whole image')]
        entry = {'file': rel, 'keys': sorted(hexcol(k) for k in keys),
                 'regions': [r.to_json() for r in regs], 'masked': [], 'walls': []}
        lst = self.imports_mut()
        self.entry_index = len(lst)
        lst.append({})
        self.s.undo.push(EditImport(self, 'Open PNG', lambda e: e.update(entry)))
        self._fill_images(keep=len(lst) - 1)
        self.status.setText(
            f'{base}: {img.width}×{img.height}px, {len(regs)} panel(s) detected, '
            f'{len(keys)} key colour(s). Check each panel\'s grid, mask what you '
            'do not want, select cells.')
        return len(lst) - 1

    def _remove_image(self):
        e = self.entry()
        if not e:
            return
        idx = self.entry_index

        def op(doc):
            lst = doc.custom['_editor']['imports']
            lst.pop(idx)
            if not lst:
                doc.custom['_editor'].pop('imports')
                if not doc.custom['_editor']:
                    doc.custom.pop('_editor')
            doc.touch()
        self.s.undo.push(C.SnapshotCommand(self.s, f"Remove {os.path.basename(e['file'])} "
                                           'from the import list', op))
        self.entry_index = -1
        self.img = None
        self.view.set_image(None)
        self.regions = []
        self.view.regions = []
        self._fill_images()

    def _image_chosen(self, i):
        if i < 0:
            return
        self.entry_index = self.image_box.itemData(i)
        e = self.entry()
        if not e:
            return
        self.img = P.load_rgb(os.path.join(self.s.doc.project_dir, e['file']))
        self.view.set_image(self.img)
        self.entry_changed(image=True)

    def entry_changed(self, image=False):
        """Rebuild the view state from the entry (after any edit / undo)."""
        e = self.entry()
        if not e or self.img is None:
            return
        keys = {parse_col(k) for k in e.get('keys', [])}
        if image or self.km is None or getattr(self, '_keys', None) != keys:
            self.km = P.key_mask(self.img, keys)
            self._keys = keys
        self.regions = [P.Region.from_json(r) for r in e.get('regions', [])]
        v = self.view
        v.regions = self.regions
        v.masked = {tuple(c) for c in e.get('masked', [])}
        v.walls = {tuple(c) for c in e.get('walls', [])}
        v.cell_region, v.key_cells = {}, set()
        for ri, r in enumerate(self.regions):
            for (x, y) in r.cell_origins():
                if self.km.crop((x, y, x + CELL, y + CELL)).getextrema()[1]:
                    v.key_cells.add((x, y))
                elif (x, y) not in v.masked:
                    v.cell_region[(x, y)] = ri
        v.selected &= set(v.cell_region)
        cur = self.region_list.currentRow()
        self.region_list.blockSignals(True)
        self.region_list.clear()
        for ri, r in enumerate(self.regions):
            n = sum(1 for c, i in v.cell_region.items() if i == ri)
            self.region_list.addItem(QListWidgetItem(
                f"{r.name or f'panel {ri + 1}'}  {r.x1 - r.x0}×{r.y1 - r.y0}px  "
                f"offset ({r.ox},{r.oy})  {n} cells"))
        self.region_list.blockSignals(False)
        if self.regions:
            self.region_list.setCurrentRow(min(max(cur, 0), len(self.regions) - 1))
        self.keys_label.setText('key colours (never art): ' + ' '.join(
            f'<span style="color:{k}">■</span>' for k in e.get('keys', [])[:24])
            + (f' +{len(e["keys"]) - 24}' if len(e.get('keys', [])) > 24 else ''))
        self._schedule_fit()
        v.viewport().update()

    # ------------------------------------------------------------ grid
    def _region_chosen(self, ri):
        self.view.active = ri
        if 0 <= ri < len(self.regions):
            r = self.regions[ri]
            for sb, v in ((self.ox, r.ox), (self.oy, r.oy)):
                sb.blockSignals(True)
                sb.setValue(v)
                sb.blockSignals(False)
        self.view.viewport().update()

    def _set_region_offset(self, ri, ox, oy):
        def mut(e):
            e['regions'][ri]['offset'] = [ox % CELL, oy % CELL]
        self.s.undo.push(EditImport(self, 'Grid offset', mut))

    def _offset_edited(self):
        ri = self.region_list.currentRow()
        if 0 <= ri < len(self.regions):
            self._set_region_offset(ri, self.ox.value(), self.oy.value())

    def _nudge(self, dx, dy):
        ri = self.region_list.currentRow()
        if 0 <= ri < len(self.regions):
            r = self.regions[ri]
            self._set_region_offset(ri, r.ox + dx, r.oy + dy)
            self._region_chosen(ri)

    def _auto_align(self):
        ri = self.region_list.currentRow()
        if not (0 <= ri < len(self.regions)):
            return
        ox, oy = P.best_offset(self.img, self.regions[ri], self._keys,
                               self.view.masked)
        self._set_region_offset(ri, ox, oy)
        self._region_chosen(ri)
        self.status.setText(f'Auto-align: offset ({ox},{oy}) gives the fewest distinct tiles '
                            '— check it by eye.')

    def _redetect(self):
        regs = P.detect_regions(self.img, self._keys) or \
            [P.Region(0, 0, self.img.width, self.img.height, 0, 0, 'whole image')]
        self.s.undo.push(EditImport(self, 'Detect panels',
                                    lambda e: e.update(regions=[r.to_json() for r in regs])))

    def _delete_region(self):
        ri = self.region_list.currentRow()
        if 0 <= ri < len(self.regions):
            self.s.undo.push(EditImport(self, 'Delete panel',
                                        lambda e: e['regions'].pop(ri)))

    def _region_drawn(self, rect):
        x0, y0, x1, y1 = rect
        r = P.Region(x0, y0, x1, y1, x0 % CELL, y0 % CELL, f'panel {len(self.regions) + 1}')
        self.s.undo.push(EditImport(self, 'Add panel',
                                    lambda e: e['regions'].append(r.to_json())))
        self.region_list.setCurrentRow(len(self.regions) - 1)

    def _select_region(self):
        ri = self.region_list.currentRow()
        self.view.selected = {c for c, i in self.view.cell_region.items() if i == ri}
        self._selection_changed()

    def _key_picked(self, rgb):
        h = hexcol(rgb)

        def mut(e):
            ks = set(e.get('keys', []))
            ks ^= {h}
            e['keys'] = sorted(ks)
        self.s.undo.push(EditImport(self, 'Key colour', mut))

    def _set_tool(self, name):
        self.view.tool = name
        self.view.setCursor(Qt.CrossCursor if name != 'select' else Qt.ArrowCursor)

    def _cells_painted(self, tool, cells, value):
        field = {'mask': 'masked', 'wall': 'walls'}[tool]
        cells = list(cells)
        if tool == 'wall' and self.same_tile.isChecked():
            want = {self.img.crop((x, y, x + CELL, y + CELL)).tobytes() for (x, y) in cells}
            allc = set(self.view.cell_region) | set(self.view.walls)
            cells = [c for c in allc
                     if self.img.crop((c[0], c[1], c[0] + CELL, c[1] + CELL)).tobytes() in want]

        def mut(e):
            cur = {tuple(c) for c in e.get(field, [])}
            if value:
                cur |= set(map(tuple, cells))
            else:
                cur -= set(map(tuple, cells))
            e[field] = sorted([list(c) for c in cur])
        self.s.undo.push(EditImport(self, {'mask': 'Mask cells', 'wall': 'Wall cells'}[tool], mut))

    # ------------------------------------------------------------ fit
    def _selection_changed(self):
        self.view.viewport().update()
        self._schedule_fit()

    def _schedule_fit(self):
        self._fit_timer.start()

    def fit_cells(self):
        """Selected cells, else every valid cell of the active panel."""
        v = self.view
        if v.selected:
            return sorted(v.selected, key=lambda c: (c[1], c[0]))
        ri = self.region_list.currentRow()
        return sorted((c for c, i in v.cell_region.items() if i == ri),
                      key=lambda c: (c[1], c[0]))

    def locked(self):
        room = self.target_room()
        if room is None:
            return {}
        pals = self.room_palettes(room)
        return {sl: [tuple(c) for c in pals[sl]] for sl, (_c, keep, _n) in enumerate(self.pal_rows)
                if keep.isChecked()}

    def refit(self):
        cells = self.fit_cells() if self.img is not None else []
        if not cells:
            self.fit = self.plans = None
            self.fit_label.setText('Select cells (or pick a panel) to fit palettes.')
            for _c, _k, new in self.pal_rows:
                new.setPixmap(QPixmap())
            self._update_preview()
            self._update_budget()
            return
        subs = [s for (x, y) in cells for s in P.cell_subtiles(self.img, x, y)]
        self.fit = P.fit_palettes(subs, locked=self.locked(),
                                  nfree=NFREE_OWN if self.own1.isChecked() else NFREE_FORCED)
        self.plans = P.plan_cells(self.img, cells, self.fit, walls=self.view.walls)
        for sl, (_c, keep, new) in enumerate(self.pal_rows):
            new.setPixmap(self._swatch(self.fit.palettes[sl]))
        pct = 100.0 * self.fit.exact / max(1, self.fit.total)
        self.fit_label.setText(
            f'{len(cells)} cells, {self.fit.total} subtiles: {self.fit.exact} exact '
            f'({pct:.0f}%) — the rest take their nearest colours. Tick "Show as GBC" to look.')
        self._update_preview()
        self._update_budget()

    def _update_preview(self):
        if not self.show_gbc.isChecked() or not self.plans:
            self.view.set_preview(None, (0, 0))
            return
        xs = [p.origin[0] for p in self.plans]
        ys = [p.origin[1] for p in self.plans]
        box = (min(xs), min(ys), max(xs) + CELL, max(ys) + CELL)
        img = P.render_plan(self.plans, self.fit, region=box)
        # cells outside the plan stay transparent: paste over the original
        base = self.img.crop(box).copy()
        mask = Image.new('L', base.size, 0)
        for p_ in self.plans:
            mask.paste(255, (p_.origin[0] - box[0], p_.origin[1] - box[1],
                             p_.origin[0] - box[0] + CELL, p_.origin[1] - box[1] + CELL))
        base.paste(img, (0, 0), mask)
        self.view.set_preview(base, (box[0], box[1]))

    def _update_budget(self):
        room = self.target_room()
        if not self.plans or room is None:
            self.budget.setText('')
            return
        d = P.slot_demand(self.plans, strict_walk=self.strict_walk.isChecked())
        gfx = self.s.renderer.room_gfx(room)
        tid = self.s.doc.tileset_key(room)
        fc = self.s.doc.free_counts(tid, gfx.threshold)
        ok = d['total'] <= fc['total'] and d['wall'] <= fc['wall'] and \
            d['walkable_br'] <= fc['walkable']
        use = self.slot_use(room)
        touched = sorted({s_ for p_ in self.plans for s_ in p_.pals} - set(self.locked()))
        clash = [f'slot {s_} ({use[s_]} subtiles)' for s_ in touched if use.get(s_)]
        warn = ('<br><span style="color:#e0b040">Recolours what the room already draws '
                f"with {', '.join(clash)} — tick “keep” to protect a slot.</span>"
                if clash else '')
        self.budget.setText(
            f"needs at most <b>{d['total']}</b> new tile slots ({d['wall']} wall, "
            f"{d['walkable_br']} walkable, {d['any']} anywhere; identical graphics "
            f"already in the sheet are reused) — the room has {fc['wall']} wall / "
            f"{fc['walkable']} walkable free. "
            + ('<span style="color:#60d060">fits</span>' if ok else
               '<span style="color:#ff6060">DOES NOT FIT — select fewer cells, release '
               'unused vocabulary (Rooms → Tileset tab), or "New room…" above (blank '
               'tileset, 125 slots free)</span>') + warn)

    # ------------------------------------------------------------ import
    def _import(self, stamp):
        room = self.target_room()
        if room is None or not self.plans:
            QMessageBox.information(self, 'Import', 'Pick a target room and select cells first.')
            return
        self.refit()
        plans, fit = self.plans, self.fit
        used = {s_ for p_ in plans for s_ in p_.pals}
        define = [sl for sl in range(4) if sl not in self.locked() and sl in used]
        key = self.dst_screen.currentData() or 0
        stamp_map = None
        if stamp:
            x0 = min(p_.origin[0] for p_ in plans)
            y0 = min(p_.origin[1] for p_ in plans)
            dx, dy = self.dst_x.value(), self.dst_y.value()
            stamp_map = {}
            kc, kr = key % 4, key // 4
            for i, p_ in enumerate(plans):
                ax = dx + (p_.origin[0] - x0) // CELL
                ay = dy + (p_.origin[1] - y0) // CELL
                if 0 <= ax < 10 and 0 <= ay < 8:
                    stamp_map[(key, ax, ay)] = i
                elif self.spill.isChecked():
                    sc, sr = kc + ax // 10, kr + ay // 8
                    if sc < 4 and sr < 4:
                        stamp_map[(sr * 4 + sc, ax % 10, ay % 8)] = i
        own = None
        if 'tileset' not in room['record']:
            own = bytes(self.s.renderer.room_gfx(room).sheet[:2048])
        rid = room['id']
        own1 = self.own1.isChecked()
        strict = self.strict_walk.isChecked()
        name = os.path.splitext(os.path.basename(self.entry()['file']))[0]
        cmd = C.SnapshotCommand(
            self.s, f'Import {len(plans)} cells from {name}',
            lambda doc: doc.import_png_cells(rid, plans, fit.palettes, define, key, 0,
                                             own_sheet=own, stamp=stamp_map,
                                             name_prefix=name, free_color1=own1,
                                             strict_walk=strict))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Import failed', str(cmd.error))
            return
        res = cmd.result
        self.status.setText(
            f"Imported {len(plans)} cells: {res['new_slots']} new tile slots in "
            f"{res['tileset']}, palette {res['palette']}"
            + (f", {res['stamped']} cells stamped" if stamp else '')
            + (f", screens created {res['screens_created']}" if res.get('screens_created') else '')
            + (f", palette set on screens {res['screens_repaletted']}"
               if res.get('screens_repaletted') else '')
            + ' — see the Rooms tab.')
        self._room_changed()
