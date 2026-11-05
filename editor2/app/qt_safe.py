"""qt_safe.py — PySide6 calls that never leave a stale Python wrapper behind (S167).

The S166 note "a test_app traceback (talk_editor BoxEditor's Insert menu:
`QStandardItem.triggered`)" — measured S167 (KEY_LESSONS "S167 — a stale PySide
wrapper"): Shiboken keeps ONE Python wrapper per C++ address. A wrapper of a
QStandardItem that QT made (`combo.model().item(i)`: the combo's own items) does
not learn when Qt deletes that item (a combo's `clear()`); while the wrapper is
still alive, the next C++ object Qt puts at the same address is handed to Python
AS that old wrapper — `QMenu.addAction('…')` returned a `QStandardItem`, and
`.triggered.connect` raised inside a slot (the menu half-built; Qt printed the
traceback, the test went on). Reproduced S167: keep `combo.model().item(5)`,
`combo.clear()`, then `QMenu.addAction` ×20 → a `QStandardItem` within ~400 calls.

Rule: never take a Python wrapper of an item Qt owns. Combo rows are changed by
INDEX here (the item's flags live in role `Qt.UserRole - 1` of a
QStandardItemModel); actions are made in Python (`QAction(text, menu)`) so the
returned object is always the new one.
"""

from PySide6.QtCore import Qt
from PySide6.QtGui import QAction

FLAGS_ROLE = Qt.UserRole - 1          # QStandardItem keeps its flags in this role


def combo_row_enabled(cb, row, on, tip=None):
    """Enable / disable row `row` of combo `cb` (and set its tool tip) without a
    QStandardItem wrapper (QStandardItem.setEnabled == toggling ItemIsEnabled)."""
    m = cb.model()
    flags = m.flags(m.index(row, 0))
    flags = (flags | Qt.ItemIsEnabled) if on else (flags & ~Qt.ItemIsEnabled)
    cb.setItemData(row, flags, FLAGS_ROLE)
    if tip is not None:
        cb.setItemData(row, tip, Qt.ToolTipRole)


def combo_row_tip(cb, row, tip):
    cb.setItemData(row, tip, Qt.ToolTipRole)


def menu_action(menu, text, slot=None, tip=None):
    """A QAction made in Python, added to `menu` (never an address-reused wrapper)."""
    a = QAction(text, menu)
    if tip:
        a.setToolTip(tip)
    if slot is not None:
        a.triggered.connect(slot)
    menu.addAction(a)
    return a
