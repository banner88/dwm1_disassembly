"""shops_tab.py — the Shops tab (ROADMAP P3.13c, S117; model: editor2/core/
shops_doc.py, compiler: editor2/core/shops.py, PROJECT_COMPILER §2.32).

Left: every shop — the game's five (Bazaar item shop, Starry Night shop,
Bookstore, Rare item shop, the gate-floor shop) and the project's own (New
shop… / Rename… / Delete). Right, for the selected shop: its list (up to 20
items, shown four per page in the game) with Add / Remove / ▲ ▼, where it
sells (the game's room rule, or the NPCs you made shopkeepers — Rooms tab →
NPC → Shopkeeper…). Below: every item's BUY price (all shops) and what the
shops pay when the player sells (3/4, staffs 1/10, the gate-floor shop the
full price — the game's rule).

Every edit is one undo step (SnapshotCommand).
"""

from PySide6.QtCore import Qt
from PySide6.QtGui import QColor
from PySide6.QtWidgets import (QAbstractItemView, QComboBox, QGroupBox, QHBoxLayout,
                               QHeaderView, QInputDialog, QLabel, QListWidget,
                               QListWidgetItem, QMessageBox, QPushButton, QSplitter,
                               QTableWidget, QTableWidgetItem, QVBoxLayout, QWidget)

from editor2.app.rooms import commands as C
from editor2.core import shops as SH

HELP = ('A shop sells up to 20 items (four per page in the game; left / right turns the '
        'page). Prices are per ITEM — the same in every shop. The game\'s five shops sell '
        'where the game puts them; your own shops sell wherever you make an NPC a '
        'shopkeeper (Rooms tab → select the NPC → Shopkeeper…).')
EDITED = QColor(255, 200, 80)


class ShopsTab(QWidget):
    def __init__(self, session):
        super().__init__()
        self.s = session
        self._building = False
        v = QVBoxLayout(self)
        top = QLabel(HELP)
        top.setWordWrap(True)
        v.addWidget(top)
        split = QSplitter(Qt.Vertical)
        v.addWidget(split, 1)
        # ---- shops
        upper = QWidget()
        uh = QHBoxLayout(upper)
        left = QVBoxLayout()
        self.list = QListWidget()
        self.list.currentRowChanged.connect(self._show_shop)
        left.addWidget(self.list, 1)
        brow = QHBoxLayout()
        b = QPushButton('New shop…')
        b.clicked.connect(self._new_shop)
        brow.addWidget(b)
        self.btn_rename = QPushButton('Rename…')
        self.btn_rename.clicked.connect(self._rename)
        brow.addWidget(self.btn_rename)
        self.btn_delete = QPushButton('Delete')
        self.btn_delete.clicked.connect(self._delete)
        brow.addWidget(self.btn_delete)
        left.addLayout(brow)
        lw = QWidget()
        lw.setLayout(left)
        lw.setMaximumWidth(320)
        uh.addWidget(lw)
        g = QGroupBox('Items for sale')
        gv = QVBoxLayout(g)
        self.head = QLabel('')
        self.head.setWordWrap(True)
        gv.addWidget(self.head)
        self.items = QListWidget()
        self.items.setSelectionMode(QAbstractItemView.SingleSelection)
        gv.addWidget(self.items, 1)
        irow = QHBoxLayout()
        self.pick = QComboBox()
        self.pick.setMinimumContentsLength(16)
        irow.addWidget(self.pick, 1)
        for text, fn in (('Add', self._add_item), ('Remove', self._remove_item),
                         ('▲', lambda: self._move(-1)), ('▼', lambda: self._move(1))):
            bb = QPushButton(text)
            bb.clicked.connect(fn)
            irow.addWidget(bb)
        self.btn_orig = QPushButton('Original list')
        self.btn_orig.clicked.connect(self._original)
        irow.addWidget(self.btn_orig)
        gv.addLayout(irow)
        # S129 (ROADMAP P3.14d): other item lists sold while flags / story checks hold
        srow = QHBoxLayout()
        self.btn_sets = QPushButton('Item sets by flag…')
        self.btn_sets.setToolTip('Sell another list while flags / story checks hold (the first '
                                 'set whose conditions all hold; none = the list above)')
        self.btn_sets.clicked.connect(self._item_sets)
        srow.addWidget(self.btn_sets)
        self.sets_lbl = QLabel('')
        self.sets_lbl.setWordWrap(True)
        srow.addWidget(self.sets_lbl, 1)
        gv.addLayout(srow)
        self.where = QLabel('')
        self.where.setWordWrap(True)
        self.where.setStyleSheet('color: #9fd0ff;')
        gv.addWidget(self.where)
        uh.addWidget(g, 1)
        split.addWidget(upper)
        # ---- prices
        pg = QGroupBox('Item prices (every shop)')
        pv = QVBoxLayout(pg)
        self.prices = QTableWidget(0, 5)
        self.prices.setHorizontalHeaderLabels(['Item', 'Buy price', 'Shops pay', 'Original',
                                               'Sold in'])
        self.prices.horizontalHeader().setSectionResizeMode(4, QHeaderView.Stretch)
        self.prices.itemChanged.connect(self._price_changed)
        pv.addWidget(self.prices)
        pnote = QLabel('Shops pay 3/4 of the price for most items, 1/10 for the staffs, and the '
                       'shop inside gates pays the full price (the game\'s rule).')
        pnote.setWordWrap(True)
        pv.addWidget(pnote)
        split.addWidget(pg)
        self.s.undo.indexChanged.connect(self._undo_changed)   # bound: dies with the tab
        self.refresh()

    # ------------------------------------------------------------ fill
    def _undo_changed(self, _i):
        # S132: refresh when shown (not on every edit in another tab)
        from shiboken6 import isValid
        if not isValid(self):
            return
        if self.isVisibleTo(self.window()):   # the current tab
            self.refresh()
        else:
            self._stale = True

    def showEvent(self, ev):
        if getattr(self, '_stale', False):
            self._stale = False
            self.refresh()
        super().showEvent(ev)

    def refresh(self):
        keep = self.current_key()
        self._building = True
        try:
            self.shops = self.s.doc.shop_list()
            rows = self.s.doc.item_rows()
        except Exception as ex:
            self.head.setText(f'⚠ {ex}')
            self._building = False
            return
        self.names = self.s.doc.shop_item_names()
        self.list.clear()
        for sh in self.shops:
            it = QListWidgetItem(f"{sh['name']}  ({len(sh['items'])})"
                                 + ('' if sh['vanilla'] else '  — yours'))
            if sh['edited'] or not sh['vanilla']:
                it.setForeground(EDITED)
            self.list.addItem(it)
        self.pick.clear()
        for i in range(1, SH.ITEM_COUNT):
            self.pick.addItem(f"{self.names.get(i, i)}", i)
        self.prices.setRowCount(len(rows))
        for r, row in enumerate(rows):
            vals = [row['name'], str(row['price']), str(row['sell']), str(row['vanilla_price']),
                    ', '.join(row['shops'])]
            for c, val in enumerate(vals):
                it = QTableWidgetItem(val)
                if c != 1:
                    it.setFlags(it.flags() & ~Qt.ItemIsEditable)
                it.setData(Qt.UserRole, row['id'])
                if c == 1 and row['price'] != row['vanilla_price']:
                    it.setForeground(EDITED)
                self.prices.setItem(r, c, it)
        self._building = False
        idx = next((i for i, sh in enumerate(self.shops) if sh['key'] == keep), 0)
        self.list.setCurrentRow(idx)
        self._show_shop(idx)

    def current_key(self):
        i = self.list.currentRow() if hasattr(self, 'list') else -1
        shops = getattr(self, 'shops', [])
        return shops[i]['key'] if 0 <= i < len(shops) else None

    def current(self):
        i = self.list.currentRow()
        return self.shops[i] if 0 <= i < len(self.shops) else None

    def _show_shop(self, i):
        if self._building or not 0 <= i < len(self.shops):
            return
        sh = self.shops[i]
        prices = {r['id']: r['price'] for r in self.s.doc.item_rows()}
        self.items.clear()
        for k, it in enumerate(sh['items']):
            self.items.addItem(f"{k + 1:2d}. {self.names.get(it, it)}   {prices.get(it, 0)}G"
                               + (f"   (page {k // 4 + 1})" if len(sh['items']) > 4 else ''))
        self.head.setText(f"<b>{sh['name']}</b> — {len(sh['items'])} of {SH.LIST_MAX} items"
                          + (' (edited)' if sh['edited'] else ''))
        if sh['vanilla']:
            where = f"Sells in the game's own place: {sh['rule']}."
            if sh['sellers']:
                where += ' Also sold by: ' + ', '.join(
                    f"{self.s.doc.room_name(r)} ({e.get('x')},{e.get('y')})"
                    for r, k, n, e, sid in sh['sellers'])
        elif sh['sellers']:
            where = 'Sold by: ' + ', '.join(f"{self.s.doc.room_name(r)} screen {k} "
                                            f"({e.get('x')},{e.get('y')})"
                                            for r, k, n, e, sid in sh['sellers'])
        else:
            where = ('⚠ nobody sells this shop yet — Rooms tab: select an NPC, '
                     'Shopkeeper…')
        self.where.setText(where)
        self.btn_rename.setEnabled(not sh['vanilla'])
        self.btn_delete.setEnabled(not sh['vanilla'])
        self.btn_orig.setEnabled(sh['vanilla'] and sh['edited'])
        sets = self.s.doc.shop_sets(sh['key'])
        self.btn_sets.setText(f'Item sets by flag… ({len(sets)})' if sets else
                              'Item sets by flag…')
        self.sets_lbl.setText(' · '.join(f"“{st.get('name')}”: {len(st.get('items') or [])} "
                                         'items' for st in sets) if sets else
                              'none — always the list above')

    def _item_sets(self):
        sh = self.current()
        if sh is None:
            return
        from PySide6.QtWidgets import QDialog
        from editor2.app.story_widgets import ItemSetsDialog
        dlg = ItemSetsDialog(self.s.doc, sh['key'], sh['name'], parent=self)
        if dlg.exec() == QDialog.Accepted:
            sets, key = dlg.result(), sh['key']
            self._push(f"Item sets of {sh['name']}", lambda doc: doc.set_shop_sets(key, sets))

    # ------------------------------------------------------------ edits
    def _push(self, text, fn):
        cmd = C.SnapshotCommand(self.s, text, fn)
        self.s.undo.push(cmd)
        if getattr(cmd, 'error', None) is not None:
            QMessageBox.warning(self, 'Shops', str(cmd.error))
        return cmd

    def _set_items(self, items, text):
        sh = self.current()
        if sh is None:
            return
        key = sh['key']
        self._push(text, lambda doc: doc.set_shop_items(key, items))

    def _add_item(self):
        sh = self.current()
        if sh is None:
            return
        if len(sh['items']) >= SH.LIST_MAX:
            QMessageBox.information(self, 'Shops', f'A shop sells at most {SH.LIST_MAX} items.')
            return
        it = self.pick.currentData()
        row = self.items.currentRow()
        lst = list(sh['items'])
        lst.insert(row + 1 if row >= 0 else len(lst), it)
        self._set_items(lst, f"{sh['name']}: add {self.names.get(it, it)}")

    def _remove_item(self):
        sh = self.current()
        row = self.items.currentRow()
        if sh is None or row < 0:
            return
        if len(sh['items']) == 1:
            QMessageBox.information(self, 'Shops', 'A shop sells at least one item.')
            return
        lst = list(sh['items'])
        gone = lst.pop(row)
        self._set_items(lst, f"{sh['name']}: remove {self.names.get(gone, gone)}")

    def _move(self, d):
        sh = self.current()
        row = self.items.currentRow()
        if sh is None or row < 0 or not 0 <= row + d < len(sh['items']):
            return
        lst = list(sh['items'])
        lst[row], lst[row + d] = lst[row + d], lst[row]
        self._set_items(lst, f"{sh['name']}: reorder")
        self.items.setCurrentRow(row + d)

    def _original(self):
        sh = self.current()
        if sh is None or not sh['vanilla']:
            return
        van = SH.vanilla()['shops'][sh['key']]
        self._set_items(list(van), f"{sh['name']}: original list")

    def _new_shop(self):
        name, ok = QInputDialog.getText(self, 'New shop', 'Shop name:')
        if not ok or not name.strip():
            return
        out = {}

        def op(doc):
            out['id'] = doc.new_shop(name)
        self._push(f'New shop {name}', op)
        if out.get('id'):
            i = next((k for k, sh in enumerate(self.shops) if sh['key'] == out['id']), None)
            if i is not None:
                self.list.setCurrentRow(i)

    def _rename(self):
        sh = self.current()
        if sh is None or sh['vanilla']:
            return
        name, ok = QInputDialog.getText(self, 'Rename shop', 'Shop name:', text=sh['name'])
        if ok and name.strip():
            key = sh['key']
            self._push(f'Rename shop {key}', lambda doc: doc.rename_shop(key, name))

    def _delete(self):
        sh = self.current()
        if sh is None or sh['vanilla']:
            return
        n = len(sh['sellers'])
        if QMessageBox.question(
                self, 'Delete shop',
                f"Delete {sh['name']}?" + (f" Its {n} shopkeeper(s) stop selling (they no "
                                          "longer talk)." if n else '') +
                " (Undo brings it back.)") != QMessageBox.Yes:
            return
        key = sh['key']
        self._push(f"Delete shop {sh['name']}", lambda doc: doc.delete_shop(key))

    def _price_changed(self, it):
        if self._building or it.column() != 1:
            return
        item = it.data(Qt.UserRole)
        try:
            p = int(it.text())
        except ValueError:
            self.refresh()
            return
        self._push(f"Price of {self.names.get(item, item)}: {p}",
                   lambda doc: doc.set_item_price(item, p))
