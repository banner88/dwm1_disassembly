"""object_panels.py — inspector forms for the non-NPC room objects (S98, P3.7).

  * DoorPanel     — a door object (S98 r2): name, connected door, where the
                    player arrives, states, edit / go / disconnect / delete.
  * TeleportPanel — a one-way exit row (authored teleports and cloned
                    vanilla exits): destination, states, delete.
  * SpotPanel     — an EXAMINE spot ($8x: answers an A press on / facing the
                    cell; facing filter) or a STEP-ON trigger ($90: runs when
                    the player walks onto the cell) — PyBoy-measured S98,
                    ROOM_DATA_FORMAT "Interact entries". Both run a talk
                    script (text, question, flags, move).
All three emit signals; the Rooms tab turns them into undoable Document ops.
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtWidgets import (QCheckBox, QComboBox, QFormLayout, QGroupBox,
                               QHBoxLayout, QLabel, QPushButton, QWidget)

from editor2.core.document import val


def _lbl(text=''):
    l = QLabel(text)
    l.setWordWrap(True)
    l.setTextInteractionFlags(Qt.TextSelectableByMouse)
    return l


class _StatesRow(QWidget):
    toggled = Signal(int, bool)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.lay = QHBoxLayout(self)
        self.lay.setContentsMargins(0, 0, 0, 0)

    def show_states(self, presence, tip):
        while self.lay.count():
            w = self.lay.takeAt(0).widget()
            if w:
                w.deleteLater()
        for n, on in enumerate(presence or []):
            cb = QCheckBox(str(n))
            cb.setChecked(on)
            cb.setToolTip(tip.format(n=n))
            cb.toggled.connect(lambda v, nn=n: self.toggled.emit(nn, bool(v)))
            self.lay.addWidget(cb)
        self.lay.addStretch(1)


def describe_end(doc, rend, end):
    if end is None:
        return '?'
    if end['kind'] == 'room':
        try:
            r = doc.room(end['room'])
            name = doc.room_name(r)
            mid = val(r['mapID'])
        except KeyError:
            return f"missing room {end['room']}"
        return f"${mid:02X} {name} — screen {end['screen']} cell ({end['x']},{end['y']})"
    try:
        name = rend.vanilla_name(end['mapID'])
    except Exception:
        name = ''
    return (f"vanilla ${end['mapID']:02X} {name} — screen {end['screen']} door "
            f"({end['x']},{end['y']})")


class DoorPanel(QGroupBox):
    """S98 r2: one door OBJECT — its name, what it is connected to, where
    the player arrives, the states that carry it."""
    editRequested = Signal()
    goRequested = Signal(object)            # the connected door (end dict)
    statesToggled = Signal(int, bool)
    disconnectRequested = Signal()
    deleteRequested = Signal()
    reaimRequested = Signal()

    def __init__(self, parent=None):
        super().__init__('Door', parent)
        f = QFormLayout(self)
        f.setLabelAlignment(Qt.AlignRight)
        self.form = f
        self.here = _lbl()
        self.there = _lbl()
        self.arrive_there = _lbl()
        self.arrive_here = _lbl()
        self.arrive_here.setStyleSheet('color:#80d080;')
        self.arrive_there.setStyleSheet('color:#80d080;')
        f.addRow('this door', self.here)
        f.addRow('connected to', self.there)
        f.addRow('arrive there', self.arrive_there)
        f.addRow('arrive here', self.arrive_here)
        self.states = _StatesRow()
        self.states.toggled.connect(self.statesToggled.emit)
        f.addRow('in states', self.states)
        self.btn_edit = QPushButton('Name / connect…  (double-click the door)')
        self.btn_edit.clicked.connect(self.editRequested.emit)
        f.addRow('', self.btn_edit)
        row = QHBoxLayout()
        self.btn_go = QPushButton('Go to connected door')
        self.btn_go.clicked.connect(lambda: self.goRequested.emit(self._other))
        row.addWidget(self.btn_go)
        self.btn_disc = QPushButton('Disconnect')
        self.btn_disc.clicked.connect(self.disconnectRequested.emit)
        row.addWidget(self.btn_disc)
        f.addRow('', row)
        row2 = QHBoxLayout()
        self.btn_reaim = QPushButton('Re-aim arrivals')
        self.btn_reaim.setToolTip('Recompute where the player appears on both sides (after '
                                  'repainting walls around a door)')
        self.btn_reaim.clicked.connect(self.reaimRequested.emit)
        row2.addWidget(self.btn_reaim)
        self.btn_del = QPushButton('Delete door')
        self.btn_del.setToolTip('Removes this door; the door it was connected to stays '
                                '(unconnected)')
        self.btn_del.clicked.connect(self.deleteRequested.emit)
        row2.addWidget(self.btn_del)
        f.addRow('', row2)
        self.note = _lbl()
        self.note.setStyleSheet('color:#e0b040;')
        f.addRow(self.note)
        self._other = None

    def show_door(self, doc, rend, me, other, presence, note=''):
        from editor2.app.rooms.door_dialog import arrival_text, end_place
        self.setTitle(f"Door '{me['name']}'")
        self._other = other
        self.here.setText(end_place(doc, me) + ('' if me['kind'] == 'vanilla'
                                                else '   — drag on the canvas to move'))
        if other is None:
            self.there.setText('<b>not connected</b> — double-click the door (or Name / '
                               'connect…) to pick the door it leads to')
        else:
            self.there.setText(f"'{other['name']}' — {end_place(doc, other)}")
        self.arrive_there.setText(arrival_text(doc, other) if other else '—')
        self.arrive_here.setText(arrival_text(doc, me) if other else '—')
        self.form.setRowVisible(self.arrive_there, other is not None)
        self.form.setRowVisible(self.arrive_here, other is not None)
        self.btn_go.setEnabled(other is not None)
        self.btn_disc.setEnabled(other is not None)
        self.btn_reaim.setEnabled(other is not None)
        if presence and len(presence) > 1:
            self.states.show_states(presence, 'door present in state {n} of this screen')
            self.form.setRowVisible(self.states, True)
        else:
            self.form.setRowVisible(self.states, False)
        self.note.setText(note)
        self.note.setVisible(bool(note))


class TeleportPanel(QGroupBox):
    statesToggled = Signal(int, bool)
    deleteRequested = Signal()
    goRequested = Signal(object)

    def __init__(self, parent=None):
        super().__init__('One-way exit / teleport', parent)
        f = QFormLayout(self)
        self.form = f
        self.info = _lbl()
        f.addRow('goes to', self.info)
        self.what = _lbl()
        self.what.setStyleSheet('color:#aaa;')
        f.addRow(self.what)
        self.states = _StatesRow()
        self.states.toggled.connect(self.statesToggled.emit)
        f.addRow('in states', self.states)
        self.note = _lbl()
        self.note.setStyleSheet('color:#e0b040;')
        f.addRow(self.note)
        row = QHBoxLayout()
        self.btn_go = QPushButton('Go to the destination')
        self.btn_go.clicked.connect(lambda: self.goRequested.emit(self._dest))
        row.addWidget(self.btn_go)
        self.btn_del = QPushButton('Delete')
        self.btn_del.clicked.connect(self.deleteRequested.emit)
        row.addWidget(self.btn_del)
        f.addRow('', row)
        self._dest = None

    def show_exit(self, doc, rend, row, presence, editable=True, note=''):
        dest = str(row.get('dest', ''))
        sb = val(row.get('screen_byte', 0))
        k = sb & 0x0F
        x, y = val(row.get('spawn_x', 0)), val(row.get('spawn_y', 0))
        self._dest = None
        try:
            mid = int(dest.split('$')[-1], 16)
            if dest.startswith('room:'):
                r = next(r for r in doc.rooms if val(r['mapID']) == mid)
                name = f"${mid:02X} {doc.room_name(r)}"
                self._dest = {'kind': 'room', 'room': r['id'], 'screen': k, 'x': x, 'y': y}
            else:
                name = f"vanilla ${mid:02X} {rend.vanilla_name(mid)}"
                self._dest = {'kind': 'vanilla', 'mapID': mid, 'screen': k, 'x': x, 'y': y}
        except Exception:
            name = dest
        nudge = ' (half a cell lower: screen byte bit 7)' if sb & 0x80 else ''
        self.info.setText(f'{name} — screen {k}, arrives at ({x},{y}){nudge}')
        self.what.setText('Stepping on this cell sends the player there. Nothing leads back '
                          '— use "Add door here…" for a two-way connection.')
        if presence and len(presence) > 1:
            self.states.show_states(presence, 'exit present in state {n} of this screen')
            self.form.setRowVisible(self.states, True)
        else:
            self.form.setRowVisible(self.states, False)
        self.btn_del.setEnabled(editable)
        self.states.setEnabled(editable)
        self.btn_go.setEnabled(self._dest is not None)
        self.note.setText(note)
        self.note.setVisible(bool(note))


class SpotPanel(QGroupBox):
    fieldsEdited = Signal(dict)
    newTalkRequested = Signal()
    editTalkRequested = Signal()
    presenceToggled = Signal(int, bool)
    deleteRequested = Signal()

    FACINGS = [('any', 'from any direction'), ('up', 'only when the player faces UP'),
               ('down', 'only when the player faces DOWN'),
               ('left', 'only when the player faces LEFT'),
               ('right', 'only when the player faces RIGHT')]

    def __init__(self, parent=None):
        super().__init__('Examine spot', parent)
        self._building = False
        f = QFormLayout(self)
        f.setLabelAlignment(Qt.AlignRight)
        self.form = f
        self.what = _lbl()
        self.what.setStyleSheet('color:#aaa;')
        f.addRow(self.what)
        self.pos = _lbl()
        f.addRow('cell', self.pos)
        self.facing = QComboBox()
        for key, text in self.FACINGS:
            self.facing.addItem(text, key)
        self.facing.currentIndexChanged.connect(
            lambda _i: self._emit('facing', self.facing.currentData()))
        f.addRow('answers A', self.facing)
        self.script = QComboBox()
        self.script.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.script.setMinimumContentsLength(14)
        self.script.currentIndexChanged.connect(
            lambda _i: self._emit('script', self.script.currentData()))
        f.addRow('script', self.script)
        row = QHBoxLayout()
        self.btn_new = QPushButton('New talk…')
        self.btn_new.clicked.connect(self.newTalkRequested.emit)
        self.btn_edit = QPushButton('Edit talk…')
        self.btn_edit.clicked.connect(self.editTalkRequested.emit)
        row.addWidget(self.btn_new)
        row.addWidget(self.btn_edit)
        f.addRow('', row)
        self.preview = _lbl()
        self.preview.setStyleSheet('color: #9fd0ff;')
        f.addRow('', self.preview)
        self.states = _StatesRow()
        self.states.toggled.connect(self.presenceToggled.emit)
        f.addRow('in states', self.states)
        self.note = _lbl()
        self.note.setStyleSheet('color:#e0b040;')
        f.addRow(self.note)
        self.btn_del = QPushButton('Delete')
        self.btn_del.clicked.connect(self.deleteRequested.emit)
        f.addRow('', self.btn_del)

    def show_spot(self, view, script_ids, talk, presence, editable=True):
        from editor2.app.rooms.npc_panel import talk_summary
        self._building = True
        kind = view['kind']
        if kind == 'step':
            self.setTitle('Step-on trigger')
            self.what.setText('Runs its script when the player WALKS onto this cell (not '
                              'when he arrives here through a door). Invisible.')
        else:
            self.setTitle('Examine spot' + (' (legacy "spawn" marker)' if kind == 'spawn' else ''))
            self.what.setText('Invisible: answers an A press while the player stands on the '
                              'cell or faces it — signs, bookshelves, searchable things.')
        self.pos.setText(f"({view['x']},{view['y']})   drag on the canvas to move")
        self.form.setRowVisible(self.facing, kind != 'step')
        fac = view.get('facing', 'any')
        self.facing.setCurrentIndex(max(0, self.facing.findData(fac)))
        self.script.clear()
        cur = view.get('script')
        for idx, sid in script_ids:
            self.script.addItem(f'[{idx}] {sid}' + ('  (room ENTRY script)' if idx == 0 else ''),
                                sid)
        if isinstance(cur, int):
            self.script.addItem(f'[{cur}] raw index (no id)', cur)
        k = self.script.findData(cur)
        self.script.setCurrentIndex(max(0, k))
        self.btn_edit.setEnabled(talk is not None and editable)
        self.preview.setText(talk_summary(talk, cur))
        if presence and len(presence) > 1:
            self.states.show_states(presence, 'present in state {n} of this screen')
            self.form.setRowVisible(self.states, True)
        else:
            self.form.setRowVisible(self.states, False)
        note = ''
        if kind == 'spawn' or (script_ids and cur == next((s for i, s in script_ids if i == 0),
                                                           object())):
            note = ('Runs the room ENTRY script (index 0) — this is the old "spawn point" '
                    'marker, which never chose where the player appears. Give it its own '
                    'talk or delete it.')
        self.note.setText(note)
        self.note.setVisible(bool(note))
        for w in (self.facing, self.script, self.btn_new, self.btn_del, self.states):
            w.setEnabled(editable)
        self._building = False

    def _emit(self, field, value):
        if not self._building:
            self.fieldsEdited.emit({field: value})
