"""side_rail.py — one page at a time behind sideways tabs (S132).

User S132: "UI was built from scratch and especially right panel is annoying
as fuck to scroll through" → "sideways tabs going up/down". The Rooms tab's
right side used to be five foldable sections in a vertical splitter, each with
its own scroll bar. A SideRail shows ONE page at the full height, chosen by a
column of vertical tab buttons on the panel's outer edge (text read top to
bottom). The buttons are painted here, not QTabWidget's East tabs, so they
look the same in every Qt style (the macOS style draws East tabs unrotated).

    rail = SideRail('rooms')                     # remembers the last page
    h = rail.add_page('tiles', 'Tiles', widget, tip='…', scroll=False)
    rail.show_page('tiles'); rail.set_page_visible('gates', False)
    h.set_expanded(True)  # == show this page (the old Section API, so callers
                          #    that "expanded a section" keep working)
"""

from PySide6.QtCore import QRect, QSettings, QSize, Qt, Signal
from PySide6.QtGui import QColor, QFont, QPainter
from PySide6.QtWidgets import (QAbstractButton, QButtonGroup, QHBoxLayout,
                               QScrollArea, QSizePolicy, QStackedWidget,
                               QVBoxLayout, QWidget)


class RailButton(QAbstractButton):
    """A checkable vertical tab: text rotated 90° (read top to bottom)."""

    def __init__(self, text, parent=None):
        super().__init__(parent)
        self.setText(text)
        self.setCheckable(True)
        self.setCursor(Qt.PointingHandCursor)
        self.setSizePolicy(QSizePolicy.Fixed, QSizePolicy.Fixed)
        self.setAttribute(Qt.WA_Hover, True)
        self.badge = ''
        f = QFont(self.font())
        f.setBold(True)
        self._bold = f

    def set_badge(self, text):
        """A short note drawn after the title (e.g. what is selected)."""
        self.badge = text or ''
        self.updateGeometry()
        self.update()

    def _label(self):
        return self.text() + (f'  · {self.badge}' if self.badge else '')

    def sizeHint(self):
        from PySide6.QtGui import QFontMetrics
        fm = QFontMetrics(self._bold)
        return QSize(fm.height() + 14, fm.horizontalAdvance(self._label()) + 26)

    def minimumSizeHint(self):
        return self.sizeHint()

    def paintEvent(self, _ev):
        p = QPainter(self)
        p.setRenderHint(QPainter.Antialiasing)
        r = self.rect().adjusted(1, 1, -1, -1)
        if self.isChecked():
            bg, fg = QColor(70, 110, 170), QColor(255, 255, 255)
        elif self.underMouse():
            bg, fg = QColor(70, 70, 80), QColor(235, 235, 235)
        else:
            bg, fg = QColor(48, 48, 54), QColor(190, 190, 190)
        if not self.isEnabled():
            fg = QColor(110, 110, 110)
        p.setPen(Qt.NoPen)
        p.setBrush(bg)
        p.drawRoundedRect(r, 5, 5)
        if self.isChecked():                   # the edge that joins the page
            p.fillRect(QRect(r.left(), r.top() + 3, 3, r.height() - 6), QColor(255, 210, 60))
        p.translate(self.width(), 0)
        p.rotate(90)
        p.setPen(fg)
        p.setFont(self._bold if self.isChecked() else self.font())
        p.drawText(QRect(0, 0, self.height(), self.width()), Qt.AlignCenter, self._label())


class PageHandle:
    """The old collapsible-Section calls (set_expanded / is_expanded /
    setVisible / isHidden) mapped onto a rail page."""

    def __init__(self, rail, key):
        self.rail, self.key = rail, key

    def set_expanded(self, on):
        if on:
            self.rail.show_page(self.key)

    def is_expanded(self):
        return self.rail.current_key() == self.key

    def setVisible(self, on):
        self.rail.set_page_visible(self.key, on)

    def isHidden(self):
        return not self.rail.page_visible(self.key)

    def setToolTip(self, tip):
        self.rail.buttons[self.key].setToolTip(tip)

    @property
    def button(self):
        return self.rail.buttons[self.key]


class SideRail(QWidget):
    pageChanged = Signal(str)

    def __init__(self, settings_key=None, parent=None, side='right'):
        super().__init__(parent)
        self.settings_key = settings_key
        self.stack = QStackedWidget()
        self.buttons = {}
        self.pages = {}
        self.order = []
        self._visible = {}
        self.group = QButtonGroup(self)
        self.group.setExclusive(True)
        col = QWidget()
        col.setObjectName('railColumn')
        self.col = QVBoxLayout(col)
        self.col.setContentsMargins(2, 4, 2, 4)
        self.col.setSpacing(4)
        self.col.addStretch(1)
        h = QHBoxLayout(self)
        h.setContentsMargins(0, 0, 0, 0)
        h.setSpacing(2)
        if side == 'right':
            h.addWidget(self.stack, 1)
            h.addWidget(col, 0)
        else:
            h.addWidget(col, 0)
            h.addWidget(self.stack, 1)

    # ------------------------------------------------------------ pages
    def add_page(self, key, title, widget, tip='', scroll=True):
        if scroll:
            sc = QScrollArea()
            sc.setWidgetResizable(True)
            sc.setFrameShape(QScrollArea.NoFrame)
            sc.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
            sc.setWidget(widget)
            page = sc
        else:
            page = widget
        self.stack.addWidget(page)
        b = RailButton(title)
        if tip:
            b.setToolTip(tip)
        b.clicked.connect(lambda _c=False, k=key: self.show_page(k, user=True))
        self.group.addButton(b)
        self.col.insertWidget(self.col.count() - 1, b, 0, Qt.AlignHCenter)
        self.buttons[key] = b
        self.pages[key] = page
        self.order.append(key)
        self._visible[key] = True
        if len(self.order) == 1:
            b.setChecked(True)
            self.stack.setCurrentWidget(page)
        return PageHandle(self, key)

    def page_widget(self, key):
        """The page's own widget (inside its scroll area when scrolled)."""
        p = self.pages[key]
        return p.widget() if isinstance(p, QScrollArea) else p

    def scroll_area(self, key):
        p = self.pages[key]
        return p if isinstance(p, QScrollArea) else None

    def current_key(self):
        cur = self.stack.currentWidget()
        for k, p in self.pages.items():
            if p is cur:
                return k
        return None

    def show_page(self, key, user=False):
        if key not in self.pages or not self._visible.get(key, True):
            return
        changed = self.current_key() != key
        self.buttons[key].setChecked(True)
        self.stack.setCurrentWidget(self.pages[key])
        if user and self.settings_key:
            QSettings('dwm1_disassembly', 'DWM1Editor').setValue(
                f'ui/rail/{self.settings_key}', key)
        if changed:
            self.pageChanged.emit(key)

    def restore(self, default=None):
        """Open the page used last time (or `default`)."""
        key = None
        if self.settings_key:
            key = QSettings('dwm1_disassembly', 'DWM1Editor').value(
                f'ui/rail/{self.settings_key}')
        key = key if key in self.pages and self._visible.get(key) else default
        if key:
            self.show_page(key)

    def set_page_visible(self, key, on):
        on = bool(on)
        if self._visible.get(key) == on:
            return
        self._visible[key] = on
        self.buttons[key].setVisible(on)
        if not on and self.current_key() == key:
            for k in self.order:
                if self._visible.get(k):
                    self.show_page(k)
                    break

    def page_visible(self, key):
        return self._visible.get(key, False)

    def set_badge(self, key, text):
        self.buttons[key].set_badge(text)

    def ensure_visible(self, key, widget):
        """Scroll a page so `widget` is in view (after showing the page)."""
        from PySide6.QtCore import QTimer
        sc = self.scroll_area(key)
        if sc is not None:
            QTimer.singleShot(0, lambda: sc.ensureWidgetVisible(widget, 0, 0))
