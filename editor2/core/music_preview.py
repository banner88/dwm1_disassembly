"""music_preview.py — hear any song in the editor (S116, ROADMAP P3.13b). Headless.

    r = Renderer.vanilla(rom, 0x09)                  # a vanilla sound id
    r = Renderer.song(rom, channels)                 # a song's channels (library /
                                                     #   project / MIDI import)
    pcm = r.render(seconds=4.0)                      # int16 (n, 2) at 32,768 Hz
    r.ended                                          # True once every channel stopped

The game's own sequencer runs on the SM83 interpreter (sound_engine.Machine) —
the sequence is exactly the game's (tools/census_sound_engine.py); apu_synth
makes the sound. A song is laid into a preview image of bank $74 at id $9E and
started the way the patched InitBGM starts a project song (InitAudioSystem, then
one AudioProcess per channel), so a song previews identically before and after
it is in the project. Costs ~0.1 s of CPU per second of music (streamable).

Also: song_info(channels) — bytes, channel roles, whether it loops / its length;
catalog(repo) — the vanilla sounds (extracted/sound_catalog.json).
"""
import json
import os

from . import apu_synth as A
from . import sound_engine as SE

PREVIEW_ID = 0x9E
SLOT_ROLE = {0x00: 'SFX 1', 0x1A: 'SFX 2', 0x34: 'pulse 1', 0x4E: 'pulse 2',
             0x68: 'wave', 0x82: 'noise'}
_STATE_SLOTS = (0x00, 0x1A, 0x34, 0x4E, 0x68, 0x82)


def _song_codec(repo):
    from .music import song_codec
    return song_codec(repo)


def _repo():
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class Renderer:
    """Streams a sound's audio frame by frame."""

    def __init__(self, machine, starter):
        self.m = machine
        self.apu = A.APU()
        self.frames = 0
        self.ended = False
        self._pending = starter(machine)       # the start's register writes
        self._hp = None

    @classmethod
    def vanilla(cls, rom, sid, path='bgm'):
        m = SE.Machine(rom)
        m._call(SE.INIT_AUDIO)
        return cls(m, (lambda mm: mm.start_bgm(sid)) if path == 'bgm'
                   else (lambda mm: mm.start_se(sid)))

    @classmethod
    def song(cls, rom, channels, repo=None):
        sc = _song_codec(repo or _repo())
        img, _, _ = sc.emit_song_bank({"songs": [{"id": "preview", "first_id": PREVIEW_ID,
                                                  "channels": channels}]})
        m = SE.Machine.for_songs(rom, {0x74: img})
        m._call(SE.INIT_AUDIO)
        n = len(channels)
        return cls(m, lambda mm: mm.start_channels(PREVIEW_ID, n))

    def _alive(self):
        w = self.m.wram
        return any(not (w[0xDD80 - 0xC000 + s] == 0xFF and w[0xDD80 - 0xC000 + s + 0x19] == 0xFF)
                   for s in _STATE_SLOTS)

    def render(self, seconds=None, frames=None):
        """The next `frames` (or seconds) of audio, int16 stereo. After the
        sound ends, renders half a second of tail, then sets `ended`."""
        n = frames if frames is not None else int(round(seconds * SE.FRAME_HZ))
        out = []
        for _ in range(n):
            if self._pending is not None:
                writes, self._pending = self._pending, None
            else:
                writes = self.m.frame()
            for a, v in writes:
                self.apu.write(a, v)
            out.append(self.apu.run(A.CYCLES_PER_FRAME))
            self.frames += 1
            if not self._alive():
                self._tail = getattr(self, '_tail', 30) - 1
                if self._tail <= 0:
                    self.ended = True
                    break
        import numpy as np
        x = np.concatenate(out) if out else np.zeros((0, 2))
        x = self.apu.highpass(x) * 0.22
        return np.clip(x * 32767, -32768, 32767).astype(np.int16)


def song_info(channels, repo=None):
    """{bytes, channels: [role...], loops} — static facts of a song."""
    sc = _song_codec(repo or _repo())
    total = sum(len(sc.emit_tokens(c['header'], c['tokens'])) for c in channels)
    loops = any(t.get('op') == 'loop_jump' for c in channels for t in c['tokens'])
    return {'bytes': total, 'roles': [SLOT_ROLE.get(int(c['slot']), '?') for c in channels],
            'loops': loops}


def catalog(repo=None):
    """The vanilla sounds (tools/dump_sound_catalog.py)."""
    p = os.path.join(repo or _repo(), 'extracted', 'sound_catalog.json')
    return json.load(open(p))['sounds']


def wav(pcm):
    return A.wav_bytes(pcm)
