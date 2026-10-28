"""hints_dialog.py — the breeding hints' words (S158, ROADMAP E15; help 78_hints.md).

  * HintWordsDialog   — several texts at once, each its own or "the default": the
                        project's words for every monument / archive (Breeding tab →
                        Hints → Words…) or one monument's / archive's own words (Rooms
                        tab panel → Its words…).
  * RiddleDialog      — one cross's riddle (or none: the monument shows the cross).
  * FamilyWordsDialog — what a family matcher reads as ("any Dragon") and the {bred}
                        mark's words.

Every text is game text (GameTextField, EDITOR_DESIGN §5.0) with the inserts {parent1} /
{parent2} / {child} / {bred} (the cross, filled by the game right before) and, in an
archive's texts, {family} (written in by the compiler).
"""

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (QCheckBox, QDialog, QDialogButtonBox, QFormLayout, QLabel,
                               QLineEdit, QMessageBox, QScrollArea, QVBoxLayout, QWidget)

from editor2.core import hints as HT

INSERTS = ('Inserts: {parent1} / {parent2} = the parents (a monster, or a family\'s words '
           'such as "any Dragon"), {child} = the monster the cross makes (with " +5" when it '
           'needs a plus), {bred} = "(bred)" once the player has made this cross.')
FAMILY_NOTE = ' In an archive\'s words {family} is the archive\'s family name.'


def _note(text):
    lb = QLabel(text)
    lb.setWordWrap(True)
    lb.setStyleSheet('color:#aaa;')
    return lb


class HintWordsDialog(QDialog):
    """roles = [(role, label, boxes or None, own, default note)] -> values() = {role:
    boxes (own words) or None (the default)}."""

    def __init__(self, rom, title, roles, intro='', family=False, parent=None):
        super().__init__(parent)
        from editor2.app.rooms.talk_editor import GameTextField
        self.setWindowTitle(title)
        self.resize(780, 720)
        self.family = family
        v = QVBoxLayout(self)
        if intro:
            v.addWidget(_note(intro))
        v.addWidget(_note(INSERTS + (FAMILY_NOTE if family else '')))
        sc = QScrollArea()
        sc.setWidgetResizable(True)
        body = QWidget()
        bl = QVBoxLayout(body)
        self.rows = []
        for role, label, boxes, own, dnote in roles:
            cb = QCheckBox(label + ' — own words (else ' + dnote + ')')
            cb.setChecked(bool(own))
            fld = GameTextField(rom, boxes, empty_note=dnote)
            fld.setEnabled(bool(own))
            cb.toggled.connect(fld.setEnabled)
            bl.addWidget(cb)
            bl.addWidget(fld)
            self.rows.append((role, label, cb, fld))
        bl.addStretch(1)
        sc.setWidget(body)
        v.addWidget(sc, 1)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def _ok(self):
        for role, label, cb, fld in self.rows:
            if not cb.isChecked():
                continue
            why = fld.problem()
            val = fld.value()
            if why is None and val:
                try:
                    HT.check_text(val, label, family=self.family)
                except HT.HintError as ex:
                    why = str(ex)
            if why:
                QMessageBox.warning(self, self.windowTitle(), f'{label}: {why}')
                return
        self.accept()

    def values(self):
        return {role: (fld.value() if cb.isChecked() else None)
                for role, _l, cb, fld in self.rows}


class RiddleDialog(QDialog):
    def __init__(self, rom, cross, boxes, parent=None):
        super().__init__(parent)
        from editor2.app.rooms.talk_editor import GameTextField
        self.setWindowTitle(f'Riddle — {cross}')
        self.resize(760, 460)
        v = QVBoxLayout(self)
        v.addWidget(_note('A monument set to show a RIDDLE says this instead of the cross '
                          '(the archive always lists the cross itself). Empty = no riddle: '
                          'the monument shows the cross. ' + INSERTS))
        self.text = GameTextField(rom, boxes, empty_note='no riddle')
        v.addWidget(self.text, 1)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def _ok(self):
        why = self.text.problem()
        val = self.text.value()
        if why is None and val:
            try:
                HT.check_text(val, 'the riddle')
            except HT.HintError as ex:
                why = str(ex)
        if why:
            QMessageBox.warning(self, 'Riddle', why)
            return
        self.accept()

    def value(self):
        return self.text.value()


class FamilyWordsDialog(QDialog):
    def __init__(self, settings, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Hint words: families and the bred mark')
        v = QVBoxLayout(self)
        v.addWidget(_note('A cross whose parent is a whole family ("any Dragon") reads that '
                          f'family\'s words here (at most {HT.WORD_MAX} letters). The bred '
                          f'mark ({{bred}}, at most {HT.BRED_MAX}) shows on a cross the player '
                          'has made; the other words on one not made yet (usually empty).'))
        f = QFormLayout()
        f.setLabelAlignment(Qt.AlignRight)
        self.fam = []
        for name, w in zip(HT.FAMILIES, settings['family_words']):
            e = QLineEdit(w)
            e.setMaxLength(HT.WORD_MAX)
            f.addRow(name, e)
            self.fam.append(e)
        self.bred = QLineEdit(settings['bred_word'])
        self.bred.setMaxLength(HT.BRED_MAX)
        self.unbred = QLineEdit(settings['unbred_word'])
        self.unbred.setMaxLength(HT.BRED_MAX)
        f.addRow('bred', self.bred)
        f.addRow('not bred yet', self.unbred)
        v.addLayout(f)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def values(self):
        return {'family_words': [e.text().strip() for e in self.fam],
                'bred_word': self.bred.text(), 'unbred_word': self.unbred.text()}
