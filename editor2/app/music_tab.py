"""music_tab.py — the Music tab (S116, ROADMAP P3.13b; EDITOR_DESIGN §5.6 "As built
S116"; model: editor2/core/music_doc.py, compiler: editor2/core/music.py,
PROJECT_COMPILER §2.9).

Four pages:

  Songs    every song you can use: the game's own (music, jingles, sound
           effects — extracted from the ROM), the 31 DWM2 songs, the MIDI
           library, and the project's songs (incl. MIDI files imported here,
           converted automatically). ▶ plays any of them in the editor — the
           GAME'S OWN sound engine runs on a built-in CPU (editor2/core/
           sound_engine.py, census-proven identical to the game), so what you
           hear is what the game plays (only the final sound synthesis is the
           editor's). Name any song; add catalog songs to the project; the
           meters show the 95 song ids and the two song banks.
  Rooms    every room — yours and the game's — with the game's song and yours,
           and the song of battles in that room.
  Gates    every gate: the song of its floors (maze floors, its special rooms,
           your rooms served in it that have no song of their own) and of its
           battles. Empty = the game's (the gate theme / the battle theme).
  Battles  the normal / boss / arena / Starry Night final battle songs, and a
           song per fight (an enemy row: your enemies, bosses, arena teams).

Every edit is one undo step (SnapshotCommand); the compiler's plan validates it.
"""
import os

from PySide6.QtCore import QObject, Qt, QTimer, Signal
from PySide6.QtGui import QColor
from PySide6.QtWidgets import (QAbstractItemView, QCheckBox, QComboBox, QFileDialog,
                               QFormLayout, QGroupBox, QHBoxLayout, QHeaderView,
                               QInputDialog, QLabel, QLineEdit, QListWidget,
                               QListWidgetItem, QMessageBox, QProgressBar, QPushButton,
                               QSplitter, QTabWidget, QTableWidget, QTableWidgetItem,
                               QVBoxLayout, QWidget)

from editor2.app.rooms import commands as C
from editor2.core import music as M
from editor2.core import music_doc as MD

HELP = ('The game plays a song through its own sound engine; the editor runs that same '
        'engine, so ▶ is what the game plays. A room, a gate or a kind of battle with no '
        'song set keeps the game\'s choice. Your songs (from the DWM2 catalog, the MIDI '
        'library, or MIDI files you import) take 1-6 sound ids each out of 95, and fill two '
        'song banks of 16,000 bytes.')
GREY = QColor(140, 140, 140)
KIND_LABEL = {'music': 'music', 'jingle': 'jingle', 'effect': 'sound effect'}


def _np():
    try:
        import numpy   # noqa: F401
        return True
    except ImportError:
        return False


# ---------------------------------------------------------------------------
# audio output: QAudioSink in push mode, fed by a timer from a Renderer
# ---------------------------------------------------------------------------

class SongPlayer(QObject):
    """Streams music_preview.Renderer output to the default audio device.

    S116b (user report, macOS: "stopped early after a few seconds, replay froze
    completely"), from Qt Multimedia 6.10/6.11's CoreAudio sink source:
      * the sink runs at the DEVICE'S OWN sample rate (the 32,768 Hz Game Boy
        rate is resampled here). Opening a sink at another rate makes Qt's
        macOS backend switch the output device's hardware rate, and a device
        reconfiguration stops the stream;
      * the sink buffer is topped up continuously (exactly what bytesFree()
        allows, rendered a few frames at a time; a partial write() keeps the
        rest), never "only once a 0.25 s chunk fits" (on a small buffer that
        never happens again and the song stops);
      * stop / restart use reset() (discard the buffer) on ONE reused sink —
        stop() drains asynchronously, and deleting / recreating the sink while
        the old stream still drains is what replay ran into;
      * a stream that CoreAudio stops by itself (device change) is restarted
        (polled each tick: PySide cannot deliver QAudioSink.stateChanged), and
        any audio error is printed to the terminal ("[music] ...").
    """
    stopped = Signal()
    position = Signal(float)

    BUFFER_S = 0.4          # the sink's buffer
    STEP_FRAMES = 2         # render granularity (game frames, ~33 ms)
    TICK_MS = 15
    SRC_RATE = 32768

    def __init__(self, parent=None):
        super().__init__(parent)
        self.sink = None
        self.dev = None
        self.r = None
        self.rate = None
        self._dev_id = None
        self._pending = b''
        self._pos = 1.0
        self._prev = None
        self._drain = 0
        self._restarts = 0
        self._last_err = None
        self._gen = 0               # bumped by play/stop: a scheduled restart of an
        self.timer = QTimer(self)   # earlier playback does nothing
        self.timer.setInterval(self.TICK_MS)
        self.timer.timeout.connect(self._feed)
        self.error = None

    @staticmethod
    def available():
        if not _np():
            return False, 'Song preview needs numpy:  pip install numpy'
        try:
            from PySide6.QtMultimedia import QMediaDevices
            if QMediaDevices.defaultAudioOutput().isNull():
                return False, 'No audio output device'
        except Exception as ex:                      # noqa: BLE001
            return False, f'QtMultimedia unavailable: {ex}'
        return True, ''

    # -- the sink -----------------------------------------------------------
    def _log(self, msg):
        import sys
        print(f'[music] {msg}', file=sys.stderr, flush=True)

    def _ensure_sink(self):
        from PySide6.QtMultimedia import QAudioFormat, QAudioSink, QMediaDevices
        dev = QMediaDevices.defaultAudioOutput()
        did = bytes(dev.id().data())
        if self.sink is not None and did == self._dev_id:
            return
        self._drop_sink()
        fmt = QAudioFormat()
        fmt.setChannelCount(2)
        fmt.setSampleFormat(QAudioFormat.Int16)
        fmt.setSampleRate(dev.preferredFormat().sampleRate() or 48000)
        if not dev.isFormatSupported(fmt):
            fmt.setSampleRate(48000)
        self.rate = fmt.sampleRate()
        self.sink = QAudioSink(dev, fmt, self)
        self.sink.setBufferSize(int(self.rate * self.BUFFER_S) * 4)
        self._dev_id = did

    def _drop_sink(self):
        if self.sink is None:
            return
        self.sink.reset()
        self.sink.deleteLater()
        self.sink = None
        self.dev = None
        self._dev_id = None

    def _start_stream(self):
        self.dev = self.sink.start()
        if self.dev is None:
            self._log(f'audio output did not start (error {self.sink.error()})')

    def _check_state(self):
        """Polled on every feed tick (PySide cannot deliver QAudioSink.stateChanged:
        "QAudio::State cannot be converted"). Returns False when the stream is
        gone and a restart was scheduled / playback stopped."""
        # by NAME: Qt >= 6.10 returns QtAudio enums, which never equal QAudio's
        state = getattr(self.sink.state(), 'name', str(self.sink.state()))
        err = getattr(self.sink.error(), 'name', str(self.sink.error()))
        if err != 'NoError' and err != self._last_err:
            self._log(f'audio output: state {state}, error {err}')
        self._last_err = err
        if state != 'StoppedState':
            return True
        # CoreAudio stopped the stream (device change / IO error): start it again,
        # continuing the song where it is.
        self.timer.stop()
        if self._restarts < 5:
            self._restarts += 1
            gen = self._gen
            QTimer.singleShot(100, lambda: self._restart_stream(gen))
        else:
            self._log('audio output keeps stopping: giving up')
            QTimer.singleShot(0, self.stop)
        return False

    def _restart_stream(self, gen):
        if gen != self._gen or self.r is None or self.sink is None:
            return
        self.sink.reset()
        self._pending = b''
        self._ensure_sink()             # the default output may have changed
        self._start_stream()
        if self.dev is None:
            self.stop()
            return
        self._feed()
        self.timer.start()

    # -- playing ------------------------------------------------------------
    def play(self, renderer):
        self.stop()
        self._ensure_sink()
        self.r = renderer
        self._pending = b''
        self._pos = 1.0
        self._prev = None
        self._drain = 0
        self._restarts = 0
        self._gen += 1
        self._start_stream()
        if self.dev is None:            # one more try on a fresh sink
            self._drop_sink()
            self._ensure_sink()
            self._start_stream()
            if self.dev is None:
                self.r = None
                raise RuntimeError('The audio output did not start (see the terminal).')
        self._feed()
        self.timer.start()

    def _resample(self, pcm):
        """32,768 Hz -> the sink's rate, linear, continuous across calls."""
        import numpy as np
        if self.rate == self.SRC_RATE or len(pcm) == 0:
            return pcm
        prev = pcm[:1] if self._prev is None else self._prev
        x = np.concatenate([prev, pcm]).astype(np.float64)
        last = len(x) - 1
        step = self.SRC_RATE / self.rate
        n = int(np.floor((last - self._pos) / step)) + 1 if self._pos <= last else 0
        t = self._pos + np.arange(n) * step
        self._pos = (self._pos + n * step) - last
        self._prev = pcm[-1:]
        idx = np.arange(len(x))
        out = np.stack([np.interp(t, idx, x[:, k]) for k in (0, 1)], axis=1)
        return np.round(out).astype(np.int16)

    def _feed(self):
        if self.sink is None or self.dev is None or self.r is None:
            return
        if not self._check_state():
            return
        free = self.sink.bytesFree()
        while free >= 4:
            if not self._pending:
                if self.r.ended:
                    break
                self._pending = self._resample(
                    self.r.render(frames=self.STEP_FRAMES)).tobytes()
                continue
            n = self.dev.write(self._pending[:free - free % 4])
            if n is None or n <= 0:
                break
            self._pending = self._pending[n:]
            free -= n
        self.position.emit(self.r.frames / 59.7275)
        if self.r.ended and not self._pending:
            # let the buffer play out (bytesFree back to the whole buffer), max ~1.5 s
            self._drain += 1
            if (self.sink.bytesFree() >= self.sink.bufferSize() - 4
                    or self._drain * self.TICK_MS > 1500):
                self.stop()

    def stop(self):
        self.timer.stop()
        self._gen += 1
        was = self.dev is not None or self.r is not None
        if self.sink is not None and self.dev is not None:
            self.sink.reset()           # discard: no asynchronous drain
        self.dev = None
        self.r = None
        self._pending = b''
        if was:
            self.stopped.emit()

    def shutdown(self):
        self.stop()
        self._drop_sink()

    @property
    def playing(self):
        return self.dev is not None


# ---------------------------------------------------------------------------
# a song value picker (rooms, gates, battles)
# ---------------------------------------------------------------------------

class SongCombo(QComboBox):
    """Picks a song value: None (the game's), a project song id, a game sound id."""
    picked = Signal(object)

    def __init__(self, tab, value, default_label="— the game's —", parent=None):
        super().__init__(parent)
        self.tab = tab
        self.setMinimumWidth(240)
        self.addItem(default_label, None)
        for sid, label in tab.project_song_labels():
            self.addItem(f'♪ {label}', sid)
        for sid, label in tab.vanilla_song_labels():
            self.addItem(label, sid)
        i = self.findData(value)
        if value is not None and i < 0:
            self.addItem(MD.value_key(value) if isinstance(value, int) else str(value), value)
            i = self.count() - 1
        self.setCurrentIndex(max(0, i))
        self.activated.connect(lambda _i: self.picked.emit(self.currentData()))


# ---------------------------------------------------------------------------
# the tab
# ---------------------------------------------------------------------------

class MusicTab(QWidget):
    def __init__(self, session, parent=None):
        super().__init__(parent)
        self.s = session
        self._busy = False
        self._stale = False
        self.player = SongPlayer(self)
        self.player.stopped.connect(self._player_stopped)
        self.player.position.connect(self._player_pos)
        self.rom = None
        self.cur = None                     # selected song row (dict)
        root = QVBoxLayout(self)
        # meters
        top = QHBoxLayout()
        self.ids_bar = self._bar('song ids')
        self.b74_bar = self._bar('song bank 1 ($74)')
        self.b75_bar = self._bar('song bank 2 ($75)')
        for lbl, b in (('song ids', self.ids_bar), ('bank $74', self.b74_bar),
                       ('bank $75', self.b75_bar)):
            top.addWidget(QLabel(lbl))
            top.addWidget(b)
        top.addStretch(1)
        self.cap_err = QLabel()
        self.cap_err.setStyleSheet('color:#c33')
        top.addWidget(self.cap_err)
        root.addLayout(top)
        self.pages = QTabWidget()
        root.addWidget(self.pages, 1)
        self.pages.addTab(self._songs_page(), 'Songs')
        self.pages.addTab(self._rooms_page(), 'Rooms')
        self.pages.addTab(self._gates_page(), 'Gates')
        self.pages.addTab(self._battles_page(), 'Battles')
        h = QLabel(HELP)
        h.setWordWrap(True)
        root.addWidget(h)
        self.s.undo.indexChanged.connect(self._undo_changed)
        self.refresh()

    @staticmethod
    def _bar(tip):
        b = QProgressBar()
        b.setFixedWidth(150)
        b.setFixedHeight(16)
        b.setToolTip(tip)
        return b

    # ---------------------------------------------------------------- pages
    def _songs_page(self):
        w = QWidget()
        h = QHBoxLayout(w)
        split = QSplitter()
        h.addWidget(split)
        left = QWidget()
        lv = QVBoxLayout(left)
        fr = QHBoxLayout()
        self.filter = QComboBox()
        for txt, key in (('all songs', 'all'), ('in the project', 'project'),
                         ("the game's music + jingles", 'game'),
                         ("the game's sound effects", 'effect'),
                         ('DWM2 songs', 'dwm2'), ('MIDI library', 'midi')):
            self.filter.addItem(txt, key)
        self.filter.currentIndexChanged.connect(lambda _i: self._fill_songs())
        fr.addWidget(self.filter)
        self.search = QLineEdit()
        self.search.setPlaceholderText('search')
        self.search.textChanged.connect(lambda _t: self._fill_songs())
        fr.addWidget(self.search, 1)
        lv.addLayout(fr)
        self.song_list = QListWidget()
        self.song_list.currentRowChanged.connect(self._song_picked)
        self.song_list.itemDoubleClicked.connect(lambda _it: self._play())
        lv.addWidget(self.song_list, 1)
        br = QHBoxLayout()
        b = QPushButton('Import MIDI…')
        b.setToolTip('Convert a MIDI file into a song of this project (automatic: the 3 '
                     'busiest melodic channels -> pulse 1, pulse 2, wave; drums -> noise)')
        b.clicked.connect(self._import_midi)
        br.addWidget(b)
        br.addStretch(1)
        lv.addLayout(br)
        split.addWidget(left)
        right = QWidget()
        rv = QVBoxLayout(right)
        self.title = QLabel()
        self.title.setStyleSheet('font-size:15px;font-weight:bold')
        rv.addWidget(self.title)
        pr = QHBoxLayout()
        self.play_b = QPushButton('▶ Play')
        self.play_b.clicked.connect(self._play)
        self.stop_b = QPushButton('■ Stop')
        self.stop_b.clicked.connect(self.player.stop)
        self.wav_b = QPushButton('Save as WAV…')
        self.wav_b.clicked.connect(self._save_wav)
        self.pos = QLabel()
        for x in (self.play_b, self.stop_b, self.wav_b, self.pos):
            pr.addWidget(x)
        pr.addStretch(1)
        rv.addLayout(pr)
        ok, why = SongPlayer.available()
        if not ok:
            self.play_b.setEnabled(False)
            self.play_b.setToolTip(why)
            self.stop_b.setEnabled(False)
            if not _np():
                self.wav_b.setEnabled(False)
            self.no_audio = QLabel(why)
            self.no_audio.setStyleSheet('color:#c33')
            rv.addWidget(self.no_audio)
        f = QFormLayout()
        self.name_e = QLineEdit()
        self.name_e.setPlaceholderText('your name for this song (editor only)')
        self.name_e.editingFinished.connect(self._rename)
        f.addRow('name', self.name_e)
        self.info = QLabel()
        self.info.setWordWrap(True)
        self.info.setTextInteractionFlags(Qt.TextSelectableByMouse)
        f.addRow('', self.info)
        rv.addLayout(f)
        ar = QHBoxLayout()
        self.add_b = QPushButton('Add to the project')
        self.add_b.clicked.connect(self._add_song)
        self.rm_b = QPushButton('Remove from the project')
        self.rm_b.clicked.connect(self._remove_song)
        ar.addWidget(self.add_b)
        ar.addWidget(self.rm_b)
        ar.addStretch(1)
        rv.addLayout(ar)
        rv.addStretch(1)
        split.addWidget(right)
        split.setSizes([520, 700])
        return w

    def _rooms_page(self):
        w = QWidget()
        v = QVBoxLayout(w)
        v.addWidget(QLabel('A room\'s song plays when you enter it (and after a reload). '
                           '"Battles here" is the song of battles that start in the room.'))
        self.rooms_t = QTableWidget(0, 4)
        self.rooms_t.setHorizontalHeaderLabels(['room', "the game's song", 'your song',
                                                'battles here'])
        self.rooms_t.horizontalHeader().setSectionResizeMode(0, QHeaderView.Stretch)
        self.rooms_t.setEditTriggers(QAbstractItemView.NoEditTriggers)
        v.addWidget(self.rooms_t, 1)
        return w

    def _gates_page(self):
        w = QWidget()
        v = QVBoxLayout(w)
        v.addWidget(QLabel('A gate\'s song plays on its maze floors, its special rooms and '
                           'your rooms served in it that have no song of their own (the floor '
                           'before a VANILLA boss room keeps that boss song). Its battle song '
                           'plays in the battles there (a boss fight uses the Battles page).'))
        self.gates_t = QTableWidget(0, 3)
        self.gates_t.setHorizontalHeaderLabels(['gate', 'floors', 'battles'])
        self.gates_t.horizontalHeader().setSectionResizeMode(0, QHeaderView.Stretch)
        self.gates_t.setEditTriggers(QAbstractItemView.NoEditTriggers)
        v.addWidget(self.gates_t, 1)
        return w

    def _battles_page(self):
        w = QWidget()
        v = QVBoxLayout(w)
        g = QGroupBox('Battle songs (empty = the game\'s: the battle theme $27; the Starry '
                      'Night final $2B)')
        self.battle_form = QFormLayout(g)
        v.addWidget(g)
        v.addWidget(QLabel('Most specific wins: a fight\'s own song › the arena › the room\'s '
                           '"battles here" › the gate\'s battle song › a boss fight › every '
                           'other battle. Link battles always keep the game\'s.'))
        fg = QGroupBox('A song for one fight (the first enemy of the battle)')
        fv = QVBoxLayout(fg)
        self.fights_t = QTableWidget(0, 3)
        self.fights_t.setHorizontalHeaderLabels(['enemy', 'song', ''])
        self.fights_t.horizontalHeader().setSectionResizeMode(0, QHeaderView.Stretch)
        self.fights_t.setEditTriggers(QAbstractItemView.NoEditTriggers)
        fv.addWidget(self.fights_t, 1)
        b = QPushButton('+ Fight…')
        b.clicked.connect(self._add_fight)
        fr = QHBoxLayout()
        fr.addWidget(b)
        fr.addStretch(1)
        fv.addLayout(fr)
        v.addWidget(fg, 1)
        return w

    # ---------------------------------------------------------------- data
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

    def _rom(self):
        if self.rom is None:
            from editor2.app.session import REPO
            path = self.s.settings.value('rom/path') or os.path.join(REPO, 'data',
                                                                     'DWM-original.gbc')
            self.rom = open(path, 'rb').read()
        return self.rom

    def push(self, label, op, assets=()):
        cmd = C.SnapshotCommand(self.s, label, op, assets=assets)
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, label, str(cmd.error))
            self.refresh()
            return None
        try:
            self.s.doc.music_plan()
        except Exception as ex:                       # noqa: BLE001
            self.s.undo.undo()
            QMessageBox.warning(self, label, f'Not possible: {ex}')
            return None
        return cmd.result

    def song_label(self, key, default):
        nm = self.s.doc.song_name(key)
        return nm or default

    def project_song_labels(self):
        out = []
        for s in self.s.doc.project_songs():
            out.append((s['id'], self.song_label(s['id'], s.get('name') or s['id'])))
        return out

    def vanilla_song_labels(self):
        out = []
        for s in self.sounds:
            if s['kind'] == 'effect':
                continue
            out.append((s['id_int'], f"{s['id']} {self.song_label(s['id'], self._auto(s))}"))
        return out

    @staticmethod
    def _auto(s):
        """An automatic label for a game sound: where the game uses it."""
        if s['id_int'] == 0x02:
            return 'silence (music off)'
        bits = []
        if s['rooms']:
            r = s['rooms'][0].split(' ', 1)[1]
            bits.append(r + (f' +{len(s["rooms"]) - 1}' if len(s['rooms']) > 1 else ''))
        if s['code']:
            c = s['code'][0].split(' — ', 1)[-1]
            bits.append(c.split(' (')[0][:40])
        elif s['scripts']:
            bits.append(s['scripts'][0].split(' (script')[0] + ' scene')
        return KIND_LABEL[s['kind']] + (': ' + '; '.join(bits) if bits else '')

    def refresh(self):
        doc = self.s.doc
        self.sounds = doc.vanilla_sounds()
        self.lib = doc.library_songs()
        cap = doc.music_capacity()
        if cap.get('error'):
            self.cap_err.setText('Music: ' + cap['error'])
        else:
            self.cap_err.setText('')
            self.ids_bar.setRange(0, cap['ids_max'])
            self.ids_bar.setValue(cap['ids'])
            self.ids_bar.setFormat(f"{cap['ids']} / {cap['ids_max']}")
            for bank, bar in ((0x74, self.b74_bar), (0x75, self.b75_bar)):
                n = cap['banks'].get(bank, 0)
                bar.setRange(0, cap['bank_max'])
                bar.setValue(n)
                bar.setFormat(f'{n:,} / {cap["bank_max"]:,} B')
        self.cap = cap
        self._fill_songs()
        self._fill_rooms()
        self._fill_gates()
        self._fill_battles()

    # ---------------------------------------------------------------- songs
    def _rows(self):
        doc = self.s.doc
        rows = []
        in_proj = {}
        for s in doc.project_songs():
            src = s.get('source') or {}
            if 'library' in src:
                in_proj.setdefault(src['library'], s['id'])
            fid = (self.cap.get('song_ids') or {}).get(s['id'])
            rows.append({'kind': 'project', 'key': s['id'], 'sid': s['id'],
                         'label': self.song_label(s['id'], s.get('name') or s['id']),
                         'detail': 'project song' + (f' · id ${fid:02X}' if fid else '')
                         + (' · from ' + (src.get('library') or src.get('file') or 'inline'))})
        for s in self.sounds:
            rows.append({'kind': 'effect' if s['kind'] == 'effect' else 'game', 'key': s['id'],
                         'sid': s['id_int'], 'snd': s,
                         'label': f"{s['id']} " + self.song_label(s['id'], self._auto(s)),
                         'detail': f"the game's {KIND_LABEL[s['kind']]}"})
        for lid, e in sorted(self.lib.items()):
            kind = 'dwm2' if 'dwm2' in e['_library'] else 'midi'
            rows.append({'kind': kind, 'key': lid, 'lib': lid,
                         'label': self.song_label(lid, e.get('name') or lid),
                         'detail': ('DWM2 song' if kind == 'dwm2' else 'MIDI library')
                         + (f" · in the project as {in_proj[lid]}" if lid in in_proj else '')})
        return rows

    def _fill_songs(self):
        self._busy = True
        keep = self.cur['key'] if self.cur else None
        flt = self.filter.currentData()
        q = self.search.text().strip().lower()
        self.shown = []
        self.song_list.clear()
        for r in self._rows():
            if flt != 'all' and r['kind'] != flt:
                continue
            if q and q not in (r['label'] + ' ' + r['detail']).lower():
                continue
            it = QListWidgetItem(f"{r['label']}\n    {r['detail']}")
            if r['kind'] == 'project':
                f = it.font()
                f.setBold(True)
                it.setFont(f)
            elif r['kind'] == 'effect':
                it.setForeground(GREY)
            self.song_list.addItem(it)
            self.shown.append(r)
        self._busy = False
        row = next((i for i, r in enumerate(self.shown) if r['key'] == keep), 0)
        if self.shown:
            self.song_list.setCurrentRow(row)
            self._song_picked(row)
        else:
            self.cur = None
            self._show_song(None)

    def _song_picked(self, row):
        if self._busy or not (0 <= row < len(self.shown)):
            return
        self.cur = self.shown[row]
        self._show_song(self.cur)

    def _show_song(self, r):
        doc = self.s.doc
        self.add_b.setVisible(bool(r) and r['kind'] in ('dwm2', 'midi'))
        self.rm_b.setVisible(bool(r) and r['kind'] == 'project')
        if r is None:
            self.title.setText('')
            self.info.setText('')
            return
        self.title.setText(r['label'])
        self.name_e.setText(doc.song_name(r['key']) or '')
        lines = [r['detail']]
        if 'snd' in r:
            s = r['snd']
            roles = ', '.join(s['slots'])
            lines.append(f"{s['channels']} channel(s) ({roles}) · "
                         + (f"{s['length_frames'] / 59.73:.1f} s" if s['length_frames']
                            else 'loops'))
            if s['rooms']:
                lines.append('rooms: ' + ', '.join(s['rooms']))
            if s['scripts']:
                lines.append('scenes: ' + ', '.join(s['scripts']))
            if s['code']:
                lines.append('code: ' + '; '.join(s['code']))
        else:
            try:
                from editor2.core import music_preview as MP
                ch = doc.song_channels(r.get('sid') or r.get('lib'))
                info = MP.song_info(ch)
                lines.append(f"{len(ch)} channel(s) ({', '.join(info['roles'])}) · "
                             f"{info['bytes']:,} bytes · "
                             + ('loops' if info['loops'] else 'plays once'))
            except Exception as ex:                   # noqa: BLE001
                lines.append(f'(cannot read: {ex})')
        uses = doc.song_uses(r['sid']) if r.get('sid') is not None else []
        lines.append('used by: ' + (', '.join(uses) if uses else 'nothing yet'))
        self.info.setText('\n'.join(lines))

    def _renderer(self, r):
        from editor2.core import music_preview as MP
        if 'snd' in r:
            return MP.Renderer.vanilla(self._rom(), r['sid'], r['snd']['starts_as'])
        ch = self.s.doc.song_channels(r.get('sid') or r.get('lib'))
        return MP.Renderer.song(self._rom(), ch)

    def _play(self):
        if not self.cur or not self.play_b.isEnabled():
            return
        try:
            self.player.play(self._renderer(self.cur))
        except Exception as ex:                       # noqa: BLE001
            QMessageBox.warning(self, 'Play', str(ex))
            return
        self.play_b.setText('▶ Restart')

    def _player_stopped(self):
        self.play_b.setText('▶ Play')
        self.pos.setText('')

    def _player_pos(self, sec):
        self.pos.setText(f'{int(sec) // 60}:{int(sec) % 60:02d}')

    def _save_wav(self):
        if not self.cur:
            return
        secs, ok = QInputDialog.getInt(self, 'Save as WAV', 'Seconds (a song that ends stops '
                                       'sooner):', 90, 1, 900)
        if not ok:
            return
        path, _ = QFileDialog.getSaveFileName(self, 'Save as WAV',
                                              f"{self.cur['label'][:40].strip()}.wav",
                                              'WAV (*.wav)')
        if not path:
            return
        from editor2.core import music_preview as MP
        import numpy as np
        r = self._renderer(self.cur)
        parts = []
        while not r.ended and r.frames < secs * 59.7275:
            parts.append(r.render(seconds=5))
        with open(path, 'wb') as f:
            f.write(MP.wav(np.concatenate(parts)))

    def _rename(self):
        if self._busy or not self.cur:
            return
        nm = self.name_e.text().strip()
        if nm == (self.s.doc.song_name(self.cur['key']) or ''):
            return
        key = self.cur['key']
        self.push(f'Name song {key}', lambda doc: doc.set_song_name(key, nm))

    def _add_song(self):
        if not self.cur or 'lib' not in self.cur:
            return
        lid = self.cur['lib']
        sid = self.push(f'Add song {lid}', lambda doc: doc.add_library_song(lid))
        if sid:
            self.filter.setCurrentIndex(1)
            self._select(sid)

    def _remove_song(self):
        if not self.cur or self.cur['kind'] != 'project':
            return
        sid = self.cur['sid']
        uses = self.s.doc.song_uses(sid)
        if uses and QMessageBox.question(
                self, 'Remove song', f'{sid} is used by: {", ".join(uses)}.\n'
                'Remove it and those assignments (they go back to the game\'s songs)?') \
                != QMessageBox.Yes:
            return
        s = self.s.doc.project_song(sid)
        asset = (s.get('source') or {}).get('file')
        assets = [asset] if asset else []

        def op(doc):
            res = doc.remove_song(sid)
            if asset:
                p = os.path.join(doc.project_dir, asset)
                if os.path.exists(p):
                    os.remove(p)
            return res
        self.push(f'Remove song {sid}', op, assets=assets)

    def _import_midi(self):
        path, _ = QFileDialog.getOpenFileName(self, 'Import MIDI', '',
                                              'MIDI (*.mid *.midi)')
        if not path:
            return
        base = os.path.splitext(os.path.basename(path))[0]
        sid = self.s.doc.unique_song_id(base)
        asset = self.s.doc.midi_asset(sid)
        res = self.push(f'Import MIDI {base}', lambda doc: doc.import_midi(path, base),
                        assets=[asset])
        if res:
            sid, warnings = res
            self.filter.setCurrentIndex(1)
            self._select(sid)
            if warnings:
                QMessageBox.information(self, 'Import MIDI',
                                        f'{sid} imported. Notes:\n• ' + '\n• '.join(warnings))

    def _select(self, key):
        for i, r in enumerate(self.shown):
            if r['key'] == key:
                self.song_list.setCurrentRow(i)
                return

    # ---------------------------------------------------------------- rooms
    def _fill_rooms(self):
        from dwm.map_names import get_name
        doc = self.s.doc
        vanilla_tbl = None
        try:
            rom = self._rom()
            o = 0x4000 + 0x373
            vanilla_tbl = rom[o:o + 0x70]
        except Exception:                             # noqa: BLE001
            pass
        rows = []
        for r in doc.custom.get('rooms', []):
            if r.get('placeholder'):
                continue
            mid = int(str(r['mapID']), 0)
            rows.append((mid, f"{doc.room_name(r)}  (your room ${mid:02X})", 'the gate theme '
                         '$34 / in a gate: the gate\'s'))
        for mid in range(0x70):
            nm = get_name(mid)
            if nm.startswith('Map') and len(nm) <= 5:
                continue
            game = vanilla_tbl[mid] if vanilla_tbl else None
            gl = 'the gate theme $34' if mid in (0x50, 0x51) or 0x53 <= mid <= 0x5C or \
                mid >= 0x61 else (f'${game:02X} ' + self.song_label(f'0x{game:02X}', '')
                                  if game is not None else '?')
            rows.append((mid, f'${mid:02X} {nm}', gl))
        self.rooms_t.setRowCount(len(rows))
        for i, (mid, label, game) in enumerate(rows):
            self.rooms_t.setItem(i, 0, QTableWidgetItem(label))
            self.rooms_t.setItem(i, 1, QTableWidgetItem(game))
            c = SongCombo(self, doc.room_music(mid))
            c.picked.connect(lambda v, m=mid: self.push(
                f'Room ${m:02X} song', lambda d: d.set_room_music_id(m, v)))
            self.rooms_t.setCellWidget(i, 2, c)
            b = SongCombo(self, doc.room_battle_music(mid), default_label='— not set —')
            b.picked.connect(lambda v, m=mid: self.push(
                f'Room ${m:02X} battle song', lambda d: d.set_room_battle_music(m, v)))
            self.rooms_t.setCellWidget(i, 3, b)

    # ---------------------------------------------------------------- gates
    def _fill_gates(self):
        doc = self.s.doc
        try:
            gates = doc.all_gates()
        except Exception:                             # noqa: BLE001
            gates = []
        self.gates_t.setRowCount(len(gates))
        for i, g in enumerate(gates):
            gid = g['id']
            self.gates_t.setItem(i, 0, QTableWidgetItem(
                f"{gid}  {g.get('name', '')}" + ('  (your new gate)' if g.get('new') else '')))
            fl, bt = doc.gate_music(gid)
            a = SongCombo(self, fl, default_label='— the gate theme —')
            a.picked.connect(lambda v, n=gid: self.push(
                f'Gate {n} song', lambda d: d.set_gate_music(n, floors=v)))
            self.gates_t.setCellWidget(i, 1, a)
            b = SongCombo(self, bt, default_label='— the battle theme —')
            b.picked.connect(lambda v, n=gid: self.push(
                f'Gate {n} battle song', lambda d: d.set_gate_music(n, battles=v)))
            self.gates_t.setCellWidget(i, 2, b)

    # ---------------------------------------------------------------- battles
    def _fill_battles(self):
        doc = self.s.doc
        while self.battle_form.rowCount():
            self.battle_form.removeRow(0)
        bm = doc.battle_music()
        for kind, label in (('normal', 'every battle'), ('boss', 'boss fights (gate bosses)'),
                            ('arena', 'arena battles'), ('starry', 'the Starry Night final')):
            c = SongCombo(self, bm[kind])
            c.picked.connect(lambda v, k=kind: self.push(
                f'{k} battle song', lambda d: d.set_battle_music(k, v)))
            self.battle_form.addRow(label, c)
        fights = doc.fight_music()
        self.fights_t.setRowCount(len(fights))
        names = self._enemy_names()
        for i, (eid, v) in enumerate(sorted(fights.items())):
            self.fights_t.setItem(i, 0, QTableWidgetItem(names.get(eid, f'EID {eid}')))
            c = SongCombo(self, v)
            c.picked.connect(lambda val, e=eid: self.push(
                f'Fight {e} song', lambda d: d.set_fight_music(e, val)))
            self.fights_t.setCellWidget(i, 1, c)
            b = QPushButton('remove')
            b.clicked.connect(lambda _c=False, e=eid: self.push(
                f'Fight {e}: no song', lambda d: d.set_fight_music(e, None)))
            self.fights_t.setCellWidget(i, 2, b)

    def _enemy_names(self):
        try:
            return {eid: label for label, _ref, eid, _sp in self.s.doc.enemy_choices()}
        except Exception:                             # noqa: BLE001
            return {}

    def _add_fight(self):
        try:
            choices = self.s.doc.enemy_choices()
        except Exception as ex:                       # noqa: BLE001
            QMessageBox.warning(self, 'Fight', str(ex))
            return
        labels = [c[0] for c in choices]
        lab, ok = QInputDialog.getItem(self, 'A song for one fight',
                                       'The battle\'s first enemy (your enemies first, then '
                                       'the game\'s rows; bosses and arena teams tagged):',
                                       labels, 0, False)
        if not ok:
            return
        eid = choices[labels.index(lab)][2]
        songs = self.project_song_labels() + self.vanilla_song_labels()
        if not songs:
            return
        sl = [s[1] for s in songs]
        pick, ok = QInputDialog.getItem(self, 'A song for one fight', 'Song:', sl, 0, False)
        if not ok:
            return
        v = songs[sl.index(pick)][0]
        self.push(f'Fight {eid} song', lambda d: d.set_fight_music(eid, v))

    def hideEvent(self, ev):
        self.player.stop()
        super().hideEvent(ev)
