"""main.py — DWM1 Editor shell (EDITOR_DESIGN §5.0; S72 skeleton → S93 shell).

Project window: top-level tab strip (Rooms · Gates · Monsters · Arena · Skills ·
Animations · Breeding · Encounters · Music · Progression & Flags · World · Balance ·
Build & Play) over ONE Session (editable project.json + live renderer +
undo stack). Only the tabs whose ROADMAP boxes have landed are live; the
rest are stubs that name their box, so later sessions slot in without
reshaping the frame. Global: Save ⌘S, Undo/Redo ⌘Z/⇧⌘Z, Build ⌘B (saves
first — the compiler reads project.json from disk, same code path as
tools/build_project.py, byte-identical by construction), Play ⌘R,
Validate. Build log + undo history docks.

Run:  pip install PySide6 Pillow numpy   then   python3 -m editor2.app
"""

import hashlib
import os
import shutil
import sys

from PySide6.QtCore import QSettings, Qt
from PySide6.QtGui import QAction, QKeySequence
from PySide6.QtWidgets import (QApplication, QDockWidget, QFileDialog,
                               QFormLayout, QInputDialog, QLabel, QMainWindow,
                               QMessageBox, QPlainTextEdit, QPushButton,
                               QStatusBar, QStyle, QToolBar,
                               QUndoView, QVBoxLayout, QWidget)

from editor2.app.build_worker import BuildWorker
from editor2.app.session import REPO, Session
from editor2.app.rooms.tab import RoomsTab
from editor2.core import emulator
from editor2.core import place_names as PN

ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'   # PROJECT_STATE canonical

STUB_TABS = [
    ('Gates', 'P3.7b', 'Custom rooms on gate floors (open a project); gate settings + boss floor = part 2.'),
    ('Monsters', 'P3.10', 'Species data, enemy rows, new species from sprite sheets (open a project).'),
    ('Skills', 'P3.11', 'Names, SKIL text, MP, learning, power, targets, AI, looks (open a project).'),
    ('Breeding', 'P3.12', 'Recipe editor + the randomizer tree explorer, live re-sim.'),
    ('Encounters', 'P3.13a', 'Every wild-monster list, gate floor plans, room battles, flag variants (open a project).'),
    ('Music', 'P3.13b', 'Song library with preview, MIDI import, room / gate / battle music (open a project).'),
    ('Progression && Flags', 'P3.14', 'Flag manager, quest forms, triggers-as-sentences.'),
    ('Balance', 'P3.15a', 'The difficulty curve of every key fight, teams, what-if.'),
]


def _stub(title, box, blurb):
    w = QWidget()
    v = QVBoxLayout(w)
    v.addStretch(1)
    title = title.replace('&&', '&amp;')
    t = QLabel(f'<h2>{title}</h2><p>ROADMAP Phase 3 box <b>{box}</b> — not built yet.</p>'
               f'<p>{blurb}</p><p style="color:#888">EDITOR_DESIGN §5 has the spec.</p>')
    t.setAlignment(Qt.AlignCenter)
    v.addWidget(t)
    v.addStretch(2)
    return w


class BuildPlayTab(QWidget):
    def __init__(self, win):
        super().__init__()
        self.win = win
        v = QVBoxLayout(self)
        f = QFormLayout()
        self.l_project = QLabel('—')
        self.l_rom = QLabel('no build yet')
        self.l_md5 = QLabel('—')
        self.l_usage = QLabel('—')
        self.l_clean = QLabel(f'original ROM MD5 must be {ORIGINAL_MD5}')
        for k, w in (('project', self.l_project), ('last ROM', self.l_rom),
                     ('md5', self.l_md5), ('bank usage', self.l_usage),
                     ('clean check', self.l_clean)):
            w.setTextInteractionFlags(Qt.TextSelectableByMouse)
            w.setWordWrap(True)
            f.addRow(k, w)
        v.addLayout(f)
        row = QWidget()
        h = QVBoxLayout(row)
        b1 = QPushButton('Build ROM  (⌘B / Ctrl+B) — saves the project first')
        b1.clicked.connect(win.build)
        b2 = QPushButton('Play in emulator  (⌘R / Ctrl+R)')
        b2.clicked.connect(win.run_rom)
        b3 = QPushButton('Validate project (compile only, no make)')
        b3.clicked.connect(win.validate)
        for b in (b1, b2, b3):
            h.addWidget(b)
        v.addWidget(row)
        v.addStretch(1)

    def refresh(self, win):
        self.l_project.setText(win.session.doc.path if win.session else '—')
        if win.session and win.session.last_rom:
            self.l_rom.setText(win.session.last_rom)
        if win.last_result and win.last_result.ok:
            self.l_md5.setText(win.last_result.rom_md5)
            self.l_usage.setText('  '.join(
                f'{b}: {n} B' for b, n in sorted(win.last_result.bank_usage.items())))


class MainWindow(QMainWindow):
    def __init__(self, defer_open=False):
        super().__init__()
        self._lazy_wrappers = {}
        self.settings = QSettings('dwm1_disassembly', 'DWM1Editor')
        PN.SHOW_IDS = self.settings.value('view/show_ids', False) in (True, 'true', '1', 1)
        self.session = None
        self.worker = None
        self.last_result = None
        self.rooms_tab = None
        self._build_ui()
        self._build_menu()
        self._restore_window()
        self._restore_rom_status()
        last = self.settings.value('recent/project')
        if last and os.path.exists(last):
            if defer_open:
                # S171: the window shows first, the project opens a moment later
                from PySide6.QtCore import QTimer
                self.statusBar().showMessage(f'Opening {os.path.basename(os.path.normpath(last))}…')
                QTimer.singleShot(50, lambda: self._open_deferred(last))
            else:
                self.open_project(last)

    def ask_for_rom_if_missing(self):
        """S171: the packaged app's first start — the original ROM is never in the app;
        ask for it once (it is copied to the app's data folder)."""
        from editor2.app import appmode
        if not appmode.APP or os.path.exists(os.path.join(REPO, 'data', 'DWM-original.gbc')):
            return
        QMessageBox.information(
            self, 'The original game',
            'The editor needs the original Dragon Warrior Monsters ROM (Game Boy Color, '
            f'MD5 {ORIGINAL_MD5}).\n\nIt is not part of the app. Choose your copy of the '
            'ROM next — the app keeps a copy of it in its own folder.')
        self._locate_rom()

    def _open_deferred(self, path):
        from PySide6.QtGui import QGuiApplication
        QGuiApplication.setOverrideCursor(Qt.WaitCursor)
        try:
            self.open_project(path)
        finally:
            QGuiApplication.restoreOverrideCursor()

    # ---------------- UI scaffolding ----------------
    def _build_ui(self):
        from editor2 import EDITOR_REVISION
        self.setWindowTitle(f'DWM1 Editor ({EDITOR_REVISION})')
        self.resize(1500, 900)
        # S169: every page in its own scroll area + a scrolling tab row — a tab click
        # can no longer push the window past the screen (editor2/app/page_tabs.py)
        from editor2.app.page_tabs import PageTabs
        self.tabs = PageTabs()
        self.tabs.setDocumentMode(True)
        self.setCentralWidget(self.tabs)
        self._fill_tabs()
        # S167: sub-tab bars a tab makes later (on first show) get their "?" too
        self.tabs.currentChanged.connect(self._help_install_late)

        self.log = QPlainTextEdit()
        self.log.setReadOnly(True)
        self.log.setMaximumBlockCount(5000)
        # S119b (user: "Why cant I copy paste build log?"): read-only text is
        # selectable by mouse only — ⌘A / ⌘C did nothing; + a right-click
        # "Copy all" (the dock is a few lines tall)
        self.log.setTextInteractionFlags(Qt.TextSelectableByMouse | Qt.TextSelectableByKeyboard)
        self.log.setContextMenuPolicy(Qt.CustomContextMenu)
        self.log.customContextMenuRequested.connect(self._log_menu)
        self.log_dock = QDockWidget('Build log', self)
        self.log_dock.setObjectName('log_dock')          # S169: saveState needs names
        self.log_dock.setWidget(self.log)
        self.log_dock.setFeatures(QDockWidget.DockWidgetMovable
                                  | QDockWidget.DockWidgetClosable)
        self.addDockWidget(Qt.BottomDockWidgetArea, self.log_dock)
        self.resizeDocks([self.log_dock], [110], Qt.Vertical)

        self.undo_view = QUndoView()
        self.undo_dock = QDockWidget('History', self)
        self.undo_dock.setObjectName('undo_dock')
        self.undo_dock.setWidget(self.undo_view)
        self.undo_dock.setFeatures(QDockWidget.DockWidgetMovable
                                   | QDockWidget.DockWidgetClosable)
        self.addDockWidget(Qt.RightDockWidgetArea, self.undo_dock)
        self.undo_dock.hide()

        self.setStatusBar(QStatusBar())
        self.rom_status = QLabel()
        self.statusBar().addPermanentWidget(self.rom_status)

    # S171 (user: "when I open editor its a bit slow at first"): every tab but Rooms is
    # made the first time it is shown or named (`self.monsters_tab` …) — opening a
    # project built all 23 pages before (6-8 s measured on the user's project).
    LAZY_TABS = ('import_tab', 'cutscenes_tab', 'gates_tab', 'families_tab', 'monsters_tab',
                 'resistances_tab', 'dialogue_tab', 'arena_tab', 'skills_tab', 'anims_tab',
                 'breeding_tab', 'encounters_tab', 'music_tab', 'items_tab', 'shops_tab',
                 'services_tab', 'progression_tab', 'world_tab', 'balance_tab', 'capacity_tab')

    def __getattr__(self, name):
        """A tab not made yet is made when it is named (S171)."""
        lazy = self.__dict__.get('_lazy_wrappers')
        if lazy is not None and name in lazy:
            lazy[name].ensure()
            if name in self.__dict__:
                return self.__dict__[name]
        raise AttributeError(name)

    def built_tab(self, name):
        """The tab `name` if it has been made — never makes it (shutdown / flush paths)."""
        return self.__dict__.get(name)

    def _lazy(self, attr, title, make):
        """Add a tab whose page `make()` builds on first need; the page is kept as
        self.<attr> (S171)."""
        def factory():
            page = make()
            self.__dict__[attr] = page
            return page
        i = self.tabs.addLazyTab(factory, title)
        self._lazy_wrappers[attr] = self.tabs.wrapper(i)

    def _fill_tabs(self):
        old = self.built_tab('cutscenes_tab')
        if old is not None:                      # S118: stop its recorder / playback
            try:
                old.shutdown()
            except RuntimeError:
                pass
        old = self.built_tab('balance_tab')
        if old is not None:                      # S130: stop its background computations
            try:
                old.shutdown()
            except RuntimeError:
                pass
        for name in self.LAZY_TABS:              # the next project's tabs are made anew
            self.__dict__.pop(name, None)
        self._lazy_wrappers = {}
        self.tabs.clear()
        s = self.session
        if s:
            self.rooms_tab = RoomsTab(s)
            self.rooms_tab.status.connect(self.statusBar().showMessage)
            self.rooms_tab.draw_tab.historyChanged.connect(self._sync_undo)   # S171 r6
            self.rooms_tab.gatesRequested.connect(self._open_gates_for)
            self.rooms_tab.hintsRequested.connect(self._open_hints)       # S158
            self.tabs.addTab(self.rooms_tab, 'Rooms')

            def import_tab():
                from editor2.app.import_tab import ImportTab
                return ImportTab(s)

            def cutscenes():
                # S118 (P3.8 part A): every scene of the game and the project —
                # storyboard, recorded frames, Playback in the real game
                from editor2.app.cutscenes_tab import CutscenesTab
                return CutscenesTab(s)

            def gates():
                # S100 (P3.7b part 1): custom rooms served on gate floors
                from editor2.app.gates_tab import GatesTab
                t = GatesTab(s)
                t.openRoomRequested.connect(self._open_gate_room)
                return t

            def families():
                # S104 (P3.10a): families — members, dialogue voice, Spirit names
                from editor2.app.families_tab import FamiliesTab
                return FamiliesTab(s)

            def monsters():
                # S106 (P3.10 part 1): species data, enemy rows, new species;
                # "Texts that name it…" opens the Text tab filtered (S108)
                from editor2.app.monsters_tab import MonstersTab
                t = MonstersTab(s)
                t.showDialogue.connect(self._show_dialogue_for)
                return t

            def resistances():
                # S159 (ROADMAP E16): every monster's 27 resistances in groups
                from editor2.app.resistances_tab import ResistancesTab
                t = ResistancesTab(s)
                t.openSkill.connect(self._open_skill)
                return t

            def text():
                # S150 (P3.6): the Text tab — the game's own texts EDITABLE
                from editor2.app.text_tab import TextTab
                return TextTab(s)

            def arena():
                # S109 (P3.10b): fees, masters, 1-3 monster teams, the teams' rows
                from editor2.app.arena_tab import ArenaTab
                return ArenaTab(s)

            def skills():
                # S110 (P3.11): the original skills
                from editor2.app.skills_tab import SkillsTab
                return SkillsTab(s)

            def anims():
                # S112 (P3.11e): new battle animations from the stock frames
                from editor2.app.anims_tab import AnimationsTab
                return AnimationsTab(s)

            def breeding():
                # S113 (P3.12): recipes, depth, try a cross, generate a tree
                from editor2.app.breeding_tab import BreedingTab
                return BreedingTab(s)

            def encounters():
                # S114 (P3.13a): wild-monster lists, gate floor plans, room battles
                from editor2.app.encounters_tab import EncountersTab
                return EncountersTab(s)

            def music():
                # S116 (P3.13b): the song library, preview on the game's own engine
                from editor2.app.music_tab import MusicTab
                return MusicTab(s)

            def items():
                # S151 (ROADMAP E9): every item's record + the project's new items
                from editor2.app.items_tab import ItemsTab
                return ItemsTab(s)

            def shops():
                # S117 (P3.13c): the vanilla lists, the project's own shops, prices
                from editor2.app.shops_tab import ShopsTab
                return ShopsTab(s)

            def services():
                # S126 (P3.14e1): service NPCs, their menu lines, medal rewards
                from editor2.app.services_tab import ServicesTab
                t = ServicesTab(s)
                t.navigate.connect(self.navigate_to)
                return t

            def progression():
                # S124 (P3.14a): every flag — what turns it ON / OFF, what checks it
                from editor2.app.flags_tab import ProgressionTab
                t = ProgressionTab(s)
                t.navigate.connect(self.navigate_to)
                return t

            def world():
                # S98 (P3.7): the World graph sits before Balance, as in §5.0
                from editor2.app.world_tab import WorldTab
                t = WorldTab(s)
                t.openRequested.connect(self._open_world_node)
                return t

            def capacity():
                # S145 (ROADMAP ARC CAP4d): every ceiling in words — the status bar's
                # meter measures, this tab shows its report
                from editor2.app.capacity_tab import CapacityTab
                t = CapacityTab(s)
                t.navigate.connect(self.navigate_to)
                t.openTab.connect(self.open_tab_titled)
                m = getattr(self, 'space_meter', None)
                if m is not None:
                    m.reported.connect(t.show_report)
                    t.measureRequested.connect(m.measure_async)
                    if m.report is not None:
                        t.show_report(m.report)
                return t

            self._lazy('import_tab', 'Import art', import_tab)
            self._lazy('cutscenes_tab', 'Cutscenes', cutscenes)
            self._lazy('gates_tab', 'Gates', gates)
            self._lazy('families_tab', 'Families', families)
            self._lazy('monsters_tab', 'Monsters', monsters)
            self._lazy('resistances_tab', 'Resistances', resistances)
            self._lazy('dialogue_tab', 'Text', text)
            self._lazy('arena_tab', 'Arena', arena)
            self._lazy('skills_tab', 'Skills', skills)
            self._lazy('anims_tab', 'Animations', anims)
            self._lazy('breeding_tab', 'Breeding', breeding)
            self._lazy('encounters_tab', 'Encounters', encounters)
            self._lazy('music_tab', 'Music', music)
            self._lazy('items_tab', 'Items', items)
            self._lazy('shops_tab', 'Shops', shops)
            self._lazy('services_tab', 'Services', services)
            self._lazy('progression_tab', 'Progression && Flags', progression)
            self._lazy('world_tab', 'World', world)
        else:
            self.rooms_tab = None
            self.tabs.addTab(_stub('Rooms', 'P3.3', 'Open a project (File → Open) to edit rooms.'),
                             'Rooms')
            for title, box, blurb in STUB_TABS:
                if title == 'Monsters':
                    self.tabs.addTab(_stub('Families', 'P3.10a', 'Family members, dialogue, Spirit names (open a project).'),
                                     'Families')
                if title == 'Balance':
                    self.tabs.addTab(_stub('World', 'P3.7', 'Room / warp graph (open a project).'),
                                     'World')
                    break
                self.tabs.addTab(_stub(title, box, blurb), title)

        def balance():
            # S130 (P3.15a): the difficulty curve — the original game's (read-only,
            # precomputed) against the project's; teams; what-if
            from editor2.app.balance_tab import BalanceTab
            return BalanceTab(s)
        self._lazy('balance_tab', 'Balance', balance)
        if s:
            self._lazy('capacity_tab', 'Capacity', capacity)
        else:
            self.__dict__['capacity_tab'] = None
        self.build_tab = BuildPlayTab(self)
        self.tabs.addTab(self.build_tab, 'Build && Play')
        from editor2.app.help_tab import HelpTab      # S101 r2
        self.help_tab = HelpTab()
        self.tabs.addTab(self.help_tab, 'Help')
        # S167 (ROADMAP P3.H): a "?" on the tab bar, on every sub-tab bar, on the Rooms
        # tab's page column and on dialogs (editor2/app/context_help.py)
        from editor2.app import context_help
        context_help.install(self)

    def _help_install_late(self, _i):
        from editor2.app import context_help
        if getattr(self, 'help_tab', None) is not None:
            context_help.install(self)

    def _wire_capacity(self):
        """S145: a click on the status bar's meter opens the Capacity tab (S171: the tab
        is made then; its own factory connects the meter's reports)."""
        m = getattr(self, 'space_meter', None)
        if m is None or self.session is None:
            return
        m.openRequested.connect(lambda: self.tabs.setCurrentWidget(self.capacity_tab))

    def open_tab_titled(self, title):
        """S145: show the tab whose title is `title` (the Capacity tab's rows)."""
        for i in range(self.tabs.count()):
            if self.tabs.tabText(i) == title:
                self.tabs.setCurrentIndex(i)
                return True
        return False

    def _open_skill(self, sid):
        """S159: the Resistances tab -> the Skills tab on skill `sid`."""
        st = getattr(self, 'skills_tab', None)
        if st is None:
            return
        self.tabs.setCurrentWidget(st)
        st.show_skill(sid)

    def _show_dialogue_for(self, sid):
        """Monsters tab → the Text tab's Dialogue page listing the texts that name `sid`."""
        self.dialogue_tab.show_monster(sid)
        self.tabs.setCurrentWidget(self.dialogue_tab)

    def _open_hints(self):
        """S158: the Breeding tab's Hints page (a monument's / archive's "Hint pool…")."""
        bt = getattr(self, 'breeding_tab', None)
        if bt is None:
            return
        self.tabs.setCurrentWidget(bt)
        bt.show_hints()

    def _open_gates_for(self, room_id):
        """Rooms tab 'Gates tab…' -> the Gates tab on the first gate serving
        the room (else where it was)."""
        gt = getattr(self, 'gates_tab', None)
        if gt is None:
            return
        self.tabs.setCurrentWidget(gt)
        rules = self.session.doc.rules_serving(room_id) if room_id else []
        if rules:
            from editor2.core.gates import _val
            gt.list.setCurrentRow(int(_val(rules[0][1].get('gate', 0))))

    def _open_gate_room(self, room_id):
        """Gates tab 'Open room' -> the room in the Rooms tab (S100)."""
        if self.rooms_tab is None:
            return
        self.tabs.setCurrentWidget(self.rooms_tab)
        self.rooms_tab.open_node(('room', room_id))

    def navigate_to(self, nav):
        """S124: open the place of a flag use / trigger (Progression & Flags tab):
        {'tab': 'rooms', room, screen, state, x, y} · {'tab': 'cutscene', room, scene}
        · {'tab': 'encounters', room | gate} · {'tab': 'gates', gate}
        · {'tab': 'game', map, screen, state, x, y} · {'tab': 'cutscenes'}
        · {'tab': 'worlds', hub} (S125)."""
        tab = (nav or {}).get('tab')
        if tab == 'rooms' and self.rooms_tab is not None:
            self.tabs.setCurrentWidget(self.rooms_tab)
            if nav.get('screen') is None:
                self.rooms_tab.open_node(('room', nav['room']))
            else:
                x = nav.get('x')
                y = nav.get('y')
                self.rooms_tab.open_node(('room', nav['room'], int(nav['screen']),
                                          -1 if x is None else int(x),
                                          -1 if y is None else int(y),
                                          int(nav.get('state') or 0)))
        elif tab == 'game' and self.rooms_tab is not None:
            self.tabs.setCurrentWidget(self.rooms_tab)
            if nav.get('screen') is None:
                self.rooms_tab.open_node(('vanilla', int(nav['map'])))
            else:                    # S124 r3: the screen, state and NPC it runs at
                x, y = nav.get('x'), nav.get('y')
                self.rooms_tab.open_node(('vanilla', int(nav['map']), int(nav['screen']),
                                          -1 if x is None else int(x),
                                          -1 if y is None else int(y),
                                          int(nav.get('state') or 0)))
        elif tab == 'cutscene' and getattr(self, 'cutscenes_tab', None) is not None:
            self.tabs.setCurrentWidget(self.cutscenes_tab)
            self.cutscenes_tab.open_cutscene(nav['room'], nav['scene'])
        elif tab == 'cutscenes' and getattr(self, 'cutscenes_tab', None) is not None:
            self.tabs.setCurrentWidget(self.cutscenes_tab)
        elif tab == 'encounters' and getattr(self, 'encounters_tab', None) is not None:
            self.tabs.setCurrentWidget(self.encounters_tab)
            if nav.get('room'):
                self.encounters_tab.show_room_battles(nav['room'])
            elif nav.get('gate') is not None:
                self.encounters_tab.show_gate_battles(int(nav['gate']))
        elif tab == 'gates' and getattr(self, 'gates_tab', None) is not None:
            gt = self.gates_tab
            self.tabs.setCurrentWidget(gt)
            gid = int(nav.get('gate') or 0)
            row = next((i for i, g in enumerate(gt.gates) if g['id'] == gid), None)
            if row is not None:
                gt.list.setCurrentRow(row)
        elif tab == 'arena' and getattr(self, 'arena_tab', None) is not None:
            # S128: your arena's class locks / won flags -> the Arena tab's Your arena box
            self.tabs.setCurrentWidget(self.arena_tab)
            if hasattr(self.arena_tab, 'show_your_arena'):
                self.arena_tab.show_your_arena(nav.get('class'))
        elif tab == 'worlds' and getattr(self, 'world_tab', None) is not None:
            # S125: a hub rule's flags (Progression & Flags tab) -> the World tab's Hub box
            self.tabs.setCurrentWidget(self.world_tab)
            hb = self.world_tab.worlds.hub
            hb.refresh()
            if nav.get('hub') is not None:
                hb.list.setCurrentRow(int(nav['hub']))

    def _open_world_node(self, key):
        """World graph double-click -> the room in the Rooms tab (S98)."""
        if self.rooms_tab is None:
            return
        self.tabs.setCurrentWidget(self.rooms_tab)
        self.rooms_tab.open_node(key)

    def _build_menu(self):
        style = self.style()
        m_file = self.menuBar().addMenu('&File')
        self.a_new = QAction(style.standardIcon(QStyle.SP_FileIcon), '&New project…', self)
        self.a_new.setShortcut(QKeySequence.New)
        self.a_new.triggered.connect(self._new_project)
        m_file.addAction(self.a_new)
        self.a_open = QAction(style.standardIcon(QStyle.SP_DirOpenIcon), '&Open project…', self)
        self.a_open.setShortcut(QKeySequence.Open)
        self.a_open.triggered.connect(self._open_dialog)
        m_file.addAction(self.a_open)
        a_reload = QAction('&Reload project', self)
        a_reload.setShortcut(QKeySequence.Refresh)
        a_reload.triggered.connect(self.reload_project)
        m_file.addAction(a_reload)
        self.a_save = QAction(style.standardIcon(QStyle.SP_DialogSaveButton), '&Save', self)
        self.a_save.setShortcut(QKeySequence.Save)
        self.a_save.triggered.connect(self.save)
        self.a_save.setEnabled(False)
        m_file.addAction(self.a_save)
        m_file.addSeparator()
        a_rom = QAction('Locate original ROM…', self)
        a_rom.triggered.connect(self._locate_rom)
        m_file.addAction(a_rom)
        a_emu = QAction('Set emulator command…', self)
        a_emu.triggered.connect(self._set_emulator)
        m_file.addAction(a_emu)
        a_rgbds = QAction('Set RGBDS folder…', self)
        a_rgbds.triggered.connect(self._set_rgbds)
        m_file.addAction(a_rgbds)

        self.m_edit = self.menuBar().addMenu('&Edit')
        self.a_undo = QAction(style.standardIcon(QStyle.SP_ArrowBack), '&Undo', self)
        self.a_undo.setShortcut(QKeySequence.Undo)
        self.a_undo.setEnabled(False)
        self.a_redo = QAction(style.standardIcon(QStyle.SP_ArrowForward), '&Redo', self)
        self.a_redo.setShortcut(QKeySequence.Redo)
        self.a_redo.setEnabled(False)
        self.m_edit.addAction(self.a_undo)
        self.m_edit.addAction(self.a_redo)

        m_build = self.menuBar().addMenu('&Build')
        self.a_build = QAction(style.standardIcon(QStyle.SP_ArrowDown), '&Build ROM', self)
        self.a_build.setShortcut(QKeySequence('Ctrl+B'))   # ⌘B on macOS
        self.a_build.triggered.connect(self.build)
        self.a_build.setEnabled(False)
        m_build.addAction(self.a_build)
        self.a_run = QAction(style.standardIcon(QStyle.SP_MediaPlay), '&Play in emulator', self)
        self.a_run.setShortcut(QKeySequence('Ctrl+R'))     # ⌘R on macOS
        self.a_run.triggered.connect(self.run_rom)
        self.a_run.setEnabled(False)
        m_build.addAction(self.a_run)
        self.a_validate = QAction('&Validate project', self)
        self.a_validate.setShortcut(QKeySequence('Ctrl+Shift+V'))
        self.a_validate.triggered.connect(self.validate)
        self.a_validate.setEnabled(False)
        m_build.addAction(self.a_validate)

        m_view = self.menuBar().addMenu('&View')
        m_view.addAction(self.log_dock.toggleViewAction())
        m_view.addAction(self.undo_dock.toggleViewAction())
        m_view.addSeparator()
        # S118e (user: "mute preview pyboy player GLOBALLY in the menu … Overrides
        # all others. Can be toggled.")
        self.a_mute = QAction('Mute game playback (every Playback window)', self)
        self.a_mute.setCheckable(True)
        self.a_mute.setShortcut(QKeySequence('Ctrl+Shift+M'))
        self.a_mute.setChecked(self.settings.value('playback/mute', False) in
                               (True, 'true', '1', 1))
        self.a_mute.toggled.connect(self._mute_toggled)
        m_view.addAction(self.a_mute)
        # S143 (ROADMAP ARC CAP4b; user: "view show in case I want them"): places are
        # shown by name only; this puts each place's technical id (map id / region /
        # game id) after its name everywhere — for debugging in SameBoy
        m_view.addSeparator()
        self.a_ids = QAction('Show technical ids (map ids, regions)', self)
        self.a_ids.setCheckable(True)
        self.a_ids.setChecked(PN.SHOW_IDS)
        self.a_ids.toggled.connect(self._ids_toggled)
        m_view.addAction(self.a_ids)

        m_help = self.menuBar().addMenu('&Help')
        a_help = QAction('Help about this tab', self)
        a_help.setShortcut(QKeySequence.HelpContents)          # F1
        # S167 (ROADMAP P3.H): F1 = the help of the tab (and sub-tab) shown
        from editor2.app import context_help
        a_help.triggered.connect(lambda: context_help.f1(self))
        m_help.addAction(a_help)
        a_all = QAction('Editor &help (all topics)', self)
        a_all.triggered.connect(lambda: self.tabs.setCurrentWidget(self.help_tab))
        m_help.addAction(a_all)
        a_gl = QAction('&Glossary', self)
        a_gl.triggered.connect(lambda: context_help.open_help('95_glossary.md', mw=self))
        m_help.addAction(a_gl)

        tb = QToolBar('Main')
        tb.setObjectName('main_toolbar')
        tb.setMovable(False)
        tb.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
        tb.addAction(self.a_new)
        tb.addAction(self.a_open)
        tb.addAction(self.a_save)
        tb.addSeparator()
        tb.addAction(self.a_undo)
        tb.addAction(self.a_redo)
        tb.addSeparator()
        tb.addAction(self.a_build)
        tb.addAction(self.a_run)
        tb.addAction(self.a_validate)
        self.addToolBar(tb)

    # ---------------- window size (S169) ----------------
    def _restore_window(self):
        """S169 (user: "I have to make it fullscreen again every time"): the window
        comes back where it was closed — size, position, maximized / full screen — and
        the docks as they were."""
        g = self.settings.value('window/geometry')
        if g:
            self.restoreGeometry(g)
        st = self.settings.value('window/state')
        if st:
            self.restoreState(st)

    def _save_window(self):
        self.settings.setValue('window/geometry', self.saveGeometry())
        self.settings.setValue('window/state', self.saveState())

    # ---------------- ROM + emulator preferences ----------------
    def _restore_rom_status(self):
        from editor2.app import appmode
        if appmode.APP:
            # S171: the app keeps its own copy (data/ in its workspace) — taken from the
            # ROM a checkout of the editor was shown, when there is one
            appmode.ensure_rom(REPO, self.settings)
            own = os.path.join(REPO, 'data', 'DWM-original.gbc')
            if os.path.exists(own):
                self.rom_status.setText('ROM: verified')
            else:
                self.rom_status.setText('ROM: not set (File → Locate…)')
            return
        rom = self.settings.value('rom/path')
        if not rom:
            default = os.path.join(REPO, 'data', 'DWM-original.gbc')
            if os.path.exists(default):
                rom = default
        if rom and os.path.exists(rom):
            ok = hashlib.md5(open(rom, 'rb').read()).hexdigest() == ORIGINAL_MD5
            self.rom_status.setText('ROM: verified' if ok else 'ROM: WRONG FILE')
        else:
            self.rom_status.setText('ROM: not set (File → Locate…)')

    def _locate_rom(self):
        path, _ = QFileDialog.getOpenFileName(
            self, 'Locate DWM-original.gbc', '', 'GBC ROM (*.gbc)')
        if not path:
            return
        got = hashlib.md5(open(path, 'rb').read()).hexdigest()
        if got != ORIGINAL_MD5:
            QMessageBox.warning(self, 'Wrong ROM',
                                f'MD5 {got}\nexpected {ORIGINAL_MD5}.\n'
                                'Select the unmodified original ROM.')
            return
        self.settings.setValue('rom/path', path)
        from editor2.app import appmode
        if appmode.APP:                  # S171: the app's own copy, in its data folder
            try:
                appmode.adopt_rom(REPO, path)
            except OSError as e:
                QMessageBox.warning(self, 'Locate ROM', f'Could not copy the ROM: {e}')
        self._restore_rom_status()
        if self.session:
            self.session.rebind_build()

    def _set_rgbds(self):
        path = QFileDialog.getExistingDirectory(
            self, 'Folder containing the RGBDS v0.6.1 binaries '
            '(rgbasm, rgblink, rgbfix, rgbgfx)')
        if path:
            self.settings.setValue('rgbds/dir', path)
            self.log.appendPlainText(f'RGBDS folder set: {path}')

    def _set_emulator(self):
        cur = self.settings.value('emulator/command', '')
        text, ok = QInputDialog.getText(
            self, 'Emulator command',
            'Command to run the built ROM ({rom} = ROM path).\n'
            'Leave empty for the platform default (SameBoy if installed).',
            text=cur)
        if ok:
            self.settings.setValue('emulator/command', text.strip())

    # ---------------- project ----------------
    def _open_dialog(self):
        if not self._confirm_discard():
            return
        path = QFileDialog.getExistingDirectory(
            self, 'Open project folder (contains project.json)')
        if path:
            self.open_project(path)

    def _new_project(self):
        if not self._confirm_discard():
            return
        path = QFileDialog.getSaveFileName(
            self, 'New project — choose a folder name', os.path.expanduser('~/my-dwm-hack'),
            options=QFileDialog.ShowDirsOnly)[0]
        if not path:
            return
        try:
            self.new_project(path)
        except Exception as e:
            QMessageBox.warning(self, 'Cannot create project', str(e))

    def new_project(self, path, name=None):
        """Create a project folder from editor2/templates/blank-project and open it."""
        tpl = os.path.join(REPO, 'editor2', 'templates', 'blank-project')
        if os.path.exists(os.path.join(path, 'project.json')):
            raise RuntimeError(f'{path} already contains a project.json')
        os.makedirs(path, exist_ok=True)
        # copyfile: the packaged app's template is read-only (S171) — the project's copy is not
        shutil.copyfile(os.path.join(tpl, 'project.json'), os.path.join(path, 'project.json'))
        os.makedirs(os.path.join(path, 'assets'), exist_ok=True)
        import json
        pj = os.path.join(path, 'project.json')
        d = json.load(open(pj))
        d['meta']['name'] = name or os.path.basename(os.path.normpath(path))
        open(pj, 'w').write(json.dumps(d, indent=1) + '\n')
        self.open_project(path)
        self.log.appendPlainText(f'New project created from the blank template: {path}')

    def open_project(self, path):
        pj = path if path.endswith('.json') else os.path.join(path, 'project.json')
        if not os.path.exists(pj):
            QMessageBox.warning(self, 'Not a project', f'No project.json in {path}.')
            return
        try:
            session = Session(path, self.settings)
        except Exception as e:
            QMessageBox.warning(self, 'Cannot read project', str(e))
            return
        self.session = session
        self.settings.setValue('recent/project', path)
        from editor2 import EDITOR_REVISION
        self.setWindowTitle(f'DWM1 Editor ({EDITOR_REVISION}) — {session.name}')
        for a in (self.a_undo, self.a_redo):
            try:
                a.triggered.disconnect()
            except (RuntimeError, TypeError):
                pass
        # S171 r6: ⌘Z / ⌘⇧Z undo the Draw tab's strokes while it shows a drawing
        self.a_undo.triggered.connect(self._undo)
        self.a_redo.triggered.connect(self._redo)
        session.undo.canUndoChanged.connect(lambda _on: self._sync_undo())
        session.undo.canRedoChanged.connect(lambda _on: self._sync_undo())
        session.undo.undoTextChanged.connect(lambda _t: self._sync_undo())
        session.undo.redoTextChanged.connect(lambda _t: self._sync_undo())
        session.dirtyChanged.connect(self._dirty_changed)
        self.undo_view.setStack(session.undo)
        # S96 space meters in the status bar (S145: ROM space + rooms, the Capacity tab's report)
        from editor2.app.space_meter import SpaceMeter
        if getattr(self, 'space_meter', None) is not None:
            self.statusBar().removeWidget(self.space_meter)
            self.space_meter.deleteLater()
        self.space_meter = SpaceMeter(session, REPO)
        self.statusBar().insertPermanentWidget(0, self.space_meter)
        self._fill_tabs()
        self._wire_capacity()
        self.tabs.setCurrentIndex(0)
        self.a_build.setEnabled(True)
        self.a_validate.setEnabled(True)
        self.a_save.setEnabled(True)
        self.a_run.setEnabled(bool(session.last_rom))
        if session.last_rom:
            self.log.appendPlainText(
                f'Found an existing build ({session.last_rom}) — Play is enabled.')
        self.build_tab.refresh(self)
        from editor2 import EDITOR_REVISION
        self.log.appendPlainText(f'Opened project: {path}   (editor code: {EDITOR_REVISION})')
        for note in getattr(session.doc, 'migrations', []):
            self.log.appendPlainText(f'MIGRATED: {note} — Save to keep it')
        for note in getattr(session.doc, 'migration_warnings', []):
            self.log.appendPlainText(f'WARNING: {note}')
        self._offer_animation_repair(session)
        self.statusBar().showMessage(f'Opened {session.name}', 4000)

    def _offer_animation_repair(self, session):
        """S99 r4 (user: "Why is the mirror in $6b moving? I never wanted it
        to move. It also didnt move in earlier editor versions."): tiles that
        sit in a 'source' room's animated slots without being that room's
        animated art started moving when S99 gave clones their source
        animation. List them and offer the fix (one undo step)."""
        from PySide6.QtWidgets import QMessageBox
        from editor2.core.animation import rng
        try:
            rep = session.doc.stray_report()
        except Exception:
            rep = []
        if not rep:
            return
        lines = '\n'.join(f"• {name}: tiles in slots {rng(sl)} move with {PN.vanilla_name(mid)}'s "
                          'animation' for _rid, name, sl, mid in rep)
        self.log.appendPlainText('ANIMATION: unintended moving tiles found —\n' + lines)
        if QMessageBox.question(
                self, 'Tiles moving by accident',
                'Since this editor version, a room made from a vanilla room plays that '
                'room\'s own animation (water, flames…). These tiles of yours sit in the '
                'slots that animation moves, so they move too:\n\n' + lines +
                '\n\nMove them to still slots? (The rooms\' own animation keeps working; '
                'one undo step.)') != QMessageBox.Yes:
            return
        from editor2.app.rooms.commands import SnapshotCommand
        cmd = SnapshotCommand(session, 'Stop unintended animation',
                              lambda doc: doc.repair_animation())
        session.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'Tiles moving by accident', str(cmd.error))
            return
        for n in cmd.result or []:
            self.log.appendPlainText('FIXED: ' + n + ' — Save to keep it')
        session.structureChanged.emit()

    def _draw_tab(self):
        """The Rooms tab's Draw tab when it owns ⌘Z (a drawing loaded, the tab shown)."""
        dt = getattr(self.rooms_tab, 'draw_tab', None) if self.rooms_tab is not None else None
        try:
            return dt if dt is not None and dt.owns_undo() else None
        except RuntimeError:            # the tab already torn down (exit, another project)
            return None

    def _undo(self):
        dt = self._draw_tab()
        if dt is not None and dt.can_undo():
            dt.undo()
        elif self.session is not None:
            self.session.undo.undo()

    def _redo(self):
        dt = self._draw_tab()
        if dt is not None and dt.can_redo():
            dt.redo()
        elif self.session is not None:
            self.session.undo.redo()

    def _sync_undo(self):
        s = self.session
        if s is None:
            return
        dt = self._draw_tab()
        try:
            if dt is not None and dt.can_undo():
                self.a_undo.setEnabled(True)
                self.a_undo.setText('Undo stroke (Draw)')
            else:
                self.a_undo.setEnabled(s.undo.canUndo())
                self._undo_text(s.undo.undoText())
            if dt is not None and dt.can_redo():
                self.a_redo.setEnabled(True)
                self.a_redo.setText('Redo stroke (Draw)')
            else:
                self.a_redo.setEnabled(s.undo.canRedo())
                self._redo_text(s.undo.redoText())
        except RuntimeError:            # actions torn down at exit
            pass

    def _undo_text(self, t):
        try:
            self.a_undo.setText(f'Undo {t}' if t else 'Undo')
        except RuntimeError:            # action already torn down at exit
            pass

    def _redo_text(self, t):
        try:
            self.a_redo.setText(f'Redo {t}' if t else 'Redo')
        except RuntimeError:
            pass

    def reload_project(self):
        if self.session and self._confirm_discard():
            self.open_project(self.session.project_dir)

    def _dirty_changed(self, dirty):
        name = self.session.name if self.session else ''
        from editor2 import EDITOR_REVISION
        self.setWindowTitle(f"DWM1 Editor ({EDITOR_REVISION}) — {name}{' •' if dirty else ''}")
        self.setWindowModified(dirty)

    def save(self):
        if not self.session:
            return False
        ct = self.built_tab('cutscenes_tab')             # S119b: a text still being typed
        if ct is not None and getattr(ct, 'editor', None) is not None:
            try:
                ct.editor.form.flush()
            except RuntimeError:
                pass
        try:
            self.session.save()
        except Exception as e:
            QMessageBox.warning(self, 'Save failed', str(e))
            return False
        self.statusBar().showMessage(f'Saved {self.session.doc.path}', 4000)
        return True

    def _confirm_discard(self):
        if not self.session or not self.session.dirty:
            return True
        r = QMessageBox.question(
            self, 'Unsaved changes', 'Save changes to the project first?',
            QMessageBox.Save | QMessageBox.Discard | QMessageBox.Cancel)
        if r == QMessageBox.Save:
            return self.save()
        return r == QMessageBox.Discard

    def _ids_toggled(self, on):
        """S143: View > Show technical ids — every view re-fills its labels."""
        PN.SHOW_IDS = bool(on)
        self.settings.setValue('view/show_ids', bool(on))
        self.settings.sync()             # S145: written now (a later window reads it back)
        if self.session is not None:
            self.session.structureChanged.emit()

    def _mute_toggled(self, on):
        self.settings.setValue('playback/mute', bool(on))
        self.settings.sync()
        ct = self.built_tab('cutscenes_tab')
        if ct is not None:
            ct.apply_mute()
        self.statusBar().showMessage('Game playback muted' if on else 'Game playback sound on',
                                     3000)

    def closeEvent(self, ev):
        if self._confirm_discard():
            ct = self.built_tab('cutscenes_tab')
            if ct is not None:
                try:
                    ct.shutdown()
                except RuntimeError:
                    pass
            bt = self.built_tab('balance_tab')
            if bt is not None:                   # S130
                try:
                    bt.shutdown()
                except RuntimeError:
                    pass
            self._save_window()                  # S169
            ev.accept()
        else:
            ev.ignore()

    # ---------------- build + run ----------------
    def build(self):
        if not self.session or (self.worker and self.worker.isRunning()):
            return
        if self.session.dirty and not self.save():
            return
        self.a_build.setEnabled(False)
        self.a_run.setEnabled(False)
        self.statusBar().showMessage('Building…')
        self.log_dock.show()
        self.worker = BuildWorker(
            REPO, self.session.project_dir,
            rgbds_dir=self.settings.value('rgbds/dir', '') or None)
        self.worker.log.connect(self.log.appendPlainText)
        self.worker.finished_build.connect(self._build_done)
        self.worker.start()

    def _log_menu(self, pos):
        from PySide6.QtWidgets import QMenu
        m = self.log.createStandardContextMenu()
        m.addSeparator()
        a = m.addAction('Copy all')
        a.triggered.connect(lambda: QApplication.clipboard().setText(self.log.toPlainText()))
        a = m.addAction('Clear')
        a.triggered.connect(self.log.clear)
        m.exec(self.log.mapToGlobal(pos))

    def _show_build_error(self, text):
        """The build's error in a dialog whose text can be selected and copied."""
        box = QMessageBox(self)
        box.setIcon(QMessageBox.Warning)
        box.setWindowTitle('Build failed')
        first = str(text).strip().splitlines()[0] if str(text).strip() else 'unknown error'
        box.setText('The project could not be built:')
        box.setInformativeText(first[:600])
        box.setDetailedText(str(text))
        box.setTextInteractionFlags(Qt.TextSelectableByMouse | Qt.TextSelectableByKeyboard)
        copy = box.addButton('Copy error', QMessageBox.ActionRole)
        box.addButton(QMessageBox.Ok)
        copy.clicked.connect(lambda: QApplication.clipboard().setText(str(text)))
        box.exec()

    def _build_done(self, res):
        self.last_result = res
        self.a_build.setEnabled(True)
        if res.ok:
            self.session.last_rom = res.rom_path
            self.a_run.setEnabled(True)
            usage = '  '.join(f'{b}:{n}B' for b, n in sorted(res.bank_usage.items()))
            self.statusBar().showMessage(
                f'Built rom.gbc · md5 {res.rom_md5} · {usage}')
            self.session.rebind_build()
            self.session.buildFinished.emit(res.rom_path)
        else:
            self.statusBar().showMessage('Build failed — see Build log')
            if not getattr(self, '_quiet_build_errors', False):
                self._show_build_error(res.error)
        self.build_tab.refresh(self)

    def validate(self):
        if not self.session:
            return
        if self.session.dirty and not self.save():
            return
        from editor2.core import compiler as C
        self.log_dock.show()
        try:
            _out, _prj, warnings = C.compile_project(self.session.project_dir, REPO)
        except Exception as e:
            self.log.appendPlainText(f'VALIDATION FAILED:\n{e}')
            self.statusBar().showMessage('Validation failed — see Build log')
            return
        self.log.appendPlainText(
            f'Validation OK — {len(warnings)} warning(s)'
            + (':\n  ' + '\n  '.join(warnings) if warnings else ''))
        self.statusBar().showMessage(f'Validation OK, {len(warnings)} warning(s)', 5000)

    def run_rom(self):
        if not self.session or not self.session.last_rom:
            return
        try:
            cmd = self.settings.value('emulator/command', '') or None
            desc = emulator.launch(self.session.last_rom, cmd)
            self.log.appendPlainText(f'Launched: {desc}')
        except RuntimeError as e:
            QMessageBox.warning(self, 'Cannot run ROM', str(e))

    # ---------------- compat for the S72 smoke test ----------------
    @property
    def project_path(self):
        return self.session.project_dir if self.session else None

    @property
    def room_list(self):
        return self.rooms_tab.room_list if self.rooms_tab else None


def main():
    app = QApplication(sys.argv)
    app.setApplicationName('DWM1 Editor')
    # S171: a widget the editor drops can never pop up as an empty window
    # (editor2/app/qt_safe.py); a stopped one is named in the Build log
    from editor2.app.qt_safe import StrayWindowGuard
    holder = {}
    guard = StrayWindowGuard(app, lambda msg: holder['w'].log.appendPlainText(msg)
                             if 'w' in holder else print(msg))
    from editor2.app import appmode
    appmode.icon_for(app)
    w = MainWindow(defer_open=True)
    holder['w'] = w
    app._stray_guard = guard
    w.show()
    from PySide6.QtCore import QTimer
    QTimer.singleShot(400, w.ask_for_rom_if_missing)
    sys.exit(app.exec())


if __name__ == '__main__':
    main()
