"""service_dialog.py — make an NPC a service NPC (ROADMAP P3.14e1, S126; model:
editor2/core/services_doc.py, compiler: editor2/core/services.py).

S127 (ROADMAP P3.14e2): Grandpa (breeds two of your monsters, hatches eggs) and a
Breeder (offers ONE of their own monsters as the mate — a fixed one, or one rolled
from a breeding pool each time the room appears; model editor2/core/breeders_doc.py,
compiler editor2/core/breeders.py).

The NPC becomes the Vault keeper, a farm keeper, the librarian, the Monster
Namer, the Medal Man, the egg appraiser or the gate guide — the game's own
menu, which works in any room (one Vault / farm / medal count for the whole
game). Optional: its own menu lines (a line set, edited on the Services tab)
and what it says on the first visit (remembered by a flag).
"""

from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox, QFormLayout,
                               QGroupBox, QHBoxLayout, QInputDialog, QLabel, QLineEdit,
                               QListWidget, QListWidgetItem, QMessageBox, QRadioButton,
                               QScrollArea, QSpinBox, QTabWidget, QVBoxLayout, QWidget)

from editor2.app.rooms.talk_editor import GameTextField

NEW_SET = '__new__'


class ServiceDialog(QDialog):
    """cur = Document.service_of(...) or None. result(): (kind, lines, first_time)."""

    def __init__(self, doc, cur=None, parent=None):
        super().__init__(parent)
        self.doc = doc
        self.setWindowTitle('Service NPC')
        self.resize(820, 820)
        self.rom = doc._rom_bytes()
        outer = QVBoxLayout(self)
        sa = QScrollArea()                   # S127 r3: the text fields show the game's boxes
        sa.setWidgetResizable(True)
        inner = QWidget()
        v = QVBoxLayout(inner)
        sa.setWidget(inner)
        outer.addWidget(sa, 1)
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
        self.kinds.setMaximumHeight(190)
        v.addWidget(self.kinds)
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
        self.first_text = GameTextField(self.rom, empty_note='what it says the first time, '
                                        'instead of its greeting — type it box by box')
        f.addRow('', self.first_text)
        self.flag = QLineEdit()
        self.flag.setToolTip('The flag that remembers the first visit (created when new; it is '
                             'listed on the Progression & Flags tab)')
        self.flag_label = QLabel('remembered by flag')
        f.addRow(self.flag_label, self.flag)
        v.addLayout(f)
        v.addWidget(self._breeder_box())
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        outer.addWidget(bb)
        self._cur = cur or {}
        row = 0
        for i in range(self.kinds.count()):
            if self.kinds.item(i).data(256) == self._cur.get('kind'):
                row = i
        self.kinds.setCurrentRow(row)
        ft = self._cur.get('first_time')
        self.first.setChecked(bool(ft))
        if ft:
            self.first_text.set_value(ft.get('boxes'))
            self.flag.setText(ft.get('flag') or '')
        self._first_toggled(bool(ft))
        self._fill_breeder(self._cur.get('breeder') or {})
        self._kind_changed(self.kinds.currentRow())

    # ------------------------------------------------------------ S127 breeder
    def _breeder_box(self):
        self.brd = QGroupBox('Breeder — the monster they offer, and when')
        g = QFormLayout(self.brd)
        # S127 r2 (user: "can I not make a monster with a specific level, why is it a
        # random selection?"): a species at a level first; the enemy rows as they are
        # (each species at the level the game gave it) second
        self.brd_level_rb = QRadioButton('a monster at a level you choose')
        self.brd_fixed = QRadioButton('an enemy row as it is (your enemies, or the game\'s rows '
                                      '— each a species at the level the game gave it)')
        self.brd_pool = QRadioButton('rolled from a breeding pool each time the room appears '
                                     '(once per appearance)')
        self.brd_species = QComboBox()
        for sid, name in self.doc.mate_species():
            self.brd_species.addItem(f'{name} (#{sid})', sid)
        self.brd_level = QSpinBox()
        self.brd_level.setRange(1, 99)
        self.brd_level.setValue(10)
        self.brd_level.setPrefix('level ')
        lw = QWidget()
        lh = QHBoxLayout(lw)
        lh.setContentsMargins(0, 0, 0, 0)
        lh.addWidget(self.brd_species, 1)
        lh.addWidget(self.brd_level)
        lw.setToolTip('The mate is made for you as one of your enemies (Monsters → enemies): '
                      'the species\' own row nearest that level, its stats grown with the '
                      'species\' growth curves. Its level and stats count — the egg\'s "+" and '
                      'stats come from both parents.')
        self.brd_mate = QComboBox()
        self.brd_mate.setEditable(False)
        for eid, label in self.doc.mate_rows():
            self.brd_mate.addItem(label, eid)
        self.brd_pools = QComboBox()
        for p in self.doc.breeding_pools_doc():
            self.brd_pools.addItem(p['name'], p['id'])
        if not self.brd_pools.count():
            self.brd_pools.addItem('(no pools yet — Services tab → Breeding pools → New)', None)
        g.addRow(self.brd_level_rb)
        g.addRow('', lw)
        g.addRow(self.brd_fixed)
        g.addRow('', self.brd_mate)
        g.addRow(self.brd_pool)
        g.addRow('', self.brd_pools)
        self.brd_texts = QTabWidget()
        self.brd_intro = GameTextField(self.rom, empty_note='nothing first — they ask "Why '
                                       'not breed with my …?" (the monster\'s name) at once')
        self.brd_texts.addTab(self.brd_intro, 'first words')
        self.brd_when = QLineEdit()
        self.brd_when.setPlaceholderText('flag names, comma separated; !name = must be OFF '
                                         '(empty = always)')
        self.brd_when.setToolTip('They offer only while all these flags hold (e.g. after a '
                                 'boss: beat_boss2). Otherwise they say the words below.')
        g.addRow('offers only when', self.brd_when)
        self.brd_notyet = GameTextField(self.rom, empty_note="when it is not time yet: the "
                                        "game's \"Come to me when you want to breed…\"")
        self.brd_texts.addTab(self.brd_notyet, 'not yet')
        self.brd_flag = QLineEdit()
        self.brd_flag.setPlaceholderText('optional: a flag turned ON when a breeding is done')
        g.addRow('done flag', self.brd_flag)
        self.brd_once = QCheckBox('only once: with the done flag ON they say the words below')
        g.addRow('', self.brd_once)
        self.brd_after = GameTextField(self.rom, empty_note="afterwards (once — or, for a "
                                       "pool, for the rest of this appearance): the game's "
                                       "\"Come to me…\"")
        self.brd_texts.addTab(self.brd_after, 'afterwards')
        g.addRow(QLabel('What they say — each box as the game shows it:'))
        g.addRow(self.brd_texts)
        return self.brd

    def _fill_breeder(self, b):
        pool = b.get('pool')
        made = self.doc.mate_info(b.get('mate')) if b.get('mate') is not None else None
        if pool:
            self.brd_pool.setChecked(True)
        elif b.get('mate') is not None and made is None:
            self.brd_fixed.setChecked(True)
        else:
            self.brd_level_rb.setChecked(True)
        sp, lv = made or (47, 10)                                   # CatFly, level 10
        self.brd_species.setCurrentIndex(max(0, self.brd_species.findData(sp)))
        self.brd_level.setValue(lv)
        if b.get('mate') is not None:
            i = self.brd_mate.findData(self.doc._medal_eid(b['mate']))
            self.brd_mate.setCurrentIndex(max(0, i))
        else:
            self.brd_mate.setCurrentIndex(max(0, self.brd_mate.findData(306)))   # CatFly
        if pool:
            self.brd_pools.setCurrentIndex(max(0, self.brd_pools.findData(pool)))
        self.brd_intro.set_value(b.get('intro'))
        self.brd_notyet.set_value(b.get('not_yet'))
        self.brd_after.set_value(b.get('after'))
        self.brd_when.setText(', '.join(('!' if t.get('is') == 'clear' else '') + str(t['flag'])
                                        for t in b.get('when') or []))
        self.brd_flag.setText(b.get('flag') or '')
        self.brd_once.setChecked(bool(b.get('once')))

    def breeder_spec(self):
        """The options for Document.set_breeder_options (kind breeder), else None."""
        if self.kind() != 'breeder':
            return None
        when = []
        for part in self.brd_when.text().split(','):
            nm = part.strip()
            if nm:
                when.append({'flag': nm.lstrip('!'), 'is': 'clear' if nm.startswith('!') else 'set'})
        spec = {'intro': self.brd_intro.value(), 'not_yet': self.brd_notyet.value(),
                'after': self.brd_after.value(), 'when': when,
                'flag': self.brd_flag.text().strip() or None,
                'once': self.brd_once.isChecked()}
        if self.brd_pool.isChecked():
            spec['pool'] = self.brd_pools.currentData()
        elif self.brd_level_rb.isChecked():
            spec['mate'] = {'species': self.brd_species.currentData(),
                            'level': self.brd_level.value()}
        else:
            spec['mate'] = self.brd_mate.currentData()
        return spec

    def kind(self):
        it = self.kinds.currentItem()
        return it.data(256) if it else None

    def _kind_changed(self, _row):
        kind = self.kind()
        if hasattr(self, 'brd'):
            self.brd.setVisible(kind == 'breeder')
            # S127 r4 (user: "Why is first visit greyed out?"): every kind has a first
            # visit (a breeder's replaces their first words, once)
            self.first.setText('says something else the first time' if kind != 'breeder' else
                               'says something else the first time (instead of the first '
                               'words below)')
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
                                              'follows the list.',
                                     'grandpa': 'The Starry Shrine\'s Grandpa: BREED / HATCH. '
                                                'The night ceremony is the game\'s own; '
                                                'afterwards the game comes back here, Grandpa '
                                                'turns to you and goes on (hatch it? name it, '
                                                'take it with you?).',
                                     'breeder': 'After the ceremony the game comes back here '
                                                'and they say "I hope a strong monster will be '
                                                'born!"; the egg goes to the farm (Grandpa '
                                                'hatches it).'}.get(kind, ''))
        cur_flag = self.flag.text().strip()
        if kind and (not cur_flag or cur_flag in {f'{k}_met' for k in self._kind_ids()}):
            self.flag.setText(f'{kind}_met')        # the suggestion follows the kind

    def _kind_ids(self):
        return [self.kinds.item(i).data(256) for i in range(self.kinds.count())]

    def _first_toggled(self, on):
        # S127 r4: shown only while ticked (a greyed-out box editor read as broken)
        self.first_text.setVisible(on)
        self.flag.setVisible(on)
        self.flag_label.setVisible(on)

    def _ok(self):
        fields = [('first visit', self.first_text)] if self.first.isChecked() else []
        if self.kind() == 'breeder':
            fields += [('first words', self.brd_intro), ('not yet', self.brd_notyet),
                       ('afterwards', self.brd_after)]
        for name, fld in fields:
            why = fld.problem()
            if why:
                QMessageBox.warning(self, 'Service NPC', f'{name}: {why}')
                return
        if self.kind() == 'breeder':
            if self.brd_pool.isChecked() and self.brd_pools.currentData() is None:
                QInputDialog.getText(self, 'No breeding pool', 'Make a pool first on the '
                                     'Services tab (Breeding pools → New). Press OK.')
                return
            if self.brd_once.isChecked() and not self.brd_flag.text().strip():
                self.brd_flag.setText(f"{self.kind()}_bred")
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
            boxes = self.first_text.value()
            if boxes:
                ft = {'boxes': boxes, 'flag': self.flag.text().strip()}
        return kind, lines, ft, getattr(self, '_new_set_name', None)
