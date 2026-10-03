#!/usr/bin/env python3
"""census_sound_engine.py — S116 (ROADMAP P3.13b): the editor's sound engine
(editor2/core/sound_engine.py — the ROM0 sequencer run on dwm/sm83.py) == the game,
frame by frame, for every sound.

Method: PyBoy boots a ROM to the title screen (frame 400, silent) and one savestate
is kept. Per sound: load it, run to the VBlank handler's audio point (a hook on
the instruction after `call ProcessBGMQueue`, $03B6 — the frame driver and the
request queue of that frame have both run), copy the game's audio RAM, HRAM and
IO registers into a fresh Machine, write the request (wBGM $C8B7 or wSoundEffect
$C8B8) in BOTH, then at every later handler pass compare
  * audio RAM $DD80-$DE2F (6 channel states + engine globals),
  * HRAM $FFE4-$FFFD (the working copy of the last channel ticked),
  * the sound registers as read back (NR12 / NR22 / NR32 / NR42 / NR43 / NR50 /
    NR51, hardware read masks) and NR52 bit 2 (the wave channel's on-bit — the
    only status bit the engine reads, at every wave note),
  * wave RAM $FF30-$FF3F while the wave channel is off (a read while it plays
    returns the sample being played)
after the Machine ran the same frame (frame driver, then the queue). Any
difference = a mismatch (first frame + byte reported).

  python3 tools/census_sound_engine.py                       # every vanilla sound, both paths
  python3 tools/census_sound_engine.py --frames 2400 --json extracted/sound_engine_census.json
  python3 tools/census_sound_engine.py --rom BUILT.gbc --ids 0x9E,0xA1 --custom
        # a patched build: ids >= $9E start through the build's own InitBGM (the
        # S116 custom path); the Machine mirrors it with start_channels(n)
  python3 tools/census_sound_engine.py --negative            # a deliberately broken
        # interpreter (DEC (HL) leaves the value) must mismatch
"""
import argparse
import io
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from editor2.core import sound_engine as SE   # noqa: E402

QUEUE_CALL = 0x03B3    # VBlankProcessAudio: `call ProcessBGMQueue`
W_BGM, W_SE = 0xC8B7, 0xC8B8     # game.sym (SOUND_SYSTEM §1 said $C8B4 — DOC_AUDIT S116)


def boot(rom_path):
    from pyboy import PyBoy
    p = PyBoy(rom_path, window='null', sound_emulated=True, cgb=True)   # registers live in the APU model
    p.set_emulation_speed(0)
    for _ in range(400):
        p.tick()
    st = io.BytesIO()
    p.save_state(st)
    return p, st


def game_state(p):
    m = p.memory
    w = bytes(m[a] for a in range(*SE.AUDIO_RAM))
    h = bytes(m[a] for a in range(*SE.HRAM_STATE))
    regs = bytes(m[a] for a in (0xFF12, 0xFF17, 0xFF1C, 0xFF21, 0xFF22, 0xFF24, 0xFF25))
    wave = bytes(m[a] for a in range(0xFF30, 0xFF40))
    on = m[0xFF26] & 0x04        # the wave channel's on-bit: the one NR52 bit the engine reads
    return w, h, regs, wave, on


def run_one(p, st, rom, sid, path, frames, custom_n=None, negative=False):
    """Events in game order: 'D' = the frame driver is about to run (snapshot taken),
    'Q' = ProcessBGMQueue is about to run. The driver also runs on lag frames
    (VBlankReentry, bank0 ~line 719) without a queue pass, so the replay follows
    the events, not a fixed per-frame pattern."""
    st.seek(0)
    p.load_state(st)
    ev = []
    seed = {}
    mm = p.memory

    def on_driver(_c):
        if not seed:
            # the seed point: the frame driver is about to run. Capture everything
            # the engine can read, then post the request so this frame's queue pass
            # consumes it (exactly like a game write to wBGM during the frame).
            seed['ram'] = bytes(mm[a] for a in range(*SE.AUDIO_RAM))
            seed['hram'] = bytes(mm[a] for a in range(0xFF80, 0xFFFF))
            seed['io'] = bytes(mm[a] for a in range(0xFF00, 0xFF80))
            seed['bgm'] = mm[0xC8B5]
            seed['on'] = mm[0xFF26] & 0x0F
            mm[W_BGM if path == 'bgm' else W_SE] = sid
        ev.append(('D', game_state(p)))
    p.hook_register(0, SE.FRAME_DRIVER, on_driver, None)
    pending = []

    def on_queue(_c):
        # the game's own requests (title-screen SEs, ...) are dropped so that only
        # the census request reaches the engine
        if not seed:
            return
        if not pending:
            pending.append(1)
        else:
            mm[W_BGM] = 0xFF
            mm[W_SE] = 0xFF
        ev.append(('Q', None))
    p.hook_register(0, QUEUE_CALL, on_queue, None)
    inits = []
    p.hook_register(0, SE.INIT_AUDIO, lambda _c: inits.append(p.frame_count) if seed else None, None)
    try:
        while sum(e[0] == 'D' for e in ev) < frames:
            p.tick()
        mach = SE.Machine(rom)
        mach.load_state(seed['ram'], seed['hram'], seed['io'])
        mach.wram[0xC8B5 - 0xC000] = seed['bgm']
        mach.ch_on = [bool(seed['on'] & (1 << i)) for i in range(4)]
        if negative:
            mach.cpu._ops[0x35] = lambda: None          # DEC (HL) does nothing
        first, started, k = None, False, 0
        for kind, g in ev:
            if kind == 'Q':
                if not started:
                    started = True
                    if custom_n:
                        mach.start_channels(sid, custom_n)
                    elif path == 'bgm':
                        mach.start_bgm(sid)
                    else:
                        mach.start_se(sid)
                continue
            mine = mach.state()
            on = 0x04 if mach.ch_on[2] else 0
            parts = [('ram', g[0], mine[0], SE.AUDIO_RAM[0]), ('hram', g[1], mine[1], SE.HRAM_STATE[0]),
                     ('regs', g[2], mine[2], 0), ('wave', g[3], mine[3], 0xFF30),
                     ('nr52', bytes([g[4]]), bytes([on]), 0)]
            if g[4]:
                # the wave channel is on: a CGB read of wave RAM returns the byte being
                # played, not the stored one — skip (the loaded instrument $DE2B is in
                # the audio RAM compare, and the copy is the same ROM code)
                parts = [x for x in parts if x[0] != 'wave']
            for name, a, b, base in parts:
                if a != b:
                    i = next(j for j in range(len(a)) if a[j] != b[j])
                    first = {'frame': k, 'what': name, 'offset': f'${base + i:04X}' if base else i,
                             'game': a[i], 'model': b[i]}
                    break
            if first:
                break
            mach.frame()
            k += 1
            if k >= frames:
                break
        foreign = {f'${a:04X}': n for a, n in mach.foreign_reads.items() if a != 0xC8B5}
        if len(inits) > (1 if path == 'bgm' else 0):
            foreign['InitAudioSystem calls by the game'] = len(inits)
        return first, foreign
    finally:
        p.hook_deregister(0, SE.FRAME_DRIVER)
        p.hook_deregister(0, QUEUE_CALL)
        p.hook_deregister(0, SE.INIT_AUDIO)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', default=os.path.join(REPO, 'data', 'DWM-original.gbc'))
    ap.add_argument('--frames', type=int, default=1200)
    ap.add_argument('--ids', default=None, help='comma list (default: every sound in songs.json)')
    ap.add_argument('--paths', default='bgm,se')
    ap.add_argument('--custom', action='store_true',
                    help='--rom is a patched build: the game plays its project songs through its '
                         'own InitBGM; the Machine is the EDITOR PREVIEW (the original ROM + the '
                         'build\'s song banks $74/$75 + its master-table rows, start_channels with '
                         'the build\'s CustomBGMChanTable count) — needs --sym')
    ap.add_argument('--sym', default=None, help='the build\'s game.sym (custom mode)')
    ap.add_argument('--original', default=os.path.join(REPO, 'data', 'DWM-original.gbc'))
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--json', default=None)
    a = ap.parse_args()
    rom = open(a.rom, 'rb').read()
    chans = None
    if a.custom:
        sym = {}
        for line in open(a.sym):
            if ':' in line and not line.startswith(';'):
                ba, name = line.split()
                b, ad = ba.split(':')
                sym[name] = (int(b, 16), int(ad, 16))
        b, ad = sym['CustomBGMChanTable']
        table = rom[b * 0x4000 + ad - 0x4000:b * 0x4000 + ad - 0x4000 + 95]
        rows = []
        t = 0x3FE8 + 12
        while rom[t] != 0xFF:
            rows.append((rom[t], rom[t + 1] | (rom[t + 2] << 8), rom[t + 3]))
            t += 4
        orig = open(a.original, 'rb').read()
        preview = SE.Machine.for_songs(orig, {bk: rom[bk * 0x4000:(bk + 1) * 0x4000]
                                              for bk in (0x74, 0x75)}, table_rows=rows).rom
        ids = [0x9E + i for i, n in enumerate(table) if n]
        chans = [table[i - 0x9E] for i in ids]
        if a.ids:
            keep = [int(x, 0) for x in a.ids.split(',')]
            chans = [c for i, c in zip(ids, chans) if i in keep]
            ids = [i for i in ids if i in keep]
        print(f'custom songs in the build: {[(hex(i), c) for i, c in zip(ids, chans)]}; rows {rows}')
    elif a.ids:
        ids = [int(x, 0) for x in a.ids.split(',')]
    else:
        songs = json.load(open(os.path.join(REPO, 'extracted', 'songs.json')))
        ids = [s['first_id'] for s in songs['sounds'] if s['first_id']]
    if chans is None:
        chans = [None] * len(ids)
    p, st = boot(a.rom)
    results, bad = [], 0
    for sid, nch in zip(ids, chans):
        for path in a.paths.split(','):
            if a.custom and path != 'bgm':
                continue
            first, foreign = run_one(p, st, preview if a.custom else rom, sid, path, a.frames,
                                     custom_n=nch if a.custom else None, negative=a.negative)
            ok = first is None and not foreign
            bad += not ok
            results.append({'id': f'${sid:02X}', 'path': path, 'frames': a.frames,
                            'ok': ok, 'first_mismatch': first, 'foreign_reads': foreign})
            if not ok:
                print(f'${sid:02X} {path}: MISMATCH {first} foreign={foreign}')
    p.stop(save=False)
    print(f'{len(results)} runs x {a.frames} frames: {len(results) - bad} identical, {bad} mismatched'
          + (' (negative control)' if a.negative else ''))
    if a.json:
        json.dump({'_generator': 'tools/census_sound_engine.py (S116): the editor sound engine '
                                 '(ROM0 sequencer on dwm/sm83.py) vs PyBoy, per VBlank handler pass',
                   'rom_md5': __import__('hashlib').md5(rom).hexdigest(),
                   'frames': a.frames, 'runs': len(results), 'mismatched': bad,
                   'results': results}, open(a.json, 'w'), indent=1)
    return 0 if (bad == 0) != a.negative else 1


if __name__ == '__main__':
    sys.exit(main())
