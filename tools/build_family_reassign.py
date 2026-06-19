#!/usr/bin/env python3
"""
build_family_reassign.py — B6 family-byte reassignment authoring (same-size).

Rewrites the Family byte (offset $00 of each 43-byte monster-info entry at
bank $03:$4461) for a set of monsters, producing patches/bank_003.asm from the
clean disassembly/bank_003.asm. Pure same-size db edits: zero byte-count change,
so no table downstream shifts. The family byte is read OUTSIDE breeding only for
DISPLAY (family name/icon) and copied into the party/battle struct — no system
gates eligibility on family == 9 (verified S18, see KEY_LESSONS). Recruit
eligibility is the enemy-stats joinability byte ($14 +$3) + boss table
($14:$4897), independent of this byte.

Source of truth for the swap: extracted/breeding_family_reassign.json
  { "_generator": ...,
    "reassignments": [ {"id": 214, "name": "Darkdrium", "from": 9, "to": 1}, ... ] }

Usage:
  python3 tools/build_family_reassign.py --emit      # write patches/bank_003.asm
  python3 tools/build_family_reassign.py --selftest  # verify clean source decodes
                                                     # to vanilla families, and the
                                                     # emit changes exactly the
                                                     # intended bytes
Validation:
  - every target id present exactly once in the source
  - 'from' matches the current vanilla family byte (guards a stale spec)
  - emitted file differs from clean source ONLY in the targeted family db lines
  - family byte stays in 0..9
"""
import argparse
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIS = os.path.join(REPO, "disassembly", "bank_003.asm")
OUT = os.path.join(REPO, "patches", "bank_003.asm")
SPEC = os.path.join(REPO, "extracted", "breeding_family_reassign.json")
ROM = os.path.join(REPO, "data", "DWM-original.gbc")

FAMILY_NAMES = {0: "Slime", 1: "Dragon", 2: "Beast", 3: "Bird", 4: "Plant",
                5: "Bug", 6: "Devil", 7: "Zombie", 8: "Material", 9: "Boss",
                10: "Spirit"}   # B9: 11th family (Spirit). Raw byte $0A.

INFO_BASE = 0x03 * 0x4000 + (0x4461 - 0x4000)
STRIDE = 43
N_MONSTERS = 221

# Matches the family db line immediately under a monster label.
# e.g.  "    db 0  ; Family: Slime"
FAMILY_LINE = re.compile(r"^(\s*db\s+)(\d+)(\s*;\s*Family:.*)$")
LABEL = re.compile(r"^MonsterInfo_(\d+)_")


def rom_family(rom, sid):
    return rom[INFO_BASE + sid * STRIDE + 0x00]


def load_spec(path=None):
    with open(path or SPEC) as f:
        spec = json.load(f)
    return spec["reassignments"]


def index_source(lines):
    """Return {species_id: family_line_index} by walking labels then the next
    family db line. Robust to comments/blank lines between label and db."""
    out = {}
    i = 0
    while i < len(lines):
        m = LABEL.match(lines[i].strip())
        if m:
            sid = int(m.group(1))
            j = i + 1
            while j < len(lines) and not FAMILY_LINE.match(lines[j]):
                j += 1
            if j < len(lines):
                out[sid] = j
        i += 1
    return out


def emit(spec, rom):
    with open(DIS) as f:
        src = f.read()
    lines = src.splitlines(keepends=True)
    idx = index_source(lines)

    seen = set()
    for r in spec:
        sid, frm, to = r["id"], r["from"], r["to"]
        if sid in seen:
            sys.exit(f"ERROR: id {sid} listed twice in spec")
        seen.add(sid)
        if to not in FAMILY_NAMES:
            sys.exit(f"ERROR: target family {to} for id {sid} out of range "
                     f"0..{max(FAMILY_NAMES)}")
        if sid not in idx:
            sys.exit(f"ERROR: id {sid} not found in {DIS}")
        # guard: spec 'from' must match vanilla
        van = rom_family(rom, sid)
        if van != frm:
            sys.exit(f"ERROR: id {sid} spec from={frm} but vanilla family={van}")
        li = idx[sid]
        m = FAMILY_LINE.match(lines[li])
        cur = int(m.group(2))
        if cur != frm:
            sys.exit(f"ERROR: id {sid} source family db={cur} but spec from={frm}")
        new_line = f"{m.group(1)}{to}  ; Family: {FAMILY_NAMES[to]}  ; reassigned (was {FAMILY_NAMES[frm]})\n"
        lines[li] = new_line

    out_text = "".join(lines)
    with open(OUT, "w") as f:
        f.write(out_text)

    # Verify: only the targeted lines differ from clean source.
    orig_lines = src.splitlines(keepends=True)
    diff_lines = [k for k in range(len(orig_lines)) if orig_lines[k] != lines[k]]
    expect = sorted(idx[r["id"]] for r in spec)
    if diff_lines != expect:
        sys.exit(f"ERROR: emit changed lines {diff_lines}, expected {expect}")

    print(f"Wrote {OUT}")
    for r in spec:
        print(f"  id {r['id']:3d} {r.get('name',''):10s} "
              f"{FAMILY_NAMES[r['from']]}({r['from']}) -> {FAMILY_NAMES[r['to']]}({r['to']})")
    print(f"Same-size db edits: {len(spec)} family bytes, zero shift.")


def selftest(rom):
    # 1) clean source families == vanilla ROM families
    with open(DIS) as f:
        lines = f.read().splitlines()
    idx = index_source([l + "\n" for l in lines])
    if len(idx) != N_MONSTERS:
        sys.exit(f"FAIL: indexed {len(idx)} monsters, expected {N_MONSTERS}")
    bad = 0
    for sid in range(N_MONSTERS):
        src_fam = int(FAMILY_LINE.match(lines[idx[sid]]).group(2))
        if src_fam != rom_family(rom, sid):
            bad += 1
    if bad:
        sys.exit(f"FAIL: {bad} source family bytes disagree with ROM")
    print(f"OK: all {N_MONSTERS} source family bytes == ROM")
    # 2) spec sanity if present
    if os.path.exists(SPEC):
        spec = load_spec()
        for r in spec:
            van = rom_family(rom, r["id"])
            assert van == r["from"], f"spec from mismatch id {r['id']}"
        print(f"OK: spec {len(spec)} reassignments, all 'from' == vanilla")
    print("SELFTEST PASS")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--spec", default=None,
                    help="path to a reassignment spec JSON (default: "
                         "extracted/breeding_family_reassign.json)")
    args = ap.parse_args()
    rom = open(ROM, "rb").read()
    if args.selftest:
        selftest(rom)
    if args.emit:
        spec = load_spec(args.spec)
        emit(spec, rom)
    if not (args.selftest or args.emit):
        ap.print_help()


if __name__ == "__main__":
    main()
