"""draw_tab.py — the Draw tab (Tiles page, after Animate; S132).

User S132: "Allow editing tiles by pixel - maybe past the animate button on
right panel?" — and both ways of applying a drawing. Load a cell (or the
brush, or a blank tile), paint its four 8×8 quarters in their own palettes,
then either redraw those tiles EVERYWHERE they are drawn, or save the drawing
as a NEW metatile (free slots; placed on the selected cells / every cell of
the room drawing the original / nowhere). The tab only shows facts and emits
requests; editor2/core/tile_draw.py does the work (one undo step each, pushed
by the Rooms tab).

S171 r4 (user: "Draw … doesnt allow all colours of the tileset? E.g. greattree tileset
includes blue but I don't see it … just give me the current valid colours and I can work
within that universe"): the colour grid shows ALL FOUR ROWS of the room's colours. An 8x8
quarter is drawn in one row (the hardware), so painting a quarter with a colour of
another row MOVES that quarter to that row — its other pixels take the closest colours
there (recolour.dist). The quarters' rows travel with the drawing: "as a new metatile"
saves them; "everywhere" is refused once a row changed (other cells drawing those tiles
keep their rows) — save it as a new metatile on every cell drawing the original instead.

S171 r6 (user: "Why cant I undo 'draw' on cell? Also why does it just make a whole quarter
a blank colour instead of filling in or doing pixel by pixel?"; "I will never want to
change the actual structure, only RECOLOR ALL PIXELS THAT ARE EXACTLY THE SAME COLOUR. Only
me clicking individual pixels should change STRUCTURE"): a quarter moved to another row
KEEPS every pixel's colour number (r4 renumbered them to the closest colours — two colours
could become one, a whole quarter one flat colour); then the clicked pixel is painted.
Tools: "row ▸ 0-3" moves the part to a row (numbers kept), "swap a ⇄ b" exchanges two colour
numbers in the part (all pixels of one colour become the other and back) — neither changes
a shape. Cmd+Z / Cmd+Shift+Z undo / redo strokes while a drawing is loaded and the tab is
shown (the main window asks `owns_undo()`), the Redo button too.

S171 r7 (user: "why does clicking on some pixels change that pixel and clicking on other
pixels change the entire regions? … I click on black and it recolours other colours? Does
it get identity from the original tile and not from current drawing window …"; then "Yes I
want that"): painting NEVER moves a quarter to another row any more — a quarter is painted
with the colours of its own row (another row's colour that the quarter's row also has, like
black or cream, paints as that one; any other is refused with a hint); the other rows'
swatches are dimmed for the quarter last clicked; right-click picks the clicked pixel's own
row; a quarter changes row only with the *row 0-3* buttons; the room's palette edits reach
the drawing at once (`set_rows`); *Recolour* (click a colour in the drawing, then a swatch)
turns every pixel of that colour in the part into the colour picked — it replaces the six
numbered swap buttons.
"""

from PySide6.QtCore import Qt, QTimer, Signal
from PySide6.QtGui import QColor
from PySide6.QtWidgets import (QCheckBox, QComboBox, QFrame, QGridLayout,
                               QGroupBox, QHBoxLayout, QLabel, QLineEdit,
                               QPushButton, QToolButton, QVBoxLayout, QWidget)

from editor2.app.rooms.animate_tab import FramePad
from editor2.app.qt_safe import combo_row_enabled            # S167

PARTS = ('whole', 0, 1, 2, 3)
PART_TEXT = {'whole': 'Whole', 0: '◤', 1: '◥', 2: '◣', 3: '◢'}


def _wrap(text, style=None):
    l = QLabel(text)
    l.setWordWrap(True)
    if style:
        l.setStyleSheet(style)
    return l


class DrawTab(QWidget):
    loadCellRequested = Signal()
    loadBrushRequested = Signal()
    blankRequested = Signal(int)                 # palette slot
    everywhereRequested = Signal(object)         # {'mt', 'old', 'new'}
    newRequested = Signal(object)                # {'mt', 'new', 'walkable', 'name', 'place', 'pal'}
    status = Signal(str)
    historyChanged = Signal()                    # S171 r6: the stroke history changed

    def __init__(self, parent=None):
        super().__init__(parent)
        self.mt = None                 # the metatile being drawn (dict)
        self.old = None                # its 4 quarters as loaded
        self.pals = None               # 4 rows of RGB (per quarter)
        self.rows = None               # S171 r4: the room's 4 rows of RGB
        self.qrow = None               # S171 r4: the row of each quarter
        self.old_qrow = None
        self.cur_row = 0               # the row of the colour picked
        self.reporter = None           # set by the tab: (new px, walkable) -> report
        self.can_place_sel = False
        self.part = 'whole'
        self._undo = []
        self._redo = []                  # S171 r6
        self._clip = None
        v = QVBoxLayout(self)
        v.setContentsMargins(6, 6, 6, 6)
        v.addWidget(_wrap('<b>Draw a tile pixel by pixel.</b> ① load one, ② paint (left = '
                          'paint, Shift = fill, right = pick a colour, Ctrl+click = pick a '
                          'quarter for the tools), ③ apply it — everywhere it is drawn, or as '
                          'a new metatile.'))
        # ① load
        row = QHBoxLayout()
        for text, sig, tip in (('Load the selected cell', self.loadCellRequested,
                                'the metatile of the cell selected on the canvas (Select tool)'),
                               ('Load the brush', self.loadBrushRequested,
                                'the metatile you paint with now')):
            b = QPushButton(text)
            b.setToolTip(tip)
            b.clicked.connect(sig.emit)
            row.addWidget(b)
        self.blank_pal = QComboBox()
        for p in range(4):
            self.blank_pal.addItem(f'colours {p}', p)
        self.blank_pal.setToolTip('the palette slot a blank tile is drawn in')
        row.addStretch(1)
        v.addLayout(row)
        row = QHBoxLayout()
        b = QPushButton('New blank tile in')
        b.setToolTip('start from an empty tile in the chosen palette slot')
        b.clicked.connect(lambda: self.blankRequested.emit(self.blank_pal.currentData()))
        row.addWidget(b)
        row.addWidget(self.blank_pal)
        row.addStretch(1)
        v.addLayout(row)
        self.head = _wrap('Nothing loaded yet.', 'color: #aaa;')
        v.addWidget(self.head)
        # ② paint
        mid = QHBoxLayout()
        self.pad = FramePad()
        self.pad.set_zoom(13)
        self.pad.pre_put = self._pre_put           # S171 r4 / r7
        self.pad.click_hook = self._recolour_click  # S171 r7
        self.pad.aboutToChange.connect(self._snap)
        self.pad.changed.connect(self._changed)
        self.pad.picked.connect(self._set_colour)
        self.pad.tileClicked.connect(self._quarter_clicked)
        self.pad.partPicked.connect(lambda k, _w: self._set_part(k))
        mid.addWidget(self.pad, 0, Qt.AlignTop)
        tcol = QVBoxLayout()
        tcol.addWidget(QLabel('as it tiles'))
        self.tiled = QLabel()
        self.tiled.setFixedSize(3 * 16 * 2, 3 * 16 * 2)
        self.tiled.setStyleSheet('background: #202024;')
        tcol.addWidget(self.tiled)
        tcol.addStretch(1)
        mid.addLayout(tcol)
        mid.addStretch(1)
        v.addLayout(mid)
        side = QVBoxLayout()
        side.addWidget(_wrap('colour — every row of the room. A quarter is painted with its '
                             'own row\'s colours (the others are dimmed); the row buttons below '
                             'move it to another row.'))
        self.swatches = {}                 # (row, index) -> button
        self.row_labels = []
        sw = QGridLayout()
        sw.setHorizontalSpacing(3)
        sw.setVerticalSpacing(3)
        for r in range(4):
            lab = QLabel(f'row {r}')
            self.row_labels.append(lab)
            sw.addWidget(lab, r, 0)
            for i in range(4):
                b = QToolButton()
                b.setFixedSize(26, 26)
                b.setCheckable(True)
                b.clicked.connect(lambda _c=False, rr=r, k=i: self._pick_swatch(rr, k))
                sw.addWidget(b, r, 1 + i)
                self.swatches[(r, i)] = b
        sw.setColumnStretch(5, 1)
        side.addLayout(sw)
        self.sw_note = _wrap('', 'color: #888;')
        side.addWidget(self.sw_note)
        side.addWidget(QLabel('tools act on'))
        pr = QHBoxLayout()
        self.part_btns = {}
        for part in PARTS:
            b = QToolButton()
            b.setText(PART_TEXT[part])
            b.setCheckable(True)
            b.clicked.connect(lambda _c=False, k=part: self._set_part(k))
            pr.addWidget(b)
            self.part_btns[part] = b
        pr.addStretch(1)
        side.addLayout(pr)
        grid = QGridLayout()
        tools = (('Flip ↔', 'flip_h'), ('Flip ↕', 'flip_v'), ('Shift ◀', 'left'),
                 ('Shift ▶', 'right'), ('Shift ▲', 'up'), ('Shift ▼', 'down'),
                 ('Copy', 'copy'), ('Paste', 'paste'), ('Clear', 'clear'),
                 ('Undo', 'undo'), ('Redo', 'redo'), ('Revert', 'revert'))
        for i, (text, key) in enumerate(tools):
            b = QPushButton(text)
            if key in ('undo', 'redo'):
                b.setToolTip(f'{text} the last stroke or tool (also ⌘{"Z" if key == "undo" else "⇧Z"} '
                             'while a drawing is loaded)')
            b.clicked.connect(lambda _c=False, k=key: self._tool(k))
            grid.addWidget(b, i // 4, i % 4)
        side.addLayout(grid)
        # S171 r6: recolour without touching a shape
        side.addWidget(_wrap('recolour the part — shapes stay as they are:', 'color: #888;'))
        rc = QHBoxLayout()
        self.recolour_btn = QPushButton('Recolour…')
        self.recolour_btn.setCheckable(True)
        self.recolour_btn.setToolTip(
            'Click a colour in the drawing, then a colour swatch: every pixel of that colour in '
            'the part (the whole tile or the quarter picked above) becomes the colour you picked.')
        self.recolour_btn.toggled.connect(self._recolour_toggled)
        rc.addWidget(self.recolour_btn)
        rc.addStretch(1)
        side.addLayout(rc)
        self._recolour_src = None          # S171 r7: (quarter, colour number) clicked
        rr = QHBoxLayout()
        rr.addWidget(QLabel('row'))
        self.row_btns = []
        for r in range(4):
            b = QPushButton(str(r))
            b.setFixedWidth(34)
            b.setToolTip(f'put the part in row {r} — every pixel keeps its colour number, so '
                         'it shows the same picture in that row\'s colours (no new slot)')
            b.clicked.connect(lambda _c=False, rr_=r: self._tool(('row', rr_)))
            rr.addWidget(b)
            self.row_btns.append(b)
        rr.addStretch(1)
        side.addLayout(rr)
        v.addLayout(side)
        # ③ apply
        ga = QGroupBox('③ Apply')
        al = QVBoxLayout(ga)
        self.ev_btn = QPushButton('Redraw it everywhere it is drawn')
        self.ev_btn.clicked.connect(self._everywhere)
        al.addWidget(self.ev_btn)
        self.ev_note = _wrap('', 'color: #e0b040;')
        al.addWidget(self.ev_note)
        line = QFrame()
        line.setFrameShape(QFrame.HLine)
        al.addWidget(line)
        nr = QHBoxLayout()
        nr.addWidget(QLabel('name'))
        self.name = QLineEdit('drawn')
        nr.addWidget(self.name, 1)
        al.addLayout(nr)
        nr = QHBoxLayout()
        self.walkable = QCheckBox('walkable (unticked = a wall)')
        self.walkable.setToolTip('the new metatile\'s bottom-right quarter goes to the walkable '
                                 '(or wall) side of the tileset — it decides walkability')
        self.walkable.toggled.connect(lambda _on: self._schedule())
        nr.addWidget(self.walkable)
        al.addLayout(nr)
        pl = QHBoxLayout()
        pl.addWidget(QLabel('put it on'))
        self.place = QComboBox()
        self.place.addItem('nothing — only add it to My metatiles', None)
        self.place.addItem('the selected cell(s)', 'selection')
        self.place.addItem('every cell of this room drawing the original', 'room')
        pl.addWidget(self.place, 1)
        al.addLayout(pl)
        self.new_btn = QPushButton('Save as a new metatile')
        self.new_btn.clicked.connect(self._new)
        al.addWidget(self.new_btn)
        self.new_note = _wrap('', 'color: #7fe07f;')
        al.addWidget(self.new_note)
        v.addWidget(ga)
        v.addStretch(1)
        self._timer = QTimer(self)
        self._timer.setSingleShot(True)
        self._timer.setInterval(150)
        self._timer.timeout.connect(self._update_report)
        self._set_part('whole')
        self._set_colour(3)
        self._set_enabled(False)

    # ------------------------------------------------------------ load
    def load(self, mt, px, pals, desc, walkable=True, selection_ok=False, rows=None,
             qrow=None):
        """mt = metatile dict, px = 4 quarters of 64 colour numbers, pals =
        4 palette rows of RGB (the quarters' palettes), desc = where from.
        S171 r4: rows = the room's 4 rows, qrow = each quarter's row."""
        self.mt = {'tiles': list(mt['tiles']), 'pal': mt.get('pal', 0),
                   'name': mt.get('name')}
        self.old = [list(q) for q in px]
        self.rows = [list(r) for r in (rows or pals)]
        if qrow is None:                 # the row whose colours each quarter shows
            qrow = [next((r for r in range(len(self.rows)) if self.rows[r] == list(p)), 0)
                    for p in pals]
        self.qrow = list(qrow)
        self.old_qrow = list(self.qrow)
        self.pals = [list(self.rows[r]) for r in self.qrow]
        self._undo = []
        self._redo = []
        self.historyChanged.emit()
        self.pad.set_frame(2, 2, self.old, self.pals, editable=True)
        self.walkable.blockSignals(True)
        self.walkable.setChecked(bool(walkable))
        self.walkable.blockSignals(False)
        self.can_place_sel = selection_ok
        combo_row_enabled(self.place, 1, selection_ok)      # S167: no item wrapper
        if not selection_ok and self.place.currentData() == 'selection':
            self.place.setCurrentIndex(0)
        tiles = ' '.join(f'${t:02X}' for t in self.mt['tiles'])
        self.head.setText(f'{desc} — tiles {tiles}, palette {self.mt["pal"]}, '
                          + ('walkable' if walkable else 'wall'))
        self.head.setStyleSheet('')
        self._set_enabled(True)
        self._quarter_clicked(0)
        self._changed()

    def loaded(self):
        return self.mt is not None

    def current(self):
        return [list(q) for q in self.pad.px]

    def rows_changed(self):
        return self.qrow is not None and self.qrow != self.old_qrow

    def pal_value(self):
        """The quarters' rows as a metatile 'pal' (int when all four are equal)."""
        q = list(self.qrow or [0, 0, 0, 0])
        return q[0] if len(set(q)) == 1 else q

    def _set_enabled(self, on):
        for w in (self.pad, self.ev_btn, self.new_btn, self.name, self.walkable, self.place):
            w.setEnabled(on)

    # ------------------------------------------------------------ paint
    def _set_colour(self, i):
        """Colour number `i` of the clicked quarter's row (the right-click pick; S171 r7:
        the pad's tileClicked came first, so _sw_quarter is the quarter clicked)."""
        k = getattr(self, '_sw_quarter', 0)
        row = self.qrow[k] if self.qrow else self.cur_row
        self._pick_swatch(row, i)

    def _pick_swatch(self, row, i):
        if self._recolour_src is not None:          # S171 r7: Recolour's second click
            self._recolour_to(row, i)
            return
        self.cur_row, self.pad.colour = row, i
        for (r, k), b in self.swatches.items():
            b.setChecked(r == row and k == i)

    # ---- S171 r7: rows follow the palette; Recolour
    def set_rows(self, rows):
        """The room's 4 rows changed (the Palettes page): the drawing shows them at once."""
        if self.mt is None or not rows:
            return
        rows = [list(r) for r in rows[:4]]
        if rows == self.rows[:4]:
            return
        self.rows = rows + self.rows[4:]
        self.pals = [list(self.rows[r]) for r in self.qrow]
        self.pad.pals = self.pals
        self._paint_swatches()
        self.pad.update()
        self._changed()

    def _own_colour(self, k, row, i):
        """The colour number in quarter k's row that IS colour i of `row` (same RGB), or
        None."""
        if not self.qrow or not self.rows:
            return i
        mine = self.qrow[k]
        if row == mine:
            return i
        want = tuple(self.rows[row][i][:3])
        own = [tuple(c[:3]) for c in self.rows[mine]]
        if want not in own:
            return None
        return i if own[i] == want else own.index(want)

    def _recolour_toggled(self, on):
        self._recolour_src = None
        if on:
            self.status.emit('Recolour: click a colour in the drawing (inside the part: '
                             + ('the whole tile' if self.part == 'whole' else 'the quarter')
                             + ')')

    def _recolour_click(self, xy):
        if not self.recolour_btn.isChecked() or self.mt is None:
            return False
        k = (xy[1] // 8) * 2 + xy[0] // 8
        if k not in self._parts():
            self.status.emit('Recolour: that pixel is outside the part — pick the whole tile or '
                             'that quarter under "tools act on"')
            return True
        self._recolour_src = (k, self.pad.get(*xy))
        r = self.qrow[k]
        self.status.emit(f'Recolour: colour {self._recolour_src[1]} of row {r} — now click the '
                         'swatch it should become')
        return True

    def _recolour_to(self, row, i):
        k, a = self._recolour_src
        self._recolour_src = None
        self.recolour_btn.setChecked(False)
        src_rgb = tuple(self.rows[self.qrow[k]][a][:3])
        self._snap()
        px = self.current()
        done, skipped = 0, []
        for q in self._parts():
            own = [tuple(c[:3]) for c in self.rows[self.qrow[q]]]
            if src_rgb not in own:
                continue
            b = self._own_colour(q, row, i)
            if b is None:
                skipped.append(q)
                continue
            hits = {n for n, c in enumerate(own) if c == src_rgb}
            new = [b if v in hits else v for v in px[q]]
            done += sum(1 for x, y in zip(px[q], new) if x != y)
            px[q] = new
        self.pad.px = px
        self.pad.update()
        self._changed()
        names = ('top-left', 'top-right', 'bottom-left', 'bottom-right')
        msg = f'Recolour: {done} pixel(s) changed'
        if skipped:
            msg += (' — not in the ' + ', '.join(names[q] for q in skipped)
                    + f' quarter: row {row}\'s colour is not in its row (move it with the row '
                    'buttons first)')
        self.status.emit(msg)

    def _paint_swatches(self):
        k = getattr(self, '_sw_quarter', None)
        mine = self.qrow[k] if (k is not None and self.qrow) else None
        own = {tuple(c[:3]) for c in self.rows[mine]} if mine is not None and self.rows else set()
        for (r, i), b in self.swatches.items():
            if not self.rows or r >= len(self.rows):
                b.setStyleSheet('')
                continue
            c = QColor(*self.rows[r][i])
            # S171 r7: a colour the clicked quarter cannot use is dimmed
            usable = mine is None or r == mine or tuple(self.rows[r][i][:3]) in own
            if not usable:
                g = QColor(70, 70, 76)
                c = QColor((c.red() + 2 * g.red()) // 3, (c.green() + 2 * g.green()) // 3,
                           (c.blue() + 2 * g.blue()) // 3)
            border = '1px solid #555' if usable else '1px dashed #333'
            b.setStyleSheet(f'QToolButton {{ background: {c.name()}; border: {border}; }}'
                            f'QToolButton:checked {{ border: 3px solid #ffe000; }}')

    def _quarter_clicked(self, k):
        if not self.pals:
            return
        self._sw_quarter = k
        self._paint_swatches()
        r = self.qrow[k] if self.qrow else 0
        for rr, lab in enumerate(self.row_labels):
            lab.setStyleSheet('font-weight: bold; color: #ffe000;' if rr == r else '')
        self.sw_note.setText(f'the {("top-left", "top-right", "bottom-left", "bottom-right")[k]} '
                             f'quarter is in row {r} — it is painted with row {r}\'s colours '
                             '(the dimmed ones are not in its row). Another row: "tools act on" '
                             'that quarter, then a row button.')

    def _pre_put(self, k, colour):
        """The colour number to paint into quarter `k` (S171 r7): a quarter is painted
        with its OWN row — another row's colour that its row also has (black, cream…) paints
        as that one; any other is refused (None) with a hint. (r4 / r6 moved the whole
        quarter to the colour's row: "clicking on other pixels change the entire regions".)"""
        if not self.qrow or self.cur_row >= len(self.rows or []):
            return colour
        got = self._own_colour(k, self.cur_row, colour)
        if got is None:
            names = ('top-left', 'top-right', 'bottom-left', 'bottom-right')
            self.status.emit(f'Draw: the {names[k]} quarter is in row {self.qrow[k]} and that '
                             f'colour is only in row {self.cur_row} — pick a colour of row '
                             f'{self.qrow[k]}, or move the quarter with the row buttons '
                             '(tools act on that quarter, then "row ' + str(self.cur_row) + '")')
        return got

    def _move_row(self, k, row):
        self.qrow[k] = row
        self.pals[k] = list(self.rows[row])
        self.pad.pals = self.pals

    def _set_part(self, part):
        self.part = part
        for k, b in self.part_btns.items():
            b.setChecked(k == part)
        if part == 'whole':
            self.pad.part_rect = None
        else:
            self.pad.part_rect = ((part % 2) * 8, (part // 2) * 8, 8, 8)
        self.pad.update()

    def _snap(self):
        self._undo.append((self.current(), list(self.qrow or [])))
        del self._undo[:-100]
        self._redo = []
        self.historyChanged.emit()

    # S171 r6: the main window's ⌘Z / ⌘⇧Z come here while this tab owns them
    def owns_undo(self):
        return self.mt is not None and self.isVisibleTo(self.window())

    def can_undo(self):
        return bool(self._undo)

    def can_redo(self):
        return bool(self._redo)

    def undo(self):
        self._tool('undo')

    def redo(self):
        self._tool('redo')

    def showEvent(self, ev):
        super().showEvent(ev)
        self.historyChanged.emit()

    def hideEvent(self, ev):
        super().hideEvent(ev)
        self.historyChanged.emit()

    def _restore(self, snap):
        px, qrow = snap
        self.pad.px = px
        if qrow:
            self.qrow = list(qrow)
            self.pals = [list(self.rows[r]) for r in self.qrow]
            self.pad.pals = self.pals
        self._quarter_clicked(getattr(self, '_sw_quarter', 0))

    def _parts(self):
        return [0, 1, 2, 3] if self.part == 'whole' else [self.part]

    def _tool(self, key):
        if self.mt is None:
            return
        if key in ('undo', 'redo'):
            src, dst = (self._undo, self._redo) if key == 'undo' else (self._redo, self._undo)
            if src:
                dst.append((self.current(), list(self.qrow or [])))
                self._restore(src.pop())
                self.pad.update()
                self._changed()
                self.historyChanged.emit()
            return
        if isinstance(key, tuple):                 # S171 r6: row / swap — shapes kept
            self._snap()
            px = self.current()
            if key[0] == 'row':
                for q in self._parts():
                    self._move_row(q, key[1])
                self._quarter_clicked(self._parts()[0])
                self.status.emit(f'Draw: row {key[1]} for '
                                 + ('the whole tile' if self.part == 'whole' else 'the quarter')
                                 + ' — colour numbers kept')
            self.pad.update()
            self._changed()
            return
        if key == 'revert':
            self._snap()
            self._restore(([list(q) for q in self.old], list(self.old_qrow or [])))
            self.pad.update()
            self._changed()
            return
        px = self.current()
        if key == 'copy':
            self._clip = ('whole', px) if self.part == 'whole' else ('quarter', px[self.part])
            self.status.emit('Copied ' + ('the whole tile' if self.part == 'whole'
                                          else 'one quarter'))
            return
        self._snap()
        if self.part == 'whole':
            g = [[px[(y // 8) * 2 + (x // 8)][(y % 8) * 8 + x % 8] for x in range(16)]
                 for y in range(16)]
            g = self._op(g, key, 16)
            if g is None:
                self._undo.pop()
                return
            px = [[g[(q // 2) * 8 + y][(q % 2) * 8 + x] for y in range(8) for x in range(8)]
                  for q in range(4)]
        else:
            q = self.part
            g = [[px[q][y * 8 + x] for x in range(8)] for y in range(8)]
            g = self._op(g, key, 8)
            if g is None:
                self._undo.pop()
                return
            px[q] = [g[y][x] for y in range(8) for x in range(8)]
        self.pad.px = px
        self.pad.update()
        self._changed()

    def _op(self, g, key, n):
        if key == 'flip_h':
            return [list(reversed(r)) for r in g]
        if key == 'flip_v':
            return list(reversed(g))
        if key == 'left':
            return [r[1:] + r[:1] for r in g]
        if key == 'right':
            return [r[-1:] + r[:-1] for r in g]
        if key == 'up':
            return g[1:] + g[:1]
        if key == 'down':
            return g[-1:] + g[:-1]
        if key == 'clear':
            return [[0] * n for _ in range(n)]
        if key == 'paste' and self._clip is not None:
            kind, data = self._clip
            if kind == 'quarter':
                src = [[data[y * 8 + x] for x in range(8)] for y in range(8)]
                return [[src[y % 8][x % 8] for x in range(n)] for y in range(n)]
            src = [[data[(y // 8) * 2 + (x // 8)][(y % 8) * 8 + x % 8] for x in range(16)]
                   for y in range(16)]
            return [[src[y][x] for x in range(n)] for y in range(n)]
        return None

    def _changed(self):
        self._render_tiled()
        self._schedule()

    def _render_tiled(self):
        if self.mt is None:
            return
        from PIL import Image, ImageQt
        from PySide6.QtGui import QPixmap
        img = Image.new('RGB', (16, 16))
        px = self.current()
        data = []
        for y in range(16):
            for x in range(16):
                q = (y // 8) * 2 + (x // 8)
                data.append(tuple(self.pals[q][px[q][(y % 8) * 8 + x % 8]]))
        img.putdata(data)
        big = Image.new('RGB', (48, 48))
        for i in range(3):
            for j in range(3):
                big.paste(img, (i * 16, j * 16))
        big = big.resize((96, 96), Image.NEAREST)
        self.tiled.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(big)))

    # ----------------------------------------------------------- report
    def _schedule(self):
        self._timer.start()

    def _update_report(self):
        if self.mt is None or self.reporter is None:
            return
        try:
            rep = self.reporter(self.current(), self.walkable.isChecked())
        except Exception as ex:                                  # noqa: BLE001
            self.ev_note.setText(f'⚠ {ex}')
            return
        self.last_report = rep
        ev = rep['everywhere']
        if self.rows_changed():                    # S171 r4
            ev = dict(ev, ok=False,
                      why='A quarter moved to another colour row — other cells drawing these '
                          'tiles keep their rows. Save it as a new metatile (put it on every '
                          'cell of this room drawing the original).')
        if ev['ok']:
            rooms = ', '.join(f'{n} in {r}' for r, n in ev['rooms'].items())
            self.ev_note.setText(f"Changes {ev['cells']} cell(s) — {rooms or 'none placed yet'}"
                                 + (f". {ev['note']}" if ev.get('note') else '')
                                 + ' (other metatiles using those tiles change too).')
            self.ev_note.setStyleSheet('color: #e0b040;')
        else:
            self.ev_note.setText(ev['why'])
            self.ev_note.setStyleSheet('color: #ff8060;')
        self.ev_btn.setEnabled(ev['ok'])
        nw = rep['new']
        if nw['ok']:
            self.new_note.setText(
                f"Uses {nw['reuse']} tile(s) already in the tileset + {nw['take']} free slot(s) "
                f"— free now: {nw['free']['wall']} wall / {nw['free']['walkable']} walkable "
                '(after saving).'
                + (f" Saving parks {nw['parks']} unplaced metatile(s) to make room (they stay "
                   'in the picker under Parked).' if nw.get('parks') else ''))
            self.new_note.setStyleSheet('color: #7fe07f;')
        else:
            self.new_note.setText(nw['why'])
            self.new_note.setStyleSheet('color: #ff8060;')
        self.new_btn.setEnabled(nw['ok'])

    # ------------------------------------------------------------ apply
    def _everywhere(self):
        if self.mt is not None:
            if self.rows_changed():
                return
            self.everywhereRequested.emit({'mt': dict(self.mt), 'old': self.old,
                                           'new': self.current()})

    def _new(self):
        if self.mt is not None:
            self.newRequested.emit({'mt': dict(self.mt), 'new': self.current(),
                                    'walkable': self.walkable.isChecked(),
                                    'name': self.name.text().strip() or 'drawn',
                                    'place': self.place.currentData(),
                                    'pal': self.pal_value()})
