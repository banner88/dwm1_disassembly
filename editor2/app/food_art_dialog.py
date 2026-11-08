"""food_art_dialog.py — S172 r2: draw a food's picture (Items tab → Food pictures).

User S172: "allow me to edit PNG using draw pixel tools same as tile (no flipping or anything
necessary, just draw). Allow to apply and restore default (yours)."

One 16 x 16 picture per food (gamedata.food_art, editor2/core/foods.py) in the food's own
OBJ palette: colour 0 = see-through, 1 = cream, 2 = the food's colour, 3 = black. The same
picture is the gate-floor pickup icon and the NPC prop. Drawing uses the Draw tab's pad
(FramePad): left = paint, Shift+left = fill (inside one 8x8 quarter), right = pick a colour.
Apply = one undo step; Restore default = back to the editor's picture (the key removed).
"""

from PySide6.QtCore import Qt
from PySide6.QtGui import QColor, QPixmap, QPainter, QIcon, QKeySequence
from PySide6.QtWidgets import (QDialog, QHBoxLayout, QLabel, QPushButton, QVBoxLayout,
                               QButtonGroup, QToolButton)

from editor2.app.rooms.animate_tab import FramePad
from editor2.core import foods as FD

# colour 0 is see-through in the game; the pad shows it as a dull floor so the cream halo reads
SEE_THROUGH = (88, 112, 96)
COLOUR_NAMES = ('see-through', 'cream', 'the food\'s colour', 'black')


def grid_to_tiles(grid):
    """16 x 16 → the pad's 4 flat 8x8 tiles (row-major: TL, TR, BL, BR)."""
    out = []
    for ty in range(2):
        for tx in range(2):
            out.append([grid[ty * 8 + y][tx * 8 + x] for y in range(8) for x in range(8)])
    return out


def tiles_to_grid(px):
    g = [[0] * 16 for _ in range(16)]
    for k, t in enumerate(px):
        ty, tx = divmod(k, 2)
        for i, v in enumerate(t):
            g[ty * 8 + i // 8][tx * 8 + i % 8] = v
    return g


def food_pixmap(grid, pal, scale=2, dim=False):
    cols = FD.obj_palette(pal)
    pm = QPixmap(16 * scale, 16 * scale)
    pm.fill(Qt.transparent)
    p = QPainter(pm)
    for y in range(16):
        for x in range(16):
            v = grid[y][x]
            if v:
                c = QColor(*cols[v])
                if dim:
                    c.setAlpha(85)
                p.fillRect(x * scale, y * scale, scale, scale, c)
    p.end()
    return pm


class FoodArtDialog(QDialog):
    """Draw one food. result_grid = the picture to store, or None = restore the default."""

    def __init__(self, parent, label, name, pal, grid, own):
        super().__init__(parent)
        self.setWindowTitle(f'Draw the {label} picture')
        self.name, self.pal = name, pal
        self.result_grid = grid
        self.restore = False
        cols = FD.obj_palette(pal)
        self.cols = [SEE_THROUGH] + [tuple(c) for c in cols[1:]]
        v = QVBoxLayout(self)
        v.addWidget(QLabel(
            f'<b>{label}</b> — 16 x 16, OBJ palette {pal}. '
            'Left = paint, Shift+left = fill (inside one quarter), right = pick a colour.<br>'
            'The same picture is the gate-floor pickup and the NPC prop.'
            + ('' if own else ' <i>(the editor\'s default)</i>')))
        h = QHBoxLayout()
        self.pad = FramePad(self)
        self.pad.set_zoom(20)
        self.pad.set_frame(2, 2, grid_to_tiles(grid), [self.cols] * 4, True)
        self.pad.changed.connect(self._preview)
        self.pad.picked.connect(self._pick)
        self._undo = []
        self.pad.aboutToChange.connect(lambda: self._undo.append([list(t) for t in self.pad.px]))
        h.addWidget(self.pad)
        side = QVBoxLayout()
        self.swatches = QButtonGroup(self)
        for c in range(4):
            b = QToolButton()
            b.setCheckable(True)
            b.setText(f' {c}: {COLOUR_NAMES[c]}')
            b.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
            sw = QPixmap(22, 22)
            sw.fill(QColor(*self.cols[c]))
            b.setIcon(QIcon(sw))
            b.setMinimumWidth(170)
            self.swatches.addButton(b, c)
            side.addWidget(b)
        self.swatches.idClicked.connect(self._set_colour)
        self._set_colour(3)
        side.addSpacing(12)
        side.addWidget(QLabel('As the game draws it:'))
        self.prev1 = QLabel()
        self.prev3 = QLabel()
        side.addWidget(self.prev1)
        side.addWidget(self.prev3)
        side.addStretch(1)
        h.addLayout(side)
        v.addLayout(h)
        btns = QHBoxLayout()
        self.b_restore = QPushButton('Restore default')
        self.b_restore.setToolTip('Back to the editor\'s picture for this food')
        self.b_restore.clicked.connect(self._restore)
        btns.addWidget(self.b_restore)
        self.b_undo = QPushButton('Undo stroke')
        self.b_undo.setShortcut(QKeySequence.Undo)
        self.b_undo.clicked.connect(self._undo_stroke)
        btns.addWidget(self.b_undo)
        btns.addStretch(1)
        b_cancel = QPushButton('Cancel')
        b_cancel.clicked.connect(self.reject)
        self.b_apply = QPushButton('Apply')
        self.b_apply.setDefault(True)
        self.b_apply.clicked.connect(self._apply)
        btns.addWidget(b_cancel)
        btns.addWidget(self.b_apply)
        v.addLayout(btns)
        self._preview()

    def grid(self):
        return tiles_to_grid(self.pad.px)

    def _set_colour(self, c):
        self.pad.colour = c
        self.swatches.button(c).setChecked(True)

    def _pick(self, c):
        self._set_colour(c)

    def _preview(self):
        g = self.grid()
        self.prev1.setPixmap(food_pixmap(g, self.pal, 2))
        self.prev3.setPixmap(food_pixmap(g, self.pal, 4))

    def _undo_stroke(self):
        if self._undo:
            self.pad.px = self._undo.pop()
            self.pad.update()
            self._preview()

    def _apply(self):
        self.result_grid = self.grid()
        self.accept()

    def _restore(self):
        self.restore = True
        self.result_grid = None
        self.accept()
