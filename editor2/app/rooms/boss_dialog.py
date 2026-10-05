"""boss_dialog.py — Make boss… (S123, ROADMAP NG3; EDITOR_DESIGN §5.1e).

One dialog for what a boss NPC needs (user S123: "mini-bosses, endbosses, flags and
triggers"): what it says, a battle of 1-3 enemies, its own "beaten" flag (other
rooms / NPCs / battle lists can test it), it leaves the moment it is beaten
(the Vanish step) and stays gone (shown only while its flag is OFF), optionally
the END boss of a world (the world's cleared flag → its portal swirl stops or
changes colour) and a way out afterwards (the helper takes the player away).
Builds the same conversation the Conversation dialog edits
(editor2/core/worlds.WorldsMixin.make_boss).
"""

from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox, QFormLayout,
                               QGroupBox, QHBoxLayout, QLabel, QLineEdit, QMessageBox,
                               QPushButton, QRadioButton, QSpinBox, QVBoxLayout, QWidget)

from editor2.app.rooms.conversation_dialog import DestEditor
from editor2.app.rooms.talk_editor import BoxList
from editor2.core.conversation import describe_enemy_row, vanilla_enemies


class MakeBossDialog(QDialog):
    def __init__(self, doc, rom, room, key=0, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Make boss')
        self.resize(760, 760)
        self.doc, self.rom, self.room = doc, rom, room
        v = QVBoxLayout(self)
        intro = QLabel('Turns this NPC into a boss: it speaks, you fight, and when you WIN it '
                       'flickers out and stays gone (its own "beaten" flag is turned ON and '
                       'it is shown only while that flag is OFF). Anything else can test the '
                       'flag — a door, another NPC\'s words, a battle list. A loss is the game\'s '
                       'rule: back to the Castle, half the gold.')
        intro.setWordWrap(True)
        v.addWidget(intro)
        f = QFormLayout()
        self.name = QLineEdit('warden')
        self.name.textChanged.connect(self._name_changed)
        f.addRow('boss name', self.name)
        self.flag_lbl = QLabel('')
        f.addRow('its flag', self.flag_lbl)
        v.addLayout(f)
        g = QGroupBox('Before the battle it says')
        gv = QVBoxLayout(g)
        self.before = BoxList(rom, [['You shall not', 'pass!']], vertical=False)
        gv.addWidget(self.before)
        v.addWidget(g, 1)
        g = QGroupBox('Battle')
        gf = QFormLayout(g)
        self.count = QSpinBox()
        self.count.setRange(1, 3)
        self.count.valueChanged.connect(self._count_changed)
        gf.addRow('enemies', self.count)
        self.combos = []
        choices = [(f"★ {e.get('name') or e['id']} (your enemy)", e['id'])
                   for e in doc.project_enemies()]
        rows = vanilla_enemies()
        choices += [(describe_enemy_row(r), r['eid']) for r in rows if r.get('boss')]
        choices += [(describe_enemy_row(r), r['eid']) for r in rows if not r.get('boss')]
        for i in range(3):
            c = QComboBox()
            c.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
            c.setMinimumContentsLength(30)
            for lab, d in choices:
                c.addItem(lab, d)
            self.combos.append(c)
            gf.addRow(f'enemy {i + 1}', c)
        note = QLabel('Your own enemies (★, made with Enemies… in any conversation or on the '
                      'Monsters tab) can be set to never / sometimes / always join.')
        note.setWordWrap(True)
        note.setStyleSheet('color:#aaa;')
        gf.addRow(note)
        v.addWidget(g)
        self._count_changed()
        g = QGroupBox('After the win')
        gv = QVBoxLayout(g)
        self.says_after = QCheckBox('it says something (after it has gone)')
        gv.addWidget(self.says_after)
        self.after = BoxList(rom, [['The way is open.']], vertical=False)
        self.after.setVisible(False)
        self.says_after.toggled.connect(self.after.setVisible)
        gv.addWidget(self.after)
        wr = QHBoxLayout()
        self.end_boss = QCheckBox('END boss of world')
        self.world = QComboBox()
        for gid in doc.world_ids():
            self.world.addItem(f'{doc.world_name(gid)} (gate {gid})', gid)
        here = doc.world_of_room(room['id']) if room is not None else None
        if here is not None:
            self.world.setCurrentIndex(max(0, self.world.findData(here)))
        self.end_boss.setEnabled(self.world.count() > 0)
        self.end_boss.setToolTip('Also turns the world\'s cleared flag ON: its portal swirl '
                                 'stops (or takes its colour), and every "gate:N cleared" test '
                                 'in the project sees it')
        self.end_boss.toggled.connect(self._end_changed)
        wr.addWidget(self.end_boss)
        wr.addWidget(self.world, 1)
        gv.addLayout(wr)
        self.stay = QRadioButton('the player stays here')
        self.leave = QRadioButton('the helper takes the player to:')
        self.stay.setChecked(True)
        gv.addWidget(self.stay)
        gv.addWidget(self.leave)
        self.mv = {'dest': 'vanilla:$00', 'screen': 1, 'x': 4, 'y': 5}
        self.dest = DestEditor(doc, self.mv, lambda: None)
        gv.addWidget(self.dest)
        self.helper_says = BoxList(rom, [['Well done!', 'Let\'s go back.']], vertical=False)
        gv.addWidget(QLabel('the helper says first (Warubou; empty = nothing):'))
        gv.addWidget(self.helper_says)
        self.leave.toggled.connect(self._leave_changed)
        self._leave_changed(False)
        v.addWidget(g, 1)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._name_changed()

    # ---------------------------------------------------------------- state
    def flag_name(self):
        return self.doc._slug(f"{self.name.text().strip() or 'boss'}_beaten")

    def _name_changed(self, *_a):
        nm = self.flag_name()
        exists = any(f.get('name') == nm for f in self.doc.flags())
        self.flag_lbl.setText(f'{nm}' + ('  (already exists — it is reused)' if exists
                                         else '  (a new project flag)'))

    def _count_changed(self, *_a):
        for i, c in enumerate(self.combos):
            c.setEnabled(i < self.count.value())

    def _end_changed(self, on):
        if on and self.world.currentData() is not None:
            spot = self.doc.world_portal_spot(self.world.currentData())
            if spot is not None:
                self.leave.setChecked(True)
                self._set_dest(*spot)

    def _set_dest(self, dest, screen, x, y):
        self.mv.update({'dest': dest, 'screen': screen, 'x': x, 'y': y})
        i = self.dest.room.findData(dest)
        if i >= 0:
            self.dest.room.setCurrentIndex(i)
        for k, val in (('screen', screen), ('x', x), ('y', y)):
            self.dest.sp[k].setValue(val)

    def _leave_changed(self, on):
        self.dest.setEnabled(bool(on))
        self.helper_says.setEnabled(bool(on))

    def _ok(self):
        probs = []
        for what, bl in (('before the battle', self.before),
                         ('after the win', self.after if self.says_after.isChecked() else None),
                         ('the helper', self.helper_says if self.leave.isChecked() else None)):
            if bl is not None and bl.bad_boxes():
                probs.append(f'{what}: a text box does not fit (Fit all)')
        if probs:
            QMessageBox.warning(self, 'Make boss', '\n'.join(probs))
            return
        self.accept()

    # ---------------------------------------------------------------- result
    def result_args(self):
        """kwargs for Document.make_boss (minus the NPC address)."""
        enemies = [self.combos[i].currentData() for i in range(self.count.value())]
        intro = self.before.text() if not self.before.is_blank() else None
        outro = (self.after.text() if self.says_after.isChecked() and not self.after.is_blank()
                 else None)
        leave = None
        if self.leave.isChecked():
            leave = dict(self.mv)
            if not self.helper_says.is_blank():
                leave['say'] = self.helper_says.text()
        end = self.world.currentData() if self.end_boss.isChecked() else None
        return {'enemies': enemies, 'flag_name': self.flag_name(), 'intro': intro,
                'outro': outro, 'end_of_world': end, 'leave': leave}
