"""gates_tab.py — Gates tab v1 (S100, ROADMAP P3.7b part 1; EDITOR_DESIGN §5.1b).

Left: the 32 vanilla gates (ROM-derived names + floor counts, extracted/
gate_names.json). Right: the selected gate's FLOOR PLAN — what the game
serves on each floor — and its CUSTOM ROOMS: ordered rules "serve room R on
floors a-b with chance p % [once per dive] [when flags …]".

How the game decides (measured S100, GATE_GENERATION §3 + §7.6): the boss
floor is fixed; on every other floor the rules of that gate are tried top
down — the first whose floors, once-per-dive state and flag conditions hold
rolls its chance; a hit serves the room, a miss tries the next rule; if no
rule serves, the vanilla choice runs (maze, or on floors 3, 6, 9 … a ~50 %
special room — never in the Gate of Beginning). The first floor stays the
gate's own unless the gate is HAND-MADE.

Gate settings (S101, P3.7b part 2): floor count 2-99 (incl. the boss floor),
the boss floor (vanilla / another gate's vanilla boss room / any custom room,
arriving on its "Inside gates" cell), hand-made (rules may take floor 1).

NEW gates (S115, ROADMAP NG1): "New gate…" adds gate 32-95 as a copy of a
vanilla gate (its maze look, special rooms, depth tier and — until edited —
floor count, boss room and monsters); rename / delete; the head line lists
its entrances (Rooms tab: "Gate entrance here"). Monsters per floor are on
the Encounters tab. Still to come: floor weighting, private floor types.

Every edit is one undo step (SnapshotCommand).
"""

import os

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QColor, QPixmap
from PySide6.QtWidgets import (QAbstractItemView, QCheckBox, QComboBox, QDialog,
                               QDialogButtonBox, QFormLayout, QGroupBox, QHBoxLayout,
                               QHeaderView, QInputDialog, QLabel, QListWidget,
                               QLineEdit, QListWidgetItem, QMessageBox, QPushButton,
                               QSpinBox,
                               QSplitter, QTableWidget, QTableWidgetItem, QToolButton,
                               QVBoxLayout, QWidget)

from editor2.app.rooms import commands as C
from editor2.app.rooms.rules_panel import WELL_KNOWN, well_known
from editor2.core import gates as G
from editor2.core.document import val

HELP = ('Custom rooms are tried top-down on every floor except the first and the boss '
        'floor: the first rule whose floors, "once per dive" and flag conditions hold rolls '
        'its chance — a hit serves the room, a miss tries the next rule, and when nothing is '
        'served the game makes its usual choice (the maze, or on floors 3, 6, 9 … a special '
        'room about half the time). The floor plan follows one dive floor by floor, so a '
        '"once per dive" room served early is not counted again later.')


class GateRuleDialog(QDialog):
    """One rule: room, floors, chance, once per dive, flag conditions."""

    def __init__(self, doc, gate, rule=None, parent=None):
        super().__init__(parent)
        self.doc, self.gate = doc, gate
        self.floors = gate['floors']
        self.setWindowTitle(f"Custom room in {gate['name']}")
        self.resize(600, 520)
        # S100 (user, 14:39): a new rule starts as once per dive — a gate room that
        # can come back on the next floor surprised the user in the example project.
        rule = dict(rule or {'gate': gate['id'], 'floors': 'all', 'chance': 100,
                             'once_per_dive': True})
        v = QVBoxLayout(self)
        f = QFormLayout()
        self.room = QComboBox()
        for r in doc.rooms:
            if r.get('placeholder'):
                continue
            rep = doc.gate_room_report(r)
            mark = '' if rep['ready'] else '   ⚠ not ready'
            self.room.addItem(f"${val(r['mapID']):02X} {doc.room_name(r)}{mark}", r['id'])
        i = self.room.findData(rule.get('room'))
        self.room.setCurrentIndex(max(i, 0))
        self.room.currentIndexChanged.connect(self._room_changed)
        f.addRow('room', self.room)
        self.ready = QLabel('')
        self.ready.setWordWrap(True)
        f.addRow('', self.ready)
        fr = QHBoxLayout()
        self.any = QCheckBox('any floor')
        self.f_from = QSpinBox()
        self.f_to = QSpinBox()
        self.min_floor = gate.get('min_floor', G.MIN_FLOOR)
        last = max(self.min_floor, self.floors - 1)
        for sb in (self.f_from, self.f_to):
            sb.setRange(self.min_floor, last)
        fr.addWidget(self.any)
        fr.addWidget(QLabel('  floors'))
        fr.addWidget(self.f_from)
        fr.addWidget(QLabel('to'))
        fr.addWidget(self.f_to)
        fr.addStretch(1)
        f.addRow('where', fr)
        f.addRow('', QLabel(f"{gate['name']} has {self.floors} floors: "
                            + ("every floor is yours (hand-made gate)"
                               if self.min_floor == 1 else "floor 1 stays the gate's own")
                            + f", floor {self.floors} is the boss."))
        spec = rule.get('floors', 'all')
        if spec in (None, 'all', 'any'):
            self.any.setChecked(True)
            self.f_from.setValue(self.min_floor)
            self.f_to.setValue(last)
        else:
            a, b = G.floor_range(spec, self.floors, self.min_floor)
            self.f_from.setValue(a)
            self.f_to.setValue(b)
        self.any.toggled.connect(lambda on: (self.f_from.setEnabled(not on),
                                             self.f_to.setEnabled(not on)))
        self.f_from.setEnabled(not self.any.isChecked())
        self.f_to.setEnabled(not self.any.isChecked())
        self.f_from.valueChanged.connect(lambda x: self.f_to.setValue(max(x, self.f_to.value())))
        self.f_to.valueChanged.connect(lambda x: self.f_from.setValue(min(x, self.f_from.value())))
        self.chance = QSpinBox()
        self.chance.setRange(1, 100)
        self.chance.setSuffix(' %')
        self.chance.setValue(int(G._val(rule.get('chance', 100))))
        self.chance.setToolTip('Rolled on each floor in range (after the other conditions '
                               'hold). 100 % = always.')
        f.addRow('chance', self.chance)
        # S127 (P3.14e2): the chance rising (or falling) with the party's average level
        cb = rule.get('chance_by_level') or {}
        self.by_level = QCheckBox('the chance follows the party\'s average level:')
        self.by_level.setChecked(bool(cb))
        lv = QHBoxLayout()
        self.lv_from, self.pc_from, self.lv_to, self.pc_to = (QSpinBox() for _ in range(4))
        for sb, lo, hi, dv, suf in ((self.lv_from, 1, 98, 5, ''), (self.pc_from, 0, 100, 10, ' %'),
                                    (self.lv_to, 2, 99, 40, ''), (self.pc_to, 0, 100, 60, ' %')):
            sb.setRange(lo, hi)
            sb.setValue(dv)
            sb.setSuffix(suf)
        if cb:
            try:
                self.lv_from.setValue(int(cb['from'][0]))
                self.pc_from.setValue(int(cb['from'][1]))
                self.lv_to.setValue(int(cb['to'][0]))
                self.pc_to.setValue(int(cb['to'][1]))
            except (KeyError, TypeError, ValueError, IndexError):
                pass
        for wdg in (QLabel('level'), self.lv_from, QLabel('→'), self.pc_from,
                    QLabel('   level'), self.lv_to, QLabel('→'), self.pc_to):
            lv.addWidget(wdg)
        lv.addStretch(1)
        f.addRow(self.by_level)
        f.addRow('', lv)
        self.by_level.setToolTip('The chance is worked out from the party\'s average level '
                                 'each time the floor is made: the first chance up to the '
                                 'first level, the second from the second level on, a straight '
                                 'line between. "chance" above is not used then.')
        self.by_level.toggled.connect(self._by_level_toggled)
        self._by_level_toggled(self.by_level.isChecked())
        self.every = QCheckBox('every gate (the floors before each gate\'s boss; with '
                               '"at most once per dive" at most once in each dive)')
        self.every.setChecked(rule.get('gate') == 'any')
        f.addRow('', self.every)
        self.once = QCheckBox('at most once per dive (resets when a new dive starts; '
                              'kept through a save)')
        self.once.setChecked(bool(rule.get('once_per_dive')))
        f.addRow('', self.once)
        v.addLayout(f)
        v.addWidget(QLabel('Only when (all must hold — none = always):'))
        self.table = QTableWidget(0, 2)
        self.table.setHorizontalHeaderLabels(['flag', 'must be'])
        self.table.horizontalHeader().setStretchLastSection(True)
        self.table.setColumnWidth(0, 340)
        v.addWidget(self.table, 1)
        trow = QHBoxLayout()
        b = QPushButton('+ condition')
        b.clicked.connect(lambda: self._add_term({}))
        trow.addWidget(b)
        b = QPushButton('− condition')
        b.clicked.connect(self._del_term)
        trow.addWidget(b)
        b = QPushButton('New named flag…')
        b.setToolTip('A project flag, auto-allocated from the safe pool (saved with the '
                     'game). Talk scripts / examine spots set it.')
        b.clicked.connect(self._new_flag)
        trow.addWidget(b)
        trow.addStretch(1)
        v.addLayout(trow)
        for t in rule.get('when') or []:
            self._add_term(t)
        self.comment = rule.get('comment')
        self.warn = QLabel('')
        self.warn.setStyleSheet('color:#e0b040;')
        self.warn.setWordWrap(True)
        v.addWidget(self.warn)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self.new_flags = []
        self._room_changed()

    def _room_changed(self, *_a):
        rid = self.room.currentData()
        if rid is None:
            self.ready.setText('Make a custom room first (Rooms tab).')
            return
        rep = self.doc.gate_room_report(self.doc.room(rid))
        if rep['ready']:
            self.ready.setStyleSheet('color:#7fd67f;')
            self.ready.setText('Ready: ' + ' · '.join(rep['notes']))
        else:
            self.ready.setStyleSheet('color:#e0b040;')
            self.ready.setText('Needs (Rooms tab → "Inside gates"): '
                               + '; '.join(rep['problems']))

    # flag conditions (same shape as the room state-rule dialog)
    def _flag_combo(self, value=None):
        c = QComboBox()
        c.setEditable(True)
        for fl in self.doc.flags():
            c.addItem(f"{fl['name']}  (project flag)", fl['name'])
        for nm in self.new_flags if hasattr(self, 'new_flags') else []:
            c.addItem(f'{nm}  (new project flag)', nm)
        for idx, name in well_known(self.doc):
            c.addItem(f'{idx}  {name}', idx)
        if value is not None:
            i = c.findData(value)
            if i >= 0:
                c.setCurrentIndex(i)
            else:
                c.setEditText(str(value))
        return c

    def _add_term(self, t):
        r = self.table.rowCount()
        self.table.insertRow(r)
        self.table.setCellWidget(r, 0, self._flag_combo(t.get('flag')))
        s = QComboBox()
        s.addItem('set', 'set')
        s.addItem('clear', 'clear')
        s.setCurrentIndex(1 if t.get('is') == 'clear' else 0)
        self.table.setCellWidget(r, 1, s)

    def _del_term(self):
        r = self.table.currentRow()
        if r < 0:
            r = self.table.rowCount() - 1
        if r >= 0:
            self.table.removeRow(r)

    def _new_flag(self):
        name, ok = QInputDialog.getText(self, 'New flag', 'Flag name (letters, digits, _):')
        if not ok or not name.strip():
            return
        nm = self.doc._slug(name.strip())
        if not nm:
            return
        if nm not in {fl['name'] for fl in self.doc.flags()} | set(self.new_flags):
            self.new_flags.append(nm)
            for r in range(self.table.rowCount()):
                self.table.cellWidget(r, 0).addItem(f'{nm}  (new project flag)', nm)
        r = self.table.currentRow()
        if r < 0:
            self._add_term({'flag': nm})
            r = self.table.rowCount() - 1
        c = self.table.cellWidget(r, 0)
        c.setCurrentIndex(c.findData(nm))

    @staticmethod
    def _term_value(combo):
        d = combo.currentData()
        txt = combo.currentText().strip()
        if d is not None and combo.itemText(combo.currentIndex()) == txt:
            return d
        return txt.split()[0] if txt else None

    def _by_level_toggled(self, on):
        self.chance.setEnabled(not on)
        for sb in (self.lv_from, self.pc_from, self.lv_to, self.pc_to):
            sb.setEnabled(on)

    def rule(self):
        r = {'room': self.room.currentData(),
             'gate': 'any' if self.every.isChecked() else self.gate['id']}
        if self.any.isChecked():
            r['floors'] = 'all'
        else:
            a, b = self.f_from.value(), self.f_to.value()
            r['floors'] = [a] if a == b else [a, b]
        r['chance'] = self.chance.value()
        if self.by_level.isChecked():
            r['chance_by_level'] = {'from': [self.lv_from.value(), self.pc_from.value()],
                                    'to': [self.lv_to.value(), self.pc_to.value()]}
        if self.once.isChecked():
            r['once_per_dive'] = True
        terms = []
        for i in range(self.table.rowCount()):
            fl = self._term_value(self.table.cellWidget(i, 0))
            if not fl:
                continue
            t = {'flag': fl}
            if self.table.cellWidget(i, 1).currentData() == 'clear':
                t['is'] = 'clear'
            terms.append(t)
        if terms:
            r['when'] = terms
        if self.comment:
            r['comment'] = self.comment
        return r

    def _ok(self):
        if self.room.currentData() is None:
            self.warn.setText('Pick a room.')
            return
        if self.by_level.isChecked() and self.lv_from.value() >= self.lv_to.value():
            self.warn.setText('The second level must be higher than the first.')
            return
        if self.table.rowCount() > G.MAX_TERMS:
            self.warn.setText(f'At most {G.MAX_TERMS} conditions.')
            return
        self.accept()


class NewGateDialog(QDialog):
    """S115 (NG1): a new gate = a copy of a vanilla gate, with a name."""

    def __init__(self, doc, parent=None, start=0):
        super().__init__(parent)
        self.setWindowTitle('New gate')
        self.resize(460, 220)
        self.van = G.vanilla_gates(getattr(doc, 'project_dir', None))
        v = QVBoxLayout(self)
        f = QFormLayout()
        self.src = QComboBox()
        for g in self.van:
            self.src.addItem(f"{g['id']:2d}  {g['name']} — {g['floors']} floors", g['id'])
        self.src.setCurrentIndex(max(0, min(int(start), 31)))
        self.src.currentIndexChanged.connect(self._src_changed)
        f.addRow('copy of', self.src)
        self.name = QLineEdit()
        self.name.setPlaceholderText('e.g. Ember Gate')
        f.addRow('name', self.name)
        self.floors = QSpinBox()
        self.floors.setRange(G.FLOORS_MIN, G.FLOORS_MAX)
        self.floors.setToolTip('Floors in one dive, INCLUDING the boss floor')
        f.addRow('floors', self.floors)
        v.addLayout(f)
        note = QLabel('The new gate looks like the one it copies (maze floors, special rooms, '
                      'depth tier) and starts with its boss room and monsters. Give it a custom '
                      'boss room (a vanilla one runs its own story scripts) and its own monsters '
                      '(Encounters tab), then put an entrance on a room cell (Rooms tab → '
                      '"Gate entrance here").')
        note.setWordWrap(True)
        note.setStyleSheet('color:#aaa;')
        v.addWidget(note)
        self.warn = QLabel('')
        self.warn.setStyleSheet('color:#e0b040;')
        v.addWidget(self.warn)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._src_changed(self.src.currentIndex())

    def _src_changed(self, i):
        self.floors.setValue(self.van[max(i, 0)]['floors'])

    def _ok(self):
        if not self.name.text().strip():
            self.warn.setText('Give the gate a name.')
            return
        self.accept()

    def values(self):
        src = self.src.currentData()
        n = self.floors.value()
        van = self.van[src]['floors']
        return src, self.name.text().strip(), (None if n == van else n)


class GatesTab(QWidget):
    openRoomRequested = Signal(str)          # custom room id

    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.gates = self.s.doc.all_gates()
        split = QSplitter(Qt.Horizontal, self)
        lay = QVBoxLayout(self)
        lay.setContentsMargins(0, 0, 0, 0)
        lay.addWidget(split)
        self.list = QListWidget()
        self.list.setMinimumWidth(240)
        self.list.currentRowChanged.connect(self._show_gate)
        left = QWidget()
        lv = QVBoxLayout(left)
        lv.setContentsMargins(0, 0, 0, 0)
        lv.addWidget(self.list)
        nrow = QHBoxLayout()
        for text, fn, tip in (
                ('New gate…', self._new_gate, 'A brand-new gate (32-95) made as a copy of a '
                                             'vanilla gate'),
                ('Rename…', self._rename_gate, 'Rename the selected NEW gate'),
                ('Delete', self._delete_gate, 'Delete the selected NEW gate (its custom-room '
                                              'rules and entrances go too)')):
            b = QPushButton(text)
            b.setToolTip(tip)
            b.clicked.connect(fn)
            nrow.addWidget(b)
            if text != 'New gate…':
                setattr(self, '_btn_' + text.strip('.…').lower(), b)
        lv.addLayout(nrow)
        split.addWidget(left)
        right = QWidget()
        rv = QVBoxLayout(right)
        self.head = QLabel('')
        self.head.setWordWrap(True)
        self.head.setStyleSheet('font-size: 14px;')
        rv.addWidget(self.head)
        self.sub = QLabel('')
        self.sub.setWordWrap(True)
        self.sub.setStyleSheet('color:#aaa;')
        rv.addWidget(self.sub)
        sg = QGroupBox('Gate settings')
        sf = QFormLayout(sg)
        frow = QHBoxLayout()
        self.set_floors = QSpinBox()
        self.set_floors.setRange(G.FLOORS_MIN, G.FLOORS_MAX)
        self.set_floors.setToolTip('Floors in one dive, INCLUDING the boss floor (the game '
                                   'serves the boss when floor = this count).')
        self.set_floors.editingFinished.connect(self._set_floors)
        frow.addWidget(self.set_floors)
        self.floors_note = QLabel('')
        self.floors_note.setStyleSheet('color:#aaa;')
        frow.addWidget(self.floors_note, 1)
        b = QToolButton()
        b.setText('Vanilla')
        b.setToolTip("Back to the game's own floor count")
        b.clicked.connect(lambda: self._setting('floors', None, 'Vanilla floor count'))
        frow.addWidget(b)
        sf.addRow('floors', frow)
        brow = QHBoxLayout()
        self.set_boss = QComboBox()
        self.set_boss.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.set_boss.setMinimumContentsLength(28)
        self.set_boss.activated.connect(self._set_boss)
        brow.addWidget(self.set_boss, 1)
        b = QToolButton()
        b.setText('Open room')
        b.setToolTip('Edit the boss room in the Rooms tab')
        b.clicked.connect(self._open_boss)
        brow.addWidget(b)
        sf.addRow('boss floor', brow)
        self.boss_note = QLabel('')
        self.boss_note.setWordWrap(True)
        sf.addRow('', self.boss_note)
        self.set_hand = QCheckBox('hand-made gate: every floor is one of my rooms '
                                  '(rules may take floor 1)')
        self.set_hand.setToolTip('The first floor normally stays the gate\'s own maze. A '
                                 'hand-made gate serves your rooms from floor 1; give every '
                                 'floor a room that is always served (the floor plan shows '
                                 'the maze where none is).')
        self.set_hand.clicked.connect(lambda on: self._setting('hand_made', bool(on),
                                                               'Hand-made gate' if on else
                                                               'Gate floors: vanilla first floor'))
        sf.addRow('', self.set_hand)
        # S123 (NG3: "portal stops when boss beaten, OR portal is different
        # colour when boss beaten"): what this gate's swirls do once cleared
        self.set_swirl = QComboBox()
        self.set_swirl.addItem("stops (the game's way)", None)
        for p in range(8):
            self.set_swirl.addItem(f'turns {G.OBJ_PALETTE_NAMES[p]} (palette {p})', p)
        self.set_swirl.setToolTip('What the spinning swirl on this gate\'s portals does once '
                                  'the gate is cleared: stop (the game\'s way), or keep spinning '
                                  'in one of the 8 sprite colours (green = palette 1). Applies '
                                  'to the entrances you add and to re-routed / re-bossed '
                                  'vanilla portals.')
        self.set_swirl.activated.connect(lambda _i: self._setting(
            'cleared_swirl', self.set_swirl.currentData(), 'Swirl after clearing'))
        sf.addRow('after clearing, the swirl', self.set_swirl)
        er = QHBoxLayout()
        b = QPushButton('Project enemies…')
        b.setToolTip('Your own enemies for boss battles (conversation Battle steps): stats, '
                     'skills, always / sometimes / never joins, a weaker join version')
        b.clicked.connect(self._enemies)
        er.addWidget(b)
        er.addStretch(1)
        sf.addRow('', er)
        rv.addWidget(sg)
        self._world_boxes = [sg]                      # S123: off for a world (World tab)
        # S120 (ROADMAP P3.7b part 2): the floor-type rows + depth tier (bytes 0-2, 7)
        mg = QGroupBox('Maze floors — look, special rooms, contents (shared rows: pick the '
                       'row of the gates you want it to feel like)')
        mf = QFormLayout(mg)
        self.row_combos = {}
        for key, label, tip in (
                ('maze_row', 'maze look', 'Which maze floor types the gate rolls (pictures '
                                          'below) — FloorTypeSelectionTable, byte 0.'),
                ('special_row', 'special rooms', 'What floors 3, 6, 9 … may be instead of a '
                                                 'maze (about half the time; never in gate 0) '
                                                 '— FloorTypeSelectionTable2, byte 1.'),
                ('contents_row', 'contents', 'The mix of things lying on the floors (and the '
                                             'treasure rooms\' chests) — '
                                             'FloorTypeSelectionTable3, byte 2.')):
            cb = QComboBox()
            cb.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
            cb.setMinimumContentsLength(24)
            cb.setToolTip(tip)
            cb.activated.connect(lambda _i, k=key: self._set_row(k))
            self.row_combos[key] = cb
            if key == 'maze_row':
                # the row's floor types as the game draws them, beside the picker
                hb = QHBoxLayout()
                hb.addWidget(cb, 1)
                self.maze_pics = QLabel()
                self.maze_pics.setToolTip('The maze floor types this row rolls, as the game '
                                          'draws them (tools/census_gate_floor_types.py)')
                hb.addWidget(self.maze_pics)
                mf.addRow(label, hb)
            else:
                mf.addRow(label, cb)
        drow = QHBoxLayout()
        self.set_depth = QSpinBox()
        self.set_depth.setRange(1, 3)
        self.set_depth.setToolTip('Byte 7: the tier of the items lying on maze floors (bank $01: '
                                  '1 = early items, 2 = later ones, 3 = the deepest gates)')
        self.set_depth.editingFinished.connect(lambda: self._set_row('depth'))
        drow.addWidget(self.set_depth)
        self.depth_note = QLabel('')
        self.depth_note.setStyleSheet('color:#aaa;')
        drow.addWidget(self.depth_note, 1)
        b = QToolButton()
        b.setText('Vanilla')
        b.setToolTip("Back to the gate's own rows and tier (a new gate: its source's)")
        b.clicked.connect(self._rows_vanilla)
        drow.addWidget(b)
        mf.addRow('item tier', drow)
        rv.addWidget(mg)
        self._world_boxes.append(mg)
        g = QGroupBox('Custom rooms in this gate — tried top-down')
        gv = QVBoxLayout(g)
        self.rules = QTableWidget(0, 6)
        self.rules.setHorizontalHeaderLabels(['#', 'room', 'floors', 'chance', 'also',
                                              'room ready?'])
        self.rules.verticalHeader().setVisible(False)
        self.rules.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.rules.setSelectionMode(QAbstractItemView.SingleSelection)
        self.rules.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.rules.horizontalHeader().setSectionResizeMode(4, QHeaderView.Stretch)
        self.rules.horizontalHeader().setSectionResizeMode(5, QHeaderView.Stretch)
        self.rules.cellDoubleClicked.connect(lambda *_a: self._edit())
        gv.addWidget(self.rules)
        row = QHBoxLayout()
        for text, fn, tip in (('Add…', self._add, 'Serve a custom room on floors of this gate'),
                              ('Edit…', self._edit, 'Edit the selected rule'),
                              ('Remove', self._remove, 'Remove the selected rule'),
                              ('▲', lambda: self._move(-1), 'Try earlier'),
                              ('▼', lambda: self._move(1), 'Try later'),
                              ('Open room', self._open_room, 'Edit the room in the Rooms tab')):
            b = QToolButton()
            b.setText(text)
            b.setToolTip(tip)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        gv.addLayout(row)
        rv.addWidget(g, 2)
        self._world_boxes.append(g)
        g = QGroupBox('Floor plan — what each floor can be, in one dive')
        gv = QVBoxLayout(g)
        self.flags_hold = QCheckBox('assume the rules\' flag conditions hold')
        self.flags_hold.setChecked(True)
        self.flags_hold.setToolTip('Rules with "only when" flag conditions serve only when their '
                                   'flags are as required. Untick to see the dive before '
                                   'those flags are set.')
        self.flags_hold.toggled.connect(lambda _on: self._show_gate(self.list.currentRow()))
        gv.addWidget(self.flags_hold)
        self.plan = QTableWidget(0, 2)
        self.plan.setHorizontalHeaderLabels(['floor', 'what the game serves'])
        self.plan.verticalHeader().setVisible(False)
        self.plan.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.plan.horizontalHeader().setSectionResizeMode(1, QHeaderView.Stretch)
        gv.addWidget(self.plan)
        rv.addWidget(g, 3)
        hl = QLabel(HELP)
        hl.setWordWrap(True)
        hl.setStyleSheet('color:#999;')
        rv.addWidget(hl)
        nl = QLabel('Boss rooms (S101): any custom room — its "Inside gates" arrival cell is '
                    'where the player appears; the fight is a conversation (NPC or arrival) '
                    'with a Battle step. New gates (S115): "New gate…" below the list; '
                    'entrances on the Rooms tab ("Gate entrance here"); monsters per floor on '
                    'the Encounters tab. Maze floors (S120): pick each row from the gates you '
                    'want it to feel like.')
        nl.setWordWrap(True)
        nl.setStyleSheet('color:#777;')
        rv.addWidget(nl)
        # S120: the panel scrolls instead of squeezing its groups (the Maze floors group
        # made it taller than a laptop screen)
        from PySide6.QtWidgets import QScrollArea
        sa = QScrollArea()
        sa.setWidgetResizable(True)
        sa.setWidget(right)
        right.setMinimumHeight(980)
        split.addWidget(sa)
        split.setStretchFactor(1, 1)
        self.s.structureChanged.connect(self.refresh)
        self.refresh()
        self.list.setCurrentRow(1 if len(self.gates) > 1 else 0)

    # ------------------------------------------------------------ views
    def refresh(self):
        cur = max(self.list.currentRow(), 0)
        self.gates = self.s.doc.all_gates()
        self.list.blockSignals(True)
        self.list.clear()
        for g in self.gates:
            n = len(self.s.doc.gate_rules_for(g['id']))
            gs = self.s.doc.gate_setting(g['id'])
            fl = self.s.doc.gate_floor_count(g['id'])
            world = gs.get('world') is not None                  # S123
            it = QListWidgetItem(f"{g['id']:2d}  {g['name']} — "
                                 + ('a world   WORLD' if world else
                                    f"{fl} fl"
                                    + (f"   ★{n}" if n else '')
                                    + ('   ♛' if gs.get('boss') else '')
                                    + ('   ✎' if gs.get('hand_made') else '')
                                    + ('   NEW' if g.get('new') else '')))
            if world:
                it.setToolTip('a WORLD (S123): rooms joined by doors, entered through its portal '
                              'like a gate — edit it on the World tab')
                it.setForeground(QColor(120, 220, 120))
            elif g.get('new'):
                it.setToolTip(f"new gate — a copy of gate {g['copy_of']} "
                              f"({self.gates[g['copy_of']]['name']}) · depth tier "
                              f"{g['depth_tier']}")
                it.setForeground(QColor(255, 170, 60))
            else:
                it.setToolTip(f"boss room {g['boss_map']} {g['boss_room']} · depth tier "
                              f"{g['depth_tier']} · FAQ: {g['faq_name']}")
            if (n or gs) and not g.get('new'):
                it.setForeground(QColor(0, 200, 255))
            self.list.addItem(it)
        self.list.setCurrentRow(min(cur, self.list.count() - 1))
        self.list.blockSignals(False)
        self._show_gate(self.list.currentRow())

    def gate(self, i=None):
        """The selected gate with the PROJECT's floor count / first floor."""
        i = self.list.currentRow() if i is None else i
        if not 0 <= i < len(self.gates):
            return None
        g = dict(self.gates[i])
        g['floors'] = self.s.doc.gate_floor_count(g['id'])
        g['min_floor'] = self.s.doc.gate_min_floor(g['id'])
        return g

    def _show_gate(self, i):
        if not 0 <= i < len(self.gates):
            return
        g = self.gate(i)
        doc = self.s.doc
        self._show_settings(g)
        new = bool(g.get('new'))
        self._btn_rename.setEnabled(new)
        self._btn_delete.setEnabled(new)
        self.head.setText(f"<b>{g['name']}</b>  (gate {g['id']}"
                          + (f" — NEW, a copy of {self.gates[g['copy_of']]['name']})"
                             if new else ')'))
        ents = doc.gate_entrances(g['id'])
        places = [f"{doc.room_name(r)} screen {k} ({e['x']},{e['y']})" for r, k, _n, e in ents]
        for _i, rd in doc.portal_redirects(g['id']):      # S117: re-routed vanilla portals
            places.append(f"vanilla {rd['mapID']} screen {rd['screen']} portal ({rd['x']},{rd['y']})")
        if places:
            where = ', '.join(places[:3]) + (' …' if len(places) > 3 else '')
            ent = f" · entrance: {where}"
        elif new:
            ent = (" · ⚠ no entrance yet — Rooms tab: pick a cell, then "
                   "\"Gate entrance here\"")
        else:
            ent = ''
        world = doc.world(g['id']) is not None                          # S123
        for box in self._world_boxes:
            box.setEnabled(not world)
        if world:
            self.head.setText(f"<b>{g['name']}</b>  (gate {g['id']}) — a WORLD")
            self.sub.setText('A world is not a random gate: its portal enters its start room '
                             'exactly like a gate entrance, and its rooms are joined by doors. '
                             'Edit it on the World tab (rooms, start, saving, the swirl after '
                             'clearing). ' + doc.gate_cleared_text(g['id']) + ent)
            self.rules.setRowCount(0)
            self.plan.setRowCount(0)
            return
        rs = G.row_settings(doc.custom, g['id'], getattr(doc, 'project_dir', None))   # S120
        self.sub.setText(f"{g['floors']} floors — boss on floor {g['floors']} "
                         f"({doc.gate_boss_label(g['id'])}) · item tier {rs['depth']} · floor-type rows "
                         f"{rs['maze_row']}/{rs['special_row']}/{rs['contents_row']}"
                         + (' · no special rooms in this gate' if g['id'] == 0 else '')
                         + ent
                         + (f" · {doc.gate_cleared_text(g['id'])}" if doc.gate_cleared_text(g['id'])
                            else ''))
        rules = doc.gate_rules_for(g['id'])
        self.rules.setRowCount(len(rules))
        for row, (idx, r) in enumerate(rules):
            try:
                room = doc.room(r.get('room'))
                rname = doc.room_name(room)
                rep = doc.gate_room_report(room)
            except KeyError:
                room, rname, rep = None, f"{r.get('room')} (missing)", None
            also = []
            if r.get('gate') == 'any':
                also.append('every gate')                         # S127
            if r.get('once_per_dive'):
                also.append('once per dive')
            for t in r.get('when') or []:
                also.append(f"{t.get('flag')} {'clear' if t.get('is') == 'clear' else 'set'}")
            cells = [str(row + 1), rname, G.floors_text(r.get('floors', 'all'), g['floors'],
                                                        g['min_floor']),
                     G.chance_text(r), ', '.join(also) or '—',
                     ('✓ ' + ' · '.join(rep['notes'])) if rep and rep['ready'] else
                     ('⚠ ' + '; '.join(rep['problems']) if rep else '⚠ room missing')]
            for c, txt in enumerate(cells):
                it = QTableWidgetItem(txt)
                it.setData(Qt.UserRole, idx)
                if c == 5:
                    it.setForeground(QColor(120, 210, 120) if rep and rep['ready']
                                     else QColor(230, 180, 60))
                    it.setToolTip(txt)
                self.rules.setItem(row, c, it)
        self.rules.resizeColumnsToContents()
        plan = doc.gate_floor_plan(g['id'], flags_hold=self.flags_hold.isChecked())
        self.plan.setRowCount(len(plan))
        for row, (fl, items, van, vp) in enumerate(plan):
            self.plan.setItem(row, 0, QTableWidgetItem(str(fl)))
            parts = []
            shown = False
            for rid, p, _r in items:
                if p <= 0.0005:
                    continue                    # cannot be served here in this dive
                try:
                    nm = doc.room_name(doc.room(rid))
                except KeyError:
                    nm = rid
                parts.append(f'{nm} {p * 100:.0f} %')
                shown = True
            if van and vp > 0.0005:
                parts.append((f'{van} ' + (f'{vp * 100:.0f} %' if shown else '')).strip())
            it = QTableWidgetItem('  ·  '.join(parts))
            if shown:
                it.setForeground(QColor(0, 200, 255))
            elif fl == g['floors']:
                it.setForeground(QColor(230, 120, 120))
            self.plan.setItem(row, 1, it)

    def _show_settings(self, g):
        doc = self.s.doc
        gs = doc.gate_setting(g['id'])
        src = g['copy_of'] if g.get('new') else g['id']      # S115: a new gate's source
        van = next(x for x in self.gates if x['id'] == src)
        self.set_floors.blockSignals(True)
        self.set_floors.setValue(g['floors'])
        self.set_floors.blockSignals(False)
        self.floors_note.setText(f"incl. the boss floor · vanilla {van['floors']}"
                                 + ('' if gs.get('floors') is None else ' (changed)'))
        self.set_boss.blockSignals(True)
        self.set_boss.clear()
        self.set_boss.addItem(f"Vanilla — {van['boss_room']}"
                              + ('  (⚠ runs that gate\'s story scripts)' if g.get('new') else ''),
                              None)
        for x in self.gates:
            if x['id'] != g['id'] and not x.get('new'):
                self.set_boss.addItem(f"Vanilla room of {x['name']} — {x['boss_room']}",
                                      f"vanilla:${int(x['boss_map'], 16):02X}")
        for r in doc.rooms:
            if r.get('placeholder'):
                continue
            mark = '' if r.get('gate_arrival') else '   ⚠ no arrival cell'
            self.set_boss.addItem(f"Custom room ${val(r['mapID']):02X} {doc.room_name(r)}{mark}",
                                  r['id'])
        i = self.set_boss.findData(gs.get('boss'))
        self.set_boss.setCurrentIndex(max(i, 0))
        self.set_boss.blockSignals(False)
        self.set_hand.setChecked(bool(gs.get('hand_made')))
        try:                                                 # S123: swatches when the ROM is there
            from editor2.app.rooms.npc_panel import NpcPanel
            from editor2.app.world_tab import _swatch_icon
            if NpcPanel.OBJ_PAL is None:
                NpcPanel.load_obj_palettes(self.s.renderer.rom)
            if NpcPanel.OBJ_PAL:
                for p in range(8):
                    self.set_swirl.setItemIcon(p + 1, _swatch_icon(NpcPanel.OBJ_PAL[p]))
        except Exception:                                  # noqa: BLE001
            pass
        self.set_swirl.setCurrentIndex(max(0, self.set_swirl.findData(
            G.cleared_swirl(doc.custom, g['id']))))
        self._show_rows(g)
        b = gs.get('boss')
        if b and not str(b).startswith('vanilla:'):
            try:
                r = doc.room(b)
            except KeyError:
                r = None
            if r is None:
                self.boss_note.setStyleSheet('color:#e0b040;')
                self.boss_note.setText(f'Room {b} is missing.')
            else:
                bits = []
                arr = r.get('gate_arrival')
                bits.append(f"arrival screen {arr['screen']} ({arr['x']},{arr['y']})" if arr
                            else '⚠ no arrival cell — Rooms tab → Inside gates')
                bits.append('no saving' if not r.get('can_save', False) else '⚠ saving allowed')
                bits.append(f"song {r['music']}" if r.get('music')
                            else '⚠ no song (the gate theme keeps playing)')
                self.boss_note.setStyleSheet('color:#7fd67f;' if arr else 'color:#e0b040;')
                self.boss_note.setText('Boss room: ' + ' · '.join(bits) + '. The fight is a '
                                       'conversation with a Battle step (an NPC, or "on '
                                       'arrival").')
        elif b:
            self.boss_note.setStyleSheet('color:#aaa;')
            self.boss_note.setText('A vanilla boss room reused here — it runs its own vanilla '
                                   'scripts (and sets vanilla story flags).')
        else:
            self.boss_note.setStyleSheet('color:#aaa;')
            self.boss_note.setText('')

    def _show_rows(self, g):
        """S120: the maze-look / special / contents rows and the item tier of gate g."""
        doc = self.s.doc
        ft = G.floor_types(getattr(doc, 'project_dir', None))
        names = {x['id']: x['name'] for x in self.gates}
        rs = G.row_settings(doc.custom, g['id'], getattr(doc, 'project_dir', None))
        for key, kind in (('maze_row', 'maze'), ('special_row', 'special'),
                          ('contents_row', 'contents')):
            cb = self.row_combos[key]
            cb.blockSignals(True)
            cb.clear()
            for r in range(16):
                txt = G.row_summary(kind, r, getattr(doc, 'project_dir', None), names)
                if r == rs['vanilla'][key]:
                    txt += '   (this gate\'s own)' if not g.get('new') else '   (the source\'s)'
                cb.addItem(txt, r)
            cb.setCurrentIndex(rs[key])
            cb.setEnabled(ft is not None)
            cb.blockSignals(False)
        self.set_depth.blockSignals(True)
        self.set_depth.setValue(rs['depth'])
        self.set_depth.blockSignals(False)
        self.depth_note.setText(f"vanilla {rs['vanilla']['depth']}"
                                + ('' if rs['depth'] == rs['vanilla']['depth'] else ' (changed)'))
        self.maze_pics.setPixmap(self._maze_pixmap(ft, rs['maze_row']) if ft else QPixmap())

    @staticmethod
    def _maze_pixmap(ft, row):
        """The maze floor types of a row as the game draws them (census pictures) + odds."""
        from PySide6.QtGui import QPainter, QPixmap
        odds = ft['tables']['maze'][row]['odds']
        w, h = 58, 50
        pm = QPixmap(max(1, len(odds)) * (w + 6), h)
        pm.fill(QColor(40, 40, 40))
        p = QPainter(pm)
        for k, (t, pc) in enumerate(odds):
            img = QPixmap(os.path.join(ft['_root'], ft['maze_types'][t]['png']))
            if not img.isNull():
                p.drawPixmap(k * (w + 6), 0, img.scaled(w, h))
            p.fillRect(k * (w + 6), h - 13, w, 13, QColor(0, 0, 0, 170))
            p.setPen(QColor(235, 235, 235))
            f = p.font()
            f.setPointSize(8)
            p.setFont(f)
            p.drawText(k * (w + 6) + 2, h - 13, w - 2, 13, Qt.AlignLeft | Qt.AlignVCenter,
                       f'{t}: {pc}%')
        p.end()
        return pm

    def _set_row(self, key):
        g = self.gate()
        if g is None:
            return
        rs = G.row_settings(self.s.doc.custom, g['id'], getattr(self.s.doc, 'project_dir', None))
        v = self.set_depth.value() if key == 'depth' else self.row_combos[key].currentData()
        if v == rs[key]:
            return
        self._setting(key, None if v == rs['vanilla'][key] else v,
                      {'maze_row': 'Maze look', 'special_row': 'Special rooms',
                       'contents_row': 'Floor contents', 'depth': 'Item tier'}[key] + f' {v}')

    def _rows_vanilla(self):
        g = self.gate()
        if g is None:
            return
        gid = g['id']
        cmd = C.SnapshotCommand(self.s, f"Vanilla maze floors ({g['name']})",
                                lambda doc: doc.set_gate_setting(
                                    gid, **{k: None for k in G.ROW_KEYS}))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Vanilla maze floors', str(cmd.error))
        self.refresh()

    def _setting(self, key, value, label):
        g = self.gate()
        if g is None:
            return
        gid = g['id']
        cmd = C.SnapshotCommand(self.s, f"{label} ({g['name']})",
                                lambda doc: doc.set_gate_setting(gid, **{key: value}))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
        self.refresh()

    def _set_floors(self):
        g = self.gate()
        if g is None or self.set_floors.value() == g['floors']:
            return
        n = self.set_floors.value()
        src = g['copy_of'] if g.get('new') else g['id']
        van = next(x for x in self.gates if x['id'] == src)['floors']
        self._setting('floors', None if n == van else n, f'{n} floors')

    def _set_boss(self, _i):
        v = self.set_boss.currentData()
        self._setting('boss', v, 'Boss floor ' + (str(v) if v else 'vanilla'))

    def _open_boss(self):
        g = self.gate()
        if g is None:
            return
        b = self.s.doc.gate_setting(g['id']).get('boss')
        if b and not str(b).startswith('vanilla:'):
            self.openRoomRequested.emit(b)

    def _enemies(self):
        from editor2.app.enemies_dialog import EnemiesDialog
        dlg = EnemiesDialog(self.s.doc, parent=self)
        if dlg.exec() != QDialog.Accepted:
            return
        new = dlg.enemies()
        if new == self.s.doc.project_enemies():
            return
        cmd = C.SnapshotCommand(self.s, 'Project enemies',
                                lambda doc: doc.set_project_enemies(new))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Project enemies', str(cmd.error))

    # ------------------------------------------------------- new gates (S115)
    def _select_gate(self, gid):
        for i, x in enumerate(self.gates):
            if x['id'] == gid:
                self.list.setCurrentRow(i)
                return

    def _new_gate(self):
        g = self.gate()
        start = (g['copy_of'] if g and g.get('new') else g['id']) if g else 0
        dlg = NewGateDialog(self.s.doc, self, start=start)
        if dlg.exec() != QDialog.Accepted:
            return
        src, name, floors = dlg.values()
        got = {}
        cmd = C.SnapshotCommand(self.s, f'New gate {name}', lambda doc: got.update(
            id=doc.new_gate(src, name, floors)))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'New gate', str(cmd.error))
            return
        self.refresh()
        if 'id' in got:
            self._select_gate(got['id'])

    def _rename_gate(self):
        g = self.gate()
        if g is None or not g.get('new'):
            return
        name, okd = QInputDialog.getText(self, 'Rename gate', 'name', text=g['name'])
        if not okd or not name.strip() or name.strip() == g['name']:
            return
        self._setting('name', name.strip(), f'Rename gate {g["id"]}')
        self._select_gate(g['id'])

    def _delete_gate(self):
        g = self.gate()
        if g is None or not g.get('new'):
            return
        n_rules = len(self.s.doc.gate_rules_for(g['id']))
        n_ent = len(self.s.doc.gate_entrances(g['id']))
        if QMessageBox.question(
                self, 'Delete gate',
                f"Delete {g['name']} (gate {g['id']})? Its {n_rules} custom-room rule(s) and "
                f"{n_ent} entrance(s) go too; its encounter plan goes with it. "
                "(Undo brings everything back.)") != QMessageBox.Yes:
            return
        gid = g['id']
        cmd = C.SnapshotCommand(self.s, f"Delete gate {g['name']}",
                                lambda doc: doc.delete_gate(gid))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Delete gate', str(cmd.error))
        self.refresh()

    # ------------------------------------------------------------ edits
    def _sel_index(self):
        r = self.rules.currentRow()
        it = self.rules.item(r, 0) if r >= 0 else None
        return it.data(Qt.UserRole) if it else None

    def _push(self, label, rules, new_flags=()):
        def op(doc):
            for nm in new_flags:
                if not any(f.get('name') == doc._slug(nm) for f in doc.flags()):
                    doc.add_flag(nm)
            doc.set_gate_inserts(rules)
        cmd = C.SnapshotCommand(self.s, label, op)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))

    def _add(self):
        g = self.gate()
        if g is None:
            return
        if g['floors'] - g['min_floor'] < 1:
            QMessageBox.information(self, 'Add custom room', 'This gate has no floor between '
                                    'the first floor and the boss.')
            return
        dlg = GateRuleDialog(self.s.doc, g, parent=self)
        if dlg.exec() == QDialog.Accepted:
            rules = [dict(r) for r in self.s.doc.gate_inserts()] + [dlg.rule()]
            self._push(f"Custom room in {g['name']}", rules, dlg.new_flags)

    def _edit(self):
        g, idx = self.gate(), self._sel_index()
        if g is None or idx is None:
            return
        rules = [dict(r) for r in self.s.doc.gate_inserts()]
        dlg = GateRuleDialog(self.s.doc, g, rules[idx], parent=self)
        if dlg.exec() == QDialog.Accepted:
            rules[idx] = dlg.rule()
            self._push(f"Edit custom room rule ({g['name']})", rules, dlg.new_flags)

    def _remove(self):
        g, idx = self.gate(), self._sel_index()
        if g is None or idx is None:
            return
        rules = [dict(r) for r in self.s.doc.gate_inserts()]
        rules.pop(idx)
        self._push(f"Remove custom room rule ({g['name']})", rules)

    def _move(self, d):
        g, idx = self.gate(), self._sel_index()
        if g is None or idx is None:
            return
        mine = [i for i, _r in self.s.doc.gate_rules_for(g['id'])]
        pos = mine.index(idx)
        if not 0 <= pos + d < len(mine):
            return
        j = mine[pos + d]
        rules = [dict(r) for r in self.s.doc.gate_inserts()]
        rules[idx], rules[j] = rules[j], rules[idx]
        self._push(f"Reorder custom rooms ({g['name']})", rules)
        self.rules.selectRow(pos + d)

    def _open_room(self):
        idx = self._sel_index()
        if idx is None:
            return
        rid = self.s.doc.gate_inserts()[idx].get('room')
        if rid:
            self.openRoomRequested.emit(rid)
