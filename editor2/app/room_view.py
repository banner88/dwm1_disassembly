"""room_view.py — the visual room display (EDITOR_DESIGN §11 Tier 1, S72).

Shows the selected room rendered with its real tileset / attrs / palette
from the last built ROM (editor2/core/render.py), with NPC / spawn / exit
markers and zoom. Read-only in the skeleton; painting is the RoomCanvas
milestone (ROADMAP Phase 3).
"""

try:
    from PIL import ImageQt
except ImportError as _e:                      # pragma: no cover
    raise ImportError(
        "The editor needs Pillow for room rendering: pip install Pillow"
    ) from _e

from PySide6.QtCore import Qt
from PySide6.QtGui import QPixmap
from PySide6.QtWidgets import (
    QCheckBox, QComboBox, QHBoxLayout, QLabel, QScrollArea, QVBoxLayout,
    QWidget)

from editor2.core.render import RoomRenderer, find_build


class RoomView(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.renderer = None
        self.room = None

        bar = QHBoxLayout()
        bar.setContentsMargins(4, 4, 4, 0)
        self.zoom = QComboBox()
        self.zoom.addItems(['1×', '2×', '3×'])
        self.zoom.setCurrentIndex(1)
        self.zoom.currentIndexChanged.connect(self.refresh)
        self.markers = QCheckBox('Show NPC / exit markers')
        self.markers.setChecked(True)
        self.markers.stateChanged.connect(self.refresh)
        self.source_label = QLabel('')
        bar.addWidget(QLabel('Zoom'))
        bar.addWidget(self.zoom)
        bar.addWidget(self.markers)
        bar.addStretch(1)
        bar.addWidget(self.source_label)

        self.canvas = QLabel('Open a project to view rooms.')
        self.canvas.setAlignment(Qt.AlignCenter)
        scroll = QScrollArea()
        scroll.setWidget(self.canvas)
        scroll.setWidgetResizable(True)

        lay = QVBoxLayout(self)
        lay.setContentsMargins(0, 0, 0, 0)
        lay.addLayout(bar)
        lay.addWidget(scroll)

    # -- wiring -------------------------------------------------------------
    def attach_build(self, project_path):
        """Bind to the project's latest build; returns True if one exists."""
        found = find_build(project_path)
        if not found:
            self.renderer = None
            self.canvas.setText(
                'No build yet — press Build (⌘B / Ctrl+B) to render this '
                'room from the real ROM data.')
            self.source_label.setText('')
            return False
        rom, sym = found
        self.renderer = RoomRenderer(rom, sym)
        self.source_label.setText(f'Rendered from {rom}')
        return True

    def show_room(self, room):
        self.room = room
        self.refresh()

    def refresh(self, *_):
        if self.room is None:
            return
        if self.renderer is None:
            self.attach_build_placeholder_text()
            return
        if self.room.get('placeholder'):
            self.canvas.setPixmap(QPixmap())
            self.canvas.setText(
                'Placeholder room (reserved mapID, never entered) — '
                'nothing to render.')
            return
        scale = self.zoom.currentIndex() + 1
        try:
            screens = self.renderer.render_room(
                self.room, scale=scale, markers=self.markers.isChecked())
        except Exception as e:
            self.canvas.setPixmap(QPixmap())
            self.canvas.setText(
                f'Cannot render this room from the current build:\n{e}\n'
                'Rebuild the project (⌘B / Ctrl+B) if it is out of date.')
            return
        img = self.renderer.stitch(screens, scale=scale)
        if img is None:
            self.canvas.setPixmap(QPixmap())
            self.canvas.setText('Room declares no screens.')
            return
        self.canvas.setPixmap(QPixmap.fromImage(ImageQt.ImageQt(img)))
        self.canvas.setText('')

    def attach_build_placeholder_text(self):
        self.canvas.setPixmap(QPixmap())
        self.canvas.setText(
            'No build yet — press Build (⌘B / Ctrl+B) to render this room '
            'from the real ROM data.')
