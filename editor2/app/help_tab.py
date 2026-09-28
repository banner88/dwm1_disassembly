"""help_tab.py — the editor's built-in help (S101 r2; user: "The editor needs
a help tab. As this gets bigger … needs lookup").

Topics are Markdown files in editor2/help/ (NN_name.md, shown in file order;
files starting with '_' are not topics;
the first "# " line is the topic title). The search box filters topics by
their text. editor2/help/_revision.md names the EDITOR_REVISION the help was
last brought up to date for — test_app fails when it lags the editor, so
every editor delivery updates the help with it (SESSION_PROTOCOL wrap-up).
"""

import os

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (QHBoxLayout, QLabel, QLineEdit, QListWidget, QListWidgetItem,
                               QSplitter, QTextBrowser, QVBoxLayout, QWidget)

HELP_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'help')


def help_revision():
    try:
        return open(os.path.join(HELP_DIR, '_revision.md')).read().strip().splitlines()[-1].strip()
    except OSError:
        return ''


def load_topics():
    """[(title, markdown text, file name)] in file order."""
    out = []
    try:
        names = sorted(n for n in os.listdir(HELP_DIR) if n.endswith('.md') and not n.startswith('_'))
    except OSError:
        names = []
    for n in names:
        text = open(os.path.join(HELP_DIR, n), encoding='utf-8').read()
        title = next((ln[2:].strip() for ln in text.splitlines() if ln.startswith('# ')), n)
        out.append((title, text, n))
    return out


class HelpTab(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.topics = load_topics()
        v = QVBoxLayout(self)
        row = QHBoxLayout()
        self.search = QLineEdit()
        self.search.setPlaceholderText('Search the help…')
        self.search.textChanged.connect(self._filter)
        row.addWidget(self.search, 1)
        from editor2 import EDITOR_REVISION
        rev = help_revision()
        note = QLabel(f'help for editor {rev}' + ('' if rev == EDITOR_REVISION else
                                                  f'  (editor is {EDITOR_REVISION})'))
        note.setStyleSheet('color:#888;')
        row.addWidget(note)
        v.addLayout(row)
        split = QSplitter(Qt.Horizontal)
        self.list = QListWidget()
        self.list.currentRowChanged.connect(self._show)
        split.addWidget(self.list)
        self.view = QTextBrowser()
        self.view.setOpenExternalLinks(True)
        split.addWidget(self.view)
        split.setStretchFactor(1, 1)
        split.setSizes([240, 900])
        v.addWidget(split, 1)
        self._filter('')

    def _filter(self, text):
        q = (text or '').strip().lower()
        self.list.blockSignals(True)
        self.list.clear()
        for i, (title, body, _n) in enumerate(self.topics):
            if not q or q in body.lower():
                it = QListWidgetItem(title)
                it.setData(Qt.UserRole, i)
                self.list.addItem(it)
        self.list.blockSignals(False)
        if self.list.count():
            self.list.setCurrentRow(0)
        else:
            self.view.setMarkdown(f'No help topic mentions “{text}”.')

    def _show(self, row):
        it = self.list.item(row)
        if it is None:
            return
        self.view.setMarkdown(self.topics[it.data(Qt.UserRole)][1])

    def show_topic(self, title_part):
        """Select the first topic whose title contains `title_part`."""
        self.search.clear()
        for r in range(self.list.count()):
            if title_part.lower() in self.list.item(r).text().lower():
                self.list.setCurrentRow(r)
                return True
        return False
