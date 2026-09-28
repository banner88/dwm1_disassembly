#!/usr/bin/env python3
"""census_monster_npc_sprites.py — every species as a MONSTER NPC (S101).

A monster NPC is an NPC entry with sprite id $F0-$F3: the bank $0B sheet
resolver reads the display-list pair at $D7CA + 2n ([species+$10, 1]) and
draws the species exactly like its overworld follower (sheet from the
follower-art table, layout from bank $10/$11, palette from its attr table —
ROOM_DATA_FORMAT "Monster NPCs"). The editor shows a thumbnail per species
in the NPC sprite picker and on the canvas; this tool captures them from the
running game, so they are pixel-exact:

  1. build the example project with four raw $F0-$F3 NPCs on gate_island
     screen 0 (a room with no cast of its own, so a poked list survives),
  2. PyBoy: new game -> bedroom; per batch of four species poke the list,
     warp into the room, screenshot; hide the four NPCs (type bit 6),
     screenshot again; the pixels that differ ARE the sprites (the sand
     under them is identical in both shots) -> 16x16 RGBA crops.

Output: extracted/monster_npc_sprites/sp_NNN.png (standing, facing down) +
extracted/monster_npc_sprites.json {_generator, cell, species: {id: {name,
file, pixels}}}.

Usage: python3 tools/census_monster_npc_sprites.py [--species 0-216,224]
Species 217-220 (Diago, Samsi, Bazoo, the unnamed last row) HANG or CRASH the game as
monster NPCs (their follower tables are not real) — measured S101; the compiler refuses them.
Needs data/DWM-original.gbc, RGBDS (the build) and pyboy.
"""
import argparse
import copy
import json
import os
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..'))
sys.path.insert(0, REPO)

OUT_DIR = os.path.join(REPO, 'extracted', 'monster_npc_sprites')
OUT_JSON = os.path.join(REPO, 'extracted', 'monster_npc_sprites.json')
CELLS = [(2, 2), (4, 2), (6, 2), (8, 2)]     # screen-0 cells of the four NPCs


def build_rom(tmp):
    from editor2.core import compiler as C
    from editor2.core import builder as B
    src = os.path.join(REPO, 'editor2', 'example-project')
    proj = os.path.join(tmp, 'proj')
    shutil.copytree(src, proj, ignore=shutil.ignore_patterns('build'))
    pj = os.path.join(proj, 'project.json')
    d = json.load(open(pj))
    room = next(r for r in d['custom']['rooms'] if r['id'] == 'gate_island')
    npcs = room['screens']['0']['npcs']
    npcs[:] = [n for n in npcs if n.get('kind') != 'npc']        # keep spots only
    for i, (x, y) in enumerate(CELLS):
        npcs.append({'kind': 'npc', 'sprite': f'0x{0xF0 + i:02X}', 'x': x, 'y': y,
                     'facing': 'down', 'script': 'none'})
    json.dump(d, open(pj, 'w'), indent=1)
    outs, _prj, _w = C.compile_project(proj, REPO)
    out = os.path.join(tmp, 'out')
    C.write_outputs(outs, out)
    rom, _sym, md5 = B.build_rom(REPO, out, os.path.join(out, 'build'))
    return rom, md5


def capture(rom, species):
    import numpy as np
    from PIL import Image
    from tools.pyboy_harness import boot, to_bedroom, warp, adv, MAP_ID
    p = boot(rom)
    if not to_bedroom(p):
        raise SystemExit('census: could not reach the bedroom intro')
    m = p.memory
    out = {}
    for b in range(0, len(species), 4):
        batch = species[b:b + 4]
        print(f'  batch {b // 4 + 1}/{(len(species) + 3) // 4}: {batch}', flush=True)
        for i in range(4):
            sp = batch[i] if i < len(batch) else None
            m[0xD7CA + 2 * i] = 0xFF if sp is None else (sp + 0x10) & 0xFF
            m[0xD7CB + 2 * i] = 0 if sp is None else 1
        warp(p, 0x6B, 7, 6, settle=260)
        if m[MAP_ID] != 0x6B:
            raise SystemExit(f'census: warp failed (map {m[MAP_ID]:#x})')
        m[0xCA39] = 0xFF
        m[0xCA3A] = 0x7F
        a = np.asarray(p.screen.image.convert('RGB')).copy()
        slots = []
        for s in range(8):
            base = 0xD7D2 + 32 * s
            if m[base] == 0xFF:
                break
            if 0xF0 <= m[base + 1] <= 0xF3:
                slots.append(base)
        for base in slots:
            m[base] |= 0x40
        adv(p, 3)
        bimg = np.asarray(p.screen.image.convert('RGB')).copy()
        for i, sp in enumerate(batch):
            x, y = CELLS[i]
            box = (x * 16 - 4, y * 16 - 8, x * 16 + 20, y * 16 + 16)
            ca = a[box[1]:box[3], box[0]:box[2]]
            cb = bimg[box[1]:box[3], box[0]:box[2]]
            mask = (ca != cb).any(axis=2)
            rgba = np.zeros(ca.shape[:2] + (4,), dtype=np.uint8)
            rgba[..., :3] = ca
            rgba[..., 3] = np.where(mask, 255, 0)
            ys, xs = np.nonzero(mask)
            if len(xs):
                cx0 = max(0, min(xs.min(), rgba.shape[1] - 16))
                cy0 = max(0, min(ys.min(), rgba.shape[0] - 16))
                crop = rgba[cy0:cy0 + 16, cx0:cx0 + 16]
            else:
                crop = rgba[8:24, 4:20]
            out[sp] = (Image.fromarray(crop, 'RGBA'), int(mask.sum()))
    # (no p.stop(): PyBoy 2.x hangs in stop() after this run; the process exits anyway)
    return out


def parse_species(spec):
    out = []
    for part in spec.split(','):
        if '-' in part:
            a, b = part.split('-')
            out += list(range(int(a), int(b) + 1))
        elif part:
            out.append(int(part))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--species', default='0-216,224')   # 217-220 hang or crash (S101)
    args = ap.parse_args()
    from editor2.core.conversation import species_names
    names = species_names()
    species = parse_species(args.species)
    tmp = tempfile.mkdtemp(prefix='monnpc_')
    try:
        rom, md5 = build_rom(tmp)
        shots = capture(rom, species)
        # a batch can come out blank for one species (four different monster
        # sheets on one screen can exhaust the per-screen sprite-sheet budget,
        # ROOM_DATA_FORMAT S91) — capture those again alone
        again = [sp for sp in species if shots[sp][1] == 0]
        for sp in again:
            shots.update(capture(rom, [sp]))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(OUT_DIR, exist_ok=True)
    index = {}
    for sp in species:
        img, px = shots[sp]
        fn = f'sp_{sp:03d}.png'
        img.save(os.path.join(OUT_DIR, fn))
        index[str(sp)] = {'name': names.get(sp, f'species {sp}'), 'file': fn, 'pixels': px}
    blank = [sp for sp in species if shots[sp][1] == 0]
    data = {'_generator': 'tools/census_monster_npc_sprites.py (S101): PyBoy capture of '
                          'each species as a monster NPC ($F0-$F3 display list) in a build '
                          f'of the example project from data/DWM-original.gbc (build md5 {md5})',
            'cell': 'standing, facing down; 16x16 RGBA, transparent background',
            'blank': blank,
            'species': index}
    json.dump(data, open(OUT_JSON, 'w'), indent=1)
    print(f'{len(species)} species captured ({len(blank)} blank) -> '
          f'{os.path.relpath(OUT_DIR, REPO)}')


if __name__ == '__main__':
    main()
