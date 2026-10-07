"""flags_tab.py — the Progression & Flags tab (S124, ROADMAP P3.14a; EDITOR_DESIGN §5.7).

Three pages over editor2/core/flag_index.py (headless):

* **Flags** — every flag of the game being made: your flags (named, each with a
  FIXED number — S124 pins them, so renaming or deleting one never renumbers the
  others and old saves keep their meaning), the gates' and worlds' "cleared"
  flags, the Milly hook's, and the original game's flags your rooms check. A flag
  shows what turns it ON / OFF and everything that checks it — each line in words
  with **show**: the place in the side panel on the right (S124 r3 — the room
  screen in its state with the NPC outlined, your NPC names, Name…, Open…). Your flags: a note, Rename… (every use follows), Renumber…, Delete.
  "Every flag of the original game" lists the game's 332 with where the game sets
  and checks them (read-only).
* **Triggers** — every "When … → …" of the project, grouped by place: room
  states, NPCs shown / coloured by flags, battles, gate-floor rooms, cutscene
  starts, the If steps of conversations and cutscenes, the branches of copied
  game scripts.
* **Story** (S129, ROADMAP P3.14b/c) — the story spine (milestones in story
  order: "says by progress" branches and "reached" checks follow it) and the
  quests (each given by an NPC — make one on the Rooms tab: an NPC → Quest…).
  Story checks (questions the game answers: an item carried, gold, monsters
  owned…) are listed with the flags (their own group) — New story check….
* **Problems** — checks waiting for a flag nothing turns ON, flags only the
  original game turns ON, unknown flag names, unused flags, numbers the game
  also uses ($0158), flags that are not saved.

Edits are SnapshotCommands (one undo step each). The index is rebuilt on the
next show after any change (0.1 s on a real project).
"""

import os

from PySide6.QtCore import Qt, QTimer, Signal
from PySide6.QtWidgets import (QCheckBox, QComboBox, QHBoxLayout, QInputDialog, QLabel,
                               QLineEdit, QListWidget, QListWidgetItem, QMessageBox, QPushButton, QSplitter, QTabWidget,
                               QTextBrowser, QTreeWidget, QTreeWidgetItem, QVBoxLayout,
                               QWidget)

from editor2.app.rooms import commands as C
from editor2.core import flag_index as FI

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

GROUPS = [('project', 'Your flags'),
          ('check', 'Story checks — questions the game answers (read-only)'),
          ('gate', 'Gates and worlds cleared'),
          ('hook', 'The Milly hook'), ('game_used', "The original game's flags your rooms check"),
          ('game', "Every other flag of the original game (read-only)")]

SHOW_MINE, SHOW_PROBLEMS, SHOW_ALL = range(3)

TRIGGER_KINDS = [('', 'Every kind'), ('state_rule', 'Room states'),
                 ('npc', 'NPCs shown / coloured, portal swirls'),
                 ('cutscene', 'Cutscenes'), ('talk', 'Conversations and talks'),
                 ('battles', 'Battles'), ('gate_room', 'Rooms on gate floors'),
                 ('script', 'Copied game scripts'), ('quest', 'Quests (legacy)'),
                 ('check', 'Story checks'), ('milestone', 'Story spine (says by progress)'),
                 ('music', 'Music by flag'), ('shop_set', 'Shop item sets')]
TRIGGER_KIND_OF = {'npc_shown': 'npc', 'npc_colour': 'npc', 'swirl': 'npc',
                   'cutscene_start': 'cutscene', 'cutscene': 'cutscene',
                   'conversation': 'talk', 'talk': 'talk', 'room_battles': 'battles',
                   'gate_battles': 'battles', 'prelude': 'script'}

LEVEL_MARK = {'error': '✖', 'warn': '⚠', 'info': 'ℹ'}


def _esc(s):
    return (str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))


class ProgressionTab(QWidget):
    navigate = Signal(dict)              # a use's place (MainWindow routes it)

    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.fi = None
        self._cat = None
        self._stale = True
        self._pending = False
        self._navs = {}
        self.cur = None                  # the shown flag number
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        self.outer = QSplitter(Qt.Horizontal)
        v.addWidget(self.outer)
        self.pages = QTabWidget()
        self.outer.addWidget(self.pages)
        self.pages.addTab(self._flags_page(), 'Flags')
        self.pages.addTab(self._triggers_page(), 'Triggers')
        self.pages.addTab(self._problems_page(), 'Problems')
        self.pages.addTab(self._story_page(), 'Story')
        # S124 r3: "show" opens the place HERE, in a panel on the right (user: "rather
        # than moving to a totally different tab"); its Open… button still goes there
        from editor2.app.place_panel import PlacePanel
        self.place_panel = PlacePanel(session)
        self.place_panel.setVisible(False)
        self.place_panel.navigate.connect(self.navigate.emit)
        self.outer.addWidget(self.place_panel)
        self.outer.setStretchFactor(0, 1)
        self.outer.setSizes([900, 380])
        self.s.structureChanged.connect(self._changed)

    # ------------------------------------------------------------ pages
    def _flags_page(self):
        w = QWidget()
        h = QHBoxLayout(w)
        split = QSplitter(Qt.Horizontal)
        h.addWidget(split)
        left = QWidget()
        lv = QVBoxLayout(left)
        lv.setContentsMargins(0, 0, 0, 0)
        row = QHBoxLayout()
        self.b_new = QPushButton('New flag…')
        self.b_new.clicked.connect(self._new_flag)
        row.addWidget(self.b_new)
        self.b_new_check = QPushButton('New story check…')
        self.b_new_check.setToolTip('A question the game answers — an item carried, gold, '
                                    'monsters owned, a level… — usable wherever a flag is '
                                    'checked (S129)')
        self.b_new_check.clicked.connect(self._new_check)
        row.addWidget(self.b_new_check)
        self.show_box = QComboBox()
        self.show_box.addItem("Your game's flags", SHOW_MINE)
        self.show_box.addItem('Only flags with a problem', SHOW_PROBLEMS)
        self.show_box.addItem('Every flag of the original game too', SHOW_ALL)
        self.show_box.currentIndexChanged.connect(lambda _i: self._fill_flags())
        row.addWidget(self.show_box, 1)
        lv.addLayout(row)
        self.search = QLineEdit()
        self.search.setPlaceholderText('Find a flag (name, number, note, place)…')
        self.search.textChanged.connect(lambda _t: self._fill_flags())
        lv.addWidget(self.search)
        self.tree = QTreeWidget()
        self.tree.setHeaderLabels(['Flag', 'Number', 'Turned ON by', 'Checked by'])
        self.tree.headerItem().setToolTip(2, 'Places in your game (in brackets: in the '
                                          'original game, for its own flags)')
        self.tree.headerItem().setToolTip(3, self.tree.headerItem().toolTip(2))
        self.tree.setColumnWidth(0, 260)
        self.tree.setColumnWidth(1, 60)
        self.tree.setColumnWidth(2, 90)
        self.tree.currentItemChanged.connect(self._picked)
        lv.addWidget(self.tree, 1)
        self.pool = QLabel()
        self.pool.setStyleSheet('color: gray')
        lv.addWidget(self.pool)
        split.addWidget(left)

        right = QWidget()
        rv = QVBoxLayout(right)
        rv.setContentsMargins(0, 0, 0, 0)
        self.title = QLabel()
        self.title.setTextFormat(Qt.RichText)
        self.title.setWordWrap(True)
        rv.addWidget(self.title)
        nrow = QHBoxLayout()
        nrow.addWidget(QLabel('Note:'))
        self.note = QLineEdit()
        self.note.setPlaceholderText('What this flag means in your game (for you — not in the ROM)')
        self.note.editingFinished.connect(self._note_done)
        nrow.addWidget(self.note, 1)
        rv.addLayout(nrow)
        brow = QHBoxLayout()
        self.b_edit = QPushButton('Edit…')
        self.b_edit.setToolTip('Change what the story check asks')
        self.b_edit.clicked.connect(self._edit_check)
        self.b_edit.setVisible(False)
        brow.addWidget(self.b_edit)
        self.b_rename = QPushButton('Rename…')
        self.b_rename.clicked.connect(self._rename)
        self.b_renumber = QPushButton('Renumber…')
        self.b_renumber.clicked.connect(self._renumber)
        self.b_delete = QPushButton('Delete')
        self.b_delete.clicked.connect(self._delete)
        for b in (self.b_rename, self.b_renumber, self.b_delete):
            brow.addWidget(b)
        brow.addStretch(1)
        rv.addLayout(brow)
        self.detail = QTextBrowser()
        self.detail.setOpenLinks(False)
        self.detail.anchorClicked.connect(self._anchor)
        rv.addWidget(self.detail, 1)
        split.addWidget(right)
        split.setStretchFactor(1, 1)
        split.setSizes([520, 700])
        return w

    def _triggers_page(self):
        w = QWidget()
        v = QVBoxLayout(w)
        row = QHBoxLayout()
        self.t_kind = QComboBox()
        for k, label in TRIGGER_KINDS:
            self.t_kind.addItem(label, k)
        self.t_kind.currentIndexChanged.connect(lambda _i: self._fill_triggers())
        row.addWidget(self.t_kind)
        self.t_search = QLineEdit()
        self.t_search.setPlaceholderText('Find (a flag, a room, words)…')
        self.t_search.textChanged.connect(lambda _t: self._fill_triggers())
        row.addWidget(self.t_search, 1)
        self.t_copied = QCheckBox('Show copied game scripts')
        self.t_copied.setChecked(True)
        self.t_copied.toggled.connect(lambda _b: self._fill_triggers())
        row.addWidget(self.t_copied)
        v.addLayout(row)
        self.t_tree = QTreeWidget()
        self.t_tree.setHeaderLabels(['When … → then', 'Kind'])
        self.t_tree.setColumnWidth(0, 900)
        self.t_tree.setWordWrap(True)
        self.t_tree.itemDoubleClicked.connect(self._trigger_go)
        v.addWidget(self.t_tree, 1)
        hint = QLabel('Double-click a line to show its place on the right. A room checks its flags each '
                      'time it loads; a conversation or cutscene when it runs.')
        hint.setStyleSheet('color: gray')
        hint.setWordWrap(True)
        v.addWidget(hint)
        return w

    def _problems_page(self):
        w = QWidget()
        v = QVBoxLayout(w)
        self.p_tree = QTreeWidget()
        self.p_tree.setHeaderLabels(['', 'Problem'])
        self.p_tree.setColumnWidth(0, 30)
        self.p_tree.setWordWrap(True)
        self.p_tree.itemDoubleClicked.connect(self._problem_go)
        v.addWidget(self.p_tree, 1)
        hint = QLabel('Double-click a problem to see its flag. ✖ stops the build · ⚠ will '
                      'not work as written in the game · ℹ for your information.')
        hint.setStyleSheet('color: gray')
        hint.setWordWrap(True)
        v.addWidget(hint)
        return w

    # ------------------------------------------------------------ model
    def catalogue(self):
        if self._cat is None:
            p = self.s.settings.value('rom/path') or os.path.join(REPO, 'data',
                                                                  'DWM-original.gbc')
            if p and os.path.exists(p):
                from editor2.core.cutscenes import Catalogue
                self._cat = Catalogue(open(p, 'rb').read())
            else:
                self._cat = False
        return self._cat or None

    def _changed(self):
        self._stale = True
        if self.isVisible() and not self._pending:
            self._pending = True
            QTimer.singleShot(0, self.refresh)

    def showEvent(self, ev):
        super().showEvent(ev)
        if self._stale:
            QTimer.singleShot(0, self.refresh)

    def refresh(self):
        self._pending = False
        self._stale = False
        self.fi = FI.FlagIndex(self.s.doc.data, repo=REPO, catalogue=self.catalogue())
        self.problems = self.fi.problems()
        self._prob_by_idx = {}
        for p in self.problems:
            idxs = {p.idx} if p.idx is not None else {u.idx for u in p.uses}
            for i in idxs:
                self._prob_by_idx.setdefault(i, []).append(p)
        self._fill_flags()
        self._fill_triggers()
        self._fill_problems()
        self._fill_story()
        self.place_panel.refresh()           # names may have changed
        used, cap = self.s.doc.flag_pool()
        self.pool.setText(f'{used} of {cap} named flags used · numbers are fixed (a '
                          'rename or delete never moves another flag)')

    # ------------------------------------------------------------ Flags page
    def _group_of(self, f):
        if f.kind in ('project', 'quest'):
            return 'project'
        if f.kind in ('gate', 'hook', 'check'):
            return f.kind
        return 'game_used' if self.fi.project_relevant(f) else 'game'

    def _flag_text(self, f):
        if f.kind in ('project', 'quest'):
            return f.name + ('  (quest)' if f.kind == 'quest' else '')
        if f.kind == 'game':
            return f.label or 'game flag'
        return f.name

    def _fill_flags(self):
        if self.fi is None:
            return
        keep = self.cur
        mode = self.show_box.currentData()
        q = self.search.text().strip().lower()
        self.tree.blockSignals(True)
        self.tree.clear()
        groups = {}
        for key, label in GROUPS:
            if key == 'game' and mode != SHOW_ALL:
                continue
            it = QTreeWidgetItem([label])
            f0 = it.font(0)
            f0.setBold(True)
            it.setFont(0, f0)
            it.setFlags(Qt.ItemIsEnabled)
            groups[key] = it
        pick = None
        for f in sorted(self.fi.flags.values(), key=lambda f: (f.kind not in ('project', 'quest'),
                                                               f.name.lower() if f.kind in
                                                               ('project', 'quest') else '',
                                                               f.idx)):
            g = self._group_of(f)
            if g not in groups:
                continue
            probs = self._prob_by_idx.get(f.idx, [])
            if mode == SHOW_PROBLEMS and not [p for p in probs if p.level != 'info']:
                continue
            if q:
                hay = ' '.join([f.name, f.label, f.comment, FI.flag_number(f.idx),
                                f'{f.idx:04x}'] + [u.where + ' ' + u.what for u in f.uses]).lower()
                if q not in hay:
                    continue
            # the counts are YOUR game's (the original game's are in the details);
            # a flag only the game uses shows the game's counts in brackets
            mine = [u for u in f.uses if u.source != 'game'] or None
            src = mine or f.uses
            ons = len([u for u in src if u.role == FI.ON])
            tests = len([u for u in src if u.role == FI.TEST])
            mark = ''
            if probs:
                lv = min(probs, key=lambda p: ['error', 'warn', 'info'].index(p.level)).level
                mark = LEVEL_MARK[lv] + ' '
            fmt = (lambda n: str(n) if n else '—') if mine else \
                (lambda n: f'({n})' if n else '—')
            it = QTreeWidgetItem([mark + self._flag_text(f), FI.flag_number(f.idx),
                                  fmt(ons), fmt(tests)])
            it.setData(0, Qt.UserRole, f.idx)
            if f.comment:
                it.setToolTip(0, f.comment)
            groups[g].addChild(it)
            if f.idx == keep:
                pick = it
        bad = [u for u in self.fi.unresolved()]
        if bad and 'project' in groups:
            for u in bad:
                it = QTreeWidgetItem([f'✖ {u.ref}  (no such flag)', '—', '', ''])
                it.setData(0, Qt.UserRole, ('bad', id(u)))
                groups['project'].addChild(it)
        for key, _l in GROUPS:
            it = groups.get(key)
            if it is None:
                continue
            it.setText(0, f'{it.text(0)} ({it.childCount()})')
            self.tree.addTopLevelItem(it)
            it.setExpanded(key != 'game' or bool(q))
        self.tree.blockSignals(False)
        if pick is None and groups.get('project') and groups['project'].childCount():
            pick = groups['project'].child(0)
        if pick is not None:
            self.tree.setCurrentItem(pick)
            self._picked(pick)
        else:
            self._show_flag(None)

    def _picked(self, it, _prev=None):
        if it is None:
            return
        d = it.data(0, Qt.UserRole)
        if isinstance(d, int):
            self._show_flag(d)
        elif isinstance(d, tuple) and d[0] == 'bad':
            u = next((u for u in self.fi.unresolved() if id(u) == d[1]), None)
            self._show_bad(u)

    def select_flag(self, idx):
        """Show flag `idx` (other pages / tabs)."""
        self.pages.setCurrentIndex(0)
        if self.show_box.currentData() == SHOW_PROBLEMS and not self._prob_by_idx.get(idx):
            self.show_box.setCurrentIndex(0)
        f = self.fi.flags.get(idx)
        if f is not None and self._group_of(f) == 'game' and \
                self.show_box.currentData() != SHOW_ALL:
            self.show_box.setCurrentIndex(self.show_box.findData(SHOW_ALL))
        self.search.setText('')
        self.cur = idx
        self._fill_flags()

    def _uses_html(self, uses, verb):
        """S124 r2 (user: "it is NOT clear how the progression goes … Looks like it just
        randomly turns on by a million things"): ONE entry per who + where (an NPC's
        script, a cutscene, a room rule), its branches folded under it with WHEN each
        one happens."""
        out = []
        for head, g in self.fi.groups(uses):
            n = len(self._navs)
            places = []
            for u in g:                          # every place of the entry's branches
                for pl in (u.places or ([u.nav] if u.nav else [])):
                    if pl and pl not in places:
                        places.append(pl)
            self._navs[n] = (places, verb)
            go = (f' <a href="go:{n}">show</a>' + (f' <span style="color:gray">'
                  f'({len(places)} places)</span>' if len(places) > 1 else '')) if places else ''
            src = {'engine': ' <i>(the editor\'s engine)</i>'}.get(head.source, '')
            dead = ' <i>— this script is used by no room, so it never runs</i>' \
                if not head.runs else ''
            who = _esc(head.who) if head.who else ''
            title = (f'<b>{who}</b> <span style="color:gray">— {_esc(head.where)}</span>'
                     if who else f'<b>{_esc(head.where)}</b>')
            lines = []
            if head.role == FI.TEST:
                for u in g:
                    want = 'ON' if u.want == 'set' else 'OFF'
                    then = u.trigger.then if u.trigger else u.what
                    when = f'<i>{_esc(u.when)}:</i> ' if u.when and u.when != 'always' else ''
                    lines.append(f'{when}while <b>{want}</b> → {_esc(then)}')
            else:
                whens = []
                for u in g:
                    w = u.when or (u.what if not head.who else '')
                    if w and w not in whens:
                        whens.append(w)
                if len(g) > 1:
                    lines.append(f'in {len(g)} of its branches: ' +
                                 ' · '.join(_esc(w) for w in whens) if whens else
                                 f'in {len(g)} places')
                elif whens:
                    lines.append(_esc(whens[0]))
            body = title + src + dead + go
            if len(lines) == 1:
                body += '<br>' + lines[0]
            elif lines:
                body += '<ul>' + ''.join(f'<li>{x}</li>' for x in lines) + '</ul>'
            out.append(f'<li>{body}</li>')
        return f'<h4>{verb}</h4><ul>' + ''.join(out) + '</ul>' if out else ''

    def _show_flag(self, idx):
        self.cur = idx
        self._navs = {}
        f = self.fi.flags.get(idx) if (self.fi and idx is not None) else None
        own = f is not None and f.kind in ('project', 'quest')
        chk = f is not None and f.kind == 'check'
        for b in (self.b_rename, self.b_delete):
            b.setEnabled(own or chk)
        self.b_renumber.setEnabled(own)
        self.b_renumber.setVisible(not chk)
        self.b_edit.setVisible(chk)
        self.note.setEnabled(own or chk)
        self.note.blockSignals(True)
        cm = ((self.s.doc.check(f.name) or {}).get('comment') or '') if chk else \
            (f.comment if own else '')
        self.note.setText(cm)
        self.note.blockSignals(False)
        if f is None:
            self.title.setText('<h2>No flag</h2>')
            self.detail.setHtml('<p>Pick a flag on the left, or <b>New flag…</b>.</p>')
            return
        kind = {'project': 'your flag', 'quest': 'your flag (made for a legacy quest)',
                'gate': 'a gate\'s / world\'s cleared flag',
                'hook': 'the Milly hook\'s own flag',
                'check': 'a story check',
                'game': "the original game's flag — read-only"}[f.kind]
        from editor2.core.project import flag_persistent
        saved = 'saved with the game' if flag_persistent(f.idx) else \
            '<b>not saved</b> — it resets when the game is loaded'
        if f.kind == 'check':
            saved = ('worked out each time something checks it — ON while the answer is yes '
                     '(nothing turns it ON or OFF)')
        head = _esc(f.name if own or f.kind != 'game' else f'game flag {FI.flag_number(f.idx)}')
        self.title.setText(f'<h2>{head}</h2><p>{FI.flag_number(f.idx)} · {kind} · {saved}'
                           + (f'<br><i>{_esc(f.label)}</i>' if f.label and not own else '')
                           + '</p>')
        html = []
        if f.kind == 'check':
            html.append('<p style="background:palette(alternate-base); padding:6px">'
                        '<b>Asks:</b> ' + _esc(self.s.doc.describe_check(f.name)) + '</p>')
        short = self.fi.summary(f)
        if short:
            html.append('<p style="background:palette(alternate-base); padding:6px">'
                        '<b>In short:</b> ' + '<br>'.join(_esc(x) for x in short) + '</p>')
        probs = self._prob_by_idx.get(f.idx, [])
        if probs:
            html.append('<h4>Problems</h4><ul>' + ''.join(
                f'<li>{LEVEL_MARK[p.level]} {_esc(p.text)}</li>' for p in probs) + '</ul>')
        mine = [u for u in f.uses if u.source != 'game']
        game = [u for u in f.uses if u.source == 'game']
        html.append(self._uses_html([u for u in mine if u.role == FI.ON], 'Turned ON by'))
        html.append(self._uses_html([u for u in mine if u.role == FI.OFF], 'Turned OFF by'))
        html.append(self._uses_html([u for u in mine if u.role == FI.TEST],
                                    'Checked by — and what it changes'))
        if not mine:
            html.append('<p>Nothing in your game uses this %s yet.</p>'
                        % ('story check' if f.kind == 'check' else 'flag'))
        if game:
            html.append('<h3>In the original game</h3>')
            html.append(self._uses_html([u for u in game if u.role == FI.ON], 'Turned ON by'))
            html.append(self._uses_html([u for u in game if u.role == FI.OFF], 'Turned OFF by'))
            html.append(self._uses_html([u for u in game if u.role == FI.TEST], 'Checked by'))
        self.detail.setHtml(''.join(html))

    def _show_bad(self, u):
        self.cur = None
        for b in (self.b_rename, self.b_renumber, self.b_delete):
            b.setEnabled(False)
        self.note.setEnabled(False)
        self.title.setText(f'<h2>✖ {_esc(u.ref)}</h2><p>not a flag of this project</p>')
        self._navs = {0: (u.places or ([u.nav] if u.nav else []), 'used by')}
        self.detail.setHtml(f'<p>{_esc(u.where)} names a flag that does not exist (renamed '
                            'or deleted by hand?). The build stops here — pick a flag there '
                            'again, or make a flag with this name (New flag…).'
                            + (' <a href="go:0">show</a>' if u.nav else '') + '</p>')

    def _anchor(self, url):
        s = url.toString()
        if s.startswith('go:'):
            got = self._navs.get(int(s[3:]))
            if got and got[0]:
                f = self.fi.flags.get(self.cur) if (self.fi and self.cur is not None) else None
                name = (f.name if f is not None and f.kind != 'game'
                        else f'game flag {FI.flag_number(f.idx)}' if f is not None else '')
                self.show_places(got[0], f'{name} — {got[1].lower()}' if name else got[1])

    def show_places(self, places, title=''):
        """S124 r3: the side panel shows the place(s) — the room screen in its state,
        the NPC outlined."""
        self.place_panel.show_places(places, title)
        if self.outer.sizes()[1] < 200:
            tot = sum(self.outer.sizes())
            self.outer.setSizes([max(300, tot - 400), 400])

    # ------------------------------------------------------------ edits
    def _push(self, label, op):
        cmd = C.SnapshotCommand(self.s, label, op)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            return False
        return True

    def _own(self):
        f = self.fi.flags.get(self.cur) if self.fi else None
        return f if f is not None and f.kind in ('project', 'quest') else None

    def _own_check(self):
        f = self.fi.flags.get(self.cur) if self.fi else None
        return f if f is not None and f.kind == 'check' else None

    # S129: story checks
    def _new_check(self):
        from editor2.app.story_widgets import new_check
        nm = new_check(self, self.s)
        if nm:
            self.refresh()
            n = self.fi.resolve(nm)
            if n is not None:
                self.select_flag(n)

    def _edit_check(self):
        f = self._own_check()
        if f is None:
            return
        from PySide6.QtWidgets import QDialog
        from editor2.app.story_widgets import CheckDialog
        c = self.s.doc.check(f.name) or {}
        spec = {k: v for k, v in c.items() if k != 'name'}
        dlg = CheckDialog(self.s.doc, f.name, spec, parent=self)
        if dlg.exec() != QDialog.Accepted:
            return
        name, spec = dlg.result()
        if c.get('comment') and 'comment' not in spec:
            spec['comment'] = c['comment']
        idx = f.idx
        if self._push(f'Story check {f.name}',
                      lambda doc: doc.update_check(f.name, spec, new_name=name)):
            self.refresh()
            self.select_flag(idx)

    def _new_flag(self):
        name, ok = QInputDialog.getText(self, 'New flag',
                                        'Name of the flag (e.g. bridge_repaired):')
        if not ok or not name.strip():
            return
        out = {}

        def op(doc):
            out['n'] = doc.add_flag(name)
        if self._push(f'New flag {name.strip()}', op):
            self.refresh()
            self.select_flag(self.s.doc.flag_numbers()[out['n']])

    def _note_done(self):
        c = self._own_check()
        if c is not None:
            spec = dict(self.s.doc.check(c.name) or {})
            spec.pop('name', None)
            text = self.note.text().strip()
            if text == (spec.get('comment') or ''):
                return
            if text:
                spec['comment'] = text
            else:
                spec.pop('comment', None)
            name = c.name
            QTimer.singleShot(0, lambda: self._push(
                f'Note of {name}', lambda doc: doc.update_check(name, spec)))
            return
        f = self._own()
        if f is None or self.note.text().strip() == (f.comment or ''):
            return
        text = self.note.text()
        name = f.name
        # deferred: the commit rebuilds this page (KEY_LESSONS S119b)
        QTimer.singleShot(0, lambda: self._push(f'Note of {name}',
                                                lambda doc: doc.set_flag_comment(name, text)))

    def _rename(self):
        c = self._own_check()
        if c is not None:
            new, ok = QInputDialog.getText(self, 'Rename story check',
                                           f'New name for “{c.name}” (every use follows):',
                                           text=c.name)
            if ok and new.strip() and new.strip() != c.name:
                idx = c.idx
                if self._push(f'Rename story check {c.name}',
                              lambda doc: doc.rename_check(c.name, new)):
                    self.refresh()
                    self.select_flag(idx)
            return
        f = self._own()
        if f is None:
            return
        n = len(self.s.doc.flag_uses(f.name))
        new, ok = QInputDialog.getText(
            self, 'Rename flag', f'New name for “{f.name}” (its {n} use{"s" if n != 1 else ""} '
            'follow; the number stays, so saves keep it):', text=f.name)
        if not ok or not new.strip() or new.strip() == f.name:
            return
        idx = f.idx
        if self._push(f'Rename flag {f.name}', lambda doc: doc.rename_flag(f.name, new)):
            self.refresh()
            self.select_flag(idx)

    def _renumber(self):
        f = self._own()
        if f is None:
            return
        if QMessageBox.question(
                self, 'Renumber flag',
                f'Give “{f.name}” a free number instead of {FI.flag_number(f.idx)}?\n\n'
                'Everything in your game follows. A save made before keeps the OLD number, '
                'so in that save the flag reads OFF.') != QMessageBox.Yes:
            return
        out = {}

        def op(doc):
            out['n'] = doc.renumber_flag(f.name)
        if self._push(f'Renumber flag {f.name}', op):
            self.refresh()
            self.select_flag(out['n'])

    def _delete(self):
        c = self._own_check()
        if c is not None:
            n = len(self.s.doc.check_uses(c.name))
            if n:
                QMessageBox.information(self, 'Delete story check',
                                        f'“{c.name}” is still used in {n} place'
                                        f'{"s" if n != 1 else ""} (listed here). Remove those '
                                        'uses first.')
                return
            if QMessageBox.question(self, 'Delete story check',
                                    f'Delete “{c.name}”?') != QMessageBox.Yes:
                return
            if self._push(f'Delete story check {c.name}', lambda doc: doc.delete_check(c.name)):
                self.cur = None
                self.refresh()
            return
        f = self._own()
        if f is None:
            return
        n = len(self.s.doc.flag_uses(f.name))
        if n:
            QMessageBox.information(self, 'Delete flag',
                                    f'“{f.name}” is still used in {n} place'
                                    f'{"s" if n != 1 else ""} (listed here). Remove those '
                                    'uses first.')
            return
        if QMessageBox.question(self, 'Delete flag', f'Delete “{f.name}”?') != QMessageBox.Yes:
            return
        if self._push(f'Delete flag {f.name}', lambda doc: doc.delete_flag(f.name)):
            self.cur = None
            self.refresh()

    # ------------------------------------------------------------ Triggers page
    def _place(self, t):
        nav = t.nav or {}
        rid = nav.get('room')
        if rid:
            try:
                return self.s.doc.room_name(self.s.doc.room(rid))
            except Exception:                                    # noqa: BLE001
                return rid
        if nav.get('gate') is not None:
            return f"Gate {nav['gate']}"
        return 'Elsewhere'

    def _fill_triggers(self):
        if self.fi is None:
            return
        want = self.t_kind.currentData()
        q = self.t_search.text().strip().lower()
        self.t_tree.clear()
        groups = {}
        n = 0
        for t, s in self.fi.triggers_sentences():
            k = TRIGGER_KIND_OF.get(t.kind, t.kind)
            if want and k != want:
                continue
            if t.kind == 'script' and not self.t_copied.isChecked():
                continue
            if q and q not in (s + ' ' + t.where).lower():
                continue
            place = self._place(t)
            g = groups.get(place)
            if g is None:
                g = groups[place] = QTreeWidgetItem([place, ''])
                f0 = g.font(0)
                f0.setBold(True)
                g.setFont(0, f0)
                self.t_tree.addTopLevelItem(g)
            it = QTreeWidgetItem([s, FI.KINDS.get(t.kind, t.kind)])
            it.setToolTip(0, f'{s}\n{t.where}')
            it.setData(0, Qt.UserRole, t.nav)
            g.addChild(it)
            n += 1
        for g in groups.values():
            g.setText(0, f'{g.text(0)} ({g.childCount()})')
            g.setExpanded(g.childCount() <= 12 or bool(q))
        self.pages.setTabText(1, f'Triggers ({n})')

    def _trigger_go(self, it, _col):
        nav = it.data(0, Qt.UserRole)
        if nav:
            self.show_places([dict(nav)], it.text(0))

    # ------------------------------------------------------------ Problems page
    PROBLEM_GROUPS = [
        ('undefined', 'Flags that do not exist — the build stops'),
        ('never_on', 'Checks that are never true — nothing turns their flag ON'),
        ('game_only', 'Checks waiting for the ORIGINAL game\'s progress (copied game '
                      'rooms) — never true unless the player also plays those game rooms'),
        ('game_shares', 'Your flags on a number the original game also uses'),
        ('not_saved', 'Flags that are not saved'),
        ('check_written', 'Story checks turned ON / OFF — a story check is only read'),
        ('never_read', 'Turned ON, but nothing checks them'),
        ('unused', 'Not used anywhere — can be deleted')]

    def _fill_problems(self):
        self.p_tree.clear()
        for code, label in self.PROBLEM_GROUPS:
            ps = [p for p in self.problems if p.code == code]
            if not ps:
                continue
            g = QTreeWidgetItem([LEVEL_MARK[ps[0].level], f'{label} ({len(ps)})'])
            f0 = g.font(1)
            f0.setBold(True)
            g.setFont(1, f0)
            self.p_tree.addTopLevelItem(g)
            for p in ps:
                it = QTreeWidgetItem(['', p.text])
                it.setToolTip(1, p.text)
                it.setData(0, Qt.UserRole, p.idx)
                it.setData(1, Qt.UserRole, p.uses[0].nav if p.uses else None)
                g.addChild(it)
            g.setExpanded(len(ps) <= 8)
        n = len([p for p in self.problems if p.level != 'info'])
        self.pages.setTabText(2, f'Problems ({n})' if n else 'Problems')

    def _problem_go(self, it, _col):
        idx = it.data(0, Qt.UserRole)
        if isinstance(idx, int):
            self.select_flag(idx)
        else:
            nav = it.data(1, Qt.UserRole)
            if nav:
                self.show_places([dict(nav)], it.text(1))

    # ------------------------------------------------------------ Story page (S129)
    def _story_page(self):
        w = QWidget()
        v = QVBoxLayout(w)
        intro = QLabel('<b>The story spine</b> — the milestones of your story in order. Each is '
                       'a flag your game turns ON when the story gets there. A conversation\'s '
                       '<i>Says by progress</i> step picks its words by the latest milestone '
                       'reached, and a story check of the kind <i>reached a milestone</i> is ON '
                       'from that milestone on.')
        intro.setWordWrap(True)
        v.addWidget(intro)
        self.ms_list = QListWidget()
        self.ms_list.itemDoubleClicked.connect(lambda _i: self._ms_rename())
        v.addWidget(self.ms_list, 1)
        row = QHBoxLayout()
        for label, fn in (('Add milestone…', self._ms_add), ('Rename…', self._ms_rename),
                          ('Earlier', lambda: self._ms_move(-1)),
                          ('Later', lambda: self._ms_move(1)), ('Remove', self._ms_remove),
                          ('Show flag', self._ms_show)):
            b = QPushButton(label)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)
        qi = QLabel('<b>Quests</b> — each given by an NPC (make one on the Rooms tab: pick the '
                    'NPC → <i>Quest…</i>). The quest is that NPC\'s conversation: the offer, '
                    'then progress, the reward and the words afterwards.')
        qi.setWordWrap(True)
        v.addWidget(qi)
        self.q_list = QListWidget()
        self.q_list.itemDoubleClicked.connect(lambda _i: self._quest_edit())
        v.addWidget(self.q_list, 1)
        row = QHBoxLayout()
        for label, fn in (('Edit…', self._quest_edit), ('Show giver', self._quest_show),
                          ('Delete', self._quest_delete)):
            b = QPushButton(label)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)
        return w

    def _fill_story(self):
        doc = self.s.doc
        r = self.ms_list.currentRow()
        self.ms_list.clear()
        for i, (flag, name) in enumerate(doc.milestones()):
            it = QListWidgetItem(f'{i + 1}. {name}   — flag {flag}')
            it.setData(Qt.UserRole, flag)
            self.ms_list.addItem(it)
        if 0 <= r < self.ms_list.count():
            self.ms_list.setCurrentRow(r)
        rq = self.q_list.currentRow()
        self.q_list.clear()
        from editor2.core import story as ST
        for q in doc.quests():
            places = (self.fi.binds.get(q.get('giver')) or []) if self.fi else []
            where = (f'{places[0].thing()}, {places[0].room_text()}' if places
                     else 'no NPC gives it yet')
            started, done = ST.quest_flags(q)
            about = f'flags {started} / {done}'
            it = QListWidgetItem(f"{q.get('name') or q.get('id')}   — {where}"
                                 + (f'   · {about}' if about else ''))
            it.setData(Qt.UserRole, q.get('id'))
            self.q_list.addItem(it)
        if 0 <= rq < self.q_list.count():
            self.q_list.setCurrentRow(rq)
        n = len(doc.quests())
        self.pages.setTabText(3, f'Story ({len(doc.milestones())} · {n} quest'
                                 f'{"s" if n != 1 else ""})')

    def _ms_items(self):
        return [list(x) for x in self.s.doc.milestones()]

    def _ms_set(self, label, items, row=None):
        if self._push(label, lambda doc: doc.set_milestones(items)):
            self.refresh()
            if row is not None:
                self.ms_list.setCurrentRow(row)

    def _ms_add(self):
        doc = self.s.doc
        have = {f for f, _n in doc.milestones()}
        names = [f.get('name') for f in doc.flags() if f.get('name') not in have]
        if not names:
            QMessageBox.information(self, 'Add milestone', 'Every flag is a milestone already — '
                                    'make a new flag first (Flags → New flag…).')
            return
        flag, ok = QInputDialog.getItem(self, 'Add milestone',
                                        'The flag your game turns ON when the story gets here:',
                                        names, 0, False)
        if not ok:
            return
        name, ok = QInputDialog.getText(self, 'Add milestone', 'Its name in the story:',
                                        text=flag.replace('_', ' '))
        if not ok:
            return
        items = self._ms_items()
        r = self.ms_list.currentRow()
        at = r + 1 if r >= 0 else len(items)
        items.insert(at, [flag, name.strip() or flag])
        self._ms_set('Add milestone', items, at)

    def _ms_rename(self):
        r = self.ms_list.currentRow()
        items = self._ms_items()
        if not 0 <= r < len(items):
            return
        name, ok = QInputDialog.getText(self, 'Milestone', 'Its name in the story:',
                                        text=items[r][1])
        if ok and name.strip():
            items[r][1] = name.strip()
            self._ms_set('Rename milestone', items, r)

    def _ms_move(self, d):
        r = self.ms_list.currentRow()
        items = self._ms_items()
        if not 0 <= r < len(items) or not 0 <= r + d < len(items):
            return
        items[r], items[r + d] = items[r + d], items[r]
        self._ms_set('Move milestone', items, r + d)

    def _ms_remove(self):
        r = self.ms_list.currentRow()
        items = self._ms_items()
        if not 0 <= r < len(items):
            return
        if QMessageBox.question(self, 'Remove milestone',
                                f'Remove “{items[r][1]}” from the story spine? (The flag '
                                'stays; "says by progress" branches for it stop working.)'
                                ) != QMessageBox.Yes:
            return
        del items[r]
        self._ms_set('Remove milestone', items, min(r, len(items) - 1))

    def _ms_show(self):
        it = self.ms_list.currentItem()
        if it is not None and self.fi is not None:
            n = self.fi.resolve(it.data(Qt.UserRole))
            if n is not None:
                self.select_flag(n)

    def _quest_id(self):
        it = self.q_list.currentItem()
        return it.data(Qt.UserRole) if it is not None else None

    def _quest_edit(self):
        qid = self._quest_id()
        q = self.s.doc.quest(qid) if qid else None
        if q is None:
            return
        from PySide6.QtWidgets import QDialog
        from editor2.app.story_widgets import QuestDialog
        rom = getattr(getattr(self.s, 'renderer', None), 'rom', None)
        dlg = QuestDialog(self.s.doc, rom, q, parent=self)
        if dlg.exec() != QDialog.Accepted:
            return
        spec, new_flags = dlg.spec(), dlg.new_flags()

        def op(doc):
            for nm in new_flags:
                if not any(f.get('name') == nm for f in doc.flags()):
                    doc.add_flag(nm)
            doc.update_quest(qid, spec)
        if self._push(f'Quest {qid}', op):
            self.refresh()

    def _quest_show(self):
        qid = self._quest_id()
        q = self.s.doc.quest(qid) if qid else None
        places = (self.fi.binds.get(q.get('giver')) or []) if q and self.fi else []
        if places:
            self.show_places([p.nav() for p in places], f"{q.get('name') or qid} — the giver")

    def _quest_delete(self):
        qid = self._quest_id()
        if not qid:
            return
        if QMessageBox.question(self, 'Delete quest',
                                f'Delete the quest “{qid}”? Its NPC stops talking (give it a '
                                'new talk on the Rooms tab); its flags stay.') != QMessageBox.Yes:
            return
        if self._push(f'Delete quest {qid}', lambda doc: doc.delete_quest(qid)):
            self.refresh()
