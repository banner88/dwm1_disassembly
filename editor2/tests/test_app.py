#!/usr/bin/env python3
"""test_app.py — app smoke test (S72 skeleton, S93 shell), headless-safe.

Runs the REAL app code offscreen (QT_QPA_PLATFORM=offscreen): opens the
example project, checks the Rooms tab renders LIVE from project.json (no
build needed since S93), that placeholder rooms do not render, that a
vanilla-referenced layout is read-only, that states switch, that the
document model round-trips project.json byte-for-byte, and (with --rom)
drives a Build through the app's worker code path and asserts the ROM md5
equals the pinned compat reference from editor2/tests/test_compiler.py —
proving GUI build == CLI build == hand-staged overlay, byte-identical.

SKIPs (exit 0 with a message) when PySide6 is not installed, so CI without
Qt stays green — the same ROM-tolerant posture as verify_integrity check 5.
The canvas acceptance (paint / states / PyBoy) lives in test_canvas.py.
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)

os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')

try:
    from PySide6.QtWidgets import QApplication          # noqa: E402
except ImportError:
    print('SKIP: PySide6 not installed (pip install PySide6 Pillow)')
    sys.exit(0)


def pinned_md5():
    """Single source of truth: the compat pin inside test_compiler.py."""
    src = open(os.path.join(REPO, 'editor2/tests/test_compiler.py')).read()
    m = re.search(r"REFERENCE_MD5\s*=\s*['\"]([0-9a-f]{32})['\"]", src)
    assert m, 'REFERENCE_MD5 not found in test_compiler.py'
    return m.group(1)


def s119_cutscene_editor(app, w, ct):
    """S119 (ROADMAP P3.8 part B, user: "Should be specific NPCs … visual … in
    tiles … previewable"): the cutscene editor on the example project — name an
    NPC, add a cast member, a new entry scene, steps added (incl. a drag on the
    stage), the model's picture / preview, the op editing of a copied room's
    script (part c); everything undone again (the project is not saved)."""
    from editor2.app.rooms import commands as C
    from editor2.core import cutscene_doc as CD
    from editor2.core import cutscene_build as CB
    from editor2.app.cutscenes_tab import questions_of
    from editor2.core import cutscenes as CSm
    from collections import namedtuple
    _st = {0: CSm.Step(0, CSm.TEXT, [5], None, None), 1: CSm.Step(1, 0x15, [0xC83C, 0, 9], 9, None),
           4: CSm.Step(4, CSm.TEXT, [6], None, None), 5: CSm.Step(5, CSm.END, [], None, None)}
    _sc = namedtuple('Sc', 'script')(CSm.Script(('project', 'x'), _st))
    _rc = namedtuple('Rc', 'script_type script_idx')(0x171, 3)
    assert questions_of(_rc, _sc) == [[0x71, 3, 0]], questions_of(_rc, _sc)
    print('OK: S119 questions_of — a project script\'s YES/NO text found for the auto answer')
    s = w.session
    start = s.undo.index()
    s.undo.push(C.SnapshotCommand(s, 'n', lambda doc: CD.name_actor(doc, 'gate_island', 0, 0, 1, 'Guard')))
    s.undo.push(C.SnapshotCommand(s, 'c', lambda doc: CD.add_cast(doc, 'gate_island', 0, 'Ghost', 0x0B, 1, 3, 'right')))
    cmd = C.SnapshotCommand(s, 'new', lambda doc: CD.new_cutscene(doc, 'gate_island', 'Haunt', 0, 'entry'))
    s.undo.push(cmd)
    sid = cmd.result
    app.processEvents()
    tops = [ct.tree.topLevelItem(i).text(0) for i in range(ct.tree.topLevelItemCount())]
    mine = ct.tree.topLevelItem(0)
    assert mine.text(0).startswith('Your cutscenes') and mine.child(0).childCount() == 1, tops
    ct.tree.setCurrentItem(mine.child(0).child(0))
    app.processEvents()
    ed = ct.editor
    assert ct.pages.currentIndex() == 1 and ed.scene_id == sid
    ed.add_step('show', {'show': {'actor': 'Ghost', 'how': 'flicker'}})
    ed.add_step('walk', {'walk': {'actor': 'Ghost', 'to': [3, 3]}})
    ed.add_step('face', {'face': {'actor': 'Ghost', 'toward': 'Guard'}})
    ed.add_step('say', {'say': {'boxes': [['Boo!']]}})
    ed._dragged('Guard', 4, 6)                     # a drag on the stage = a walk
    ed.add_step('anim', {'anim': {'actor': 'Ghost', 'move': 'hop'}})
    app.processEvents()
    r, sc = CD.find(s.doc, sid)
    kinds = [CB.step_kind(x) for x in sc['steps']]
    assert kinds == ['show', 'walk', 'face', 'say', 'walk', 'anim'], kinds
    assert sc['steps'][4]['walk'] == {'actor': 'Guard', 'to': [4, 6]}
    assert 'no problems' in ed.problems.text(), ed.problems.text()
    assert ed.tree.topLevelItemCount() == 7                    # 6 steps + the end row
    ed.path = (1,)
    ed.refresh()
    assert ed.stage.moves and ed.stage.moves[0][0] == 'Ghost', ed.stage.moves
    g = ed.stage.actors['Ghost']
    assert (g['x'], g['y']) == CB.cell_px(0, 3, 3) and g['shown'], g
    ed.preview()
    for _ in range(4000):
        ed._tick()
        if not ed.timer.isActive():
            break
    assert not ed.timer.isActive()
    ed._scrub(int(ed.t_end))                       # the preview's last frame
    last = ed.lw.info[-1]['state']
    assert ed.stage.actors['Guard']['x'] == last['Guard']['x'] == CB.cell_px(0, 4, 6)[0]
    grab = ed.stage.grab()
    assert grab.width() == 480 and grab.height() == 384
    # S119 r2 (user: "Why cant I select npc in a custom room …"): the talk trigger
    # lists the NPCs without a scene name too; picking one names it
    ed.trig.setCurrentIndex(ed.trig.findData('talk'))
    app.processEvents()
    toks = [i for i in range(ed.trig_actor.count()) if CD.is_token(ed.trig_actor.itemData(i))]
    assert toks, [ed.trig_actor.itemText(i) for i in range(ed.trig_actor.count())]
    ed.trig_actor.setCurrentIndex(toks[0])
    app.processEvents()
    r, sc = CD.find(s.doc, sid)
    nm = sc['trigger'].get('actor')
    assert nm and not CD.is_token(nm) and any(
        e.get('actor') == nm for e in r['screens']['0']['npcs']), sc['trigger']
    assert ed.trig_actor.currentData() == nm, ed.trig_actor.currentData()
    print(f'OK: S119 r2 — an NPC without a scene name picked for "talking to" -> named “{nm}”')
    # S119b (user's Mac: "Segmentation fault: 11" picking an unnamed NPC in a walk's
    # Who list): a form widget must outlive its own signal — the edit is applied
    # after it returns (macOS crashes when a combo dies while its popup closes)
    import shiboken6
    from PySide6.QtWidgets import QComboBox as _QCB
    s.undo.push(C.SnapshotCommand(s, 'npc', lambda doc: doc.room('gate_island')['screens']['0']
                                  ['npcs'].append({'kind': 'npc', 'sprite': '0x10', 'x': 8, 'y': 2,
                                                   'facing': 'down', 'script': 'none'})))
    app.processEvents()
    ed.path = (1,)                                  # the Ghost's walk
    ed.refresh()
    cb = ed.form.body.findChildren(_QCB)[0]
    toks = [i for i in range(cb.count()) if CD.is_token(cb.itemData(i))]
    assert toks, [cb.itemText(i) for i in range(cb.count())]
    cb.setCurrentIndex(toks[0])
    assert shiboken6.isValid(cb), 'the Who combo was deleted inside its own signal'
    app.processEvents()
    r, sc = CD.find(s.doc, sid)
    who = sc['steps'][1]['walk']['actor']
    assert who and not CD.is_token(who) and who != 'Ghost', sc['steps'][1]
    # S119b (user: "Why is text box so slow to type in?"): keys are not commits —
    # the text is stored once after a pause, the box keeps its cursor (it was
    # rebuilt per key: "Hello" came out "olleH")
    import time as _time
    from PySide6.QtTest import QTest
    from PySide6.QtWidgets import QPlainTextEdit as _QPT
    ed.path = (3,)                                  # the "Boo!" text
    ed.refresh()
    te = ed.form.body.findChildren(_QPT)[0]
    te.moveCursor(te.textCursor().MoveOperation.End)
    n0 = s.undo.index()
    for ch in ' Hello':
        QTest.keyClicks(te, ch)
        app.processEvents()
    assert s.undo.index() == n0, 'a key press must not be an undo step'
    t0 = _time.time()
    while _time.time() - t0 < 1.2:
        app.processEvents()
        _time.sleep(0.02)
    assert shiboken6.isValid(te) and ed.form.body.findChildren(_QPT)[0] is te, 'box rebuilt'
    r, sc = CD.find(s.doc, sid)
    assert sc['steps'][3]['say']['boxes'] == [['Boo! Hello']], sc['steps'][3]
    assert s.undo.index() == n0 + 1, (n0, s.undo.index())
    print('OK: S119b — typing in a text step: no commit per key, one undo step after the '
          'pause, the box (and its cursor) kept')
    # S119b (user: "Why not preview message using in-game boxes …" / "Can you not hover or
    # explain what is e.g. 'wait until everyone stops'?" / "Why cant I copy paste build log?")
    from editor2.app.rooms.talk_editor import BoxList as _BL
    from editor2.app.cutscene_editor import STEP_HELP
    from PySide6.QtCore import Qt as _Qt
    assert ed.form.body.findChildren(_BL), 'the text step has no in-game box editor'
    assert ed.form.about.text() == STEP_HELP['say']
    missing = [k for k in CB.STEP_KINDS if not STEP_HELP.get(k)]
    assert not missing, f'steps without an explanation: {missing}'
    assert ed.tree.topLevelItem(3).toolTip(0), 'step list rows have no hover text'
    assert w.log.textInteractionFlags() & _Qt.TextSelectableByKeyboard, 'build log: ⌘A / ⌘C'
    print('OK: S119b — text steps use the in-game box editor; every step kind explained '
          '(form + hover); the build log selectable by keyboard')
    print(f'OK: S119b — a walk\'s Who changed to an unnamed NPC: applied after the combo\'s '
          f'signal (the combo survives it), the NPC named “{who}”')
    # part c: a copied room's script, step by step (arena_clone $72)
    from editor2.app.cutscenes_tab import SceneRef, OpDialog
    ct._load_project()
    scs = [x for x in ct.pcat.scenes(0x72, min_show=0) if len(x.steps) > 3]
    assert scs
    ct.pages.setCurrentIndex(0)
    ct.cur = SceneRef('project', 0x72, scs[0], ct.pcat, 't')
    ct.show_scene()
    n_ok = 0
    for row, st in enumerate(scs[0].steps):
        ct.steps.setCurrentRow(row)
        t = ct._op_target()
        assert t is not None, row
        sc2, i = t
        it = sc2['ops'][i]
        assert (it[0] == 'end') == (st.code == 0x100) and (it[0] == 'text') == (st.code == 0x101)
        if it[0] == 'op':
            assert OpDialog._code(it[1]) == st.code, (it, st)
        n_ok += 1
    assert ct.b_edit_op.isEnabled()
    d = OpDialog(ct, ['op', 'npc_walk_x', '0x0001', '0xFFF0'], [])
    d._ok()
    assert d.value == ['op', '0x1A', '0x0001', '0xFFF0'], d.value
    while s.undo.index() > start:
        s.undo.undo()
    app.processEvents()
    assert s.doc.dumps() == open(s.doc.path).read(), 'undo restores the project exactly'
    print(f'OK: Cutscene editor (S119) — named NPC + cast member, a new scene of 6 steps '
          f'(one by dragging on the stage), the stage picture / arrows / preview, '
          f'{n_ok} steps of a copied room\'s script mapped to their ops, undone again')


def s120_dialogue(app, w):
    """S120 (ROADMAP P3.6): the box editor's Speaker / Voice / Insert — through the
    TalkDialog and the document's talk + conversation round trips."""
    from editor2.app.rooms.talk_editor import TalkDialog
    import copy
    from editor2.core.document import Document
    doc = Document(w.session.doc.path)                  # a private copy: the window's doc untouched
    rom = w.session.renderer.rom if getattr(w.session, 'renderer', None) else None
    spec = {'boxes': [["I'll show", "what's [new]: x&y"]], 'speaker': 'Milayou', 'voice': 'high'}
    dlg = TalkDialog(rom=rom, spec=spec, doc=doc)
    bl = dlg.box_list
    assert bl.speaker() == 'Milayou' and bl.meta() == {'speaker': 'Milayou', 'voice': 'high'}, bl.meta()
    assert not bl.bad_boxes(), bl.bad_boxes()
    ed = bl.editors[0]
    assert '10 cells' in ed.title.text(), ed.title.text()
    ed.edit.setPlainText("I'll show you more")           # 16 cells > 10 after "Milayou:"
    app.processEvents()
    assert bl.bad_boxes() == [1], bl.bad_boxes()
    bl.sp_kind.setCurrentIndex(bl.sp_kind.findData(''))   # no label: 18 cells
    app.processEvents()
    assert not bl.bad_boxes() and bl.meta() == {'speaker': '', 'voice': 'high'}, bl.meta()
    ed.edit.setPlainText('Hi ')
    from PySide6.QtGui import QTextCursor
    ed.edit.moveCursor(QTextCursor.End)
    ed._insert('{hero}')
    assert ed.lines() == ['Hi {hero}'] and not ed.problems(), (ed.lines(), ed.problems())
    got = dlg.spec()
    assert got['speaker'] == '' and got['voice'] == 'high', got
    # the document keeps them (talk form + conversation form)
    room = next(r for r in doc.rooms if not r.get('placeholder'))
    sid = doc.new_talk(room, got, name='s120')
    back = doc.talk_spec(sid)
    assert back['speaker'] == '' and back['voice'] == 'high' and back['boxes'] == [['Hi {hero}']], back
    csid = doc.new_conversation(room, {'steps': [
        {'say': {'boxes': [['Hello']], 'speaker': 'hero', 'voice': 'none'}},
        {'ask': {'boxes': [['Sure?']]}, 'yes': [{'ask': {'boxes': [['Really?']]},
                                                 'yes': [{'say': {'boxes': [['Your {lead}']]}}],
                                                 'no': []}], 'no': []}]}, name='s120c')
    cs = doc.conversation_spec(csid)
    st = cs['steps']
    assert st[0]['say'].get('speaker') == 'hero' and st[0]['say'].get('voice') == 'none', st[0]
    assert st[1]['yes'][0]['yes'][0]['say']['boxes'] == [['Your {lead}']], st[1]
    dlg.deleteLater()
    print('OK: S120 — Speaker / Voice / Insert in the box editor (limits follow the speaker), '
          'kept by the talk and the nested conversation forms')


def s120_gates(app, w):
    """S120 (ROADMAP P3.7b part 2): the Gates tab's Maze floors group — rows named by the
    gates that use them, the maze pictures, one undo step per change."""
    gt = w.gates_tab
    w.tabs.setCurrentWidget(gt)
    app.processEvents()
    gt.list.setCurrentRow(5)
    app.processEvents()
    cb = gt.row_combos['maze_row']
    assert cb.count() == 16 and cb.currentData() == 3 and 'Bazaar Gate' in cb.currentText(), \
        cb.currentText()
    assert not gt.maze_pics.pixmap().isNull(), 'no maze pictures'
    n0 = w.session.undo.count()
    cb.setCurrentIndex(0)
    gt._set_row('maze_row')
    app.processEvents()
    assert w.session.doc.gate_setting(5).get('maze_row') == 0, w.session.doc.gate_setting(5)
    assert w.session.undo.count() == n0 + 1
    gt.set_depth.setValue(3)
    gt._set_row('depth')
    assert w.session.doc.gate_setting(5).get('depth') == 3
    gt._rows_vanilla()
    assert w.session.doc.gate_setting(5) == {}, w.session.doc.gate_setting(5)
    for _ in range(3):
        w.session.undo.undo()
    app.processEvents()
    assert w.session.doc.gate_setting(5) == {}, w.session.doc.gate_setting(5)
    print('OK: S120 — Gates tab maze floors: 16 rows per table named by their gates, the '
          'pictures, maze row / item tier / Vanilla as undo steps')


def s121_milly(app, w):
    """S121 (ROADMAP P3.16 + E7): the Cutscenes tab's Milly hook dialog — Create the
    roots room (a copy of $08 with Warubou's scene; the arrival), tick the hook, send
    Warubou's walk to one of the project's rooms; text previews draw MILLY only while
    the hook is on; everything undoes, leaving the project files as they were."""
    from editor2.app.milly_dialog import MillyHookDialog
    from editor2.core import milly as MH
    from editor2.core import textenc as Tx
    s = w.session
    pdir = s.doc.project_dir
    files0 = sorted(os.path.relpath(os.path.join(dp, f), pdir)
                    for dp, _d, fs in os.walk(pdir) for f in fs if '/build' not in dp)
    n0 = s.undo.index()
    assert Tx.PATCHED_GLYPHS == {}, 'the example has the hook off: previews say TERRY'
    d = MillyHookDialog(s, w)
    assert d.roots.count() == 0 and d.b_create.isEnabled()
    d._create_roots()
    app.processEvents()
    rid = d.roots.currentData()
    assert rid and d.room.currentData() == rid and (d.x.value(), d.y.value()) == (5, 4), \
        (rid, d.room.currentData(), d.x.value(), d.y.value())
    assert not d.b_create.isEnabled(), 'one roots room is enough'
    assert d.naming.isEnabled() and d.naming.isChecked(), 'S121 r3: a new roots room asks her name'
    d.on.setChecked(True)
    d.dest.setCurrentIndex(d.dest.findData('room:$6D'))
    assert [d.d_screen.itemData(i) for i in range(d.d_screen.count())] == [0], \
        'S121 r3: only the screens the destination has'
    d.dest.setCurrentIndex(d.dest.findData('room:$6B'))
    assert [d.d_screen.itemData(i) for i in range(d.d_screen.count())] == [0, 4]
    d.naming.setChecked(False)
    d._ok()
    assert not s.doc.roots_naming(rid), 'S121 r3: unticked = no naming screen'
    app.processEvents()
    h = s.doc.milly_hook()
    assert h['enabled'] and h['arrive']['room'] == rid and h['spin'], h
    assert s.doc.roots_scene_destination(rid)['dest'] == 'room:$6B'
    assert s.doc.milly_arrival_problem() is None
    assert Tx.PATCHED_GLYPHS == Tx.MILLY_GLYPHS, 'hook on: previews draw MILLY'
    assert 'hook:milly' in [k for k, _n in __import__(
        'editor2.app.rooms.rules_panel', fromlist=['x']).well_known(s.doc)]
    assert s.undo.index() == n0 + 2, (n0, s.undo.index())
    for _ in range(2):
        s.undo.undo()
    app.processEvents()
    assert not s.doc.milly_hook() and Tx.PATCHED_GLYPHS == {}
    assert not any(r['id'] == rid for r in s.doc.rooms)
    files1 = sorted(os.path.relpath(os.path.join(dp, f), pdir)
                    for dp, _d, fs in os.walk(pdir) for f in fs if '/build' not in dp)
    assert files0 == files1, set(files0) ^ set(files1)
    assert MH.ROOTS_SCENE == 'milly_roots'
    print('OK: S121 — Milly hook dialog: Create the roots room (the arrival), the tick, '
          'Warubou\'s destination, the naming option (r3), MILLY previews only with the hook, two undo steps undone '
          'cleanly')


def s122_gate_themes(app, w):
    """S122 (ROADMAP P3.7b part 2; user: "can I currently use gate themes for custom
    room build? … as an option for tileset, properly coloured" + "the option of starting
    with gate tiles/palettes then borrowing additional tiles elsewhere"): New room on a
    gate theme, its picker = the maze metatiles, the themes in the Borrow list, the Maze
    screen dialog (filters, 254 screens) stamping a screen, Change tileset -> a gate theme
    with its colours; everything undoes to the original project.json."""
    from PySide6.QtCore import Qt
    from PySide6.QtWidgets import QDialog
    from editor2.app.rooms import tab as RT
    from editor2.app.rooms import maze_dialog as MD
    from editor2.app.rooms.tileset_dialog import TilesetDialog
    from editor2.core import maze as MZ
    s = w.session
    doc = s.doc
    before = doc.dumps()
    n0 = s.undo.index()
    rt = w.rooms_tab
    w.tabs.setCurrentWidget(rt)
    app.processEvents()
    d = RT.NewRoomDialog(s.renderer, rt)
    assert d.theme.count() == 17, d.theme.count()
    d.theme.setCurrentIndex(5)
    assert d.theme.currentData() == 4 and not d.src.isEnabled() and not d.blank.isEnabled()

    class _New(RT.NewRoomDialog):
        def exec(self_):
            self_.name.setCurrentText('Ice room')
            self_.theme.setCurrentIndex(5)
            return QDialog.Accepted
    keep = RT.NewRoomDialog
    RT.NewRoomDialog = _New
    try:
        rt._new_room()
    finally:
        RT.NewRoomDialog = keep
    app.processEvents()
    room = rt.current_room()
    assert room is not None and doc.gate_theme(room) == 4, room
    voc = rt._room_vocab(room)
    assert any(m['tiles'] == [0x3C, 0x3D, 0x3E, 0x3F] for m in voc) and len(voc) >= 16, len(voc)
    data = [rt.foreign_box.itemData(i) for i in range(rt.foreign_box.count())]
    assert all(RT.THEME_KEY + t in data for t in range(16)), 'the 16 themes in Borrow'
    rt.foreign_box.setCurrentIndex(rt.foreign_box.findData(RT.THEME_KEY + 13))
    app.processEvents()
    md = MD.MazeScreenDialog(s.renderer, 4, rt.canvas.gfx, rt.canvas.pals, rt)
    assert md.list.count() == 254, md.list.count()
    md.open[MZ.OPEN_UP].setChecked(True)
    md.exact.setChecked(True)
    vis = [md.list.item(i) for i in range(md.list.count()) if not md.list.item(i).isHidden()]
    assert vis and all(it.data(Qt.UserRole)[2] == MZ.OPEN_UP for it in vis), len(vis)
    md.list.setCurrentItem(vis[0])
    pick = md.choice()
    assert pick is not None and pick[0] >> 4 == 11, pick      # piece 11 = open up only

    class _Pick(MD.MazeScreenDialog):
        def exec(self_):
            for i in range(self_.list.count()):
                if self_.list.item(i).data(Qt.UserRole)[:2] == (0x5C, 0):
                    self_.list.setCurrentRow(i)
            return QDialog.Accepted
    keep = MD.MazeScreenDialog
    MD.MazeScreenDialog = _Pick
    try:
        rt._maze_screen()
    finally:
        MD.MazeScreenDialog = keep
    app.processEvents()
    tiles, attr = MZ.MazeRom(s.renderer.rom).cell_grids(0x5C, 0)
    lid = rt.current_room()['screens']['0']['layout']['id']
    assert doc.layout(lid)['tiles'] == tiles and doc.layout(lid)['attr'] == attr
    # borrow a Library WALL metatile: the theme's wall slots are all vocabulary ->
    # the editor offers to release the unused vocabulary (S122), Yes -> borrowed
    rt.foreign_box.setCurrentIndex(rt.foreign_box.findData(0x12))
    app.processEvents()
    lib = [m for m in rt._vanilla_vocab(0x12)
           if m['tiles'][3] < s.renderer.vanilla_gfx(0x12).threshold][0]
    asked = []
    q_keep = RT.QMessageBox.question
    RT.QMessageBox.question = staticmethod(
        lambda *a, **k: (asked.append(a[2]), RT.QMessageBox.Yes)[1])
    try:
        rt._import_metatile(lib)
    finally:
        RT.QMessageBox.question = q_keep
    app.processEvents()
    room = rt.current_room()
    assert asked and 'Release' in asked[0], asked
    assert doc.released(doc.tileset_key(room)) and doc.gate_theme(room) == 4
    assert any(m.get('src') == 'borrowed' for m in doc.metatiles(doc.tileset_key(room)))
    td = TilesetDialog(doc, s.renderer, doc.room('dusk_mirror'), rt.canvas.pals, rt)
    td.rb_g.setChecked(True)
    td.g_box.setCurrentIndex(9)
    assert td.choice() == ('gate', 9, None) and td.theme_colours()
    while s.undo.index() > n0:
        s.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    hlp = open(os.path.join(REPO, 'editor2', 'help', '12_gate_themes.md')).read()
    for word in ('Gate theme', 'Maze screen', 'Borrow', 'Stairs down', '3-15'):
        assert word in hlp, f'help 12_gate_themes.md lacks "{word}"'
    print('OK: S122 — gate themes: New room on theme 4 (maze metatiles in the picker), the 16 '
          'themes in Borrow, the Maze screen dialog (254 screens, openings filter) stamping a '
          'screen, a Library wall borrowed after "release unused vocabulary", Change tileset -> '
          'a gate theme + colours; undo restores project.json')


def s123_worlds(app, w):
    """S123 (ROADMAP NG3; user: "a world that can have encounters, encounter-free rooms
    (where you can also save), mini-bosses, endbosses, flags and triggers. Enter via
    swirling portal, portal stops when boss beaten, OR portal is different colour"):
    the World tab's Worlds panel (New world with a new start room in a gate look, the
    swirl colour, the saving rule, a second room, the report), the Rooms tab's World
    entrance here…, an NPC's colour, Make boss… (end boss of the world), the Vanish step
    in the conversation dialog, the Gates tab showing the world locked; everything
    undoes to the original project.json."""
    from PySide6.QtWidgets import QDialog, QInputDialog, QMessageBox
    from editor2.app import world_tab as WT
    from editor2.app.rooms import boss_dialog as BD
    from editor2.app.rooms import conversation_dialog as CD
    s = w.session
    doc = s.doc
    before = doc.dumps()
    n0 = s.undo.index()
    wt = w.world_tab
    w.tabs.setCurrentWidget(wt)
    app.processEvents()
    wp = wt.worlds
    assert wp.list.count() == 0 and not wp.form_box.isEnabled()

    class _NW(WT.NewWorldDialog):
        def exec(self_):
            self_.name.setText('Fern World')
            self_.start.setCurrentIndex(0)          # a NEW start room
            self_.theme.setCurrentIndex(9)          # Forest
            return QDialog.Accepted
    keep = WT.NewWorldDialog
    WT.NewWorldDialog = _NW
    try:
        wp._new()
    finally:
        WT.NewWorldDialog = keep
    app.processEvents()
    gid = wp.current()
    assert gid == 32 and doc.world(gid)['start']['room'] == 'fern_world_start', doc.world(gid)
    assert doc.gate_theme(doc.room('fern_world_start')) == 9
    assert wp.rooms.rowCount() == 1 and 'portal' in wp.problems.text().lower()
    wp.swirl.setCurrentIndex(wp.swirl.findData(1))
    wp._swirl_changed(0)
    assert doc.gate_setting(gid).get('cleared_swirl') == 1
    wp.saving.setCurrentIndex(wp.saving.findData('everywhere'))
    wp._saving_changed(0)
    assert doc.world(gid)['saving'] == 'everywhere'
    keep_t, keep_i = QInputDialog.getText, QInputDialog.getItem
    QInputDialog.getText = staticmethod(lambda *a, **k: ('Fern cave', True))
    QInputDialog.getItem = staticmethod(lambda *a, **k: (a[3][1], True))   # gate theme 1
    try:
        wp._new_room()
    finally:
        QInputDialog.getText, QInputDialog.getItem = keep_t, keep_i
    app.processEvents()
    assert doc.world_rooms(gid) == ['fern_world_start', 'fern_cave'], doc.world_rooms(gid)
    assert wp.rooms.rowCount() == 2
    # the Gates tab: the world is listed and locked
    gt = w.gates_tab
    gt.refresh()
    row = next(i for i, g in enumerate(gt.gates) if g['id'] == gid)
    assert 'WORLD' in gt.list.item(row).text()
    gt.list.setCurrentRow(row)
    gt._show_gate(row)
    assert not any(b.isEnabled() for b in gt._world_boxes) and 'WORLD' in gt.head.text()
    # an ordinary gate: its swirl turns green once cleared (Gates tab), and back
    row1 = next(i for i, g in enumerate(gt.gates) if g['id'] == 1)
    gt.list.setCurrentRow(row1)
    gt._show_gate(row1)
    assert all(b.isEnabled() for b in gt._world_boxes)
    gt.set_swirl.setCurrentIndex(gt.set_swirl.findData(1))
    gt.set_swirl.activated.emit(gt.set_swirl.currentIndex())
    assert doc.gate_setting(1).get('cleared_swirl') == 1, doc.gate_setting(1)
    gt.list.setCurrentRow(row1)
    gt._show_gate(row1)
    assert gt.set_swirl.currentData() == 1
    gt.set_swirl.setCurrentIndex(0)
    gt.set_swirl.activated.emit(0)
    assert doc.gate_setting(1).get('cleared_swirl') is None
    # Rooms tab: the portal in the example's dusk_mirror, an NPC colour, Make boss
    rt = w.rooms_tab
    w.tabs.setCurrentWidget(rt)
    for i in range(rt.room_list.count()):
        if 'dusk_mirror' in rt.room_list.item(i).text() or 'Dusk' in rt.room_list.item(i).text():
            rt.room_list.setCurrentRow(i)
            break
    app.processEvents()
    assert rt.current_room() is not None and rt.current_room()['id'] == 'dusk_mirror'
    QInputDialog.getItem = staticmethod(lambda *a, **k: (a[3][0], True))
    try:
        rt._add_world_entrance((4, 2))
    finally:
        QInputDialog.getItem = keep_i
    app.processEvents()
    ents = doc.gate_entrances(gid)
    assert len(ents) == 1 and ents[0][0]['id'] == 'dusk_mirror' and doc.gate_swirls(gid)
    # an NPC in the cave: colour + Make boss (end boss)
    for i in range(rt.room_list.count()):
        if 'Fern cave' in rt.room_list.item(i).text():
            rt.room_list.setCurrentRow(i)
            break
    app.processEvents()
    cave = rt.current_room()
    assert cave['id'] == 'fern_cave'
    cmd = rt._npc_op('Add NPC', lambda d, r, k, st: d.add_npc(r, k, st, 5, 3, 0x08))
    idx = cmd.result                                  # a person (Make boss works on any NPC)
    rt._show()
    rt._sel_npc = idx
    rt._show_npc_panel(idx)
    panel = rt.npc_panel
    assert panel.colour.count() == 9 and panel.colour.isEnabled()
    rt._npc_colour(4)
    assert doc.npc_entries(doc.room('fern_cave'), 0, 0)[idx].get('colour') == 4

    class _MB(BD.MakeBossDialog):
        def exec(self_):
            self_.name.setText('fern lord')
            self_.end_boss.setChecked(True)
            return QDialog.Accepted
    keep = BD.MakeBossDialog
    BD.MakeBossDialog = _MB
    try:
        rt._npc_make_boss()
    finally:
        BD.MakeBossDialog = keep
    app.processEvents()
    e = doc.npc_entries(doc.room('fern_cave'), 0, 0)[idx]
    t = doc.conversation(e['script'])
    kinds = [list(st)[0] for st in t['steps']]
    assert kinds == ['say', 'battle', 'set', 'vanish', 'helper'], kinds
    assert t['steps'][2]['set'] == ['fern_lord_beaten', 'gate:32'], t['steps'][2]
    assert t['steps'][4]['helper']['dest'] == f"room:${int(doc.room('dusk_mirror')['mapID'], 16):02X}"
    assert e.get('shown_when') == [{'flag': 'fern_lord_beaten', 'is': 'clear'}]
    assert e.get('colour') == 4, 'Make boss keeps the colour (update_npc carries it)'
    # the Vanish step in the conversation dialog
    from PySide6.QtGui import QAction
    dlg = CD.ConversationDialog(doc, rom=s.renderer.rom, room=doc.room('fern_cave'), key=0,
                                spec=doc.conversation_spec(e['script']), parent=rt)
    assert any(a.text().startswith('Vanish') for a in dlg.findChildren(QAction)), \
        'no Vanish in + Add step'
    dlg.add_step('vanish')
    app.processEvents()
    assert any('vanish' in st for st in dlg.spec()['steps'])
    dlg.reject()
    # the World tab report now: the end boss clears it, the portal exists
    w.tabs.setCurrentWidget(wt)
    wp.refresh()
    app.processEvents()
    assert 'END boss' in ' '.join(wp.rooms.item(r, 3).text() for r in range(wp.rooms.rowCount()))
    assert 'portal' not in wp.problems.text().lower(), wp.problems.text()
    wt.only_world.setChecked(True)
    app.processEvents()
    keys = set(wt.nodes)
    assert ('room', 'fern_world_start') in keys and ('room', 'fern_cave') in keys and \
        ('room', 'dusk_mirror') in keys and ('room', 'gate_rotation') not in keys, keys
    wt.only_world.setChecked(False)
    # S123 r3 (user: "SHOW VISUALLY … where it lands player INSIDE new world"): the
    # way in as pictures; a portal added by clicking a cell; the landing changed by a
    # click; Go to opens the cell; the Rooms canvas marks the portal + the landing
    wp.refresh()
    app.processEvents()
    assert wp.land_pic.pixmap() is not None and not wp.land_pic.pixmap().isNull()
    assert wp.portal_pic.pixmap() is not None and not wp.portal_pic.pixmap().isNull()
    assert len(wp._portals) == 1 and wp._portals[0][:5] == ('room', 'dusk_mirror', 0, 4, 2), \
        wp._portals
    assert 'dusk' in wp.portal_lbl.text().lower() or 'Dusk' in wp.portal_lbl.text()

    class _PD(WT.PortalDialog):
        def exec(self_):
            i = self_.room.findData('gate_rotation')
            self_.room.setCurrentIndex(i)
            assert self_.picker.pic.img is not None, 'the portal room is drawn'
            self_.picker._clicked(3, 3)                 # a click on the picture
            return QDialog.Accepted
    keep_pd = WT.PortalDialog
    WT.PortalDialog = _PD
    try:
        wp._add_portal()
    finally:
        WT.PortalDialog = keep_pd
    app.processEvents()
    assert ('room', 'gate_rotation', 0, 3, 3) in [c[:5] for c in doc.world_portals(gid)], \
        doc.world_portals(gid)
    assert '2 of 2' in wp.portal_lbl.text() or '1 of 2' in wp.portal_lbl.text()
    keep_q = QMessageBox.question
    QMessageBox.question = staticmethod(lambda *a, **k: QMessageBox.Yes)
    try:
        wp._portal_i = [c[:5] for c in wp._portals].index(('room', 'gate_rotation', 0, 3, 3))
        wp._remove_portal()
    finally:
        QMessageBox.question = keep_q
    assert ('room', 'gate_rotation', 0, 3, 3) not in [c[:5] for c in doc.world_portals(gid)]

    class _SD(WT.StartDialog):
        def exec(self_):
            assert self_.picker.pic.img is not None, 'the start room is drawn'
            self_.picker._clicked(6, 2)
            return QDialog.Accepted
    keep_sd = WT.StartDialog
    WT.StartDialog = _SD
    try:
        wp._change_start()
    finally:
        WT.StartDialog = keep_sd
    st0 = doc.world(gid)['start']
    assert (st0['room'], st0['x'], st0['y']) == ('fern_world_start', 6, 2), st0
    got = []
    wt.openRequested.connect(lambda k: got.append(k))
    wp._go_land()
    wp._go_portal()
    assert got[0] == ('room', 'fern_world_start', 0, 6, 2) and got[1][0] == 'room', got
    w.tabs.setCurrentWidget(rt)
    rt.open_node(got[0])
    app.processEvents()
    assert rt.current_room()['id'] == 'fern_world_start' and rt.canvas.selected_cell == (6, 2)
    assert any(m[0] == 'world_land' and (m[1], m[2]) == (6, 2) for m in rt.canvas.markers), \
        [m[:3] for m in rt.canvas.markers]
    rt._move_marker(('world_land', gid, st0), 5, 5)            # drag the landing
    assert (doc.world(gid)['start']['x'], doc.world(gid)['start']['y']) == (5, 5)
    rt.open_node(('room', 'dusk_mirror', 0, 4, 2))
    app.processEvents()
    assert any(m[0] == 'portal' and (m[1], m[2]) == (4, 2) for m in rt.canvas.markers)
    w.tabs.setCurrentWidget(wt)
    # flag pickers name the world's cleared flag
    from editor2.app.rooms.rules_panel import well_known
    assert ('gate:32', 'world cleared — Fern World (gate 32)') in well_known(doc)
    while s.undo.index() > n0:
        s.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    wp.refresh()
    hlp = open(os.path.join(REPO, 'editor2', 'help', '65_worlds.md')).read()
    for word in ('New world', 'World entrance here', 'Make boss', 'Vanish', 'green', 'JOURNAL',
                 'Castle'):
        assert word in hlp, f'help 65_worlds.md lacks "{word}"'
    print('OK: S123 — worlds: New world (a new Forest start room), swirl turns green, saving '
          'everywhere, a second room, the Gates tab locks it, World entrance here…, an NPC '
          'colour, Make boss (end boss: own flag + gate:32 + Vanish + helper to the portal), '
          'the Vanish step, the report and "only this world"; undo restores project.json')


def s125_hub(app, w):
    """S125 (ROADMAP P3.14d; user: "Make a single room be HUB but … transferrable upon
    flag"): the World tab's Hub box — a rule to the example's gate_island, a rule to the
    Castle once a flag is ON (kept before the unconditional one), the order, Add the
    arrival scenes; the H marker on the Rooms canvas; the cutscene editor's Arrival home
    menu, the Heal step, "home" as a move destination; the conversation dialog's Home
    destination; the Flags tab's way to a hub rule; everything undoes."""
    from PySide6.QtWidgets import QDialog, QMessageBox
    from editor2.app import world_tab as WT
    from editor2.app.cutscene_editor import room_items
    from editor2.app.rooms import conversation_dialog as CVD
    from editor2.app.rooms import commands as C
    from editor2.core import cutscene_doc as CD
    s = w.session
    doc = s.doc
    before = doc.dumps()
    n0 = s.undo.index()
    wt = w.world_tab
    w.tabs.setCurrentWidget(wt)
    app.processEvents()
    hb = wt.worlds.hub
    hb.refresh()
    assert hb.list.count() == 1 and 'Castle' in hb.list.item(0).text(), hb.list.item(0).text()
    s.undo.push(C.SnapshotCommand(s, 'flag', lambda d: d.add_flag('post_game')))
    plan = [('gate_island', [], (0, 4, 4)), ('castle', [{'flag': 'post_game'}], None)]

    class _RD(WT.HubRuleDialog):
        def exec(self_):
            rid, terms, cell = plan.pop(0)
            self_.room.setCurrentIndex(self_.room.findData(rid))
            for t in terms:
                self_.terms._add(t)
            if cell:
                assert self_.picker.pic.img is not None, 'the room is drawn'
                self_.picker._clicked(cell[1], cell[2])
            return QDialog.Accepted
    keep = WT.HubRuleDialog
    WT.HubRuleDialog = _RD
    try:
        hb._add()
        hb._add()
    finally:
        WT.HubRuleDialog = keep
    rules = doc.hub_rules()
    assert [r['room'] for r in rules] == ['castle', 'gate_island'], rules
    assert rules[0]['when'] == [{'flag': 'post_game'}] and (rules[1]['x'], rules[1]['y']) == (4, 4)
    assert hb.list.count() == 2 and 'post_game is ON' in hb.list.item(0).text()
    hb.list.setCurrentRow(1)
    hb._move(-1)                                    # the unconditional rule first: a problem
    assert 'never applies' in hb.problems.text(), hb.problems.text()
    hb._move(1)
    assert not hb.problems.isVisible() or not hb.problems.text()
    keep_i = QMessageBox.information
    QMessageBox.information = staticmethod(lambda *a, **k: None)
    try:
        hb.list.setCurrentRow(1)
        hb._arrivals()
    finally:
        QMessageBox.information = keep_i
    arr = doc.hub_arrival_scenes('gate_island')
    assert [a[2] for a in arr] == [['lost', 'wiped', 'final_lost'], ['warpwing'], ['home']], arr
    # the Rooms canvas marks the hub cell
    rt = w.rooms_tab
    w.tabs.setCurrentWidget(rt)
    rt.open_node(('room', 'gate_island', 0, 4, 4))
    app.processEvents()
    assert any(m[0] == 'hub' and (m[1], m[2]) == (4, 4) for m in rt.canvas.markers), \
        [m[:3] for m in rt.canvas.markers]
    # the cutscene editor: Arrival home, Heal, a move home
    ct = w.cutscenes_tab
    w.tabs.setCurrentWidget(ct)
    ct.open_cutscene('gate_island', arr[1][0])
    app.processEvents()
    ed = ct.editor
    assert ed.arr_btn.isVisibleTo(ed) and 'WarpWing' in ed.arr_btn.text(), ed.arr_btn.text()
    ed._toggle_arrival('home', True)
    app.processEvents()
    assert CD.find(doc, arr[1][0])[1]['trigger']['arrival'] == ['warpwing', 'home']
    ed._toggle_arrival('home', False)
    ed.add_step('heal')
    ed.add_step('move', {'move': {'dest': 'hub'}})
    app.processEvents()
    steps = CD.find(doc, arr[1][0])[1]['steps']
    assert {'heal': {}} in steps and {'move': {'dest': 'hub'}} == steps[-1], steps
    assert room_items(s)[0] == ('home — the hub (World tab)', 'hub')
    errs, _warns, _lw = CD.problems(doc, doc.room('gate_island'), CD.find(doc, arr[1][0])[1])
    assert not errs, errs
    # the conversation dialog: Home as a destination
    mv = {'dest': 'vanilla:$00', 'screen': 1, 'x': 4, 'y': 5}
    de = CVD.DestEditor(doc, mv, lambda: None)
    de.room.setCurrentIndex(de.room.findData('hub'))
    de._changed()
    assert mv == {'dest': 'hub'} and not de.sp['x'].isEnabled(), mv
    assert CVD.new_step('heal', doc, None, 0) == {'heal': {}}
    # the Flags tab's link to a hub rule
    w.navigate_to({'tab': 'worlds', 'hub': 0})
    app.processEvents()
    assert w.tabs.currentWidget() is wt and hb.list.currentRow() == 0
    while s.undo.index() > n0:
        s.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    hb.refresh()
    hlp = open(os.path.join(REPO, 'editor2', 'help', '66_hub.md')).read()
    for word in ('Add rule', 'arrival scenes', 'Arrival home', 'Heal', 'WarpWing', 'Castle',
                 'half the gold'):
        assert word in hlp, f'help 66_hub.md lacks "{word}"'
    print('OK: S125 — the hub: rules (a room, the Castle once a flag is ON) in order, the '
          'order problem, Add the arrival scenes, the H marker, Arrival home / Heal / move '
          'home in the cutscene editor, Home in conversations, the Flags tab link; undo '
          'restores project.json')


def s124_progression(app, w):
    """S124 (ROADMAP P3.14a): the Progression & Flags tab — every flag with what turns
    it ON / OFF and what checks it (with links to the place), New flag (a fixed
    number, never $0158), a note, Rename (every use follows), Renumber, Delete,
    the Triggers page (a double-click opens the place), the Problems page; every
    edit undoes to the original project.json."""
    from PySide6.QtWidgets import QInputDialog, QMessageBox
    s = w.session
    doc = s.doc
    before = doc.dumps()
    n0 = s.undo.index()
    pt = w.progression_tab
    w.tabs.setCurrentWidget(pt)
    app.processEvents()
    pt.refresh()
    tops = [pt.tree.topLevelItem(i).text(0) for i in range(pt.tree.topLevelItemCount())]
    assert tops[0].startswith('Your flags') and any(t.startswith('The original game') for t in tops), tops
    # S128 r2: the example's quest flag is no longer on $0158 (the game's) — no problem
    vg = doc.flag_numbers()['vault_guardian_beaten']
    assert vg == 0x015A and not any(p.code == 'game_shares' for p in pt.problems)
    pt.select_flag(vg)
    assert 'vault_guardian_beaten' in pt.title.text()
    assert 'Turned ON by' in pt.detail.toPlainText() and pt.b_renumber.isEnabled()
    keep_t, keep_q = QInputDialog.getText, QMessageBox.question
    QInputDialog.getText = staticmethod(lambda *a, **k: ('Bridge repaired', True))
    QMessageBox.question = staticmethod(lambda *a, **k: QMessageBox.Yes)
    try:
        pt._new_flag()
        n = doc.flag_numbers()['bridge_repaired']
        assert n != 0x0158 and str(doc.flag_entry('bridge_repaired')['index']).startswith('0x')
        assert pt.cur == n and 'bridge_repaired' in pt.title.text()
        pt.note.setText('The east bridge can be crossed')
        pt._note_done()
        app.processEvents()
        assert doc.flag_entry('bridge_repaired').get('comment') == 'The east bridge can be crossed'
        # rename a used flag (the quest's): every use follows, the number stays
        pt.select_flag(vg)
        QInputDialog.getText = staticmethod(lambda *a, **k: ('Vault guard beaten', True))
        pt._rename()
        q = doc.data['progression']['quests'][0]
        assert q['flags']['done'] == 'vault_guard_beaten', q['flags']
        assert doc.flag_numbers()['vault_guard_beaten'] == 0x015A
        pt._renumber()
        assert doc.flag_numbers()['vault_guard_beaten'] not in (0x0158, 0x015A, n)
        assert not any(p.code == 'game_shares' and p.idx == 0x0158 for p in pt.problems)
        # delete: refused while used, allowed when unused
        keep_i = QMessageBox.information
        QMessageBox.information = staticmethod(lambda *a, **k: QMessageBox.Ok)
        try:
            pt._delete()
            assert doc.flag_entry('vault_guard_beaten') is not None
        finally:
            QMessageBox.information = keep_i
        pt.select_flag(n)
        pt._delete()
        assert all(f.get('name') != 'bridge_repaired' for f in doc.flags())
    finally:
        QInputDialog.getText, QMessageBox.question = keep_t, keep_q
    # the Triggers page: sentences grouped by place; a double-click SHOWS the place in
    # the side panel (S124 r3), its Open button goes to the room
    pt.pages.setCurrentIndex(1)
    app.processEvents()
    assert pt.t_tree.topLevelItemCount() > 0
    g = pt.t_tree.topLevelItem(0)
    it = g.child(0)
    assert it.text(0).startswith('When ') and '→' in it.text(0), it.text(0)
    nav = it.data(0, 0x0100)
    pt._trigger_go(it, 0)
    app.processEvents()
    assert w.tabs.currentWidget() is pt and not pt.place_panel.isHidden()
    if nav and nav.get('tab') == 'rooms':
        pt.place_panel._open()
        app.processEvents()
        assert w.tabs.currentWidget() is w.rooms_tab and w.rooms_tab.room_id == nav['room']
    s124r3_places(app, w, pt)
    # undo -> the original project
    s.undo.setIndex(n0)
    app.processEvents()
    assert doc.dumps() == before, 'S124 edits did not undo to the original project'
    w.tabs.setCurrentWidget(pt)
    pt.refresh()
    print(f'OK: S124 Progression & Flags — {len(pt.fi.flags)} flags, {len(pt.fi.triggers)} '
          'triggers, new / note / rename / renumber / delete, Triggers → the room, undo')


def s124r3_places(app, w, pt):
    """S124 r3 (user: "show the specific NPC in the specific room … rather than moving
    to a totally different tab"; "allow naming all NPCs … carry that through";
    "You dont actually show the correct NPC"): game flag $0080 (talked to Santi) —
    "show" opens the side panel at GreatTree screen 8 / screen 12 IN THE RIGHT STATE
    with the NPC outlined; Name… names a game room's NPC (editor data), the name
    carries to the flag's sentences, the Rooms tab canvas and its NPC panel; Open
    lands the Rooms tab on that screen, state and NPC."""
    from PySide6.QtWidgets import QInputDialog
    s = w.session
    doc = s.doc
    if pt.catalogue() is None:
        print('SKIP: S124 r3 places (no ROM)')
        return
    w.tabs.setCurrentWidget(pt)
    pt.pages.setCurrentIndex(0)
    pt.show_box.setCurrentIndex(pt.show_box.findData(2))      # every game flag
    app.processEvents()
    pt.refresh()
    pt.select_flag(0x0080)
    key = next(k for k, (pl, _v) in pt._navs.items()
               if any(p.get('map') == 1 and p.get('screen') == 12 for p in pl))
    from PySide6.QtCore import QUrl
    pt._anchor(QUrl(f'go:{key}'))
    app.processEvents()
    pp = pt.place_panel
    assert w.tabs.currentWidget() is pt and not pp.isHidden()
    p = pp.place()
    assert (p['map'], p['screen'], p['state'], p['x'], p['y'], p['n']) == (1, 12, 1, 1, 6, 1), p
    assert pp.state == 1 and pp.sel_n == 1
    assert any(r[0] == 1 and (r[2], r[3]) == (1, 6) for r in pp.rows), pp.rows
    assert 'GreatTree' in pp.head.text() and 'screen 12' in pp.head.text()
    # state 0 of screen 12: Santi is NOT there (the bug the user saw: state 0 only)
    pp.state_box.setCurrentIndex(0)
    app.processEvents()
    assert not any((r[2], r[3]) == (1, 6) and r[0] is not None for r in pp.rows)
    pp.state_box.setCurrentIndex(1)
    app.processEvents()
    pp.sel_n = 1
    from PySide6.QtWidgets import QMessageBox

    def _fail(*a, **k):
        raise AssertionError(f'Name this NPC refused: {a[2] if len(a) > 2 else a}')
    keep, keep_w = QInputDialog.getText, QMessageBox.warning
    QInputDialog.getText = staticmethod(lambda *a, **k: ('Santi', True))
    QMessageBox.warning = staticmethod(_fail)
    try:
        pp._name()
    finally:
        QInputDialog.getText, QMessageBox.warning = keep, keep_w
    app.processEvents()
    names = doc.data['custom']['_editor']['npc_names']
    assert names.get('01:12:1:1') == 'Santi' and names.get('01:12:2:1') == 'Santi', names
    pt.refresh()
    pt.select_flag(0x0080)
    assert 'talking to Santi at (1, 6)' in pt.detail.toPlainText()
    assert any(r[5] == 'Santi' for r in pp.rows)
    # Open → the Rooms tab at GreatTree screen 12 state 1 with Santi selected and named
    pp._open()
    app.processEvents()
    rt = w.rooms_tab
    assert w.tabs.currentWidget() is rt
    assert (rt.vanilla_mid, rt.key, rt.state_idx) == (1, 12, 1), (rt.vanilla_mid, rt.key, rt.state_idx)
    ref = rt.canvas.selected_marker
    assert ref is not None and rt.canvas.npc_tags.get(id(ref)) == 'Santi'
    assert 'Santi' in rt.npc_panel.name_lbl.text()
    # the father in the Old Man Gate Room ($0D) checks it: the panel shows him there
    pt.select_flag(0x0080)
    key = next(k for k, (pl, _v) in pt._navs.items()
               if any(p.get('map') == 13 for p in pl))
    pt._anchor(QUrl(f'go:{key}'))
    app.processEvents()
    p = pp.place()
    assert (p['map'], p['x'], p['y']) == (13, 3, 5) and any(
        r[0] == p['n'] and (r[2], r[3]) == (3, 5) for r in pp.rows)
    pt.show_box.setCurrentIndex(0)
    print('OK: S124 r3 the place panel — $0080: GreatTree screen 12 state 1 at (1, 6), '
          'named Santi (game room, editor data) → the sentences, the canvas, the NPC '
          'panel; Open → that screen / state / NPC; the Old Man Gate Room (3, 5)')


def s126_services(app, w):
    """S126 (ROADMAP P3.14e1): Rooms tab → NPC → Service… makes an NPC a service
    NPC (here the farm keeper with a new line set and a first visit remembered
    by a new flag); the Services tab lists it (Go to opens it), edits the line
    set (speaker, a line with the box preview, the game's words back) and the
    Medal Man's rewards; the project compiles; every edit undoes to the
    original project.json."""
    from PySide6 import QtWidgets as QW
    import editor2.app.rooms.service_dialog as SDm
    import editor2.app.services_tab as SVm
    s = w.session
    doc = s.doc
    before = doc.dumps()
    n0 = s.undo.index()
    rt = w.rooms_tab
    w.tabs.setCurrentWidget(rt)
    rt.open_node(('room', 'dusk_mirror'))
    app.processEvents()
    cmd = rt._npc_op('Add NPC', lambda d, r, k, st: d.add_npc(r, k, st, 6, 4, 0x06))
    idx = cmd.result
    rt._after_npc_edit(idx)
    app.processEvents()
    assert rt.npc_panel.btn_service.isEnabled()
    d_exec = SDm.ServiceDialog.exec
    k_text = SDm.QInputDialog.getText

    def _farm(dlg):
        for i in range(dlg.kinds.count()):
            if dlg.kinds.item(i).data(256) == 'farm':
                dlg.kinds.setCurrentRow(i)
        dlg.lines.setCurrentIndex(dlg.lines.findData(SDm.NEW_SET))
        dlg.first.setChecked(True)
        dlg.first_text.set_value([['Hi! I keep the', 'farm up here.']])
        dlg.flag.setText('mira_met')
        dlg._ok()
        return QW.QDialog.Accepted
    SDm.ServiceDialog.exec = _farm
    SDm.QInputDialog.getText = staticmethod(lambda *a, **k: ("Mira's lines", True))
    try:
        rt._npc_service()
    finally:
        SDm.ServiceDialog.exec = d_exec
        SDm.QInputDialog.getText = k_text
    app.processEvents()
    room = doc.room('dusk_mirror')
    sv = doc.service_of(room, rt.key, rt.state_idx, idx)
    assert sv['kind'] == 'farm' and sv['lines'] == 'mira_s_lines', sv
    assert sv['first_time']['boxes'] == [['Hi! I keep the', 'farm up here.']], sv
    assert any(f.get('name') == 'mira_met' for f in doc.flags()), 'first-visit flag not made'
    assert 'Farm keeper' in rt.npc_panel.talk_preview.text(), rt.npc_panel.talk_preview.text()
    # the flag's uses show on the Progression & Flags tab
    from editor2.core import flag_index as FI
    fx = FI.FlagIndex(doc.data, REPO)
    num = doc.flag_numbers()['mira_met']
    roles = sorted(u.role for u in fx.uses if u.idx == num)
    assert roles == ['on', 'test'] and all(u.kind == 'service' for u in fx.uses
                                           if u.idx == num), roles
    # the Services tab
    vt = w.services_tab
    w.tabs.setCurrentWidget(vt)
    vt.refresh()
    app.processEvents()
    assert vt.npcs.rowCount() == 1 and vt.npcs.item(0, 3).text() == 'Farm keeper', \
        [vt.npcs.item(0, c).text() for c in range(5)]
    got = []
    vt.navigate.connect(got.append)
    vt.npcs.setCurrentCell(0, 0)
    vt._goto()
    assert got and got[-1]['room'] == 'dusk_mirror' and (got[-1]['x'], got[-1]['y']) == (6, 4), got
    vt.pages.setCurrentIndex(1)
    assert vt.current_set_id() == 'mira_s_lines' and vt.lines.rowCount() == 39
    vt.set_speaker.setText('Mira')
    vt.set_speaker.editingFinished.emit()
    app.processEvents()
    assert doc._line_set('mira_s_lines')['speaker'] == 'Mira'
    vt.lines.setCurrentCell(0, 0)
    app.processEvents()
    assert vt.line_edit.toPlainText().startswith('Hey there!'), vt.line_edit.toPlainText()
    vt.line_edit.setPlainText('Howdy! What\ndo you need?')
    app.processEvents()
    assert vt.line_probs.text() == '' and vt.preview_v.count() == 2   # one box + stretch
    vt._apply_line()
    app.processEvents()
    assert doc._line_set('mira_s_lines')['lines'] == {'0': 'Howdy! What\ndo you need?'}
    assert vt.lines.item(0, 2).text().startswith('Howdy!')
    vt.line_edit.setPlainText('This line is far too long for one box line')
    app.processEvents()
    assert 'cells' in vt.line_probs.text(), vt.line_probs.text()
    vt._line_game()                                        # the game's words again
    app.processEvents()
    assert doc._line_set('mira_s_lines').get('lines') == {}, doc._line_set('mira_s_lines')
    vt.lines.setCurrentCell(0, 0)
    vt._show_line(0)
    vt.line_edit.setPlainText('Howdy! What\ndo you need?')
    vt._apply_line()
    app.processEvents()
    # the Medal Man
    vt.pages.setCurrentIndex(2)
    assert vt.medals.rowCount() == 4 and 'game' in vt.medals_state.text()
    vt.medals.item(0, 0).setText('3')
    app.processEvents()
    rw = doc.data['gamedata']['medals']['rewards']
    assert [r['medals'] for r in rw] == [3, 18, 25, 30], rw
    warned = []
    k_w = SVm.QMessageBox.warning
    SVm.QMessageBox.warning = staticmethod(lambda *a, **k: warned.append(a[2]))
    vt.medals.item(1, 0).setText('2')                       # not rising: refused
    app.processEvents()
    SVm.QMessageBox.warning = k_w
    assert warned and 'more medals' in warned[0], warned
    assert [r['medals'] for r in doc.data['gamedata']['medals']['rewards']] == [3, 18, 25, 30]
    vt._medal_add()
    app.processEvents()
    assert vt.medals.rowCount() == 5 and doc.data['gamedata']['medals']['rewards'][-1]['medals'] == 35
    cb = vt.medals.cellWidget(4, 1)
    cb.setCurrentIndex(cb.findData(336))
    app.processEvents()
    assert doc.data['gamedata']['medals']['rewards'][-1]['enemy'] == 336
    vt.medals.item(4, 2).setText("A gift ⏎ for you!")
    app.processEvents()
    assert doc.data['gamedata']['medals']['rewards'][-1]['line'] == 'A gift\nfor you!'
    # reward 5 speaks block line +7, which ends with a line break: its last box holds one
    assert 'reward 5' in vt.medal_probs.text() and 'holds 1' in vt.medal_probs.text(), \
        vt.medal_probs.text()
    vt.medals.item(4, 2).setText("A gift for you!")
    app.processEvents()
    assert doc.data['gamedata']['medals']['rewards'][-1]['line'] == 'A gift for you!' \
        and vt.medal_probs.text() == '', vt.medal_probs.text()
    # the edits compile (service script, line set, medal table)
    import shutil as _sh
    import tempfile
    from editor2.core import compiler as Cc
    td = tempfile.mkdtemp()
    _sh.copytree(doc.project_dir, os.path.join(td, 'p'), ignore=_sh.ignore_patterns('build'))
    open(os.path.join(td, 'p', 'project.json'), 'w').write(doc.dumps())
    outs, _pp, _ww = Cc.compile_project(os.path.join(td, 'p'), REPO)
    assert 'SERVICE_SET_COUNT EQU 1' in outs['patches/bank_077.asm']
    assert 'MEDAL_REWARD_COUNT EQU 5' in outs['patches/bank_012.asm']
    _sh.rmtree(td, ignore_errors=True)
    vt._medal_reset()
    app.processEvents()
    assert 'medals' not in (doc.data.get('gamedata') or {})
    k_q = SVm.QMessageBox.question
    SVm.QMessageBox.question = staticmethod(lambda *a, **k: SVm.QMessageBox.Yes)
    vt.pages.setCurrentIndex(1)
    vt._delete_set()
    SVm.QMessageBox.question = k_q
    app.processEvents()
    assert doc.service_line_sets() == [] and \
        doc.service_of(doc.room('dusk_mirror'), rt.key, rt.state_idx, idx).get('lines') is None
    while s.undo.index() > n0:
        s.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'S126 service edits did not undo to the original'
    print('OK: S126 Services — Service… (farm keeper, new line set, first visit + flag), '
          'the Services tab (NPC list + Go to, speaker, a line with preview / problems / the '
          "game's words, Medal Man rewards add / egg / line / refused / reset), compiles, "
          'undoes to the original')


def s127r3_game_text_rule(app, w):
    """S127 r3 (user: "Use game text box previews. FOr the love of god make that default
    for all text entries in editor this is like the fifth time this comes up"): no plain
    text edit in the app becomes game text — every QPlainTextEdit is a log / read-only
    view, the box editor's own field or the Services tab's line editor (which draws its
    boxes beside it). A new one fails here until it is a GameTextField / BoxList."""
    import re as _re
    allowed = {('app/main.py', 'self.log'), ('app/cutscenes_tab.py', 'self.log'),
               ('app/cutscenes_tab.py', 'self.textbox'), ('app/dialogue_tab.py', 'self.detail'),
               ('app/services_tab.py', 'self.line_edit'),
               ('app/rooms/talk_editor.py', 'self.edit')}
    found = []
    base = os.path.join(REPO, 'editor2')
    for sub in ('app', 'app/rooms'):
        for fn in sorted(os.listdir(os.path.join(base, sub))):
            if not fn.endswith('.py'):
                continue
            rel = f'{sub}/{fn}'
            for ln in open(os.path.join(base, sub, fn), encoding='utf-8'):
                m = _re.search(r'([\w.]+)\s*=\s*QPlainTextEdit\(', ln)
                if m:
                    found.append((rel, m.group(1)))
    bad = [f for f in found if f not in allowed]
    assert not bad, f'plain text edits that may become game text (use GameTextField): {bad}'
    # the Services tab's line editor draws the boxes; a medal reward shows its boxes too
    vt = w.services_tab
    vt.refresh()
    vt.pages.setCurrentIndex(2)
    app.processEvents()
    vt._medal_preview(0)
    from PySide6.QtWidgets import QLabel as _QL
    pics = [x for x in vt.medal_prev.findChildren(_QL) if x.pixmap() is not None and
            not x.pixmap().isNull()]
    assert pics, 'the medal reward has no game box preview'
    # S127 r4 (user: "Why is first visit greyed out? Also why is box1 duplicated weirdly
    # glitchily?"): a breeder has a first visit; a filled field holds exactly its boxes
    import editor2.app.rooms.service_dialog as SDm
    from editor2.app.rooms.talk_editor import BoxEditor as _BE
    dlg = SDm.ServiceDialog(w.session.doc, {'kind': 'breeder',
                                            'first_time': {'boxes': [['First time here?']],
                                                           'flag': 'brd_met'},
                                            'breeder': {'mate': 306, 'intro': [['Yo!']]}})
    dlg.show()
    app.processEvents()
    assert dlg.first.isEnabled() and dlg.first.isChecked() and dlg.first_text.isVisible()
    for fld in (dlg.first_text, dlg.brd_intro, dlg.brd_notyet, dlg.brd_after):
        kids = [x for x in fld.holder.findChildren(_BE) if x.parent() is not None]
        assert len(kids) == len(fld.editors) == 1, (len(kids), len(fld.editors))
    dlg.first.setChecked(False)
    app.processEvents()
    assert not dlg.first_text.isVisible()
    dlg.close()
    print(f'OK: S127 r3 game text rule — {len(found)} QPlainTextEdit(s), all logs / views / the '
          'box editor / the line editor; the Service… / Shopkeeper texts are box editors; a '
          'medal reward previews its boxes')


def s127_breeding(app, w):
    """S127 (ROADMAP P3.14e2): the Services tab → Breeding pools (New, the scales, bands
    in the table + Apply, Try it = the band nearest a player, a refused band), Rooms tab
    → NPC → Service… → Breeder (rolled from the pool, offers only when a flag holds,
    done flag + once) and → Grandpa; the Gates tab's rule dialog: every gate + the
    chance by the party's level; the project compiles (bank $77 pool data, the room's
    return script, GATE_ANY + ScaledChanceTable); every edit undoes to the original."""
    from PySide6 import QtWidgets as QW
    import editor2.app.rooms.service_dialog as SDm
    import editor2.app.services_tab as SVm
    import editor2.app.gates_tab as GTm
    s = w.session
    doc = s.doc
    before = doc.dumps()
    n0 = s.undo.index()
    vt = w.services_tab
    w.tabs.setCurrentWidget(vt)
    vt.refresh()
    vt.pages.setCurrentIndex(3)
    k_text = SVm.QInputDialog.getText
    SVm.QInputDialog.getText = staticmethod(lambda *a, **k: ('Wild mates', True))
    try:
        vt._new_pool()
    finally:
        SVm.QInputDialog.getText = k_text
    app.processEvents()
    assert vt.current_pool_id() == 'wild_mates' and vt.bands.rowCount() == 1
    vt.pool_scales['arena'].setChecked(True)
    app.processEvents()
    assert doc._pool('wild_mates')['measures'] == ['level', 'arena']
    vt._band_add()
    for c, val in enumerate(['late', '35', '4', '0', '0', '310, 313×3']):
        vt.bands.item(1, c).setText(val)
    vt._bands_apply()
    app.processEvents()
    b = doc._pool('wild_mates')['bands']
    assert len(b) == 2 and b[1]['mates'] == [{'enemy': 310}, {'enemy': 313, 'weight': 3}], b
    vt.try_spins['level'].setValue(30)
    vt.try_spins['arena'].setValue(3)
    app.processEvents()
    assert 'band 2 "late"' in vt.try_out.text() and '75 %' in vt.try_out.text(), vt.try_out.text()
    vt.try_spins['level'].setValue(8)
    vt.try_spins['arena'].setValue(0)
    assert 'band 1' in vt.try_out.text(), vt.try_out.text()
    warned = []
    k_w = SVm.QMessageBox.warning
    SVm.QMessageBox.warning = staticmethod(lambda *a, **k: warned.append(a[2]))
    vt.bands.item(0, 1).setText('150')                       # level 150: refused
    vt._bands_apply()
    SVm.QMessageBox.warning = k_w
    app.processEvents()
    assert warned and '0-99' in warned[0], warned
    assert doc._pool('wild_mates')['bands'][0]['level'] == 10
    # Rooms tab: a random breeder + a Grandpa
    rt = w.rooms_tab
    w.tabs.setCurrentWidget(rt)
    rt.open_node(('room', 'dusk_mirror'))
    app.processEvents()
    made = []
    for x in (6, 7, 8):
        cmd = rt._npc_op('Add NPC', lambda d, r, k, st, x=x: d.add_npc(r, k, st, x, 4, 0x08))
        made.append(cmd.result)
    d_exec = SDm.ServiceDialog.exec

    def pick(dlg, kind):
        for i in range(dlg.kinds.count()):
            if dlg.kinds.item(i).data(256) == kind:
                dlg.kinds.setCurrentRow(i)

    def _breeder(dlg):
        pick(dlg, 'breeder')
        assert dlg.brd.isVisibleTo(dlg) or not dlg.isVisible()
        dlg.brd_pool.setChecked(True)
        dlg.brd_pools.setCurrentIndex(dlg.brd_pools.findData('wild_mates'))
        dlg.brd_intro.set_value([['Fancy a match?']])
        dlg.brd_when.setText('saw_ruins')
        dlg.brd_after.set_value([['Come back', 'another time!']])
        dlg._ok()
        return QW.QDialog.Accepted

    def _grandpa(dlg):
        pick(dlg, 'grandpa')
        dlg._ok()
        return QW.QDialog.Accepted

    def _breeder_lv(dlg):                 # S127 r2: a species at a level; long words
        pick(dlg, 'breeder')
        assert dlg.brd_level_rb.isChecked()                  # the default for a new breeder
        dlg.brd_species.setCurrentIndex(dlg.brd_species.findData(47))
        dlg.brd_level.setValue(25)
        dlg.brd_flag.setText('lv_bred')
        dlg.brd_once.setChecked(True)
        dlg.brd_after.set_value([['THanks for breeding with me!']])
        assert dlg.brd_after.problem() and 'Fit' in dlg.brd_after.problem()
        dlg.brd_after._fit_all()                 # S127 r3: the box editor wraps it
        assert dlg.brd_after.problem() is None, dlg.brd_after.boxes()
        dlg._ok()
        return QW.QDialog.Accepted
    try:
        for idx, fn in zip(made, (_breeder, _grandpa, _breeder_lv)):
            rt._after_npc_edit(idx)
            SDm.ServiceDialog.exec = fn
            rt._npc_service()
            app.processEvents()
    finally:
        SDm.ServiceDialog.exec = d_exec
    room = doc.room('dusk_mirror')
    sv = doc.service_of(room, rt.key, rt.state_idx, made[0])
    assert sv['kind'] == 'breeder' and sv['breeder']['pool'] == 'wild_mates' and \
        sv['breeder']['when'] == [{'flag': 'saw_ruins', 'is': 'set'}] and \
        sv['breeder']['intro'] == [['Fancy a match?']] and \
        sv['breeder']['after'] == [['Come back', 'another time!']], sv
    assert any(f.get('name') == 'saw_ruins' for f in doc.flags())
    assert doc.service_of(room, rt.key, rt.state_idx, made[1])['kind'] == 'grandpa'
    sv3 = doc.service_of(room, rt.key, rt.state_idx, made[2])['breeder']
    assert doc.mate_info(sv3['mate']) == (47, 25) and \
        sv3['after'] == [['THanks for', 'breeding with me!']], sv3
    vt.refresh()
    kinds = sorted(vt.npcs.item(r, 3).text() for r in range(vt.npcs.rowCount()))
    assert kinds == ['Breeder (my monster)', 'Breeder (my monster)', 'Grandpa (breeding)'], kinds
    assert 'dusk_mirror_breeder' in vt.pool_users.text() or vt.current_pool()['users'], \
        vt.pool_users.text()
    # the Gates tab: a rule for every gate, its chance by level
    gt = w.gates_tab
    w.tabs.setCurrentWidget(gt)
    gt.refresh()
    gt.list.setCurrentRow(1)
    app.processEvents()
    dlg = GTm.GateRuleDialog(doc, gt.gate(), parent=gt)
    dlg.room.setCurrentIndex(dlg.room.findData('gate_rotation'))
    dlg.every.setChecked(True)
    dlg.by_level.setChecked(True)
    dlg.lv_from.setValue(5)
    dlg.pc_from.setValue(10)
    dlg.lv_to.setValue(40)
    dlg.pc_to.setValue(60)
    rule = dlg.rule()
    assert rule['gate'] == 'any' and rule['chance_by_level'] == {'from': [5, 10], 'to': [40, 60]}
    gt._push('every gate rule', [dict(r) for r in doc.gate_inserts()] + [rule], [])
    app.processEvents()
    import shutil as _sh
    import tempfile
    from editor2.core import compiler as Cc
    td = tempfile.mkdtemp()
    _sh.copytree(doc.project_dir, os.path.join(td, 'p'), ignore=_sh.ignore_patterns('build'))
    open(os.path.join(td, 'p', 'project.json'), 'w').write(doc.dumps())
    outs, _pp, _ww = Cc.compile_project(os.path.join(td, 'p'), REPO)
    assert 'BREED_POOL_COUNT EQU 1' in outs['patches/bank_077.asm']
    assert 'GATE_ANY EQU $FE' in outs['patches/bank_071.asm'] and \
        '; row 0: level 5 -> 10 %, level 40 -> 60 %' in outs['patches/bank_071.asm']
    assert 'breed:dusk_mirror:entry' in outs['patches/bank_060.asm']
    _sh.rmtree(td, ignore_errors=True)
    while s.undo.index() > n0:
        s.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'S127 breeding edits did not undo to the original'
    print('OK: S127 Breeding — Services tab Breeding pools (new, scales, bands + Apply, Try it, '
          'a refused band), Service… Breeder (pool, when, words; r2: CatFly at level 25, long '
          'words wrapped) + Grandpa, Gates tab every '
          'gate + chance by level, compiles, undoes to the original')


def s128_arena(app, w):
    """S128 (ROADMAP P3.14e3): the Arena tab → ★ Your arena (Make your arena = copies of the
    Arena Lobby + the Arena Battle room, the night arena ONE layout for states 1-4 — S128 r2),
    the receptionist's words (game text boxes), a class page's "In your arena" box (a new won
    flag, won words, a win goes to the hub), Starry Night offered with the game's ending; the
    labels say Monster Grandpa's match (S128 r2, not "King"); the project compiles with the
    arena's room ids in bank $6E; every edit undoes to the original."""
    import json
    import PySide6.QtWidgets as QWm
    import editor2.app.arena_tab as ATm
    from editor2.core import arena as AR
    s = w.session
    doc = s.doc
    before = doc.dumps()
    n0 = s.undo.index()
    at = w.arena_tab
    w.tabs.setCurrentWidget(at)
    at.refresh()
    app.processEvents()
    labels = [at.list.item(i).text() for i in range(at.list.count())]
    assert labels[0].startswith('★') and any("Monster Grandpa's match" in t for t in labels) \
        and not any('King' in t for t in labels), labels
    at.list.setCurrentRow(0)
    app.processEvents()
    yp = at.your_page
    assert yp.isVisibleTo(at) and yp.make_btn.isVisibleTo(yp)
    def _no_warning(*a, **k):
        raise AssertionError(f'unexpected warning: {a[2] if len(a) > 2 else a}')
    k_w = ATm.QMessageBox.warning
    ATm.QMessageBox.warning = staticmethod(_no_warning)
    k_q = ATm.QMessageBox.question
    ATm.QMessageBox.question = staticmethod(lambda *a, **k: ATm.QMessageBox.Yes)
    try:
        yp._make()
    finally:
        ATm.QMessageBox.question = k_q
    app.processEvents()
    a = doc.your_arena()
    assert a and doc.room(a['lobby'])['source_mapID'] in ('0x06', '0x6') and \
        int(str(doc.room(a['battle'])['source_mapID']), 0) == 0x5D, a
    sts = doc.room(a['battle'])['screens']['0']['states']
    night = {json.dumps(st.get('layout')) for st in sts[1:]}
    assert len(sts) == 5 and len(night) == 1, (len(sts), night)    # S128 r2: one night look
    at.list.setCurrentRow(0)
    app.processEvents()
    yp.refresh()
    assert yp.body.isVisibleTo(yp) and not yp.make_btn.isVisibleTo(yp)
    yp.words['lost'].set_value([['Too bad!', 'Train more.']])
    yp.words['locked'].set_value([['Not open yet.']])
    yp._words()
    app.processEvents()
    wd = doc.your_arena()['words']
    assert wd['lost'] == {'boxes': [['Too bad!', 'Train more.']]} and \
        wd['locked'] == 'Not open yet.', wd
    # a class page: a new won flag, won words, a win goes to the hub
    at.show_your_arena('F')
    app.processEvents()
    cb = at.class_box
    assert cb.isVisibleTo(at) and cb.name == 'F'
    k_t = QWm.QInputDialog.getText
    QWm.QInputDialog.getText = staticmethod(lambda *a, **k: ('F class won', True))
    try:
        cb._new_flag()
    finally:
        QWm.QInputDialog.getText = k_t
    cb.words.set_value([['F class is', 'yours!']])
    cb.then.setCurrentIndex(cb.then.findData('hub'))
    cb._apply()
    app.processEvents()
    sp = doc.your_arena_class('F')
    assert sp['won_flag'] == 'f_class_won' and sp['then'] == {'to': 'hub'} and \
        sp['won_words'] == {'boxes': [['F class is', 'yours!']]}, sp
    assert any(f.get('name') == 'f_class_won' for f in doc.flags())
    # Starry Night: offered, the game's ending after the final
    at.show_your_arena('StarryNight')
    app.processEvents()
    assert cb.name == 'StarryNight' and cb.offer_box.isVisibleTo(cb)
    cb.offered.setChecked(True)
    cb.then.setCurrentIndex(cb.then.findData('ending'))
    cb._apply()
    app.processEvents()
    assert doc.your_arena()['starry']['then'] == {'to': 'ending'}, doc.your_arena()
    # the Monster Grandpa page has no "In your arena" box
    at.list.setCurrentRow(AR.GROUPS.index('King') + 1)
    app.processEvents()
    assert "Monster Grandpa" in at.title.text() and not cb.isVisibleTo(at), at.title.text()
    # S128 r3 (user: "When I double click on an exit or entry, it should bring up a window
    # that can set both ends"): double-click the lobby copy's bottom exit (a plain game
    # exit) on the Rooms tab -> the connect window lists your rooms' exits + the game's
    # doors; pick GreatTree's arena door -> both ends written (the lobby exit becomes a
    # door, its second cell follows; the game's double door leads into the lobby)
    import editor2.app.rooms.door_dialog as DDm
    from PySide6.QtCore import Qt as _Qt
    rt = w.rooms_tab
    w.navigate_to({'tab': 'rooms', 'room': a['lobby'], 'screen': 1, 'state': 0, 'x': 4, 'y': 7})
    app.processEvents()
    row = next(e for e in doc.exits_of(doc.room(a['lobby']), 1, 0)
               if (e['x'], e['y']) == (4, 7))
    seen = {}
    vid = doc.vanilla_door_id(0x01, 4, 4, 3)
    k_exec = DDm.DoorPropsDialog.exec

    def _pick(dlg):
        groups = [dlg.tree.topLevelItem(i).text(0) for i in range(dlg.tree.topLevelItemCount())]
        seen['groups'] = groups
        seen['title'] = dlg.windowTitle()

        def find(item):
            for i in range(item.childCount()):
                c = item.child(i)
                d = c.data(0, _Qt.UserRole)
                if d and d[1] == vid:
                    return c
                hit = find(c)
                if hit:
                    return hit
            return None
        for i in range(dlg.tree.topLevelItemCount()):
            hit = find(dlg.tree.topLevelItem(i))
            if hit:
                dlg.tree.setCurrentItem(hit)
                break
        return QWm.QDialog.Accepted
    DDm.DoorPropsDialog.exec = _pick
    try:
        rt._marker_activated({'kind': 'exit', 'ref': ('exit', 0, row)})
    finally:
        DDm.DoorPropsDialog.exec = k_exec
    app.processEvents()
    assert seen.get('title') == 'Exit — connect both ends' and \
        any(g.startswith("Your rooms' exits") for g in seen['groups']), seen
    rows = doc.exits_of(doc.room(a['lobby']), 1, 0)
    d_main = [e for e in rows if e.get('door') and (e['x'], e['y']) == (4, 7)]
    d_twin = [e for e in rows if e.get('twin_of') and (e['x'], e['y']) == (5, 7)]
    rds = [r for r in doc.custom.get('entrance_redirects') or [] if r.get('mapID') == '0x01'
           and r.get('screen') == 4 and r.get('y') == 3]
    assert d_main and d_main[0].get('link') == vid and d_twin and \
        sorted(r['x'] for r in rds) == [4, 5], (d_main, d_twin, rds)
    import shutil as _sh
    import tempfile
    from editor2.core import compiler as Cc
    td = tempfile.mkdtemp()
    _sh.copytree(doc.project_dir, os.path.join(td, 'p'), ignore=_sh.ignore_patterns('build'))
    open(os.path.join(td, 'p', 'project.json'), 'w').write(doc.dumps())
    outs, _pp, _ww = Cc.compile_project(os.path.join(td, 'p'), REPO)
    b6e = outs['patches/bank_06e.asm']
    lmid = int(str(doc.room(a['lobby'])['mapID']), 0)
    assert f'ARENA_LOBBY_MID EQU ${lmid:02X}' in b6e, b6e[b6e.find('arena_rooms'):][:400]
    assert 'arena:desk' in outs['patches/bank_060.asm']
    _sh.rmtree(td, ignore_errors=True)
    ATm.QMessageBox.warning = k_w
    while s.undo.index() > n0:
        s.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'S128 arena edits did not undo to the original'
    print("OK: S128 Your arena — Arena tab Make your arena (one night layout), the desk's "
          "words, F class (new won flag, words, then the hub), Starry Night (the game's "
          "ending), Monster Grandpa's match page; r3: double-click the lobby's game exit -> "
          "connect window -> GreatTree's arena door (both ends, both cells); compiles, undoes "
          "to the original")


def s129_story(app, w):
    """S129 (ROADMAP P3.14b/c/d): the story tools in the app — Progression & Flags: the
    story checks' group (New story check…, Edit…, Rename… everywhere, Delete), the Story
    page (milestones added / moved / renamed / removed, the quests listed and edited); the
    Music tab's "Music by flag…" for one of your rooms and for a gate; the Shops tab's
    "Item sets by flag…"; the project compiles with the MusicRuleTable / ShopSetTable rows
    and the StoryCheckTable; every edit undoes to the original."""
    import shutil as _sh
    import tempfile
    import PySide6.QtWidgets as QWm
    import editor2.app.flags_tab as FTm
    import editor2.app.story_widgets as SWm
    from editor2.core import compiler as Cc
    s = w.session
    doc = s.doc
    before = doc.dumps()
    n0 = s.undo.index()
    pt = w.progression_tab
    w.tabs.setCurrentWidget(pt)
    pt.refresh()
    app.processEvents()
    tops = [pt.tree.topLevelItem(i).text(0) for i in range(pt.tree.topLevelItemCount())]
    grp = next(pt.tree.topLevelItem(i) for i in range(pt.tree.topLevelItemCount())
               if pt.tree.topLevelItem(i).text(0).startswith('Story checks'))
    names = sorted(grp.child(i).text(0).lstrip('ℹ⚠✖ ') for i in range(grp.childCount()))
    assert names == ['has_2_medals', 'vault_rich'], (tops, names)
    # New story check… (the dialog filled in: the party's average level 12)
    k_exec = SWm.CheckDialog.exec

    def _fill(dlg):
        dlg.name.setText('party lv 12')
        dlg.kind.setCurrentIndex(dlg.kind.findData('level'))
        dlg._fields['mode'].setCurrentIndex(dlg._fields['mode'].findData('average'))
        dlg._fields['level'].setValue(12)
        assert 'average' in dlg.said.text(), dlg.said.text()
        dlg.accept()
        return QWm.QDialog.Accepted
    SWm.CheckDialog.exec = _fill
    try:
        pt._new_check()
    finally:
        SWm.CheckDialog.exec = k_exec
    app.processEvents()
    c = doc.check('party_lv_12')
    assert c == {'name': 'party_lv_12', 'kind': 'level', 'mode': 'average', 'level': 12}, c
    f = pt.fi.flags.get(pt.cur)
    assert f is not None and f.kind == 'check' and f.idx == 0x1802, (f and (f.kind, f.idx))
    assert pt.b_edit.isVisible() or not pt.isVisible()
    assert not pt.b_renumber.isEnabled() and 'average' in pt.detail.toPlainText()
    # used by a music rule below, then Rename… follows it everywhere
    rid = 'medal_vault'
    mt = w.music_tab
    k_m = SWm.MusicRulesDialog.exec

    def _rules(dlg):
        dlg._add()
        dlg.song.setCurrentIndex(1)
        dlg.terms._add({'flag': 'party_lv_12'})
        dlg.accept()
        return QWm.QDialog.Accepted
    SWm.MusicRulesDialog.exec = _rules
    try:
        mt._room_rules(rid, 'Medal Vault')
        gid = doc.all_gates()[0]['id']
        mt._gate_rules(gid, '')
    finally:
        SWm.MusicRulesDialog.exec = k_m
    app.processEvents()
    rr = doc.room_music_rules(doc.room(rid))
    gr = doc.gate_music_rules(gid)
    assert len(rr) == 1 and rr[0]['when'] == [{'flag': 'party_lv_12'}] and rr[0]['song'], rr
    assert len(gr) == 1 and gr[0]['when'] == [{'flag': 'party_lv_12'}], gr
    k_t = QWm.QInputDialog.getText
    QWm.QInputDialog.getText = staticmethod(lambda *a, **k: ('strong party', True))
    try:
        pt._rename()
    finally:
        QWm.QInputDialog.getText = k_t
    app.processEvents()
    assert doc.check('strong_party') and not doc.check('party_lv_12')
    assert doc.room_music_rules(doc.room(rid))[0]['when'] == [{'flag': 'strong_party'}]
    assert doc.gate_music_rules(gid)[0]['when'] == [{'flag': 'strong_party'}]
    # Edit… (now level 20, every monster)
    def _edit(dlg):
        assert dlg.kind.currentData() == 'level' and dlg._fields['level'].value() == 12
        dlg._fields['mode'].setCurrentIndex(dlg._fields['mode'].findData('all'))
        dlg._fields['level'].setValue(20)
        dlg.accept()
        return QWm.QDialog.Accepted
    SWm.CheckDialog.exec = _edit
    try:
        pt._edit_check()
    finally:
        SWm.CheckDialog.exec = k_exec
    assert doc.check('strong_party') == {'name': 'strong_party', 'kind': 'level',
                                         'mode': 'all', 'level': 20}, doc.check('strong_party')
    # Delete is refused while used
    seen = {}
    k_i = FTm.QMessageBox.information
    FTm.QMessageBox.information = staticmethod(lambda *a, **k: seen.setdefault('i', a[2]))
    try:
        pt._delete()
    finally:
        FTm.QMessageBox.information = k_i
    assert 'still used in 2 places' in seen.get('i', ''), seen
    # the Shops tab: an item set sold while the check holds
    st = w.shops_tab
    w.tabs.setCurrentWidget(st)
    st.refresh()
    st.list.setCurrentRow(0)
    app.processEvents()
    key = st.current()['key']
    k_s = SWm.ItemSetsDialog.exec

    def _sets(dlg):
        dlg._add()
        dlg.name.setText('Strong party goods')
        dlg.terms._add({'flag': 'strong_party'})
        dlg.items._add({'item': 0x05, 'count': 1}) if hasattr(dlg.items, '_add') else None
        dlg.accept()
        return QWm.QDialog.Accepted
    SWm.ItemSetsDialog.exec = _sets
    try:
        st._item_sets()
    finally:
        SWm.ItemSetsDialog.exec = k_s
    app.processEvents()
    sets = doc.shop_sets(key)
    assert len(sets) == 1 and sets[0]['name'] == 'Strong party goods' and \
        sets[0]['when'] == [{'flag': 'strong_party'}] and sets[0]['items'][0] == 0x01, sets
    assert '(1)' in st.btn_sets.text(), st.btn_sets.text()
    # the Story page: milestones and quests
    w.tabs.setCurrentWidget(pt)
    pt.refresh()
    pt.pages.setCurrentIndex(3)
    app.processEvents()
    assert pt.ms_list.count() == 1 and pt.q_list.count() == 1 and \
        'medal' in pt.q_list.item(0).text().lower(), pt.q_list.item(0).text()
    k_gi = QWm.QInputDialog.getItem
    QWm.QInputDialog.getItem = staticmethod(lambda *a, **k: ('mini_medal_quest_started', True))
    QWm.QInputDialog.getText = staticmethod(lambda *a, **k: ('The keeper asked', True))
    try:
        pt.ms_list.setCurrentRow(-1)
        pt._ms_add()
        pt.ms_list.setCurrentRow(1)
        pt._ms_move(-1)
    finally:
        QWm.QInputDialog.getItem = k_gi
        QWm.QInputDialog.getText = k_t
    assert [f for f, _n in doc.milestones()] == ['mini_medal_quest_started',
                                                 'mini_medal_quest_done'], doc.milestones()
    assert pt.ms_list.item(0).text().startswith('1. The keeper asked')
    k_qd = SWm.QuestDialog.exec

    def _quest(dlg):
        dlg.name.setText('Two medals for the keeper')
        dlg.r_gold.setValue(600)
        dlg.accept()
        return QWm.QDialog.Accepted
    SWm.QuestDialog.exec = _quest
    try:
        pt.q_list.setCurrentRow(0)
        pt._quest_edit()
    finally:
        SWm.QuestDialog.exec = k_qd
    q = doc.quest('mini_medal_quest')
    assert q['name'] == 'Two medals for the keeper' and q['reward']['gold'] == 600 and \
        q['flags'] == {'started': 'mini_medal_quest_started', 'done': 'mini_medal_quest_done'}, q
    assert 'Two medals' in pt.q_list.item(0).text()
    # the Rooms tab: Lock until… on an exit (a second room state, the shut look), and an
    # NPC's Quest… (its script becomes the quest's conversation)
    import editor2.app.rooms.tab as RTm
    rt = w.rooms_tab
    w.navigate_to({'tab': 'rooms', 'room': 'ember_keystone', 'screen': 0, 'state': 0,
                   'x': 3, 'y': 1})
    app.processEvents()
    room = doc.room('ember_keystone')
    rows = doc.exits_of(room, 0, 0)
    i = next(j for j, e in enumerate(rows) if (e['x'], e['y']) == (3, 1))
    rt._show_exit_panel(i, rows[i])
    k_l = SWm.LockDialog.exec

    def _lock(dlg):
        dlg.terms._add({'flag': 'has_2_medals'})
        dlg.accept()
        return QWm.QDialog.Accepted
    SWm.LockDialog.exec = _lock
    try:
        rt._lock_exit()
    finally:
        SWm.LockDialog.exec = k_l
    app.processEvents()
    room = doc.room('ember_keystone')
    sts = room['screens']['0']['states']
    assert len(sts) == 2 and not [e for e in sts[1].get('exits') or []
                                  if (e['x'], e['y']) == (3, 1)], sts[1].get('exits')
    assert any(e.get('kind') == 'examine' and (e.get('x'), e.get('y')) == (3, 1)
               for e in sts[1].get('npcs') or []), sts[1].get('npcs')
    rules = doc.state_rules(room)
    assert rules[-2]['state'] == 0 and rules[-2]['when'] == [{'flag': 'has_2_medals'}] and \
        rules[-1]['state'] == 1 and rt.state_idx == 1, (rules, rt.state_idx)
    w.navigate_to({'tab': 'rooms', 'room': 'dusk_mirror', 'screen': 0, 'state': 0,
                   'x': 5, 'y': 6})
    app.processEvents()
    rt._show_npc_panel(2)
    assert rt._sel_npc == 2
    k_qd = SWm.QuestDialog.exec
    k_q = RTm.QMessageBox.question

    def _new_quest(dlg):
        dlg.name.setText('Bard song')
        dlg.objective._add({'flag': 'vault_rich'})
        dlg.r_gold.setValue(50)
        dlg.accept()
        return QWm.QDialog.Accepted
    SWm.QuestDialog.exec = _new_quest
    RTm.QMessageBox.question = staticmethod(lambda *a, **k: RTm.QMessageBox.Yes)
    try:
        rt._npc_quest()
    finally:
        SWm.QuestDialog.exec = k_qd
        RTm.QMessageBox.question = k_q
    q = doc.quest('bard_song')
    assert q and q['giver'] == 'bgm07_change' and q['objective'] == [{'flag': 'vault_rich'}] \
        and q['flags'] == {'started': 'bard_song_started', 'done': 'bard_song_done'}, q
    assert doc.script('bgm07_change')['ops'] == [['end']]
    # the conversation window's new steps (each step's editor opens)
    from PySide6.QtWidgets import QTreeWidgetItemIterator
    from editor2.app.rooms import conversation_dialog as CVm
    dlg = CVm.ConversationDialog(doc, rom=s.renderer.rom, room=doc.room('gate_island'), key=0,
                                 spec={'steps': [{'say': {'boxes': [['Hello!']]}}]}, parent=rt)
    for k in ('by_progress', 'give_item', 'give_monster', 'take_item', 'gold', 'refresh'):
        dlg.tree.setCurrentItem(dlg.tree.topLevelItem(dlg.tree.topLevelItemCount() - 1))
        dlg.add_step(k)
        app.processEvents()
    it = QTreeWidgetItemIterator(dlg.tree)
    n_items = 0
    while it.value():
        dlg.tree.setCurrentItem(it.value())
        app.processEvents()
        n_items += 1
        it += 1
    sp = dlg.spec()
    kinds = [CVm.step_kind(x) for x in sp['steps']]
    assert kinds == ['say', 'by_progress', 'give_item', 'give_monster', 'take_item', 'gold',
                     'refresh'], kinds
    assert sp['steps'][1]['by_progress'][0]['milestone'] == 'mini_medal_quest_started', sp
    assert CVm.spec_problems(sp, doc) == [], CVm.spec_problems(sp, doc)
    assert n_items >= 9, n_items
    dlg.reject()
    # the cutscene editor's new steps: several of an item, take items, gold, refresh
    from editor2.app.rooms import commands as C
    from editor2.app.cutscene_editor import STEP_HELP
    from editor2.core import cutscene_doc as CD
    ct = w.cutscenes_tab
    w.tabs.setCurrentWidget(ct)
    app.processEvents()
    if ct.cat is None:
        ct.load()
    cmd = C.SnapshotCommand(s, 'new', lambda d: CD.new_cutscene(d, 'gate_island', 'Pay', 0,
                                                              'entry'))
    s.undo.push(cmd)
    sid = cmd.result
    app.processEvents()
    ct.refresh()
    app.processEvents()
    mine = ct.tree.topLevelItem(0)
    pick = None
    for i in range(mine.childCount()):
        for j in range(mine.child(i).childCount()):
            if 'Pay' in mine.child(i).child(j).text(0):
                pick = mine.child(i).child(j)
    ct.tree.setCurrentItem(pick)
    app.processEvents()
    ed = ct.editor
    assert ed.scene_id == sid, ([mine.child(i).text(0) for i in range(mine.childCount())],
                                pick and pick.text(0), sid, ed.scene_id)
    ed.add_step('give_item', {'give_item': {'item': 0x1E, 'count': 3}})
    ed.add_step('take_item', {'take_item': {'item': 0x1E, 'count': 2}})
    ed.add_step('gold', {'gold': {'give': 250}})
    ed.add_step('refresh', {'refresh': True})
    app.processEvents()
    assert 'no problems' in ed.problems.text(), ed.problems.text()
    for n, k in enumerate(('give_item', 'take_item', 'gold', 'refresh')):
        ed.path = (n,)
        ed.refresh()
        assert ed.form.about.text() == STEP_HELP[k], (k, ed.form.about.text())
    # compiles: the tables carry the rows
    td = tempfile.mkdtemp()
    _sh.copytree(doc.project_dir, os.path.join(td, 'p'), ignore=_sh.ignore_patterns('build'))
    open(os.path.join(td, 'p', 'project.json'), 'w').write(doc.dumps())
    outs, _pp, _ww = Cc.compile_project(os.path.join(td, 'p'), REPO)
    b71, b77 = outs['patches/bank_071.asm'], outs['patches/bank_077.asm']
    mrt = b71[b71.find('MusicRuleTable:'):].split('db $FF')[0]
    assert 'db $00' in mrt and 'db $01' in mrt, mrt
    assert 'ShopSetTable:' in b77 and "sells 'Strong party goods'" in b77
    assert '= strong_party' in b77, b77[b77.find('StoryCheck_'):][:300]
    cmds = b77[b77.find('StoryCmdPtrs:'):][:900]
    assert 'give_item' in cmds and 'take_item' in cmds and 'give_gold' in cmds, cmds
    _sh.rmtree(td, ignore_errors=True)
    while s.undo.index() > n0:
        s.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'S129 story edits did not undo to the original'
    print('OK: S129 story — the conversation window\'s new steps (says by progress, give '
          'items / a monster, take, gold, refresh); the cutscene editor\'s new steps (3 of an item, take, gold, '
          'refresh); Rooms tab Lock until… (a shut state + its rules), an NPC\'s '
          'Quest…; Progression & Flags: the story checks group (New story check…, '
          'Rename… follows into the music rules, Edit…, Delete refused while used), the Story '
          'page (milestones added / moved, the quest edited); Music by flag for a room and a '
          'gate; a shop\'s item set; compiles with MusicRuleTable / ShopSetTable / '
          'StoryCheckTable; undoes to the original')


def s130_balance(app, w):
    """S130 (ROADMAP P3.15a): the Balance tab — offscreen without a project (the
    original game only: rows from a small anchor, project columns hidden) and with
    the example project (its timeline, the anchor's numbers on the same rows, one
    fight computed with tiny sizes into a scratch cache, the breeding setting as
    one undo step); the Team page (a tiny roll, a save's party, a picked member);
    the Fight page (the team evaluated, a what-if applied — the story data
    untouched — and reset). Nothing is saved; every edit is undone."""
    import tempfile
    from editor2.app import balance_tab as BT
    from editor2.core import balance as BL
    sys.path.insert(0, os.path.join(REPO, 'editor2', 'tests'))
    from test_compiler import fake_sav_s130

    def ev(l90, l50, unm=0.05, tl=None, win=0.92, ehp=0.0, tactic=None):
        r = {'l90': l90, 'l50': l50, 'at90': {'win': win, 'rounds': 3.0, 'hp_left': 0.5,
                                             'battles': 96, 'unmodelled': unm,
                                             'enemy_hp_left': ehp,
                                             'team_level': tl or (l90 or 99)}}
        if tactic is not None:
            r['at90']['tactic'] = tactic
        return r

    def kit(step, fights):                     # a kit as kits.step_kit writes it
        mem = [{'species': 78, 'name': 'Dracky', 'src': ['join', 4], 'plus': 0,
                'skills': [51, 21], 'skill_names': ['Sleep', 'Antidote'], 'level': 6},
               {'species': 53, 'name': 'Anteater', 'src': ['join', 3], 'plus': 0,
                'skills': [], 'skill_names': [], 'level': 6},
               {'species': 8, 'name': 'Slime', 'src': ['join', 1], 'plus': 0,
                'skills': [3], 'skill_names': ['Blaze'], 'level': 7}]
        return {'step': step, 'level': 6, 'members': mem, 'score': 0.9, 'version': 1,
                'why': ['Dracky L6 (joins (EID 4)): ordered Attack 70%'], 'fights': fights}
    anchor = {
        'sim_version': BL.SIM_VERSION, 'breeding_opens': BL.BREEDING_OPENS_AFTER,
        'steps': [{'index': 0, 'kind': 'gate', 'id': 0, 'label': 'Gate of Beginning',
                   'postgame': False, 'breeding': False, 'fights': ['gate0.f1', 'gate0.boss0'],
                   'kit': kit(0, {'gate0.boss0': {'win': 1.0, 'tactic': None}})},
                  {'index': 1, 'kind': 'class', 'id': 0, 'label': 'G class', 'postgame': False,
                   'breeding': False, 'fights': ['arena0.m0'],
                   'kit': kit(1, {'arena0.m0': {'win': 0.8, 'tactic': 1}})}],
        'fights': {'gate0.f1': {'step': 0, 'kind': 'list', 'label': 'Gate of Beginning — floors 1-4',
                                'step_label': 'Gate of Beginning', 'casual': ev(3, 1), 'strong': ev(2, 1),
                                'player': ev(2, 1)},
                   'gate0.boss0': {'step': 0, 'kind': 'boss', 'label': 'Gate of Beginning — boss: Healer',
                                   'step_label': 'Gate of Beginning', 'casual': ev(9, 6, 0.3, 7.0),
                                   'strong': ev(7, 5), 'player': ev(5, 4)},
                   'arena0.m0': {'step': 1, 'kind': 'arena', 'label': 'G class — match 1',
                                 'step_label': 'G class', 'casual': ev(None, 40, win=0.17, ehp=0.4),
                                 'strong': ev(30, 20), 'player': ev(8, 5, tactic=1)}},
        'dives': {'0': {'casual': {'direct': {'level': 6, 'eval': {'clear': 0.9, 'battles': 4.2}},
                                   'sweep': {'level': 10, 'eval': {'clear': 0.9, 'battles': 12.0}}}}}}
    # --- pure pieces
    assert BT.delta_class(10, 20) == ('+10', 'much harder') and BT.delta_class(10, 13)[1] == 'harder'
    assert BT.delta_class(10, 11)[1] == 'similar' and BT.delta_class(10, 6)[1] == 'easier'
    assert BT.delta_class(100, 100)[1] == 'similar' and BT.lv_text({'l90': None}) == '99+'
    r99 = ev(None, None, win=0.17, ehp=0.4)                 # not even at 99: graded
    assert BT.lv_text(r99) == '99+ (17 %)' and abs(BT.chart_value(r99) - 112.3) < 0.01
    assert BT.delta_beyond(ev(None, None, win=0.6), r99) == ('-43 % at 99', 'much harder')
    assert BT.lv_text({'l90': None, 'dive': True, 'at90': {'clear': 0.5}}) == '99+ (50 %)'
    assert BT.anchor_problem(None) and BT.anchor_problem(anchor) is None
    # --- no project: the original game only
    from PySide6.QtCore import QSettings
    QSettings('dwm1_disassembly', 'DWM1Editor').remove('balance/details')
    t = BT.BalanceTab(None, anchor=anchor)
    t.resize(1200, 700)
    t.show()
    app.processEvents()
    st = t.story
    # the simple view is the default (user: "really crowded"): Fight | Level needed
    assert not t.details and not t.cb_details.isChecked()
    shown = [c for c in range(len(BT.HEADERS)) if not st.tree.isColumnHidden(c)]
    assert shown == [BT.C_FIGHT, BT.C_VP90], shown
    assert st.tree.headerItem().text(BT.C_VP90) == 'Level needed'
    b = st.items['gate0.boss0']
    assert b.text(BT.C_VP90) == 'Lv 5' and 'wins 9 of 10' in b.toolTip(BT.C_VP90), b.toolTip(BT.C_VP90)
    assert st.items['dive0.direct'].isHidden() and st.simple_line.isVisibleTo(t)
    assert not st.kit_panel.isVisibleTo(t) and not st.chart_prof.isVisibleTo(t)
    st.b_show_team.setChecked(True)
    assert st.kit_panel.isVisibleTo(t)
    assert st.tree.topLevelItem(0).text(BT.C_VP90) == 'Lv 5'
    assert BT.simple_change(ev(20, 10), ev(32, 20)) == ('much harder (+12)', 'much harder')
    assert BT.simple_change(ev(20, 10), ev(25, 20)) == ('harder (+5)', 'harder')
    assert BT.simple_change(ev(20, 10), ev(21, 20))[0] == 'about the same'
    assert BT.simple_change(ev(20, 10), ev(16, 10))[0] == 'easier (−4)'
    assert BT.simple_change(ev(40, 10), ev(28, 10))[0] == 'much easier (−12)'
    assert BT.simple_text(ev(None, None, win=0.38)) == "can't win (38 %)"
    assert not t.team.prof.isVisibleTo(t) and t.team.prof.currentText() == 'player'
    assert not t.fight.prof.isVisibleTo(t) and not t.fight.orders.isVisibleTo(t)
    t.cb_details.setChecked(True)                   # the full view, as before
    assert t.details and not st.tree.isColumnHidden(BT.C_V90) and not st.items['dive0.direct'].isHidden()
    assert st.tree.headerItem().text(BT.C_VP90) == BT.HEADERS[BT.C_VP90]
    assert st.tree.isColumnHidden(BT.C_P90) and st.tree.isColumnHidden(BT.C_PP90) and \
        not st.b_casual.isVisibleTo(t) and not st.b_player.isVisibleTo(t)
    # the player profile is the main number: first, bold, the chart's and Change's default
    assert not st.tree.isColumnHidden(BT.C_VP90) and BT.C_VP90 < BT.C_V90
    assert st.tree.headerItem().font(BT.C_VP90).bold() and not st.tree.headerItem().font(BT.C_V90).bold()
    assert st.chart_prof.currentText() == 'player' == st.delta_prof.currentText()
    assert st.items['gate0.boss0'].text(BT.C_VP90) == '5' and st.items['gate0.boss0'].text(BT.C_VP50) == '4'
    assert st.chart.van == {0: 5, 1: 8}, st.chart.van
    assert "best tactic: Mixed" in st.items['arena0.m0'].text(BT.C_NOTE), st.items['arena0.m0'].text(BT.C_NOTE)
    st.show_sec.setChecked(False)
    assert st.tree.isColumnHidden(BT.C_V90) and not st.tree.isColumnHidden(BT.C_VP90)
    st.show_sec.setChecked(True)
    st.chart_prof.setCurrentText('casual')
    tops = [st.tree.topLevelItem(i).text(0) for i in range(st.tree.topLevelItemCount())]
    assert tops == ['1. Gate of Beginning', '2. G class'], tops
    b = st.items['gate0.boss0']
    assert [b.text(c) for c in (BT.C_V90, BT.C_V50, BT.C_VS90, BT.C_UNM)] == ['9', '6', '7', '30 %']
    assert 'level caps' in b.text(BT.C_NOTE), b.text(BT.C_NOTE)
    # level colours by band (S130 user: "colour code levels")
    bg = lambda it, c: it.background(c).color()                          # noqa: E731
    c7 = bg(b, BT.C_VS90)
    a0 = st.items['arena0.m0']
    c40, c99 = bg(a0, BT.C_V50), bg(a0, BT.C_V90)
    assert c7 == BT.level_colour(7) == BT.level_colour(1) and c40 == BT.level_colour(31)
    assert c99 == BT.level_colour(100, 0.83) and len({c7.rgba(), c40.rgba(), c99.rgba()}) == 3
    assert BT.level_colour(45) != BT.level_colour(40) and BT.level_colour(45) == BT.level_colour(50)
    assert BT.level_colour(100, 1.0).alpha() > BT.level_colour(100, 0.1).alpha()
    assert 'Levels:' in st.level_legend.text() and '76-98' in st.level_legend.text()
    assert a0.text(BT.C_V90) == '99+ (17 %)' and 'enemies left with 40 % HP' in a0.toolTip(BT.C_V90)
    assert st.items['dive0.direct'].text(BT.C_V90) == '6' and st.items['dive0.sweep'].text(BT.C_V90) == '10'
    assert st.tree.topLevelItem(0).text(BT.C_V90) == '9'            # the step's hardest fight
    assert st.chart.van[0] == 9 and abs(st.chart.van[1] - 112.3) < 0.01, st.chart.van
    # the kit view: the step's kit (3 members), the arena fight's tactic, "use this kit"
    st.tree.setCurrentItem(st.items['arena0.m0'])
    kv = st.kit_view.toPlainText()
    assert 'Original game' in kv and all(n in kv for n in ('Dracky', 'Anteater', 'Slime')) \
        and 'joins (EID 3)' in kv and 'Mixed' in kv, kv
    assert st.b_use_kit.isEnabled() and '(L8)' in st.b_use_kit.text(), st.b_use_kit.text()
    st.use_kit()
    assert t.wait_idle(60) and t.team.table.rowCount() == 3 and 'player kit' in \
        t.team.summary.text(), t.team.summary.text()
    assert [m.species for m in t.team.team] == [78, 53, 8]
    # Team page: a tiny roll on the original game; the player profile = the step kit
    t.pages.setCurrentWidget(t.team)
    assert t.wait_idle(60) and t.team.step.count() >= 40, t.team.step.count()
    t.team.level.setValue(5)
    t.team.prof.setCurrentText('casual')
    t.team.roll()
    assert t.wait_idle(60) and t.team.table.rowCount() == 3 and 'Rolled casual team #0' in \
        t.team.summary.text(), t.team.summary.text()
    t.team.prof.setCurrentText('player')
    t.team.roll()
    assert t.wait_idle(60) and t.team.table.rowCount() == 3 and 'player kit of 1.' in \
        t.team.summary.text(), t.team.summary.text()
    t.shutdown()
    t.deleteLater()
    print('OK: S130 Balance tab without a project — rows from the anchor (99+, dives, the step\'s '
          'hardest fight, the chart), player columns first, the kit view (3 members, the arena '
          'tactic), project columns hidden, teams rolled (casual, the player kit)')
    # --- with the example project
    s = w.session
    before = s.doc.dumps()
    n0 = s.undo.index()
    assert w.tabs.indexOf(w.balance_tab) >= 0, 'no Balance tab'
    t = BT.BalanceTab(s, anchor=anchor)
    t.teams, t.battles = 2, 2
    t.resize(1200, 700)
    t.show()
    assert t.wait_idle(120), 'project data not read'
    st = t.story
    t.cb_details.setChecked(False)
    shown = [c for c in range(len(BT.HEADERS)) if not st.tree.isColumnHidden(c)]
    assert shown == [BT.C_FIGHT, BT.C_VP90, BT.C_PP90, BT.C_DELTA], shown
    assert [st.tree.headerItem().text(c) for c in shown[1:]] == ['Original game', 'Your project',
                                                                 'Change']
    assert st.b_simple.isVisibleTo(t) and not st.b_casual.isVisibleTo(t) and not st.b_player.isVisibleTo(t)
    t.cb_details.setChecked(True)
    pc = t.ctx['project']
    tmp = tempfile.mkdtemp()
    pc.cache = BL.FightCache(os.path.join(tmp, 'balance_cache.json'))   # never the example's build/
    for cp in list(t._caches):
        t._caches[cp] = pc.cache                                         # (re-reads too)
    t.kit_budget = {'evals': 2, 'teams': 1, 'battles': 2}                # a tiny kit search
    assert not st.tree.isColumnHidden(BT.C_P90)
    assert len(pc.tl.steps) == len(BL.VANILLA_STEPS) and st.tree.topLevelItemCount() >= 41
    k = pc.tl.steps[0]['fights'][0]
    assert st.items[k].text(BT.C_V90) == ('3' if k == 'gate0.f1' else '—')
    assert st.breed.currentData() == BL.BREEDING_OPENS_AFTER
    st.dives.setChecked(False)
    st.tree.clearSelection()
    st.items[k].setSelected(True)
    assert st.selected_keys() == [k]
    st.compute_selected()
    assert t.wait_idle(300), 'compute did not finish'
    assert st.items[k].text(BT.C_P90) not in ('—', '') and st.items[k].text(BT.C_PS90) != '—', \
        [st.items[k].text(c) for c in range(15)]
    assert st.items[k].text(BT.C_PP90) not in ('—', ''), [st.items[k].text(c) for c in range(15)]
    assert len(st.kits_prj[0]['members']) == 3
    st.tree.setCurrentItem(st.items[k])
    assert 'Your project' in st.kit_view.toPlainText() and st.b_use_kit.isEnabled()
    assert os.path.exists(os.path.join(tmp, 'balance_cache.json')) and \
        not os.path.exists(os.path.join(s.project_dir, 'build', 'balance_cache.json'))
    # the breeding setting: one undo step in meta.balance, the timeline re-read
    st.breed.setCurrentIndex(st.breed.findData(BL.BREEDING_OPENS_AFTER - 1))
    st._breed_changed(st.breed.currentIndex())
    assert s.doc.data['meta'].get('balance') == {'breeding_opens_after': BL.BREEDING_OPENS_AFTER - 1}
    assert t.wait_idle(120) and t.ctx['project'].tl.breeding_opens == BL.BREEDING_OPENS_AFTER - 1
    s.undo.setIndex(n0)
    assert 'balance' not in s.doc.data['meta']
    # Team page: a save's party, a picked member
    tm = t.team
    path = os.path.join(tmp, 'party.sav')
    open(path, 'wb').write(fake_sav_s130())
    assert tm.import_sav(path) is None and tm.table.rowCount() == 3
    assert [tm.table.item(r, 0).text() for r in range(3)] == ['Goo', 'Ant', 'Bat']
    assert tm.import_sav(os.path.join(tmp, 'nope.sav'))          # a problem, not a crash
    ctx = t.ctx.get('project')
    if ctx is None:
        t.with_ctx('project', lambda _c: None)
        assert t.wait_idle(120)
        ctx = t.ctx['project']
    tm.table.selectRow(2)
    tm.add_member(BL.custom_member(ctx.data, 8, 12, [3]))
    assert tm.table.rowCount() == 3 and tm.team[2].species == 8 and tm.team[2].skills == [3]
    # Fight page: evaluate the team, a what-if (the story data untouched), reset
    fp = t.fight
    t.pages.setCurrentWidget(fp)
    assert t.wait_idle(60) and fp.fights.count() >= 100, fp.fights.count()
    key = next(k for k in ctx.tl.fights if '.boss' in k)
    fp.show_fight('project', key)
    assert t.wait_idle(60) and fp.fights.currentData() == key and fp.enemies.rowCount() >= 1
    fp.n_battles.setValue(4)
    fp.eval_team()
    assert t.wait_idle(60) and fp.results.item(0, 0).text().endswith('%'), fp.status.text()
    how_row = [k for k, _l in BT.RES_ROWS].index('how')
    assert fp.results.item(how_row, 0).text() == 'your orders (Command)'
    ehp_row = [k for k, _l in BT.RES_ROWS].index('enemy_hp_left')
    assert fp.results.item(ehp_row, 0).text().endswith('%'), fp.results.item(ehp_row, 0).text()
    eid = fp.w_enemy.currentData()
    ctx = fp.ctx()
    fp.apply_whatif(eid, level=99, atk=999, skills=[3])
    assert ctx.whatif.enemy_overrides.get(eid) and not ctx.data.enemy_overrides
    assert ctx.whatif.enemy_rec(eid)['atk'] == 999 and ctx.data.enemy_rec(eid)['atk'] != 999
    assert 'What-if on' in fp.w_note.text()
    fp.eval_team()
    assert t.wait_idle(60) and fp.results.item(0, 1).text().endswith('%'), fp.status.text()
    fp.prof.setCurrentText('player')                # the player level, as is and what-if
    fp.level_needed()
    assert t.wait_idle(300), fp.status.text()
    l90_row = [k for k, _l in BT.RES_ROWS].index('l90')
    assert fp.results.item(l90_row, 0).text() and fp.results.item(l90_row, 1).text() not in ('', '—'), \
        (fp.results.item(l90_row, 0).text(), fp.results.item(l90_row, 1).text(), fp.status.text())
    assert not ctx.data.enemy_overrides
    t.project_changed(now=True)                   # a project edit: re-read, the what-if kept
    assert t.wait_idle(120) and t.ctx['project'] is not ctx
    ctx = fp.ctx()
    assert ctx.whatif.enemy_overrides.get(eid) and fp.fights.currentData() == key
    fp.reset_whatif()
    assert not ctx.whatif.enemy_overrides and fp.w_note.text() == 'No what-if.'
    # the simple view's Change words on a computed row
    t.cb_details.setChecked(False)
    for kk in ('gate0.f1',):
        if ('prj', 'player', kk) in st.res and ('van', 'player', kk) in st.res:
            txt = st.items[kk].text(BT.C_DELTA)
            assert any(wd in txt for wd in ('harder', 'easier', 'about the same')), txt
    fp.apply_mode()
    win_row = [k for k, _l in BT.RES_ROWS].index('win')
    assert fp.results.verticalHeaderItem(win_row).text() == 'Wins'
    t.shutdown()
    t.deleteLater()
    app.processEvents()
    assert s.undo.index() == n0 and s.doc.dumps() == before
    print(f'OK: S130 Balance tab with the example project — {len(st.items)} rows, {k} computed '
          '(tiny sizes, scratch cache), breeding setting undone, a .sav party + a picked member, '
          'the team evaluated (orders) with and without a what-if, the player level with a '
          'tiny kit search')


def main():
    do_rom = '--rom' in sys.argv
    app = QApplication.instance() or QApplication(sys.argv)
    from editor2.app.main import MainWindow             # noqa: E402
    w = MainWindow()
    w.open_project(os.path.join(REPO, 'editor2/example-project'))
    n = w.room_list.count()
    assert n >= 6, f'room list has {n} entries, expected >= 6'
    assert w.a_build.isEnabled(), 'Build action not enabled after open'
    assert not w.session.dirty, 'opening must not dirty the project'
    assert w.session.doc.dumps() == open(w.session.doc.path).read(), \
        'document model must round-trip project.json byte-for-byte'
    print(f'OK: window up, {n} rooms listed, Build enabled, doc round-trips')

    # S101 r2: the Help tab (user: "needs lookup") — every topic loads, search
    # filters, and the help is kept up to date WITH the editor: its
    # _revision.md must name the current EDITOR_REVISION
    from editor2 import EDITOR_REVISION
    from editor2.app.help_tab import help_revision, load_topics
    ht = w.help_tab
    assert w.tabs.indexOf(ht) >= 0, 'no Help tab'
    topics = load_topics()
    assert len(topics) >= 8 and ht.list.count() == len(topics), (len(topics), ht.list.count())
    ht.search.setText('warubou')
    assert 0 < ht.list.count() < len(topics), ht.list.count()
    ht.search.setText('')
    assert ht.show_topic('Boss floors') and 'step by step' in ht.view.toPlainText()
    assert help_revision() == EDITOR_REVISION, (
        f'editor2/help/_revision.md says {help_revision()!r} but EDITOR_REVISION is '
        f'{EDITOR_REVISION!r} — update the help topics for this delivery, then the stamp')
    # S119b (user: "Your help tab is cut off for cutscenes"): a raw <word> outside a
    # code span is read as an HTML tag and hides the rest of the topic — every topic
    # must render to its last words
    import re as _re
    from PySide6.QtGui import QTextDocument
    for title, md, fname in topics:
        d = QTextDocument()
        d.setMarkdown(md)
        shown = ' '.join(d.toPlainText().split())
        tail = _re.findall(r'[A-Za-z]{5,}', md)[-3:]
        assert all(t in shown for t in tail), f'help {fname} is cut off when shown (look for <…>)'
    print(f'OK: Help tab — {len(topics)} topics, search, help revision == {EDITOR_REVISION}, '
          f'every topic shown to its end')
    s120_dialogue(app, w)
    s120_gates(app, w)
    s121_milly(app, w)
    s122_gate_themes(app, w)
    s123_worlds(app, w)
    s124_progression(app, w)
    s125_hub(app, w)
    s126_services(app, w)
    s127_breeding(app, w)
    s127r3_game_text_rule(app, w)
    s128_arena(app, w)
    s129_story(app, w)
    s130_balance(app, w)

    # S101 r3: World tab zoom (wheel, around the mouse) + pan (drag empty canvas)
    from PySide6.QtCore import QPoint, QPointF, Qt
    from PySide6.QtGui import QWheelEvent, QMouseEvent
    wt = w.world_tab
    w.tabs.setCurrentWidget(wt)
    w.resize(1300, 800)
    w.show()
    app.processEvents()
    z0 = wt.view.transform().m11()
    vp = wt.view.viewport()
    c = QPointF(vp.width() / 2, vp.height() / 2)
    for _ in range(4):
        ev = QWheelEvent(c, vp.mapToGlobal(c), QPoint(0, 0), QPoint(0, 120), Qt.NoButton,
                         Qt.NoModifier, Qt.NoScrollPhase, False)
        wt._wheel(ev)
    z1 = wt.view.transform().m11()
    assert z1 > z0 * 1.5, (z0, z1)
    h0 = wt.view.horizontalScrollBar().value()
    wt.view.horizontalScrollBar().setValue(h0 + 200)       # what a hand-drag does
    assert wt.view.horizontalScrollBar().value() != h0, 'no room to pan when zoomed'
    wt.zoom(1 / 50)
    assert abs(wt.view.transform().m11() - wt.ZOOM_MIN) < 1e-6
    wt.fit()
    print(f'OK: World tab — wheel zoom {z0:.2f} -> {z1:.2f}, pans when zoomed, clamp, Fit')

    # Rooms tab: the canvas renders LIVE from project.json (S93) — no build
    # needed. The selected room must produce pixels; placeholder rooms must
    # not; the arena clone's vanilla-referenced layout must be read-only.
    app.processEvents()
    rt = w.rooms_tab
    pm = rt.canvas.base.pixmap()
    assert pm is not None and not pm.isNull() and pm.width() == 160, \
        'canvas produced no 160px-wide screen pixmap'
    for i in range(n):
        if 'placeholder' in rt.room_list.item(i).text():
            rt.room_list.setCurrentRow(i)
            app.processEvents()
            assert rt.canvas.room is None, 'placeholder room unexpectedly rendered'
            break
    for i in range(n):
        if 'arena_clone' in rt.room_list.item(i).text():
            rt.room_list.setCurrentRow(i)
            app.processEvents()
            rt.select_screen(1)
            assert not rt.canvas.is_editable(), 'vanilla layout ref must be read-only'
            assert rt.state_box.count() == 2, 'arena_clone screen 1 has 2 states'
            rt.select_state(1)
            assert len(rt.canvas.markers) > 0
            break
    rt.room_list.setCurrentRow(0)
    app.processEvents()
    assert w.tabs.count() >= 11, 'tab strip incomplete'
    print('OK: Rooms tab renders live (placeholders skipped, vanilla refs '
          'read-only, states switch); shell has the §5.0 tab strip')

    # S104 (P3.10a): Families tab — 11 families, move a monster, dialogue voice,
    # Spirit names; each edit is one undo step and undo restores the file
    from editor2.core import gamedata as G
    ft = w.families_tab
    w.tabs.setCurrentWidget(ft)
    app.processEvents()
    assert ft.fam_list.count() == 11, ft.fam_list.count()
    doc = w.session.doc
    before = doc.dumps()
    n_spirit = len(doc.family_members()[10])
    ft.fam_list.setCurrentRow(0)
    for i in range(ft.members.count()):
        if ft.members.item(i).data(Qt.UserRole) == 4:          # Snaily
            ft.members.setCurrentRow(i)
    ft.move_to.setCurrentIndex(ft.move_to.findData(10))
    ft._move()
    assert len(doc.family_members()[10]) == n_spirit + 1
    # S104 r5: display order puts Spirit before ??? (row 9)
    assert ft.fam_list.item(9).text().startswith('Spirit'), ft.fam_list.item(9).text()
    assert ft.fam_list.item(10).text().startswith('???'), ft.fam_list.item(10).text()
    ft.fam_list.setCurrentRow(9)
    ft.voice.setCurrentIndex(ft.voice.findData('A'))
    ft._voice(0)
    assert doc.family_voice(10) == 'A'
    assert ft.names_box.isVisibleTo(ft)
    ft.name_edits[0].setText('Boo')
    ft._names()
    assert doc.spirit_names()[0] == 'Boo'
    fam = doc.data['gamedata']['families']
    assert any(v.get('dialogue') == 'A' and v.get('names', [''])[0] == 'Boo'
               for v in fam.values()), fam
    ft.name_edits[1].setText('TOOLONG'[:G.NAME_MAX] + '1')   # maxLength stops the 5th char
    assert len(ft.name_edits[1].text()) <= G.NAME_MAX
    for _ in range(3):
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    print('OK: Families tab — 11 families, move Snaily to Spirit, voice A, a Spirit '
          'name; undo restores the document')

    # S107 (P3.10 part 2c): the family icon editor — a painted stroke = one
    # undo step into gamedata.families.<f>.icon; a PNG import; the original
    # again removes the key; undo restores the file
    from editor2.app import families_tab as FT
    before = doc.dumps()
    ft.fam_list.setCurrentRow(0)                                   # Slime
    app.processEvents()
    assert ft.icon_canvas.grid == doc.vanilla_family_icon(0)
    assert not ft.icon_reset.isEnabled()
    g = [list(r) for r in ft.icon_canvas.grid]
    g[0][0] = 3
    ft.icon_canvas.set_grid(g)
    ft._icon_edited(g)
    assert doc.data['gamedata']['families']['slime']['icon'][0][0] == '3', \
        doc.data['gamedata']['families']
    assert ft.icon_reset.isEnabled() and ft.icon_canvas.grid == g
    import tempfile
    from PIL import Image
    tmp = os.path.join(tempfile.mkdtemp(), 'icon.png')
    im = Image.new('RGB', (8, 8), (255, 255, 255))
    for k in range(8):
        im.putpixel((k, k), (0, 0, 0))
        im.putpixel((7 - k, k), (90, 90, 90))
    im.save(tmp)
    want = FT.png_to_grid(tmp)
    assert want[0][0] == 3 and want[0][7] == 0 and want[1][2] == 1, want
    ft.fam_list.setCurrentRow(9)                                   # Spirit
    app.processEvents()
    real = FT.QFileDialog.getOpenFileName
    FT.QFileDialog.getOpenFileName = staticmethod(lambda *a, **k: (tmp, ''))
    try:
        ft._icon_png()
    finally:
        FT.QFileDialog.getOpenFileName = real
    assert doc.family_icon(10) == want
    ft._icon_original()
    assert doc.family_icon(10) == doc.vanilla_family_icon(10)
    for _ in range(3):
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    print('OK: Families tab (S107) — icon painted, a PNG imported for Spirit, back to '
          'the original; undo restores the document')

    # S106 (P3.10 part 1): Monsters tab — species list (original + new),
    # species field edits, an enemy-row edit, a new species cut from a sprite
    # sheet through the real dialog; every edit one undo step, undo restores
    # project.json AND removes the written art / sheet files
    mt = w.monsters_tab
    w.tabs.setCurrentWidget(mt)
    app.processEvents()
    ids = [mt.list.item(i).data(Qt.UserRole) for i in range(mt.list.count())]
    assert 224 in ids and 0 in ids and 220 in ids, 'species list incomplete'
    assert sum(1 for i in ids if i is not None) == 222, len(ids)
    before = doc.dumps()
    mt.select(8)
    assert mt.sid == 8 and 'Slime' in mt.title.text()
    assert mt.walk.frames is not None and mt.battle.pixmap() is not None
    mt.w_cap.setValue(60)
    mt._set('level_cap', 60)
    mt.w_resist['Fire'].setCurrentIndex(3)
    mt._set('resist.Fire', 3)
    assert doc.data['gamedata']['monsters']['8'] == {'level_cap': 60, 'resist': {'Fire': 3}}, \
        doc.data['gamedata']['monsters']['8']
    mt.pages.setCurrentIndex(1)
    app.processEvents()
    rows = {mt.table.item(r, 0).text(): r for r in range(mt.table.rowCount())}
    assert '2' in rows and '1' in rows, rows
    it = mt.table.item(rows['2'], 3)          # HP of the wild Slime (EID 2)
    it.setText('99')
    assert doc.data['gamedata']['enemies']['2'] == {'hp': 99}, doc.data['gamedata'].get('enemies')
    # S106 r3: "Put the selected row in a gate…" — a new enemy row of Gorbunok,
    # into the free slot of the Gate of Beginning list, chances to 100 %
    from editor2.app.pool_dialog import PoolDialog
    mt.select(224)
    mt._new_enemy_row()
    nid = [e for e in mt._rows if e['kind'] == 'project'][-1]
    pd = PoolDialog(doc, nid['id'], 'test row', parent=mt)
    pd.pool.setCurrentIndex(pd.pool.findData(0))
    assert pd.table.currentRow() == 4, pd.table.currentRow()     # the free slot preselected
    pd._put()
    pd.table.cellWidget(3, 1).setCurrentIndex(5)                 # Gorbunok 70 % -> 50 %
    pd._ok()
    assert pd.result_slots and pd.result_slots[4][0] == nid['id'], pd.result_slots
    pi, slots = pd.result_pool, pd.result_slots
    assert mt._push('gate', lambda d: d.set_pool_slots(pi, slots))
    assert doc.data['gamedata']['encounters']['0']['eids'][4] == nid['id']
    w.session.undo.undo()
    w.session.undo.undo()
    from editor2.app.sheet_import_dialog import SheetImportDialog, copy_sheet_into_project
    sheet = os.path.join(REPO, 'examples/follower_swap/W_bluedragon.png')
    dlg = SheetImportDialog(doc, 'new', parent=mt)
    dlg.load_sheet(sheet)
    k = next(i for i, e in enumerate(dlg.entries)
             if e['frames'] and e['frames']['DOWN-a']['x'] == 232 and e['frames']['DOWN-a']['y'] == 8)
    dlg.select_entry(k)
    it = dlg.items['DOWN-a']
    it.setPos(it.pos().x() + 1, it.pos().y())       # a dragged box changes the preview
    assert dlg.current()['frames']['DOWN-a']['x'] == 233
    it.setPos(it.pos().x() - 1, it.pos().y())
    dlg.name.setText('Aquadrak')
    dlg._accept()
    r = dlg.result_data
    assert r and r['id'] == 221 and r['art']['follower_palette'] == 2, r and r.get('id')
    assets = doc.species_asset_paths(r['id'], r['name']) + [r['source']['sheet']]

    def op(d):
        copy_sheet_into_project(d.project_dir, r['sheet_abs'], r['source']['sheet'])
        d.add_species(r['id'], r['name'], r['short'], r['clone_from'], r['family'],
                      r['art'], source=r['source'])
    assert mt._push('New species Aquadrak', op, assets=assets)
    files = [os.path.join(doc.project_dir, a) for a in assets]
    assert all(os.path.exists(f) for f in files), files
    mt.refresh()
    mt.select(221)
    assert mt.sid == 221 and 'Aquadrak' in mt.title.text() and mt.pages.isTabEnabled(2)
    for _ in range(4):
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    assert not any(os.path.exists(f) for f in files), 'undo must remove the written art'
    sdir = os.path.join(doc.project_dir, 'assets', 'sheets')
    if os.path.isdir(sdir) and not os.listdir(sdir):
        os.rmdir(sdir)
    print('OK: Monsters tab — 222 species listed, Slime level cap + Fire resistance, wild '
          'Slime HP, a Gorbunok row put in a gate, a new species cut from the water sheet; undo restores everything')

    # S107 (P3.10 part 2a): new art for an ORIGINAL monster (Dracky, 78) through
    # the real sheet dialog ('original' mode), a battle colour + walking palette
    # on another (Slime 8, colours only), TERRY? (215) has no art page; undo
    # restores project.json and removes the written art
    before = doc.dumps()
    mt.select(215)
    assert not mt.pages.isTabEnabled(2), 'TERRY? must have no art page (Iron Rule 8)'
    mt.select(78)
    assert mt.pages.isTabEnabled(2) and mt.orig_btn.isVisibleTo(mt.art_page) \
        and mt.name_box.isVisibleTo(mt.art_page) and not mt.a_desc.isVisibleTo(mt.art_page)
    dlg = SheetImportDialog(doc, 'original', sid=78, parent=mt)
    assert 'Dracky' in dlg.windowTitle()
    dlg.load_sheet(sheet)
    dlg.select_entry(k)
    # S107 2b: the walk style list = all 155 layouts ranked, best first, the
    # sheet's own frames shown beside the game's; picking another re-packs
    assert dlg.lay_combo.count() == 155 and dlg.lay_combo.currentIndex() == 0
    assert dlg._follow[2] == dlg._fit[0][1] and dlg.walk_sheet.frames
    other = dlg.lay_combo.itemData(5)
    dlg.lay_combo.setCurrentIndex(5)
    dlg._lay_chosen(5)
    assert dlg._follow[2] == other and dlg.lay == other
    dlg.lay_combo.setCurrentIndex(0)
    dlg._lay_chosen(0)
    dlg._accept()
    r = dlg.result_data
    assert r and 'id' not in r and r['art']['follower_palette'] == 2
    assert r['art']['layout'] == dlg._fit[0][1], r['art'].get('layout')
    assets = doc.original_art_paths(78) + [r['source']['sheet']]

    def op2(d):
        copy_sheet_into_project(d.project_dir, r['sheet_abs'], r['source']['sheet'])
        d.set_original_art(78, r['art'], source=r['source'])
    assert mt._push('Dracky: new art', op2, assets=assets)
    e = doc.data['gamedata']['art']['78']
    assert e['battle']['art'].startswith('assets/art/078_') and e['follower']['palette'] == 2, e
    assert e['follower']['layout'] == r['art']['layout'], e
    from editor2.app import sprite_qt as Qs
    from editor2.core import sprite_render as SRr
    bnew, fnew = Qs.species_art(doc, 78)
    assert bnew and fnew and bnew != SRr.vanilla_battle(78), 'the tab must draw the new art'
    mt.select(8)
    mt.a_pal.setCurrentIndex(5)
    mt._prop('follower_palette', 5)
    assert doc.data['gamedata']['art']['8'] == {'follower': {'palette': 5}}, doc.data['gamedata']['art']
    mt._prop('follower_palette', doc.original_palettes(8)[1])       # back to the original value
    assert '8' not in doc.data['gamedata']['art'], 'an original value must disappear'
    files = [os.path.join(doc.project_dir, a) for a in assets]
    assert all(os.path.exists(f) for f in files)
    for _ in range(3):
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    assert not any(os.path.exists(f) for f in files[:2]), 'undo must remove the written art'
    if os.path.isdir(sdir) and not os.listdir(sdir):
        os.rmdir(sdir)
    adir = os.path.join(doc.project_dir, 'assets', 'art')
    if os.path.isdir(adir) and not os.listdir(adir):
        os.rmdir(adir)
    print('OK: Monsters tab (S107) — Dracky re-arted from the water sheet, Slime walking '
          'palette set and set back, TERRY? has no art page; undo restores everything')

    # S108 (P3.10 part 3): rename an original monster (name, default nickname,
    # description) through the tab's fields; the Dialogue tab lists the texts
    # that name it (old + new name); a new species gets its own description;
    # undo restores everything
    before = doc.dumps()
    mt.pages.setCurrentIndex(2)
    mt.select(8)
    app.processEvents()
    assert mt.a_name.text() == 'Slime' and mt.a_short.text() == 'SL', (mt.a_name.text(), mt.a_short.text())
    assert mt.a_lines[0].text() == 'The most abundant'
    n0 = int(mt.a_mentions.text().split('(')[-1].rstrip(')'))
    assert n0 > 5, mt.a_mentions.text()
    mt.a_name.setText('Goober')
    mt._text_edit('name', 'Goober')
    mt.a_short.setText('GOOB')
    mt._text_edit('nickname', 'GOOB')
    for k, t in enumerate(['A wobbly blob', "that's always", 'grinning']):
        mt.a_lines[k].setText(t)
    mt._desc_done()
    e = doc.data['gamedata']['monster_text']['8']
    assert e == {'name': 'Goober', 'nickname': 'GOOB',
                 'description': ['A wobbly blob', "that's always", 'grinning']}, e
    assert any(s_['id'] == 8 and s_['name'] == 'Goober' for s_ in doc.species_catalog())
    assert 'Goober' in mt.title.text()
    dt = w.dialogue_tab
    w._show_dialogue_for(8)
    app.processEvents()
    assert w.tabs.currentWidget() is dt and dt.table.rowCount() == n0, (dt.table.rowCount(), n0)
    assert 'Goober' in dt.monster.currentText() and 'was Slime' in dt.monster.currentText()
    dt.query.setText('$0000')
    assert dt.table.rowCount() >= 0
    dt.show_monster(None)
    dt.query.setText('Terry! Wait!')
    assert dt.table.rowCount() == 1 and dt.shown[0]['ref'] == '$0000', dt.table.rowCount()
    dt.query.clear()
    w.tabs.setCurrentWidget(mt)
    mt.select(224)
    for k, t in enumerate(['A gentle dragon', 'from the deep sea', '']):
        mt.a_lines[k].setText(t)
    mt._desc_done()
    g = next(x for x in doc.data['custom']['species'] if x['id'] == 224)
    assert g.get('description') == ['A gentle dragon', 'from the deep sea'] and \
        'description_from' not in g, g
    try:
        doc.set_monster_text(215, name='Rival')
        raise AssertionError('TERRY? must not be renamed')
    except Exception as ex:                                       # noqa: BLE001
        assert 'Iron Rule 8' in str(ex)
    for _ in range(4):
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    print('OK: Monsters tab (S108) — Slime renamed Goober / GOOB with a new description, '
          'the Dialogue tab lists its texts (old + new name), Gorbunok got its own '
          'description, TERRY? refused; undo restores everything')

    # S109 (P3.10b): the Arena tab — Starry Night: match 1 one monster (a Slime
    # at level 5), match 3's master a monster (Coatol), the G class fee 20;
    # a summon in a fighting team is refused; undo restores everything
    before = doc.dumps()
    at = w.arena_tab
    w.tabs.setCurrentWidget(at)
    app.processEvents()
    assert at.list.count() == 11, at.list.count()     # S128: row 0 = ★ Your arena
    assert at.list.item(1).text().startswith('G class') and 'fee 0' in at.list.item(1).text()
    at.list.setCurrentRow(9)
    app.processEvents()
    assert 'Starry Night' in at.title.text() and not at.fee.isVisible()
    c1 = at.cards[0]
    c1.size_btns[0].click()                          # 1 monster
    app.processEvents()
    assert doc.data['gamedata']['arena'] == {'StarryNight': {'matches': {'0': {'size': 1}}}}, \
        doc.data['gamedata'].get('arena')
    c1 = at.cards[0]
    assert '(not fought)' in c1.table.verticalHeaderItem(1).text()
    combo = c1.table.cellWidget(0, 0)
    combo.setCurrentIndex(combo.findData(8))          # a Slime
    app.processEvents()
    assert doc.data['gamedata']['enemies']['296']['species'] == 8
    c1 = at.cards[0]
    c1.table.item(0, 1).setText('5')                  # level 5
    app.processEvents()
    assert doc.data['gamedata']['enemies']['296']['level'] == 5
    at.set_master(2, {'monster': 40})
    assert doc.data['gamedata']['arena']['StarryNight']['matches']['2'] == {'master': {'monster': 40}}
    assert 'Coatol' in at.cards[2].master_btn.text()
    at.list.setCurrentRow(1)
    app.processEvents()
    assert at.fee.isVisible()
    at.fee.setValue(20)
    app.processEvents()
    assert doc.data['gamedata']['arena']['G'] == {'fee': 20}
    assert 'fee 20' in at.list.item(1).text()
    n_undo = w.session.undo.index()
    try:
        doc.set_enemy_fields(224, {'species': 217})
        raise AssertionError('a summon in a fighting arena team must be refused')
    except Exception as ex:                                       # noqa: BLE001
        assert 'Iron Rule 8' in str(ex), ex
    import editor2.app.arena_tab as ATm
    warned = []
    orig_warn = ATm.QMessageBox.warning
    ATm.QMessageBox.warning = staticmethod(lambda *a, **k: warned.append(a[1:3]))
    try:
        at.cards[0].table.item(0, 2).setText('notanumber')        # refused by the parser
        app.processEvents()
    finally:
        ATm.QMessageBox.warning = orig_warn
    assert warned and w.session.undo.index() == n_undo, (warned, w.session.undo.index(), n_undo)
    while w.session.undo.index() > 0 and doc.dumps() != before:
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    print('OK: Arena tab (S109) — Starry Night match 1 = one Lv-5 Slime, match 3 master = '
          'Coatol, G class fee 20; a summon in a team refused; undo restores everything')

    # S110 (P3.11): the Skills tab — Zap renamed Spark with a new SKIL text, MP 1,
    # party power 150-159, looks like Bang; MetalCut aimed at all foes; a flag;
    # a bad name refused without an undo step; a battle item is read-only;
    # other tabs' skill lists follow the rename; undo restores everything
    from editor2.core import skills as SKm
    import editor2.app.skills_tab as STm
    before = doc.dumps()
    warned = []
    orig_warn = STm.QMessageBox.warning
    STm.QMessageBox.warning = staticmethod(lambda *a, **k: warned.append(a[1:3]))
    st = w.skills_tab
    w.tabs.setCurrentWidget(st)
    app.processEvents()
    assert st.list.count() == 232, st.list.count()     # S111: + the 10 custom skills

    def pick(sid):
        for i in range(st.list.count()):
            if st.list.item(i).data(0x0100) == sid:
                st.list.setCurrentRow(i)
        app.processEvents()
        assert st.sid == sid, (st.sid, sid)
    pick(16)
    assert st.name.text() == 'Zap' and st.mp.value() == 10
    st.name.setText('Spark')
    st.name.editingFinished.emit()
    st.desc[0].setText('Sparks leap at')
    st.desc[1].setText('every foe')
    st.desc[2].setText('')
    st.desc[0].editingFinished.emit()
    st.mp.setValue(1)
    st.power['party'][0].setValue(150)
    st.power['party'][1].setValue(159)
    st.looks.setCurrentIndex(st.looks.findData(6))
    app.processEvents()
    e = doc.data['gamedata']['skills']['16']
    assert e['name'] == 'Spark' and e['description'] == ['Sparks leap at', 'every foe'] \
        and e['mp'] == 1 and e['looks_like'] == 6 \
        and e['record'] == {'party_min': 150, 'party_range': 9}, e
    assert 'Spark' in st.title.text() and '(was Zap)' in st.list.currentItem().text()
    pick(72)
    st.target.setCurrentIndex(st.target.findData(0x12))
    st.flags['f8_dodge'].setChecked(False)
    app.processEvents()
    assert doc.data['gamedata']['skills']['72']['record']['target_mode'] == 0x12
    assert doc.skill_detail(72)['record']['flags']['f8_dodge'] is False
    assert not warned, warned                          # no modal popped so far
    n_undo = w.session.undo.index()
    st.name.setText('Sp@rk')                           # a character the font lacks
    st.name.editingFinished.emit()
    app.processEvents()
    STm.QMessageBox.warning = orig_warn
    assert warned and w.session.undo.index() == n_undo, (warned, w.session.undo.index(), n_undo)
    pick(176)                                          # HERB, a battle item
    assert not st.sec_text.content.isEnabled() and 'read-only' in st.kind_note.text()
    assert doc.skill_names_effective()[16] == 'Spark'
    w.monsters_tab.refresh()
    assert any(c.itemText(c.findData(16)) == 'Spark' for c in w.monsters_tab.w_skill)
    assert 'Spark' in SKm.names(doc.data)[16]
    while w.session.undo.index() > 0 and doc.dumps() != before:
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    hlp = open(os.path.join(REPO, 'editor2', 'help', '54_skills.md')).read()
    for _o, _b, key, label, _h in SKm.FLAG_BITS:
        assert label in hlp, f'help 54_skills.md lacks the behaviour box "{label}"'
    print('OK: Skills tab (S110) — Zap -> Spark (SKIL text, MP 1, 150-159, looks like '
          'Bang), MetalCut at all foes, a flag; a bad name refused; items read-only; '
          'the Monsters tab follows the rename; undo restores everything')

    # S111 (P3.11c/d): custom skills + new skills + elements in the Skills tab
    from editor2.core import custom_skills as CSm
    before = doc.dumps()
    warned = []
    STm.QMessageBox.warning = staticmethod(lambda *a, **k: warned.append(a[1:3]))
    w.tabs.setCurrentWidget(st)
    st.kind.setCurrentIndex(0)
    app.processEvents()
    pick(230)                                          # Quake (built in)
    assert st.sec_params.isVisible() or not st.isVisible()
    assert not st.power['party'][0].isEnabled() and not st.sec_target.content.isEnabled()
    st.mp.setValue(12)
    st.element.setCurrentIndex(st.element.findData(2))        # Explosion
    app.processEvents()
    assert st.ann_mode.currentData() == 0xFD and st.ann_lines[0].text() == '{name} sets off'
    st.ann_lines[1].setText('a big quake!')
    st.ann_lines[1].editingFinished.emit()
    app.processEvents()
    e = doc.data['gamedata']['skills']['230']
    assert e['mp'] == 12 and e['element'] == 'Explosion' and \
        e['announce'] == ['{name} sets off', 'a big quake!'], e
    pick(224)                                          # MagicBurn: MP is code
    assert not st.mp.isEnabled()
    assert set(st.ratio_edits) == {'burn', 'damage_per_mp'}, st.ratio_edits
    st.ratio_edits['burn'].setText('1/4')              # [S111] the ratios
    st.ratio_edits['burn'].editingFinished.emit()
    app.processEvents()
    assert doc.data['gamedata']['skills']['224']['burn'] == '1/4'
    assert st.ratio_edits['burn'].text() == '1/4'
    warned_before = len(warned)
    st.ratio_edits['damage_per_mp'].setText('9')       # refused: at most 4
    st.ratio_edits['damage_per_mp'].editingFinished.emit()
    app.processEvents()
    assert 'damage_per_mp' not in doc.data['gamedata']['skills']['224']
    assert len(warned) == warned_before + 1 and 'at most 4' in str(warned[-1]), warned
    warned.pop()
    pick(230)
    assert set(st.ratio_edits) == {'ally_damage'}
    st.ratio_edits['ally_damage'].setText('1/3')       # = the original: nothing written
    st.ratio_edits['ally_damage'].editingFinished.emit()
    app.processEvents()
    assert 'ally_damage' not in doc.data['gamedata']['skills']['230']
    pick(233)
    st.ratio_edits['per_fallen'].setText('1/2')
    st.ratio_edits['per_fallen'].editingFinished.emit()
    app.processEvents()
    assert doc.data['gamedata']['skills']['233']['per_fallen'] == '1/2'
    nid = st.create_skill(16, 'Thunder')                # a NEW skill based on Zap
    app.processEvents()
    assert nid == 234 and st.sid == 234 and 'Thunder' in st.title.text(), (nid, st.sid)
    st.power['party'][0].setValue(60)
    st.power['party'][1].setValue(75)
    st.looks.setCurrentIndex(st.looks.findData(6))     # Bang's look
    st.sounds.setCurrentIndex(st.sounds.findData(15))  # Bolt's sounds
    st.element.setCurrentIndex(st.element.findData(2))
    st.learnable.setChecked(True)
    app.processEvents()
    st.prereqs.setText('Zap')
    st.prereqs.editingFinished.emit()
    app.processEvents()
    e = doc.data['gamedata']['skills']['234']
    assert e['base'] == 16 and e['name'] == 'Thunder' and e['looks_like'] == 6 and \
        e['sounds_like'] == 15 and e['element'] == 'Explosion' and \
        e['record']['party_min'] == 60 and e['learn']['prereqs'] == [16], e
    assert doc.skill_names_effective()[234] == 'Thunder'
    w.monsters_tab.refresh()
    assert any(c.findData(234) >= 0 for c in w.monsters_tab.w_skill)
    pick(30)                                           # Upper: no element to change
    assert not st.element.isEnabled()
    pick(0)                                            # Blaze -> Ice
    st.element.setCurrentIndex(st.element.findData(5))
    app.processEvents()
    assert doc.data['gamedata']['skills']['0']['element'] == 'Ice'
    assert doc.skill_detail(0)['record']['status_id'] == 6       # the AI element follows
    pick(234)
    st._delete_skill()
    app.processEvents()
    assert 234 not in doc.new_skill_ids()
    STm.QMessageBox.warning = orig_warn
    assert not warned, warned
    while w.session.undo.index() > 0 and doc.dumps() != before:
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    hlp = open(os.path.join(REPO, 'editor2', 'help', '54_skills.md')).read()
    for word in ('New skill', 'Element', 'Sounds like', 'Its own numbers', 'share of the current MP'):
        assert word in hlp, f'help 54_skills.md lacks "{word}"'
    print('OK: Skills tab (S111) — Quake MP 12 / Explosion / its own line; MagicBurn MP is '
          'code, its burn share 1/4 (9 refused); Mourn per fallen 1/2; a new skill Thunder (Zap base, Bang look, Bolt sounds, Explosion, evolves '
          'from Zap); Blaze -> Ice (AI element follows); delete; undo restores everything')

    # S112 (P3.11e): the Animations tab (a mashup with the preview) and the
    # Skills tab's Animation section; delete refused while a skill shows it;
    # undo restores everything; the help names the parts
    import editor2.app.anims_tab as ATm
    from editor2.core import battle_anims as BAm
    before = doc.dumps()
    at = w.anims_tab
    w.tabs.setCurrentWidget(at)
    app.processEvents()
    awarned = []
    a_warn, a_q = ATm.QMessageBox.warning, ATm.QMessageBox.question
    ATm.QMessageBox.warning = staticmethod(lambda *a, **k: awarned.append(a[1:3]))
    ATm.QMessageBox.question = staticmethod(lambda *a, **k: ATm.QMessageBox.Yes)
    assert at.list.count() == len(doc.animations())
    aid = at.create(0x10, 'Spark storm')               # all of Zap's steps
    app.processEvents()
    assert aid == 'spark_storm' and at.aid == aid and at.list.count() == len(doc.animations())
    n0 = at.table.rowCount()
    assert n0 == len(BAm.expand_source(0x10)) and at.box.preview.full, n0
    dlg = ATm.AddFramesDialog(at, 0x06)                # Bang: its first two steps
    dlg.steps.item(0).setSelected(True)
    dlg.steps.item(1).setSelected(True)
    new = dlg.chosen()
    assert [('from' in x) or ('sound' in x) for x in new] == [True, True], new
    at.table.clearSelection()
    at.insert_steps(new, 'two Bang steps')
    at._add_blank()
    app.processEvents()
    e = doc.animation(aid)
    assert len(e['steps']) == n0 + 3 and e['sources'] == [0x10, 0x06] and e['error'] is None, e
    sp = at.table.cellWidget(0, 1)
    sp.setValue(9)                                     # step 1 shows 9 frames
    app.processEvents()
    assert doc.animation(aid)['steps'][0]['hold'] == 8
    at.box.preview.play()
    for _ in range(5):
        at.box.preview._tick()
    assert at.box.preview.pos == 5
    at.box.preview.stop()
    # a skill shows it: Zap, on each target in turn
    w.tabs.setCurrentWidget(st)
    pick(16)
    st.anim_kind.setCurrentIndex(st.anim_kind.findData('animation'))
    app.processEvents()
    st.anim_which.setCurrentIndex(st.anim_which.findData(doc.animation(aid)['number']))
    app.processEvents()
    st.anim_motion.setCurrentIndex(st.anim_motion.findData(2))
    app.processEvents()
    assert doc.skill_presentation(16)['own'] == {'kind': 'animation', 'animation': aid,
                                                  'motion': 2}, doc.skill_presentation(16)
    assert 'your monsters' in st.anim_note.text() and st.anim_preview.preview.full
    pick(94)                                           # Scorching: the screen blinks
    st.anim_kind.setCurrentIndex(st.anim_kind.findData('effect'))
    app.processEvents()
    assert doc.skill_presentation(94)['own'] == {'kind': 'effect', 'effect': 4}
    assert doc.animation_users(aid) == [16]
    w.tabs.setCurrentWidget(at)
    app.processEvents()
    at._delete()                                       # refused: Zap shows it
    app.processEvents()
    assert awarned and 'Zap' in str(awarned[-1]) and aid in [x['id'] for x in doc.animations()]
    ATm.QMessageBox.warning, ATm.QMessageBox.question = a_warn, a_q
    STm.QMessageBox.warning = orig_warn
    while w.session.undo.index() > 0 and doc.dumps() != before:
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    hlp = open(os.path.join(REPO, 'editor2', 'help', '57_animations.md')).read()
    for word in ('Add frames', 'Add sound', 'Limits', 'Skills'):
        assert word in hlp, f'help 57_animations.md lacks "{word}"'
    assert '## Animation' in open(os.path.join(REPO, 'editor2', 'help', '54_skills.md')).read()
    print('OK: Animations tab (S112) — Spark storm = Zap + two Bang steps + a blank, a step '
          'held 9 frames, the preview plays; Zap shows it on each target, Scorching blinks '
          'the screen; delete refused while Zap shows it; undo restores everything')

    # S113 (P3.12): the Breeding tab — depth / roots read-outs, try a cross,
    # a recipe added for two exact monsters beats the general ones, a special
    # row changed and removed + brought back, a family (library) recipe,
    # the whole-table form, a generated tree; undo restores everything
    import editor2.app.breeding_tab as BTm
    before = doc.dumps()
    bt = w.breeding_tab
    w.tabs.setCurrentWidget(bt)
    app.processEvents()
    an = bt.an
    assert 'deepest' in bt.summary.text() and bt.sp_tree.topLevelItemCount() == len(an.species)
    bt.select_species(8)                                    # Slime
    app.processEvents()
    assert bt.current_species() == 8 and 'Slime' in bt.sp_title.text()
    bt.t_p1.set_value(8); bt.t_p2.set_value(8); bt.t_plus1.setValue(4)
    app.processEvents()
    assert 'KingSlime' in bt.t_out.text() and '#0' in bt.t_out.text(), bt.t_out.text()
    bt.t_plus1.setValue(0)
    app.processEvents()
    assert 'KingSlime' not in bt.t_out.text().split('<br>')[0], bt.t_out.text()
    bwarned = []
    b_warn, b_q = BTm.QMessageBox.warning, BTm.QMessageBox.question
    BTm.QMessageBox.warning = staticmethod(lambda *a, **k: bwarned.append(a[1:3]))
    BTm.QMessageBox.question = staticmethod(lambda *a, **k: BTm.QMessageBox.Yes)
    # Slime x DragonKid -> Healer (a vanilla Slime x [Dragon] row fits them too)
    van_res = an.br.resolve(8, 20).species
    assert bt._push('Recipe for Healer', lambda d: d.add_special(
        {'p1': 8, 'p2': 20, 'min_plus': 0, 'result': 9, 'plus_mod': 0}))
    app.processEvents()
    assert doc.data['gamedata']['breeding']['special']['appends'][-1] == \
        {'p1': 8, 'p2': 20, 'min_plus': 0, 'result': 9, 'plus_mod': 0}
    bt.t_p1.set_value(8); bt.t_p2.set_value(20); bt._try()
    assert bt.an.br.resolve(8, 20).species == 9 and van_res != 9 and 'Healer' in bt.t_out.text()
    # a duplicate of an existing row is refused (it could never fire)
    n_undo = w.session.undo.index()
    bt._push('dup', lambda d: d.add_special({'p1': 8, 'p2': 20, 'min_plus': 0, 'result': 4,
                                            'plus_mod': 0}))
    app.processEvents()
    assert bwarned and 'same parents' in str(bwarned[-1]) and w.session.undo.index() == n_undo
    # change vanilla row 0 (Slime x Slime +5 -> KingSlime) to need +9, remove row 1, bring back
    r0 = next(r for r in doc.special_rows() if r['src'] == ('vanilla', 0))
    assert bt._push('row 0', lambda d: d.set_special(('vanilla', 0), dict(r0, min_plus=9)))
    app.processEvents()
    assert [o for o in doc.data['gamedata']['breeding']['special']['overrides']
            if o.get('index') == 0][0]['min_plus'] == 9
    assert bt._push('rm 1', lambda d: d.remove_special(('vanilla', 1)))
    app.processEvents()
    assert bt.removed.count() == 1 and bt.removed.currentData() == 1
    bt._restore_special()
    app.processEvents()
    assert bt.removed.count() == 0
    # the family (library) recipe of Slime: [Slime] x [Slime]
    assert bt._push('fam', lambda d: d.set_family_recipe(8, 0xF0, 0xF0))
    app.processEvents()
    assert doc.data['gamedata']['breeding']['family']['8'] == {'p1': 'Slime', 'p2': 'Slime'}
    assert bt.fam_table.item(8, 4).text() == 'changed'
    # whole-table form
    bt._to_table()
    app.processEvents()
    tab = doc.data['gamedata']['breeding']['special']
    assert list(tab) == ['table'] and len(tab['table']) == len(bt.an.br.special)
    assert not bt.b_table.isEnabled() and 'whole table' in bt.summary.text()
    # a generated tree (seeded), applied as one undo step
    dlg = BTm.GenerateDialog(bt, w.session, bt.an)
    dlg.seed.setValue(7)
    dlg.max_depth.setValue(12)                              # deeper than vanilla's 9
    app.processEvents()
    assert sorted(dlg.share) == list(range(1, 13)) and 'at most' in dlg.cap_note.text()
    dlg.propose()
    from editor2.core.breeding import Analysis as _An
    from editor2.core.project import Project as _Pr
    from editor2.core import breed_gen as _BG
    _a12 = _An(_Pr(_BG.apply_to(doc.data, dlg.gd), doc.project_dir))
    assert max(d for d in _a12.depth.values() if d < 99) >= 11, _a12.histogram()
    assert dlg.b_apply.isEnabled() and 'special recipes' in dlg.report.text()
    gd = dlg.gd
    assert bt._push('Generated breeding tree', lambda d: d.apply_breeding(gd))
    app.processEvents()
    assert doc.data['gamedata']['breeding']['special']['table'] == gd['special']['table']
    assert not bt.an.unreachable() or all(s >= 221 for s in bt.an.unreachable()), bt.an.unreachable()
    BTm.QMessageBox.warning, BTm.QMessageBox.question = b_warn, b_q
    while w.session.undo.index() > 0 and doc.dumps() != before:
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    hlp = open(os.path.join(REPO, 'editor2', 'help', '58_breeding.md')).read()
    for word in ('Depth', 'Try a cross', 'Special recipes', 'Family recipes', 'Generate',
                 'whole table', 'never fires'):
        assert word in hlp, f'help 58_breeding.md lacks "{word}"'
    print('OK: Breeding tab (S113) — Slime x Slime +5 = KingSlime (#0); Slime x DragonKid -> '
          'Healer beats the general rows; a duplicate refused; row 0 needs +9; row 1 removed '
          'and brought back; Slime\'s library recipe; the whole table; a generated tree; '
          'undo restores everything')

    # S114 (P3.13a): the Encounters tab — lists (staged slot edits + Apply), a
    # project list copied, a gate floor given it + a flag variant, a room on its
    # own list with a rate; undo restores project.json exactly
    import editor2.app.encounters_tab as ETm
    et = w.encounters_tab
    doc = w.session.doc
    before = doc.dumps()
    w.tabs.setCurrentWidget(et)
    app.processEvents()
    assert et.list_w.count() == 128, et.list_w.count()
    assert et.list_w.item(1).text().startswith('1 · Gate of Villager floors 1-2'), \
        et.list_w.item(1).text()
    et.show_list(0)
    app.processEvents()
    le = et.list_ed
    assert 'Gorbunok' in le.odds.text() and 'Gate of Beginning floors 1-4' in le.uses.text(), \
        (le.odds.text(), le.uses.text())
    # staged: 10 % then 20 % — Apply only once the slots add up to 100 %
    le.table.cellWidget(0, 1).setCurrentIndex(0)            # Slime 10 % -> 0 %
    app.processEvents()
    assert not le.apply_btn.isEnabled() and 'must be exactly' in le.total.text()
    le.table.cellWidget(1, 1).setCurrentIndex(2)            # Dracky 10 % -> 20 %
    app.processEvents()
    assert le.apply_btn.isEnabled(), le.total.text()
    le._apply()
    app.processEvents()
    assert doc.data['gamedata']['encounters']['0']['slot_chance'][:2] == [0, 2]
    e_q = ETm.QInputDialog.getText
    ETm.QInputDialog.getText = staticmethod(lambda *a, **k: ('Night wolves', True))
    et.cur_list = 12
    et._new_list()
    app.processEvents()
    assert et.cur_list == 128 and doc.data['custom']['encounter_lists'][0]['id'] == 'night_wolves'
    ETm.QInputDialog.getText = e_q
    et.pages.setCurrentIndex(1)
    app.processEvents()
    et.gate_w.setCurrentRow(1)                              # Gate of Villager
    app.processEvents()
    ge = et.gate_ed
    assert ge.table.rowCount() == 4 and "the game's rule (list 1)" in ge.table.item(0, 2).text()
    c = ge.table.cellWidget(0, 1)
    c.setCurrentIndex(c.findData(128))
    app.processEvents()
    g1 = next(g for g in doc.data['custom']['gates'] if g['gate'] == 1)
    assert g1['encounters'] == {'floors': [{'floors': 1, 'list': 'night_wolves'}]}, g1
    assert ge.table.item(0, 2).text() == 'your plan'
    assert et.push('variant', lambda d: d.set_gate_variants(
        1, [{'when': [{'flag': '0x0030'}], 'floors': [{'floors': 'all', 'list': 5}]}]))
    app.processEvents()
    assert ge.which.count() == 2 and 'when' in ge.which.itemText(1)
    ge.which.setCurrentIndex(1)
    app.processEvents()
    assert all(ge.table.item(i, 2).text() == 'this variant' for i in range(4))
    et.pages.setCurrentIndex(2)
    app.processEvents()
    k = et.room_ids.index('dusk_mirror')
    et.room_w.setCurrentRow(k)
    app.processEvents()
    re_ = et.room_ed
    re_.mode_btn['own'].setChecked(True)
    app.processEvents()
    re_.rate_on.setChecked(True)
    app.processEvents()
    re_.rate.setCurrentIndex(7)
    app.processEvents()
    dm = next(r for r in doc.data['custom']['rooms'] if r['id'] == 'dusk_mirror')
    assert dm['encounters'] == {'enabled': True, 'list': 0, 'rate': 7}, dm['encounters']
    assert 'steps between battles' in re_.rate_steps.text()
    from editor2.core import compiler as Cc                # the edits compile
    import tempfile
    import shutil as _sh
    td = tempfile.mkdtemp()
    _sh.copytree(doc.project_dir, os.path.join(td, 'p'), ignore=_sh.ignore_patterns('build'))
    open(os.path.join(td, 'p', 'project.json'), 'w').write(doc.dumps())
    outs, _pp, _ww = Cc.compile_project(os.path.join(td, 'p'), REPO)
    assert 'EncGatePlan_01' in outs['patches/bank_076.asm'] and \
        '; list 128: night_wolves' in outs['patches/bank_076.asm']
    while w.session.undo.index() > 0 and doc.dumps() != before:
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    hlp = open(os.path.join(REPO, 'editor2', 'help', '59_encounters.md')).read()
    for word in ('Lists', 'Real chance', 'Apply', 'Gates', 'Flag variants', 'Rooms',
                 'Its own list', 'Shared'):
        assert word in hlp, f'help 59_encounters.md lacks "{word}"'
    print('OK: Encounters tab (S114) — list 0 staged to 0/20 % and applied; a copy of list 12 '
          'as list 128; Villager floor 1 on it + a flag variant; dusk_mirror on its own list at '
          'rate 7; compiles; undo restores everything')

    # S115 (ROADMAP NG1): new gates — Gates tab New gate… (a copy of Memories, 4
    # floors), rename, the Encounters tab lists it, the Rooms tab puts a gate
    # entrance on a cell; compiles; Delete gate; undo restores project.json
    import editor2.app.gates_tab as GTm
    gt = w.gates_tab
    doc = w.session.doc
    before = doc.dumps()
    w.tabs.setCurrentWidget(gt)
    app.processEvents()
    n0 = gt.list.count()
    assert n0 == 32, n0
    e_exec, e_vals = GTm.NewGateDialog.exec, GTm.NewGateDialog.values
    GTm.NewGateDialog.exec = lambda self: GTm.QDialog.Accepted
    GTm.NewGateDialog.values = lambda self: (3, 'Ember Gate', 4)
    gt._new_gate()
    GTm.NewGateDialog.exec, GTm.NewGateDialog.values = e_exec, e_vals
    app.processEvents()
    assert gt.list.count() == 33 and 'NEW' in gt.list.item(32).text(), gt.list.item(32).text()
    assert gt.list.currentRow() == 32 and gt._btn_delete.isEnabled()
    assert 'no entrance yet' in gt.sub.text(), gt.sub.text()
    assert doc.data['custom']['gates'][-1] == {'gate': 32, 'copy_of': 3, 'name': 'Ember Gate',
                                               'floors': 4}, doc.data['custom']['gates']
    e_t = GTm.QInputDialog.getText
    GTm.QInputDialog.getText = staticmethod(lambda *a, **k: ('Cinder Gate', True))
    gt._rename_gate()
    GTm.QInputDialog.getText = e_t
    app.processEvents()
    assert doc.gate_name(32) == 'Cinder Gate' and 'Cinder Gate' in gt.list.item(32).text()
    et = w.encounters_tab
    w.tabs.setCurrentWidget(et)
    et.refresh() if hasattr(et, 'refresh') else None
    app.processEvents()
    et.pages.setCurrentIndex(1)
    app.processEvents()
    assert et.gate_ids[-1] == 32 and 'NEW (copy of gate 3)' in et.gate_w.item(32).text()
    rt = w.rooms_tab
    w.tabs.setCurrentWidget(rt)
    rt.open_node(('room', 'dusk_mirror'))
    app.processEvents()
    import PySide6.QtWidgets as QW
    q_gi = QW.QInputDialog.getItem
    QW.QInputDialog.getItem = staticmethod(lambda _p, _t, _l, items, *a, **k: (items[0], True))
    rt._add_gate_entrance((2, 3))
    QW.QInputDialog.getItem = q_gi
    app.processEvents()
    ents = doc.gate_entrances(32)
    assert len(ents) == 1 and ents[0][3]['gate_flag'] == 1 and ents[0][3]['dest'] == 'gate:32', ents
    w.tabs.setCurrentWidget(gt)
    gt.refresh()
    app.processEvents()
    gt.list.setCurrentRow(32)
    app.processEvents()
    assert 'entrance:' in gt.sub.text(), gt.sub.text()
    from editor2.core import compiler as Cc                # the edits compile
    td = tempfile.mkdtemp()
    _sh.copytree(doc.project_dir, os.path.join(td, 'p'), ignore=_sh.ignore_patterns('build'))
    open(os.path.join(td, 'p', 'project.json'), 'w').write(doc.dumps())
    outs, _pp, _ww = Cc.compile_project(os.path.join(td, 'p'), REPO)
    assert 'NEW_GATE_LEN EQU 1' in outs['patches/bank_076.asm'] and \
        'gate 32 Cinder Gate' in outs['patches/bank_076.asm']
    e_q = GTm.QMessageBox.question
    GTm.QMessageBox.question = staticmethod(lambda *a, **k: GTm.QMessageBox.Yes)
    gt._delete_gate()
    GTm.QMessageBox.question = e_q
    app.processEvents()
    assert gt.list.count() == 32 and not doc.gate_entrances(32)
    while w.session.undo.index() > 0 and doc.dumps() != before:
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    hlp = open(os.path.join(REPO, 'editor2', 'help', '60_gates.md')).read()
    for word in ('New gate', 'copy of', 'Gate entrance here', 'Delete'):
        assert word in hlp, f'help 60_gates.md lacks "{word}"'
    print('OK: New gates (S115) — Gates tab New gate (copy of Memories, 4 floors) as gate 32, '
          'renamed; listed on the Encounters tab; a gate entrance on dusk_mirror (2,3); '
          'compiles; Delete gate removes it and its entrance; undo restores everything')

    # S116 (ROADMAP P3.13b): the Music tab — the song list (the game's sounds,
    # DWM2, MIDI library, the project's), rename, Add to the project, a room song,
    # a gate's songs, a battle setting, a fight; the preview renders through the
    # game's engine (headless: no audio device, the renderer is called directly);
    # compiles; undo restores project.json exactly
    mt = w.music_tab
    doc = w.session.doc
    before = doc.dumps()
    w.tabs.setCurrentWidget(mt)
    app.processEvents()
    kinds = {r['kind'] for r in mt._rows()}
    assert kinds == {'project', 'game', 'effect', 'dwm2', 'midi'}, kinds
    n_game = sum(1 for r in mt._rows() if r['kind'] in ('game', 'effect'))
    assert n_game >= 85 and mt.ids_bar.value() == 12, (n_game, mt.ids_bar.value())
    mt.filter.setCurrentIndex(mt.filter.findData('dwm2'))
    app.processEvents()
    assert mt.song_list.count() == 31, mt.song_list.count()
    mt.song_list.setCurrentRow(3)                      # BGM #04: four channels
    app.processEvents()
    assert mt.cur['lib'] == 'dwm2_bgm04' and '4 channel(s)' in mt.info.text() and \
        'noise' in mt.info.text(), mt.info.text()
    pcm = mt._renderer(mt.cur).render(seconds=1.0)
    assert pcm.shape[1] == 2 and len(pcm) > 30000 and abs(pcm).max() > 1000, pcm.shape
    mt.name_e.setText('Drum song')
    mt._rename()
    mt._add_song()
    app.processEvents()
    assert doc.song_name('dwm2_bgm04') == 'Drum song' and \
        doc.project_song('dwm2_bgm04') is not None and mt.cur['kind'] == 'project', mt.cur
    assert mt.ids_bar.value() == 16, mt.ids_bar.value()
    mt.filter.setCurrentIndex(mt.filter.findData('game'))
    app.processEvents()
    r27 = next(i for i, r in enumerate(mt.shown) if r['key'] == '$27')
    mt.song_list.setCurrentRow(r27)
    app.processEvents()
    assert 'battle start' in mt.info.text() and '4 channel(s)' in mt.info.text(), mt.info.text()
    mt.push('room', lambda d: d.set_room_music_id(0x01, 'dwm2_bgm04'))
    mt.push('gate', lambda d: d.set_gate_music(2, floors='dwm2_bgm04', battles=0x2B))
    mt.push('battle', lambda d: d.set_battle_music('starry', 'dwm2_bgm04'))
    mt.push('fight', lambda d: d.set_fight_music(325, 0x31))
    mt.refresh()
    app.processEvents()
    gl = [mt.gates_t.cellWidget(i, 1).currentData() for i in range(mt.gates_t.rowCount())]
    assert gl[2] == 'dwm2_bgm04' and mt.fights_t.rowCount() == 1, (gl[:4], mt.fights_t.rowCount())
    rows = [mt.rooms_t.item(i, 0).text() for i in range(mt.rooms_t.rowCount())]
    i01 = next(i for i, t in enumerate(rows) if t.startswith('$01 '))
    assert mt.rooms_t.cellWidget(i01, 2).currentData() == 'dwm2_bgm04'
    from editor2.core import compiler as Cc                # the edits compile
    td = tempfile.mkdtemp()
    _sh.copytree(doc.project_dir, os.path.join(td, 'p'), ignore=_sh.ignore_patterns('build'))
    open(os.path.join(td, 'p', 'project.json'), 'w').write(doc.dumps())
    outs, pp, _ww = Cc.compile_project(os.path.join(td, 'p'), REPO)
    P = pp.music_plan()
    assert P.room_bgm[0x01] == P.song_ids['dwm2_bgm04'] and P.gate_battle[2] == 0x2B and \
        P.fights == [(325, 0x31)] and P.chan_table[P.song_ids['dwm2_bgm04'] - 0x9E] == 4
    while w.session.undo.index() > 0 and doc.dumps() != before:
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    hlp = open(os.path.join(REPO, 'editor2', 'help', '61_music.md')).read()
    for word in ('Import MIDI', 'Add to the project', 'Starry Night final', 'battles here',
                 'numpy', '95 song ids'):
        assert word in hlp, f'help 61_music.md lacks "{word}"'
    print('OK: Music tab (S116) — every kind of song listed; DWM2 BGM #04 shows 4 channels '
          '(noise) and renders through the game engine; renamed + added (16 ids); $27 = the '
          'battle start; room / gate / Starry / fight songs compile; undo restores everything')

    # S116b: the song player (user report, macOS: "stopped early after a few seconds,
    # replay froze completely"). A fake sink (headless: no audio device) with a buffer
    # SMALLER than the old 0.25 s feed chunk and partial writes must keep the song
    # going; replay / stop discard (reset), never drain (stop); a stream the system
    # stops (device change) is restarted and the song continues.
    import time as _time
    from editor2.app.music_tab import SongPlayer

    class _Nm:
        def __init__(self, n):
            self.name = n

    class FakeSink:
        def __init__(self, cap):
            self.cap, self.fill, self.calls, self.st, self.got = cap, 0, [], 'ActiveState', 0

        def bytesFree(self):
            return self.cap - self.fill

        def bufferSize(self):
            return self.cap

        def state(self):
            return _Nm(self.st)

        def error(self):
            return _Nm('IOError' if self.st == 'StoppedState' else 'NoError')

        def reset(self):
            self.calls.append('reset')
            self.fill, self.st = 0, 'StoppedState'

        def stop(self):
            self.calls.append('stop')

        def start(self):
            self.calls.append('start')
            self.st = 'ActiveState'
            return self

        def write(self, b):
            n = min(len(b), self.cap - self.fill, 1000)       # partial writes
            self.fill += n
            self.got += n
            return n

        def consume(self, n):
            self.fill = max(0, self.fill - n)

        def deleteLater(self):
            pass

    fake = FakeSink(int(48000 * 0.1) * 4)                  # 0.1 s buffer < 0.25 s
    pl = SongPlayer()

    def _fake_sink():
        pl.sink, pl.rate, pl._dev_id = fake, 48000, b'fake'
    pl._ensure_sink = _fake_sink
    from editor2.core import music_preview as MPv
    pl.play(MPv.Renderer.vanilla(mt._rom(), 0x09))
    pl.timer.stop()                                         # the test drives the ticks
    for _ in range(150):                                    # 3 s of device time
        fake.consume(48000 * 4 // 50)
        pl._feed()
    assert pl.playing and pl.r.frames >= int(59.7 * 2.9), pl.r.frames
    assert fake.got >= 48000 * 4 * 2.9, fake.got
    pl.play(MPv.Renderer.vanilla(mt._rom(), 0x09))          # replay
    pl.timer.stop()
    assert fake.calls[-2:] == ['reset', 'start'] and 'stop' not in fake.calls, fake.calls
    f0 = pl.r.frames
    fake.st = 'StoppedState'                                # the system stopped the stream
    pl._feed()
    t_end = _time.time() + 1.0
    while _time.time() < t_end and fake.calls.count('start') < 3:
        app.processEvents()
        _time.sleep(0.01)
    pl.timer.stop()
    for _ in range(50):
        fake.consume(48000 * 4 // 50)
        pl._feed()
    assert fake.calls.count('start') == 3 and pl.playing and pl.r.frames >= f0 + 50, \
        (fake.calls, pl.r.frames, f0)
    pl.stop()
    assert not pl.playing and 'stop' not in fake.calls, fake.calls
    print('OK: song player (S116b) — a 0.1 s buffer with partial writes keeps the song '
          'going (3 s); replay = reset + start (no draining stop); a stream the system '
          'stops is restarted and the song continues; stop discards')

    # S117 (ROADMAP NG2 + P3.13c): a gate entrance gets the spinning swirl (shown
    # while the gate is not cleared) and the still swirl picture; a vanilla portal
    # led to another gate; an NPC made a shopkeeper; the Shops tab — a new shop,
    # items, a price; compiles; undo restores project.json
    import editor2.app.shops_tab as STm
    import editor2.app.rooms.tab as RTm
    import PySide6.QtWidgets as QW
    doc = w.session.doc
    before = doc.dumps()
    rt = w.rooms_tab
    w.tabs.setCurrentWidget(rt)
    rt.open_node(('room', 'dusk_mirror'))
    app.processEvents()
    q_gi = QW.QInputDialog.getItem
    QW.QInputDialog.getItem = staticmethod(
        lambda _p, _t, _l, items, *a, **k: (next(i for i in items if i.startswith(' 2 ')), True))
    rt._add_gate_entrance((2, 3))
    QW.QInputDialog.getItem = q_gi
    app.processEvents()
    sw = doc.gate_swirls(2)
    assert len(sw) == 1 and (sw[0][3]['x'], sw[0][3]['y']) == (2, 3) and \
        sw[0][3]['swirl_of'] == 2, sw
    assert 'Gate entrance' in rt.status_line.text() and 'swirl' in rt.status_line.text(), \
        rt.status_line.text()
    QW.QInputDialog.getItem = staticmethod(
        lambda _p, _t, _l, items, *a, **k: (next(i for i in items if i.startswith(' 5 ')), True))
    rt._portal_to_gate({'mapID': 0x24, 'screen': 0, 'x': 2, 'y': 2})
    QW.QInputDialog.getItem = q_gi
    app.processEvents()
    pr = doc.portal_redirects()
    assert len(pr) == 1 and pr[0][1]['dest'] == 'gate:5', pr
    gt = w.gates_tab
    gt.refresh()
    gt.list.setCurrentRow(5)
    app.processEvents()
    assert 'cleared' in gt.sub.text(), gt.sub.text()
    room = doc.room('dusk_mirror')
    cmd = rt._npc_op('Add NPC', lambda d, r, k, st: d.add_npc(r, k, st, 6, 4, 0x06))
    rt._after_npc_edit(cmd.result)
    app.processEvents()
    assert rt._sel_npc == cmd.result
    STm.QInputDialog.getText = staticmethod(lambda *a, **k: ('Mirror stall', True))
    st = w.shops_tab
    w.tabs.setCurrentWidget(st)
    st.refresh()
    app.processEvents()
    assert st.list.count() == 5 and st.prices.rowCount() == 43, (st.list.count(),
                                                                 st.prices.rowCount())
    st._new_shop()
    STm.QInputDialog.getText = QW.QInputDialog.getText
    app.processEvents()
    assert st.list.count() == 6 and st.current()['key'] == 'mirror_stall', st.current()
    assert 'nobody sells' in st.where.text(), st.where.text()
    st.pick.setCurrentIndex(st.pick.findData(29))              # ...
    st._add_item()
    st.items.setCurrentRow(1)
    st._move(-1)
    app.processEvents()
    assert st.current()['items'] == [29, 1], st.current()['items']
    st.prices.item(0, 1).setText('12')                         # Herb costs 12
    app.processEvents()
    assert doc.data['gamedata']['items'] == {'1': {'price': 12}}, doc.data.get('gamedata')
    w.tabs.setCurrentWidget(rt)
    rt.open_node(('room', 'dusk_mirror'))
    app.processEvents()
    rt._after_npc_edit(cmd.result)
    d_exec = RTm.QDialog.exec

    def _pick_shop(dlg):
        cb = dlg.findChild(QW.QComboBox)
        cb.setCurrentIndex(cb.findData('mirror_stall'))
        dlg.findChild(QW.QPlainTextEdit).setPlainText('MIRROR STALL.\nLook around!')
        return QW.QDialog.Accepted
    RTm.QDialog.exec = _pick_shop
    rt._npc_shop()
    RTm.QDialog.exec = d_exec
    app.processEvents()
    room = doc.room('dusk_mirror')
    so = doc.shopkeeper_of(room, rt.key, rt.state_idx, cmd.result)
    assert so == ('mirror_stall', [['MIRROR STALL.', 'Look around!']]), so
    w.tabs.setCurrentWidget(st)
    st.refresh()
    app.processEvents()
    st.list.setCurrentRow(5)
    app.processEvents()
    assert 'Sold by:' in st.where.text(), st.where.text()
    from editor2.core import compiler as Cc                # the edits compile
    td = tempfile.mkdtemp()
    _sh.copytree(doc.project_dir, os.path.join(td, 'p'), ignore=_sh.ignore_patterns('build'))
    open(os.path.join(td, 'p', 'project.json'), 'w').write(doc.dumps())
    outs, _pp, _ww = Cc.compile_project(os.path.join(td, 'p'), REPO)
    b77 = outs['patches/bank_077.asm']
    assert 'SHOP_COUNT EQU 6' in b77 and 'Mirror stall' in b77 and '$1d, $01, $ff' in b77, b77
    assert 'price 12' in outs['patches/bank_003.asm']
    b60 = outs['patches/bank_060.asm']
    assert 'VanillaNPCExtTable:' in b60 and 'is CLEAR' in b60, 'no swirl conditions'
    e_q = STm.QMessageBox.question
    STm.QMessageBox.question = staticmethod(lambda *a, **k: STm.QMessageBox.Yes)
    st._delete()
    STm.QMessageBox.question = e_q
    app.processEvents()
    assert st.list.count() == 5 and doc.shopkeeper_of(doc.room('dusk_mirror'), rt.key,
                                                       rt.state_idx, cmd.result) is None
    # S117b: the sprite limits show on the Rooms tab banner (3 NPCs on one row)
    w.tabs.setCurrentWidget(rt)
    rt.open_node(('room', 'dusk_mirror'))
    app.processEvents()
    for x in (1, 3, 5):
        rt._npc_op('Add NPC', lambda d, r, k, st_, x=x: d.add_npc(r, k, st_, x, 6, 0x06))
    rt._show()
    app.processEvents()
    assert 'Sprite limit: row 6 has' in rt.banner.text(), rt.banner.text()
    while w.session.undo.index() > 0 and doc.dumps() != before:
        w.session.undo.undo()
    app.processEvents()
    assert doc.dumps() == before, 'undo must restore project.json exactly'
    for fn, words in (('60_gates.md', ('swirl', 'cleared', 'Lead this portal')),
                      ('62_shops.md', ('Shopkeeper', 'New shop', 'Shops pay', '20 items')),
                      ('30_flags.md', ('gate:', '$1000'))):
        hlp = open(os.path.join(REPO, 'editor2', 'help', fn)).read()
        for word in words:
            assert word in hlp, f'help {fn} lacks "{word}"'
    print('OK: Swirls + shops (S117) — a gate entrance gets its swirl (shown until gate 2 is '
          'cleared); the Villager / Talisman room portal (2,2) led to gate 5; the Shops tab makes "Mirror '
          'stall" (2 items, reordered), Herb at 12; an NPC sells it with its own greeting; '
          'compiles (6 lists, swirl conditions); Delete unbinds it; the sprite-limit banner (S117b); '
          'undo restores everything')

    # S118 (P3.8 part A): the Cutscenes tab — every scene, the storyboard, the
    # model picture, and (with PyBoy + the ROM) the Playback window playing the
    # intro chain in the real game with auto text
    ct = w.cutscenes_tab
    w.tabs.setCurrentWidget(ct)
    app.processEvents()
    if ct.cat is None:
        ct.load()
    if ct.cat is None:
        print('SKIP: Cutscenes tab needs data/DWM-original.gbc')
    else:
        tops = [ct.tree.topLevelItem(i).text(0) for i in range(ct.tree.topLevelItemCount())]
        assert tops[0].startswith('Your cutscenes') and tops[1].startswith('Chains') and \
            'Your rooms' in tops and 'Game rooms' in tops, tops
        game = ct.tree.topLevelItem(3)
        assert game.childCount() >= 40, game.childCount()
        chain = ct.tree.topLevelItem(1).child(0)
        ct.tree.setCurrentItem(chain)
        app.processEvents()
        rows = [ct.steps.item(i).text() for i in range(ct.steps.count())]
        assert len(rows) > 80 and any('walks left 2 tiles' in r for r in rows), rows[:10]
        assert any('Milayou:Terry!' in r for r in rows), 'the bedtime text'
        assert 'starts by' in ct.head.text(), ct.head.text()
        # S118e (user: "Milayou and Terry … both are in wrong positions"): the
        # bedtime scene is played from a new game itself
        assert ct._recipe.action == 'newgame', ct._recipe
        assert ct._model_picture(10).width() == 320
        ct.search.setText('Watabou')
        app.processEvents()
        n_hits = sum(ct.tree.topLevelItem(3).child(i).childCount()
                     for i in range(ct.tree.topLevelItem(3).childCount()))
        ct.search.setText('')
        app.processEvents()
        chain = ct.tree.topLevelItem(1).child(0)
        assert n_hits > 0, 'search finds Watabou scenes'
        for word in ('Play', 'Auto text', 'intro', 'pyboy', 'save file'):
            assert word in open(os.path.join(REPO, 'editor2', 'help', '63_cutscenes.md')).read(), word
        from editor2.core import playback as PB
        if PB.available()[0]:
            ct.tree.setCurrentItem(chain)
            app.processEvents()
            ct.play()
            pw = ct.playback
            pw.speed_box.setCurrentIndex(3)          # 8x (no sound) keeps the test short
            import time as _t
            t0 = _t.time()
            def frames():
                return pw.st.get('frames', 0) if pw.st else 0
            while _t.time() - t0 < 30 and (pw.eng is None or frames() < 1500):
                app.processEvents()
                _t.sleep(0.002)
            assert pw.eng is not None and frames() >= 1500, 'playback did not run'
            assert pw.st['map'] == 0x2F, pw.st
            assert ct.steps.currentRow() > 5, 'the storyboard follows the game'
            # the game runs in its own process: a game that stops answering is
            # killed and reported, the editor keeps going (Restart starts it again)
            import signal
            pw.toggle()                              # pause
            os.kill(pw.eng.proc.pid, signal.SIGSTOP)
            t1 = _t.time()
            pw._run_frames(1)
            for _ in range(20):
                app.processEvents()
            assert pw.hung and pw.eng is None, 'a hung game is reported'
            assert _t.time() - t1 < 15
            pw.restart()
            t0 = _t.time()
            while _t.time() - t0 < 30 and (pw.eng is None or frames() < 300):
                app.processEvents()
                _t.sleep(0.002)
            assert pw.eng is not None and not pw.hung and frames() >= 300, 'restart after a hang'
            pw.close()
            app.processEvents()
            # ▶ From this step: the steps before it run fast, then normal play
            ct.tree.setCurrentItem(chain)
            app.processEvents()
            ct.steps.setCurrentRow(40)
            target = ct.cur.scene.steps[40].pos
            ct.play(from_step=True)
            pw = ct.playback
            assert pw.skip_to == target
            t0 = _t.time()
            while _t.time() - t0 < 60 and (pw.eng is None or pw.skipping or not pw.st):
                app.processEvents()
                _t.sleep(0.002)
            assert not pw.skipping, 'the fast run reached the chosen step'
            from editor2.core import cutscenes as CS2
            cur = CS2.step_at_counter(ct.cur.scene.script, pw.st['pos'])
            assert cur is not None and cur.pos >= target, (cur, target)
            assert pw.speed_box.currentData() == 8 or pw.clock.isActive() or pw.player
            # S118e: View → Mute game playback overrides every window's Sound box
            was = w.a_mute.isChecked()
            w.a_mute.setChecked(True)
            app.processEvents()
            assert not pw.c_sound.isEnabled() and (pw.player is None or not pw.player.playing)
            w.a_mute.setChecked(False)
            app.processEvents()
            assert pw.c_sound.isEnabled()
            w.a_mute.setChecked(was)
            # Step ▸▸ / ◂ Step back (S118b: step through the scene step by step)
            f0 = pw.st.get('frames', 0)
            pw.step_script()
            pw.step_script()
            app.processEvents()
            log = pw.log.toPlainText()
            assert log.count('▸▸ after') + log.count('no new step') + \
                log.count('has ended') >= 2, log[-400:]
            f2 = pw.st.get('frames', 0)
            pw.step_script(back=True)
            assert pw.st.get('frames', 0) <= f2 and not pw.clock.isActive()
            assert f2 >= f0
            pw.close()
            app.processEvents()
            # S118c (user: "selecting a script then clicking on another … after
            # playing a GreatTree cutscene — new cutscene doesnt appear"): after a
            # playback, other scenes still open; every 7th scene of the whole
            # tree opens without an error and shows its own steps
            errs = []
            old_hook = sys.excepthook
            sys.excepthook = lambda t, v, tb: errs.append(f'{t.__name__}: {v}')
            ct.only_moves.setChecked(False)
            app.processEvents()
            refs = []

            def _walk(it):
                for i in range(it.childCount()):
                    c = it.child(i)
                    if isinstance(c.data(0, ROLE_CS), SceneRef_CS):
                        refs.append(c)
                    _walk(c)
            from editor2.app.cutscenes_tab import ROLE as ROLE_CS
            from editor2.app.cutscenes_tab import SceneRef as SceneRef_CS
            for i in range(ct.tree.topLevelItemCount()):
                _walk(ct.tree.topLevelItem(i))
            saved_auto = ct._auto_record
            ct._auto_record = lambda: False
            for c in refs[::7]:
                ct.tree.setCurrentItem(c)
                app.processEvents()
                ref = c.data(0, ROLE_CS)
                assert ct.cur is ref and ct.steps.count() == len(ref.scene.steps), c.text(0)
            ct._auto_record = saved_auto
            sys.excepthook = old_hook
            assert not errs, errs[:3]
            assert len(refs) > 500, len(refs)
            ct.only_moves.setChecked(True)
            app.processEvents()
            # S118f (user: "I want everything interpretable"): no step of any game
            # script is left as a bare address / number
            import re as _re
            from editor2.core import script_ops as SO2
            from editor2.app.cutscenes_tab import TextCtx as _TC
            raw = []
            for _m in ct.cat.map_types():
                _ctx = _TC(ct.cat.text, {}, {}, cat=ct.cat, vanilla=ct.cat)
                _ctx.bank = CS2.script_bank(_m)
                for _sc in ct.cat.scripts(_m):
                    for _st in (_sc.steps.values() if _sc else []):
                        _t = SO2.sentence(_st.code, _st.params, _ctx, _st.target)
                        if ('not yet named' in _t or 'game screen' in _t or 'slot byte' in _t
                                or _re.search(r'\(\w+ \$[0-9A-F]{4}\)$', _t)):
                            raw.append(_t)
            assert not raw, raw[:5]
            _ctx = _TC(ct.cat.text, {}, {}, cat=ct.cat, vanilla=ct.cat)
            assert SO2.sentence(0x12, (0xD92B, 0), _ctx).startswith('Room state of Castle screen 1')
            assert 'arena class G won' in SO2.sentence(0x03, (0x30,), _ctx)
            # the egg appraiser's plain talk is not a "moving" scene; the GreatTree
            # cliff scene plays in the room state the Castle leaves (S118 user report)
            egg = [s for s in ct.cat.scenes(0x09) if s.entry == 20][0]
            assert not CS2.moves(egg)
            cliff = [s for s in ct.cat.scenes(0x01) if s.entry == 202][0]
            assert ct.cat.recipe(cliff, 0x01).room_step == 2
            ct.shutdown()
            print('OK: Cutscenes (S118) — chains / your rooms / game rooms, the intro storyboard '
                  f'({len(rows)} steps), search, model picture; Playback ran the intro in the '
                  f'game ({1500}+ frames, storyboard highlight); a hung game is killed, Restart works; From this step; Step ▸▸ / back')
        else:
            print('OK: Cutscenes (S118) — storyboard (Playback SKIPPED: no PyBoy)')
        s119_cutscene_editor(app, w, ct)

    if do_rom:
        from editor2.app.build_worker import BuildWorker  # noqa: E402
        results = []
        worker = BuildWorker(REPO, w.project_path)
        worker.log.connect(lambda s: print('  |', s))
        worker.finished_build.connect(results.append)
        worker.start()
        worker.wait()
        app.processEvents()
        res = results[0]
        assert res.ok, f'GUI build failed: {res.error}'
        want = pinned_md5()
        assert res.rom_md5 == want, \
            f'GUI build md5 {res.rom_md5} != pinned {want}'
        print(f'OK: GUI build byte-identical to pin {want}')
    print('PASS')


if __name__ == '__main__':
    main()
