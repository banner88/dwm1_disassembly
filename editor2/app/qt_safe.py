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


# ---------------------------------------------------------------------------
# S171 — a widget taken out of a page never becomes a window of its own
# ---------------------------------------------------------------------------
# User (S171, with a screenshot): "when I change tabs a random empty window pops up that
# never loads, and I have to close it" — over the Arena tab. Measured S171 (offscreen,
# the user's project): ClassArenaBox.show_class twice in one event-loop turn (a quick
# change of class, or the refresh after an edit) left the first "opens when" FlagTerms
# as a TOP-LEVEL WINDOW. Why: QLayout.addWidget into a shown page queues a
# `_q_showIfNotHidden` call on the new child; `setParent(None)` hides the widget but
# CLEARS its "explicitly hidden" mark, so when the queued call runs, the now
# parentless widget is shown — as a window. `hide()` FIRST keeps the mark (Qt then
# skips the show), and deleteLater removes the widget for good.

def discard(w):
    """Take widget `w` out of its page for good: hidden first (so a show Qt has
    already queued can never turn it into a window), unparented, deleted later."""
    if w is None:
        return
    try:
        w.hide()
        w.setParent(None)
        w.deleteLater()
    except RuntimeError:                 # already gone
        pass


def _hide_quietly(w):
    try:
        w.hide()
        w.setAttribute(Qt.WA_DontShowOnScreen, False)
    except RuntimeError:
        pass


class StrayWindowGuard:
    """The app's safety net (installed by main(), not by the tests): a parentless
    plain widget that is about to be shown as a window is hidden at once and
    reported in the Build log — so a missed `discard` can never again leave an empty
    window on the screen, and the log names the widget's class for the next fix."""

    def __init__(self, app, report=None):
        from PySide6.QtCore import QEvent, QObject
        from PySide6.QtWidgets import QDialog, QMainWindow, QMenu, QWidget
        guard = self
        self.report = report
        self.stopped = []

        class _F(QObject):
            def eventFilter(self, obj, ev):              # noqa: N802 (Qt API)
                if ev.type() == QEvent.Show and isinstance(obj, QWidget) \
                        and obj.parent() is None and obj.windowType() == Qt.Window \
                        and not isinstance(obj, (QMainWindow, QDialog, QMenu)) \
                        and not obj.property('dwm_window'):
                    name = type(obj).__name__
                    guard.stopped.append(name)
                    # Qt maps the native window right AFTER this event: never on screen,
                    # then hidden (not deleted — Python code may still hold it)
                    obj.setAttribute(Qt.WA_DontShowOnScreen, True)
                    from PySide6.QtCore import QTimer
                    QTimer.singleShot(0, lambda o=obj: _hide_quietly(o))
                    if guard.report is not None:
                        try:
                            guard.report(f'Stopped a stray window ({name}) — an editor bug; '
                                         'please mention it to Claude.')
                        except RuntimeError:
                            pass
                    return True
                return False
        self._filter = _F(app)
        app.installEventFilter(self._filter)
