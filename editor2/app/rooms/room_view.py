"""room_view.py — S173 looking aids for building rooms (EDITOR_DESIGN §5.1 "As built S173").

The user (S173): "Anything else you can suggest to make life easier for me when making
rooms and combining tiles" → "Whole room view - yes. Reference window - YES"; and for
the Still tool: "I want to choose a frame".

  WholeRoomView     every screen of the room joined into one picture on the engine's
                    4×4 screen grid (the screen edges marked, the screen on the canvas
                    outlined); click a screen = edit it. Follows every edit.
  ReferenceWindow   any room — the game's or yours — in a window of its own: the real
                    room canvas, read-only (grid, markers, animation, zoom, hold H);
                    right-click a cell = take it as the brush when that room draws with
                    the same tiles as the room you are editing.
  StillFrameDialog  the pictures a moving cell shows (animate.cell_frames); pick one.

No ROM bytes: the editor only.
"""

from PIL import Image, ImageQt
from PySide6.QtCore import QPointF, QRectF, Qt, QTimer, Signal
from PySide6.QtGui import QBrush, QColor, QFont, QPen, QPixmap
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox,
                               QGraphicsPixmapItem, QGraphicsScene, QGraphicsView, QHBoxLayout,
                               QLabel, QLineEdit, QListWidget, QListWidgetItem, QSpinBox,
                               QToolButton, QVBoxLayout, QWidget)

from editor2.core import page2 as P2
from editor2.core.document import GRID_COLS, metatile_pals
from editor2.core.render_project import SCREEN_H, SCREEN_W
from editor2.app.rooms.canvas import RoomCanvas, ZOOMS, zoom_text

SW, SH = SCREEN_W * 8, SCREEN_H * 8          # one screen in game pixels (160 × 128)
CELL = 16


# ------------------------------------------------------------------ helpers
def screen_keys(session, src):
    """The screens of ('custom', room id) / ('vanilla', mapID), in key order."""
    if src[0] == 'custom':
        return [int(k) for k in session.doc.screen_keys(session.doc.room(src[1]))]
    for mid, _n, scr in session.renderer.vanilla_rooms():
        if mid == src[1]:
            return [int(k) for k in scr]
    return []


def state_count(session, src, key):
    if src[0] == 'custom':
        return max(1, len(session.doc.states(session.doc.room(src[1]), key)))
    return max(1, len(session.renderer.vanilla_steps(src[1], key)))


def screen_image(session, src, key, state=0):
    """PIL RGB picture of one screen in one state (no markers), as the canvas draws it."""
    r = session.renderer
    st = min(int(state), state_count(session, src, key) - 1)
    if src[0] == 'custom':
        return r.render_screen(session.doc.room(src[1]), key, st)
    mid = src[1]
    return r.compose(r.vanilla_gfx(mid).sheet, r.vanilla_screen_grid(mid, key, st),
                     r.vanilla_attr_grid(mid, key, st), r.vanilla_palettes_step(mid, key, st))


def _zoom_box(view_setter):
    box = QComboBox()
    box.addItems([zoom_text(z) for z in ZOOMS])
    box.currentIndexChanged.connect(lambda i: i >= 0 and view_setter(ZOOMS[i]))
    return box


# ------------------------------------------------------------------ the whole room
class _StitchView(QGraphicsView):
    screenClicked = Signal(int)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.scene_ = QGraphicsScene(self)
        self.setScene(self.scene_)
        self.item = QGraphicsPixmapItem()
        self.item.setTransformationMode(Qt.FastTransformation)
        self.scene_.addItem(self.item)
        self.setBackgroundBrush(QBrush(QColor(28, 28, 32)))
        self.setTransformationAnchor(QGraphicsView.AnchorUnderMouse)
        self.setDragMode(QGraphicsView.ScrollHandDrag)
        self.zoom = 2
        self.origin = (0, 0)             # grid (col, row) of the picture's top-left screen
        self.cols = self.rows = 1
        self.keys = []
        self.current = None
        self.edges = True
        self.cells = False
        self.labels = True
        self.jumps = []                  # S175: [(screen, x, y, land_y)] — drawn as arrows

    def set_zoom(self, z):
        self.zoom = z
        self.resetTransform()
        self.scale(z, z)

    def key_at(self, pos):
        p = self.mapToScene(pos)
        c, r = int(p.x() // SW), int(p.y() // SH)
        if p.x() < 0 or p.y() < 0 or c >= self.cols or r >= self.rows:
            return None
        k = (self.origin[1] + r) * GRID_COLS + self.origin[0] + c
        return k if k in self.keys else None

    def mouseDoubleClickEvent(self, ev):
        k = self.key_at(ev.position().toPoint())
        if k is not None:
            self.screenClicked.emit(k)

    def drawForeground(self, painter, rect):
        if not self.keys:
            return
        painter.save()
        if self.cells:
            pen = QPen(QColor(255, 255, 255, 60))
            pen.setCosmetic(True)
            painter.setPen(pen)
            for x in range(0, self.cols * SW + 1, CELL):
                painter.drawLine(x, 0, x, self.rows * SH)
            for y in range(0, self.rows * SH + 1, CELL):
                painter.drawLine(0, y, self.cols * SW, y)
        for k in self.keys:
            c = k % GRID_COLS - self.origin[0]
            r = k // GRID_COLS - self.origin[1]
            rc = QRectF(c * SW, r * SH, SW, SH)
            if self.edges:
                pen = QPen(QColor(255, 200, 40, 200))
                pen.setCosmetic(True)
                pen.setStyle(Qt.DashLine)
                painter.setPen(pen)
                painter.setBrush(Qt.NoBrush)
                painter.drawRect(rc)
            if k == self.current:
                pen = QPen(QColor(80, 245, 255))
                pen.setCosmetic(True)
                pen.setWidth(3)
                painter.setPen(pen)
                painter.drawRect(rc.adjusted(1, 1, -1, -1))
            if self.labels:
                painter.setFont(QFont('Menlo', 6))
                # (the screen's label; S175's jump arrows are drawn after the loop)
                tr = QRectF(rc.left() + 2, rc.top() + 2, 44, 9)
                painter.fillRect(tr, QColor(0, 0, 0, 170))
                painter.setPen(QColor(255, 230, 120))
                painter.drawText(tr, Qt.AlignCenter, f'screen {k}')
        # S175: every jump as an arrow from its cell down to its landing (screen below)
        pen = QPen(QColor(255, 120, 40))
        pen.setCosmetic(True)
        pen.setWidth(2)
        for k, x, y, ly in self.jumps:
            c = k % GRID_COLS - self.origin[0]
            r = k // GRID_COLS - self.origin[1]
            x0 = c * SW + x * CELL + CELL / 2
            y0 = r * SH + y * CELL + CELL / 2
            y1 = (r + 1) * SH + ly * CELL + CELL / 2
            painter.setPen(pen)
            painter.drawLine(QPointF(x0, y0), QPointF(x0, y1))
            painter.drawLine(QPointF(x0, y1), QPointF(x0 - 4, y1 - 5))
            painter.drawLine(QPointF(x0, y1), QPointF(x0 + 4, y1 - 5))
            painter.drawRect(QRectF(x0 - CELL / 2 + 1, y0 - CELL / 2 + 1, CELL - 2, CELL - 2))
        painter.restore()


class WholeRoomView(QWidget):
    """S173: all screens of the room on the canvas as one picture (a window of its own)."""
    screenPicked = Signal(int)

    def __init__(self, session, parent=None):
        super().__init__(parent, Qt.Window)
        self.s = session
        self.src = None
        self.current = None
        self.setWindowTitle('Whole room')
        self.resize(900, 640)
        v = QVBoxLayout(self)
        bar = QHBoxLayout()
        self.title = QLabel('')
        self.title.setStyleSheet('font-weight: bold;')
        bar.addWidget(self.title)
        bar.addStretch(1)
        bar.addWidget(QLabel('State'))
        self.state = QSpinBox()
        self.state.setRange(0, 63)
        self.state.setToolTip('The state every screen shows (a screen with fewer states '
                              'shows its last one); the screen on the canvas shows the '
                              'canvas\'s state when "Follow the canvas" is ticked')
        self.state.valueChanged.connect(lambda _v: self.refresh())
        bar.addWidget(self.state)
        self.follow = QCheckBox('Follow the canvas')
        self.follow.setChecked(True)
        self.follow.setToolTip('The screen and state on the canvas are the ones shown here')
        self.follow.toggled.connect(lambda _v: self.refresh())
        bar.addWidget(self.follow)
        self.edges = QCheckBox('Screen edges')
        self.edges.setChecked(True)
        self.edges.toggled.connect(self._opts)
        bar.addWidget(self.edges)
        self.cells = QCheckBox('Cell grid')
        self.cells.toggled.connect(self._opts)
        bar.addWidget(self.cells)
        zo = QToolButton()
        zo.setText('−')
        bar.addWidget(zo)
        self.zoom = _zoom_box(self._set_zoom)
        bar.addWidget(self.zoom)
        zi = QToolButton()
        zi.setText('+')
        bar.addWidget(zi)
        zf = QToolButton()
        zf.setText('Fit')
        bar.addWidget(zf)
        zo.clicked.connect(lambda: self._step(-1))
        zi.clicked.connect(lambda: self._step(1))
        zf.clicked.connect(self.fit)
        v.addLayout(bar)
        self.view = _StitchView()
        self.view.screenClicked.connect(self.screenPicked)
        v.addWidget(self.view, 1)
        self.note = QLabel('Double-click a screen to edit it on the canvas. Drag to move '
                           'around.')
        self.note.setStyleSheet('color: #bbb;')
        v.addWidget(self.note)
        self.zoom.setCurrentIndex(ZOOMS.index(2))
        self._pending = False
        self._fitted = False
        for sig in (session.layoutChanged, session.structureChanged, session.paletteChanged):
            sig.connect(lambda *_a: self._later())

    def _later(self):
        if not self._pending and self.isVisible():
            self._pending = True
            QTimer.singleShot(30, self.refresh)

    def _opts(self):
        self.view.edges = self.edges.isChecked()
        self.view.cells = self.cells.isChecked()
        self.view.viewport().update()

    def _set_zoom(self, z):
        self.view.set_zoom(z)

    def _step(self, d):
        i = self.zoom.currentIndex()
        self.zoom.setCurrentIndex(max(0, min(len(ZOOMS) - 1, i + d)))

    def fit(self):
        vp = self.view.viewport().size()
        w, h = self.view.cols * SW, self.view.rows * SH
        best = 0
        for i, z in enumerate(ZOOMS):
            if w * z <= vp.width() - 4 and h * z <= vp.height() - 4:
                best = i
        self.zoom.setCurrentIndex(best)

    def show_room(self, src, current=None, state=0):
        """src = ('custom', room id) | ('vanilla', mapID); `current` = the canvas's screen."""
        self.src, self.current = src, current
        if self.follow.isChecked():
            self.state.blockSignals(True)
            self.state.setValue(int(state))
            self.state.blockSignals(False)
        self.refresh()

    def refresh(self):
        self._pending = False
        v = self.view
        if self.src is None:
            return
        try:
            keys = screen_keys(self.s, self.src)
        except Exception:                                        # noqa: BLE001
            keys = []
        if self.src[0] == 'custom':
            try:
                name = self.s.doc.room_name(self.s.doc.room(self.src[1]))
            except Exception:                                    # noqa: BLE001
                name = str(self.src[1])
        else:
            name = self.s.renderer.vanilla_name(self.src[1]) + ' (game room)'
        if not keys:
            self.title.setText(f'{name} — no screens')
            v.keys = []
            v.item.setPixmap(QPixmap())
            return
        cs = [k % GRID_COLS for k in keys]
        rs = [k // GRID_COLS for k in keys]
        c0, r0 = min(cs), min(rs)
        cols, rows = max(cs) - c0 + 1, max(rs) - r0 + 1
        img = Image.new('RGB', (cols * SW, rows * SH), (28, 28, 32))
        st = self.state.value()
        for k in keys:
            try:
                pic = screen_image(self.s, self.src, k, st)
            except Exception:                                    # noqa: BLE001
                continue
            img.paste(pic, ((k % GRID_COLS - c0) * SW, (k // GRID_COLS - r0) * SH))
        v.origin, v.cols, v.rows, v.keys = (c0, r0), cols, rows, list(keys)
        v.jumps = []
        if self.src[0] == 'custom':                     # S175: the room's jumps
            try:
                from editor2.core import jumps as JU
                seen = set()
                for k, _s, _i, e in JU.room_jumps(self.s.doc.room(self.src[1])):
                    t = (k, int(e['x']), int(e['y']), int(e['land_y']))
                    if t not in seen and k + GRID_COLS in keys:
                        seen.add(t)
                        v.jumps.append(t)
            except Exception:                                    # noqa: BLE001
                v.jumps = []
        v.current = self.current
        v.item.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(img)))
        v.scene_.setSceneRect(0, 0, cols * SW, rows * SH)
        v.viewport().update()
        self.title.setText(f'{name} — {len(keys)} screen{"s" if len(keys) != 1 else ""}, '
                           f'state {st}')
        self.setWindowTitle(f'Whole room — {name}')
        if not self._fitted and self.isVisible():
            self._fitted = True
            QTimer.singleShot(0, self.fit)

    def showEvent(self, ev):
        super().showEvent(ev)
        if not self._fitted:
            self._fitted = True
            QTimer.singleShot(0, self.fit)


# ------------------------------------------------------------------ the reference window
class ReferenceCanvas(RoomCanvas):
    """The room canvas, read-only: hover, zoom, pan, ▶ animation, hold H; right-click =
    the cell's metatile (brushPicked); nothing else edits."""

    def is_editable(self):
        return False

    def mousePressEvent(self, ev):
        if ev.button() == Qt.MiddleButton or (ev.button() == Qt.LeftButton and self._space):
            return super().mousePressEvent(ev)
        if ev.button() == Qt.RightButton:
            cell = self._cell_at(ev.position().toPoint())
            if cell is not None and self.tiles is not None:
                self.brushPicked.emit(self.cell_metatile(*cell))
            return
        if ev.button() == Qt.LeftButton:
            cell = self._cell_at(ev.position().toPoint())
            self.selected_marker = None
            self.selected_cell = cell
            self.viewport().update()

    def mouseDoubleClickEvent(self, ev):
        return

    def mouseReleaseEvent(self, ev):
        self._drag = None
        self._sel_drag = None
        self._stroke = None
        super().mouseReleaseEvent(ev)


class ReferenceWindow(QWidget):
    """S173: any room beside the editor, to look at while you build."""
    brushOffered = Signal(object, object)      # metatile, the reference's sheet (bytes)

    def __init__(self, session, parent=None):
        super().__init__(parent, Qt.Window)
        self.s = session
        self.setWindowTitle('Reference')
        self.resize(560, 560)
        v = QVBoxLayout(self)
        top = QHBoxLayout()
        self.search = QLineEdit()
        self.search.setPlaceholderText('Find a room…')
        self.search.setClearButtonEnabled(True)
        self.search.textChanged.connect(self._fill)
        top.addWidget(self.search, 1)
        self.rooms = QComboBox()
        self.rooms.setMinimumContentsLength(22)
        self.rooms.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.rooms.currentIndexChanged.connect(self._room_changed)
        top.addWidget(self.rooms, 2)
        v.addLayout(top)
        row = QHBoxLayout()
        row.addWidget(QLabel('Screen'))
        self.screen = QComboBox()
        self.screen.currentIndexChanged.connect(self._screen_changed)
        row.addWidget(self.screen)
        row.addWidget(QLabel('State'))
        self.state = QComboBox()
        self.state.currentIndexChanged.connect(self._state_changed)
        row.addWidget(self.state)
        row.addStretch(1)
        self.grid = QCheckBox('Grid')
        self.grid.setChecked(True)
        row.addWidget(self.grid)
        self.marks = QCheckBox('Markers')
        self.marks.setChecked(False)
        row.addWidget(self.marks)
        self.play = QToolButton()
        self.play.setText('▶ Play')
        self.play.setCheckable(True)
        self.play.setToolTip('Play the room\'s tile animation')
        row.addWidget(self.play)
        self.on_top = QCheckBox('On top')
        self.on_top.setToolTip('Keep this window above the editor')
        self.on_top.toggled.connect(self._on_top)
        row.addWidget(self.on_top)
        v.addLayout(row)
        zrow = QHBoxLayout()
        zo = QToolButton()
        zo.setText('−')
        zrow.addWidget(zo)
        self.zoom = QComboBox()
        self.zoom.addItems([zoom_text(z) for z in ZOOMS])
        zrow.addWidget(self.zoom)
        zi = QToolButton()
        zi.setText('+')
        zrow.addWidget(zi)
        zf = QToolButton()
        zf.setText('Fit')
        zrow.addWidget(zf)
        zrow.addStretch(1)
        v.addLayout(zrow)
        self.canvas = ReferenceCanvas(session)
        self.canvas.layers['markers'] = False
        self.grid.toggled.connect(lambda on: self.canvas.set_layer('grid', on))
        self.marks.toggled.connect(lambda on: self.canvas.set_layer('markers', on))
        self.play.toggled.connect(self._play)
        zo.clicked.connect(lambda: self.canvas.zoom_step(-1))
        zi.clicked.connect(lambda: self.canvas.zoom_step(1))
        zf.clicked.connect(self.canvas.fit_zoom)
        self.zoom.currentIndexChanged.connect(lambda i: i >= 0 and self.canvas.set_zoom(ZOOMS[i]))
        self.canvas.zoomChanged.connect(self._zoom_shown)
        self.canvas.hoverInfo.connect(lambda t: self.info.setText(t or self._hint))
        self.canvas.brushPicked.connect(
            lambda mt: self.brushOffered.emit(mt, bytes(self.canvas.gfx.sheet)
                                              if self.canvas.gfx is not None else None))
        v.addWidget(self.canvas, 1)
        self._hint = ('Right-click a cell: it becomes your brush when this room draws with '
                      'the same tiles as the room you edit. Hold H = no grid / markers. '
                      '⌘/Ctrl + wheel zooms, space-drag pans.')
        self.info = QLabel(self._hint)
        self.info.setWordWrap(True)
        self.info.setStyleSheet('color: #bbb;')
        v.addWidget(self.info)
        self._zoom_shown(self.canvas.zoom())
        self._fill()

    # ---------------------------------------------------------------- choosing a room
    def _entries(self):
        out = []
        try:
            for r in self.s.doc.rooms:
                out.append((f"Your room: {self.s.doc.room_name(r)}", ('custom', r['id'])))
        except Exception:                                        # noqa: BLE001
            pass
        for mid, name, _scr in self.s.renderer.vanilla_rooms():
            out.append((f'Game room: {name}', ('vanilla', mid)))
        return out

    def _fill(self, *_a):
        want = self.search.text().strip().lower()
        cur = self.rooms.currentData()
        self.rooms.blockSignals(True)
        self.rooms.clear()
        for text, src in self._entries():
            if want and want not in text.lower():
                continue
            self.rooms.addItem(text, src)
        i = self._index_of(cur) if cur is not None else -1
        self.rooms.setCurrentIndex(i if i >= 0 else 0 if self.rooms.count() else -1)
        self.rooms.blockSignals(False)
        now = self.rooms.currentData()
        if (tuple(now) if now is not None else None) != (tuple(cur) if cur is not None else None):
            self._room_changed()

    def show_source(self, src):
        """Open ('custom', id) / ('vanilla', mapID) here."""
        self.search.clear()
        i = self._index_of(src)
        if i >= 0:
            self.rooms.setCurrentIndex(i)

    def _index_of(self, src):
        # QComboBox.findData does not match Python tuples — compare by hand
        for i in range(self.rooms.count()):
            d = self.rooms.itemData(i)
            if d is not None and tuple(d) == tuple(src):
                return i
        return -1

    def source(self):
        return self.rooms.currentData()

    def _room_changed(self, *_a):
        src = self.rooms.currentData()
        self.screen.blockSignals(True)
        self.screen.clear()
        if src is not None:
            try:
                for k in screen_keys(self.s, src):
                    self.screen.addItem(f'{k}', k)
            except Exception:                                    # noqa: BLE001
                pass
        self.screen.blockSignals(False)
        self._screen_changed()

    def _screen_changed(self, *_a):
        src, key = self.rooms.currentData(), self.screen.currentData()
        self.state.blockSignals(True)
        self.state.clear()
        if src is not None and key is not None:
            for i in range(state_count(self.s, src, key)):
                self.state.addItem(f'{i}', i)
        self.state.blockSignals(False)
        self._state_changed()

    def _state_changed(self, *_a):
        src, key = self.rooms.currentData(), self.screen.currentData()
        st = self.state.currentData() or 0
        if src is None or key is None:
            self.canvas.clear()
            return
        if src[0] == 'custom':
            self.canvas.show_custom(src[1], key, st)
        else:
            self.canvas.show_vanilla(src[1], key, st)
        if self.play.isChecked():
            self.canvas.set_preview(True)
        self.setWindowTitle(f'Reference — {self.rooms.currentText().split(": ", 1)[-1]}')

    def _play(self, on):
        self.play.setText('■ Stop' if on else '▶ Play')
        self.canvas.set_preview(on)

    def _zoom_shown(self, z):
        i = min(range(len(ZOOMS)), key=lambda j: abs(ZOOMS[j] - z))
        self.zoom.blockSignals(True)
        self.zoom.setCurrentIndex(i)
        self.zoom.blockSignals(False)

    def _on_top(self, on):
        self.setWindowFlag(Qt.WindowStaysOnTopHint, bool(on))
        self.show()

    def closeEvent(self, ev):
        self.canvas.set_preview(False)
        super().closeEvent(ev)


# ------------------------------------------------------------------ the Still tool's frames
def frame_picture(renderer, sheet, pals, mt, gfx, scale=4):
    """PIL picture (16·scale) of metatile `mt` with its 4 subtiles drawn from `gfx`."""
    sh = bytearray(P2.pad_sheet(bytes(sheet)))
    for t, g in zip(mt['tiles'], gfx):
        k = P2.slot_key(t)
        sh[k * 16:k * 16 + 16] = bytes(g)
    sh = bytes(sh)                     # 4096 bytes: page-2 values find their block too
    img = Image.new('RGB', (16, 16))
    mp = metatile_pals(mt) or [0] * 4
    for i, t in enumerate(mt['tiles']):
        img.paste(renderer.render_tile(sh, int(t), pals, mp[i]), ((i % 2) * 8, (i // 2) * 8))
    return img.resize((16 * scale, 16 * scale), Image.NEAREST)


class StillFrameDialog(QDialog):
    """S173: choose the frame the new still tile keeps."""

    def __init__(self, renderer, sheet, pals, mt, frames, start=0, cell=None, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Still tile — choose a frame')
        v = QVBoxLayout(self)
        where = f' on cell ({cell[0]},{cell[1]})' if cell else ''
        lab = QLabel(
            f'This tile{where} shows <b>{len(frames)}</b> different picture'
            f'{"s" if len(frames) != 1 else ""} while the room animates. Pick the one to keep: '
            'this cell gets a <b>new tile that never moves</b> — also in My metatiles, your '
            'brush for other cells. Other cells drawn with the moving tile keep moving.'
            + (' <i>(at most 64 shown)</i>' if len(frames) >= 64 else ''))
        lab.setWordWrap(True)
        v.addWidget(lab)
        self.list = QListWidget()
        self.list.setViewMode(QListWidget.IconMode)
        self.list.setResizeMode(QListWidget.Adjust)
        self.list.setMovement(QListWidget.Static)
        from PySide6.QtCore import QSize
        self.list.setIconSize(QSize(64, 64))
        self.list.setGridSize(QSize(84, 96))
        self.list.setSpacing(4)
        from PySide6.QtGui import QIcon
        for i, g in enumerate(frames):
            pic = frame_picture(renderer, sheet, pals, mt, g)
            pm = QPixmap.fromImage(ImageQt.ImageQt(pic))
            icon = QIcon(pm)
            icon.addPixmap(pm, QIcon.Selected)      # the true colours when picked (no tint)
            it = QListWidgetItem(icon,
                                 'at rest' if i == 0 else f'frame {i + 1}')
            it.setData(Qt.UserRole, i)
            self.list.addItem(it)
        self.list.setCurrentRow(max(0, min(int(start), len(frames) - 1)))
        self.list.itemDoubleClicked.connect(lambda _it: self.accept())
        self.list.setMinimumSize(420, 220)
        v.addWidget(self.list, 1)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.button(QDialogButtonBox.Ok).setText('Make the still tile')
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def chosen(self):
        return max(0, self.list.currentRow())
