"""encounters_tab.py — the Encounters tab (S114, ROADMAP P3.13a; EDITOR_DESIGN
§5.5 "As built S114"; model: editor2/core/encounters_doc.py, compiler:
editor2/core/encounters.py, PROJECT_COMPILER §2.30).

Three pages:

  Lists   every wild-monster list: the game's 128 (numbers 0-127) and your
          own (128+), where each is used (gate floors, rooms, flag variants),
          the monsters' levels. Right: the list itself — five slots (an enemy
          row, its chance, the most copies in one battle), how many monsters a
          battle has, the rate, the maze size — with the REAL chances (the
          game picks the first slot whose running total reaches the draw, so
          the first slot gets one point more and the last one point less) and
          the battles it gives most often. New list = a copy of the selected.
  Gates   every gate: the list each floor uses — the game's rule, or your own
          per floor — and flag variants ("when these flags hold, the floors
          use …"). The boss floor (the last) has no maze and no list.
  Rooms   every custom room: no battles / a gate floor's list / the dive's
          list (a room served inside a gate) / its own list (+ flag
          variants), and its own battle rate.

The list a battle uses is chosen by bank $76 EncResolve (PyBoy-measured ==
this model: tools/census_encounters.py). Every edit is one undo step
(SnapshotCommand) validated by the compiler's own model.
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QColor, QIcon
from PySide6.QtWidgets import (QAbstractItemView, QButtonGroup, QCheckBox, QComboBox,
                               QDialog, QDialogButtonBox, QFormLayout, QGroupBox,
                               QHBoxLayout, QHeaderView, QInputDialog, QLabel, QLineEdit,
                               QListWidget, QListWidgetItem, QMessageBox, QPushButton,
                               QRadioButton, QScrollArea, QSpinBox, QSplitter,
                               QStackedWidget, QTabWidget, QTableWidget, QTableWidgetItem,
                               QVBoxLayout, QWidget)

from editor2.app.rooms import commands as C
from editor2.app.rooms.rules_panel import WELL_KNOWN
from editor2.core import encounters as EN
from editor2.core import encounters_doc as ED

HELP = ('A battle draws its monsters from a LIST: five slots, each an enemy row with a '
        'chance; the list also says how many monsters come at once and how often battles '
        'happen. The game has 128 lists (several gates share some); add your own and give '
        'them to gate floors or rooms. Flag variants switch a gate or a room to other '
        'lists once a flag is set (or clear).')
GREY = QColor(140, 140, 140)
RATE_NAMES = ['very rare', 'rare', 'less often', 'normal', 'often', 'very often',
              'constant', 'relentless']


def _bold(item, on=True):
    f = item.font()
    f.setBold(on)
    item.setFont(f)


# ---------------------------------------------------------------------------
# flag conditions (same shape as the gate-insert rule dialog)
# ---------------------------------------------------------------------------

class FlagTerms(QWidget):
    """A table of flag conditions [{"flag": name | number, "is": set|clear}]."""

    def __init__(self, doc, terms=(), parent=None):
        super().__init__(parent)
        self.doc = doc
        self.new_flags = []
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        self.table = QTableWidget(0, 2)
        self.table.setHorizontalHeaderLabels(['flag', 'must be'])
        self.table.horizontalHeader().setStretchLastSection(True)
        self.table.setColumnWidth(0, 320)
        v.addWidget(self.table, 1)
        row = QHBoxLayout()
        for txt, fn in (('+ condition', lambda: self._add({})), ('− condition', self._del),
                        ('New named flag…', self._new_flag)):
            b = QPushButton(txt)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)
        for t in terms or []:
            self._add(t)

    def _combo(self, value=None):
        c = QComboBox()
        c.setEditable(True)
        for fl in self.doc.flags():
            c.addItem(f"{fl['name']}  (project flag)", fl['name'])
        for nm in self.new_flags:
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

    def _add(self, t):
        r = self.table.rowCount()
        self.table.insertRow(r)
        self.table.setCellWidget(r, 0, self._combo(t.get('flag')))
        s = QComboBox()
        s.addItem('set', 'set')
        s.addItem('clear', 'clear')
        s.setCurrentIndex(1 if t.get('is') == 'clear' else 0)
        self.table.setCellWidget(r, 1, s)

    def _del(self):
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
        if nm and nm not in {fl['name'] for fl in self.doc.flags()} | set(self.new_flags):
            self.new_flags.append(nm)
            for r in range(self.table.rowCount()):
                self.table.cellWidget(r, 0).addItem(f'{nm}  (new project flag)', nm)
        r = self.table.currentRow()
        if r < 0:
            self._add({'flag': nm})
            r = self.table.rowCount() - 1
        c = self.table.cellWidget(r, 0)
        c.setCurrentIndex(c.findData(nm))

    def terms(self):
        out = []
        for i in range(self.table.rowCount()):
            c = self.table.cellWidget(i, 0)
            d, txt = c.currentData(), c.currentText().strip()
            fl = d if d is not None and c.itemText(c.currentIndex()) == txt else (
                txt.split()[0] if txt else None)
            if not fl:
                continue
            t = {'flag': fl}
            if self.table.cellWidget(i, 1).currentData() == 'clear':
                t['is'] = 'clear'
            out.append(t)
        return out


class VariantDialog(QDialog):
    """A flag variant: its conditions (+ for a room, the list it switches to)."""

    def __init__(self, doc, title, terms=(), lists=None, list_ref=None, parent=None):
        super().__init__(parent)
        self.setWindowTitle(title)
        self.resize(640, 380)
        v = QVBoxLayout(self)
        v.addWidget(QLabel('When ALL these hold (checked in order — the first variant whose '
                           'conditions hold wins):'))
        self.terms_w = FlagTerms(doc, terms)
        v.addWidget(self.terms_w, 1)
        self.list_combo = None
        if lists is not None:
            h = QHBoxLayout()
            h.addWidget(QLabel('… use list'))
            self.list_combo = ListCombo(lists, list_ref)
            h.addWidget(self.list_combo, 1)
            v.addLayout(h)
        self.warn = QLabel('')
        self.warn.setStyleSheet('color:#e0b040;')
        v.addWidget(self.warn)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def _ok(self):
        t = self.terms_w.terms()
        if not t:
            self.warn.setText('A variant needs at least one flag condition.')
            return
        if len(t) > EN.MAX_TERMS:
            self.warn.setText(f'At most {EN.MAX_TERMS} conditions.')
            return
        self.accept()

    def result_terms(self):
        return self.terms_w.terms()

    def new_flags(self):
        return list(self.terms_w.new_flags)


class ListCombo(QComboBox):
    """Pick a list: '12 · Gate of Peace floors 1-3 · Picky, …'."""

    def __init__(self, lists, current=None, allow_none=None, parent=None):
        super().__init__(parent)
        if allow_none:
            self.addItem(allow_none, None)
        for row in lists:
            self.addItem(list_label(row), row['number'])
        if current is not None:
            i = self.findData(current)
            if i >= 0:
                self.setCurrentIndex(i)


def list_label(row):
    n = row['number']
    head = f"{n} · {row['name']}" if row['kind'] == 'project' else f"{n}"
    lv = row['levels']
    lv = f" · Lv {lv[0]}" + (f"-{lv[1]}" if lv[1] != lv[0] else '') if lv else ''
    who = ', '.join(row['who'][:3]) + ('…' if len(row['who']) > 3 else '')
    used = row['uses'][0]['label'] if row['uses'] else 'not used'
    more = f" (+{len(row['uses']) - 1})" if len(row['uses']) > 1 else ''
    return f"{head} · {used}{more}{lv} · {who}"


class EnemyPick(QDialog):
    """Choose an enemy row for a slot (your enemies first, then the game's)."""

    def __init__(self, choices, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Monster for this slot')
        self.resize(560, 520)
        v = QVBoxLayout(self)
        self.filter = QLineEdit()
        self.filter.setPlaceholderText('filter: name, level, EID …')
        self.filter.textChanged.connect(self._fill)
        v.addWidget(self.filter)
        self.list = QListWidget()
        self.list.itemDoubleClicked.connect(lambda _i: self.accept())
        v.addWidget(self.list, 1)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self.choices = choices
        self._fill('')

    def _fill(self, txt):
        self.list.clear()
        t = txt.lower().strip()
        for label, ref, _eid, _sp in self.choices:
            if t and t not in label.lower():
                continue
            it = QListWidgetItem(label)
            it.setData(Qt.UserRole, ref)
            self.list.addItem(it)
        if self.list.count():
            self.list.setCurrentRow(0)

    def ref(self):
        it = self.list.currentItem()
        return None if it is None else it.data(Qt.UserRole)


# ---------------------------------------------------------------------------
# the pages' right-hand editors
# ---------------------------------------------------------------------------

class ListEditor(QWidget):
    def __init__(self, tab):
        super().__init__()
        self.tab = tab
        self.n = None
        self._busy = False
        v = QVBoxLayout(self)
        self.title = QLabel()
        fo = self.title.font()
        fo.setPointSize(fo.pointSize() + 4)
        fo.setBold(True)
        self.title.setFont(fo)
        v.addWidget(self.title)
        top = QHBoxLayout()
        self.name_lbl = QLabel('Name:')
        top.addWidget(self.name_lbl)
        self.name = QLineEdit()
        self.name.editingFinished.connect(self._rename)
        top.addWidget(self.name, 1)
        v.addLayout(top)
        f = QFormLayout()
        self.rate = QComboBox()
        for code in range(8):
            self.rate.addItem(f'{code} — {RATE_NAMES[code]}', code)
        self.rate.setToolTip(ED.RATE_HELP)
        self.rate.currentIndexChanged.connect(lambda _i: self._field(
            'rate', self.rate.currentData()))
        self.steps = QLabel()
        rr = QHBoxLayout()
        rr.addWidget(self.rate)
        rr.addWidget(self.steps, 1)
        f.addRow('Battle rate', rr)
        self.size = []
        sz = QHBoxLayout()
        for k in range(3):
            c = QComboBox()
            c.currentIndexChanged.connect(lambda _i, k=k: self._size())
            self.size.append(c)
            sz.addWidget(QLabel(f'{k + 1}:'))
            sz.addWidget(c)
        self.size_real = QLabel()
        sz.addWidget(self.size_real, 1)
        f.addRow('Monsters per battle', sz)
        self.maze = QSpinBox()
        self.maze.setRange(0, 255)
        self.maze.setKeyboardTracking(False)
        self.maze.setToolTip('Gate floors only: how many pieces the maze is carved from '
                             '(the game uses 3, 8 or 15).')
        self.maze.valueChanged.connect(lambda val: self._field('maze_size', val))
        f.addRow('Maze size (gate floors)', self.maze)
        v.addLayout(f)
        self.table = QTableWidget(5, 5)
        self.table.setHorizontalHeaderLabels(['Monster (enemy row)', 'Chance', 'Real chance',
                                              'Most in one battle', ''])
        self.table.horizontalHeader().setSectionResizeMode(0, QHeaderView.Stretch)
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        v.addWidget(self.table)
        tb = QHBoxLayout()
        self.total = QLabel()
        tb.addWidget(self.total, 1)
        self.apply_btn = QPushButton('Apply')
        self.apply_btn.setToolTip('Write the slots and the monsters-per-battle chances (one '
                                  'undo step) — they must add up to 100 %')
        self.apply_btn.clicked.connect(self._apply)
        tb.addWidget(self.apply_btn)
        self.revert_btn = QPushButton('Revert')
        self.revert_btn.clicked.connect(self._revert)
        tb.addWidget(self.revert_btn)
        v.addLayout(tb)
        self.odds = QLabel()
        self.odds.setWordWrap(True)
        self.odds.setTextInteractionFlags(Qt.TextSelectableByMouse)
        v.addWidget(self.odds)
        self.uses = QLabel()
        self.uses.setWordWrap(True)
        self.uses.setTextInteractionFlags(Qt.TextSelectableByMouse)
        v.addWidget(self.uses)
        self.balance = QLabel('<span style="color:#888">Fight length for a party against this '
                              'list: the Balance tab (ROADMAP P3.15) — levels above for now.'
                              '</span>')
        self.balance.setWordWrap(True)
        v.addWidget(self.balance)
        v.addStretch(1)

    def show_list(self, n, M):
        doc = self.tab.s.doc
        self.n = n
        d = doc.enc_list_detail(n, M)
        self.d = d
        pct = M.pct
        self._busy = True
        own = d['kind'] == 'project'
        self.title.setText(f"List {n}" + (f" — {d['name']}" if own else " — the game's"))
        self.name_lbl.setVisible(own)
        self.name.setVisible(own)
        if own:
            self.name.setText(d['name'])
        self.rate.setCurrentIndex(d['rate'])
        self.steps.setText(f"≈ {d['steps']:.0f} steps between battles outside gates "
                           f"(rooms); on gate floors the floor type changes it")
        for k, c in enumerate(self.size):
            c.clear()
            for code, p in enumerate(pct):
                c.addItem(f'{p} %', code)
            c.setCurrentIndex(d['size'][k])
        self.maze.setValue(d['maze'])
        multi = any(pct[c] for c in d['size'][1:])
        for k, s in enumerate(d['slots']):
            it = QTableWidgetItem(s['name'] + (f"  Lv {s['level']}  (EID {s['eid']})"
                                               if not s['empty'] else ''))
            it.setFlags(it.flags() & ~Qt.ItemIsEditable)
            self.table.setItem(k, 0, it)
            c = QComboBox()
            for code, p in enumerate(pct):
                c.addItem(f'{p} %', code)
            c.setCurrentIndex(s['chance'])
            c.currentIndexChanged.connect(lambda _i, k=k, c=c: self._slot_chance(k, c.currentData()))
            self.table.setCellWidget(k, 1, c)
            m = QSpinBox()
            m.setRange(0, 3)
            m.setValue(s['max'])
            m.setEnabled(not s['empty'])
            m.setToolTip('1 = this monster only ever comes alone; 0 = never as the 2nd / '
                         '3rd monster; 2-3 = up to that many copies together')
            m.valueChanged.connect(lambda val, k=k: self._slot_max(k, val))
            self.table.setCellWidget(k, 3, m)
            b = QPushButton('Monster…')
            b.clicked.connect(lambda _c=False, k=k: self._slot_monster(k))
            self.table.setCellWidget(k, 4, b)
        self.odds.setText(('' if multi else 'Every battle has one monster. ')
                          + '<b>Battles it gives most often:</b> ' + '; '.join(
            f'{who} {p * 100:.0f} %' for who, p in d['odds']))
        uses = doc.enc_usage(M).get(n, [])
        self.uses.setText('<b>Used by:</b> ' + ('; '.join(u['label'] for u in uses)
                                               if uses else 'nothing'))
        self._stage_from(d)
        self._busy = False

    def _push_fields(self, label, fields):
        n = self.n
        self.tab.push(f'List {n}: {label}', lambda doc: doc.set_enc_list(n, fields))

    def _field(self, key, val):
        if self._busy or self.n is None:
            return
        self._push_fields(f'{key} → {val}', {key: val})

    # -- staged edits: the slots and the monsters-per-battle chances change
    # together (a half-edited list would not add up to 100 % and the compiler
    # refuses it), then "Apply" writes them as one undo step
    def _stage_from(self, d):
        self.stage = {'size': list(d['size']),
                      'slots': [dict(x) for x in d['slots']]}
        self._stage_view()

    def _stage_dirty(self):
        d = self.d
        st = self.stage
        return (st['size'] != list(d['size']) or
                [(x['chance'], x['ref'], x['max']) for x in st['slots']] !=
                [(x['chance'], x['ref'], x['max']) for x in d['slots']])

    def _stage_view(self):
        pct = self.tab.M.pct
        st = self.stage
        real = EN.real_chances([x['chance'] for x in st['slots']], pct)
        for k, x in enumerate(st['slots']):
            r = QTableWidgetItem(f"{real[k]} %" if x['chance'] else '—')
            r.setFlags(r.flags() & ~Qt.ItemIsEditable)
            self.table.setItem(k, 2, r)
        self.size_real.setText('real: ' + ' / '.join(
            f'{v} %' for v in EN.real_chances(st['size'], pct)))
        tot = sum(pct[x['chance']] for x in st['slots'])
        stot = sum(pct[c] for c in st['size'])
        ok = tot == 100 and stot >= 100
        dirty = self._stage_dirty()
        msg = (f'<b style="color:{"#070" if tot == 100 else "#b00"}">slot chances total '
               f'{tot} %</b>' + ('' if tot == 100 else ' — must be exactly 100 %'))
        if stot < 100:
            msg += f' · <b style="color:#b00">monsters per battle total {stot} %</b>'
        if dirty:
            msg += '  — <i>not applied yet</i>'
        self.total.setText(msg)
        self.apply_btn.setEnabled(dirty and ok)
        self.revert_btn.setEnabled(dirty)

    def _size(self):
        if self._busy or self.n is None:
            return
        self.stage['size'] = [c.currentData() for c in self.size]
        self._stage_view()

    def _slot_chance(self, k, code):
        if self._busy:
            return
        self.stage['slots'][k]['chance'] = code
        self._stage_view()

    def _slot_max(self, k, val):
        if self._busy:
            return
        self.stage['slots'][k]['max'] = val
        self._stage_view()

    def _slot_monster(self, k):
        doc = self.tab.s.doc
        dlg = EnemyPick([('(empty slot)', 0, 0, None)] + doc.enemy_choices(self.tab.M), self)
        if not dlg.exec():
            return
        ref = dlg.ref()
        x = self.stage['slots'][k]
        label = next((lab for lab, r, _e, _s in doc.enemy_choices(self.tab.M) if r == ref),
                     '—')
        x['ref'] = ref
        x['empty'] = ref == 0
        if ref == 0:
            x['chance'], x['max'] = 0, 0
        elif x['max'] == 0:
            x['max'] = 1
        self._busy = True
        it = QTableWidgetItem(label if ref else '—')
        it.setFlags(it.flags() & ~Qt.ItemIsEditable)
        self.table.setItem(k, 0, it)
        self.table.cellWidget(k, 1).setCurrentIndex(x['chance'])
        self.table.cellWidget(k, 3).setValue(x['max'])
        self.table.cellWidget(k, 3).setEnabled(ref != 0)
        self._busy = False
        self._stage_view()

    def _apply(self):
        st = self.stage
        fields = {'size_chance': list(st['size']),
                  'slot_chance': [x['chance'] for x in st['slots']],
                  'eids': [x['ref'] if not x['empty'] else 0 for x in st['slots']],
                  'max_count': [x['max'] for x in st['slots']]}
        self._push_fields('monsters / chances', fields)

    def _revert(self):
        self.show_list(self.n, self.tab.M)

    def _rename(self):
        if self._busy or self.n is None or self.d['kind'] != 'project':
            return
        nm = self.name.text().strip()
        if nm and nm != self.d['name']:
            self._push_fields(f'name → {nm}', {'name': nm})


class GateEditor(QWidget):
    def __init__(self, tab):
        super().__init__()
        self.tab = tab
        self.gid = None
        self._busy = False
        v = QVBoxLayout(self)
        self.title = QLabel()
        fo = self.title.font()
        fo.setPointSize(fo.pointSize() + 4)
        fo.setBold(True)
        self.title.setFont(fo)
        v.addWidget(self.title)
        h = QHBoxLayout()
        h.addWidget(QLabel('Show:'))
        self.which = QComboBox()
        self.which.currentIndexChanged.connect(lambda _i: self._redraw())
        h.addWidget(self.which, 1)
        v.addLayout(h)
        self.note = QLabel()
        self.note.setWordWrap(True)
        v.addWidget(self.note)
        self.table = QTableWidget(0, 3)
        self.table.setHorizontalHeaderLabels(['Floor', 'List', 'From'])
        self.table.horizontalHeader().setSectionResizeMode(1, QHeaderView.Stretch)
        v.addWidget(self.table, 1)
        row = QHBoxLayout()
        for txt, fn in (('+ Flag variant…', self._add_variant),
                        ('Edit variant flags…', self._edit_variant),
                        ('Remove variant', self._remove_variant),
                        ("Back to the game's rule", self._reset)):
            b = QPushButton(txt)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)
        self.shared = QLabel()
        self.shared.setWordWrap(True)
        self.shared.setStyleSheet('color:#e0b040;')
        v.addWidget(self.shared)

    def show_gate(self, gid, M, prj, lists):
        self.gid = gid
        self.M, self.prj, self.lists = M, prj, lists
        doc = self.tab.s.doc
        from editor2.core import gates as GT
        g = next((x for x in GT.all_gates(prj.custom) if x['id'] == gid),
                 {'name': f'Gate {gid}'})                     # S115: + new gates
        n = GT.gate_floor_count(prj.custom, gid) or 0
        self.title.setText(f"{g['name']} — {n} floors (floor {n} is the boss floor)")
        self._busy = True
        cur = self.which.currentData()
        self.which.clear()
        self.which.addItem('the floors (no flag variant)', None)
        names = {v: k for k, v in prj.flag_map().items()}
        gv = M.gates.get(gid)
        for k, (terms, _p) in enumerate(gv['variants'] if gv else []):
            self.which.addItem(f'variant {k + 1}: {ED.when_text(terms, names)}', k)
        i = self.which.findData(cur)
        self.which.setCurrentIndex(i if i >= 0 else 0)
        self._busy = False
        self._redraw()

    def _redraw(self):
        if self._busy or self.gid is None:
            return
        doc = self.tab.s.doc
        var = self.which.currentData()
        rows = doc.gate_plan_view(self.gid, var, self.M, self.prj)
        self._busy = True
        self.table.setRowCount(len(rows))
        usage = doc.enc_usage(self.M, self.prj)
        shared = set()
        for i, r in enumerate(rows):
            it = QTableWidgetItem(str(r['floor']))
            it.setFlags(it.flags() & ~Qt.ItemIsEditable)
            self.table.setItem(i, 0, it)
            c = ListCombo(self.lists, r['list'])
            c.currentIndexChanged.connect(
                lambda _i, f=r['floor'], c=c: self._set_floor(f, c.currentData()))
            self.table.setCellWidget(i, 1, c)
            src = {'game': f"the game's rule (list {r['vanilla']})", 'plan': 'your plan',
                   'variant': 'this variant'}[r['source']]
            s = QTableWidgetItem(src)
            s.setFlags(s.flags() & ~Qt.ItemIsEditable)
            if r['source'] == 'game':
                s.setForeground(GREY)
            self.table.setItem(i, 2, s)
            for u in usage.get(r['list'], []):
                if u.get('gate') != self.gid:
                    shared.add((r['list'], u['label']))
        self.table.resizeColumnToContents(0)
        self._busy = False
        self.note.setText('Pick a list per floor. Floors on "the game\'s rule" follow the '
                          'original breakpoints; in a variant, floors you do not change keep '
                          'the gate\'s own plan.' if var is not None else
                          'Pick a list per floor. Floors left on "the game\'s rule" keep the '
                          'original breakpoints (and follow the floor count).')
        self.shared.setText(
            ('Shared: ' + '; '.join(f'list {n} is also {lab}' for n, lab in sorted(shared)[:8])
             + (' …' if len(shared) > 8 else '')
             + ' — editing those lists changes them there too; give this gate a copy '
               '(Lists → New list) to change only it.') if shared else '')

    def _set_floor(self, floor, num):
        if self._busy or num is None:
            return
        gid, var = self.gid, self.which.currentData()
        doc = self.tab.s.doc
        rows = {r['floor']: r for r in doc.gate_plan_view(gid, var, self.M, self.prj)}
        ref = doc.list_ref_value(num)
        if var is None and num == rows[floor]['vanilla']:
            ref = None                      # back to the game's rule
        self.tab.push(f'Gate {gid} floor {floor}: list {num}',
                      lambda d: d.set_gate_floor_list(gid, floor, ref, var))

    def _add_variant(self):
        doc = self.tab.s.doc
        dlg = VariantDialog(doc, 'New flag variant', parent=self)
        if not dlg.exec():
            return
        gid = self.gid
        vs = doc.gate_variants(gid) + [{'when': dlg.result_terms(), 'floors': []}]
        flags = dlg.new_flags()
        self.tab.push(f'Gate {gid}: + flag variant', lambda d: self.tab.with_flags(
            d, flags, lambda: d.set_gate_variants(gid, vs)))

    def _edit_variant(self):
        k = self.which.currentData()
        if k is None:
            QMessageBox.information(self, 'Variant', 'Pick a variant in "Show" first.')
            return
        doc = self.tab.s.doc
        vs = doc.gate_variants(self.gid)
        dlg = VariantDialog(doc, f'Variant {k + 1}', vs[k].get('when'), parent=self)
        if not dlg.exec():
            return
        vs[k]['when'] = dlg.result_terms()
        gid, flags = self.gid, dlg.new_flags()
        self.tab.push(f'Gate {gid}: variant {k + 1} flags', lambda d: self.tab.with_flags(
            d, flags, lambda: d.set_gate_variants(gid, vs)))

    def _remove_variant(self):
        k = self.which.currentData()
        if k is None:
            return
        vs = self.tab.s.doc.gate_variants(self.gid)
        vs.pop(k)
        gid = self.gid
        self.tab.push(f'Gate {gid}: − variant {k + 1}', lambda d: d.set_gate_variants(gid, vs))

    def _reset(self):
        gid = self.gid
        self.tab.push(f"Gate {gid}: the game's rule", lambda d: d.reset_gate_plan(gid))


class RoomEditor(QWidget):
    def __init__(self, tab):
        super().__init__()
        self.tab = tab
        self.rid = None
        self._busy = False
        v = QVBoxLayout(self)
        self.title = QLabel()
        fo = self.title.font()
        fo.setPointSize(fo.pointSize() + 4)
        fo.setBold(True)
        self.title.setFont(fo)
        v.addWidget(self.title)
        self.modes = QButtonGroup(self)
        box = QGroupBox('Battles in this room')
        bv = QVBoxLayout(box)
        self.mode_btn = {}
        for key, txt in (('off', 'No battles'),
                         ('gate', 'A gate floor\'s list (the room pins that gate + floor at '
                                  'every step — not for rooms served inside gates)'),
                         ('follow', 'The dive\'s own list (a room served on gate floors)'),
                         ('own', 'Its own list (+ flag variants) — works inside and outside '
                                 'gates')):
            b = QRadioButton(txt)
            self.modes.addButton(b)
            self.mode_btn[key] = b
            b.toggled.connect(lambda on, key=key: on and self._mode(key))
            bv.addWidget(b)
        gl = QHBoxLayout()
        gl.addWidget(QLabel('gate'))
        self.gate = QComboBox()
        from editor2.core import gates as GT
        for g in GT.vanilla_gates():
            self.gate.addItem(f"{g['id']} {g['name']}", g['id'])
        self.gate.currentIndexChanged.connect(lambda _i: self._gate_changed())
        gl.addWidget(self.gate, 1)
        gl.addWidget(QLabel('floor'))
        self.floor = QSpinBox()
        self.floor.setRange(1, 99)
        self.floor.setKeyboardTracking(False)
        self.floor.valueChanged.connect(lambda _v: self._gate_changed())
        gl.addWidget(self.floor)
        bv.addLayout(gl)
        ll = QHBoxLayout()
        ll.addWidget(QLabel('list'))
        self.list_holder = QHBoxLayout()
        ll.addLayout(self.list_holder, 1)
        bv.addLayout(ll)
        v.addWidget(box)
        rb = QHBoxLayout()
        self.rate_on = QCheckBox('Own battle rate')
        self.rate_on.toggled.connect(lambda _on: self._rate())
        rb.addWidget(self.rate_on)
        self.rate = QComboBox()
        for code in range(8):
            self.rate.addItem(f'{code} — {RATE_NAMES[code]}', code)
        self.rate.currentIndexChanged.connect(lambda _i: self._rate())
        rb.addWidget(self.rate)
        self.rate_steps = QLabel()
        rb.addWidget(self.rate_steps, 1)
        v.addLayout(rb)
        v.addWidget(QLabel('<b>Flag variants</b> (own list only; checked top-down, the first '
                           'whose flags hold wins):'))
        self.vtable = QTableWidget(0, 2)
        self.vtable.setHorizontalHeaderLabels(['When', 'List'])
        self.vtable.horizontalHeader().setSectionResizeMode(0, QHeaderView.Stretch)
        self.vtable.setSelectionBehavior(QAbstractItemView.SelectRows)
        v.addWidget(self.vtable, 1)
        row = QHBoxLayout()
        for txt, fn in (('+ Flag variant…', self._add_variant), ('Edit…', self._edit_variant),
                        ('Remove', self._remove_variant)):
            b = QPushButton(txt)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)
        self.note = QLabel()
        self.note.setWordWrap(True)
        v.addWidget(self.note)
        self.list_combo = None

    def show_room(self, rid, M, prj, lists):
        doc = self.tab.s.doc
        self.rid, self.M, self.prj, self.lists = rid, M, prj, lists
        b = doc.room_battles(rid)
        self.b = b
        self._busy = True
        r = doc.room(rid)
        self.title.setText(f"Room {rid} ({r.get('mapID')})")
        self.mode_btn[b['mode']].setChecked(True)
        i = self.gate.findData(int(b.get('gate_id') or 0))
        self.gate.setCurrentIndex(max(i, 0))
        self.floor.setValue(int(b.get('floor') or 0) + 1)
        if self.list_combo is not None:
            self.list_combo.setParent(None)
        cur = M.ref(b['list'], 'list') if b['list'] is not None else None
        self.list_combo = ListCombo(lists, cur)
        self.list_combo.currentIndexChanged.connect(lambda _i: self._list_changed())
        self.list_holder.addWidget(self.list_combo)
        self.rate_on.setChecked(b['rate'] is not None)
        self.rate.setCurrentIndex(b['rate'] if b['rate'] is not None else 3)
        self.rate.setEnabled(b['rate'] is not None)
        names = {v: k for k, v in prj.flag_map().items()}
        rm = M.rooms.get(int(str(r.get('mapID')), 0) if isinstance(r.get('mapID'), str)
                         else r.get('mapID'))
        self.vtable.setRowCount(len(b['variants']))
        for k, var in enumerate(b['variants']):
            terms = rm['variants'][k][0] if rm else []
            self.vtable.setItem(k, 0, QTableWidgetItem(ED.when_text(terms, names)))
            num = M.ref(var.get('list'), 'v')
            self.vtable.setItem(k, 1, QTableWidgetItem(str(num)))
        self._busy = False
        self._enable()

    def _enable(self):
        m = self.b['mode']
        self.gate.setEnabled(m == 'gate')
        self.floor.setEnabled(m == 'gate')
        self.list_combo.setEnabled(m == 'own')
        self.vtable.setEnabled(m == 'own')
        rate = self.b['rate'] if self.b['rate'] is not None else None
        if m == 'own':
            num = self.list_combo.currentData()
        elif m == 'gate':
            num = self.M.gate_list(self.gate.currentData(), self.floor.value())
        else:
            num = None
        code = rate if rate is not None else (self.M.list_bytes(num)[0] if num is not None
                                              else None)
        self.rate_steps.setText(
            f"≈ {EN.steps_between(EN._repo(self.prj), code):.0f} steps between battles"
            if code is not None else '')
        self.note.setText({
            'off': 'No battles here.',
            'gate': f"Uses list {num} — what that gate floor uses (with its plan and "
                    "variants). The room sets the gate number while you walk here.",
            'follow': 'Inside a dive: the floor\'s own list. Outside a dive this mode has '
                      'no list of its own — use it only for rooms served on gate floors.',
            'own': f'Its own list {num}; flag variants switch it.'}[m])

    def _apply(self, label, **kw):
        rid = self.rid
        b = dict(self.b)
        b.update(kw)
        mode = b['mode']
        args = dict(mode=mode, rate=b['rate'])
        if mode == 'gate':
            args.update(gate_id=b['gate_id'], floor=b['floor'])
        if mode == 'own':
            args.update(list_ref=b['list'], variants=b['variants'])
        self.tab.push(f'Room {rid}: {label}', lambda d: d.set_room_battles(rid, **args))

    def _mode(self, key):
        if self._busy or self.rid is None or key == self.b['mode']:
            return
        kw = {'mode': key}
        if key == 'own' and self.b['list'] is None:
            kw['list'] = self.tab.s.doc.list_ref_value(self.list_combo.currentData() or 0)
        self._apply(f'battles: {key}', **kw)

    def _gate_changed(self):
        if self._busy or self.b['mode'] != 'gate':
            return
        self._apply('gate floor', gate_id=self.gate.currentData(), floor=self.floor.value() - 1)

    def _list_changed(self):
        if self._busy or self.b['mode'] != 'own':
            return
        self._apply('list', list=self.tab.s.doc.list_ref_value(self.list_combo.currentData()))

    def _rate(self):
        if self._busy:
            return
        self.rate.setEnabled(self.rate_on.isChecked())
        if self.b['mode'] == 'off':
            return
        rate = self.rate.currentData() if self.rate_on.isChecked() else None
        if rate != self.b['rate']:
            self._apply(f'rate {rate}', rate=rate)

    def _add_variant(self):
        if self.b['mode'] != 'own':
            QMessageBox.information(self, 'Variant', 'Flag variants need "Its own list".')
            return
        doc = self.tab.s.doc
        dlg = VariantDialog(doc, 'New flag variant', lists=self.lists,
                            list_ref=self.list_combo.currentData(), parent=self)
        if not dlg.exec():
            return
        vs = self.b['variants'] + [{'when': dlg.result_terms(),
                                    'list': doc.list_ref_value(dlg.list_combo.currentData())}]
        rid, flags = self.rid, dlg.new_flags()
        b = dict(self.b)
        self.tab.push(f'Room {rid}: + flag variant', lambda d: self.tab.with_flags(
            d, flags, lambda: d.set_room_battles(rid, 'own', list_ref=b['list'],
                                                 rate=b['rate'], variants=vs)))

    def _edit_variant(self):
        k = self.vtable.currentRow()
        if k < 0:
            return
        doc = self.tab.s.doc
        var = self.b['variants'][k]
        dlg = VariantDialog(doc, f'Variant {k + 1}', var.get('when'), lists=self.lists,
                            list_ref=self.M.ref(var.get('list'), 'v'), parent=self)
        if not dlg.exec():
            return
        vs = [dict(x) for x in self.b['variants']]
        vs[k] = {'when': dlg.result_terms(),
                 'list': doc.list_ref_value(dlg.list_combo.currentData())}
        rid, flags, b = self.rid, dlg.new_flags(), dict(self.b)
        self.tab.push(f'Room {rid}: variant {k + 1}', lambda d: self.tab.with_flags(
            d, flags, lambda: d.set_room_battles(rid, 'own', list_ref=b['list'],
                                                 rate=b['rate'], variants=vs)))

    def _remove_variant(self):
        k = self.vtable.currentRow()
        if k < 0:
            return
        vs = [dict(x) for x in self.b['variants']]
        vs.pop(k)
        rid, b = self.rid, dict(self.b)
        self.tab.push(f'Room {rid}: − variant {k + 1}', lambda d: d.set_room_battles(
            rid, 'own', list_ref=b['list'], rate=b['rate'], variants=vs))


# ---------------------------------------------------------------------------
# the tab
# ---------------------------------------------------------------------------

class EncountersTab(QWidget):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self._busy = False
        self._stale = False
        root = QHBoxLayout(self)
        split = QSplitter()
        root.addWidget(split)
        left = QWidget()
        lv = QVBoxLayout(left)
        self.pages = QTabWidget()
        lv.addWidget(self.pages, 1)
        # lists
        lw = QWidget()
        lwv = QVBoxLayout(lw)
        self.list_w = QListWidget()
        self.list_w.currentRowChanged.connect(self._list_picked)
        lwv.addWidget(self.list_w, 1)
        self.only_used = QCheckBox('hide lists nothing uses')
        self.only_used.toggled.connect(lambda _on: self.refresh())
        lwv.addWidget(self.only_used)
        br = QHBoxLayout()
        for txt, fn in (('New list (copy)', self._new_list), ('Delete', self._delete_list)):
            b = QPushButton(txt)
            b.clicked.connect(fn)
            br.addWidget(b)
        br.addStretch(1)
        lwv.addLayout(br)
        self.pages.addTab(lw, 'Lists')
        # gates
        self.gate_w = QListWidget()
        self.gate_w.currentRowChanged.connect(self._gate_picked)
        self.pages.addTab(self.gate_w, 'Gates')
        # rooms
        self.room_w = QListWidget()
        self.room_w.currentRowChanged.connect(self._room_picked)
        self.pages.addTab(self.room_w, 'Rooms')
        self.pages.currentChanged.connect(self._page_changed)
        h = QLabel(HELP)
        h.setWordWrap(True)
        lv.addWidget(h)
        split.addWidget(left)
        self.stack = QStackedWidget()
        self.list_ed = ListEditor(self)
        self.gate_ed = GateEditor(self)
        self.room_ed = RoomEditor(self)
        self.err = QLabel()
        self.err.setWordWrap(True)
        for w in (self.list_ed, self.gate_ed, self.room_ed, self.err):
            sc = QScrollArea()
            sc.setWidgetResizable(True)
            sc.setWidget(w)
            self.stack.addWidget(sc)
        split.addWidget(self.stack)
        split.setSizes([480, 1000])
        self.cur_list = 0
        self.cur_gate = 0
        self.cur_room = None
        self.s.undo.indexChanged.connect(self._undo_changed)
        self.refresh()

    # ---------------------------------------------------------------- data
    def _undo_changed(self, _i):
        from shiboken6 import isValid
        if not isValid(self):
            return
        if self.isVisible():
            self.refresh()
        else:
            self._stale = True

    def showEvent(self, ev):
        if self._stale:
            self._stale = False
            self.refresh()
        super().showEvent(ev)

    def refresh(self):
        doc = self.s.doc
        try:
            self.M, self.prj = doc.enc_model()
            self.lists = doc.enc_lists(self.M)
        except Exception as ex:                    # noqa: BLE001
            self.err.setText(f'<b>The project does not validate</b><br>{ex}')
            self.stack.setCurrentIndex(3)
            return
        self._busy = True
        self.list_w.clear()
        self.shown_lists = []
        for row in self.lists:
            if self.only_used.isChecked() and not row['uses'] and row['kind'] == 'game':
                continue
            it = QListWidgetItem(list_label(row))
            if row['edited']:
                _bold(it)
            if not row['uses']:
                it.setForeground(GREY)
            self.list_w.addItem(it)
            self.shown_lists.append(row['number'])
        from editor2.core import gates as GT
        self.gate_w.clear()
        self.gate_ids = []
        for g in GT.all_gates(self.prj.custom):          # S115: + the project's new gates
            n = GT.gate_floor_count(self.prj.custom, g['id']) or 0
            own = g['id'] in self.M.gates
            it = QListWidgetItem(f"{g['id']} {g['name']} — {n} floors"
                                 + (f"  · NEW (copy of gate {g['copy_of']})" if g.get('new') else '')
                                 + ('  · own plan' if own else ''))
            if own:
                _bold(it)
            self.gate_w.addItem(it)
            self.gate_ids.append(g['id'])
        self.room_w.clear()
        self.room_ids = []
        for r in doc.rooms:
            if r.get('placeholder'):
                continue
            b = doc.room_battles(r['id'])
            txt = {'off': 'no battles', 'gate': f"gate {b['gate_id']} floor {int(b['floor']) + 1}",
                   'follow': "the dive's list", 'own': f"own list {b['list']}"}[b['mode']]
            it = QListWidgetItem(f"{r['id']} ({r.get('mapID')}) — {txt}"
                                 + (f", rate {b['rate']}" if b['rate'] is not None else ''))
            if b['mode'] != 'off':
                _bold(it)
            self.room_w.addItem(it)
            self.room_ids.append(r['id'])
        self._busy = False
        self._page_changed(self.pages.currentIndex())

    def _page_changed(self, i):
        if self._busy:
            return
        if i == 0:
            n = self.cur_list if self.cur_list in self.shown_lists else (
                self.shown_lists[0] if self.shown_lists else None)
            if n is not None:
                self._busy = True
                self.list_w.setCurrentRow(self.shown_lists.index(n))
                self._busy = False
                self.list_ed.show_list(n, self.M)
                self.stack.setCurrentIndex(0)
        elif i == 1:
            self._busy = True
            self.gate_w.setCurrentRow(self.gate_ids.index(self.cur_gate))
            self._busy = False
            self.gate_ed.show_gate(self.cur_gate, self.M, self.prj, self.lists)
            self.stack.setCurrentIndex(1)
        else:
            if not self.room_ids:
                self.err.setText('No custom rooms yet (Rooms tab).')
                self.stack.setCurrentIndex(3)
                return
            rid = self.cur_room if self.cur_room in self.room_ids else self.room_ids[0]
            self.cur_room = rid
            self._busy = True
            self.room_w.setCurrentRow(self.room_ids.index(rid))
            self._busy = False
            self.room_ed.show_room(rid, self.M, self.prj, self.lists)
            self.stack.setCurrentIndex(2)

    def _list_picked(self, row):
        if self._busy or row < 0:
            return
        self.cur_list = self.shown_lists[row]
        self.list_ed.show_list(self.cur_list, self.M)
        self.stack.setCurrentIndex(0)

    def _gate_picked(self, row):
        if self._busy or row < 0:
            return
        self.cur_gate = self.gate_ids[row]
        self.gate_ed.show_gate(self.cur_gate, self.M, self.prj, self.lists)
        self.stack.setCurrentIndex(1)

    def _room_picked(self, row):
        if self._busy or row < 0:
            return
        self.cur_room = self.room_ids[row]
        self.room_ed.show_room(self.cur_room, self.M, self.prj, self.lists)
        self.stack.setCurrentIndex(2)

    def show_list(self, n):
        """Jump to list n (other tabs)."""
        self.cur_list = n
        self.pages.setCurrentIndex(0)
        self._page_changed(0)

    # ---------------------------------------------------------------- edits
    def push(self, label, op):
        cmd = C.SnapshotCommand(self.s, label, op)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            self.refresh()
            return False
        return True

    @staticmethod
    def with_flags(doc, new_flags, then):
        for nm in new_flags:
            if not any(f.get('name') == doc._slug(nm) for f in doc.flags()):
                doc.add_flag(nm)
        then()

    def _new_list(self):
        src = self.cur_list
        name, ok = QInputDialog.getText(self, 'New list', f'Name (a copy of list {src}):')
        if not ok:
            return
        out = {}

        def op(doc):
            out['r'] = doc.new_enc_list(copy_from=src, name=name.strip() or None)
        if self.push(f'New list (copy of {src})', op) and 'r' in out:
            self.show_list(out['r'][1])

    def _delete_list(self):
        n = self.cur_list
        if n < EN.PROJECT_BASE:
            QMessageBox.information(self, 'Delete', "The game's lists stay (they can be "
                                    "changed, not removed).")
            return
        lid = self.M.lists[n - EN.PROJECT_BASE]['id']
        self.push(f'Delete list {lid}', lambda doc: doc.delete_enc_list(lid))
