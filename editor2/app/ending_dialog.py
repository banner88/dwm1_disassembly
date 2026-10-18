"""ending_dialog.py — the title screen and the credits (S153, ROADMAP E5; model:
editor2/core/ending_doc.py, compiler: editor2/core/ending.py, PROJECT_COMPILER §2.61).

User (S153): "If intro has 'Milayou's Journey' or whatever text I want added to it
that would be cool. The final cutscene before credits also should be editable and you
can send a given cutscene to credits."

Two pages:
  Title screen — lines of text drawn on the game's title (row, centred or at a
      column, black / orange / red), the title's song; the picture is the game's title
      as it draws it (pixel-exact, ROM data) with your lines.
  Credits — every page of the credits: its role, its names and its monster (the game's
      27 to start with; add your own, move them, remove them — the last page is the
      closing page, drawn with the copyright layout); the seconds a page shows; the
      credits' song and "TO BE CONTINUED"'s song. The picture is the page as the game
      draws it (text grids, the monster, what falls outside the picture).
The credits roll from a cutscene's "Roll the credits" step; "TO BE CONTINUED" (the
ending's save) is a step too. OK applies everything as one undo step.
"""

import copy

from PySide6.QtCore import Qt
from PySide6.QtGui import QPixmap
from PySide6.QtWidgets import (QAbstractItemView, QComboBox, QDialog, QDialogButtonBox,
                               QFormLayout, QGridLayout, QGroupBox, QHBoxLayout, QLabel,
                               QLineEdit, QListWidget, QMessageBox, QPlainTextEdit,
                               QPushButton, QSpinBox, QTableWidget, QTableWidgetItem,
                               QTabWidget, QVBoxLayout, QWidget)

from editor2.app.rooms import commands as C
from editor2.app.sprite_qt import pixmap, species_art
from editor2.app.story_widgets import song_choices, species_choices
from editor2.core import ending as EN

INTRO = ('<b>Title &amp; ending</b> — the title screen\'s own lines and song, and the credits '
         '(their pages, seconds and songs). A cutscene rolls the credits with its <i>Roll the '
         'credits</i> step (The ending group of ＋ Add step) and shows "…TO BE CONTINUED" — the '
         'ending\'s save — with <i>TO BE CONTINUED</i>; <i>The original game\'s story → a story '
         'point</i> puts the game\'s own rooms where they are after, say, Starry Night.')
TITLE_HELP = ('The game draws your lines in its text font on the title, between the logo and the '
              'copyright (rows 12-14) or above the logo (rows 0-5) or at the bottom (row 17) — '
              'those rows are empty. Other rows cover the logo / the copyright (a warning). '
              'Game Boy Color only (an original Game Boy shows the title without them).')
CREDITS_HELP = ('A page = a ROLE (2 lines: up to 19 and 18 letters), NAMES (12 lines of up to 11 '
                'letters; the game indents some rows and the monster covers the right end of '
                'rows 8, 10 and 12) and a MONSTER. A line is not wrapped: letters past its row '
                'go into the next row and the picture shows what the game shows. The LAST page '
                'is the closing page: its names are shown two rows to a line (19 letters) — the '
                'game\'s copyright lines end with two line breaks each.')
COLOUR_ITEMS = [('black', 'black'), ('orange', 'orange'), ('dark red', 'red')]
GAME_TITLE_SONG = ('$06 the game\'s title song', None)
GAME_CREDITS_SONG = ('$21 the game\'s credits song', None)
GAME_CONTINUE_SONG = ('$31 the game\'s (the Starry Shrine)', None)


def _qpix(rows, scale=2):
    return pixmap(rows, scale)


def _song_combo(doc, cur, game):
    c = QComboBox()
    c.addItem(game[0], None)
    for lab, d in song_choices(doc):
        c.addItem(lab, d)
    if cur not in (None, ''):
        i = c.findData(cur)
        if i < 0:
            c.addItem(str(cur), cur)
            i = c.count() - 1
        c.setCurrentIndex(i)
    return c


class EndingDialog(QDialog):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        doc = session.doc
        self.setWindowTitle('Title & ending')
        self._busy = True
        lay = QVBoxLayout(self)
        intro = QLabel(INTRO)
        intro.setWordWrap(True)
        lay.addWidget(intro)
        self.tabs = QTabWidget()
        lay.addWidget(self.tabs, 1)
        self.tabs.addTab(self._title_page(doc), 'Title screen')
        self.tabs.addTab(self._credits_page(doc), 'Credits')
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        lay.addWidget(bb)
        self._busy = False
        self._title_preview()
        self._pick_page(0)

    # ================================================================ the title
    def _title_page(self, doc):
        w = QWidget()
        g = QGridLayout(w)
        t = doc.title_settings()
        left = QVBoxLayout()
        hlp = QLabel(TITLE_HELP)
        hlp.setWordWrap(True)
        hlp.setStyleSheet('color:#aab;')
        left.addWidget(hlp)
        self.lines = QTableWidget(0, 4)
        self.lines.setHorizontalHeaderLabels(['text', 'row', 'column', 'colour'])
        self.lines.horizontalHeader().setStretchLastSection(False)
        self.lines.setColumnWidth(0, 200)
        self.lines.setSelectionBehavior(QAbstractItemView.SelectRows)
        left.addWidget(self.lines, 1)
        hb = QHBoxLayout()
        b = QPushButton('＋ Line')
        b.clicked.connect(lambda: self._add_line({'text': "Milayou's Journey", 'row': 13,
                                                  'align': 'center', 'colour': 'black'}))
        hb.addWidget(b)
        b = QPushButton('Remove line')
        b.clicked.connect(self._remove_line)
        hb.addWidget(b)
        hb.addStretch(1)
        left.addLayout(hb)
        f = QFormLayout()
        self.title_song = _song_combo(doc, t.get('song'), GAME_TITLE_SONG)
        self.title_song.currentIndexChanged.connect(self._title_preview)
        f.addRow('title song', self.title_song)
        left.addLayout(f)
        self.title_problem = QLabel('')
        self.title_problem.setWordWrap(True)
        self.title_problem.setStyleSheet('color:#e0b040;')
        left.addWidget(self.title_problem)
        g.addLayout(left, 0, 0)
        self.title_pic = QLabel()
        self.title_pic.setAlignment(Qt.AlignTop | Qt.AlignHCenter)
        g.addWidget(self.title_pic, 0, 1)
        for ln in t.get('lines') or []:
            self._add_line(ln, preview=False)
        return w

    def _add_line(self, ln, preview=True):
        r = self.lines.rowCount()
        self.lines.insertRow(r)
        te = QLineEdit(str(ln.get('text', '')))
        te.textChanged.connect(self._title_preview)
        self.lines.setCellWidget(r, 0, te)
        row = QSpinBox()
        row.setRange(0, 17)
        row.setValue(int(ln.get('row', 13)))
        row.valueChanged.connect(self._title_preview)
        self.lines.setCellWidget(r, 1, row)
        col = QSpinBox()
        col.setRange(-1, 19)
        col.setSpecialValueText('centred')
        col.setValue(-1 if ln.get('align') == 'center' or ln.get('col') is None
                     else int(ln['col']))
        col.valueChanged.connect(self._title_preview)
        self.lines.setCellWidget(r, 2, col)
        cc = QComboBox()
        for lab, d in COLOUR_ITEMS:
            cc.addItem(lab, d)
        cc.setCurrentIndex(max(0, cc.findData(ln.get('colour', 'black'))))
        cc.currentIndexChanged.connect(self._title_preview)
        self.lines.setCellWidget(r, 3, cc)
        if preview:
            self._title_preview()

    def _remove_line(self):
        r = self.lines.currentRow()
        if r < 0:
            r = self.lines.rowCount() - 1
        if r >= 0:
            self.lines.removeRow(r)
            self._title_preview()

    def title_lines(self):
        out = []
        for r in range(self.lines.rowCount()):
            txt = self.lines.cellWidget(r, 0).text()
            col = self.lines.cellWidget(r, 2).value()
            d = {'text': txt, 'row': self.lines.cellWidget(r, 1).value(),
                 'colour': self.lines.cellWidget(r, 3).currentData()}
            if col < 0:
                d['align'] = 'center'
            else:
                d['col'] = col
            out.append(d)
        return out

    def _title_preview(self, *_a):
        if self._busy:
            return
        lines = [ln for ln in self.title_lines() if ln['text']]
        custom = {'title': {'lines': lines}} if lines else {}
        msg = ''
        try:
            EN.title_layout(custom)
            msg = '\n'.join(EN.title_warnings(custom))
        except EN.EndingError as ex:
            msg = str(ex)
            custom = {}
        self.title_problem.setText(msg)
        try:
            self.title_pic.setPixmap(_qpix(EN.title_picture(custom or None)))
        except Exception as ex:                          # noqa: BLE001 (no ROM)
            self.title_pic.setText(f'(no picture: {ex})')

    # ================================================================ the credits
    def _credits_page(self, doc):
        w = QWidget()
        g = QGridLayout(w)
        c = doc.credits_settings()
        if not c['own']:
            c['pages'] = doc.credits_pages_from_text()
        self.pages = [dict(p) for p in c['pages']]
        left = QVBoxLayout()
        self.page_list = QListWidget()
        self.page_list.currentRowChanged.connect(self._pick_page)
        left.addWidget(self.page_list, 1)
        hb = QGridLayout()
        for i, (txt, fn) in enumerate((('＋ Page', self._add_page), ('Remove', self._remove_page),
                                       ('▲', lambda: self._move(-1)), ('▼', lambda: self._move(1)),
                                       ('The game\'s pages', self._game_pages))):
            b = QPushButton(txt)
            b.clicked.connect(fn)
            hb.addWidget(b, i // 3, i % 3)
        left.addLayout(hb)
        f = QFormLayout()
        self.seconds = QSpinBox()
        self.seconds.setRange(1, 60)
        self.seconds.setSuffix(' s a page')
        self.seconds.setValue(int(c.get('seconds', EN.SECONDS)))
        f.addRow('each page', self.seconds)
        self.credits_song = _song_combo(doc, c.get('song'), GAME_CREDITS_SONG)
        f.addRow('credits song', self.credits_song)
        self.continue_song = _song_combo(doc, c.get('continue_song'), GAME_CONTINUE_SONG)
        f.addRow('"TO BE CONTINUED" song', self.continue_song)
        left.addLayout(f)
        g.addLayout(left, 0, 0)

        mid = QVBoxLayout()
        hlp = QLabel(CREDITS_HELP)
        hlp.setWordWrap(True)
        hlp.setStyleSheet('color:#aab;')
        mid.addWidget(hlp)
        box = QGroupBox('The page')
        bf = QFormLayout(box)
        self.role = QPlainTextEdit()
        self.role.setFixedHeight(54)
        self.role.textChanged.connect(self._page_edited)
        bf.addRow('role', self.role)
        self.names = QPlainTextEdit()
        self.names.setFixedHeight(190)
        self.names.textChanged.connect(self._page_edited)
        bf.addRow('names', self.names)
        self.monster = QComboBox()
        for lab, d in species_choices(doc):
            self.monster.addItem(lab, d)
        self.monster.currentIndexChanged.connect(self._page_edited)
        bf.addRow('monster', self.monster)
        mid.addWidget(box)
        self.page_problem = QLabel('')
        self.page_problem.setWordWrap(True)
        self.page_problem.setStyleSheet('color:#e0b040;')
        mid.addWidget(self.page_problem)
        mid.addStretch(1)
        g.addLayout(mid, 0, 1)
        self.page_pic = QLabel()
        self.page_pic.setAlignment(Qt.AlignTop | Qt.AlignHCenter)
        g.addWidget(self.page_pic, 0, 2)
        self._fill_list()
        return w

    def _label(self, i):
        p = self.pages[i]
        role = ' '.join(str(p.get('role', '')).replace('{ED}', '').split())
        last = ' — the closing page' if i == len(self.pages) - 1 else ''
        return f'{i + 1}. {role[:28] or "(no role)"}{last}'

    def _fill_list(self, keep=None):
        self.page_list.blockSignals(True)
        self.page_list.clear()
        for i in range(len(self.pages)):
            self.page_list.addItem(self._label(i))
        self.page_list.blockSignals(False)
        if keep is not None and self.pages:
            self.page_list.setCurrentRow(max(0, min(keep, len(self.pages) - 1)))

    def _pick_page(self, i):
        if i is None or i < 0 or i >= len(self.pages):
            return
        if self.page_list.currentRow() != i:
            self.page_list.setCurrentRow(i)
            return
        p = self.pages[i]
        self._busy = True
        self.role.setPlainText(str(p.get('role', '')))
        self.names.setPlainText(str(p.get('names', '')))
        j = self.monster.findData(int(p.get('monster', 0)))
        if j < 0:
            self.monster.addItem(f"#{p.get('monster')}", int(p.get('monster', 0)))
            j = self.monster.count() - 1
        self.monster.setCurrentIndex(j)
        self._busy = False
        self._page_preview()

    def _page_edited(self, *_a):
        if self._busy:
            return
        i = self.page_list.currentRow()
        if i < 0:
            return
        self.pages[i] = {'role': self.role.toPlainText(), 'names': self.names.toPlainText(),
                         'monster': int(self.monster.currentData() or 0)}
        it = self.page_list.item(i)
        if it is not None:
            it.setText(self._label(i))
        self._page_preview()

    def _page_preview(self):
        i = self.page_list.currentRow()
        if i < 0:
            return
        p = self.pages[i]
        last = i == len(self.pages) - 1
        errs, warns = EN.page_problems(p, last)
        self.page_problem.setText('\n'.join(errs + warns))
        mon = EN.monster_art(self.s.doc.data, self.s.doc.project_dir, int(p.get('monster', 0)))
        if mon is None:
            try:
                mon = species_art(self.s.doc, int(p.get('monster', 0)))[0]
            except Exception:                            # noqa: BLE001
                mon = None
        try:
            self.page_pic.setPixmap(_qpix(EN.page_picture(p, last, monster_rows=mon)))
        except EN.EndingError as ex:
            self.page_pic.setText(str(ex))
        except Exception as ex:                          # noqa: BLE001 (no ROM)
            self.page_pic.setText(f'(no picture: {ex})')

    def _add_page(self):
        i = self.page_list.currentRow()
        at = max(0, min(i + 1 if i >= 0 else len(self.pages) - 1, len(self.pages) - 1))
        if len(self.pages) >= EN.MAX_PAGES:
            QMessageBox.information(self, 'Credits', f'At most {EN.MAX_PAGES} pages.')
            return
        self.pages.insert(at, {'role': 'ROMHACK', 'names': 'YOUR NAME', 'monster': 0})
        self._fill_list(keep=at)

    def _remove_page(self):
        i = self.page_list.currentRow()
        if i < 0 or len(self.pages) <= 1:
            return
        del self.pages[i]
        self._fill_list(keep=i)

    def _move(self, d):
        i = self.page_list.currentRow()
        j = i + d
        if i < 0 or not 0 <= j < len(self.pages):
            return
        self.pages[i], self.pages[j] = self.pages[j], self.pages[i]
        self._fill_list(keep=j)

    def _game_pages(self):
        if QMessageBox.question(self, 'Credits', 'Put back the game\'s 27 pages (your pages and '
                                'edits go)?') != QMessageBox.Yes:
            return
        self.pages = EN.vanilla_pages()
        self._fill_list(keep=0)

    # ================================================================ OK
    def _ok(self):
        lines = [ln for ln in self.title_lines() if ln['text']]
        try:
            EN.title_layout({'title': {'lines': lines}})
        except EN.EndingError as ex:
            QMessageBox.warning(self, 'Title & ending', f'The title: {ex}')
            return
        bad = []
        for i, p in enumerate(self.pages):
            e, _w = EN.page_problems(p, i == len(self.pages) - 1)
            bad += [f'page {i + 1}: {x}' for x in e]
        if bad:
            QMessageBox.warning(self, 'Title & ending', 'The credits:\n' + '\n'.join(bad[:8]))
            return
        tsong = self.title_song.currentData()
        pages = copy.deepcopy(self.pages)
        seconds = self.seconds.value()
        csong = self.credits_song.currentData()
        ksong = self.continue_song.currentData()
        def op(doc):
            doc.set_title(lines, tsong)
            doc.set_credits(pages, seconds, csong, ksong)
        cmd = C.SnapshotCommand(self.s, 'Title & ending', op)
        self.s.undo.push(cmd)
        if getattr(cmd, 'error', None) is not None:
            QMessageBox.warning(self, 'Title & ending', str(cmd.error))
            return
        self.accept()
