"""page_tabs.py — the main window's tab strip (S169).

User (S169): "clicking on a different tab resizes the window and I have to make it
fullscreen again every time". Measured S169 (the user's project, every tab shown in
turn): a QTabWidget's minimum size is the LARGEST minimum of ALL its pages plus the tab
row, and a QMainWindow is never smaller than its central widget's minimum —

- the tab row: 23 tabs. The macOS style gives a tab bar NO scroll arrows
  (SH_TabBar_PreferNoArrows), so the row alone asked for 1,669 px (window 1,696 px);
- the widest pages: World 1,526 px (1,666 px once shown), Music 1,477, Cutscenes 1,435;
  the tallest made the window at least 911 px high;
- five pages (World, Capacity, Skills, Monsters, Breeding) change their minimum the
  first time they are shown, so a tab click re-applied a minimum larger than a laptop
  screen (1,440 / 1,512 px) and the window left its full-screen / zoomed size.

The fix: the tab row scrolls (arrows), and every page sits in its own QScrollArea —
a scroll area's minimum is a few pixels, so no page can push the window any more; a page
larger than the window scrolls instead. The wrapper is invisible to the rest of the
editor: `widget(i)`, `currentWidget()`, `indexOf(page)` and `setCurrentWidget(page)`
answer with the PAGE (every caller compares pages: `tabs.currentWidget() is
mw.help_tab`, `tabs.indexOf(w.balance_tab)`, `tabs.setCurrentWidget(self.gates_tab)` …).

S171 (user: "when I open editor its a bit slow at first"): measured on the user's project, the
window appeared only after all 23 tabs were built (6-8 s: Breeding 3.3 s, Skills 0.8, Text 0.7,
Arena 0.6, Monsters 0.6 …). A tab may now be added as a FACTORY (`addLazyTab`): its page is
made the first time it is shown or asked for (`widget(i)`, `currentWidget()`), so opening a
project builds the Rooms tab only. `built(i)` answers without building (the "?" installer).
"""

from PySide6.QtCore import QEvent, QTimer, Qt
from PySide6.QtWidgets import QFrame, QScrollArea, QTabWidget, QWidget

WRAP_NAME = 'pageTabScroll'


class PageScroll(QScrollArea):
    """The scroll area one page sits in. The page fills it and scrolls only when the
    window is smaller than the page's own MINIMUM size.

    Not `widgetResizable`: a resizable scroll area asks a page with word-wrapped labels
    for its height-for-width — its PREFERRED height — and showed scroll bars on pages
    that fit (measured S169: the World tab scrolled at 1440 x 860). Here the page is
    sized by hand: the viewport, but never below the page's minimum — what the window
    gave the page before S169, and how a layout squeezes it."""

    def __init__(self, page=None, factory=None):
        super().__init__()
        self.setObjectName(WRAP_NAME)
        self.setWidgetResizable(False)
        self.setFrameShape(QFrame.NoFrame)
        self._pending = False
        self._factory = factory          # S171: made on first show
        self.page = None
        if page is not None:
            self._set_page(page)
        else:
            self.setWidget(QWidget())    # an empty stand-in until the page is made

    def _set_page(self, page):
        self.page = page
        self.setWidget(page)
        page.installEventFilter(self)

    def ensure(self):
        """The page, made now if it is still a factory (S171)."""
        if self.page is None and self._factory is not None:
            from PySide6.QtGui import QGuiApplication
            f, self._factory = self._factory, None
            QGuiApplication.setOverrideCursor(Qt.WaitCursor)
            try:
                self._set_page(f())
            finally:
                QGuiApplication.restoreOverrideCursor()
            self.fit()
        return self.page

    def fit(self):
        self._pending = False
        page = self.page
        if page is None:
            return
        mn = page.minimumSizeHint().expandedTo(page.minimumSize())
        vp = self.maximumViewportSize()          # the viewport without scroll bars
        size = vp.expandedTo(mn)
        if mn.width() > vp.width():              # a horizontal bar takes some height
            size.setHeight(max(mn.height(), vp.height() - self.horizontalScrollBar().sizeHint().height()))
        if mn.height() > vp.height():            # a vertical bar takes some width
            size.setWidth(max(mn.width(), vp.width() - self.verticalScrollBar().sizeHint().width()))
        if page.size() != size:
            page.resize(size)

    def resizeEvent(self, ev):                           # noqa: N802 (Qt API)
        super().resizeEvent(ev)
        self.fit()

    def showEvent(self, ev):                             # noqa: N802 (Qt API)
        super().showEvent(ev)
        self.fit()

    def eventFilter(self, obj, ev):                      # noqa: N802 (Qt API)
        if obj is self.page and ev.type() == QEvent.LayoutRequest and not self._pending:
            self._pending = True                 # the page's minimum may have changed
            QTimer.singleShot(0, self.fit)
        return False


def _page_of(w, make=True):
    """The page inside a wrapper (`w` itself when it is not one); a page still a
    factory is made now (`make`) or answered as None."""
    if isinstance(w, PageScroll):
        return w.ensure() if make else w.page
    return w


class PageTabs(QTabWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        bar = self.tabBar()
        bar.setUsesScrollButtons(True)       # macOS: off by default — the row then sets the width
        bar.setElideMode(Qt.ElideNone)
        bar.setExpanding(False)
        # S171: the page of the tab shown is made BEFORE anyone else hears of the change
        # (connected first: MainWindow's "?" installer then sees the page)
        self.currentChanged.connect(self._make_current)

    def clear(self):
        """Every tab out (a project is opened again). A page never made stays unmade —
        removing tabs moves the current index across them (measured S171: the old
        session's pages were built one by one while the tabs went)."""
        old = [super(PageTabs, self).widget(i) for i in range(self.count())]
        self._clearing = True
        try:
            super().clear()
        finally:
            self._clearing = False
        for w in old:
            if isinstance(w, PageScroll) and w.page is None:
                w._factory = None
                w.deleteLater()

    def _make_current(self, i):
        if getattr(self, '_clearing', False):
            return
        w = super().widget(i)
        if isinstance(w, PageScroll):
            w.ensure()

    # ---- adding: wrap the page --------------------------------------------------
    def addTab(self, page, *args):                       # noqa: N802 (Qt API)
        return super().addTab(PageScroll(page), *args)

    def insertTab(self, index, page, *args):             # noqa: N802 (Qt API)
        return super().insertTab(index, PageScroll(page), *args)

    def addLazyTab(self, factory, *args):                # noqa: N802
        """S171: a tab whose page `factory()` makes the first time it is needed."""
        i = super().addTab(PageScroll(factory=factory), *args)
        if i == self.currentIndex():
            self._make_current(i)
        return i

    def built(self, index):
        """The page at `index` if it has been made, else None (never makes it)."""
        return _page_of(super().widget(index), make=False)

    # ---- asking: answer with the page ---------------------------------------------
    def widget(self, index):
        return _page_of(super().widget(index))

    def currentWidget(self):                             # noqa: N802 (Qt API)
        return _page_of(super().currentWidget())

    def wrapper(self, index):
        """The PageScroll at `index` (tests / scrolling a page into view)."""
        return super().widget(index)

    def indexOf(self, page):                             # noqa: N802 (Qt API)
        if page is None:
            return -1
        for i in range(self.count()):
            w = super().widget(i)
            if w is page or _page_of(w, make=False) is page:
                return i
        return -1

    def setCurrentWidget(self, page):                    # noqa: N802 (Qt API)
        i = self.indexOf(page)
        if i >= 0:
            self.setCurrentIndex(i)
