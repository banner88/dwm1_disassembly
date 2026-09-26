"""tileset_dialog.py — point a custom room at another tileset (S96).

Three sources, one sheet per room (engine: 128 slots):
  • another room's VANILLA tileset (that room's ROM sheet + its collision
    threshold) — e.g. start a cave on the Library's sheet;
  • a tileset already in this PROJECT (copied/edited sheets, imports);
  • a NEW BLANK tileset — every slot free, for art imported from PNGs.
The screens keep their tile NUMBERS, so they will draw with the new sheet's
graphics until repainted; the dialog says so and previews the sheet under
the room's current palette.
"""

from PIL import ImageQt
from PySide6.QtCore import Qt
from PySide6.QtGui import QPixmap
from PySide6.QtWidgets import (QButtonGroup, QComboBox, QDialog, QDialogButtonBox,
                               QGridLayout, QLabel, QRadioButton, QSpinBox,
                               QVBoxLayout)

from editor2.core.document import val


class TilesetDialog(QDialog):
    def __init__(self, doc, renderer, room, pals, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Change tileset')
        self.doc, self.r, self.room, self.pals = doc, renderer, room, pals
        v = QVBoxLayout(self)
        v.addWidget(QLabel(f"Room <b>{doc.room_name(room)}</b> draws with "
                           f"<b>{doc.tileset_key(room)}</b> now."))
        g = QGridLayout()
        self.group = QButtonGroup(self)
        self.rb_v = QRadioButton("Another room's tileset (vanilla)")
        self.rb_p = QRadioButton('A tileset in this project')
        self.rb_b = QRadioButton('New blank tileset (for imported PNG art)')
        others = doc.tileset_sharers(room)
        self.rb_o = QRadioButton('Own copy of the current tileset (stop sharing with: '
                                 + ', '.join(doc.room_name(r) for r in others) + ')'
                                 if others else 'Own copy of the current tileset')
        self.rb_o.setVisible(bool(others))
        for i, rb in enumerate((self.rb_v, self.rb_p, self.rb_b, self.rb_o)):
            self.group.addButton(rb, i)
        self.v_box = QComboBox()
        for mid, name, _scr in renderer.vanilla_rooms():
            self.v_box.addItem(f'${mid:02X}  {name}', mid)
        self.p_box = QComboBox()
        for t in doc.custom.get('tilesets', []):
            users = [doc.room_name(r) for r in doc.rooms_using_tileset(t['id'])]
            self.p_box.addItem(f"{t['id']}  ({', '.join(users) or 'unused'})", t['id'])
        self.rb_p.setEnabled(self.p_box.count() > 0)
        self.thr = QSpinBox()
        self.thr.setRange(1, 127)
        self.thr.setDisplayIntegerBase(16)
        self.thr.setPrefix('$')
        self.thr.setValue(0x40)
        self.thr.setToolTip('Collision threshold: slots below it are WALL tiles, '
                            'slots from it on are walkable.')
        g.addWidget(self.rb_v, 0, 0)
        g.addWidget(self.v_box, 0, 1)
        g.addWidget(self.rb_p, 1, 0)
        g.addWidget(self.p_box, 1, 1)
        g.addWidget(self.rb_b, 2, 0)
        g.addWidget(self.rb_o, 3, 0, 1, 2)
        g.addWidget(QLabel('wall | walkable split at'), 4, 0, Qt.AlignRight)
        g.addWidget(self.thr, 4, 1)
        v.addLayout(g)
        self.preview = QLabel()
        self.preview.setFixedSize(16 * 16 + 4, 8 * 16 + 4)
        self.preview.setAlignment(Qt.AlignCenter)
        v.addWidget(self.preview)
        warn = QLabel('Your screens keep their tile numbers: they draw with the new '
                      "sheet's graphics until you repaint them. Undo restores the "
                      'old tileset.')
        warn.setWordWrap(True)
        warn.setStyleSheet('color: #e0b040;')
        v.addWidget(warn)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self.rb_v.setChecked(True)
        self.group.idToggled.connect(lambda *_a: self._update())
        self.v_box.currentIndexChanged.connect(lambda _i: self._update())
        self.p_box.currentIndexChanged.connect(lambda _i: self._update())
        self._update()

    def _update(self):
        kind = self.choice()[0]
        self.thr.setEnabled(kind not in ('vanilla', 'own'))
        if kind == 'blank' and getattr(self, '_last_kind', None) != 'blank':
            self.thr.setValue(0x40)
        self._last_kind = kind
        sheet = None
        try:
            if kind == 'vanilla':
                g = self.r.vanilla_gfx(self.v_box.currentData())
                sheet = g.sheet
                self.thr.setValue(g.threshold)
            elif kind == 'project' and self.p_box.currentData():
                sheet = self.r.tileset_sheet(self.p_box.currentData())
                users = self.doc.rooms_using_tileset(self.p_box.currentData())
                if users:
                    self.thr.setValue(val(users[0]['record']['collision_threshold']))
            elif kind == 'own':
                sheet = self.r.tileset_sheet(self.doc.tileset_key(self.room))
            else:
                sheet = bytes(2048)
        except Exception:
            sheet = None
        if sheet is None:
            self.preview.clear()
            return
        img = self.r.tile_sheet_image(sheet, self.pals, 0, 16, 2)
        self.preview.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(img)))

    def choice(self):
        """(kind, value, threshold)"""
        i = self.group.checkedId()
        if i == 0:
            return 'vanilla', self.v_box.currentData(), None
        if i == 1:
            return 'project', self.p_box.currentData(), self.thr.value()
        if i == 3:
            return 'own', None, None
        return 'blank', None, self.thr.value()
