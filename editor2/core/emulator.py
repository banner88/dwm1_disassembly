"""emulator.py — launch the built ROM in an external emulator (EDITOR_DESIGN §4).

Pure Python, NO Qt imports (core stays headless — EDITOR_DESIGN "Hard
rules"). Cross-platform per the S72 decision (PySide6 app targets
macOS/Windows/Linux; macOS is the primary target):

  macOS   : `open -a SameBoy <rom>` if SameBoy is installed, else `open`
            (OS default .gbc association).
  Windows : os.startfile(rom) — OS default association.
  Linux   : `sameboy <rom>` if on PATH, else `xdg-open <rom>`.

A custom command overrides all of the above. It is a shell-free argv list
or a single string split on whitespace; the placeholder `{rom}` is replaced
with the ROM path (appended if absent). The app persists it in QSettings;
headless callers pass it directly.
"""

import os
import shutil
import subprocess
import sys


def default_command(rom_path):
    """Return (argv_list_or_None, description). None argv => os.startfile."""
    if sys.platform == 'darwin':
        # `open -a` fails cleanly if the app is missing; probe first so the
        # fallback is silent.
        probe = subprocess.run(
            ['open', '-Ra', 'SameBoy'], capture_output=True)
        if probe.returncode == 0:
            return ['open', '-a', 'SameBoy', rom_path], 'SameBoy (macOS)'
        return ['open', rom_path], 'macOS default app for .gbc'
    if sys.platform.startswith('win'):
        return None, 'Windows default app for .gbc'
    if shutil.which('sameboy'):
        return ['sameboy', rom_path], 'SameBoy (PATH)'
    return ['xdg-open', rom_path], 'Linux default app for .gbc'


def launch(rom_path, custom_command=None):
    """Launch the ROM. Returns a human-readable description of what ran.
    Raises RuntimeError with a fix-it message on failure."""
    rom_path = os.path.abspath(rom_path)
    if not os.path.exists(rom_path):
        raise RuntimeError(
            f"ROM not found: {rom_path}. Build the project first.")
    if custom_command:
        argv = (list(custom_command) if isinstance(custom_command, (list,
                tuple)) else str(custom_command).split())
        if any('{rom}' in a for a in argv):
            argv = [a.replace('{rom}', rom_path) for a in argv]
        else:
            argv = argv + [rom_path]
        desc = ' '.join(argv[:-1]) + ' <rom>'
    else:
        argv, desc = default_command(rom_path)
    if argv is None:                       # Windows default-association path
        os.startfile(rom_path)             # noqa — windows-only branch
        return desc
    try:
        subprocess.Popen(argv)
    except FileNotFoundError:
        raise RuntimeError(
            f"Emulator command not found: {argv[0]}. Set a custom emulator "
            "command in Preferences (use {rom} as the ROM placeholder).")
    return desc
