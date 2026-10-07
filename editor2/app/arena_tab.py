"""arena_tab.py — the Arena tab (ROADMAP P3.10b, S109; EDITOR_DESIGN §5.2b;
model: editor2/core/arena_doc.py, compiler: editor2/core/arena.py).

Left: the ten arena groups — the classes G F E D C B A S (with their entry
fee), Starry Night and Monster Grandpa's match. Right: the group's entry fee, what winning it
does (read-only — flags belong to the Progression & Flags tab) and one card
per match (three; Monster Grandpa's match is one):

  Master       who stands for the match in the Arena Battle room — a person
               (NPC sprite) or any monster, picked like an NPC sprite.
  Monsters     1, 2 or 3: a smaller team fights only its first monsters.
  the team     one row per monster = its enemy row (EID = $E0 + 9*group +
               3*match + slot; Monster Grandpa $01E1-$01E3): the monster, level,
               stats, exp, AI weights, battle skills. Rows the team does not
               use are grey ("not fought").

Every edit is one undo step (SnapshotCommand); the model validates with the
compiler's own code (no summon / TERRY? in a fighting team — Iron Rule 8).

S128 (ROADMAP P3.14e3) — YOUR ARENA: the list's first row "Your arena" = the
project's own arena (custom.arena, editor2/core/your_arena.py): copies of the
game's Arena Lobby and Arena Battle room (Make your arena), where a lost match /
a win puts you in the lobby, the desk's words. Each class page (and Starry Night)
then shows "In your arena": when the class opens (flags), the flag a win turns ON,
the won words, where a win sends you (the lobby / a room / the hub; Starry Night
also the game's ending).
"""

from PySide6.QtCore import QSize, Qt
from PySide6.QtGui import QColor, QIcon
from PySide6.QtWidgets import (QAbstractItemView, QButtonGroup, QComboBox,
                               QGroupBox, QHBoxLayout, QHeaderView, QLabel,
                               QListWidget, QListWidgetItem, QMessageBox,
                               QPushButton, QRadioButton, QScrollArea,
                               QSpinBox, QSplitter, QTableWidget,
                               QTableWidgetItem, QToolButton, QVBoxLayout,
                               QWidget)

from editor2.app import sprite_qt as Q
from editor2.app.rooms import commands as C
from editor2.core import arena as AR
from editor2.core import arena_doc as AD
from editor2.core import monsters as M
from editor2.core import your_arena as YA
from editor2.core import your_arena_doc as YD

HELP = ('The arena\'s teams are ordinary enemy rows: each match fights three rows in a '
        'fixed place (the same rows the Monsters tab lists as "arena class …"). Change a '
        'monster, its level and stats right here. A team can be 1, 2 or 3 monsters; the '
        'master is who stands for the match before the fight. The entry fee is paid in '
        'the class menu at the lobby.')
COLS = ['Monster', 'Level', 'HP', 'MP', 'ATK', 'DEF', 'AGL', 'INT', 'Exp', 'AI weights',
        'Battle skills']
KEYS = {1: 'level', 2: 'hp', 3: 'mp', 4: 'atk', 5: 'def', 6: 'agl', 7: 'int', 8: 'exp',
        9: 'ai_weights', 10: 'skills'}
GREY = QColor(150, 150, 150)


def _skill_names():
    from editor2.app.monsters_tab import _skill_names as sn
    return sn()


class MatchCard(QGroupBox):
    """One match: master, team size, the three enemy rows."""

    def __init__(self, tab, m):
        super().__init__(f'Match {m + 1}')
        self.tab, self.m = tab, m
        v = QVBoxLayout(self)
        top = QHBoxLayout()
        top.addWidget(QLabel('Master:'))
        self.master_btn = QToolButton()
        self.master_btn.setIconSize(QSize(32, 32))
        self.master_btn.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
        self.master_btn.setToolTip('Who stands for this match in the Arena Battle room: '
                                   'a person or a monster')
        self.master_btn.clicked.connect(self._pick_master)
        top.addWidget(self.master_btn)
        self.master_reset = QPushButton('Original master')
        self.master_reset.clicked.connect(lambda: self.tab.set_master(self.m, None))
        top.addWidget(self.master_reset)
        top.addSpacing(24)
        top.addWidget(QLabel('Monsters:'))
        self.size_group = QButtonGroup(self)
        self.size_btns = []
        for n in (1, 2, 3):
            b = QRadioButton(str(n))
            self.size_group.addButton(b, n)
            self.size_btns.append(b)
            top.addWidget(b)
        self.size_group.idClicked.connect(lambda n: self.tab.set_size(self.m, n))
        top.addStretch(1)
        self.reset_btn = QPushButton('Back to the original match')
        self.reset_btn.setToolTip('The original master, three monsters and the original '
                                  'enemy rows of this match')
        self.reset_btn.clicked.connect(lambda: self.tab.reset_match(self.m))
        top.addWidget(self.reset_btn)
        v.addLayout(top)
        self.table = QTableWidget(3, len(COLS))
        self.table.setHorizontalHeaderLabels(COLS)
        self.table.setVerticalHeaderLabels(['1', '2', '3'])
        self.table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.table.horizontalHeader().setSectionResizeMode(len(COLS) - 1, QHeaderView.Stretch)
        self.table.itemChanged.connect(self._cell_changed)
        self.table.setFixedHeight(self.table.verticalHeader().defaultSectionSize() * 3 + 34)
        v.addWidget(self.table)
        self.note = QLabel('')
        self.note.setWordWrap(True)
        v.addWidget(self.note)
        self.info = None

    # ---------------------------------------------------------------- fill
    def fill(self, info, gi):
        self.info, self.gi = info, gi
        tab = self.tab
        d, f = info['master']
        if f:
            sp = (d - 0x10) & 0xFF
            pm = Q.species_icon(tab.s.doc, sp, 2)
            self.master_btn.setText(f'{tab.names.get(sp, sp)}  (monster)')
        else:
            from editor2.app.rooms.canvas import SpriteCache
            pm = SpriteCache.get(d)
            self.master_btn.setText(f'person ${d:02X}')
        self.master_btn.setIcon(QIcon(pm) if pm is not None and not pm.isNull() else QIcon())
        self.master_reset.setEnabled(info['master_edited'])
        fo = self.master_btn.font()
        fo.setBold(info['master_edited'])
        self.master_btn.setFont(fo)
        self.size_btns[info['size'] - 1].setChecked(True)
        tab._busy = True
        try:
            for r, sl in enumerate(info['slots']):
                fl = sl['fields']
                combo = QComboBox()
                combo.setIconSize(QSize(24, 24))
                for sid, name, icon in tab.species_items():
                    combo.addItem(icon, f'{sid:3d} {name}', sid)
                k = combo.findData(fl['species'])
                if k < 0:            # a species the picker does not offer (215-220)
                    combo.addItem(f"{fl['species']:3d} {tab.names.get(fl['species'], '?')}",
                                  fl['species'])
                    k = combo.count() - 1
                combo.setCurrentIndex(k)
                combo.setEnabled(sl['fights'])
                combo.currentIndexChanged.connect(
                    lambda _i, c=combo, e=sl['eid']: self.tab.set_species(e, c.currentData()))
                self.table.setCellWidget(r, 0, combo)
                vals = [fl['level'], fl['hp'], fl['mp'], fl['atk'], fl['def'], fl['agl'],
                        fl['int'], fl['exp'], ' '.join(str(x) for x in fl['ai_weights']),
                        ', '.join(tab.skills.get(x, f'${x:02X}') for x in fl['skills'])]
                for c, val in enumerate(vals, start=1):
                    it = QTableWidgetItem(str(val))
                    if not sl['fights']:
                        it.setFlags(it.flags() & ~Qt.ItemIsEditable)
                        it.setForeground(GREY)
                    if sl['edited']:
                        fo = it.font()
                        fo.setBold(True)
                        it.setFont(fo)
                    self.table.setItem(r, c, it)
                self.table.setVerticalHeaderItem(
                    r, QTableWidgetItem(f"{r + 1}  EID {sl['eid']}" +
                                        ('' if sl['fights'] else '  (not fought)')))
            self.table.resizeColumnsToContents()
            self.table.horizontalHeader().setSectionResizeMode(len(COLS) - 1, QHeaderView.Stretch)
        finally:
            tab._busy = False
        n = info['size']
        self.note.setText('Bold = changed from the original game. '
                          + ('' if n == 3 else
                             ('This team fights only its first monster' if n == 1 else
                              f'This team fights only its first {n} monsters')
                             + '; the grey rows are not loaded.'))
        self.reset_btn.setEnabled(info['size_edited'] or info['master_edited']
                                  or any(s['edited'] for s in info['slots']))

    # ---------------------------------------------------------------- edits
    def _pick_master(self):
        from editor2.app.rooms.npc_panel import SpritePicker
        d, f = self.info['master']
        cur = ('monster', (d - 0x10) & 0xFF) if f else d
        dlg = SpritePicker(cur, self, monsters=True, project_data=self.tab.s.doc.data)
        dlg.setWindowTitle(f'Master of {AR.group_label(self.gi)} match {self.m + 1}')
        if dlg.exec() and dlg.value is not None and dlg.value != cur:
            v = dlg.value
            spec = {'monster': v[1]} if isinstance(v, tuple) else {'person': f'0x{v:02X}'}
            self.tab.set_master(self.m, spec)

    def _cell_changed(self, it):
        if self.tab._busy or self.info is None:
            return
        r, c = it.row(), it.column()
        key = KEYS.get(c)
        if key is None:
            return
        txt = it.text().strip()
        try:
            if key == 'ai_weights':
                val = [int(x) for x in txt.replace(',', ' ').split()]
                if len(val) != 4:
                    raise ValueError('four numbers 0-255')
            elif key == 'skills':
                inv = {v.lower(): k for k, v in self.tab.skills.items()}
                val = []
                for part in [p.strip() for p in txt.split(',') if p.strip()]:
                    val.append(inv[part.lower()] if part.lower() in inv
                               else int(part.replace('$', '0x'), 0))
                if len(val) > 4:
                    raise ValueError('at most 4 skills')
            else:
                val = int(txt)
        except ValueError as ex:
            QMessageBox.warning(self, 'Arena', f'{COLS[c]}: {txt!r} — {ex}')
            self.tab.refresh()
            return
        self.tab.set_field(self.info['slots'][r]['eid'], key, val)


def _boxes_text(boxes):
    """GameTextField boxes -> the menu-line text form ('\n' a line, '\n\n' a box)."""
    return '\n\n'.join('\n'.join(b) for b in boxes) if boxes else None


def _text_boxes(text):
    if not text:
        return None
    return [b.split('\n') for b in str(text).split('\n\n')]


def _inline(v):
    """A custom.arena TEXT -> boxes for a GameTextField (a dialogue id shows empty)."""
    return [list(b) for b in v['boxes']] if isinstance(v, dict) and v.get('boxes') else None


class YourArenaPage(QWidget):
    """S128: the project's own arena — rooms, return cell, the desk's words."""

    def __init__(self, tab):
        super().__init__()
        from editor2.app.rooms.cell_picker import CellPicker
        from editor2.app.rooms.talk_editor import GameTextField
        self.tab, self.s = tab, tab.s
        rom = getattr(self.s.renderer, 'rom', None)
        v = QVBoxLayout(self)
        lab = QLabel('<b>Your arena</b> — the game\'s Arena Lobby and Arena Battle room copied '
                     'into your project: edit their tiles, NPCs and doors on the Rooms tab '
                     '(a door from any of your rooms leads in; the lobby\'s doors can lead '
                     'anywhere). The receptionist (the lobby\'s script 6) opens the class menu; '
                     'the walk into the arena, the announcer and the crowd are the game\'s. '
                     'The teams, masters and fees are the class pages below; on each class page '
                     '"In your arena" sets when the class opens, the flag a win turns ON and '
                     'where a win sends you. Monster Grandpa\'s match stays in the original game\'s '
                     'arena (your post-game).')
        lab.setWordWrap(True)
        v.addWidget(lab)
        self.make_btn = QPushButton('Make your arena (copy the Arena Lobby and the Arena '
                                    'Battle room)')
        self.make_btn.clicked.connect(self._make)
        v.addWidget(self.make_btn)
        self.body = QWidget()
        bv = QVBoxLayout(self.body)
        bv.setContentsMargins(0, 0, 0, 0)
        row = QHBoxLayout()
        row.addWidget(QLabel('Lobby:'))
        self.lobby = QComboBox()
        row.addWidget(self.lobby, 1)
        b = QPushButton('Open')
        b.clicked.connect(lambda: self._open(self.lobby.currentData()))
        row.addWidget(b)
        row.addSpacing(16)
        row.addWidget(QLabel('Arena:'))
        self.battle = QComboBox()
        row.addWidget(self.battle, 1)
        b = QPushButton('Open')
        b.clicked.connect(lambda: self._open(self.battle.currentData()))
        row.addWidget(b)
        b = QPushButton('Use these rooms')
        b.clicked.connect(self._rooms)
        row.addWidget(b)
        bv.addLayout(row)
        bv.addWidget(QLabel('<b>Back in the lobby</b> — where a lost match and a won class '
                            'put you (click a cell):'))
        rrow = QHBoxLayout()
        self.picker = CellPicker(self.s, 'BACK')
        rrow.addWidget(self.picker)
        b = QPushButton('Set')
        b.clicked.connect(self._return)
        rrow.addWidget(b, 0, Qt.AlignTop)
        rrow.addStretch(1)
        bv.addLayout(rrow)
        self.words = {}
        for key, title, note in (
                ('lost', 'Lost a match', 'the game\'s "Too bad. You need more training…"'),
                ('no', 'Backed out of the menu', 'the game\'s "Better luck next time."'),
                ('locked', 'A class that is not open yet',
                 f'"{YA.LOCKED_DEFAULT.replace(chr(10), " ")}"')):
            bv.addWidget(QLabel(f'<b>{title}</b> — the receptionist says (empty = {note}):'))
            ed = GameTextField(rom, None, empty_note=note)
            self.words[key] = ed
            bv.addWidget(ed)
        wrow = QHBoxLayout()
        b = QPushButton('Apply the words')
        b.clicked.connect(self._words)
        wrow.addWidget(b)
        wrow.addStretch(1)
        b = QPushButton('Remove your arena')
        b.setToolTip('custom.arena goes — the two rooms stay as ordinary copies')
        b.clicked.connect(self._remove)
        wrow.addWidget(b)
        bv.addLayout(wrow)
        v.addWidget(self.body)
        self.problems = QLabel('')
        self.problems.setWordWrap(True)
        self.problems.setStyleSheet('color:#f88;')
        v.addWidget(self.problems)
        v.addStretch(1)

    def refresh(self):
        doc = self.s.doc
        a = doc.your_arena()
        self.make_btn.setVisible(a is None)
        self.body.setVisible(a is not None)
        probs = doc.your_arena_problems() if a is not None else []
        self.problems.setText('<br>'.join('⚠ ' + p for p in probs))
        if a is None:
            return
        for combo, src, cur in ((self.lobby, YA.LOBBY_SOURCE, a.get('lobby')),
                                (self.battle, YA.BATTLE_SOURCE, a.get('battle'))):
            combo.blockSignals(True)
            combo.clear()
            for rid, name in doc.arena_room_choices(src):
                combo.addItem(name, rid)
            combo.setCurrentIndex(max(0, combo.findData(cur)))
            combo.blockSignals(False)
        try:
            self.picker.set_room(a.get('lobby'))
            r = dict(YA.RETURN_DEFAULT, **(a.get('return') or {}))
            self.picker.set_cell(int(r['screen']), int(r['x']), int(r['y']))
        except Exception:                                        # noqa: BLE001
            pass
        w = a.get('words') or {}
        self.words['lost'].set_value(_inline(w.get('lost')))
        self.words['no'].set_value(_inline(w.get('no')))
        self.words['locked'].set_value(_text_boxes(w.get('locked')))

    def _open(self, rid):
        win = self.window()
        if rid and hasattr(win, 'navigate_to'):
            win.navigate_to({'tab': 'rooms', 'room': rid})

    def _make(self):
        from editor2.app.session import REPO
        rend = self.s.renderer
        if QMessageBox.question(self, 'Your arena', 'Copy the Arena Lobby ($06) and the Arena '
                                'Battle room ($5D, every state — Starry Night is at night) into '
                                'your project as your arena?') != QMessageBox.Yes:
            return
        self.tab._push('Make your arena', lambda doc: doc.make_your_arena(REPO, rend))

    def _rooms(self):
        lo, ba = self.lobby.currentData(), self.battle.currentData()
        self.tab._push('Your arena: rooms', lambda doc: doc.set_your_arena_rooms(lo, ba))

    def _return(self):
        k, x, y = self.picker.cell()
        if self.picker.is_wall(x, y):
            QMessageBox.warning(self, 'Your arena', f'({x},{y}) is a wall — click a floor cell.')
            return
        self.tab._push(f'Your arena: back in the lobby at screen {k} ({x},{y})',
                       lambda doc: doc.set_your_arena_return(k, x, y))

    def _words(self):
        for key, ed in self.words.items():
            p = ed.problem()
            if p:
                QMessageBox.warning(self, 'Your arena', f'{key}: {p}')
                return
        vals = {k: ed.value() for k, ed in self.words.items()}

        def op(doc):
            doc.set_your_arena_words('lost', vals['lost'])
            doc.set_your_arena_words('no', vals['no'])
            doc.set_your_arena_words('locked', _boxes_text(vals['locked']))
        self.tab._push('Your arena: the desk\'s words', op)

    def _remove(self):
        if QMessageBox.question(self, 'Your arena', 'Remove your arena? The two rooms stay as '
                                'ordinary copies.') != QMessageBox.Yes:
            return
        self.tab._push('Remove your arena', lambda doc: doc.remove_your_arena())


class ClassArenaBox(QGroupBox):
    """S128: one class (or Starry Night) in YOUR arena."""

    def __init__(self, tab):
        super().__init__('In your arena')
        from editor2.app.encounters_tab import FlagTerms
        from editor2.app.rooms.cell_picker import CellPicker
        from editor2.app.rooms.talk_editor import GameTextField
        self.tab, self.s = tab, tab.s
        self.FlagTerms = FlagTerms
        rom = getattr(self.s.renderer, 'rom', None)
        self.name = None
        v = QVBoxLayout(self)
        self.offered = QRadioButton('The receptionist offers Starry Night')
        self.not_offered = QRadioButton('No Starry Night in your arena')
        orow = QHBoxLayout()
        orow.addWidget(self.offered)
        orow.addWidget(self.not_offered)
        orow.addStretch(1)
        self.offer_row = QWidget()
        self.offer_row.setLayout(orow)
        v.addWidget(self.offer_row)
        self.when_label = QLabel()
        v.addWidget(self.when_label)
        self.terms_holder = QVBoxLayout()
        v.addLayout(self.terms_holder)
        self.terms = None
        frow = QHBoxLayout()
        frow.addWidget(QLabel('A win turns this flag ON:'))
        self.flag = QComboBox()
        self.flag.setEditable(True)
        frow.addWidget(self.flag, 1)
        b = QPushButton('New flag…')
        b.clicked.connect(self._new_flag)
        frow.addWidget(b)
        v.addLayout(frow)
        self.flag_note = QLabel('')
        self.flag_note.setWordWrap(True)
        self.flag_note.setStyleSheet('color:#aaa;')
        v.addWidget(self.flag_note)
        self.words_label = QLabel()
        v.addWidget(self.words_label)
        self.words = GameTextField(rom, None, empty_note="the game's words")
        v.addWidget(self.words)
        trow = QHBoxLayout()
        trow.addWidget(QLabel('After a win:'))
        self.then = QComboBox()
        self.then.currentIndexChanged.connect(self._then_changed)
        trow.addWidget(self.then, 1)
        self.room = QComboBox()
        self.room.currentIndexChanged.connect(self._room_changed)
        trow.addWidget(self.room, 1)
        v.addLayout(trow)
        self.picker = CellPicker(self.s, 'LAND')
        v.addWidget(self.picker)
        self.offer_words = {}
        self.offer_box = QWidget()
        ob = QVBoxLayout(self.offer_box)
        ob.setContentsMargins(0, 0, 0, 0)
        for key, title, note in (('offer', 'The offer (ends with YES / NO)',
                                  "the game's \"You made it! … ready?\""),
                                 ('yes', 'YES', "the game's announcement"),
                                 ('no', 'NO', "the game's \"Let me know when you're ready.\"")):
            ob.addWidget(QLabel(f'<b>{title}</b> (empty = {note}):'))
            ed = GameTextField(rom, None, empty_note=note)
            self.offer_words[key] = ed
            ob.addWidget(ed)
        v.addWidget(self.offer_box)
        brow = QHBoxLayout()
        b = QPushButton('Apply')
        b.clicked.connect(self._apply)
        brow.addWidget(b)
        b = QPushButton('Clear (the game\'s rules)')
        b.clicked.connect(self._clear)
        brow.addWidget(b)
        brow.addStretch(1)
        v.addLayout(brow)

    def _fill_flags(self, cur):
        self.flag.blockSignals(True)
        self.flag.clear()
        self.flag.addItem('(no flag)', None)
        for fl in self.s.doc.flags():
            self.flag.addItem(fl['name'], fl['name'])
        if cur is not None and self.flag.findData(cur) < 0:
            self.flag.addItem(str(cur), cur)
        self.flag.setCurrentIndex(max(0, self.flag.findData(cur)))
        self.flag.blockSignals(False)

    def _new_flag(self):
        from PySide6.QtWidgets import QInputDialog
        name, ok = QInputDialog.getText(self, 'New flag', 'Flag name (letters, digits, _):')
        if ok and name.strip():
            nm = self.s.doc._slug(name.strip())
            self.flag.addItem(f'{nm}  (new)', nm)
            self.flag.setCurrentIndex(self.flag.count() - 1)
            self._new.append(nm)

    def show_class(self, name):
        doc = self.s.doc
        self.name = name
        self._new = []
        starry = name == 'StarryNight'
        sp = doc.your_arena_class(name)
        self.offer_row.setVisible(starry)
        self.offer_box.setVisible(starry)
        if starry:
            (self.offered if sp is not None else self.not_offered).setChecked(True)
        sp = sp or {}
        self.when_label.setText('<b>Offered when</b> (every condition; none = always — and '
                                'never again once its won flag is ON):' if starry else
                                f'<b>{name} class opens when</b> (every condition; none = always '
                                'open — a closed class shows "-" in the class menu):')
        if self.terms is not None:
            self.terms_holder.removeWidget(self.terms)
            self.terms.setParent(None)
        self.terms = self.FlagTerms(doc, sp.get('opens_when') or [])
        self.terms.setMinimumHeight(100)
        self.terms_holder.addWidget(self.terms)
        self._fill_flags(sp.get('won_flag'))
        self.flag_note.setText('Winning a class also turns ON the flags of the classes below it '
                               'that have one (the game\'s catch-up) and marks them won in the '
                               'menu.' if not starry else 'The receptionist stops offering Starry '
                               'Night once this flag is ON.')
        self.words_label.setText('<b>What the receptionist says after the win</b>' if not starry
                                 else '<b>Said in the arena after the final</b> (not for the '
                                 'ending — the game\'s own scene plays)')
        self.words.set_value(_inline(sp.get('won_words')))
        for k, ed in self.offer_words.items():
            ed.set_value(_inline(sp.get(k)))
        self.then.blockSignals(True)
        self.then.clear()
        for k in (('lobby', 'room', 'hub', 'ending') if starry else ('lobby', 'room', 'hub')):
            self.then.addItem(YD.THEN_LABELS[k], k)
        th = sp.get('then') or {'to': 'ending' if starry else 'lobby'}
        self.then.setCurrentIndex(max(0, self.then.findData(th.get('to'))))
        self.then.blockSignals(False)
        self.room.blockSignals(True)
        self.room.clear()
        for r in doc.rooms:
            if not r.get('placeholder'):
                self.room.addItem(f"${int(str(r['mapID']), 0):02X} {doc.room_name(r)}", r['id'])
        if th.get('room'):
            self.room.setCurrentIndex(max(0, self.room.findData(th['room'])))
        self.room.blockSignals(False)
        self._then_changed()
        if th.get('to') == 'room':
            self.picker.set_cell(int(th.get('screen', 0)), int(th.get('x', 4)),
                                 int(th.get('y', 4)))

    def _then_changed(self, _i=None):
        room = self.then.currentData() == 'room'
        self.room.setVisible(room)
        self.picker.setVisible(room)
        if room:
            self._room_changed()

    def _room_changed(self, _i=None):
        rid = self.room.currentData()
        if rid:
            self.picker.set_room(rid)

    def spec(self):
        th = {'to': self.then.currentData()}
        if th['to'] == 'room':
            k, x, y = self.picker.cell()
            th.update(room=self.room.currentData(), screen=k, x=x, y=y)
        d, txt = self.flag.currentData(), self.flag.currentText().strip()
        fl = d if d is not None else (txt.split()[0] if txt and txt != '(no flag)' else None)
        out = {'opens_when': self.terms.terms(), 'won_flag': fl,
               'won_words': self.words.value(), 'then': th}
        if self.name == 'StarryNight':
            for k, ed in self.offer_words.items():
                out[k] = ed.value()
        return out

    def _apply(self):
        name = self.name
        eds = [self.words] + (list(self.offer_words.values()) if name == 'StarryNight' else [])
        for ed in eds:
            p = ed.problem()
            if p:
                QMessageBox.warning(self, 'Your arena', p)
                return
        if self.then.currentData() == 'room':
            _k, x, y = self.picker.cell()
            if self.picker.is_wall(x, y):
                QMessageBox.warning(self, 'Your arena', f'({x},{y}) is a wall — click a floor '
                                    'cell.')
                return
        spec = None if (name == 'StarryNight' and self.not_offered.isChecked()) else self.spec()
        new = list(self._new) + list(self.terms.new_flags)

        def op(doc):
            for nm in new:
                if not any(f.get('name') == doc._slug(nm) for f in doc.flags()):
                    doc.add_flag(nm)
            doc.set_your_arena_class(name, spec)
        self.tab._push(f'Your arena: {AR.group_label(AR.GROUPS.index(name))}', op)

    def _clear(self):
        name = self.name
        self.tab._push(f'Your arena: {name} — the game\'s rules',
                       lambda doc: doc.set_your_arena_class(name, None if name == 'StarryNight'
                                                            else {}))


class ArenaTab(QWidget):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.gi = 0
        self._busy = False
        self._items = None
        self.skills = _skill_names()
        root = QHBoxLayout(self)
        split = QSplitter()
        root.addWidget(split)
        left = QWidget()
        lv = QVBoxLayout(left)
        self.list = QListWidget()
        self.list.currentRowChanged.connect(self._picked)
        lv.addWidget(self.list, 1)
        h = QLabel(HELP)
        h.setWordWrap(True)
        lv.addWidget(h)
        split.addWidget(left)

        right = QWidget()
        self.rv = QVBoxLayout(right)
        self.title = QLabel()
        fo = self.title.font()
        fo.setPointSize(fo.pointSize() + 4)
        fo.setBold(True)
        self.title.setFont(fo)
        self.rv.addWidget(self.title)
        fee = QHBoxLayout()
        self.fee_label = QLabel('Entry fee (gold):')
        fee.addWidget(self.fee_label)
        self.fee = QSpinBox()
        self.fee.setRange(0, 65535)
        self.fee.setKeyboardTracking(False)
        self.fee.valueChanged.connect(self._fee_changed)
        fee.addWidget(self.fee)
        self.fee_reset = QPushButton('Original fee')
        self.fee_reset.clicked.connect(lambda: self._fee_changed(None))
        fee.addWidget(self.fee_reset)
        fee.addStretch(1)
        self.rv.addLayout(fee)
        self.victory = QLabel()
        self.victory.setWordWrap(True)
        self.victory.setTextInteractionFlags(Qt.TextSelectableByMouse)
        self.rv.addWidget(self.victory)
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        inner = QWidget()
        self.cards_v = QVBoxLayout(inner)
        self.your_page = YourArenaPage(self)          # S128: your arena (list row 0)
        self.cards_v.addWidget(self.your_page)
        self.class_box = ClassArenaBox(self)          # S128: a class in your arena
        self.cards_v.addWidget(self.class_box)
        self.cards = [MatchCard(self, m) for m in range(3)]
        for c in self.cards:
            self.cards_v.addWidget(c)
        self.cards_v.addStretch(1)
        scroll.setWidget(inner)
        self.rv.addWidget(scroll, 1)
        split.addWidget(right)
        split.setSizes([260, 1200])

        self._stale = False
        self.s.undo.indexChanged.connect(self._undo_changed)
        self.refresh()

    # ---------------------------------------------------------------- data
    @property
    def names(self):
        return {s['id']: s['name'] for s in self.s.doc.species_catalog()}

    def species_items(self):
        """[(sid, name, QIcon)] a team member may be: monsters 0-214 + the
        project's new species (never TERRY? / the summons — Iron Rule 8)."""
        if self._items is None:
            out = []
            for s in self.s.doc.species_catalog():
                if s['kind'] in ('monster', 'new'):
                    pm = Q.species_icon(self.s.doc, s['id'], 1)
                    out.append((s['id'], s['name'], QIcon(pm) if not pm.isNull() else QIcon()))
            self._items = out
        return self._items

    def _undo_changed(self, _i):
        from shiboken6 import isValid
        if not isValid(self):
            return
        self._items = None
        if self.isVisible():
            self.refresh()
        else:
            self._stale = True

    def showEvent(self, ev):
        if self._stale:
            self._stale = False
            self.refresh()
        super().showEvent(ev)

    def refresh(self):
        doc = self.s.doc
        try:
            self.skills = doc.skill_names_effective()     # S110: project skill names
            groups = doc.arena_groups()
            model = doc.monsters_model()
        except Exception as ex:                       # noqa: BLE001
            self.title.setText('The project does not validate')
            self.victory.setText(str(ex))
            return
        self._busy = True
        cur = self.gi
        self.list.clear()
        ya = doc.your_arena()                         # S128: row 0 = your arena
        it = QListWidgetItem('★ Your arena' + ('' if ya is not None else '  (none yet)'))
        fo = it.font()
        fo.setBold(ya is not None)
        it.setFont(fo)
        self.list.addItem(it)
        for g in groups:
            txt = g['label'] + (f"   · fee {g['fee']}" if g['fee'] is not None else '')
            sizes = [doc.arena_match(g['gi'], m, model)['size'] for m in range(g['matches'])]
            if any(n != 3 for n in sizes):
                txt += '   · ' + '/'.join(str(n) for n in sizes)
            it = QListWidgetItem(txt)
            edited = g['fee_edited'] or any(
                (lambda i: i['size_edited'] or i['master_edited'] or
                 any(s['edited'] for s in i['slots']))(doc.arena_match(g['gi'], m, model))
                for m in range(g['matches']))
            if edited:
                fo = it.font()
                fo.setBold(True)
                it.setFont(fo)
            self.list.addItem(it)
        self._busy = False
        self.list.setCurrentRow(cur + 1)
        if cur < 0:
            self._show_your()
        else:
            self._show(groups[cur], model)

    def _picked(self, row):
        if self._busy or row < 0:
            return
        self.gi = row - 1
        if self.gi < 0:
            self._show_your()
            return
        self._show(self.s.doc.arena_groups()[self.gi], self.s.doc.monsters_model())

    def _show_your(self):
        """S128: list row 0 — your arena's page."""
        self.title.setText('Your arena')
        for w in (self.fee_label, self.fee, self.fee_reset, self.victory, self.class_box):
            w.setVisible(False)
        for c in self.cards:
            c.setVisible(False)
        self.your_page.setVisible(True)
        self.your_page.refresh()

    def show_your_arena(self, cls=None):
        """S128: the Progression & Flags tab's link — a class page (or your arena)."""
        if cls in AR.GROUPS:
            self.list.setCurrentRow(AR.GROUPS.index(cls) + 1)
        else:
            self.list.setCurrentRow(0)

    def _show(self, g, model):
        doc = self.s.doc
        gi = g['gi']
        self.your_page.setVisible(False)
        self.victory.setVisible(True)
        ya = doc.your_arena() is not None and gi != AR.KING
        self.class_box.setVisible(ya)
        if ya:
            self.class_box.show_class(AR.GROUPS[gi])
        self.title.setText(g['label'] + ('  — one match' if gi == AR.KING else '  — three matches'))
        has_fee = g['fee'] is not None
        for w in (self.fee_label, self.fee, self.fee_reset):
            w.setVisible(has_fee)
        if has_fee:
            self._busy = True
            self.fee.setValue(g['fee'])
            self._busy = False
            self.fee_reset.setEnabled(g['fee_edited'])
            fo = self.fee.font()
            fo.setBold(g['fee_edited'])
            self.fee.setFont(fo)
        self.victory.setText('<b>Winning it</b> (read-only — event flags are the Progression '
                             '&amp; Flags tab\'s): ' + '; '.join(AD.VICTORY[gi]))
        for m, card in enumerate(self.cards):
            card.setVisible(m < g['matches'])
            if m < g['matches']:
                card.fill(doc.arena_match(gi, m, model), gi)

    # ---------------------------------------------------------------- edits
    def _push(self, label, op):
        cmd = C.SnapshotCommand(self.s, label, op)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            self.refresh()
            return False
        return True

    def _fee_changed(self, value):
        if self._busy:
            return
        gi = self.gi
        if value is None:
            value = self.s.doc.arena_fee_vanilla(gi)
        self._push(f'{AR.group_label(gi)}: fee → {value}',
                   lambda doc: doc.set_arena_fee(gi, value))

    def set_size(self, m, n):
        if self._busy:
            return
        gi = self.gi
        self._push(f'{AR.group_label(gi)} match {m + 1}: {n} monster' + ('s' if n > 1 else ''),
                   lambda doc: doc.set_arena_size(gi, m, n))

    def set_master(self, m, spec):
        gi = self.gi
        what = 'original master' if spec is None else (
            f"master → {self.names.get(spec['monster'], spec['monster'])}"
            if 'monster' in spec else f"master → person {spec['person']}")
        self._push(f'{AR.group_label(gi)} match {m + 1}: {what}',
                   lambda doc: doc.set_arena_master(gi, m, spec))

    def set_species(self, eid, sid):
        if self._busy:
            return
        self._push(f'EID {eid}: monster → {self.names.get(sid, sid)}',
                   lambda doc: doc.set_enemy_fields(eid, {'species': sid}))

    def set_field(self, eid, key, val):
        self._push(f'EID {eid}: {key} → {val}',
                   lambda doc: doc.set_enemy_fields(eid, {key: val}))

    def reset_match(self, m):
        gi = self.gi
        self._push(f'{AR.group_label(gi)} match {m + 1}: back to the original',
                   lambda doc: doc.reset_arena_match(gi, m))
