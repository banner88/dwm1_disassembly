"""maze_dialog.py — pick one of the gates' maze screens for a room screen (S122,
ROADMAP P3.7b part 2).

The gate maze floors are cut, at random, from a fixed set of hand-drawn
screens: per PIECE (which sides are open — up / down / left / right) 13
drawings, plus the screens of the 21 ready-made patterns (shape mode 2).
They are the same in all 16 gate themes; a theme only changes the tiles'
look and the colours (editor2/core/maze.py, GATE_GENERATION §4 / §7). The
dialog shows them in the room's theme (or any theme), filtered by openings;
the chosen screen's tiles AND palette slots replace the current screen/state
(Document.stamp_maze_screen).
"""

from PIL import ImageQt
from PySide6.QtCore import QSize, Qt
from PySide6.QtGui import QIcon, QPixmap
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox,
                               QHBoxLayout, QLabel, QListView, QListWidget,
                               QListWidgetItem, QVBoxLayout)

from editor2.core import maze as MZ

ARROWS = ((MZ.OPEN_UP, '↑'), (MZ.OPEN_DOWN, '↓'), (MZ.OPEN_LEFT, '←'), (MZ.OPEN_RIGHT, '→'))


class MazeScreenDialog(QDialog):
    def __init__(self, renderer, theme, room_gfx, room_pals, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Start this screen from a maze screen')
        self.r = renderer
        self.room_gfx, self.room_pals = room_gfx, room_pals
        self._cache = {}
        v = QVBoxLayout(self)
        intro = QLabel('The gates\' maze floors are made of these screens, picked at random: '
                       'each <b>piece</b> is a set of open sides (↑ ↓ ← →) with 13 drawings, '
                       'plus the screens of the ready-made pattern floors. They are the same in '
                       'every gate theme. The one you pick replaces this screen (this state) — '
                       'its tiles and palette slots; exits, NPCs and doors stay.')
        intro.setWordWrap(True)
        v.addWidget(intro)
        row = QHBoxLayout()
        row.addWidget(QLabel('Show in'))
        self.theme = QComboBox()
        if theme is None:
            self.theme.addItem("this room's own tiles and colours", None)
        for t, nm in enumerate(MZ.THEME_NAMES):
            self.theme.addItem(f'gate theme {t}: {nm}', t)
        if theme is not None:
            self.theme.setCurrentIndex(theme)
        row.addWidget(self.theme, 1)
        v.addLayout(row)
        frow = QHBoxLayout()
        frow.addWidget(QLabel('Open to:'))
        self.open = {}
        for bit, arrow in ARROWS:
            cb = QCheckBox(arrow)
            cb.setToolTip('Only screens open on this side (a maze floor joins screens '
                          'through their open sides)')
            cb.toggled.connect(lambda _on: self._filter())
            frow.addWidget(cb)
            self.open[bit] = cb
        self.exact = QCheckBox('exactly these sides')
        self.exact.toggled.connect(lambda _on: self._filter())
        frow.addWidget(self.exact)
        self.patterns = QCheckBox('pattern-floor screens')
        self.patterns.setChecked(True)
        self.patterns.setToolTip('The screens of the 21 ready-made floors (shape mode 2)')
        self.patterns.toggled.connect(lambda _on: self._filter())
        frow.addWidget(self.patterns)
        frow.addStretch(1)
        v.addLayout(frow)
        self.list = QListWidget()
        self.list.setViewMode(QListView.IconMode)
        self.list.setIconSize(QSize(160, 128))
        self.list.setGridSize(QSize(176, 160))
        self.list.setResizeMode(QListView.Adjust)
        self.list.setMovement(QListView.Static)
        self.list.setMinimumSize(760, 520)
        self.list.itemDoubleClicked.connect(lambda _it: self.accept())
        v.addWidget(self.list, 1)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self.pieces = self.r.maze().pieces()
        self.theme.currentIndexChanged.connect(lambda _i: self._fill())
        self._fill()

    # ------------------------------------------------------------------
    def _look(self):
        t = self.theme.currentData()
        if t is None:
            return 'room', self.room_gfx.sheet, self.room_pals
        return t, self.r.theme_gfx(t).sheet, self.r.theme_palettes(t)

    def _fill(self):
        key, sheet, pals = self._look()
        keep = self.choice()
        self.list.clear()
        for p in self.pieces:
            ck = (key, p['cell'], p['mode'])
            if ck not in self._cache:
                img = self.r.render_maze_piece(p['cell'], p['mode'], sheet, pals)
                self._cache[ck] = QIcon(QPixmap.fromImage(ImageQt.ImageQt(img)))
            if p['mode'] == 2:
                text = f"pattern ${p['cell']:02X}"
                tip = (f"Screen of the ready-made pattern floors: cell ${p['cell']:02X} "
                       f"(layout ${p['layout'][0]:02X}:{p['layout'][1]:02X})")
            else:
                ops = ''.join(a for b, a in ARROWS if p['openings'] & b) or 'closed'
                text = f"{ops}  #{p['variant']}"
                tip = (f"Piece {p['piece']} — open {MZ.openings_text(p['openings'])}; "
                       f"drawing {p['variant']}{' (the plain one)' if p['variant'] == 12 else ''} "
                       f"— cell ${p['cell']:02X}")
            it = QListWidgetItem(self._cache[ck], text)
            it.setToolTip(tip)
            it.setData(Qt.UserRole, (p['cell'], p['mode'], p['openings']))
            self.list.addItem(it)
        self._filter()
        if keep:
            for i in range(self.list.count()):
                if self.list.item(i).data(Qt.UserRole)[:2] == keep:
                    self.list.setCurrentRow(i)
                    break

    def _filter(self):
        want = sum(b for b, cb in self.open.items() if cb.isChecked())
        exact = self.exact.isChecked()
        for i in range(self.list.count()):
            it = self.list.item(i)
            cell, mode, ops = it.data(Qt.UserRole)
            if mode == 2:
                show = self.patterns.isChecked() and not want
            elif exact:
                show = ops == want
            else:
                show = (ops & want) == want
            it.setHidden(not show)

    def choice(self):
        it = self.list.currentItem()
        if it is None or it.isHidden():
            return None
        cell, mode, _ops = it.data(Qt.UserRole)
        return cell, mode
