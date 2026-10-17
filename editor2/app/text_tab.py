"""text_tab.py — the Text tab: the game's own texts, editable (S150, ROADMAP
P3.6 / Phase F T-author; replaces the read-only S108 Dialogue tab; model
editor2/core/gametext_doc.py, compiler editor2/core/gametext.py, markup
editor2/core/textmark.py; PROJECT_COMPILER §2.58).

One sub-tab per kind of text (user S150: "differentiate by tab"):
  Dialogue        the 2,560 text ids — people, story, signs, questions
  Battle          battle messages, treats / veils / not enough MP, commands,
                  the BeastTail, level-up and spell lines, the battle tutorial
  Items           item names, descriptions, use messages
  Menus & field   field messages and menu words, personalities, the families'
                  default names, Watabou
  Credits         the ending's credits and "TO BE CONTINUED"
  Other tabs      the monster / skill descriptions (read-only here — the
                  Monsters / Skills tabs edit them)

Each text is edited as markup (the module doc of textmark.py): letters as
themselves, a new line, ▼ = the next box (dialogue), {tokens} for the codes.
The picture under it is the game's own font. Any length: an edited text lives
in its own bank of the 4 MB ROM. Texts the game showed through several ids
with the SAME line are edited together (untick "with its copies" for one id).
"""

import re

from PySide6.QtCore import Qt
from PySide6.QtGui import QColor, QFont, QImage, QKeySequence, QPixmap, QShortcut
from PySide6.QtWidgets import (QAbstractItemView, QCheckBox, QComboBox, QFileDialog,
                               QHBoxLayout, QHeaderView, QLabel, QLineEdit,
                               QPlainTextEdit, QPushButton, QScrollArea, QSplitter,
                               QTableWidget, QTableWidgetItem, QTabWidget, QVBoxLayout,
                               QWidget)

from editor2.app.rooms import commands as C
from editor2.app.rooms.talk_editor import FRAME, PAL, OVER, _blit
from editor2.core import dialogue_index as D
from editor2.core import gametext as GT
from editor2.core import textenc as TE
from editor2.core import textmark as TM

PAGES = GT.GROUPS + [('other', 'Other tabs')]
OTHER_GROUPS = ('skills', 'monsters')
HELP = {
    'dialogue': 'Everything people say: the 2,560 text ids of the game (story, signs, '
                'questions). A new line = the next line of the box; ▼ = wait for A, '
                'the next box. {low} / {high} = the voice, {hero} = the player\'s name, '
                '{yes/no} = the YES / NO box.',
    'battle': 'Battle messages ({ins 00} = the acting monster\'s name …), what treats, '
              'veils and the BeastTail say, level-up and spell lines, the battle tutorial.',
    'items': 'Item names (at most 9 letters — the bag draws them in a 9-cell column), '
             'descriptions (the item page) and what using one says.',
    'menus': 'Field messages and the words of the menus, personalities (at most 9 '
             'letters), the families\' default names (at most 4 — the naming screen), '
             'Watabou.',
    'credits': 'The ending\'s credits — the roles, the names — and "TO BE CONTINUED".',
    'other': 'Read-only here: the monster descriptions are edited on the Monsters tab, '
             'the skill descriptions on the Skills tab.',
}
TOKENS_HELP = ('Tokens: {hero} the player\'s name · {ins 00} a name the game fills in '
               '(00 / 10 / 20 / 30) · {low} {high} the voice · {yes/no} · ▼ (dialogue: '
               'wait + next box) · {wait} {clear} · {sound 60} · {end} (dialogue: end '
               'without clearing) · {XX} any code ($E0-$FF) with its bytes · {$xx} any '
               'glyph · {slime} … the family icons. ".." typed is two dots; ‥ is the '
               'one-cell glyph.')
SCALE = 2
NAME_CELLS = 9
BOX_W = 18


def _units(raw):
    return TM._units(raw)


_SHOWN = re.compile(r'\{(hero|ins [0-9a-fA-F]{2}|\$[0-9a-fA-F]{2}|slime|dragon|beast|bird|plant|bug|'
                    r'devil|zombie|material)\}', re.I)


def list_text(markup):
    """The markup on one line for the list: what prints (letters, {hero}, {ins NN}, icons)
    — the voice / box / wait codes left out."""
    keep = []

    def mark(m):
        keep.append(m.group(0))
        return f'\x00{len(keep) - 1}\x00'
    s = _SHOWN.sub(mark, markup or '')
    s = TM.plain(s)
    s = re.sub('\x00(\\d+)\x00', lambda m: keep[int(m.group(1))], s)
    return ' '.join(s.split())


def _glyph(rom, code):
    if rom:
        g = TE.glyph_2bpp(rom, code)
        if len(g) == 16:
            return g
    return FRAME[0xE0]


def layout_boxes(raw):
    """Box style -> [[line codes, ...] per box] as the engine draws them:
    $EF $EE = next line, ▼ ($FA $F7) / $F7 / $F3 = next box, inserts at the
    cells they may take."""
    boxes, lines, cur = [], [], []
    units = _units(raw)
    k = 0
    while k < len(units):
        kind, bs = units[k]
        b = bs[0]
        if kind == 'g':
            cur.append(b)
        elif b == 0xF6:
            cur += list(TE.TOKENS['{hero}'][2])
        elif b == 0xF9:
            cur += [-1] * NAME_CELLS
        elif b == 0xEF and k + 1 < len(units) and units[k + 1][1] == b'\xee':
            lines.append(cur)
            cur = []
            k += 1
        elif b == 0xFA and k + 1 < len(units) and units[k + 1][1] == b'\xf7':
            lines.append(cur)
            boxes.append(lines)
            lines, cur = [], []
            k += 1
            # the usual "▼\n": the line break after a fresh box starts line 1
            if k + 2 < len(units) and units[k + 1][1] == b'\xef' and units[k + 2][1] == b'\xee':
                k += 2
        elif b in (0xF7, 0xF3):
            if cur or lines:
                lines.append(cur)
                boxes.append(lines)
            lines, cur = [], []
        k += 1
    if cur or lines:
        lines.append(cur)
        boxes.append(lines)
    return [[ln for ln in bx] for bx in boxes if any(bx)] or [[[]]]


def layout_rows(raw):
    """Rows style -> [line codes] ($F1 = next line; inserts at their cells)."""
    lines, cur = [], []
    for kind, bs in _units(raw):
        b = bs[0]
        if kind == 'g':
            cur.append(b)
        elif b == 0xF6:
            cur += list(TE.TOKENS['{hero}'][2])
        elif b == 0xF9:
            cur += [-1] * NAME_CELLS
        elif b == 0xF1 or b == 0xEE:
            lines.append(cur)
            cur = []
    lines.append(cur)
    return lines


def render(rom, raw, style, width=BOX_W):
    """QPixmap of the text in the game's font: dialogue as its boxes (2 lines
    each — a line past 18 cells and a 3rd line are red: the game loses or
    scrolls them), a table text as its lines (cells past `width` red)."""
    name = bytes.fromhex('ff00ff7eff42ff42ff42ff42ff7eff00')     # an inserted name's cell
    if style == 'box':
        boxes = layout_boxes(raw)
        rows_px = 0
        tiles = []
        for bx in boxes:
            h = 5 + 2 * max(0, len(bx) - 2)
            tiles.append(h)
            rows_px += h
        img = QImage(8 * (BOX_W + 2), 8 * max(5, rows_px), QImage.Format_RGB32)
        img.fill(QColor(40, 40, 40))
        y0 = 0
        for bx, h in zip(boxes, tiles):
            top = [0xFA] + [0xEF] * 18 + [0xFB]
            mid = [0xFE] + [0xE0] * 18 + [0xFF]
            bot = [0xFC] + [0xEE] * 18 + [0xFD]
            for ty, row in enumerate([top] + [mid] * (h - 2) + [bot]):
                for tx, c in enumerate(row):
                    _blit(img, FRAME[c], tx, y0 + ty)
            for li, ln in enumerate(bx):
                ty = y0 + 1 + 2 * li
                for kx, c in enumerate(ln[:BOX_W]):
                    tint = OVER if li >= 2 else None
                    _blit(img, name if c < 0 else _glyph(rom, c), 1 + kx, ty, tint)
            y0 += h
        pm = QPixmap.fromImage(img)
        return pm.scaled(pm.width() * SCALE, pm.height() * SCALE)
    lines = layout_rows(raw)
    w = max([width] + [len(ln) for ln in lines])
    img = QImage(8 * (w + 2), 8 * (2 * len(lines) + 1), QImage.Format_RGB32)
    img.fill(PAL[1])
    for li, ln in enumerate(lines):
        for kx, c in enumerate(ln):
            tint = OVER if kx >= width else None
            _blit(img, name if c < 0 else _glyph(rom, c), 1 + kx, 1 + 2 * li, tint)
    pm = QPixmap.fromImage(img)
    return pm.scaled(pm.width() * SCALE, pm.height() * SCALE)


class GroupPage(QWidget):
    def __init__(self, tab, group, title):
        super().__init__()
        self.tab = tab
        self.s = tab.s
        self.group = group
        self.title = title
        self.shown = []
        self.cur = None
        self._busy = False
        v = QVBoxLayout(self)
        h = QLabel(HELP.get(group, ''))
        h.setWordWrap(True)
        v.addWidget(h)
        row = QHBoxLayout()
        self.query = QLineEdit()
        self.query.setPlaceholderText('Search words, a text id ($0123), a row (#12) or an address ($42:$4142)')
        self.query.textChanged.connect(self.refresh)
        row.addWidget(self.query, 2)
        self.kind = QComboBox()
        self.kind.currentIndexChanged.connect(self.refresh)
        row.addWidget(self.kind, 1)
        self.edited_only = QCheckBox('Edited only')
        self.edited_only.toggled.connect(self.refresh)
        row.addWidget(self.edited_only)
        self.monster = None
        if group == 'dialogue':
            self.monster = QComboBox()
            self.monster.currentIndexChanged.connect(self.refresh)
            row.addWidget(QLabel('Names a monster:'))
            row.addWidget(self.monster, 1)
        exp = QPushButton('Save as text file…')
        exp.clicked.connect(self._export)
        row.addWidget(exp)
        v.addLayout(row)
        split = QSplitter(Qt.Vertical)
        self.table = QTableWidget()
        self.table.setColumnCount(4)
        self.table.setHorizontalHeaderLabels(['', 'Kind', 'Id', 'Text'])
        self.table.verticalHeader().setVisible(False)
        self.table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.table.horizontalHeader().setSectionResizeMode(3, QHeaderView.Stretch)
        self.table.currentCellChanged.connect(self._pick)
        split.addWidget(self.table)
        det = QWidget()
        dv = QVBoxLayout(det)
        dv.setContentsMargins(0, 0, 0, 0)
        self.head = QLabel('')
        self.head.setWordWrap(True)
        self.head.setTextInteractionFlags(Qt.TextSelectableByMouse)
        dv.addWidget(self.head)
        mid = QHBoxLayout()
        left = QVBoxLayout()
        self.edit = QPlainTextEdit()
        f = QFont('Menlo')
        f.setStyleHint(QFont.Monospace)
        self.edit.setFont(f)
        self.edit.setLineWrapMode(QPlainTextEdit.NoWrap)
        self.edit.textChanged.connect(self._preview)
        left.addWidget(self.edit, 1)
        btns = QHBoxLayout()
        self.apply_b = QPushButton('Apply')
        self.apply_b.setToolTip('Keep this text (Ctrl+Return) — one undo step')
        self.apply_b.clicked.connect(self._apply)
        btns.addWidget(self.apply_b)
        self.orig_b = QPushButton('Original')
        self.orig_b.setToolTip("Back to the game's own text")
        self.orig_b.clicked.connect(self._original)
        btns.addWidget(self.orig_b)
        self.copies = QCheckBox('with its copies')
        self.copies.setChecked(True)
        self.copies.setToolTip('The game shows this same line through other ids too — change '
                               'them all (untick: only this id)')
        btns.addWidget(self.copies)
        arrow = QPushButton('▼')
        arrow.setToolTip('Type the box break (dialogue: wait for A, then the next box)')
        arrow.setMaximumWidth(30)
        arrow.clicked.connect(lambda: self.edit.insertPlainText(TM.ARROW))
        btns.addWidget(arrow)
        btns.addStretch(1)
        left.addLayout(btns)
        self.status = QLabel('')
        self.status.setWordWrap(True)
        left.addWidget(self.status)
        tok = QLabel(TOKENS_HELP)
        tok.setWordWrap(True)
        tok.setStyleSheet('color: #777;')
        left.addWidget(tok)
        mid.addLayout(left, 3)
        self.pic = QLabel()
        self.pic.setAlignment(Qt.AlignTop | Qt.AlignLeft)
        sc = QScrollArea()
        sc.setWidget(self.pic)
        sc.setWidgetResizable(True)
        sc.setMinimumWidth(8 * (BOX_W + 2) * SCALE + 24)
        mid.addWidget(sc, 2)
        dv.addLayout(mid, 1)
        split.addWidget(det)
        split.setSizes([360, 340])
        v.addWidget(split, 1)
        self.count = QLabel()
        v.addWidget(self.count)
        QShortcut(QKeySequence('Ctrl+Return'), self.edit, activated=self._apply)
        self.read_only = group == 'other'
        for w in (self.edit,):
            w.setReadOnly(self.read_only)
        for w in (self.apply_b, self.orig_b, self.copies, arrow):
            w.setEnabled(not self.read_only)
        self.fill_kinds()

    # ------------------------------------------------------------ data
    def entries(self):
        ix = self.s.doc.game_text_index()
        groups = OTHER_GROUPS if self.group == 'other' else (self.group,)
        out = []
        for k in ix.order:
            x = ix.entries[k]
            if x.group not in groups:
                continue
            if not x.first:
                continue               # a copy: listed once (the first id)
            out.append(x)
        return out

    def fill_kinds(self):
        self.kind.blockSignals(True)
        self.kind.clear()
        self.kind.addItem('All kinds', None)
        seen = []
        for x in self.entries():
            t = x.title
            if t not in seen:
                seen.append(t)
                self.kind.addItem(t, t)
        self.kind.blockSignals(False)
        if self.monster is not None:
            self.fill_monsters()
        self.refresh()

    def fill_monsters(self):
        from editor2.core import monster_text as MT
        try:
            names = self.s.doc.monster_names_effective()
        except Exception:                                   # noqa: BLE001
            names = {}
        cur = self.monster.currentData()
        van = MT.vanilla()
        self.monster.blockSignals(True)
        self.monster.clear()
        self.monster.addItem('—', None)
        for sid in sorted(names):
            if 215 <= sid <= 220:
                continue
            orig = MT.decode(van['names'][sid]) if sid < 215 else None
            label = names[sid] + (f'  (was {orig})' if orig and orig != names[sid] else '')
            self.monster.addItem(f'{sid:3d}  {label}', sid)
        i = self.monster.findData(cur)
        self.monster.setCurrentIndex(max(0, i))
        self.monster.blockSignals(False)

    def _monster_names(self, sid):
        from editor2.core import monster_text as MT
        names = self.s.doc.monster_names_effective()
        out = [names.get(sid)] if names.get(sid) else []
        if sid is not None and sid < 215:
            orig = MT.decode(MT.vanilla()['names'][sid])
            if orig not in out:
                out.append(orig)
        return out

    def current_markup(self, x):
        rows = self.s.doc._gt_rows().get(x.source) or {}
        m = rows.get(GT._norm_key(x.source, x.key))
        return (m, True) if m is not None else (self.tab.original(x), False)

    def refresh(self, *_a):
        q = ' '.join((self.query.text() or '').lower().split())
        kind = self.kind.currentData()
        only = self.edited_only.isChecked()
        marks = []
        pats = []
        if self.monster is not None and self.monster.currentData() is not None:
            marks = self._monster_names(self.monster.currentData())
            pats = [D.name_pattern(n) for n in marks]
        out = []
        for x in self.entries():
            if kind and x.title != kind:
                continue
            m, ed = self.current_markup(x)
            if only and not ed:
                continue
            flat = list_text(m)
            if q:
                ref = f"{x.key if x.source == GT.DIALOGUE else '#' + x.key}".lower()
                where = f"${x.bank:02x}:${x.addr:04x}"
                if q[:1] in '#$' and ':' not in q:
                    if q != ref:                 # an id / a row number: that one
                        continue
                elif q not in flat.lower() and q not in where:
                    continue
            if pats and not any(p.search(flat) for p in pats):
                continue
            out.append((x, m, ed, flat))
        self.shown = out
        self._marks = marks
        self.table.setRowCount(len(out))
        for r, (x, m, ed, flat) in enumerate(out):
            ref = x.key if x.source == GT.DIALOGUE else f'#{x.key}'
            vals = ['✎' if ed else '', x.title if x.source != GT.DIALOGUE else 'text id',
                    ref, flat[:200]]
            for c, val in enumerate(vals):
                it = QTableWidgetItem(val)
                if ed:
                    it.setForeground(QColor(30, 90, 200))
                self.table.setItem(r, c, it)
        for c in range(3):
            self.table.resizeColumnToContents(c)
        n_ed = len(self.s.doc.game_text_edited(None if self.group == 'other' else self.group))
        self.count.setText(f'{len(out)} texts' + (f" naming {' / '.join(marks)}" if marks else '')
                           + (f' · {n_ed} edited on this tab' if self.group != 'other' else ''))
        if out:
            keep = next((i for i, t in enumerate(out) if self.cur is not None and
                         (t[0].source, t[0].key) == (self.cur.source, self.cur.key)), 0)
            self.table.setCurrentCell(keep, 3)
            self._pick(keep)
        else:
            self.cur = None
            self.edit.setPlainText('')
            self.head.setText('')

    def _pick(self, row, *_a):
        if not 0 <= row < len(self.shown):
            return
        x, m, ed, _f = self.shown[row]
        self.cur = x
        ref = x.key if x.source == GT.DIALOGUE else f'row {x.key}'
        bits = [f"<b>{x.title}</b> · {ref} · bank ${x.bank:02X} ${x.addr:04X} "
                f"(slot ${x.bank:02X}:${x.table + 2 * x.index:04X})"]
        if x.same:
            others = [k if s == GT.DIALOGUE else f'{s} #{k}' for s, k in x.same]
            bits.append(f"also shown as {', '.join(others[:12])}{' …' if len(others) > 12 else ''}")
        if x.inside:
            bits.append(f"(the game starts this text inside {x.inside}'s line — editing that one "
                        "does not change this one)")
        if ed:
            bits.append('<span style="color:#1e5ac8">edited</span>')
        if x.owner:
            bits.append(f'edit it on the {x.owner} tab')
        self.head.setText(' · '.join(bits))
        self.copies.setVisible(bool(x.same))
        self._busy = True
        self.edit.setPlainText(m)
        self._busy = False
        self._preview()

    def _style(self):
        return self.cur.style if self.cur else 'box'

    def _preview(self):
        if self.cur is None:
            return
        txt = self.edit.toPlainText()
        rom = getattr(getattr(self.s, 'renderer', None), 'rom', None)
        try:
            raw = self.s.doc.check_game_text(self.cur.source, txt) if not self.cur.owner \
                else TM.encode(txt, self.cur.style)
            err = None
        except ValueError as e:
            raw, err = None, str(e)
        if raw is not None:
            self.pic.setPixmap(render(rom, raw, self.cur.style))
            ws = GT.warnings_for(self.cur, raw + b'\xf0')
            n = len(raw) + 1
            msg = f'{n} bytes'
            if ws:
                msg += ' · ⚠ ' + '; '.join(w.split(': ', 1)[-1] for w in ws)
            self.status.setStyleSheet('color: #b26b00;' if ws else 'color: #2a7a2a;')
            self.status.setText(msg)
        else:
            self.status.setStyleSheet('color: #c62828;')
            self.status.setText('✗ ' + err)
        orig = self.tab.original(self.cur)
        self.apply_b.setEnabled(not self.read_only and raw is not None and
                                txt != self.current_markup(self.cur)[0])
        self.orig_b.setEnabled(not self.read_only and txt != orig or
                               (not self.read_only and self.current_markup(self.cur)[1]))

    def _apply(self):
        if self.cur is None or self.read_only:
            return
        x = self.cur
        txt = self.edit.toPlainText()
        if txt == self.current_markup(x)[0]:
            return
        only = bool(x.same) and not self.copies.isChecked()
        ref = x.key if x.source == GT.DIALOGUE else f'{x.title} #{x.key}'
        cmd = C.SnapshotCommand(self.s, f'Text {ref}',
                                lambda doc: doc.set_game_text(x.source, x.key, txt, only_this=only))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            self.status.setStyleSheet('color: #c62828;')
            self.status.setText('✗ ' + str(cmd.error))
        self.refresh()

    def _original(self):
        if self.cur is None or self.read_only:
            return
        x = self.cur
        only = bool(x.same) and not self.copies.isChecked()
        ref = x.key if x.source == GT.DIALOGUE else f'{x.title} #{x.key}'
        cmd = C.SnapshotCommand(self.s, f'Text {ref}: original',
                                lambda doc: doc.reset_game_text(x.source, x.key, only_this=only))
        self.s.undo.push(cmd)
        self.refresh()

    def _export(self):
        path, _ = QFileDialog.getSaveFileName(self, 'Save texts', f'{self.group}.txt',
                                              'Text files (*.txt)')
        if not path:
            return
        with open(path, 'w', encoding='utf-8') as f:
            for x, m, ed, _flat in self.shown:
                ref = x.key if x.source == GT.DIALOGUE else f'#{x.key}'
                f.write(f"=== {x.title} {ref}   (${x.bank:02X}:${x.addr:04X})"
                        + ('   [edited]' if ed else '') + "\n" + m + "\n\n")
        self.count.setText(f'Saved {len(self.shown)} texts to {path}')


class TextTab(QWidget):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self._orig = {}
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        self.tabs = QTabWidget()
        self.pages = {}
        for group, title in PAGES:
            pg = GroupPage(self, group, title)
            self.pages[group] = pg
            self.tabs.addTab(pg, title.replace('&', '&&'))
        v.addWidget(self.tabs)
        self.s.undo.indexChanged.connect(self._undo_changed)

    def original(self, x):
        k = (x.source, x.key)
        if k not in self._orig:
            self._orig[k] = x.markup()
        return self._orig[k]

    def _undo_changed(self, _i):
        # a Text tab of a previously opened project can still be wired to that
        # session's undo stack after Qt deleted its widgets (KEY_LESSONS S107)
        from shiboken6 import isValid
        if not isValid(self) or not isValid(self.tabs) or \
                not all(isValid(pg) and isValid(pg.kind) for pg in self.pages.values()):
            return
        if self.isVisibleTo(self.window()):
            self.tabs.currentWidget().refresh()
            if self.pages['dialogue'].monster is not None:
                self.pages['dialogue'].fill_monsters()
        else:
            self._stale = True

    def showEvent(self, ev):
        if getattr(self, '_stale', False):
            self._stale = False
            for pg in self.pages.values():
                if pg.monster is not None:
                    pg.fill_monsters()
                pg.refresh()
        super().showEvent(ev)

    def show_monster(self, sid):
        """Monsters tab → "Texts that name it…": the Dialogue sub-tab filtered."""
        pg = self.pages['dialogue']
        self.tabs.setCurrentWidget(pg)
        pg.query.clear()
        pg.kind.setCurrentIndex(0)
        pg.fill_monsters()
        i = pg.monster.findData(sid)
        if i >= 0:
            pg.monster.setCurrentIndex(i)
        pg.refresh()
