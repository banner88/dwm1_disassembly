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

6. ALL CLONES (S96, ~12 s) — clone EVERY vanilla room, render-parity every
   screen/state against vanilla, and compile each clone.

5. V3 (S96) — fresh project: a blank-tileset room; a rip-like PNG (vanilla
   Farm art on a key-colour background, two panels at odd offsets) imported
   through the Import-art tab code path (panels + offsets detected, nudge,
   mask, WALL mark, exact palette fit, stamp pixel-identical, spill onto new
   screens); slot map == used_tiles; per-subtile palette paint; tileset
   switch with exact undo; release unused vocabulary turns a failing import
   into a succeeding one and flags the overwritten vocabulary; space meters.
   --rom: VRAM == canvas, BG palette RAM == project palette, the WALL cell
   blocks the player.

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

from editor2.core.document import val, metatile_key, metatile_pals          # noqa: E402

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
    before = {metatile_key(m) for m in rt.picker.found}
    grid4 = s.doc.layout(f'{rid}_s4')['tiles']
    attr4 = s.doc.layout(f'{rid}_s4')['attr']
    from collections import Counter
    cnt = Counter(metatile_key(metatile_at(grid4, attr4, cx, cy))
                  for cy in range(8) for cx in range(10))
    lonely = next(k for k, n in cnt.items() if n == 1)
    cell = next((cx, cy) for cy in range(8) for cx in range(10)
                if metatile_key(metatile_at(grid4, attr4, cx, cy)) == lonely)
    cv._begin_stroke(); cv._stroke_cell(cell); cv._end_stroke('Paint')
    app.processEvents()
    after = {metatile_key(m) for m in rt.picker.found}
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
    assert mine and metatile_pals(mine[-1]) == metatile_pals(foreign_mt)
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
                                         metatile_pals(foreign_mt)[i]), ((i % 2) * 8, (i // 2) * 8))
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


# ------------------------------------------------------------ S96 (v3)
V3_WALL_CELL = None          # set by v3_round_trip: a stamped cell marked WALL


def synth_rip(path):
    """A rip-like PNG built from VANILLA art (so the fit must be exact): two
    Farm screens on a (237,28,36) key background at odd offsets, plus a
    non-GBC 'caption' bar — the shape of the user's DWM2 rips (S96)."""
    from PIL import Image
    from editor2.core.render_project import ProjectRenderer
    r = ProjectRenderer(REPO, os.path.dirname(path), {})
    im = Image.new('RGB', (400, 330), (237, 28, 36))
    im.paste(r.render_vanilla_screen(0x04, 0, 1, 0), (5, 3))
    im.paste(r.render_vanilla_screen(0x04, 5, 1, 0), (200, 170))
    im.paste((237, 20, 14), (10, 300, 150, 310))
    im.save(path)
    return im


def v3_round_trip(new_dir):
    """S96: metatile per-subtile palettes, tileset slot map + release,
    tileset switching, PNG import (grid/panels/mask/wall/fit/stamp with
    spill), space meters — on a fresh project."""
    global V3_WALL_CELL
    from PIL import ImageChops
    from editor2.app.main import MainWindow
    from editor2.app.rooms import commands as C
    from editor2.core import png_import as P
    from PySide6.QtWidgets import QMessageBox
    app = QApplication.instance() or QApplication(sys.argv)
    QMessageBox.question = staticmethod(lambda *a, **k: QMessageBox.Yes)
    w = MainWindow()
    w.new_project(new_dir, 'v3 acceptance')
    app.processEvents()
    s, rt, it = w.session, w.rooms_tab, w.import_tab
    s.undo.push(C.SnapshotCommand(s, 'New room', lambda doc: doc.new_room(
        'Art room', 0x04, s.renderer, blank_tileset=True)))
    app.processEvents()
    rid = s.doc.rooms[-1]['id']
    room = s.doc.room(rid)
    tid = room['record']['tileset']
    assert s.doc.free_counts(tid, 0x40)['total'] == 128 - 2 - 1, \
        'blank tileset: every slot free but 77/78 and the floor tile'
    # --- PNG import through the tab's code path
    png = os.path.join(new_dir, 'synth_rip.png')
    src = synth_rip(png)
    it._fill_rooms()
    it.open_png(png)
    app.processEvents()
    assert [(r.x0, r.y0, r.ox, r.oy) for r in it.regions] == [(5, 3, 5, 3), (200, 170, 8, 10)], \
        [(r.x0, r.y0, r.ox, r.oy) for r in it.regions]
    assert os.path.exists(os.path.join(new_dir, 'assets', 'imports', 'synth_rip.png'))
    it.region_list.setCurrentRow(0)
    it._select_region()
    assert len(it.view.selected) == 80, 'panel 1 = one 10x8 screen of cells'
    # nudge the grid off and back (merged undo steps), mask a cell and unmask
    it._nudge(1, 0)
    assert it.regions[0].ox == 6
    it._nudge(-1, 0)
    assert it.regions[0].ox == 5
    cell = (5 + 16 * 2, 3 + 16 * 7)
    it._cells_painted('mask', [cell], True)
    assert cell not in it.view.cell_region
    it._cells_painted('mask', [cell], False)
    assert cell in it.view.cell_region
    it._select_region()
    # a stump cell becomes a WALL (every identical cell with it)
    grid0 = s.renderer.vanilla_screen_grid(0x04, 0, 0)
    stump = None
    for cy in range(8):
        for cx in range(10):
            if grid0[cy * 2 + 1][cx * 2 + 1] < s.renderer.vanilla_gfx(0x04).threshold and \
                    grid0[cy * 2][cx * 2] != grid0[0][0]:
                stump = (cx, cy)
                break
        if stump:
            break
    assert stump, 'no wall cell on Farm screen 0'
    wc = (5 + stump[0] * 16, 3 + stump[1] * 16)
    it._cells_painted('wall', [wc], True)
    assert wc in it.view.walls
    V3_WALL_CELL = stump
    it.refit()
    assert it.fit.exact == it.fit.total == 320, \
        f'vanilla art must fit the DWM1 palette rules exactly ({it.fit.exact}/{it.fit.total})'
    it.dst_x.setValue(0)
    it.dst_y.setValue(0)
    it._import(stamp=True)
    app.processEvents()
    room = s.doc.room(rid)
    img = s.renderer.render_screen(room, 0, 0, 1)
    assert ImageChops.difference(img, src.crop((5, 3, 165, 131))).getbbox() is None, \
        'stamped screen must render pixel-identical to the PNG panel'
    lid = room['screens']['0']['layout']['id']
    br = s.doc.layout(lid)['tiles'][stump[1] * 2 + 1][stump[0] * 2 + 1]
    assert br < 0x40, 'WALL cell: bottom-right subtile below the threshold'
    print('OK: PNG import — 2 panels detected with their own grid offsets, key colour '
          'masked, 80 cells fitted exactly, stamped pixel-identical, wall cell below '
          'the threshold')
    # spill: the second panel stamped from screen 0 cell (5,4) -> screens 0,1,4,5
    it.region_list.setCurrentRow(1)
    it._select_region()
    it.refit()
    for sl in range(4):                   # keep the palettes the first import set
        it.pal_rows[sl][1].setChecked(True)
    it.refit()
    it.dst_x.setValue(5)
    it.dst_y.setValue(4)
    it._import(stamp=True)
    app.processEvents()
    room = s.doc.room(rid)
    assert s.doc.screen_keys(room) == [0, 1, 4, 5], s.doc.screen_keys(room)
    assert room['record']['width_px'] == 320 and room['record']['height_px'] == 256
    print('OK: spill — a selection past the screen edge created screens 1, 4, 5 '
          '(record 2x2) with the palettes kept')
    # --- slot map == Document.used_tiles
    rt._fill_rooms(keep=rid)
    app.processEvents()
    used = s.doc.used_tiles(tid)
    fc = s.doc.free_counts(tid, 0x40)
    assert fc['total'] == 128 - len(used)
    assert sum(1 for u in rt.tileset_map.usage if u['status'] == 'free') == fc['total']
    assert rt.picker_tabs.tabText(2) == f"Tileset ({fc['total']} free)"
    print(f"OK: slot map — {fc['wall']} wall / {fc['walkable']} walkable free == "
          'Document.used_tiles')
    # --- per-subtile palettes: paint a mixed metatile, read it back, undo
    cv = rt.canvas
    rt.select_screen(0)
    app.processEvents()
    before = [row[:] for row in s.doc.layout(cv.attr_lid)['attr']]
    mixed = {'tiles': cv.cell_metatile(0, 0)['tiles'], 'pal': [0, 1, 2, 3]}
    cv.set_brush(mixed)
    cv._begin_stroke(); cv._stroke_cell((9, 7)); cv._end_stroke('Paint')
    a = s.doc.layout(cv.attr_lid)['attr']
    assert [a[14][18], a[14][19], a[15][18], a[15][19]] == [0, 1, 2, 3]
    assert cv.cell_metatile(9, 7)['pal'] == [0, 1, 2, 3]
    s.undo.undo()
    assert s.doc.layout(cv.attr_lid)['attr'] == before
    print('OK: a metatile with four palettes paints per subtile (and undoes)')
    # --- tileset switch (vanilla Library sheet) + exact undo
    snap = s.doc.dumps()
    rt._change_tileset_to = None
    s.undo.push(C.SnapshotCommand(s, 'Change tileset', lambda doc: doc.set_room_tileset(
        rid, 'vanilla', 0x12)))
    rec = s.doc.room(rid)['record']
    lib = s.renderer.vanilla_record(0x12)
    assert 'tileset' not in rec and rec['gfx_bank'] == lib['gfx_bank'] and \
        rec['collision_threshold'] == lib['collision_threshold']
    s.undo.undo()
    assert s.doc.dumps() == snap, 'tileset switch undo must be exact'
    print('OK: tileset switched to the Library sheet and back (exact undo)')
    # --- release unused vocabulary: a GreatTree-sheet room has ~8 free slots
    s.undo.push(C.SnapshotCommand(s, 'New room', lambda doc: doc.new_room(
        'GT room', 0x01, s.renderer)))
    rid2 = s.doc.rooms[-1]['id']
    key2 = s.doc.tileset_key(s.doc.room(rid2))
    free_before = s.doc.free_counts(key2, s.renderer.vanilla_gfx(0x01).threshold)['total']
    img_ = P.load_rgb(png)
    keys_ = P.guess_key_colours(img_)
    reg_ = P.detect_regions(img_, keys_)[0]
    cells_ = P.valid_cells(img_, reg_, keys_)
    subs_ = [x for (cx, cy) in cells_ for x in P.cell_subtiles(img_, cx, cy)]
    fit_ = P.fit_palettes(subs_)
    plans_ = P.plan_cells(img_, cells_, fit_)
    # S96 round 3 (user: "let me do the walkability"): unmarked cells bind no
    # threshold side unless strict_walk — never more slots than strict
    d_free, d_strict = P.slot_demand(plans_), P.slot_demand(plans_, strict_walk=True)
    assert d_free['walkable_br'] == 0 and d_free['total'] <= d_strict['total']
    own = bytes(s.renderer.vanilla_gfx(0x01).sheet[:2048])
    cmd = C.SnapshotCommand(s, 'Import', lambda doc: doc.import_png_cells(
        rid2, plans_, fit_.palettes, [0, 1, 2], 0, 0, own_sheet=own))
    s.undo.push(cmd)
    assert cmd.error is not None and 'not enough free tileset slots' in str(cmd.error), cmd.error
    s.undo.push(C.SnapshotCommand(s, 'Release', lambda doc: doc.set_released(key2, True)))
    free_rel = s.doc.free_counts(key2, s.renderer.vanilla_gfx(0x01).threshold)['total']
    assert free_rel > free_before + 50, (free_before, free_rel)
    s.undo.undo()
    assert s.doc.free_counts(key2, s.renderer.vanilla_gfx(0x01).threshold)['total'] == free_before, \
        're-protecting restores the count'
    s.undo.redo()
    cmd = C.SnapshotCommand(s, 'Import', lambda doc: doc.import_png_cells(
        rid2, plans_, fit_.palettes, [0, 1, 2], 0, 0, own_sheet=own))
    s.undo.push(cmd)
    assert cmd.error is None, cmd.error
    rt._fill_rooms(keep=rid2)
    app.processEvents()
    flags = rt.picker.flags
    assert any(v == 'changed' for v in flags.values()), 'overwritten vocabulary must be flagged'
    print(f'OK: release — import failed with {free_before} free, succeeded after releasing '
          f'({free_rel} free); re-protect restores {free_before}; overwritten vocabulary '
          f'flagged in "This room" ({sum(1 for v in flags.values() if v == "changed")} tiles)')
    # --- space meters measured the unsaved project
    w.space_meter.measure()
    assert w.space_meter.last.get(0x67, (0, 0))[0] > 0 and w.space_meter.last.get(0x64, (0, 0))[0] > 0
    print('OK: space meters — ' + ', '.join(f'${b:02X} {u}/{c}' for b, (u, c)
                                               in sorted(w.space_meter.last.items())))
    # drop the GreatTree test room (keeps the --rom build to the art room)
    s.undo.push(C.SnapshotCommand(s, 'Delete', lambda doc: doc.delete_room(rid2)))
    assert w.save()
    return w, s, rid


def test_rom_v3(w, s, rid, keep_dir=None):
    from editor2.app.build_worker import BuildWorker
    app = QApplication.instance()
    results = []
    worker = BuildWorker(REPO, s.project_dir)
    worker.finished_build.connect(results.append)
    worker.start()
    worker.wait()
    app.processEvents()
    res = results[0]
    assert res.ok, f'build failed: {res.error}'
    from tools.pyboy_harness import boot, to_bedroom, warp, adv, MAP_ID, give_party_monster
    room = s.doc.room(rid)
    p = boot(res.rom_path)
    assert to_bedroom(p), 'scripted intro failed'
    p.memory[0xCA39] = p.memory[0xCA3A] = 0xFF
    cx, cy = V3_WALL_CELL
    # stand on the cell above the wall (or below when it is on row 0)
    sy = cy - 1 if cy > 0 else cy + 1
    warp(p, 0x6B, cx, sy, settle=500)
    adv(p, 120)
    assert p.memory[MAP_ID] == 0x6B and p.memory[0xC925] == 0
    grid = s.doc.layout(room['screens']['0']['layout']['id'])['tiles']
    vram = [[p.memory[0x9800 + r * 32 + c] for c in range(20)] for r in range(16)]
    diff = sum(1 for r in range(16) for c in range(20) if vram[r][c] != grid[r][c])
    assert diff == 0, f'{diff} VRAM tiles differ from the imported screen'
    pals = []
    for i in range(32):
        p.memory[0xFF68] = i
        pals.append(p.memory[0xFF69])
    # bit 15 of colour 3 = the per-slot free-colour marker (hardware ignores it)
    words = [(pals[i] | (pals[i + 1] << 8)) & 0x7FFF for i in range(0, 32, 2)]
    pid = room['render'].get('palette') or s.doc.effective_palette(room, 0, 0)
    pal = s.doc.palette(pid)
    assert pal.get('free_color1'), 'the import tab marks the palette "own colour 1" by default'
    want = [int(x, 16) for row in pal['colors_rgb555'][:4] for x in row]
    want = [0 if i % 4 == 3 else v for i, v in enumerate(want)]
    assert words == want, f'BG palette RAM {words} != project {want}'
    sys_c1 = []
    for i in range(32, 64, 8):
        p.memory[0xFF68] = i + 2
        lo = p.memory[0xFF69]
        p.memory[0xFF68] = i + 3
        sys_c1.append(lo | (p.memory[0xFF69] << 8))
    assert sys_c1[:3] == [0x6BFF] * 3, f'slots 4-6 colour 1 must stay forced: {sys_c1}'
    print('OK: imported screen — VRAM tilemap == canvas (320/320), BG palette RAM == project '
          'palette incl. its OWN colour 1 (FreeColor1Hook); system slots 4-6 still $6BFF')

    # S96 round 4 (user, SameBoy: "opening menu then going back … everything
    # becomes blinding white … coloured background squares as it opens"):
    # the field menu re-runs LoadPal_4102 (marker must survive) and blanks
    # the BG under the room's attrs (colour 1 must read cream meanwhile).
    def bg_words(n=32):
        out = []
        for i in range(0, n, 2):
            p.memory[0xFF68] = i
            lo = p.memory[0xFF69]
            p.memory[0xFF68] = i + 1
            out.append((lo | (p.memory[0xFF69] << 8)) & 0x7FFF)
        return out
    give_party_monster(p)
    seen_c1 = set()
    for i in range(120):                          # A on nothing = open the menu
        (p.button_press if i < 4 else p.button_release)('a')
        p.tick()
        if 4 <= i <= 12:                          # the tile-$E0 blanking frames
            w = bg_words()
            seen_c1 |= {w[k * 4 + 1] for k in range(4)}
    assert p.memory[0xC8EB] & 0x02, 'the field menu did not open'
    assert seen_c1 == {0x6BFF}, f'colour 1 during the menu wipe must be cream: {seen_c1}'
    for i in range(150):
        (p.button_press if i < 4 else p.button_release)('b')
        p.tick()
    assert not p.memory[0xC8EB] & 0x02, 'the field menu did not close'
    assert bg_words() == want, f'after the menu: BG palette RAM {bg_words()} != project {want}'
    print('OK: field menu open/close — cream wipe (no colour-1 squares), own colours back after close')
    home = (p.memory[0xFF97], p.memory[0xFF98])
    d = 'down' if sy < cy else 'up'
    for _ in range(48):
        p.button_press(d)
        p.tick()
    p.button_release(d)
    adv(p, 24)
    assert (p.memory[0xFF97], p.memory[0xFF98]) == home, 'the WALL cell must block the player'
    print(f'OK: the cell marked WALL in the import tab blocks the player in-game')
    if keep_dir:
        p.screen.image.save(os.path.join(keep_dir, 'pyboy_import.png'))
        shutil.copy(res.rom_path, os.path.join(keep_dir, 'rom_v3.gbc'))
    p.stop(save=False)


# ---------------------------------------------------------------- S97 (v4)
V4_WALKER = (2, 7)       # servant clone screen 0, cleared state: open floor
V4_TALKER = (5, 5)
V4_STAND = (5, 6)        # the player's cell below the talker (faces up to talk)
V4_BOXES = [['The servant is', 'gone.'], ['Thank you, hero!']]   # S97 r2: per-box text


def v4_round_trip(new_dir):
    """S97 (ROADMAP P3.5 + P3.5a) — fresh project: clone the Servant room
    ($3F: burning / cleared, own layout + palette per state) to $6B; a flag
    rule 'servant_beaten set -> state 1' authored through the rules path
    (named flag created with it); NPCs added through the NPC-panel path
    (sprite picker, behaviour, facing, new talk text, presence in the other
    state, drag-move); a CLONED raw NPC edited (typed entry, same bytes but
    the changed field); exact full undo/redo; compile."""
    from editor2.app.main import MainWindow
    from editor2.app.rooms import npc_panel
    from PySide6.QtWidgets import QMessageBox, QDialog
    from editor2.core import formats as F
    app = QApplication.instance() or QApplication(sys.argv)
    QMessageBox.question = staticmethod(lambda *a, **k: QMessageBox.Yes)
    w = MainWindow()
    w.new_project(new_dir, 'v4 acceptance')
    app.processEvents()
    rt, s = w.rooms_tab, w.session
    for i in range(rt.vanilla_list.count()):
        if rt.vanilla_list.item(i).data(0x100) == 0x3F:
            rt.vanilla_list.setCurrentRow(i)
    app.processEvents()
    rt._clone_vanilla()
    app.processEvents()
    rid = rt.room_id
    room = s.doc.room(rid)
    assert len(s.doc.states(room, 0)) == 2, 'servant clone carries both vanilla states'
    s.doc.save()
    saved = open(s.doc.path).read()
    n0 = s.undo.count()
    # ---- state rule (P3.5a) with a NEW named flag, through the rules group
    rule = {'state': 1, 'when': [{'flag': 'servant_beaten'}]}
    rt._rules_edited([rule], ['servant_beaten'])
    app.processEvents()
    room = s.doc.room(rid)
    assert s.doc.state_rules(room) == [rule] and s.doc.flags()[0]['name'] == 'servant_beaten'
    # 'Otherwise: state 0' through the group's combo (a trailing always-rule)
    rg = rt.inspector.rules
    rg.otherwise.setCurrentIndex(rg.otherwise.findData(0))
    app.processEvents()
    room = s.doc.room(rid)
    assert s.doc.state_rules(room) == [rule, {'state': 0, 'when': []}], s.doc.state_rules(room)
    assert s.doc.rules_for_state(room, 0, 1) == [(0, rule)]
    assert [ru for _i, ru in s.doc.rules_for_state(room, 0, 0)] == [{'state': 0, 'when': []}]
    rt.select_state(1)
    app.processEvents()
    assert 'servant_beaten' in rt.shown_when.text(), rt.shown_when.text()
    assert not rt.shown_when.isHidden()
    # ---- NPCs (P3.5) through the panel code path (dialogs answered)
    picks = iter([0x0B, 0x00])

    def fake_pick(dlg):
        dlg.value = next(picks)
        return QDialog.Accepted
    npc_panel.SpritePicker.exec = fake_pick
    npc_panel.TalkDialog.exec = lambda dlg: QDialog.Accepted
    npc_panel.TalkDialog.boxes = lambda dlg: V4_BOXES
    rt._add_npc((4, 7))                                    # walker, placed then moved
    app.processEvents()
    wi = rt._sel_npc
    assert wi is not None and not rt.npc_panel.isHidden() and rt.sec_npc.is_expanded()
    rt._move_marker(('npc', wi, None), *V4_WALKER)        # drag-move
    rt._npc_fields({'behaviour': F.BEHAVIOURS['pace_x1']})
    rt._npc_fields({'facing': 'right'})
    rt._add_npc(V4_TALKER)                                 # talker
    ti = rt._sel_npc
    rt._npc_fields({'behaviour': F.BEHAVIOURS['stand_return'], 'facing': 'left'})
    rt._npc_new_talk()
    app.processEvents()
    room = s.doc.room(rid)
    tv = s.doc.npc_view(room, s.doc.npc_entries(room, 0, 1)[ti])
    wv = s.doc.npc_view(room, s.doc.npc_entries(room, 0, 1)[wi])
    assert (wv['x'], wv['y'], wv['behaviour'], wv['facing'], wv['sprite']) == \
        (*V4_WALKER, 8, 'right', 0x0B), wv
    assert tv['behaviour'] == 7 and tv['facing'] == 'left' and tv['sprite'] == 0
    assert s.doc.talk_boxes(tv['script']) == V4_BOXES, tv
    assert room['scripts'].get('0'), 'a room-entry script 0 was created with the talk script'
    # presence: the talker in the burning state too
    rt._npc_presence(0, True)
    room = s.doc.room(rid)
    assert s.doc.npc_presence(room, 0, 1, ti) == [True, True]
    # a CLONED raw NPC (state 0: `00 2B 01 05 01`) edited -> typed, same bytes + facing up
    rt.select_state(0)
    app.processEvents()
    room = s.doc.room(rid)
    ri = next(i for i, e in enumerate(s.doc.npc_entries(room, 0, 0))
              if e.get('kind') == 'raw' and [val(b) for b in e['bytes']] == [0x00, 0x2B, 1, 5, 1])
    rt._sel_npc = ri
    rt._npc_fields({'facing': 'up'})
    room = s.doc.room(rid)
    e = s.doc.npc_entries(room, 0, 0)[ri]
    assert e['kind'] == 'npc'
    from editor2.core.project import Project
    from editor2.core import compiler
    # exact undo / redo
    n = s.undo.count() - n0
    for _ in range(n):
        s.undo.undo()
    app.processEvents()
    assert s.doc.dumps() == saved, 'full undo must restore the project byte-for-byte'
    for _ in range(n):
        s.undo.redo()
    app.processEvents()
    s.doc.save()
    # the typed entry of the edited clone NPC emits the vanilla bytes + facing
    prj = Project.load(new_dir)
    room_p = next(r for r in prj.rooms if r.get('id') == rid)
    e = prj.screen_states(prj.room_screens(room_p)[0])[0]['npcs'][ri]
    sidx = prj.script_index(room_p, e['script'])
    b = F.npc_entry(e['facing'], F.val(e['sprite']), e['x'], e['y'], sidx,
                    behaviour=e.get('behaviour', 0), hidden=e.get('hidden', False))
    assert b == [0x20, 0x2B, 1, 5, 1], b
    print(f'OK: v4 — servant clone at {room_p["mapID"]}: state rule servant_beaten -> 1 (new named '
          f'flag), walker ${0x0B:02X} pace_x1 dragged to {V4_WALKER}, talker stand_return with a '
          f'new talk script, presence in both states, cloned NPC edited to typed bytes '
          f'{" ".join("%02X" % x for x in b)}; {n} undoable edits, exact undo/redo')
    return w, s, rid, ti, wi


def test_rom_v4(w, s, rid, ti, wi, keep_dir=None):
    """--rom: the rule selects the state at LOAD — layout (VRAM), palette
    (BG palette RAM, loaded BEFORE bank $0B Entry 0 — the hook placement)
    and NPC set all follow the flag, and survive a wiped counter (= reload);
    the walker paces as measured; talking to the talker shows the authored
    text."""
    from editor2.app.build_worker import BuildWorker
    from editor2.core import formats as F
    app = QApplication.instance()
    results = []
    worker = BuildWorker(REPO, s.project_dir)
    worker.finished_build.connect(results.append)
    worker.start()
    worker.wait()
    app.processEvents()
    res = results[0]
    assert res.ok, f'build failed: {res.error}'
    man = json.load(open(os.path.join(os.path.dirname(res.rom_path), 'manifest.json')))
    flag = int(man['flags']['servant_beaten'].lstrip('$'), 16)
    ctr = int(next(v for k, v in man['step_counters'].items() if k.endswith('_S0'))
              .lstrip('$'), 16)
    from tools.pyboy_harness import boot, to_bedroom, warp, adv, MAP_ID, set_flag
    room = s.doc.room(rid)
    p = boot(res.rom_path)
    assert to_bedroom(p), 'scripted intro failed'
    p.memory[0xCA39] = p.memory[0xCA3A] = 0xFF
    import tempfile as _t
    base = os.path.join(_t.mkdtemp(prefix='v4_'), 'bed.state')
    with open(base, 'wb') as f:
        p.save_state(f)

    def bg_words():
        out = []
        for i in range(0, 32, 2):
            p.memory[0xFF68] = i
            lo = p.memory[0xFF69]
            p.memory[0xFF68] = i + 1
            out.append((lo | (p.memory[0xFF69] << 8)) & 0x7FFF)
        return out

    def expect(state):
        grid = s.renderer.layout_grid(s.renderer.screen_state(room, 0, state)['layout'])[0]
        vram = [[p.memory[0x9800 + r * 32 + c] for c in range(20)] for r in range(16)]
        d = sum(1 for r in range(16) for c in range(20) if vram[r][c] != grid[r][c])
        assert d == 0, f'state {state}: {d} VRAM tiles differ'
        pid = s.doc.effective_palette(room, 0, state)
        want = [val(x) for row in s.doc.palette(pid)['colors_rgb555'][:4] for x in row]
        want = [0x6BFF if i % 4 == 1 else 0 if i % 4 == 3 else v for i, v in enumerate(want)]
        assert bg_words() == want, f'state {state}: BG palette RAM != {pid}'
        npcs = []
        for i in range(8):
            b = 0xD7D2 + 32 * i
            if p.memory[b] == 0xFF:
                break
            npcs.append((p.memory[b], p.memory[b + 1]))
        return npcs
    # flag clear -> state 0 (burning)
    warp(p, 0x6B, *V4_STAND, settle=500)
    adv(p, 60)
    assert p.memory[MAP_ID] == 0x6B and p.memory[ctr] == 0
    n0 = expect(0)
    assert (0x20, 0x2B) in n0, f'edited clone NPC (facing up) in state 0: {n0}'
    # flag set -> state 1 (cleared), incl. its palette (hook before the palette load)
    p.load_state(open(base, 'rb'))
    set_flag(p, flag)
    warp(p, 0x6B, *V4_STAND, settle=500)
    adv(p, 60)
    assert p.memory[ctr] == 1, f'rule did not select state 1 (counter {p.memory[ctr]})'
    n1 = expect(1)
    assert (F.npc_type_byte('right', 8), 0x0B) in n1 and (F.npc_type_byte('left', 7), 0x00) in n1, n1
    print(f'OK: state rule — flag {flag:#06x} clear: state 0 (VRAM + palette + NPCs), set: state 1 '
          'incl. its own palette (rule runs before the palette load)')
    # reload = counter wiped (the $CD80 window is zeroed at save-restore)
    p.memory[ctr] = 0
    warp(p, 0x6B, *V4_STAND, settle=500)
    adv(p, 30)
    assert p.memory[ctr] == 1, 'the rule must re-select state 1 after the counter is wiped'
    expect(1)
    print('OK: counter wiped (reload) -> the flag rule restores state 1 on the next load')
    # flag cleared again -> 'otherwise: state 0' takes the room back
    p.memory[0xD99B + (flag >> 3)] &= ~(1 << (7 - (flag & 7))) & 0xFF
    warp(p, 0x6B, *V4_STAND, settle=500)
    adv(p, 30)
    assert p.memory[ctr] == 0, 'otherwise-rule must return the room to state 0'
    expect(0)
    p.load_state(open(base, 'rb'))
    set_flag(p, flag)
    warp(p, 0x6B, *V4_STAND, settle=500)
    adv(p, 60)
    print('OK: flag cleared -> "otherwise: state 0" puts the room back to state 0')
    # the walker paces +-1 (measured behaviour 8)
    slot = next(i for i in range(8) if p.memory[0xD7D2 + 32 * i + 1] == 0x0B)
    b = 0xD7D2 + 32 * slot
    xs = set()
    for _ in range(300):
        p.tick()
        xs.add(((p.memory[b + 0x18] | p.memory[b + 0x19] << 8) - 8) // 16)
    assert xs == {V4_WALKER[0] - 1, V4_WALKER[0], V4_WALKER[0] + 1}, f'walker tiles {xs}'
    print(f'OK: walker (pace_x1) visits tiles {sorted(xs)} on row {V4_WALKER[1]}')
    # talk: face up at the talker and press A
    for _ in range(6):
        p.button_press('up')
        p.tick()
    p.button_release('up')
    adv(p, 20)
    sid = s.doc.npc_view(room, s.doc.npc_entries(room, 0, 1)[ti])['script']
    did = s.doc.script(sid)['ops'][0][1]
    tid = next(int(k.lstrip('$'), 16) for k, v in man['texts'].items() if v['id'] == did)
    seen = set()
    for i in range(200):
        (p.button_press if i < 4 else p.button_release)('a')
        p.tick()
        # $D8D9/$D8DA = the script's queued text id (LE; BANK04 "Key RAM")
        if p.memory[0xC8EB] & 1:
            seen.add(p.memory[0xD8D9] | p.memory[0xD8DA] << 8)
    assert tid in seen, f'talk text {tid:#06x} never displayed (saw {sorted(hex(x) for x in seen)[:8]})'
    # S97 r2: box 1 WAITS for A ($FA) — still open 196 frames after the talk press
    assert p.memory[0xC8EB] & 1, 'the first box must wait for A (boxes form, $FA $F7 $EF $EE)'
    sl = next(i for i in range(8) if p.memory[0xD7D2 + 32 * i + 1] == 0x00
              and p.memory[0xD7D2 + 32 * i] & 0x0F == 7)
    assert p.memory[0xD7D2 + 32 * sl + 6] == 0, 'stand_return NPC faces the player (down) while talking'
    if keep_dir:
        p.screen.image.save(os.path.join(keep_dir, 'pyboy_v4_talk.png'))
    print(f'OK: talking to the talker displays its text {tid:#06x} and it turns to face the player')
    if keep_dir:
        shutil.copy(res.rom_path, os.path.join(keep_dir, 'rom_v4.gbc'))
    p.stop(save=False)


# ------------------------------------------------------------ S98 (v5)
V5_NPC = (3, 3)          # the question NPC in room A
V5_NPC_STAND = (3, 4)    # the player's cell below it (faces up to talk)
V5_BOOK = (1, 1)         # examine spot (facing up), approached from (1, 2)
V5_STEP = (6, 5)         # step-on trigger, approached from (6, 4)
V5_TELE = (8, 6)         # one-way teleport in room B -> room A (5, 5)
V5_B_DOOR = (3, 3)       # room B's end of door A(7,2)<->B, after the drag
V5_SPECS = [
    {'boxes': [['A dusty book.'], ['Nothing inside.']], 'question': False,
     'then': {'boxes': [], 'set': ['book_read'], 'clear': [], 'move': None},
     'yes': {'boxes': [], 'set': [], 'clear': [], 'move': None},
     'no': {'boxes': [], 'set': [], 'clear': [], 'move': None}},
    {'boxes': [['Squish.']], 'question': False,
     'then': {'boxes': [], 'set': ['stepped'], 'clear': [], 'move': None},
     'yes': {'boxes': [], 'set': [], 'clear': [], 'move': None},
     'no': {'boxes': [], 'set': [], 'clear': [], 'move': None}},
]


def v5_round_trip(new_dir):
    """S98 (ROADMAP P3.7) — fresh project, everything through the Rooms-tab
    code path with the dialogs answered: room A (2 states, rule 'state 1 when
    lab_flag set') and room B; door A(4,7) <-> the vanilla GreatTree 2F
    Library door; door A(7,2) <-> B, B's end dragged; an examine spot (facing
    up) that sets a flag; a step-on trigger; an NPC whose YES sets lab_flag
    and moves the player (room reload -> the rule picks state 1); a one-way
    teleport B -> A; exact undo/redo; world graph; compile."""
    from editor2.app.main import MainWindow
    from editor2.app.rooms import npc_panel, door_dialog
    from editor2.app.rooms import commands as C
    from PySide6.QtWidgets import QMessageBox, QDialog, QDialogButtonBox
    from editor2.core import world as Wd
    app = QApplication.instance() or QApplication(sys.argv)
    QMessageBox.question = staticmethod(lambda *a, **k: QMessageBox.Yes)
    w = MainWindow()
    w.new_project(new_dir, 'v5 acceptance')
    app.processEvents()
    rt, s = w.rooms_tab, w.session
    rend = s.renderer
    s.undo.push(C.SnapshotCommand(s, 'New room A', lambda doc: doc.new_room('Door Lab', 0x04, rend)))
    s.undo.push(C.SnapshotCommand(s, 'New room B', lambda doc: doc.new_room('Room B', 0x04, rend)))
    app.processEvents()
    a_id, b_id = [r['id'] for r in s.doc.rooms]
    A = s.doc.room(a_id)
    assert not A['screens']['0']['npcs'], 'S98: a new room carries no "spawn" marker'
    s.doc.save()
    saved = open(s.doc.path).read()
    n0 = s.undo.count()

    def open_room(rid, state=0):
        for i in range(rt.room_list.count()):
            if rt.room_list.item(i).data(0x100) == rid:
                rt.room_list.setCurrentRow(i)
        app.processEvents()
        rt.select_state(state)
        app.processEvents()
    open_room(a_id)
    # ---- a 2nd state with its own layout (a visible stripe) + the rule
    rt._add_state(True, True)
    app.processEvents()
    A = s.doc.room(a_id)
    lid1 = s.doc.states(A, 0)[1]['layout']['id']
    stripe = [(r, c, 0x10) for r in (12, 13) for c in range(20)]
    from editor2.app.rooms.commands import PaintCells
    s.undo.push(PaintCells(s, lid1, 'tiles', stripe, 'stripe'))
    rt._rules_edited([{'state': 1, 'when': [{'flag': 'lab_flag'}]}], ['lab_flag'])
    open_room(a_id, 0)
    # ---- doors, the S98 r2 way (user design): select a cell, press + Door —
    # the door appears unconnected; double-click it, name it, pick the door
    # it connects to from the list. No coordinates anywhere.
    from PySide6.QtTest import QTest
    from PySide6.QtCore import QPointF, QPoint, Qt
    from editor2.app.rooms import canvas as CV

    def vp(cell):
        p = rt.canvas.mapFromScene(QPointF(cell[0] * CV.CELL + CV.CELL / 2,
                                           cell[1] * CV.CELL + CV.CELL / 2))
        return QPoint(p.x(), p.y())

    def click(cell):
        QTest.mouseClick(rt.canvas.viewport(), Qt.LeftButton, Qt.NoModifier, vp(cell))
        app.processEvents()

    link_plan = []          # (new name, target door id) per dialog opened

    def fake_props(dlg):
        name, target = link_plan.pop(0)
        dlg.name.setText(name)
        found = []

        def walk(it):
            d = it.data(0, Qt.UserRole)
            if d and d[0] == 'door' and d[1] == target:
                found.append(it)
            for k in range(it.childCount()):
                walk(it.child(k))
        for k in range(dlg.tree.topLevelItemCount()):
            walk(dlg.tree.topLevelItem(k))
        assert found, f'{target} is not in the connection list'
        dlg.tree.setCurrentItem(found[0])
        assert dlg.bb.button(QDialogButtonBox.Ok).isEnabled(), dlg.warn.text()
        return QDialog.Accepted
    door_dialog.DoorPropsDialog.exec = fake_props
    assert not any('rect' in a.text().lower() for a in rt.tools.actions()), 'Rect is off the bar'
    click((4, 7))                                   # Select tool: pick the cell
    rt.act_add_door.trigger()                       # + Door
    app.processEvents()
    A = s.doc.room(a_id)
    d1 = s.doc.door_end_at(a_id, 0, 4, 7)
    assert d1 and s.doc.door_partner(d1) is None, 'the new door sits on the cell, unconnected'
    assert 'dest' not in s.doc.door_end(d1)['row']
    assert s.doc.door_end(d1)['states'] == [0, 1], 'the door exists in both states'
    # double-click it -> name it + connect it to the GreatTree 2F Library door
    vid = s.doc.vanilla_door_id(0x01, 8, 5, 3)
    link_plan.append(('Library door', vid))
    QTest.mouseDClick(rt.canvas.viewport(), Qt.LeftButton, Qt.NoModifier, vp((4, 7)))
    app.processEvents()
    cus, van = s.doc.door_end(d1), s.doc.door_end(vid)
    assert cus['name'] == 'Library door' and cus['link'] == vid and van['link'] == d1
    # S98 r3 (user: "You arrive on tile fully always"): ON the vanilla door
    # (vanilla's own $88 would be half a cell below it)
    assert (cus['row']['screen_byte'], cus['row']['spawn_x'], cus['row']['spawn_y']) == \
        ('0x08', 5, 3), cus['row']
    # the custom door is on the bottom edge: arrive ON the door cell
    assert (van['row']['screen_byte'], van['row']['spawn_x'], van['row']['spawn_y']) == \
        ('0x00', 4, 7), van['row']
    # second door in A at (7,2), one in B at (0,2); connect them from B's side
    click((7, 2))
    rt.act_add_door.trigger()
    d2 = s.doc.door_end_at(a_id, 0, 7, 2)
    open_room(b_id)
    rt.canvas.selected_cell = (0, 2)
    rt._add_door_selected()
    d3 = s.doc.door_end_at(b_id, 0, 0, 2)
    assert d2 and d3 and d2 != d3
    link_plan.append(('Back to the lab', d2))
    QTest.mouseDClick(rt.canvas.viewport(), Qt.LeftButton, Qt.NoModifier, vp((0, 2)))
    app.processEvents()
    assert s.doc.door_partner(d3)['id'] == d2 and s.doc.door_partner(d2)['id'] == d3
    # drag B's door to its final cell: A's door re-aims at the new arrival
    B = s.doc.room(b_id)
    bi = next(i for i, e in enumerate(s.doc.exits_of(B, 0, 0)) if e.get('door') == d3)
    rt._move_marker(('exit', bi, s.doc.exits_of(B, 0, 0)[bi]), *V5_B_DOOR)
    endA, endB = s.doc.door_end(d2), s.doc.door_end(d3)
    assert (endB['x'], endB['y']) == V5_B_DOOR
    # S98 r2 (user): arrival = ON the partner door (arrival never re-fires it)
    assert (endA['row']['screen_byte'], endA['row']['spawn_x'], endA['row']['spawn_y']) == \
        ('0x00', *V5_B_DOOR), endA['row']
    assert (endB['row']['screen_byte'], endB['row']['spawn_x'], endB['row']['spawn_y']) == \
        ('0x00', 7, 2), endB['row']
    # re-linking frees the old partner: connect d2 to d1 would free d3 and the
    # vanilla door — check on a copy via undo
    n_before = s.undo.count()
    s.undo.push(C.SnapshotCommand(s, 'relink', lambda doc: doc.link_doors(d2, d1)))
    assert s.doc.door_partner(d3) is None and s.doc.door_end(vid)['row'] is None
    s.undo.undo()
    assert s.undo.index() == n_before and s.doc.door_partner(d3)['id'] == d2
    # deleting a door leaves its partner, unconnected (then undo)
    s.undo.push(C.SnapshotCommand(s, 'del', lambda doc: doc.remove_door(d3)))
    assert s.doc.door_end(d3) is None and s.doc.door_partner(d2) is None \
        and s.doc.door_end(d2) is not None
    s.undo.undo()
    assert s.doc.door_partner(d2)['id'] == d3
    # ---- one-way teleport B (8,6) -> A (5,5)
    tele = iter([(('room', a_id), 0, 5, 5)])

    def fake_tele(dlg):
        data, k, x, y = next(tele)
        for i in range(dlg.dst_room.count()):
            if dlg.dst_room.itemData(i) == data:
                dlg.dst_room.setCurrentIndex(i)
        dlg.dst_screen.setCurrentIndex(dlg.dst_screen.findData(k))
        dlg.dst_x.setValue(x)
        dlg.dst_y.setValue(y)
        dlg._refresh()
        return QDialog.Accepted
    door_dialog.DoorDialog.exec = fake_tele
    rt._add_exit(V5_TELE)
    B = s.doc.room(b_id)
    tr = [e for e in s.doc.exits_of(B, 0, 0) if not e.get('door')]
    assert len(tr) == 1 and (tr[0]['x'], tr[0]['y'], tr[0]['spawn_x'], tr[0]['spawn_y']) == \
        (*V5_TELE, 5, 5), tr
    # ---- examine spot + step trigger + the question NPC in room A
    open_room(a_id, 0)
    specs = iter(V5_SPECS + [{
        'boxes': [['Want me to', 'turn the flag on?']], 'question': True,
        'then': {'boxes': [], 'set': [], 'clear': [], 'move': None},
        'yes': {'boxes': [['Done!']], 'set': ['lab_flag'], 'clear': [],
                'move': {'dest': f"room:${val(A['mapID']):02X}", 'screen': 0,
                         'x': V5_NPC_STAND[0], 'y': V5_NPC_STAND[1]}},
        'no': {'boxes': [['Maybe later.']], 'set': [], 'clear': [], 'move': None}}])
    npc_panel.TalkDialog.exec = lambda dlg: QDialog.Accepted
    npc_panel.TalkDialog.spec = lambda dlg: next(specs)
    npc_panel.TalkDialog.new_flags = lambda dlg: ['book_read', 'stepped']
    rt.canvas.selected_cell = V5_BOOK             # S98 r2: the + Examine (X) button
    rt.act_add_examine.trigger()
    app.processEvents()
    rt._spot_fields({'facing': 'up'})
    rt._add_spot(V5_STEP, 'step')
    npc_panel.SpritePicker.exec = lambda dlg: (setattr(dlg, 'value', 0x0B), QDialog.Accepted)[1]
    rt._add_npc(V5_NPC)
    rt._npc_new_talk()
    app.processEvents()
    A = s.doc.room(a_id)
    views = [s.doc.npc_view(A, e) for e in s.doc.npc_entries(A, 0, 0)]
    kinds = sorted(v['kind'] for v in views)
    assert kinds == ['examine', 'npc', 'step'], kinds
    book = next(v for v in views if v['kind'] == 'examine')
    assert book['facing'] == 'up' and (book['x'], book['y']) == V5_BOOK
    npcv = next(v for v in views if v['kind'] == 'npc')
    spec = s.doc.talk_spec(npcv['script'])
    assert spec['question'] and spec['yes']['set'] == ['lab_flag'] and spec['yes']['move'], spec
    assert {f['name'] for f in s.doc.flags()} == {'lab_flag', 'book_read', 'stepped'}
    # ---- world graph: A-B door, A-GreatTree door, B->A exit, A->A warp
    nodes, edges = Wd.world_graph(s.doc, rend)
    kinds = sorted(e['kind'] for e in edges)
    assert kinds == ['door', 'door', 'exit', 'warp'], kinds
    assert ('vanilla', 0x01) in {n['key'] for n in nodes}
    # ---- exact undo / redo
    n = s.undo.index() - n0   # (the undone 'del' probe stays redoable)
    for _ in range(n):
        s.undo.undo()
    app.processEvents()
    assert s.doc.dumps() == saved, 'full undo must restore the project byte-for-byte'
    for _ in range(n):
        s.undo.redo()
    app.processEvents()
    s.doc.save()
    print(f'OK: v5 — doors A(4,7)<->GreatTree Library door (vanilla partner bytes $88 (5,3)), '
          f'A(7,2)<->B dragged to {V5_B_DOOR} (step-out arrivals), one-way teleport, examine '
          f'spot (facing up), step trigger, YES/NO NPC (flag + move), world graph '
          f'{len(nodes)} rooms / {len(edges)} links; {n} undoable edits, exact undo/redo')
    return w, s, a_id, b_id


def tileset_sharing_check(new_dir):
    """S98 r2 (user: "when I make a custom room it should STOP sharing
    tilesets by default"; threshold shift "make that an option"): a copied
    room gets its own sheet; a shared sheet is flagged and "own copy" ends
    it; a full walkable side offers moving the split down one slot — Yes
    flips the cell and nothing else on screen changes, No changes nothing."""
    from editor2.app.main import MainWindow
    from PySide6.QtWidgets import QMessageBox
    from editor2.app.rooms import commands as C
    app = QApplication.instance() or QApplication(sys.argv)
    answers = []
    QMessageBox.question = staticmethod(lambda *a, **k: answers.pop(0) if answers
                                        else QMessageBox.Yes)
    warned = []
    QMessageBox.warning = staticmethod(lambda *a, **k: warned.append(a[2]))
    w = MainWindow()
    w.new_project(new_dir, 'tileset sharing')
    app.processEvents()
    rt, s = w.rooms_tab, w.session
    doc = s.doc
    for i in range(rt.vanilla_list.count()):
        if rt.vanilla_list.item(i).data(0x100) == 0x3F:
            rt.vanilla_list.setCurrentRow(i)
    app.processEvents()
    rt._clone_vanilla()
    app.processEvents()
    sid = rt.room_id
    rt.select_state(1)
    app.processEvents()
    answers.append(QMessageBox.Yes)                      # copy the tileset in
    rt._flip_walk(4, 1)
    app.processEvents()
    tid = doc.room(sid)['record']['tileset']
    # 1. Copy room -> its own sheet
    s.undo.push(C.SnapshotCommand(s, 'copy', lambda d: d.copy_room(sid, 'Servant B')))
    cid = [r['id'] for r in doc.rooms if r['id'] != sid][0]
    ctid = doc.room(cid)['record']['tileset']
    assert ctid != tid and os.path.exists(doc.sheet_path(ctid)), (ctid, tid)
    assert doc.read_sheet(ctid) == doc.read_sheet(tid)
    assert not doc.tileset_sharers(doc.room(sid)) and not doc.tileset_sharers(doc.room(cid))
    # 2. make them share (the old behaviour) -> flagged
    s.undo.push(C.SnapshotCommand(s, 'share', lambda d: d.set_room_tileset(cid, 'project', tid)))
    assert [r['id'] for r in doc.tileset_sharers(doc.room(sid))] == [cid]
    # 3. fill the walkable side, then flip a wall cell walkable
    thr = val(doc.room(sid)['record']['collision_threshold'])
    used = doc.used_tiles(tid)
    for i in range(thr, 128):
        if i not in used and i not in (77, 78):
            doc.add_metatile(tid, f'fill {i}', [i] * 4, 0)
    assert doc.free_counts(tid, thr)['walkable'] == 0
    rt._show()
    app.processEvents()
    cv = rt.canvas
    sheet = doc.read_sheet(tid)
    cell = approach = None
    DIRS = {'left': (-1, 0), 'right': (1, 0), 'up': (0, -1), 'down': (0, 1)}
    for y in range(1, 7):
        for x in range(1, 9):
            if cv.cell_walkable(x, y):
                continue
            t = cv.tiles[y * 2 + 1][x * 2 + 1] & 0x7F
            g = sheet[t * 16:t * 16 + 16]
            if any(sheet[i * 16:i * 16 + 16] == g for i in range(thr, 128)):
                continue
            for d, (dx, dy) in DIRS.items():       # a walkable cell to walk in from
                if cv.cell_walkable(x - dx, y - dy):
                    cell, approach = (x, y), ((x - dx, y - dy), d)
                    break
            if cell:
                break
        if cell:
            break
    assert cell, 'no wall cell (with a walkable neighbour) lacking a walkable twin'
    # which placed wall cells use the slot that will move ($thr-1)?
    moved_cells = [(x, y) for y in range(8) for x in range(10)
                   if (cv.tiles[y * 2 + 1][x * 2 + 1] & 0x7F) == thr - 1]
    room = doc.room(sid)
    before = s.renderer.render_screen(room, 0, 1, 1).convert('RGB')
    snap = doc.dumps()
    answers.append(QMessageBox.No)                       # decline the shift
    rt._flip_walk(*cell)
    app.processEvents()
    assert doc.dumps() == snap and not warned, 'No = nothing changes, no error box'
    answers.append(QMessageBox.Yes)
    rt._flip_walk(*cell)
    app.processEvents()
    room = doc.room(sid)
    assert val(room['record']['collision_threshold']) == thr - 1, room['record']
    assert val(doc.room(cid)['record']['collision_threshold']) == thr - 1, 'sharer follows'
    assert rt.canvas.cell_walkable(*cell), 'the cell is walkable now'
    after = s.renderer.render_screen(room, 0, 1, 1).convert('RGB')
    diff = [(x, y) for y in range(before.height) for x in range(before.width)
            if before.getpixel((x, y)) != after.getpixel((x, y))]
    assert not diff, f'the screen must look identical ({len(diff)} pixels changed)'
    # 4. own copy ends the sharing
    rt._show()
    app.processEvents()
    rt.room_list.setCurrentRow([rt.room_list.item(i).data(0x100)
                                for i in range(rt.room_list.count())].index(cid))
    app.processEvents()
    rt._own_tileset()
    app.processEvents()
    assert doc.room(cid)['record']['tileset'] not in (tid, ctid)
    assert not doc.tileset_sharers(doc.room(sid))
    # 5. purge buttons (S98 r2): borrowed pieces placed nowhere go, a placed
    # one stays; own metatiles are a separate button
    rt.room_list.setCurrentRow([rt.room_list.item(i).data(0x100)
                                for i in range(rt.room_list.count())].index(sid))
    app.processEvents()
    for i in range(rt.foreign_box.count()):
        if rt.foreign_box.itemData(i) == 0x01:
            rt.foreign_box.setCurrentIndex(i)
    app.processEvents()
    tid_now = doc.room(sid)['record']['tileset']
    for mt in rt._vanilla_vocab(0x01)[:4]:
        rt._import_metatile(mt)
        app.processEvents()
    mts = doc.metatiles(tid_now)
    borrowed = [m for m in mts if doc.metatile_kind(m) == 'borrowed']
    assert len(borrowed) == 4 and all(m.get('src') == 'borrowed' for m in borrowed)
    keep = borrowed[0]
    from editor2.app.rooms.commands import PaintCells
    lid_s = s.renderer.screen_state(doc.room(sid), 0, 1)['layout']['id']
    s.undo.push(PaintCells(s, lid_s, 'tiles', [(12, 2, keep['tiles'][0]), (12, 3, keep['tiles'][1]),
                                              (13, 2, keep['tiles'][2]), (13, 3, keep['tiles'][3])],
                           'place one'))
    rt._show()
    app.processEvents()
    thr_s = val(doc.room(sid)['record']['collision_threshold'])
    n_own = len(doc.unused_metatiles(tid_now, 'own'))
    free0 = doc.free_counts(tid_now, thr_s)['total']
    from PySide6.QtTest import QTest
    from PySide6.QtCore import Qt as _Qt
    QTest.mouseClick(rt.tileset_map.purge_b, _Qt.LeftButton)
    app.processEvents()
    left = [m for m in doc.metatiles(tid_now) if doc.metatile_kind(m) == 'borrowed']
    assert left == [keep], f'only the placed borrowed metatile stays: {left}'
    assert len(doc.unused_metatiles(tid_now, 'own')) == n_own, 'own ones untouched'
    assert doc.free_counts(tid_now, thr_s)['total'] > free0
    # 6. S98 r2 (user: "I walk onto door but nothing happens"): a door on an
    # edge that scrolls into another screen can never fire — refused, and an
    # existing one is drawn as a red 'D!'
    rt._add_screen(1)
    app.processEvents()
    rt.select_screen(0)
    app.processEvents()
    n_warn = len(warned)
    rt.canvas.selected_cell = (9, 3)
    rt.act_add_door.trigger()
    app.processEvents()
    assert len(warned) == n_warn + 1 and 'SCROLLS' in warned[-1], warned[-1:]
    assert doc.door_end_at(sid, 0, 9, 3) is None, 'no door written on the dead edge'
    st1 = rt.state_idx
    doc.exits_of(doc.room(sid), 0, st1).append({'x': 9, 'y': 3, 'door': 'door_x',
                                                'name': 'hand-made'})
    rt._show()
    app.processEvents()
    assert any(m[0] == 'door_dead' and (m[1], m[2]) == (9, 3) for m in rt.canvas.markers)
    doc.exits_of(doc.room(sid), 0, st1).pop()
    s.undo.undo()                                # the added screen
    rt._show()
    app.processEvents()
    # for the ROM check: the room always shows state 1 (the edited layout)
    s.undo.push(C.SnapshotCommand(s, 'rule', lambda d: d.set_state_rules(
        d.room(sid), [{'state': 1, 'when': []}])))
    doc.save()
    w._ts_info = {'sid': sid, 'cell': cell, 'approach': approach, 'thr': thr,
                  'moved_cells': moved_cells, 'dirs': DIRS}
    print(f'OK: tilesets — Copy room gets its own sheet ({ctid}); a shared sheet is flagged; '
          f'walkable side full -> "move the split down" asked (No = no change; Yes = cell '
          f'{cell} walkable, split ${thr:02X}->${thr - 1:02X}, screen pixel-identical); '
          f'"own copy" stops sharing; "Purge unused borrowed" drops the 3 unplaced '
          f'borrowed metatiles and keeps the placed one')
    return w


def test_rom_tilesets(w, keep_dir=None):
    """--rom: the cell made walkable by moving the split down is walkable
    in game; the wall cells whose tile moved to a lower slot still block."""
    from editor2.app.build_worker import BuildWorker
    from tools.pyboy_harness import boot, to_bedroom, warp, adv, MAP_ID
    app = QApplication.instance()
    info, s = w._ts_info, w.session
    results = []
    worker = BuildWorker(REPO, s.project_dir)
    worker.finished_build.connect(results.append)
    worker.start()
    worker.wait()
    app.processEvents()
    res = results[0]
    assert res.ok, f'build failed: {res.error}'
    mid = val(s.doc.room(info['sid'])['mapID'])
    p = boot(res.rom_path)
    assert to_bedroom(p), 'scripted intro failed'
    p.memory[0xCA39] = p.memory[0xCA3A] = 0xFF

    def walk_from(start, d):
        warp(p, mid, *start, settle=500)
        adv(p, 60)
        assert p.memory[MAP_ID] == mid
        for _ in range(40):
            p.button_press(d)
            p.tick()
        p.button_release(d)
        adv(p, 30)
        return p.memory[0xFF97], p.memory[0xFF98]
    (ax, ay), d = info['approach']
    got = walk_from((ax, ay), d)
    assert got == info['cell'], f"walking {d} from {(ax, ay)}: at {got}, want {info['cell']}"
    blocked = 0
    for (x, y) in info['moved_cells']:
        for dd, (dx, dy) in info['dirs'].items():
            sx, sy = x - dx, y - dy
            if not (0 <= sx <= 9 and 0 <= sy <= 7) or (sx, sy) == info['cell']:
                continue
            grid = s.renderer.layout_grid(s.renderer.screen_state(
                s.doc.room(info['sid']), 0, 1)['layout'])[0]
            thr_now = val(s.doc.room(info['sid'])['record']['collision_threshold'])
            if grid[sy * 2 + 1][sx * 2 + 1] < thr_now:
                continue                               # start cell is a wall
            got = walk_from((sx, sy), dd)
            assert got == (sx, sy), f'moved wall tile at {(x, y)} let the player in ({got})'
            blocked += 1
            break
    # control: another wall cell next to open floor still blocks
    room = s.doc.room(info['sid'])
    grid = s.renderer.layout_grid(s.renderer.screen_state(room, 0, 1)['layout'])[0]
    thr_now = val(room['record']['collision_threshold'])
    ctrl = None
    for y in range(1, 7):
        for x in range(1, 9):
            if (x, y) == info['cell'] or grid[y * 2 + 1][x * 2 + 1] >= thr_now:
                continue
            for dd, (dx, dy) in info['dirs'].items():
                sx, sy = x - dx, y - dy
                if (sx, sy) != info['cell'] and grid[sy * 2 + 1][sx * 2 + 1] >= thr_now:
                    ctrl = ((sx, sy), dd, (x, y))
                    break
            if ctrl:
                break
        if ctrl:
            break
    assert ctrl, 'no control wall cell'
    got = walk_from(ctrl[0], ctrl[1])
    assert got == ctrl[0], f'control wall {ctrl[2]} let the player in ({got})'
    print(f"OK: split moved down — cell {info['cell']} walkable in game; wall {ctrl[2]} still "
          f"blocks; {blocked} wall cell(s) whose tile changed slot checked")
    if keep_dir:
        shutil.copy(res.rom_path, os.path.join(keep_dir, 'rom_tilesets.gbc'))
    p.stop(save=False)


def test_rom_v5(w, s, a_id, b_id, keep_dir=None):
    """--rom: PyBoy — both doors both ways with the measured arrivals, the
    examine spot answers only when faced from below, the step trigger fires
    and sets its flag, the NPC's YES sets lab_flag and reloads room A in
    state 1 (the rule), the one-way teleport lands where authored."""
    from editor2.app.build_worker import BuildWorker
    app = QApplication.instance()
    results = []
    worker = BuildWorker(REPO, s.project_dir)
    worker.finished_build.connect(results.append)
    worker.start()
    worker.wait()
    app.processEvents()
    res = results[0]
    assert res.ok, f'build failed: {res.error}'
    man = json.load(open(os.path.join(os.path.dirname(res.rom_path), 'manifest.json')))
    fl = {k: int(v.lstrip('$'), 16) for k, v in man['flags'].items()}
    ctr = int(next(v for k, v in man['step_counters'].items() if k.endswith('_S0'))
              .lstrip('$'), 16)
    A, B = s.doc.room(a_id), s.doc.room(b_id)
    ma, mb = val(A['mapID']), val(B['mapID'])
    from tools.pyboy_harness import boot, to_bedroom, warp, adv, MAP_ID, flag
    import tempfile as _t
    p = boot(res.rom_path)
    assert to_bedroom(p), 'scripted intro failed'
    base = os.path.join(_t.mkdtemp(prefix='v5_'), 'bed.state')
    with open(base, 'wb') as f:
        p.save_state(f)

    def fresh():
        p.load_state(open(base, 'rb'))

    def pos():
        return p.memory[MAP_ID], p.memory[0xFF97], p.memory[0xFF98]

    def walk(d, frames):
        p.button_press(d)
        for _ in range(frames):
            p.tick()
        p.button_release(d)
        adv(p, 120)
        return pos()

    def tap(b, wait=40):
        p.button_press(b)
        adv(p, 3)
        p.button_release(b)
        adv(p, wait)

    def text_id():
        return p.memory[0xD8D9] | p.memory[0xD8DA] << 8

    def tid(did):
        return next(int(k.lstrip('$'), 16) for k, v in man['texts'].items() if v['id'] == did)
    # 1. Library door -> A on its door cell (4,7); walking back onto it -> GreatTree (5,4)
    fresh()
    p.memory[0xD95C] = 0
    warp(p, 0x01, 5, 16 + 4, settle=400)
    assert walk('up', 20) == (ma, 4, 7), pos()
    assert walk('up', 20) == (ma, 4, 6), pos()
    assert walk('down', 20)[0] == 0x01 and pos()[1:] == (5, 16 + 3), \
        f'back through door_1: {pos()} (want GreatTree screen 8 ON the door (5,3))'
    y = p.memory[0xFF95] | p.memory[0xFF96] << 8
    assert y % 16 == 8, f'arrival pixel y {y}: not a whole-tile position'
    print('OK: door_1 — Library door -> A (4,7) on the door cell; back -> GreatTree ON the '
          'Library door (5,3), whole-tile pixel position')
    # 2. A (7,2) -> B arrives ON its door; step off and back on -> A, on (7,2)
    fresh()
    warp(p, ma, 7, 3, settle=400)
    assert walk('up', 20) == (mb, *V5_B_DOOR), pos()
    y = p.memory[0xFF95] | p.memory[0xFF96] << 8
    assert y % 16 == 8, f'arrival pixel y {y}: not a whole-tile position (half a cell off)'
    adv(p, 60)
    assert walk('down', 20) == (mb, V5_B_DOOR[0], V5_B_DOOR[1] + 1), \
        f'arriving on the door must not re-fire it: {pos()}'
    assert walk('up', 20) == (ma, 7, 2), pos()
    print(f'OK: door_2 — A (7,2) <-> B {V5_B_DOOR}: both ways, arriving ON the door cell '
          '(no re-fire; step off and on to go back)')
    # 3. examine spot: answers facing up from (1,2), not from the side
    fresh()
    warp(p, ma, V5_BOOK[0] + 1, V5_BOOK[1], settle=400)
    walk('left', 3)
    tap('a', 60)
    assert not (p.memory[0xC8EB] & 1), 'examine spot answered while facing left'
    fresh()
    warp(p, ma, V5_BOOK[0], V5_BOOK[1] + 1, settle=400)
    walk('up', 3)
    tap('a', 60)
    ex = next(v for v in (s.doc.npc_view(A, e) for e in s.doc.npc_entries(A, 0, 0))
              if v['kind'] == 'examine')
    want = tid(s.doc.script(ex['script'])['talk']['text'])
    assert p.memory[0xC8EB] & 1 and text_id() == want, (hex(text_id()), hex(want))
    for _ in range(4):
        tap('a', 40)
    assert flag(p, fl['book_read']), 'the examine spot set book_read after its text'
    print('OK: examine spot — answers facing up only; its talk set book_read')
    # 4. step trigger
    fresh()
    warp(p, ma, V5_STEP[0], V5_STEP[1] - 1, settle=400)
    walk('down', 20)
    assert p.memory[0xC8EB] & 1, 'step trigger did not open its text'
    for _ in range(3):
        tap('a', 40)
    assert flag(p, fl['stepped']), 'step trigger set stepped'
    print('OK: step-on trigger — walking onto it shows its text and sets its flag')
    # 5. the question NPC: YES -> reply, lab_flag, reload -> state 1 by the rule
    fresh()
    warp(p, ma, *V5_NPC_STAND, settle=400)
    assert p.memory[ctr] == 0
    walk('up', 3)
    tap('a', 90)
    tap('up', 20)                        # cursor to YES ($C83C 0)
    assert p.memory[0xC83C] == 0
    tap('a', 30)
    adv(p, 60)
    tap('a', 30)                          # dismiss "Done!"
    adv(p, 300)
    assert flag(p, fl['lab_flag']), 'YES must set lab_flag'
    assert p.memory[MAP_ID] == ma and pos()[1:] == V5_NPC_STAND, pos()
    assert p.memory[ctr] == 1, f'reload must pick state 1 via the rule (counter {p.memory[ctr]})'
    grid = s.renderer.layout_grid(s.renderer.screen_state(A, 0, 1)['layout'])[0]
    vram = [[p.memory[0x9800 + r * 32 + c] for c in range(20)] for r in range(16)]
    assert vram == [list(r) for r in grid], 'VRAM != state 1 grid after the reload'
    print('OK: NPC YES — reply shown, lab_flag set, player moved -> room A reloads in state 1 '
          '(rule), VRAM == state 1 canvas')
    # 6. one-way teleport B -> A (5,5)
    fresh()
    warp(p, mb, V5_TELE[0], V5_TELE[1] - 1, settle=400)
    assert walk('down', 20) == (ma, 5, 5), pos()
    print('OK: one-way teleport B (8,6) -> A (5,5)')
    if keep_dir:
        shutil.copy(res.rom_path, os.path.join(keep_dir, 'rom_v5.gbc'))
    p.stop(save=False)


def test_all_clones():
    """--all-clones (S96): EVERY vanilla room clones ("Make editable"),
    every screen AND every valid state renders pixel-identical to vanilla,
    and each single-clone project passes the compiler (scripts decoded by
    the handler-arity table, attr rows read by direct screen index, per-
    screen step-0 palettes). ~12 s."""
    from editor2.core.document import Document
    from editor2.core.render_project import ProjectRenderer
    from editor2.core.compiler import compile_project
    base = tempfile.mkdtemp(prefix='dwm_clones_')
    r0 = ProjectRenderer(REPO, base, {})
    n_scr = n_st = 0
    bad = []
    for mid, name, scr in r0.vanilla_rooms():
        d = os.path.join(base, f'm{mid:02X}')
        os.makedirs(d)
        shutil.copy(os.path.join(REPO, 'editor2', 'templates', 'blank-project',
                                 'project.json'), d)
        doc = Document(d)
        r = ProjectRenderer(REPO, d, doc.data)
        doc.vanilla = r
        try:
            rid = doc.clone_vanilla(mid, name, REPO, r)
            r.invalidate()
            room = doc.room(rid)
            for k in scr:
                n_scr += 1
                for st in range(len(r.vanilla_steps(mid, k))):
                    n_st += 1
                    if r.render_screen(room, k, st, 1).tobytes() != \
                            r.render_vanilla_screen(mid, k, 1, st).tobytes():
                        bad.append(f'${mid:02X} {name} screen {k} state {st}: render')
            doc.save()
            compile_project(d, REPO)
        except Exception as e:
            bad.append(f'${mid:02X} {name}: {str(e)[:200]}')
    shutil.rmtree(base, ignore_errors=True)
    assert not bad, '\n'.join(bad)
    print(f'OK: all {len(r0.vanilla_rooms())} vanilla rooms clone — {n_scr} screens / '
          f'{n_st} states pixel-identical, every clone compiles')


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
    if '--only-v5' in sys.argv:          # S98: fast path while iterating on v5
        tmp = tempfile.mkdtemp(prefix='dwm_v5_')
        keep = None
        if '--out' in sys.argv:
            keep = os.path.abspath(sys.argv[sys.argv.index('--out') + 1])
            os.makedirs(keep, exist_ok=True)
            tmp = keep
        v5_dir = os.path.join(tmp, 'fresh_v5')
        if os.path.exists(v5_dir):
            shutil.rmtree(v5_dir)
        w5, s5, a5, b5 = v5_round_trip(v5_dir)
        test_compile(v5_dir)
        tsd = os.path.join(tmp, 'fresh_tilesets')
        if os.path.exists(tsd):
            shutil.rmtree(tsd)
        wts = tileset_sharing_check(tsd)
        test_compile(tsd)
        if do_rom:
            test_rom_v5(w5, s5, a5, b5, keep)
            test_rom_tilesets(wts, keep)
        print('PASS (v5 only)')
        return
    test_all_clones()
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
    v3_dir = os.path.join(tmp, 'fresh_v3')
    if os.path.exists(v3_dir):
        shutil.rmtree(v3_dir)
    w3, s3, rid3 = v3_round_trip(v3_dir)
    test_compile(v3_dir)
    v4_dir = os.path.join(tmp, 'fresh_v4')
    if os.path.exists(v4_dir):
        shutil.rmtree(v4_dir)
    w4, s4, rid4, ti4, wi4 = v4_round_trip(v4_dir)
    test_compile(v4_dir)
    v5_dir = os.path.join(tmp, 'fresh_v5')
    if os.path.exists(v5_dir):
        shutil.rmtree(v5_dir)
    w5, s5, a5, b5 = v5_round_trip(v5_dir)
    test_compile(v5_dir)
    tsd = os.path.join(tmp, 'fresh_tilesets')
    if os.path.exists(tsd):
        shutil.rmtree(tsd)
    wts = tileset_sharing_check(tsd)
    test_compile(tsd)
    if do_rom:
        test_rom_tilesets(wts, keep)
        test_rom(proj, grids, keep)
        test_rom_v2(w2, s2, rid, keep)
        test_rom_v3(w3, s3, rid3, keep)
        test_rom_v4(w4, s4, rid4, ti4, wi4, keep)
        test_rom_v5(w5, s5, a5, b5, keep)
    if not keep:
        shutil.rmtree(tmp, ignore_errors=True)
    print('PASS')


if __name__ == '__main__':
    main()
