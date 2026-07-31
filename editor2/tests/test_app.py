#!/usr/bin/env python3
"""test_app.py — walking-skeleton smoke test (S72), headless-safe.

Runs the REAL app code offscreen (QT_QPA_PLATFORM=offscreen): opens the
example project, checks the room list populated, drives a Build through
the app's worker code path, and (with --rom) asserts the ROM md5 equals
the pinned compat reference from editor2/tests/test_compiler.py — proving
GUI build == CLI build == hand-staged overlay, byte-identical.

SKIPs (exit 0 with a message) when PySide6 is not installed, so CI without
Qt stays green — the same ROM-tolerant posture as verify_integrity check 5.
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
    print(f'OK: window up, {n} rooms listed, Build enabled')

    # Room view: if a build exists, the selected room must render to pixels.
    from editor2.core.render import find_build            # noqa: E402
    if find_build(w.project_path):
        app.processEvents()
        pm = w.room_view.canvas.pixmap()
        assert pm is not None and not pm.isNull() and pm.width() > 100, \
            'room view produced no pixmap from the existing build'
        # placeholder room must NOT render (text instead of pixmap)
        for i in range(n):
            if 'placeholder' in w.room_list.item(i).text():
                w.room_list.setCurrentRow(i)
                app.processEvents()
                pm2 = w.room_view.canvas.pixmap()
                assert pm2 is None or pm2.isNull(), \
                    'placeholder room unexpectedly rendered'
                break
        w.room_list.setCurrentRow(0)
        app.processEvents()
        print('OK: room view renders from the existing build '
              '(placeholder rooms correctly skipped)')
    else:
        print('NOTE: no existing build — room-view render check skipped '
              '(run with --rom to build first)')

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
