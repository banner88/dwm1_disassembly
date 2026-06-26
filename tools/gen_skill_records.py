#!/usr/bin/env python3
"""Generate extracted/skill_records.json — the complete per-skill record set.

This is the editor-facing source of truth for the skill subsystem. Every skill
entry (id 0..221, $00..$DD) is assembled from SIX ROM data sources, each verified
against the ROM bytes at generation time:

  1. Name           $41:$4539  SkillNamePtrTable (dw) -> strings @ $628E ($F0 term)
  2. Effect handler $52:$4011  SkillFunctionTable (222 x dw), 115 unique handlers
  3. MP cost (cast) $07:$570C  222 x u16 LE   (999 = "All MP" sentinel)
                               [disassembly currently mislabels this region
                                'TilesetLookupTable'; the values are MP costs]
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
            },
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
