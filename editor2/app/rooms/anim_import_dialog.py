"""anim_import_dialog.py — S173 r3: the window of Animate → "Import frames from PNG…".

Shows the frames as the game will draw them (editor2/core/anim_import.preview), what the
import does (rows used / new rows, own colour 1, tiles, colours not exact) and asks the
speed, the order and a name. No ROM bytes.
"""
from PIL import ImageQt
from PySide6.QtCore import Qt
from PySide6.QtGui import QPixmap
from PySide6.QtWidgets import (QComboBox, QDialog, QDialogButtonBox, QHBoxLayout, QLabel,
                               QLineEdit, QSpinBox, QVBoxLayout)

from editor2.core import anim_import as AI


def _swatch(c):
    return (f'<span style="background:#{c[0]:02x}{c[1]:02x}{c[2]:02x};">&nbsp;&nbsp;&nbsp;&nbsp;'
            '</span>')


class AnimImportDialog(QDialog):
    def __init__(self, plan, info, free_tiles, path_name, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Import frames from PNG')
        self.plan = plan
        v = QVBoxLayout(self)
        c0, r0, c1, r1 = plan['rect']
        cells = (c1 - c0 + 1) * (r1 - r0 + 1)
        head = QLabel(f'<b>{path_name}</b> — {info["n"]} frame{"s" if info["n"] != 1 else ""} '
                      f'({info["layout"]}{", zoom " + str(info["scale"]) + "×" if info["scale"] > 1 else ""})'
                      f' onto {cells} cell{"s" if cells != 1 else ""} at ({c0},{r0})'
                      + (f'–({c1},{r1})' if cells > 1 else ''))
        head.setWordWrap(True)
        v.addWidget(head)
        # the frames as the game draws them
        row = QHBoxLayout()
        for i, im in enumerate(AI.preview(plan, scale=5)):
            col = QVBoxLayout()
            lab = QLabel()
            lab.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(im)))
            col.addWidget(lab)
            t = QLabel(f'frame {i + 1}' + (' (the map)' if i == 0 else ''))
            t.setAlignment(Qt.AlignCenter)
            col.addWidget(t)
            row.addLayout(col)
        row.addStretch(1)
        v.addLayout(row)
        # what it does
        lines = []
        used = sorted(set(plan['assign'].values()))
        for r in used:
            sw = ''.join(_swatch(c) for c in plan['rows'][r])
            what = 'NEW colours' if r in plan['new_rows'] else 'the room\'s colours'
            n = sum(1 for p in plan['pieces'] if plan['assign'][p] == r)
            lines.append(f'row {r} {sw} — {what}, {n} piece{"s" if n != 1 else ""} of 8×8')
        if plan['free1']:
            lines.append('own colour 1 is turned on for this palette (a row needs a colour 1 that '
                         'is not the cream; the rows you have keep their cream)')
        need = AI.tiles_needed(plan)
        lines.append(f'tiles: up to {need} new ({len(plan["moving"])} of them change) — '
                     f'{free_tiles} free on this tileset')
        if plan['off_px']:
            lines.append(f'<span style="color:#ff8060">{plan["off_px"]} pixel(s) have no exact '
                         'colour (no free palette row left) — shown above in the nearest colour'
                         '</span>')
        for n in plan['notes']:
            lines.append(f'<span style="color:#ff8060">{n}</span>')
        if info.get('alpha'):
            lines.append('see-through pixels: the map shows through (fully clear) or is LIT '
                         '(half-clear: the colour, except where the map is black)')
        if info['n'] == 1:
            lines.append('one frame: the picture is placed, nothing moves')
        txt = QLabel('<br>'.join(lines))
        txt.setWordWrap(True)
        txt.setTextFormat(Qt.RichText)
        v.addWidget(txt)
        # speed / order / name
        form = QHBoxLayout()
        form.addWidget(QLabel('Every'))
        self.speed = QSpinBox()
        self.speed.setRange(1, 255)
        self.speed.setValue(32)
        self.speed.setToolTip('Game frames between two steps (60 a second). The game\'s own '
                              'torches swap every 32.')
        form.addWidget(self.speed)
        form.addWidget(QLabel('frames'))
        self.order = QComboBox()
        self.order.addItem('Loop (1 2 3 1 2 3)', 'loop')
        self.order.addItem('Back and forth (1 2 3 2 1)', 'pingpong')
        form.addWidget(self.order)
        form.addWidget(QLabel('Name'))
        self.name = QLineEdit(path_name.rsplit('.', 1)[0][:24] or 'imported')
        form.addWidget(self.name, 1)
        v.addLayout(form)
        for w in (self.speed, self.order):
            w.setEnabled(info['n'] > 1)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.button(QDialogButtonBox.Ok).setText('Import')
        bb.button(QDialogButtonBox.Ok).setEnabled(not plan['notes'] and need <= free_tiles)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def values(self):
        return {'speed': self.speed.value(), 'order': self.order.currentData(),
                'name': self.name.text().strip() or 'imported'}
