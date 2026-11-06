"""replan_dialog.py — Palettes page → "Re-plan colours…" (S171 r4, ROADMAP P3.3i).

User (S171): "there is no way to re-roll the colour allocation or change it … It's when I
started pulling together diverse tilesets for the master room that it's become an issue."

The dialog works on recolour.Scope (the screens / states of this room drawing with the
palette of the screen shown, + the tileset's My metatiles): it shows the screen as it is
and four plans (recolour.propose — the first starts from the palette as it is, the others
from random starts), each with its picture, its rows and its score; "Re-roll" asks for four
more; a row can be LOCKED (kept as it is, the plan fits the rest around it); "Own colour 1"
= three colours of your own per row (recommended) or two + the game's cream. Apply = one
undo step (the Rooms tab runs recolour.apply_plan in a SnapshotCommand).
"""

from PIL import ImageQt
from PySide6.QtCore import Qt
from PySide6.QtGui import QColor, QPixmap
from PySide6.QtWidgets import (QButtonGroup, QCheckBox, QDialog, QDialogButtonBox,
                               QGridLayout, QHBoxLayout, QLabel, QPushButton, QRadioButton,
                               QVBoxLayout, QWidget)

from editor2.core import recolour as RC

ZOOM = 2


def _swatch_row(row):
    w = QWidget()
    h = QHBoxLayout(w)
    h.setContentsMargins(0, 0, 0, 0)
    h.setSpacing(2)
    for c in row:
        lab = QLabel()
        lab.setFixedSize(16, 16)
        lab.setStyleSheet(f'background: {QColor(*RC.snap(c)).name()}; border: 1px solid #444;')
        h.addWidget(lab)
    h.addStretch(1)
    return w


class ReplanDialog(QDialog):
    def __init__(self, doc, scope, key, state, free1, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Re-plan colours')
        self.doc, self.scope, self.key, self.state = doc, scope, key, state
        self.seed = 0
        self.plans = []
        self.shown = set()
        v = QVBoxLayout(self)
        sm = scope.summary()
        v.addWidget(QLabel(
            f'<b>The colours of this room\'s palette, planned again.</b> {sm["states"]} screen '
            f'state(s) drawing with it, {sm["distinct"]} different tiles (+ My metatiles). '
            'Each 8×8 piece takes the row that draws its REAL colours best (the colours it had '
            'where it came from, when the editor knows them); a tile needed in two colourings '
            'takes a second slot. One undo step.'))
        if scope.problems:
            warn = QLabel('⚠ ' + '; '.join(scope.problems))
            warn.setWordWrap(True)
            warn.setStyleSheet('color: #ff8060;')
            v.addWidget(warn)
        opt = QHBoxLayout()
        self.free1 = QCheckBox('Own colour 1 — three colours of your own per row (recommended)')
        self.free1.setChecked(True)          # recommended (the Import art tab says so too)
        self.free1.toggled.connect(lambda _on: self._compute(reset=True))
        opt.addWidget(self.free1)
        opt.addStretch(1)
        v.addLayout(opt)
        lk = QGridLayout()
        lk.addWidget(QLabel('Keep a row as it is:'), 0, 0, 1, 3)
        self.locks = []
        for r in range(4):
            cb = QCheckBox(f'row {r}')
            cb.toggled.connect(lambda _on: self._compute(reset=True))
            lk.addWidget(cb, 1 + r, 0)
            lk.addWidget(_swatch_row(scope.rows_old[r]), 1 + r, 1)
            self.locks.append(cb)
        v.addLayout(lk)
        self.grid = QGridLayout()
        v.addLayout(self.grid)
        self.group = QButtonGroup(self)
        btns = QHBoxLayout()
        self.reroll = QPushButton('Re-roll — four other plans')
        self.reroll.clicked.connect(self._reroll)
        btns.addWidget(self.reroll)
        btns.addStretch(1)
        self.box = QDialogButtonBox(QDialogButtonBox.Apply | QDialogButtonBox.Cancel)
        self.box.button(QDialogButtonBox.Apply).clicked.connect(self.accept)
        self.box.rejected.connect(self.reject)
        btns.addWidget(self.box)
        v.addLayout(btns)
        self._compute(reset=True)

    def _zoom(self):
        """Five pictures side by side on the screen the dialog is on (1-2x)."""
        from PySide6.QtGui import QGuiApplication
        scr = self.screen() or QGuiApplication.primaryScreen()
        w = scr.availableGeometry().width() if scr is not None else 1400
        return max(1.0, min(ZOOM, (w - 140) / (5 * 172.0)))

    def _locked(self):
        return {r: self.scope.rows_old[r] for r, cb in enumerate(self.locks) if cb.isChecked()}

    def _nfree(self):
        return 3 if self.free1.isChecked() else 2

    def _reroll(self):
        self.seed += 10
        self._compute()

    def _compute(self, reset=False):
        if reset:
            self.seed = 0
        qs = self.scope.quarters()
        start = self.scope.rows_old       # re-rolls: 1-2 rows started again, or a fresh start
        if reset:
            self.shown = set()
        self.plans = RC.propose(qs, nfree=self._nfree(), locked=self._locked(),
                                start_seed=self.seed, n=4, start_rows=start,
                                tries=10 if not self.seed else 16, exclude=self.shown)
        if not self.plans:                   # nothing new any more: show the best again
            self.shown = set()
            self.plans = RC.propose(qs, nfree=self._nfree(), locked=self._locked(),
                                    start_seed=self.seed, n=4, start_rows=start)
        self.shown |= {RC._plan_sig(p) for p in self.plans}
        cur = RC.plan_rows(qs, self._nfree(), locked={r: self.scope.rows_old[r]
                                                      for r in range(4)})
        self._show(cur)

    def _picture(self, rows):
        img = self.scope.preview(self.doc, rows, self.key, self.state)
        z = self._zoom()
        img = img.resize((int(img.width * z), int(img.height * z)))
        lab = QLabel()
        lab.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(img)))
        return lab

    def _show(self, cur):
        while self.grid.count():
            it = self.grid.takeAt(0)
            if it.widget() is not None:
                it.widget().hide()
                it.widget().deleteLater()
        for b in list(self.group.buttons()):
            self.group.removeButton(b)
        col = QVBoxLayout()
        w = QWidget()
        w.setLayout(col)
        col.addWidget(QLabel('<b>The rows as they are</b>'))
        col.addWidget(self._picture(self.scope.rows_old))
        col.addWidget(QLabel(cur.score_text()))
        for r in range(4):
            col.addWidget(_swatch_row(self.scope.rows_old[r]))
        self.grid.addWidget(w, 0, 0)
        for i, p in enumerate(self.plans):
            col = QVBoxLayout()
            w = QWidget()
            w.setLayout(col)
            rb = QRadioButton(f'Plan {i + 1}' + (' (from the palette as it is)'
                                                 if self.seed == 0 and i == 0 else ''))
            rb.setChecked(i == 0)
            self.group.addButton(rb, i)
            col.addWidget(rb)
            col.addWidget(self._picture(p.rows))
            col.addWidget(QLabel(p.score_text()))
            for r in range(4):
                col.addWidget(_swatch_row(p.rows[r]))
            self.grid.addWidget(w, 0, 1 + i)
        self.box.button(QDialogButtonBox.Apply).setEnabled(bool(self.plans))

    def chosen(self):
        """(rows, nfree) of the plan picked."""
        i = max(0, self.group.checkedId())
        return self.plans[i].rows, self._nfree()
