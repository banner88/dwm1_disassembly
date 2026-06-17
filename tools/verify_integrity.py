#!/usr/bin/env python3
"""Repo integrity verifier — run at the START and END of every session.

Checks, in order:
  1. CLEAN BUILD   disassembly/ builds and MD5 == ORIGINAL_MD5 (1ca657...).
                   This is the byte-perfect guarantee. If it fails, the session
                   must fix it before doing ANYTHING else.
  2. PATCHED BUILD patches/*.asm applied on top builds without errors and
                   bank $60 is populated (custom content present).
  3. TREE RESTORE  working tree is restored to clean state afterwards.
  4. DOC SANITY    no documentation file claims a different "original MD5".

Exit code 0 = all good. Non-zero = integrity broken; see output.

Usage:
    python3 tools/verify_integrity.py            # full check
    python3 tools/verify_integrity.py --clean    # clean build only (fast-ish)
"""
import hashlib
import os
import re
import shutil
import subprocess
import sys

ORIGINAL_MD5 = "1ca6579359f21d8e27b446f865bf6b83"
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIS = os.path.join(REPO, "disassembly")
PATCHES = os.path.join(REPO, "patches")
DOCS = os.path.join(REPO, "documentation")

PATCH_FILES = [
    "bank_000.asm", "bank_001.asm", "bank_004.asm", "bank_006.asm",
    "bank_007.asm", "bank_00b.asm", "bank_016.asm", "bank_017.asm",
    "wram.asm", "game.asm",
]
PATCH_NEW_FILES = ["bank_060.asm", "bank_064.asm", "bank_067.asm", "bank_069.asm"]  # don't exist in clean disassembly/

BUILD_ARTIFACTS = ["game.o", "game.gbc", "game.sym", "game.map"]


def run(cmd, cwd):
    return subprocess.run(cmd, cwd=cwd, shell=True,
                          capture_output=True, text=True)


def md5(path):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def clean_artifacts():
    for f in BUILD_ARTIFACTS:
        p = os.path.join(DIS, f)
        if os.path.exists(p):
            os.remove(p)


def build():
    clean_artifacts()
    r = run("make", DIS)
    ok = r.returncode == 0 and os.path.exists(os.path.join(DIS, "game.gbc"))
    return ok, (r.stdout + r.stderr)


def check_clean_build():
    print("[1/4] Clean build (byte-perfect check)...")
    ok, log = build()
    if not ok:
        print("  FAIL: clean build did not produce game.gbc")
        print("  ---- build log tail ----")
        print("\n".join(log.splitlines()[-15:]))
        return False
    got = md5(os.path.join(DIS, "game.gbc"))
    if got != ORIGINAL_MD5:
        print(f"  FAIL: clean build MD5 {got}")
        print(f"        expected         {ORIGINAL_MD5}")
        print("  The clean disassembly has DRIFTED from the original ROM.")
        print("  Do not proceed until this is fixed. Diff against the")
        print("  original ROM bank-by-bank to locate the divergence:")
        print("    python3 -c \"see documentation/SESSION_PROTOCOL.md\"")
        return False
    print(f"  OK: {got} (byte-perfect)")
    return True


def check_patched_build():
    print("[2/4] Patched build (custom content check)...")
    # Snapshot clean files we are about to overwrite
    backups = {}
    for f in PATCH_FILES:
        src = os.path.join(DIS, f)
        backups[f] = open(src, "rb").read() if os.path.exists(src) else None
    try:
        for f in PATCH_FILES + PATCH_NEW_FILES:
            p = os.path.join(PATCHES, f)
            if os.path.exists(p):
                shutil.copy(p, os.path.join(DIS, f))
        ok, log = build()
        if not ok:
            print("  FAIL: patched build errored")
            print("\n".join(log.splitlines()[-15:]))
            return False
        rom = open(os.path.join(DIS, "game.gbc"), "rb").read()
        bank60 = rom[0x60 * 0x4000:0x61 * 0x4000]
        used = sum(1 for b in bank60 if b != 0)
        if used < 16:
            print(f"  FAIL: bank $60 nearly empty ({used} nonzero bytes) —"
                  " custom content missing from patched build")
            return False
        got = md5(os.path.join(DIS, "game.gbc"))
        if got == ORIGINAL_MD5:
            print("  FAIL: patched build MD5 equals original — patches"
                  " were not applied")
            return False
        print(f"  OK: patched ROM builds, bank $60 holds {used} bytes")
        return True
    finally:
        # Always restore the clean tree
        for f, data in backups.items():
            if data is not None:
                open(os.path.join(DIS, f), "wb").write(data)
        for f in PATCH_NEW_FILES:
            p = os.path.join(DIS, f)
            if os.path.exists(p):
                os.remove(p)
        clean_artifacts()


def check_tree_restored():
    print("[3/4] Tree restore check...")
    bad = [f for f in PATCH_NEW_FILES
           if os.path.exists(os.path.join(DIS, f))]
    if bad:
        print(f"  FAIL: leftover patch files in disassembly/: {bad}")
        return False
    print("  OK")
    return True


def check_doc_sanity():
    print("[4/4] Documentation MD5 sanity...")
    bad = []
    pat = re.compile(r"\b([0-9a-f]{32})\b")
    for root, _dirs, files in os.walk(DOCS):
        for name in files:
            if not name.endswith(".md"):
                continue
            path = os.path.join(root, name)
            text = open(path, errors="replace").read()
            for m in pat.finditer(text):
                h = m.group(1)
                if h != ORIGINAL_MD5:
                    # allow hashes explicitly marked as patched/historical
                    line = text[max(0, m.start() - 120):m.end() + 120].lower()
                    if any(k in line for k in
                           ("patched", "drift", "historical", "wrong",
                            "superseded", "do not use")):
                        continue
                    bad.append((name, h))
    readme = os.path.join(REPO, "README.md")
    if os.path.exists(readme):
        for m in pat.finditer(open(readme, errors="replace").read()):
            if m.group(1) != ORIGINAL_MD5:
                bad.append(("README.md", m.group(1)))
    if bad:
        print("  FAIL: docs reference unexpected MD5s presented as canonical:")
        for name, h in bad:
            print(f"    {name}: {h}")
        print(f"  The ONLY canonical original MD5 is {ORIGINAL_MD5}.")
        return False
    print("  OK")
    return True


def main():
    clean_only = "--clean" in sys.argv
    results = [check_clean_build()]
    if not clean_only:
        if results[0]:
            results.append(check_patched_build())
        results.append(check_tree_restored())
        results.append(check_doc_sanity())
    if all(results):
        print("\nINTEGRITY: PASS")
        return 0
    print("\nINTEGRITY: FAIL — fix before committing or continuing work")
    return 1


if __name__ == "__main__":
    sys.exit(main())
