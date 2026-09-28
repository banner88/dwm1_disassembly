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
