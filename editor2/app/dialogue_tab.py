"""dialogue_tab.py — the Dialogue tab (S108, ROADMAP P3.10 part 3; read-only
seed of P3.6; model editor2/core/dialogue_index.py).

Every text the game can show: the 2,560 text ids (NPCs, story, system — the
id -> bank / address map measured in the emulator) and the text tables
(battle messages, field / item / spell messages, skill and monster
descriptions). Search by words, id or address; or pick a monster to see every
text that names it ("Slime", "Slimes", "Slime's") — under its original name
and, if renamed, its new one. Renaming a monster changes every place the game
prints the name from its name table; words written INTO dialogue stay as
written — this tab is where to find them. "Save as text file…" exports the
current list.
"""

from PySide6.QtCore import Qt
from PySide6.QtGui import QColor, QFont, QTextCharFormat, QTextCursor
from PySide6.QtWidgets import (QAbstractItemView, QComboBox, QFileDialog,
                               QHBoxLayout, QHeaderView, QLabel, QLineEdit,
                               QPlainTextEdit, QPushButton, QSplitter,
                               QTableWidget, QTableWidgetItem, QVBoxLayout,
                               QWidget)

from editor2.core import dialogue_index as D

ALL = 'All texts'
HELP = ('Every text in the game, read straight from the ROM (read-only for now). '
        'Renaming a monster changes it everywhere the game prints the name for you '
        '(battles, menus, the library, breeding, joins, recipe lines) — but not words '
        'written into dialogue. Pick a monster to list the texts that name it.')


class DialogueTab(QWidget):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.entries = D.load()
        self.shown = []
        v = QVBoxLayout(self)
        h = QLabel(HELP)
        h.setWordWrap(True)
        v.addWidget(h)
        row = QHBoxLayout()
        self.query = QLineEdit()
        self.query.setPlaceholderText('Search words, a text id ($0123) or an address ($42:$4142)')
        self.query.textChanged.connect(self.refresh)
        row.addWidget(self.query, 2)
        self.kind = QComboBox()
        self.kind.addItem(ALL, None)
        for k in D.kinds(self.entries):
            self.kind.addItem(k, k)
        self.kind.currentIndexChanged.connect(self.refresh)
        row.addWidget(self.kind, 1)
        self.monster = QComboBox()
        self.monster.currentIndexChanged.connect(self.refresh)
        row.addWidget(QLabel('Names a monster:'))
        row.addWidget(self.monster, 1)
        exp = QPushButton('Save as text file…')
        exp.clicked.connect(self._export)
        row.addWidget(exp)
        v.addLayout(row)
        split = QSplitter(Qt.Vertical)
        self.table = QTableWidget()
        self.table.setColumnCount(4)
        self.table.setHorizontalHeaderLabels(['Kind', 'Id', 'Where', 'Text'])
        self.table.verticalHeader().setVisible(False)
        self.table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.table.horizontalHeader().setSectionResizeMode(3, QHeaderView.Stretch)
        self.table.currentCellChanged.connect(self._show)
        split.addWidget(self.table)
        self.detail = QPlainTextEdit()
        self.detail.setReadOnly(True)
        f = QFont('Menlo')
        f.setStyleHint(QFont.Monospace)
        self.detail.setFont(f)
        split.addWidget(self.detail)
        split.setSizes([500, 220])
        v.addWidget(split, 1)
        self.count = QLabel()
        v.addWidget(self.count)
        self.fill_monsters()
        self.s.undo.indexChanged.connect(self._undo_changed)

    def _undo_changed(self, _i):
        # a tab of a previously opened project can still be wired to that
        # session's undo stack after Qt deleted its widgets (S107 lesson)
        from shiboken6 import isValid
        if isValid(self) and isValid(self.monster):
            self.fill_monsters()

    # ------------------------------------------------------------ monsters
    def _names(self):
        try:
            return self.s.doc.monster_names_effective()
        except Exception:                              # noqa: BLE001
            return {}

    def fill_monsters(self):
        from editor2.core import monster_text as MT
        cur = self.monster.currentData()
        names = self._names()
        van = MT.vanilla()
        self.monster.blockSignals(True)
        self.monster.clear()
        self.monster.addItem('—', None)
        for sid in sorted(names):
            if 215 <= sid <= 220:
                continue
            orig = MT.decode(van['names'][sid]) if sid < 215 else None
            label = names[sid] + (f'  (was {orig})' if orig and orig != names[sid] else '')
            self.monster.addItem(f'{sid:3d}  {label}', sid)
        i = self.monster.findData(cur)
        self.monster.setCurrentIndex(max(0, i))
        self.monster.blockSignals(False)
        self.refresh()

    def show_monster(self, sid):
        """Monsters tab → "Texts that name it…"."""
        self.query.clear()
        self.kind.setCurrentIndex(0)
        i = self.monster.findData(sid)
        if i >= 0:
            self.monster.setCurrentIndex(i)
        self.refresh()

    def _monster_names(self, sid):
        from editor2.core import monster_text as MT
        names = self._names()
        out = [names.get(sid)] if names.get(sid) else []
        if sid is not None and sid < 215:
            orig = MT.decode(MT.vanilla()['names'][sid])
            if orig not in out:
                out.append(orig)
        return out

    # ------------------------------------------------------------ list
    def refresh(self, *_a):
        entries = D.search(self.query.text(), self.entries, kind=self.kind.currentData())
        sid = self.monster.currentData()
        self._marks = []
        if sid is not None:
            names = self._monster_names(sid)
            keep = set()
            for n in names:
                keep |= {e['key'] for e in D.mentions(n, entries)}
            entries = [e for e in entries if e['key'] in keep]
            self._marks = names
        self.shown = entries
        self.table.setRowCount(len(entries))
        for r, e in enumerate(entries):
            prev = e['text'].replace(' ▼', '').replace('\n', ' ')
            vals = [e['kind'], e['ref'], e['where'], prev[:200]]
            for c, val in enumerate(vals):
                self.table.setItem(r, c, QTableWidgetItem(val))
        self.table.resizeColumnToContents(0)
        self.table.resizeColumnToContents(1)
        self.table.resizeColumnToContents(2)
        self.count.setText(f'{len(entries)} texts' + (
            f" naming {' / '.join(self._marks)}" if self._marks else ''))
        if entries:
            self.table.setCurrentCell(0, 3)
        else:
            self.detail.clear()

    def _show(self, row, _c=None, _pr=None, _pc=None):
        if not 0 <= row < len(self.shown):
            return
        e = self.shown[row]
        same = [x['ref'] for x in self.entries if x.get('same_as') == e['key']]
        head = f"{e['kind']} {e['ref']}   at {e['where']}"
        if same:
            head += f"   (also shown as {', '.join(same[:12])}{' …' if len(same) > 12 else ''})"
        self.detail.setPlainText(head + '\n\n' + e['text'])
        fmt = QTextCharFormat()
        fmt.setBackground(QColor(255, 225, 120))
        doc = self.detail.document()
        for n in self._marks:
            pat = D.name_pattern(n)
            txt = self.detail.toPlainText()
            for m in pat.finditer(txt):
                cur = QTextCursor(doc)
                cur.setPosition(m.start())
                cur.setPosition(m.end(), QTextCursor.KeepAnchor)
                cur.mergeCharFormat(fmt)

    def _export(self):
        path, _ = QFileDialog.getSaveFileName(self, 'Save texts', 'dialogue.txt',
                                              'Text files (*.txt)')
        if path:
            n = D.export_text(self.shown, path)
            self.count.setText(f'Saved {n} texts to {path}')
