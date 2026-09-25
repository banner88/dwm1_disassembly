"""rules_panel.py — room state rules (S97, ROADMAP P3.5a).

A room's `state_rules` are checked top-down every time a screen of the room
loads (entry, scroll, return from battle/menu — bank $60 entry 8
CustomStateRules): the FIRST rule whose flag conditions all hold picks the
state; if none holds, the state is whatever scripts left in the counter
(state 0 after a reload). Because flags are saved and custom step counters
are not, rules are how a custom room REMEMBERS its version across a save.
A rule applies only to screens that have that state. "Otherwise" (a
trailing unconditional rule) forces a state when nothing else matched —
e.g. back to state 0 when a script clears the flag.
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox,
                               QFormLayout, QGroupBox, QHBoxLayout, QInputDialog,
                               QLabel, QListWidget, QListWidgetItem, QMessageBox,
                               QPushButton, QTableWidget, QVBoxLayout, QWidget)

WELL_KNOWN = [   # vanilla story flags worth offering by name (EVENT_FLAGS.md)
    ('0x0030', 'arena class G cleared'), ('0x0031', 'arena class F cleared'),
    ('0x0032', 'arena class E cleared'), ('0x0033', 'arena class D cleared'),
    ('0x0034', 'arena class C cleared'), ('0x0035', 'arena class B cleared'),
    ('0x0036', 'arena class A cleared'), ('0x0037', 'arena class S cleared'),
    ('0x001D', 'BattleRex (Gate of Anger) beaten'),
    ('0x0025', 'Durran (Gate of Reflection) beaten'),
    ('0x00F1', 'Starry Night won (post-game)'),
]


class RuleDialog(QDialog):
    """Edit one rule: state, AND-ed flag terms, screens."""

    def __init__(self, doc, room, rule=None, parent=None, default_state=0):
        super().__init__(parent)
        self.doc, self.room = doc, room
        self.setWindowTitle('State rule')
        self.resize(560, 420)
        rule = rule or {'state': default_state, 'when': []}
        v = QVBoxLayout(self)
        v.addWidget(QLabel('The room shows this STATE when ALL conditions hold. Rules are '
                           'checked top-down each time a screen loads; the first match wins.'))
        f = QFormLayout()
        self.state = QComboBox()
        for n, label in self._state_labels():
            self.state.addItem(label, n)
        self.state.setCurrentIndex(max(0, self.state.findData(int(rule.get('state', 0)))))
        f.addRow('state', self.state)
        v.addLayout(f)
        v.addWidget(QLabel('Conditions (all must hold — none = always):'))
        self.table = QTableWidget(0, 2)
        self.table.setHorizontalHeaderLabels(['flag', 'must be'])
        self.table.horizontalHeader().setStretchLastSection(True)
        self.table.setColumnWidth(0, 330)
        v.addWidget(self.table, 1)
        trow = QHBoxLayout()
        b = QPushButton('+ condition')
        b.clicked.connect(lambda: self._add_term({}))
        trow.addWidget(b)
        b = QPushButton('− condition')
        b.clicked.connect(self._del_term)
        trow.addWidget(b)
        b = QPushButton('New named flag…')
        b.setToolTip('A project flag, auto-allocated from the safe pool (saved with the game). '
                     'Scripts set it with set_flag.')
        b.clicked.connect(self._new_flag)
        trow.addWidget(b)
        trow.addStretch(1)
        used, cap = doc.flag_pool()
        self.pool = QLabel(f'named flags {used}/{cap}')
        trow.addWidget(self.pool)
        v.addLayout(trow)
        for t in rule.get('when') or []:
            self._add_term(t)
        self.all_screens = QCheckBox('all screens of the room that have this state')
        v.addWidget(self.all_screens)
        self.scr_box = QWidget()
        sl = QHBoxLayout(self.scr_box)
        sl.setContentsMargins(0, 0, 0, 0)
        self.scr_checks = {}
        chosen = rule.get('screens')
        for k in doc.screen_keys(room):
            cb = QCheckBox(f'screen {k}')
            cb.setChecked(chosen is None or int(k) in [int(x) for x in chosen])
            self.scr_checks[k] = cb
            sl.addWidget(cb)
        sl.addStretch(1)
        v.addWidget(self.scr_box)
        self.all_screens.toggled.connect(lambda on: self.scr_box.setEnabled(not on))
        self.all_screens.setChecked(chosen is None)
        self.scr_box.setEnabled(chosen is not None)
        self.warn = QLabel('')
        self.warn.setStyleSheet('color: #e0b040;')
        self.warn.setWordWrap(True)
        v.addWidget(self.warn)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def _state_labels(self):
        """States by index across the room's screens (a rule's state is an
        index; screens without it are unaffected)."""
        n = max((len(self.doc.states(self.room, k)) for k in self.doc.screen_keys(self.room)),
                default=1)
        out = []
        for i in range(n):
            names = []
            for k in self.doc.screen_keys(self.room):
                sts = self.doc.states(self.room, k)
                if i < len(sts) and sts[i].get('comment'):
                    names.append(sts[i]['comment'])
            out.append((i, f'{i}: ' + (names[0][:50] if names else f'state {i}')))
        return out

    def _flag_combo(self, value=None):
        c = QComboBox()
        c.setEditable(True)
        for fl in self.doc.flags():
            c.addItem(f"{fl['name']}  (project flag)", fl['name'])
        for nm in getattr(self, 'new_flags', []):        # created in this dialog
            c.addItem(f'{nm}  (new project flag)', nm)
        for idx, name in WELL_KNOWN:
            c.addItem(f'{idx}  {name}', idx)
        c.setToolTip('A project flag name, or any event flag number (e.g. 0x0030). '
                     'EVENT_FLAGS.md lists the vanilla story flags.')
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
        """Create a named flag and put it in a condition row: the selected
        row, else a new row. S97 r2 fix: the
        name is a real item of every flag list (it used to be edit text only
        on the new row, so the row showed the new name while its list still
        pointed at the first entry)."""
        name, ok = QInputDialog.getText(self, 'New flag', 'Flag name (letters, digits, _):')
        if not ok or not name.strip():
            return
        nm = self.doc._slug(name.strip())
        if not nm:
            QMessageBox.warning(self, 'New flag', 'Use letters, digits and _.')
            return
        known = {fl['name'] for fl in self.doc.flags()} | set(getattr(self, 'new_flags', []))
        if nm not in known:
            self.new_flags = getattr(self, 'new_flags', []) + [nm]
            for r in range(self.table.rowCount()):
                self.table.cellWidget(r, 0).addItem(f'{nm}  (new project flag)', nm)
        r = self.table.currentRow()
        if r < 0:
            self._add_term({'flag': nm})
            r = self.table.rowCount() - 1
        c = self.table.cellWidget(r, 0)
        c.setCurrentIndex(c.findData(nm))
        self.table.setCurrentCell(r, 0)

    def _term_value(self, combo):
        d = combo.currentData()
        txt = combo.currentText().strip()
        if d is not None and combo.itemText(combo.currentIndex()) == txt:
            return d
        return txt.split()[0] if txt else None

    def rule(self):
        terms = []
        for r in range(self.table.rowCount()):
            fl = self._term_value(self.table.cellWidget(r, 0))
            if not fl:
                continue
            t = {'flag': fl}
            if self.table.cellWidget(r, 1).currentData() == 'clear':
                t['is'] = 'clear'
            terms.append(t)
        ru = {'state': int(self.state.currentData()), 'when': terms}
        if not self.all_screens.isChecked():
            ru['screens'] = [k for k, cb in self.scr_checks.items() if cb.isChecked()]
        return ru

    def _ok(self):
        ru = self.rule()
        if 'screens' in ru and not ru['screens']:
            self.warn.setText('Pick at least one screen.')
            return
        self.accept()


def split_otherwise(rules):
    """(explicit rules, otherwise-state|None): a trailing unconditional,
    all-screens rule is the 'otherwise' fallback the group shows apart."""
    rules = list(rules or [])
    if rules and not rules[-1].get('when') and rules[-1].get('screens') is None:
        return rules[:-1], int(rules[-1].get('state', 0))
    return rules, None


class RulesGroup(QGroupBox):
    """Inspector group: the room's ordered rule list + 'otherwise'."""
    rulesEdited = Signal(list, list)       # new rules, new flag names to create
    HELP = ('Flag rules pick the room\'s state when a screen loads — and, because flags are '
            'saved, they are how a custom room remembers its version after a reload.')

    def __init__(self, parent=None):
        super().__init__('State rules — which state shows when', parent)
        self.doc = self.room = None
        self._state_view = (0, 0)
        v = QVBoxLayout(self)
        lab = QLabel(self.HELP)
        lab.setWordWrap(True)
        lab.setStyleSheet('color: #aaa;')
        v.addWidget(lab)
        self.list = QListWidget()
        self.list.setMaximumHeight(110)
        self.list.itemDoubleClicked.connect(lambda _i: self._edit())
        v.addWidget(self.list)
        row = QHBoxLayout()
        from PySide6.QtWidgets import QToolButton
        for text, fn, tip in (('Add…', self._add, 'New rule (defaults to the state on screen)'),
                              ('Edit…', self._edit, 'Edit the selected rule'),
                              ('Remove', self._remove, 'Remove the selected rule'),
                              ('▲', lambda: self._move(-1), 'Check earlier (higher priority)'),
                              ('▼', lambda: self._move(1), 'Check later')):
            b = QToolButton()
            b.setText(text)
            b.setToolTip(tip)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)
        orow = QHBoxLayout()
        orow.addWidget(QLabel('Otherwise:'))
        self.otherwise = QComboBox()
        self.otherwise.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.otherwise.setMinimumContentsLength(10)
        self.otherwise.setToolTip(
            'When no rule matches. "Keep" leaves the state to scripts (write_ram on the '
            'step counter) — it falls back to state 0 after a reload. A state here is '
            'forced on every load, overriding scripts.')
        self.otherwise.currentIndexChanged.connect(self._otherwise_changed)
        orow.addWidget(self.otherwise, 1)
        v.addLayout(orow)
        self._building = False

    def show_room(self, doc, room, key, state_idx):
        self.doc, self.room = doc, room
        self._state_view = (key, state_idx)
        self.list.clear()
        explicit, other = split_otherwise(doc.state_rules(room))
        self._building = True
        self.otherwise.clear()
        self.otherwise.addItem('keep what scripts set (state 0 after a reload)', None)
        n = max((len(doc.states(room, k)) for k in doc.screen_keys(room)), default=1)
        for i in range(n):
            self.otherwise.addItem(f'state {i}', i)
        self.otherwise.setCurrentIndex(max(0, self.otherwise.findData(other))
                                       if other is not None else 0)
        self._building = False
        for i, ru in enumerate(explicit):
            scr = ru.get('screens')
            txt = (f"{i + 1}. state {ru.get('state')}  ←  {doc.describe_rule(ru)}"
                   + (f"   [screens {', '.join(str(s) for s in scr)}]" if scr is not None else ''))
            it = QListWidgetItem(txt)
            if any(j == i for j, _r in doc.rules_for_state(room, key, state_idx)):
                it.setForeground(Qt.green)
                it.setToolTip('selects the state you are viewing')
            self.list.addItem(it)
        if not explicit:
            it = QListWidgetItem('(no rules — the state is whatever scripts set; '
                                 'state 0 after a reload)')
            it.setFlags(Qt.NoItemFlags)
            self.list.addItem(it)

    def _rules(self):
        """The explicit (listed) rules; _emit re-appends the otherwise rule."""
        return [dict(r) for r in split_otherwise(self.doc.state_rules(self.room))[0]]

    def _other(self):
        return split_otherwise(self.doc.state_rules(self.room))[1]

    def _emit(self, explicit, new_flags=(), other='same'):
        other = self._other() if other == 'same' else other
        full = list(explicit) + ([{'state': other, 'when': []}] if other is not None else [])
        self.rulesEdited.emit(full, list(new_flags))

    def _otherwise_changed(self, _i):
        if self._building or self.room is None:
            return
        self._emit(self._rules(), other=self.otherwise.currentData())

    def _add(self):
        if self.room is None:
            return
        dlg = RuleDialog(self.doc, self.room, parent=self, default_state=self._state_view[1])
        if dlg.exec() == QDialog.Accepted:
            self._emit(self._rules() + [dlg.rule()], getattr(dlg, 'new_flags', []))

    def _edit(self):
        i = self.list.currentRow()
        rules = self._rules() if self.room is not None else []
        if not 0 <= i < len(rules):
            return
        dlg = RuleDialog(self.doc, self.room, rules[i], parent=self)
        if dlg.exec() == QDialog.Accepted:
            rules[i] = dlg.rule()
            self._emit(rules, getattr(dlg, 'new_flags', []))

    def _remove(self):
        i = self.list.currentRow()
        rules = self._rules() if self.room is not None else []
        if 0 <= i < len(rules):
            rules.pop(i)
            self._emit(rules)

    def _move(self, d):
        i = self.list.currentRow()
        rules = self._rules() if self.room is not None else []
        j = i + d
        if 0 <= i < len(rules) and 0 <= j < len(rules):
            rules[i], rules[j] = rules[j], rules[i]
            self._emit(rules)
            self.list.setCurrentRow(j)
