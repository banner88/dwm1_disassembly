"""sheet_import_dialog.py — cut a monster out of a sprite sheet (S106, ROADMAP
P3.10; core: editor2/core/sheet_import.py).

The sheet is shown zoomed with every monster the reader found outlined. Click
one: its battle box (red, drag to move, drag the corner square to resize) and
its six walking frames (cyan = frame a, blue = frame b; drag any square) become
editable — arrow keys nudge the selected box by one pixel. The right side shows
exactly what the game will draw: the 48x48 battle pose on the cream backdrop
with its four colours — black, the cream (also inside the body) and two
free colours (click a free swatch to change it) and the four walking
directions in one of the eight object palettes.

Used two ways: New species (name, id, starting stats, family below the sheet)
and Re-cut art of an existing new species (same view, no name fields).
"""

import os
import shutil

from PySide6.QtCore import QPointF, QRectF, Qt, Signal
from PySide6.QtGui import QBrush, QColor, QIcon, QPainter, QPen, QPixmap
from PySide6.QtWidgets import (QColorDialog, QComboBox, QDialog,
                               QDialogButtonBox, QFileDialog, QFormLayout,
                               QGraphicsItem, QGraphicsRectItem, QGraphicsScene,
                               QGraphicsView, QGroupBox, QHBoxLayout, QLabel,
                               QLineEdit, QMessageBox, QPushButton, QSplitter,
                               QVBoxLayout, QWidget)

from editor2.app import sprite_qt as Q
from editor2.core import gamedata as G
from editor2.core import sheet_import as S
from editor2.core import species as SP
from editor2.core import sprite_render as R

HELP = ('Click a monster on the sheet. Red = its battle pose, cyan / blue = its six '
        'walking frames (rows: facing down, sideways, up). Drag any box to fix it; the '
        'red box\'s corner square resizes it; arrow keys move the selected box one pixel. '
        'The right side is what the game will draw.')

WALK_NOTE = ('The game stores 4 walking frames: down, sideways a + b, up — the second '
             'down / up frame is the first one mirrored, like every original monster '
             'that walks this way (layout of Armorpion).')


class _Box(QGraphicsRectItem):
    """A box in sheet pixels; moves snap to whole pixels."""

    def __init__(self, dlg, key, rect, color, resizable=False):
        super().__init__(QRectF(0, 0, rect['w'], rect['h']))
        self.dlg = dlg
        self.key = key
        self.resizable = resizable
        self.setPos(rect['x'], rect['y'])
        pen = QPen(color)
        pen.setCosmetic(True)
        pen.setWidth(2)
        self.setPen(pen)
        self.setFlags(QGraphicsItem.ItemIsMovable | QGraphicsItem.ItemIsSelectable
                      | QGraphicsItem.ItemSendsGeometryChanges | QGraphicsItem.ItemIsFocusable)
        self.setZValue(5)
        self._resizing = False

    def box(self):
        r = self.rect()
        return {'x': int(round(self.pos().x())), 'y': int(round(self.pos().y())),
                'w': int(round(r.width())), 'h': int(round(r.height()))}

    def itemChange(self, change, value):
        if change == QGraphicsItem.ItemPositionChange:
            return QPointF(round(value.x()), round(value.y()))
        if change == QGraphicsItem.ItemPositionHasChanged:
            self.dlg.boxes_changed()
        return super().itemChange(change, value)

    def paint(self, p, opt, w=None):
        super().paint(p, opt, w)
        if self.resizable:
            r = self.rect()
            p.fillRect(QRectF(r.right() - 3, r.bottom() - 3, 3, 3), self.pen().color())

    def _corner(self, pos):
        r = self.rect()
        return self.resizable and pos.x() >= r.right() - 4 and pos.y() >= r.bottom() - 4

    def mousePressEvent(self, ev):
        if self._corner(ev.pos()):
            self._resizing = True
            ev.accept()
            return
        super().mousePressEvent(ev)

    def mouseMoveEvent(self, ev):
        if self._resizing:
            w = max(4, round(ev.pos().x()))
            h = max(4, round(ev.pos().y()))
            self.prepareGeometryChange()
            self.setRect(QRectF(0, 0, w, h))
            self.dlg.boxes_changed()
            return
        super().mouseMoveEvent(ev)

    def mouseReleaseEvent(self, ev):
        self._resizing = False
        super().mouseReleaseEvent(ev)

    def keyPressEvent(self, ev):
        d = {Qt.Key_Left: (-1, 0), Qt.Key_Right: (1, 0), Qt.Key_Up: (0, -1),
             Qt.Key_Down: (0, 1)}.get(ev.key())
        if d:
            if ev.modifiers() & Qt.ShiftModifier and self.resizable:
                r = self.rect()
                self.setRect(QRectF(0, 0, max(4, r.width() + d[0]), max(4, r.height() + d[1])))
                self.dlg.boxes_changed()
            else:
                self.setPos(self.pos() + QPointF(*d))
            return
        super().keyPressEvent(ev)


class _Outline(QGraphicsRectItem):
    def __init__(self, dlg, k, rect):
        super().__init__(rect)
        self.dlg, self.k = dlg, k
        pen = QPen(QColor(255, 255, 255, 170))
        pen.setCosmetic(True)
        pen.setStyle(Qt.DashLine)
        self.setPen(pen)
        self.setBrush(QBrush(QColor(255, 255, 255, 0)))
        self.setZValue(1)
        self.setCursor(Qt.PointingHandCursor)

    def mousePressEvent(self, ev):
        self.dlg.select_entry(self.k)
        ev.accept()


class SheetView(QGraphicsView):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setScene(QGraphicsScene(self))
        self.setRenderHint(QPainter.Antialiasing, False)
        self.setDragMode(QGraphicsView.NoDrag)
        self.setTransformationAnchor(QGraphicsView.AnchorUnderMouse)
        self.zoom = 2.0
        self.scale(self.zoom, self.zoom)

    def wheelEvent(self, ev):
        if ev.modifiers() & (Qt.ControlModifier | Qt.MetaModifier):
            f = 1.25 if ev.angleDelta().y() > 0 else 0.8
            if 1 <= self.zoom * f <= 8:
                self.zoom *= f
                self.scale(f, f)
            return
        super().wheelEvent(ev)


def _entry_rect(e):
    xs, ys = [], []
    for b in ([e['battle']] if e.get('battle') else []) + list((e.get('frames') or {}).values()):
        xs += [b['x'], b['x'] + b['w']]
        ys += [b['y'], b['y'] + b['h']]
    return QRectF(min(xs) - 2, min(ys) - 2, max(xs) - min(xs) + 4, max(ys) - min(ys) + 4)


class SheetImportDialog(QDialog):
    """mode 'new' (a new species) or 'recut' (replace a new species' art)."""

    def __init__(self, doc, mode='new', sid=None, parent=None):
        super().__init__(parent)
        self.doc = doc
        self.mode = mode
        self.sid = sid
        self.sheet = None
        self.sheet_path = None
        self.entries = []
        self.cur = None
        self.items = {}
        self.bpal = None            # user-chosen battle palette (None = auto)
        self.fpal = None            # user-chosen OBJ palette (None = auto)
        self.result_data = None
        self.setWindowTitle('New species from a sprite sheet' if mode == 'new'
                            else 'Re-cut the art from a sprite sheet')
        self.resize(1400, 860)
        v = QVBoxLayout(self)
        top = QHBoxLayout()
        top.addWidget(QLabel('Sheet'))
        self.sheet_combo = QComboBox()
        self.sheet_combo.setMinimumContentsLength(24)
        self.sheet_combo.activated.connect(lambda _i: self.load_sheet(self.sheet_combo.currentData()))
        top.addWidget(self.sheet_combo, 1)
        b = QPushButton('Open a PNG…')
        b.clicked.connect(self._open_png)
        top.addWidget(b)
        b = QPushButton('Add boxes here (a monster the reader missed)')
        b.clicked.connect(self._add_entry)
        top.addWidget(b)
        v.addLayout(top)
        h = QLabel(HELP)
        h.setWordWrap(True)
        v.addWidget(h)
        split = QSplitter()
        v.addWidget(split, 1)
        self.view = SheetView()
        split.addWidget(self.view)

        right = QWidget()
        rv = QVBoxLayout(right)
        bg = QGroupBox('Battle (48 × 48, as the game draws it)')
        bl = QVBoxLayout(bg)
        self.battle_view = Q.BattleView(scale=3)
        bl.addWidget(self.battle_view, 0, Qt.AlignCenter)
        self.fit_note = QLabel()
        self.fit_note.setWordWrap(True)
        bl.addWidget(self.fit_note)
        sw = QHBoxLayout()
        sw.addWidget(QLabel('Colours'))
        self.sw = []
        for k, tip in ((0, 'body colour 1 (darker) — click to change'),
                       (1, 'cream — the backdrop AND the light colour inside the pose '
                           '(fixed by the game)'),
                       (2, 'body colour 2 (lighter) — click to change'),
                       (3, 'outline — fixed black')):
            btn = QPushButton()
            btn.setFixedSize(34, 24)
            btn.setToolTip(tip)
            btn.setEnabled(k in (0, 2))
            btn.clicked.connect(lambda _c=False, k=k: self._pick_colour(k))
            sw.addWidget(btn)
            self.sw.append(btn)
        auto = QPushButton('Auto colours')
        auto.clicked.connect(self._auto_colours)
        sw.addWidget(auto)
        sw.addStretch(1)
        bl.addLayout(sw)
        rv.addWidget(bg)
        fg = QGroupBox('Walking (down, left, right, up)')
        fl = QVBoxLayout(fg)
        self.walk = Q.WalkPreview(scale=3)
        fl.addWidget(self.walk)
        row = QHBoxLayout()
        row.addWidget(QLabel('Object palette'))
        self.pal_combo = QComboBox()
        for i in range(8):
            pm = QPixmap(36, 14)
            pm.fill(Qt.transparent)
            pp = QPainter(pm)
            for j, w in enumerate(S.OBJ_PALETTES[i][1:]):
                pp.fillRect(j * 12, 0, 12, 14, QColor(*S.rgb888(w)))
            pp.end()
            self.pal_combo.addItem(QIcon(pm), f'{i} — {S.OBJ_PALETTE_NAMES[i]}', i)
        self.pal_combo.activated.connect(self._pal_chosen)
        row.addWidget(self.pal_combo, 1)
        fl.addLayout(row)
        n = QLabel('The game has 8 shared palettes for walking monsters: cream, '
                   'one colour, black. ' + WALK_NOTE)
        n.setWordWrap(True)
        fl.addWidget(n)
        rv.addWidget(fg)

        if mode == 'new':
            form = QGroupBox('The new species')
            f = QFormLayout(form)
            self.name = QLineEdit()
            self.name.setMaxLength(SP.NAME_MAX)
            self.name.setPlaceholderText('1-9 letters')
            f.addRow('Name', self.name)
            self.short = QLineEdit()
            self.short.setMaxLength(SP.SHORT_MAX)
            self.short.setPlaceholderText('default: first 4 letters')
            f.addRow('Nickname', self.short)
            self.id_combo = QComboBox()
            for i in doc.free_species_ids():
                self.id_combo.addItem(f'{i}', i)
            f.addRow('Species id', self.id_combo)
            self.clone = QComboBox()
            names = G.monster_names(R.REPO)
            for i in range(0, G.COLLECTIBLE_MAX + 1):
                self.clone.addItem(f'{i:3d}  {names.get(i, "")}', i)
            self.clone.setToolTip('Growth, resistances, skills, level cap … start as a '
                                  'copy of this monster; change them in the Monsters tab.')
            self.clone.setCurrentIndex(self.clone.findData(28))     # Dragon: a mid-game all-rounder
            f.addRow('Copy data from', self.clone)
            cn = QLabel('Its family, level cap, growth, resistances, 3 skills and library '
                        'text start as a copy of this monster (only the art is new). Change '
                        'any of them on the Monsters tab afterwards.')
            cn.setWordWrap(True)
            cn.setStyleSheet('color:#666')
            f.addRow('', cn)
            self.family = QComboBox()
            for fam in G.DISPLAY_ORDER:
                self.family.addItem(G.FAMILY_NAMES[fam], fam)
            f.addRow('Family', self.family)
            self.clone.activated.connect(self._clone_family)
            self._clone_family(0)
            rv.addWidget(form)
        rv.addStretch(1)
        split.addWidget(right)
        split.setSizes([920, 480])

        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.button(QDialogButtonBox.Ok).setText('Create species' if mode == 'new' else 'Use this art')
        bb.accepted.connect(self._accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

        self._fill_sheets()
        src = None
        if mode == 'recut' and sid is not None:
            try:
                src = doc.new_species(sid).get('source')
            except KeyError:
                src = None
        if src and src.get('sheet'):
            p = os.path.join(doc.project_dir, src['sheet'])
            if os.path.exists(p):
                self.load_sheet(p, select=src)
                return
        if self.sheet_combo.count():
            self.load_sheet(self.sheet_combo.itemData(0))

    # ------------------------------------------------------------ sheets
    def _sheet_dir(self):
        return os.path.join(self.doc.project_dir, 'assets', 'sheets')

    def _fill_sheets(self, extra=None):
        self.sheet_combo.clear()
        paths = []
        d = self._sheet_dir()
        if os.path.isdir(d):
            paths = sorted(os.path.join(d, n) for n in os.listdir(d) if n.lower().endswith('.png'))
        if extra and extra not in paths:
            paths.insert(0, extra)
        for p in paths:
            inside = os.path.dirname(p) == d
            self.sheet_combo.addItem(os.path.basename(p) + ('' if inside else '  (outside the project)'), p)

    def _open_png(self):
        p, _ = QFileDialog.getOpenFileName(self, 'Open a sprite sheet', '', 'PNG images (*.png)')
        if p:
            self._fill_sheets(extra=p)
            self.load_sheet(p)

    def load_sheet(self, path, select=None):
        if not path:
            return
        self.sheet = S.Sheet(path)
        self.sheet_path = path
        i = self.sheet_combo.findData(path)
        if i < 0:
            self._fill_sheets(extra=path)
            i = self.sheet_combo.findData(path)
        self.sheet_combo.setCurrentIndex(i)
        self.entries = S.find_entries(self.sheet)
        sc = self.view.scene()
        sc.clear()
        self.items = {}
        sc.addPixmap(QPixmap(path)).setZValue(0)
        sc.setSceneRect(0, 0, self.sheet.w, self.sheet.h)
        self.outlines = []
        for k, e in enumerate(self.entries):
            o = _Outline(self, k, _entry_rect(e))
            sc.addItem(o)
            self.outlines.append(o)
        self.cur = None
        if select:
            e = {'battle': select.get('battle'), 'frames': select.get('frames')}
            self.entries.append(e)
            o = _Outline(self, len(self.entries) - 1, _entry_rect(e))
            sc.addItem(o)
            self.outlines.append(o)
            self.select_entry(len(self.entries) - 1)
        elif self.entries:
            self.select_entry(0)

    # ------------------------------------------------------------ entries
    def select_entry(self, k):
        sc = self.view.scene()
        for it in self.items.values():
            sc.removeItem(it)
        self.items = {}
        self.cur = k
        self.bpal = None
        self.fpal = None
        e = self.entries[k]
        for o in self.outlines:
            o.setVisible(o.k != k)
        if e.get('battle'):
            self.items['battle'] = _Box(self, 'battle', e['battle'], QColor(230, 30, 30), True)
        for key, b in (e.get('frames') or {}).items():
            col = QColor(0, 230, 230) if key.endswith('a') else QColor(40, 110, 255)
            self.items[key] = _Box(self, key, b, col)
        for it in self.items.values():
            sc.addItem(it)
        self.view.centerOn(_entry_rect(e).center())
        self.boxes_changed()

    def _add_entry(self):
        c = self.view.mapToScene(self.view.viewport().rect().center())
        x, y = int(c.x()), int(c.y())
        e = {'battle': {'x': x - 50, 'y': y - 24, 'w': 48, 'h': 48},
             'frames': {}}
        for r, key in enumerate(('DOWN', 'SIDE', 'UP')):
            for j, ab in enumerate(('a', 'b')):
                e['frames'][f'{key}-{ab}'] = {'x': x + 4 + 18 * j, 'y': y - 27 + 18 * r,
                                              'w': 16, 'h': 16}
        self.entries.append(e)
        o = _Outline(self, len(self.entries) - 1, _entry_rect(e))
        self.view.scene().addItem(o)
        self.outlines.append(o)
        self.select_entry(len(self.entries) - 1)

    def current(self):
        """The selected entry with the boxes as they are on screen now."""
        if self.cur is None:
            return None
        e = {'battle': None, 'frames': None}
        if 'battle' in self.items:
            e['battle'] = self.items['battle'].box()
        fr = {k: self.items[k].box() for k in S.FRAME_KEYS if k in self.items}
        if len(fr) == 6:
            e['frames'] = fr
        self.entries[self.cur] = e
        return e

    # ------------------------------------------------------------ preview
    def boxes_changed(self):
        e = self.current()
        if not e or not self.sheet:
            return
        if e['battle']:
            cmap, pal = S.battle_colors(self.sheet, e['battle'])
            if self.bpal:
                pal = list(self.bpal)
            self._battle = (S.battle_payload(self.sheet, e['battle'], cmap), pal)
            s, w, h = S.battle_fit(e['battle'])
            if s == 1:
                self.fit_note.setText(f'The pose is {w} × {h} pixels — it fits.')
            else:
                self.fit_note.setText(
                    f'<span style="color:#b00">The pose box is {e["battle"]["w"]} × '
                    f'{e["battle"]["h"]}: bigger than the 48 × 48 field, so it is shrunk '
                    f'to {w} × {h}. Tighten the red box to crop instead.</span>')
            self.battle_view.set_rows(R.battle_rgb(*self._battle))
            for k, btn in enumerate(self.sw):
                c = QColor(*S.rgb888(pal[k]))
                btn.setStyleSheet(f'background:{c.name()}; border:1px solid #444')
        else:
            self._battle = None
            self.battle_view.set_rows(None)
            self.fit_note.setText('No battle box — use "Add boxes here".')
        if e['frames']:
            cmap, auto = S.follower_colors(self.sheet, e['frames'])
            p = auto if self.fpal is None else self.fpal
            self.pal_combo.setCurrentIndex(p)
            self._follow = (S.follower_payload(self.sheet, e['frames'], cmap), p)
            _b, fol = R.payload_preview(None, None, self._follow[0], p, SP.DONOR_MIN)
            self.walk.set_frames(fol)
        else:
            self._follow = None
            self.walk.set_frames(None)

    def _pick_colour(self, k):
        if not self._battle:
            return
        pal = list(self._battle[1])
        c = QColorDialog.getColor(QColor(*S.rgb888(pal[k])), self, 'Battle colour')
        if c.isValid():
            pal[k] = S.rgb555((c.red(), c.green(), c.blue()))
            self.bpal = pal
            self.boxes_changed()

    def _auto_colours(self):
        self.bpal = None
        self.fpal = None
        self.boxes_changed()

    def _pal_chosen(self, _i):
        self.fpal = self.pal_combo.currentData()
        self.boxes_changed()

    def _clone_family(self, _i):
        sid = self.clone.currentData()
        fam = G._rows(G.vanilla(R.REPO), 'monster_info')[sid][0]
        self.family.setCurrentIndex(self.family.findData(fam))

    # ------------------------------------------------------------ accept
    def _accept(self):
        e = self.current()
        if not e or not self._battle or not self._follow:
            QMessageBox.warning(self, 'Art', 'Select a monster with a battle box and all six '
                                'walking frames.')
            return
        sheet_rel = self._sheet_rel()
        art = {'battle': S.literal_stream(self._battle[0]), 'battle_palette': self._battle[1],
               'follower': S.literal_stream(self._follow[0]),
               'follower_palette': self._follow[1], 'walks_like': SP.DONOR_MIN}
        src = {'sheet': sheet_rel, 'battle': e['battle'], 'frames': e['frames']}
        out = {'art': art, 'source': src, 'sheet_abs': self.sheet_path}
        if self.mode == 'new':
            name = self.name.text().strip()
            short = self.short.text().strip() or name[:SP.SHORT_MAX]
            try:
                SP.name_bytes(name, 'name', 1, SP.NAME_MAX)
                SP.name_bytes(short, 'nickname', 1, SP.SHORT_MAX)
            except SP.SpeciesError as ex:
                QMessageBox.warning(self, 'Name', str(ex))
                return
            if self.id_combo.count() == 0:
                QMessageBox.warning(self, 'Species', 'All 19 new-species slots are used.')
                return
            out.update({'id': self.id_combo.currentData(), 'name': name, 'short': short,
                        'clone_from': self.clone.currentData(),
                        'family': self.family.currentData()})
        self.result_data = out
        self.accept()

    def _sheet_rel(self):
        base = os.path.basename(self.sheet_path)
        return f'assets/sheets/{base}'


def copy_sheet_into_project(project_dir, sheet_abs, rel):
    """The sheet travels with the project (source boxes stay re-cuttable)."""
    dst = os.path.join(project_dir, rel)
    if os.path.abspath(dst) != os.path.abspath(sheet_abs):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copyfile(sheet_abs, dst)
