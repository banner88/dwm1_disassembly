#!/usr/bin/env python3
"""walk_library.py — the LIBRARY in a project room, walked on a real save (S177).

The user (S177): "Visual glitches in library room. Why is monster palette wrong? Why does
description have part of a tile in it?" — measured: bank $77 ScreenPush re-wrote the
attributes of the library's full screen on every push in a free-colour / page-2 room (the
picture on palette 7; a letter whose slot number equalled the room tile under it given the
room's attribute back — VRAM bank 1). Fixed S177: the library (op $04 type 8) pushes tiles
only, as the original (ROOM_DATA_FORMAT "The game's menus draw into the room's tile slots").

Checks (PyBoy, the project's librarian found by its service kind):
  * the family list and a monster's page: EVERY visible cell has the attribute the original
    game gives it — the picture (rows 1-6, columns 1-6 of the page) palette 4, every other
    cell palette 7, VRAM bank 0 (measured on the original ROM S177: map $12's librarian);
  * the page's BG palette 4 in the hardware == the monster's battle palette (bank $17
    MonsterBattlePalettes row, as bank $17 entry 6 loads it);
  * sampled every 2 frames while the library is open: no visible cell reads a tile from VRAM
    bank 1 whose bytes there differ from bank 0 (except a room cell exactly as it was);
  * after the farewell: the room is whole (the visible map, tiles + attributes, and both VRAM
    banks' $9000-$97FF == before the talk, the room's animated slots aside).
  --podium (S177, the podium proxy): the same session opened from the podium cell (an
  examine spot that `talks_for` the librarian) — the same texts in the same order as talking
  to the librarian, the same flags set, the librarian turned to face the player.
  --negative: the S177 branch broken in the ROM copy (ScreenPush's `cp $08` -> `cp $FF`):
  the attribute / palette checks MUST fail.

    python3 tools/walk_library.py --build <dir with rom.gbc + game.sym + manifest.json>
        --project <dir> --sav <.sav> [--keep DIR] [--negative] [--podium]
"""
import argparse
import json
import os
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, PLAYER_TX, PLAYER_TY       # noqa: E402
from tools.walk_regions import Walk, s_continue                       # noqa: E402
from tools.walk_page2 import visible_cells, room_ref                  # noqa: E402

PIC = {(r, c) for r in range(1, 7) for c in range(1, 7)}   # the picture's cells on the page
W_GAMESTATE, SCREEN_TYPE, LIB_OPEN = 0xC8EB, 0xC8EF, 0xC8EC
SPECIES_SHOWN = 0xCAC0
FLAG_BASE = 0xD99B
FACE_HRAM = 0xFF8E            # the player's facing: 0 down, 1 left, 2 up, 3 right
NPC_SLOTS = 0xD7D2            # NPC n = slot n-1, 32 bytes (+$06 facing 0-3, ROOM_DATA_FORMAT)
DIRS = {'down': (0, 1), 'up': (0, -1), 'left': (-1, 0), 'right': (1, 0)}
FACE_OF = {'down': 0, 'left': 1, 'up': 2, 'right': 3}


def find_librarian(pj):
    """(room, screen key, npc dict, its index among the screen's NPC entries, podium spot or
    None) of the first NPC whose script is a library service."""
    c = pj['custom']
    lib = {s['id'] for s in c.get('scripts', []) if (s.get('service') or {}).get('kind') == 'library'}
    for r in c['rooms']:
        for k, scr in (r.get('screens') or {}).items():
            ents = scr.get('npcs') or []
            npcs = [e for e in ents if isinstance(e, dict) and e.get('kind') == 'npc']
            for i, e in enumerate(npcs):
                if e.get('script') in lib:
                    pod = next((x for x in ents if isinstance(x, dict) and x.get('kind') == 'examine'
                                and x.get('talks_for') is not None), None)
                    return r, int(k), e, i, pod
    raise SystemExit('no library NPC in the project')


def bank1_letters(m, ref):
    """Visible cells drawing a tile from VRAM bank 1 that differs from bank 0's, minus room
    cells exactly as they were (`ref` = room_ref before the talk)."""
    mp = ref[0]
    out = []
    for a, _r, _c, t, at in visible_cells(m):
        if not at & 0x08 or mp.get(a) == (t, at):
            continue
        base = 0x9000 + 16 * t if t < 0x80 else 0x8800 + 16 * (t - 0x80)
        if bytes(m[1, base:base + 16]) != bytes(m[0, base:base + 16]):
            out.append((a, t, at))
    return out


def page2_from_bank0(m, ref):
    """S177 r2 (the user: "glitch on screen when opening menu (very briefly in background
    just before menu appears)"): visible cells that still hold a PAGE-2 room tile (its
    number and bank-1 attribute before the talk) but whose attribute now reads VRAM bank 0 —
    the page-1 tile of the same number in the menu's colours. -> [(addr, tile, attr)]."""
    mp = ref[0]
    out = []
    for a, _r, _c, t, at in visible_cells(m):
        was = mp.get(a)
        if was and t < 0x80 and was[0] == t and was[1] & 0x08 and not at & 0x08:
            out.append((a, t, at))
    return out


def page_attrs(m, with_picture):
    """[(row, col, tile, attr)] of the 18 x 20 screen whose attribute is not the original's."""
    scx, scy = m[0xFF43], m[0xFF42]
    bad = []
    for r in range(18):
        for c in range(20):
            a = 0x9800 + ((scy // 8 + r) % 32) * 32 + ((scx // 8 + c) % 32)
            want = 0x04 if with_picture and (r, c) in PIC else 0x07
            if m[1, a] != want:
                bad.append((r, c, m[0, a], m[1, a]))
    return bad


def hw_pal(m, i):
    out = []
    for c in range(4):
        m[0xFF68] = i * 8 + c * 2
        lo = m[0xFF69]
        m[0xFF68] = i * 8 + c * 2 + 1
        out.append(m[0xFF69] << 8 | lo)
    return out


def rom_pal(rom, sym, species):
    b, a = sym.get('MonsterBattlePalettes') or sym['RoomAttrDataBlocks']
    o = b * 0x4000 + (a - 0x4000) + 8 * species
    return [rom[o + 2 * k] | rom[o + 2 * k + 1] << 8 for k in range(4)]


class LibWalk(Walk):
    def start(self, state=None):
        super().start(state)
        b, a = self.sym['TextBankDispatch']
        self.p.hook_register(b, a, self._vtext, None)

    def _vtext(self, _ctx):
        # ROM0 TextBankDispatch: HL = the game's text id (PyBoy 2.x register_file)
        self.said.append(f'${self.p.register_file.HL:04X}')

    def flags(self):
        return bytes(self.m[FLAG_BASE:FLAG_BASE + 0x40]) + bytes(self.m[0xD140:0xD240])

    def run(self, keys, ref, bad, label):
        """keys = [(button, frames after)]; sample every 2 frames while the library shows."""
        m = self.m
        for btn, wait in keys:
            if btn:
                tap(self.p, btn, hold=3, wait=2)
            for _ in range(0, wait, 2):
                adv(self.p, 2)
                if m[W_GAMESTATE] & 0x10 and m[SCREEN_TYPE] == 8:
                    for x in bank1_letters(m, ref):
                        bad.setdefault(label, []).append(x)
                for x in page2_from_bank0(m, ref):            # S177 r2: the opening's frames
                    bad.setdefault('page-2 room cell drawn from bank 0', []).append(x)


def session(w, opener, ref, rom, tag):
    """One library visit: opened by `opener()` (a talk), the family list, the first family,
    down x 4, the monster's page, back out, the farewell. -> the checks of the pages."""
    m = w.m
    bad = {}
    opener()
    w.run([('a', 100)] * 8, ref, bad, 'intro')
    for _ in range(40):                         # until the family list waits for a pick
        if m[W_GAMESTATE] & 0x10 and m[SCREEN_TYPE] == 8 and m[LIB_OPEN] == 1 and not m[0xC8EB] & 1:
            break
        w.run([('a', 60)], ref, bad, 'intro')
    w.run([(None, 60)], ref, bad, 'list')
    w.snap(f'{tag}_list')
    lst = page_attrs(m, False)
    w.check(f'{tag}: the family list — every cell palette 7, VRAM bank 0 (as the original)',
            not lst, f'{len(lst)} cells differ, e.g. {lst[:4]}')
    w.run([('a', 100), ('a', 100)] + [('down', 40)] * 4 + [('a', 260)], ref, bad, 'page')
    w.snap(f'{tag}_page')
    sp = m[SPECIES_SHOWN]
    pg = page_attrs(m, True)
    w.check(f'{tag}: the monster page (species {sp}) — the picture palette 4, every other cell 7, '
            'VRAM bank 0 (as the original)', not pg, f'{len(pg)} cells differ, e.g. {pg[:4]}')
    hw, want = hw_pal(m, 4), rom_pal(rom, w.sym, sp)
    w.check(f'{tag}: BG palette 4 == the monster\'s battle palette',
            hw == want, f"hardware {' '.join(f'{x:04X}' for x in hw)} / ROM "
            f"{' '.join(f'{x:04X}' for x in want)}")
    w.run([('b', 100)] * 5, ref, bad, 'close')
    w.idle(maxf=4000)
    leaks = sum(len(v) for v in bad.values())
    w.check(f'{tag}: sampled every 2 frames from the talk — no library cell read from VRAM bank 1, '
            'no page-2 room cell drawn from bank 0 (the opening, S177 r2)', not leaks,
            '; '.join(f'{k}: {len(v)} e.g. {[(hex(a), hex(t), hex(at)) for a, t, at in v[:2]]}'
                      for k, v in bad.items()))
    return sp


def room_back(w, ref, anim, tag):
    m = w.m
    mp, v = ref
    now = room_ref(m)
    cells = [a for a in mp if 0x9800 <= a < 0x9C00]
    vis = {a for a, *_ in visible_cells(m) if a < 0x9C00}
    diff = [hex(a) for a in cells if a in vis and now[0][a] != mp[a]]
    w.check(f'{tag}: the room is back — every visible cell (tile + attribute) as before', not diff,
            f'{len(diff)} differ, e.g. {diff[:4]}')
    slots = [b * 128 + s for b in (0, 1) for s in range(128)
             if b * 128 + s not in anim and now[1][b][s * 16:s * 16 + 16] != v[b][s * 16:s * 16 + 16]]
    w.check(f'{tag}: both VRAM banks hold the room\'s tiles again', not slots,
            f'slots {slots[:8]}')


def animated(w):
    m = w.m
    a = room_ref(m)[1]
    seen = set()
    for _ in range(8):
        adv(w.p, 16)
        b = room_ref(m)[1]
        seen |= {k * 128 + s for k in (0, 1) for s in range(128)
                 if a[k][s * 16:s * 16 + 16] != b[k][s * 16:s * 16 + 16]}
    return seen


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--negative-open', action='store_true')
    ap.add_argument('--podium', action='store_true')
    args = ap.parse_args()
    keep = args.keep or tempfile.mkdtemp(prefix='walk_library_')
    os.makedirs(keep, exist_ok=True)
    w = LibWalk(args.build, args.sav, keep)
    if args.negative_open:
        # S177 r2: LibraryOpen's far call back to the original's (`ld hl, $170a`)
        rom = bytearray(open(w.rom, 'rb').read())
        o = 0x12 * 0x4000
        k = rom.find(bytes([0x21, 0x23, 0x77, 0xD7]), o, o + 0x4000)
        if k < 0:
            raise SystemExit('bank $12: no `ld hl, $7723 / rst $10`')
        rom[k + 1:k + 3] = bytes([0x0A, 0x17])
        open(w.rom, 'wb').write(rom)
        print(f'NEGATIVE CONTROL: LibraryOpen at $12:{0x4000 + k % 0x4000:04X} calls bank $17 '
              'entry 10 directly again')
    if args.negative:
        b, a = w.sym['ScreenPush']
        rom = bytearray(open(w.rom, 'rb').read())
        o = b * 0x4000 + a - 0x4000
        k = rom.find(bytes([0xFE, 0x08, 0x20]), o, o + 0x30)
        if k < 0:
            raise SystemExit('ScreenPush: no `cp $08` found')
        rom[k + 1] = 0xFF
        open(w.rom, 'wb').write(rom)
        print(f'NEGATIVE CONTROL: ScreenPush\'s library test at ${b:02X}:{0x4000 + k % 0x4000:04X} '
              'broken (cp $08 -> cp $FF)')
    rom = open(w.rom, 'rb').read()
    pj = json.load(open(os.path.join(args.project, 'project.json')))
    room, key, npc, idx, pod = find_librarian(pj)
    mid = int(str(room['mapID']), 16)
    col, row = key % 4, key // 4
    print(f"the librarian: room {room.get('name')} (${mid:02X}) screen {key} cell ({npc['x']},{npc['y']})")
    s_continue(w)
    w.save('cont')

    def stand(cell, face):
        x, y = cell
        ok = w.goto(mid, 0, col * 10 + x, row * 8 + y)
        w.face(face)
        w.idle()
        return ok and (w.m[PLAYER_TX], w.m[PLAYER_TY]) == (col * 10 + x, row * 8 + y)

    # beside the librarian, facing it (left of it, else right of it, else above)
    for d in ('right', 'left', 'down'):
        dx, dy = DIRS[d]
        cell = (npc['x'] - dx, npc['y'] - dy)
        if stand(cell, d):
            break
    else:
        raise SystemExit('could not stand beside the librarian')
    print(f'  standing at {cell}, facing {d}')
    anim = animated(w)
    ref = room_ref(w.m)
    f0 = w.flags()
    w.said = []
    sp = session(w, lambda: tap(w.p, 'a', hold=3, wait=6), ref, rom, 'librarian')
    said_npc, f_npc = list(w.said), w.flags()
    room_back(w, ref, anim, 'librarian')

    if args.podium:
        if pod is None:
            raise SystemExit('--podium: no examine spot that talks_for the librarian')
        # the same visit from the podium, from the save's state (the first-time lines again)
        w.start('cont')
        pf = pod.get('facing', 'up')
        dx, dy = DIRS[pf]
        cell = (pod['x'] - dx, pod['y'] - dy)
        w.check('podium: standing in front of the podium', stand(cell, pf))
        w.m[NPC_SLOTS + 32 * idx + 6] = 3                       # the librarian turned away (right)
        ref2 = room_ref(w.m)
        w.said = []
        f1 = w.flags()
        w.check('podium: the flags before == before the librarian talk', f1 == f0)
        turned = []

        def open_podium():
            tap(w.p, 'a', hold=3, wait=6)
            for _ in range(30):
                adv(w.p, 2)
                turned.append(w.m[NPC_SLOTS + 32 * idx + 6])
        sp2 = session(w, open_podium, ref2, rom, 'podium')
        want_face = FACE_OF[{'up': 'down', 'down': 'up', 'left': 'right', 'right': 'left'}[pf]]
        w.check('podium: the librarian turned to face the player', want_face in turned,
                f'facing seen {sorted(set(turned))}, want {want_face}')
        w.check('podium: the same texts in the same order as the librarian', w.said == said_npc,
                f'{len(w.said)} vs {len(said_npc)}')
        w.check('podium: the same flags afterwards as the librarian', w.flags() == f_npc)
        w.check('podium: the same monster page', sp2 == sp)
        room_back(w, ref2, anim, 'podium')

    print(f"\n{w.checks - w.fails} / {w.checks} checks passed" + ('  (NEGATIVE CONTROL)' if args.negative else ''))
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
