"""Internal gate ID -> gate name, derived from the gate-indexed ROM table (S100 rewrite).

WHY THE REWRITE (S100, DOC_AUDIT S100): the old version keyed gate names on the
boss FIGHT/JOIN redirect table at $14:$4897, read as if it were indexed by gate
id. It is not: that table has one row per boss (the Gate of Demolition has two,
Hargon and Sidoh), so every gate from 23 up came out one name late (23 "Demolition
(Hargon)", 24 "Demolition (Sidoh)", 25 "Mastermind" ... 31 "Unused"). A second,
hand-written list (tools/gate_reference.py) had its own error in the other
direction (gates 12-17 in FAQ chapter order instead of ROM id order).

THE GATE-INDEXED SOURCE: GateFloorDataTable ($16:$70A6, 32 x 8 B, indexed by
wGateID — the loader at $16:$5B72 reads it with wGateID*8; GATE_GENERATION.md §1).
Two of its fields identify a gate independently of each other:
  byte 3 = last_floor (the gate's floor count INCLUDING the boss floor: the boss
           floor is served when wCurrentFloor+1 == last_floor, wCurrentFloor
           counting from 0) — cross-checked here against the FAQ "Levels: N"
           box of every gate;
  byte 4 = boss map type (the bank $0B room served on the boss floor) — named
           through dwm/map_names.py.
Every gate must agree on BOTH or the tool fails (non-zero exit).

Output: extracted/gate_names.json
  {"_generator": ..., "gates": [{"id", "name", "faq_name", "floors",
    "boss_map", "boss_room", "floor_types", "depth_tier"} x 32]}
Readers: tools/dump_room_data.py, tools/gen_encounter_db.py, editor2 Gates tab
(editor2/core/gates.py).

Usage:  python3 -m tools.map_gate_names [--check]
  --check / --selftest  exit non-zero if extracted/gate_names.json differs from
           the ROM derivation (verify_integrity check 5).
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
from dwm.map_names import MAP_NAMES  # noqa: E402

ROM_PATH = ROOT / "data" / "DWM-original.gbc"
OUT = ROOT / "extracted" / "gate_names.json"

GATE_TABLE_BANK, GATE_TABLE_ADDR, GATE_ROW = 0x16, 0x70A6, 8

# boss map type (ROM fact, GateFloorDataTable byte 4) -> (editor name, FAQ box
# title, FAQ "Levels:" value). The FAQ column is the independent witness.
BOSS_MAP_TO_GATE = {
    0x30: ("Gate of Beginning", "Gate 1 - Beginning", 5),
    0x31: ("Gate of Villager", "Gate 2 - Villager", 5),
    0x32: ("Gate of Talisman", "Gate 3 - Talisman", 6),
    0x33: ("Gate of Memories", "Gate 4 - Memories", 5),
    0x34: ("Gate of Bewilder", "Gate 5 - Bewilder", 6),
    0x35: ("Bazaar Gate", "Bazaar Gate", 9),
    0x36: ("Gate of Peace", "Gate 6 - Peace", 8),
    0x37: ("Gate of Bravery", "Gate 7 - Bravery", 9),
    0x38: ("Well Gate", "Well Gate", 12),
    0x39: ("Gate of Strength", "Gate 9 - Strength", 11),
    0x3C: ("Gate of Anger", "Gate 8 - Anger", 11),
    0x10: ("Farm Gate", "Monster Farm Gate", 12),        # boss = the Copycat House room
    0x3B: ("Gate of Joy", "Gate 10 - Joy", 14),
    0x3A: ("Gate of Wisdom", "Gate 11 - Wisdom", 15),
    0x3D: ("Arena - Left Gate", "Goopi's Gate", 16),
    0x3E: ("Gate of Happiness", "Gate 12 - Happiness", 18),
    0x3F: ("Gate of Temptation", "Gate 13 - Temptation", 20),
    0x40: ("Medal Gate", "Medal King's Gate", 19),        # boss room = KingSlime decision room
    0x42: ("Gate of Labyrinth", "Gate 14 - Labyrinth", 23),
    0x43: ("Gate of Judgement", "Gate 15 - Judgement", 25),
    0x44: ("Library Gate", "Library Gate", 25),
    0x45: ("Gate of Reflection", "Gate 16 - Reflection", 29),
    0x46: ("Gate of Ambition", "Gate 17 - Ambition", 30),
    0x47: ("Gate of Demolition", "Gate 18 - Demolition", 29),
    0x48: ("Gate of Mastermind", "Gate 19 - Mastermind", 27),
    0x49: ("Gate of Control", "Gate 20 - Control", 30),
    0x4A: ("Gate of Extinction", "Gate 21 - Extinction", 30),
    0x4B: ("Gate of Sleep", "Gate 22 - Sleep", 30),
    0x4C: ("Bazaar Edge Gate", "Bazaar Gate 2", 30),
    0x4D: ("Arena - Right Gate", "Goopi's Gate 2", 27),
    0x4E: ("Old Man's Gate", "Grandpa's Gate", 30),
    0x4F: ("Unused Gate", "??? (99 floors)", 99),
}


def derive(rom: bytes) -> dict:
    base = GATE_TABLE_BANK * 0x4000 + GATE_TABLE_ADDR - 0x4000
    gates, problems = [], []
    for g in range(32):
        row = rom[base + g * GATE_ROW: base + (g + 1) * GATE_ROW]
        ft1, ft2, ft3, last, boss, _sx, _sy, tier = row
        if boss not in BOSS_MAP_TO_GATE:
            problems.append(f"gate {g}: boss map ${boss:02X} not in the name table")
            continue
        name, faq, faq_levels = BOSS_MAP_TO_GATE[boss]
        if faq_levels != last:
            problems.append(f"gate {g} ({name}): ROM floors {last} != FAQ Levels {faq_levels}")
        gates.append({
            "id": g,
            "name": name,
            "faq_name": faq,
            "floors": last,
            "boss_map": f"0x{boss:02X}",
            "boss_room": MAP_NAMES.get(boss, f"map ${boss:02X}"),
            "floor_types": [ft1, ft2, ft3],
            "depth_tier": tier,
        })
    if len({x["boss_map"] for x in gates}) != len(gates):
        problems.append("two gates share a boss map")
    if problems:
        raise SystemExit("map_gate_names: ROM/FAQ disagreement:\n  " + "\n  ".join(problems))
    return {
        "_generator": "tools/map_gate_names.py (S100) from data/DWM-original.gbc "
                      "GateFloorDataTable $16:$70A6 (floors byte 3 + boss map byte 4), "
                      "cross-checked vs FULL_FAQ.txt 'Levels:'",
        "gates": gates,
    }


def load_names(path=OUT) -> dict:
    """{gate id: name} from gate_names.json (any historical shape)."""
    gn = json.loads(Path(path).read_text())
    if isinstance(gn, dict) and "gates" in gn:
        return {x["id"]: x["name"] for x in gn["gates"]}
    if isinstance(gn, list):
        return {i: (g.get("name") if isinstance(g, dict) else str(g)) for i, g in enumerate(gn)}
    return {int(k): v for k, v in gn.items() if not str(k).startswith("_")}


def main():
    rom = ROM_PATH.read_bytes()
    data = derive(rom)
    text = json.dumps(data, indent=1) + "\n"
    if "--check" in sys.argv or "--selftest" in sys.argv:
        if not OUT.exists() or OUT.read_text() != text:
            raise SystemExit("map_gate_names --check: extracted/gate_names.json is stale")
        print("map_gate_names --check: OK (32 gates, ROM floors == FAQ, boss maps unique)")
        return
    OUT.write_text(text)
    for x in data["gates"]:
        print(f"{x['id']:3d}  {x['floors']:3d} fl  boss {x['boss_map']}  {x['name']}")
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
