"""talk_editor.py — per-box NPC talk text with an in-game preview (S97 r2).

What the game does with a talk text (PyBoy-measured S97 r2, TEXT_SYSTEM
"Text boxes"): the box shows TWO lines of 18 cells. The first line of the
first box starts with the "*:" speaker mark, leaving 16 cells. Each box
waits for A (an arrow) and clears before the next one. A line longer than
its cells is wrapped by the engine in the middle of a word, and a third line
scrolls the box without waiting — so text is authored box by box, and each
box shows exactly what the game will draw (ROM font, bank $4F $4010).
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QColor, QFont, QImage, QPixmap
from PySide6.QtWidgets import (QDialog, QDialogButtonBox, QHBoxLayout, QLabel,
                               QPlainTextEdit, QPushButton, QScrollArea,
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


class TalkDialog(QDialog):
    """Talk text as a list of boxes. Enter = next line of the same box;
    each box waits for A in the game. The preview is the game's own font."""

    def __init__(self, boxes=None, title='What does this NPC say?', rom=None, parent=None):
        super().__init__(parent)
        self.setWindowTitle(title)
        self.rom = rom
        self.resize(760, 560)
        v = QVBoxLayout(self)
        intro = QLabel('Each box shows 2 lines and waits for A before the next box. '
                       'Line 1 of box 1 has 16 cells (after "*:"), every other line 18. '
                       'Press Enter to start the second line. Red = does not fit (the game '
                       'loses the cells past the edge, a third line scrolls without waiting). Letters, digits, '
                       "space and . , ; ! ? ' only.")
        intro.setWordWrap(True)
        v.addWidget(intro)
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
        self.bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        self.bb.accepted.connect(self.accept)
        self.bb.rejected.connect(self.reject)
        v.addWidget(self.bb)
        self.editors = []
        for b in (boxes or [['Hello!']]):
            self._add('\n'.join(b))
        self._renumber()

    # ------------------------------------------------------------ boxes
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

    def _validate(self):
        bad = [i + 1 for i, ed in enumerate(self.editors) if ed.problems()]
        n = len(self.editors)
        if bad:
            self.summary.setText(f'<span style="color:#ff6060;">{n} box(es) — fix box '
                                 + ', '.join(map(str, bad)) + '</span>')
        else:
            self.summary.setText(f'{n} box(es) — all fit')
        self.bb.button(QDialogButtonBox.Ok).setEnabled(not bad)

    def boxes(self):
        return [[ln for ln in ed.lines()] for ed in self.editors]
