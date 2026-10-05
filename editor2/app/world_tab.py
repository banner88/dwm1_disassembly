"""world_tab.py — World graph v0 (S98, ROADMAP P3.7; EDITOR_DESIGN §5.8).

Read-only map of how the player moves between rooms: custom rooms (with a
thumbnail of their first screen), the vanilla rooms they connect to, and
the connections (editor2/core/world.py): two-way doors, one-way exits,
vanilla doors re-pointed one-way, script warps. "Whole vanilla world" adds
every vanilla exit. Double-click a room to open it in the Rooms tab; hover
a line to see what it is. Drag rooms around to untangle (positions are not
saved — the layout is deterministic). S101 r3 (user: "world tab needs
zoomability. Mouse scroll in/out - zoom in/out; also click and drag canvas
when zoomed"): the wheel zooms around the mouse, dragging empty canvas pans
(at any zoom), Fit / + / − buttons.

S123 (ROADMAP NG3, user: "it needs to act as a world that can have encounters,
encounter-free rooms (where you can also save), mini-bosses, endbosses, flags and
triggers. Enter via swirling portal …"): the WORLDS panel on the left — the
project's worlds (editor2/core/worlds.py), each with its start room, portals, what
the swirl does once the world is cleared, the saving rule, its rooms (battles,
saving, bosses, where their doors lead) and what it still needs; "only this
world" draws just its rooms (green frames) and the rooms its doors touch.
"""

import math

from PIL import ImageQt
from PySide6.QtCore import QPointF, QRectF, Qt, Signal
from PySide6.QtGui import QBrush, QColor, QFont, QPainter, QPainterPath, QPen, QPixmap
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox,
                               QFormLayout, QGraphicsItem, QGraphicsPathItem,
                               QGraphicsPixmapItem, QGraphicsRectItem,
                               QGraphicsScene, QGraphicsSimpleTextItem,
                               QGraphicsView, QGridLayout, QGroupBox, QHBoxLayout,
                               QHeaderView,
                               QInputDialog, QLabel, QLineEdit, QListWidget,
                               QMessageBox, QPushButton, QScrollArea, QSpinBox,
                               QSplitter, QTableWidget, QTableWidgetItem, QVBoxLayout,
                               QWidget)

from editor2.core import gates as G
from editor2.core import maze as MZ
from editor2.core import world as W

EDGE_COLORS = {'door': QColor(0, 230, 200), 'exit': QColor(255, 90, 90),
               'redirect': QColor(255, 0, 255), 'warp': QColor(255, 210, 60),
               'vanilla': QColor(140, 140, 140)}
NODE_W, NODE_H = 96, 86


class _Node(QGraphicsRectItem):
    def __init__(self, tab, info, pixmap):
        super().__init__(0, 0, NODE_W, NODE_H)
        self.tab, self.info = tab, info
        self.edges = []
        self.setFlag(QGraphicsItem.ItemIsMovable, True)
        self.setFlag(QGraphicsItem.ItemSendsGeometryChanges, True)
        custom = info['custom']
        self.setBrush(QBrush(QColor(40, 60, 70) if custom else QColor(55, 55, 55)))
        if info.get('world'):                       # S123: a room of the shown world
            self.setPen(QPen(QColor(120, 230, 120), 4))
        else:
            self.setPen(QPen(QColor(0, 200, 255) if custom else QColor(130, 130, 130), 2))
        self.setToolTip(f"${info['mapID']:02X} {info['label']} "
                        f"({'custom' if custom else 'vanilla'}) — double-click to open")
        if pixmap is not None:
            pm = QGraphicsPixmapItem(pixmap.scaled(80, 64), self)
            pm.setPos(8, 4)
        t = QGraphicsSimpleTextItem(f"${info['mapID']:02X} {info['label']}"[:16], self)
        t.setBrush(QBrush(QColor(230, 230, 230)))
        t.setFont(QFont('Helvetica', 7))
        t.setPos(4, 70)
        self.setZValue(2)

    def itemChange(self, change, value):
        if change == QGraphicsItem.ItemPositionHasChanged:
            for e in self.edges:
                e.update_path()
        return super().itemChange(change, value)

    def mouseDoubleClickEvent(self, ev):
        self.tab.openRequested.emit(self.info['key'])

    def centre(self):
        return self.pos() + QPointF(NODE_W / 2, NODE_H / 2)


class _Edge(QGraphicsPathItem):
    def __init__(self, a, b, info, offset=0):
        super().__init__()
        self.a, self.b, self.info, self.offset = a, b, info, offset
        col = EDGE_COLORS.get(info['kind'], QColor(200, 200, 200))
        pen = QPen(col, 2 if info['kind'] != 'vanilla' else 1)
        if info['kind'] == 'warp':
            pen.setStyle(Qt.DashLine)
        self.setPen(pen)
        self.col = col
        self.setToolTip(f"{info['kind']}: {info['label']}")
        self.setZValue(1)
        a.edges.append(self)
        b.edges.append(self)
        self.update_path()

    @staticmethod
    def _clip(c, toward):
        """The point where the line centre->toward leaves the node box."""
        dx, dy = toward.x() - c.x(), toward.y() - c.y()
        hw, hh = NODE_W / 2 + 3, NODE_H / 2 + 3
        if dx == 0 and dy == 0:
            return c
        t = min(hw / abs(dx) if dx else 1e9, hh / abs(dy) if dy else 1e9)
        return QPointF(c.x() + dx * t, c.y() + dy * t)

    def update_path(self):
        c1, c2 = self.a.centre(), self.b.centre()
        path = QPainterPath()
        if self.a is self.b:
            path.addEllipse(QRectF(c1.x() + NODE_W / 2 - 10, c1.y() - 20, 30, 30))
            self.setPath(path)
            return
        dx, dy = c2.x() - c1.x(), c2.y() - c1.y()
        d = math.hypot(dx, dy) or 1
        nx, ny = -dy / d, dx / d
        off = self.offset * 12
        mid = QPointF((c1.x() + c2.x()) / 2 + nx * off, (c1.y() + c2.y()) / 2 + ny * off)
        p1, p2 = self._clip(c1, mid), self._clip(c2, mid)
        path.moveTo(p1)
        path.quadTo(mid, p2)

        def head(tip, frm):
            ax, ay = tip.x() - frm.x(), tip.y() - frm.y()
            L = math.hypot(ax, ay) or 1
            ux, uy = ax / L, ay / L
            left = QPointF(tip.x() - ux * 10 + uy * 5, tip.y() - uy * 10 - ux * 5)
            right = QPointF(tip.x() - ux * 10 - uy * 5, tip.y() - uy * 10 + ux * 5)
            path.moveTo(left)
            path.lineTo(tip)
            path.lineTo(right)
        head(p2, mid)
        if self.info.get('both'):
            head(p1, mid)
        self.setPath(path)


class WorldTab(QWidget):
    openRequested = Signal(object)          # node key: ('room', id) | ('vanilla', mid)

    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self._dirty = True
        outer = QHBoxLayout(self)
        split = QSplitter()
        outer.addWidget(split)
        self.worlds = WorldsPanel(self)
        split.addWidget(self.worlds)
        right = QWidget()
        split.addWidget(right)
        split.setStretchFactor(1, 3)
        split.setSizes([430, 900])
        v = QVBoxLayout(right)
        v.setContentsMargins(0, 0, 0, 0)
        row = QHBoxLayout()
        self.only_world = QCheckBox('only this world')
        self.only_world.setToolTip('S123: draw only the selected world\'s rooms (green frames) '
                                   'and the rooms its doors / portals touch')
        self.only_world.toggled.connect(lambda _on: self.refresh())
        row.addWidget(self.only_world)
        self.all_vanilla = QCheckBox('whole vanilla world')
        self.all_vanilla.setToolTip('Also draw every vanilla room and vanilla exit '
                                    '(big — slower layout)')
        self.all_vanilla.toggled.connect(lambda _on: self.refresh())
        row.addWidget(self.all_vanilla)
        b = QPushButton('Re-layout')
        b.clicked.connect(self.refresh)
        row.addWidget(b)
        for txt, tip, fn in (('Fit', 'Show the whole graph', self.fit),
                             ('+', 'Zoom in (mouse wheel)', lambda: self.zoom(1.25)),
                             ('−', 'Zoom out (mouse wheel)', lambda: self.zoom(1 / 1.25))):
            zb = QPushButton(txt)
            zb.setToolTip(tip)
            zb.setMaximumWidth(48)
            zb.clicked.connect(fn)
            row.addWidget(zb)
        legend = QLabel('<span style="color:#00e6c8">━ door (two-way)</span> &nbsp; '
                        '<span style="color:#ff5a5a">━ one-way exit</span> &nbsp; '
                        '<span style="color:#ff00ff">━ vanilla door → here (one-way)</span> &nbsp; '
                        '<span style="color:#ffd23c">┅ script warp</span> &nbsp; '
                        '<span style="color:#8c8c8c">─ vanilla exit</span>')
        row.addWidget(legend)
        row.addStretch(1)
        self.count = QLabel('')
        row.addWidget(self.count)
        v.addLayout(row)
        self.scene = QGraphicsScene(self)
        self.view = QGraphicsView(self.scene)
        self.view.setRenderHints(QPainter.Antialiasing)
        self.view.setDragMode(QGraphicsView.ScrollHandDrag)   # empty canvas = pan
        self.view.setTransformationAnchor(QGraphicsView.AnchorUnderMouse)
        self.view.setResizeAnchor(QGraphicsView.AnchorViewCenter)
        self.view.setToolTip('Wheel = zoom · drag empty space = move around · drag a room '
                             'to move it · double-click a room to open it')
        self.view.setBackgroundBrush(QBrush(QColor(24, 24, 28)))
        v.addWidget(self.view, 1)
        self.view.wheelEvent = self._wheel
        self.s.structureChanged.connect(self._mark)
        self.nodes = {}
        self.edges = []

    ZOOM_MIN, ZOOM_MAX = 0.05, 8.0

    def _wheel(self, ev):
        d = ev.angleDelta().y() or ev.angleDelta().x()
        if d:
            self.zoom(1.15 if d > 0 else 1 / 1.15)
        ev.accept()

    def zoom(self, f):
        cur = self.view.transform().m11()
        f = max(self.ZOOM_MIN / cur, min(self.ZOOM_MAX / cur, f))
        self.view.scale(f, f)

    def _pan_rect(self):
        """Scene rect with a margin of a whole view on every side, so the
        canvas can be dragged around at any zoom."""
        r = self.scene.itemsBoundingRect()
        m = max(r.width(), r.height(), 800.0)
        return r.adjusted(-m, -m, m, m)

    def fit(self):
        r = self.scene.itemsBoundingRect().adjusted(-40, -40, 40, 40)
        if r.width() > 0 and r.height() > 0:
            self.view.resetTransform()
            self.view.fitInView(r, Qt.KeepAspectRatio)
            if self.view.transform().m11() > 1.0:        # small graphs: 1:1, centred
                self.view.resetTransform()
            self.view.centerOn(r.center())

    def _mark(self):
        self._dirty = True
        if self.isVisible():
            self.refresh()
            self.worlds.refresh()

    def showEvent(self, ev):
        super().showEvent(ev)
        if self._dirty:
            self.refresh()
            self.worlds.refresh()

    def graph(self):
        nodes, edges = W.world_graph(self.s.doc, self.s.renderer, self.all_vanilla.isChecked())
        gid = self.worlds.current()
        if gid is not None:
            members = set(self.s.doc.world_rooms(gid))
            portal_rooms = {r['id'] for r, _k, _n, _e in self.s.doc.gate_entrances(gid)}
            for n in nodes:
                n['world'] = n['key'][0] == 'room' and n['key'][1] in members
            if self.only_world.isChecked():
                keep = {('room', r) for r in members | portal_rooms}
                for e in edges:
                    if e['a'] in keep and e['b'][0] == 'room' and e['b'][1] in members:
                        keep.add(e['a'])
                    if e['b'] in keep and e['a'][0] == 'room' and e['a'][1] in members:
                        keep.add(e['b'])
                nodes = [n for n in nodes if n['key'] in keep]
                edges = [e for e in edges if e['a'] in keep and e['b'] in keep]
        return nodes, edges

    def refresh(self):
        self._dirty = False
        self.scene.clear()
        self.nodes, self.edges = {}, []
        nodes, edges = self.graph()
        big = len(nodes) > 40
        import math as _m
        scale = max(1.0, _m.sqrt(len(nodes) / 6.0))
        pos = W.layout(nodes, edges, width=900.0 * scale, height=650.0 * scale,
                       iterations=120 if big else 250)
        for n in nodes:
            pm = None
            try:
                if n['custom']:
                    room = self.s.doc.room(n['key'][1])
                    k = self.s.doc.screen_keys(room)[0]
                    img = self.s.renderer.render_screen(room, k, 0, 1)
                else:
                    mid = n['key'][1]
                    scr = next(sc for m, _n, sc in self.s.renderer.vanilla_rooms() if m == mid)
                    img = self.s.renderer.render_vanilla_screen(mid, scr[0], 1, 0)
                pm = QPixmap.fromImage(ImageQt.ImageQt(img.convert('RGB')))
            except Exception:
                pm = None
            item = _Node(self, n, pm)
            x, y = pos.get(n['key'], (0, 0))
            item.setPos(x, y)
            self.scene.addItem(item)
            self.nodes[n['key']] = item
        pairs = {}
        for e in edges:
            a, b = self.nodes.get(e['a']), self.nodes.get(e['b'])
            if a is None or b is None:
                continue
            key = tuple(sorted((str(e['a']), str(e['b']))))
            off = pairs.get(key, 0)
            pairs[key] = off + 1
            item = _Edge(a, b, e, offset=off - 0 if off % 2 == 0 else -off)
            self.scene.addItem(item)
            self.edges.append(item)
        self.count.setText(f'{len(nodes)} rooms, {len(edges)} connections')
        self.scene.setSceneRect(self._pan_rect())
        vw, vh = self.view.viewport().width(), self.view.viewport().height()
        if vw > 50 and vh > 50:
            self.fit()


# ---------------------------------------------------------------------------
# S123 (ROADMAP NG3) — the Worlds panel
# ---------------------------------------------------------------------------
SAVING_UI = (('calm', 'in rooms without battles'),
             ('everywhere', 'in every room'),
             ('nowhere', 'nowhere (only outside the world)'))


def _swatch_icon(rgb):
    from PySide6.QtGui import QIcon
    pm = QPixmap(14, 14)
    pm.fill(QColor(*rgb))
    return QIcon(pm)


class NewWorldDialog(QDialog):
    """Name + start room (a new room in one of the 16 gate looks, or one of the
    project's rooms) + the landing cell, picked ON THE PICTURE (S123 r3)."""

    def __init__(self, session, parent=None):
        super().__init__(parent)
        from editor2.app.rooms.cell_picker import CellPicker
        self.s = session
        doc = session.doc
        self.doc = doc
        self.setWindowTitle('New world')
        lay = QHBoxLayout(self)
        left = QWidget()
        f = QFormLayout(left)
        intro = QLabel('A world is entered through a swirling portal exactly like a gate '
                       '(the same whirl, the same rules: a lost battle sends the player to the '
                       'Castle), but inside it is your own rooms joined by doors — each with '
                       'its own battles, saving, people and bosses.<br><br>'
                       '<b>1.</b> Name it. <b>2.</b> Pick its START room — where the portal '
                       'drops the player. <b>3.</b> Click on the picture where the player '
                       '<span style="color:#5aff78">lands</span>.<br><br>'
                       'The portal itself (where the swirl is, somewhere in your other '
                       'rooms) comes next: World tab → <i>Add portal…</i>.')
        intro.setWordWrap(True)
        intro.setMaximumWidth(300)
        f.addRow(intro)
        self.name = QLineEdit('New world')
        f.addRow('name', self.name)
        self.start = QComboBox()
        self.start.addItem('a NEW room in a gate look:', None)
        free = [r for r in doc.rooms if not r.get('placeholder')
                and doc.world_of_room(r['id']) is None]
        for r in free:
            self.start.addItem(f"${int(str(r['mapID']), 0):02X} {doc.room_name(r)}", r['id'])
        f.addRow('start room', self.start)
        self.theme = QComboBox()
        for t, nm in enumerate(MZ.THEME_NAMES):
            self.theme.addItem(f'gate theme {t}: {nm}', t)
        self.theme.setCurrentIndex(9)
        f.addRow('its look', self.theme)
        lay.addWidget(left)
        rg = QGroupBox('Where the player LANDS (click a cell)')
        rv = QVBoxLayout(rg)
        self.picker = CellPicker(session, 'LAND')
        rv.addWidget(self.picker)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        rv.addWidget(bb)
        lay.addWidget(rg)
        self.start.currentIndexChanged.connect(self._source)
        self.theme.currentIndexChanged.connect(self._source)
        self._source()

    def _source(self, _i=None):
        rid = self.start.currentData()
        self.theme.setEnabled(rid is None)
        if rid is None:
            self.picker.set_theme(self.theme.currentData())
        else:
            self.picker.set_room(rid)

    def cell(self):
        return self.picker.cell()

    def _ok(self):
        k, x, y = self.cell()
        if self.picker.is_wall(x, y):
            QMessageBox.warning(self, 'New world', f'({x},{y}) is a wall — the player would be '
                                'stuck. Click a floor cell.')
            return
        self.accept()


class StartDialog(QDialog):
    """Where the portal lands the player: a room of the world + a cell picked on
    the room's picture (S123 r3)."""

    def __init__(self, session, gid, parent=None):
        super().__init__(parent)
        from editor2.app.rooms.cell_picker import CellPicker
        doc = session.doc
        self.setWindowTitle('Where the player lands')
        w = doc.world(gid)
        st = w.get('start') or {}
        v = QVBoxLayout(self)
        lab = QLabel(f'Walking into a portal of <b>{doc.world_name(gid)}</b> drops the player '
                     'here (the world\'s start room). Pick the room, then click the cell.')
        lab.setWordWrap(True)
        v.addWidget(lab)
        row = QHBoxLayout()
        row.addWidget(QLabel('room'))
        self.room = QComboBox()
        for r in doc.rooms:
            if r.get('placeholder'):
                continue
            o = doc.world_of_room(r['id'])
            if o is None or o == gid:
                self.room.addItem(f"${int(str(r['mapID']), 0):02X} {doc.room_name(r)}", r['id'])
        self.room.setCurrentIndex(max(0, self.room.findData(st.get('room'))))
        row.addWidget(self.room, 1)
        v.addLayout(row)
        self.picker = CellPicker(session, 'LAND')
        self.picker.set_cell(int(st.get('screen', 0)), int(st.get('x', 4)), int(st.get('y', 4)))
        self.picker.set_room(self.room.currentData())
        self.picker.set_cell(int(st.get('screen', 0)), int(st.get('x', 4)), int(st.get('y', 4)))
        self.room.currentIndexChanged.connect(lambda _i: self.picker.set_room(self.room.currentData()))
        v.addWidget(self.picker)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def cell(self):
        return self.picker.cell()

    def _ok(self):
        k, x, y = self.cell()
        if self.picker.is_wall(x, y):
            QMessageBox.warning(self, 'Where the player lands', f'({x},{y}) is a wall — the '
                                'player would be stuck. Click a floor cell.')
            return
        self.accept()


class PortalDialog(QDialog):
    """A new PORTAL into a world (S123 r3): one of your rooms (not one of the
    world's own) + a cell picked on its picture."""

    def __init__(self, session, gid, parent=None):
        super().__init__(parent)
        from editor2.app.rooms.cell_picker import CellPicker
        doc = session.doc
        self.doc, self.gid = doc, gid
        self.setWindowTitle('Add a portal')
        v = QVBoxLayout(self)
        lab = QLabel(f'A swirling portal into <b>{doc.world_name(gid)}</b>: stepping on it '
                     'enters the world like a gate. Pick one of your rooms (outside the world), '
                     'then click the cell where the swirl goes. It gets the still swirl picture '
                     'and the spinning swirl. (A game room\'s own portal can be led here too: '
                     'Rooms tab → select the portal → <i>Lead this portal to another gate…</i>)')
        lab.setWordWrap(True)
        lab.setMaximumWidth(420)
        v.addWidget(lab)
        row = QHBoxLayout()
        row.addWidget(QLabel('room'))
        self.room = QComboBox()
        for r in doc.rooms:
            if r.get('placeholder') or doc.world_of_room(r['id']) == gid:
                continue
            self.room.addItem(f"${int(str(r['mapID']), 0):02X} {doc.room_name(r)}", r['id'])
        row.addWidget(self.room, 1)
        v.addLayout(row)
        self.picker = CellPicker(session, 'PORTAL')
        if self.room.count():
            self.picker.set_room(self.room.currentData())
        self.room.currentIndexChanged.connect(lambda _i: self.picker.set_room(self.room.currentData()))
        v.addWidget(self.picker)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def cell(self):
        return self.picker.cell()

    def _ok(self):
        if self.room.currentData() is None:
            self.reject()
            return
        k, x, y = self.cell()
        if self.picker.is_wall(x, y):
            QMessageBox.warning(self, 'Add a portal', f'({x},{y}) is a wall — the player could '
                                'never step on it. Click a floor cell.')
            return
        self.accept()


class WorldsPanel(QWidget):
    """The project's worlds: list, settings, rooms, problems (S123)."""

    def __init__(self, tab):
        super().__init__()
        self.tab, self.s = tab, tab.s
        self._building = False
        self.setMinimumWidth(440)
        outer = QVBoxLayout(self)
        outer.setContentsMargins(0, 0, 0, 0)
        sc = QScrollArea()
        sc.setWidgetResizable(True)
        outer.addWidget(sc)
        body = QWidget()
        sc.setWidget(body)
        v = QVBoxLayout(body)
        g = QGroupBox('Worlds')
        gv = QVBoxLayout(g)
        self.list = QListWidget()
        self.list.setMaximumHeight(110)
        self.list.currentRowChanged.connect(self._picked)
        gv.addWidget(self.list)
        row = QHBoxLayout()
        for txt, tip, fn in (('New world…', 'A new world: a name, its start room (a new room '
                              'in a gate look, or one of yours) and where the player lands',
                              self._new),
                             ('Rename…', '', self._rename),
                             ('Delete', 'Delete the world (its portals and swirls go; its rooms '
                              'stay)', self._delete)):
            b = QPushButton(txt)
            if tip:
                b.setToolTip(tip)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        gv.addLayout(row)
        v.addWidget(g)
        # S123 r3 (user: "there is the STARTING SWIRL that leads into world, where
        # else in game is it placed, and where it lands player INSIDE new world.
        # That needs to be visually clear"): the way in, as two pictures.
        self.way_box = QGroupBox('The way in')
        wl = QGridLayout(self.way_box)
        wl.setColumnStretch(1, 1)
        self.portal_pic = QLabel()
        self.portal_pic.setFixedSize(160, 128)
        self.portal_pic.setAlignment(Qt.AlignCenter)
        self.portal_pic.setStyleSheet('background:#202020; color:#aaa;')
        self.land_pic = QLabel()
        self.land_pic.setFixedSize(160, 128)
        self.land_pic.setStyleSheet('background:#202020;')
        # ① the portal: picture | title, where, buttons
        pcol = QVBoxLayout()
        self.portal_title = QLabel('<b>① The portal</b><br>the swirl the player steps on '
                                   '(outside the world)')
        self.portal_title.setWordWrap(True)
        pcol.addWidget(self.portal_title)
        self.portal_lbl = QLabel('')
        self.portal_lbl.setWordWrap(True)
        pcol.addWidget(self.portal_lbl)
        pcol.addStretch(1)
        prow = QHBoxLayout()
        self.btn_prev = QPushButton('◀')
        self.btn_next = QPushButton('▶')
        for b_ in (self.btn_prev, self.btn_next):
            b_.setFixedWidth(28)
        self.btn_prev.setToolTip('The previous portal of this world')
        self.btn_next.setToolTip('The next portal of this world')
        self.btn_prev.clicked.connect(lambda: self._cycle(-1))
        self.btn_next.clicked.connect(lambda: self._cycle(1))
        prow.addWidget(self.btn_prev)
        prow.addWidget(self.btn_next)
        self.btn_pgo = QPushButton('Go to')
        self.btn_pgo.setToolTip('Open this portal\'s room on the Rooms tab, the portal selected')
        self.btn_pgo.clicked.connect(self._go_portal)
        prow.addWidget(self.btn_pgo)
        self.btn_prm = QPushButton('Remove')
        self.btn_prm.clicked.connect(self._remove_portal)
        prow.addWidget(self.btn_prm)
        prow.addStretch(1)
        pcol.addLayout(prow)
        b = QPushButton('Add portal…')
        b.setToolTip('A new swirl into this world in one of your rooms — pick the room, click '
                     'the cell')
        b.clicked.connect(self._add_portal)
        arow = QHBoxLayout()
        arow.addWidget(b)
        arow.addStretch(1)
        pcol.addLayout(arow)
        wl.addWidget(self.portal_pic, 0, 0)
        wl.addLayout(pcol, 0, 1)
        arrow = QLabel('⬇  walking onto the swirl drops the player into the world')
        arrow.setStyleSheet('color:#5ac8ff;')
        wl.addWidget(arrow, 1, 0, 1, 2)
        # ② the landing: picture | title, where, buttons
        lcol = QVBoxLayout()
        self.land_title = QLabel('<b>② Lands here</b><br>the world\'s start room')
        self.land_title.setWordWrap(True)
        lcol.addWidget(self.land_title)
        self.start_lbl = QLabel('')
        self.start_lbl.setWordWrap(True)
        lcol.addWidget(self.start_lbl)
        lcol.addStretch(1)
        lrow = QHBoxLayout()
        b = QPushButton('Change…')
        b.setToolTip('Pick the start room and click where the player lands')
        b.clicked.connect(self._change_start)
        lrow.addWidget(b)
        b = QPushButton('Go to')
        b.setToolTip('Open the start room on the Rooms tab, the landing cell selected')
        b.clicked.connect(self._go_land)
        lrow.addWidget(b)
        lrow.addStretch(1)
        lcol.addLayout(lrow)
        wl.addWidget(self.land_pic, 2, 0)
        wl.addLayout(lcol, 2, 1)
        v.addWidget(self.way_box)
        self._portal_i = 0
        self._portals = []
        self.form_box = QGroupBox('This world')
        f = QFormLayout(self.form_box)
        self.swirl = QComboBox()
        self.swirl.addItem('stops (the game\'s way)', None)
        for p in range(8):
            self.swirl.addItem(f'turns {G.OBJ_PALETTE_NAMES[p]} (palette {p})', p)
        self.swirl.setToolTip('What the portal\'s spinning swirl does once the world is cleared '
                              '(a boss conversation turned its cleared flag ON): disappear, or '
                              'keep spinning in another colour — green = palette 1')
        self.swirl.activated.connect(self._swirl_changed)
        f.addRow('after clearing, the swirl', self.swirl)
        self.saving = QComboBox()
        for k, lab in SAVING_UI:
            self.saving.addItem(lab, k)
        self.saving.setToolTip('Where the JOURNAL works inside the world. A room can still '
                               'choose for itself (Rooms tab → Inside gates and worlds → save).')
        self.saving.activated.connect(self._saving_changed)
        f.addRow('saving (JOURNAL)', self.saving)
        self.cleared = QLabel('')
        self.cleared.setWordWrap(True)
        self.cleared.setStyleSheet('color:#aaa;')
        f.addRow('cleared', self.cleared)
        v.addWidget(self.form_box)
        rg = QGroupBox('Its rooms')
        rv = QVBoxLayout(rg)
        self.rooms = QTableWidget(0, 5)
        self.rooms.setHorizontalHeaderLabels(['room', 'battles', 'save', 'bosses', 'doors to'])
        self.rooms.verticalHeader().setVisible(False)
        self.rooms.setSelectionBehavior(QTableWidget.SelectRows)
        self.rooms.setEditTriggers(QTableWidget.NoEditTriggers)
        self.rooms.horizontalHeader().setSectionResizeMode(4, QHeaderView.Stretch)
        self.rooms.cellDoubleClicked.connect(lambda r, _c: self._open_room())
        self.rooms.setMinimumHeight(170)
        rv.addWidget(self.rooms)
        row = QHBoxLayout()
        for txt, tip, fn in (('Add room…', 'Add one of your rooms to this world', self._add_room),
                             ('New room…', 'A new room in this world (a gate look); then join it '
                              'with doors on the Rooms tab', self._new_room),
                             ('Remove', 'Take the room out of the world (the room stays)',
                              self._remove_room),
                             ('Open', 'Open the room on the Rooms tab (or double-click)',
                              self._open_room)):
            b = QPushButton(txt)
            b.setToolTip(tip)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        rv.addLayout(row)
        mrow = QHBoxLayout()
        b = QPushButton('Music for every room…')
        b.setToolTip('Give every room of the world that has no song of its own this song '
                     '(rooms without one keep whatever is playing — at first the gate theme)')
        b.clicked.connect(self._music)
        mrow.addWidget(b)
        mrow.addStretch(1)
        rv.addLayout(mrow)
        v.addWidget(rg)
        self.problems = QLabel('')
        self.problems.setWordWrap(True)
        v.addWidget(self.problems)
        how = QLabel('<b>How</b>: <i>Add portal…</i> above (or Rooms tab → a cell → More ▾ → '
                     '<i>World entrance here…</i>) puts the portal anywhere. Join the world\'s rooms with doors (Add door '
                     'here, double-click to connect). Battles per room: Encounters tab → Rooms '
                     '(flag variants switch the list once a boss is beaten). Bosses: select an '
                     'NPC → <i>Make boss…</i>. A way out: a door / exit back to your other rooms, '
                     'or the end boss\'s helper. Help → <i>Worlds</i>.')
        how.setWordWrap(True)
        how.setStyleSheet('color:#aaa;')
        v.addWidget(how)
        v.addStretch(1)
        self._ids = []
        self.refresh()

    # ------------------------------------------------------------- state
    def current(self):
        i = self.list.currentRow()
        return self._ids[i] if 0 <= i < len(self._ids) else None

    def refresh(self):
        doc = self.s.doc
        cur = self.current()
        self._ids = doc.world_ids()
        self._building = True
        self.list.clear()
        for gid in self._ids:
            self.list.addItem(f'{doc.world_name(gid)}   (gate {gid})')
        if cur in self._ids:
            self.list.setCurrentRow(self._ids.index(cur))
        elif self._ids:
            self.list.setCurrentRow(0)
        self._building = False
        self._show()

    def _picked(self, _row):
        if self._building:
            return
        self._show()
        if self.tab.isVisible():
            self.tab.refresh()

    def _show(self):
        doc = self.s.doc
        gid = self.current()
        self.form_box.setEnabled(gid is not None)
        self.way_box.setEnabled(gid is not None)
        if gid is None:
            self.start_lbl.setText('')
            self.portal_lbl.setText('')
            self.portal_pic.clear()
            self.land_pic.clear()
            self._portals = []
            self.cleared.setText('')
            self.rooms.setRowCount(0)
            self.problems.setText('No world yet — New world… makes one.' if not self._ids else '')
            return
        self._building = True
        w = doc.world(gid)
        st = w.get('start') or {}
        try:
            sname = doc.room_name(doc.room(st.get('room')))
        except Exception:                                  # noqa: BLE001
            sname = f"{st.get('room')} (missing)"
        self.start_lbl.setText(f"<b>{sname}</b>, screen {st.get('screen', 0)}, cell "
                               f"({st.get('x')},{st.get('y')})")
        self.land_pic.setPixmap(self._marked('room', st.get('room'), st.get('screen', 0),
                                             st.get('x', 0), st.get('y', 0),
                                             QColor(90, 255, 120), 'LAND'))
        self._portals = doc.world_portals(gid)
        self._portal_i = min(self._portal_i, max(0, len(self._portals) - 1))
        self._show_portal()
        try:
            from editor2.app.rooms.npc_panel import NpcPanel
            if NpcPanel.OBJ_PAL is None:
                NpcPanel.load_obj_palettes(self.s.renderer.rom)
            for p in range(8):
                if NpcPanel.OBJ_PAL:
                    self.swirl.setItemIcon(p + 1, _swatch_icon(NpcPanel.OBJ_PAL[p]))
        except Exception:                                  # noqa: BLE001
            pass
        self.swirl.setCurrentIndex(max(0, self.swirl.findData(G.cleared_swirl(doc.custom, gid))))
        self.saving.setCurrentIndex(max(0, self.saving.findData(w.get('saving', 'calm'))))
        self.cleared.setText(doc.gate_cleared_text(gid))
        rep = doc.world_report(gid)
        self.rooms.setRowCount(len(rep['rooms']))
        names = {}
        for x in rep['rooms']:
            names[x['id']] = x['name']
        for i, x in enumerate(rep['rooms']):
            if x['battles_on']:
                bt = (f"list {x['battles']}" if x['battles'] is not None else '⚠ no list') + \
                     (f" (+{x['variants']} variant)" if x['variants'] else '')
            else:
                bt = 'none'
            bosses = ', '.join(sorted({f for b in x['bosses'] for f in b[4]
                                       if not str(f).startswith('gate:')})) or '—'
            if any(f'gate:{gid}' in b[4] for b in x['bosses']):
                bosses += '  (END boss)'
            cells = [('★ ' if x['start'] else '') + x['name'], bt,
                     'yes' if x['save'] else 'no', bosses,
                     ', '.join(names.get(r, r) for r in x['ways']) or '—']
            for c, t in enumerate(cells):
                it = QTableWidgetItem(t)
                it.setData(Qt.UserRole, x['id'])
                it.setToolTip(t)
                self.rooms.setItem(i, c, it)
        self.rooms.resizeColumnsToContents()
        if rep['problems']:
            self.problems.setStyleSheet('color:#e0b040;')
            self.problems.setText('Still needs:\n• ' + '\n• '.join(rep['problems']))
        else:
            self.problems.setStyleSheet('color:#7fd67f;')
            self.problems.setText('Ready: a portal, a start room, its rooms reachable, an end '
                                  'boss that clears it, a way out.')
        self._building = False

    # ------------------------------------------------------------- the way in
    def _marked(self, kind, ident, screen, x, y, colour, text):
        """A 1x picture of a screen with the cell (x, y) outlined (S123 r3)."""
        rend = self.s.renderer
        try:
            if kind == 'room':
                img = rend.render_screen(self.s.doc.room(ident), int(screen), 0, 1)
            else:
                img = rend.render_vanilla_screen(int(ident), int(screen), 1, 0)
            pm = QPixmap.fromImage(ImageQt.ImageQt(img.convert('RGB')))
        except Exception:                                  # noqa: BLE001
            pm = QPixmap(160, 128)
            pm.fill(QColor(32, 32, 32))
        p = QPainter(pm)
        p.fillRect(int(x) * 16, int(y) * 16, 16, 16, QColor(colour.red(), colour.green(),
                                                            colour.blue(), 90))
        pen = QPen(colour)
        pen.setWidth(2)
        p.setPen(pen)
        p.drawRect(int(x) * 16, int(y) * 16, 15, 15)
        f = QFont()
        f.setPointSize(7)
        f.setBold(True)
        p.setFont(f)
        tx = min(int(x) * 16, 160 - 6 * len(text) - 4)
        ty = int(y) * 16 - 3 if int(y) > 0 else int(y) * 16 + 27
        p.fillRect(tx, ty - 9, 6 * len(text) + 4, 11, QColor(0, 0, 0, 180))
        p.drawText(tx + 2, ty, text)
        p.end()
        return pm

    def _show_portal(self):
        gid = self.current()
        n = len(self._portals)
        self.btn_prev.setEnabled(n > 1)
        self.btn_next.setEnabled(n > 1)
        self.btn_pgo.setEnabled(n > 0)
        if not n:
            self.portal_pic.clear()
            self.portal_pic.setText('no portal yet\n\nAdd portal… →\nput the swirl\nin one of '
                                    'your rooms')
            self.portal_lbl.setStyleSheet('color:#e0b040;')
            self.portal_lbl.setText('⚠ Nothing leads into the world yet.')
            self.btn_prm.setEnabled(False)
            return
        kind, ident, scr, x, y, label = self._portals[self._portal_i]
        pal = G.cleared_swirl(self.s.doc.custom, gid) if gid is not None else None
        self.portal_pic.setPixmap(self._marked(kind, ident, scr, x, y,
                                               QColor(90, 200, 255), 'PORTAL'))
        self.portal_lbl.setStyleSheet('')
        more = f' ({self._portal_i + 1} of {n})' if n > 1 else ''
        self.portal_lbl.setText(f'<b>{label}</b>{more}<br><span style="color:#aaa">spins until '
                                'the world is cleared, then '
                                + ('stops' if pal is None else
                                   f'turns {G.OBJ_PALETTE_NAMES[pal]}') + '</span>')
        self.btn_prm.setEnabled(kind == 'room')
        self.btn_prm.setToolTip('Take this portal away (its exit and spinning swirl; the still '
                                'swirl picture stays painted)' if kind == 'room' else
                                'A game room\'s portal: Rooms tab → select it → Lead this '
                                'portal to another gate… → back to the game\'s gate')

    def _cycle(self, d):
        if self._portals:
            self._portal_i = (self._portal_i + d) % len(self._portals)
            self._show_portal()

    def _go_portal(self):
        if self._portals:
            kind, ident, scr, x, y, _l = self._portals[self._portal_i]
            self.tab.openRequested.emit((kind, ident, scr, x, y))

    def _go_land(self):
        gid = self.current()
        if gid is None:
            return
        st = self.s.doc.world(gid).get('start') or {}
        self.tab.openRequested.emit(('room', st.get('room'), int(st.get('screen', 0)),
                                     int(st.get('x', 0)), int(st.get('y', 0))))

    def _add_portal(self):
        gid = self.current()
        if gid is None:
            return
        dlg = PortalDialog(self.s, gid, self)
        if dlg.room.count() == 0:
            QMessageBox.information(self, 'Add portal', 'Every room of the project belongs to '
                                    'this world — make a room outside it first.')
            return
        if dlg.exec() != QDialog.Accepted:
            return
        rid = dlg.room.currentData()
        k, x, y = dlg.cell()

        def op(d):
            room = d.room(rid)
            dead = d.edge_conflict(room, k, x, y)
            if dead and dead[0] != 'bottom':
                raise ValueError(f'({x},{y}) sits on the {dead[0]} edge that scrolls into '
                                 f'screen {dead[1]} — a portal there would never fire')
            sts = list(range(len(d.states(room, k))))
            full = d.add_world_entrance(room, k, 0, x, y, gid, states=sts)
            return full
        cmd = self._op(f'Portal into {self.s.doc.world_name(gid)}', op)
        if cmd is not None:
            self._portals = self.s.doc.world_portals(gid)
            for i, c in enumerate(self._portals):
                if c[:5] == ('room', rid, k, x, y):
                    self._portal_i = i
            self._show_portal()
            if cmd.result:
                QMessageBox.information(self, 'Add portal', 'The portal works, but there was no '
                                        'room for the spinning swirl (8 NPCs on that screen) in '
                                        f'state(s) {cmd.result}.')

    def _remove_portal(self):
        gid = self.current()
        if gid is None or not self._portals:
            return
        kind, rid, scr, x, y, label = self._portals[self._portal_i]
        if kind != 'room':
            return
        if QMessageBox.question(self, 'Remove portal', f'Remove the portal at {label}? (Undo '
                                'brings it back.)') != QMessageBox.Yes:
            return
        self._op('Remove portal', lambda d: d.remove_world_entrance(d.room(rid), scr, x, y))

    # ------------------------------------------------------------- edits
    def _op(self, label, fn):
        from editor2.app.rooms import commands as C
        cmd = C.SnapshotCommand(self.s, label, fn)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            return None
        self.refresh()
        return cmd

    def _new(self):
        doc = self.s.doc
        dlg = NewWorldDialog(self.s, self)
        if dlg.exec() != QDialog.Accepted:
            return
        name = dlg.name.text().strip() or 'New world'
        start = dlg.start.currentData()
        theme = dlg.theme.currentData()
        scr, x, y = dlg.cell()
        renderer = self.s.renderer

        def op(d):
            rid = start
            if rid is None:
                rid = d.new_room(f'{name} start', 0, renderer, gate_theme=theme)
            return d.new_world(name, rid, scr if start is not None else 0, x, y)
        cmd = self._op(f'New world {name}', op)
        if cmd is not None and cmd.result in self._ids:
            self.list.setCurrentRow(self._ids.index(cmd.result))

    def _rename(self):
        gid = self.current()
        if gid is None:
            return
        doc = self.s.doc
        name, okd = QInputDialog.getText(self, 'Rename world', 'Name:', text=doc.world_name(gid))
        if okd and name.strip():
            self._op(f'Rename world {name}',
                     lambda d: d.set_gate_setting(gid, name=name.strip()))

    def _delete(self):
        gid = self.current()
        if gid is None:
            return
        doc = self.s.doc
        if QMessageBox.question(self, 'Delete world',
                                f'Delete the world {doc.world_name(gid)}? Its portals and swirls '
                                'go; its rooms stay (Undo brings it back).') != QMessageBox.Yes:
            return
        self._op('Delete world', lambda d: d.delete_world(gid))

    def _change_start(self):
        gid = self.current()
        if gid is None:
            return
        dlg = StartDialog(self.s, gid, self)
        if dlg.exec() != QDialog.Accepted:
            return
        rid = dlg.room.currentData()
        scr, x, y = dlg.cell()
        self._op('World start', lambda d: d.set_world_start(gid, rid, scr, x, y))

    def _swirl_changed(self, _i):
        gid = self.current()
        if gid is None or self._building:
            return
        v = self.swirl.currentData()
        self._op('Swirl after clearing', lambda d: d.set_cleared_swirl(gid, v))

    def _saving_changed(self, _i):
        gid = self.current()
        if gid is None or self._building:
            return
        v = self.saving.currentData()
        self._op('World saving', lambda d: d.set_world_saving(gid, v))

    def _room_sel(self):
        it = self.rooms.item(self.rooms.currentRow(), 0) if self.rooms.currentRow() >= 0 else None
        return it.data(Qt.UserRole) if it is not None else None

    def _add_room(self):
        gid = self.current()
        if gid is None:
            return
        doc = self.s.doc
        free = [r for r in doc.rooms if not r.get('placeholder')
                and doc.world_of_room(r['id']) is None]
        if not free:
            QMessageBox.information(self, 'Add room', 'Every room already belongs to a world — '
                                    'New room… makes one.')
            return
        items = [f"${int(str(r['mapID']), 0):02X} {doc.room_name(r)}" for r in free]
        it, okd = QInputDialog.getItem(self, 'Add room', 'Room:', items, 0, False)
        if okd:
            rid = free[items.index(it)]['id']
            self._op('Add room to world', lambda d: d.add_world_room(gid, rid))

    def _new_room(self):
        gid = self.current()
        if gid is None:
            return
        name, okd = QInputDialog.getText(self, 'New room in this world', 'Name:')
        if not okd or not name.strip():
            return
        items = [f'gate theme {t}: {nm}' for t, nm in enumerate(MZ.THEME_NAMES)]
        it, okd = QInputDialog.getItem(self, 'New room in this world', 'Its look:', items, 0,
                                       False)
        if not okd:
            return
        t = items.index(it)
        renderer = self.s.renderer
        self._op(f'New room {name}',
                 lambda d: d.new_world_room(gid, name.strip(), 0, renderer, gate_theme=t))

    def _remove_room(self):
        gid, rid = self.current(), self._room_sel()
        if gid is None or rid is None:
            return
        self._op('Remove room from world', lambda d: d.remove_world_room(gid, rid))

    def _open_room(self):
        rid = self._room_sel()
        if rid is not None:
            self.tab.openRequested.emit(('room', rid))

    def _music(self):
        gid = self.current()
        if gid is None:
            return
        doc = self.s.doc
        songs = [s['id'] for s in (doc.custom.get('music') or {}).get('songs', [])]
        song, okd = QInputDialog.getItem(
            self, 'Music for every room', 'A project song id — or type a game song number '
            '(e.g. 0x09):', songs or ['0x09'], 0, True)
        if okd and song.strip():
            v = song.strip()
            self._op('World music', lambda d: d.set_world_music(gid, v))

