"""milly_dialog.py — the Milly hook (S121, ROADMAP P3.16 + E7; model:
editor2/core/milly_doc.py, compiler: editor2/core/milly.py, PROJECT_COMPILER §2.34).

One tick turns the hook on: in the intro, when Warubou drags Milayou into the
dresser, the screen whirls as when Terry steps into it, and the game goes on in
the room picked here — with MILLY as the player for the rest of the game (her own
sprite, the default name MILLY). Off = the game as before (Terry).

Left: the tick, where she arrives (one of your rooms, screen, tile, facing,
spinning in or not) on a picture of that screen. Right: the "Roots room (Milly)"
— a copy of the tree-root chamber where Terry spins in, with grey Warubou
instead of the old man; Create makes it, and where Warubou leads her is the
last step of its scene (Edit the scene… opens it in the cutscene editor: his
lines, the walks …). S121 r3: "Warubou asks her name" puts the game's naming
screen between his lines (a text box before, one after).

OK applies everything as one undo step.
"""

from PySide6.QtGui import QColor
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox,
                               QFormLayout, QGridLayout, QGroupBox, QHBoxLayout,
                               QLabel, QMessageBox, QPushButton, QSpinBox,
                               QVBoxLayout)

from editor2.app.rooms import commands as C
from editor2.app.rooms.redirect_dialog import _Preview
from editor2.app.session import REPO
from editor2.core import milly as MH

INTRO = ('<b>The Milly hook</b> — in the intro, when Warubou drags Milayou into the dresser, '
         'the screen whirls (as when Terry steps into it) and the game goes on in the room '
         'you pick here. From then on the player is <b>MILLY</b>: her own sprite in every '
         'room, the default name MILLY. The bedroom scene stops at the dresser\'s glow '
         '(no Terry, no Watabou). Untick to get the game back as it was.')
FACE_NAMES = [('down', 'down'), ('left', 'left'), ('up', 'up'), ('right', 'right')]


class MillyHookDialog(QDialog):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.rend = session.renderer
        self.edit_scene = None          # (room id, scene id) after "Edit the scene…"
        self._building = True
        self.setWindowTitle('Milly hook')
        h = session.doc.milly_hook()
        lay = QVBoxLayout(self)
        intro = QLabel(INTRO)
        intro.setWordWrap(True)
        lay.addWidget(intro)
        self.on = QCheckBox('Apply the Milly patch (the Milly hook)')
        self.on.setChecked(bool(h.get('enabled')))
        lay.addWidget(self.on)
        grid = QGridLayout()
        lay.addLayout(grid)

        # ---- arrival
        g = QGroupBox('Where Milly arrives')
        f = QFormLayout(g)
        self.room = QComboBox()
        self.screen = QComboBox()
        self.x = QSpinBox(); self.x.setRange(0, 9)
        self.y = QSpinBox(); self.y.setRange(0, 7)
        self.face = QComboBox()
        for text, data in FACE_NAMES:
            self.face.addItem(text, data)
        self.spin = QCheckBox('arrive spinning (as Terry does in the roots room)')
        f.addRow('room', self.room)
        f.addRow('screen', self.screen)
        f.addRow('tile x', self.x)
        f.addRow('tile y', self.y)
        f.addRow('facing', self.face)
        f.addRow(self.spin)
        self.prev = _Preview()
        f.addRow(self.prev)
        self.problem = QLabel('')
        self.problem.setWordWrap(True)
        self.problem.setStyleSheet('color:#e0b040;')
        f.addRow(self.problem)
        grid.addWidget(g, 0, 0)

        # ---- the roots room
        g = QGroupBox('Roots room (Milly)')
        f = QFormLayout(g)
        about = QLabel('A copy of the tree-root chamber where Terry spins in after his dresser '
                       '— grey Warubou walks up instead of the old man, talks, and she follows '
                       'him out. It is an ordinary room of yours: its scene can be edited like '
                       'any cutscene.')
        about.setWordWrap(True)
        f.addRow(about)
        row = QHBoxLayout()
        self.b_create = QPushButton('Create the roots room')
        self.b_create.setToolTip('Copies the game\'s room $08 into your project as "Roots '
                                 'room (Milly)" with Warubou and his scene (one undo step). '
                                 'When no arrival is set yet, Milly arrives there.')
        self.b_create.clicked.connect(self._create_roots)
        row.addWidget(self.b_create)
        self.b_edit = QPushButton('Edit the scene…')
        self.b_edit.setToolTip('Opens the roots room\'s scene in the cutscene editor '
                               '(Warubou\'s text boxes, the walks; add "Name the hero" there)')
        self.b_edit.clicked.connect(self._edit_scene)
        row.addWidget(self.b_edit)
        f.addRow(row)
        self.roots = QComboBox()
        f.addRow('roots room', self.roots)
        self.naming = QCheckBox('Warubou asks her name (the naming screen between his lines)')
        self.naming.setToolTip('His text box(es), then the game\'s naming screen (it offers '
                               'MILLY), then another text box — all editable in Edit the '
                               'scene…. Unticking removes the naming screen and the box '
                               'right after it.')
        f.addRow(self.naming)
        self.dest = QComboBox()
        self.d_screen = QComboBox()
        self.d_x = QSpinBox(); self.d_x.setRange(0, 9)
        self.d_y = QSpinBox(); self.d_y.setRange(0, 7)
        f.addRow('Warubou leads her to', self.dest)
        f.addRow('screen', self.d_screen)
        f.addRow('tile x', self.d_x)
        f.addRow('tile y', self.d_y)
        self.d_note = QLabel('')
        self.d_note.setWordWrap(True)
        f.addRow(self.d_note)
        grid.addWidget(g, 0, 1)

        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        lay.addWidget(bb)

        self.room.currentIndexChanged.connect(self._room_changed)
        self.screen.currentIndexChanged.connect(self._preview)
        for w in (self.x, self.y):
            w.valueChanged.connect(self._preview)
        self.on.toggled.connect(self._enable)
        self.roots.currentIndexChanged.connect(self._roots_changed)
        self.dest.currentIndexChanged.connect(self._dest_changed)

        self._fill(h)
        self._building = False
        self._room_changed()
        self._roots_changed()
        self._enable()

    # ------------------------------------------------------------ filling
    def _rooms(self):
        return [r for r in self.s.doc.rooms if not r.get('placeholder')]

    def _fill(self, h):
        a = h.get('arrive') or {}
        self.room.blockSignals(True)
        self.room.clear()
        for r in self._rooms():
            self.room.addItem(self.s.doc.room_name(r), r['id'])
        i = self.room.findData(a.get('room'))
        self.room.setCurrentIndex(max(0, i))
        self.room.blockSignals(False)
        self._want = a
        self.spin.setChecked(bool(h.get('spin', True)))
        j = self.face.findData(a.get('face', 'down'))
        self.face.setCurrentIndex(max(0, j))
        self._fill_roots()

    def _roots_rooms(self):
        out = []
        for r in self._rooms():
            for sc in r.get('cutscenes') or []:
                if sc.get('id') == MH.ROOTS_SCENE:
                    out.append(r)
                    break
        return out

    def _fill_roots(self):
        keep = self.roots.currentData()
        self.roots.blockSignals(True)
        self.roots.clear()
        for r in self._roots_rooms():
            self.roots.addItem(self.s.doc.room_name(r), r['id'])
        i = self.roots.findData(keep)
        self.roots.setCurrentIndex(max(0, i))
        self.roots.blockSignals(False)
        from editor2.app.cutscene_editor import room_items
        self.dest.blockSignals(True)
        self.dest.clear()
        for text, data in room_items(self.s):
            self.dest.addItem(text, data)
        self.dest.blockSignals(False)

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
            self.problem.setText('Make a room first (Rooms tab), or Create the roots room.')
            return
        try:
            self.prev.set_image(self.rend.render_screen(self.s.doc.room(rid), k, 0, 1))
        except Exception:                                   # noqa: BLE001
            self.prev.set_image(None)
        self.prev.set_boxes([(self.x.value(), self.y.value(), QColor(255, 120, 200), 'M')])
        self.problem.setText('')

    def _roots_changed(self, *_a):
        if self._building:
            return
        rid = self.roots.currentData()
        have = rid is not None
        for w in (self.dest, self.d_screen, self.d_x, self.d_y, self.b_edit, self.naming):
            w.setEnabled(have)
        self.naming.setChecked(bool(have and self.s.doc.roots_naming(rid)))
        self.b_create.setEnabled(not self._roots_rooms())
        if not have:
            self.d_note.setText('No roots room yet — Create makes one.')
            return
        d = self.s.doc.roots_scene_destination(rid)
        if d is None:
            self.d_note.setText('Its scene has no "Go to a room" step any more — the scene '
                                'ends in the roots room. Add one in the cutscene editor.')
            for w in (self.dest, self.d_screen, self.d_x, self.d_y):
                w.setEnabled(False)
            return
        self.d_note.setText('The last step of its scene ("Go to a room").')
        i = self.dest.findData(d.get('dest'))
        if i < 0:
            self.dest.addItem(str(d.get('dest')), d.get('dest'))
            i = self.dest.count() - 1
        self.dest.blockSignals(True)
        self.dest.setCurrentIndex(i)
        self.dest.blockSignals(False)
        self._fill_dest_screens(int(d.get('screen', 0)))
        self.d_x.setValue(int(d.get('x', 4)))
        self.d_y.setValue(int(d.get('y', 4)))

    def _fill_dest_screens(self, want=None):
        """S121 r3 (user: "I tried redirecting to SBOSS and game crashes"): only the
        screens the destination room HAS — GreatTree's screen 12 kept for SBOSS
        (screens 0 / 4) warped into nothing and crashed the game."""
        from editor2.app.cutscene_editor import dest_screens, screen_label
        scr = dest_screens(self.s, self.dest.currentData()) or list(range(16))
        if want is None:
            want = self.d_screen.currentData()
        self.d_screen.clear()
        for k in scr:
            self.d_screen.addItem(screen_label(k), k)
        j = self.d_screen.findData(want)
        self.d_screen.setCurrentIndex(max(0, j))

    def _dest_changed(self, *_a):
        if self._building:
            return
        self._fill_dest_screens()

    def _enable(self, *_a):
        on = self.on.isChecked()
        for w in (self.room, self.screen, self.x, self.y, self.face, self.spin):
            w.setEnabled(on)

    # ------------------------------------------------------------ actions
    def _create_roots(self):
        rend = self.rend
        cmd = C.SnapshotCommand(self.s, 'Create the roots room (Milly)',
                                lambda doc: doc.create_roots_room(REPO, rend))
        self.s.undo.push(cmd)
        if getattr(cmd, 'error', None) is not None:
            QMessageBox.warning(self, 'Milly hook', str(cmd.error))
            return
        rid = cmd.result
        self._building = True
        self._fill(self.s.doc.milly_hook())
        i = self.roots.findData(rid)
        self.roots.setCurrentIndex(max(0, i))
        self._building = False
        self._room_changed()
        self._roots_changed()

    def _edit_scene(self):
        rid = self.roots.currentData()
        if rid is None:
            return
        if not self._apply():
            return
        self.edit_scene = (rid, MH.ROOTS_SCENE)
        self.accept()

    def _ok(self):
        if self._apply():
            self.accept()

    def _apply(self):
        on = self.on.isChecked()
        rid = self.room.currentData()
        if on and rid is None:
            QMessageBox.warning(self, 'Milly hook', 'Pick the room where Milly arrives '
                                '(or Create the roots room).')
            return False
        arrive = None
        if rid is not None and self.screen.currentData() is not None:
            arrive = {'room': rid, 'screen': self.screen.currentData(),
                      'x': self.x.value(), 'y': self.y.value(),
                      'face': self.face.currentData()}
        spin = self.spin.isChecked()
        roots = self.roots.currentData() if self.dest.isEnabled() else None
        dest = None
        if roots is not None:
            dest = {'dest': self.dest.currentData(), 'screen': self.d_screen.currentData(),
                    'x': self.d_x.value(), 'y': self.d_y.value()}
        rroom = self.roots.currentData()
        naming = self.naming.isChecked() if rroom is not None else None
        same_naming = rroom is None or self.s.doc.roots_naming(rroom) == naming
        before = self.s.doc.milly_hook()
        same_dest = roots is None or self.s.doc.roots_scene_destination(roots) == dest
        want = dict(before)
        want.update({'enabled': on, 'spin': spin})
        if arrive is not None:
            want['arrive'] = arrive
        if want == before and same_dest and same_naming:
            return True

        def op(doc):
            doc.set_milly_hook(enabled=on, arrive=arrive, spin=spin)
            if roots is not None:
                doc.set_roots_scene_destination(roots, dest)
            if rroom is not None and not same_naming:
                doc.set_roots_naming(rroom, naming)
        cmd = C.SnapshotCommand(self.s, 'Milly hook ' + ('on' if on else 'off'), op)
        self.s.undo.push(cmd)
        if getattr(cmd, 'error', None) is not None:
            QMessageBox.warning(self, 'Milly hook', str(cmd.error))
            return False
        problem = self.s.doc.milly_arrival_problem()
        if problem:
            QMessageBox.information(self, 'Milly hook', f'Saved — but the build will stop: '
                                    f'{problem}.')
        return True
