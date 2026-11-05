"""cross_page.py — the Breeding tab's "Try a cross" page (S169; EDITOR_DESIGN §5.4
"As built S169"; help 30_breeding.md "Try a cross: the baby").

Two parents — a TYPICAL monster of a kind at a level and plus, or a monster of a
battery save (.sav) — and what the game makes of them: the egg (which recipe decided,
its plus), and the baby: max level, the six stats worked out the game's way, the AI
weights, gender and resistance chances, its LEARN QUEUE (what it can pick up as it
grows, where each skill came from, what was not passed on) and the TIMELINE (the level
it learns each skill at). The answers are editor2/core/cross.py's — the S130 raising
model, == the game's routines (tools/census_raising.py; on a real save,
tools/walk_cross.py).
"""

import os

from PySide6.QtCore import QSettings, Qt
from PySide6.QtGui import QBrush, QColor, QPixmap
from PySide6.QtWidgets import (QComboBox, QFileDialog, QGridLayout, QGroupBox,
                               QHBoxLayout, QHeaderView, QLabel, QMessageBox,
                               QPushButton, QSpinBox, QSplitter, QTableWidget,
                               QTableWidgetItem, QTreeWidget, QTreeWidgetItem,
                               QVBoxLayout, QWidget)

from editor2.app import sprite_qt as Q
from editor2.core import cross as X
from editor2.core import gamedata as G

INTRO = ('What the game makes of two monsters — a <b>typical</b> one of a kind or one from '
         '<b>your save</b>. The baby knows nothing: it carries a <b>learn queue</b> (its own '
         'kind\'s 3 skills, both parents\' kinds\' 3, then every skill the parents knew, each '
         'back to the first skill of its chain; 25 at most) and learns them as it grows. '
         'Every number is the game\'s own rule (help: Breeding → Try a cross).')

GREY = QColor(140, 140, 140)
RED = QColor(200, 60, 60)
ORANGE = QColor(200, 120, 20)
HOW_WORDS = {'queue': 'from its learn queue', 'upgrade': 'replaces {old}',
             'combination': 'combination (it knows every skill it needs)'}


def _item(text, tip=None, color=None):
    it = QTableWidgetItem(str(text))
    it.setFlags(it.flags() & ~Qt.ItemIsEditable)
    if tip:
        it.setToolTip(tip)
    if color is not None:
        it.setForeground(QBrush(color))
    return it


RES_SHOWN = 6                         # resistances listed; the rest in the tooltip
PIC_SCALE = 2                         # a 48 x 48 battle pose -> 96 x 96
PIC_BG = '#F8F8D8'                    # the battle screen's cream


class MonPic(QWidget):
    """S169 r2 (user: "can you have a picture of the resulting monster (egg) displayed? … Also
    show the two parents … if I modified monster graphics it should reflect that"): a monster's
    BATTLE POSE as the project draws it (`sprite_qt.species_art`: the project's own art for an
    original monster — `gamedata.art`, new streams and / or colours —, a new species' art, else
    the original game's) with a role line above and its name below."""

    def __init__(self, role, parent=None):
        super().__init__(parent)
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        v.setSpacing(2)
        self.role = QLabel(f'<span style="color:#888">{role}</span>')
        self.role.setAlignment(Qt.AlignHCenter)
        v.addWidget(self.role)
        self.pic = QLabel()
        self.pic.setFixedSize(48 * PIC_SCALE + 8, 48 * PIC_SCALE + 8)
        self.pic.setAlignment(Qt.AlignCenter)
        self.pic.setStyleSheet(f'background: {PIC_BG}; border: 1px solid #b8b098; '
                               'border-radius: 4px; color: #888;')
        v.addWidget(self.pic, 0, Qt.AlignHCenter)
        self.cap = QLabel()
        self.cap.setAlignment(Qt.AlignHCenter)
        self.cap.setFixedWidth(48 * PIC_SCALE + 40)
        v.addWidget(self.cap, 0, Qt.AlignHCenter)
        v.addStretch(1)                              # pictures on one line, captions top-aligned
        self.sid = None
        self.cap.setText('x<br>x<br>x')              # three lines: nickname, name, level
        self.setFixedHeight(self.sizeHint().height())

    def show_monster(self, rows, sid, caption, tip=''):
        self.sid = sid
        if rows:
            self.pic.setPixmap(Q.pixmap(rows, PIC_SCALE))
        else:
            self.pic.setPixmap(QPixmap())
            self.pic.setText('no picture')
        self.cap.setText(caption)
        self.setToolTip(tip)


class ParentRow:
    """One parent's controls: which one (typical / a save monster), kind, plus, level."""

    def __init__(self, page, grid, row, label, names, species, icons):
        from editor2.app.breeding_tab import MatcherCombo
        self.page = page
        grid.addWidget(QLabel(f'<b>{label}</b>'), row, 0)
        self.which = QComboBox()
        self.which.setToolTip('A typical monster of the kind below, or one of the monsters '
                              'of the save you loaded (its own stats, skills, plus, level and '
                              'pedigree names)')
        self.which.addItem('a typical one', None)
        grid.addWidget(self.which, row, 1)
        self.kind = MatcherCombo(names, species, icons, families=False)
        grid.addWidget(self.kind, row, 2)
        grid.addWidget(QLabel('+'), row, 3)
        self.plus = QSpinBox()
        self.plus.setRange(0, 99)
        grid.addWidget(self.plus, row, 4)
        grid.addWidget(QLabel('Lv'), row, 5)
        self.level = QSpinBox()
        self.level.setRange(1, 99)
        self.level.setValue(10)
        grid.addWidget(self.level, row, 6)
        self.which.currentIndexChanged.connect(self._which_changed)
        self.kind.currentIndexChanged.connect(lambda *_: page.update_baby())
        self.plus.valueChanged.connect(lambda *_: page.update_baby())
        self.level.valueChanged.connect(lambda *_: page.update_baby())

    def slot(self):
        return self.which.currentData()

    def set_save_monsters(self, items):
        keep = self.slot()
        self.which.blockSignals(True)
        self.which.clear()
        self.which.addItem('a typical one', None)
        for slot, text in items:
            self.which.addItem(text, slot)
        i = self.which.findData(keep) if keep is not None else 0
        self.which.setCurrentIndex(max(0, i))
        self.which.blockSignals(False)
        self._which_changed()

    def _which_changed(self, *_):
        slot = self.slot()
        m = self.page.save_monster(slot) if slot is not None else None
        for w in (self.kind, self.plus, self.level):
            w.blockSignals(True)
        if m is not None:
            self.kind.set_value(m.species)
            self.plus.setValue(m.plus)
            self.level.setValue(m.level)
        for w in (self.kind, self.plus, self.level):
            w.setEnabled(m is None)
            w.blockSignals(False)
        self.page.update_baby()


class CrossPage(QWidget):
    def __init__(self, session, an, icons, parent=None):
        super().__init__(parent)
        self.s = session
        self._T = None
        self._T_key = None
        self.sav = None
        self.sav_path = None
        self.roster = {}
        self._k_auto = True
        self.result = None
        split = QSplitter(Qt.Horizontal)
        outer = QVBoxLayout(self)
        intro = QLabel(INTRO)
        intro.setWordWrap(True)
        outer.addWidget(intro)
        outer.addWidget(split, 1)

        # ---------------------------------------------------------------- left
        left = QWidget()
        lv = QVBoxLayout(left)
        lv.setContentsMargins(0, 0, 0, 0)
        pg = QGroupBox('The parents')
        grid = QGridLayout(pg)
        self.p1 = ParentRow(self, grid, 0, 'Pedigree', an.names, an.species, icons)
        self.p2 = ParentRow(self, grid, 1, 'Mate', an.names, an.species, icons)
        grid.setColumnStretch(1, 3)
        grid.setColumnStretch(2, 2)
        row = QHBoxLayout()
        self.b_sav = QPushButton('Monsters from a save (.sav)…')
        self.b_sav.setToolTip('Load a battery save of this project\'s ROM: its party and farm '
                              'monsters can then be picked as parents')
        self.b_sav.clicked.connect(self._load_dialog)
        row.addWidget(self.b_sav)
        self.sav_lbl = QLabel('no save loaded')
        self.sav_lbl.setWordWrap(True)
        row.addWidget(self.sav_lbl, 1)
        grid.addLayout(row, 2, 0, 1, 7)
        krow = QHBoxLayout()
        krow.addWidget(QLabel('Pedigree names that are not yours'))
        self.k = QSpinBox()
        self.k.setRange(0, 6)
        self.k.setToolTip(
            'The game adds 2 % to every stat of the baby for each of the six pedigree names '
            '(each parent\'s master, and the two parents of a parent that was bred) that is '
            'not your name. A bred parent keeps its parents\' NICKNAMES there, so it usually '
            'counts 2. Set from the parents you pick; change it to try other cases.')
        self.k.valueChanged.connect(self._k_changed)
        krow.addWidget(self.k)
        self.k_lbl = QLabel('')
        krow.addWidget(self.k_lbl, 1)
        grid.addLayout(krow, 3, 0, 1, 7)
        lv.addWidget(pg)
        pics = QHBoxLayout()
        self.pic1 = MonPic('Pedigree')
        self.pic2 = MonPic('Mate')
        self.pic_baby = MonPic('The egg')
        for w_, sign in ((self.pic1, '×'), (self.pic2, '→'), (self.pic_baby, None)):
            pics.addWidget(w_)
            if sign:
                lab = QLabel(f'<span style="font-size:20pt; color:#888">{sign}</span>')
                lab.setAlignment(Qt.AlignCenter)
                pics.addWidget(lab)
        pics.addStretch(1)
        lv.addLayout(pics)
        self._art_cache = {}
        self._art_rev = None
        self.egg = QLabel()
        self.egg.setWordWrap(True)
        self.egg.setTextInteractionFlags(Qt.TextSelectableByMouse)
        lv.addWidget(self.egg)
        self.summary = QLabel()               # S169 r2: the baby's line under the egg's
        self.summary.setWordWrap(True)
        lv.addWidget(self.summary)
        self.parents_lbl = QLabel()
        self.parents_lbl.setWordWrap(True)
        self.parents_lbl.setTextInteractionFlags(Qt.TextSelectableByMouse)
        lv.addWidget(self.parents_lbl)
        bg = QGroupBox('Resistances')
        bl = QVBoxLayout(bg)
        self.res_lbl = QLabel()
        self.res_lbl.setWordWrap(True)
        bl.addWidget(self.res_lbl)
        lv.addStretch(1)
        split.addWidget(left)
        # a wrapped label's height is not part of a layout's minimum (it is height-for-width):
        # claim the lines each one can need, so a column never squeezes it into the next
        line = self.fontMetrics().lineSpacing()
        for lab, n in ((self.egg, 2), (self.summary, 2), (self.parents_lbl, 4), (self.res_lbl, 4)):
            lab.setMinimumHeight(n * line + 4)

        # -------------------------------------------------------------- middle
        mid = QWidget()
        bv = QVBoxLayout(mid)
        bv.setContentsMargins(0, 0, 0, 0)
        bv.addWidget(QLabel('<b>Stats at birth</b>'))
        self.stats = QTableWidget(6, 5)
        self.stats.setHorizontalHeaderLabels(['Stat', 'Pedigree', 'Mate', 'Both ÷ 4', 'Baby'])
        self.stats.verticalHeader().setVisible(False)
        self.stats.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.stats.verticalHeader().setDefaultSectionSize(22)
        self.stats.setFixedHeight(6 * 22 + 28)
        bv.addWidget(self.stats)
        bv.addWidget(QLabel('<b>AI weights</b>'))
        self.ai = QTableWidget(4, 5)
        self.ai.setHorizontalHeaderLabels(['Weight', 'Pedigree', 'Mate', 'Baby', ''])
        self.ai.verticalHeader().setVisible(False)
        self.ai.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        for col in (0, 4):
            self.ai.horizontalHeader().setSectionResizeMode(col, QHeaderView.ResizeToContents)
        self.ai.verticalHeader().setDefaultSectionSize(22)
        self.ai.setFixedHeight(4 * 22 + 28)
        bv.addWidget(self.ai)
        bv.addWidget(bg)                 # S169 r2: under the tables (the pictures took its room)
        bv.addStretch(1)
        split.addWidget(mid)

        # --------------------------------------------------------------- right
        right = QWidget()
        rv = QVBoxLayout(right)
        rv.setContentsMargins(0, 0, 0, 0)
        rv.addWidget(QLabel('<b>Learn queue</b> — what the baby can pick up, in the order '
                            'the game keeps it'))
        self.queue = QTreeWidget()
        self.queue.setHeaderLabels(['#', 'Skill', 'From', 'Learns it at'])
        self.queue.setRootIsDecorated(True)
        self.queue.setColumnWidth(0, 40)
        self.queue.setColumnWidth(1, 120)
        self.queue.setColumnWidth(2, 220)
        rv.addWidget(self.queue, 3)
        rv.addWidget(QLabel('<b>As it grows</b> — every skill the game offers it, level by '
                            'level, up to its max level'))
        self.tl = QTreeWidget()
        self.tl.setHeaderLabels(['Level', 'Skill', 'How', 'Knows'])
        self.tl.setRootIsDecorated(False)
        self.tl.setColumnWidth(0, 50)
        self.tl.setColumnWidth(1, 120)
        self.tl.setColumnWidth(2, 260)
        rv.addWidget(self.tl, 2)
        self.tl_note = QLabel()
        self.tl_note.setWordWrap(True)
        rv.addWidget(self.tl_note)
        split.addWidget(right)
        split.setSizes([540, 380, 520])
        self._restore_sav()

    # ------------------------------------------------------------------ data
    def tables(self):
        doc = self.s.doc
        key = (getattr(doc, 'revision', 0), id(doc.data))
        if self._T is None or self._T_key != key:
            self._T = X.tables(doc.model_project())
            self._T_key = key
        return self._T

    def save_monster(self, slot):
        return self.roster.get(slot)

    def _restore_sav(self):
        path = QSettings('dwm1_disassembly', 'DWM1Editor').value('breeding/sav')
        if path and os.path.exists(path):
            try:
                self.load_sav(path)
            except Exception:                                   # noqa: BLE001
                pass

    def _load_dialog(self):
        path, _f = QFileDialog.getOpenFileName(self, 'Monsters from a save', self.sav_path or '',
                                               'Battery saves (*.sav *.srm);;All files (*)')
        if not path:
            return
        err = self.load_sav(path)
        if err:
            QMessageBox.warning(self, 'Monsters from a save', err)

    def load_sav(self, path):
        """Read the party + farm of a battery save -> None, or the problem."""
        from editor2.core import savefile as SF
        try:
            data = open(path, 'rb').read()
            T = self.tables()
            ro = SF.read_roster(data, T.names)
        except Exception as e:                                  # noqa: BLE001
            return f'Could not read {os.path.basename(path)}: {e}'
        if not ro['monsters']:
            return f'{os.path.basename(path)} has no monsters.'
        self.sav, self.sav_path, self.roster = data, path, ro['monsters']
        QSettings('dwm1_disassembly', 'DWM1Editor').setValue('breeding/sav', path)
        items = []
        for slot in sorted(self.roster):
            m = self.roster[slot]
            where = 'party' if slot in ro['party'] else 'farm'
            nick = f'{m.nickname} ' if m.nickname else ''
            items.append((slot, f'{nick}({m.name}) Lv {m.level} +{m.plus} — {where}'))
        self.sav_lbl.setText(f'{os.path.basename(path)}: {len(items)} monsters')
        for pr in (self.p1, self.p2):
            pr.set_save_monsters(items)
        return None

    def set_parents(self, s1, s2, plus1, plus2, lv1, lv2):
        """From the By monster page's small box: typical parents of these kinds."""
        for pr, sp, pl, lv in ((self.p1, s1, plus1, lv1), (self.p2, s2, plus2, lv2)):
            for w in (pr.which, pr.kind, pr.plus, pr.level):
                w.blockSignals(True)
            pr.which.setCurrentIndex(0)
            pr.kind.set_value(sp)
            pr.plus.setValue(pl)
            pr.level.setValue(lv)
            for w in (pr.kind, pr.plus, pr.level):
                w.setEnabled(True)
            for w in (pr.which, pr.kind, pr.plus, pr.level):
                w.blockSignals(False)
        self._k_auto = True
        self.update_baby()

    def battle_rows(self, sid):
        """The battle pose of species `sid` as this project draws it (cached per document
        revision: an art or colour edit shows at once)."""
        doc = self.s.doc
        rev = (getattr(doc, 'revision', 0), id(doc.data))
        if rev != self._art_rev:
            self._art_cache = {}
            self._art_rev = rev
        if sid not in self._art_cache:
            try:
                rows, _fol = Q.species_art(doc, sid)
            except Exception:                                   # noqa: BLE001
                rows = None
            self._art_cache[sid] = rows
        return self._art_cache[sid]

    def _parent(self, pr):
        T = self.tables()
        slot = pr.slot()
        if slot is not None and slot in self.roster:
            m = self.roster[slot].copy()
            rec = X.save_record(self.sav, slot)
            k = X.names_not_yours(rec, X.player_name(self.sav))
            nick = f'“{m.nickname}” ' if m.nickname else ''
            return m, f'{nick}from your save (slot {slot})', k
        sp = pr.kind.value()
        if sp is None:
            return None, '', 0
        m, how = X.typical_parent(T, sp, pr.level.value(), pr.plus.value())
        return m, 'typical: ' + how, 0

    def _k_changed(self, *_):
        if not getattr(self, '_k_setting', False):
            self._k_auto = False
            self.update_baby(keep_k=True)

    # ---------------------------------------------------------------- update
    def update_baby(self, keep_k=False):
        if not hasattr(self, 'tl'):
            return
        try:
            T = self.tables()
        except Exception as e:                                  # noqa: BLE001
            self.egg.setText(f'<span style="color:#c33">The project does not compile: {e}</span>')
            return
        p1, how1, k1 = self._parent(self.p1)
        p2, how2, k2 = self._parent(self.p2)
        if p1 is None or p2 is None:
            return
        if not keep_k:
            self._k_auto = True
        if self._k_auto:
            self._k_setting = True
            self.k.setValue(k1 + k2)
            self._k_setting = False
        k = self.k.value()
        self.k_lbl.setText(f'→ +{2 * k} % to every stat' + ('' if self._k_auto else ' (set by hand)'))
        an = self.s.doc.breeding_analysis()
        c = an.br.resolve(p1.species, p2.species, p1.plus, p2.plus, p1.level, p2.level)
        if c.how == 'special':
            e = an.br.special[c.index]
            why = (f'special recipe #{c.index}: {an.name(e[0])} × {an.name(e[1])}'
                   + (f' (needs +{e[2]})' if e[2] else ''))
        elif c.how == 'family':
            fr = an.br.family[c.index]
            why = f'{an.names.get(c.index)}\'s family recipe: {an.name(fr[0])} × {an.name(fr[1])}'
        else:
            why = 'no recipe fits — the egg is the pedigree\'s kind'
        b = X.baby(T, p1, p2, c.species, c.plus, k)
        self.result = b
        nm = T.names.get(c.species, f'#{c.species}')
        self.egg.setText(f'<b>Egg: {nm} +{c.plus}</b> — {why}')

        def known(m):
            return ', '.join(X.skill_name(T, s) for s in m.skills) or 'nothing'

        def sex(m, slot):
            return (' ♀' if m.female & 1 else ' ♂') if slot is not None else ''
        for pic, m, pr in ((self.pic1, p1, self.p1), (self.pic2, p2, self.p2)):
            nick = f'“{m.nickname}”<br>' if pr.slot() is not None and m.nickname else ''
            pic.show_monster(self.battle_rows(m.species), m.species,
                             f'{nick}<b>{m.name}</b>{sex(m, pr.slot())}<br>Lv {m.level} +{m.plus}',
                             f'{m.name} knows: {known(m)}')
        self.pic_baby.show_monster(self.battle_rows(c.species), c.species,
                                   f'<b>{nm}</b> +{c.plus}<br>max Lv {b["cap"]}', why)
        self.parents_lbl.setText(
            f'<b>Pedigree</b> {p1.name} Lv {p1.level} +{p1.plus} ({how1}) knows: {known(p1)}<br>'
            f'<b>Mate</b> {p2.name} Lv {p2.level} +{p2.plus} ({how2}) knows: {known(p2)}')
        self._fill_baby(T, b, p1, p2)
        self._fill_queue(T, b)
        self._fill_timeline(T, b)

    def _fill_baby(self, T, b, p1, p2):
        fem = b['female']
        g = ('always male' if fem == 0 else 'always female' if fem == 1
             else f'{round(100 * fem)} % female')
        self.summary.setText(
            f'<b>The baby</b>: level 1 · <b>max level {b["cap"]}</b> (its kind\'s {b["info_cap"]} + 2 × plus '
            f'{b["plus"]}, at most 99) · {g} · knows nothing')
        tip = ('Each stat = (pedigree + mate) ÷ 4, then + 2 % for each pedigree name that is '
               'not yours (the game rounds down)')
        for i, (name, a, bb, s, v) in enumerate(b['stats']):
            for col, val in enumerate((name, a, bb, s, v)):
                self.stats.setItem(i, col, _item(val, tip))
        for i, (name, a, bb, v, wrapped) in enumerate(b['ai']):
            note = ('wraps (game bug)' if wrapped else 'average')
            for col, val in enumerate((name, a, bb, v, note)):
                self.ai.setItem(i, col, _item(
                    val, 'The AI weights are the parents\' average — but the original code '
                         'drops the carry of the sum, so when the two add up past 255 the '
                         'baby gets ((sum − 256) ÷ 2): two 200s give 72, not 200.',
                    RED if wrapped and col == 4 else None))
        rises = b['resist_rises']
        if rises:
            parts = []
            for i, own, up, _dist in sorted(rises, key=lambda r: -r[2]):
                parts.append(f'{G.RESIST_NAMES[i]} {own}→{own + 1}: {self._pct(up)}')
            shown = parts[:RES_SHOWN]
            more = (f' … and {len(parts) - RES_SHOWN} more (hover)' if len(parts) > RES_SHOWN
                    else '')
            self.res_lbl.setText('Its kind\'s own; with a chance one higher: '
                                 + ', '.join(shown) + more)
            self.res_lbl.setToolTip('Can come out one level higher (the plus and the parents\' '
                                    'own levels decide the chance):\n' + '\n'.join(parts))
        else:
            self.res_lbl.setText('Exactly its kind\'s own (no chance to '
                                 'rise with these parents and this plus).')
            self.res_lbl.setToolTip('')

    @staticmethod
    def _pct(x):
        if x >= 0.995:
            return 'always'
        return f'{x * 100:.0f} %' if x >= 0.01 else f'{x * 100:.1f} %'

    def _fill_queue(self, T, b):
        self.queue.clear()
        at = b['learned_at']
        for n, sid in enumerate(b['queue'], 1):
            src, orig = b['queue_src'].get(sid, ('', sid))
            frm = (f'{src} {X.skill_name(T, orig)}' if src in (X.SRC_P1_KNEW, X.SRC_P2_KNEW)
                   else src)
            lv = at.get(sid)
            it = QTreeWidgetItem([str(n), X.skill_name(T, sid), frm,
                                  f'Lv {lv}' if lv else f'not by Lv {b["cap"]}'])
            if not lv:
                it.setForeground(3, QBrush(ORANGE))
                it.setToolTip(3, 'Its level or stats never reach what this skill needs before '
                                 'its max level (the Skills tab shows each skill\'s needs)')
            self.queue.addTopLevelItem(it)
        lost = [r for r in b['sources'] if r[3] in (X.ST_NEVER, X.ST_CUT)]
        if lost:
            top = QTreeWidgetItem(['', f'Not passed on ({len(lost)})', '', ''])
            top.setForeground(1, QBrush(GREY))
            for src, s, base, st in lost:
                why = ('the game never passes this skill on' if st == X.ST_NEVER
                       else 'the queue already holds 25')
                ch = QTreeWidgetItem(['', X.skill_name(T, s), f'{src} {X.skill_name(T, s)}', why])
                for col in range(4):
                    ch.setForeground(col, QBrush(GREY))
                top.addChild(ch)
            self.queue.addTopLevelItem(top)
            top.setExpanded(True)

    def _fill_timeline(self, T, b):
        self.tl.clear()
        knows = 0
        first_full = None
        for lv, sid, how, old in b['timeline']:
            if how != 'upgrade':
                knows += 1
            words = HOW_WORDS[how].format(old=X.skill_name(T, old) if old is not None else '')
            it = QTreeWidgetItem([str(lv), X.skill_name(T, sid), words, str(knows)])
            if knows > 8:
                it.setForeground(3, QBrush(ORANGE))
                it.setToolTip(3, 'A 9th skill: the game asks which one to forget')
                if first_full is None:
                    first_full = lv
            self.tl.addTopLevelItem(it)
        grown = b['grown']
        st = ' · '.join(f'{n} {v}' for n, v in zip(X.STAT_NAMES, grown.stats))
        note = (f'At its max level {grown.level}: {st} (a typical run — HP and ATK get '
                f'random bonuses from level 14 when it has a plus).')
        if first_full is not None:
            note += (f' From level {first_full} it is offered a 9th skill: the game then asks '
                     'which one to forget — the list goes on as if you never forgot one.')
        if not b['timeline']:
            note = 'It learns nothing on the way to its max level. ' + note
        self.tl_note.setText(note)
