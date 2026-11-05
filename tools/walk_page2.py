#!/usr/bin/env python3
"""walk_page2.py — PAGE 2 in the game (S168, ROADMAP P3.3g): a build of
examples/s168_page2_demo (THE NUMBERED GALLERY, 168 numbered tiles) walked on a real save.

Checks (PyBoy):
  * entering the gallery: wPage2On = 1; VRAM bank 1 $9000-$97FF == the tileset's page 2
    (the blinking strip's slots: one of the animation's frames); VRAM bank 0 == page 1;
    every visible cell shows the tile + VRAM bank the project grid says (both screens);
    more than 128 different (tile, bank) pairs on screen 0;
  * the blinking strip changes in VRAM bank 1 only, with the authored frames;
  * every window of the game over page-2 cells — the curator's YES / NO, the shop, Grandpa,
    the field menu (ITEM), the Vault, the library (a full screen), a battle (won): sampled
    every 2 frames, NO visible cell shows a shared font / window tile ($80-$FF) from VRAM
    bank 1 (attribute bit 3), NO visible room cell shows a slot the window drew into (S168 r2:
    Grandpa's words over the floor), and after it the room is whole again (tiles, banks, page 2);
  * leaving to the city: wPage2On = 0, no visible cell has attribute bit 3.
  --negative: wPage2On forced to 0 every frame (the boxes / windows then keep bit 3 under
  their letters) — the overlay checks MUST fail.

    python3 tools/walk_page2.py --build <build dir with rom.gbc + game.sym> --project <dir>
        --sav <.sav> [--keep DIR] [--negative]
"""
import argparse
import json
import os
import shutil
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, GAME_MODE                    # noqa: E402
from tools.walk_regions import Walk, s_continue                       # noqa: E402
from editor2.core import page2 as P2                                  # noqa: E402

GALLERY_NAME = 'NUMBERED GALLERY'
_A, _B, _D, _U, _R = ('a', 90), ('b', 60), ('down', 30), ('up', 30), ('right', 30)
# (what, stand at (abs x, y), face, answers, keys after the talk opened, kind)
TOUR = [
    ('the curator (YES / NO, NO)', (2, 3), 'up', [False], None, 'talk'),
    ('the shop', (5, 5), 'down', None,
     [_A, _A, _A, _A, _D, _A, _B, _B, _D, _A, _A, _A, _A] + [_B] * 6, 'keys'),
    ('Grandpa (breeding)', (7, 4), 'up', None,
     [_A] * 7 + [_B, _B, _D, _A, _A, _A, _A] + [_B] * 9, 'keys'),
    ('the field menu (ITEM)', (4, 5), 'right', None,
     [('a', 60), ('right', 30)] + [('a', 80)] * 6 + [('b', 60)] * 6, 'menu'),
    ('the Vault', (12, 3), 'up', None,
     [_A] * 5 + [_B, _B, _D, _A, _A, _A, _B, _B, _R, _A, _A, _A] + [_B] * 8, 'keys'),
    ('the library (a full screen)', (15, 5), 'down', None,
     [_A] * 7 + [_B, _D, _A, _A, _B, _R, _A, _A] + [_B] * 8, 'keys'),
    ('the sparring slime (a battle, won)', (17, 4), 'up', [True], None, 'battle'),
]


class Gallery:
    def __init__(self, project):
        pj = json.load(open(os.path.join(project, 'project.json')))
        c = pj['custom']
        self.room = next(r for r in c['rooms'] if r.get('name') == GALLERY_NAME)
        self.mid = int(self.room['mapID'], 16)
        tid = self.room['record']['tileset']
        ts = next(t for t in c['tilesets'] if t['id'] == tid)
        self.sheet = open(os.path.join(project, ts['raw2bpp']), 'rb').read()
        lays = {la['id']: la for la in c['layouts']}
        self.grids = {int(k): lays[s['layout']['id']]['tiles']
                      for k, s in self.room['screens'].items()}
        anim = (self.room.get('tile_anims') or [None])[0]
        self.strip = [s for row in anim['rows'] for s in row] if anim else []
        self.strip_frames = []
        if anim:
            self.strip_frames.append([self.sheet[s * 16:s * 16 + 16] for s in self.strip])
            for f in anim['frames']:
                self.strip_frames.append([bytes.fromhex(h) for h in f])


def vram(m, bank, a, b):
    return bytes(m[bank, a:b - 1]) + bytes([m[bank, b - 1]])


def visible_cells(m):
    """[(map addr, row, col, tile, attr)] of the cells on screen: the BG (minus what the
    window covers) and the window."""
    lc, scx, scy, wy, wx = m[0xFF40], m[0xFF43], m[0xFF42], m[0xFF4A], m[0xFF4B]
    out = []
    win = bool(lc & 0x20) and wy < 144 and wx < 167
    bg = 0x9C00 if lc & 0x08 else 0x9800
    for r in range(19):
        for c in range(21):
            y, x = r * 8 - (scy % 8), c * 8 - (scx % 8)
            if y >= 144 or x >= 160:
                continue
            if win and y >= wy and x + 7 >= wx - 7:
                continue
            a = bg + ((scy // 8 + r) % 32) * 32 + ((scx // 8 + c) % 32)
            out.append((a, r, c, m[0, a], m[1, a]))
    if win:
        wb = 0x9C00 if lc & 0x40 else 0x9800
        for r in range(0, (144 - wy + 7) // 8):
            for c in range(0, (167 - wx + 7) // 8 + 1):
                a = wb + (r % 32) * 32 + (c % 32)
                out.append((a, 100 + r, c, m[0, a], m[1, a]))
    return out


def _tile16(m, bank, t):
    a = 0x9000 + 16 * t if t < 0x80 else 0x8800 + 16 * (t - 0x80)
    return bytes(m[bank, a:a + 16])


def letters_from_bank1(m):
    """Visible cells that draw a shared font / window tile ($80-$FF) from VRAM bank 1 whose
    bytes there differ from bank 0's (what the game meant to show)."""
    out = []
    for a, _r, _c, t, at in visible_cells(m):
        if at & 0x08 and t >= 0x80 and _tile16(m, 1, t) != _tile16(m, 0, t):
            out.append((a, t, at))
    return out


def room_art_damage(m, ref, skip=()):
    """S168 r2 (the user: "Breed/hatch/exit menu ... creates visual glitches of words on the
    screen"): visible cells that still show the room (map tile + attribute as at `ref` time)
    whose tile ($00-$7F, VRAM bank by attribute bit 3) no longer holds the room's graphic — a
    menu drew into a slot the room shows. `skip` = slots (0-255) the room animates.
    -> ({slot}, number of room cells seen)."""
    mp, v = ref
    out, room = set(), 0
    for a, r, _c, t, at in visible_cells(m):
        if r >= 100 or (t, at) != mp.get(a) or t >= 0x80:
            continue
        room += 1
        b = (at >> 3) & 1
        if b * 128 + t in skip:
            continue
        if bytes(m[b, 0x9000 + t * 16:0x9010 + t * 16]) != v[b][t * 16:t * 16 + 16]:
            out.add(b * 128 + t)
    return out, room


def room_ref(m):
    return ({a: (m[0, a], m[1, a]) for a in range(0x9800, 0x9C00)},
            {b: vram(m, b, 0x9000, 0x9800) for b in (0, 1)})


def room_whole(w, g, m, what):
    """The room as the grid says + page 2 in VRAM bank 1."""
    scx, scy = m[0xFF43], m[0xFF42]
    key = (scy // 128) * 4 + scx // 160
    grid = g.grids.get(key)
    bad = []
    for r in range(16):
        for c in range(20):
            a = 0x9800 + ((scy // 8 + r) % 32) * 32 + ((scx // 8 + c) % 32)
            want = grid[r][c]
            got_t, got_b = m[0, a], (m[1, a] >> 3) & 1
            if got_t != P2.byte_of(want) or got_b != (1 if P2.is_page2(want) else 0):
                bad.append((r, c))
    w.check(f'{what}: screen {key} shows every tile from its page (320 cells)', not bad,
            f'{len(bad)} wrong, e.g. {bad[:4]}')
    v1 = vram(m, 1, 0x9000, 0x9800)
    sheet2 = g.sheet[2048:4096]
    wrong = []
    for s in range(128):
        got = v1[s * 16:s * 16 + 16]
        if got == sheet2[s * 16:s * 16 + 16]:
            continue
        slot = 128 + s
        if slot in g.strip:
            k = g.strip.index(slot)
            if any(fr[k] == got for fr in g.strip_frames):
                continue
        wrong.append(slot)
    w.check(f'{what}: VRAM bank 1 holds page 2 (the strip: one of its frames)', not wrong,
            f'slots {wrong[:6]}')
    v0 = vram(m, 0, 0x9000, 0x9800)
    w.check(f'{what}: VRAM bank 0 holds page 1', v0 == g.sheet[:2048],
            f'{sum(1 for s in range(128) if v0[s*16:s*16+16] != g.sheet[s*16:s*16+16])} slots differ')
    return key


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep')
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args()
    keep = a.keep or tempfile.mkdtemp(prefix='walk_page2_')
    os.makedirs(keep, exist_ok=True)
    g = Gallery(a.project)
    w = Walk(a.build, a.sav, keep)
    shutil.copy(os.path.join(a.build, 'rom.gbc'), w.rom)
    s_continue(w)
    if a.negative:
        print('NEGATIVE CONTROL: wPage2On forced to 0 every frame — the overlay checks must fail')
    w.goto(g.mid, 0, 4, 5)
    m = w.m
    w.check('the gallery reached', w.where() == (g.mid, 0), f'at ${w.where()[0]:02X}')
    w.check('wPage2On = 1 in the gallery', m[w.sym['wPage2On'][1]] == 1)
    room_whole(w, g, m, 'arrival')
    pairs = {(t, (at >> 3) & 1) for _a, _r, _c, t, at in visible_cells(m) if _r < 16}
    w.check('more than 128 different tiles on screen 0 (S168 r2: 168 — page-1 $38-$7F stay '
            "free for Grandpa's screens)", len(pairs) > 128, f'{len(pairs)}')
    w.snap('arrival')
    # the blinking strip: bank 1 only
    seen = set()
    v0a = vram(m, 0, 0x9000, 0x9800)
    for _ in range(12):
        adv(w.p, 8)
        seen.add(vram(m, 1, 0x9000 + (g.strip[0] - 128) * 16, 0x9000 + (g.strip[0] - 127) * 16))
    w.check('the page-2 strip blinks (VRAM bank 1 shows both frames)', len(seen) == 2, f'{len(seen)}')
    w.check('… and VRAM bank 0 does not change', vram(m, 0, 0x9000, 0x9800) == v0a)
    w.save('gallery')
    pw = w.sym['wPage2On']

    arrival0 = vram(m, 0, 0x8800, 0x9000)
    rewritten = set()                    # shared tiles ($80-$FF) a window rewrote in bank 0

    def sample(bad, f, dmg=None, ref=None):
        if a.negative:
            m[pw[1]] = 0
        hits = letters_from_bank1(m)
        if hits:
            bad.append((f, hits[:3], len(hits)))
        if ref is not None:
            d, n = room_art_damage(m, ref, set(g.strip))
            if n >= 60 and d:
                dmg.append((f, sorted(d)))
        if f % 20 == 0:
            now = vram(m, 0, 0x8800, 0x9000)
            for t in range(128):
                if now[t * 16:t * 16 + 16] != arrival0[t * 16:t * 16 + 16]:
                    rewritten.add(0x80 + t)

    for what, (x, y), face, answers, keys, kind in TOUR:
        w.start('gallery')
        m = w.m
        w.goto(g.mid, 0, x, y)
        w.face(face)
        bad, shots, dmg = [], 0, []
        f = 0
        ref = room_ref(m)

        def run(n):
            nonlocal f
            for _ in range(n // 2):
                adv(w.p, 2)
                f += 2
                sample(bad, f, dmg, ref)
        if a.negative:
            m[pw[1]] = 0
        if kind == 'talk':
            w.p.hook_register(0, 0x0040, lambda _c: sample(bad, -1), None) if False else None
            tap(w.p, 'a', hold=3, wait=6)
            for _ in range(60):
                run(20)
                if m[0xC83C] == 1:
                    run(30)
                    w.snap(f'tour_{TOUR.index((what, (x, y), face, answers, keys, kind))}')
                    shots += 1
                    tap(w.p, 'down', hold=6, wait=12)
                    tap(w.p, 'a', hold=3, wait=10)
                    m[0xC83C] = 0
                    break
                tap(w.p, 'a', hold=2, wait=4)
            run(400)
            for _ in range(6):
                tap(w.p, 'a', hold=2, wait=10)
                run(40)
        elif kind == 'battle':
            m[0xC83C] = 0
            res = w.talk(answers)
            w.check(f'{what}: a battle began', res == 'battle', res)
            if res == 'battle':
                w.battle_won()
            run(200)
            for _ in range(8):
                tap(w.p, 'a', hold=2, wait=10)
                run(30)
        else:
            if kind == 'keys':
                tap(w.p, 'a', hold=3, wait=6)
                run(60)
            for i, (k, n) in enumerate(keys):
                if k != 'w':
                    w.p.button_press(k)
                    run(4)
                    w.p.button_release(k)
                run(n)
                if i in (3, 8):
                    w.snap(f'tour_{TOUR.index((what, (x, y), face, answers, keys, kind))}_{i}')
                    shots += 1
            run(200)
        w.check(f'{what}: no letter / window tile read from VRAM bank 1 while it was open '
                f'({f // 2} samples)', not bad,
                f'first at frame {bad[0][0]}: {[(hex(x_), hex(t_), hex(a_)) for x_, t_, a_ in bad[0][1]]} '
                f'({bad[0][2]} cells), {len(bad)} samples bad' if bad else '')
        allslots = sorted({x for _f, d in dmg for x in d})
        w.check(f'{what}: no room cell showed a slot the window drew into (S168 r2)', not dmg,
                f"first at frame {dmg[0][0]}; slots {' '.join(P2.label(P2.value_of(x)) for x in allslots[:12])}"
                if dmg else '')
        w.idle()
        for _ in range(4):
            tap(w.p, 'b', wait=20)
        w.idle()
        w.check(f'{what}: back in the gallery', w.where() == (g.mid, 0), f'at ${w.where()[0]:02X}')
        if w.where() == (g.mid, 0):
            if a.negative:
                m[pw[1]] = 0
            room_whole(w, g, m, f'after {what}')
            w.check(f'after {what}: wPage2On = 1', a.negative or m[pw[1]] == 1)
        w.snap(f'after_{TOUR.index((what, (x, y), face, answers, keys, kind))}')
    # leaving: the city
    w.start('gallery')
    m = w.m
    city = 0x6E
    w.goto(city, 0, 3, 5)
    w.check('the city reached', w.where() == (city, 0))
    w.check('wPage2On = 0 in a room without page 2', m[pw[1]] == 0)
    n3 = sum(1 for _a, _r, _c, _t, at in visible_cells(m) if at & 0x08)
    w.check('no visible cell has attribute bit 3 there', n3 == 0, f'{n3}')
    print('shared tiles a window rewrote in VRAM bank 0:',
          ' '.join(f'${t:02X}' for t in sorted(rewritten)))
    print(f'{w.checks - w.fails} / {w.checks} checks passed' + (f', {w.fails} FAILED' if w.fails else ''))
    print('screenshots:', keep)
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
