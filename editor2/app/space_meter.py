"""space_meter.py — "no invisible ceilings" in the status bar (S96; S145 two numbers).

EDITOR_DESIGN §5.C: every ceiling the author can hit must be visible.

S96-S139 showed one bar per compiler bank ($60 / $64 / $67 / $6C / $71) and a "new
banks" bar. Since the 4 MB arc (ARC CAP1-CAP3) a full $60 / $64 / $67 / $6C is normal
(they spill into the new banks), so four of those bars sat amber for good and none said
how much room was really left.

S145 (ROADMAP ARC CAP4d, user: "Sounds good"): TWO numbers, from the same report the
Capacity tab shows (`editor2/core/capacity.measure`, measured off the UI thread on a
copy of the unsaved document shortly after each edit):

  * **ROM space** — the bytes your rooms, texts, screens, tilesets and animated tiles
    use of the space they can fill (banks $60 / $64 / $67 / $6C + the 128 new banks);
  * **Rooms** — your rooms of about how many fit (bank $71's per-room tables decide,
    ≈950).

A ⚠ count follows when anything on the Capacity tab is near (≥ 80 %) or at its limit.
Clicking either opens the Capacity tab. `last` keeps the {bank: (used, capacity)} usage
(the tests and the tab's technical section read it).
"""

import threading

from PySide6.QtCore import QTimer, Qt, Signal
from PySide6.QtWidgets import QHBoxLayout, QLabel, QProgressBar, QSizePolicy, QWidget

from editor2.core import capacity as CAP

GREEN, AMBER, RED = '#3c9a50', '#d0a030', '#d04040'


def _colour(frac):
    return RED if frac >= 1.0 else AMBER if frac >= CAP.NEAR else GREEN


class _ClickBar(QProgressBar):
    clicked = Signal()

    def mousePressEvent(self, ev):
        self.clicked.emit()
        super().mousePressEvent(ev)


class SpaceMeter(QWidget):
    # S142 (ARC CAP4a): a background measurement's result
    measured = Signal(object)
    # S145: the whole capacity report (the Capacity tab listens)
    reported = Signal(object)
    # S145: a click on a meter — open the Capacity tab
    openRequested = Signal()

    def __init__(self, session, repo, parent=None):
        super().__init__(parent)
        self.s, self.repo = session, repo
        h = QHBoxLayout(self)
        h.setContentsMargins(0, 0, 6, 0)
        h.setSpacing(4)
        self.setSizePolicy(QSizePolicy.Fixed, QSizePolicy.Fixed)
        self.bars = {}
        for key, width, tip in (
                ('space', 150, 'ROM space your rooms, texts, screens, tilesets and animated '
                               'tiles use. Click for the Capacity tab.'),
                ('rooms', 130, 'Your rooms, of about how many fit. Click for the Capacity '
                               'tab.')):
            b = _ClickBar()
            b.setRange(0, 1000)
            b.setFixedWidth(width)
            b.setFixedHeight(14)
            b.setTextVisible(True)
            b.setFormat('–')
            b.setToolTip(tip)
            b.setCursor(Qt.PointingHandCursor)
            b.clicked.connect(self.openRequested)
            h.addWidget(b)
            self.bars[key] = b
        self.warn = QLabel('')
        self.warn.setCursor(Qt.PointingHandCursor)
        self.warn.mousePressEvent = lambda _e: self.openRequested.emit()
        h.addWidget(self.warn)
        self.timer = QTimer(self)
        self.timer.setSingleShot(True)
        self.timer.setInterval(900)    # S132: after the edits settle
        self.timer.timeout.connect(self.measure_async)
        self.measured.connect(self._measured)
        self._running = False          # a background measurement is under way
        self._again = False            # an edit came while it ran
        # bound methods (not lambdas): Qt drops the connections when this
        # widget is deleted (a new project replaces the meter)
        session.structureChanged.connect(self.poke)
        session.undo.indexChanged.connect(self.poke)
        session.layoutChanged.connect(self.poke)
        self.last = {}                 # {bank: (used, cap)}
        self.report = None             # S145: the last capacity report
        # S145: the first measurement starts once the window is up (the timer runs on
        # the event loop, after open_project returns) — measured on a fresh 160-room
        # project, a measurement in the thread while the tabs were being built held the
        # interpreter and slowed opening down
        self.timer.start()

    def poke(self, *_a):
        self.timer.start()

    def _compute(self, data):
        try:
            return CAP.measure(data, self.s.project_dir, self.repo)
        except Exception as e:                       # never break the editor
            return {'rows': [], 'usage': {}, 'errors': [str(e)], 'content': {},
                    'rooms': {}, 'left': {}}

    def measure(self):
        """Measure now (blocking) and show it."""
        from editor2.core.document import fast_copy
        self._apply(self._compute(fast_copy(self.s.doc.data)))

    def measure_async(self):
        """S142 (ARC CAP4a): measure in a background thread — at 300 places a
        measurement is ~0.6 s of compiler work. The document is copied here (main
        thread); the thread only reads its copy; the result comes back as a signal."""
        if self._running:
            self._again = True
            return
        from editor2.core.document import fast_copy
        data = fast_copy(self.s.doc.data)
        self._running = True

        def run():
            res = self._compute(data)
            try:
                self.measured.emit(res)
            except RuntimeError:                     # the widget is gone
                pass
        threading.Thread(target=run, daemon=True).start()

    def _measured(self, rep):
        self._running = False
        self._apply(rep)
        if self._again:
            self._again = False
            self.timer.start()

    def _apply(self, rep):
        self.report = rep
        self.last = dict(rep.get('usage') or {})
        sp, rm = self.bars['space'], self.bars['rooms']
        c, r = rep.get('content') or {}, rep.get('rooms') or {}
        if rep.get('errors') or not c:
            for b, what in ((sp, 'ROM space'), (rm, 'rooms')):
                b.setValue(0)
                b.setFormat(f'{what} ?')
                b.setToolTip(f'{what}: not measurable until the project builds:\n'
                             + '\n'.join((rep.get('errors') or ['?'])[:5]))
            n = len([x for x in rep.get('rows') or [] if x.get('level') == 'full'])
            self.warn.setText(f'⚠ {n}' if n else '')
            self.reported.emit(rep)
            return
        frac = c['used'] / c['cap']
        sp.setValue(int(frac * 1000))
        sp.setFormat(f'ROM space {frac * 100:.0f}%')
        sp.setStyleSheet(f'QProgressBar::chunk {{ background: {_colour(frac)}; }}')
        left = rep.get('left') or {}
        more = (f"\nAbout {left['rooms']:,} more rooms like your average one "
                f"({CAP.kb(left['typical'])} each)." if left.get('rooms') is not None else '')
        sp.setToolTip(f"Your rooms, texts, screens, tilesets and animated tiles use "
                      f"{CAP.kb(c['used'])} of {CAP.kb(c['cap'])}.{more}\n"
                      'Measured from the unsaved project. Click for the Capacity tab.')
        n, top = r.get('count', 0), r.get('ceiling') or 1
        frac = n / top
        rm.setValue(int(frac * 1000))
        rm.setFormat(f'rooms {n:,} / ≈{top:,}')
        rm.setStyleSheet(f'QProgressBar::chunk {{ background: {_colour(frac)}; }}')
        rm.setToolTip(f'{n:,} rooms of about {top:,} — the table that holds every room\'s '
                      'record, songs and battles fills first. Click for the Capacity tab.')
        bad = CAP.worst(rep)
        self.warn.setText(f'⚠ {len(bad)}' if bad else '')
        self.warn.setToolTip('\n'.join(f"{x['what']}: {x['shown']}" for x in bad[:8])
                             + '\nClick for the Capacity tab.' if bad else '')
        self.reported.emit(rep)
