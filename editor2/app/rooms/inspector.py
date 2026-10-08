"""inspector.py — the Rooms tab's right-hand inspector (S93).

Panels (top to bottom): Room · Screen & state · Selection (clicked
marker) · Layout. Every value shown is read straight from the Document;
editable fields push undo commands. Fields whose editing belongs to a
later ROADMAP box (triggers/exits proper = P3.7) are shown read-only rather
than hidden, so the author always sees what the engine will get. S97: NPCs
are edited in the NPC panel (rooms/npc_panel.py, P3.5) and the room's flag
rules in the State rules group (rooms/rules_panel.py, P3.5a).
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtWidgets import (QComboBox, QFormLayout, QGroupBox, QLabel,
                               QLineEdit, QListWidget, QPushButton,
                               QScrollArea, QSpinBox, QVBoxLayout, QWidget,
                               QTreeWidget, QTreeWidgetItem, QHBoxLayout)

from editor2.core import animation as ANIM
from editor2.core import tileanim as TA
from editor2.core.document import val

VANILLA_PAL = '(borrow vanilla source palette)'


def narrow_combo(combo, chars=14):
    """S100 r3: size a combo to a short minimum instead of its longest item;
    the popup list keeps the full width of its texts (re-measured whenever
    the items change)."""
    combo.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
    combo.setMinimumContentsLength(chars)

    def fit_view(*_a):
        v = combo.view()
        v.setMinimumWidth(v.sizeHintForColumn(0) + 24 if combo.count() else 0)
    m = combo.model()
    m.rowsInserted.connect(fit_view)
    m.rowsRemoved.connect(fit_view)
    m.modelReset.connect(fit_view)
    m.dataChanged.connect(fit_view)
    fit_view()


def _lbl(text=''):
    l = QLabel(text)
    l.setWordWrap(True)
    l.setTextInteractionFlags(Qt.TextSelectableByMouse)
    return l


class Inspector(QWidget):
    thresholdEdited = Signal(int)
    paletteChosen = Signal(object)         # palette id or None
    localizeRequested = Signal()
    nameEdited = Signal(str)
    hoverInfo = Signal(str)
    statePaletteChosen = Signal(object)        # pid | None | ('vanilla', mid)
    addExitRequested = Signal(object)          # (cx, cy)
    removeExitRequested = Signal(int)          # exit index in the current state
    addRedirectRequested = Signal()
    removeRedirectRequested = Signal(int)      # index into custom.entrance_redirects
    routeDoorRequested = Signal(object)        # vanilla door preset dict
    portalGateRequested = Signal(object)       # S117 (NG2): vanilla portal -> another gate
    tilesetChangeRequested = Signal()          # S96
    addNpcRequested = Signal(object)           # (cx, cy)  S97
    addDoorRequested = Signal(object)          # (cx, cy)  S98
    addSpotRequested = Signal(object, str)     # (cx, cy), 'examine'|'step'  S98
    removeDoorRequested = Signal(str)          # door id  S98
    goDoorRequested = Signal(str)              # door id: select its end here  S98
    addStairsRequested = Signal(object)        # (cx, cy)  S100 gate rooms
    addGateEntranceRequested = Signal(object)  # (cx, cy)  S115 new gates (NG1)
    addWorldEntranceRequested = Signal(object)  # (cx, cy)  S123 worlds (NG3)
    playHereRequested = Signal(object)         # (cx, cy)  S120 (P3.4): play the room from here
    animationChosen = Signal(str)              # 'none' | 'source' | '0xNN'  S99

    def __init__(self, parent=None):
        super().__init__(parent)
        self._building = False
        self._vanilla_view = None
        # S132 (user: the right panel "is annoying as fuck to scroll through"):
        # the inspector no longer stacks everything in one scroll area — it
        # builds PAGES the Rooms tab puts behind its side rail:
        #   room_page   — the room, its doors in, state rules, Technical (folded)
        #   screen_page — the screen & state on the canvas, Technical (folded)
        #   object_page — the selected cell / marker (the tab adds the NPC, door
        #                 and spot forms under it)
        #   palette_row — the room / this-screen palette combos (Palettes page)
        from editor2.app.collapsible import Section
        self.scroll = None
        self.reveal_hook = None            # set by the tab: (widget) -> show its page
        self.room_page = QWidget()
        self.lay = QVBoxLayout(self.room_page)
        self.lay.setContentsMargins(6, 6, 6, 6)
        self.screen_page = QWidget()
        slay = QVBoxLayout(self.screen_page)
        slay.setContentsMargins(6, 6, 6, 6)
        self.object_page = QWidget()
        olay = QVBoxLayout(self.object_page)
        olay.setContentsMargins(6, 6, 6, 6)
        self.object_lay = olay
        self.palette_row = QWidget()
        pform = QFormLayout(self.palette_row)
        pform.setContentsMargins(0, 0, 0, 0)
        pform.setLabelAlignment(Qt.AlignRight)

        # ---- Room
        g = QGroupBox('Room')
        f = QFormLayout(g)
        f.setLabelAlignment(Qt.AlignRight)
        self.r_name = QLineEdit()
        self.r_name.editingFinished.connect(self._name_done)
        self.r_id = _lbl()
        self.r_map = _lbl()
        self.r_src = _lbl()
        self.r_gfx = _lbl()
        self.r_dims = _lbl()
        self.r_thr = QSpinBox()
        self.r_thr.setRange(0, 255)
        self.r_thr.setPrefix('$')
        self.r_thr.setDisplayIntegerBase(16)
        self.r_thr.valueChanged.connect(self._thr_changed)
        self.r_thr.setToolTip('Tiles below this index are walls. Use Walkability '
                              'mode (W) on the canvas rather than editing this.')
        self.r_pal = QComboBox()
        self.r_pal.currentIndexChanged.connect(self._pal_changed)
        self.r_attr = _lbl()
        self.r_enc = _lbl()
        self.r_music = _lbl()
        self.r_scripts = _lbl()
        self.r_note = _lbl()
        self.r_note.setStyleSheet('color: #e0b040;')
        # S99 (P3.3e): which room's tile animation this room plays
        self.r_anim = QComboBox()
        self.r_anim.setToolTip(
            'Tile animation (water, torches, swirls…) is a per-ROOM routine in the '
            'game that changes fixed tile slots of the sheet every few frames. '
            'Pick none, the source room\'s own, or borrow any room\'s — it then '
            'animates whatever graphic sits in those slots of THIS room\'s sheet. '
            'Anim (toolbar) outlines the tiles; ▶ Play previews it.')
        self.r_anim.currentIndexChanged.connect(self._anim_changed)
        self.r_anim_note = _lbl()
        self.r_anim_note.setStyleSheet('color: #6ad8e6;')
        f.addRow('name', self.r_name)
        trow = QHBoxLayout()
        trow.addWidget(self.r_gfx, 1)
        self.r_gfx_btn = QPushButton('Change…')
        self.r_gfx_btn.setToolTip("Draw this room with another room's tileset, a "
                                  'project tileset, or a new blank one for imported art.')
        self.r_gfx_btn.clicked.connect(self.tilesetChangeRequested.emit)
        trow.addWidget(self.r_gfx_btn)
        f.addRow('tileset', trow)
        f.addRow('size', self.r_dims)
        f.addRow('encounters', self.r_enc)
        f.addRow('music', self.r_music)
        # S102 (user: "I have NO understanding why you built in a drop down list
        # for importing animations"): the vanilla-source combo + note move to
        # the Animate tab, behind "Copy a vanilla room's animation…"
        # (tab.py attach_vanilla_controls); here one plain summary line
        self.r_anim_sum = _lbl()
        self.r_anim_sum.setToolTip('Make tiles move: Metatiles → Animate tab')
        f.addRow('animated tiles', self.r_anim_sum)
        f.addRow(self.r_note)
        self.lay.addWidget(g)
        # S132: the room palette lives on the Palettes page
        pform.addRow('room palette', self.r_pal)
        # S132: engine numbers in a folded box (they are not what you edit)
        tech = QWidget()
        tf = QFormLayout(tech)
        tf.setLabelAlignment(Qt.AlignRight)
        tf.setContentsMargins(4, 0, 4, 0)
        tf.addRow('id', self.r_id)
        tf.addRow('mapID', self.r_map)
        tf.addRow('source map', self.r_src)
        tf.addRow('collision ≥', self.r_thr)
        tf.addRow('attr base', self.r_attr)
        tf.addRow('scripts', self.r_scripts)
        self._room_tech = tech
        self._room_tech_form = tf

        # ---- Doors & entrances (S94b redirects, S98 doors)
        g = QGroupBox('Doors && entrances — how the player gets here')
        v = QVBoxLayout(g)
        self.redirect_list = QListWidget()
        self.redirect_list.setMaximumHeight(110)
        self.redirect_list.setToolTip(
            'This room\'s doors (and what each is connected to), and vanilla doors routed '
            'one-way into it. Double-click a door to show it.')
        self.redirect_list.itemDoubleClicked.connect(self._go_item)
        self.redirect_none = _lbl('No door leads here yet — this room is reachable only by '
                                  'warp. Select a cell and press + Door (D), then double-click '
                                  'the door to connect it (a vanilla door is the quickest '
                                  'in-game test).')
        self.redirect_none.setStyleSheet('color: #e0b040;')
        row = QHBoxLayout()
        self.btn_add_redirect = QPushButton('One-way from a vanilla door…')
        self.btn_add_redirect.setToolTip('Re-point a vanilla door into this room WITHOUT a way '
                                         'back (S94b). For two-way, add a door here (+ Door) '
                                         'and connect it to the vanilla door.')
        self.btn_add_redirect.clicked.connect(self.addRedirectRequested.emit)
        self.btn_go_redirect = QPushButton('Show')
        self.btn_go_redirect.clicked.connect(lambda: self._go_item(self.redirect_list.currentItem()))
        self.btn_del_redirect = QPushButton('Remove')
        self.btn_del_redirect.clicked.connect(self._remove_redirect)
        row.addWidget(self.btn_add_redirect)
        row.addWidget(self.btn_go_redirect)
        row.addWidget(self.btn_del_redirect)
        v.addWidget(self.redirect_none)
        v.addWidget(self.redirect_list)
        v.addLayout(row)
        self.entr_group = g
        self.lay.addWidget(g)

        # ---- Inside gates (S100, P3.7b part 1). S100 r3 (user: "separate the
        # gate stuff from 'room/screen/selection' with its own arrow button"):
        # built here (the inspector still fills it) but NOT added to this
        # layout — the Rooms tab shows it in its own foldable section.
        from editor2.app.rooms.gate_panel import GateRoomGroup
        self.gate_group = GateRoomGroup()

        # ---- State rules (S97, P3.5a) — room level
        from editor2.app.rooms.rules_panel import RulesGroup
        self.rules = RulesGroup()
        self.lay.addWidget(self.rules)
        self.lay.addWidget(Section('Technical (engine numbers)', self._room_tech,
                                   'rooms_room_tech', expanded=False))
        self.lay.addStretch(1)

        # ---- Screen & state
        g = QGroupBox('Screen && state')
        f = QFormLayout(g)
        f.setLabelAlignment(Qt.AlignRight)
        self.s_key = _lbl()
        self.s_layout = _lbl()
        self.s_localize = QPushButton('Make editable (copy into project)')
        self.s_localize.clicked.connect(self.localizeRequested.emit)
        self.s_attr = _lbl()
        self.s_counter = _lbl()
        self.s_states = _lbl()
        self.s_npcs = _lbl()
        self.s_pal = QComboBox()
        self.s_pal.currentIndexChanged.connect(self._state_pal_changed)
        self.s_pal.setToolTip('Palette shown on THIS screen/state (states[n].palette or '
                              'screens[k].palette). "(room palette)" inherits the Room '
                              'setting; a vanilla entry copies that room\'s palette into '
                              'your project as an editable item.')
        f.addRow('screen', self.s_key)
        f.addRow('states', self.s_states)
        f.addRow('NPC slots', self.s_npcs)
        f.addRow('layout', self.s_layout)
        f.addRow('', self.s_localize)
        slay.addWidget(g)
        pform.addRow('this screen / state', self.s_pal)
        stech = QWidget()
        sf = QFormLayout(stech)
        sf.setLabelAlignment(Qt.AlignRight)
        sf.setContentsMargins(4, 0, 4, 0)
        sf.addRow('attr grid', self.s_attr)
        sf.addRow('step counter', self.s_counter)
        self._screen_tech_form = sf

        # ---- Selection
        g = QGroupBox('Selection')
        v = QVBoxLayout(g)
        self.sel_title = _lbl('Nothing selected — use the Select tool (V) and '
                              'click a cell, an NPC, a door or a spot.')
        self.sel_tree = QTreeWidget()
        self.sel_tree.setHeaderLabels(['field', 'value'])
        self.sel_tree.setRootIsDecorated(False)
        self.sel_tree.setMaximumHeight(170)
        self.sel_tree.setVisible(False)
        self.sel_note = _lbl('Exit fields become editable in P3.7 (doors).')
        self.sel_note.setStyleSheet('color: #888;')
        self.sel_route = QPushButton('Route this door into a custom room…')
        self.sel_route.clicked.connect(self._route_selected)
        self.sel_route.setVisible(False)
        self.sel_portal = QPushButton('Lead this portal to another gate…')
        self.sel_portal.setToolTip('S117: this vanilla gate portal enters the gate you pick '
                                   '(e.g. one of your new gates). Its swirl then spins until '
                                   'THAT gate is cleared.')
        self.sel_portal.clicked.connect(self._portal_selected)
        self.sel_portal.setVisible(False)
        self._sel_door = None
        # S98: what can be placed on a cell (the rare ones under "More")
        from PySide6.QtWidgets import QMenu, QToolButton
        self.sel_add_npc = QPushButton('Add NPC here…')
        self.sel_add_npc.clicked.connect(self._add_npc_here)
        self.sel_add_door = QPushButton('Add door here')
        self.sel_add_door.setToolTip('Puts a door on this cell (D). Double-click it to name it '
                                     'and connect it to another door.')
        self.sel_add_door.clicked.connect(lambda: self._emit_cell(self.addDoorRequested))
        self.sel_add_spot = QPushButton('Add examine spot here…')
        self.sel_add_spot.setToolTip('Invisible: answers an A press on / facing this cell '
                                     '(signs, bookshelves, searchable things).')
        self.sel_add_spot.clicked.connect(lambda: self._emit_spot('examine'))
        self.sel_more = QToolButton()
        self.sel_more.setText('More ▾')
        self.sel_more.setPopupMode(QToolButton.InstantPopup)
        m = QMenu(self.sel_more)
        m.addAction('One-way teleport here…', self._add_exit_here)
        m.addAction('Step-on trigger here…', lambda: self._emit_spot('step'))
        m.addAction('Stairs down here (gate rooms)', lambda: self._emit_cell(self.addStairsRequested))
        m.addAction('Gate entrance here…', lambda: self._emit_cell(self.addGateEntranceRequested))
        m.addAction('World entrance here…', lambda: self._emit_cell(self.addWorldEntranceRequested))
        m.addSeparator()
        m.addAction('▶ Play the game here (last build)',
                    lambda: self._emit_cell(self.playHereRequested))
        self.sel_more.setMenu(m)
        self.sel_add_row = QWidget()
        ar = QHBoxLayout(self.sel_add_row)
        ar.setContentsMargins(0, 0, 0, 0)
        for w in (self.sel_add_npc, self.sel_add_door, self.sel_add_spot, self.sel_more):
            ar.addWidget(w)
        ar.addStretch(1)
        self.sel_add_row.setVisible(False)
        # kept for callers of the S95 API (hidden; "More" holds the teleport)
        self.sel_add_exit = QPushButton('One-way teleport here…')
        self.sel_add_exit.clicked.connect(self._add_exit_here)
        self.sel_add_exit.setVisible(False)
        self._sel_cell = None
        self.sel_del_exit = QPushButton('Delete this exit')
        self.sel_del_exit.clicked.connect(self._del_exit)
        self.sel_del_exit.setVisible(False)
        self._sel_exit_idx = None
        v.addWidget(self.sel_title)
        v.addWidget(self.sel_tree)
        v.addWidget(self.sel_route)
        v.addWidget(self.sel_portal)
        v.addWidget(self.sel_add_row)
        v.addWidget(self.sel_del_exit)
        v.addWidget(self.sel_note)
        olay.addWidget(g)

        # ---- NPC (S97, P3.5): the form lives in the tab's own "NPC" section
        # (S97 r2 user request); the tab sets self.npc so a new selection
        # here hides it.
        self.npc = None

        # ---- Layout
        self.l_id = _lbl()
        self.l_users = _lbl()
        sf.addRow('layout id', self.l_id)
        sf.addRow('layout used by', self.l_users)
        slay.addWidget(Section('Technical (engine numbers)', stech, 'rooms_screen_tech',
                               expanded=False))
        slay.addStretch(1)
        # S100 r3 (user: "'room/screen/selection' is enormous and needs to be
        # scrolled both down and to the right"): a combo is as wide as its
        # LONGEST item (the animation list reached ~1,400 px) — every combo
        # here gets a short minimum; its open list still shows full texts
        for page in (self.room_page, self.screen_page, self.object_page, self.palette_row):
            for c in page.findChildren(QComboBox):
                narrow_combo(c)
        for c in self.gate_group.findChildren(QComboBox):
            narrow_combo(c)

    # ------------------------------------------------------------ updates
    def show_vanilla(self, renderer, mid, key):
        """Read-only view of a vanilla room."""
        self._building = True
        self.r_name.setText(renderer.vanilla_name(mid))
        self.r_name.setEnabled(False)
        self.r_id.setText(f'vanilla ${mid:02X}')
        self.r_map.setText(f'${mid:02X}  (vanilla — read-only)')
        self.r_src.setText('—')
        gfx = renderer.vanilla_gfx(mid)
        self.r_gfx.setText(f'bank ${gfx.gfx_bank:02X} id ${gfx.gfx_id:02X}')
        self.r_gfx_btn.setEnabled(False)
        self.r_thr.setValue(gfx.threshold)
        self.r_thr.setEnabled(False)
        rec = renderer.vanilla_record(mid)
        self.r_dims.setText(f"{rec['width_px'] // 160}×{rec['height_px'] // 128} screens")
        self.r_pal.clear()
        self.r_pal.addItem('vanilla palette', None)
        self.r_pal.setEnabled(False)
        self.r_attr.setText('vanilla')
        self.r_enc.setText('vanilla')
        self.r_music.setText('vanilla')
        self.r_anim.clear()
        e = ANIM.map_entry(mid)
        if e.get('slots') and not e.get('inert_in_vanilla') and mid not in (0x08,):
            self.r_anim.addItem(f'animates: {ANIM.describe_effects(mid)}', None)
            hid = e.get('hidden_frames') or []
            self.r_anim_note.setText(
                'Outlined dashed on the canvas (Anim); ▶ Play shows it moving.'
                + (f' Slots {ANIM.rng(hid)} hold the hidden second frames.' if hid else ''))
        else:
            self.r_anim.addItem('none', None)
            self.r_anim_note.setText('' if not e.get('slots') else
                                     'Its routine animates blank slots (nothing visible).')
        self.r_anim.setEnabled(False)
        self.r_anim_note.setVisible(bool(self.r_anim_note.text()))
        self.r_anim_sum.setText(self.r_anim.itemText(0) if self.r_anim.count() else 'none')
        self.r_scripts.setText('vanilla')
        self.r_note.setText('Vanilla room. "Make editable" clones it into your '
                            'project (the original stays untouched).')
        self.r_note.setVisible(True)
        self.entr_group.setVisible(False)
        self.rules.setVisible(False)
        self.gate_group.setVisible(False)
        self._vanilla_view = (mid, key)
        self.s_key.setText(f'{key}')
        self.s_layout.setText('vanilla layout (read-only)')
        self.s_localize.setVisible(False)
        self.s_attr.setText('vanilla attr')
        self.s_attr.setStyleSheet('')
        self.s_counter.setText('vanilla')
        self.s_states.setText('showing vanilla step 0')
        self.s_npcs.setText('—')
        self.s_npcs.setStyleSheet('')
        self.l_id.setText('—')
        self.l_users.setText('—')
        self._building = False

    def show_room(self, doc, renderer, room, key, state_idx):
        self._building = True
        mid = val(room['mapID'])
        self.r_name.setText(doc.room_name(room))
        self.r_name.setEnabled(not room.get('placeholder'))
        self.r_pal.setEnabled(True)
        self.r_id.setText(room.get('id', '?'))
        self.r_map.setText(f'${mid:02X}' + (' (placeholder)' if room.get('placeholder') else ''))
        self.r_src.setText(f"${val(room.get('source_mapID', 0)):02X}")
        rec = room.get('record') or {}
        self.r_gfx_btn.setEnabled(bool(rec) and not room.get('placeholder'))
        note = ''
        try:
            gfx = renderer.room_gfx(room)
            if 'tileset' in rec:
                self.r_gfx.setText(f"custom tileset {rec['tileset']!r} (bank $67)")
            else:
                self.r_gfx.setText(f'bank ${gfx.gfx_bank:02X} id ${gfx.gfx_id:02X}')
            note = gfx.note
            self.r_thr.setValue(gfx.threshold)
            self.r_thr.setEnabled(bool(rec))
        except Exception as e:                    # pragma: no cover
            self.r_gfx.setText(f'unavailable: {e}')
        keys = doc.screen_keys(room)
        cols = (max(k % 4 for k in keys) + 1) if keys else 0
        rows = (max(k // 4 for k in keys) + 1) if keys else 0
        dims = f"{cols}×{rows} screens"
        if rec:
            dims += f"  (record {rec.get('width_px')}×{rec.get('height_px')} px)"
        else:
            note = note or 'legacy room (< $70): record hand-patched in bank_000'
        self.r_dims.setText(dims)
        # palette combo
        self.r_pal.clear()
        self.r_pal.addItem(VANILLA_PAL, None)
        cur = (room.get('render') or {}).get('palette')
        self._fill_palette_combo(self.r_pal, doc, renderer)
        idx = self.r_pal.findData(cur) if cur else 0
        self.r_pal.setCurrentIndex(max(idx, 0))
        at = (room.get('render') or {}).get('attr')
        self.r_attr.setText(str(at.get('id') if at and 'id' in at else at or 'none'))
        enc = room.get('encounters')
        self.r_enc.setText(
            (f"its own list {enc.get('list')}" + (f" (+{len(enc['variants'])} flag "
             "variant(s))" if enc.get('variants') else '') if enc.get('list') is not None
             else "follows the gate being dived" if enc.get('follow_gate')
             else f"gate {enc.get('gate_id')} floor {enc.get('floor')}")
            + (f", rate code {enc['rate']}" if enc.get('rate') is not None else '')
            + '  (Encounters tab)'
            if enc and enc.get('enabled') else 'off')
        self.r_music.setText(str(room.get('music', 'default')))
        self._fill_anim(doc, renderer, room)
        self.r_scripts.setText(str(len(room.get('scripts') or {})))
        self.r_note.setText(note)
        self.r_note.setVisible(bool(note))
        self._vanilla_view = None
        self.show_entrances(doc, renderer, room)
        self.rules.setVisible(not room.get('placeholder'))
        self.rules.show_room(doc, room, key, state_idx)
        self.gate_group.setVisible(not room.get('placeholder'))
        if not room.get('placeholder'):
            self.gate_group.show_room(doc, room)
        self.show_screen(doc, renderer, room, key, state_idx)
        self._building = False

    def _fill_anim(self, doc, renderer, room):
        """S99: None / Same as source room / Borrow <room>, plus one line
        saying exactly which slots move and whether they hold that room's art."""
        self.r_anim.clear()
        self.r_anim.setEnabled(not room.get('placeholder'))
        src = val(room.get('source_mapID', 0))
        names = {m: n for m, n, _s in renderer.vanilla_rooms()}
        src_name = names.get(src) or renderer.vanilla_name(src)
        src_txt = ANIM.describe_effects(src) if src < 0x6B else ''
        self.r_anim.addItem('None — no tile animation', 'none')
        self.r_anim.addItem(f'Same as source room (${src:02X} {src_name}'
                            + (f': {src_txt})' if src_txt else ': none)'), 'source')
        self.r_anim.insertSeparator(self.r_anim.count())
        for mid, label in ANIM.sources(names):
            self.r_anim.addItem(f'Borrow {label}', f'0x{mid:02X}')
        info = doc.room_animation(room)
        cur = room.get('animation')
        idx = -1
        if isinstance(cur, str) and cur.lower() in ('none', 'source'):
            idx = self.r_anim.findData(cur.lower())
        elif cur is not None:
            try:
                idx = self.r_anim.findData(f'0x{val(cur):02X}')
            except Exception:
                idx = -1
        if idx < 0 and cur is not None:
            self.r_anim.addItem(f'(current: {cur})', cur)
            idx = self.r_anim.count() - 1
        self.r_anim.setCurrentIndex(max(idx, 0))
        self.r_anim_note.setText(self._anim_note(doc, renderer, room, info))
        self.r_anim_note.setVisible(bool(self.r_anim_note.text()))
        own = doc.tile_anims(room)
        bits = []
        if own:
            n = sum(len(TA.slots_of(a)) for a in own)
            bits.append(f"{len(own)} animation{'s' if len(own) != 1 else ''} ({n} tiles)")
        if info.get('map') is not None:
            bits.append(f"copied vanilla ${info['map']:02X}")
        self.r_anim_sum.setText((', '.join(bits) or 'none') + ' — Animate tab')

    @staticmethod
    def _anim_note(doc, renderer, room, info):
        if info.get('error'):
            return f"⚠ {info['error']}"
        if info['kind'] == 'legacy':
            return ('Not set: plays Castle\'s roll on slots 77-78 (the old behaviour). '
                    'Pick one above.')
        mid = info['map']
        if mid is None:
            return 'No tile moves in this room.'
        txt = f"Slots {ANIM.rng(info['slots'])} change in game: {info['text']}."
        try:                                  # S99 r6: the count
            b = doc.anim_budget(room)
            cnt = '; '.join(f"{u['effect']} {u['used']} of {u['total']} {u['unit']}s"
                            + (' (FULL)' if u['used'] >= u['total'] else '')
                            for u in b['units'])
            if cnt:
                txt = (f"Used here: {cnt} — {len(b['tiles'])} moving tile(s) "
                       '(Animate tab). ' + txt)
        except Exception:
            pass
        try:
            g = renderer.vanilla_gfx(mid)
            same = doc.tileset_origin(doc.tileset_key(room)) == (g.gfx_bank, g.gfx_id)
        except Exception:
            same = False
        if not same:
            txt += (f' This room\'s sheet is NOT ${mid:02X}\'s, so whatever graphic sits '
                    'in those slots here moves instead (dashed outline on the canvas; '
                    '▶ Play shows it). Imports and twins leave those slots alone.')
        return txt

    def _anim_changed(self, _i):
        if not self._building and self.r_anim.isEnabled():
            v = self.r_anim.currentData()
            if isinstance(v, str):
                self.animationChosen.emit(v)

    def _fill_palette_combo(self, combo, doc, renderer):
        """Project palettes, then every vanilla room's palette as a
        'copy into project' entry (user S95: "use a pre-existing room's
        palette")."""
        from editor2.core.palette_borrow import palette_users
        for p in doc.palettes:
            # S132: say whose palette it is (a bare id told the user nothing)
            rooms = []
            for rid, _k, _s in palette_users(doc, p['id']):
                try:
                    nm = doc.room_name(doc.room(rid))
                except KeyError:
                    continue
                if nm not in rooms:
                    rooms.append(nm)
            label = p['id'] + (f"  — {', '.join(rooms[:3])}{'…' if len(rooms) > 3 else ''}"
                               if rooms else '  — not used')
            combo.addItem(label, p['id'])
        combo.insertSeparator(combo.count())
        for mid, name, _scr in renderer.vanilla_rooms():
            combo.addItem(f'copy from vanilla ${mid:02X} {name}', ('vanilla', mid))

    def show_entrances(self, doc, renderer, room):
        from PySide6.QtWidgets import QListWidgetItem
        from editor2.app.rooms.object_panels import describe_end
        self.entr_group.setVisible(not room.get('placeholder'))
        self.redirect_list.clear()
        n = 0
        from editor2.app.rooms.door_dialog import end_place
        for end in doc.doors_touching(room['id']):
            p = doc.door_partner(end['id'])
            if end['kind'] == 'room':
                txt = (f"'{end['name']}' screen {end['screen']} ({end['x']},{end['y']})  ↔  "
                       + (f"'{p['name']}' ({end_place(doc, p)})" if p else 'not connected'))
            else:
                txt = f"{end_place(doc, end)}  ↔  '{p['name'] if p else '?'}'"
            it = QListWidgetItem(txt)
            it.setData(Qt.UserRole, ('door', end['id']))
            self.redirect_list.addItem(it)
            n += 1
        reds = doc.redirects_to(room['id'])
        for i, rd in reds:
            if rd.get('door'):
                continue
            try:
                name = renderer.vanilla_name(val(rd['mapID']))
            except Exception:
                name = f"${val(rd['mapID']):02X}"
            it = QListWidgetItem(f"one-way: {name} screen {val(rd['screen'])} door "
                                 f"({val(rd['x'])},{val(rd['y'])})  →  screen "
                                 f"{val(rd['screen_byte']) & 0x0F} cell "
                                 f"({val(rd['spawn_x'])},{val(rd['spawn_y'])})")
            it.setData(Qt.UserRole, ('redirect', i))
            self.redirect_list.addItem(it)
            n += 1
        self.redirect_none.setVisible(not n)
        self.redirect_list.setVisible(bool(n))
        self.btn_del_redirect.setEnabled(bool(n))
        self.btn_go_redirect.setEnabled(bool(n))

    def _go_item(self, it):
        if it is None:
            return
        d = it.data(Qt.UserRole)
        if d and d[0] == 'door':
            self.goDoorRequested.emit(d[1])

    def show_screen(self, doc, renderer, room, key, state_idx):
        if str(key) not in room.get('screens', {}):
            self.s_key.setText('—')
            return
        self.s_key.setText(f'{key}  (col {key % 4}, row {key // 4})')
        ref = doc.state_layout_ref(room, key, state_idx)
        if ref and 'id' in ref:
            self.s_layout.setText(f"{ref['id']}  (project layout, editable)")
            self.s_localize.setVisible(False)
        elif ref:
            self.s_layout.setText(
                f"vanilla bank {ref.get('bank')} entry {ref.get('entry')} — "
                'read-only until copied into the project')
            self.s_localize.setVisible(True)
        else:
            self.s_layout.setText('none')
            self.s_localize.setVisible(False)
        self._building = True
        self.s_pal.clear()
        self.s_pal.addItem('(room palette)', None)
        self._fill_palette_combo(self.s_pal, doc, renderer)
        scr = doc.screen(room, key)
        own = (scr['states'][state_idx].get('palette') if scr.get('states')
               else scr.get('palette'))
        i = self.s_pal.findData(own) if own else 0
        self.s_pal.setCurrentIndex(max(i, 0))
        self._building = False
        _grid, note = renderer.attr_grid(room, int(key), state_idx)
        self.s_attr.setText(note)
        self.s_attr.setStyleSheet('color: #ff6060;' if note.startswith('WARNING')
                                  else '')
        scr = doc.screen(room, key)
        sc = scr.get('step_counter', 'auto')
        self.s_counter.setText(sc if isinstance(sc, str) else
                               str(sc.get('label') or sc.get('addr')))
        sts = doc.states(room, key)
        self.s_states.setText(f'{len(sts)}  (viewing state {state_idx})'
                              + ('' if scr.get('states') else '  — single implicit state'))
        n, cap = doc.state_capacity(room, key, state_idx)
        self.s_npcs.setText(f'{n} / {cap} (hard cap, S91)')
        self.s_npcs.setStyleSheet('color: #ff6060;' if n > cap else
                                  'color: #e0b040;' if n == cap else '')
        # layout panel
        lid = ref.get('id') if ref and 'id' in ref else None
        self.l_id.setText(lid or '—')
        if lid:
            users = doc.layout_users(lid)
            self.l_users.setText('\n'.join(
                f"{r} screen {k}" + (f" state {i}" if i is not None else '')
                + (' (attr)' if kind == 'attr' else '')
                for r, k, i, kind in users) or '—')
        else:
            self.l_users.setText('—')

    def show_cell(self, cell, mt, walkable, editable=False):
        self.sel_tree.clear()
        self.sel_route.setVisible(False)
        self.sel_portal.setVisible(False)
        self.sel_del_exit.setVisible(False)
        if self.npc is not None:
            self.npc.setVisible(False)
        self._sel_exit_idx = None
        if cell is None:
            self.show_selection(None)
            return
        cx, cy = cell
        self._sel_cell = cell
        self.sel_tree.setVisible(True)
        self.sel_add_row.setVisible(bool(editable))
        self.sel_title.setText(f'Cell ({cx},{cy})')
        for name, t in zip(('top-left', 'top-right', 'bottom-left', 'bottom-right'),
                           mt['tiles']):
            QTreeWidgetItem(self.sel_tree, [f'subtile {name}', f'${t:02X} ({t})'])
        QTreeWidgetItem(self.sel_tree, ['palette slot', str(mt.get('pal'))])
        QTreeWidgetItem(self.sel_tree, ['walkable', 'yes' if walkable else 'NO (wall)'])
        self.sel_note.setText('Walkability is decided by the bottom-right subtile '
                              '(engine, measured S94). Use Walkability mode (W) to flip it.')

    def add_cell_row(self, name, value):
        """S99 r3: an extra line under the selected cell (animation)."""
        QTreeWidgetItem(self.sel_tree, [name, value])

    def show_selection(self, sel, editable=False):
        self.sel_tree.clear()
        self.sel_route.setVisible(False)
        self.sel_portal.setVisible(False)
        self.sel_add_row.setVisible(False)
        self.sel_del_exit.setVisible(False)
        if self.npc is not None:
            self.npc.setVisible(False)
        self._sel_door = None
        self._sel_exit_idx = None
        if not sel:
            self.sel_title.setText('Nothing selected — click a cell, an NPC, a door or a '
                                   'spot with the Select tool (V).')
            self.sel_note.setText('')
            self.sel_tree.setVisible(False)          # S132: no empty table
            return
        self.sel_tree.setVisible(True)
        if sel['kind'] in ('exit', 'redirect') and self._vanilla_view:
            mid, key = self._vanilla_view
            self._sel_door = {'mapID': mid, 'screen': key,
                              'x': sel['x'], 'y': sel['y']}
            self.sel_route.setVisible(True)
            try:
                gf = sel['ref'][2].get('gate_flag', 0)
                gf = int(str(gf), 0) if not isinstance(gf, int) else gf
            except (TypeError, ValueError, IndexError, AttributeError):
                gf = 0
            self.sel_portal.setVisible(gf == 1)
        self.sel_note.setText('' if sel['kind'] in ('npc', 'door', 'exit', 'examine', 'step',
                                                     'spawn') else
                              'Edit it in the Object section below.')
        self.sel_title.setText(f"{sel['label']}  at cell ({sel['x']},{sel['y']})")
        _kind, idx, entry = sel['ref']
        for k, v in entry.items():
            if isinstance(v, list):
                v = ' '.join(str(x) for x in v)
            QTreeWidgetItem(self.sel_tree, [str(k), str(v)])
        QTreeWidgetItem(self.sel_tree, ['entry #', str(idx)])

    # ------------------------------------------------------------- slots
    def _remove_redirect(self):
        it = self.redirect_list.currentItem() or (
            self.redirect_list.item(0) if self.redirect_list.count() else None)
        if it is None:
            return
        kind, v = it.data(Qt.UserRole)
        if kind == 'door':
            self.removeDoorRequested.emit(v)
        else:
            self.removeRedirectRequested.emit(v)

    def _route_selected(self):
        if self._sel_door:
            self.routeDoorRequested.emit(dict(self._sel_door))

    def _portal_selected(self):
        if self._sel_door:
            self.portalGateRequested.emit(dict(self._sel_door))

    def reveal(self, widget):
        """Bring `widget` into view (S97; S132: the tab shows its rail page)."""
        if self.reveal_hook is not None:
            self.reveal_hook(widget)

    def _add_npc_here(self):
        if self._sel_cell is not None:
            self.addNpcRequested.emit(tuple(self._sel_cell))

    def _emit_cell(self, sig):
        if self._sel_cell is not None:
            sig.emit(tuple(self._sel_cell))

    def _emit_spot(self, kind):
        if self._sel_cell is not None:
            self.addSpotRequested.emit(tuple(self._sel_cell), kind)

    def _add_exit_here(self):
        if self._sel_cell is not None:
            self.addExitRequested.emit(tuple(self._sel_cell))

    def _del_exit(self):
        if self._sel_exit_idx is not None:
            self.removeExitRequested.emit(int(self._sel_exit_idx))

    def _state_pal_changed(self, _i):
        if not self._building:
            self.statePaletteChosen.emit(self.s_pal.currentData())

    def _thr_changed(self, v):
        if not self._building:
            self.thresholdEdited.emit(v)

    def _pal_changed(self, _i):
        if not self._building:
            self.paletteChosen.emit(self.r_pal.currentData())

    def _name_done(self):
        if not self._building and self.r_name.isEnabled():
            self.nameEdited.emit(self.r_name.text().strip())
