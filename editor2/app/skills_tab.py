"""skills_tab.py — the Skills tab (ROADMAP P3.11, S110; EDITOR_DESIGN §5.3
"As built S110"; model: editor2/core/skills_doc.py; compiler: gamedata.skills
→ editor2/core/gamedata.py + editor2/core/skills.py, PROJECT_COMPILER §2.26).

Left: the 222 original skills (search, kind filter: skills / battle actions &
boss moves / battle items), bold = changed; the text space meters. Right, one
foldable section per topic:

  Name and SKIL text   name (1-9) + the SKIL-menu description (3 x 18) with the
                       game font preview
  MP and learning      one MP field (battle + field copies), learn level, the six
                       stat requirements, the skills it evolves from
  Power                min-max for party casters and for enemies
  Targets              one foe / all foes / one ally / all allies / the user
  Monster AI           plan, weight, element, damage class (only the AI reads them)
  Behaviour            the record flags some code reads (each with what it does);
                       the bytes / bits nothing reads, greyed
  Looks and sounds     play another skill's animation + sounds; the announce line
  Who has it           natural learners, enemy rows, evolve chain, shared effect

Battle items (ids 176-212) are listed read-only: they are edited with the
items (the Items tab, ROADMAP E9). Every edit is one undo step
(SnapshotCommand); the model validates with the compiler's own code.
"""

from PySide6.QtCore import Qt
from PySide6.QtGui import QFont
from PySide6.QtWidgets import (QCheckBox, QComboBox, QFormLayout, QGridLayout,
                               QHBoxLayout, QLabel, QLineEdit, QListWidget,
                               QListWidgetItem, QMessageBox, QPushButton,
                               QScrollArea, QSpinBox, QSplitter, QVBoxLayout,
                               QWidget)

from editor2.app.collapsible import Section
from editor2.app.rooms import commands as C
from editor2.core import gamedata as G
from editor2.core import monster_text as MT
from editor2.core import skills as SK

HELP = ('Every original skill: its name and SKIL-menu text, MP, when monsters learn it, '
        'its power, who it hits, how the monster AI treats it, the battle rules it '
        'follows, and which skill\'s animation and sounds it plays. Hover any field for '
        'what the game does with it. Bold = changed.')
KIND_FILTER = [('All skills', None), ('Skills', 'skill'),
               ('Battle actions / boss moves', 'internal'), ('Battle items (read-only)',
                                                             'item_effect')]
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
        g.addWidget(QLabel('Looks and sounds like:'), 0, 0)
        self.looks = QComboBox()
        self.looks.setToolTip(SK.LOOKS_HINT)
        self.looks.currentIndexChanged.connect(self._looks_changed)
        g.addWidget(self.looks, 0, 1)
        self.looks_note = QLabel()
        self.looks_note.setWordWrap(True)
        g.addWidget(self.looks_note, 1, 0, 1, 3)
        g.addWidget(QLabel('Announced as:'), 2, 0)
        self.announce = QLabel()
        self.announce.setToolTip('The battle message shown when the skill is used (bank '
                                 '$58 AnnounceTemplateTable). Read-only until the dialogue '
                                 'editor (ROADMAP P3.6).')
        self.announce.setTextInteractionFlags(Qt.TextSelectableByMouse)
        g.addWidget(self.announce, 2, 1, 1, 2)
        self.sec_looks = self._section('Looks and sounds', 'looks', w)

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
            self.meters.setText(
                f"Skill names: {u['names'][0]} / {u['names'][1]} B (more spill into the "
                f"shared bank $41 space).  SKIL texts: {u['descs'][0]} / {u['descs'][1]} B "
                f"+ spare {u['extra'][0]} / {u['extra'][1]} B.")
        except SK.SkillError as ex:
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
            self.title.setText(f"{d['name']}   #{d['id']} (${d['id']:02X})")
            self.kind_note.setText(
                ('A skill monsters learn and cast.' if d['kind'] == 'skill' else
                 f"{SK.KIND_LABEL.get(d['kind'], d['kind']).capitalize()}.")
                + (' Battle items are edited with the items (the Items tab, not built yet) '
                   '— shown read-only here.' if item else '')
                + (' A battle action / boss move: monsters do not learn it from the SKIL '
                   'menu, but bosses and enemy rows may use it.' if d['kind'] == 'internal'
                   else ''))
            self.reset_btn.setEnabled(d['edited'] and not item)
            for w in (self.sec_text, self.sec_cost, self.sec_power, self.sec_target,
                      self.sec_ai, self.sec_flags, self.sec_looks):
                w.content.setEnabled(not item)
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
            self.mp.setEnabled(not allmp)
            self.mp.setValue(d['battle_mp'] if allmp else min(d['mp'], 255))
            _bold(self.mp, d['mp'] != d['vanilla_mp'])
            if allmp:
                self.mp_note.setText('All MP — the game empties the caster\'s MP in this '
                                     'skill\'s own code; not a number.')
            elif d['vanilla_battle_mp'] != (d['vanilla_mp'] & 0xFF):
                self.mp_note.setText('Field-only skill: the field menu charges this; in '
                                     'battle it is never cast.')
            else:
                self.mp_note.setText('Charged in battle and in the field menu.')
            L, VL = d['learn'], d['vanilla_learn']
            for k, sp in self.learn.items():
                sp.setEnabled(L is not None)
                sp.setValue(L[k] if L else 0)
                _bold(sp, L is not None and L[k] != VL[k])
            self.prereqs.setEnabled(L is not None)
            names = doc.skill_names_effective()
            self.prereqs.setText(', '.join(names.get(x, str(x)) for x in (L or {}).get('prereqs', [])))
            _bold(self.prereqs, L is not None and L['prereqs'] != VL['prereqs'])
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
            self.power_note.setText(
                'Damage / healing = a random value from min to max (the party pair for your '
                'monsters, the enemy pair for enemies). '
                + (f"Its effect code is shared with: {', '.join(names.get(x, str(x)) for x in shared)}."
                   if shared else 'Its effect code is its own.'))
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
            self.looks.addItem(f"its own look ({d['vanilla_name']})", d['id'])
            model = self.looks.model()
            warn_now = None
            for donor, nm, problem, warn in doc.skill_lend_options(d['id']):
                if donor == d['id']:
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
            _bold(self.looks, d['looks_like'] != d['id'])
            self.looks_note.setText(
                'Plays the chosen skill\'s animation, screen flash and sounds; what the skill '
                'DOES (effect, damage, targets, messages) stays its own. Any original skill can '
                'lend its look (measured: none stalls a battle); "(other side)" = made for a '
                'skill aimed at the other side — it may show nothing.'
                + (f'<br><b>Note:</b> {warn_now}' if warn_now else ''))
            aid, atext = d['announce']
            self.announce.setText('(silent)' if aid in (None, 0xFF) else
                                  f"{_readable(atext, d['name'])}   (battle message ${aid:02X})")
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
