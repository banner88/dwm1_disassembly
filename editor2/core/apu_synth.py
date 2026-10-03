"""apu_synth.py — Game Boy (CGB) audio from sound-register writes (S116, ROADMAP P3.13b).

Headless (numpy, no Qt). editor2/core/sound_engine.py runs the game's own sequencer
and yields, per video frame, the writes it made to $FF10-$FF3F; this module is the
APU those writes drive: two square channels (ch1 with sweep), the wave channel, the
noise LFSR, the 512 Hz frame sequencer (length 256 Hz, sweep 128 Hz, envelope
64 Hz), NR51 panning, NR50 master volume, the DACs and the output high-pass
capacitor (Pan Docs "Audio details"). Writes are applied at the start of their
frame (the engine runs in VBlank; the real ones are spread over ~1 ms of it).

Output: 32,768 Hz stereo (128 cycles per sample, so a frame-sequencer step is
exactly 64 samples). Each sample is the AVERAGE of the channel waveform over its
128 cycles (exact integration of the step functions — a box filter), which keeps
high notes from aliasing into noise.

The synth is the one approximation in the preview: the sequencing (which notes,
when, with which envelope / duty / wave / sweep / noise settings) is the game's
code, measured identical to the game (tools/census_sound_engine.py); the sound of
those settings follows the hardware documentation, checked against PyBoy's APU by
tools/census_sound_engine.py --audio (correlation of the two renders).
"""
import numpy as np

CPU_HZ = 4194304
CYCLES_PER_FRAME = 70224
RATE = 32768
CPS = CPU_HZ // RATE              # 128 cycles per sample
FS_PERIOD = 8192                  # frame-sequencer step (512 Hz)

DUTY = np.array([[0, 0, 0, 0, 0, 0, 0, 1],
                 [1, 0, 0, 0, 0, 0, 0, 1],
                 [1, 0, 0, 0, 0, 1, 1, 1],
                 [0, 1, 1, 1, 1, 1, 1, 0]], dtype=np.float64)
NOISE_DIV = [8, 16, 32, 48, 64, 80, 96, 112]


def _lfsr_sequence(width7):
    s, out = 0x7FFF, []
    period = 127 if width7 else 32767
    for _ in range(period):
        out.append((~s) & 1)
        x = (s ^ (s >> 1)) & 1
        s = (s >> 1) | (x << 14)
        if width7:
            s = (s & ~0x40) | (x << 6)
    return np.array(out, dtype=np.float64)


class _Table:
    """A periodic step function over integer steps: value(n) = vals[n % P].
    cum(x) = integral from 0 to x (x in steps, float array)."""

    def __init__(self, vals):
        self.vals = np.asarray(vals, dtype=np.float64)
        self.P = len(self.vals)
        self.cs = np.concatenate([[0.0], np.cumsum(self.vals)])
        self.total = self.cs[-1]

    def cum(self, x):
        n = np.floor(x)
        q, r = np.divmod(n, self.P)
        ri = r.astype(np.int64)
        return q * self.total + self.cs[ri] + (x - n) * self.vals[ri]


_DUTY_T = [_Table(d) for d in DUTY]
_NOISE_T = {False: _Table(_lfsr_sequence(False)), True: _Table(_lfsr_sequence(True))}


class _Ch:
    def __init__(self, kind):
        self.kind = kind               # 'sq1' 'sq2' 'wave' 'noise'
        self.on = False
        self.length = 0
        self.len_en = False
        self.vol = 0
        self.env_dir = 0
        self.env_per = 0
        self.env_timer = 0
        self.freq = 0
        self.phase = 0.0               # in steps of the channel's table
        self.duty = 2
        # sweep (ch1)
        self.sw_per = self.sw_neg = self.sw_shift = 0
        self.sw_timer = 0
        self.sw_en = False
        self.shadow = 0
        # wave
        self.wave_shift = 4            # 4 = mute
        # noise
        self.n_shift = self.n_div = 0
        self.n_width7 = False


class APU:
    def __init__(self, rate=RATE):
        assert rate == RATE, 'the synth runs at 32768 Hz (128 cycles / sample)'
        self.regs = bytearray(0x30)
        self.ch = [_Ch('sq1'), _Ch('sq2'), _Ch('wave'), _Ch('noise')]
        self.power = True
        self.fs_step = 0
        self.fs_clock = 0              # cycles until the next frame-sequencer step
        self.t = 0                     # cycles since start
        self.sample_t = 0              # next sample's END time (cycles)
        self.cap_l = self.cap_r = 0.0
        self.charge = 0.999958 ** CPS
        self._wave_tab = _Table([0] * 32)
        self._wave_dirty = True

    # ------------------------------------------------------------------ writes
    def write(self, addr, v):
        r = addr - 0xFF10
        if not (0 <= r < 0x30):
            return
        if r == 0x16:
            on = bool(v & 0x80)
            if not on:
                for i in range(0x16):
                    self.regs[i] = 0
                for c in self.ch:
                    c.on = False
            elif not self.power:
                self.fs_step = 0
            self.power = on
            self.regs[r] = v & 0x80
            return
        if r >= 0x20:
            self.regs[r] = v
            self._wave_dirty = True
            return
        if not self.power:
            return
        self.regs[r] = v
        if r < 5:
            self._sq_write(self.ch[0], r, v, sweep=True)
        elif r < 10:
            self._sq_write(self.ch[1], r - 5, v, sweep=False)
        elif r < 15:
            self._wave_write(r - 10, v)
        elif r < 20:
            self._noise_write(r - 15, v)

    def _env_write(self, c, v):
        if (v & 0xF8) == 0:
            c.on = False

    def _sq_write(self, c, r, v, sweep):
        if r == 0:
            if sweep:
                c.sw_per, c.sw_neg, c.sw_shift = (v >> 4) & 7, (v >> 3) & 1, v & 7
        elif r == 1:
            c.duty = v >> 6
            c.length = 64 - (v & 0x3F)
        elif r == 2:
            self._env_write(c, v)
        elif r == 3:
            c.freq = (c.freq & 0x700) | v
        elif r == 4:
            c.freq = (c.freq & 0xFF) | ((v & 7) << 8)
            c.len_en = bool(v & 0x40)
            if v & 0x80:
                base = 0 if sweep else 5
                nrx2 = self.regs[base + 2]
                c.on = (nrx2 & 0xF8) != 0
                if c.length == 0:
                    c.length = 64
                c.vol, c.env_dir, c.env_per = nrx2 >> 4, 1 if nrx2 & 8 else -1, nrx2 & 7
                c.env_timer = c.env_per or 8
                if sweep:
                    c.shadow = c.freq
                    c.sw_timer = c.sw_per or 8
                    c.sw_en = bool(c.sw_per or c.sw_shift)
                    if c.sw_shift and self._sweep_calc(c) > 2047:
                        c.on = False

    def _sweep_calc(self, c):
        d = c.shadow >> c.sw_shift
        return c.shadow - d if c.sw_neg else c.shadow + d

    def _wave_write(self, r, v):
        c = self.ch[2]
        if r == 0:
            if not (v & 0x80):
                c.on = False
        elif r == 1:
            c.length = 256 - v
        elif r == 2:
            c.wave_shift = {0: 4, 1: 0, 2: 1, 3: 2}[(v >> 5) & 3]
        elif r == 3:
            c.freq = (c.freq & 0x700) | v
        elif r == 4:
            c.freq = (c.freq & 0xFF) | ((v & 7) << 8)
            c.len_en = bool(v & 0x40)
            if v & 0x80:
                c.on = bool(self.regs[0x0A] & 0x80)
                if c.length == 0:
                    c.length = 256
                c.phase = 0.0

    def _noise_write(self, r, v):
        c = self.ch[3]
        if r == 1:
            c.length = 64 - (v & 0x3F)
        elif r == 2:
            self._env_write(c, v)
        elif r == 3:
            c.n_shift, c.n_width7, c.n_div = v >> 4, bool(v & 8), v & 7
        elif r == 4:
            c.len_en = bool(v & 0x40)
            if v & 0x80:
                nrx2 = self.regs[0x11]
                c.on = (nrx2 & 0xF8) != 0
                if c.length == 0:
                    c.length = 64
                c.vol, c.env_dir, c.env_per = nrx2 >> 4, 1 if nrx2 & 8 else -1, nrx2 & 7
                c.env_timer = c.env_per or 8
                c.phase = 0.0

    # ------------------------------------------------------------------ clocks
    def _fs_tick(self):
        s = self.fs_step
        if s % 2 == 0:
            for c in self.ch:
                if c.len_en and c.length > 0:
                    c.length -= 1
                    if c.length == 0:
                        c.on = False
        if s in (2, 6):
            c = self.ch[0]
            c.sw_timer -= 1
            if c.sw_timer <= 0:
                c.sw_timer = c.sw_per or 8
                if c.sw_en and c.sw_per:
                    nf = self._sweep_calc(c)
                    if nf > 2047:
                        c.on = False
                    elif c.sw_shift:
                        c.shadow = c.freq = nf
                        self.regs[3] = nf & 0xFF
                        self.regs[4] = (self.regs[4] & 0xF8) | (nf >> 8)
                        if self._sweep_calc(c) > 2047:
                            c.on = False
        if s == 7:
            for c in (self.ch[0], self.ch[1], self.ch[3]):
                if c.env_per:
                    c.env_timer -= 1
                    if c.env_timer <= 0:
                        c.env_timer = c.env_per
                        nv = c.vol + c.env_dir
                        if 0 <= nv <= 15:
                            c.vol = nv
        self.fs_step = (s + 1) & 7

    # ------------------------------------------------------------------ render
    def _channel_out(self, k, n, t0):
        """Digital output (0-15, float, box-averaged) of channel k for samples
        whose END times are t0 + CPS*(1..n); advances the channel phase."""
        c = self.ch[k]
        dac = (self.regs[0x0A] & 0x80) if k == 2 else \
            (self.regs[(0x02, 0x07, None, 0x11)[k]] & 0xF8)
        if k == 2:
            cps = (2048 - c.freq) * 2
        elif k == 3:
            cps = NOISE_DIV[c.n_div] << c.n_shift
        else:
            cps = (2048 - c.freq) * 4
        steps = CPS * n / cps
        ph0 = c.phase
        if not dac:
            out = None
        elif not c.on or (k != 2 and c.vol == 0) or (k == 2 and c.wave_shift == 4) \
                or (k == 3 and c.n_shift >= 14):
            out = np.zeros(n)
        else:
            x = ph0 + (np.arange(n + 1) * (CPS / cps))
            if k == 2:
                if self._wave_dirty:
                    w = []
                    for b in self.regs[0x20:0x30]:
                        w += [b >> 4, b & 15]
                    self._wave_tab = _Table(w)
                    self._wave_dirty = False
                tab, scale = self._wave_tab, 1.0 / (1 << c.wave_shift)
            elif k == 3:
                tab, scale = _NOISE_T[c.n_width7], float(c.vol)
            else:
                tab, scale = _DUTY_T[c.duty], float(c.vol)
            cum = tab.cum(x)
            out = np.diff(cum) * (cps / CPS) * scale
        c.phase = (ph0 + steps) % ({2: 32, 3: _NOISE_T[c.n_width7].P}.get(k, 8))
        return out

    def run(self, cycles):
        """Advance `cycles`; return the samples whose end falls inside, (n, 2) float."""
        end = self.t + cycles
        chunks = []
        while self.t < end:
            nxt_fs = self.t + (self.fs_clock or FS_PERIOD)
            seg_end = min(end, nxt_fs)
            n = 0
            st = self.sample_t
            while st + CPS <= seg_end:
                st += CPS
                n += 1
            if n:
                chunks.append(self._mix(n, self.sample_t))
                self.sample_t = st
            self.fs_clock = nxt_fs - seg_end
            self.t = seg_end
            if self.fs_clock == 0:
                self._fs_tick()
                self.fs_clock = FS_PERIOD
        return np.concatenate(chunks) if chunks else np.zeros((0, 2))

    def _mix(self, n, t0):
        nr50, nr51 = self.regs[0x14], self.regs[0x15]
        left = np.zeros(n)
        right = np.zeros(n)
        for k in range(4):
            d = self._channel_out(k, n, t0)
            if d is None:
                continue                       # DAC off: no output
            a = 1.0 - d / 7.5                  # DAC: 0..15 -> +1..-1
            if nr51 & (0x10 << k):
                left += a
            if nr51 & (1 << k):
                right += a
        left *= (((nr50 >> 4) & 7) + 1) / 8.0
        right *= ((nr50 & 7) + 1) / 8.0
        return np.stack([left, right], axis=1)

    def highpass(self, x):
        """The output capacitor (Pan Docs): out = in - cap; cap = in - out*charge."""
        ch = self.charge
        y = np.empty_like(x)
        cap = np.array([self.cap_l, self.cap_r])
        B = 256
        k = np.arange(B)
        pw = ch ** k
        for i in range(0, len(x), B):
            seg = x[i:i + B]
            m = len(seg)
            # cap[j] = ch^j cap0 + (1-ch) * sum_{i<j} ch^(j-1-i) seg[i]
            w = seg / pw[:m, None]
            cs = np.cumsum(w, axis=0)
            prev = np.vstack([np.zeros((1, 2)), cs[:-1]])
            capj = pw[:m, None] * (cap[None, :] + (1 - ch) * prev / ch)
            y[i:i + m] = seg - capj
            cap = (pw[m - 1] * ch) * cap + (1 - ch) * (pw[:m][::-1, None] * seg).sum(axis=0)
        self.cap_l, self.cap_r = cap
        return y


def render(frames_writes, rate=RATE, gain=0.22):
    """frames_writes: iterable of per-frame [(addr, value), ...] (sound_engine.frame()).
    -> int16 stereo array (n, 2) at 32768 Hz."""
    apu = APU(rate)
    out = []
    for writes in frames_writes:
        for a, v in writes:
            apu.write(a, v)
        out.append(apu.run(CYCLES_PER_FRAME))
    x = np.concatenate(out) if out else np.zeros((0, 2))
    x = apu.highpass(x) * gain
    return np.clip(x * 32767, -32768, 32767).astype(np.int16)


def wav_bytes(pcm, rate=RATE):
    import io
    import wave
    b = io.BytesIO()
    with wave.open(b, 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.astype('<i2').tobytes())
    return b.getvalue()
