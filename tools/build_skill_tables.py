#!/usr/bin/env python3
"""Re-emit the skill data tables from extracted/skill_records.json and prove the
round-trip is byte-identical to the original ROM (the keystone guarantee).

Tables covered (the numeric, fully-owned ones):
  - SkillFunctionTable   $52:$4011   222 x dw (handler_addr)
  - SkillMPCostTable     $07:$570C   222 x u16 LE  (ALL -> 999)
  - SkillLearnReqTable   $06:$50E0   222 x 18B record
  - SkillRecordPtrTable  $54:$4013   222 x dw  (= $41CF + id*19; dispatch entries 9..230)
  - SkillRecordData      $54:$41CF   222 x 19B per-skill PARAMETER block
                                     (power/targeting/message; handler is the shared
                                      effect TYPE, record is the per-skill params)

(The name pointer table + strings round-trip is owned by the text keystone, T1.)

Usage:
  python3 tools/build_skill_tables.py --selftest      # PASS/FAIL byte-compare
  python3 tools/build_skill_tables.py --emit func     # print asm dw block
  python3 tools/build_skill_tables.py --emit mp        # print asm dw block
  python3 tools/build_skill_tables.py --emit learn     # print asm db block

--selftest exits non-zero on any mismatch so it can gate CI / verify_integrity.
"""
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(SCRIPT_DIR)
sys.path.insert(0, REPO)
from dwm.rom import ROM  # noqa: E402

ROM_PATH = os.path.join(REPO, "data", "DWM-original.gbc")
JSON_PATH = os.path.join(REPO, "extracted", "skill_records.json")

N = 222
FUNC_BANK, FUNC_TABLE = 0x52, 0x4011
MP_BANK, MP_TABLE = 0x07, 0x570C
LEARN_BANK, LEARN_TABLE, LEARN_REC = 0x06, 0x50E0, 18
MP_ALL = 999

# Battle "record" table (per-skill PARAMETER block; see gen_skill_records.py).
# $54:$4013 = entry 9 of the rst-$10 dispatch table; entries 9..230 are the 222
# record pointers (= $41CF + id*19). The record DATA (222 x 19 = 4218 B) begins
# at $41CF, immediately after the 231-entry table.
REC_BANK, REC_PTRS, REC_DATA, REC_STRIDE = 0x54, 0x4013, 0x41CF, 19
sys.path.insert(0, SCRIPT_DIR)
from gen_skill_records import encode_battle_record  # noqa: E402  (single codec)


def load_records():
    d = json.load(open(JSON_PATH))
    recs = {r["id"]: r for r in d["records"]}
    return [recs[i] for i in range(N)]


def lo_hi(v):
    return bytes([v & 0xFF, (v >> 8) & 0xFF])


def emit_func_bytes(recs):
    out = bytearray()
    for r in recs:
        out += lo_hi(int(r["handler_addr"].lstrip("$"), 16))
    return bytes(out)


def emit_mp_bytes(recs):
    out = bytearray()
    for r in recs:
        mp = MP_ALL if r["mp_cost"] == "ALL" else int(r["mp_cost"])
        out += lo_hi(mp)
    return bytes(out)


def emit_learn_bytes(recs):
    out = bytearray()
    for r in recs:
        L = r["learn"]
        rec = bytearray()
        rec.append(L["level"] & 0xFF)
        for k in ("hp", "mp", "atk", "def", "agl", "int"):
            rec += lo_hi(L[k])
        pre = list(r["prereqs"])
        pre += [0xFF] * (5 - len(pre))
        rec += bytes(pre[:5])
        assert len(rec) == LEARN_REC, len(rec)
        out += rec
    return bytes(out)


def emit_record_data_bytes(recs):
    """The 222 x 19B record data block at $54:$41CF (4218 bytes)."""
    out = bytearray()
    for r in recs:
        out += encode_battle_record(r["battle_record"]["fields"])
    return bytes(out)


def emit_record_ptr_bytes(recs):
    """The 222 record pointers (dispatch-table entries 9..230) = $41CF + id*19."""
    out = bytearray()
    for r in recs:
        out += lo_hi(REC_DATA + r["id"] * REC_STRIDE)
    return bytes(out)


def rom_bytes(rom, bank, addr, size):
    return rom.read(bank, addr, size)


def selftest():
    from pathlib import Path
    rom = ROM(Path(ROM_PATH))
    recs = load_records()
    checks = [
        ("SkillFunctionTable", FUNC_BANK, FUNC_TABLE, emit_func_bytes(recs), N * 2),
        ("SkillMPCostTable",   MP_BANK,  MP_TABLE,   emit_mp_bytes(recs),   N * 2),
        ("SkillLearnReqTable", LEARN_BANK, LEARN_TABLE, emit_learn_bytes(recs), N * LEARN_REC),
        ("SkillRecordPtrTable", REC_BANK, REC_PTRS, emit_record_ptr_bytes(recs), N * 2),
        ("SkillRecordData",     REC_BANK, REC_DATA, emit_record_data_bytes(recs), N * REC_STRIDE),
    ]
    ok = True
    for name, bank, addr, got, size in checks:
        want = rom_bytes(rom, bank, addr, size)
        if got == want:
            print(f"  OK   {name:<20} ${bank:02X}:${addr:04X}  {size} bytes byte-identical")
        else:
            ok = False
            # first differing offset
            diff = next((k for k in range(min(len(got), len(want))) if got[k] != want[k]), None)
            print(f"  FAIL {name:<20} mismatch at offset {diff} "
                  f"(got {got[diff]:#04x} want {want[diff]:#04x}, skill id ~{diff // (size // N)})")
    print("SKILL TABLE ROUND-TRIP:", "PASS" if ok else "FAIL")
    return ok


def emit_asm(which):
    recs = load_records()
    if which == "func":
        print("SkillFunctionTable:  ; $52:$4011 — 222 x dw skill effect handler")
        for r in recs:
            print(f"    dw ${int(r['handler_addr'].lstrip('$'),16):04X}  ; [{r['id']:3d}] {r['name']}")
    elif which == "mp":
        print("SkillMPCostTable:  ; $07:$570C — 222 x u16 LE MP cost (999=ALL)")
        for r in recs:
            mp = MP_ALL if r["mp_cost"] == "ALL" else int(r["mp_cost"])
            print(f"    dw {mp:>3}  ; [{r['id']:3d}] {r['name']}")
    elif which == "learn":
        print("SkillLearnReqTable:  ; $06:$50E0 — 222 x 18B (lvl u8; hp/mp/atk/def/agl/int u16; 5 prereq ids $FF=none)")
        for r in recs:
            L = r["learn"]
            pre = list(r["prereqs"]) + [0xFF] * (5 - len(r["prereqs"]))
            stats = ", ".join(f"${L[k] & 0xFF:02X}, ${(L[k] >> 8) & 0xFF:02X}"
                              for k in ("hp", "mp", "atk", "def", "agl", "int"))
            prs = ", ".join(f"${p:02X}" for p in pre[:5])
            print(f"    db ${L['level']:02X}, {stats}, {prs}  ; [{r['id']:3d}] {r['name']}")
    elif which == "recordptr":
        print("SkillRecordPtrTable:  ; $54:$4013 — 222 x dw (dispatch entries 9..230 = $41CF+id*19)")
        for r in recs:
            print(f"    dw ${REC_DATA + r['id'] * REC_STRIDE:04X}  ; [{r['id']:3d}] {r['name']}")
    elif which == "record":
        print("SkillRecordData:  ; $54:$41CF — 222 x 19B per-skill parameter block")
        for r in recs:
            b = encode_battle_record(r["battle_record"]["fields"])
            print("    db " + ", ".join(f"${x:02X}" for x in b) + f"  ; [{r['id']:3d}] {r['name']}")
    else:
        print("unknown table:", which, file=sys.stderr)
        sys.exit(2)


def main():
    if "--selftest" in sys.argv:
        sys.exit(0 if selftest() else 1)
    if "--emit" in sys.argv:
        emit_asm(sys.argv[sys.argv.index("--emit") + 1])
        return
    print(__doc__)


if __name__ == "__main__":
    main()
