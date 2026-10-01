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
    print(f'OK: Help tab — {len(topics)} topics, search, help revision == {EDITOR_REVISION}')

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
    assert at.list.count() == 10, at.list.count()
    assert at.list.item(0).text().startswith('G class') and 'fee 0' in at.list.item(0).text()
    at.list.setCurrentRow(8)
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
    at.list.setCurrentRow(0)
    app.processEvents()
    assert at.fee.isVisible()
    at.fee.setValue(20)
    app.processEvents()
    assert doc.data['gamedata']['arena']['G'] == {'fee': 20}
    assert 'fee 20' in at.list.item(0).text()
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
