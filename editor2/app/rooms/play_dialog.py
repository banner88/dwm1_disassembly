"""play_dialog.py — "▶ Play here" game state (S132, Rooms tab).

User S132: "Really need a 'play this room' with either flags + monsters
imported from a save OR set manually or generated according to thresholds (ie
have a vanilla slide scale you can put yourself on, and ideally make a separate
slide scale for romhack). Then you immediately enter room from editor."
The romhack scale "follow gates naturally. Just like balance tab".

The dialog edits a SETUP (editor2/core/play_setup.py); the Rooms tab keeps one
per project (QSettings) and its ▶ Play here button plays with it at once.
The party preview is worked out in a background thread (a story point takes a
few seconds: the Balance timeline + the step's kit).
"""

import json

from PySide6.QtCore import QObject, QSettings, Qt, QThread, QTimer, Signal
from PySide6.QtWidgets import (QButtonGroup, QComboBox, QDialog, QDialogButtonBox,
                               QFileDialog, QFormLayout, QGridLayout, QGroupBox,
                               QHBoxLayout, QLabel, QLineEdit, QListWidget,
                               QListWidgetItem, QPlainTextEdit, QPushButton,
                               QRadioButton, QSlider, QSpinBox, QStackedWidget,
                               QVBoxLayout, QWidget, QCheckBox)

from editor2.core import play_setup as PS

KEY = 'play/setup/'


def load_setup(project_dir):
    raw = QSettings('dwm1_disassembly', 'DWM1Editor').value(KEY + str(project_dir))
    try:
        return dict(PS.default_setup(), **json.loads(raw)) if raw else None
    except (TypeError, ValueError):
        return None


def save_setup(project_dir, setup):
    QSettings('dwm1_disassembly', 'DWM1Editor').setValue(KEY + str(project_dir),
                                                         json.dumps(setup))


class Resolver(QThread):
    """play_setup.resolve in the background; `done(token, result | exception)`."""
    done = Signal(int, object)

    def __init__(self, token, setup, project, repo, cache=None, parent=None):
        super().__init__(parent)
        self.token, self.setup, self.project, self.repo, self.cache = token, setup, project, repo, cache

    def run(self):
        try:
            res = PS.resolve(self.setup, self.project, self.repo, cache=self.cache)
        except Exception as ex:                                  # noqa: BLE001
            res = ex
        self.done.emit(self.token, res)


def flag_number(doc, token):
    """A flag picker's value (a project flag name, 'gate:N', '0x0030', a
    number) -> its number, or None."""
    t = str(token).strip()
    if not t:
        return None
    try:
        return int(t, 0)
    except ValueError:
        pass
    if t.startswith('gate:'):
        try:
            info = doc.gate_cleared_info(int(t[5:]))
            return info['flag'] if info else None
        except Exception:                                        # noqa: BLE001
            return None
    try:
        return doc.flag_numbers().get(t.split('  ')[0])
    except Exception:                                            # noqa: BLE001
        return None


class FlagList(QWidget):
    """A small list of flag numbers with Add (a picker combo) / Remove."""

    def __init__(self, doc, title, parent=None):
        super().__init__(parent)
        self.doc = doc
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        v.addWidget(QLabel(title))
        self.list = QListWidget()
        self.list.setMaximumHeight(90)
        v.addWidget(self.list)
        row = QHBoxLayout()
        self.combo = QComboBox()
        self.combo.setEditable(True)
        try:
            for fl in doc.flags():
                self.combo.addItem(f"{fl['name']}  (project flag)", fl['name'])
        except Exception:                                        # noqa: BLE001
            pass
        from editor2.app.rooms.rules_panel import well_known
        for idx, name in well_known(doc, tests=False):
            self.combo.addItem(f'{idx}  {name}', idx)
        self.combo.setCurrentIndex(-1)
        self.combo.setToolTip('A project flag, a gate\'s cleared flag, or any flag number '
                              '(0x0030 …)')
        row.addWidget(self.combo, 1)
        b = QPushButton('Add')
        b.clicked.connect(self._add)
        row.addWidget(b)
        b = QPushButton('Remove')
        b.clicked.connect(lambda: [self.list.takeItem(self.list.row(i))
                                   for i in self.list.selectedItems()])
        row.addWidget(b)
        v.addLayout(row)

    def _add(self):
        tok = self.combo.currentData() if self.combo.currentIndex() >= 0 and \
            self.combo.currentText() == self.combo.itemText(self.combo.currentIndex()) \
            else self.combo.currentText()
        n = flag_number(self.doc, tok)
        if n is None:
            return
        self.add_number(n, self.combo.currentText())

    def add_number(self, n, text=None):
        for i in range(self.list.count()):
            if self.list.item(i).data(Qt.UserRole) == n:
                return
        it = QListWidgetItem(f'${n:04X}' + (f'  {text}' if text and not str(text).startswith('0x')
                                             else ''))
        it.setData(Qt.UserRole, n)
        self.list.addItem(it)

    def numbers(self):
        return [self.list.item(i).data(Qt.UserRole) for i in range(self.list.count())]


class MemberRow(QWidget):
    """By hand: species, level, plus, skills (as raised / picked)."""

    def __init__(self, species, skills, parent=None):
        super().__init__(parent)
        self.skills_all = skills
        h = QHBoxLayout(self)
        h.setContentsMargins(0, 0, 0, 0)
        self.sp = QComboBox()
        self.sp.setEditable(True)
        self.sp.addItem('(empty)', None)
        for sid, name in species:
            self.sp.addItem(f'{name}', sid)
        h.addWidget(self.sp, 2)
        h.addWidget(QLabel('Lv'))
        self.lv = QSpinBox()
        self.lv.setRange(1, 99)
        self.lv.setValue(10)
        h.addWidget(self.lv)
        h.addWidget(QLabel('+'))
        self.plus = QSpinBox()
        self.plus.setRange(0, 99)
        h.addWidget(self.plus)
        self.sk_btn = QPushButton('skills: as raised')
        self.sk_btn.setToolTip('The skills it knows: as the game raises it to that level, or '
                               'pick up to 8')
        self.sk_btn.clicked.connect(self._pick)
        h.addWidget(self.sk_btn, 1)
        self.skills = None

    def _pick(self):
        d = QDialog(self)
        d.setWindowTitle('Skills (up to 8)')
        v = QVBoxLayout(d)
        f = QLineEdit()
        f.setPlaceholderText('filter…')
        v.addWidget(f)
        lst = QListWidget()
        lst.setSelectionMode(QListWidget.MultiSelection)
        for sid, name in self.skills_all:
            it = QListWidgetItem(f'{name}')
            it.setData(Qt.UserRole, sid)
            lst.addItem(it)
            if self.skills and sid in self.skills:
                it.setSelected(True)
        f.textChanged.connect(lambda t: [lst.item(i).setHidden(bool(t) and t.lower() not in
                                                               lst.item(i).text().lower())
                                         for i in range(lst.count())])
        v.addWidget(lst)
        clear = QCheckBox('as raised (the game\'s own skills at that level)')
        clear.setChecked(self.skills is None)
        v.addWidget(clear)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(d.accept)
        bb.rejected.connect(d.reject)
        v.addWidget(bb)
        d.resize(320, 480)
        if d.exec() != QDialog.Accepted:
            return
        if clear.isChecked():
            self.set_skills(None)
        else:
            self.set_skills([it.data(Qt.UserRole) for it in lst.selectedItems()][:8])

    def set_skills(self, skills):
        self.skills = skills
        self.sk_btn.setText('skills: as raised' if skills is None else
                            f'skills: {len(skills)} picked')

    def value(self):
        sp = self.sp.currentData()
        if sp is None:
            return None
        return {'species': sp, 'level': self.lv.value(), 'plus': self.plus.value(),
                'skills': self.skills}

    def set_value(self, v):
        if not v:
            self.sp.setCurrentIndex(0)
            return
        i = self.sp.findData(v.get('species'))
        self.sp.setCurrentIndex(max(i, 0))
        self.lv.setValue(int(v.get('level') or 10))
        self.plus.setValue(int(v.get('plus') or 0))
        self.set_skills(v.get('skills'))


class PlayDialog(QDialog):
    def __init__(self, session, room_label, where_label, setup, repo, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Play here — the game state')
        self.s, self.repo = session, repo
        self.setup = dict(PS.default_setup(), **(setup or {}))
        self._token = 0
        self._threads = []
        self._points = {}
        v = QVBoxLayout(self)
        v.addWidget(QLabel(f'<b>{room_label}</b> — {where_label}'))
        top = QHBoxLayout()
        v.addLayout(top, 1)
        # sources
        g = QGroupBox('Start the game from')
        gl = QVBoxLayout(g)
        self.src_group = QButtonGroup(self)
        self.radios = {}
        for k in PS.SOURCES:
            r = QRadioButton(PS.SOURCE_LABELS[k])
            self.src_group.addButton(r)
            gl.addWidget(r)
            self.radios[k] = r
            r.toggled.connect(lambda on, kk=k: on and self._source(kk))
        gl.addStretch(1)
        top.addWidget(g)
        self.pages = QStackedWidget()
        top.addWidget(self.pages, 1)
        self.page = {}
        # newgame
        p = QLabel('A new game: the hero, no monsters, no story flags (plus the flags below). '
                   'Battles in the room will need a monster — pick "Set by hand" for one.')
        p.setWordWrap(True)
        self._add_page('newgame', p)
        # sav
        w = QWidget()
        f = QFormLayout(w)
        row = QHBoxLayout()
        self.sav = QLineEdit()
        self.sav.setPlaceholderText('a battery save (.sav) of THIS project\'s build')
        row.addWidget(self.sav, 1)
        b = QPushButton('Browse…')
        b.clicked.connect(self._browse)
        row.addWidget(b)
        f.addRow('save file', row)
        n = QLabel('CONTINUE from the save — its flags, party and farm — then straight into '
                   'this room. A save of another build of the game may not continue.')
        n.setWordWrap(True)
        f.addRow(n)
        self._add_page('sav', w)
        # story (original) / project
        for kind in ('story', 'project'):
            w = QWidget()
            f = QVBoxLayout(w)
            sl = QSlider(Qt.Horizontal)
            sl.setTickPosition(QSlider.TicksBelow)
            lab = QLabel('')
            lab.setStyleSheet('font-weight: bold;')
            f.addWidget(QLabel('Put yourself at a point of the story (the game\'s order of '
                               'gates and arena classes, as the Balance tab):'
                               if kind == 'story' else
                               'Your project\'s gates at the game\'s places (as the Balance '
                               'tab); new gates / worlds right after the gate they copy:'))
            f.addWidget(sl)
            f.addWidget(lab)
            sl.valueChanged.connect(lambda _v, kk=kind: self._slider(kk))
            setattr(self, f'{kind}_slider', sl)
            setattr(self, f'{kind}_label', lab)
            f.addStretch(1)
            self._add_page(kind, w)
        self._fill_points()
        # manual
        w = QWidget()
        f = QVBoxLayout(w)
        f.addWidget(QLabel('Up to three monsters (raised the way the game raises them):'))
        species, skills = self._lists()
        self.members = [MemberRow(species, skills) for _ in range(3)]
        for m in self.members:
            f.addWidget(m)
            m.sp.currentIndexChanged.connect(lambda _i: self._schedule())
            m.lv.valueChanged.connect(lambda _i: self._schedule())
        f.addWidget(QLabel('Story flags: none (add any below).'))
        f.addStretch(1)
        self._add_page('manual', w)
        # level / party (story + project)
        g2 = QGroupBox('The party')
        g2l = QGridLayout(g2)
        self.auto_level = QCheckBox('level: what this point needs')
        self.auto_level.setChecked(self.setup.get('level') is None)
        self.auto_level.setToolTip('The team level its hardest fight needs to win 9 times in '
                                   '10 (the Balance tab\'s l90; your project\'s cached numbers, '
                                   'else the original game\'s at the same place)')
        self.level = QSpinBox()
        self.level.setRange(1, 99)
        self.level.setValue(int(self.setup.get('level') or 10))
        self.profile = QComboBox()
        for k, t in (('player', 'a player\'s kit (the Balance tab\'s main number)'),
                     ('strong', 'a strong rolled team'), ('casual', 'a casual rolled team')):
            self.profile.addItem(t, k)
        self.profile.setCurrentIndex(max(0, self.profile.findData(self.setup.get('profile'))))
        reroll = QPushButton('Reroll')
        reroll.clicked.connect(self._reroll)
        g2l.addWidget(self.auto_level, 0, 0)
        g2l.addWidget(self.level, 0, 1)
        g2l.addWidget(self.profile, 0, 2)
        g2l.addWidget(reroll, 0, 3)
        self.preview = QPlainTextEdit()
        self.preview.setReadOnly(True)
        self.preview.setMaximumHeight(120)
        g2l.addWidget(self.preview, 1, 0, 1, 4)
        self.party_group = g2
        v.addWidget(g2)
        for w_ in (self.auto_level, self.level, self.profile):
            sig = (w_.toggled if isinstance(w_, QCheckBox) else
                   w_.valueChanged if isinstance(w_, QSpinBox) else w_.currentIndexChanged)
            sig.connect(lambda *_a: self._schedule())
        self.auto_level.toggled.connect(lambda on: self.level.setEnabled(not on))
        self.level.setEnabled(not self.auto_level.isChecked())
        # flags
        fl = QHBoxLayout()
        self.flags_on = FlagList(session.doc, 'Also turn these flags ON:')
        self.flags_off = FlagList(session.doc, 'and these OFF:')
        for n_ in self.setup.get('flags_on') or []:
            self.flags_on.add_number(int(n_))
        for n_ in self.setup.get('flags_off') or []:
            self.flags_off.add_number(int(n_))
        fl.addWidget(self.flags_on)
        fl.addWidget(self.flags_off)
        v.addLayout(fl)
        note = QLabel('Play saves and builds your project first when it changed since the last '
                      'build.')
        note.setStyleSheet('color: #aaa;')
        v.addWidget(note)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.button(QDialogButtonBox.Ok).setText('▶ Play')
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self._timer = QTimer(self)
        self._timer.setSingleShot(True)
        self._timer.setInterval(500)
        self._timer.timeout.connect(self._compute)
        # values
        self.sav.setText(self.setup.get('sav') or '')
        for i, m in enumerate(self.members):
            party = self.setup.get('party') or []
            m.set_value(party[i] if i < len(party) else None)
        src = self.setup.get('source') if self.setup.get('source') in self.radios else 'story'
        self.radios[src].setChecked(True)
        self._source(src)
        self.resize(900, 640)

    # ------------------------------------------------------------ build
    def _add_page(self, key, w):
        self.page[key] = self.pages.count()
        self.pages.addWidget(w)

    def _lists(self):
        """(species [(id, name)], skills [(id, name)]) of this project."""
        from editor2.core import balance as B
        try:
            data = B.BattleData(self._project(), repo=self.repo)
        except Exception:                                        # noqa: BLE001
            data = B.BattleData(None, repo=self.repo)
        names = getattr(data.T, 'names', {}) or {}
        sp = sorted(((i, names[i]) for i in list(range(0, 215)) + list(range(221, 240))
                     if names.get(i)), key=lambda x: str(x[1]).lower())
        sk = sorted(((sid, n) for sid, n in (getattr(data, 'skill_names', {}) or {}).items()
                     if n and sid < 0xFF), key=lambda x: str(x[1]).lower())
        return sp, sk

    def _fill_points(self):
        from editor2.core import balance as B
        try:
            tl = B.Timeline(B.BattleData(None, repo=self.repo))
            pts = [((s['index'], None), s['label'] + ('  (post-game)' if s['postgame'] else ''))
                   for s in tl.steps]
        except Exception as ex:                                  # noqa: BLE001
            pts = [((0, None), f'⚠ {ex}')]
        self._points['story'] = pts
        try:
            prj = self._project()
            tlp = B.Timeline(B.BattleData(prj, repo=self.repo))
            ppts = PS.project_points(tlp, prj.data)
        except Exception as ex:                                  # noqa: BLE001
            ppts = [((0, None), f'⚠ {ex}')]
        self._points['project'] = ppts
        for kind in ('story', 'project'):
            sl = getattr(self, f'{kind}_slider')
            sl.blockSignals(True)
            sl.setRange(0, max(0, len(self._points[kind]) - 1))
            want = (int(self.setup.get('step') or 0), self.setup.get('extra_gate'))
            idx = next((i for i, (k, _l) in enumerate(self._points[kind]) if k == want), 0)
            sl.setValue(idx)
            sl.blockSignals(False)
            self._slider(kind, schedule=False)

    def _project(self):
        import copy
        from editor2.core.project import Project
        # a COPY: Project() lowers quests / cutscenes into the dict it is given
        prj = Project(copy.deepcopy(self.s.doc.data), self.s.project_dir)
        prj.repo_root = self.repo
        return prj

    # ------------------------------------------------------------ events
    def _source(self, key):
        self.pages.setCurrentIndex(self.page[key])
        self.party_group.setVisible(key in ('story', 'project', 'manual'))
        for w in (self.auto_level, self.level, self.profile):
            w.setEnabled(key in ('story', 'project') and
                         (w is not self.level or not self.auto_level.isChecked()))
        self._schedule()

    def _slider(self, kind, schedule=True):
        sl = getattr(self, f'{kind}_slider')
        pts = self._points.get(kind) or []
        if not pts:
            return
        (_step, _extra), label = pts[min(sl.value(), len(pts) - 1)]
        getattr(self, f'{kind}_label').setText(f'about to do: {label}  ({sl.value() + 1} of '
                                               f'{len(pts)})')
        if schedule:
            self._schedule()

    def _browse(self):
        path, _ = QFileDialog.getOpenFileName(self, 'Save file', self.sav.text(),
                                              'Battery saves (*.sav *.ram);;All files (*)')
        if path:
            self.sav.setText(path)

    def _reroll(self):
        self.setup['seed'] = int(self.setup.get('seed') or 0) + 1
        self._schedule()

    def _schedule(self):
        self._timer.start()

    # ------------------------------------------------------------ value
    def value(self):
        s = dict(self.setup)
        src = next(k for k, r in self.radios.items() if r.isChecked())
        s['source'] = src
        s['sav'] = self.sav.text().strip() or None
        if src in ('story', 'project'):
            pts = self._points.get(src) or [((0, None), '')]
            sl = getattr(self, f'{src}_slider')
            (step, extra), _l = pts[min(sl.value(), len(pts) - 1)]
            s['step'], s['extra_gate'] = step, extra
        s['level'] = None if self.auto_level.isChecked() else self.level.value()
        s['profile'] = self.profile.currentData()
        s['party'] = [m.value() for m in self.members if m.value()]
        s['flags_on'] = self.flags_on.numbers()
        s['flags_off'] = self.flags_off.numbers()
        return s

    def _compute(self):
        s = self.value()
        if s['source'] not in ('story', 'project', 'manual'):
            self.preview.setPlainText('')
            return
        self._token += 1
        self.preview.setPlainText('working out the party… (a few seconds)')
        prj = self._project() if s['source'] in ('project', 'manual') else None
        th = Resolver(self._token, s, prj, self.repo, parent=self)
        th.done.connect(self._computed)
        self._threads.append(th)
        th.start()

    def _computed(self, token, res):
        if token != self._token:
            return
        if isinstance(res, Exception):
            self.preview.setPlainText(f'⚠ {res}')
            return
        from editor2.core import balance as B
        try:
            data = B.BattleData(None, repo=self.repo)
        except Exception:                                        # noqa: BLE001
            data = None
        lines = PS.team_lines(data, res['team']) or ['(no monsters)']
        if res.get('level') is not None and self.auto_level.isChecked():
            self.level.blockSignals(True)
            self.level.setValue(int(res['level']))
            self.level.blockSignals(False)
        self.preview.setPlainText('\n'.join(lines + [''] + res['notes']))
        self.last = res

    def _ok(self):
        self.result_setup = self.value()
        for th in self._threads:
            th.wait(50)
        self.accept()

    def done(self, r):                                           # noqa: D401
        for th in self._threads:
            if th.isRunning():
                th.wait(20000)
        super().done(r)
