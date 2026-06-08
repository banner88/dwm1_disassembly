"""Parse all rooms' NPC spawn data from the map pointer table.

Outputs a full NPC catalog with sprite IDs, positions, scripts, and ROM addresses.

Usage:
    uv run python -m tools.dump_all_npcs
"""
import json
from pathlib import Path
from collections import defaultdict
from dwm.rom import ROM, BANK_SIZE

BANK = 0x0B
MAP_PTR_ADDR = 0x4B43

MAP_NAMES = {
    0x00: "Castle", 0x01: "GreatTree", 0x02: "Bazaar", 0x03: "Gate Hub",
    0x04: "Farm", 0x05: "Stable", 0x06: "Arena Lobby", 0x07: "Arena Rooms",
    0x08: "Gate(08)", 0x09: "Starry Shrine", 0x0A: "Secret Passage",
    0x0C: "Renamer", 0x0D: "Old Man Gate Room", 0x0F: "Vault",
    0x10: "Copycat House", 0x12: "Library", 0x16: "MedalMan", 0x18: "Well",
    0x1D: "Monster School", 0x1E: "Restaurant", 0x1F: "Queen Room",
    0x23: "Room of Beginning", 0x24: "Villager/Talisman", 0x25: "Memories/Bewilder",
    0x26: "Peace/Bravery", 0x27: "Strength/Anger", 0x28: "Joy/Wisdom",
    0x29: "Happiness/Temptation", 0x2A: "Labyrinth/Judgment", 0x2B: "Reflection",
    0x2C: "Ambition/Demolition", 0x2D: "Mastermind/Control",
    0x2E: "Extinction/Sleep", 0x30: "Boss: Beginning", 0x42: "Labyrinth",
    0x4E: "Boss(4E)", 0x4F: "Boss: Unused Gate",
    0x52: "Coliseum", 0x53: "Forest Maze",
    0x5D: "Arena Battle", 0x5E: "Arena Battle(5E)",
}


def flat(addr):
    return BANK * BANK_SIZE + (addr - 0x4000)


def parse_interaction_block(data, rom_data, block_addr):
    """Parse a 5-byte-entry interaction block. Returns list of entries."""
    entries = []
    bf = flat(block_addr)
    pos = 0
    max_bytes = 128  # safety limit

    while pos < max_bytes:
        if bf + pos >= len(rom_data):
            break
        byte = rom_data[bf + pos]

        if byte == 0xFF:
            entries.append({
                "type": "terminator", "raw": [0xFF],
                "offset": pos, "flat": bf + pos,
            })
            break

        if pos + 4 >= max_bytes or bf + pos + 4 >= len(rom_data):
            break

        raw = list(rom_data[bf + pos:bf + pos + 5])

        if byte & 0x80:  # bit 7 set: 0x8F, 0x90, 0x82, 0x81, 0x80
            kind = {0x8F: "arrival", 0x90: "exit_trigger", 0x82: "setup_82",
                    0x81: "setup_81", 0x80: "setup_80"}.get(byte, f"special_{byte:02X}")
            entries.append({
                "type": kind, "code": byte, "raw": raw,
                "b1": raw[1], "b2": raw[2], "b3": raw[3], "b4": raw[4],
                "offset": pos, "flat": bf + pos,
            })
        else:
            # NPC entry: [type] [sprite] [X] [Y] [script]
            entries.append({
                "type": "npc", "npc_type": byte,
                "sprite": raw[1], "x": raw[2], "y": raw[3], "script": raw[4],
                "raw": raw, "offset": pos, "flat": bf + pos,
            })

        pos += 5

    return entries


def parse_step_block(rom_data, block_addr):
    """Parse a step block: 2-byte RAM ptr + repeating 6-byte step entries."""
    bf = flat(block_addr)
    ram_lo = rom_data[bf]
    ram_hi = rom_data[bf + 1]
    ram_ptr = ram_lo | (ram_hi << 8)

    steps = []
    offset = bf + 2
    for i in range(12):  # max steps
        if offset + 5 >= len(rom_data):
            break
        step_id = rom_data[offset]
        tileset = rom_data[offset + 1]
        interact = rom_data[offset + 2] | (rom_data[offset + 3] << 8)
        exit_ptr = rom_data[offset + 4] | (rom_data[offset + 5] << 8)

        if not (0x4000 <= interact <= 0x7FFF):
            break

        steps.append({
            "step_id": step_id, "tileset": tileset,
            "interact_ptr": interact, "exit_ptr": exit_ptr,
            "interact_flat": flat(interact), "exit_flat": flat(exit_ptr),
        })
        offset += 6

    return ram_ptr, steps


def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    d = rom.data

    # Read map pointer table
    ptr_table_flat = flat(MAP_PTR_ADDR)
    room_pointers = []
    for i in range(107):
        lo = d[ptr_table_flat + i * 2]
        hi = d[ptr_table_flat + i * 2 + 1]
        ptr = lo | (hi << 8)
        room_pointers.append(ptr)

    # Track all NPCs and sprites
    all_npcs = []
    sprite_usage = defaultdict(list)
    npc_type_usage = defaultdict(int)

    # Track seen interaction pointers to avoid duplicates
    seen_interact = set()

    print("=" * 90)
    print("COMPLETE NPC CATALOG")
    print("=" * 90)

    for map_type, room_ptr in enumerate(room_pointers):
        if not (0x4000 <= room_ptr <= 0x7FFF):
            continue

        name = MAP_NAMES.get(map_type, "")
        rf = flat(room_ptr)

        # Parse screen blocks (8 bytes each: up to 4 pointers)
        # Detect how many screens by reading pointer pairs
        screen_ptrs = []
        pos = 0
        for screen in range(16):  # max screens
            if rf + pos + 7 >= len(d):
                break
            ptrs = []
            all_ff = True
            for slot in range(4):
                p = d[rf + pos] | (d[rf + pos + 1] << 8)
                if p != 0xFFFF:
                    all_ff = False
                ptrs.append(p)
                pos += 2

            # If first pointer of this screen block looks like step data
            # (has D9 as second byte), we've gone past the pointer table
            if len(screen_ptrs) > 0 and all_ff:
                # Check if next block also looks wrong
                if pos + 1 < 128:
                    next_byte = d[rf + pos + 1] if rf + pos + 1 < len(d) else 0
                    if next_byte == 0xD9:
                        break
                continue

            # Check if first ptr looks valid
            first_valid = any(0x4000 <= p <= 0x7FFF for p in ptrs)
            if not first_valid and screen > 0:
                # Might have hit step data
                # Check if this looks like a step block (byte[1] == 0xD9)
                test_addr = rf + pos - 8
                if d[test_addr + 1] == 0xD9:
                    break
                continue

            screen_ptrs.append(ptrs)

            # Heuristic: if we see step data pattern, stop
            if pos < 128:
                next_hi = d[rf + pos + 1] if rf + pos + 1 < len(d) else 0
                if next_hi == 0xD9:
                    break

        # For rooms with no clear screen blocks, try direct step block parse
        if not screen_ptrs:
            # The room pointer might directly point to step data
            if d[rf + 1] == 0xD9:
                # Direct step block
                pass
            continue

        # Process each screen's step blocks
        room_npcs = []
        for screen_idx, ptrs in enumerate(screen_ptrs):
            for slot_idx, ptr in enumerate(ptrs):
                if ptr == 0xFFFF or not (0x4000 <= ptr <= 0x7FFF):
                    continue

                # Check if this is a step block (byte[1] should be 0xD9)
                pf = flat(ptr)
                if d[pf + 1] != 0xD9:
                    continue

                ram_ptr, steps = parse_step_block(d, ptr)

                for step in steps:
                    iptr = step["interact_ptr"]
                    if iptr in seen_interact:
                        continue
                    seen_interact.add(iptr)

                    entries = parse_interaction_block(d, d, iptr)

                    for entry in entries:
                        if entry["type"] == "npc":
                            npc = {
                                "map_type": map_type,
                                "room": name or f"Map_{map_type:02X}",
                                "screen": screen_idx,
                                "step_id": step["step_id"],
                                "npc_type": entry["npc_type"],
                                "sprite": entry["sprite"],
                                "x": entry["x"],
                                "y": entry["y"],
                                "script": entry["script"],
                                "flat": entry["flat"],
                                "interact_ptr": iptr,
                            }
                            room_npcs.append(npc)
                            all_npcs.append(npc)
                            sprite_usage[entry["sprite"]].append(npc)
                            npc_type_usage[entry["npc_type"]] += 1

        if room_npcs:
            print(f"\n--- 0x{map_type:02X} {name or 'Unknown'} ({len(room_npcs)} NPCs) ---")
            for npc in room_npcs:
                print(f"  type={npc['npc_type']:02X} sprite=0x{npc['sprite']:02X} "
                      f"X={npc['x']:2d} Y={npc['y']:2d} script=0x{npc['script']:02X}  "
                      f"step=0x{npc['step_id']:02X}  flat=0x{npc['flat']:06X}")

    # Summary
    print("\n" + "=" * 90)
    print("SUMMARY")
    print("=" * 90)
    print(f"\nTotal NPCs found: {len(all_npcs)}")
    print(f"Unique rooms with NPCs: {len(set(n['map_type'] for n in all_npcs))}")

    print(f"\n--- NPC Type Distribution ---")
    for t, count in sorted(npc_type_usage.items()):
        print(f"  type 0x{t:02X}: {count:3d} NPCs")

    print(f"\n--- Sprite ID Reference ({len(sprite_usage)} unique sprites) ---")
    for sprite_id in sorted(sprite_usage.keys()):
        usages = sprite_usage[sprite_id]
        rooms = sorted(set(n["room"] for n in usages))
        room_str = ", ".join(rooms[:5])
        if len(rooms) > 5:
            room_str += f", +{len(rooms)-5} more"
        print(f"  sprite 0x{sprite_id:02X} ({sprite_id:3d}): {len(usages):3d} uses  "
              f"in: {room_str}")

    # Save JSON for the editor
    out_path = Path("extracted/npc_catalog.json")
    out_path.parent.mkdir(exist_ok=True)
    out_path.write_text(json.dumps(all_npcs, indent=2))
    print(f"\nSaved to {out_path}")

    # Also save sprite reference
    sprite_ref = {}
    for sid, usages in sorted(sprite_usage.items()):
        rooms = sorted(set(n["room"] for n in usages))
        sprite_ref[f"0x{sid:02X}"] = {
            "decimal": sid,
            "count": len(usages),
            "rooms": rooms,
        }
    sprite_path = Path("extracted/sprite_reference.json")
    sprite_path.write_text(json.dumps(sprite_ref, indent=2))
    print(f"Sprite reference saved to {sprite_path}")


if __name__ == "__main__":
    main()
