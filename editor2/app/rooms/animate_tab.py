"""animate_tab.py — the Animate tab (S102; replaces the S99 "Make animated").

User S102: "This is NOT UI friendly. I dont … understand the budget, how it
works … I just want animated tiles and for the UI to tell me wtf is
happening … I want to mostly make them myself"; "from-scratch animations with
clearly explained budget. Also if I can set speed that would be great";
"Keep button" (copying a vanilla room's animation).

Workflow: select cells on the canvas (Select tool: click, drag or Shift+click
for several) → Use the selected cells → pick how they move (flip through
frames you draw / drift right / drift left / sway) and how fast → Create.
The box at the top says in plain numbers what the room uses. Engine and data:
editor2/core/tileanim.py (bank $6C); document ops: core/tileanim_doc.py.
"""

from PIL import Image, ImageQt
from PySide6.QtCore import QElapsedTimer, QRect, Qt, QTimer, Signal
from PySide6.QtGui import QColor, QPainter, QPen, QPixmap
from PySide6.QtWidgets import (QButtonGroup, QCheckBox, QComboBox, QFrame, QGridLayout,
                               QHBoxLayout,
                               QLabel, QLineEdit, QListWidget, QListWidgetItem,
                               QPushButton, QRadioButton, QSpinBox, QToolButton,
                               QVBoxLayout, QWidget)

from editor2.core import tileanim as TA
from editor2.core.png_import import decode_2bpp, encode_2bpp

PANEL = 'background:#1d2a2e; color:#cfe; padding:5px; border-radius:3px;'
HOW = ('<b>How it works.</b> The game animates a TILE (an 8×8 graphic of the tileset), '
       'so every place in this room drawn with that tile moves together. Your frames '
       'are stored separately in the ROM — they never use tileset space. The only thing '
       'that costs free tiles is "only the selected cells": the editor then gives those '
       'cells their own copy of each tile so nothing else moves. Speed = how many game '
       'frames each step lasts (the game runs ~60 frames a second; vanilla animations use 32). '
       '<b>Load</b> = how much the room changes each frame compared with what the game can '
       'safely do (8 tiles a frame): under 100% everything runs at the speed you set; over '
       '100% the busiest steps wait a frame or two.')


def _narrow(combo, n=12):
    """Combos size to a short minimum (long item texts must not widen the
    side panel — the S100 r3 lesson); the popup still shows full texts."""
    combo.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
    combo.setMinimumContentsLength(n)
    combo.view().setTextElideMode(Qt.ElideNone)


def _wrap(text, style=None):
    lab = QLabel(text)
    lab.setWordWrap(True)
    lab.setTextFormat(Qt.RichText)
    if style:
        lab.setStyleSheet(style)
    return lab


class FramePad(QWidget):
    """A frame of the selection: rows x cols 8x8 tiles, each in its own
    palette. Left = paint, Shift+left = fill (inside one 8x8 tile), right =
    pick a colour. Read-only frames (frame 1 = the map as drawn) are dimmed."""
    changed = Signal()
    aboutToChange = Signal()
    picked = Signal(int)
    tileClicked = Signal(int)            # index into the flat tile list
    activated = Signal()                 # any click: this frame becomes current
    partPicked = Signal(int, bool)       # Ctrl+click: tile index, whole 16x16 cell?

    def __init__(self, parent=None):
        super().__init__(parent)
        self.rows = self.cols = 1
        self.zoom = 8
        self.px = [[0] * 64]              # flat list of tiles (row-major)
        self.pals = [[(255, 255, 255)] * 4]
        self.colour = 3
        self.editable = True
        self.active = False
        self.part_rect = None            # (x, y, w, h) in pixels: the selected part
        self._last = None
        self._resize()

    def _resize(self):
        self.setFixedSize(self.cols * 8 * self.zoom + 6, self.rows * 8 * self.zoom + 6)

    def set_zoom(self, z):
        self.zoom = z
        self._resize()
        self.update()

    def set_frame(self, rows, cols, px, pals, editable=True):
        self.rows, self.cols = rows, cols
        self.px = [list(p) for p in px]
        self.pals = pals
        self.editable = editable
        self._resize()
        self.update()

    def get(self, x, y):
        k = (y // 8) * self.cols + (x // 8)
        return self.px[k][(y % 8) * 8 + (x % 8)]

    def put(self, x, y, v):
        k = (y // 8) * self.cols + (x // 8)
        self.px[k][(y % 8) * 8 + (x % 8)] = v

    def paintEvent(self, ev):
        p = QPainter(self)
        z = self.zoom
        p.fillRect(self.rect(), QColor(20, 20, 24))
        p.translate(2, 2)
        for y in range(self.rows * 8):
            for x in range(self.cols * 8):
                k = (y // 8) * self.cols + (x // 8)
                p.fillRect(1 + x * z, 1 + y * z, z, z, QColor(*self.pals[k][self.get(x, y)]))
        if z >= 6:
            p.setPen(QPen(QColor(0, 0, 0, 70)))
            for i in range(self.cols * 8 + 1):
                p.drawLine(1 + i * z, 1, 1 + i * z, 1 + self.rows * 8 * z)
            for i in range(self.rows * 8 + 1):
                p.drawLine(1, 1 + i * z, 1 + self.cols * 8 * z, 1 + i * z)
        pen = QPen(QColor(255, 255, 255, 120))
        p.setPen(pen)
        for c in range(0, self.cols + 1):
            p.drawLine(1 + c * 8 * z, 1, 1 + c * 8 * z, 1 + self.rows * 8 * z)
        for r in range(0, self.rows + 1):
            p.drawLine(1, 1 + r * 8 * z, 1 + self.cols * 8 * z, 1 + r * 8 * z)
        pen = QPen(QColor(255, 255, 255, 220))
        pen.setWidth(2)
        p.setPen(pen)
        for c in range(0, self.cols + 1, 2):
            p.drawLine(1 + c * 8 * z, 1, 1 + c * 8 * z, 1 + self.rows * 8 * z)
        for r in range(0, self.rows + 1, 2):
            p.drawLine(1, 1 + r * 8 * z, 1 + self.cols * 8 * z, 1 + r * 8 * z)
        if self.part_rect is not None:
            x0, y0, w0, h0 = self.part_rect
            r = QRect(1 + x0 * z, 1 + y0 * z, w0 * z, h0 * z)
            pen = QPen(QColor(0, 0, 0, 220))
            pen.setWidth(3)
            p.setPen(pen)
            p.drawRect(r)
            pen = QPen(QColor('#6ad8e6'))
            pen.setWidth(2)
            pen.setStyle(Qt.DashLine)
            p.setPen(pen)
            p.drawRect(r)
        p.translate(-2, -2)
        if not self.editable:
            p.fillRect(self.rect(), QColor(20, 20, 24, 110))
        if self.active:
            pen = QPen(QColor('#ffe000'))
            pen.setWidth(3)
            p.setPen(pen)
            p.drawRect(self.rect().adjusted(1, 1, -2, -2))

    def _xy(self, ev):
        pos = ev.position().toPoint()
        x, y = (pos.x() - 3) // self.zoom, (pos.y() - 3) // self.zoom
        return (x, y) if 0 <= x < self.cols * 8 and 0 <= y < self.rows * 8 else None

    def _fill(self, x, y, v):
        ox, oy = (x // 8) * 8, (y // 8) * 8
        old = self.get(x, y)
        if old == v:
            return
        todo = [(x, y)]
        while todo:
            a, b = todo.pop()
            if not (ox <= a < ox + 8 and oy <= b < oy + 8) or self.get(a, b) != old:
                continue
            self.put(a, b, v)
            todo += [(a + 1, b), (a - 1, b), (a, b + 1), (a, b - 1)]

    def mousePressEvent(self, ev):
        self.activated.emit()
        xy = self._xy(ev)
        if xy is None:
            return
        self.tileClicked.emit((xy[1] // 8) * self.cols + xy[0] // 8)
        if ev.button() == Qt.RightButton:
            self.picked.emit(self.get(*xy))
            return
        if ev.modifiers() & Qt.ControlModifier:
            self.partPicked.emit((xy[1] // 8) * self.cols + xy[0] // 8,
                                 bool(ev.modifiers() & Qt.ShiftModifier))
            return
        if not self.editable:
            return
        self.aboutToChange.emit()
        if ev.modifiers() & Qt.ShiftModifier:
            self._fill(*xy, self.colour)
        else:
            self.put(*xy, self.colour)
            self._last = xy
        self.update()
        self.changed.emit()

    def mouseMoveEvent(self, ev):
        if self._last is None or not self.editable or not (ev.buttons() & Qt.LeftButton):
            return
        xy = self._xy(ev)
        if xy and xy != self._last:
            self.put(*xy, self.colour)
            self._last = xy
            self.update()
            self.changed.emit()

    def mouseReleaseEvent(self, ev):
        self._last = None


class AnimateTab(QWidget):
    createRequested = Signal(object)     # dict (see _request)
    replaceRequested = Signal(object)    # dict + 'aid' (edit = replace in one undo step)
    removeRequested = Signal(str)
    useSelectionRequested = Signal()
    showRequested = Signal(str)          # select an animation's cells on the canvas
    stillRequested = Signal(object)      # metatile: stop the VANILLA animation moving it
    status = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.doc = self.room = self.renderer = None
        self.sel = None                  # {'lid','rect','rows','cols','art','pals','key'}
        self.editing = None              # animation id being edited
        self.frames = []                 # flip: frames 1..N-1 as flat tile pixel lists
        self.cur_frame = 0               # 0 = the map as drawn
        self._hist = []
        v = QVBoxLayout(self)
        v.setContentsMargins(4, 4, 4, 4)
        v.setSpacing(5)
        # --- the numbers
        self.budget = _wrap('', PANEL)
        v.addWidget(self.budget)
        self.how_btn = QToolButton()
        self.how_btn.setText('How does this work?')
        self.how_btn.setCheckable(True)
        self.how = _wrap(HOW, 'color:#9ab; padding:2px;')
        self.how.setVisible(False)
        self.how_btn.toggled.connect(self.how.setVisible)
        v.addWidget(self.how_btn)
        v.addWidget(self.how)
        # --- the room's animations
        v.addWidget(_wrap('<b>Animations in this room</b>'))
        self.listw = QListWidget()
        self.listw.setMaximumHeight(84)
        self.listw.setWordWrap(True)
        self.listw.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.listw.setTextElideMode(Qt.ElideNone)
        self.listw.itemSelectionChanged.connect(self._list_sel)
        self.listw.itemDoubleClicked.connect(lambda _i: self._edit_selected())
        v.addWidget(self.listw)
        lr = QHBoxLayout()
        self.b_edit = QPushButton('Edit')
        self.b_edit.setToolTip('Load it below (its cells are selected on the canvas)')
        self.b_edit.clicked.connect(self._edit_selected)
        self.b_remove = QPushButton('Remove')
        self.b_remove.setToolTip('Stop it: its tiles show their first frame again')
        self.b_remove.clicked.connect(self._remove_selected)
        lr.addWidget(self.b_edit)
        lr.addWidget(self.b_remove)
        lr.addStretch(1)
        v.addLayout(lr)
        # --- new / edit
        line = QFrame()
        line.setFrameShape(QFrame.HLine)
        v.addWidget(line)
        self.form_title = _wrap('<b>New animation</b>')
        v.addWidget(self.form_title)
        cr = QHBoxLayout()
        self.b_use = QPushButton('Use the selected cells')
        self.b_use.setToolTip('Select tool (V): click a cell, or drag / Shift+click to select '
                              'several, then press this. Double-clicking a cell does the same.')
        self.b_use.clicked.connect(self.useSelectionRequested.emit)
        cr.addWidget(self.b_use)
        cr.addStretch(1)
        v.addLayout(cr)
        self.cells_lbl = _wrap('No cells yet: select them on the canvas (click, or drag for '
                               'several) and press <i>Use the selected cells</i>.',
                               'color:#ffe000;')
        v.addWidget(self.cells_lbl)
        nr = QHBoxLayout()
        nr.addWidget(QLabel('Name'))
        self.name = QLineEdit()
        self.name.setPlaceholderText('e.g. Cloud')
        nr.addWidget(self.name, 1)
        v.addLayout(nr)
        # motion
        v.addWidget(_wrap('<b>How it moves</b>'))
        self.m_btns = {}
        self.m_grp = QButtonGroup(self)
        mr = QVBoxLayout()
        tips = {
            'flip': 'Plays frames you draw below, one after another (torches, blinking, '
                    'water sparkle, a cloud changing shape).',
            'drift_right': 'The picture scrolls right 1 pixel per step and wraps round inside '
                           'the selected cells (water, conveyor, a cloud drifting in its box).',
            'drift_left': 'Same, to the left.',
            'sway': 'Moves 1-3 pixels one way, then the other (leaves, grass, flags — like '
                    'the GreatTree).',
        }
        for m in TA.MOTIONS:
            b = QRadioButton(TA.MOTION_LABEL[m])
            b.setToolTip(tips[m])
            self.m_grp.addButton(b)
            self.m_btns[m] = b
            mr.addWidget(b)
            b.toggled.connect(lambda on, m=m: on and self._motion_changed())
        self.m_btns['flip'].setChecked(True)
        v.addLayout(mr)
        self.motion_help = _wrap('', 'color:#9ab;')
        v.addWidget(self.motion_help)
        opt = QHBoxLayout()
        self.strip = QCheckBox('the selection moves as one picture')
        self.strip.setChecked(True)
        self.strip.setToolTip('Ticked: pixels flow from tile to tile across each row of the '
                              'selection (at most 2 cells wide). Unticked: each 8×8 tile scrolls '
                              'on its own (seamless textures like water).')
        self.strip.toggled.connect(lambda _on: self._changed())
        opt.addWidget(self.strip)
        self.amp_lbl = QLabel('pixels each way')
        self.amp = QSpinBox()
        self.amp.setRange(1, 3)
        self.amp.valueChanged.connect(lambda _v: self._changed())
        opt.addWidget(self.amp_lbl)
        opt.addWidget(self.amp)
        self.order = QComboBox()
        _narrow(self.order)
        self.order.addItem('loop (1 2 3 1 2 3)', 'loop')
        self.order.addItem('back and forth (1 2 3 2 1)', 'pingpong')
        self.order.currentIndexChanged.connect(lambda _i: self._changed())
        opt.addWidget(self.order)
        opt.addStretch(1)
        v.addLayout(opt)
        # speed
        v.addWidget(_wrap('<b>Speed</b>'))
        sr = QHBoxLayout()
        self.speed_box = QComboBox()
        _narrow(self.speed_box)
        for sp, words in TA.SPEED_PRESETS:
            self.speed_box.addItem(f'{words} — every {sp} frames', sp)
        self.speed_box.addItem('custom…', None)
        self.speed_box.setCurrentIndex(3)
        self.speed_box.currentIndexChanged.connect(self._preset)
        sr.addWidget(self.speed_box, 1)
        v.addLayout(sr)
        sr = QHBoxLayout()
        sr.addWidget(QLabel('exactly'))
        self.speed = QSpinBox()
        self.speed.setRange(TA.SPEED_MIN, TA.SPEED_MAX)
        self.speed.setValue(32)
        self.speed.valueChanged.connect(self._speed_changed)
        sr.addWidget(self.speed)
        sr.addWidget(QLabel('game frames per step'))
        sr.addStretch(1)
        v.addLayout(sr)
        self.speed_lbl = _wrap('', 'color:#9ab;')
        v.addWidget(self.speed_lbl)
        # frames (flip)
        self.frames_w = QWidget()
        fv = QVBoxLayout(self.frames_w)
        fv.setContentsMargins(0, 0, 0, 0)
        fv.setSpacing(3)
        fv.addWidget(_wrap('<b>Frames</b> — all side by side; paint straight on any of '
                           'them. Frame 1 is the map as drawn (fixed). Tiles you leave the '
                           'same do not move. The yellow frame is the one the tools act on.'))
        self.frames_box = QWidget()
        self.strip_grid = QGridLayout(self.frames_box)
        self.strip_grid.setContentsMargins(0, 0, 0, 0)
        self.strip_grid.setHorizontalSpacing(6)
        self.strip_grid.setVerticalSpacing(2)
        self.pads = []                   # FramePad per frame (0 = the map)
        self.pad_lbls = []
        self._zoom = None                # None = automatic
        self._cols_shown = 0
        fv.addWidget(self.frames_box)
        fr2 = QHBoxLayout()
        self.b_add = QPushButton('+ Add frame')
        self.b_add.setToolTip('A new frame after the yellow one, starting as a copy of it')
        self.b_add.clicked.connect(self._add_frame)
        self.b_del = QPushButton('− Remove frame')
        self.b_del.setToolTip('Remove the yellow frame')
        self.b_del.clicked.connect(self._del_frame)
        fr2.addWidget(self.b_add)
        fr2.addWidget(self.b_del)
        fr2.addStretch(1)
        fr2.addWidget(QLabel('Size'))
        for txt, d in (('−', -1), ('+', 1)):
            b = QToolButton()
            b.setText(txt)
            b.setToolTip('Smaller / bigger frames (they wrap to the panel width)')
            b.clicked.connect(lambda _c, d=d: self._zoom_by(d))
            fr2.addWidget(b)
        fv.addLayout(fr2)
        cr2 = QHBoxLayout()
        cr2.addWidget(QLabel('Colour'))
        self.sw = []
        for i in range(4):
            b = QToolButton()
            b.setFixedSize(22, 22)
            b.clicked.connect(lambda _c, i=i: self._set_colour(i))
            cr2.addWidget(b)
            self.sw.append(b)
        self._sw_tile = 0
        cr2.addStretch(1)
        fv.addLayout(cr2)
        hint = QLabel('left = paint · Shift+left = fill · right = pick a colour')
        hint.setStyleSheet('color:#999;')
        fv.addWidget(hint)
        # S102 r3 (user: "Can I still copy or shift individual quadrants?"):
        # the tools act on the selected PART — the whole frame, one 8x8 tile
        # (Ctrl+click) or one 16x16 cell (Ctrl+Shift+click), the same part
        # outlined on every frame
        prow = QHBoxLayout()
        self.part = None                 # None | ('tile', k) | ('cell', tile k of its top-left)
        self.part_lbl = QLabel('')
        self.part_lbl.setStyleSheet('color:#6ad8e6;')
        prow.addWidget(self.part_lbl, 1)
        self.b_whole = QPushButton('Whole frame')
        self.b_whole.setToolTip('Tools act on the whole frame again')
        self.b_whole.clicked.connect(lambda: self._set_part(None))
        prow.addWidget(self.b_whole)
        fv.addLayout(prow)
        phint = QLabel('Ctrl+click = pick that 8×8 tile · Ctrl+Shift+click = that 16×16 cell '
                       '· Ctrl+click it again = whole frame')
        phint.setWordWrap(True)
        phint.setStyleSheet('color:#999;')
        fv.addWidget(phint)
        self.clip = None                 # (w, h, rows of colour indices)
        tr = QHBoxLayout()
        tr2 = QHBoxLayout()
        tr3 = QHBoxLayout()
        self.tool_btns = {}
        for key, text, tip in (('l', '◀', 'Shift the selected part 1 px left (wraps inside it)'),
                               ('r', '▶', 'Shift the selected part 1 px right (wraps inside it)'),
                               ('u', '▲', 'Shift the selected part 1 px up (wraps inside it)'),
                               ('d', '▼', 'Shift the selected part 1 px down (wraps inside it)'),
                               ('copy', 'Copy', 'Copy the selected part of the yellow frame '
                                                '(frame 1 too)'),
                               ('paste', 'Paste', 'Paste into the selected part of the yellow frame. '
                                                  'A smaller piece repeats to fill it (one tile '
                                                  'pasted on a cell fills its 4 tiles); a bigger '
                                                  'one is cut to size from its top-left.'),
                               ('clear', 'Clear', 'Fill the selected part with the chosen colour'),
                               ('fh', 'Mirror ↔', 'Mirror the selected part left-right'),
                               ('fv', 'Mirror ↕', 'Mirror the selected part top-bottom'),
                               ('prev', 'Copy previous', 'The selected part of the yellow frame '
                                                         'becomes a copy of the frame before it'),
                               ('undo', 'Undo', 'Undo the last paint or tool on the frames')):
            b = QPushButton(text)
            b.setToolTip(tip)
            b.clicked.connect(lambda _c, k=key: self._tool(k))
            (tr if key in ('l', 'r', 'u', 'd') else
             tr2 if key in ('copy', 'paste', 'clear') else tr3).addWidget(b)
            self.tool_btns[key] = b
        tr.insertWidget(0, QLabel('Shift'))
        tr.addStretch(1)
        fv.addLayout(tr)
        fv.addLayout(tr2)
        fv.addLayout(tr3)
        v.addWidget(self.frames_w)
        # preview
        pr = QHBoxLayout()
        pr.addWidget(QLabel('Preview'))
        self.preview = QLabel()
        self.preview.setMinimumSize(32, 32)
        pr.addWidget(self.preview)
        pr.addStretch(1)
        v.addLayout(pr)
        # scope
        v.addWidget(_wrap('<b>What moves</b>'))
        self.scope_here = QRadioButton('only the selected cells')
        self.scope_all = QRadioButton('every place in this room drawn with these tiles')
        self.scope_here.setChecked(True)
        sg = QButtonGroup(self)
        sg.addButton(self.scope_here)
        sg.addButton(self.scope_all)
        self.scope_here.toggled.connect(lambda _on: self._changed())
        v.addWidget(self.scope_here)
        v.addWidget(self.scope_all)
        self.result = _wrap('', 'color:#6ad8e6;')
        v.addWidget(self.result)
        self.problem = _wrap('', 'color:#ffb060; font-weight:bold;')
        v.addWidget(self.problem)
        br = QHBoxLayout()
        self.b_create = QPushButton('Create animation')
        self.b_create.setStyleSheet('font-weight:bold;')
        self.b_create.clicked.connect(self._create)
        self.b_cancel = QPushButton('Cancel editing')
        self.b_cancel.clicked.connect(self.cancel_edit)
        br.addWidget(self.b_create)
        br.addWidget(self.b_cancel)
        br.addStretch(1)
        v.addLayout(br)
        # --- vanilla copy (the kept button)
        line2 = QFrame()
        line2.setFrameShape(QFrame.HLine)
        v.addWidget(line2)
        self.van_btn = QToolButton()
        self.van_btn.setText('Copy a vanilla room\'s animation…')
        self.van_btn.setCheckable(True)
        self.van_btn.setToolTip('Optional: also play the animation of one of the game\'s own '
                                'rooms here (it moves fixed tiles of the sheet — mostly useful '
                                'for rooms copied from that room). Your own animations keep '
                                'working next to it.')
        v.addWidget(self.van_btn)
        self.van_box = QWidget()
        vv = QVBoxLayout(self.van_box)
        vv.setContentsMargins(12, 0, 0, 0)
        self.van_lay = vv
        self.van_state = _wrap('', 'color:#9ab;')
        vv.addWidget(self.van_state)
        self.still_b = QPushButton('Make the selected cell still')
        self.still_b.setToolTip('The copied vanilla animation moves this cell: give it a still '
                                'copy of its tiles (other cells keep moving).')
        self.still_b.clicked.connect(lambda: self._still_mt and self.stillRequested.emit(self._still_mt))
        vv.addWidget(self.still_b)
        self._still_mt = None
        self.van_box.setVisible(False)
        self.van_btn.toggled.connect(self.van_box.setVisible)
        v.addWidget(self.van_box)
        v.addStretch(1)
        # preview clock
        self._clock = QElapsedTimer()
        self._clock.start()
        self.timer = QTimer(self)
        self.timer.setInterval(33)
        self.timer.timeout.connect(self._tick)
        self.timer.start()
        self._ready = True
        self._set_form_enabled(False)
        self._motion_changed()
        self._speed_changed(32)

    # ------------------------------------------------------------ vanilla combo
    def attach_vanilla_controls(self, combo, note):
        """The inspector's vanilla-source combo + note (S99 logic) live here,
        behind the "Copy a vanilla room's animation…" button (user S102)."""
        self.van_lay.insertWidget(0, note)
        self.van_lay.insertWidget(0, combo)

    # ------------------------------------------------------------ room
    def show_room(self, doc, room, renderer=None):
        rid = room.get('id') if room else None
        if self.room is not None and self.room.get('id') != rid:
            self.sel = None
            self.editing = None
        self.doc, self.room = doc, room
        if renderer is not None:
            self.renderer = renderer
        self._fill_list()
        self._update_budget()
        if room is None or not room.get('record'):
            self._set_form_enabled(False)
            self.cells_lbl.setText('Vanilla room — "Make editable" first (the Anim outline '
                                   'shows what the game already animates here).')
            self.b_use.setEnabled(False)
        else:
            self.b_use.setEnabled(True)
            if self.sel is None:
                self._set_form_enabled(False)
        info = doc.room_animation(room) if room else None
        if info and info['map'] is not None:
            self.van_state.setText(f"Copied here now: <b>${info['map']:02X}</b> — {info['text']}.")
        else:
            self.van_state.setText('No vanilla animation copied here.')
        self._refresh_form()

    def _fill_list(self):
        self.listw.blockSignals(True)
        self.listw.clear()
        for it in (self.doc.tile_anims(self.room) if self.doc and self.room else []):
            n = len(TA.slots_of(it))
            sp = int(it.get('speed', 32))
            words = next((w for s, w in TA.SPEED_PRESETS if s == sp), f'every {sp} frames')
            txt = (f"{it.get('name') or it.get('id')} — {TA.MOTION_LABEL[it['motion']].lower()}, "
                   f"{words}, {n} tile{'s' if n != 1 else ''}"
                   + ('' if it.get('scope') != 'everywhere' else ' (everywhere)'))
            li = QListWidgetItem(txt)
            li.setData(Qt.UserRole, it.get('id'))
            self.listw.addItem(li)
        if not self.listw.count():
            li = QListWidgetItem('(none yet)')
            li.setFlags(Qt.NoItemFlags)
            self.listw.addItem(li)
        self.listw.blockSignals(False)
        self._list_sel()

    def _list_sel(self):
        aid = self._list_aid()
        self.b_edit.setEnabled(aid is not None)
        self.b_remove.setEnabled(aid is not None)

    def _list_aid(self):
        it = self.listw.currentItem()
        return it.data(Qt.UserRole) if it is not None else None

    def _edit_selected(self):
        aid = self._list_aid()
        if aid:
            self.showRequested.emit(aid)

    def _remove_selected(self):
        aid = self._list_aid()
        if aid:
            self.removeRequested.emit(aid)

    def _update_budget(self):
        if self.doc is None or self.room is None or not self.room.get('record'):
            self.budget.setText('<b>Animated tiles</b> — open a custom room.')
            return
        b = self.doc.tile_anim_budget(self.room)
        kb = lambda n: f'{n / 1024:.1f} KB'
        extra = ''
        if self.sel is not None and self._pending() is not None:
            p = self._pending()
            extra = (f"<br><b>With this new animation:</b> load {p['load']:.0f}%, "
                     f"{p['copies']} free tile(s) used, +{kb(p['rom'])} frame storage")
        load_col = '#8f8' if b['load_pct'] <= 60 else '#ff8' if b['load_pct'] <= 100 else '#f88'
        self.budget.setText(
            f"<b>This room:</b> {b['items']} animation{'s' if b['items'] != 1 else ''}, "
            f"{b['tiles']} tile{'s' if b['tiles'] != 1 else ''} changing<br>"
            f"<b>Load:</b> <span style='color:{load_col}'>{b['load_words']}</span><br>"
            f"<b>Free tiles on this tileset:</b> {b['free_tiles']} (only \"only the selected "
            f"cells\" uses them; frames never do)<br>"
            f"<b>Frame storage (whole project):</b> {kb(b['rom_used'])} of {kb(b['rom_cap'])}"
            f" · animation groups here: {b['groups']} of {b['groups_cap']}" + extra)

    # ------------------------------------------------------------ selection
    def load_selection(self, sel, anim=None):
        """sel = {'lid', 'rect' (c0,r0,c1,r1), 'art' [flat tile bytes, rows*cols],
        'pals' [flat per-tile RGB x4], 'rows', 'cols', 'where' text}.
        anim = an existing animation to edit (its frames are loaded)."""
        self.sel = dict(sel)
        self.part = None
        self.editing = anim.get('id') if anim else None
        self._hist = []
        self.frames = []
        self.cur_frame = 0
        if anim:
            self.name.setText(anim.get('name') or '')
            self.m_btns[anim['motion']].setChecked(True)
            sp = int(anim.get('speed', 32))
            self._set_speed(sp)
            self.strip.setChecked(bool(anim.get('strip', True)))
            self.amp.setValue(int(anim.get('amplitude', 1)))
            i = self.order.findData(anim.get('order', 'loop'))
            self.order.setCurrentIndex(max(0, i))
            (self.scope_all if anim.get('scope') == 'everywhere' else self.scope_here).setChecked(True)
            if anim['motion'] == 'flip':
                slots = TA.slots_of(anim)
                pos = sel.get('slots') or []
                for f in anim.get('frames') or []:
                    frame = []
                    for k, art in enumerate(sel['art']):
                        s = pos[k] if k < len(pos) else None
                        if s in slots:
                            frame.append(decode_2bpp(bytes.fromhex(f[slots.index(s)])))
                        else:
                            frame.append(decode_2bpp(art))
                    self.frames.append(frame)
                if self.frames:
                    self.cur_frame = 1
        else:
            self.name.setText('')
            self.frames = [[decode_2bpp(a) for a in sel['art']]] if self._motion() == 'flip' else []
            if self.frames:
                self.cur_frame = 1
        self.form_title.setText('<b>Editing: ' + (anim.get('name') or anim.get('id')) + '</b>'
                                if anim else '<b>New animation</b>')
        self.b_create.setText('Save changes' if anim else 'Create animation')
        self.b_cancel.setVisible(bool(anim))
        self.cells_lbl.setText(f"<b>{sel['cols'] // 2}×{sel['rows'] // 2} cell(s)</b> {sel.get('where', '')}")
        self._set_form_enabled(True)
        self._rebuild_frame_btns()
        self._show_frame()
        self._set_part(None)
        self._changed()

    def cancel_edit(self):
        self.editing = None
        self.sel = None
        self.frames = []
        self.form_title.setText('<b>New animation</b>')
        self.b_create.setText('Create animation')
        self.b_cancel.setVisible(False)
        self.cells_lbl.setText('No cells yet: select them on the canvas (click, or drag for '
                               'several) and press <i>Use the selected cells</i>.')
        self._set_form_enabled(False)
        self._update_budget()

    def set_still_candidate(self, mt):
        """The selected cell moves with the copied vanilla animation (or None)."""
        self._still_mt = mt
        self.still_b.setEnabled(mt is not None)

    def _set_form_enabled(self, on):
        for w in list(self.m_btns.values()) + [self.strip, self.amp, self.order, self.speed_box,
                                               self.speed, self.frames_w, self.scope_here,
                                               self.scope_all, self.b_create, self.name]:
            w.setEnabled(on)
        if not on:
            self.b_cancel.setVisible(False)
            self.result.setText('')
            self.problem.setText('')

    # ------------------------------------------------------------ form
    def _motion(self):
        return next(m for m, b in self.m_btns.items() if b.isChecked())

    def _motion_changed(self):
        if not getattr(self, '_ready', False):
            return
        m = self._motion()
        self.frames_w.setVisible(m == 'flip')
        self.order.setVisible(m == 'flip')
        self.strip.setVisible(m != 'flip')
        self.amp.setVisible(m == 'sway')
        self.amp_lbl.setVisible(m == 'sway')
        self.motion_help.setText({
            'flip': 'Draw the frames below. Each step shows the next frame.',
            'drift_right': 'Each step moves the picture 1 pixel right; what leaves on the right '
                           'comes back on the left (inside the selected cells).',
            'drift_left': 'Each step moves the picture 1 pixel left, wrapping round.',
            'sway': 'Each step moves 1 pixel: over, back, the other way, back.',
        }[m])
        if m == 'flip' and self.sel is not None and not self.frames:
            self.frames = [[decode_2bpp(a) for a in self.sel['art']]]
            self.cur_frame = 1
            self._rebuild_frame_btns()
            self._show_frame()
        self._changed()

    def _preset(self, _i):
        sp = self.speed_box.currentData()
        if sp is not None:
            self.speed.blockSignals(True)
            self.speed.setValue(sp)
            self.speed.blockSignals(False)
            self._speed_changed(sp)

    def _set_speed(self, sp):
        self.speed.setValue(sp)
        self._speed_changed(sp)

    def _speed_changed(self, sp):
        if not getattr(self, '_ready', False):
            return
        i = self.speed_box.findData(sp)
        self.speed_box.blockSignals(True)
        self.speed_box.setCurrentIndex(i if i >= 0 else self.speed_box.count() - 1)
        self.speed_box.blockSignals(False)
        m = self._motion()
        what = {'flip': 'frame', 'sway': 'pixel', 'drift_right': 'pixel',
                'drift_left': 'pixel'}[m]
        self.speed_lbl.setText(f'One {what} {TA.speed_words(sp)}.')
        self._changed()

    # ------------------------------------------------------------ frames
    @property
    def pad(self):
        """The current (yellow) frame's painter."""
        if not self.pads:
            return self._pad0 if hasattr(self, '_pad0') else FramePad()
        return self.pads[min(self.cur_frame, len(self.pads) - 1)]

    def _auto_zoom(self):
        if self._zoom is not None:
            return self._zoom
        w = self.sel['cols'] * 8 if self.sel else 16
        return max(2, min(10, 170 // max(1, w)))

    def _zoom_by(self, d):
        self._zoom = max(2, min(12, self._auto_zoom() + d))
        for p in self.pads:
            p.set_zoom(self._zoom)
        self._layout_strip(force=True)

    def _rebuild_frame_btns(self):
        """(Re)build the side-by-side painters: frame 1 (the map) + frames."""
        for w in self.pads + self.pad_lbls:
            w.hide()                      # a deleteLater'd widget would still paint
            w.setParent(None)
            w.deleteLater()
        self.pads, self.pad_lbls = [], []
        if self.sel is None:
            return
        n = 1 + len(self.frames)
        z = self._auto_zoom()
        colour = getattr(self, '_colour', 3)
        for i in range(n):
            lab = QLabel(f'{i + 1}' + (' — map (fixed)' if i == 0 else ''), self.frames_box)
            lab.setStyleSheet('color:#bbb;')
            pad = FramePad(self.frames_box)
            pad.zoom = z
            pad.colour = colour
            pad.set_frame(self.sel['rows'], self.sel['cols'], self._frame_px(i),
                          self.sel['pals'], editable=i > 0)
            pad.changed.connect(lambda i=i: self._pad_changed(i))
            pad.aboutToChange.connect(self._snap)
            pad.picked.connect(self._set_colour)
            pad.tileClicked.connect(self._tile_clicked)
            pad.activated.connect(lambda i=i: self._pick_frame(i))
            pad.partPicked.connect(self._pick_part)
            pad.part_rect = self._part_rect()
            self.pads.append(pad)
            self.pad_lbls.append(lab)
        self._cols_shown = 0
        self._layout_strip(force=True)
        self.b_add.setEnabled(n < TA.MAX_FRAMES)
        self._pick_frame(min(self.cur_frame, n - 1))

    def _layout_strip(self, force=False):
        if not self.pads:
            return
        avail = max(120, (self.width() or 380) - 16)
        pw = self.pads[0].width() + 6
        cols = max(1, avail // pw)
        if cols == self._cols_shown and not force:
            return
        self._cols_shown = cols
        while self.strip_grid.count():
            self.strip_grid.takeAt(0)
        for i, (pad, lab) in enumerate(zip(self.pads, self.pad_lbls)):
            r, c = (i // cols) * 2, i % cols
            self.strip_grid.addWidget(lab, r, c, Qt.AlignLeft | Qt.AlignBottom)
            self.strip_grid.addWidget(pad, r + 1, c, Qt.AlignLeft | Qt.AlignTop)
            pad.show()
            lab.show()
        self.strip_grid.setColumnStretch(cols, 1)

    def resizeEvent(self, ev):
        super().resizeEvent(ev)
        self._layout_strip()

    def _pick_frame(self, i):
        self.cur_frame = i
        for k, p in enumerate(self.pads):
            if p.active != (k == i):
                p.active = k == i
                p.update()
        self.b_del.setEnabled(i > 0 and len(self.frames) > 1)
        self._tile_clicked(self._sw_tile)

    def _frame_px(self, i):
        if i == 0:
            return [decode_2bpp(a) for a in self.sel['art']]
        return self.frames[i - 1]

    def _show_frame(self):
        """Refresh every painter from the frames (after a tool / undo)."""
        if self.sel is None:
            return
        if len(self.pads) != 1 + len(self.frames):
            self._rebuild_frame_btns()
            return
        for i, p in enumerate(self.pads):
            p.set_frame(self.sel['rows'], self.sel['cols'], self._frame_px(i),
                        self.sel['pals'], editable=i > 0)
        self._pick_frame(self.cur_frame)

    def _add_frame(self):
        if self.sel is None or 1 + len(self.frames) >= TA.MAX_FRAMES:
            return
        self._snap()
        self.frames.insert(self.cur_frame, [list(p) for p in self._frame_px(self.cur_frame)])
        self.cur_frame += 1
        self._rebuild_frame_btns()
        self._changed()

    def _del_frame(self):
        if self.cur_frame == 0 or len(self.frames) <= 1:
            return
        self._snap()
        del self.frames[self.cur_frame - 1]
        self.cur_frame = min(self.cur_frame, len(self.frames))
        self._rebuild_frame_btns()
        self._changed()

    def _pad_changed(self, i=None):
        i = self.cur_frame if i is None else i
        if 0 < i <= len(self.frames):
            self.frames[i - 1] = [list(p) for p in self.pads[i].px]
        self._changed()

    def _snap(self):
        self._hist.append(([[list(p) for p in f] for f in self.frames], self.cur_frame))
        del self._hist[:-100]

    def _part_rect(self):
        """(x, y, w, h) pixels of the selected part, or None = the whole frame."""
        if self.part is None or self.sel is None:
            return None
        cols = self.sel['cols']
        kind, k = self.part
        tx, ty = k % cols, k // cols
        if kind == 'tile':
            return (tx * 8, ty * 8, 8, 8)
        return ((tx // 2) * 16, (ty // 2) * 16, 16, 16)

    def _set_part(self, part):
        self.part = part
        r = self._part_rect()
        for p in self.pads:
            p.part_rect = r
            p.update()
        if part is None:
            self.part_lbl.setText('Tools act on: the whole frame')
        else:
            kind, k = part
            cols = self.sel['cols']
            tx, ty = k % cols, k // cols
            self.part_lbl.setText(
                f'Tools act on: 8×8 tile (column {tx + 1}, row {ty + 1})' if kind == 'tile' else
                f'Tools act on: 16×16 cell (column {tx // 2 + 1}, row {ty // 2 + 1})')
        self.b_whole.setEnabled(part is not None)

    def _pick_part(self, k, cell):
        kind = 'cell' if cell else 'tile'
        if self.sel is not None and cell:
            cols = self.sel['cols']
            k = ((k // cols) // 2 * 2) * cols + (k % cols) // 2 * 2   # the cell's top-left tile
        new = (kind, k)
        self._set_part(None if self.part == new else new)

    def _grid(self, i):
        """Frame i as rows of colour indices (W x H)."""
        cols = self.sel['cols']
        px = self._frame_px(i)
        return [[px[(y // 8) * cols + x // 8][(y % 8) * 8 + x % 8]
                 for x in range(cols * 8)] for y in range(self.sel['rows'] * 8)]

    def _put_grid(self, i, grid):
        cols, rows = self.sel['cols'], self.sel['rows']
        self.frames[i - 1] = [[grid[(k // cols) * 8 + j // 8][(k % cols) * 8 + j % 8]
                               for j in range(64)] for k in range(rows * cols)]

    def _tool(self, key):
        if self.sel is None:
            return
        if key == 'undo':
            if not self._hist:
                self.status.emit('Nothing to undo on these frames.')
                return
            self.frames, self.cur_frame = self._hist.pop()
            self._rebuild_frame_btns()
            self._show_frame()
            self._changed()
            return
        W, H = self.sel['cols'] * 8, self.sel['rows'] * 8
        x0, y0, w, h = self._part_rect() or (0, 0, W, H)
        cur = self._grid(self.cur_frame)
        part = [row[x0:x0 + w] for row in cur[y0:y0 + h]]
        what = 'the whole frame' if self.part is None else self.part_lbl.text().split(': ', 1)[-1]
        if key == 'copy':
            self.clip = (w, h, part)
            self.status.emit(f'Copied {what} of frame {self.cur_frame + 1}.')
            return
        if self.cur_frame == 0:
            self.status.emit('Frame 1 is the map as drawn — click another frame to change it '
                             '(Copy works on frame 1).')
            return
        if key == 'paste' and self.clip is None:
            self.status.emit('Copy a part first.')
            return
        self._snap()
        if key == 'l':
            part = [r[1:] + r[:1] for r in part]
        elif key == 'r':
            part = [r[-1:] + r[:-1] for r in part]
        elif key == 'u':
            part = part[1:] + part[:1]
        elif key == 'd':
            part = part[-1:] + part[:-1]
        elif key == 'fh':
            part = [r[::-1] for r in part]
        elif key == 'fv':
            part = part[::-1]
        elif key == 'clear':
            c = getattr(self, '_colour', 3)
            part = [[c] * w for _ in range(h)]
        elif key == 'prev':
            prev = self._grid(self.cur_frame - 1)
            part = [row[x0:x0 + w] for row in prev[y0:y0 + h]]
        elif key == 'paste':
            cw, ch, cg = self.clip
            part = [[cg[y % ch][x % cw] for x in range(w)] for y in range(h)]
        for y in range(h):
            cur[y0 + y][x0:x0 + w] = part[y]
        self._put_grid(self.cur_frame, cur)
        self._show_frame()
        self._changed()
        if key == 'paste':
            self.status.emit(f'Pasted into {what} of frame {self.cur_frame + 1} (colour numbers; '
                             'a tile with another palette shows them in its own colours).')

    def _tile_clicked(self, k):
        self._sw_tile = k
        if self.sel is None:
            return
        pal = self.sel['pals'][min(k, len(self.sel['pals']) - 1)]
        for i, b in enumerate(self.sw):
            b.setStyleSheet(f'background: rgb{tuple(pal[i])}; border: 2px solid '
                            f"{'#ffe000' if i == getattr(self, '_colour', 3) else '#333'};")

    def _set_colour(self, i):
        self._colour = i
        for p in self.pads:
            p.colour = i
        self._tile_clicked(self._sw_tile)

    # ------------------------------------------------------------ the check
    def _frames_grid(self):
        """flip frames as grids rows x cols of 16-byte tiles (the doc API)."""
        rows, cols = self.sel['rows'], self.sel['cols']
        return [[[encode_2bpp(f[r * cols + c]) for c in range(cols)] for r in range(rows)]
                for f in self.frames]

    def _request(self):
        m = self._motion()
        return {'lid': self.sel['lid'], 'rect': tuple(self.sel['rect']), 'motion': m,
                'speed': self.speed.value(),
                'frames': self._frames_grid() if m == 'flip' else None,
                'order': self.order.currentData(), 'strip': self.strip.isChecked(),
                'amplitude': self.amp.value(),
                'name': self.name.text().strip() or TA.MOTION_LABEL[m],
                'private': self.scope_here.isChecked()}

    def _pending(self):
        return getattr(self, '_pend', None)

    def _changed(self):
        if not getattr(self, '_ready', False):
            return
        self._pend = None
        if self.doc is None or self.room is None or self.sel is None:
            self._update_budget()
            return
        req = self._request()
        room = self.room
        if self.editing:
            room = dict(room)
            room['tile_anims'] = [a for a in room.get('tile_anims') or []
                                  if a.get('id') != self.editing]
        try:
            info = self.doc.anim_selection(room, req['lid'], req['rect'], req['motion'],
                                           req['frames'], req['strip'], req['private'])
        except Exception as e:
            info = {'problem': str(e), 'moving': [], 'copies': 0, 'free': 0, 'elsewhere': 0}
        n_move = len(info['moving'])
        other = self.doc.tile_anims(room)
        fake = {'id': '_new', 'motion': req['motion'], 'speed': req['speed'],
                'rows': [[0] * max(1, n_move)], 'strip': req['strip'],
                'amplitude': req['amplitude'], 'order': req['order'],
                'frames': [['00' * 16] * max(1, n_move)] * len(self.frames)}
        if req['motion'] != 'flip' and req['strip']:
            fake['rows'] = [[0] * min(self.sel['cols'], TA.MAX_STRIP)] * max(1, self.sel['rows'])
        try:
            load = TA.load(other + [fake])['pct']
            rom = TA.rom_bytes(fake)
        except Exception:
            load, rom = 0.0, 0
        self._pend = {'load': load, 'copies': info['copies'], 'rom': rom}
        self.scope_here.setText(
            'only the selected cells' + (f" (uses {info['copies']} free tile"
                                         f"{'s' if info['copies'] != 1 else ''})"
                                         if info['copies'] else ' (no free tiles needed)'))
        self.scope_all.setText(
            'every place in this room drawn with these tiles'
            + (f" ({info['elsewhere']} more place{'s' if info['elsewhere'] != 1 else ''} move)"
               if not req['private'] and info['elsewhere'] else ''))
        bits = []
        if n_move:
            bits.append(f"{n_move} of the {self.sel['rows'] * self.sel['cols']} tiles here change")
        if not req['private'] and info['elsewhere']:
            bits.append(f"{info['elsewhere']} other place(s) in this room drawn with the same "
                        'tiles change with them')
        self.result.setText(('; '.join(bits) + '.') if bits else '')
        why = info.get('problem') or ''
        if not why and load > 100:
            why = (f'Load would be {load:.0f}% — the animations would run slower than set. '
                   'Pick a slower speed or fewer tiles.')
        self.problem.setText(why)
        self.b_create.setEnabled(not info.get('problem'))
        self._update_budget()

    def _create(self):
        if self.sel is None:
            return
        self._changed()                   # re-check right before acting
        if not self.b_create.isEnabled():
            self.status.emit(self.problem.text() or 'Cannot create this animation.')
            return
        req = self._request()
        if self.editing:
            req['aid'] = self.editing
            self.replaceRequested.emit(req)
        else:
            self.createRequested.emit(req)

    def _refresh_form(self):
        if self.sel is not None:
            self._changed()

    # ------------------------------------------------------------ preview
    def _tick(self):
        if self.sel is None or not self.isVisible():
            return
        m = self._motion()
        game_f = int(self._clock.elapsed() * TA.FPS / 1000.0)
        step = game_f // max(1, self.speed.value())
        rows, cols = self.sel['rows'], self.sel['cols']
        art = [bytes(a) for a in self.sel['art']]
        if m == 'flip':
            n = 1 + len(self.frames)
            seq = list(range(n))
            if self.order.currentData() == 'pingpong' and n > 2:
                seq += list(range(n - 2, 0, -1))
            px = self._frame_px(seq[step % len(seq)])
            tiles = px
        else:
            item = {'motion': m, 'rows': [[0] * cols] * rows, 'strip': self.strip.isChecked()
                    and cols <= TA.MAX_STRIP, 'amplitude': self.amp.value()}
            offs = TA.offsets(item)
            dx = offs[step % len(offs)]
            out = []
            for r in range(rows):
                row = art[r * cols:(r + 1) * cols]
                if item['strip']:
                    out += TA.roll(row, dx)
                else:
                    out += [TA.roll([t], dx)[0] for t in row]
            tiles = [decode_2bpp(t) for t in out]
        img = Image.new('RGB', (cols * 8, rows * 8))
        for k, p in enumerate(tiles):
            ox, oy = (k % cols) * 8, (k // cols) * 8
            pal = self.sel['pals'][k]
            for i, v in enumerate(p):
                img.putpixel((ox + i % 8, oy + i // 8), tuple(pal[v]))
        z = max(2, min(4, 96 // max(1, cols * 8)))
        img = img.resize((cols * 8 * z, rows * 8 * z), Image.NEAREST)
        self.preview.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(img)))
