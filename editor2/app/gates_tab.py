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
special room — never in the Gate of Beginning). The first floor always stays
the gate's own. Gate settings (floor count, weighting, monster pools), the
boss floor and gate entrances are ROADMAP P3.7b part 2.

Every edit is one undo step (SnapshotCommand).
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QColor
from PySide6.QtWidgets import (QAbstractItemView, QCheckBox, QComboBox, QDialog,
                               QDialogButtonBox, QFormLayout, QGroupBox, QHBoxLayout,
                               QHeaderView, QInputDialog, QLabel, QListWidget,
                               QListWidgetItem, QMessageBox, QPushButton, QSpinBox,
                               QSplitter, QTableWidget, QTableWidgetItem, QToolButton,
                               QVBoxLayout, QWidget)

from editor2.app.rooms import commands as C
from editor2.app.rooms.rules_panel import WELL_KNOWN
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
        last = max(G.MIN_FLOOR, self.floors - 1)
        for sb in (self.f_from, self.f_to):
            sb.setRange(G.MIN_FLOOR, last)
        fr.addWidget(self.any)
        fr.addWidget(QLabel('  floors'))
        fr.addWidget(self.f_from)
        fr.addWidget(QLabel('to'))
        fr.addWidget(self.f_to)
        fr.addStretch(1)
        f.addRow('where', fr)
        f.addRow('', QLabel(f"{gate['name']} has {self.floors} floors: floor 1 stays the "
                            f"gate's own, floor {self.floors} is the boss."))
        spec = rule.get('floors', 'all')
        if spec in (None, 'all', 'any'):
            self.any.setChecked(True)
            self.f_from.setValue(G.MIN_FLOOR)
            self.f_to.setValue(last)
        else:
            a, b = G.floor_range(spec, self.floors)
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
        for idx, name in WELL_KNOWN:
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

    def rule(self):
        r = {'room': self.room.currentData(), 'gate': self.gate['id']}
        if self.any.isChecked():
            r['floors'] = 'all'
        else:
            a, b = self.f_from.value(), self.f_to.value()
            r['floors'] = [a] if a == b else [a, b]
        r['chance'] = self.chance.value()
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
        if self.table.rowCount() > G.MAX_TERMS:
            self.warn.setText(f'At most {G.MAX_TERMS} conditions.')
            return
        self.accept()


class GatesTab(QWidget):
    openRoomRequested = Signal(str)          # custom room id

    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.gates = G.vanilla_gates(self.s.project_dir)
        split = QSplitter(Qt.Horizontal, self)
        lay = QVBoxLayout(self)
        lay.setContentsMargins(0, 0, 0, 0)
        lay.addWidget(split)
        self.list = QListWidget()
        self.list.setMinimumWidth(240)
        self.list.currentRowChanged.connect(self._show_gate)
        split.addWidget(self.list)
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
        nl = QLabel('Coming in part 2 (ROADMAP P3.7b): floor count, floor weighting and '
                    'monster pools per gate, a custom boss floor, gate entrances.')
        nl.setWordWrap(True)
        nl.setStyleSheet('color:#777;')
        rv.addWidget(nl)
        split.addWidget(right)
        split.setStretchFactor(1, 1)
        self.s.structureChanged.connect(self.refresh)
        self.refresh()
        self.list.setCurrentRow(1 if len(self.gates) > 1 else 0)

    # ------------------------------------------------------------ views
    def refresh(self):
        cur = max(self.list.currentRow(), 0)
        self.list.blockSignals(True)
        self.list.clear()
        for g in self.gates:
            n = len(self.s.doc.gate_rules_for(g['id']))
            it = QListWidgetItem(f"{g['id']:2d}  {g['name']} — {g['floors']} fl"
                                 + (f"   ★{n}" if n else ''))
            it.setToolTip(f"boss room {g['boss_map']} {g['boss_room']} · depth tier "
                          f"{g['depth_tier']} · FAQ: {g['faq_name']}")
            if n:
                it.setForeground(QColor(0, 200, 255))
            self.list.addItem(it)
        self.list.setCurrentRow(min(cur, self.list.count() - 1))
        self.list.blockSignals(False)
        self._show_gate(self.list.currentRow())

    def gate(self):
        i = self.list.currentRow()
        return self.gates[i] if 0 <= i < len(self.gates) else None

    def _show_gate(self, i):
        if not 0 <= i < len(self.gates):
            return
        g = self.gates[i]
        doc = self.s.doc
        self.head.setText(f"<b>{g['name']}</b>  (gate {g['id']})")
        self.sub.setText(f"{g['floors']} floors — boss on floor {g['floors']} ({g['boss_map']} "
                         f"{g['boss_room']}) · depth tier {g['depth_tier']} · floor-type rows "
                         f"{g['floor_types'][0]}/{g['floor_types'][1]}/{g['floor_types'][2]}"
                         + (' · no special rooms in this gate' if g['id'] == 0 else ''))
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
            if r.get('once_per_dive'):
                also.append('once per dive')
            for t in r.get('when') or []:
                also.append(f"{t.get('flag')} {'clear' if t.get('is') == 'clear' else 'set'}")
            cells = [str(row + 1), rname, G.floors_text(r.get('floors', 'all'), g['floors']),
                     f"{int(G._val(r.get('chance', 100)))} %", ', '.join(also) or '—',
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
        if g['floors'] < 3:
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
