"""playback.py — play any script scene in the real game, headless (S118, ROADMAP
P3.8 part A). No Qt: the Cutscenes tab's Playback window drives it, and so does
tools/census_cutscenes.py.

The game itself runs (PyBoy, `pip install pyboy`), so every effect is exact:
walks, programs, text boxes, screen effects, music, room changes. The author
never walks to a scene: the engine starts from a cached base state and SETS IT
UP (cutscenes.Recipe):

  1. base state: a NEW GAME (title -> new game -> the bedroom, the intro script
     stopped) or the author's own .sav (CONTINUE) — one per ROM, cached in
     cache_dir (PYBOY_DEBUGGING: savestates never travel between builds);
  2. stop any script, set the scene's event flags / RAM (path conditions, the
     room-state counter), warp with the exit handler's own mailbox
     ($C96D map, $C96F-$C972 pixels, $C96C = 1, $C88F = 1) — the harness warp;
  3. room-entry scenes (script 0) start by themselves on arrival; other
     scripts are armed the way S73's field-cast skills are: $D8D3 = map type,
     $D8D4 = script, counter $FFFF (the per-frame ticker pre-increments), $D8D7
     = 1, plus dialog mode for talks (init_dialog's own writes);
  4. if the script ends without reaching the scene (a condition the recipe
     could not set — a party check, a full bag …) the scene is started at its
     own first step instead (`forced`).

While it runs: `auto_text` presses A on every text box once it is fully
printed and has been shown `text_pause` frames (the text pointer $C82D/$C82E
stops moving — PyBoy S118), answering YES/NO with `answer`; `auto_dpad`
presses right when the script waits for the D-pad (opcode $4C); `buttons`
are the author's own presses (manual mode). `where()` gives the live script
position ($D8D3/$D8D4/$D8D5) for the storyboard highlight.
"""

import hashlib
import os
import shutil
import tempfile

MAP_ID, SCREEN_IDX, GAME_MODE = 0xC968, 0xC925, 0xC88A
GAME_STATE = 0xC8EB
SCRIPT_TYPE, SCRIPT_ID, SCRIPT_CTR, SCRIPT_FLAGS, SCRIPT_FLAGS2 = 0xD8D3, 0xD8D4, 0xD8D5, 0xD8D7, 0xD8D8
TEXT_PTR = 0xC82D
FLAG_BASE = 0xD99B
W_CHANGING, W_DEST, W_FLAG = 0xC96C, 0xC96D, 0xC96E
W_X, W_Y, W_KICK = 0xC96F, 0xC971, 0xC88F
YESNO_CURSOR = 0xC83C


def available():
    try:
        import pyboy  # noqa: F401
        return True, ''
    except Exception as ex:                       # noqa: BLE001
        return False, f'Playback needs PyBoy:  pip install pyboy   ({ex})'


def md5(path):
    h = hashlib.md5()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


class Engine:
    TEXT_PAUSE = 75           # frames a fully printed box stays before auto A
    DPAD_BUTTON = 'right'

    def __init__(self, rom_path, cache_dir=None, sav_path=None, sound=True, rom_bytes=None):
        from pyboy import PyBoy
        self.cache_dir = cache_dir or os.path.join(tempfile.gettempdir(), 'dwm_playback')
        os.makedirs(self.cache_dir, exist_ok=True)
        self.rom_md5 = md5(rom_path)
        self.sav_md5 = md5(sav_path) if sav_path else None
        tag = self.rom_md5[:12] + ('_' + self.sav_md5[:8] if sav_path else '')
        # a private copy: PyBoy reads/writes <rom>.ram next to the ROM
        self.rom_copy = os.path.join(self.cache_dir, f'rom_{tag}.gbc')
        if not os.path.exists(self.rom_copy):
            shutil.copy(rom_path, self.rom_copy)
        ram = self.rom_copy + '.ram'
        if sav_path:
            data = open(sav_path, 'rb').read()
            data = data + b'\x00' * max(0, 32 * 1024 - len(data))
            open(ram, 'wb').write(data)
        elif os.path.exists(ram):
            os.remove(ram)
        self.rom = rom_bytes if rom_bytes is not None else open(rom_path, 'rb').read()
        self.sav = bool(sav_path)
        # a state saved without sound emulation plays back SILENT in an emulator
        # with sound (measured S118, PyBoy 2.x) — one start state per sound mode
        self.state_path = os.path.join(self.cache_dir,
                                       f'base_{tag}{"_snd" if sound else ""}.state')
        self.newgame_path = os.path.join(self.cache_dir,
                                         f'newgame_{tag}{"_snd" if sound else ""}.state')
        self.sound = sound
        self._power_on()
        # behaviour
        self.auto_text = True
        self.text_pause = self.TEXT_PAUSE
        self.answer = 'no'                 # YES/NO: what auto mode answers
        self.auto_dpad = True
        self.buttons = set()               # manual presses
        # run state
        self.frames = 0
        self.ended = False
        self.started = False
        self.reached = False
        self.forced = False
        self.reset = False
        self.log = []
        self._held = set()
        self._ptr, self._ptr_still = None, 0
        self._auto_phase = 0
        self._scene = None
        self._script_ptrs = {}
        self.watchers = []                 # cb(engine) after every emulated frame
        self.deadline = None               # time.monotonic() limit (census), else None

    def _power_on(self):
        """A fresh emulator (power-on state of the cartridge)."""
        from pyboy import PyBoy
        old = getattr(self, 'p', None)
        if old is not None:
            try:
                old.stop(save=False)
            except Exception:                            # noqa: BLE001
                pass
        self.p = PyBoy(self.rom_copy, window='null', cgb=True, sound_emulated=self.sound,
                       sound_sample_rate=32768, log_level='ERROR')
        self.p.set_emulation_speed(0)
        self.m = self.p.memory

    MARK_SCRIPT_ACTIVE = (0x04, 0x5613)   # every op / text is dispatched here

    def trace_ops(self):
        """Log every script word the VM dispatches: self.executed gets
        (type, script, pos) — a code hook (it perturbs input timing slightly:
        PYBOY_DEBUGGING S80; the census only, never the Playback window)."""
        self.executed = []
        m = self.m

        def cb(_ctx):
            ctr = m[SCRIPT_CTR] | (m[SCRIPT_CTR + 1] << 8)
            self.executed.append((m[SCRIPT_TYPE], m[SCRIPT_ID],
                                  ctr if ctr < 0x8000 else ctr - 0x10000))
        self.p.hook_register(*self.MARK_SCRIPT_ACTIVE, cb, None)

    # ------------------------------------------------------------ basics
    def tick(self, n=1):
        for _ in range(n):
            self.p.tick()
            for cb in self.watchers:
                cb(self)
            if self.deadline is not None:
                import time
                if time.monotonic() > self.deadline:
                    raise TimeoutError('the scene ran past its time limit')

    def tap(self, btn, hold=3, wait=12):
        self.p.button_press(btn)
        self.tick(hold)
        self.p.button_release(btn)
        self.tick(wait)

    def screen(self):
        return self.p.screen.ndarray

    def audio(self):
        """The last frame's samples as int16 (n, 2)."""
        import numpy as np
        a = self.p.sound.ndarray
        return (a.astype(np.int16) * 256) if len(a) else np.zeros((0, 2), np.int16)

    def flag(self, idx):
        return (self.m[FLAG_BASE + (idx >> 3)] >> (7 - (idx & 7))) & 1

    def set_flag(self, idx, on=True):
        a, bit = FLAG_BASE + (idx >> 3), 1 << (7 - (idx & 7))
        self.m[a] = (self.m[a] | bit) if on else (self.m[a] & ~bit & 0xFF)

    # ------------------------------------------------------------ base state
    def base_state(self, progress=None):
        """Load (or make and cache) the base state. Returns True when it was
        made now."""
        if os.path.exists(self.state_path):
            with open(self.state_path, 'rb') as f:
                self.p.load_state(f)
            return False
        if progress:
            progress('Starting the game once for this build (a few seconds)…')
        if self.sav:
            self._continue_save()
        else:
            self._new_game()
        self._stop_scripts()
        self.tick(30)
        with open(self.state_path, 'wb') as f:
            self.p.save_state(f)
        return True

    def _new_game(self, keep_intro=True):
        self.tick(280)
        self.tap('start')
        self.tick(40)
        for _ in range(120):
            self.tap('a', wait=8)
            if self.m[MAP_ID] == 0x2F:
                if keep_intro:
                    # S118e: the game AS A NEW GAME STARTS — the bedtime scene
                    # plays from here exactly as in the game (user: "Milayou and
                    # Terry … both are in wrong positions")
                    with open(self.newgame_path, 'wb') as f:
                        self.p.save_state(f)
                self.tick(120)
                return
        raise RuntimeError('the new game did not reach the bedroom')

    def newgame_state(self):
        """Load the cached state of a new game at the moment the bedroom loads
        (made with the base state; a .sav start has none). True if loaded."""
        if self.sav:
            return False
        if not os.path.exists(self.newgame_path):
            # made from POWER-ON (an older cache has only the base state)
            traced = hasattr(self, 'executed')
            self._power_on()
            self._new_game()
            if traced:                               # the hook went with the old emulator
                self.trace_ops()
        if not os.path.exists(self.newgame_path):
            return False
        with open(self.newgame_path, 'rb') as f:
            self.p.load_state(f)
        return True

    def _continue_save(self):
        self.tick(400)
        self.tap('start')
        self.tick(120)
        self.tap('a')
        self.tick(120)
        self.tap('a')
        self.tick(200)
        self.tap('a')
        for _ in range(200):
            if self.m[GAME_MODE] == 1 and self.m[GAME_STATE] == 0:
                break
            self.tap('a', wait=10)
        for _ in range(20):
            if self.m[GAME_STATE] == 0:
                break
            self.tap('b', wait=10)
        if self.m[GAME_MODE] != 1:
            raise RuntimeError('CONTINUE from the save did not reach the field')

    def _stop_scripts(self):
        m = self.m
        m[SCRIPT_FLAGS] = 0
        m[SCRIPT_FLAGS2] = 0
        for a in range(0xD8E9, 0xD929):
            m[a] = 0
        m[GAME_STATE] = 0
        m[0xC915] = 0
        m[0xC825] = 0

    # ------------------------------------------------------------ set-up
    # the EID-1 starter as the real engine grant builds it (pyboy_harness)
    STARTER = bytes.fromhex(
        '023649463ff0f0f0f0080000d3d4d5d60000000033ffff'
        '646464f0f0f0f0f000646464f0f0f0f0f000e109ffffffffffff'
        '036673ffffffffffffffffffffffffffffffffffffffffffff'
        '0001270000001b001b0062006200080005000500000005000000'
        '5ec6b15b000000000000020202020202020202020000000000'
        '00000000006464' '64f0f0f0f0f000646464f0f0f0f0f000')

    def give_party(self):
        """A battle-valid party monster in slot 0 when the party is empty (a
        new game has none; scenes with battles need one). After the warp — the
        canonicalizer erases a half-made party on room loads (S70)."""
        m = self.m
        if m[0xCA8D]:
            return False
        for i, b in enumerate(self.STARTER[:149]):
            m[0xCAC1 + i] = b
        m[0xCA8D] = 1
        m[0xCA8E], m[0xCA8F], m[0xCA90] = 0, 0xFF, 0xFF
        return True

    def start(self, recipe, scene_entry=None, wait=900, settle=True, party=False):
        """Set the game up for a recipe (cutscenes.Recipe) and leave it
        running at the start of the scene's script."""
        m = self.m
        self.base_state()
        self.frames = 0
        self.ended = self.started = self.reached = self.forced = self.reset = False
        self._await_start = False
        self.log = []
        self._scene = recipe
        self._scene_entry = recipe.start_pos if scene_entry is None else scene_entry
        if recipe.action == 'newgame':
            if self.newgame_state():
                self._await_start = True          # "started" once the script runs
                self.log.append('a new game, exactly as it starts (the bedtime scene plays '
                                'by itself)')
                return
            recipe = recipe._replace(action='entry')
            self._scene = recipe
            self.log.append('(started from a save: the new-game opening is set up instead)')
        self._stop_scripts()
        for f in recipe.flags_set:
            self.set_flag(f, True)
        for f in recipe.flags_clear:
            self.set_flag(f, False)
        for a, v in recipe.ram.items():
            m[a] = v & 0xFF
        px, py = recipe.player
        m[W_DEST] = recipe.map & 0xFF
        m[W_FLAG] = 0
        m[W_X], m[W_X + 1] = px & 0xFF, (px >> 8) & 0xFF
        m[W_Y], m[W_Y + 1] = py & 0xFF, (py >> 8) & 0xFF
        m[W_CHANGING] = 1
        m[W_KICK] = 1
        # wait for the room (the entry script may start on its own)
        arrived = False
        for i in range(wait):
            self.tick()
            if (m[MAP_ID] == recipe.map & 0xFF and m[GAME_MODE] == 1
                    and m[W_KICK] == 0 and m[W_CHANGING] == 0):
                arrived = True
                break
        if not arrived:
            self.log.append('the room did not finish loading')
        for a, v in recipe.ram.items():          # the load may reset counters
            m[a] = v & 0xFF
        if party and self.give_party():
            self.log.append('gave the party a monster (a new game has none)')
        self._hero_name()
        self._name_slots(recipe.names or ())
        if recipe.action == 'head':
            self._settle()
            self.force_scene()
            self.log[-1] = (f'started at the scene\'s own first step (pos {self._scene_entry}): '
                            'it plays after a battle is won')
            return
        if recipe.action == 'entry':
            for i in range(30):
                if m[SCRIPT_FLAGS] & 1:
                    break
                self.tick()
            if m[SCRIPT_FLAGS] & 1 and m[SCRIPT_ID] == 0:
                self.started = True
                self.log.append('the room-entry script started on arrival')
                return
            self._arm(recipe.script_type, 0, -1, dialog=False)
            self.log.append('room-entry script armed')
            return
        if recipe.action == 'walkin':
            # the neighbour screen's own entry scene (the bedroom plays bedtime
            # whenever its flags are clear) is stopped as soon as the room is in:
            # the player is only passing through it, as in the game
            for _ in range(300):
                if m[0xC850] == 0:
                    break
                self.tick()
            self._stop_scripts()
            m[0xFF90] = m[0xFF90] & ~0x40 & 0xFF          # the player shown
            self.tick(8)
            for k, (sx, sy, face) in enumerate(recipe.stands):
                if self._walk_in(recipe, sx, sy, face):
                    self.log.append(f'walked in from screen {recipe.screen} (edge cell {k + 1})')
                    return
            self.log.append('could not walk in: the room-entry script armed directly')
            self._arm(recipe.script_type, 0, -1, dialog=False)
            return
        # another script: let the room's entry script finish first
        self._settle()
        if recipe.action in ('talk', 'examine', 'stepon') and recipe.stands:
            for k, (sx, sy, face) in enumerate(recipe.stands):
                if self._interact(recipe, sx, sy, face):
                    self.log.append(f'started by {recipe.action} from side {k + 1}')
                    return
            self.log.append(f'{recipe.action} did not start the script: armed directly')
        self._arm(recipe.script_type, recipe.script_idx, -1, dialog=recipe.dialog)

    HERO_NAME = 0xCA42        # text code $F6 [HERO] prints these 8 bytes (bank $56)

    def _hero_name(self):
        """A new game holds the placeholder $D3 $D4 $D5 $D6 $00… until the Castle's
        naming screen ($04 15 on $C8F2 = $CA42) — texts then print "TERRY0000"
        (user S118f). Put in TERRY the way the naming screen leaves a name."""
        m = self.m
        if self.sav or [m[self.HERO_NAME + i] for i in range(4)] != [0xD3, 0xD4, 0xD5, 0xD6]:
            return
        from .monster_text import encode_name
        name = encode_name('TERRY', 'hero') + b'\xF0' * 3
        for i, b in enumerate(name[:8]):
            m[self.HERO_NAME + i] = b

    INSERT_SLOTS = 0xC180     # text code $F9 nn inserts the name at $C180 + nn (bank $56)

    def _name_slots(self, slots):
        """Text code `$F9 nn` prints the name at $C180 + nn ($00 / $10 / $20 /
        $30, 16 B each) — filled by the game's own code (the egg appraiser,
        a join) right before such a text. A scene started from a synthetic
        state can reach the text with the slot never filled: the text engine
        then runs on through RAM and the game crashes (measured S118: the
        Starry Shrine's egg scenes). Each slot the scene prints that has no
        end mark gets a placeholder name — ONLY those: the slots double as
        other buffers (filling all four crashed the Castle, S118)."""
        from .monster_text import encode_name
        m = self.m
        name = encode_name('Slime', 'placeholder') + b'\xF0'
        n = 0
        for k in slots:
            a = self.INSERT_SLOTS + (k & 0x30)
            if 0xF0 not in [m[a + i] for i in range(16)]:
                for i, b in enumerate(name):
                    m[a + i] = b
                n += 1
        if n:
            self.log.append(f'{n} inserted name(s) had no data: "Slime" put in')

    def _settle(self, n=1200):
        m = self.m
        for i in range(n):
            if not (m[SCRIPT_FLAGS] & 1) and m[GAME_STATE] in (0, 4) and m[0xC850] == 0:
                self.tick(8)
                return
            self._auto(i)
            self.tick()

    FACE_HRAM = {0: (0x00, 0x00), 1: (0x20, 0x01), 2: (0x00, 0x02), 3: (0x00, 0x01)}
    FACE_BUTTON = {0: 'down', 1: 'left', 2: 'up', 3: 'right'}

    def _place(self, px, py, face):
        m = self.m
        m[0xFF92], m[0xFF93] = px & 0xFF, (px >> 8) & 0xFF
        m[0xFF95], m[0xFF96] = py & 0xFF, (py >> 8) & 0xFF
        m[0xFF97], m[0xFF98] = px >> 4, py >> 4
        m[0xFF8E] = face
        m[0xFF8D], m[0xFF8F] = self.FACE_HRAM[face]

    def _interact(self, recipe, sx, sy, face):
        """Trigger the script the way the player does; True when it ran."""
        m = self.m
        state = None
        import io
        buf = io.BytesIO()
        self.p.save_state(buf)
        if recipe.action == 'stepon':
            # stand on the side cell, then walk onto the spot
            back = {0: 2, 1: 3, 2: 0, 3: 1}[face]
            self._place(sx, sy, face)
            self.tick(4)
            btn = self.FACE_BUTTON[face]
            self.p.button_press(btn)
            for i in range(40):
                self.tick()
                if m[SCRIPT_FLAGS] & 1 and m[SCRIPT_ID] == recipe.script_idx:
                    break
            self.p.button_release(btn)
        else:
            self._place(sx, sy, face)
            self.tick(4)
            self.p.button_press('a')
            self.tick(4)
            self.p.button_release('a')
            for i in range(40):
                if m[SCRIPT_FLAGS] & 1:
                    break
                self.tick()
        if m[SCRIPT_FLAGS] & 1 and m[SCRIPT_ID] == recipe.script_idx:
            self.started = True
            return True
        buf.seek(0)
        self.p.load_state(buf)
        return False

    def _walk_in(self, recipe, sx, sy, face):
        """Stand at an edge cell of the neighbouring screen and walk onto the
        scene's screen; True when the room-entry script runs there."""
        import io
        m = self.m
        buf = io.BytesIO()
        self.p.save_state(buf)
        self._place(sx, sy, face)
        self.tick(4)
        btn = self.FACE_BUTTON[face]
        self.p.button_press(btn)
        ok = False
        for _ in range(90):
            self.tick()
            if m[SCREEN_IDX] == recipe.target:
                break
        self.p.button_release(btn)
        if m[SCREEN_IDX] == recipe.target:
            for _ in range(90):
                if m[SCRIPT_FLAGS] & 1 and m[SCRIPT_ID] == 0:
                    ok = True
                    break
                self.tick()
        if ok:
            self.started = True
            return True
        buf.seek(0)
        self.p.load_state(buf)
        return False

    def _arm(self, map_type, idx, pos, dialog):
        m = self.m
        self._stop_scripts()
        ctr = (pos - 1) & 0xFFFF if pos >= 0 else 0xFFFF
        m[SCRIPT_TYPE] = map_type & 0xFF
        m[SCRIPT_ID] = idx & 0xFF
        m[SCRIPT_CTR], m[SCRIPT_CTR + 1] = ctr & 0xFF, ctr >> 8
        if dialog:
            m[0xC917] = m[0xC918] = 0xFF
            m[GAME_STATE] = m[GAME_STATE] | 1
            m[0xC915] = 0
            m[0xC916] = 0
        m[SCRIPT_FLAGS] = 1
        self.started = True

    def force_scene(self):
        """Start the scene at its own first step (the conditions could not be
        met by the recipe)."""
        r = self._scene
        self._arm(r.script_type, r.script_idx if r.script_idx is not None else 0,
                  self._scene_entry, dialog=r.dialog)
        self.forced = True
        self.reached = True
        self.ended = False
        self.log.append(f'started at the scene\'s own first step (pos {self._scene_entry})')

    # ------------------------------------------------------------ running
    def where(self):
        m = self.m
        ctr = m[SCRIPT_CTR] | (m[SCRIPT_CTR + 1] << 8)
        return {'map': m[MAP_ID], 'screen': m[SCREEN_IDX], 'type': m[SCRIPT_TYPE],
                'script': m[SCRIPT_ID], 'pos': ctr if ctr < 0x8000 else ctr - 0x10000,
                'active': bool(m[SCRIPT_FLAGS] & 1), 'dialog': bool(m[GAME_STATE] & 1),
                'frames': self.frames}

    def _word_at(self, map_type, idx, pos):
        """The script word at a position (vanilla scripts; None otherwise)."""
        from .cutscenes import vanilla_script_ptrs, script_bank, CUSTOM_ROOM_START
        if map_type >= CUSTOM_ROOM_START:
            return None
        key = map_type
        if key not in self._script_ptrs:
            try:
                self._script_ptrs[key] = vanilla_script_ptrs(self.rom, map_type)
            except Exception:                       # noqa: BLE001
                self._script_ptrs[key] = []
        ptrs = self._script_ptrs[key]
        if idx >= len(ptrs):
            return None
        a = ptrs[idx] + 2 * pos
        if not 0x4000 <= a <= 0x7FFE:
            return None
        o = script_bank(map_type) * 0x4000 + (a - 0x4000)
        return self.rom[o] | (self.rom[o + 1] << 8)

    def _auto(self, i):
        """One frame of automatic input (text, YES/NO, game screens, D-pad)."""
        m = self.m
        want = set(self.buttons)
        if self.auto_text and m[GAME_STATE] & 1:
            ptr = m[TEXT_PTR] | (m[TEXT_PTR + 1] << 8)
            if ptr == self._ptr:
                self._ptr_still += 1
            else:
                self._ptr, self._ptr_still = ptr, 0
            if self._ptr_still >= max(8, self.text_pause):
                ph = self._auto_phase
                question = self._is_question()
                if question and self.answer == 'yes' and m[YESNO_CURSOR] != 0:
                    if ph < 4:
                        want.add('up')
                elif ph < 4:
                    want.add('a')
                self._auto_phase += 1
                if self._auto_phase >= 8:
                    self._auto_phase = 0
                    if not question or self.answer != 'yes' or m[YESNO_CURSOR] == 0:
                        self._ptr_still = 0
            else:
                self._auto_phase = 0
        if self.auto_text and m[GAME_STATE] & 0x10:
            # a game screen opened by op $04 (wGameState bit 4; kind in $C8EF):
            # the naming screen (15) takes the default name (START, then A);
            # any other screen (a shop …) is left with B
            self._screen_t = getattr(self, '_screen_t', 0) + 1
            t = self._screen_t % 40
            if t < 4:
                if m[0xC8EF] == 15:
                    want.add('start' if (self._screen_t // 40) % 2 == 0 else 'a')
                else:
                    want.add('b')
        else:
            self._screen_t = 0
        if self.auto_dpad and m[SCRIPT_FLAGS] & 1 and not (m[GAME_STATE] & 1):
            ctr = m[SCRIPT_CTR] | (m[SCRIPT_CTR + 1] << 8)
            w = self._word_at(m[SCRIPT_TYPE], m[SCRIPT_ID], (ctr + 1) & 0xFFFF)
            w0 = self._word_at(m[SCRIPT_TYPE], m[SCRIPT_ID], ctr)
            if 0xFF4C in (w, w0) and (i // 4) % 2 == 0:
                want.add(self.DPAD_BUTTON)
        for b in self._held - want:
            self.p.button_release(b)
        for b in want - self._held:
            self.p.button_press(b)
        self._held = want

    def _is_question(self):
        m = self.m
        ctr = m[SCRIPT_CTR] | (m[SCRIPT_CTR + 1] << 8)
        for d in (1, 2):
            w = self._word_at(m[SCRIPT_TYPE], m[SCRIPT_ID], (ctr + d) & 0xFFFF)
            if w == 0xFF15:
                a = self._word_at(m[SCRIPT_TYPE], m[SCRIPT_ID], (ctr + d + 1) & 0xFFFF)
                return a == YESNO_CURSOR
        return False

    def frame(self):
        """Advance one frame with the automatic input; track the scene."""
        m = self.m
        self._auto(self.frames)
        self.tick()
        self.frames += 1
        if self.started and not self.reset and m[GAME_MODE] == 0:
            # S118c (user: the "Arena Rooms" scene "resets and plays logo"): the
            # game left the field for its boot / title mode — a crash-reset
            self.reset = True
            self.log.append(f'⚠ the game RESET at frame {self.frames} (back to the title) — '
                            'this scene\'s set-up is wrong; please report it')
        if getattr(self, '_await_start', False) and m[SCRIPT_FLAGS] & 1:
            self._await_start = False
            self.started = True
        if self._scene is not None:
            w = self.where()
            if w['active'] and w['type'] == (self._scene.script_type & 0xFF) and \
                    w['script'] == (self._scene.script_idx or 0) and \
                    w['pos'] >= self._scene_entry - 1:
                self.reached = True
            if not w['active'] and self.started and not self.ended:
                self.ended = True
                self.log.append(f'the script ended at frame {self.frames}')

    def render(self, frames=2):
        """For the editor's audio player (music_tab.SongPlayer): run frames,
        return their sound as int16 (n, 2) at 32,768 Hz."""
        import numpy as np
        out = []
        for _ in range(frames):
            self.frame()
            if self.sound:
                out.append(self.audio())
        return np.concatenate(out) if out else np.zeros((0, 2), np.int16)

    def stop(self):
        try:
            self.p.stop(save=False)
        except TypeError:
            self.p.stop()
        except Exception:                             # noqa: BLE001
            pass
