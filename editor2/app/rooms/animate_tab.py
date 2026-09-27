"""animate_tab.py — "Make animated" (S99 r3).

User: "please make the 'make animatable' tab. Bonus points if you can make a
little tab/edit doodad that lets me re-paint a second tile in a paint-like
manner." And: "how do I change animation of e.g. the water? Double clicking
on the tile doesnt bring up any animation info."

The game animates SLOTS of the room's sheet with ONE animation per room
(ROOM_DATA_FORMAT "Animated tiles"). This tab takes a metatile (the brush,
or a double-clicked / selected cell), lets the author pick

  * Slide  — the tile rolls 1 px sideways (water, lava, conveyor);
  * Flip   — the tile alternates with a SECOND FRAME the author paints here
             (torches, blinking eyes, swirls),

shows which vanilla animations can host it (free slots, walkability, what a
switch would stop), paints frame A / frame B in a 16x16 pad with the tile's
own palette, previews at game speed, and applies it through
Document.make_animated (one undo step).
"""

from PIL import Image, ImageQt
from PySide6.QtCore import QRect, Qt, QTimer, Signal
from PySide6.QtGui import QColor, QPainter, QPen, QPixmap
from PySide6.QtWidgets import (QButtonGroup, QComboBox, QGridLayout, QHBoxLayout,
                               QLabel, QPushButton, QRadioButton, QToolButton,
                               QVBoxLayout, QWidget)

from editor2.core import animation as ANIM
from editor2.core.document import metatile_pals
from editor2.core.png_import import decode_2bpp, encode_2bpp

ZOOM = 8


def _rotr(v):
    return ((v >> 1) | ((v & 1) << 7)) & 0xFF


def _rotl(v):
    return ((v << 1) & 0xFF) | (v >> 7)


PART_NAMES = ('top-left', 'top-right', 'bottom-left', 'bottom-right')


def _wrap(text):
    lab = QLabel(text)
    lab.setWordWrap(True)
    return lab


def budget_html(doc, room):
    """'This room's animation' count (S99 r6), shared with the inspector."""
    b = doc.anim_budget(room)
    rule = ('One animation per room. A 16×16 tile needs one slot (slide) or pair (flip) '
            'per different 8×8 quarter; identical quarters share one.')
    if b['map'] is None:
        return ('<b>Animated tiles here: none.</b> ' + rule + ' Sizes: slides move 2 '
                'slots (GreatTree sway 16); flips 1-8 pairs (Arena Battle $5D: 8, '
                'Zoma $49: 6 + a 2-slot slide).')
    parts = []
    for u in b['units']:
        left = u['total'] - u['used']
        parts.append(f"{u['effect']} <b>{u['used']} of {u['total']}</b> {u['unit']}s used"
                     + (' — <span style="color:#ffb060">FULL</span>' if left <= 0 else
                        f' ({left} free)'))
    tl = []
    for name, tiles, cells in b['tiles'][:6]:
        tl.append(f"{name or 'tile ' + str(tiles)} ×{cells}")
    more = len(b['tiles']) - 6
    return (f"<b>This room's animation: ${b['map']:02X}</b> — " + '; '.join(parts) + '.<br>'
            + (f"Moving here: {len(b['tiles'])} tile(s): " + ', '.join(tl)
               + (f', +{more} more' if more > 0 else '') + '.<br>' if b['tiles'] else
               'Nothing in this room uses it yet.<br>')
            + f'<span style="color:#9ab">{rule}</span>')


class PixelPad(QWidget):
    """16x16 colour-index canvas (the metatile's 4 subtiles) in the tile's
    own palettes. Left = paint the chosen colour (drag), right = pick,
    Shift+left = flood fill within the subtile, Ctrl+left = select that
    quarter for the part tools (S99 r5)."""
    changed = Signal()
    aboutToChange = Signal()        # before a paint stroke (local undo)
    activated = Signal()            # any click: this frame is being edited
    picked = Signal(int)            # colour index picked (right click)
    quadrant = Signal(int)          # subtile position under the last click
    partPicked = Signal(int)        # Ctrl+click: select that quarter

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setFixedSize(16 * ZOOM + 2, 16 * ZOOM + 2)
        self.px = [[0] * 64 for _ in range(4)]      # per subtile: 64 indices
        self.pals = [[(255, 255, 255)] * 4] * 4     # per subtile: 4 RGB
        self.colour = 3
        self.editable = True
        self.active = False                         # the frame the tools act on
        self.sel = None                             # selected quarter (None = whole)
        self._last = None

    def set_pixels(self, px, pals):
        self.px = [list(p) for p in px]
        self.pals = pals
        self.update()

    def get(self, x, y):
        k = (y // 8) * 2 + (x // 8)
        return self.px[k][(y % 8) * 8 + (x % 8)]

    def put(self, x, y, v):
        k = (y // 8) * 2 + (x // 8)
        self.px[k][(y % 8) * 8 + (x % 8)] = v

    def paintEvent(self, ev):
        p = QPainter(self)
        p.fillRect(self.rect(), QColor(20, 20, 24))
        for y in range(16):
            for x in range(16):
                k = (y // 8) * 2 + (x // 8)
                c = self.pals[k][self.get(x, y)]
                p.fillRect(1 + x * ZOOM, 1 + y * ZOOM, ZOOM, ZOOM, QColor(*c))
        pen = QPen(QColor(0, 0, 0, 90))
        p.setPen(pen)
        for i in range(17):
            p.drawLine(1 + i * ZOOM, 1, 1 + i * ZOOM, 1 + 16 * ZOOM)
            p.drawLine(1, 1 + i * ZOOM, 1 + 16 * ZOOM, 1 + i * ZOOM)
        pen = QPen(QColor(255, 255, 255, 160))
        pen.setWidth(2)
        p.setPen(pen)
        p.drawLine(1 + 8 * ZOOM, 1, 1 + 8 * ZOOM, 1 + 16 * ZOOM)
        p.drawLine(1, 1 + 8 * ZOOM, 1 + 16 * ZOOM, 1 + 8 * ZOOM)
        if self.sel is not None:
            # the selected quarter: dark underlay + bright dashed outline
            r = QRect(1 + (self.sel % 2) * 8 * ZOOM, 1 + (self.sel // 2) * 8 * ZOOM,
                      8 * ZOOM - 1, 8 * ZOOM - 1)
            pen = QPen(QColor(0, 0, 0, 200))
            pen.setWidth(3)
            p.setPen(pen)
            p.drawRect(r)
            pen = QPen(QColor('#6ad8e6'))
            pen.setWidth(2)
            pen.setStyle(Qt.DashLine)
            p.setPen(pen)
            p.drawRect(r)
        if self.active:
            pen = QPen(QColor('#ffe000'))
            pen.setWidth(2)
            p.setPen(pen)
            p.drawRect(self.rect().adjusted(1, 1, -1, -1))
        if not self.editable:
            p.fillRect(self.rect(), QColor(20, 20, 24, 90))

    def _xy(self, ev):
        pos = ev.position().toPoint()
        x, y = (pos.x() - 1) // ZOOM, (pos.y() - 1) // ZOOM
        return (x, y) if 0 <= x < 16 and 0 <= y < 16 else None

    def _fill(self, x, y, v):
        k = (y // 8) * 2 + (x // 8)
        ox, oy = (x // 8) * 8, (y // 8) * 8
        old = self.get(x, y)
        if old == v:
            return
        todo = [(x, y)]
        while todo:
            a, b = todo.pop()
            if not (ox <= a < ox + 8 and oy <= b < oy + 8) or self.get(a, b) != old:
                continue
            self.put(a, b, v)
            todo += [(a + 1, b), (a - 1, b), (a, b + 1), (a, b - 1)]
        del k

    def mousePressEvent(self, ev):
        xy = self._xy(ev)
        if xy is None:
            return
        k = (xy[1] // 8) * 2 + xy[0] // 8
        self.activated.emit()
        self.quadrant.emit(k)
        if ev.button() == Qt.RightButton:
            self.picked.emit(self.get(*xy))
            return
        if ev.modifiers() & Qt.ControlModifier:
            self.partPicked.emit(k)
            return
        if not self.editable:
            return
        self.aboutToChange.emit()
        if ev.modifiers() & Qt.ShiftModifier:
            self._fill(*xy, self.colour)
        else:
            self.put(*xy, self.colour)
            self._last = xy
        self.update()
        self.changed.emit()

    def mouseMoveEvent(self, ev):
        if self._last is None or not self.editable or not (ev.buttons() & Qt.LeftButton):
            return
        xy = self._xy(ev)
        if xy and xy != self._last:
            self.put(*xy, self.colour)
            self._last = xy
            self.update()
            self.changed.emit()

    def mouseReleaseEvent(self, ev):
        self._last = None


class AnimateTab(QWidget):
    applyRequested = Signal(object)      # dict: mt, effect, mid, a, b
    stillRequested = Signal(object)      # metatile: stop it moving (S99 r4)
    status = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.doc = self.renderer = self.room = None
        self.mt = None
        self.sheet = None
        self.pals = None
        self.cands = []
        v = QVBoxLayout(self)
        v.setContentsMargins(4, 4, 4, 4)
        v.setSpacing(4)
        # S99 r7 (user: "Not sure what 'use the brush' or 'use the selected
        # cell' does … no idea what selecting the animation drop down button
        # does"): numbered steps, plain labels, and the reason next to the
        # button whenever it is grey
        self.head = QLabel('Pick a tile: double-click a cell on the canvas, or use the brush.')
        self.head.setWordWrap(True)
        # S99 r6 (user: "I'm still very unclear how many tiles per room are
        # allowed to be animated. Would be good to have a count")
        self.budget = QLabel('')
        self.budget.setWordWrap(True)
        self.budget.setTextFormat(Qt.RichText)
        self.budget.setStyleSheet('background:#1d2a2e; color:#cfe; padding:4px; '
                                  'border-radius:3px;')
        v.addWidget(self.budget)
        v.addWidget(_wrap('<b>① The tile</b> — double-click it on the canvas, or:'))
        row = QHBoxLayout()
        self.b_cell = QPushButton('Load the selected cell')
        self.b_cell.setToolTip('Loads the tile of the cell selected on the canvas (Select tool, '
                               'click a cell) into ③ below. Double-clicking a cell does the same.')
        row.addWidget(self.b_cell)
        self.b_brush = QPushButton('Load the brush tile')
        self.b_brush.setToolTip('Loads the metatile on the paint brush into ③ below.')
        row.addWidget(self.b_brush)
        row.addStretch(1)
        v.addLayout(row)
        v.addWidget(self.head)
        v.addWidget(_wrap('<b>② How it moves</b>'))
        er = QHBoxLayout()
        self.r_slide = QRadioButton('Slide sideways')
        self.r_slide.setToolTip('The tile rolls 1 px sideways every 32 frames (3 steps one '
                                'way, 1 back) — water, lava, conveyors. Draw it so the left '
                                'and right edges meet.')
        self.r_flip = QRadioButton('Two-frame flip')
        self.r_flip.setToolTip('The tile alternates with a second frame you paint below '
                               '(every 32 frames in most rooms) — torches, eyes, swirls.')
        self.r_flip.setChecked(True)
        grp = QButtonGroup(self)
        grp.addButton(self.r_slide)
        grp.addButton(self.r_flip)
        er.addWidget(self.r_flip)
        er.addWidget(self.r_slide)
        er.addStretch(1)
        v.addLayout(er)
        self.eff_help = QLabel('')
        self.eff_help.setWordWrap(True)
        self.eff_help.setStyleSheet('color:#9ab;')
        v.addWidget(self.eff_help)
        self.r_slide.toggled.connect(lambda _on: self._effect_changed())
        self.src = QComboBox()
        # long entries must not widen the side panel (it clipped the tools)
        self.src.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.src.setMinimumContentsLength(18)
        self.src.view().setTextElideMode(Qt.ElideNone)
        self.src.setToolTip(
            'The game cannot animate a tile on its own: every animation belongs to one of '
            'its rooms (which tiles move, how, how often). Your room borrows ONE of them. '
            'Each entry is such a room; the best choice for this tile is first, and entries '
            'that cannot take it say why.')
        self.src.currentIndexChanged.connect(lambda _i: self._update_note())
        self.note = QLabel('')
        self.note.setWordWrap(True)
        self.note.setStyleSheet('color:#6ad8e6;')
        self.why = QLabel('')
        self.why.setWordWrap(True)
        self.why.setStyleSheet('color:#ffb060; font-weight:bold;')
        # frames
        self.paint_lbl = _wrap('<b>③ Paint the frames</b>')
        v.addWidget(self.paint_lbl)
        fr = QHBoxLayout()
        ca = QVBoxLayout()
        self.la = QLabel('Frame A (as it is now)')
        ca.addWidget(self.la)
        self.pad_a = PixelPad()
        ca.addWidget(self.pad_a)
        fr.addLayout(ca)
        cb = QVBoxLayout()
        self.lb = QLabel('Frame B (paint the second frame)')
        cb.addWidget(self.lb)
        self.pad_b = PixelPad()
        cb.addWidget(self.pad_b)
        fr.addLayout(cb)
        fr.addStretch(1)
        v.addLayout(fr)
        # colours + tools
        cr = QHBoxLayout()
        cr.addWidget(QLabel('Colour'))
        self.sw = []
        for i in range(4):
            b = QToolButton()
            b.setFixedSize(24, 24)
            b.setCheckable(True)
            b.clicked.connect(lambda _c, i=i: self._set_colour(i))
            cr.addWidget(b)
            self.sw.append(b)
        self.quad = 0
        cr.addStretch(1)
        cr.addWidget(QLabel('Preview'))
        self.preview = QLabel()
        self.preview.setFixedSize(48, 48)
        cr.addWidget(self.preview)
        v.addLayout(cr)
        hint = QLabel('left = paint · Shift+left = fill · right = pick a colour · '
                      'Ctrl+left = select that quarter')
        hint.setWordWrap(True)
        hint.setStyleSheet('color:#999;')
        v.addWidget(hint)
        # S99 r5 (user: "allow copy of quadrants separately not just a -> B.
        # Make it easier to edit"): every tool acts on the EDITED frame
        # (yellow border; click a pad to switch) and the selected PART
        # (whole tile or one 8x8 quarter)
        tv = QVBoxLayout()
        tv.setContentsMargins(0, 0, 0, 0)
        tv.setSpacing(3)
        pr = QHBoxLayout()
        pr.addWidget(QLabel('Part'))
        self.part_grp = QButtonGroup(self)
        self.part_grp.setExclusive(True)
        self.part_btns = {}
        b = QToolButton()
        b.setText('Whole tile')
        b.setCheckable(True)
        b.setChecked(True)
        b.setToolTip('Tools act on all four quarters')
        self.part_grp.addButton(b, 4)
        self.part_btns[None] = b
        pr.addWidget(b)
        qg = QGridLayout()
        qg.setSpacing(1)
        for k, arrow in enumerate(('◤', '◥', '◣', '◢')):
            b = QToolButton()
            b.setText(arrow)
            b.setFixedSize(24, 20)
            b.setCheckable(True)
            b.setToolTip(f'Tools act on the {PART_NAMES[k]} 8×8 quarter only '
                         '(or Ctrl+click that quarter on a frame)')
            self.part_grp.addButton(b, k)
            self.part_btns[k] = b
            qg.addWidget(b, k // 2, k % 2)
        pr.addLayout(qg)
        self.part_grp.idClicked.connect(lambda i: self._set_part(None if i == 4 else i))
        self.editing = QLabel('')
        self.editing.setWordWrap(True)
        self.editing.setStyleSheet('color:#ffe000;')
        pr.addWidget(self.editing, 1)
        tv.addLayout(pr)
        self.tool_btns = {}
        tips = {
            'copy': 'Copy the selected part of the frame being edited',
            'paste': 'Paste into the selected part of the frame being edited. A copied quarter '
                     'pasted on "Whole tile" fills all four quarters; a copied whole tile pasted '
                     'on a quarter gives that quarter.',
            'undo': 'Undo the last paint or tool on these frames (the room itself is untouched '
                    'until Make animated)',
            'revert': 'Back to the frames as loaded',
            'ab': "Copy frame A's selected part to frame B",
            'ba': "Copy frame B's selected part to frame A",
            'swap': 'Swap the selected part between the frames',
            'fh': 'Mirror left-right', 'fv': 'Mirror top-bottom',
            'clear': 'Fill with colour 0',
            'l': 'Shift 1 px left (wraps)', 'r': 'Shift 1 px right (wraps)',
            'u': 'Shift 1 px up (wraps)', 'd': 'Shift 1 px down (wraps)',
        }
        rows = [
            (None, [('copy', 'Copy', self._copy), ('paste', 'Paste', self._paste),
                    ('undo', 'Undo', self._undo), ('revert', 'Revert', self._revert)]),
            (None, [('ab', 'A → B', lambda: self._between('ab')),
                    ('ba', 'B → A', lambda: self._between('ba')),
                    ('swap', 'A ⇄ B', lambda: self._between('swap'))]),
            (None, [('fh', 'Flip ↔', lambda: self._xform('fh')),
                    ('fv', 'Flip ↕', lambda: self._xform('fv')),
                    ('clear', 'Clear', lambda: self._xform('clear'))]),
            ('Shift', [('l', '◀', lambda: self._xform('l')), ('r', '▶', lambda: self._xform('r')),
                       ('u', '▲', lambda: self._xform('u')), ('d', '▼', lambda: self._xform('d'))]),
        ]
        self.between_w = None
        for label, btns in rows:
            rw = QWidget()
            rl = QHBoxLayout(rw)
            rl.setContentsMargins(0, 0, 0, 0)
            rl.setSpacing(2)
            if label:
                rl.addWidget(QLabel(label))
            for key, t, fn in btns:
                b = QPushButton(t)
                b.setToolTip(tips[key])
                b.clicked.connect(fn)
                rl.addWidget(b, 1)
                self.tool_btns[key] = b
            tv.addWidget(rw)
            if btns[0][0] == 'ab':
                self.between_w = rw
        self.tools_w = QWidget()
        self.tools_w.setLayout(tv)
        v.addWidget(self.tools_w)
        self.part = None
        self.clip = None                   # (size 8|16, rows, source palettes)
        self._hist = []
        self._loaded = None
        v.addWidget(_wrap('<b>④ Borrow the motion from</b> (one game room\'s animation '
                           'per room — best choice first)'))
        v.addWidget(self.src)
        v.addWidget(self.note)
        v.addWidget(self.why)
        self.apply_b = QPushButton('Make animated')
        self.apply_b.setStyleSheet('font-weight:bold;')
        self.apply_b.clicked.connect(self._apply)
        v.addWidget(self.apply_b)
        self.still_b = QPushButton('Make still')
        self.still_b.setToolTip('Stop this tile moving in this room: its current graphics get '
                                'copies in ordinary (still) slots and this room\'s cells of it '
                                'use them. Other animated tiles keep moving.')
        self.still_b.clicked.connect(lambda: self.mt and self.stillRequested.emit(self.mt))
        v.addWidget(self.still_b)
        v.addStretch(1)
        for pad in (self.pad_a, self.pad_b):
            pad.changed.connect(self._frames_changed)
            pad.picked.connect(self._set_colour)
            pad.quadrant.connect(self._quad)
            pad.aboutToChange.connect(self._snap)
            pad.activated.connect(lambda pad=pad: self._set_active(pad))
            pad.partPicked.connect(self._pick_part)
        self.active = self.pad_b
        self._tick = 0
        self.timer = QTimer(self)
        self.timer.setInterval(int(1000 * 8 / ANIM.FPS))      # 8 game frames per step
        self.timer.timeout.connect(self._step)
        self.timer.start()
        self.set_enabled(False)

    # ------------------------------------------------------------ context
    def set_enabled(self, on, why=''):
        for w in (self.r_slide, self.r_flip, self.src, self.pad_a, self.pad_b,
                  self.tools_w, self.apply_b, self.b_brush, self.b_cell, self.still_b):
            w.setEnabled(on)
        if why:
            self.head.setText(why)

    def set_tile(self, doc, renderer, room, sheet, pals, mt, where=''):
        """Load a metatile of `room` (a custom room) into the tab."""
        self.doc, self.renderer, self.room = doc, renderer, room
        self.sheet, self.pals, self.mt = bytes(sheet), pals, dict(mt)
        self.set_enabled(True)
        self.update_budget()
        tiles = [t & 0x7F for t in mt['tiles']]
        mp = metatile_pals(mt) or [0] * 4
        self.sub_pals = [pals[p & 7] for p in mp]
        a = [decode_2bpp(self.sheet[t * 16:t * 16 + 16]) for t in tiles]
        cur = doc.anim_of_metatile(room, mt)
        cells = len(doc._cells_of(room, mt))
        b = [list(x) for x in a]
        if cur['effect'] == 'flip':
            for k, p in cur['partners'].items():
                b[k] = decode_2bpp(self.sheet[p * 16:p * 16 + 16])
            self.r_flip.setChecked(True)
        elif cur['effect'] == 'slide':
            self.r_slide.setChecked(True)
        else:
            pass                  # frame B starts as A: paint what changes (S99 r7)
        self.pad_a.set_pixels(a, self.sub_pals)
        self.pad_b.set_pixels(b, self.sub_pals)
        self._hist = []
        self._loaded = self._state()
        moving = bool({t & 0x7F for t in mt['tiles']} & doc.room_animation(room)['slots'])
        self.still_b.setEnabled(moving)
        now = ('not animated' if cur['effect'] is None else
               f"animated now: {cur['effect']} with ${cur['map']:02X}'s animation")
        self.head.setText(f"<b>{mt.get('name') or 'metatile'}</b> {tiles}{where} — {now}. "
                          f"{cells} cell(s) of this room draw it (all of them change).")
        self._quad(0)
        self._effect_changed()

    @staticmethod
    def _shifted(px):
        return [px[y * 8 + (x - 1) % 8] for y in range(8) for x in range(8)]

    def effect(self):
        return 'slide' if self.r_slide.isChecked() else 'flip'

    def frames(self):
        a = [encode_2bpp(p) for p in self.pad_a.px]
        b = [encode_2bpp(p) for p in self.pad_b.px] if self.effect() == 'flip' else None
        return a, b

    # ------------------------------------------------------------ events
    def _effect_changed(self):
        flip = self.effect() == 'flip'
        self.eff_help.setText(
            'Two-frame flip: the tile alternates between frame A and a frame B you paint. '
            'Quarters you leave the same in B stay still (and keep their walkability).'
            if flip else
            'Slide: every quarter of the tile rolls 1 px sideways and back (water, lava). '
            'Uses one slot per different quarter.')
        self.lb.setText('Frame B (paint what changes)')
        self.pad_b.setVisible(flip)
        self.lb.setVisible(flip)
        self.between_w.setVisible(flip)
        self._set_active(self.active if flip else self.pad_a)
        self._refresh_sources()

    def _frames_changed(self):
        self._refresh_sources(keep=True)

    def _refresh_sources(self, keep=False):
        if self.doc is None or self.mt is None:
            return
        a, b = self.frames()
        old = self.src.currentData()
        self.cands = self.doc.animate_candidates(self.room, self.mt, self.effect(), a, b)
        self.src.blockSignals(True)
        self.src.clear()
        for c in self.cands:
            tags = []
            if c['current']:
                tags.append("this room's animation")
            if not c['fits'] and not c.get('room_ok', True):
                tags.append("can't: tileset full")
            elif not c['fits']:
                tags.append("can't: too small")
            elif c.get('shift'):
                tags.append('moves the wall/walkable split')
            elif not c['walk_ok']:
                tags.append('changes walkability')
            if c['fits'] and c.get('takes'):
                tags.append(f"full: takes over slot(s) {ANIM.rng(c['takes'])}")
            elif c['fits'] and c['stops']:
                tags.append(f"switch: {c['stops']} moving cell(s) stand still")
            self.src.addItem(c['label'] + (f"  [{', '.join(tags)}]" if tags else ''), c['map'])
        i = self.src.findData(old) if keep and old is not None else 0
        if i >= 0 and i < len(self.cands) and not self.cands[i]['fits']:
            i = 0                     # the kept choice no longer fits: best one
        self.src.setCurrentIndex(max(i, 0))
        self.src.blockSignals(False)
        self._update_note()

    def _cand(self):
        mid = self.src.currentData()
        return next((c for c in self.cands if c['map'] == mid), None)

    def _update_note(self):
        c = self._cand()
        flip = self.effect() == 'flip'
        unit = 'slot' if not flip else 'pair'
        if c is None:
            self.note.setText('')
            if not self.mt:
                why = ''
            elif flip and not self._changes():
                why = ('Frame B is the same as frame A, so nothing would move. Paint what '
                       'should change in frame B (tip: select a quarter and use the tools).')
            else:
                why = f'No animation in the game can move this tile as a {self.effect()}.'
            self.why.setText(why)
            self.apply_b.setEnabled(False)
            return
        bits, why = [], ''
        if not c['fits'] and not c.get('room_ok', True):
            if c.get('short_any'):
                sh = f"{c['short_any']} more free slot(s)"
            else:
                sh = ' and '.join(f'{n} more free {side} slot(s)'
                                  for side, n in (c.get('short') or {}).items() if n)
            lib = c.get('lib_only') or 0
            why = (f"Can't: {c['moves']} tile(s) already sit in this animation's slots and "
                   f"must move to free slots, and this tileset needs {sh} for that. A free "
                   'slot = a graphic no cell and no My metatile uses — changing walkability '
                   'does not free one. '
                   + (f'{lib} slot(s) here are held only by unused My metatiles: Tileset tab '
                      '→ purge unused frees them. ' if lib else
                      'Free some in the Tileset tab (purge unused / release). ')
                   + 'Or pick another animation in the list, or change fewer quarters in '
                     'frame B.')
        elif not c['fits']:
            why = (f"Can't: this animation moves {c.get('offer', len(c['free']))} {unit}(s) in "
                   f"all; this tile needs {c['units']} (one per quarter that "
                   f"{'changes' if flip else 'slides'}; identical quarters share one). Pick "
                   'a bigger one in the list' + (', or change fewer quarters in frame B'
                                                 if flip else '') + '.')
        else:
            bits.append(f"uses {c['units']} {unit}(s)"
                        + (f", moves {c['moves']} still tile(s) out of the way" if c['moves']
                           else ''))
            if c.get('shift'):
                n = abs(c['shift'])
                bits.append(f"this tileset has no free {'wall' if c['shift'] > 0 else 'walkable'}"
                            f" slot for that, so the editor turns {n} free "
                            f"{'walkable' if c['shift'] > 0 else 'wall'} slot(s) into "
                            f"{'wall' if c['shift'] > 0 else 'walkable'} ones (moves the "
                            'wall/walkable split; nothing changes on screen or in walkability)')
            if not c['walk_ok']:
                bits.append("its slots sit on the other side of the wall/walkable split, so the "
                            "tile's bottom-right quarter changes walkability (leave that quarter "
                            'the same in frame B to keep it)')
            if c.get('takes'):
                bits.append(f"this animation is FULL, so this tile TAKES OVER slot(s) "
                            f"{ANIM.rng(c['takes'])} from what moves there now: in {c['stops']} "
                            'cell(s) the quarters drawn from those slots will stand still '
                            '(same look; any other moving quarters keep moving — Make still '
                            'stops a tile completely)')
            elif c['stops']:
                bits.append(f"switching the room to it STOPS {c['stops']} cell(s) already "
                            'moving here (they keep their current look)')
            if flip:
                bits.append(f"flips every {self._period(c['map'])} frames")
        self.note.setText(('; '.join(bits) + '.') if bits else '')
        self.why.setText(why)
        self.apply_b.setEnabled(bool(c['fits']))

    def _changes(self):
        return any(self.pad_a.px[k] != self.pad_b.px[k] for k in range(4))

    @staticmethod
    def _period(mid):
        ps = sorted({e['period_frames'] for e in ANIM.handler(mid).get('effects') or []
                     if e['kind'] == 'swap'})
        return '/'.join(str(p) for p in ps) or '32'

    def _quad(self, k):
        self.quad = k
        pal = self.pad_a.pals[k] if self.pad_a.pals else [(0, 0, 0)] * 4
        for i, b in enumerate(self.sw):
            c = pal[i]
            b.setStyleSheet(f'background: rgb{tuple(c)}; border: 2px solid '
                            f"{'#ffe000' if i == self.pad_a.colour else '#333'};")

    def _set_colour(self, i):
        self.pad_a.colour = self.pad_b.colour = i
        self._quad(self.quad)

    # ------------------------------------------------ part tools (S99 r5)
    def _state(self):
        return ([list(p) for p in self.pad_a.px], [list(p) for p in self.pad_b.px])

    def _snap(self):
        self._hist.append(self._state())
        del self._hist[:-100]

    def _restore(self, st):
        self.pad_a.set_pixels(st[0], self.pad_a.pals)
        self.pad_b.set_pixels(st[1], self.pad_b.pals)
        self._frames_changed()

    def _undo(self):
        if not self._hist:
            self.status.emit('Nothing to undo on these frames.')
            return
        self._restore(self._hist.pop())

    def _revert(self):
        if self._loaded is None:
            return
        self._snap()
        self._restore(self._loaded)

    def _set_active(self, pad):
        if pad is self.pad_b and self.effect() != 'flip':
            pad = self.pad_a
        self.active = pad
        self.pad_a.active, self.pad_b.active = pad is self.pad_a, pad is self.pad_b
        self.pad_a.update()
        self.pad_b.update()
        self._update_editing()

    def _set_part(self, k):
        self.part = k
        self.part_btns[k].setChecked(True)
        for pad in (self.pad_a, self.pad_b):
            pad.sel = k
            pad.update()
        self._update_editing()

    def _pick_part(self, k):
        # Ctrl+click the selected quarter again = back to the whole tile
        self._set_part(None if self.part == k else k)

    def _part_name(self):
        return 'whole tile' if self.part is None else f'{PART_NAMES[self.part]} quarter'

    def _update_editing(self):
        f = 'A' if self.active is self.pad_a else 'B'
        self.editing.setText(f'editing frame {f} · {self._part_name()}')

    @staticmethod
    def _region(pad, part):
        """Rows of colour indices: 16x16 for the whole tile, 8x8 for a quarter."""
        if part is None:
            return [[pad.get(x, y) for x in range(16)] for y in range(16)]
        return [list(pad.px[part][y * 8:y * 8 + 8]) for y in range(8)]

    @staticmethod
    def _put_region(pad, part, g):
        if part is None:
            for y in range(16):
                for x in range(16):
                    pad.put(x, y, g[y][x])
        else:
            pad.px[part] = [v for row in g for v in row]
        pad.update()

    def _copy(self):
        pad = self.active
        pals = [pad.pals[k] for k in (range(4) if self.part is None else (self.part,))]
        self.clip = (16 if self.part is None else 8, self._region(pad, self.part), pals)
        self.status.emit(f"Copied frame {'A' if pad is self.pad_a else 'B'}'s "
                         f'{self._part_name()}.')

    def _paste(self):
        if self.clip is None:
            self.status.emit('Copy a part first.')
            return
        size, g, cpals = self.clip
        pad = self.active
        self._snap()
        if size == 16 and self.part is not None:           # whole -> one quarter
            ox, oy = (self.part % 2) * 8, (self.part // 2) * 8
            g = [row[ox:ox + 8] for row in g[oy:oy + 8]]
            cpals = [cpals[self.part]]
        if size == 8 and self.part is None:                # quarter -> all four
            for k in range(4):
                self._put_region(pad, k, g)
            targets = range(4)
        else:
            self._put_region(pad, self.part, g)
            targets = range(4) if self.part is None else (self.part,)
        differ = any(list(pad.pals[k]) != list(cpals[k] if len(cpals) == 4 else cpals[0])
                     for k in targets)
        self.status.emit(f'Pasted into the {self._part_name()}' +
                         (' — that part uses a different palette, so the same colour numbers '
                          'show as its own colours.' if differ else '.'))
        self._frames_changed()

    def _between(self, op):
        a = self._region(self.pad_a, self.part)
        b = self._region(self.pad_b, self.part)
        self._snap()
        if op in ('ab', 'swap'):
            self._put_region(self.pad_b, self.part, a)
        if op in ('ba', 'swap'):
            self._put_region(self.pad_a, self.part, b)
        self._frames_changed()

    def _copy_ab(self):
        """Whole frame A -> frame B (kept for callers; = Part: whole, A → B)."""
        self._snap()
        self._put_region(self.pad_b, None, self._region(self.pad_a, None))
        self._frames_changed()

    def _xform(self, op):
        pad, part = self.active, self.part
        g = self._region(pad, part)
        self._snap()
        n = len(g)
        if op == 'fh':
            g = [row[::-1] for row in g]
        elif op == 'fv':
            g = g[::-1]
        elif op == 'l':
            g = [row[1:] + row[:1] for row in g]
        elif op == 'r':
            g = [row[-1:] + row[:-1] for row in g]
        elif op == 'u':
            g = g[1:] + g[:1]
        elif op == 'd':
            g = g[-1:] + g[:-1]
        elif op == 'clear':
            g = [[0] * n for _ in range(n)]
        self._put_region(pad, part, g)
        self._frames_changed()

    def _step(self):
        """Preview at game timing: one tick = 8 game frames."""
        if self.mt is None or not self.isVisible():
            return
        self._tick = (self._tick + 1) % 128
        frame = self._tick * 8
        if self.effect() == 'flip':
            show_b = (frame // 32) % 2 == 1
            px = self.pad_b.px if show_b else self.pad_a.px
        else:
            # slide: the roll pattern (per 128 frames: R at 7/39/71, L at 103)
            shift = 0
            for f in range(0, frame + 1):
                m = f & 0x7F
                if m in (7, 39, 71):
                    shift += 1
                elif m == 103:
                    shift -= 1
            px = [[p[y * 8 + (x - shift) % 8] for y in range(8) for x in range(8)]
                  for p in self.pad_a.px]
        img = Image.new('RGB', (16, 16))
        for k in range(4):
            ox, oy = (k % 2) * 8, (k // 2) * 8
            for i, v in enumerate(px[k]):
                img.putpixel((ox + i % 8, oy + i // 8), tuple(self.pad_a.pals[k][v]))
        img = img.resize((48, 48), Image.NEAREST)
        self.preview.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(img)))

    def _apply(self):
        c = self._cand()
        if c is None or not c['fits']:
            return
        a, b = self.frames()
        self.applyRequested.emit({'mt': self.mt, 'effect': self.effect(), 'mid': c['map'],
                                  'a': a, 'b': b, 'stops': c['stops'],
                                  'takes': list(c.get('takes') or []),
                                  'label': c['label']})

    # ------------------------------------------------ the count (S99 r6)
    def show_room(self, doc, room):
        """The Rooms tab shows `room` (a custom room, or None for a vanilla
        one): refresh the count; a tile loaded from ANOTHER room is dropped
        (it must never be applied to this one)."""
        rid = room.get('id') if room else None
        if self.room is not None and self.room.get('id') != rid:
            self.mt = None
        self.doc, self.room = doc, room
        if room is None or not room.get('record'):
            self.set_enabled(False, 'Vanilla room — "Make editable" first; the outline '
                                    '(Anim) shows what already animates.')
            self.budget.setText('')
            return
        if self.mt is None:
            self.set_enabled(False, 'Pick a tile: double-click a cell on the canvas, or use '
                                    'the brush.')
            self.b_brush.setEnabled(True)
            self.b_cell.setEnabled(True)
        else:
            self.room = doc.room(rid) or room
        self.update_budget()

    def update_budget(self):
        if self.doc is None or self.room is None:
            self.budget.setText('')
            return
        self.budget.setText(budget_html(self.doc, self.room))
