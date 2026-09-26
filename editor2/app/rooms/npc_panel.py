"""npc_panel.py — the NPC inspector (S97, ROADMAP P3.5; EDITOR_DESIGN §5.1).

Everything an NPC entry can say to the engine, as a form:
  * sprite  — picker over the S91 sprite catalog (normal ids first)
  * facing  — bits 4-5 of the type byte
  * behaviour — the per-frame routine (type low nibble, bank $06
    NPCBehaviourTable; ROOM_DATA_FORMAT "NPC behaviour types", measured
    S97); the canvas draws the walk path of the selected NPC
  * hidden  — bit 6: an inactive entry — not drawn, not solid, no
    behaviour, cannot be talked to (vanilla: 250 cutscene/placeholder entries)
  * script  — any script in the room's table, or a new plain talk script
    (per-box editor with the game's own font: talk_editor.py, S97 r2)
  * present in states — the same NPC (sprite + home cell + script) across
    the screen's states
Position: drag the NPC on the canvas (Select tool).
"""

import json
import os

from PySide6.QtCore import QSize, Qt, Signal
from PySide6.QtGui import QIcon
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox,
                               QFormLayout, QGridLayout, QGroupBox, QHBoxLayout,
                               QLabel, QPushButton, QScrollArea,
                               QToolButton, QVBoxLayout, QWidget)

from editor2.app.session import REPO
from editor2.core import formats as F
from editor2.app.rooms.talk_editor import TalkDialog  # noqa: F401 (re-export)

CATALOG = os.path.join(REPO, 'extracted', 'npc_sprite_catalog.json')

# user-facing behaviour vocabulary (order = combo order); descriptions are
# the measured facts (PyBoy S97)
BEHAVIOUR_UI = [
    (0x0, 'Stand — turns to face the player (keeps it)',
     'Stands still. Turns to face the player when talked to and keeps that facing.'),
    (0x7, 'Stand — faces the player, then turns back',
     'Faces the player while talked to, then returns to the facing you set.'),
    (0x6, 'Stand — never turns',
     'Stands still and never turns, even when talked to (still talkable).'),
    (0x1, 'Spin in place',
     'Turns 90° every 16 frames: down, left, up, right.'),
    (0x8, 'Pace ±1 tile (left–right)',
     'Walks 1 tile right, back, 1 tile left, back. Pauses 32 frames per tile.'),
    (0x2, 'Pace ±2 tiles (starts right)',
     'Walks between 2 tiles right and 2 tiles left of home.'),
    (0x9, 'Pace ±2 tiles (starts left)',
     'Walks between 2 tiles left and 2 tiles right of home.'),
    (0x5, 'Pace 3 tiles right and back',
     'Walks from home to 3 tiles right and back.'),
    (0x3, 'Walk a 2×2 square',
     'Down 2, right 2, up 2, left 2.'),
    (0x4, 'Walk a figure 8 (3-tile legs)',
     'Left 3, up 3, left 3, down 3, right 3, up 3, right 3, down 3 — a 7×4 area '
     'to the left of and above home.'),
    (0xA, 'Sway slowly ±1 tile',
     'Slides 1 px every 8 frames between 1 tile right and 1 tile left, never '
     'turning (vanilla: the DeathMore boss).'),
    (0xE, 'Gate wanderer, auto-talks (gate floors only)',
     'Random walk with collision on the gate floor that owns the wanderer. '
     'In a room it stands frozen and unanimated.'),
    (0xF, 'Gate wanderer (gate floors only)',
     'Random walk with collision on gate floors only. In a room it stands frozen.'),
]
def talk_summary(talk, script_id):
    """Preview line for a talk script: `talk` = a talk spec (S98), the S97
    list of boxes, or None (the script does more than the talk form)."""
    if isinstance(talk, dict):
        from editor2.core.talk import TalkMixin
        return TalkMixin.describe_talk(talk)
    if talk:
        return ' ▸ '.join('"' + ' '.join(ln for ln in b if ln) + '"' for b in talk)
    if script_id not in (None, 'none'):
        return '(script does more than talk — edited as a script in a later box, P3.6/P3.8)'
    return ''


WALK_NOTE = ('Walkers never test walls or screen edges — only the player blocks '
             'them (they wait). Keep the dotted path on open floor.')


def load_catalog():
    try:
        d = json.load(open(CATALOG))
        return {int(k, 16): v for k, v in d.get('sprites', {}).items()}
    except Exception:
        return {}


class SpritePicker(QDialog):
    """Grid of NPC sprite ids (S91 catalog crops)."""

    def __init__(self, current=None, parent=None):
        super().__init__(parent)
        from editor2.app.rooms.canvas import SpriteCache
        self.setWindowTitle('NPC sprite')
        self.resize(560, 520)
        self.value = current
        self.cat = load_catalog()
        v = QVBoxLayout(self)
        self.show_all = QCheckBox('show boss fragments / empty / glitch ids too')
        self.show_all.toggled.connect(self._fill)
        v.addWidget(QLabel('Sprite ids from the vanilla census (S91). Each screen has a '
                           'sprite-sheet VRAM budget: many DIFFERENT sprites on one screen '
                           'can render blank — repeats are free.'))
        v.addWidget(self.show_all)
        self.scroll = QScrollArea()
        self.scroll.setWidgetResizable(True)
        v.addWidget(self.scroll, 1)
        self.info = QLabel('')
        v.addWidget(self.info)
        bb = QDialogButtonBox(QDialogButtonBox.Cancel)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._cache = SpriteCache
        self._fill()

    def _fill(self):
        w = QWidget()
        g = QGridLayout(w)
        g.setSpacing(2)
        ids = sorted(self.cat) or list(range(0x60))
        n = 0
        for sid in ids:
            meta = self.cat.get(sid, {})
            cat = meta.get('category', 'normal')
            if not self.show_all.isChecked() and cat != 'normal':
                continue
            b = QToolButton()
            pm = self._cache.get(sid)
            if pm is not None:
                b.setIcon(QIcon(pm.scaled(32, 32)))
                b.setIconSize(QSize(32, 32))
            b.setText(f'${sid:02X}')
            b.setToolButtonStyle(Qt.ToolButtonTextUnderIcon)
            name = meta.get('name') or ''
            b.setToolTip(f'${sid:02X} {name}  [{cat}]')
            if sid == self.value:
                b.setStyleSheet('background: #806010;')
            b.clicked.connect(lambda _c=False, s=sid: self._pick(s))
            g.addWidget(b, n // 8, n % 8)
            n += 1
        self.scroll.setWidget(w)
        self.info.setText(f'{n} ids shown')

    def _pick(self, sid):
        self.value = sid
        self.accept()


class NpcPanel(QGroupBox):
    """Form for one NPC entry; emits edits, the tab turns them into undoable
    Document operations."""
    fieldsEdited = Signal(dict)          # {field: value}
    spriteRequested = Signal()
    newTalkRequested = Signal()
    editTalkRequested = Signal()
    presenceToggled = Signal(int, bool)  # state index, present
    deleteRequested = Signal()
    shownChanged = Signal(bool)          # S97 r2: the NPC section swaps in its hint

    def setVisible(self, on):
        super().setVisible(on)
        self.shownChanged.emit(bool(on))

    def __init__(self, parent=None):
        super().__init__('NPC', parent)
        self._building = False
        self._view = None
        f = QFormLayout(self)
        self.form = f
        f.setLabelAlignment(Qt.AlignRight)
        row = QHBoxLayout()
        self.sprite_btn = QToolButton()
        self.sprite_btn.setIconSize(QSize(32, 32))
        self.sprite_btn.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
        self.sprite_btn.clicked.connect(self.spriteRequested.emit)
        self.sprite_btn.setToolTip('Change the sprite (S91 catalog)')
        row.addWidget(self.sprite_btn)
        row.addStretch(1)
        f.addRow('sprite', row)
        self.pos = QLabel('')
        f.addRow('home cell', self.pos)
        self.facing = QComboBox()
        self.facing.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        for n in F.FACING_NAMES:
            self.facing.addItem(n, n)
        self.facing.currentIndexChanged.connect(lambda _i: self._emit('facing', self.facing.currentData()))
        f.addRow('facing', self.facing)
        self.beh = QComboBox()
        self.beh.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.beh.setMinimumContentsLength(14)
        for v, name, tip in BEHAVIOUR_UI:
            self.beh.addItem(name, v)
            self.beh.setItemData(self.beh.count() - 1, tip, Qt.ToolTipRole)
        self.beh.currentIndexChanged.connect(lambda _i: self._emit('behaviour', self.beh.currentData()))
        f.addRow('behaviour', self.beh)
        self.beh_note = QLabel('')
        self.beh_note.setWordWrap(True)
        self.beh_note.setStyleSheet('color: #aaa;')
        f.addRow('', self.beh_note)
        self.obj = QCheckBox('hidden (inactive entry)')
        self.obj.setToolTip('Type bit 6 (PyBoy-measured S97): the entry exists but is not drawn, '
                            'does not block the player, has no behaviour and cannot be talked to. '
                            'Vanilla uses it on 250 entries (cutscene actors / placeholders).')
        self.obj.toggled.connect(lambda on: self._emit('hidden', bool(on)))
        f.addRow('', self.obj)
        srow = QHBoxLayout()
        self.script = QComboBox()
        self.script.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.script.setMinimumContentsLength(14)
        self.script.currentIndexChanged.connect(self._script_changed)
        srow.addWidget(self.script, 1)
        f.addRow('talk script', srow)
        brow = QHBoxLayout()
        self.btn_new_talk = QPushButton('New talk…')
        self.btn_new_talk.setToolTip('What the NPC says and does: text, an optional YES/NO '
                                     'question, flags to turn on/off, moving the player')
        self.btn_new_talk.clicked.connect(self.newTalkRequested.emit)
        self.btn_edit_talk = QPushButton('Edit talk…')
        self.btn_edit_talk.clicked.connect(self.editTalkRequested.emit)
        brow.addWidget(self.btn_new_talk)
        brow.addWidget(self.btn_edit_talk)
        f.addRow('', brow)
        self.talk_preview = QLabel('')
        self.talk_preview.setWordWrap(True)
        self.talk_preview.setStyleSheet('color: #9fd0ff;')
        f.addRow('', self.talk_preview)
        self.presence_box = QWidget()
        self.presence_lay = QHBoxLayout(self.presence_box)
        self.presence_lay.setContentsMargins(0, 0, 0, 0)
        f.addRow('in states', self.presence_box)
        self.raw_note = QLabel('')
        self.raw_note.setWordWrap(True)
        self.raw_note.setStyleSheet('color: #888;')
        f.addRow(self.raw_note)
        self.btn_del = QPushButton('Delete NPC')
        self.btn_del.clicked.connect(self.deleteRequested.emit)
        f.addRow('', self.btn_del)

    # --------------------------------------------------------------- show
    def show_npc(self, view, script_ids, talk_pages, presence, editable, bytes_hint=''):
        """view = Document.npc_view(...); script_ids = [(index, id)];
        talk_pages = pages of a plain talk script or None; presence =
        [bool per state] or None (single-state screen)."""
        from editor2.app.rooms.canvas import SpriteCache
        self._building = True
        self._view = view
        spr = view.get('sprite', 0)
        cat = load_catalog().get(spr, {})
        pm = SpriteCache.get(spr)
        self.sprite_btn.setIcon(QIcon(pm.scaled(32, 32)) if pm is not None else QIcon())
        self.sprite_btn.setText(f"${spr:02X} {cat.get('name') or ''}".strip())
        self.pos.setText(f"({view['x']},{view['y']})   drag on the canvas to move")
        self.facing.setCurrentIndex(max(0, self.facing.findData(view.get('facing', 'down'))))
        b = int(view.get('behaviour', 0))
        i = self.beh.findData(b)
        if i < 0:                      # B/C/D: aliases of 0 — show them as 0
            i = self.beh.findData(0)
        self.beh.setCurrentIndex(i)
        self._beh_note(b)
        self.obj.setChecked(bool(view.get('hidden')))
        self.script.clear()
        self.script.addItem('(none — cannot be talked to)', None)
        for idx, sid in script_ids:
            if idx == 0:
                continue                # index 0 = room entry, never an NPC's
            self.script.addItem(f'[{idx}] {sid}', sid)
        cur = view.get('script')
        if isinstance(cur, int):
            self.script.addItem(f'[{cur}] raw index (no id)', cur)
        k = self.script.findData(cur) if cur not in (None, 'none') else 0
        self.script.setCurrentIndex(max(0, k))
        self.btn_edit_talk.setEnabled(talk_pages is not None)
        self.talk_preview.setText(talk_summary(talk_pages, cur))
        while self.presence_lay.count():
            w = self.presence_lay.takeAt(0).widget()
            if w:
                w.deleteLater()
        if presence and len(presence) > 1:
            for n, on in enumerate(presence):
                cb = QCheckBox(str(n))
                cb.setChecked(on)
                cb.setToolTip(f'NPC present in state {n} of this screen')
                cb.toggled.connect(lambda v, nn=n: self.presenceToggled.emit(nn, bool(v)))
                self.presence_lay.addWidget(cb)
            self.presence_lay.addStretch(1)
            self.form.setRowVisible(self.presence_box, True)
        else:
            self.form.setRowVisible(self.presence_box, False)
        self.raw_note.setText(('Cloned entry (' + bytes_hint + '): editing a field turns it into '
                               'a typed NPC with the same bytes.') if view.get('raw') else '')
        for w in (self.sprite_btn, self.facing, self.beh, self.obj, self.script,
                  self.btn_new_talk, self.btn_del, self.presence_box):
            w.setEnabled(editable)
        if not editable:
            self.btn_edit_talk.setEnabled(False)
        self._building = False

    def _beh_note(self, b):
        tip = next((t for v, _n, t in BEHAVIOUR_UI if v == b), '')
        if b in F.BEHAVIOUR_PATHS:
            tip += '  ' + WALK_NOTE
        if b in (0xB, 0xC, 0xD):
            tip = f'Type {b:X} = alias of 0 (stand).'
        self.beh_note.setText(tip)

    # ------------------------------------------------------------ emit
    def _emit(self, field, value):
        if self._building or self._view is None:
            return
        if field == 'behaviour':
            self._beh_note(value)
        self.fieldsEdited.emit({field: value})

    def _script_changed(self, _i):
        if self._building:
            return
        self._emit('script', self.script.currentData())
