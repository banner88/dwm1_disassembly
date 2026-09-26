"""world_tab.py — World graph v0 (S98, ROADMAP P3.7; EDITOR_DESIGN §5.8).

Read-only map of how the player moves between rooms: custom rooms (with a
thumbnail of their first screen), the vanilla rooms they connect to, and
the connections (editor2/core/world.py): two-way doors, one-way exits,
vanilla doors re-pointed one-way, script warps. "Whole vanilla world" adds
every vanilla exit. Double-click a room to open it in the Rooms tab; hover
a line to see what it is. Drag rooms around to untangle (positions are not
saved — the layout is deterministic).
"""

import math

from PIL import ImageQt
from PySide6.QtCore import QPointF, QRectF, Qt, Signal
from PySide6.QtGui import QBrush, QColor, QFont, QPainter, QPainterPath, QPen, QPixmap
from PySide6.QtWidgets import (QCheckBox, QGraphicsItem, QGraphicsPathItem,
                               QGraphicsPixmapItem, QGraphicsRectItem,
                               QGraphicsScene, QGraphicsSimpleTextItem,
                               QGraphicsView, QHBoxLayout, QLabel, QPushButton,
                               QVBoxLayout, QWidget)

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
        v = QVBoxLayout(self)
        row = QHBoxLayout()
        self.all_vanilla = QCheckBox('whole vanilla world')
        self.all_vanilla.setToolTip('Also draw every vanilla room and vanilla exit '
                                    '(big — slower layout)')
        self.all_vanilla.toggled.connect(lambda _on: self.refresh())
        row.addWidget(self.all_vanilla)
        b = QPushButton('Re-layout')
        b.clicked.connect(self.refresh)
        row.addWidget(b)
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
        self.view.setDragMode(QGraphicsView.ScrollHandDrag)
        self.view.setBackgroundBrush(QBrush(QColor(24, 24, 28)))
        v.addWidget(self.view, 1)
        self.view.wheelEvent = self._wheel
        self.s.structureChanged.connect(self._mark)
        self.nodes = {}
        self.edges = []

    def _wheel(self, ev):
        if ev.modifiers() & (Qt.ControlModifier | Qt.MetaModifier):
            f = 1.15 if ev.angleDelta().y() > 0 else 1 / 1.15
            self.view.scale(f, f)
            ev.accept()
            return
        QGraphicsView.wheelEvent(self.view, ev)

    def _mark(self):
        self._dirty = True
        if self.isVisible():
            self.refresh()

    def showEvent(self, ev):
        super().showEvent(ev)
        if self._dirty:
            self.refresh()

    def graph(self):
        return W.world_graph(self.s.doc, self.s.renderer, self.all_vanilla.isChecked())

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
        rect = self.scene.itemsBoundingRect().adjusted(-40, -40, 40, 40)
        self.scene.setSceneRect(rect)
        self.view.resetTransform()
        vw, vh = self.view.viewport().width(), self.view.viewport().height()
        if vw > 50 and vh > 50 and (rect.width() > vw or rect.height() > vh):
            self.view.fitInView(rect, Qt.KeepAspectRatio)
