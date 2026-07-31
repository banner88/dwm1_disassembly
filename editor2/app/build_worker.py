"""build_worker.py — run compile_project + build_rom off the GUI thread.

Thin QThread over editor2.core (compiler/builder are UNCHANGED — same code
path as tools/build_project.py, so a GUI build is byte-identical to a CLI
build by construction). Emits log lines as they happen and a single
finished(result) with either the manifest facts or the error text.
"""

import os
import traceback

from PySide6.QtCore import QThread, Signal

from editor2.core import builder as B
from editor2.core import compiler as C


class BuildResult:
    def __init__(self):
        self.ok = False
        self.error = ''
        self.rom_path = ''
        self.rom_md5 = ''
        self.manifest_path = ''
        self.bank_usage = {}
        self.warnings = []


class BuildWorker(QThread):
    log = Signal(str)
    finished_build = Signal(object)      # BuildResult

    def __init__(self, repo, project_path, parent=None):
        super().__init__(parent)
        self.repo = repo
        self.project_path = project_path

    def run(self):
        res = BuildResult()
        try:
            out = os.path.join(
                self.project_path if os.path.isdir(self.project_path)
                else os.path.dirname(self.project_path), 'build')
            self.log.emit(f"Compiling {self.project_path} …")
            outputs, prj, warnings = C.compile_project(
                self.project_path, self.repo)
            res.warnings = list(warnings)
            written = C.write_outputs(outputs, out)
            self.log.emit(f"Generated {len(written)} file(s) under {out}/")
            for w in warnings:
                self.log.emit(f"  WARN: {w}")
            self.log.emit("Staging patches and running make "
                          "(about a minute)…")
            rom, sym, rom_md5 = B.build_rom(
                self.repo, out, os.path.join(out, 'build'))
            mpath = B.write_manifest(os.path.join(out, 'build'), prj,
                                     self.project_path, rom, sym, rom_md5,
                                     warnings)
            res.ok = True
            res.rom_path = rom
            res.rom_md5 = rom_md5
            res.manifest_path = mpath
            import json
            res.bank_usage = json.load(open(mpath)).get('bank_usage', {})
            self.log.emit(f"ROM: {rom}")
            self.log.emit(f"md5: {rom_md5}")
        except Exception as e:                        # surfaced in the log dock
            res.ok = False
            res.error = str(e)
            self.log.emit("BUILD FAILED:")
            self.log.emit(str(e))
            self.log.emit(traceback.format_exc(limit=3))
        self.finished_build.emit(res)
