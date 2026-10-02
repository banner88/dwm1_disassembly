"""enemies_dialog.py — the project's own enemies (S101, ROADMAP P3.7b part 2).

A project enemy is one 25-byte enemy-stats row (bank $6B, EID 519 + its
position; MONSTER_DATA "Project enemy rows"): species, level, exp, the six
stats, AI weights, up to four skills, and JOINABILITY — 0 always joins,
1-6 sometimes (tier-scaled chance, bank $54 JoinDecision), 7 never.

JOIN VERSION (vanilla does it for every story boss: Dragon fights with
90 HP, joins as a 60 HP row): a second row the player gets instead of the
fought one — progression.enemies[].join_as, emitted as a fight->join
redirect row (bank $14 BossRedirectTableExt).

The dialog edits a scratch copy; `enemies()` is the new list, written by the
caller as ONE undo step.
"""

import copy

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (QComboBox, QDialog, QDialogButtonBox, QFormLayout,
                               QGridLayout, QGroupBox, QHBoxLayout, QInputDialog, QLabel,
                               QLineEdit, QListWidget, QMessageBox, QPushButton, QSpinBox,
                               QSplitter, QVBoxLayout, QWidget)

from editor2.core.conversation import (EnemiesMixin, JOIN_ALWAYS, JOIN_NEVER,
                                       describe_enemy_row, join_label, skill_names,
                                       species_names, vanilla_enemies)

STATS = ('hp', 'mp', 'atk', 'def', 'agl', 'int')


class EnemyScratch(EnemiesMixin):
    """EnemiesMixin over a deep copy of the document's enemy list."""

    def __init__(self, doc):
        self._doc = doc
        self.data = {'progression': {'enemies': copy.deepcopy(doc.project_enemies())}}

    def touch(self):
        pass

    def _slug(self, name):
        return self._doc._slug(name)

    def _unique_id(self, base, taken):
        return self._doc._unique_id(base, taken)


def vanilla_choices():
    """[(label, eid)] — story/gate bosses first, then every vanilla row."""
    rows = vanilla_enemies()
    boss = [r for r in rows if r.get('boss')]
    return ([(describe_enemy_row(r), r['eid']) for r in boss] +
            [(describe_enemy_row(r), r['eid']) for r in rows if not r.get('boss')])


class EnemiesDialog(QDialog):
    def __init__(self, doc, parent=None, select=None):
        super().__init__(parent)
        self.setWindowTitle('Project enemies')
        self.resize(820, 560)
        self.doc = doc
        self.x = EnemyScratch(doc)
        self._building = False
        v = QVBoxLayout(self)
        intro = QLabel('Enemies of your own (EID 519 and up), used by conversation Battle '
                       'steps. Start from a vanilla row and change what you like. A boss '
                       'that can join should get a weaker JOIN VERSION — the monster you '
                       'get instead of the one you fought (vanilla does this for every '
                       'story boss).')
        intro.setWordWrap(True)
        v.addWidget(intro)
        split = QSplitter(Qt.Horizontal)
        v.addWidget(split, 1)
        left = QWidget()
        lv = QVBoxLayout(left)
        lv.setContentsMargins(0, 0, 0, 0)
        self.list = QListWidget()
        self.list.currentRowChanged.connect(self._show)
        lv.addWidget(self.list, 1)
        row = QHBoxLayout()
        for txt, fn, tip in (('Add from vanilla…', self._add, 'Copy a vanilla enemy row'),
                             ('Remove', self._remove, ''),
                             ('Make join version', self._join_version,
                              'A weaker copy (stats halved, always joins) that the player '
                              'gets instead of this one')):
            b = QPushButton(txt)
            b.setToolTip(tip)
            b.clicked.connect(fn)
            row.addWidget(b)
        lv.addLayout(row)
        split.addWidget(left)
        right = QWidget()
        rv = QVBoxLayout(right)
        rv.setContentsMargins(0, 0, 0, 0)
        f = QFormLayout()
        self.eid = QLabel('')
        f.addRow('EID', self.eid)
        self.name = QLineEdit()
        self.name.editingFinished.connect(lambda: self._set('name', self.name.text().strip()
                                                            or None))
        f.addRow('name (editor only)', self.name)
        self.species = QComboBox()
        for sp, nm in sorted(species_names(self.doc.data).items()):
            self.species.addItem(f'{sp:3d} {nm}', sp)
        self.species.activated.connect(lambda _i: self._set('species',
                                                            self.species.currentData()))
        f.addRow('species', self.species)
        self.level = QSpinBox()
        self.level.setRange(1, 99)
        self.level.valueChanged.connect(lambda n: self._set('level', n))
        f.addRow('level', self.level)
        self.exp = QSpinBox()
        self.exp.setRange(0, 0xFFFF)
        self.exp.valueChanged.connect(lambda n: self._set('exp', n))
        f.addRow('exp reward', self.exp)
        g = QGridLayout()
        self.stat = {}
        for i, k in enumerate(STATS):
            sb = QSpinBox()
            sb.setRange(0, 0xFFFF)
            sb.valueChanged.connect(lambda n, kk=k: self._set(kk, n))
            self.stat[k] = sb
            g.addWidget(QLabel(k.upper()), i // 3, (i % 3) * 2)
            g.addWidget(sb, i // 3, (i % 3) * 2 + 1)
        f.addRow('stats', g)
        jr = QHBoxLayout()
        self.join = QComboBox()
        self.join.addItem('always joins', 'always')
        self.join.addItem('sometimes joins', 'sometimes')
        self.join.addItem('never joins', 'never')
        self.join.activated.connect(self._join_changed)
        jr.addWidget(self.join)
        self.tier = QSpinBox()
        self.tier.setRange(1, 6)
        self.tier.setPrefix('tier ')
        self.tier.setToolTip('Sometimes: 1 = most likely … 6 = least likely (bank $54 '
                             'JoinDecision; the vanilla table is per tier)')
        self.tier.valueChanged.connect(self._join_changed)
        jr.addWidget(self.tier)
        jr.addStretch(1)
        f.addRow('joins?', jr)
        self.join_as = QComboBox()
        self.join_as.activated.connect(self._join_as_changed)
        f.addRow('join version', self.join_as)
        sk = QHBoxLayout()
        self.skills = []
        try:                                   # S110: the project's skill names
            names = self.doc.skill_names_effective()
        except Exception:                      # noqa: BLE001
            names = skill_names()
        for i in range(4):
            c = QComboBox()
            c.setMinimumContentsLength(10)
            c.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
            c.addItem('—', None)
            for sid, nm in sorted(names.items()):
                c.addItem(f'{nm}', sid)
            c.activated.connect(lambda _i: self._skills_changed())
            self.skills.append(c)
            sk.addWidget(c)
        f.addRow('skills', sk)
        ai = QHBoxLayout()
        self.ai = []
        for i in range(4):
            sb = QSpinBox()
            sb.setRange(0, 255)
            sb.valueChanged.connect(lambda _n: self._ai_changed())
            self.ai.append(sb)
            ai.addWidget(sb)
        f.addRow('AI weights', ai)
        box = QGroupBox('Enemy')
        box.setLayout(f)
        rv.addWidget(box)
        self.note = QLabel('')
        self.note.setWordWrap(True)
        self.note.setStyleSheet('color:#e0b040;')
        rv.addWidget(self.note)
        rv.addStretch(1)
        split.addWidget(right)
        split.setStretchFactor(1, 1)
        self.form = box
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._fill(select)

    # ------------------------------------------------------------ list
    def enemies(self):
        return self.x.project_enemies()

    def _cur(self):
        i = self.list.currentRow()
        lst = self.enemies()
        return lst[i] if 0 <= i < len(lst) else None

    def _fill(self, select=None):
        cur = self._cur()
        sel = select if select is not None else (cur['id'] if cur else None)
        self.list.blockSignals(True)
        self.list.clear()
        row = 0
        for i, e in enumerate(self.enemies()):
            sp = species_names(self.doc.data).get(int(e.get('species', 0)), '?')
            j = f" → joins as {e['join_as']}" if e.get('join_as') else ''
            self.list.addItem(f"{self.x.project_eid(e)}  {e.get('name') or e['id']}  "
                              f"({sp} L{e.get('level')}, {join_label(e.get('joinability', 7))})"
                              + j)
            if e['id'] == sel:
                row = i
        self.list.blockSignals(False)
        if self.list.count():
            self.list.setCurrentRow(row)
        self._show(self.list.currentRow())

    def _show(self, _i):
        e = self._cur()
        self.form.setEnabled(e is not None)
        if e is None:
            self.eid.setText('')
            self.note.setText('No enemies yet — "Add from vanilla…".')
            return
        self._building = True
        self.eid.setText(f"{self.x.project_eid(e)}  (id {e['id']})")
        self.name.setText(e.get('name') or '')
        self.species.setCurrentIndex(max(0, self.species.findData(int(e.get('species', 0)))))
        self.level.setValue(int(e.get('level', 1)))
        self.exp.setValue(int(e.get('exp', 0)))
        for k in STATS:
            self.stat[k].setValue(int(e.get(k, 0)))
        j = int(e.get('joinability', JOIN_NEVER))
        self.join.setCurrentIndex(0 if j == JOIN_ALWAYS else 2 if j == JOIN_NEVER else 1)
        self.tier.setValue(min(6, max(1, j)) if j not in (JOIN_ALWAYS, JOIN_NEVER) else 3)
        self.tier.setEnabled(j not in (JOIN_ALWAYS, JOIN_NEVER))
        self.join_as.clear()
        self.join_as.addItem('— none (the fought row joins)', None)
        for o in self.enemies():
            if o is not e:
                self.join_as.addItem(f"{o.get('name') or o['id']}", o['id'])
        self.join_as.setCurrentIndex(max(0, self.join_as.findData(e.get('join_as'))))
        sk = list(e.get('skills') or [])
        for i, c in enumerate(self.skills):
            c.setCurrentIndex(max(0, c.findData(int(sk[i]) if i < len(sk) else None)))
        ai = list(e.get('ai_weights') or [0, 0, 0, 0])
        for i, sb in enumerate(self.ai):
            sb.setValue(int(ai[i]) if i < len(ai) else 0)
        self._building = False
        self._note(e)

    def _note(self, e):
        bits = []
        if int(e.get('joinability', 7)) != JOIN_NEVER and not e.get('join_as') \
                and int(e.get('hp', 0)) > 1023:
            bits.append('Joinable with more than 1023 HP and no join version: the monster '
                        'you get inherits these battle stats.')
        users = [o.get('name') or o['id'] for o in self.enemies() if o.get('join_as') == e['id']]
        if users:
            bits.append('This is the join version of ' + ', '.join(users) + '.')
        self.note.setText(' '.join(bits))

    # ------------------------------------------------------------ edits
    def _set(self, k, v):
        if self._building:
            return
        e = self._cur()
        if e is None:
            return
        self.x.update_enemy(e['id'], **{k: v})
        self._refresh_row(e)

    def _refresh_row(self, e):
        i = self.list.currentRow()
        sp = species_names(self.doc.data).get(int(e.get('species', 0)), '?')
        j = f" → joins as {e['join_as']}" if e.get('join_as') else ''
        self.list.item(i).setText(f"{self.x.project_eid(e)}  {e.get('name') or e['id']}  "
                                  f"({sp} L{e.get('level')}, "
                                  f"{join_label(e.get('joinability', 7))})" + j)
        self._note(e)

    def _join_changed(self, *_a):
        if self._building:
            return
        mode = self.join.currentData()
        self.tier.setEnabled(mode == 'sometimes')
        self._set('joinability', JOIN_ALWAYS if mode == 'always' else JOIN_NEVER
                  if mode == 'never' else self.tier.value())

    def _join_as_changed(self, _i):
        self._set('join_as', self.join_as.currentData())

    def _skills_changed(self):
        self._set('skills', [c.currentData() for c in self.skills
                             if c.currentData() is not None])

    def _ai_changed(self):
        self._set('ai_weights', [sb.value() for sb in self.ai])

    def _add(self):
        ch = vanilla_choices()
        if not ch:
            QMessageBox.warning(self, 'Add enemy', 'extracted/enemy_stats.json is missing.')
            return
        label, ok = QInputDialog.getItem(self, 'Add enemy', 'Start from vanilla row '
                                         '(story / gate bosses first):',
                                         [c[0] for c in ch], 0, False)
        if not ok:
            return
        eid = dict(ch)[label]
        name, ok = QInputDialog.getText(self, 'Add enemy', 'Name (editor only):')
        if not ok:
            return
        nid = self.x.add_enemy(copy_eid=eid, name=name.strip() or None)
        self._fill(nid)

    def _remove(self):
        e = self._cur()
        if e is None:
            return
        try:
            self.x.remove_enemy(e['id'])
        except (KeyError, ValueError) as ex:
            QMessageBox.warning(self, 'Remove enemy', str(ex))
            return
        for o in self.enemies():
            if o.get('join_as') == e['id']:
                o.pop('join_as', None)
        self._fill()

    def _join_version(self):
        e = self._cur()
        if e is None:
            return
        if e.get('join_as'):
            QMessageBox.information(self, 'Join version',
                                    f"{e.get('name') or e['id']} already joins as "
                                    f"{e['join_as']}.")
            return
        jid = self.x.make_join_version(e['id'])
        self._fill(jid)
