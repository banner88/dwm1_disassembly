#!/usr/bin/env python3
"""census_lz_decode.py — prove dwm.sprite_codec.decode == the game's own LZ
decompressor (S106, ROADMAP P3.10).

Runs the ORIGINAL ROM in PyBoy, stub-calls ROM0 `WaitDMATransfer` ($00:$1577 —
DecompressTileLayout + the copy loop) for every monster gfx-ID (221 battle +
221 walking streams; extracted/monster_sprites.json) into VRAM $8B00, and
compares the bytes with the Python decoder. Each stream runs twice, with the 4
KB below the destination ("pool") filled with $00 and with $AA: a stream whose
output changes depends on what was in VRAM before it.

Measured S106: 442 / 442 equal, 0 depend on prior VRAM (a source below the
destination reads as 0 — $00 TextMakeVisible — and no stream copies from a
part of its destination it has not written yet). The pre-S106 decoder (an
offset past the payload returned 0 for the whole copy instead of re-wrapping
each byte 4 KB down) differed on 213 battle and 49 walking streams — every
vanilla battle sprite the extractor wrote was garbled.

  pip install pyboy --break-system-packages
  python3 tools/census_lz_decode.py            # prints the counts; exit 1 on a mismatch
"""
import io
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from dwm import sprite_codec as sc                                  # noqa: E402
from tools.pyboy_harness import adv, boot                           # noqa: E402

ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
DEST = 0x8B00
STUB = 0xD700        # WRAM scratch, unused at the title screen


def main():
    rom = open(ROM, 'rb').read()
    p = boot(ROM)
    adv(p, 600)                                   # title screen: interrupts on, VRAM free
    st = io.BytesIO()
    p.save_state(st)
    ms = json.load(open(os.path.join(REPO, 'extracted', 'monster_sprites.json')))['monsters']

    def run(gid, n, pool):
        st.seek(0)
        p.load_state(st)
        for a in range(0x8000, DEST + n):
            p.memory[0, a] = pool
        code = [0xF3, 0x11, gid & 0xFF, gid >> 8,           # di / ld de,gid
                0x21, DEST & 0xFF, DEST >> 8,                # ld hl,$8B00
                0xCD, 0x77, 0x15, 0x18, 0xFE]                # call WaitDMATransfer / jr $
        for i, b in enumerate(code):
            p.memory[STUB + i] = b
        p.register_file.PC = STUB
        adv(p, 12)
        return bytes(p.memory[0, a] for a in range(DEST, DEST + n))

    bad, pooldep, total = [], [], 0
    for sid in range(221):
        for kind in ('battle', 'follower'):
            gid = int(ms[str(sid)][kind]['gfx_id'][1:], 16)
            off = sc.gfxid_stream_offset(rom, gid)[3]
            mine = sc.decode(sc.read_stream(rom, off))
            v0, va = run(gid, len(mine), 0), run(gid, len(mine), 0xAA)
            total += 1
            if v0 != mine:
                bad.append((sid, kind))
            if v0 != va:
                pooldep.append((sid, kind))
    print(f'checked {total} streams: {total - len(bad)} equal to the game, '
          f'{len(bad)} different {bad[:10]}; {len(pooldep)} depend on prior VRAM {pooldep[:10]}')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
