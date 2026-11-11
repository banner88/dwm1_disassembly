"""stamps_panel.py — S174 (ROADMAP P3.3m): the Rooms tab's Stamps page + the import window.

The library of stamp pictures (custom.stamps, editor2/core/stamps.py), the chosen one for the
Stamp tool, and the selected placement's light (on / off, its colour) and warnings.
"""
from PIL import Image, ImageQt
from PySide6.QtCore import Qt, Signal, QSize
from PySide6.QtGui import QColor, QIcon, QPixmap
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox, QFormLayout,
                               QGroupBox, QHBoxLayout, QLabel, QLineEdit, QListWidget,
                               QListWidgetItem, QPushButton, QSpinBox, QVBoxLayout, QWidget)

from editor2.core import stamps as ST
from editor2.core import tileanim as TA


def checker(w, h, s=4):
    im = Image.new('RGBA', (w, h))
    px = im.load()
    for y in range(h):
        for x in range(w):
            px[x, y] = (200, 200, 200, 255) if ((x // s + y // s) % 2) else (150, 150, 150, 255)
    return im


def picture(frames, scale=3, gap=4, n=None):
    """The frames side by side over a checkerboard (clear / half-clear parts visible)."""
    frames = frames[:n] if n else frames
    if not frames:
        return QPixmap()
    w, h = frames[0].size
    out = Image.new('RGBA', ((w + gap) * len(frames) - gap, h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(Image.alpha_composite(checker(w, h), f.convert('RGBA')), (i * (w + gap), 0))
    out = out.resize((out.width * scale, out.height * scale), Image.NEAREST)
    return QPixmap.fromImage(ImageQt.ImageQt(out))


def speed_combo():
    cb = QComboBox()
    for v, words in TA.SPEED_PRESETS:
        cb.addItem(f'{v} — {words}', v)
    return cb


class StampImportDialog(QDialog):
    """A PNG into the library: its name, the size of ONE frame in cells, the speed."""

    def __init__(self, path, parent=None):
        super().__init__(parent)
        import os
        self.setWindowTitle('Import a stamp')
        self.path = path
        self.img = Image.open(path)
        w, h = ST.guess_size(self.img, path)
        v = QVBoxLayout(self)
        intro = QLabel('A stamp goes on top of the tiles. In the picture, <b>clear</b> pixels let '
                       'the tiles show, <b>half-clear</b> pixels light them (a glow), solid pixels '
                       'are drawn. Frames side by side (or one under the other) make it move.')
        intro.setWordWrap(True)
        v.addWidget(intro)
        self.pic = QLabel()
        self.pic.setAlignment(Qt.AlignCenter)
        v.addWidget(self.pic)
        f = QFormLayout()
        self.name = QLineEdit(os.path.splitext(os.path.basename(path))[0][:40])
        f.addRow('Name', self.name)
        row = QHBoxLayout()
        self.w = QSpinBox()
        self.w.setRange(1, ST.CELLS_W)
        self.w.setValue(w)
        self.h = QSpinBox()
        self.h.setRange(1, ST.CELLS_H)
        self.h.setValue(h)
        row.addWidget(self.w)
        row.addWidget(QLabel('cells wide ×'))
        row.addWidget(self.h)
        row.addWidget(QLabel('tall (16 px a cell)'))
        row.addStretch(1)
        f.addRow('One frame', row)
        self.info = QLabel()
        self.info.setWordWrap(True)
        f.addRow('', self.info)
        self.speed = speed_combo()
        self.speed.setCurrentIndex(max(0, self.speed.findData(ST.SPEED_DEFAULT)))
        f.addRow('Speed', self.speed)
        v.addLayout(f)
        self.bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        self.bb.accepted.connect(self.accept)
        self.bb.rejected.connect(self.reject)
        v.addWidget(self.bb)
        self.w.valueChanged.connect(self._update)
        self.h.valueChanged.connect(self._update)
        self.frames = []
        self._update()

    def _update(self):
        try:
            self.frames, info = ST.read_png(self.path, self.w.value(), self.h.value())
            self.info.setText(f"{info['n']} frame{'s' if info['n'] != 1 else ''} ({info['layout']}"
                              + (f", drawn at {info['scale']}×" if info['scale'] > 1 else '') + ')'
                              + ('' if info.get('alpha') else ' — no clear pixels: it will '
                                 'cover the tiles completely'))
            self.pic.setPixmap(picture(self.frames, 4 if self.w.value() <= 3 else 2))
            self.bb.button(QDialogButtonBox.Ok).setEnabled(True)
        except Exception as e:                                   # noqa: BLE001
            self.frames = []
            self.info.setText(f'<span style="color:#e66">{e}</span>')
            self.pic.setPixmap(QPixmap())
            self.bb.button(QDialogButtonBox.Ok).setEnabled(False)

    def values(self):
        return {'name': self.name.text().strip() or 'stamp', 'w': self.w.value(),
                'h': self.h.value(), 'speed': self.speed.currentData()}


class StampsPanel(QWidget):
    importRequested = Signal()
    chosen = Signal(object)              # library id or None
    renameRequested = Signal(str)
    removeRequested = Signal(str)
    speedChanged = Signal(str, int)
    litToggled = Signal(bool)
    lightChosen = Signal(object)         # '#rrggbb' or None (= as drawn)
    deleteRequested = Signal()
    copyRequested = Signal()
    showToggled = Signal(bool)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.doc = None
        self._busy = False
        v = QVBoxLayout(self)
        v.setContentsMargins(6, 6, 6, 6)
        head = QLabel('<b>Stamps</b> — pictures put on top of the tiles (a wall torch…). The '
                      'tiles under a stamp are never changed: the build draws the stamp into a '
                      'copy, so moving or removing one leaves the tiles exactly as they were. '
                      'The colour rows a stamp needs are written into your palette when you put '
                      'it down (Palettes page) — use them for tiles too.')
        head.setWordWrap(True)
        v.addWidget(head)
        self.list = QListWidget()
        self.list.setIconSize(QSize(144, 96))
        self.list.setSpacing(2)
        self.list.setMinimumHeight(150)
        self.list.currentItemChanged.connect(self._current)
        v.addWidget(self.list, 1)
        row = QHBoxLayout()
        self.b_import = QPushButton('Import PNG…')
        self.b_import.setToolTip('Add a picture to the library (clear = the tiles show, '
                                 'half-clear = light, frames side by side = it moves)')
        self.b_import.clicked.connect(self.importRequested)
        self.b_rename = QPushButton('Rename…')
        self.b_rename.clicked.connect(lambda: self.current_id() and
                                      self.renameRequested.emit(self.current_id()))
        self.b_remove = QPushButton('Remove…')
        self.b_remove.setToolTip('Take it out of the library — and off every screen it is on')
        self.b_remove.clicked.connect(lambda: self.current_id() and
                                      self.removeRequested.emit(self.current_id()))
        for b in (self.b_import, self.b_rename, self.b_remove):
            row.addWidget(b)
        v.addLayout(row)
        srow = QHBoxLayout()
        srow.addWidget(QLabel('Speed'))
        self.speed = speed_combo()
        self.speed.setToolTip('Game frames between two frames of the stamp (32 = the game\'s '
                              'own torches)')
        self.speed.activated.connect(self._speed)
        srow.addWidget(self.speed, 1)
        v.addLayout(srow)
        self.show_box = QCheckBox('Show the stamps on the canvas')
        self.show_box.setChecked(True)
        self.show_box.setToolTip('Off: see the tiles under your stamps (nothing changes)')
        self.show_box.toggled.connect(self.showToggled)
        v.addWidget(self.show_box)
        tip = QLabel('<b>Stamp tool (T)</b>: click to put the chosen stamp down (the cursor on its '
                     'middle column, top row) · drag a stamp to move it · <b>Del</b> removes · '
                     '<b>⌘C / ⌘V</b> copy and paste (also onto another screen) · right-click: its '
                     'light. Stamps cannot overlap. ▶ Play shows them moving.')
        tip.setWordWrap(True)
        tip.setStyleSheet('color: #aaa;')
        v.addWidget(tip)
        g = QGroupBox('The selected stamp on this screen')
        gv = QVBoxLayout(g)
        self.sel_label = QLabel('none — click one with the Stamp tool')
        self.sel_label.setWordWrap(True)
        gv.addWidget(self.sel_label)
        self.lit = QCheckBox('Light (its half-clear glow)')
        self.lit.setToolTip('Off: the stamp without its glow (a sign, a plant…)')
        self.lit.toggled.connect(lambda on: not self._busy and self.litToggled.emit(on))
        gv.addWidget(self.lit)
        lrow = QHBoxLayout()
        lrow.addWidget(QLabel('Light colour'))
        self.light = QComboBox()
        for name, rgb in ST.LIGHTS:
            if rgb is None:
                self.light.addItem(name, None)
            else:
                pm = QPixmap(14, 14)
                pm.fill(QColor(*rgb))
                self.light.addItem(QIcon(pm), name, ST.colour_text(rgb))
        self.light.addItem('Custom…', 'custom')
        self.light.setToolTip('The glow (and the stamp\'s own glow colour inside it, a torch\'s '
                              'hot core). A new colour needs free colour rows on this palette — '
                              'without them the nearest colours are used (warned).')
        self.light.activated.connect(self._light)
        lrow.addWidget(self.light, 1)
        gv.addLayout(lrow)
        brow = QHBoxLayout()
        self.b_copy = QPushButton('Copy (⌘C)')
        self.b_copy.clicked.connect(self.copyRequested)
        self.b_del = QPushButton('Remove from screen (Del)')
        self.b_del.clicked.connect(self.deleteRequested)
        brow.addWidget(self.b_copy)
        brow.addWidget(self.b_del)
        gv.addLayout(brow)
        self.warn = QLabel('')
        self.warn.setWordWrap(True)
        self.warn.setStyleSheet('color: #f0a030;')
        gv.addWidget(self.warn)
        v.addWidget(g)
        self.sel_box = g
        self.show_placement(None)

    # ------------------------------------------------------------ library
    def set_library(self, doc):
        self.doc = doc
        cur = self.current_id()
        self._busy = True
        self.list.clear()
        for st in ST.library(doc.custom):
            try:
                fr = ST.stamp_frames(doc.project_dir, st)
                icon = QIcon(picture(fr, 2 if int(st['w']) <= 3 else 1, n=2))
                note = f"{st['w']}×{st['h']} cells, {len(fr)} frame{'s' if len(fr) != 1 else ''}"
            except Exception as e:                               # noqa: BLE001
                icon, note = QIcon(), f'missing picture: {e}'
            n = len(ST.uses(doc, st['id']))
            it = QListWidgetItem(icon, f"{st['name']}\n{note} · placed {n}×")
            it.setData(Qt.UserRole, st['id'])
            self.list.addItem(it)
            if st['id'] == cur:
                self.list.setCurrentItem(it)
        self._busy = False
        self._sync_buttons()

    def current_id(self):
        it = self.list.currentItem()
        return it.data(Qt.UserRole) if it else None

    def choose(self, sid):
        for i in range(self.list.count()):
            if self.list.item(i).data(Qt.UserRole) == sid:
                self.list.setCurrentRow(i)
                return

    def _current(self, *_a):
        self._sync_buttons()
        if not self._busy:
            self.chosen.emit(self.current_id())

    def _sync_buttons(self):
        sid = self.current_id()
        for b in (self.b_rename, self.b_remove, self.speed):
            b.setEnabled(sid is not None)
        st = ST.stamp_of(self.doc.custom, sid) if (self.doc and sid) else None
        if st:
            i = self.speed.findData(int(st.get('speed') or ST.SPEED_DEFAULT))
            if i < 0:
                self.speed.addItem(f"{st['speed']} — custom", int(st['speed']))
                i = self.speed.count() - 1
            self.speed.setCurrentIndex(i)

    def _speed(self, _i):
        sid = self.current_id()
        if sid:
            self.speedChanged.emit(sid, int(self.speed.currentData()))

    # ------------------------------------------------------------ the placement
    def show_placement(self, pl, st=None, info=None):
        self._busy = True
        on = pl is not None
        for w in (self.lit, self.light, self.b_copy, self.b_del):
            w.setEnabled(on)
        if not on:
            self.sel_label.setText('none — click one with the Stamp tool')
            self.lit.setChecked(True)
            self.light.setCurrentIndex(0)
            self.warn.setText('')
            self._busy = False
            return
        name = st['name'] if st else pl.get('stamp')
        self.sel_label.setText(f"<b>{name}</b> at cell ({pl['x']},{pl['y']})")
        self.lit.setChecked(pl.get('lit', True))
        self.light.setEnabled(pl.get('lit', True))
        lt = pl.get('light')
        i = self.light.findData(ST.colour_text(ST.parse_colour(lt))) if lt else 0
        if lt and i < 0:
            pm = QPixmap(14, 14)
            pm.fill(QColor(*ST.parse_colour(lt)))
            self.light.insertItem(self.light.count() - 1, QIcon(pm), lt, lt)
            i = self.light.findData(lt)
        self.light.setCurrentIndex(max(0, i))
        w = ''
        if info:
            if info.get('error'):
                w = 'Cannot be drawn: ' + info['error']
            elif info.get('warn'):
                w = '⚠ ' + info['warn'] + '.'
        self.warn.setText(w)
        self._busy = False

    def _light(self, _i):
        d = self.light.currentData()
        if d == 'custom':
            from PySide6.QtWidgets import QColorDialog
            c = QColorDialog.getColor(QColor(240, 192, 72), self, 'Light colour')
            if not c.isValid():
                return
            d = ST.colour_text(ST.parse_colour((c.red(), c.green(), c.blue())))
        self.lightChosen.emit(d)
