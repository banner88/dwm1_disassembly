"""Canonical room/map-type names — single source of truth.

Source: editor/editor.py MAP_TYPE_NAMES (96 entries, human-verified,
includes boss rooms with monster names, gate floors, sub-areas).

Every tool that needs room names imports from here.  Do NOT define
local MAP_NAMES / MAP_TYPE_NAMES dictionaries in individual tools.
If a name is wrong, fix it HERE.
"""

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
    0x40: "KingSlime Decision Room (3 doors)",
    0x41: "Boss: Medal (Lipsy variant)",
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


def get_name(map_type: int) -> str:
    """Return the canonical name for a map type, or a hex fallback."""
    return MAP_TYPE_NAMES.get(map_type, f"Map{map_type:02X}")


# Alias for tools that use the shorter name
MAP_NAMES = MAP_TYPE_NAMES
