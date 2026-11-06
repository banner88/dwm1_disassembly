"""launch.py — starts the DWM1 Editor inside the packaged app (S171, ROADMAP P3.17).

Run by the app's own Python (Contents/MacOS/DWM1 Editor → dwm1-python launch.py).
This file sits next to the app's read-only files (Resources/repo); it

  1. makes the WORKSPACE <data>/runtime/<build id>/: a symbolic link for every entry of
     Resources/repo + `data` → <data>/data (a real folder, the user's ROM copy) — so the
     editor's REPO (computed from __file__ everywhere) is a folder whose data/ is
     writable while everything else is the app's (editor2/app/appmode.py);
  2. sets DWM_APP / DWM_APP_RESOURCES / DWM_APP_DATA / DWM_RGBDS_DIR / DWM_SAMEBOY and
     PYTHONPATH (the helper processes the editor starts with sys.executable find the
     same workspace);
  3. runs `python -m editor2.app` there — or the app's self-check (`--selftest`,
     editor2/packaging/selftest.py), used by tools/package_app.py and the GitHub build.

Opened from the Finder the app has no terminal: what Python prints goes to
<data>/logs/editor.log (the last run's; the run before it in editor.log.1).
"""

import os
import runpy
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_SRC = os.path.join(HERE, 'repo')
APP_NAME = 'DWM1 Editor'


def data_dir():
    d = os.environ.get('DWM_APP_DATA')
    if d:
        return d
    if sys.platform == 'darwin':
        return os.path.expanduser(f'~/Library/Application Support/{APP_NAME}')
    return os.path.join(os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share')),
                        'dwm1-editor')


def build_id():
    try:
        with open(os.path.join(HERE, 'build_id.txt')) as f:
            return f.read().strip() or 'build'
    except OSError:
        return 'build'


def _link(target, link):
    """`link` -> `target`, replaced when it points elsewhere (a moved / translocated app)."""
    if os.path.islink(link):
        if os.readlink(link) == target:
            return
        os.remove(link)
    elif os.path.exists(link):
        shutil.rmtree(link) if os.path.isdir(link) else os.remove(link)
    os.symlink(target, link)


def workspace(data):
    runtime = os.path.join(data, 'runtime')
    ws = os.path.join(runtime, build_id())
    os.makedirs(ws, exist_ok=True)
    os.makedirs(os.path.join(data, 'data'), exist_ok=True)
    for name in os.listdir(REPO_SRC):
        if name == 'data':
            continue
        _link(os.path.join(REPO_SRC, name), os.path.join(ws, name))
    _link(os.path.join(data, 'data'), os.path.join(ws, 'data'))
    # workspaces of older builds of the app (links only — never the user's data/)
    for old in os.listdir(runtime):
        p = os.path.join(runtime, old)
        if old != os.path.basename(ws) and os.path.isdir(p) and not os.path.islink(p):
            shutil.rmtree(p, ignore_errors=True)
    return ws


def _log_to_file(data):
    if sys.stderr is not None and hasattr(sys.stderr, 'isatty') and sys.stderr.isatty():
        return
    logs = os.path.join(data, 'logs')
    os.makedirs(logs, exist_ok=True)
    p = os.path.join(logs, 'editor.log')
    if os.path.exists(p):
        os.replace(p, p + '.1')
    f = open(p, 'w', buffering=1, encoding='utf-8', errors='replace')
    sys.stdout = sys.stderr = f
    os.dup2(f.fileno(), 1)
    os.dup2(f.fileno(), 2)


def main():
    argv = sys.argv[1:]
    selftest = '--selftest' in argv
    if selftest and not os.environ.get('DWM_APP_DATA'):
        import tempfile             # the check never touches the user's own data folder
        os.environ['DWM_APP_DATA'] = tempfile.mkdtemp(prefix='dwm1-selftest-')
    data = data_dir()
    os.makedirs(data, exist_ok=True)
    if not selftest:
        _log_to_file(data)
    ws = workspace(data)
    env = os.environ
    env['DWM_APP'] = '1'
    env['DWM_APP_RESOURCES'] = HERE
    env['DWM_APP_DATA'] = data
    env['DWM_RGBDS_DIR'] = os.path.join(HERE, 'rgbds')
    for cand in (os.path.join(HERE, 'SameBoy.app'), os.path.join(HERE, 'sameboy', 'sameboy')):
        if os.path.exists(cand):
            env['DWM_SAMEBOY'] = cand
            break
    env['PYTHONPATH'] = ws
    env['PYTHONNOUSERSITE'] = '1'
    os.chdir(ws)
    sys.path[:] = [ws] + [p for p in sys.path if os.path.abspath(p or '.') != HERE]
    if selftest:
        from editor2.packaging import selftest as T
        sys.exit(T.main([a for a in argv if a != '--selftest']))
    sys.argv = [sys.argv[0]] + argv
    runpy.run_module('editor2.app', run_name='__main__', alter_sys=True)


if __name__ == '__main__':
    main()
