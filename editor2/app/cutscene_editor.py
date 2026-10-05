"""cutscene_editor.py — the cutscene EDITOR (S119, ROADMAP P3.8 part B).

The user's direction (S119): "Should be specific NPCs. Design should be visual,
ie you should indicate which NPC faces where, moves where, and operates by
tile … Custom cutscenes should be previewable. Everything should be in tiles."
→ a step list (left), the ROOM as a stage (middle: the screen with every
actor drawn as the game draws it, facing where the scene has turned it, the
selected step's movement as arrows, drag an actor onto a tile = a walk there,
right-click = everything an actor can do), the selected step's settings
(right), the problems line, and two previews: ▶ Preview (the editor's model,
instant, no build) and ▶ Play in the game (build, then the Playback window
plays the scene in the real game, set up for you).

Model / compiler: editor2/core/cutscene_build.py (the SAME pass makes the ops
and the pictures); data edits: editor2/core/cutscene_doc.py. Every change is
one undo step (SnapshotCommand).
"""

import copy
import os

from PySide6.QtCore import QPoint, QPointF, QRectF, Qt, QTimer, Signal
from PySide6.QtGui import (QBrush, QColor, QFont, QImage, QPainter, QPainterPath, QPen,
                           QPixmap, QPolygonF)
from PySide6.QtWidgets import (QAbstractItemView, QCheckBox, QComboBox, QFormLayout,
                               QHBoxLayout, QInputDialog, QLabel, QLineEdit, QListWidget,
                               QListWidgetItem, QMenu, QMessageBox, QPlainTextEdit,
                               QPushButton, QScrollArea, QSlider, QSpinBox, QSplitter,
                               QToolButton, QTreeWidget, QTreeWidgetItem, QVBoxLayout,
                               QWidget)

from editor2.app.session import REPO
from editor2.core import cutscene_build as CB
from editor2.core import cutscene_doc as CD

FACE_SPRITES = os.path.join(REPO, 'extracted', 'npc_facing_sprites')
OLD_SPRITES = os.path.join(REPO, 'extracted', 'npc_field_sprites')
S = 3                                     # stage scale
DIRS = CB.DIR_NAMES
KIND_COLOUR = {
    'say': '#f0e6a0', 'ask': '#f0e6a0', 'if': '#aaaaaa', 'set': '#c8aaff', 'clear': '#c8aaff',
    'walk': '#8cc8ff', 'face': '#8cc8ff', 'show': '#9fe0c0', 'hide': '#9fe0c0',
    'anim': '#8cc8ff', 'fly': '#8cc8ff', 'wait': '#999999', 'wait_walks': '#999999',
    'music': '#a0e6a0', 'sound': '#a0e6a0', 'shake': '#ffc878', 'fade': '#ffc878',
    'flash': '#ffc878', 'followers': '#ffc878', 'give_item': '#ffdc96',
    'give_monster': '#ffb4dc', 'tiles': '#ffc878', 'battle': '#ff7878', 'move': '#ffaa78',
    'end': '#cccccc', 'name_hero': '#f0e6a0'}
ADD_GROUPS = [
    ('Actors', ['walk', 'face', 'show', 'hide', 'anim', 'fly']),
    ('Text and choices', ['say', 'ask', 'if', 'name_hero']),
    ('Time', ['wait', 'wait_walks']),
    ('Screen', ['shake', 'fade', 'flash', 'tiles', 'followers']),
    ('Sound', ['music', 'sound']),
    ('Story', ['set', 'clear', 'give_item', 'give_monster', 'battle', 'move', 'end']),
]
# S119b (user: "Can you not hover or explain what is e.g. 'wait until everyone
# stops'?"): what each step does — under the form's title, on the Add step menu and
# on the step list (hover); FIELD_HELP / CHECK_HELP = hover text of the form rows.
STEP_HELP = {
    'say': 'Shows text boxes (2 lines each, drawn as in the game). The player presses A '
           'after each box; the scene goes on when the last one is closed.',
    'ask': 'Text whose last box ends in a YES / NO choice (the cursor starts on NO, as in the '
           'game). The steps under "If YES" / "If NO" run for that answer; then both go on '
           'with the next step.',
    'if': 'Runs the steps under "Then" when every flag in "All ON" is ON and every flag in '
          '"All OFF" is OFF — otherwise the steps under "Otherwise".',
    'set': 'Turns flags ON (saved with the game). Other scenes, NPCs ("shown when …") and room '
           'states can react to them.',
    'clear': 'Turns flags OFF (saved with the game).',
    'walk': 'Someone walks to a tile, one tile at a time along an L-shaped path (across first, '
            'or up / down first). The scene waits until he arrives — unless "the next step '
            'starts at once" is ticked. Tip: drag the actor on the picture.',
    'face': 'Someone turns to look in a direction, or toward another actor.',
    'show': 'A hidden NPC appears — a cast member, or someone an earlier step hid: '
            'instantly, flickering in (about 4 s) or spinning in; on his own tile or another one.',
    'hide': 'Someone disappears (instantly or flickering out). He stays away until the room is '
            'loaded again.',
    'anim': 'One of the game\'s own movements (hop, jumps, leaps …) — the same ones the '
            'game\'s scenes use.',
    'fly': 'Fly in: the NPC comes through the air in an arc and lands on a tile. Fly off: he '
           'leaves in an arc toward a side of the screen.',
    'wait': 'Pauses the scene for a while (60 frames = 1 second). Whatever is already moving '
            'keeps moving.',
    'wait_walks': 'Waits until every walk / hop / flight that was started with "the next step '
                  'starts at once" has finished. Use it after letting several people move at '
                  'the same time, before the next text.',
    'music': 'Plays another song (or goes back to the room\'s own one). It lasts until the '
             'player leaves the room.',
    'sound': 'Plays a sound effect.',
    'shake': 'Shakes the screen (up and down, left and right, or both).',
    'fade': 'Fades the screen to black in 3 steps — or back in from black. Fade back in before '
            'the scene ends.',
    'flash': 'The screen flashes for a moment (lightning, magic …).',
    'followers': 'Hides the monsters walking behind the player (or shows them again) — for '
                 'scenes where they would be in the way.',
    'give_item': 'Puts an item in the bag. The game says nothing by itself: write what the '
                 'player reads ("Then say"), and what happens when the bag is full.',
    'give_monster': 'Gives a monster (it goes to the party or the farm). Write what the player '
                    'reads, and what happens when there is no room.',
    'tiles': 'Changes a piece of the room picture (an opened door, a cleared path …) to how it '
             'looks in another screen / state of the room. Until the room is loaded again.',
    'battle': 'Starts a battle with up to 3 enemies. The steps after it run only when the '
              'player wins.',
    'move': 'Sends the player to a room / screen / tile (the scene ends there).',
    'end': 'The scene stops here.',
    'name_hero': 'Opens the game\'s naming screen (the King\'s "What is your name?" one): the player types the hero\'s name, confirms it, and the '
                 'scene goes on. It offers the current name — MILLY with the Milly hook, '
                 'else TERRY. Text after it can use the name ({hero}).',
}
FIELD_HELP = {
    'Who': 'Who this step is about. NPCs that have no name yet are listed at the end — '
           'picking one gives it a name (rename it with a right-click on the picture).',
    'To': 'The tile to walk to: x = 0-9 across, y = 0-7 down (or "Pick on the picture").',
    'Path': 'Which way the L-shaped walk goes first. Pick the one whose path is free.',
    'Faces': 'A direction, or toward another actor (he turns to wherever that one stands then).',
    'How': 'Instantly, flickering (about 4 seconds) or spinning.',
    'At the tile': 'Where he appears (instead of his own tile).',
    'Move': 'The game\'s own movement to play.',
    'Flight': 'In from a side and landing on a tile, or off toward a side.',
    'Lands on': 'The tile the flight ends on.',
    'Length': 'How far the flight goes, in tiles across.',
    'Curve': 'The shape of the arc — the game\'s own curves; try them with ▶ Preview / ▶ Play.',
    'Wait': 'How long: 60 frames = 1 second.',
    'Song': 'The song to play.',
    'Sound': 'The sound effect (▶ Hear it plays it).',
    'Direction': 'Which way the screen shakes.',
    'For': 'How long it shakes (60 frames = 1 second).',
    'Fade': 'To black, or back in from black.',
    'Each step': 'A fade has 3 steps; each lasts this long.',
    'Flash': 'How long the flash lasts (60 frames = 1 second).',
    'Item': 'The item to give.',
    'Monster': 'The monster to give.',
    'Text': 'One editor per text box, drawn as the game draws it. Red = does not fit (Fit wraps '
            'it); + Add box for the next box.',
    'Question': 'The last box is the question; the YES / NO box opens below it.',
    'Then say': 'What the player reads after getting it.',
    'When it is full': 'What the player reads when there is no room — he gets nothing then.',
    'Box': 'Where the text box is: where the game puts it (away from the player), at the top '
           'or at the bottom.',
    'All ON': 'Every ticked flag must be ON.',
    'All OFF': 'Every ticked flag must be OFF.',
    'Flags': 'The flags this step turns ON / OFF (New flag… makes one).',
    'Top-left tile': 'The top-left tile of the piece that changes.',
    'Width': 'How many tiles across.',
    'Height': 'How many tiles down.',
    'Look like': 'The screen / room state whose tiles are copied to that place.',
    'Enemy 1': 'The enemies of the battle (from the Enemies tab).',
    'Enemy 2': 'The enemies of the battle (from the Enemies tab).',
    'Enemy 3': 'The enemies of the battle (from the Enemies tab).',
    'To room': 'The room the player goes to.',
    'Screen': 'The screen of that room.',
    'x': 'The tile across (0-9).',
    'y': 'The tile down (0-7).',
    'The monsters following the player': 'Hide them for the scene, or show them again.',
}
CHECK_HELP = {
    'the next step starts at once (walk together with it)':
        'Do not wait for this walk: the next step starts right away (two people walking at '
        'once). Add "Wait until everyone stops" before the next text.',
    'the next step starts at once':
        'Do not wait for this: the next step starts right away. Add "Wait until everyone '
        'stops" later.',
    'run (double speed)': 'Walk twice as fast.',
    'keep facing (walk backwards)': 'He keeps looking the way he faces now while he walks.',
    'somewhere else than its own tile': 'Appear on another tile than the one the NPC stands '
                                        'on in the room.',
    'the scene waits while it shakes': 'Untick to let the next steps run while the screen '
                                       'shakes.',
}


TRIGGER_LABELS = [('entry', 'Entering the room (this screen)'), ('talk', 'Talking to an NPC'),
                  ('examine', 'Examining a tile (A in front of it)'),
                  ('stepon', 'Stepping on a tile')]


# ---------------------------------------------------------------- sprites

class Sprites:
    """Actor pictures in every facing, as the game draws them
    (extracted/npc_facing_sprites, tools/extract_npc_facings.py — PyBoy)."""
    _strips = {}

    @classmethod
    def frame(cls, sprite, face, step=0, monster=None):
        if monster is not None:
            try:
                from editor2.app.rooms.canvas import MonsterCache
                pm = MonsterCache.get(monster)
                if pm is not None:
                    return pm
            except Exception:                            # noqa: BLE001
                pass
        key = 'player' if sprite == 'player' else f'id_{int(sprite) & 0xFF:02X}'
        if key not in cls._strips:
            p = os.path.join(FACE_SPRITES, key + '.png')
            pm = QPixmap(p) if os.path.exists(p) else None
            if pm is None or pm.isNull():
                p2 = os.path.join(OLD_SPRITES, key + '.png')
                pm = QPixmap(p2) if os.path.exists(p2) else None
            cls._strips[key] = pm
        pm = cls._strips[key]
        if pm is None or pm.isNull():
            return None
        if pm.width() < 128:
            return pm
        return pm.copy(((face & 3) * 2 + (step & 1)) * 16, 0, 16, 16)


# ---------------------------------------------------------------- the stage

class Stage(QWidget):
    """One room screen with the scene's actors. Cell coordinates are the
    screen's (0-9, 0-7); actors are given in the room's absolute pixels."""
    actorDragged = Signal(str, int, int)
    actorPicked = Signal(str)
    menuAt = Signal(object, int, int, QPoint)        # actor name or None, cell, global pos
    cellPicked = Signal(int, int)

    def __init__(self):
        super().__init__()
        self.setFixedSize(160 * S, 128 * S)
        self.setMouseTracking(True)
        self.bg = None
        self.screen = 0
        self.actors = {}          # name -> dict(x, y, face, shown, known, sprite, monster, step)
        self.moves = []           # [(name, (x0, y0), (x1, y1), style, order)]
        self.text = None
        self.effects = {}
        self.selected = None
        self.patch = None         # ((x, y), w, h) highlight
        self.others = []          # unnamed NPCs of the shown state: (cell, face, sprite, monster, hidden, n)
        self.hover = None
        self._drag = None         # (name, start QPoint)
        self._drag_cell = None
        self.pick_mode = False

    def set_background(self, pm, screen):
        self.bg, self.screen = pm, int(screen)
        self.update()

    def to_widget(self, px, py):
        col, row = self.screen % 4, self.screen // 4
        return QPointF((px - 8 - col * 160) * S, (py - 8 - row * 128) * S)

    def cell_at(self, pos):
        return int(pos.x() // (16 * S)), int(pos.y() // (16 * S))

    def actor_at(self, pos):
        for name, a in sorted(self.actors.items(), key=lambda kv: kv[0] != self.selected):
            p = self.to_widget(a['x'], a['y'])
            if QRectF(p.x(), p.y(), 16 * S, 16 * S).contains(QPointF(pos)):
                return name
        return None

    # -------------------------------------------------------------- paint
    def paintEvent(self, _ev):
        p = QPainter(self)
        sh = self.effects.get('shake', (0, 0))
        p.translate(sh[0] * S, sh[1] * S)
        if self.bg is not None:
            p.drawPixmap(0, 0, self.bg)
        else:
            p.fillRect(self.rect(), QColor(40, 40, 40))
        p.setPen(QPen(QColor(255, 255, 255, 38), 1))
        for x in range(1, 10):
            p.drawLine(x * 16 * S, 0, x * 16 * S, 128 * S)
        for y in range(1, 8):
            p.drawLine(0, y * 16 * S, 160 * S, y * 16 * S)
        if self.patch is not None:
            (cx, cy), w, h = self.patch
            p.setPen(QPen(QColor(255, 200, 80), 2, Qt.DashLine))
            p.drawRect(cx * 16 * S, cy * 16 * S, w * 16 * S, h * 16 * S)
        for (cx, cy), face, spr, mon, hidden, n in self.others:
            pm = Sprites.frame(spr or 0, face, 0, mon)
            p.setOpacity(0.25 if hidden else 0.55)
            if pm is not None:
                p.drawPixmap(QRectF(cx * 16 * S, cy * 16 * S, 16 * S, 16 * S), pm, QRectF(pm.rect()))
            p.setOpacity(1.0)
            p.setPen(QColor(200, 200, 200))
            p.setFont(QFont('Helvetica', 8))
            p.drawText(QRectF(cx * 16 * S, cy * 16 * S - 13, 16 * S, 12), Qt.AlignCenter,
                       f'NPC {n}')
        for mv in self.moves:
            self._draw_move(p, *mv)
        for name, a in sorted(self.actors.items(), key=lambda kv: kv[1]['y']):
            self._draw_actor(p, name, a)
        if self._drag is not None and self._drag_cell is not None:
            cx, cy = self._drag_cell
            p.setPen(QPen(QColor(255, 255, 80), 2))
            p.setBrush(QColor(255, 255, 80, 50))
            p.drawRect(cx * 16 * S, cy * 16 * S, 16 * S, 16 * S)
            p.setBrush(Qt.NoBrush)
        if self.hover is not None and self._drag is None:
            cx, cy = self.hover
            p.setPen(QPen(QColor(255, 255, 255, 110), 1))
            p.drawRect(cx * 16 * S, cy * 16 * S, 16 * S, 16 * S)
        fade = self.effects.get('fade', 0)
        if fade:
            p.fillRect(self.rect(), QColor(0, 0, 0, int(255 * fade)))
        if self.effects.get('flash'):
            p.fillRect(self.rect(), QColor(255, 255, 240, 200))
        if self.text:
            self._draw_text(p, self.text)
        if self.hover is not None:
            p.resetTransform()
            p.setPen(QColor(255, 255, 255))
            p.setFont(QFont('Menlo', 10))
            p.drawText(6, 128 * S - 6, f'tile ({self.hover[0]}, {self.hover[1]})')
        p.end()

    def _draw_actor(self, p, name, a):
        pt = self.to_widget(a['x'], a['y'])
        pm = Sprites.frame('player' if name == CB.PLAYER else a.get('sprite') or 0,
                           a.get('face', 0), a.get('step', 0), a.get('monster'))
        p.setOpacity(1.0 if a.get('shown', True) else 0.32)
        if pm is not None:
            p.drawPixmap(QRectF(pt.x(), pt.y(), 16 * S, 16 * S), pm, QRectF(pm.rect()))
        else:
            p.fillRect(QRectF(pt.x() + 6, pt.y() + 6, 36, 36), QColor(200, 80, 80))
        p.setOpacity(1.0)
        # facing: a small wedge on the side he faces
        cx, cy = pt.x() + 8 * S, pt.y() + 8 * S
        d = [(0, 1), (-1, 0), (0, -1), (1, 0)][a.get('face', 0) & 3]
        tip = QPointF(cx + d[0] * 10 * S, cy + d[1] * 10 * S)
        side = QPointF(-d[1] * 3 * S, d[0] * 3 * S)
        base = QPointF(cx + d[0] * 7 * S, cy + d[1] * 7 * S)
        p.setPen(Qt.NoPen)
        p.setBrush(QColor(255, 230, 60) if name == self.selected else QColor(255, 255, 255, 200))
        p.drawPolygon(QPolygonF([tip, base + side, base - side]))
        p.setBrush(Qt.NoBrush)
        if name == self.selected:
            p.setPen(QPen(QColor(255, 230, 60), 2))
            p.drawRect(QRectF(pt.x(), pt.y(), 16 * S, 16 * S))
        if not a.get('shown', True):
            p.setPen(QPen(QColor(200, 255, 220), 1, Qt.DashLine))
            p.drawRect(QRectF(pt.x() + 1, pt.y() + 1, 16 * S - 2, 16 * S - 2))
        label = 'Player' if name == CB.PLAYER else name
        if not a.get('known', True):
            label += ' ?'
        f = QFont('Helvetica', 9)
        f.setBold(True)
        p.setFont(f)
        w = p.fontMetrics().horizontalAdvance(label) + 6
        r = QRectF(pt.x() + 8 * S - w / 2, pt.y() - 15, w, 14)
        p.fillRect(r, QColor(0, 0, 0, 150))
        p.setPen(QColor(255, 255, 255))
        p.drawText(r, Qt.AlignCenter, label)

    def _draw_move(self, p, name, a, b, style, order=None):
        pa, pb = self.to_widget(*a), self.to_widget(*b)
        off = QPointF(8 * S, 8 * S)
        pa, pb = pa + off, pb + off
        col = {'walk': QColor(120, 200, 255), 'jump': QColor(255, 170, 80),
               'fly': QColor(230, 140, 255), 'appear': QColor(140, 255, 190),
               'vanish': QColor(255, 140, 140), 'teleport': QColor(140, 255, 190)}.get(
            style, QColor(255, 255, 255))
        p.setPen(QPen(col, 3, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin))
        path = QPainterPath(pa)
        if style == 'walk':
            mid = QPointF(pb.x(), pa.y()) if (order or ('x', 'y'))[0] == 'x' else QPointF(pa.x(), pb.y())
            path.lineTo(mid)
            path.lineTo(pb)
            end_from = mid if mid != pb else pa
        elif style in ('jump', 'fly'):
            ctrl = QPointF((pa.x() + pb.x()) / 2, min(pa.y(), pb.y()) - 18 * S)
            path.quadTo(ctrl, pb)
            end_from = ctrl
        else:
            p.drawEllipse(pb, 9 * S, 9 * S)
            return
        p.drawPath(path)
        if pa != pb:
            v = pb - end_from
            ln = max(1e-6, (v.x() ** 2 + v.y() ** 2) ** 0.5)
            u = QPointF(v.x() / ln, v.y() / ln)
            n = QPointF(-u.y(), u.x())
            p.setBrush(col)
            p.drawPolygon(QPolygonF([pb, pb - u * 12 + n * 7, pb - u * 12 - n * 7]))
            p.setBrush(Qt.NoBrush)
        else:
            p.drawEllipse(pa, 10 * S, 10 * S)

    def _draw_text(self, p, text):
        r = QRectF(4 * S, 88 * S, 152 * S, 38 * S)
        p.setPen(QPen(QColor(40, 40, 40), 3))
        p.setBrush(QColor(248, 240, 208))
        p.drawRoundedRect(r, 6, 6)
        p.setBrush(Qt.NoBrush)
        p.setPen(QColor(30, 30, 30))
        f = QFont('Menlo', 15)
        f.setStyleHint(QFont.Monospace)
        p.setFont(f)
        p.drawText(r.adjusted(10, 6, -8, -4), Qt.TextWordWrap, text)

    # -------------------------------------------------------------- mouse
    def mousePressEvent(self, ev):
        pos = ev.position().toPoint()
        cx, cy = self.cell_at(pos)
        if ev.button() == Qt.RightButton:
            self.menuAt.emit(self.actor_at(pos), cx, cy, ev.globalPosition().toPoint())
            return
        if self.pick_mode:
            self.cellPicked.emit(cx, cy)
            return
        name = self.actor_at(pos)
        if name is not None:
            self._drag = (name, pos)
            self._drag_cell = None
            self.actorPicked.emit(name)
        else:
            self.cellPicked.emit(cx, cy)

    def mouseMoveEvent(self, ev):
        pos = ev.position().toPoint()
        c = self.cell_at(pos)
        if c != self.hover:
            self.hover = c if 0 <= c[0] < 10 and 0 <= c[1] < 8 else None
            self.update()
        if self._drag is not None and (pos - self._drag[1]).manhattanLength() > 6:
            self._drag_cell = c
            self.update()

    def mouseReleaseEvent(self, ev):
        if self._drag is not None and self._drag_cell is not None:
            name = self._drag[0]
            cx, cy = self._drag_cell
            self._drag, self._drag_cell = None, None
            self.update()
            self.actorDragged.emit(name, cx, cy)
            return
        self._drag, self._drag_cell = None, None

    def leaveEvent(self, _ev):
        self.hover = None
        self.update()


# ---------------------------------------------------------------- the step form

def _text_from_boxes(v):
    if isinstance(v, dict) and v.get('boxes'):
        return '\n\n'.join('\n'.join(b) for b in v['boxes'])
    return '' if v is None else str(v)


def _boxes_from_text(t):
    boxes = []
    for chunk in t.strip('\n').split('\n\n'):
        lines = [ln for ln in chunk.split('\n') if ln.strip() or chunk.strip()]
        lines = [ln.rstrip() for ln in lines if ln.strip()]
        if lines:
            boxes.append(lines[:2] if len(lines) <= 2 else lines)
    return {'boxes': boxes or [['…']]}


class StepForm(QWidget):
    """The selected step's settings. `changed(value)` = the step's new dict."""
    changed = Signal(object)
    pickCell = Signal(str)                 # ask the stage for a tile (field name)

    def __init__(self, editor):
        super().__init__()
        self.ed = editor
        self.v = QVBoxLayout(self)
        self.title = QLabel('')
        f = self.title.font()
        f.setBold(True)
        self.title.setFont(f)
        self.v.addWidget(self.title)
        self.about = QLabel('')
        self.about.setWordWrap(True)
        self.about.setStyleSheet('color:#aab;')
        self.v.addWidget(self.about)
        self.body = QWidget()
        self.form = QFormLayout(self.body)
        self.v.addWidget(self.body)
        self.note = QLabel('')
        self.note.setWordWrap(True)
        self.note.setStyleSheet('color:#9ab;')
        self.v.addWidget(self.note)
        self.v.addStretch(1)
        self.step = None
        self._busy = False

    def clear(self):
        while self.form.rowCount():
            self.form.removeRow(0)

    def flush(self):
        """Store a typed text that is waiting for its pause (S119b) — before the
        form shows another step, a preview, Play, Save."""
        for f in getattr(self, '_stores', []):
            try:
                f()
            except RuntimeError:             # its widget is gone already
                pass
        p, self._pending = self._pending, None
        if p is not None:
            self.changed.emit(p)

    def show_step(self, step, note='', path=None):
        for f in getattr(self, '_stores', []):          # typed text not stored yet: it
            try:                                         # is queued with ITS step's path
                f()
            except RuntimeError:
                pass
        self._stores = []
        self._busy = True
        self.clear()
        self.path = path
        self.step = copy.deepcopy(step) if step is not None else None
        self.note.setText(note)
        if step is None:
            self.title.setText('Select a step — or add one (＋ Add step), or drag an actor '
                               'on the picture to a tile.')
            self.about.setText('')
            self._busy = False
            return
        k = CB.step_kind(step)
        self.title.setText(CB.STEP_NAMES.get(k, k))
        self.about.setText(STEP_HELP.get(k, ''))
        getattr(self, 'f_' + k, lambda v: None)(step[k])
        self._tooltips()
        self._busy = False

    def _tooltips(self):
        """Hover text for every row of the form (FIELD_HELP by row label, CHECK_HELP
        by check box text)."""
        for r in range(self.form.rowCount()):
            li = self.form.itemAt(r, QFormLayout.LabelRole)
            fi = self.form.itemAt(r, QFormLayout.FieldRole) or \
                self.form.itemAt(r, QFormLayout.SpanningRole)
            lw = li.widget() if li is not None else None
            fw = fi.widget() if fi is not None else None
            tip = FIELD_HELP.get(lw.text()) if isinstance(lw, QLabel) else None
            if isinstance(fw, QCheckBox):
                tip = CHECK_HELP.get(fw.text(), tip)
            if tip:
                for w in (lw, fw):
                    if w is not None and not w.toolTip():
                        w.setToolTip(tip)

    # ---- widgets
    def _emit(self, k, v):
        if self._busy or self.step is None:
            return
        st = dict(self.step)
        st[k] = v
        self.step = st
        # S119b (user's Mac: "Segmentation fault: 11" picking an NPC in a walk's
        # Who list): the commit rebuilds this form, which DELETES the widget whose
        # signal is still running — macOS crashes when a combo box dies while its
        # popup closes. So the change is applied after the signal returns (the
        # step's path is kept: the selection may move before the flush).
        first = self._pending is None
        self._pending = (getattr(self, 'path', None), copy.deepcopy(st))
        if first:
            QTimer.singleShot(0, self._flush)

    _pending = None

    def _flush(self):
        p, self._pending = self._pending, None
        if p is not None:
            self.changed.emit(p)

    def _actor_box(self, cur, player=True, npc=True):
        cb = QComboBox()
        for name, n, _e in self.ed.actor_list():
            if (name == CB.PLAYER and not player) or (name != CB.PLAYER and not npc):
                continue
            cb.addItem('Player' if name == CB.PLAYER else f'{name}  (NPC {n})', name)
        if npc:
            for lbl, tok in self.ed.unnamed_choices():
                cb.addItem(lbl, tok)
        i = cb.findData(cur)
        if i < 0 and cur:
            cb.addItem(f'{cur} (not on this screen!)', cur)
            i = cb.count() - 1
        cb.setCurrentIndex(max(0, i))
        return cb

    def _cell_row(self, label, x, y, on_change, field='to'):
        w = QWidget()
        h = QHBoxLayout(w)
        h.setContentsMargins(0, 0, 0, 0)
        sx, sy = QSpinBox(), QSpinBox()
        sx.setKeyboardTracking(False)
        sy.setKeyboardTracking(False)
        sx.setRange(CB.CELL_MIN, CB.CELL_MAX_X)
        sy.setRange(CB.CELL_MIN, CB.CELL_MAX_Y)
        sx.setValue(int(x if x is not None else 0))
        sy.setValue(int(y if y is not None else 0))
        sx.valueChanged.connect(lambda _v: on_change([sx.value(), sy.value()]))
        sy.valueChanged.connect(lambda _v: on_change([sx.value(), sy.value()]))
        h.addWidget(QLabel('x'))
        h.addWidget(sx)
        h.addWidget(QLabel('y'))
        h.addWidget(sy)
        b = QPushButton('Pick on the picture')
        b.setToolTip('Then click a tile on the room picture')
        b.clicked.connect(lambda: self.pickCell.emit(field))
        h.addWidget(b)
        self.form.addRow(label, w)
        return sx, sy

    def _check(self, label, val, on):
        c = QCheckBox(label)
        c.setChecked(bool(val))
        c.toggled.connect(on)
        self.form.addRow('', c)
        return c

    def _combo(self, label, items, cur, on):
        cb = QComboBox()
        for text, data in items:
            cb.addItem(text, data)
        i = cb.findData(cur)
        cb.setCurrentIndex(max(0, i))
        cb.currentIndexChanged.connect(lambda _i: on(cb.currentData()))
        self.form.addRow(label, cb)
        return cb

    def _spin(self, label, lo, hi, cur, on, suffix=''):
        sp = QSpinBox()
        sp.setRange(lo, hi)
        sp.setValue(int(cur))
        sp.setKeyboardTracking(False)    # S119b: typed digits count on Enter / leaving
        if suffix:
            sp.setSuffix(suffix)
        sp.valueChanged.connect(on)
        self.form.addRow(label, sp)
        return sp

    def _text(self, label, v, on, help_=''):
        """S119b (user: "Why not preview message using in-game boxes for new line and
        next box … This is already implemented in NPC conversations??"): the same
        box editor as the NPC conversations — one editor per box, each drawn with
        the game's font and frame, what does not fit in red, Fit / Fit all / + Add box.
        Stored after a pause (0.7 s) or when the form changes step — never per key
        (user: "Why is text box so slow to type in?")."""
        from editor2.app.rooms.talk_editor import BoxList
        boxes = [list(b) for b in ((v or {}).get('boxes') or []) if b] or [['']]
        bl = BoxList(self.ed.s.renderer.rom, boxes, first_default='', vertical=True,
                     meta=v if isinstance(v, dict) else None)
        bl.setMinimumHeight(min(640, 80 + 250 * len(boxes)))
        bl.scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        pause = QTimer(bl)
        pause.setSingleShot(True)
        pause.setInterval(700)
        start = ([[ln for ln in b] for b in bl.boxes()], bl.meta())

        def store():
            pause.stop()
            got = [b for b in bl.boxes() if any(ln.strip() for ln in b)] or [['']]
            meta = bl.meta()                               # S120 speaker / voice
            if (got, meta) == getattr(bl, '_stored', start):
                return
            bl._stored = (got, meta)
            val = {k: x for k, x in dict(v or {}).items() if k not in ('speaker', 'voice')}
            val['boxes'] = got
            val.update(meta)
            on(val)
        pause.timeout.connect(store)
        bl.changed.connect(pause.start)
        self.form.addRow(label, bl)
        if help_:
            hl = QLabel(help_)
            hl.setWordWrap(True)
            hl.setStyleSheet('color:#999;')
            self.form.addRow('', hl)
        self._stores = getattr(self, '_stores', []) + [store]
        return bl

    def _flags_list(self, label, cur, on):
        lw = QListWidget()
        lw.setMaximumHeight(110)
        cur = list(cur or [])
        names = [f.get('name') for f in self.ed.s.doc.flags()]
        names += list(self.ed.s.doc.milly_flag_names())          # S121: hook:milly …
        for n in names + [c for c in cur if c not in names]:
            it = QListWidgetItem(str(n))
            it.setFlags(it.flags() | Qt.ItemIsUserCheckable)
            it.setCheckState(Qt.Checked if n in cur else Qt.Unchecked)
            lw.addItem(it)

        def changed(_it):
            on([lw.item(i).text() for i in range(lw.count())
                if lw.item(i).checkState() == Qt.Checked])
        lw.itemChanged.connect(changed)
        w = QWidget()
        h = QVBoxLayout(w)
        h.setContentsMargins(0, 0, 0, 0)
        h.addWidget(lw)
        b = QPushButton('New flag…')
        b.clicked.connect(lambda: QTimer.singleShot(0, self.ed.new_flag))   # S119b: not inside the button's own signal (the reload deletes it)
        h.addWidget(b)
        self.form.addRow(label, w)
        return lw

    # ---- per kind
    def f_say(self, v):
        self._text('Text', v, lambda val: self._emit('say', val))
        self._combo('Box', [('where the game puts it', 'auto'), ('at the top', 'top'),
                            ('at the bottom', 'bottom')], self.step.get('box', 'auto'),
                    lambda b: self._emit('box', b))

    def f_ask(self, v):
        self._text('Question', v, lambda val: self._emit('ask', val),
                   'The last box is the question; YES / NO opens below it. The steps under '
                   '“If YES” / “If NO” in the list run for each answer, then both go on.')

    def f_if(self, v):
        terms = v or []
        on_ = [t['flag'] for t in terms if t.get('is', 'set') == 'set']
        off = [t['flag'] for t in terms if t.get('is') == 'clear']

        def upd(a, b):
            self._emit('if', [{'flag': f, 'is': 'set'} for f in a] +
                       [{'flag': f, 'is': 'clear'} for f in b])
        self._flags_list('All ON', on_, lambda a: upd(a, [t['flag'] for t in (self.step['if'] or [])
                                                          if t.get('is') == 'clear']))
        self._flags_list('All OFF', off, lambda b: upd([t['flag'] for t in (self.step['if'] or [])
                                                        if t.get('is', 'set') == 'set'], b))

    def f_set(self, v):
        self._flags_list('Flags', v if isinstance(v, list) else [v], lambda a: self._emit('set', a))

    def f_clear(self, v):
        self._flags_list('Flags', v if isinstance(v, list) else [v], lambda a: self._emit('clear', a))

    def _upd(self, k, key, val):
        d = dict(self.step[k] or {})
        if val is None:
            d.pop(key, None)
        else:
            d[key] = val
        self._emit(k, d)

    def f_walk(self, v):
        cb = self._actor_box(v.get('actor'))
        cb.currentIndexChanged.connect(lambda _i: self._upd('walk', 'actor', cb.currentData()))
        self.form.addRow('Who', cb)
        to = v.get('to') or [0, 0]
        self._cell_row('To', to[0], to[1], lambda c: self._upd('walk', 'to', c))
        self._combo('Path', [('left / right first, then up / down', 'x'),
                             ('up / down first, then left / right', 'y')], v.get('first', 'x'),
                    lambda f: self._upd('walk', 'first', f))
        self._check('the next step starts at once (walk together with it)', v.get('together'),
                    lambda b: self._upd('walk', 'together', bool(b) or None))
        self._check('run (double speed)', v.get('fast'), lambda b: self._upd('walk', 'fast', bool(b) or None))
        self._check('keep facing (walk backwards)', v.get('keep_facing'),
                    lambda b: self._upd('walk', 'keep_facing', bool(b) or None))

    def f_face(self, v):
        cb = self._actor_box(v.get('actor'))
        cb.currentIndexChanged.connect(lambda _i: self._upd('face', 'actor', cb.currentData()))
        self.form.addRow('Who', cb)
        items = [(d, d) for d in ('down', 'left', 'up', 'right')]
        items += [(f'toward {"the player" if n == CB.PLAYER else n}', 'toward:' + n)
                  for n, _k, _e in self.ed.actor_list()]
        items += [(f'toward {lbl}', 'toward:' + tok) for lbl, tok in self.ed.unnamed_choices()]
        cur = ('toward:' + v['toward']) if v.get('toward') else v.get('dir', 'down')

        def set_(d):
            nd = {'actor': self.step['face'].get('actor')}
            if str(d).startswith('toward:'):
                nd['toward'] = d.split(':', 1)[1]
            else:
                nd['dir'] = d
            self._emit('face', nd)
        self._combo('Faces', items, cur, set_)

    def f_show(self, v, k='show'):
        cb = self._actor_box(v.get('actor'))
        cb.currentIndexChanged.connect(lambda _i: self._upd(k, 'actor', cb.currentData()))
        self.form.addRow('Who', cb)
        hows = [('instantly', 'instant'), ('flickering (about 4 seconds)', 'flicker')]
        if k == 'show':
            hows.append(('spinning', 'spin'))
        self._combo('How', hows, v.get('how', 'instant'), lambda h: self._upd(k, 'how', h))
        if k == 'show':
            at = v.get('at')
            c = self._check('somewhere else than its own tile', at is not None,
                            lambda b: self._upd('show', 'at', ([3, 3] if b else None)))
            if at is not None:
                self._cell_row('At the tile', at[0], at[1], lambda c2: self._upd('show', 'at', c2), 'at')
            del c

    def f_hide(self, v):
        self.f_show(v, 'hide')

    def f_anim(self, v):
        cb = self._actor_box(v.get('actor'))
        cb.currentIndexChanged.connect(lambda _i: self._upd('anim', 'actor', cb.currentData()))
        self.form.addRow('Who', cb)
        player = v.get('actor') == CB.PLAYER
        items = [(lbl, k) for k, (npc, pl, lbl) in CB.ANIMS.items()
                 if (pl if player else npc) is not None]
        self._combo('Move', items, v.get('move', 'hop'), lambda m: self._upd('anim', 'move', m))
        self._check('the next step starts at once', v.get('together'),
                    lambda b: self._upd('anim', 'together', bool(b) or None))

    def f_fly(self, v):
        cb = self._actor_box(v.get('actor'), player=False)
        cb.currentIndexChanged.connect(lambda _i: self._upd('fly', 'actor', cb.currentData()))
        self.form.addRow('Who', cb)
        self._combo('Flight', [(CB.FLY_NAMES[k], k) for k in CB.FLY], v.get('dir', 'in_right'),
                    lambda d: self._upd('fly', 'dir', d))
        if str(v.get('dir', 'in_right')).startswith('in'):
            to = v.get('to') or [4, 4]
            self._cell_row('Lands on', to[0], to[1], lambda c: self._upd('fly', 'to', c))
        self._spin('Length', 1, 9, v.get('length', 3), lambda n: self._upd('fly', 'length', n),
                   ' tiles across')
        self._spin('Curve', 0, 5, v.get('curve', 3), lambda n: self._upd('fly', 'curve', n))
        self._check('the next step starts at once', v.get('together'),
                    lambda b: self._upd('fly', 'together', bool(b) or None))

    def f_wait(self, v):
        fr = v.get('frames', 30) if isinstance(v, dict) else v
        self._spin('Wait', 1, 6000, fr, lambda n: self._emit('wait', {'frames': n}),
                   ' frames (60 = 1 s)')

    def f_wait_walks(self, v):
        self.form.addRow(QLabel('Waits until every walk / jump / flight started with “the next '
                                'step starts at once” has finished.'))

    def f_music(self, v):
        items = [('back to the room\'s own song', 'back')] + self.ed.song_items()
        cur = 'back' if v == 'back' else (v.get('song') if isinstance(v, dict) else v)
        try:
            from editor2.core import formats as F
            cur = cur if cur == 'back' else f'0x{F.val(cur):02X}'
        except Exception:                                # noqa: BLE001
            pass
        self._combo('Song', items, cur, lambda s: self._emit('music', 'back' if s == 'back'
                                                               else {'song': s}))

    def f_sound(self, v):
        cur = v.get('id') if isinstance(v, dict) else v
        try:
            from editor2.core import formats as F
            cur = f'0x{F.val(cur):02X}'
        except Exception:                                # noqa: BLE001
            pass
        cb = self._combo('Sound', self.ed.sound_items(), cur, lambda s: self._emit('sound', s))
        b = QPushButton('▶ Hear it')
        b.clicked.connect(lambda: self.ed.hear(cb.currentData(), 'se'))
        self.form.addRow('', b)

    def f_shake(self, v):
        self._combo('Direction', [('up and down + left and right', 'both'),
                                  ('up and down', 'up_down'), ('left and right', 'left_right')],
                    v.get('dir', 'both'), lambda d: self._upd('shake', 'dir', d))
        self._spin('For', 1, 255, v.get('frames', 30), lambda n: self._upd('shake', 'frames', n),
                   ' frames')
        self._check('the scene waits while it shakes', v.get('wait', True),
                    lambda b: self._upd('shake', 'wait', bool(b)))

    def f_fade(self, v):
        self._combo('Fade', [('to black', 'black'), ('back in from black', 'normal')],
                    v.get('to', 'black'), lambda t: self._upd('fade', 'to', t))
        self._spin('Each step', 1, 255, v.get('step', 16), lambda n: self._upd('fade', 'step', n),
                   ' frames (3 steps)')

    def f_flash(self, v):
        fr = v.get('frames', 8) if isinstance(v, dict) else v
        self._spin('Flash', 1, 255, fr, lambda n: self._emit('flash', {'frames': n}), ' frames')
        self.form.addRow(QLabel('The screen turns to each palette\'s first colour (white in the '
                                'game\'s own rooms; in rooms with your own colours: their first '
                                'colours — measured S119).'))

    def f_followers(self, v):
        self._combo('The monsters following the player', [('hide them', 'hide'),
                                                          ('show them again', 'show')],
                    v, lambda x: self._emit('followers', x))

    def f_give_item(self, v, k='give_item'):
        if k == 'give_item':
            self._combo('Item', self.ed.item_items(), v.get('item'), lambda i: self._upd(k, 'item', i))
        else:
            self._combo('Monster', self.ed.enemy_items(), v.get('enemy'), lambda e: self._upd(k, 'enemy', e))
        self._text('Then say', v.get('got') or {'boxes': [['']]},
                   lambda t: self._upd(k, 'got', t if _text_from_boxes(t).strip(' …') else None))
        self._text('When it is full', v.get('full') or {'boxes': [['']]},
                   lambda t: self._upd(k, 'full', t if _text_from_boxes(t).strip(' …') else None),
                   'The game gives nothing when the bag (20 items) / the monster farm is full.')

    def f_give_monster(self, v):
        self.f_give_item(v, 'give_monster')

    def f_tiles(self, v):
        self._cell_row('Top-left tile', v.get('x', 0), v.get('y', 0),
                       lambda c: self._emit('tiles', dict(self.step['tiles'], x=c[0], y=c[1])), 'tiles_at')
        self._spin('Width', 1, 10, v.get('w', 1), lambda n: self._upd('tiles', 'w', n), ' tiles')
        self._spin('Height', 1, 8, v.get('h', 1), lambda n: self._upd('tiles', 'h', n), ' tiles')
        cp = v.get('copy') or {}
        items = self.ed.state_items()
        cur = f"{cp.get('screen', self.ed.screen)}:{cp.get('state', 0)}" if cp else None
        self._combo('Look like', items, cur,
                    lambda d: self._upd('tiles', 'copy', {'screen': int(d.split(':')[0]),
                                                          'state': int(d.split(':')[1])}))
        if v.get('rows') and not cp:
            self.form.addRow(QLabel('(this step carries its own tiles)'))
        self.form.addRow(QLabel('The piece of the screen at that place takes the look it has in '
                                'the chosen screen / room state (paint the open door, the '
                                'cleared floor … there in the Rooms tab). Until the room is '
                                'loaded again — for a lasting change use the room\'s state '
                                'rules.'))

    def f_battle(self, v):
        ens = list((v or {}).get('enemies') or [])
        items = self.ed.enemy_items()
        for i in range(3):
            cur = ens[i] if i < len(ens) else None

            def set_(e, i=i):
                cur_l = list((self.step['battle'] or {}).get('enemies') or [])
                while len(cur_l) <= i:
                    cur_l.append(None)
                cur_l[i] = e
                self._emit('battle', {'enemies': [x for x in cur_l if x is not None]})
            self._combo(f'Enemy {i + 1}', ([('—', None)] if i else []) + items, cur, set_)
        self.form.addRow(QLabel('The steps after a battle run only when the player WINS.'))

    def f_move(self, v):
        def to_room(d):
            mv = dict(self.step['move'] or {})
            mv['dest'] = d
            scr = dest_screens(self.ed.s, d)
            if scr and int(mv.get('screen', 0)) not in scr:
                mv['screen'] = scr[0]        # S121 r3: never keep a screen the room lacks
            self._emit('move', mv)
        self._combo('To room', self.ed.room_items(), v.get('dest'), to_room)
        scr = dest_screens(self.ed.s, v.get('dest'))
        cur = int(v.get('screen', 0))
        if scr:
            items = [(screen_label(k), k) for k in scr]
            if cur not in scr:
                items.append((f'screen {cur} — NOT IN THIS ROOM (the build stops)', cur))
            self._combo('Screen', items, cur, lambda n: self._upd('move', 'screen', n))
        else:
            self._spin('Screen', 0, 15, cur, lambda n: self._upd('move', 'screen', n))
        self._spin('x', 0, 9, v.get('x', 4), lambda n: self._upd('move', 'x', n))
        self._spin('y', 0, 7, v.get('y', 4), lambda n: self._upd('move', 'y', n))

    def f_end(self, v):
        self.form.addRow(QLabel('The scene stops here (an entry scene then runs the room\'s own '
                                'arrival script).'))

    def f_name_hero(self, v):
        lab = QLabel('The naming screen opens here; the scene goes on when the player has '
                     'confirmed a name. Nothing to set — the screen offers the hero\'s '
                     'current name.')
        lab.setWordWrap(True)
        self.form.addRow(lab)


# ---------------------------------------------------------------- the editor

def get_at(steps, path):
    """The step at a path ((i,), (i, 'yes', j) …) — None if gone."""
    cur = steps
    st = None
    for k in path:
        if isinstance(k, int):
            if not isinstance(cur, list) or not 0 <= k < len(cur):
                return None
            st = cur[k]
        else:
            cur = (st or {}).get(k)
            if cur is None:
                return None
    return st


def list_at(steps, path):
    """The list holding the step at path, and its index."""
    cur = steps
    for k in path[:-1]:
        if isinstance(k, int):
            st = cur[k]
        else:
            cur = st.setdefault(k, [])
    return cur, path[-1]


def room_items(session):
    """[(label, dest)] for a `move` step: the Castle throne room, the project's rooms,
    then every game room (S121: the roots room's scene leads to GreatTree)."""
    out = [('the Castle throne room', 'vanilla:$00')]
    for r in session.doc.rooms:
        if not r.get('placeholder'):
            out.append((f"{r.get('name') or r['id']} (your room)", f"room:{r['mapID'].replace('0x', '$')}"))
    try:
        for mid, name, _scr in session.renderer.vanilla_rooms():
            if mid != 0x00:
                out.append((f'${mid:02X} {name} (game room)', f'vanilla:${mid:02X}'))
    except Exception:                                   # noqa: BLE001 (no ROM)
        pass
    return out


def dest_screens(session, dest):
    """The screens a `move` destination has ([ints]; [] = unknown) — S121 r3: a move to
    a screen the room does not have crashes the game (the build now refuses it)."""
    from editor2.core import formats as F
    from editor2.core.project import vanilla_screens
    kind, _sep, num = str(dest or '').partition(':')
    try:
        mid = F.val(num)
    except (TypeError, ValueError):
        return []
    if kind == 'room':
        for r in session.doc.rooms:
            if r.get('mapID') is not None and F.val(r['mapID']) == mid:
                return sorted(int(k) for k in (r.get('screens') or {}))
        return []
    return list(vanilla_screens().get(mid) or [])


def screen_label(k):
    return f'screen {k}  (col {k % 4}, row {k // 4})'


def default_step(kind, ed):
    first_npc = next((n for n, k, _e in ed.actor_list() if k), CB.PLAYER)
    return {
        'say': {'say': {'boxes': [['…']]}},
        'ask': {'ask': {'boxes': [['Yes or no?']]}, 'yes': [], 'no': []},
        'if': {'if': [], 'then': [], 'else': []},
        'set': {'set': []}, 'clear': {'clear': []},
        'walk': {'walk': {'actor': first_npc, 'to': [4, 4]}},
        'face': {'face': {'actor': first_npc, 'dir': 'down'}},
        'show': {'show': {'actor': first_npc, 'how': 'instant'}},
        'hide': {'hide': {'actor': first_npc, 'how': 'instant'}},
        'anim': {'anim': {'actor': first_npc, 'move': 'hop'}},
        'fly': {'fly': {'actor': first_npc if first_npc != CB.PLAYER else '', 'dir': 'in_right',
                        'to': [4, 4], 'length': 3, 'curve': 3}},
        'wait': {'wait': {'frames': 30}}, 'wait_walks': {'wait_walks': True},
        'music': {'music': {'song': '0x09'}}, 'sound': {'sound': '0x60'},
        'shake': {'shake': {'dir': 'both', 'frames': 30, 'wait': True}},
        'fade': {'fade': {'to': 'black', 'step': 16}}, 'flash': {'flash': {'frames': 8}},
        'followers': {'followers': 'hide'},
        'give_item': {'give_item': {'item': 1}},
        'give_monster': {'give_monster': {'enemy': 1}},
        'tiles': {'tiles': {'x': 4, 'y': 3, 'w': 1, 'h': 1,
                            'copy': {'screen': ed.screen, 'state': 0}}},
        'battle': {'battle': {'enemies': [1]}},
        'move': {'move': {'dest': 'vanilla:$00', 'screen': 1, 'x': 4, 'y': 5}},
        'end': {'end': True},
        'name_hero': {'name_hero': True},
    }[kind]


class CutsceneEditor(QWidget):
    """Edits one cutscene of the project (room id + scene id)."""
    playRequested = Signal(str)            # scene id
    closed = Signal()

    def __init__(self, session):
        super().__init__()
        self.s = session
        self.room_id = self.scene_id = None
        self.scene = None
        self.path = None                   # the selected step's path
        self.lw = None                     # the last analysis
        self.state_view = 0                # which room state the picture shows
        self._busy = False
        self.anim_t = None
        self.timer = QTimer(self)
        self.timer.setInterval(16)
        self.timer.timeout.connect(self._tick)
        self._build()
        self._header_tips()
        self.s.structureChanged.connect(self._reload)

    def _header_tips(self):
        """S119b: hover text on the header controls (those without one)."""
        tips = {
            'name': 'The scene\'s name (only for you — the game does not show it).',
            'trig': 'What starts the scene: arriving on this screen, talking to an NPC, pressing '
                    'A in front of a tile, or walking onto a tile.',
            'trig_actor': 'The NPC to talk to. NPCs without a name are listed at the end — '
                          'picking one names it.',
            'trig_x': 'The tile across (0-9).', 'trig_y': 'The tile down (0-7).',
            'trig_pick': 'Then click the tile on the room picture.',
            'flags_btn': 'Play the scene only when these flags are ON (and those OFF) — e.g. '
                         'a second scene after the first one set a flag.',
            'ps_x': 'Where the player stands when an entry scene starts (the door / exit '
                    'that leads here) — his walks are counted from there.',
            'ps_y': 'Where the player stands when an entry scene starts.',
            'ps_face': 'Which way the player looks when the scene starts.',
            'ps_pick': 'Then click the tile on the room picture.',
            'state_box': 'Which state of the room the picture shows (rooms with states).',
            'slider': 'Drag to see any moment of the preview.',
            'tree': 'The scene\'s steps, in order. Hover a step for what it does; drag '
                    'actors on the picture to add walks.',
        }
        for attr, tip in tips.items():
            w = getattr(self, attr, None)
            if w is not None and not w.toolTip():
                w.setToolTip(tip)
        for i, (k, _l) in enumerate(TRIGGER_LABELS):
            j = self.trig.findData(k)
            if j >= 0:
                self.trig.setItemData(j, {
                    'entry': 'Plays when the player arrives on this screen (a door, a warp, '
                             'or walking in from the next screen).',
                    'talk': 'Plays when the player talks to the chosen NPC (A facing him). '
                            'Afterwards the NPC does what he always does.',
                    'examine': 'Plays when the player presses A facing the chosen tile.',
                    'stepon': 'Plays when the player walks onto the chosen tile.'}[k],
                    Qt.ToolTipRole)

    # -------------------------------------------------------------- layout
    def _build(self):
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        # header: name + trigger
        h1 = QHBoxLayout()
        self.name = QLineEdit()
        self.name.setPlaceholderText('Name of the scene')
        self.name.editingFinished.connect(self._name_done)
        h1.addWidget(QLabel('Cutscene'))
        h1.addWidget(self.name, 1)
        self.where = QLabel('')
        self.where.setStyleSheet('color:#9ab;')
        h1.addWidget(self.where)
        b = QPushButton('Duplicate')
        b.clicked.connect(self._duplicate)
        h1.addWidget(b)
        b = QPushButton('Delete…')
        b.clicked.connect(self._delete)
        h1.addWidget(b)
        v.addLayout(h1)
        h2 = QHBoxLayout()
        h2.addWidget(QLabel('Plays when'))
        self.trig = QComboBox()
        for k, lbl in TRIGGER_LABELS:
            self.trig.addItem(lbl, k)
        self.trig.currentIndexChanged.connect(self._trigger_changed)
        h2.addWidget(self.trig)
        self.trig_actor = QComboBox()
        self.trig_actor.currentIndexChanged.connect(self._trigger_changed)
        h2.addWidget(self.trig_actor)
        self.trig_x, self.trig_y = QSpinBox(), QSpinBox()
        self.trig_x.setKeyboardTracking(False)
        self.trig_y.setKeyboardTracking(False)
        self.trig_x.setRange(0, 9)
        self.trig_y.setRange(0, 7)
        for sp in (self.trig_x, self.trig_y):
            sp.valueChanged.connect(self._trigger_changed)
            h2.addWidget(sp)
        self.trig_pick = QPushButton('Pick tile')
        self.trig_pick.clicked.connect(lambda: self._start_pick('trigger'))
        h2.addWidget(self.trig_pick)
        self.flags_btn = QToolButton()
        self.flags_btn.setText('Only when flags… ▾')
        self.flags_btn.setPopupMode(QToolButton.InstantPopup)
        self.flags_btn.clicked.connect(self._flags_menu)
        h2.addWidget(self.flags_btn)
        self.once = QCheckBox('Plays once')
        self.once.setToolTip('A flag of its own is turned ON when the scene starts; the scene '
                             'does not play again (saved with the game).')
        self.once.toggled.connect(self._once_toggled)
        h2.addWidget(self.once)
        h2.addStretch(1)
        v.addLayout(h2)
        h3 = QHBoxLayout()
        self.start_lbl = QLabel('Player starts at')
        h3.addWidget(self.start_lbl)
        self.ps_x, self.ps_y = QSpinBox(), QSpinBox()
        self.ps_x.setKeyboardTracking(False)
        self.ps_y.setKeyboardTracking(False)
        self.ps_x.setRange(0, 9)
        self.ps_y.setRange(0, 7)
        self.ps_face = QComboBox()
        self.ps_face.addItems(DIRS)
        for wdg in (self.ps_x, self.ps_y):
            wdg.valueChanged.connect(self._player_start_changed)
            h3.addWidget(wdg)
        self.ps_face.currentIndexChanged.connect(self._player_start_changed)
        h3.addWidget(self.ps_face)
        self.ps_pick = QPushButton('Pick tile')
        self.ps_pick.clicked.connect(lambda: self._start_pick('player'))
        h3.addWidget(self.ps_pick)
        self.ps_note = QLabel('')
        self.ps_note.setStyleSheet('color:#9ab;')
        self.ps_note.setWordWrap(True)
        h3.addWidget(self.ps_note, 1)
        v.addLayout(h3)
        # body: steps | stage | form
        split = QSplitter(Qt.Horizontal)
        v.addWidget(split, 1)
        left = QWidget()
        lv = QVBoxLayout(left)
        lv.setContentsMargins(0, 0, 0, 0)
        tb = QHBoxLayout()
        self.add_btn = QToolButton()
        self.add_btn.setText('＋ Add step ▾')
        self.add_btn.setPopupMode(QToolButton.InstantPopup)
        menu = QMenu(self.add_btn)
        menu.setToolTipsVisible(True)
        for grp, kinds in ADD_GROUPS:
            sub = menu.addMenu(grp)
            sub.setToolTipsVisible(True)
            for k in kinds:
                a = sub.addAction(CB.STEP_NAMES[k])
                a.setToolTip(STEP_HELP.get(k, ''))
                a.triggered.connect(lambda _c=False, k=k: self.add_step(k))
        self.add_btn.setMenu(menu)
        tb.addWidget(self.add_btn)
        for txt, fn, tip in (('▲', lambda: self.move_step(-1), 'Move up'),
                             ('▼', lambda: self.move_step(1), 'Move down'),
                             ('⧉', self.dup_step, 'Duplicate the step'),
                             ('✕', self.remove_step, 'Remove the step')):
            bb = QToolButton()
            bb.setText(txt)
            bb.setToolTip(tip)
            bb.clicked.connect(fn)
            tb.addWidget(bb)
        tb.addStretch(1)
        lv.addLayout(tb)
        self.tree = QTreeWidget()
        self.tree.setHeaderHidden(True)
        self.tree.setSelectionMode(QAbstractItemView.SingleSelection)
        self.tree.currentItemChanged.connect(self._picked)
        lv.addWidget(self.tree, 1)
        cast = QHBoxLayout()
        b = QPushButton('＋ Cast member…')
        b.setToolTip('An NPC that is hidden until the scene shows it (it appears out of '
                     'nowhere). Click a tile on the picture first, or it is put at (4, 4).')
        b.clicked.connect(lambda: self.add_cast())
        cast.addWidget(b)
        b = QPushButton('Name an NPC…')
        b.setToolTip('Scenes refer to NPCs by name — right-click an NPC on the picture too')
        b.clicked.connect(lambda: self.name_npc())
        cast.addWidget(b)
        lv.addLayout(cast)
        split.addWidget(left)
        mid = QWidget()
        mv = QVBoxLayout(mid)
        mv.setContentsMargins(0, 0, 0, 0)
        sh = QHBoxLayout()
        sh.addWidget(QLabel('Room state shown'))
        self.state_box = QComboBox()
        self.state_box.currentIndexChanged.connect(self._state_view_changed)
        sh.addWidget(self.state_box)
        sh.addStretch(1)
        mv.addLayout(sh)
        self.stage = Stage()
        self.stage.actorDragged.connect(self._dragged)
        self.stage.actorPicked.connect(self._actor_picked)
        self.stage.menuAt.connect(self._stage_menu)
        self.stage.cellPicked.connect(self._cell_picked)
        mv.addWidget(self.stage, 0, Qt.AlignHCenter)
        pv = QHBoxLayout()
        self.b_prev = QPushButton('▶ Preview')
        self.b_prev.setToolTip('Plays the scene on the picture from the editor\'s model (instant, '
                               'no build; times measured in the game — ▶ Play in the game for '
                               'the real thing)')
        self.b_prev.clicked.connect(self.preview)
        pv.addWidget(self.b_prev)
        self.answer = QComboBox()
        self.answer.addItems(['answer YES / flags ON', 'answer NO / flags OFF'])
        self.answer.setToolTip('Which way the preview takes at YES/NO and “If flags”')
        pv.addWidget(self.answer)
        self.slider = QSlider(Qt.Horizontal)
        self.slider.setRange(0, 100)
        self.slider.sliderMoved.connect(self._scrub)
        pv.addWidget(self.slider, 1)
        self.t_lbl = QLabel('')
        pv.addWidget(self.t_lbl)
        mv.addLayout(pv)
        self.b_play = QPushButton('▶ Play in the game (build first)')
        self.b_play.setToolTip('Saves, builds and plays the scene in the real game (Playback '
                               'window, set up for you)')
        self.b_play.clicked.connect(lambda: (self.form.flush(),
                                             self.playRequested.emit(self.scene_id or '')))
        mv.addWidget(self.b_play)
        self.problems = QLabel('')
        self.problems.setWordWrap(True)
        self.problems.setTextFormat(Qt.RichText)
        mv.addWidget(self.problems)
        mv.addStretch(1)
        split.addWidget(mid)
        self.form = StepForm(self)
        self.form.changed.connect(self._form_changed)
        self.form.pickCell.connect(self._start_pick)
        sc = QScrollArea()
        sc.setWidgetResizable(True)
        sc.setWidget(self.form)
        sc.setMinimumWidth(440)          # S119b: room for the 320-px game text box
        split.addWidget(sc)
        split.setStretchFactor(0, 1)
        split.setStretchFactor(1, 0)
        split.setStretchFactor(2, 1)
        self._pick = None

    # -------------------------------------------------------------- data
    def open(self, room_id, scene_id):
        self.room_id, self.scene_id = room_id, scene_id
        self.path = None
        self.state_view = 0
        self._reload()

    def room(self):
        return self.s.doc.room(self.room_id)

    @property
    def screen(self):
        return int((self.scene or {}).get('screen', 0))

    def _reload(self):
        if self.scene_id is None:
            return
        try:
            r, sc = CD.find(self.s.doc, self.scene_id)
        except KeyError:
            self.scene = None
            self.closed.emit()
            return
        self.room_id = r['id']
        self.scene = copy.deepcopy(sc)
        self._busy = True
        self.name.setText(sc.get('name') or sc['id'])
        self.where.setText(f"{r.get('name') or r['id']} · screen {self.screen} · id {sc['id']}")
        tr = sc.get('trigger') or {}
        self.trig.setCurrentIndex(max(0, self.trig.findData(tr.get('on', 'entry'))))
        self.trig_actor.clear()
        for name, n, e in self.actor_list():
            if name != CB.PLAYER:
                self.trig_actor.addItem(f'{name} (NPC {n})', name)
        for lbl, tok in self.unnamed_choices():
            self.trig_actor.addItem(lbl, tok)
        self.trig_actor.setCurrentIndex(max(0, self.trig_actor.findData(tr.get('actor'))))
        self.trig_x.setValue(int(tr.get('x', 0)))
        self.trig_y.setValue(int(tr.get('y', 0)))
        self.once.setChecked(bool(tr.get('once')))
        ps = sc.get('player_start') or {}
        self.ps_x.setValue(int(ps.get('x', 5)))
        self.ps_y.setValue(int(ps.get('y', 4)))
        self.ps_face.setCurrentIndex(CB.DIRS.get(ps.get('face', 'down'), 0))
        self.state_box.clear()
        for k in range(len(CD.screen_states(r, self.screen))):
            self.state_box.addItem(f'state {k}', k)
        self.state_box.setCurrentIndex(min(self.state_view, self.state_box.count() - 1))
        self._busy = False
        self._trigger_widgets()
        self._background()
        self.refresh()

    def _form_context(self):
        """What the step forms' lists are made of (actors, unnamed NPCs, flags,
        rooms): a form is kept only while this is unchanged too."""
        try:
            return ([(n, k) for n, k, _e in self.actor_list()], self.unnamed_choices(),
                    [f.get('name') for f in self.s.doc.flags()],
                    [r.get('id') for r in self.s.doc.rooms])
        except Exception:                                # noqa: BLE001
            return None

    def unnamed_choices(self):
        """[(label, token)] the screen's NPCs without a scene name — picking one
        names it ('Shopkeeper' / 'NPC n'; rename it any time)."""
        if self.scene is None:
            return []
        try:
            rows = CD.unnamed_npcs(self.room(), self.screen)
        except Exception:                                # noqa: BLE001
            return []
        multi = len(CD.screen_states(self.room(), self.screen)) > 1
        out = []
        for k, n, e in rows:
            x, y = CB.entry_cell(e)
            where = f'NPC {n} at ({x}, {y})' + (f', state {k}' if multi else '')
            out.append((f'{where} — no name yet', CD.npc_token(k, n)))
        return out

    def actor_list(self):
        if self.scene is None:
            return []
        try:
            return CD.actors(self.room(), self.screen)
        except Exception:                                # noqa: BLE001
            return [(CB.PLAYER, 0, None)]

    def _background(self):
        try:
            im = self.s.renderer.render_screen(self.room(), str(self.screen), self.state_view)
            from editor2.app.cutscenes_tab import _pil_to_qimage
            pm = QPixmap.fromImage(_pil_to_qimage(im)).scaled(160 * S, 128 * S)
        except Exception:                                # noqa: BLE001
            pm = None
        self.stage.set_background(pm, self.screen)

    def commit(self, label):
        """Write self.scene back (one undo step)."""
        from editor2.app.rooms import commands as C
        sc = copy.deepcopy(self.scene)
        sid, rid, scr = self.scene_id, self.room_id, self.screen
        # an NPC picked that has no scene name yet is named in the same undo step
        cmd = C.SnapshotCommand(self.s, label, lambda doc: CD.set_scene(
            doc, sid, CD.resolve_tokens(doc, rid, scr, sc)))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Cutscene', str(cmd.error))

    _later = None

    def _later_commit(self, label):
        """commit() once the current widget signal has returned (several changes
        in one event-loop turn = one undo step)."""
        if self._later is None:
            QTimer.singleShot(0, self._do_later)
        self._later = label

    def _do_later(self):
        label, self._later = self._later, None
        if label is not None and self.scene is not None:
            self.commit(label)

    def _push(self, label, fn):
        from editor2.app.rooms import commands as C
        cmd = C.SnapshotCommand(self.s, label, fn)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Cutscene', str(cmd.error))
            return None
        return cmd.result

    # -------------------------------------------------------------- the list
    def refresh(self):
        """Re-analyse, re-fill the step list (keeping the selection) and redraw."""
        if self.scene is None:
            return
        errs, warns, self.lw = CD.problems(self.s.doc, self.room(), self.scene)
        self._fill_tree()
        msgs = [f'<span style="color:#ff7070">✖ {e}</span>' for e in errs] + \
               [f'<span style="color:#e8b060">⚠ {w}</span>' for w in warns]
        self.problems.setText('<br>'.join(msgs) if msgs else
                              '<span style="color:#7c7">✔ no problems</span>')
        self._show_selected()

    def _fill_tree(self):
        self.tree.blockSignals(True)
        self.tree.clear()
        info = {tuple(r['path']): r for r in (self.lw.info if self.lw else [])}
        sel_item = None

        def add(parent, steps, path):
            nonlocal sel_item
            for i, st in enumerate(steps or []):
                p = path + (i,)
                k = CB.step_kind(st)
                rec = info.get(p, {})
                txt = CB.describe(st)
                if rec.get('note'):
                    txt += '  — ' + '; '.join(rec['note'])
                it = QTreeWidgetItem([txt])
                it.setToolTip(0, f'{CB.STEP_NAMES.get(k, k)}: {STEP_HELP.get(k, "")}')
                it.setData(0, Qt.UserRole, p)
                it.setForeground(0, QBrush(QColor(KIND_COLOUR.get(k, '#ddd'))))
                (parent.addChild(it) if parent is not None else self.tree.addTopLevelItem(it))
                if p == self.path:
                    sel_item = it
                for key, lbl in (('yes', 'If YES'), ('no', 'If NO'), ('then', 'Then'),
                                 ('else', 'Otherwise')):
                    if k in ('ask', 'if') and ((k == 'ask') == (key in ('yes', 'no'))):
                        br = QTreeWidgetItem([lbl])
                        f = br.font(0)
                        f.setItalic(True)
                        br.setFont(0, f)
                        br.setData(0, Qt.UserRole, p + (key,))
                        it.addChild(br)
                        if p + (key,) == self.path:
                            sel_item = br
                        add(br, st.get(key) or [], p + (key,))
                it.setExpanded(True)
        add(None, self.scene.get('steps') or [], ())
        end = QTreeWidgetItem(['(end of the scene)'])
        end.setData(0, Qt.UserRole, ('end',))
        end.setForeground(0, QBrush(QColor('#777')))
        self.tree.addTopLevelItem(end)
        if self.path == ('end',):
            sel_item = end
        self.tree.blockSignals(False)
        if sel_item is not None:
            self.tree.setCurrentItem(sel_item)

    def _picked(self, item, _prev=None):
        if item is None:
            return
        self.path = tuple(item.data(0, Qt.UserRole) or ())
        self._show_selected()

    def selected_step(self):
        if not self.path or not isinstance(self.path[-1], int):
            return None
        return get_at(self.scene.get('steps') or [], self.path)

    def _show_selected(self):
        st = self.selected_step()
        rec = self._rec(self.path)
        note = '; '.join(rec.get('note') or []) if rec else ''
        ctx = self._form_context()
        if st is not None and getattr(self.form, 'path', None) == self.path \
                and self.form.step == st and self.form.form.rowCount() \
                and getattr(self.form, 'ctx', None) == ctx:
            # S119b: the form already shows exactly this step (the commit of its own
            # edit) — keep its widgets, so the cursor / focus stay where they are
            self.form.note.setText(note)
        else:
            self.form.show_step(st, note, self.path)
            self.form.ctx = ctx
        self.timer.stop()
        self.anim_t = None
        self._draw_static()

    def _rec(self, path):
        if not self.lw or not path:
            return None
        for r in self.lw.info:
            if tuple(r['path']) == tuple(path):
                return r
        return None

    # -------------------------------------------------------------- picture
    def _actor_meta(self):
        """name -> sprite / monster of each actor."""
        out = {}
        for name, n, e in self.actor_list():
            if e is None:
                out[name] = {'sprite': 'player', 'monster': None}
            else:
                out[name] = {'sprite': CB.entry_sprite(e) or 0, 'monster': e.get('monster')}
        return out

    def _draw_static(self):
        """The state AFTER the selected step (the start for the end / branch rows),
        with the step's own movement as arrows."""
        meta = self._actor_meta()
        rec = self._rec(self.path) if self.path and isinstance(self.path[-1], int) else None
        if rec is None and self.path == ('end',) and self.lw and self.lw.info:
            rec = self.lw.info[-1]
        state = rec['state'] if rec else self._start_state()
        acts = {}
        for name, a in state.items():
            if name not in meta:
                continue
            acts[name] = dict(a, **meta[name])
        moves = []
        if rec:
            for mv in rec.get('moves') or []:
                nm = self.lw.names.get(mv['actor'], '')
                moves.append((nm, mv['from'], mv['to'], mv['style'], mv.get('order')))
        self.stage.actors = acts
        self.stage.moves = moves
        st = self.selected_step()
        k = CB.step_kind(st) if st else None
        self.stage.text = _text_from_boxes(st[k]).split('\n\n')[0] if k in ('say', 'ask') else None
        self.stage.patch = None
        if k == 'tiles':
            t = st['tiles']
            self.stage.patch = ((int(t.get('x', 0)), int(t.get('y', 0))),
                                int(t.get('w', 1)), int(t.get('h', 1)))
        if k in ('walk', 'face', 'show', 'hide', 'anim', 'fly'):
            self.stage.selected = (st[k] or {}).get('actor')
        self.stage.effects = {}
        self._others()
        self.stage.update()

    def _others(self):
        """The NPCs nobody has named (right-click one to name it)."""
        out = []
        try:
            for n, e in CD.npc_rows(self.room(), self.screen, self.state_view):
                if e.get('actor') or (e.get('kind') == 'npc' and str(e.get('sprite')).upper() == '0XFF'):
                    continue
                t = CB.entry_type_byte(e)
                out.append((CB.entry_cell(e), (t >> 4) & 3, CB.entry_sprite(e), e.get('monster'),
                            bool(t & 0x40), n))
        except Exception:                                # noqa: BLE001
            pass
        self.stage.others = out

    def _start_state(self):
        if not self.lw:
            return {}
        return {self.lw.names.get(n, ''): a.as_dict() for n, a in self._initial_acts().items()}

    def _initial_acts(self):
        lw0 = CB.Lowerer(CB.Env(), self.room(), dict(self.scene, steps=[]), 'p')
        return lw0.acts

    # -------------------------------------------------------------- preview
    def _path_ok(self, path):
        no = self.answer.currentIndex() == 1
        bad = ('yes', 'then') if no else ('no', 'else')
        return not any(k in bad for k in path if isinstance(k, str))

    def preview(self):
        self.form.flush()
        if self.timer.isActive():
            self.timer.stop()
            self.b_prev.setText('▶ Preview')
            return
        if not self.lw:
            return
        self._recs = [r for r in self.lw.info if self._path_ok(r['path'])]
        self.t_end = max([r['t1'] for r in self._recs] + [1]) + 30
        self.slider.setRange(0, int(self.t_end))
        self.anim_t = 0.0
        self.b_prev.setText('❚❚ Stop')
        self.timer.start()

    def _scrub(self, v):
        if not self.lw:
            return
        self._recs = [r for r in self.lw.info if self._path_ok(r['path'])]
        self.t_end = max([r['t1'] for r in self._recs] + [1]) + 30
        self.anim_t = float(v)
        self._draw_at(self.anim_t)

    def _tick(self):
        if self.anim_t is None:
            self.timer.stop()
            return
        self.anim_t += 1.0
        if self.anim_t > self.t_end:
            self.timer.stop()
            self.b_prev.setText('▶ Preview')
            self._draw_static()
            return
        self.slider.setValue(int(self.anim_t))
        self._draw_at(self.anim_t)

    def _draw_at(self, t):
        """Actors at frame t of the model (linear moves; hops / flights arc)."""
        meta = self._actor_meta()
        names = self.lw.names
        pos = {names.get(n, ''): a.as_dict() for n, a in self._initial_acts().items()}
        text, eff, cur = None, {}, None
        for r in self._recs:
            if r['t0'] <= t:
                cur = r
            for mv in r.get('moves') or []:
                nm = names.get(mv['actor'], '')
                if nm not in pos:
                    continue
                a = pos[nm]
                if t >= mv['t1']:
                    a['x'], a['y'] = mv['to']
                elif t >= mv['t0']:
                    f = (t - mv['t0']) / max(1e-6, mv['t1'] - mv['t0'])
                    (x0, y0), (x1, y1) = mv['from'], mv['to']
                    a['x'] = x0 + (x1 - x0) * f
                    a['y'] = y0 + (y1 - y0) * f
                    if mv['style'] in ('jump', 'fly'):
                        a['y'] -= 16 * 4 * f * (1 - f)
                    if mv['style'] == 'walk':
                        if x1 != x0:
                            a['face'] = 3 if x1 > x0 else 1
                        elif y1 != y0:
                            a['face'] = 0 if y1 > y0 else 2
                        a['step'] = int(t / 8) & 1
                    if mv['style'] in ('appear', 'vanish'):
                        a['shown'] = int(t / 4) & 1 == 0
            k = r['kind']
            if r['t0'] <= t < max(r['t1'], r['t0'] + 1):
                st = get_at(self.scene.get('steps') or [], tuple(r['path']))
                if k in ('say', 'ask') and st:
                    boxes = _text_from_boxes(st[k]).split('\n\n')
                    span = max(1.0, (r['t1'] - r['t0']) / max(1, len(boxes)))
                    text = boxes[min(len(boxes) - 1, int((t - r['t0']) / span))]
                if k == 'shake':
                    eff['shake'] = ((int(t) % 4) - 2, (int(t / 2) % 3) - 1)
                if k == 'fade' and st:
                    f = (t - r['t0']) / max(1, r['t1'] - r['t0'])
                    eff['fade'] = f if (st['fade'] or {}).get('to', 'black') == 'black' else 1 - f
                if k == 'flash':
                    eff['flash'] = True
            if r['t1'] <= t:
                for nm, a in (r.get('state') or {}).items():
                    if nm in pos:
                        moving = any(names.get(m['actor']) == nm and m['t0'] <= t < m['t1']
                                     for rr in self._recs for m in rr.get('moves') or [])
                        if not moving:
                            pos[nm].update(face=a['face'], shown=a['shown'])
                            pos[nm]['x'], pos[nm]['y'] = a['x'], a['y']
                if k == 'fade':
                    st = get_at(self.scene.get('steps') or [], tuple(r['path']))
                    eff['fade_hold'] = 1 if st and (st['fade'] or {}).get('to', 'black') == 'black' else 0
        if 'fade' not in eff and eff.get('fade_hold'):
            eff['fade'] = 1
        self.stage.actors = {nm: dict(a, **meta.get(nm, {})) for nm, a in pos.items() if nm in meta}
        self.stage.moves = []
        self.stage.text = text
        self.stage.effects = eff
        self.stage.update()
        self.t_lbl.setText(f'{t / 60:.1f} s')
        if cur is not None:
            self._highlight(tuple(cur['path']))

    def _highlight(self, path):
        it = self.tree.currentItem()
        if it is not None and tuple(it.data(0, Qt.UserRole) or ()) == path:
            return
        found = self.tree.findItems('*', Qt.MatchWildcard | Qt.MatchRecursive)
        for x in found:
            if tuple(x.data(0, Qt.UserRole) or ()) == path:
                self.tree.blockSignals(True)
                self.tree.setCurrentItem(x)
                self.tree.blockSignals(False)
                break

    # -------------------------------------------------------------- step edits
    def _insert_point(self):
        """(list, index) where a new step goes: after the selection, or into a
        selected branch row, or at the end."""
        steps = self.scene.setdefault('steps', [])
        p = self.path
        if not p or p == ('end',):
            return steps, len(steps)
        if isinstance(p[-1], str):
            parent = get_at(steps, p[:-1])
            lst = parent.setdefault(p[-1], [])
            return lst, len(lst)
        lst, i = list_at(steps, p)
        return lst, i + 1

    def add_step(self, kind, step=None):
        if self.scene is None:
            return
        lst, i = self._insert_point()
        lst.insert(i, step or default_step(kind, self))
        base = self.path if self.path and isinstance(self.path[-1], int) else None
        if base is not None:
            self.path = base[:-1] + (i,)
        elif self.path and isinstance(self.path[-1], str):
            self.path = self.path + (i,)
        else:
            self.path = (i,)
        self.commit(f'Cutscene: add “{CB.STEP_NAMES[kind]}”')

    def remove_step(self):
        st = self.selected_step()
        if st is None:
            return
        lst, i = list_at(self.scene['steps'], self.path)
        lst.pop(i)
        self.path = self.path[:-1] + (max(0, i - 1),) if lst else self.path[:-2] or None
        self.commit('Cutscene: remove a step')

    def dup_step(self):
        st = self.selected_step()
        if st is None:
            return
        lst, i = list_at(self.scene['steps'], self.path)
        lst.insert(i + 1, copy.deepcopy(st))
        self.path = self.path[:-1] + (i + 1,)
        self.commit('Cutscene: duplicate a step')

    def move_step(self, d):
        st = self.selected_step()
        if st is None:
            return
        lst, i = list_at(self.scene['steps'], self.path)
        j = i + d
        if not 0 <= j < len(lst):
            return
        lst[i], lst[j] = lst[j], lst[i]
        self.path = self.path[:-1] + (j,)
        self.commit('Cutscene: move a step')

    def _form_changed(self, payload):
        path, st = payload
        if self.scene is None or not path:
            return
        try:
            lst, i = list_at(self.scene['steps'], path)
            if CB.step_kind(lst[i]) != CB.step_kind(st):
                return                      # the list changed under a late edit
        except (IndexError, KeyError, TypeError):
            return
        lst[i] = st
        self.commit('Cutscene: edit a step')

    # -------------------------------------------------------------- stage actions
    def _dragged(self, name, cx, cy):
        """Drag an actor to a tile: the selected walk of that actor goes there,
        or a new walk is added after the selected step."""
        st = self.selected_step()
        if st is not None and CB.step_kind(st) == 'walk' and st['walk'].get('actor') == name:
            st['walk']['to'] = [cx, cy]
            lst, i = list_at(self.scene['steps'], self.path)
            lst[i] = st
            self.commit(f'Cutscene: {name} walks to ({cx}, {cy})')
            return
        if st is not None and CB.step_kind(st) == 'fly' and st['fly'].get('actor') == name:
            st['fly']['to'] = [cx, cy]
            lst, i = list_at(self.scene['steps'], self.path)
            lst[i] = st
            self.commit(f'Cutscene: {name} lands on ({cx}, {cy})')
            return
        self.add_step('walk', {'walk': {'actor': name, 'to': [cx, cy]}})

    def _actor_picked(self, name):
        self.stage.selected = name
        self.stage.update()

    def _cell_picked(self, cx, cy):
        self._last_cell = (cx, cy)
        if self._pick is None:
            return
        what, self._pick = self._pick, None
        self.stage.pick_mode = False
        self.stage.setCursor(Qt.ArrowCursor)
        if what == 'trigger':
            self.trig_x.setValue(cx)
            self.trig_y.setValue(cy)
        elif what == 'player':
            self.ps_x.setValue(cx)
            self.ps_y.setValue(cy)
        else:
            st = self.selected_step()
            if st is None:
                return
            k = CB.step_kind(st)
            if what == 'tiles_at':
                st['tiles']['x'], st['tiles']['y'] = cx, cy
            elif what == 'at':
                st[k]['at'] = [cx, cy]
            else:
                st[k]['to'] = [cx, cy]
            lst, i = list_at(self.scene['steps'], self.path)
            lst[i] = st
            self.commit('Cutscene: pick a tile')

    def _start_pick(self, what):
        self._pick = what
        self.stage.pick_mode = True
        self.stage.setCursor(Qt.CrossCursor)

    def _stage_menu(self, name, cx, cy, gpos):
        m = QMenu(self)
        if name is not None:
            who = 'the player' if name == CB.PLAYER else name
            m.addAction(f'{who} walks to ({cx}, {cy})…').setEnabled(False)
            sub = m.addMenu(f'{who} faces')
            for d in DIRS:
                sub.addAction(d).triggered.connect(
                    lambda _c=False, d=d: self.add_step('face', {'face': {'actor': name, 'dir': d}}))
            for other, _n, _e in self.actor_list():
                if other != name:
                    sub.addAction(f'toward {"the player" if other == CB.PLAYER else other}').triggered.connect(
                        lambda _c=False, o=other: self.add_step('face', {'face': {'actor': name, 'toward': o}}))
            m.addAction(f'{who} appears').triggered.connect(
                lambda: self.add_step('show', {'show': {'actor': name, 'how': 'instant'}}))
            m.addAction(f'{who} appears (flickering)').triggered.connect(
                lambda: self.add_step('show', {'show': {'actor': name, 'how': 'flicker'}}))
            m.addAction(f'{who} disappears').triggered.connect(
                lambda: self.add_step('hide', {'hide': {'actor': name, 'how': 'instant'}}))
            if name != CB.PLAYER:
                m.addAction(f'{who} disappears (flickering)').triggered.connect(
                    lambda: self.add_step('hide', {'hide': {'actor': name, 'how': 'flicker'}}))
            sub = m.addMenu(f'{who} moves')
            for k, (npc, pl, lbl) in CB.ANIMS.items():
                if (pl if name == CB.PLAYER else npc) is not None:
                    sub.addAction(lbl).triggered.connect(
                        lambda _c=False, k=k: self.add_step('anim', {'anim': {'actor': name, 'move': k}}))
            if name != CB.PLAYER:
                sub = m.addMenu(f'{who} flies')
                for k in CB.FLY:
                    sub.addAction(CB.FLY_NAMES[k]).triggered.connect(
                        lambda _c=False, k=k: self.add_step('fly', {'fly': {
                            'actor': name, 'dir': k, 'to': [cx, cy], 'length': 3, 'curve': 3}}))
            m.addSeparator()
            if name != CB.PLAYER:
                ent = next((e for n, _k, e in self.actor_list() if n == name), None)
                m.addAction(f'Rename “{name}”…').triggered.connect(lambda: self.rename_actor(name))
                if ent is not None and ent.get('cast'):
                    m.addAction(f'Move the cast member to ({cx}, {cy})').triggered.connect(
                        lambda: self._push('Cutscene: move a cast member', lambda doc: CD.move_cast(
                            doc, self.room_id, self.screen, name, cx, cy)))
                    m.addAction(f'Remove the cast member “{name}”').triggered.connect(
                        lambda: self._push('Cutscene: remove a cast member', lambda doc: CD.remove_cast(
                            doc, self.room_id, self.screen, name)))
        else:
            npc = self._unnamed_at(cx, cy)
            if npc is not None:
                m.addAction(f'Name this NPC (NPC {npc})…').triggered.connect(
                    lambda: self.name_npc(npc))
            m.addAction(f'New cast member here ({cx}, {cy})…').triggered.connect(
                lambda: self.add_cast(cx, cy))
            if self.stage.selected:
                nm = self.stage.selected
                m.addAction(f'{"The player" if nm == CB.PLAYER else nm} walks here').triggered.connect(
                    lambda: self._dragged(nm, cx, cy))
            m.addAction(f'Change the tiles here ({cx}, {cy})').triggered.connect(
                lambda: self.add_step('tiles', {'tiles': {'x': cx, 'y': cy, 'w': 1, 'h': 1,
                                                          'copy': {'screen': self.screen, 'state': 0}}}))
        m.exec(gpos)

    def _unnamed_at(self, cx, cy):
        for n, e in CD.npc_rows(self.room(), self.screen, self.state_view):
            if not e.get('actor') and CB.entry_cell(e) == (cx, cy):
                return n
        return None

    def name_npc(self, n=None):
        rows = CD.npc_rows(self.room(), self.screen, self.state_view)
        if n is None:
            items = [f'NPC {k} at ({CB.entry_cell(e)[0]}, {CB.entry_cell(e)[1]})'
                     + (f' — “{e["actor"]}”' if e.get('actor') else '') for k, e in rows]
            if not items:
                QMessageBox.information(self, 'Cutscene', 'This screen state has no NPCs.')
                return
            it, ok = QInputDialog.getItem(self, 'Name an NPC', 'Which NPC?', items, 0, False)
            if not ok:
                return
            n = rows[items.index(it)][0]
        cur = dict(rows).get(n, {}).get('actor', '')
        name, ok = QInputDialog.getText(self, 'Name an NPC', f'Name of NPC {n} (scenes use it):',
                                        text=cur)
        if ok:
            self._push('Cutscene: name an NPC', lambda doc: CD.name_actor(
                doc, self.room_id, self.screen, self.state_view, n, name))

    def rename_actor(self, name):
        rows = CD.npc_rows(self.room(), self.screen, self.state_view)
        n = next((k for k, e in rows if e.get('actor') == name), None)
        if n is None:
            return
        new, ok = QInputDialog.getText(self, 'Rename', 'New name:', text=name)
        if ok and new and new != name:
            self._push('Cutscene: rename an actor', lambda doc: CD.name_actor(
                doc, self.room_id, self.screen, self.state_view, n, new))

    def add_cast(self, cx=None, cy=None):
        if cx is None:
            cx, cy = getattr(self, '_last_cell', (4, 4))
        from editor2.app.rooms.npc_panel import SpritePicker
        dlg = SpritePicker(None, self, monsters=False, project_data=self.s.doc.data)
        if not dlg.exec():
            return
        spr = dlg.value
        if not isinstance(spr, int):
            return
        name, ok = QInputDialog.getText(self, 'Cast member', 'Name (scenes use it):')
        if not ok or not name.strip():
            return
        self._push('Cutscene: add a cast member', lambda doc: CD.add_cast(
            doc, self.room_id, self.screen, name.strip(), spr, cx, cy))

    def new_flag(self):
        name, ok = QInputDialog.getText(self, 'New flag', 'Flag name:')
        if ok and name.strip():
            self._push('New flag', lambda doc: doc.add_flag(name.strip()))
            self._show_selected()

    # -------------------------------------------------------------- header edits
    def _name_done(self):
        if self.scene is None or self._busy:
            return
        if self.name.text().strip() and self.name.text() != self.scene.get('name'):
            self.scene['name'] = self.name.text().strip()
            self.commit('Cutscene: rename')

    def _trigger_widgets(self):
        on = self.trig.currentData()
        self.trig_actor.setVisible(on == 'talk')
        for w in (self.trig_x, self.trig_y, self.trig_pick):
            w.setVisible(on in ('examine', 'stepon'))
        ent = on == 'entry'
        for w in (self.start_lbl, self.ps_x, self.ps_y, self.ps_face, self.ps_pick):
            w.setVisible(ent)
        known = ent and bool((self.scene or {}).get('player_start'))
        self.ps_note.setText('' if not ent else (
            'the walks of the player are counted from here (where he arrives on this screen)'
            if known else 'unknown — the player\'s walks are exact walks the scene waits for'))
        self.ps_note.setVisible(ent)

    def _trigger_changed(self, *_a):
        if self._busy or self.scene is None:
            return
        tr = dict(self.scene.get('trigger') or {})
        on = self.trig.currentData()
        tr['on'] = on
        for k in ('actor', 'x', 'y', 'facing'):
            tr.pop(k, None)
        if on == 'talk':
            tr['actor'] = self.trig_actor.currentData()
        elif on in ('examine', 'stepon'):
            tr['x'], tr['y'] = self.trig_x.value(), self.trig_y.value()
            if on == 'examine':
                tr['facing'] = 'any'
        self.scene['trigger'] = tr
        self._trigger_widgets()
        # after the combo's signal returns: the reload refills these combos (S119b,
        # the macOS crash of a combo changed inside its own signal)
        self._later_commit('Cutscene: trigger')

    def _player_start_changed(self, *_a):
        if self._busy or self.scene is None:
            return
        self.scene['player_start'] = {'x': self.ps_x.value(), 'y': self.ps_y.value(),
                                      'face': DIRS[self.ps_face.currentIndex()]}
        self._later_commit('Cutscene: where the player starts')

    def _once_toggled(self, on):
        if self._busy or self.scene is None:
            return
        tr = dict(self.scene.get('trigger') or {})
        if on:
            fname = CD._slug(self.scene_id + '_seen')

            def op(doc):
                CD.ensure_flag(doc, fname)
                r, sc = CD.find(doc, self.scene_id)
                sc.setdefault('trigger', {})['once'] = fname
            self._push('Cutscene: plays once', op)
        else:
            tr.pop('once', None)
            self.scene['trigger'] = tr
            self.commit('Cutscene: plays every time')

    def _flags_menu(self):
        if self.scene is None:
            return
        tr = self.scene.get('trigger') or {}
        m = QMenu(self)
        m.addSection('Only when these flags are ON')
        for f in self.s.doc.flags():
            n = f.get('name')
            a = m.addAction(n)
            a.setCheckable(True)
            a.setChecked(n in (tr.get('when_on') or []))
            a.toggled.connect(lambda c, n=n: self._toggle_flag('when_on', n, c))
        m.addSection('… and these OFF')
        for f in self.s.doc.flags():
            n = f.get('name')
            a = m.addAction(n)
            a.setCheckable(True)
            a.setChecked(n in (tr.get('when_off') or []))
            a.toggled.connect(lambda c, n=n: self._toggle_flag('when_off', n, c))
        m.addSeparator()
        m.addAction('New flag…').triggered.connect(self.new_flag)
        m.exec(self.flags_btn.mapToGlobal(QPoint(0, self.flags_btn.height())))

    def _toggle_flag(self, key, name, on):
        tr = dict(self.scene.get('trigger') or {})
        lst = [x for x in tr.get(key) or [] if x != name]
        if on:
            lst.append(name)
        if lst:
            tr[key] = lst
        else:
            tr.pop(key, None)
        self.scene['trigger'] = tr
        self.commit('Cutscene: flag condition')

    def _state_view_changed(self, i):
        if self._busy or i < 0:
            return
        self.state_view = i
        self._background()
        self._draw_static()

    def _duplicate(self):
        sid = self._push('Cutscene: duplicate', lambda doc: CD.duplicate(doc, self.scene_id))
        if sid:
            self.open(self.room_id, sid)

    def _delete(self):
        if QMessageBox.question(self, 'Delete', f'Delete the cutscene “{self.scene.get("name")}”?') \
                != QMessageBox.Yes:
            return
        sid = self.scene_id
        self.scene_id = None
        self._push('Cutscene: delete', lambda doc: CD.delete_cutscene(doc, sid))
        self.closed.emit()

    # -------------------------------------------------------------- lists for the form
    def song_items(self):
        out = []
        for s in self._catalog():
            if s.get('kind') in ('music', 'jingle'):
                where = ', '.join(r.split(' ', 1)[-1] for r in (s.get('rooms') or [])[:2])
                out.append((f"${s['id_int']:02X} {s['kind']}" + (f' — {where}' if where else ''),
                            f"0x{s['id_int']:02X}"))
        for sg in (self.s.doc.custom.get('music') or {}).get('songs') or []:
            if sg.get('id') is not None and sg.get('first_id') is not None:
                out.append((f"your song {sg['id']}", sg['first_id']))
        return out

    def sound_items(self):
        out = []
        for s in self._catalog():
            if s.get('kind') == 'effect':
                used = ', '.join((s.get('scripts') or [])[:1])
                out.append((f"${s['id_int']:02X}" + (f' — used by {used}' if used else ''),
                            f"0x{s['id_int']:02X}"))
        return out

    def _catalog(self):
        if not hasattr(self, '_cat'):
            import json
            try:
                self._cat = json.load(open(os.path.join(REPO, 'extracted', 'sound_catalog.json')))['sounds']
            except Exception:                            # noqa: BLE001
                self._cat = []
        return self._cat

    def hear(self, sid, path):
        try:
            from editor2.core import formats as F
            from editor2.core import music_preview as MP
            from editor2.app.music_tab import SongPlayer
            rom = open(self.s.settings.value('rom/path') or os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
            if not hasattr(self, '_player'):
                self._player = SongPlayer(self)
            self._player.play(MP.Renderer.vanilla(rom, F.val(sid), path))
        except Exception as ex:                          # noqa: BLE001
            QMessageBox.information(self, 'Sound', f'Cannot play it here: {ex}')

    def item_items(self):
        from editor2.core.shops import item_names
        return [(f'{n} ({i})', i) for i, n in sorted(item_names().items())]

    def enemy_items(self):
        from editor2.core.conversation import vanilla_enemies
        out = [(f"{e['id']} (your enemy)", e['id']) for e in
               (self.s.doc.data.get('progression') or {}).get('enemies') or []]
        out += [(f"{e['name']} — row {e['eid']}" + (f" ({e['boss']})" if e.get('boss') else ''), e['eid'])
                for e in vanilla_enemies() if e.get('level')]
        return out

    def room_items(self):
        return room_items(self.s)

    def state_items(self):
        out = []
        r = self.room()
        for k in sorted(int(x) for x in (r.get('screens') or {})):
            for n in range(len(CD.screen_states(r, k))):
                out.append((f'screen {k}, state {n}' + (' (this screen)' if k == self.screen else ''),
                            f'{k}:{n}'))
        return out
