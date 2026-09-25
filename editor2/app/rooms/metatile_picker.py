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
"""

from PIL import Image, ImageQt
from PySide6.QtCore import QRect, QSize, Qt, Signal
from PySide6.QtGui import QColor, QPainter, QPen, QPixmap
from PySide6.QtWidgets import QMenu, QWidget

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
        self.foreign = []         # [metatile] from another room
        self.foreign_sheet = None
        self.foreign_threshold = 0
        self.foreign_same = True  # foreign room shares this tileset?
        self.foreign_title = ''
        self.selected = None      # (section, index)
        self._hover = None
        self._pix = {}
        self.setMouseTracking(True)
        self.setMinimumWidth(PER_ROW * (MT + GAP) + GAP)

    # --------------------------------------------------------------- data
    def set_context(self, renderer, sheet, pals, threshold):
        self.renderer, self.sheet, self.pals, self.threshold = renderer, sheet, pals, threshold
        self._pix = {}

    def set_lists(self, found, custom):
        self.found, self.custom = list(found), list(custom)
        self._pix = {}
        self._relayout()

    def set_foreign(self, title, mts, sheet, threshold, same_tileset):
        self.foreign_title = title
        self.foreign = list(mts)
        self.foreign_sheet = sheet
        self.foreign_threshold = threshold
        self.foreign_same = same_tileset
        self._pix = {k: v for k, v in self._pix.items() if k[0] != 'foreign'}
        self._relayout()

    def _list(self, sec):
        return {'found': self.found, 'foreign': self.foreign, 'custom': self.custom}[sec]

    def select_metatile(self, mt):
        """Select the entry equal to mt (found list first); returns index or None."""
        for sec in ('found', 'custom'):
            for i, m in enumerate(self._list(sec)):
                if m['tiles'] == mt['tiles'] and m.get('pal') == mt.get('pal'):
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
        for sec in self.sections:
            if sec == 'foreign' and not self.foreign_title:
                continue
            h += HDR + self._rows(sec) * (MT + GAP) + GAP
        self.setFixedHeight(max(h, 80))
        self.update()

    def _render(self, sec, mt):
        sheet = self.foreign_sheet if sec == 'foreign' else self.sheet
        key = (sec if sec == 'foreign' else 'own', tuple(mt['tiles']), mt.get('pal'))
        if key not in self._pix:
            if self.renderer is None or sheet is None:
                return None
            img = Image.new('RGB', (16, 16))
            p = mt.get('pal') or 0
            for i, t in enumerate(mt['tiles']):
                img.paste(self.renderer.render_tile(sheet, t & 0x7F, self.pals, p),
                          ((i % 2) * 8, (i // 2) * 8))
            img = img.resize((MT, MT), Image.NEAREST)
            self._pix[key] = QPixmap.fromImage(ImageQt.ImageQt(img))
        return self._pix[key]

    # ------------------------------------------------------------ geometry
    def _section_top(self, sec):
        y = 0
        for s in self.sections:
            if s == 'foreign' and not self.foreign_title:
                continue
            if s == sec:
                return y + HDR
            y += HDR + self._rows(s) * (MT + GAP) + GAP
        return y + HDR

    def _rect(self, sec, i):
        y0 = self._section_top(sec)
        return QRect(GAP + (i % PER_ROW) * (MT + GAP), y0 + (i // PER_ROW) * (MT + GAP), MT, MT)

    def _hit(self, pos):
        for sec in self.sections:
            if sec == 'foreign' and not self.foreign_title:
                continue
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
            'found': f"This room's tiles ({len(self.found)})  — its whole vocabulary, never shrinks",
            'foreign': (f"From {self.foreign_title} ({len(self.foreign)})  — "
                        + ('same tileset: click = brush' if self.foreign_same
                           else 'other tileset: click = import into this tileset')),
            'custom': f'My metatiles ({len(self.custom)})  — click + to build one',
        }
        if 'foreign' in self.sections and not self.foreign_title:
            p.setPen(QColor(160, 160, 160))
            p.drawText(QRect(GAP, 0, self.width() - 2 * GAP, 60),
                       Qt.AlignTop | Qt.AlignLeft | Qt.TextWordWrap,
                       'Pick a room above. Its tiles are drawn with THIS room\'s '
                       'palettes; same tileset = brush, other tileset = click imports.')
        for sec in self.sections:
            if sec == 'foreign' and not self.foreign_title:
                continue
            y = self._section_top(sec) - HDR
            p.setPen(QColor(200, 200, 200))
            p.drawText(QRect(GAP, y, self.width(), HDR), Qt.AlignVCenter | Qt.AlignLeft,
                       titles[sec])
            thr = self.foreign_threshold if sec == 'foreign' else self.threshold
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

    def _draw(self, p, r, sec, mt, key, thr):
        pm = self._render(sec, mt)
        if pm is not None:
            p.drawPixmap(r, pm)
        # walkability corner (bottom-right subtile decides — S94 measurement)
        wall = mt['tiles'][3] < thr
        p.fillRect(QRect(r.right() - 5, r.bottom() - 5, 5, 5),
                   QColor(255, 60, 60) if wall else QColor(60, 220, 90))
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
                else:
                    mt = self._list(sec)[i]
                    thr = self.foreign_threshold if sec == 'foreign' else self.threshold
                    walk = 'WALL' if mt['tiles'][3] < thr else 'walkable'
                    extra = ''
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
            self.importRequested.emit(mt)
            return
        self.selected = h
        self.update()
        self.brushSelected.emit(mt)
