"""sound_engine.py — the game's OWN sound engine, run in the editor (S116, ROADMAP P3.13b).

Headless (no Qt). The DWM1 sequencer lives in ROM0 ($3331-$3AB2, SOUND_SYSTEM.md);
this module runs THAT CODE, from the ROM bytes, on the pure-Python SM83 interpreter
(dwm/sm83.py) over a small memory map, once per video frame — exactly what the
game's VBlank handler does. The result is the frame-by-frame list of sound
register writes ($FF10-$FF3F), which editor2/core/apu_synth.py turns into audio.

Why run the code instead of re-implementing it: the engine is ~1.9 KB of
interpreter with effects whose audible meaning is only partly decoded ($Cn, $A5,
$A8 — SOUND_SYSTEM §5); running it makes every song (vanilla, DWM2 ports, MIDI
conversions, anything a future import emits) play exactly as in the game by
construction. Proven by tools/census_sound_engine.py: engine RAM + HRAM + readable
sound registers == PyBoy, frame by frame, for every sound in the ROM and every
library song.

    m = Machine.for_rom(rom_bytes)                 # the original ROM
    m.start_bgm(0x09)                              # = the game's InitBGM
    for _ in range(600):
        writes = m.frame()                         # [(reg, value), ...] this frame

    m = Machine.for_songs(rom_bytes, banks)        # + project song banks {bank: image}
    m.start_channels(0xA1, 3)                      # = the S116 InitBGM custom path

The memory map is the minimum the engine touches: ROM bank 0 + one switchable
bank (MBC5 $2000-$3FFF; $4000-$7FFF RAM-bank / $6100 writes ignored), 8 KB WRAM
(flat — the engine's state $DD80-$DE2B), HRAM, and the sound registers with the
hardware's read-back masks; NR52 reports the channels' on-bits from the trigger /
DAC rules (the engine reads bit 2, the wave channel, at every wave note). Reads
outside ROM / audio RAM / HRAM / sound registers are counted in `foreign_reads`
(the census requires none).
"""
import os
import sys

_REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if _REPO not in sys.path:
    sys.path.insert(0, _REPO)
from dwm.sm83 import CPU   # noqa: E402

# ROM0 entry points (game.sym; identical in the original and patched trees)
SET_BGM = 0x1AE1
INIT_BGM = 0x1AE5
LOAD_SE = 0x1B30
INIT_AUDIO = 0x3331
AUDIO_PROCESS = 0x33D2
FRAME_DRIVER = 0x3473          # SaveBankAndAudioState: one tick of all 6 channels
AUDIO_PROCESS_TABLE_OPERAND = 0x33D9   # the `ld hl, $3466` operand (S63 repoint)
MASTER_TABLE_EXT = 0x3FE8      # AudioMasterTableExt (patched builds)

AUDIO_RAM = (0xDD80, 0xDE30)   # 6 x 26-byte channel states + engine globals
HRAM_STATE = (0xFFE4, 0xFFFE)  # the ticking channel's working copy

# read-back OR-masks of $FF10-$FF3F (Pan Docs "Audio registers"; wave RAM raw)
_READ_OR = [0x80, 0x3F, 0x00, 0xFF, 0xBF,   0xFF, 0x3F, 0x00, 0xFF, 0xBF,
            0x7F, 0xFF, 0x9F, 0xFF, 0xBF,   0xFF, 0xFF, 0x00, 0x00, 0xBF,
            0x00, 0x00, 0x70,
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
FRAME_HZ = 4194304 / 70224     # 59.7275 frames per second


class Machine:
    """CPU + memory map around the ROM0 sound engine."""

    def __init__(self, rom):
        self.rom = rom if isinstance(rom, (bytes, bytearray)) else bytes(rom)
        self.nbanks = len(self.rom) // 0x4000
        self.bank = 1
        self.wram = bytearray(0x2000)
        self.hram = bytearray(0x80)
        self.io = bytearray(0x80)        # $FF00-$FF7F raw written values
        self.ch_on = [False] * 4         # NR52 low bits
        self.writes = []                 # sound register writes of the current call
        self.foreign_reads = {}
        self.cpu = CPU(self._rd, self._wr)
        self.io[0x26] = 0x80             # NR52: power on

    @classmethod
    def for_rom(cls, rom):
        return cls(rom)

    @classmethod
    def for_songs(cls, rom, banks, table_rows=None):
        """A preview image: the ROM with the project's song banks ({bank: 16 KB image})
        laid in, and AudioProcess pointed at an extended master table at $3FE8 (the
        S63 layout; `table_rows` = [(base_id, ptr, bank), ...] after the 3 vanilla
        rows — default one row per song bank in id order)."""
        img = bytearray(rom)
        for bank, data in banks.items():
            assert len(data) == 0x4000
            img[bank * 0x4000:(bank + 1) * 0x4000] = data
        rows = [(0x00, 0x4001, 0x1C), (0x21, 0x4001, 0x1D), (0x37, 0x4001, 0x1E)]
        rows += table_rows if table_rows is not None else \
            [(0x9E, 0x4001, b) for b in sorted(banks)][:1]
        tbl = bytearray()
        for base, ptr, bank in rows:
            tbl += bytes((base, ptr & 0xFF, ptr >> 8, bank))
        tbl.append(0xFF)
        assert len(tbl) <= 0x4000 - MASTER_TABLE_EXT
        img[MASTER_TABLE_EXT:MASTER_TABLE_EXT + len(tbl)] = tbl
        img[AUDIO_PROCESS_TABLE_OPERAND] = MASTER_TABLE_EXT & 0xFF
        img[AUDIO_PROCESS_TABLE_OPERAND + 1] = MASTER_TABLE_EXT >> 8
        return cls(bytes(img))

    # ------------------------------------------------------------------ memory
    def _rd(self, a):
        if a < 0x4000:
            return self.rom[a]
        if a < 0x8000:
            return self.rom[(self.bank % self.nbanks) * 0x4000 + a - 0x4000]
        if 0xC000 <= a < 0xE000:
            if not (AUDIO_RAM[0] <= a < AUDIO_RAM[1] or a >= 0xDF00):
                self.foreign_reads[a] = self.foreign_reads.get(a, 0) + 1
            return self.wram[a - 0xC000]
        if a >= 0xFF80:
            return self.hram[a - 0xFF80]
        if 0xFF10 <= a < 0xFF40:
            r = a - 0xFF10
            if r >= 0x20:                               # wave RAM
                return self.io[a - 0xFF00]
            if r == 0x16:                               # NR52
                return 0x70 | (self.io[0x26] & 0x80) | sum(1 << i for i in range(4)
                                                           if self.ch_on[i])
            return self.io[a - 0xFF00] | _READ_OR[r]
        self.foreign_reads[a] = self.foreign_reads.get(a, 0) + 1
        if 0xFF00 <= a < 0xFF80:
            return self.io[a - 0xFF00]
        return 0xFF

    def _wr(self, a, v):
        if a < 0x8000:
            if 0x2000 <= a < 0x3000:
                self.bank = (self.bank & 0x100) | v
            elif 0x3000 <= a < 0x4000:
                self.bank = (self.bank & 0xFF) | ((v & 1) << 8)
            return                                       # RAMB / $6100: ignored
        if 0xC000 <= a < 0xE000:
            self.wram[a - 0xC000] = v
            return
        if a >= 0xFF80:
            if a < 0xFFFF:
                self.hram[a - 0xFF80] = v
            return
        if 0xFF10 <= a < 0xFF40:
            self._apu_write(a - 0xFF10, v)
            return
        if 0xFF00 <= a < 0xFF80:
            self.io[a - 0xFF00] = v

    def _apu_write(self, r, v):
        """Sound register write: log it and keep the channel on-bits (NR52)."""
        self.writes.append((0xFF10 + r, v))
        if r == 0x16:                                    # NR52
            if not (v & 0x80):
                self.ch_on = [False] * 4
                for i in range(0x10, 0x26):
                    self.io[i] = 0
            self.io[0x26] = v & 0x80
            return
        self.io[0x10 + r] = v
        # DAC off disables the channel; a trigger with the DAC on enables it
        if r in (0x02, 0x07, 0x11):                      # NR12 / NR22 / NR42
            ch = {0x02: 0, 0x07: 1, 0x11: 3}[r]
            if (v & 0xF8) == 0:
                self.ch_on[ch] = False
        elif r == 0x0A:                                  # NR30
            if not (v & 0x80):
                self.ch_on[2] = False
        elif r in (0x04, 0x09, 0x0E, 0x13) and (v & 0x80):
            ch = {0x04: 0, 0x09: 1, 0x0E: 2, 0x13: 3}[r]
            dac = (self.io[0x1A] & 0x80) if ch == 2 else \
                (self.io[(0x12, 0x17, None, 0x21)[ch]] & 0xF8)
            self.ch_on[ch] = bool(dac)

    # ------------------------------------------------------------------ calls
    def _call(self, addr, a=None):
        # the current bank must hold its own number at $4000 (every bank does)
        self.cpu.call(addr, a=a, sp=0xDFFE)

    def start_bgm(self, sid):
        """The game's InitBGM (what ProcessBGMQueue runs for a wBGM request)."""
        self.writes = []
        self._call(INIT_BGM, a=sid)
        return self.writes

    def start_se(self, sid):
        """The game's LoadSE (a wSoundEffect request)."""
        self.writes = []
        self._call(LOAD_SE, a=sid)
        return self.writes

    def start_channels(self, first_id, n):
        """InitBGM's custom path (S116, patches/bank_000.asm): reset the audio
        system, then start `n` consecutive ids from `first_id` (one AudioProcess
        each — the same calls bank $71 `CustomBGMStart` makes)."""
        self.writes = []
        self.wram[0xC8B5 - 0xC000] = first_id            # wCurrPlayingBGM
        self._call(INIT_AUDIO)
        self.wram[0xDE24 - 0xC000] = first_id
        for _ in range(n):
            self._call(AUDIO_PROCESS)
        return self.writes

    def frame(self):
        """One VBlank tick of the sequencer -> the sound register writes made."""
        self.writes = []
        self._call(FRAME_DRIVER)
        return self.writes

    # ------------------------------------------------------------------ state
    def state(self):
        """The bytes the census compares: audio RAM, HRAM working copy, NR12 / NR22
        / NR32 / NR42 / NR43 / NR50 / NR51 as read back, wave RAM."""
        w = bytes(self.wram[AUDIO_RAM[0] - 0xC000:AUDIO_RAM[1] - 0xC000])
        h = bytes(self.hram[HRAM_STATE[0] - 0xFF80:HRAM_STATE[1] - 0xFF80])
        regs = bytes(self._rd(a) for a in (0xFF12, 0xFF17, 0xFF1C, 0xFF21, 0xFF22,
                                           0xFF24, 0xFF25))   # as read back (masks)
        wave = bytes(self.io[0x30:0x40])
        return w, h, regs, wave

    def load_state(self, audio_ram, hram, io):
        """Seed from a real game (census): audio RAM, HRAM $FF80-$FFFE, IO $FF00-$FF7F."""
        self.wram[AUDIO_RAM[0] - 0xC000:AUDIO_RAM[1] - 0xC000] = audio_ram
        self.hram[:len(hram)] = hram
        self.io[:] = io
