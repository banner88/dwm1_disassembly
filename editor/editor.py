"""DWM1 editor with encounter pools, starter monster, and byte-budget-aware text editing."""
import json
import subprocess
import sys
from pathlib import Path
import streamlit as st

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dwm.text import encode

EDITS = Path("extracted/edits.json")
MONSTERS = Path("extracted/monsters.json")
NAMES = Path("extracted/monster_names.json")
BLOBS = Path("extracted/text_blobs.json")
TABLES = Path("extracted/all_text.json")
FREE = Path("extracted/free_space.json")
ENCOUNTERS = Path("extracted/encounters.json")

# ── Gate reference (from gate_reference.py) ────────────────────
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
    31: "Old Man's Gate",
}

GATE_BOSSES = {
    0: "Healer",  1: "Dragon",  2: "Golem",  3: "MadCat",
    4: "FaceTree",  5: "MadKnight",  6: "FangSlime",  7: "BigEye",
    8: "Gigantes",  9: "StoneMan",  10: "BattleRex",  11: "Copycat",
    12: "FunkyBird",  13: "SkyDragon",  14: "Digster",  15: "Jamirus",
    16: "Servant",  17: "KingSlime",  18: "DarkHorn",  19: "Akubar",
    20: "Orochi",  21: "Durran",  22: "DracoLord",  23: "Hargon",
    24: "Sidoh",  25: "Baramos",  26: "Zoma",  27: "Pizzaro",
    28: "Esterk",  29: "Mirudraas",  30: "Mudou",  31: "DeathMore",
}

# ── Starter monster ROM offsets ────────────────────────────────
STARTER_BASE = 0x50C36
STARTER_OFFSETS = {
    "species":  (0x50C36, 1),
    "level":    (0x50C3A, 1),
    "hp":       (0x50C3B, 2),
    "mp":       (0x50C3D, 2),
    "atk":      (0x50C3F, 2),
    "def":      (0x50C41, 2),
    "agl":      (0x50C43, 2),
    "int":      (0x50C45, 2),
}

STARTER_DEFAULTS = {
    "species": 0x08, "level": 1, "hp": 30, "mp": 0,
    "atk": 10, "def": 6, "agl": 5, "int": 1,
}

# ── Encounter block constants ─────────────────────────────────
POOL_BLOCK_BASE = 0x6AAE
POOL_BLOCK_SIZE = 26

# ── Boss table constants ──────────────────────────────────────
BOSS_TABLE_BASE = 0x50897   # flat ROM offset, $14:$4897
BOSS_TABLE_STRIDE = 4       # 4 bytes per gate: [fight_eid, 0x00, join_eid_lo, join_eid_hi]
BOSS_EIDS_ORIGINAL = {
    0: 11, 1: 31, 2: 32, 3: 51, 4: 53, 5: 55, 6: 75, 7: 77,
    8: 79, 9: 99, 10: 101, 11: 103, 12: 123, 13: 125, 14: 127,
    15: 147, 16: 149, 17: 153, 18: 175, 19: 177, 20: 179, 21: 199,
    22: 201, 23: 203, 24: 205, 25: 207, 26: 209, 27: 211, 28: 213,
    29: 215, 30: 217, 31: 219,
}
# Join EID = bytes 2-3 (16-bit LE) of each 4-byte boss entry
BOSS_JOIN_ORIGINAL = {
    0: 12, 1: 484, 2: 485, 3: 52, 4: 54, 5: 56, 6: 76, 7: 78,
    8: 80, 9: 100, 10: 102, 11: 104, 12: 124, 13: 126, 14: 128,
    15: 148, 16: 150, 17: 154, 18: 176, 19: 178, 20: 180, 21: 200,
    22: 202, 23: 204, 24: 206, 25: 208, 26: 210, 27: 212, 28: 214,
    29: 216, 30: 218, 31: 220,
}

# ── Enemy stats table constants ───────────────────────────────
ENEMY_STATS_ROM_BASE = 0x50C1D   # flat ROM offset of EID 0
ENEMY_STATS_ENTRY_SIZE = 25
# Offsets within each 25-byte entry
ES_SPECIES = 0
ES_LEVEL   = 4
ES_HP      = 5   # 2 bytes LE
ES_MP      = 7   # 2 bytes LE
ES_ATK     = 9   # 2 bytes LE
ES_DEF     = 11  # 2 bytes LE
ES_AGL     = 13  # 2 bytes LE
ES_INT     = 15  # 2 bytes LE

# ── Helpers ────────────────────────────────────────────────────

@st.cache_data
def load(path: Path):
    return json.loads(path.read_text())

def load_edits() -> dict:
    if EDITS.exists():
        return json.loads(EDITS.read_text())
    return {"monster_stats": {}, "text": {}, "raw_bytes": {}}

def save_edits(edits: dict):
    # Backup before overwriting
    if EDITS.exists():
        backup = EDITS.with_suffix(".json.bak")
        import shutil
        shutil.copy2(EDITS, backup)
    EDITS.write_text(json.dumps(edits, indent=2))

def le16(value: int) -> str:
    """Convert int to 2-byte little-endian hex string for raw_bytes."""
    lo = value & 0xFF
    hi = (value >> 8) & 0xFF
    return f"{lo:02X} {hi:02X}"

def hex_offset(offset: int) -> str:
    """Format flat offset as 0x-prefixed hex string for edits.json keys."""
    return f"0x{offset:05X}"


# ── Build EID master list ──────────────────────────────────────
ENEMY_STATS_FILE = Path("extracted/enemy_stats.json")

@st.cache_data
def build_eid_lookup():
    """Build lookup of all enemy_stats_ids → monster info.

    Prefers extracted/enemy_stats.json (full table from dump_enemy_stats.py).
    Falls back to encounters.json (only wild encounter monsters).
    """
    lookup = {}

    # Primary source: full enemy stats dump (has bosses, specials, everything)
    if ENEMY_STATS_FILE.exists():
        for e in json.loads(ENEMY_STATS_FILE.read_text()):
            eid = e["enemy_stats_id"]
            lookup[eid] = {
                "name": e["species_name"],
                "species_id": e["species_id"],
                "level": e.get("level"),
                "hp": e.get("hp"),
                "atk": e.get("atk"),
            }
        return lookup

    # Fallback: encounters.json (wild pool monsters only, ~198)
    if ENCOUNTERS.exists():
        enc = json.loads(ENCOUNTERS.read_text())
        for gate_data in enc.values():
            for fg in gate_data.get("floor_groups", []):
                for m in fg.get("monsters", []):
                    eid = m["enemy_stats_id"]
                    if eid not in lookup:
                        lookup[eid] = {
                            "name": m["monster_name"],
                            "species_id": m["species_id"],
                        }
    return lookup


@st.cache_data
def load_orphan_ptrs() -> dict:
    p = Path("extracted/orphan_pointers.json")
    if not p.exists(): return {}
    data = json.loads(p.read_text())
    out = {}
    for loc, info in data.get("confident", {}).items():
        if info["confident"]:
            out[loc] = info["confident"][0]["operand_at"]
    return out

orphan_ptrs = load_orphan_ptrs()

def find_ptr_location(loc: str, tables: dict) -> str | None:
    for t in tables["tables"]:
        for entry in t["entries"]:
            if entry["target_offset"] == loc:
                return entry["ptr_location"]
    return orphan_ptrs.get(loc)


# ── Get current value (check edits first, fall back to default) ──

def get_raw_byte_edit(offset_hex: str, edits: dict) -> str | None:
    """Check if there's a raw_bytes edit at the given hex offset."""
    return edits.get("raw_bytes", {}).get(offset_hex)


def get_current_starter_value(field: str, edits: dict) -> int:
    """Get current starter monster value, checking edits first."""
    offset, size = STARTER_OFFSETS[field]
    key = hex_offset(offset)
    edit_val = get_raw_byte_edit(key, edits)
    if edit_val is not None:
        # Parse hex string back to int (little-endian for 2-byte)
        parts = edit_val.strip().split()
        if size == 1:
            return int(parts[0], 16)
        else:
            return int(parts[0], 16) | (int(parts[1], 16) << 8)
    return STARTER_DEFAULTS[field]


def get_current_eid_for_slot(pool_index: int, slot: int, edits: dict, original_eid: int) -> int:
    """Get current enemy_stats_id for an encounter slot, checking edits."""
    offset = POOL_BLOCK_BASE + pool_index * POOL_BLOCK_SIZE + 10 + slot * 2
    key = hex_offset(offset)
    edit_val = get_raw_byte_edit(key, edits)
    if edit_val is not None:
        parts = edit_val.strip().split()
        return int(parts[0], 16) | (int(parts[1], 16) << 8)
    return original_eid


def get_current_weight_for_slot(pool_index: int, slot: int, edits: dict, original_weight: int) -> int:
    """Get current weight for an encounter slot, checking edits."""
    offset = POOL_BLOCK_BASE + pool_index * POOL_BLOCK_SIZE + 20 + slot
    key = hex_offset(offset)
    edit_val = get_raw_byte_edit(key, edits)
    if edit_val is not None:
        return int(edit_val.strip(), 16)
    return original_weight


def es_flat_offset(eid: int, field_offset: int) -> int:
    """Flat ROM offset for a field within enemy stats entry."""
    return ENEMY_STATS_ROM_BASE + eid * ENEMY_STATS_ENTRY_SIZE + field_offset

def get_current_es_value(eid: int, field_offset: int, size: int, edits: dict, default: int) -> int:
    """Get current value for an enemy stats field, checking edits first."""
    key = hex_offset(es_flat_offset(eid, field_offset))
    edit_val = get_raw_byte_edit(key, edits)
    if edit_val is not None:
        parts = edit_val.strip().split()
        if size == 1:
            return int(parts[0], 16)
        else:
            return int(parts[0], 16) | (int(parts[1], 16) << 8)
    return default

@st.cache_data
def load_enemy_stats_data():
    """Load the full enemy stats dump."""
    if not ENEMY_STATS_FILE.exists():
        return []
    return json.loads(ENEMY_STATS_FILE.read_text())

def get_effective_es(eid: int, edits: dict, es_data: list) -> dict:
    """Get effective stats for an EID, applying any raw_bytes edits on top of dump data."""
    # Base from dump
    base = {}
    if eid < len(es_data):
        base = es_data[eid]
    else:
        base = {"species_id": 0, "species_name": "???", "level": 0,
                "hp": 0, "mp": 0, "atk": 0, "def": 0, "agl": 0, "int": 0}

    result = dict(base)
    # Apply any edits
    for field, foff, size in [
        ("species_id", ES_SPECIES, 1), ("level", ES_LEVEL, 1),
        ("hp", ES_HP, 2), ("mp", ES_MP, 2), ("atk", ES_ATK, 2),
        ("def", ES_DEF, 2), ("agl", ES_AGL, 2), ("int", ES_INT, 2),
    ]:
        key = hex_offset(es_flat_offset(eid, foff))
        edit_val = edits.get("raw_bytes", {}).get(key)
        if edit_val is not None:
            parts = edit_val.strip().split()
            if size == 1:
                result[field] = int(parts[0], 16)
            else:
                result[field] = int(parts[0], 16) | (int(parts[1], 16) << 8)
    # Update species name if species was changed
    if result["species_id"] != base.get("species_id"):
        result["species_name"] = names.get(result["species_id"], f"???#{result['species_id']:02X}")
    return result

def eid_effective_label(eid: int, edits: dict, es_data: list) -> str:
    """Build a dropdown label showing the effective (post-edit) state of an EID."""
    eff = get_effective_es(eid, edits, es_data)
    edited = any(
        hex_offset(es_flat_offset(eid, foff)) in edits.get("raw_bytes", {})
        for foff in [ES_SPECIES, ES_LEVEL, ES_HP, ES_MP, ES_ATK, ES_DEF, ES_AGL, ES_INT]
    )
    tag = " ✏️" if edited else ""
    return f"{eid:3d} — {eff.get('species_name', '???')} Lv{eff.get('level', '?')}{tag}"


# ── Per-gate boss join system ──────────────────────────────────
# Custom routine in bank $54 free space: checks natural join probability,
# then if the enemy is a non-joinable boss ($DB4D==7), looks up a per-gate
# table to decide whether to force join.
#
# Architecture: $54:$55BB (fn$07) is called after every battle to decide
# if a defeated enemy joins. The original code skips join when $DB85==7
# (non-story boss) and uses RNG probability otherwise. Our patch:
#   1) NOPs the $DB85==7 early exit at $54:$55D5
#   2) Redirects the probability CALL at $54:$5604 to our custom routine
#   3) Custom routine at $54:$7FC8 checks natural probability first (for
#      wild monsters), then for bosses ($DB4D==7) checks a 32-byte table
#   4) Table at $54:$7FE0: one byte per gate (01=force join, 00=default)

JOIN_HOOK_BYTES = {
    "0x1515D5": "00 00",        # NOP the $DB85==7 early exit (JR z → NOP NOP)
    "0x151604": "CD C8 7F",     # Redirect CALL $5683 → CALL $7FC8 (our routine)
    "0x153FC8": "CD 83 56 D8 FA 4D DB EE 07 C0 FA 35 C9 21 E0 7F 85 6F 7E B7 C8 37 C9",
}
JOIN_TABLE_FLAT = 0x153FE0      # 32 bytes, one per gate ID (0-31)

def is_join_system_enabled(edits: dict) -> bool:
    """Check if the per-gate join hook code is installed."""
    return edits.get("raw_bytes", {}).get("0x151604") == "CD C8 7F"

def enable_join_system(edits: dict):
    """Install the hook code (does NOT enable any gates)."""
    for k, v in JOIN_HOOK_BYTES.items():
        edits.setdefault("raw_bytes", {})[k] = v

def disable_join_system(edits: dict):
    """Remove all hook code AND per-gate table entries."""
    for k in JOIN_HOOK_BYTES:
        edits.get("raw_bytes", {}).pop(k, None)
    for g in range(32):
        edits.get("raw_bytes", {}).pop(f"0x{JOIN_TABLE_FLAT + g:05X}", None)

def get_gate_join_flag(gate_id: int, edits: dict) -> bool:
    """Check if a specific gate's boss is set to force-join."""
    key = f"0x{JOIN_TABLE_FLAT + gate_id:05X}"
    val = edits.get("raw_bytes", {}).get(key)
    if val is not None:
        return int(val.strip(), 16) != 0
    return False

def set_gate_join_flag(gate_id: int, edits: dict, join: bool):
    """Set or clear a gate's force-join flag."""
    key = f"0x{JOIN_TABLE_FLAT + gate_id:05X}"
    if join:
        edits.setdefault("raw_bytes", {})[key] = "01"
    else:
        edits.get("raw_bytes", {}).pop(key, None)

def count_gates_forced(edits: dict) -> int:
    """Count how many gates have force-join enabled."""
    return sum(1 for g in range(32) if get_gate_join_flag(g, edits))

st.set_page_config(page_title="DWM1 Editor", layout="wide")
st.title("Dragon Warrior Monsters 1 — Editor")

# Load data
monsters = load(MONSTERS) if MONSTERS.exists() else []
names_data = load(NAMES) if NAMES.exists() else []
names = {n["id"]: n["name"] for n in names_data}
blobs = load(BLOBS) if BLOBS.exists() else []
tables = load(TABLES) if TABLES.exists() else {"tables": [], "orphans": []}
free = json.loads(FREE.read_text()) if FREE.exists() else {}
encounters_data = json.loads(ENCOUNTERS.read_text()) if ENCOUNTERS.exists() else {}
edits = load_edits()
eid_lookup = build_eid_lookup()
es_data = load_enemy_stats_data()

# Sorted EID list for dropdowns — labels reflect any Enemy Stats edits
eid_list = sorted(eid_lookup.keys())
def _eid_label(eid):
    """Label that shows effective (post-edit) species and level."""
    if es_data:
        return eid_effective_label(eid, edits, es_data)
    info = eid_lookup[eid]
    lv = info.get("level")
    extra = f"  Lv{lv}" if lv is not None else ""
    return f"{eid:3d} — {info['name']}{extra}"

if not ENEMY_STATS_FILE.exists() and ENCOUNTERS.exists():
    st.sidebar.warning(
        "Encounter dropdowns show only wild monsters (~198). "
        "Run `uv run python -m tools.dump_enemy_stats` for the full list "
        "including bosses and specials."
    )

# Monster species list for starter dropdown (from monster_names.json)
species_options = {n["id"]: f"0x{n['id']:02X} — {n['name']}" for n in sorted(names_data, key=lambda x: x["id"])} if names_data else {}


# ── Room Routing Data ─────────────────────────────────────────
# From ROUTING_DISCOVERIES.md — verified via SameBoy breakpoint $0B:$45AB
# Format: entry_addr, original map_type, original bytes 3-4 (spawn coords)

MAP_TYPE_NAMES = {
    0x00: "Castle",             0x01: "GreatTree",          0x02: "Bazaar",
    0x03: "Gate Hub",           0x04: "Farm",               0x05: "Stable",
    0x06: "Arena Lobby",        0x07: "Arena Rooms",        0x08: "Starry Shrine Breeding Cutscene",
    0x09: "Starry Shrine",      0x0A: "Secret Passage",     0x0B: "Castle: Chest Room (variant)",
    0x0C: "Egg Evaluator",
    0x0D: "Old Man Gate Room",  0x0E: "Castle: Chest Room (variant)",  0x0F: "Vault",
    0x10: "Copycat House",
    0x11: "Castle: Chest Room (variant)",
    0x12: "Library",            0x13: "Library Gate Room",
    0x14: "Castle: Chest Room (variant)",  0x15: "Castle: Chest Room (variant)",
    0x16: "MedalMan",
    0x17: "Copycat House (Glitched)",
    0x18: "Well",
    0x19: "Goopy Room 1 (scr8)", 0x1A: "Goopy Room 2 (scr8)",
    0x1B: "Stable: KingSlime Room", 0x1C: "Stable: Coffin Room",
    0x1D: "Monster School",     0x1E: "Restaurant",         0x1F: "Queen Room",
    0x23: "Room of Beginning",  0x24: "Room: Villager/Talisman",
    0x25: "Room: Memories/Bewilder", 0x26: "Room: Peace/Bravery",
    0x27: "Room: Strength/Anger",    0x28: "Room: Joy/Wisdom",
    0x29: "Room: Happiness/Temptation", 0x2A: "Room: Labyrinth/Judgment",
    0x2B: "Room: Reflection",   0x2C: "Room: Ambition/Demolition",
    0x2D: "Room: Mastermind/Control", 0x2E: "Room: Extinction/Sleep",
    0x2F: "Intro Bedroom (2-screen, crashes)",
    # Boss rooms — verified against boss table byte 4
    0x30: "Boss: Beginning (Healer)",
    0x31: "Boss: Villager (Dragon)",
    0x32: "Boss: Talisman (Golem)",
    0x33: "Boss: Memories (MadCat)",
    0x34: "Boss: Bewilder (FaceTree)",
    0x35: "Boss: Bazaar (MadKnight)",
    0x36: "Boss: Peace (FangSlime)",
    0x37: "Boss: Bravery (BigEye)",
    0x38: "Boss: Well (Gigantes)",
    0x39: "Boss: Strength (StoneMan)",
    0x3A: "Boss: Wisdom (SkyDragon)",
    0x3B: "Boss: Joy (FunkyBird)",
    0x3C: "Boss: Anger (BattleRex)",
    0x3D: "Boss: Arena Left (Digster)",
    0x3E: "Boss: Happiness (Jamirus)",
    0x3F: "Boss: Temptation (Servant)",
    0x41: "Boss: Medal (Lipsy variant)",
    0x40: "KingSlime Decision Room (3 doors)",
    0x42: "Labyrinth",
    0x43: "Boss: Judgment (Akubar)",
    0x44: "Boss: Library (Orochi)",
    0x45: "Boss: Reflection (Durran)",
    0x46: "Boss: Ambition (DracoLord)",
    0x47: "Boss: Demolition (Hargon/Sidoh)",
    0x48: "Boss: Mastermind (Baramos)",
    0x49: "Boss: Control (Zoma)",
    0x4A: "Boss: Extinction (Pizzaro)",
    0x4B: "Boss: Sleep (Esterk)",
    0x4C: "Boss: Bazaar Edge (Mirudraas)",
    0x4D: "Boss: Arena Right (Mudou)",
    0x4E: "Boss: Grandpa's Gate (DeathMore)",
    0x4F: "Boss: Unused (DarkDrium)",
    # Special gate floors
    0x50: "Gate Floor: Item Shop",
    0x51: "Gate Floor: Priest",
    0x52: "Gate Floor: Coliseum",
    0x53: "Forest Maze",        0x54: "Conveyor Maze 1",
    0x55: "Conveyor Maze 2",    0x56: "Conveyor Maze 3",
    0x57: "Maze 1",             0x58: "Maze 2",             0x59: "Maze 3",
    0x5A: "Gate Floor: 6 Chests Diagonal",
    0x5B: "Gate Floor: 6 Chests Rows",
    0x5C: "Gate Floor: 8 Chests Rows",
    0x5D: "Arena Battle",
    0x5E: "Arena Setup Room (white, 2 Terrys)",
    0x60: "Labyrinth Final",
    0x61: "Forest Maze Gate Floor 1",  0x62: "Forest Maze Gate Floor 2",
    0x63: "Forest Maze Gate Floor 3",  0x64: "Forest Maze Gate Floor 4",
}

# With screen=0x00, all tested destinations work except these
WORKING_DESTINATIONS = sorted(set(MAP_TYPE_NAMES.keys()) - {0x2F, 0x0A, 0x13, 0x19, 0x1A})
CRASHING_DESTINATIONS = [
    0x2F,   # Intro Bedroom (2-screen, crashes)
]

# Exit spawn defaults: when redirecting an exit to a room, use that room's
# own entry screen/X/Y values (proven valid in vanilla game).
# Format: {map_type: (screen, X, Y)}
# Extracted from ENTRY_TRANSITIONS raw data bytes 2,3,4
DEST_SPAWN_DEFAULTS = {
    0x00: (0x05, 0x04, 0x07),  # Castle
    0x01: (0x80, 0x04, 0x04),  # GreatTree
    0x02: (0x00, 0x00, 0x03),  # Bazaar
    0x03: (0x01, 0x02, 0x05),  # Gate Hub
    0x04: (0x05, 0x07, 0x05),  # Farm
    0x05: (0x00, 0x00, 0x00),  # Stable
    0x06: (0x01, 0x04, 0x07),  # Arena Lobby
    0x07: (0x04, 0x05, 0x07),  # Arena Rooms
    0x08: (0x00, 0x00, 0x00),  # Starry Shrine Breeding Cutscene
    0x09: (0x04, 0x04, 0x06),  # Starry Shrine
    0x0A: (0x00, 0x07, 0x07),  # Secret Passage
    0x0B: (0x00, 0x00, 0x00),  # Castle: Chest Room (variant)
    0x0C: (0x00, 0x02, 0x07),  # Egg Evaluator
    0x0D: (0x00, 0x05, 0x07),  # Old Man Gate Room
    0x0E: (0x00, 0x00, 0x00),  # Castle: Chest Room (variant)
    0x0F: (0x00, 0x05, 0x07),  # Vault
    0x10: (0x00, 0x04, 0x07),  # Copycat House
    0x11: (0x00, 0x00, 0x00),  # Castle: Chest Room (variant)
    0x12: (0x04, 0x05, 0x07),  # Library
    0x13: (0x00, 0x06, 0x07),  # Library Gate Room
    0x14: (0x00, 0x00, 0x00),  # Castle: Chest Room (variant)
    0x15: (0x00, 0x00, 0x00),  # Castle: Chest Room (variant)
    0x16: (0x00, 0x03, 0x07),  # MedalMan
    0x17: (0x00, 0x00, 0x00),  # Copycat House (Glitched)
    0x18: (0x00, 0x04, 0x00),  # Well
    0x19: (0x00, 0x01, 0x07),  # Goopy Room 1
    0x1A: (0x00, 0x04, 0x07),  # Goopy Room 2
    0x1B: (0x00, 0x04, 0x07),  # Stable: KingSlime Room
    0x1C: (0x00, 0x00, 0x00),  # Stable: Coffin Room
    0x1D: (0x00, 0x05, 0x07),  # Monster School
    0x1E: (0x00, 0x05, 0x07),  # Restaurant
    0x1F: (0x00, 0x05, 0x02),  # Queen Room
    0x23: (0x00, 0x07, 0x07),  # Room of Beginning
    0x24: (0x00, 0x06, 0x07),  # Room: Villager/Talisman
    0x25: (0x00, 0x01, 0x07),  # Room: Memories/Bewilder
    0x26: (0x00, 0x08, 0x07),  # Room: Peace/Bravery
    0x27: (0x00, 0x04, 0x07),  # Room: Strength/Anger
    0x28: (0x00, 0x04, 0x07),  # Room: Joy/Wisdom
    0x29: (0x00, 0x04, 0x07),  # Room: Happiness/Temptation
    0x2A: (0x00, 0x04, 0x07),  # Room: Labyrinth/Judgment
    0x2B: (0x00, 0x07, 0x07),  # Room: Reflection
    0x2C: (0x00, 0x08, 0x07),  # Room: Ambition/Demolition
    0x2D: (0x00, 0x02, 0x07),  # Room: Mastermind/Control
    0x2E: (0x00, 0x06, 0x07),  # Room: Extinction/Sleep
    0x41: (0x00, 0x01, 0x06),  # Boss: Medal (Lipsy)
    0x42: (0x00, 0x02, 0x07),  # Labyrinth
    0x53: (0x00, 0x01, 0x00),  # Forest Maze
    0x60: (0x00, 0x00, 0x02),  # Map_60
    0x61: (0x00, 0x01, 0x07),  # Forest Maze Gate Floor 1
    0x62: (0x00, 0x09, 0x03),  # Forest Maze Gate Floor 2
    0x63: (0x00, 0x08, 0x07),  # Forest Maze Gate Floor 3
    0x64: (0x00, 0x04, 0x07),  # Forest Maze Gate Floor 4
}
# For rooms not in this dict (boss rooms, gate rooms, etc.), use screen=0x00, X=1, Y=1

# Each entry: label, flat_addr, source_map_type, dest_map_type, spawn_x, spawn_y, full_data_hex
# source_map_type = the room the entrance door is IN (where you're standing)
# dest_map_type = the room it originally takes you TO
ENTRY_TRANSITIONS = [
    # ── Castle ──
    ("Castle → Secret Passage",                     0x02CE00, 0x00, 0x0A, 0x07, 0x07, "0a 00 00 07 07 ff"),
    ("Castle stairs DOWN → Gate Hub",               0x02CE08, 0x00, 0x03, 0x02, 0x05, "03 00 01 02 05 07"),
    ("Castle stairs UP → Farm",                     0x02CE0F, 0x00, 0x04, 0x07, 0x05, "04 00 05 07 05 04"),
    ("Castle → GreatTree (left tile)",              0x02CE16, 0x00, 0x01, 0x04, 0x04, "01 00 80 04 04 ff"),
    ("Castle → GreatTree (right tile)",             0x02CE1D, 0x00, 0x01, 0x05, 0x04, "01 00 80 05 04 ff"),
    # ── GreatTree ──
    ("GreatTree scr1 → Castle (left tile)",         0x02CFC1, 0x01, 0x00, 0x04, 0x07, "00 00 05 04 07 05"),
    ("GreatTree scr1 → Castle (right tile)",        0x02CFC8, 0x01, 0x00, 0x05, 0x07, "00 00 05 05 07 ff"),
    ("GreatTree scr2 → MedalMan",                   0x02CFD0, 0x01, 0x16, 0x03, 0x07, "16 00 00 03 07 ff"),
    ("GreatTree scr3 → Arena (left tile)",          0x02CFD8, 0x01, 0x06, 0x04, 0x07, "06 00 01 04 07 05"),
    ("GreatTree scr3 → Arena (right tile)",         0x02CFDF, 0x01, 0x06, 0x05, 0x07, "06 00 01 05 07 ff"),
    ("GreatTree scr5 → Library",                    0x02CFE8, 0x01, 0x12, 0x05, 0x07, "12 00 04 05 07 04"),
    ("GreatTree scr5 → Well",                       0x02CFEF, 0x01, 0x18, 0x04, 0x00, "18 00 00 04 00 ff"),
    ("GreatTree scr6 → Vault",                      0x02CFF7, 0x01, 0x0F, 0x05, 0x07, "0f 00 00 05 07 09"),
    ("GreatTree scr6 → Bazaar",                     0x02CFFE, 0x01, 0x02, 0x00, 0x03, "02 00 00 00 03 ff"),
    ("GreatTree scr7 → Starry Shrine",              0x02D006, 0x01, 0x09, 0x04, 0x06, "09 00 04 04 06 05"),
    ("GreatTree scr7 → Old Man Gate Room",          0x02D00D, 0x01, 0x0D, 0x05, 0x07, "0d 00 00 05 07 04"),
    ("GreatTree scr7 → Copycat House",              0x02D014, 0x01, 0x10, 0x04, 0x07, "10 00 00 04 07 ff"),
    ("GreatTree scr8 → Renamer (Egg Evaluator)",    0x02D032, 0x01, 0x0C, 0x02, 0x07, "0c 00 00 02 07 ff"),
    ("GreatTree scr8 → Goopy Room 1",               0x02D041, 0x01, 0x19, 0x01, 0x07, "19 00 00 01 07 ff"),
    ("GreatTree scr8 → Goopy Room 2",               0x02D057, 0x01, 0x1A, 0x04, 0x07, "1a 00 00 04 07 ff"),
    # ── Gate Hub ──
    ("Gate Hub → sub-level 2 (stairs)",             0x02D492, 0x03, 0x03, 0x07, 0x05, "03 00 04 07 05 07"),
    ("Gate Hub → Room: Peace/Bravery",              0x02D499, 0x03, 0x26, 0x08, 0x07, "26 00 00 08 07 ff"),
    ("Gate Hub → Room: Strength/Anger (L)",         0x02D4AF, 0x03, 0x27, 0x04, 0x07, "27 00 00 04 07 ff"),
    ("Gate Hub → Room: Strength/Anger (R)",         0x02D4B6, 0x03, 0x27, 0x05, 0x07, "27 00 00 05 07 ff"),
    ("Gate Hub → Room: Joy/Wisdom",                 0x02D4DA, 0x03, 0x28, 0x04, 0x07, "28 00 00 04 07 ff"),
    ("Gate Hub → Castle",                           0x02D4E2, 0x03, 0x00, 0x02, 0x05, "00 00 05 02 05 ff"),
    ("Gate Hub → Room of Beginning (L)",            0x02D4F1, 0x03, 0x23, 0x07, 0x07, "23 00 00 07 07 ff"),
    ("Gate Hub → Room of Beginning (R)",            0x02D4F8, 0x03, 0x23, 0x08, 0x07, "23 00 00 08 07 ff"),
    ("Gate Hub → Room: Villager/Talisman",          0x02D515, 0x03, 0x24, 0x06, 0x07, "24 00 00 06 07 ff"),
    ("Gate Hub → Room of Beginning",                0x02D524, 0x03, 0x23, 0x07, 0x07, "23 00 00 07 07 05"),
    ("Gate Hub → Room: Memories/Bewilder",          0x02D539, 0x03, 0x25, 0x01, 0x07, "25 00 00 01 07 ff"),
    ("Gate Hub sub2 → sub1",                        0x02D541, 0x03, 0x03, 0x07, 0x05, "03 00 00 07 05 ff"),
    ("Gate Hub → Room: Happiness/Temptation",       0x02D550, 0x03, 0x29, 0x04, 0x07, "29 00 00 04 07 ff"),
    ("Gate Hub → Room: Labyrinth/Judgment",         0x02D566, 0x03, 0x2A, 0x04, 0x07, "2a 00 00 04 07 ff"),
    ("Gate Hub → Room: Reflection (L)",             0x02D583, 0x03, 0x2B, 0x07, 0x07, "2b 00 00 07 07 ff"),
    ("Gate Hub → Room: Reflection (R)",             0x02D58A, 0x03, 0x2B, 0x08, 0x07, "2b 00 00 08 07 ff"),
    # ── Farm / Stable ──
    ("Farm → Castle: Chest Room",                               0x02D823, 0x04, 0x0B, 0x00, 0x00, "0b 00 00 00 00 ff"),
    ("Farm → Stable",                               0x02D82B, 0x04, 0x05, 0x06, 0x04, "05 00 02 06 04 ff"),
    ("Farm → Castle (stairs)",                      0x02D833, 0x04, 0x00, 0x07, 0x05, "00 00 05 07 05 ff"),
    ("Stable → Farm (stairs)",                      0x02D998, 0x05, 0x04, 0x06, 0x04, "04 00 04 06 04 ff"),
    # ── Arena ──
    ("Arena Lobby → Arena Rooms (front)",            0x02DA0E, 0x06, 0x07, 0x05, 0x07, "07 00 04 05 07 ff"),
    ("Arena Lobby → Arena Rooms (back)",             0x02DA25, 0x06, 0x07, 0x04, 0x07, "07 00 06 04 07 ff"),
    ("Arena → Monster School",                      0x02DC2B, 0x07, 0x1D, 0x05, 0x07, "1d 00 00 05 07 ff"),
    ("Arena → Queen Room",                          0x02DC34, 0x07, 0x1F, 0x05, 0x02, "1f 00 00 05 02 ff"),
    ("Arena → Castle: Chest Room",                              0x02DC43, 0x07, 0x0E, 0x00, 0x00, "0e 00 00 00 00 ff"),
    ("Arena → Monster School (alt)",                0x02DC59, 0x07, 0x1D, 0x00, 0x00, "1d 00 00 00 00 ff"),
    ("Arena → Restaurant",                          0x02DC61, 0x07, 0x1E, 0x05, 0x07, "1e 00 00 05 07 ff"),
    # ── Secret Passage ──
    ("Secret Passage → Castle",                     0x02DE86, 0x0A, 0x00, 0x07, 0x01, "00 00 81 07 01 ff"),
    ("Secret Passage → MedalMan",                   0x02DE8E, 0x0A, 0x16, 0x03, 0x01, "16 00 80 03 01 ff"),
    # ── Other rooms ──
    ("Old Man Gate Room → Restaurant",              0x02DF44, 0x0D, 0x1E, 0x00, 0x00, "1e 00 00 00 00 ff"),
    ("Copycat House → Castle",                      0x02DFD5, 0x10, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Library → Library Gate Room",                 0x02E077, 0x12, 0x13, 0x06, 0x07, "13 00 00 06 07 ff"),
    ("Library Gate Room → Library",                 0x02E12C, 0x13, 0x12, 0x06, 0x01, "12 00 84 06 01 ff"),
    ("Library Gate Room → Castle: Chest Room",                  0x02E133, 0x13, 0x14, 0x00, 0x00, "14 00 00 00 00 ff"),
    ("MedalMan → Secret Passage",                   0x02E1DC, 0x16, 0x0A, 0x03, 0x07, "0a 00 01 03 07 ff"),
    ("MedalMan → Castle: Chest Room",                           0x02E1E3, 0x16, 0x11, 0x00, 0x00, "11 00 00 00 00 ff"),
    ("Well → Breeding Cutscene",                            0x02E2B5, 0x18, 0x08, 0x00, 0x00, "08 00 00 00 00 ff"),
    ("Queen Room → Arena (leaving!)",               0x02E49E, 0x1F, 0x07, 0x05, 0x02, "07 00 01 05 02 ff"),
    # ── Gate rooms → destinations ──
    ("Room: Villager/Talisman → GreatTree",         0x02E52C, 0x24, 0x01, 0x00, 0x00, "01 00 00 00 00 ff"),
    ("Room: Villager/Talisman → Bazaar",            0x02E533, 0x24, 0x02, 0x00, 0x00, "02 00 00 00 00 ff"),
    ("Room: Memories/Bewilder → Farm",              0x02E591, 0x25, 0x04, 0x00, 0x00, "04 00 00 00 00 ff"),
    ("Room: Peace/Bravery → Arena Lobby",           0x02E5E8, 0x26, 0x06, 0x00, 0x00, "06 00 00 00 00 ff"),
    ("Room: Peace/Bravery → Arena Rooms",           0x02E5EF, 0x26, 0x07, 0x00, 0x00, "07 00 00 00 00 ff"),
    ("Room: Strength/Anger → Starry Shrine",        0x02E64B, 0x27, 0x09, 0x00, 0x00, "09 00 00 00 00 ff"),
    ("Room: Strength/Anger → Secret Passage",       0x02E652, 0x27, 0x0A, 0x00, 0x00, "0a 00 00 00 00 ff"),
    ("Room: Joy/Wisdom → Egg Evaluator",            0x02E6A9, 0x28, 0x0C, 0x00, 0x00, "0c 00 00 00 00 ff"),
    ("Room: Joy/Wisdom → Old Man Gate Room",        0x02E6B0, 0x28, 0x0D, 0x00, 0x00, "0d 00 00 00 00 ff"),
    ("Room: Happiness/Temptation → Vault",          0x02E707, 0x29, 0x0F, 0x00, 0x00, "0f 00 00 00 00 ff"),
    ("Room: Happiness/Temptation → Copycat",        0x02E70E, 0x29, 0x10, 0x00, 0x00, "10 00 00 00 00 ff"),
    ("Room: Labyrinth/Judgment → Library",          0x02E765, 0x2A, 0x12, 0x00, 0x00, "12 00 00 00 00 ff"),
    ("Room: Labyrinth/Judgment → Lib Gate",         0x02E76C, 0x2A, 0x13, 0x00, 0x00, "13 00 00 00 00 ff"),
    ("Room: Reflection → Castle: Chest Room",                   0x02E7A3, 0x2B, 0x15, 0x00, 0x00, "15 00 00 00 00 ff"),
    ("Room: Ambition/Demolition → MedalMan",        0x02E7FA, 0x2C, 0x16, 0x00, 0x00, "16 00 00 00 00 ff"),
    ("Room: Ambition/Demolition → Copycat (Glitched)",          0x02E801, 0x2C, 0x17, 0x00, 0x00, "17 00 00 00 00 ff"),
    ("Room: Mastermind/Control → Well",             0x02E858, 0x2D, 0x18, 0x00, 0x00, "18 00 00 00 00 ff"),
    ("Room: Mastermind/Control → Goopy 1",          0x02E85F, 0x2D, 0x19, 0x00, 0x00, "19 00 00 00 00 ff"),
    ("Room: Extinction/Sleep → Goopy 2",            0x02E8BD, 0x2E, 0x1A, 0x00, 0x00, "1a 00 00 00 00 ff"),
    ("Room: Extinction/Sleep → Stable: KingSlime",             0x02E8C4, 0x2E, 0x1B, 0x00, 0x00, "1b 00 00 00 00 ff"),
    # ── Room of Beginning ──
    ("Room of Beginning → Gate (flag=01)",          0x02E4D5, 0x23, 0x00, 0x00, 0x00, "00 01 00 00 00 ff"),
    # ── Boss rooms (all → Castle) ──
    ("Boss: Beginning (Healer) → Castle",           0x02EACE, 0x30, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Villager (Dragon) → Castle",            0x02EB0C, 0x31, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Talisman (Golem) → Castle",             0x02EB3B, 0x32, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Memories (MadCat) → Castle",            0x02EB60, 0x33, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Bewilder (FaceTree) → Castle",          0x02EBBC, 0x34, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Peace (FangSlime) → Castle",            0x02EC7E, 0x36, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Bravery (BigEye) → Castle",             0x02ED11, 0x37, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Well (Gigantes) → Castle",              0x02EDF4, 0x38, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Strength (StoneMan) → Castle",          0x02EE2D, 0x39, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Wisdom (SkyDragon) → Castle",           0x02EF38, 0x3A, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Joy (FunkyBird) → Castle",              0x02EF5D, 0x3B, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Anger (BattleRex) → Castle",            0x02EFDD, 0x3C, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Happiness (Jamirus) → Castle",          0x02F04C, 0x3E, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Temptation (Servant) → Castle",         0x02F071, 0x3F, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Judgment (Akubar) → Castle",            0x02F518, 0x43, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Library (Orochi) → Castle",             0x02F55B, 0x44, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Reflection (Durran) → Castle",          0x02F5C3, 0x45, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Ambition (DracoLord) → Castle",         0x02F5F2, 0x46, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Demolition (Hargon) → Castle",          0x02F63D, 0x47, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Mastermind (Baramos) → Castle",         0x02F66C, 0x48, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Control (Zoma) → Castle",               0x02F69B, 0x49, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Extinction (Pizzaro) → Castle",         0x02F6CA, 0x4A, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Sleep (Esterk) → Castle",               0x02F6F9, 0x4B, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Bazaar Edge (Mirudraas) → Castle",      0x02F728, 0x4C, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Arena Right (Mudou) → Castle",          0x02F757, 0x4D, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
    ("Boss: Unused (DarkDrium) → Castle",           0x02F7D7, 0x4F, 0x00, 0x04, 0x05, "00 00 01 04 05 ff"),
]

# Full exit transition catalog — 270 entries from dump_all_exits.py
# Each: (label, flat_addr, src_mt, dest_mt, screen, spawn_x, spawn_y)
EXIT_TRANSITIONS = [
    ("Castle → Secret Passage", 0x02CE00, 0x00, 0x0A, 0x00, 0x07, 0x07),
    ("Castle → Gate Hub", 0x02CE08, 0x00, 0x03, 0x01, 0x02, 0x05),
    ("Castle → Farm", 0x02CE0F, 0x00, 0x04, 0x05, 0x07, 0x05),
    ("Castle → GreatTree", 0x02CE16, 0x00, 0x01, 0x80, 0x04, 0x04),
    ("Castle → GreatTree", 0x02CE1D, 0x00, 0x01, 0x80, 0x05, 0x04),
    ("GreatTree → Castle", 0x02CFC1, 0x01, 0x00, 0x05, 0x04, 0x07),
    ("GreatTree → Castle", 0x02CFC8, 0x01, 0x00, 0x05, 0x05, 0x07),
    ("GreatTree → MedalMan", 0x02CFD0, 0x01, 0x16, 0x00, 0x03, 0x07),
    ("GreatTree → Arena Lobby", 0x02CFD8, 0x01, 0x06, 0x01, 0x04, 0x07),
    ("GreatTree → Arena Lobby", 0x02CFDF, 0x01, 0x06, 0x01, 0x05, 0x07),
    ("GreatTree → Library", 0x02CFE8, 0x01, 0x12, 0x04, 0x05, 0x07),
    ("GreatTree → Well", 0x02CFEF, 0x01, 0x18, 0x00, 0x04, 0x00),
    ("GreatTree → Vault", 0x02CFF7, 0x01, 0x0F, 0x00, 0x05, 0x07),
    ("GreatTree → Bazaar", 0x02CFFE, 0x01, 0x02, 0x00, 0x00, 0x03),
    ("GreatTree → Starry Shrine", 0x02D006, 0x01, 0x09, 0x04, 0x04, 0x06),
    ("GreatTree → Old Man Gate Room", 0x02D00D, 0x01, 0x0D, 0x00, 0x05, 0x07),
    ("GreatTree → Copycat House", 0x02D014, 0x01, 0x10, 0x00, 0x04, 0x07),
    ("GreatTree → Starry Shrine", 0x02D01C, 0x01, 0x09, 0x04, 0x04, 0x06),
    ("GreatTree → Old Man Gate Room", 0x02D023, 0x01, 0x0D, 0x00, 0x05, 0x07),
    ("GreatTree → Copycat House", 0x02D02A, 0x01, 0x10, 0x00, 0x04, 0x07),
    ("GreatTree → Egg Evaluator", 0x02D032, 0x01, 0x0C, 0x00, 0x02, 0x07),
    ("GreatTree → Egg Evaluator", 0x02D03A, 0x01, 0x0C, 0x00, 0x02, 0x07),
    ("GreatTree → Goopy Room 1", 0x02D041, 0x01, 0x19, 0x00, 0x01, 0x07),
    ("GreatTree → Egg Evaluator", 0x02D049, 0x01, 0x0C, 0x00, 0x02, 0x07),
    ("GreatTree → Goopy Room 1", 0x02D050, 0x01, 0x19, 0x00, 0x01, 0x07),
    ("GreatTree → Goopy Room 2", 0x02D057, 0x01, 0x1A, 0x00, 0x04, 0x07),
    ("Bazaar → GreatTree", 0x02D2C5, 0x02, 0x01, 0x09, 0x09, 0x03),
    ("Bazaar → Stable", 0x02D2D5, 0x02, 0x05, 0x00, 0x00, 0x00),
    ("Bazaar → Stable", 0x02D2DD, 0x02, 0x05, 0x00, 0x00, 0x00),
    ("Bazaar → Stable", 0x02D2E5, 0x02, 0x05, 0x00, 0x00, 0x00),
    ("Bazaar → Stable: Coffin Room", 0x02D2EC, 0x02, 0x1C, 0x00, 0x00, 0x00),
    ("Gate Hub → Gate Hub", 0x02D48A, 0x03, 0x03, 0x04, 0x07, 0x05),
    ("Gate Hub → Gate Hub", 0x02D492, 0x03, 0x03, 0x04, 0x07, 0x05),
    ("Gate Hub → Room: Peace/Bravery", 0x02D499, 0x03, 0x26, 0x00, 0x08, 0x07),
    ("Gate Hub → Gate Hub", 0x02D4A1, 0x03, 0x03, 0x04, 0x07, 0x05),
    ("Gate Hub → Room: Peace/Bravery", 0x02D4A8, 0x03, 0x26, 0x00, 0x08, 0x07),
    ("Gate Hub → Room: Strength/Anger", 0x02D4AF, 0x03, 0x27, 0x00, 0x04, 0x07),
    ("Gate Hub → Room: Strength/Anger", 0x02D4B6, 0x03, 0x27, 0x00, 0x05, 0x07),
    ("Gate Hub → Gate Hub", 0x02D4BE, 0x03, 0x03, 0x04, 0x07, 0x05),
    ("Gate Hub → Room: Peace/Bravery", 0x02D4C5, 0x03, 0x26, 0x00, 0x08, 0x07),
    ("Gate Hub → Room: Strength/Anger", 0x02D4CC, 0x03, 0x27, 0x00, 0x04, 0x07),
    ("Gate Hub → Room: Strength/Anger", 0x02D4D3, 0x03, 0x27, 0x00, 0x05, 0x07),
    ("Gate Hub → Room: Joy/Wisdom", 0x02D4DA, 0x03, 0x28, 0x00, 0x04, 0x07),
    ("Gate Hub → Castle", 0x02D4E2, 0x03, 0x00, 0x05, 0x02, 0x05),
    ("Gate Hub → Castle", 0x02D4EA, 0x03, 0x00, 0x05, 0x02, 0x05),
    ("Gate Hub → Room of Beginning", 0x02D4F1, 0x03, 0x23, 0x00, 0x07, 0x07),
    ("Gate Hub → Room of Beginning", 0x02D4F8, 0x03, 0x23, 0x00, 0x08, 0x07),
    ("Gate Hub → Castle", 0x02D500, 0x03, 0x00, 0x05, 0x02, 0x05),
    ("Gate Hub → Room of Beginning", 0x02D507, 0x03, 0x23, 0x00, 0x07, 0x07),
    ("Gate Hub → Room of Beginning", 0x02D50E, 0x03, 0x23, 0x00, 0x08, 0x07),
    ("Gate Hub → Room: Villager/Talisman", 0x02D515, 0x03, 0x24, 0x00, 0x06, 0x07),
    ("Gate Hub → Castle", 0x02D51D, 0x03, 0x00, 0x05, 0x02, 0x05),
    ("Gate Hub → Room of Beginning", 0x02D524, 0x03, 0x23, 0x00, 0x07, 0x07),
    ("Gate Hub → Room of Beginning", 0x02D52B, 0x03, 0x23, 0x00, 0x08, 0x07),
    ("Gate Hub → Room: Villager/Talisman", 0x02D532, 0x03, 0x24, 0x00, 0x06, 0x07),
    ("Gate Hub → Room: Memories/Bewilder", 0x02D539, 0x03, 0x25, 0x00, 0x01, 0x07),
    ("Gate Hub → Gate Hub", 0x02D541, 0x03, 0x03, 0x00, 0x07, 0x05),
    ("Gate Hub → Gate Hub", 0x02D549, 0x03, 0x03, 0x00, 0x07, 0x05),
    ("Gate Hub → Room: Happiness/Temptation", 0x02D550, 0x03, 0x29, 0x00, 0x04, 0x07),
    ("Gate Hub → Gate Hub", 0x02D558, 0x03, 0x03, 0x00, 0x07, 0x05),
    ("Gate Hub → Room: Happiness/Temptation", 0x02D55F, 0x03, 0x29, 0x00, 0x04, 0x07),
    ("Gate Hub → Room: Labyrinth/Judgment", 0x02D566, 0x03, 0x2A, 0x00, 0x04, 0x07),
    ("Gate Hub → Gate Hub", 0x02D56E, 0x03, 0x03, 0x00, 0x07, 0x05),
    ("Gate Hub → Room: Happiness/Temptation", 0x02D575, 0x03, 0x29, 0x00, 0x04, 0x07),
    ("Gate Hub → Room: Labyrinth/Judgment", 0x02D57C, 0x03, 0x2A, 0x00, 0x04, 0x07),
    ("Gate Hub → Room: Reflection", 0x02D583, 0x03, 0x2B, 0x00, 0x07, 0x07),
    ("Gate Hub → Room: Reflection", 0x02D58A, 0x03, 0x2B, 0x00, 0x08, 0x07),
    ("Gate Hub → Room: Ambition/Demolition", 0x02D593, 0x03, 0x2C, 0x00, 0x08, 0x07),
    ("Gate Hub → Room: Mastermind/Control", 0x02D59A, 0x03, 0x2D, 0x00, 0x02, 0x07),
    ("Gate Hub → Room: Extinction/Sleep", 0x02D5A1, 0x03, 0x2E, 0x00, 0x06, 0x07),
    ("Gate Hub → Room: Extinction/Sleep", 0x02D5A8, 0x03, 0x2E, 0x00, 0x07, 0x07),
    ("Farm → Castle: Chest Room", 0x02D823, 0x04, 0x0B, 0x00, 0x00, 0x00),
    ("Farm → Stable", 0x02D82B, 0x04, 0x05, 0x02, 0x06, 0x04),
    ("Farm → Castle", 0x02D833, 0x04, 0x00, 0x05, 0x07, 0x05),
    ("Stable → KingSlime Room", 0x02D96B, 0x05, 0x1B, 0x00, 0x04, 0x07),
    ("Stable → KingSlime Room", 0x02D972, 0x05, 0x1B, 0x00, 0x05, 0x07),
    ("Stable → KingSlime Room", 0x02D97A, 0x05, 0x1B, 0x00, 0x04, 0x07),
    ("Stable → KingSlime Room", 0x02D981, 0x05, 0x1B, 0x00, 0x05, 0x07),
    ("Stable → Coffin Room", 0x02D989, 0x05, 0x1C, 0x00, 0x04, 0x07),
    ("Stable → Coffin Room", 0x02D990, 0x05, 0x1C, 0x00, 0x05, 0x07),
    ("Stable → Farm", 0x02D998, 0x05, 0x04, 0x04, 0x06, 0x04),
    ("Arena Lobby → Arena Rooms", 0x02DA0E, 0x06, 0x07, 0x04, 0x05, 0x07),
    ("Arena Lobby → GreatTree", 0x02DA16, 0x06, 0x01, 0x84, 0x04, 0x03),
    ("Arena Lobby → GreatTree", 0x02DA1D, 0x06, 0x01, 0x84, 0x05, 0x03),
    ("Arena Lobby → Arena Rooms", 0x02DA25, 0x06, 0x07, 0x06, 0x04, 0x07),
    ("Arena Rooms → Monster School", 0x02DC2B, 0x07, 0x1D, 0x00, 0x05, 0x07),
    ("Arena Rooms → Queen Room", 0x02DC34, 0x07, 0x1F, 0x00, 0x05, 0x02),
    ("Arena Rooms → Queen Room", 0x02DC3C, 0x07, 0x1F, 0x00, 0x05, 0x02),
    ("Arena Rooms → Castle: Chest Room", 0x02DC43, 0x07, 0x0E, 0x00, 0x00, 0x00),
    ("Arena Rooms → Queen Room", 0x02DC4B, 0x07, 0x1F, 0x00, 0x05, 0x02),
    ("Arena Rooms → Castle: Chest Room", 0x02DC52, 0x07, 0x0E, 0x00, 0x00, 0x00),
    ("Arena Rooms → Monster School", 0x02DC59, 0x07, 0x1D, 0x00, 0x00, 0x00),
    ("Arena Rooms → Restaurant", 0x02DC61, 0x07, 0x1E, 0x00, 0x05, 0x07),
    ("Arena Rooms → Arena Lobby", 0x02DC69, 0x07, 0x06, 0x00, 0x05, 0x00),
    ("Arena Rooms → Arena Lobby", 0x02DC71, 0x07, 0x06, 0x01, 0x04, 0x03),
    ("Arena Rooms → Arena Lobby", 0x02DC78, 0x07, 0x06, 0x01, 0x05, 0x03),
    ("Arena Rooms → Arena Lobby", 0x02DC80, 0x07, 0x06, 0x02, 0x04, 0x00),
    ("Starry Shrine → GreatTree", 0x02DE62, 0x09, 0x01, 0x0C, 0x04, 0x06),
    ("Secret Passage → Castle", 0x02DE86, 0x0A, 0x00, 0x81, 0x07, 0x01),
    ("Secret Passage → MedalMan", 0x02DE8E, 0x0A, 0x16, 0x80, 0x03, 0x01),
    ("Egg Evaluator → GreatTree", 0x02DEBA, 0x0C, 0x01, 0x8D, 0x02, 0x01),
    ("Old Man Gate Room → GreatTree", 0x02DF3D, 0x0D, 0x01, 0x8C, 0x05, 0x01),
    ("Old Man Gate Room → Restaurant", 0x02DF44, 0x0D, 0x1E, 0x00, 0x00, 0x00),
    ("Vault → GreatTree", 0x02DF6B, 0x0F, 0x01, 0x89, 0x05, 0x01),
    ("Copycat House → GreatTree", 0x02DFC6, 0x10, 0x01, 0x8C, 0x04, 0x04),
    ("Copycat House → GreatTree", 0x02DFCE, 0x10, 0x01, 0x8C, 0x04, 0x04),
    ("Copycat House → Castle", 0x02DFD5, 0x10, 0x00, 0x01, 0x04, 0x05),
    ("Library → GreatTree", 0x02E070, 0x12, 0x01, 0x88, 0x05, 0x03),
    ("Library → Library Gate Room", 0x02E077, 0x12, 0x13, 0x00, 0x06, 0x07),
    ("Library Gate Room → Library", 0x02E12C, 0x13, 0x12, 0x84, 0x06, 0x01),
    ("Library Gate Room → Castle: Chest Room", 0x02E133, 0x13, 0x14, 0x00, 0x00, 0x00),
    ("MedalMan → GreatTree", 0x02E1CD, 0x16, 0x01, 0x81, 0x03, 0x02),
    ("MedalMan → GreatTree", 0x02E1D5, 0x16, 0x01, 0x81, 0x03, 0x02),
    ("MedalMan → Secret Passage", 0x02E1DC, 0x16, 0x0A, 0x01, 0x03, 0x07),
    ("MedalMan → Castle: Chest Room", 0x02E1E3, 0x16, 0x11, 0x00, 0x00, 0x00),
    ("MedalMan → GreatTree", 0x02E1EB, 0x16, 0x01, 0x81, 0x03, 0x02),
    ("MedalMan → Secret Passage", 0x02E1F2, 0x16, 0x0A, 0x01, 0x03, 0x07),
    ("Well → GreatTree", 0x02E2AC, 0x18, 0x01, 0x08, 0x04, 0x05),
    ("Well → Breeding Cutscene", 0x02E2B5, 0x18, 0x08, 0x00, 0x00, 0x00),
    ("Goopy Room 1 → GreatTree", 0x02E2DC, 0x19, 0x01, 0x8D, 0x01, 0x04),
    ("Goopy Room 2 → GreatTree", 0x02E30D, 0x1A, 0x01, 0x8D, 0x04, 0x06),
    ("KingSlime Room → Stable", 0x02E351, 0x1B, 0x05, 0x80, 0x04, 0x00),
    ("KingSlime Room → Stable", 0x02E358, 0x1B, 0x05, 0x80, 0x05, 0x00),
    ("Coffin Room → Stable", 0x02E3B8, 0x1C, 0x05, 0x81, 0x04, 0x00),
    ("Coffin Room → Stable", 0x02E3BF, 0x1C, 0x05, 0x81, 0x05, 0x00),
    ("Monster School → Arena Rooms", 0x02E3F0, 0x1D, 0x07, 0x80, 0x05, 0x01),
    ("Restaurant → Arena Rooms", 0x02E432, 0x1E, 0x07, 0x82, 0x05, 0x01),
    ("Queen Room → Arena Rooms", 0x02E49E, 0x1F, 0x07, 0x01, 0x05, 0x02),
    ("Room of Beginning → Gate Hub", 0x02E4C7, 0x23, 0x03, 0x81, 0x04, 0x01),
    ("Room of Beginning → Gate Hub", 0x02E4CE, 0x23, 0x03, 0x81, 0x05, 0x01),
    ("Room of Beginning → Castle", 0x02E4D5, 0x23, 0x00, 0x00, 0x00, 0x00),
    ("Room: Villager/Talisman → Gate Hub", 0x02E525, 0x24, 0x03, 0x81, 0x02, 0x02),
    ("Room: Villager/Talisman → GreatTree", 0x02E52C, 0x24, 0x01, 0x00, 0x00, 0x00),
    ("Room: Villager/Talisman → Bazaar", 0x02E533, 0x24, 0x02, 0x00, 0x00, 0x00),
    ("Room: Memories/Bewilder → Gate Hub", 0x02E583, 0x25, 0x03, 0x81, 0x07, 0x02),
    ("Room: Memories/Bewilder → Gate Hub", 0x02E58A, 0x25, 0x03, 0x00, 0x00, 0x00),
    ("Room: Memories/Bewilder → Farm", 0x02E591, 0x25, 0x04, 0x00, 0x00, 0x00),
    ("Room: Peace/Bravery → Gate Hub", 0x02E5E1, 0x26, 0x03, 0x80, 0x07, 0x02),
    ("Room: Peace/Bravery → Arena Lobby", 0x02E5E8, 0x26, 0x06, 0x00, 0x00, 0x00),
    ("Room: Peace/Bravery → Arena Rooms", 0x02E5EF, 0x26, 0x07, 0x00, 0x00, 0x00),
    ("Room: Strength/Anger → Gate Hub", 0x02E63D, 0x27, 0x03, 0x80, 0x04, 0x01),
    ("Room: Strength/Anger → Gate Hub", 0x02E644, 0x27, 0x03, 0x80, 0x05, 0x01),
    ("Room: Strength/Anger → Starry Shrine", 0x02E64B, 0x27, 0x09, 0x00, 0x00, 0x00),
    ("Room: Strength/Anger → Secret Passage", 0x02E652, 0x27, 0x0A, 0x00, 0x00, 0x00),
    ("Room: Joy/Wisdom → Gate Hub", 0x02E6A2, 0x28, 0x03, 0x80, 0x02, 0x02),
    ("Room: Joy/Wisdom → Egg Evaluator", 0x02E6A9, 0x28, 0x0C, 0x00, 0x00, 0x00),
    ("Room: Joy/Wisdom → Old Man Gate Room", 0x02E6B0, 0x28, 0x0D, 0x00, 0x00, 0x00),
    ("Room: Happiness/Temptation → Gate Hub", 0x02E700, 0x29, 0x03, 0x84, 0x07, 0x02),
    ("Room: Happiness/Temptation → Vault", 0x02E707, 0x29, 0x0F, 0x00, 0x00, 0x00),
    ("Room: Happiness/Temptation → Copycat House", 0x02E70E, 0x29, 0x10, 0x00, 0x00, 0x00),
    ("Room: Labyrinth/Judgment → Gate Hub", 0x02E75E, 0x2A, 0x03, 0x84, 0x02, 0x02),
    ("Room: Labyrinth/Judgment → Library", 0x02E765, 0x2A, 0x12, 0x00, 0x00, 0x00),
    ("Room: Labyrinth/Judgment → Library Gate Room", 0x02E76C, 0x2A, 0x13, 0x00, 0x00, 0x00),
    ("Room: Reflection → Gate Hub", 0x02E795, 0x2B, 0x03, 0x84, 0x04, 0x01),
    ("Room: Reflection → Gate Hub", 0x02E79C, 0x2B, 0x03, 0x84, 0x05, 0x01),
    ("Room: Reflection → Castle: Chest Room", 0x02E7A3, 0x2B, 0x15, 0x00, 0x00, 0x00),
    ("Room: Ambition/Demolition → Gate Hub", 0x02E7F3, 0x2C, 0x03, 0x85, 0x02, 0x02),
    ("Room: Ambition/Demolition → MedalMan", 0x02E7FA, 0x2C, 0x16, 0x00, 0x00, 0x00),
    ("Room: Ambition/Demolition → Copycat (Glitched)", 0x02E801, 0x2C, 0x17, 0x00, 0x00, 0x00),
    ("Room: Mastermind/Control → Gate Hub", 0x02E851, 0x2D, 0x03, 0x85, 0x07, 0x02),
    ("Room: Mastermind/Control → Well", 0x02E858, 0x2D, 0x18, 0x00, 0x00, 0x00),
    ("Room: Mastermind/Control → Goopy Room 1", 0x02E85F, 0x2D, 0x19, 0x00, 0x00, 0x00),
    ("Room: Extinction/Sleep → Gate Hub", 0x02E8AF, 0x2E, 0x03, 0x85, 0x04, 0x01),
    ("Room: Extinction/Sleep → Gate Hub", 0x02E8B6, 0x2E, 0x03, 0x85, 0x05, 0x01),
    ("Room: Extinction/Sleep → Goopy Room 2", 0x02E8BD, 0x2E, 0x1A, 0x00, 0x00, 0x00),
    ("Room: Extinction/Sleep → Stable: KingSlime", 0x02E8C4, 0x2E, 0x1B, 0x00, 0x00, 0x00),
    ("Boss: Beginning (Healer) → Castle", 0x02EACE, 0x30, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Villager (Dragon) → Castle", 0x02EB0C, 0x31, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Talisman (Golem) → Castle", 0x02EB3B, 0x32, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Memories (MadCat) → Castle", 0x02EB60, 0x33, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Bewilder (FaceTree) → Castle", 0x02EBBC, 0x34, 0x00, 0x01, 0x04, 0x05),
    ("Boss: MadKnight → Castle", 0x02EBF5, 0x35, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Peace (FangSlime) → Castle", 0x02EC7E, 0x36, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Bravery (BigEye) → Castle", 0x02ED11, 0x37, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Well (Gigantes) → Castle", 0x02EDF4, 0x38, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Strength (StoneMan) → Castle", 0x02EE2D, 0x39, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Wisdom (SkyDragon) → Castle", 0x02EF38, 0x3A, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Joy (FunkyBird) → Castle", 0x02EF5D, 0x3B, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Anger (BattleRex) → Castle", 0x02EFDD, 0x3C, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Happiness (Jamirus) → Castle", 0x02F04C, 0x3E, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Temptation (Servant) → Castle", 0x02F071, 0x3F, 0x00, 0x01, 0x04, 0x05),
    ("KingSlime Decision → Boss: Medal (Lipsy)", 0x02F0BB, 0x40, 0x41, 0x00, 0x01, 0x06),
    ("KingSlime Decision → Boss: Medal (Lipsy)", 0x02F0C2, 0x40, 0x41, 0x00, 0x02, 0x06),
    ("KingSlime Decision → Boss: Medal (Lipsy)", 0x02F0C9, 0x40, 0x41, 0x00, 0x04, 0x06),
    ("KingSlime Decision → Boss: Medal (Lipsy)", 0x02F0D0, 0x40, 0x41, 0x00, 0x05, 0x06),
    ("KingSlime Decision → Boss: Medal (Lipsy)", 0x02F0D7, 0x40, 0x41, 0x00, 0x07, 0x06),
    ("KingSlime Decision → Boss: Medal (Lipsy)", 0x02F0DE, 0x40, 0x41, 0x00, 0x08, 0x06),
    ("Boss: Medal (Lipsy) → Castle", 0x02F12E, 0x41, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Medal (Lipsy) → Castle", 0x02F135, 0x41, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Medal (Lipsy) → Castle", 0x02F13C, 0x41, 0x00, 0x01, 0x04, 0x05),
    ("Labyrinth → Castle", 0x02F380, 0x42, 0x00, 0x01, 0x04, 0x05),
    ("Labyrinth → Labyrinth", 0x02F387, 0x42, 0x42, 0x00, 0x02, 0x07),
    ("Labyrinth → Labyrinth", 0x02F38E, 0x42, 0x42, 0x00, 0x07, 0x07),
    ("Labyrinth → Labyrinth", 0x02F395, 0x42, 0x42, 0x00, 0x09, 0x02),
    ("Labyrinth → Labyrinth", 0x02F39C, 0x42, 0x42, 0x00, 0x09, 0x05),
    ("Labyrinth → Labyrinth", 0x02F3A3, 0x42, 0x42, 0x00, 0x02, 0x00),
    ("Labyrinth → Labyrinth", 0x02F3AA, 0x42, 0x42, 0x00, 0x07, 0x00),
    ("Labyrinth → Labyrinth", 0x02F3B1, 0x42, 0x42, 0x00, 0x00, 0x02),
    ("Labyrinth → Labyrinth", 0x02F3B8, 0x42, 0x42, 0x00, 0x00, 0x05),
    ("Labyrinth → Castle", 0x02F3C0, 0x42, 0x00, 0x01, 0x04, 0x05),
    ("Labyrinth → Labyrinth", 0x02F3C7, 0x42, 0x42, 0x00, 0x02, 0x07),
    ("Labyrinth → Labyrinth", 0x02F3CE, 0x42, 0x42, 0x00, 0x07, 0x07),
    ("Labyrinth → Labyrinth", 0x02F3D5, 0x42, 0x42, 0x00, 0x09, 0x02),
    ("Labyrinth → Labyrinth", 0x02F3DC, 0x42, 0x42, 0x00, 0x09, 0x05),
    ("Labyrinth → Labyrinth", 0x02F3E3, 0x42, 0x42, 0x00, 0x02, 0x00),
    ("Labyrinth → Labyrinth", 0x02F3EA, 0x42, 0x42, 0x00, 0x07, 0x00),
    ("Labyrinth → Map_60", 0x02F3F1, 0x42, 0x60, 0x00, 0x00, 0x02),
    ("Labyrinth → Labyrinth", 0x02F3F8, 0x42, 0x42, 0x00, 0x00, 0x05),
    ("Labyrinth → Castle", 0x02F400, 0x42, 0x00, 0x01, 0x04, 0x05),
    ("Labyrinth → Labyrinth", 0x02F407, 0x42, 0x42, 0x00, 0x02, 0x07),
    ("Labyrinth → Labyrinth", 0x02F40E, 0x42, 0x42, 0x00, 0x07, 0x07),
    ("Labyrinth → Labyrinth", 0x02F415, 0x42, 0x42, 0x00, 0x09, 0x02),
    ("Labyrinth → Labyrinth", 0x02F41C, 0x42, 0x42, 0x00, 0x09, 0x05),
    ("Labyrinth → Labyrinth", 0x02F423, 0x42, 0x42, 0x00, 0x02, 0x00),
    ("Labyrinth → Labyrinth", 0x02F42A, 0x42, 0x42, 0x00, 0x07, 0x00),
    ("Labyrinth → Labyrinth", 0x02F431, 0x42, 0x42, 0x00, 0x00, 0x02),
    ("Labyrinth → Map_60", 0x02F438, 0x42, 0x60, 0x00, 0x00, 0x05),
    ("Labyrinth → Castle", 0x02F440, 0x42, 0x00, 0x01, 0x04, 0x05),
    ("Labyrinth → Labyrinth", 0x02F447, 0x42, 0x42, 0x00, 0x02, 0x07),
    ("Labyrinth → Labyrinth", 0x02F44E, 0x42, 0x42, 0x00, 0x07, 0x07),
    ("Labyrinth → Labyrinth", 0x02F455, 0x42, 0x42, 0x00, 0x09, 0x02),
    ("Labyrinth → Map_60", 0x02F45C, 0x42, 0x60, 0x00, 0x09, 0x05),
    ("Labyrinth → Labyrinth", 0x02F463, 0x42, 0x42, 0x00, 0x02, 0x00),
    ("Labyrinth → Labyrinth", 0x02F46A, 0x42, 0x42, 0x00, 0x07, 0x00),
    ("Labyrinth → Labyrinth", 0x02F471, 0x42, 0x42, 0x00, 0x00, 0x02),
    ("Labyrinth → Labyrinth", 0x02F478, 0x42, 0x42, 0x00, 0x00, 0x05),
    ("Labyrinth → Castle", 0x02F480, 0x42, 0x00, 0x01, 0x04, 0x05),
    ("Labyrinth → Labyrinth", 0x02F487, 0x42, 0x42, 0x00, 0x02, 0x07),
    ("Labyrinth → Labyrinth", 0x02F48E, 0x42, 0x42, 0x00, 0x07, 0x07),
    ("Labyrinth → Map_60", 0x02F495, 0x42, 0x60, 0x00, 0x09, 0x02),
    ("Labyrinth → Labyrinth", 0x02F49C, 0x42, 0x42, 0x00, 0x09, 0x05),
    ("Labyrinth → Labyrinth", 0x02F4A3, 0x42, 0x42, 0x00, 0x02, 0x00),
    ("Labyrinth → Labyrinth", 0x02F4AA, 0x42, 0x42, 0x00, 0x07, 0x00),
    ("Labyrinth → Labyrinth", 0x02F4B1, 0x42, 0x42, 0x00, 0x00, 0x02),
    ("Labyrinth → Labyrinth", 0x02F4B8, 0x42, 0x42, 0x00, 0x00, 0x05),
    ("Labyrinth → Labyrinth", 0x02F4C0, 0x42, 0x42, 0x00, 0x09, 0x02),
    ("Labyrinth → Labyrinth", 0x02F4C7, 0x42, 0x42, 0x00, 0x09, 0x05),
    ("Labyrinth → Labyrinth", 0x02F4CE, 0x42, 0x42, 0x00, 0x00, 0x02),
    ("Labyrinth → Labyrinth", 0x02F4D5, 0x42, 0x42, 0x00, 0x00, 0x05),
    ("Boss: Judgment (Akubar) → Castle", 0x02F518, 0x43, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Library (Orochi) → Castle", 0x02F55B, 0x44, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Reflection (Durran) → Castle", 0x02F5C3, 0x45, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Ambition (DracoLord) → Castle", 0x02F5F2, 0x46, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Demolition (Hargon/Sidoh) → Castle", 0x02F63D, 0x47, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Mastermind (Baramos) → Castle", 0x02F66C, 0x48, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Control (Zoma) → Castle", 0x02F69B, 0x49, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Extinction (Pizzaro) → Castle", 0x02F6CA, 0x4A, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Sleep (Esterk) → Castle", 0x02F6F9, 0x4B, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Bazaar Edge (Mirudraas) → Castle", 0x02F728, 0x4C, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Arena Right (Mudou) → Castle", 0x02F757, 0x4D, 0x00, 0x01, 0x04, 0x05),
    ("Boss: DeathMore → Castle", 0x02F7A2, 0x4E, 0x00, 0x01, 0x04, 0x05),
    ("Boss: Unused (DarkDrium) → Castle", 0x02F7D7, 0x4F, 0x00, 0x01, 0x04, 0x05),
    ("Forest Maze → Gate Floor 2", 0x02F880, 0x53, 0x62, 0x00, 0x09, 0x03),
    ("Forest Maze → Gate Floor 1", 0x02F887, 0x53, 0x61, 0x00, 0x01, 0x07),
    ("Forest Maze → Gate Floor 3", 0x02F88E, 0x53, 0x63, 0x00, 0x08, 0x07),
    ("Forest Maze → Gate Floor 1", 0x02F895, 0x53, 0x61, 0x00, 0x00, 0x03),
    ("Forest Maze → Forest Maze", 0x02F89D, 0x53, 0x53, 0x00, 0x01, 0x00),
    ("Forest Maze → Forest Maze", 0x02F8A4, 0x53, 0x53, 0x00, 0x08, 0x00),
    ("Forest Maze → Forest Maze", 0x02F8AB, 0x53, 0x53, 0x00, 0x09, 0x03),
    ("Forest Maze → Gate Floor 2", 0x02F8B2, 0x53, 0x62, 0x00, 0x01, 0x07),
    ("Forest Maze → Gate Floor 1", 0x02F8BA, 0x53, 0x61, 0x00, 0x01, 0x00),
    ("Forest Maze → Gate Floor 1", 0x02F8C1, 0x53, 0x61, 0x00, 0x08, 0x07),
    ("Forest Maze → Forest Maze", 0x02F8C8, 0x53, 0x53, 0x00, 0x00, 0x03),
    ("Forest Maze → Gate Floor 2", 0x02F8D0, 0x53, 0x62, 0x00, 0x08, 0x00),
    ("Forest Maze → Gate Floor 3", 0x02F8D7, 0x53, 0x63, 0x00, 0x00, 0x05),
    ("Forest Maze → Gate Floor 3", 0x02F8DE, 0x53, 0x63, 0x00, 0x01, 0x07),
    ("Forest Maze → Gate Floor 4", 0x02F8E5, 0x53, 0x64, 0x00, 0x04, 0x07),
    ("Forest Maze → Gate Floor 3", 0x02F8EC, 0x53, 0x63, 0x00, 0x09, 0x05),
    ("Forest Maze → Gate Floor 3", 0x02F8F3, 0x53, 0x63, 0x00, 0x01, 0x00),
    ("Forest Maze → Gate Floor 3", 0x02F8FB, 0x53, 0x63, 0x00, 0x04, 0x00),
]

# Lookup: exits FROM a given room (keyed by the room you're leaving)
EXITS_FROM_ROOM = {}
for _label, _addr, _src_mt, _dst_mt, _scr, _sx, _sy in EXIT_TRANSITIONS:
    EXITS_FROM_ROOM.setdefault(_src_mt, []).append((_label, _addr, _dst_mt, _scr, _sx, _sy))

# Known landing spots on GreatTree (from exit transition data going TO GreatTree)
# Format: label, screen_byte, x, y
GREATTREE_LANDING_PRESETS = [
    ("Near Castle door (scr1)",         0x80, 0x04, 0x04),
    ("Near MedalMan door (scr2)",       0x81, 0x03, 0x02),
    ("Near Arena entrance (scr3)",      0x84, 0x05, 0x03),
    ("Near Library door (scr5)",        0x88, 0x05, 0x03),
    ("Near Well entrance (scr5)",       0x08, 0x04, 0x05),
    ("Near Vault door (scr6)",          0x89, 0x05, 0x01),
    ("Near Starry Shrine door (scr7)",  0x0C, 0x04, 0x06),
    ("Near Old Man door (scr7)",        0x8C, 0x05, 0x01),
    ("Near Copycat door (scr7)",        0x8C, 0x04, 0x04),
    ("Near Renamer door (scr8)",        0x8D, 0x02, 0x01),
]

# Screen byte → human-readable name for display
SCREEN_BYTE_NAMES = {
    0x80: "scr1 Castle", 0x81: "scr2 MedalMan", 0x84: "scr3 Arena",
    0x08: "scr5 Well", 0x88: "scr5 Library", 0x89: "scr6 Vault",
    0x0C: "scr7 Shrine", 0x8C: "scr7 OldMan/Copycat", 0x8D: "scr8 Renamer",
}

# All known routing ROM addresses (for revert tab classification)
ROUTING_ADDRS = set()
for _, addr, *_ in ENTRY_TRANSITIONS:
    # Entry patches: bytes 0, 1 (gate flag), 2 (screen), 3, 4
    ROUTING_ADDRS.add(f"0x{addr:06X}")
    ROUTING_ADDRS.add(f"0x{addr+1:06X}")
    ROUTING_ADDRS.add(f"0x{addr+2:06X}")
    ROUTING_ADDRS.add(f"0x{addr+3:06X}")
    ROUTING_ADDRS.add(f"0x{addr+4:06X}")
for _, addr, *_ in EXIT_TRANSITIONS:
    # Exit patches: bytes 0, 2, 3, 4
    ROUTING_ADDRS.add(f"0x{addr:06X}")
    ROUTING_ADDRS.add(f"0x{addr+2:06X}")
    ROUTING_ADDRS.add(f"0x{addr+3:06X}")
    ROUTING_ADDRS.add(f"0x{addr+4:06X}")


# ============ CROSS-BANK CUSTOM ROOMS SYSTEM ============
# Enables custom rooms stored in bank 0x68+ and loaded via WRAM buffer.
# 5 patches total: 3 in bank 0x0B, 2 in bank 0x00.

CROSSBANK_WRAM_FLAG  = 0xD377   # 1 byte: non-zero = use WRAM room data
CROSSBANK_WRAM_BASE  = 0xD378   # 128 bytes: room data buffer
CROSSBANK_ROOM_BANK  = 0x68     # ROM bank for custom room data (258KB free)
CROSSBANK_FIRST_MT   = 0x65     # First map_type used for cross-bank rooms
CROSSBANK_PTR_TABLE  = 0x02CB43 # Flat addr of pointer table ($0B:$4B43)

# Available map_type slots (currently aliases to existing rooms)
CROSSBANK_SLOTS = [0x65, 0x66, 0x67, 0x68, 0x69,    # alias Labyrinth/Castle
                   0x20, 0x21, 0x22,                  # alias Castle
                   0x0B, 0x0E, 0x11, 0x14, 0x15]      # alias Castle

# WRAM layout: fixed offsets within the 128-byte buffer
_WB = CROSSBANK_WRAM_BASE
_WRAM_OFFSETS = {
    "screen_ptrs": _WB + 0x00,   # 8 bytes (4 slots × 2)
    "step_block":  _WB + 0x08,   # 14 bytes (2-byte RAM ptr + 2 × 6-byte entries)
    "interact_0":  _WB + 0x20,   # 24 bytes max (NPCs + terminator)
    "interact_1":  _WB + 0x38,   # 24 bytes max
    "exit_0":      _WB + 0x50,   # 24 bytes max (exits + terminator)
    "exit_1":      _WB + 0x68,   # 24 bytes max
}

TILESET_NAMES = {
    0x23: "Cave Dark", 0x24: "Dungeon", 0x25: "Temple",
    0x26: "Gate Floor", 0x27: "Lava", 0x29: "Town (outdoor)",
    0x2A: "Castle/Tree (indoor)", 0x2D: "Gate Room (dark)",
    0x30: "House Interior", 0x37: "Maze/Conveyor",
}


def crossbank_infrastructure_patches() -> dict:
    """Return raw_bytes patches for cross-bank room support.

    Only 2 patches, both verified safe:
    - Patch 1: Trampoline in DarkDrium space (bank 0x0B, 47 bytes of 52 available)
    - Patch 2: Copy routine at end of bank 0x00 ($3FE8, 23 bytes of 24 available)

    No WRAM flag needed. The trampoline detects cross-bank rooms by pointer
    value: valid room pointers are $4000-$7FFF (bit 6 of high byte set).
    Redirect entries are $00xx where xx = target bank number.
    """
    patches = {}
    base_lo = CROSSBANK_WRAM_BASE & 0xFF
    base_hi = (CROSSBANK_WRAM_BASE >> 8) & 0xFF

    # Patch 1: Redirect room loader pointer read at correct address $4289
    # The 4 functions that read $4B43 all have: ... 8C 67 2A 66 6F ...
    # The "2A 66 6F" (ld a,(hl+)/ld h,(hl)/ld l,a) is at $4253/$4289/$44B6/$4542
    # We ONLY patch $4289 (main room loader). The other 3 functions follow the
    # pointer naturally — if it points to WRAM ($D378), they read from WRAM.
    patches["0x02C289"] = "C3 A9 77"  # jp $77A9

    # Patch 2: Trampoline in DarkDrium space ($0B:$77A9, 51 bytes of 52)
    # Pointer table entry for cross-bank rooms = $D378 (WRAM address).
    # ROM pointers: $4000-$7FFF (bit 7 = 0). WRAM: $D378 (bit 7 = 1).
    trampoline = [
        # Read pointer from table (HL fully computed including carry)
        0x2A,                       # ld a,(hl+)     — ptr_lo
        0x66,                       # ld h,(hl)      — ptr_hi
        0x6F,                       # ld l,a         — HL = pointer value
        # Check: WRAM pointer? (bit 7 distinguishes ROM from WRAM)
        0xCB, 0x7C,                 # bit 7,h        — ROM=$4x-$7x(bit7=0), WRAM=$Dx(bit7=1)
        0x28, 0x0A,                 # jr z, .done    — if ROM ptr, skip copy (+10)
        # Cross-bank: copy room data from bank 0x68 to WRAM first
        0xE5,                       # push hl        — save WRAM addr ($D378)
        0x3E, CROSSBANK_ROOM_BANK,  # ld a,$68       — target bank
        0x21, 0x00, 0x40,          # ld hl,$4000    — source in target bank
        0xCD, 0xE8, 0x3F,          # call $3FE8     — copy 128B to WRAM (DI/EI)
        0xE1,                       # pop hl         — HL = $D378
        # .done: Steps 2-4 (copy of $428C-$42AB)
        0xFA, 0x25, 0xC9,          # ld a,($C925)   — screen index
        0x87,                       # add a,a
        0x85,                       # add a,l
        0x6F,                       # ld l,a
        0x3E, 0x00,                 # ld a,$00
        0x8C,                       # adc a,h
        0x67,                       # ld h,a
        0x2A,                       # ld a,(hl+)     — step_block_ptr
        0x66,                       # ld h,(hl)
        0x6F,                       # ld l,a
        0x5E,                       # ld e,(hl)      — RAM flag addr
        0x23,                       # inc hl
        0x56,                       # ld d,(hl)
        0x23,                       # inc hl
        0x1A,                       # ld a,(de)      — step value
        0x5F,                       # ld e,a
        0x87,                       # add a,a
        0x83,                       # add a,e
        0x87,                       # add a,a        — × 6
        0x85,                       # add a,l
        0x6F,                       # ld l,a
        0x3E, 0x00,                 # ld a,$00
        0x8C,                       # adc a,h
        0x67,                       # ld h,a
        0x23,                       # inc hl         — skip step_id
        0x23,                       # inc hl         — skip tileset
        0x2A,                       # ld a,(hl+)     — interact_ptr lo
        0x66,                       # ld h,(hl)
        0x6F,                       # ld l,a
        0xC9,                       # ret
    ]
    while len(trampoline) < 52:
        trampoline.append(0xFF)
    assert len(trampoline) == 52

    # Verify: jr z at byte 5, offset 10 → byte 5+2+10 = byte 17 = .done
    assert trampoline[17] == 0xFA, f"jr z lands on 0x{trampoline[17]:02X}, expected 0xFA"
    patches["0x02F7A9"] = " ".join(f"{b:02X}" for b in trampoline)

    # Patch 3: Copy routine at end of bank 0x00 ($3FE8, 22 bytes of 24)
    copy_routine = [
        0xF3,                       # di
        0xEA, 0x00, 0x21,          # ld ($2100),a   — switch to target bank
        0x11, base_lo, base_hi,    # ld de,$D378    — dest
        0x06, 0x80,                 # ld b,128       — count
        0x2A,                       # ld a,(hl+)
        0x12,                       # ld (de),a
        0x13,                       # inc de
        0x05,                       # dec b
        0x20, 0xFA,                 # jr nz,.loop
        0x3E, 0x0B,                 # ld a,$0B       — restore bank
        0xEA, 0x00, 0x21,          # ld ($2100),a
        0xFB,                       # ei
        0xC9,                       # ret
    ]
    assert len(copy_routine) <= 24
    patches["0x003FE8"] = " ".join(f"{b:02X}" for b in copy_routine)

    return patches


def build_custom_room_data(
    tileset: int = 0x26,
    ram_flag: int = 0xD377,          # MUST point to a byte containing 0x00 or 0x01
    step0_id: int = 0x00,            # step_id is cosmetic; INDEX matters (0x00→entry 0)
    step1_id: int = 0x01,            # INDEX 0x01→entry 1
    npcs_step0: list = None,       # [(type, sprite, x, y, script), ...]
    npcs_step1: list = None,
    exits_step0: list = None,      # [(trig_x, trig_y, dest_mt, gate_flag, screen, spawn_x, spawn_y), ...]
    exits_step1: list = None,
) -> bytes:
    """Build 128-byte room data with WRAM-relative pointers.

    Returns bytes ready to write to bank 0x68 at $4000.
    All internal pointers are pre-set to WRAM addresses ($D378+).

    CRITICAL: ram_flag must point to a byte containing 0x00 (for step 0)
    or 0x01 (for step 1). The game uses this value as a direct index:
    value × 6 = byte offset into step entries. Values ≥ 2 overflow the
    2-entry step block and crash. Default $D377 is verified safe (0 refs, value=0).
    """
    if npcs_step0 is None: npcs_step0 = []
    if npcs_step1 is None: npcs_step1 = []
    if exits_step0 is None: exits_step0 = []
    if exits_step1 is None: exits_step1 = []

    buf = bytearray(128)  # zero-filled

    W = CROSSBANK_WRAM_BASE  # $D378

    # Screen pointer block (offset 0x00, 8 bytes)
    step_block_addr = W + 0x08
    buf[0] = step_block_addr & 0xFF
    buf[1] = (step_block_addr >> 8) & 0xFF
    buf[2] = 0xFF; buf[3] = 0xFF   # slot 1 unused
    buf[4] = 0xFF; buf[5] = 0xFF   # slot 2 unused
    buf[6] = 0xFF; buf[7] = 0xFF   # slot 3 unused

    # Step block (offset 0x08, 14 bytes)
    interact0_addr = W + 0x20
    interact1_addr = W + 0x38
    exit0_addr     = W + 0x50
    exit1_addr     = W + 0x68

    buf[0x08] = ram_flag & 0xFF
    buf[0x09] = (ram_flag >> 8) & 0xFF
    # Step 0 entry
    buf[0x0A] = step0_id
    buf[0x0B] = tileset
    buf[0x0C] = interact0_addr & 0xFF
    buf[0x0D] = (interact0_addr >> 8) & 0xFF
    buf[0x0E] = exit0_addr & 0xFF
    buf[0x0F] = (exit0_addr >> 8) & 0xFF
    # Step 1 entry
    buf[0x10] = step1_id
    buf[0x11] = tileset
    buf[0x12] = interact1_addr & 0xFF
    buf[0x13] = (interact1_addr >> 8) & 0xFF
    buf[0x14] = exit1_addr & 0xFF
    buf[0x15] = (exit1_addr >> 8) & 0xFF

    # Interact block 0 (offset 0x20, max 24 bytes)
    pos = 0x20
    for npc in npcs_step0[:4]:
        ntype, sprite, x, y, script = npc
        buf[pos]   = ntype
        buf[pos+1] = sprite
        buf[pos+2] = x
        buf[pos+3] = y
        buf[pos+4] = script
        pos += 5
    buf[pos] = 0xFF  # terminator

    # Interact block 1 (offset 0x38)
    pos = 0x38
    for npc in npcs_step1[:4]:
        ntype, sprite, x, y, script = npc
        buf[pos]   = ntype
        buf[pos+1] = sprite
        buf[pos+2] = x
        buf[pos+3] = y
        buf[pos+4] = script
        pos += 5
    buf[pos] = 0xFF

    # Exit block 0 (offset 0x50, max 24 bytes)
    pos = 0x50
    for ex in exits_step0[:3]:
        trig_x, trig_y, dest_mt, gf, scr, sx, sy = ex
        buf[pos]   = trig_x
        buf[pos+1] = trig_y
        buf[pos+2] = dest_mt
        buf[pos+3] = gf
        buf[pos+4] = scr
        buf[pos+5] = sx
        buf[pos+6] = sy
        pos += 7
    buf[pos] = 0xFF

    # Exit block 1 (offset 0x68)
    pos = 0x68
    for ex in exits_step1[:3]:
        trig_x, trig_y, dest_mt, gf, scr, sx, sy = ex
        buf[pos]   = trig_x
        buf[pos+1] = trig_y
        buf[pos+2] = dest_mt
        buf[pos+3] = gf
        buf[pos+4] = scr
        buf[pos+5] = sx
        buf[pos+6] = sy
        pos += 7
    buf[pos] = 0xFF

    return bytes(buf)


def is_crossbank_enabled(edits: dict) -> bool:
    """Check if cross-bank infrastructure patches are present."""
    raw = edits.get("raw_bytes", {})
    return raw.get("0x02C289") == "C3 A9 77"


def enable_crossbank(edits: dict):
    """Add infrastructure patches to edits. Cleans legacy patches first."""
    disable_crossbank(edits)  # clean slate — remove old/dangerous patches
    raw = edits.setdefault("raw_bytes", {})
    for addr, hex_data in crossbank_infrastructure_patches().items():
        raw[addr] = hex_data


def disable_crossbank(edits: dict):
    """Remove ALL cross-bank patches from edits, including legacy ones."""
    raw = edits.get("raw_bytes", {})
    # Remove current patches
    for addr in crossbank_infrastructure_patches():
        raw.pop(addr, None)
    # Remove ALL legacy patches from every previous version
    for addr in ["0x003A83", "0x003FE8", "0x02C609",
                  "0x02C253", "0x02C287", "0x02C289",
                  "0x02C4B6", "0x02C542", "0x02F7A9"]:
        raw.pop(addr, None)
    # Remove room data in bank 0x68+
    bank_prefix = f"0x{CROSSBANK_ROOM_BANK * 0x4000:06X}"[:4]
    to_remove = [k for k in raw if k.startswith(bank_prefix)]
    for k in to_remove:
        raw.pop(k, None)
    # Remove pointer table patches
    for mt in CROSSBANK_SLOTS:
        ptr_addr = f"0x{CROSSBANK_PTR_TABLE + mt * 2:06X}"
        raw.pop(ptr_addr, None)
    edits.pop("custom_rooms", None)


def get_custom_rooms(edits: dict) -> list:
    """Return list of custom room definitions from edits."""
    return edits.get("custom_rooms", [])


def save_custom_room(edits: dict, room: dict, index: int = -1):
    """Save a custom room definition and generate patches."""
    rooms = edits.setdefault("custom_rooms", [])
    if index >= 0 and index < len(rooms):
        rooms[index] = room
    else:
        rooms.append(room)

    # Regenerate all room patches
    raw = edits.setdefault("raw_bytes", {})
    bank = CROSSBANK_ROOM_BANK
    bank_flat_base = bank * 0x4000  # flat addr of $4000 in target bank

    for i, rm in enumerate(rooms):
        mt = rm.get("map_type", CROSSBANK_SLOTS[i] if i < len(CROSSBANK_SLOTS) else 0x65 + i)

        # Build room binary
        room_bytes = build_custom_room_data(
            tileset=rm.get("tileset", 0x26),
            ram_flag=rm.get("ram_flag", 0xD377),
            step0_id=rm.get("step0_id", 0x00),
            step1_id=rm.get("step1_id", 0x01),
            npcs_step0=rm.get("npcs_step0", []),
            npcs_step1=rm.get("npcs_step1", []),
            exits_step0=rm.get("exits_step0", []),
            exits_step1=rm.get("exits_step1", []),
        )

        # Write room data to bank 0x68 at offset i*128
        rom_offset = bank_flat_base + (i * 128)
        raw[f"0x{rom_offset:06X}"] = " ".join(f"{b:02X}" for b in room_bytes)

        # Set pointer table entry to WRAM address $D378
        # All 4 functions that read the pointer table will follow this to WRAM.
        # Only the main room loader ($4289) goes through our trampoline which
        # copies the data first; the other 3 follow it naturally afterward.
        ptr_table_offset = CROSSBANK_PTR_TABLE + mt * 2
        raw[f"0x{ptr_table_offset:06X}"] = f"{CROSSBANK_WRAM_BASE & 0xFF:02X} {(CROSSBANK_WRAM_BASE >> 8) & 0xFF:02X}"

    # Update MAP_TYPE_NAMES reference in the room definition
    for i, rm in enumerate(rooms):
        rm["_room_index"] = i


def get_routing_edits(edits: dict) -> list:
    """Return list of raw_bytes keys that fall within routing address ranges."""
    return [k for k in edits.get("raw_bytes", {}) if k in ROUTING_ADDRS]


def get_npc_edits(edits: dict) -> list:
    """Return list of raw_bytes keys that are NPC edits (from npc_catalog.json)."""
    catalog_path = Path("extracted/npc_catalog.json")
    if not catalog_path.exists():
        return []
    try:
        catalog = json.loads(catalog_path.read_text())
    except Exception:
        return []
    npc_addrs = set()
    for npc in catalog:
        f = npc["flat"]
        for off in range(4):  # type, sprite, x, y
            npc_addrs.add(f"0x{f+off:06X}")
    return [k for k in edits.get("raw_bytes", {}) if k in npc_addrs]


# ══════════════════════════════════════════════════════════════
# TABS
# ══════════════════════════════════════════════════════════════

tab_enc, tab_start, tab_estats, tab_mon, tab_text, tab_routing, tab_npcs, tab_rooms, tab_random, tab_revert, tab_build, tab_info = st.tabs(
    ["⚔️ Encounters", "🌟 Starter", "📊 Enemy Stats", "🐉 Monsters", "💬 Text",
     "🚪 Routing", "👤 NPCs", "🏠 Custom Rooms", "🎲 Randomize", "↩️ Revert", "🛠 Build", "ℹ️ Info"]
)


# ============ ENCOUNTERS TAB ============
with tab_enc:
    st.markdown("### Gate Encounter Editor")
    st.markdown(
        "Change which monsters appear on each floor of each gate. "
        "Edits go to `raw_bytes` — the build pipeline patches them into the ROM."
    )

    # ── Per-gate boss join system ──
    join_enabled = is_join_system_enabled(edits)
    n_forced = count_gates_forced(edits) if join_enabled else 0

    with st.expander(
        f"🏆 Boss Join System — {'✅ Enabled ({} gates forced)'.format(n_forced) if join_enabled else '❌ Disabled'}",
        expanded=not join_enabled,
    ):
        st.markdown(
            "Control which bosses join your party after defeat. "
            "Story bosses (Healer, FaceTree, etc.) always join naturally. "
            "This system lets you force **non-story bosses** to join too, on a per-gate basis."
        )
        if join_enabled:
            col_toggle, col_all, col_none = st.columns([2, 1, 1])
            with col_toggle:
                if st.button("🔌 Disable join system"):
                    disable_join_system(edits)
                    save_edits(edits)
                    st.rerun()
            with col_all:
                if st.button("✅ All gates ON"):
                    for g in range(32):
                        set_gate_join_flag(g, edits, True)
                    save_edits(edits)
                    st.rerun()
            with col_none:
                if st.button("❌ All gates OFF"):
                    for g in range(32):
                        set_gate_join_flag(g, edits, False)
                    save_edits(edits)
                    st.rerun()

            # Grid of gate toggles
            gate_cols = st.columns(4)
            for g in range(32):
                with gate_cols[g % 4]:
                    boss = GATE_BOSSES.get(g, "?")
                    flag = get_gate_join_flag(g, edits)
                    new_flag = st.checkbox(
                        f"{g}: {boss}",
                        value=flag,
                        key=f"join_gate_{g}",
                    )
                    if new_flag != flag:
                        set_gate_join_flag(g, edits, new_flag)
                        save_edits(edits)
                        st.rerun()
        else:
            if st.button("⚡ Enable join system"):
                enable_join_system(edits)
                # Default: enable all gates
                for g in range(32):
                    set_gate_join_flag(g, edits, True)
                save_edits(edits)
                st.rerun()

    if not encounters_data:
        st.error(
            "No `extracted/encounters.json` found. "
            "Run `uv run python -m tools.dump_encounters` first."
        )
    else:
        # Gate selector
        gate_id = st.selectbox(
            "Select gate",
            options=list(range(32)),
            format_func=lambda g: f"{g:2d} — {GATE_NAMES.get(g, f'Gate {g}')}  "
                                  f"(Boss: {GATE_BOSSES.get(g, '?')})",
        )

        gate_key = str(gate_id)
        gate_info = encounters_data.get(gate_key, {})
        floor_groups = gate_info.get("floor_groups", [])

        if not floor_groups:
            st.info("No encounter data for this gate.")
        else:
            for fg_idx, fg in enumerate(floor_groups):
                pool_idx = fg["pool_index"]
                floor_range = fg["floor_range"]
                original_monsters = fg["monsters"]

                st.markdown(f"---")
                st.markdown(f"#### {floor_range}  ·  Pool #{pool_idx}")

                cols = st.columns(len(original_monsters))

                for slot_i, (col, orig_m) in enumerate(zip(cols, original_monsters)):
                    with col:
                        orig_eid = orig_m["enemy_stats_id"]
                        orig_weight = orig_m["weight"]
                        cur_eid = get_current_eid_for_slot(pool_idx, slot_i, edits, orig_eid)
                        cur_weight = get_current_weight_for_slot(pool_idx, slot_i, edits, orig_weight)

                        # Effective stats for display
                        eff = get_effective_es(cur_eid, edits, es_data) if es_data else {}
                        eff_name = eff.get("species_name", eid_lookup.get(cur_eid, {}).get("name", "?"))
                        eff_lv = eff.get("level", "?")
                        is_modified = (cur_eid != orig_eid) or (cur_weight != orig_weight)
                        label_suffix = " ✏️" if is_modified else ""

                        st.markdown(f"**Slot {slot_i + 1}** — {eff_name} Lv{eff_lv}{label_suffix}")

                        # Monster dropdown
                        if cur_eid in eid_list:
                            default_idx = eid_list.index(cur_eid)
                        else:
                            default_idx = 0

                        new_eid = st.selectbox(
                            "Monster",
                            options=eid_list,
                            index=default_idx,
                            format_func=lambda e: _eid_label(e),
                            key=f"enc_eid_{pool_idx}_{slot_i}",
                        )

                        # Weight slider
                        new_weight = st.slider(
                            "Weight",
                            min_value=0, max_value=255,
                            value=cur_weight,
                            key=f"enc_wt_{pool_idx}_{slot_i}",
                            help="Higher = more common relative to other slots",
                        )

                        if orig_weight > 0:
                            st.caption(f"Orig: {orig_m['monster_name']} (wt {orig_weight})")

                        # Inline stat editing for the selected EID
                        if es_data:
                            sel_eid = st.session_state.get(f"enc_eid_{pool_idx}_{slot_i}", cur_eid)
                            sel_eff = get_effective_es(sel_eid, edits, es_data)
                            with st.expander(f"✏️ Edit EID {sel_eid} stats"):
                                if species_options:
                                    sp_list_i = sorted(species_options.keys())
                                    sp_cur = sel_eff.get("species_id", 0)
                                    sp_idx_i = sp_list_i.index(sp_cur) if sp_cur in sp_list_i else 0
                                    new_isp = st.selectbox(
                                        "Species", options=sp_list_i, index=sp_idx_i,
                                        format_func=lambda s: species_options.get(s, f"0x{s:02X}"),
                                        key=f"isp_{pool_idx}_{slot_i}")
                                else:
                                    new_isp = sel_eff.get("species_id", 0)
                                new_ilv = st.number_input("Level", 0, 99, value=sel_eff.get("level", 1), key=f"ilv_{pool_idx}_{slot_i}")
                                ic1, ic2 = st.columns(2)
                                with ic1:
                                    new_ihp  = st.number_input("HP",  0, 9999, value=sel_eff.get("hp", 0),  key=f"ihp_{pool_idx}_{slot_i}")
                                    new_iatk = st.number_input("ATK", 0, 9999, value=sel_eff.get("atk", 0), key=f"iatk_{pool_idx}_{slot_i}")
                                    new_iagl = st.number_input("AGL", 0, 9999, value=sel_eff.get("agl", 0), key=f"iagl_{pool_idx}_{slot_i}")
                                with ic2:
                                    new_imp  = st.number_input("MP",  0, 9999, value=sel_eff.get("mp", 0),  key=f"imp_{pool_idx}_{slot_i}")
                                    new_idef = st.number_input("DEF", 0, 9999, value=sel_eff.get("def", 0), key=f"idef_{pool_idx}_{slot_i}")
                                    new_iint = st.number_input("INT", 0, 9999, value=sel_eff.get("int", 0), key=f"iint_{pool_idx}_{slot_i}")
                                if st.button("💾 Save stats", key=f"isave_{pool_idx}_{slot_i}"):
                                    orig_es = es_data[sel_eid] if sel_eid < len(es_data) else {}
                                    inline_writes = [
                                        (ES_SPECIES, 1, new_isp,  orig_es.get("species_id", 0)),
                                        (ES_LEVEL,   1, new_ilv,  orig_es.get("level", 0)),
                                        (ES_HP,      2, new_ihp,  orig_es.get("hp", 0)),
                                        (ES_MP,      2, new_imp,  orig_es.get("mp", 0)),
                                        (ES_ATK,     2, new_iatk, orig_es.get("atk", 0)),
                                        (ES_DEF,     2, new_idef, orig_es.get("def", 0)),
                                        (ES_AGL,     2, new_iagl, orig_es.get("agl", 0)),
                                        (ES_INT,     2, new_iint, orig_es.get("int", 0)),
                                    ]
                                    ch = 0
                                    for foff, sz, nv, ov in inline_writes:
                                        k = hex_offset(es_flat_offset(sel_eid, foff))
                                        if nv != ov:
                                            edits["raw_bytes"][k] = f"{nv:02X}" if sz == 1 else le16(nv)
                                            ch += 1
                                        elif k in edits.get("raw_bytes", {}):
                                            del edits["raw_bytes"][k]
                                    save_edits(edits)
                                    st.success(f"Saved {ch} stat edit(s) for EID {sel_eid}")
                                    st.rerun()

                # Total weight preview for this floor group
                total_new_wt = sum(
                    st.session_state.get(f"enc_wt_{pool_idx}_{i}", original_monsters[i]["weight"])
                    for i in range(len(original_monsters))
                )
                if total_new_wt > 0:
                    pcts = []
                    for i in range(len(original_monsters)):
                        w = st.session_state.get(f"enc_wt_{pool_idx}_{i}", original_monsters[i]["weight"])
                        eid_val = st.session_state.get(f"enc_eid_{pool_idx}_{i}", original_monsters[i]["enemy_stats_id"])
                        eff_i = get_effective_es(eid_val, edits, es_data) if es_data else {}
                        name = eff_i.get("species_name", eid_lookup.get(eid_val, {}).get("name", "?"))
                        lv = eff_i.get("level", "")
                        pcts.append(f"{name} Lv{lv} {w/total_new_wt*100:.0f}%")
                    st.caption("Preview: " + " · ".join(pcts))

                # Save button for this floor group
                if st.button(f"💾 Save {floor_range}", key=f"save_enc_{gate_id}_{fg_idx}"):
                    changes = 0
                    for slot_i, orig_m in enumerate(original_monsters):
                        new_eid = st.session_state.get(
                            f"enc_eid_{pool_idx}_{slot_i}", orig_m["enemy_stats_id"]
                        )
                        new_weight = st.session_state.get(
                            f"enc_wt_{pool_idx}_{slot_i}", orig_m["weight"]
                        )

                        # Write EID if changed
                        eid_offset = POOL_BLOCK_BASE + pool_idx * POOL_BLOCK_SIZE + 10 + slot_i * 2
                        eid_key = hex_offset(eid_offset)
                        if new_eid != orig_m["enemy_stats_id"]:
                            edits["raw_bytes"][eid_key] = le16(new_eid)
                            changes += 1
                        elif eid_key in edits.get("raw_bytes", {}):
                            # Reverted to original — remove edit
                            del edits["raw_bytes"][eid_key]

                        # Write weight if changed
                        wt_offset = POOL_BLOCK_BASE + pool_idx * POOL_BLOCK_SIZE + 20 + slot_i
                        wt_key = hex_offset(wt_offset)
                        if new_weight != orig_m["weight"]:
                            edits["raw_bytes"][wt_key] = f"{new_weight:02X}"
                            changes += 1
                        elif wt_key in edits.get("raw_bytes", {}):
                            del edits["raw_bytes"][wt_key]

                    save_edits(edits)
                    if changes > 0:
                        st.success(f"Saved {changes} encounter edit(s) for {floor_range}")
                    else:
                        st.info("No changes (matches original)")

            # ── Gate Boss Section ──────────────────────────────────
            st.markdown("---")
            st.markdown(f"#### 👑 Gate Boss")

            # Fight EID (byte 0)
            orig_boss_eid = BOSS_EIDS_ORIGINAL.get(gate_id, 0)
            boss_eid_offset = BOSS_TABLE_BASE + gate_id * BOSS_TABLE_STRIDE
            boss_eid_key = hex_offset(boss_eid_offset)
            boss_edit = get_raw_byte_edit(boss_eid_key, edits)
            cur_boss_eid = int(boss_edit.strip(), 16) if boss_edit else orig_boss_eid

            # Join EID (bytes 2-3, 16-bit LE)
            orig_join_eid = BOSS_JOIN_ORIGINAL.get(gate_id, 0)
            join_eid_offset = BOSS_TABLE_BASE + gate_id * BOSS_TABLE_STRIDE + 2
            join_eid_key = hex_offset(join_eid_offset)
            join_edit = get_raw_byte_edit(join_eid_key, edits)
            if join_edit:
                parts = join_edit.strip().split()
                cur_join_eid = int(parts[0], 16) | (int(parts[1], 16) << 8)
            else:
                cur_join_eid = orig_join_eid

            boss_eff = get_effective_es(cur_boss_eid, edits, es_data) if es_data else {}
            boss_name = boss_eff.get("species_name", "?")
            boss_lv = boss_eff.get("level", "?")

            join_eff = get_effective_es(cur_join_eid, edits, es_data) if es_data else {}
            join_name = join_eff.get("species_name", "?")
            join_lv = join_eff.get("level", "?")

            fight_mod = " ✏️" if cur_boss_eid != orig_boss_eid else ""
            join_mod = " ✏️" if cur_join_eid != orig_join_eid else ""

            st.markdown(
                f"**Fight:** {boss_name} Lv{boss_lv} (EID {cur_boss_eid}){fight_mod}  ·  "
                f"**Joins:** {join_name} Lv{join_lv} (EID {cur_join_eid}){join_mod}  ·  "
                f"Original: {GATE_BOSSES.get(gate_id, '?')}"
            )

            # Per-gate force-join toggle (only if join system is enabled)
            if is_join_system_enabled(edits):
                gate_flag = get_gate_join_flag(gate_id, edits)
                new_gate_flag = st.checkbox(
                    f"Force {GATE_BOSSES.get(gate_id, 'boss')} to join after defeat",
                    value=gate_flag,
                    key=f"boss_join_toggle_{gate_id}",
                    help="Non-story bosses only. Story bosses (Healer, FaceTree, etc.) join naturally regardless.",
                )
                if new_gate_flag != gate_flag:
                    set_gate_join_flag(gate_id, edits, new_gate_flag)
                    save_edits(edits)
                    st.rerun()

            fcol, jcol = st.columns(2)
            with fcol:
                if cur_boss_eid in eid_list:
                    boss_default_idx = eid_list.index(cur_boss_eid)
                else:
                    boss_default_idx = 0
                new_boss_eid = st.selectbox(
                    "Boss fight monster",
                    options=eid_list,
                    index=boss_default_idx,
                    format_func=lambda e: _eid_label(e),
                    key=f"boss_eid_{gate_id}",
                )
            with jcol:
                if cur_join_eid in eid_list:
                    join_default_idx = eid_list.index(cur_join_eid)
                else:
                    join_default_idx = 0
                new_join_eid = st.selectbox(
                    "Monster that joins after win",
                    options=eid_list,
                    index=join_default_idx,
                    format_func=lambda e: _eid_label(e),
                    key=f"join_eid_{gate_id}",
                )

            if st.button("💾 Save boss fight + join", key=f"save_boss_{gate_id}"):
                changes = 0
                # Fight EID (1 byte)
                if new_boss_eid != orig_boss_eid:
                    edits["raw_bytes"][boss_eid_key] = f"{new_boss_eid:02X}"
                    changes += 1
                elif boss_eid_key in edits.get("raw_bytes", {}):
                    del edits["raw_bytes"][boss_eid_key]
                # Join EID (2 bytes LE)
                if new_join_eid != orig_join_eid:
                    edits["raw_bytes"][join_eid_key] = le16(new_join_eid)
                    changes += 1
                elif join_eid_key in edits.get("raw_bytes", {}):
                    del edits["raw_bytes"][join_eid_key]
                save_edits(edits)
                if changes > 0:
                    st.success(f"Saved {changes} boss edit(s)")
                    st.rerun()
                else:
                    st.info("No changes")

            # Inline boss stat editing (fight + join)
            if es_data:
                sel_fight = st.session_state.get(f"boss_eid_{gate_id}", cur_boss_eid)
                sel_join = st.session_state.get(f"join_eid_{gate_id}", cur_join_eid)

                for label, sel_eid, prefix in [
                    ("boss fight", sel_fight, "bf"),
                    ("join monster", sel_join, "bj"),
                ]:
                    sel_eff = get_effective_es(sel_eid, edits, es_data)
                    with st.expander(f"✏️ Edit {label} EID {sel_eid} stats"):
                        if species_options:
                            sp_list_b = sorted(species_options.keys())
                            sp_cur_b = sel_eff.get("species_id", 0)
                            sp_idx_b = sp_list_b.index(sp_cur_b) if sp_cur_b in sp_list_b else 0
                            new_sp_b = st.selectbox(
                                "Species", options=sp_list_b, index=sp_idx_b,
                                format_func=lambda s: species_options.get(s, f"0x{s:02X}"),
                                key=f"{prefix}sp_{gate_id}")
                        else:
                            new_sp_b = sel_eff.get("species_id", 0)

                        new_lv_b = st.number_input("Level", 0, 99, value=sel_eff.get("level", 1), key=f"{prefix}lv_{gate_id}")
                        bc1, bc2 = st.columns(2)
                        with bc1:
                            new_hp_b  = st.number_input("HP",  0, 9999, value=sel_eff.get("hp", 0),  key=f"{prefix}hp_{gate_id}")
                            new_atk_b = st.number_input("ATK", 0, 9999, value=sel_eff.get("atk", 0), key=f"{prefix}atk_{gate_id}")
                            new_agl_b = st.number_input("AGL", 0, 9999, value=sel_eff.get("agl", 0), key=f"{prefix}agl_{gate_id}")
                        with bc2:
                            new_mp_b  = st.number_input("MP",  0, 9999, value=sel_eff.get("mp", 0),  key=f"{prefix}mp_{gate_id}")
                            new_def_b = st.number_input("DEF", 0, 9999, value=sel_eff.get("def", 0), key=f"{prefix}def_{gate_id}")
                            new_int_b = st.number_input("INT", 0, 9999, value=sel_eff.get("int", 0), key=f"{prefix}int_{gate_id}")

                        if st.button("💾 Save stats", key=f"{prefix}save_{gate_id}"):
                            orig_b = es_data[sel_eid] if sel_eid < len(es_data) else {}
                            b_writes = [
                                (ES_SPECIES, 1, new_sp_b,  orig_b.get("species_id", 0)),
                                (ES_LEVEL,   1, new_lv_b,  orig_b.get("level", 0)),
                                (ES_HP,      2, new_hp_b,  orig_b.get("hp", 0)),
                                (ES_MP,      2, new_mp_b,  orig_b.get("mp", 0)),
                                (ES_ATK,     2, new_atk_b, orig_b.get("atk", 0)),
                                (ES_DEF,     2, new_def_b, orig_b.get("def", 0)),
                                (ES_AGL,     2, new_agl_b, orig_b.get("agl", 0)),
                                (ES_INT,     2, new_int_b, orig_b.get("int", 0)),
                            ]
                            ch = 0
                            for foff, sz, nv, ov in b_writes:
                                k = hex_offset(es_flat_offset(sel_eid, foff))
                                if nv != ov:
                                    edits["raw_bytes"][k] = f"{nv:02X}" if sz == 1 else le16(nv)
                                    ch += 1
                                elif k in edits.get("raw_bytes", {}):
                                    del edits["raw_bytes"][k]
                            save_edits(edits)
                            st.success(f"Saved {ch} stat edit(s) for EID {sel_eid}")
                            st.rerun()


# ============ STARTER MONSTER TAB ============
with tab_start:
    st.markdown("### Starter Monster Editor")
    st.markdown(
        "The starter uses **enemy_stats_id 1** in the enemy stats table at "
        "flat ROM offset `0x50C36`. Changes here write directly to `raw_bytes`."
    )

    col_sp, col_lv = st.columns(2)

    with col_sp:
        cur_species = get_current_starter_value("species", edits)
        if species_options:
            species_list = sorted(species_options.keys())
            default_sp_idx = species_list.index(cur_species) if cur_species in species_list else 0
            new_species = st.selectbox(
                "Species",
                options=species_list,
                index=default_sp_idx,
                format_func=lambda s: species_options.get(s, f"0x{s:02X}"),
            )
        else:
            new_species = st.number_input("Species ID", 0, 255, value=cur_species)

    with col_lv:
        cur_level = get_current_starter_value("level", edits)
        new_level = st.number_input("Level", 1, 99, value=cur_level)

    st.markdown("#### Stats")
    c1, c2, c3 = st.columns(3)

    with c1:
        new_hp = st.number_input("HP", 1, 999, value=get_current_starter_value("hp", edits))
        new_mp = st.number_input("MP", 0, 999, value=get_current_starter_value("mp", edits))
    with c2:
        new_atk = st.number_input("ATK", 1, 999, value=get_current_starter_value("atk", edits))
        new_def = st.number_input("DEF", 1, 999, value=get_current_starter_value("def", edits))
    with c3:
        new_agl = st.number_input("AGL", 1, 999, value=get_current_starter_value("agl", edits))
        new_int = st.number_input("INT", 1, 999, value=get_current_starter_value("int", edits))

    # Show what's changed vs defaults
    starter_preview = {
        "species": new_species, "level": new_level,
        "hp": new_hp, "mp": new_mp,
        "atk": new_atk, "def": new_def,
        "agl": new_agl, "int": new_int,
    }
    diffs = [f for f in starter_preview if starter_preview[f] != STARTER_DEFAULTS[f]]
    if diffs:
        sp_name = species_options.get(new_species, f"0x{new_species:02X}") if species_options else f"0x{new_species:02X}"
        st.info(
            f"Modified vs default Slime: **{', '.join(diffs)}** → "
            f"{sp_name.split(' — ')[-1] if ' — ' in str(sp_name) else sp_name} "
            f"Lv{new_level}  HP:{new_hp} MP:{new_mp} ATK:{new_atk} "
            f"DEF:{new_def} AGL:{new_agl} INT:{new_int}"
        )

    if st.button("💾 Save Starter Monster"):
        write_map = {
            "species": (0x50C36, 1, new_species),
            "level":   (0x50C3A, 1, new_level),
            "hp":      (0x50C3B, 2, new_hp),
            "mp":      (0x50C3D, 2, new_mp),
            "atk":     (0x50C3F, 2, new_atk),
            "def":     (0x50C41, 2, new_def),
            "agl":     (0x50C43, 2, new_agl),
            "int":     (0x50C45, 2, new_int),
        }
        changes = 0
        for field, (offset, size, value) in write_map.items():
            key = hex_offset(offset)
            if value != STARTER_DEFAULTS[field]:
                if size == 1:
                    edits["raw_bytes"][key] = f"{value:02X}"
                else:
                    edits["raw_bytes"][key] = le16(value)
                changes += 1
            elif key in edits.get("raw_bytes", {}):
                del edits["raw_bytes"][key]
        save_edits(edits)
        if changes > 0:
            st.success(f"Saved {changes} starter edits to raw_bytes")
        else:
            st.info("Starter matches defaults — no edits needed")


# ============ ENEMY STATS TAB ============
with tab_estats:
    st.markdown("### Enemy Stats Editor")
    st.markdown(
        "Each enemy_stats_id (EID) is a 25-byte stat block: species, level, HP, MP, "
        "ATK, DEF, AGL, INT. Encounter pools and bosses reference these by EID. "
        "Edit an EID here to change what a monster looks like when it appears in battle."
    )

    es_data = load_enemy_stats_data()
    if not es_data:
        st.error(
            "No `extracted/enemy_stats.json` found. "
            "Run `uv run python -m tools.dump_enemy_stats` first."
        )
    else:
        # ── EID selector ──
        es_eid = st.selectbox(
            "Select enemy stats entry",
            options=[e["enemy_stats_id"] for e in es_data],
            format_func=lambda eid: _eid_label(eid) if eid in eid_lookup else f"{eid:3d} — ???",
            key="es_eid_select",
        )

        es_entry = es_data[es_eid]  # entries are ordered by EID
        es_rom = es_entry["flat_offset"]

        st.caption(f"ROM: {es_rom}  ·  25 bytes  ·  EID {es_eid}")

        # ── Show which gates use this EID ──
        if encounters_data:
            usage = []
            for gk, gd in encounters_data.items():
                for fg in gd.get("floor_groups", []):
                    for m in fg.get("monsters", []):
                        if m["enemy_stats_id"] == es_eid:
                            usage.append(f"{gd['name']} ({fg['floor_range']})")
            if usage:
                st.info(f"Used in: {', '.join(usage[:8])}" +
                        (f" +{len(usage)-8} more" if len(usage) > 8 else ""))

        # ── Editable fields ──
        col_sp, col_lv = st.columns(2)

        with col_sp:
            cur_sp = get_current_es_value(es_eid, ES_SPECIES, 1, edits, es_entry["species_id"])
            if species_options:
                sp_list = sorted(species_options.keys())
                sp_idx = sp_list.index(cur_sp) if cur_sp in sp_list else 0
                new_sp = st.selectbox("Species", options=sp_list, index=sp_idx,
                                      format_func=lambda s: species_options.get(s, f"0x{s:02X}"),
                                      key="es_species")
            else:
                new_sp = st.number_input("Species ID", 0, 255, value=cur_sp, key="es_species")

        with col_lv:
            cur_lv = get_current_es_value(es_eid, ES_LEVEL, 1, edits, es_entry["level"])
            new_lv = st.number_input("Level", 0, 99, value=cur_lv, key="es_level")

        c1, c2, c3 = st.columns(3)
        with c1:
            cur_hp = get_current_es_value(es_eid, ES_HP, 2, edits, es_entry["hp"])
            new_es_hp = st.number_input("HP", 0, 9999, value=cur_hp, key="es_hp")
            cur_mp = get_current_es_value(es_eid, ES_MP, 2, edits, es_entry["mp"])
            new_es_mp = st.number_input("MP", 0, 9999, value=cur_mp, key="es_mp")
        with c2:
            cur_atk = get_current_es_value(es_eid, ES_ATK, 2, edits, es_entry["atk"])
            new_es_atk = st.number_input("ATK", 0, 9999, value=cur_atk, key="es_atk")
            cur_def = get_current_es_value(es_eid, ES_DEF, 2, edits, es_entry["def"])
            new_es_def = st.number_input("DEF", 0, 9999, value=cur_def, key="es_def")
        with c3:
            cur_agl = get_current_es_value(es_eid, ES_AGL, 2, edits, es_entry["agl"])
            new_es_agl = st.number_input("AGL", 0, 9999, value=cur_agl, key="es_agl")
            cur_int = get_current_es_value(es_eid, ES_INT, 2, edits, es_entry["int"])
            new_es_int = st.number_input("INT", 0, 9999, value=cur_int, key="es_int")

        # ── Show diff ──
        es_fields = {
            "species": (ES_SPECIES, 1, new_sp, es_entry["species_id"]),
            "level":   (ES_LEVEL,   1, new_lv, es_entry["level"]),
            "hp":      (ES_HP,      2, new_es_hp, es_entry["hp"]),
            "mp":      (ES_MP,      2, new_es_mp, es_entry["mp"]),
            "atk":     (ES_ATK,     2, new_es_atk, es_entry["atk"]),
            "def":     (ES_DEF,     2, new_es_def, es_entry["def"]),
            "agl":     (ES_AGL,     2, new_es_agl, es_entry["agl"]),
            "int":     (ES_INT,     2, new_es_int, es_entry["int"]),
        }
        diffs = [f for f, (_, _, new, orig) in es_fields.items() if new != orig]
        if diffs:
            sp_name = species_options.get(new_sp, f"0x{new_sp:02X}").split(" — ")[-1] if species_options else f"0x{new_sp:02X}"
            st.warning(
                f"Modified: **{', '.join(diffs)}** → "
                f"{sp_name} Lv{new_lv}  HP:{new_es_hp} MP:{new_es_mp} "
                f"ATK:{new_es_atk} DEF:{new_es_def} AGL:{new_es_agl} INT:{new_es_int}"
            )

        es_save, es_revert = st.columns(2)
        with es_save:
            if st.button("💾 Save EID Edit", key="save_es"):
                changes = 0
                for field, (foff, size, new_val, orig_val) in es_fields.items():
                    key = hex_offset(es_flat_offset(es_eid, foff))
                    if new_val != orig_val:
                        if size == 1:
                            edits["raw_bytes"][key] = f"{new_val:02X}"
                        else:
                            edits["raw_bytes"][key] = le16(new_val)
                        changes += 1
                    elif key in edits.get("raw_bytes", {}):
                        del edits["raw_bytes"][key]
                save_edits(edits)
                if changes > 0:
                    st.success(f"Saved {changes} field(s) for EID {es_eid}")
                else:
                    st.info("No changes vs original")

        with es_revert:
            # Check if any edits exist for this EID
            eid_edit_keys = [
                hex_offset(es_flat_offset(es_eid, foff))
                for foff in [ES_SPECIES, ES_LEVEL, ES_HP, ES_MP, ES_ATK, ES_DEF, ES_AGL, ES_INT]
            ]
            has_edits = any(k in edits.get("raw_bytes", {}) for k in eid_edit_keys)
            if st.button("↩️ Revert EID", key="revert_es", disabled=not has_edits):
                for k in eid_edit_keys:
                    edits["raw_bytes"].pop(k, None)
                save_edits(edits)
                st.success(f"Reverted EID {es_eid} to original")
                st.rerun()

        # ── Batch view of edited EIDs ──
        all_es_edits = {}
        for k, v in edits.get("raw_bytes", {}).items():
            off = int(k, 16)
            if ENEMY_STATS_ROM_BASE <= off < ENEMY_STATS_ROM_BASE + 487 * ENEMY_STATS_ENTRY_SIZE:
                eid_num = (off - ENEMY_STATS_ROM_BASE) // ENEMY_STATS_ENTRY_SIZE
                all_es_edits.setdefault(eid_num, []).append((k, v))

        if all_es_edits:
            with st.expander(f"📋 All edited EIDs ({len(all_es_edits)})"):
                for eid_num in sorted(all_es_edits.keys()):
                    name = eid_lookup.get(eid_num, {}).get("name", "???")
                    fields = ", ".join(f"{k}={v}" for k, v in all_es_edits[eid_num])
                    st.text(f"EID {eid_num:3d} ({name}): {fields}")


# ============ MONSTER TAB ============
with tab_mon:
    if not monsters:
        st.error("No `extracted/monsters.json` found.")
    else:
        mid = st.selectbox(
            "Pick monster",
            options=[m["id"] for m in monsters],
            format_func=lambda i: f"{i:3d}  {monsters[i]['name']}  ({monsters[i]['family']})",
        )
        m = monsters[mid]
        override = edits["monster_stats"].get(str(mid), {})

        c1, c2, c3 = st.columns(3)
        cap = c1.number_input("Level cap (1-99)", 1, 99,
                              value=override.get("level_cap", m["level_cap"]))
        skills_default = override.get("base_skills", m["base_skills"])
        s1 = c2.number_input("Skill 1 ID", 0, 255, value=skills_default[0])
        s2 = c2.number_input("Skill 2 ID", 0, 255, value=skills_default[1])
        s3 = c2.number_input("Skill 3 ID", 0, 255, value=skills_default[2])
        fam = c3.number_input("Family", 0, 9,
                              value=override.get("family", m.get("family_id", 0))
                              if isinstance(m.get("family_id"), int) else 0)

        if st.button("Save monster edit"):
            edits["monster_stats"][str(mid)] = {
                "level_cap": cap, "base_skills": [s1, s2, s3]
            }
            save_edits(edits)
            st.success(f"Saved edit for monster #{mid} ({m['name']})")


# ============ TEXT TAB ============
with tab_text:
    st.markdown("### Dialogue editor")
    st.markdown(
        "**Quick reference:**  `\\n` = line break + wait  ·  `---` = page break  "
        "·  `[NAME]` = player name  ·  `[AND]` = `and` glyph"
    )
    query = st.text_input("Search dialogue", "")
    allow_repoint = st.checkbox(
        "Allow repointing (use bank free space if too long)", value=True
    )

    NATURAL_TO_RAW = [
        ("---",     "{FA}{F7}{EF}{EE}"),
        ("[NAME]",  "{F6}"),
        ("[AND]",   "{B6}"),
        ("\n",      "{EF}{EE}"),
    ]

    def to_natural(raw: str) -> str:
        s = raw
        for natural, rawcode in NATURAL_TO_RAW:
            s = s.replace(rawcode, natural)
        return s

    def from_natural(natural: str) -> str:
        s = natural
        for natural_token, rawcode in NATURAL_TO_RAW:
            s = s.replace(natural_token, rawcode)
        return s

    if query:
        hits = [b for b in blobs if query.lower() in b["text"].lower()][:30]
        st.write(f"{len(hits)} matches")
        for b in hits:
            loc = f"{b['bank']}:{b['offset']}"
            max_bytes = b["length"]
            ptr_loc = find_ptr_location(loc, tables)
            bank_free = sum(r["length"] for r in free.get(b["bank"], []))

            existing = edits["text"].get(loc)
            current = (existing if isinstance(existing, str)
                       else existing["text"] if isinstance(existing, dict)
                       else b["text"])

            header = f"{loc}  · orig {max_bytes}B · bank free {bank_free}B"
            is_edited = loc in edits.get("text", {})
            edit_badge = " ✏️ EDITED" if is_edited else ""
            with st.expander(f"{header}{edit_badge}\n→ {to_natural(b['text'])[:60]}"):
                col_a, col_b = st.columns([3, 1])

                with col_b:
                    st.markdown("**Insert at cursor** (copy):")
                    st.code("\\n", language=None)
                    st.caption("line break + wait")
                    st.code("---", language=None)
                    st.caption("page break")
                    st.code("[NAME]", language=None)
                    st.caption("player name")
                    st.code("[AND]", language=None)
                    st.caption("'and' glyph")
                    st.markdown("**Raw controls** (advanced):")
                    st.code("{EE} {EF} {FA} {F7} {EB} {EA} {A3}", language=None)

                with col_a:
                    natural_mode = st.checkbox(
                        "Natural mode (newlines & --- instead of brackets)",
                        value=True, key=f"nat_{loc}",
                    )
                    if natural_mode:
                        display = to_natural(current)
                        new_display = st.text_area(
                            "Text", value=display, key=f"ta_nat_{loc}", height=200,
                        )
                        new_raw = from_natural(new_display)
                    else:
                        new_raw = st.text_area(
                            "Raw text (with all {XX} codes)",
                            value=current, key=f"ta_raw_{loc}", height=200,
                        )

                    try:
                        enc = encode(new_raw)
                        n = len(enc)
                        if n <= max_bytes:
                            st.success(f"✓ {n}/{max_bytes} bytes (in-place)")
                        elif ptr_loc and allow_repoint and n <= bank_free:
                            st.warning(
                                f"⚠ {n}B exceeds {max_bytes}B — will repoint "
                                f"(uses {n}B of bank free space)"
                            )
                        elif not ptr_loc:
                            st.error(
                                f"✗ {n}/{max_bytes} bytes — orphan, no pointer found, "
                                f"cannot repoint"
                            )
                        else:
                            st.error(
                                f"✗ {n}B too long; only {bank_free}B free in bank"
                            )
                    except Exception as e:
                        st.error(f"Encode error: {e}")
                        n = None

                    btn_save, btn_revert = st.columns([1, 1])
                    with btn_save:
                        if st.button(f"💾 Save", key=f"save_{loc}"):
                            if n is None:
                                st.error("Fix encode error first")
                            elif n <= max_bytes:
                                edits["text"][loc] = new_raw
                            elif ptr_loc and allow_repoint and n <= bank_free:
                                edits["text"][loc] = {
                                    "text": new_raw,
                                    "ptr_location": ptr_loc,
                                    "allow_repoint": True,
                                }
                            else:
                                st.error("Cannot save — over budget and can't repoint")
                                st.stop()
                            save_edits(edits)
                            st.success(f"Saved edit for {loc}")
                    with btn_revert:
                        if is_edited:
                            if st.button(f"↩️ Revert", key=f"revert_{loc}"):
                                del edits["text"][loc]
                                save_edits(edits)
                                st.success(f"Reverted {loc} to original")
                                st.rerun()


# ============ ROUTING TAB ============
with tab_routing:
    st.markdown("### Room Routing Editor")
    st.markdown(
        "**Entrance Editor** controls where doors/stairs take you. "
        "**Exit Editor** controls where leaving a room drops you. "
        "Set both independently for full control over map connections."
    )

    # ── Helper: destination dropdown options ──
    def _build_dest_options():
        opts = {}
        for mt in WORKING_DESTINATIONS:
            name = MAP_TYPE_NAMES.get(mt, f"Unknown 0x{mt:02X}")
            opts[mt] = f"0x{mt:02X} — {name}  ✅"
        for mt in CRASHING_DESTINATIONS:
            name = MAP_TYPE_NAMES.get(mt, f"Unknown 0x{mt:02X}")
            if mt not in opts:
                opts[mt] = f"0x{mt:02X} — {name}  ⚠️ may crash"
        for mt, name in MAP_TYPE_NAMES.items():
            if mt not in opts:
                opts[mt] = f"0x{mt:02X} — {name}  ❓ untested"
        # Add custom cross-bank rooms
        for rm in get_custom_rooms(load_edits()):
            mt = rm.get("map_type", 0x65)
            rm_name = rm.get("name", "Custom Room")
            opts[mt] = f"0x{mt:02X} — 🏠 {rm_name}  (custom)"
        return opts

    dest_options = _build_dest_options()
    sorted_dests = sorted(dest_options.keys())
    raw_bytes = edits.get("raw_bytes", {})

    # ══════════════════════════════════════════════════════════════
    # ACTIVE REDIRECTIONS — with inline editing and per-item revert
    # ══════════════════════════════════════════════════════════════

    # Collect active entry redirects (any patched byte)
    active_entries = []
    for label, addr, src_mt, dest_mt, sx, sy, data_hex in ENTRY_TRANSITIONS:
        mt_edit = raw_bytes.get(f"0x{addr:06X}")
        gf_edit = raw_bytes.get(f"0x{addr+1:06X}")
        x_edit = raw_bytes.get(f"0x{addr+3:06X}")
        y_edit = raw_bytes.get(f"0x{addr+4:06X}")
        if mt_edit is not None or gf_edit is not None or x_edit is not None or y_edit is not None:
            orig_gf = int(data_hex.split()[1], 16)
            cur_mt = int(mt_edit.strip(), 16) if mt_edit else dest_mt
            cur_gf = int(gf_edit.strip(), 16) if gf_edit else orig_gf
            cur_x = int(x_edit.strip(), 16) if x_edit else sx
            cur_y = int(y_edit.strip(), 16) if y_edit else sy
            active_entries.append({
                "label": label, "addr": addr,
                "src_mt": src_mt, "orig_mt": dest_mt,
                "orig_gf": orig_gf, "cur_gf": cur_gf,
                "orig_x": sx, "orig_y": sy,
                "cur_mt": cur_mt, "cur_x": cur_x, "cur_y": cur_y,
            })

    # Collect active exit redirects (any patched byte)
    active_exits = []
    for label, addr, src_mt, dst_mt, scr, x, y in EXIT_TRANSITIONS:
        mt_edit = raw_bytes.get(f"0x{addr:06X}")
        scr_edit = raw_bytes.get(f"0x{addr+2:06X}")
        x_edit = raw_bytes.get(f"0x{addr+3:06X}")
        y_edit = raw_bytes.get(f"0x{addr+4:06X}")
        if mt_edit is not None or scr_edit is not None or x_edit is not None or y_edit is not None:
            cur_mt = int(mt_edit.strip(), 16) if mt_edit else dst_mt
            cur_scr = int(scr_edit.strip(), 16) if scr_edit else scr
            cur_x = int(x_edit.strip(), 16) if x_edit else x
            cur_y = int(y_edit.strip(), 16) if y_edit else y
            active_exits.append({
                "label": label, "addr": addr,
                "src_mt": src_mt, "orig_mt": dst_mt,
                "orig_scr": scr, "orig_x": x, "orig_y": y,
                "cur_mt": cur_mt, "cur_scr": cur_scr, "cur_x": cur_x, "cur_y": cur_y,
            })

    if active_entries or active_exits:
        st.markdown(f"#### 📋 Active Redirections "
                    f"({len(active_entries)} entrance, {len(active_exits)} exit)")

        for i, ae in enumerate(active_entries):
            orig_dest = MAP_TYPE_NAMES.get(ae["orig_mt"], f'0x{ae["orig_mt"]:02X}')
            cur_dest = MAP_TYPE_NAMES.get(ae["cur_mt"], f'0x{ae["cur_mt"]:02X}')
            src_part = ae["label"].split(" → ")[0] if " → " in ae["label"] else ae["label"]
            dest_changed = ae["cur_mt"] != ae["orig_mt"]
            gf_changed = ae.get("cur_gf", 0) != ae.get("orig_gf", 0)
            gf_tag = " ⚡gate→room" if gf_changed else (" ⚡gate" if ae.get("orig_gf") else "")
            if dest_changed:
                st.markdown(f"🚪 **{src_part}**: ~~{orig_dest}~~ → **{cur_dest}**{gf_tag} "
                            f"(X=0x{ae['cur_x']:02X}, Y=0x{ae['cur_y']:02X})")
            else:
                st.markdown(f"🚪 **{src_part}**: {orig_dest}{gf_tag} "
                            f"(X=0x{ae['cur_x']:02X}, Y=0x{ae['cur_y']:02X})")
            ec1, ec2, ec3, ec4 = st.columns([1, 1, 1, 1])
            with ec1:
                new_x = st.number_input("X", value=ae["cur_x"], min_value=0, max_value=255, key=f"ae_x_{i}")
                st.caption(f"0x{new_x:02X}")
            with ec2:
                new_y = st.number_input("Y", value=ae["cur_y"], min_value=0, max_value=255, key=f"ae_y_{i}")
                st.caption(f"0x{new_y:02X}")
            with ec3:
                if st.button("💾 Update", key=f"ae_upd_{i}"):
                    if new_x != ae["cur_x"]:
                        edits.setdefault("raw_bytes", {})[f"0x{ae['addr']+3:06X}"] = f"{new_x:02X}"
                    if new_y != ae["cur_y"]:
                        edits.setdefault("raw_bytes", {})[f"0x{ae['addr']+4:06X}"] = f"{new_y:02X}"
                    save_edits(edits)
                    st.rerun()
            with ec4:
                if st.button("↩️ Revert", key=f"ae_rev_{i}"):
                    for off in [0, 1, 2, 3, 4]:
                        edits.get("raw_bytes", {}).pop(f"0x{ae['addr']+off:06X}", None)
                    save_edits(edits)
                    st.rerun()

        for i, ax in enumerate(active_exits):
            orig_dest = MAP_TYPE_NAMES.get(ax["orig_mt"], f'0x{ax["orig_mt"]:02X}')
            cur_dest = MAP_TYPE_NAMES.get(ax["cur_mt"], f'0x{ax["cur_mt"]:02X}')
            src_part = ax["label"].split(" → ")[0] if " → " in ax["label"] else ax["label"]
            dest_changed = ax["cur_mt"] != ax["orig_mt"]
            scr_label = SCREEN_BYTE_NAMES.get(ax["cur_scr"], f"0x{ax['cur_scr']:02X}")
            if dest_changed:
                st.markdown(f"🚶 **{src_part}** exit: ~~→ {orig_dest}~~ → **{cur_dest}** "
                            f"({scr_label}, X=0x{ax['cur_x']:02X}, Y=0x{ax['cur_y']:02X})")
            else:
                st.markdown(f"🚶 **{src_part}** exit: → {orig_dest} "
                            f"({scr_label}, X=0x{ax['cur_x']:02X}, Y=0x{ax['cur_y']:02X})")
            xc1, xc2, xc3, xc4, xc5 = st.columns([1, 1, 1, 1, 1])
            with xc1:
                new_scr = st.number_input("Scr", value=ax["cur_scr"], min_value=0, max_value=255, key=f"ax_scr_{i}")
                st.caption(f"0x{new_scr:02X} {SCREEN_BYTE_NAMES.get(new_scr, '')}")
            with xc2:
                new_x = st.number_input("X", value=ax["cur_x"], min_value=0, max_value=255, key=f"ax_x_{i}")
                st.caption(f"0x{new_x:02X}")
            with xc3:
                new_y = st.number_input("Y", value=ax["cur_y"], min_value=0, max_value=255, key=f"ax_y_{i}")
                st.caption(f"0x{new_y:02X}")
            with xc4:
                if st.button("💾 Update", key=f"ax_upd_{i}"):
                    updates = {}
                    if new_scr != ax["cur_scr"]:
                        updates[f"0x{ax['addr']+2:06X}"] = f"{new_scr:02X}"
                    if new_x != ax["cur_x"]:
                        updates[f"0x{ax['addr']+3:06X}"] = f"{new_x:02X}"
                    if new_y != ax["cur_y"]:
                        updates[f"0x{ax['addr']+4:06X}"] = f"{new_y:02X}"
                    for k, v in updates.items():
                        edits.setdefault("raw_bytes", {})[k] = v
                    save_edits(edits)
                    st.rerun()
            with xc5:
                if st.button("↩️ Revert", key=f"ax_rev_{i}"):
                    for off in [0, 2, 3, 4]:
                        edits.get("raw_bytes", {}).pop(f"0x{ax['addr']+off:06X}", None)
                    save_edits(edits)
                    st.rerun()
            # GreatTree preset picker for active exit edits
            if ax["cur_mt"] == 0x01:
                preset_labels = ["(keep current)"] + [p[0] for p in GREATTREE_LANDING_PRESETS]
                preset_pick = st.selectbox(
                    "Quick-fill GreatTree landing spot",
                    range(len(preset_labels)),
                    format_func=lambda j: preset_labels[j],
                    key=f"ax_preset_{i}",
                )
                if preset_pick > 0:
                    p = GREATTREE_LANDING_PRESETS[preset_pick - 1]
                    if st.button(f"Apply: {p[0]} (scr=0x{p[1]:02X}, X={p[2]}, Y={p[3]})",
                                 key=f"ax_preset_apply_{i}"):
                        edits.setdefault("raw_bytes", {})[f"0x{ax['addr']+2:06X}"] = f"{p[1]:02X}"
                        edits.setdefault("raw_bytes", {})[f"0x{ax['addr']+3:06X}"] = f"{p[2]:02X}"
                        edits.setdefault("raw_bytes", {})[f"0x{ax['addr']+4:06X}"] = f"{p[3]:02X}"
                        save_edits(edits)
                        st.rerun()

        st.divider()
    else:
        st.caption("No active redirections yet.")
        st.divider()

    # ══════════════════════════════════════════════════════════════
    # ENTRANCE EDITOR
    # ══════════════════════════════════════════════════════════════
    st.markdown("#### 🚪 Entrance Editor")
    st.caption("Where does this door/staircase take you?")

    entry_labels = [f"{label}  [0x{addr:06X}]" for label, addr, *_ in ENTRY_TRANSITIONS]
    selected_entry_idx = st.selectbox(
        "Source transition", range(len(entry_labels)),
        format_func=lambda i: entry_labels[i],
        key="routing_entry_select",
    )
    sel = ENTRY_TRANSITIONS[selected_entry_idx]
    sel_label, sel_addr, sel_src_mt, sel_dest_mt, sel_sx, sel_sy, sel_data = sel

    # Parse gate flag from original data (byte 1)
    sel_gate_flag = int(sel_data.split()[1], 16)
    gate_flag_edit = raw_bytes.get(f"0x{sel_addr+1:06X}")
    cur_gate_flag = int(gate_flag_edit.strip(), 16) if gate_flag_edit else sel_gate_flag

    # Parse screen byte from original data (byte 2)
    sel_screen = int(sel_data.split()[2], 16)
    screen_edit = raw_bytes.get(f"0x{sel_addr+2:06X}")
    cur_screen = int(screen_edit.strip(), 16) if screen_edit else sel_screen

    current_edit = raw_bytes.get(f"0x{sel_addr:06X}")
    current_mt = int(current_edit.strip(), 16) if current_edit else sel_dest_mt
    orig_name = MAP_TYPE_NAMES.get(sel_dest_mt, f"0x{sel_dest_mt:02X}")
    src_name = MAP_TYPE_NAMES.get(sel_src_mt, f"0x{sel_src_mt:02X}")

    col_info, col_edit = st.columns([1, 2])
    with col_info:
        st.markdown(f"**Source room:** {src_name}")
        st.markdown(f"**Original destination:** {orig_name}")
        st.markdown(f"**Original spawn:** X=0x{sel_sx:02X}, Y=0x{sel_sy:02X}")
        if sel_gate_flag == 0x01:
            st.markdown("**Gate flag:** `0x01` ⚡ *this is a gate entry*")
        if current_mt != sel_dest_mt:
            cur_name = MAP_TYPE_NAMES.get(current_mt, f"0x{current_mt:02X}")
            st.warning(f"Currently redirected to: **{cur_name}**")

    with col_edit:
        default_idx = sorted_dests.index(current_mt) if current_mt in sorted_dests else 0
        new_mt = st.selectbox(
            "New destination", sorted_dests, index=default_idx,
            format_func=lambda mt: dest_options[mt], key=f"routing_dest_{sel_addr}",
        )
        dest_default_x, dest_default_y = sel_sx, sel_sy
        for _, d_addr, _, d_mt, d_x, d_y, _ in ENTRY_TRANSITIONS:
            if d_mt == new_mt and d_addr != sel_addr:
                dest_default_x, dest_default_y = d_x, d_y
                break
        cur_sx_edit = raw_bytes.get(f"0x{sel_addr+3:06X}")
        cur_sy_edit = raw_bytes.get(f"0x{sel_addr+4:06X}")
        sx_cur = int(cur_sx_edit.strip(), 16) if cur_sx_edit else dest_default_x
        sy_cur = int(cur_sy_edit.strip(), 16) if cur_sy_edit else dest_default_y
        sc1, sc2, sc3 = st.columns([1, 1, 1])
        with sc1:
            # Screen byte — auto-set to 0x00 for safe compatibility
            default_screen = 0x00 if new_mt != sel_dest_mt else sel_screen
            new_screen = st.number_input("Screen", min_value=0, max_value=255,
                value=int(screen_edit.strip(), 16) if screen_edit else default_screen,
                key=f"routing_scr_{sel_addr}_{new_mt}",
                help="Screen index for multi-screen rooms. 0x00 = safe for all rooms. "
                     "Higher values crash on single-screen destinations.")
            st.caption(f"= 0x{new_screen:02X}")
        with sc2:
            new_sx = st.number_input("Spawn X", min_value=0, max_value=255,
                value=sx_cur if new_mt != sel_dest_mt else dest_default_x,
                key=f"routing_sx_{sel_addr}_{new_mt}")
            st.caption(f"= 0x{new_sx:02X}")
        with sc3:
            new_sy = st.number_input("Spawn Y", min_value=0, max_value=255,
                value=sy_cur if new_mt != sel_dest_mt else dest_default_y,
                key=f"routing_sy_{sel_addr}_{new_mt}")
            st.caption(f"= 0x{new_sy:02X}")

        # Gate flag handling
        new_gate_flag = sel_gate_flag
        if sel_gate_flag == 0x01:
            clear_gate = st.checkbox(
                "Clear gate flag (byte 1: 0x01 → 0x00) — required to redirect to a normal room",
                value=True, key="routing_clear_gate",
            )
            new_gate_flag = 0x00 if clear_gate else 0x01
        if new_mt != sel_dest_mt:
            st.caption("⚠️ Spawn coords are vanilla defaults for this destination. "
                       "Multi-screen rooms (Library, GreatTree) may need different values — "
                       "test in-game and tweak via the Active Redirections list above.")

    if new_mt != sel_dest_mt or new_sx != sel_sx or new_sy != sel_sy or new_gate_flag != sel_gate_flag or new_screen != sel_screen:
        changes = {}
        new_name = MAP_TYPE_NAMES.get(new_mt, f"0x{new_mt:02X}")
        if new_mt != sel_dest_mt:
            changes[f"0x{sel_addr:06X}"] = f"{new_mt:02X}"
        if new_gate_flag != sel_gate_flag:
            changes[f"0x{sel_addr+1:06X}"] = f"{new_gate_flag:02X}"
        if new_screen != sel_screen:
            changes[f"0x{sel_addr+2:06X}"] = f"{new_screen:02X}"
        if new_sx != sel_sx:
            changes[f"0x{sel_addr+3:06X}"] = f"{new_sx:02X}"
        if new_sy != sel_sy:
            changes[f"0x{sel_addr+4:06X}"] = f"{new_sy:02X}"
        st.caption(f"Will write {len(changes)} byte(s): {orig_name} → {new_name} "
                   f"screen=0x{new_screen:02X}, X=0x{new_sx:02X}, Y=0x{new_sy:02X}"
                   f"{' (gate flag cleared)' if new_gate_flag != sel_gate_flag else ''}")
        bc1, bc2 = st.columns(2)
        with bc1:
            if st.button("✅ Apply entrance change", key="routing_apply"):
                for k, v in changes.items():
                    edits.setdefault("raw_bytes", {})[k] = v
                save_edits(edits)
                st.success(f"Applied — now leads to {new_name}")
                st.rerun()
        with bc2:
            has_existing = any(f"0x{sel_addr+off:06X}" in raw_bytes for off in [0, 1, 2, 3, 4])
            if st.button("↩️ Revert this entrance", key="routing_revert_one", disabled=not has_existing):
                for off in [0, 1, 2, 3, 4]:
                    edits.get("raw_bytes", {}).pop(f"0x{sel_addr+off:06X}", None)
                save_edits(edits)
                st.rerun()
    else:
        st.caption("Select a different destination to preview changes.")

    # ══════════════════════════════════════════════════════════════
    st.divider()
    # EXIT EDITOR
    # ══════════════════════════════════════════════════════════════
    st.markdown("#### 🚶 Exit Editor")
    st.caption("Where does leaving this room drop you?")

    exit_labels = [f"{label}  [0x{addr:06X}]" for label, addr, *_ in EXIT_TRANSITIONS]
    sel_exit_idx = st.selectbox(
        "Exit transition", range(len(exit_labels)),
        format_func=lambda i: exit_labels[i],
        key="routing_exit_select",
    )
    ex = EXIT_TRANSITIONS[sel_exit_idx]
    ex_label, ex_addr, ex_src_mt, ex_dst_mt, ex_scr, ex_x, ex_y = ex
    ex_src_name = MAP_TYPE_NAMES.get(ex_src_mt, f"0x{ex_src_mt:02X}")
    ex_dst_name = MAP_TYPE_NAMES.get(ex_dst_mt, f"0x{ex_dst_mt:02X}")

    ex_col_info, ex_col_edit = st.columns([1, 2])
    with ex_col_info:
        st.markdown(f"**Leaving room:** {ex_src_name}")
        st.markdown(f"**Original destination:** {ex_dst_name}")
        st.markdown(f"**Original:** screen=0x{ex_scr:02X} "
                    f"({SCREEN_BYTE_NAMES.get(ex_scr, '?')}), X={ex_x}, Y={ex_y}")
        ex_mt_edit = raw_bytes.get(f"0x{ex_addr:06X}")
        ex_cur_mt = int(ex_mt_edit.strip(), 16) if ex_mt_edit else ex_dst_mt
        if ex_cur_mt != ex_dst_mt:
            st.warning(f"Currently redirected to: **{MAP_TYPE_NAMES.get(ex_cur_mt, f'0x{ex_cur_mt:02X}')}**")

    with ex_col_edit:
        ex_default_idx = sorted_dests.index(ex_cur_mt) if ex_cur_mt in sorted_dests else 0
        ex_new_mt = st.selectbox(
            "Exit destination", sorted_dests, index=ex_default_idx,
            format_func=lambda mt: dest_options[mt], key=f"exit_dest_{ex_addr}",
        )
        # Read current edits for screen/x/y
        ex_scr_edit = raw_bytes.get(f"0x{ex_addr+2:06X}")
        ex_x_edit = raw_bytes.get(f"0x{ex_addr+3:06X}")
        ex_y_edit = raw_bytes.get(f"0x{ex_addr+4:06X}")
        ex_cur_scr = int(ex_scr_edit.strip(), 16) if ex_scr_edit else ex_scr
        ex_cur_x = int(ex_x_edit.strip(), 16) if ex_x_edit else ex_x
        ex_cur_y = int(ex_y_edit.strip(), 16) if ex_y_edit else ex_y

        # GreatTree preset picker — applies directly to avoid Streamlit widget state issues
        if ex_new_mt == 0x01:
            preset_labels = ["(manual entry)"] + [
                f"{p[0]}  scr=0x{p[1]:02X} X={p[2]} Y={p[3]}" for p in GREATTREE_LANDING_PRESETS
            ]
            preset_pick = st.selectbox(
                "🌳 GreatTree landing spot",
                range(len(preset_labels)),
                format_func=lambda j: preset_labels[j],
                key=f"exit_gt_preset_{ex_addr}",
            )
            if preset_pick > 0:
                p = GREATTREE_LANDING_PRESETS[preset_pick - 1]
                if st.button(f"⚡ Apply preset: {p[0]}", key="exit_gt_preset_apply"):
                    edits.setdefault("raw_bytes", {})[f"0x{ex_addr+2:06X}"] = f"{p[1]:02X}"
                    edits.setdefault("raw_bytes", {})[f"0x{ex_addr+3:06X}"] = f"{p[2]:02X}"
                    edits.setdefault("raw_bytes", {})[f"0x{ex_addr+4:06X}"] = f"{p[3]:02X}"
                    save_edits(edits)
                    st.success(f"Applied preset — exit now lands at {p[0]}")
                    st.rerun()

        ec1, ec2, ec3 = st.columns(3)

        # When destination changes to non-GreatTree, auto-populate from DEST_SPAWN_DEFAULTS
        if ex_new_mt != ex_dst_mt and ex_new_mt != 0x01:
            defaults = DEST_SPAWN_DEFAULTS.get(ex_new_mt, (0x00, 0x01, 0x01))
            default_scr, default_x, default_y = defaults
            # Use defaults unless already edited
            display_scr = int(ex_scr_edit.strip(), 16) if ex_scr_edit else default_scr
            display_x = int(ex_x_edit.strip(), 16) if ex_x_edit else default_x
            display_y = int(ex_y_edit.strip(), 16) if ex_y_edit else default_y
            st.info(f"💡 Auto-populated from {MAP_TYPE_NAMES.get(ex_new_mt, '?')}'s entry data: "
                    f"screen=0x{default_scr:02X}, X={default_x}, Y={default_y}")
        else:
            display_scr = ex_cur_scr
            display_x = ex_cur_x
            display_y = ex_cur_y

        with ec1:
            ex_new_scr = st.number_input("Screen byte", min_value=0, max_value=255,
                value=display_scr, key=f"exit_scr_{ex_addr}_{ex_new_mt}",
                help="Auto-populated from destination's entry data. "
                     "GreatTree: use presets above. Other rooms: use entry values.")
            scr_name = SCREEN_BYTE_NAMES.get(ex_new_scr, "unknown")
            st.caption(f"= 0x{ex_new_scr:02X} ({scr_name})")
        with ec2:
            ex_new_x = st.number_input("Arrival X", min_value=0, max_value=255,
                value=display_x, key=f"exit_x_{ex_addr}_{ex_new_mt}")
            st.caption(f"= 0x{ex_new_x:02X}")
        with ec3:
            ex_new_y = st.number_input("Arrival Y", min_value=0, max_value=255,
                value=display_y, key=f"exit_y_{ex_addr}_{ex_new_mt}")
            st.caption(f"= 0x{ex_new_y:02X}")

    # Exit preview + apply
    ex_changes = {}
    if ex_new_mt != ex_dst_mt:
        ex_changes[f"0x{ex_addr:06X}"] = f"{ex_new_mt:02X}"
    if ex_new_scr != ex_scr:
        ex_changes[f"0x{ex_addr+2:06X}"] = f"{ex_new_scr:02X}"
    if ex_new_x != ex_x:
        ex_changes[f"0x{ex_addr+3:06X}"] = f"{ex_new_x:02X}"
    if ex_new_y != ex_y:
        ex_changes[f"0x{ex_addr+4:06X}"] = f"{ex_new_y:02X}"

    if ex_changes:
        new_dst_name = MAP_TYPE_NAMES.get(ex_new_mt, f"0x{ex_new_mt:02X}")
        st.caption(f"Will write {len(ex_changes)} byte(s): exit → {new_dst_name} "
                   f"screen=0x{ex_new_scr:02X} at X=0x{ex_new_x:02X} ({ex_new_x}), "
                   f"Y=0x{ex_new_y:02X} ({ex_new_y})")
        ebc1, ebc2 = st.columns(2)
        with ebc1:
            if st.button("✅ Apply exit change", key="exit_apply"):
                for k, v in ex_changes.items():
                    edits.setdefault("raw_bytes", {})[k] = v
                save_edits(edits)
                st.success(f"Applied — leaving {ex_src_name} now goes to {new_dst_name}")
                st.rerun()
        with ebc2:
            ex_has_edits = any(f"0x{ex_addr+off:06X}" in raw_bytes for off in [0, 2, 3, 4])
            if st.button("↩️ Revert this exit", key="exit_revert", disabled=not ex_has_edits):
                for off in [0, 2, 3, 4]:
                    edits.get("raw_bytes", {}).pop(f"0x{ex_addr+off:06X}", None)
                save_edits(edits)
                st.rerun()
    else:
        st.caption("Change destination or coordinates to preview changes.")

    # ── Reference tables ──
    with st.expander("📖 Reference: All Entry Transitions"):
        for label, addr, src_mt, mt, sx, sy, data in ENTRY_TRANSITIONS:
            edited = any(f"0x{addr+off:06X}" in raw_bytes for off in [0, 1, 2, 3, 4])
            tag = " ✏️" if edited else ""
            st.text(f"0x{addr:06X}  {MAP_TYPE_NAMES.get(mt, f'0x{mt:02X}'):20s}  {label}{tag}")

    with st.expander("📖 Reference: All Exit Transitions"):
        for label, addr, src_mt, dst_mt, scr, x, y in EXIT_TRANSITIONS:
            edited = any(f"0x{addr+off:06X}" in raw_bytes for off in [0, 2, 3, 4])
            tag = " ✏️" if edited else ""
            dst_name = MAP_TYPE_NAMES.get(dst_mt, f'0x{dst_mt:02X}')
            st.text(f"0x{addr:06X}  scr=0x{scr:02X} X={x} Y={y}  → {dst_name:20s}  {label}{tag}")

    with st.expander("🌳 Reference: GreatTree Landing Coordinates"):
        st.markdown("Known landing spots on GreatTree from vanilla exit data:")
        for plabel, pscr, px, py in GREATTREE_LANDING_PRESETS:
            st.text(f"  screen=0x{pscr:02X}  X={px}  Y={py}  —  {plabel}")

# ============ NPC TAB ============
with tab_npcs:
    st.markdown("### NPC Editor")

    # Load NPC catalog and names
    npc_catalog_path = Path("extracted/npc_catalog.json")
    npc_names_path = Path("npc_names.json")

    if not npc_catalog_path.exists():
        st.error("Run `uv run python -m tools.dump_all_npcs` first to generate extracted/npc_catalog.json")
    else:
        catalog = json.loads(npc_catalog_path.read_text())
        names = {}
        if npc_names_path.exists():
            names = json.loads(npc_names_path.read_text())

        sprite_names = names.get("sprite_names", {})
        type_names = names.get("type_names", {})
        npc_labels = names.get("npc_labels", {})
        room_overrides = names.get("room_names_override", {})

        def sprite_label(sid):
            key = f"0x{sid:02X}"
            name = sprite_names.get(key, "")
            return f"0x{sid:02X} {name}".strip() if name else f"0x{sid:02X}"

        def type_label(t):
            key = f"0x{t:02X}"
            name = type_names.get(key, "")
            # Also check high nibble
            if not name:
                hi_key = f"0x{t & 0xF0:02X}"
                name = type_names.get(hi_key, "")
            return f"0x{t:02X} {name}".strip() if name else f"0x{t:02X}"

        # Group catalog by room then by unique interact_ptr (= unique game state)
        rooms = {}
        for npc in catalog:
            mt = npc["map_type"]
            rm = room_overrides.get(f"0x{mt:02X}", npc.get("room", f"Map_{mt:02X}"))
            rooms.setdefault(mt, {"name": rm, "variants": {}})
            rooms[mt]["name"] = rm
            iptr = npc.get("interact_ptr", npc["flat"])  # unique per game state
            rooms[mt]["variants"].setdefault(iptr, {"step_id": npc["step_id"], "npcs": []})
            rooms[mt]["variants"][iptr]["npcs"].append(npc)

        sorted_rooms = sorted(rooms.keys())
        room_labels = [f"0x{mt:02X} — {rooms[mt]['name']} "
                       f"({len(rooms[mt]['variants'])} states, "
                       f"{sum(len(v['npcs']) for v in rooms[mt]['variants'].values())} entries)"
                       for mt in sorted_rooms]

        sel_room_idx = st.selectbox(
            "Room", range(len(sorted_rooms)),
            format_func=lambda i: room_labels[i],
            key="npc_room_select",
        )
        sel_mt = sorted_rooms[sel_room_idx]
        sel_room = rooms[sel_mt]

        # Variant selector (each interact_ptr = one game state)
        variant_keys = sorted(sel_room["variants"].keys())
        variant_labels = []
        for vi, vk in enumerate(variant_keys):
            v = sel_room["variants"][vk]
            npc_summary = ", ".join(sprite_label(n["sprite"]) for n in v["npcs"])
            variant_labels.append(
                f"Variant {vi+1} (step 0x{v['step_id']:02X}, "
                f"{len(v['npcs'])} NPCs: {npc_summary[:60]})"
            )

        if len(variant_keys) > 1:
            # Show cross-state summary first
            with st.expander(f"🔄 Same NPC across {len(variant_keys)} game states"):
                # Match NPCs across variants by sprite+script
                npc_tracker = {}
                for vi, vk in enumerate(variant_keys):
                    for n in sel_room["variants"][vk]["npcs"]:
                        key = (n["sprite"], n["script"])
                        npc_tracker.setdefault(key, []).append({
                            "variant": vi+1, "x": n["x"], "y": n["y"],
                            "type": n["npc_type"], "flat": n["flat"],
                        })
                for (spr, scr), appearances in sorted(npc_tracker.items()):
                    positions = [f"V{a['variant']}:({a['x']},{a['y']})" for a in appearances]
                    all_same_pos = len(set((a["x"], a["y"]) for a in appearances)) == 1
                    pos_tag = " ✓same pos" if all_same_pos else " ⚡moves"
                    st.text(f"  {sprite_label(spr):20s} script=0x{scr:02X}  "
                            f"in {len(appearances)}/{len(variant_keys)} states{pos_tag}  "
                            f"{' '.join(positions[:8])}")

            sel_var_idx = st.selectbox(
                "Game state variant", range(len(variant_keys)),
                format_func=lambda i: variant_labels[i],
                key="npc_var_select",
            )
        else:
            sel_var_idx = 0

        sel_vk = variant_keys[sel_var_idx]
        sel_variant = sel_room["variants"][sel_vk]
        npcs = sel_variant["npcs"]

        st.caption(f"step_id=0x{sel_variant['step_id']:02X}, "
                   f"interact_ptr=0x{sel_vk:04X} — "
                   f"{len(npcs)} NPC(s) in this variant")

        st.divider()
        raw_bytes = edits.get("raw_bytes", {})

        # Display and edit each NPC
        for i, npc in enumerate(npcs):
            flat_addr = npc["flat"]
            addr_key = f"0x{flat_addr:06X}"
            custom_label = npc_labels.get(addr_key, "")

            # Check for existing edits
            spr_edit = raw_bytes.get(f"0x{flat_addr+1:06X}")
            x_edit = raw_bytes.get(f"0x{flat_addr+2:06X}")
            y_edit = raw_bytes.get(f"0x{flat_addr+3:06X}")
            type_edit = raw_bytes.get(f"0x{flat_addr:06X}")

            cur_spr = int(spr_edit.strip(), 16) if spr_edit else npc["sprite"]
            cur_x = int(x_edit.strip(), 16) if x_edit else npc["x"]
            cur_y = int(y_edit.strip(), 16) if y_edit else npc["y"]
            cur_type = int(type_edit.strip(), 16) if type_edit else npc["npc_type"]

            # Header
            spr_name = sprite_label(cur_spr)
            t_name = type_label(cur_type)
            edited_tag = ""
            if spr_edit or x_edit or y_edit or type_edit:
                edited_tag = " ✏️"

            label_display = f"**{custom_label}**" if custom_label else spr_name
            st.markdown(f"**NPC {i+1}**: {label_display} — {t_name} at ({cur_x},{cur_y}) "
                        f"script=0x{npc['script']:02X}{edited_tag}  "
                        f"`{addr_key}`")

            c1, c2, c3, c4, c5 = st.columns([2, 1, 1, 1, 1])
            with c1:
                new_spr = st.number_input("Sprite", value=cur_spr, min_value=0, max_value=255,
                                          key=f"npc_spr_{flat_addr}")
                st.caption(sprite_label(new_spr))
            with c2:
                new_x = st.number_input("X", value=cur_x, min_value=0, max_value=255,
                                        key=f"npc_x_{flat_addr}")
            with c3:
                new_y = st.number_input("Y", value=cur_y, min_value=0, max_value=255,
                                        key=f"npc_y_{flat_addr}")
            with c4:
                new_type = st.number_input("Type", value=cur_type, min_value=0, max_value=255,
                                           key=f"npc_type_{flat_addr}")
                st.caption(type_label(new_type))
            with c5:
                # Apply changes: write new values OR delete edits that match original
                has_existing = any(f"0x{flat_addr+off:06X}" in raw_bytes for off in [0, 1, 2, 3])
                values_changed = (new_type != npc["npc_type"] or new_spr != npc["sprite"]
                                  or new_x != npc["x"] or new_y != npc["y"])
                needs_save = values_changed or has_existing

                if st.button("💾", key=f"npc_apply_{flat_addr}", disabled=not needs_save):
                    rb = edits.setdefault("raw_bytes", {})
                    # For each field: write if changed, delete if reverted to original
                    for off, new_val, orig_val in [
                        (0, new_type, npc["npc_type"]),
                        (1, new_spr, npc["sprite"]),
                        (2, new_x, npc["x"]),
                        (3, new_y, npc["y"]),
                    ]:
                        key = f"0x{flat_addr+off:06X}"
                        if new_val != orig_val:
                            rb[key] = f"{new_val:02X}"
                        else:
                            rb.pop(key, None)  # remove stale edit
                    save_edits(edits)
                    st.rerun()

                if st.button("↩️", key=f"npc_rev_{flat_addr}", disabled=not has_existing):
                    for off in [0, 1, 2, 3]:
                        edits.get("raw_bytes", {}).pop(f"0x{flat_addr+off:06X}", None)
                    save_edits(edits)
                    st.rerun()

        # Naming section
        st.divider()
        with st.expander("🏷️ Name Sprites & NPCs"):
            st.markdown("Names persist in `npc_names.json` across editor sessions.")

            st.markdown("**Rename a sprite** (from current room):")
            # Build sprite options from currently displayed NPCs
            room_sprites = sorted(set(n["sprite"] for n in npcs))
            all_sprites = sorted(set(n["sprite"] for n in catalog))
            spr_options = room_sprites + [s for s in all_sprites if s not in room_sprites]
            spr_labels = [f"{'→ ' if s in room_sprites else ''}"
                          f"0x{s:02X} ({sprite_label(s)})" for s in spr_options]

            rc1, rc2, rc3 = st.columns([2, 2, 1])
            with rc1:
                rename_spr_idx = st.selectbox("Sprite", range(len(spr_options)),
                    format_func=lambda i: spr_labels[i], key="npc_rename_spr_sel")
                rename_spr = spr_options[rename_spr_idx]
            with rc2:
                cur_name = sprite_names.get(f"0x{rename_spr:02X}", "")
                new_name = st.text_input("Name", value=cur_name,
                    key=f"npc_rename_name_{rename_spr}")
            with rc3:
                if st.button("Save name", key="npc_rename_save"):
                    names.setdefault("sprite_names", {})[f"0x{rename_spr:02X}"] = new_name
                    npc_names_path.write_text(json.dumps(names, indent=2))
                    st.success(f"Sprite 0x{rename_spr:02X} → {new_name}")
                    st.rerun()

            st.markdown("**Label an NPC** (from current variant):")
            npc_options = [(n, f"0x{n['flat']:06X}") for n in npcs]
            npc_labels_list = [f"NPC {i+1}: {sprite_label(n['sprite'])} at ({n['x']},{n['y']}) "
                               f"script=0x{n['script']:02X}  [{addr}]"
                               for i, (n, addr) in enumerate(npc_options)]

            if npc_options:
                lc1, lc2, lc3 = st.columns([2, 2, 1])
                with lc1:
                    label_npc_idx = st.selectbox("NPC", range(len(npc_options)),
                        format_func=lambda i: npc_labels_list[i], key="npc_label_sel")
                    label_addr = npc_options[label_npc_idx][1]
                with lc2:
                    cur_label = npc_labels.get(label_addr, "")
                    new_label = st.text_input("Label", value=cur_label,
                        key=f"npc_label_text_{label_addr}")
                with lc3:
                    if st.button("Save label", key="npc_label_save"):
                        names.setdefault("npc_labels", {})[label_addr] = new_label
                        npc_names_path.write_text(json.dumps(names, indent=2))
                        st.success(f"{label_addr} → {new_label}")
                        st.rerun()

            st.markdown("**Override room name:**")
            oc1, oc2, oc3 = st.columns([2, 2, 1])
            with oc1:
                cur_room_name = room_overrides.get(f"0x{sel_mt:02X}", sel_room["name"])
                st.caption(f"Current: 0x{sel_mt:02X} = {cur_room_name}")
            with oc2:
                new_override = st.text_input("New name", value=cur_room_name,
                    key=f"npc_room_name_{sel_mt}")
            with oc3:
                if st.button("Save room name", key="npc_room_save"):
                    names.setdefault("room_names_override", {})[f"0x{sel_mt:02X}"] = new_override
                    npc_names_path.write_text(json.dumps(names, indent=2))
                    st.success(f"0x{sel_mt:02X} → {new_override}")
                    st.rerun()

        # Sprite reference
        with st.expander("📖 Sprite Reference"):
            for sid in sorted(set(n["sprite"] for n in catalog)):
                sname = sprite_label(sid)
                usage_rooms = sorted(set(
                    room_overrides.get(f"0x{n['map_type']:02X}", n.get("room", "?"))
                    for n in catalog if n["sprite"] == sid
                ))
                count = sum(1 for n in catalog if n["sprite"] == sid)
                st.text(f"  {sname:30s}  {count:3d} uses  in: {', '.join(usage_rooms[:6])}")

# ============ CUSTOM ROOMS TAB ============
with tab_rooms:
    st.markdown("### 🏠 Custom Room Builder")
    st.caption("Create new rooms stored in bank 0x68, loaded via WRAM at runtime.")

    edits = load_edits()

    # Check for stale/dangerous legacy patches
    raw = edits.get("raw_bytes", {})
    stale_patches = [addr for addr in ["0x003A83", "0x02C609", "0x02C253", "0x02C287", "0x02C4B6", "0x02C542"]
                      if addr in raw and addr not in crossbank_infrastructure_patches()]
    if stale_patches:
        st.error(f"⚠️ Found {len(stale_patches)} dangerous legacy patch(es) in edits.json "
                 f"({', '.join(stale_patches)}). These overwrite active game data in bank 0x00 "
                 f"and cause crashes. Click below to remove them.")
        if st.button("🗑️ Remove dangerous patches"):
            for addr in stale_patches:
                raw.pop(addr, None)
            save_edits(edits)
            st.rerun()

    # Infrastructure toggle
    infra_enabled = is_crossbank_enabled(edits)
    infra_patches = crossbank_infrastructure_patches()
    active_count = sum(1 for addr in infra_patches if raw.get(addr) == infra_patches[addr])

    col_infra1, col_infra2 = st.columns([3, 1])
    with col_infra1:
        if infra_enabled:
            st.markdown(f"**Cross-bank infrastructure:** ✅ Enabled ({active_count} patches in bank 0x0B)")
            st.caption("Patches: loader redirect ($4287→$77A9) + trampoline + copy routine ($3FE8). "
                       "Normal rooms work unchanged.")
        else:
            st.markdown("**Cross-bank infrastructure:** ❌ Disabled")
            st.caption("2 safe patches (55 bytes total, bank 0x0B only)")
    with col_infra2:
        if not infra_enabled:
            if st.button("Enable Infrastructure"):
                enable_crossbank(edits)
                save_edits(edits)
                st.rerun()
        else:
            if st.button("Disable Infrastructure"):
                disable_crossbank(edits)
                save_edits(edits)
                st.rerun()

    if not infra_enabled:
        st.info("Enable cross-bank infrastructure above to start creating custom rooms.")
    else:
        st.success("✅ Cross-bank infrastructure active. Custom rooms ready to test. "
                    "Create a room below, save it, then route to it from the Routing tab.")
        st.markdown("---")
        rooms = get_custom_rooms(edits)

        # Room list with per-room delete
        st.markdown(f"**Custom Rooms ({len(rooms)}/{len(CROSSBANK_SLOTS)})**")

        if rooms:
            for i, rm in enumerate(rooms):
                mt = rm.get("map_type", CROSSBANK_SLOTS[i] if i < len(CROSSBANK_SLOTS) else 0x65+i)
                tileset_name = TILESET_NAMES.get(rm.get("tileset", 0x26), f"0x{rm.get('tileset', 0x26):02X}")
                n_npcs = len(rm.get("npcs_step0", []))
                n_exits = len(rm.get("exits_step0", []))
                rm_name = rm.get("name", f"Room {i+1}")
                c_info, c_del = st.columns([5, 1])
                with c_info:
                    st.text(f"  [{i}] mt=0x{mt:02X}  \"{rm_name}\"  tileset={tileset_name}  "
                            f"NPCs={n_npcs}  exits={n_exits}")
                with c_del:
                    if st.button("🗑️", key=f"rm_list_del_{i}", help=f"Delete {rm_name}"):
                        rooms.pop(i)
                        raw_ed = edits.get("raw_bytes", {})
                        bank_flat = CROSSBANK_ROOM_BANK * 0x4000
                        raw_ed.pop(f"0x{bank_flat + i * 128:06X}", None)
                        ptr_addr = f"0x{CROSSBANK_PTR_TABLE + mt * 2:06X}"
                        raw_ed.pop(ptr_addr, None)
                        save_edits(edits)
                        st.rerun()
            if len(rooms) > 1:
                if st.button("🗑️ Delete All Rooms"):
                    edits["custom_rooms"] = []
                    raw_ed = edits.get("raw_bytes", {})
                    bank_flat = CROSSBANK_ROOM_BANK * 0x4000
                    to_rm = [k for k in raw_ed
                             if any(k == f"0x{bank_flat + j*128:06X}" for j in range(20))
                             or any(k == f"0x{CROSSBANK_PTR_TABLE + mt*2:06X}" for mt in CROSSBANK_SLOTS)]
                    for k in to_rm:
                        raw_ed.pop(k, None)
                    save_edits(edits)
                    st.rerun()
        else:
            st.caption("No custom rooms defined yet.")

        st.markdown("---")

        # Room editor
        st.markdown("#### Edit Room")
        room_idx = st.selectbox("Room to edit",
            list(range(len(rooms))) + (["(new)"] if len(rooms) < len(CROSSBANK_SLOTS) else []),
            format_func=lambda x: f"Room {x}: {rooms[x].get('name', 'Unnamed')}" if isinstance(x, int) and x < len(rooms) else "➕ Create New Room",
            key="room_sel")

        is_new = room_idx == "(new)"
        if is_new:
            room_idx = len(rooms)
            current = {}
        else:
            current = rooms[room_idx] if room_idx < len(rooms) else {}

        col1, col2, col3 = st.columns(3)
        with col1:
            room_name = st.text_input("Room name", value=current.get("name", f"Custom Room {room_idx+1}"), key="rm_name")
        with col2:
            mt_options = CROSSBANK_SLOTS[:len(CROSSBANK_SLOTS)]
            used_mts = {rm.get("map_type") for i, rm in enumerate(rooms) if i != room_idx}
            available_mts = [mt for mt in mt_options if mt not in used_mts]
            default_mt = current.get("map_type", available_mts[0] if available_mts else 0x65)
            map_type = st.selectbox("Map type slot", available_mts,
                format_func=lambda mt: f"0x{mt:02X} ({MAP_TYPE_NAMES.get(mt, 'alias')})",
                index=available_mts.index(default_mt) if default_mt in available_mts else 0,
                key="rm_mt")
        with col3:
            tileset = st.selectbox("Tileset", list(TILESET_NAMES.keys()),
                format_func=lambda t: f"0x{t:02X} {TILESET_NAMES[t]}",
                index=list(TILESET_NAMES.keys()).index(current.get("tileset", 0x26))
                    if current.get("tileset", 0x26) in TILESET_NAMES else 0,
                key="rm_tileset")

        # NPC editor (Step 0 — main state)
        st.markdown("##### NPCs (Step 0 — primary state)")

        # Built-in reference data for NPC types and common sprites
        NPC_TYPE_OPTIONS = [
            (0x00, "Stationary (talkable)"), (0x01, "Stationary (auto)"),
            (0x02, "Hidden marker"), (0x03, "Stationary (special)"),
            (0x06, "Shopkeeper"), (0x07, "Priest/healer"),
            (0x08, "Inn/rest"), (0x10, "Wander"),
            (0x17, "Wander + special"), (0x20, "Face down"),
            (0x22, "Face down (special)"), (0x26, "Face down + shop"),
            (0x27, "Face down + special"), (0x30, "Face left"),
            (0x32, "Face left (special)"), (0x33, "Face left (guard)"),
            (0x36, "Face left + shop"), (0x37, "Face left + wander"),
            (0x40, "Invisible/overlay"), (0x50, "System (portal)"),
            (0x60, "Background object"), (0x70, "Trigger/loader"),
        ]
        SPRITE_OPTIONS = [
            (0x00, "Hero (alt)"), (0x01, "Woman (red)"), (0x02, "Scholar"),
            (0x03, "Sage"), (0x04, "Merchant"), (0x05, "Girl/Milayou"),
            (0x06, "Shopkeeper"), (0x07, "Innkeeper"), (0x08, "Terry (hero)"),
            (0x09, "Old woman"), (0x0A, "Knight"), (0x0B, "Guard/soldier"),
            (0x0C, "Kid"), (0x0D, "Cat"), (0x0E, "Queen/noble"),
            (0x0F, "Old man/Pulio"), (0x10, "Jester"), (0x11, "King"),
            (0x12, "Monster tamer"), (0x13, "MedalMan"), (0x14, "Warubou"),
            (0x15, "Dark smoke"), (0x16, "Slime (NPC)"), (0x17, "Dracky"),
            (0x18, "Dragon (big)"), (0x19, "Farm animal"), (0x1A, "Monster (misc)"),
            (0x1B, "Monster (large)"), (0x1C, "Trainer"), (0x1D, "Monster (big)"),
            (0x1E, "Gigantes"), (0x1F, "Fighter"), (0x20, "Monster (walk)"),
            (0x21, "Gate portal"), (0x22, "KingSlime"), (0x24, "KingSlime (alt)"),
            (0x25, "FaceTree"), (0x26, "Shrine priest"), (0x39, "Sparkle"),
            (0x3A, "Stable keeper"), (0x3B, "Stable helper"), (0x3E, "Monster (rare)"),
            (0x41, "Coffin"), (0x43, "Well NPC"), (0x44, "Egg"), (0x4D, "Door/warp"),
            (0x55, "Egg (hatching)"),
        ]
        npc_type_map = {t: f"0x{t:02X} {n}" for t, n in NPC_TYPE_OPTIONS}
        sprite_map = {s: f"0x{s:02X} {n}" for s, n in SPRITE_OPTIONS}
        type_vals = [t for t, _ in NPC_TYPE_OPTIONS]
        sprite_vals = [s for s, _ in SPRITE_OPTIONS]

        cur_npcs = current.get("npcs_step0", [])
        npcs_step0 = []
        n_npcs = st.number_input("Number of NPCs", 0, 4, value=len(cur_npcs), key="rm_nnpc")
        for ni in range(n_npcs):
            nc = cur_npcs[ni] if ni < len(cur_npcs) else (0x00, 0x0B, 4, 4, 0xFF)
            c1, c2, c3, c4, c5 = st.columns(5)
            with c1:
                cur_type_idx = type_vals.index(nc[0]) if nc[0] in type_vals else 0
                ntype = st.selectbox("Type", type_vals,
                    format_func=lambda t: npc_type_map.get(t, f"0x{t:02X}"),
                    index=cur_type_idx, key=f"rm_nt{ni}")
            with c2:
                cur_spr_idx = sprite_vals.index(nc[1]) if nc[1] in sprite_vals else 0
                nsprite = st.selectbox("Sprite", sprite_vals,
                    format_func=lambda s: sprite_map.get(s, f"0x{s:02X}"),
                    index=cur_spr_idx, key=f"rm_ns{ni}")
            with c3:
                nx = st.number_input("X", 0, 9, value=nc[2], key=f"rm_nx{ni}")
            with c4:
                ny = st.number_input("Y", 0, 8, value=nc[3], key=f"rm_ny{ni}")
            with c5:
                nscript = st.number_input("Script", 0, 255, value=nc[4], key=f"rm_nscr{ni}",
                    help="0xFF = no interaction, 0x01-0xFE = dialogue script ID")
            npcs_step0.append((ntype, nsprite, nx, ny, nscript))

        # Exit editor (Step 0)
        st.markdown("##### Exits (Step 0)")
        cur_exits = current.get("exits_step0", [])
        exits_step0 = []
        n_exits = st.number_input("Number of exits", 0, 3, value=max(1, len(cur_exits)), key="rm_nex")
        for ei in range(n_exits):
            ec = cur_exits[ei] if ei < len(cur_exits) else (4, 7, 0x00, 0x00, 0x05, 4, 5)
            c1, c2, c3, c4, c5, c6, c7 = st.columns(7)
            with c1:
                etx = st.number_input("TrigX", 0, 9, value=ec[0], key=f"rm_etx{ei}")
            with c2:
                ety = st.number_input("TrigY", 0, 8, value=ec[1], key=f"rm_ety{ei}")
            with c3:
                emt = st.number_input("DestMT", 0, 255, value=ec[2], key=f"rm_emt{ei}",
                    help="Destination map_type (0x00=Castle, 0x01=GreatTree...)")
            with c4:
                egf = st.number_input("GateFlg", 0, 255, value=ec[3], key=f"rm_egf{ei}")
            with c5:
                escr = st.number_input("Screen", 0, 255, value=ec[4], key=f"rm_escr{ei}")
            with c6:
                esx = st.number_input("SpawnX", 0, 255, value=ec[5], key=f"rm_esx{ei}")
            with c7:
                esy = st.number_input("SpawnY", 0, 255, value=ec[6], key=f"rm_esy{ei}")
            exits_step0.append((etx, ety, emt, egf, escr, esx, esy))

        # Step 1 (post-state, e.g., after defeating boss)
        with st.expander("Step 1 (alternate state — optional)"):
            use_step1 = st.checkbox("Enable Step 1", value=bool(current.get("npcs_step1") or current.get("exits_step1")), key="rm_s1")
            npcs_step1 = []
            exits_step1 = []
            if use_step1:
                st.caption("Step 1 loads when the RAM flag matches step1_id (e.g., post-defeat)")
                cur_npcs1 = current.get("npcs_step1", [])
                cur_exits1 = current.get("exits_step1", [(4, 7, 0x00, 0x00, 0x01, 4, 5)])
                n_npcs1 = st.number_input("NPCs (step 1)", 0, 4, value=len(cur_npcs1), key="rm_nnpc1")
                for ni in range(n_npcs1):
                    nc = cur_npcs1[ni] if ni < len(cur_npcs1) else (0x00, 0x0B, 4, 4, 0xFF)
                    c1, c2, c3, c4, c5 = st.columns(5)
                    with c1: ntype = st.number_input("Type", 0, 255, value=nc[0], key=f"rm_nt1_{ni}")
                    with c2: nsprite = st.number_input("Sprite", 0, 255, value=nc[1], key=f"rm_ns1_{ni}")
                    with c3: nx = st.number_input("X", 0, 9, value=nc[2], key=f"rm_nx1_{ni}")
                    with c4: ny = st.number_input("Y", 0, 8, value=nc[3], key=f"rm_ny1_{ni}")
                    with c5: nscript = st.number_input("Script", 0, 255, value=nc[4], key=f"rm_nscr1_{ni}")
                    npcs_step1.append((ntype, nsprite, nx, ny, nscript))
                n_exits1 = st.number_input("Exits (step 1)", 0, 3, value=max(1, len(cur_exits1)), key="rm_nex1")
                for ei in range(n_exits1):
                    ec = cur_exits1[ei] if ei < len(cur_exits1) else (4, 7, 0x00, 0x00, 0x01, 4, 5)
                    c1, c2, c3, c4, c5, c6, c7 = st.columns(7)
                    with c1: etx = st.number_input("TrigX", 0, 9, value=ec[0], key=f"rm_etx1_{ei}")
                    with c2: ety = st.number_input("TrigY", 0, 8, value=ec[1], key=f"rm_ety1_{ei}")
                    with c3: emt = st.number_input("DestMT", 0, 255, value=ec[2], key=f"rm_emt1_{ei}")
                    with c4: egf = st.number_input("GateFlg", 0, 255, value=ec[3], key=f"rm_egf1_{ei}")
                    with c5: escr = st.number_input("Screen", 0, 255, value=ec[4], key=f"rm_escr1_{ei}")
                    with c6: esx = st.number_input("SpawnX", 0, 255, value=ec[5], key=f"rm_esx1_{ei}")
                    with c7: esy = st.number_input("SpawnY", 0, 255, value=ec[6], key=f"rm_esy1_{ei}")
                    exits_step1.append((etx, ety, emt, egf, escr, esx, esy))

        # Preview
        with st.expander("Binary Preview"):
            preview_data = build_custom_room_data(
                tileset=tileset, ram_flag=0xD377,
                step0_id=0x01, step1_id=0x02,
                npcs_step0=npcs_step0, npcs_step1=npcs_step1,
                exits_step0=exits_step0, exits_step1=exits_step1,
            )
            hex_lines = []
            for i in range(0, len(preview_data), 16):
                chunk = preview_data[i:i+16]
                hex_str = " ".join(f"{b:02X}" for b in chunk)
                label = {0x00: "screen_ptrs", 0x08: "step_block", 0x20: "interact_0",
                         0x38: "interact_1", 0x50: "exit_0", 0x68: "exit_1"}.get(i, "")
                hex_lines.append(f"  +{i:02X}: {hex_str:48s} {label}")
            st.code("\n".join(hex_lines), language=None)

        # Save button
        if st.button("💾 Save Room", type="primary", key="rm_save"):
            room_def = {
                "name": room_name,
                "map_type": map_type,
                "tileset": tileset,
                "ram_flag": 0xD9E9,
                "step0_id": 0x00,
                "step1_id": 0x01,
                "npcs_step0": npcs_step0,
                "npcs_step1": npcs_step1 if use_step1 else [],
                "exits_step0": exits_step0,
                "exits_step1": exits_step1 if use_step1 else [],
            }
            save_custom_room(edits, room_def, room_idx if not is_new else -1)
            save_edits(edits)
            st.success(f"Room saved to map_type 0x{map_type:02X}. Build to apply.")
            st.rerun()

        # Delete room
        if not is_new and room_idx < len(rooms):
            if st.button("🗑️ Delete Room", key="rm_del"):
                rooms.pop(room_idx)
                # Clean up patches for this room
                raw = edits.get("raw_bytes", {})
                bank_flat = CROSSBANK_ROOM_BANK * 0x4000
                addr_key = f"0x{bank_flat + room_idx * 128:06X}"
                raw.pop(addr_key, None)
                save_edits(edits)
                st.rerun()

# ============ RANDOMIZE TAB ============
with tab_random:
    if st.button("🎲 Shuffle monster skills + caps + resistances"):
        subprocess.run([sys.executable, "-m", "tools.randomize"], check=True)
        st.success("Randomized. Switch to Build tab.")


# ============ REVERT TAB ============
with tab_revert:
    st.markdown("### Revert Edits")
    st.markdown(
        "Remove edits from `edits.json`. The build pipeline always starts from the "
        "original ROM, so removing an edit reverts that change."
    )

    # Count edits by category
    enc_offsets = [k for k in edits.get("raw_bytes", {})
                   if int(k, 16) >= POOL_BLOCK_BASE
                   and int(k, 16) < POOL_BLOCK_BASE + 128 * POOL_BLOCK_SIZE]
    boss_offsets = [k for k in edits.get("raw_bytes", {})
                    if int(k, 16) >= BOSS_TABLE_BASE
                    and int(k, 16) < BOSS_TABLE_BASE + 32 * BOSS_TABLE_STRIDE]
    starter_offsets = [k for k in edits.get("raw_bytes", {})
                       if int(k, 16) >= 0x50C36 and int(k, 16) <= 0x50C4E]
    es_end = ENEMY_STATS_ROM_BASE + 487 * ENEMY_STATS_ENTRY_SIZE
    estats_offsets = [k for k in edits.get("raw_bytes", {})
                      if int(k, 16) >= ENEMY_STATS_ROM_BASE
                      and int(k, 16) < es_end
                      and k not in starter_offsets]
    # Join system: hook code + per-gate table
    join_hook_keys = set(JOIN_HOOK_BYTES.keys())
    join_table_keys = {f"0x{JOIN_TABLE_FLAT + g:05X}" for g in range(32)}
    join_all_keys = join_hook_keys | join_table_keys
    join_offsets = [k for k in edits.get("raw_bytes", {}) if k in join_all_keys]
    routing_offsets = get_routing_edits(edits)
    npc_offsets = get_npc_edits(edits)
    other_raw = [k for k in edits.get("raw_bytes", {})
                 if k not in enc_offsets and k not in starter_offsets
                 and k not in estats_offsets and k not in boss_offsets
                 and k not in join_all_keys and k not in routing_offsets
                 and k not in npc_offsets]

    join_status = "enabled" if is_join_system_enabled(edits) else "disabled"
    n_gates_on = count_gates_forced(edits)
    st.markdown(f"""
**Current edit counts:**
- Encounter pool edits: **{len(enc_offsets)}** raw_bytes entries
- Boss edits: **{len(boss_offsets)}** raw_bytes entries
- Boss join system: **{join_status}** ({n_gates_on} gates forced, {len(join_offsets)} raw_bytes entries)
- Enemy stats edits: **{len(estats_offsets)}** raw_bytes entries
- Starter monster edits: **{len(starter_offsets)}** raw_bytes entries (EID 1)
- Room routing edits: **{len(routing_offsets)}** raw_bytes entries
- NPC edits: **{len(npc_offsets)}** raw_bytes entries
- Other raw_bytes edits: **{len(other_raw)}**
- Monster stat edits: **{len(edits.get('monster_stats', {}))}**
- Text edits: **{len(edits.get('text', {}))}**
""")

    col1, col2 = st.columns(2)

    with col1:
        if st.button("↩️ Clear encounter edits", disabled=len(enc_offsets) == 0):
            for k in enc_offsets:
                del edits["raw_bytes"][k]
            save_edits(edits)
            st.success(f"Cleared {len(enc_offsets)} encounter edits")
            st.rerun()

        if st.button("↩️ Clear boss edits", disabled=len(boss_offsets) == 0):
            for k in boss_offsets:
                del edits["raw_bytes"][k]
            save_edits(edits)
            st.success(f"Cleared {len(boss_offsets)} boss edits")
            st.rerun()

        if st.button("↩️ Clear boss join system", disabled=len(join_offsets) == 0):
            disable_join_system(edits)
            save_edits(edits)
            st.success("Removed boss join system (hook code + all gate flags)")
            st.rerun()

        if st.button("↩️ Clear enemy stats edits", disabled=len(estats_offsets) == 0):
            for k in estats_offsets:
                del edits["raw_bytes"][k]
            save_edits(edits)
            st.success(f"Cleared {len(estats_offsets)} enemy stats edits")
            st.rerun()

        if st.button("↩️ Clear starter edits", disabled=len(starter_offsets) == 0):
            for k in starter_offsets:
                del edits["raw_bytes"][k]
            save_edits(edits)
            st.success(f"Cleared {len(starter_offsets)} starter edits")
            st.rerun()

        if st.button("↩️ Clear routing edits", disabled=len(routing_offsets) == 0):
            for k in routing_offsets:
                del edits["raw_bytes"][k]
            save_edits(edits)
            st.success(f"Cleared {len(routing_offsets)} routing edits")
            st.rerun()

        if st.button("↩️ Clear NPC edits", disabled=len(npc_offsets) == 0):
            for k in npc_offsets:
                del edits["raw_bytes"][k]
            save_edits(edits)
            st.success(f"Cleared {len(npc_offsets)} NPC edits")
            st.rerun()

        if st.button("↩️ Clear all raw_bytes", disabled=len(edits.get("raw_bytes", {})) == 0):
            edits["raw_bytes"] = {}
            save_edits(edits)
            st.success("Cleared all raw_bytes edits")
            st.rerun()

    with col2:
        if st.button("↩️ Clear monster stat edits", disabled=len(edits.get("monster_stats", {})) == 0):
            edits["monster_stats"] = {}
            save_edits(edits)
            st.success("Cleared monster stat edits")
            st.rerun()

        if st.button("↩️ Clear text edits", disabled=len(edits.get("text", {})) == 0):
            edits["text"] = {}
            save_edits(edits)
            st.success("Cleared text edits")
            st.rerun()

        if st.button("🗑️ Clear ALL edits", type="primary"):
            edits = {"monster_stats": {}, "text": {}, "raw_bytes": {}}
            save_edits(edits)
            st.success("All edits cleared — ROM will build as vanilla")
            st.rerun()

    # Show raw_bytes detail
    if edits.get("raw_bytes"):
        with st.expander("📋 All raw_bytes edits"):
            for k in sorted(edits["raw_bytes"].keys(), key=lambda x: int(x, 16)):
                offset = int(k, 16)
                label = ""
                if k in enc_offsets:
                    label = " (encounter)"
                elif k in boss_offsets:
                    gate_num = (offset - BOSS_TABLE_BASE) // BOSS_TABLE_STRIDE
                    label = f" (boss gate {gate_num}: {GATE_NAMES.get(gate_num, '?')})"
                elif k in join_all_keys:
                    if k in join_hook_keys:
                        label = " (join system hook)"
                    else:
                        gate_num = offset - JOIN_TABLE_FLAT
                        flag_val = "ON" if int(edits["raw_bytes"][k].strip(), 16) else "OFF"
                        label = f" (join gate {gate_num}: {GATE_BOSSES.get(gate_num, '?')} = {flag_val})"
                elif k in starter_offsets:
                    label = " (starter)"
                elif k in routing_offsets:
                    label = " (routing)"
                elif k in npc_offsets:
                    label = " (npc)"
                elif k in estats_offsets:
                    eid_num = (offset - ENEMY_STATS_ROM_BASE) // ENEMY_STATS_ENTRY_SIZE
                    eid_name = eid_lookup.get(eid_num, {}).get("name", "???")
                    label = f" (enemy stats EID {eid_num} {eid_name})"
                st.code(f"{k}: {edits['raw_bytes'][k]}{label}", language=None)


# ============ BUILD TAB ============
with tab_build:
    n_text_inplace = sum(1 for v in edits["text"].values() if isinstance(v, str))
    n_text_repoint = sum(1 for v in edits["text"].values() if isinstance(v, dict))
    st.write(f"- {len(edits['monster_stats'])} monster edits")
    st.write(f"- {n_text_inplace} in-place text edits")
    st.write(f"- {n_text_repoint} repointed text edits")
    st.write(f"- {len(edits['raw_bytes'])} raw byte edits")

    if st.button("🛠 Build & verify"):
        r = subprocess.run([sys.executable, "-m", "tools.build_rom"],
                           capture_output=True, text=True)
        st.code(r.stdout + r.stderr)
        shot = Path("data/title_after_build.png")
        if shot.exists(): st.image(str(shot), caption="Boot screenshot")


# ============ INFO TAB ============
with tab_info:
    total_free = sum(r["length"] for runs in free.values() for r in runs)
    st.metric("Total free bytes available", total_free)
    st.metric("Strings in catalog", len(blobs))
    st.metric("Pointer tables", len(tables["tables"]))
    st.metric("Orphan strings", len(tables.get("orphans", [])))
    st.metric("Encounter pools loaded", sum(len(g.get("floor_groups", [])) for g in encounters_data.values()))
    st.metric("Unique enemy_stats_ids", len(eid_lookup))
