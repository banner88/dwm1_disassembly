"""memorial_dialog.py — the memorial's settings and a statue's own words (S154).

  * MemorialDialog    — how many monsters the memorial remembers (custom.memorial.cap,
                        8-120; the oldest is forgotten when it is full) and the words
                        every statue says / an empty statue says.
  * StatueWordsDialog — one statue's OWN words (or back to the memorial's).

The words are game text (GameTextField, EDITOR_DESIGN §5.0): {fallen} = the monster's
nickname, {fallen_level} = its level when it last won, {fallen_species} = its kind —
those three only in a statue's words (editor2/core/memorial.py; help 77_memorial.md).
"""

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (QCheckBox, QDialog, QDialogButtonBox, QFormLayout, QLabel,
                               QMessageBox, QSpinBox, QVBoxLayout)

from editor2.core import memorial as MM

INSERTS = ('Inserts: {fallen} = the monster\'s nickname, {fallen_level} = its level when '
           'it last won, {fallen_species} = what kind of monster it is.')


def _note(text):
    lb = QLabel(text)
    lb.setWordWrap(True)
    lb.setStyleSheet('color:#aaa;')
    return lb


class MemorialDialog(QDialog):
    def __init__(self, doc, rom, parent=None):
        super().__init__(parent)
        from editor2.app.rooms.talk_editor import GameTextField
        self.setWindowTitle('Memorial settings')
        self.resize(760, 640)
        s = doc.memorial_settings()
        v = QVBoxLayout(self)
        v.addWidget(_note('Statues remember the monsters that won a boss battle, an arena '
                          'class or Starry Night with the player and have left since — bred, '
                          'released or traded. ' + INSERTS))
        f = QFormLayout()
        f.setLabelAlignment(Qt.AlignRight)
        self.cap = QSpinBox()
        self.cap.setRange(MM.CAP_MIN, MM.CAP_MAX)
        self.cap.setValue(int(s['cap']))
        self.cap.setSuffix(' monsters')
        self.cap.setToolTip('When the memorial is full the monster remembered longest ago is '
                            'forgotten. 8 bytes of the save each (SRAM bank 3).')
        f.addRow('remembers up to', self.cap)
        v.addLayout(f)
        v.addWidget(QLabel('A statue says (when it shows a monster):'))
        self.text = GameTextField(rom, s['text'], empty_note="the game's default words")
        v.addWidget(self.text, 2)
        v.addWidget(QLabel('An empty statue says:'))
        self.empty = GameTextField(rom, s['empty'], empty_note="the game's default words")
        v.addWidget(self.empty, 1)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def _ok(self):
        for fld in (self.text, self.empty):
            if fld.problem():
                QMessageBox.warning(self, 'Memorial settings', fld.problem())
                return
        self.accept()

    def values(self):
        return {'cap': self.cap.value(),
                'text': self.text.value() or MM.DEFAULT_TEXT,
                'empty': self.empty.value() or MM.DEFAULT_EMPTY}


class StatueWordsDialog(QDialog):
    def __init__(self, doc, room, sid, rom, parent=None):
        super().__init__(parent)
        from editor2.app.rooms.talk_editor import GameTextField
        self.setWindowTitle(f'Statue {doc.statue_number(room, sid)} — its words')
        self.resize(760, 600)
        w = doc.statue_words(room, sid)
        v = QVBoxLayout(self)
        self.own = QCheckBox('This statue has words of its own (else the memorial\'s — '
                             'Memorial settings…)')
        self.own.setChecked(w['own'])
        v.addWidget(self.own)
        v.addWidget(_note(INSERTS))
        v.addWidget(QLabel('It says (when it shows a monster):'))
        self.text = GameTextField(rom, w['text'], empty_note="the memorial's words")
        v.addWidget(self.text, 2)
        v.addWidget(QLabel('Empty, it says:'))
        self.empty = GameTextField(rom, w['empty'], empty_note="the memorial's words")
        v.addWidget(self.empty, 1)
        self.own.toggled.connect(self._sync)
        self._sync(self.own.isChecked())
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def _sync(self, on):
        self.text.setEnabled(on)
        self.empty.setEnabled(on)

    def _ok(self):
        if self.own.isChecked():
            for fld in (self.text, self.empty):
                if fld.problem():
                    QMessageBox.warning(self, 'Statue words', fld.problem())
                    return
        self.accept()

    def values(self):
        return {'own': self.own.isChecked(), 'text': self.text.value(),
                'empty': self.empty.value()}
