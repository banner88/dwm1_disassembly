"""newgame_dialog.py — where a new game starts (S152, ROADMAP E3 a2; model:
editor2/core/newgame_doc.py, compiler: editor2/core/newgame.py, PROJECT_COMPILER §2.60).

User (S152): "editor probably SHOULD have that capability. New game -> where to
start -> etc."

Left: where the game starts — the game's own intro (the bedroom; with the Milly hook
the dresser sends Milly to the hook's arrival room) or one of your rooms (screen,
tile, facing) on a picture of that screen. Right: the original game's story — left
as it is, or as after the original opening (the game's own Castle, GreatTree and
Farm act as when the King has sent the player to the gates; the starter Slib is
never given). OK applies everything as one undo step.
"""

from PySide6.QtGui import QColor
from PySide6.QtWidgets import (QButtonGroup, QComboBox, QDialog, QDialogButtonBox,
                               QFormLayout, QGridLayout, QGroupBox, QLabel, QMessageBox,
                               QRadioButton, QSpinBox, QVBoxLayout)

from editor2.app.place_picker import PlacePicker
from editor2.app.rooms import commands as C
from editor2.app.rooms.redirect_dialog import _Preview
from editor2.core import newgame as NG

INTRO = ('<b>New game</b> — where the game starts when the player picks NEW GAME on the '
         'title screen, and how far the original game\'s own story counts as played. Gold, '
         'items and the party start empty, as in the game: give the first monster with a farm '
         'keeper (Rooms tab → the NPC → <i>Service…</i> → Farm keeper → <i>hands over the first '
         'monster</i>) or a <i>Give a monster</i> step.')
FACE_NAMES = [('down', 'down'), ('left', 'left'), ('up', 'up'), ('right', 'right')]
STORY_HELP = ('After the original opening = the point where the King sends the player to the '
              'Travelers\' Gates (measured in the game): the flags $0000-$0008 of the intro, the '
              'Castle, Pulio and the King, and the room states of the Castle, GreatTree, the Gate '
              'Hub and the Farm. Then the game\'s own rooms play their later scenes and the '
              'starter Slib is never given. Left as it is, the game\'s rooms wait at the very '
              'start: walking into the game\'s Castle plays the Minister, the King and his '
              'naming screen and gives Slib.')


class NewGameDialog(QDialog):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.rend = session.renderer
        self._building = True
        self.setWindowTitle('New game')
        ng = session.doc.new_game()
        lay = QVBoxLayout(self)
        intro = QLabel(INTRO)
        intro.setWordWrap(True)
        lay.addWidget(intro)
        grid = QGridLayout()
        lay.addLayout(grid)

        # ---- where it starts
        g = QGroupBox('Where the game starts')
        f = QFormLayout(g)
        self.r_intro = QRadioButton('the game\'s intro (the bedroom: Terry, Milayou, Warubou, '
                                    'the dresser)')
        self.r_room = QRadioButton('one of your rooms — no bedroom, no dresser')
        self.start_grp = QButtonGroup(self)
        self.start_grp.addButton(self.r_intro)
        self.start_grp.addButton(self.r_room)
        f.addRow(self.r_intro)
        self.intro_note = QLabel('')
        self.intro_note.setWordWrap(True)
        self.intro_note.setStyleSheet('color: #aaa;')
        f.addRow(self.intro_note)
        f.addRow(self.r_room)
        self.room = PlacePicker()
        self.screen = QComboBox()
        self.x = QSpinBox(); self.x.setRange(0, 9)
        self.y = QSpinBox(); self.y.setRange(0, 7)
        self.face = QComboBox()
        for text, data in FACE_NAMES:
            self.face.addItem(text, data)
        f.addRow('room', self.room)
        f.addRow('screen', self.screen)
        f.addRow('tile x', self.x)
        f.addRow('tile y', self.y)
        f.addRow('facing', self.face)
        self.prev = _Preview()
        f.addRow(self.prev)
        self.room_note = QLabel('')
        self.room_note.setWordWrap(True)
        self.room_note.setStyleSheet('color: #aaa;')
        f.addRow(self.room_note)
        grid.addWidget(g, 0, 0)

        # ---- the original game's story
        g = QGroupBox('The original game\'s story')
        f = QFormLayout(g)
        self.r_untouched = QRadioButton('as it is (the game\'s rooms wait at the very start)')
        self.r_done = QRadioButton('as after the original opening (the King has sent the '
                                   'player to the gates)')
        self.story_grp = QButtonGroup(self)
        self.story_grp.addButton(self.r_untouched)
        self.story_grp.addButton(self.r_done)
        f.addRow(self.r_untouched)
        f.addRow(self.r_done)
        hlp = QLabel(STORY_HELP)
        hlp.setWordWrap(True)
        hlp.setStyleSheet('color: #aaa;')
        f.addRow(hlp)
        self.problem = QLabel('')
        self.problem.setWordWrap(True)
        self.problem.setStyleSheet('color:#e0b040;')
        f.addRow(self.problem)
        grid.addWidget(g, 0, 1)

        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        lay.addWidget(bb)

        self.room.currentIndexChanged.connect(self._room_changed)
        self.screen.currentIndexChanged.connect(self._preview)
        for w in (self.x, self.y):
            w.valueChanged.connect(self._preview)
        for b in (self.r_intro, self.r_room, self.r_untouched, self.r_done):
            b.toggled.connect(self._enable)

        self._fill(ng)
        self._building = False
        self._room_changed()
        self._enable()

    # ------------------------------------------------------------ filling
    def _hook_on(self):
        return bool((self.s.doc.custom.get('milly_hook') or {}).get('enabled'))

    def _fill(self, ng):
        a = ng.get('at') or {}
        (self.r_room if ng.get('start') == 'room' else self.r_intro).setChecked(True)
        (self.r_done if ng.get('story') == 'opening_done' else self.r_untouched).setChecked(True)
        self.room.blockSignals(True)
        self.room.clear()
        from editor2.core import place_names as PN
        self.room.add_entries(PN.Places.of(self.s.doc).room_entries('id'))
        i = self.room.findData(a.get('room'))
        if i < 0:            # no start yet: the Milly hook's arrival room, else the first room
            arr = (self.s.doc.custom.get('milly_hook') or {}).get('arrive') or {}
            i = self.room.findData(arr.get('room'))
            if i >= 0 and not a:
                a = dict(arr)
        self.room.setCurrentIndex(max(0, i))
        self.room.blockSignals(False)
        self._want = a
        j = self.face.findData(a.get('face', 'down'))
        self.face.setCurrentIndex(max(0, j))
        hook = self._hook_on()
        arr = (self.s.doc.custom.get('milly_hook') or {}).get('arrive') or {}
        if hook:
            where = self.s.doc.room(arr['room']).get('name') if arr.get('room') else '?'
            self.intro_note.setText(f'The Milly hook is on: Warubou drags Milayou into the dresser '
                                    f'and the game goes on in {where} (Cutscenes → Milly hook…).')
            self.room_note.setText('The Milly hook is on: the player is MILLY from the first frame '
                                   'and arrives here as the hook says (spinning in, or simply '
                                   'there); the hook\'s own "Where Milly arrives" is not used.')
        else:
            self.intro_note.setText('Terry, Milayou and Warubou, then the dresser, the tree roots, '
                                    'the old man\'s walk and the Castle — the original game.')
            self.room_note.setText('Terry starts here (tick the Milly hook to play as Milly). The '
                                   'room\'s own entry scenes play at once.')

    def _room_changed(self, *_a):
        if self._building:
            return
        rid = self.room.currentData()
        self.screen.blockSignals(True)
        self.screen.clear()
        if rid is not None:
            r = self.s.doc.room(rid)
            for k in self.s.doc.screen_keys(r):
                self.screen.addItem(f'screen {k}  (col {k % 4}, row {k // 4})', k)
        want = getattr(self, '_want', None) or {}
        if want.get('room') == rid:
            i = self.screen.findData(int(want.get('screen', 0)))
            self.screen.setCurrentIndex(max(0, i))
            self.x.setValue(int(want.get('x', 4)))
            self.y.setValue(int(want.get('y', 4)))
        self.screen.blockSignals(False)
        self._preview()

    def _preview(self, *_a):
        if self._building:
            return
        rid, k = self.room.currentData(), self.screen.currentData()
        if rid is None or k is None:
            self.prev.set_image(None)
            return
        try:
            self.prev.set_image(self.rend.render_screen(self.s.doc.room(rid), k, 0, 1))
        except Exception:                                   # noqa: BLE001
            self.prev.set_image(None)
        self.prev.set_boxes([(self.x.value(), self.y.value(), QColor(120, 220, 255), 'S')])

    def _enable(self, *_a):
        room = self.r_room.isChecked()
        for w in (self.room, self.screen, self.x, self.y, self.face):
            w.setEnabled(room)
        msg = ''
        if self.r_intro.isChecked() and self.r_done.isChecked() and not self._hook_on():
            msg = ('With the game\'s own intro the original opening plays anyway — "as after the '
                   'opening" needs the Milly hook (it leaves the intro at the dresser) or a start '
                   'in one of your rooms.')
        elif room and self.room.currentData() is None:
            msg = 'Make a room first (Rooms tab).'
        self.problem.setText(msg)

    # ------------------------------------------------------------ actions
    def _ok(self):
        if self._apply():
            self.accept()

    def _apply(self):
        start = 'room' if self.r_room.isChecked() else 'intro'
        story = 'opening_done' if self.r_done.isChecked() else 'untouched'
        if start == 'intro' and story == 'opening_done' and not self._hook_on():
            QMessageBox.warning(self, 'New game', self.problem.text())
            return False
        at = None
        rid = self.room.currentData()
        if start == 'room':
            if rid is None or self.screen.currentData() is None:
                QMessageBox.warning(self, 'New game', 'Pick the room the game starts in.')
                return False
            at = {'room': rid, 'screen': self.screen.currentData(), 'x': self.x.value(),
                  'y': self.y.value(), 'face': self.face.currentData()}
        before = self.s.doc.new_game()
        want = dict(before, start=start, story=story)
        if at is not None:
            want['at'] = at
        if want == before:
            return True

        def op(doc):
            doc.set_new_game(start=start, at=at, story=story)
        cmd = C.SnapshotCommand(self.s, 'New game: ' + ('starts in a room' if start == 'room'
                                                         else 'the game\'s intro'), op)
        self.s.undo.push(cmd)
        if getattr(cmd, 'error', None) is not None:
            QMessageBox.warning(self, 'New game', str(cmd.error))
            return False
        problem = self.s.doc.new_game_problem()
        if problem:
            QMessageBox.information(self, 'New game', f'Saved — but the build will stop: {problem}.')
        return True
