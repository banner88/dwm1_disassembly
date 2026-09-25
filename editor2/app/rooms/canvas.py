"""canvas.py — the room canvas, v2 (EDITOR_DESIGN §5.1; S93 → S94).

The unit of editing is the 16×16 CELL the player walks on (10×8 per
screen); a cell's graphic is a METATILE = 4 subtiles (tl, tr, bl, br) +
one palette slot. Subtile-level editing exists only inside the metatile
editor. One screen at native 160×128, zoom 1–6×, pixel-exact.

Tools (V = Select is the default):
  select  V   click a cell → Selection panel; click an NPC/spawn/exit marker
  paint   B   place the current metatile (drag paints)
  rect    R   drag a rectangle of the current metatile
  fill    F   flood-fill cells that match the clicked cell's metatile
  pick    I   (or right-click, any tool) make the clicked cell's metatile the brush
  walk    W   walkability mode: cells red (wall) / green (walkable); click flips
              — only the BOTTOM-RIGHT subtile decides (PyBoy-measured S94), so a
              flip swaps that subtile for its cross-threshold twin
Sources: a CUSTOM room (editable when its layout is a project item) or a
VANILLA room (read-only; "Make editable" clones it).
"""

import os

from PIL import ImageQt
from PySide6.QtCore import QRectF, Qt, Signal
from PySide6.QtGui import QBrush, QColor, QFont, QPainter, QPen, QPixmap
from PySide6.QtWidgets import QGraphicsPixmapItem, QGraphicsScene, QGraphicsView

from editor2.core.document import val, metatile_pals, pal_value, metatile_key
from editor2.core.render_project import SCREEN_H, SCREEN_W
from editor2.app.session import REPO

TILE = 8
CELL = 16
CELLS_W, CELLS_H = 10, 8
SPRITE_DIR = os.path.join(REPO, 'extracted', 'npc_field_sprites')

PAL_TINTS = [QColor(255, 80, 80, 70), QColor(80, 160, 255, 70),
             QColor(80, 220, 120, 70), QColor(255, 200, 60, 70),
             QColor(200, 100, 255, 70), QColor(60, 220, 220, 70),
             QColor(255, 130, 200, 70), QColor(200, 200, 200, 70)]
MARKER = {'npc': QColor(0, 200, 255), 'spawn': QColor(40, 230, 90),
          'exit': QColor(255, 70, 70), 'walkon': QColor(255, 160, 40),
          'redirect': QColor(255, 0, 255), 'entrance': QColor(120, 255, 120),
          'special': QColor(200, 200, 200)}
SEL = QColor(255, 230, 0)


def classify_npc(entry):
    """project.json npcs[] entry -> (kind, x, y, sprite|None, label)."""
    k = entry.get('kind')
    if k == 'spawn':
        return 'spawn', int(entry['x']), int(entry['y']), None, 'spawn point'
    if k == 'npc':
        spr = val(entry.get('sprite', 0))
        return ('npc', int(entry['x']), int(entry['y']), spr,
                f"NPC ${spr:02X} {entry.get('facing', '')} → {entry.get('script', 'none')}")
    if k == 'raw':
        b = [val(x) for x in entry['bytes']]
        t = b[0]
        if t < 0x80:
            return 'npc', b[2], b[3], b[1], f"NPC ${b[1]:02X} script ${b[4]:02X}"
        if t == 0x8F:
            return 'spawn', b[2], b[3], None, 'spawn point'
        if t == 0x90:
            return 'walkon', b[2], b[3], None, f"walk-on exit → ${b[4]:02X}"
        return 'special', b[2], b[3], None, f"special ${t:02X}"
    return 'special', int(entry.get('x', 0)), int(entry.get('y', 0)), None, '?'


class SpriteCache:
    """NPC thumbnails from the S91 census crops. The crops carry the throne
    room's floor (user S94: "castle red tiles where the boss should be"), so
    the background is knocked out here: every crop shows the SAME 16x16
    floor cell, so the per-pixel mode across all 137 crops IS the floor —
    pixels equal to it become transparent. (Bosses are multi-entry
    composites: one crop = one 16x16 fragment, ROOM_DATA_FORMAT S91.)"""
    _pix = {}
    _floor = None

    @classmethod
    def floor(cls):
        if cls._floor is None:
            from collections import Counter
            from PIL import Image
            cols = [[Counter() for _ in range(16)] for _ in range(16)]
            try:
                for fn in os.listdir(SPRITE_DIR):
                    if not fn.endswith('.png'):
                        continue
                    im = Image.open(os.path.join(SPRITE_DIR, fn)).convert('RGB')
                    if im.size != (16, 16):
                        continue
                    px = im.load()
                    for y in range(16):
                        for x in range(16):
                            cols[y][x][px[x, y]] += 1
            except OSError:
                pass
            cls._floor = [[(c.most_common(1)[0][0] if c else None) for c in row]
                          for row in cols]
        return cls._floor

    @staticmethod
    def knock_out(im, floor):
        """Flood-fill from the crop's border over floor-coloured pixels only:
        a sprite's own pixels that happen to share a floor colour (cream
        faces) stay opaque because the outline encloses them."""
        px = im.load()
        seen = set()
        stack = [(x, y) for x in range(16) for y in (0, 15)] + \
                [(x, y) for y in range(16) for x in (0, 15)]
        while stack:
            x, y = stack.pop()
            if (x, y) in seen or not (0 <= x < 16 and 0 <= y < 16):
                continue
            seen.add((x, y))
            if px[x, y][:3] != floor[y][x]:
                continue
            px[x, y] = (0, 0, 0, 0)
            stack.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    @classmethod
    def get(cls, sprite_id):
        if sprite_id not in cls._pix:
            p = os.path.join(SPRITE_DIR, f'id_{sprite_id:02X}.png')
            pm = None
            if os.path.exists(p):
                from PIL import Image, ImageQt
                im = Image.open(p).convert('RGBA')
                if im.size == (16, 16):
                    cls.knock_out(im, cls.floor())
                pm = QPixmap.fromImage(ImageQt.ImageQt(im))
            cls._pix[sprite_id] = pm
        return cls._pix[sprite_id]


def metatile_at(tiles, attr, cx, cy):
    """The cell's metatile; 'pal' is per subtile when the four differ (S96 —
    vanilla mixes slots inside a cell, the attr grid is per 8x8)."""
    r, c = cy * 2, cx * 2
    pal = None
    if attr:
        pal = pal_value([attr[r][c], attr[r][c + 1], attr[r + 1][c], attr[r + 1][c + 1]])
    return {'tiles': [tiles[r][c], tiles[r][c + 1], tiles[r + 1][c], tiles[r + 1][c + 1]],
            'pal': pal}


class RoomCanvas(QGraphicsView):
    hoverInfo = Signal(str)
    brushPicked = Signal(object)              # metatile dict
    markerSelected = Signal(object)           # dict or None
    cellSelected = Signal(object)             # (cx, cy) or None
    walkFlipRequested = Signal(int, int)      # cx, cy
    zoomChanged = Signal(int)
    editRequested = Signal()                  # painting attempted on read-only
    toolChanged = Signal(str)

    TOOLS = ('select', 'paint', 'rect', 'fill', 'pick', 'walk')

    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.source = None           # ('custom', room_id) | ('vanilla', mid)
        self.room = None
        self.key = 0
        self.state_idx = 0
        self._zoom = 3
        self.tool = 'select'
        self.brush = None            # metatile dict
        self.layers = {'grid': True, 'attr': False, 'walk': False, 'markers': True}
        self.tiles = None
        self.attr = None
        self.lid = None
        self.attr_lid = None
        self.attr_note = ''
        self.gfx = None
        self.pals = None
        self.markers = []
        self.selected_marker = None
        self.selected_cell = None
        self._stroke = None
        self._rect_anchor = None
        self._rect_cur = None
        self._hover = None
        self._panning = None
        self._space = False
        self.highlight = None        # S96 slot map: tile index to outline

        self.scene_ = QGraphicsScene(self)
        self.setScene(self.scene_)
        self.base = QGraphicsPixmapItem()
        self.base.setTransformationMode(Qt.FastTransformation)
        self.scene_.addItem(self.base)
        self.scene_.setSceneRect(0, 0, SCREEN_W * TILE, SCREEN_H * TILE)
        self.setRenderHints(QPainter.RenderHints())
        self.setBackgroundBrush(QBrush(QColor(28, 28, 32)))
        self.setMouseTracking(True)
        self.setFocusPolicy(Qt.StrongFocus)
        self.setTransformationAnchor(QGraphicsView.AnchorUnderMouse)
        self.setDragMode(QGraphicsView.NoDrag)
        self.set_zoom(3)
        self.set_tool('select')

        self.s.layoutChanged.connect(self._on_layout_changed)
        self.s.paletteChanged.connect(lambda _p: self.reload())
        self.s.structureChanged.connect(self.reload)

    # ----------------------------------------------------------------- view
    def set_zoom(self, z):
        z = max(1, min(6, int(z)))
        self._zoom = z
        self.resetTransform()
        self.scale(z, z)
        self.zoomChanged.emit(z)

    def zoom(self):
        return self._zoom

    def set_tool(self, tool):
        assert tool in self.TOOLS
        self.tool = tool
        self.setCursor({'select': Qt.ArrowCursor, 'walk': Qt.PointingHandCursor}
                       .get(tool, Qt.CrossCursor))
        self._rect_anchor = self._rect_cur = None
        self.viewport().update()
        self.toolChanged.emit(tool)

    def set_brush(self, metatile):
        self.brush = dict(metatile) if metatile else None

    def set_highlight(self, tile):
        self.highlight = tile
        self.viewport().update()

    def set_layer(self, name, on):
        self.layers[name] = bool(on)
        self.viewport().update()

    # ----------------------------------------------------------------- data
    def show_custom(self, room_id, key, state_idx=0):
        self.source = ('custom', room_id)
        self.key, self.state_idx = int(key), int(state_idx)
        self.selected_marker = self.selected_cell = None
        self.reload()

    def show_vanilla(self, mid, key, state_idx=0):
        self.source = ('vanilla', int(mid))
        self.key, self.state_idx = int(key), int(state_idx)
        self.selected_marker = self.selected_cell = None
        self.reload()

    def clear(self):
        self.source = self.room = None
        self.tiles = self.attr = None
        self.base.setPixmap(QPixmap())
        self.viewport().update()

    def is_vanilla(self):
        return bool(self.source) and self.source[0] == 'vanilla'

    def is_editable(self):
        return (not self.is_vanilla()) and self.lid is not None

    def reload(self):
        if not self.source:
            return
        r = self.s.renderer
        if self.is_vanilla():
            mid = self.source[1]
            self.room = None
            nst = len(r.vanilla_steps(mid, self.key))
            self.state_idx = min(self.state_idx, nst - 1)
            self.gfx = r.vanilla_gfx(mid)
            self.pals = r.vanilla_palettes_step(mid, self.key, self.state_idx)
            self.tiles = [list(x) for x in r.vanilla_screen_grid(mid, self.key, self.state_idx)]
            attr = r.vanilla_attr_grid(mid, self.key, self.state_idx)
            self.attr = [list(x) for x in attr] if attr else None
            self.lid = self.attr_lid = None
            self.attr_note = f'vanilla attr (step {self.state_idx})'
            npcs, exits = r.vanilla_markers(mid, self.key, self.state_idx)
            self._build_markers({'npcs': npcs, 'exits': exits})
            self._mark_redirects_vanilla(mid)
        else:
            try:
                room = self.s.doc.room(self.source[1])
            except KeyError:
                self.clear()
                return
            self.room = room
            if str(self.key) not in room.get('screens', {}):
                keys = self.s.doc.screen_keys(room)
                if not keys:
                    self.clear()
                    return
                self.key = keys[0]
            nstates = len(self.s.doc.states(room, self.key))
            self.state_idx = min(self.state_idx, nstates - 1)
            st = r.screen_state(room, self.key, self.state_idx)
            self.gfx = r.room_gfx(room)
            self.pals = r.room_palettes(room, self.key, self.state_idx)
            grid, lid = r.layout_grid(st['layout'])
            self.tiles = [list(x) for x in grid]
            self.lid = lid
            attr, note = r.attr_grid(room, self.key, self.state_idx)
            self.attr = [list(x) for x in attr] if attr else None
            self.attr_note = note
            self.attr_lid = None
            if attr and note and not note.startswith(('WARNING', 'vanilla', 'no ')):
                cand = note.split(' ')[0]
                if cand in r.layout_by_id and 'attr' in r.layout_by_id[cand]:
                    self.attr_lid = cand
            self._build_markers(st)
            self._mark_entrances(room)
        self._render()

    # S94b entrance redirects: a vanilla door routed into a custom room is a
    # magenta 'R' on the vanilla screen; the arrival cell in the custom room
    # is a green 'IN' marker (both read live from custom.entrance_redirects).
    def _mark_redirects_vanilla(self, mid):
        for i, rd in enumerate(self.s.doc.redirects()):
            if val(rd['mapID']) != mid or val(rd['screen']) != self.key:
                continue
            x, y = val(rd['x']), val(rd['y'])
            self.markers = [m for m in self.markers
                            if not (m[0] == 'exit' and m[1] == x and m[2] == y)]
            self.markers.append(('redirect', x, y, None,
                                 f"door ({x},{y}) REDIRECTED → {rd['dest']} "
                                 f"screen {val(rd['screen_byte']) & 0x0F} "
                                 f"spawn ({rd['spawn_x']},{rd['spawn_y']})",
                                 ('redirect', i, rd)))

    def _mark_entrances(self, room):
        for i, rd in self.s.doc.redirects_to(room['id']):
            if (val(rd['screen_byte']) & 0x0F) != self.key:
                continue
            x, y = val(rd['spawn_x']), val(rd['spawn_y'])
            name = self.s.renderer.vanilla_name(val(rd['mapID']))
            self.markers.append(('entrance', x, y, None,
                                 f"ENTRANCE from {name} screen {val(rd['screen'])} "
                                 f"door ({rd['x']},{rd['y']})",
                                 ('redirect', i, rd)))

    def _build_markers(self, st):
        self.markers = []
        for i, e in enumerate(st.get('npcs', [])):
            kind, x, y, spr, label = classify_npc(e)
            self.markers.append((kind, x, y, spr, label, ('npc', i, e)))
        for i, e in enumerate(st.get('exits', [])):
            self.markers.append(('exit', int(e['x']), int(e['y']), None,
                                 f"exit → {e.get('dest')}", ('exit', i, e)))

    def _render(self):
        img = self.s.renderer.compose(self.gfx.sheet, self.tiles, self.attr, self.pals)
        self.base.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(img)))
        self.viewport().update()

    def _on_layout_changed(self, lid):
        if lid in (self.lid, self.attr_lid) and self._stroke is None:
            self.reload()

    def screenshot(self):
        return self.s.renderer.compose(self.gfx.sheet, self.tiles, self.attr, self.pals)

    def cell_metatile(self, cx, cy):
        return metatile_at(self.tiles, self.attr, cx, cy)

    def cell_walkable(self, cx, cy):
        """The engine samples the bottom-right subtile (S94 measurement)."""
        return self.tiles[cy * 2 + 1][cx * 2 + 1] >= self.gfx.threshold

    # ------------------------------------------------------------ geometry
    def _cell_at(self, viewpos):
        p = self.mapToScene(viewpos)
        cx, cy = int(p.x() // CELL), int(p.y() // CELL)
        if 0 <= cx < CELLS_W and 0 <= cy < CELLS_H and p.x() >= 0 and p.y() >= 0:
            return cx, cy
        return None

    def _marker_at(self, cell):
        if cell is None:
            return None
        for m in reversed(self.markers):
            if m[1] == cell[0] and m[2] == cell[1]:
                return m
        return None

    # ------------------------------------------------------------- overlays
    def drawForeground(self, painter, rect):
        if self.tiles is None:
            return
        painter.save()
        z = self._zoom
        walk_mode = self.tool == 'walk' or self.layers['walk']
        if walk_mode and self.gfx is not None:
            painter.setPen(Qt.NoPen)
            for cy in range(CELLS_H):
                for cx in range(CELLS_W):
                    ok = self.cell_walkable(cx, cy)
                    painter.fillRect(QRectF(cx * CELL, cy * CELL, CELL, CELL),
                                     QColor(60, 220, 90, 70) if ok else QColor(255, 40, 40, 110))
        if self.layers['attr'] and self.attr:
            painter.setFont(QFont('Menlo', 5))
            for cy in range(CELLS_H):
                for cx in range(CELLS_W):
                    p = self.attr[cy * 2][cx * 2] & 7
                    painter.fillRect(QRectF(cx * CELL, cy * CELL, CELL, CELL), PAL_TINTS[p])
                    if z >= 2:
                        painter.setPen(QColor(255, 255, 255, 230))
                        painter.drawText(QRectF(cx * CELL, cy * CELL, CELL, CELL),
                                         Qt.AlignCenter, str(p))
        if self.layers['grid']:
            pen = QPen(QColor(255, 255, 255, 28))
            pen.setCosmetic(True)
            painter.setPen(pen)
            for c in range(1, SCREEN_W):
                if c % 2:
                    painter.drawLine(c * TILE, 0, c * TILE, SCREEN_H * TILE)
            for r in range(1, SCREEN_H):
                if r % 2:
                    painter.drawLine(0, r * TILE, SCREEN_W * TILE, r * TILE)
            pen = QPen(QColor(255, 255, 255, 95))
            pen.setCosmetic(True)
            painter.setPen(pen)
            for c in range(1, CELLS_W):
                painter.drawLine(c * CELL, 0, c * CELL, SCREEN_H * TILE)
            for r in range(1, CELLS_H):
                painter.drawLine(0, r * CELL, SCREEN_W * TILE, r * CELL)
        if self.highlight is not None:
            pen = QPen(QColor(255, 230, 0))
            pen.setCosmetic(True)
            pen.setWidth(2)
            painter.setPen(pen)
            painter.setBrush(QBrush(QColor(255, 230, 0, 70)))
            for r in range(SCREEN_H):
                for c in range(SCREEN_W):
                    if (self.tiles[r][c] & 0x7F) == self.highlight:
                        painter.drawRect(QRectF(c * TILE, r * TILE, TILE, TILE))
        if self.layers['markers']:
            for kind, x, y, spr, label, ref in self.markers:
                rc = QRectF(x * CELL, y * CELL, CELL, CELL)
                col = MARKER[kind]
                if kind == 'npc' and spr is not None:
                    pm = SpriteCache.get(spr)
                    if pm is not None:
                        painter.drawPixmap(rc.toRect(), pm)
                pen = QPen(col)
                pen.setCosmetic(True)
                painter.setPen(pen)
                painter.setBrush(Qt.NoBrush if kind == 'npc'
                                 else QBrush(QColor(col.red(), col.green(), col.blue(), 60)))
                painter.drawRect(rc.adjusted(0.5, 0.5, -0.5, -0.5))
                if kind != 'npc':
                    painter.setFont(QFont('Menlo', 6))
                    painter.setPen(col)
                    painter.drawText(rc, Qt.AlignCenter,
                                     {'spawn': 'S', 'exit': 'E', 'walkon': 'W', 'special': '?',
                                      'redirect': 'R', 'entrance': 'IN'}[kind])
                if self.selected_marker is ref:
                    pen = QPen(SEL)
                    pen.setCosmetic(True)
                    pen.setWidth(3)
                    painter.setPen(pen)
                    painter.setBrush(Qt.NoBrush)
                    painter.drawRect(rc.adjusted(-1, -1, 1, 1))
        if self.selected_cell and self.selected_marker is None:
            cx, cy = self.selected_cell
            pen = QPen(SEL)
            pen.setCosmetic(True)
            pen.setWidth(3)
            painter.setPen(pen)
            painter.setBrush(Qt.NoBrush)
            painter.drawRect(QRectF(cx * CELL, cy * CELL, CELL, CELL).adjusted(0.5, 0.5, -0.5, -0.5))
        if self._rect_anchor and self._rect_cur:
            x0, y0 = self._rect_anchor
            x1, y1 = self._rect_cur
            rr = QRectF(min(x0, x1) * CELL, min(y0, y1) * CELL,
                        (abs(x1 - x0) + 1) * CELL, (abs(y1 - y0) + 1) * CELL)
            pen = QPen(SEL)
            pen.setCosmetic(True)
            painter.setPen(pen)
            painter.setBrush(QBrush(QColor(255, 230, 0, 50)))
            painter.drawRect(rr)
        if self._hover and self.tool != 'select':
            cx, cy = self._hover
            pen = QPen(QColor(255, 255, 255, 200))
            pen.setCosmetic(True)
            painter.setPen(pen)
            painter.setBrush(Qt.NoBrush)
            painter.drawRect(QRectF(cx * CELL, cy * CELL, CELL, CELL).adjusted(0.5, 0.5, -0.5, -0.5))
        painter.restore()

    # ------------------------------------------------------------- painting
    def _can_paint(self):
        if self.is_vanilla() or self.lid is None:
            self.editRequested.emit()
            return False
        if self.brush is None:
            self.hoverInfo.emit('Pick a metatile first (click one in the picker, '
                                'or right-click a cell to copy its metatile).')
            return False
        return True

    def _begin_stroke(self):
        self._stroke = {'tiles': {}, 'attr': {}, 'ot': {}, 'oa': {}}

    def _stroke_cell(self, cell, mt=None):
        if self._stroke is None or cell is None:
            return
        mt = mt or self.brush
        cx, cy = cell
        r0, c0 = cy * 2, cx * 2
        tl, tr, bl, br = mt['tiles']
        for (r, c), v in (((r0, c0), tl), ((r0, c0 + 1), tr),
                          ((r0 + 1, c0), bl), ((r0 + 1, c0 + 1), br)):
            self._stroke['ot'].setdefault((r, c), self.tiles[r][c])
            self._stroke['tiles'][(r, c)] = v
            self.tiles[r][c] = v
        pals = metatile_pals(mt)
        if pals is not None and self.attr is not None and self.attr_lid:
            for (r, c), p in zip(((r0, c0), (r0, c0 + 1), (r0 + 1, c0), (r0 + 1, c0 + 1)),
                                 pals):
                self._stroke['oa'].setdefault((r, c), self.attr[r][c])
                self._stroke['attr'][(r, c)] = p
                self.attr[r][c] = p
        self._render()

    def _end_stroke(self, label='Paint'):
        st, self._stroke = self._stroke, None
        if not st:
            return
        tch = [(r, c, v) for (r, c), v in st['tiles'].items() if st['ot'][(r, c)] != v]
        ach = [(r, c, v) for (r, c), v in st['attr'].items() if st['oa'][(r, c)] != v]
        for (r, c), v in st['ot'].items():
            self.tiles[r][c] = v
        for (r, c), v in st['oa'].items():
            self.attr[r][c] = v
        if not tch and not ach:
            self._render()
            return
        from editor2.app.rooms.commands import PaintCells
        self.s.undo.beginMacro(label)
        if tch:
            self.s.undo.push(PaintCells(self.s, self.lid, 'tiles', tch, label))
        if ach:
            self.s.undo.push(PaintCells(self.s, self.attr_lid, 'attr', ach, label))
        self.s.undo.endMacro()

    def _flood(self, cell):
        target = self.cell_metatile(*cell)
        if target['tiles'] == self.brush['tiles'] and \
                (self.brush.get('pal') is None
                 or metatile_key(target) == metatile_key(self.brush)):
            return
        seen, stack = set(), [cell]
        while stack:
            cx, cy = stack.pop()
            if (cx, cy) in seen or not (0 <= cx < CELLS_W and 0 <= cy < CELLS_H):
                continue
            if self.cell_metatile(cx, cy) != target:
                continue
            seen.add((cx, cy))
            stack.extend([(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)])
        self._begin_stroke()
        for c in seen:
            self._stroke_cell(c)
        self._end_stroke('Fill')

    def _pick(self, cell):
        if cell is None or self.tiles is None:
            return
        mt = self.cell_metatile(*cell)
        self.brush = mt
        self.brushPicked.emit(mt)

    # --------------------------------------------------------------- events
    def mousePressEvent(self, ev):
        if ev.button() == Qt.MiddleButton or (ev.button() == Qt.LeftButton and self._space):
            self._panning = ev.position().toPoint()
            self.setCursor(Qt.ClosedHandCursor)
            return
        cell = self._cell_at(ev.position().toPoint())
        if ev.button() == Qt.RightButton:
            self._pick(cell)
            return
        if ev.button() != Qt.LeftButton:
            return
        if self.tool == 'select':
            m = self._marker_at(cell)
            self.selected_marker = m[5] if m else None
            self.selected_cell = cell
            self.viewport().update()
            if m:
                self.markerSelected.emit({'kind': m[0], 'x': m[1], 'y': m[2],
                                          'sprite': m[3], 'label': m[4], 'ref': m[5]})
            else:
                self.markerSelected.emit(None)
                self.cellSelected.emit(cell)
            return
        if self.tool == 'pick':
            self._pick(cell)
            return
        if self.tool == 'walk':
            if cell is not None:
                self.walkFlipRequested.emit(*cell)
            return
        if cell is None or not self._can_paint():
            return
        if self.tool == 'paint':
            self._begin_stroke()
            self._stroke_cell(cell)
        elif self.tool == 'rect':
            self._rect_anchor = self._rect_cur = cell
            self.viewport().update()
        elif self.tool == 'fill':
            self._flood(cell)

    def mouseMoveEvent(self, ev):
        pos = ev.position().toPoint()
        if self._panning is not None:
            d = pos - self._panning
            self._panning = pos
            self.horizontalScrollBar().setValue(self.horizontalScrollBar().value() - d.x())
            self.verticalScrollBar().setValue(self.verticalScrollBar().value() - d.y())
            return
        cell = self._cell_at(pos)
        if cell != self._hover:
            self._hover = cell
            self.viewport().update()
            self._emit_hover(cell)
        if cell is None:
            return
        if self._stroke is not None and self.tool == 'paint':
            self._stroke_cell(cell)
        elif self._rect_anchor is not None:
            self._rect_cur = cell
            self.viewport().update()

    def mouseReleaseEvent(self, ev):
        if self._panning is not None:
            self._panning = None
            self.set_tool(self.tool)
            return
        if ev.button() != Qt.LeftButton:
            return
        if self._stroke is not None and self.tool == 'paint':
            self._end_stroke('Paint')
        elif self._rect_anchor is not None:
            x0, y0 = self._rect_anchor
            x1, y1 = self._rect_cur or self._rect_anchor
            self._rect_anchor = self._rect_cur = None
            self._begin_stroke()
            for cy in range(min(y0, y1), max(y0, y1) + 1):
                for cx in range(min(x0, x1), max(x0, x1) + 1):
                    self._stroke_cell((cx, cy))
            self._end_stroke('Rectangle')

    def leaveEvent(self, ev):
        self._hover = None
        self.viewport().update()
        super().leaveEvent(ev)

    def wheelEvent(self, ev):
        if ev.modifiers() & (Qt.ControlModifier | Qt.MetaModifier):
            self.set_zoom(self._zoom + (1 if ev.angleDelta().y() > 0 else -1))
            ev.accept()
            return
        super().wheelEvent(ev)

    def keyPressEvent(self, ev):
        k = ev.key()
        if k == Qt.Key_Space:
            self._space = True
            self.setCursor(Qt.OpenHandCursor)
        elif k == Qt.Key_Escape:
            self.set_tool('select')
        elif k in (Qt.Key_Plus, Qt.Key_Equal):
            self.set_zoom(self._zoom + 1)
        elif k == Qt.Key_Minus:
            self.set_zoom(self._zoom - 1)
        else:
            super().keyPressEvent(ev)

    def keyReleaseEvent(self, ev):
        if ev.key() == Qt.Key_Space:
            self._space = False
            self.set_tool(self.tool)
        else:
            super().keyReleaseEvent(ev)

    def _emit_hover(self, cell):
        if cell is None or self.tiles is None:
            self.hoverInfo.emit('')
            return
        cx, cy = cell
        mt = self.cell_metatile(cx, cy)
        walk = 'walkable' if self.cell_walkable(cx, cy) else 'WALL'
        here = [m[4] for m in self.markers if m[1] == cx and m[2] == cy]
        self.hoverInfo.emit(
            f'cell ({cx},{cy})   subtiles {mt["tiles"]}   palette {mt["pal"]}   {walk}'
            + (f'   ▸ {"; ".join(here)}' if here else ''))
