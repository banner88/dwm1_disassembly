"""main.py — DWM1 Editor walking skeleton (ROADMAP Phase 3, item 1; S72).

Open a project · room list · read-only room summary · Build ROM · Run in
emulator. PySide6, cross-platform (primary target macOS — S72 decision,
EDITOR_DESIGN §4). The GUI is a shell over editor2.core; it never encodes
game formats itself and a build here is byte-identical to
`tools/build_project.py --build` by construction (same code path).

Run:  pip install PySide6   then   python3 -m editor2.app
"""

import hashlib
import json
import os
import sys

from PySide6.QtCore import QSettings, Qt
from PySide6.QtGui import QAction, QKeySequence
from PySide6.QtWidgets import (
    QApplication, QDockWidget, QFileDialog, QInputDialog, QLabel,
    QListWidget, QListWidgetItem, QMainWindow, QMessageBox, QPlainTextEdit,
    QSplitter, QStatusBar, QTreeWidget, QTreeWidgetItem, QVBoxLayout,
    QWidget)

from editor2.app.build_worker import BuildWorker
from editor2.core import emulator

REPO = os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))))
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'   # PROJECT_STATE canonical


def _hex(v):
    """Schema values arrive as '0x6B' / '$6B' / int (PROJECT_COMPILER §2)."""
    if isinstance(v, int):
        return v
    s = str(v).strip()
    if s.startswith('$'):
        return int(s[1:], 16)
    return int(s, 0)


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.settings = QSettings('dwm1_disassembly', 'DWM1Editor')
        self.project_path = None
        self.project_data = None
        self.last_rom = None
        self.worker = None
        self._build_ui()
        self._build_menu()
        self._restore_rom_status()
        last = self.settings.value('recent/project')
        if last and os.path.exists(last):
            self.open_project(last)

    # ---------------- UI scaffolding ----------------
    def _build_ui(self):
        self.setWindowTitle('DWM1 Editor')
        self.resize(1100, 720)

        self.room_list = QListWidget()
        self.room_list.currentItemChanged.connect(self._show_room)

        self.detail = QTreeWidget()
        self.detail.setHeaderLabels(['Field', 'Value'])
        self.detail.setColumnWidth(0, 240)

        split = QSplitter()
        left = QWidget()
        lv = QVBoxLayout(left)
        lv.setContentsMargins(4, 4, 4, 4)
        self.rooms_header = QLabel('No project open')
        lv.addWidget(self.rooms_header)
        lv.addWidget(self.room_list)
        split.addWidget(left)
        split.addWidget(self.detail)
        split.setStretchFactor(1, 1)
        self.setCentralWidget(split)

        self.log = QPlainTextEdit()
        self.log.setReadOnly(True)
        self.log.setMaximumBlockCount(5000)
        dock = QDockWidget('Build log', self)
        dock.setWidget(self.log)
        dock.setFeatures(QDockWidget.DockWidgetMovable)
        self.addDockWidget(Qt.BottomDockWidgetArea, dock)

        self.setStatusBar(QStatusBar())
        self.rom_status = QLabel()
        self.statusBar().addPermanentWidget(self.rom_status)

    def _build_menu(self):
        m_file = self.menuBar().addMenu('&File')
        a_open = QAction('&Open project…', self)
        a_open.setShortcut(QKeySequence.Open)
        a_open.triggered.connect(self._open_dialog)
        m_file.addAction(a_open)
        a_reload = QAction('&Reload project', self)
        a_reload.setShortcut(QKeySequence.Refresh)
        a_reload.triggered.connect(
            lambda: self.project_path and self.open_project(self.project_path))
        m_file.addAction(a_reload)
        m_file.addSeparator()
        a_rom = QAction('Locate original ROM…', self)
        a_rom.triggered.connect(self._locate_rom)
        m_file.addAction(a_rom)
        a_emu = QAction('Set emulator command…', self)
        a_emu.triggered.connect(self._set_emulator)
        m_file.addAction(a_emu)

        m_build = self.menuBar().addMenu('&Build')
        self.a_build = QAction('&Build ROM', self)
        self.a_build.setShortcut(QKeySequence('Ctrl+B'))   # ⌘B on macOS
        self.a_build.triggered.connect(self.build)
        self.a_build.setEnabled(False)
        m_build.addAction(self.a_build)
        self.a_run = QAction('&Run in emulator', self)
        self.a_run.setShortcut(QKeySequence('Ctrl+R'))     # ⌘R on macOS
        self.a_run.triggered.connect(self.run_rom)
        self.a_run.setEnabled(False)
        m_build.addAction(self.a_run)

    # ---------------- ROM + emulator preferences ----------------
    def _restore_rom_status(self):
        rom = self.settings.value('rom/path')
        if rom and os.path.exists(rom):
            ok = hashlib.md5(
                open(rom, 'rb').read()).hexdigest() == ORIGINAL_MD5
            self.rom_status.setText(
                'ROM: verified' if ok else 'ROM: WRONG FILE')
        else:
            self.rom_status.setText('ROM: not set (File → Locate…)')

    def _locate_rom(self):
        path, _ = QFileDialog.getOpenFileName(
            self, 'Locate DWM-original.gbc', '', 'GBC ROM (*.gbc)')
        if not path:
            return
        got = hashlib.md5(open(path, 'rb').read()).hexdigest()
        if got != ORIGINAL_MD5:
            QMessageBox.warning(
                self, 'Wrong ROM',
                f'MD5 {got}\nexpected {ORIGINAL_MD5}.\n'
                'Select the unmodified original ROM.')
            return
        self.settings.setValue('rom/path', path)
        self._restore_rom_status()

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
        path = QFileDialog.getExistingDirectory(
            self, 'Open project folder (contains project.json)')
        if path:
            self.open_project(path)

    def open_project(self, path):
        pj = (path if path.endswith('.json')
              else os.path.join(path, 'project.json'))
        if not os.path.exists(pj):
            QMessageBox.warning(self, 'Not a project',
                                f'No project.json in {path}.')
            return
        try:
            data = json.load(open(pj))
        except Exception as e:
            QMessageBox.warning(self, 'Cannot read project', str(e))
            return
        self.project_path = path
        self.project_data = data
        self.settings.setValue('recent/project', path)
        name = data.get('meta', {}).get('name', os.path.basename(path))
        self.setWindowTitle(f'DWM1 Editor — {name}')
        self._fill_rooms()
        self.a_build.setEnabled(True)
        self.a_run.setEnabled(False)
        self.log.appendPlainText(f'Opened project: {path}')

    def _fill_rooms(self):
        self.room_list.clear()
        rooms = self.project_data.get('custom', {}).get('rooms', [])
        self.rooms_header.setText(f'Rooms ({len(rooms)})')
        for r in rooms:
            map_id = _hex(r.get('mapID', 0))
            tag = ' [placeholder]' if r.get('placeholder') else ''
            it = QListWidgetItem(f"${map_id:02X}  {r.get('id', '?')}{tag}")
            it.setData(Qt.UserRole, r)
            self.room_list.addItem(it)
        if rooms:
            self.room_list.setCurrentRow(0)

    def _show_room(self, item, _prev=None):
        self.detail.clear()
        if not item:
            return
        r = item.data(Qt.UserRole)

        def add(parent, k, v):
            node = QTreeWidgetItem([str(k), '' if isinstance(v, (dict, list))
                                    else str(v)])
            (parent.addChild(node) if parent
             else self.detail.addTopLevelItem(node))
            if isinstance(v, dict):
                for kk, vv in v.items():
                    add(node, kk, vv)
            elif isinstance(v, list):
                for i, vv in enumerate(v):
                    add(node, i, vv)
            return node

        for k, v in r.items():
            add(None, k, v)
        self.detail.expandToDepth(1)

    # ---------------- build + run ----------------
    def build(self):
        if self.worker and self.worker.isRunning():
            return
        self.a_build.setEnabled(False)
        self.a_run.setEnabled(False)
        self.statusBar().showMessage('Building…')
        self.worker = BuildWorker(REPO, self.project_path)
        self.worker.log.connect(self.log.appendPlainText)
        self.worker.finished_build.connect(self._build_done)
        self.worker.start()

    def _build_done(self, res):
        self.a_build.setEnabled(True)
        if res.ok:
            self.last_rom = res.rom_path
            self.a_run.setEnabled(True)
            usage = '  '.join(f'{b}:{n}B'
                              for b, n in sorted(res.bank_usage.items()))
            self.statusBar().showMessage(
                f'Built rom.gbc · md5 {res.rom_md5} · {usage}')
        else:
            self.statusBar().showMessage('Build failed — see Build log')

    def run_rom(self):
        if not self.last_rom:
            return
        try:
            cmd = self.settings.value('emulator/command', '') or None
            desc = emulator.launch(self.last_rom, cmd)
            self.log.appendPlainText(f'Launched: {desc}')
        except RuntimeError as e:
            QMessageBox.warning(self, 'Cannot run ROM', str(e))


def main():
    app = QApplication(sys.argv)
    app.setApplicationName('DWM1 Editor')
    w = MainWindow()
    w.show()
    sys.exit(app.exec())


if __name__ == '__main__':
    main()
