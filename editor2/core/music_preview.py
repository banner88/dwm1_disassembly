"""music_preview.py — hear any song in the editor (S116, ROADMAP P3.13b). Headless.

    r = Renderer.vanilla(rom, 0x09)                  # a vanilla sound id
    r = Renderer.song(rom, channels)                 # a song's channels (library /
                                                     #   project / MIDI import)
    pcm = r.render(seconds=4.0)                      # int16 (n, 2) at 32,768 Hz
    r.ended                                          # True once every channel stopped

The game's own sequencer runs on the SM83 interpreter (sound_engine.Machine) —
the sequence is exactly the game's (tools/census_sound_engine.py); apu_synth
makes the sound. S147: a song's streams are laid into a preview image of bank $75
(bank $74 = the dummy records the game's SongStart uses, ids $9E-$FC) and started
the way the patched InitBGM starts a project song (sound_engine.Machine.start_song
= bank $74 SongStart: InitAudioSystem, one AudioProcess per channel on its dummy
record, then the channel's stream pointer + bank) — streams are relocatable, so a
song previews identically before and after it is in the project, wherever the
build puts it. Costs ~0.1 s of CPU per second of music (streamable).

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
        m, chans = song_machine(rom, channels, repo)
        m._call(SE.INIT_AUDIO)
        return cls(m, lambda mm: mm.start_song(PREVIEW_ID, chans))

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


def song_machine(rom, channels, repo=None):
    """S147: (Machine, [(dummy id, slot, stream, bank)]) for one song: the ROM with
    a preview bank $74 (self-ID + the 95 dummy records at $4003 + the silent
    stream — the template's bytes, music.dummy_records) and the song's streams in
    a preview bank $75 from $4001; the master table's custom row [$9E, $4003, $74]."""
    from . import music as M
    sc = _song_codec(repo or _repo())
    b74 = bytearray(0x4000)
    b74[0] = 0x74
    silent = M.SONG_RECORDS_AT + 4 * M.SONG_IDS
    recs = M.dummy_records(silent)
    b74[3:3 + len(recs)] = recs
    b74[silent - 0x4000:silent - 0x4000 + len(M.SILENT_STREAM)] = M.SILENT_STREAM
    b75 = bytearray(0x4000)
    b75[0] = 0x75
    pos, chans = 0x4001, []
    for c in channels:
        blob = sc.emit_tokens(c['header'], c['tokens'])
        if pos + len(blob) > 0x8000:
            raise ValueError("the song is bigger than one bank")
        b75[pos - 0x4000:pos - 0x4000 + len(blob)] = blob
        from . import formats as F
        slot, hw = F.val(c['slot']), F.val(c['hw'])
        chans.append((M.dummy_id(slot, hw), slot, pos, 0x75))
        pos += len(blob)
    m = SE.Machine.for_songs(rom, {0x74: bytes(b74), 0x75: bytes(b75)},
                             table_rows=[(M.FIRST_ID, M.SONG_RECORDS_AT, 0x74)])
    return m, chans


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
