"""Derive internal gate ID → gate name mapping by matching ROM boss data to known FAQ data.

Each gate has a unique boss (except Gate of Demolition which has Hargon then Sidoh).
We use the boss species as a key to match ROM gate IDs to real gate names.

Usage:
  uv run python -m tools.map_gate_names
"""

import json
from pathlib import Path
from dwm.rom import ROM
from dwm.text import decode

rom = ROM(Path("data/DWM-original.gbc"))

BOSS_TABLE_BANK = 0x14
BOSS_TABLE_OFFSET = 0x4897
BOSS_TABLE_STRIDE = 4
ENEMY_STATS_START = 0x4C1D
ENEMY_STATS_SIZE = 25
NAME_PTR_BANK = 0x41
NAME_PTR_OFFSET = 0x4339
BOSS_FLOOR_BANK = 0x16
BOSS_FLOOR_OFFSET = 0x70A6

def load_monster_names():
    names = {}
    for i in range(256):
        ptr_bytes = rom.read(NAME_PTR_BANK, NAME_PTR_OFFSET + i * 2, 2)
        ptr = ptr_bytes[0] | (ptr_bytes[1] << 8)
        if ptr < 0x4000 or ptr > 0x7FFF:
            continue
        raw = rom.read_until(NAME_PTR_BANK, ptr, 0xF0)
        name, _ = decode(raw)
        names[i] = name
    return names

NAMES = load_monster_names()

# Definitive FAQ: gate name → boss species name
# This mapping is confirmed correct by the user
BOSS_TO_GATE = {
    "Healer":    "Gate of Beginning",
    "Dragon":    "Gate of Villager",
    "Golem":     "Gate of Talisman",
    "MadKnight": "Bazaar Gate",
    "MadCat":    "Gate of Memories",
    "FaceTree":  "Gate of Bewilder",
    "FangSlime": "Gate of Peace",
    "BigEye":    "Gate of Bravery",
    "Gigantes":  "Well Gate",
    "BattleRex": "Gate of Anger",
    "StoneMan":  "Gate of Strength",
    "Copycat":   "Farm Gate",
    "Digster":   "Arena - Left Gate",
    "FunkyBird": "Gate of Joy",
    "SkyDragon": "Gate of Wisdom",
    "KingSlime": "Medal Gate",
    "Jamirus":   "Gate of Happiness",
    "Servant":   "Gate of Temptation",
    "DarkHorn":  "Gate of Labyrinth",
    "Akubar":    "Gate of Judgement",
    "Orochi":    "Library Gate",
    "Durran":    "Gate of Reflection",
    "DracoLord": "Gate of Ambition",
    "Hargon":    "Gate of Demolition",
    "Sidoh":     "Gate of Demolition",  # second boss, same gate
    "Baramos":   "Gate of Mastermind",
    "Zoma":      "Gate of Control",
    "Pizzaro":   "Gate of Extinction",
    "Esterk":    "Gate of Sleep",
    "Mirudraas": "Bazaar Edge Gate",
    "Mudou":     "Arena - Right Gate",
    "DeathMore": "Old Man's Gate",
}

# Read all 32 boss table entries and match
print(f"{'ID':>3s}  {'Boss Species':<14s}  {'Lv':>3s}  {'Fl':>3s}  {'Gate Name (derived)'}")
print("-" * 60)

gate_names = {}
for gate in range(32):
    # Read boss entry
    data = rom.read(BOSS_TABLE_BANK, BOSS_TABLE_OFFSET + gate * 4, 4)
    fight_eid = data[0]

    # Get species
    es_offset = ENEMY_STATS_START + fight_eid * ENEMY_STATS_SIZE
    es_data = rom.read(BOSS_TABLE_BANK, es_offset, ENEMY_STATS_SIZE)
    species_id = es_data[0]
    species_name = NAMES.get(species_id, f"???#{species_id:02X}")
    level = es_data[4]

    # Get floor count
    fl_data = rom.read(BOSS_FLOOR_BANK, BOSS_FLOOR_OFFSET + gate * 8, 8)
    floors = fl_data[3]

    # Match to gate name
    gate_name = BOSS_TO_GATE.get(species_name)
    if gate_name and gate == 31 and floors == 99:
        gate_name = "Unused Gate (99 Floors)"
    elif gate_name == "Gate of Demolition":
        # Distinguish first and second boss
        if species_name == "Hargon":
            gate_name = "Gate of Demolition (Hargon)"
        else:
            gate_name = "Gate of Demolition (Sidoh)"
    elif gate_name is None:
        gate_name = f"??? (boss={species_name})"

    gate_names[gate] = gate_name
    print(f"{gate:3d}  {species_name:<14s}  {level:>3d}  {floors:>3d}  {gate_name}")

# Save
out = Path("extracted/gate_names.json")
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(gate_names, indent=2))
print(f"\nSaved to {out}")

# Generate Python dict for editor
print("\n# For editor.py GATE_NAMES:")
print("GATE_NAMES = {")
for gate in range(32):
    print(f'    {gate}: "{gate_names[gate]}",')
print("}")
