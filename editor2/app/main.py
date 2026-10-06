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
                               QStatusBar, QStyle, QTabWidget, QToolBar,
                               QUndoView, QVBoxLayout, QWidget)

from editor2.app.build_worker import BuildWorker
from editor2.app.session import REPO, Session
from editor2.app.rooms.tab import RoomsTab
from editor2.core import emulator

ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'   # PROJECT_STATE canonical

STUB_TABS = [
    ('Gates', 'P3.7b', 'Custom rooms on gate floors (open a project); gate settings + boss floor = part 2.'),
    ('Monsters', 'P3.10', 'Species data, enemy rows, new species from sprite sheets (open a project).'),
    ('Skills', 'P3.11', 'Names, SKIL text, MP, learning, power, targets, AI, looks (open a project).'),
    ('Breeding', 'P3.12', 'Recipe editor + the randomizer tree explorer, live re-sim.'),
    ('Encounters', 'P3.13a', 'Every wild-monster list, gate floor plans, room battles, flag variants (open a project).'),
    ('Music', 'P3.13b', 'Song library with preview, MIDI import, room / gate / battle music (open a project).'),
    ('Progression && Flags', 'P3.14', 'Flag manager, quest forms, triggers-as-sentences.'),
    ('Balance', 'P3.15', 'TTK sweeps, what-if deltas, obedience curves (validated only).'),
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
    def __init__(self):
        super().__init__()
        self.settings = QSettings('dwm1_disassembly', 'DWM1Editor')
        self.session = None
        self.worker = None
        self.last_result = None
        self.rooms_tab = None
        self._build_ui()
        self._build_menu()
        self._restore_rom_status()
        last = self.settings.value('recent/project')
        if last and os.path.exists(last):
            self.open_project(last)

    # ---------------- UI scaffolding ----------------
    def _build_ui(self):
        from editor2 import EDITOR_REVISION
        self.setWindowTitle(f'DWM1 Editor ({EDITOR_REVISION})')
        self.resize(1500, 900)
        self.tabs = QTabWidget()
        self.tabs.setDocumentMode(True)
        self.setCentralWidget(self.tabs)
        self._fill_tabs()

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
        self.log_dock.setWidget(self.log)
        self.log_dock.setFeatures(QDockWidget.DockWidgetMovable
                                  | QDockWidget.DockWidgetClosable)
        self.addDockWidget(Qt.BottomDockWidgetArea, self.log_dock)
        self.resizeDocks([self.log_dock], [110], Qt.Vertical)

        self.undo_view = QUndoView()
        self.undo_dock = QDockWidget('History', self)
        self.undo_dock.setWidget(self.undo_view)
        self.undo_dock.setFeatures(QDockWidget.DockWidgetMovable
                                   | QDockWidget.DockWidgetClosable)
        self.addDockWidget(Qt.RightDockWidgetArea, self.undo_dock)
        self.undo_dock.hide()

        self.setStatusBar(QStatusBar())
        self.rom_status = QLabel()
        self.statusBar().addPermanentWidget(self.rom_status)

    def _fill_tabs(self):
        old = getattr(self, 'cutscenes_tab', None)
        if old is not None:                      # S118: stop its recorder / playback
            try:
                old.shutdown()
            except RuntimeError:
                pass
            self.cutscenes_tab = None
        self.tabs.clear()
        if self.session:
            self.rooms_tab = RoomsTab(self.session)
            self.rooms_tab.status.connect(self.statusBar().showMessage)
            self.rooms_tab.gatesRequested.connect(self._open_gates_for)
            self.tabs.addTab(self.rooms_tab, 'Rooms')
            from editor2.app.import_tab import ImportTab
            self.import_tab = ImportTab(self.session)
            self.tabs.addTab(self.import_tab, 'Import art')
            # S118 (P3.8 part A): every scene of the game and the project —
            # storyboard, recorded frames, Playback in the real game
            from editor2.app.cutscenes_tab import CutscenesTab
            self.cutscenes_tab = CutscenesTab(self.session)
            self.tabs.addTab(self.cutscenes_tab, 'Cutscenes')
        else:
            self.rooms_tab = None
            self.tabs.addTab(_stub('Rooms', 'P3.3', 'Open a project (File → Open) to edit rooms.'),
                             'Rooms')
        for title, box, blurb in STUB_TABS:
            if title == 'Gates' and self.session:
                # S100 (P3.7b part 1): custom rooms served on gate floors
                from editor2.app.gates_tab import GatesTab
                self.gates_tab = GatesTab(self.session)
                self.gates_tab.openRoomRequested.connect(self._open_gate_room)
                self.tabs.addTab(self.gates_tab, 'Gates')
                continue
            if title == 'Monsters':
                # S104 (P3.10a): families — members, dialogue voice, Spirit names
                if self.session:
                    from editor2.app.families_tab import FamiliesTab
                    self.families_tab = FamiliesTab(self.session)
                    self.tabs.addTab(self.families_tab, 'Families')
                else:
                    self.tabs.addTab(_stub('Families', 'P3.10a', 'Family members, dialogue, Spirit names (open a project).'),
                                     'Families')
                if self.session:
                    # S106 (P3.10 part 1): species data, enemy rows, new species
                    from editor2.app.monsters_tab import MonstersTab
                    self.monsters_tab = MonstersTab(self.session)
                    self.tabs.addTab(self.monsters_tab, 'Monsters')
                    # S108 (P3.10 part 3): every text in the game, searchable;
                    # "Texts that name it…" on the Monsters tab opens it filtered
                    from editor2.app.dialogue_tab import DialogueTab
                    self.dialogue_tab = DialogueTab(self.session)
                    self.tabs.addTab(self.dialogue_tab, 'Dialogue')
                    self.monsters_tab.showDialogue.connect(self._show_dialogue_for)
                    # S109 (P3.10b): the arena — fees, masters, 1-3 monster teams,
                    # the teams' enemy rows
                    from editor2.app.arena_tab import ArenaTab
                    self.arena_tab = ArenaTab(self.session)
                    self.tabs.addTab(self.arena_tab, 'Arena')
                    continue
            if title == 'Skills' and self.session:
                # S110 (P3.11): the original skills — names, SKIL text, MP,
                # learning, power, targets, AI, behaviour flags, looks
                from editor2.app.skills_tab import SkillsTab
                self.skills_tab = SkillsTab(self.session)
                self.tabs.addTab(self.skills_tab, 'Skills')
                # S112 (P3.11e): new battle animations from the stock frames
                from editor2.app.anims_tab import AnimationsTab
                self.anims_tab = AnimationsTab(self.session)
                self.tabs.addTab(self.anims_tab, 'Animations')
                continue
            if title == 'Encounters' and self.session:
                # S114 (P3.13a): every wild-monster list, gate floor plans,
                # room battles, flag variants
                from editor2.app.encounters_tab import EncountersTab
                self.encounters_tab = EncountersTab(self.session)
                self.tabs.addTab(self.encounters_tab, 'Encounters')
                continue
            if title == 'Music' and self.session:
                # S116 (P3.13b): the song library (the game's songs, DWM2, MIDI)
                # with preview on the game's own sound engine, MIDI import,
                # room / gate / battle music
                from editor2.app.music_tab import MusicTab
                self.music_tab = MusicTab(self.session)
                self.tabs.addTab(self.music_tab, 'Music')
                # S117 (P3.13c): shops — the five vanilla lists, the project's
                # own shops (sold by NPCs made shopkeepers), item prices
                from editor2.app.shops_tab import ShopsTab
                self.shops_tab = ShopsTab(self.session)
                self.tabs.addTab(self.shops_tab, 'Shops')
                continue
            if title == 'Breeding' and self.session:
                # S113 (P3.12): recipes, depth, try a cross, generate a tree
                from editor2.app.breeding_tab import BreedingTab
                self.breeding_tab = BreedingTab(self.session)
                self.tabs.addTab(self.breeding_tab, 'Breeding')
                continue
            if title.startswith('Progression') and self.session:
                # S124 (P3.14a): every flag — what turns it ON / OFF, what checks
                # it, in words with a link to the place; every trigger; problems
                from editor2.app.flags_tab import ProgressionTab
                self.progression_tab = ProgressionTab(self.session)
                self.progression_tab.navigate.connect(self.navigate_to)
                self.tabs.addTab(self.progression_tab, 'Progression && Flags')
                continue
            if title == 'Balance':
                # S98 (P3.7): the World graph sits before Balance, as in §5.0
                if self.session:
                    from editor2.app.world_tab import WorldTab
                    self.world_tab = WorldTab(self.session)
                    self.world_tab.openRequested.connect(self._open_world_node)
                    self.tabs.addTab(self.world_tab, 'World')
                else:
                    self.tabs.addTab(_stub('World', 'P3.7', 'Room / warp graph (open a project).'),
                                     'World')
            self.tabs.addTab(_stub(title, box, blurb), title)
        self.build_tab = BuildPlayTab(self)
        self.tabs.addTab(self.build_tab, 'Build && Play')
        from editor2.app.help_tab import HelpTab      # S101 r2
        self.help_tab = HelpTab()
        self.tabs.addTab(self.help_tab, 'Help')

    def _show_dialogue_for(self, sid):
        """Monsters tab → the Dialogue tab listing the texts that name `sid`."""
        self.dialogue_tab.show_monster(sid)
        self.tabs.setCurrentWidget(self.dialogue_tab)

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

        m_help = self.menuBar().addMenu('&Help')
        a_help = QAction('Editor &help', self)
        a_help.setShortcut(QKeySequence.HelpContents)          # F1
        a_help.triggered.connect(lambda: self.tabs.setCurrentWidget(self.help_tab))
        m_help.addAction(a_help)

        tb = QToolBar('Main')
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

    # ---------------- ROM + emulator preferences ----------------
    def _restore_rom_status(self):
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
        shutil.copy(os.path.join(tpl, 'project.json'), os.path.join(path, 'project.json'))
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
        self.a_undo.triggered.connect(session.undo.undo)
        self.a_redo.triggered.connect(session.undo.redo)
        session.undo.canUndoChanged.connect(self.a_undo.setEnabled)
        session.undo.canRedoChanged.connect(self.a_redo.setEnabled)
        session.undo.undoTextChanged.connect(self._undo_text)
        session.undo.redoTextChanged.connect(self._redo_text)
        session.dirtyChanged.connect(self._dirty_changed)
        self.undo_view.setStack(session.undo)
        # S96 space meters (banks $60/$64/$67/$71) in the status bar
        from editor2.app.space_meter import SpaceMeter
        if getattr(self, 'space_meter', None) is not None:
            self.statusBar().removeWidget(self.space_meter)
            self.space_meter.deleteLater()
        self.space_meter = SpaceMeter(session, REPO)
        self.statusBar().insertPermanentWidget(0, self.space_meter)
        self._fill_tabs()
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
        lines = '\n'.join(f"• {name}: tiles in slots {rng(sl)} move with ${mid:02X}'s "
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
        ct = getattr(self, 'cutscenes_tab', None)        # S119b: a text still being typed
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

    def _mute_toggled(self, on):
        self.settings.setValue('playback/mute', bool(on))
        self.settings.sync()
        ct = getattr(self, 'cutscenes_tab', None)
        if ct is not None:
            ct.apply_mute()
        self.statusBar().showMessage('Game playback muted' if on else 'Game playback sound on',
                                     3000)

    def closeEvent(self, ev):
        if self._confirm_discard():
            ct = getattr(self, 'cutscenes_tab', None)
            if ct is not None:
                try:
                    ct.shutdown()
                except RuntimeError:
                    pass
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
    w = MainWindow()
    w.show()
    sys.exit(app.exec())


if __name__ == '__main__':
    main()
