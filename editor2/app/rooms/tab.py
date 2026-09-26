"""tab.py — the Rooms tab, v2 (EDITOR_DESIGN §5.1; S93 → S94).

Layout:   [VANILLA rooms | CUSTOM rooms | mini-map]  |  [tool bar / state bar /
          banner / canvas / status]  |  [metatile picker / palettes / inspector]

Room model (user decision S94 — fork, don't fiddle):
  • Vanilla rooms (97 named, all rendered live, read-only). "Make editable"
    clones one into the project (extract_room.py + layouts localized) after
    a confirmation; the original is untouched.
  • Custom rooms: New (blank, on a vanilla tileset), Copy, Rename, Delete.
Every edit goes through rooms/commands.py so ⌘Z always works.
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QAction, QActionGroup, QKeySequence, QPixmap
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox, QFormLayout,
                               QHBoxLayout, QInputDialog, QLabel, QListWidget,
                               QListWidgetItem, QMenu, QMessageBox, QPushButton,
                               QScrollArea, QSizePolicy, QSplitter, QTabWidget,
                               QToolBar, QToolButton, QVBoxLayout, QWidget)

from editor2.core.document import val, GRID_COLS, metatile_key
from editor2.app.session import REPO
from editor2.app.rooms import commands as C
from editor2.app.rooms.canvas import RoomCanvas, metatile_at
from editor2.app.rooms.inspector import Inspector
from editor2.app.rooms.metatile_editor import MetatileEditor
from editor2.app.rooms.metatile_picker import MetatilePicker
from editor2.app.rooms.minimap import MiniMap
from editor2.app.rooms.palette_panel import PalettePanel
from editor2.app.rooms.redirect_dialog import RedirectDialog, ExitDialog
from editor2.app.rooms.door_dialog import DoorDialog
from editor2.app.rooms.tileset_map import TilesetMap
from editor2.app.rooms.tileset_dialog import TilesetDialog
from editor2.app.collapsible import Section


class NewRoomDialog(QDialog):
    def __init__(self, renderer, parent=None):
        super().__init__(parent)
        self.setWindowTitle('New room')
        f = QFormLayout(self)
        self.name = QComboBox()
        self.name.setEditable(True)
        self.name.setCurrentText('New room')
        self.src = QComboBox()
        for mid, name, _scr in renderer.vanilla_rooms():
            self.src.addItem(f'${mid:02X}  {name}', mid)
        f.addRow('Name', self.name)
        f.addRow('Tileset / palette from', self.src)
        from PySide6.QtWidgets import QCheckBox
        self.blank = QCheckBox('start with a BLANK tileset (for imported PNG art)')
        self.blank.setToolTip('The room gets its own empty 128-slot sheet; palette and '
                              'engine source still come from the room above.')
        f.addRow('', self.blank)
        f.addRow(QLabel('The room starts as one screen of floor. Connect it with "Add door '
                        'here…" on a cell (a vanilla door as the other end is the quickest '
                        'in-game test).'))
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        f.addRow(bb)


class _ObjectPanels:
    """The inspector's `npc` hook (S97: 'a new selection hides the NPC
    form') now hides every object panel of the Object section (S98)."""

    def __init__(self, tab):
        self.tab = tab

    def setVisible(self, on):
        t = self.tab
        if not on:
            for p in (t.npc_panel, t.door_panel, t.tele_panel, t.spot_panel):
                p.setVisible(False)
            t.npc_hint.setVisible(True)

    def isHidden(self):
        t = self.tab
        return all(p.isHidden() for p in (t.npc_panel, t.door_panel, t.tele_panel, t.spot_panel))


class RoomsTab(QWidget):
    status = Signal(str)
    HELP = ('V select · D / X add a door / examine spot on the selected cell · double-click to edit · B paint · I / right-click eyedrop · W walkability · '
            'Esc select · ⌘/Ctrl+wheel zoom · space-drag pan · , . state · 0-9 screen · ⌘Z undo')

    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.room_id = None          # custom room id, or None when viewing vanilla
        self._sel_npc = None         # S97: index of the selected NPC entry
        self.vanilla_mid = None
        self.key = 0
        self.state_idx = 0
        self._build()
        self.s.structureChanged.connect(self._on_structure)
        self.s.layoutChanged.connect(self._on_layout)
        self.s.paletteChanged.connect(lambda _p: self._refresh_side())
        self._fill_rooms()

    # ------------------------------------------------------------- build
    def _build(self):
        # ---------- left: vanilla | custom | minimap
        left = QWidget()
        lv = QVBoxLayout(left)
        lv.setContentsMargins(4, 4, 4, 4)
        lsplit = QSplitter(Qt.Vertical)

        vbox = QWidget()
        vl = QVBoxLayout(vbox)
        vl.setContentsMargins(0, 0, 0, 0)
        self.vanilla_header = QLabel('Vanilla rooms (read-only)')
        self.vanilla_list = QListWidget()
        self.vanilla_list.currentItemChanged.connect(self._vanilla_picked)
        self.btn_clone = QPushButton('Make editable → clone into project')
        self.btn_clone.clicked.connect(self._clone_vanilla)
        vl.addWidget(self.vanilla_header)
        vl.addWidget(self.vanilla_list, 1)
        vl.addWidget(self.btn_clone)
        lsplit.addWidget(vbox)

        cbox = QWidget()
        cl = QVBoxLayout(cbox)
        cl.setContentsMargins(0, 0, 0, 0)
        self.rooms_header = QLabel('Custom rooms')
        self.room_list = QListWidget()
        self.room_list.currentItemChanged.connect(self._room_picked)
        self.room_list.itemDoubleClicked.connect(lambda _i: self._rename_room())
        row = QHBoxLayout()
        for text, fn, tip in (('New', self._new_room, 'Blank room on a vanilla tileset'),
                              ('Copy', self._copy_room, 'Copy the selected custom room (own layouts)'),
                              ('Rename', self._rename_room, 'Rename the selected room'),
                              ('Delete', self._delete_room, 'Delete the selected room')):
            b = QPushButton(text)
            b.setToolTip(tip)
            b.clicked.connect(fn)
            row.addWidget(b)
        cl.addWidget(self.rooms_header)
        cl.addWidget(self.room_list, 1)
        cl.addLayout(row)
        lsplit.addWidget(cbox)
        lsplit.setSizes([260, 300])
        lv.addWidget(lsplit, 1)
        lv.addWidget(QLabel('Screens (4×4 grid — click + to add, right-click to remove)'))
        self.minimap = MiniMap()
        self.minimap.screenSelected.connect(self.select_screen)
        self.minimap.addScreenRequested.connect(self._add_screen)
        self.minimap.removeScreenRequested.connect(self._remove_screen)
        lv.addWidget(self.minimap, 0, Qt.AlignHCenter)

        # ---------- centre
        centre = QWidget()
        centre.setMinimumWidth(320)
        cv = QVBoxLayout(centre)
        cv.setContentsMargins(0, 0, 0, 0)
        cv.setSpacing(2)
        self.tools = QToolBar('Tools')
        self.tools.setMovable(False)
        self.tools.setToolButtonStyle(Qt.ToolButtonTextOnly)
        self.tool_group = QActionGroup(self)
        self.tool_actions = {}
        # S98 r2: Rect / Fill dropped from the bar (user: "kinda pointless")
        # — their R / F keys still work. "Add door" sits next to Select.
        for name, text, key, shown, tip in (
                ('select', 'Select', 'V', True, 'select cells and markers; drag markers to move'),
                ('paint', 'Paint', 'B', True, 'paint the picked metatile'),
                ('rect', 'Rect', 'R', False, ''), ('fill', 'Fill', 'F', False, ''),
                ('pick', 'Eyedrop', 'I', True, 'copy a cell\'s metatile (also right-click)'),
                ('walk', 'Walkability', 'W', True, 'click a cell to flip wall / walkable')):
            a = QAction(f'{text} ({key})', self)
            a.setCheckable(True)
            a.setShortcut(QKeySequence(key))
            a.setShortcutContext(Qt.WidgetWithChildrenShortcut)
            if tip:
                a.setToolTip(f'{text} ({key}) — {tip}')
            a.triggered.connect(lambda _c, n=name: self._set_tool(n))
            self.tool_group.addAction(a)
            if shown:
                self.tools.addAction(a)
            else:
                self.addAction(a)
            self.tool_actions[name] = a
            if name == 'select':
                # S98 r2 (user design): select a cell, press Add door — the
                # door appears there; double-click it to name / connect it
                self.act_add_door = QAction('+ Door (D)', self)
                self.act_add_door.setShortcut(QKeySequence('D'))
                self.act_add_door.setShortcutContext(Qt.WidgetWithChildrenShortcut)
                self.act_add_door.setToolTip('Add a door on the selected cell — then '
                                             'double-click it to name it and connect it to '
                                             'another door')
                self.act_add_door.triggered.connect(self._add_door_selected)
                self.tools.addAction(self.act_add_door)
                # S98 r2 (user: "Why is examine spot not a button?")
                self.act_add_examine = QAction('+ Examine (X)', self)
                self.act_add_examine.setShortcut(QKeySequence('X'))
                self.act_add_examine.setShortcutContext(Qt.WidgetWithChildrenShortcut)
                self.act_add_examine.setToolTip('Add an examine spot on the selected cell (a '
                                                'sign, a book, a pot…): the player presses A '
                                                'on or facing it. Double-click it to edit.')
                self.act_add_examine.triggered.connect(
                    lambda: self._add_on_selected(lambda c: self._add_spot(c, 'examine')))
                self.tools.addAction(self.act_add_examine)
        self.tool_actions['select'].setChecked(True)
        for seq, fn in ((',', lambda: self.select_state(self.state_idx - 1)),
                        ('.', lambda: self.select_state(self.state_idx + 1)),
                        ('PgUp', lambda: self.select_state(self.state_idx - 1)),
                        ('PgDown', lambda: self.select_state(self.state_idx + 1))):
            a = QAction(self)
            a.setShortcut(QKeySequence(seq))
            a.setShortcutContext(Qt.WidgetWithChildrenShortcut)
            a.triggered.connect(fn)
            self.addAction(a)
        for k in range(10):
            a = QAction(self)
            a.setShortcut(QKeySequence(str(k)))
            a.setShortcutContext(Qt.WidgetWithChildrenShortcut)
            a.triggered.connect(lambda _c, kk=k: self._jump_screen(kk))
            self.addAction(a)
        self.tools.addSeparator()
        self.brush_label = QLabel('  brush: none  ')
        self.tools.addWidget(self.brush_label)
        self.tools.addSeparator()
        self.layer_buttons = {}
        for name, text, tip in (('grid', 'Grid', 'cell grid (16px) + subtile grid'),
                                ('attr', 'Palettes', 'palette-slot overlay per cell'),
                                ('walk', 'Walk', 'walkability overlay: red = wall'),
                                ('markers', 'Markers', 'NPC / spawn / exit markers')):
            b = QToolButton()
            b.setText(text)
            b.setToolTip(tip)
            b.setCheckable(True)
            b.setChecked(name in ('grid', 'markers'))
            b.toggled.connect(lambda on, n=name: self.canvas.set_layer(n, on))
            if name == 'walk':
                # S98 r2 (user: "Why can I no longer change walkability by
                # clicking walk button and click on a tile?"): the Walk
                # button IS the walkability mode now — on = Walkability tool
                # (click a cell to flip wall / walkable), off = back to Select
                b.setToolTip('Walkability: click a cell to flip wall / walkable (red = wall). '
                             'Same as the W tool.')
                b.clicked.connect(self._walk_button)
            self.tools.addWidget(b)
            self.layer_buttons[name] = b
        self.tools.addSeparator()
        self.tools.addWidget(QLabel(' Zoom '))
        self.zoom_box = QComboBox()
        self.zoom_box.addItems([f'{z}×' for z in range(1, 7)])
        self.zoom_box.currentIndexChanged.connect(lambda i: self.canvas.set_zoom(i + 1))
        self.tools.addWidget(self.zoom_box)
        cv.addWidget(self.tools)

        sb = QHBoxLayout()
        sb.setContentsMargins(6, 0, 6, 0)
        self.screen_label = QLabel('Screen 0')
        self.screen_label.setStyleSheet('font-weight: bold;')
        sb.addWidget(self.screen_label)
        sb.addSpacing(16)
        sb.addWidget(QLabel('State'))
        self.state_prev = QToolButton()
        self.state_prev.setText('◀')
        self.state_prev.clicked.connect(lambda: self.select_state(self.state_idx - 1))
        self.state_box = QComboBox()
        self.state_box.setSizeAdjustPolicy(QComboBox.AdjustToContents)
        self.state_box.setMinimumContentsLength(18)
        self.state_box.currentIndexChanged.connect(self._state_box_changed)
        self.state_next = QToolButton()
        self.state_next.setText('▶')
        self.state_next.clicked.connect(lambda: self.select_state(self.state_idx + 1))
        sb.addWidget(self.state_prev)
        sb.addWidget(self.state_box)
        sb.addWidget(self.state_next)
        self.state_add = QToolButton()
        self.state_add.setText('+ Add state')
        self.state_add.setPopupMode(QToolButton.InstantPopup)
        m = QMenu(self.state_add)
        m.addAction('Duplicate this state (shares layout)', lambda: self._add_state(True, False))
        m.addAction('Duplicate this state with its OWN layout copy', lambda: self._add_state(True, True))
        m.addAction('Empty state (no NPCs / exits)', lambda: self._add_state(False, False))
        self.state_add.setMenu(m)
        self.state_del = QToolButton()
        self.state_del.setText('− Remove state')
        self.state_del.clicked.connect(self._remove_state)
        sb.addWidget(self.state_add)
        sb.addWidget(self.state_del)
        sb.addStretch(1)
        self.cap_label = QLabel('')
        sb.addWidget(self.cap_label)
        cv.addLayout(sb)
        self.shown_when = QLabel('')
        self.shown_when.setStyleSheet('color: #7fe07f; padding: 0 6px;')
        self.shown_when.setSizePolicy(QSizePolicy.Ignored, QSizePolicy.Preferred)
        self.shown_when.setToolTip('State rules that select this state (inspector → '
                                   'State rules). Rules run every time a screen loads.')
        cv.addWidget(self.shown_when)

        self.banner = QLabel('')
        self.banner.setStyleSheet('background: #5a4a10; color: #ffe08a; padding: 4px;')
        self.banner.setVisible(False)
        self.banner.setWordWrap(True)
        self.banner.setSizePolicy(QSizePolicy.Ignored, QSizePolicy.Preferred)
        cv.addWidget(self.banner)

        self.canvas = RoomCanvas(self.s)
        self.canvas.hoverInfo.connect(self._hover)
        self.canvas.brushPicked.connect(self._brush_picked)
        self.canvas.markerSelected.connect(self._marker_selected)
        self.canvas.markerMoveRequested.connect(self._move_marker)
        self.canvas.cellSelected.connect(self._cell_selected)
        self.canvas.walkFlipRequested.connect(self._flip_walk)
        self.canvas.zoomChanged.connect(lambda z: self.zoom_box.setCurrentIndex(z - 1))
        self.canvas.editRequested.connect(self._edit_requested)
        self.canvas.markerActivated.connect(self._marker_activated)
        self.canvas.toolChanged.connect(self._tool_changed)
        cv.addWidget(self.canvas, 1)
        self.status_line = QLabel(self.HELP)
        self.status_line.setStyleSheet('color: #bbb; padding: 2px 6px;')
        self.status_line.setToolTip(self.HELP)
        # S94b (user report: maximised window slid off-screen when hovering
        # the right pane): a QLabel's minimum width follows its text, and
        # hover strings are long — the growing minimum pushed the whole
        # window wider than the screen. Ignored = never asks for width.
        self.status_line.setSizePolicy(QSizePolicy.Ignored, QSizePolicy.Preferred)
        self.status_line.setMinimumWidth(0)
        cv.addWidget(self.status_line)

        # ---------- right: three foldable, resizable sections (S96 user QOL)
        right = QWidget()
        right.setMinimumWidth(380)
        right.setMaximumWidth(620)
        rv = QVBoxLayout(right)
        rv.setContentsMargins(4, 4, 4, 4)
        self.right_split = QSplitter(Qt.Vertical)
        self.right_split.setChildrenCollapsible(False)
        rv.addWidget(self.right_split)
        self._vocab_cache = {}
        self.picker_tabs = QTabWidget()
        # tab 1 — this room's tiles + my metatiles
        self.picker = MetatilePicker(sections=('found', 'custom'))
        self.picker.brushSelected.connect(self._brush_selected)
        self.picker.hoverInfo.connect(self._hover)
        self.picker.editRequested.connect(self._edit_metatile)
        self.picker.removeRequested.connect(self._remove_metatile)
        pscroll = QScrollArea()
        pscroll.setWidgetResizable(True)
        pscroll.setWidget(self.picker)
        self.picker_tabs.addTab(pscroll, 'This room')
        # tab 2 — borrow from another room (S95: separated on user request)
        btab = QWidget()
        bl = QVBoxLayout(btab)
        bl.setContentsMargins(0, 0, 0, 0)
        frow = QHBoxLayout()
        frow.addWidget(QLabel('Room:'))
        self.foreign_box = QComboBox()
        self.foreign_box.setSizeAdjustPolicy(QComboBox.AdjustToContents)
        self.foreign_box.setToolTip('Show another room\'s tiles, drawn with THIS room\'s '
                                    'palettes. Same tileset: click = brush. Other tileset: '
                                    'click imports the 4 subtiles into this room\'s tileset.')
        self.foreign_box.currentIndexChanged.connect(lambda _i: self._refresh_foreign())
        frow.addWidget(self.foreign_box, 1)
        bl.addLayout(frow)
        self.picker_foreign = MetatilePicker(sections=('foreign',))
        self.picker_foreign.brushSelected.connect(self._brush_selected)
        self.picker_foreign.hoverInfo.connect(self._hover)
        self.picker_foreign.importRequested.connect(self._import_metatile)
        fscroll = QScrollArea()
        fscroll.setWidgetResizable(True)
        fscroll.setWidget(self.picker_foreign)
        bl.addWidget(fscroll, 1)
        self.picker_tabs.addTab(btab, 'Borrow')
        # tab 3 — the tileset's 128 slots (P3.3c, S96)
        self.tileset_map = TilesetMap()
        self.tileset_map.hoverInfo.connect(self._hover)
        self.tileset_map.highlightTile.connect(self._highlight_tile)
        self.tileset_map.releaseToggled.connect(self._release_vocab)
        self.tileset_map.ownCopyRequested.connect(self._own_tileset)
        self.tileset_map.purgeRequested.connect(self._purge_metatiles)
        tscroll = QScrollArea()
        tscroll.setWidgetResizable(True)
        tscroll.setWidget(self.tileset_map)
        self.picker_tabs.addTab(tscroll, 'Tileset')
        self.picker_tabs.setMinimumHeight(120)
        self.sec_tiles = Section('Metatiles', self.picker_tabs, 'rooms_metatiles',
                                 expanded=True, remember=False)
        self.sec_tiles.setToolTip('click = brush · corner dot: red wall / green walkable')
        self.right_split.addWidget(self.sec_tiles)
        palbox = QWidget()
        pl = QVBoxLayout(palbox)
        pl.setContentsMargins(0, 0, 0, 0)
        self.palettes = PalettePanel()
        self.palettes.colorEdited.connect(self._color_edited)
        self.palettes.hoverInfo.connect(self._hover)
        self.palettes.makeEditableRequested.connect(self._palette_make_editable)
        pl.addWidget(self.palettes, 0, Qt.AlignLeft)
        prow = QHBoxLayout()
        self.pal_sys = QCheckBox('show system 4-7')
        self.pal_sys.setToolTip('Slots 4-7 are the shared system palettes (HUD, menus, '
                                'monsters) — shown read-only.')
        self.pal_sys.toggled.connect(self.palettes.set_show_system)
        self.pal_free1 = QCheckBox('own colour 1')
        self.pal_free1.setToolTip(
            'Colour 1 of slots 0-3 is normally forced to cream ($6BFF) by the engine. '
            'Ticked, this palette keeps its own colour 1 in this custom room '
            '(FreeColor1Hook, S96) — three colours of your own per slot.')
        self.pal_free1.toggled.connect(self._free1_toggled)
        prow.addWidget(self.pal_sys)
        prow.addWidget(self.pal_free1)
        prow.addStretch(1)
        pl.addLayout(prow)
        pl.addStretch(1)
        self.sec_pal = Section('BG palettes', palbox, 'rooms_palettes',
                               expanded=False, remember=False)
        self.sec_pal.setToolTip('double-click a colour to edit')
        self.right_split.addWidget(self.sec_pal)
        self.inspector = Inspector()
        self.inspector.thresholdEdited.connect(self._threshold_edited)
        self.inspector.paletteChosen.connect(self._palette_chosen)
        self.inspector.localizeRequested.connect(self._localize)
        self.inspector.nameEdited.connect(self._rename_to)
        self.inspector.addRedirectRequested.connect(self._add_redirect)
        self.inspector.removeRedirectRequested.connect(self._remove_redirect)
        self.inspector.routeDoorRequested.connect(self._route_door)
        self.inspector.statePaletteChosen.connect(self._state_palette_chosen)
        self.inspector.addExitRequested.connect(self._add_exit)
        self.inspector.removeExitRequested.connect(self._remove_exit)
        self.inspector.tilesetChangeRequested.connect(self._change_tileset)
        # S97: NPC inspector (P3.5) + state rules (P3.5a)
        self.inspector.addNpcRequested.connect(self._add_npc)
        # S98 (P3.7): doors, examine spots / step triggers
        self.inspector.addDoorRequested.connect(self._add_door)
        self.inspector.addSpotRequested.connect(self._add_spot)
        self.inspector.removeDoorRequested.connect(self._remove_door)
        self.inspector.goDoorRequested.connect(self._go_door_here)
        self.inspector.rules.rulesEdited.connect(self._rules_edited)
        self.sec_insp = Section('Room / screen / selection', self.inspector, 'rooms_inspector',
                                expanded=False, remember=False)
        self.right_split.addWidget(self.sec_insp)
        # S97 r2: the NPC form is its own foldable section (user request);
        # S98: the section holds whichever OBJECT is selected — NPC, door,
        # one-way exit, examine spot / step trigger
        from editor2.app.rooms.npc_panel import NpcPanel
        from editor2.app.rooms.object_panels import DoorPanel, SpotPanel, TeleportPanel
        npcbox = QWidget()
        nl = QVBoxLayout(npcbox)
        nl.setContentsMargins(0, 0, 0, 0)
        self.npc_hint = QLabel('Nothing selected. Click an NPC, a door (D), an examine spot (X) '
                               'or a step trigger (T) with the Select tool (V) — or click an '
                               'empty cell and use the "Add … here" buttons in Room / screen / '
                               'selection.')
        self.npc_hint.setWordWrap(True)
        self.npc_hint.setStyleSheet('color: #aaa;')
        nl.addWidget(self.npc_hint)
        npc = self.npc_panel = NpcPanel()
        npc.setTitle('')
        npc.setVisible(False)
        nl.addWidget(npc)
        self.door_panel = DoorPanel()
        self.door_panel.setVisible(False)
        nl.addWidget(self.door_panel)
        self.tele_panel = TeleportPanel()
        self.tele_panel.setVisible(False)
        nl.addWidget(self.tele_panel)
        self.spot_panel = SpotPanel()
        self.spot_panel.setVisible(False)
        nl.addWidget(self.spot_panel)
        nl.addStretch(1)
        nscroll = QScrollArea()
        nscroll.setWidgetResizable(True)
        nscroll.setWidget(npcbox)
        self.npc_scroll = nscroll
        self.inspector.npc = _ObjectPanels(self)
        npc.fieldsEdited.connect(self._npc_fields)
        npc.spriteRequested.connect(self._npc_sprite)
        npc.newTalkRequested.connect(self._npc_new_talk)
        npc.editTalkRequested.connect(self._npc_edit_talk)
        npc.presenceToggled.connect(self._npc_presence)
        npc.deleteRequested.connect(self._npc_delete)
        dp = self.door_panel
        dp.goRequested.connect(self._go_end)
        dp.statesToggled.connect(self._door_states)
        dp.deleteRequested.connect(self._door_delete)
        dp.reaimRequested.connect(self._door_reaim)
        dp.editRequested.connect(lambda: self._edit_door(getattr(self, '_sel_door', None)))
        dp.disconnectRequested.connect(self._door_disconnect)
        tp = self.tele_panel
        tp.statesToggled.connect(self._exit_states)
        tp.deleteRequested.connect(self._exit_delete)
        tp.goRequested.connect(self._go_end)
        sp = self.spot_panel
        sp.fieldsEdited.connect(self._spot_fields)
        sp.newTalkRequested.connect(self._npc_new_talk)
        sp.editTalkRequested.connect(self._npc_edit_talk)
        sp.presenceToggled.connect(self._npc_presence)
        sp.deleteRequested.connect(self._npc_delete)
        self.sec_npc = Section('Object (NPC / door / spot)', nscroll, 'rooms_npc',
                               expanded=False, remember=False)
        self.right_split.addWidget(self.sec_npc)
        self._sel_exit = None           # S98: index of the selected exit row
        self.right_split.setStretchFactor(0, 3)
        self.right_split.setStretchFactor(1, 0)
        self.right_split.setStretchFactor(2, 4)
        self.right_split.setStretchFactor(3, 4)
        from PySide6.QtCore import QSettings
        st = QSettings('dwm1_disassembly', 'DWM1Editor').value('ui/rooms_right_split4')
        if st:
            self.right_split.restoreState(st)
        self.right_split.splitterMoved.connect(lambda *_a: QSettings(
            'dwm1_disassembly', 'DWM1Editor').setValue('ui/rooms_right_split4',
                                                      self.right_split.saveState()))
        for sec in (self.sec_tiles, self.sec_pal, self.sec_insp, self.sec_npc):
            sec.toggled.connect(lambda _on: self._relayout_right())
        self.pal_sys.toggled.connect(lambda _on: self._relayout_right())
        self._relayout_right()          # S97 r2: start folded (only Metatiles open)

        split = QSplitter()
        split.addWidget(left)
        split.addWidget(centre)
        split.addWidget(right)
        split.setStretchFactor(1, 1)
        split.setSizes([340, 760, 420])
        root = QHBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.addWidget(split)

    # ------------------------------------------------------------ browser
    def _fill_rooms(self, keep=None):
        self.vanilla_list.blockSignals(True)
        if self.vanilla_list.count() == 0:
            for mid, name, scr in self.s.renderer.vanilla_rooms():
                it = QListWidgetItem(f'${mid:02X}   {name}   ({len(scr)} scr)')
                it.setData(Qt.UserRole, mid)
                self.vanilla_list.addItem(it)
        self.vanilla_list.blockSignals(False)
        self.room_list.blockSignals(True)
        self.room_list.clear()
        rooms = self.s.doc.rooms
        self.rooms_header.setText(f'Custom rooms ({len(rooms)})')
        sel = -1
        for i, r in enumerate(rooms):
            mid = val(r.get('mapID', 0))
            if r.get('placeholder'):
                continue
            scr = r.get('screens') or {}
            nst = sum(max(1, len(v.get('states') or [])) for v in scr.values())
            tag = f"   ({len(scr)} scr" + (f", {nst} states)" if nst > len(scr) else ')')
            it = QListWidgetItem(f"${mid:02X}   {self.s.doc.room_name(r)}{tag}")
            it.setData(Qt.UserRole, r.get('id'))
            self.room_list.addItem(it)
            if keep and r.get('id') == keep:
                sel = self.room_list.count() - 1
        self.room_list.blockSignals(False)
        if sel >= 0:
            self.room_list.setCurrentRow(sel)
            self._room_picked(self.room_list.currentItem())
        elif keep is None and self.room_list.count():
            self.room_list.setCurrentRow(0)
            self._room_picked(self.room_list.currentItem())
        elif self.room_list.count() == 0 and self.vanilla_list.count() and self.vanilla_mid is None:
            self.vanilla_list.setCurrentRow(0)
            self._vanilla_picked(self.vanilla_list.currentItem())

    def _room_picked(self, item, _prev=None):
        if not item:
            return
        rid = item.data(Qt.UserRole)
        self.vanilla_list.blockSignals(True)
        self.vanilla_list.setCurrentRow(-1)
        self.vanilla_list.blockSignals(False)
        self.vanilla_mid = None
        if rid != self.room_id:
            self.room_id = rid
            room = self.s.doc.room(rid)
            keys = self.s.doc.screen_keys(room)
            self.key = keys[0] if keys else 0
            self.state_idx = 0
        self._show()

    def _vanilla_picked(self, item, _prev=None):
        if not item:
            return
        mid = item.data(Qt.UserRole)
        self.room_list.blockSignals(True)
        self.room_list.setCurrentRow(-1)
        self.room_list.blockSignals(False)
        self.room_id = None
        if mid != self.vanilla_mid:
            self.vanilla_mid = mid
            scr = next(s for m, _n, s in self.s.renderer.vanilla_rooms() if m == mid)
            self.key = scr[0]
            self.state_idx = 0
        self._show()

    def current_room(self):
        return self.s.doc.room(self.room_id) if self.room_id else None

    # ----------------------------------------------------------- display
    def _show(self):
        # the canvas drops its selection on every (re)show — so does the
        # NPC form (S97; an edit re-selects through _after_npc_edit)
        self._sel_npc = None
        self.inspector.show_selection(None)
        if self.vanilla_mid is not None:
            self._show_vanilla()
            return
        room = self.current_room()
        if room is None:
            self.canvas.clear()
            self.minimap.set_screens({}, 0)
            self.state_box.clear()
            return
        if not room.get('screens'):
            self.canvas.clear()
            self.minimap.set_screens({}, 0)
            self.banner.setText('Room declares no screens — add one on the mini-map.')
            self.banner.setVisible(True)
            self.inspector.show_room(self.s.doc, self.s.renderer, room, self.key, 0)
            self.state_box.clear()
            return
        keys = self.s.doc.screen_keys(room)
        if self.key not in keys:
            self.key = keys[0]
        nst = len(self.s.doc.states(room, self.key))
        self.state_idx = max(0, min(self.state_idx, nst - 1))
        try:
            self.canvas.show_custom(self.room_id, self.key, self.state_idx)
        except Exception as e:
            self.banner.setText(f'Cannot render this screen: {e}')
            self.banner.setVisible(True)
            self.status.emit(str(e))
            return
        self._set_state_widgets(True)
        self._refresh_side()
        self._refresh_minimap()

    def _show_vanilla(self):
        mid = self.vanilla_mid
        scr = next(s for m, _n, s in self.s.renderer.vanilla_rooms() if m == mid)
        if self.key not in scr:
            self.key = scr[0]
        nst = len(self.s.renderer.vanilla_steps(mid, self.key))
        self.state_idx = max(0, min(self.state_idx, nst - 1))
        try:
            self.canvas.show_vanilla(mid, self.key, self.state_idx)
        except Exception as e:
            self.banner.setText(f'Cannot render vanilla ${mid:02X}: {e}')
            self.banner.setVisible(True)
            return
        self._set_state_widgets(False)
        for w_ in (self.state_prev, self.state_next, self.state_box):
            w_.setEnabled(True)
        self.state_box.blockSignals(True)
        self.state_box.clear()
        for i in range(nst):
            self.state_box.addItem(f'vanilla state {i} of {nst}')
        self.state_box.setCurrentIndex(self.state_idx)
        self.state_box.blockSignals(False)
        self.state_prev.setEnabled(self.state_idx > 0)
        self.state_next.setEnabled(self.state_idx < nst - 1)
        self.screen_label.setText(f'Screen {self.key}  (col {self.key % 4}, row {self.key // 4})')
        self.cap_label.setText('')
        self.shown_when.setText('')
        self.shown_when.setVisible(False)
        self.banner.setText(f'Vanilla room ${mid:02X} {self.s.renderer.vanilla_name(mid)} — '
                            'read-only. "Make editable" clones it into your project; '
                            'the original stays untouched.')
        self.banner.setVisible(True)
        gfx, pals = self.canvas.gfx, self.canvas.pals
        self.picker.set_context(self.s.renderer, gfx.sheet, pals, gfx.threshold)
        self.picker_foreign.set_context(self.s.renderer, gfx.sheet, pals, gfx.threshold)
        self.picker.set_lists(self._harvest(), [])
        self.picker.set_flags({}, '')
        self.tileset_map.clear()
        self.picker_tabs.setTabText(2, 'Tileset')
        self._fill_foreign_box()
        self._refresh_foreign()
        self.palettes.set_palettes(pals, None, None)
        self.pal_free1.setEnabled(False)
        self.inspector.show_vanilla(self.s.renderer, mid, self.key)
        imgs = {}
        for k in scr:
            try:
                imgs[k] = self.s.renderer.render_vanilla_screen(mid, k, 1)
            except Exception:
                pass
        self.minimap.set_screens(imgs, self.key)

    def _set_state_widgets(self, on):
        for w in (self.state_prev, self.state_next, self.state_add, self.state_del, self.state_box):
            w.setEnabled(on)

    @staticmethod
    def _harvest_grid(tiles, attr, seen, out):
        for cy in range(8):
            for cx in range(10):
                mt = metatile_at(tiles, attr, cx, cy)
                key = metatile_key(mt)
                if key not in seen:
                    seen.add(key)
                    out.append(mt)

    def _vanilla_vocab(self, mid):
        """Every metatile a vanilla room uses on any screen/step (cached)."""
        if mid not in self._vocab_cache:
            r = self.s.renderer
            seen, out = set(), []
            try:
                screens = next(sc for m, _n, sc in r.vanilla_rooms() if m == mid)
            except StopIteration:
                screens = []
            for k in screens:
                for st in range(len(r.vanilla_steps(mid, k))):
                    try:
                        tiles = r.vanilla_screen_grid(mid, k, st)
                        attr = r.vanilla_attr_grid(mid, k, st)
                    except Exception:
                        continue
                    self._harvest_grid(tiles, attr, seen, out)
            self._vocab_cache[mid] = out
        return self._vocab_cache[mid]

    def _room_vocab(self, room):
        """S95: the room's WHOLE vocabulary — every metatile on any of its
        screens/states now, plus everything its vanilla source room uses —
        so a tile painted over never disappears from the picker."""
        seen, out = set(), []
        r = self.s.renderer
        for k in self.s.doc.screen_keys(room):
            for n in range(len(self.s.doc.states(room, k))):
                try:
                    st = r.screen_state(room, k, n)
                    tiles, _lid = r.layout_grid(st['layout'])
                    attr, _note = r.attr_grid(room, k, n)
                except Exception:
                    continue
                self._harvest_grid(tiles, attr or [[0] * 20 for _ in range(16)], seen, out)
        src = val(room.get('source_mapID', 0)) if room.get('source_mapID') is not None else None
        if src is not None and src < 0x6B:
            for mt in self._vanilla_vocab(src):
                key = metatile_key(mt)
                if key not in seen:
                    seen.add(key)
                    out.append(mt)
        # S96: the slots behind the vocabulary are protected by
        # Document.tile_usage (derived from the source room, releasable) —
        # no session registration here any more
        return out

    def _harvest(self):
        room = self.current_room()
        if room is not None:
            return self._room_vocab(room)
        if self.vanilla_mid is not None:
            return self._vanilla_vocab(self.vanilla_mid)
        return []

    def _fill_foreign_box(self):
        if self.foreign_box.count():
            return
        self.foreign_box.blockSignals(True)
        self.foreign_box.addItem('(none)', None)
        for mid, name, _scr in self.s.renderer.vanilla_rooms():
            self.foreign_box.addItem(f'${mid:02X}  {name}', int(mid))
        self.foreign_box.blockSignals(False)

    def _refresh_foreign(self):
        sel = self.foreign_box.currentData()
        room = self.current_room()
        if sel is None or self.canvas.gfx is None:
            self.picker_foreign.set_foreign('', [], None, 0, True)
            return
        r = self.s.renderer
        mid = int(sel)
        gfx = r.vanilla_gfx(mid)
        same = (bytes(gfx.sheet[:2048]) == bytes(self.canvas.gfx.sheet[:2048]))
        title = r.vanilla_name(mid)
        if room is None:
            same = same  # vanilla view: brush only when the sheets match
        self.picker_foreign.set_foreign(title, self._vanilla_vocab(mid), gfx.sheet, gfx.threshold, same)

    def _import_metatile(self, mt):
        room = self.current_room()
        sel = self.foreign_box.currentData()
        if room is None or sel is None:
            QMessageBox.information(self, 'Import', 'Select a custom room first — a vanilla '
                                    'room is read-only (clone it to import tiles).')
            return
        r = self.s.renderer
        mid = int(sel)
        gfx = r.vanilla_gfx(mid)
        src_sheet, src_thr = bytes(gfx.sheet[:2048]), gfx.threshold
        own = bytes(self.canvas.gfx.sheet[:2048])
        name = f"{r.vanilla_name(mid)} {mt['tiles']}"
        rid = room['id']
        cmd = C.SnapshotCommand(
            self.s, f'Import metatile from {r.vanilla_name(mid)}',
            lambda doc: doc.import_metatile(doc.room(rid), mt, src_sheet, src_thr,
                                            own_sheet=own, name=name))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Import failed', str(cmd.error))
            return
        if cmd.result is not None:
            self._brush_selected(cmd.result)

    def _refresh_side(self):
        room = self.current_room()
        if room is None or self.canvas.tiles is None:
            return
        sts = self.s.doc.states(room, self.key)
        self.state_box.blockSignals(True)
        self.state_box.clear()
        for i, st in enumerate(sts):
            self.state_box.addItem(f"{i}: {st.get('comment', '') or 'state'}"[:40])
        self.state_box.setCurrentIndex(self.state_idx)
        self.state_box.blockSignals(False)
        self.state_prev.setEnabled(self.state_idx > 0)
        self.state_next.setEnabled(self.state_idx < len(sts) - 1)
        self.state_del.setEnabled(len(sts) > 1)
        self.screen_label.setText(f'Screen {self.key}  (col {self.key % GRID_COLS}, row {self.key // GRID_COLS})')
        rules = self.s.doc.rules_for_state(room, self.key, self.state_idx)
        self.shown_when.setVisible(bool(rules))
        self.shown_when.setText(('State shown when: ' + '  |  '.join(
            (self.s.doc.describe_rule(ru) if ru.get('when') else 'no rule above matches')
            for _i, ru in rules)) if rules else '')
        n, cap = self.s.doc.state_capacity(room, self.key, self.state_idx)
        self.cap_label.setText(f'NPCs {n}/{cap}')
        self.cap_label.setStyleSheet('color:#ff6060;' if n > cap else
                                     'color:#e0b040;' if n == cap else 'color:#bbb;')
        msgs = []
        if not self.canvas.is_editable():
            msgs.append('This state uses a VANILLA layout reference — it renders but cannot '
                        'be painted. Use "Make editable" in the inspector.')
        elif self.canvas.lid:
            users = [u for u in self.s.doc.layout_users(self.canvas.lid) if u[3] == 'layout']
            if len(users) > 1:
                msgs.append(f"Layout '{self.canvas.lid}' is shared by {len(users)} screens/states "
                            '— painting changes all of them.')
        if self.canvas.attr_note.startswith('WARNING'):
            msgs.append(self.canvas.attr_note)
        self.banner.setText('\n'.join(msgs))
        self.banner.setVisible(bool(msgs))
        gfx, pals = self.canvas.gfx, self.canvas.pals
        self.picker.set_context(self.s.renderer, gfx.sheet, pals, gfx.threshold)
        self.picker_foreign.set_context(self.s.renderer, gfx.sheet, pals, gfx.threshold)
        self.picker.set_lists(self._harvest(), self.s.doc.metatiles(self.s.doc.tileset_key(room)))
        self._refresh_slots(room)
        self._fill_foreign_box()
        self._refresh_foreign()
        if self.canvas.brush:
            self.picker.select_metatile(self.canvas.brush)
        pid, words = self.s.renderer.room_palettes_555(room, self.key, self.state_idx)
        free1 = bool(words) and bool(self.s.doc.palette(pid).get('free_color1'))
        self.palettes.set_palettes(pals, words, pid if words else None, free1=free1)
        self.pal_free1.blockSignals(True)
        self.pal_free1.setChecked(free1)
        self.pal_free1.setEnabled(bool(words))
        self.pal_free1.blockSignals(False)
        self.inspector.show_room(self.s.doc, self.s.renderer, room, self.key, self.state_idx)
        self._update_brush_label()

    # ---------------------------------------------- tileset slots (P3.3c)
    def _refresh_slots(self, room):
        """Slot map + per-side free counts (picker header, tab title) +
        'graphic may change' flags on the vocabulary metatiles."""
        gfx = self.canvas.gfx
        if gfx is None:
            return
        doc = self.s.doc
        tid = doc.tileset_key(room)
        self.tileset_map.set_room(doc, self.s.renderer, room, gfx.sheet,
                                  self.canvas.pals, gfx.threshold)
        fc = doc.free_counts(tid, gfx.threshold)
        self.picker_tabs.setTabText(2, f"Tileset ({fc['total']} free)")
        flags = {}
        for i, u in enumerate(self.tileset_map.usage or []):
            if u['placed']:
                continue
            if u['vocab'] and u['changed']:
                flags[i] = 'changed'
            elif u.get('released'):
                flags[i] = 'released'
        self.picker.set_flags(flags, f"{fc['wall']} wall / {fc['walkable']} walkable slots free")

    def _change_tileset(self):
        room = self.current_room()
        if room is None:
            return
        dlg = TilesetDialog(self.s.doc, self.s.renderer, room, self.canvas.pals, self)
        if dlg.exec() != QDialog.Accepted:
            return
        kind, value, thr = dlg.choice()
        rid = room['id']
        cmd = C.SnapshotCommand(self.s, f'Change tileset ({kind})',
                                lambda doc: doc.set_room_tileset(rid, kind, value, thr))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Change tileset', str(cmd.error))

    def _purge_metatiles(self, kind):
        """S98 r2: drop every unused own / borrowed metatile of this room's
        tileset (one undo step)."""
        room = self.current_room()
        if room is None:
            return
        tid = self.s.doc.tileset_key(room)
        thr = val(room['record']['collision_threshold'])
        n, fr = self.s.doc.purge_preview(tid, kind, thr)
        if not n:
            return
        cmd = C.SnapshotCommand(self.s, f'Purge {n} unused {kind} metatiles',
                                lambda doc: doc.purge_unused_metatiles(tid, kind))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Purge', str(cmd.error))
            return
        self._show()
        self.status_line.setText(f"Purged {n} unused {kind} metatiles — {fr['walkable']} walkable "
                                 f"and {fr['wall']} wall slots free again (undo restores them).")

    def _own_tileset(self):
        """S98 r2: this room stops sharing its tileset (private copy)."""
        room = self.current_room()
        if room is None:
            return
        rid = room['id']
        cmd = C.SnapshotCommand(self.s, 'Own copy of the tileset',
                                lambda doc: doc.set_room_tileset(rid, 'own'))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Own copy of the tileset', str(cmd.error))
        self._show()

    def _relayout_right(self):
        """Folded sections shrink to their header; the palette section takes
        its natural height; Metatiles and the inspector share the rest in
        their current ratio (S96 QOL)."""
        from PySide6.QtCore import QTimer
        QTimer.singleShot(0, self._do_relayout_right)

    def _do_relayout_right(self):
        sp = self.right_split
        secs = [self.sec_tiles, self.sec_pal, self.sec_insp, self.sec_npc]
        sizes = sp.sizes()
        total = sum(sizes) or sp.height()
        head = self.sec_tiles.button.sizeHint().height() + 6
        pal_h = (self.palettes.sizeHint().height() + self.pal_sys.sizeHint().height()
                 + head + 12) if self.sec_pal.is_expanded() else head
        self.sec_pal.setMinimumHeight(pal_h if self.sec_pal.is_expanded() else 0)
        flexible = (0, 2, 3)
        flex = [i for i in flexible if secs[i].is_expanded()]
        rest = max(0, total - pal_h - sum(head for i in flexible if i not in flex))
        new = [head, pal_h, head, head]
        if flex:
            # a section that was folded (header-sized) opens with an equal
            # share instead of its old header height (S97 r2)
            share = rest // len(flex)
            want = {i: (sizes[i] if sizes[i] > 150 else share) for i in flex}
            base = sum(max(want[i], 1) for i in flex)
            for i in flex:
                new[i] = int(rest * max(want[i], 1) / base)
        sp.setSizes(new)

    def _free1_toggled(self, on):
        room = self.current_room()
        pid = self.palettes.pid
        if room is None or not pid:
            return
        self.s.undo.push(C.SnapshotCommand(
            self.s, ('Own' if on else 'Engine') + f' colour 1 for {pid}',
            lambda doc: doc.set_palette_free1(pid, on)))

    def _highlight_tile(self, i):
        self.canvas.set_highlight(None if i < 0 else i)

    def _release_vocab(self, on):
        room = self.current_room()
        if room is None:
            return
        tid = self.s.doc.tileset_key(room)
        self.s.undo.push(C.SnapshotCommand(
            self.s, ('Release' if on else 'Protect') + ' tileset vocabulary',
            lambda doc: doc.set_released(tid, on)))

    def _refresh_minimap(self):
        room = self.current_room()
        imgs = {}
        for k in self.s.doc.screen_keys(room):
            try:
                imgs[k] = self.s.renderer.render_screen(room, k, 0, 1)
            except Exception:
                pass
        self.minimap.set_screens(imgs, self.key)

    # ------------------------------------------------------------ events
    def _on_structure(self):
        keep = self.room_id
        if keep:
            try:
                self.s.doc.room(keep)
            except KeyError:
                keep = None
                self.room_id = None
        self._fill_rooms(keep=keep)
        if self.vanilla_mid is not None and self.room_id is None:
            self._show()

    def _on_layout(self, lid):
        if self.room_id:
            self._refresh_minimap()
            room = self.current_room()
            self.picker.set_lists(self._harvest(), self.s.doc.metatiles(self.s.doc.tileset_key(room)))
            self._refresh_slots(room)
            if self.canvas.brush:
                self.picker.select_metatile(self.canvas.brush)

    def select_screen(self, key):
        self.key = int(key)
        self.state_idx = 0
        self._show()

    def _jump_screen(self, key):
        if self.vanilla_mid is not None:
            scr = next(s for m, _n, s in self.s.renderer.vanilla_rooms() if m == self.vanilla_mid)
            if key in scr:
                self.select_screen(key)
            return
        room = self.current_room()
        if room and key in self.s.doc.screen_keys(room):
            self.select_screen(key)

    def select_state(self, idx):
        if self.vanilla_mid is not None:
            n = len(self.s.renderer.vanilla_steps(self.vanilla_mid, self.key))
            self.state_idx = max(0, min(int(idx), n - 1))
            self._show()
            return
        room = self.current_room()
        if room is None:
            return
        n = len(self.s.doc.states(room, self.key))
        self.state_idx = max(0, min(int(idx), n - 1))
        self._show()

    def _state_box_changed(self, i):
        if i >= 0 and i != self.state_idx and (self.room_id or self.vanilla_mid is not None):
            self.select_state(i)

    def _set_tool(self, name):
        self.canvas.set_tool(name)
        self.canvas.setFocus()

    def _tool_changed(self, name):
        self.tool_actions[name].setChecked(True)
        b = self.layer_buttons.get('walk')
        if b is not None and b.isChecked() != (name == 'walk'):
            b.blockSignals(True)
            b.setChecked(name == 'walk')
            b.blockSignals(False)
            self.canvas.set_layer('walk', name == 'walk')

    def _walk_button(self, on):
        self._set_tool('walk' if on else 'select')

    def _update_brush_label(self):
        b = self.canvas.brush
        self.brush_label.setText('  brush: none  ' if not b else
                                 f"  brush: {b.get('name', 'metatile')} {b['tiles']} pal {b.get('pal')}  ")

    def _brush_selected(self, mt):
        self.canvas.set_brush(mt)
        self._update_brush_label()
        if self.canvas.tool in ('select', 'walk', 'pick'):
            self._set_tool('paint')
        self.canvas.setFocus()

    def _brush_picked(self, mt):
        self.picker.select_metatile(mt)
        self._update_brush_label()
        if self.canvas.tool in ('select', 'pick'):
            self._set_tool('paint')

    def _hover(self, text):
        self.status_line.setText(text or self.HELP)

    def _marker_selected(self, sel):
        self.inspector.show_selection(sel, editable=self.current_room() is not None)
        self._sel_npc = None
        self._sel_exit = None
        if sel:
            self.status_line.setText(sel['label'])
            ref = sel.get('ref')
            if sel['kind'] == 'npc' and ref and ref[0] == 'npc':
                self._show_npc_panel(ref[1], ref[2])
            elif sel['kind'] in ('examine', 'step', 'spawn') and ref and ref[0] == 'npc':
                self._show_spot_panel(ref[1], ref[2])
            elif sel['kind'] in ('door', 'door_open', 'door_dead') and ref:
                self._show_door_panel(ref)
            elif sel['kind'] == 'exit' and ref and ref[0] == 'exit':
                self._show_exit_panel(ref[1], ref[2])

    def _show_object(self, panel):
        for p in (self.npc_panel, self.door_panel, self.tele_panel, self.spot_panel):
            p.setVisible(p is panel)
        self.npc_hint.setVisible(panel is None)
        if panel is not None:
            self.sec_npc.set_expanded(True)

    # ------------------------------------------------- doors (S98, P3.7)
    def _door_id_of_ref(self, ref):
        """Door object id behind a canvas marker ref (custom door row, or a
        vanilla door's redirect row / plain vanilla exit in a vanilla view)."""
        if not ref:
            return None
        e = ref[2] if isinstance(ref[2], dict) else {}
        if ref[0] == 'exit' and e.get('door'):
            return e['door']
        if ref[0] == 'redirect':
            d = e.get('door')
            if d and self.s.doc.parse_vanilla_door_id(d):
                return d
            if self.vanilla_mid is not None:
                return self.s.doc.vanilla_door_id(self.vanilla_mid, self.key,
                                                  val(e['x']), val(e['y']))
        if ref[0] == 'exit' and self.vanilla_mid is not None:
            return self.s.doc.vanilla_door_id(self.vanilla_mid, self.key,
                                              val(e['x']), val(e['y']))
        return None

    def _show_door_panel(self, ref):
        doc = self.s.doc
        did = self._door_id_of_ref(ref)
        me = doc.door_end(did) if did else None
        if me is None:
            return
        room = self.current_room()
        pres, note = None, ''
        if me['kind'] == 'room' and room is not None:
            self._sel_exit = ref[1]
            pres = doc.exit_presence(room, self.key, self.state_idx, ref[1])
            c = doc.edge_conflict(room, self.key, me['x'], me['y'])
            if c and c[0] != 'bottom':
                note = (f'This {c[0]} edge scrolls into screen {c[1]} — the door never fires '
                        '(PyBoy S98). Drag it off the edge.')
        self._sel_door = did
        self.door_panel.show_door(doc, self.s.renderer, me, doc.door_partner(did), pres, note)
        self.door_panel.btn_del.setEnabled(me['kind'] == 'room')
        self._show_object(self.door_panel)

    def _marker_activated(self, sel):
        """S98 r2: double-click — a door (custom, or a vanilla door in a
        vanilla view) opens its name / connection dialog."""
        if not sel:
            return
        ref = sel.get('ref')
        if sel['kind'] in ('door', 'door_open', 'door_dead') or \
                (self.vanilla_mid is not None and sel['kind'] in ('exit', 'redirect')):
            did = self._door_id_of_ref(ref)
            if did:
                self._edit_door(did)
            return
        self._marker_selected(sel)
        if sel['kind'] in ('npc', 'examine', 'step', 'spawn') and self.current_room() is not None \
                and self._sel_npc is not None:
            self._npc_edit_talk()            # double-click = edit what it says / does

    def _show_exit_panel(self, index, row):
        room = self.current_room()
        if room is not None:
            self._sel_exit = index
            pres = self.s.doc.exit_presence(room, self.key, self.state_idx, index)
            note = ''
            c = self.s.doc.edge_conflict(room, self.key, val(row['x']), val(row['y']))
            if c and c[0] != 'bottom':
                note = (f'This {c[0]} edge scrolls into screen {c[1]} — the exit never fires '
                        '(PyBoy S98).')
            self.tele_panel.show_exit(self.s.doc, self.s.renderer, row, pres, True, note)
        else:
            self.tele_panel.show_exit(self.s.doc, self.s.renderer, row, None, False,
                                      'Vanilla door. Double-click it to connect it to one of '
                                      'your doors (two-way), or use "Route this door into a '
                                      'custom room…" for one-way.')
        self._show_object(self.tele_panel)

    def _door_op(self, label, fn):
        cmd = C.SnapshotCommand(self.s, label, fn)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            return None
        return cmd

    def _add_door_selected(self):
        self._add_on_selected(self._add_door)

    def _add_on_selected(self, fn):
        cell = self.canvas.selected_cell
        if self.current_room() is None:
            self._edit_requested()
            return
        if cell is None:
            self.status_line.setText('Select a cell first (Select tool, click a cell), then '
                                     'press the + button.')
            return
        fn(cell)

    def _dead_edge(self, cell, what='door'):
        """S98 r2 (user: "I walk onto door but nothing happens"): an exit on
        a screen edge that borders another screen of the room NEVER fires —
        pushing into that edge scrolls (PyBoy S98). Returns the message, or
        None when the cell is fine."""
        room = self.current_room()
        c = self.s.doc.edge_conflict(room, self.key, *cell) if room else None
        if not c or c[0] == 'bottom':
            return None
        x, y = cell
        inward = {'left': (x + 1, y), 'right': (x - 1, y), 'top': (x, y + 1)}[c[0]]
        return (f'Cell ({x},{y}) is on the {c[0]} edge of screen {self.key}, and screen {c[1]} '
                f'lies beyond it: walking into that edge SCROLLS to screen {c[1]}, so a {what} '
                f'there can never fire (the game checks edge exits only where the room ends). '
                f'Put the {what} one cell in, e.g. ({inward[0]},{inward[1]}).')

    def _add_door(self, cell):
        """S98 r2 (user design): the door appears on the cell at once, not
        connected yet; double-click it to name it and connect it."""
        room = self.current_room()
        if room is None:
            return
        dead = self._dead_edge(cell)
        if dead:
            QMessageBox.warning(self, 'A door cannot go here', dead)
            return
        rid, key = room['id'], self.key
        cmd = self._door_op(f"Add door ({cell[0]},{cell[1]})",
                            lambda doc: doc.add_door(rid, key, cell[0], cell[1]))
        if cmd is not None:
            self._show()
            self._select_exit_at(cell)
            self.status_line.setText('Door added — double-click it to name it and connect it '
                                     'to another door.')

    def _edit_door(self, did):
        """Name / connection / states of a door object (DoorPropsDialog)."""
        if not did:
            return
        from editor2.app.rooms.door_dialog import DoorPropsDialog
        if self.s.doc.door_end(did) is None:
            return
        dlg = DoorPropsDialog(self.s, did, self)
        if dlg.exec() != QDialog.Accepted:
            return
        v = dlg.result_values()
        me = self.s.doc.door_end(did)
        cur = me.get('link')

        def apply(doc):
            end = doc.door_end(did)
            if end['kind'] == 'room' and v['name'] != end['name']:
                doc.rename_door(did, v['name'])
            if v['states'] is not None and sorted(v['states']) != end['states']:
                doc.set_door_states(did, v['states'])
            if v['link'] != cur:
                if v['link'] is None:
                    doc.unlink_door(did)
                else:
                    doc.link_doors(did, v['link'])
        if v['name'] == me['name'] and v['link'] == cur and \
                (v['states'] is None or sorted(v['states']) == me.get('states')):
            return
        cmd = self._door_op(f"Door '{v['name']}'", apply)
        if cmd is not None:
            cell = (me['x'], me['y'])
            self._show()
            if me['kind'] == 'room':
                self._select_exit_at(cell)
            else:
                self.canvas.selected_cell = cell
                self.canvas.viewport().update()

    def _door_disconnect(self):
        did = getattr(self, '_sel_door', None)
        if did and self._door_op('Disconnect door', lambda doc: doc.unlink_door(did)) is not None:
            cell = self.canvas.selected_cell
            self._show()
            if cell:
                self._select_exit_at(cell)

    def _select_exit_at(self, cell):
        room = self.current_room()
        if room is None:
            return
        rows = self.s.doc.exits_of(room, self.key, self.state_idx)
        for i, e in enumerate(rows):
            if (val(e['x']), val(e['y'])) == tuple(cell):
                ref = self.canvas.select_marker('exit', i)
                if ref is not None:
                    m = next(m for m in self.canvas.markers if m[5] is ref)
                    self._marker_selected({'kind': m[0], 'x': m[1], 'y': m[2], 'sprite': m[3],
                                           'label': m[4], 'ref': ref})
                return

    def _door_states(self, target, present):
        room = self.current_room()
        if room is None or self._sel_exit is None:
            return
        rid, key, st, idx = self.room_id, self.key, self.state_idx, self._sel_exit
        cmd = self._door_op(('Add door to' if present else 'Remove door from') + f' state {target}',
                            lambda doc: doc.set_exit_presence(doc.room(rid), key, st, idx,
                                                              target, present))
        if cmd is not None:
            cell = self.canvas.selected_cell
            self._show()
            if cell:
                self._select_exit_at(cell)

    def _door_delete(self):
        sel = getattr(self, '_sel_door', None)
        if not sel:
            return
        self._remove_door(sel)

    def _remove_door(self, did):
        if self._door_op(f"Delete door '{self.s.doc.door_name(did)}'",
                         lambda doc: doc.remove_door(did)) is not None:
            self._sel_door = None
            self._show()
            self.inspector.show_selection(None)

    def _door_reaim(self):
        sel = getattr(self, '_sel_door', None)
        if sel and self._door_op('Re-aim door arrivals',
                                 lambda doc: doc.refresh_door(sel)) is not None:
            cell = self.canvas.selected_cell
            self._show()
            if cell:
                self._select_exit_at(cell)

    def open_node(self, key):
        """Open a room given a world-graph key (S98)."""
        if key[0] == 'room':
            room = self.s.doc.room(key[1])
            self._go_end({'kind': 'room', 'room': key[1],
                          'screen': self.s.doc.screen_keys(room)[0], 'x': -1, 'y': -1,
                          'states': [0]})
            self.canvas.selected_cell = None
        else:
            scr = next(sc for m, _n, sc in self.s.renderer.vanilla_rooms() if m == key[1])
            self._go_end({'kind': 'vanilla', 'mapID': key[1], 'screen': scr[0], 'x': -1, 'y': -1})
            self.canvas.selected_cell = None
        self.canvas.viewport().update()

    def _go_door_here(self, did):
        """Select this room's end of door `did` (Doors & entrances list)."""
        e = self.s.doc.door_end(did)
        if e is not None and e['kind'] == 'room':
            self._go_end(e)
        elif e is not None:
            p = self.s.doc.door_partner(did)
            if p is not None:
                self._go_end(p)

    def _go_end(self, end):
        """Show a door end / exit destination: its room, screen, state, cell."""
        if not end:
            return
        if end['kind'] == 'room':
            self.vanilla_mid = None
            self.room_id = end['room']
            self.key = int(end['screen'])
            sts = end.get('states') or [0]
            self.state_idx = self.state_idx if self.state_idx in sts else sts[0]
            self._fill_rooms(keep=end['room'])
            self.key = int(end['screen'])
            self._show()
            self._select_exit_at((end['x'], end['y']))
            if self.canvas.selected_marker is None:
                self.canvas.selected_cell = (end['x'], end['y'])
                self.canvas.viewport().update()
        else:
            self.room_id = None
            self.room_list.blockSignals(True)
            self.room_list.setCurrentRow(-1)
            self.room_list.blockSignals(False)
            self.vanilla_mid = int(end['mapID'])
            for i in range(self.vanilla_list.count()):
                if self.vanilla_list.item(i).data(Qt.UserRole) == self.vanilla_mid:
                    self.vanilla_list.blockSignals(True)
                    self.vanilla_list.setCurrentRow(i)
                    self.vanilla_list.blockSignals(False)
            self.key, self.state_idx = int(end['screen']), 0
            self._show()
            self.canvas.selected_cell = (end['x'], end['y'])
            self.canvas.viewport().update()

    # ------------------------------------------ one-way exits / teleports
    def _exit_states(self, target, present):
        room = self.current_room()
        if room is None or self._sel_exit is None:
            return
        rid, key, st, idx = self.room_id, self.key, self.state_idx, self._sel_exit
        cmd = self._door_op(('Add exit to' if present else 'Remove exit from') + f' state {target}',
                            lambda doc: doc.set_exit_presence(doc.room(rid), key, st, idx,
                                                              target, present))
        if cmd is not None:
            cell = self.canvas.selected_cell
            self._show()
            if cell:
                self._select_exit_at(cell)

    def _exit_delete(self):
        if self._sel_exit is not None:
            self._remove_exit(self._sel_exit)

    # ----------------------------------------- examine spots / step triggers
    def _show_spot_panel(self, index, entry=None):
        room = self.current_room()
        doc = self.s.doc
        if room is None:
            view = doc.npc_view({}, entry)
            self.spot_panel.show_spot(view, [], None, None, editable=False)
            self._show_object(self.spot_panel)
            return
        lst = doc.npc_entries(room, self.key, self.state_idx)
        if not 0 <= index < len(lst):
            return
        view = doc.npc_view(room, lst[index])
        self._sel_npc = index
        sid = view.get('script')
        talk = doc.talk_spec(sid) if isinstance(sid, str) and sid != 'none' else None
        pres = doc.npc_presence(room, self.key, self.state_idx, index)
        self.spot_panel.show_spot(view, doc.room_script_ids(room), talk,
                                  pres if len(pres) > 1 else None, editable=True)
        self._show_object(self.spot_panel)

    def _add_spot(self, cell, kind):
        room = self.current_room()
        if room is None:
            return
        from editor2.app.rooms.npc_panel import TalkDialog
        dlg = TalkDialog(title=('What does the player find here?' if kind == 'examine'
                                else 'What happens when the player steps here?'),
                         rom=self.s.renderer.rom, parent=self, doc=self.s.doc, room=room,
                         key=self.key,
                         boxes=[['There is nothing', 'special here.']] if kind == 'examine'
                         else [['Something happens!']])
        if dlg.exec() != QDialog.Accepted:
            return
        spec, new_flags = dlg.spec(), dlg.new_flags()
        cx, cy = cell

        def op(doc, r, k, st):
            for nm in new_flags:
                if not any(f.get('name') == nm for f in doc.flags()):
                    doc.add_flag(nm)
            sid = doc.new_talk(r, spec, name='examine' if kind == 'examine' else 'step')
            return doc.add_spot(r, k, st, kind, cx, cy, sid)
        cmd = self._npc_op(f'Add {kind} spot at ({cx},{cy})', op)
        if cmd is not None:
            self._after_spot_edit(cmd.result)

    def _after_spot_edit(self, index):
        self._show()
        if index is None:
            return
        ref = self.canvas.select_npc(index)
        if ref is not None:
            m = next(m for m in self.canvas.markers if m[5] is ref)
            self.inspector.show_selection({'kind': m[0], 'x': m[1], 'y': m[2], 'sprite': m[3],
                                           'label': m[4], 'ref': ref}, editable=True)
            self._show_spot_panel(index)

    def _spot_fields(self, fields):
        idx = self._sel_npc
        if idx is None:
            return
        what = ', '.join(f'{k}={v}' for k, v in fields.items())
        cmd = self._npc_op(f'Spot {what}',
                           lambda doc, r, k, st: doc.update_spot(r, k, st, idx, **fields))
        if cmd is not None:
            self._after_spot_edit(idx)

    # ------------------------------------------------------ NPCs (S97, P3.5)
    def _show_npc_panel(self, index, entry=None):
        room = self.current_room()
        panel = self.npc_panel
        if room is None:
            # vanilla view: read-only form from the raw bytes
            view = self.s.doc.npc_view({}, entry)
            panel.show_npc(view, [], None, None, editable=False,
                           bytes_hint=' '.join(str(b) for b in entry.get('bytes', [])))
            self._show_object(panel)
            return
        lst = self.s.doc.npc_entries(room, self.key, self.state_idx)
        if not 0 <= index < len(lst):
            panel.setVisible(False)
            return
        entry = lst[index]
        view = self.s.doc.npc_view(room, entry)
        if view['kind'] != 'npc':
            panel.setVisible(False)
            return
        self._sel_npc = index
        sid = view.get('script')
        talk = (self.s.doc.talk_spec(sid) if isinstance(sid, str) and sid != 'none' else None)
        pres = self.s.doc.npc_presence(room, self.key, self.state_idx, index)
        panel.show_npc(view, self.s.doc.room_script_ids(room), talk,
                       pres if len(pres) > 1 else None, editable=True,
                       bytes_hint=' '.join(str(b) for b in entry.get('bytes', [])))
        self._show_object(panel)                # selecting an NPC opens its section

    def _after_npc_edit(self, index):
        """Reload, then keep the edited NPC selected (marker refs are rebuilt)."""
        self._show()
        if index is None:
            return
        ref = self.canvas.select_npc(index)
        if ref is not None:
            m = next(m for m in self.canvas.markers if m[5] is ref)
            self.inspector.show_selection({'kind': m[0], 'x': m[1], 'y': m[2], 'sprite': m[3],
                                           'label': m[4], 'ref': ref}, editable=True)
            self._show_npc_panel(index)

    def _npc_op(self, label, fn, keep=True):
        room = self.current_room()
        if room is None:
            return None
        rid, key, st = self.room_id, self.key, self.state_idx
        cmd = C.SnapshotCommand(self.s, label, lambda doc: fn(doc, doc.room(rid), key, st))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            return None
        return cmd

    def _add_npc(self, cell):
        room = self.current_room()
        if room is None:
            return
        n, cap = self.s.doc.state_capacity(room, self.key, self.state_idx)
        if n >= cap:
            QMessageBox.warning(self, 'Add NPC', f'This screen/state already has {n} NPCs — '
                                f'the engine hard cap is {cap} (S91 measurement).')
            return
        from editor2.app.rooms.npc_panel import SpritePicker
        dlg = SpritePicker(parent=self)
        if dlg.exec() != QDialog.Accepted or dlg.value is None:
            return
        spr = int(dlg.value)
        cx, cy = cell
        cmd = self._npc_op(f'Add NPC ${spr:02X} at ({cx},{cy})',
                           lambda doc, r, k, st: doc.add_npc(r, k, st, cx, cy, spr))
        if cmd is not None:
            self._after_npc_edit(cmd.result)

    def _move_marker(self, ref, cx, cy):
        room = self.current_room()
        if not ref or room is None:
            return
        if ref[0] == 'exit':
            e = ref[2]
            dead = self._dead_edge((cx, cy), 'door' if e.get('door') else 'exit')
            if dead:
                QMessageBox.warning(self, 'Cannot move it there', dead)
                self._show()
                return
            if e.get('door'):
                did = e['door']
                if self._door_op(f'Move door to ({cx},{cy})',
                                 lambda doc: doc.move_door(did, cx, cy)) is not None:
                    self._show()
                    self._select_exit_at((cx, cy))
                return
            rid, key, st, idx = self.room_id, self.key, self.state_idx, ref[1]

            def mv(doc):
                r = doc.room(rid)
                row = doc.exits_of(r, key, st)[idx]
                sig = doc.exit_signature(row)
                for n in range(len(doc.states(r, key))):
                    for e2 in doc.exits_of(r, key, n):
                        if doc.exit_signature(e2) == sig:
                            e2['x'], e2['y'] = int(cx), int(cy)
                doc.touch()
            if self._door_op(f'Move exit to ({cx},{cy})', mv) is not None:
                self._show()
                self._select_exit_at((cx, cy))
            return
        if ref[0] != 'npc':
            return
        idx = ref[1]
        v = self.s.doc.npc_view(room, self.s.doc.npc_entries(room, self.key, self.state_idx)[idx])
        if v['kind'] in ('examine', 'step', 'spawn'):
            cmd = self._npc_op(f'Move spot to ({cx},{cy})',
                               lambda doc, r, k, st: doc.update_spot(r, k, st, idx, x=cx, y=cy))
            if cmd is not None:
                self._after_spot_edit(idx)
            return
        cmd = self._npc_op(f'Move to ({cx},{cy})',
                           lambda doc, r, k, st: doc.update_npc(r, k, st, idx, x=cx, y=cy))
        if cmd is not None:
            self._after_npc_edit(idx)

    def _npc_fields(self, fields):
        idx = self._sel_npc
        if idx is None:
            return
        what = ', '.join(f'{k}={v}' for k, v in fields.items())
        cmd = self._npc_op(f'NPC {what}',
                           lambda doc, r, k, st: doc.update_npc(r, k, st, idx, **fields))
        if cmd is not None:
            self._after_npc_edit(idx)

    def _npc_sprite(self):
        idx = self._sel_npc
        room = self.current_room()
        if idx is None or room is None:
            return
        from editor2.app.rooms.npc_panel import SpritePicker
        cur = self.s.doc.npc_view(room, self.s.doc.npc_entries(room, self.key, self.state_idx)[idx])
        dlg = SpritePicker(current=cur.get('sprite'), parent=self)
        if dlg.exec() == QDialog.Accepted and dlg.value is not None:
            self._npc_fields({'sprite': int(dlg.value)})

    def _sel_is_spot(self):
        room = self.current_room()
        idx = self._sel_npc
        if room is None or idx is None:
            return False
        lst = self.s.doc.npc_entries(room, self.key, self.state_idx)
        return 0 <= idx < len(lst) and \
            self.s.doc.npc_view(room, lst[idx])['kind'] in ('examine', 'step', 'spawn')

    def _npc_new_talk(self):
        """New talk script for the selected NPC / spot (S98: text, YES/NO,
        flags, move — talk_editor.TalkDialog, editor2/core/talk.py)."""
        idx = self._sel_npc
        room = self.current_room()
        if idx is None or room is None:
            return
        from editor2.app.rooms.npc_panel import TalkDialog
        spot = self._sel_is_spot()
        dlg = TalkDialog(rom=self.s.renderer.rom, parent=self, doc=self.s.doc, room=room,
                         key=self.key)
        if dlg.exec() != QDialog.Accepted:
            return
        spec, new_flags = dlg.spec(), dlg.new_flags()

        def op(doc, r, k, st):
            for nm in new_flags:
                if not any(f.get('name') == nm for f in doc.flags()):
                    doc.add_flag(nm)
            sid = doc.new_talk(r, spec, name='examine' if spot else 'talk')
            if spot:
                doc.update_spot(r, k, st, idx, script=sid)
            else:
                doc.update_npc(r, k, st, idx, script=sid)
            return sid
        if self._npc_op('New talk', op) is not None:
            (self._after_spot_edit if spot else self._after_npc_edit)(idx)

    def _npc_edit_talk(self):
        idx = self._sel_npc
        room = self.current_room()
        if idx is None or room is None:
            return
        spot = self._sel_is_spot()
        v = self.s.doc.npc_view(room, self.s.doc.npc_entries(room, self.key, self.state_idx)[idx])
        sid = v.get('script')
        spec = self.s.doc.talk_spec(sid) if isinstance(sid, str) else None
        if spec is None:
            return
        from editor2.app.rooms.npc_panel import TalkDialog
        dlg = TalkDialog(title=f'Edit {sid}', rom=self.s.renderer.rom, parent=self,
                         spec=spec, doc=self.s.doc, room=room, key=self.key)
        if dlg.exec() != QDialog.Accepted:
            return
        new, new_flags = dlg.spec(), dlg.new_flags()

        def op(doc, r, k, st):
            for nm in new_flags:
                if not any(f.get('name') == nm for f in doc.flags()):
                    doc.add_flag(nm)
            doc.set_talk(sid, new)
        if self._npc_op(f'Edit talk {sid}', op) is not None:
            (self._after_spot_edit if spot else self._after_npc_edit)(idx)

    def _npc_presence(self, target, present):
        idx = self._sel_npc
        if idx is None:
            return
        cmd = self._npc_op(('Add NPC to' if present else 'Remove NPC from') + f' state {target}',
                           lambda doc, r, k, st: doc.set_npc_presence(r, k, st, idx, target, present))
        if cmd is not None:
            self._after_npc_edit(idx)

    def _npc_delete(self):
        idx = self._sel_npc
        if idx is None:
            return
        label = 'Delete spot' if self._sel_is_spot() else 'Delete NPC'
        if self._npc_op(label, lambda doc, r, k, st: doc.remove_npc(r, k, st, idx)) is not None:
            self._sel_npc = None
            self._show()
            self.inspector.show_selection(None)

    # ------------------------------------------------- state rules (P3.5a)
    def _rules_edited(self, rules, new_flags):
        room = self.current_room()
        if room is None:
            return
        rid = self.room_id

        def op(doc):
            for nm in new_flags:
                if not any(f.get('name') == doc._slug(nm) for f in doc.flags()):
                    doc.add_flag(nm)
            doc.set_state_rules(doc.room(rid), rules)
        cmd = C.SnapshotCommand(self.s, 'Edit state rules', op)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'State rules', str(cmd.error))
        self._show()

    def _cell_selected(self, cell):
        if cell is None or self.canvas.tiles is None:
            self.inspector.show_selection(None)
            return
        self.inspector.show_cell(cell, self.canvas.cell_metatile(*cell),
                                 self.canvas.cell_walkable(*cell),
                                 editable=self.current_room() is not None)

    def _edit_requested(self):
        if self.vanilla_mid is not None:
            self._clone_vanilla()
        else:
            self._localize_prompt()

    # ------------------------------------------------------------- rooms
    def _clone_vanilla(self):
        if self.vanilla_mid is None:
            it = self.vanilla_list.currentItem()
            if not it:
                return
            mid = it.data(Qt.UserRole)
        else:
            mid = self.vanilla_mid
        name = self.s.renderer.vanilla_name(mid)
        if QMessageBox.question(
                self, 'Make editable',
                f'Clone vanilla room ${mid:02X} "{name}" into your project as a custom '
                f'room?\n\nThe original stays untouched; the copy gets its own layouts, '
                'palette and scripts (mapID ${:02X}).'.format(self.s.doc.next_free_mapid())
        ) != QMessageBox.Yes:
            return
        rend = self.s.renderer
        cmd = C.SnapshotCommand(self.s, f'Clone vanilla ${mid:02X} {name}',
                                lambda doc: doc.clone_vanilla(mid, name, REPO, rend))
        self.s.undo.push(cmd)
        self.vanilla_mid = None
        self.room_id = cmd.result
        self.key, self.state_idx = 0, 0
        self._fill_rooms(keep=cmd.result)

    def _new_room(self):
        dlg = NewRoomDialog(self.s.renderer, self)
        if dlg.exec() != QDialog.Accepted:
            return
        name = dlg.name.currentText().strip() or 'New room'
        src = dlg.src.currentData()
        blank = dlg.blank.isChecked()
        rend = self.s.renderer
        cmd = C.SnapshotCommand(self.s, f'New room {name}',
                                lambda doc: doc.new_room(name, src, rend, blank_tileset=blank))
        self.s.undo.push(cmd)
        self.vanilla_mid = None
        self.room_id = cmd.result
        self.key, self.state_idx = 0, 0
        self._fill_rooms(keep=cmd.result)

    def _copy_room(self):
        room = self.current_room()
        if room is None:
            return
        name, ok = QInputDialog.getText(self, 'Copy room', 'Name for the copy:',
                                        text=f'{self.s.doc.room_name(room)} copy')
        if not ok or not name.strip():
            return
        rid = self.room_id
        cmd = C.SnapshotCommand(self.s, f'Copy room {name}',
                                lambda doc: doc.copy_room(rid, name.strip()))
        self.s.undo.push(cmd)
        self.room_id = cmd.result
        self.key, self.state_idx = 0, 0
        self._fill_rooms(keep=cmd.result)

    def _rename_room(self):
        room = self.current_room()
        if room is None:
            return
        name, ok = QInputDialog.getText(self, 'Rename room', 'Name:',
                                        text=self.s.doc.room_name(room))
        if ok and name.strip():
            self._rename_to(name.strip())

    def _rename_to(self, name):
        room = self.current_room()
        if room is None or name == self.s.doc.room_name(room):
            return
        rid = self.room_id
        self.s.undo.push(C.SnapshotCommand(self.s, f'Rename room to {name}',
                                           lambda doc: doc.rename_room(rid, name)))

    def _delete_room(self):
        room = self.current_room()
        if room is None:
            return
        if QMessageBox.question(
                self, 'Delete room',
                f'Delete "{self.s.doc.room_name(room)}" (${val(room["mapID"]):02X})? '
                'Layouts only it used are removed too. Undo restores everything.') != QMessageBox.Yes:
            return
        rid = self.room_id
        self.room_id = None
        self.s.undo.push(C.SnapshotCommand(self.s, f'Delete room {rid}',
                                           lambda doc: doc.delete_room(rid)))

    # ---------------------------------------------------------- metatiles
    # --------------------------------------------- entrance redirects (S94b)
    def _add_redirect(self, preset=None):
        room = self.current_room()
        if room is None or room.get('placeholder'):
            return
        dlg = RedirectDialog(self.s, room['id'], self, preset=preset)
        if dlg.exec() != QDialog.Accepted:
            return
        v = dlg.values()
        self._add_redirect_entry(v['source_mid'], v['screen'], v['x'], v['y'],
                                 v['dest_screen'], v['spawn_x'], v['spawn_y'])

    def _add_redirect_entry(self, src_mid, screen, x, y, dest_screen, sx, sy):
        rid = self.room_id
        name = self.s.renderer.vanilla_name(src_mid)
        self.s.undo.push(C.SnapshotCommand(
            self.s, f'Route {name} door ({x},{y}) → {rid}',
            lambda doc: doc.add_redirect(src_mid, screen, x, y, rid, dest_screen, sx, sy,
                                         comment=f'{name} screen {screen} door ({x},{y}) -> {rid}')))

    def _remove_redirect(self, index):
        rd = self.s.doc.redirects()[index]
        self.s.undo.push(C.SnapshotCommand(
            self.s, f"Remove entrance {rd['mapID']} ({rd['x']},{rd['y']})",
            lambda doc: doc.remove_redirect(index)))

    def _route_door(self, preset):
        """From the vanilla view: pick WHICH custom room this door should
        lead to, then open the dialog pre-filled with the door."""
        rooms = [r for r in self.s.doc.rooms if not r.get('placeholder')]
        if not rooms:
            QMessageBox.information(self, 'No custom rooms',
                                    'Clone or create a custom room first, then route this door to it.')
            return
        names = [f"${val(r['mapID']):02X}  {self.s.doc.room_name(r)}" for r in rooms]
        pick, ok = QInputDialog.getItem(self, 'Route this door',
                                        'Custom room the door should lead to:', names, 0, False)
        if not ok:
            return
        room = rooms[names.index(pick)]
        self.vanilla_mid = None
        self.room_id = room['id']
        self.key = self.s.doc.screen_keys(room)[0]
        self.state_idx = 0
        self._fill_rooms(keep=room['id'])
        self._add_redirect(preset)

    def _edit_metatile(self, seed):
        cv = self.canvas
        if cv.gfx is None:
            return
        dlg = MetatileEditor(self.s.renderer, cv.gfx.sheet, cv.pals, cv.gfx.threshold,
                             seed=seed, parent=self)
        if dlg.exec() != QDialog.Accepted:
            return
        mt = dlg.result_metatile()
        room = self.current_room()
        if room is None:
            # vanilla view: just use it as the brush
            self._brush_selected(mt)
            return
        key = self.s.doc.tileset_key(room)
        self.s.undo.push(C.SnapshotCommand(
            self.s, f"New metatile {mt['name']}",
            lambda doc: doc.add_metatile(key, mt['name'], mt['tiles'], mt['pal'])))
        self._brush_selected(mt)

    def _remove_metatile(self, index):
        room = self.current_room()
        if room is None:
            return
        key = self.s.doc.tileset_key(room)
        self.s.undo.push(C.SnapshotCommand(self.s, 'Delete metatile',
                                           lambda doc: doc.remove_metatile(key, index)))

    # --------------------------------------------------------- walkability
    def _flip_walk(self, cx, cy):
        cv = self.canvas
        if cv.is_vanilla():
            self._clone_vanilla()
            return
        if not cv.is_editable():
            self._localize_prompt()
            return
        room = self.current_room()
        rec = room.get('record') or {}
        if 'tileset' not in rec:
            if QMessageBox.question(
                    self, 'Copy tileset into project',
                    'Walkability is a property of the TILESET (tile index < collision '
                    'threshold = wall). Flipping a cell needs a twin of its bottom-right '
                    'subtile on the other side of the threshold, which means editing the '
                    'tileset — so it must be copied into your project first (bank $67).\n\n'
                    'Copy this room\'s vanilla tileset into the project now?') != QMessageBox.Yes:
                return
        want = not cv.cell_walkable(cx, cy)
        rid, lid, sheet = self.room_id, cv.lid, cv.gfx.sheet
        shift = [False]

        def op(doc):
            r = doc.room(rid)
            tid = doc.localize_tileset(r, sheet)
            return doc.set_cell_walkable(lid, tid, cx, cy, want, shift_ok=shift[0])
        # S98 r2 fix: SnapshotCommand CATCHES a failing op (S95: no trace
        # left) and stores it in .error — the old `except RuntimeError` here
        # never fired, so a refused flip (e.g. no free tileset slot for the
        # twin subtile) did nothing, silently. Say why.
        label = f'Make cell ({cx},{cy}) {"walkable" if want else "a wall"}'
        cmd = C.SnapshotCommand(self.s, label, op)
        self.s.undo.push(cmd)
        from editor2.core.document import ThresholdShiftNeeded
        if isinstance(cmd.error, ThresholdShiftNeeded):
            # S98 r2 (user: "make that an option"): ask before moving the split
            if QMessageBox.question(self, 'Walkable side is full', str(cmd.error)) \
                    == QMessageBox.Yes:
                shift[0] = True
                cmd = C.SnapshotCommand(self.s, label + ' (split moved down)', op)
                self.s.undo.push(cmd)
            else:
                cmd.error = None
        if cmd.error is not None:
            msg = str(cmd.error)
            others = self.s.doc.tileset_sharers(self.s.doc.room(rid))
            if others:
                msg += ('\n\nThis tileset is SHARED with: '
                        + ', '.join(self.s.doc.room_name(r) for r in others)
                        + ' — their tiles use slots too. Tileset tab → "Give this room its '
                          'own copy" stops sharing.')
            QMessageBox.warning(self, 'Cannot flip walkability', msg)
        self._show()

    # ---------------------------------------------------------- commands
    def _add_state(self, copy=True, own=False):
        room = self.current_room()
        if room is None:
            return
        grid = self.canvas.tiles if own else None
        n_before = len(self.s.doc.states(room, self.key))
        self.s.undo.push(C.AddState(self.s, self.room_id, self.key,
                                    copy_from=self.state_idx if copy else None,
                                    own_layout=own, renderer_grid=grid))
        self.state_idx = n_before
        self._show()

    def _remove_state(self):
        room = self.current_room()
        if room is None or len(self.s.doc.states(room, self.key)) <= 1:
            return
        if QMessageBox.question(self, 'Remove state',
                                f'Remove state {self.state_idx} of screen {self.key}? '
                                '(Undo restores it.)') != QMessageBox.Yes:
            return
        self.s.undo.push(C.RemoveState(self.s, self.room_id, self.key, self.state_idx))
        self.state_idx = max(0, self.state_idx - 1)
        self._show()

    def _localize_prompt(self):
        if QMessageBox.question(
                self, 'Layout is read-only',
                'This state renders a VANILLA layout (bank/entry reference). '
                'Copy it into the project as an editable layout?') == QMessageBox.Yes:
            self._localize()

    def _localize(self):
        room = self.current_room()
        if room is None:
            return
        ref = self.s.doc.state_layout_ref(room, self.key, self.state_idx)
        if not ref or 'id' in ref:
            return
        grid = self.s.renderer.vanilla_layout_grid(val(ref['bank']), val(ref['entry']))
        self.s.undo.push(C.LocalizeLayout(self.s, self.room_id, self.key, self.state_idx, grid))
        self._show()

    def _add_screen(self, key):
        room = self.current_room()
        if room is None:
            if self.vanilla_mid is not None:
                self._clone_vanilla()
            return
        thr = self.s.renderer.room_gfx(room).threshold
        grid = self.s.doc.blank_grid(min(thr, 127))
        attr = self.s.doc.blank_grid(0)
        # S95: the new screen shows the palette the author is looking at
        pal = None
        if str(self.key) in (room.get('screens') or {}):
            pal = self.s.doc.effective_palette(room, self.key, self.state_idx)
        self.s.undo.push(C.AddScreen(self.s, self.room_id, key, grid, attr, palette=pal))
        self.key, self.state_idx = key, 0
        self._show()

    def _remove_screen(self, key):
        room = self.current_room()
        if room is None:
            return
        if len(self.s.doc.screen_keys(room)) <= 1:
            QMessageBox.information(self, 'Remove screen', 'A room keeps at least one screen.')
            return
        if QMessageBox.question(self, 'Remove screen',
                                f'Remove screen {key}? (Undo restores it.)') != QMessageBox.Yes:
            return
        self.s.undo.push(C.RemoveScreen(self.s, self.room_id, key))
        self._show()

    def _threshold_edited(self, v):
        room = self.current_room()
        if room is None or not room.get('record'):
            return
        self.s.undo.push(C.SetRoomField(self.s, self.room_id, ('record', 'collision_threshold'),
                                        f'0x{v:02X}', 'Set collision threshold'))
        self._show()

    def _vanilla_palette_words(self, mid):
        from editor2.app.rooms.palette_panel import to555
        from PySide6.QtGui import QColor
        pals = self.s.renderer.vanilla_palettes(mid)
        return [[to555(QColor(*c)) for c in row] for row in pals]

    def _palette_chosen(self, pid):
        if self.room_id is None:
            return
        if isinstance(pid, tuple):            # ('vanilla', mid): copy into the project
            mid = pid[1]
            words = self._vanilla_palette_words(mid)
            rid = self.room_id
            name = self.s.renderer.vanilla_name(mid)

            def op(doc):
                new = doc.add_palette_from_words(f'pal_from_{mid:02X}', words,
                                                 f'copied from vanilla ${mid:02X} {name}')
                doc.room(rid).setdefault('render', {})['palette'] = new
                return new
            self.s.undo.push(C.SnapshotCommand(self.s, f'Room palette from {name}', op))
        else:
            self.s.undo.push(C.SetRoomField(self.s, self.room_id, ('render', 'palette'), pid,
                                            'Set room palette'))
        self._show()

    def _state_palette_chosen(self, pid):
        room = self.current_room()
        if room is None:
            return
        rid, key, st = self.room_id, self.key, self.state_idx
        if isinstance(pid, tuple):
            mid = pid[1]
            words = self._vanilla_palette_words(mid)
            name = self.s.renderer.vanilla_name(mid)

            def op(doc):
                new = doc.add_palette_from_words(f'pal_from_{mid:02X}', words,
                                                 f'copied from vanilla ${mid:02X} {name}')
                doc.set_state_palette(doc.room(rid), key, st, new)
                return new
            label = f'Screen {key} palette from {name}'
        else:
            def op(doc):
                return doc.set_state_palette(doc.room(rid), key, st, pid)
            label = f'Screen {key} state {st} palette'
        self.s.undo.push(C.SnapshotCommand(self.s, label, op))
        self._show()

    # ------------------------------------------------------------ exits (S95)
    def _add_exit(self, cell):
        """S98: 'One-way teleport here…' (the rare object; doors are the
        two-way default). Arrives exactly on the chosen cell."""
        room = self.current_room()
        if room is None:
            return
        dlg = DoorDialog(self.s, room['id'], self.key, self.state_idx, cell, self, teleport=True)
        if dlg.exec() != QDialog.Accepted:
            return
        v = dlg.teleport_values()
        rid, key, st = self.room_id, self.key, self.state_idx
        cmd = self._door_op(f"One-way teleport ({v['x']},{v['y']}) → {v['dest']}",
                            lambda doc: doc.add_teleport(doc.room(rid), key, st, **v))
        if cmd is not None:
            self._show()
            self._select_exit_at(cell)

    def _remove_exit(self, index):
        room = self.current_room()
        if room is None:
            return
        rid, key, st = self.room_id, self.key, self.state_idx
        self.s.undo.push(C.SnapshotCommand(
            self.s, f'Delete exit #{index}',
            lambda doc: doc.remove_exit(doc.room(rid), key, st, index)))
        self._show()

    def _palette_make_editable(self, slot, idx):
        """Double-click on a borrowed (vanilla) palette colour."""
        if self.vanilla_mid is not None:
            if QMessageBox.question(
                    self, 'Vanilla palette',
                    'This is a vanilla room (read-only). Clone it into your project '
                    'to edit its colours?') == QMessageBox.Yes:
                self._clone_vanilla()
            return
        room = self.current_room()
        if room is None:
            return
        if QMessageBox.question(
                self, 'Borrowed palette',
                'This room still borrows its vanilla palette. Copy the palette into '
                'your project so you can edit its colours?\n\n(The room then owns a '
                'palette item; the vanilla original is untouched.)') != QMessageBox.Yes:
            return
        pals = self.s.renderer.room_palettes(room, self.key, self.state_idx)
        from editor2.app.rooms.palette_panel import to555
        from PySide6.QtGui import QColor
        words = [[to555(QColor(*c)) for c in row] for row in pals]
        key, st = self.key, self.state_idx
        cmd = C.SnapshotCommand(
            self.s, 'Make palette editable',
            lambda doc: doc.localize_palette(doc.room(room['id']), key, st, words))
        self.s.undo.push(cmd)
        self._show()
        self.palettes.edit_color(slot, idx)

    def _color_edited(self, pid, slot, idx, rgb):
        self.s.undo.push(C.SetPaletteColor(self.s, pid, slot, idx, rgb))
        self._show()

    def current_screen_image(self):
        return self.canvas.screenshot()
