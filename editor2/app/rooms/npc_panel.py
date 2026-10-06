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
    """Grid of NPC sprite ids (S91 catalog crops) + S101 MONSTERS: any
    species drawn as the game draws its overworld follower (a monster NPC,
    ROOM_DATA_FORMAT "Monster NPCs"). `value` = sprite id (int) or
    ('monster', species)."""

    def __init__(self, current=None, parent=None, monsters=True, project_data=None):
        super().__init__(parent)
        from PySide6.QtWidgets import QLineEdit, QTabWidget
        from editor2.app.rooms.canvas import SpriteCache
        self.setWindowTitle('NPC sprite')
        self.resize(620, 560)
        self.value = current
        self.project_data = project_data      # S105: the project's new species
        self.cat = load_catalog()
        v = QVBoxLayout(self)
        self.tabs = QTabWidget()
        v.addWidget(self.tabs, 1)
        # people & objects
        pw = QWidget()
        pv = QVBoxLayout(pw)
        self.show_all = QCheckBox('show boss fragments / empty / glitch ids too')
        self.show_all.toggled.connect(self._fill)
        pv.addWidget(QLabel('Sprite ids from the vanilla census (S91). Each screen has a '
                            'sprite-sheet VRAM budget: many DIFFERENT sprites on one screen '
                            'can render blank — repeats are free.'))
        pv.addWidget(self.show_all)
        self.scroll = QScrollArea()
        self.scroll.setWidgetResizable(True)
        pv.addWidget(self.scroll, 1)
        self.tabs.addTab(pw, 'People && objects')
        # monsters
        self.mscroll = None
        if monsters:
            mw = QWidget()
            mv = QVBoxLayout(mw)
            ml = QLabel('Any monster as an NPC, drawn like its follower (captured from the '
                        'game). Up to 4 different monsters per screen; repeats are free. '
                        'Diago, Samsi, Bazoo and the last row cannot be shown (they crash '
                        'the game).')
            ml.setWordWrap(True)
            mv.addWidget(ml)
            self.mfilter = QLineEdit()
            self.mfilter.setPlaceholderText('filter by name…')
            self.mfilter.textChanged.connect(self._fill_monsters)
            mv.addWidget(self.mfilter)
            self.mscroll = QScrollArea()
            self.mscroll.setWidgetResizable(True)
            mv.addWidget(self.mscroll, 1)
            self.tabs.addTab(mw, 'Monsters')
        self.info = QLabel('')
        v.addWidget(self.info)
        bb = QDialogButtonBox(QDialogButtonBox.Cancel)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._cache = SpriteCache
        self._fill()
        if monsters:
            self._fill_monsters()
            if isinstance(current, tuple):
                self.tabs.setCurrentIndex(1)

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

    def _fill_monsters(self):
        from editor2.app.rooms.canvas import MonsterCache
        w = QWidget()
        g = QGridLayout(w)
        g.setSpacing(2)
        flt = self.mfilter.text().strip().lower()
        n = 0
        for sp, name in MonsterCache.species(self.project_data):
            if flt and flt not in name.lower():
                continue
            b = QToolButton()
            pm = MonsterCache.get(sp)
            if pm is not None:
                b.setIcon(QIcon(pm.scaled(32, 32)))
                b.setIconSize(QSize(32, 32))
            b.setText(name[:9])
            b.setToolButtonStyle(Qt.ToolButtonTextUnderIcon)
            b.setToolTip(f'{name} (species {sp})')
            if self.value == ('monster', sp):
                b.setStyleSheet('background: #806010;')
            b.clicked.connect(lambda _c=False, s=sp: self._pick(('monster', s)))
            g.addWidget(b, n // 8, n % 8)
            n += 1
        self.mscroll.setWidget(w)

    def _pick(self, sid):
        self.value = sid
        self.accept()


class NpcPanel(QGroupBox):
    """Form for one NPC entry; emits edits, the tab turns them into undoable
    Document operations."""
    fieldsEdited = Signal(dict)          # {field: value}
    spriteRequested = Signal()
    newTalkRequested = Signal()
    newConversationRequested = Signal()  # S101
    shopRequested = Signal()             # S117 (P3.13c): make this NPC a shopkeeper
    serviceRequested = Signal()          # S126 (P3.14e1): make this NPC a service NPC
    shownWhenRequested = Signal()        # S120: flag conditions (NG2 residual b)
    colourEdited = Signal(object)        # S123: OBJ palette 0-7 or None (own colours)
    bossRequested = Signal()             # S123: Make boss…
    nameRequested = Signal()             # S124 r3: Name… (game rooms too — editor data)
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
        self.sprite_btn.setToolTip('Change the sprite (S91 catalog) — or any monster '
                                   '(drawn like its follower, S101)')
        row.addWidget(self.sprite_btn)
        row.addStretch(1)
        f.addRow('sprite', row)
        nrow = QHBoxLayout()                      # S124 r3: YOUR name for this NPC
        self.name_lbl = QLabel('')
        self.name_lbl.setWordWrap(True)
        self.btn_name = QPushButton('Name…')
        self.btn_name.setToolTip('Your name for this NPC (e.g. “King — after class B”): '
                                 'shown on the canvas, in the Progression & Flags tab and '
                                 'in the cutscene storyboards. Works in the original game\'s '
                                 'rooms too (it is only for you, never in the ROM).')
        self.btn_name.clicked.connect(self.nameRequested.emit)
        nrow.addWidget(self.btn_name)
        nrow.addWidget(self.name_lbl, 1)
        f.addRow('name', nrow)
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
        self.btn_new_conv = QPushButton('New conversation…')
        self.btn_new_conv.setToolTip('A conversation tree (S101): text, YES/NO branches, flag '
                                     'checks, flags, a battle of 1-3 enemies, the helper who '
                                     'takes the player away — boss rooms')
        self.btn_new_conv.clicked.connect(self.newConversationRequested.emit)
        self.btn_shop = QPushButton('Shopkeeper…')
        self.btn_shop.setToolTip('S117: this NPC runs a shop — pick which shop (the game\'s '
                                 'five or one of yours, Shops tab) and an optional greeting')
        self.btn_shop.clicked.connect(self.shopRequested.emit)
        self.btn_service = QPushButton('Service…')
        self.btn_service.setToolTip('S126: this NPC is one of the game\'s services — the '
                                    'Vault, a farm keeper, the librarian, the Monster Namer, '
                                    'the Medal Man, the egg appraiser or the gate guide '
                                    '(their menus work in any room)')
        self.btn_service.clicked.connect(self.serviceRequested.emit)
        brow.addWidget(self.btn_new_talk)
        brow.addWidget(self.btn_new_conv)
        brow.addWidget(self.btn_shop)
        brow.addWidget(self.btn_service)
        brow.addWidget(self.btn_edit_talk)
        f.addRow('', brow)
        self.talk_preview = QLabel('')
        self.talk_preview.setWordWrap(True)
        self.talk_preview.setStyleSheet('color: #9fd0ff;')
        f.addRow('', self.talk_preview)
        wrow = QHBoxLayout()
        self.shown_when = QLabel('')
        self.shown_when.setWordWrap(True)
        wrow.addWidget(self.shown_when, 1)
        self.btn_shown = QPushButton('Flags…')
        self.btn_shown.setToolTip('Show this NPC only while flags are ON / OFF (S117 engine: '
                                  'checked whenever the screen loads — a flag set while you '
                                  'are in the room shows / hides it at the next load)')
        self.btn_shown.clicked.connect(self.shownWhenRequested.emit)
        wrow.addWidget(self.btn_shown)
        f.addRow('shown when', wrow)
        # S123: the NPC's colour — any of the game's 8 sprite palettes (bank $60
        # entry 11 NpcColourDraw rewrites the palette bits of its OAM pieces)
        crow = QHBoxLayout()
        self.colour = QComboBox()
        self.colour.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.colour.setToolTip('Draw this NPC in another of the game\'s 8 sprite palettes '
                               '(the swatch = its main colour). "own colours" = the sprite\'s '
                               'usual palette. Not for monster NPCs (they walk in their own '
                               'colours).')
        self._fill_colours(None)
        self.colour.activated.connect(self._colour_changed)
        crow.addWidget(self.colour, 1)
        f.addRow('colour', crow)
        self.colour_note = QLabel('')
        self.colour_note.setWordWrap(True)
        self.colour_note.setStyleSheet('color: #aaa;')
        f.addRow('', self.colour_note)
        self.btn_boss = QPushButton('Make boss…')
        self.btn_boss.setToolTip('S123: turn this NPC into a boss in one go — its words, a '
                                 'battle, its own "beaten" flag, it leaves after the win and '
                                 'stays gone; optionally the END boss of a world (its portal '
                                 'swirl stops / changes colour) and a way out afterwards')
        self.btn_boss.clicked.connect(self.bossRequested.emit)
        f.addRow('', self.btn_boss)
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

    # ------------------------------------------------------------- colours
    OBJ_PAL = None      # [(r, g, b)] colour 2 of the 8 OBJ palettes ($17:$5615), from the ROM

    @classmethod
    def load_obj_palettes(cls, rom):
        try:
            o = 0x17 * 0x4000 + 0x5615 - 0x4000
            out = []
            for p in range(8):
                w = rom[o + p * 8 + 4] | rom[o + p * 8 + 5] << 8
                out.append(((w & 31) * 255 // 31, ((w >> 5) & 31) * 255 // 31,
                            ((w >> 10) & 31) * 255 // 31))
            cls.OBJ_PAL = out
        except Exception:                                    # noqa: BLE001
            cls.OBJ_PAL = None

    def _fill_colours(self, cur):
        from PySide6.QtGui import QColor, QPixmap
        from editor2.core import gates as G
        self.colour.clear()
        self.colour.addItem('own colours', None)
        for p in range(8):
            icon = QIcon()
            if self.OBJ_PAL:
                pm = QPixmap(14, 14)
                pm.fill(QColor(*self.OBJ_PAL[p]))
                icon = QIcon(pm)
            self.colour.addItem(icon, f'palette {p}: {G.OBJ_PALETTE_NAMES[p]}', p)
        self.colour.setCurrentIndex(max(0, self.colour.findData(cur)))

    def _colour_changed(self, _i):
        if self._building or self._view is None:
            return
        self.colourEdited.emit(self.colour.currentData())

    # --------------------------------------------------------------- show
    def show_npc(self, view, script_ids, talk_pages, presence, editable, bytes_hint='',
                 conversation=None, name=None, service=None):
        """view = Document.npc_view(...); script_ids = [(index, id)];
        talk_pages = pages of a plain talk script or None; presence =
        [bool per state] or None (single-state screen)."""
        from editor2.app.rooms.canvas import SpriteCache
        self._building = True
        self._view = view
        spr = view.get('sprite', 0)
        if view.get('monster') is not None:          # S101: a monster NPC
            from editor2.app.rooms.canvas import MonsterCache, monster_name
            pm = MonsterCache.get(view['monster'])
            text = f"monster: {monster_name(view['monster'])}"
        else:
            cat = load_catalog().get(spr, {})
            pm = SpriteCache.get(spr)
            text = f"${spr:02X} {cat.get('name') or ''}".strip()
        self.sprite_btn.setIcon(QIcon(pm.scaled(32, 32)) if pm is not None else QIcon())
        self.sprite_btn.setText(text)
        self.pos.setText(f"({view['x']},{view['y']})   drag on the canvas to move")
        self.name_lbl.setText(f'“{name}”' if name else '<i>(no name)</i>')
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
        self.btn_edit_talk.setEnabled(talk_pages is not None or conversation is not None)
        self.talk_preview.setText(('Conversation: ' + conversation) if conversation is not None
                                  else ('Service: ' + service) if service is not None   # S126
                                  else talk_summary(talk_pages, cur))
        sw = view.get('shown_when') or []
        if view.get('swirl_of') is not None:
            self.shown_when.setText(f"a gate swirl: shown until gate {view['swirl_of']} is cleared")
        elif sw:
            self.shown_when.setText(' AND '.join(f"{t['flag']} {'ON' if t['is'] == 'set' else 'OFF'}"
                                                 for t in sw))
        else:
            self.shown_when.setText('always')
        col = view.get('colour')
        pal = col.get('palette') if isinstance(col, dict) else col
        self._fill_colours(pal)
        monster = view.get('monster') is not None
        if view.get('swirl_of') is not None:
            self.colour_note.setText('A portal swirl: its colour after clearing is set per gate '
                                     '/ world (World tab → "after clearing").')
        elif monster:
            self.colour_note.setText('A monster NPC walks in its own colours.')
        elif isinstance(col, dict) and col.get('when'):
            self.colour_note.setText(f"only while {col['when']} is ON (else its own colours)")
        else:
            self.colour_note.setText('')
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
                  self.btn_new_talk, self.btn_new_conv, self.btn_del, self.presence_box,
                  self.btn_shown, self.btn_boss, self.btn_service):
            w.setEnabled(editable)
        self.colour.setEnabled(editable and not monster and view.get('swirl_of') is None
                               and not view.get('raw'))
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



class ShownWhenDialog(QDialog):
    """S120 (ROADMAP NG2 residual b): which flags must be ON / OFF for an NPC to be shown
    (all must hold). Uses the talk editor's flag lists (project flags, New flag…, the
    well-known story flags, any number)."""

    def __init__(self, doc, terms=None, parent=None):
        super().__init__(parent)
        from PySide6.QtWidgets import QDialogButtonBox, QVBoxLayout
        from editor2.app.rooms.talk_editor import FlagList
        self.setWindowTitle('Shown when…')
        v = QVBoxLayout(self)
        intro = QLabel('The NPC is there only while ALL of these hold. The game checks them '
                       'whenever the screen loads (entering it, scrolling to it, after a '
                       'battle) — a flag set by a talk shows / hides the NPC at the next load. '
                       'Nothing listed = always there.')
        intro.setWordWrap(True)
        v.addWidget(intro)
        terms = terms or []
        self.on = FlagList(doc, 'These flags are ON:',
                           [t['flag'] for t in terms if t.get('is') == 'set'])
        self.off = FlagList(doc, 'These flags are OFF:',
                            [t['flag'] for t in terms if t.get('is') == 'clear'])
        v.addWidget(self.on)
        v.addWidget(self.off)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def terms(self):
        return ([{'flag': f, 'is': 'set'} for f in self.on.flags()]
                + [{'flag': f, 'is': 'clear'} for f in self.off.flags()])

    def new_flags(self):
        return self.on.new_flags + [f for f in self.off.new_flags if f not in self.on.new_flags]
