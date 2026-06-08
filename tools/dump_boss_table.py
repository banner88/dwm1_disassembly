"""Dump the full boss table (4 bytes per gate) from ROM.

Boss table at $14:$4897, stride 4 bytes per gate.
Byte 0 = boss fight EID (confirmed via watchpoint)
Byte 1 = always $00
Bytes 2-3 = join EID (16-bit LE) — monster that joins party after defeat

Usage:
  uv run python -m tools.dump_boss_table
"""

import json
from pathlib import Path
from dwm.rom import ROM
from dwm.text import decode

rom = ROM(Path("data/DWM-original.gbc"))

BOSS_TABLE_BANK = 0x14
BOSS_TABLE_OFFSET = 0x4897
BOSS_TABLE_STRIDE = 4
NUM_GATES = 33  # 32 real entries (0-31) + 1 cut content entry (32)

ENEMY_STATS_BANK = 0x14
ENEMY_STATS_START = 0x4C1D
ENEMY_STATS_SIZE = 25
NAME_PTR_BANK = 0x41
NAME_PTR_OFFSET = 0x4339

GATE_NAMES = {
    0:  "Gate of Beginning",     1:  "Gate of Villager",
    2:  "Gate of Talisman",      3:  "Gate of Memories",
    4:  "Gate of Bewilder",      5:  "Bazaar Gate",
    6:  "Gate of Peace",         7:  "Gate of Bravery",
    8:  "Well Gate",             9:  "Gate of Strength",
    10: "Gate of Anger",         11: "Farm Gate",
    12: "Gate of Joy",           13: "Gate of Wisdom",
    14: "Arena - Left Gate",     15: "Gate of Happiness",
    16: "Gate of Temptation",    17: "Medal Gate",
    18: "Gate of Labyrinth",     19: "Gate of Judgement",
    20: "Library Gate",          21: "Gate of Reflection",
    22: "Gate of Ambition",
    23: "Gate of Demolition (Hargon)",
    24: "Gate of Demolition (Sidoh)",
    25: "Gate of Mastermind",    26: "Gate of Control",
    27: "Gate of Extinction",    28: "Gate of Sleep",
    29: "Bazaar Edge Gate",      30: "Arena - Right Gate",
    31: "Old Man's Gate",        32: "Cut Content",
}

BOSS_FLOOR_BANK = 0x16
BOSS_FLOOR_OFFSET = 0x70A6
BOSS_FLOOR_STRIDE = 8


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


def get_enemy_stats(eid):
    offset = ENEMY_STATS_START + eid * ENEMY_STATS_SIZE
    if offset + ENEMY_STATS_SIZE > 0x8000:
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


def get_boss_floor_data(gate):
    offset = BOSS_FLOOR_OFFSET + gate * BOSS_FLOOR_STRIDE
    try:
        return rom.read(BOSS_FLOOR_BANK, offset, BOSS_FLOOR_STRIDE)
    except Exception:
        return bytes(BOSS_FLOOR_STRIDE)  # zeros if out of range


print(f"{'=' * 120}")
print(f"BOSS TABLE at $14:${BOSS_TABLE_OFFSET:04X} (flat 0x{rom.addr(BOSS_TABLE_BANK, BOSS_TABLE_OFFSET):05X})")
print(f"{'=' * 120}")
print()
print(f"{'Gate':>4s}  {'Gate Name':<22s}  {'Fight EID':>9s}  {'Boss Species':<14s}  {'Lv':>3s}  "
      f"{'Join EID':>8s}  {'Join Species':<14s}  {'Lv':>3s}  {'Floors':>6s}  {'Raw'}")
print("-" * 120)

boss_table = []
for gate in range(NUM_GATES):
    offset = BOSS_TABLE_OFFSET + gate * BOSS_TABLE_STRIDE
    data = rom.read(BOSS_TABLE_BANK, offset, BOSS_TABLE_STRIDE)
    flat = rom.addr(BOSS_TABLE_BANK, offset)

    fight_eid = data[0]
    byte1 = data[1]
    join_eid = data[2] | (data[3] << 8)

    fight_stats = get_enemy_stats(fight_eid)
    join_stats = get_enemy_stats(join_eid)

    floor_data = get_boss_floor_data(gate)
    floor_count = floor_data[3]

    fight_name = fight_stats["species_name"] if fight_stats else "???"
    fight_lv = fight_stats["level"] if fight_stats else 0
    join_name = join_stats["species_name"] if join_stats else "???"
    join_lv = join_stats["level"] if join_stats else 0
    gate_name = GATE_NAMES.get(gate, f"Gate {gate}")

    print(f"{gate:4d}  {gate_name:<22s}  {fight_eid:4d}(0x{fight_eid:02X})  {fight_name:<14s}  {fight_lv:>3}  "
          f"{join_eid:4d}(0x{join_eid:02X})  {join_name:<14s}  {join_lv:>3}  {floor_count:>6d}  "
          f"{data.hex()}")

    boss_table.append({
        "gate": gate,
        "gate_name": gate_name,
        "fight_eid": fight_eid,
        "fight_species": fight_name,
        "fight_level": fight_lv,
        "join_eid": join_eid,
        "join_species": join_name,
        "join_level": join_lv,
        "byte1": byte1,
        "floor_count": floor_count,
        "flat_offset": f"0x{flat:05X}",
        "fight_stats": fight_stats,
        "join_stats": join_stats,
    })

out = Path("extracted/boss_table.json")
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(boss_table, indent=2))
print(f"\nSaved to {out}")

print(f"\nBoss table: {BOSS_TABLE_STRIDE} bytes/gate at $14:${BOSS_TABLE_OFFSET:04X}")
print(f"  Byte 0: fight EID")
print(f"  Byte 1: always 0x00")
print(f"  Bytes 2-3: join EID (16-bit LE)")
print(f"\nFloor array: {BOSS_FLOOR_STRIDE} bytes/gate at $16:${BOSS_FLOOR_OFFSET:04X}")
print(f"  Byte 3: floor count  |  Byte 4: boss room map_type")
