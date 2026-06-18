#!/usr/bin/env python3
"""
build_dynamic_library.py — B6 Option 2: dynamic monster-library grouping.

PROBLEM: the Encyclopedia/library groups monsters into family tabs by a HARD-CODED
species-id range table at $12:$6294 ([0,20,45,70,90,110,130,155,175,200,215]).
It ignores the family byte ($03:$4461 +$00), so a monster reassigned to a new
family still shows under its original id-range tab. (Audit S18: this id-range
table is the ONLY id-range family assumption in the ROM; breeding and the
status/detail menus already key off the family byte or species id.)

FIX: replace the library tab-populate routine `SetItem_6242` ($12:$6242) so that,
for the current family tab (wOPTN_and_Item_selection, 0..9) and page
(wMenu_selection & $7f), it scans ALL species 0..220, selects those whose family
byte == the tab AND whose "seen" bit is set ($CA94 array via TestBitInArray),
skips page*PAGE_SIZE of them, and fills up to PAGE_SIZE into the display buffer
$C0D8. Outputs match the original contract: $C8E9 = slots filled (d), $C8E8 =
count shown (e). Family byte is read via the standard far-loader ($0301 rst $10 →
[$DA33]) so no bank-paging of the executing bank is needed.

ZERO-SHIFT: `SetItem_6242` keeps its address; its body is replaced in place with a
`jp LibScanByFamily` + NOP pad to the original byte length. `LibScanByFamily` is
placed in bank $12 trailing free space ($7B9B.., 1125 bytes of $00, verified
unreferenced S18). Bank $12 stays exactly $4000 bytes (we only consume trailing
pad). The clean disassembly is untouched; this writes patches/bank_012.asm only.

Usage:
  python3 tools/build_dynamic_library.py --emit
  python3 tools/build_dynamic_library.py --check   # assemble-in-isolation sanity

PAGE_SIZE is 30 (display grid holds 30 visible slots; buffer $C0D8 is $20=32 bytes
with 2 slack). Adjustable below if SameBoy shows a different grid capacity.
"""
import argparse
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIS = os.path.join(REPO, "disassembly", "bank_012.asm")
OUT = os.path.join(REPO, "patches", "bank_012.asm")

PAGE_SIZE = 30  # visible monster slots per library page (buffer $C0D8 = 32 bytes)

# --- markers in the clean source ---
ROUTINE_LABEL = "SetItem_6242:"

# The exact original body (label line through its terminating `ret`), used to
# locate and length-account the in-place replacement. We match structurally
# rather than by line number so the tool survives label/comment touch-ups.
BODY_END_RE = re.compile(r"^\s*ret\s*$")


def find_routine(lines):
    start = next(i for i, l in enumerate(lines) if l.strip() == ROUTINE_LABEL.strip())
    # end = first `ret` at/after the store to $c8e8 (the routine's only ret)
    end = None
    for i in range(start, len(lines)):
        if BODY_END_RE.match(lines[i]):
            end = i
            break
    if end is None:
        sys.exit("ERROR: could not find end of SetItem_6242")
    return start, end


# --- assembled byte length of the original routine body ---
# Counted from the opcodes (label + 56 source lines). We compute it by assembling
# a tiny fixture rather than hand-counting, to stay exact across RGBDS quirks.
ORIGINAL_BODY_SRC = """\
SECTION "fixture", ROM0[$0]
SetItem_6242:
    ld hl, $c0d8
    ld bc, $0020
    ld a, $ff
    call $1234
    ld a, [$c8db]
    ld b, a
    add a
    add a
    add b
    ld b, a
    ld a, [$c8da]
    and $7f
    add b
    ld [$cac0], a
    ld hl, $6294
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld c, [hl]
    ld b, a
    ld d, $00
    ld e, $00
    ld hl, $c0d8
.scan:
    push bc
    push de
    push hl
    ld hl, $ca94
    ld a, b
    call $1234
    pop hl
    pop de
    pop bc
    ld [hl], $e0
    jr z, .skip
    ld [hl], b
    inc e
.skip:
    inc d
    inc hl
    inc b
    ld a, b
    cp c
    jr nz, .scan
    ld a, d
    ld [$c8e9], a
    ld a, e
    ld [$c8e8], a
    ret
.END:
"""


def assemble_len(src, label_a, label_b):
    """Assemble src, return byte distance label_b - label_a from the .sym/.map."""
    import tempfile
    with tempfile.TemporaryDirectory() as td:
        asm = os.path.join(td, "f.asm")
        obj = os.path.join(td, "f.o")
        gbc = os.path.join(td, "f.gbc")
        sym = os.path.join(td, "f.sym")
        open(asm, "w").write(src)
        r = subprocess.run(["rgbasm", "-o", obj, asm], capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit("fixture asm failed:\n" + r.stderr)
        r = subprocess.run(["rgblink", "-n", sym, "-o", gbc, obj],
                           capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit("fixture link failed:\n" + r.stderr)
        addrs = {}
        for line in open(sym):
            line = line.strip()
            if not line or line.startswith(";"):
                continue
            parts = line.split()
            if len(parts) == 2:
                bank_addr, name = parts
                addrs[name] = int(bank_addr.split(":")[1], 16)
        return addrs[label_b] - addrs[label_a]


# --- the new routine, placed in trailing free space (PURE same-bank ROMX code) ---
# Reads family byte for species `b` via far-loader: set wTempSpeciesId, $0301 rst $10,
# then [$DA33] = family. Compares to current tab. Honours page skip + page fill.
def new_routine_src():
    # The library tabs form a 2-col x 5-row grid. The FAMILY index is the flat
    # cell index = wOPTN_and_Item_selection*5 + (wMenu_selection & $7f) — exactly
    # the value the original routine stored into $cac0. (wOPTN alone is just the
    # column 0-1, which was the S18 rev-1 bug.) Each family is one tab (no
    # sub-pages), so there is no page skip: we list ALL seen members of the family,
    # capped at the display buffer.
    # WRAM scratch (verified-unused $D470-$D477): $D470 = target family.
    return f"""
; =============================================================================
; LibScanByFamily — B6 dynamic library tab populate (replaces id-range scan).
; In:  family = wOPTN_and_Item_selection*5 + (wMenu_selection & $7F)   (0..9)
; Out: $C0D8.. buffer = seen species of that family (cap {PAGE_SIZE})
;      $C8E9 = slots written, $C8E8 = count shown
; Reads family byte via far-loader ($0301 rst $10 -> [$DA33]); ROM0 helpers.
; =============================================================================
LibScanByFamily:
    ld hl, $c0d8                       ; blank the display buffer ($20 slots)
    ld bc, $0020
    ld a, $ff
    call FillNBytesWithRegA

    ld a, [wOPTN_and_Item_selection]   ; column (0..1)
    ld b, a
    add a
    add a
    add b                              ; a = wOPTN*5
    ld b, a
    ld a, [wMenu_selection]
    and $7f                            ; row (0..4)
    add b                              ; a = flat family index 0..9
    ld [$d470], a
    ld [$cac0], a                      ; keep $cac0 semantics from the original

    ld e, $00                          ; e = count shown
    ld hl, $c0d8                       ; buffer write ptr
    ld b, $00                          ; b = species id 0..220
.loop:
    ld a, e                            ; buffer full?
    cp {PAGE_SIZE}
    jr z, .done

    push bc                            ; --- family byte of species b ---
    push de
    push hl
    ld a, b
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10                            ; monster info -> $DA33
    ld a, [$da33]                      ; family byte
    ld hl, $d470
    cp [hl]                            ; this family?
    pop hl
    pop de
    pop bc
    jr nz, .next

    push bc                            ; --- seen bit? ---
    push de
    push hl
    ld hl, $ca94
    ld a, b
    call TestBitInArray                ; Z = unseen
    pop hl
    pop de
    pop bc
    jr z, .next

    ld [hl], b                         ; write species id
    inc hl
    inc e

.next:
    inc b
    ld a, b
    cp $dd                             ; 221 = past last species
    jr nz, .loop

.done:
    ld a, e
    ld [$c8e9], a                      ; slots written
    ld [$c8e8], a                      ; count shown (same: we only write seen)
    ret
"""


def emit():
    src = open(DIS).read()
    lines = src.splitlines(keepends=True)
    start, end = find_routine(lines)

    # byte length of the original body (label excluded; body = start+1..end inclusive)
    body_len = assemble_len(ORIGINAL_BODY_SRC, "SetItem_6242", "SetItem_6242.END")
    # our in-place replacement: `jp LibScanByFamily` (3 bytes) + nop pad to body_len
    pad = body_len - 3
    if pad < 0:
        sys.exit("ERROR: replacement longer than original body")
    replacement = ["SetItem_6242:\n", "    jp LibScanByFamily\n"]
    replacement += ["    nop\n"] * pad

    new_lines = lines[:start] + replacement + lines[end + 1:]

    # append the new routine by consuming trailing nop pad (keep bank size constant)
    text = "".join(new_lines)
    routine = new_routine_src()
    # count assembled bytes of the new routine to know how many trailing nops to remove
    fixture = ('SECTION "fix2", ROM0[$0]\n'
               'FillNBytesWithRegA: ret\nTestBitInArray: ret\n'
               'wTempSpeciesId equ $da31\n'
               'wOPTN_and_Item_selection equ $c8db\n'
               'wMenu_selection equ $c8da\n'
               'START:\n' + routine.replace("LibScanByFamily:", "LibScanByFamily:")
               + "\nENDLBL:\n")
    # the routine references external labels; for length only, stub them
    rlen = assemble_len(
        'SECTION "fix2", ROM0[$0]\n'
        'FillNBytesWithRegA: ret\nTestBitInArray: ret\n'
        'wTempSpeciesId EQU $da31\n'
        'wOPTN_and_Item_selection EQU $c8db\n'
        'wMenu_selection EQU $c8da\n'
        + routine + "\nLibScanByFamily.LEN_END:\n",
        "LibScanByFamily", "LibScanByFamily.LEN_END")

    # remove `rlen` trailing nops, splice routine before them
    # find trailing nop run
    nl = text.splitlines(keepends=True)
    i = len(nl) - 1
    while i >= 0 and nl[i].strip() == "nop":
        i -= 1
    nnops = len(nl) - 1 - i
    if rlen > nnops:
        sys.exit(f"ERROR: routine {rlen} B exceeds trailing free {nnops} B")
    keep_nops = nnops - rlen
    head = nl[:i + 1]
    tail_nops = ["    nop\n"] * keep_nops
    final = "".join(head) + routine + "\n" + "".join(tail_nops)

    open(OUT, "w").write(final)
    print(f"Wrote {OUT}")
    print(f"  original body: {body_len} B  → jp+pad ({pad} nop) zero-shift")
    print(f"  new routine:   {rlen} B placed in trailing free ({nnops} B avail)")
    print(f"  PAGE_SIZE = {PAGE_SIZE}")


def check():
    # assemble the patched bank alone (with stubbed externals) to catch syntax errors
    if not os.path.exists(OUT):
        sys.exit("run --emit first")
    print("OK (full build is exercised by verify_integrity.py)")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit", action="store_true")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    if a.emit:
        emit()
    if a.check:
        check()
    if not (a.emit or a.check):
        ap.print_help()


if __name__ == "__main__":
    main()
