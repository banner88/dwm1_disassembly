#!/usr/bin/env python3
"""
decode_battle_animations.py — the battle-skill animations as data (schema 2,
S112, ROADMAP P3.11e). Rewritten S112 from the S47 decoder: the S47 version
walked the frame tables heuristically (stop at a repeated pointer, <= 24
frames) and decoded the per-skill tables as "routine 0..7 + two selectors";
schema 2 reads every table the game reads, by its real extent (the decoder
proper is editor2/core/battle_anims.py `decode_rom`; BATTLE_SKILL_SYSTEM §11).

  * 45 animations ($00-$2C): 32 frame slots each (frames = 4-byte sprites),
    the bank-$02 timeline (frame / hold, sound cues, control ops), the gfx id
    + the tiles its frames draw (hex, 16 B each), OBJ palette 0, DMG shade;
  * per skill id: cmd_foe / cmd_own ($5F:$56ED / $57D5, 232 rows) and the
    routine index per caster side (party / enemy / link: $58DD / $59C3 /
    $5AA9, 230 rows); the 16 routine pointers ($58BD);
  * extents: the byte ranges each bank's animation data covers (contiguous —
    the re-section's bounds, tools/resection_battle_anims.py).

The model is MEASURED: tools/census_battle_anims.py plays all 45 in the
game's own animation debugger and compares every frame (sprites, timing,
sounds, tiles, palette) — extracted/battle_anim_census.json.

USAGE
  python3 tools/decode_battle_animations.py            # write extracted/battle_animations.json
  python3 tools/decode_battle_animations.py --selftest # the JSON == the ROM (verify check 5)
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from editor2.core import battle_anims as BA  # noqa: E402

ROM_PATH = os.path.join(REPO, 'data', 'DWM-original.gbc')
OUT = os.path.join(REPO, 'extracted', 'battle_animations.json')
GENERATOR = ('tools/decode_battle_animations.py (S112, schema 2; decoder '
             'editor2/core/battle_anims.decode_rom) from data/DWM-original.gbc')


def build(R):
    d = BA.decode_rom(R)
    out = {'_generator': GENERATOR,
           '_doc': 'BATTLE_SKILL_SYSTEM.md §11 (the animation system, measured S112)'}
    out.update(d)
    return out


def selftest(R):
    d = build(R)
    try:
        cur = json.load(open(OUT))
    except (OSError, ValueError):
        print('  FAIL: extracted/battle_animations.json missing or unreadable')
        return False
    ok = True
    if json.loads(json.dumps(d)) != cur:
        print('  FAIL: extracted/battle_animations.json != a fresh decode of the ROM')
        ok = False
    # anchors that ground the model
    a0 = d['animations'][0]
    checks = [
        (a0['frame_table'] == 0x414D and a0['frame_ptrs'][0] == 0x418D, 'Blaze frames at $5C:$414D'),
        (a0['frames'][0] == [[0xF8, 0xF8, 0, 0], [0xF8, 0, 1, 0]], 'Blaze frame 0 = 2 sprites'),
        (d['animations'][0x10]['timeline'][:2] == [{'frame': 0, 'hold': 4}, {'sound': 0x82}],
         'Zap timeline opens (0,4) then sound $82'),
        (d['animations'][0x10]['gfx_id'] == 0x5A10, 'Zap tiles = gfx $5A10'),
        (all(a['sheet_len'] == 2048 for a in d['animations']), 'every sheet = 128 tiles'),
        (all(len(a['frame_ptrs']) == 32 for a in d['animations']), '32 frame slots each'),
        (d['routines'][13] == 0x55CC, 'routine 13 = the bare ret at $55CC'),
        (d['skills'][0x10]['cmd_foe'] == 0x10 and d['skills'][0x10]['party'] == 2,
         'Zap: animation $10, routine 2'),
        (all(a['gfx_id'] == a['gfx_id_debug'] for a in d['animations']),
         'the debugger gfx table == the battle one'),
    ]
    for good, what in checks:
        print(f"  [{'ok' if good else 'FAIL'}] {what}")
        ok = ok and good
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', default=ROM_PATH)
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    R = open(a.rom, 'rb').read()
    if a.selftest:
        print('decode_battle_animations selftest:')
        if not selftest(R):
            sys.exit(1)
        print('SELFTEST PASS')
        return
    d = build(R)
    json.dump(d, open(OUT, 'w'), indent=1)
    print(f"wrote {OUT}: {len(d['animations'])} animations, "
          f"{sum(len(a['tiles']) for a in d['animations'])} tiles, "
          f"{sum(len(set(a['frame_ptrs'])) for a in d['animations'])} distinct frames")


if __name__ == '__main__':
    main()
