"""conversation_dialog.py — conversation trees (S101, ROADMAP P3.7b part 2).

Edits a `talk.steps` script (editor2/core/conversation.py; lowered by
project.Project._lower_steps, PROJECT_COMPILER §2.18) as a tree of STEPS:

  Say · Ask YES / NO (branches If YES / If NO, both rejoin) · If flags…
  (branches Then / Otherwise) · Turn flags ON / OFF · Battle (1-3 enemies;
  the steps after it run only after a WIN — a loss sends the player to the
  castle, as vanilla) · Helper takes the player away (the vanilla boss exit:
  the helper flies in, spins, may speak, and fades the player out to the
  destination) · Move the player · Stop here.

Measured S101 (PyBoy, user save): conversation → YES → battle → win → flag
set → helper flies in / spins / speaks → wavy warp to the Castle; a 2-enemy
battle; a fight that starts on arrival (the room's entry script).
"""

import copy

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox, QFormLayout,
                               QHBoxLayout, QLabel, QMenu, QMessageBox, QPushButton,
                               QSpinBox, QSplitter, QToolButton, QTreeWidget, QTreeWidgetItem,
                               QVBoxLayout, QWidget)

from editor2.app.rooms.talk_editor import BoxList, FlagList, analyse_box
from editor2.core.conversation import (CASTLE_THRONE, HELPER_SPRITE, STEP_KINDS, STEP_NAMES,
                                       ConversationMixin, describe_enemy_row, vanilla_enemies)

BRANCHES = {'ask': (('yes', 'If YES'), ('no', 'If NO')),
            'if': (('then', 'Then'), ('else', 'Otherwise'))}
KIND_TIPS = {
    'say': 'Text boxes.',
    'ask': 'Text whose last box asks YES / NO; each answer has its own steps, then both '
           'continue with the steps after the question.',
    'if': 'Checks flags (all must hold): Then steps, else Otherwise steps.',
    'set': 'Turns flags on.',
    'clear': 'Turns flags off.',
    'battle': '1-3 enemies. The steps after it run only after a WIN (a loss takes the player '
              'back to the castle, as in vanilla). Whether the monster may join is the '
              "enemy's own setting (Enemies…).",
    'helper': 'The vanilla boss exit: the helper (Warubou by default) flies in next to the player, spins, can say '
              'something (the text box at the top), then the screen fades and the player is taken '
              'to the destination — at the Castle optionally with the priest\'s heal or the '
              'King\'s speech. Nothing after it runs.',
    'move': 'Warps the player (the room reloads, so state rules pick the new state).',
    'end': 'Ends the conversation here.',
}


def step_kind(st):
    return next((k for k in STEP_KINDS if k in st), None)


def new_step(kind, doc, room, key):
    if kind == 'say':
        return {'say': {'boxes': [['...']]}}
    if kind == 'ask':
        return {'ask': {'boxes': [['Will you fight me?']]}, 'yes': [], 'no': []}
    if kind == 'if':
        return {'if': [], 'then': [], 'else': []}
    if kind in ('set', 'clear'):
        return {kind: []}
    if kind == 'battle':
        ens = doc.project_enemies() if doc is not None else []
        return {'battle': {'enemies': [ens[0]['id']] if ens else []}}
    if kind == 'helper':
        return {'helper': dict(CASTLE_THRONE)}     # lands beside the player
    if kind == 'move':
        mid = int(str(room['mapID']), 0) if room is not None else 0
        return {'move': {'dest': f'room:${mid:02X}', 'screen': int(key), 'x': 4, 'y': 4}}
    return {'end': True}


def spec_problems(spec, doc=None):
    """[text] — what keeps the conversation from compiling as intended."""
    out = []

    def boxes_bad(boxes, where):
        if not boxes or not any(any(ln for ln in b) for b in boxes):
            out.append(f'{where}: no text')
            return
        for bi, b in enumerate(boxes):
            p = analyse_box(bi, b)[0]
            if p:
                out.append(f'{where} box {bi + 1}: {p[0]}')

    def walk(steps, path):
        for i, st in enumerate(steps or []):
            k = step_kind(st)
            where = f'{path}{i + 1} {STEP_NAMES.get(k, "?")}'
            if k in ('say', 'ask'):
                boxes_bad((st[k] or {}).get('boxes'), where)
            elif k == 'if' and not st['if']:
                out.append(f'{where}: no flags to check')
            elif k in ('set', 'clear') and not st[k]:
                out.append(f'{where}: no flags')
            elif k == 'battle':
                n = len((st['battle'] or {}).get('enemies') or [])
                if not 1 <= n <= 3:
                    out.append(f'{where}: pick 1-3 enemies')
            elif k == 'helper':
                h = st['helper'] or {}
                if isinstance(h.get('say'), dict):
                    boxes_bad(h['say'].get('boxes'), where + ' (helper text)')
            if k in ('helper', 'move', 'end') and i != len(steps) - 1:
                out.append(f'{where}: the steps after it never run')
            for key, lab in BRANCHES.get(k, ()):
                walk(st.get(key), f'{path}{i + 1}.{lab}: ')
    walk(spec.get('steps'), '')
    if not spec.get('steps'):
        out.append('no steps')
    return out


def _dest_choices(doc):
    out = [('Castle — throne room (where vanilla bosses send you)', 'vanilla:$00')]
    if doc is not None:
        for r in doc.rooms:
            if r.get('placeholder'):
                continue
            mid = int(str(r['mapID']), 0)
            out.append((f'${mid:02X} {doc.room_name(r)}', f'room:${mid:02X}'))
    return out


class DestEditor(QWidget):
    """Destination room + screen + cell."""

    def __init__(self, doc, mv, on_change, parent=None):
        super().__init__(parent)
        self.mv, self.on_change = mv, on_change
        h = QHBoxLayout(self)
        h.setContentsMargins(0, 0, 0, 0)
        self.room = QComboBox()
        self.room.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.room.setMinimumContentsLength(18)
        for lab, d in _dest_choices(doc):
            self.room.addItem(lab, d)
        i = self.room.findData(mv.get('dest'))
        if i < 0:
            self.room.addItem(str(mv.get('dest')), mv.get('dest'))
            i = self.room.count() - 1
        self.room.setCurrentIndex(i)
        self.room.activated.connect(self._changed)
        h.addWidget(self.room, 1)
        self.sp = {}
        for k, hi in (('screen', 15), ('x', 9), ('y', 7)):
            sb = QSpinBox()
            sb.setRange(0, hi)
            sb.setValue(int(mv.get(k, 0)))
            sb.setPrefix(f'{k} ')
            sb.valueChanged.connect(self._changed)
            self.sp[k] = sb
            h.addWidget(sb)

    def _changed(self, *_a):
        self.mv['dest'] = self.room.currentData()
        for k, sb in self.sp.items():
            self.mv[k] = sb.value()
        self.on_change()


class ConversationDialog(QDialog):
    """spec() -> {'steps': [...], 'screen'?: n, 'on_arrival'?: True};
    new_flags() -> project flags to create; enemies() -> the (possibly
    edited) project enemy list, or None when Enemies… was not used."""

    def __init__(self, doc, rom=None, room=None, key=0, spec=None, title='Conversation',
                 entry=False, parent=None):
        super().__init__(parent)
        self.setWindowTitle(title)
        self.resize(1000, 700)
        self.doc, self.rom, self.room, self.key = doc, rom, room, key
        self.entry = entry
        self._spec = copy.deepcopy(spec) if spec else {'steps': []}
        if entry:
            self._spec['on_arrival'] = True
        self._new_flags = []
        self._enemies = None           # edited enemy list (Enemies…) or None
        self._pay = {}                 # tree item key -> ('step', lst, st) | ('branch', lst)
        self._n = 0
        v = QVBoxLayout(self)
        intro = QLabel('Steps run top to bottom. Ask and If have branches (select a branch '
                       'to add steps into it). After a Battle, the next steps run only when '
                       'the player WINS.')
        intro.setWordWrap(True)
        v.addWidget(intro)
        if entry:
            er = QHBoxLayout()
            er.addWidget(QLabel('Runs when the player arrives on'))
            self.scr = QComboBox()
            self.scr.addItem('every screen of this room', None)
            keys = doc.screen_keys(room) if room is not None else [0]
            for k in keys:
                self.scr.addItem(f'screen {k} only', int(k))
            self.scr.setCurrentIndex(max(0, self.scr.findData(self._spec.get('screen'))))
            self.scr.activated.connect(self._screen_changed)
            er.addWidget(self.scr)
            er.addStretch(1)
            v.addLayout(er)
            n2 = QLabel('It runs on EVERY arrival (also after a battle or a save load) — '
                        'start with "If flags…" so a finished fight does not start again.')
            n2.setWordWrap(True)
            n2.setStyleSheet('color:#e0b040;')
            v.addWidget(n2)
        split = QSplitter(Qt.Horizontal)
        v.addWidget(split, 1)
        left = QWidget()
        lv = QVBoxLayout(left)
        lv.setContentsMargins(0, 0, 0, 0)
        self.tree = QTreeWidget()
        self.tree.setHeaderHidden(True)
        self.tree.currentItemChanged.connect(lambda *_a: self._show_editor())
        lv.addWidget(self.tree, 1)
        row = QHBoxLayout()
        add = QToolButton()
        add.setText('+ Add step ▾')
        add.setPopupMode(QToolButton.InstantPopup)
        m = QMenu(add)
        for k in STEP_KINDS:
            a = m.addAction(STEP_NAMES[k])
            a.setToolTip(KIND_TIPS[k])
            a.triggered.connect(lambda _c=False, kk=k: self.add_step(kk))
        add.setMenu(m)
        row.addWidget(add)
        for txt, fn in (('▲', lambda: self._move(-1)), ('▼', lambda: self._move(1)),
                        ('Remove', self._remove)):
            b = QToolButton()
            b.setText(txt)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        lv.addLayout(row)
        split.addWidget(left)
        self.right = QWidget()
        self.rv = QVBoxLayout(self.right)
        self.rv.setContentsMargins(0, 0, 0, 0)
        split.addWidget(self.right)
        split.setStretchFactor(1, 2)
        split.setSizes([360, 640])
        self.problems = QLabel('')
        self.problems.setWordWrap(True)
        v.addWidget(self.problems)
        self.bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        self.bb.accepted.connect(self.accept)
        self.bb.rejected.connect(self.reject)
        v.addWidget(self.bb)
        self._editor = None
        self._rebuild()

    # ------------------------------------------------------------ results
    def spec(self):
        return copy.deepcopy(self._spec)

    def new_flags(self):
        return list(self._new_flags)

    def enemies(self):
        return self._enemies

    def enemy_name(self, ref):
        if self._enemies is not None:
            for e in self._enemies:
                if e.get('id') == ref:
                    return e.get('name') or e['id']
        return self.doc.enemy_name(ref) if self.doc is not None else str(ref)

    # ------------------------------------------------------------ tree
    def _key(self, payload):
        self._n += 1
        self._pay[self._n] = payload
        return self._n

    def _label(self, st):
        return ConversationMixin.describe_step(st, self.enemy_name)

    def _rebuild(self, select=None):
        self.tree.blockSignals(True)
        self.tree.clear()
        self._pay.clear()
        found = [None]

        def add(parent, steps):
            for st in steps:
                it = QTreeWidgetItem([self._label(st)])
                it.setData(0, Qt.UserRole, self._key(('step', steps, st)))
                it.setToolTip(0, KIND_TIPS.get(step_kind(st), ''))
                (parent.addChild(it) if parent is not None else self.tree.addTopLevelItem(it))
                if st is select:
                    found[0] = it
                for key, lab in BRANCHES.get(step_kind(st), ()):
                    lst = st.setdefault(key, [])
                    b = QTreeWidgetItem([lab])
                    b.setData(0, Qt.UserRole, self._key(('branch', lst)))
                    f = b.font(0)
                    f.setItalic(True)
                    b.setFont(0, f)
                    it.addChild(b)
                    if lst is select:
                        found[0] = b
                    add(b, lst)
        add(None, self._spec.setdefault('steps', []))
        self.tree.expandAll()
        self.tree.blockSignals(False)
        if found[0] is not None:
            self.tree.setCurrentItem(found[0])
        self._show_editor()
        self._validate()

    def _payload(self, it=None):
        it = it or self.tree.currentItem()
        if it is None:
            return None
        return self._pay.get(it.data(0, Qt.UserRole))

    def add_step(self, kind):
        st = new_step(kind, self._enemies_doc(), self.room, self.key)
        p = self._payload()
        if p is None:
            self._spec['steps'].append(st)
        elif p[0] == 'branch':
            p[1].append(st)
        else:
            lst, cur = p[1], p[2]
            lst.insert(next(i for i, x in enumerate(lst) if x is cur) + 1, st)
        self._rebuild(select=st)
        return st

    def _move(self, d):
        p = self._payload()
        if p is None or p[0] != 'step':
            return
        lst, st = p[1], p[2]
        i = next(i for i, x in enumerate(lst) if x is st)
        j = i + d
        if 0 <= j < len(lst):
            lst[i], lst[j] = lst[j], lst[i]
            self._rebuild(select=st)

    def _remove(self):
        p = self._payload()
        if p is None or p[0] != 'step':
            return
        lst, st = p[1], p[2]
        i = next(i for i, x in enumerate(lst) if x is st)
        lst.pop(i)
        self._rebuild(select=lst[min(i, len(lst) - 1)] if lst else None)

    def _refresh_label(self):
        it = self.tree.currentItem()
        p = self._payload(it)
        if it is not None and p and p[0] == 'step':
            it.setText(0, self._label(p[2]))
        self._validate()

    def _validate(self):
        probs = spec_problems(self._spec, self.doc)
        if probs:
            self.problems.setStyleSheet('color:#ff6060;')
            self.problems.setText('Fix: ' + ' · '.join(probs[:4])
                                  + (f' (+{len(probs) - 4} more)' if len(probs) > 4 else ''))
        else:
            self.problems.setStyleSheet('color:#80d080;')
            self.problems.setText('Ready.')
        self.bb.button(QDialogButtonBox.Ok).setEnabled(not probs)

    def _screen_changed(self, _i):
        d = self.scr.currentData()
        if d is None:
            self._spec.pop('screen', None)
        else:
            self._spec['screen'] = int(d)

    # ------------------------------------------------------------ editors
    def _clear_editor(self):
        while self.rv.count():
            w = self.rv.takeAt(0).widget()
            if w is not None:
                w.hide()
                w.setParent(None)
                w.deleteLater()

    def _show_editor(self):
        self._clear_editor()
        p = self._payload()
        if p is None:
            lab = QLabel('Add a step with "+ Add step".')
            self.rv.addWidget(lab)
            self.rv.addStretch(1)
            return
        if p[0] == 'branch':
            lab = QLabel('A branch: "+ Add step" adds steps into it.')
            self.rv.addWidget(lab)
            self.rv.addStretch(1)
            return
        st = p[2]
        k = step_kind(st)
        head = QLabel(f'<b>{STEP_NAMES[k]}</b> — {KIND_TIPS[k]}')
        head.setWordWrap(True)
        self.rv.addWidget(head)
        getattr(self, f'_ed_{k}')(st)

    def _flaglist(self, title, flags):
        fl = FlagList(self.doc, title, flags)
        fl.new_flags = list(self._new_flags)
        fl._fill_pick()

        def merge():
            for nm in fl.new_flags:
                if nm not in self._new_flags:
                    self._new_flags.append(nm)
        fl.changed.connect(merge)
        return fl

    def _boxes(self, holder, key, default):
        bl = BoxList(self.rom, (holder.get(key) or {}).get('boxes') or None,
                     first_default=default)

        def ch():
            holder[key] = {'boxes': bl.boxes()}
            self._refresh_label()
        bl.changed.connect(ch)
        return bl

    def _ed_say(self, st):
        self.rv.addWidget(self._boxes(st, 'say', '...'), 1)

    def _ed_ask(self, st):
        self.rv.addWidget(QLabel('The last box is the question (the YES / NO box opens '
                                 'under it).'))
        self.rv.addWidget(self._boxes(st, 'ask', 'Will you fight me?'), 1)

    def _ed_if(self, st):
        on = [t['flag'] for t in st['if'] if t.get('is', 'set') == 'set']
        off = [t['flag'] for t in st['if'] if t.get('is') == 'clear']
        a = self._flaglist('All of these must be ON:', on)
        b = self._flaglist('…and all of these OFF:', off)

        def ch():
            st['if'] = ([{'flag': f, 'is': 'set'} for f in a.flags()] +
                        [{'flag': f, 'is': 'clear'} for f in b.flags()])
            self._refresh_label()
        a.changed.connect(ch)
        b.changed.connect(ch)
        self.rv.addWidget(a)
        self.rv.addWidget(b)
        self.rv.addStretch(1)

    def _ed_flags(self, st, k):
        fl = self._flaglist('Flags:', st[k] if isinstance(st[k], list) else [st[k]])

        def ch():
            st[k] = fl.flags()
            self._refresh_label()
        fl.changed.connect(ch)
        self.rv.addWidget(fl)
        self.rv.addStretch(1)

    def _ed_set(self, st):
        self._ed_flags(st, 'set')

    def _ed_clear(self, st):
        self._ed_flags(st, 'clear')

    def _enemies_doc(self):
        """An object with project_enemies() reflecting pending Enemies… edits."""
        if self._enemies is None:
            return self.doc

        class _E:
            pass
        e = _E()
        e.project_enemies = lambda: self._enemies
        return e

    def _enemy_choices(self):
        out = []
        for e in (self._enemies if self._enemies is not None
                  else (self.doc.project_enemies() if self.doc is not None else [])):
            out.append((f"★ {e.get('name') or e['id']} (your enemy)", e['id']))
        rows = vanilla_enemies()
        out += [(describe_enemy_row(r), r['eid']) for r in rows if r.get('boss')]
        out += [(describe_enemy_row(r), r['eid']) for r in rows if not r.get('boss')]
        return out

    def _ed_battle(self, st):
        b = st['battle'] = st.get('battle') or {}
        ens = b.setdefault('enemies', [])
        f = QFormLayout()
        cnt = QSpinBox()
        cnt.setRange(1, 3)
        cnt.setValue(max(1, min(3, len(ens) or 1)))
        f.addRow('enemies', cnt)
        combos = []
        choices = self._enemy_choices()
        for i in range(3):
            c = QComboBox()
            c.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
            c.setMinimumContentsLength(30)
            for lab, d in choices:
                c.addItem(lab, d)
            cur = ens[i] if i < len(ens) else None
            j = c.findData(cur) if cur is not None else -1
            if cur is not None and j < 0:
                c.addItem(str(cur), cur)
                j = c.count() - 1
            c.setCurrentIndex(max(0, j))
            combos.append(c)
            f.addRow(f'enemy {i + 1}', c)

        def ch(*_a):
            n = cnt.value()
            for i, c in enumerate(combos):
                c.setEnabled(i < n)
            b['enemies'] = [combos[i].currentData() for i in range(n)]
            self._refresh_label()
        cnt.valueChanged.connect(ch)
        for c in combos:
            c.activated.connect(ch)
        w = QWidget()
        w.setLayout(f)
        self.rv.addWidget(w)
        ch()
        eb = QPushButton('Enemies…')
        eb.setToolTip('Your own enemies: stats, skills, always / sometimes / never joins, '
                      'a weaker join version')
        eb.clicked.connect(lambda: self._open_enemies(st))
        self.rv.addWidget(eb)
        note = QLabel('Vanilla rows keep their own join setting. For a boss that can join, '
                      'make your own enemy and give it a join version. With 2-3 enemies, '
                      'the one that may join is the LAST one knocked out (as in vanilla).')
        note.setWordWrap(True)
        note.setStyleSheet('color:#aaa;')
        self.rv.addWidget(note)
        self.rv.addStretch(1)

    def _open_enemies(self, st):
        from editor2.app.enemies_dialog import EnemiesDialog
        dlg = EnemiesDialog(self.doc, parent=self)
        if self._enemies is not None:
            dlg.x.data['progression']['enemies'] = copy.deepcopy(self._enemies)
            dlg._fill()
        if dlg.exec() == QDialog.Accepted:
            self._enemies = copy.deepcopy(dlg.enemies())
            ids = {e['id'] for e in self._enemies}
            self._drop_missing(ids)
            self._rebuild(select=st)

    def _drop_missing(self, ids):
        """Battle steps naming a removed project enemy lose that entry."""
        def walk(steps):
            for s in steps or []:
                if 'battle' in s:
                    s['battle']['enemies'] = [e for e in s['battle'].get('enemies') or []
                                              if not isinstance(e, str) or e in ids]
                for k in ('yes', 'no', 'then', 'else'):
                    walk(s.get(k))
        walk(self._spec.get('steps'))

    def _ed_helper(self, st):
        from PySide6.QtWidgets import QGroupBox
        from editor2.core.conversation import CASTLE_DEST, KING_SPEECHES, SPEECH_NOTES
        h = st['helper'] = st.get('helper') or {}
        # 1. what the helper says (S101 r3: user "where is the conversation tab?
        #    I sometimes want it to say something") — first, and visible
        says = QGroupBox('Warubou says something first (tick to add text)')
        says.setCheckable(True)
        says.setChecked(isinstance(h.get('say'), dict))
        sv = QVBoxLayout(says)
        holder = {'say': h.get('say') if isinstance(h.get('say'), dict)
                  else {'boxes': [["Let's go home!"]]}}
        bl = self._boxes(holder, 'say', "Let's go home!")
        bl.setMinimumHeight(150)
        sv.addWidget(bl)

        def sync():
            if says.isChecked():
                h['say'] = holder['say']
            else:
                h.pop('say', None)
            self._refresh_label()
        bl.changed.connect(sync)
        says.toggled.connect(lambda on: (bl.setVisible(on), sync()))
        bl.setVisible(says.isChecked())
        self.rv.addWidget(says, 1)
        # 2. where to, and what happens there
        f = QFormLayout()
        dest = DestEditor(self.doc, h, lambda: (castle_state(), self._refresh_label()))
        f.addRow('takes the player to', dest)
        cr = QHBoxLayout()
        castle = QComboBox()
        castle.addItem('nothing happens', 'none')
        castle.addItem('the priest blesses + heals the party (vanilla gate return)', 'heal')
        castle.addItem("the King's speech after a gate boss (vanilla)", 'king')
        castle.setCurrentIndex(max(0, castle.findData(h.get('castle') or 'none')))
        cr.addWidget(castle)
        speech = QComboBox()
        for code, name in KING_SPEECHES:
            speech.addItem(name + ('  ⚠' if code in SPEECH_NOTES else ''), code)
            if code in SPEECH_NOTES:
                speech.setItemData(speech.count() - 1, SPEECH_NOTES[code], Qt.ToolTipRole)
        speech.setCurrentIndex(max(0, speech.findData(int(str(h.get('king_speech', 0x31)), 0)
                                                      if isinstance(h.get('king_speech'), str)
                                                      else int(h.get('king_speech', 0x31)))))
        speech.setToolTip('Which gate the King talks about. Only this speech is chosen — no '
                          'story flag changes (measured for every speech).')
        cr.addWidget(speech, 1)
        cw = QWidget()
        cw.setLayout(cr)
        f.addRow('at the Castle', cw)

        def castle_state():
            at_castle = str(h.get('dest')) == 'vanilla:$00'
            castle.setEnabled(at_castle)
            if not at_castle:
                h.pop('castle', None)
                h.pop('king_speech', None)
            speech.setEnabled(at_castle and castle.currentData() == 'king')

        def castle_ch(_i=None):
            ev = castle.currentData()
            if ev == 'none':
                h.pop('castle', None)
                h.pop('king_speech', None)
            else:
                h['castle'] = ev
                h.update(CASTLE_DEST)           # the events expect the throne spawn
                i = dest.room.findData(CASTLE_DEST['dest'])
                dest.room.setCurrentIndex(max(0, i))
                for k in ('screen', 'x', 'y'):
                    dest.sp[k].blockSignals(True)
                    dest.sp[k].setValue(CASTLE_DEST[k])
                    dest.sp[k].blockSignals(False)
                if ev == 'king':
                    h['king_speech'] = speech.currentData()
                else:
                    h.pop('king_speech', None)
            speech.setEnabled(ev == 'king')
            self._refresh_label()
        castle.activated.connect(castle_ch)
        speech.activated.connect(lambda _i: castle_ch())
        castle_state()
        beside = QCheckBox('lands next to the player — on their left, turned to them '
                           '(on their right at a screen\'s left edge)')
        beside.setChecked(not isinstance(h.get('land'), dict))
        f.addRow('landing', beside)
        lr = QHBoxLayout()
        sps = []
        land0 = h.get('land') if isinstance(h.get('land'), dict) else {'x': 4, 'y': 3}
        for k, hi in (('x', 9), ('y', 7)):
            sb = QSpinBox()
            sb.setRange(0, hi)
            sb.setValue(int(land0.get(k, 4 if k == 'x' else 3)))
            sb.setPrefix(f'{k} ')
            lr.addWidget(sb)
            sps.append((k, sb))

        def land_ch(*_a):
            if beside.isChecked():
                h.pop('land', None)
            else:
                h['land'] = {k: sb.value() for k, sb in sps}
            for _k, sb in sps:
                sb.setEnabled(not beside.isChecked())
            self._refresh_label()
        for _k, sb in sps:
            sb.valueChanged.connect(land_ch)
        beside.toggled.connect(land_ch)
        lr.addStretch(1)
        lw = QWidget()
        lw.setLayout(lr)
        lw.setToolTip('A fixed cell of the screen instead (the helper then faces right).')
        f.addRow('or this cell', lw)
        for _k, sb in sps:
            sb.setEnabled(not beside.isChecked())
        spb = QToolButton()
        spb.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)

        def show_sprite():
            from PySide6.QtGui import QIcon
            from editor2.app.rooms.canvas import SpriteCache
            sid = int(str(h.get('sprite', HELPER_SPRITE)), 0) if isinstance(
                h.get('sprite', HELPER_SPRITE), str) else int(h.get('sprite', HELPER_SPRITE))
            pm = SpriteCache.get(sid)
            spb.setIcon(QIcon(pm.scaled(32, 32)) if pm is not None else QIcon())
            spb.setText(f'${sid:02X}' + ('  Warubou (default)' if sid == HELPER_SPRITE else
                                         '  Watabou (vanilla)' if sid == 0x21 else ''))

        def pick():
            from editor2.app.rooms.npc_panel import SpritePicker
            dlg = SpritePicker(current=h.get('sprite', HELPER_SPRITE), parent=self,
                               monsters=False)
            if dlg.exec() == QDialog.Accepted and isinstance(dlg.value, int):
                if dlg.value == HELPER_SPRITE:
                    h.pop('sprite', None)
                else:
                    h['sprite'] = dlg.value
                show_sprite()
        spb.clicked.connect(pick)
        show_sprite()
        f.addRow('helper sprite', spb)
        w = QWidget()
        w.setLayout(f)
        self.rv.addWidget(w)

    def _ed_move(self, st):
        mv = st['move'] = st.get('move') or {}
        self.rv.addWidget(DestEditor(self.doc, mv, self._refresh_label))
        self.rv.addStretch(1)

    def _ed_end(self, st):
        self.rv.addStretch(1)

    def accept(self):
        probs = spec_problems(self._spec, self.doc)
        if probs:
            QMessageBox.warning(self, 'Conversation', '\n'.join(probs[:10]))
            return
        super().accept()
