"""session.py — one open project as the GUI sees it (S93).

Holds the Document (editable project.json), the live ProjectRenderer,
the QUndoStack, and the change signals every tab listens to. Tabs never
touch project.json directly: they push QUndoCommands (rooms/commands.py)
that mutate the Document and emit the right signal.
"""

import os

from PySide6.QtCore import QObject, QSettings, Signal
from PySide6.QtGui import QUndoStack

from editor2.core.document import Document
from editor2.core.render import find_build
from editor2.core.render_project import ProjectRenderer

REPO = os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))))


class Session(QObject):
    # coarse-grained: something structural changed (rooms/screens/states
    # added or removed, layouts localized) — rebuild views
    structureChanged = Signal()
    # a layout grid changed (tiles or attr) — re-render anything showing it
    layoutChanged = Signal(str)
    # a palette changed
    paletteChanged = Signal(str)
    # dirty flag flipped
    dirtyChanged = Signal(bool)
    # a build finished (rom path or '')
    buildFinished = Signal(str)

    def __init__(self, project_path, settings=None):
        super().__init__()
        self.settings = settings or QSettings('dwm1_disassembly', 'DWM1Editor')
        self.doc = Document(project_path)
        self.project_dir = self.doc.project_dir
        self.undo = QUndoStack(self)
        self.undo.cleanChanged.connect(self._clean_changed)
        self.last_rom = None
        self.renderer = self._make_renderer()

    # ------------------------------------------------------------ renderer
    def _make_renderer(self):
        rom = self.settings.value('rom/path') or os.path.join(
            REPO, 'data', 'DWM-original.gbc')
        found = find_build(self.project_dir)
        build_rom = found[0] if found else None
        if found:
            self.last_rom = found[0]
        r = ProjectRenderer(REPO, self.project_dir, self.doc.data,
                            rom_path=rom, build_rom_path=build_rom)
        self.doc.vanilla = r          # S96: tileset usage / vocabulary queries
        return r

    def refresh_renderer(self):
        """After a build (new legacy rows) or a structural change."""
        self.renderer.invalidate()

    def rebind_build(self):
        self.renderer = self._make_renderer()
        self.structureChanged.emit()

    # --------------------------------------------------------------- state
    def _clean_changed(self, clean):
        self.dirtyChanged.emit(not clean)

    @property
    def dirty(self):
        return not self.undo.isClean()

    def save(self):
        self.doc.save()
        self.undo.setClean()
        self.dirtyChanged.emit(False)

    @property
    def name(self):
        return self.doc.data.get('meta', {}).get(
            'name', os.path.basename(self.project_dir))
