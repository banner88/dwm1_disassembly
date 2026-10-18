#!/usr/bin/env python3
"""walk_opening.py — S152 (ROADMAP E3 a2): a whole romhack OPENING made in the editor,
then played in the game (PyBoy).

User (S152): "Make a new project and set up an alternative where waroubou greets Milly (and
asks name) in roots room. Then link to them walking (cutscene) through two new screens (new
greatlog) upwards into a door entrance). No player control. Then link to a new custom throne
room with new king (GreatLog king) with new dialogue and cutscene. then give player control
and let them go up into a new farm area (totally redesigned) and get their first new
(different monster). See if there are any issues doing this purely via editor and make a new
help detailing every step. Then unlock area and let player enter new gate (custom gate)." +
"editor probably SHOULD have that capability. New game -> where to start -> etc."

  make  — the REAL editor window (Qt offscreen, editor2.app.main.MainWindow): File → New
          project, then every step of the help topic `75_opening.md`, each through the code
          the GUI runs (undo commands; the New game, Milly hook and Service dialogs driven
          through their own widgets):
            THE ROOTS ROOM (Cutscenes → Milly hook… → Create the roots room; Warubou asks
              her name) — New game… starts the game HERE, as Milly, the original opening
              counted as played;
            GREATLOG PATH (new, GreatTree's tileset, own autumn colours, 2 screens tall):
              Warubou and Milly walk up through both screens into the door — no control;
            GREATLOG THRONE (new, the Castle's tileset, own colours): the GREATLOG KING's
              scene (new words), then control; the KING / WARUBOU / the GUARD talk;
            GREATLOG FARM (new, the Farm's tileset, 2 screens wide): LOGGO, a farm keeper
              who hands over the FIRST MONSTER (a DragonKid, level 1 — Pulio's way: it waits
              in the farm, the menu opens, PICK UP); the LOG GUARD blocks the way east until
              the first monster is given, then steps aside (a talk scene + a room state);
              THE GATE GLADE (screen 1): the portal of GREATLOG GATE (a new gate, a copy of
              the first gate, 3 floors) and the GLADE KEEPER;
            STUMP HOLLOW (new, a gate theme): the gate's boss floor — the STUMP KING
              (Make boss…), Warubou takes the player back to the glade.
          Saves, builds through the window's Build, writes `opening.json` (room ids, map ids,
          the friction found on the way).
          `--variant intro`: the same project with New game = the game's intro (the Milly
          hook's dresser sends Milly to the roots room) — the second test ROM.
  walk  — PyBoy, a NEW GAME on that build (no save needed): the title, NEW GAME → the roots
          room (map, Milly's flag, the spin-in), Warubou's words + the naming screen (MILLY),
          the path's two screens walked by the scenes (screen 4 → screen 0 → the throne room,
          no input but A for the texts), the King's scene, control; the original opening's
          flags / room states at that point; the stairs up WALKED to the farm; LOGGO: the
          farm menu, PICK UP → the DragonKid in the party (species, level); the LOG GUARD
          before (blocks, his words) / after (steps aside, the state after a reload); the
          glade walked into; the portal stepped on → GREATLOG GATE floor 1 (gate 32); the
          boss floor (kick); the STUMP KING's battle won (A-mash); Warubou → the glade; the
          gate's cleared flag ($17C0) and the swirl gone; the game's own Castle in its
          post-opening state (no Minister scene, no Slib). `--negative`: the ROM copy's
          newgame_start region back to the vanilla bytes — the new game starts in the bedroom
          and the start checks FAIL (room variant only — the intro variant starts in the
          bedroom anyway; its control is the S152 hook change: before it the story check
          FAILED on $0000). `make --story untouched` (control): New game's story left as it
          is — the story checks and the game's-Castle checks FAIL.

  python3 tools/walk_opening.py make --out DIR [--variant room|intro] [--story untouched]
  python3 tools/walk_opening.py walk --out DIR [--keep KEEP] [--negative]
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

FRICTION = []               # what the editor made hard / impossible (written to opening.json)
STARTER_SPECIES, STARTER_LEVEL = 20, 1          # DragonKid, level 1
BOSS_SPECIES = 45                                # Tonguella
GT, CASTLE, FARM = 0x01, 0x00, 0x04
WARUBOU = 0x39
KING_SPRITE, GUARD_SPRITE, KEEPER_SPRITE, GLADE_SPRITE = 0x0C, 0x0B, 0x06, 0x05


def note(msg):
    FRICTION.append(msg)
    print('  FRICTION:', msg)


# =============================================================== make
def make(out, variant, story='opening_done'):
    os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
    os.environ.setdefault('QT_AUDIO_BACKEND', 'none')
    from PySide6.QtWidgets import QApplication, QMessageBox
    app = QApplication.instance() or QApplication(sys.argv)
    QMessageBox.warning = staticmethod(lambda *a, **k: print('  [dialog warning]', a[2:3]))
    QMessageBox.information = staticmethod(lambda *a, **k: print('  [dialog info]', a[2:3]))
    QMessageBox.question = staticmethod(lambda *a, **k: QMessageBox.Discard)
    from editor2.app.main import MainWindow
    from editor2.app.rooms.commands import SnapshotCommand, AddScreen
    from editor2.app.session import REPO as SREPO
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
    w.new_project(out, name='GreatLog Opening (S152 demo)')
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

    # ---------------------------------------------------------- painting helpers
    def src_cell(mid, scr, cx, cy):
        g = rend.vanilla_screen_grid(mid, scr)
        a = rend.vanilla_attr_grid(mid, scr)
        t = [g[2 * cy][2 * cx], g[2 * cy][2 * cx + 1], g[2 * cy + 1][2 * cx], g[2 * cy + 1][2 * cx + 1]]
        at = [a[2 * cy][2 * cx], a[2 * cy][2 * cx + 1], a[2 * cy + 1][2 * cx], a[2 * cy + 1][2 * cx + 1]]
        return t, at

    def stamp(d, rid, key, plan, legend):
        """plan = 8 strings of 10 chars; legend = {char: (mid, screen, cx, cy)} — the
        Rooms tab's metatile picker with the room's vocabulary (the source room's)."""
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

    def own_colours(d, rid, changes, base_mid):
        """Palette panel: "Make palette editable" (Rooms tab, the borrowed-palette
        question → localize_palette with the colours shown), then change some."""
        from editor2.app.rooms.palette_panel import to555
        from PySide6.QtGui import QColor
        room = d.room(rid)
        pals = rend.room_palettes(room, 0, 0)
        words = [[to555(QColor(*c)) for c in row] for row in pals]
        pid = d.localize_palette(room, 0, 0, words)
        for slot, idx, rgb in changes:
            d.set_palette_color(pid, slot, idx, rgb)
        return pid

    def rgb(r, g, b):          # 0-31 each -> RGB555
        return (b << 10) | (g << 5) | r

    # =========================================================== 1. the roots room
    # Cutscenes tab → Milly hook… → "Create the roots room" (MillyHookDialog._create_roots),
    # tick "Apply the Milly patch", "Warubou asks her name" is on for a new roots room.
    from editor2.app.milly_dialog import MillyHookDialog
    dlg = MillyHookDialog(s, w)
    dlg._create_roots()
    dlg.on.setChecked(True)
    roots = dlg.roots.currentData()
    if not dlg._apply():
        raise SystemExit('Milly hook dialog refused')
    dlg.deleteLater()
    pump()
    print('roots room:', roots, s.doc.room(roots)['mapID'],
          'naming:', s.doc.roots_naming(roots))

    # =========================================================== 2. GREATLOG PATH
    PATH_LEG = {'L': (GT, 0, 2, 0), 'l': (GT, 0, 1, 1), 'b': (GT, 0, 0, 2), 'B': (GT, 0, 1, 6),
                'h': (GT, 0, 5, 2), 'H': (GT, 0, 0, 3), 'p': (GT, 0, 3, 5), 'P': (GT, 0, 4, 5),
                't': (GT, 0, 4, 3), 'T': (GT, 0, 5, 3), 'd': (GT, 0, 4, 4), 'D': (GT, 0, 5, 4),
                'f': (GT, 0, 3, 4), 'F': (GT, 0, 6, 4)}
    PATH_TOP = ['LLLLLLLLLL',
                'bbbhtThbbb',
                'bBbfdDFbBb',
                'bbbpPpPbhb',
                'Hbbppppbbb',
                'bBbpPpPbBb',
                'bbhppppbbb',
                'bbbpPpPbbH']
    PATH_BOTTOM = ['bbbppppbbb',
                   'bBbpPpPbBb',
                   'Hbbppppbhb',
                   'bbbpPpPbbb',
                   'bhbppppbBb',
                   'bBbpPpPbbb',
                   'bbbppppbbH',
                   'BbbbBbbbbB']

    def make_path(d):
        rid = d.new_room('GREATLOG PATH', GT, rend)
        return rid
    path = push('New room GREATLOG PATH', make_path)
    # the mini-map's "+" below screen 0 = screen 4 (Rooms tab _add_screen → AddScreen)
    thr = rend.room_gfx(s.doc.room(path)).threshold
    s.undo.push(AddScreen(s, path, 4, s.doc.blank_grid(min(thr, 127)), s.doc.blank_grid(0)))
    pump()

    def paint_path(d):
        stamp(d, path, 0, PATH_TOP, PATH_LEG)
        stamp(d, path, 4, PATH_BOTTOM, PATH_LEG)
        # autumn GreatLog: the leaves orange, the bark redder (palette panel)
        return own_colours(d, path, [(0, 0, rgb(30, 20, 6)), (1, 0, rgb(28, 14, 4)),
                                     (2, 2, rgb(22, 10, 4)), (3, 2, rgb(24, 12, 6))], GT)
    push('Paint GREATLOG PATH', paint_path)

    # =========================================================== 3. GREATLOG THRONE
    TH_LEG = {'S': (CASTLE, 1, 0, 3), 'C': (CASTLE, 1, 1, 0), 'c': (CASTLE, 1, 1, 1),
              'r': (CASTLE, 1, 1, 2), 'a': (CASTLE, 1, 2, 2), 'e': (CASTLE, 1, 2, 4),
              '1': (CASTLE, 1, 3, 2), '2': (CASTLE, 1, 4, 2), '3': (CASTLE, 1, 5, 2),
              '4': (CASTLE, 1, 6, 2), '5': (CASTLE, 1, 3, 3), '6': (CASTLE, 1, 4, 3),
              '7': (CASTLE, 1, 5, 3), '8': (CASTLE, 1, 6, 3), 'A': (CASTLE, 1, 7, 2),
              'E': (CASTLE, 1, 7, 4), 'm': (CASTLE, 1, 3, 4), 'n': (CASTLE, 1, 4, 4),
              'o': (CASTLE, 1, 5, 4), 'q': (CASTLE, 1, 6, 4), 'k': (CASTLE, 1, 4, 5),
              'K': (CASTLE, 1, 5, 5), 'g': (CASTLE, 5, 2, 4), 'v': (CASTLE, 5, 2, 5),
              '^': (CASTLE, 5, 7, 5), 'w': (CASTLE, 5, 1, 7), 'W': (CASTLE, 5, 2, 7),
              'x': (CASTLE, 5, 3, 7)}
    THRONE = ['SCCCCCCCCS',
              'SccccccccS',
              'Sra1234ArS',
              'Sra5678ArS',
              'SremnoqErS',
              'Svgrkkrg^S',
              'Srrrkkrrr' + 'S',
              'SwWxxxxWwS']

    def make_throne(d):
        rid = d.new_room('GREATLOG THRONE', CASTLE, rend)
        stamp(d, rid, 0, THRONE, TH_LEG)
        # GreatLog green: the red floor turned moss green, the curtains brown
        own_colours(d, rid, [(0, 0, rgb(12, 20, 8)), (0, 2, rgb(6, 14, 4)),
                             (1, 0, rgb(20, 12, 6)), (1, 2, rgb(12, 6, 2))], CASTLE)
        return rid
    throne = push('New room GREATLOG THRONE', make_throne)

    # =========================================================== 4. GREATLOG FARM
    FA_LEG = {'g': (FARM, 1, 5, 5), 'G': (FARM, 1, 2, 4), 's': (FARM, 1, 3, 1),
              'S': (FARM, 0, 8, 3), 'u': (FARM, 5, 1, 7), 'w': (FARM, 0, 2, 2),
              'W': (FARM, 0, 5, 1), 'D': (FARM, 5, 7, 5), 'n': (FARM, 1, 4, 1),
              'j': (FARM, 4, 2, 1)}
    FARM0 = ['uuuuuuuuuu',
             'ugggngggsu',
             'uggggggggs',
             'uggggggggs',
             'ugggwwgggg',
             'ugggwwgggs',
             'uDggggggjs',
             'uuuuuuuuuu']
    FARM1 = ['uuuuuuuuuu',
             'ugggggggsu',
             'sgsgggsggu',
             'sggggggggu',
             'gggggggggu',
             'sgsgggsggu',
             'sggggggggu',
             'uuuuuuuuuu']

    def make_farm(d):
        rid = d.new_room('GREATLOG FARM', FARM, rend)
        return rid
    farm = push('New room GREATLOG FARM', make_farm)
    thr = rend.room_gfx(s.doc.room(farm)).threshold
    s.undo.push(AddScreen(s, farm, 1, s.doc.blank_grid(min(thr, 127)), s.doc.blank_grid(0)))
    pump()

    def paint_farm(d):
        stamp(d, farm, 0, FARM0, FA_LEG)
        stamp(d, farm, 1, FARM1, FA_LEG)
        return own_colours(d, farm, [(0, 0, rgb(26, 28, 10)), (1, 0, rgb(24, 26, 8))], FARM)
    push('Paint GREATLOG FARM', paint_farm)

    # =========================================================== 5. STUMP HOLLOW (boss floor)
    WALL = [0x08, 0x09, 0x18, 0x19]

    def make_hollow(d):
        rid = d.new_room('STUMP HOLLOW', 0, rend, gate_theme=3)
        lid = d.room(rid)['screens']['0']['layout']['id']
        ch = []
        for cx in range(10):
            for cy in range(8):
                if cx in (0, 9) or cy in (0, 7):
                    for i, (dy, dx) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
                        ch.append((2 * cy + dy, 2 * cx + dx, WALL[i]))
        d.set_cells(lid, 'tiles', ch)
        return rid
    hollow = push('New room STUMP HOLLOW', make_hollow)

    # =========================================================== 6. doors
    def doors(d):
        # S152 r2: the door ON the hole (row 2) — and, as the game does on GreatTree (screen
        # 0: no exits in state 0, the door in state 1), only in the state AFTER the walk:
        # + Add state → Duplicate this state; the door "in this state only"; a state rule
        # (state 1 when path_walk_2 is ON). In state 0 the walk scene plays and walks Milly
        # into the hole without the door firing mid-scene (r2: the room loaded twice).
        proom = d.room(path)
        st1, _l = d.add_state(proom, '0', copy_from=0)
        d.set_state_rules(proom, [{'screens': [0], 'state': st1,
                                   'when': [{'flag': CD.ensure_flag(d, 'path_walk_2'),
                                             'is': 'set'}]}])
        a = d.add_door(path, 0, 4, 2, states=[st1], name='GreatLog door (path)')
        b = d.add_door(throne, 0, 1, 5, name='Throne stairs down')
        d.link_doors(a, b)
        c = d.add_door(throne, 0, 8, 5, name='Throne stairs up')
        e = d.add_door(farm, 0, 1, 6, name='Farm door down')
        d.link_doors(c, e)
        return a, b, c, e
    door_ids = push('Doors', doors)

    def arrival_of(did):
        from editor2.core import doors as DR   # noqa: F401
        end = s.doc.door_end(did)
        p = s.doc.door_partner(did)
        return end, p
    print('doors:', door_ids)

    # =========================================================== 7. the roots room → the path
    # Milly hook dialog: "Warubou leads her to" GREATLOG PATH screen 4 (4, 6)
    dlg = MillyHookDialog(s, w)
    i = dlg.dest.findData(f"room:${int(s.doc.room(path)['mapID'], 16):02X}")
    if i < 0:
        note('Milly hook dialog: the new room is not in "Warubou leads her to" until the '
             'dialog is reopened')
        raise SystemExit('dest not offered')
    dlg.dest.setCurrentIndex(i)
    dlg._fill_dest_screens(4)
    dlg.d_x.setValue(4)
    dlg.d_y.setValue(6)
    dlg._apply()
    dlg.deleteLater()
    pump()
    print('roots → path:', s.doc.roots_scene_destination(roots))

    # =========================================================== 8. New game…
    from editor2.app.newgame_dialog import NewGameDialog
    ng = NewGameDialog(s, w)
    if variant == 'room':
        ng.r_room.setChecked(True)
        ng.room.setCurrentIndex(ng.room.findData(roots))
        ng._room_changed()
        ng.screen.setCurrentIndex(ng.screen.findData(0))
        ng.x.setValue(5)
        ng.y.setValue(4)
        ng.face.setCurrentIndex(ng.face.findData('down'))
    else:
        ng.r_intro.setChecked(True)
    (ng.r_done if story == 'opening_done' else ng.r_untouched).setChecked(True)
    if not ng._apply():
        raise SystemExit('New game dialog refused')
    ng.deleteLater()
    pump()
    print('new game:', s.doc.new_game())

    # =========================================================== 9. the path's scenes
    # S152 r2 (user: "In second screen, milly disappears. Then warubou is sitting inside the
    # entrance hall. Then he goes ABOVE the hole and then milly appears. Not ideal. See how
    # vanilla game does it."): the game's own way (GreatTree, map $01 script 0 — the old
    # man's walk): the helper is an NPC of each screen while the walk is on, both walk to the
    # top edge, "Warp the player" (op $0F) to the next screen's bottom, whose own entry
    # scene goes on; the door is ON the hole, each walks into it, the door sound ($51),
    # gone.
    # Rooms tab → Add NPC here… (Warubou) → "Shown when" flags; Cutscenes → ＋ New cutscene…
    def path_scenes(d):
        room = d.room(path)
        w1 = CD.ensure_flag(d, 'path_walk_1')
        w2 = CD.ensure_flag(d, 'path_walk_2')
        d.add_npc(room, '4', 0, 4, 5, WARUBOU, 'up')
        i4 = len(d.npc_entries(room, '4', 0)) - 1
        d.set_npc_shown_when(room, '4', 0, i4, [{'flag': w1, 'is': 'clear'}])
        d.add_npc(room, '0', 0, 4, 6, WARUBOU, 'up')
        i0 = len(d.npc_entries(room, '0', 0)) - 1
        d.set_npc_shown_when(room, '0', 0, i0, [{'flag': w1, 'is': 'set'},
                                                 {'flag': w2, 'is': 'clear'}])
        for key in (4, 0):
            n = max(k for k, _e in CD.npc_rows(d.room(path), key, 0))
            CD.name_actor(d, path, key, 0, n, 'Warubou')
        door = f"room:${int(d.room(path)['mapID'], 16):02X}"
        sid1 = CD.new_cutscene(d, path, 'Up the GreatLog path', screen=4, on='entry')
        r, sc = CD.find(d, sid1)
        sc['trigger']['once'] = w1
        sc['player_start'] = {'x': 4, 'y': 6, 'face': 'up'}
        sc['steps'] = [
            {'say': B('Heh heh! This way. Up the path!', speaker='Warubou')},
            {'walk': {'actor': 'Warubou', 'to': [4, 0], 'first': 'y', 'together': True}},
            {'walk': {'actor': 'player', 'to': [4, 1], 'first': 'y'}},
            {'wait_walks': True},
            {'move': {'dest': door, 'screen': 0, 'x': 4, 'y': 7}},
        ]
        CD.set_scene(d, sid1, sc)
        sid2 = CD.new_cutscene(d, path, 'Into the GreatLog door', screen=0, on='entry')
        r, sc = CD.find(d, sid2)
        sc['trigger']['once'] = w2
        sc['player_start'] = {'x': 4, 'y': 7, 'face': 'up'}
        sc['steps'] = [
            {'walk': {'actor': 'Warubou', 'to': [4, 3], 'first': 'y', 'together': True}},
            {'walk': {'actor': 'player', 'to': [4, 4], 'first': 'y'}},
            {'wait_walks': True},
            {'face': {'actor': 'Warubou', 'dir': 'down'}},
            {'say': B('The KING of GREATLOG waits inside. In you go!', speaker='Warubou')},
            {'face': {'actor': 'Warubou', 'dir': 'up'}},
            {'walk': {'actor': 'Warubou', 'to': [4, 2], 'first': 'y'}},
            {'sound': '0x51'},
            {'hide': {'actor': 'Warubou', 'how': 'instant'}},
            {'walk': {'actor': 'player', 'to': [4, 2], 'first': 'y'}},
            {'sound': '0x51'},
            {'wait': {'frames': 16}},
            {'hide': {'actor': 'player', 'how': 'instant'}},
            {'wait': {'frames': 32}},
            {'move': {'dest': f"room:${int(d.room(throne)['mapID'], 16):02X}", 'screen': 0,
                      'x': 2, 'y': 5}},
        ]
        CD.set_scene(d, sid2, sc)
        return sid1, sid2
    push('Path scenes', path_scenes)

    # =========================================================== 10. the throne room
    def throne_npcs(d):
        room = d.room(throne)
        d.add_npc(room, '0', 0, 4, 2, KING_SPRITE, 'down')
        d.add_npc(room, '0', 0, 6, 5, WARUBOU, 'left')
        d.add_npc(room, '0', 0, 7, 3, GUARD_SPRITE, 'down')
        CD.name_actor(d, throne, 0, 0, 1, 'King')
        CD.name_actor(d, throne, 0, 0, 2, 'Warubou')
        CD.name_actor(d, throne, 0, 0, 3, 'Guard')
        CD.ensure_flag(d, 'met_king')
        sid = CD.new_cutscene(d, throne, 'The GreatLog King', screen=0, on='entry')
        r, sc = CD.find(d, sid)
        sc['trigger']['once'] = 'met_king'
        sc['player_start'] = {'x': 2, 'y': 5, 'face': 'right'}
        K = 'King'
        sc['steps'] = [
            {'walk': {'actor': 'player', 'to': [4, 4], 'first': 'x'}},
            {'face': {'actor': 'player', 'dir': 'up'}},
            {'say': B('So this is the girl from the roots. Welcome to GREATLOG, {hero}!',
                      'I am the KING of GREATLOG, the kingdom inside the fallen log.',
                      speaker=K)},
            {'face': {'actor': 'Warubou', 'dir': 'up'}},
            {'say': B('Heh heh! I found her, my King.', speaker='Warubou')},
            {'say': B('A master needs a partner monster. Climb the STAIRS on the right to '
                      'the GREATLOG FARM. LOGGO will give you your first monster.',
                      speaker=K)},
            {'say': B('Then the GATE GLADE behind the farm is yours to explore.', speaker=K)},
        ]
        CD.set_scene(d, sid, sc)
        # their words afterwards (Rooms tab → the NPC → New conversation…)
        got = CD.ensure_flag(d, 'first_monster_given')     # the flag picker's "New flag…"
        room = d.room(throne)
        k = d.new_conversation(room, {'steps': [
            {'if': [{'flag': got, 'is': 'set'}],
             'then': [{'say': B('A fine partner! The GATE GLADE is beyond the farm.',
                                speaker=K)}],
             'else': [{'say': B('LOGGO is up the STAIRS on the right. He keeps your first '
                                'monster.', speaker=K)}]}]}, name='king')
        d.update_npc(room, '0', 0, 0, script=k)
        wsid = d.new_conversation(room, {'steps': [{'say': B(
            'Heh heh! GREATLOG is my home. The GreatTree folk never visit.',
            speaker='Warubou')}]}, name='warubou')
        d.update_npc(room, '0', 0, 1, script=wsid)
        gsid = d.new_conversation(room, {'steps': [{'say': B(
            'The STAIRS behind you lead back to the GREATLOG PATH.')}]}, name='guard')
        d.update_npc(room, '0', 0, 2, script=gsid)
        return sid
    push('Throne room', throne_npcs)

    # =========================================================== 11. the farm
    # Rooms tab → Add NPC here… → the NPC → Service… → Farm keeper → "hands over the first
    # monster" (ServiceDialog: S152)
    def farm_npcs(d):
        room = d.room(farm)
        d.add_npc(room, '0', 0, 6, 3, KEEPER_SPRITE, 'down')
        d.add_npc(room, '0', 0, 7, 1, 0xF0, 'down', monster=8)          # a Slime monster NPC
        d.add_npc(room, '0', 0, 9, 4, GUARD_SPRITE, 'left')
        d.add_npc(room, '1', 0, 2, 5, GLADE_SPRITE, 'down')
    push('Farm NPCs', farm_npcs)

    from editor2.app.rooms.service_dialog import ServiceDialog
    sd = ServiceDialog(s.doc, None, w)
    for i in range(sd.kinds.count()):
        if sd.kinds.item(i).data(256) == 'farm':
            sd.kinds.setCurrentRow(i)
    sd.st_on.setChecked(True)
    sd.st_species.setCurrentIndex(sd.st_species.findData(STARTER_SPECIES))
    sd.st_level.setValue(STARTER_LEVEL)
    sd.st_speaker.setText('LOGGO')
    sd.st_name.setChecked(True)          # the naming screen (the default)
    sd.st_text.set_value([['Heh! The King', 'sent you?'], ['This DragonKid is', 'yours now!'],
                          ['Give it a name,', 'then choose PICK UP'], ['to take it with', 'you!']])
    # menu lines → "a new line set…" (named on OK), its speaker on the Services tab
    sd.lines.setCurrentIndex(sd.lines.findData('__new__'))
    sd._new_set_name = 'LOGGO lines'
    kind, lines, ft, new_set = sd.result_spec()
    fm = sd.starter_spec()
    sd.deleteLater()
    if fm is None:
        raise SystemExit('the farm keeper dialog gave no first monster')

    def keeper(d):
        room = d.room(farm)
        ls = d.add_service_lines(kind, new_set) if new_set else lines
        sid = d.make_service_npc(room, '0', 0, 0, kind, ls, ft, first_monster=fm)
        d.set_service_lines_meta(ls, speaker='LOGGO')          # Services tab: speaker
        CD.name_actor(d, farm, 0, 0, 1, 'LOGGO')
        return sid
    push('LOGGO: farm keeper + first monster', keeper)

    # the LOG GUARD: state 1 (stepped aside) when guard_moved is ON; two talk scenes
    def guard(d):
        room = d.room(farm)
        got = 'first_monster_given'
        CD.name_actor(d, farm, 0, 0, 3, 'LOG GUARD')
        CD.ensure_flag(d, 'guard_moved')
        # + Add state → Duplicate this state; move the guard aside in state 1
        idx, _l = d.add_state(room, '0', copy_from=0)
        d.update_npc(room, '0', idx, 2, x=8, y=5)
        d.set_state_rules(room, [{'screens': [0], 'state': idx,
                                  'when': [{'flag': 'guard_moved', 'is': 'set'}]}])
        # talk scenes: before / after the first monster
        a = CD.new_cutscene(d, farm, 'Guard: not yet', screen=0, on='talk', actor='LOG GUARD')
        r, sc = CD.find(d, a)
        sc['trigger']['when_off'] = [got]
        sc['steps'] = [{'say': B('No monster, no GATE GLADE! LOGGO keeps your first monster. '
                                 'Talk to him.', speaker='LOG GUARD')}]
        CD.set_scene(d, a, sc)
        b = CD.new_cutscene(d, farm, 'Guard steps aside', screen=0, on='talk', actor='LOG GUARD')
        r, sc = CD.find(d, b)
        sc['trigger']['when_on'] = [got]
        sc['trigger']['once'] = 'guard_moved'
        sc['steps'] = [{'say': B('A DragonKid! You are a real master now. The GATE GLADE '
                                 'is open.', speaker='LOG GUARD')},
                       {'walk': {'actor': 'LOG GUARD', 'to': [8, 5], 'first': 'x'}},
                       {'face': {'actor': 'LOG GUARD', 'dir': 'down'}}]
        CD.set_scene(d, b, sc)
        # his words in state 1 (the NPC's own talk)
        sid = d.new_conversation(room, {'steps': [{'say': B(
            'The GATE GLADE is east. Step on the swirl to enter GREATLOG GATE!',
            speaker='LOG GUARD')}]}, name='guard_after')
        d.update_npc(room, '0', idx, 2, script=sid)
        return a, b
    push('The LOG GUARD', guard)

    # =========================================================== 12. the gate
    # Gates tab → New gate… (copy of the first gate, 3 floors) → boss floor = STUMP HOLLOW
    def gate(d):
        gid = d.new_gate(0, 'GREATLOG GATE', floors=3)
        hr = d.room(hollow)
        d.set_gate_arrival(hr, 0, 4, 6)
        d.set_gate_setting(gid, boss=hollow)
        return gid
    gid = push('New gate GREATLOG GATE', gate)

    def boss(d):
        hr = d.room(hollow)
        eid = d.add_enemy(copy_eid=2, name='Stump King', species=BOSS_SPECIES, level=2,
                          hp=6, mp=0, atk=3, **{'def': 2}, agl=2, joinability=7)
        d.add_npc(hr, '0', 0, 4, 3, 0xF0, 'down', monster=BOSS_SPECIES)
        mt = len(d.npc_entries(hr, '0', 0)) - 1
        glade = (f"room:${int(d.room(farm)['mapID'], 16):02X}", 1, 5, 5)
        d.make_boss(hr, '0', 0, mt, [eid], 'stump_king_beaten',
                    intro=[['STUMP KING:Who', 'dares wake me?']],
                    outro=[['You beat the', 'STUMP KING!']],
                    end_of_world=None,
                    leave={'dest': glade[0], 'screen': glade[1], 'x': glade[2], 'y': glade[3],
                           'say': {'boxes': [['Warubou:Heh heh!', 'Back to the glade!']]}})
        return eid
    push('The STUMP KING (Make boss…)', boss)

    # Rooms tab → GREATLOG FARM screen 1 → select (5, 3) → More ▾ → Gate entrance here…
    def portal(d):
        room = d.room(farm)
        full = d.add_gate_entrance(room, '1', 0, 5, 3, gid)
        d.paint_swirl(room, '1', 0, 5, 3)
        sid = d.new_conversation(room, {'steps': [{'say': B(
            'THE GATE GLADE: the swirl is GREATLOG GATE, a new gate of 3 floors. The STUMP '
            'KING waits at the bottom. Beat him and the swirl stops.', speaker='KEEPER')}]},
            name='glade_keeper')
        d.update_npc(room, '1', 0, 0, script=sid)
        return full
    full = push('Gate entrance in THE GATE GLADE', portal)
    if full:
        note(f'the swirl object did not fit (states {full})')

    # music (Rooms tab → the room → music)
    def music(d):
        d.set_room_music(d.room(path), '0x0F')
        d.set_room_music(d.room(throne), '0x09')
        d.set_room_music(d.room(farm), '0x12')
        d.set_room_music(d.room(hollow), '0x2E')
    push('Music', music)

    # ---------------------------------------------------------- save + build
    w.save()
    pump(0.5)
    from editor2.core import compiler as CC
    _o, _p, warns = CC.compile_project(out, REPO)
    mine = [x for x in warns if any(nm in x for nm in ('GREATLOG', 'STUMP', 'Roots room'))]
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
    info = {'variant': variant, 'story': story, 'rom': res.rom_path, 'md5': res.rom_md5,
            'rooms': {k: {'id': v, 'mid': d.room(v)['mapID']} for k, v in
                      (('roots', roots), ('path', path), ('throne', throne), ('farm', farm),
                       ('hollow', hollow))},
            'gate': gid, 'flags': {f['name']: f.get('_index') for f in d.flags()},
            'warnings': mine, 'friction': FRICTION}
    from editor2.core.project import Project
    prj = Project.load(out)
    prj.repo_root = REPO
    info['flag_numbers'] = {f['name']: prj._flag_index(f['name'], 'walk') for f in d.flags()}
    json.dump(info, open(os.path.join(out, 'opening.json'), 'w'), indent=1)
    w.close()
    return info


# =============================================================== walk
MAP_ID, SCREEN_IDX, GAME_MODE = 0xC968, 0xC925, 0xC88A
SCRIPT_FLAGS, TEXTBOX, GSTATE, SCREEN_KIND = 0xD8D7, 0xC8EB, 0xC8EB, 0xC8EF
W_CHANGING = 0xC96C
PARTY_COUNT, PARTY_LIST, SLOT0 = 0xCA8D, 0xCA8E, 0xCAC1
FLAG_BASE, EXT_FLAGS = 0xD99B, 0xD140
IN_GATE, GATE_ID, FLOOR = 0xC969, 0xC935, 0xC939
DIRV = {'up': (0, -1), 'down': (0, 1), 'left': (-1, 0), 'right': (1, 0)}


class Play:
    """A PyBoy run of the opening: helpers + the checks."""

    def __init__(self, rom, keep):
        from pyboy import PyBoy
        self.keep = keep
        if os.path.exists(rom + '.ram'):
            os.remove(rom + '.ram')
        self.p = PyBoy(rom, window='null', cgb=True, sound_emulated=False)
        self.p.set_emulation_speed(0)
        self.m = self.p.memory
        self.fails = 0
        self.n = 0
        self.t = 0

    # ---- low level
    def adv(self, n):
        for _ in range(n):
            self.p.tick()

    def tap(self, b, hold=4, wait=12):
        self.p.button_press(b)
        self.adv(hold)
        self.p.button_release(b)
        self.adv(wait)

    def snap(self, name):
        if self.keep:
            os.makedirs(self.keep, exist_ok=True)
            self.p.screen.image.save(os.path.join(self.keep, f'{self.n:02d}_{name}.png'))

    def check(self, name, ok, info=''):
        self.n += 1
        print(f"{'ok' if ok else 'FAIL'}: {name}" + (f'  ({info})' if info else ''))
        if not ok:
            self.fails += 1
        self.snap(name.split()[0])
        return ok

    def flag(self, i):
        if i >= 0x1000:
            b = EXT_FLAGS + (i - 0x1000) // 8
        else:
            b = FLAG_BASE + (i >> 3)
        return (self.m[b] >> (7 - (i & 7))) & 1

    def px(self):
        m = self.m
        return (m[0xFF93] << 8 | m[0xFF92]), (m[0xFF96] << 8 | m[0xFF95])

    def cell(self):
        x, y = self.px()
        return (x - 8) // 16, (y - 8) // 16

    def idle(self):
        m = self.m
        return (not (m[SCRIPT_FLAGS] & 1) and not (m[TEXTBOX] & 1) and m[GAME_MODE] == 1
                and m[GSTATE] == 0 and m[W_CHANGING] == 0)

    def auto(self):
        """one 4-frame slice: A on a text box, START / A on the naming screen (the name
        offered), B on another screen"""
        m = self.m
        self.t += 1
        want = set()
        if m[GAME_MODE] == 2:
            if self.t % 2 == 0:                   # a battle: A (FIGHT, the target, texts)
                want.add('a')
        elif m[GSTATE] & 0x10:
            if m[SCREEN_KIND] == 15:
                want.add('start' if (self.t // 10) % 2 == 0 else 'a')
            else:
                want.add('b')
        elif m[TEXTBOX] & 1 or m[0xC915] == 0x0B:
            if self.t % 2 == 0:
                want.add('a')
        for b in ('a', 'b', 'start'):
            (self.p.button_press if b in want else self.p.button_release)(b)
        self.adv(4)

    def until(self, cond, frames=8000, auto=True):
        for _ in range(frames // 4):
            if cond():
                break
            if auto:
                self.auto()
            else:
                self.adv(4)
        for b in ('a', 'b', 'start'):
            self.p.button_release(b)
        return cond()

    def step(self, d):
        x0, y0 = self.px()
        dx, dy = DIRV[d]
        tx, ty = x0 + 16 * dx, y0 + 16 * dy
        m0 = self.m[MAP_ID]
        self.p.button_press(d)
        for _ in range(60):
            self.p.tick()
            if self.px() != (x0, y0) or self.m[MAP_ID] != m0:
                break
        self.p.button_release(d)
        for _ in range(40):
            if self.px() == (tx, ty) or self.m[MAP_ID] != m0:
                break
            self.p.tick()
        self.adv(4)
        return self.px() == (tx, ty) or self.m[MAP_ID] != m0

    def npc_cell(self, n):
        """NPC slot n's cell now: its pixel position (+$18 X, +$1A Y, absolute) — the
        slot's +2 / +3 keep the cell it was placed on."""
        b = 0xD7D2 + 32 * n
        x = self.m[b + 0x18] | self.m[b + 0x19] << 8
        y = self.m[b + 0x1A] | self.m[b + 0x1B] << 8
        return (x - 8) // 16, (y - 8) // 16

    def npcs(self):
        out = set()
        for n in range(8):
            b = 0xD7D2 + 32 * n
            if (self.m[b + 1] or self.m[b + 2] or self.m[b + 3]) and not (self.m[b] & 0x40):
                out.add(self.npc_cell(n))
        return out

    def go(self, grid, goal):
        from collections import deque
        start = self.cell()
        blocked = self.npcs() - {goal}
        W, H = len(grid[0]), len(grid)
        q, prev = deque([start]), {start: None}
        while q:
            c = q.popleft()
            if c == goal:
                break
            for d, (dx, dy) in DIRV.items():
                n = (c[0] + dx, c[1] + dy)
                if n in prev:
                    continue
                if n == goal or (0 <= n[0] < W and 0 <= n[1] < H and grid[n[1]][n[0]]
                                 and n not in blocked):
                    prev[n] = (c, d)
                    q.append(n)
        if goal not in prev:
            return False
        path, c = [], goal
        while prev[c] is not None:
            c0, d = prev[c]
            path.append(d)
            c = c0
        for d in reversed(path):
            if not self.step(d):
                return False
        return True

    def talk(self, d):
        self.tap(d, hold=2, wait=10)
        self.tap('a', hold=3, wait=20)


def walk_grid(project_dir, room_id):
    from editor2.core.document import Document
    from editor2.core.render_project import ProjectRenderer
    d = Document(project_dir)
    r = ProjectRenderer(REPO, project_dir, d.data)
    room = d.room(room_id)
    thr = r.room_gfx(room).threshold
    keys = [int(k) for k in room['screens']]
    cols = max(k % 4 for k in keys) + 1
    rows = max(k // 4 for k in keys) + 1
    g = [[False] * (cols * 10) for _ in range(rows * 8)]
    for k in keys:
        lay = d.layout(room['screens'][str(k)]['layout']['id'])['tiles']
        for cy in range(8):
            for cx in range(10):
                g[(k // 4) * 8 + cy][(k % 4) * 10 + cx] = lay[2 * cy + 1][2 * cx + 1] >= thr
    return g


def walk_grid_vanilla(mid):
    """The walkable cells of a game room (every screen, state 0)."""
    from editor2.core.render_project import ProjectRenderer
    from editor2.core.vanilla import VanillaTable
    from editor2.core.formats import val
    r = ProjectRenderer(REPO, '/tmp', {'custom': {}})
    thr = val(r.vanilla_record(mid)['collision_threshold'])
    keys = [sr['c925'] for sr in VanillaTable(REPO).entries[mid]['sub_rooms']]
    cols = max(k % 4 for k in keys) + 1
    rows = max(k // 4 for k in keys) + 1
    g = [[False] * (cols * 10) for _ in range(rows * 8)]
    for k in keys:
        t = r.vanilla_screen_grid(mid, k)
        for cy in range(8):
            for cx in range(10):
                g[(k // 4) * 8 + cy][(k % 4) * 10 + cx] = t[2 * cy + 1][2 * cx + 1] >= thr
    return g


def walk(out, keep, negative):
    info = json.load(open(os.path.join(out, 'opening.json')))
    variant = info['variant']
    rooms = {k: (v['id'], int(v['mid'], 16)) for k, v in info['rooms'].items()}
    fl = info['flag_numbers']
    rom = os.path.join(out, 'build', 'build', 'rom.gbc')
    work = os.path.join(keep or out, 'walk_rom.gbc')
    os.makedirs(os.path.dirname(work), exist_ok=True)
    data = bytearray(open(rom, 'rb').read())
    if negative and variant != 'room':
        raise SystemExit('--negative: the room variant only (the intro starts in the bedroom)')
    if negative:
        # the newgame_start region back to the vanilla 8 bytes (ld a, $2f / ld [wMapID], a /
        # ld [wMapIDMirror], a): bank $15 $4652
        o = 0x15 * 0x4000 + 0x4652 - 0x4000
        assert data[o:o + 3] == bytes([0x21, 0x02, 0x79]), data[o:o + 4].hex()
        data[o:o + 8] = bytes([0x3E, 0x2F, 0xEA, 0x68, 0xC9, 0xEA, 0x6A, 0xC9])
    open(work, 'wb').write(data)
    P = Play(work, keep)
    m = P.m
    # ---- NEW GAME
    P.adv(280)
    P.tap('start', wait=40)
    for _ in range(40):
        P.tap('a', wait=8)
        if m[GAME_MODE] == 1 and m[MAP_ID] != 0:
            break
    roots_id, roots_mid = rooms['roots']
    if variant == 'room':
        P.check('start: NEW GAME lands in the roots room (no bedroom)', m[MAP_ID] == roots_mid,
                f'map ${m[MAP_ID]:02X}')
        P.check('start: the player is Milly from the first frame (flag $179F)', P.flag(0x179F) == 1)
    else:
        P.check('start: NEW GAME lands in the intro bedroom ($2F)', m[MAP_ID] == 0x2F,
                f'map ${m[MAP_ID]:02X}')
        # the intro: the bed scene waits for a direction press (op $4C), then Terry has
        # control in the bedroom; walking into the east room plays Warubou's scene and the
        # dresser's glow — the Milly hook's whirl to its arrival room (the roots room)
        from editor2.core.cutscenes import vanilla_script_ptrs, script_bank
        rom_b = bytes(data)
        ptrs = vanilla_script_ptrs(rom_b, 0x2F)

        def word(pos):
            i = m[0xD8D4]
            if m[0xD8D3] != 0x2F or i >= len(ptrs):
                return None
            a = ptrs[i] + 2 * (pos & 0xFFFF)
            if not 0x4000 <= a <= 0x7FFE:
                return None
            o = script_bank(0x2F) * 0x4000 + a - 0x4000
            return rom_b[o] | rom_b[o + 1] << 8

        def bed_free():
            if m[SCRIPT_FLAGS] & 1 and not (m[TEXTBOX] & 1):
                ctr = m[0xD8D5] | m[0xD8D6] << 8
                if 0xFF4C in (word(ctr), word(ctr + 1)):
                    P.tap('right', hold=6, wait=6)    # op $4C waits on a direction
            return P.idle() and m[MAP_ID] == 0x2F
        P.until(lambda: m[SCRIPT_FLAGS] & 1, frames=900, auto=False)   # the bedtime scene starts
        P.until(bed_free, frames=16000)
        P.check('intro: the bedtime scene ends, Terry has control', P.idle(),
                f'cell {P.cell()}')
        P.go(walk_grid_vanilla(0x2F), (10, 12))         # into the east room (screen 5)
        ok = P.until(lambda: m[MAP_ID] == roots_mid, frames=20000)
        P.check('intro: the dresser whirls Milly to the roots room (the Milly hook)', ok,
                f'map ${m[MAP_ID]:02X}')
        P.check('intro: the player is Milly (flag $179F)', P.flag(0x179F) == 1)
    if P.fails and negative:
        print(f'WALK: FAIL {P.fails}')
        return 1
    # the roots scene: Warubou, the naming screen, the move
    named = {'seen': False}

    def to_path():
        if m[GSTATE] & 0x10 and m[SCREEN_KIND] == 15:
            named['seen'] = True
        return m[MAP_ID] == rooms['path'][1]
    ok = P.until(to_path, frames=12000)
    P.check('roots: Warubou\'s scene asks her name (the naming screen)', named['seen'])
    P.check('roots: the name is the one offered (MILLY tiles)',
            [m[0xCA42 + i] for i in range(5)] == [0xD3, 0xD4, 0xD5, 0xD6, 0xF0],
            ' '.join(f'{m[0xCA42 + i]:02X}' for i in range(5)))
    P.check('roots → GREATLOG PATH (the scene\'s move)', ok)
    screens = []
    seen = []          # S152 r2: (screen, player cell, Warubou shown?, his cell) on the path

    loads = {'prev': m[W_CHANGING], 'n': 0}   # S152 r2: room loads once on the door screen

    def to_throne():
        k = m[SCREEN_IDX]
        c = m[W_CHANGING]
        if c and not loads['prev'] and 0 in screens and screens[-1] == 0 or \
                (c and not loads['prev'] and m[MAP_ID] == rooms['throne'][1]):
            loads['n'] += 1
        loads['prev'] = c
        if m[MAP_ID] == rooms['path'][1] and (not screens or screens[-1] != k):
            screens.append(k)
        if m[MAP_ID] == rooms['path'][1] and m[W_CHANGING] == 0 and m[GSTATE] & 0x20 == 0:
            wb = None
            for n in range(8):
                b = 0xD7D2 + 32 * n
                if m[b + 1] == WARUBOU:
                    wb = (not (m[b] & 0x40), P.npc_cell(n))
            seen.append((k, P.cell(), wb))
        return m[MAP_ID] == rooms['throne'][1] and P.idle()
    ok = P.until(to_throne, frames=16000)
    P.check('path: the scenes walk her up screen 4 then screen 0 (no control)',
            screens[-2:] == [4, 0], f'screens {screens}')
    # the user's r1 report: on screen 0 Milly was out of sight (a row below the screen)
    # while Warubou appeared, walked ABOVE the hole and vanished — the game's way: she is
    # on the screen the whole time, he stands there when it loads and goes INTO the hole
    s0 = [x for x in seen if x[0] == 0]
    s4 = [x for x in seen if x[0] == 4]
    off = [c for _k, c, _w in s0 if not 0 <= c[1] <= 7] + \
          [c for _k, c, _w in s4 if not 8 <= c[1] <= 15]
    P.check('path: Milly is on the screen the whole walk (both screens)', s0 and s4 and not off,
            f'off-screen samples {off[:4]} (of {len(s0) + len(s4)})')
    first0 = s0[0][2] if s0 else None
    first4 = s4[0][2] if s4 else None
    P.check('path: Warubou stands there when each screen appears (no pop-in)',
            bool(first0 and first0[0] and first0[1] in ((4, 6), (4, 5))
                 and first4 and first4[0] and first4[1] in ((4, 13), (4, 12))),
            f'{first4} / {first0} (the first samples after the fade; he starts walking at once)')
    P.check('path → throne: ONE room load (the door does not fire mid-scene)', loads['n'] == 1,
            f"{loads['n']} loads")
    rows = sorted({w[1][1] for _k, _c, w in s0 if w and w[0]})
    P.check('path: Warubou goes INTO the hole (row 2), never above it', rows and min(rows) == 2,
            f'his rows on screen 0 {rows}')
    P.check('path → GREATLOG THRONE, the King\'s scene played, control back', ok,
            f'map ${m[MAP_ID]:02X} cell {P.cell()}')
    P.check('throne: the scene put her before the King', P.cell() == (4, 4), str(P.cell()))
    # S152 r2: she went into the hole hidden (op $0D 0,$FF90,$40, as the game does); the
    # hidden bit survives the room change — the compiler's arrival scene shows her again
    P.check('throne: Milly is shown again (HRAM $FF90 bit 6 clear)', not (m[0xFF90] & 0x40),
            f'$FF90 = ${m[0xFF90]:02X}')
    P.check('throne: flag met_king ON', P.flag(fl['met_king']) == 1)
    # the original opening's state (New game: as after the opening)
    # $0000 / $D974: the start scene (room) or the Milly hook's whirl (intro, S152)
    want_f = [0x0000, 0x0001, 0x0002, 0x0005, 0x0007, 0x0008]
    got_f = [f for f in want_f if P.flag(f)]
    P.check('story: the original opening\'s flags $0000-$0008 ON', got_f == want_f,
            ' '.join(f'${f:04X}' for f in got_f))
    bytes_ = {0xD92B: 1, 0xD92C: 3, 0xD92D: 1, 0xD93C: 1, 0xD93F: 1, 0xD940: 1, 0xD944: 1,
              0xD974: 1}
    bad = {f'${a:04X}': m[a] for a, v in bytes_.items() if m[a] != v}
    P.check('story: the Castle / GreatTree / Gate Hub / Farm room states as after the opening',
            not bad, str(bad))
    # ---- walk to the stairs up (8, 5) → the farm
    g = walk_grid(out, rooms['throne'][0])
    P.go(g, (8, 5))
    ok = P.until(lambda: m[MAP_ID] == rooms['farm'][1] and P.idle(), frames=600, auto=False)
    P.check('throne: the STAIRS walked → GREATLOG FARM', ok, f'map ${m[MAP_ID]:02X} {P.cell()}')
    gf = walk_grid(out, rooms['farm'][0])
    # ---- the LOG GUARD before
    P.go(gf, (8, 4))
    P.talk('right')
    said = P.until(lambda: m[TEXTBOX] & 1, frames=200, auto=False)
    P.until(P.idle, frames=3000)
    P.check('guard: talks while there is no monster', said)
    P.step('right')
    P.check('guard: blocks the way east', P.cell() == (8, 4), str(P.cell()))
    # ---- LOGGO: the first monster
    P.go(gf, (6, 4))
    P.talk('up')
    seen = {'name': False, 'farm': False}

    def to_menu():
        if m[GSTATE] & 0x10 and m[SCREEN_KIND] == 15:
            seen['name'] = True
        if m[GSTATE] & 0x10 and m[SCREEN_KIND] == 3:
            seen['farm'] = True
            return True
        return False
    P.until(to_menu, frames=8000)
    slot = [(s, m[SLOT0 + 0x95 * s], m[SLOT0 + 0x95 * s + 9]) for s in range(20)
            if m[SLOT0 + 0x95 * s]]
    P.check('LOGGO: the DragonKid waits in the farm (slot flag 1)',
            any(sp == STARTER_SPECIES and f == 1 for _s, f, sp in slot), str(slot))
    P.check('LOGGO: the naming screen for it', seen['name'])
    nick = [m[SLOT0 + 1 + i] for i in range(8)]
    P.check('LOGGO: it has a name (not "0000")', nick[0] not in (0x00, 0x9F),
            ' '.join(f'{x:02X}' for x in nick))
    P.check('LOGGO: the farm menu opens', seen['farm'])
    if os.environ.get('WALK_DEBUG'):
        with open(os.path.join(keep, 'farm_menu.state'), 'wb') as fh:
            P.p.save_state(fh)
    # PICK UP → the monster → OK, then EXIT
    P.adv(200)
    for b, wt in [('down', 60), ('a', 120), ('a', 120), ('down', 60), ('a', 120), ('a', 120)]:
        P.tap(b, hold=6, wait=wt)
    P.check('PICK UP: the DragonKid is in the party', m[PARTY_COUNT] == 1
            and m[SLOT0 + 0x95 * m[PARTY_LIST] + 9] == STARTER_SPECIES
            and m[SLOT0 + 0x95 * m[PARTY_LIST] + 0x4B] == STARTER_LEVEL,
            f'party {m[PARTY_COUNT]} species {m[SLOT0 + 0x95 * m[PARTY_LIST] + 9]}')
    for b, wt in [('b', 90), ('a', 60)]:        # B leaves the menu, A the farewell
        P.tap(b, hold=6, wait=wt)
    P.until(P.idle, frames=2000)
    P.check('LOGGO: flag first_monster_given ON', P.flag(fl['first_monster_given']) == 1)
    if os.environ.get('WALK_DEBUG'):
        print('  dbg after farm:', 'gs', hex(m[GSTATE]), 'tb', m[TEXTBOX], 'sf', m[SCRIPT_FLAGS],
              'mode', m[GAME_MODE], 'chg', m[W_CHANGING], 'cell', P.cell(), 'idle', P.idle())
        with open(os.path.join(keep, 'after_farm.state'), 'wb') as fh:
            P.p.save_state(fh)
    # ---- the LOG GUARD after
    P.go(gf, (8, 4))
    P.talk('right')
    P.until(P.idle, frames=4000)
    P.check('guard: steps aside (flag guard_moved)', P.flag(fl['guard_moved']) == 1)
    gx = None
    for n in range(8):
        if m[0xD7D2 + 32 * n + 1] == GUARD_SPRITE:
            gx = P.npc_cell(n)
    P.check('guard: now stands at (8, 5)', gx == (8, 5), str(gx))
    # ---- east into THE GATE GLADE
    ok = P.go(gf, (12, 4))
    P.check('glade: walked east through the gap onto screen 1', m[SCREEN_IDX] == 1, f'screen {m[SCREEN_IDX]} {P.cell()}')
    swirl = [n for n in range(8) if m[0xD7D2 + 32 * n + 1] == 0x4D and not (m[0xD7D2 + 32 * n] & 0x40)]
    P.check('glade: the portal\'s swirl spins (gate not cleared)', bool(swirl), str(swirl))
    # ---- the portal (15, 3) on screen 1
    P.go(gf, (15, 4))
    P.step('up')
    ok = P.until(lambda: m[IN_GATE] != 0 and P.idle(), frames=1500, auto=True)
    P.check('portal: GREATLOG GATE entered (gate 32, floor 1)',
            m[IN_GATE] != 0 and m[GATE_ID] == info['gate'] and m[FLOOR] == 0,
            f'in gate {m[IN_GATE]:02X} gate {m[GATE_ID]} floor index {m[FLOOR]}')
    # ---- down to the boss floor: the staircase kick (PYBOY_DEBUGGING S100) — floor 3 of 3
    m[0xCA39], m[0xCA3A] = 0xFF, 0x7F                     # no wild battle on the way
    m[GATE_ID] = info['gate']
    m[FLOOR] = 3 - 2
    m[0xC96D], m[0xC96E] = 0, 0x80
    m[W_CHANGING] = 1
    m[0xC88F] = (m[0xC88F] + 1) & 0xFF
    ok = P.until(lambda: m[MAP_ID] == rooms['hollow'][1] and P.idle(), frames=3000)
    P.check('boss floor: STUMP HOLLOW (floor 3)', ok, f'map ${m[MAP_ID]:02X} floor {m[FLOOR]}')
    gh = walk_grid(out, rooms['hollow'][0])
    P.go(gh, (4, 4))
    P.talk('up')
    beaten = fl['stump_king_beaten']
    battle = {'seen': False}

    def back():
        if m[GAME_MODE] == 2:
            battle['seen'] = True
        return m[MAP_ID] == rooms['farm'][1] and P.idle()
    ok = P.until(back, frames=40000)
    P.check('boss: the STUMP KING\'s battle', battle['seen'])
    P.check('boss: beaten (flag stump_king_beaten)', P.flag(beaten) == 1)
    P.check('boss: GREATLOG GATE cleared (its own flag $17C0)', P.flag(0x17A0 + info['gate']) == 1)
    P.check('boss: Warubou takes her back to THE GATE GLADE', ok and m[SCREEN_IDX] == 1,
            f'map ${m[MAP_ID]:02X} screen {m[SCREEN_IDX]} {P.cell()}')
    swirl = [n for n in range(8) if m[0xD7D2 + 32 * n + 1] == 0x4D and not (m[0xD7D2 + 32 * n] & 0x40)]
    P.check('glade: the spinning swirl is gone (gate cleared)', not swirl, str(swirl))
    # ---- the guard stays aside after the room loads again (its room state)
    P.go(gf, (7, 4))                                   # back west through the gap
    P.until(P.idle, frames=600, auto=False)
    gx = None
    for n in range(8):
        if m[0xD7D2 + 32 * n + 1] == GUARD_SPRITE:
            gx = P.npc_cell(n)
    P.check('guard: after the room loaded again he stands aside (room state 1)', gx == (8, 5),
            str(gx))
    # ---- the game's own Castle: as after the opening (no Minister, no Slib)
    # Castle script 0 runs on screen 1 (story_state.py): the Minister / King opening and
    # Slib (add_monster: a new monster slot) while $0001 is OFF
    before = sum(1 for sl in range(20) if m[SLOT0 + 0x95 * sl])
    m[SCRIPT_FLAGS] = 0
    m[0xC96D], m[0xC96E] = 0x00, 0
    px_, py_ = (10 + 5) * 16 + 8, (0 + 6) * 16 + 8                # Castle screen 1 (5, 6)
    m[0xC96F], m[0xC970], m[0xC971], m[0xC972] = px_ & 255, px_ >> 8, py_ & 255, py_ >> 8
    m[W_CHANGING] = 1
    m[0xC88F] = (m[0xC88F] + 1) & 0xFF
    texts = {'n': 0}

    def castle():
        if m[TEXTBOX] & 1:
            texts['n'] += 1
        return m[MAP_ID] == 0x00 and P.idle()
    ok = P.until(castle, frames=40000)
    after = sum(1 for sl in range(20) if m[SLOT0 + 0x95 * sl])
    P.check('the game\'s Castle: no opening scene plays (as after the opening)',
            ok and texts['n'] == 0, f'text frames {texts["n"]}')
    P.check('the game\'s Castle: no Slib given', after == before, f'{before} -> {after}')
    print(f'WALK: {"PASS" if not P.fails else "FAIL " + str(P.fails)}')
    return 1 if P.fails else 0


# =============================================================== main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=['make', 'walk'])
    ap.add_argument('--out', required=True)
    ap.add_argument('--variant', default='room', choices=['room', 'intro'])
    ap.add_argument('--keep')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--story', default='opening_done', choices=['opening_done', 'untouched'])
    a = ap.parse_args()
    if a.cmd == 'make':
        make(a.out, a.variant, a.story)
    else:
        sys.exit(walk(a.out, a.keep, a.negative))


if __name__ == '__main__':
    main()
