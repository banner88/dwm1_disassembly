"""Dump step block data for all rooms to understand pre/post defeat variants.

Shows: which RAM flag controls each room's step, what NPCs/exits load per step,
and how boss rooms switch between boss-present and gate-present states.

Usage:
    python dump_steps.py path/to/DWM-original.gbc
    python dump_steps.py path/to/DWM-original.gbc --room 0x30   # specific room
    python dump_steps.py path/to/DWM-original.gbc --boss-only   # just boss rooms
    python dump_steps.py path/to/DWM-original.gbc --all --brief # all rooms, compact
"""
import sys
from pathlib import Path

BANK_SIZE = 0x4000
BANK = 0x0B
MAP_PTR_ADDR = 0x4B43

MAP_NAMES = {
    0x00: "Castle", 0x01: "GreatTree", 0x02: "Bazaar", 0x03: "Gate Hub",
    0x04: "Farm", 0x05: "Stable", 0x06: "Arena Lobby", 0x07: "Arena Rooms",
    0x08: "Starry Shrine Breeding Cutscene", 0x09: "Starry Shrine",
    0x0A: "Secret Passage", 0x0B: "Castle: Chest Room (variant)",
    0x0C: "Egg Evaluator", 0x0D: "Old Man Gate Room",
    0x0E: "Castle: Chest Room (variant)", 0x0F: "Vault",
    0x10: "Copycat House", 0x11: "Castle: Chest Room (variant)",
    0x12: "Library", 0x13: "Library Gate Room",
    0x14: "Castle: Chest Room (variant)", 0x15: "Castle: Chest Room (variant)",
    0x16: "MedalMan", 0x17: "Copycat House (Glitched)", 0x18: "Well",
    0x19: "Goopy Room 1", 0x1A: "Goopy Room 2",
    0x1B: "Stable: KingSlime Room", 0x1C: "Stable: Coffin Room",
    0x1D: "Monster School", 0x1E: "Restaurant", 0x1F: "Queen Room",
    0x23: "Room of Beginning",
    0x24: "Room: Villager/Talisman", 0x25: "Room: Memories/Bewilder",
    0x26: "Room: Peace/Bravery", 0x27: "Room: Strength/Anger",
    0x28: "Room: Joy/Wisdom", 0x29: "Room: Happiness/Temptation",
    0x2A: "Room: Labyrinth/Judgment", 0x2B: "Room: Reflection",
    0x2C: "Room: Ambition/Demolition", 0x2D: "Room: Mastermind/Control",
    0x2E: "Room: Extinction/Sleep", 0x2F: "Intro Bedroom",
    0x30: "Boss: Beginning (Healer)", 0x31: "Boss: Villager (Dragon)",
    0x32: "Boss: Talisman (Golem)", 0x33: "Boss: Memories (MadCat)",
    0x34: "Boss: Bewilder (FaceTree)", 0x35: "Boss: Bazaar (MadKnight)",
    0x36: "Boss: Peace (FangSlime)", 0x37: "Boss: Bravery (BigEye)",
    0x38: "Boss: Well (Gigantes)", 0x39: "Boss: Strength (StoneMan)",
    0x3A: "Boss: Wisdom (SkyDragon)", 0x3B: "Boss: Joy (FunkyBird)",
    0x3C: "Boss: Anger (BattleRex)", 0x3D: "Boss: Arena Left (Digster)",
    0x3E: "Boss: Happiness (Jamirus)", 0x3F: "Boss: Temptation (Servant)",
    0x40: "KingSlime Decision Room (3 doors)",
    0x41: "Boss: Medal (Lipsy variant)", 0x42: "Labyrinth",
    0x43: "Boss: Judgment (Akubar)", 0x44: "Boss: Library (Orochi)",
    0x45: "Boss: Reflection (Durran)", 0x46: "Boss: Ambition (DracoLord)",
    0x47: "Boss: Demolition (Hargon/Sidoh)",
    0x48: "Boss: Mastermind (Baramos)", 0x49: "Boss: Control (Zoma)",
    0x4A: "Boss: Extinction (Pizzaro)", 0x4B: "Boss: Sleep (Esterk)",
    0x4C: "Boss: Bazaar Edge (Mirudraas)", 0x4D: "Boss: Arena Right (Mudou)",
    0x4E: "Boss: Grandpa's Gate (DeathMore)",
    0x4F: "Boss: Unused (DarkDrium)",
    0x50: "Gate Floor: Item Shop", 0x51: "Gate Floor: Priest",
    0x52: "Gate Floor: Coliseum", 0x53: "Forest Maze",
    0x54: "Conveyor Maze 1", 0x55: "Conveyor Maze 2", 0x56: "Conveyor Maze 3",
    0x57: "Maze 1", 0x58: "Maze 2", 0x59: "Maze 3",
    0x5A: "Gate Floor: 6 Chests Diagonal", 0x5B: "Gate Floor: 6 Chests Rows",
    0x5C: "Gate Floor: 8 Chests Rows", 0x5D: "Arena Battle",
    0x5E: "Arena Setup Room", 0x60: "Labyrinth Final",
    0x61: "Forest Maze Gate Floor 1", 0x62: "Forest Maze Gate Floor 2",
    0x63: "Forest Maze Gate Floor 3", 0x64: "Forest Maze Gate Floor 4",
}

BOSS_ROOMS = set(range(0x30, 0x50)) | {0x40, 0x41}


def flat(addr):
    return BANK * BANK_SIZE + (addr - 0x4000)


def parse_step_block(d, block_addr):
    bf = flat(block_addr)
    ram_ptr = d[bf] | (d[bf + 1] << 8)
    steps = []
    offset = bf + 2
    for _ in range(12):
        if offset + 5 >= len(d):
            break
        step_id = d[offset]
        tileset = d[offset + 1]
        interact = d[offset + 2] | (d[offset + 3] << 8)
        exit_ptr = d[offset + 4] | (d[offset + 5] << 8)
        if not (0x4000 <= interact <= 0x7FFF):
            break
        steps.append({
            "step_id": step_id, "tileset": tileset,
            "interact_ptr": interact, "exit_ptr": exit_ptr,
            "interact_flat": flat(interact), "exit_flat": flat(exit_ptr),
        })
        offset += 6
    return ram_ptr, steps


def parse_interaction_block(d, interact_ptr):
    bf = flat(interact_ptr)
    npcs, specials = [], []
    pos = 0
    for _ in range(30):
        if bf + pos >= len(d) or d[bf + pos] == 0xFF:
            break
        raw = list(d[bf + pos:bf + pos + 5])
        byte = raw[0]
        if byte & 0x80:
            kind = {0x8F: "arrival", 0x90: "exit_trig", 0x82: "setup_82",
                    0x81: "setup_81", 0x80: "setup_80"}.get(byte, f"spc_{byte:02X}")
            specials.append(f"{kind}({raw[1]:02X},{raw[2]:02X},{raw[3]:02X},{raw[4]:02X})")
        else:
            npcs.append(f"type=0x{byte:02X} spr=0x{raw[1]:02X} @({raw[2]},{raw[3]}) scr=0x{raw[4]:02X}")
        pos += 5
    return npcs, specials


def parse_exit_block(d, exit_ptr):
    bf = flat(exit_ptr)
    exits = []
    pos = 0
    for _ in range(20):
        if bf + pos >= len(d) or d[bf + pos] == 0xFF:
            break
        raw = list(d[bf + pos:bf + pos + 7])
        if len(raw) < 7:
            break
        exits.append(
            f"trig({raw[0]},{raw[1]}) -> mt=0x{raw[2]:02X} gf=0x{raw[3]:02X} "
            f"scr=0x{raw[4]:02X} spawn({raw[5]},{raw[6]})"
        )
        pos += 7
    return exits


def dump_room(d, mt, room_pointers, verbose=True):
    name = MAP_NAMES.get(mt, f"Map_{mt:02X}")
    if mt >= len(room_pointers):
        return
    room_ptr = room_pointers[mt]
    if not (0x4000 <= room_ptr <= 0x7FFF):
        return

    rf = flat(room_ptr)
    print(f"\n{'='*80}")
    print(f"0x{mt:02X} {name}  (ptr=0x{room_ptr:04X}, flat=0x{rf:06X})")
    print(f"{'='*80}")

    screen_idx = 0
    pos = 0
    for screen in range(16):
        screen_ptrs = []
        for slot in range(4):
            if rf + pos + 1 >= len(d):
                break
            p = d[rf + pos] | (d[rf + pos + 1] << 8)
            screen_ptrs.append(p)
            pos += 2

        valid_steps = []
        for slot_idx, ptr in enumerate(screen_ptrs):
            if ptr == 0xFFFF or not (0x4000 <= ptr <= 0x7FFF):
                continue
            pf = flat(ptr)
            if pf + 1 < len(d) and d[pf + 1] == 0xD9:
                ram_ptr, steps = parse_step_block(d, ptr)
                valid_steps.append((slot_idx, ptr, ram_ptr, steps))

        if valid_steps:
            print(f"\n  Screen {screen_idx}:")
            for slot_idx, ptr, ram_ptr, steps in valid_steps:
                print(f"    Slot {slot_idx}: step_block @0x{ptr:04X}, RAM flag=0x{ram_ptr:04X}")
                for step in steps:
                    npcs, specials = parse_interaction_block(d, step["interact_ptr"])
                    exits = parse_exit_block(d, step["exit_ptr"])
                    marker = ""
                    if step["step_id"] == 0x00 and mt in BOSS_ROOMS:
                        marker = "  << BOSS PRESENT?"
                    elif step["step_id"] > 0x00 and mt in BOSS_ROOMS:
                        marker = "  << POST-DEFEAT?"
                    print(f"      Step 0x{step['step_id']:02X}: tileset=0x{step['tileset']:02X}  "
                          f"interact=0x{step['interact_ptr']:04X}  exit=0x{step['exit_ptr']:04X}{marker}")
                    if verbose:
                        for s in specials:
                            print(f"        [special] {s}")
                        for n in npcs:
                            print(f"        [npc]     {n}")
                        for e in exits:
                            print(f"        [exit]    {e}")
                    else:
                        print(f"        {len(npcs)} NPCs, {len(specials)} specials, {len(exits)} exits")
            screen_idx += 1
        else:
            if all(p == 0xFFFF for p in screen_ptrs):
                continue
            if screen > 0 and not any(0x4000 <= p <= 0x7FFF for p in screen_ptrs):
                break
            screen_idx += 1


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Dump step block data for DWM1 rooms")
    parser.add_argument("rom", help="Path to DWM-original.gbc")
    parser.add_argument("--room", help="Specific room hex (e.g. 0x30)", default=None)
    parser.add_argument("--boss-only", action="store_true", help="Only dump boss rooms")
    parser.add_argument("--brief", action="store_true", help="Compact output (counts only)")
    parser.add_argument("--all", action="store_true", help="Dump all rooms")
    args = parser.parse_args()

    d = bytearray(Path(args.rom).read_bytes())

    # Read map pointer table
    ptr_table_flat = flat(MAP_PTR_ADDR)
    room_pointers = []
    for i in range(107):
        lo = d[ptr_table_flat + i * 2]
        hi = d[ptr_table_flat + i * 2 + 1]
        ptr = lo | (hi << 8)
        room_pointers.append(ptr)

    if args.room:
        mt = int(args.room, 16)
        dump_room(d, mt, room_pointers, verbose=not args.brief)
    elif args.boss_only:
        for mt in sorted(BOSS_ROOMS):
            dump_room(d, mt, room_pointers, verbose=not args.brief)
    elif args.all:
        for mt in range(107):
            dump_room(d, mt, room_pointers, verbose=not args.brief)
    else:
        # Default: interesting rooms with known multi-step behavior
        interesting = [0x00, 0x01, 0x04, 0x30, 0x31, 0x36, 0x40, 0x42, 0x4E, 0x4F, 0x53]
        for mt in interesting:
            dump_room(d, mt, room_pointers, verbose=not args.brief)

    # Summary: RAM flag → room mapping
    print(f"\n{'='*80}")
    print("RAM FLAG SUMMARY — which flag controls which rooms")
    print(f"{'='*80}")
    flag_rooms = {}
    for mt in range(107):
        if mt >= len(room_pointers):
            continue
        room_ptr = room_pointers[mt]
        if not (0x4000 <= room_ptr <= 0x7FFF):
            continue
        rf = flat(room_ptr)
        pos = 0
        for screen in range(16):
            for slot in range(4):
                if rf + pos + 1 >= len(d):
                    break
                p = d[rf + pos] | (d[rf + pos + 1] << 8)
                pos += 2
                if p == 0xFFFF or not (0x4000 <= p <= 0x7FFF):
                    continue
                pf = flat(p)
                if pf + 1 < len(d) and d[pf + 1] == 0xD9:
                    ram_ptr, steps = parse_step_block(d, p)
                    name = MAP_NAMES.get(mt, f"Map_{mt:02X}")
                    step_ids = [s["step_id"] for s in steps]
                    key = (ram_ptr, mt, screen)
                    flag_rooms.setdefault(ram_ptr, []).append(
                        (mt, name, screen, step_ids)
                    )

    seen = set()
    for flag in sorted(flag_rooms.keys()):
        rooms = flag_rooms[flag]
        # Deduplicate
        unique = []
        for entry in rooms:
            key = (entry[0], entry[2])
            if key not in seen:
                seen.add(key)
                unique.append(entry)
        if unique:
            print(f"\n  RAM 0x{flag:04X}:")
            for mt, name, scr, step_ids in unique:
                steps_str = ",".join(f"0x{s:02X}" for s in step_ids)
                print(f"    0x{mt:02X} {name} scr{scr}  steps=[{steps_str}]")


if __name__ == "__main__":
    main()
