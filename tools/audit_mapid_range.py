#!/usr/bin/env python3
"""audit_mapid_range.py — A'1: mapID >=$80 readiness census (S66).

Enumerates every `ld a, [wMapID]` consumer site in BOTH trees, classifies the
instruction pattern that consumes A, and attaches the S66 human-adjudicated
verdict. Owning doc: CROSSBANK_ROOMS.md "mapID >=$80 readiness audit (A'1)".

Purpose for future sessions: when custom content crosses mapID $7F
(custom room #22+, Layer A'), re-run this tool. A site reported NEEDS_REVIEW
is NEW since S66 and must be adjudicated by hand before shipping rooms >=$80.
The pinned site counts are a drift tripwire, not a promise the tree is frozen.

Key S66 facts the verdicts encode (full reasoning in the owning doc):
  * The SM83 has no sign flag; `jp m`-class tests cannot exist. Every wMapID
    comparison in the ROM is an UNSIGNED `cp` — mapIDs >=$80 take the
    identical branch already proven by rooms $6B-$70.
  * The real >=$80 hazard classes are (a) 8-bit `add a` doubling that drops
    the $100 carry (RST_00 itself is $7F-capped this way) and (b) fixed-size
    tables. Every such vanilla site is diverted upstream for ALL mapIDs
    >=$6B by an unsigned predicate in the patched tree, or runs only in gate
    context where wMapID = floortype/gateID (< $20).
  * Custom-side `sub CUSTOM_ROOM_START / add a` idiom caps at index $7F ->
    mapID <=$EA. Hard ceiling $FE ($FF = exit-list terminator byte).

Usage:
  python3 tools/audit_mapid_range.py            # full table + selftest
  python3 tools/audit_mapid_range.py --json     # + write extracted/mapid_range_audit.json
  python3 tools/audit_mapid_range.py --selftest # counts-only (CI-friendly)
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TREES = {"clean": "disassembly", "patched": "patches"}

LOAD_RE = re.compile(r"^\s*ld a, \[wMapID\]")
LABEL_RE = re.compile(r"^(\.?[A-Za-z_][A-Za-z0-9_]*):")
A_KILL_RE = re.compile(r"^\s*(ld a,|ldh a,|pop af)")

# Verdict codes (adjudicated S66; per-site reasoning in CROSSBANK_ROOMS):
#  CP_UNSIGNED   unsigned cp chain; >=$80 takes the same branch proven by $6B-$70
#  COPY          full-byte copy to another var/HRAM; consumer audited (doc table)
#  DEAD          dead load (A overwritten before any use)
#  DEBUG         debug-menu display only
#  IDX16         16-bit index math; safe for the full 0-$FE range
#  LOSSY_DIVERTED  8-bit `add a` x2 walk that DROPS the $100 carry — but the
#                patched tree diverts ALL mapIDs >=$6B upstream (unsigned cp)
#  GATE_CTX      reachable only with wMapID = floortype/gateID (< $20)
#  TBL_GUARDED   table walk whose reachable index range is bounded by an
#                upstream unsigned cp guard (only vanilla-range values index)
#  CLAMPED       via MapIDClampForDispatch/Palette (unsigned clamp to 0)
#  IDX8_SUB6B    custom-side `sub $6B` then 8-bit `add a`; safe to mapID $EA
#  BOUNDED       explicit in-code bounds check (safe; may cap a FEATURE at $7F)
#  RST00_CLAMPED mapID-driven rst $00 (RST_00 is $7F-capped by construction —
#                the `add a` carry is lost before `adc h`); clamp-protected
#  WATCH         pre-existing >=$6B table overrun, empirically benign on all
#                proven paths (v7 load-in-room OK); crossing $80 changes
#                NOTHING — but if the editor ever depends on this path for
#                custom rooms, emit a custom table
#
# Keyed by (file, anchor label, occurrence-under-label). Vanilla labels are
# shared by both trees; patched-only code carries its own labels. A site whose
# key is absent -> NEEDS_REVIEW (new code since S66: adjudicate by hand, then
# add its key here AND its reasoning to the owning doc).
V = {
    # ---- bank_000
    ("bank_000.asm", "UseGateWorldTable", 0): "IDX16",       # clean only (patched: rst -> bank $71 entry 0)
    ("bank_000.asm", "CheckGateWorldMapType", 0): "CP_UNSIGNED",
    ("bank_000.asm", "CheckGateWorldMapType", 1): "CP_UNSIGNED",
    # ---- bank_001
    ("bank_001.asm", "InitFieldState", 0): "COPY",           # -> $c96a (write-only mirror, zero readers)
    ("bank_001.asm", "InitFieldState", 1): "CP_UNSIGNED",
    ("bank_001.asm", "ClearAnimationState", 0): "CP_UNSIGNED",
    ("bank_001.asm", "LoadNewBGMIdIntoA", 0): "CP_UNSIGNED", # patched S64: resolver-first, then same guard
    ("bank_001.asm", "jr_001_4346", 0): "TBL_GUARDED",       # RoomBGMTable x1 stride: cp $61 guard stops >=$61
    ("bank_001.asm", "SaveMapStateToHRAM", 0): "COPY",       # hram $d5 consumer = unsigned cp classifier
    ("bank_001.asm", "jr_001_4464", 0): "WATCH",             # default-SPAWN table (auto-label "NPCWalkDataTable"
                                                             # is misleading), raw mapID x4, 16-bit math
    ("bank_001.asm", "CheckBattleModeFlag", 0): "COPY",      # -> wScriptMapType
    ("bank_001.asm", "RetIfInGateworld", 0): "CP_UNSIGNED",
    ("bank_001.asm", "CheckSpecialMapExits", 0): "CP_UNSIGNED",
    ("bank_001.asm", "CopyPlayerCoordsAndGetNextRoom", 0): "COPY",
    ("bank_001.asm", "CheckScriptBeforeAction", 0): "CP_UNSIGNED",
    ("bank_001.asm", "jr_001_5e23", 0): "GATE_CTX",          # FloorDamageTable (damage-tile class; S41 rotation note)
    ("bank_001.asm", "jr_001_6115", 0): "RST00_CLAMPED",     # PerRoomDispatchEntry
    ("bank_001.asm", "CheckPaletteAnimActive", 0): "CP_UNSIGNED",
    # ---- bank_003 / _004
    ("bank_003.asm", "jr_003_6dd9", 0): "CP_UNSIGNED",
    ("bank_004.asm", "label4_5bdb", 0): "CP_UNSIGNED",
    ("bank_004.asm", "label4_66bd", 0): "COPY",              # -> $c8fb pair (teleport params; full byte)
    ("bank_004.asm", "label4_68d7", 0): "COPY",
    # ---- bank_006 / _007 / _009
    ("bank_006.asm", "jr_006_4d99", 0): "CP_UNSIGNED",
    ("bank_006.asm", "jr_006_60b8", 0): "CP_UNSIGNED",
    ("bank_006.asm", "jr_006_618e", 0): "COPY",              # -> wScriptMapType ($70 forced in gateworld)
    ("bank_006.asm", "jr_006_66c2", 0): "COPY",
    ("bank_006.asm", "jr_006_6893", 0): "CP_UNSIGNED",
    ("bank_006.asm", "Jump_006_6b87", 0): "CP_UNSIGNED",
    ("bank_007.asm", "jr_007_6004", 0): "CP_UNSIGNED",
    ("bank_007.asm", "CmpFld_604d", 0): "CP_UNSIGNED",
    ("bank_009.asm", "jr_009_46de", 0): "CP_UNSIGNED",
    ("bank_009.asm", "SetFld9_4bc8", 0): "CP_UNSIGNED",
    # ---- bank_00b (the room-data readers)
    ("bank_00b.asm", "jr_00b_4037", 0): "IDX16",
    ("bank_00b.asm", "jr_00b_4037", 1): "DEAD",
    ("bank_00b.asm", "jr_00b_4094", 0): "IDX16",
    ("bank_00b.asm", "jr_00b_4094", 1): "DEAD",
    ("bank_00b.asm", "jr_00b_4244", 0): "LOSSY_DIVERTED",    # ReadStepBlock
    ("bank_00b.asm", "GetRoomDataPtr", 0): "LOSSY_DIVERTED", # ReadInteractPtr
    ("bank_00b.asm", "labelb_4488", 0): "LOSSY_DIVERTED",    # special block reader
    ("bank_00b.asm", "labelb_451d", 0): "LOSSY_DIVERTED",    # exit block reader
    ("bank_00b.asm", "jr_00b_4601", 0): "CP_UNSIGNED",
    ("bank_00b.asm", "jr_00b_462c", 0): "COPY",              # same-room transition compare/restore
    ("bank_00b.asm", "jr_00b_4674", 0): "CP_UNSIGNED",
    ("bank_00b.asm", "jr_00b_4674", 1): "CP_UNSIGNED",
    ("bank_00b.asm", "jr_00b_492a", 0): "CP_UNSIGNED",
    ("bank_00b.asm", "Jump_00b_4945", 0): "CP_UNSIGNED",
    # ---- bank_013 / _016 / _017
    ("bank_013.asm", "label13_7370", 0): "CP_UNSIGNED",
    ("bank_016.asm", "label16_5b4e", 0): "COPY",             # gate-entry: -> wGateID (gate ids only; exits to
                                                             # custom rooms MUST carry gate_flag=0)
    ("bank_016.asm", "label16_6f05", 0): "CP_UNSIGNED",
    ("bank_016.asm", "jr_016_6f39", 0): "GATE_CTX",          # EncounterRateData x8 (wMapID = floortype)
    ("bank_017.asm", "label17_401d", 0): "LOSSY_DIVERTED",   # AttrPtrTable (patched: CustomAttrCheck)
    ("bank_017.asm", "jr_017_4071", 0): "GATE_CTX",          # FloorPalettePtrTable (floortype)
    ("bank_017.asm", "label17_409e", 0): "LOSSY_DIVERTED",   # AttrPtrTable #2 (patched: clamp call)
    # ---- bank_050 / _051 / _055
    ("bank_050.asm", "Jump_050_640a", 0): "CP_UNSIGNED",
    ("bank_050.asm", "Jump_050_64e0", 0): "CP_UNSIGNED",
    ("bank_051.asm", "jr_051_4073", 0): "CP_UNSIGNED",
    ("bank_055.asm", "jr_055_4a47", 0): "DEBUG",
    ("bank_055.asm", "Jump_055_4dba", 0): "COPY",
    # ---- patched-only code
    ("bank_000.asm", "MapIDClampForPalette", 0): "CLAMPED",  # the merged clamp body itself (unsigned cp/ret c)
    ("bank_00b.asm", "SharedPtrChase", 0): "TBL_GUARDED",    # reached only for mapID <$6B (custom diverted upstream)
    ("bank_00b.asm", "CustomDescentInGate", 0): "CP_UNSIGNED",
    ("bank_017.asm", "CustomAttrCheck", 0): "IDX8_SUB6B",
    ("bank_017.asm", "CustomPalCheck", 0): "IDX8_SUB6B",
    ("bank_060.asm", "CustomPtrChase", 0): "IDX8_SUB6B",
    ("bank_060.asm", "CustomPtrChase", 1): "IDX8_SUB6B",
    ("bank_060.asm", "GateAwareDispatch", 0): "CP_UNSIGNED",
    ("bank_071.asm", "CopyCustomRoomRecord", 0): "CP_UNSIGNED",  # derives wCustomRoomFlag
    ("bank_071.asm", "CopyCustomRoomRecord", 1): "CP_UNSIGNED",  # $70 table split
    ("bank_071.asm", "CopyCustomRoomRecord", 2): "IDX16",        # sla/rl x8
    ("bank_071.asm", "CustomEncResolve", 0): "BOUNDED",          # cp ENC_TABLE_LEN
    ("bank_071.asm", "CustomRoomBGMResolve", 0): "BOUNDED",      # cp $80 (FEATURE cap $7F; ROADMAP follow-up)
}

# Site-count pins (S66). A mismatch = the tree changed; re-adjudicate.
PIN_CLEAN = 58
PIN_PATCHED_MIN = 50   # patched loses raw loads to clamp/intercept rewrites…
PIN_PATCHED_MAX = 90   # …and gains custom-bank sites; band, not exact, so
                       # compiler-regenerated banks don't false-alarm.


def scan(tree):
    droot = os.path.join(ROOT, TREES[tree])
    sites = []
    for fn in sorted(os.listdir(droot)):
        if not fn.endswith(".asm"):
            continue
        label = "?"
        per_label = {}
        lines = open(os.path.join(droot, fn), encoding="utf-8",
                     errors="replace").read().splitlines()
        for i, ln in enumerate(lines):
            m = LABEL_RE.match(ln)
            if m and not m.group(1).startswith("."):
                label = m.group(1)
            if not LOAD_RE.match(ln):
                continue
            cls = set()
            for w in lines[i + 1:i + 13]:
                ws = w.split(";")[0].strip()
                if not ws:
                    continue
                if ws.startswith("cp "):
                    cls.add("cp")
                elif ws == "add a":
                    cls.add("add_a")
                elif ws.startswith("bit 7"):
                    cls.add("bit7")
                elif ws.startswith("rst $00"):
                    cls.add("rst00")
                elif ws.startswith(("ld [", "ldh [")):
                    cls.add("store")
                elif ws.startswith("sub "):
                    cls.add("sub")
                if A_KILL_RE.match(w) or ws.startswith(("ret", "jp hl")):
                    break
            k = per_label.get(label, 0)
            per_label[label] = k + 1
            sites.append({"tree": tree, "file": fn, "line": i + 1,
                          "label": label, "occ": k, "pattern": sorted(cls),
                          "verdict": V.get((fn, label, k), "NEEDS_REVIEW")})
    return sites


def main():
    clean = scan("clean")
    patched = scan("patched")
    ok = True
    if len(clean) != PIN_CLEAN:
        print(f"SELFTEST FAIL: clean-tree wMapID loads = {len(clean)}, "
              f"pinned {PIN_CLEAN} — tree changed, re-adjudicate "
              f"(CROSSBANK_ROOMS audit section)")
        ok = False
    if not (PIN_PATCHED_MIN <= len(patched) <= PIN_PATCHED_MAX):
        print(f"SELFTEST FAIL: patched-tree loads = {len(patched)}, "
              f"outside pin band [{PIN_PATCHED_MIN},{PIN_PATCHED_MAX}]")
        ok = False
    review = [s for s in clean + patched if s["verdict"] == "NEEDS_REVIEW"]
    if review:
        print(f"NEEDS_REVIEW: {len(review)} unadjudicated site(s):")
        for s in review:
            print(f"  {s['tree']}/{s['file']}:{s['line']} "
                  f"({s['label']}#{s['occ']})")
        ok = False
    if "--selftest" in sys.argv:
        print("SELFTEST " + ("PASS" if ok else "FAIL") +
              f" (clean={len(clean)} patched={len(patched)})")
        sys.exit(0 if ok else 1)
    for s in clean + patched:
        print(f"{s['tree']:7} {s['file']:14} L{s['line']:<5} "
              f"{','.join(s['pattern']) or '-':16} {s['verdict']:15} "
              f"{s['label']}#{s['occ']}")
    print(f"\nclean={len(clean)} patched={len(patched)} "
          + ("SELFTEST PASS" if ok else "SELFTEST FAIL"))
    if "--json" in sys.argv:
        out = os.path.join(ROOT, "extracted", "mapid_range_audit.json")
        with open(out, "w") as f:
            json.dump({"_generator": "tools/audit_mapid_range.py (S66; "
                       "tree-based, no ROM needed)",
                       "clean_sites": clean, "patched_sites": patched,
                       "ceilings": {
                           "hard_max_mapid": "0xFE ($FF = exit-list "
                               "terminator byte)",
                           "idx8_sub6b_max_mapid": "0xEA (custom-side sub "
                               "$6B then 8-bit add a idiom)",
                           "bgm_room_default_max": "0x7F (bank $71 cp $80 "
                               "guard + 128-entry table + music.py "
                               "validator — compiler-owned extension, see "
                               "ROADMAP A'1 follow-up)"}},
                      f, indent=1)
        print(f"wrote {out}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
