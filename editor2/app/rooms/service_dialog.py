"""service_dialog.py — make an NPC a service NPC (ROADMAP P3.14e1, S126; model:
editor2/core/services_doc.py, compiler: editor2/core/services.py).

The NPC becomes the Vault keeper, a farm keeper, the librarian, the Monster
Namer, the Medal Man, the egg appraiser or the gate guide — the game's own
menu, which works in any room (one Vault / farm / medal count for the whole
game). Optional: its own menu lines (a line set, edited on the Services tab)
and what it says on the first visit (remembered by a flag).
"""

from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox, QFormLayout,
                               QInputDialog, QLabel, QLineEdit, QListWidget, QListWidgetItem,
                               QPlainTextEdit, QVBoxLayout)

NEW_SET = '__new__'


class ServiceDialog(QDialog):
    """cur = Document.service_of(...) or None. result(): (kind, lines, first_time)."""

    def __init__(self, doc, cur=None, parent=None):
        super().__init__(parent)
        self.doc = doc
        self.setWindowTitle('Service NPC')
        self.resize(600, 560)
        v = QVBoxLayout(self)
        top = QLabel('This NPC is one of the game\'s services. Its menu is the game\'s '
                     'own and works in any room; there is one Vault, one farm and one '
                     'medal count for the whole game, so every NPC of a kind shares them '
                     '(the original game\'s NPCs too).')
        top.setWordWrap(True)
        v.addWidget(top)
        self.kinds = QListWidget()
        for kind, name, what in doc.service_kinds():
            it = QListWidgetItem(f'{name} — {what}')
            it.setData(256, kind)
            self.kinds.addItem(it)
        self.kinds.currentRowChanged.connect(self._kind_changed)
        v.addWidget(self.kinds, 1)
        f = QFormLayout()
        self.lines = QComboBox()
        self.lines.setToolTip('The words its menu says. "The game\'s lines" = the original '
                              'NPC\'s (Pulio\'s for the farm). A line set changes any of them '
                              '— its speaker\'s name, single lines — edit it on the Services tab.')
        f.addRow('menu lines', self.lines)
        self.lines_note = QLabel('')
        self.lines_note.setWordWrap(True)
        self.lines_note.setStyleSheet('color: #aaa;')
        f.addRow('', self.lines_note)
        self.first = QCheckBox('says something else the first time')
        self.first.toggled.connect(self._first_toggled)
        f.addRow('first visit', self.first)
        self.first_text = QPlainTextEdit()
        self.first_text.setPlaceholderText('What it says the first time, instead of its greeting '
                                           '(a blank line starts a new box; 2 lines of 16 a box)')
        self.first_text.setMaximumHeight(110)
        f.addRow('', self.first_text)
        self.flag = QLineEdit()
        self.flag.setToolTip('The flag that remembers the first visit (created when new; it is '
                             'listed on the Progression & Flags tab)')
        f.addRow('remembered by flag', self.flag)
        v.addLayout(f)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._cur = cur or {}
        row = 0
        for i in range(self.kinds.count()):
            if self.kinds.item(i).data(256) == self._cur.get('kind'):
                row = i
        self.kinds.setCurrentRow(row)
        ft = self._cur.get('first_time')
        self.first.setChecked(bool(ft))
        if ft:
            self.first_text.setPlainText('\n\n'.join('\n'.join(b) for b in (ft.get('boxes') or [])))
            self.flag.setText(ft.get('flag') or '')
        self._first_toggled(bool(ft))

    def kind(self):
        it = self.kinds.currentItem()
        return it.data(256) if it else None

    def _kind_changed(self, _row):
        kind = self.kind()
        self.lines.clear()
        if kind == 'gates':
            self.lines.addItem("the game's lines (the guide's list has no lines of its own)", None)
            self.lines.setEnabled(False)
            self.lines_note.setText("The list of Travelers' Gates shows the original game's 31 "
                                    "gates (your own gates and worlds are not on it).")
        else:
            self.lines.setEnabled(True)
            self.lines.addItem("the game's lines", None)
            for st in self.doc.service_line_sets(kind):
                self.lines.addItem(f"{st['name']}" + ('  (every NPC of this kind)'
                                                      if st['everywhere'] else ''), st['id'])
            self.lines.addItem('a new line set…', NEW_SET)
            cur = self._cur.get('lines') if self._cur.get('kind') == kind else None
            k = self.lines.findData(cur)
            self.lines.setCurrentIndex(max(0, k))
            self.lines_note.setText({'medals': 'The rewards (medals → egg) are on the Services '
                                               'tab — for every Medal Man, the game\'s too.',
                                     'namer': 'Its question is a YES / NO; the naming screen '
                                              'follows the list.'}.get(kind, ''))
        cur_flag = self.flag.text().strip()
        if kind and (not cur_flag or cur_flag in {f'{k}_met' for k in self._kind_ids()}):
            self.flag.setText(f'{kind}_met')        # the suggestion follows the kind

    def _kind_ids(self):
        return [self.kinds.item(i).data(256) for i in range(self.kinds.count())]

    def _first_toggled(self, on):
        self.first_text.setEnabled(on)
        self.flag.setEnabled(on)

    def _ok(self):
        if self.lines.currentData() == NEW_SET:
            name, ok = QInputDialog.getText(self, 'New line set', 'Name of the line set:',
                                            text=f'{self.kind()} lines')
            if not ok or not name.strip():
                return
            self._new_set_name = name.strip()
        self.accept()

    def result_spec(self):
        kind = self.kind()
        lines = self.lines.currentData()
        ft = None
        if self.first.isChecked():
            txt = self.first_text.toPlainText().strip()
            if txt:
                boxes = [[ln for ln in blk.split('\n') if ln.strip()][:2]
                         for blk in txt.split('\n\n') if blk.strip()]
                ft = {'boxes': boxes, 'flag': self.flag.text().strip()}
        return kind, lines, ft, getattr(self, '_new_set_name', None)
