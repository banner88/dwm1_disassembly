"""Species slot-allocation map for the "add new monsters" arc (Phase N).

Decodes all 256 species-ID slots from the ROM and classifies each as
real / special / empty / free, then emits the verified fork points and the
top-range special-case gate inventory that the add-species work depends on.

This is the cemented output of the Phase-N scoping/RE pass: a fresh session
runs this instead of re-deriving the slot geography, the single-indexer fork
points, and the safe first-free id by hand.

Everything here is GROUND-TRUTH from the ROM/disassembly except the
`_user_annotation` strings on the 215-219 cluster (game knowledge: 215 TERRY?
is a one-off enemy, 216-219 Tatsu/Diago/Samsi/Bazoo are summon-skill
byproducts). The tool self-checks the load-bearing facts and aborts on drift.

Regenerates: extracted/species_slot_map.json
"""
import json
import sys
from pathlib import Path

from dwm.rom import ROM
from dwm.text import decode

ROM_PATH = Path("data/DWM-original.gbc")
DISASM = Path("disassembly")

# --- Verified geography constants (this session, ROM-grounded) -------------
NAME_PTR_BANK = 0x41
NAME_PTR_OFFSET = 0x4339          # 256 x 2 LE pointers within bank $41
INFO_LAST_ID = 220               # MonsterInfoTable is 221 entries (0..220)
LAST_REAL_NAME_ID = 219          # Bazoo; 220+ have empty names
SPECIAL_CLUSTER = {              # have names + bespoke per-id handling in code
    215: "TERRY? - one-off enemy, fightable, NOT breedable",
    216: "Tatsu - summon-skill byproduct only",
    217: "Diago - summon-skill byproduct only",
    218: "Samsi - summon-skill byproduct only",
    219: "Bazoo - summon-skill byproduct only",
}
FIRST_FREE_ID = 224              # >= $E0: every classifier ladder routes here to "normal"
LAST_ID = 255                    # species id is a single byte -> hard 256 ceiling

# Single arithmetic indexers (the ONLY fork points needed per table).
FORK_POINTS = {
    "monster_info": {
        "table": "$03:$4461", "entry_size": 43, "count": 221,
        "indexer": "$03:SaveMon_4446 (MonsterInfoCopy)",
        "note": "Only indexer; all 16 consumer banks read the 43-byte copy at $DA33. "
                "Fork: if id >= FIRST_FREE_ID, index a free-bank high-table instead of $4461.",
    },
    "enemy_stats": {
        "table": "$14:$4C1D", "entry_size": 25, "count": 487,
        "indexer": "$14:LoadEnemyStats",
        "note": "Only indexer; EID is 16-bit ($DA12/$DA13 -> Mul16x8To24), so the battle-stats "
                "side has NO 256 ceiling - new fight/join entries can append past 487.",
    },
}

# Top-range special-case gates to verify in N6 (decoded by hand this session).
# Each treats specific top ids specially; a new id MUST land in their "normal" bucket.
N6_GATES = [
    {"loc": "bank_05f.asm ~1680", "ladder": "$d5/$d6/$da/$dd/$de/$df/$e0",
     "effect": "clears 6 bytes @ $DA82 for ids <213,214-217,221,223; KEEP for 213,218-220,222,>=224",
     "verdict_for_new": "ids >= 224 fall in the final 'ret/keep' bucket = NORMAL"},
    {"loc": "bank_057.asm ~5773", "ladder": "$db/$dc/$dd",
     "effect": "battle attacker path special-cases id 221 (cp $dd; ret nz)",
     "verdict_for_new": "ids >= 224 are not 221 -> unaffected; CONFIRM no upper open-end"},
    {"loc": "bank_058.asm ~658", "ladder": "$d9/$dd (equality)",
     "effect": "loads $5203 for id 217 or 221",
     "verdict_for_new": "equality on 217/221 only -> ids >= 224 unaffected"},
    {"loc": "bank_052.asm ~3510", "ladder": "$d6/$dd (range)",
     "effect": "skill-function range check near SkillFunctionTable",
     "verdict_for_new": "CONFIRM ids >= 224 take the intended branch"},
]
# NB: the ~40 other `cp $dd`/`cp $de` hits repo-wide are FALSE POSITIVES -
# replicated interrupt-handler boilerplate (rst $28/ei/ret c/cp $dd/ldh [rIE])
# and misassembled data in high banks. Not species gates.


def _abort(msg: str):
    sys.stderr.write(f"SELF-CHECK FAILED: {msg}\n")
    sys.exit(1)


def main():
    rom = ROM(ROM_PATH)

    # --- self-check the load-bearing facts before emitting anything --------
    info_asm = (DISASM / "bank_003.asm").read_text()
    if "ld c, $2b" not in info_asm or "MonsterInfoTable:" not in info_asm:
        _abort("MonsterInfoTable indexer constants ($2b / label) not found in bank_003.asm")
    enemy_asm = (DISASM / "bank_014.asm").read_text()
    if "ld a, $19" not in enemy_asm or "EnemyStatsTable:" not in enemy_asm:
        _abort("EnemyStatsTable indexer constants ($19 / label) not found in bank_014.asm")

    # decode all 256 name slots
    slots = []
    ptr_for = {}
    for i in range(256):
        pb = rom.read(NAME_PTR_BANK, NAME_PTR_OFFSET + i * 2, 2)
        ptr = pb[0] | (pb[1] << 8)
        ptr_for[i] = ptr
        if ptr < 0x4000 or ptr > 0x7FFF:
            name, raw_len = "", 0
        else:
            raw = rom.read_until(NAME_PTR_BANK, ptr, 0xF0)
            name, _ = decode(raw)
            raw_len = len(raw)
        name_empty = (raw_len <= 1) or (name.strip() == "")

        if i <= LAST_REAL_NAME_ID and i not in SPECIAL_CLUSTER:
            status = "real"
        elif i in SPECIAL_CLUSTER:
            status = "special"
        elif FIRST_FREE_ID <= i <= LAST_ID:
            status = "free"
        else:                       # 220-223
            status = "empty_or_phantom"

        entry = {
            "id": i,
            "name": name,
            "name_ptr": f"$41:${ptr:04X}",
            "name_empty": name_empty,
            "has_info_entry": i <= INFO_LAST_ID,
            "status": status,
        }
        if i in SPECIAL_CLUSTER:
            entry["_user_annotation"] = SPECIAL_CLUSTER[i]
        slots.append(entry)

    # geography self-check: 220/221/222 must share one empty name pointer
    if not (ptr_for[220] == ptr_for[221] == ptr_for[222]):
        _abort(f"expected 220/221/222 to share a name pointer; got "
               f"{ptr_for[220]:04X}/{ptr_for[221]:04X}/{ptr_for[222]:04X}")
    empty_raw = rom.read_until(NAME_PTR_BANK, ptr_for[220], 0xF0)
    if len(empty_raw) != 0:          # read_until is terminator-exclusive -> empty name = b''
        _abort(f"expected id 220 name to be empty ($F0 first); got {empty_raw.hex()}")

    free_ids = [s["id"] for s in slots if s["status"] == "free"]

    out = {
        "_generator": "tools/map_species_slots.py (ROM data/DWM-original.gbc)",
        "_format": "Per-id species slot map for the add-new-species arc (Phase N). "
                   "status: real | special | empty_or_phantom | free.",
        "_self_checks": [
            "info/enemy indexer constants present in disasm",
            "ids 220/221/222 share one empty name pointer",
            "id 220 name is the bare $F0 terminator",
        ],
        "species_id_is_byte": True,
        "hard_ceiling": 256,
        "first_free_id": FIRST_FREE_ID,
        "free_count": len(free_ids),
        "free_ids": free_ids,
        "info_table_last_id": INFO_LAST_ID,
        "last_real_name_id": LAST_REAL_NAME_ID,
        "fork_points": FORK_POINTS,
        "n6_special_case_gates": N6_GATES,
        "slots": slots,
    }
    out_path = Path("extracted/species_slot_map.json")
    out_path.parent.mkdir(exist_ok=True)
    out_path.write_text(json.dumps(out, indent=2))

    # console summary
    print(f"Wrote {out_path}")
    print(f"  real slots          : {sum(1 for s in slots if s['status']=='real')}")
    print(f"  special (215-219)   : {sum(1 for s in slots if s['status']=='special')}")
    print(f"  empty/phantom 220-223: {sum(1 for s in slots if s['status']=='empty_or_phantom')}")
    print(f"  FREE for new species: {len(free_ids)}  (ids {FIRST_FREE_ID}..{LAST_ID})")
    print(f"  fork points         : monster_info {FORK_POINTS['monster_info']['indexer']}; "
          f"enemy_stats {FORK_POINTS['enemy_stats']['indexer']}")
    print("  self-checks         : PASS")


if __name__ == "__main__":
    main()
