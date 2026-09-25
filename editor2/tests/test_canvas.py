#!/usr/bin/env python3
"""test_canvas.py — room-canvas acceptance (S93 v1 + S94 v2), headless.

Layers, each a hard assertion:

0. VANILLA — all vanilla rooms render live; a clone renders pixel-identical
   to its vanilla source on every screen (per-screen attr maps, S94).

4. V2 ROUND TRIP (S94) — on a FRESH project from the blank template:
   clone the Farm, paint metatiles on the cell grid, flip one grass cell to
   a wall and one fence cell to walkable (tileset copied into the project,
   twin subtiles), copy + rename the room, exact undo/redo incl. the
   tileset asset file, save, compile.  --rom: build, PyBoy: VRAM tilemap ==
   canvas on the edited screen AND the player is blocked by the new wall /
   walks through the opened fence (walkability = bottom-right subtile).

1. RENDER PARITY — the live project renderer (core/render_project.py) is
   pixel-identical to the ROM-built renderer (core/render.py, itself
   PyBoy-validated S72) on EVERY screen of the example project. Needs an
   existing example-project build (test_compiler --rom / build_project).

2. GUI ROUND TRIP — on a scratch COPY of the example project, drive the
   real Rooms-tab code path: pencil / rect / fill / attr strokes, add a
   second state with its own layout copy, paint it, add a screen; assert
   exact undo (full undo => project.json byte-identical to disk), save,
   and that the compiler accepts the result. The example project itself
   is never touched (the S92 pin stays).

3. --rom: BUILD + EMULATE — build the scratch project, boot PyBoy through
   the scripted intro, warp into the edited room with the step counter at
   0 and at 1, and assert the BG tilemap in VRAM ($9800) equals the
   canvas grid of each state tile-for-tile (and that the two states
   differ). This is the ROADMAP P3.3 acceptance test.

   --out DIR keeps the scratch project + ROM (used to produce the user
   test ROM).

SKIPs (exit 0) without PySide6, like test_app.py.
"""

import copy
import json
import os
import shutil
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')

try:
    from PySide6.QtWidgets import QApplication          # noqa: E402
except ImportError:
    print('SKIP: PySide6 not installed (pip install PySide6 Pillow)')
    sys.exit(0)

from editor2.core.document import val          # noqa: E402

EXAMPLE = os.path.join(REPO, 'editor2', 'example-project')
ROOM = 'medal_vault'          # $71: own record, project-owned layout
COUNTER_LABEL = 'wCustomStep_Room71_S0'


def test_render_parity():
    from editor2.core.render import RoomRenderer, find_build
    from editor2.core.render_project import ProjectRenderer
    from PIL import ImageChops
    found = find_build(EXAMPLE)
    if not found:
        print('NOTE: example project has no build — parity check skipped '
              '(python3 tools/build_project.py --project editor2/example-project --build)')
        return
    rom, sym = found
    data = json.load(open(os.path.join(EXAMPLE, 'project.json')))
    rr = RoomRenderer(rom, sym)
    pr = ProjectRenderer(REPO, EXAMPLE, data, build_rom_path=rom)
    n = 0
    for room in data['custom']['rooms']:
        if room.get('placeholder'):
            continue
        for k, img in rr.render_room(room, scale=1, markers=False).items():
            live = pr.render_screen(room, k, 0, 1)
            bbox = ImageChops.difference(img.convert('RGB'), live).getbbox()
            assert bbox is None, f'{room["id"]} screen {k}: pixels differ at {bbox}'
            n += 1
    print(f'OK: live renderer pixel-identical to the ROM-built renderer on {n} screens')


def gui_round_trip(project_dir):
    """S93 acceptance re-expressed on the v2 cell canvas. Returns
    (window, session, grids{state: 16x20}) after the edits."""
    from editor2.app.main import MainWindow
    from editor2.app.rooms.canvas import metatile_at
    app = QApplication.instance() or QApplication(sys.argv)
    w = MainWindow()
    w.open_project(project_dir)
    app.processEvents()
    rt, s = w.rooms_tab, w.session
    assert rt.canvas.tool == 'select', 'Select must be the default tool'
    for i in range(rt.room_list.count()):
        if rt.room_list.item(i).data(0x100) == ROOM:
            rt.room_list.setCurrentRow(i)
    app.processEvents()
    cv = rt.canvas
    assert cv.is_editable(), 'medal_vault layout should be project-owned'
    thr = cv.gfx.threshold
    lid0 = cv.lid
    orig = copy.deepcopy(s.doc.layout(lid0)['tiles'])
    floor = {'tiles': [thr + 2] * 4, 'pal': 3}
    # paint stroke (3 cells)
    cv.set_brush(floor)
    cv._begin_stroke()
    for c in ((1, 1), (2, 1), (2, 2)):
        cv._stroke_cell(c)
    cv._end_stroke('Paint')
    assert s.undo.count() == 1 and s.dirty
    assert cv.cell_metatile(1, 1) == floor
    assert s.doc.layout(cv.attr_lid)['attr'][2][2] == 3
    s.undo.undo()
    assert s.doc.layout(lid0)['tiles'] == orig, 'undo must restore exactly'
    s.undo.redo()
    # rectangle
    cv.set_brush({'tiles': [thr + 1] * 4, 'pal': None})
    cv._begin_stroke()
    for cy in range(6, 7):
        for cx in range(1, 3):
            cv._stroke_cell((cx, cy))
    cv._end_stroke('Rectangle')
    # second state with its OWN layout copy, painted visibly: black holes
    rt._add_state(copy=True, own=True)
    app.processEvents()
    room = s.doc.room(ROOM)
    assert len(s.doc.states(room, 0)) == 2
    assert rt.state_idx == 1 and cv.lid != lid0, 'state 1 must own its layout'
    lid1 = cv.lid
    cv.set_brush({'tiles': [60, 61, 62, 63], 'pal': 1})
    cv._begin_stroke()
    for cy in range(2, 6):
        for cx in range(2, 8):
            cv._stroke_cell((cx, cy))
    cv._end_stroke('Rectangle')
    assert s.doc.layout(lid0)['tiles'] != s.doc.layout(lid1)['tiles']
    # add a screen (record dims follow) — 4x4 grid: screen 8 is row 2
    rt._add_screen(8)
    app.processEvents()
    room = s.doc.room(ROOM)
    assert s.doc.screen_keys(room) == [0, 8]
    assert room['record']['width_px'] == 160 and room['record']['height_px'] == 384
    # full undo == disk, redo, save
    n = s.undo.count()
    for _ in range(n):
        s.undo.undo()
    assert s.doc.dumps() == open(s.doc.path).read(), \
        'full undo must leave project.json byte-identical to disk'
    assert not s.dirty
    for _ in range(n):
        s.undo.redo()
    assert w.save()
    assert not s.dirty
    reloaded = json.load(open(s.doc.path))
    r2 = [r for r in reloaded['custom']['rooms'] if r['id'] == ROOM][0]
    assert len(r2['screens']['0']['states']) == 2
    assert 'npcs' not in r2['screens']['0'], 'states form must not keep top-level npcs'
    print(f'OK: GUI round trip — {n} undoable edits, exact undo, saved, '
          f'2 states ({lid0} / {lid1}), screen 8 added (4x4 grid)')
    return w, s, {0: copy.deepcopy(s.doc.layout(lid0)['tiles']),
                  1: copy.deepcopy(s.doc.layout(lid1)['tiles'])}


def test_vanilla(project_dir):
    from editor2.core.render_project import ProjectRenderer
    from editor2.core.document import Document
    from PIL import ImageChops
    d = Document(project_dir)
    pr = ProjectRenderer(REPO, project_dir, d.data)
    rooms = pr.vanilla_rooms()
    assert len(rooms) >= 90, f'only {len(rooms)} vanilla rooms listed'
    n = 0
    for mid, _name, scr in rooms:
        for k in scr:
            pr.render_vanilla_screen(mid, k, 1)
            n += 1
    print(f'OK: {len(rooms)} vanilla rooms, {n} screens render live')
    # clone == vanilla on every screen (needs per-screen attr maps)
    rid = d.clone_vanilla(0x04, 'Farm', REPO, pr)
    pr.invalidate()
    room = d.room(rid)
    for k in d.screen_keys(room):
        a = pr.render_screen(room, k, 0, 1)
        b = pr.render_vanilla_screen(0x04, k, 1)
        assert ImageChops.difference(a, b).getbbox() is None, \
            f'Farm clone screen {k} differs from vanilla'
    print(f'OK: Farm clone renders pixel-identical to vanilla on {len(d.screen_keys(room))} screens')


V2_STAND_A, V2_CELL_A = (5, 2), (5, 3)      # grass -> WALL (approach from above)
V2_STAND_B, V2_CELL_B = (4, 4), (3, 4)      # fence -> walkable (approach from right)


def v2_round_trip(new_dir):
    """Fresh project from the blank template; clone Farm; edit screen 4."""
    from editor2.app.main import MainWindow
    from editor2.app.rooms.canvas import metatile_at
    from PySide6.QtWidgets import QMessageBox
    app = QApplication.instance() or QApplication(sys.argv)
    QMessageBox.question = staticmethod(lambda *a, **k: QMessageBox.Yes)
    w = MainWindow()
    w.new_project(new_dir, 'v2 acceptance')
    app.processEvents()
    rt, s = w.rooms_tab, w.session
    assert len(s.doc.rooms) == 0 and rt.vanilla_list.count() >= 90
    for i in range(rt.vanilla_list.count()):
        if rt.vanilla_list.item(i).data(0x100) == 0x04:
            rt.vanilla_list.setCurrentRow(i)
    app.processEvents()
    assert rt.canvas.is_vanilla() and not rt.canvas.is_editable()
    rt._clone_vanilla()
    app.processEvents()
    rid = rt.room_id
    room = s.doc.room(rid)
    assert room['mapID'] in ('0x6B', 0x6B) and s.doc.screen_keys(room) == [0, 1, 2, 4, 5, 6]
    assert rt.canvas.is_editable()
    # paint two water cells (metatile harvested from screen 0) onto screen 4
    water = metatile_at(s.doc.layout(f'{rid}_s0')['tiles'],
                        s.doc.layout(f'{rid}_s0')['attr'], 0, 0)
    rt.select_screen(4)
    app.processEvents()
    cv = rt.canvas
    cv.set_brush(water)
    cv._begin_stroke()
    cv._stroke_cell((8, 0))
    cv._stroke_cell((9, 0))
    cv._end_stroke('Paint')
    assert cv.cell_metatile(8, 0) == water
    # S95: the picker keeps the room's whole vocabulary — paint over the only
    # cell holding some metatile and it must still be offered
    before = {(tuple(m['tiles']), m['pal']) for m in rt.picker.found}
    grid4 = s.doc.layout(f'{rid}_s4')['tiles']
    attr4 = s.doc.layout(f'{rid}_s4')['attr']
    from collections import Counter
    cnt = Counter((tuple(metatile_at(grid4, attr4, cx, cy)['tiles']),
                   metatile_at(grid4, attr4, cx, cy)['pal'])
                  for cy in range(8) for cx in range(10))
    lonely = next(k for k, n in cnt.items() if n == 1)
    cell = next((cx, cy) for cy in range(8) for cx in range(10)
                if (tuple(metatile_at(grid4, attr4, cx, cy)['tiles']),
                    metatile_at(grid4, attr4, cx, cy)['pal']) == lonely)
    cv._begin_stroke(); cv._stroke_cell(cell); cv._end_stroke('Paint')
    app.processEvents()
    after = {(tuple(m['tiles']), m['pal']) for m in rt.picker.found}
    assert lonely in after and before <= after, 'vocabulary must never shrink'
    s.undo.undo()
    app.processEvents()
    # S95: borrow tiles from another room — Castle ($00) uses a different
    # tileset, so a click imports the 4 subtiles into this room's tileset
    i = rt.foreign_box.findData(0x00)
    assert i > 0
    rt.foreign_box.setCurrentIndex(i)
    app.processEvents()
    assert rt.picker_foreign.foreign and not rt.picker_foreign.foreign_same
    n_free_before = 128 - len(s.doc.used_tiles(s.doc.tileset_key(s.doc.room(rid)))) \
        if 'tileset' in s.doc.room(rid)['record'] else None
    foreign_mt = rt.picker_foreign.foreign[5]
    rt._import_metatile(foreign_mt)
    app.processEvents()
    rec = s.doc.room(rid)['record']
    assert 'tileset' in rec, 'import must localize the tileset'
    mine = s.doc.metatiles(rec['tileset'])
    assert mine and mine[-1]['pal'] == foreign_mt['pal']
    imported = mine[-1]
    sheet = s.doc.read_sheet(rec['tileset'])
    src_sheet = s.renderer.vanilla_gfx(0x00).sheet
    for t_src, t_dst in zip(foreign_mt['tiles'], imported['tiles']):
        assert bytes(sheet[t_dst * 16:t_dst * 16 + 16]) == \
            bytes(src_sheet[(t_src & 0x7F) * 16:(t_src & 0x7F) * 16 + 16]), 'graphic copied'
    thr = val(rec['collision_threshold'])
    src_thr = s.renderer.vanilla_gfx(0x00).threshold
    assert (imported['tiles'][3] < thr) == ((foreign_mt['tiles'][3] & 0x7F) < src_thr), \
        'bottom-right subtile keeps its walkability side'
    assert cv.brush == imported
    s.undo.undo()
    app.processEvents()
    assert not s.doc.metatiles(s.doc.tileset_key(s.doc.room(rid))), 'import undone'
    s.undo.redo()
    app.processEvents()
    rt.foreign_box.setCurrentIndex(0)
    app.processEvents()
    # place the imported metatile at (7,0) — the --rom check reads it back from VRAM
    cv = rt.canvas
    cv.set_brush(imported)
    cv._begin_stroke(); cv._stroke_cell((7, 0)); cv._end_stroke('Paint')
    app.processEvents()
    assert cv.cell_metatile(7, 0)['tiles'] == imported['tiles']
    print('OK: vocabulary persists; Castle metatile imported into the Farm tileset (undo/redo exact)')
    # walkability flips (tileset gets copied into the project)
    assert cv.cell_walkable(*V2_CELL_A) and not cv.cell_walkable(*V2_CELL_B)
    rt._flip_walk(*V2_CELL_A)
    app.processEvents()
    rt._flip_walk(*V2_CELL_B)
    app.processEvents()
    cv = rt.canvas
    assert not cv.cell_walkable(*V2_CELL_A) and cv.cell_walkable(*V2_CELL_B)
    rec = s.doc.room(rid)['record']
    assert 'tileset' in rec, 'walkability flip must localize the tileset'
    asset = os.path.join(new_dir, s.doc.tileset_item(rec['tileset'])['raw2bpp'])
    assert os.path.exists(asset)
    # the graphics did not change: clone screen 4 still renders like vanilla
    # except the two painted cells
    from PIL import ImageChops
    a = s.renderer.render_screen(s.doc.room(rid), 4, 0, 1)
    b = s.renderer.render_vanilla_screen(0x04, 4, 1)
    bbox = ImageChops.difference(a, b).getbbox()
    assert bbox == (112, 0, 160, 16), f'only the painted cells may differ, got {bbox}'
    # copy + rename
    rt._rename_to('Farm (mine)')
    assert s.doc.room_name(s.doc.room(rid)) == 'Farm (mine)'
    # S94b entrance redirect: GreatTree 2F Library door (screen 8, (5,3))
    # -> this clone, screen 4, standing on the opened fence's neighbour
    from editor2.app.rooms.redirect_dialog import RedirectDialog, ExitDialog
    from editor2.app.rooms import commands as C
    dlg = RedirectDialog(s, rid, rt)
    v = dlg.values()
    assert (v['source_mid'], v['screen'], v['x'], v['y']) == (0x01, 8, 5, 3), v
    assert dlg.src_door.currentText().startswith('(5,3) door → Library'), dlg.src_door.currentText()
    dlg.deleteLater()
    rt._add_redirect_entry(0x01, 8, 5, 3, 4, V2_STAND_B[0], V2_STAND_B[1])
    app.processEvents()
    reds = s.doc.redirects_to(rid)
    assert len(reds) == 1 and reds[0][1]['screen_byte'] == '0x04', reds
    assert rt.inspector.redirect_list.count() == 1
    # the vanilla view shows the routed door as a redirect marker
    for i in range(rt.vanilla_list.count()):
        if rt.vanilla_list.item(i).data(0x100) == 0x01:
            rt.vanilla_list.setCurrentRow(i)
    rt.select_screen(8)
    app.processEvents()
    kinds = {(m[0], m[1], m[2]) for m in rt.canvas.markers}
    assert ('redirect', 5, 3) in kinds and ('exit', 4, 5) in kinds, kinds
    rt.room_list.setCurrentRow(0)
    rt.select_screen(4)
    app.processEvents()
    assert any(m[0] == 'entrance' for m in rt.canvas.markers)
    # palette double-click on a borrowed palette offers to copy it (S94b);
    # the clone owns pal_farm already, so the words are editable directly
    pid, words = s.renderer.room_palettes_555(s.doc.room(rid), 4, 0)
    assert pid == 'pal_farm' and words is not None
    # exact undo incl. the asset file, then redo
    n = s.undo.count()
    for _ in range(n):
        s.undo.undo()
    assert len(s.doc.rooms) == 0 and not os.path.exists(asset)
    for _ in range(n):
        s.undo.redo()
    assert os.path.exists(asset) and s.doc.room_name(s.doc.room(rid)) == 'Farm (mine)'
    # ---- S95: servant room ($3F, 2 states: burning / cleared). Delete the
    # burning state, add a screen: the new screen must keep the CLEARED
    # palette, not fall back to the room default (user report).
    for i in range(rt.vanilla_list.count()):
        if rt.vanilla_list.item(i).data(0x100) == 0x3F:
            rt.vanilla_list.setCurrentRow(i)
    app.processEvents()
    assert rt.canvas.is_vanilla()
    rt._clone_vanilla()
    app.processEvents()
    sid = rt.room_id
    srv = s.doc.room(sid)
    assert srv['mapID'] in ('0x6C', 0x6C) and len(s.doc.states(srv, 0)) == 2
    green = s.doc.states(srv, 0)[1].get('palette')
    assert green and green != (srv.get('render') or {}).get('palette'), 'state 1 has its own palette'
    s.undo.push(C.RemoveState(s, sid, 0, 0))     # drop the burning state
    rt.state_idx = 0
    rt._show()
    app.processEvents()
    assert s.doc.effective_palette(s.doc.room(sid), 0, 0) == green
    rt._add_screen(1)
    app.processEvents()
    assert s.doc.effective_palette(s.doc.room(sid), 1, 0) == green, 'new screen inherits the shown palette'
    assert s.renderer.state_palette_id(s.doc.room(sid), 1, 0) == green
    # per-screen palette selector: copy a vanilla room's palette onto screen 1
    rt.select_screen(1)
    app.processEvents()
    rt._state_palette_chosen(('vanilla', 0x04))
    app.processEvents()
    pid1 = s.doc.effective_palette(s.doc.room(sid), 1, 0)
    assert pid1.startswith('pal_from_04') and s.doc.palette(pid1)
    assert s.doc.effective_palette(s.doc.room(sid), 0, 0) == green, 'screen 0 untouched'
    rt._state_palette_chosen(None)
    app.processEvents()
    assert s.doc.effective_palette(s.doc.room(sid), 1, 0) == (srv.get('render') or {}).get('palette')
    s.undo.undo()                                   # back to pal_from_04
    app.processEvents()
    assert s.doc.effective_palette(s.doc.room(sid), 1, 0) == pid1
    # exits: a staircase on screen 0 of the servant clone -> Farm clone screen 4
    rt.select_screen(0)
    app.processEvents()
    dlg = ExitDialog(s, sid, 0, (5, 5), rt)
    for k in range(dlg.dst_room.count()):
        if dlg.dst_room.itemData(k) == ('room', rid):
            dlg.dst_room.setCurrentIndex(k)
    j = dlg.dst_screen.findData(4)
    dlg.dst_screen.setCurrentIndex(j)
    dlg.dst_x.setValue(V2_STAND_B[0]); dlg.dst_y.setValue(V2_STAND_B[1])
    ev = dlg.values()
    assert ev['dest'] == 'room:$6B' and ev['dest_screen'] == 4, ev
    dlg.deleteLater()
    s.undo.push(C.SnapshotCommand(s, 'Add exit', lambda doc: doc.add_exit(
        doc.room(sid), 0, 0, ev['x'], ev['y'], ev['dest'], ev['dest_screen'],
        ev['spawn_x'], ev['spawn_y'])))
    rt._show()
    app.processEvents()
    rows = s.doc.states(s.doc.room(sid), 0)[0]['exits']
    assert any(val(e['x']) == 5 and val(e['y']) == 5 and e['dest'] == 'room:$6B' for e in rows)
    assert any(m[0] == 'exit' and m[1] == 5 and m[2] == 5 for m in rt.canvas.markers)
    idx = next(i for i, e in enumerate(rows) if val(e['x']) == 5 and val(e['y']) == 5)
    rt._remove_exit(idx)
    app.processEvents()
    assert not any(val(e['x']) == 5 and val(e['y']) == 5
                   for e in s.doc.states(s.doc.room(sid), 0)[0]['exits'])
    s.undo.undo()
    app.processEvents()
    assert any(val(e['x']) == 5 and val(e['y']) == 5
               for e in s.doc.states(s.doc.room(sid), 0)[0]['exits'])
    # back to the Farm clone for the remaining checks
    for i in range(rt.room_list.count()):
        if rt.room_list.item(i).data(0x100) == rid:
            rt.room_list.setCurrentRow(i)
    rt.select_screen(4)
    app.processEvents()
    print('OK: servant clone — burning state removed, new screen keeps the cleared palette; '
          'per-screen palette copied from Farm; staircase exit added/removed/undone')
    assert w.save()
    # the imported cell renders the CASTLE graphic under the Farm palette
    from PIL import Image as _I
    cell_img = a.crop((112, 0, 128, 16))
    ref = _I.new('RGB', (16, 16))
    for i, t in enumerate(foreign_mt['tiles']):
        ref.paste(s.renderer.render_tile(src_sheet, t & 0x7F, s.renderer.room_palettes(s.doc.room(rid), 4, 0),
                                         foreign_mt['pal']), ((i % 2) * 8, (i // 2) * 8))
    assert ImageChops.difference(cell_img, ref).getbbox() is None, 'imported cell must show the source graphic'
    print(f'OK: v2 round trip — fresh project, Farm cloned to $6B, metatiles painted, '
          f'walkability flipped both ways ({n} undoable edits, exact undo incl. asset)')
    return w, s, rid


def test_rom_v2(w, s, rid, keep_dir=None):
    from editor2.app.build_worker import BuildWorker
    app = QApplication.instance()
    results = []
    worker = BuildWorker(REPO, s.project_dir)
    worker.log.connect(lambda t: print('  |', t))
    worker.finished_build.connect(results.append)
    worker.start()
    worker.wait()
    app.processEvents()
    res = results[0]
    assert res.ok, f'build failed: {res.error}'
    rom = res.rom_path
    from tools.pyboy_harness import boot, to_bedroom, warp, adv, MAP_ID
    grid = s.doc.layout(f'{rid}_s4')['tiles']
    p = boot(rom)
    assert to_bedroom(p), 'scripted intro failed'
    p.memory[0xCA39] = p.memory[0xCA3A] = 0xFF

    def settle():
        for i in range(300):
            if i % 8 < 4:
                p.button_press('b')
            else:
                p.button_release('b')
            p.tick()
        p.button_release('b')
        adv(p, 60)

    def pos():
        return p.memory[0xFF97], p.memory[0xFF98]

    def walk(d, frames=48):
        for _ in range(frames):
            p.button_press(d)
            p.tick()
        p.button_release(d)
        adv(p, 24)
        return pos()
    # screen 4 = row 1: absolute tile coords (x, y+8)
    warp(p, 0x6B, V2_STAND_A[0], V2_STAND_A[1] + 8, settle=500)
    settle()
    assert p.memory[MAP_ID] == 0x6B and p.memory[0xC925] == 4, \
        f'expected $6B screen 4, got map {p.memory[MAP_ID]:02X} c925 {p.memory[0xC925]}'
    # the BG map is 32x32; screens off row/col 0 live at the SCX/SCY offset
    scx, scy = p.memory[0xFF43], p.memory[0xFF42]
    vram = [[p.memory[0x9800 + ((scy // 8 + r) % 32) * 32 + ((scx // 8 + c) % 32)]
             for c in range(20)] for r in range(16)]
    diff = [(r, c) for r in range(16) for c in range(20) if vram[r][c] != grid[r][c]]
    assert not diff, f'{len(diff)} VRAM tiles differ from the canvas grid: {diff[:5]}'
    print('OK: Farm clone screen 4 — VRAM tilemap == canvas grid (320/320), records from ROM0 $6B row')
    home = pos()                      # $FF97/$FF98 are ABSOLUTE walk coords (row 1 = y+8)
    assert home == (V2_STAND_A[0], V2_STAND_A[1] + 8), f'stand A: {home}'
    after = walk('down')
    assert after == home, f'new WALL at {V2_CELL_A} did not block: walked to {after}'
    print(f'OK: grass cell {V2_CELL_A} flipped to WALL blocks the player')
    warp(p, 0x6B, V2_STAND_B[0], V2_STAND_B[1] + 8, settle=500)
    settle()
    home = pos()
    assert home == (V2_STAND_B[0], V2_STAND_B[1] + 8), f'stand B: {home}'
    after = walk('left')
    assert after == (V2_STAND_B[0] - 1, V2_STAND_B[1] + 8), \
        f'opened fence cell {V2_CELL_B} still blocks: at {after}'
    print(f'OK: fence cell {V2_CELL_B} flipped to walkable — player walks through')
    # S94b: the redirected vanilla door — walk into the GreatTree 2F Library
    # door (screen 8 = row 2, col 0 -> absolute (5, 16+3)) and arrive in the
    # clone's screen 4 at the redirect's spawn. A neighbouring vanilla door
    # on the same screen keeps its vanilla destination.
    warp(p, 0x01, 5, 20, settle=500)
    settle()
    assert p.memory[MAP_ID] == 0x01 and p.memory[0xC925] == 8, 'GreatTree screen 8 warp'
    walk('up', 60)
    adv(p, 300)
    assert p.memory[MAP_ID] == 0x6B and p.memory[0xC925] == 4, \
        f'Library door redirect: map {p.memory[MAP_ID]:02X} scr {p.memory[0xC925]}'
    assert pos() == (V2_STAND_B[0], V2_STAND_B[1] + 8), f'redirect spawn: {pos()}'
    print('OK: GreatTree Library door redirected into the Farm clone (screen 4, spawn as authored)')
    warp(p, 0x01, 4, 20, settle=500)
    settle()
    walk('down', 60)
    adv(p, 300)
    assert p.memory[MAP_ID] == 0x18, \
        f'un-redirected door (4,5) must keep its vanilla dest $18, got {p.memory[MAP_ID]:02X}'
    print('OK: the other door on that screen still goes to its vanilla room $18')
    # S95: custom-room exit authored in the GUI — servant clone $6C, cell
    # (5,5) on screen 0 -> Farm clone screen 4 at V2_STAND_B
    warp(p, 0x6C, 5, 4, settle=500)
    settle()
    assert p.memory[MAP_ID] == 0x6C, f'servant clone warp: {p.memory[MAP_ID]:02X}'
    walk('down', 60)
    adv(p, 300)
    assert p.memory[MAP_ID] == 0x6B and p.memory[0xC925] == 4, \
        f'staircase exit: map {p.memory[MAP_ID]:02X} scr {p.memory[0xC925]}'
    assert pos() == (V2_STAND_B[0], V2_STAND_B[1] + 8), f'exit spawn: {pos()}'
    print('OK: GUI-authored exit in the servant clone walks the player into the Farm clone')
    # the per-screen palette reached the ROM: screen 1 of $6C points at pal_from_04
    b17 = open(os.path.join(s.project_dir, 'build', 'patches', 'bank_017.asm')).read()
    seg = b17.split('ScrAttr_6C_1:', 1)[1].split('ScrAttr_6C_2:')[0]
    assert 'CustomPaletteColors_pal_from_04' in seg, seg
    print('OK: screens[1].palette of the servant clone emitted into its ScrAttr row')
    if keep_dir:
        p.screen.image.save(os.path.join(keep_dir, 'pyboy_farm_s4.png'))
        shutil.copy(rom, os.path.join(keep_dir, 'rom_v2.gbc'))
    p.stop(save=False)


def test_compile(project_dir):
    from editor2.core import compiler as C
    _out, _prj, warnings = C.compile_project(project_dir, REPO)
    print(f'OK: compiler accepts the edited project ({len(warnings)} warnings)')


def test_rom(project_dir, grids, keep_dir=None):
    from editor2.app.build_worker import BuildWorker
    app = QApplication.instance()
    results = []
    worker = BuildWorker(REPO, project_dir)
    worker.log.connect(lambda t: print('  |', t))
    worker.finished_build.connect(results.append)
    worker.start()
    worker.wait()
    app.processEvents()
    res = results[0]
    assert res.ok, f'build failed: {res.error}'
    rom = res.rom_path
    manifest = json.load(open(res.manifest_path))
    counter = int(manifest['step_counters'][COUNTER_LABEL].replace('$', ''), 16)
    from tools.pyboy_harness import boot, to_bedroom, warp, adv, MAP_ID
    p = boot(rom)
    assert to_bedroom(p), 'scripted intro failed'
    for state in (0, 1):
        p.memory[counter] = state
        warp(p, 0x71, 7, 6, settle=400)
        for i in range(400):                 # let any entry cutscene run out
            if i % 8 < 4:
                p.button_press('b')
            else:
                p.button_release('b')
            p.tick()
        p.button_release('b')
        adv(p, 60)
        assert p.memory[MAP_ID] == 0x71, f'not in $71 (map {p.memory[MAP_ID]:02X})'
        assert p.memory[counter] == state
        vram = [[p.memory[0x9800 + r * 32 + c] for c in range(20)] for r in range(16)]
        diff = [(r, c) for r in range(16) for c in range(20)
                if vram[r][c] != grids[state][r][c]]
        assert not diff, f'state {state}: {len(diff)} VRAM tiles differ from the canvas grid, e.g. {diff[:5]}'
        if keep_dir:
            p.screen.image.save(os.path.join(keep_dir, f'pyboy_state{state}.png'))
        print(f'OK: state {state} — VRAM tilemap == canvas grid (320/320 tiles)')
    p.stop(save=False)
    if keep_dir:
        shutil.copy(rom, os.path.join(keep_dir, 'rom.gbc'))
        print(f'kept ROM + screenshots in {keep_dir}')


def main():
    do_rom = '--rom' in sys.argv
    keep = None
    if '--out' in sys.argv:
        keep = os.path.abspath(sys.argv[sys.argv.index('--out') + 1])
        os.makedirs(keep, exist_ok=True)
    test_render_parity()
    tmp = keep or tempfile.mkdtemp(prefix='dwm_canvas_')
    proj = os.path.join(tmp, 'project')
    if os.path.exists(proj):
        shutil.rmtree(proj)
    shutil.copytree(EXAMPLE, proj, ignore=shutil.ignore_patterns('build'))
    test_vanilla(proj)
    w, s, grids = gui_round_trip(proj)
    test_compile(proj)
    new_dir = os.path.join(tmp, 'fresh')
    if os.path.exists(new_dir):
        shutil.rmtree(new_dir)
    w2, s2, rid = v2_round_trip(new_dir)
    test_compile(new_dir)
    if do_rom:
        test_rom(proj, grids, keep)
        test_rom_v2(w2, s2, rid, keep)
    if not keep:
        shutil.rmtree(tmp, ignore_errors=True)
    print('PASS')


if __name__ == '__main__':
    main()
