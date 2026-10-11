"""room_tree.py — the Rooms tab's room lists as folders (S143, ROADMAP ARC CAP4b).

Your rooms are listed in their AREAS (one level of named folders, user S143: "One
level"; `custom.rooms[].area`, Document.areas()), the game's rooms in their groups
(place_names.VANILLA_GROUPS) — names only, never a map id (View > Show technical
ids adds them). A search box above filters by name or area. Your rooms can be
dragged onto another area folder; the right-click menu moves a room or edits the
areas.

`PlaceTree` keeps the QListWidget calls the Rooms tab and the tests use on a flat
list of the PLACE rows (folders skipped): count(), item(i) (with .text() /
.data(role)), setCurrentRow(i), currentItem(), currentRow().
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtWidgets import QAbstractItemView, QTreeWidget, QTreeWidgetItem

FOLDER_ROLE = Qt.UserRole + 7


class PlaceItem(QTreeWidgetItem):
    """A place row; .text() / .data(role) default to column 0 (QListWidgetItem-like)."""

    def text(self, column=0):
        return super().text(column)

    def data(self, *args):
        if len(args) == 1:
            return super().data(0, args[0])
        return super().data(*args)

    def setData(self, *args):                         # noqa: N802 (Qt API)
        if len(args) == 2:
            return super().setData(0, args[0], args[1])
        return super().setData(*args)


class PlaceTree(QTreeWidget):
    """Folders of place rows + a flat QListWidget-like view of the rows."""
    roomDropped = Signal(str, str)        # room id, area ('' = no area)

    def __init__(self, parent=None, droppable=False):
        super().__init__(parent)
        self.setHeaderHidden(True)
        self.setRootIsDecorated(True)
        self.setIndentation(12)
        self.setUniformRowHeights(True)
        self.setExpandsOnDoubleClick(False)
        self._rows = []
        self._folders = {}
        self._collapsed = set()
        self.itemCollapsed.connect(lambda it: self._collapsed.add(it.text(0).split('   (')[0]))
        self.itemExpanded.connect(lambda it: self._collapsed.discard(it.text(0).split('   (')[0]))
        if droppable:
            self.setDragEnabled(True)
            self.setAcceptDrops(True)
            self.setDropIndicatorShown(True)
            self.setDragDropMode(QAbstractItemView.InternalMove)
            self.setDefaultDropAction(Qt.MoveAction)

    # ---- filling
    def clear(self):
        super().clear()
        self._rows = []
        self._folders = {}

    def folder(self, key, title):
        f = self._folders.get(key)
        if f is None:
            f = PlaceItem([title])
            f.setData(0, FOLDER_ROLE, key)
            fnt = f.font(0)
            fnt.setBold(True)
            f.setFont(0, fnt)
            f.setFlags(Qt.ItemIsEnabled | Qt.ItemIsDropEnabled)
            self.addTopLevelItem(f)
            f.setExpanded(key not in self._collapsed)
            self._folders[key] = f
        return f

    def add_row(self, folder_key, folder_title, text, data, tip=None):
        f = self.folder(folder_key, folder_title)
        it = PlaceItem([text])
        it.setData(0, Qt.UserRole, data)
        it.setFlags(Qt.ItemIsEnabled | Qt.ItemIsSelectable | Qt.ItemIsDragEnabled)
        if tip:
            it.setToolTip(0, tip)
        f.addChild(it)
        self._rows.append(it)
        return it

    def finish(self):
        """Folder titles get their room counts."""
        for key, f in self._folders.items():
            f.setText(0, f'{key}   ({f.childCount()})')

    # ---- QListWidget-like API over the place rows
    def count(self):
        return len(self._rows)

    def item(self, i):
        return self._rows[i] if 0 <= i < len(self._rows) else None

    def currentRow(self):                              # noqa: N802 (Qt API)
        it = self.currentItem()
        try:
            return self._rows.index(it)
        except ValueError:
            return -1

    def setCurrentRow(self, i):                        # noqa: N802 (Qt API)
        if 0 <= i < len(self._rows):
            it = self._rows[i]
            p = it.parent()
            if p is not None and not p.isExpanded():
                p.setExpanded(True)
            self.setCurrentItem(it)
            self.scrollToItem(it)
        else:
            self.setCurrentItem(None)
            self.clearSelection()

    def select_data(self, data):
        for i, it in enumerate(self._rows):
            if it.data(Qt.UserRole) == data:
                self.setCurrentRow(i)
                return True
        return False

    # ---- search
    def apply_filter(self, text):
        t = (text or '').strip().casefold()
        for f in self._folders.values():
            fhit = bool(t) and t in f.text(0).casefold()
            n = 0
            for k in range(f.childCount()):
                ch = f.child(k)
                hit = not t or fhit or t in ch.text(0).casefold()
                ch.setHidden(not hit)
                n += hit
            f.setHidden(n == 0 and bool(t))
            if t and n:
                f.setExpanded(True)

    # ---- drag a room onto an area folder
    def dropEvent(self, ev):                           # noqa: N802 (Qt API)
        it = self.currentItem()
        target = self.itemAt(ev.position().toPoint())
        ev.ignore()                                    # the model is rebuilt from the doc
        if it is None or target is None or it.data(FOLDER_ROLE) is not None:
            return
        f = target if target.data(0, FOLDER_ROLE) is not None else target.parent()
        if f is None:
            return
        key = f.data(0, FOLDER_ROLE)
        rid = it.data(Qt.UserRole)
        if isinstance(rid, str):
            self.roomDropped.emit(rid, '' if key == self.no_area_key else key)

    no_area_key = 'No area'
