#!/usr/bin/env python3
"""walk_ending.py — S153 (ROADMAP E5): a romhack's TITLE, its FINAL SCENE, the CREDITS,
"TO BE CONTINUED" and the post-game — made in the editor, then played in the game (PyBoy).

User (S153): "If intro has "Milayou's Journey" or whatever text I want added to it that
would be cool. The final cutscene before credits also should be editable and you can send a
given cutscene to credits. Anything connected to this is also fine."

  make  — the REAL editor window (Qt offscreen, editor2.app.main.MainWindow): File → New
          project, then (help topic `76_ending.md`):
            Cutscenes → Title & ending… (EndingDialog, driven through its widgets):
              the title lines "Milayou's Journey" (orange, row 13, centred) and
              "S153 ENDING DEMO" (red, row 2); the credits: the game's 27 pages + 2 new ones
              before the closing page (ROMHACK / MILAYOU'S JOURNEY with a DragonKid,
              THANK YOU FOR / PLAYING! with a WingSlime), 2 seconds a page;
            THE LAST GLADE (new, GreatTree's tileset, own violet dusk colours): the ENDING
              SAGE — a talk scene: "Shall the tale end?" YES → the original game's story
              point "everything done" (the arena classes too), the flag journey_over ON,
              Roll the credits → THE AFTER ROOM; NO → "Come back when you are ready.";
            THE AFTER ROOM (new, the Farm's tileset, own golden colours), the AFTER KEEPER:
              entry scene 1 (once tbc_shown): his words, then "…TO BE CONTINUED" (the save);
              talk scene (when tbc_shown ON, once post_game_seen) — after CONTINUE (which
              plays no entry scene): his post-game words, then a move to the game's own
              Castle (screen 1, cell (5, 6));
            New game… → starts in THE LAST GLADE facing the sage (the opening counted as
              played).
          Saves, builds through the window's Build, writes `ending.json`.
  walk  — PyBoy on that build: the title == EN.title_picture (pixel for pixel, RGB555);
          NEW GAME → THE LAST GLADE; talk to the sage, YES; the credits start (mode 4) with
          the story RAM = the story point's rows (every byte StoryPointApply writes, the
          project's own flag bits aside) and journey_over ON; the credits run 29 pages, the
          2 new pages == EN.page_picture (with their monster's art), 2 s a page; the field
          again in THE AFTER ROOM at (4, 4); "TO BE CONTINUED" (mode 4 sub 1); A → "save?"
          → YES = SaveGameState ($00:$2128); a reboot with that save → CONTINUE → THE AFTER
          ROOM, no entry scene (the game's load runs none); the AFTER KEEPER's talk → the
          post-game scene → the game's Castle screen 1 (5, 6), post_game_seen ON.
          `--negative`: a copy of the ROM with bank $5F back to the original's bytes and
          StoryPointApply's first byte = ret — the title, the story, the page count, the
          new pages and the arrival checks FAIL.

  python3 tools/walk_ending.py make --out DIR
  python3 tools/walk_ending.py walk --out DIR [--keep KEEP] [--negative]
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import shutil
import sys
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

GT, FARM, CASTLE = 0x01, 0x04, 0x00
SAGE_SPRITE, KEEPER_SPRITE = 0x06, 0x05
POINT = 41                          # "everything done (after Monster Grandpa's match)"
NEW_PAGES = [('{ED}ROMHACK', "{ED}MILAYOU'S\n  JOURNEY", 20),
             ('{ED}THANK YOU FOR', '{ED}PLAYING!', 2)]
SECONDS = 2
TITLE_LINES = [{'text': "Milayou's Journey", 'row': 13, 'col': -1, 'colour': 'orange'},
               {'text': 'S153 ENDING DEMO', 'row': 2, 'col': -1, 'colour': 'red'}]
AFTER_CELL = (4, 4)
CASTLE_SCREEN, CASTLE_CELL = 1, (5, 6)


# =============================================================== make
def make(out):
    os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
    os.environ.setdefault('QT_AUDIO_BACKEND', 'none')
    from PySide6.QtWidgets import QApplication, QMessageBox
    app = QApplication.instance() or QApplication(sys.argv)
    QMessageBox.warning = staticmethod(lambda *a, **k: print('  [dialog warning]', a[2:3]))
    QMessageBox.information = staticmethod(lambda *a, **k: print('  [dialog info]', a[2:3]))
    QMessageBox.question = staticmethod(lambda *a, **k: QMessageBox.Discard)
    from editor2.app.main import MainWindow
    from editor2.app.rooms.commands import SnapshotCommand
    from editor2.core import textenc as T
    from editor2.core import cutscene_doc as CD

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
    w.new_project(out, name="Milayou's Journey (S153 ending demo)")
    pump()
    s = w.session
    rend = s.renderer

    def push(label, fn):
        c = SnapshotCommand(s, label, fn)
        s.undo.push(c)
        if c.error:
            raise SystemExit(f'{label}: {c.error}')
        pump()
        return c.result

    def B(*paras, speaker=None):
        o = []
        for p in paras:
            o += T.flow_boxes(p, first_box=not o, speaker=speaker)
        d = {'boxes': o}
        if speaker:
            d['speaker'] = speaker
        return d

    def src_cell(mid, scr, cx, cy):
        g = rend.vanilla_screen_grid(mid, scr)
        a = rend.vanilla_attr_grid(mid, scr)
        t = [g[2 * cy][2 * cx], g[2 * cy][2 * cx + 1], g[2 * cy + 1][2 * cx], g[2 * cy + 1][2 * cx + 1]]
        at = [a[2 * cy][2 * cx], a[2 * cy][2 * cx + 1], a[2 * cy + 1][2 * cx], a[2 * cy + 1][2 * cx + 1]]
        return t, at

    def stamp(d, rid, key, plan, legend):
        room = d.room(rid)
        lid = room['screens'][str(key)]['layout']['id']
        tiles, attrs = [], []
        for cy, row in enumerate(plan):
            assert len(row) == 10, row
            for cx, ch in enumerate(row):
                t, at = src_cell(*legend[ch])
                for i, (dy, dx) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
                    tiles.append((2 * cy + dy, 2 * cx + dx, t[i]))
                    attrs.append((2 * cy + dy, 2 * cx + dx, at[i]))
        d.set_cells(lid, 'tiles', tiles)
        d.set_cells(lid, 'attr', attrs)

    def own_colours(d, rid, changes):
        from editor2.app.rooms.palette_panel import to555
        from PySide6.QtGui import QColor
        room = d.room(rid)
        pals = rend.room_palettes(room, 0, 0)
        words = [[to555(QColor(*c)) for c in row] for row in pals]
        pid = d.localize_palette(room, 0, 0, words)
        for slot, idx, rgb_ in changes:
            d.set_palette_color(pid, slot, idx, rgb_)
        return pid

    def rgb(r, g, b):
        return (b << 10) | (g << 5) | r

    # =========================================================== 1. Title & ending…
    from editor2.app.ending_dialog import EndingDialog
    dlg = EndingDialog(s, w)
    for ln in TITLE_LINES:
        dlg._add_line(ln)
    at = len(dlg.pages) - 2             # the page before the closing page: ＋ Page after it
    for role, names, mon in NEW_PAGES:
        dlg.page_list.setCurrentRow(at)
        pump()
        dlg._add_page()
        pump()
        at = dlg.page_list.currentRow()
        dlg.role.setPlainText(role)
        dlg.names.setPlainText(names)
        j = dlg.monster.findData(mon)
        if j < 0:
            raise SystemExit(f'species {mon} not in the monster list')
        dlg.monster.setCurrentIndex(j)
        pump()
    dlg.seconds.setValue(SECONDS)
    want = [(p['role'], p['names'], p['monster']) for p in dlg.pages[25:28]]
    print('credits pages 26-28:', want)
    dlg._ok()
    from PySide6.QtWidgets import QDialog
    if dlg.result() != QDialog.Accepted:
        raise SystemExit('Title & ending dialog refused')
    dlg.deleteLater()
    pump()
    print('title:', s.doc.title_settings())
    c = s.doc.credits_settings()
    print('credits:', len(c['pages']), 'pages,', c['seconds'], 's')

    # =========================================================== 2. THE LAST GLADE
    LEG = {'L': (GT, 0, 2, 0), 'b': (GT, 0, 0, 2), 'B': (GT, 0, 1, 6), 'h': (GT, 0, 5, 2),
           'H': (GT, 0, 0, 3), 'p': (GT, 0, 3, 5), 'P': (GT, 0, 4, 5)}
    GLADE = ['LLLLLLLLLL',
             'bBbbhbbBbb',
             'bbppppppbb',
             'Hbppppppbh',
             'bbpPpPpPbb',
             'bBppppppBb',
             'bbppppppbb',
             'BbbbBbbbbB']

    def make_glade(d):
        rid = d.new_room('THE LAST GLADE', GT, rend)
        stamp(d, rid, 0, GLADE, LEG)
        # violet dusk: the leaves violet, the path lilac
        own_colours(d, rid, [(0, 0, rgb(18, 10, 26)), (1, 0, rgb(14, 8, 22)),
                             (2, 2, rgb(10, 4, 16)), (3, 2, rgb(22, 16, 28))])
        return rid
    glade = push('New room THE LAST GLADE', make_glade)

    # =========================================================== 3. THE AFTER ROOM
    FA_LEG = {'g': (FARM, 1, 5, 5), 's': (FARM, 1, 3, 1), 'u': (FARM, 5, 1, 7),
              'w': (FARM, 0, 2, 2), 'n': (FARM, 1, 4, 1)}
    AFTER = ['uuuuuuuuuu',
             'usggnggsgu',
             'uwwgggggsu',
             'uwwggggggu',
             'ugggggggsu',
             'ugggggggsu',
             'usggggsggu',
             'uuuuuuuuuu']

    def make_after(d):
        rid = d.new_room('THE AFTER ROOM', FARM, rend)
        stamp(d, rid, 0, AFTER, FA_LEG)
        own_colours(d, rid, [(0, 0, rgb(31, 24, 8)), (1, 0, rgb(30, 20, 6))])   # golden
        return rid
    after = push('New room THE AFTER ROOM', make_after)
    after_dest = f"room:${int(s.doc.room(after)['mapID'], 16):02X}"

    # =========================================================== 4. the sage's final scene
    def glade_scene(d):
        room = d.room(glade)
        d.add_npc(room, '0', 0, 4, 3, SAGE_SPRITE, 'down')
        CD.name_actor(d, glade, 0, 0, 1, 'ENDING SAGE')
        CD.ensure_flag(d, 'journey_over')
        sid = CD.new_cutscene(d, glade, 'The tale ends', screen=0, on='talk',
                              actor='ENDING SAGE')
        r, sc = CD.find(d, sid)
        S = 'SAGE'                      # a speaker: at most 9 letters
        sc['steps'] = [
            {'say': B('THE LAST GLADE. This is where MILAYOU\'S JOURNEY ends, {hero}.',
                      speaker=S)},
            {'ask': B('Shall the tale end and the credits roll?', speaker=S),
             'yes': [
                 {'story_point': {'point': POINT, 'arena': True}},
                 {'set': ['journey_over']},
                 {'say': B('Then the whole world is at peace. Farewell!', speaker=S)},
                 {'credits': {'dest': after_dest, 'screen': 0,
                              'x': AFTER_CELL[0], 'y': AFTER_CELL[1]}},
             ],
             'no': [{'say': B('Come back when you are ready.', speaker=S)}]},
        ]
        CD.set_scene(d, sid, sc)
        return sid
    push('THE LAST GLADE: the final scene', glade_scene)

    # =========================================================== 5. after the credits
    def after_scenes(d):
        room = d.room(after)
        d.add_npc(room, '0', 0, 6, 3, KEEPER_SPRITE, 'left')
        CD.name_actor(d, after, 0, 0, 1, 'AFTER KEEPER')
        CD.ensure_flag(d, 'tbc_shown')
        CD.ensure_flag(d, 'post_game_seen')
        K = 'KEEPER'
        a = CD.new_cutscene(d, after, 'To be continued', screen=0, on='entry')
        r, sc = CD.find(d, a)
        sc['trigger']['once'] = 'tbc_shown'
        sc['steps'] = [
            {'say': B('THE AFTER ROOM: the credits brought you here. Your tale pauses now...',
                      speaker=K)},
            {'to_be_continued': {}},
        ]
        CD.set_scene(d, a, sc)
        # the post-game: a TALK scene — CONTINUE runs no entry scene (measured S153)
        b = CD.new_cutscene(d, after, 'The post-game', screen=0, on='talk',
                            actor='AFTER KEEPER')
        r, sc = CD.find(d, b)
        sc['trigger']['when_on'] = ['tbc_shown']
        sc['trigger']['once'] = 'post_game_seen'
        sc['steps'] = [
            {'say': B('Welcome back! The whole world is open now. Off to the KING\'s castle!',
                      speaker=K)},
            {'move': {'dest': 'vanilla:$00', 'screen': CASTLE_SCREEN,
                      'x': CASTLE_CELL[0], 'y': CASTLE_CELL[1]}},
        ]
        CD.set_scene(d, b, sc)
        sid = d.new_conversation(room, {'steps': [{'say': B(
            'THE AFTER ROOM is where a story waits after its credits.', speaker=K)}]},
            name='after_keeper')
        d.update_npc(room, '0', 0, 0, script=sid)
        return a, b
    push('THE AFTER ROOM: the scenes', after_scenes)

    def music(d):
        d.set_room_music(d.room(glade), '0x0F')
        d.set_room_music(d.room(after), '0x12')
    push('Music', music)

    # =========================================================== 6. New game…
    from editor2.app.newgame_dialog import NewGameDialog
    ng = NewGameDialog(s, w)
    ng.r_room.setChecked(True)
    ng.room.setCurrentIndex(ng.room.findData(glade))
    ng._room_changed()
    ng.screen.setCurrentIndex(ng.screen.findData(0))
    ng.x.setValue(4)
    ng.y.setValue(4)
    ng.face.setCurrentIndex(ng.face.findData('up'))
    ng.r_done.setChecked(True)
    if not ng._apply():
        raise SystemExit('New game dialog refused')
    ng.deleteLater()
    pump()
    print('new game:', s.doc.new_game())

    # ---------------------------------------------------------- save + build
    w.save()
    pump(0.5)
    from editor2.core import compiler as CC
    _o, _p, warns = CC.compile_project(out, REPO)
    mine = [x for x in warns if any(nm in x for nm in ('LAST GLADE', 'AFTER ROOM', 'credit',
                                                       'title', 'Title'))]
    for x in mine:
        print('  build warning:', x)
    t0 = time.perf_counter()
    w.build()
    while w.worker is not None and w.worker.isRunning():
        pump(0.2)
    pump(0.5)
    res = w.last_result
    if res is None or not res.ok:
        raise SystemExit(f'BUILD FAILED: {getattr(res, "error", "?")}')
    print(f'built in {time.perf_counter() - t0:.0f} s: {res.rom_path} md5 {res.rom_md5}')
    d = s.doc
    from editor2.core.project import Project
    prj = Project.load(out)
    prj.repo_root = REPO
    info = {'rom': os.path.relpath(res.rom_path, out), 'md5': res.rom_md5,
            'rooms': {k: {'id': v, 'mid': d.room(v)['mapID']} for k, v in
                      (('glade', glade), ('after', after))},
            'flag_numbers': {f['name']: prj._flag_index(f['name'], 'walk') for f in d.flags()},
            'warnings': mine}
    json.dump(info, open(os.path.join(out, 'ending.json'), 'w'), indent=1)
    w.close()
    return info


# =============================================================== walk
GAME_MODE, SUB_MODE, MODE_LATCH = 0xC88A, 0xC88B, 0xC88E
PAGE, PAGE_STATE, PAGE_FRAMES, PAGE_SECS = 0xC0D9, 0xC0D8, 0xC0DA, 0xC0DB
SAVE_HOOK = (0x00, 0x2128)                  # SaveGameState
YESNO = 0xC83C                              # the YES/NO cursor (1 = NO)


def rgb5(img, x, y):
    return tuple(v >> 3 for v in img.getpixel((x, y))[:3])


def differing(img, model):
    return sum(1 for y in range(144) for x in range(160)
               if rgb5(img, x, y) != tuple(round(v * 31 / 255) for v in model[y][x]))


def sym_addr(sym_path, name):
    for ln in open(sym_path):
        p = ln.split()
        if len(p) == 2 and p[1] == name:
            b, a = p[0].split(':')
            return int(b, 16), int(a, 16)
    return None


def walk(out, keep, negative):
    from tools.walk_opening import Play, MAP_ID
    from editor2.core import ending as EN
    info = json.load(open(os.path.join(out, 'ending.json')))
    fl = info['flag_numbers']
    glade_mid = int(info['rooms']['glade']['mid'], 16) & 0xFF
    after_mid = int(info['rooms']['after']['mid'], 16) & 0xFF
    bdir = os.path.join(out, 'build', 'build')
    rom = os.path.join(bdir, 'rom.gbc')
    prj = json.load(open(os.path.join(out, 'project.json')))
    work = os.path.join(keep or out, 'walk_rom.gbc')
    os.makedirs(os.path.dirname(work), exist_ok=True)
    data = bytearray(open(rom, 'rb').read())
    if negative:
        orig = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
        o = 0x5F * 0x4000
        data[o:o + 0x4000] = orig[o:o + 0x4000]
        b, a = sym_addr(os.path.join(bdir, 'game.sym'), 'StoryPointApply')
        data[b * 0x4000 + a - 0x4000] = 0xC9
        print('negative: bank $5F = the original bytes; StoryPointApply = ret')
    open(work, 'wb').write(data)
    P = Play(work, keep)
    m = P.m

    # ---- the title
    # the logos, the run, the drop (~1200 frames), then the title: the screen polled
    model = EN.title_picture(prj['custom'])
    best = None
    for _ in range(100):
        P.adv(30)
        if m[GAME_MODE] == 0 and m[SUB_MODE] == 0 and m[0xC88C] == 6:
            bad = differing(P.p.screen.image, model)
            best = bad if best is None else min(best, bad)
            if bad == 0:
                break
    P.check('title: the screen == EN.title_picture ("Milayou\'s Journey" + the red line)',
            best == 0, f'{best} differing pixels at best')

    # ---- NEW GAME
    for _ in range(40):
        P.tap('a', wait=8)
        if m[GAME_MODE] == 1 and m[MAP_ID] != 0:
            break
    P.until(P.idle, 3000, auto=False)
    P.adv(240)                          # the room's fade in (talking earlier is ignored)
    P.check('start: NEW GAME lands in THE LAST GLADE', m[MAP_ID] == glade_mid,
            f'map ${m[MAP_ID]:02X}')

    # ---- the sage: YES (the cursor starts on YES)
    # the YES/NO menu starts on NO ($C83C = 1 once it shows — PYBOY_DEBUGGING): up, A
    P.talk('up')
    answered = False
    for _ in range(300):
        if m[GAME_MODE] == 4:
            break
        if m[YESNO] == 1 and not answered:
            P.adv(20)
            P.tap('up', hold=3, wait=10)
            P.tap('a', hold=3, wait=20)
            answered = True
        elif m[0xC8EB] & 1:
            P.tap('a', hold=3, wait=20)
        else:
            P.adv(20)
    ok = m[GAME_MODE] == 4
    P.check('final scene: the sage\'s YES rolls the credits (game mode 4 sub 0)',
            ok and m[SUB_MODE] == 0, f'mode {m[GAME_MODE]} sub {m[SUB_MODE]}')
    own_bits = {}
    for nm, i in fl.items():
        if i is not None and i < 0x1000:
            own_bits.setdefault(0xD99B + (i >> 3), 0)
            own_bits[0xD99B + (i >> 3)] |= 0x80 >> (i & 7)
    rows = EN.point_rows(POINT, True)
    wrong = []
    for a, k, v in rows:
        mask = 0xFF & ~k & ~own_bits.get(a, 0)
        if (m[a] & mask) != (v & mask):
            wrong.append(f'${a:04X}={m[a]:02X} want {v:02X}/{mask:02X}')
    P.check(f'story point {POINT} ({EN.point_label(POINT)}): every byte StoryPointApply '
            f'writes ({len(rows)} rows)', not wrong, '; '.join(wrong[:6]) +
            (f' … {len(wrong)} wrong' if len(wrong) > 6 else ''))
    P.check('final scene: journey_over ON', P.flag(fl['journey_over']) == 1)

    # ---- the credits
    pages = EN.pages(prj['custom'])
    n_pages = len(pages)
    seen, starts, shots = set(), {}, {}
    f = 0
    for f in range(30000):
        P.p.tick()
        if m[GAME_MODE] != 4:
            break
        pg, st = m[PAGE], m[PAGE_STATE]
        if pg not in starts:
            starts[pg] = f
        seen.add(pg)
        if pg in (25, 26, 27, 28) and pg not in shots and st in (0, 4) \
                and m[PAGE_SECS] == 1 and m[PAGE_FRAMES] == 0:
            shots[pg] = P.p.screen.image.copy()
            if keep:
                shots[pg].save(os.path.join(keep, f'page_{pg:02d}.png'))
    P.check(f'credits: {n_pages} pages shown (the game\'s 27 + 2 new)', max(seen) == n_pages - 1,
            f'last page index {max(seen)}')
    # a page = the seconds x 60 frames + 50 (the fade out / in: measured S153 — 170 at 2 s)
    gaps = [starts[i + 1] - starts[i] for i in range(1, min(20, max(seen)))]
    P.check(f'credits: {SECONDS} s a page', bool(gaps) and all(
        abs(g - (SECONDS * 60 + 50)) <= 2 for g in gaps), f'frames {gaps[:5]}')
    for i in (25, 26, 27, 28):
        if i >= n_pages:
            continue
        pg = pages[i]
        mon = EN.monster_art(prj, out, int(pg['monster']))
        mdl = EN.page_picture(pg, i == n_pages - 1, monster_rows=mon)
        bad = differing(shots[i], mdl) if i in shots else -1
        P.check(f'credits page {i + 1} ({pg["role"]!r}) == EN.page_picture', bad == 0,
                f'{bad} differing pixels' if bad >= 0 else 'never shown')

    # ---- after the credits: THE AFTER ROOM, then TO BE CONTINUED
    arrived = None
    for _ in range(4000):
        P.adv(1)
        if m[GAME_MODE] == 1 and m[0xC96C] == 0 and m[MAP_ID] != 0:
            P.adv(2)
            arrived = (m[MAP_ID], m[0xC925], P.cell())
            break
    P.check('after the credits: THE AFTER ROOM, screen 0, cell (4, 4)',
            arrived == (after_mid, 0, AFTER_CELL), f'{arrived}')
    ok = P.until(lambda: m[GAME_MODE] == 4 and m[SUB_MODE] == 1, 4000)
    P.check('THE AFTER ROOM entry scene: "TO BE CONTINUED" (mode 4 sub 1)', ok,
            f'mode {m[GAME_MODE]} sub {m[SUB_MODE]} map ${m[MAP_ID]:02X}')
    P.adv(200)
    P.snap('tbc')
    saves = []
    P.p.hook_register(SAVE_HOOK[0], SAVE_HOOK[1], lambda _c: saves.append(1), None)
    for _ in range(200):
        P.tap('a', hold=3, wait=10)
        if saves:
            break
    P.adv(300)
    P.check('TO BE CONTINUED: A → "save?" → YES = SaveGameState', bool(saves))
    sav = bytes(m[k // 0x2000, 0xA000 + (k % 0x2000)] for k in range(0x8000))
    sav_path = os.path.join(keep or out, 'ending.sav')
    open(sav_path, 'wb').write(sav)
    fails = P.fails
    n = P.n
    P.p.stop(save=False)

    # ---- CONTINUE
    open(work + '.ram', 'wb').write(sav)
    Q = Play.__new__(Play)
    from pyboy import PyBoy
    Q.keep, Q.fails, Q.n, Q.t = keep, fails, n, 0
    Q.p = PyBoy(work, window='null', cgb=True, sound_emulated=False)
    Q.p.set_emulation_speed(0)
    Q.m = q = Q.p.memory
    Q.adv(400)
    Q.tap('start')
    Q.adv(120)
    for _ in range(40):
        if q[GAME_MODE] == 1 and q[MAP_ID] not in (0, 0x2F):
            break
        Q.tap('a', hold=4, wait=60)
    Q.check('CONTINUE: THE AFTER ROOM (where the save was made)', q[MAP_ID] == after_mid,
            f'map ${q[MAP_ID]:02X}')
    # the post-game: no entry scene on CONTINUE; talk to the AFTER KEEPER (6, 3)
    Q.until(Q.idle, 2000, auto=False)
    Q.adv(240)
    Q.check('CONTINUE: no entry scene plays (the player has control at once)',
            Q.idle() and not Q.flag(fl['post_game_seen']))
    Q.step('right')
    Q.step('right')
    Q.talk('up')
    ok = Q.until(lambda: q[MAP_ID] == CASTLE and q[0xC96C] == 0 and q[GAME_MODE] == 1, 4000)
    Q.adv(30)
    Q.check('the post-game scene: the game\'s Castle, screen 1, cell (5, 6)',
            ok and q[0xC925] == CASTLE_SCREEN and Q.cell() == (15, 6),
            f'map ${q[MAP_ID]:02X} screen {q[0xC925]} cell {Q.cell()}')
    Q.check('the post-game scene: post_game_seen ON, tbc_shown ON',
            Q.flag(fl['post_game_seen']) == 1 and Q.flag(fl['tbc_shown']) == 1)
    Q.p.stop(save=False)
    print(f"WALK: {'PASS' if Q.fails == 0 else f'FAIL {Q.fails}'}  ({Q.n} checks)")
    return Q.fails


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=['make', 'walk'])
    ap.add_argument('--out', required=True)
    ap.add_argument('--keep')
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args()
    if a.cmd == 'make':
        make(a.out)
    else:
        sys.exit(1 if walk(a.out, a.keep, a.negative) else 0)


if __name__ == '__main__':
    main()
