#!/usr/bin/env python3
"""
resection_monster_art_tables.py — S107 (ROADMAP P3.10 part 2a, Iron Rule 6):
re-section the per-species ART tables the editor now owns from mgbdis fake
instructions into labeled, commented `dw` / `db` rows — in BOTH trees, zero
byte change (clean build stays 1ca6579…, the patched pin stays the same).

  * the seven still-misassembled copies of the follower (walking) gfx-ID table
    (MONSTER_DATA "Follower-art table has EIGHT copies"; bank $01's copy was
    re-sectioned S24): $06 $07 $09 $0B $12 index species+$10 (231 words: 16
    non-monster entries + species 0-214), $18 $59 index species (215 words);
  * bank $10's follower LAYOUT level-1 table ($407F, 128 dw, species 0-127) +
    ATTR table ($417F, 128 db) — bank $11's twins were re-sectioned S105.

The battle gfx-ID table head in patches/bank_000.asm is ported from the clean
disassembly by --port-battle (the clean tree has it since S22).

Method = the repo's probe-build (resection_skill_tables.py; never sum opcode
sizes): zero-byte probe labels before every code/db line → line addresses
from game.sym → splice window [A, B) around the table → verbatim db for the
bytes outside the table + one row per entry. Labels defined in the removed
lines that ANY file of either tree references are kept at their exact byte
offset (rows split into db); unreferenced fake-decode labels are dropped and
listed. The patched copy gets the identical text replacement (asserted to
occur exactly once). Idempotent (a re-sectioned table is skipped).

Run:  python3 tools/resection_monster_art_tables.py [--port-battle]
"""
import glob
import hashlib
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
DIS = os.path.join(REPO, "disassembly")
PAT = os.path.join(REPO, "patches")
ROM = os.path.join(REPO, "data", "DWM-original.gbc")
CLEAN_MD5 = "1ca6579359f21d8e27b446f865bf6b83"

# (file, bank, base, entries, first species index, kind, new label)
FOLLOWER = [
    ("bank_006.asm", 0x06, 0x4DCC, 231, 16, "FollowerGfxTable06"),
    ("bank_007.asm", 0x07, 0x6E14, 231, 16, "FollowerGfxTable07"),
    ("bank_009.asm", 0x09, 0x6B10, 231, 16, "FollowerGfxTable09"),
    ("bank_00b.asm", 0x0B, 0x4974, 231, 16, "FollowerGfxTable0B"),
    ("bank_012.asm", 0x12, 0x65F2, 231, 16, "FollowerGfxTable12"),
    ("bank_018.asm", 0x18, 0x4123, 215, 0, "FollowerGfxTable18"),
    ("bank_059.asm", 0x59, 0x4363, 215, 0, "FollowerGfxTable59"),
]
READERS = {0x06: "the field (farm / follower refresh) $4D7E",
           0x07: "the monster status / party screens $66B8",
           0x09: "the naming / evaluator screens $61FB",
           0x0B: "the room NPC sprite resolver (monster NPCs $F0-$F3, FollowerArtResolve0b) $490F",
           0x12: "the library + lineage parent icons (CmpItem_65cb) $65DE",
           0x18: "the field menu (TextDataPtrLookup reader $40BF, raw species)",
           0x59: "the battle-side party list $42CA (raw species)"}


def rom():
    return open(ROM, "rb").read()


def rb(bank, addr, n):
    off = bank * 0x4000 + (addr - 0x4000) if bank else addr
    return rom()[off:off + n]


def names():
    from editor2.core import gamedata as G
    return G.monster_names(REPO)


def clean_artifacts():
    for f in ("game.o", "game.gbc", "game.sym", "game.map"):
        p = os.path.join(DIS, f)
        if os.path.exists(p):
            os.remove(p)


def build(check=True):
    clean_artifacts()
    r = subprocess.run(["make"], cwd=DIS, capture_output=True, text=True)
    if r.returncode:
        sys.exit("build failed:\n" + (r.stdout + r.stderr)[-3000:])
    md5 = hashlib.md5(open(os.path.join(DIS, "game.gbc"), "rb").read()).hexdigest()
    if check and md5 != CLEAN_MD5:
        sys.exit(f"NOT byte-perfect: {md5}")
    return md5


CODE_RE = re.compile(r"^\s+\S")
LABEL_RE = re.compile(r"^([A-Za-z_]\w*):")


def probe_map(path):
    orig = open(path).read()
    lines = orig.splitlines()
    # a probe is a GLOBAL label: it would re-scope `.local` labels below it,
    # so lines whose scope (up to the next global label) uses a local label
    # are not probed
    unsafe = [False] * len(lines)
    local = False
    for i in range(len(lines) - 1, -1, -1):
        l = lines[i].split(";", 1)[0]
        if re.search(r"(^|[\s,(])\.[A-Za-z_]\w*", l):
            local = True
        unsafe[i] = local
        if LABEL_RE.match(lines[i]):
            local = False
    out, of = [], {}
    for i, l in enumerate(lines):
        if CODE_RE.match(l) and not l.strip().startswith(";") and not unsafe[i]:
            out.append(f"Lprobe_{i}:")
            of[f"Lprobe_{i}"] = i
        out.append(l)
    try:
        open(path, "w").write("\n".join(out) + "\n")
        build()
        addr = {}
        for ln in open(os.path.join(DIS, "game.sym")):
            p = ln.split()
            if len(p) == 2 and p[1] in of:
                addr[of[p[1]]] = int(p[0].split(":")[1], 16)
        return lines, addr
    finally:
        open(path, "w").write(orig)
        clean_artifacts()


def sym():
    build()
    s = {}
    for ln in open(os.path.join(DIS, "game.sym")):
        p = ln.split()
        if len(p) == 2 and ":" in p[0] and not ln.startswith(";"):
            b, a = p[0].split(":")
            s[p[1]] = (int(b, 16), int(a, 16))
    clean_artifacts()
    return s


def referenced(label, exclude_text):
    """Is `label` referenced anywhere in either tree outside `exclude_text`
    (the removed lines, which carry its definition)?"""
    pat = re.compile(r"\b%s\b" % re.escape(label))
    for f in glob.glob(os.path.join(DIS, "*.asm")) + glob.glob(os.path.join(PAT, "*.asm")):
        t = open(f).read()
        n = len(pat.findall(t))
        if n == 0:
            continue
        n_ex = len(pat.findall(exclude_text)) if exclude_text in t else 0
        if n > n_ex:
            return True
    return False


def db(bs):
    return "    db " + ", ".join(f"${b:02x}" for b in bs)


def rows_follower(bank, base, n, first, label, nm):
    data = rb(bank, base, n * 2)
    segs = [(None, 0, f"{label}:"),
            (None, 0, f"    ; FOLLOWER (walking) gfx-ID table — one of the EIGHT per-screen copies"),
            (None, 0, f"    ; (MONSTER_DATA 'Follower-art table has EIGHT copies'; bank $01's"),
            (None, 0, f"    ; ScreenTransDataTable is the overworld one). Read by {READERS[bank]}."),
            (None, 0, f"    ; Index = " + ("species + $10" if first else "species") +
             " -> gfx-ID (bank<<8 | index) -> $<bank>:$4001 + index*2."),
            (None, 0, f"    ; {n} words: " + ("16 non-monster entries, then " if first else "") +
             "species 0-214; ids 215+ read past the end (never followers)."),
            (None, 0, f"    ; A re-arted species writes the SAME new gfx-ID into all eight copies"),
            (None, 0, f"    ; (S107: compiler region art_walk_{bank:02x}, gamedata.art)."),
            (None, 0, f"    ; Re-sectioned S107 (tools/resection_monster_art_tables.py), byte-identical.")]
    for i in range(n):
        w = data[2 * i] | data[2 * i + 1] << 8
        sp = i - first
        what = f"species {sp} {nm.get(sp, '')}" if sp >= 0 else \
               ("default" if i == 0 else "non-monster (loader index 1-15)")
        segs.append((base + 2 * i, 2, f"    dw ${w:04x}   ; [{i:3d}] {what}"))
    return segs, data


def rows_layout10(nm):
    from editor2.core import sprite_render as R
    base = 0x407F
    data = rb(0x10, base, 128 * 3)
    segs = [(None, 0, "FollowerLayoutL1Table10:"),
            (None, 0, "    ; FOLLOWER LAYOUT level-1 table, species 0-127 (bank $11's twin"),
            (None, 0, "    ; FollowerLayoutL1Table11 covers 128-214). Index = [$ffc7] = species"),
            (None, 0, "    ; (the bank-$04 router subtracts $10 from species+$10). Read by both"),
            (None, 0, "    ; bank-$10 entries (`ld de, $407f`: entry 0 via ROM0 $0D91) -> the"),
            (None, 0, "    ; species' level-2 table (six frame pointers -> metasprite lists"),
            (None, 0, "    ; (dy, dx, tile, attr), MONSTER_DATA 'Follower / walking-sprite render"),
            (None, 0, "    ; system'). Layout ids = extracted/follower_layouts.json. A level-2"),
            (None, 0, "    ; pointer is dereferenced with bank $10 mapped: only bank-$10 layouts."),
            (None, 0, "    ; Re-sectioned S107 (tools/resection_monster_art_tables.py), byte-identical.")]
    for sp in range(128):
        w = data[2 * sp] | data[2 * sp + 1] << 8
        lid, _a = R.species_layout_id(sp)
        segs.append((base + 2 * sp, 2, f"    dw ${w:04x}   ; [{sp:3d}] {nm.get(sp, '')} (layout {lid})"))
    segs += [(None, 0, "FollowerAttrTable10:"),
             (None, 0, "    ; FOLLOWER ATTR table, species 0-127: OR-ed into [$ffca] by HramScr2_406e"),
             (None, 0, "    ; (bit6 Y-flip, bit5 X-flip, low3 = OBJ palette $17:$5615). Every"),
             (None, 0, "    ; collectible species uses 0-7 (palette only).")]
    for sp in range(128):
        segs.append((base + 256 + sp, 1, f"    db ${data[256 + sp]:02x}   ; [{sp:3d}] {nm.get(sp, '')}"))
    return segs, data[:384]


def splice(fname, bank, start, size, segs_fn, label, old_base=None):
    path = os.path.join(DIS, fname)
    src = open(path).read()
    if re.search(rf"^{label}:", src, re.M):
        print(f"  {fname}: {label} already re-sectioned — skipped")
        return
    end = start + size
    lines, addr = probe_map(path)
    S = sym()
    coded = sorted(addr.items())
    A_i = max(i for i, a in coded if a <= start)
    B_i = min(i for i, a in coded if a >= end)
    A, B = addr[A_i], addr[B_i]
    # pull bare label lines sitting just above the first code line into the window
    while A_i > 0 and LABEL_RE.match(lines[A_i - 1]) and not CODE_RE.match(lines[A_i - 1]):
        A_i -= 1
    # bare label lines right above the line at B belong to B (kept outside)
    while B_i > A_i and LABEL_RE.match(lines[B_i - 1]) and not CODE_RE.match(lines[B_i - 1]):
        B_i -= 1
    removed = lines[A_i:B_i]
    rtext = "\n".join(removed)
    defs = [LABEL_RE.match(l).group(1) for l in removed if LABEL_RE.match(l)]
    segs, data = segs_fn()
    assert data == rb(bank, start, size), "table bytes differ from the ROM"
    if A < start:
        segs = [(None, 0, f"; ${A:04x}-${start - 1:04x}: bytes before the table (preserved verbatim; were fake-decoded)"),
                (A, start - A, db(rb(bank, A, start - A)))] + segs
    if end < B:
        segs += [(None, 0, f"; ${end:04x}-${B - 1:04x}: bytes after the table up to the next decoded line (verbatim)"),
                 (end, B - end, db(rb(bank, end, B - end)))]
    keep, dropped = {}, []
    for d in defs:
        if d not in S:
            sys.exit(f"ABORT {fname}: label {d} has no sym address")
        b_, a_ = S[d]
        if b_ != bank:
            sys.exit(f"ABORT {fname}: label {d} resolves to bank {b_:02x}")
        if d == old_base and a_ == start:
            continue                    # re-declared next to the new label
        if referenced(d, rtext):
            keep[a_] = keep.get(a_, []) + [d]
        else:
            dropped.append(d)
    for ka in sorted(keep):
        for i, (sa, sn, txt) in enumerate(segs):
            if sa is not None and sa <= ka < sa + sn:
                row = rb(bank, sa, sn)
                tail = txt.split(";", 1)[1].strip() if ";" in txt else ""
                rep = []
                if ka > sa:
                    rep.append((sa, ka - sa, db(row[:ka - sa]) + (f"   ; {tail} (lo)" if tail else "")))
                for k in keep[ka]:
                    rep.append((None, 0, f"{k}:   ; fake-decode label kept at its exact offset ${ka:04x} "
                                         "(referenced by bytes decoded as code elsewhere; NOT code)"))
                rep.append((ka, sa + sn - ka, db(row[ka - sa:]) + (f"   ; {tail}" + (" (hi)" if ka > sa else "") if tail else "")))
                segs[i:i + 1] = rep
                break
        else:
            sys.exit(f"ABORT {fname}: kept label {keep[ka]} @ ${ka:04x} outside the block")
    block = []
    for sa, sn, txt in segs:
        block.append(txt)
        if txt == f"{label}:" and old_base:
            block.append(f"{old_base}:   ; (mgbdis name, kept: referenced by the readers / patches)")
    if dropped:
        block.append("; NOTE: unreferenced fake-decode labels removed with this block: " + ", ".join(dropped))
    new = "\n".join(lines[:A_i] + block + lines[B_i:]) + "\n"
    open(path, "w").write(new)
    build()
    clean_artifacts()
    # the patched copy: identical text replacement
    ppath = os.path.join(PAT, fname)
    if os.path.exists(ppath):
        pt = open(ppath).read()
        n = pt.count(rtext + "\n")
        if n != 1:
            sys.exit(f"ABORT: patched {fname}: the removed text occurs {n} times — do it by hand")
        open(ppath, "w").write(pt.replace(rtext + "\n", "\n".join(block) + "\n"))
    print(f"  {fname}: [{A:04x},{B:04x}) -> {label}; {len(removed)} lines -> {len(block)}; "
          f"kept {sum(len(v) for v in keep.values())} labels, dropped {len(dropped)}; clean byte-perfect"
          + ("; patched copy updated" if os.path.exists(ppath) else ""))


def base_label(bank, addr):
    S = sym()
    for k, (b, a) in sorted(S.items()):
        if b == bank and a == addr and k[0].isupper() and not k.startswith("Lprobe"):
            return k
    return None


def main():
    nm = names()
    for fname, bank, base, n, first, label in FOLLOWER:
        ob = base_label(bank, base)
        splice(fname, bank, base, n * 2,
               lambda bank=bank, base=base, n=n, first=first, label=label:
               rows_follower(bank, base, n, first, label, nm),
               label, old_base=ob)
    splice("bank_010.asm", 0x10, 0x407F, 384, lambda: rows_layout10(nm),
           "FollowerLayoutL1Table10", old_base=None)


if __name__ == "__main__":
    main()
