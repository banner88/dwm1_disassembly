"""Dump complete enemy stats table: every enemy_stats_id with species, level, stats.

This gives the encounter editor access to ALL monsters (bosses, specials, etc.),
not just the ~198 that appear in wild encounter pools.

Usage:
  uv run python -m tools.dump_enemy_stats
"""

import json
from pathlib import Path
from dwm.rom import ROM
from dwm.text import decode

rom = ROM(Path("data/DWM-original.gbc"))

# ── Constants ──────────────────────────────────────────────────
ENEMY_STATS_BANK  = 0x14
ENEMY_STATS_START = 0x4C1D
ENEMY_STATS_SIZE  = 25
NAME_PTR_BANK     = 0x41
NAME_PTR_OFFSET   = 0x4339


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


# ── Scan all enemy stats entries ───────────────────────────────
entries = []
eid = 0
max_entries = 600  # safety limit

while eid < max_entries:
    offset = ENEMY_STATS_START + eid * ENEMY_STATS_SIZE
    if offset + ENEMY_STATS_SIZE > 0x8000:
        break

    try:
        data = rom.read(ENEMY_STATS_BANK, offset, ENEMY_STATS_SIZE)
    except Exception:
        break

    # Check for table end: delimiter at byte 24 should be 0xFF
    # If species_id is 0 and all stats are 0, we've likely hit padding
    species_id = data[0]
    level = data[4]
    hp = data[5] | (data[6] << 8)
    delimiter = data[24]

    # Stop if we hit a clearly invalid entry (no 0xFF delimiter)
    if delimiter != 0xFF:
        print(f"  EID {eid}: no 0xFF delimiter (got 0x{delimiter:02X}), stopping scan")
        break

    # Full 25-byte layout (verified 487/487 vs ROM, DOC_AUDIT/TOOLS_AND_DATA):
    #   +0 species_id, +1..+2 exp_reward LE16, +3 joinability (0-7),
    #   +4 level, +5..+16 hp/mp/atk/def/agl/int LE16, +17..+20 ai_weights[4],
    #   +21..+24 skills[4] (skills[3] always $FF = table delimiter)
    entry = {
        "enemy_stats_id": eid,
        "species_id": species_id,
        "exp_reward": data[1] | (data[2] << 8),
        "level": level,
        "hp": hp,
        "mp": data[7] | (data[8] << 8),
        "atk": data[9] | (data[10] << 8),
        "def": data[11] | (data[12] << 8),
        "agl": data[13] | (data[14] << 8),
        "int": data[15] | (data[16] << 8),
        "ai_weights": list(data[17:21]),
        "skills": list(data[21:25]),
        "species_name": MONSTER_NAMES.get(species_id, f"???#{species_id:02X}"),
        "joinability": data[3],
    }
    entries.append(entry)
    eid += 1

print(f"Found {len(entries)} enemy stats entries")

# ── Print summary ─────────────────────────────────────────────
print(f"\n{'EID':>4s}  {'Species':>4s}  {'Name':<14s}  {'Lv':>3s}  {'HP':>5s}  {'MP':>5s}  "
      f"{'ATK':>5s}  {'DEF':>5s}  {'AGL':>5s}  {'INT':>5s}  {'ROM Offset'}")
print("─" * 90)
for e in entries:
    print(f"{e['enemy_stats_id']:4d}  0x{e['species_id']:02X}  {e['species_name']:<14s}  "
          f"{e['level']:3d}  {e['hp']:5d}  {e['mp']:5d}  "
          f"{e['atk']:5d}  {e['def']:5d}  {e['agl']:5d}  {e['int']:5d}  "
          f"{e['flat_offset']}")

# ── Save JSON ─────────────────────────────────────────────────
out = Path("extracted/enemy_stats.json")
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(entries, indent=2))
print(f"\nSaved to {out}")
print(f"\nThis file is used by the encounter editor for full monster dropdowns.")
print(f"Re-run after any enemy stats changes to keep it current.")
