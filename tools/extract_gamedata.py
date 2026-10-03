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
  battle_gfx        $00:$2B9F  221 x 2    MonsterBattleGfxTable (S107 art tables)
  battle_palettes   $17:$62FD  216 x 8    MonsterBattlePalettes
  follower_gfx      $01:$49FF  215 x 2    ScreenTransDataTable species 0-214 (the
                                          eight copies are identical: --selftest)
  follower_layout_10 / _attr_10  $10:$407F 128 x 2 / $417F 128 x 1
  follower_layout_11 / _attr_11  $11:$407F  87 x 2 / $412D  87 x 1
  arena_masters     $04:$5E22   30 x 2    ArenaMasterSpriteTable (S109, P3.10b):
                                          [draw id, is_monster] per (group, match)
  arena_masters_50  $50:$6778   27 x 2    ArenaMasterSpriteTable50 — the bank $50
                                          copy (no King rows; --selftest: == the
                                          first 27 rows of bank $04's)
  arena_fees        $09:$5D23    8 x 2    ArenaClassFeeTable (entry fee G..S)
  chance_percent    $01:$69C0    8        EncounterChancePercent (code -> %)
  item_info         $03:$71DA   44 x 12   ItemInfoTable (S117: +1/+2 = buy price)
  shop_bazaar / _starry / _books / _rare / _gate
                    $09:$476B / $4774 / $477D / $4784 / $478C  the five vanilla
                    shop lists ($FF-terminated; S117 P3.13c)
  library           bank $4D recipe TEXT (dispatch entry = species + 5):
                    the 221 pointers, the raw $43CE-$53D2 string block, pad
                    byte, family tokens, and the bank-$41 monster name bytes
                    (BREEDING_SYSTEM "Library recipe TEXT").
  monster_text      S108 (P3.10 part 3): the three per-species text blocks the
                    compiler re-emits from gamedata.monster_text — names
                    ($41:$5B1F-$628D, 222 strings: species 0-219, then the
                    empty string of 220-224 and "?????" of 225-255), default
                    nicknames ($41:$69F2-$6C76, mode 7, species 0-214) and
                    descriptions ($4D:$53D3-$7719, mode 1 = dispatch entries
                    261-475, species 0-214). --selftest also proves each block
                    is contiguous, id-ordered and unshared (the property that
                    makes an unedited project reproduce the bytes).

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
    # S107 (P3.10 part 2a, gamedata.art): the per-species ART tables. Species
    # 0-214 only for everything but the battle tables (215-220 = TERRY? and the
    # summons — PROJECT_STATE Iron Rule 8 — are never re-arted, but their
    # battle rows are part of the tables).
    "battle_gfx": (0x00, 0x2B9F, 221, 2, "MonsterBattleGfxTable"),
    "battle_palettes": (0x17, 0x62FD, 216, 8, "MonsterBattlePalettes"),
    "follower_gfx": (0x01, 0x49DF + 32, 215, 2, "ScreenTransDataTable"),
    "follower_layout_10": (0x10, 0x407F, 128, 2, "FollowerLayoutL1Table10"),
    "follower_attr_10": (0x10, 0x417F, 128, 1, "FollowerAttrTable10"),
    "follower_layout_11": (0x11, 0x407F, 87, 2, "FollowerLayoutL1Table11"),
    "follower_attr_11": (0x11, 0x412D, 87, 1, "FollowerAttrTable11"),
    # S109 (P3.10b, gamedata.arena — editor2/core/arena.py): the arena tables
    # the compiler re-emits (the teams themselves are enemy_stats rows)
    "arena_masters": (0x04, 0x5E22, 30, 2, "ArenaMasterSpriteTable"),
    "arena_masters_50": (0x50, 0x6778, 27, 2, "ArenaMasterSpriteTable50"),
    "arena_fees": (0x09, 0x5D23, 8, 2, "ArenaClassFeeTable"),
    # S110 (P3.11, read-only in the Skills tab): the battle message id each
    # skill is ANNOUNCED with (bank $58 entry 6; $FF = silent) — the text is
    # dialogue.json's battle_message table
    "skill_announce": (0x58, 0x5806, 222, 1, "AnnounceTemplateTable"),
    # S114 (P3.13a, editor2/core/encounters.py): the vanilla gate+floor -> list
    # rule (bank $01 LoadNextDungeonFloor; copied into bank $76 by the compiler —
    # the patched build reads the copies) and the encounter-rate tables of bank
    # $16 (per-step drain = base * modifier / 64; the counter is re-seeded from
    # RandomEncounterCounterTable) for the editor's "steps between battles"
    "gate_base_pool": (0x01, 0x6A22, 32, 1, "GateBasePoolIndex"),
    "gate_bp_ptrs": (0x01, 0x6A42, 32, 2, "GateFloorBreakpoints"),
    "floor_breakpoints": (0x01, 0x6A82, 44, 1, "FloorBreakpointData"),
    "encounter_rate_mod": (0x16, 0x702B, 8, 1, "EncounterRateModifierTable"),
    "encounter_rate_data": (0x16, 0x6FAB, 16, 8, "EncounterRateData"),
    "encounter_counter_seeds": (0x16, 0x6E3D, 50, 4, "RandomEncounterCounterTable"),
    # S117 (P3.13c Shops, editor2/core/shops.py): the 44 item records (+1/+2 =
    # the buy price; the rest is re-emitted verbatim) and the five vanilla
    # shop lists of bank $09 ($FF-terminated; the patched build copies them
    # into bank $77, whose ShopFill replaced the bank $09 choice)
    "item_info": (0x03, 0x71DA, 44, 12, "ItemInfoTable"),
    "shop_bazaar": (0x09, 0x476B, 9, 1, "BazaarInventory"),
    "shop_starry": (0x09, 0x4774, 9, 1, "StarryNightShopInventory"),
    "shop_books": (0x09, 0x477D, 7, 1, "BookstoreInventory"),
    "shop_rare": (0x09, 0x4784, 8, 1, "RareItemShopInventory"),
    "shop_gate": (0x09, 0x478C, 9, 1, "GateworldShopInventory"),
}
# the eight copies of the follower gfx-ID table at species 0 (MONSTER_DATA
# "Follower-art table has EIGHT copies"): identical for species 0-214 —
# checked by --selftest, so one row list (follower_gfx) serves all eight
FOLLOWER_COPIES = [(0x01, 0x49DF + 32), (0x06, 0x4DCC + 32), (0x07, 0x6E14 + 32),
                   (0x09, 0x6B10 + 32), (0x0B, 0x4974 + 32), (0x12, 0x65F2 + 32),
                   (0x18, 0x4123), (0x59, 0x4363)]
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
    out["monster_text"] = monster_text(rom)
    out["skill_text"] = skill_text(rom)

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


# S108: the three per-species text blocks (PROJECT_COMPILER §2.24)
NAME_BLOCK = (0x5B1F, 0x628E)        # bank $41, [lo, hi)
NICK_TABLE, NICK_BLOCK = 0x4739, (0x69F2, 0x6C77)
DESC_ENTRY0, DESC_BLOCK = 261, (0x53D3, 0x771A)   # bank $4D


def _strings_in_order(rom, bank, ptrs, block, what):
    """The strings at `ptrs` (hex, without $F0) after checking they tile
    [block) exactly, in pointer order, each once."""
    out, a = [], block[0]
    for i, p in enumerate(ptrs):
        if p != a:
            raise SystemExit(f"{what}: entry {i} at ${p:04X}, expected ${a:04X} "
                             "(block not contiguous / id-ordered)")
        o = flat(bank, p)
        e = rom.index(b"\xf0", o)
        out.append(rom[o:e].hex())
        a += e - o + 1
    if a != block[1]:
        raise SystemExit(f"{what}: block ends at ${a:04X}, expected ${block[1]:04X}")
    return out


def monster_text(rom):
    w = lambda bank, addr: rom[flat(bank, addr)] | rom[flat(bank, addr) + 1] << 8
    nptr = [w(0x41, NAME_PTRS[1] + 2 * s) for s in range(256)]
    order = list(range(220)) + [220, 225]           # the 222 distinct strings
    _strings_in_order(rom, 0x41, [nptr[s] for s in order], NAME_BLOCK, "names")
    shared = {s: (220 if nptr[s] == nptr[220] else 225) for s in range(221, 256)}
    if any(nptr[s] not in (nptr[220], nptr[225]) for s in range(221, 256)):
        raise SystemExit("names: ids 221-255 must point at the 220 / 225 strings")
    kptr = [w(0x41, NICK_TABLE + 2 * s) for s in range(215)]
    nicks = _strings_in_order(rom, 0x41, kptr, NICK_BLOCK, "nicknames")
    dptr = [w(LIB_BANK, 0x4001 + 2 * (DESC_ENTRY0 + s)) for s in range(215)]
    descs = _strings_in_order(rom, LIB_BANK, dptr, DESC_BLOCK, "descriptions")
    return {
        "name_block": list(NAME_BLOCK), "name_order": order,
        "name_shared_221_255": [shared[s] for s in range(221, 256)],
        "nick_block": list(NICK_BLOCK), "nicks": nicks,
        "desc_block": list(DESC_BLOCK), "desc_entry0": DESC_ENTRY0, "descs": descs,
    }


# S110 (P3.11): the skill names (bank $41 text mode 6) and the SKIL-menu
# descriptions (bank $56 SkillDescPtrTable, mode 1 of SkillDescModeTable) —
# PROJECT_COMPILER §2.26
SKILL_NAME_PTRS, SKILL_NAME_BLOCK = 0x4539, (0x628E, 0x69F2)   # bank $41
SKILL_DESC_PTRS, SKILL_DESC_BLOCK = 0x6667, (0x502F, 0x664B)   # bank $56
SKILL_IDS = 222
SKILL_DESC_BLANK, SKILL_DESC_NONE = 0x6599, 0x664A


def skill_text(rom):
    w = lambda bank, addr: rom[flat(bank, addr)] | rom[flat(bank, addr) + 1] << 8
    nptr = [w(0x41, SKILL_NAME_PTRS + 2 * i) for i in range(256)]
    names = _strings_in_order(rom, 0x41, nptr[:SKILL_IDS + 1], SKILL_NAME_BLOCK,
                              "skill names")
    if any(nptr[i] != nptr[SKILL_IDS] for i in range(SKILL_IDS, 256)):
        raise SystemExit("skill names: ids 222-255 must share the empty string")
    dptr = [w(0x56, SKILL_DESC_PTRS + 2 * i) for i in range(256)]
    order = sorted(set(dptr))
    _strings_in_order(rom, 0x56, order, SKILL_DESC_BLOCK, "skill descriptions")
    shared = {SKILL_DESC_BLANK: "blank", SKILL_DESC_NONE: "none"}
    if any(dptr.count(p) > 1 for p in order if p not in shared):
        raise SystemExit("skill descriptions: only $6599 / $664A are shared")

    def text(p):
        o = flat(0x56, p)
        return rom[o:rom.index(b"\xf0", o)].hex()
    return {
        "name_block": list(SKILL_NAME_BLOCK), "names": names[:SKILL_IDS],
        "desc_block": list(SKILL_DESC_BLOCK),
        "descs": [text(dptr[i]) for i in range(SKILL_IDS)],
        "desc_shared": {str(i): shared[dptr[i]] for i in range(SKILL_IDS)
                        if dptr[i] in shared},
    }


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
    ref = rom[flat(*FOLLOWER_COPIES[0]):flat(*FOLLOWER_COPIES[0]) + 430]
    for b, a in FOLLOWER_COPIES[1:]:
        if rom[flat(b, a):flat(b, a) + 430] != ref:
            print(f"FAIL: follower gfx copy ${b:02X}:${a:04X} differs from bank $01's")
            return 1
    t = want["tables"]
    if t["arena_masters_50"]["rows"] != t["arena_masters"]["rows"][:27]:
        print("FAIL: the bank $50 arena master table is not the first 27 rows of bank $04's")
        return 1
    for k in ("shop_bazaar", "shop_starry", "shop_books", "shop_rare", "shop_gate"):
        rows = t[k]["rows"]
        if rows[-1] != "ff" or "ff" in rows[:-1] or "00" in rows:
            print(f"FAIL: {k} is not one $FF-terminated list of item ids")
            return 1
    if sorted(want["library"]["family_tokens"]) != [str(i) for i in range(10)]:
        print("FAIL: library family tokens incomplete")
        return 1
    print(f"OK: gamedata_vanilla.json == ROM ({len(want['tables'])} tables, "
          "library text, names, chance codes; monster name / nickname / "
          "description blocks contiguous + id-ordered; arena master copies agree;\n"
          "    skill name / description blocks contiguous, 2 shared empty descriptions)")
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
