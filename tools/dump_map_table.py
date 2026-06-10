"""Decode the Bank 0B map pointer table and dump room connection data.

Traces the pointer chain:
  $0B:$4B43 + map_type×2  →  sub_table_ptr
  sub_table_ptr + C925×2  →  room_data_ptr
  room_data_ptr:
    +0,+1  = RAM counter address (identifies room type)
    +2...  = array of 6-byte step entries:
               +0,+1 = unknown (possibly tilemap/config pointer)
               +2,+3 = interact/NPC data pointer
               +4,+5 = exit checker data pointer

Exit data: variable-length list terminated by 0xFF.
  Type 0x9X entries: [type, ?, X, Y, next_room_id]
NPC data:  7-byte entries terminated by 0xFF.

Usage:
  python -m tools.dump_map_table
  python -m tools.dump_map_table --map-type 0   (single map type)
  python -m tools.dump_map_table --verbose       (show raw hex)
"""

import argparse
import json
from pathlib import Path

# ── Inline ROM helpers (no dependency on dwm.rom for portability) ─────

BANK_SIZE = 0x4000
BANK = 0x0B
TABLE_LOCAL = 0x4B43  # bank-local address of map type pointer table

# Known RAM counter addresses → human labels (from known_RAM_map.md)
RAM_LABELS = {
    0xD8D4: "next_step_or_next_room_id",
    0xD988: "labyrinth_step",
    0xD997: "unused_gate_step",
    0xD999: "arena_battle_starry",
    0xD9CD: "coliseum_or_arena_battle",
    0xD9E9: "multi_step_screen",
    0xC925: "current_room_index",
}

# Known map type IDs → names (from known_NOTES.md)
MAP_TYPE_NAMES = {
    0x00: "Castle",
    0x01: "GreatTree Overworld",
    0x02: "Bazaar",
    0x03: "Gate Hub",
    0x04: "Farm (top of GreatTree)",
    0x05: "Stable",
    0x06: "Arena Lobby",
    0x07: "Arena Rooms",
    0x08: "Gate tileset",
    0x09: "Starry Shrine",
    0x0A: "Secret Passage (Throne→MedalMan)",
    0x0C: "Gate tileset",
    0x0D: "Old Man Gate Room",
    0x10: "Copycat Room",
    0x12: "Library",
    0x16: "MedalMan Room",
    0x18: "Well",
    0x23: "Room of Beginning",
    0x24: "Room of Villager & Talisman",
    0x25: "Room of Memories & Bewilder",
    0x26: "Room of Peace & Bravery",
    0x27: "Room of Strength & Anger",
    0x28: "Room of Joy & Wisdom",
    0x29: "Room of Happiness & Temptation",
    0x2A: "Room of Labyrinth & Judgment",
    0x2B: "Room of Reflection",
    0x2C: "Room of Ambition & Demolition",
    0x2D: "Room of Mastermind & Control",
    0x2E: "Room of Extinction & Sleep",
    0x30: "Boss Room - Gate of Beginning",
    0x31: "Boss Room - Gate of Villager",
    0x32: "Boss Room - Gate of Talisman",
    0x33: "Boss Room - Gate of Memories",
    0x34: "Boss Room - Gate of Bewilder",
    0x36: "Boss Room - Gate of Peace",
    0x37: "Boss Room - Gate of Bravery",
    0x42: "Labyrinth",
    0x46: "Boss Room - Gate of Ambition",
    0x4D: "Boss Room - Arena Right Gate",
    0x4F: "Boss Room - Unused Gate",
    0x52: "Special - Coliseum",
    0x53: "Special - Forest Maze",
    0x54: "Special - Conveyor Belt 1",
    0x55: "Special - Conveyor Belt 2",
    0x56: "Special - Conveyor Belt 3",
    0x57: "Special - Maze 1",
    0x58: "Special - Maze 2",
    0x59: "Special - Maze 3",
    0x5A: "Special - Treasure Chest 1",
    0x5C: "Special - Treasure Chest 3",
    0x5D: "Arena Battle",
    0x60: "Labyrinth Final Room",
}


def flat(bank: int, local: int) -> int:
    """Bank-local address → flat ROM offset."""
    if bank == 0:
        return local
    return bank * BANK_SIZE + (local - 0x4000)


def read_u16(data: bytes, offset: int) -> int:
    """Read little-endian 16-bit value."""
    return data[offset] | (data[offset + 1] << 8)


def is_valid_bank_ptr(ptr: int) -> bool:
    """Check if a pointer is a valid bank-local address ($4000-$7FFF)."""
    return 0x4000 <= ptr <= 0x7FFF


def local_to_flat(ptr: int) -> int:
    """Bank 0B local address → flat ROM offset."""
    return flat(BANK, ptr)


def decode_exit_entries(data: bytes, ptr_local: int, max_entries: int = 32) -> list:
    """Decode exit entries from the exit data pointer.

    Exit data is a variable-length list terminated by 0xFF.
    Type 0x9X entries appear to be: [type, flags, X, Y, next_room_id] (5 bytes)
    Other types have varying formats.
    """
    exits = []
    f = local_to_flat(ptr_local)

    if f < 0 or f >= len(data):
        return exits

    pos = f
    for _ in range(max_entries):
        if pos >= len(data):
            break
        type_byte = data[pos]
        if type_byte == 0xFF:
            break

        entry = {"entry_flat": f"0x{pos:06X}", "type_byte": f"0x{type_byte:02X}"}

        if type_byte & 0x80:
            # Bit 7 set = coordinate-matched exit
            top_nibble = type_byte & 0xF0
            if top_nibble == 0x90 and pos + 4 < len(data):
                # Standard coordinate exit: [type, param, X, Y, next_room_id]
                entry["kind"] = "coord_exit"
                entry["param"] = f"0x{data[pos+1]:02X}"
                entry["x"] = data[pos + 2]
                entry["y"] = data[pos + 3]
                entry["next_room_id"] = data[pos + 4]
                entry["next_room_id_flat"] = f"0x{pos + 4:06X}"  # patchable byte
                entry["raw"] = data[pos:pos + 5].hex(" ")
                exits.append(entry)
                pos += 5
            elif pos + 4 < len(data):
                # Other bit-7-set type
                entry["kind"] = f"exit_type_{top_nibble >> 4:X}X"
                entry["raw"] = data[pos:pos + 5].hex(" ")
                entry["next_room_id"] = data[pos + 4]
                entry["next_room_id_flat"] = f"0x{pos + 4:06X}"
                exits.append(entry)
                pos += 5
            else:
                entry["kind"] = "truncated"
                entry["raw"] = data[pos:min(pos + 5, len(data))].hex(" ")
                exits.append(entry)
                break
        else:
            # Bit 7 clear = different format (possibly warp or script trigger)
            end = min(pos + 8, len(data))
            chunk = data[pos:end]
            entry["kind"] = "non_coord_entry"
            entry["raw"] = chunk.hex(" ")
            exits.append(entry)
            # Without knowing the exact length, advance conservatively
            # Look for next valid-looking type byte or 0xFF
            pos += 1
            while pos < len(data) and pos < f + 256:
                b = data[pos]
                if b == 0xFF or (b & 0x80):
                    break
                pos += 1

    return exits


def decode_npc_entries(data: bytes, ptr_local: int, max_entries: int = 32) -> list:
    """Decode NPC/interaction entries (7 bytes each, terminated by 0xFF)."""
    npcs = []
    f = local_to_flat(ptr_local)

    if f < 0 or f >= len(data):
        return npcs

    pos = f
    for _ in range(max_entries):
        if pos + 6 >= len(data):
            break
        first_byte = data[pos]
        if first_byte == 0xFF:
            break

        entry = {
            "flat": f"0x{pos:06X}",
            "raw": data[pos:pos + 7].hex(" "),
            "npc_type": f"0x{first_byte:02X}",
            "byte1": f"0x{data[pos+1]:02X}",
            "x": data[pos + 2],
            "y": data[pos + 3],
            "bytes_4_5_6": data[pos + 4:pos + 7].hex(" "),
        }
        npcs.append(entry)
        pos += 7

    return npcs


def decode_step_entries(data: bytes, room_data_flat: int, max_steps: int = 16) -> list:
    """Decode 6-byte step entries from room data (starting after the 2-byte RAM ptr)."""
    steps = []
    base = room_data_flat + 2  # skip the RAM counter pointer

    for step in range(max_steps):
        entry_flat = base + step * 6
        if entry_flat + 5 >= len(data):
            break

        bytes_01 = read_u16(data, entry_flat)
        interact_ptr = read_u16(data, entry_flat + 2)
        exit_ptr = read_u16(data, entry_flat + 4)

        # Validate: interact_ptr and exit_ptr should be valid bank-local addresses
        if not is_valid_bank_ptr(interact_ptr) or not is_valid_bank_ptr(exit_ptr):
            break

        entry = {
            "step": step,
            "flat": f"0x{entry_flat:06X}",
            "bytes_0_1": f"0x{bytes_01:04X}",
            "interact_ptr": f"0x{interact_ptr:04X}",
            "interact_ptr_flat": f"0x{local_to_flat(interact_ptr):06X}",
            "exit_ptr": f"0x{exit_ptr:04X}",
            "exit_ptr_flat": f"0x{local_to_flat(exit_ptr):06X}",
        }

        # Decode exits
        entry["interact_data"] = decode_exit_entries(data, interact_ptr)

        # Decode NPCs
        entry["exit_data"] = decode_npc_entries(data, exit_ptr)

        steps.append(entry)

    return steps


def dump_map_type(data: bytes, map_type: int, verbose: bool = False) -> dict | None:
    """Decode a single map type's room data."""
    table_flat = local_to_flat(TABLE_LOCAL)

    # Read the map type's sub-table pointer
    ptr_offset = table_flat + map_type * 2
    if ptr_offset + 1 >= len(data):
        return None

    sub_table_ptr = read_u16(data, ptr_offset)
    if not is_valid_bank_ptr(sub_table_ptr):
        return None

    result = {
        "map_type": map_type,
        "map_type_hex": f"0x{map_type:02X}",
        "name": MAP_TYPE_NAMES.get(map_type, ""),
        "sub_table_ptr": f"0x{sub_table_ptr:04X}",
        "sub_table_flat": f"0x{local_to_flat(sub_table_ptr):06X}",
        "sub_rooms": [],
    }

    # Determine how many sub-rooms by reading pointers until invalid
    sub_flat = local_to_flat(sub_table_ptr)
    for c925 in range(32):  # reasonable max
        room_ptr_offset = sub_flat + c925 * 2
        if room_ptr_offset + 1 >= len(data):
            break

        room_data_ptr = read_u16(data, room_ptr_offset)
        if not is_valid_bank_ptr(room_data_ptr):
            break

        room_flat = local_to_flat(room_data_ptr)
        if room_flat + 1 >= len(data):
            break

        # Read the RAM counter pointer (first 2 bytes of room data)
        ram_counter = read_u16(data, room_flat)

        # Sanity check: RAM counter should be in WRAM range
        if not (0xC000 <= ram_counter <= 0xDFFF):
            break

        ram_label = RAM_LABELS.get(ram_counter, "")

        sub_room = {
            "c925": c925,
            "room_data_ptr": f"0x{room_data_ptr:04X}",
            "room_data_flat": f"0x{room_flat:06X}",
            "ram_counter": f"0x{ram_counter:04X}",
            "ram_label": ram_label,
        }

        # Decode step entries
        sub_room["steps"] = decode_step_entries(data, room_flat)

        if verbose:
            # Dump raw bytes of the room data header + first few step entries
            raw_len = min(2 + len(sub_room["steps"]) * 6, 128)
            sub_room["raw_header"] = data[room_flat:room_flat + raw_len].hex(" ")

        result["sub_rooms"].append(sub_room)

    return result


def print_summary(result: dict, verbose: bool = False):
    """Print human-readable summary of a map type."""
    mt = result["map_type"]
    name = result["name"] or "?"
    n_rooms = len(result["sub_rooms"])
    print(f"\n{'='*70}")
    print(f"Map Type 0x{mt:02X} ({mt:3d})  {name}")
    print(f"  Sub-table ptr: {result['sub_table_ptr']} (flat {result['sub_table_flat']})")
    print(f"  Sub-rooms: {n_rooms}")

    for sr in result["sub_rooms"]:
        c925 = sr["c925"]
        ram = sr["ram_counter"]
        ram_l = sr["ram_label"]
        n_steps = len(sr["steps"])
        label = f"  ({ram_l})" if ram_l else ""
        print(f"\n  [C925={c925}] room_data={sr['room_data_ptr']}  "
              f"RAM={ram}{label}  steps={n_steps}")

        if verbose and "raw_header" in sr:
            print(f"    raw: {sr['raw_header']}")

        for step in sr["steps"]:
            n_interact = len(step["interact_data"])
            n_exits = len(step["exit_data"])
            print(f"    step {step['step']}: "
                  f"bytes01={step['bytes_0_1']}  "
                  f"interact@{step['interact_ptr']}({n_interact})  "
                  f"exits@{step['exit_ptr']}({n_interact})")

            for ex in step["interact_data"]:
                kind = ex["kind"]
                if kind == "coord_exit":
                    print(f"      EXIT: ({ex['x']},{ex['y']}) → room {ex['next_room_id']}  "
                          f"patch@{ex.get('next_room_id_flat','')}  [{ex['raw']}]")
                else:
                    nrid = ex.get("next_room_id", "?")
                    print(f"      EXIT ({kind}): next={nrid}  [{ex['raw']}]")

            for npc in step["exit_data"]:
                print(f"      NPC: type={npc['npc_type']} "
                      f"pos=({npc['x']},{npc['y']})  [{npc['raw']}]")


def build_connection_graph(all_results: list) -> dict:
    """Build a graph of room connections from exit data."""
    # Map (map_type, c925, step) → list of destination room IDs
    connections = {}
    for result in all_results:
        mt = result["map_type"]
        for sr in result["sub_rooms"]:
            c925 = sr["c925"]
            for step in sr["steps"]:
                key = f"0x{mt:02X}:c925={c925}:step={step['step']}"
                dests = []
                for ex in step["interact_data"]:
                    nrid = ex.get("next_room_id")
                    if nrid is not None and nrid != 0xFF:
                        dests.append({
                            "next_room_id": nrid,
                            "kind": ex["kind"],
                            "x": ex.get("x"),
                            "y": ex.get("y"),
                            "next_room_id_flat": ex.get("next_room_id_flat", ""),
                        })
                if dests:
                    connections[key] = dests
    return connections


def main():
    ap = argparse.ArgumentParser(description="Dump DWM1 map pointer table from Bank 0B")
    ap.add_argument("--rom", default="data/DWM-original.gbc", help="ROM path")
    ap.add_argument("--map-type", type=lambda x: int(x, 0), default=None,
                    help="Dump a single map type (hex or decimal)")
    ap.add_argument("--verbose", "-v", action="store_true",
                    help="Show raw hex bytes")
    ap.add_argument("--json-only", action="store_true",
                    help="Output JSON only (no summary text)")
    args = ap.parse_args()

    rom_path = Path(args.rom)
    if not rom_path.exists():
        print(f"ROM not found: {rom_path}")
        print("Place your DWM-original.gbc in data/ or use --rom PATH")
        return

    data = rom_path.read_bytes()
    print(f"ROM loaded: {len(data)} bytes ({len(data)/1024:.0f} KB)")

    # Determine which map types to dump
    if args.map_type is not None:
        map_types = [args.map_type]
    else:
        # Scan all possible map types (0x00-0x64 based on known_NOTES.md)
        map_types = list(range(0x65))

    all_results = []
    for mt in map_types:
        result = dump_map_type(data, mt, verbose=args.verbose)
        if result and result["sub_rooms"]:
            all_results.append(result)

    if not args.json_only:
        # Print table summary first
        print(f"\n{'='*70}")
        print(f"MAP TYPE POINTER TABLE @ $0B:$4B43 (flat 0x{local_to_flat(TABLE_LOCAL):06X})")
        print(f"{'='*70}")

        # Show pointer table entries
        table_flat = local_to_flat(TABLE_LOCAL)
        print(f"\n  {'Type':>6}  {'Ptr':>6}  {'Flat':>8}  {'Name'}")
        print(f"  {'----':>6}  {'---':>6}  {'----':>8}  {'----'}")
        seen_ptrs = {}
        for mt in range(0x65):
            ptr_off = table_flat + mt * 2
            if ptr_off + 1 >= len(data):
                break
            ptr = read_u16(data, ptr_off)
            name = MAP_TYPE_NAMES.get(mt, "")
            shared = ""
            if ptr in seen_ptrs:
                shared = f"  (same as 0x{seen_ptrs[ptr]:02X})"
            else:
                seen_ptrs[ptr] = mt
            if is_valid_bank_ptr(ptr):
                print(f"  0x{mt:02X}    0x{ptr:04X}  0x{local_to_flat(ptr):06X}  {name}{shared}")

        # Print detailed room info
        for result in all_results:
            print_summary(result, verbose=args.verbose)

        # Print connection summary
        conns = build_connection_graph(all_results)
        if conns:
            print(f"\n{'='*70}")
            print(f"ROOM CONNECTION GRAPH ({len(conns)} rooms with exits)")
            print(f"{'='*70}")
            for key in sorted(conns.keys()):
                dests = conns[key]
                dest_str = ", ".join(
                    f"({d.get('x','?')},{d.get('y','?')})→room {d['next_room_id']} @{d.get('next_room_id_flat','?')}"
                    for d in dests
                )
                print(f"  {key}: {dest_str}")

        # Stats
        total_rooms = sum(len(r["sub_rooms"]) for r in all_results)
        total_steps = sum(
            len(sr["steps"])
            for r in all_results for sr in r["sub_rooms"]
        )
        total_exits = sum(
            len(step["interact_data"])
            for r in all_results for sr in r["sub_rooms"]
            for step in sr["steps"]
        )
        total_npcs = sum(
            len(step["exit_data"])
            for r in all_results for sr in r["sub_rooms"]
            for step in sr["steps"]
        )
        print(f"\n{'='*70}")
        print(f"TOTALS")
        print(f"  Map types decoded:  {len(all_results)}")
        print(f"  Total sub-rooms:    {total_rooms}")
        print(f"  Total step entries: {total_steps}")
        print(f"  Total exits:        {total_exits}")
        print(f"  Total NPCs:         {total_npcs}")

    # Save JSON
    out_dir = Path("extracted")
    out_dir.mkdir(exist_ok=True)

    # Full structured dump
    out_path = out_dir / "map_table.json"
    out_path.write_text(json.dumps(all_results, indent=2))
    print(f"\nSaved {out_path} ({len(all_results)} map types)")

    # Connection graph
    conns = build_connection_graph(all_results)
    conn_path = out_dir / "room_connections.json"
    conn_path.write_text(json.dumps(conns, indent=2))
    print(f"Saved {conn_path} ({len(conns)} connected rooms)")

    # Editable exit summary — flat offsets for raw_bytes patching
    exit_summary = []
    for result in all_results:
        mt = result["map_type"]
        for sr in result["sub_rooms"]:
            for step in sr["steps"]:
                for ex in step["interact_data"]:
                    nrid = ex.get("next_room_id")
                    if nrid is not None:
                        exit_summary.append({
                            "map_type": f"0x{mt:02X}",
                            "map_name": result["name"],
                            "c925": sr["c925"],
                            "step": step["step"],
                            "kind": ex["kind"],
                            "x": ex.get("x"),
                            "y": ex.get("y"),
                            "next_room_id": nrid,
                            "next_room_id_flat": ex.get("next_room_id_flat", ""),
                            "raw": ex.get("raw", ""),
                        })

    exit_path = out_dir / "exit_table.json"
    exit_path.write_text(json.dumps(exit_summary, indent=2))
    print(f"Saved {exit_path} ({len(exit_summary)} exits)")


if __name__ == "__main__":
    main()
