#!/usr/bin/env python3
"""build_new_species.py — Phase N (add NEW monster species, ids >= 224).

Stage 1 (this tool, current scope):
  * Reads extracted/new_species.json + the original ROM.
  * Builds each new species' 43-byte monster-info entry by cloning a base
    species and applying field overrides (e.g. family).
  * EMITS patches/bank_06a.asm: the free-bank "new species data" bank holding
      - $4000: bank self-id ($6A)
      - $4001: rst-$10 entry table (entry 0 -> NewSpeciesInfoCopy)
      - NewSpeciesInfoCopy: far-copy routine (id>=224 -> (id-224)*43 + table)
      - NewSpeciesHighInfoTable: 32 slots x 43 bytes (ids 224..255)
  * VALIDATES a byte-exact round-trip: re-decodes the emitted high table and
    asserts each populated slot equals the authored bytes; asserts the base
    clone equals the vanilla ROM entry before overrides.

The bank_003 loader fork (zero-shift) that reaches this bank for id>=224 is a
hand-applied patch in patches/bank_003.asm (see that file's N2 comment block);
this tool only owns the GENERATED bank_06a.asm + the authored data.

Enemy-stats placement, encounter-pool edits, name and battle gfx/palette are
applied in their owning banks (see APPLY notes); their authored values live in
new_species.json so this file stays the single source of truth.

Usage:
    python3 tools/build_new_species.py            # emit bank_06a.asm + validate
    python3 tools/build_new_species.py --check     # validate only (no write)
    python3 tools/build_new_species.py --dump-json  # print decoded high table
"""
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_PATH = os.path.join(REPO, "data", "DWM-original.gbc")
SPEC_PATH = os.path.join(REPO, "extracted", "new_species.json")
OUT_PATH = os.path.join(REPO, "patches", "bank_06a.asm")
DIS_BANK14 = os.path.join(REPO, "disassembly", "bank_014.asm")
OUT_BANK14 = os.path.join(REPO, "patches", "bank_014.asm")

BANK_SIZE = 0x4000
FIRST_FREE_ID = 224
ID_BUDGET = 32                      # ids 224..255
INFO_BANK = 0x03
INFO_TABLE = 0x4461                 # MonsterInfoTable
INFO_SIZE = 43

# Enemy-stats table (bank $14). LoadEnemyStats has no EID ceiling and computes
# EID*25 + $4C1D, so a new entry placed in bank $14's trailing free space at the
# address its EID computes is read with NO code fork. The trailing free run is
# exactly $7EAD..$7FFF (339 bytes of $00).
ESTATS_BANK = 0x14
ESTATS_TABLE = 0x4C1D
ESTATS_SIZE = 25
ESTATS_FREE_START = 0x7EAD
ESTATS_FREE_LEN = 339
ESTATS_FIELDS = {"monster_id": (0x00, 1), "level": (0x04, 1), "joinability": (0x03, 1)}
HIGH_BANK = 0x6A

# Field name -> (offset, size) within the 43-byte info entry (subset we author).
INFO_FIELDS = {
    "family": (0x00, 1),
    "level_cap": (0x01, 1),
    "exp_table": (0x02, 1),
    "female_ratio": (0x03, 1),
    "can_fly": (0x04, 1),
    "metal_body": (0x05, 1),
    "tier": (0x2A, 1),
}


def flat(bank, local):
    return bank * BANK_SIZE + (local - 0x4000 if bank else local)


def read_rom():
    with open(ROM_PATH, "rb") as f:
        return f.read()


def info_entry(rom, species):
    o = flat(INFO_BANK, INFO_TABLE) + species * INFO_SIZE
    return bytearray(rom[o:o + INFO_SIZE])


def build_info(rom, spec_entry):
    info = spec_entry["info"]
    base = info["clone_from_species"]
    entry = info_entry(rom, base)
    assert len(entry) == INFO_SIZE
    for field, val in info.get("overrides", {}).items():
        if field not in INFO_FIELDS:
            raise SystemExit(f"unknown info override field: {field}")
        off, size = INFO_FIELDS[field]
        assert size == 1, "only single-byte overrides supported"
        entry[off] = val & 0xFF
    return base, entry


def assemble_high_table(rom, spec):
    """Return {slot_index(0..31): (species_id, 43-byte authored entry)}."""
    slots = {}
    for e in spec["species"]:
        sid = e["id"]
        if not (FIRST_FREE_ID <= sid <= FIRST_FREE_ID + ID_BUDGET - 1):
            raise SystemExit(f"id {sid} out of new-species range "
                             f"{FIRST_FREE_ID}..{FIRST_FREE_ID + ID_BUDGET - 1}")
        idx = sid - FIRST_FREE_ID
        base, entry = build_info(rom, e)
        slots[idx] = (sid, base, bytes(entry))
    return slots


def estats_entry(rom, eid):
    o = flat(ESTATS_BANK, ESTATS_TABLE) + eid * ESTATS_SIZE
    return bytearray(rom[o:o + ESTATS_SIZE])


def build_estats(rom, e):
    """Return (eid, 25-byte authored entry) or None if no enemy_stats authored."""
    es = e.get("enemy_stats")
    if not es:
        return None
    eid = es["eid"]
    entry = estats_entry(rom, es["clone_from_eid"])
    for field, val in es.get("overrides", {}).items():
        if field not in ESTATS_FIELDS:
            raise SystemExit(f"unknown enemy_stats override field: {field}")
        off = ESTATS_FIELDS[field][0]
        entry[off] = val & 0xFF
    # Address the EID naturally computes must land inside the trailing free run.
    addr = eid * ESTATS_SIZE + ESTATS_TABLE
    if not (ESTATS_FREE_START <= addr and addr + ESTATS_SIZE <= 0x8000):
        raise SystemExit(
            f"EID {eid} -> ${addr:04x} not in bank $14 free run "
            f"(${ESTATS_FREE_START:04x}..$7FFF); pick an EID that lands there.")
    return eid, addr, bytes(entry)


def emit_bank14(rom, spec):
    """Generate patches/bank_014.asm from the disassembly: replace the trailing
    339-nop free run with ds-pad + each authored enemy-stats entry at its
    EID-computed address + ds-pad. Only the entry bytes differ from clean."""
    placements = []
    for e in spec["species"]:
        r = build_estats(rom, e)
        if r:
            eid, addr, entry = r
            placements.append((addr, entry, e["id"], eid))
    if not placements:
        return False
    placements.sort()
    src = open(DIS_BANK14).read().split("\n")
    # strip the trailing run of `nop` lines (and trailing blanks)
    i = len(src) - 1
    while i >= 0 and src[i].strip() == "":
        i -= 1
    nop = 0
    while i >= 0 and src[i].strip() == "nop":
        nop += 1
        i -= 1
    assert nop == ESTATS_FREE_LEN, f"unexpected trailing nop count {nop}"
    head = src[:i + 1]
    # build the replacement free-space block
    body = []
    body.append("")
    body.append("; --- Phase N: new-species enemy-stats entries placed in free space ---")
    body.append("; (generated by tools/build_new_species.py; addresses chosen so vanilla")
    body.append(";  LoadEnemyStats addresses them via EID*25+$4C1D with no code fork)")
    cur = ESTATS_FREE_START
    for addr, entry, sid, eid in placements:
        if addr > cur:
            body.append(f"    ds {addr - cur}, $00")
            cur = addr
        b = ", ".join(f"${x:02x}" for x in entry)
        body.append(f"NewSpeciesEnemyStats_{sid}:   ; EID {eid} @ ${addr:04x} (species {sid})")
        body.append(f"    db {b}")
        cur += len(entry)
    if cur < 0x8000:
        body.append(f"    ds {0x8000 - cur}, $00")
    out = "\n".join(head + body) + "\n"
    with open(OUT_BANK14, "w") as f:
        f.write(out)
    return placements


def emit_asm(slots):
    lines = []
    A = lines.append
    A("; =============================================================================")
    A("; BANK $6A - NEW SPECIES DATA (Phase N, ids 224..255)")
    A("; =============================================================================")
    A("; Generated by tools/build_new_species.py (source: extracted/new_species.json)")
    A(";")
    A("; Reached from the bank $03 info-loader fork via `ld hl,$6a00; rst $10`")
    A("; (entry 0). The far-copy routine runs IN this bank (so the high table at")
    A("; $4000-$7FFF is mapped), reads $DA31 (species id >= 224), and copies the")
    A("; 43-byte info entry for (id-224) into DE (= $DA33, preserved across rst $10).")
    A("; Mul8x8To16 lives in ROM0 so it is callable here without a bank switch.")
    A("; =============================================================================")
    A("")
    A('SECTION "ROM Bank $06A", ROMX[$4000], BANK[$6A]')
    A("    db $6A                            ; bank self-ID at $4000")
    A("")
    A("; rst-$10 entry table at $4001 (HL=$6a00 dispatches entry 0)")
    A("    dw NewSpeciesInfoCopy")
    A("")
    A("; -----------------------------------------------------------------------------")
    A("; NewSpeciesInfoCopy - copy a new-species 43-byte info entry to DE (=$DA33).")
    A("; In: $DA31 = species id (>=224), DE = dest. Mirrors the vanilla copy loop.")
    A("; -----------------------------------------------------------------------------")
    A("NewSpeciesInfoCopy:")
    A("    ld a, [wTempSpeciesId]            ; $DA31 = species id (>=224)")
    A("    sub $e0                           ; index = id - 224")
    A("    ld c, $2b                         ; 43 = entry size")
    A("    call Mul8x8To16                   ; HL = index * 43")
    A("    ld bc, NewSpeciesHighInfoTable    ; + high table base (this bank)")
    A("    add hl, bc")
    A("    ld b, $2b                         ; copy 43 bytes")
    A(".copy:")
    A("    ld a, [hl+]")
    A("    ld [de], a")
    A("    inc de")
    A("    dec b")
    A("    jr nz, .copy")
    A("    ret")
    A("")
    A("; -----------------------------------------------------------------------------")
    A("; NewSpeciesHighInfoTable - 32 slots x 43 bytes, indexed (species_id - 224).")
    A("; Unpopulated slots are zero-filled (no species defined there yet).")
    A("; -----------------------------------------------------------------------------")
    A("NewSpeciesHighInfoTable:")
    for idx in range(ID_BUDGET):
        sid = FIRST_FREE_ID + idx
        if idx in slots:
            _sid, base, entry = slots[idx]
            A(f"; --- slot {idx}: species {sid} (cloned from species {base}) ---")
            body = ", ".join(f"${b:02x}" for b in entry)
            A(f"    db {body}")
        else:
            A(f"; --- slot {idx}: species {sid} (empty) ---")
            A("    ds 43, $00")
    A("")
    return "\n".join(lines) + "\n"


def validate(rom, spec, slots):
    """Round-trip: re-parse what we will emit, assert == authored; assert clone
    base == vanilla ROM entry before overrides."""
    for e in spec["species"]:
        idx = e["id"] - FIRST_FREE_ID
        sid, base, entry = slots[idx]
        # 1) clone base equals the vanilla ROM entry (minus the overridden bytes)
        vanilla = info_entry(rom, base)
        ov = e["info"].get("overrides", {})
        for off in range(INFO_SIZE):
            overridden = any(INFO_FIELDS[f][0] == off for f in ov)
            if not overridden:
                assert entry[off] == vanilla[off], (
                    f"slot {idx} byte {off:#x} drifted from clone base")
        # 2) overrides took effect
        for f, v in ov.items():
            off = INFO_FIELDS[f][0]
            assert entry[off] == (v & 0xFF), f"override {f} not applied"
        assert len(entry) == INFO_SIZE
    return True


def main():
    args = set(sys.argv[1:])
    rom = read_rom()
    with open(SPEC_PATH) as f:
        spec = json.load(f)
    slots = assemble_high_table(rom, spec)
    validate(rom, spec, slots)

    if "--dump-json" in args:
        out = {f"slot_{i}": {"species": s[0], "clone_from": s[1],
                             "info": s[2].hex(" ")}
               for i, s in sorted(slots.items())}
        print(json.dumps(out, indent=2))
        return

    asm = emit_asm(slots)
    if "--check" in args:
        print("VALIDATE OK: %d species, round-trip clean (no write)." % len(slots))
        return
    with open(OUT_PATH, "w") as f:
        f.write(asm)
    print("WROTE %s" % os.path.relpath(OUT_PATH, REPO))
    for idx, (sid, base, entry) in sorted(slots.items()):
        print(f"  slot {idx}: species {sid}  info={entry.hex(' ')}")
    placements = emit_bank14(rom, spec)
    if placements:
        print("WROTE %s" % os.path.relpath(OUT_BANK14, REPO))
        for addr, entry, sid, eid in placements:
            print(f"  enemy-stats species {sid} EID {eid} @ ${addr:04x}: {entry.hex(' ')}")
    print("VALIDATE OK: round-trip clean.")


if __name__ == "__main__":
    main()
