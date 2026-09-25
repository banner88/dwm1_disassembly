"""metatile_editor.py — build a player-sized tile from 4 subtiles (S94).

The only place subtiles are handled directly. Click a slot (TL/TR/BL/BR),
then click a subtile in the sheet; pick a palette slot (for all four, or —
with "per subtile" ticked — for the selected slot only: the attr grid is per
8x8 and vanilla mixes slots inside a cell, S96); the preview shows
the metatile in the room's real palette and whether it will be a WALL
(bottom-right subtile below the collision threshold — the engine samples
that one subtile, S94 measurement) or walkable.
"""

from PIL import Image, ImageQt
from PySide6.QtCore import Qt
from PySide6.QtGui import QPixmap
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox,
                               QGridLayout, QHBoxLayout, QLabel, QLineEdit,
                               QPushButton, QVBoxLayout)

from editor2.core.document import metatile_pals, pal_value

from editor2.app.rooms.tile_picker import TilePicker


class MetatileEditor(QDialog):
    def __init__(self, renderer, sheet, pals, threshold, seed=None, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Metatile editor')
        self.renderer, self.sheet, self.pals, self.threshold = renderer, sheet, pals, threshold
        seed = seed or {'tiles': [0, 0, 0, 0], 'pal': 0, 'name': ''}
        self.tiles = list(seed['tiles'])
        self.pals4 = metatile_pals(seed) or [0] * 4
        self.pal = self.pals4[0]
        self.slot = 0

        v = QVBoxLayout(self)
        top = QHBoxLayout()
        left = QVBoxLayout()
        left.addWidget(QLabel('Slots — click one, then a subtile:'))
        g = QGridLayout()
        self.slot_btns = []
        for i, name in enumerate(('TL', 'TR', 'BL', 'BR')):
            b = QPushButton(name)
            b.setCheckable(True)
            b.setFixedSize(48, 48)
            b.clicked.connect(lambda _c, k=i: self._pick_slot(k))
            g.addWidget(b, i // 2, i % 2)
            self.slot_btns.append(b)
        left.addLayout(g)
        self.preview = QLabel()
        self.preview.setFixedSize(96, 96)
        self.preview.setAlignment(Qt.AlignCenter)
        left.addWidget(QLabel('Preview (6×):'))
        left.addWidget(self.preview)
        self.walk_lbl = QLabel()
        left.addWidget(self.walk_lbl)
        left.addWidget(QLabel('Palette slot'))
        self.pal_box = QComboBox()
        self.pal_box.addItems([f'{i}' for i in range(8)])
        self.pal_box.setCurrentIndex(self.pal)
        self.pal_box.currentIndexChanged.connect(self._pal_changed)
        left.addWidget(self.pal_box)
        self.per_sub = QCheckBox('per subtile (selected slot only)')
        self.per_sub.setChecked(len(set(self.pals4)) > 1)
        left.addWidget(self.per_sub)
        left.addWidget(QLabel('Name'))
        self.name = QLineEdit(seed.get('name', ''))
        left.addWidget(self.name)
        left.addStretch(1)
        top.addLayout(left)
        self.picker = TilePicker()
        self.picker.set_scale(3)
        self.picker.set_sheet(renderer, sheet, pals, threshold, self.pal)
        self.picker.tileSelected.connect(self._tile_chosen)
        self.info = QLabel('')
        self.picker.hoverInfo.connect(self.info.setText)
        right = QVBoxLayout()
        right.addWidget(QLabel('Subtiles (red = below the collision threshold = wall):'))
        right.addWidget(self.picker)
        right.addWidget(self.info)
        top.addLayout(right)
        v.addLayout(top)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._pick_slot(0)
        self._refresh()

    def _pick_slot(self, k):
        self.slot = k
        for i, b in enumerate(self.slot_btns):
            b.setChecked(i == k)
        self.picker.set_selected(self.tiles[k])
        if self.per_sub.isChecked() and self.pals4[k] != self.pal:
            self.pal_box.setCurrentIndex(self.pals4[k])

    def _tile_chosen(self, t):
        self.tiles[self.slot] = t
        self._refresh()
        # advance to the next slot for quick building
        self._pick_slot((self.slot + 1) % 4)

    def _pal_changed(self, p):
        self.pal = p
        if self.per_sub.isChecked():
            self.pals4[self.slot] = p
        else:
            self.pals4 = [p] * 4
        self.picker.set_palette_index(p)
        self._refresh()

    def _refresh(self):
        img = Image.new('RGB', (16, 16))
        for i, t in enumerate(self.tiles):
            img.paste(self.renderer.render_tile(self.sheet, t & 0x7F, self.pals, self.pals4[i]),
                      ((i % 2) * 8, (i // 2) * 8))
        img = img.resize((96, 96), Image.NEAREST)
        self.preview.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(img)))
        for i, b in enumerate(self.slot_btns):
            b.setText(f"{('TL', 'TR', 'BL', 'BR')[i]}\n${self.tiles[i]:02X} p{self.pals4[i]}")
        wall = self.tiles[3] < self.threshold
        self.walk_lbl.setText('WALL (bottom-right subtile < threshold)' if wall
                              else 'walkable')
        self.walk_lbl.setStyleSheet('color:#ff6060;' if wall else 'color:#60d060;')

    def result_metatile(self):
        return {'name': self.name.text().strip() or f"mt_{'_'.join(f'{t:02X}' for t in self.tiles)}",
                'tiles': list(self.tiles), 'pal': pal_value(self.pals4)}
