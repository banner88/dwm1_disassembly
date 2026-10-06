"""services_tab.py — the Services tab (ROADMAP P3.14e1, S126; model: editor2/core/
services_doc.py, compiler: editor2/core/services.py, PROJECT_COMPILER §2.39).

Three pages:
  * Service NPCs — every NPC you made a service NPC (Rooms tab → NPC →
    Service…) and every shopkeeper with its own menu lines; Go to opens it.
  * Menu lines — the line sets: what a service's menu says. A set names its
    kind (Vault, farm, library, namer, Medal Man, eggs or shop), a speaker
    (the name before the ':'), a voice, and the lines it changes; the others
    stay the game's (re-flowed when the speaker's name is longer). "Every NPC
    of this kind" makes the set the words of all of them — the game's own
    NPCs too. Each line shows the game's words beside yours and the box as
    the game draws it.
  * Medal Man — how many medals each reward needs and which egg it is (1-8
    rewards, any monster — a project enemy too), with its line.

Every edit is one undo step (SnapshotCommand).
"""

import re

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QColor
from PySide6.QtWidgets import (QAbstractItemView, QCheckBox, QComboBox, QFormLayout,
                               QGroupBox, QHBoxLayout, QHeaderView, QInputDialog, QLabel,
                               QLineEdit, QListWidget, QListWidgetItem, QMessageBox,
                               QPlainTextEdit, QPushButton, QScrollArea, QSplitter,
                               QTableWidget, QTableWidgetItem, QTabWidget, QVBoxLayout,
                               QWidget)

from editor2.app.rooms import commands as C
from editor2.core import services as SV

HELP = ('The game\'s services work in any room: make an NPC the Vault keeper, a farm keeper, '
        'the librarian, the Monster Namer, the Medal Man, the egg appraiser or the gate guide '
        '(Rooms tab → select the NPC → Service…). There is one Vault, one farm and one medal '
        'count for the whole game. Here: who they are, what their menus say, and the Medal '
        'Man\'s rewards.')
EDITED = QColor(255, 200, 80)
KIND_NAMES = dict({k: v['name'] for k, v in SV.KINDS.items()}, shop='Shopkeeper')
INS_PREVIEW = 'xxxx'               # {ins0}..{ins3}: what the menu fills in (a name, a count);
                                   # 4 cells, as services.TOKEN_CELLS counts them


def _one_line(t):
    return (t or '').replace('\n\n', ' ▸ ').replace('\n', ' ⏎ ')


class ServicesTab(QWidget):
    navigate = Signal(dict)

    def __init__(self, session):
        super().__init__()
        self.s = session
        self._building = False
        v = QVBoxLayout(self)
        top = QLabel(HELP)
        top.setWordWrap(True)
        v.addWidget(top)
        self.pages = QTabWidget()
        v.addWidget(self.pages, 1)
        self.pages.addTab(self._npcs_page(), 'Service NPCs')
        self.pages.addTab(self._lines_page(), 'Menu lines')
        self.pages.addTab(self._medals_page(), 'Medal Man')
        self.s.undo.indexChanged.connect(self._undo_changed)    # bound: dies with the tab
        self.refresh()

    # ============================================================ pages
    def _npcs_page(self):
        w = QWidget()
        v = QVBoxLayout(w)
        self.npcs = QTableWidget(0, 5)
        self.npcs.setHorizontalHeaderLabels(['Room', 'Where', 'NPC', 'Service', 'Menu lines'])
        self.npcs.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.npcs.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.npcs.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.npcs.doubleClicked.connect(lambda _i: self._goto())
        self.npcs.verticalHeader().setVisible(False)
        v.addWidget(self.npcs, 1)
        row = QHBoxLayout()
        b = QPushButton('Go to')
        b.setToolTip('Open this NPC on the Rooms tab')
        b.clicked.connect(self._goto)
        row.addWidget(b)
        self.npcs_note = QLabel('')
        self.npcs_note.setWordWrap(True)
        row.addWidget(self.npcs_note, 1)
        v.addLayout(row)
        return w

    def _lines_page(self):
        w = QWidget()
        h = QHBoxLayout(w)
        left = QVBoxLayout()
        self.sets = QListWidget()
        self.sets.currentRowChanged.connect(self._show_set)
        left.addWidget(self.sets, 1)
        brow = QHBoxLayout()
        b = QPushButton('New…')
        b.clicked.connect(self._new_set)
        brow.addWidget(b)
        self.btn_del_set = QPushButton('Delete')
        self.btn_del_set.clicked.connect(self._delete_set)
        brow.addWidget(self.btn_del_set)
        left.addLayout(brow)
        lw = QWidget()
        lw.setLayout(left)
        lw.setMaximumWidth(300)
        h.addWidget(lw)
        right = QVBoxLayout()
        f = QFormLayout()
        self.set_name = QLineEdit()
        self.set_name.editingFinished.connect(lambda: self._meta('name', self.set_name.text()))
        f.addRow('name', self.set_name)
        self.set_kind = QLabel('')
        f.addRow('for', self.set_kind)
        self.set_speaker = QLineEdit()
        self.set_speaker.setPlaceholderText("the game's (e.g. Pulio)")
        self.set_speaker.setToolTip('The name before the ":" on every line that has one '
                                    '(empty = the game\'s; * = "*:"; hero = the hero\'s name). '
                                    'Max 9 letters. A longer name re-flows the game\'s words.')
        self.set_speaker.editingFinished.connect(
            lambda: self._meta('speaker', self.set_speaker.text().strip() or None))
        f.addRow('speaker', self.set_speaker)
        self.set_voice = QComboBox()
        for label, val in (("the game's", None), ('low (the King, bosses)', 'low'),
                           ('high (Pulio, Watabou)', 'high')):
            self.set_voice.addItem(label, val)
        self.set_voice.currentIndexChanged.connect(
            lambda _i: self._meta('voice', self.set_voice.currentData()))
        f.addRow('voice', self.set_voice)
        self.set_every = QCheckBox('every NPC of this kind speaks these lines (the game\'s too)')
        self.set_every.toggled.connect(lambda on: self._meta('everywhere', on))
        f.addRow('', self.set_every)
        self.set_users = QLabel('')
        self.set_users.setWordWrap(True)
        f.addRow('spoken by', self.set_users)
        right.addLayout(f)
        split = QSplitter(Qt.Vertical)
        self.lines = QTableWidget(0, 3)
        self.lines.setHorizontalHeaderLabels(['#', "The game's words", 'Yours'])
        hh = self.lines.horizontalHeader()
        hh.setSectionResizeMode(0, QHeaderView.ResizeToContents)
        hh.setSectionResizeMode(1, QHeaderView.Stretch)
        hh.setSectionResizeMode(2, QHeaderView.Stretch)
        self.lines.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.lines.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.lines.setSelectionMode(QAbstractItemView.SingleSelection)
        self.lines.verticalHeader().setVisible(False)
        self.lines.currentCellChanged.connect(lambda r, _c, _pr, _pc: self._show_line(r))
        split.addWidget(self.lines)
        ed = QWidget()
        ev = QVBoxLayout(ed)
        self.line_head = QLabel('')
        self.line_head.setWordWrap(True)
        ev.addWidget(self.line_head)
        eh = QHBoxLayout()
        self.line_edit = QPlainTextEdit()
        self.line_edit.setPlaceholderText('Select a line. A box is 2 lines of 18 letters (the '
                                          'first line less the speaker\'s name); a blank line '
                                          'starts a new box. {hero} = the hero\'s name, '
                                          '{ins0}..{ins3} = what the menu fills in.')
        self.line_edit.textChanged.connect(self._preview)
        eh.addWidget(self.line_edit, 1)
        pv = QScrollArea()
        pv.setWidgetResizable(True)
        self.preview = QWidget()
        self.preview_v = QVBoxLayout(self.preview)
        self.preview_v.addStretch(1)
        pv.setWidget(self.preview)
        pv.setMinimumWidth(340)
        eh.addWidget(pv)
        ev.addLayout(eh, 1)
        self.line_probs = QLabel('')
        self.line_probs.setWordWrap(True)
        self.line_probs.setStyleSheet('color: #f88;')
        ev.addWidget(self.line_probs)
        brow = QHBoxLayout()
        self.btn_line_apply = QPushButton('Apply')
        self.btn_line_apply.clicked.connect(self._apply_line)
        brow.addWidget(self.btn_line_apply)
        self.btn_line_game = QPushButton("The game's words")
        self.btn_line_game.clicked.connect(self._line_game)
        brow.addWidget(self.btn_line_game)
        brow.addStretch(1)
        ev.addLayout(brow)
        split.addWidget(ed)
        right.addWidget(split, 1)
        rw = QWidget()
        rw.setLayout(right)
        h.addWidget(rw, 1)
        return w

    def _medals_page(self):
        w = QWidget()
        v = QVBoxLayout(w)
        note = QLabel('Each visit, the Medal Man counts the TinyMedals the player has brought '
                      '(at most 999) and gives the next egg once the count reaches its number '
                      '— it goes to the farm. 1 to 8 rewards, each needing more medals than the '
                      'one before. This is every Medal Man\'s list, the game\'s too.')
        note.setWordWrap(True)
        v.addWidget(note)
        self.medals_state = QLabel('')
        v.addWidget(self.medals_state)
        self.medals = QTableWidget(0, 3)
        self.medals.setHorizontalHeaderLabels(['Medals', 'Egg', 'What he says (empty = the '
                                               'game\'s wording)'])
        hh = self.medals.horizontalHeader()
        hh.setSectionResizeMode(0, QHeaderView.ResizeToContents)
        hh.setSectionResizeMode(1, QHeaderView.Stretch)
        hh.setSectionResizeMode(2, QHeaderView.Stretch)
        self.medals.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.medals.itemChanged.connect(self._medal_cell)
        v.addWidget(self.medals, 1)
        row = QHBoxLayout()
        for text, fn in (('Add reward', self._medal_add), ('Remove', self._medal_remove),
                         ("The game's rewards", self._medal_reset)):
            b = QPushButton(text)
            b.clicked.connect(fn)
            row.addWidget(b)
        row.addStretch(1)
        v.addLayout(row)
        self.medal_probs = QLabel('')
        self.medal_probs.setWordWrap(True)
        self.medal_probs.setStyleSheet('color: #f88;')
        v.addWidget(self.medal_probs)
        return w

    # ============================================================ fill
    def _undo_changed(self, _i):
        self.refresh()

    def refresh(self):
        self._building = True
        try:
            self._fill_npcs()
            self._fill_sets()
            self._fill_medals()
        except Exception as ex:                                   # noqa: BLE001
            self.npcs_note.setText(f'⚠ {ex}')
        finally:
            self._building = False
        self._show_set(self.sets.currentRow())

    def _fill_npcs(self):
        doc = self.s.doc
        names = {st['id']: st['name'] for st in doc.service_line_sets()}
        self._npc_rows = doc.service_npcs()
        self.npcs.setRowCount(len(self._npc_rows))
        for r, (room, key, st, e, sid, spec) in enumerate(self._npc_rows):
            where = f"screen {key}" + (f", state {st}" if st else '') + \
                    f" at ({e.get('x')},{e.get('y')})"
            lines = names.get(spec.get('lines'), "the game's") if spec.get('lines') else "the game's"
            if spec.get('first_time'):
                lines += ' · first visit'
            vals = [room.get('name') or room['id'], where, e.get('actor') or sid,
                    KIND_NAMES.get(spec.get('kind'), spec.get('kind')), lines]
            for c, val in enumerate(vals):
                self.npcs.setItem(r, c, QTableWidgetItem(str(val)))
        self.npcs_note.setText('' if self._npc_rows else
                               'No service NPCs yet — Rooms tab → select an NPC → Service….')

    def _fill_sets(self):
        keep = self.current_set_id()
        self._sets = self.s.doc.service_line_sets()
        self.sets.clear()
        for st in self._sets:
            it = QListWidgetItem(f"{st['name']}  — {KIND_NAMES.get(st['kind'], st['kind'])}"
                                 + ('  (everywhere)' if st['everywhere'] else ''))
            if not st['users'] and not st['everywhere']:
                it.setForeground(QColor(150, 150, 150))
                it.setToolTip('No NPC speaks this set yet')
            self.sets.addItem(it)
        idx = next((i for i, st in enumerate(self._sets) if st['id'] == keep),
                   0 if self._sets else -1)
        self.sets.setCurrentRow(idx)

    def current_set_id(self):
        i = self.sets.currentRow() if hasattr(self, 'sets') else -1
        sets = getattr(self, '_sets', [])
        return sets[i]['id'] if 0 <= i < len(sets) else None

    def current_set(self):
        i = self.sets.currentRow()
        return self._sets[i] if 0 <= i < len(self._sets) else None

    def _show_set(self, _i):
        if self._building:
            return
        st = self.current_set()
        on = st is not None
        for wdg in (self.set_name, self.set_speaker, self.set_voice, self.set_every,
                    self.btn_del_set, self.lines, self.line_edit):
            wdg.setEnabled(on)
        self._building = True
        try:
            if not on:
                self.set_name.setText('')
                self.set_kind.setText('— New… makes a line set for a service —')
                self.set_speaker.setText('')
                self.set_users.setText('')
                self.lines.setRowCount(0)
                self._show_line(-1)
                return
            self.set_name.setText(st['name'])
            b = SV.block(st['kind'], self._repo())
            self.set_kind.setText(f"{KIND_NAMES.get(st['kind'])} — the game's "
                                  f"{b.get('vanilla_npc') or 'lines'}")
            self.set_speaker.setText(st['speaker'] or '')
            self.set_voice.setCurrentIndex(max(0, self.set_voice.findData(st['voice'])))
            self.set_every.setChecked(st['everywhere'])
            self.set_users.setText(', '.join(st['users']) if st['users'] else
                                   ('every NPC of this kind' if st['everywhere'] else
                                    'nobody yet — pick this set in an NPC\'s Service… '
                                    '(or Shopkeeper…) dialog'))
            keep = self.lines.currentRow()
            self.lines.setRowCount(b['count'])
            for off in range(b['count']):
                vl = b['lines'][off]
                txt, changed = self.s.doc.service_line_text(st['id'], off)
                items = [QTableWidgetItem(str(off)), QTableWidgetItem(_one_line(vl['text'])),
                         QTableWidgetItem(_one_line(txt) if changed else
                                          ('(re-flowed) ' + _one_line(txt)
                                           if txt != vl['text'] else ''))]
                if changed:
                    items[2].setForeground(EDITED)
                for c, it in enumerate(items):
                    self.lines.setItem(off, c, it)
            self.lines.setCurrentCell(max(0, keep), 0)
        finally:
            self._building = False
        self._show_line(self.lines.currentRow())

    def _repo(self):
        return getattr(self.s.doc, 'repo_root', None)

    # ------------------------------------------------------------ one line
    def _show_line(self, off):
        if self._building:
            return
        st = self.current_set()
        self._line_off = off if st is not None and off >= 0 else None
        self.btn_line_apply.setEnabled(self._line_off is not None)
        self.btn_line_game.setEnabled(self._line_off is not None)
        if self._line_off is None:
            self.line_head.setText('')
            self.line_edit.setPlainText('')
            return
        b = SV.block(st['kind'], self._repo())
        vl = b['lines'][off]
        who = ('the menu (the game shows it while the screen is open)'
               if off in b.get('engine_offsets', []) else 'the NPC (greeting / farewell)')
        txt, changed = self.s.doc.service_line_text(st['id'], off)
        self.line_head.setText(f"Line {off} — said by {who}. The game's words: "
                               f"“{_one_line(vl['text'])}”"
                               + ('' if changed else ' — not changed'))
        self.line_edit.blockSignals(True)
        self.line_edit.setPlainText(txt)
        self.line_edit.blockSignals(False)
        self._preview()

    def _speaker_for(self, st, vl):
        if vl['voice'] is None or vl['speaker'] is None:
            return ''
        sp = st['speaker'] if st['speaker'] is not None else vl['speaker']
        return sp

    def _preview(self):
        while self.preview_v.count() > 1:
            w = self.preview_v.takeAt(0).widget()
            if w is not None:
                w.deleteLater()
        st = self.current_set()
        if st is None or self._line_off is None:
            self.line_probs.setText('')
            return
        from editor2.app.rooms.talk_editor import render_box
        vl = SV.vline(st['kind'], self._line_off, self._repo())
        text = self.line_edit.toPlainText()
        try:
            probs = self.s.doc.service_line_problems(st['kind'], self._line_off, text,
                                                     st['speaker'])
        except Exception as ex:                                   # noqa: BLE001
            probs = [str(ex)]
        self.line_probs.setText(('⚠ ' + '; '.join(probs) + ' — the game would wrap it in '
                                 'the middle of a word') if probs else '')
        sp = self._speaker_for(st, vl)
        rom = getattr(self.s.renderer, 'rom', None)
        for bi, bx in enumerate(SV.text_boxes(text)):     # the game's box rule
            lines = [re.sub(r'\{ins[0-3]\}', INS_PREVIEW, ln) for ln in bx]
            lab = QLabel()
            try:
                lab.setPixmap(render_box(rom, bi, lines, speaker=sp if bi == 0 else ''))
            except Exception as ex:                               # noqa: BLE001
                lab.setText(f'(preview: {ex})')
            self.preview_v.insertWidget(self.preview_v.count() - 1, lab)

    def _apply_line(self):
        st = self.current_set()
        if st is None or self._line_off is None:
            return
        off, sid, text = self._line_off, st['id'], self.line_edit.toPlainText()
        self._push(f'Line {off} of {st["name"]}',
                   lambda doc: doc.set_service_line(sid, off, text))

    def _line_game(self):
        st = self.current_set()
        if st is None or self._line_off is None:
            return
        off, sid = self._line_off, st['id']
        self._push(f"Line {off} of {st['name']}: the game's words",
                   lambda doc: doc.set_service_line(sid, off, None))

    # ------------------------------------------------------------ set edits
    def _push(self, text, fn):
        cmd = C.SnapshotCommand(self.s, text, fn)
        self.s.undo.push(cmd)
        if getattr(cmd, 'error', None) is not None:
            QMessageBox.warning(self, 'Services', str(cmd.error))
        return cmd

    def _meta(self, key, val):
        if self._building:
            return
        st = self.current_set()
        if st is None:
            return
        cur = {'name': st['name'], 'speaker': st['speaker'], 'voice': st['voice'],
               'everywhere': st['everywhere']}[key]
        if (val or None) == (cur or None) and key != 'everywhere' or \
                (key == 'everywhere' and bool(val) == cur):
            return
        sid = st['id']
        self._push(f'{st["name"]}: {key}',
                   lambda doc: doc.set_service_lines_meta(sid, **{key: val}))

    def _new_set(self):
        kinds = [k for k in SV.LINE_KINDS]
        labels = [KIND_NAMES[k] for k in kinds]
        lab, ok = QInputDialog.getItem(self, 'New line set', 'For which service?', labels, 0,
                                       False)
        if not ok:
            return
        kind = kinds[labels.index(lab)]
        name, ok = QInputDialog.getText(self, 'New line set', 'Name of the line set:',
                                        text=f'{KIND_NAMES[kind]} lines')
        if not ok or not name.strip():
            return
        made = {}

        def op(doc):
            made['id'] = doc.add_service_lines(kind, name.strip())
        self._push(f'New line set {name.strip()}', op)
        if made.get('id'):
            k = next((i for i, st in enumerate(self._sets) if st['id'] == made['id']), -1)
            self.sets.setCurrentRow(k)

    def _delete_set(self):
        st = self.current_set()
        if st is None:
            return
        if QMessageBox.question(self, 'Delete line set',
                                f"Delete {st['name']}? "
                                + (f"{len(st['users'])} NPC(s) go back to the game's lines."
                                   if st['users'] else '')) != QMessageBox.Yes:
            return
        sid = st['id']
        self._push(f"Delete line set {st['name']}", lambda doc: doc.delete_service_lines(sid))

    # ------------------------------------------------------------ NPCs
    def _goto(self):
        r = self.npcs.currentRow()
        rows = getattr(self, '_npc_rows', [])
        if not 0 <= r < len(rows):
            return
        room, key, st, e, _sid, _spec = rows[r]
        self.navigate.emit({'tab': 'rooms', 'room': room['id'], 'screen': key, 'state': st,
                            'x': e.get('x'), 'y': e.get('y')})

    # ------------------------------------------------------------ medals
    def _egg_choices(self):
        from editor2.app.enemies_dialog import vanilla_choices
        from editor2.core import conversation as CV
        doc = self.s.doc
        names = CV.species_names(doc.data)
        out = []
        for e in doc.project_enemies():
            out.append((f"{e.get('id')} — {names.get(int(e.get('species', 0)), 'monster')} "
                        f"(yours, EID {doc.project_eid(e)})", e.get('id')))
        return out + vanilla_choices()

    def _fill_medals(self):
        rows, edited = self.s.doc.medal_rewards_doc()
        self._medal_rows = rows
        self.medals_state.setText("Your rewards." if edited else
                                  "The game's rewards (13 / 18 / 25 / 30 medals). Any change "
                                  "makes them yours.")
        choices = self._egg_choices()
        self.medals.setRowCount(len(rows))
        for r, row in enumerate(rows):
            it = QTableWidgetItem(str(row['medals']))
            self.medals.setItem(r, 0, it)
            combo = QComboBox()
            for label, val in choices:
                combo.addItem(label, val)
            k = combo.findData(row['enemy'])
            if k < 0:
                k = combo.findData(row['eid'])
            combo.setCurrentIndex(max(0, k))
            combo.currentIndexChanged.connect(lambda _i, rr=r: self._medal_egg(rr))
            self.medals.setCellWidget(r, 1, combo)
            lt = QTableWidgetItem(_one_line(row['line']) if row['line'] else '')
            lt.setToolTip('The game would say: ' + _one_line(row['default_line'])
                          + '\nType ⏎ for a new line and ▸ for a new box, or edit in the dialog '
                            '(double-click).')
            self.medals.setItem(r, 2, lt)
        self.medals.resizeRowsToContents()
        probs = [f"reward {i + 1}: {'; '.join(r['problems'])}"
                 for i, r in enumerate(rows) if r.get('problems')]
        for i, r in enumerate(rows):
            if r.get('problems'):
                self.medals.item(i, 2).setForeground(QColor(255, 120, 120))
        self.medal_probs.setText(('⚠ ' + ' · '.join(probs) + ' — the build stops until it fits')
                                 if probs else '')

    def _rewards(self):
        return [{'medals': r['medals'], 'enemy': r['enemy'],
                 **({'line': r['line']} if r['line'] else {})} for r in self._medal_rows]

    def _set_rewards(self, rewards, text):
        self._push(text, lambda doc: doc.set_medal_rewards(rewards))

    def _medal_cell(self, it):
        if self._building:
            return
        r, c = it.row(), it.column()
        rewards = self._rewards()
        if c == 0:
            try:
                rewards[r]['medals'] = int(it.text())
            except ValueError:
                self.medal_probs.setText('⚠ medals: a number')
                self.refresh()
                return
        elif c == 2:
            t = it.text().replace(' ▸ ', '\n\n').replace(' ⏎ ', '\n').strip()
            if t:
                rewards[r]['line'] = t
            else:
                rewards[r].pop('line', None)
        else:
            return
        self._set_rewards(rewards, f'Medal reward {r + 1}')

    def _medal_egg(self, r):
        if self._building:
            return
        combo = self.medals.cellWidget(r, 1)
        rewards = self._rewards()
        rewards[r]['enemy'] = combo.currentData()
        self._set_rewards(rewards, f'Medal reward {r + 1}: egg')

    def _medal_add(self):
        rewards = self._rewards()
        if len(rewards) >= SV.MEDALS_MAX:
            QMessageBox.information(self, 'Medal Man', f'At most {SV.MEDALS_MAX} rewards (the '
                                    'eggs given are remembered by flags $0050-$0057).')
            return
        last = rewards[-1]['medals'] if rewards else 0
        rewards.append({'medals': min(SV.MEDAL_TOTAL_MAX, last + 5), 'enemy': 1})
        self._set_rewards(rewards, 'Add medal reward')

    def _medal_remove(self):
        r = self.medals.currentRow()
        rewards = self._rewards()
        if not 0 <= r < len(rewards) or len(rewards) <= 1:
            return
        rewards.pop(r)
        self._set_rewards(rewards, f'Remove medal reward {r + 1}')

    def _medal_reset(self):
        self._set_rewards(None, "The game's medal rewards")
