"""metatile_picker.py — the brush palette of player-sized tiles (S94 → S95).

A metatile = 4 subtiles (tl, tr, bl, br) + a palette slot: the thing the
author places on the 10×8 cell grid. Three sections:
  • THIS ROOM'S TILES — the room's VOCABULARY: every distinct metatile used
    on ANY screen/state of the room, plus (for a clone) everything its
    vanilla source room uses — so a tile you painted over is still here to
    paint back (user, S95: "should NOT disappear if I remove them");
  • FROM ANOTHER ROOM — the vocabulary of a room chosen in the combo above
    the picker, drawn with THIS room's palettes. Same tileset → plain brush;
    different tileset → the click IMPORTS the 4 subtiles into this room's
    (project-owned) tileset in free slots and the result lands in "My
    metatiles" (`Document.import_metatile`);
  • MY METATILES — the author's own, built in the metatile editor from any
    4 subtiles, stored per tileset under custom._editor.metatiles
    (editor-only data; the compiler ignores underscore keys).
Click = brush (and the canvas switches to Paint). Right-click a custom
metatile to delete it.
  • PARKED (S171 r5, editor2/core/parking.py) — metatiles kept with their own graphics
    that hold NO tileset slot (only tiles placed on screens do). Click = bring it into the
    tileset and paint with it (`parkedPicked`); right-click = delete it.
"""

from PIL import Image, ImageQt
from PySide6.QtCore import QRect, QSize, Qt, Signal
from PySide6.QtGui import QColor, QPainter, QPen, QPixmap
from PySide6.QtWidgets import QMenu, QWidget

from editor2.core.document import metatile_key, metatile_pals
from editor2.core import page2 as P2

PER_ROW = 8
S = 2                       # scale
MT = 16 * S                 # metatile pixel size on screen
GAP = 4
HDR = 18


class MetatilePicker(QWidget):
    brushSelected = Signal(object)
    hoverInfo = Signal(str)
    removeRequested = Signal(int)          # index in the custom list
    editRequested = Signal(object)         # metatile dict (to seed the editor)
    importRequested = Signal(object)       # foreign metatile dict (other tileset)
    foreignSelection = Signal(int)         # S171 r4: how many foreign metatiles are ticked
    parkedPicked = Signal(int)             # S171 r5: index in the parked list -> unpark + brush
    parkedRemove = Signal(int)             # S171 r5: delete a parked metatile

    SECTIONS = ('found', 'foreign', 'custom')

    def __init__(self, parent=None, sections=('found', 'custom')):
        super().__init__(parent)
        self.sections = tuple(sections)     # S95: tabbed — one picker per tab
        self.renderer = None
        self.sheet = None
        self.pals = None
        self.threshold = 0
        self.found = []           # [metatile]
        self.custom = []          # [metatile] (with 'name')
        self.parked = []          # S171 r5: parking entries (no slots; own graphics)
        self.foreign = []         # [metatile] from another room
        self.foreign_sheet = None
        self.foreign_threshold = 0
        self.foreign_same = True  # foreign room shares this tileset?
        self.foreign_pals = None  # S171 r4: the source's own colours (None = this room's)
        self.foreign_ticked = set()
        self.foreign_title = ''
        self.flags = {}           # tile index -> 'released' | 'changed' (S96)
        self.anim = set()         # S99: slots the room's animation changes
        self.free_text = ''       # "12 wall / 40 walkable slots free"
        self.selected = None      # (section, index)
        self._hover = None
        self._pix = {}
        self.setMouseTracking(True)
        self.setMinimumWidth(PER_ROW * (MT + GAP) + GAP)

    # --------------------------------------------------------------- data
    def set_context(self, renderer, sheet, pals, threshold):
        # S132: keep the cached pictures while the sheet and colours are the same
        if (renderer is not self.renderer or sheet != self.sheet or pals != self.pals):
            self._pix = {}
        self.renderer, self.sheet, self.pals, self.threshold = renderer, sheet, pals, threshold

    def set_flags(self, flags, free_text=''):
        """P3.3c: vocabulary tiles whose slot is RELEASED (graphic may change
        on the next import) or already CHANGED get a corner mark."""
        self.flags, self.free_text = dict(flags), free_text
        self.update()

    def set_animated(self, slots):
        """S99: metatiles using an animated slot get a teal corner mark."""
        self.anim = set(slots or ())
        self.update()

    def _animated(self, sec, mt):
        return sec in ('found', 'custom') and any(P2.slot_key(t) in self.anim for t in mt['tiles'])

    def _flag(self, mt):
        f = {self.flags.get(P2.slot_key(t)) for t in mt['tiles']}
        return 'changed' if 'changed' in f else 'released' if 'released' in f else None

    def set_lists(self, found, custom):
        # S132: painting re-sends the same lists after every stroke — nothing to
        # redraw then; pictures are cached by metatile (sheet + colours unchanged)
        found, custom = list(found), list(custom)
        if found == self.found and custom == self.custom:
            return
        self.found, self.custom = found, custom
        self._relayout()

    def set_parked(self, entries):
        """S171 r5: the tileset's parked metatiles (parking.parked) — drawn from their own
        graphics, after My metatiles."""
        entries = list(entries)
        if entries == self.parked:
            return
        self.parked = entries
        self._pix = {k: v for k, v in self._pix.items() if k[0] != 'parked'}
        self._relayout()

    def _shown(self):
        out = []
        for sec in self.sections:
            if sec == 'foreign' and not self.foreign_title:
                continue
            out.append(sec)
            if sec == 'custom' and self.parked:
                out.append('parked')
        return out

    def set_foreign(self, title, mts, sheet, threshold, same_tileset, pals=None):
        """S171 r4: `pals` = the SOURCE's own colours (Borrow → match colours shows the
        tiles as they really look); None = drawn in this room's colours."""
        self.foreign_title = title
        self.foreign = list(mts)
        self.foreign_sheet = sheet
        self.foreign_threshold = threshold
        self.foreign_same = same_tileset
        self.foreign_pals = pals
        self.foreign_ticked = set()
        self.foreignSelection.emit(0)
        self._pix = {k: v for k, v in self._pix.items() if k[0] != 'foreign'}
        self._relayout()

    def _list(self, sec):
        return {'found': self.found, 'foreign': self.foreign, 'custom': self.custom,
                'parked': self.parked}[sec]

    def select_metatile(self, mt):
        """Select the entry equal to mt (found list first); returns index or None."""
        for sec in ('found', 'custom'):
            for i, m in enumerate(self._list(sec)):
                if metatile_key(m) == metatile_key(mt):
                    self.selected = (sec, i)
                    self.update()
                    return self.selected
        self.selected = None
        self.update()
        return None

    def _rows(self, sec):
        n = len(self._list(sec)) + (1 if sec == 'custom' else 0)
        if sec == 'foreign' and not self.foreign_title:
            return 0
        return max(1 if sec == 'custom' else 0, (n + PER_ROW - 1) // PER_ROW)

    def _relayout(self):
        h = GAP
        for sec in self._shown():
            h += HDR + self._rows(sec) * (MT + GAP) + GAP
        self.setFixedHeight(max(h, 80))
        self.update()

    def _render_parked(self, i, e):
        key = ('parked', i, tuple(q['g'] for q in e['q']), tuple(q['row'] for q in e['q']))
        if key not in self._pix:
            if self.pals is None:
                return None
            from editor2.core import tile_draw as TD
            img = Image.new('RGB', (16, 16))
            for q, d in enumerate(e['q']):
                px = TD.decode_tile(bytes.fromhex(d['g']))
                row = self.pals[int(d['row'])] if int(d['row']) < len(self.pals) else self.pals[0]
                t = Image.new('RGB', (8, 8))
                t.putdata([tuple(row[c][:3]) for c in px])
                img.paste(t, ((q % 2) * 8, (q // 2) * 8))
            img = img.resize((MT, MT), Image.NEAREST)
            self._pix[key] = QPixmap.fromImage(ImageQt.ImageQt(img))
        return self._pix[key]

    def _render(self, sec, mt):
        sheet = self.foreign_sheet if sec == 'foreign' else self.sheet
        key = (sec if sec == 'foreign' else 'own',) + metatile_key(mt)
        if key not in self._pix:
            if self.renderer is None or sheet is None:
                return None
            img = Image.new('RGB', (16, 16))
            pals = metatile_pals(mt) or [0] * 4
            rows = self.pals
            if sec == 'foreign' and getattr(self, 'foreign_pals', None) is not None:
                rows = self.foreign_pals
            for i, t in enumerate(mt['tiles']):
                img.paste(self.renderer.render_tile(sheet, t, rows, pals[i]),
                          ((i % 2) * 8, (i // 2) * 8))
            img = img.resize((MT, MT), Image.NEAREST)
            self._pix[key] = QPixmap.fromImage(ImageQt.ImageQt(img))
        return self._pix[key]

    # ------------------------------------------------------------ geometry
    def _section_top(self, sec):
        y = 0
        for s in self._shown():
            if s == sec:
                return y + HDR
            y += HDR + self._rows(s) * (MT + GAP) + GAP
        return y + HDR

    def _rect(self, sec, i):
        y0 = self._section_top(sec)
        return QRect(GAP + (i % PER_ROW) * (MT + GAP), y0 + (i // PER_ROW) * (MT + GAP), MT, MT)

    def _hit(self, pos):
        for sec in self._shown():
            n = len(self._list(sec)) + (1 if sec == 'custom' else 0)   # + the "+" tile
            for i in range(n):
                if self._rect(sec, i).contains(pos):
                    return (sec, i)
        return None

    # --------------------------------------------------------------- paint
    def paintEvent(self, ev):
        p = QPainter(self)
        p.fillRect(self.rect(), QColor(36, 36, 40))
        titles = {
            'found': (f"This room's tiles ({len(self.found)})  — whole vocabulary"
                      + (f"  · {self.free_text}" if self.free_text else '')),
            'foreign': (f"From {self.foreign_title} ({len(self.foreign)})  — "
                        + ('same tileset: click = brush' if self.foreign_same
                           else 'other tileset: click = import into this tileset')),
            'custom': f'My metatiles ({len(self.custom)})  — click + to build one',
            'parked': (f'Parked ({len(self.parked)})  — no slots used; click = bring into '
                       'the tileset and paint'),
        }
        if 'foreign' in self.sections and not self.foreign_title:
            p.setPen(QColor(160, 160, 160))
            p.drawText(QRect(GAP, 0, self.width() - 2 * GAP, 60),
                       Qt.AlignTop | Qt.AlignLeft | Qt.TextWordWrap,
                       'Pick a room above. Its tiles are drawn with THIS room\'s '
                       'palettes; same tileset = brush, other tileset = click imports.')
        for sec in self._shown():
            y = self._section_top(sec) - HDR
            p.setPen(QColor(200, 200, 200))
            p.drawText(QRect(GAP, y, self.width(), HDR), Qt.AlignVCenter | Qt.AlignLeft,
                       titles[sec])
            thr = self.foreign_threshold if sec == 'foreign' else self.threshold
            if sec == 'parked':
                for i, e in enumerate(self.parked):
                    self._draw_parked(p, self._rect(sec, i), i, e)
                continue
            for i, mt in enumerate(self._list(sec)):
                self._draw(p, self._rect(sec, i), sec, mt, (sec, i), thr)
        if 'custom' not in self.sections:
            return
        r = self._rect('custom', len(self.custom))
        pen = QPen(QColor(120, 120, 130))
        pen.setStyle(Qt.DashLine)
        p.setPen(pen)
        p.setBrush(Qt.NoBrush)
        p.drawRect(r.adjusted(0, 0, -1, -1))
        p.setPen(QColor(220, 220, 220))
        p.drawText(r, Qt.AlignCenter, '+')

    def _draw_parked(self, p, r, i, e):
        pm = self._render_parked(i, e)
        if pm is not None:
            p.drawPixmap(r, pm)
        # parked: a dashed grey frame + the walkable corner
        pen = QPen(QColor(170, 170, 190))
        pen.setStyle(Qt.DashLine)
        p.setPen(pen)
        p.setBrush(Qt.NoBrush)
        p.drawRect(r.adjusted(0, 0, -1, -1))
        p.fillRect(QRect(r.right() - 5, r.bottom() - 5, 5, 5),
                   QColor(60, 220, 90) if e.get('walk') else QColor(255, 60, 60))
        p.fillRect(QRect(r.x(), r.y(), 7, 7), QColor(150, 150, 170))
        if self._hover == ('parked', i):
            p.setPen(QPen(QColor(255, 255, 255, 180), 1))
            p.drawRect(r.adjusted(0, 0, -1, -1))

    def _draw(self, p, r, sec, mt, key, thr):
        pm = self._render(sec, mt)
        if pm is not None:
            p.drawPixmap(r, pm)
        if sec == 'foreign' and key[1] in getattr(self, 'foreign_ticked', ()):
            pen = QPen(QColor('#ffe000'))
            pen.setWidth(3)
            p.setPen(pen)
            p.setBrush(Qt.NoBrush)
            p.drawRect(r.adjusted(1, 1, -2, -2))
        # walkability corner (bottom-right subtile decides — S94 measurement)
        wall = (mt['tiles'][3] & 0xFF) < thr
        p.fillRect(QRect(r.right() - 5, r.bottom() - 5, 5, 5),
                   QColor(255, 60, 60) if wall else QColor(60, 220, 90))
        fl = self._flag(mt) if sec == 'found' else None
        if fl:
            p.fillRect(QRect(r.x(), r.y(), 7, 7),
                       QColor(255, 40, 40) if fl == 'changed' else QColor(255, 150, 40))
        if self._animated(sec, mt):
            p.fillRect(QRect(r.right() - 6, r.y(), 7, 7), QColor(40, 200, 220))
        if self._hover == key:
            p.setPen(QPen(QColor(255, 255, 255, 180), 1))
            p.setBrush(Qt.NoBrush)
            p.drawRect(r.adjusted(0, 0, -1, -1))
        if self.selected == key:
            pen = QPen(QColor(255, 230, 0))
            pen.setWidth(3)
            p.setPen(pen)
            p.setBrush(Qt.NoBrush)
            p.drawRect(r.adjusted(1, 1, -2, -2))

    # -------------------------------------------------------------- events
    def mouseMoveEvent(self, ev):
        h = self._hit(ev.position().toPoint())
        if h != self._hover:
            self._hover = h
            self.update()
            if h is None:
                self.hoverInfo.emit('')
            else:
                sec, i = h
                if sec == 'custom' and i == len(self.custom):
                    self.hoverInfo.emit('Build a new metatile from 4 subtiles')
                elif sec == 'parked':
                    e = self.parked[i]
                    self.hoverInfo.emit(
                        f"{e.get('name', 'metatile')}  PARKED — uses no tileset slot; click "
                        "brings it into the tileset (it takes slots then) and paints with it  "
                        f"{'walkable' if e.get('walk') else 'WALL'}   right-click = delete")
                else:
                    mt = self._list(sec)[i]
                    thr = self.foreign_threshold if sec == 'foreign' else self.threshold
                    walk = 'WALL' if (mt['tiles'][3] & 0xFF) < thr else 'walkable'
                    extra = ''
                    fl = self._flag(mt) if sec == 'found' else None
                    if fl == 'changed':
                        extra = '   GRAPHIC CHANGED — a released slot was reused'
                    elif fl == 'released':
                        extra = '   slot released — graphic may change on the next import'
                    if self._animated(sec, mt):
                        extra += '   ANIMATED in game (this room\'s tile animation)'
                    if sec == 'foreign' and not self.foreign_same:
                        extra = '   (click imports the 4 subtiles into this tileset)'
                    self.hoverInfo.emit(
                        f"{mt.get('name', 'metatile')}  subtiles {mt['tiles']}  "
                        f"palette {mt.get('pal')}  {walk}{extra}")

    def leaveEvent(self, ev):
        self._hover = None
        self.update()

    def mousePressEvent(self, ev):
        h = self._hit(ev.position().toPoint())
        if h is None:
            return
        sec, i = h
        if sec == 'custom' and i == len(self.custom):
            if ev.button() == Qt.LeftButton:
                self.editRequested.emit(None)
            return
        if sec == 'parked':
            if ev.button() == Qt.RightButton:
                m = QMenu(self)
                a_del = m.addAction('Delete this parked metatile')
                if m.exec(ev.globalPosition().toPoint()) == a_del:
                    self.parkedRemove.emit(i)
            elif ev.button() == Qt.LeftButton:
                self.parkedPicked.emit(i)
            return
        mt = self._list(sec)[i]
        if ev.button() == Qt.RightButton:
            m = QMenu(self)
            a_edit = m.addAction('Open in metatile editor…') if sec != 'foreign' else None
            a_del = m.addAction('Delete') if sec == 'custom' else None
            a_imp = (m.addAction('Import into this tileset')
                     if sec == 'foreign' and not self.foreign_same else None)
            chosen = m.exec(ev.globalPosition().toPoint())
            if a_edit is not None and chosen == a_edit:
                self.editRequested.emit(mt)
            elif a_del is not None and chosen == a_del:
                self.removeRequested.emit(i)
            elif a_imp is not None and chosen == a_imp:
                self.importRequested.emit(mt)
            return
        if sec == 'foreign' and not self.foreign_same:
            # S171 r4: Ctrl / Shift + click ticks several for "Import the selected"
            if ev.modifiers() & (Qt.ControlModifier | Qt.ShiftModifier):
                t = getattr(self, 'foreign_ticked', set())
                t ^= {i}
                self.foreign_ticked = t
                self.foreignSelection.emit(len(t))
                self.update()
                return
            self.importRequested.emit(mt)
            return
        self.selected = h
        self.update()
        self.brushSelected.emit(mt)
