"""draw_tab.py — the Draw tab (Tiles page, after Animate; S132, rebuilt S176).

Load a cell (or the brush, or a blank tile), paint its four 8×8 quarters, apply the drawing.
The tab shows facts and emits requests; editor2/core/tile_draw.py does the work (one undo step
each, pushed by the Rooms tab).

THE ONE HARDWARE RULE the panel is built round: a 16×16 tile is four 8×8 quarters and each
quarter is drawn with ONE of the room's (or the screen's own) 4 colour rows.

S176 — rebuilt (the user: "it shows palette rows but wont let me change the row? But then I
can 'recolor' and it randomly flips the colours? Can you make it fucking normal please from a
UI point of view … fully intuitive and I know what colours are available and how to use them.
And if I want to recolour all the pixels of a certain colour a different colour, make that
intuitive as well"). Measured on the user's project first: clicking another row's colour and
then the tile painted NOTHING (the reason only in the status line under the canvas); the
other rows were greyed; the *row 0-3* buttons and *Recolour…* sat below the fold (the panel
1,057 px in a 691 px view) behind a "tools act on" choice; "row 2" kept colour NUMBERS, so a
brown-and-tan shelf turned red-and-amber, frame included. Now:

  * the four rows are always in their true colours; RIGHT of each row four marks ◤ ◥ ◣ ◢ show
    which quarters draw with it — click a mark = put that quarter on that row (*all* = the
    whole tile); hovering a mark shows the tile as it would look BEFORE you click;
  * every quarter of the pad carries a tag with its row's four colours;
  * a quarter put on another row keeps every colour the new row also has; the others take the
    closest colour left, one-to-one (recolour.move_row — two colours never become one, so
    shapes stay);
  * painting with a colour the quarter's row lacks is never silent: a bar under the pad says
    which quarter is on which row and offers the switch as one button (the quarter / the
    whole tile) — then paints;
  * the tools are a paint program's: Pencil, Fill area (crosses the quarters), Replace colour
    (click a colour in the drawing: every pixel of it becomes the picked colour — the whole
    tile, or only the quarter clicked), Pick (also right-click, any tool);
  * *Edit colours…* opens the Palettes page; the line over the rows says whose colours they
    are (the room's / this screen's own) and which rows stamps use;
  * Apply = ONE chooser the user sets ("Let me decide"): this cell / every cell of the room
    drawn with the tile / everywhere the tile is drawn (the tile itself) / nowhere yet (My
    metatiles) — the line under it says what that will do before Apply is pressed;
  * the whole panel fits its page without scrolling.

History kept from S171 r4-r7: all four rows offered (r4); ⌘Z / ⌘⇧Z undo / redo strokes while
a drawing is loaded and the tab is shown (r6, `owns_undo`); a quarter changes row only when
the user says so (r7: "why does clicking on some pixels change that pixel and clicking on
other pixels change the entire regions?"); the room's palette edits reach the drawing at once
(`set_rows`).
"""

from PySide6.QtCore import QEvent, QRect, QSize, Qt, QTimer, Signal
from PySide6.QtGui import QColor, QPainter, QPen
from PySide6.QtWidgets import (QCheckBox, QComboBox, QFrame, QGridLayout,
                               QHBoxLayout, QLabel, QLineEdit, QPushButton, QSizePolicy,
                               QToolButton, QVBoxLayout, QWidget)

from editor2.app.rooms.animate_tab import FramePad
from editor2.app.qt_safe import combo_row_enabled            # S167
from editor2.core import recolour as RC

PARTS = ('whole', 0, 1, 2, 3)
PART_TEXT = {'whole': 'Whole', 0: '◤', 1: '◥', 2: '◣', 3: '◢'}
QNAME = ('top-left', 'top-right', 'bottom-left', 'bottom-right')
TOOLS = (('pencil', 'Pencil', 'Paint one pixel at a time (drag to draw)'),
         ('fill', 'Fill area', 'Fill the area of one colour you click — it crosses the four '
                               'quarters'),
         ('replace', 'Replace colour', 'Click a colour in the drawing: EVERY pixel of that '
                                       'colour becomes the colour picked below (shapes stay)'),
         ('pick', 'Pick', 'Click a pixel to paint with its colour (right-click does this with '
                          'any tool)'))
TARGETS = (('selection', 'Only the selected cell(s)'),
           ('room', 'Every cell of this room drawn with this tile'),
           ('everywhere', 'Everywhere this tile is drawn — the tile itself changes'),
           (None, 'Nowhere yet — keep it in My metatiles'))


def _wrap(text, style=None):
    l = QLabel(text)
    l.setWordWrap(True)
    if style:
        l.setStyleSheet(style)
    return l


def _chip(rgb):
    return (f'<span style="background:#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x};">'
            '&nbsp;&nbsp;&nbsp;&nbsp;</span>')


class QuarterTag(QWidget):
    """A quarter's row at a glance: its mark, "row N" and the row's four colours. Click =
    the tools act on this quarter."""
    clicked = Signal(int)

    def __init__(self, k, parent=None):
        super().__init__(parent)
        self.k = k
        self.row = 0
        self.cols = [(0, 0, 0)] * 4
        self.on = False
        self.setFixedHeight(16)
        self.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
        self.setCursor(Qt.PointingHandCursor)

    def set(self, row, cols, on):
        self.row, self.cols, self.on = row, [tuple(c[:3]) for c in cols], on
        self.setToolTip(f'The {QNAME[self.k]} quarter draws with row {row}. Click = the Flip / '
                        'Shift / Copy tools act on this quarter. Another row: the marks right '
                        'of the rows below.')
        self.update()

    def paintEvent(self, ev):
        p = QPainter(self)
        right = self.k % 2 == 1
        text = f'{PART_TEXT[self.k]} row {self.row}'
        fm = p.fontMetrics()
        tw = fm.horizontalAdvance(text) + 10
        sw = 4 * 11
        x = self.width() - tw - sw - 2 if right else 0
        f = p.font()
        f.setBold(self.on)
        p.setFont(f)
        p.setPen(self.palette().color(self.foregroundRole()))
        p.drawText(QRect(x, 0, tw + 8, self.height()), Qt.AlignVCenter | Qt.AlignLeft, text)
        for i, c in enumerate(self.cols):
            r = QRect(x + tw + i * 11, 2, 10, 12)
            p.fillRect(r, QColor(*c))
            p.setPen(QColor(0, 0, 0))
            p.drawRect(r.adjusted(0, 0, -1, -1))

    def mousePressEvent(self, ev):
        self.clicked.emit(self.k)


class DrawPad(FramePad):
    """The Draw tab's pad: FramePad + a PREVIEW (the tile as it would look — a row mark
    hovered) and the quarter under the mouse."""
    hovered = Signal(object)             # quarter 0-3 or None

    def __init__(self, parent=None):
        super().__init__(parent)
        self.preview = None              # (px, pals) drawn instead of the drawing
        self.flash = None                # quarters outlined (the ones a prompt is about)
        self._hq = None
        self.cur_xy = None               # the pixel the mouse event in progress is on
        self.setMouseTracking(True)

    def paintEvent(self, ev):
        keep = None
        if self.preview is not None:
            keep = (self.px, self.pals)
            self.px, self.pals = self.preview
        try:
            super().paintEvent(ev)
        finally:
            if keep is not None:
                self.px, self.pals = keep
        if self.flash or self.preview is not None:
            p = QPainter(self)
            z = self.zoom
            pen = QPen(QColor('#ff9a50') if self.flash else QColor('#6ad8e6'))
            pen.setWidth(3)
            p.setPen(pen)
            for k in (self.flash or ()):
                p.drawRect(QRect(3 + (k % 2) * 8 * z, 3 + (k // 2) * 8 * z, 8 * z, 8 * z)
                           .adjusted(1, 1, -2, -2))
            if self.preview is not None and not self.flash:
                p.drawRect(self.rect().adjusted(1, 1, -2, -2))

    def mousePressEvent(self, ev):
        self.cur_xy = self._xy(ev)
        super().mousePressEvent(ev)

    def mouseMoveEvent(self, ev):
        xy = self._xy(ev)
        self.cur_xy = xy
        k = None if xy is None else (xy[1] // 8) * self.cols + xy[0] // 8
        if k != self._hq:
            self._hq = k
            self.hovered.emit(k)
        super().mouseMoveEvent(ev)

    def leaveEvent(self, ev):
        if self._hq is not None:
            self._hq = None
            self.hovered.emit(None)
        super().leaveEvent(ev)


class DrawTab(QWidget):
    loadCellRequested = Signal()
    loadBrushRequested = Signal()
    blankRequested = Signal(int)                 # palette slot
    everywhereRequested = Signal(object)         # {'mt', 'old', 'new'}
    newRequested = Signal(object)                # {'mt', 'new', 'walkable', 'name', 'place', 'pal'}
    editColoursRequested = Signal()              # S176: open the Palettes page
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
        self.blank = False
        self.part = 'whole'
        self.tool = 'pencil'
        self.pending = None            # S176: what the bar's buttons will do
        self.last_report = None
        self._undo = []
        self._redo = []                  # S171 r6
        self._clip = None
        self._sw_quarter = 0
        v = QVBoxLayout(self)
        v.setContentsMargins(6, 4, 6, 4)
        v.setSpacing(3)
        # ① load
        row = QHBoxLayout()
        row.setSpacing(4)
        for text, sig, tip in (('Load cell', self.loadCellRequested,
                                'Load the tile of the cell selected on the canvas (Select '
                                'tool: click a cell)'),
                               ('Load brush', self.loadBrushRequested,
                                'Load the tile you paint with now')):
            b = QPushButton(text)
            b.setToolTip(tip)
            b.clicked.connect(sig.emit)
            row.addWidget(b)
        b = QPushButton('Blank')
        b.setToolTip('Start from an empty tile, every quarter on the row chosen beside it')
        b.clicked.connect(lambda: self.blankRequested.emit(self.blank_pal.currentData()))
        row.addWidget(b)
        self.blank_pal = QComboBox()
        for p in range(4):
            self.blank_pal.addItem(f'row {p}', p)
        self.blank_pal.setToolTip('the colour row a blank tile starts on')
        row.addWidget(self.blank_pal)
        row.addStretch(1)
        v.addLayout(row)
        self.head = QLabel('Nothing loaded yet — select a cell on the canvas, then Load cell.')
        self.head.setWordWrap(True)
        self.head.setStyleSheet('color: #aaa;')
        v.addWidget(self.head)
        # ② paint: the pad with a row tag on every quarter, the tools beside it
        mid = QHBoxLayout()
        mid.setSpacing(8)
        padbox = QGridLayout()
        padbox.setSpacing(1)
        self.tags = [QuarterTag(k) for k in range(4)]
        for k, t in enumerate(self.tags):
            t.clicked.connect(self._set_part)
        padbox.addWidget(self.tags[0], 0, 0)
        padbox.addWidget(self.tags[1], 0, 1)
        self.pad = DrawPad()
        self.pad.set_zoom(12)
        self.pad.pre_put = self._pre_put           # S171 r4 / r7
        self.pad.click_hook = self._click_hook     # S176: Fill / Replace / Pick
        self.pad.aboutToChange.connect(self._snap)
        self.pad.changed.connect(self._changed)
        self.pad.picked.connect(self._set_colour)
        self.pad.tileClicked.connect(self._quarter_clicked)
        self.pad.partPicked.connect(lambda k, _w: self._set_part(k))
        self.pad.hovered.connect(self._hovered)
        padbox.addWidget(self.pad, 1, 0, 1, 2)
        padbox.addWidget(self.tags[2], 2, 0)
        padbox.addWidget(self.tags[3], 2, 1)
        mid.addLayout(padbox)
        tcol = QVBoxLayout()
        tcol.setSpacing(3)
        self.tool_btns = {}
        for key, text, tip in TOOLS:
            b = QToolButton()
            b.setText(text)
            b.setCheckable(True)
            b.setToolTip(tip)
            b.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
            b.clicked.connect(lambda _c=False, k=key: self.set_tool(k))
            tcol.addWidget(b)
            self.tool_btns[key] = b
        self.only_q = QCheckBox('only the\nquarter I click')
        self.only_q.setToolTip('Replace colour: change that colour in the quarter clicked only '
                               '(unticked = in the whole tile)')
        tcol.addWidget(self.only_q)
        tcol.addWidget(QLabel('as it tiles'))
        self.tiled = QLabel()
        self.tiled.setFixedSize(3 * 16 * 2, 3 * 16 * 2)
        self.tiled.setStyleSheet('background: #202024;')
        tcol.addWidget(self.tiled)
        tcol.addStretch(1)
        mid.addLayout(tcol)
        mid.addStretch(1)
        v.addLayout(mid)
        # the bar: where the mouse is / what a tool needs — and the one-click answer
        self.bar = QFrame()
        self.bar.setFixedHeight(48)
        self.bar.setStyleSheet('QFrame { background: #2a2a30; border-radius: 4px; }')
        bl = QVBoxLayout(self.bar)
        bl.setContentsMargins(6, 3, 6, 3)
        bl.setSpacing(2)
        self.bar_text = QLabel('')
        self.bar_text.setWordWrap(True)
        self.bar_text.setTextFormat(Qt.RichText)
        self.bar_text.setStyleSheet('background: transparent; color: #ddd;')
        bl.addWidget(self.bar_text, 1)
        br = QHBoxLayout()
        br.setSpacing(4)
        self.bar_q = QPushButton('')
        self.bar_q.clicked.connect(lambda: self._answer(False))
        self.bar_all = QPushButton('')
        self.bar_all.clicked.connect(lambda: self._answer(True))
        self.bar_no = QPushButton('Leave it')
        self.bar_no.clicked.connect(lambda: self._prompt(None))
        for b in (self.bar_q, self.bar_all, self.bar_no):
            b.setVisible(False)
            br.addWidget(b)
        br.addStretch(1)
        bl.addLayout(br)
        v.addWidget(self.bar)
        # the colours: every row, true; right of each row the quarters that draw with it
        crow = QHBoxLayout()
        self.scope = QLabel('<b>Colours</b>')
        self.scope.setTextFormat(Qt.RichText)
        crow.addWidget(self.scope, 1)
        self.edit_btn = QPushButton('Edit colours…')
        self.edit_btn.setToolTip('Open the Palettes page: change a colour, give this screen its '
                                 'own colours, borrow another room\'s')
        self.edit_btn.clicked.connect(self.editColoursRequested.emit)
        crow.addWidget(self.edit_btn)
        v.addLayout(crow)
        self.swatches = {}                 # (row, index) -> button
        self.row_labels = []
        self.marks = {}                    # (row, quarter) -> button
        self.all_btns = []
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
            sw.setColumnMinimumWidth(5, 10)
            for k in range(4):
                m = QToolButton()
                m.setText(PART_TEXT[k])
                m.setFixedSize(24, 24)
                m.setCheckable(True)
                m.clicked.connect(lambda _c=False, rr=r, q=k: self._mark_clicked(rr, [q]))
                m.installEventFilter(self)
                m.setProperty('mark', (r, k))
                sw.addWidget(m, r, 6 + k)
                self.marks[(r, k)] = m
            a = QToolButton()
            a.setText('all')
            a.setFixedHeight(24)
            a.setToolTip(f'the whole tile on row {r}')
            a.clicked.connect(lambda _c=False, rr=r: self._mark_clicked(rr, [0, 1, 2, 3]))
            a.installEventFilter(self)
            a.setProperty('mark', (r, 'all'))
            sw.addWidget(a, r, 10)
            self.all_btns.append(a)
        sw.setColumnStretch(11, 1)
        v.addLayout(sw)
        self.sw_note = _wrap('', 'color: #f0c060;')
        self.sw_note.setVisible(False)
        v.addWidget(self.sw_note)
        # the shape tools
        pr = QHBoxLayout()
        pr.setSpacing(3)
        pr.addWidget(QLabel('shape tools on'))
        self.part_btns = {}
        for part in PARTS:
            b = QToolButton()
            b.setText(PART_TEXT[part])
            b.setCheckable(True)
            b.setToolTip('the whole tile' if part == 'whole' else f'the {QNAME[part]} quarter')
            b.clicked.connect(lambda _c=False, k=part: self._set_part(k))
            pr.addWidget(b)
            self.part_btns[part] = b
        pr.addStretch(1)
        v.addLayout(pr)
        grid = QGridLayout()
        grid.setSpacing(3)
        tools = (('Flip ↔', 'flip_h'), ('Flip ↕', 'flip_v'), ('◀', 'left'), ('▶', 'right'),
                 ('▲', 'up'), ('▼', 'down'),
                 ('Copy', 'copy'), ('Paste', 'paste'), ('Clear', 'clear'),
                 ('Undo', 'undo'), ('Redo', 'redo'), ('Revert', 'revert'))
        tips = {'left': 'shift left', 'right': 'shift right', 'up': 'shift up',
                'down': 'shift down', 'revert': 'back to the tile as loaded',
                'clear': 'every pixel colour 0'}
        self.tool_grid = {}
        for i, (text, key) in enumerate(tools):
            b = QToolButton()
            b.setText(text)
            b.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
            b.setMinimumWidth(20)
            if key in ('undo', 'redo'):
                b.setToolTip(f'{text} the last stroke or tool (also ⌘{"Z" if key == "undo" else "⇧Z"} '
                             'while a drawing is loaded)')
            elif key in tips:
                b.setToolTip(tips[key])
            b.clicked.connect(lambda _c=False, k=key: self._tool(k))
            grid.addWidget(b, i // 6, i % 6)
            self.tool_grid[key] = b
        v.addLayout(grid)
        # ③ apply
        ar = QHBoxLayout()
        ar.setSpacing(4)
        ar.addWidget(QLabel('Apply to'))
        self.target = QComboBox()
        self.target.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.target.setMinimumContentsLength(12)
        for key, text in TARGETS:
            self.target.addItem(text, key)
        self.target.currentIndexChanged.connect(lambda _i: self._show_report())
        ar.addWidget(self.target, 1)
        self.apply_btn = QPushButton('Apply')
        self.apply_btn.clicked.connect(self._apply)
        ar.addWidget(self.apply_btn)
        v.addLayout(ar)
        nr = QHBoxLayout()
        nr.setSpacing(4)
        self.name_label = QLabel('name')
        nr.addWidget(self.name_label)
        self.name = QLineEdit('drawn')
        self.name.setMinimumWidth(60)
        nr.addWidget(self.name, 1)
        self.walkable = QCheckBox('walkable')
        self.walkable.setToolTip('unticked = a wall. The new tile\'s bottom-right quarter goes '
                                 'to the walkable (or wall) side of the tileset — it decides '
                                 'walkability')
        self.walkable.toggled.connect(lambda _on: self._schedule())
        nr.addWidget(self.walkable)
        v.addLayout(nr)
        self.note = _wrap('', 'color: #7fe07f;')
        self.note.setMinimumHeight(44)
        self.note.setAlignment(Qt.AlignTop | Qt.AlignLeft)
        v.addWidget(self.note)
        v.addStretch(1)
        self._timer = QTimer(self)
        self._timer.setSingleShot(True)
        self._timer.setInterval(150)
        self._timer.timeout.connect(self._update_report)
        self._set_part('whole')
        self.set_tool('pencil')
        self._pick_swatch(0, 3)
        self._set_enabled(False)
        self._idle_bar()

    # ------------------------------------------------------------ load
    def load(self, mt, px, pals, desc, walkable=True, selection_ok=False, rows=None,
             qrow=None):
        """mt = metatile dict, px = 4 quarters of 64 colour numbers, pals =
        4 palette rows of RGB (the quarters' palettes), desc = where from.
        S171 r4: rows = the room's 4 rows, qrow = each quarter's row."""
        self.mt = {'tiles': list(mt['tiles']), 'pal': mt.get('pal', 0),
                   'name': mt.get('name')}
        self.blank = bool(mt.get('blank'))
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
        self.pending = None
        self.pad.preview = None
        self.pad.flash = None
        self.historyChanged.emit()
        self.pad.set_frame(2, 2, self.old, self.pals, editable=True)
        self.walkable.blockSignals(True)
        self.walkable.setChecked(bool(walkable))
        self.walkable.blockSignals(False)
        self.can_place_sel = selection_ok
        self.target.blockSignals(True)
        combo_row_enabled(self.target, 0, selection_ok,
                          None if selection_ok else 'select a cell on the canvas first')
        combo_row_enabled(self.target, 1, not self.blank)
        combo_row_enabled(self.target, 2, not self.blank)
        keep = self.target.currentData()
        ok = {'selection': selection_ok, 'room': not self.blank,
              'everywhere': not self.blank, None: True}
        if not ok.get(keep, False) or getattr(self, '_fresh', True):
            self.target.setCurrentIndex(0 if selection_ok else 3)
        self._fresh = False
        self.target.blockSignals(False)
        self.head.setText(f'{desc} — ' + ('walkable' if walkable else 'a wall'))
        self.head.setToolTip('tiles ' + ' '.join(f'${t:02X}' for t in self.mt['tiles']))
        self.head.setStyleSheet('')
        self._set_enabled(True)
        self._sw_quarter = 0
        if getattr(self, '_fresh_colour', True):     # the first tile: black of its own row
            self._fresh_colour = False
            self._pick_swatch(self.qrow[0], 3)
        self._refresh_rows()
        self._idle_bar()
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
        for w in (self.pad, self.apply_btn, self.name, self.walkable, self.target,
                  *self.marks.values(), *self.all_btns, *self.tool_grid.values()):
            w.setEnabled(on)

    def set_scope(self, text, notes=None):
        """S176: whose colours the rows are ("screen 15's own colours" / "the room's
        colours") and a note per row ({row: "stamps: Wall torch"})."""
        short, _sep, long = text.partition(' (')
        self.scope.setText(f'<b>Colours</b> — {short}')
        self.scope.setToolTip(text + '. An 8×8 quarter draws with ONE of these rows.')
        self._row_notes = dict(notes or {})
        for r, lab in enumerate(self.row_labels):
            lab.setText(f'row {r}' + (' ★' if r in self._row_notes else ''))
            lab.setToolTip(self._row_notes.get(r, ''))
        rows = sorted(self._row_notes)
        self.sw_note.setText('★ = your stamps draw with this row too' if rows else '')
        self.sw_note.setToolTip('; '.join(f'row {r}: {t}' for r, t in sorted(
            self._row_notes.items())) + ' — paint with these rows freely; changing their '
            'colours changes the stamps')
        self.sw_note.setVisible(bool(rows))

    # ------------------------------------------------------------ colours
    def set_tool(self, key):
        self.tool = key
        for k, b in self.tool_btns.items():
            b.setChecked(k == key)
        self.only_q.setEnabled(key == 'replace')
        self._prompt(None)

    def _set_colour(self, i):
        """Colour number `i` of the clicked quarter's row (the right-click pick; S171 r7:
        the pad's tileClicked came first, so _sw_quarter is the quarter clicked)."""
        k = getattr(self, '_sw_quarter', 0)
        row = self.qrow[k] if self.qrow else self.cur_row
        self._pick_swatch(row, i)

    def _pick_swatch(self, row, i):
        self.cur_row, self.pad.colour = row, i
        for (r, k), b in self.swatches.items():
            b.setChecked(r == row and k == i)
        if self.pending is not None:
            self._prompt(None)

    def picked_rgb(self):
        if not self.rows or self.cur_row >= len(self.rows):
            return (0, 0, 0)
        return tuple(self.rows[self.cur_row][self.pad.colour][:3])

    # ---- S171 r7: rows follow the palette
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
        self._refresh_rows()
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

    def _refresh_rows(self):
        """Swatches (true colours, always), the marks, the quarters' tags."""
        for (r, i), b in self.swatches.items():
            if not self.rows or r >= len(self.rows):
                b.setStyleSheet('')
                continue
            c = QColor(*self.rows[r][i][:3])
            b.setStyleSheet(f'QToolButton {{ background: {c.name()}; border: 1px solid #555; }}'
                            f'QToolButton:checked {{ border: 3px solid #ffe000; }}')
            b.setToolTip(f'row {r}, colour {i}  #{c.red():02x}{c.green():02x}{c.blue():02x}')
        if not self.qrow:
            return
        for (r, k), m in self.marks.items():
            on = self.qrow[k] == r
            m.setChecked(on)
            m.setStyleSheet('QToolButton:checked { background: #ffe000; color: #000; '
                            'border: 1px solid #a09000; }')
            m.setToolTip(f'the {QNAME[k]} quarter draws with row {r}' if on else
                         f'put the {QNAME[k]} quarter on row {r} (hover: how it will look)')
        used = set(self.qrow)
        for r, lab in enumerate(self.row_labels):
            lab.setStyleSheet('font-weight: bold;' if r in used else '')
        for k, t in enumerate(self.tags):
            t.set(self.qrow[k], self.rows[self.qrow[k]], self.part == k)

    def _quarter_clicked(self, k):
        if not self.pals:
            return
        self._sw_quarter = k

    def _hovered(self, k):
        if self.pending is None:
            self._idle_bar(k)

    def _idle_bar(self, k=None):
        if self.mt is None:
            self.bar_text.setText('Load a tile to draw on it.')
            return
        tool = {'pencil': 'Pencil: click or drag; right-click picks a colour',
                'fill': 'Fill area: click an area of one colour',
                'replace': 'Replace colour: click a colour — all of it becomes '
                           + _chip(self.picked_rgb()),
                'pick': 'Pick: click a pixel to paint with its colour'}[self.tool]
        where = (f'The <b>{QNAME[k]}</b> quarter draws with <b>row {self.qrow[k]}</b>.'
                 if k is not None else
                 'One row per 8×8 quarter — a mark ◤◥◣◢ moves it.')
        self.bar_text.setText(f'{tool}.<br>{where}')

    # ---- putting quarters on another row
    def _moved(self, k, row, px=None, force=None):
        """Quarter k's pixels as they will be on `row` (recolour.move_row)."""
        px = px if px is not None else self.pad.px[k]
        if self.qrow[k] == row:
            return list(px)
        return RC.move_row(px, self.rows[self.qrow[k]], self.rows[row], force)

    def _switch(self, quarters, row, force=None):
        """Put the quarters on `row` (no undo snapshot here)."""
        px = self.current()
        for k in quarters:
            if self.qrow[k] == row:
                continue
            px[k] = self._moved(k, row, px[k], (force or {}).get(k))
            self.qrow[k] = row
            self.pals[k] = list(self.rows[row])
        self.pad.px = px
        self.pad.pals = self.pals

    def _mark_clicked(self, row, quarters):
        if self.mt is None:
            return
        todo = [k for k in quarters if self.qrow[k] != row]
        self._preview(None)
        if not todo:
            self._refresh_rows()
            return
        self._snap()
        self._switch(todo, row)
        self._prompt(None)
        self._refresh_rows()
        self.pad.update()
        self._changed()
        what = ('the whole tile' if len(quarters) == 4 else f'the {QNAME[todo[0]]} quarter')
        self.status.emit(f'Draw: {what} on row {row} — the colours row {row} also has stay, '
                         'the others took the closest (⌘Z undoes)')

    def _preview(self, spec):
        """spec = (row, quarters) hovered, or None."""
        if spec is None or self.mt is None:
            if self.pad.preview is not None:
                self.pad.preview = None
                self.pad.update()
                if self.pending is None:
                    self._idle_bar()
            return
        row, quarters = spec
        todo = [k for k in quarters if self.qrow[k] != row]
        if not todo:
            return
        px = self.current()
        pals = [list(p) for p in self.pals]
        for k in todo:
            px[k] = self._moved(k, row, px[k])
            pals[k] = list(self.rows[row])
        self.pad.preview = (px, pals)
        self.pad.update()
        if self.pending is None:
            what = 'the whole tile' if len(quarters) == 4 else f'the {QNAME[todo[0]]} quarter'
            self.bar_text.setText(f'<b>Preview:</b> {what} on row {row}. Colours row {row} '
                                  'also has stay; the others take the closest. Click to do it.')

    def eventFilter(self, obj, ev):
        spec = obj.property('mark')
        if spec is not None:
            if ev.type() == QEvent.Enter:
                row, k = spec
                self._preview((row, [0, 1, 2, 3] if k == 'all' else [k]))
            elif ev.type() == QEvent.Leave:
                self._preview(None)
        return super().eventFilter(obj, ev)

    # ---- the bar: a tool that needs a row the quarter is not on
    def _prompt(self, pending):
        self.pending = pending
        on = pending is not None
        self.pad.flash = list(pending['quarters']) if on else None
        self.pad.update()
        for b in (self.bar_q, self.bar_all, self.bar_no):
            b.setVisible(False)
        if not on:
            self.bar.setStyleSheet('QFrame { background: #2a2a30; border-radius: 4px; }')
            self._idle_bar()
            return
        row, qs = pending['row'], pending['quarters']
        names = ' + '.join(PART_TEXT[k] for k in qs)
        rows_now = sorted({self.qrow[k] for k in qs})
        self.bar.setStyleSheet('QFrame { background: #5a3410; border-radius: 4px; }')
        self.bar_text.setText(
            f"{names} {'draws' if len(qs) == 1 else 'draw'} with row "
            f"{' / '.join(map(str, rows_now))} — no {_chip(pending['rgb'])} there (it is row "
            f'{row}\'s).')
        self.bar_q.setText(f'Put {names} on row {row}')
        self.bar_q.setVisible(True)
        self.bar_all.setText(f'Whole tile on row {row}')
        self.bar_all.setVisible(len(qs) < 4)
        self.bar_no.setVisible(True)
        self.status.emit(f"Draw: the {' / '.join(QNAME[k] for k in qs)} quarter"
                         f"{'s are' if len(qs) > 1 else ' is'} not on row {row} — the bar "
                         'under the drawing switches it in one click')

    def _answer(self, whole):
        """A bar button: switch the row(s), then do what was asked."""
        p = self.pending
        if p is None or self.mt is None:
            return
        qs = [0, 1, 2, 3] if whole else list(p['quarters'])
        self._snap()
        force = {}
        if p['kind'] == 'replace':
            for k in qs:
                if self.qrow[k] == p['row']:
                    continue
                own = [tuple(c[:3]) for c in self.rows[self.qrow[k]]]
                hits = [n for n, c in enumerate(own) if c == p['src']]
                used = set(self.pad.px[k])
                hit = next((n for n in hits if n in used), None)
                if hit is not None:
                    force[k] = {hit: p['index']}
        self._switch(qs, p['row'], force)
        self.pending = None
        if p['kind'] == 'pencil':
            if p.get('xy'):
                self.pad.put(p['xy'][0], p['xy'][1], p['index'])
        elif p['kind'] == 'fill':
            self._paint_area(p['area'])
        elif p['kind'] == 'replace':
            self._do_replace(p['src'], p['scope'], ask=False)
        self._prompt(None)
        self._refresh_rows()
        self.pad.update()
        self._changed()

    # ------------------------------------------------------------ paint
    def _pre_put(self, k, colour):
        """Pencil: the colour number to paint into quarter `k` — its own row's number of the
        picked colour (S171 r7: a quarter is painted with its OWN row). A colour its row
        lacks is not painted: the bar offers the switch (S176)."""
        if not self.qrow or self.cur_row >= len(self.rows or []):
            return colour
        got = self._own_colour(k, self.cur_row, colour)
        if got is None:
            if self.pending is None or self.pending.get('quarters') != [k]:
                self._prompt({'kind': 'pencil', 'quarters': [k], 'row': self.cur_row,
                              'index': colour, 'rgb': self.picked_rgb(),
                              'xy': self.pad.cur_xy})
        elif self.pending is not None:
            self._prompt(None)
        return got

    def _click_hook(self, xy):
        """Fill / Replace / Pick use the click; Pencil lets FramePad paint (pre_put)."""
        if self.mt is None:
            return True
        k = (xy[1] // 8) * 2 + xy[0] // 8
        if self.tool == 'pick':
            self._pick_swatch(self.qrow[k], self.pad.get(*xy))
            self._idle_bar(k)
            return True
        if self.tool == 'fill':
            self._do_fill(xy)
            return True
        if self.tool == 'replace':
            src = tuple(self.rows[self.qrow[k]][self.pad.get(*xy)][:3])
            self._do_replace(src, [k] if self.only_q.isChecked() else [0, 1, 2, 3])
            return True
        return False

    def _rgb_at(self, px, x, y):
        k = (y // 8) * 2 + x // 8
        return tuple(self.rows[self.qrow[k]][px[k][(y % 8) * 8 + x % 8]][:3])

    def _area(self, px, xy):
        """The pixels of one colour joined to `xy` (across the quarters)."""
        src = self._rgb_at(px, *xy)
        area, todo, seen = [], [tuple(xy)], set()
        while todo:
            x, y = todo.pop()
            if (x, y) in seen or not (0 <= x < 16 and 0 <= y < 16):
                continue
            seen.add((x, y))
            if self._rgb_at(px, x, y) != src:
                continue
            area.append((x, y))
            todo += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
        return area

    def _paint_area(self, area):
        """The picked colour on every pixel of `area` whose quarter's row has it. -> count."""
        px = self.current()
        n = 0
        for x, y in area:
            k = (y // 8) * 2 + x // 8
            i = self._own_colour(k, self.cur_row, self.pad.colour)
            if i is not None:
                px[k][(y % 8) * 8 + x % 8] = i
                n += 1
        self.pad.px = px
        return n

    def _do_fill(self, xy):
        """Flood the area of one colour round `xy` (across the quarters) with the picked
        colour. Quarters whose row lacks it: the bar asks first."""
        px = self.current()
        tgt = self.picked_rgb()
        if self._rgb_at(px, *xy) == tgt:
            return
        area = self._area(px, xy)
        qs = sorted({(y // 8) * 2 + x // 8 for x, y in area})
        lack = [k for k in qs if self._own_colour(k, self.cur_row, self.pad.colour) is None]
        if lack:
            self._prompt({'kind': 'fill', 'quarters': lack, 'row': self.cur_row,
                          'index': self.pad.colour, 'rgb': tgt, 'area': area})
            return
        self._snap()
        n = self._paint_area(area)
        self.pad.update()
        self._changed()
        self.status.emit(f'Draw: filled {n} pixel(s)')

    def _do_replace(self, src, scope, ask=True):
        """Every pixel of colour `src` (RGB) in the quarters `scope` -> the picked colour.
        Shapes stay. Quarters whose row lacks the picked colour: asked (ask) or left."""
        tgt = self.picked_rgb()
        px = self.current()
        work, lack = [], []
        for k in scope:
            own = [tuple(c[:3]) for c in self.rows[self.qrow[k]]]
            hits = {n for n, c in enumerate(own) if c == src}
            if not hits or not any(v in hits for v in px[k]):
                continue
            to = self._own_colour(k, self.cur_row, self.pad.colour)
            if to is None:
                lack.append(k)
            else:
                work.append((k, hits, to))
        if src == tgt:
            self.status.emit('Replace colour: that is the colour picked already — pick the '
                             'colour it should become first (a swatch below)')
            return
        if lack and ask:
            self._prompt({'kind': 'replace', 'quarters': lack, 'row': self.cur_row,
                          'index': self.pad.colour, 'rgb': tgt, 'src': src, 'scope': list(scope)})
            if not work:
                return
        if not work:
            if ask:
                self.status.emit('Replace colour: no pixel of that colour there')
            return
        if ask:
            self._snap()
        n = 0
        for k, hits, to in work:
            new = [to if v in hits else v for v in px[k]]
            n += sum(1 for a, b in zip(px[k], new) if a != b)
            px[k] = new
        self.pad.px = px
        if ask:
            self.pad.update()
            self._changed()
        self.status.emit(f'Replace colour: {n} pixel(s) changed'
                         + (f" — not yet in {' / '.join(QNAME[k] for k in lack)}: see the bar "
                            'under the drawing' if lack and ask else ''))

    def _set_part(self, part):
        self.part = part
        for k, b in self.part_btns.items():
            b.setChecked(k == part)
        if part == 'whole':
            self.pad.part_rect = None
        else:
            self.pad.part_rect = ((part % 2) * 8, (part // 2) * 8, 8, 8)
        if self.qrow:
            for k, t in enumerate(self.tags):
                t.set(self.qrow[k], self.rows[self.qrow[k]], part == k)
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
        self._prompt(None)
        self._refresh_rows()

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
        if isinstance(key, tuple):                 # ('row', r): the part on row r
            if key[0] == 'row':
                self._mark_clicked(key[1], self._parts())
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
                data.append(tuple(self.pals[q][px[q][(y % 8) * 8 + x % 8]][:3]))
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
            self.last_report = None
            self.note.setText(f'⚠ {ex}')
            self.note.setStyleSheet('color: #ff8060;')
            return
        ev = rep['everywhere']
        if self.rows_changed():                    # S171 r4
            ev = dict(ev, ok=False,
                      why='A quarter is on another colour row now — the other cells drawn with '
                          'this tile keep their rows, so the tile itself cannot simply change. '
                          'Choose "Every cell of this room drawn with this tile" instead.')
        rep = dict(rep, everywhere=ev)
        self.last_report = rep
        self._show_report()

    def can_everywhere(self):
        return bool(self.last_report and self.last_report['everywhere']['ok'])

    def can_new(self):
        return bool(self.last_report and self.last_report['new']['ok'])

    def _show_report(self):
        """The line under Apply: what the chosen target will do."""
        rep = self.last_report
        key = self.target.currentData()
        new_tile = key != 'everywhere'
        for w in (self.name, self.name_label, self.walkable):
            w.setEnabled(self.mt is not None and new_tile)
        if rep is None or self.mt is None:
            return
        if key == 'everywhere':
            ev = rep['everywhere']
            if ev['ok']:
                rooms = ', '.join(f'{n} in {r}' for r, n in ev['rooms'].items())
                text = (f"Changes {ev['cells']} cell(s) — {rooms or 'none placed yet'}"
                        + (f". {ev['note']}" if ev.get('note') else '')
                        + ' (other tiles using those pieces change too). No new slot.')
                ok = True
            else:
                text, ok = ev['why'], False
        else:
            nw = rep['new']
            if nw['ok']:
                where = {'selection': 'On the selected cell(s) only: a new tile',
                         'room': 'On every cell of this room drawn with the original: a new '
                                 'tile',
                         None: 'A new tile in My metatiles (no cell changes)'}[key]
                text = (f"{where} — {nw['reuse']} piece(s) already in the tileset + "
                        f"{nw['take']} free slot(s); free after: {nw['free']['wall']} wall / "
                        f"{nw['free']['walkable']} walkable."
                        + (f" Parks {nw['parks']} unplaced tile(s) to make room (they stay in "
                           'the picker under Parked).' if nw.get('parks') else ''))
                ok = True
            else:
                text, ok = nw['why'], False
        self.note.setText(text)
        self.note.setStyleSheet('color: #7fe07f;' if ok else 'color: #ff8060;')
        self.apply_btn.setEnabled(ok)

    # ------------------------------------------------------------ apply
    def _apply(self):
        if self.mt is None:
            return
        if self.target.currentData() == 'everywhere':
            self._everywhere()
        else:
            self._new()

    def _everywhere(self):
        if self.mt is not None:
            if self.rows_changed():
                return
            self.everywhereRequested.emit({'mt': dict(self.mt), 'old': self.old,
                                           'new': self.current()})

    def _new(self, place='ask'):
        if self.mt is not None:
            key = self.target.currentData() if place == 'ask' else place
            if key == 'everywhere':
                key = None
            mt = dict(self.mt)
            if self.blank:
                mt['blank'] = True
            self.newRequested.emit({'mt': mt, 'new': self.current(),
                                    'walkable': self.walkable.isChecked(),
                                    'name': self.name.text().strip() or 'drawn',
                                    'place': key,
                                    'pal': self.pal_value()})

    def sizeHint(self):
        return QSize(360, 640)
