"""items_tab.py — the Items tab (ROADMAP E9, S151; model: editor2/core/items_doc.py,
compiler: editor2/core/items.py, PROJECT_COMPILER §2.59).

Left: every item — the game's 43, then the project's own (ids 44-127) — with New item… /
Copy / Delete / Original. Right, for the selected item: its name and description (the
bag / shop words), what it does (the game's code it runs: its own, or for a project item
the game item it WORKS LIKE), every field of its record (price, used-up chance, power,
usable from the field menu, asks for a monster, shops buy it, kept after a lost battle),
its use / result lines (one of the game's 48, or — project items — a line of its own),
its battle half (the game's items 1-37: power / range / usable in battle; a project
item uses its base's) and where the project sells / gives / checks it.

Every edit is one undo step (SnapshotCommand).
"""

import re

from PySide6.QtCore import Qt
from PySide6.QtGui import QColor
from PySide6.QtWidgets import (QCheckBox, QComboBox, QFormLayout, QGroupBox, QHBoxLayout,
                               QInputDialog, QLabel, QListWidget, QListWidgetItem,
                               QMessageBox, QPlainTextEdit, QPushButton, QScrollArea,
                               QSpinBox, QVBoxLayout, QWidget)

from editor2.app.rooms import commands as C
from editor2.core import items as IT
from editor2.core import textmark as TM

HELP = ('Every item of the game can be edited here, and you can add NEW items (up to 84, '
        'ids 44-127). A new item WORKS LIKE one of the game\'s items — it runs that item\'s '
        'code (a Herb heals, a seed raises a stat, a WarpWing leaves the gate) with its own '
        'name, price, power and the rest. Sell new items in a shop (Shops tab) or give them '
        '(conversations, cutscenes, quests).')
EDITED = QColor(255, 200, 80)
YOURS = QColor(140, 220, 140)


def plain_line(markup):
    """A use line's markup in short words: {ins 00} = the hero, {ins 10} = the monster,
    {ins 20} = the item."""
    s = markup or ''
    s = s.replace('{ins 00}', '‹hero›').replace('{ins 10}', '‹monster›')
    s = s.replace('{ins 20}', '‹item›')
    s = re.sub(r'\{[^}]*\}', ' ', s).replace('\n', ' ')
    return re.sub(r'\s+', ' ', s).strip()


class MarkupField(QWidget):
    """An item's words as markup (the Text tab's: a new line = the next row, {codes}) with
    the game-font picture beside it (text_tab.render, rows style; cells past `width` red),
    the status and Apply. The rule (EDITOR_DESIGN §5.0 "Game text"): no game words in a
    plain text edit without the game's picture."""

    def __init__(self, tab, width, height, on_apply, tip='', style='rows'):
        super().__init__()
        self.tab, self.width_cells, self.on_apply = tab, width, on_apply
        self.style = style                      # S157: 'box' for a dialogue line
        self.markup = ''
        h = QHBoxLayout(self)
        h.setContentsMargins(0, 0, 0, 0)
        col = QVBoxLayout()
        self.edit = QPlainTextEdit()
        self.edit.setFixedHeight(height)
        self.edit.setToolTip(tip)
        self.edit.textChanged.connect(self._preview)
        col.addWidget(self.edit)
        row = QHBoxLayout()
        self.status = QLabel('')
        row.addWidget(self.status, 1)
        self.apply_b = QPushButton('Apply')
        self.apply_b.clicked.connect(self._apply)
        row.addWidget(self.apply_b)
        col.addLayout(row)
        h.addLayout(col, 1)
        self.pic = QLabel()
        self.pic.setAlignment(Qt.AlignTop | Qt.AlignLeft)
        h.addWidget(self.pic)

    def set(self, markup, enabled=True):
        self.markup = markup or ''
        self.edit.blockSignals(True)
        self.edit.setPlainText(self.markup)
        self.edit.blockSignals(False)
        self.edit.setEnabled(enabled)
        self._preview()

    def text(self):
        return self.edit.toPlainText()

    def _preview(self):
        from editor2.app.text_tab import render
        txt = self.text()
        rom = getattr(getattr(self.tab.s, 'renderer', None), 'rom', None)
        try:
            raw = TM.encode(txt, self.style) if txt else b''
            err = None
        except ValueError as ex:
            raw, err = None, str(ex)
        if raw is not None:
            if txt:
                self.pic.setPixmap(render(rom, raw, self.style, self.width_cells))
            else:
                self.pic.clear()
            self.status.setStyleSheet('color: #2a7a2a;')
            self.status.setText(f'{len(raw)} bytes' if txt else 'empty')
        else:
            self.pic.clear()
            self.status.setStyleSheet('color: #c62828;')
            self.status.setText('✗ ' + err)
        self.apply_b.setEnabled(self.edit.isEnabled() and raw is not None and
                                txt != self.markup)

    def _apply(self):
        if self.text() != self.markup:
            self.on_apply(self.text())


class ItemsTab(QWidget):
    def __init__(self, session):
        super().__init__()
        self.s = session
        self._building = False
        self.info = None
        v = QVBoxLayout(self)
        top = QLabel(HELP)
        top.setWordWrap(True)
        v.addWidget(top)
        h = QHBoxLayout()
        v.addLayout(h, 1)
        # ---- the list
        left = QVBoxLayout()
        self.list = QListWidget()
        self.list.currentRowChanged.connect(self._show)
        left.addWidget(self.list, 1)
        r1 = QHBoxLayout()
        b = QPushButton('New item…')
        b.setToolTip('A new item that works like one of the game\'s items')
        b.clicked.connect(self._new)
        r1.addWidget(b)
        self.btn_copy = QPushButton('Copy')
        self.btn_copy.setToolTip('A new item with every field of the selected one')
        self.btn_copy.clicked.connect(self._copy)
        r1.addWidget(self.btn_copy)
        left.addLayout(r1)
        r2 = QHBoxLayout()
        self.btn_delete = QPushButton('Delete')
        self.btn_delete.clicked.connect(self._delete)
        r2.addWidget(self.btn_delete)
        self.btn_orig = QPushButton('Original')
        self.btn_orig.setToolTip('The game\'s item back as the game has it (fields, words, '
                                 'battle power)')
        self.btn_orig.clicked.connect(self._original)
        r2.addWidget(self.btn_orig)
        left.addLayout(r2)
        self.count = QLabel('')
        left.addWidget(self.count)
        lw = QWidget()
        lw.setLayout(left)
        lw.setMaximumWidth(260)
        h.addWidget(lw)
        # ---- the item
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        body = QWidget()
        bv = QVBoxLayout(body)
        self.head = QLabel('')
        self.head.setWordWrap(True)
        bv.addWidget(self.head)

        g = QGroupBox('Words')
        f = QFormLayout(g)
        self.name = MarkupField(self, IT.NAME_MAX, 30, self._name_done,
                                f'At most {IT.NAME_MAX} letters (the bag and shop column)')
        f.addRow('Name', self.name)
        self.desc = MarkupField(self, 18, 54, self._desc_done,
                                'Two lines of up to 18 letters (the bag\'s INFO box)')
        f.addRow('Description', self.desc)
        bv.addWidget(g)

        g = QGroupBox('What it does')
        f = QFormLayout(g)
        self.base = QComboBox()
        self.base.activated.connect(self._base_changed)
        f.addRow('Works like', self.base)
        self.effect = QLabel('')
        self.effect.setWordWrap(True)
        self.effect.setStyleSheet('color: #9fd0ff;')
        f.addRow('', self.effect)
        self.power = QSpinBox()
        self.power.setRange(0, 255)
        self.power.editingFinished.connect(lambda: self._field('power', self.power.value()))
        f.addRow('Power', self.power)
        self.consume = QSpinBox()
        self.consume.setRange(0, 100)
        self.consume.setSuffix(' %')
        self.consume.setToolTip('The chance that using it uses it up: 100 = always, 0 = never '
                                '(a permanent item)')
        self.consume.editingFinished.connect(lambda: self._field('consume',
                                                                 self.consume.value()))
        f.addRow('Used up', self.consume)
        # S157 (ROADMAP E9): used-up 0 = permanent = ONE-ONLY
        self.one_only = QLabel('')
        self.one_only.setWordWrap(True)
        self.one_only.setStyleSheet('color: #e0b050;')
        f.addRow('', self.one_only)
        self.field_use = QCheckBox('Can be used from the field menu')
        self.field_use.setToolTip('Off: "… uses the X as a tool. But nothing happens." '
                                  '(a key item)')
        self.field_use.clicked.connect(lambda c: self._field('field_use', bool(c)))
        f.addRow('', self.field_use)
        self.pick = QCheckBox('Asks which monster')
        self.pick.clicked.connect(lambda c: self._field('pick_monster', bool(c)))
        f.addRow('', self.pick)
        bv.addWidget(g)

        g = QGroupBox('Shops and battles lost')
        f = QFormLayout(g)
        self.price = QSpinBox()
        self.price.setRange(0, 65535)
        self.price.setSuffix(' G')
        self.price.editingFinished.connect(lambda: self._field('price', self.price.value()))
        f.addRow('Price', self.price)
        self.sell = QLabel('')
        f.addRow('Shops pay', self.sell)
        self.sellable = QCheckBox('Shops buy it (it is on the SELL list)')
        self.sellable.clicked.connect(lambda c: self._field('sellable', bool(c)))
        f.addRow('', self.sellable)
        self.keep = QCheckBox('Kept when the party loses a battle')
        self.keep.clicked.connect(lambda c: self._field('keep_on_loss', bool(c)))
        f.addRow('', self.keep)
        bv.addWidget(g)

        g = QGroupBox('Lines')
        f = QFormLayout(g)
        self.use_line = QComboBox()
        self.use_line.activated.connect(lambda _i: self._line('use_message', self.use_line))
        f.addRow('Use line', self.use_line)
        self.result_line = QComboBox()
        self.result_line.activated.connect(lambda _i: self._line('result_message',
                                                                 self.result_line))
        f.addRow('Result line', self.result_line)
        own_tip = ('A line of its own (your items): {ins 00} = the hero, {ins 10} = the '
                   'monster, {ins 20} = the item; a new line = the next line of the box. '
                   'Empty + Apply = back to a game line.')
        self.own_use = MarkupField(self, 18, 54, lambda t: self._own('use', t), own_tip)
        f.addRow('Own use line', self.own_use)
        self.own_result = MarkupField(self, 18, 54, lambda t: self._own('result', t), own_tip)
        f.addRow('Own result line', self.own_result)
        note = QLabel('The game\'s 48 lines are edited on the Text tab (Items page).')
        note.setWordWrap(True)
        f.addRow('', note)
        bv.addWidget(g)

        g = QGroupBox('In battle')
        f = QFormLayout(g)
        self.b_usable = QCheckBox('Can be used in battle')
        self.b_usable.clicked.connect(lambda c: self._battle(usable=bool(c)))
        f.addRow('', self.b_usable)
        self.b_power = QSpinBox()
        self.b_power.setRange(0, 999)
        self.b_power.editingFinished.connect(lambda: self._battle(power=self.b_power.value()))
        f.addRow('Battle power', self.b_power)
        self.b_range = QSpinBox()
        self.b_range.setRange(0, 999)
        self.b_range.setToolTip('The random extra: the effect is power + 0..range')
        self.b_range.editingFinished.connect(lambda: self._battle(range_=self.b_range.value()))
        f.addRow('+ random up to', self.b_range)
        self.b_note = QLabel('')
        self.b_note.setWordWrap(True)
        f.addRow('', self.b_note)
        bv.addWidget(g)

        # S157 (ROADMAP E9): the one-only items — a project-wide line
        g = QGroupBox('One-only items (used up 0 %)')
        f = QFormLayout(g)
        self.oo_list = QLabel('')
        self.oo_list.setWordWrap(True)
        f.addRow('This project', self.oo_list)
        self.oo_line = MarkupField(
            self, 18, 54, self._rule_done,
            'Shown instead of a give\'s "bag full" words when the player already holds a '
            'one-only item (the game\'s scripts and yours). {ins 00} = the item\'s name, '
            '{hero} = the hero; a new line = the next line of the box. Empty + Apply = the '
            'default.', style='box')
        f.addRow('"Already has" line', self.oo_line)
        bv.addWidget(g)

        self.uses = QLabel('')
        self.uses.setWordWrap(True)
        self.uses.setStyleSheet('color: #9fd0ff;')
        bv.addWidget(self.uses)
        bv.addStretch(1)
        scroll.setWidget(body)
        h.addWidget(scroll, 1)
        self.s.undo.indexChanged.connect(self._undo_changed)
        self.refresh()

    # ------------------------------------------------------------ fill
    def _undo_changed(self, _i):
        from shiboken6 import isValid
        if not isValid(self):
            return
        if self.isVisibleTo(self.window()):
            self.refresh()
        else:
            self._stale = True

    def showEvent(self, ev):
        if getattr(self, '_stale', False):
            self._stale = False
            self.refresh()
        super().showEvent(ev)

    def current_id(self):
        it = self.list.currentItem() if hasattr(self, 'list') else None
        return it.data(Qt.UserRole) if it is not None else None

    def refresh(self):
        keep = self.current_id()
        self._building = True
        try:
            rows = self.s.doc.item_list()
        except Exception as ex:                             # noqa: BLE001
            self.head.setText(f'⚠ {ex}')
            self._building = False
            return
        self.list.clear()
        for row in rows:
            it = QListWidgetItem(f"{row['id']:3d}  {row['name']}" +
                                 (f"  — like {self._names().get(row['base'], row['base'])}"
                                  if row['new'] else ''))
            it.setData(Qt.UserRole, row['id'])
            if row['new']:
                it.setForeground(YOURS)
            elif row['edited']:
                it.setForeground(EDITED)
            self.list.addItem(it)
        n_new = sum(1 for r in rows if r['new'])
        self.count.setText(f'{n_new} of {IT.ID_MAX + 1 - IT.FIRST_NEW} new items')
        names = self._names()
        self.base.clear()
        for i in range(1, IT.GAME_ITEMS):
            self.base.addItem(f"{IT.game_names(getattr(self.s.doc, 'repo_root', None)).get(i, i)}"
                              f" — {IT.EFFECTS[i][0]}", i)
        del names
        lines = self.s.doc.use_lines()
        for cb in (self.use_line, self.result_line):
            cb.clear()
        self.result_line.addItem('(none)', 0)
        for n, words in lines:
            self.use_line.addItem(f'{n:2d}: {plain_line(words)[:60]}', n)
            if n:
                self.result_line.addItem(f'{n:2d}: {plain_line(words)[:60]}', n)
        self._building = False
        k = next((r for r in range(self.list.count())
                  if self.list.item(r).data(Qt.UserRole) == keep), 0)
        self.list.setCurrentRow(k)
        self._show(k)

    def _names(self):
        if getattr(self, '_names_cache_idx', None) != self.s.undo.index():
            self._names_cache = self.s.doc.item_names_all()
            self._names_cache_idx = self.s.undo.index()
        return self._names_cache

    def _show(self, _row):
        if self._building:
            return
        i = self.current_id()
        if i is None:
            return
        try:
            info = self.s.doc.item_info(i)
        except Exception as ex:                             # noqa: BLE001
            self.head.setText(f'⚠ {ex}')
            return
        self.info = info
        self._building = True
        f, van, new = info['fields'], info['vanilla'], info['new']
        self.head.setText(f"<b>{info['name']}</b> — item {i}" +
                          (f" (yours: works like the {info['base_name']})" if new else
                           ' (the game\'s)'))
        self.name.set(info['name'])
        self.desc.set(info['description'])
        k = self.base.findData(info['base'])
        self.base.setCurrentIndex(k)
        self.base.setEnabled(new)
        self.effect.setText(f"{info['effect']}")
        self.power.setValue(f['power'])
        self.consume.setValue(f['consume'])
        self.field_use.setChecked(f['field_use'])
        self.pick.setChecked(f['pick_monster'])
        self.price.setValue(f['price'])
        self.sell.setText(f"{info['sell']} G" if f['sellable'] else '— (not on the SELL list)')
        self.sellable.setChecked(f['sellable'])
        self.keep.setChecked(f['keep_on_loss'])
        # S157: a permanent item is always kept after a lost battle (the compiler sets it)
        self.keep.setEnabled(not info['one_only'])
        self.keep.setToolTip('A permanent item (used up 0 %) is always kept.'
                             if info['one_only'] else '')
        if info['one_only']:
            self.one_only.setText(
                'Permanent = ONE-ONLY: the player holds just one (the bag and the Vault '
                'together). Shops hide it while one is held and sell one at a time; a give '
                'of one already held shows the "already has" line (below); it never lies on '
                'random gate floors, in their chests or as a Coliseum prize; it is always '
                'kept after a lost battle.' +
                ''.join('\n• ' + n for n in info['loot_notes']))
            self.one_only.show()
        else:
            self.one_only.hide()
        for w, key in ((self.power, 'power'), (self.consume, 'consume'),
                       (self.price, 'price')):
            w.setStyleSheet('color: rgb(255,200,80);' if f[key] != van[key] else '')
        self._set_line_combo(self.use_line, f['use_message'], info['use_text'])
        self._set_line_combo(self.result_line, f['result_message'], info['result_text'])
        oo = self.s.doc.one_only_names()
        self.oo_list.setText(', '.join(f'{n} ({i})' for i, n in oo) or 'none')
        self.oo_line.set(self.s.doc.item_rule('already_has'))
        self.own_use.set(info['use_text'] or '', new)
        self.own_result.set(info['result_text'] or '', new)
        b = info['battle']
        own = b['own']
        for w in (self.b_usable, self.b_power, self.b_range):
            w.setEnabled(own)
        self.b_usable.setChecked(b['usable'])
        self.b_power.setValue(b['power'])
        self.b_range.setValue(b['range'])
        if b.get('field_only'):
            self.b_note.setText('Field-only: the game never lets the hero use this item in '
                                'battle ("Can\'t use this item in battle!"), and new items '
                                'that work like it are field-only too. Its battle-skill id '
                                f"({b['skill']}) can hold one of your new skills (Skills tab).")
            for w in (self.b_usable, self.b_power, self.b_range):
                w.setEnabled(False)
        elif not b['item_effect']:
            self.b_note.setText('This item does nothing in battle in the game (no battle '
                                'skill of its own).')
            for w in (self.b_usable, self.b_power, self.b_range):
                w.setEnabled(False)
        elif new:
            self.b_note.setText(f"In battle a new item does what its base does — the "
                                f"{info['base_name']}'s battle power ({b['power']} + 0-"
                                f"{b['range']}); edit it on the {info['base_name']}. Its "
                                'name in the battle text is its own.')
        else:
            self.b_note.setText(f"Item skill {b['skill']} (Skills tab). New items that work "
                                'like this one use it too.')
        uses = self.s.doc.item_uses(i)
        self.uses.setText(('Used by the project: ' + '; '.join(uses)) if uses else
                          ('Nothing sells or gives it yet — add it to a shop (Shops tab) or '
                           'give it in a conversation.' if new else ''))
        self.btn_copy.setEnabled(True)
        self.btn_delete.setEnabled(new)
        self.btn_orig.setEnabled(not new)
        self._building = False

    def _set_line_combo(self, cb, n, own):
        while cb.count() and (cb.itemData(cb.count() - 1) or 0) >= IT.USE_MESSAGES:
            cb.removeItem(cb.count() - 1)          # the previous item's own line
        k = cb.findData(n)
        if k < 0:                                 # an own line (48+)
            cb.addItem(f'(its own line) {plain_line(own)[:50]}', n)
            k = cb.count() - 1
        cb.setCurrentIndex(k)
        cb.setEnabled(not own)

    # ------------------------------------------------------------ edits
    def _push(self, text, fn):
        cmd = C.SnapshotCommand(self.s, text, fn)
        self.s.undo.push(cmd)
        if getattr(cmd, 'error', None) is not None:
            QMessageBox.warning(self, 'Items', str(cmd.error))
            self.refresh()
        return cmd

    def _field(self, key, value):
        if self._building or self.info is None:
            return
        if self.info['fields'].get(key) == value:
            return
        i, nm = self.info['id'], self.info['name']
        self._push(f'{nm}: {key} {value}', lambda doc: doc.set_item_field(i, key, value))

    def _line(self, key, cb):
        if self._building or self.info is None:
            return
        n = cb.currentData()
        self._field(key, n)

    def _rule_done(self, txt):
        """S157: the one-only "already has" line (gamedata.item_rules.already_has)."""
        def do(d):
            d.set_item_rule('already_has', txt)
        self._push('"already has" line', do)

    def _own(self, which, text):
        if self._building or self.info is None:
            return
        i, nm = self.info['id'], self.info['name']
        markup = text or None
        self._push(f'{nm}: own {which} line',
                   lambda doc: doc.set_item_own_line(i, which, markup))

    def _name_done(self, t):
        if self._building or self.info is None:
            return
        if t == self.info['name']:
            return
        i = self.info['id']
        self._push(f'Item {i}: name {t}', lambda doc: doc.set_item_name(i, t))

    def _desc_done(self, t):
        if self.info is None:
            return
        if t == self.info['description']:
            return
        i, nm = self.info['id'], self.info['name']
        self._push(f'{nm}: description', lambda doc: doc.set_item_description(i, t))

    def _base_changed(self, _k):
        if self._building or self.info is None or not self.info['new']:
            return
        base = self.base.currentData()
        if base == self.info['base']:
            return
        i, nm = self.info['id'], self.info['name']
        self._push(f'{nm}: works like item {base}', lambda doc: doc.set_item_base(i, base))

    def _battle(self, **kw):
        if self._building or self.info is None or not self.info['battle']['own']:
            return
        b = self.info['battle']
        if ('power' in kw and kw['power'] == b['power']) or \
                ('range_' in kw and kw['range_'] == b['range']) or \
                ('usable' in kw and kw['usable'] == b['usable']):
            return
        i, nm = self.info['id'], self.info['name']
        self._push(f'{nm}: battle', lambda doc: doc.set_item_battle(i, **kw))

    def _select(self, i):
        for r in range(self.list.count()):
            if self.list.item(r).data(Qt.UserRole) == i:
                self.list.setCurrentRow(r)
                return

    def _new(self):
        gn = IT.game_names(getattr(self.s.doc, 'repo_root', None))
        labels = [f'{gn.get(i, i)} — {IT.EFFECTS[i][0]}' for i in range(1, IT.GAME_ITEMS)]
        cur = self.info['base'] - 1 if self.info else 0
        lab, ok = QInputDialog.getItem(self, 'New item', 'It works like:', labels, cur, False)
        if not ok:
            return
        base = labels.index(lab) + 1
        name, ok = QInputDialog.getText(self, 'New item',
                                        f'Its name (up to {IT.NAME_MAX} letters):')
        if not ok:
            return
        out = {}

        def op(doc):
            out['id'] = doc.new_item(base, name.strip() or None)
        self._push(f'New item like {gn.get(base, base)}', op)
        if out.get('id'):
            self._select(out['id'])

    def _copy(self):
        if self.info is None:
            return
        src, base = self.info['id'], self.info['base']
        out = {}

        def op(doc):
            out['id'] = doc.new_item(base, None, copy_of=src)
        self._push(f"Copy of {self.info['name']}", op)
        if out.get('id'):
            self._select(out['id'])

    def _delete(self):
        if self.info is None or not self.info['new']:
            return
        i, nm = self.info['id'], self.info['name']
        uses = self.s.doc.item_uses(i)
        msg = f'Delete {nm}?'
        if uses:
            msg += ' It is still used: ' + '; '.join(uses[:6]) + '. Those uses will refuse ' \
                   'to build until you change them.'
        if QMessageBox.question(self, 'Delete item', msg + ' (Undo brings it back.)') != \
                QMessageBox.Yes:
            return
        self._push(f'Delete {nm}', lambda doc: doc.delete_item(i, force=True))

    def _original(self):
        if self.info is None or self.info['new']:
            return
        i, nm = self.info['id'], self.info['name']
        self._push(f'{nm}: original', lambda doc: doc.reset_item(i))
