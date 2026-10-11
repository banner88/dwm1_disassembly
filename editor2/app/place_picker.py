"""place_picker.py — ONE searchable place picker for every room choice (S143,
ROADMAP ARC CAP4b).

Before S143 the editor had 28 room pickers, ~20 of them re-implementing the same
loop as a plain drop-down of every room labelled with its map id. Now every one is
a `PlacePicker` (a drop-down you can TYPE into: any part of a name or an area
narrows the list) filled from `core/place_names.Places` entries — names only,
grouped (Special / your rooms by area / the game's rooms by group). `ask_place`
is the same list as a dialog with a search box (it replaces QInputDialog.getItem
over rooms).

A PlacePicker is a QComboBox: callers keep `currentData()`, `findData()`,
`setCurrentIndex()`, `currentIndexChanged`, and may still `addItem()` items of
their own (e.g. "(none)") before or after `add_entries()`.
"""

from PySide6.QtCore import QStringListModel, Qt
from PySide6.QtGui import QBrush, QColor, QFont, QStandardItem, QStandardItemModel
from PySide6.QtWidgets import (QComboBox, QCompleter, QDialog, QDialogButtonBox,
                               QLabel, QLineEdit, QTreeWidget, QTreeWidgetItem,
                               QVBoxLayout)

HEADER_ROLE = Qt.UserRole + 41


class PlacePicker(QComboBox):
    """A searchable, grouped place drop-down."""

    def __init__(self, parent=None, placeholder='type to search…'):
        super().__init__(parent)
        self.setModel(QStandardItemModel(self))
        self.setEditable(True)
        self.setInsertPolicy(QComboBox.NoInsert)
        self.setMaxVisibleItems(24)
        self.lineEdit().setPlaceholderText(placeholder)
        self._names = QStringListModel(self)
        self._label_index = {}
        comp = QCompleter(self._names, self)
        comp.setCaseSensitivity(Qt.CaseInsensitive)
        comp.setFilterMode(Qt.MatchContains)
        comp.setCompletionMode(QCompleter.PopupCompletion)
        comp.setMaxVisibleItems(16)
        comp.activated[str].connect(self._picked)
        self.setCompleter(comp)
        self.lineEdit().editingFinished.connect(self._restore_text)
        self._last_group = None

    # ---- filling
    def clear(self):
        super().clear()
        self._last_group = None
        self._label_index = {}
        self._names.setStringList([])

    def _model(self):
        return self.model()

    def add_header(self, title):
        it = QStandardItem(title)
        it.setFlags(Qt.NoItemFlags)
        f = QFont()
        f.setBold(True)
        it.setFont(f)
        it.setForeground(QBrush(QColor('#8a8a8a')))
        it.setData(True, HEADER_ROLE)
        self._model().appendRow(it)

    def addItem(self, *args):                             # noqa: N802 (Qt API)
        super().addItem(*args)
        text = args[0] if isinstance(args[0], str) else args[1]
        self._index_label(self.count() - 1, text)

    def insertItem(self, *args):                          # noqa: N802 (Qt API)
        super().insertItem(*args)
        self._reindex()

    def _index_label(self, i, text):
        key = text.strip()
        if key and key not in self._label_index:
            self._label_index[key] = i
            names = self._names.stringList()
            names.append(key)
            self._names.setStringList(names)

    def _reindex(self):
        self._label_index = {}
        names = []
        for i in range(self.count()):
            if self.itemData(i, HEADER_ROLE):
                continue
            key = self.itemText(i).strip()
            if key and key not in self._label_index:
                self._label_index[key] = i
                names.append(key)
        self._names.setStringList(names)

    def add_entries(self, entries, headers=True):
        """Append place_names.PlaceEntry items, a header before each new group."""
        self.blockSignals(True)
        names = self._names.stringList()
        for e in entries:
            if headers and e.group != self._last_group:
                self.add_header(e.group)
                self._last_group = e.group
            it = QStandardItem(('   ' if headers else '') + e.label)
            it.setData(e.value, Qt.UserRole)
            it.setToolTip(e.label)
            self._model().appendRow(it)
            key = e.label.strip()
            if key not in self._label_index:
                self._label_index[key] = self.count() - 1
                names.append(key)
        self._names.setStringList(names)
        cur = self.currentIndex()
        if cur < 0 or self.itemData(cur, HEADER_ROLE):
            self.select_first()              # Qt made the first row (a header) current
        self.blockSignals(False)

    def set_entries(self, entries, value=None, headers=True):
        """Replace the list; select `value` (else the first place)."""
        self.blockSignals(True)
        self.clear()
        self.add_entries(entries, headers)
        self.blockSignals(False)
        if value is not None and self.set_value(value):
            return
        self.select_first()

    def select_first(self):
        for i in range(self.count()):
            if not self.itemData(i, HEADER_ROLE):
                self.setCurrentIndex(i)
                return

    def setCurrentIndex(self, i):                         # noqa: N802 (Qt API)
        """A group header is never the current item: the next place is."""
        n = self.count()
        while 0 <= i < n and self.itemData(i, HEADER_ROLE):
            i += 1
        if i >= n:
            i = -1 if n == 0 else self.currentIndex()
        super().setCurrentIndex(i)

    # ---- values
    def value(self):
        return self.currentData()

    def set_value(self, value):
        i = self.findData(value)
        if i >= 0:
            self.setCurrentIndex(i)
            return True
        return False

    def current_label(self):
        return self.itemText(self.currentIndex()).strip() if self.currentIndex() >= 0 else ''

    # ---- typing
    def _picked(self, text):
        i = self._label_index.get(text.strip())
        if i is not None:
            self.setCurrentIndex(i)
            self.activated.emit(i)        # a typed pick is a user choice, like a click
        self._restore_text()

    def _restore_text(self):
        """Typed text that names no place -> back to the current place's name."""
        le = self.lineEdit()
        cur = self.currentIndex()
        txt = le.text().strip()
        if txt and txt in self._label_index and self._label_index[txt] != cur:
            self.setCurrentIndex(self._label_index[txt])
            cur = self.currentIndex()
            self.activated.emit(cur)
        if cur >= 0 and le.text() != self.itemText(cur):
            le.setText(self.itemText(cur))



def ask_place(parent, title, prompt, entries, current=None, extra=None):
    """A place chosen in a dialog with a search box (grouped list); returns the
    entry's value, or None when cancelled. `extra` = [(label, value)] shown first."""
    dlg = QDialog(parent)
    dlg.setWindowTitle(title)
    lay = QVBoxLayout(dlg)
    if prompt:
        lab = QLabel(prompt)
        lab.setWordWrap(True)
        lay.addWidget(lab)
    search = QLineEdit()
    search.setPlaceholderText('Search by name or area…')
    search.setClearButtonEnabled(True)
    lay.addWidget(search)
    tree = QTreeWidget()
    tree.setHeaderHidden(True)
    tree.setRootIsDecorated(True)
    lay.addWidget(tree, 1)
    groups = {}
    sel = None
    for lab_, v in (extra or []):
        it = QTreeWidgetItem([lab_])
        it.setData(0, Qt.UserRole, ('v', v))
        it.setData(0, Qt.UserRole + 1, lab_.casefold())
        tree.addTopLevelItem(it)
        if v == current:
            sel = it
    for e in entries:
        g = groups.get(e.group)
        if g is None:
            g = QTreeWidgetItem([e.group])
            f = g.font(0)
            f.setBold(True)
            g.setFont(0, f)
            g.setFlags(Qt.ItemIsEnabled)
            tree.addTopLevelItem(g)
            g.setExpanded(True)
            groups[e.group] = g
        it = QTreeWidgetItem([e.label])
        it.setData(0, Qt.UserRole, ('v', e.value))
        it.setData(0, Qt.UserRole + 1, e.search or e.label.casefold())
        g.addChild(it)
        if e.value == current:
            sel = it
    bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
    lay.addWidget(bb)
    bb.accepted.connect(dlg.accept)
    bb.rejected.connect(dlg.reject)
    tree.itemDoubleClicked.connect(lambda it, _c: it.data(0, Qt.UserRole) and dlg.accept())

    def refilter(text):
        t = text.strip().casefold()
        first = None
        for i in range(tree.topLevelItemCount()):
            top = tree.topLevelItem(i)
            if top.childCount() == 0:
                hit = not t or t in (top.data(0, Qt.UserRole + 1) or '')
                top.setHidden(not hit)
                if hit and first is None:
                    first = top
                continue
            any_ = False
            for k in range(top.childCount()):
                ch = top.child(k)
                hit = not t or t in (ch.data(0, Qt.UserRole + 1) or '') \
                    or t in top.text(0).casefold()
                ch.setHidden(not hit)
                if hit:
                    any_ = True
                    if first is None:
                        first = ch
            top.setHidden(not any_)
        cur = tree.currentItem()
        if first is not None and (cur is None or cur.isHidden() or not cur.data(0, Qt.UserRole)):
            tree.setCurrentItem(first)
    search.textChanged.connect(refilter)
    if sel is not None:
        tree.setCurrentItem(sel)
        tree.scrollToItem(sel)
    dlg.resize(460, 560)
    search.setFocus()
    if dlg.exec() != QDialog.Accepted:
        return None
    it = tree.currentItem()
    d = it.data(0, Qt.UserRole) if it is not None else None
    return d[1] if d else None
