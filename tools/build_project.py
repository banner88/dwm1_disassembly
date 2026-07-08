#!/usr/bin/env python3
"""build_project.py — compile a project.json into the patch overlay + ROM.

The headless backend of the editor (ROADMAP Phase 2; reference:
documentation/PROJECT_COMPILER.md). project.json is the source of truth;
this tool generates patches/bank_060.asm + patches/bank_071.asm and splices
the @BUILD_PROJECT regions of patches/bank_017.asm + patches/wram.asm, then
(optionally) builds the patched ROM exactly the way verify_integrity.py
check 2 does, emitting build/manifest.json + game.sym for debugging.

Usage:
  python3 tools/build_project.py --project editor2/example-project
      [--out editor2/example-project/build]   output dir (default: <proj>/build)
      [--build]                               stage + make + manifest
      [--apply]                               copy generated files into patches/
      [--expect-md5 MD5]                      fail unless the ROM matches
      [--pin-templates]                       record engine-template sha256s

Typical flows:
  regression check:  --project … --build --expect-md5 <reference md5>
  author + test:     --project … --build          (ROM at <out>/build/rom.gbc)
  commit to overlay: --project … --apply          (after the ROM is verified)
"""
import argparse
import os
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)

from editor2.core import compiler as C          # noqa: E402
from editor2.core import builder as B           # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--project', required=True)
    ap.add_argument('--out')
    ap.add_argument('--build', action='store_true')
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--expect-md5')
    ap.add_argument('--pin-templates', action='store_true')
    args = ap.parse_args()

    if args.pin_templates:
        for line in C.pin_templates():
            print("pinned:", line)

    proj = args.project
    out = args.out or os.path.join(
        proj if os.path.isdir(proj) else os.path.dirname(proj), 'build')

    outputs, prj, warnings = C.compile_project(proj, REPO)
    written = C.write_outputs(outputs, out)
    print(f"generated {len(written)} file(s) under {out}/")
    for w in warnings:
        print(f"  WARN: {w}")

    rom_md5 = None
    if args.build:
        rom, sym, rom_md5 = B.build_rom(REPO, out, os.path.join(out, 'build'))
        mpath = B.write_manifest(os.path.join(out, 'build'), prj, proj,
                                 rom, sym, rom_md5, warnings)
        print(f"ROM: {rom}\nmd5: {rom_md5}\nmanifest: {mpath}")
        if args.expect_md5:
            if rom_md5 != args.expect_md5:
                print(f"FAIL: md5 {rom_md5} != expected {args.expect_md5}")
                return 1
            print("OK: ROM matches expected md5 (byte-identical)")

    if args.apply:
        gen_patches = os.path.join(out, 'patches')
        for f in sorted(os.listdir(gen_patches)):
            dst = os.path.join(REPO, 'patches', f)
            shutil.copy(os.path.join(gen_patches, f), dst)
            print(f"applied → patches/{f}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
