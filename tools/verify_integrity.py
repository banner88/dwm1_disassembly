#!/usr/bin/env python3
"""Repo integrity verifier — run at the START and END of every session.

Checks, in order:
  1. CLEAN BUILD   disassembly/ builds and MD5 == ORIGINAL_MD5 (1ca657...).
                   This is the byte-perfect guarantee. If it fails, the session
                   must fix it before doing ANYTHING else.
  2. PATCHED BUILD patches/*.asm applied on top builds without errors and
                   bank $60 is populated (custom content present), AND (S120)
                   its md5 == editor2/tests/test_compiler.py REFERENCE_MD5: the
                   committed overlay must be exactly what the compiler emits for
                   editor2/example-project (S119 re-pinned the template but left
                   the S117 patches/bank_060.asm committed — bank $04 then
                   far-called a bank $60 entry 9 that the overlay lacked, and
                   nothing failed). Fix on failure: `python3 tools/build_project.py
                   --project editor2/example-project --apply`.
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
# S76: the German (SGB Enhanced) build. A second ORIGINAL ROM, never a build
# target -- the byte-perfect check in step 1 still pins ORIGINAL_MD5 only.
GERMAN_MD5 = "08bca718c62e3c2870a2df107fc0a562"
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
    "script_param_counts.py",  # S96: opcode arity table == bank-$04 handler analysis
    "census_room_animation.py",  # S99: room-animation census JSON == bank-$01 dispatch table + handler operands
    "map_gate_names.py",         # S100: gate_names.json == GateFloorDataTable (floors + boss map) x FAQ
    "extract_gamedata.py",       # S103: gamedata_vanilla.json (the Layer A-lite base) == ROM tables
    "build_family_icon.py",      # S104: family_icons.json vanilla icons == ROM; Spirit grid == $4F:$41B0 glyph + bank $6D SpiritIconStream
    "extract_monster_follower_layouts.py",  # S107: the 155 walking layouts (+ stored bytes, per-bank instances / frames) == ROM
    "dump_dialogue.py",          # S108: dialogue.json (all 2,560 text ids, measured; + the text tables) raw bytes == ROM
    "decode_battle_animations.py",  # S112: battle_animations.json (schema 2: 45 animations, per-skill tables) == ROM
    "dump_encounters.py",        # S114: encounters.json (gate floor -> list by the game's rule, 5 slots, chance / max count) == ROM
    "dump_sound_catalog.py",     # S116: sound_catalog.json anchors (RoomBGMTable, the SetBGM code sites, the bank $55 sound test) == ROM
    "census_cutscenes.py",       # S118: cutscene_census.json scene list == the cutscene catalogue decoded from the ROM (+ totals)
    "census_gate_floor_types.py",  # S120: gate_floor_types.json tables + 32 gate rows == ROM bank $16, the 16 floor-type pictures present
    "audit_mapid_range.py",      # S120: every `ld a, [wMapID]` site in both trees has a verdict (no NEEDS_REVIEW, no stale key); was failing unseen S73-S99 and S116-S119
    "census_maze.py",            # S122: maze_pieces.json (maze tables, the 254 maze screens, 16 themes, metatiles) == ROM banks $16/$17/ROM0
    "extract_service_lines.py",  # S126: service_lines.json (the service screens' lines in frame + words, the medal rewards) == ROM; every line rebuilds
    "census_raising.py",         # S130: raising_census.json clean + a quick PyBoy re-run: creation / level-up / learning / breeding / birth model == the game's routines
    "census_dive.py",            # S130: dive_census.json == a re-derived sample (shortest walks, steps between battles; GATE_GENERATION §4.4)
    "build_balance_anchor.py",   # S130: balance_vanilla.json covers every story fight x profile + every gate dive, matches SIM_VERSION / the raising digest, 3 fights + 1 dive re-derived
    "census_story_state.py",     # S132: story_state_census.json clean (the game's own win tails / arena cascades in PyBoy == editor2/core/story_state.py) + every story point re-derived equal
]

PATCH_FILES = [
    "bank_000.asm", "bank_001.asm", "bank_003.asm", "bank_004.asm",
    "bank_006.asm", "bank_007.asm", "bank_00b.asm", "bank_012.asm",
    "bank_011.asm", "bank_014.asm", "bank_02e.asm", "bank_016.asm", "bank_017.asm", "bank_018.asm", "bank_009.asm", "bank_041.asm", "bank_04d.asm", "bank_04f.asm",
    "bank_054.asm", "bank_053.asm",
    "bank_04c.asm", "bank_058.asm", "bank_05f.asm", "bank_059.asm",
    "bank_052.asm", "bank_050.asm", "bank_056.asm", "bank_055.asm",
    "bank_00a.asm", "bank_015.asm", "bank_051.asm",  # S60 CF3 walker redirects
    "bank_013.asm",  # S103 P3.9: gamedata exp/growth curve regions
    "bank_010.asm",  # S107 P3.10 part 2a: gamedata.art follower layout/attr regions
    "bank_002.asm",  # S112 P3.11e: ReadSeqStepFork (new battle animations' timelines)
    "bank_00e.asm",  # S121 the Milly hook: region milly_bedroom_script (the bedroom's dresser scene)
    "wram.asm", "game.asm",
]
PATCH_NEW_FILES = ["bank_ext.asm", "bank_060.asm", "bank_064.asm", "bank_067.asm", "bank_069.asm", "bank_06a.asm", "bank_06b.asm", "bank_06c.asm", "bank_06d.asm", "bank_06e.asm", "bank_06f.asm", "bank_070.asm", "bank_071.asm", "bank_072.asm", "bank_073.asm", "bank_074.asm", "bank_075.asm", "bank_076.asm", "bank_077.asm", "bank_079.asm", "bank_07a.asm", "bank_07c.asm", "bank_07e.asm", "bank_07f.asm"]  # S107: art banks $7A/$7C/$7F (gamedata.art); S112: $6F/$70 new battle animations; S114: $76 encounter lists; S116: $75 second song bank; S117: $77 shops; S121: $79 story hooks  # don't exist in clean disassembly/

# S134 (ROADMAP ARC CAP1): bank_ext.asm = banks $80-$FF of the 4 MB ROM (compiler-
# generated). Any OTHER bank file in patches/ without a clean counterpart (ARC CAP2's
# place banks bank_080.asm …) is a new file too — discovered, so the list cannot go
# stale. editor2/core/builder.py applies the same rule (keep the two in step).
_NEW_FILE_RE = re.compile(r"bank_(?:[0-9a-f]{3}|ext)\.asm")
PATCH_NEW_FILES = PATCH_NEW_FILES + sorted(
    f for f in (os.listdir(PATCHES) if os.path.isdir(PATCHES) else [])
    if _NEW_FILE_RE.fullmatch(f) and f not in PATCH_NEW_FILES and f not in PATCH_FILES
    and not os.path.exists(os.path.join(DIS, f)))

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
    print("[1/6] Clean build (byte-perfect check)...")
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


def reference_md5():
    """S120: the example project's pinned patched md5 (test_compiler)."""
    path = os.path.join(REPO, "editor2", "tests", "test_compiler.py")
    m = re.search(r'^REFERENCE_MD5\s*=\s*"([0-9a-f]{32})"', open(path).read(), re.M)
    return m.group(1) if m else None


def check_patched_build():
    print("[2/6] Patched build (custom content check)...")
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
        open("/tmp/verify_patched.gbc", "wb").write(rom)  # for check 6
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
        # S120: the committed overlay == the compiler's example-project build.
        pin = reference_md5()
        if pin is None:
            print("  FAIL: REFERENCE_MD5 not found in editor2/tests/test_compiler.py")
            return False
        if got != pin:
            print(f"  FAIL: committed overlay builds {got}, the compiler pin "
                  f"(test_compiler REFERENCE_MD5) is {pin} — a compiler-owned "
                  "file in patches/ is stale. Run: python3 tools/build_project.py "
                  "--project editor2/example-project --apply (PROJECT_COMPILER §1)")
            return False
        print(f"  OK: patched ROM builds, bank $60 holds {used} bytes, "
              f"== compiler pin {pin[:8]}…")
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
    print("[3/6] Tree restore check...")
    bad = [f for f in PATCH_NEW_FILES
           if os.path.exists(os.path.join(DIS, f))]
    if bad:
        print(f"  FAIL: leftover patch files in disassembly/: {bad}")
        return False
    print("  OK")
    return True


def check_doc_sanity():
    print("[4/6] Documentation MD5 sanity...")
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
                    # S76: the German build is a SECOND original ROM, not a
                    # patched or historical one, so none of the qualifiers above
                    # describe it honestly. Allow it by exact identity and only
                    # where the surrounding text names the region -- this stays
                    # as tight as the rule it extends.
                    if h == GERMAN_MD5 and "german" in line:
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
    print("[5/6] Tool selftests (generated tables vs ROM)...")
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


def check_custom_data():
    print("[6/6] Custom-data crash-config validation (S75)...")
    # Hard-errors on crash-capable configurations: universal-qualifier learn
    # rows without the code-2 fence, missing slot-index fence, and redirected
    # battle-sprite streams that do not decode to the original tile count.
    rom_arg = "/tmp/verify_patched.gbc" if os.path.exists("/tmp/verify_patched.gbc") else None
    cmd = "python3 tools/validate_custom_data.py" + (f" --rom {rom_arg}" if rom_arg else " --records-only")
    r = run(cmd, REPO)
    if r.returncode != 0:
        print(r.stdout.rstrip())
        print("  FAIL")
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
        results.append(check_tool_selftests())
        results.append(check_custom_data())
    if all(results):
        print("\nINTEGRITY: PASS")
        return 0
    print("\nINTEGRITY: FAIL — fix before committing or continuing work")
    return 1


if __name__ == "__main__":
    sys.exit(main())
