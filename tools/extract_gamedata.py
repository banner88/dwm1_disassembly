#!/usr/bin/env python3
"""extract_gamedata.py — the VANILLA base of project.json `gamedata` (P3.9, S103).

Layer A-lite (EDITOR_DESIGN §6.2, PROJECT_COMPILER §2.20): the compiler owns the
vanilla data tables as @BUILD_PROJECT regions and emits them as
"vanilla rows + the project's gamedata overrides". The vanilla rows come from
this committed JSON, so compiling never needs the ROM (CI has none) and an
unedited `gamedata` reproduces the ROM bytes exactly.

Tables (flat offsets verified S76 in randomizer/romdata.py and re-checked S103
against the patched build's game.sym — every label sits at the same address):

  monster_info      $03:$4461  221 x 43   MonsterInfoTable
  enemy_stats       $14:$4C1D  487 x 25   EnemyStatsTable (EIDs 0-486)
  encounter_pools   $01:$6AAE  128 x 26   EncounterPoolData
  family_recipes    $16:$4974  222 x 2    FamilyRecipeTable (slot = offspring)
  special_recipes   $16:$4B30  825 x 5    SpecialRecipeTable (vanilla base of
                                          the live bank-$69 table, B2/B5)
  exp_curves        $13:$41E6   32 x 297  ExpCurveTables (99 x u24 LE)
  growth_curves     $13:$6706   32 x 99   StatGrowthTables
  skill_learn       $06:$50E0  218 x 18   SkillLearnReqTable (ids $00-$D9 ONLY:
                                          $DA-$DD read bank-$06 code, S100)
  skill_mp          $07:$570C  222 x 2    SkillMPCostTable
  skill_records     $54:$41CF  222 x 19   SkillRecordData
  boss_redirects    $14:$4893   34 x 4    BossRedirectTable (fight, join)
  chance_percent    $01:$69C0    8        EncounterChancePercent (code -> %)
  library           bank $4D recipe TEXT (dispatch entry = species + 5):
                    the 221 pointers, the raw $43CE-$53D2 string block, pad
                    byte, family tokens, and the bank-$41 monster name bytes
                    (BREEDING_SYSTEM "Library recipe TEXT").

Usage:
  python3 tools/extract_gamedata.py              # write extracted/gamedata_vanilla.json
  python3 tools/extract_gamedata.py --selftest   # JSON == ROM (verify check 5)
"""
import hashlib
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_PATH = os.path.join(REPO, "data", "DWM-original.gbc")
OUT = os.path.join(REPO, "extracted", "gamedata_vanilla.json")
ORIGINAL_MD5 = "1ca6579359f21d8e27b446f865bf6b83"


def flat(bank, addr):
    return bank * 0x4000 + (addr - 0x4000 if bank else addr)


# name: (bank, addr, count, stride, label)
TABLES = {
    "monster_info": (0x03, 0x4461, 221, 43, "MonsterInfoTable"),
    "enemy_stats": (0x14, 0x4C1D, 487, 25, "EnemyStatsTable"),
    "encounter_pools": (0x01, 0x6AAE, 128, 26, "EncounterPoolData"),
    "family_recipes": (0x16, 0x4974, 222, 2, "FamilyRecipeTable"),
    "special_recipes": (0x16, 0x4B30, 825, 5, "SpecialRecipeTable"),
    "exp_curves": (0x13, 0x41E6, 32, 297, "ExpCurveTables"),
    "growth_curves": (0x13, 0x6706, 32, 99, "StatGrowthTables"),
    "skill_learn": (0x06, 0x50E0, 218, 18, "SkillLearnReqTable"),
    "skill_mp": (0x07, 0x570C, 222, 2, "SkillMPCostTable"),
    "skill_records": (0x54, 0x41CF, 222, 19, "SkillRecordData"),
    "boss_redirects": (0x14, 0x4893, 34, 4, "BossRedirectTable"),
}
CHANCE = (0x01, 0x69C0, 8)          # EncounterChancePercent
LIB_BANK = 0x4D
LIB_ENTRY0 = 5                      # dispatch entry = species + 5
SPECIES = 221
NAME_PTRS = (0x41, 0x4339)          # MonsterNamePtrTable (256 x dw)
TOKEN1 = 9


def extract(rom):
    out = {
        "_generator": ("tools/extract_gamedata.py from data/DWM-original.gbc "
                       f"{ORIGINAL_MD5} (S103, ROADMAP P3.9). Rows are hex. "
                       "Consumed by editor2/core/gamedata.py; verify check 5 "
                       "runs --selftest."),
        "tables": {},
    }
    for name, (bank, addr, n, stride, label) in TABLES.items():
        o = flat(bank, addr)
        out["tables"][name] = {
            "bank": bank, "addr": addr, "stride": stride, "label": label,
            "rows": [rom[o + i * stride: o + (i + 1) * stride].hex() for i in range(n)],
        }
    b, a, n = CHANCE
    out["chance_percent"] = list(rom[flat(b, a): flat(b, a) + n])

    # --- names (bank $41) ---------------------------------------------------
    names = []
    for s in range(256):
        p = flat(NAME_PTRS[0], NAME_PTRS[1]) + 2 * s
        ptr = rom[p] | rom[p + 1] << 8
        q = flat(0x41, ptr)
        end = rom.find(b"\xf0", q, q + 24)
        names.append(rom[q:end].hex() if 0x4000 <= ptr < 0x8000 and end > 0 else "")
    out["monster_name_bytes"] = names

    # --- bank $4D library recipe text ------------------------------------
    base = flat(LIB_BANK, 0x4000)
    ptrs = [rom[base + 1 + 2 * i] | rom[base + 2 + 2 * i] << 8 for i in range(476)]
    lib_ptrs = ptrs[LIB_ENTRY0:LIB_ENTRY0 + SPECIES]

    def text(ptr):
        o = flat(LIB_BANK, ptr)
        e = rom.find(b"\xf0", o, o + 64)
        return rom[o:e]

    row0 = text(lib_ptrs[0])
    pad = row0[TOKEN1 - 1]
    pad2 = len(row0) == 2 * TOKEN1
    fam = [rom[flat(0x16, 0x4974) + 2 * i: flat(0x16, 0x4974) + 2 * i + 2] for i in range(222)]
    tokens = {}
    for s in range(SPECIES):
        a, b2 = fam[s]
        row = text(lib_ptrs[s])
        if len(row) < TOKEN1:
            continue
        if a >= 0xF0 and a <= 0xF9 and (a - 0xF0) not in tokens:
            t = row[:TOKEN1].rstrip(bytes([pad]))
            if t:
                tokens[a - 0xF0] = t
        if b2 >= 0xF0 and b2 <= 0xF9 and (b2 - 0xF0) not in tokens:
            t = row[TOKEN1:].rstrip(bytes([pad]))
            if t:
                tokens[b2 - 0xF0] = t
    # the contiguous string block (species 0-214 one slot each, then the one
    # string 215-220 share), kept raw so slots keep their exact bytes
    blk_lo = min(lib_ptrs)
    blk_hi = flat(LIB_BANK, max(lib_ptrs))
    blk_hi = rom.find(b"\xf0", blk_hi, blk_hi + 64) + 1
    out["library"] = {
        "dispatch_entry0": LIB_ENTRY0,
        "block_addr": blk_lo,
        "block": rom[flat(LIB_BANK, blk_lo):blk_hi].hex(),
        "ptrs": lib_ptrs,
        "strings": [text(p).hex() for p in lib_ptrs],
        "pad": pad,
        "pad_token2": pad2,
        "family_tokens": {str(k): v.hex() for k, v in sorted(tokens.items())},
    }
    return out


def load_rom():
    rom = open(ROM_PATH, "rb").read()
    if hashlib.md5(rom).hexdigest() != ORIGINAL_MD5:
        sys.exit("ERROR: data/DWM-original.gbc is not the original ROM")
    return rom


def selftest():
    if not os.path.exists(ROM_PATH):
        print("SKIP: no ROM")
        return 0
    rom = load_rom()
    want = extract(rom)
    have = json.load(open(OUT))
    bad = [k for k in want if k != "_generator" and want[k] != have.get(k)]
    if bad:
        print(f"FAIL: {OUT} differs from the ROM in {bad} — regenerate")
        return 1
    # family tokens: all ten must be present (the library writer needs them)
    if sorted(want["library"]["family_tokens"]) != [str(i) for i in range(10)]:
        print("FAIL: library family tokens incomplete")
        return 1
    print(f"OK: gamedata_vanilla.json == ROM ({len(want['tables'])} tables, "
          "library text, names, chance codes)")
    return 0


def main():
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    rom = load_rom()
    data = extract(rom)
    with open(OUT, "w") as f:
        json.dump(data, f, indent=1)
        f.write("\n")
    print(f"wrote {OUT} ({os.path.getsize(OUT)} B)")


if __name__ == "__main__":
    main()
