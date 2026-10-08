"""palette_borrow_dialog.py — Borrow palette… (S132, Palettes page).

User S132: "Need to be able to borrow palette from any other room without
having to recreate it." Pick any room — yours, the game's (any screen and
step, e.g. the Servant room on fire), or a gate theme — see its screen in its
own colours next to YOUR screen re-coloured live, then take the whole palette
(for the room, or only this screen / state; your own palettes can be shared
instead of copied) or only some rows into chosen slots. The data work is
editor2/core/palette_borrow.py; the tab pushes one undo step.
"""

from PIL import ImageQt
from PySide6.QtCore import QRect, QSize, Qt
from PySide6.QtGui import QColor, QPainter, QPixmap
from PySide6.QtWidgets import (QButtonGroup, QCheckBox, QComboBox, QDialog,
                               QDialogButtonBox, QGridLayout, QGroupBox,
                               QHBoxLayout, QLabel, QLineEdit, QListWidget,
                               QListWidgetItem, QRadioButton, QVBoxLayout,
                               QWidget)

from editor2.core import palette_borrow as PB
from editor2.core.render_project import rgb555

SW = 24


class RowsView(QWidget):
    """4 palette rows as swatches (read-only), row numbers on the left;
    `marked` rows get a yellow frame (the rows being copied)."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.rows = None
        self.free1 = False
        self.marked = set()
        self.setFixedSize(self.sizeHint())

    def sizeHint(self):
        return QSize(22 + 4 * (SW + 3) + 4, 4 * (SW + 3) + 4)

    def set_rows(self, rows, free1=False, marked=()):
        self.rows, self.free1, self.marked = rows, free1, set(marked)
        self.update()

    def paintEvent(self, _ev):
        p = QPainter(self)
        p.fillRect(self.rect(), QColor(36, 36, 40))
        if not self.rows:
            return
        for s, row in enumerate(self.rows[:4]):
            y = 2 + s * (SW + 3)
            p.setPen(QColor(220, 220, 220))
            p.drawText(QRect(0, y, 18, SW), Qt.AlignRight | Qt.AlignVCenter, str(s))
            for i, w in enumerate(row[:4]):
                r = QRect(22 + i * (SW + 3), y, SW, SW)
                p.fillRect(r, QColor(*rgb555(int(w) & 0x7FFF)))
                p.setPen(QColor(90, 90, 90))
                p.drawRect(r.adjusted(0, 0, -1, -1))
            if s in self.marked:
                p.setPen(QColor(255, 220, 40))
                p.drawRect(QRect(20, y - 2, 4 * (SW + 3) + 2, SW + 3))


def _pix(img, scale=2):
    if img is None:
        return QPixmap()
    if scale != 1:
        img = img.resize((img.width * scale, img.height * scale))
    return QPixmap.fromImage(ImageQt.ImageQt(img))


class BorrowPaletteDialog(QDialog):
    def __init__(self, session, room, key, state, canvas, parent=None):
        super().__init__(parent)
        self.setWindowTitle('Borrow palette')
        self.s, self.room, self.key, self.state = session, room, key, state
        self.doc, self.r = session.doc, session.renderer
        self.tiles, self.attr, self.sheet = canvas.tiles, canvas.attr, canvas.gfx.sheet
        pid, words = self.r.room_palettes_555(room, key, state)
        self.my_pid = pid if words else None
        self.my_free1 = bool(self.my_pid and self.doc.palette(self.my_pid).get('free_color1'))
        self.my_rows = ([list(w) for w in words[:4]] if words else
                        [[PB.to555(c) for c in row] for row in canvas.pals[:4]])
        self.current_words = [[PB.to555(c) for c in row] for row in canvas.pals[:8]]
        self.src = None
        self.src_rows, self.src_free1, self.src_desc = None, False, ''

        root = QVBoxLayout(self)
        top = QHBoxLayout()
        root.addLayout(top, 1)

        # ---- left: where from
        left = QVBoxLayout()
        left.addWidget(QLabel('<b>Borrow from</b>'))
        self.filter = QLineEdit()
        self.filter.setPlaceholderText('type to filter (room name, $id, theme)…')
        self.filter.textChanged.connect(self._filter)
        left.addWidget(self.filter)
        self.list = QListWidget()
        self.list.setMinimumWidth(270)
        for src, label in PB.sources(self.doc, self.r):
            if src == ('room', room.get('id')):
                label += '  (this room)'
            it = QListWidgetItem(label)
            it.setData(Qt.UserRole, src)
            self.list.addItem(it)
        self.list.currentItemChanged.connect(lambda *_a: self._source_changed())
        left.addWidget(self.list, 1)
        srow = QHBoxLayout()
        srow.addWidget(QLabel('screen'))
        self.screen_box = QComboBox()
        self.screen_box.currentIndexChanged.connect(lambda _i: self._screen_changed())
        srow.addWidget(self.screen_box, 1)
        srow.addWidget(QLabel('state'))
        self.state_box = QComboBox()
        self.state_box.currentIndexChanged.connect(lambda _i: self._refresh())
        srow.addWidget(self.state_box, 1)
        left.addLayout(srow)
        top.addLayout(left)

        # ---- middle: theirs
        mid = QVBoxLayout()
        mid.addWidget(QLabel('<b>Their screen, their colours</b>'))
        self.their_pic = QLabel()
        self.their_pic.setFixedSize(320, 256)
        self.their_pic.setStyleSheet('background: #202024;')
        mid.addWidget(self.their_pic)
        self.their_rows = RowsView()
        mid.addWidget(QLabel('their palette rows'))
        mid.addWidget(self.their_rows)
        self.their_note = QLabel('')
        self.their_note.setWordWrap(True)
        self.their_note.setStyleSheet('color: #aaa;')
        mid.addWidget(self.their_note)
        mid.addStretch(1)
        top.addLayout(mid)

        # ---- right: yours, re-coloured
        rt = QVBoxLayout()
        rt.addWidget(QLabel(f'<b>Your screen {key} with them</b>'))
        self.my_pic = QLabel()
        self.my_pic.setFixedSize(320, 256)
        self.my_pic.setStyleSheet('background: #202024;')
        rt.addWidget(self.my_pic)
        self.my_rows_view = RowsView()
        rt.addWidget(QLabel('your palette rows after borrowing'))
        rt.addWidget(self.my_rows_view)
        rt.addStretch(1)
        top.addLayout(rt)

        # ---- what to take
        g = QGroupBox('What to take')
        gl = QGridLayout(g)
        self.mode_group = QButtonGroup(self)
        self.r_whole = QRadioButton('The whole palette, for')
        self.r_rows = QRadioButton('Only some rows:')
        self.mode_group.addButton(self.r_whole)
        self.mode_group.addButton(self.r_rows)
        self.r_whole.setChecked(True)
        self.scope = QComboBox()
        self.scope.addItem('this whole room', 'room')
        self.scope.addItem(f'only screen {key}, state {state}', 'here')
        self.share = QCheckBox('Share it (one palette for both rooms — a colour edit shows in both)')
        gl.addWidget(self.r_whole, 0, 0)
        gl.addWidget(self.scope, 0, 1, 1, 4)
        gl.addWidget(self.share, 1, 1, 1, 4)
        gl.addWidget(self.r_rows, 2, 0)
        self.slot_boxes = []
        for s_ in range(4):
            cb = QComboBox()
            cb.addItem(f'my slot {s_}: keep', None)
            for r_ in range(4):
                cb.addItem(f'my slot {s_} ← their row {r_}', r_)
            cb.currentIndexChanged.connect(lambda _i: self._rows_touched())
            gl.addWidget(cb, 2 + (s_ // 2), 1 + (s_ % 2) * 2, 1, 2)
            self.slot_boxes.append(cb)
        users = PB.palette_users(self.doc, self.my_pid) if self.my_pid else []
        self.only_here = QCheckBox(f'Only here — your palette {self.my_pid} is also used by '
                                   f'{len(users) - 1} other place(s); copy it first so they '
                                   'keep their colours')
        self.only_here.setChecked(True)
        self.only_here.setVisible(len(users) > 1)
        gl.addWidget(self.only_here, 4, 1, 1, 4)
        for w in (self.r_whole, self.r_rows, self.scope, self.share, self.only_here):
            sig = w.currentIndexChanged if isinstance(w, QComboBox) else w.toggled
            sig.connect(lambda *_a: self._refresh())
        root.addWidget(g)
        self.summary = QLabel('')
        self.summary.setWordWrap(True)
        self.summary.setStyleSheet('color: #7fe07f;')
        root.addWidget(self.summary)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        self.ok = bb.button(QDialogButtonBox.Ok)
        self.ok.setText('Borrow')
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        root.addWidget(bb)
        self.resize(1080, 720)
        if self.list.count():
            self.list.setCurrentRow(0)

    # ------------------------------------------------------------ choose
    def _filter(self, text):
        t = text.strip().lower()
        for i in range(self.list.count()):
            it = self.list.item(i)
            it.setHidden(bool(t) and t not in it.text().lower())

    def select_source(self, src, screen=None, state=None):
        """Pick a source programmatically (tests, and 'borrow from' links)."""
        for i in range(self.list.count()):
            if self.list.item(i).data(Qt.UserRole) == src:
                self.list.setCurrentRow(i)
                break
        if screen is not None:
            i = self.screen_box.findData(screen)
            if i >= 0:
                self.screen_box.setCurrentIndex(i)
        if state is not None:
            self.state_box.setCurrentIndex(min(state, self.state_box.count() - 1))

    def _source_changed(self):
        it = self.list.currentItem()
        self.src = it.data(Qt.UserRole) if it else None
        self.screen_box.blockSignals(True)
        self.screen_box.clear()
        self._screens = PB.screens_of(self.doc, self.r, self.src) if self.src else []
        for k, n in self._screens:
            self.screen_box.addItem(f'{k}', k)
        self.screen_box.blockSignals(False)
        self.screen_box.setEnabled(len(self._screens) > 1)
        self._screen_changed()

    def _screen_changed(self):
        k = self.screen_box.currentData()
        n = dict(self._screens).get(k, 1) if self._screens else 1
        self.state_box.blockSignals(True)
        self.state_box.clear()
        word = 'step' if self.src and self.src[0] == 'vanilla' else 'state'
        for i in range(n):
            self.state_box.addItem(f'{word} {i}', i)
        self.state_box.blockSignals(False)
        self.state_box.setEnabled(n > 1)
        self._refresh()

    def _rows_touched(self):
        if any(cb.currentData() is not None for cb in self.slot_boxes):
            self.r_rows.setChecked(True)
        self._refresh()

    # ------------------------------------------------------------- show
    def _where(self):
        k = self.screen_box.currentData() or 0
        st = self.state_box.currentData() or 0
        return k, st

    def mapping(self):
        return {s_: cb.currentData() for s_, cb in enumerate(self.slot_boxes)}

    def _refresh(self):
        if not self.src:
            return
        k, st = self._where()
        try:
            self.src_rows, self.src_free1, self.src_desc = PB.source_rows(
                self.doc, self.r, self.src, k, st)
            pic = PB.source_picture(self.doc, self.r, self.src, k, st)
        except Exception as ex:                                  # noqa: BLE001
            self.their_note.setText(f'⚠ {ex}')
            self.ok.setEnabled(False)
            return
        self.their_pic.setPixmap(_pix(pic))
        spid = PB.source_pid(self.doc, self.r, self.src, k, st)
        self.share.setVisible(spid is not None and spid != self.my_pid)
        whole = self.r_whole.isChecked()
        for cb in self.slot_boxes:
            cb.setEnabled(not whole)
        self.scope.setEnabled(whole)
        self.share.setEnabled(whole)
        self.only_here.setEnabled(not whole)
        if whole:
            rows, free1 = [list(r) for r in self.src_rows], self.src_free1
            marked = set(range(4))
        else:
            rows = PB.mixed_rows(self.my_rows, self.src_rows, self.mapping())
            free1 = self.my_free1
            marked = {s_ for s_, r_ in self.mapping().items() if r_ is not None}
        self.their_rows.set_rows(self.src_rows, self.src_free1,
                                 {r_ for r_ in self.mapping().values() if r_ is not None}
                                 if not whole else set(range(4)))
        self.my_rows_view.set_rows(rows, free1, marked)
        try:
            img = self.r.compose(self.sheet, self.tiles, self.attr, PB.rows_to_rgb(rows, free1))
            self.my_pic.setPixmap(_pix(img))
        except Exception:                                        # noqa: BLE001
            pass
        note = [self.src_desc]
        if self.src_free1:
            note.append('This palette has its own colour 1 (cream replaced).')
        if self.src == ('room', self.room.get('id')) and (k, st) == (self.key, self.state):
            note.append('That is the screen you are on.')
        self.their_note.setText('  '.join(note))
        if whole:
            share = self.share.isVisible() and self.share.isChecked()
            what = (f"Uses {spid} itself (shared)" if share else
                    'Copies these 4 rows into a new palette of your project')
            where = ('the whole room (screens / states with their own palette keep it)'
                     if self.scope.currentData() == 'room' else
                     f'screen {self.key}, state {self.state} only')
            self.summary.setText(f'{what} — for {where}. One undo step.')
            self.ok.setEnabled(True)
        else:
            picked = [(s_, r_) for s_, r_ in self.mapping().items() if r_ is not None]
            if not picked:
                self.summary.setText('Pick at least one of your slots to replace.')
                self.ok.setEnabled(False)
                return
            tgt = self.my_pid or 'a copy of the game palette this screen shows'
            extra = ('' if not self.only_here.isVisible() else
                     (' (copied first — only this screen / state changes)'
                      if self.only_here.isChecked() else
                      ' — EVERY place using it changes'))
            self.summary.setText(
                'Copies ' + ', '.join(f'their row {r_} into your slot {s_}' for s_, r_ in picked)
                + f' — into {tgt}{extra}. One undo step.'
                + (' Their colour 1 shows only with "own colour 1" on.'
                   if self.src_free1 and not self.my_free1 else ''))
            self.ok.setEnabled(True)

    # ----------------------------------------------------------- result
    def values(self):
        """kwargs for palette_borrow.apply_borrow (minus doc / room / key / state)."""
        k, st = self._where()
        whole = self.r_whole.isChecked()
        spid = PB.source_pid(self.doc, self.r, self.src, k, st)
        return dict(src=self.src, src_rows=[list(r) for r in self.src_rows],
                    src_free1=self.src_free1, mode='whole' if whole else 'rows',
                    scope=self.scope.currentData(),
                    share_pid=(spid if whole and self.share.isVisible()
                               and self.share.isChecked() else None),
                    mapping=None if whole else self.mapping(),
                    only_here=self.only_here.isVisible() and self.only_here.isChecked(),
                    current_words=self.current_words, description=self.src_desc)
