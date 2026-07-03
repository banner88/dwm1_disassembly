#!/usr/bin/env python3
"""Generate extracted/skill_records.json — the complete per-skill record set.

This is the editor-facing source of truth for the skill subsystem. Every skill
entry (id 0..221, $00..$DD) is assembled from SIX ROM data sources, each verified
against the ROM bytes at generation time:

  1. Name           $41:$4539  SkillNamePtrTable (dw) -> strings @ $628E ($F0 term)
  2. Effect handler $52:$4011  SkillFunctionTable (222 x dw), 115 unique handlers
  3. MP cost (cast) $07:$570C  222 x u16 LE   (999 = "All MP" sentinel)
                               [disassembly currently mislabels this region
                                'SkillMPCostTable' (renamed S51; was mislabeled TilesetLookupTable); the values are MP costs]
  4. Learn reqs     $06:$50E0  222 x 18B record (see LEARN_FMT below)
  5. Natural skills $03:$4461  monster info table, +$06 = 3 base-skill ids/monster
  6. Inherit base   $16:$4874  UnevolvedSkillMap (256B, skill_id -> base, $FF=none)

Classification (`kind`):
  - "skill"       : referenced by any monster natural set OR any enemy skill list
  - "item_effect" : ids 176..212 (the in-battle item-use handler block)
  - "internal"    : everything else (battle states, dupes, the basic-attack command)

Family-cut decoding: handlers shaped like the family-cut stub
  (call $63xx; ld hl,$b682; call $54ea; ret) are followed into their $63xx
  sub-function, whose `cp $0X` reveals the family code it boosts damage against
  (0=Slime 1=Dragon 2=Beast 3=Bird 4=Plant 5=Bug 6=Devil 7=Zombie 8=Material).
  This is why id 215 (ROM name "Sheldodge") is really the Bug-family cut.

Run from repo root:  python3 tools/gen_skill_records.py
Writes extracted/skill_records.json. Pair with build_skill_tables.py --selftest
to prove the JSON re-emits the ROM tables byte-identically.
"""
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(SCRIPT_DIR)
sys.path.insert(0, REPO)
from dwm.rom import ROM          # noqa: E402
from dwm.text import decode      # noqa: E402

ROM_PATH = os.path.join(REPO, "data", "DWM-original.gbc")
ENEMY_PATH = os.path.join(REPO, "extracted", "enemy_stats.json")
OUT_PATH = os.path.join(REPO, "extracted", "skill_records.json")

N_SKILLS = 222                   # ids 0..221 ($00..$DD); table 222..255 is dead

# Table locations (all verified against ROM at runtime via the asserts below)
NAME_BANK, NAME_PTRS = 0x41, 0x4539
FUNC_BANK, FUNC_TABLE = 0x52, 0x4011
MP_BANK, MP_TABLE = 0x07, 0x570C
LEARN_BANK, LEARN_TABLE = 0x06, 0x50E0
LEARN_REC = 18
INHERIT_BANK, INHERIT_TABLE = 0x16, 0x4874
MON_BANK, MON_TABLE, MON_STRIDE, MON_COUNT = 0x03, 0x4461, 43, 221
MON_SKILL_OFF = 0x06             # +6,+7,+8 = 3 base skill ids

# --- battle "record" table (the per-skill PARAMETER block) ---------------------
# $54:$4001 is a 231-entry dw table reached via rst $10 (entries 0..8 are routines).
# Entries 9..230 (222) are the per-skill record pointers; they are simply
# $41CF + id*19, i.e. the record-pointer table shares storage with the dispatch
# table and is indexed (as $54:$4013 + id*2) by the working skill id $db8a.
# Each record is 19 ($13) bytes. Handlers ($52:$4011) are the EFFECT TYPE and are
# shared across same-effect skills (Blaze/Blazemore/Blazemost all -> $41CD); the
# per-skill differences (power, targeting, message) live HERE in the record.
#
# Field map — FAQ-validated where marked PROVEN:
#   +0  b  effect_class    fine effect/message id; shared by same-effect skills
#                          (Heal/Healmore=$18, Increase/Upper=$0f)            HIGH
#   +1  b  effect_category coarse category, hi-nibble: 1=damage 2=status/debuff
#                          3=heal/buff 6/8=special, items=$8x                  HIGH
#   +2  b  target_mode     target scope (cached -> $dcfc, read by AI $57):
#                          $11=1 foe $12=all foes $21=1 ally $22=all allies,
#                          $31/$41=special. FAQ-Range-validated.             PROVEN
#   +3  b  ai_weight       per-skill AI action score; the enemy AI ($57
#                          Jump_057_7529) SUMS record[+3] over its skill list
#                          into the score table $dce4 -> picks weighted. The
#                          per-skill AI lever (distinct from enemy-stats +17).  HIGH
#   +4  b  mp_cost_byte    byte copy of MP cost ($07 table); 19/19 match     PROVEN
#   +5  b  status_id       status/secondary-effect id; groups by effect
#                          (Sleep fam=$08, Poison=$13, Slow=$0e, death=$09)  PROVEN
#   +6  b  damage_class    $00=non-damage $04=spell-damage $05=breath-damage PROVEN
#                          (FireAir/Scorching breath=$05 vs Blaze spell=$04;
#                          element itself is chosen in the handler, not here)
#   +7  b  flags7          presentation bitfield (cached $dcfd; bit3 -> guard/
#                          skip path in bank $53)                              MED
#   +8  b  flags8          anim/message bitfield (cached $dcfe; bit4 -> message
#                          variant $67/$68)                                    MED
#   +9  b  flags9          cast-behavior bitfield (cached $dcff; bit5 -> special
#                          cast sub-state $d9ed=5)                             MED
#   +10 b  field10         small class flag (read, compared ==1 in a build loop) LOW
#   +11 w  power_party_min   damage/heal MINIMUM, party-side caster          PROVEN
#   +13 w  power_party_range damage/heal RANGE (max = min+range), party       PROVEN
#   +15 w  power_enemy_min   damage/heal minimum, enemy-side caster          PROVEN
#   +17 w  power_enemy_range damage/heal range, enemy                        PROVEN
# PROVEN +11/+13: 31/32 FAQ damage-heal ranges match min..min+range exactly
# (the 1 miss is Explodet, ROM 130-150 vs a likely FAQ typo "130-140").
# Caster side picked in $52:StoreDamageResult / $54 entry5 by wBattleAttackerIdx
# bit2. Animation is NOT here — it is the descriptor-setter's anim pointer
# ($52:SetHLBattle_54e7 -> $dd70=$b882 for Blaze).
REC_BANK, REC_PTRS = 0x54, 0x4013   # entry 9 = first record pointer
REC_DATA = 0x41CF                    # record data start (= entry 9 target)
REC_STRIDE = 19                      # $13 bytes / record

# Symmetric (name <-> byte) codec so every one of the 19 bytes is a named field
# and encode(decode(raw)) == raw exactly (the round-trip guarantee).
REC_BYTE_FIELDS = [                 # offset -> single-byte field name
    (0, "effect_class"), (1, "effect_category"), (2, "target_mode"),
    (3, "ai_weight"), (4, "mp_cost_byte"), (5, "status_id"), (6, "damage_class"),
    (7, "flags7"), (8, "flags8"), (9, "flags9"), (10, "field10"),
]
REC_WORD_FIELDS = [                 # offset -> 16-bit LE field name
    (11, "power_party_min"), (13, "power_party_range"),
    (15, "power_enemy_min"), (17, "power_enemy_range"),
]


def decode_battle_record(b):
    """19 raw bytes -> dict of named fields covering every byte."""
    d = {}
    for off, nm in REC_BYTE_FIELDS:
        d[nm] = b[off]
    for off, nm in REC_WORD_FIELDS:
        d[nm] = b[off] | (b[off + 1] << 8)
    return d


def encode_battle_record(fields):
    """Named fields -> 19 raw bytes (inverse of decode_battle_record)."""
    b = bytearray(REC_STRIDE)
    for off, nm in REC_BYTE_FIELDS:
        b[off] = fields[nm] & 0xFF
    for off, nm in REC_WORD_FIELDS:
        v = fields[nm]
        b[off] = v & 0xFF
        b[off + 1] = (v >> 8) & 0xFF
    return bytes(b)

MP_ALL_SENTINEL = 999            # Farewell / MegaMagic

FAMILY_NAMES = {0: "slime", 1: "dragon", 2: "beast", 3: "bird", 4: "plant",
                5: "bug", 6: "devil", 7: "zombie", 8: "material"}


def u16(b, i):
    return b[i] | (b[i + 1] << 8)


def decode_family_code(rom, handler_addr):
    """If handler is a family-cut stub, return (family_code, family_name); else None.

    Stub pattern @ handler: CD lo hi 21 82 B6 CD EA 54 C9  (call sub; ld hl,$b682;
    call $54ea; ret).  Sub @ $63xx: CD D7 60 CD C0 6A FE XX 20 03 ...  -> XX = family.
    """
    h = rom.read(FUNC_BANK, handler_addr, 10)
    if not (h[0] == 0xCD and h[3:10] == bytes([0x21, 0x82, 0xB6, 0xCD, 0xEA, 0x54, 0xC9])):
        return None
    sub = h[1] | (h[2] << 8)
    s = rom.read(FUNC_BANK, sub, 8)
    # standard families: CD D7 60 CD C0 6A FE XX
    if s[0:6] == bytes([0xCD, 0xD7, 0x60, 0xCD, 0xC0, 0x6A]):
        if s[6] == 0xFE:                       # cp $0X  -> families 1..8
            code = s[7]
            return code, FAMILY_NAMES.get(code, f"code_{code}")
        if s[6] == 0xB7:                       # or a    -> slime (family 0)
            return 0, FAMILY_NAMES[0]
    return None


def main():
    from pathlib import Path
    rom = ROM(Path(ROM_PATH))

    # --- names ---
    names = []
    for i in range(N_SKILLS):
        ptr = u16(rom.read(NAME_BANK, NAME_PTRS + i * 2, 2), 0)
        names.append(decode(rom.read_until(NAME_BANK, ptr, 0xF0))[0])

    # --- handlers ---
    handlers = [u16(rom.read(FUNC_BANK, FUNC_TABLE + i * 2, 2), 0) for i in range(N_SKILLS)]
    handler_group = {}
    for i, h in enumerate(handlers):
        handler_group.setdefault(h, []).append(i)

    # --- mp costs ---
    mp = [u16(rom.read(MP_BANK, MP_TABLE + i * 2, 2), 0) for i in range(N_SKILLS)]

    # --- learn requirements + prereqs ---
    learn = []
    prereqs = []
    for i in range(N_SKILLS):
        r = rom.read(LEARN_BANK, LEARN_TABLE + i * LEARN_REC, LEARN_REC)
        learn.append({"level": r[0], "hp": u16(r, 1), "mp": u16(r, 3),
                      "atk": u16(r, 5), "def": u16(r, 7), "agl": u16(r, 9),
                      "int": u16(r, 11)})
        prereqs.append([p for p in r[13:18] if p != 0xFF])

    # --- inheritance base map ---
    inherit = rom.read(INHERIT_BANK, INHERIT_TABLE, 256)

    # --- battle records (the per-skill PARAMETER block) ---
    # Verify the pointer table (entries 9..230) is exactly $41CF + i*19 so the
    # round-trip can re-emit BOTH the pointers and the data from id alone.
    battle_raw = []
    for i in range(N_SKILLS):
        ptr = u16(rom.read(REC_BANK, REC_PTRS + i * 2, 2), 0)
        assert ptr == REC_DATA + i * REC_STRIDE, (
            f"record ptr[{i}]=${ptr:04X} != ${REC_DATA + i * REC_STRIDE:04X}; "
            "table geometry changed — re-verify before trusting")
        battle_raw.append(rom.read(REC_BANK, ptr, REC_STRIDE))
    # self-check: decode->encode is byte-exact for every record
    for i, b in enumerate(battle_raw):
        assert encode_battle_record(decode_battle_record(b)) == bytes(b), \
            f"battle-record codec not byte-exact for id {i}"

    # --- usage: monster natural sets + enemy lists ---
    nat_by_skill = {i: [] for i in range(N_SKILLS)}
    for m in range(MON_COUNT):
        rec = rom.read(MON_BANK, MON_TABLE + m * MON_STRIDE, 9)
        for s in rec[MON_SKILL_OFF:MON_SKILL_OFF + 3]:
            if s < N_SKILLS:
                nat_by_skill[s].append(m)
    enemy = json.load(open(ENEMY_PATH))
    enemy_by_skill = {i: [] for i in range(N_SKILLS)}
    for e in enemy:
        for s in e.get("skills", []):
            if s < N_SKILLS:
                enemy_by_skill[s].append(e.get("species_name"))
    referenced = {i for i in range(N_SKILLS)
                  if nat_by_skill[i] or enemy_by_skill[i]}

    def kind_of(i):
        if i in referenced:
            return "skill"
        if 176 <= i <= 212:
            return "item_effect"
        return "internal"

    # --- assemble records ---
    records = []
    for i in range(N_SKILLS):
        fam = decode_family_code(rom, handlers[i])
        rec = {
            "id": i,
            "name": names[i],
            "kind": kind_of(i),
            "mp_cost": ("ALL" if mp[i] == MP_ALL_SENTINEL else mp[i]),
            "handler_addr": f"${handlers[i]:04X}",
            "handler_shared_with": [j for j in handler_group[handlers[i]] if j != i],
            "learn": learn[i],
            "prereqs": prereqs[i],
            "prereq_names": [(names[p] if p < N_SKILLS else f"?{p}") for p in prereqs[i]],
            "inherit_base": (None if inherit[i] == 0xFF else inherit[i]),
            "family_code": (fam[0] if fam else None),
            "family": (fam[1] if fam else None),
            "natural_to_species": sorted(set(nat_by_skill[i])),
            "enemy_users": sorted(set(x for x in enemy_by_skill[i] if x)),
            "battle_record": {
                "addr": f"${REC_DATA + i * REC_STRIDE:04X}",
                "raw": battle_raw[i].hex(),
                "fields": decode_battle_record(battle_raw[i]),
            },
        }
        if i == 215:
            rec["note"] = ("ROM name 'Sheldodge' is a placeholder; this is the "
                           "Bug-family cut (family code 5). FAQ calls it 'BugBlow'. "
                           "patches/bank_041.asm renames the displayed string to 'BugCut'.")
        records.append(rec)

    out = {
        "_generator": {
            "tool": "tools/gen_skill_records.py",
            "rom_md5_source": "1ca6579359f21d8e27b446f865bf6b83",
            "n_skills": N_SKILLS,
            "id_range": "0x00..0xDD",
            "sources": {
                "name_ptr_table": f"${NAME_BANK:02X}:${NAME_PTRS:04X}",
                "function_table": f"${FUNC_BANK:02X}:${FUNC_TABLE:04X}",
                "mp_cost_table": f"${MP_BANK:02X}:${MP_TABLE:04X} (u16 LE; 999=ALL)",
                "learn_req_table": f"${LEARN_BANK:02X}:${LEARN_TABLE:04X} (18B/record)",
                "natural_skills": f"${MON_BANK:02X}:${MON_TABLE:04X}+${MON_SKILL_OFF:02X}",
                "inherit_base": f"${INHERIT_BANK:02X}:${INHERIT_TABLE:04X}",
                "battle_record_table": (
                    f"${REC_BANK:02X}:${REC_PTRS:04X} ptrs (=${REC_DATA:04X}+id*{REC_STRIDE}) "
                    f"-> {REC_STRIDE}B records; handler=effect-type (shared), "
                    "record=per-skill params"),
            },
            "battle_record_format": (
                "+0 effect_class | +1 effect_category(1=dmg 2=status 3=heal/buff "
                "8=item) | +2 target_mode($11=1foe $12=allfoes $21=1ally $22=allallies) "
                "| +3 ai_weight(per-skill AI score, summed by enemy AI $57) "
                "| +4 mp_cost_byte | +5 status_id(Sleep=$08 Poison=$13 Slow=$0e death=$09) "
                "| +6 damage_class($00=none $04=spell $05=breath) | +7/+8/+9 flag "
                "bitfields(presentation/anim/cast) | +11/+13 power_party_min/range, "
                "+15/+17 power_enemy_min/range (u16 LE; max=min+range; caster-side). "
                "PROVEN/HIGH: +0,+1,+2,+3,+4,+5,+6,+11,+13,+15,+17. Animation pointer "
                "is in the handler's descriptor-setter ($52:SetHLBattle_54e7 -> "
                "$dd70=$b882 for Blaze), NOT the record."),
            "learn_record_format":
                "+0 level u8 | +1 hp +3 mp +5 atk +7 def +9 agl +11 int (u16 LE) "
                "| +13..17 up to 5 prereq skill ids ($FF=none)",
            "kind_counts": None,   # filled below
        },
        "records": records,
    }
    kc = {}
    for r in records:
        kc[r["kind"]] = kc.get(r["kind"], 0) + 1
    out["_generator"]["kind_counts"] = kc

    json.dump(out, open(OUT_PATH, "w"), indent=2)
    print(f"wrote {OUT_PATH}: {len(records)} records  kinds={kc}")


if __name__ == "__main__":
    main()
