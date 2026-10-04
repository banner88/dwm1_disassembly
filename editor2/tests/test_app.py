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
        assert tops[0].startswith('Chains') and 'Your rooms' in tops and 'Game rooms' in tops, tops
        game = ct.tree.topLevelItem(2)
        assert game.childCount() >= 40, game.childCount()
        chain = ct.tree.topLevelItem(0).child(0)
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
        n_hits = sum(ct.tree.topLevelItem(2).child(i).childCount()
                     for i in range(ct.tree.topLevelItem(2).childCount()))
        ct.search.setText('')
        app.processEvents()
        chain = ct.tree.topLevelItem(0).child(0)
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
                    if c.data(0, ROLE_CS) is not None:
                        refs.append(c)
                    _walk(c)
            from editor2.app.cutscenes_tab import ROLE as ROLE_CS
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
