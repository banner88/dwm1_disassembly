"""breeding_tab.py — the Breeding tab (S113, ROADMAP P3.12; EDITOR_DESIGN §5.4
"As built S113").

Three pages over `gamedata.breeding` (model: editor2/core/breeding_doc.py):

  By monster       every monster with its breeding DEPTH (0 = you can get it
                   without breeding) and how you get it; for the selected one:
                   every recipe that makes it (its library recipe + the
                   special recipes, with how many parent pairs each really
                   decides), what it makes, and edit / add / remove.
                   Right: "Try a cross" (pedigree, mate, plus, levels ->
                   offspring + which recipe decided + plus), the depth chart
                   (this project against the original tables) and a problem
                   list (monsters nobody can get, recipes that never fire).
  Special recipes  the whole special table in the order the game reads it
                   (the editor sorts it: the most specific recipe first).
  Family recipes   the 215 family recipes (= what each library page shows).

Plus "Generate a tree…" (editor2/core/breed_gen.py: the randomizer's
depth-profile builder on this project) and "Work on the whole table".
Every answer comes from the resolver model, which a PyBoy census matched to
the game for every pair (tools/census_breeding.py). Every edit is one undo
step (SnapshotCommand) validated by the compiler's own model.
"""

import os

from PySide6.QtCore import Qt, QTimer, Signal
from PySide6.QtGui import QColor, QPainter, QPen, QBrush
from PySide6.QtWidgets import (QAbstractItemView, QComboBox, QDialog, QDialogButtonBox,
                               QFormLayout, QGroupBox, QHBoxLayout, QHeaderView, QLabel,
                               QLineEdit, QListWidget, QListWidgetItem, QMessageBox,
                               QPushButton, QSpinBox, QSplitter, QTabWidget,
                               QTableWidget, QTableWidgetItem, QTreeWidget,
                               QTreeWidgetItem, QVBoxLayout, QWidget, QGridLayout)

from editor2.app.rooms import commands as C
from editor2.app.families_tab import family_icons
from editor2.core import breeding as B
from editor2.core import gamedata as G

HELP = ('Breeding: the game first reads the SPECIAL recipes (top to bottom, the first '
        'that fits wins; a "+N" recipe needs that much plus on the egg), then the FAMILY '
        'recipe of each monster (the one its library page shows), and when nothing fits '
        'the egg is the pedigree\'s own kind. Depth = how many breedings a monster is '
        'from the ones you can get without breeding (0). The editor keeps the special '
        'recipes sorted most specific first, so a recipe you add for two exact monsters '
        'beats the general ones that also fit them.')

SRC_LABEL = {'vanilla': 'original', 'edited': 'original, changed', 'added': 'added',
             'table': 'your table'}


def depth_text(d):
    return '—' if d >= B.UNREACHABLE else str(d)


class DepthChart(QWidget):
    """Bars: how many monsters sit at each depth — this project (filled) and
    the original tables (outline)."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.cur, self.van = {}, {}
        self.setMinimumHeight(150)

    def set_data(self, cur, van):
        self.cur, self.van = dict(cur), dict(van)
        self.update()

    def paintEvent(self, _ev):
        p = QPainter(self)
        keys = sorted(set(self.cur) | set(self.van))
        if not keys:
            return
        w, h = self.width(), self.height()
        top = max(max(self.cur.values(), default=1), max(self.van.values(), default=1), 1)
        n = len(keys)
        bw = max(8, (w - 20) // max(n, 1))
        base = h - 18
        pal = self.palette()
        p.setPen(pal.text().color())
        for i, k in enumerate(keys):
            x = 10 + i * bw
            c, v = self.cur.get(k, 0), self.van.get(k, 0)
            hc = int((base - 14) * min(c, top) / top)
            hv = int((base - 14) * min(v, top) / top)
            p.fillRect(x + 2, base - hc, bw - 6, hc, QColor(70, 130, 200) if k < 99
                       else QColor(200, 70, 70))
            p.setPen(QPen(pal.text().color(), 1, Qt.DashLine))
            p.drawRect(x + 2, base - hv, bw - 6, hv)
            p.setPen(pal.text().color())
            p.drawText(x, base + 2, bw, 14, Qt.AlignHCenter, depth_text(k) if k < 99 else 'none')
            p.drawText(x, base - hc - 14, bw, 14, Qt.AlignHCenter, str(c))


class MatcherCombo(QComboBox):
    """A recipe parent: a family (any monster of it) or one monster."""

    def __init__(self, names, species, icons, families=True, parent=None):
        super().__init__(parent)
        self.setEditable(False)
        self.setMaxVisibleItems(25)
        if families:
            for f in G.DISPLAY_ORDER:
                label = '??? (Boss)' if G.FAMILY_NAMES[f] == 'Boss' else G.FAMILY_NAMES[f]
                self.addItem(icons[f], f'[{label} family]', 0xF0 + f)
        for s in species:
            self.addItem(f'{s:3d}  {names.get(s, "?")}', s)

    def set_value(self, m):
        i = self.findData(m)
        if i >= 0:
            self.setCurrentIndex(i)

    def value(self):
        return self.currentData()


class RecipeDialog(QDialog):
    """Edit / add one recipe. `kind` 'special' (pedigree, mate, min plus,
    offspring, plus added) or 'family' (pedigree, mate; the offspring is the
    monster whose recipe it is)."""

    def __init__(self, parent, an, icons, title, values=None, kind='special'):
        super().__init__(parent)
        self.setWindowTitle(title)
        self.an = an
        values = values or {}
        f = QFormLayout(self)
        names = an.names
        self.p1 = MatcherCombo(names, an.species, icons)
        self.p2 = MatcherCombo(names, an.species, icons)
        self.p1.set_value(values.get('p1', 0xF0))
        self.p2.set_value(values.get('p2', 0xF0))
        f.addRow('Pedigree (parent 1)', self.p1)
        f.addRow('Mate (parent 2)', self.p2)
        self.kind = kind
        if kind == 'special':
            self.min_plus = QSpinBox()
            self.min_plus.setRange(0, 99)
            self.min_plus.setValue(values.get('min_plus', 0))
            self.min_plus.setToolTip('The egg needs at least this much plus (0 = always). '
                                     'Plus = the higher parent plus + 1, + up to 4 for the '
                                     'parents\' levels.')
            f.addRow('Needs plus at least', self.min_plus)
            self.result = MatcherCombo(names, an.species, icons, families=False)
            self.result.set_value(values.get('result', 0))
            f.addRow('Makes', self.result)
            self.plus_mod = QSpinBox()
            self.plus_mod.setRange(0, 99)
            self.plus_mod.setValue(values.get('plus_mod', 0))
            self.plus_mod.setToolTip('Added to the egg\'s plus (the game caps it at 99).')
            f.addRow('Adds plus', self.plus_mod)
        note = QLabel('A family stands for every monster of it. The editor sorts the special '
                      'recipes: two exact monsters before monster × family, before family × '
                      'monster, before family × family; a + recipe before the same parents '
                      'without it.' if kind == 'special' else
                      'This is the recipe the monster\'s library page shows. The game reads '
                      'the special recipes first.')
        note.setWordWrap(True)
        f.addRow(note)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        f.addRow(bb)

    def values(self):
        v = {'p1': self.p1.value(), 'p2': self.p2.value()}
        if self.kind == 'special':
            v.update(min_plus=self.min_plus.value(), result=self.result.value(),
                     plus_mod=self.plus_mod.value())
        return v


class GenerateDialog(QDialog):
    """breed_gen.propose on this project: pick the depth profile, the deepest
    depth, a seed and the monsters to keep; see the result before applying."""

    def __init__(self, parent, session, an):
        super().__init__(parent)
        self.setWindowTitle('Generate a breeding tree')
        self.s, self.an = session, an
        self.proposal = None
        self.gd = None
        v = QVBoxLayout(self)
        t = QLabel('Builds a NEW special table and new family recipes for every monster you '
                   'cannot get without breeding, so the tree reaches the depths you ask for: '
                   'deeper = monsters with a higher level cap. Monsters you KEEP keep every '
                   'recipe that makes them. Nothing changes until you press Apply (one undo '
                   'step).')
        t.setWordWrap(True)
        v.addWidget(t)
        from editor2.core import breed_gen as BGm
        self.BG = BGm
        row = QHBoxLayout()
        row.addWidget(QLabel('Deepest'))
        self.max_depth = QSpinBox()
        self.max_depth.setRange(2, BGm.MAX_DEPTH_LIMIT)
        self.max_depth.setValue(BGm.DEFAULT_MAX_DEPTH)
        self.max_depth.setToolTip('No game limit. The real ceiling is how many monsters '
                                  'cannot be had without breeding (each depth needs at '
                                  'least one).')
        self.max_depth.valueChanged.connect(self._depth_changed)
        row.addWidget(self.max_depth)
        b = QPushButton('Default shares')
        b.clicked.connect(lambda: self._fill_shares(BGm.default_profile(self.max_depth.value())))
        row.addWidget(b)
        b = QPushButton('Even shares')
        b.clicked.connect(lambda: self._fill_shares(
            {d: 1 for d in range(1, self.max_depth.value() + 1)}))
        row.addWidget(b)
        row.addWidget(QLabel('Seed'))
        self.seed = QSpinBox()
        self.seed.setRange(0, 999999)
        self.seed.setValue(113)
        row.addWidget(self.seed)
        row.addStretch(1)
        v.addLayout(row)
        self.breedable = [x for x in an.species if x not in an.roots]
        self.cap_note = QLabel()
        self.cap_note.setWordWrap(True)
        v.addWidget(self.cap_note)
        self.share_box = QWidget()
        self.grid = QGridLayout(self.share_box)
        self.grid.setContentsMargins(0, 0, 0, 0)
        v.addWidget(self.share_box)
        self.share = {}
        self._depth_changed()
        v.addWidget(QLabel('Keep the recipes of (tick monsters):'))
        self.keep = QListWidget()
        for s in an.species:
            it = QListWidgetItem(f'{s:3d}  {an.names.get(s, "?")}   depth {depth_text(an.depth[s])}')
            it.setData(Qt.UserRole, s)
            it.setFlags(it.flags() | Qt.ItemIsUserCheckable)
            it.setCheckState(Qt.Unchecked)
            self.keep.addItem(it)
        v.addWidget(self.keep, 1)
        self.chart = DepthChart()
        v.addWidget(self.chart)
        self.report = QLabel('')
        self.report.setWordWrap(True)
        v.addWidget(self.report)
        bb = QDialogButtonBox()
        self.b_prop = bb.addButton('Propose', QDialogButtonBox.ActionRole)
        self.b_apply = bb.addButton('Apply', QDialogButtonBox.AcceptRole)
        bb.addButton(QDialogButtonBox.Cancel)
        self.b_apply.setEnabled(False)
        self.b_prop.clicked.connect(self.propose)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self.resize(720, 640)

    def _fill_shares(self, prof):
        tot = sum(prof.values()) or 1
        for d, sb in self.share.items():
            sb.setValue(int(round(100 * prof.get(d, 0) / tot)))

    def _depth_changed(self, *_):
        """One share box per depth 1..Deepest (10 per row)."""
        md = self.max_depth.value()
        while self.grid.count():
            w = self.grid.takeAt(0).widget()
            if w is not None:
                w.hide()
                w.setParent(None)
                w.deleteLater()
        self.share = {}
        for d in range(1, md + 1):
            r, c = divmod(d - 1, 10)
            sb = QSpinBox()
            sb.setRange(0, 100)
            sb.setSuffix(' %')
            self.grid.addWidget(QLabel(f'depth {d}'), 2 * r, c)
            self.grid.addWidget(sb, 2 * r + 1, c)
            self.share[d] = sb
        self._fill_shares(self.BG.default_profile(md))
        n = len(self.breedable)
        self.cap_note.setText(
            f'{n} monsters cannot be had without breeding — the tree is built from them, '
            f'so it can be at most {n} deep' + (' (fewer than you ask: lower Deepest, or '
            'take monsters out of the wild lists).' if n < md else '.') +
            ' Shares are the part of those monsters at each depth (any total).')

    def pins(self):
        return [self.keep.item(i).data(Qt.UserRole) for i in range(self.keep.count())
                if self.keep.item(i).checkState() == Qt.Checked]

    def propose(self):
        from editor2.core import breed_gen as BG
        from editor2.core.project import Project
        import copy
        doc = self.s.doc
        prj = Project(copy.deepcopy(doc.data), doc.project_dir)
        prof = {d: sb.value() / 100.0 for d, sb in self.share.items()}
        self.proposal = BG.propose(prj, seed=self.seed.value(), profile=prof,
                                   max_depth=self.max_depth.value(), pins=self.pins())
        self.gd = BG.to_gamedata(self.proposal)
        an2 = B.Analysis(Project(BG.apply_to(doc.data, self.gd), doc.project_dir))
        self.chart.set_data(an2.histogram(), self.an.histogram())
        unr = an2.unreachable()
        nf = an2.never_fires()[0]
        self.report.setText(
            f'Asked for depth {self.max_depth.value()}. '
            f'{len(self.proposal.special)} special recipes, '
            f'{len(self.gd["family"])} family recipes changed; deepest '
            f'{max((d for d in an2.depth.values() if d < 99), default=0)}; '
            f'{len(unr)} monsters nobody can get; {len(nf)} special recipes never fire. '
            '(Bars = the proposal, dashed = now.)')
        self.b_apply.setEnabled(True)


class BreedingTab(QWidget):
    showMonster = Signal(int)

    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.icons = family_icons(session.doc)
        v = QVBoxLayout(self)
        h = QLabel(HELP)
        h.setWordWrap(True)
        v.addWidget(h)
        top = QHBoxLayout()
        self.summary = QLabel()
        top.addWidget(self.summary, 1)
        self.b_gen = QPushButton('Generate a tree…')
        self.b_gen.clicked.connect(self._generate)
        top.addWidget(self.b_gen)
        self.b_table = QPushButton('Work on the whole table')
        self.b_table.setToolTip('Store the special recipes as one list you own (for heavy '
                                'rework) instead of changes to the original 825.')
        self.b_table.clicked.connect(self._to_table)
        top.addWidget(self.b_table)
        self.b_orig = QPushButton('Original special recipes')
        self.b_orig.clicked.connect(self._to_vanilla)
        top.addWidget(self.b_orig)
        v.addLayout(top)
        self.pages = QTabWidget()
        v.addWidget(self.pages, 1)
        self._build_by_monster()
        self._build_special()
        self._build_family()
        self._stale = False
        self._timer = QTimer(self)
        self._timer.setSingleShot(True)
        self._timer.timeout.connect(self.refresh)
        self.s.undo.indexChanged.connect(self._undo_changed)
        self.refresh()

    # ------------------------------------------------------------ layout
    def _build_by_monster(self):
        page = QWidget()
        split = QSplitter()
        lay = QVBoxLayout(page)
        lay.addWidget(split)
        left = QWidget()
        lv = QVBoxLayout(left)
        self.filter = QLineEdit()
        self.filter.setPlaceholderText('Find a monster…')
        self.filter.textChanged.connect(self._fill_species)
        lv.addWidget(self.filter)
        self.sp_tree = QTreeWidget()
        self.sp_tree.setHeaderLabels(['Monster', 'Depth', 'You get it'])
        self.sp_tree.setRootIsDecorated(False)
        self.sp_tree.setSortingEnabled(True)
        self.sp_tree.sortByColumn(0, Qt.AscendingOrder)
        self.sp_tree.setColumnWidth(0, 150)
        self.sp_tree.setColumnWidth(1, 50)
        self.sp_tree.currentItemChanged.connect(lambda *_: self._show_species())
        lv.addWidget(self.sp_tree, 1)
        split.addWidget(left)

        mid = QWidget()
        mv = QVBoxLayout(mid)
        self.sp_title = QLabel()
        self.sp_title.setWordWrap(True)
        mv.addWidget(self.sp_title)
        mv.addWidget(QLabel('<b>Made by</b>'))
        self.made_by = QTreeWidget()
        self.made_by.setHeaderLabels(['Recipe', 'Decides', 'Where'])
        self.made_by.setRootIsDecorated(False)
        self.made_by.setColumnWidth(0, 300)
        self.made_by.setColumnWidth(1, 110)
        self.made_by.itemDoubleClicked.connect(lambda *_: self._edit_made_by())
        mv.addWidget(self.made_by, 2)
        row = QHBoxLayout()
        self.b_add = QPushButton('Add a recipe for it…')
        self.b_add.clicked.connect(self._add_for_species)
        row.addWidget(self.b_add)
        self.b_edit = QPushButton('Change…')
        self.b_edit.clicked.connect(self._edit_made_by)
        row.addWidget(self.b_edit)
        self.b_rm = QPushButton('Remove')
        self.b_rm.clicked.connect(self._remove_made_by)
        row.addWidget(self.b_rm)
        row.addStretch(1)
        mv.addLayout(row)
        mv.addWidget(QLabel('<b>Makes</b> (as pedigree or mate)'))
        self.makes = QTreeWidget()
        self.makes.setHeaderLabels(['Egg', 'Depth', 'With'])
        self.makes.setRootIsDecorated(False)
        self.makes.setColumnWidth(0, 150)
        self.makes.setColumnWidth(1, 50)
        self.makes.itemDoubleClicked.connect(self._goto_item)
        mv.addWidget(self.makes, 1)
        split.addWidget(mid)

        right = QWidget()
        rv = QVBoxLayout(right)
        box = QGroupBox('Try a cross')
        bf = QFormLayout(box)
        an = self.s.doc.breeding_analysis()
        self.t_p1 = MatcherCombo(an.names, an.species, self.icons, families=False)
        self.t_p2 = MatcherCombo(an.names, an.species, self.icons, families=False)
        self.t_plus1, self.t_plus2 = QSpinBox(), QSpinBox()
        self.t_lv1, self.t_lv2 = QSpinBox(), QSpinBox()
        for sb in (self.t_plus1, self.t_plus2):
            sb.setRange(0, 99)
        for sb in (self.t_lv1, self.t_lv2):
            sb.setRange(1, 99)
            sb.setValue(10)
        r1 = QHBoxLayout()
        r1.addWidget(self.t_p1, 1)
        r1.addWidget(QLabel('+'))
        r1.addWidget(self.t_plus1)
        r1.addWidget(QLabel('Lv'))
        r1.addWidget(self.t_lv1)
        r2 = QHBoxLayout()
        r2.addWidget(self.t_p2, 1)
        r2.addWidget(QLabel('+'))
        r2.addWidget(self.t_plus2)
        r2.addWidget(QLabel('Lv'))
        r2.addWidget(self.t_lv2)
        bf.addRow('Pedigree', r1)
        bf.addRow('Mate', r2)
        self.t_out = QLabel()
        self.t_out.setWordWrap(True)
        bf.addRow(self.t_out)
        for w in (self.t_p1, self.t_p2):
            w.currentIndexChanged.connect(lambda *_: self._try())
        for w in (self.t_plus1, self.t_plus2, self.t_lv1, self.t_lv2):
            w.valueChanged.connect(lambda *_: self._try())
        rv.addWidget(box)
        cb = QGroupBox('Depth (bars = this project, dashed = original tables)')
        cv = QVBoxLayout(cb)
        self.chart = DepthChart()
        cv.addWidget(self.chart)
        rv.addWidget(cb)
        pb = QGroupBox('Problems')
        pv = QVBoxLayout(pb)
        self.problems = QListWidget()
        self.problems.itemDoubleClicked.connect(self._goto_problem)
        pv.addWidget(self.problems)
        rv.addWidget(pb, 1)
        split.addWidget(right)
        split.setSizes([300, 460, 360])
        self.pages.addTab(page, 'By monster')

    def _build_special(self):
        page = QWidget()
        v = QVBoxLayout(page)
        t = QLabel('The game reads these top to bottom; the first that fits the two parents '
                   '(and the egg\'s plus) decides. "Decides" = how many pedigree × mate pairs '
                   'it really decides (0 = it never fires: a recipe above always fits first).')
        t.setWordWrap(True)
        v.addWidget(t)
        row = QHBoxLayout()
        self.sp_filter = QLineEdit()
        self.sp_filter.setPlaceholderText('Filter (a monster or family name)…')
        self.sp_filter.textChanged.connect(self._fill_special)
        row.addWidget(self.sp_filter, 1)
        for label, fn in (('Add…', self._add_special), ('Change…', self._edit_special),
                          ('Remove', self._remove_special)):
            b = QPushButton(label)
            b.clicked.connect(fn)
            row.addWidget(b)
        v.addLayout(row)
        self.sp_table = QTableWidget(0, 8)
        self.sp_table.setHorizontalHeaderLabels(['#', 'Pedigree', 'Mate', 'Needs +', 'Makes',
                                                 'Adds +', 'From', 'Decides'])
        self.sp_table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.sp_table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.sp_table.setSelectionMode(QAbstractItemView.SingleSelection)
        self.sp_table.verticalHeader().setVisible(False)
        self.sp_table.verticalHeader().setDefaultSectionSize(22)
        self.sp_table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeToContents)
        self.sp_table.cellDoubleClicked.connect(lambda *_: self._edit_special())
        v.addWidget(self.sp_table, 1)
        rrow = QHBoxLayout()
        self.removed_lbl = QLabel()
        rrow.addWidget(self.removed_lbl, 1)
        self.removed = QComboBox()
        rrow.addWidget(self.removed)
        b = QPushButton('Bring back')
        b.clicked.connect(self._restore_special)
        rrow.addWidget(b)
        v.addLayout(rrow)
        self.pages.addTab(page, 'Special recipes')

    def _build_family(self):
        page = QWidget()
        v = QVBoxLayout(page)
        t = QLabel('One family recipe per monster: it makes THAT monster, and it is what the '
                   'monster\'s library page shows (the page text follows your change). '
                   '"Works for" = how many of the parent pairs it names really give it (a '
                   'special recipe can win first).')
        t.setWordWrap(True)
        v.addWidget(t)
        row = QHBoxLayout()
        for label, fn in (('Change…', self._edit_family), ('No family recipe', self._clear_family),
                          ('Original recipe', self._orig_family)):
            b = QPushButton(label)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)
        self.fam_table = QTableWidget(0, 5)
        self.fam_table.setHorizontalHeaderLabels(['Monster', 'Pedigree', 'Mate', 'Works for',
                                                  'Changed'])
        self.fam_table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.fam_table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.fam_table.setSelectionMode(QAbstractItemView.SingleSelection)
        self.fam_table.verticalHeader().setVisible(False)
        self.fam_table.verticalHeader().setDefaultSectionSize(22)
        self.fam_table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeToContents)
        self.fam_table.cellDoubleClicked.connect(lambda *_: self._edit_family())
        v.addWidget(self.fam_table, 1)
        self.pages.addTab(page, 'Family recipes')

    # ------------------------------------------------------------ refresh
    def _undo_changed(self, _i):
        if self.isVisible():
            self._timer.start(0)
        else:
            self._stale = True

    def showEvent(self, ev):
        if self._stale:
            self._stale = False
            self.refresh()
        super().showEvent(ev)

    def refresh(self):
        doc = self.s.doc
        self.an = an = doc.breeding_analysis()
        self.van = doc.vanilla_breeding_analysis()
        self.icons = family_icons(doc)
        unr = an.unreachable()
        nf_rows, _ = an.never_fires()
        mx = max((d for d in an.depth.values() if d < 99), default=0)
        table = doc.special_is_table()
        self.summary.setText(
            f'<b>{len(an.roots)}</b> monsters you get without breeding · deepest <b>{mx}</b> · '
            f'<b>{len(unr)}</b> nobody can get · <b>{len(an.br.special)}</b> special recipes'
            f'{" (your whole table)" if table else ""} · <b>{len(nf_rows)}</b> never fire')
        self.b_table.setEnabled(not table)
        self.chart.set_data(an.histogram(), self.van.histogram())
        self._fill_species()
        self._fill_problems()
        self._fill_special()
        self._fill_family()
        self._try()

    def _fam_icon(self, s):
        c = self.an.fast.fam(s)
        return self.icons[c - 0xF0] if c is not None else None

    def _got(self, s):
        an = self.an
        if s in an.roots:
            hows = an.roots[s]
            first = hows[0].split(' (')[0]
            return first + (f' (+{len(hows) - 1})' if len(hows) > 1 else '')
        if an.depth[s] >= B.UNREACHABLE:
            return 'nobody can get it'
        return 'breeding'

    def _fill_species(self, *_):
        an = self.an
        cur = self.current_species()
        q = self.filter.text().strip().lower()
        self.sp_tree.blockSignals(True)
        self.sp_tree.setSortingEnabled(False)
        self.sp_tree.clear()
        pick = None
        for s in an.species:
            nm = an.names.get(s, '?')
            if q and q not in nm.lower() and q != str(s):
                continue
            it = QTreeWidgetItem([f'{s:3d}  {nm}', depth_text(an.depth[s]), self._got(s)])
            ic = self._fam_icon(s)
            if ic is not None:
                it.setIcon(0, ic)
            it.setData(0, Qt.UserRole, s)
            it.setData(1, Qt.UserRole, an.depth[s])
            if an.depth[s] >= B.UNREACHABLE:
                it.setForeground(1, QBrush(QColor(200, 60, 60)))
                it.setForeground(2, QBrush(QColor(200, 60, 60)))
            self.sp_tree.addTopLevelItem(it)
            if s == cur:
                pick = it
        self.sp_tree.setSortingEnabled(True)
        self.sp_tree.blockSignals(False)
        if pick is None and self.sp_tree.topLevelItemCount():
            pick = self.sp_tree.topLevelItem(0)
        if pick is not None:
            self.sp_tree.setCurrentItem(pick)
        self._show_species()

    def current_species(self):
        it = self.sp_tree.currentItem() if hasattr(self, 'sp_tree') else None
        return it.data(0, Qt.UserRole) if it is not None else None

    def select_species(self, s):
        self.filter.setText('')
        for i in range(self.sp_tree.topLevelItemCount()):
            it = self.sp_tree.topLevelItem(i)
            if it.data(0, Qt.UserRole) == s:
                self.sp_tree.setCurrentItem(it)
                self.pages.setCurrentIndex(0)
                return

    def _pairs_text(self, pairs, n=4):
        an = self.an
        out = []
        for a, b, plus in pairs[:n]:
            out.append(f'{an.names.get(a, a)} × {an.names.get(b, b)}'
                       + (f' (+{plus})' if plus else ''))
        more = len(pairs) - n
        return ', '.join(out) + (f' … +{more} more' if more > 0 else '')

    def _show_species(self):
        s = self.current_species()
        an = self.an
        self.made_by.clear()
        self.makes.clear()
        if s is None:
            self.sp_title.setText('')
            return
        nm = an.names.get(s, '?')
        d = an.depth[s]
        if s in an.roots:
            got = 'You get it without breeding: ' + '; '.join(an.roots[s][:4]) + \
                  (' …' if len(an.roots[s]) > 4 else '')
        elif d >= B.UNREACHABLE:
            got = '<span style="color:#c33">Nobody can get it: no recipe makes it from monsters you can get.</span>'
        else:
            (a, b), _info = an.via[s]
            got = f'Shallowest: {an.names.get(a, a)} × {an.names.get(b, b)}'
        self.sp_title.setText(f'<b>{s} {nm}</b> — depth {depth_text(d)}<br>{got}')
        makes = an.makes(s)
        # its family (library) recipe, even when it never decides a pair
        fr = self.s.doc.family_recipe(s) if s <= 214 else None
        if s <= 214:
            if fr is None:
                it = QTreeWidgetItem(['Library recipe: none', '', 'family recipes'])
            else:
                pairs = makes.get(('family', s), [])
                lm = an.library_mismatch().get(s)
                works = (f'{lm[1]} of {lm[0]} pairs' if lm else 'all its pairs')
                it = QTreeWidgetItem([f'Library recipe: {an.name(fr[0])} × {an.name(fr[1])}',
                                      str(len(pairs)), f'family recipes · works for {works}'])
            it.setData(0, Qt.UserRole, ('family', s))
            self.made_by.addTopLevelItem(it)
        rows = self.s.doc.special_rows()
        self._rows = rows
        for r in rows:
            if r['result'] != s:
                continue
            pairs = makes.get(('special', r['row']), [])
            txt = f"#{r['row']}  {an.name(r['p1'])} × {an.name(r['p2'])}"
            if r['min_plus']:
                txt += f"  (needs +{r['min_plus']})"
            it = QTreeWidgetItem([txt, str(len(pairs)),
                                  f"special · {SRC_LABEL[r['src'][0]]}"])
            if not r['decides']:
                it.setForeground(1, QBrush(QColor(200, 60, 60)))
                it.setText(1, '0 — never fires')
            it.setToolTip(0, self._pairs_text(pairs, 12))
            it.setData(0, Qt.UserRole, ('special', r['row']))
            self.made_by.addTopLevelItem(it)
        for res, pairs in sorted(an.breeds_into(s).items(),
                                 key=lambda t: (an.depth.get(t[0], 99), t[0])):
            if res == s:
                continue
            others = sorted({b if a == s else a for a, b, _p in pairs})
            it = QTreeWidgetItem([f'{res:3d}  {an.names.get(res, "?")}',
                                  depth_text(an.depth.get(res, 99)),
                                  ', '.join(an.names.get(o, str(o)) for o in others[:6])
                                  + (' …' if len(others) > 6 else '')])
            it.setData(0, Qt.UserRole, res)
            self.makes.addTopLevelItem(it)
        if not self.made_by.topLevelItemCount():
            self.made_by.addTopLevelItem(QTreeWidgetItem(
                ['No recipe makes it (a new monster can only be made by a special recipe).'
                 if s > 214 else 'No recipe makes it.', '', '']))
        self.b_add.setEnabled(True)

    def _fill_problems(self):
        an = self.an
        self.problems.clear()
        for s in an.unreachable():
            it = QListWidgetItem(f'Nobody can get {an.names.get(s, s)} ({s})')
            it.setData(Qt.UserRole, ('species', s))
            self.problems.addItem(it)
        rows, slots = an.never_fires()
        for i in rows:
            e = an.br.special[i]
            it = QListWidgetItem(f'Special #{i} {an.name(e[0])} × {an.name(e[1])} → '
                                 f'{an.names.get(e[3], e[3])} never fires')
            it.setData(Qt.UserRole, ('row', i))
            self.problems.addItem(it)
        for s, (n, give) in sorted(an.library_mismatch().items()):
            if give == 0:
                it = QListWidgetItem(f'{an.names.get(s, s)}\'s library recipe never gives it')
                it.setData(Qt.UserRole, ('species', s))
                self.problems.addItem(it)
        if not self.problems.count():
            self.problems.addItem('No problems found.')

    def _fill_special(self, *_):
        an = self.an
        rows = self.s.doc.special_rows()
        self._rows = rows
        q = self.sp_filter.text().strip().lower()
        self.sp_table.setRowCount(0)
        shown = []
        for r in rows:
            cells = [str(r['row']), an.name(r['p1']), an.name(r['p2']),
                     str(r['min_plus']) if r['min_plus'] else '',
                     an.names.get(r['result'], str(r['result'])),
                     str(r['plus_mod']) if r['plus_mod'] else '',
                     SRC_LABEL[r['src'][0]], str(r['decides'])]
            if q and not any(q in c.lower() for c in cells[1:5]):
                continue
            shown.append((r, cells))
        self.sp_table.setRowCount(len(shown))
        for k, (r, cells) in enumerate(shown):
            for c, txt in enumerate(cells):
                it = QTableWidgetItem(txt)
                if c == 0:
                    it.setData(Qt.UserRole, r['row'])
                if c == 7 and not r['decides']:
                    it.setForeground(QBrush(QColor(200, 60, 60)))
                if r['src'][0] in ('edited', 'added'):
                    f = it.font()
                    f.setBold(True)
                    it.setFont(f)
                self.sp_table.setItem(k, c, it)
        rem = self.s.doc.removed_special_rows()
        self.removed.clear()
        for n, e in rem:
            self.removed.addItem(f'original #{n}: {an.name(e[0])} × {an.name(e[1])} → '
                                 f'{an.names.get(e[3], e[3])}', n)
        self.removed_lbl.setText(f'{len(rem)} original special recipes removed'
                                 if rem else 'No original special recipe removed.')

    def _fill_family(self):
        an = self.an
        doc = self.s.doc
        lm = an.library_mismatch()
        cur = self.fam_table.currentRow()
        self.fam_table.setRowCount(G.COLLECTIBLE_MAX + 1)
        for s in range(G.COLLECTIBLE_MAX + 1):
            fr = doc.family_recipe(s)
            van = doc.vanilla_family_recipe(s)
            works = '' if fr is None else (f'{lm[s][1]} of {lm[s][0]}' if s in lm else 'all')
            cells = [f'{s:3d}  {an.names.get(s, "?")}', an.name(fr[0]) if fr else '—',
                     an.name(fr[1]) if fr else '', works, '' if fr == van else 'changed']
            for c, txt in enumerate(cells):
                it = QTableWidgetItem(txt)
                if c == 0:
                    it.setData(Qt.UserRole, s)
                if c == 3 and s in lm and lm[s][1] == 0:
                    it.setForeground(QBrush(QColor(200, 60, 60)))
                self.fam_table.setItem(s, c, it)
        if cur >= 0:
            self.fam_table.selectRow(cur)

    def _try(self):
        if not hasattr(self, 'an'):
            return
        an = self.an
        p1, p2 = self.t_p1.value(), self.t_p2.value()
        if p1 is None or p2 is None:
            return
        c = an.br.resolve(p1, p2, self.t_plus1.value(), self.t_plus2.value(),
                          self.t_lv1.value(), self.t_lv2.value())
        if c.how == 'special':
            e = an.br.special[c.index]
            why = (f'special recipe #{c.index}: {an.name(e[0])} × {an.name(e[1])}'
                   + (f' (needs +{e[2]})' if e[2] else ''))
        elif c.how == 'family':
            fr = an.br.family[c.index]
            why = f'{an.names.get(c.index)}\'s family recipe: {an.name(fr[0])} × {an.name(fr[1])}'
        else:
            why = 'no recipe fits — the egg is the pedigree\'s kind'
        self.t_out.setText(f'<b>{an.names.get(c.species, c.species)}</b> +{c.plus}<br>{why}')

    # ------------------------------------------------------------ edits
    def _push(self, label, op):
        cmd = C.SnapshotCommand(self.s, label, op)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            self.refresh()
            return False
        return True

    def _row(self, i):
        return next((r for r in self._rows if r['row'] == i), None)

    def _dialog_special(self, title, r=None, result=None):
        vals = dict(r) if r else {'p1': 0xF0, 'p2': 0xF0, 'min_plus': 0,
                                  'result': result if result is not None else 0, 'plus_mod': 0}
        dlg = RecipeDialog(self, self.an, self.icons, title, vals)
        return dlg.values() if dlg.exec() == QDialog.Accepted else None

    def _add_for_species(self):
        s = self.current_species()
        if s is None:
            return
        v = self._dialog_special(f'New recipe for {self.an.names.get(s)}', result=s)
        if v:
            self._push(f'Recipe for {self.an.names.get(v["result"])}',
                       lambda doc: doc.add_special(v))

    def _edit_made_by(self):
        it = self.made_by.currentItem()
        if it is None or not it.data(0, Qt.UserRole):
            return
        kind, n = it.data(0, Qt.UserRole)
        if kind == 'family':
            self._edit_family_of(n)
        else:
            self._edit_row(n)

    def _remove_made_by(self):
        it = self.made_by.currentItem()
        if it is None or not it.data(0, Qt.UserRole):
            return
        kind, n = it.data(0, Qt.UserRole)
        if kind == 'family':
            self._push(f'No family recipe for {self.an.names.get(n)}',
                       lambda doc: doc.set_family_recipe(n, None, None))
        else:
            self._remove_row(n)

    def _edit_row(self, i):
        r = self._row(i)
        if r is None:
            return
        v = self._dialog_special(f'Special recipe #{i}', r)
        if v:
            src = r['src']
            self._push(f'Special recipe → {self.an.names.get(v["result"])}',
                       lambda doc: doc.set_special(src, v))

    def _remove_row(self, i):
        r = self._row(i)
        if r is None:
            return
        src = r['src']
        self._push(f'Remove special recipe #{i}', lambda doc: doc.remove_special(src))

    def _sel_special(self):
        k = self.sp_table.currentRow()
        it = self.sp_table.item(k, 0) if k >= 0 else None
        return it.data(Qt.UserRole) if it is not None else None

    def _add_special(self):
        v = self._dialog_special('New special recipe')
        if v:
            self._push(f'Recipe for {self.an.names.get(v["result"])}',
                       lambda doc: doc.add_special(v))

    def _edit_special(self):
        i = self._sel_special()
        if i is not None:
            self._edit_row(i)

    def _remove_special(self):
        i = self._sel_special()
        if i is not None:
            self._remove_row(i)

    def _restore_special(self):
        n = self.removed.currentData()
        if n is not None:
            self._push(f'Bring back original special recipe #{n}',
                       lambda doc: doc.restore_special(n))

    def _sel_family(self):
        k = self.fam_table.currentRow()
        it = self.fam_table.item(k, 0) if k >= 0 else None
        return it.data(Qt.UserRole) if it is not None else None

    def _edit_family_of(self, s):
        fr = self.s.doc.family_recipe(s) or self.s.doc.vanilla_family_recipe(s) or (0xF0, 0xF0)
        dlg = RecipeDialog(self, self.an, self.icons,
                           f'Family recipe of {self.an.names.get(s)}',
                           {'p1': fr[0], 'p2': fr[1]}, kind='family')
        if dlg.exec() == QDialog.Accepted:
            v = dlg.values()
            self._push(f'{self.an.names.get(s)}: family recipe',
                       lambda doc: doc.set_family_recipe(s, v['p1'], v['p2']))

    def _edit_family(self):
        s = self._sel_family()
        if s is not None:
            self._edit_family_of(s)

    def _clear_family(self):
        s = self._sel_family()
        if s is not None:
            self._push(f'No family recipe for {self.an.names.get(s)}',
                       lambda doc: doc.set_family_recipe(s, None, None))

    def _orig_family(self):
        s = self._sel_family()
        if s is not None:
            van = self.s.doc.vanilla_family_recipe(s)
            self._push(f'{self.an.names.get(s)}: original family recipe',
                       lambda doc: doc.set_family_recipe(s, *(van or (None, None))))

    def _to_table(self):
        self._push('Special recipes: work on the whole table',
                   lambda doc: doc.special_to_table())

    def _to_vanilla(self):
        if QMessageBox.question(self, 'Original special recipes',
                                'Throw away every change to the special recipes?') \
                != QMessageBox.Yes:
            return
        self._push('Special recipes: original', lambda doc: doc.special_to_vanilla())

    def _generate(self):
        dlg = GenerateDialog(self, self.s, self.an)
        if dlg.exec() == QDialog.Accepted and dlg.gd is not None:
            gd = dlg.gd
            self._push('Generated breeding tree', lambda doc: doc.apply_breeding(gd))

    # ------------------------------------------------------------ navigation
    def _goto_item(self, it, _col=0):
        s = it.data(0, Qt.UserRole)
        if isinstance(s, int):
            self.select_species(s)

    def _goto_problem(self, it):
        d = it.data(Qt.UserRole)
        if not d:
            return
        kind, n = d
        if kind == 'species':
            self.select_species(n)
        else:
            self.pages.setCurrentIndex(1)
            self.sp_filter.setText('')
            for k in range(self.sp_table.rowCount()):
                if self.sp_table.item(k, 0).data(Qt.UserRole) == n:
                    self.sp_table.selectRow(k)
                    self.sp_table.scrollToItem(self.sp_table.item(k, 0))
                    break
