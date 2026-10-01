"""arena_tab.py — the Arena tab (ROADMAP P3.10b, S109; EDITOR_DESIGN §5.2b;
model: editor2/core/arena_doc.py, compiler: editor2/core/arena.py).

Left: the ten arena groups — the classes G F E D C B A S (with their entry
fee), Starry Night and the King. Right: the group's entry fee, what winning it
does (read-only — flags belong to the Progression & Flags tab) and one card
per match (three; the King fights one):

  Master       who stands for the match in the Arena Battle room — a person
               (NPC sprite) or any monster, picked like an NPC sprite.
  Monsters     1, 2 or 3: a smaller team fights only its first monsters.
  the team     one row per monster = its enemy row (EID = $E0 + 9*group +
               3*match + slot; the King $01E1-$01E3): the monster, level,
               stats, exp, AI weights, battle skills. Rows the team does not
               use are grey ("not fought").

Every edit is one undo step (SnapshotCommand); the model validates with the
compiler's own code (no summon / TERRY? in a fighting team — Iron Rule 8).
"""

from PySide6.QtCore import QSize, Qt
from PySide6.QtGui import QColor, QIcon
from PySide6.QtWidgets import (QAbstractItemView, QButtonGroup, QComboBox,
                               QGroupBox, QHBoxLayout, QHeaderView, QLabel,
                               QListWidget, QListWidgetItem, QMessageBox,
                               QPushButton, QRadioButton, QScrollArea,
                               QSpinBox, QSplitter, QTableWidget,
                               QTableWidgetItem, QToolButton, QVBoxLayout,
                               QWidget)

from editor2.app import sprite_qt as Q
from editor2.app.rooms import commands as C
from editor2.core import arena as AR
from editor2.core import arena_doc as AD
from editor2.core import monsters as M

HELP = ('The arena\'s teams are ordinary enemy rows: each match fights three rows in a '
        'fixed place (the same rows the Monsters tab lists as "arena class …"). Change a '
        'monster, its level and stats right here. A team can be 1, 2 or 3 monsters; the '
        'master is who stands for the match before the fight. The entry fee is paid in '
        'the class menu at the lobby.')
COLS = ['Monster', 'Level', 'HP', 'MP', 'ATK', 'DEF', 'AGL', 'INT', 'Exp', 'AI weights',
        'Battle skills']
KEYS = {1: 'level', 2: 'hp', 3: 'mp', 4: 'atk', 5: 'def', 6: 'agl', 7: 'int', 8: 'exp',
        9: 'ai_weights', 10: 'skills'}
GREY = QColor(150, 150, 150)


def _skill_names():
    from editor2.app.monsters_tab import _skill_names as sn
    return sn()


class MatchCard(QGroupBox):
    """One match: master, team size, the three enemy rows."""

    def __init__(self, tab, m):
        super().__init__(f'Match {m + 1}')
        self.tab, self.m = tab, m
        v = QVBoxLayout(self)
        top = QHBoxLayout()
        top.addWidget(QLabel('Master:'))
        self.master_btn = QToolButton()
        self.master_btn.setIconSize(QSize(32, 32))
        self.master_btn.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
        self.master_btn.setToolTip('Who stands for this match in the Arena Battle room: '
                                   'a person or a monster')
        self.master_btn.clicked.connect(self._pick_master)
        top.addWidget(self.master_btn)
        self.master_reset = QPushButton('Original master')
        self.master_reset.clicked.connect(lambda: self.tab.set_master(self.m, None))
        top.addWidget(self.master_reset)
        top.addSpacing(24)
        top.addWidget(QLabel('Monsters:'))
        self.size_group = QButtonGroup(self)
        self.size_btns = []
        for n in (1, 2, 3):
            b = QRadioButton(str(n))
            self.size_group.addButton(b, n)
            self.size_btns.append(b)
            top.addWidget(b)
        self.size_group.idClicked.connect(lambda n: self.tab.set_size(self.m, n))
        top.addStretch(1)
        self.reset_btn = QPushButton('Back to the original match')
        self.reset_btn.setToolTip('The original master, three monsters and the original '
                                  'enemy rows of this match')
        self.reset_btn.clicked.connect(lambda: self.tab.reset_match(self.m))
        top.addWidget(self.reset_btn)
        v.addLayout(top)
        self.table = QTableWidget(3, len(COLS))
        self.table.setHorizontalHeaderLabels(COLS)
        self.table.setVerticalHeaderLabels(['1', '2', '3'])
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.table.horizontalHeader().setSectionResizeMode(len(COLS) - 1, QHeaderView.Stretch)
        self.table.itemChanged.connect(self._cell_changed)
        self.table.setFixedHeight(self.table.verticalHeader().defaultSectionSize() * 3 + 34)
        v.addWidget(self.table)
        self.note = QLabel('')
        self.note.setWordWrap(True)
        v.addWidget(self.note)
        self.info = None

    # ---------------------------------------------------------------- fill
    def fill(self, info, gi):
        self.info, self.gi = info, gi
        tab = self.tab
        d, f = info['master']
        if f:
            sp = (d - 0x10) & 0xFF
            pm = Q.species_icon(tab.s.doc, sp, 2)
            self.master_btn.setText(f'{tab.names.get(sp, sp)}  (monster)')
        else:
            from editor2.app.rooms.canvas import SpriteCache
            pm = SpriteCache.get(d)
            self.master_btn.setText(f'person ${d:02X}')
        self.master_btn.setIcon(QIcon(pm) if pm is not None and not pm.isNull() else QIcon())
        self.master_reset.setEnabled(info['master_edited'])
        fo = self.master_btn.font()
        fo.setBold(info['master_edited'])
        self.master_btn.setFont(fo)
        self.size_btns[info['size'] - 1].setChecked(True)
        tab._busy = True
        try:
            for r, sl in enumerate(info['slots']):
                fl = sl['fields']
                combo = QComboBox()
                combo.setIconSize(QSize(24, 24))
                for sid, name, icon in tab.species_items():
                    combo.addItem(icon, f'{sid:3d} {name}', sid)
                k = combo.findData(fl['species'])
                if k < 0:            # a species the picker does not offer (215-220)
                    combo.addItem(f"{fl['species']:3d} {tab.names.get(fl['species'], '?')}",
                                  fl['species'])
                    k = combo.count() - 1
                combo.setCurrentIndex(k)
                combo.setEnabled(sl['fights'])
                combo.currentIndexChanged.connect(
                    lambda _i, c=combo, e=sl['eid']: self.tab.set_species(e, c.currentData()))
                self.table.setCellWidget(r, 0, combo)
                vals = [fl['level'], fl['hp'], fl['mp'], fl['atk'], fl['def'], fl['agl'],
                        fl['int'], fl['exp'], ' '.join(str(x) for x in fl['ai_weights']),
                        ', '.join(tab.skills.get(x, f'${x:02X}') for x in fl['skills'])]
                for c, val in enumerate(vals, start=1):
                    it = QTableWidgetItem(str(val))
                    if not sl['fights']:
                        it.setFlags(it.flags() & ~Qt.ItemIsEditable)
                        it.setForeground(GREY)
                    if sl['edited']:
                        fo = it.font()
                        fo.setBold(True)
                        it.setFont(fo)
                    self.table.setItem(r, c, it)
                self.table.setVerticalHeaderItem(
                    r, QTableWidgetItem(f"{r + 1}  EID {sl['eid']}" +
                                        ('' if sl['fights'] else '  (not fought)')))
            self.table.resizeColumnsToContents()
            self.table.horizontalHeader().setSectionResizeMode(len(COLS) - 1, QHeaderView.Stretch)
        finally:
            tab._busy = False
        n = info['size']
        self.note.setText('Bold = changed from the original game. '
                          + ('' if n == 3 else
                             ('This team fights only its first monster' if n == 1 else
                              f'This team fights only its first {n} monsters')
                             + '; the grey rows are not loaded.'))
        self.reset_btn.setEnabled(info['size_edited'] or info['master_edited']
                                  or any(s['edited'] for s in info['slots']))

    # ---------------------------------------------------------------- edits
    def _pick_master(self):
        from editor2.app.rooms.npc_panel import SpritePicker
        d, f = self.info['master']
        cur = ('monster', (d - 0x10) & 0xFF) if f else d
        dlg = SpritePicker(cur, self, monsters=True, project_data=self.tab.s.doc.data)
        dlg.setWindowTitle(f'Master of {AR.group_label(self.gi)} match {self.m + 1}')
        if dlg.exec() and dlg.value is not None and dlg.value != cur:
            v = dlg.value
            spec = {'monster': v[1]} if isinstance(v, tuple) else {'person': f'0x{v:02X}'}
            self.tab.set_master(self.m, spec)

    def _cell_changed(self, it):
        if self.tab._busy or self.info is None:
            return
        r, c = it.row(), it.column()
        key = KEYS.get(c)
        if key is None:
            return
        txt = it.text().strip()
        try:
            if key == 'ai_weights':
                val = [int(x) for x in txt.replace(',', ' ').split()]
                if len(val) != 4:
                    raise ValueError('four numbers 0-255')
            elif key == 'skills':
                inv = {v.lower(): k for k, v in self.tab.skills.items()}
                val = []
                for part in [p.strip() for p in txt.split(',') if p.strip()]:
                    val.append(inv[part.lower()] if part.lower() in inv
                               else int(part.replace('$', '0x'), 0))
                if len(val) > 4:
                    raise ValueError('at most 4 skills')
            else:
                val = int(txt)
        except ValueError as ex:
            QMessageBox.warning(self, 'Arena', f'{COLS[c]}: {txt!r} — {ex}')
            self.tab.refresh()
            return
        self.tab.set_field(self.info['slots'][r]['eid'], key, val)


class ArenaTab(QWidget):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.gi = 0
        self._busy = False
        self._items = None
        self.skills = _skill_names()
        root = QHBoxLayout(self)
        split = QSplitter()
        root.addWidget(split)
        left = QWidget()
        lv = QVBoxLayout(left)
        self.list = QListWidget()
        self.list.currentRowChanged.connect(self._picked)
        lv.addWidget(self.list, 1)
        h = QLabel(HELP)
        h.setWordWrap(True)
        lv.addWidget(h)
        split.addWidget(left)

        right = QWidget()
        self.rv = QVBoxLayout(right)
        self.title = QLabel()
        fo = self.title.font()
        fo.setPointSize(fo.pointSize() + 4)
        fo.setBold(True)
        self.title.setFont(fo)
        self.rv.addWidget(self.title)
        fee = QHBoxLayout()
        self.fee_label = QLabel('Entry fee (gold):')
        fee.addWidget(self.fee_label)
        self.fee = QSpinBox()
        self.fee.setRange(0, 65535)
        self.fee.setKeyboardTracking(False)
        self.fee.valueChanged.connect(self._fee_changed)
        fee.addWidget(self.fee)
        self.fee_reset = QPushButton('Original fee')
        self.fee_reset.clicked.connect(lambda: self._fee_changed(None))
        fee.addWidget(self.fee_reset)
        fee.addStretch(1)
        self.rv.addLayout(fee)
        self.victory = QLabel()
        self.victory.setWordWrap(True)
        self.victory.setTextInteractionFlags(Qt.TextSelectableByMouse)
        self.rv.addWidget(self.victory)
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        inner = QWidget()
        self.cards_v = QVBoxLayout(inner)
        self.cards = [MatchCard(self, m) for m in range(3)]
        for c in self.cards:
            self.cards_v.addWidget(c)
        self.cards_v.addStretch(1)
        scroll.setWidget(inner)
        self.rv.addWidget(scroll, 1)
        split.addWidget(right)
        split.setSizes([260, 1200])

        self._stale = False
        self.s.undo.indexChanged.connect(self._undo_changed)
        self.refresh()

    # ---------------------------------------------------------------- data
    @property
    def names(self):
        return {s['id']: s['name'] for s in self.s.doc.species_catalog()}

    def species_items(self):
        """[(sid, name, QIcon)] a team member may be: monsters 0-214 + the
        project's new species (never TERRY? / the summons — Iron Rule 8)."""
        if self._items is None:
            out = []
            for s in self.s.doc.species_catalog():
                if s['kind'] in ('monster', 'new'):
                    pm = Q.species_icon(self.s.doc, s['id'], 1)
                    out.append((s['id'], s['name'], QIcon(pm) if not pm.isNull() else QIcon()))
            self._items = out
        return self._items

    def _undo_changed(self, _i):
        from shiboken6 import isValid
        if not isValid(self):
            return
        self._items = None
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
            groups = doc.arena_groups()
            model = doc.monsters_model()
        except Exception as ex:                       # noqa: BLE001
            self.title.setText('The project does not validate')
            self.victory.setText(str(ex))
            return
        self._busy = True
        cur = self.gi
        self.list.clear()
        for g in groups:
            txt = g['label'] + (f"   · fee {g['fee']}" if g['fee'] is not None else '')
            sizes = [doc.arena_match(g['gi'], m, model)['size'] for m in range(g['matches'])]
            if any(n != 3 for n in sizes):
                txt += '   · ' + '/'.join(str(n) for n in sizes)
            it = QListWidgetItem(txt)
            edited = g['fee_edited'] or any(
                (lambda i: i['size_edited'] or i['master_edited'] or
                 any(s['edited'] for s in i['slots']))(doc.arena_match(g['gi'], m, model))
                for m in range(g['matches']))
            if edited:
                fo = it.font()
                fo.setBold(True)
                it.setFont(fo)
            self.list.addItem(it)
        self._busy = False
        self.list.setCurrentRow(cur)
        self._show(groups[cur], model)

    def _picked(self, row):
        if self._busy or row < 0:
            return
        self.gi = row
        self._show(self.s.doc.arena_groups()[row], self.s.doc.monsters_model())

    def _show(self, g, model):
        doc = self.s.doc
        gi = g['gi']
        self.title.setText(g['label'] + ('  — one match' if gi == AR.KING else '  — three matches'))
        has_fee = g['fee'] is not None
        for w in (self.fee_label, self.fee, self.fee_reset):
            w.setVisible(has_fee)
        if has_fee:
            self._busy = True
            self.fee.setValue(g['fee'])
            self._busy = False
            self.fee_reset.setEnabled(g['fee_edited'])
            fo = self.fee.font()
            fo.setBold(g['fee_edited'])
            self.fee.setFont(fo)
        self.victory.setText('<b>Winning it</b> (read-only — event flags are the Progression '
                             '&amp; Flags tab\'s): ' + '; '.join(AD.VICTORY[gi]))
        for m, card in enumerate(self.cards):
            card.setVisible(m < g['matches'])
            if m < g['matches']:
                card.fill(doc.arena_match(gi, m, model), gi)

    # ---------------------------------------------------------------- edits
    def _push(self, label, op):
        cmd = C.SnapshotCommand(self.s, label, op)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            self.refresh()
            return False
        return True

    def _fee_changed(self, value):
        if self._busy:
            return
        gi = self.gi
        if value is None:
            value = self.s.doc.arena_fee_vanilla(gi)
        self._push(f'{AR.group_label(gi)}: fee → {value}',
                   lambda doc: doc.set_arena_fee(gi, value))

    def set_size(self, m, n):
        if self._busy:
            return
        gi = self.gi
        self._push(f'{AR.group_label(gi)} match {m + 1}: {n} monster' + ('s' if n > 1 else ''),
                   lambda doc: doc.set_arena_size(gi, m, n))

    def set_master(self, m, spec):
        gi = self.gi
        what = 'original master' if spec is None else (
            f"master → {self.names.get(spec['monster'], spec['monster'])}"
            if 'monster' in spec else f"master → person {spec['person']}")
        self._push(f'{AR.group_label(gi)} match {m + 1}: {what}',
                   lambda doc: doc.set_arena_master(gi, m, spec))

    def set_species(self, eid, sid):
        if self._busy:
            return
        self._push(f'EID {eid}: monster → {self.names.get(sid, sid)}',
                   lambda doc: doc.set_enemy_fields(eid, {'species': sid}))

    def set_field(self, eid, key, val):
        self._push(f'EID {eid}: {key} → {val}',
                   lambda doc: doc.set_enemy_fields(eid, {key: val}))

    def reset_match(self, m):
        gi = self.gi
        self._push(f'{AR.group_label(gi)} match {m + 1}: back to the original',
                   lambda doc: doc.reset_arena_match(gi, m))
