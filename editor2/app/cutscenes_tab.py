"""cutscenes_tab.py — the Cutscenes tab + the Playback window (S118, ROADMAP P3.8
part A; model: editor2/core/cutscenes.py + script_ops.py, the game itself:
editor2/core/playback.py).

Left: every scene — the intro chain, your rooms (custom and cloned rooms, the
scripts exactly as the compiler builds them) and every game room — filtered to
the scenes where actors move (or everything that shows something), searchable.
Middle: the storyboard — what starts the scene, when it plays (the conditions
on the way to it), and its steps as sentences (walks, jumps, turns, appearing,
texts, flags, music, room changes …). Right: the picture of the selected step —
a frame RECORDED from the real game ("Record frames", automatic when PyBoy is
installed) or, without PyBoy, the room with the actors where the model puts
them.

▶ Play opens the Playback window: the game runs the scene in the editor with
sound; it is set up for you (flags, room, trigger) — no walking there. Text
boxes advance by themselves (turn "Auto text" off to press A yourself: arrows,
Z = A, X = B, Enter = Start); the current step is highlighted in the storyboard.
"""

import json
import os

from PySide6.QtCore import QObject, QThread, QTimer, Qt, Signal
from PySide6.QtGui import QColor, QFont, QImage, QPainter, QPen, QPixmap
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDialog, QDialogButtonBox,
                               QFileDialog, QFormLayout, QGroupBox,
                               QHBoxLayout, QLabel, QLineEdit, QListWidget,
                               QListWidgetItem, QMessageBox, QPlainTextEdit,
                               QPushButton, QSlider, QSpinBox, QSplitter, QStackedWidget,
                               QTreeWidget, QTreeWidgetItem, QVBoxLayout, QWidget)

from editor2.app.session import REPO
from editor2.core import cutscenes as CS
from editor2.core import script_ops as SO

KIND_COLOUR = {'actor': QColor(140, 200, 255), 'text': QColor(240, 230, 160),
               'flow': QColor(170, 170, 170), 'state': QColor(200, 170, 255),
               'world': QColor(255, 170, 120), 'battle': QColor(255, 120, 120),
               'sound': QColor(160, 230, 160), 'screen': QColor(255, 200, 120),
               'wait': QColor(150, 150, 150), 'party': QColor(255, 180, 220),
               'item': QColor(255, 220, 150)}
SPRITE_DIR = os.path.join(REPO, 'extracted', 'npc_field_sprites')
ROLE = Qt.UserRole + 1
TRIGGER_WORDS = {'entry': 'entering the room', 'talk': 'talking to someone',
                 'examine': 'examining a spot', 'stepon': 'stepping on a spot',
                 'arm': 'the script itself (started directly)',
                 'newgame': 'starting a new game',
                 'head': 'its own first step (it plays after a battle is won)'}
HELP = ('Every scene the game plays with its scripts — and your rooms\' scenes as you built '
        'them. ▶ Play runs it in the real game right here (set up for you: no walking '
        'there). Pictures on the right are recorded from the game. Your own cutscenes '
        '(＋ New cutscene) are made on the room itself, in tiles, and previewed here.')


def _qimage(arr):
    """numpy (144, 160, 4) RGBA -> QImage (a copy)."""
    h, w = arr.shape[0], arr.shape[1]
    img = QImage(arr.tobytes(), w, h, w * 4, QImage.Format_RGBA8888)
    return img.copy()


def _pil_to_qimage(im):
    im = im.convert('RGBA')
    return QImage(im.tobytes(), im.width, im.height, im.width * 4,
                  QImage.Format_RGBA8888).copy()


# ---------------------------------------------------------------- the model

class TextCtx:
    """Names for script_ops.sentence() — S118f: every number in words (flags,
    RAM variables and room states, rooms, items, monsters, skills, music)."""

    _shared = {}

    def __init__(self, text, actors=None, labels=None, cat=None, vanilla=None):
        self._text, self.actors, self.labels = text, actors or {}, labels or {}
        self.cat, self.vanilla = cat, vanilla or cat
        from editor2.core.ram_names import RamNames
        rooms = getattr(self.vanilla, 'rooms', None)
        self.names = RamNames(rooms, enemy_name=self.enemy)

    @classmethod
    def _data(cls, key, make):
        if key not in cls._shared:
            try:
                cls._shared[key] = make()
            except Exception:                            # noqa: BLE001
                cls._shared[key] = {}
        return cls._shared[key]

    def flag(self, n):
        d = ''
        try:
            d = self.cat.flag_desc(n) if self.cat is not None else ''
        except Exception:                                # noqa: BLE001
            d = ''
        return f'flag ${n:04X}' + (f' ({d})' if d else '')

    def room(self, m):
        if self.cat is not None and hasattr(self.cat, 'room') and m >= 0x6B:
            r = self.cat.room(m) or {}
            if r.get('name'):
                return r['name']
        try:
            return self.vanilla.rooms.name(m)
        except Exception:                                # noqa: BLE001
            return ''

    def item(self, n):
        from editor2.core.shops import item_names
        return self._data('items', item_names).get(n, '')

    def enemy(self, row):
        from editor2.core.conversation import vanilla_enemies
        by = self._data('enemies', lambda: {e['eid']: e['name'] for e in vanilla_enemies()})
        return by.get(row, '')

    def skill(self, k):
        from editor2.core.conversation import skill_names
        return self._data('skills', skill_names).get(k, f'skill ${k:02X}')

    def species(self, k):
        from editor2.core.conversation import species_names
        return self._data('species', species_names).get(k, f'species ${k:02X}')

    def _sound(self):
        def make():
            d = json.load(open(os.path.join(REPO, 'extracted', 'sound_catalog.json')))
            return {s['id_int']: s for s in d.get('sounds', [])}
        return self._data('sounds', make)

    def music(self, k):
        s = self._sound().get(k)
        if k == 0x02:
            return 'music off'
        if not s:
            return ''
        where = [r.split(' ', 1)[-1] for r in s.get('rooms', [])][:2]
        kind = 'a jingle' if s.get('kind') == 'jingle' else 'the music'
        return f'{kind} of {", ".join(where)}' if where else kind

    def sound(self, k):
        return ''

    def patch(self, addr):
        """(w, h, tile col, tile row) of a $24 / $61 tile patch in the scene's
        script bank: [offset word, tiles, $D8 next row, $D9 end]."""
        rom, bank = getattr(self.vanilla, 'rom', None), getattr(self, 'bank', None)
        if rom is None or bank is None or not 0x4000 <= addr < 0x8000:
            return None
        o = bank * 0x4000 + addr - 0x4000
        off = rom[o] | rom[o + 1] << 8
        w = h = cur = 0
        for b in rom[o + 2:o + 2 + 64]:
            if b == 0xD9:
                break
            if b == 0xD8:
                w, cur, h = max(w, cur), 0, h + 1
                continue
            cur += 1
        w, h = max(w, cur), h + 1
        return w, h, off % 32, off // 32

    def actor(self, n):
        if n == 0:
            return 'Terry'
        a = self.actors.get(n)
        if a is not None and a.name:
            return f'NPC {n} ({a.name})'
        if a is not None and a.sprite is not None:
            return f'NPC {n} (sprite ${a.sprite:02X})'
        return f'NPC {n}'

    def text(self, tid):
        t = self._text(tid) if self._text else ''
        return (t or '').split('\n')[0][:60]

    def label(self, pos):
        return self.labels.get(pos, f'step {pos}')


def questions_of(recipe, scene):
    """S119: the YES/NO texts of a scene's script — (type, script, pos) of every
    text followed by the $C83C test — for the auto answer in project scripts."""
    out = []
    steps = scene.script.steps
    for st in steps.values():
        nx = steps.get(st.pos + 1)
        if st.code == CS.TEXT and nx is not None and nx.code == 0x15 and nx.params \
                and nx.params[0] == 0xC83C:
            out.append([recipe.script_type & 0xFF, recipe.script_idx, st.pos])
    return out


class SceneRef:
    def __init__(self, kind, mid, scene, cat, title, chain=None):
        self.kind, self.mid, self.scene, self.cat = kind, mid, scene, cat
        self.title, self.chain = title, chain


# ---------------------------------------------------------------- recording

def game_muted():
    """The editor-wide "Mute game playback" switch (View menu, S118e — user:
    "mute preview pyboy player GLOBALLY in the menu … Overrides all others")."""
    from PySide6.QtCore import QSettings
    v = QSettings('dwm1_disassembly', 'DWM1Editor').value('playback/mute', False)
    return v in (True, 'true', '1', 1)


class Recorder(QObject):
    """Plays a scene silently in a playback-server process and keeps the last
    frame of every step it rested on — the storyboard's pictures. Runs in a
    QThread; a game that hangs is killed (the editor never freezes)."""
    done = Signal(object, object)          # key, {counter: QImage}
    failed = Signal(object, str)

    def __init__(self, key, rom_path, sav, cache_dir, recipe, scene, max_frames=15000):
        super().__init__()
        self.key, self.rom_path, self.sav, self.cache_dir = key, rom_path, sav, cache_dir
        self.recipe, self.scene, self.max_frames = recipe, scene, max_frames
        self.cancel = False
        self.client = None

    def run(self):
        from editor2.core.playback_server import PlaybackClient, recipe_dict
        try:
            self.client = PlaybackClient(REPO)
            self.client.call({'cmd': 'open', 'rom': self.rom_path, 'cache_dir': self.cache_dir,
                              'sav': self.sav, 'sound': False}, timeout=120)
            if self.cancel:
                raise RuntimeError('cancelled')
            head, payload = self.client.call(
                {'cmd': 'record', 'recipe': recipe_dict(self.recipe),
                 'party': any(st.code in (0x05, 0x5A, 0x5B, 0x20) for st in self.scene.steps),
                 'script_type': self.recipe.script_type, 'script_idx': self.recipe.script_idx,
                 'questions': questions_of(self.recipe, self.scene),
                 'max_frames': self.max_frames}, timeout=180)
            out, off = {}, 0
            for ctr in head.get('order', []):
                n = head['frames'][ctr]
                img = QImage.fromData(payload[off:off + n], 'PNG')
                off += n
                if head.get('by') == 'pos':     # S118b: one picture per step
                    out[int(ctr)] = img
                    continue
                st = CS.step_at_counter(self.scene.script, int(ctr))
                if st is not None:              # counter -> the step it rests on
                    out[st.pos] = img
            self.client.close()
            if not self.cancel:
                self.done.emit(self.key, out)
        except Exception as ex:                          # noqa: BLE001
            if self.client is not None:
                self.client.kill()
            if not self.cancel:
                self.failed.emit(self.key, f'{ex}')


# ---------------------------------------------------------------- the window

class EngineAudio:
    """music_tab.SongPlayer's renderer protocol over the playback engine."""

    def __init__(self, win):
        self.win = win
        self.frames = 0
        self.ended = False

    def render(self, frames=2):
        out = self.win._run_frames(frames, sound=True)
        self.frames = self.win.st.get('frames', 0)
        if self.win.eng is None:
            self.ended = True
        return out


class PlaybackWindow(QDialog):
    """The game, playing a scene (or a chain of scenes) in the editor."""
    position = Signal(int, int, int)       # script type, script id, counter
    KEYS = {Qt.Key_Up: 'up', Qt.Key_Down: 'down', Qt.Key_Left: 'left',
            Qt.Key_Right: 'right', Qt.Key_Z: 'a', Qt.Key_Space: 'a', Qt.Key_X: 'b',
            Qt.Key_Return: 'start', Qt.Key_Enter: 'start', Qt.Key_Backspace: 'select'}

    def __init__(self, parent, rom_path, sav, cache_dir, items, title, sound=True,
                 skip_to=None, start_extra=None):
        super().__init__(parent)
        # S132 (Play here): extra 'start' fields — party records (hex), repoke
        self.start_extra = dict(start_extra or {})
        self.skip_to = skip_to                 # play fast up to this step of the 1st scene
        self.skipping = False
        self.setWindowTitle(f'Playback — {title}')
        self.setAttribute(Qt.WA_DeleteOnClose)
        self.rom_path, self.sav, self.cache_dir = rom_path, sav, cache_dir
        self.items = list(items)               # [(recipe, scene, label)]
        self.index = 0
        self.eng = None                        # the PlaybackClient (game process)
        self.st = {}                           # the game's last status
        self.img = None                        # the last frame (QImage)
        self.buttons = set()
        self.hung = False
        self.player = None
        self.running = False
        self.speed = 1
        self._ended_at = None
        v = QVBoxLayout(self)
        self.screen = QLabel()
        self.screen.setFixedSize(480, 432)
        self.screen.setAlignment(Qt.AlignCenter)
        self.screen.setStyleSheet('background:#000;')
        v.addWidget(self.screen, 0, Qt.AlignHCenter)
        self.status = QLabel('')
        self.status.setWordWrap(True)
        v.addWidget(self.status)
        row = QHBoxLayout()
        self.b_play = QPushButton('❚❚ Pause')
        self.b_play.clicked.connect(self.toggle)
        row.addWidget(self.b_play)
        b = QPushButton('Frame ▸')
        b.setToolTip('Advance one frame (pauses first)')
        b.clicked.connect(self.step_frame)
        row.addWidget(b)
        self.b_back = QPushButton('◂ Step back')
        self.b_back.setToolTip('Go back to before the last "Step ▸▸"')
        self.b_back.clicked.connect(lambda: self.step_script(back=True))
        row.addWidget(self.b_back)
        b = QPushButton('Step ▸▸')
        b.setToolTip('Run until the scene\'s NEXT step starts and stop there (pauses first). '
                     'Steps that take no time (turns, flags) are stepped one by one too; '
                     'the log says what ran.')
        b.clicked.connect(self.step_script)
        row.addWidget(b)
        b = QPushButton('⟲ Restart')
        b.clicked.connect(self.restart)
        row.addWidget(b)
        self.b_next = QPushButton('Next scene ⏭')
        self.b_next.clicked.connect(self.next_scene)
        row.addWidget(self.b_next)
        self.speed_box = QComboBox()
        for label, sp in (('1× (sound)', 1), ('2×', 2), ('4×', 4), ('8×', 8)):
            self.speed_box.addItem(label, sp)
        self.speed_box.currentIndexChanged.connect(self._speed)
        row.addWidget(self.speed_box)
        v.addLayout(row)
        row2 = QHBoxLayout()
        self.c_text = QCheckBox('Auto text')
        self.c_text.setChecked(True)
        self.c_text.setToolTip('Text boxes advance by themselves. Off: press A yourself '
                               '(Z or Space).')
        self.c_text.toggled.connect(self._options)
        row2.addWidget(self.c_text)
        row2.addWidget(QLabel('read time'))
        self.pause = QSlider(Qt.Horizontal)
        self.pause.setRange(0, 240)
        self.pause.setValue(75)
        self.pause.setToolTip('How long a full text box stays before auto text presses A '
                              '(frames; 60 = 1 second)')
        self.pause.valueChanged.connect(self._options)
        row2.addWidget(self.pause)
        row2.addWidget(QLabel('YES/NO:'))
        self.answer = QComboBox()
        self.answer.addItems(['No', 'Yes'])
        self.answer.currentIndexChanged.connect(self._options)
        row2.addWidget(self.answer)
        self.c_dpad = QCheckBox('Auto D-pad')
        self.c_dpad.setChecked(True)
        self.c_dpad.setToolTip('When the script waits for a D-pad press (the bedroom wake-up), '
                               'press right.')
        self.c_dpad.toggled.connect(self._options)
        row2.addWidget(self.c_dpad)
        self.c_sound = QCheckBox('Sound')
        self.c_sound.setChecked(sound)
        self.c_sound.toggled.connect(self._sound_toggled)
        row2.addWidget(self.c_sound)
        self.apply_mute()
        v.addLayout(row2)
        keys = QLabel('Keys (click the picture first): arrows · Z / Space = A · X = B · '
                      'Enter = Start · Backspace = Select')
        keys.setStyleSheet('color:#888;')
        v.addWidget(keys)
        self.log = QPlainTextEdit()
        self.log.setReadOnly(True)
        self.log.setMaximumHeight(90)
        v.addWidget(self.log)
        self.video = QTimer(self)
        self.video.setInterval(33)
        self.video.timeout.connect(self._show)
        self.clock = QTimer(self)
        self.clock.setInterval(16)
        self.clock.timeout.connect(self._tick)
        self.setFocusPolicy(Qt.StrongFocus)
        QTimer.singleShot(0, self._boot)

    # -------------------------------------------------------------- set-up
    def _boot(self):
        from editor2.core import playback as PB
        from editor2.core.playback_server import GameHung, PlaybackClient
        ok, why = PB.available()
        if not ok:
            self.status.setText(why)
            return
        self.status.setText('Starting the game… (the first time for a build takes a few '
                            'seconds)')
        self.repaint()
        try:
            self.eng = PlaybackClient(REPO)
            head, _p = self.eng.call({'cmd': 'open', 'rom': self.rom_path,
                                      'cache_dir': self.cache_dir, 'sav': self.sav,
                                      'sound': True}, timeout=120)
            if head.get('made_base'):
                self._say('made the start state for this ROM (cached)')
        except (GameHung, RuntimeError) as ex:
            self.status.setText(f'Could not start the game: {ex}')
            self.eng = None
            return
        self.hung = False
        self.start_item(0)

    def start_item(self, i):
        from editor2.core.playback_server import GameHung, recipe_dict
        if self.eng is None:
            return
        self.stop_audio()
        self.clock.stop()
        self.index = i
        recipe, scene, label = self.items[i]
        self._say(f'— {label}')
        try:
            head, _p = self.eng.call(dict({'cmd': 'start', 'recipe': recipe_dict(recipe),
                                           'party': any(st.code in (0x05, 0x5A, 0x5B, 0x20)
                                                        for st in scene.steps),
                                           'questions': questions_of(recipe, scene)},
                                          **self.start_extra), timeout=60)
            for line in head.get('log', []):
                self._say(line)
        except GameHung as ex:
            self._hung(ex)
            return
        except RuntimeError as ex:
            self._say(f'set-up failed: {ex}')
        for n in recipe.notes:
            self._say('note: ' + n)
        self._ended_at = None
        self.b_next.setEnabled(i + 1 < len(self.items))
        self.skipping = i == 0 and self.skip_to is not None
        if self.skipping:
            st = scene.script.steps.get(self.skip_to)
            self._say(f'running fast to step {self.skip_to}'
                      + (f' ({SO.sentence(st.code, st.params, None, st.target)[:50]})'
                         if st is not None else '') + ' …')
        self.running = True
        self._run()

    def _hung(self, ex):
        self.hung = True
        self.clock.stop()
        self.stop_audio()
        self.video.stop()
        self.eng = None
        self.status.setText(f'⚠ {ex}')
        self._say(f'⚠ {ex}  — press Restart to start again')

    def _say(self, msg):
        self.log.appendPlainText(msg)

    # -------------------------------------------------------------- running
    def _run(self):
        self.b_play.setText('❚❚ Pause')
        self.video.start()
        if self.skipping:
            self.clock.start()                 # fast, silent
            return
        if self.c_sound.isChecked() and not game_muted() and self.speed == 1 and \
                self._audio_ok():
            from editor2.app.music_tab import SongPlayer
            if self.player is None:
                self.player = SongPlayer(self)
            try:
                self.player.play(EngineAudio(self))
                return
            except Exception as ex:                      # noqa: BLE001
                self._say(f'sound off: {ex}')
        self.clock.start()

    def apply_mute(self):
        """Follow the editor-wide mute (it overrides this window's Sound box)."""
        muted = game_muted()
        self.c_sound.setEnabled(not muted)
        self.c_sound.setToolTip('Muted for every Playback window: View → Mute game playback'
                                if muted else 'Sound at 1× speed')
        if getattr(self, 'eng', None) is not None and (
                self.clock.isActive() or (self.player is not None and self.player.playing)):
            self.clock.stop()
            self.stop_audio()
            self._run()

    def _audio_ok(self):
        try:
            from editor2.app.music_tab import SongPlayer
            ok, why = SongPlayer.available()
            if not ok:
                self._say(why)
            return ok
        except Exception:                                # noqa: BLE001
            return False

    def stop_audio(self):
        if self.player is not None:
            self.player.stop()

    def _opts(self):
        if self.skipping:
            return {'auto_text': True, 'text_pause': 2, 'auto_dpad': True,
                    'answer': 'yes' if self.answer.currentIndex() == 1 else 'no'}
        return {'auto_text': self.c_text.isChecked(), 'text_pause': self.pause.value(),
                'answer': 'yes' if self.answer.currentIndex() == 1 else 'no',
                'auto_dpad': self.c_dpad.isChecked()}

    def _skip_check(self):
        """Stop running fast once the game is on the chosen step (or past it)."""
        if not self.skipping:
            return
        st = self.st
        recipe, scene, _l = self.items[self.index]
        done = st.get('ended')
        if st.get('active') and (st['type'], st['script']) == (recipe.script_type & 0xFF,
                                                               recipe.script_idx):
            cur = CS.step_at_counter(scene.script, st['pos'])
            if cur is not None and cur.pos >= self.skip_to:
                done = True
        if done:
            self.skipping = False
            self._say(f'at step {self.skip_to} — playing normally' if not st.get('ended')
                      else f'the scene ended before step {self.skip_to}')
            QTimer.singleShot(0, self._speed)

    def _run_frames(self, n, sound=False):
        import numpy as np
        from editor2.core.playback_server import GameHung
        if self.eng is None:
            return np.zeros((0, 2), np.int16) if sound else None
        try:
            head, payload = self.eng.call({'cmd': 'run', 'frames': n, 'audio': sound,
                                           'buttons': sorted(self.buttons),
                                           'opts': self._opts()}, timeout=10)
        except (GameHung, RuntimeError) as ex:
            err = ex                           # `ex` is unbound after the except block
            QTimer.singleShot(0, lambda: self._hung(err))
            return np.zeros((0, 2), np.int16) if sound else None
        fl = head['frame']
        self.img = QImage(payload[:fl], 160, 144, 640, QImage.Format_RGBA8888).copy()
        self.st = head['status']
        for line in self.st.get('log', []):
            self._say(line)
        self._skip_check()
        self._chain_check()
        if not sound:
            return None
        return np.frombuffer(payload[fl:fl + head['audio']], np.int16).reshape(-1, 2).copy()

    def _tick(self):
        self._run_frames(24 if self.skipping else self.speed)

    def _chain_check(self):
        st = self.st
        frames = st.get('frames', 0)
        if st.get('ended') and self._ended_at is None:
            self._ended_at = frames
            self._say(f'the scene\'s script ended (frame {frames})'
                      + ('' if self.index + 1 >= len(self.items) else
                         ' — the next scene starts in 2 seconds'))
        if (self._ended_at is not None and self.index + 1 < len(self.items)
                and frames - self._ended_at > 120):
            QTimer.singleShot(0, lambda: self.start_item(self.index + 1))
            self._ended_at = 1 << 30

    def _show(self):
        if self.eng is None or self.img is None or not self.st:
            return
        self.screen.setPixmap(QPixmap.fromImage(self.img).scaled(480, 432))
        w = self.st
        recipe, scene, label = self.items[self.index]
        line = f"{label} · room ${w['map']:02X} screen {w['screen']} · frame {w['frames']}"
        if w['active']:
            st = None
            if (w['type'], w['script']) == (recipe.script_type & 0xFF, recipe.script_idx):
                st = CS.step_at_counter(scene.script, w['pos'])
            line += f" · script {w['script']} step {w['pos']}"
            if st is not None:
                line += ' — ' + SO.sentence(st.code, st.params, None, st.target)
            self.position.emit(w['type'], w['script'], w['pos'])
        elif self._ended_at is not None:
            line += ' · the scene is over (the game keeps running: you can walk around)'
        self.status.setText(line)

    def toggle(self):
        if self.eng is None:
            return
        if self.clock.isActive() or (self.player is not None and self.player.playing):
            self.clock.stop()
            self.stop_audio()
            self.video.stop()
            self._show()
            self.b_play.setText('▶ Play')
        else:
            self._run()

    def step_frame(self):
        if self.eng is None:
            return
        if self.clock.isActive() or (self.player is not None and self.player.playing):
            self.toggle()
        self._run_frames(1)
        self._show()

    def step_script(self, back=False):
        """Script-step stepping (S118b): the game runs until the scene's next
        step is dispatched (the server's dispatch hook) and stops at the end of
        that frame; back = the state before the last step."""
        from editor2.core.playback_server import GameHung
        if self.eng is None:
            return
        if self.clock.isActive() or (self.player is not None and self.player.playing):
            self.toggle()
        recipe, scene, _l = self.items[self.index]
        try:
            head, payload = self.eng.call({'cmd': 'step', 'back': back,
                                           'script_type': recipe.script_type,
                                           'script_idx': recipe.script_idx,
                                           'opts': self._opts()}, timeout=30)
        except (GameHung, RuntimeError) as ex:
            err = ex
            QTimer.singleShot(0, lambda: self._hung(err))
            return
        fl = head['frame']
        self.img = QImage(payload[:fl], 160, 144, 640, QImage.Format_RGBA8888).copy()
        self.st = head['status']
        if back:
            self._say(f'◂ back (frame {self.st.get("frames")})')
        elif head.get('ran'):
            said = []
            for p in head['ran']:
                st = scene.script.steps.get(p)
                if st is not None:
                    said.append(f'{p}: ' + SO.sentence(st.code, st.params, None, st.target)[:60])
            self._say(f'▸▸ after {head.get("frames_run")} frame(s) — ' + ' · '.join(said))
        elif self.st.get('ended'):
            self._say('the scene\'s script has ended')
        else:
            self._say(f'no new step within {head.get("frames_run")} frames (the game waits — '
                      'for you? press a key, or Play)')
        self._chain_check()
        self._show()

    def restart(self):
        if self.eng is None:
            self._boot()
        else:
            self.start_item(0)

    def next_scene(self):
        if self.eng is not None and self.index + 1 < len(self.items):
            self.start_item(self.index + 1)

    def _speed(self):
        self.speed = self.speed_box.currentData() or 1
        if self.eng is not None and (self.clock.isActive() or
                                     (self.player is not None and self.player.playing)):
            self.clock.stop()
            self.stop_audio()
            self._run()

    def _sound_toggled(self, _on):
        self._speed()

    def _options(self, *_a):
        pass                                   # sent with every run command

    # -------------------------------------------------------------- keys
    def keyPressEvent(self, ev):
        b = self.KEYS.get(ev.key())
        if b and not ev.isAutoRepeat():
            self.buttons.add(b)
            return
        super().keyPressEvent(ev)

    def keyReleaseEvent(self, ev):
        b = self.KEYS.get(ev.key())
        if b and not ev.isAutoRepeat():
            self.buttons.discard(b)
            return
        super().keyReleaseEvent(ev)

    def closeEvent(self, ev):
        self.clock.stop()
        self.video.stop()
        if self.player is not None:
            self.player.shutdown()
        if self.eng is not None:
            self.eng.close()
            self.eng = None
        super().closeEvent(ev)


# ---------------------------------------------------------------- S119 part c: one script step

class OpDialog(QDialog):
    """One step of a copied room's script: any of the game's 102 opcodes (named and
    explained — script_ops), a text, or the end; its parameters as numbers ($xx /
    decimal), RAM / flag symbols, or a label of the script (branches)."""

    def __init__(self, parent, cur, labels):
        super().__init__(parent)
        self.setWindowTitle('Script step')
        self.resize(560, 360)
        self.labels = labels
        self.value = None
        v = QVBoxLayout(self)
        f = QFormLayout()
        v.addLayout(f)
        self.kind = QComboBox()
        self.kind.addItem('Text (a dialogue id)', 'text')
        self.kind.addItem('End — control back to the player', 'end')
        for c, o in sorted(SO.OPS.items()):
            self.kind.addItem(f'${c:02X} {o.name} — {o.doc.split(".")[0][:60]}', c)
        f.addRow('Step', self.kind)
        self.params = [QLineEdit() for _ in range(3)]
        self.plabels = [QLabel('') for _ in range(3)]
        for lb, ed in zip(self.plabels, self.params):
            ed.textChanged.connect(self._preview)
            f.addRow(lb, ed)
        self.doc = QLabel('')
        self.doc.setWordWrap(True)
        self.doc.setStyleSheet('color:#9ab;')
        v.addWidget(self.doc)
        self.prev = QLabel('')
        self.prev.setWordWrap(True)
        v.addWidget(self.prev)
        if labels:
            lab = QLabel('Labels of this script (for branches, write @NAME): ' + ', '.join(labels[:40]))
            lab.setWordWrap(True)
            lab.setStyleSheet('color:#888;')
            v.addWidget(lab)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self._ok)
        bb.rejected.connect(self.reject)
        v.addWidget(bb)
        self.kind.currentIndexChanged.connect(self._kind)
        if cur:
            if cur[0] == 'text':
                self.kind.setCurrentIndex(0)
                self.params[0].setText(str(cur[1]))
            elif cur[0] == 'end':
                self.kind.setCurrentIndex(1)
            else:
                code = self._code(cur[1])
                i = self.kind.findData(code)
                self.kind.setCurrentIndex(max(0, i))
                for k, prm in enumerate(cur[2:5]):
                    self.params[k].setText(str(prm))
        self._kind()

    @staticmethod
    def _code(name):
        from editor2.core import scriptgen as SG
        if isinstance(name, str) and name in SG.OPS:
            return SG.OPS[name][0]
        for c, o in SO.OPS.items():
            if o.name == name:
                return c
        try:
            return CS._pv(name)
        except Exception:                                # noqa: BLE001
            return None

    def _kind(self, *_a):
        k = self.kind.currentData()
        names = ['text id'] if k == 'text' else [] if k == 'end' else list(SO.OPS[k].params)
        self.nparams = len(names)
        for i in range(3):
            show = i < len(names)
            self.params[i].setVisible(show)
            self.plabels[i].setVisible(show)
            if show:
                br = isinstance(k, int) and SO.OPS[k].branch == i
                self.plabels[i].setText(names[i] + (' (@label)' if br else ''))
        self.doc.setText('' if k in ('text', 'end') else SO.OPS[k].doc)
        self._preview()

    def _vals(self):
        return [ed.text().strip() for ed in self.params[:getattr(self, 'nparams', 0)]]

    def _preview(self, *_a):
        k = self.kind.currentData()
        if k in ('text', 'end'):
            self.prev.setText('')
            return
        nums = []
        for t in self._vals():
            v = CS._pv(t) if t and not t.startswith('@') else 0
            nums.append(v if isinstance(v, int) else 0)
        try:
            self.prev.setText('Reads: ' + SO.sentence(k, nums))
        except Exception:                                # noqa: BLE001
            self.prev.setText('')

    def _ok(self):
        k = self.kind.currentData()
        vals = self._vals()
        if k == 'end':
            self.value = ['end']
        elif k == 'text':
            t = vals[0] if vals else ''
            if not t:
                QMessageBox.warning(self, 'Script step', 'A text id is needed')
                return
            self.value = ['text', t]
        else:
            for i, t in enumerate(vals):
                if not t:
                    QMessageBox.warning(self, 'Script step', f'Parameter {i + 1} is empty')
                    return
                if t.startswith('@') and t[1:] not in self.labels:
                    QMessageBox.warning(self, 'Script step', f'No label {t[1:]!r} in this script')
                    return
            self.value = ['op', f'0x{k:02X}'] + vals
        self.accept()


# ---------------------------------------------------------------- the tab

class CutscenesTab(QWidget):
    def __init__(self, session):
        super().__init__()
        self.s = session
        self.cat = None              # vanilla Catalogue
        self.pcat = None             # ProjectCatalogue
        self.cur = None              # SceneRef
        self.frames = {}             # scene key -> {pos: QImage}
        self._threads = []
        self._queued = None
        self._loaded = False
        self.playback = None
        v = QVBoxLayout(self)
        top = QLabel(HELP)
        top.setWordWrap(True)
        v.addWidget(top)
        split = QSplitter(Qt.Horizontal)
        v.addWidget(split, 1)
        # ---- left: the scenes
        left = QWidget()
        lv = QVBoxLayout(left)
        self.only_moves = QCheckBox('Only scenes where actors move')
        self.only_moves.setChecked(True)
        self.only_moves.toggled.connect(self.refresh)
        lv.addWidget(self.only_moves)
        self.search = QLineEdit()
        self.search.setPlaceholderText('Search (room, words of a text, a step)…')
        self.search.textChanged.connect(self.refresh)
        lv.addWidget(self.search)
        b = QPushButton('＋ New cutscene…')
        b.setToolTip('A scene of your own in one of your rooms: NPCs (named, or cast members '
                     'that appear) walk, turn, jump, talk — all in tiles, on the room itself')
        b.clicked.connect(self.new_cutscene)
        lv.addWidget(b)
        b = QPushButton('Milly hook…')
        b.setToolTip('S121: Milayou goes into the dresser and the game goes on as MILLY — the '
                     'tick, where she arrives, the Roots room (Milly) and its scene')
        b.clicked.connect(self.milly_hook)
        lv.addWidget(b)
        self.tree = QTreeWidget()
        self.tree.setHeaderHidden(True)
        self.tree.currentItemChanged.connect(self._picked)
        self.tree.itemDoubleClicked.connect(lambda *_: self.play())
        lv.addWidget(self.tree, 1)
        left.setMinimumWidth(260)
        split.addWidget(left)
        # ---- middle: the storyboard
        mid = QWidget()
        mv = QVBoxLayout(mid)
        self.head = QLabel('Pick a scene.')
        self.head.setWordWrap(True)
        self.head.setTextFormat(Qt.RichText)
        mv.addWidget(self.head)
        prow = QHBoxLayout()
        self.b_play = QPushButton('▶ Play scene')
        self.b_play.setToolTip('Play the WHOLE scene in the game, here, with sound — from what '
                               'starts it (entering the room, talking …) to its end (set up '
                               'for you; a chain plays all its scenes)')
        self.b_play.clicked.connect(self.play)
        prow.addWidget(self.b_play)
        self.b_from = QPushButton('▶ From this step')
        self.b_from.setToolTip('Play the scene from the step selected in the list: the game runs '
                               'the steps before it fast (no sound, text skipped) so everyone '
                               'stands where they should, then plays normally from that step')
        self.b_from.clicked.connect(lambda: self.play(from_step=True))
        prow.addWidget(self.b_from)
        self.b_record = QPushButton('Record frames')
        self.b_record.setToolTip('Play the scene silently in the background and keep a picture '
                                 'of every step')
        self.b_record.clicked.connect(self.record)
        prow.addWidget(self.b_record)
        prow.addWidget(QLabel('Play on:'))
        self.rom_box = QComboBox()
        prow.addWidget(self.rom_box)
        prow.addWidget(QLabel('Start from:'))
        self.start_box = QComboBox()
        self.start_box.addItems(['a new game', 'my save file…'])
        self.start_box.activated.connect(self._start_choice)
        prow.addWidget(self.start_box)
        prow.addStretch(1)
        mv.addLayout(prow)
        self.steps = QListWidget()
        f = QFont('Menlo')
        f.setStyleHint(QFont.Monospace)
        self.steps.setFont(f)
        self.steps.currentRowChanged.connect(self._step_picked)
        self.steps.itemDoubleClicked.connect(self._step_double)
        mv.addWidget(self.steps, 1)
        self.textbox = QPlainTextEdit()
        self.textbox.setReadOnly(True)
        self.textbox.setMaximumHeight(110)
        mv.addWidget(self.textbox)
        # S119 (ROADMAP P3.8 part c): a copied room's game scripts, step by step
        erow = QHBoxLayout()
        self.b_edit_op = QPushButton('Edit step…')
        self.b_edit_op.setToolTip('Change this step of your copied room\'s script (any game '
                                  'opcode, its parameters in words)')
        self.b_edit_op.clicked.connect(lambda: self.edit_op('edit'))
        self.b_ins_op = QPushButton('Insert step before…')
        self.b_ins_op.clicked.connect(lambda: self.edit_op('insert'))
        self.b_del_op = QPushButton('Delete step')
        self.b_del_op.clicked.connect(lambda: self.edit_op('delete'))
        for b in (self.b_edit_op, self.b_ins_op, self.b_del_op):
            erow.addWidget(b)
        self.op_note = QLabel('')
        self.op_note.setStyleSheet('color:#9ab;')
        erow.addWidget(self.op_note, 1)
        mv.addLayout(erow)
        self.viewer = QWidget()
        vh = QHBoxLayout(self.viewer)
        vh.setContentsMargins(0, 0, 0, 0)
        vh.addWidget(mid, 1)
        # ---- right: the picture
        right = QGroupBox('The step')
        rv = QVBoxLayout(right)
        self.pic = QLabel()
        self.pic.setFixedSize(320, 288)
        self.pic.setAlignment(Qt.AlignCenter)
        self.pic.setStyleSheet('background:#111;')
        rv.addWidget(self.pic)
        self.pic_note = QLabel('')
        self.pic_note.setWordWrap(True)
        self.pic_note.setStyleSheet('color:#aaa;')
        rv.addWidget(self.pic_note)
        rv.addStretch(1)
        vh.addWidget(right)
        # S119 (ROADMAP P3.8 part B): the cutscene editor (your own scenes)
        from editor2.app.cutscene_editor import CutsceneEditor
        self.editor = CutsceneEditor(self.s)
        self.editor.playRequested.connect(self.play_cutscene)
        self.editor.closed.connect(lambda: (self.pages.setCurrentIndex(0), self.refresh()))
        self.pages = QStackedWidget()
        self.pages.addWidget(self.viewer)
        self.pages.addWidget(self.editor)
        self.pages.currentChanged.connect(self._page_changed)
        split.addWidget(self.pages)
        split.setStretchFactor(1, 1)
        self._pending_play = None
        self.s.buildFinished.connect(self._built)
        self.s.structureChanged.connect(self._structure)
        self.s.buildFinished.connect(lambda _p: self._fill_roms())
        self._fill_roms()

    # ------------------------------------------------------------ data
    def showEvent(self, ev):
        super().showEvent(ev)
        if not self._loaded:
            self._loaded = True
            QTimer.singleShot(0, self.load)

    def _orig_rom(self):
        p = self.s.settings.value('rom/path') or os.path.join(REPO, 'data', 'DWM-original.gbc')
        return p if os.path.exists(p) else None

    def _fill_roms(self):
        keep = self.rom_box.currentData()
        self.rom_box.clear()
        if self.s.last_rom and os.path.exists(self.s.last_rom):
            self.rom_box.addItem('your last build', self.s.last_rom)
        o = self._orig_rom()
        if o:
            self.rom_box.addItem('the original game', o)
        if keep:
            i = self.rom_box.findData(keep)
            if i >= 0:
                self.rom_box.setCurrentIndex(i)

    def _start_choice(self, i):
        if i == 1:
            cur = self.s.settings.value('cutscenes/sav') or ''
            p, _ = QFileDialog.getOpenFileName(self, 'Your save file (.sav)', cur,
                                               'Game Boy saves (*.sav *.srm);;All files (*)')
            if p:
                self.s.settings.setValue('cutscenes/sav', p)
                self.start_box.setItemText(1, f'my save file ({os.path.basename(p)})')
            else:
                self.start_box.setCurrentIndex(0)

    def _sav(self):
        if self.start_box.currentIndex() == 1:
            p = self.s.settings.value('cutscenes/sav')
            return p if p and os.path.exists(p) else None
        return None

    def load(self):
        rom = self._orig_rom()
        if rom is None:
            self.head.setText('The game ROM is needed (data/DWM-original.gbc).')
            return
        self.cat = CS.Catalogue(open(rom, 'rb').read())
        self._load_project()
        self.refresh()

    def _load_project(self):
        from editor2.core.render import find_build
        syms = {}
        fb = find_build(self.s.project_dir)
        if fb:
            syms = CS.read_symbols(fb[1])
        try:
            self.pcat = CS.ProjectCatalogue(self.s.doc.data, self.s.project_dir, symbols=syms,
                                            rooms=self.cat.rooms, vanilla=self.cat)
            self.pcat_error = None
        except Exception as ex:                          # noqa: BLE001
            self.pcat, self.pcat_error = None, str(ex)

    def _match(self, ref, q):
        if not q:
            return True
        q = q.lower()
        if q in ref.title.lower():
            return True
        for st in ref.scene.steps:
            if st.code == CS.TEXT and q in (ref.cat.text(st.params[0]) or '').lower():
                return True
        return False

    def _scene_ok(self, sc):
        if not self.only_moves.isChecked():
            return True
        return CS.moves(sc)

    def refresh(self):
        if self.cat is None:
            return
        q = self.search.text().strip()
        self.tree.blockSignals(True)
        self.tree.clear()
        # S119: the project's own cutscenes (the editor)
        from editor2.core import cutscene_doc as CD
        mine = QTreeWidgetItem(['Your cutscenes (edit)'])
        self.tree.addTopLevelItem(mine)
        self._fill_mine(mine, q)
        self._fill_rest(q)

    def _fill_mine(self, mine, q):
        from editor2.core import cutscene_doc as CD
        by_room = {}
        for r, sc in CD.scenes(self.s.doc):
            if q and q.lower() not in (sc.get('name', '') + ' ' + sc['id']).lower():
                continue
            by_room.setdefault(r['id'], (r, []))[1].append(sc)
        for rid, (r, lst) in by_room.items():
            node = QTreeWidgetItem([f"{r.get('name') or rid}  ({len(lst)})"])
            for sc in lst:
                tr = (sc.get('trigger') or {}).get('on', 'entry')
                c = QTreeWidgetItem([f"{sc.get('name') or sc['id']}  · {tr}"])
                c.setData(0, ROLE, ('cutscene', rid, sc['id']))
                node.addChild(c)
                if self.editor.scene_id == sc['id']:
                    self._sel_cut = c
            mine.addChild(node)
            node.setExpanded(True)
        if not by_room:
            mine.addChild(QTreeWidgetItem(['(none yet — ＋ New cutscene…)']))
        mine.setExpanded(True)

    def _fill_rest(self, q):
        # chains
        top = QTreeWidgetItem(['Chains (scenes played one after another)'])
        self.tree.addTopLevelItem(top)
        for name, items in CS.CHAINS.items():
            it = QTreeWidgetItem([name])
            first = self._vanilla_scene(*items[0])
            if first is not None:
                it.setData(0, ROLE, SceneRef('chain', items[0][0], first, self.cat, name,
                                             chain=items))
            top.addChild(it)
        top.setExpanded(True)
        # the project
        ptop = QTreeWidgetItem(['Your rooms'])
        self.tree.addTopLevelItem(ptop)
        if self.pcat is None:
            ptop.addChild(QTreeWidgetItem([f'(the project does not compile: '
                                           f'{getattr(self, "pcat_error", "")[:80]})']))
        else:
            for mid, r in self.pcat.room_list():
                scenes = [s for s in self.pcat.scenes(mid) if self._scene_ok(s)]
                refs = [SceneRef('project', mid, s, self.pcat, self._title(self.pcat, s, mid))
                        for s in scenes]
                refs = [x for x in refs if self._match(x, q) or q.lower() in
                        str(r.get('name', '')).lower()]
                if not refs:
                    continue
                node = QTreeWidgetItem([f"${mid:02X} {r.get('name') or r.get('id')}  ({len(refs)})"])
                for ref in refs:
                    c = QTreeWidgetItem([ref.title])
                    c.setData(0, ROLE, ref)
                    node.addChild(c)
                ptop.addChild(node)
        ptop.setExpanded(True)
        # the game
        vtop = QTreeWidgetItem(['Game rooms'])
        self.tree.addTopLevelItem(vtop)
        for mid in self.cat.map_types():
            name = self.cat.rooms.name(mid)
            scenes = [s for s in self.cat.scenes(mid) if self._scene_ok(s)]
            refs = [SceneRef('vanilla', mid, s, self.cat, self._title(self.cat, s, mid))
                    for s in scenes]
            refs = [x for x in refs if self._match(x, q) or q.lower() in name.lower()]
            if not refs:
                continue
            node = QTreeWidgetItem([f'${mid:02X} {name}  ({len(refs)})'])
            for ref in refs:
                c = QTreeWidgetItem([ref.title])
                c.setData(0, ROLE, ref)
                node.addChild(c)
            vtop.addChild(node)
        vtop.setExpanded(bool(q))
        self.tree.blockSignals(False)

    def _vanilla_scene(self, mid, idx, entry):
        for s in self.cat.scenes(mid):
            if s.script.key[2] == idx and s.entry == entry:
                return s
        return None

    @staticmethod
    def _title(cat, s, mid):
        idx = s.script.key[2]
        return f'script {idx} · {cat.title(s)}'

    # ------------------------------------------------------------ showing
    def _picked(self, item, _prev=None):
        ref = item.data(0, ROLE) if item is not None else None
        if isinstance(ref, tuple) and ref and ref[0] == 'cutscene':
            self.pages.setCurrentIndex(1)
            self.editor.open(ref[1], ref[2])
            return
        if not isinstance(ref, SceneRef):
            return
        self.pages.setCurrentIndex(0)
        self.cur = ref
        self.show_scene()

    # ------------------------------------------------------------ S119: own cutscenes
    def _structure(self):
        """A project change (undo / redo / an edit): re-read the project's scenes."""
        if not self._loaded or self.cat is None:
            return
        if self.pages.currentIndex() == 1:
            # S119b (typing was ~1 s per key): while the cutscene editor is open only
            # its own list is redone; the project's compiled scenes (a whole-project
            # lowering) are re-read when the scene viewer comes back
            self._pcat_stale = True
            self._refresh_mine()
            return
        self._pcat_stale = False
        self._load_project()
        keep = self.editor.scene_id if self.pages.currentIndex() == 1 else None
        self._sel_cut = None
        self.refresh()
        if keep and getattr(self, '_sel_cut', None) is not None:
            self.tree.blockSignals(True)
            self.tree.setCurrentItem(self._sel_cut)
            self.tree.blockSignals(False)

    def _refresh_mine(self):
        top = self.tree.topLevelItem(0) if self.tree.topLevelItemCount() else None
        if top is None or not top.text(0).startswith('Your cutscenes'):
            return
        self.tree.blockSignals(True)
        top.takeChildren()
        self._sel_cut = None
        self._fill_mine(top, self.search.text().strip())
        if self._sel_cut is not None:
            self.tree.setCurrentItem(self._sel_cut)
        self.tree.blockSignals(False)

    def _page_changed(self, idx):
        if idx == 0 and getattr(self, '_pcat_stale', False):
            self._structure()

    def milly_hook(self):
        """S121: the Milly hook dialog (editor2/app/milly_dialog.py); "Edit the
        scene…" there opens the roots room's scene here."""
        from editor2.app.milly_dialog import MillyHookDialog
        dlg = MillyHookDialog(self.s, self)
        if dlg.exec() and dlg.edit_scene:
            self.open_cutscene(*dlg.edit_scene)

    def open_cutscene(self, room_id, scene_id):
        """Open one of the project's cutscenes in the cutscene editor."""
        if not self._loaded:
            self._loaded = True
            self.load()
        self.pages.setCurrentIndex(1)
        self.editor.open(room_id, scene_id)

    def new_cutscene(self):
        from editor2.core import cutscene_build as CB
        from editor2.core import cutscene_doc as CD
        from editor2.app.rooms import commands as C
        rooms = [r for r in self.s.doc.rooms if not r.get('placeholder') and r.get('screens')]
        if not rooms:
            QMessageBox.information(self, 'New cutscene', 'Make a room first (Rooms tab): a '
                                    'cutscene plays in one of your rooms (a copy of a game room '
                                    'works too).')
            return
        dlg = QDialog(self)
        dlg.setWindowTitle('New cutscene')
        f = QFormLayout(dlg)
        name = QLineEdit('New scene')
        f.addRow('Name', name)
        rb = QComboBox()
        for r in rooms:
            rb.addItem(f"{r.get('name') or r['id']} ({r['mapID']})", r['id'])
        f.addRow('Room', rb)
        sb = QComboBox()

        def fill(_i=0):
            sb.clear()
            r = self.s.doc.room(rb.currentData())
            for k in sorted(int(x) for x in r.get('screens') or {}):
                sb.addItem(f'screen {k}', k)
        rb.currentIndexChanged.connect(fill)
        fill()
        f.addRow('Screen', sb)
        tb = QComboBox()
        for k, lbl in (('entry', 'entering the room'), ('talk', 'talking to an NPC'),
                       ('examine', 'examining a tile'), ('stepon', 'stepping on a tile')):
            tb.addItem(lbl, k)
        f.addRow('Plays when', tb)
        who = QComboBox()
        who_lbl = QLabel('Talking to')

        def fill_who(_i=0):
            # every NPC of the screen: the named ones, then the ones without a
            # scene name yet (picking one names it — S119 r2, user: "Why cant I
            # select npc in a custom room when creating new cutscene?")
            who.clear()
            r = self.s.doc.room(rb.currentData())
            k = sb.currentData() or 0
            try:
                for nm, n, _e in CD.actors(r, k):
                    if n:
                        who.addItem(f'{nm} (NPC {n})', nm)
                for st, n, e in CD.unnamed_npcs(r, k):
                    x, y = CB.entry_cell(e)
                    who.addItem(f'NPC {n} at ({x}, {y})' + (f', state {st}' if st else '')
                                + ' — no name yet', CD.npc_token(st, n))
            except Exception:                            # noqa: BLE001
                pass
            if not who.count():
                who.addItem('(no NPCs on this screen — add one in the Rooms tab)', None)
            talk = tb.currentData() == 'talk'
            who.setVisible(talk)
            who_lbl.setVisible(talk)
        rb.currentIndexChanged.connect(fill_who)
        sb.currentIndexChanged.connect(fill_who)
        tb.currentIndexChanged.connect(fill_who)
        f.addRow(who_lbl, who)
        fill_who()
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(dlg.accept)
        bb.rejected.connect(dlg.reject)
        f.addRow(bb)
        if not dlg.exec():
            return
        rid, scr, on, nm = rb.currentData(), sb.currentData(), tb.currentData(), name.text().strip() or 'scene'
        actor = who.currentData() if on == 'talk' else None
        cmd = C.SnapshotCommand(self.s, 'New cutscene',
                                lambda doc: CD.new_cutscene(doc, rid, nm, scr, on, actor))
        self.s.undo.push(cmd)
        if cmd.error is not None:
            QMessageBox.warning(self, 'New cutscene', str(cmd.error))
            return
        self.pages.setCurrentIndex(1)
        self.editor.open(rid, cmd.result)
        self._structure()

    def play_cutscene(self, scene_id):
        """Save + build (when the build is older than the project), then play the
        scene in the game (the Playback window)."""
        if not scene_id:
            return
        from editor2.core import playback as PB
        ok, why = PB.available()
        if not ok:
            QMessageBox.information(self, 'Playback', why)
            return
        win = self.window()
        if self.s.dirty or not (self.s.last_rom and os.path.exists(self.s.last_rom)) or \
                self._build_stale():
            if not hasattr(win, 'build'):
                QMessageBox.information(self, 'Playback', 'Build the project first (⌘B).')
                return
            self._pending_play = scene_id
            win.build()
            return
        self._play_built(scene_id)

    def _build_stale(self):
        try:
            return os.path.getmtime(self.s.doc.path) > os.path.getmtime(self.s.last_rom)
        except OSError:
            return True

    def _built(self, rom):
        sid, self._pending_play = self._pending_play, None
        if sid and rom:
            QTimer.singleShot(200, lambda: self._play_built(sid))

    def scene_ref(self, scene_id):
        """(mid, Scene, recipe) of one of the project's cutscenes in the last build."""
        from editor2.core import cutscene_build as CB
        from editor2.core import cutscene_doc as CD
        from editor2.core.render import find_build
        self._load_project()
        r, sc = CD.find(self.s.doc, scene_id)
        mid = CS._pv(r['mapID'])
        gid = CB.trigger_script_id(r, sc)
        script = next((x for x in self.pcat.scripts(mid) if x.key[3] == gid), None)
        if script is None:
            raise RuntimeError('the scene is not in the build (does the project compile?)')
        labels = {v: k for k, v in getattr(script, 'labels', {}).items()}
        p = CB.scene_prefix(sc)
        group = [x for x in r.get('cutscenes') or [] if CB.trigger_key(x) == CB.trigger_key(sc)
                 and not x.get('disabled')]
        i = group.index(sc) if sc in group else 0
        head = labels.get(f'{p}_go')
        if head is None:
            head = 0 if i == 0 else labels.get(f'{CB.scene_prefix(group[i - 1])}_skip', 0)
        scene = CS.Scene(script, head, script.run_from(head, stop_at_heads=False),
                         script.path_to(head), sc.get('name', ''), None, 1)
        rec = self.pcat.recipe(scene, mid)
        ps = sc.get('player_start')
        if (sc.get('trigger') or {}).get('on', 'entry') == 'entry' and isinstance(ps, dict):
            rec = rec._replace(player=CB.cell_px(int(sc.get('screen', 0)), int(ps['x']), int(ps['y'])),
                               screen=int(sc.get('screen', 0)))
        return mid, scene, rec

    def _play_built(self, scene_id):
        try:
            mid, scene, rec = self.scene_ref(scene_id)
        except Exception as ex:                          # noqa: BLE001
            QMessageBox.warning(self, 'Playback', f'Cannot play it: {ex}')
            return
        if self.playback is not None:
            try:
                self.playback.close()
            except RuntimeError:
                pass
        title = scene.title or scene_id
        self.playback = PlaybackWindow(self, self.s.last_rom, self._sav(), self._cache_dir(),
                                       [(rec, scene, title[:60])], title[:60])
        self.playback.show()

    # ------------------------------------------------------------ S119 part c: op editing
    def _op_target(self):
        """(script dict, op index) of the selected storyboard step when it is a step
        of one of the project's own op scripts (a copied room's script), else None."""
        if self.cur is None or self.cur.kind != 'project':
            return None
        key = self.cur.scene.script.key
        sid = key[3] if len(key) > 3 else None
        if not sid or str(sid).startswith(('cut:', 'skill:', 'quest:', 'entry:')):
            return None
        sc = next((x for x in self.s.doc.custom.get('scripts', []) if x.get('id') == sid), None)
        if sc is None or 'ops' not in sc or any(k in sc for k in ('talk', 'shop')):
            return None
        row = self.steps.currentRow()
        if row < 0:
            return None
        pos = self.cur.scene.steps[row].pos
        w = 0
        for i, it in enumerate(sc['ops']):
            if isinstance(it, str):
                continue
            if w == pos:
                return sc, i
            w += 1 if it[0] in ('end', 'text') else 1 + len(it) - 2
        return None

    def _op_buttons(self):
        t = self._op_target()
        for b in (self.b_edit_op, self.b_ins_op, self.b_del_op):
            b.setEnabled(t is not None)
        self.op_note.setText('' if t is not None else
                             ('your own cutscenes are edited in the cutscene editor'
                              if self.cur is not None and self.cur.kind == 'project' else
                              'game scenes: copy the room (Rooms → Make editable) to change them'))

    def edit_op(self, what):
        from editor2.app.rooms import commands as C
        t = self._op_target()
        if t is None:
            return
        sc, i = t
        sid = sc['id']
        if what == 'delete':
            if QMessageBox.question(self, 'Delete step', 'Delete this step of the script?') \
                    != QMessageBox.Yes:
                return

            def op(doc):
                s2 = next(x for x in doc.custom['scripts'] if x.get('id') == sid)
                s2['ops'].pop(i)
                doc.touch()
            self.s.undo.push(C.SnapshotCommand(self.s, 'Script: delete a step', op))
            return
        cur = sc['ops'][i] if what == 'edit' else None
        labels = [x.split(':', 1)[1] for x in sc['ops'] if isinstance(x, str) and x.startswith('label:')]
        dlg = OpDialog(self, cur, labels)
        if not dlg.exec():
            return
        new = dlg.value

        def op2(doc):
            s2 = next(x for x in doc.custom['scripts'] if x.get('id') == sid)
            if what == 'edit':
                s2['ops'][i] = new
            else:
                s2['ops'].insert(i, new)
            doc.touch()
        self.s.undo.push(C.SnapshotCommand(self.s, 'Script: edit a step', op2))

    def recipe_of(self, ref, scene=None):
        scene = scene or ref.scene
        if ref.kind == 'project':
            return ref.cat.recipe(scene, ref.mid)
        return self.cat.recipe(scene, ref.mid)

    def show_scene(self):
        ref = self.cur
        sc = ref.scene
        r = self.recipe_of(ref)
        room = (self.cat.rooms.name(ref.mid) if ref.kind != 'project'
                else (self.pcat.room(ref.mid) or {}).get('name', f'${ref.mid:02X}'))
        cond = []
        for lit in sc.path or []:
            cond.append(self._lit_text(lit))
        head = [f'<b>{ref.title}</b>',
                f'Room ${ref.mid:02X} {room} · script {sc.script.key[2]} · starts by '
                f'{TRIGGER_WORDS.get(r.action, r.action)} · screen {r.screen}'
                + (f' · room state {r.room_step}' if r.room_step else ''),
                'Plays when: ' + ('; '.join(cond) if cond else 'always (its script\'s first branch)')]
        if ref.kind != 'project' or ref.mid < 0x6B:
            org, more = self.cat.room_origin(ref.mid)
            if org:
                head.append('<span style="color:#9ab">In the game this room is entered from: '
                            + '; '.join(org) + (f' (+{more} more)' if more else '')
                            + ' — the room names are the editor\'s labels</span>')
        if r.notes:
            head.append('<span style="color:#e8b060">' + ' · '.join(r.notes) + '</span>')
        if ref.chain:
            head.append('Chain: ' + ' → '.join(f'${m:02X} script {i}' for m, i, _e in ref.chain))
        self.head.setText('<br>'.join(head))
        # the steps
        acts = self._actors(ref, r)
        labels = {}
        for s2 in (ref.cat.scenes(ref.mid) if ref.kind != 'chain' else self.cat.scenes(ref.mid)):
            if s2.script is sc.script:
                labels[s2.entry] = f'the scene at step {s2.entry}'
        ctx = TextCtx(ref.cat.text, acts, labels, cat=ref.cat,
                      vanilla=self.cat)
        if ref.kind != 'project':
            ctx.bank = CS.script_bank(ref.mid)
        self.steps.blockSignals(True)
        self.steps.clear()
        for st in sc.steps:
            kind = 'text' if st.code == CS.TEXT else ('flow' if st.code == CS.END
                                                       else SO.OPS[st.code].kind)
            it = QListWidgetItem(f'{st.pos:>5}  {SO.sentence(st.code, st.params, ctx, st.target)}')
            it.setForeground(KIND_COLOUR.get(kind, QColor(220, 220, 220)))
            it.setData(ROLE, st.pos)
            if st.code < 0x100:
                it.setToolTip(SO.OPS[st.code].doc + f'\n(opcode ${st.code:02X}: '
                              f'{SO.OPS[st.code].name})')
            self.steps.addItem(it)
        self.steps.blockSignals(False)
        self._ctx = ctx
        self._model = CS.actor_frames(acts, sc.steps)
        self._recipe = r
        self.steps.setCurrentRow(0)
        self._step_picked(0)
        key = self._key(ref)
        if key not in self.frames and self._auto_record():
            self.record()

    def _lit_text(self, lit):
        if lit[0] == 'flag':
            return f'flag ${lit[1]:04X} {"set" if lit[2] else "clear"}'
        if lit[0] == 'screen':
            return f'screen {"=" if lit[2] else "≠"} {lit[1]}'
        if lit[0] == 'ram':
            return f'${lit[1]:04X} {"=" if lit[3] else "≠"} {lit[2]}'
        return ('' if lit[2] else 'not: ') + lit[1]

    def _actors(self, ref, r):
        if ref.kind == 'project':
            npcs = self.pcat.npcs(ref.mid, r.screen, r.room_step)
        else:
            npcs = self.cat.rooms.npcs(ref.mid, r.screen, r.room_step)
        # S118g: an NPC is named by the speaker of its OWN talk script (the
        # game's dialogue), never by a hand-made sprite table
        cat = self.pcat if ref.kind == 'project' else self.cat
        try:
            by_idx = {s.key[2]: s for s in cat.scripts(ref.mid) if s is not None}
        except Exception:                                # noqa: BLE001
            by_idx = {}
        named = []
        # S124 r3: YOUR names first (an NPC's actor name / custom._editor.npc_names)
        from editor2.core import npc_names as NN
        custom = (self.s.doc.data.get('custom') if getattr(self.s, 'doc', None) else None) or {}
        for i, n in enumerate(npcs, 1):
            sid = n.get('script')
            user = (n.get('actor') if ref.kind == 'project'
                    else NN.name_of(custom, ref.mid, r.screen, r.room_step, i))
            spk = user or (CS.script_speaker(by_idx.get(sid), ref.cat.text)
                           if isinstance(sid, int) and sid != 0xFF else None)
            named.append(dict(n, speaker=spk))
        return CS.initial_actors(named, r.screen, r.player, r.facing, {})

    def _step_picked(self, row):
        if row < 0 or self.cur is None:
            return
        self._op_buttons()
        st = self.cur.scene.steps[row]
        if st.code == CS.TEXT:
            self.textbox.setPlainText(self.cur.cat.text(st.params[0]) or '(text not found)')
        elif st.code < 0x100:
            self.textbox.setPlainText(SO.OPS[st.code].doc)
        else:
            self.textbox.setPlainText('The script ends; the player has control again.')
        self._show_picture(row)

    def _step_double(self, item):
        """A branch step: jump to the scene it goes to."""
        if self.cur is None:
            return
        st = self.cur.scene.steps[self.steps.row(item)]
        if st.target is None:
            return
        for s2 in self.cur.cat.scenes(self.cur.mid):
            if s2.script is self.cur.scene.script and s2.entry == st.target:
                self.cur = SceneRef(self.cur.kind, self.cur.mid, s2, self.cur.cat,
                                    self._title(self.cur.cat, s2, self.cur.mid))
                self.show_scene()
                return

    def _key(self, ref):
        sc = ref.scene
        return (ref.kind, ref.mid, sc.script.key[2], sc.entry, self.rom_box.currentData(),
                self._sav())

    def _show_picture(self, row):
        ref = self.cur
        frames = self.frames.get(self._key(ref))
        if isinstance(frames, dict) and frames:
            img = None
            for k in range(row, -1, -1):
                img = frames.get(ref.scene.steps[k].pos)
                if img is not None:
                    break
            if img is None:
                img = next(iter(frames.values()))
            self.pic.setPixmap(QPixmap.fromImage(img).scaled(320, 288))
            self.pic_note.setText('Recorded from the game: the frame in which the game ran this '
                                  'step (a walk or a wait: the frame it finished). Use the arrow '
                                  'keys in the list to step through.')
            return
        self.pic.setPixmap(self._model_picture(row))
        note = 'The room, with the actors where the scene puts them (the model).'
        if frames == 'busy':
            note += ' Recording the game frames…'
        elif isinstance(frames, str):
            note += f' (recording failed: {frames})'
        self.pic_note.setText(note)

    def _model_picture(self, row):
        r = self._recipe
        try:
            if self.cur.kind == 'project':
                room = self.s.doc.room_by_mid(r.map) if hasattr(self.s.doc, 'room_by_mid') else None
                if room is None:
                    room = next(x for x in self.s.doc.custom.get('rooms', [])
                                if CS._pv(x.get('mapID')) == r.map)
                im = self.s.renderer.render_screen(room, str(r.screen), r.room_step)
            else:
                im = self.s.renderer.render_vanilla_screen(r.map, r.screen, 1, r.room_step)
            base = QPixmap.fromImage(_pil_to_qimage(im))
        except Exception:                                # noqa: BLE001
            base = QPixmap(160, 128)
            base.fill(QColor(40, 40, 40))
        pm = QPixmap(160, 144)
        pm.fill(QColor(0, 0, 0))
        p = QPainter(pm)
        p.drawPixmap(0, 0, base)
        acts = self._model[row][1] if row < len(self._model) else {}
        col, rr = r.screen % 4, r.screen // 4
        for n, a in sorted(acts.items()):
            x, y = a.x - col * 160 - 8, a.y - rr * 128 - 8
            if not (-16 < x < 176 and -16 < y < 160):
                continue
            p.setOpacity(1.0 if a.shown else 0.3)
            spr = a.sprite if n else 0x08
            path = os.path.join(SPRITE_DIR, f'id_{spr:02X}.png') if spr is not None else ''
            if path and os.path.exists(path):
                p.drawPixmap(x, y, QPixmap(path))
            else:
                p.fillRect(x + 2, y + 2, 12, 12, QColor(200, 80, 80))
            p.setOpacity(1.0)
            p.setPen(QPen(QColor(255, 255, 0)))
            dx, dy = {0: (8, 16), 1: (0, 8), 2: (8, 0), 3: (16, 8)}[a.face & 3]
            p.drawEllipse(x + dx - 1, y + dy - 1, 3, 3)
            p.drawText(x, y, str(n))
        p.end()
        return pm.scaled(320, 288)

    # ------------------------------------------------------------ record / play
    def _auto_record(self):
        from editor2.core import playback as PB
        return PB.available()[0] and self.rom_box.currentData() is not None

    def _cache_dir(self):
        d = os.path.join(self.s.project_dir, 'build', 'playback')
        os.makedirs(d, exist_ok=True)
        return d

    def _rom_for(self, ref):
        rom = self.rom_box.currentData()
        if ref.kind == 'project':
            if not (self.s.last_rom and os.path.exists(self.s.last_rom)):
                return None
            return self.s.last_rom
        return rom

    def record(self):
        ref = self.cur
        if ref is None:
            return
        rom = self._rom_for(ref)
        if rom is None:
            self.pic_note.setText('Build the project first (⌘B) to play your rooms.')
            return
        key = self._key(ref)
        if self.frames.get(key) == 'busy':
            return
        if self._threads:                    # one recording at a time: the latest waits
            self._queued = ref
            return
        self.frames[key] = 'busy'
        th = QThread(self)
        rec = Recorder(key, rom, self._sav(), self._cache_dir(), self._recipe, ref.scene)
        rec.moveToThread(th)
        th.started.connect(rec.run)
        rec.done.connect(self._recorded)
        rec.failed.connect(self._record_failed)
        rec.done.connect(th.quit)
        rec.failed.connect(th.quit)
        th.finished.connect(lambda: self._record_finished(th, rec))
        self._threads.append((th, rec))
        th.start()
        self._show_picture(max(0, self.steps.currentRow()))

    def _record_finished(self, th, rec):
        if (th, rec) in self._threads:
            self._threads.remove((th, rec))
        th.deleteLater()
        q, self._queued = self._queued, None
        if q is not None and q is self.cur:
            self.record()

    def _recorded(self, key, frames):
        self.frames[key] = frames
        if self.cur is not None and self._key(self.cur) == key:
            self._show_picture(max(0, self.steps.currentRow()))

    def _record_failed(self, key, msg):
        self.frames[key] = msg
        if self.cur is not None and self._key(self.cur) == key:
            self._show_picture(max(0, self.steps.currentRow()))

    def play(self, from_step=False):
        ref = self.cur
        if ref is None:
            return
        skip_to = None
        if from_step:
            row = self.steps.currentRow()
            steps = ref.scene.steps
            if 0 < row < len(steps):
                skip_to = steps[row].pos
        rom = self._rom_for(ref)
        if rom is None:
            QMessageBox.information(self, 'Playback', 'Build the project first (⌘B / Ctrl+B) — '
                                    'your rooms play from your build.')
            return
        from editor2.core import playback as PB
        ok, why = PB.available()
        if not ok:
            QMessageBox.information(self, 'Playback', why)
            return
        items = []
        if ref.chain:
            for (m, i, e) in ref.chain:
                s2 = self._vanilla_scene(m, i, e)
                if s2 is not None:
                    items.append((self.cat.recipe(s2, m), s2,
                                  f'${m:02X} script {i}: {self.cat.title(s2)[:40]}'))
        else:
            items.append((self._recipe, ref.scene, ref.title[:60]))
        if self.playback is not None:
            try:
                self.playback.close()
            except RuntimeError:
                pass
        self.playback = PlaybackWindow(self, rom, self._sav(), self._cache_dir(), items,
                                       ref.title[:60], skip_to=skip_to)
        self.playback.position.connect(self._follow)
        self.playback.show()

    def _follow(self, typ, script, pos):
        """Highlight the step the game is on."""
        if self.cur is None:
            return
        r = self._recipe
        if (typ, script) != (r.script_type & 0xFF, r.script_idx):
            return
        st = CS.step_at_counter(self.cur.scene.script, pos)
        if st is None:
            return
        for i in range(self.steps.count()):
            if self.steps.item(i).data(ROLE) == st.pos:
                if self.steps.currentRow() != i:
                    self.steps.setCurrentRow(i)
                break

    def apply_mute(self):
        if self.playback is not None:
            try:
                self.playback.apply_mute()
            except RuntimeError:
                pass

    def shutdown(self):
        self._queued = None
        for th, rec in list(self._threads):
            rec.cancel = True
            if rec.client is not None:
                rec.client.kill()
            th.quit()
            th.wait(10000)
        if self.playback is not None:
            try:
                self.playback.close()
            except RuntimeError:
                pass
