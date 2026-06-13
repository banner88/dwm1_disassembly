"""Decode the Bank 0B map pointer table and dump room connection data.

Traces the pointer chain:
  $0B:$4B43 + map_type×2  →  sub_table_ptr
  sub_table_ptr + C925×2  →  room_data_ptr
  room_data_ptr:
    +0,+1  = RAM counter address (identifies room type)
    +2...  = array of 6-byte step entries:
               +0,+1 = unknown (possibly tilemap/config pointer)
               +2,+3 = interact/NPC block ptr (5-byte entries), +4,+5 = exit checker ptr (7-byte entries)
               +4,+5 = exit checker data pointer

Exit data: variable-length list terminated by 0xFF.
  Interact block: 5-byte entries (NPCs + spawn/walk-on markers).
Exit checker block: 7-byte entries (trigger, dest map_type, screen, spawn).

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
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dwm.map_names import MAP_TYPE_NAMES  # canonical room names (97 entries)


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


def decode_interact_entries(data: bytes, ptr_local: int, max_entries: int = 32) -> list:
    """Decode the INTERACT block (step entry bytes +2,+3).

    5-byte entries, terminated by 0xFF as the FIRST byte of an entry only
    (internal bytes may be 0xFF). Two entry classes by bit 7 of byte 0
    (ROOM_DATA_FORMAT.md, SameBoy-verified):

      bit7 SET  — spawn/exit markers: [type, param, x, y, map_type]
                  type 0x8F = spawn point, 0x90 = walk-on exit marker
      bit7 CLEAR — NPC: [type_facing, sprite_id, x, y, script_id]
                  facing in bits 4-5 of byte 0 (0=down,1=left,2=up,3=right)
    """
    entries = []
    f = local_to_flat(ptr_local)
    if f < 0 or f >= len(data):
        return entries
    pos = f
    for _ in range(max_entries):
        if pos + 4 >= len(data):
            break
        b0 = data[pos]
        if b0 == 0xFF:
            break
        raw = data[pos:pos + 5]
        entry = {"entry_flat": f"0x{pos:06X}", "raw": raw.hex(" ")}
        if b0 & 0x80:
            entry["kind"] = {0x8F: "spawn_point", 0x90: "walkon_exit"}.get(b0, f"marker_{b0:02X}")
            entry["type"] = f"0x{b0:02X}"
            entry["param"] = f"0x{raw[1]:02X}"
            entry["x"] = raw[2]
            entry["y"] = raw[3]
            entry["map_type"] = raw[4]
        else:
            entry["kind"] = "npc"
            entry["npc_type"] = f"0x{b0 & 0xCF:02X}"
            entry["facing"] = ["down", "left", "up", "right"][(b0 >> 4) & 3]
            entry["sprite_id"] = raw[1]
            entry["x"] = raw[2]
            entry["y"] = raw[3]
            entry["script_id"] = raw[4]
        entries.append(entry)
        pos += 5
    return entries


def decode_exit_checker_entries(data: bytes, ptr_local: int, max_entries: int = 32) -> list:
    """Decode the EXIT CHECKER block (step entry bytes +4,+5).

    7-byte entries, 0xFF-terminated (first byte of entry only). Read by
    RoomEntry6 every step (ROOM_DATA_FORMAT.md):
      [trigger_x, trigger_y, dest_map_type, gate_flag,
       screen_byte (low nibble=spawn screen, bit7=Y+8), spawn_x, spawn_y]
    byte0 == 0x00 (arrival point) and 0x09 (special) are skipped by the
    engine but still occupy 7 bytes.
    """
    entries = []
    f = local_to_flat(ptr_local)
    if f < 0 or f >= len(data):
        return entries
    pos = f
    for _ in range(max_entries):
        if pos + 6 >= len(data):
            break
        b0 = data[pos]
        if b0 == 0xFF:
            break
        raw = data[pos:pos + 7]
        entries.append({
            "entry_flat": f"0x{pos:06X}",
            "raw": raw.hex(" "),
            "kind": {0x00: "arrival_point", 0x09: "special_marker"}.get(b0, "walkon_exit"),
            "trigger_x": raw[0],
            "trigger_y": raw[1],
            "dest_map_type": raw[2],
            "gate_flag": raw[3],
            "screen_byte": f"0x{raw[4]:02X}",
            "spawn_x": raw[5],
            "spawn_y": raw[6],
            "dest_map_type_flat": f"0x{pos + 2:06X}",
        })
        pos += 7
    return entries


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
        entry["interact_data"] = decode_interact_entries(data, interact_ptr)

        # Decode NPCs
        entry["exit_data"] = decode_exit_checker_entries(data, exit_ptr)

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

    # Sub-table size (ROOM_DATA_FORMAT.md): the slot region extends from
    # sub_table_ptr up to the LOWEST room_data pointer it contains ("the gap").
    # $FFFF slots are HOLES (unused screens) — skip them, never stop on them.
    # The old version broke at the first $FFFF and silently dropped screens
    # (e.g. GreatTree screens 4+ behind holes at slots 2-3).
    sub_flat = local_to_flat(sub_table_ptr)
    min_target = float("inf")          # lowest valid room_data ptr seen
    c925 = -1
    while True:
        c925 += 1
        if c925 >= 64:                  # hard cap (LabyrinthFinal uses 32)
            break
        # Stop when the slot cursor reaches the start of room data (the gap)
        if c925 > 0 and sub_table_ptr + c925 * 2 >= min_target:
            break
        room_ptr_offset = sub_flat + c925 * 2
        if room_ptr_offset + 1 >= len(data):
            break

        room_data_ptr = read_u16(data, room_ptr_offset)
        if room_data_ptr == 0xFFFF:
            continue                     # hole — unused screen position
        if not is_valid_bank_ptr(room_data_ptr):
            break                        # left the table entirely

        if room_data_ptr >= sub_table_ptr:
            min_target = min(min_target, room_data_ptr)

        room_flat = local_to_flat(room_data_ptr)
        if room_flat + 1 >= len(data):
            break

        # Read the RAM counter pointer (first 2 bytes of room data)
        ram_counter = read_u16(data, room_flat)

        # Sanity check: RAM counter should be in WRAM range
        if not (0xC000 <= ram_counter <= 0xDFFF):
            continue                     # garbage slot — skip, don't truncate

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
                  f"exits@{step['exit_ptr']}({n_exits})")

            for it in step["interact_data"]:
                if it["kind"] == "npc":
                    print(f"      NPC: type={it['npc_type']} {it['facing']:<5} "
                          f"sprite={it['sprite_id']} pos=({it['x']},{it['y']}) "
                          f"script={it['script_id']}  [{it['raw']}]")
                else:
                    print(f"      {it['kind'].upper()}: pos=({it['x']},{it['y']}) "
                          f"map_type={it['map_type']}  [{it['raw']}]")

            for ex in step["exit_data"]:
                print(f"      EXITCHK ({ex['kind']}): trig=({ex['trigger_x']},{ex['trigger_y']}) "
                      f"→ mt=0x{ex['dest_map_type']:02X} screen={ex['screen_byte']} "
                      f"spawn=({ex['spawn_x']},{ex['spawn_y']})  patch@{ex['dest_map_type_flat']}")


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
                # Real transitions come from the EXIT CHECKER block
                for ex in step["exit_data"]:
                    if ex["kind"] != "walkon_exit":
                        continue
                    dests.append({
                        "dest_map_type": ex["dest_map_type"],
                        "kind": "exit_checker",
                        "trigger_x": ex["trigger_x"],
                        "trigger_y": ex["trigger_y"],
                        "screen_byte": ex["screen_byte"],
                        "spawn_x": ex["spawn_x"],
                        "spawn_y": ex["spawn_y"],
                        "dest_map_type_flat": ex["dest_map_type_flat"],
                    })
                # Walk-on markers in the interact block also carry a map_type
                for it in step["interact_data"]:
                    if it["kind"] == "walkon_exit":
                        dests.append({
                            "dest_map_type": it["map_type"],
                            "kind": "interact_marker",
                            "x": it["x"], "y": it["y"],
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
                    f"→mt=0x{d['dest_map_type']:02X} ({d['kind']})"
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
            len(step["exit_data"])
            for r in all_results for sr in r["sub_rooms"]
            for step in sr["steps"]
        )
        total_npcs = sum(
            sum(1 for it in step["interact_data"] if it["kind"] == "npc")
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
                for ex in step["exit_data"]:
                    if ex["kind"] != "walkon_exit":
                        continue
                    exit_summary.append({
                        "map_type": f"0x{mt:02X}",
                        "map_name": result["name"],
                        "c925": sr["c925"],
                        "step": step["step"],
                        "trigger_x": ex["trigger_x"],
                        "trigger_y": ex["trigger_y"],
                        "dest_map_type": ex["dest_map_type"],
                        "gate_flag": ex["gate_flag"],
                        "screen_byte": ex["screen_byte"],
                        "spawn_x": ex["spawn_x"],
                        "spawn_y": ex["spawn_y"],
                        "dest_map_type_flat": ex["dest_map_type_flat"],
                        "raw": ex["raw"],
                    })

    exit_path = out_dir / "exit_table.json"
    exit_path.write_text(json.dumps(exit_summary, indent=2))
    print(f"Saved {exit_path} ({len(exit_summary)} exits)")


if __name__ == "__main__":
    main()
