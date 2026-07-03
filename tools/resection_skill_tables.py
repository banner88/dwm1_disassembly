#!/usr/bin/env python3
"""
resection_skill_tables.py — Phase D item (2b): convert the two S44-decoded skill
tables from mgbdis fake instructions to real, labeled `dw`/`db` data.

  SkillMPCostTable    $07:$570C  222 x u16 LE   (999 = "ALL MP")
  SkillLearnReqTable  $06:$50E0  222 x 18 B     (lvl u8; hp/mp/atk/def/agl/int u16 LE; 5 prereq ids, $FF = none)

Method (the repo's proven probe-build approach — see resection_library_tables.py;
NEVER sum opcode sizes by hand, that was the S22 trap):
  1. Insert zero-byte `Lprobe_N:` labels before every code/db line of the target
     bank file, build once, read every line's ADDRESS from the linker game.sym,
     restore the file. Assert the probe build is still byte-perfect.
  2. Pick the splice window [A, B): A = addr of the last probed line <= table
     start, B = addr of the first probed line >= table end. Replace those source
     lines with:  verbatim `db` for ROM[A:start]  +  the structured table
     (names/comments from extracted/skill_records.json)  +  verbatim `db` for
     ROM[end:B]. Byte identity holds by construction.
  3. GUARD: every label DEFINED inside the removed lines must have all its
     references inside them too (they are fake-decode artifacts); abort otherwise.
  4. Rebuild; assert clean MD5 1ca6579359f21d8e27b446f865bf6b83.
  5. patches/bank_006.asm + patches/bank_007.asm: assert the region text is
     IDENTICAL to the pre-edit disassembly region, then apply the same textual
     replacement (the patched build is overlay-per-file, so both trees need it).

Run:  python3 tools/resection_skill_tables.py            # apply
      python3 tools/resection_skill_tables.py --check    # verify only (post-apply)
Idempotent: aborts if the target label already exists as a `dw`/`db` block.
"""
import json, os, re, subprocess, sys, hashlib, shutil

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIS = os.path.join(REPO, "disassembly")
ROM = os.path.join(REPO, "data", "DWM-original.gbc")
CLEAN_MD5 = "1ca6579359f21d8e27b446f865bf6b83"
SYM_TXT = ""
RECS = json.load(open(os.path.join(REPO, "extracted", "skill_records.json")))["records"]

TARGETS = [
    # (file, bank, start, size, kind, label)
    ("bank_007.asm", 0x07, 0x570C, 222 * 2,  "mp",    "SkillMPCostTable"),
    ("bank_006.asm", 0x06, 0x50E0, 222 * 18, "learn", "SkillLearnReqTable"),
]

def rom_bytes(bank, addr, n):
    off = bank * 0x4000 + (addr - 0x4000)
    with open(ROM, "rb") as f:
        f.seek(off); return f.read(n)

def build(check_md5=True):
    r = subprocess.run(["make"], cwd=DIS, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("build failed:\n" + r.stdout + r.stderr)
    md5 = hashlib.md5(open(os.path.join(DIS, "game.gbc"), "rb").read()).hexdigest()
    if check_md5 and md5 != CLEAN_MD5:
        sys.exit(f"NOT byte-perfect: {md5}")
    return md5

def clean():
    # NEVER `make clean` — it deletes the COMMITTED gfx/*.2bpp/1bpp files, which
    # are NOT regenerable from the PNGs with default rgbgfx flags (S51 lesson).
    for f in ("game.o", "game.gbc", "game.sym", "game.map"):
        p = os.path.join(DIS, f)
        if os.path.exists(p): os.remove(p)

CODE_RE = re.compile(r"^\s+\S")          # indented instruction / db line
def probe_map(path):
    """{line_idx0: start_addr} for every code/db line, via a probe build."""
    orig = open(path).read()
    lines = orig.splitlines()
    probed, probe_of = [], {}
    for i, l in enumerate(lines):
        if CODE_RE.match(l):
            probed.append(f"Lprobe_{i}:")
            probe_of[f"Lprobe_{i}"] = i
        probed.append(l)
    try:
        open(path, "w").write("\n".join(probed) + "\n")
        clean(); build(check_md5=True)          # zero-size labels: must stay perfect
        addr = {}
        for ln in open(os.path.join(DIS, "game.sym")):
            parts = ln.split()
            if len(parts) == 2 and parts[1] in probe_of and ":" in parts[0]:
                addr[probe_of[parts[1]]] = int(parts[0].split(":")[1], 16)
        return lines, addr
    finally:
        open(path, "w").write(orig)

def emit_db(data, per=16, indent="    "):
    out = []
    for i in range(0, len(data), per):
        out.append(indent + "db " + ", ".join(f"${b:02x}" for b in data[i:i+per]))
    return out

def emit_mp(start):
    data = rom_bytes(0x07, start, 222 * 2)
    out = [f"{'SkillMPCostTable'}:  ; $07:$570C — 222 x u16 LE MP cost, skill-id order; $03E7 (999) = \"All MP\".",
           ";   Decoded S44 (gen_skill_records.py), FAQ-validated; round-trip proven by",
           ";   build_skill_tables.py --selftest. Re-sectioned S51 (probe-build; byte-perfect).",
           ";   Read by GetSkillMPCost ($56E8) and the two other MP readers mapped in S48."]
    segs = [(None, 0, l) for l in out]
    for r in RECS:
        v = data[r["id"]*2] | (data[r["id"]*2+1] << 8)
        assert v == (999 if r["mp_cost"] in (999, "ALL") else r["mp_cost"]), (r["id"], v, r["mp_cost"])
        tag = "ALL" if v == 999 else str(v)
        segs.append((start + r["id"]*2, 2,
                     f"    dw ${v:04x}  ; ${r['id']:02x} {r['name']} (MP {tag}, {r['kind']})"))
    return segs, data

def emit_learn(start):
    data = rom_bytes(0x06, start, 222 * 18)
    out = []
    hdr = [f"{'SkillLearnReqTable'}:  ; $06:$50E0 — 222 x 18 B, skill-id order:",
           ";   +0 level u8; +1 hp, +3 mp, +5 atk, +7 def, +9 agl, +11 int (u16 LE);",
           ";   +13..17 five prereq skill ids ($FF = none).",
           ";   Decoded S44, FAQ-validated; round-trip proven by build_skill_tables.py",
           ";   --selftest. Re-sectioned S51 (probe-build; byte-perfect)."]
    out += [(None, 0, l) for l in hdr]
    for r in RECS:
        rec = data[r["id"]*18:(r["id"]+1)*18]
        lvl = rec[0]
        st = [rec[1]|rec[2]<<8, rec[3]|rec[4]<<8, rec[5]|rec[6]<<8,
              rec[7]|rec[8]<<8, rec[9]|rec[10]<<8, rec[11]|rec[12]<<8]
        pre = [b for b in rec[13:18] if b != 0xFF]
        L = r.get("learn") or {}
        if L:
            assert (lvl, st) == (L["level"], [L["hp"], L["mp"], L["atk"], L["def"], L["agl"], L["int"]]), r["id"]
        pc = ("prereq " + ",".join(f"${p:02x}" for p in pre)) if pre else "no prereq"
        out.append((None, 0, f"    ; --- ${r['id']:02x} {r['name']}: lvl {lvl}; hp {st[0]} mp {st[1]} atk {st[2]} def {st[3]} agl {st[4]} int {st[5]}; {pc}"))
        out.append((start + r["id"]*18, 18, "    db " + ", ".join(f"${b:02x}" for b in rec)))
    return out, data

def resect(fname, bank, start, size, kind, label):
    path = os.path.join(DIS, fname)
    src = open(path).read()
    if re.search(rf"^{label}:\s*(;.*)?$", src, re.M) and (f"{label}:  ; ${bank:02x}".upper() in src.upper()):
        print(f"  {fname}: already re-sectioned — skipping"); return None
    end = start + size
    lines, addr = probe_map(path)
    clean(); build(check_md5=True)           # fresh sym WITHOUT probe labels
    global SYM_TXT
    SYM_TXT = open(os.path.join(DIS, "game.sym")).read()
    coded = sorted(addr.items())
    A_i = max(i for i, a in coded if a <= start)
    B_i = min(i for i, a in coded if a >= end)
    A, B = addr[A_i], addr[B_i]
    # absorb a pre-existing bare `LABEL:` line for this label sitting just above
    # the first code line (our block re-declares it — avoid a duplicate label)
    while A_i > 0 and re.match(rf"^{label}:\s*(;.*)?$", lines[A_i-1]):
        A_i -= 1
    # guard: labels defined in removed lines must not be referenced from kept lines
    removed = lines[A_i:B_i]
    kept = lines[:A_i] + lines[B_i:]
    defs = [m.group(1) for l in removed for m in [re.match(r"^([A-Za-z_]\w*):", l)]
            if m and m.group(1) != label]  # the target label is re-declared by our block
    kept_txt = "\n".join(kept)
    keep = {}   # addr -> fake-artifact label that MUST survive at its exact offset
    for d in defs:
        if re.search(rf"\b{d}\b", kept_txt):
            # referenced from a not-yet-re-sectioned (fake-decoded) region elsewhere
            # in the bank: keep the label at its exact byte offset inside our block
            m = re.search(rf"^06:([0-9A-Fa-f]{{4}}) {d}$", SYM_TXT, re.M) or \
                re.search(rf"^0?7:([0-9A-Fa-f]{{4}}) {d}$", SYM_TXT, re.M)
            if not m:
                sys.exit(f"ABORT {fname}: outside-referenced label {d} has no sym address")
            keep[int(m.group(1), 16)] = d
    segs, data = (emit_mp if kind == "mp" else emit_learn)(start)
    assert data == rom_bytes(bank, start, size)
    if A < start:
        segs = [(None, 0, f"; ${A:04x}-${start-1:04x}: tail of the preceding region (preserved verbatim, was fake-decoded)"),
                (A, start - A, "    db " + ", ".join(f"${b:02x}" for b in rom_bytes(bank, A, start - A)))] + segs
    if end < B:
        segs += [(None, 0, f"; ${end:04x}-${B-1:04x}: bytes between {label} and the next labeled line (unclassified; preserved verbatim, was fake-decoded)"),
                 (end, B - end, "    db " + ", ".join(f"${b:02x}" for b in rom_bytes(bank, end, B - end)))]
    # insert kept artifact labels at exact offsets, splitting db/dw rows as needed
    for kaddr in sorted(keep):
        kname = keep[kaddr]
        for i, (sa, sn, txt) in enumerate(segs):
            if sa is not None and sa <= kaddr < sa + sn:
                row = rom_bytes(bank, sa, sn)
                pre, post = row[:kaddr - sa], row[kaddr - sa:]
                repl = []
                if pre:  repl.append((sa, len(pre), "    db " + ", ".join(f"${b:02x}" for b in pre)))
                repl.append((None, 0, f"{kname}:  ; fake-decode ARTIFACT kept at exact offset ${kaddr:04x} — referenced by a fake instruction in a not-yet-re-sectioned region of this bank; NOT a real entry point (mid-table byte)"))
                repl.append((kaddr, len(post), "    db " + ", ".join(f"${b:02x}" for b in post)))
                segs[i:i+1] = repl
                break
        else:
            sys.exit(f"ABORT: kept label {kname} @ ${kaddr:04x} not inside any emitted segment")
    block = [txt for _, _, txt in segs]
    removed_defs = [d for d in defs if d not in keep.values()]
    if removed_defs:
        block += [f"; NOTE: fake-decode artifact labels removed with this region: " + ", ".join(removed_defs)]
    if keep:
        print(f"    kept {len(keep)} artifact labels at exact offsets: " + ", ".join(keep.values()))
    new_lines = lines[:A_i] + block + lines[B_i:]
    open(path, "w").write("\n".join(new_lines) + "\n")
    clean(); build(check_md5=True)
    print(f"  {fname}: [{A:04x},{B:04x}) → {label} dw/db block; {len(removed)} fake lines → {len(block)}; clean build byte-perfect")
    return "\n".join(removed), "\n".join(block)

def patch_tree(fname, old_block, new_block):
    p = os.path.join(REPO, "patches", fname)
    s = open(p).read()
    if old_block not in s:
        sys.exit(f"ABORT: patches/{fname} region text differs from disassembly — needs its own probe pass")
    open(p, "w").write(s.replace(old_block, new_block, 1))
    print(f"  patches/{fname}: identical region replaced")

def main():
    if "--check" in sys.argv:
        for fname, bank, start, size, kind, label in TARGETS:
            for tree in (DIS, os.path.join(REPO, "patches")):
                s = open(os.path.join(tree, fname)).read()
                ok = f"{label}:" in s
                print(f"{tree.split('/')[-1]}/{fname}: {label} {'present' if ok else 'MISSING'}")
        clean(); build(); print("clean build byte-perfect"); return
    for fname, bank, start, size, kind, label in TARGETS:
        print(f"== {label} ({fname} ${start:04x}..${start+size:04x})")
        r = resect(fname, bank, start, size, kind, label)
        if r:
            patch_tree(fname, *r)
    clean(); build()
    print("DONE — clean build byte-perfect", CLEAN_MD5)

if __name__ == "__main__":
    main()
