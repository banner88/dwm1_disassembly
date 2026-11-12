"""S175r3: a song picker with names, the DWM2 / MIDI library and a ▶ preview.

User report on S175r2 ("I can only select random numerals for songs, no custom songs,
I can't preview it — where are the DWM2 songs?"): the Screen page's music combo only
listed the project's own songs plus the game's songs as bare ids. This picker lists,
in groups:

  * Your songs        — project songs (value = the song id);
  * DWM2 songs        — the repo's DWM2 catalog (extracted/dwm2_song_library.json);
  * MIDI library      — the MIDI catalog;
  * Game songs        — the game's music, labelled by where the game uses it
                         (the Music tab's automatic labels / your names).

A library song not yet in the project has the value  'lib:<library id>'; the caller
adds it to the project (doc.add_library_song) and assigns it as ONE undo step
(see resolve_value). A library song already in the project maps to that project song.
The ▶ button previews the selected entry with music_tab.SongPlayer / music_preview.
"""
import os

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QFont
from PySide6.QtWidgets import QComboBox, QHBoxLayout, QPushButton, QWidget

LIB = 'lib:'


def _in_project(doc):
    """{library id: project song id} of library songs already in the project."""
    out = {}
    for s in doc.project_songs() or []:
        src = s.get('source') or {}
        if isinstance(src, dict) and src.get('library'):
            out.setdefault(src['library'], s['id'])
    return out


def game_song_label(doc, s):
    """'$NN <your name | where the game uses it>' for a game sound catalog entry."""
    from editor2.app.music_tab import MusicTab
    n = int(s['id_int'])
    nm = None
    for k in (s.get('id'), f'${n:02X}', f'0x{n:02X}'):
        if k and not nm:
            try:
                nm = doc.song_name(k, None)
            except Exception:                                   # noqa: BLE001
                nm = None
    if not nm:
        try:
            nm = MusicTab._auto(s)
        except Exception:                                       # noqa: BLE001
            nm = 'game song'
    return f'${n:02X} {nm}'


def groups(doc):
    """[(header, [(label, value, preview)])] — preview = ('song', id) | ('lib', id) |
    ('game', id_int, starts_as)."""
    out = []
    in_proj = _in_project(doc)
    mine = []
    for s in doc.project_songs() or []:
        nm = doc.song_name(s['id'], None) or s.get('name') or s['id']
        src = (s.get('source') or {}) if isinstance(s.get('source'), dict) else {}
        tag = ' (DWM2)' if 'dwm2' in str(src.get('library', '')) else ''
        mine.append((f'★ {nm}{tag}', s['id'], ('song', s['id'])))
    if mine:
        out.append(('Your songs', mine))
    try:
        lib = doc.library_songs() or {}
    except Exception:                                           # noqa: BLE001
        lib = {}
    dwm2, midi = [], []
    for lid, e in sorted(lib.items()):
        nm = doc.song_name(lid, None) or e.get('name') or lid
        if lid in in_proj:
            row = (f'{nm}  (in your songs)', in_proj[lid], ('song', in_proj[lid]))
        else:
            row = (nm, LIB + lid, ('lib', lid))
        (dwm2 if 'dwm2' in str(e.get('_library', '')) else midi).append(row)
    if dwm2:
        out.append(('DWM2 songs — picking one adds it to your songs', dwm2))
    if midi:
        out.append(('MIDI library — picking one adds it to your songs', midi))
    try:
        cat = doc.vanilla_sounds() or []
    except Exception:                                           # noqa: BLE001
        cat = []
    game = []
    for s in cat:
        if s.get('kind') != 'music':
            continue
        n = int(s['id_int'])
        game.append((game_song_label(doc, s), f'0x{n:02X}',
                     ('game', n, s.get('starts_as', 'bgm'))))
    if game:
        out.append(("The game's songs", game))
    return out


def resolve_value(doc, value):
    """Inside an undo op: 'lib:<id>' -> a project song id (added when missing)."""
    if isinstance(value, str) and value.startswith(LIB):
        lid = value[len(LIB):]
        have = _in_project(doc).get(lid)
        return have or doc.add_library_song(lid)
    return value


class SongPicker(QWidget):
    """A song combo + ▶ preview. `chosen(value)` on a user pick (None = the default)."""
    chosen = Signal(object)

    def __init__(self, default_label, parent=None):
        super().__init__(parent)
        self.default_label = default_label
        self.rom_path = None              # callable -> ROM path (set by the owner)
        self._rom = None
        self._building = False
        self._preview = {}
        self.player = None
        h = QHBoxLayout(self)
        h.setContentsMargins(0, 0, 0, 0)
        self.combo = QComboBox()
        self.combo.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.combo.setMinimumContentsLength(16)
        self.combo.setMaxVisibleItems(24)
        self.combo.currentIndexChanged.connect(self._changed)
        h.addWidget(self.combo, 1)
        self.play_b = QPushButton('▶')
        self.play_b.setFixedWidth(34)
        self.play_b.setToolTip('Preview the selected song (click again to stop)')
        self.play_b.clicked.connect(self._toggle)
        h.addWidget(self.play_b)

    # -- filling --------------------------------------------------------------
    def fill(self, doc, current, default_preview=None):
        """(Re)fill for `doc`, selecting `current`. default_preview = the preview of
        the default entry (e.g. the room's song), or None."""
        was = (self._preview.get(self.combo.currentIndex())
               if self.play_b.text() == '■' else None)
        self._building = True
        self.combo.clear()
        self._preview = {}
        self.combo.addItem(self.default_label, None)
        self._preview[0] = default_preview
        try:
            gs = groups(doc)
        except Exception:                                       # noqa: BLE001
            gs = []
        bold = QFont()
        bold.setBold(True)
        for header, rows in gs:
            self.combo.insertSeparator(self.combo.count())
            self.combo.addItem(f'— {header} —', '__header__')
            k = self.combo.count() - 1
            # item data only — no QStandardItem wrappers (holding one across clear()
            # crashed later Qt event delivery in test_app)
            self.combo.setItemData(k, 0, Qt.UserRole - 1)      # flags: not selectable
            self.combo.setItemData(k, bold, Qt.FontRole)
            for label, value, prev in rows:
                self.combo.addItem('   ' + label, value)
                self._preview[self.combo.count() - 1] = prev
        i = 0
        if current is not None:
            i = self.combo.findData(current)
            if i < 0:
                self.combo.addItem(str(current), current)
                i = self.combo.count() - 1
        self.combo.setCurrentIndex(i)
        self._building = False
        self._sync_play()
        if was is None or self._preview.get(i) != was:   # a refresh keeps the preview
            self.stop()                                  # of the same song playing

    def value(self):
        return self.combo.currentData()

    def setEnabled(self, on):                                   # noqa: N802
        super().setEnabled(on)
        if not on:
            self.stop()

    def _changed(self, _i):
        self._sync_play()
        if self._building:
            return
        self.stop()
        v = self.combo.currentData()
        if v == '__header__':
            return
        # deferred (KEY_LESSONS S119b): the pick's undo step refreshes the inspector,
        # which refills THIS combo — never inside its own currentIndexChanged
        from PySide6.QtCore import QTimer
        QTimer.singleShot(0, lambda: self.chosen.emit(v))

    # -- preview --------------------------------------------------------------
    def _sync_play(self):
        self.play_b.setEnabled(self._preview.get(self.combo.currentIndex()) is not None)

    def _rom_bytes(self):
        if self._rom is None:
            path = self.rom_path() if callable(self.rom_path) else None
            if not path:
                from editor2.app.session import REPO
                path = os.path.join(REPO, 'data', 'DWM-original.gbc')
            with open(path, 'rb') as f:
                self._rom = f.read()
        return self._rom

    def renderer(self, doc, prev):
        from editor2.core import music_preview as MP
        if prev[0] == 'game':
            return MP.Renderer.vanilla(self._rom_bytes(), prev[1], prev[2])
        return MP.Renderer.song(self._rom_bytes(), doc.song_channels(prev[1]))

    def _toggle(self):
        if self.player is not None and self.play_b.text() == '■':
            self.stop()
            return
        prev = self._preview.get(self.combo.currentIndex())
        if prev is None or self.doc_getter is None:
            return
        from editor2.app.music_tab import SongPlayer
        ok, why = SongPlayer.available()
        if not ok:
            self.play_b.setToolTip(why)
            self.window().statusBar().showMessage(why, 6000) \
                if hasattr(self.window(), 'statusBar') else None
            return
        try:
            r = self.renderer(self.doc_getter(), prev)
        except Exception as ex:                                 # noqa: BLE001
            self.play_b.setToolTip(f'Cannot preview: {ex}')
            return
        if self.player is None:
            self.player = SongPlayer(self)
            self.player.stopped.connect(lambda: self.play_b.setText('▶'))
        self.player.play(r)
        self.play_b.setText('■')

    doc_getter = None                     # callable -> the Document (set by the owner)

    def stop(self):
        if self.player is not None:
            try:
                self.player.stop()
            except Exception:                                   # noqa: BLE001
                pass
        self.play_b.setText('▶')
