"""pool_dialog.py — put an enemy row into a gate's wild-monster list (S106 r3,
ROADMAP P3.10 part 1; the full Encounters tab is P3.13).

A gate floor's wild monsters come from an ENCOUNTER LIST (DATA_STRUCTURES
"Encounter pool entry"): five slots, each an enemy row + the chance that a
battle draws it (codes 0 / 10 / 20 / 30 / 40 / 50 / 70 / 100 %). The chances
must add up to exactly 100 % like every original list (the game walks the
running sums until one exceeds a 0-99 draw: under 100 it runs off the list,
over 100 the last slots are cut — the "Real chance" column shows it). "Max in a group" only matters for lists that can draw 2 or 3
monsters (1 = this monster always comes alone). The compiler's own checks run
on OK (editor2/core/gamedata.py) — a list that could freeze the game is refused.
"""

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (QComboBox, QDialog, QDialogButtonBox, QHBoxLayout,
                               QHeaderView, QLabel, QMessageBox, QPushButton,
                               QSpinBox, QTableWidget, QTableWidgetItem, QVBoxLayout)

HELP = ('Pick the gate floors, then put the monster in a slot. Each slot has a chance; '
        'together they must make exactly 100 %. Lists marked "(1 monster)" always give a '
        'one-monster battle; in the others "Max" says how many copies may come together '
        '(1 = only ever alone, 0 = never 2nd / 3rd).')


class PoolDialog(QDialog):
    def __init__(self, doc, enemy_ref, enemy_label, parent=None):
        super().__init__(parent)
        self.doc = doc
        self.ref = enemy_ref
        self.label = enemy_label
        self.pct = doc.chance_percent()
        self.result_slots = None
        self.setWindowTitle(f'Put {enemy_label} in a gate')
        self.resize(760, 420)
        v = QVBoxLayout(self)
        h = QLabel(HELP)
        h.setWordWrap(True)
        v.addWidget(h)
        row = QHBoxLayout()
        row.addWidget(QLabel('Gate floors'))
        self.pool = QComboBox()
        for pi, label in doc.gate_pools():
            self.pool.addItem(f'{label}   — list {pi}', pi)
        self.pool.currentIndexChanged.connect(self._load)
        row.addWidget(self.pool, 1)
        v.addLayout(row)
        self.size_note = QLabel()
        v.addWidget(self.size_note)
        self.table = QTableWidget(5, 4)
        self.table.setHorizontalHeaderLabels(['Monster (enemy row)', 'Chance', 'Real chance',
                                              'Max in a group'])
        self.table.horizontalHeader().setSectionResizeMode(0, QHeaderView.Stretch)
        self.table.verticalHeader().setVisible(True)
        v.addWidget(self.table, 1)
        b = QHBoxLayout()
        put = QPushButton(f'Put {enemy_label} in the selected slot')
        put.clicked.connect(self._put)
        b.addWidget(put)
        clr = QPushButton('Empty the selected slot')
        clr.clicked.connect(self._clear)
        b.addWidget(clr)
        b.addStretch(1)
        self.total = QLabel()
        b.addWidget(self.total)
        v.addLayout(b)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._load()

    # ------------------------------------------------------------ view
    def _load(self, *_a):
        pi = self.pool.currentData()
        view = self.doc.pool_slots(pi)
        self.size = view['size']
        multi = any(self.pct[c] for c in self.size[1:])
        self.multi = multi
        self.size_note.setText(
            'Battles from this list: ' + ', '.join(
                f'{n} monster{"s" if n > 1 else ""} {self.pct[c]} %'
                for n, c in zip((1, 2, 3), self.size) if self.pct[c])
            + ('' if multi else '   (1 monster)'))
        self.slots = [dict(s) for s in view['slots']]
        # the first free slot is selected: one click on "Put" does the usual thing
        free = next((k for k, s in enumerate(self.slots) if s['empty']), 0)
        self._fill()
        self.table.selectRow(free)

    def _fill(self):
        self.table.blockSignals(True)
        for k, s in enumerate(self.slots):
            it = QTableWidgetItem(s['name'])
            it.setFlags(it.flags() & ~Qt.ItemIsEditable)
            self.table.setItem(k, 0, it)
            c = QComboBox()
            for code, p in enumerate(self.pct):
                c.addItem(f'{p} %', code)
            c.setCurrentIndex(s['chance'])
            c.currentIndexChanged.connect(lambda _i, k=k, c=c: self._chance(k, c))
            self.table.setCellWidget(k, 1, c)
            m = QSpinBox()
            m.setRange(0, 3)
            m.setValue(s['max'])
            m.setEnabled(self.multi and not s['empty'])
            m.valueChanged.connect(lambda val, k=k: self._max(k, val))
            self.table.setCellWidget(k, 3, m)
        self.table.blockSignals(False)
        self._total()

    def _total(self):
        t, run = 0, 0
        for k, s in enumerate(self.slots):
            p = self.pct[s['chance']]
            real = max(0, min(100, run + p) - run)
            run += p
            it = QTableWidgetItem(f'{real} %' + ('  (cut)' if real < p else ''))
            it.setFlags(it.flags() & ~Qt.ItemIsEditable)
            self.table.setItem(k, 2, it)
            t += p
        ok = t == 100
        self.total.setText(f'<b style="color:{"#070" if ok else "#b00"}">total {t} %</b>'
                           + ('' if ok else (' — must reach 100 %' if t < 100 else
                                             ' — over 100 %: the last slots are cut')))

    def _chance(self, k, c):
        self.slots[k]['chance'] = c.currentData()
        self._total()

    def _max(self, k, val):
        self.slots[k]['max'] = val

    def _sel(self):
        r = self.table.currentRow()
        return r if r >= 0 else None

    def _put(self):
        k = self._sel()
        if k is None:
            return
        s = self.slots[k]
        filled = [x for x in self.slots if not x['empty']]
        s.update({'ref': self.ref, 'name': self.label, 'empty': False})
        if s['chance'] == 0:
            s['chance'] = 2                                  # 20 %
        if not self.multi:
            s['max'] = 1
        elif s['max'] == 0:
            maxes = [x['max'] for x in filled if x['max']]
            s['max'] = max(set(maxes), key=maxes.count) if maxes else 1
        self._fill()
        self.table.selectRow(k)

    def _clear(self):
        k = self._sel()
        if k is None:
            return
        self.slots[k].update({'ref': 0, 'eid': 0, 'chance': 0, 'max': 0, 'empty': True,
                              'name': '—'})
        self._fill()
        self.table.selectRow(k)

    def _ok(self):
        if sum(self.pct[s['chance']] for s in self.slots) != 100:
            QMessageBox.warning(self, 'Chances', 'The chances must add up to exactly 100 % '
                                '(see "Real chance").')
            return
        for s in self.slots:
            if s['chance'] and s['empty']:
                QMessageBox.warning(self, 'Chances', 'An empty slot has a chance — set it '
                                    'to 0 % or put a monster in it.')
                return
        self.result_pool = self.pool.currentData()
        self.result_slots = [(0 if s['empty'] else s['ref'], s['chance'],
                              0 if s['empty'] else s['max']) for s in self.slots]
        self.accept()
