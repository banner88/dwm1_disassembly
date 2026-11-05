"""help_tab.py — the editor's built-in help (S101 r2; user: "The editor needs a help
tab. As this gets bigger … needs lookup").

Topics are Markdown files in editor2/help/ (NN_name.md, shown in file order;
files starting with '_' are not topics;
the first "# " line is the topic title). The search box filters topics by
their text. editor2/help/_revision.md names the EDITOR_REVISION the help was
last brought up to date for — test_app fails when it lags the editor, so
every editor delivery updates the help with it (SESSION_PROTOCOL wrap-up).

S167 (ROADMAP P3.H — user: "a glossary, a '?' button per section, screenshots"):
  * links between topics: `[text](11_doors.md)` or `[text](11_doors.md#The World tab)`
    open that topic (at that heading); `[text](#Heading)` a heading of this topic;
    http(s) links open in the browser;
  * pictures: `![…](img/rooms.png)` — editor2/help/img/ (tools/help_screenshots.py
    makes the tab pictures from the example project);
  * `open_help(topic, heading)` — what every "?" button and F1 call
    (editor2/app/context_help.py); "◀ Back to …" returns to the tab you came from,
    "◀ Previous" to the topic before.
"""

import os

from PySide6.QtCore import Qt, QUrl
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import (QHBoxLayout, QLabel, QLineEdit, QListWidget, QListWidgetItem,
                               QPushButton, QSplitter, QTextBrowser, QVBoxLayout, QWidget)

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


def topic_headings(md):
    """The '#'-headings of a topic's Markdown, in order (text only)."""
    out = []
    fence = False
    for ln in md.splitlines():
        if ln.startswith('```'):
            fence = not fence
        if not fence and ln.startswith('#'):
            out.append(ln.lstrip('#').strip())
    return out


def _norm(s):
    return ' '.join(''.join(c.lower() if c.isalnum() else ' ' for c in s).split())


class HelpTab(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.topics = load_topics()
        self.current = None              # index into self.topics
        self.history = []                # previous (topic index, heading)
        self.return_to = None            # (QTabWidget, widget) of the "?" that opened us
        v = QVBoxLayout(self)
        row = QHBoxLayout()
        self.btn_back_tab = QPushButton('◀ Back')
        self.btn_back_tab.setToolTip('Back to the tab you pressed "?" on')
        self.btn_back_tab.clicked.connect(self._back_to_tab)
        self.btn_back_tab.setVisible(False)
        row.addWidget(self.btn_back_tab)
        self.btn_prev = QPushButton('◀ Previous topic')
        self.btn_prev.setToolTip('The help topic you were reading before this one')
        self.btn_prev.clicked.connect(self._previous)
        self.btn_prev.setEnabled(False)
        row.addWidget(self.btn_prev)
        self.search = QLineEdit()
        self.search.setPlaceholderText('Search the help…')
        self.search.textChanged.connect(self._filter)
        row.addWidget(self.search, 1)
        gl = QPushButton('Glossary')
        gl.setToolTip('Every word the editor uses, in one list, each with a link to its topic')
        gl.clicked.connect(lambda: self.open_topic('95_glossary.md'))
        row.addWidget(gl)
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
        self.view.setOpenLinks(False)            # S167: topic links are ours
        self.view.anchorClicked.connect(self._link)
        self.view.setSearchPaths([HELP_DIR])     # S167: ![…](img/x.png)
        split.addWidget(self.view)
        split.setStretchFactor(1, 1)
        split.setSizes([240, 900])
        v.addWidget(split, 1)
        self._filter('')

    # ------------------------------------------------------------- list
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
            self._show(0)
        else:
            self.view.setMarkdown(f'No help topic mentions “{text}”.')

    def _show(self, row, record=True):
        it = self.list.item(row)
        if it is None:
            return
        i = it.data(Qt.UserRole)
        if record and self.current is not None and self.current != i:
            self.history.append(self.current)
            self.btn_prev.setEnabled(True)
        self.current = i
        self.view.setMarkdown(self.topics[i][1])

    # ------------------------------------------------------------- navigation
    def _index_of(self, topic):
        """A topic by file name ('11_doors.md', '11_doors') or by part of its title."""
        t = (topic or '').strip()
        for i, (_title, _b, n) in enumerate(self.topics):
            if t == n or t + '.md' == n:
                return i
        for i, (title, _b, _n) in enumerate(self.topics):
            if t and t.lower() in title.lower():
                return i
        return None

    def open_topic(self, topic, heading=None, record=True):
        """Show `topic` (file name or part of its title), scrolled to `heading`
        (the first heading that equals it, else that contains it). True when found."""
        i = self._index_of(topic)
        if i is None:
            return False
        if self.search.text():
            self.search.blockSignals(True)
            self.search.clear()
            self.search.blockSignals(False)
            self._filter('')
        for r in range(self.list.count()):
            if self.list.item(r).data(Qt.UserRole) == i:
                self.list.blockSignals(True)
                self.list.setCurrentRow(r)
                self.list.blockSignals(False)
                self._show(r, record)
                break
        self.view.verticalScrollBar().setValue(0)
        if heading:
            self.scroll_to_heading(heading)
        return True

    def scroll_to_heading(self, heading):
        """Scroll the shown topic to the heading block matching `heading`."""
        doc = self.view.document()
        want = _norm(heading)
        best = None
        b = doc.begin()
        while b.isValid():
            if b.blockFormat().headingLevel() > 0:
                t = _norm(b.text())
                if t == want:
                    best = b
                    break
                if best is None and want and want in t:
                    best = b
            b = b.next()
        if best is None:
            return False
        y = doc.documentLayout().blockBoundingRect(best).top()
        self.view.verticalScrollBar().setValue(int(y))
        return True

    def show_topic(self, title_part):
        """Select the first topic whose title contains `title_part`."""
        self.search.clear()
        for r in range(self.list.count()):
            if title_part.lower() in self.list.item(r).text().lower():
                self.list.setCurrentRow(r)
                return True
        return False

    def _previous(self):
        if not self.history:
            return
        i = self.history.pop()
        self.btn_prev.setEnabled(bool(self.history))
        self.open_topic(self.topics[i][2], record=False)

    def _link(self, url):
        s = url.toString()
        if url.scheme() in ('http', 'https', 'mailto'):
            QDesktopServices.openUrl(url)
            return
        path, _, frag = s.partition('#')
        frag = QUrl.fromPercentEncoding(frag.encode()) if frag else ''
        if not path:
            self.scroll_to_heading(frag)
            return
        self.open_topic(os.path.basename(path), frag or None)

    # ------------------------------------------------------------- back to the tab
    def set_return(self, tabs, widget, label):
        self.return_to = (tabs, widget)
        self.btn_back_tab.setText(f'◀ Back to {label}')
        self.btn_back_tab.setVisible(True)

    def _back_to_tab(self):
        if self.return_to:
            tabs, w = self.return_to
            if tabs.indexOf(w) >= 0:
                tabs.setCurrentWidget(w)
        self.btn_back_tab.setVisible(False)
        self.return_to = None
