"""selftest.py — the packaged app checks itself (S171, ROADMAP P3.17).

    "DWM1 Editor.app/Contents/MacOS/DWM1 Editor" --selftest [--rom PATH] [--quick]

Run by tools/package_app.py --selftest and by the GitHub build on a macOS machine
(.github/workflows/editor-app.yml). Everything runs with the app's OWN Python, Qt,
RGBDS and SameBoy, in a temporary data folder (launch.py), offscreen:

  1. RGBDS: the app's rgbasm is the one found, and it is v0.6.1;
  2. the original ROM: --rom PATH, else assembled from the app's own clean disassembly
     with the app's RGBDS — it must be the original (MD5 1ca6579…, the byte-perfect rule);
  3. the example project builds (tools/build_project.py, the editor's compiler + builder,
     no `make`) to the regression pin of editor2/tests/test_compiler.py (REFERENCE_MD5);
  4. the window: MainWindow opens the example project, every tab is shown, no stray
     window (qt_safe.StrayWindowGuard), QtMultimedia loads;
  5. the game for Playback: a playback-server process (sys.executable) opens the ROM
     (PyBoy) and answers;
  6. Play: the bundled SameBoy is what Build → Play would start (macOS).
Prints one line per check; the exit code is the number of failed checks.
"""

import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def _md5(p):
    with open(p, 'rb') as f:
        return hashlib.md5(f.read()).hexdigest()


class Checks:
    def __init__(self):
        self.failed = 0

    def ok(self, cond, what, detail=''):
        print(('PASS ' if cond else 'FAIL ') + what + (f' — {detail}' if detail else ''),
              flush=True)
        if not cond:
            self.failed += 1
        return cond


def main(argv=()):
    argv = list(argv)
    rom_arg = argv[argv.index('--rom') + 1] if '--rom' in argv else None
    quick = '--quick' in argv
    os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
    C = Checks()
    tmp = tempfile.mkdtemp(prefix='dwm1-selftest-work-')
    t0 = time.time()
    print(f'DWM1 Editor self-check — workspace {REPO}', flush=True)

    # 1. RGBDS
    from editor2.core import builder as B
    try:
        env = B.check_toolchain(None)
        found = shutil.which('rgbasm', path=env.get('PATH'))
        own = os.environ.get('DWM_RGBDS_DIR')
        C.ok(own is not None and found is not None
             and os.path.dirname(found) == own.rstrip(os.sep),
             'RGBDS v0.6.1 is the app\'s own', found or 'none')
    except RuntimeError as e:
        C.ok(False, 'RGBDS v0.6.1', str(e).splitlines()[0])
        env = None

    # 2. the original ROM
    data_rom = os.path.join(REPO, 'data', 'DWM-original.gbc')
    if rom_arg:
        from editor2.app import appmode
        appmode.adopt_rom(REPO, rom_arg)
    elif not os.path.exists(data_rom) and env is not None:
        stage = os.path.join(tmp, 'clean')
        os.makedirs(stage)
        dis = os.path.join(REPO, 'disassembly') + os.sep
        for args in (['rgbasm', '-i', dis, '-o', 'game.o', dis + 'game.asm'],
                     ['rgblink', '-o', 'game.gbc', 'game.o'],
                     ['rgbfix', '-v', '-p', '255', 'game.gbc']):
            subprocess.run(args, cwd=stage, env=env, capture_output=True)
        g = os.path.join(stage, 'game.gbc')
        if os.path.exists(g) and _md5(g) == ORIGINAL_MD5:
            os.makedirs(os.path.dirname(data_rom), exist_ok=True)
            shutil.copy(g, data_rom)
    C.ok(os.path.exists(data_rom) and _md5(data_rom) == ORIGINAL_MD5,
         'the original ROM (the clean disassembly assembled by the app\'s RGBDS)'
         if not rom_arg else 'the original ROM (--rom)')

    # 3. the example project builds to the pin
    src = open(os.path.join(REPO, 'editor2', 'tests', 'test_compiler.py'), encoding='utf-8').read()
    pin = re.search(r'REFERENCE_MD5 = "([0-9a-f]{32})"', src).group(1)
    prj = os.path.join(tmp, 'example-project')
    shutil.copytree(os.path.join(REPO, 'editor2', 'example-project'), prj,
                    copy_function=shutil.copyfile)          # the app's files are read-only
    out = os.path.join(tmp, 'out')
    r = subprocess.run([sys.executable, os.path.join(REPO, 'tools', 'build_project.py'),
                        '--project', prj, '--out', out, '--build'],
                       capture_output=True, text=True, cwd=REPO)
    m = re.search(r'md5: ([0-9a-f]{32})', r.stdout)
    rom = os.path.join(out, 'build', 'rom.gbc')
    C.ok(m is not None and m.group(1) == pin, 'the example project builds to the pin',
         (m.group(1) if m else (r.stdout + r.stderr).strip().splitlines()[-1:] or ['?'])[0]
         if not (m and m.group(1) == pin) else pin)
    C.ok(not any(os.path.exists(os.path.join(REPO, 'disassembly', f))
                 for f in ('game.o', 'game.gbc')), 'the build wrote nothing into the app')

    # 4. the window
    from PySide6.QtWidgets import QApplication
    app = QApplication.instance() or QApplication(['DWM1 Editor'])
    from editor2.app.qt_safe import StrayWindowGuard
    guard = StrayWindowGuard(app)
    try:
        from PySide6.QtMultimedia import QMediaDevices        # noqa: F401
        C.ok(True, 'QtMultimedia loads')
    except Exception as e:                                     # noqa: BLE001
        C.ok(False, 'QtMultimedia loads', str(e))
    from editor2.app.main import MainWindow
    w = MainWindow()
    w.open_project(prj)
    w.resize(1280, 800)
    w.show()
    app.processEvents()
    n = w.tabs.count()
    shown = 0
    for i in range(n if not quick else 3):
        w.tabs.setCurrentIndex(i)
        for _ in range(3):
            app.processEvents()
        shown += w.tabs.currentWidget() is not None
    C.ok(shown == (n if not quick else 3), f'the window: {shown} tabs shown')
    C.ok(not guard.stopped, 'no stray window', ', '.join(guard.stopped))
    w.session.undo.clear()
    w.close()
    app.processEvents()

    # 5. the game for Playback (its own process)
    if os.path.exists(rom):
        from editor2.core.playback_server import PlaybackClient
        cache = os.path.join(tmp, 'playback')
        os.makedirs(cache)
        try:
            pc = PlaybackClient(REPO, timeout=300)
            head, _ = pc.call({'cmd': 'open', 'rom': rom, 'cache_dir': cache, 'sav': None,
                               'sound': False}, timeout=600)
            C.ok(bool(head.get('ok')), 'the game runs (Playback process, PyBoy)')
            pc.close()
        except Exception as e:                                 # noqa: BLE001
            C.ok(False, 'the game runs (Playback process, PyBoy)', str(e))

    # 6. Play
    from editor2.core import emulator
    argv_, desc = emulator.default_command(rom)
    if sys.platform == 'darwin':
        C.ok('inside the editor app' in desc, 'Play starts the app\'s SameBoy', desc)
    else:
        print(f'INFO Play would run: {desc}')
    print(f'{"ALL PASSED" if not C.failed else f"{C.failed} FAILED"} in {time.time() - t0:.0f} s',
          flush=True)
    shutil.rmtree(tmp, ignore_errors=True)
    return C.failed


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
