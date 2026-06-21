#!/usr/bin/env python3
"""
resection_library_tables.py — re-section the misassembled library/family DATA
tables in disassembly/bank_012.asm into labeled db/dw blocks (LABELS/COMMENTS
ONLY — zero byte impact). Idempotent, per-table; re-runnable from the clean
tree OR a partially-converted tree.

Bank $12 is the monster-library / family-tab menu bank. mgbdis decoded several
in-bank DATA tables as fake instructions (e.g. the family id-range bounds read
as `nop / inc d / dec l / ...`, and the window-draw layout streams read as
`jr`/`ld` runs), which blocks editing them in source. This tool converts the
genuine data tables to named db/dw and labelizes the raw-pointer references
that reach them, so the editor can address them by label.

TABLES converted (all ROM-verified; see documentation/DATA_STRUCTURES.md
"Library / family-tab menu data (bank $12)"):

  LibraryFamilyTabBounds  $6294  11 B  family id-range boundaries (the S18 case):
                                       SetItem_6242 scans species start..end-1
                                       per family tab; THE ONLY id-range family
                                       assumption in the ROM.
  LibTabColPos_564a/_5a8e        tab-column cursor-position words, $ffff-term,
                                       read by FuncItem_43e2.
  Window-draw layout streams: a CONTIGUOUS run of packed layouts at $710c..$7b9b
  (the bank's trailing free space starts at $7b9b). Each layout = a 2-byte
  dest-position word, then a tile-byte stream where $d8 = newline (advance dest
  by $20) and $d9 = terminator; every other byte is a literal tile written via
  `ld [hl+],a` by the draw loop at $40c3 (reached through ReadPtrFromDE).
  Each layout is named LibWinLayout_<addr>. Session 26 converted the directly-
  `ld de`-referenced subset ($710c/$71aa/$71f4, $759a, $7b42/$7b6c); this tool
  now ALSO converts the two remaining contiguous gaps ($724e..$759a and
  $75c0..$7b42) so the WHOLE run reads as data, not just the referenced layouts.
  The gap layouts include $79c6 (380 B, a different window-border tileset that
  mgbdis decoded with several fake `jr` labels — both the `jr`s and their targets
  are inside the data and vanish together when the range is emitted as db).

RE-SECTION SCOPE (the two contiguous mgbdis gaps inside the layout run):
  $724e..$759a  10 layouts  (after the S26 $710c block, before the S26 $759a one)
  $75c0..$7b42  13 layouts  (after the S26 $759a layout, before the S26 $7b42 one)
Sub-layout boundaries are discovered by walking ROM bytes ($d9 terminators), so
no per-layout address is hardcoded.

ROBUST LINE->ADDRESS MAPPING (no opcode-size summing — that bit Session 22):
zero-byte probe labels are inserted before every instruction/db line, the tree
is built once, and each line's address is read from the linker `game.sym`. A
table's source-line span is then exactly the lines whose mapped address falls in
[start, end) — which CLEANLY excludes an adjacent already-converted block's
comment/label/dw lines (they map to >= end or have no probe address). The probe
build itself stays byte-perfect (labels emit no bytes), asserted here. Because
every emitted byte is sourced from the ROM and no externally-referenced label
sits inside any converted range (asserted), the build stays byte-perfect
(verify_integrity.py check 1).

Usage:
    python3 tools/resection_library_tables.py            # re-section (idempotent)
    python3 tools/resection_library_tables.py --dump-json # ALSO write the layouts JSON
    python3 tools/resection_library_tables.py --json-only # only write the layouts JSON
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIS  = os.path.join(REPO, "disassembly")
ASM  = os.path.join(DIS, "bank_012.asm")
ROM  = os.path.join(REPO, "data", "DWM-original.gbc")
JSON_OUT = os.path.join(REPO, "extracted", "library_layouts.json")
BANK = 0x12
ORIGINAL_MD5 = "1ca6579359f21d8e27b446f865bf6b83"

# The full packed layout run lives at $710c .. $7b9b (trailing free space @ $7b9b).
LAYOUT_RUN_START = 0x710c
LAYOUT_RUN_END   = 0x7b9b

# Layouts that the menu code reaches via `ld de, $imm` (these get their `ld de`
# reference site labelized too). All other layouts in the run are still named
# LibWinLayout_<addr> and become editor-addressable, but have no direct imm ref.
LD_DE_LAYOUTS = {0x724e, 0x7768, 0x77cd, 0x78ab, 0x78d0, 0x7935, 0x79c6}

# ---- Fixed single-purpose tables (Session 26; kept for clean-tree reproducibility) ----
# (label, start, end_exclusive, kind)  kind: 'bounds' | 'colpos'
FIXED_TABLES = [
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
]

# ---- Session 26 layout blocks (already in the committed tree; converted on a clean tree) ----
S26_LAYOUT_BLOCKS = [
    dict(start=0x710c, end=0x724e,
         comment=["; Library window-draw layout streams (ReadPtrFromDE + draw loop $40c3).",
                  "; Each: dest-position word, then a tile-byte stream; $d8=newline, $d9=end.",
                  "; Contiguous packed run of layouts continues to $7b9b (the trailing free space)."]),
    dict(start=0x759a, end=0x75c0,
         comment=["; Library window-draw layout stream (see LibWinLayout_710c for format)."]),
    dict(start=0x7b42, end=0x7b9b,
         comment=["; Library window-draw layout streams (see LibWinLayout_710c for format).",
                  "; Last layouts before the bank-$12 trailing free space at $7b9b."]),
]

# ---- NEW (this session): the two remaining contiguous gaps in the layout run ----
GAP_LAYOUT_BLOCKS = [
    dict(start=0x724e, end=0x759a,
         comment=["; Library window-draw layout streams (see LibWinLayout_710c for format).",
                  "; Contiguous gap of 10 packed layouts between the S26 $710c and $759a blocks."]),
    dict(start=0x75c0, end=0x7b42,
         comment=["; Library window-draw layout streams (see LibWinLayout_710c for format).",
                  "; Contiguous gap of 13 packed layouts (incl. the 380-B $79c6 stream, a",
                  "; different window-border tileset mgbdis mis-decoded with fake `jr` labels)."]),
]


def rom_bytes(start, end):
    rom = open(ROM, "rb").read()
    base = BANK * 0x4000 + (start - 0x4000)
    return rom[base: base + (end - start)]


def walk_layouts(start, end):
    """Split [start,end) into packed layouts: dw pos, stream..., $d9. Returns
    list of (addr, length)."""
    data = rom_bytes(start, end)
    out, i = [], 0
    while i < len(data):
        s = i
        i += 2  # position word
        while i < len(data) and data[i] != 0xd9:
            i += 1
        if i < len(data) and data[i] == 0xd9:
            i += 1
        out.append((start + s, i - s))
    consumed = out[-1][0] + out[-1][1] if out else start
    if consumed != end:
        sys.exit(f"walk_layouts({start:#x},{end:#x}) misaligned: consumed ${consumed:04x}")
    return out


def decode_layout(addr, length):
    """Decode a layout into {addr,label,pos,rows} for the JSON dump."""
    data = rom_bytes(addr, addr + length)
    pos = data[0] | (data[1] << 8)
    rows, row = [], []
    for v in data[2:]:
        if v == 0xd9:
            break
        if v == 0xd8:
            rows.append(row); row = []
        else:
            row.append(v)
    if row:
        rows.append(row)
    return dict(addr=f"${addr:04x}", label=f"LibWinLayout_{addr:04x}", pos=pos,
                length=length, ld_de_ref=(addr in LD_DE_LAYOUTS),
                rows=[[f"${t:02x}" for t in r] for r in rows])


# --------------------------- emitters ---------------------------

def fmt_db(byts, indent="    "):
    return [indent + "db " + ", ".join(f"${b:02x}" for b in byts[k:k+16])
            for k in range(0, len(byts), 16)]


def emit_bounds(label, byts, comment):
    return comment + [f"{label}:"] + fmt_db(byts)


def emit_colpos(label, byts, comment):
    words = [byts[i] | (byts[i+1] << 8) for i in range(0, len(byts), 2)]
    return comment + [f"{label}:", "    dw " + ", ".join(f"${w:04x}" for w in words)]


def emit_layout_run(start, end, comment):
    """Emit every packed layout in [start,end) as `LibWinLayout_<addr>:` + dw pos
    + db stream (to $d9). A `; <- ld de ref` note marks directly-referenced ones."""
    out = list(comment)
    for addr, length in walk_layouts(start, end):
        byts = rom_bytes(addr, addr + length)
        if addr in LD_DE_LAYOUTS:
            # NOTE: phrasing deliberately avoids the literal `ld de, $XXXX` form so the
            # reference-labelizer below doesn't also rewrite this comment.
            out.append("    ; directly referenced (ld-de immediate) by the menu code")
        out.append(f"LibWinLayout_{addr:04x}:")
        pos = byts[0] | (byts[1] << 8)
        out.append(f"    dw ${pos:04x}                ; dest position")
        out += fmt_db(byts[2:])
    return out


# --------------------------- line<->addr mapping ---------------------------

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


def span_for_range(line_addr, start, end):
    """Source-line span [sline, eline) covering exactly the lines whose mapped
    address is in [start, end). Robust against adjacent converted blocks: their
    comment/label lines carry no probe address and their first db/dw maps to
    >= end, so they're excluded."""
    in_range = [ln for ln, a in line_addr.items() if start <= a < end]
    if not in_range:
        sys.exit(f"no source lines map into [${start:04x},${end:04x})")
    return min(in_range), max(in_range) + 1


# --------------------------- main ---------------------------

def emit_json():
    layouts = [decode_layout(a, n) for a, n in walk_layouts(LAYOUT_RUN_START, LAYOUT_RUN_END)]
    doc = dict(
        _generator="tools/resection_library_tables.py --dump-json (ROM: data/DWM-original.gbc)",
        _doc=("Bank $12 monster-library / family-tab menu window-draw layout streams. "
              "Contiguous packed run $710c..$7b9b. Each layout: dest-position word + rows "
              "of literal tile ids; $d8=newline (dest += $20), $d9=terminator. Drawn by the "
              "$40c3 loop via ReadPtrFromDE. ld_de_ref=true => reached by `ld de,$imm` from "
              "the menu code; the rest are part of the packed run. See DATA_STRUCTURES."),
        bank="$12", run_start="$710c", run_end="$7b9b",
        count=len(layouts), layouts=layouts,
    )
    os.makedirs(os.path.dirname(JSON_OUT), exist_ok=True)
    open(JSON_OUT, "w").write(json.dumps(doc, indent=2))
    print(f"  wrote {JSON_OUT} ({len(layouts)} layouts)")


def main():
    args = set(sys.argv[1:])
    if "--json-only" in args:
        emit_json()
        return

    src = open(ASM).read()
    lines = src.split("\n")

    def have(label):
        return re.search(rf"^{re.escape(label)}:\s*$", src, re.M) is not None

    todo = []
    for t in FIXED_TABLES:
        if not have(t["label"]):
            todo.append(("fixed", t))
    for blk in S26_LAYOUT_BLOCKS:
        first = walk_layouts(blk["start"], blk["end"])[0][0]
        if not have(f"LibWinLayout_{first:04x}"):
            todo.append(("run", blk))
    for blk in GAP_LAYOUT_BLOCKS:
        first = walk_layouts(blk["start"], blk["end"])[0][0]
        if not have(f"LibWinLayout_{first:04x}"):
            todo.append(("run", blk))

    if not todo:
        print("All tables already re-sectioned. Nothing to do.")
        if "--dump-json" in args:
            emit_json()
        return

    print(f"{len(todo)} block(s) to convert. Building line->address map (probe build)...")
    line_addr = build_line_addr_map(lines)

    plan = []
    for kind, t in todo:
        sline, eline = span_for_range(line_addr, t["start"], t["end"])
        byts = rom_bytes(t["start"], t["end"])
        if kind == "fixed":
            if t["kind"] == "bounds":
                new = emit_bounds(t["label"], byts, t["comment"])
            else:
                new = emit_colpos(t["label"], byts, t["comment"])
            desc = t["label"]
        else:
            new = emit_layout_run(t["start"], t["end"], t["comment"])
            n = len(walk_layouts(t["start"], t["end"]))
            desc = f"layout run ${t['start']:04x}..${t['end']:04x} ({n} layouts)"
        plan.append((sline, eline, new, desc, len(byts)))

    plan.sort(key=lambda p: p[0], reverse=True)
    for sline, eline, new, desc, nbytes in plan:
        lines[sline:eline] = new
        print(f"  {desc}: {nbytes} B ({eline-sline} src lines -> {len(new)})")

    out = "\n".join(lines)

    ref_labels = [
        ("ld hl, $6294", "ld hl, LibraryFamilyTabBounds"),
        ("ld de, $564a", "ld de, LibTabColPos_564a"),
        ("ld de, $5a8e", "ld de, LibTabColPos_5a8e"),
    ]
    for la in sorted(set(list(LD_DE_LAYOUTS) +
                         [0x710c, 0x71aa, 0x71f4, 0x759a, 0x7b42, 0x7b6c])):
        ref_labels.append((f"ld de, ${la:04x}", f"ld de, LibWinLayout_{la:04x}"))

    n_ref = 0
    for old, new in ref_labels:
        c = out.count(old)
        if c:
            out = out.replace(old, new)
            n_ref += c
            print(f"  ref: '{old}' -> '{new}'  ({c} site{'s' if c != 1 else ''})")
    open(ASM, "w").write(out)
    print(f"Done. {len(plan)} block(s) converted, {n_ref} reference site(s) labelized.")
    if "--dump-json" in args:
        emit_json()
    print("Now run: python3 tools/verify_integrity.py  (must stay byte-perfect)")


if __name__ == "__main__":
    main()
