"""capacity_tab.py — the Capacity tab (S145, ROADMAP ARC CAP4d; EDITOR_DESIGN §5.C).

Every ceiling your project can reach, in words: how much is used, of how much, what
happens at the limit, and — for a limit per room or per screen — which one is the
fullest. The numbers come from `editor2/core/capacity.measure` (the same compiler
counts as the build), measured by the status bar's meter (`app/space_meter.py`) off
the UI thread after each edit; this tab shows its last report.

Double-click a row to open what it counts (the room, or the tab that edits it).
View → Show technical ids adds the technical column and the bank-by-bank list.
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QBrush, QColor, QFont
from PySide6.QtWidgets import (QHBoxLayout, QLabel, QPushButton, QTreeWidget,
                               QTreeWidgetItem, QVBoxLayout, QWidget)

from editor2.core import capacity as CAP
from editor2.core import place_names as PN

LEVEL_BG = {'ok': QColor(60, 154, 80, 60), 'near': QColor(208, 160, 48, 110),
            'full': QColor(208, 64, 64, 120), 'unknown': QColor(128, 128, 128, 50)}
LEVEL_WORD = {'ok': '', 'near': 'nearly full', 'full': 'at the limit', 'unknown': ''}
GROUPS = ('Space', 'Rooms', 'Text and story', 'Gates, battles and monsters', 'Music')
COLS = ('What', 'Used', 'The fullest', 'When it is full', 'Technical')


class CapacityTab(QWidget):
    navigate = Signal(object)       # {'tab': 'rooms', 'room', 'screen'} (main.navigate_to)
    openTab = Signal(str)           # a tab title ('Music', 'Progression && Flags' …)
    measureRequested = Signal()

    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.rep = None
        v = QVBoxLayout(self)
        self.summary = QLabel('Measuring…')
        self.summary.setWordWrap(True)
        self.summary.setTextFormat(Qt.RichText)
        self.summary.setTextInteractionFlags(Qt.TextSelectableByMouse)
        v.addWidget(self.summary)
        self.tree = QTreeWidget()
        self.tree.setColumnCount(len(COLS))
        self.tree.setHeaderLabels(COLS)
        self.tree.setRootIsDecorated(False)
        self.tree.setAlternatingRowColors(False)
        self.tree.setUniformRowHeights(True)
        self.tree.itemDoubleClicked.connect(self._open)
        v.addWidget(self.tree, 1)
        h = QHBoxLayout()
        self.note = QLabel('')
        self.note.setStyleSheet('color: #888')
        h.addWidget(self.note, 1)
        b = QPushButton('Measure now')
        b.clicked.connect(self.measureRequested)
        h.addWidget(b)
        v.addLayout(h)
        session.structureChanged.connect(self._ids_maybe_changed)

    # ------------------------------------------------------------------ report
    def show_report(self, rep):
        self.rep = rep
        self._fill()

    def _ids_maybe_changed(self, *_a):
        # View → Show technical ids emits structureChanged: redraw the last report
        if self.rep is not None and self.isVisible():
            self._fill()

    def showEvent(self, ev):
        super().showEvent(ev)
        if self.rep is not None:
            self._fill()

    def _fill(self):
        rep = self.rep
        self.tree.clear()
        self.tree.setColumnHidden(4, not PN.SHOW_IDS)
        c, r, left = rep.get('content') or {}, rep.get('rooms') or {}, rep.get('left') or {}
        parts = []
        if rep.get('errors'):
            parts.append('<p style="color:#d04040"><b>The project does not build yet</b> — '
                         'the numbers that need a build are unknown until it does:<br>'
                         + '<br>'.join(_esc(e) for e in rep['errors'][:3]) + '</p>')
        if c:
            parts.append(f"<b>ROM space</b>: {CAP.kb(c['used'])} of {CAP.kb(c['cap'])} used "
                         f"({100 * c['used'] / c['cap']:.0f} %) &nbsp;·&nbsp; "
                         f"<b>Rooms</b>: {r.get('count', 0):,} of about {r.get('ceiling', 0):,}")
        if left.get('rooms') is not None:
            what = (f"your average one ({CAP.kb(left['typical'])} each)" if left.get('avg')
                    else f"a typical one ({CAP.kb(left['typical'])})")
            decides = ('the ROM space decides' if left['by'] == 'ROM space' else
                       'the table of every room\'s record, songs and battles decides')
            parts.append(f"About <b>{left['rooms']:,}</b> more rooms like {what} — {decides}.")
        bad = CAP.worst(rep)
        if bad:
            parts.append('<span style="color:#d0a030">⚠ ' + '; '.join(
                f"{_esc(x['what'])}: {_esc(x['shown'])}" for x in bad[:4]) + '</span>')
        self.summary.setText('<br>'.join(parts) or '—')
        bold = QFont()
        bold.setBold(True)
        for g in GROUPS:
            rows = [x for x in rep.get('rows') or [] if x['group'] == g]
            if not rows:
                continue
            head = QTreeWidgetItem(self.tree, [g])
            head.setFont(0, bold)
            head.setFirstColumnSpanned(True)
            head.setFlags(Qt.ItemIsEnabled)
            for x in rows:
                lvl, word = x['level'], LEVEL_WORD[x['level']]
                if x['key'] in CAP.EACH and lvl == 'full':
                    # one room / screen using all of its own allowance is a choice
                    lvl, word = 'near', 'all used'
                it = QTreeWidgetItem(self.tree, [
                    '   ' + x['what'], x['shown'] + (f'  ({word})' if word else ''),
                    x.get('where') or '', x.get('at_limit') or '',
                    (x.get('tech') or '') if PN.SHOW_IDS else ''])
                it.setBackground(1, QBrush(LEVEL_BG[lvl]))
                it.setData(0, Qt.UserRole, dict(x))
                it.setToolTip(0, x['what'])
                it.setToolTip(3, x.get('at_limit') or '')
        if PN.SHOW_IDS and rep.get('usage'):
            head = QTreeWidgetItem(self.tree, ['Banks (technical)'])
            head.setFont(0, bold)
            head.setFirstColumnSpanned(True)
            head.setFlags(Qt.ItemIsEnabled)
            for b, u, cap, kind, spills in CAP.bank_rows(rep['usage']):
                lvl = 'ok' if spills else CAP._level(u, cap)
                it = QTreeWidgetItem(self.tree, [
                    f'   bank ${b:02X}', f'{u:,} of {cap:,} B', '',
                    'spills into the next bank' if spills else 'the build stops',
                    kind])
                it.setBackground(1, QBrush(LEVEL_BG[lvl]))
        for i in range(len(COLS)):
            self.tree.resizeColumnToContents(i)
        self.tree.setColumnWidth(0, min(self.tree.columnWidth(0), 520))
        self.note.setText(f"Measured from the unsaved project after each edit "
                          f"(took {rep.get('seconds', 0):.1f} s). Double-click a row to "
                          'open what it counts.')

    # ------------------------------------------------------------------ navigation
    def _open(self, item, _col):
        x = item.data(0, Qt.UserRole)
        if not x:
            return
        if x.get('room'):
            nav = {'tab': 'rooms', 'room': x['room']}
            if x.get('screen') is not None:
                nav['screen'] = x['screen']
            self.navigate.emit(nav)
        elif x.get('tab'):
            self.openTab.emit(x['tab'])


def _esc(t):
    return str(t).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
