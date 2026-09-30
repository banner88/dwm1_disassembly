"""families_tab.py — the Families tab (S104, ROADMAP P3.10a; EDITOR_DESIGN §5.2).

Left: the 11 families (icon, name, member count). Middle: the selected
family's members; move a member to another family, or bring any monster in.
Right: the family's settings — the arena-lobby dialogue voice (every family)
and, for Spirit, its 8 default names.

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

from PySide6.QtCore import Qt
from PySide6.QtGui import QColor, QIcon, QImage, QPixmap
from PySide6.QtWidgets import (QComboBox, QFormLayout, QGroupBox, QHBoxLayout,
                               QInputDialog, QLabel, QLineEdit, QListWidget,
                               QListWidgetItem, QMessageBox, QPushButton,
                               QSplitter, QVBoxLayout, QWidget)

from editor2.app.rooms import commands as C
from editor2.core import gamedata as G

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
# the menu font's 4 shades (index 1 = the menu background)
SHADES = [QColor(248, 216, 120), QColor(248, 248, 224), QColor(200, 96, 40), QColor(24, 24, 24)]

HELP = ('Which family a monster belongs to decides its library tab, how it breeds '
        '(family recipes), how it talks in the arena lobby and which names the game '
        'suggests for it. A monster the player already owns keeps, on its INFO page and '
        'status icon, the family it had when it joined; everything else follows at once. '
        'Spirit has no members in the original game.')

NAMES_HELP = ('When a monster joins or hatches, the naming screen fills in a name for '
              'you, picked at random from its family\'s list (the other families use the '
              'game\'s own 16 names each). These are Spirit\'s 8 — up to 4 letters each.')


def family_icons():
    """[QPixmap] for families 0-10 from extracted/family_icons.json."""
    try:
        d = json.load(open(os.path.join(REPO, 'extracted', 'family_icons.json')))
        grids = [ic['grid'] for ic in d['icons']] + [d['spirit']['grid']]
    except Exception:
        return [QPixmap() for _ in range(G.NUM_FAMILIES)]
    out = []
    for g in grids:
        img = QImage(8, 8, QImage.Format_RGB32)
        for y in range(8):
            for x in range(8):
                img.setPixelColor(x, y, SHADES[g[y][x] & 3])
        out.append(QPixmap.fromImage(img.scaled(24, 24)))
    return out


class FamiliesTab(QWidget):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.icons = family_icons()
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
        split.addWidget(right)
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

    def _names(self):
        names = [e.text().strip() for e in self.name_edits]
        if names == self.s.doc.spirit_names():
            return
        self._push('Spirit default names', lambda doc: doc.set_spirit_names(names))
