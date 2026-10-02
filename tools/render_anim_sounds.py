#!/usr/bin/env python3
"""
render_anim_sounds.py — S112 (ROADMAP P3.11e): the sound cues of the battle
animations as small WAV files, so the editor's animation preview can play them
(editor2/app/anims_tab.py). Each file is the GAME'S OWN sound engine playing
that sound effect, recorded in PyBoy — not a re-synthesis.

  * the sound ids = every `$FD` cue of the 45 stock timelines
    (extracted/battle_animations.json; 35 ids, $70-$9B — the ids between them
    are the second channels of two-channel effects, SOUND_SYSTEM §1);
  * the original ROM boots to the title (silent at frame 400), one savestate;
    per id: load it, write wSoundEffect ($C8B8) = id, record 150 frames of
    the emulated APU (48 kHz stereo), cut the silence after the last sample
    above 1/128 (+ 50 ms), mix to mono, 16 kHz, 16-bit signed PCM (8-bit
    WAVs are refused by some QSoundEffect back ends);
  * output extracted/anim_sounds/sfx_XX.wav + index.json (id -> file, length
    in frames, the stock animations that cue it).

USAGE
  python3 tools/render_anim_sounds.py            # needs pyboy + the ROM
"""
import io
import json
import os
import sys
import wave

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
OUT = os.path.join(REPO, 'extracted', 'anim_sounds')
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
W_SOUND_EFFECT = 0xC8B8
FRAMES = 150
RATE_OUT = 16000


def main():
    import numpy as np
    from pyboy import PyBoy
    from editor2.core import battle_anims as BA
    ids = BA.sound_ids(REPO)
    os.makedirs(OUT, exist_ok=True)
    p = PyBoy(ROM, window='null', sound_emulated=True, cgb=True)
    p.set_emulation_speed(0)
    for _ in range(400):
        p.tick()
    base = io.BytesIO()
    p.save_state(base)
    index = {}
    for sid in sorted(ids):
        base.seek(0)
        p.load_state(base)
        p.memory[W_SOUND_EFFECT] = sid
        chunks = []
        for _ in range(FRAMES):
            p.tick()
            chunks.append(p.sound.ndarray.copy())
        a = np.concatenate(chunks).astype(np.int16)
        mono = a.mean(axis=1)
        loud = np.nonzero(np.abs(mono) > 1)[0]
        end = (loud[-1] + 2400) if len(loud) else 4800
        mono = mono[:end]
        n = len(mono) // 3
        mono = mono[:n * 3].reshape(n, 3).mean(axis=1)           # 48 -> 16 kHz
        pcm = np.clip(mono * 512, -32768, 32767).astype(np.int16)  # int8 -> s16, x2
        name = f'sfx_{sid:02x}.wav'
        with wave.open(os.path.join(OUT, name), 'wb') as wv:
            wv.setnchannels(1)
            wv.setsampwidth(2)
            wv.setframerate(RATE_OUT)
            wv.writeframes(pcm.tobytes())
        index[f'{sid}'] = {'file': name, 'frames': round(len(pcm) / RATE_OUT * 59.73),
                           'animations': ids[sid]}
        print(f'${sid:02X}: {len(pcm) / RATE_OUT:.2f} s, used by {[hex(c) for c in ids[sid]]}')
    json.dump({'_generator': 'tools/render_anim_sounds.py (S112): the original ROM\'s sound '
                             'engine in PyBoy, wSoundEffect per id, 16 kHz mono s16',
               'sounds': index}, open(os.path.join(OUT, 'index.json'), 'w'), indent=1)
    print('wrote', OUT)


if __name__ == '__main__':
    main()
