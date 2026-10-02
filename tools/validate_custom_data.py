#!/usr/bin/env python3
"""validate_custom_data.py — hard-error checks for crash-capable custom data.

Born from the S75 Dracky-battle crash investigation. Two classes of custom
data can produce a crashy patched ROM while assembling cleanly:

1. CUSTOM LEARN RECORDS (S111: bank $72 CustomLearnTable, ids $E0-$FE, the
   compiler region gd_custom_learn — S75-S110 they were the hand tables
   CustomLearnReqTable/2 in bank $06, whose fixed scan bound this tool also
   checked; S111's LearnLoopFork walks every custom id and skips level $FF):
   - structural: 31 records of exactly 18 bytes (lvl + 6x u16 stats + 5
     prereq bytes), level 1-99 or $FF (= not learnable), prereq ids $FF or a
     skill id ($00-$D9 a stock row, $E0-$FE a custom one with a learn row).
   - UNIVERSAL QUALIFIERS (no prereq AND all-zero stats) are only permitted
     if the code-2 fence (LearnCode2Guard06, `cp $da` since S111) is present
     in the built ROM: without it, any monster at the required level
     stat-learns the custom skill through the never-exercised code-2 display
     path.

2. REPLACEMENT BATTLE-SPRITE STREAMS (bank $36 pointer-table redirects):
   - every redirected pointer-table entry must decode via dwm.sprite_codec
     to EXACTLY the tile count of the stream it replaces. A short/long
     decode means the loader over/under-reads in some consumer context.
   - S105 (P3.9b): the only redirect ever made (the S21 Dracky -> "Clam"
     battle-sprite POC, entry 39) was purged with patches/bank_036.asm, so
     today every entry equals the original and the check is a guard for
     future redirects.

Usage:
  python3 tools/validate_custom_data.py --rom <patched.gbc>   # full check
  python3 tools/validate_custom_data.py --records-only        # source-only

Exit code 0 = PASS, 1 = FAIL (build systems must treat FAIL as fatal).
"""
import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO))

RECORD_LEN = 18
LEARN_FIRST, LEARN_ROWS = 0xE0, 31


def _records_from_rom(rom):
    """The 31 custom learn rows, found through bank $72 entry 6
    (CustomLearnRow72: `add hl,bc / add hl,bc / ld bc, CustomLearnTable`)."""
    b72 = 0x72 * 0x4000
    ent = rom[b72 + 0x0D] | rom[b72 + 0x0E] << 8
    code = rom[b72 + ent - 0x4000:b72 + ent - 0x4000 + 48]
    k = code.find(bytes([0x09, 0x09, 0x01]))
    if k < 0:
        return None
    tab = code[k + 3] | code[k + 4] << 8
    o = b72 + tab - 0x4000
    return [rom[o + RECORD_LEN * i:o + RECORD_LEN * (i + 1)] for i in range(LEARN_ROWS)]


def _records_from_source():
    src = (REPO / "patches" / "bank_072.asm").read_text()
    m = re.search(r"; @BUILD_PROJECT BEGIN gd_custom_learn\n(.*?); @BUILD_PROJECT END", src, re.S)
    if not m:
        return None
    vals = []
    for dbl in re.finditer(r"^\s+db\s+([^\n;]+)", m.group(1), re.M):
        vals += [int(v.strip().replace("$", "0x"), 16) if "$" in v else int(v)
                 for v in dbl.group(1).split(",")]
    if not vals:                          # a placeholder `ds` region (not --apply'd)
        return []
    return [bytes(vals[i:i + RECORD_LEN]) for i in range(0, len(vals), RECORD_LEN)]


def check_records(errors, rom=None):
    rows = _records_from_rom(rom) if rom is not None else _records_from_source()
    if rows is None:
        errors.append("custom learn rows not found (bank $72 CustomLearnTable)")
        return []
    if rows and len(rows) != LEARN_ROWS:
        errors.append(f"custom learn rows: {len(rows)} records, want {LEARN_ROWS}")
    universal, learnable = [], set()
    for i, r in enumerate(rows):
        if r[0] != 0xFF:
            learnable.add(LEARN_FIRST + i)
    for i, r in enumerate(rows):
        sid = LEARN_FIRST + i
        if len(r) != RECORD_LEN:
            errors.append(f"learn row ${sid:02X}: {len(r)} bytes")
            continue
        if r[0] == 0xFF:
            continue
        if not 1 <= r[0] <= 99:
            errors.append(f"learn row ${sid:02X}: level {r[0]} outside 1-99 ($FF = not learnable)")
        stats = [r[1 + j * 2] | (r[2 + j * 2] << 8) for j in range(6)]
        prereqs = list(r[13:18])
        for p in prereqs:
            if p != 0xFF and not (p <= 0xD9 or p in learnable or p in range(0xE0, 0xFF)):
                errors.append(f"learn row ${sid:02X}: prereq ${p:02X} is not a skill id")
        if all(p == 0xFF for p in prereqs) and all(x == 0 for x in stats):
            universal.append(sid)
    return universal


def check_rom(rom_path, universal, errors):
    rom = Path(rom_path).read_bytes()
    b06 = 0x06 * 0x4000
    # code-2 fence: Jump_006_50b5 must start with jp (C3) into bank $06,
    # and the guard body (cp $e1 / jp nc) must exist at the jp target.
    head = rom[b06 + 0x10B5:b06 + 0x10B8]
    fence_ok = False
    if head[0] == 0xC3:
        tgt = head[1] | (head[2] << 8)
        body = rom[b06 + (tgt - 0x4000):b06 + (tgt - 0x4000) + 8]
        fence_ok = bytes([0x79, 0xFE, 0xDA]) == body[:3] and body[3] == 0xD2   # S111: cp $da
    if universal and not fence_ok:
        errors.append(
            f"universal-qualifier learn rows {['$%02X' % u for u in universal]} present "
            "but the code-2 fence (LearnCode2Guard06) is ABSENT from the ROM — this is "
            "the S75 crash-capable configuration (any monster stat-learns the custom id "
            "through the unexercised code-2 display path)")
    # slot-bound fence in bank $50: CmpBtl_6383 head must be a jp trampoline
    # whose target contains cp $28 (the S71 40-slot bound).
    b50 = 0x50 * 0x4000
    p50 = rom[b50 + 0x2383:b50 + 0x2386]
    slot_ok = False
    if p50[0] == 0xC3:
        tgt = p50[1] | (p50[2] << 8)
        body = rom[b50 + (tgt - 0x4000):b50 + (tgt - 0x4000) + 10]
        slot_ok = bytes([0xFE, 0x28]) in body
    if not slot_ok:
        errors.append("slot-index fence (SlotProbeGuard50, bound < $28) ABSENT from bank $50 "
                      "— stale-$cac0 probes can process the phantom slot 40 (echo RAM)")
    # sprite stream redirects: every bank $36 pointer-table entry must decode
    # to the same tile count as the ORIGINAL entry it replaced.
    from dwm.sprite_codec import decode, read_stream
    orig_path = REPO / "data" / "DWM-original.gbc"
    if not orig_path.exists():
        # S106 r3: was an uncaught FileNotFoundError (the editor showed an
        # empty "crash-config validation failed")
        errors.append(f"the original ROM is not at {orig_path} — copy DWM-original.gbc "
                      "(md5 1ca6579359f21d8e27b446f865bf6b83) there; the build compares "
                      "its sprite streams with it")
        return
    orig = orig_path.read_bytes()
    b36 = 0x36 * 0x4000
    for e in range(221):
        o_lo, o_hi = orig[b36 + 1 + e * 2], orig[b36 + 2 + e * 2]
        n_lo, n_hi = rom[b36 + 1 + e * 2], rom[b36 + 2 + e * 2]
        o_ptr, n_ptr = o_lo | (o_hi << 8), n_lo | (n_hi << 8)
        if o_ptr == n_ptr:
            continue  # not redirected
        if not (0x4000 <= n_ptr < 0x8000):
            errors.append(f"bank $36 entry {e}: redirected pointer ${n_ptr:04X} outside the bank")
            continue
        try:
            want = len(decode(read_stream(orig, b36 + (o_ptr - 0x4000))))
            got = len(decode(read_stream(rom, b36 + (n_ptr - 0x4000))))
        except Exception as ex:  # noqa: BLE001
            errors.append(f"bank $36 entry {e}: replacement stream does not decode ({ex})")
            continue
        if want != got:
            errors.append(f"bank $36 entry {e}: replacement decodes to {got} bytes, original {want} "
                          "— loader over/under-read in some consumer context")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", help="patched ROM to verify fences + streams against")
    ap.add_argument("--records-only", action="store_true")
    args = ap.parse_args()

    errors = []
    if args.rom and not args.records_only:
        universal = check_records(errors, Path(args.rom).read_bytes())
        check_rom(args.rom, universal, errors)
    else:
        universal = check_records(errors)
    if universal and not args.rom:
        print(f"note: universal-qualifier rows {['$%02X' % u for u in universal]} found; "
              "supply --rom to verify the code-2 fence is present")

    if errors:
        print("VALIDATE_CUSTOM_DATA: FAIL")
        for e in errors:
            print("  ERROR:", e)
        return 1
    print("VALIDATE_CUSTOM_DATA: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
