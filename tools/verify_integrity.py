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
  5. TOOL SELFTESTS the table generators' --selftest round-trips still pass, so a
                   hand edit to a generated table cannot silently diverge from
                   the JSON/ROM it is supposed to reproduce. SKIPPED (not failed)
                   when data/DWM-original.gbc is absent — the ROM is gitignored
                   and user-provided, and CI runs without it.

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
TOOLS = os.path.join(REPO, "tools")
ROM_PATH = os.path.join(REPO, "data", "DWM-original.gbc")

# Check 5. Each tool exposes --selftest and exits non-zero on any mismatch.
# These prove the emitted tables still reproduce the ROM/JSON byte-for-byte;
# without this they only ran when someone remembered to invoke them.
SELFTEST_TOOLS = [
    "build_breeding.py",       # breeding family/special tables round-trip
    "build_library_table.py",  # library grouping reproduces vanilla bounds
    "build_skill_tables.py",   # skill MP/learn/record tables byte-identical
]

PATCH_FILES = [
    "bank_000.asm", "bank_001.asm", "bank_003.asm", "bank_004.asm",
    "bank_006.asm", "bank_007.asm", "bank_00b.asm", "bank_012.asm",
    "bank_011.asm", "bank_014.asm", "bank_016.asm", "bank_017.asm", "bank_018.asm", "bank_009.asm", "bank_036.asm", "bank_041.asm", "bank_04d.asm", "bank_04f.asm",
    "bank_054.asm", "bank_053.asm",
    "bank_04c.asm", "bank_058.asm", "bank_05f.asm", "bank_059.asm",
    "bank_052.asm", "bank_050.asm",
    "bank_00a.asm", "bank_015.asm", "bank_051.asm",  # S60 CF3 walker redirects
    "wram.asm", "game.asm",
]
PATCH_NEW_FILES = ["bank_060.asm", "bank_064.asm", "bank_067.asm", "bank_069.asm", "bank_06a.asm", "bank_071.asm", "bank_072.asm", "bank_073.asm", "bank_07e.asm"]  # don't exist in clean disassembly/

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
    print("[1/5] Clean build (byte-perfect check)...")
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
    print("[2/5] Patched build (custom content check)...")
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
    print("[3/5] Tree restore check...")
    bad = [f for f in PATCH_NEW_FILES
           if os.path.exists(os.path.join(DIS, f))]
    if bad:
        print(f"  FAIL: leftover patch files in disassembly/: {bad}")
        return False
    print("  OK")
    return True


def check_doc_sanity():
    print("[4/5] Documentation MD5 sanity...")
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


def check_tool_selftests():
    print("[5/5] Tool selftests (generated tables vs ROM)...")
    # ROM-tolerant BY DESIGN. These generators decode tables straight out of the
    # original ROM, but data/DWM-original.gbc is gitignored and user-provided:
    # CI verifies the build with only the expected MD5 and has no ROM. Treating
    # an absent ROM as FAIL would break every CI push, so it SKIPs instead.
    if not os.path.exists(ROM_PATH):
        print("  SKIP: data/DWM-original.gbc not present"
              " (CI / no-ROM checkout) — selftests need the ROM")
        return True
    got = md5(ROM_PATH)
    if got != ORIGINAL_MD5:
        print(f"  FAIL: data/DWM-original.gbc MD5 {got}")
        print(f"        expected              {ORIGINAL_MD5}")
        print("  Selftests compare against the canonical ROM; this one is not it.")
        return False

    ok = True
    for tool in SELFTEST_TOOLS:
        if not os.path.exists(os.path.join(TOOLS, tool)):
            print(f"  FAIL: tools/{tool} is missing")
            ok = False
            continue
        r = run(f"python3 tools/{tool} --selftest", REPO)
        if r.returncode != 0:
            print(f"  FAIL: {tool} --selftest exited {r.returncode}")
            for line in (r.stdout + r.stderr).splitlines()[-8:]:
                print(f"    | {line}")
            ok = False
        else:
            print(f"  OK: {tool}")
    return ok


def main():
    clean_only = "--clean" in sys.argv
    results = [check_clean_build()]
    if not clean_only:
        if results[0]:
            results.append(check_patched_build())
        results.append(check_tree_restored())
        results.append(check_doc_sanity())
        results.append(check_tool_selftests())
    if all(results):
        print("\nINTEGRITY: PASS")
        return 0
    print("\nINTEGRITY: FAIL — fix before committing or continuing work")
    return 1


if __name__ == "__main__":
    sys.exit(main())
