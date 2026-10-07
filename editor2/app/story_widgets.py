"""story_widgets.py — the editor's story tools (S129, ROADMAP P3.14b-d; EDITOR_DESIGN §5.7
"Story (S129)").

* CheckDialog — a STORY CHECK (custom.checks): a named question about the game (the bag,
  the gold, the monsters owned, the party's levels, the Library, a chance, the arena, the
  story spine, AND / OR of flags). A check stands wherever a flag can be checked.
* QuestDialog — a QUEST (custom.quests) given by an NPC: offer / accept / decline, what it
  asks for (conditions — flags or checks), items handed over, the reward, every text a
  game box editor.
* LockDialog — a door / exit that opens once conditions hold (Document.lock_exit).
* MusicRulesDialog — a room's / a gate's songs by flag.
* ItemSetsDialog — a shop's item sets by flag.
Headless helpers: item_choices, species_choices, family_choices, milestone_choices.
"""

import copy

from PySide6.QtCore import Qt, Signal
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox, QFormLayout,
                               QGroupBox, QHBoxLayout, QLabel, QLineEdit, QListWidget,
                               QListWidgetItem, QMessageBox, QPushButton, QScrollArea, QSpinBox,
                               QTabWidget, QTableWidget, QToolButton, QVBoxLayout, QWidget)

from editor2.core import story as ST


# ------------------------------------------------------------------ choices
def item_choices():
    from editor2.core.shops import item_names
    return [(f'{n} ({i})', i) for i, n in sorted(item_names().items()) if 1 <= i <= 43]


def species_choices(doc):
    from editor2.core.conversation import species_names
    names = species_names(doc.data if doc is not None else None)
    return [(f'{n} ({i})', i) for i, n in sorted(names.items())
            if i not in ST.PROTECTED_SPECIES and i != 220 and (i <= 214 or 221 <= i <= 239)]


def family_choices():
    from editor2.core.gamedata import FAMILY_NAMES
    return [(n, i) for i, n in enumerate(FAMILY_NAMES)]


def milestone_choices(doc):
    return [(f'{n}  ({f})', f) for f, n in (doc.milestones() if doc is not None else [])]


def song_choices(doc):
    """(label, value) of every song a rule may play: the project's songs (by id), then
    the game's music (raw ids '0xNN')."""
    out = []
    try:
        for s in doc.project_songs() or []:
            out.append((f"★ {s.get('name') or s.get('id')} (your song)", s.get('id')))
    except Exception:                                            # noqa: BLE001
        pass
    try:
        cat = doc.vanilla_sounds()
    except Exception:                                            # noqa: BLE001
        cat = []
    for s in cat or []:
        if s.get('kind') != 'music':
            continue
        n = int(s.get('id_int', int(str(s['id']).replace('$', '0x'), 0)))
        nm = None
        try:
            nm = doc.song_name(f'${n:02X}', None) or doc.song_name(f'0x{n:02X}', None)
        except Exception:                                        # noqa: BLE001
            pass
        out.append((f'${n:02X} ' + (nm or 'game song'), f'0x{n:02X}'))
    if not cat:
        for n in (0x09, 0x0C, 0x0F, 0x12, 0x15, 0x18, 0x1B, 0x1E, 0x2E, 0x31, 0x34):
            out.append((f'${n:02X} game song', f'0x{n:02X}'))
    return out


def _combo(choices, value=None, width=24):
    c = QComboBox()
    c.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
    c.setMinimumContentsLength(width)
    for lab, d in choices:
        c.addItem(lab, d)
    if value is not None:
        i = c.findData(value)
        if i < 0:
            c.addItem(str(value), value)
            i = c.count() - 1
        c.setCurrentIndex(i)
    return c


def _spin(lo, hi, v, suffix=''):
    s = QSpinBox()
    s.setRange(lo, hi)
    s.setValue(int(v))
    if suffix:
        s.setSuffix(suffix)
    return s


def _terms_widget(doc, terms):
    from editor2.app.encounters_tab import FlagTerms
    return FlagTerms(doc, terms or [])


# ------------------------------------------------------------------ item lists
class ItemCountList(QWidget):
    """Rows of (item, how many)."""
    changed = Signal()

    def __init__(self, items=None, parent=None, max_rows=8):
        super().__init__(parent)
        self.max_rows = max_rows
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        self.table = QTableWidget(0, 2)
        self.table.setHorizontalHeaderLabels(['item', 'how many'])
        self.table.horizontalHeader().setStretchLastSection(True)
        self.table.setColumnWidth(0, 240)
        self.table.setMaximumHeight(130)
        v.addWidget(self.table)
        row = QHBoxLayout()
        for txt, fn in (('+ item', lambda: self._add({})), ('− item', self._del)):
            b = QPushButton(txt)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)
        for it in items or []:
            self._add(it)

    def _add(self, it):
        if self.table.rowCount() >= self.max_rows:
            return
        r = self.table.rowCount()
        self.table.insertRow(r)
        c = _combo(item_choices(), it.get('item', 0x01))
        c.activated.connect(lambda _i: self.changed.emit())
        self.table.setCellWidget(r, 0, c)
        s = _spin(1, 20, it.get('count', 1))
        s.valueChanged.connect(lambda _v: self.changed.emit())
        self.table.setCellWidget(r, 1, s)
        self.changed.emit()

    def _del(self):
        r = self.table.currentRow()
        if r < 0:
            r = self.table.rowCount() - 1
        if r >= 0:
            self.table.removeRow(r)
            self.changed.emit()

    def value(self):
        return [{'item': self.table.cellWidget(r, 0).currentData(),
                 'count': self.table.cellWidget(r, 1).value()}
                for r in range(self.table.rowCount())]


# ------------------------------------------------------------------ story check
KIND_HELP = {
    'item': 'True while the bag holds at least this many of the item.',
    'gold': 'True while the player has at least this much gold.',
    'species': 'True while a monster of this kind is owned (anywhere: the party or the '
               'farm; eggs and sleeping monsters do not count).',
    'family': 'True while a monster of this family is owned (the party or the farm).',
    'monsters': 'True while at least this many monsters are owned (or in the party).',
    'level': 'The party\'s levels: one party monster at the level or higher, the average, '
             'or every party monster.',
    'seen': 'True while at least this many kinds of monster are marked seen in the '
            'Library.',
    'chance': 'A dice roll each time the game reads it (a conversation\'s If, a room '
              'loading…): true this percent of the time.',
    'arena': 'True once at least this many arena classes are won (G = 1 … S = 8).',
    'bag_room': 'True while the bag has room for at least this many more items (a reward '
                'that would not fit…).',
    'story': 'True once the story has reached this milestone or a later one (the story '
             'spine: Progression & Flags → Story).',
    'all': 'True while ALL the conditions hold (flags and other checks; "OFF" = NOT).',
    'any': 'True while at least ONE of the conditions holds (OR).',
}


class CheckDialog(QDialog):
    """New / edit a story check. result() -> (name, spec)."""

    def __init__(self, doc, name=None, spec=None, parent=None):
        super().__init__(parent)
        self.doc = doc
        self.setWindowTitle('Story check' if name is None else f'Story check “{name}”')
        self.resize(640, 520)
        spec = copy.deepcopy(spec or {'kind': 'item', 'item': 0x01, 'count': 1})
        self._spec = spec
        v = QVBoxLayout(self)
        intro = QLabel('A <b>story check</b> asks the game a question — what the player carries, '
                       'owns, has reached. Use it wherever a flag can be checked (an If, a room '
                       'state, an NPC shown when, a quest, music, a shop\'s items): '
                       '<i>ON</i> = the answer is yes, <i>OFF</i> = no.')
        intro.setWordWrap(True)
        v.addWidget(intro)
        f = QFormLayout()
        self.name = QLineEdit(name or '')
        self.name.setPlaceholderText('e.g. has_key, rich, party_level_20')
        f.addRow('name', self.name)
        self.kind = QComboBox()
        for k in ST.CHECK_KIND_ORDER:
            self.kind.addItem(ST.CHECK_KINDS[k][1], k)
        self.kind.setCurrentIndex(max(0, self.kind.findData(spec.get('kind'))))
        self.kind.currentIndexChanged.connect(lambda _i: self._build())
        f.addRow('asks', self.kind)
        v.addLayout(f)
        self.help = QLabel()
        self.help.setWordWrap(True)
        self.help.setStyleSheet('color:#aaa;')
        v.addWidget(self.help)
        self.box = QWidget()
        self.bl = QVBoxLayout(self.box)
        self.bl.setContentsMargins(0, 0, 0, 0)
        v.addWidget(self.box, 1)
        self.said = QLabel()
        self.said.setWordWrap(True)
        v.addWidget(self.said)
        self.note = QLineEdit(spec.get('comment', ''))
        self.note.setPlaceholderText('a note for you (not in the game)')
        v.addWidget(self.note)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._fields = {}
        self._build()

    def _clear(self):
        while self.bl.count():
            w = self.bl.takeAt(0).widget()
            if w is not None:
                w.hide()
                w.setParent(None)
                w.deleteLater()

    def _build(self):
        self._clear()
        k = self.kind.currentData()
        sp = self._spec if self._spec.get('kind') == k else {'kind': k}
        self.help.setText(KIND_HELP.get(k, ''))
        f = QFormLayout()
        w = QWidget()
        w.setLayout(f)
        self._fields = {}
        if k == 'item':
            self._fields['item'] = _combo(item_choices(), sp.get('item', 0x01))
            self._fields['count'] = _spin(1, 20, sp.get('count', 1))
            f.addRow('item', self._fields['item'])
            f.addRow('at least', self._fields['count'])
        elif k == 'gold':
            self._fields['amount'] = _spin(0, ST.GOLD_MAX, sp.get('amount', 1000), ' G')
            f.addRow('at least', self._fields['amount'])
        elif k in ('species', 'family'):
            ch = species_choices(self.doc) if k == 'species' else family_choices()
            self._fields[k] = _combo(ch, sp.get(k, ch[0][1] if ch else 0))
            f.addRow('monster' if k == 'species' else 'family', self._fields[k])
            self._fields['where'] = _combo([('anywhere (party or farm)', 'anywhere'),
                                            ('in the party', 'party')],
                                           sp.get('where', 'anywhere'))
            f.addRow('where', self._fields['where'])
        elif k == 'monsters':
            self._fields['count'] = _spin(1, 40, sp.get('count', 5))
            f.addRow('at least', self._fields['count'])
            self._fields['where'] = _combo([('owned (party and farm)', 'anywhere'),
                                            ('in the party', 'party')],
                                           sp.get('where', 'anywhere'))
            f.addRow('monsters', self._fields['where'])
        elif k == 'level':
            self._fields['mode'] = _combo([('a party monster is', 'any'),
                                           ("the party's average is", 'average'),
                                           ('every party monster is', 'all')],
                                          sp.get('mode', 'any'))
            self._fields['level'] = _spin(1, 99, sp.get('level', 10))
            f.addRow('', self._fields['mode'])
            f.addRow('level (or higher)', self._fields['level'])
        elif k in ('seen', 'bag_room'):
            self._fields['count'] = _spin(1, 240 if k == 'seen' else 20,
                                          sp.get('count', 10 if k == 'seen' else 1))
            f.addRow('at least', self._fields['count'])
        elif k == 'chance':
            self._fields['percent'] = _spin(1, 100, sp.get('percent', 50), ' %')
            f.addRow('chance', self._fields['percent'])
        elif k == 'arena':
            self._fields['classes'] = _spin(1, 8, sp.get('classes', 1))
            f.addRow('classes won', self._fields['classes'])
        elif k == 'story':
            ch = milestone_choices(self.doc)
            if not ch:
                lab = QLabel('The story spine has no milestones yet (Progression & Flags → '
                             'Story).')
                lab.setWordWrap(True)
                f.addRow(lab)
            else:
                self._fields['milestone'] = _combo(ch, sp.get('milestone', ch[0][1]))
                f.addRow('reached', self._fields['milestone'])
        elif k in ('all', 'any'):
            self._fields['terms'] = _terms_widget(self.doc, sp.get('terms') or [])
            f.addRow(self._fields['terms'])
        self.bl.addWidget(w)
        self.bl.addStretch(1)
        for wd in self._fields.values():
            for sig in ('activated', 'valueChanged'):
                if hasattr(wd, sig):
                    getattr(wd, sig).connect(lambda *_a: self._said())
        self._said()

    def spec(self):
        k = self.kind.currentData()
        out = {'kind': k}
        for key, wd in self._fields.items():
            if key == 'terms':
                out['terms'] = wd.terms()
            elif isinstance(wd, QComboBox):
                out[key] = wd.currentData()
            else:
                out[key] = wd.value()
        if self.note.text().strip():
            out['comment'] = self.note.text().strip()
        return out

    def _said(self):
        try:
            self.said.setText('<b>True when:</b> ' + self.doc.describe_check(self.spec()))
        except Exception:                                        # noqa: BLE001
            self.said.setText('')

    def accept(self):
        nm = self.name.text().strip()
        if not nm:
            QMessageBox.warning(self, 'Story check', 'Give the check a name.')
            return
        try:
            self.doc._check_spec_ok(self.spec())
        except ValueError as ex:
            QMessageBox.warning(self, 'Story check', str(ex))
            return
        super().accept()

    def result(self):
        return self.name.text().strip(), self.spec()


def new_check(parent, session):
    """New story check… from anywhere: returns the new name (one undo step) or None."""
    from editor2.app.rooms import commands as C
    dlg = CheckDialog(session.doc, parent=parent)
    if dlg.exec() != QDialog.Accepted:
        return None
    name, spec = dlg.result()
    out = {}

    def op(doc):
        out['n'] = doc.add_check(name, spec)
    cmd = C.SnapshotCommand(session, f'New story check {name}', op)
    session.undo.push(cmd)
    if cmd.error is not None:
        QMessageBox.warning(parent, 'Story check', str(cmd.error))
        return None
    return out.get('n')


# ------------------------------------------------------------------ quest
QUEST_TEXT_LABELS = [
    ('offer', 'Offer (the YES / NO question)', 'I have a favour to ask. Will you help me?'),
    ('accept', 'YES — accepted', 'Thank you! Come back when it is done.'),
    ('decline', 'NO — declined', 'Oh well. Maybe another time.'),
    ('progress', 'Under way (the objective not met yet)', 'Not done yet? Come back later.'),
    ('complete', 'Finished (said before the reward)', 'You did it! Here is your reward.'),
    ('done', 'Afterwards (every later talk)', 'Thanks again!'),
    ('not_yet', 'Not offered yet (its "offered only when" fails)', ''),
    ('bag_full', 'Bag full (the reward items would not fit)', ''),
]


class QuestDialog(QDialog):
    """Edit a quest (custom.quests). result() -> the spec (without id / giver / flags)."""

    def __init__(self, doc, rom, quest, parent=None):
        super().__init__(parent)
        from editor2.app.rooms.talk_editor import FlagList, GameTextField
        self.doc, self.rom = doc, rom
        q = copy.deepcopy(quest or {})
        self.q = q
        self.setWindowTitle(f"Quest “{q.get('name') or q.get('id')}”")
        self.resize(980, 760)
        v = QVBoxLayout(self)
        top = QFormLayout()
        self.name = QLineEdit(q.get('name') or q.get('id') or '')
        top.addRow('name', self.name)
        started, done = ST.quest_flags(q)
        fl = QLabel(f'Its flags: <b>{started}</b> (under way) · <b>{done}</b> (finished) — '
                    'use them anywhere (a door that opens, a milestone of the story…).')
        fl.setWordWrap(True)
        top.addRow('', fl)
        v.addLayout(top)
        tabs = QTabWidget()
        v.addWidget(tabs, 1)
        # -- what it asks
        w = QWidget()
        f = QVBoxLayout(w)
        f.addWidget(QLabel('<b>Offered only when</b> (all must hold; empty = always):'))
        self.requires = _terms_widget(doc, q.get('requires'))
        f.addWidget(self.requires)
        f.addWidget(QLabel('<b>Objective</b> — the quest can be finished while all of these '
                           'hold (flags or story checks, e.g. a check "the bag holds 3 '
                           'TinyMedals"):'))
        self.objective = _terms_widget(doc, q.get('objective'))
        f.addWidget(self.objective)
        b = QPushButton('New story check…')
        b.clicked.connect(self._new_check)
        f.addWidget(b)
        f.addWidget(QLabel('<b>Handed over</b> when it is finished (taken from the bag):'))
        self.take = ItemCountList(q.get('take'))
        f.addWidget(self.take)
        tabs.addTab(w, 'What it asks')
        # -- reward
        w = QWidget()
        f = QVBoxLayout(w)
        rw = q.get('reward') or {}
        f.addWidget(QLabel('<b>Items</b> (the bag must have room — else the "bag full" words; '
                           'the items handed over make room first):'))
        self.r_items = ItemCountList(rw.get('items'))
        f.addWidget(self.r_items)
        g = QFormLayout()
        self.r_gold = _spin(0, ST.GOLD_MAX, rw.get('gold', 0), ' G')
        g.addRow('gold', self.r_gold)
        from editor2.core.conversation import describe_enemy_row, vanilla_enemies
        ch = [('— none —', None)] + [(f"★ {e.get('name') or e['id']} (your enemy)", e['id'])
                                     for e in doc.project_enemies()]
        ch += [(describe_enemy_row(r), r['eid']) for r in vanilla_enemies() if not r.get('boss')]
        self.r_monster = _combo(ch, rw.get('monster'), 30)
        g.addRow('a monster joins', self.r_monster)
        self.r_refresh = QCheckBox('refresh the room afterwards (a door this quest unlocks '
                                   'opens at once)')
        self.r_refresh.setChecked(bool(rw.get('refresh')))
        g.addRow('', self.r_refresh)
        f.addLayout(g)
        self.r_set = FlagList(doc, 'Also turn these flags ON:', rw.get('set'))
        self.r_clear = FlagList(doc, 'Turn these flags OFF:', rw.get('clear'))
        for fl_ in (self.r_set, self.r_clear):
            fl_.writes = True
            fl_._fill_pick()
            f.addWidget(fl_)
        f.addStretch(1)
        tabs.addTab(w, 'Reward')
        # -- words
        sc = QScrollArea()
        sc.setWidgetResizable(True)
        inner = QWidget()
        iv = QVBoxLayout(inner)
        self.texts = {}
        for key, label, default in QUEST_TEXT_LABELS:
            gb = QGroupBox(label)
            gv = QVBoxLayout(gb)
            cur = q.get(key)
            boxes = cur.get('boxes') if isinstance(cur, dict) else (
                doc._dlg_boxes(cur) if isinstance(cur, str) else None)
            if not boxes and default:
                from editor2.core import textenc as T
                try:
                    boxes = T.flow_boxes(default, first_box=True)
                except Exception:                                # noqa: BLE001
                    boxes = [[default]]
            tf = GameTextField(rom, boxes, empty_note='not said' if not default else 'empty')
            gv.addWidget(tf)
            iv.addWidget(gb)
            self.texts[key] = tf
        sc.setWidget(inner)
        tabs.addTab(sc, 'Words')
        self.problems = QLabel()
        self.problems.setWordWrap(True)
        v.addWidget(self.problems)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def _new_check(self):
        from editor2.app.encounters_tab import FlagTerms   # noqa: F401
        dlg = CheckDialog(self.doc, parent=self)
        if dlg.exec() != QDialog.Accepted:
            return
        name, spec = dlg.result()
        try:
            nm = self.doc.add_check(name, spec)
        except ValueError as ex:
            QMessageBox.warning(self, 'Story check', str(ex))
            return
        self.objective._add({'flag': nm})
        for r in range(self.objective.table.rowCount()):
            c = self.objective.table.cellWidget(r, 0)
            if c.findData(nm) < 0:
                c.addItem(f'{nm}  (story check)', nm)
        c = self.objective.table.cellWidget(self.objective.table.rowCount() - 1, 0)
        c.setCurrentIndex(c.findData(nm))

    def spec(self):
        out = {'name': self.name.text().strip() or self.q.get('id')}
        for key, tf in self.texts.items():
            val = tf.value()
            if val:
                out[key] = {'boxes': val}
        if self.requires.terms():
            out['requires'] = self.requires.terms()
        out['objective'] = self.objective.terms()
        if self.take.value():
            out['take'] = self.take.value()
        rw = {}
        if self.r_items.value():
            rw['items'] = self.r_items.value()
        if self.r_gold.value():
            rw['gold'] = self.r_gold.value()
        if self.r_monster.currentData() is not None:
            rw['monster'] = self.r_monster.currentData()
        if self.r_set.flags():
            rw['set'] = self.r_set.flags()
        if self.r_clear.flags():
            rw['clear'] = self.r_clear.flags()
        if self.r_refresh.isChecked():
            rw['refresh'] = True
        if rw:
            out['reward'] = rw
        return out

    def new_flags(self):
        return sorted(set(self.r_set.new_flags) | set(self.r_clear.new_flags)
                      | set(getattr(self.requires, 'new_flags', []))
                      | set(getattr(self.objective, 'new_flags', [])))

    def accept(self):
        bad = [f'{lab}: {tf.problem()}' for (key, lab, _d), tf in
               zip(QUEST_TEXT_LABELS, self.texts.values()) if tf.problem()]
        sp = self.spec()
        for key in ('offer', 'complete'):
            if not sp.get(key):
                bad.append(f'the {dict((k, l) for k, l, _d in QUEST_TEXT_LABELS)[key]} words '
                           'are needed')
        if not sp.get('objective'):
            bad.append('the objective needs at least one condition')
        try:
            ST.quest_steps(dict(sp, id=self.q.get('id') or 'q'), 'quest')
        except ST.StoryError as ex:
            bad.append(str(ex))
        if bad:
            QMessageBox.warning(self, 'Quest', '\n'.join(bad[:8]))
            return
        super().accept()


# ------------------------------------------------------------------ lock
class LockDialog(QDialog):
    """S129: the door / exit at a cell opens only while conditions hold."""

    def __init__(self, doc, rom, title='Lock this exit', parent=None):
        super().__init__(parent)
        from editor2.app.rooms.talk_editor import GameTextField
        self.doc = doc
        self.setWindowTitle(title)
        self.resize(700, 620)
        v = QVBoxLayout(self)
        intro = QLabel(
            'The exit stays SHUT until the conditions hold. The screen gets a second room '
            'state — the locked look: its cell is a wall (paint the closed door there) and '
            'pressing A in front of it shows the words below. While the conditions hold the '
            'room shows the open state.\n\nThe room picks its state each time it loads: to '
            'open it the moment a flag turns ON, add a "Refresh the room" step right after '
            '(a quest: "refresh the room afterwards").')
        intro.setWordWrap(True)
        v.addWidget(intro)
        v.addWidget(QLabel('<b>Open while</b> (all must hold — flags or story checks):'))
        self.terms = _terms_widget(doc, [])
        v.addWidget(self.terms)
        b = QPushButton('New story check…')
        b.clicked.connect(self._new_check)
        v.addWidget(b)
        v.addWidget(QLabel('<b>Locked words</b> (pressing A in front of it):'))
        from editor2.core import textenc as T
        self.words = GameTextField(rom, T.flow_boxes('It is locked.', first_box=True))
        v.addWidget(self.words, 1)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)

    def _new_check(self):
        dlg = CheckDialog(self.doc, parent=self)
        if dlg.exec() != QDialog.Accepted:
            return
        name, spec = dlg.result()
        try:
            nm = self.doc.add_check(name, spec)
        except ValueError as ex:
            QMessageBox.warning(self, 'Story check', str(ex))
            return
        self.terms._add({'flag': nm})
        c = self.terms.table.cellWidget(self.terms.table.rowCount() - 1, 0)
        if c.findData(nm) < 0:
            c.addItem(f'{nm}  (story check)', nm)
        c.setCurrentIndex(c.findData(nm))

    def accept(self):
        if not self.terms.terms():
            QMessageBox.warning(self, 'Lock', 'Add at least one condition.')
            return
        if self.words.problem():
            QMessageBox.warning(self, 'Lock', self.words.problem())
            return
        super().accept()

    def result(self):
        return self.terms.terms(), (self.words.value() or [['It is locked.']])


# ------------------------------------------------------------------ music rules
class MusicRulesDialog(QDialog):
    """S129: songs by flag for a room or a gate (the first rule whose conditions hold)."""

    def __init__(self, doc, rules, what, parent=None):
        super().__init__(parent)
        self.doc = doc
        self.setWindowTitle(f'Music by flag — {what}')
        self.resize(760, 560)
        self.rules = copy.deepcopy(rules or [])
        v = QVBoxLayout(self)
        intro = QLabel(f'{what} plays the song of the FIRST rule whose conditions all hold; '
                       'none holds = its usual song. The game picks it when the room / floor '
                       'loads (a flag turned ON in the room changes the song at the next '
                       'load — or a "Refresh the room" step).')
        intro.setWordWrap(True)
        v.addWidget(intro)
        h = QHBoxLayout()
        self.list = QListWidget()
        self.list.currentRowChanged.connect(self._pick)
        h.addWidget(self.list, 1)
        side = QVBoxLayout()
        for txt, fn in (('Add rule', self._add), ('Remove', self._remove),
                        ('▲', lambda: self._move(-1)), ('▼', lambda: self._move(1))):
            b = QPushButton(txt)
            b.clicked.connect(fn)
            side.addWidget(b)
        side.addStretch(1)
        h.addLayout(side)
        v.addLayout(h, 1)
        f = QFormLayout()
        self.song = _combo(song_choices(doc), None, 30)
        self.song.activated.connect(lambda _i: self._store())
        f.addRow('song', self.song)
        v.addLayout(f)
        v.addWidget(QLabel('while (all hold):'))
        self.terms_holder = QVBoxLayout()
        v.addLayout(self.terms_holder, 1)
        self.terms = None
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._fill()

    def _text(self, ru):
        cond = ' AND '.join(f"{t.get('flag')}{' OFF' if t.get('is') == 'clear' else ''}"
                            for t in ru.get('when') or []) or 'always'
        return f"{ru.get('song')}  while {cond}"

    def _fill(self, sel=0):
        self._row = -1                       # nothing to store while rebuilding
        self.list.blockSignals(True)
        self.list.clear()
        for ru in self.rules:
            self.list.addItem(self._text(ru))
        self.list.blockSignals(False)
        self._show(max(0, min(sel, len(self.rules) - 1)) if self.rules else -1)
        if self.rules:
            self.list.blockSignals(True)
            self.list.setCurrentRow(self._row)
            self.list.blockSignals(False)

    def _pick(self, row):
        self._store()
        self._show(row)

    def _show(self, row):
        if self.terms is not None:
            self.terms.hide()
            self.terms.setParent(None)
            self.terms.deleteLater()
            self.terms = None
        self._row = row
        if 0 <= row < len(self.rules):
            ru = self.rules[row]
            i = self.song.findData(ru.get('song'))
            if i < 0:
                self.song.addItem(str(ru.get('song')), ru.get('song'))
                i = self.song.count() - 1
            self.song.setCurrentIndex(i)
            self.terms = _terms_widget(self.doc, ru.get('when'))
            self.terms_holder.addWidget(self.terms)

    def _store(self):
        r = getattr(self, '_row', -1)
        if 0 <= r < len(self.rules):
            self.rules[r]['song'] = self.song.currentData()
            if self.terms is not None:
                self.rules[r]['when'] = self.terms.terms()
            self.list.item(r).setText(self._text(self.rules[r]))

    def _add(self):
        self._store()
        self.rules.append({'when': [], 'song': self.song.itemData(0)})
        self._fill(len(self.rules) - 1)

    def _remove(self):
        r = self.list.currentRow()
        if 0 <= r < len(self.rules):
            self._row = -1
            self.rules.pop(r)
            self._fill(r)

    def _move(self, d):
        self._store()
        r = self.list.currentRow()
        j = r + d
        if 0 <= r < len(self.rules) and 0 <= j < len(self.rules):
            self.rules[r], self.rules[j] = self.rules[j], self.rules[r]
            self._fill(j)

    def accept(self):
        self._store()
        if any(not ru.get('when') for ru in self.rules[:-1]):
            QMessageBox.warning(self, 'Music by flag', 'A rule with no condition always '
                                'holds — the rules after it would never play. Move it last.')
            return
        super().accept()

    def result(self):
        return self.rules


# ------------------------------------------------------------------ shop item sets
class ItemSetsDialog(QDialog):
    """S129: a shop's item sets — another list sold while conditions hold."""

    def __init__(self, doc, shop, label, parent=None):
        super().__init__(parent)
        self.doc, self.shop = doc, shop
        self.setWindowTitle(f'Item sets — {label}')
        self.resize(820, 600)
        self.sets = copy.deepcopy(doc.shop_sets(shop))
        v = QVBoxLayout(self)
        intro = QLabel(f'{label} sells the items of the FIRST set whose conditions all hold — '
                       'none holds = its own list (the Shops tab). The list is read each time '
                       'BUY opens, so a flag turned ON shows at once.')
        intro.setWordWrap(True)
        v.addWidget(intro)
        h = QHBoxLayout()
        self.list = QListWidget()
        self.list.currentRowChanged.connect(self._pick)
        h.addWidget(self.list, 1)
        side = QVBoxLayout()
        for txt, fn in (('Add set', self._add), ('Remove', self._remove),
                        ('▲', lambda: self._move(-1)), ('▼', lambda: self._move(1))):
            b = QPushButton(txt)
            b.clicked.connect(fn)
            side.addWidget(b)
        side.addStretch(1)
        h.addLayout(side)
        v.addLayout(h)
        f = QFormLayout()
        self.name = QLineEdit()
        self.name.editingFinished.connect(self._store)
        f.addRow('name', self.name)
        v.addLayout(f)
        self.holder = QVBoxLayout()
        v.addLayout(self.holder, 1)
        self.terms = None
        self.items = None
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._fill()

    def _fill(self, sel=0):
        self._row = -1                       # nothing to store while rebuilding
        self.list.blockSignals(True)
        self.list.clear()
        for s in self.sets:
            self.list.addItem(f"{s.get('name')}  ({len(s.get('items') or [])} items)")
        self.list.blockSignals(False)
        self._show(max(0, min(sel, len(self.sets) - 1)) if self.sets else -1)
        if self.sets:
            self.list.blockSignals(True)
            self.list.setCurrentRow(self._row)
            self.list.blockSignals(False)

    def _pick(self, row):
        self._store()
        self._show(row)

    def _show(self, row):
        while self.holder.count():
            w = self.holder.takeAt(0).widget()
            if w is not None and w not in (self.terms, self.items):
                w.hide()
                w.setParent(None)
                w.deleteLater()
        for w in (self.terms, self.items):
            if w is not None:
                w.hide()
                w.setParent(None)
                w.deleteLater()
        self.terms = self.items = None
        self._row = row
        if 0 <= row < len(self.sets):
            s = self.sets[row]
            self.name.setText(s.get('name') or '')
            self.holder.addWidget(QLabel('sold while (all hold):'))
            self.terms = _terms_widget(self.doc, s.get('when'))
            self.holder.addWidget(self.terms)
            self.items = ItemCountList([{'item': i, 'count': 1} for i in s.get('items') or []],
                                       max_rows=20)
            self.items.table.setHorizontalHeaderLabels(['item', '(one each)'])
            self.holder.addWidget(self.items)

    def _store(self):
        r = getattr(self, '_row', -1)
        if 0 <= r < len(self.sets):
            s = self.sets[r]
            s['name'] = self.name.text().strip() or s.get('name')
            if self.terms is not None:
                s['when'] = self.terms.terms()
            if self.items is not None:
                s['items'] = [x['item'] for x in self.items.value()]
            self.list.item(r).setText(f"{s.get('name')}  ({len(s.get('items') or [])} items)")

    def _add(self):
        self._store()
        self.sets.append({'name': f'{self.shop} set {len(self.sets) + 1}', 'when': [],
                          'items': [0x01]})
        self._fill(len(self.sets) - 1)

    def _remove(self):
        r = self.list.currentRow()
        if 0 <= r < len(self.sets):
            self._row = -1
            self.sets.pop(r)
            self._fill(r)

    def _move(self, d):
        self._store()
        r = self.list.currentRow()
        j = r + d
        if 0 <= r < len(self.sets) and 0 <= j < len(self.sets):
            self.sets[r], self.sets[j] = self.sets[j], self.sets[r]
            self._fill(j)

    def accept(self):
        self._store()
        for s in self.sets:
            if not s.get('when'):
                QMessageBox.warning(self, 'Item sets', f"“{s.get('name')}” needs a condition.")
                return
            if not s.get('items'):
                QMessageBox.warning(self, 'Item sets', f"“{s.get('name')}” has no items.")
                return
        super().accept()

    def result(self):
        return self.sets
