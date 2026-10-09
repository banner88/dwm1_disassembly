"""space_meter.py — "no invisible ceilings" for the compiler-owned banks (S96).

EDITOR_DESIGN §5.C: every ceiling the author can hit must be visible. The
banks the project fills are $60 (rooms / NPCs / scripts / text), $64 (screen
layouts + palette grids — every cloned room copies its screens here), $67
(tileset sheets) and $71 (per-room tables). The meter re-measures the
UNSAVED document shortly after each edit with `compiler.measure_banks`
(the same byte count the pre-build overflow check uses) and turns amber
above 80 %, red above 95 %.

S135 (ROADMAP ARC CAP2a): layouts, palette grids and tilesets no longer stop
at a full $64 / $67 — what does not fit goes to the 4 MB ROM's new banks
($80-$FF, shared). So a full $64 / $67 is amber, not red, and a fifth bar
("new banks") counts the banks $80-$FF in use out of 128.
"""

from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QHBoxLayout, QLabel, QProgressBar, QSizePolicy, QWidget

from editor2.core.compiler import measure_banks

BANKS = ((0x60, 'rooms/scripts/text'), (0x64, 'screen layouts'),
         (0x67, 'tilesets'), (0x71, 'room tables'),
         (0x80, 'new banks $80-$FF of the 4 MB ROM (layouts / tilesets that do not '
                'fit $64 / $67)'))
EXT = 0x80         # S135: the "new banks" bar (measures every bank $80-$FF)


class SpaceMeter(QWidget):
    def __init__(self, session, repo, parent=None):
        super().__init__(parent)
        self.s, self.repo = session, repo
        h = QHBoxLayout(self)
        h.setContentsMargins(0, 0, 6, 0)
        h.setSpacing(4)
        self.setSizePolicy(QSizePolicy.Fixed, QSizePolicy.Fixed)
        h.addWidget(QLabel('bank space'))
        self.bars = {}
        for bank, what in BANKS:
            b = QProgressBar()
            b.setRange(0, 1000)
            b.setFixedWidth(78)
            b.setFixedHeight(14)
            b.setTextVisible(True)
            b.setFormat(f'${bank:02X} –')
            b.setToolTip(f'bank ${bank:02X} — {what}')
            h.addWidget(b)
            self.bars[bank] = (b, what)
        self.timer = QTimer(self)
        self.timer.setSingleShot(True)
        self.timer.setInterval(900)    # S132: after the edits settle (0.14 s now, was 2 s)
        self.timer.timeout.connect(self.measure)
        # bound methods (not lambdas): Qt drops the connections when this
        # widget is deleted (a new project replaces the meter)
        session.structureChanged.connect(self.poke)
        session.undo.indexChanged.connect(self.poke)
        session.layoutChanged.connect(self.poke)
        self.last = {}
        self.measure()

    def poke(self, *_a):
        self.timer.start()

    def measure(self):
        try:
            usage, errors = measure_banks(self.s.doc.data, self.s.project_dir, self.repo,
                                          banks=tuple(self.bars))   # S132: only these
        except Exception as e:                       # never break the editor
            usage, errors = {}, [str(e)]
        if errors:
            for bank, (b, what) in self.bars.items():
                b.setFormat(f'${bank:02X} ?')
                b.setToolTip(f'bank ${bank:02X} — {what}: not measurable until the '
                             f'project validates:\n' + '\n'.join(errors[:5]))
            return
        self.last = usage
        ext = {b: u for b, u in usage.items() if b >= EXT}
        for bank, (b, what) in self.bars.items():
            if bank == EXT:
                n = len(ext)
                frac = n / 128
                b.setValue(int(frac * 1000))
                b.setFormat(f'new {n}/128')
                col = '#d04040' if frac > 0.95 else '#d0a030' if frac > 0.80 else '#3c9a50'
                b.setStyleSheet(f'QProgressBar::chunk {{ background: {col}; }}')
                detail = '\n'.join(f'  ${k:02X}: {u:,} of {c:,} bytes'
                                    for k, (u, c) in sorted(ext.items())) or '  (none in use)'
                b.setToolTip(f'{what}: {n} of 128 banks in use.\n{detail}\n'
                             'Measured from the unsaved project.')
                continue
            used, cap = usage.get(bank, (0, 0x4000))
            frac = used / cap if cap else 0
            b.setValue(int(frac * 1000))
            b.setFormat(f'${bank:02X} {frac * 100:.0f}%')
            col = '#d04040' if frac > 0.95 else '#d0a030' if frac > 0.80 else '#3c9a50'
            spills = bank in (0x64, 0x67)
            if spills and frac > 0.80:
                col = '#d0a030'          # S135: full is fine — the rest goes to the new banks
            b.setStyleSheet(f'QProgressBar::chunk {{ background: {col}; }}')
            more = (' When it is full, further ones go to the new banks $80+ '
                    '(the "new" bar).' if spills else '')
            b.setToolTip(f'bank ${bank:02X} — {what}: {used:,} of {cap:,} bytes used '
                         f'({cap - used:,} free). Measured from the unsaved project '
                         '(same count as the pre-build overflow check).' + more)
