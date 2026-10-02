"""skills_tab.py — the Skills tab (ROADMAP P3.11, S110; P3.11c/d, S111;
EDITOR_DESIGN §5.3; model: editor2/core/skills_doc.py; compiler: gamedata.skills
→ editor2/core/gamedata.py + skills.py + custom_skills.py, PROJECT_COMPILER
§2.26 / §2.27).

Left: the 222 original skills, then the ten built-in custom skills (MagicBurn …
Mourn) and the project's NEW skills (search, kind filter), bold = changed; the
text space meters; New skill… / Delete. Right, one foldable section per topic:

  Name and SKIL text   name (1-9) + the SKIL-menu description (3 x 18) with the
                       game font preview
  MP and learning      one MP field (battle + field copies), learn level, the six
                       stat requirements, the skills it evolves from
  Power                min-max for party casters and for enemies
  Targets              one foe / all foes / one ally / all allies / the user
  Monster AI           plan, weight, element, damage class (only the AI reads them)
  Behaviour            the record flags some code reads (each with what it does);
                       the bytes / bits nothing reads, greyed
  Looks and sounds     play another skill's animation / another's sounds; the
                       announce line (editable for custom skills)
  Its own numbers      built-in custom skills: Tame's meter, Quake's power, the
                       Quake / Mourn extra lines, Anchor's dialogs
  Who has it           natural learners, enemy rows, evolve chain, shared effect
Power also holds the ELEMENT (the resistance the damage tests, S111).

Battle items (ids 176-212) are listed read-only: they are edited with the
items (the Items tab, ROADMAP E9). Every edit is one undo step
(SnapshotCommand); the model validates with the compiler's own code.
"""

from PySide6.QtCore import Qt
from PySide6.QtGui import QFont
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox,
                               QFormLayout, QGridLayout,
                               QHBoxLayout, QLabel, QLineEdit, QListWidget,
                               QListWidgetItem, QMessageBox, QPushButton,
                               QScrollArea, QSpinBox, QSplitter, QVBoxLayout,
                               QWidget)

from editor2.app.collapsible import Section
from editor2.app.rooms import commands as C
from editor2.core import gamedata as G
from editor2.core import monster_text as MT
from editor2.core import skills as SK
from editor2.core import custom_skills as CS

HELP = ('Every original skill: its name and SKIL-menu text, MP, when monsters learn it, '
        'its power, who it hits, how the monster AI treats it, the battle rules it '
        'follows, and which skill\'s animation and sounds it plays. Hover any field for '
        'what the game does with it. Bold = changed.')
KIND_FILTER = [('All skills', None), ('Skills', 'skill'),
               ('Battle actions / boss moves', 'internal'), ('Battle items (read-only)',
                                                             'item_effect'),
               ('Custom skills (built in)', 'custom'), ('New skills (this project)', 'new')]
ELEMENT_HINT = ('The resistance this skill\'s DAMAGE tests (Fire, Ice, …): the target\'s '
                'level 0-3 in it cuts the damage (level 3 = immune). Original skills keep '
                'the element their code reads unless you pick another; "none" ignores '
                'resistances. Only skills whose damage tests a resistance (measured, 38 '
                'original ones) and the custom damage skills have one. The monster AI\'s '
                'element (Monster AI) follows it.')
SOUNDS_HINT = ('Play another skill\'s sounds (bank $55). Default: the sounds of the look '
               'you picked (original skills) / of its base (new skills) / Infernos\' '
               '(built-in custom skills — what they always played).')
ANNOUNCE_HINT = ('What the battle says when the skill is used. "Its own line": up to two '
                 'pages of two lines (18 cells; {name} = the caster, {skill} = this skill). '
                 'Or one of the game\'s lines ("{name} casts {skill}!" …), or silent.')
STAT_LABEL = {'hp': 'HP', 'mp': 'MP', 'atk': 'ATK', 'def': 'DEF', 'agl': 'AGL', 'int': 'INT'}


def _readable(text, skill_name):
    """A battle message for people: the inserts named, control codes dropped."""
    import re
    t = text.replace('[INS 00]', '<user>').replace('[INS 10]', skill_name)
    t = re.sub(r'\[INS [0-9A-F]{2}\]', '<…>', t)
    t = re.sub(r'\{[0-9A-F]{2}\}', '', t)
    t = re.sub(r'<(slime|NAME|MONSTER)>', '', t)
    return ' '.join(t.replace('\n', ' ').split())


def _spin(lo, hi, tip=''):
    s = QSpinBox()
    s.setRange(lo, hi)
    s.setKeyboardTracking(False)
    if tip:
        s.setToolTip(tip)
    return s


def _bold(w, on):
    f = w.font()
    f.setBold(bool(on))
    w.setFont(f)


class SkillsTab(QWidget):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self.sid = 0
        self._busy = False
        self._rom_bytes = None
        root = QHBoxLayout(self)
        split = QSplitter()
        root.addWidget(split)

        # ---- left ----
        left = QWidget()
        lv = QVBoxLayout(left)
        self.filter = QLineEdit()
        self.filter.setPlaceholderText('Find a skill (name or number)')
        self.filter.textChanged.connect(self._fill_list)
        lv.addWidget(self.filter)
        self.kind = QComboBox()
        for label, k in KIND_FILTER:
            self.kind.addItem(label, k)
        self.kind.currentIndexChanged.connect(self._fill_list)
        lv.addWidget(self.kind)
        self.list = QListWidget()
        self.list.currentItemChanged.connect(self._picked)
        lv.addWidget(self.list, 1)
        bh = QHBoxLayout()
        self.new_btn = QPushButton('New skill…')
        self.new_btn.setToolTip('A new skill (ids 234-254) that runs the effect of an original '
                                'skill you pick, with its own name, text, power, look, '
                                'element and learning')
        self.new_btn.clicked.connect(self._new_skill)
        bh.addWidget(self.new_btn)
        self.del_btn = QPushButton('Delete')
        self.del_btn.setToolTip('Delete this NEW skill (refused while something uses it)')
        self.del_btn.clicked.connect(self._delete_skill)
        bh.addWidget(self.del_btn)
        lv.addLayout(bh)
        self.meters = QLabel()
        self.meters.setWordWrap(True)
        lv.addWidget(self.meters)
        h = QLabel(HELP)
        h.setWordWrap(True)
        lv.addWidget(h)
        split.addWidget(left)

        # ---- right ----
        right = QWidget()
        rv = QVBoxLayout(right)
        head = QHBoxLayout()
        self.title = QLabel()
        f = self.title.font()
        f.setPointSize(f.pointSize() + 4)
        f.setBold(True)
        self.title.setFont(f)
        head.addWidget(self.title)
        head.addStretch(1)
        self.reset_btn = QPushButton('Back to the original skill')
        self.reset_btn.setToolTip('Every field of this skill back to the original game')
        self.reset_btn.clicked.connect(self._reset)
        head.addWidget(self.reset_btn)
        rv.addLayout(head)
        self.kind_note = QLabel()
        self.kind_note.setWordWrap(True)
        rv.addWidget(self.kind_note)
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        inner = QWidget()
        self.sv = QVBoxLayout(inner)
        self._build_text()
        self._build_cost()
        self._build_power()
        self._build_target()
        self._build_ai()
        self._build_flags()
        self._build_looks()
        self._build_params()
        self._build_who()
        self.sv.addStretch(1)
        scroll.setWidget(inner)
        rv.addWidget(scroll, 1)
        split.addWidget(right)
        split.setSizes([280, 1200])

        self._stale = False
        self.s.undo.indexChanged.connect(self._undo_changed)
        self.refresh()

    # ================================================================ build
    def _section(self, title, key, content, expanded=True):
        sec = Section(title, content, f'skills/{key}', expanded=expanded)
        self.sv.addWidget(sec)
        return sec

    def _build_text(self):
        w = QWidget()
        g = QGridLayout(w)
        g.addWidget(QLabel('Name:'), 0, 0)
        self.name = QLineEdit()
        self.name.setMaxLength(SK.NAME_MAX)
        self.name.setToolTip(f'1-{SK.NAME_MAX} letters, digits, space and \' , . ! ? - &. '
                             'Every menu, battle message and the library show this name.')
        self.name.editingFinished.connect(self._name_done)
        g.addWidget(self.name, 0, 1)
        self.name_orig = QLabel()
        g.addWidget(self.name_orig, 0, 2)
        g.addWidget(QLabel('SKIL text:'), 1, 0, Qt.AlignTop)
        dv = QVBoxLayout()
        self.desc = []
        for k in range(SK.DESC_LINES):
            e = QLineEdit()
            e.setToolTip(f'The SKIL menu\'s info box: up to {SK.DESC_LINES} lines of '
                         f'{SK.DESC_CELLS} cells ("\'s", "\'t" and ".." take one cell). '
                         'Empty = no text.')
            e.editingFinished.connect(self._desc_done)
            e.textEdited.connect(self._desc_preview)
            dv.addWidget(e)
            self.desc.append(e)
        g.addLayout(dv, 1, 1)
        self.desc_preview = QLabel()
        g.addWidget(self.desc_preview, 1, 2, Qt.AlignTop)
        self.desc_orig = QLabel()
        self.desc_orig.setWordWrap(True)
        g.addWidget(self.desc_orig, 2, 1, 1, 2)
        self.sec_text = self._section('Name and SKIL text', 'text', w)

    def _build_cost(self):
        w = QWidget()
        g = QGridLayout(w)
        g.addWidget(QLabel('MP:'), 0, 0)
        self.mp = _spin(0, 255, SK.MP_HINT)
        self.mp.valueChanged.connect(self._mp_changed)
        g.addWidget(self.mp, 0, 1)
        self.mp_note = QLabel()
        self.mp_note.setWordWrap(True)
        g.addWidget(self.mp_note, 0, 2, 1, 5)
        self.learnable = QCheckBox('Learnable')
        self.learnable.setToolTip('Custom skills: whether monsters learn it at a level-up at '
                                  'all (else only an enemy row or a natural skill slot gives it)')
        self.learnable.toggled.connect(self._learnable_toggled)
        g.addWidget(self.learnable, 6, 0, 1, 3)
        g.addWidget(QLabel('Learned at level:'), 1, 0)
        self.learn = {'level': _spin(0, 255, 'The level from which a monster that can learn '
                                     'this skill learns it (and may cast it: a monster '
                                     'below the level gets "can\'t use it yet").')}
        g.addWidget(self.learn['level'], 1, 1)
        g.addWidget(QLabel('and at least:'), 1, 2)
        col = 3
        row = 1
        for s in G.STATS:
            lab = QLabel(STAT_LABEL[s])
            sp = _spin(0, 0xFFFF, f'The {STAT_LABEL[s]} a monster needs (with the level) '
                                  'to learn it at a level-up.')
            self.learn[s] = sp
            g.addWidget(lab, row, col)
            g.addWidget(sp, row, col + 1)
            col += 2
            if col > 7:
                col, row = 3, row + 1
        for k, sp in self.learn.items():
            sp.valueChanged.connect(lambda v, k=k: self._learn_changed(k, v))
        g.addWidget(QLabel('Evolves from:'), 4, 0)
        self.prereqs = QLineEdit()
        self.prereqs.setToolTip('Up to 5 skills (names or numbers, comma-separated). A '
                                'monster that knows one of them learns this skill IN ITS '
                                'PLACE (Blaze → Blazemore).')
        self.prereqs.editingFinished.connect(self._prereqs_done)
        g.addWidget(self.prereqs, 4, 1, 1, 6)
        self.learn_note = QLabel()
        self.learn_note.setWordWrap(True)
        g.addWidget(self.learn_note, 5, 0, 1, 7)
        self.sec_cost = self._section('MP and learning', 'cost', w)

    def _build_power(self):
        w = QWidget()
        g = QGridLayout(w)
        self.power = {}
        for r, (side, lab) in enumerate((('party', 'Cast by your monsters'),
                                         ('enemy', 'Cast by enemies'))):
            g.addWidget(QLabel(lab + ':'), r, 0)
            lo = _spin(0, 0xFFFF, SK.POWER_HINT)
            hi = _spin(0, 0x1FFFE, SK.POWER_HINT)
            g.addWidget(lo, r, 1)
            g.addWidget(QLabel('to'), r, 2)
            g.addWidget(hi, r, 3)
            lo.valueChanged.connect(lambda _v, s=side: self._power_changed(s, 'min'))
            hi.valueChanged.connect(lambda _v, s=side: self._power_changed(s, 'max'))
            self.power[side] = (lo, hi)
        self.power_note = QLabel()
        self.power_note.setWordWrap(True)
        g.addWidget(self.power_note, 2, 0, 1, 5)
        g.addWidget(QLabel('Element:'), 3, 0)
        self.element = QComboBox()
        self.element.setToolTip(ELEMENT_HINT)
        self.element.currentIndexChanged.connect(self._element_changed)
        g.addWidget(self.element, 3, 1, 1, 3)
        self.element_note = QLabel()
        self.element_note.setWordWrap(True)
        g.addWidget(self.element_note, 4, 0, 1, 5)
        self.sec_power = self._section('Power', 'power', w)

    def _build_target(self):
        w = QWidget()
        h = QHBoxLayout(w)
        h.addWidget(QLabel('Aimed at:'))
        self.target = QComboBox()
        self.target.setToolTip(SK.TARGET_HINT)
        self.target.currentIndexChanged.connect(self._target_changed)
        h.addWidget(self.target)
        self.target_note = QLabel()
        self.target_note.setWordWrap(True)
        h.addWidget(self.target_note, 1)
        self.sec_target = self._section('Targets', 'target', w)

    def _build_ai(self):
        w = QWidget()
        f = QFormLayout(w)
        self.ai_tag = QComboBox()
        self.ai_tag.setToolTip(SK.AI_TAG_HINT)
        for v, lab in SK.AI_TAGS:
            self.ai_tag.addItem(lab, v)
        self.ai_tag.currentIndexChanged.connect(
            lambda _i: self._record({'ai_tag': self.ai_tag.currentData()}, 'AI plan'))
        f.addRow('Plan:', self.ai_tag)
        self.ai_weight = _spin(0, 255, SK.AI_WEIGHT_HINT)
        self.ai_weight.valueChanged.connect(
            lambda v: self._record({'ai_weight': v}, 'AI weight'))
        f.addRow('Weight:', self.ai_weight)
        self.ai_elem = QComboBox()
        self.ai_elem.setToolTip(SK.AI_ELEMENT_HINT)
        self.ai_elem.addItem('none', 0)
        for k, n in enumerate(G.RESIST_NAMES, start=1):
            self.ai_elem.addItem(n, k)
        self.ai_elem.currentIndexChanged.connect(
            lambda _i: self._record({'status_id': self.ai_elem.currentData()}, 'AI element'))
        f.addRow('Element:', self.ai_elem)
        self.ai_dmg = QComboBox()
        self.ai_dmg.setToolTip(SK.AI_DAMAGE_HINT)
        for v, lab in SK.DAMAGE_CLASSES:
            self.ai_dmg.addItem(lab, v)
        self.ai_dmg.currentIndexChanged.connect(
            lambda _i: self._record({'damage_class': self.ai_dmg.currentData()},
                                    'AI damage class'))
        f.addRow('Damage class:', self.ai_dmg)
        note = QLabel('Only the enemy / tactics AI reads these four; they do not change '
                      'what the skill does.')
        note.setWordWrap(True)
        f.addRow(note)
        self.sec_ai = self._section('Monster AI', 'ai', w)

    def _build_flags(self):
        w = QWidget()
        v = QVBoxLayout(w)
        g = QGridLayout()
        self.flags = {}
        for k, (off, bit, key, label, hint) in enumerate(SK.FLAG_BITS):
            cb = QCheckBox(label)
            cb.setToolTip(f'{hint}\n(record +{off} bit {bit})')
            cb.toggled.connect(lambda on, key=key: self._record({f'flag.{key}': on}, key))
            self.flags[key] = cb
            g.addWidget(cb, k // 2, k % 2)
        v.addLayout(g)
        dead = QLabel('Not read by the game (shown for completeness): ' + '; '.join(
            d[2].split(' — ')[0] for d in SK.DEAD))
        dead.setWordWrap(True)
        dead.setStyleSheet('color: gray')
        dead.setToolTip('\n'.join(d[2] for d in SK.DEAD))
        v.addWidget(dead)
        self.dead_vals = QLabel()
        self.dead_vals.setStyleSheet('color: gray')
        self.dead_vals.setWordWrap(True)
        v.addWidget(self.dead_vals)
        self.sec_flags = self._section('Behaviour', 'flags', w)

    def _build_looks(self):
        w = QWidget()
        g = QGridLayout(w)
        g.addWidget(QLabel('Looks like:'), 0, 0)
        self.looks = QComboBox()
        self.looks.setToolTip(SK.LOOKS_HINT)
        self.looks.currentIndexChanged.connect(self._looks_changed)
        g.addWidget(self.looks, 0, 1)
        g.addWidget(QLabel('Sounds like:'), 1, 0)
        self.sounds = QComboBox()
        self.sounds.setToolTip(SOUNDS_HINT)
        self.sounds.currentIndexChanged.connect(self._sounds_changed)
        g.addWidget(self.sounds, 1, 1)
        self.looks_note = QLabel()
        self.looks_note.setWordWrap(True)
        g.addWidget(self.looks_note, 2, 0, 1, 3)
        g.addWidget(QLabel('Announced as:'), 3, 0)
        self.announce = QLabel()
        self.announce.setToolTip('The battle message shown when the skill is used (bank '
                                 '$58 AnnounceTemplateTable). Original skills: read-only until '
                                 'the dialogue editor (ROADMAP P3.6).')
        self.announce.setTextInteractionFlags(Qt.TextSelectableByMouse)
        g.addWidget(self.announce, 3, 1, 1, 2)
        self.ann_mode = QComboBox()
        self.ann_mode.setToolTip(ANNOUNCE_HINT)
        self.ann_mode.currentIndexChanged.connect(self._ann_mode_changed)
        g.addWidget(self.ann_mode, 4, 1, 1, 2)
        self.ann_lines = []
        for k in range(4):
            e = QLineEdit()
            e.setPlaceholderText(['page 1, line 1', 'page 1, line 2', 'page 2, line 1 (optional)',
                                  'page 2, line 2'][k])
            e.setToolTip(ANNOUNCE_HINT)
            e.editingFinished.connect(self._ann_lines_done)
            g.addWidget(e, 5 + k, 1, 1, 2)
            self.ann_lines.append(e)
        self.sec_looks = self._section('Looks and sounds', 'looks', w)

    def _build_params(self):
        w = QWidget()
        self.params_box = QVBoxLayout(w)
        self.params_widgets = []
        self.sec_params = self._section('Its own numbers and lines', 'params', w)

    def _build_who(self):
        w = QWidget()
        v = QVBoxLayout(w)
        self.who = QLabel()
        self.who.setWordWrap(True)
        self.who.setTextInteractionFlags(Qt.TextSelectableByMouse)
        v.addWidget(self.who)
        self.sec_who = self._section('Who has it', 'who', w, expanded=False)

    # ================================================================ data
    def _undo_changed(self, _i):
        from shiboken6 import isValid
        if not isValid(self):
            return
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
        self._fill_list()
        try:
            u = SK.usage(self.s.doc.data, SK._repo())
            c = CS.usage(self.s.doc.data, SK._repo())
            self.meters.setText(
                f"Skill names: {u['names'][0]} / {u['names'][1]} B (more spill into the "
                f"shared bank $41 space).  SKIL texts: {u['descs'][0]} / {u['descs'][1]} B "
                f"+ spare {u['extra'][0]} / {u['extra'][1]} B.  Custom skills: names "
                f"{c['names'][0]} / {c['names'][1]} B, texts {c['descs'][0]} / {c['descs'][1]} B, "
                f"battle lines {c['lines'][0]} / {c['lines'][1]} B; new skills "
                f"{len(self.s.doc.new_skill_ids())} / {len(CS.NEW)}.")
        except (SK.SkillError, CS.CustomSkillError) as ex:
            self.meters.setText(str(ex))
        self._show()

    def _fill_list(self, *_a):
        doc = self.s.doc
        try:
            items = doc.skills_list()
        except Exception as ex:                       # noqa: BLE001
            self.title.setText('The project does not validate')
            self.kind_note.setText(str(ex))
            return
        flt = self.filter.text().strip().lower()
        kind = self.kind.currentData()
        self._busy = True
        self.list.clear()
        sel = None
        for e in items:
            if kind and e['kind'] != kind:
                continue
            label = f"{e['id']:3d}  {e['name']}"
            if e['name'] != e['vanilla']:
                label += f"  (was {e['vanilla']})"
            if flt and flt not in label.lower():
                continue
            it = QListWidgetItem(label)
            it.setData(Qt.UserRole, e['id'])
            if e['edited']:
                _bold(it, True)
            if e['kind'] == 'item_effect':
                it.setForeground(Qt.gray)
            self.list.addItem(it)
            if e['id'] == self.sid:
                sel = it
        self._busy = False
        if sel is not None:
            self.list.setCurrentItem(sel)

    def _picked(self, cur, _prev):
        if self._busy or cur is None:
            return
        self.sid = cur.data(Qt.UserRole)
        self._show()

    # ================================================================ show
    def _show(self):
        doc = self.s.doc
        try:
            d = doc.skill_detail(self.sid)
        except Exception as ex:                       # noqa: BLE001
            self.title.setText('The project does not validate')
            self.kind_note.setText(str(ex))
            return
        self.d = d
        item = d['kind'] == 'item_effect'
        self._busy = True
        try:
            custom = d['kind'] in ('custom', 'new')
            builtin = d['kind'] == 'custom'
            self.title.setText(f"{d['name']}   #{d['id']} (${d['id']:02X})")
            if builtin:
                note = (f"A built-in custom skill: {d['handler_label']}. Its effect is its own "
                        "code; its numbers, texts, look, sounds, element and learning are "
                        "yours to change (the power and targets belong to the code — see "
                        "\u201cIts own numbers and lines\u201d).")
            elif d['kind'] == 'new':
                note = (f"A new skill of this project: it runs {d['base_name']}'s effect "
                        f"(#{d['base']}) with its own name, text, power, targets, look, sounds, "
                        "element, announce line and learning. Battle only (the field menu "
                        "knows the original skills only).")
            else:
                note = (('A skill monsters learn and cast.' if d['kind'] == 'skill' else
                         f"{SK.KIND_LABEL.get(d['kind'], d['kind']).capitalize()}.")
                        + (' Battle items are edited with the items (the Items tab, not built '
                           'yet) — shown read-only here.' if item else '')
                        + (' A battle action / boss move: monsters do not learn it from the '
                           'SKIL menu, but bosses and enemy rows may use it.'
                           if d['kind'] == 'internal' else ''))
            self.kind_note.setText(note)
            self.reset_btn.setEnabled(d['edited'] and not item)
            self.reset_btn.setText('Back to the base skill\'s values' if d['kind'] == 'new'
                                   else 'Back to the original skill')
            self.del_btn.setEnabled(d['kind'] == 'new')
            for w in (self.sec_text, self.sec_cost, self.sec_power, self.sec_target,
                      self.sec_ai, self.sec_flags, self.sec_looks):
                w.content.setEnabled(not item)
            self.sec_params.setVisible(builtin)
            self.sec_target.content.setEnabled(not item and not builtin)
            self.sec_flags.content.setEnabled(not item and not builtin)
            for side in ('party', 'enemy'):
                for sp in self.power[side]:
                    sp.setEnabled(not builtin)
            # text
            self.name.setText(d['name'])
            _bold(self.name, d['name'] != d['vanilla_name'])
            self.name_orig.setText('' if d['name'] == d['vanilla_name']
                                   else f"original: {d['vanilla_name']}")
            for k, e in enumerate(self.desc):
                e.setText(d['description'][k] if k < len(d['description']) else '')
                _bold(e, d['description'] != d['vanilla_description'])
            ov = ' / '.join(d['vanilla_description']) or '(no text)'
            self.desc_orig.setText(
                '' if d['description'] == d['vanilla_description'] else f'original: {ov}')
            if d['shares_empty'] and not d['description']:
                self.desc_orig.setText('No SKIL text in the original game (this id shares the '
                                       'empty one); typing one gives it its own.')
            self._desc_preview()
            # MP / learning
            allmp = d['vanilla_mp'] == G.ALL_MP
            self.mp.setEnabled(not allmp and not d.get('mp_code'))
            self.mp.setValue(d['battle_mp'] if allmp else min(d['mp'], 255))
            _bold(self.mp, d['mp'] != d['vanilla_mp'])
            if d.get('mp_code'):
                self.mp_note.setText(
                    'It spends a share of the current MP instead (set in "Its own numbers '
                    'and lines").' if d['handler'] == 'magicburn' else
                    'It charges a share of the current MP on arrival instead (set in "Its own '
                    'numbers and lines").')
            elif custom:
                self.mp_note.setText('Charged in battle (and shown in the SKIL menu).')
            elif allmp:
                self.mp_note.setText('All MP — the game empties the caster\'s MP in this '
                                     'skill\'s own code; not a number.')
            elif d['vanilla_battle_mp'] != (d['vanilla_mp'] & 0xFF):
                self.mp_note.setText('Field-only skill: the field menu charges this; in '
                                     'battle it is never cast.')
            else:
                self.mp_note.setText('Charged in battle and in the field menu.')
            L, VL = d['learn'], d['vanilla_learn']
            self.learnable.setVisible(custom)
            self.learnable.setChecked(L is not None)
            _bold(self.learnable, (L is None) != (VL is None))
            for k, sp in self.learn.items():
                sp.setEnabled(L is not None)
                sp.setValue(L[k] if L else 0)
                _bold(sp, L is not None and (VL is None or L[k] != VL[k]))
            self.prereqs.setEnabled(L is not None)
            names = doc.skill_names_effective()
            self.prereqs.setText(', '.join(names.get(x, str(x)) for x in (L or {}).get('prereqs', [])))
            _bold(self.prereqs, L is not None and (VL is None or L['prereqs'] != VL['prereqs']))
            if custom and L is None:
                self.learn_note.setText('Not learned at a level-up: only an enemy row or a '
                                        'natural skill slot (Monsters tab) gives it.')
            elif custom:
                self.learn_note.setText(
                    'A monster that knows a skill it evolves from learns this one IN ITS PLACE '
                    'at a level-up (from the level shown); with nothing to evolve from it is '
                    'learned only as a natural skill. Custom skills are never learned by '
                    'stats alone (the S75 fence).')
            else:
                self.learn_note.setText(
                    'No learn row: ids $DA-$DD are code in bank $06 (a monster can still be '
                    'given it as a natural skill).' if L is None else
                    'A monster learns it at a level-up when this skill is in its learnable set '
                    '(its three natural skills and what they evolve into) and it meets the '
                    'level and every stat.')
            # power
            R, VR = d['record'], d['vanilla_record']
            for side in ('party', 'enemy'):
                lo, hi = self.power[side]
                lo.setValue(R[f'{side}_min'])
                hi.setValue(R[f'{side}_min'] + R[f'{side}_range'])
                ed = (R[f'{side}_min'], R[f'{side}_range']) != (VR[f'{side}_min'], VR[f'{side}_range'])
                _bold(lo, ed)
                _bold(hi, ed)
            shared = d['handler_shared_with']
            if builtin:
                self.power_note.setText(
                    'Not used: this skill\'s code sets the damage'
                    + (' (Quake\'s numbers are under \u201cIts own numbers and lines\u201d).'
                       if d['handler'] == 'quake' else '.'))
            else:
                self.power_note.setText(
                    'Damage / healing = a random value from min to max (the party pair for '
                    'your monsters, the enemy pair for enemies). '
                    + (f"Its effect code is shared with: "
                       f"{', '.join(names.get(x, str(x)) for x in shared)}." if shared else
                       f"Its effect is {d['base_name']}'s." if d['kind'] == 'new' else
                       'Its effect code is its own.'))
            self._show_element(d)
            # target
            self.target.clear()
            for v, lab in SK.TARGET_MODES:
                self.target.addItem(lab, v)
            if self.target.findData(R['target_mode']) < 0:
                self.target.addItem(f"original (${R['target_mode']:02X})", R['target_mode'])
            self.target.setCurrentIndex(self.target.findData(R['target_mode']))
            _bold(self.target, R['target_mode'] != VR['target_mode'])
            self.target_note.setText(
                '' if SK.side(R['target_mode']) == SK.side(VR['target_mode']) else
                'The SIDE changed from the original — its effect code was written for the '
                'other side (test it in battle).')
            # AI
            k = self.ai_tag.findData(R['ai_tag'])
            if k < 0:
                self.ai_tag.addItem(f"original ({R['ai_tag']})", R['ai_tag'])
                k = self.ai_tag.count() - 1
            self.ai_tag.setCurrentIndex(k)
            _bold(self.ai_tag, R['ai_tag'] != VR['ai_tag'])
            self.ai_weight.setValue(R['ai_weight'])
            _bold(self.ai_weight, R['ai_weight'] != VR['ai_weight'])
            k = self.ai_elem.findData(R['status_id'])
            self.ai_elem.setCurrentIndex(max(k, 0))
            _bold(self.ai_elem, R['status_id'] != VR['status_id'])
            k = self.ai_dmg.findData(R['damage_class'])
            if k < 0:
                self.ai_dmg.addItem(f"original ({R['damage_class']})", R['damage_class'])
                k = self.ai_dmg.count() - 1
            self.ai_dmg.setCurrentIndex(k)
            _bold(self.ai_dmg, R['damage_class'] != VR['damage_class'])
            # flags
            for key, cb in self.flags.items():
                cb.setChecked(R['flags'][key])
                _bold(cb, R['flags'][key] != VR['flags'][key])
            self.dead_vals.setText(
                f"This skill: +0 = {R['effect_class']}, +1 low half = {R['category'] & 15}, "
                f"+10 = {R['field10']}, flags7 bit2 = {R['flags7'] >> 2 & 1}, flags8 bit3 = "
                f"{R['flags8'] >> 3 & 1}, flags9 bits 1/6/7 = {R['flags9'] >> 1 & 1}/"
                f"{R['flags9'] >> 6 & 1}/{R['flags9'] >> 7 & 1}.")
            # looks
            self.looks.clear()
            if custom:
                vl = d['vanilla_looks']
                self.looks.addItem(f"{'its base' if d['kind'] == 'new' else 'built-in'}: "
                                   f"{names.get(vl, vl)} (#{vl})", vl)
            else:
                self.looks.addItem(f"its own look ({d['vanilla_name']})", d['id'])
            model = self.looks.model()
            warn_now = None
            for donor, nm, problem, warn in doc.skill_lend_options(d['id']):
                if donor == (d['vanilla_looks'] if custom else d['id']):
                    continue
                tag = ''
                if warn:
                    tag = '   (summon)' if donor in SK.SUMMONS else '   (other side)'
                self.looks.addItem(f'{donor:3d}  {nm}{tag}', donor)
                it = model.item(self.looks.count() - 1)
                if problem:
                    it.setEnabled(False)
                    it.setToolTip(problem)
                elif warn:
                    it.setToolTip(warn)
                if donor == d['looks_like']:
                    warn_now = warn
            self.looks.setCurrentIndex(max(0, self.looks.findData(d['looks_like'])))
            _bold(self.looks, d['looks_like'] != (d['vanilla_looks'] if custom else d['id']))
            self._show_sounds(d, names)
            self.looks_note.setText(
                'Plays the chosen skill\'s animation, screen flash and sounds; what the skill '
                'DOES (effect, damage, targets, messages) stays its own. Any original skill can '
                'lend its look (measured: none stalls a battle); "(other side)" = made for a '
                'skill aimed at the other side — it may show nothing.'
                + (f'<br><b>Note:</b> {warn_now}' if warn_now else ''))
            aid, atext = d['announce']
            if custom:
                self._show_announce(d)
            else:
                for wdg in [self.ann_mode] + self.ann_lines:
                    wdg.setVisible(False)
                self.announce.setText('(silent)' if aid in (None, 0xFF) else
                                      f"{_readable(atext, d['name'])}   (battle message ${aid:02X})")
            if builtin:
                self._show_params(d)
            # who
            nat = ', '.join(f'{n} (#{s})' for s, n in d['natural']) or 'none'
            ens = ', '.join(str(e) for e in d['enemies'][:40]) + \
                (f' … ({len(d["enemies"])} rows)' if len(d['enemies']) > 40 else '')
            self.who.setText(
                f"<b>Natural skill of:</b> {nat}<br>"
                f"<b>Enemy rows using it (EID):</b> {ens or 'none'}<br>"
                f"<b>Evolves from:</b> {', '.join(n for _t, n in d['evolves_from']) or '—'}"
                f" &nbsp; <b>Evolves into:</b> {', '.join(n for _t, n in d['evolves_to']) or '—'}")
        finally:
            self._busy = False

    def _show_element(self, d):
        self.element.clear()
        nat = d['native_element']
        custom = d['kind'] in ('custom', 'new')
        if d['kind'] == 'custom':
            self.element.addItem('no element (its damage ignores resistances)', None)
        elif nat is not None:
            self.element.addItem(f'its own: {G.RESIST_NAMES[nat]}', None)
            self.element.addItem('none (ignores resistances)', 'none')
        else:
            self.element.addItem('— (its damage tests no resistance)', None)
        for k, n in enumerate(G.RESIST_NAMES):
            self.element.addItem(n, k)
        cur = d['element']
        if cur == CS.ELEMENT_NONE:
            cur = 'none'
        self.element.setCurrentIndex(max(0, self.element.findData(cur)))
        self.element.setEnabled(bool(d['element_editable']) and d['kind'] != 'item_effect')
        _bold(self.element, cur is not None)
        if not d['element_editable'] and d['kind'] == 'custom':
            self.element_note.setText(f"{d['vanilla_name']} deals no damage, so it has no "
                                      "element.")
        elif not d['element_editable']:
            self.element_note.setText('This skill\'s damage tests no resistance (measured), so '
                                      'it has no element to change.')
        elif custom and d['kind'] == 'custom':
            self.element_note.setText('Built-in custom skills deal raw damage; an element runs '
                                      'it through the spell ladder (resistance 1 = 85 %, 2 = '
                                      '½, 3 = immune).')
        else:
            self.element_note.setText('')

    def _show_sounds(self, d, names):
        custom = d['kind'] in ('custom', 'new')
        self.sounds.clear()
        if custom and d['kind'] == 'custom':
            dv = d['vanilla_sounds']
            self.sounds.addItem(f'built-in: {names.get(dv, dv)} (#{dv})', dv)
        else:
            dv = d['looks_like']
            self.sounds.addItem(f'same as the look ({names.get(dv, dv)})', dv)
        for k in range(SK.N_IDS):
            if k != dv:
                self.sounds.addItem(f'{k:3d}  {names.get(k, k)}', k)
        self.sounds.setCurrentIndex(max(0, self.sounds.findData(d['sounds_like'])))
        _bold(self.sounds, d['sounds_like'] != dv)

    def _show_announce(self, d):
        self.ann_mode.setVisible(True)
        self.ann_mode.clear()
        self.ann_mode.addItem('its own line (below)', 0xFD)
        for i, t in self.s.doc.announce_choices():
            self.ann_mode.addItem(f'{_readable(t, "{skill}")}   (${i:02X})', i)
        self.ann_mode.addItem('silent', 0xFF)
        tpl = d['announce_template']
        k = self.ann_mode.findData(tpl)
        if k < 0:
            self.ann_mode.addItem(f'battle message ${tpl:02X}', tpl)
            k = self.ann_mode.count() - 1
        self.ann_mode.setCurrentIndex(k)
        _bold(self.ann_mode, tpl != d['vanilla_announce_template'] or
              'announce' in d['raw_edit'])
        lines = d['announce_lines']
        pages = []
        if lines:
            pages = lines if lines and isinstance(lines[0], list) else [lines]
        flat = []
        for pg in pages[:2]:
            flat += (pg + [''])[:2]
        flat = (flat + [''] * 4)[:4]
        own = tpl == 0xFD
        for e, t in zip(self.ann_lines, flat):
            e.setVisible(own)
            e.setText(t)
        if own:
            self.announce.setText('')
        elif tpl == 0xFF:
            self.announce.setText('(silent)')
        else:
            self.announce.setText(_readable(d['announce_text'], d['name']))

    def _show_params(self, d):
        for wdg in self.params_widgets:
            wdg.setParent(None)
            wdg.deleteLater()
        self.params_widgets = []
        P = d['params']
        sid = d['id']
        self.ratio_edits = {}                   # [S111] test hook: key -> QLineEdit

        def row(widget):
            self.params_box.addWidget(widget)
            self.params_widgets.append(widget)
        if 'tame_meter' in P:
            cur, orig = P['tame_meter']
            w = QWidget()
            h = QHBoxLayout(w)
            h.addWidget(QLabel('Taming meter added per cast:'))
            sp = _spin(0, 1600, 'The recruit meter (the one meat fills): FeedMeat adds 10, '
                                'PorkChop 100, Sirloin 400; the meter caps at 1600.')
            sp.setValue(cur)
            _bold(sp, cur != orig)
            sp.valueChanged.connect(lambda v, o=orig: self._param('tame_meter',
                                                                  None if v == o else v))
            h.addWidget(sp)
            h.addStretch(1)
            row(w)
        if 'quake_power' in P:
            (mn, rg), (omn, org) = P['quake_power']
            w = QWidget()
            h = QHBoxLayout(w)
            h.addWidget(QLabel('Damage to foes (its own side takes the share below):'))
            lo = _spin(0, 255, 'The smallest damage roll')
            hi = _spin(0, 510, 'The largest damage roll (min + up to 255)')
            lo.setValue(mn)
            hi.setValue(mn + rg)
            for sp in (lo, hi):
                _bold(sp, (mn, rg) != (omn, org))
            h.addWidget(lo)
            h.addWidget(QLabel('to'))
            h.addWidget(hi)
            h.addStretch(1)

            def done(_v=None, lo=lo, hi=hi, o=(omn, omn + org)):
                a, b = lo.value(), max(hi.value(), lo.value())
                b = min(b, a + 255)
                self._param('quake_power', None if (a, b) == o else {'min': a, 'max': b})
            lo.valueChanged.connect(done)
            hi.valueChanged.connect(done)
            row(w)
        rlabels = {'burn': 'Share of the current MP it spends',
                   'damage_per_mp': 'Damage to each foe per MP spent',
                   'damage_of_atk': 'Damage, as a share of the caster\'s ATK',
                   'mp_charge': 'Share of the current MP charged on arrival',
                   'ally_damage': 'Share of the damage its own side takes',
                   'per_fallen': 'Extra damage per fallen ally (x the normal hit)'}
        for key in CS.RATIO_KEYS:
            if 'ratio:' + key not in P:
                continue
            cur, dflt, most, _what = P['ratio:' + key]
            w = QWidget()
            h = QHBoxLayout(w)
            h.addWidget(QLabel(rlabels[key] + ':'))
            e = QLineEdit(CS.ratio_text(cur))
            e.setMaxLength(7)
            e.setFixedWidth(70)
            e.setToolTip(f"A fraction such as 1/3 (or a whole number), at most {most}. "
                         f"Original: {CS.ratio_text(dflt)}. Results stop at 999.")
            _bold(e, tuple(cur) != tuple(dflt))

            def fin(key=key, e=e, dflt=dflt, cur=cur):
                t = e.text().strip()
                if t == CS.ratio_text(cur):
                    return
                try:
                    v = CS.ratio_value(t, key, 255)
                except CS.CustomSkillError:
                    v = None
                self._param(key, None if v == tuple(dflt) else t)
            e.editingFinished.connect(fin)
            self.ratio_edits[key] = e
            h.addWidget(e)
            h.addWidget(QLabel(f"(original {CS.ratio_text(dflt)})"))
            h.addStretch(1)
            row(w)
        labels = {'allies_line': 'Line when the wave turns on its own side',
                  'flew_line': 'Line for an ally that flies over it ({name} = the flyer)',
                  'boost_line': 'Line when fallen allies boost the hit'}
        for key in ('allies_line', 'flew_line', 'boost_line'):
            if key in P:
                cur, orig = P[key]
                w = QWidget()
                g = QGridLayout(w)
                g.addWidget(QLabel(labels[key] + ':'), 0, 0, 1, 2)
                cur = cur if cur and not isinstance(cur[0], list) else (cur[0] if cur else [])
                edits = []
                for k in range(2):
                    e = QLineEdit((cur + ['', ''])[k])
                    e.setToolTip('Battle text: 2 lines of 18 cells')
                    g.addWidget(e, 1 + k, 0, 1, 2)
                    edits.append(e)

                def fin(key=key, edits=edits, orig=orig):
                    lines = [x.text() for x in edits]
                    while lines and not lines[-1].strip():
                        lines.pop()
                    o = orig if orig and not isinstance(orig[0], list) else orig[0]
                    self._param(key, None if lines == o else lines)
                for e in edits:
                    e.editingFinished.connect(fin)
                    _bold(e, cur != (orig if orig and not isinstance(orig[0], list) else orig[0]))
                row(w)
        if 'dialogs' in P:
            labels = {'gate_ask': 'Cast in a gate (YES / NO)',
                      'return_ask': 'Cast in town with an anchor (YES / NO)',
                      'err_special': 'Cast in a special / boss room',
                      'err_none': 'Cast in town without an anchor'}
            for key, (cur, orig) in P['dialogs'].items():
                w = QWidget()
                g = QGridLayout(w)
                g.addWidget(QLabel(labels[key] + ':'), 0, 0)
                edits = []
                for k in range(3):
                    e = QLineEdit((list(cur) + ['', '', ''])[k])
                    e.setMaxLength(18)
                    e.setToolTip('A dialog box line (up to 18 characters)')
                    g.addWidget(e, 1 + k, 0)
                    _bold(e, list(cur) != list(orig))
                    edits.append(e)

                def fin(key=key, edits=edits, orig=orig):
                    lines = [x.text() for x in edits]
                    while lines and not lines[-1].strip():
                        lines.pop()
                    D = dict((self.d['raw_edit'] or {}).get('dialogs') or {})
                    if lines == list(orig) or not lines:
                        D.pop(key, None)
                    else:
                        D[key] = lines
                    self._param('dialogs', D or None)
                for e in edits:
                    e.editingFinished.connect(fin)
                row(w)
        if not P:
            row(QLabel('Nothing else: its numbers are in its code.'))

    def _desc_preview(self, *_a):
        from editor2.app.monsters_tab import text_pixmap, _rom
        if self._rom_bytes is None:
            self._rom_bytes = _rom()
        rows = []
        for e in self.desc:
            try:
                rows.append(MT.desc_codes(e.text()))
            except MT.MonsterTextError:
                rows.append([])
        while rows and not rows[-1]:
            rows.pop()
        self.desc_preview.setPixmap(text_pixmap(self._rom_bytes, rows or [[]], SK.DESC_CELLS))

    # ================================================================ edits
    def _push(self, label, op):
        cmd = C.SnapshotCommand(self.s, label, op)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            self.refresh()
            return False
        return True

    def _label(self, what):
        return f"skill {self.sid} {self.d['name']}: {what}"

    def _name_done(self):
        if self._busy:
            return
        txt = self.name.text()
        if txt == self.d['name']:
            return
        sid = self.sid
        self._push(self._label(f'name → {txt}'), lambda doc: doc.set_skill_name(sid, txt))

    def _desc_done(self):
        if self._busy:
            return
        lines = [e.text() for e in self.desc]
        while lines and not lines[-1].strip():
            lines.pop()
        if lines == self.d['description']:
            return
        sid = self.sid
        self._push(self._label('SKIL text'), lambda doc: doc.set_skill_description(sid, lines))

    def _mp_changed(self, v):
        if self._busy or v == self.d['mp']:
            return
        sid = self.sid
        self._push(self._label(f'MP → {v}'), lambda doc: doc.set_skill_mp(sid, v))

    def _learn_changed(self, key, v):
        if self._busy or self.d['learn'] is None or v == self.d['learn'][key]:
            return
        sid = self.sid
        self._push(self._label(f'learn {key} → {v}'),
                   lambda doc: doc.set_skill_learn(sid, {key: v}))

    def _prereqs_done(self):
        if self._busy or self.d['learn'] is None:
            return
        names = {v.lower(): k for k, v in self.s.doc.skill_names_effective().items()}
        out = []
        try:
            for part in [p.strip() for p in self.prereqs.text().split(',') if p.strip()]:
                out.append(names[part.lower()] if part.lower() in names
                           else int(part.replace('$', '0x'), 0))
            if len(out) > 5:
                raise ValueError('at most 5 skills')
        except (ValueError, KeyError) as ex:
            QMessageBox.warning(self, 'Skills', f'Evolves from: {ex}')
            self._show()
            return
        if out == self.d['learn']['prereqs']:
            return
        sid = self.sid
        self._push(self._label('evolves from'), lambda doc: doc.set_skill_learn(sid, {'prereqs': out}))

    def _power_changed(self, side, which='min'):
        if self._busy:
            return
        lo, hi = self.power[side]
        mn, mx = lo.value(), hi.value()
        if mx < mn:                      # the other bound follows the one typed
            if which == 'min':
                mx = mn
            else:
                mn = mx
        mx = min(mx, mn + 0xFFFF)        # the range is a 16-bit value
        R = self.d['record']
        if (mn, mx - mn) == (R[f'{side}_min'], R[f'{side}_range']):
            return
        sid = self.sid
        ch = {f'{side}_min': mn, f'{side}_range': mx - mn}
        self._push(self._label(f'{side} power → {mn}-{mx}'),
                   lambda doc: doc.set_skill_record(sid, ch))

    def _target_changed(self, _i):
        if self._busy:
            return
        v = self.target.currentData()
        if v is None or v == self.d['record']['target_mode']:
            return
        self._record({'target_mode': v}, 'aimed at')

    def _record(self, changes, what):
        if self._busy:
            return
        sid = self.sid
        self._push(self._label(what), lambda doc: doc.set_skill_record(sid, changes))

    def _looks_changed(self, _i):
        if self._busy:
            return
        v = self.looks.currentData()
        if v is None or v == self.d['looks_like']:
            return
        sid = self.sid
        self._push(self._label(f'looks like {v}'), lambda doc: doc.set_skill_looks(sid, v))

    def _reset(self):
        sid = self.sid
        self._push(self._label('back to the original'), lambda doc: doc.reset_skill(sid))

    # ---------------------------------------------------------------- S111
    def _learnable_toggled(self, on):
        if self._busy or self.d['kind'] not in ('custom', 'new'):
            return
        if on == (self.d['learn'] is not None):
            return
        sid = self.sid
        self._push(self._label('learnable' if on else 'not learnable'),
                   lambda doc: doc.set_skill_learn(sid, {'learnable': on} if not on
                                                   else {'level': 1}))

    def _element_changed(self, _i):
        if self._busy:
            return
        v = self.element.currentData()
        cur = self.d['element']
        if cur == CS.ELEMENT_NONE:
            cur = 'none'
        if v == cur:
            return
        sid = self.sid
        lab = 'its own' if v is None else ('none' if v == 'none' else G.RESIST_NAMES[v])
        self._push(self._label(f'element → {lab}'), lambda doc: doc.set_skill_element(sid, v))

    def _sounds_changed(self, _i):
        if self._busy:
            return
        v = self.sounds.currentData()
        if v is None or v == self.d['sounds_like']:
            return
        sid = self.sid
        self._push(self._label(f'sounds like {v}'), lambda doc: doc.set_skill_sounds(sid, v))

    def _ann_lines(self):
        t = [e.text() for e in self.ann_lines]
        p1 = [x for x in t[:2]]
        p2 = [x for x in t[2:]]
        while p1 and not p1[-1].strip():
            p1.pop()
        while p2 and not p2[-1].strip():
            p2.pop()
        if not p1:
            return None
        return [p1, p2] if p2 else p1

    def _ann_mode_changed(self, _i):
        if self._busy:
            return
        v = self.ann_mode.currentData()
        if v is None or v == self.d['announce_template']:
            return
        sid = self.sid
        if v == 0xFD:
            lines = self._ann_lines() or [f'{{name}} uses', f'{self.d["name"]}!']
            self._push(self._label('own announce line'),
                       lambda doc: doc.set_skill_announce(sid, lines=lines))
        else:
            t = 'none' if v == 0xFF else v
            self._push(self._label(f'announced as ${v:02X}'),
                       lambda doc: doc.set_skill_announce(sid, template=t))

    def _ann_lines_done(self):
        if self._busy or self.d['announce_template'] != 0xFD:
            return
        lines = self._ann_lines()
        cur = self.d['announce_lines']
        if lines is None or lines == cur:
            return
        sid = self.sid
        self._push(self._label('announce line'), lambda doc: doc.set_skill_announce(sid, lines=lines))

    def _param(self, key, value):
        if self._busy:
            return
        sid = self.sid
        self._push(self._label(key.replace('_', ' ')),
                   lambda doc: doc.set_skill_param(sid, key, value))

    def _new_skill(self):
        doc = self.s.doc
        bases = doc.clone_bases()
        dlg = QDialog(self)
        dlg.setWindowTitle('New skill')
        f = QFormLayout(dlg)
        f.addRow(QLabel('A new skill runs the effect of an original skill (its BASE) with its '
                        'own name, text, power, targets, look, sounds, element and learning. '
                        'Only bases measured to behave the same under a new id are offered.'))
        base = QComboBox()
        for b, n in bases:
            base.addItem(f'{b:3d}  {n}', b)
        if self.sid < SK.N_IDS and base.findData(self.sid) >= 0:
            base.setCurrentIndex(base.findData(self.sid))
        f.addRow('Base skill:', base)
        name = QLineEdit()
        name.setMaxLength(SK.NAME_MAX)
        f.addRow('Name:', name)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(dlg.accept)
        bb.rejected.connect(dlg.reject)
        f.addRow(bb)
        if dlg.exec() != QDialog.Accepted:
            return
        self.create_skill(base.currentData(), name.text().strip())

    def create_skill(self, base, name):
        """(also the test hook) add a new skill and select it."""
        out = []
        ok_ = self._push(f'new skill {name}', lambda doc: out.append(doc.new_custom_skill(base, name)))
        if ok_ and out:
            self.sid = out[0]
            self.kind.setCurrentIndex(0)
            self.refresh()
        return out[0] if ok_ and out else None

    def _delete_skill(self):
        if self.d.get('kind') != 'new':
            return
        sid = self.sid
        if self._push(self._label('deleted'), lambda doc: doc.delete_custom_skill(sid)):
            self.sid = 0
            self.refresh()
