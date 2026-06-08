"""Dump all encounter pools: gate -> floor -> monsters with probabilities.

Reads encounter data directly from the ROM using verified addresses.

Usage:
  uv run python -m tools.dump_encounters
"""

import json
from pathlib import Path
from dwm.rom import ROM
from dwm.text import decode

rom = ROM(Path("data/DWM-original.gbc"))

# ── Constants ──────────────────────────────────────────────────
POOL_BLOCK_SIZE   = 26
ENEMY_STATS_BANK  = 0x14
ENEMY_STATS_START = 0x4C1D
ENEMY_STATS_SIZE  = 25
NAME_PTR_BANK     = 0x41
NAME_PTR_OFFSET   = 0x4339

GATE_NAMES = {
    0:  "Gate of Beginning",
    1:  "Gate of Villager",
    2:  "Gate of Talisman",
    3:  "Gate of Memories",
    4:  "Gate of Bewilder",
    5:  "Bazaar Gate",
    6:  "Gate of Peace",
    7:  "Gate of Bravery",
    8:  "Well Gate",
    9:  "Gate of Strength",
    10: "Gate of Anger",
    11: "Farm Gate",
    12: "Arena - Left Gate",
    13: "Gate of Joy",
    14: "Gate of Wisdom",
    15: "Medal Gate",
    16: "Gate of Happiness",
    17: "Gate of Temptation",
    18: "Gate of Labyrinth",
    19: "Gate of Judgement",
    20: "Library Gate",
    21: "Gate of Reflection",
    22: "Gate of Ambition",
    23: "Gate of Demolition",
    24: "Gate of Mastermind",
    25: "Gate of Control",
    26: "Gate of Extinction",
    27: "Gate of Sleep",
    28: "Bazaar Edge Gate",
    29: "Arena - Right Gate",
    30: "Old Man's Gate",
    31: "Unused Gate (99 Floors)",
}

NUM_GATES = 32

# ── Load monster names ─────────────────────────────────────────
def load_monster_names():
    names = {}
    for i in range(256):
        ptr_bytes = rom.read(NAME_PTR_BANK, NAME_PTR_OFFSET + i * 2, 2)
        ptr = ptr_bytes[0] | (ptr_bytes[1] << 8)
        if ptr < 0x4000 or ptr > 0x7FFF:
            names[i] = f"???#{i:02X}"
            continue
        raw = rom.read_until(NAME_PTR_BANK, ptr, 0xF0)
        name, _ = decode(raw)
        names[i] = name
    return names

MONSTER_NAMES = load_monster_names()


# ── Read enemy stats ───────────────────────────────────────────
def get_species_id(enemy_stats_id):
    offset = ENEMY_STATS_START + enemy_stats_id * ENEMY_STATS_SIZE
    if offset > 0x7FFF:
        return None
    try:
        return rom.read(ENEMY_STATS_BANK, offset, 1)[0]
    except Exception:
        return None

def get_enemy_stats_detail(enemy_stats_id):
    offset = ENEMY_STATS_START + enemy_stats_id * ENEMY_STATS_SIZE
    if offset > 0x7FFF:
        return None
    try:
        data = rom.read(ENEMY_STATS_BANK, offset, ENEMY_STATS_SIZE)
    except Exception:
        return None
    return {
        "species_id": data[0],
        "species_name": MONSTER_NAMES.get(data[0], f"???#{data[0]:02X}"),
        "level": data[4],
        "hp": data[5] | (data[6] << 8),
        "mp": data[7] | (data[8] << 8),
        "atk": data[9] | (data[10] << 8),
        "def": data[11] | (data[12] << 8),
        "agl": data[13] | (data[14] << 8),
        "int": data[15] | (data[16] << 8),
    }


# ── Read gate index structures ────────────────────────────────
pool_offsets = list(rom.read(0x01, 0x6A22, NUM_GATES))

thresholds_per_gate = {}
for gate in range(NUM_GATES):
    ptr_bytes = rom.read(0x01, 0x6A42 + gate * 2, 2)
    ptr = ptr_bytes[0] | (ptr_bytes[1] << 8)
    vals = []
    for j in range(20):
        b = rom.read(0x01, ptr + j, 1)[0]
        if b == 0xFF:
            break
        vals.append(b)
    thresholds_per_gate[gate] = vals


# ── Calculate total pools needed ──────────────────────────────
max_pool_index = 0
for gate in range(NUM_GATES):
    base = pool_offsets[gate]
    num_groups = len(thresholds_per_gate.get(gate, [])) + 1
    max_pool_index = max(max_pool_index, base + num_groups - 1)

NUM_POOLS = max_pool_index + 1
print(f"Total encounter pool blocks: {NUM_POOLS}")


# ── Read all pool blocks ──────────────────────────────────────
def read_pool_block(index):
    offset = 0x6AAE + index * POOL_BLOCK_SIZE
    if offset > 0x7FFF:
        return None
    try:
        data = rom.read(0x01, offset, POOL_BLOCK_SIZE)
    except Exception:
        return None
    flat = rom.addr(0x01, offset)

    slots = []
    for i in range(4):
        eid = data[10 + i * 2] | (data[11 + i * 2] << 8)
        weight = data[20 + i]
        if weight == 0 and eid == 0:
            continue
        species = get_species_id(eid)
        species_name = MONSTER_NAMES.get(species, "???") if species is not None else "???"
        flat_eid_offset = rom.addr(0x01, offset + 10 + i * 2)
        slots.append({
            "enemy_stats_id": eid,
            "species_id": species,
            "monster_name": species_name,
            "weight": weight,
            "rom_offset": f"0x{flat_eid_offset:05X}",
        })

    return {
        "pool_index": index,
        "flat_offset": f"0x{flat:05X}",
        "enc_rate": data[0],
        "floor_level": data[1],
        "raw": data.hex(),
        "monster_slots": slots,
    }

all_pools = {}
for idx in range(NUM_POOLS):
    block = read_pool_block(idx)
    if block:
        all_pools[idx] = block


# ── Map gates to pools ────────────────────────────────────────
gate_encounters = {}
for gate in range(NUM_GATES):
    base_offset = pool_offsets[gate]
    thresholds = thresholds_per_gate.get(gate, [])
    floor_groups = []
    num_groups = len(thresholds) + 1

    for g in range(num_groups):
        pool_idx = base_offset + g
        if g == 0:
            floor_range = f"Floors 1-{thresholds[0]}" if thresholds else "All floors"
        elif g < len(thresholds):
            floor_range = f"Floors {thresholds[g-1]+1}-{thresholds[g]}"
        else:
            floor_range = f"Floors {thresholds[g-1]+1}+"

        pool = all_pools.get(pool_idx)
        if pool:
            floor_groups.append({
                "floor_range": floor_range,
                "pool_index": pool_idx,
                "monsters": pool["monster_slots"],
            })

    gate_encounters[gate] = {
        "name": GATE_NAMES.get(gate, f"Gate {gate}"),
        "floor_groups": floor_groups,
    }


# ── Print ─────────────────────────────────────────────────────
print("=" * 80)
print("DWM1 ENCOUNTER POOL TABLE")
print("=" * 80)

for gate in range(NUM_GATES):
    info = gate_encounters[gate]
    if not info["floor_groups"]:
        continue
    print(f"\n{'─' * 80}")
    print(f"  GATE {gate}: {info['name']}")
    print(f"{'─' * 80}")
    for fg in info["floor_groups"]:
        print(f"\n  {fg['floor_range']} (pool #{fg['pool_index']}):")
        total_weight = sum(m["weight"] for m in fg["monsters"])
        for m in fg["monsters"]:
            pct = f"{m['weight']/total_weight*100:.0f}%" if total_weight > 0 else "?"
            stats = get_enemy_stats_detail(m["enemy_stats_id"])
            lvl = f"Lv{stats['level']}" if stats else "?"
            print(f"    {m['monster_name']:<12s}  {pct:>4s}  {lvl:>5s}  "
                  f"(eid={m['enemy_stats_id']:3d}, species=0x{m['species_id']:02X})  "
                  f"ROM: {m['rom_offset']}")

print(f"\n{'=' * 80}")

# ── Save JSON ─────────────────────────────────────────────────
out = Path("extracted/encounters.json")
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(gate_encounters, indent=2))
print(f"\nFull data saved to {out}")
print(f"\nTo change a monster, edit the enemy_stats_id at the ROM offset shown.")
print(f'Example edits.json: "raw_bytes": {{ "0x6AB8": "07" }}')
