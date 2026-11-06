"""appmode.py — the editor running as the packaged app (S171, ROADMAP P3.17).

The app (`DWM1 Editor.app`, made by tools/package_app.py) carries its own Python,
PySide6, PyBoy, RGBDS v0.6.1 (rgbasm / rgblink / rgbfix) and SameBoy, and the
editor's files (`Resources/repo`: editor2, disassembly, patches, extracted, tools,
simulator, dwm …). Those files are READ-ONLY: a downloaded app may run from a
read-only place (macOS App Translocation) and a signed bundle must not change.

`Resources/launch.py` starts the editor from a WORKSPACE in the user's data folder
(macOS: ~/Library/Application Support/DWM1 Editor/runtime/<build>/): one symbolic
link per entry of Resources/repo, except `data/`, which is a real folder shared by
every build (it holds the user's copy of the original ROM). Every path the editor
and its helper processes compute from `__file__` (REPO, repo_root …) is therefore
the workspace, `data/DWM-original.gbc` works as in a checkout, and nothing is ever
written into the app. The build itself writes nothing into the tree either
(core/builder.py S171: a private temporary folder).

Environment the launcher sets (absent in a checkout — `APP` False):
  DWM_APP=1, DWM_APP_RESOURCES=<Resources>, DWM_APP_DATA=<the user's data folder>,
  DWM_RGBDS_DIR=<Resources/rgbds> (core/builder.check_toolchain looks there after a
  folder set with File → Set RGBDS folder), DWM_SAMEBOY=<the bundled SameBoy>.
"""

import hashlib
import os
import shutil
import sys

APP = os.environ.get('DWM_APP') == '1'
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'
APP_NAME = 'DWM1 Editor'


def resources():
    return os.environ.get('DWM_APP_RESOURCES') or None


def user_data_dir():
    """Where the app keeps what it writes (the ROM copy, the runtime workspaces)."""
    d = os.environ.get('DWM_APP_DATA')
    if d:
        return d
    if sys.platform == 'darwin':
        return os.path.expanduser(f'~/Library/Application Support/{APP_NAME}')
    if sys.platform.startswith('win'):
        return os.path.join(os.environ.get('APPDATA', os.path.expanduser('~')), APP_NAME)
    return os.path.join(os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share')),
                        'dwm1-editor')


def bundled_sameboy():
    """The SameBoy the app carries (macOS: SameBoy.app), or None."""
    p = os.environ.get('DWM_SAMEBOY')
    return p if p and os.path.exists(p) else None


def rom_md5(path):
    with open(path, 'rb') as f:
        return hashlib.md5(f.read()).hexdigest()


def adopt_rom(repo, path):
    """Copy the original ROM at `path` to <repo>/data/DWM-original.gbc (the app's
    data folder) when it is the right file. Returns the destination or None."""
    if not path or not os.path.exists(path) or rom_md5(path) != ORIGINAL_MD5:
        return None
    dst = os.path.join(repo, 'data', 'DWM-original.gbc')
    if os.path.abspath(path) != os.path.abspath(dst):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        tmp = dst + '.part'
        shutil.copyfile(path, tmp)
        os.replace(tmp, dst)
    return dst


def ensure_rom(repo, settings):
    """At start: the app has no ROM of its own yet, but the editor (a checkout) was
    told where one is (File → Locate original ROM) — take a copy. True when
    <repo>/data/DWM-original.gbc is the original ROM."""
    dst = os.path.join(repo, 'data', 'DWM-original.gbc')
    if os.path.exists(dst) and rom_md5(dst) == ORIGINAL_MD5:
        return True
    try:
        return adopt_rom(repo, settings.value('rom/path')) is not None
    except OSError:
        return False


def icon_path():
    here = os.path.dirname(os.path.abspath(__file__))
    p = os.path.join(here, 'icon.png')
    return p if os.path.exists(p) else None


def icon_for(app):
    """The editor's icon on its windows (the Dock / task bar of a checkout too)."""
    p = icon_path()
    if p:
        from PySide6.QtGui import QIcon
        app.setWindowIcon(QIcon(p))
