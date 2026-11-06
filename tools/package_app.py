#!/usr/bin/env python3
"""package_app.py — the DWM1 Editor as ONE app with everything inside (S171, ROADMAP P3.17).

    python3 tools/package_app.py                 # on a Mac: dist/DWM1 Editor.app (+ .zip)
    python3 tools/package_app.py --selftest      # … and run the app's own check on it

What goes in (EDITOR_DESIGN §4 "Packaging, as built S171"):
  - Python 3.12 (python-build-standalone, a self-contained interpreter) with PySide6 6.9.1,
    PyBoy 2.9.0, numpy, Pillow installed into it; PySide6 cut to what the editor uses
    (QtCore / QtGui / QtWidgets / QtMultimedia / QtTest and the Qt libraries they load);
  - RGBDS v0.6.1: rgbasm, rgblink, rgbfix (the build needs nothing else — no `make`,
    core/builder.py S171), taken from --rgbds DIR or the PATH, version-checked;
  - SameBoy (macOS: SameBoy.app from its GitHub release; MIT licence) for Build → Play;
  - the editor's files (Resources/repo): editor2, dwm, tools, simulator, randomizer,
    extracted, disassembly, patches, dwm.tbl — read-only at run time; compiled to .pyc.
NOT in the app: the original ROM (the app asks for it once and keeps a copy in its data
folder — editor2/app/appmode.py), documentation/, examples/, data/.

Why not PyInstaller (the S72 plan): the editor starts its own scripts as separate Python
processes (the game for Playback / storyboards — core/playback_server.py, the ROM checker
tools/validate_custom_data.py, the Balance anchor) with `sys.executable`; in a PyInstaller
app sys.executable is the app itself, so each would open a second editor. A real Python
inside the app keeps every one of them working unchanged.

macOS layout:
  DWM1 Editor.app/Contents/Info.plist
                          /MacOS/DWM1 Editor      (sh: PYTHONHOME, exec the next one)
                          /MacOS/dwm1-python      (the interpreter — in MacOS/ so the Dock
                                                   and the menu bar show the app's name/icon)
                          /Resources/python       (the standard library + site-packages)
                          /Resources/repo  /rgbds  /SameBoy.app  /launch.py  /AppIcon.icns
Linux layout (used to test the packaging on a Linux machine): dist/DWM1-Editor/ with the
same Resources content and a `dwm1-editor` script.

Signing: ad hoc (no Apple Developer ID — user decision S171). An app built on the Mac it runs
on just opens. A downloaded one (the GitHub workflow .github/workflows/editor-app.yml): after
unzipping, run once in Terminal   xattr -cr "/Applications/DWM1 Editor.app"
(or System Settings → Privacy & Security → Open Anyway) — help 00_start "The app".
"""

import argparse
import compileall
import hashlib
import os
import platform
import plistlib
import re
import shutil
import subprocess
import sys
import tarfile
import time
import urllib.request
import zipfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

APP_NAME = 'DWM1 Editor'
BUNDLE_ID = 'io.github.banner88.dwm1editor'
PBS_TAG = '20261026'
PBS_PY = '3.12.16'
PBS_URL = ('https://github.com/astral-sh/python-build-standalone/releases/download/'
           '{tag}/cpython-{py}+{tag}-{triple}-install_only_stripped.tar.gz')
SAMEBOY_URL = 'https://github.com/LIJI32/SameBoy/releases/download/v1.0.5/sameboy_cocoa_v1.0.5.zip'
PIP_PACKAGES = ['PySide6==6.9.1', 'pyboy==2.9.0', 'numpy', 'pillow']
RGBDS_TOOLS = ('rgbasm', 'rgblink', 'rgbfix')
RGBDS_VERSION = 'v0.6.1'

# the repository's top-level entries the app carries (everything the editor and its
# helper processes read); data/ is NEVER copied (the ROM)
REPO_ENTRIES = ['editor2', 'dwm', 'tools', 'simulator', 'randomizer', 'extracted',
                'disassembly', 'patches', 'dwm.tbl']
SKIP_NAMES = {'__pycache__', '.DS_Store', '.git', 'game.o', 'game.gbc', 'game.sym', 'game.map'}
# Qt: the Python modules the editor imports (QtTest: the editor's own tests run in the app)
QT_MODULES = ['QtCore', 'QtGui', 'QtWidgets', 'QtMultimedia', 'QtTest']
QT_PLUGIN_DIRS = ['platforms', 'platformthemes', 'platforminputcontexts', 'styles',
                  'imageformats', 'iconengines', 'multimedia', 'xcbglintegrations',
                  'egldeviceintegrations', 'generic', 'tls', 'networkinformation',
                  'wayland-decoration-client', 'wayland-graphics-integration-client',
                  'wayland-shell-integration']


def log(*a):
    print('[package]', *a, flush=True)


def target_triple():
    m = platform.machine().lower()
    arch = {'arm64': 'aarch64', 'aarch64': 'aarch64', 'x86_64': 'x86_64', 'amd64': 'x86_64'}[m]
    if sys.platform == 'darwin':
        return f'{arch}-apple-darwin'
    if sys.platform.startswith('linux'):
        return f'{arch}-unknown-linux-gnu'
    raise SystemExit('package_app.py makes the macOS app (and a Linux folder for testing)')


def fetch(url, cache):
    os.makedirs(cache, exist_ok=True)
    dst = os.path.join(cache, url.rsplit('/', 1)[1].replace('%2B', '+'))
    if not os.path.exists(dst):
        log('download', url)
        tmp = dst + '.part'
        with urllib.request.urlopen(url) as r, open(tmp, 'wb') as f:
            shutil.copyfileobj(r, f)
        os.replace(tmp, dst)
    return dst


def run(args, **kw):
    log('$', ' '.join(str(a) for a in args))
    subprocess.run(args, check=True, **kw)


# ----------------------------------------------------------------------------- python
def install_python(res, cache, triple, tarball=None):
    src = tarball or fetch(PBS_URL.format(tag=PBS_TAG, py=PBS_PY, triple=triple), cache)
    with tarfile.open(src) as t:
        t.extractall(res, filter='tar') if sys.version_info >= (3, 12) else t.extractall(res)
    py = os.path.join(res, 'python', 'bin', 'python3')
    env = dict(os.environ, PYTHONNOUSERSITE='1')
    env.pop('PYTHONPATH', None)
    env.pop('PYTHONHOME', None)
    run([py, '-m', 'pip', 'install', '--cache-dir', os.path.join(cache, 'pip'),
         '--disable-pip-version-check',
         '--only-binary=:all:'] + PIP_PACKAGES, env=env)
    return py


def _deps(path):
    """Library names a binary loads (otool on macOS, readelf on Linux)."""
    try:
        if sys.platform == 'darwin':
            out = subprocess.run(['otool', '-L', path], capture_output=True, text=True).stdout
            return [ln.strip().split(' (')[0] for ln in out.splitlines()[1:]]
        out = subprocess.run(['readelf', '-d', path], capture_output=True, text=True).stdout
        return re.findall(r'\(NEEDED\)\s+Shared library: \[([^\]]+)\]', out)
    except OSError:
        return []


def _qt_name(dep):
    """'libQt6Network.so.6' / '@rpath/QtNetwork.framework/…' -> 'Network' (else None)."""
    m = re.search(r'libQt6(\w+?)\.so', dep) or re.search(r'Qt(\w+)\.framework', dep)
    return m.group(1) if m else None


def _is_binary(p):
    if not os.path.isfile(p) or os.path.islink(p):
        return False
    with open(p, 'rb') as f:
        head = f.read(4)
    return head in (b'\x7fELF', b'\xcf\xfa\xed\xfe', b'\xca\xfe\xba\xbe', b'\xce\xfa\xed\xfe')


def prune_pyside(site):
    """Keep the Qt the editor uses: the QT_MODULES bindings, the plugin folders it needs,
    and every Qt library those load (a dependency closure read from the binaries)."""
    ps = os.path.join(site, 'PySide6')
    qt = os.path.join(ps, 'Qt')
    lib = os.path.join(qt, 'lib')
    before = _du(ps)
    def binding(f):
        m = re.match(r'(Qt\w+)\.(abi3\.so|pyi|cpython.*\.so|pyd)$', f)
        return m.group(1) if m else None
    for f in os.listdir(ps):                 # designer, Assistant.app, examples, includes …
        p = os.path.join(ps, f)
        if f in ('examples', 'include', 'typesystems', 'glue', 'doc', 'QtAsyncio', 'scripts') or \
                f.endswith('.app') or (os.path.isfile(p) and _is_binary(p) and '.so' not in f
                                       and '.dylib' not in f and not f.startswith('lib')):
            shutil.rmtree(p, ignore_errors=True) if os.path.isdir(p) else os.remove(p)
    for d in ('qml', 'translations', 'resources', 'metatypes', 'libexec'):
        shutil.rmtree(os.path.join(qt, d), ignore_errors=True)
    plugins = os.path.join(qt, 'plugins')
    if os.path.isdir(plugins):
        for d in os.listdir(plugins):
            if d not in QT_PLUGIN_DIRS:
                shutil.rmtree(os.path.join(plugins, d), ignore_errors=True)
    # the closure of Qt libraries, from the bindings the editor imports + the plugins
    roots = [os.path.join(ps, f) for f in os.listdir(ps) if _is_binary(os.path.join(ps, f))
             and (binding(f) is None or binding(f) in QT_MODULES)]
    for dp, _dn, fn in os.walk(plugins):
        roots += [os.path.join(dp, f) for f in fn if _is_binary(os.path.join(dp, f))]

    def lib_path(name):
        for cand in (os.path.join(lib, f'libQt6{name}.so.6'),
                     os.path.join(lib, f'Qt{name}.framework', 'Versions', 'A', f'Qt{name}')):
            if os.path.exists(cand):
                return cand
        return None
    need, todo = set(), list(roots)
    while todo:
        b = todo.pop()
        for dep in _deps(b):
            n = _qt_name(dep)
            if n and n not in need:
                need.add(n)
                p = lib_path(n)
                if p:
                    todo.append(p)
    # bindings: the editor's + the ones of every kept library (QtMultimedia's Python
    # module imports QtNetwork's)
    keep_py = set(QT_MODULES) | {f'Qt{n}' for n in need}
    for f in os.listdir(ps):
        if binding(f) and binding(f) not in keep_py:
            os.remove(os.path.join(ps, f))
    removed = []
    if os.path.isdir(lib):
        for f in os.listdir(lib):
            n = _qt_name(f)
            if n and n not in need:
                p = os.path.join(lib, f)
                shutil.rmtree(p) if os.path.isdir(p) and not os.path.islink(p) else os.remove(p)
                removed.append(n)
    log(f'PySide6 {before // 2**20} MB -> {_du(ps) // 2**20} MB; Qt libraries kept: '
        f'{", ".join(sorted(need))}')
    return sorted(need)


def slim_site(site):
    """Files the app never uses: PyBoy's generated C sources (64 MB; its compiled modules
    are what runs)."""
    n = 0
    for dp, _dn, fn in os.walk(os.path.join(site, 'pyboy')):
        for f in fn:
            if f.endswith(('.c', '.h')):
                os.remove(os.path.join(dp, f))
                n += 1
    log(f'removed {n} PyBoy C sources')


def _du(p):
    tot = 0
    for dp, _dn, fn in os.walk(p):
        for f in fn:
            fp = os.path.join(dp, f)
            if not os.path.islink(fp):
                tot += os.path.getsize(fp)
    return tot


# ----------------------------------------------------------------------------- rgbds
def find_rgbds(given=None):
    dirs = [given] if given else []
    w = shutil.which('rgbasm')
    if w:
        dirs.append(os.path.dirname(w))
    for d in dirs:
        if not d or not all(os.path.exists(os.path.join(d, t)) for t in RGBDS_TOOLS):
            continue
        v = subprocess.run([os.path.join(d, 'rgbasm'), '--version'], capture_output=True,
                           text=True)
        if RGBDS_VERSION in (v.stdout + v.stderr):
            return d
        log(f'skipping {d}: not RGBDS {RGBDS_VERSION}')
    raise SystemExit(f'RGBDS {RGBDS_VERSION} not found — pass --rgbds DIR (the folder with '
                     'rgbasm / rgblink / rgbfix), or build it: git clone --branch v0.6.1 '
                     '--depth 1 https://github.com/gbdev/rgbds && make -C rgbds rgbasm rgblink rgbfix')


def install_rgbds(res, src):
    dst = os.path.join(res, 'rgbds')
    os.makedirs(dst, exist_ok=True)
    for t in RGBDS_TOOLS:
        shutil.copy2(os.path.join(src, t), os.path.join(dst, t))
        os.chmod(os.path.join(dst, t), 0o755)
        bad = [d for d in _deps(os.path.join(dst, t))
               if not (d.startswith('/usr/lib/') or d.startswith('/System/') or
                       re.match(r'lib(c|m|dl|pthread|rt)\.so', d) or d.startswith('ld-linux')
                       or d.startswith('libc.') or d.startswith('libm.'))]
        if bad:
            raise SystemExit(f'{t} loads libraries a fresh computer lacks: {bad}')


# ----------------------------------------------------------------------------- repo
def copy_repo(res):
    dst = os.path.join(res, 'repo')

    def ignore(d, names):
        out = [n for n in names if n in SKIP_NAMES or n.endswith('.pyc')
               or n.lower().endswith(('.gbc', '.gb', '.sav', '.ram'))]
        if os.path.basename(d) == 'example-project':      # its builds hold ROM copies
            out += [n for n in names if n == 'build']
        return out
    for e in REPO_ENTRIES:
        s = os.path.join(REPO, e)
        if os.path.isdir(s):
            shutil.copytree(s, os.path.join(dst, e), ignore=ignore, symlinks=False)
        else:
            shutil.copy2(s, os.path.join(dst, e))
    # the app never carries a ROM (a test build left in a folder, a copy …): checked
    left = [os.path.join(dp, f) for dp, _dn, fn in os.walk(dst) for f in fn
            if f.lower().endswith(('.gbc', '.gb', '.sav'))]
    if left:
        raise SystemExit(f'a ROM / save would go into the app: {left[:3]}')
    return dst


def build_id():
    from editor2 import EDITOR_REVISION
    try:
        sha = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], cwd=REPO,
                             capture_output=True, text=True).stdout.strip()
    except OSError:
        sha = ''
    return f"{EDITOR_REVISION}-{sha or 'local'}-{time.strftime('%Y%m%d%H%M%S')}"


# ----------------------------------------------------------------------------- layout
def write_launcher_files(res, bid):
    pk = os.path.join(REPO, 'editor2', 'packaging')
    shutil.copy2(os.path.join(pk, 'launch.py'), os.path.join(res, 'launch.py'))
    with open(os.path.join(res, 'build_id.txt'), 'w') as f:
        f.write(bid + '\n')


MAC_LAUNCHER = '''#!/bin/sh
# DWM1 Editor (S171, tools/package_app.py): the app's own Python runs Resources/launch.py
HERE="$(cd "$(dirname "$0")" && pwd)"
RES="$(cd "$HERE/../Resources" && pwd)"
export PYTHONHOME="$RES/python"
export PYTHONNOUSERSITE=1
unset PYTHONPATH
exec "$HERE/dwm1-python" "$RES/launch.py" "$@"
'''

LINUX_LAUNCHER = '''#!/bin/sh
# DWM1 Editor (S171, tools/package_app.py): the folder's own Python runs launch.py
HERE="$(cd "$(dirname "$0")" && pwd)"
export PYTHONHOME="$HERE/python"
export PYTHONNOUSERSITE=1
unset PYTHONPATH
exec "$HERE/python/bin/python3" "$HERE/launch.py" "$@"
'''


def make_mac(out, cache, args):
    app = os.path.join(out, APP_NAME + '.app')
    shutil.rmtree(app, ignore_errors=True)
    con = os.path.join(app, 'Contents')
    res = os.path.join(con, 'Resources')
    macos = os.path.join(con, 'MacOS')
    os.makedirs(res)
    os.makedirs(macos)
    triple = target_triple()
    py = install_python(res, cache, triple, args.python_tarball)
    site = _site(res)
    prune_pyside(site)
    slim_site(site)
    install_rgbds(res, find_rgbds(args.rgbds))
    if not args.no_sameboy:
        z = args.sameboy_zip or fetch(SAMEBOY_URL, cache)
        run(['ditto', '-x', '-k', z, res])           # keeps SameBoy.app's own signature
    copy_repo(res)
    bid = build_id()
    write_launcher_files(res, bid)
    shutil.copy2(os.path.join(REPO, 'editor2', 'packaging', 'AppIcon.icns'),
                 os.path.join(res, 'AppIcon.icns'))
    # the interpreter in Contents/MacOS (statically linked: only system libraries)
    shutil.copy2(os.path.realpath(py), os.path.join(macos, 'dwm1-python'))
    for f in os.listdir(os.path.join(res, 'python', 'bin')):        # pip & co. not needed
        p = os.path.join(res, 'python', 'bin', f)
        os.remove(p)
    with open(os.path.join(macos, APP_NAME), 'w') as f:
        f.write(MAC_LAUNCHER)
    os.chmod(os.path.join(macos, APP_NAME), 0o755)
    from editor2 import EDITOR_REVISION
    plist = {
        'CFBundleName': APP_NAME, 'CFBundleDisplayName': APP_NAME,
        'CFBundleIdentifier': BUNDLE_ID, 'CFBundleExecutable': APP_NAME,
        'CFBundleIconFile': 'AppIcon', 'CFBundlePackageType': 'APPL',
        'CFBundleShortVersionString': EDITOR_REVISION.lstrip('S'),
        'CFBundleVersion': bid, 'LSMinimumSystemVersion': '12.0',
        'NSHighResolutionCapable': True, 'NSRequiresAquaSystemAppearance': False,
        'LSApplicationCategoryType': 'public.app-category.developer-tools',
        'NSHumanReadableCopyright': 'DWM1 disassembly project editor. SameBoy © Lior Halphon '
                                    '(MIT). Qt / PySide6 (LGPLv3).',
    }
    with open(os.path.join(con, 'Info.plist'), 'wb') as f:
        plistlib.dump(plist, f)
    compile_all(os.path.join(macos, 'dwm1-python'), res, env_home=os.path.join(res, 'python'))
    # ad-hoc signature for the bundle (not --deep: SameBoy.app keeps its own)
    if not args.no_sign:
        try:
            run(['codesign', '--force', '--sign', '-', '--timestamp=none',
                 os.path.join(macos, 'dwm1-python')])
            run(['codesign', '--force', '--sign', '-', '--timestamp=none', app])
        except (subprocess.CalledProcessError, OSError) as e:
            log(f'codesign failed ({e}) — the app still runs after: xattr -cr "{app}"')
    return app, os.path.join(macos, APP_NAME)


def make_linux(out, cache, args):
    root = os.path.join(out, 'DWM1-Editor')
    shutil.rmtree(root, ignore_errors=True)
    os.makedirs(root)
    py = install_python(root, cache, target_triple(), args.python_tarball)
    prune_pyside(_site(root))
    slim_site(_site(root))
    install_rgbds(root, find_rgbds(args.rgbds))
    copy_repo(root)
    bid = build_id()
    write_launcher_files(root, bid)
    with open(os.path.join(root, 'dwm1-editor'), 'w') as f:
        f.write(LINUX_LAUNCHER)
    os.chmod(os.path.join(root, 'dwm1-editor'), 0o755)
    compile_all(py, root, env_home=os.path.join(root, 'python'))
    return root, os.path.join(root, 'dwm1-editor')


def _site(res):
    lib = os.path.join(res, 'python', 'lib')
    pyd = next(d for d in os.listdir(lib) if re.match(r'python3\.\d+$', d))
    return os.path.join(lib, pyd, 'site-packages')


def compile_all(py, res, env_home):
    """.pyc for the editor's files (they are read-only in the app: Python could not
    write its cache there, and every start would compile again)."""
    env = dict(os.environ, PYTHONHOME=env_home, PYTHONNOUSERSITE='1')
    env.pop('PYTHONPATH', None)
    run([py, '-m', 'compileall', '-q', '-j', '0', os.path.join(res, 'repo'),
         os.path.join(res, 'launch.py')], env=env, stdout=subprocess.DEVNULL)


def zip_it(path, out):
    base = os.path.join(out, os.path.basename(path).replace(' ', '-').replace('.app', ''))
    if sys.platform == 'darwin':
        z = base + '-macOS.zip'
        if os.path.exists(z):
            os.remove(z)
        run(['ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', path, z])
    else:
        z = base + '-linux.tar.gz'
        with tarfile.open(z, 'w:gz') as t:
            t.add(path, arcname=os.path.basename(path))
    log('zip', z, f'{os.path.getsize(z) // 2**20} MB')
    return z


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', default=os.path.join(REPO, 'dist'))
    ap.add_argument('--cache', default=os.path.join(os.path.expanduser('~'), '.cache',
                                                    'dwm1-editor-package'))
    ap.add_argument('--rgbds', help='folder with rgbasm / rgblink / rgbfix v0.6.1 (else PATH)')
    ap.add_argument('--python-tarball', help='a python-build-standalone install_only tarball')
    ap.add_argument('--sameboy-zip', help='sameboy_cocoa_*.zip (else downloaded)')
    ap.add_argument('--no-sameboy', action='store_true')
    ap.add_argument('--no-sign', action='store_true')
    ap.add_argument('--no-zip', action='store_true')
    ap.add_argument('--selftest', action='store_true',
                    help="run the app's own check (launch.py --selftest) on the result")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    t0 = time.time()
    if sys.platform == 'darwin':
        path, launcher = make_mac(args.out, args.cache, args)
    else:
        path, launcher = make_linux(args.out, args.cache, args)
    log(f'made {path} ({_du(path) // 2**20} MB) in {time.time() - t0:.0f} s')
    if args.selftest:
        env = {k: v for k, v in os.environ.items()
               if not k.startswith('PYTHON') and k not in ('DWM_APP', 'DWM_RGBDS_DIR')}
        run([launcher, '--selftest'], env=env)
    if not args.no_zip:
        zip_it(path, args.out)


if __name__ == '__main__':
    main()
