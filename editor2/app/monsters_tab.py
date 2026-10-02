"""monsters_tab.py — the Monsters tab (ROADMAP P3.10 part 1, S106; EDITOR_DESIGN §5.2;
model: editor2/core/monsters.py).

Left: every species — your new species first (with the 19-slot, name-space
and art-space meters and "New species from a sprite sheet…"), then the 215
original monsters and the 6 combat-only entries — each with its walking
sprite. Right: the selected species' battle pose and walking preview, then
three pages:

  Species       family, level cap, exp curve, female ratio, flying, metal,
                tier, its 3 natural skills, its 6 growth curves (with a chart)
                and its 27 resistances — the 43-byte info row.
  Where you meet it
                every ENEMY ROW of this species (wild pools, bosses, arena,
                the starter, your own enemies): level, stats, exp, joining,
                AI weights, battle skills. A monster that joins takes its
                stats and AI from the row it joined from.
  Name & art    (new species) name, nickname, description, walking palette,
                battle colours, re-cut the art from a sheet, remove.
                (original monsters 0-214, S107) new art from a sprite sheet,
                battle colours, walking palette, back to the original —
                gamedata.art. TERRY? and the summons (215-220) have no art
                page: they are not monsters (PROJECT_STATE Iron Rule 8).
                (S108, part 3) the name, default nickname and library
                description of the originals (gamedata.monster_text) and a
                new species' own description, each previewed in the game's
                font; "Texts that name it…" opens the Dialogue tab.

Every edit is one undo step (SnapshotCommand); the model validates with the
compiler's own code, so the GUI can never save what the build would refuse.
"""

import os

from PySide6.QtCore import QSize, Qt, Signal
from PySide6.QtGui import QColor, QFont, QIcon, QPainter, QPen, QPixmap
from PySide6.QtWidgets import (QAbstractItemView, QCheckBox, QColorDialog,
                               QComboBox, QFormLayout, QGridLayout, QGroupBox,
                               QHBoxLayout, QHeaderView, QInputDialog, QLabel,
                               QLineEdit, QListWidget, QListWidgetItem,
                               QMessageBox, QProgressBar, QPushButton,
                               QScrollArea, QSpinBox, QSplitter, QTableWidget,
                               QTableWidgetItem, QTabWidget, QVBoxLayout,
                               QWidget)

from editor2.app import sprite_qt as Q
from editor2.app.rooms import commands as C
from editor2.app.rooms.inspector import narrow_combo
from editor2.core import gamedata as G
from editor2.core import monsters as M
from editor2.core import sheet_import as S
from editor2.core import species as SP

HELP_SPECIES = ('A species is what every monster of that kind shares: family, how '
                'it grows, what it resists, the three skills it learns by itself. Its '
                'fighting STATS are not here — they belong to each enemy row '
                '(“Where you meet it”).')
HELP_WHERE = ('Every enemy row of this species. A wild monster, a boss or an arena '
              'fighter is a row: its level, stats, exp reward, battle skills and AI '
              'weights. A monster that JOINS you takes its stats and AI from the row it '
              'joined from (each stat rolled to 80-100 %). Double-click a number to change '
              'it. Joins: 0 = always, 7 = never, anything else = a chance.')
TIER_HELP = '0 = starter, 3-6 = normal, 7 = endgame boss (the original game)'


def _skill_names():
    from editor2.core.conversation import skill_names
    out = dict(skill_names())
    for k, v in M.CUSTOM_SKILL_NAMES.items():
        out.setdefault(k, v)
    return out


class CurveChart(QWidget):
    """The six stats of one species at every level (cumulative growth)."""

    COLORS = [QColor(220, 60, 60), QColor(60, 90, 220), QColor(230, 140, 0),
              QColor(40, 160, 70), QColor(150, 60, 200), QColor(30, 160, 170)]

    def __init__(self, parent=None):
        super().__init__(parent)
        self.series = []
        self.setMinimumHeight(150)

    def set_series(self, series):
        self.series = series            # [(label, [99 cumulative])]
        self.update()

    def paintEvent(self, _ev):
        p = QPainter(self)
        p.fillRect(self.rect(), QColor(250, 250, 246))
        if not self.series:
            return
        top = max(1, max(max(s) for _l, s in self.series))
        w, h = self.width() - 46, self.height() - 22
        p.setPen(QColor(170, 170, 170))
        p.drawText(2, 12, f'{top}')
        p.drawText(2, h + 4, '0')
        p.drawText(40, h + 18, 'level 1')
        p.drawText(w - 10, h + 18, '99')
        for k, (label, s) in enumerate(self.series):
            pen = QPen(self.COLORS[k % 6])
            pen.setWidth(2)
            p.setPen(pen)
            pts = [(40 + i * w / 98.0, 6 + h - 6 - v * (h - 6) / top) for i, v in enumerate(s)]
            for a, b in zip(pts, pts[1:]):
                p.drawLine(int(a[0]), int(a[1]), int(b[0]), int(b[1]))
            p.drawText(int(pts[-1][0]) - 28, int(pts[-1][1]) - 2, label)


def _rom():
    p = os.path.join(M.REPO, 'data', 'DWM-original.gbc')
    try:
        return open(p, 'rb').read()
    except OSError:
        return b''


def text_pixmap(rom, rows, width, scale=2):
    """The game's font on cream: rows = [glyph codes]; cells past `width` red
    (the library page / name fields cut them)."""
    from editor2.app.rooms import talk_editor as TE
    from editor2.core import textenc as T
    from PySide6.QtGui import QImage
    n = max([width] + [len(r) for r in rows])
    img = QImage(8 * (n + 1), 8 * max(1, len(rows)) + 2, QImage.Format_RGB32)
    img.fill(TE.PAL[1])
    for ty, codes in enumerate(rows):
        for k, c in enumerate(codes):
            g = T.glyph_2bpp(rom, c) if rom else b''
            if len(g) == 16:
                TE._blit(img, g, k, ty, TE.OVER if k >= width else None)
    pm = QPixmap.fromImage(img)
    return pm.scaled(pm.width() * scale, pm.height() * scale)


class MonstersTab(QWidget):
    openEnemies = Signal()
    showDialogue = Signal(int)          # S108: "Texts that name it…" (main opens the Dialogue tab)

    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.sid = 0
        self._busy = False
        self._model = None
        self.skills = _skill_names()
        root = QHBoxLayout(self)
        split = QSplitter()
        root.addWidget(split)

        # ---- left: species list ----
        left = QWidget()
        lv = QVBoxLayout(left)
        self.filter = QLineEdit()
        self.filter.setPlaceholderText('Find a monster (name or number)')
        self.filter.textChanged.connect(self._filter)
        lv.addWidget(self.filter)
        self.list = QListWidget()
        self.list.setIconSize(QSize(32, 32))
        self.list.currentItemChanged.connect(self._picked)
        lv.addWidget(self.list, 1)
        nb = QPushButton('New species from a sprite sheet…')
        nb.clicked.connect(self._new_species)
        lv.addWidget(nb)
        self.meters = QLabel()
        self.meters.setWordWrap(True)
        lv.addWidget(self.meters)
        split.addWidget(left)

        # ---- right ----
        right = QWidget()
        rv = QVBoxLayout(right)
        head = QHBoxLayout()
        self.battle = Q.BattleView(scale=2)
        head.addWidget(self.battle)
        hv = QVBoxLayout()
        self.title = QLabel()
        f = self.title.font()
        f.setPointSize(f.pointSize() + 4)
        f.setBold(True)
        self.title.setFont(f)
        hv.addWidget(self.title)
        self.subtitle = QLabel()
        self.subtitle.setWordWrap(True)
        hv.addWidget(self.subtitle)
        self.walk = Q.WalkPreview(scale=2)
        hv.addWidget(self.walk)
        hv.addStretch(1)
        head.addLayout(hv, 1)
        rv.addLayout(head)
        self.pages = QTabWidget()
        rv.addWidget(self.pages, 1)
        self.pages.addTab(self._species_page(), 'Species')
        self.pages.addTab(self._where_page(), 'Where you meet it')
        self.art_page = self._art_page()
        self.pages.addTab(self.art_page, 'Name && art')
        split.addWidget(right)
        split.setSizes([300, 1100])

        self._stale = False
        self.s.undo.indexChanged.connect(self._undo_changed)
        self.refresh()

    # ================================================================ pages
    def _species_page(self):
        w = QWidget()
        outer = QVBoxLayout(w)
        h = QLabel(HELP_SPECIES)
        h.setWordWrap(True)
        outer.addWidget(h)
        sa = QScrollArea()
        sa.setWidgetResizable(True)
        inner = QWidget()
        sa.setWidget(inner)
        outer.addWidget(sa, 1)
        v = QVBoxLayout(inner)
        top = QHBoxLayout()
        basics = QGroupBox('Basics')
        f = QFormLayout(basics)
        self.w_family = QComboBox()
        for fam in G.DISPLAY_ORDER:
            self.w_family.addItem('??? (Boss)' if G.FAMILY_NAMES[fam] == 'Boss'
                                  else G.FAMILY_NAMES[fam], fam)
        self.w_family.activated.connect(lambda _i: self._set('family', self.w_family.currentData()))
        f.addRow('Family', self.w_family)
        self.w_cap = QSpinBox()
        self.w_cap.setRange(1, 99)
        self.w_cap.editingFinished.connect(lambda: self._set('level_cap', self.w_cap.value()))
        f.addRow('Level cap', self.w_cap)
        self.w_exp = QComboBox()
        narrow_combo(self.w_exp, 22)
        self.w_exp.activated.connect(lambda _i: self._set('exp_table', self.w_exp.currentData()))
        f.addRow('Exp curve', self.w_exp)
        self.w_exp_note = QLabel()
        self.w_exp_note.setWordWrap(True)
        f.addRow('', self.w_exp_note)
        self.w_female = QComboBox()
        for i, t in enumerate(M.FEMALE_LABELS):
            self.w_female.addItem(t, i)
        self.w_female.activated.connect(lambda _i: self._set('female_ratio', self.w_female.currentData()))
        f.addRow('Female', self.w_female)
        self.w_fly = QCheckBox('flies (skips LegSweep and the Earthquake skills)')
        self.w_fly.clicked.connect(lambda on: self._set('can_fly', int(on)))
        f.addRow('', self.w_fly)
        self.w_metal = QCheckBox('metal body (like Metaly / MetalKing)')
        self.w_metal.clicked.connect(lambda on: self._set('metal_body', int(on)))
        f.addRow('', self.w_metal)
        self.w_tier = QSpinBox()
        self.w_tier.setRange(0, M.TIER_MAX)
        self.w_tier.setToolTip(TIER_HELP)
        self.w_tier.editingFinished.connect(lambda: self._set('tier', self.w_tier.value()))
        f.addRow('Tier', self.w_tier)
        top.addWidget(basics, 1)
        sk = QGroupBox('Learns by itself')
        sf = QFormLayout(sk)
        self.w_skill = []
        for k in range(3):
            c = QComboBox()
            narrow_combo(c, 16)
            for sid, nm in sorted(self.skills.items()):
                c.addItem(f'{nm}' + ('' if sid < G.SKILL_COUNT else f'  (custom ${sid:02X})'), sid)
            c.activated.connect(lambda _i, k=k: self._set_skill(k))
            sf.addRow(f'Skill {k + 1}', c)
            self.w_skill.append(c)
        n = QLabel('The level / stats each skill needs, and what it upgrades into, belong '
                   'to the skill (Skills tab).')
        n.setWordWrap(True)
        sf.addRow(n)
        top.addWidget(sk, 1)
        v.addLayout(top)

        gr = QGroupBox('Growth — how each stat rises when it levels up')
        gv = QVBoxLayout(gr)
        grid = QGridLayout()
        self.w_growth = {}
        self.w_growth_note = {}
        for i, st in enumerate(G.STATS):
            grid.addWidget(QLabel(M.STAT_LABELS[st]), i // 3, (i % 3) * 3)
            c = QComboBox()
            narrow_combo(c, 10)
            c.activated.connect(lambda _x, st=st, c=c: self._set(f'growth.{st}', c.currentData()))
            grid.addWidget(c, i // 3, (i % 3) * 3 + 1)
            note = QLabel()
            note.setStyleSheet('color:#666')
            grid.addWidget(note, i // 3, (i % 3) * 3 + 2)
            self.w_growth[st] = c
            self.w_growth_note[st] = note
        gv.addLayout(grid)
        self.chart = CurveChart()
        gv.addWidget(self.chart)
        gn = QLabel('Each curve is shared: changing which curve a stat uses affects only '
                    'this species; the 32 curves themselves are used by many species. '
                    'Growth only matters for monsters you raise — enemies use their row\'s '
                    'stats.')
        gn.setWordWrap(True)
        gv.addWidget(gn)
        v.addWidget(gr)

        rs = QGroupBox('Resistances')
        rg = QGridLayout(rs)
        self.w_resist = {}
        names = [n for n in G.RESIST_NAMES if n != 'Unused']
        for i, n in enumerate(names):
            r, c = i // 3, (i % 3) * 2
            rg.addWidget(QLabel(n), r, c)
            cb = QComboBox()
            for k, t in enumerate(M.RESIST_LABELS):
                cb.addItem(t, k)
            cb.activated.connect(lambda _x, n=n, cb=cb: self._set(f'resist.{n}', cb.currentData()))
            rg.addWidget(cb, r, c + 1)
            self.w_resist[n] = cb
        v.addWidget(rs)
        row = QHBoxLayout()
        self.reset_btn = QPushButton('Reset this species to the original game')
        self.reset_btn.clicked.connect(self._reset)
        row.addWidget(self.reset_btn)
        self.diff_note = QLabel()
        self.diff_note.setStyleSheet('color:#a50')
        row.addWidget(self.diff_note, 1)
        v.addLayout(row)
        v.addStretch(1)
        return w

    def _where_page(self):
        w = QWidget()
        v = QVBoxLayout(w)
        h = QLabel(HELP_WHERE)
        h.setWordWrap(True)
        v.addWidget(h)
        self.table = QTableWidget()
        self.cols = ['EID', 'Where', 'Level', 'HP', 'MP', 'ATK', 'DEF', 'AGL', 'INT', 'Exp',
                     'Joins', 'AI weights', 'Battle skills']
        self.table.setColumnCount(len(self.cols))
        self.table.setHorizontalHeaderLabels(self.cols)
        self.table.verticalHeader().setVisible(False)
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.table.horizontalHeader().setSectionResizeMode(1, QHeaderView.Stretch)
        self.table.itemChanged.connect(self._cell_changed)
        v.addWidget(self.table, 1)
        row = QHBoxLayout()
        b = QPushButton('New enemy row for this monster')
        b.setToolTip('Your own battle row of this species (a copy of its first original row, '
                     'or of the wild Slime) — set its level and stats in the table.')
        b.clicked.connect(self._new_enemy_row)
        row.addWidget(b)
        b = QPushButton('Put the selected row in a gate…')
        b.setToolTip('Make it a wild monster of a gate: pick the floors and its chance.')
        b.clicked.connect(self._put_in_gate)
        row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)
        n = QLabel('AI weights: four numbers 0-255 (the monster\'s leanings between its '
                   'kinds of action; the simulator\'s explanation comes with the Balance tab). '
                   'Battle skills: up to 4 skill names, comma-separated. Bold = changed from '
                   'the original game; your own enemies are edited the same way (the Enemies '
                   'dialog has the rest).')
        n.setWordWrap(True)
        v.addWidget(n)
        return w

    def _art_page(self):
        w = QWidget()
        v = QVBoxLayout(w)
        self.art_note = QLabel()
        self.art_note.setWordWrap(True)
        v.addWidget(self.art_note)
        box = QGroupBox('Name and library text')
        self.name_box = box
        f = QFormLayout(box)
        self.a_name = QLineEdit()
        self.a_name.setMaxLength(SP.NAME_MAX)
        self.a_name.editingFinished.connect(lambda: self._text_edit('name', self.a_name.text().strip()))
        f.addRow('Name', self.a_name)
        self.a_short = QLineEdit()
        self.a_short.setMaxLength(SP.SHORT_MAX)
        self.a_short.setToolTip('The naming screen offers this when the monster joins you '
                                '(the player can change it; 4 letters at most).')
        self.a_short.editingFinished.connect(lambda: self._text_edit('nickname', self.a_short.text().strip()))
        f.addRow('Default nickname', self.a_short)
        self.a_desc = QComboBox()
        narrow_combo(self.a_desc, 18)
        names = G.monster_names(M.REPO)
        for i in range(SP.DESC_MAX + 1):
            self.a_desc.addItem(f'{i:3d}  {names.get(i, "")}', i)
        self.a_desc.activated.connect(lambda _i: self._prop('description_from', self.a_desc.currentData()))
        self.a_desc_label = QLabel('Library text of')
        f.addRow(self.a_desc_label, self.a_desc)
        self.a_lines = []
        for k in range(3):
            le = QLineEdit()
            le.setMaxLength(24)
            le.textEdited.connect(self._desc_preview)
            le.editingFinished.connect(self._desc_done)
            f.addRow(f'Description {k + 1}', le)
            self.a_lines.append(le)
        self.a_preview = QLabel()
        f.addRow('In the game', self.a_preview)
        self.a_text_note = QLabel()
        self.a_text_note.setWordWrap(True)
        self.a_text_note.setStyleSheet('color:#555')
        f.addRow(self.a_text_note)
        row = QHBoxLayout()
        self.a_text_reset = QPushButton('Back to the original name and text')
        self.a_text_reset.clicked.connect(self._text_reset)
        row.addWidget(self.a_text_reset)
        self.a_mentions = QPushButton('Texts that name it…')
        self.a_mentions.setToolTip('Dialogue and messages that spell this monster\'s name '
                                   '(they keep what is written there when you rename it).')
        self.a_mentions.clicked.connect(lambda: self.showDialogue.emit(self.sid))
        row.addWidget(self.a_mentions)
        row.addStretch(1)
        f.addRow(row)
        v.addWidget(box)
        art = QGroupBox('Art')
        af = QFormLayout(art)
        self.a_pal = QComboBox()
        for i in range(8):
            pm = QPixmap(36, 14)
            pm.fill(Qt.transparent)
            pp = QPainter(pm)
            for j, ww in enumerate(S.OBJ_PALETTES[i][1:]):
                pp.fillRect(j * 12, 0, 12, 14, QColor(*S.rgb888(ww)))
            pp.end()
            self.a_pal.addItem(QIcon(pm), f'{i} — {S.OBJ_PALETTE_NAMES[i]}', i)
        self.a_pal.activated.connect(lambda _i: self._prop('follower_palette', self.a_pal.currentData()))
        af.addRow('Walking palette', self.a_pal)
        row = QHBoxLayout()
        self.a_sw = []
        for k in range(4):
            b = QPushButton()
            b.setFixedSize(34, 22)
            b.setEnabled(k in (0, 2))
            b.clicked.connect(lambda _c=False, k=k: self._battle_colour(k))
            row.addWidget(b)
            self.a_sw.append(b)
        row.addStretch(1)
        af.addRow('Battle colours', row)
        recut = QPushButton('Re-cut the art from a sprite sheet…')
        recut.clicked.connect(self._recut)
        self.recut_btn = recut
        af.addRow(recut)
        # S107 (P3.10 part 2a): an ORIGINAL monster's art (gamedata.art)
        self.orig_btn = QPushButton('New art from a sprite sheet…')
        self.orig_btn.setToolTip('Cut a battle pose and six walking frames from a sheet; '
                                 'the game then draws this monster with them everywhere '
                                 '(battles, menus, library, following you).')
        self.orig_btn.clicked.connect(self._orig_art)
        af.addRow(self.orig_btn)
        self.orig_reset = QPushButton('Back to the original art and colours')
        self.orig_reset.clicked.connect(self._orig_reset)
        af.addRow(self.orig_reset)
        v.addWidget(art)
        rm = QPushButton('Remove this species…')
        rm.clicked.connect(self._remove)
        self.rm_btn = rm
        v.addWidget(rm)
        v.addStretch(1)
        return w

    # ================================================================ refresh
    def _undo_changed(self, _i):
        # a tab left over from a previously opened project can still be wired
        # to that session's undo stack while Qt has already deleted its child
        # widgets (seen once in test_app S107: "Internal C++ object already
        # deleted" in _fill_art) — such a tab must do nothing
        from shiboken6 import isValid
        if not isValid(self) or not all(isValid(b) for b in self.a_sw):
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
            self._model = doc.monsters_model()
            cat = doc.species_catalog()
            # S110: skill lists show the project's skill names (Skills tab renames)
            self.skills = doc.skill_names_effective()
            for c in self.w_skill:
                for i in range(c.count()):
                    sid = c.itemData(i)
                    if sid is not None and sid < G.SKILL_COUNT:
                        c.setItemText(i, self.skills.get(sid, str(sid)))
        except Exception as ex:                     # noqa: BLE001
            self.title.setText('The project does not validate')
            self.subtitle.setText(str(ex))
            return
        self._busy = True
        cur = self.sid
        self.list.clear()
        new = [s for s in cat if s['kind'] == 'new']
        self._header(f'Your new species  ({len(new)} / {SP.N_IDS})')
        for s in new:
            self._item(s)
        self._header('Original monsters')
        for s in cat:
            if s['kind'] == 'monster':
                self._item(s)
        self._header('Combat-only (never in the library)')
        for s in cat:
            if s['kind'] == 'combat':
                self._item(s)
        self._busy = False
        self._filter(self.filter.text())
        self._meters()
        self.select(cur if any(s['id'] == cur for s in cat) else 0)

    def _header(self, text):
        it = QListWidgetItem(text)
        it.setFlags(Qt.NoItemFlags)
        f = it.font()
        f.setBold(True)
        it.setFont(f)
        it.setData(Qt.UserRole, None)
        self.list.addItem(it)

    def _item(self, s):
        fam = G.FAMILY_NAMES[s['family']] if s['family'] < len(G.FAMILY_NAMES) else '?'
        pm = Q.species_icon(self.s.doc, s['id'], 2)
        it = QListWidgetItem(QIcon(pm) if not pm.isNull() else QIcon(),
                             f"{s['id']:3d}  {s['name']}   · {fam}")
        it.setData(Qt.UserRole, s['id'])
        self.list.addItem(it)

    def _filter(self, text):
        t = text.strip().lower()
        for i in range(self.list.count()):
            it = self.list.item(i)
            sid = it.data(Qt.UserRole)
            if sid is None:
                it.setHidden(bool(t))
            else:
                it.setHidden(bool(t) and t not in it.text().lower())

    def _meters(self):
        try:
            c = self.s.doc.species_capacity()
        except Exception as ex:                     # noqa: BLE001
            self.meters.setText(f'<span style="color:#b00">{ex}</span>')
            return
        u, n = c['slots']
        nu, nn = c['names']
        au, an = c['art']
        try:
            ou, oc = self.s.doc.art_capacity()
        except Exception:                           # noqa: BLE001
            ou, oc = 0, 0
        self.meters.setText(f'New species: <b>{u} / {n}</b> slots · names {nu} / {nn} bytes '
                            f'· art {au} / {an} bytes<br>New art for original monsters: '
                            f'{ou:,} / {oc:,} bytes')

    def select(self, sid):
        for i in range(self.list.count()):
            if self.list.item(i).data(Qt.UserRole) == sid:
                self.list.setCurrentRow(i)
                return

    def _picked(self, it, _prev=None):
        if self._busy or it is None or it.data(Qt.UserRole) is None:
            return
        self.sid = it.data(Qt.UserRole)
        self.show_species()

    def show_species(self):
        doc, sid, model = self.s.doc, self.sid, self._model
        row = doc.species_row(sid, model)
        base = doc.species_base_row(sid)
        info = M.decode_info(row)
        cat = {s['id']: s for s in doc.species_catalog()}
        sp = cat[sid]
        battle, fol = Q.species_art(doc, sid)
        self.battle.set_rows(battle)
        self.walk.set_frames(fol)
        self.title.setText(f"{sp['name']}   #{sid}")
        kind = {'monster': 'original monster', 'combat': 'combat-only entry (rival / summon; '
                'never in the library — its family cannot change)', 'new': 'your new species'}[sp['kind']]
        diff = M.info_diff(row, base)
        self.subtitle.setText(f"{G.FAMILY_NAMES[info['family']]} family · {kind}"
                              + (f" · starts from {G.monster_names(M.REPO).get(doc.new_species(sid)['info']['clone_from'], '')}"
                                 if sp['kind'] == 'new' else ''))
        self._busy = True
        self.w_family.setCurrentIndex(self.w_family.findData(info['family']))
        self.w_family.setEnabled(sp['kind'] != 'combat')
        self.w_cap.setValue(max(1, info['level_cap']))
        self._fill_exp(info['exp_table'])
        self.w_female.setCurrentIndex(info['female_ratio'] & 3)
        self.w_fly.setChecked(bool(info['can_fly']))
        self.w_metal.setChecked(bool(info['metal_body']))
        self.w_tier.setValue(min(M.TIER_MAX, info['tier']))
        for k, c in enumerate(self.w_skill):
            i = c.findData(info['skills'][k])
            if i < 0:
                c.addItem(f"skill ${info['skills'][k]:02X}", info['skills'][k])
                i = c.count() - 1
            c.setCurrentIndex(i)
        series = []
        for st in G.STATS:
            self._fill_growth(st, info['growth'][st])
            cur = self.s.doc.growth_curve(info['growth'][st], model)
            acc, tot = [], 0
            for x in cur:
                tot += x
                acc.append(tot)
            series.append((M.STAT_LABELS[st], acc))
        self.chart.set_series(series)
        for n, cb in self.w_resist.items():
            cb.setCurrentIndex(info['resist'][n] & 3)
            changed = info['resist'][n] != M.decode_info(base)['resist'][n]
            cb.setStyleSheet('font-weight:bold' if changed else '')
        self.diff_note.setText(
            ('changed: ' + ', '.join(sorted(diff))) if diff else
            ('as the original game' if sid <= 220 else 'as the monster it starts from'))
        self.reset_btn.setText('Reset this species to the original game' if sid <= 220
                               else 'Reset to the monster it starts from')
        self._busy = False
        self._fill_where()
        self._fill_art(sp)

    def _fill_exp(self, cur):
        doc, model = self.s.doc, self._model
        self.w_exp.clear()
        for k in range(32):
            c = doc.exp_curve(k, model)
            self.w_exp.addItem(f'curve {k}: level 99 needs {c[-2]:,} exp', k)
        self.w_exp.setCurrentIndex(cur if cur < 32 else 0)
        users = doc.curve_users('exp', cur, model)
        c = doc.exp_curve(cur, model) if cur < 32 else [0] * 99
        self.w_exp_note.setText(f'level 10: {c[8]:,} · level 50: {c[48]:,} · used by '
                                f'{len(users)} species')

    def _fill_growth(self, st, cur):
        doc, model = self.s.doc, self._model
        c = self.w_growth[st]
        c.clear()
        for k in range(32):
            g = doc.growth_curve(k, model)
            c.addItem(f'curve {k} (+{sum(g)} by 99)', k)
        c.setCurrentIndex(cur if cur < 32 else 0)
        g = doc.growth_curve(cur, model) if cur < 32 else [0] * 99
        users = len(doc.curve_users('growth', cur, model))
        self.w_growth_note[st].setText(f'Lv20 +{sum(g[:19])}, Lv50 +{sum(g[:49])} · ×{users}')

    def _fill_where(self):
        doc = self.s.doc
        rows = doc.species_enemies(self.sid, self._model)
        self._rows = rows
        self._busy = True
        self.table.setRowCount(len(rows))
        names = self.skills
        for r, e in enumerate(rows):
            f = e['fields']
            eid_txt = f"{e['eid']}" + ('' if e['kind'] == 'original' else f"  ({e['id']})")
            vals = [eid_txt, '; '.join(e['where']) or '— (not met in a pool, boss or arena list)',
                    f['level'], f['hp'], f['mp'], f['atk'], f['def'], f['agl'], f['int'],
                    f['exp'], f['joinability'], ' '.join(str(x) for x in f['ai_weights']),
                    ', '.join(names.get(x, f'${x:02X}') for x in f['skills'])]
            for c, val in enumerate(vals):
                it = QTableWidgetItem(str(val))
                if c < 2:
                    it.setFlags(it.flags() & ~Qt.ItemIsEditable)
                if e['edited']:
                    fo = it.font()
                    fo.setBold(True)
                    it.setFont(fo)
                if c == 10:
                    it.setToolTip(M.JOIN_LABELS.get(f['joinability'], 'joins by chance'))
                self.table.setItem(r, c, it)
        self.table.resizeColumnsToContents()
        self.table.horizontalHeader().setSectionResizeMode(1, QHeaderView.Stretch)
        self._busy = False

    def _fill_art(self, sp):
        kind = sp['kind']
        self.pages.setTabEnabled(2, kind in ('new', 'monster'))
        if kind == 'combat':
            # TERRY? and the summons are not monsters (PROJECT_STATE Iron Rule 8):
            # only their moves and stats change — no art page
            if self.pages.currentIndex() == 2:
                self.pages.setCurrentIndex(0)
            return
        is_new = kind == 'new'
        for wdg in (self.rm_btn, self.recut_btn, self.a_desc, self.a_desc_label):
            wdg.setVisible(is_new)
        self.a_text_reset.setVisible(not is_new)
        for wdg in (self.orig_btn, self.orig_reset):
            wdg.setVisible(not is_new)
        self._busy = True
        self._fill_text(sp)
        if is_new:
            e = self.s.doc.new_species(self.sid)
            self.a_name.setText(e['name'])
            self.a_short.setText(e.get('short_name', e['name'][:SP.SHORT_MAX]))
            self.a_desc.setCurrentIndex(self.a_desc.findData(int(e.get('description_from', 0))))
            self.a_desc.setEnabled('description' not in e)
            self.a_pal.setCurrentIndex(int((e.get('follower') or {}).get('palette', 0)))
            pal = [int(str(x).replace('$', '0x'), 0) for x in (e.get('battle') or {}).get('palette', [0, 0, 0, 0])]
            src = e.get('source') or {}
            self.art_note.setText('Art from ' + (src.get('sheet') or 'a stream file (no sheet recorded)')
                                  + '. The encyclopedia shows the recipe of the first special '
                                  'breeding recipe that makes this species (Breeding).')
        else:
            e = self.s.doc.original_art(self.sid)
            vb, vf = self.s.doc.original_palettes(self.sid)
            b, f = e.get('battle') or {}, e.get('follower') or {}
            pal = [int(str(x).replace('$', '0x'), 0) for x in b['palette']] if 'palette' in b else vb
            self.a_pal.setCurrentIndex(int(f['palette']) if 'palette' in f else vf)
            src = e.get('source') or {}
            if 'art' in b or 'art' in f:
                what = 'New art from ' + (src.get('sheet') or 'stream files') + '.'
            elif e:
                what = 'The original art, with your colours.'
            else:
                what = 'The original art and colours.'
            used, cap = self.s.doc.art_capacity()
            self.art_note.setText(
                f'{what} New art replaces this monster everywhere the game draws it: battles, '
                'the menus and the library, and following you in the field (it walks with '
                'the walk style you pick). '
                f'Art space used: {used:,} / {cap:,} bytes (banks $7F, $7C, $7A).')
            self.orig_reset.setEnabled(bool(e))
        for k, btn in enumerate(self.a_sw):
            btn.setStyleSheet(f'background:{QColor(*S.rgb888(pal[k])).name()}; border:1px solid #444')
        self._busy = False

    # ================================================================ edits
    def _push(self, label, op, assets=()):
        cmd = C.SnapshotCommand(self.s, label, op, assets=assets)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            self.refresh()
            return False
        return True

    def _name(self):
        return {s['id']: s['name'] for s in self.s.doc.species_catalog()}.get(self.sid, self.sid)

    def _set(self, key, value):
        if self._busy:
            return
        sid = self.sid
        cur = M.decode_info(self.s.doc.species_row(sid, self._model))
        if '.' in key:
            a, b = key.split('.')
            if cur[a][b] == value:
                return
        elif cur.get(key) == value:
            return
        self._push(f'{self._name()}: {key.replace(".", " ")} → {value}',
                   lambda doc: doc.set_species_fields(sid, {key: value}))

    def _set_skill(self, k):
        if self._busy:
            return
        cur = M.decode_info(self.s.doc.species_row(self.sid, self._model))['skills']
        new = list(cur)
        new[k] = self.w_skill[k].currentData()
        if new != cur:
            sid = self.sid
            self._push(f'{self._name()}: skill {k + 1} → {self.skills.get(new[k], new[k])}',
                       lambda doc: doc.set_species_fields(sid, {'skills': new}))

    def _reset(self):
        sid = self.sid
        base = M.decode_info(self.s.doc.species_base_row(sid))
        ch = {k: base[k] for k in ('family', 'level_cap', 'exp_table', 'female_ratio',
                                   'can_fly', 'metal_body', 'tier', 'skills')}
        for st, v in base['growth'].items():
            ch[f'growth.{st}'] = v
        for n, v in base['resist'].items():
            ch[f'resist.{n}'] = v
        if sid in G.PROTECTED_SPECIES:
            ch.pop('family')
        self._push(f'{self._name()}: reset', lambda doc: doc.set_species_fields(sid, ch))

    def _cell_changed(self, it):
        if self._busy:
            return
        r, c = it.row(), it.column()
        e = self._rows[r]
        key = {2: 'level', 3: 'hp', 4: 'mp', 5: 'atk', 6: 'def', 7: 'agl', 8: 'int',
               9: 'exp', 10: 'joinability', 11: 'ai_weights', 12: 'skills'}.get(c)
        if key is None:
            return
        txt = it.text().strip()
        try:
            if key == 'ai_weights':
                val = [int(x) for x in txt.replace(',', ' ').split()]
                if len(val) != 4:
                    raise ValueError('four numbers 0-255')
            elif key == 'skills':
                inv = {v.lower(): k for k, v in self.skills.items()}
                val = []
                for part in [p.strip() for p in txt.split(',') if p.strip()]:
                    if part.lower() in inv:
                        val.append(inv[part.lower()])
                    else:
                        val.append(int(part.replace('$', '0x'), 0))
                if len(val) > 4:
                    raise ValueError('at most 4 skills')
            else:
                val = int(txt)
        except ValueError as ex:
            QMessageBox.warning(self, 'Enemy row', f'{self.cols[c]}: {txt!r} — {ex}')
            self._fill_where()
            return
        eid, pid = e['eid'], e['id']
        self._push(f'EID {eid}: {key} → {val}',
                   lambda doc: doc.set_enemy_fields(eid, {key: val}, project_id=pid))

    def _selected_row(self):
        r = self.table.currentRow()
        rows = getattr(self, '_rows', [])
        return rows[r] if 0 <= r < len(rows) else None

    def _new_enemy_row(self):
        sid = self.sid
        out = {}

        def op(doc):
            out['id'] = doc.new_enemy_for_species(sid)
        if self._push(f'{self._name()}: new enemy row', op):
            self.pages.setCurrentIndex(1)
            for k, e in enumerate(self._rows):
                if e['id'] == out.get('id'):
                    self.table.selectRow(k)

    def _put_in_gate(self):
        e = self._selected_row()
        if e is None:
            if not getattr(self, '_rows', None):
                QMessageBox.information(self, 'Put in a gate', 'This monster has no enemy '
                                        'row yet — click "New enemy row for this monster" '
                                        'first, then set its level and stats.')
            else:
                QMessageBox.information(self, 'Put in a gate', 'Select a row first.')
            return
        from editor2.app.pool_dialog import PoolDialog
        ref = e['id'] if e['kind'] == 'project' else e['eid']
        label = f"{self._name()} Lv {e['fields']['level']} (EID {e['eid']})"
        dlg = PoolDialog(self.s.doc, ref, label, parent=self)
        if not dlg.exec() or dlg.result_slots is None:
            return
        pi, slots = dlg.result_pool, dlg.result_slots
        self._push(f'{self._name()} → gate list {pi}',
                   lambda doc: doc.set_pool_slots(pi, slots))

    def _prop(self, key, value):
        if self._busy:
            return
        if self.sid <= 214:
            if key == 'follower_palette':
                sid = self.sid
                if self.s.doc.original_art(sid).get('follower', {}).get(
                        'palette', self.s.doc.original_palettes(sid)[1]) != value:
                    self._push(f'{self._name()}: walking palette → {value}',
                               lambda doc: doc.set_original_art_props(sid, follower_palette=value))
            return
        e = self.s.doc.new_species(self.sid)
        cur = {'name': e['name'], 'short_name': e.get('short_name', e['name'][:SP.SHORT_MAX]),
               'description_from': e.get('description_from'),
               'follower_palette': (e.get('follower') or {}).get('palette')}.get(key)
        if cur == value:
            return
        sid = self.sid
        self._push(f'{self._name()}: {key.replace("_", " ")} → {value}',
                   lambda doc: doc.set_species_props(sid, **{key: value}))

    # ---------------------------------------------------- S108 name / text
    def _desc_rows(self):
        from editor2.core import monster_text as MT
        rows = []
        for le in self.a_lines:
            try:
                rows.append(MT.desc_codes(le.text()))
            except MT.MonsterTextError:
                rows.append([0x64] * len(le.text()))
        while len(rows) > 1 and not rows[-1]:
            rows.pop()
        return rows

    def _desc_preview(self, *_a):
        from editor2.core import monster_text as MT
        if not hasattr(self, '_rom_bytes'):
            self._rom_bytes = _rom()
        rows = self._desc_rows()
        self.a_preview.setPixmap(text_pixmap(self._rom_bytes, rows, MT.DESC_CELLS))
        cells = ', '.join(f'{len(r)}' for r in rows)
        bad = [k + 1 for k, r in enumerate(rows) if len(r) > MT.DESC_CELLS]
        msg = f'cells per line: {cells} (18 fit)'
        if bad:
            msg += f' — line {", ".join(map(str, bad))} is too long (red = cut off)'
        self._desc_msg = msg

    def _fill_text(self, sp):
        """Name / nickname / description fields + preview + meters."""
        from editor2.core import dialogue_index as DI
        from editor2.core import monster_text as MT
        doc = self.s.doc
        if sp['kind'] == 'new':
            e = doc.new_species(self.sid)
            own = e.get('description')
            if own:
                lines = list(own) if not isinstance(own, str) else own.split('\n')
            else:
                van = MT.vanilla()
                lines = MT.desc_lines(van['descs'][int(e.get('description_from', 0))])
            names = [e['name']]
            edited = bool(own)
            note = ('Type your own description, or leave the lines empty to show another '
                    'monster\'s ("Library text of").' + ('' if own else ' (showing that text now)'))
        else:
            t = doc.monster_text(self.sid)
            self.a_name.setText(t['name'])
            self.a_short.setText(t['nickname'])
            lines = t['description']
            names = [t['name']] + ([t['original']['name']] if t['edited']['name'] else [])
            edited = any(t['edited'].values())
            ch = [k for k, v in t['edited'].items() if v]
            note = (('Changed: ' + ', '.join(ch) + f' (originally “{t["original"]["name"]}”, '
                     f'“{t["original"]["nickname"]}”). ') if ch else 'As in the original game. ')
            note += ('The name shows everywhere the game prints it: battles, menus, the '
                     'library, breeding and the recipe lines (they follow automatically).')
            self.a_text_reset.setEnabled(edited)
        for k, le in enumerate(self.a_lines):
            le.setText(lines[k] if k < len(lines) else '')
        self._desc_preview()
        try:
            cap = doc.text_capacity()
            meter = (f" Text space: names {cap['names'][0]:,} / {cap['names'][1]:,} B · nicknames "
                     f"{cap['nicks'][0]} / {cap['nicks'][1]} B · descriptions {cap['descs'][0]:,} / "
                     f"{cap['descs'][1]:,} B (more than the block spills into free space; the "
                     "build says when it is full).")
        except Exception:                           # noqa: BLE001
            meter = ''
        n = len({e['key'] for nm in names for e in DI.mentions(nm)})
        self.a_mentions.setText(f'Texts that name it… ({n})')
        self.a_text_note.setText(note + ' ' + self._desc_msg + '.' + meter)

    def _text_edit(self, key, value):
        """Name / nickname edited (originals -> gamedata.monster_text; new
        species -> custom.species name / short_name)."""
        if self._busy:
            return
        sid = self.sid
        if sid > 220:
            self._prop('name' if key == 'name' else 'short_name', value)
            return
        cur = self.s.doc.monster_text(sid)
        if cur[key] == value:
            return
        self._push(f'{self._name()}: {key} → {value}',
                   lambda doc: doc.set_monster_text(sid, **{key: value}))

    def _desc_done(self):
        if self._busy:
            return
        lines = [le.text() for le in self.a_lines]
        while lines and not lines[-1].strip():
            lines.pop()
        sid = self.sid
        if sid > 220:
            e = self.s.doc.new_species(sid)
            cur = e.get('description') or None
            if (lines or None) == (list(cur) if cur else None):
                return
            if not lines and cur is None:
                return
            self._push(f'{self._name()}: description',
                       lambda doc: doc.set_species_props(sid, description=lines or None))
            return
        cur = self.s.doc.monster_text(sid)
        if not lines:
            lines = cur['original']['description']
        if lines == cur['description']:
            return
        self._push(f'{self._name()}: description',
                   lambda doc: doc.set_monster_text(sid, description=lines))

    def _text_reset(self):
        sid = self.sid
        self._push(f'{self._name()}: original name and text',
                   lambda doc: doc.reset_monster_text(sid))

    def _battle_colour(self, k):
        if self.sid <= 214:
            e = self.s.doc.original_art(self.sid)
            b = e.get('battle') or {}
            pal = [int(str(x).replace('$', '0x'), 0) for x in b['palette']] if 'palette' in b \
                else self.s.doc.original_palettes(self.sid)[0]
            c = QColorDialog.getColor(QColor(*S.rgb888(pal[k])), self, 'Battle colour')
            if not c.isValid():
                return
            pal[k] = S.rgb555((c.red(), c.green(), c.blue()))
            sid = self.sid
            self._push(f'{self._name()}: battle colour', lambda doc: doc.set_original_art_props(
                sid, battle_palette=pal))
            return
        e = self.s.doc.new_species(self.sid)
        pal = [int(str(x).replace('$', '0x'), 0) for x in e['battle']['palette']]
        c = QColorDialog.getColor(QColor(*S.rgb888(pal[k])), self, 'Battle colour')
        if not c.isValid():
            return
        pal[k] = S.rgb555((c.red(), c.green(), c.blue()))
        sid = self.sid
        self._push(f'{self._name()}: battle colour', lambda doc: doc.set_species_props(
            sid, battle_palette=pal))

    def _new_species(self):
        if not self.s.doc.free_species_ids():
            QMessageBox.information(self, 'New species', 'All 19 new-species slots (ids 221-239) '
                                    'are used.')
            return
        from editor2.app.sheet_import_dialog import SheetImportDialog, copy_sheet_into_project
        dlg = SheetImportDialog(self.s.doc, 'new', parent=self)
        if not dlg.exec() or not dlg.result_data:
            return
        r = dlg.result_data
        assets = self.s.doc.species_asset_paths(r['id'], r['name']) + [r['source']['sheet']]

        def op(doc):
            copy_sheet_into_project(doc.project_dir, r['sheet_abs'], r['source']['sheet'])
            doc.add_species(r['id'], r['name'], r['short'], r['clone_from'], r['family'],
                            r['art'], source=r['source'])
        if self._push(f"New species {r['name']} (#{r['id']})", op, assets=assets):
            self.sid = r['id']
            self.refresh()

    def _recut(self):
        from editor2.app.sheet_import_dialog import SheetImportDialog, copy_sheet_into_project
        dlg = SheetImportDialog(self.s.doc, 'recut', sid=self.sid, parent=self)
        if not dlg.exec() or not dlg.result_data:
            return
        r = dlg.result_data
        e = self.s.doc.new_species(self.sid)
        assets = [e['battle']['art'], e['follower']['art'], r['source']['sheet']]
        sid = self.sid

        def op(doc):
            copy_sheet_into_project(doc.project_dir, r['sheet_abs'], r['source']['sheet'])
            doc.set_species_art(sid, r['art'], source=r['source'])
        self._push(f'{self._name()}: new art', op, assets=assets)

    def _orig_art(self):
        """S107: new art for an ORIGINAL monster from a sprite sheet."""
        from editor2.app.sheet_import_dialog import SheetImportDialog, copy_sheet_into_project
        dlg = SheetImportDialog(self.s.doc, 'original', sid=self.sid, parent=self)
        if not dlg.exec() or not dlg.result_data:
            return
        r = dlg.result_data
        sid = self.sid
        assets = self.s.doc.original_art_paths(sid) + [r['source']['sheet']]

        def op(doc):
            copy_sheet_into_project(doc.project_dir, r['sheet_abs'], r['source']['sheet'])
            doc.set_original_art(sid, r['art'], source=r['source'])
        self._push(f'{self._name()}: new art', op, assets=assets)

    def _orig_reset(self):
        sid = self.sid
        self._push(f'{self._name()}: original art', lambda doc: doc.reset_original_art(sid))

    def _remove(self):
        refs = self.s.doc.species_references(self.sid)
        if refs:
            QMessageBox.warning(self, 'Remove species', f'{self._name()} is still used by: '
                                + ', '.join(refs) + '. Change those first.')
            return
        if QMessageBox.question(self, 'Remove species', f'Remove {self._name()} '
                                f'(#{self.sid}) from the project?') != QMessageBox.Yes:
            return
        sid = self.sid
        if self._push(f'Remove species #{sid}', lambda doc: doc.remove_species(sid)):
            self.sid = 0
            self.refresh()
