#!/usr/bin/env python3
"""
build_library_table.py — B7: production monster-library family grouping.

REPLACES the Session-18 dynamic-library PROOF OF CONCEPT
(`tools/build_dynamic_library.py`, runtime per-species far-load scan). Instead
of grouping the encyclopedia at RUNTIME (cheap to write, but ~221 cross-bank
far-loads per tab press → visible lag + a scratch RAM byte), this emits a
PRECOMPUTED family->members table into bank $12 free space at BUILD time and a
tiny walker that reads it directly. Zero runtime RAM, zero far-loads; as cheap as
vanilla's id-range scan.

WHY THIS IS CORRECT (all ROM-verified, see BREEDING_SYSTEM.md "Three family
representations" + DATA: this file's self-test):
  * Vanilla library groups by a HARD-CODED id-RANGE table `LibraryFamilyTabBounds`
    at $12:$6294 = [0,20,45,70,90,110,130,155,175,200,215]. It assumes each family
    is a CONTIGUOUS species-id block — true in vanilla, false the moment monsters
    are reassigned (B6) or an 11th family is inserted (B9). This is the ONLY
    id-range family assumption in the whole ROM (S18 audit).
  * The family byte ($03:$4461 +$00, raw 0..9) is the single source of truth.
    Grouping the COLLECTIBLE set (ids 0..214) by that byte reproduces the vanilla
    bounds table EXACTLY (proven in --selftest: contiguity holds for 0..214).
  * So this tool's DEFAULT (no reassignment) emits a table behaviorally identical
    to vanilla; applying `breeding_family_reassign.json` (the SAME spec B6 feeds to
    bank_003) regroups exactly the reassigned monsters — keeping bank_003's family
    bytes and bank_012's library in lock-step.

COLLECTIBLE vs SPECIAL (user-confirmed, do not re-derive from "looks empty"):
  Ids 0..214 are the COLLECTIBLE monsters shown in the encyclopedia.
  Ids 215..220 are REAL but NON-collectible combat-only entities and are PROTECTED
  (never listed, never overwritten, never a reassignment target):
     215 TERRY?   — scripted story enemy (Durran fight); fightable, not recruitable
     216 Tatsu    — summon-skill product (tier 1)
     217 Diago    — summon-skill product
     218 Samsi    — summon-skill product
     219 Bazoo    — summon-skill product
     220 (blank)  — reserved/unknown; left strictly untouched
  Vanilla hides them precisely because the library is the *collection* register,
  not a bestiary. Their stats read empty (lvl cap 0, Blaze x3) only because they
  need no recruit/breed/growth data.

EXTENSION-AWARE (B9 / future, see ROADMAP):
  Nothing here hardcodes 221. Species ids are 1 byte → the design ceiling is 256
  species (ids 0..255); COLLECTIBLE_MAX is the single knob to raise. The family
  COUNT is data (NUM_FAMILIES, default 10): adding an 11th family is purely
  additive — one more pointer + one more list; the walker indexes by family with
  no ==10 assumption. The 2x5 tab-grid -> flat-index formula in the walker is the
  ONLY 10-bound, and it is the menu/UI's concern (owned by B9 when the grid grows),
  not the data path. See "EXTENSION TO 255 / 11th family" notes inline.

ZERO-SHIFT: `SetItem_6242` keeps its address; its 82-byte body is replaced in
place with `jp LibScanByFamily` + NOP pad. `LibScanByFamily` + the table live in
bank $12 trailing free space ($7B9B.., 1125 B, verified unreferenced S18). Bank
$12 stays exactly $4000 bytes. Clean disassembly untouched; writes
patches/bank_012.asm + extracted/library_grouping.json.

Usage:
  python3 tools/build_library_table.py --emit            # vanilla grouping (parity)
  python3 tools/build_library_table.py --emit --reassign extracted/breeding_family_reassign.json
  python3 tools/build_library_table.py --selftest        # prove vanilla-parity
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_PATH = os.path.join(REPO, "data", "DWM-original.gbc")
DIS = os.path.join(REPO, "disassembly", "bank_012.asm")
OUT = os.path.join(REPO, "patches", "bank_012.asm")
GROUPING_JSON = os.path.join(REPO, "extracted", "library_grouping.json")
NEW_SPECIES_JSON = os.path.join(REPO, "extracted", "new_species.json")
ORIGINAL_MD5 = "1ca6579359f21d8e27b446f865bf6b83"

# --- ROM-verified constants (grep/byte-checked, not doc-trusted) ---
MONSTER_INFO_BASE = 0x4461       # $03:$4461, 221 x 43 B; +$00 = family byte (raw 0..9)
MONSTER_INFO_BANK = 0x03
ENTRY_SIZE = 43                  # $2B
VANILLA_BOUNDS = [0, 20, 45, 70, 90, 110, 130, 155, 175, 200, 215]  # $12:$6294

# --- design knobs (the ONLY things to touch for extension to 255 / 11 families) ---
COLLECTIBLE_MAX = 214            # last collectible species id; library lists ids 0..214.
                                 # EXTENSION: raise toward 255 when new collectible
                                 # monsters are added (species id is 1 byte → max 255).
FIRST_FREE_ID = 224             # first NEW-species id ($E0); new_species.json ids start here.
# Library "unseen" sentinel: written into a family slot whose member is not yet discovered,
# so the encyclopedia renders it blank. Vanilla used $E0 (224) — safe only while 224 was an
# empty slot. Phase N puts a REAL species at $E0 (Gorbunok), so $E0-as-"unseen" would
# collide (undiscovered slots would show Gorbunok). The marker is moved to $FE (254): above
# every new-species id (224..253 budget) and pointed at a blank name in bank $41 (MonsterName
# id 254 -> $F0-only blank). $FF stays the buffer-fill blank. If new species ever reach 254,
# raise this AND re-point that name slot.
UNSEEN_MARKER = 0xFE
SPECIES_ID_MAX = 255             # 1-byte species-id ceiling (hard architectural limit)
NUM_FAMILIES = 11                # emitted tab count. B9: 11th family (Spirit) added.
GRID_ROWS = 5                    # library tab grid rows (`ld b,$05`); cols = cells/rows.
GRID_BOUND_SITES = 2             # number of `ld c,$0a` tab-cell-count sites in bank $12
                                 # (both the nav setup and the redraw path). Audited S20.
BUFFER_CAPACITY = 32             # display buffer $C0D8 size ($20). A family must fit.
                                 # (user guarantee: no family exceeds 30.)

# Protected non-collectible entities (never listed, never a reassignment target).
SPECIAL_ENTRIES = {
    215: "TERRY? (story enemy, Durran fight)",
    216: "Tatsu (summon tier)",
    217: "Diago (summon tier)",
    218: "Samsi (summon tier)",
    219: "Bazoo (summon tier)",
    220: "(reserved/blank)",
}

FREE_SPACE_ADDR = 0x7B9B         # trailing free run start (verified)
ROUTINE_LABEL = "SetItem_6242:"

# Original SetItem_6242 body, used only to measure its assembled length so the
# in-place `jp + nop` replacement is exactly zero-shift.
ORIGINAL_BODY_SRC = """\
SECTION "fixture", ROM0[$0]
SetItem_6242:
    ld hl, $c0d8
    ld bc, $0020
    ld a, $ff
    call $1234
    ld a, [$c8db]
    ld b, a
    add a
    add a
    add b
    ld b, a
    ld a, [$c8da]
    and $7f
    add b
    ld [$cac0], a
    ld hl, $6294
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld c, [hl]
    ld b, a
    ld d, $00
    ld e, $00
    ld hl, $c0d8
.scan:
    push bc
    push de
    push hl
    ld hl, $ca94
    ld a, b
    call $1234
    pop hl
    pop de
    pop bc
    ld [hl], $e0
    jr z, .skip
    ld [hl], b
    inc e
.skip:
    inc d
    inc hl
    inc b
    ld a, b
    cp c
    jr nz, .scan
    ld a, d
    ld [$c8e9], a
    ld a, e
    ld [$c8e8], a
    ret
.END:
"""


def read_rom():
    with open(ROM_PATH, "rb") as f:
        return f.read()


def vanilla_families(rom):
    """family byte for every collectible species id 0..COLLECTIBLE_MAX (raw 0..9)."""
    base = MONSTER_INFO_BANK * 0x4000 + (MONSTER_INFO_BASE - 0x4000)
    return {i: rom[base + i * ENTRY_SIZE + 0] for i in range(COLLECTIBLE_MAX + 1)}


def load_reassign(path):
    if not path:
        return []
    with open(path) as f:
        return json.load(f).get("reassignments", [])


def load_new_species(path):
    """NEW species (ids >= FIRST_FREE_ID) authored in new_species.json -> {id: family}.

    New species are NOT in the ROM info table, so their library family is read from
    the authored info entry's effective family byte: the cloned base species' family
    byte (vanilla ROM) with any `info.overrides.family` applied. This keeps the
    library grouping tool-owned and reproducible (the prior hand-edit of $e0 into
    LibFamily_00 was the defect this fixes)."""
    if not path or not os.path.exists(path):
        return {}
    with open(path) as f:
        spec = json.load(f)
    rom = read_rom()
    base = MONSTER_INFO_BANK * 0x4000 + (MONSTER_INFO_BASE - 0x4000)
    out = {}
    for sp in spec.get("species", []):
        sid = sp["id"]
        if sid < FIRST_FREE_ID:
            sys.exit(f"ERROR: new_species id {sid} < FIRST_FREE_ID {FIRST_FREE_ID} "
                     f"(would collide with vanilla/special slots).")
        if sid > SPECIES_ID_MAX:
            sys.exit(f"ERROR: new_species id {sid} > {SPECIES_ID_MAX} (1-byte ceiling).")
        if sid == UNSEEN_MARKER:
            sys.exit(f"ERROR: new_species id {sid} == UNSEEN_MARKER ${UNSEEN_MARKER:02X} "
                     f"(library sentinel collision — raise UNSEEN_MARKER first).")
        info = sp.get("info", {})
        cf = info.get("clone_from_species")
        fam = rom[base + cf * ENTRY_SIZE + 0] if cf is not None else None
        fam = info.get("overrides", {}).get("family", fam)
        if fam is None:
            sys.exit(f"ERROR: new_species id {sid} has no family "
                     f"(needs info.clone_from_species or info.overrides.family).")
        out[sid] = fam
    return out


def effective_families(rom, reassign_path, new_species_path=None):
    """vanilla family bytes + reassignment overrides + NEW species (validated)."""
    fam = vanilla_families(rom)
    for r in load_reassign(reassign_path):
        i = r["id"]
        if i in SPECIAL_ENTRIES:
            sys.exit(f"ERROR: reassignment targets PROTECTED special entry id {i} "
                     f"({SPECIAL_ENTRIES[i]}). Refusing — would corrupt non-collectible data.")
        if i > COLLECTIBLE_MAX:
            sys.exit(f"ERROR: reassignment id {i} is past COLLECTIBLE_MAX {COLLECTIBLE_MAX}.")
        if "from" in r and fam[i] != r["from"]:
            sys.exit(f"ERROR: reassignment id {i} 'from'={r['from']} != vanilla "
                     f"family {fam[i]} (spec drift vs ROM).")
        fam[i] = r["to"]
    for sid, f in load_new_species(new_species_path).items():
        if sid in SPECIAL_ENTRIES:
            sys.exit(f"ERROR: new_species id {sid} collides with PROTECTED entry.")
        fam[sid] = f                  # ids >= 224, added on top of the 0..214 set
    return fam


def group(fam):
    """family index -> ordered list of collectible species ids (species-id order)."""
    g = {f: [] for f in range(NUM_FAMILIES)}
    extra = {}
    for i in sorted(fam):
        f = fam[i]
        if f < NUM_FAMILIES:
            g[f].append(i)
        else:
            extra.setdefault(f, []).append(i)  # family >= NUM_FAMILIES (needs B9 UI)
    return g, extra


def validate(g, extra):
    for f, members in g.items():
        if len(members) > BUFFER_CAPACITY:
            sys.exit(f"ERROR: family {f} has {len(members)} members > buffer "
                     f"capacity {BUFFER_CAPACITY}. Library buffer $C0D8 would overflow.")
        for m in members:
            if m > SPECIES_ID_MAX:
                sys.exit(f"ERROR: species id {m} > {SPECIES_ID_MAX} (1-byte ceiling).")
    if extra:
        print(f"  WARNING: families {sorted(extra)} >= NUM_FAMILIES={NUM_FAMILIES} have "
              f"members {extra}. Data is emitted, but navigating tabs beyond "
              f"{NUM_FAMILIES} needs the B9 tab-grid UI. Raise NUM_FAMILIES for B9.")


def selftest(rom):
    """Prove: grouping collectibles by family byte (no reassign) == vanilla bounds."""
    fam = vanilla_families(rom)
    g, extra = group(fam)
    ok = True
    for f in range(10):
        lo, hi = VANILLA_BOUNDS[f], VANILLA_BOUNDS[f + 1]
        expected = list(range(lo, hi))
        if g[f] != expected:
            ok = False
            print(f"  family {f}: MISMATCH got {g[f][:3]}..{g[f][-3:]} expected {lo}..{hi-1}")
    assert not extra, f"unexpected families beyond 9: {extra}"
    if ok:
        print("SELFTEST PASS: vanilla family-byte grouping reproduces the id-range "
              "bounds table exactly for ids 0..214 (library is behavior-identical to "
              "vanilla when no reassignment is applied).")
    else:
        sys.exit("SELFTEST FAIL")
    return ok


# ----------------------------------------------------------------------------
# The walker. Reads the precomputed table; no far-loads, no scratch RAM.
# ----------------------------------------------------------------------------
WALKER = f"""
; =============================================================================
; LibScanByFamily — B7 PRODUCTION monster-library tab populate.
; Replaces vanilla's id-range scan over LibraryFamilyTabBounds ($12:$6294) with a
; precomputed family->members table (LibFamilyPtrTable below), so the encyclopedia
; honours the family byte ($03:$4461+$00) — reassignments (B6) regroup correctly.
;
; In : flat family index F = wOPTN_and_Item_selection*5 + (wMenu_selection & $7F)
;        (the 2x5 tab grid -> 0..9). This formula is the ONLY 10-bound here; it is
;        the tab-GRID mapping and changes with the B9 11th-family UI, not the data.
; Out: $C0D8.. buffer = one slot per family member (${UNSEEN_MARKER:02X} if unseen, species id if
;        seen — vanilla semantics: undiscovered monsters keep their blank slot).
;      $C8E9 = total slots (= member count), $C8E8 = seen count.
; Cost: one table walk, ROM0 helpers only. Zero far-loads, zero scratch RAM.
; Capacity: emitter guarantees every family <= BUFFER_CAPACITY (32), so no
;        buffer overflow check is needed at runtime.
; =============================================================================
LibScanByFamily:
    ld hl, $c0d8                       ; blank the display buffer ($20 slots) to $FF
    ld bc, $0020
    ld a, $ff
    call FillNBytesWithRegA

    ld a, [wOPTN_and_Item_selection]   ; tab column (0..1)
    ld b, a
    add a
    add a
    add b                              ; A = column*5
    ld b, a
    ld a, [wMenu_selection]
    and $7f                            ; tab row (0..4)
    add b                              ; A = flat family index F (0..NUM_FAMILIES-1)
    ld [$cac0], a                      ; preserve original $cac0 semantics

    add a                              ; F*2 (pointer table stride)
    ld e, a
    ld d, $00
    ld hl, LibFamilyPtrTable
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a                            ; HL -> this family's list: db count, ids...

    ld a, [hl+]                        ; A = member count
    ld [$c8e9], a                      ; total slots written = member count
    ld c, a                            ; C = remaining members
    ld b, $00                          ; B = seen count
    or a
    jr z, .done                        ; empty family -> buffer stays blank

    ld d, h
    ld e, l                            ; DE = source (member-id list)
    ld hl, $c0d8                       ; HL = dest buffer ptr
.loop:
    ld a, [de]                         ; A = species id (current member)
    push hl                            ; save dest (TestBitInArray clobbers HL)
    ld hl, $ca94                       ; seen-bit array base
    call TestBitInArray                ; in A=species id; Z=unseen; preserves B,C,DE
    pop hl
    jr z, .unseen
    ld a, [de]                         ; re-read species id (A clobbered)
    ld [hl], a                         ; seen -> write species id
    inc b                              ; seen count++
    jr .next
.unseen:
    ld [hl], ${UNSEEN_MARKER:02x}                       ; unseen -> blank marker (id ${UNSEEN_MARKER:02X}, blank name; NOT $E0 — that's Gorbunok now)
.next:
    inc hl
    inc de
    dec c
    jr nz, .loop
.done:
    ld a, b
    ld [$c8e8], a                      ; seen count
    ret
"""


def emit_table_asm(g):
    """Pointer table + length-prefixed member lists. Additive for an 11th family."""
    lines = []
    lines.append("")
    lines.append("; -----------------------------------------------------------------------------")
    lines.append("; LibFamilyPtrTable — B7 precomputed family->members grouping (build-time).")
    lines.append(f"; {NUM_FAMILIES} entries (one per family tab); each -> [db count, species ids...].")
    lines.append("; EXTENSION (B9 11th family): append one more `dw` here + one more list below;")
    lines.append("; the walker is family-count-agnostic. Species ids are 1 byte (<=255).")
    lines.append("; Regenerated by tools/build_library_table.py from the family byte +")
    lines.append("; breeding_family_reassign.json (same source as bank_003 / B6).")
    lines.append("; -----------------------------------------------------------------------------")
    lines.append("LibFamilyPtrTable:")
    for f in range(NUM_FAMILIES):
        lines.append(f"    dw LibFamily_{f:02d}")
    # B9: the nav grid rounds up to whole columns (GRID_ROWS), so it can reach cells
    # beyond NUM_FAMILIES (e.g. 11 families -> 15 nav cells). Pad the pointer table to
    # the full nav cell count so the walker never reads past it; spare cells point to a
    # shared empty list (0 members) → blank, crash-safe tab.
    import math as _math
    nav_cells = GRID_ROWS * _math.ceil(NUM_FAMILIES / GRID_ROWS) if NUM_FAMILIES > 10 else NUM_FAMILIES
    for _ in range(NUM_FAMILIES, nav_cells):
        lines.append("    dw LibFamilyEmpty")
    lines.append("")
    for f in range(NUM_FAMILIES):
        members = g[f]
        lines.append(f"LibFamily_{f:02d}:  ; {len(members)} members")
        if members:
            ids = ", ".join(f"${m:02x}" for m in members)
            lines.append(f"    db {len(members)}, {ids}")
        else:
            lines.append("    db 0")
    if nav_cells > NUM_FAMILIES:
        lines.append("LibFamilyEmpty:  ; spare nav cells (>= NUM_FAMILIES) — blank, crash-safe")
        lines.append("    db 0")
    return "\n".join(lines) + "\n"


def assemble_len(src, a_lbl, b_lbl):
    with tempfile.TemporaryDirectory() as td:
        asm = os.path.join(td, "f.asm")
        obj = os.path.join(td, "f.o")
        gbc = os.path.join(td, "f.gbc")
        sym = os.path.join(td, "f.sym")
        open(asm, "w").write(src)
        r = subprocess.run(["rgbasm", "-o", obj, asm], capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit("fixture asm failed:\n" + r.stderr)
        r = subprocess.run(["rgblink", "-n", sym, "-o", gbc, obj], capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit("fixture link failed:\n" + r.stderr)
        ad = {}
        for line in open(sym):
            line = line.strip()
            if not line or line.startswith(";"):
                continue
            p = line.split()
            if len(p) == 2:
                ad[p[1]] = int(p[0].split(":")[1], 16)
        return ad[b_lbl] - ad[a_lbl]


def content_len(g):
    """Assembled byte length of WALKER + table (with stubbed externals)."""
    stub = (
        'SECTION "fix", ROM0[$0]\n'
        'FillNBytesWithRegA: ret\nTestBitInArray: ret\n'
        'wOPTN_and_Item_selection EQU $c8db\nwMenu_selection EQU $c8da\n'
        "CONTENT_START:\n" + WALKER + emit_table_asm(g) + "\nCONTENT_END:\n"
    )
    return assemble_len(stub, "CONTENT_START", "CONTENT_END")


def find_routine(lines):
    start = next(i for i, l in enumerate(lines) if l.strip() == ROUTINE_LABEL.strip())
    for i in range(start, len(lines)):
        if lines[i].strip() == "ret":
            return start, i
    sys.exit("ERROR: could not find end of SetItem_6242")


def emit(reassign_path, new_species_path=None):
    rom = read_rom()
    import hashlib
    if hashlib.md5(rom).hexdigest() != ORIGINAL_MD5:
        sys.exit("ERROR: data/DWM-original.gbc is not the canonical ROM.")

    fam = effective_families(rom, reassign_path, new_species_path)
    g, extra = group(fam)
    validate(g, extra)

    # --- build the patched bank_012 from the CLEAN disassembly ---
    src = open(DIS).read()
    lines = src.splitlines(keepends=True)
    start, end = find_routine(lines)

    body_len = assemble_len(ORIGINAL_BODY_SRC, "SetItem_6242", "SetItem_6242.END")
    pad = body_len - 3                       # jp = 3 bytes
    if pad < 0:
        sys.exit("ERROR: jp longer than original body")
    replacement = ["SetItem_6242:\n", "    jp LibScanByFamily\n"] + ["    nop\n"] * pad
    new_lines = lines[:start] + replacement + lines[end + 1:]
    text = "".join(new_lines)

    # consume the trailing nop free-run, splice in WALKER + table, re-pad to size.
    nl = text.splitlines(keepends=True)
    i = len(nl) - 1
    while i >= 0 and nl[i].strip() == "nop":
        i -= 1
    nnops = len(nl) - 1 - i
    clen = content_len(g)
    if clen > nnops:
        sys.exit(f"ERROR: content {clen} B exceeds trailing free {nnops} B")
    keep_nops = nnops - clen
    head = nl[: i + 1]
    body = WALKER + emit_table_asm(g)
    final = "".join(head) + body + "\n" + "".join(["    nop\n"] * keep_nops)

    # header: rewrite the POC banner to the production banner.
    final = _rewrite_header(final, reassign_path, g)

    # --- B9: extend the tab-strip NAV GRID so the cursor can reach tab 10 (Spirit) ---
    # The grid is `ld b,$05` (rows) + `ld c,$0a` (cells = 2 cols x 5). Flat index =
    # column*5 + row. For 11 families we set the cell bound to NUM_FAMILIES itself
    # (11 -> $0b), NOT the rounded-up 15. This matters: LoadItem_4241's partial-last-
    # column clamp computes `cells / rows` = 2 rem 1, so the 3rd column has exactly 1
    # valid cell (Spirit, row 0) and the cursor CANNOT scroll down into the empty
    # cells 11..14. (Vanilla never hit that clamp since 10 = 2x5, remainder 0.)
    # The LibFamilyPtrTable is still padded to the rounded-up cell count (15) as a
    # draw-time safety belt, but those cells are now unreachable.
    if NUM_FAMILIES > 10:
        cells = NUM_FAMILIES                                  # 11 -> $0b (clamped grid)
        old = "    ld c, $0a\n"
        new = f"    ld c, ${cells:02x}\n"
        n = final.count(old)
        if n != GRID_BOUND_SITES:
            sys.exit(f"ERROR: expected {GRID_BOUND_SITES} `ld c,$0a` tab-grid sites, "
                     f"found {n}. Library nav layout changed — re-audit before B9.")
        final = final.replace(old, new)
        print(f"  B9 nav grid: {n} sites `ld c,$0a` -> `ld c,${cells:02x}` "
              f"(3rd column has {cells % GRID_ROWS or GRID_ROWS} cell(s); cursor clamps at Spirit).")

    # --- Unseen-marker comparison sites (only when the marker moved off $E0) ---
    # The walker writes UNSEEN_MARKER into undiscovered library slots; two routines
    # READ a slot and compare it against the marker (one to skip-select a blank slot
    # -> Jump_012_639d, one a blank-test that returns Z). Vanilla compares `cp $e0`.
    # When a new species occupies $E0 (Gorbunok), the marker is $FE, so these two
    # reads must compare `cp $FE` too — otherwise a blank slot ($FE) is mistaken for a
    # real monster, or the real $E0 monster is mistaken for blank. Both sites are read
    # from the $C0D8 buffer (`ld a, [hl]` immediately precedes the `cp`); matched on
    # their full unique context so the other ~47 `cp $e0` sites in the bank are
    # untouched. Count-validated: exactly 2 expected.
    if UNSEEN_MARKER != 0xE0:
        cmp_sites = [
            ("    ld a, [hl]\n    ld [$cac0], a\n    cp $e0\n    jp z, Jump_012_639d\n",
             f"    ld a, [hl]\n    ld [$cac0], a\n    cp ${UNSEEN_MARKER:02x}"
             f"   ; unseen-marker test (moved off $E0 = Gorbunok)\n    jp z, Jump_012_639d\n"),
            ("    ld a, [hl]\n    cp $e0\n    ret\n",
             f"    ld a, [hl]\n    cp ${UNSEEN_MARKER:02x}"
             f"   ; unseen-marker test (moved off $E0 = Gorbunok)\n    ret\n"),
        ]
        for old_ctx, new_ctx in cmp_sites:
            c = final.count(old_ctx)
            if c != 1:
                sys.exit(f"ERROR: unseen-marker compare site matched {c}x (expected 1). "
                         f"bank_012 layout changed — re-audit before moving the marker.\n"
                         f"  context: {old_ctx!r}")
            final = final.replace(old_ctx, new_ctx)
        print(f"  unseen marker: 2 compare sites `cp $e0` -> `cp ${UNSEEN_MARKER:02x}` "
              f"(walker + reads consistent; $E0 freed for new species).")

    open(OUT, "w").write(final)

    # --- data deliverable ---
    grouping = {
        "_generator": f"tools/build_library_table.py; ROM {ORIGINAL_MD5}"
                      + (f"; reassign {os.path.basename(reassign_path)}" if reassign_path else "; vanilla (no reassign)")
                      + (f"; new_species {os.path.basename(new_species_path)}" if new_species_path else ""),
        "_note": "B7 production library family->members grouping. Collectible set ids "
                 "0..%d grouped by effective family byte (vanilla + reassignment). "
                 "Special non-collectible entries 215..220 are PROTECTED and excluded."
                 % COLLECTIBLE_MAX,
        "num_families": NUM_FAMILIES,
        "buffer_capacity": BUFFER_CAPACITY,
        "collectible_max": COLLECTIBLE_MAX,
        "species_id_max": SPECIES_ID_MAX,
        "special_entries": {str(k): v for k, v in SPECIAL_ENTRIES.items()},
        "families": {str(f): g[f] for f in range(NUM_FAMILIES)},
    }
    if extra:
        grouping["families_beyond_num_families"] = {str(k): v for k, v in extra.items()}
    with open(GROUPING_JSON, "w") as f:
        json.dump(grouping, f, indent=2)

    print(f"Wrote {OUT}")
    print(f"  original body {body_len} B -> jp + {pad} nop (zero-shift)")
    print(f"  content (walker+table) {clen} B in trailing free ({nnops} B avail), "
          f"{keep_nops} nop pad kept (bank stays $4000)")
    print(f"  families: " + ", ".join(f"{f}:{len(g[f])}" for f in range(NUM_FAMILIES)))
    print(f"Wrote {GROUPING_JSON}")


def _rewrite_header(text, reassign_path, g):
    banner = (
        "; ============================================================================\n"
        "; B7 PRODUCTION — monster-library family grouping (replaces S18 POC).\n"
        "; ----------------------------------------------------------------------------\n"
        "; SetItem_6242 (library tab populate, originally an id-RANGE scan over\n"
        "; LibraryFamilyTabBounds $6294) is redirected zero-shift to LibScanByFamily in\n"
        "; trailing free space, which reads a PRECOMPUTED family->members table\n"
        "; (LibFamilyPtrTable). Grouping honours the family byte, so B6 reassignments\n"
        "; regroup correctly with NO runtime far-loads and NO scratch RAM (unlike the\n"
        "; POC). Vanilla parity proven by build_library_table.py --selftest.\n"
        "; Generated by tools/build_library_table.py "
        + ("(--emit --reassign %s).\n" % os.path.basename(reassign_path) if reassign_path
           else "(--emit, vanilla grouping).\n")
        + "; EXTENSION: COLLECTIBLE_MAX (->255) and NUM_FAMILIES (->11, B9) are the only\n"
        "; knobs; the table format + walker are already count/id agnostic.\n"
        "; ============================================================================\n"
    )
    # Replace the original mgbdis 5-line header banner region up to the first blank
    # line after the POC/section banner, then keep the section directive intact.
    # Simplest robust approach: prepend our banner after the first 5 comment lines.
    lines = text.splitlines(keepends=True)
    # drop any existing leading ';'-comment block, keep from first non-comment line
    j = 0
    while j < len(lines) and (lines[j].lstrip().startswith(";") or lines[j].strip() == ""):
        j += 1
    return banner + "\n" + "".join(lines[j:])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit", action="store_true")
    ap.add_argument("--reassign", default=None,
                    help="path to breeding_family_reassign.json (applies B6 overrides)")
    ap.add_argument("--new-species", default=None,
                    help="path to new_species.json (adds Phase N species ids >= 224 to "
                         "their family group, so the library lists them reproducibly)")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        selftest(read_rom())
    if a.emit:
        emit(a.reassign, a.new_species)
    if not (a.emit or a.selftest):
        ap.print_help()


if __name__ == "__main__":
    main()
