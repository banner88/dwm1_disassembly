#!/usr/bin/env python3
"""midi_to_song.py — MIDI (SMF 0/1) -> DWM1-native song-library entry (M3c, S64).

Emits the SAME library schema as song_codec.py extract-gbs-library
(channels carry DWM1 state slots + header + token list), so the one proven
spec->bytes path (song_codec emit_song_bank, via the editor2 music emitter)
serves MIDI and DWM2 sources alike — the M2 "common intermediate" design
(SOUND_SYSTEM.md §8).

Engine timing facts this converter builds on (instruction-verified S64,
SOUND_SYSTEM.md §4/§5 corrections):
  * Note lengths are FRAMES (~59.7275/s): the per-frame driver decrements
    the $EC length counter unconditionally every frame; the $A3 value in
    $FA/$FB only gates the groove stepper ($3B83). (S61's "length in
    $A3-scaled ticks" reading is falsified — DOC_AUDIT S64.)
  * Note byte: low nibble = semitone (0-11; >= $0C = rest/key-off), high
    nibble n shifts the pitch-table period RIGHT (P>>n) which RAISES the
    pitch n octaves. Semitone 0 / n=0 = 65.4 Hz = C2 = MIDI 36
    (freq = 131072 / (P>>n); table @ ROM0 $3A53).
  * $A7 xx reloads $EC without retriggering — a tie/hold, used here to
    extend notes past the 255-frame length ceiling without re-attack.

Timing: every note boundary is independently rounded to the nearest frame
(no cumulative drift); lengths are boundary differences. Overlapping notes
on one MIDI channel are monophonized (a new note-on truncates the previous;
counts reported). Channel 10 (idx 9) maps to noise; melodic channels map in
--map order (default: order of first note) to pulse1/pulse2/wave.

Usage:
  python3 tools/midi_to_song.py --midi dq6-town1.mid --song-id dq6_town1 \
      --library extracted/midi_song_library.json
  Options: --map "0:pulse1,1:pulse2,2:wave" --transpose 0 --no-loop
           --pulse-duty 2 --pulse-envelope 0x0B --wave-instrument 8
           --wave-outlevel 0x20 --name "DQ6 Town 1"
"""
import argparse
import hashlib
import json
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import song_codec as SC  # noqa: E402  (emit_tokens / decode round-trip)

GB_FPS = 59.7275
FRAME_MAX = 255                 # $EC is one byte
CH_SLOT = {"pulse1": (0x34, 0), "pulse2": (0x4E, 1),
           "wave": (0x68, 2), "noise": (0x82, 3)}
# GM percussion note -> noise-table index ($37C5, 16 entries). Convention
# defaults (ear-tune; noise-table audible semantics are not fully mapped):
GM_NOISE = {35: 0x0C, 36: 0x0C, 38: 0x06, 40: 0x06, 37: 0x07,
            42: 0x02, 44: 0x02, 46: 0x01, 49: 0x00, 51: 0x03}
NOISE_DEFAULT = 0x04
NOISE_REST = 0x1F


# ------------------------------------------------------------ MIDI parsing --
def _vlq(data, p):
    v = 0
    while True:
        b = data[p]
        p += 1
        v = (v << 7) | (b & 0x7F)
        if not b & 0x80:
            return v, p


def parse_midi(path):
    data = Path(path).read_bytes()
    if data[:4] != b"MThd":
        raise ValueError("not a Standard MIDI File")
    hlen, fmt, ntrk, div = struct.unpack(">IHHH", data[4:14])
    if div & 0x8000:
        raise ValueError("SMPTE division not supported")
    if fmt not in (0, 1):
        raise ValueError(f"SMF format {fmt} not supported (0/1 only)")
    ofs = 8 + hlen
    tempos = []            # (abs_tick, us_per_qn)
    notes = {}             # midi_ch -> [(on_tick, off_tick, pitch, vel)]
    for _ in range(ntrk):
        assert data[ofs:ofs + 4] == b"MTrk"
        tlen = struct.unpack(">I", data[ofs + 4:ofs + 8])[0]
        p, end, t, running = ofs + 8, ofs + 8 + tlen, 0, None
        open_notes = {}    # (ch, pitch) -> on_tick
        while p < end:
            dt, p = _vlq(data, p)
            t += dt
            b = data[p]
            if b == 0xFF:
                typ = data[p + 1]
                ln, q = _vlq(data, p + 2)
                meta = data[q:q + ln]
                p = q + ln
                if typ == 0x51:
                    tempos.append((t, struct.unpack(">I", b"\0" + meta)[0]))
                elif typ == 0x2F:
                    break
                continue
            if b in (0xF0, 0xF7):
                ln, q = _vlq(data, p + 1)
                p = q + ln
                continue
            if b & 0x80:
                st, p = b, p + 1
                running = st
            else:
                st = running
            typ, ch = st & 0xF0, st & 0x0F
            if typ in (0xC0, 0xD0):
                p += 1
                continue
            d1, d2 = data[p], data[p + 1]
            p += 2
            if typ == 0x90 and d2 > 0:
                if (ch, d1) in open_notes:          # re-strike: close first
                    notes.setdefault(ch, []).append(
                        (open_notes.pop((ch, d1)), t, d1, d2))
                open_notes[(ch, d1)] = t
            elif typ == 0x80 or (typ == 0x90 and d2 == 0):
                if (ch, d1) in open_notes:
                    notes.setdefault(ch, []).append(
                        (open_notes.pop((ch, d1)), t, d1, d2))
        for (ch, d1), on in open_notes.items():     # dangling note-ons
            notes.setdefault(ch, []).append((on, t, d1, 64))
        ofs += 8 + tlen
    if not tempos:
        tempos = [(0, 500000)]                      # MIDI default 120 bpm
    tempos.sort()
    if tempos[0][0] != 0:
        tempos.insert(0, (0, 500000))
    for ch in notes:
        notes[ch].sort()
    return div, tempos, notes


def tick_to_frames(div, tempos):
    """Return f(abs_tick) -> absolute frame number (float)."""
    # precompute cumulative seconds at each tempo change
    cum = []
    sec = 0.0
    for i, (t, us) in enumerate(tempos):
        cum.append((t, sec, us))
        nxt = tempos[i + 1][0] if i + 1 < len(tempos) else None
        if nxt is not None:
            sec += (nxt - t) * us / 1e6 / div

    def f(tick):
        base_t, base_s, us = cum[0]
        for bt, bs, bu in cum:
            if bt <= tick:
                base_t, base_s, us = bt, bs, bu
            else:
                break
        return (base_s + (tick - base_t) * us / 1e6 / div) * GB_FPS
    return f


# ------------------------------------------------------- channel rendering --
def monophonize(evts):
    """[(on,off,pitch,vel)] sorted -> non-overlapping; returns (evts, cut)."""
    out, cut = [], 0
    for on, off, pitch, vel in evts:
        if out and out[-1][1] > on:
            last = out[-1]
            out[-1] = (last[0], on, last[2], last[3])
            cut += 1
        if out and out[-1][0] >= out[-1][1]:
            out.pop()
        out.append((on, off, pitch, vel))
    return out, cut


def note_byte(pitch, transpose, warnings):
    n = pitch - 36 + transpose
    while n < 0:
        n += 12
        warnings.append(f"pitch {pitch} below C2 — raised an octave")
    while n > 9 * 12 + 11:
        n -= 12
        warnings.append(f"pitch {pitch} above range — lowered an octave")
    return ((n // 12) << 4) | (n % 12)


def emit_len(tokens, first, length):
    """Emit `first` token then $A7 holds for length > 255 frames."""
    seg = min(length, FRAME_MAX)
    first = dict(first)
    first["len"] = seg
    tokens.append(first)
    length -= seg
    while length > 0:
        seg = min(length, FRAME_MAX)
        tokens.append({"op": "ctl", "byte": 0xA7, "prm": seg,
                       "name": "rest_hold"})
        length -= seg
    return


def render_channel(role, evts, to_frames, opts, warnings):
    """-> token list (setup ctls + notes/rests [+ loop])."""
    # $A3 param bit7=1 -> E5 &= $0F: groove stepper OFF (instruction-verified
    # S64: bit7=0 would SET E5 bit7 and every groove row at $3B83 is a live
    # vibrato/detune shape — $A3 $80 is the only deterministic "straight" form,
    # and it clears any groove state inherited from the previous song).
    tokens = [{"op": "ctl", "byte": 0xA3, "prm": 0x80,
               "name": "tempo_groove"}]
    if role in ("pulse1", "pulse2"):
        tokens.append({"op": "ctl", "byte": 0xA2, "prm": opts.pulse_duty,
                       "name": "duty_outlevel"})
        tokens.append({"op": "ctl", "byte": 0xA0, "prm": opts.pulse_envelope,
                       "name": "envelope"})
    elif role == "wave":
        tokens.append({"op": "ctl", "byte": 0xA1, "prm": opts.wave_instrument,
                       "name": "instrument"})
        tokens.append({"op": "ctl", "byte": 0xA2, "prm": opts.wave_outlevel,
                       "name": "duty_outlevel"})
    else:                                       # noise
        tokens.append({"op": "ctl", "byte": 0xA0, "prm": opts.pulse_envelope,
                       "name": "envelope"})
    rest = 0x1F if role == "noise" else 0x0C
    cursor = 0                                  # absolute frames emitted
    for on, off, pitch, vel in evts:
        fon, foff = round(to_frames(on)), round(to_frames(off))
        if foff <= fon:
            foff = fon + 1                      # never drop to zero length
        if fon > cursor:
            emit_len(tokens, {"op": "note", "byte": rest}, fon - cursor)
        elif fon < cursor:
            fon = cursor                        # rounding overlap: clip
            if foff <= fon:
                continue
        if role == "noise":
            nb = GM_NOISE.get(pitch, NOISE_DEFAULT)
        else:
            nb = note_byte(pitch, opts.transpose, warnings)
        emit_len(tokens, {"op": "note", "byte": nb}, foff - fon)
        cursor = foff
    return tokens, cursor


# ------------------------------------------------------------------- main ---
def convert(opts):
    warnings = []
    div, tempos, notes = parse_midi(opts.midi)
    to_frames = tick_to_frames(div, tempos)
    # channel -> role
    mapping = {}
    if opts.map:
        for pair in opts.map.split(","):
            ch, role = pair.split(":")
            if role not in CH_SLOT:
                raise SystemExit(f"unknown role {role!r}")
            mapping[int(ch)] = role
    else:
        melodic = [c for c in notes if c != 9]
        if 9 in notes:
            mapping[9] = "noise"
        if len(melodic) > 3:
            raise SystemExit(f"more than 3 melodic MIDI channels "
                             f"({sorted(notes)}) — pick 3 with --map")
        # lowest mean pitch = bass -> wave; the rest -> pulse1/pulse2 in
        # first-note order (wave has no envelope decay: best for sustained bass)
        def mean_pitch(c):
            return sum(p for _, _, p, _ in notes[c]) / len(notes[c])
        if len(melodic) == 3:
            bass = min(melodic, key=mean_pitch)
            mapping[bass] = "wave"
            rest = sorted((c for c in melodic if c != bass),
                          key=lambda c: notes[c][0][0])
            mapping[rest[0]], mapping[rest[1]] = "pulse1", "pulse2"
        else:
            roles = iter(["pulse1", "pulse2", "wave"])
            for ch in sorted(melodic, key=lambda c: notes[c][0][0]):
                mapping[ch] = next(roles)
    used = [r for r in mapping.values()]
    if len(set(used)) != len(used):
        raise SystemExit("--map assigns one role twice")

    channels = []
    total_cut = 0
    ends = []
    order = ["pulse1", "pulse2", "wave", "noise"]
    for role in order:
        chs = [c for c, r in mapping.items() if r == role]
        if not chs:
            continue
        ch = chs[0]
        evts, cut = monophonize(notes[ch])
        total_cut += cut
        toks, end = render_channel(role, evts, to_frames, opts, warnings)
        ends.append(end)
        channels.append({"role": role, "midi_channel": ch, "tokens": toks,
                         "note_count": len(evts), "overlap_cuts": cut})
    # equalize channel end times so the loop stays phase-locked
    song_end = max(ends)
    for c, end in zip(channels, ends):
        if end < song_end:
            rest = NOISE_REST if c["role"] == "noise" else 0x0C
            emit_len(c["tokens"], {"op": "note", "byte": rest},
                     song_end - end)
    out_channels = []
    for c in channels:
        toks = c.pop("tokens")
        if not opts.no_loop:
            toks.append({"op": "loop_jump", "n": 0, "target": 2})
        toks.append({"op": "end"})
        role = c["role"]
        slot, hw = CH_SLOT[role]
        header = [0, 0, 0, 0]                   # all setup via explicit ctls
        blob = SC.emit_tokens(header, toks)
        # decode round-trip against an in-memory image (well-formedness)
        img = bytearray(0x4000)
        img[0x180:0x180 + len(blob)] = blob
        rdr = SC.ImageReader(bytes(img), 0x74)
        hdr2, toks2, _ = SC.decode_tokens(rdr, 0x74, 0x4180)
        if toks2[-1]["op"] != "end":
            toks2.append({"op": "end"})         # decode stops at the jump
        if SC.emit_tokens(hdr2, toks2) != blob:
            raise SystemExit(f"{role}: decode round-trip mismatch (bug)")
        out_channels.append({"slot": slot, "hw": hw, "header": header,
                             "tokens": toks, "bytes": len(blob),
                             "midi_channel": c["midi_channel"],
                             "note_count": c["note_count"],
                             "overlap_cuts": c["overlap_cuts"]})
    entry = {
        "id": opts.song_id,
        "name": opts.name or opts.song_id,
        "channels": out_channels,
        "channel_count": len(out_channels),
        "total_bytes": sum(c["bytes"] for c in out_channels),
        "duration_frames": song_end,
        "loops": not opts.no_loop,
        "midi_source": {"file": Path(opts.midi).name,
                        "md5": hashlib.md5(
                            Path(opts.midi).read_bytes()).hexdigest(),
                        "division": div,
                        "tempo_us_per_qn": [list(t) for t in tempos]},
        "conversion": {"transpose": opts.transpose,
                       "pulse_duty": opts.pulse_duty,
                       "pulse_envelope": opts.pulse_envelope,
                       "wave_instrument": opts.wave_instrument,
                       "wave_outlevel": opts.wave_outlevel,
                       "map": {str(c): r for c, r in mapping.items()},
                       "overlap_cuts": total_cut,
                       "warnings": sorted(set(warnings))},
    }
    p = Path(opts.library)
    lib = json.loads(p.read_text()) if p.exists() else {
        "_generator": "tools/midi_to_song.py (MIDI -> DWM1-native tokens; "
                      "lengths in frames, decode round-trip checked)",
        "songs": []}
    lib["songs"] = [s for s in lib["songs"] if s.get("id") != opts.song_id]
    lib["songs"].append(entry)
    lib["songs"].sort(key=lambda s: s["id"])
    p.write_text(json.dumps(lib, indent=1))
    dur = song_end / GB_FPS
    print(f"'{opts.song_id}': {len(out_channels)} channels, "
          f"{entry['total_bytes']} stream bytes, {dur:.1f}s/loop, "
          f"{total_cut} overlap cuts, map "
          f"{entry['conversion']['map']} -> {opts.library}")
    for w in sorted(set(warnings)):
        print(f"  warn: {w} (x{warnings.count(w)})")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--midi", required=True)
    ap.add_argument("--song-id", required=True)
    ap.add_argument("--name", default=None)
    ap.add_argument("--library", default="extracted/midi_song_library.json")
    ap.add_argument("--map", default=None,
                    help='e.g. "0:pulse1,1:pulse2,2:wave,9:noise"')
    ap.add_argument("--transpose", type=int, default=0,
                    help="semitones added before the C2-based pitch mapping")
    ap.add_argument("--no-loop", action="store_true")
    ap.add_argument("--pulse-duty", type=lambda x: int(x, 0), default=2,
                    help="$A2 param, low 2 bits = duty (default 2 = 50%%)")
    ap.add_argument("--pulse-envelope", type=lambda x: int(x, 0),
                    default=0x0B, help="$A0 param (default $0B: vol 11 held)")
    ap.add_argument("--wave-instrument", type=lambda x: int(x, 0), default=8,
                    help="$A1 wave slot 0-15 (default 8, the DWM2-port pick)")
    ap.add_argument("--wave-outlevel", type=lambda x: int(x, 0), default=0x20,
                    help="$A2 param on wave = $F1 out-level (default $20)")
    convert(ap.parse_args())


if __name__ == "__main__":
    main()
