"""gate_panel.py — the inspector's "Inside gates" group (S100, ROADMAP P3.7b part 1).

Everything a custom room needs to be served as a gate floor (Gates tab):
  * where it is served (the rules naming it; edited in the Gates tab);
  * the ARRIVAL cell — where the player appears (absolute pixels
    16*(col*10+x)+8 / 16*(row*8+y)+8, the special-room handler contract);
  * Stairs down (added from Selection → More ▾ → "Stairs down here") —
    the only way on to the next floor;
  * saving (vanilla: special rooms in gates allow it, boss rooms and the
    random floors do not — bank $07 SaveAllowCheck + CustomRoomFlags);
  * battles: off, or "follow the gate" (the dive's own monsters — a fixed
    pool would re-route the dive, so it is refused for gate rooms);
  * music: no song = the gate's music keeps playing (on the floor before
    the boss that is the boss theme, as on a vanilla floor), or a song.
"""

from PySide6.QtCore import Signal
from PySide6.QtWidgets import (QCheckBox, QComboBox, QFormLayout, QGroupBox, QHBoxLayout,
                               QLabel, QPushButton, QVBoxLayout)


def _lbl(t=''):
    lab = QLabel(t)
    lab.setWordWrap(True)
    return lab


class GateRoomGroup(QGroupBox):
    shownChanged = Signal(bool)        # S100 r3: its own section follows
    arrivalHereRequested = Signal()
    arrivalClearRequested = Signal()
    canSaveToggled = Signal(bool)
    encounterModeChosen = Signal(str)
    musicChosen = Signal(object)
    openGatesRequested = Signal()
    arrivalConversationRequested = Signal()     # S101: the room's entry conversation

    def __init__(self, parent=None):
        # S100 r3: shown in its own foldable Rooms-tab section (title there)
        super().__init__('', parent)
        self.setFlat(True)
        self._building = False
        v = QVBoxLayout(self)
        self.served = _lbl('')
        v.addWidget(self.served)
        f = QFormLayout()
        ar = QHBoxLayout()
        self.arrival = _lbl('')
        ar.addWidget(self.arrival, 1)
        self.btn_arr = QPushButton('Selected cell')
        self.btn_arr.setToolTip('The player appears on the selected cell when the room is '
                                'served on a gate floor (select a cell with V first).')
        self.btn_arr.clicked.connect(self.arrivalHereRequested.emit)
        ar.addWidget(self.btn_arr)
        self.btn_arr_clr = QPushButton('Clear')
        self.btn_arr_clr.clicked.connect(self.arrivalClearRequested.emit)
        ar.addWidget(self.btn_arr_clr)
        f.addRow('arrival', ar)
        self.stairs = _lbl('')
        f.addRow('stairs', self.stairs)
        self.can_save = QCheckBox('saving allowed here (JOURNAL)')
        self.can_save.setToolTip('Vanilla: you can save in the special rooms inside gates, '
                                 'not in boss rooms or on the random floors.')
        self.can_save.toggled.connect(self._save_toggled)
        f.addRow('save', self.can_save)
        self.enc = QComboBox()
        self.enc.addItem('off — no battles', 'off')
        self.enc.addItem("follow the gate — the dive's own monsters", 'follow')
        self.enc.addItem('fixed pool (not for gate rooms)', 'fixed')
        # S114 (P3.13a): a list of its own (chosen on the Encounters tab)
        self.enc.addItem('its own list — set on the Encounters tab', 'own')
        self.enc.currentIndexChanged.connect(self._enc_changed)
        f.addRow('battles', self.enc)
        self.music = QComboBox()
        self.music.setEditable(True)
        self.music.setToolTip('No song = inside a dive the gate\'s music keeps playing (on the '
                              'floor before the boss that is the boss theme, like a vanilla '
                              'floor). A project song id, or a vanilla BGM number like 0x09.')
        self.music.activated.connect(self._music_changed)
        self.music.lineEdit().editingFinished.connect(self._music_changed)
        f.addRow('music', self.music)
        v.addLayout(f)
        self.status = _lbl('')
        v.addWidget(self.status)
        self.boss = _lbl('')
        v.addWidget(self.boss)
        row = QHBoxLayout()
        self.btn_conv = QPushButton('Arrival conversation…')
        self.btn_conv.setToolTip('A conversation that runs when the player arrives on a screen '
                                 'of this room (the room\'s entry script) — e.g. a boss fight '
                                 'that starts on arrival. It runs on every arrival: guard it '
                                 'with an "If flags…" step.')
        self.btn_conv.clicked.connect(self.arrivalConversationRequested.emit)
        row.addWidget(self.btn_conv)
        b = QPushButton('Gates tab…')
        b.setToolTip('Choose the gates and floors that serve this room')
        b.clicked.connect(self.openGatesRequested.emit)
        row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)

    def setVisible(self, on):
        super().setVisible(on)
        self.shownChanged.emit(bool(on))

    def show_room(self, doc, room):
        self._building = True
        self.room = room
        rules = doc.rules_serving(room.get('id'))
        wid = doc.world_of_room(room.get('id'))          # S123 (ROADMAP NG3)
        if wid is not None:
            w = doc.world(wid) or {}
            st = w.get('start') or {}
            if st.get('room') == room.get('id'):
                where = (f"its START room: the portal lands the player on cell "
                         f"({st.get('x')},{st.get('y')}) of screen {st.get('screen', 0)}")
            else:
                where = 'reached by the world\'s doors'
            self.served.setText(f'In world {doc.world_name(wid)} — {where}. Battles, saving and '
                                'music are this room\'s own; edit the world on the World tab.')
            self.served.setStyleSheet('color:#7fd67f;')
        elif rules:
            from editor2.core import gates as G
            names = {g['id']: g['name'] for g in doc.all_gates()}      # S115: + new gates
            self.served.setText('Served in: ' + '; '.join(
                f"{names.get(int(G._val(r.get('gate', 0))), 'gate ' + str(r.get('gate')))} "
                f"{doc.describe_gate_rule(r)}" for _i, r in rules))
            self.served.setStyleSheet('color:#6ad8e6;')
        else:
            self.served.setText('Not served in any gate yet — add it in the Gates tab. '
                                'The settings below prepare it.')
            self.served.setStyleSheet('color:#aaa;')
        arr = room.get('gate_arrival')
        self.arrival.setText(f"cell ({arr['x']},{arr['y']}) on screen {arr.get('screen', 0)}"
                             if arr else 'not set')
        self.btn_arr_clr.setEnabled(bool(arr))
        rep = doc.gate_room_report(room)
        if wid is not None:
            self.stairs.setText('not needed in a world (its doors lead on)')
        else:
            self.stairs.setText(f"{rep['stairs']} Stairs down" if rep['stairs'] else
                                'none — select a cell, then Room / screen / selection → More ▾ → '
                                '"Stairs down here" (paints the next-floor well)')
        boss_of = doc.boss_gates_of(room.get('id'))
        self.can_save.setChecked(doc.room_can_save(room))
        if wid is not None and 'can_save' not in room:
            self.can_save.setToolTip('Follows the world\'s saving rule (World tab) until you '
                                     'change it here.')
        if boss_of:
            from editor2.core import gates as G
            names = {g['id']: g['name'] for g in doc.all_gates()}      # S115: + new gates
            self.boss.setText('Boss floor of: ' + ', '.join(names.get(g, f'gate {g}')
                                                            for g in boss_of)
                              + '. The fight is a conversation with a Battle step (an NPC '
                              'here, or the arrival conversation).')
            self.boss.setStyleSheet('color:#e6a0ff;')
        else:
            self.boss.setText('')
        ent = (room.get('scripts') or {}).get('0')
        has = ent is not None and doc.conversation(ent) is not None
        self.btn_conv.setText('Edit arrival conversation…' if has else 'Arrival conversation…')
        self.enc.setCurrentIndex(max(0, self.enc.findData(doc.encounter_mode(room))))
        self.music.clear()
        self.music.addItem("no song — the gate's music keeps playing", None)
        for s in (doc.custom.get('music') or {}).get('songs', []):
            self.music.addItem(f"{s['id']}  (project song)", s['id'])
        cur = room.get('music')
        if cur is not None and self.music.findData(cur) < 0:
            self.music.addItem(str(cur), cur)
        self.music.setCurrentIndex(max(0, self.music.findData(cur)))
        if wid is not None:
            self.status.setStyleSheet('color:#7fd67f;')
            self.status.setText('Part of a world — the World tab lists what the world still '
                                'needs.')
        elif rules or arr or boss_of:
            if rep['ready']:
                self.status.setStyleSheet('color:#7fd67f;')
                self.status.setText('Ready for gates.')
            else:
                self.status.setStyleSheet('color:#e0b040;')
                self.status.setText('Needs: ' + '; '.join(rep['problems']))
        else:
            self.status.setText('')
        self._building = False

    def _save_toggled(self, on):
        if not self._building:
            self.canSaveToggled.emit(on)

    def _enc_changed(self, _i):
        if not self._building:
            self.encounterModeChosen.emit(self.enc.currentData())

    def _music_changed(self, *_a):
        if self._building:
            return
        d = self.music.currentData()
        txt = self.music.currentText().strip()
        if d is None and txt and self.music.itemText(self.music.currentIndex()) != txt:
            d = txt.split()[0]
        self.musicChosen.emit(d)
