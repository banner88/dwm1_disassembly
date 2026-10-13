#!/usr/bin/env python3
"""walk_fresh_project.py — S145 (ROADMAP ARC CAP4d): the 4 MB arc's acceptance, machine half —
a FRESH project past 150 places, made in the real editor, built by the editor, walked in the game.

User (S145): "Do a machine version. I dont have time to make a fake 150 room project." The ROADMAP
acceptance of ARC CAP ("the user builds a fresh project in the editor past 150 places") is played
here by driving the editor itself:

  make   — the real editor window (Qt offscreen, `editor2.app.main.MainWindow`): File → New project
           (the blank template), then THE ATLAS HALLS — 160 brand-new rooms "ATLAS HALL 1" …
           "ATLAS HALL 160", each pushed as ONE undo step through the Rooms tab's SnapshotCommand:
           a gate-theme room (the 16 maze looks in turn) with its OWN tileset copy (each sheet also
           carries the hall's number in digits + a signature tile of its own, so no two sheets are
           alike), its own palette, walls, STAIRS up (top right) and down (top left), a GUIDE who
           names the hall and offers to send you ten halls ahead (a script warp — across the
           128-room boundary for halls 119-128 and back from 151-160), a room song; every 20th hall
           is 2 × 2 screens and halls 100 and 150 are 4 × 4 = 16 screens (the engine's ceiling, and
           a claim — "the custom schema accepts 8" — that this walk settles); hall 140 has a SCRIBE
           (save with the JOURNAL there). Stairs link hall n's up to hall n + 1's down (Doors); the
           GreatTree's WELL door (screen 8, (4, 5)) is linked to hall 1's down stairs. Areas "Atlas
           wing A-D" (40 halls each). Halls 129-160 land in the second group of 128 (region 1) by
           the editor's own numbering. Then Save, re-open (timed), the Capacity report (timed), and
           Build through the window's own Build (BuildWorker).
  census — the existing stub censuses on that build: `census_place_banks` (every forwarded read of
           every place) and `census_stale_places` (every per-place reader).
  walk   — PyBoy on the user's .sav (CONTINUE): every hall entered through the warp mailbox with
           its region — the map id, region and screen, then the game's picture of the screen == the
           editor's preview (8 × 8 tiles outside sprites; every screen of the 4 × 4 halls), the
           guide's words (the text ids the game reads == that hall's guide talk); the stairs walked
           up from hall 125 to 131 and back down (126-131 cross the boundary), the guide's YES from
           hall 125 → hall 135 and from hall 155 → hall 5, the GreatTree's Well door → hall 1 and
           its stairs back, the room song of a sample of halls (the `SetBGM` request), and a JOURNAL
           save in hall 140 + CONTINUE → hall 140 in region 1.
           `--negative`: the ROM copy swaps the tileset pointers of two halls of different looks in
           the same bank — exactly those two halls' picture checks must FAIL.

  python3 tools/walk_fresh_project.py make --out DIR [--halls 160]
  python3 tools/walk_fresh_project.py census --out DIR
  python3 tools/walk_fresh_project.py walk --out DIR --sav USER.sav [--keep DIR2] [--negative]
                                           [--only a,b,…]  (halls, talk, stairs, guide, well,
                                           songs, journal)
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`. Needs PySide6 (make) and PyBoy
(walk). PYBOY_DEBUGGING "S145 techniques".
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')

HALLS = 160
WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
DIGIT0 = 0x50                    # sheet slots $50-$59 = the digits 0-9 (theme slots $40-$7F are free)
SIGN = 0x5A                      # a signature tile of the hall's own
PLAQUE = 0x5B                    # a plain plaque tile (cream)
SONGS = ['0x09', '0x1E', '0x31', '0x61']
WELL_DOOR = (0x01, 8, 4, 5)      # GreatTree screen 8 (4, 5) — the Well's door (vanilla dest $18)
GUIDE = (4, 3)
UP, DOWN = (8, 1), (1, 1)
SCRIBE_HALL = 140
BIG = {100: (4, 4), 150: (4, 4)}  # 16-screen halls


def big_of(n):
    if n in BIG:
        return BIG[n]
    return (2, 2) if n % 20 == 0 else (1, 1)


FONT = {                         # 5 × 7
    '0': ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
    '1': ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
    '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
    '3': ['11110', '00001', '00001', '01110', '00001', '00001', '11110'],
    '4': ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
    '5': ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
    '6': ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
    '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
    '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
    '9': ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
}


def tile(pix):
    out = bytearray()
    for row in pix:
        lo = hi = 0
        for c in row:
            lo = (lo << 1) | (c & 1)
            hi = (hi << 1) | (c >> 1)
        out += bytes((lo, hi))
    return bytes(out)


def digit_tile(ch):
    rows = [[1] * 8]
    for r in FONT[ch]:
        rows.append([1] + [3 if b == '1' else 1 for b in r] + [1, 1])
    return tile(rows[:8])


def sign_tile(n):
    """A 4 × 4 pattern of 2 × 2 blocks from the hall's number: no two halls alike."""
    bits = (n * 2654435761) & 0xFFFF
    pix = [[(2 if (bits >> ((y // 2) * 4 + x // 2)) & 1 else 1) for x in range(8)]
           for y in range(8)]
    return tile(pix)


def hall_name(n):
    return f'ATLAS HALL {n}'


def wing(n):
    return 'Atlas wing ' + 'ABCD'[(n - 1) // 40]


# ============================================================== make
def make(out, halls):
    os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
    os.environ.setdefault('QT_AUDIO_BACKEND', 'none')
    from PySide6.QtWidgets import QApplication, QMessageBox
    app = QApplication.instance() or QApplication(sys.argv)
    QMessageBox.warning = staticmethod(lambda *a, **k: None)
    QMessageBox.information = staticmethod(lambda *a, **k: None)
    QMessageBox.question = staticmethod(lambda *a, **k: QMessageBox.Discard)
    from editor2.app.main import MainWindow
    from editor2.app.rooms.commands import SnapshotCommand
    from editor2.core import textenc as T

    def pump(sec=0.0):
        t = time.time()
        while True:
            app.processEvents()
            if time.time() - t >= sec:
                break
            time.sleep(0.01)

    if os.path.exists(out):
        shutil.rmtree(out)
    w = MainWindow()
    w._quiet_build_errors = True
    t0 = time.perf_counter()
    w.new_project(out, name='Atlas Halls (S145 acceptance)')
    pump()
    s = w.session
    print(f'new project from the blank template: {out} ({time.perf_counter() - t0:.1f} s)')

    def B(*paras):
        o = []
        for p in paras:
            o += T.flow_boxes(p, first_box=not o)
        return {'boxes': o}

    rooms = []                                   # (n, room id)

    def paint(d, lid, cx, cy, mt, pal):
        lay = d.layout(lid)
        for i, (dy, dx) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
            lay['tiles'][2 * cy + dy][2 * cx + dx] = mt[i]
            lay['attr'][2 * cy + dy][2 * cx + dx] = pal

    def put(d, lid, tx, ty, t, pal):
        lay = d.layout(lid)
        lay['tiles'][ty][tx] = t
        lay['attr'][ty][tx] = pal

    def floor_pal(d, lid):
        lay = d.layout(lid)
        for rr in range(16):
            for cc in range(20):
                if 0x30 <= lay['tiles'][rr][cc] <= 0x33:
                    return lay['attr'][rr][cc], lay['tiles'][rr][cc]
        return 0, 0x33

    def new_hall(d, n):
        r = s.renderer
        theme = (n - 1) % 16
        rid = d.new_room(hall_name(n), 0, r, gate_theme=theme)
        room = d.room(rid)
        tid = d.localize_tileset(room, r.theme_gfx(theme).sheet, name=f'ts_atlas_{n}')
        sheet = bytearray(d.read_sheet(tid))
        for k in range(10):
            sheet[(DIGIT0 + k) * 16:(DIGIT0 + k) * 16 + 16] = digit_tile(str(k))
        sheet[SIGN * 16:SIGN * 16 + 16] = sign_tile(n)
        sheet[PLAQUE * 16:PLAQUE * 16 + 16] = tile([[1] * 8] * 8)
        d.write_sheet(tid, bytes(sheet))
        room['music'] = SONGS[((n - 1) // 8) % 4]
        cols, rows_ = big_of(n)
        lid0 = room['screens']['0']['layout']['id']
        pal, floor = floor_pal(d, lid0)
        for k in range(rows_ * 4):
            c, rr = k % 4, k // 4
            if c >= cols:
                continue
            if k == 0:
                lid = lid0
            else:
                lid = d.unique_layout_id(f'{rid}_s{k}')
                d.add_layout(lid, tiles=d.blank_grid(floor), attr=d.blank_grid(pal))
                d.add_screen(room, str(k), {'id': lid})
            for cx in range(10):
                if rr == 0:
                    paint(d, lid, cx, 0, WALL, pal)
                if rr == rows_ - 1:
                    paint(d, lid, cx, 7, WALL, pal)
            for cy in range(8):
                if c == 0:
                    paint(d, lid, 0, cy, WALL, pal)
                if c == cols - 1:
                    paint(d, lid, 9, cy, WALL, pal)
            # the hall's number (top halves only: a cell's bottom-right tile decides walking)
            ty = 0 if rr == 0 else 2
            digits = f'{n:>3}'
            put(d, lid, 7, ty, PLAQUE, pal)
            for i, ch in enumerate(digits):
                put(d, lid, 8 + i, ty, PLAQUE if ch == ' ' else DIGIT0 + int(ch), pal)
            put(d, lid, 11, ty, SIGN, pal)
            if k:                                 # a screen's own number, low on the screen
                put(d, lid, 9, 12, PLAQUE, pal)
                for i, ch in enumerate(f'{k:>2}'):
                    put(d, lid, 10 + i, 12, PLAQUE if ch == ' ' else DIGIT0 + int(ch), pal)
        paint(d, lid0, *DOWN, STAIRS, pal)
        if n < halls:
            paint(d, lid0, *UP, STAIRS, pal)
        g = d.add_npc(room, '0', 0, *GUIDE, 0x0B, 'down')
        sc = d.add_npc(room, '0', 0, 7, 5, 0x0C, 'down') if n == SCRIBE_HALL else None
        d.set_room_area(rid, wing(n))
        return rid, g, sc

    t0 = time.perf_counter()
    for n in range(1, halls + 1):
        cmd = SnapshotCommand(s, f'New room {hall_name(n)}', lambda d, n=n: new_hall(d, n))
        s.undo.push(cmd)
        if cmd.error:
            raise SystemExit(f'hall {n}: {cmd.error}')
        rooms.append((n,) + cmd.result)
        if n % 40 == 0:
            pump()
            print(f'  {n} halls ({time.perf_counter() - t0:.1f} s)')
    by_n = {n: (rid, g, sc) for n, rid, g, sc in rooms}

    def mid_of(d, n):
        return int(d.room(by_n[n][0])['mapID'], 16)

    def talks(d):
        for n in range(1, halls + 1):
            rid, g, sc = by_n[n]
            room = d.room(rid)
            m = n + 10 if n + 10 <= halls else n + 10 - halls
            down = 'the GreatTree' if n == 1 else f'hall {n - 1}'
            up = f'hall {n + 1}' if n < halls else 'no stairs up: the last hall'
            steps = [{'say': B(f'{hall_name(n)} of {halls}, in {wing(n)}. Stairs up: '
                               f'{up}. Stairs down: {down}.')},
                     {'ask': B(f'Shall I send you to hall {m}?'),
                      'yes': [{'move': {'dest': f'room:${mid_of(d, m):X}', 'screen': 0,
                                        'x': 5, 'y': 4}}],
                      'no': [{'say': B('Then take the stairs.')}]}]
            sid = d.new_conversation(room, {'steps': steps}, name='guide')
            d.update_npc(room, '0', 0, g, script=sid)
            if sc is not None:
                sid = d.new_conversation(room, {'steps': [{'say': B(
                    f'I am the SCRIBE of hall {n}. Save with the JOURNAL here, turn the game off '
                    'and CONTINUE.', f'You must wake up here, in hall {n}.')}]}, name='scribe')
                d.update_npc(room, '0', 0, sc, script=sid)

    def stairs(d):
        for n in range(1, halls):
            a = d.add_door(by_n[n][0], '0', *UP, name=f'Atlas stairs {n} up')
            b = d.add_door(by_n[n + 1][0], '0', *DOWN, name=f'Atlas stairs {n + 1} down')
            d.link_doors(a, b)
        a = d.add_door(by_n[1][0], '0', *DOWN, name='Atlas stairs 1 down')
        d.link_doors(d.vanilla_door_id(*WELL_DOOR), a)

    for label, op in (('Guides', talks), ('Stairs', stairs)):
        cmd = SnapshotCommand(s, label, op)
        s.undo.push(cmd)
        if cmd.error:
            raise SystemExit(f'{label}: {cmd.error}')
    pump(0.5)
    print(f'{halls} halls made in the editor: {time.perf_counter() - t0:.1f} s; undo steps '
          f'{s.undo.count()}')
    w.save()
    pump(0.5)
    # ---- re-open (timed), the capacity report (timed)
    t0 = time.perf_counter()
    w.open_project(out)
    pump()
    t_open = time.perf_counter() - t0
    from editor2.core import capacity as CAP
    t0 = time.perf_counter()
    rep = CAP.measure(w.session.doc.data, out, REPO)
    t_cap = time.perf_counter() - t0
    print(f're-open {t_open:.1f} s; the capacity report {t_cap:.1f} s; errors {rep["errors"][:2]}')
    for x in rep['rows']:
        if x['key'] in ('rom_space', 'rooms', 'screens_room', 'screens_group', 'texts'):
            print(f"   {x['what'][:60]:60} {x['shown']}  {x['where']}")
    print(f"   about {rep['left']['rooms']} more rooms like the average "
          f"({rep['left']['typical']} B; {rep['left']['by']})")
    # ---- build through the window
    t0 = time.perf_counter()
    w.build()
    while w.worker is not None and w.worker.isRunning():
        pump(0.2)
    pump(0.5)
    res = w.last_result
    if res is None or not res.ok:
        raise SystemExit(f'BUILD FAILED: {getattr(res, "error", "?")}')
    print(f'built in {time.perf_counter() - t0:.0f} s: {res.rom_path} md5 {res.rom_md5}')
    info = {'halls': halls, 'rooms': {str(n): {'id': rid, 'mid': w.session.doc.room(rid)['mapID']}
                                      for n, (rid, _g, _s) in by_n.items()},
            'rom': res.rom_path, 'md5': res.rom_md5, 'open_s': t_open, 'capacity_s': t_cap}
    json.dump(info, open(os.path.join(out, 'acceptance.json'), 'w'), indent=1)
    w.close()


# ============================================================== census
def census(out):
    build = os.path.join(out, 'build', 'build')
    rom, sym = os.path.join(build, 'rom.gbc'), os.path.join(build, 'game.sym')
    ok = True
    for tool in ('census_place_banks', 'census_stale_places'):
        t0 = time.time()
        r = subprocess.run([sys.executable, os.path.join(REPO, 'tools', tool + '.py'),
                            '--project', out, '--rom', rom, '--sym', sym],
                           capture_output=True, text=True)
        tail = (r.stdout + r.stderr).strip().splitlines()[-4:]
        print(f'{tool}: exit {r.returncode} ({time.time() - t0:.0f} s)')
        for ln in tail:
            print('   ', ln)
        ok = ok and r.returncode == 0
    print('CENSUS:', 'PASS' if ok else 'FAIL')
    return ok


# ============================================================== walk
def walk(out, sav, keep, negative, only):
    from tools.walk_regions import Walk, s_continue
    from tools.census_stream_banks import bg_tiles, sprite_tiles, _pad144
    from tools.pyboy_harness import adv, tap, SCREEN_IDX
    from editor2.core.document import Document
    from editor2.core.render_project import ProjectRenderer
    from editor2.core.project import Project
    from editor2.core import formats as F
    info = json.load(open(os.path.join(out, 'acceptance.json')))
    os.makedirs(keep, exist_ok=True)
    build = os.path.join(out, 'build', 'build')
    w = Walk(build, sav, keep)
    doc = Document(os.path.join(out, 'project.json'))
    ren = ProjectRenderer(REPO, out, doc.data, rom_path=ROM)
    prj = Project(json.load(open(os.path.join(out, 'project.json'))), out)
    prj.repo_root = REPO
    plan = prj.stream_plan()
    hall = {int(n): v for n, v in info['rooms'].items()}
    room_of = {n: doc.room(v['id']) for n, v in hall.items()}
    where = {n: (F.mid_real(int(v['mid'], 16)), F.mid_region(int(v['mid'], 16)))
             for n, v in hall.items()}
    swapped = set()
    if negative:
        # two halls of different looks whose tilesets share one bank: swap the pointers
        by_bank = {}
        for n in sorted(hall):
            tid = room_of[n]['record']['tileset']
            b, e = plan['where'][('tileset', tid)]
            by_bank.setdefault(b, []).append((n, e))
        # prefer a new bank $80+ (the 4 MB ROM's overflow banks)
        b, lst = next((b, l) for b, l in sorted(by_bank.items(), key=lambda kv: -kv[0])
                      if len(l) >= 2 and any((x[0] - l[0][0]) % 16 for x in l[1:]))
        (n1, e1), (n2, e2) = lst[0], next(x for x in lst[1:] if (x[0] - lst[0][0]) % 16)
        rom = bytearray(open(w.rom, 'rb').read())
        o1, o2 = b * 0x4000 + 1 + 2 * e1, b * 0x4000 + 1 + 2 * e2
        rom[o1:o1 + 2], rom[o2:o2 + 2] = rom[o2:o2 + 2], rom[o1:o1 + 2]
        open(w.rom, 'wb').write(rom)
        swapped = {n1, n2}
        print(f'NEGATIVE CONTROL: the tileset pointers of halls {n1} and {n2} swapped in bank '
              f'${b:02X} — exactly their picture checks must FAIL')
    s_continue(w)
    w.save('base')
    steps = (only or 'halls,talk,stairs,guide,well,songs,journal').split(',')

    def into(n, k=0, x=None, y=None):
        mid, reg = where[n]
        c, r = k % 4, k // 4
        x = 10 * c + 5 if x is None else x
        y = 8 * r + 5 if y is None else y
        w.goto(mid, reg, x, y)
        return mid, reg

    def picture(n, k):
        room = room_of[n]
        img = w.p.screen.image.copy()
        prev = ren.render_screen(room, str(k))
        g = bg_tiles(img)
        e = bg_tiles(prev.crop((0, 0, 160, 144)) if prev.height >= 144 else _pad144(prev))
        cov = sprite_tiles(w.p)
        diff = [(tx, ty) for ty in range(16) for tx in range(20)
                if (tx, ty) not in cov and g[(tx, ty)] != e[(tx, ty)]]
        return diff, 320 - len([c for c in cov if c[1] < 16])

    if 'halls' in steps:
        print('halls: every hall entered — place, screen, picture (vs the editor preview)')
        bad = []
        for n in sorted(hall):
            cols, rows_ = big_of(n)
            keys = [k for k in range(16) if k % 4 < cols and k // 4 < rows_]
            if n not in (100, 150):
                keys = keys[:1] if cols == 1 else keys
            for k in keys:
                mid, reg = into(n, k)
                got = (w.m[0xC968], w.m[0xD536], w.m[SCREEN_IDX])
                diff, seen = picture(n, k)
                ok = got == (mid, reg, k) and not diff and seen > 200
                exp_fail = n in swapped
                if negative:
                    ok = (bool(diff) == exp_fail) and got == (mid, reg, k)
                if not ok:
                    bad.append(n)
                    w.snap(f'hall{n}_s{k}')
                w.check(f'hall {n} screen {k}: map ${mid:02X} region {reg}, screen {k}; '
                        f'picture == the preview' + (' (must differ: swapped)' if n in swapped
                                                      else ''), ok,
                        f'at ${got[0]:02X} r{got[1]} s{got[2]}; {len(diff)} tiles differ of '
                        f'{seen} compared')
        w.save('halls_done')
    if 'talk' in steps:
        print('talk: every guide says its own hall\'s words (the text ids the game reads)')
        for n in sorted(hall):
            into(n, 0, GUIDE[0], GUIDE[1] + 1)
            w.face('up')
            w.said = []
            res = w.talk(answers=(False,))
            want = f'{hall[n]["id"]}_guide'
            hit = [t for t in w.said if str(t).startswith(want)]
            w.check(f'hall {n}: the guide spoke ({res})', len(hit) >= 2 and res == 'idle',
                    ', '.join(map(str, w.said[-4:])))
    if 'stairs' in steps:
        print('stairs: up from hall 125 to 131 and back down (126 → 131 crosses into the second '
              'group of 128)')
        into(125, 0, UP[0], UP[1] + 1)
        for n in range(125, 131):
            w.face('up')
            w.step('up')
            w.idle()
            mid, reg = where[n + 1]
            w.check_at(f'hall {n} up → hall {n + 1}', mid, reg)
            # from the down stairs' landing to under the up stairs
            for _ in range(UP[0] - DOWN[0]):
                w.step('right')
            w.idle()
        into(131, 0, DOWN[0], DOWN[1] + 1)
        for n in range(131, 125, -1):
            w.face('up')
            w.step('up')
            w.idle()
            mid, reg = where[n - 1]
            w.check_at(f'hall {n} down → hall {n - 1}', mid, reg)
            for _ in range(UP[0] - DOWN[0]):
                w.step('left')
            w.idle()
    if 'guide' in steps:
        print('guide: YES — ten halls ahead by a script warp')
        for a, b_ in ((125, 135), (155, 5), (60, 70)):
            into(a, 0, GUIDE[0], GUIDE[1] + 1)
            w.face('up')
            res = w.talk(answers=(True,))
            w.idle()
            mid, reg = where[b_]
            w.check_at(f'hall {a} guide YES → hall {b_} ({res})', mid, reg)
    if 'well' in steps:
        print('well: the GreatTree\'s Well door → hall 1, its down stairs → the GreatTree')
        # GreatTree screen 8 = grid row 2, column 0: the door (4, 5) is tile (4, 21)
        w.goto(0x01, 0, WELL_DOOR[2], 16 + WELL_DOOR[3] + 1)
        w.face('up')
        w.step('up')
        w.idle()
        mid, reg = where[1]
        w.check_at('the GreatTree Well door → hall 1', mid, reg)
        into(1, 0, DOWN[0], DOWN[1] + 1)
        w.face('up')
        w.step('up')
        w.idle()
        w.check_at('hall 1 down stairs → the GreatTree', 0x01, 0)
        w.check('… on GreatTree screen 8 (the Well door\'s screen)', w.m[SCREEN_IDX] == 8,
                f'screen {w.m[SCREEN_IDX]}')
    if 'songs' in steps:
        print('songs: each hall\'s own song (the room song the game requests on entry)')
        seen = []

        def bgm(_c):
            seen.append(w.p.register_file.A)
        b2, a2 = w.sym['SetBGM']
        w.p.hook_register(b2, a2, bgm, None)
        # the game requests a song only when it differs from the one playing: visit
        # halls whose songs alternate (each differs from the previous one)
        def song(n):
            return int(SONGS[((n - 1) // 8) % 4], 16)
        sample = (1, 9, 17, 25, 120, 127, 129, 137, 128, 130, 150, 160)
        assert all(song(a) != song(b) for a, b in zip(sample, sample[1:]))
        for n in sample:
            seen.clear()
            into(n, 0)
            want = song(n)
            w.check(f'hall {n}: song ${want:02X}', want in seen,
                    ' '.join(f'${x:02X}' for x in seen[-6:]))
        w.p.hook_deregister(b2, a2)
    if 'journal' in steps:
        print(f'journal: save in hall {SCRIBE_HALL} (the second group), CONTINUE → there')
        into(SCRIBE_HALL, 0, 5, 5)
        w.face('down')
        p = w.p
        b, a = w.sym['SaveGameState']
        saved = []
        p.hook_register(b, a, lambda _c: saved.append(1), None)
        tap(p, 'a', hold=3, wait=90)                  # the field menu
        tap(p, 'down', hold=6, wait=20)
        tap(p, 'right', hold=6, wait=20)
        tap(p, 'a', hold=3, wait=60)                  # OPTN
        for _ in range(3):
            tap(p, 'down', hold=6, wait=20)
        tap(p, 'a', hold=3, wait=90)                  # JOURNAL
        tap(p, 'a', hold=3, wait=200)                 # YES
        for _ in range(10):
            if saved:
                break
            tap(p, 'a', hold=3, wait=60)
        adv(p, 300)
        w.check('the JOURNAL saved', bool(saved))
        p.hook_deregister(b, a)
        p.stop(save=True)                              # PyBoy writes <rom>.ram
        ram = os.path.join(keep, 'journal.sav')
        shutil.copy(w.rom + '.ram', ram)
        w2 = Walk(build, ram, keep)
        w2.rom = w.rom
        s_continue(w2)
        mid, reg = where[SCRIBE_HALL]
        w2.check_at(f'CONTINUE → hall {SCRIBE_HALL}', mid, reg)
        w.checks += w2.checks
        w.fails += w2.fails
        w.p = w2.p
    print(f'WALK: {"PASS" if not w.fails else "FAIL"}' + (f' {w.fails}' if w.fails else '')
          + f'  ({w.checks} checks)')
    w.p.stop(save=False)
    return w.fails == 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', choices=('make', 'census', 'walk'))
    ap.add_argument('--out', required=True)
    ap.add_argument('--halls', type=int, default=HALLS)
    ap.add_argument('--sav')
    ap.add_argument('--keep')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--only')
    a = ap.parse_args()
    if a.what == 'make':
        make(os.path.abspath(a.out), a.halls)
    elif a.what == 'census':
        sys.exit(0 if census(os.path.abspath(a.out)) else 1)
    else:
        keep = a.keep or os.path.join(os.path.abspath(a.out), 'walk')
        sys.exit(0 if walk(os.path.abspath(a.out), a.sav, keep, a.negative, a.only) else 1)


if __name__ == '__main__':
    main()
