"""Dump the complete arena / gate-boss / coliseum opponent-roster system (E1).

Decoded S67. The system has FOUR mechanisms (owning prose:
SIDEQUEST_MAP.md "Arena / gate-boss ROSTER format — DECODED"):

1. ARENA (authored, formula-addressed — no roster table exists):
   opcode $1F ArenaBattleSetup ($04:$5D5B) + bank $50 clone
   LoadArenaEnemyStats ($50:$6716) compute
       EID = $E0 + 9*wArenaGroup + 3*wColiseumBattle + slot   (slot 0-2)
   Groups 0-7 = classes G F E D C B A S, 8 = Starry Night, 9 = King
   (formula result overridden with EIDs $01E1-$01E3; the group-9 formula
   rows 305-313 are unreachable cut data). Master lobby sprites per match:
   ArenaMasterSpriteTable $04:$5E22 (30x2) / $50:$6778 (27x2 dup).
   Entry gold per class: word table $09:$5D23 (8 entries).

2. GATE BOSSES (authored, script-side): every boss room script triggers
   its fight with opcode $5A trigger_battle3 <EID> (single enemy) or
   opcode $05 TriggerBattle <EID>; two multi-enemy exceptions write
   $DA03+/$DA02 directly via write_ram2 (Temptation, Durran phase 1).
   The $14:$4893 redirect table maps fight EID -> join EID only.

3. IN-GATE COLISEUM (RNG, level-banded): opcode $5C ColiseumInitPrize
   ($04:$6D93, MAX party level) / bank $16 twin SetBrd_5e38 ($16:$5E38,
   AVERAGE party level) roll 3 parties of 3 from EID windows
   base+rand(range); prize item from $04:$6F44 (visits<9) / $6F54.

4. MIMIC / RANDOM SCALED (RNG): opcode $36 MimicBattleSetup word table
   $04:$63EF indexed by $CAB4 (arena-progress tier, = class+1, written
   by Arena Lobby scr0 on each class victory); opcode $52
   RandomScaledBattle word table $04:$6A3C (8 bases, +rand&$0F).

Self-checking: aborts if the load-bearing ROM anchors drift.

Usage: python3 tools/dump_arena_brackets.py   (writes extracted/arena_brackets.json)
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROM_PATH = ROOT / "data" / "DWM-original.gbc"

rom = ROM_PATH.read_bytes()


def rd(bank, addr, n):
    off = bank * 0x4000 + (addr - 0x4000 if bank else addr)
    return rom[off:off + n]


# ---------------------------------------------------------------- enemy stats
ES_BANK, ES_BASE, ES_SIZE, ES_COUNT = 0x14, 0x4C1D, 25, 487
NAME_PTR_BANK, NAME_PTR_OFFSET = 0x41, 0x4339

sys.path.insert(0, str(ROOT))
from dwm.rom import ROM  # noqa: E402
from dwm.text import decode  # noqa: E402

_rom_obj = ROM(ROM_PATH)
_names = {}
for i in range(256):
    p = _rom_obj.read(NAME_PTR_BANK, NAME_PTR_OFFSET + i * 2, 2)
    ptr = p[0] | (p[1] << 8)
    if 0x4000 <= ptr <= 0x7FFF:
        _names[i] = decode(_rom_obj.read_until(NAME_PTR_BANK, ptr, 0xF0))[0]


def enemy(eid):
    if not (0 <= eid < ES_COUNT):
        return {"eid": eid, "error": "out of range"}
    d = rd(ES_BANK, ES_BASE + eid * ES_SIZE, ES_SIZE)
    return {
        "eid": eid,
        "species_id": d[0],
        "species_name": _names.get(d[0], f"?#{d[0]}"),
        "level": d[4],
        "hp": d[5] | (d[6] << 8),
        "mp": d[7] | (d[8] << 8),
        "atk": d[9] | (d[10] << 8),
        "def": d[11] | (d[12] << 8),
        "agl": d[13] | (d[14] << 8),
        "int": d[15] | (d[16] << 8),
        "joinability": d[3],
    }


# ---------------------------------------------------------------- selftest anchors
def check(cond, msg):
    if not cond:
        sys.exit(f"SELFTEST FAIL: {msg}")


# opcode $1F formula constants: ld hl,$00e0 inside $04:$5D5B..; pin the bytes
check(rd(4, 0x5d69, 3) == bytes([0x21, 0xe0, 0x00]), "$1F base-$00E0 anchor @ $04:$5D69")
# group-9 override: ld hl,$01e1
check(rd(4, 0x5d98, 3) == bytes([0x21, 0xe1, 0x01]), "$1F King override anchor @ $04:$5D98")
# bank $50 clone base
check(bytes([0x21, 0xe0, 0x00]) in rd(0x50, 0x66d3, 0x40), "$50 clone base anchor")
# master sprite tables: first 54 bytes identical between $04:$5E22 and $50:$6778
check(rd(4, 0x5e22, 54) == rd(0x50, 0x6778, 54), "master sprite table duplication")
# G match0 slot0 = EID 224 = Dracky L1
e = enemy(0xE0)
check(e["species_name"] == "Dracky" and e["level"] == 1, "EID 224 = Dracky L1")
# redirect table head: dw 4,486
check(rd(0x14, 0x4893, 4) == bytes([4, 0, 0xE6, 0x01]), "redirect head 4->486")
# coliseum ladder heads (avg variant $16:$5E53, max variant $04:$6EC7 region)
check(bytes([0x21, 0x09, 0x02, 0xfe, 0x04]) in rd(0x16, 0x5e38, 0x40), "$16 coliseum ladder")
check(bytes([0x21, 0x09, 0x02, 0xfe, 0x04]) in rd(0x04, 0x6eb3, 0x60), "$04 coliseum ladder")

# ---------------------------------------------------------------- 1. arena brackets
CLASSES = ["G", "F", "E", "D", "C", "B", "A", "S", "StarryNight", "King"]
groups = []
for g in range(10):
    matches = []
    for m in range(3):
        base = 0xE0 + 9 * g + 3 * m
        matches.append({
            "match": m,
            "eids": [base, base + 1, base + 2],
            "party": [enemy(base + s) for s in range(3)],
        })
    entry = {"group": g, "class": CLASSES[g], "matches": matches}
    if g == 9:
        entry["note"] = ("group 9 formula rows (EIDs 305-313) are UNREACHABLE: "
                         "opcode $1F overrides group 9 with the King party below; "
                         "bank $50's clone early-returns before a 2nd King match")
        entry["king_override_party"] = [enemy(e) for e in (0x1E1, 0x1E2, 0x1E3)]
    groups.append(entry)

# master sprites
spr = rd(4, 0x5e22, 60)
master_sprites = []
for i in range(30):
    gfx, is_mon = spr[2 * i], spr[2 * i + 1]
    row = {"group": i // 3, "class": CLASSES[i // 3], "match": i % 3,
           "gfx_id": gfx, "is_monster": bool(is_mon)}
    if is_mon:
        sp = (gfx - 0x10) & 0xFF
        row["species_id"] = sp
        row["species_name"] = _names.get(sp, "?")
    master_sprites.append(row)

gold = rd(9, 0x5d23, 16)
entry_gold = {CLASSES[i]: gold[2 * i] | (gold[2 * i + 1] << 8) for i in range(8)}

# ---------------------------------------------------------------- 2. gate-boss triggers
# Decode script banks $0C-$0F command streams directly (words; opcode = lo|$FF00).
def scan_script_bank(bank):
    """Yield (addr, opcode, params...) for battle-relevant opcodes.

    We scan raw words; opcode words have high byte $FF. To avoid false
    positives we only accept sites whose surrounding decode is coherent:
    opcode $5A/$05 followed by a param word with high byte < $02 (EIDs < 512).
    """
    data = rd(bank, 0x4000, 0x4000)
    out = []
    for off in range(0, 0x4000 - 6, 2):
        if data[off + 1] != 0xFF:
            continue
        op = data[off]
        if op in (0x5A, 0x05):
            eid = data[off + 2] | (data[off + 3] << 8)
            if eid < ES_COUNT:
                out.append({"bank": bank, "addr": f"0x{0x4000+off:04X}",
                            "opcode": f"0x{op:02X}",
                            "opcode_name": "trigger_battle3" if op == 0x5A else "trigger_battle",
                            "eid": eid})
        elif op == 0x13:  # write_ram2
            tgt = data[off + 2] | (data[off + 3] << 8)
            if tgt in (0xDA03, 0xDA05, 0xDA07):
                val = data[off + 4] | (data[off + 5] << 8)
                out.append({"bank": bank, "addr": f"0x{0x4000+off:04X}",
                            "opcode": "0x13", "opcode_name": "write_ram2",
                            "target": f"0x{tgt:04X}", "eid": val})
    return out


sites = []
for b in range(0x0C, 0x10):
    sites.extend(scan_script_bank(b))

# attribute to scripts via all_scripts.json if present
scripts_path = ROOT / "extracted" / "all_scripts.json"
if scripts_path.exists():
    allscripts = json.loads(scripts_path.read_text())["scripts"]
    spans = []
    for sc in allscripts:
        addrs = [int(c["addr"][1:], 16) for c in sc["commands"]
                 if isinstance(c, dict) and "addr" in c]
        if addrs:
            spans.append((sc["bank"], min(addrs), max(addrs),
                          f"{sc['map_name']}/scr{sc['script_id']}"))
    for s in sites:
        a = int(s["addr"], 16)
        s["script"] = next((nm for b2, lo, hi, nm in spans
                            if b2 == s["bank"] and lo <= a <= hi + 6), None)

# known false-positive-free expectation: every $5A/$05 site with eid<487 in
# banks $0C-$0F should attribute; keep unattributed ones flagged, not dropped.
boss_sites = [dict(s, eid_info=enemy(s["eid"])) for s in sites]

# redirect table
redirects = []
addr = 0x4893
while True:
    d = rd(0x14, addr, 4)
    fe = d[0] | (d[1] << 8)
    if fe == 0xFFFF:
        break
    redirects.append({"fight_eid": fe, "join_eid": d[2] | (d[3] << 8),
                      "fight": enemy(fe)["species_name"] if fe < ES_COUNT else None})
    addr += 4
check(len(redirects) == 34, f"redirect table entry count {len(redirects)} != 34")

# ---------------------------------------------------------------- 3. coliseum RNG
LADDER = [  # (max avg/max level exclusive, base EID, range) — else-row cap = None
    (4, 0x02, 0x09), (10, 0x0D, 0x12), (16, 0x21, 0x12), (22, 0x39, 0x12),
    (28, 0x51, 0x12), (34, 0x69, 0x12), (40, 0x81, 0x12), (46, 0x9D, 0x12),
    (None, 0xB5, 0x12),
]
coliseum = {
    "mechanism": "3 parties of 3 random EIDs = base + rand(range); party level "
                 "keyed: bank $16 SetBrd_5e38 uses AVERAGE (floor-creation path), "
                 "opcode $5C ColiseumInitPrize ($04:$6D93) uses MAX (room script "
                 "path, also rolls prize). Parties 2/3 staged at $D9D1-$D9D6 / "
                 "$D9D9-$D9DE; bank $50 SetBtl_67ae chains them as wColiseumBattle "
                 "0->1->2->3.",
    "level_bands": [{"party_level_below": lv, "base_eid": b, "range": r,
                     "eid_window": [b, b + r - 1]} for lv, b, r in LADDER],
    "prize_table_lt9_visits": list(rd(4, 0x6f44, 16)),
    "prize_table_ge9_visits": list(rd(4, 0x6f54, 16)),
}

# ---------------------------------------------------------------- 4. mimic + scaled
mim = rd(4, 0x63ef, 18)
mimic = {"indexed_by": "$CAB4 arena-progress tier (Arena Lobby scr0 sets class+1)",
         "table_addr": "$04:$63EF",
         "eids": [mim[2 * i] | (mim[2 * i + 1] << 8) for i in range(9)]}
mimic["parties"] = [enemy(e) for e in mimic["eids"]]

sc = rd(4, 0x6a3c, 16)
scaled = {"opcode": "0x52", "table_addr": "$04:$6A3C",
          "tier": "(sum of party levels + 1) / 20, capped 7",
          "base_eids": [sc[2 * i] | (sc[2 * i + 1] << 8) for i in range(8)],
          "note": "EID = base + rand & $0F (16-wide windows, EIDs 352-479)"}

# ---------------------------------------------------------------- emit
out = {
    "_generator": "tools/dump_arena_brackets.py <- data/DWM-original.gbc "
                  "(md5 1ca6579359f21d8e27b446f865bf6b83) + extracted/all_scripts.json",
    "_note": "E1 roster system, decoded S67. Owning prose: SIDEQUEST_MAP.md. "
             "Arena parties are FORMULA-addressed consecutive enemy-stats rows "
             "(edit rows 224-304/481-483 to author); gate bosses are script "
             "opcode params (edit the $5A/$05 param + redirect pair + stats row).",
    "arena": {
        "formula": "EID = 0xE0 + 9*wArenaGroup + 3*wColiseumBattle + slot",
        "enemy_slot_ram": "$DA03/04 $DA05/06 $DA07/08 (16-bit LE); $DA02 = count-1",
        "groups": groups,
        "master_sprites": master_sprites,
        "entry_gold": entry_gold,
    },
    "gate_boss_triggers": boss_sites,
    "boss_redirect_table": redirects,
    "coliseum": coliseum,
    "mimic_battles": mimic,
    "random_scaled_battles": scaled,
}

dest = ROOT / "extracted" / "arena_brackets.json"
dest.write_text(json.dumps(out, indent=2))
n_boss = sum(1 for s in boss_sites if s["opcode"] != "0x13")
print(f"OK: {dest} — 10 arena groups, {n_boss} script battle triggers, "
      f"{len(redirects)} redirects. Selftest anchors PASS.")
