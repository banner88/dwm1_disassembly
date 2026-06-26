#!/usr/bin/env python3
"""
resection_text_bank.py — convert a misassembled per-bank TEXT region from mgbdis
fake-instructions into a labeled, byte-exact `db` block (T1 keystone, Arc 1).

WHY
  Banks $42-$4B and $4E hold the game's dialogue corpus: a small dispatch table
  + text-loader stubs (real CODE), followed by a large contiguous run of
  DTE-encoded text strings (DATA). mgbdis decoded the text run as ~12k bogus
  instruction lines per bank. The bytes are correct (build stays 1ca6579...),
  but the source READS as garbage, so vanilla text is not editable in source.
  This tool re-sections the text run into `TextStr_<bank>_<addr>:` + `db` blocks,
  one label per string (from text_id_map.json), each carrying the decoded text in
  a comment. Labels/comments only => ZERO byte impact, build MUST stay 1ca6579.

HOW (mirrors tools/resection_library_tables.py)
  1. Region bounds come from DATA, not guesses:
       - first text addr  = min string addr for the bank (text_id_map.json)
       - region end       = start of the bank's trailing $00/$FF padding (ROM)
  2. A zero-byte probe build maps every source line -> its address (game.sym).
     The probe build is asserted byte-perfect (labels emit no bytes).
  3. R_start / R_end are SNAPPED to real line boundaries (down / up) so no fake
     instruction is split. The exact ROM bytes [R_start,R_end) are emitted as
     `db`, so byte-perfection is automatic regardless of where strings begin.
  4. String labels + decoded-text comments are placed at the listed string addrs
     that fall inside the region.
  5. Rebuild; assert MD5 == 1ca6579. A wrong split changes bytes and fails here.

  Idempotent: if the bank already carries the first text label, it is skipped.
  Re-runnable from the clean tree.

USAGE
  python3 tools/resection_text_bank.py --bank 0x47           # plan only (no write)
  python3 tools/resection_text_bank.py --bank 0x47 --apply   # convert + build + verify
  python3 tools/resection_text_bank.py --bank 0x47 --check   # verify current build byte-perfect
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIS = os.path.join(REPO, "disassembly")
ROM = os.path.join(REPO, "data", "DWM-original.gbc")
TEXT_MAP = os.path.join(REPO, "extracted", "text_id_map.json")
ORIGINAL_MD5 = "1ca6579359f21d8e27b446f865bf6b83"

# Banks whose strings live in text_id_map.json (the dialogue corpus).
CORPUS_BANKS = {0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4E}


def md5(path):
    return hashlib.md5(open(path, "rb").read()).hexdigest()


def rom_bytes(bank, start, end):
    base = bank * 0x4000
    data = open(ROM, "rb").read()
    return data[base + (start - 0x4000): base + (end - 0x4000)]


def padding_start(bank):
    """Address where the bank's trailing $00/$FF fill begins (== region end)."""
    base = bank * 0x4000
    data = open(ROM, "rb").read()[base: base + 0x4000]
    fill = 0
    for b in reversed(data):
        if b in (0x00, 0xFF):
            fill += 1
        else:
            break
    return 0x8000 - fill


def bank_strings(bank):
    """Sorted [(addr, [ids], decoded_text)] for this bank, deduped by addr."""
    m = json.load(open(TEXT_MAP))
    by_addr = {}
    for e in m.values():
        if int(e["bank"].lstrip("$"), 16) != bank:
            continue
        a = int(e["addr"].lstrip("$"), 16)
        by_addr.setdefault(a, ([], e.get("text", "")))[0].append(e["id"])
    return [(a, ids, txt) for a, (ids, txt) in sorted(by_addr.items())]


def asm_path(bank):
    return os.path.join(DIS, f"bank_{bank:03x}.asm")


def build():
    for f in ("game.o", "game.gbc", "game.sym", "game.map"):
        p = os.path.join(DIS, f)
        if os.path.exists(p):
            os.remove(p)
    r = subprocess.run("make", cwd=DIS, shell=True, capture_output=True, text=True)
    ok = os.path.exists(os.path.join(DIS, "game.gbc"))
    return ok, r.stdout + r.stderr


def build_line_addr_map(asm, bank):
    """Insert zero-byte probe labels, build once, return {line_idx0: addr}."""
    lines = open(asm).read().split("\n")
    probed, probe_of = [], {}
    for i, l in enumerate(lines):
        s = l.strip()
        if s and not s.startswith(";") and not (s.endswith(":") and " " not in s):
            probed.append(f"Lprobe_{i}:")
            probe_of[f"Lprobe_{i}"] = i
        probed.append(l)
    backup = asm + ".probebak"
    shutil.copy(asm, backup)
    try:
        open(asm, "w").write("\n".join(probed) + "\n")
        ok, log = build()
        if not ok:
            sys.exit("probe build failed:\n" + log)
        got = md5(os.path.join(DIS, "game.gbc"))
        if got != ORIGINAL_MD5:
            sys.exit(f"probe build not byte-perfect ({got}); aborting.")
        sym = open(os.path.join(DIS, "game.sym")).read()
    finally:
        shutil.move(backup, asm)
    addr_of = {}
    pat = re.compile(rf"^{bank:02x}:([0-9a-fA-F]{{4}}) (Lprobe_\d+)")
    for line in sym.splitlines():
        m = pat.match(line)
        if m:
            addr_of[m.group(2)] = int(m.group(1), 16)
    return lines, {ln: addr_of[name] for name, ln in probe_of.items() if name in addr_of}


def fmt_db(byts, indent="    "):
    out, row = [], []
    for b in byts:
        row.append(f"${b:02x}")
        if len(row) == 16:
            out.append(indent + "db " + ", ".join(row))
            row = []
    if row:
        out.append(indent + "db " + ", ".join(row))
    return out


def sanitize(txt, limit=140):
    t = txt.replace("//", " / ").replace("\n", " ")
    t = re.sub(r"\s+", " ", t).strip()
    return (t[:limit] + "...") if len(t) > limit else t


def emit_region(bank, R_start, R_end, strings):
    """Emit [R_start,R_end) as TextStr_<bank>_<addr> labeled db chunks."""
    # boundaries = listed string addrs strictly inside the region, plus R_start
    bounds = [a for a, _, _ in strings if R_start < a < R_end]
    boundaries = [R_start] + bounds
    out = [
        f"; --- BEGIN re-sectioned text run (bank ${bank:02x}: ${R_start:04x}-${R_end:04x}) ---",
        f"; DTE-encoded dialogue strings, one label per text id (text_id_map.json).",
        f"; Labels/comments only; bytes are byte-identical to the original ROM.",
    ]
    info = {a: (ids, txt) for a, ids, txt in strings}
    for i, b in enumerate(boundaries):
        nxt = boundaries[i + 1] if i + 1 < len(boundaries) else R_end
        chunk = rom_bytes(bank, b, nxt)
        if b in info:
            ids, txt = info[b]
            out.append(f"TextStr_{bank:02x}_{b:04x}:           ; id {' '.join(ids)}")
            if txt:
                out.append(f"    ; \"{sanitize(txt)}\"")
        else:
            out.append(f"TextStr_{bank:02x}_{b:04x}:           ; (region entry / unlisted fragment)")
        out += fmt_db(chunk)
    out.append(f"; --- END re-sectioned text run (bank ${bank:02x}) ---")
    return out


def already_done(asm, bank, first_addr):
    return re.search(rf"^TextStr_{bank:02x}_{first_addr:04x}:", open(asm).read(), re.M) is not None


def main():
    args = sys.argv[1:]
    if "--bank" not in args:
        sys.exit("need --bank 0xNN")
    bank = int(args[args.index("--bank") + 1], 16)
    apply_ = "--apply" in args
    check = "--check" in args

    if check:
        ok, log = build()
        if not ok:
            sys.exit("build failed:\n" + log)
        got = md5(os.path.join(DIS, "game.gbc"))
        print(f"clean build MD5 {got} {'OK (byte-perfect)' if got == ORIGINAL_MD5 else 'MISMATCH'}")
        sys.exit(0 if got == ORIGINAL_MD5 else 1)

    if bank not in CORPUS_BANKS:
        sys.exit(f"bank ${bank:02x} is not a known text-corpus bank {sorted(hex(b) for b in CORPUS_BANKS)}")

    asm = asm_path(bank)
    strings = bank_strings(bank)
    if not strings:
        sys.exit(f"no strings for bank ${bank:02x} in text_id_map.json")
    first_addr = strings[0][0]
    raw_start = first_addr
    raw_end = padding_start(bank)
    print(f"bank ${bank:02x}: {len(strings)} strings, raw region ${raw_start:04x}-${raw_end:04x} "
          f"({raw_end - raw_start} bytes)")

    if already_done(asm, bank, first_addr):
        print("  already re-sectioned (idempotent) — nothing to do")
        return

    lines, line_addr = build_line_addr_map(asm, bank)
    line_addrs = sorted(set(line_addr.values()))

    # Snap to real line boundaries: R_start down, R_end up (no split instruction).
    R_start = max(a for a in line_addrs if a <= raw_start)
    ge = [a for a in line_addrs if a >= raw_end]
    R_end = min(ge) if ge else 0x8000
    if raw_start - R_start > 16:
        sys.exit(f"R_start snap moved too far (${R_start:04x} vs ${raw_start:04x}) — refusing")
    print(f"  snapped region ${R_start:04x}-${R_end:04x}")

    in_range = [ln for ln, a in line_addr.items() if R_start <= a < R_end]
    if not in_range:
        sys.exit("no source lines map into region")
    sline, eline = min(in_range), max(in_range) + 1
    print(f"  replacing source lines {sline}-{eline} ({eline - sline} lines)")

    block = emit_region(bank, R_start, R_end, strings)
    new_lines = lines[:sline] + block + lines[eline:]

    if not apply_:
        print("  (plan only — pass --apply to write + build + verify)")
        return

    backup = asm + ".bak"
    shutil.copy(asm, backup)
    try:
        open(asm, "w").write("\n".join(new_lines) + "\n")
        ok, log = build()
        if not ok:
            shutil.move(backup, asm)
            sys.exit("build FAILED after re-section:\n" + log[-2000:])
        got = md5(os.path.join(DIS, "game.gbc"))
        if got != ORIGINAL_MD5:
            shutil.move(backup, asm)
            sys.exit(f"NOT byte-perfect after re-section ({got}); reverted.")
        os.remove(backup)
        n = sum(1 for l in block if l.startswith("TextStr_"))
        print(f"  OK: {n} text labels emitted, build byte-perfect ({got})")
    except Exception:
        if os.path.exists(backup):
            shutil.move(backup, asm)
        raise


if __name__ == "__main__":
    main()
