"""resistances_tab.py — the Resistances tab (S159, ROADMAP E16; model editor2/core/
resistances.py, help 79_resistances.md).

Left: THE GRID — every monster (the game's 0-214, TERRY? and the summons 215-219,
the project's new species) x the 27 resistances in the editor's groups (elemental
spells, breaths, status ailments, stat down / drain, seals, special attacks). A cell
is the level 0-3 (0 none … 3 immune), coloured by level; a * = changed from the
original game. Select cells (drag, Shift / Ctrl-click, a whole column by its header)
and press 0-3 or use the buttons: one undo step. Filters: name, family, which monsters.

Right: THIS RESISTANCE — the clicked column's type: what it protects against, what
each level does through each ladder its skills use, how many monsters have each
level, and every skill that tests it NOW (the game's, your changed ones, your new
skills, the built-ins). SKILLS BY RESISTANCE — the whole map, group by group, plus
the damage skills that test none. Right-click a skill whose damage element can change
(the 38 measured damage skills, new skills on one of them, the built-in damage skills)
-> "Test another resistance" / its own / none; double-click opens it in the Skills tab.
Status skills test the resistance their code picks (measured) — not editable.

Enemies use their SPECIES' levels (there is no per-enemy copy); a monster the player
already owns keeps the levels it was made with (record +$68..; breeding starts the
child from its species' row) — so a change shows on new monsters and every enemy.
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QBrush, QColor, QFont
from PySide6.QtWidgets import (QAbstractItemView, QComboBox, QHBoxLayout, QHeaderView,
                               QLabel, QLineEdit, QMenu, QMessageBox, QPushButton,
                               QSplitter, QTableWidget, QTableWidgetItem, QTabWidget,
                               QTreeWidget, QTreeWidgetItem, QVBoxLayout, QWidget)

from editor2.app.rooms import commands as C
from editor2.core import gamedata as G
from editor2.core import resistances as RZ

HELP = ('Every monster\'s resistances, grouped. A level is how much a skill\'s effect gets '
        'through: 0 = none (full effect), 1 = some, 2 = strong, 3 = immune. Enemies use '
        'their species\' levels; monsters you already own keep theirs. Select cells and '
        'press 0-3 (or the buttons). Click a column to see what it blocks and which skills '
        'test it; right-click a skill on the right to make it test another resistance.')
LEVEL_BG = [None, QColor(90, 160, 235, 70), QColor(70, 140, 225, 150), QColor(35, 95, 200)]
GROUP_SHORT = {'elemental': 'ELEM', 'breath': 'BREATH', 'status': 'STATUS',
               'stat': 'STAT', 'seal': 'SEAL', 'special': 'SPECIAL'}
SHOW = [('All monsters', 'all'), ('Changed from the original', 'changed'),
        ('Your new species', 'new'), ('TERRY? + the summons', 'combat')]
FIRST_COL = 1                      # column 0 = family; the name is the row header
ORIGIN = {'game': '', 'changed': 'changed', 'new': 'your new skill', 'built-in': 'built-in'}


class LevelItem(QTableWidgetItem):
    """A grid cell: sorts by the level, not the text ('2*')."""

    def __lt__(self, other):
        a, b = self.data(Qt.UserRole), other.data(Qt.UserRole)
        if isinstance(a, int) and isinstance(b, int):
            return a < b
        return super().__lt__(other)


class ResistancesTab(QWidget):
    openSkill = Signal(int)

    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self._busy = False
        self._stale = False
        self.cur_type = 0
        self._rows = {}
        self._base = {}
        root = QVBoxLayout(self)
        h = QLabel(HELP)
        h.setWordWrap(True)
        root.addWidget(h)
        bar = QHBoxLayout()
        self.find = QLineEdit()
        self.find.setPlaceholderText('Find a monster')
        self.find.textChanged.connect(self._filter)
        bar.addWidget(self.find, 2)
        self.family = QComboBox()
        self.family.addItem('All families', None)
        for i in G.DISPLAY_ORDER:
            self.family.addItem(G.FAMILY_NAMES[i], i)
        self.family.currentIndexChanged.connect(self._filter)
        bar.addWidget(self.family)
        self.show_which = QComboBox()
        for lab, k in SHOW:
            self.show_which.addItem(lab, k)
        self.show_which.currentIndexChanged.connect(self._filter)
        bar.addWidget(self.show_which)
        self.group = QComboBox()
        self.group.addItem('Every group', None)
        for k, t, _ts in RZ.GROUPS:
            self.group.addItem(t, k)
        self.group.currentIndexChanged.connect(self._columns)
        bar.addWidget(self.group)
        bar.addWidget(QLabel('Set selected:'))
        self.set_btns = []
        for lv, tip in enumerate(['none — full effect', 'some', 'strong', 'immune']):
            b = QPushButton(str(lv))
            b.setFixedWidth(34)
            b.setToolTip(f'Level {lv}: {tip} (or press {lv})')
            b.clicked.connect(lambda _c=False, lv=lv: self.set_selected(lv))
            bar.addWidget(b)
            self.set_btns.append(b)
        self.orig_btn = QPushButton('Original')
        self.orig_btn.setToolTip('The selected cells back to the original game\'s levels '
                                 '(a new species: its clone_from monster\'s)')
        self.orig_btn.clicked.connect(lambda: self.set_selected(None))
        bar.addWidget(self.orig_btn)
        root.addLayout(bar)

        split = QSplitter()
        root.addWidget(split, 1)
        self.grid = QTableWidget()
        self.grid.setSelectionMode(QAbstractItemView.ExtendedSelection)
        self.grid.setSelectionBehavior(QAbstractItemView.SelectItems)
        self.grid.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.grid.verticalHeader().setDefaultAlignment(Qt.AlignLeft | Qt.AlignVCenter)
        self.grid.setSortingEnabled(False)
        self.grid.currentCellChanged.connect(self._cell_moved)
        self.grid.cellDoubleClicked.connect(self._cycle)
        self.grid.horizontalHeader().sectionClicked.connect(self._header_clicked)
        self.grid.installEventFilter(self)
        cols = ['Family'] + [self._head(t) for t in RZ.ORDER]
        self.grid.setColumnCount(len(cols))
        self.grid.setHorizontalHeaderLabels(cols)
        for k, t in enumerate(RZ.ORDER):
            hi = self.grid.horizontalHeaderItem(FIRST_COL + k)
            hi.setToolTip(f'<b>{RZ.label(t)}</b> — {RZ.GROUP_TITLE[RZ.GROUP_OF[t]]}<br>'
                          f'{RZ.TYPES[t][1]}')
        hh = self.grid.horizontalHeader()
        hh.setSectionResizeMode(QHeaderView.Interactive)
        hh.setSortIndicatorShown(True)
        split.addWidget(self.grid)

        right = QTabWidget()
        split.addWidget(right)
        split.setSizes([900, 520])
        # this resistance
        w = QWidget()
        v = QVBoxLayout(w)
        self.t_title = QLabel()
        self.t_title.setWordWrap(True)
        v.addWidget(self.t_title)
        self.t_blurb = QLabel()
        self.t_blurb.setWordWrap(True)
        v.addWidget(self.t_blurb)
        self.t_ladder = QLabel()
        self.t_ladder.setWordWrap(True)
        self.t_ladder.setTextFormat(Qt.RichText)
        v.addWidget(self.t_ladder)
        self.t_counts = QLabel()
        self.t_counts.setWordWrap(True)
        v.addWidget(self.t_counts)
        v.addWidget(QLabel('<b>Skills that test it</b> (right-click to move one; '
                           'double-click = the Skills tab):'))
        self.t_skills = self._skill_tree()
        v.addWidget(self.t_skills, 1)
        right.addTab(w, 'This resistance')
        # the whole map
        w2 = QWidget()
        v2 = QVBoxLayout(w2)
        self.map_find = QLineEdit()
        self.map_find.setPlaceholderText('Find a skill')
        self.map_find.textChanged.connect(self._fill_map)
        v2.addWidget(self.map_find)
        self.map = self._skill_tree()
        v2.addWidget(self.map, 1)
        right.addTab(w2, 'Skills by resistance')
        self.right = right

        self.s.undo.indexChanged.connect(self._undo_changed)
        self.refresh()

    # ------------------------------------------------------------ helpers
    @staticmethod
    def _head(t):
        return f'{GROUP_SHORT[RZ.GROUP_OF[t]]}\n{G.RESIST_NAMES[t]}'

    def _skill_tree(self):
        tr = QTreeWidget()
        tr.setHeaderLabels(['Skill', 'Ladder', 'Note'])
        tr.setSelectionMode(QAbstractItemView.ExtendedSelection)
        tr.setContextMenuPolicy(Qt.CustomContextMenu)
        tr.customContextMenuRequested.connect(lambda pos, tr=tr: self._skill_menu(tr, pos))
        tr.itemDoubleClicked.connect(self._skill_open)
        tr.header().setSectionResizeMode(0, QHeaderView.ResizeToContents)
        return tr

    def _push(self, label, fn):
        cmd = C.SnapshotCommand(self.s, label, fn)
        self.s.undo.push(cmd)
        if getattr(cmd, 'error', None) is not None:
            QMessageBox.warning(self, 'Resistances', str(cmd.error))
            self.refresh()
            return False
        return True

    # ------------------------------------------------------------ refresh
    def _undo_changed(self, _i):
        from shiboken6 import isValid
        if not isValid(self) or not all(isValid(w) for w in (self.grid, self.family,
                                                             self.map, self.t_skills)):
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
            model = doc.monsters_model()
            cat = [c for c in doc.species_catalog() if c['id'] != 220]
            self._rows = {c['id']: doc.species_row(c['id'], model) for c in cat}
            self._base = {c['id']: doc.species_base_row(c['id']) for c in cat}
            self._skills = RZ.by_type(doc)
        except Exception as ex:                             # noqa: BLE001
            self.t_title.setText(f'⚠ the project does not validate: {ex}')
            return
        self._cat = cat
        self._fill_grid()
        self._show_type(self.cur_type)
        self._fill_map()

    def _fill_grid(self):
        g = self.grid
        keep = {(i.row(), i.column()) for i in g.selectedIndexes()}
        sort_col = g.horizontalHeader().sortIndicatorSection()
        sort_ord = g.horizontalHeader().sortIndicatorOrder()
        self._busy = True
        g.setUpdatesEnabled(False)
        g.setSortingEnabled(False)
        g.clearContents()
        g.setRowCount(len(self._cat))
        bold = QFont()
        bold.setBold(True)
        for r, c in enumerate(self._cat):
            sid = c['id']
            row, base = self._rows[sid], self._base[sid]
            # the name is the ROW HEADER (it stays in view while the columns scroll)
            hd = QTableWidgetItem(f"{sid:3d}  {c['name']}")
            g.setVerticalHeaderItem(r, hd)
            fam = c['family']
            it = QTableWidgetItem(G.FAMILY_NAMES[fam] if 0 <= fam < len(G.FAMILY_NAMES) else str(fam))
            it.setData(Qt.UserRole, sid)
            it.setData(Qt.UserRole + 1, c['kind'])
            it.setData(Qt.UserRole + 3, fam)
            g.setItem(r, 0, it)
            changed_any = False
            for k, t in enumerate(RZ.ORDER):
                lv = row[15 + t] & 3
                was = base[15 + t] & 3
                ch = lv != was
                changed_any |= ch
                cell = LevelItem(f'{lv}*' if ch else str(lv))
                cell.setData(Qt.UserRole, lv)
                cell.setTextAlignment(Qt.AlignCenter)
                if LEVEL_BG[lv] is not None:
                    cell.setBackground(QBrush(LEVEL_BG[lv]))
                if lv == 3:
                    cell.setForeground(QBrush(QColor(255, 255, 255)))
                if ch:
                    cell.setFont(bold)
                    cell.setToolTip(f"{c['name']} — {RZ.label(t)}: {lv} (the original: {was})")
                else:
                    cell.setToolTip(f"{c['name']} — {RZ.label(t)}: {lv}")
                g.setItem(r, FIRST_COL + k, cell)
            it.setData(Qt.UserRole + 2, changed_any)
            if changed_any:
                it.setFont(bold)
                hd.setFont(bold)
        g.resizeColumnsToContents()
        g.setSortingEnabled(True)
        if sort_col >= 0:
            g.sortItems(sort_col, sort_ord)
        g.setUpdatesEnabled(True)
        for (r, col) in keep:
            if r < g.rowCount():
                g.item(r, col) and g.item(r, col).setSelected(True)
        self._busy = False
        self._filter()
        self._columns()

    def _filter(self, *_a):
        g = self.grid
        t = self.find.text().strip().lower()
        fam = self.family.currentData()
        which = self.show_which.currentData()
        for r in range(g.rowCount()):
            it, hd = g.item(r, 0), g.verticalHeaderItem(r)
            if it is None or hd is None:
                continue
            hide = bool(t) and t not in hd.text().lower()
            if fam is not None and it.data(Qt.UserRole + 3) != fam:
                hide = True
            kind = it.data(Qt.UserRole + 1)
            if which == 'changed' and not it.data(Qt.UserRole + 2):
                hide = True
            elif which == 'new' and kind != 'new':
                hide = True
            elif which == 'combat' and kind != 'combat':
                hide = True
            g.setRowHidden(r, hide)

    def _columns(self, *_a):
        grp = self.group.currentData()
        for k, t in enumerate(RZ.ORDER):
            self.grid.setColumnHidden(FIRST_COL + k, grp is not None and RZ.GROUP_OF[t] != grp)

    # ------------------------------------------------------------ the grid
    def eventFilter(self, obj, ev):
        from PySide6.QtCore import QEvent
        if obj is self.grid and ev.type() == QEvent.KeyPress and ev.text() in ('0', '1', '2', '3'):
            self.set_selected(int(ev.text()))
            return True
        return super().eventFilter(obj, ev)

    def _cell_moved(self, r, c, _pr, _pc):
        if self._busy or c < FIRST_COL:
            return
        self._show_type(RZ.ORDER[c - FIRST_COL])

    def _header_clicked(self, c):
        if c >= FIRST_COL:
            self._show_type(RZ.ORDER[c - FIRST_COL])

    def _cycle(self, r, c):
        if c < FIRST_COL:
            return
        it = self.grid.item(r, c)
        sid = self.grid.item(r, 0).data(Qt.UserRole)
        t = RZ.ORDER[c - FIRST_COL]
        self._apply({sid: {G.RESIST_NAMES[t]: (it.data(Qt.UserRole) + 1) % 4}},
                    f'{self.grid.verticalHeaderItem(r).text().strip()}: {G.RESIST_NAMES[t]} +1')

    def selected_cells(self):
        """[(species id, resistance index)] of the selected level cells (visible rows)."""
        out = []
        for ix in self.grid.selectedIndexes():
            r, c = ix.row(), ix.column()
            if c < FIRST_COL or self.grid.isRowHidden(r) or self.grid.isColumnHidden(c):
                continue
            out.append((self.grid.item(r, 0).data(Qt.UserRole), RZ.ORDER[c - FIRST_COL]))
        return out

    def set_selected(self, level):
        """level 0-3, or None = the original game's level, for every selected cell."""
        cells = self.selected_cells()
        if not cells:
            return
        ch = {}
        for sid, t in cells:
            lv = (self._base[sid][15 + t] & 3) if level is None else level
            if (self._rows[sid][15 + t] & 3) != lv:
                ch.setdefault(sid, {})[G.RESIST_NAMES[t]] = lv
        if not ch:
            return
        n = sum(len(v) for v in ch.values())
        what = 'the original' if level is None else str(level)
        self._apply(ch, f'resistances: {n} cell(s) → {what}')

    def _apply(self, ch, label):
        self._push(label, lambda doc: doc.set_species_resists(ch))

    # ------------------------------------------------------------ this resistance
    def _show_type(self, t):
        self.cur_type = t
        rows = self._skills.get(t, []) if hasattr(self, '_skills') else []
        self.t_title.setText(f'<h3>{RZ.label(t)}</h3>{RZ.GROUP_TITLE[RZ.GROUP_OF[t]]}')
        self.t_blurb.setText(RZ.TYPES[t][1])
        lads = []
        for r in rows:
            if r['ladder'] not in lads:
                lads.append(r['ladder'])
        if not lads:
            lads = ['spell']
        html = ['<table cellspacing="0" cellpadding="3" border="1"><tr><th>level</th>']
        html += [f'<th>{RZ.LADDER_TITLE[k]}</th>' for k in lads]
        html.append('</tr>')
        for lv, nm in enumerate(['0 none', '1 some', '2 strong', '3 immune']):
            html.append(f'<tr><td>{nm}</td>' + ''.join(
                f'<td>{RZ.LADDERS[k][1][lv]}</td>' for k in lads) + '</tr>')
        html.append('</table>')
        if 'slash' in lads:
            html.append('<small>An elemental slash hits harder than plain on a target with '
                        'no resistance (the game\'s own rule).</small>')
        self.t_ladder.setText(''.join(html))
        cnt = RZ.level_counts({s: r for s, r in self._rows.items() if s < 215 or s > 220}, t)
        self.t_counts.setText('Monsters at level 0 / 1 / 2 / 3: '
                              + ' / '.join(str(n) for n in cnt)
                              + ' (the game\'s 215 + your new species; enemies use these)')
        self._fill_tree(self.t_skills, {t: rows}, flat=True)

    def _fill_map(self, *_a):
        if not hasattr(self, '_skills'):
            return
        self._fill_tree(self.map, self._skills, flat=False, find=self.map_find.text())

    def _fill_tree(self, tr, by, flat, find=''):
        tr.clear()
        find = (find or '').strip().lower()

        def add(parent, r):
            note = ORIGIN[r['origin']]
            if r['via']:
                note = f"{note} (works like {r['via']})"
            if r['origin'] == 'changed' and r['native'] is not None:
                note += f" — its own: {G.RESIST_NAMES[r['native']]}"
            if not r['editable']:
                note = (note + ' · ' if note else '') + 'fixed (its code picks it)'
            it = QTreeWidgetItem([f"{r['sid']:3d}  {r['name']}", RZ.LADDER_TITLE[r['ladder']],
                                  note])
            it.setData(0, Qt.UserRole, r['sid'])
            it.setData(0, Qt.UserRole + 1, r['editable'])
            if r['origin'] != 'game':
                f = it.font(0)
                f.setBold(True)
                it.setFont(0, f)
            (parent.addChild(it) if parent is not None else tr.addTopLevelItem(it))
            return it

        if flat:
            for rows in by.values():
                for r in rows:
                    add(None, r)
            return
        for k, title, ts in RZ.GROUPS:
            gi = QTreeWidgetItem([title, '', ''])
            tr.addTopLevelItem(gi)
            n = 0
            for t in ts:
                rows = [r for r in by.get(t, []) if not find or find in r['name'].lower()]
                ti = QTreeWidgetItem([f"{RZ.label(t)}  ({len(rows)})", '', ''])
                ti.setData(0, Qt.UserRole + 2, t)
                gi.addChild(ti)
                for r in rows:
                    add(ti, r)
                n += len(rows)
                ti.setExpanded(bool(find) or bool(rows))
            gi.setExpanded(True)
        rows = [r for r in by.get(None, []) if not find or find in r['name'].lower()]
        ni = QTreeWidgetItem([f'Tests no resistance ({len(rows)}) — damage skills', '', ''])
        tr.addTopLevelItem(ni)
        for r in rows:
            add(ni, r)
        ni.setExpanded(True)

    # ------------------------------------------------------------ moving skills
    def _skill_menu(self, tr, pos):
        its = [i for i in tr.selectedItems() if i.data(0, Qt.UserRole) is not None]
        if not its:
            it = tr.itemAt(pos)
            its = [it] if it is not None and it.data(0, Qt.UserRole) is not None else []
        ed = [i for i in its if i.data(0, Qt.UserRole + 1)]
        m = QMenu(self)
        if not ed:
            a = m.addAction('Status skills test the resistance their code picks — fixed')
            a.setEnabled(False)
        else:
            sids = [i.data(0, Qt.UserRole) for i in ed]
            sub = m.addMenu(f'Test another resistance ({len(sids)} skill(s))')
            for _k, title, ts in RZ.GROUPS:
                gm = sub.addMenu(title)
                for t in ts:
                    gm.addAction(RZ.label(t)).triggered.connect(
                        lambda _c=False, t=t, sids=sids: self.move_skills(sids, t))
            m.addAction('Back to its own').triggered.connect(
                lambda _c=False, sids=sids: self.move_skills(sids, None))
            m.addAction('No resistance (ignores them)').triggered.connect(
                lambda _c=False, sids=sids: self.move_skills(sids, 'none'))
        if its:
            m.addSeparator()
            sid0 = its[0].data(0, Qt.UserRole)
            m.addAction('Open in the Skills tab').triggered.connect(
                lambda _c=False, s=sid0: self.openSkill.emit(s))
        m.exec(tr.viewport().mapToGlobal(pos))

    def move_skills(self, sids, element):
        """element: 0-26, 'none' or None (= its own) for every skill in `sids`."""
        lab = ('its own' if element is None else 'no resistance' if element == 'none'
               else G.RESIST_NAMES[element])

        def op(doc):
            for s in sids:
                doc.set_skill_element(s, element)
        return self._push(f'{len(sids)} skill(s) → {lab}', op)

    def _skill_open(self, it, _col):
        sid = it.data(0, Qt.UserRole)
        if sid is not None:
            self.openSkill.emit(sid)
