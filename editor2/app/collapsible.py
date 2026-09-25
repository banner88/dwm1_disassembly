"""collapsible.py — a titled section that folds away (S96 user QOL:
"the right-hand panel … taking up a lot of space; can I hide them with a
down arrow, or resize parts with their own scroll bar?").

`Section(title, content, key)`: a header button with ▼ / ▶ and an optional
row of extra header widgets; the content hides when folded and the section
then asks for no more height than its header — inside a vertical QSplitter
the neighbours take the room. The folded state persists in QSettings under
`ui/section/<key>`.
"""

from PySide6.QtCore import QSettings, Qt, Signal
from PySide6.QtWidgets import (QHBoxLayout, QSizePolicy, QToolButton,
                               QVBoxLayout, QWidget)

MAX = 16777215


class Section(QWidget):
    toggled = Signal(bool)            # True = expanded

    def __init__(self, title, content, key, parent=None, expanded=True):
        super().__init__(parent)
        self.key = key
        self.content = content
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        v.setSpacing(1)
        head = QHBoxLayout()
        head.setContentsMargins(0, 0, 0, 0)
        self.button = QToolButton()
        self.button.setText(title)
        self.button.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
        self.button.setCheckable(True)
        self.button.setAutoRaise(True)
        self.button.setStyleSheet('QToolButton { font-weight: bold; }')
        self.button.toggled.connect(self._set)
        head.addWidget(self.button)
        self.head_extra = QHBoxLayout()
        head.addLayout(self.head_extra)
        head.addStretch(1)
        v.addLayout(head)
        v.addWidget(content, 1)
        st = QSettings('dwm1_disassembly', 'DWM1Editor').value(f'ui/section/{key}')
        on = expanded if st is None else (str(st).lower() in ('true', '1'))
        self.button.setChecked(on)
        self._set(on, save=False)

    def add_header_widget(self, w):
        self.head_extra.addWidget(w)

    def is_expanded(self):
        return self.button.isChecked()

    def _set(self, on, save=True):
        self.button.setArrowType(Qt.DownArrow if on else Qt.RightArrow)
        self.content.setVisible(on)
        if on:
            self.setMaximumHeight(MAX)
            self.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Expanding)
        else:
            self.setMaximumHeight(self.button.sizeHint().height() + 4)
            self.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
        if save:
            QSettings('dwm1_disassembly', 'DWM1Editor').setValue(f'ui/section/{self.key}', on)
        self.toggled.emit(on)
