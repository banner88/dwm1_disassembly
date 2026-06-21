#!/usr/bin/env python3
"""
resection_library_tables.py — re-section the misassembled library/family DATA
tables in disassembly/bank_012.asm into labeled db/dw blocks (LABELS/COMMENTS
ONLY — zero byte impact). Idempotent.

Bank $12 is the monster-library / family-tab menu bank. mgbdis decoded several
in-bank DATA tables as fake instructions (e.g. the family id-range bounds read
as `nop / inc d / dec l / ...`), which blocks editing them in source. This tool
converts the genuine data tables to named db/dw and labelizes the raw-pointer
references that reach them, so the editor can address them by label.

TABLES converted (all ROM-verified; see documentation/DATA_STRUCTURES.md
"Library / family-tab menu data (bank $12)"):

  LibraryFamilyTabBounds  $6294  11 B  family id-range boundaries (the S18 case):
                                       SetItem_6242 scans species start..end-1
                                       per family tab; THE ONLY id-range family
                                       assumption in the ROM.
  LibTabColPos_564a        $564a   6 B  3 dw {$00a1,$00e1,$ffff} — tab column
  LibTabColPos_5a8e        $5a8e   6 B  cursor-position words, indexed by the
                                       0/1 column selector (FuncItem_43e2),
                                       $ffff-terminated.
  LibWinLayout_710c/71aa/71f4   window-draw layout streams (ReadPtrFromDE +
  LibWinLayout_759a              the $40c3 draw loop): a 2-byte dest-position
  LibWinLayout_7b42/7b6c         word, then a tile-byte stream where $d8 =
                                       newline (advance dest by $20) and $d9 =
                                       terminator; every other byte is a literal
                                       tile written via `ld [hl+],a`.

ROBUST LINE→ADDRESS MAPPING (no opcode-size summing — that bit Session 22):
zero-byte probe labels are inserted before every instruction line, the tree is
built once, and each line's address is read from the linker `game.sym`. The
exact source-line span of each table is then the lines whose addresses fall in
[start, end). The probe build itself stays byte-perfect (labels emit no bytes),
which the tool asserts. Because every emitted byte is sourced from the ROM and
no real label sits inside any converted range (asserted), the build stays
byte-perfect (verify_integrity.py check 1).
"""
import os, re, shutil, subprocess, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIS  = os.path.join(REPO, "disassembly")
ASM  = os.path.join(DIS, "bank_012.asm")
ROM  = os.path.join(REPO, "data", "DWM-original.gbc")
BANK = 0x12
ORIGINAL_MD5 = "1ca6579359f21d8e27b446f865bf6b83"

# (label, start_addr, end_addr_exclusive, kind)  kind: 'bounds' | 'colpos' | 'layout'
# layout/colpos blocks may hold MULTIPLE labeled sub-tables packed back to back;
# `extra_labels` places a label at an interior start within the same db/dw block.
TABLES = [
    dict(label="LibraryFamilyTabBounds", start=0x6294, end=0x629f, kind="bounds",
         comment=["; Family id-range boundaries (read by SetItem_6242). entry[i]=first species id",
                  "; of family i, entry[i+1]=one past its last. 10 families (0..9) => 11 bounds.",
                  "; THE ONLY id-range family assumption in the ROM (a reassigned monster still",
                  "; lists under its original id-range tab). See DATA_STRUCTURES 'Library menu'."]),
    dict(label="LibTabColPos_564a", start=0x564a, end=0x5650, kind="colpos",
         comment=["; Library tab column cursor-position words, indexed by the 0/1 column",
                  "; selector (wOPTN_and_Item_selection) via FuncItem_43e2. $ffff terminates."]),
    dict(label="LibTabColPos_5a8e", start=0x5a8e, end=0x5a94, kind="colpos",
         comment=["; Library tab column cursor-position words (parallel copy of LibTabColPos_564a",
                  "; for a second menu state). Same FuncItem_43e2 reader; $ffff terminates."]),
    dict(label="LibWinLayout_710c", start=0x710c, end=0x724e, kind="layout",
         extra_labels={0x71aa: "LibWinLayout_71aa", 0x71f4: "LibWinLayout_71f4"},
         comment=["; Library window-draw layout streams (ReadPtrFromDE + draw loop $40c3).",
                  "; Each: dest-position word, then a tile-byte stream; $d8=newline, $d9=end."]),
    dict(label="LibWinLayout_759a", start=0x759a, end=0x75c0, kind="layout",
         comment=["; Library window-draw layout stream (see LibWinLayout_710c for format)."]),
    dict(label="LibWinLayout_7b42", start=0x7b42, end=0x7b9b, kind="layout",
         extra_labels={0x7b6c: "LibWinLayout_7b6c"},
         comment=["; Library window-draw layout streams (see LibWinLayout_710c for format).",
                  "; Last layouts before the bank-$12 trailing free space at $7b9b."]),
]

# Raw-pointer references to labelize (byte-neutral; the label resolves to the
# same address). Exact instruction text -> labeled text.
REF_LABELS = [
    ("ld hl, $6294", "ld hl, LibraryFamilyTabBounds"),
    ("ld de, $564a", "ld de, LibTabColPos_564a"),
    ("ld de, $5a8e", "ld de, LibTabColPos_5a8e"),
    ("ld de, $710c", "ld de, LibWinLayout_710c"),
    ("ld de, $71aa", "ld de, LibWinLayout_71aa"),
    ("ld de, $71f4", "ld de, LibWinLayout_71f4"),
    ("ld de, $759a", "ld de, LibWinLayout_759a"),
    ("ld de, $7b42", "ld de, LibWinLayout_7b42"),
    ("ld de, $7b6c", "ld de, LibWinLayout_7b6c"),
]

DONE_MARKER = "LibraryFamilyTabBounds:"


def rom_bytes(start, end):
    rom = open(ROM, "rb").read()
    base = BANK * 0x4000 + (start - 0x4000)
    return rom[base: base + (end - start)]


def build_line_addr_map(lines):
    """Insert zero-byte probe labels, build once, return {line_idx0: addr}."""
    probed, probe_of = [], {}
    for i, l in enumerate(lines):
        s = l.strip()
        if s and not s.startswith(";") and not (s.endswith(":") and " " not in s):
            probed.append(f"Lprobe_{i}:")
            probe_of[f"Lprobe_{i}"] = i
        probed.append(l)
    backup = ASM + ".probebak"
    shutil.copy(ASM, backup)
    try:
        open(ASM, "w").write("\n".join(probed) + "\n")
        for f in ("game.o", "game.gbc", "game.sym", "game.map"):
            p = os.path.join(DIS, f)
            if os.path.exists(p):
                os.remove(p)
        r = subprocess.run("make", cwd=DIS, shell=True, capture_output=True, text=True)
        if not os.path.exists(os.path.join(DIS, "game.gbc")):
            sys.exit("probe build failed:\n" + r.stdout + r.stderr)
        import hashlib
        md5 = hashlib.md5(open(os.path.join(DIS, "game.gbc"), "rb").read()).hexdigest()
        if md5 != ORIGINAL_MD5:
            sys.exit(f"probe build not byte-perfect ({md5}); aborting (labels should be zero-byte).")
        sym = open(os.path.join(DIS, "game.sym")).read()
    finally:
        shutil.move(backup, ASM)
    addr_of = {}
    for line in sym.splitlines():
        m = re.match(r"^12:([0-9a-fA-F]{4}) (Lprobe_\d+)", line)
        if m:
            addr_of[m.group(2)] = int(m.group(1), 16)
    return {ln: addr_of[name] for name, ln in probe_of.items() if name in addr_of}


def fmt_db(byts, indent="    "):
    out = []
    for k in range(0, len(byts), 16):
        out.append(indent + "db " + ", ".join(f"${b:02x}" for b in byts[k:k+16]))
    return out


def emit_bounds(label, byts, comment):
    return comment + [f"{label}:"] + fmt_db(byts)


def emit_colpos(label, byts, comment):
    words = [byts[i] | (byts[i+1] << 8) for i in range(0, len(byts), 2)]
    return comment + [f"{label}:", "    dw " + ", ".join(f"${w:04x}" for w in words)]


def emit_layout(label, start, byts, comment, extra_labels):
    """Emit a layout block: dw position, then db tile stream, splitting at $d9
    terminators and at any extra interior label."""
    out = list(comment)
    i = 0
    cur_label = label
    while i < len(byts):
        addr = start + i
        if addr in (extra_labels or {}):
            cur_label = extra_labels[addr]
        out.append(f"{cur_label}:")
        # position word
        pos = byts[i] | (byts[i+1] << 8)
        out.append(f"    dw ${pos:04x}                ; dest position")
        i += 2
        # tile stream up to and including $d9
        stream_start = i
        while i < len(byts) and byts[i] != 0xd9:
            i += 1
        if i < len(byts):
            i += 1  # include the $d9 terminator
        out += fmt_db(byts[stream_start:i])
        cur_label = None  # next iteration must hit an extra_label or end
        if i < len(byts) and (start + i) not in (extra_labels or {}):
            # more bytes but no label — shouldn't happen for clean layout packing
            sys.exit(f"layout {label}: unexpected continuation at ${start+i:04x}")
    return out


def main():
    src = open(ASM).read()
    if DONE_MARKER in src:
        sys.exit("Already re-sectioned (LibraryFamilyTabBounds present). Nothing to do.")
    lines = src.split("\n")

    print("Building line->address map (probe build)...")
    line_addr = build_line_addr_map(lines)
    inv = {}
    for ln, a in line_addr.items():
        inv.setdefault(a, []).append(ln)

    def line_at(addr):
        ls = sorted(inv.get(addr, []))
        if not ls:
            sys.exit(f"no source line maps to ${addr:04x}")
        return ls[0]

    # Build replacement plan: (start_line_idx0, end_line_idx0_exclusive, new_lines)
    plan = []
    for t in TABLES:
        sline = line_at(t["start"])
        eline = line_at(t["end"])
        # assert the span between is pure data (no real labels)
        for ln in range(sline, eline):
            s = lines[ln].strip()
            if s.endswith(":") and not s.startswith(";"):
                sys.exit(f"real label {s} inside {t['label']} range; aborting")
        byts = rom_bytes(t["start"], t["end"])
        if t["kind"] == "bounds":
            new = emit_bounds(t["label"], byts, t["comment"])
        elif t["kind"] == "colpos":
            new = emit_colpos(t["label"], byts, t["comment"])
        else:
            new = emit_layout(t["label"], t["start"], byts, t["comment"], t.get("extra_labels"))
        plan.append((sline, eline, new, t["label"], len(byts)))

    # Apply replacements from the bottom up so earlier indices stay valid.
    plan.sort(key=lambda p: p[0], reverse=True)
    for sline, eline, new, label, nbytes in plan:
        lines[sline:eline] = new
        print(f"  {label}: {nbytes} B re-sectioned ({eline-sline} src lines -> {len(new)})")

    out = "\n".join(lines)

    # Labelize raw-pointer references (byte-neutral).
    n_ref = 0
    for old, new in REF_LABELS:
        c = out.count(old)
        if c:
            out = out.replace(old, new)
            n_ref += c
            print(f"  ref: '{old}' -> '{new}'  ({c} site{'s' if c!=1 else ''})")
    open(ASM, "w").write(out)
    print(f"Done. {len(TABLES)} tables, {n_ref} reference sites labelized.")
    print("Now run: python3 tools/verify_integrity.py  (must stay byte-perfect)")


if __name__ == "__main__":
    main()
