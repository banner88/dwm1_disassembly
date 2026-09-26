"""talk_editor.py — per-box NPC talk text with an in-game preview (S97 r2).

What the game does with a talk text (PyBoy-measured S97 r2, TEXT_SYSTEM
"Text boxes"): the box shows TWO lines of 18 cells. The first line of the
first box starts with the "*:" speaker mark, leaving 16 cells. Each box
waits for A (an arrow) and clears before the next one. A line longer than
its cells is wrapped by the engine in the middle of a word, and a third line
scrolls the box without waiting — so text is authored box by box, and each
box shows exactly what the game will draw (ROM font, bank $4F $4010).

S98: the dialog also edits what the talk DOES (editor2/core/talk.py spec):
an optional YES/NO question (the last box ends in the choice box), and per
answer (or once, afterwards) a reply, flags to turn on / off, and moving the
player (a warp: the room reloads, so state rules pick the new state at
once — PyBoy S98: reply shown and waited for, flag set, warp done).
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QColor, QFont, QImage, QPixmap
from PySide6.QtWidgets import (QComboBox, QDialog, QDialogButtonBox, QHBoxLayout,
                               QLabel, QPlainTextEdit, QPushButton, QScrollArea,
                               QToolButton, QVBoxLayout, QWidget)

from editor2.core import textenc as T

# GBC palette 7 as the box shows it: colour 1 = the engine's forced cream
# ($6BFF), colour 3 = black; 0/2 are not used by the font or the frame.
PAL = [QColor(255, 255, 255), QColor(222, 255, 214), QColor(140, 140, 140), QColor(0, 0, 0)]
PAL[1] = QColor((0x1F * 255) // 31, (0x1F * 255) // 31, (0x1A * 255) // 31)
OVER = QColor(230, 40, 40)

# The dialog frame tiles as VRAM holds them while a box is open (PyBoy S97
# r2, $8E00-$8FFF; they are not the font's glyphs at those codes).
FRAME = {c: bytes.fromhex(h) for c, h in {
    0xE0: 'ff00ff00ff00ff00ff00ff00ff00ff00',
    0xEE: 'ff00ff00ff00ff00ff00ffffffffff00',
    0xEF: 'ff00ffffffffff00ff00ff00ff00ff00',
    0xFA: 'ff00ff1fff3fff70ff60ff60ff60ff60',
    0xFB: 'ff00fff8fffcff0eff06ff06ff06ff06',
    0xFC: 'ff60ff60ff60ff60ff70ff3fff1fff00',
    0xFD: 'ff06ff06ff06ff06ff0efffcfff8ff00',
    0xFE: 'ff60ff60ff60ff60ff60ff60ff60ff60',
    0xFF: 'ff06ff06ff06ff06ff06ff06ff06ff06',
}.items()}
SCALE = 2


def _blit(img, tile, tx, ty, tint=None):
    for y in range(8):
        lo, hi = tile[2 * y], tile[2 * y + 1]
        for x in range(8):
            b = 7 - x
            c = ((lo >> b) & 1) | (((hi >> b) & 1) << 1)
            col = PAL[c]
            if tint is not None and c == 3:
                col = tint
            elif tint is not None and c == 1:
                col = QColor(255, 225, 225)
            img.setPixelColor(tx * 8 + x, ty * 8 + y, col)


def _tolerant(s):
    """Glyph codes, unknown characters shown as '?'."""
    out, i = [], 0
    while i < len(s):
        if s.startswith('..', i):
            out.append(0x61)
            i += 2
        else:
            out.append(T.CHARMAP.get(s[i], 0x64))
            i += 1
    return out


def analyse_box(bi, lines):
    """-> (problems, rows) for one box. rows = [(codes, red_from)] per
    authored line; red_from = the cell where the word that crosses the edge
    starts (None when the line fits). PyBoy S97 r2: cells past a line's edge
    wrap to the next line and are overwritten by it — lost — and a third
    line scrolls the box without waiting."""
    problems = []
    rows = []
    if len(lines) > T.BOX_LINES:
        problems.append(f'{len(lines)} lines — a box shows {T.BOX_LINES}; line 3 would '
                        'scroll line 1 away without waiting. Use "Fit" or a new box.')
    for li, ln in enumerate(lines):
        try:
            cs = T.codes(ln)
        except T.TextError as e:
            problems.append(f'line {li + 1}: {e}')
            cs = _tolerant(ln)
        lim = T.line_limit(bi, li)
        if len(cs) > lim:
            pos, cut, room = 0, None, 0
            for w in ln.split(' '):
                wc = len(_tolerant(w))
                if pos + wc > lim:
                    cut, room = w, lim - pos
                    break
                pos += wc + 1
            if cut and 0 < room:
                where = f'"{cut}" would be split: "{cut[:room]}|{cut[room:]}"'
            elif cut:
                where = f'"{cut}" starts past the edge'
            else:
                where = 'text runs past the edge'
            problems.append(f'line {li + 1} is {len(cs)} cells (max {lim}): {where} — '
                            f'the cells past the edge are LOST in the game (it wraps them '
                            f'and the next line overwrites them). Press Enter before it (or Fit).')
            rows.append((cs, pos if cut else lim))
        else:
            rows.append((cs, None))
    return problems, rows


def render_box(rom, bi, lines, scale=SCALE):
    """QPixmap of the box as the game draws it (20x5 tiles); the word that
    crosses an edge is red, and a strip under the box shows (in red) what
    does not fit — lost cells and scrolled-away lines."""
    _p, rows = analyse_box(bi, lines)
    extra = sum(1 for r in rows if r[1] is not None) + max(0, len(rows) - T.BOX_LINES)
    h_tiles = 5 + (2 * extra if extra else 0)
    img = QImage(160, h_tiles * 8, QImage.Format_RGB32)
    img.fill(QColor(40, 40, 40))
    top = [0xFA] + [0xEF] * 18 + [0xFB]
    mid = [0xFE] + [0xE0] * 18 + [0xFF]
    bot = [0xFC] + [0xEE] * 18 + [0xFD]
    for ty, row in enumerate([top, mid, mid, mid, bot]):
        for tx, c in enumerate(row):
            _blit(img, FRAME[c], tx, ty)

    def glyph(code):
        if rom:
            g = T.glyph_2bpp(rom, code)
            if len(g) == 16:
                return g
        return FRAME[0xE0]

    spill = []
    for li, (cs, over) in enumerate(rows):
        seq = (T.SPEAKER + cs) if (bi, li) == (0, 0) else cs
        start = 0
        if li < T.BOX_LINES:
            ty = 1 + 2 * li
            for k, c in enumerate(seq[:18]):
                tint = OVER if over is not None and (k - (2 if (bi, li) == (0, 0) else 0)) >= over else None
                _blit(img, glyph(c), 1 + k, ty, tint)
            start = 18
        if len(seq) > start or li >= T.BOX_LINES:
            spill.append(seq[start:])
    for n, seq in enumerate(spill):
        ty = 5 + 1 + 2 * n
        if ty >= h_tiles:
            break
        for k, c in enumerate(seq[:18]):
            _blit(img, glyph(c), 1 + k, ty, OVER)
    pm = QPixmap.fromImage(img)
    return pm.scaled(pm.width() * scale, pm.height() * scale)


class BoxEditor(QWidget):
    changed = Signal()
    moveRequested = Signal(object, int)
    removeRequested = Signal(object)
    fitRequested = Signal(object)

    def __init__(self, rom, text='', parent=None):
        super().__init__(parent)
        self.rom = rom
        self.index = 0
        h = QHBoxLayout(self)
        h.setContentsMargins(0, 2, 0, 2)
        left = QVBoxLayout()
        self.title = QLabel('')
        self.title.setStyleSheet('font-weight: bold;')
        left.addWidget(self.title)
        self.edit = QPlainTextEdit(text)
        f = QFont('Menlo')
        f.setStyleHint(QFont.Monospace)
        self.edit.setFont(f)
        fm = self.edit.fontMetrics()
        self.edit.setFixedHeight(fm.lineSpacing() * 3 + 14)
        self.edit.setMinimumWidth(fm.horizontalAdvance('M') * 21)
        self.edit.setLineWrapMode(QPlainTextEdit.NoWrap)
        self.edit.textChanged.connect(self._update)
        left.addWidget(self.edit)
        btns = QHBoxLayout()
        for txt, tip, fn in (('▲', 'Move this box up', lambda: self.moveRequested.emit(self, -1)),
                             ('▼', 'Move this box down', lambda: self.moveRequested.emit(self, 1)),
                             ('Fit', 'Word-wrap this box; what does not fit moves to new boxes '
                                     'after it', lambda: self.fitRequested.emit(self)),
                             ('✕', 'Delete this box', lambda: self.removeRequested.emit(self))):
            b = QToolButton()
            b.setText(txt)
            b.setToolTip(tip)
            b.clicked.connect(fn)
            btns.addWidget(b)
            if txt == 'Fit':
                self.fit_btn = b
        btns.addStretch(1)
        left.addLayout(btns)
        h.addLayout(left)
        right = QVBoxLayout()
        self.prev = QLabel()
        self.prev.setAlignment(Qt.AlignLeft | Qt.AlignTop)
        right.addWidget(self.prev)
        self.status = QLabel('')
        self.status.setWordWrap(True)
        self.status.setMaximumWidth(160 * SCALE)
        right.addWidget(self.status)
        right.addStretch(1)
        h.addLayout(right, 1)

    def lines(self):
        ls = self.edit.toPlainText().replace('\r', '').split('\n')
        while ls and not ls[-1].strip():
            ls.pop()
        return [' '.join(ln.split()) for ln in ls]

    def problems(self):
        ls = self.lines()
        if not any(ls):
            return ['empty box']
        return analyse_box(self.index, ls)[0]

    def set_index(self, i):
        self.index = i
        self.title.setText(f'Box {i + 1}' + ('  (starts with "*:" — line 1 has 16 cells)'
                                             if i == 0 else ''))
        self._update()

    def _update(self):
        ls = self.lines() or ['']
        self.prev.setPixmap(render_box(self.rom, self.index, ls))
        probs = self.problems()
        if probs:
            self.status.setText('<span style="color:#ff6060;">' + '<br>'.join(probs) + '</span>')
        else:
            used = [T.cells(ln) for ln in ls]
            lims = [T.line_limit(self.index, k) for k in range(len(ls))]
            self.status.setText('<span style="color:#80d080;">fits — '
                                + ', '.join(f'line {k + 1}: {u}/{m}'
                                            for k, (u, m) in enumerate(zip(used, lims)))
                                + '</span>')
        self.fit_btn.setEnabled(bool(probs) and probs != ['empty box'])
        self.changed.emit()


class BoxList(QWidget):
    """A list of BoxEditors (+ Add box / Fit all, OK-gating summary)."""
    changed = Signal()

    def __init__(self, rom, boxes=None, first_default='Hello!', parent=None):
        super().__init__(parent)
        self.rom = rom
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        self.scroll = QScrollArea()
        self.scroll.setWidgetResizable(True)
        self.holder = QWidget()
        self.lay = QVBoxLayout(self.holder)
        self.lay.addStretch(1)
        self.scroll.setWidget(self.holder)
        v.addWidget(self.scroll, 1)
        row = QHBoxLayout()
        add = QPushButton('+ Add box')
        add.clicked.connect(lambda: self._add('', focus=True))
        row.addWidget(add)
        fit = QPushButton('Fit all')
        fit.setToolTip('Word-wrap every box that does not fit (overflow moves to new boxes)')
        fit.clicked.connect(self._fit_all)
        row.addWidget(fit)
        row.addStretch(1)
        self.summary = QLabel('')
        row.addWidget(self.summary)
        v.addLayout(row)
        self.editors = []
        start = boxes if boxes is not None else ([[first_default]] if first_default else [])
        for b in start:
            self._add('\n'.join(b))
        self._renumber()

    def _add(self, text, at=None, focus=False):
        ed = BoxEditor(self.rom, text)
        ed.changed.connect(self._validate)
        ed.moveRequested.connect(self._move)
        ed.removeRequested.connect(self._remove)
        ed.fitRequested.connect(self._fit)
        at = len(self.editors) if at is None else at
        self.editors.insert(at, ed)
        self.lay.insertWidget(at, ed)
        self._renumber()
        if focus:
            ed.edit.setFocus()
            self.scroll.ensureWidgetVisible(ed)
        return ed

    def _renumber(self):
        for i, ed in enumerate(self.editors):
            self.lay.removeWidget(ed)
            self.lay.insertWidget(i, ed)
            ed.set_index(i)
        self._validate()

    def _move(self, ed, d):
        i = self.editors.index(ed)
        j = i + d
        if 0 <= j < len(self.editors):
            self.editors[i], self.editors[j] = self.editors[j], self.editors[i]
            self._renumber()

    def _remove(self, ed):
        if len(self.editors) <= 1:
            ed.edit.setPlainText('')
            return
        self.editors.remove(ed)
        self.lay.removeWidget(ed)
        ed.deleteLater()
        self._renumber()

    def _fit(self, ed):
        """Re-wrap one box; lines past the box go into new boxes after it."""
        i = self.editors.index(ed)
        text = ' '.join(ln for ln in ed.lines() if ln)
        try:
            boxes = T.flow_boxes(text, first_box=(i == 0))
        except T.TextError:
            return
        if not boxes:
            return
        ed.edit.setPlainText('\n'.join(boxes[0]))
        for k, b in enumerate(boxes[1:], 1):
            self._add('\n'.join(b), at=i + k)
        self._renumber()

    def _fit_all(self):
        for ed in list(self.editors):
            if ed.problems() and ed.problems() != ['empty box']:
                self._fit(ed)

    def bad_boxes(self):
        return [i + 1 for i, ed in enumerate(self.editors) if ed.problems()]

    def is_blank(self):
        return all(not any(ed.lines()) for ed in self.editors)

    def _validate(self):
        bad = self.bad_boxes()
        n = len(self.editors)
        if bad:
            self.summary.setText(f'<span style="color:#ff6060;">{n} box(es) — fix box '
                                 + ', '.join(map(str, bad)) + '</span>')
        else:
            self.summary.setText(f'{n} box(es) — all fit')
        self.changed.emit()

    def boxes(self):
        return [[ln for ln in ed.lines()] for ed in self.editors]


class FlagList(QWidget):
    """Flags to set / clear: project flags, well-known vanilla story flags or
    any number, plus 'New flag…' (auto-allocated project flag)."""
    changed = Signal()

    def __init__(self, doc, title, flags=None, parent=None):
        super().__init__(parent)
        from PySide6.QtWidgets import QListWidget
        self.doc = doc
        self.new_flags = []
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        v.addWidget(QLabel(title))
        self.list = QListWidget()
        self.list.setMaximumHeight(70)
        for f in flags or []:
            self.list.addItem(str(f))
        v.addWidget(self.list)
        row = QHBoxLayout()
        self.pick = QComboBox()
        self.pick.setEditable(True)
        self.pick.setMinimumContentsLength(16)
        self._fill_pick()
        row.addWidget(self.pick, 1)
        b = QToolButton()
        b.setText('Add')
        b.clicked.connect(self._add)
        row.addWidget(b)
        b = QToolButton()
        b.setText('New flag…')
        b.setToolTip('A project flag, auto-allocated from the safe pool (saved with the game).')
        b.clicked.connect(self._new)
        row.addWidget(b)
        b = QToolButton()
        b.setText('Remove')
        b.clicked.connect(self._remove)
        row.addWidget(b)
        v.addLayout(row)

    def _fill_pick(self):
        from editor2.app.rooms.rules_panel import WELL_KNOWN
        self.pick.clear()
        if self.doc is not None:
            for fl in self.doc.flags():
                self.pick.addItem(f"{fl['name']}  (project flag)", fl['name'])
        for nm in self.new_flags:
            self.pick.addItem(f'{nm}  (new project flag)', nm)
        for idx, name in WELL_KNOWN:
            self.pick.addItem(f'{idx}  {name}', idx)
        self.pick.setToolTip('A project flag, or any event flag number (e.g. 0x0030). '
                             'EVENT_FLAGS.md lists the vanilla story flags.')

    def _value(self):
        d = self.pick.currentData()
        txt = self.pick.currentText().strip()
        if d is not None and self.pick.itemText(self.pick.currentIndex()) == txt:
            return d
        return txt.split()[0] if txt else None

    def _add(self):
        v = self._value()
        if v and v not in self.flags():
            self.list.addItem(str(v))
            self.changed.emit()

    def _new(self):
        from PySide6.QtWidgets import QInputDialog, QMessageBox
        name, ok = QInputDialog.getText(self, 'New flag', 'Flag name (letters, digits, _):')
        if not ok or not name.strip():
            return
        nm = self.doc._slug(name.strip()) if self.doc is not None else name.strip()
        if not nm:
            QMessageBox.warning(self, 'New flag', 'Use letters, digits and _.')
            return
        known = {fl['name'] for fl in (self.doc.flags() if self.doc else [])}
        if nm not in known and nm not in self.new_flags:
            self.new_flags.append(nm)
            self._fill_pick()
        if nm not in self.flags():
            self.list.addItem(nm)
        self.changed.emit()

    def _remove(self):
        r = self.list.currentRow()
        if r < 0:
            r = self.list.count() - 1
        if r >= 0:
            self.list.takeItem(r)
            self.changed.emit()

    def flags(self):
        return [self.list.item(i).text() for i in range(self.list.count())]


class BlockEditor(QWidget):
    """What happens after the text (or after YES / NO): an optional reply,
    flags to set / clear, and optionally moving the player (a warp: the
    room reloads, so state rules pick the new state at once)."""
    changed = Signal()

    def __init__(self, rom, doc=None, room=None, block=None, key=0, parent=None):
        super().__init__(parent)
        from PySide6.QtWidgets import QCheckBox, QGroupBox, QSpinBox
        from editor2.core.talk import empty_block
        self.doc, self.room = doc, room
        b = block or empty_block()
        v = QVBoxLayout(self)
        self.say = QCheckBox('Say something')
        self.say.setChecked(bool(b.get('boxes')))
        v.addWidget(self.say)
        self.reply = BoxList(rom, b.get('boxes') or None, first_default='OK.')
        self.reply.setMinimumHeight(140)
        self.reply.setVisible(self.say.isChecked())
        self.say.toggled.connect(self.reply.setVisible)
        self.say.toggled.connect(lambda _on: self.changed.emit())
        self.reply.changed.connect(self.changed.emit)
        v.addWidget(self.reply, 1)
        row = QHBoxLayout()
        self.set_list = FlagList(doc, 'Turn these flags ON:', b.get('set'))
        self.clear_list = FlagList(doc, 'Turn these flags OFF:', b.get('clear'))
        for fl in (self.set_list, self.clear_list):
            fl.changed.connect(self.changed.emit)
            row.addWidget(fl)
        v.addLayout(row)
        mg = QGroupBox('Then move the player (reloads the room — state rules pick the new state)')
        mg.setCheckable(True)
        mv = b.get('move')
        mg.setChecked(bool(mv))
        mf = QHBoxLayout(mg)
        self.m_room = QComboBox()
        if doc is not None:
            for r in doc.rooms:
                if r.get('placeholder'):
                    continue
                self.m_room.addItem(f"${int(str(r['mapID']), 0):02X} {doc.room_name(r)}",
                                    f"room:${int(str(r['mapID']), 0):02X}")
        self.m_screen = QSpinBox(); self.m_screen.setRange(0, 15)
        self.m_x = QSpinBox(); self.m_x.setRange(0, 9)
        self.m_y = QSpinBox(); self.m_y.setRange(0, 7)
        for lab, w in (('room', self.m_room), ('screen', self.m_screen),
                       ('x', self.m_x), ('y', self.m_y)):
            mf.addWidget(QLabel(lab))
            mf.addWidget(w)
        self.move_group = mg
        if mv:
            i = self.m_room.findData(mv.get('dest'))
            if i < 0:
                self.m_room.addItem(str(mv.get('dest')), mv.get('dest'))
                i = self.m_room.count() - 1
            self.m_room.setCurrentIndex(i)
            self.m_screen.setValue(int(mv.get('screen', 0)))
            self.m_x.setValue(int(mv.get('x', 0)))
            self.m_y.setValue(int(mv.get('y', 0)))
        elif room is not None:
            i = self.m_room.findData(f"room:${int(str(room['mapID']), 0):02X}")
            self.m_room.setCurrentIndex(max(i, 0))
            self.m_screen.setValue(int(key))
        v.addWidget(mg)

    def ok(self):
        return not (self.say.isChecked() and self.reply.bad_boxes())

    def block(self):
        b = {'boxes': self.reply.boxes() if self.say.isChecked() and not self.reply.is_blank()
             else [],
             'set': self.set_list.flags(), 'clear': self.clear_list.flags(), 'move': None}
        if self.move_group.isChecked() and self.m_room.currentData():
            b['move'] = {'dest': self.m_room.currentData(), 'screen': self.m_screen.value(),
                         'x': self.m_x.value(), 'y': self.m_y.value()}
        return b

    def new_flags(self):
        return self.set_list.new_flags + [f for f in self.clear_list.new_flags
                                          if f not in self.set_list.new_flags]


class TalkDialog(QDialog):
    """What an NPC / examine spot / step trigger says and does (S98; the
    per-box text editor is S97 r2). Text as boxes; optionally a YES/NO
    question (the last box is the question); then, per answer (or once):
    a reply, flags to turn on/off, and optionally moving the player.
    `spec()` returns the talk spec (editor2/core/talk.py)."""

    def __init__(self, boxes=None, title='What does this NPC say?', rom=None, parent=None,
                 spec=None, doc=None, room=None, key=0):
        super().__init__(parent)
        from PySide6.QtWidgets import QCheckBox, QTabWidget
        self.setWindowTitle(title)
        self.rom = rom
        self.doc = doc
        self.resize(820, 720)
        spec = spec or {}
        if boxes is None:
            boxes = spec.get('boxes')
        v = QVBoxLayout(self)
        intro = QLabel('Each box shows 2 lines and waits for A before the next box. '
                       'Line 1 of box 1 has 16 cells (after "*:"), every other line 18. '
                       'Press Enter to start the second line. Red = does not fit (the game '
                       'loses the cells past the edge, a third line scrolls without waiting). Letters, digits, '
                       "space and . , ; ! ? ' only.")
        intro.setWordWrap(True)
        v.addWidget(intro)
        self.box_list = BoxList(rom, boxes)
        self.box_list.changed.connect(self._validate)
        v.addWidget(self.box_list, 3)
        self.question = QCheckBox('Ask YES / NO after the text (the last box is the question)')
        self.question.setChecked(bool(spec.get('question')))
        v.addWidget(self.question)
        self.tabs = QTabWidget()
        self.then = BlockEditor(rom, doc, room, spec.get('then'), key)
        self.yes = BlockEditor(rom, doc, room, spec.get('yes'), key)
        self.no = BlockEditor(rom, doc, room, spec.get('no'), key)
        for be in (self.then, self.yes, self.no):
            be.changed.connect(self._validate)
        v.addWidget(self.tabs, 2)
        self.question.toggled.connect(self._tabs)
        self._tabs(self.question.isChecked())
        self.bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        self.bb.accepted.connect(self.accept)
        self.bb.rejected.connect(self.reject)
        v.addWidget(self.bb)
        self._validate()

    def _tabs(self, q):
        while self.tabs.count():
            self.tabs.removeTab(0)
        if q:
            self.tabs.addTab(self.yes, 'If YES')
            self.tabs.addTab(self.no, 'If NO')
        else:
            self.tabs.addTab(self.then, 'Afterwards')
        self._validate()

    def _validate(self):
        if not hasattr(self, 'bb'):
            return
        ok = not self.box_list.bad_boxes()
        blocks = (self.yes, self.no) if self.question.isChecked() else (self.then,)
        ok = ok and all(b.ok() for b in blocks)
        self.bb.button(QDialogButtonBox.Ok).setEnabled(ok)

    # the S97 API (tests stub this one)
    def boxes(self):
        return self.box_list.boxes()

    def spec(self):
        from editor2.core.talk import empty_block
        q = self.question.isChecked()
        return {'boxes': self.boxes(), 'question': q,
                'then': empty_block() if q else self.then.block(),
                'yes': self.yes.block() if q else empty_block(),
                'no': self.no.block() if q else empty_block()}

    def new_flags(self):
        out = []
        for b in (self.then, self.yes, self.no):
            for f in b.new_flags():
                if f not in out:
                    out.append(f)
        return out
