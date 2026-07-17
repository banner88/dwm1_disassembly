#!/usr/bin/env python3
"""
audit_wram.py — WRAM usage mapper for the DWM disassembly + patches.

WHY THIS EXISTS (S54): the Phase-0 "custom WRAM $D378-$D477 unclaimed" claim was
made by grepping for literal address references. That audit method is WRONG for
two access classes the engine uses heavily:

  1. INDEXED ARRAYS  — base + index*stride computed at runtime (e.g. the party/
     storage monster array: GetMonsterDataPtr = $CAC1 + slot*$95, 20 slots,
     spanning $CAC1-$D664 with ZERO literal refs to $D3xx/$D4xx). The custom
     S60 NOTE: this file documents the VANILLA WRAM shape (the selftest
     asserts the vanilla array extent). Post-CF3 (S60), farm slots 3-19 are
     SRAM-resident ($A3BA-$AD9E in the save image) and WRAM $CC80-$D664 is
     free — see MONSTER_DATA "CF3 as built (S60)".
     room state placed at $D378-$D48B sits inside monster slots 14-16 → the
     SkyDragon-egg-give room corruption (S54 root cause).
  2. POINTER-WALKED BUFFERS — a literal base plus a copy/scan loop; interior
     bytes have no literal refs but are used (e.g. library seen-bits $CA94,
     scanned to bit $EF by bank $07 → extent $CA94-$CAB1).

This tool therefore classifies every WRAM byte from FOUR evidence sources:
  A. literal refs in disassembly/*.asm            (vanilla literal use)
  B. curated indexed/walked arrays (evidence-cited, verified against code)
  C. sized spans parsed from documentation/known_RAM_map.md
  D. literal refs + wram-label refs in patches/*.asm (custom-introduced use)

and reports:
  - every custom-introduced address/span and its collision class
  - gaps with NO known use  (reported as "unvetted", NEVER as "free" —
    absence of evidence is not evidence of absence; that is the S54 lesson)
  - the extended-index (class C) findings for new content ids

Outputs: extracted/wram_usage.json + a human-readable stdout report.

Usage:
  python3 tools/audit_wram.py             # full report + write JSON
  python3 tools/audit_wram.py --selftest  # assert the known S54 collision is
                                          # detected (regression for the tool)
"""

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DIS = REPO / "disassembly"
PAT = REPO / "patches"
RAMMAP = REPO / "documentation" / "known_RAM_map.md"
OUT = REPO / "extracted" / "wram_usage.json"

WRAM_LO, WRAM_HI = 0xC000, 0xDFFF

# -----------------------------------------------------------------------------
# Curated indexed / pointer-walked arrays.
# RULES for this table: every entry MUST carry evidence (code label + file, or
# doc section verified against code). Do not add entries from documentation
# alone — documentation has been wrong before (DOC_AUDIT.md).
# -----------------------------------------------------------------------------
INDEXED_ARRAYS = [
    {
        "name": "party/storage monster array",
        "base": 0xCAC1, "stride": 0x95, "count": 20,
        "evidence": "GetMonsterDataPtr (bank_000: HL=HL+(A&$7F)*$95); "
                    "label14_40b4 field writes; slots hold party+farm+eggs "
                    "under one 20-slot limit (user-confirmed S54)",
    },
    {
        "name": "monster staging pseudo-slots $14/$15 (S56)",
        "base": 0xD665, "stride": 0x95, "count": 2,
        "evidence": "GetMonsterDataPtr masks $7F so indices $14/$15 reach "
                    "$D665/$D6FA: breeding parents copied+deleted here "
                    "(bank $0a flows; $16:SaveBrd_41ff reads fields at "
                    "+$0BA4/+$0BA4+$95), link-trade transit ($15:jr_015_5aa5 "
                    "send, $18 receive), bank $15 menu scratch "
                    "($CAC0:=$14/$15 writers). See MONSTER_DATA CF1 section "
                    "+ extracted/monster_walkers.json",
    },
    {
        "name": "library seen-bits",
        "base": 0xCA94, "stride": 1, "count": 30,
        "evidence": "bank_007 jr_007_4251/PushAndReadParty loops: "
                    "TestBitInArray($CA94, b) for b in 0..$EF -> 240 bits "
                    "= 30 bytes $CA94-$CAB1",
    },
    {
        "name": "OAM shadow (DMA source page)",
        "base": 0xC000, "stride": 1, "count": 0xA0,
        "evidence": "standard $FF46 DMA source page; wram.asm reserves "
                    "$C000-$C09F before first label at $C0A0",
    },
    {
        "name": "screen staging block (tile-id shadow + pair)",
        "base": 0xC300, "stride": 1, "count": 0x200,
        "evidence": "S55: bank_006 bulk copy $C500->$C300 length $0200; "
                    "save routine copies $C300 x$200 -> SRAM $BCC8 as a unit "
                    "(bank_000 SavePartyData). Old 256-B extent was too small.",
    },
    {
        "name": "attr decompression staging",
        "base": 0xC200, "stride": 1, "count": 0x100,
        "evidence": "S55: every attr stream declares declen 256 to $C200 "
                    "(bank_017 'ld hl,$c200 / call WaitLCDTransfer' x2 + "
                    "banks $00/$06/$07/$0B; stream header = 2-byte declen); "
                    "save routine copies $C200 x$100 -> SRAM $BEC8.",
    },
    {
        "name": "battle enemy tile buffer / staging source",
        "base": 0xC500, "stride": 1, "count": 0x240,
        "evidence": "known_RAM_map $C500 $240 (LoadBtl_7627, S52 HW); also the "
                    "source of the bank_006 $0200 copy to $C300 (S55).",
    },
    {
        "name": "audio channel state + engine scalars",
        "base": 0xDD80, "stride": 1, "count": 0xAC,
        "evidence": "S55: ClearAudioChannels (bank_000 ~10701) inits 6 "
                    "channels x 26 B from $DD80 (b=$06, stride $19+1); audio "
                    "scalars enumerate to $DE2B. Supersedes the known_RAM_map "
                    "'INFERRED battle struct array' label for this range.",
    },
    {
        "name": "battle stat tables",
        "base": 0xDBA3, "stride": 1, "count": 0x90,
        "evidence": "known_RAM_map / patches wram.asm: 9 tables x 16 B "
                    "($DBA3-$DC32), HW-confirmed S52.",
    },
    {
        "name": "gate floor grid + per-cell state",
        "base": 0xC940, "stride": 1, "count": 0x20,
        "evidence": "GATE_GENERATION.md §4.1/§9 ($C940-$C94F grid, "
                    "$C950-$C95F paired state)",
    },
    {
        "name": "per-screen content state",
        "base": 0xC100, "stride": 1, "count": 0x10,
        "evidence": "GATE_GENERATION.md §9 ($C100-$C10F placement state)",
    },
    {
        "name": "per-screen feature list",
        "base": 0xD793, "stride": 1, "count": 0x25,
        "evidence": "GATE_GENERATION.md §9 ($D793 entries [type,?,x,y]), "
                    "bounded above by documented $D7B8",
    },
]

# Class-C: content-id-indexed vanilla arrays whose index range our patches
# extended. Each entry: which array, vanilla max index, where new ids come from.
EXTENDED_INDEX_CHECKS = [
    {
        "array": "library seen-bits",
        "base": 0xCA94,
        "vanilla_scan_bits": 0xF0,      # bank_007 loops scan 0..$EF
        "vanilla_max_species": 214,
        "new_ids_source": "extracted/new_species.json",
        "note": "SetBitInArray($CA94, species) fires on add-to-storage "
                "(label14_40b4). Bits for new species land inside the "
                "vanilla-scanned extent, so no memory collision, but they "
                "COUNT toward the library completion counters (cp $64 / "
                "100-monster reward checks in bank_007).",
    },
]

ADDR_RE = re.compile(r"\$([cdCD][0-9a-fA-F]{3})\b")
LABEL_DEF_RE = re.compile(r"^(w[A-Za-z0-9_]+)::")
RAMMAP_ROW_RE = re.compile(r"^\s+(?:1:)?([C-F][0-9A-F]{3})\s+(~?\d+)\s+(\S.*)")


def strip_comment(line: str) -> str:
    return line.split(";", 1)[0]


SUSPECT_OPS = re.compile(r"^\s*(call|jp|jr)\b", re.I)


def collect_literals(folder: Path):
    """address -> {'solid': sites, 'suspect': sites}. A ref is SUSPECT when the
    WRAM address is a call/jp/jr operand — in this ROM that pattern comes from
    data regions disassembled as code, not real control flow into WRAM."""
    refs = defaultdict(lambda: {"solid": set(), "suspect": set()})
    for f in sorted(folder.glob("*.asm")):
        for i, line in enumerate(f.read_text(errors="ignore").splitlines(), 1):
            code = strip_comment(line)
            kind = "suspect" if SUSPECT_OPS.match(code) else "solid"
            for m in ADDR_RE.finditer(code):
                a = int(m.group(1), 16)
                if WRAM_LO <= a <= WRAM_HI:
                    refs[a][kind].add(f"{f.name}:{i}")
    return refs


def parse_wram_labels(path: Path):
    """Resolve every label in patches/wram.asm to an address by walking the
    location counter from the section org. Cross-checks against the ';cXXX'
    address comments and refuses to continue on mismatch (parser honesty)."""
    labels = {}
    lc = None
    sizes = []  # (label, addr, size) in file order for span reconstruction
    pending = []  # labels waiting for the next data directive
    ds_expr_re = re.compile(r"^\s*ds\s+(.+?)\s*$")
    for raw in path.read_text().splitlines():
        line = strip_comment(raw).rstrip()
        low = line.strip().lower()
        msec = re.match(r'section\s+".*?",\s*wram[0x]\[\$([0-9a-f]{4})\]', low)
        if msec:
            lc = int(msec.group(1), 16)
            continue
        if lc is None:
            continue
        mlab = LABEL_DEF_RE.match(line.strip())
        if mlab:
            name = mlab.group(1)
            labels[name] = lc
            pending.append(name)
            # check the address comment if present
            mc = re.search(r";\s*([cd][0-9a-f]{3})\b", raw.lower())
            if mc:
                want = int(mc.group(1), 16)
                if want != lc:
                    raise SystemExit(
                        f"wram.asm parse mismatch at {name}: computed "
                        f"${lc:04X}, comment says ${want:04X} — fix parser "
                        f"or file before trusting this audit")
            line = line.strip()[mlab.end():].strip()
            low = line.lower()
            if not line:
                continue
        size = None
        if low.startswith("db"):
            size = 1
        elif low.startswith("dw"):
            size = 2
        else:
            mds = ds_expr_re.match(line)
            if mds:
                expr = mds.group(1)
                expr = re.sub(r"\$([0-9a-fA-F]+)", lambda m: str(int(m.group(1), 16)), expr)
                if not re.fullmatch(r"[0-9+\-*/() ]+", expr):
                    raise SystemExit(f"unsupported ds expression: {mds.group(1)}")
                size = eval(expr)  # arithmetic only, sanitized above
        if size is not None:
            for name in pending:
                sizes.append((name, lc, size))
            pending.clear()
            lc += size
    return labels, sizes


def parse_rammap(path: Path):
    spans = []
    for raw in path.read_text(errors="ignore").splitlines():
        m = RAMMAP_ROW_RE.match(raw)
        if m:
            a = int(m.group(1), 16)
            if not (WRAM_LO <= a <= WRAM_HI):
                continue
            desc = m.group(3).strip()
            # S55: rammap rows that DOCUMENT our own custom state are not
            # vanilla claims — treating them as such makes the custom labels
            # self-collide the moment the map is documented.
            if "CUSTOM ROOM STATE" in desc.upper():
                continue
            size = int(m.group(2).lstrip("~"))
            spans.append({"addr": a, "size": size,
                          "desc": desc,
                          "approx": m.group(2).startswith("~")})
    return spans


def build_coverage(van_lits, rammap_spans):
    """byte -> list of evidence dicts (vanilla only, solid refs)."""
    cov = defaultdict(list)
    for a, kinds in van_lits.items():
        if kinds["solid"]:
            cov[a].append({"kind": "literal", "sites": len(kinds["solid"])})
    for arr in INDEXED_ARRAYS:
        end = arr["base"] + arr["stride"] * arr["count"] \
            if arr["stride"] != 1 else arr["base"] + arr["count"]
        # stride>1 arrays cover the full contiguous span (records are dense)
        end = arr["base"] + (arr["stride"] * arr["count"])
        for a in range(arr["base"], end):
            cov[a].append({"kind": "indexed", "name": arr["name"]})
    for sp in rammap_spans:
        for a in range(sp["addr"], sp["addr"] + sp["size"]):
            if WRAM_LO <= a <= WRAM_HI:
                cov[a].append({"kind": "rammap", "desc": sp["desc"]})
    return cov


def classify_custom(custom_spans, cov):
    findings = []
    for name, addr, size in custom_spans:
        classes, details = set(), []
        for a in range(addr, addr + size):
            for ev in cov.get(a, []):
                if ev["kind"] == "literal":
                    classes.add("A:vanilla-literal")
                elif ev["kind"] == "indexed":
                    classes.add("B:vanilla-indexed")
                    details.append((a, ev["name"]))
                elif ev["kind"] == "rammap":
                    classes.add("A':rammap-span")
        det = sorted({d[1] for d in details})
        findings.append({
            "label": name, "addr": f"${addr:04X}", "size": size,
            "end": f"${addr+size-1:04X}",
            "collision_classes": sorted(classes) or ["clear"],
            "collides_with_indexed": det,
        })  # label_use metadata attached by caller
    return findings


def find_gaps(cov, min_size=16):
    gaps, start = [], None
    for a in range(WRAM_LO, WRAM_HI + 1):
        if a not in cov:
            if start is None:
                start = a
        else:
            if start is not None and a - start >= min_size:
                gaps.append({"addr": f"${start:04X}", "end": f"${a-1:04X}",
                             "size": a - start,
                             "verdict": "no known use (UNVETTED — not 'free')"})
            start = None
    if start is not None and WRAM_HI + 1 - start >= min_size:
        gaps.append({"addr": f"${start:04X}", "end": f"${WRAM_HI:04X}",
                     "size": WRAM_HI + 1 - start,
                     "verdict": "no known use (UNVETTED — not 'free')"})
    return gaps


def class_c_findings():
    out = []
    for chk in EXTENDED_INDEX_CHECKS:
        src = REPO / chk["new_ids_source"]
        ids = []
        if src.exists():
            data = json.loads(src.read_text())
            items = data if isinstance(data, list) else data.get("species", [])
            for x in items:
                v = x.get("species_id", x.get("id"))
                if v is not None:
                    ids.append(int(v))
        finding = dict(chk)
        finding["new_ids"] = sorted(ids)
        if ids:
            worst = max(ids)
            byte = chk["base"] + worst // 8
            inside = worst < chk["vanilla_scan_bits"]
            finding["worst_bit_byte"] = f"${byte:04X}"
            finding["inside_vanilla_scanned_extent"] = inside
            finding["verdict"] = (
                "benign placement (inside scanned extent); affects library "
                "completion counts" if inside else
                "OUT OF EXTENT — memory collision risk, investigate")
        out.append(finding)
    return out


def main():
    selftest = "--selftest" in sys.argv
    van_lits = collect_literals(DIS)
    pat_lits = collect_literals(PAT)
    labels, spans = parse_wram_labels(PAT / "wram.asm")
    rammap_spans = parse_rammap(RAMMAP)
    cov = build_coverage(van_lits, rammap_spans)

    # custom state = every wram.asm label whose address has no vanilla SOLID
    # ref. (Vanilla-naming labels alias vanilla-referenced bytes and drop out;
    # reserved-but-unreferenced custom bytes stay in — they still relocate.)
    van_solid = {a for a, k in van_lits.items() if k["solid"]}
    custom_lit = {a: sorted(k["solid"] | k["suspect"])
                  for a, k in pat_lits.items()
                  if a not in van_solid and k["solid"]}

    label_use = defaultdict(set)
    for f in sorted(PAT.glob("*.asm")):
        if f.name == "wram.asm":
            continue
        text = f.read_text(errors="ignore")
        for name in labels:
            if re.search(rf"\b{re.escape(name)}\b", text):
                label_use[name].add(f.name)
    custom_spans = [(n, a, s) for (n, a, s) in spans if a not in van_solid]
    # drop labels that resolve to pure padding markers
    custom_spans = [(n, a, s) for (n, a, s) in custom_spans
                    if not n.endswith("Start")]

    findings = classify_custom(custom_spans, cov)
    gaps = find_gaps(cov)
    classc = class_c_findings()

    suspect_refs = {f"${a:04X}": sorted(k["suspect"])
                    for a, k in van_lits.items()
                    if k["suspect"] and not k["solid"]}
    rammap_bytes = set()
    for sp in rammap_spans:
        rammap_bytes.update(range(sp["addr"], sp["addr"] + sp["size"]))
    for f in findings:
        f["referenced_by"] = sorted(label_use.get(f["label"], []))
        a0 = int(f["addr"][1:], 16)
        f["vanilla_alias"] = a0 in rammap_bytes  # names a documented engine var

    result = {
        "generated_by": "tools/audit_wram.py",
        "method": ("vanilla literal refs + curated evidence-cited indexed "
                   "arrays + known_RAM_map sized spans; custom = patch-only "
                   "refs and wram.asm labels at vanilla-unreferenced "
                   "addresses. Gaps are UNVETTED, never 'free'."),
        "caveats": [
            "Literal refs from data-heavy banks can be data-disassembled-as-"
            "code artifacts (e.g. 'ld sp,$d38c' in bank_019 gfx). The tool "
            "keeps them: it must over-claim usage, never under-claim.",
            "call/jp/jr operands into WRAM are classed 'suspect' and excluded "
            "from coverage (data-as-code; this ROM runs no code from WRAM).",
            "Curated indexed arrays are the only positive free-space "
            "evidence source; a gap here still needs per-candidate vetting "
            "(pointer-walk loops, SVBK bank-2 windows in bank_051/052) "
            "before anything is placed in it.",
        ],
        "indexed_arrays": [
            {**a, "span": f"${a['base']:04X}-${a['base']+a['stride']*a['count']-1:04X}"}
            for a in INDEXED_ARRAYS],
        "custom_state_findings": findings,
        "custom_literal_only_refs": {f"${a:04X}": v for a, v in sorted(custom_lit.items())},
        "extended_index_findings": classc,
        "unvetted_gaps": gaps,
        "vanilla_suspect_only_refs": suspect_refs,
    }

    if selftest:
        # regression 1: array extent pin (S54)
        arr = next(a for a in INDEXED_ARRAYS if "monster array" in a["name"])
        assert arr["base"] + arr["stride"] * arr["count"] - 1 == 0xD664
        # regression 4 (S56): staging pseudo-slots pinned at $D665-$D78E
        stg = next(a for a in INDEXED_ARRAYS if "staging pseudo-slots" in a["name"])
        assert stg["base"] == 0xD665
        assert stg["base"] + stg["stride"] * stg["count"] - 1 == 0xD78E
        bad = [f for f in findings
               if "B:vanilla-indexed" in f["collision_classes"]
               and any("monster array" in n for n in f["collides_with_indexed"])]
        names = {f["label"] for f in bad}
        # regression 2 (S55): the buffers REMAIN in the array (accepted legacy
        # hazard, exploration overlay only — see patches/wram.asm banner) and
        # MUST still be detected...
        expect_flagged = {"wCustomNPCBuffer", "wCustomExitBuffer"}
        missing = expect_flagged - names
        assert not missing, f"selftest FAILED — collisions not detected: {missing}"
        # ...and the S55-relocated labels MUST be collision-free at $DE74+.
        expect_clean = {"wCustomRoomFlag",
                        "wCustomStep_Room6B_S0", "wCustomStep_Room6B_S1",
                        "wCustomStep_Room6C_S0", "wCustomStep_Room6C_S1",
                        "wCustomStep_Room6C_S5", "wCustomStep_Room6D_S0",
                        "wCustomStep_Room70_S0", "wRoomRecScratch",
                        "wRoomEncFlag", "wTameDelay", "wTameBGSave"}
        wrongly_flagged = expect_clean & {
            f["label"] for f in findings
            if any(c != "clear" for c in f["collision_classes"])}
        assert not wrongly_flagged, (
            f"selftest FAILED — relocated labels still collide: {wrongly_flagged}")
        # regression 3 (S55): the relocated block must sit inside the vetted
        # window $DE74-$DEDD, past the audio ceiling $DE2B.
        audio = next(a for a in INDEXED_ARRAYS if "audio channel" in a["name"])
        assert audio["base"] + audio["count"] - 1 == 0xDE2B
        print("SELFTEST PASS: array extent $CAC1-$D664 (+staging to $D78E); "
              "buffers still flagged "
              "class B (accepted legacy); relocated labels clean; audio "
              "ceiling $DE2B pinned below the $DE74 block.")
        return

    OUT.write_text(json.dumps(result, indent=1))
    print(f"wrote {OUT.relative_to(REPO)}")
    print("\n=== CUSTOM STATE COLLISIONS ===")
    for f in findings:
        flag = "!!" if any(c.startswith("B") for c in f["collision_classes"]) else "  "
        print(f"{flag} {f['label']:26} {f['addr']}-{f['end']}  "
              f"{','.join(f['collision_classes'])}"
              + (f"  <- {', '.join(f['collides_with_indexed'])}"
                 if f["collides_with_indexed"] else ""))
    if custom_lit:
        print("\n=== PATCH-ONLY LITERAL REFS (unlabeled custom usage?) ===")
        for a, sites in sorted(custom_lit.items()):
            print(f"   ${a:04X}  {len(sites)} site(s)  e.g. {sites[0]}")
    print("\n=== EXTENDED-INDEX (class C) ===")
    for c in classc:
        print(f"   {c['array']}: new ids {c['new_ids']} -> {c.get('verdict','n/a')}")
    print(f"\n=== UNVETTED GAPS (>=16B, no known use — NOT 'free') ===")
    for g in gaps:
        print(f"   {g['addr']}-{g['end']}  {g['size']:4} bytes")


if __name__ == "__main__":
    main()
