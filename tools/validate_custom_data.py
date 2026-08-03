#!/usr/bin/env python3
"""validate_custom_data.py — hard-error checks for crash-capable custom data.

Born from the S75 Dracky-battle crash investigation. Two classes of custom
data can produce a crashy patched ROM while assembling cleanly:

1. CUSTOM LEARN RECORDS (patches/bank_006.asm, CustomLearnReqTable/2):
   - structural: every record must be exactly 18 bytes (lvl + 6x u16 stats +
     5 prereq bytes), level 1-99, prereq ids must be $FF or an existing
     custom skill id covered by the scan range.
   - the scan range bound (LearnLoopFork `cp $XX`) must equal
     last_record_id + 1, or the scanner walks non-record bytes.
   - UNIVERSAL QUALIFIERS (no prereq AND all-zero stats) are only permitted
     if the code-2 fence (LearnCode2Guard06) is present in the built ROM:
     without it, any monster at the required level stat-learns the custom
     skill through the never-exercised code-2 display path.

2. REPLACEMENT BATTLE-SPRITE STREAMS (patches/bank_036.asm redirects):
   - every redirected pointer-table entry must decode via dwm.sprite_codec
     to EXACTLY the tile count of the stream it replaces. A short/long
     decode means the loader over/under-reads in some consumer context.

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
CUSTOM_BASE = 0xE1


def parse_learn_tables(src: str):
    """Extract (table_name, [(id, level, stats[6], prereqs[5])]) from bank_006."""
    tables = {}
    for name, first_id in (("CustomLearnReqTable", 0xE1), ("CustomLearnReqTable2", 0xE5)):
        m = re.search(rf"^{name}:\n(.*?)(?=^\S|\Z)", src, re.M | re.S)
        if not m:
            continue
        body = m.group(1)
        rows = []
        for dbl in re.finditer(r"^\s+db\s+([^\n;]+)", body, re.M):
            vals = [int(v.strip().replace("$", "0x"), 16) if "$" in v else int(v)
                    for v in dbl.group(1).split(",")]
            rows.extend(vals)
        records = []
        for i in range(0, len(rows) - len(rows) % RECORD_LEN, RECORD_LEN):
            r = rows[i:i + RECORD_LEN]
            stats = [r[1 + j * 2] | (r[2 + j * 2] << 8) for j in range(6)]
            records.append((first_id + i // RECORD_LEN, r[0], stats, r[13:18]))
        tables[name] = (records, len(rows))
    return tables


def check_records(errors):
    src = (REPO / "patches" / "bank_006.asm").read_text()
    tables = parse_learn_tables(src)
    all_ids = set()
    universal = []
    for name, (records, nbytes) in tables.items():
        if nbytes % RECORD_LEN:
            errors.append(f"{name}: byte count {nbytes} is not a multiple of {RECORD_LEN}")
        for sid, lvl, stats, prereqs in records:
            all_ids.add(sid)
            if not (1 <= lvl <= 99):
                errors.append(f"{name} ${sid:02X}: level {lvl} outside 1-99")
            has_prereq = any(p != 0xFF for p in prereqs)
            for p in prereqs:
                if p != 0xFF and not (CUSTOM_BASE <= p <= 0xF0):
                    errors.append(f"{name} ${sid:02X}: prereq ${p:02X} is not a custom id")
            if not has_prereq and all(s == 0 for s in stats):
                universal.append(sid)
    # prereq ids must reference records that exist
    for name, (records, _) in tables.items():
        for sid, _, _, prereqs in records:
            for p in prereqs:
                if p != 0xFF and p not in all_ids:
                    errors.append(f"{name} ${sid:02X}: prereq ${p:02X} has no learn record")
    # scan bound: LearnLoopFork's final `cp $XX` must be last id + 1
    fork = re.search(r"LearnLoopFork:.*?cp \$([0-9a-fA-F]{2})\s*\n\s*ret", src, re.S)
    if fork and all_ids:
        bound = int(fork.group(1), 16)
        want = max(all_ids) + 1
        if bound != want:
            errors.append(f"LearnLoopFork scan bound ${bound:02X} != last record id + 1 (${want:02X})")
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
        fence_ok = bytes([0x79, 0xFE, 0xE1]) == body[:3] and body[3] == 0xD2
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
    orig = (REPO / "data" / "DWM-original.gbc").read_bytes()
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
    universal = check_records(errors)
    if args.rom and not args.records_only:
        check_rom(args.rom, universal, errors)
    elif universal and not args.rom:
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
