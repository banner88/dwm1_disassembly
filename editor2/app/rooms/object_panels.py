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
  * StatuePanel   — a MEMORIAL STATUE (S154, editor2/core/memorial.py): which
                    statue it is (its fill order), its words, the memorial's
                    settings, its states.
  * HintObjectPanel — a breeding-hint MONUMENT (the families it teaches, skip owned,
                    what it shows) or ARCHIVE (its family) — S158, editor2/core/hints.py.
All of them emit signals; the Rooms tab turns them into undoable Document ops.
"""

from PySide6.QtCore import Qt, Signal
from PySide6.QtWidgets import (QCheckBox, QComboBox, QFormLayout, QGroupBox,
                               QHBoxLayout, QLabel, QPushButton, QWidget)

from editor2.core import place_names as PN
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
        except KeyError:
            return f"missing room {end['room']}"
        return (f"{PN.Places.of(doc).room_label(r)} — screen {end['screen']} "
                f"cell ({end['x']},{end['y']})")
    return (f"{PN.Places.of(doc).vanilla_label(end['mapID'])} — screen {end['screen']} door "
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
    lockRequested = Signal()                # S129: shut until conditions hold

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
        self.btn_lock = QPushButton('Lock until…')
        self.btn_lock.setToolTip('S129: the door stays shut (a wall you can examine — your '
                                 'words) until flags or story checks hold: a second room '
                                 'state of this screen, picked by a state rule')
        self.btn_lock.clicked.connect(self.lockRequested.emit)
        f.addRow('', self.btn_lock)
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
    lockRequested = Signal()                # S129

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
        self.btn_lock = QPushButton('Lock until…')
        self.btn_lock.setToolTip('S129: shut until flags or story checks hold (a second room '
                                 'state of this screen)')
        self.btn_lock.clicked.connect(self.lockRequested.emit)
        row.addWidget(self.btn_lock)
        f.addRow('', row)
        self._dest = None

    def show_exit(self, doc, rend, row, presence, editable=True, note=''):
        from editor2.core import gates as G
        if G.is_stairs_down(row):                  # S100 (P3.7b): gate rooms
            self.setTitle('Stairs down')
            self._dest = None
            self.info.setText('the next floor of the gate being dived')
            self.what.setText('Stepping on this cell takes the player down one floor — the '
                              "gate's maze, a special room, another custom room, or the boss. "
                              'It only works while this room is served inside a gate (Gates '
                              'tab); anywhere else it does nothing useful.')
            if presence and len(presence) > 1:
                self.states.show_states(presence, 'stairs present in state {n} of this screen')
                self.form.setRowVisible(self.states, True)
            else:
                self.form.setRowVisible(self.states, False)
            self.btn_del.setEnabled(editable)
            self.states.setEnabled(editable)
            self.btn_go.setEnabled(False)
            self.note.setText(note)
            self.note.setVisible(bool(note))
            return
        if G.is_gate_entrance(row):                # S115 (NG1): enters a gate
            gid = G.entrance_gate(row)
            self.setTitle('Gate entrance')
            self._dest = None
            try:
                name = doc.gate_name(gid)
            except Exception:
                name = '?'
            self.info.setText(f'gate {gid} — {name}, floor 1')
            self.what.setText('Stepping on this cell starts a dive into that gate (the vanilla '
                              'portal form). The gate\'s floors, boss and monsters are set on '
                              'the Gates and Encounters tabs.')
            if presence and len(presence) > 1:
                self.states.show_states(presence, 'entrance present in state {n} of this screen')
                self.form.setRowVisible(self.states, True)
            else:
                self.form.setRowVisible(self.states, False)
            self.btn_del.setEnabled(editable)
            self.states.setEnabled(editable)
            self.btn_go.setEnabled(False)
            self.note.setText(note)
            self.note.setVisible(bool(note))
            return
        self.setTitle('One-way exit / teleport')
        dest = str(row.get('dest', ''))
        sb = val(row.get('screen_byte', 0))
        k = sb & 0x0F
        x, y = val(row.get('spawn_x', 0)), val(row.get('spawn_y', 0))
        self._dest = None
        try:
            mid = int(dest.split('$')[-1], 16)
            if dest.startswith('room:'):
                r = next(r for r in doc.rooms if val(r['mapID']) == mid)
                name = PN.Places.of(doc).room_label(r)
                self._dest = {'kind': 'room', 'room': r['id'], 'screen': k, 'x': x, 'y': y}
            else:
                name = PN.Places.of(doc).vanilla_label(mid)
                self._dest = {'kind': 'vanilla', 'mapID': mid, 'screen': k, 'x': x, 'y': y}
        except Exception:
            name = PN.Places.of(doc).label(dest)
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


class StatuePanel(QGroupBox):
    """S154: a memorial statue (help 77_memorial.md)."""
    wordsRequested = Signal()
    settingsRequested = Signal()
    orderRequested = Signal(int)
    presenceToggled = Signal(int, bool)
    deleteRequested = Signal()

    def __init__(self, parent=None):
        super().__init__('Memorial statue', parent)
        f = QFormLayout(self)
        f.setLabelAlignment(Qt.AlignRight)
        self.form = f
        self.what = _lbl('Shows a monster that won a boss battle, an arena class or Starry '
                         'Night with the player and has LEFT since (bred, released, traded). '
                         'Every statue of the room shows a different one, picked again each '
                         'time the player comes in. Two cells: the pedestal here (the room\'s '
                         '"Pedestal" metatile — redraw it in the Draw tab) and the monster '
                         'above it, drawn grey over the floor that was there. Examining the '
                         'pedestal says its words.')
        self.what.setStyleSheet('color:#aaa;')
        f.addRow(self.what)
        self.pos = _lbl()
        f.addRow('cell', self.pos)
        self.order = _lbl()
        row = QHBoxLayout()
        row.addWidget(self.order, 1)
        self.btn_up = QPushButton('Earlier')
        self.btn_up.setToolTip('This statue gets a monster sooner (when fewer monsters than '
                               'statues have left)')
        self.btn_up.clicked.connect(lambda: self.orderRequested.emit(-1))
        self.btn_down = QPushButton('Later')
        self.btn_down.clicked.connect(lambda: self.orderRequested.emit(1))
        row.addWidget(self.btn_up)
        row.addWidget(self.btn_down)
        f.addRow('fills', row)
        self.tiles = _lbl()
        self.tiles.setStyleSheet('color:#9fd0ff;')
        f.addRow('its tiles', self.tiles)
        self.words = _lbl()
        self.words.setStyleSheet('color:#9fd0ff;')
        f.addRow('says', self.words)
        row2 = QHBoxLayout()
        self.btn_words = QPushButton('Its words…')
        self.btn_words.clicked.connect(self.wordsRequested.emit)
        self.btn_settings = QPushButton('Memorial settings…')
        self.btn_settings.setToolTip('How many monsters the memorial remembers and the words '
                                     'every statue says (unless it has its own)')
        self.btn_settings.clicked.connect(self.settingsRequested.emit)
        row2.addWidget(self.btn_words)
        row2.addWidget(self.btn_settings)
        f.addRow('', row2)
        self.states = _StatesRow()
        self.states.toggled.connect(self.presenceToggled.emit)
        f.addRow('in states', self.states)
        self.btn_del = QPushButton('Remove from this state')
        self.btn_del.clicked.connect(self.deleteRequested.emit)
        f.addRow('', self.btn_del)

    def show_statue(self, view, number, count, tiles, words, presence, editable=True,
                    look=''):
        self.pos.setText(f"pedestal ({view['x']},{view['y']}) — an examine spot; the monster "
                         f"on ({view['x']},{view['y'] - 1})")
        self.order.setText(f'statue {number} of {count} in this room'
                           + (' (gets a monster first)' if number == 1 else ''))
        self.tiles.setText('the monster cell ' + ', '.join(f'${t:02X}' for t in tiles)
                           + ' — no other picture may use them' + (f'; {look}' if look else ''))
        first = ' / '.join(' '.join(b) for b in (words.get('text') or [])[:2])
        self.words.setText(('its own words: ' if words.get('own') else '') + first)
        if presence and len(presence) > 1:
            self.states.show_states(presence, 'standing in state {n} of this screen')
            self.form.setRowVisible(self.states, True)
        else:
            self.form.setRowVisible(self.states, False)
        for w in (self.btn_up, self.btn_down, self.btn_words, self.btn_settings, self.btn_del,
                  self.states):
            w.setEnabled(editable)
        self.btn_up.setEnabled(editable and number > 1)
        self.btn_down.setEnabled(editable and number < count)


class HintObjectPanel(QGroupBox):
    """S158: a breeding-hint MONUMENT or ARCHIVE (editor2/core/hints.py, help 78_hints.md)."""
    fieldsEdited = Signal(dict)          # monument: families / skip_owned / show; archive: family
    wordsRequested = Signal()
    settingsRequested = Signal()
    presenceToggled = Signal(int, bool)
    deleteRequested = Signal()

    SHOW_LABELS = (('explicit', 'the cross (names)'), ('riddle', 'the riddle (else the cross)'),
                   ('both', 'the riddle, then the cross'))

    def __init__(self, parent=None):
        super().__init__('Hint monument', parent)
        from editor2.core import hints as HT
        self.HT = HT
        f = QFormLayout(self)
        f.setLabelAlignment(Qt.AlignRight)
        self.form = f
        self.what = _lbl()
        self.what.setStyleSheet('color:#aaa;')
        f.addRow(self.what)
        self.pos = _lbl()
        f.addRow('cell', self.pos)
        # monument
        fam = QWidget()
        from PySide6.QtWidgets import QGridLayout
        g = QGridLayout(fam)
        g.setContentsMargins(0, 0, 0, 0)
        self.fam_all = QCheckBox('every family')
        self.fam_all.toggled.connect(self._fam_all)
        g.addWidget(self.fam_all, 0, 0, 1, 3)
        self.fam_cb = []
        for i, name in enumerate(HT.FAMILIES):
            cb = QCheckBox(name)
            cb.toggled.connect(lambda _v: self._emit_mon())
            g.addWidget(cb, 1 + i // 3, i % 3)
            self.fam_cb.append(cb)
        self.fam_row = fam
        f.addRow('teaches', fam)
        self.skip = QCheckBox('skip children the player has owned')
        self.skip.toggled.connect(lambda _v: self._emit_mon())
        f.addRow('', self.skip)
        self.show_box = QComboBox()
        for _k, lab in self.SHOW_LABELS:
            self.show_box.addItem(lab)
        self.show_box.currentIndexChanged.connect(lambda _i: self._emit_mon())
        f.addRow('shows', self.show_box)
        # archive
        self.family = QComboBox()
        for name in HT.FAMILIES:
            self.family.addItem(name)
        self.family.currentIndexChanged.connect(
            lambda i: (not self._loading) and self.fieldsEdited.emit({'family': HT.FAMILIES[i]}))
        f.addRow('family', self.family)
        self.words = _lbl()
        self.words.setStyleSheet('color:#9fd0ff;')
        f.addRow('says', self.words)
        row = QHBoxLayout()
        self.btn_words = QPushButton('Its words…')
        self.btn_words.clicked.connect(self.wordsRequested.emit)
        self.btn_settings = QPushButton('Hint pool…')
        self.btn_settings.setToolTip('The Breeding tab\'s Hints page: which crosses are hints, '
                                     'riddles, the words every monument / archive says')
        self.btn_settings.clicked.connect(self.settingsRequested.emit)
        row.addWidget(self.btn_words)
        row.addWidget(self.btn_settings)
        f.addRow('', row)
        self.states = _StatesRow()
        self.states.toggled.connect(self.presenceToggled.emit)
        f.addRow('in states', self.states)
        self.btn_del = QPushButton('Remove from this state')
        self.btn_del.clicked.connect(self.deleteRequested.emit)
        f.addRow('', self.btn_del)
        self._loading = False
        self.kind = 'monument'

    def _fam_all(self, on):
        for cb in self.fam_cb:
            cb.setEnabled(not on)
        self._emit_mon()

    def _emit_mon(self):
        if self._loading or self.kind != 'monument':
            return
        fams = None if self.fam_all.isChecked() else \
            [n for n, cb in zip(self.HT.FAMILIES, self.fam_cb) if cb.isChecked()]
        if fams == []:
            return                                      # pick at least one (or every family)
        self.fieldsEdited.emit({'families': fams, 'skip_owned': self.skip.isChecked(),
                                'show': self.SHOW_LABELS[self.show_box.currentIndex()][0]})

    def show_object(self, kind, view, obj, words, presence, editable=True):
        """kind 'monument' / 'archive', obj = its record, words = {role: (boxes, own)}."""
        self._loading = True
        self.kind = kind
        mon = kind == 'monument'
        self.setTitle('Hint monument' if mon else f"Hint archive — {obj.get('family')}")
        self.what.setText(
            'An examine spot (put it on your own art — a stone, a pillar). Read, it teaches '
            'a breeding cross the player has not found yet (random among the hint pool\'s '
            'crosses of the families below) and unlocks it at once; read again in the same '
            'visit it repeats it; the next visit teaches another. None left: its worn-away '
            'words.' if mon else
            'An examine spot (put it on your own art — a bookcase with the family\'s '
            'emblem). It asks to be read, then lists the family\'s crosses the player has '
            'unlocked (at monuments, or by breeding them), "(bred)" on the ones made, '
            '"Keep reading?" after each.')
        self.pos.setText(f"({view['x']},{view['y']}) — '{obj.get('id')}'")
        for w in (self.fam_row, self.skip, self.show_box):
            self.form.setRowVisible(w, mon)
        self.form.setRowVisible(self.family, not mon)
        if mon:
            fams = obj.get('families')
            self.fam_all.setChecked(not fams)
            for n, cb in zip(self.HT.FAMILIES, self.fam_cb):
                cb.setChecked(bool(fams) and n in fams)
                cb.setEnabled(bool(fams) and editable)
            self.skip.setChecked(obj.get('skip_owned', True))
            keys = [k for k, _l in self.SHOW_LABELS]
            self.show_box.setCurrentIndex(keys.index(obj.get('show', 'explicit')))
        else:
            fi = self.HT.family_index(obj.get('family')) or 0
            self.family.setCurrentIndex(fi)
        main = words.get('text' if mon else 'ask') or (None, False)
        first = ' / '.join(' '.join(b) for b in (main[0] or [])[:2])
        own = [r for r, (_b, o) in words.items() if o]
        self.words.setText(first + (f"  (own: {', '.join(own)})" if own else ''))
        if presence and len(presence) > 1:
            self.states.show_states(presence, 'standing in state {n} of this screen')
            self.form.setRowVisible(self.states, True)
        else:
            self.form.setRowVisible(self.states, False)
        for w in (self.fam_all, self.skip, self.show_box, self.family, self.btn_words,
                  self.btn_del, self.states):
            w.setEnabled(editable)
        self._loading = False
