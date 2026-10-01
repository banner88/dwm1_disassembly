"""families_tab.py — the Families tab (S104, ROADMAP P3.10a; EDITOR_DESIGN §5.2).

Left: the 11 families (icon, name, member count). Middle: the selected
family's members; move a member to another family, or bring any monster in.
Right: the family's settings — its ICON (S107, ROADMAP P3.10 part 2c: an 8 x 8
pixel editor + PNG import; the compiler writes it into the font glyph AND the
gfx stream, so every screen shows it), the arena-lobby dialogue voice (every
family) and, for Spirit, its 8 default names.

What moving a monster does in the game (BREEDING_SYSTEM "Spirit — the 11th
family (S104)"): the library tab and recipe text, breeding (family code),
the arena-lobby dialogue and the naming screen follow the species at once;
the INFO page and status icon of a monster the player ALREADY owns keep the
family stored with it when it joined.

Every edit is one undo step (SnapshotCommand); the setters validate with the
compiler's own gamedata model.
"""

import json
import os

from PySide6.QtCore import QSize, Qt, Signal
from PySide6.QtGui import QColor, QIcon, QImage, QPainter, QPen, QPixmap
from PySide6.QtWidgets import (QButtonGroup, QComboBox, QFileDialog, QFormLayout,
                               QGroupBox, QHBoxLayout, QInputDialog, QLabel,
                               QLineEdit, QListWidget, QListWidgetItem,
                               QMessageBox, QPushButton, QScrollArea, QSplitter,
                               QToolButton, QVBoxLayout, QWidget, QFrame, QSizePolicy)

from editor2.app.rooms import commands as C
from editor2.core import gamedata as G

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
# the 4 shades of an icon as two screens draw them (PyBoy S107, user's save:
# index 1 = the cream menu background and 3 = black everywhere; 0 / 2 take the
# screen's own palette — the INFO page draws them green, the continue box /
# JOURNAL orange and gold)
SHADES_INFO = [QColor(0, 128, 56), QColor(248, 248, 208), QColor(120, 216, 8), QColor(0, 0, 0)]
SHADES_BOX = [QColor(200, 72, 0), QColor(248, 248, 208), QColor(248, 200, 0), QColor(0, 0, 0)]
SHADES = SHADES_INFO
SHADE_NAMES = ['0 — dark colour', '1 — background (cream)', '2 — light colour', '3 — black']

ICON_HELP = ('The family icon is one 8 × 8 picture in 4 shades: 1 is the cream '
             'background, 3 black; 0 and 2 take each screen\'s own colours (green on '
             'the INFO page, orange and gold in the continue box and the JOURNAL). '
             'The game shows it on the INFO page, the library tabs, family recipes, '
             'the field status bar, lists and the JOURNAL — all from this picture.')

HELP = ('Which family a monster belongs to decides its library tab, how it breeds '
        '(family recipes), how it talks in the arena lobby and which names the game '
        'suggests for it. A monster the player already owns keeps, on its INFO page and '
        'status icon, the family it had when it joined; everything else follows at once. '
        'Spirit has no members in the original game.')

NAMES_HELP = ('When a monster joins or hatches, the naming screen fills in a name for '
              'you, picked at random from its family\'s list (the other families use the '
              'game\'s own 16 names each). These are Spirit\'s 8 — up to 4 letters each.')


def icon_pixmap(grid, shades=None, scale=3):
    shades = shades or SHADES
    img = QImage(8, 8, QImage.Format_RGB32)
    for y in range(8):
        for x in range(8):
            img.setPixelColor(x, y, shades[grid[y][x] & 3])
    return QPixmap.fromImage(img.scaled(8 * scale, 8 * scale))


def family_icons(doc=None):
    """[QPixmap] for families 0-10: the project's icons (S107), else the
    original ones from extracted/family_icons.json."""
    try:
        if doc is not None:
            grids = doc.family_icon_grids()
        else:
            d = json.load(open(os.path.join(REPO, 'extracted', 'family_icons.json')))
            grids = [ic['grid'] for ic in d['icons']] + [d['spirit']['grid']]
    except Exception:
        return [QPixmap() for _ in range(G.NUM_FAMILIES)]
    return [icon_pixmap(g) for g in grids]


def png_to_grid(path):
    """An 8 x 8 picture -> grid of 0-3 by brightness: the darkest colour
    -> 3 (black), the lightest -> 1 (background), in between -> 0 (dark) /
    2 (light) — the order the game's palettes have. Transparent = 1. A
    bigger picture is shrunk to 8 x 8 (nearest)."""
    from PIL import Image
    im = Image.open(path).convert('RGBA')
    if im.size != (8, 8):
        im = im.resize((8, 8), Image.NEAREST)
    px = [[im.getpixel((x, y)) for x in range(8)] for y in range(8)]
    lum = lambda c: 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]
    cols = sorted({c[:3] for r in px for c in r if c[3] >= 128}, key=lum)
    if len(cols) > 4:
        # cluster to 4 brightness levels
        ls = [lum(c) for c in cols]
        lo, hi = min(ls), max(ls)
        lvl = {c: min(3, int(4 * (lum(c) - lo) / (hi - lo + 1e-9))) for c in cols}
    else:
        order = {1: [0], 2: [0, 3], 3: [0, 1, 3], 4: [0, 1, 2, 3]}[max(1, len(cols))]
        lvl = {c: order[i] for i, c in enumerate(cols)}
    to_idx = {0: 3, 1: 0, 2: 2, 3: 1}          # dark -> light = 3, 0, 2, 1
    return [[1 if c[3] < 128 else to_idx[lvl[c[:3]]] for c in r] for r in px]


class IconCanvas(QWidget):
    """8 x 8 pixel editor: left button paints the chosen shade, right button
    picks the shade under the cursor. `edited(grid)` fires once per stroke."""
    edited = Signal(object)
    CELL = 20

    def __init__(self, parent=None):
        super().__init__(parent)
        self.grid = [[1] * 8 for _ in range(8)]
        self.shade = 3
        self.shades = SHADES
        self._painting = False
        self.picked = None                      # callback(shade) for right-click
        self.setFixedSize(8 * self.CELL + 1, 8 * self.CELL + 1)
        self.setCursor(Qt.CrossCursor)

    def set_grid(self, g):
        self.grid = [list(r) for r in g]
        self.update()

    def _cell(self, ev):
        x, y = int(ev.position().x()) // self.CELL, int(ev.position().y()) // self.CELL
        return (x, y) if 0 <= x < 8 and 0 <= y < 8 else None

    def mousePressEvent(self, ev):
        c = self._cell(ev)
        if c is None:
            return
        if ev.button() == Qt.RightButton:
            self.shade = self.grid[c[1]][c[0]]
            if self.picked:
                self.picked(self.shade)
            return
        self._painting = True
        self._paint(c)

    def mouseMoveEvent(self, ev):
        if self._painting:
            c = self._cell(ev)
            if c is not None:
                self._paint(c)

    def mouseReleaseEvent(self, ev):
        if self._painting:
            self._painting = False
            self.edited.emit([list(r) for r in self.grid])

    def _paint(self, c):
        if self.grid[c[1]][c[0]] != self.shade:
            self.grid[c[1]][c[0]] = self.shade
            self.update()

    def paintEvent(self, _ev):
        p = QPainter(self)
        for y in range(8):
            for x in range(8):
                p.fillRect(x * self.CELL, y * self.CELL, self.CELL, self.CELL,
                           self.shades[self.grid[y][x]])
        p.setPen(QPen(QColor(150, 150, 150)))
        for k in range(9):
            p.drawLine(k * self.CELL, 0, k * self.CELL, 8 * self.CELL)
            p.drawLine(0, k * self.CELL, 8 * self.CELL, k * self.CELL)


class FamiliesTab(QWidget):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.icons = family_icons(session.doc)
        self.names = self.s.doc.species_names()
        v = QVBoxLayout(self)
        h = QLabel(HELP)
        h.setWordWrap(True)
        v.addWidget(h)
        split = QSplitter()
        v.addWidget(split, 1)

        self.fam_list = QListWidget()
        self.fam_list.currentRowChanged.connect(self._fam_changed)
        split.addWidget(self.fam_list)

        mid = QWidget()
        mv = QVBoxLayout(mid)
        self.members_title = QLabel()
        mv.addWidget(self.members_title)
        self.members = QListWidget()
        mv.addWidget(self.members, 1)
        row = QHBoxLayout()
        row.addWidget(QLabel('Move selected to'))
        self.move_to = QComboBox()
        for f in G.DISPLAY_ORDER:
            self.move_to.addItem(self.icons[f], G.FAMILY_NAMES[f], f)
        row.addWidget(self.move_to, 1)
        b = QPushButton('Move')
        b.clicked.connect(self._move)
        row.addWidget(b)
        mv.addLayout(row)
        add = QPushButton('Add a monster to this family…')
        add.clicked.connect(self._add)
        mv.addWidget(add)
        split.addWidget(mid)

        right = QWidget()
        rv = QVBoxLayout(right)
        # S107 (P3.10 part 2c): the family icon
        ib = QGroupBox('Icon')
        il = QVBoxLayout(ib)
        ih = QLabel(ICON_HELP)
        ih.setWordWrap(True)
        il.addWidget(ih)
        row = QHBoxLayout()
        self.icon_canvas = IconCanvas()
        self.icon_canvas.edited.connect(self._icon_edited)
        self.icon_canvas.picked = self._shade_picked
        row.addWidget(self.icon_canvas)
        col = QVBoxLayout()
        self.shade_btns = QButtonGroup(self)
        for k in (3, 0, 2, 1):
            b = QToolButton()
            b.setCheckable(True)
            b.setText(SHADE_NAMES[k])
            b.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
            pm = QPixmap(28, 14)
            pp = QPainter(pm)
            pp.fillRect(0, 0, 14, 14, SHADES_INFO[k])
            pp.fillRect(14, 0, 14, 14, SHADES_BOX[k])
            pp.end()
            b.setIcon(QIcon(pm))
            b.setIconSize(QSize(28, 14))
            b.setMinimumHeight(26)
            b.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
            self.shade_btns.addButton(b, k)
            col.addWidget(b)
        self.shade_btns.button(3).setChecked(True)
        self.shade_btns.idClicked.connect(self._shade_chosen)
        tip = QLabel('Left button paints, right button picks a shade.')
        tip.setStyleSheet('color:#666')
        tip.setWordWrap(True)
        col.addWidget(tip)
        col.addStretch(1)
        row.addLayout(col, 1)
        il.addLayout(row)
        prow = QHBoxLayout()
        prow.addWidget(QLabel('INFO page'))
        self.prev_info = QLabel()
        prow.addWidget(self.prev_info)
        prow.addWidget(QLabel('  continue box / JOURNAL'))
        self.prev_box = QLabel()
        prow.addWidget(self.prev_box)
        prow.addWidget(QLabel('  actual size'))
        self.prev_1x = QLabel()
        prow.addWidget(self.prev_1x)
        prow.addStretch(1)
        il.addLayout(prow)
        brow = QHBoxLayout()
        b = QPushButton('Import an 8 × 8 PNG…')
        b.clicked.connect(self._icon_png)
        brow.addWidget(b)
        self.icon_reset = QPushButton('Back to the original icon')
        self.icon_reset.clicked.connect(self._icon_original)
        brow.addWidget(self.icon_reset)
        brow.addStretch(1)
        il.addLayout(brow)
        self.icon_note = QLabel()
        il.addWidget(self.icon_note)
        rv.addWidget(ib)
        box = QGroupBox('Settings')
        f = QFormLayout(box)
        self.voice = QComboBox()
        for k in sorted(G.VOICES):
            self.voice.addItem(f'{k} — {G.VOICE_LABEL[k]}', k)
        self.voice.activated.connect(self._voice)
        f.addRow('Arena-lobby dialogue', self.voice)
        self.voice_note = QLabel()
        self.voice_note.setWordWrap(True)
        f.addRow('', self.voice_note)
        rv.addWidget(box)
        self.names_box = QGroupBox('Spirit default names')
        nv = QVBoxLayout(self.names_box)
        nh = QLabel(NAMES_HELP)
        nh.setWordWrap(True)
        nv.addWidget(nh)
        grid = QFormLayout()
        self.name_edits = []
        for i in range(8):
            e = QLineEdit()
            e.setMaxLength(G.NAME_MAX)
            e.editingFinished.connect(self._names)
            grid.addRow(f'{i + 1}', e)
            self.name_edits.append(e)
        nv.addLayout(grid)
        rv.addWidget(self.names_box)
        rv.addStretch(1)
        # S107: the icon editor made the column taller than small windows —
        # it scrolls instead of squeezing the editor
        sa = QScrollArea()
        sa.setWidgetResizable(True)
        sa.setFrameShape(QFrame.NoFrame)
        sa.setWidget(right)
        split.addWidget(sa)
        split.setSizes([220, 380, 420])

        # a bound slot (auto-disconnected when the tab is deleted on reopen);
        # hidden tabs only mark themselves stale — the model rebuild is not free
        self._stale = False
        self.s.undo.indexChanged.connect(self._undo_changed)
        self.refresh()

    def _undo_changed(self, _i):
        if self.isVisible():
            self.refresh()
        else:
            self._stale = True

    def showEvent(self, ev):
        if self._stale:
            self._stale = False
            self.refresh()
        super().showEvent(ev)

    # ------------------------------------------------------------ view
    def family(self):
        """The selected FAMILY (rows follow G.DISPLAY_ORDER)."""
        r = self.fam_list.currentRow()
        return G.DISPLAY_ORDER[r] if r >= 0 else 0

    def refresh(self):
        cur = self.family()
        self.icons = family_icons(self.s.doc)
        self.members_of = self.s.doc.family_members()
        self.fam_list.blockSignals(True)
        self.fam_list.clear()
        for f in G.DISPLAY_ORDER:
            nm = G.FAMILY_NAMES[f]
            label = '??? (Boss)' if nm == 'Boss' else nm
            self.fam_list.addItem(QListWidgetItem(
                self.icons[f], f'{label}  ({len(self.members_of[f])})'))
        self.fam_list.setCurrentRow(G.DISPLAY_ORDER.index(cur))
        self.fam_list.blockSignals(False)
        self._fam_changed(G.DISPLAY_ORDER.index(cur))

    def _fam_changed(self, row):
        if row < 0:
            return
        f = G.DISPLAY_ORDER[row]
        doc = self.s.doc
        self.members_title.setText(f'<b>{G.FAMILY_NAMES[f]}</b> — {len(self.members_of[f])} '
                                   'monsters')
        self.members.clear()
        for sid in self.members_of[f]:
            moved = doc.vanilla_family(sid) != f
            it = QListWidgetItem(f"{sid:3d}  {self.names.get(sid, '?')}"
                                 + ('   (moved here)' if moved else ''))
            it.setData(Qt.UserRole, sid)
            self.members.addItem(it)
        voice = doc.family_voice(f)
        self.voice.setCurrentIndex(self.voice.findData(voice))
        van = G.VOICE_OF[f]
        self.voice_note.setText('original game' if voice == van else
                                f'changed (the original game: {van})')
        self._show_icon(f)
        self.names_box.setVisible(f == 10)
        if f == 10:
            for e, n in zip(self.name_edits, doc.spirit_names()):
                e.setText(n)

    # ------------------------------------------------------------ edits
    def _push(self, label, op):
        cmd = C.SnapshotCommand(self.s, label, op)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            self.refresh()
            return False
        return True

    def _move(self):
        it = self.members.currentItem()
        if it is None:
            return
        sid = it.data(Qt.UserRole)
        to = self.move_to.currentData()
        if to == self.family():
            return
        self._push(f"{self.names.get(sid, sid)} → {G.FAMILY_NAMES[to]}",
                   lambda doc: doc.set_monster_family(sid, to))

    def _add(self):
        f = self.family()
        fam_of = {sid: fam for fam, ms in self.members_of.items() for sid in ms}
        items = [f"{sid:3d}  {self.names.get(sid, '?')}  ({G.FAMILY_NAMES[fam_of[sid]]})"
                 for sid in sorted(fam_of) if fam_of[sid] != f]
        pick, ok = QInputDialog.getItem(self, f'Add to {G.FAMILY_NAMES[f]}',
                                        'Monster', items, 0, False)
        if not ok or not pick:
            return
        sid = int(pick.split()[0])
        self._push(f"{self.names.get(sid, sid)} → {G.FAMILY_NAMES[f]}",
                   lambda doc: doc.set_monster_family(sid, f))

    def _voice(self, _i):
        f = self.family()
        v = self.voice.currentData()
        if v == self.s.doc.family_voice(f):
            return
        self._push(f"{G.FAMILY_NAMES[f]} dialogue → {v}",
                   lambda doc: doc.set_family_voice(f, v))

    # ------------------------------------------------------------ icon
    def _show_icon(self, f):
        g = self.s.doc.family_icon(f)
        self.icon_canvas.set_grid(g)
        self.prev_info.setPixmap(icon_pixmap(g, SHADES_INFO, 4))
        self.prev_box.setPixmap(icon_pixmap(g, SHADES_BOX, 4))
        self.prev_1x.setPixmap(icon_pixmap(g, SHADES_INFO, 1))
        orig = g == self.s.doc.vanilla_family_icon(f)
        self.icon_reset.setEnabled(not orig)
        self.icon_note.setText('the original game\'s icon' if orig else 'changed')

    def _shade_chosen(self, k):
        self.icon_canvas.shade = k

    def _shade_picked(self, k):
        self.shade_btns.button(k).setChecked(True)

    def _icon_edited(self, grid):
        f = self.family()
        if grid == self.s.doc.family_icon(f):
            return
        self._push(f'{G.FAMILY_NAMES[f]} icon', lambda doc: doc.set_family_icon(f, grid))

    def _icon_png(self):
        path, _ = QFileDialog.getOpenFileName(self, 'An 8 × 8 icon', '', 'PNG images (*.png)')
        if not path:
            return
        try:
            grid = png_to_grid(path)
        except Exception as ex:                          # noqa: BLE001
            QMessageBox.warning(self, 'Icon', f'Could not read {os.path.basename(path)}: {ex}')
            return
        self._icon_edited(grid)

    def _icon_original(self):
        f = self.family()
        g = self.s.doc.vanilla_family_icon(f)
        self._push(f'{G.FAMILY_NAMES[f]} icon: original', lambda doc: doc.set_family_icon(f, g))

    def _names(self):
        names = [e.text().strip() for e in self.name_edits]
        if names == self.s.doc.spirit_names():
            return
        self._push('Spirit default names', lambda doc: doc.set_spirit_names(names))
