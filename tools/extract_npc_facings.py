#!/usr/bin/env python3
"""extract_npc_facings.py — every NPC field sprite in all four facings, with
transparency, read from the game itself (S119, ROADMAP P3.8 part B: the
cutscene editor shows who faces where).

Method (PyBoy, the original ROM): each sprite id is placed SOLO in the Castle
throne room (screen 1, state 4 — the S91 catalog's slot: dump_npc_sprite_catalog
patches that step's interact block in a temp ROM copy), the room is entered,
then the NPC's animation is frozen (slot +$05 := $80) and for every facing
(slot +$06) and step frame (slot +$14: 0/1 down, 2/3 sideways, 4/5 up) the
game draws it. The picture is composed from what the game put in OAM (the
NPC's objects), VRAM (tile data, bank from the attribute) and the CGB object
palettes — exact pixels, colour 0 transparent, X/Y flips as the game sets
them. The player (Terry) is captured the same way from OAM 0-3 with his HRAM
facing ($FF8E, $FF8D/$FF8F as the field engine writes them).

Outputs (extracted/):
  npc_facing_sprites/id_XX.png   128x16 RGBA strip: down, down-step, left,
                                 left-step, up, up-step, right, right-step
  npc_facing_sprites/player.png  the same for the player
  npc_facing_sprites.json        _generator + per id: drawn (bool), objects

Usage:  python3 tools/extract_npc_facings.py [--ids 00-7F]
"""
import argparse
import json
import os
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
OUT = os.path.join(REPO, 'extracted', 'npc_facing_sprites')
TMP = '/tmp/npcface'
ENTS = 183595                 # Castle screen 1 state 4 interact block (dump_npc_sprite_catalog)
CTR = 0xD92B
CELL = (3, 3)                 # screen-local cell of the solo NPC
SLOT = 0xD7D2                 # NPC 1
FACINGS = [(0, 0), (1, 2), (2, 4), (3, 2)]   # (slot +$06 facing, base cel)
ORDER = [0, 1, 2, 3]          # down, left, up, right in the strip
CANDIDATES = list(range(0x00, 0x80)) + [0xE0, 0xE1, 0xE2, 0xE3]


def obj_palettes(p):
    """64 bytes of CGB object palette RAM -> [[(r, g, b) x4] x8]."""
    m = p.memory
    raw = []
    for i in range(64):
        m[0xFF6A] = i
        raw.append(m[0xFF6B])
    pals = []
    for k in range(8):
        cols = []
        for c in range(4):
            v = raw[k * 8 + c * 2] | (raw[k * 8 + c * 2 + 1] << 8)
            r, g, b = v & 31, (v >> 5) & 31, (v >> 10) & 31
            cols.append((r * 255 // 31, g * 255 // 31, b * 255 // 31))
        pals.append(cols)
    return pals


def tile_pixels(p, bank, tile):
    rows = []
    base = 0x8000 + tile * 16
    for y in range(8):
        lo, hi = p.memory[bank, base + 2 * y], p.memory[bank, base + 2 * y + 1]
        rows.append([((lo >> (7 - x)) & 1) | (((hi >> (7 - x)) & 1) << 1) for x in range(8)])
    return rows


def compose(p, x0, y0, oam_range=range(40), size=16):
    """RGBA image of the objects whose top-left lies in [x0, x0+16) x [y0, y0+16)
    (screen pixels; OAM x-8 / y-16), plus the object count."""
    from PIL import Image
    pals = obj_palettes(p)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    px = img.load()
    n = 0
    lcdc = p.memory[0xFF40]
    tall = bool(lcdc & 4)
    for i in reversed(list(oam_range)):            # lower index drawn on top
        y, x, t, a = [p.memory[0xFE00 + 4 * i + k] for k in range(4)]
        sx, sy = x - 8, y - 16
        if not (x0 - 7 <= sx < x0 + size and y0 - (15 if tall else 7) <= sy < y0 + size):
            continue
        if y == 0 or x == 0:
            continue
        n += 1
        bank = (a >> 3) & 1
        pal = pals[a & 7]
        tiles = [t & 0xFE, t | 1] if tall else [t]
        for ti, tt in enumerate(tiles):
            pix = tile_pixels(p, bank, tt)
            for yy in range(8):
                for xx in range(8):
                    c = pix[7 - yy if a & 0x40 else yy][7 - xx if a & 0x20 else xx]
                    if not c:
                        continue
                    if a & 0x40 and tall:
                        ty = (1 - ti) * 8 + yy
                    else:
                        ty = ti * 8 + yy
                    X, Y = sx + xx - x0, sy + ty - y0
                    if 0 <= X < size and 0 <= Y < size:
                        px[X, Y] = pal[c] + (255,)
    return img, n


def boot_state():
    from tools.pyboy_harness import boot, to_bedroom
    st = os.path.join(TMP, 'base.state')
    if os.path.exists(st):
        return st
    shutil.copy(ROM, os.path.join(TMP, 'rom.gbc'))
    p = boot(os.path.join(TMP, 'rom.gbc'))
    assert to_bedroom(p), 'scripted intro failed'
    with open(st, 'wb') as f:
        p.save_state(f)
    p.stop(save=False)
    return st


def render_id(sid, st):
    from PIL import Image
    from tools.pyboy_harness import boot, adv, warp
    rom = bytearray(open(ROM, 'rb').read())
    rom[ENTS:ENTS + 5] = bytes([0x00, sid, CELL[0], CELL[1], 0xFF])
    rom[ENTS + 5] = 0xFF
    path = os.path.join(TMP, f'rom_{sid:02X}.gbc')
    open(path, 'wb').write(rom)
    p = boot(path)
    with open(st, 'rb') as f:
        p.load_state(f)
    adv(p, 10)
    p.memory[CTR] = 4
    warp(p, 0x00, 14, 7, settle=400)
    m = p.memory
    strip = Image.new('RGBA', (128, 16), (0, 0, 0, 0))
    objs = 0
    ok = m[0xC968] == 0x00 and m[SLOT] != 0xFF
    if ok:
        m[SLOT + 5] = 0x80                    # freeze the animation picker
        for k, (face, cel) in enumerate(FACINGS):
            for step in (0, 1):
                m[SLOT + 6] = face
                m[SLOT + 0x14] = cel + step
                adv(p, 3)
                scx, scy = m[0xFF43], m[0xFF42]
                x = m[SLOT + 0x18] | (m[SLOT + 0x19] << 8)
                y = m[SLOT + 0x1A] | (m[SLOT + 0x1B] << 8)
                img, n = compose(p, x - 8 - scx, y - 8 - scy, range(4, 40))
                objs = max(objs, n)
                strip.paste(img, ((ORDER[k] * 2 + step) * 16, 0))
    p.stop(save=False)
    os.remove(path)
    return strip, ok and objs > 0, objs


def render_player(st):
    from PIL import Image
    from tools.pyboy_harness import boot, adv, warp
    p = boot(os.path.join(TMP, 'rom.gbc'))
    with open(st, 'rb') as f:
        p.load_state(f)
    adv(p, 10)
    warp(p, 0x01, 5, 5, settle=300)
    m = p.memory
    strip = Image.new('RGBA', (128, 16), (0, 0, 0, 0))
    hram = {0: (0x00, 0x00), 1: (0x20, 0x01), 2: (0x00, 0x02), 3: (0x00, 0x01)}
    for k, (face, _cel) in enumerate(FACINGS):
        for step in (0, 1):
            # the player's frame: $FF8E facing, $FF8D flip, $FF8F cel row (+ the
            # walk toggle in bit 0 of $FF91 is the engine's own; held still here)
            m[0xFF8E] = face
            m[0xFF8D], m[0xFF8F] = hram[face]
            adv(p, 2)
            px = m[0xFF92] | (m[0xFF93] << 8)
            py = m[0xFF95] | (m[0xFF96] << 8)
            img, _n = compose(p, px - 8 - m[0xFF43], py - 8 - m[0xFF42], range(0, 4))
            strip.paste(img, ((ORDER[k] * 2 + step) * 16, 0))
    p.stop(save=False)
    return strip


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--ids', default=None, help='e.g. 00-3F')
    a = ap.parse_args()
    ids = CANDIDATES
    if a.ids:
        lo, hi = (int(x, 16) for x in a.ids.split('-'))
        ids = [i for i in CANDIDATES if lo <= i <= hi]
    os.makedirs(TMP, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    st = boot_state()
    man_path = os.path.join(REPO, 'extracted', 'npc_facing_sprites.json')
    man = json.load(open(man_path)) if os.path.exists(man_path) else {}
    man['_generator'] = ('tools/extract_npc_facings.py (S119) — PyBoy on data/DWM-original.gbc: '
                         'each sprite solo in the Castle throne room, every facing drawn by the '
                         'game, composed from OAM + VRAM + CGB object palettes')
    man['_strip'] = 'down, down-step, left, left-step, up, up-step, right, right-step (16x16 each)'
    ids_out = man.setdefault('ids', {})
    for sid in ids:
        strip, drawn, objs = render_id(sid, st)
        strip.save(os.path.join(OUT, f'id_{sid:02X}.png'))
        ids_out[f'0x{sid:02X}'] = {'drawn': drawn, 'objects': objs}
        print(f'{sid:02X}: {"drawn" if drawn else "NOT DRAWN"} ({objs} objects)')
    render_player(st).save(os.path.join(OUT, 'player.png'))
    json.dump(man, open(man_path, 'w'), indent=1, sort_keys=True)


if __name__ == '__main__':
    main()
