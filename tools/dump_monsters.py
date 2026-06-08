"""Dump the 221-entry monster info table at 03:4461 (43 bytes each)."""
import json
from pathlib import Path
from dwm.rom import ROM

FAMILY = ["Slime", "Dragon", "Beast", "Flying", "Plant",
          "Bug", "Devil", "Zombie", "Material", "???"]
FEMALE_PCT = {0: "0%", 1: "10%", 2: "50%", 3: "84%"}

def parse(raw: bytes, idx: int) -> dict:
    assert len(raw) == 43
    return {
        "id": idx,
        "family": FAMILY[raw[0]] if raw[0] < len(FAMILY) else f"?{raw[0]}",
        "level_cap": raw[1],
        "exp_table": raw[2],
        "female_ratio": FEMALE_PCT.get(raw[3], f"?{raw[3]}"),
        "byte_04": raw[4],
        "byte_05": raw[5],
        "base_skills": [raw[6], raw[7], raw[8]],
        "bytes_09_0E": list(raw[0x09:0x0F]),
        "resistances": list(raw[0x0F:0x2A]),  # 27 bytes
        "byte_2A": raw[0x2A],
    }

def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    names = {n["id"]: n["name"] for n in
             json.loads(Path("extracted/monster_names.json").read_text())}

    monsters = []
    for i in range(221):
        raw = rom.read(0x03, 0x4461 + i * 43, 43)
        m = parse(raw, i)
        m["name"] = names.get(i, f"#{i:02X}")
        monsters.append(m)

    Path("extracted/monsters.json").write_text(json.dumps(monsters, indent=2))
    print(f"Dumped {len(monsters)} monster stat blocks")
    for m in monsters[:8]:
        print(f"  {m['id']:3d}  {m['name']:<12s}  fam={m['family']:<8s} "
              f"cap={m['level_cap']:3d}  skills={m['base_skills']}")

if __name__ == "__main__":
    main()
