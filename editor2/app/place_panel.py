"""place_panel.py — the side panel that SHOWS a place (S124 r3, ROADMAP P3.14a).

User S124 r3: "When you have something like this: * talking to the NPC (sprite $01)
at (3, 6) / (2, 7) — GreatTree · screen 8 … open … this should open a SIDE WINDOW
PANEL on the RIGHT to show the specific NPC in the specific room for visualization.
Rather than moving to a totally different tab. It should also allow naming all NPCs
(e.g. King at Stage X …) and carry that through, both vanilla and in romhack."

The Progression & Flags tab's "show" links and the Triggers / Problems pages open
their place here: the room's screen IN THE RIGHT STATE (a game room's NPCs differ
from state to state — Santi stands in GreatTree screen 12 only from state 1 on),
its NPCs drawn with their sprites and your names, the NPC of the place outlined.

* ◀ ▶ step through every place of the entry (the same script runs at several
  screens / states / cells);
* the state box shows the screen in its other states;
* click an NPC (on the picture or in the list) and **Name…** it — a project NPC's
  name is its actor name (cutscene_doc.name_actor), a game room's NPC's name is
  editor data (custom._editor.npc_names, npc_names.py). Either way the same NPC in
  the screen's other states gets it too, and the name shows everywhere;
* **Open in the Rooms tab** goes there (or to the cutscene / battles / gate).
"""

from PIL import ImageQt
from PySide6.QtCore import QRectF, Qt, Signal
from PySide6.QtGui import QColor, QFont, QPainter, QPen, QPixmap
from PySide6.QtWidgets import (QComboBox, QHBoxLayout, QInputDialog, QLabel, QListWidget,
                               QListWidgetItem, QMessageBox, QPushButton, QSizePolicy,
                               QToolButton, QVBoxLayout, QWidget)

from editor2.app.rooms import commands as C
from editor2.core import npc_names as NN

SCALE = 2
CELL = 16 * SCALE
GO_WHERE = {'rooms': 'Open in the Rooms tab', 'game': 'Open in the Rooms tab',
            'cutscene': 'Open the cutscene', 'cutscenes': 'Open the Cutscenes tab',
            'encounters': 'Open the battles (Encounters tab)', 'gates': 'Open the gate'}


def _esc(s):
    return str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


class _Picture(QLabel):
    clicked = Signal(int, int)           # cell x, y

    def mousePressEvent(self, ev):
        p = ev.position() if hasattr(ev, 'position') else ev.pos()
        pm = self.pixmap()
        if pm is not None and not pm.isNull():
            ox = (self.width() - pm.width()) // 2
            oy = (self.height() - pm.height()) // 2
            x, y = int((p.x() - ox) // CELL), int((p.y() - oy) // CELL)
            if 0 <= x < 10 and 0 <= y < 8:
                self.clicked.emit(x, y)
        super().mousePressEvent(ev)


class PlacePanel(QWidget):
    """Shows one place {'tab': 'game'|'rooms'|'cutscene'|…, map|room, screen, state,
    x, y, n, who} of a list; emits `navigate` for Open…"""
    navigate = Signal(dict)
    closed = Signal()

    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.places, self.i = [], 0
        self.title_text = ''
        self.state = 0
        self.sel_n = None                # the picked NPC number
        self.rows = []                   # [(n | None, kind, x, y, sprite, name, hidden)]
        v = QVBoxLayout(self)
        v.setContentsMargins(4, 0, 0, 0)
        top = QHBoxLayout()
        self.prev = QToolButton()
        self.prev.setText('◀')
        self.prev.clicked.connect(lambda: self._step(-1))
        self.next = QToolButton()
        self.next.setText('▶')
        self.next.clicked.connect(lambda: self._step(1))
        self.count = QLabel('')
        close = QToolButton()
        close.setText('✕')
        close.setToolTip('Hide this panel')
        close.clicked.connect(self._close)
        top.addWidget(self.prev)
        top.addWidget(self.count)
        top.addWidget(self.next)
        top.addStretch(1)
        top.addWidget(close)
        v.addLayout(top)
        self.head = QLabel('')
        self.head.setTextFormat(Qt.RichText)
        self.head.setWordWrap(True)
        v.addWidget(self.head)
        srow = QHBoxLayout()
        srow.addWidget(QLabel('Room state:'))
        self.state_box = QComboBox()
        self.state_box.currentIndexChanged.connect(self._state_picked)
        srow.addWidget(self.state_box, 1)
        v.addLayout(srow)
        self.pic = _Picture()
        self.pic.setAlignment(Qt.AlignCenter)
        self.pic.setMinimumSize(10 * CELL, 8 * CELL)
        self.pic.setSizePolicy(QSizePolicy.Minimum, QSizePolicy.Fixed)
        self.pic.setToolTip('Click an NPC to pick it (then Name… it)')
        self.pic.clicked.connect(self._clicked)
        v.addWidget(self.pic)
        self.npcs = QListWidget()
        self.npcs.setToolTip('The NPCs of this screen in this state (the game\'s order — '
                             'NPC 1, 2, …). Pick one to name it.')
        self.npcs.currentRowChanged.connect(self._row_picked)
        self.npcs.itemDoubleClicked.connect(lambda _it: self._name())
        v.addWidget(self.npcs, 1)
        brow = QHBoxLayout()
        self.b_name = QPushButton('Name this NPC…')
        self.b_name.setToolTip('Your name for the picked NPC (e.g. “King — after class B”). '
                               'It shows in this tab, on the Rooms tab canvas and in the '
                               'cutscene storyboards; the same NPC in the screen\'s other '
                               'states gets it too. Game rooms too — it is only for you, '
                               'never in the ROM.')
        self.b_name.clicked.connect(self._name)
        self.b_open = QPushButton('Open in the Rooms tab')
        self.b_open.clicked.connect(self._open)
        brow.addWidget(self.b_name)
        brow.addWidget(self.b_open)
        v.addLayout(brow)
        self.note = QLabel('')
        self.note.setWordWrap(True)
        self.note.setStyleSheet('color: gray')
        v.addWidget(self.note)

    # ------------------------------------------------------------ API
    def show_places(self, places, title='', i=0):
        self.places = [dict(p) for p in (places or []) if p]
        self.title_text = title
        self.i = max(0, min(i, len(self.places) - 1)) if self.places else 0
        self.setVisible(True)
        self._load()

    def place(self):
        return self.places[self.i] if self.places else None

    def refresh(self):
        """Re-draw (after an edit — names may have changed)."""
        if self.isVisible() and self.places:
            self._draw(keep_sel=True)

    # ------------------------------------------------------------ model
    def _custom(self):
        return self.s.doc.data.get('custom') or {}

    def _room(self, p):
        rid = p.get('room')
        try:
            return self.s.doc.room(rid) if rid else None
        except Exception:                                        # noqa: BLE001
            return None

    def _kind(self, p):
        """'game' | 'room' | None (a place with no room screen to show)."""
        if p.get('tab') == 'game' and p.get('map') is not None:
            return 'game'
        if p.get('room') and self._room(p) is not None:
            return 'room'
        return None

    def _screen(self, p):
        if p.get('screen') is not None:
            return int(p['screen'])
        if self._kind(p) == 'game':
            for m, _n, scr in self.s.renderer.vanilla_rooms():
                if m == int(p['map']):
                    return scr[0]
            return 0
        room = self._room(p)
        return self.s.doc.screen_keys(room)[0] if room is not None else 0

    def _nstates(self, p):
        k = self._kind(p)
        try:
            if k == 'game':
                return len(self.s.renderer.vanilla_steps(int(p['map']), self._screen(p)))
            if k == 'room':
                return len(self.s.doc.states(self._room(p), self._screen(p)))
        except Exception:                                        # noqa: BLE001
            pass
        return 1

    def _entries(self, p, state):
        k = self._kind(p)
        r = self.s.renderer
        if k == 'game':
            return r.vanilla_markers(int(p['map']), self._screen(p), state)[0]
        if k == 'room':
            return r.screen_state(self._room(p), self._screen(p), state).get('npcs') or []
        return []

    def _build_rows(self, p, state):
        from editor2.app.rooms.canvas import classify_npc
        from editor2.core.cutscene_build import is_npc_entry
        k = self._kind(p)
        vn = (NN.names_in(self._custom(), int(p['map']), self._screen(p), state)
              if k == 'game' else {})
        rows, n = [], 0
        for e in self._entries(p, state):
            try:
                kind, x, y, spr, _label = classify_npc(e)
                npc = is_npc_entry(e)
            except Exception:                                    # noqa: BLE001
                continue
            nn = None
            name = None
            hidden = False
            if npc:
                n += 1
                nn = n
                name = e.get('actor') if k == 'room' else vn.get(n)
                if e.get('kind') == 'raw':
                    from editor2.core import formats as F
                    hidden = bool(F.val(e['bytes'][0]) & 0x40)
                else:
                    hidden = bool(e.get('hidden'))
            rows.append((nn, kind, x, y, spr, name, hidden))
        return rows

    # ------------------------------------------------------------ view
    def _load(self):
        p = self.place()
        if p is None:
            self.setVisible(False)
            return
        self.state = int(p.get('state') or 0)
        self.sel_n = p.get('n')
        self.state_box.blockSignals(True)
        self.state_box.clear()
        ns = self._nstates(p)
        for k in range(ns):
            self.state_box.addItem(f'state {k} of {ns}' + (' — the place' if k == self.state
                                                             else ''), k)
        self.state_box.setCurrentIndex(min(self.state, ns - 1))
        self.state_box.blockSignals(False)
        self.state_box.setEnabled(ns > 1)
        self._draw()

    def _step(self, d):
        if self.places:
            self.i = (self.i + d) % len(self.places)
            self._load()

    def _state_picked(self, _i):
        st = self.state_box.currentData()
        if st is None:
            return
        self.state = int(st)
        p = self.place()
        # keep the same NPC picked when it is there in the other state too
        if p is not None and self.sel_n is not None:
            old = next((r for r in self.rows if r[0] == self.sel_n), None)
            rows = self._build_rows(p, self.state)
            same = next((r for r in rows if old and r[0] is not None and
                         (r[4], r[2], r[3]) == (old[4], old[2], old[3])), None)
            self.sel_n = same[0] if same else None
        self._draw(keep_sel=True)

    def _who(self, p):
        who = p.get('who') or ''
        if p.get('n') is not None and int(self.state) == int(p.get('state') or 0) and \
                who.startswith('talking to '):
            row = next((r for r in self.rows if r[0] == p['n']), None)
            if row is not None and row[5]:
                who = f'talking to {row[5]} at ({row[2]}, {row[3]})'
        return who

    def _draw(self, keep_sel=False):
        p = self.place()
        k = self._kind(p) if p else None
        n = len(self.places)
        self.count.setText(f'{self.i + 1} of {n}' if n > 1 else '')
        self.prev.setEnabled(n > 1)
        self.next.setEnabled(n > 1)
        self.b_open.setText(GO_WHERE.get(p.get('tab'), 'Open'))
        self.rows = self._build_rows(p, self.state) if k else []
        scr = self._screen(p) if k else None
        if k == 'game':
            where = (f'{_esc(self.s.renderer.vanilla_name(int(p["map"])))} '
                     f'<span style="color:gray">(game room ${int(p["map"]):02X})</span>')
        elif k == 'room':
            where = _esc(self.s.doc.room_name(self._room(p)))
        else:
            where = _esc(p.get('where') or '')
        loc = f' · screen {scr}' if scr is not None else ''
        if k and self._nstates(p) > 1:
            loc += f' · state {self.state}'
        who = self._who(p)
        self.head.setText((f'<b>{_esc(self.title_text)}</b><br>' if self.title_text else '')
                          + (f'<b>{_esc(who)}</b><br>' if who else '') + where + loc)
        if not k:
            self.pic.setPixmap(QPixmap())
            self.pic.setVisible(False)
            self.npcs.clear()
            self.npcs.setVisible(False)
            self.b_name.setEnabled(False)
            self.state_box.setEnabled(False)
            self.note.setText('This place is not a room screen — Open goes there.')
            return
        self.pic.setVisible(True)
        self.npcs.setVisible(True)
        self._paint(p, scr)
        self.npcs.blockSignals(True)
        self.npcs.clear()
        sel_row = -1
        for r in self.rows:
            nn, kind, x, y, spr, name, hidden = r
            if nn is None:
                txt = f'{kind} spot at ({x}, {y})'
            else:
                what = f'sprite ${spr:02X}' if isinstance(spr, int) and spr < 0x1000 else 'monster'
                txt = (f'NPC {nn}: ' + (f'“{name}” — ' if name else '') +
                       f'{what} at ({x}, {y})' + (' · hidden' if hidden else ''))
            it = QListWidgetItem(txt)
            it.setData(Qt.UserRole, nn)
            if nn is None:
                it.setFlags(it.flags() & ~Qt.ItemIsSelectable)
                it.setForeground(QColor('gray'))
            self.npcs.addItem(it)
            if nn is not None and nn == self.sel_n:
                sel_row = self.npcs.count() - 1
        self.npcs.setCurrentRow(sel_row)
        self.npcs.blockSignals(False)
        self.b_name.setEnabled(self.sel_n is not None)
        on = int(p.get('state') or 0) == self.state
        miss = (p.get('x') is not None and on and
                not any(r[2] == p['x'] and r[3] == p['y'] for r in self.rows))
        self.note.setText('Outlined in yellow: the place. ' +
                          ('' if on else f'(It is in state {p.get("state") or 0}; this is '
                           f'state {self.state}.) ') +
                          ('⚠ nothing stands there in this state.' if miss else '') +
                          'Click an NPC to pick it.')

    def _paint(self, p, scr):
        r = self.s.renderer
        try:
            if self._kind(p) == 'game':
                img = r.render_vanilla_screen(int(p['map']), scr, SCALE, self.state)
            else:
                img = r.render_screen(self._room(p), scr, self.state, SCALE)
            pm = QPixmap.fromImage(ImageQt.ImageQt(img.convert('RGBA')))
        except Exception as e:                                   # noqa: BLE001
            self.pic.setText(f'(cannot draw this screen: {e})')
            return
        from editor2.app.rooms.canvas import SpriteCache
        qp = QPainter(pm)
        for nn, kind, x, y, spr, name, hidden in self.rows:
            rc = QRectF(x * CELL, y * CELL, CELL, CELL)
            if nn is not None:
                sp = SpriteCache.get(spr) if spr is not None else None
                if sp is not None:
                    if hidden:
                        qp.setOpacity(0.35)
                    qp.drawPixmap(rc.toRect(), sp)
                    qp.setOpacity(1.0)
                pen = QPen(QColor(255, 255, 255, 120))
            else:
                pen = QPen(QColor(0, 200, 255, 200))
                pen.setStyle(Qt.DashLine)
            qp.setPen(pen)
            qp.setBrush(Qt.NoBrush)
            qp.drawRect(rc.adjusted(0.5, 0.5, -0.5, -0.5))
            if name:
                qp.setFont(QFont('Helvetica', 7))
                nm = name[:18]
                tw = 6 + 5.2 * len(nm)
                tr = QRectF(rc.center().x() - tw / 2, max(0, rc.top() - 11), tw, 11)
                qp.fillRect(tr, QColor(0, 0, 0, 200))
                qp.setPen(QColor(255, 255, 255))
                qp.drawText(tr, Qt.AlignCenter, nm)
        # the place's cell (yellow), the picked NPC (cyan)
        if p.get('x') is not None and p.get('y') is not None and \
                int(p.get('state') or 0) == self.state:
            pen = QPen(QColor(255, 220, 0))
            pen.setWidth(3)
            qp.setPen(pen)
            qp.drawRect(QRectF(p['x'] * CELL - 1, p['y'] * CELL - 1, CELL + 2, CELL + 2))
        sel = next((r for r in self.rows if r[0] is not None and r[0] == self.sel_n), None)
        if sel is not None:
            pen = QPen(QColor(0, 230, 255))
            pen.setWidth(2)
            pen.setStyle(Qt.DotLine)
            qp.setPen(pen)
            qp.drawRect(QRectF(sel[2] * CELL - 3, sel[3] * CELL - 3, CELL + 6, CELL + 6))
        qp.end()
        self.pic.setPixmap(pm)

    # ------------------------------------------------------------ actions
    def _clicked(self, x, y):
        row = next((r for r in self.rows if r[0] is not None and r[2] == x and r[3] == y), None)
        if row is not None:
            self.sel_n = row[0]
            self._draw(keep_sel=True)

    def _row_picked(self, row):
        it = self.npcs.item(row) if row >= 0 else None
        nn = it.data(Qt.UserRole) if it is not None else None
        if nn is not None and nn != self.sel_n:
            self.sel_n = nn
            self._draw(keep_sel=True)

    def _name(self):
        p = self.place()
        if p is None or self.sel_n is None:
            return
        row = next((r for r in self.rows if r[0] == self.sel_n), None)
        if row is None:
            return
        text, ok = QInputDialog.getText(
            self, 'Name this NPC', f'Your name for NPC {self.sel_n} at ({row[2]}, {row[3]}) '
            '(empty = no name).\nThe same NPC in this screen\'s other states gets it too:',
            text=row[5] or '')
        if not ok:
            return
        k, scr, st, n = self._kind(p), self._screen(p), self.state, self.sel_n
        if k == 'game':
            mid = int(p['map'])
            op = lambda doc: doc.name_npc(text, mid=mid, screen=scr, state=st, n=n)  # noqa: E731
        else:
            rid = p['room']
            op = lambda doc: doc.name_npc(text, room=rid, screen=scr, state=st, n=n)  # noqa: E731
        cmd = C.SnapshotCommand(self.s, 'Name an NPC', op)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Name this NPC', str(cmd.error))
            return
        self._draw(keep_sel=True)

    def _open(self):
        p = self.place()
        if p is None:
            return
        nav = dict(p)
        if self._kind(p) and nav.get('tab') in ('game', 'rooms'):
            nav['state'] = self.state            # what the panel shows
            row = next((r for r in self.rows if r[0] == self.sel_n), None)
            if row is not None:
                nav['x'], nav['y'] = row[2], row[3]
            elif int(p.get('state') or 0) != self.state:
                nav['x'] = nav['y'] = None
        self.navigate.emit(nav)

    def _close(self):
        self.setVisible(False)
        self.closed.emit()
