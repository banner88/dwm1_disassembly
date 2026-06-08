"""Dump the room transition routing table found at $41BA in banks 0C-0F.

The game uses a two-level lookup:
  1. master_table[$41BA + index × 2] → sub_table_ptr
  2. sub_table[room_id × 2] → destination_data_ptr
  3. destination_data contains: new_map_type, new_C925, spawn info, etc.

This script dumps both levels and tries to decode the destination data.

Usage:
  python -m tools.dump_routing_table
  python -m tools.dump_routing_table --bank 0C   (specific bank)
  python -m tools.dump_routing_table --verbose    (show raw hex)
"""

import argparse
import json
from pathlib import Path

BANK_SIZE = 0x4000
TABLE_LOCAL = 0x41BA  # bank-local address of master routing table

# Map type names for annotation
MAP_TYPE_NAMES = {
    0x00: "Castle", 0x01: "GreatTree", 0x02: "Bazaar", 0x03: "Gate Hub",
    0x04: "Farm", 0x05: "Stable", 0x06: "Arena Lobby", 0x07: "Arena Rooms",
    0x08: "Gate tileset", 0x09: "Starry Shrine", 0x0A: "Secret Passage",
    0x0C: "Gate tileset 2", 0x0D: "Old Man Gate", 0x10: "Copycat Room",
    0x12: "Library", 0x16: "MedalMan Room", 0x18: "Well",
    0x42: "Labyrinth", 0x5D: "Arena Battle",
}


def flat(bank: int, local: int) -> int:
    if bank == 0:
        return local
    return bank * BANK_SIZE + (local - 0x4000)


def read_u16(data: bytes, offset: int) -> int:
    return data[offset] | (data[offset + 1] << 8)


def is_valid_ptr(ptr: int) -> bool:
    return 0x4000 <= ptr <= 0x7FFF


def dump_routing_table(data: bytes, bank: int, verbose: bool = False):
    """Dump the routing table in the specified bank."""
    bank_base = bank * BANK_SIZE
    table_flat = flat(bank, TABLE_LOCAL)

    print(f"\n{'='*70}")
    print(f"ROUTING TABLE @ bank {bank:02X}:${TABLE_LOCAL:04X} (flat 0x{table_flat:06X})")
    print(f"{'='*70}")

    # First, figure out how many entries the master table has.
    # Read pointers until they look invalid.
    master_entries = []
    for i in range(256):  # generous upper bound
        ptr_flat = table_flat + i * 2
        if ptr_flat + 1 >= len(data):
            break
        ptr = read_u16(data, ptr_flat)
        if not is_valid_ptr(ptr):
            # Could be end of table, or could be a zero/padding entry
            # Check if it's obviously invalid
            if ptr == 0x0000 or ptr == 0xFFFF:
                master_entries.append((i, ptr, False))
                continue
            break
        master_entries.append((i, ptr, True))

    # Find where the first sub-table starts to bound the master table
    first_sub = min((ptr for _, ptr, valid in master_entries if valid), default=0x7FFF)
    # The master table can't extend past the first sub-table
    max_entries = (first_sub - TABLE_LOCAL) // 2
    master_entries = master_entries[:max_entries]

    print(f"\n  Master table: {len(master_entries)} entries "
          f"(table ends before first sub-table @ 0x{first_sub:04X})")

    # Group entries that share the same sub-table pointer
    ptr_to_indices = {}
    for idx, ptr, valid in master_entries:
        if valid:
            ptr_to_indices.setdefault(ptr, []).append(idx)

    # Print master table
    print(f"\n  {'Index':>5}  {'Ptr':>6}  {'Flat':>8}  {'Map Type Name'}")
    print(f"  {'-----':>5}  {'---':>6}  {'----':>8}  {'-------------'}")
    seen_ptrs = {}
    for idx, ptr, valid in master_entries:
        if not valid:
            print(f"  {idx:5d}  0x{ptr:04X}  {'':>8}  (invalid)")
            continue
        name = MAP_TYPE_NAMES.get(idx, "")
        shared = ""
        if ptr in seen_ptrs:
            shared = f"  (same sub-table as index {seen_ptrs[ptr]})"
        else:
            seen_ptrs[ptr] = idx
        sub_flat = flat(bank, ptr)
        print(f"  {idx:5d}  0x{ptr:04X}  0x{sub_flat:06X}  {name}{shared}")

    # Now dump each unique sub-table
    unique_ptrs = sorted(set(ptr for _, ptr, valid in master_entries if valid))
    all_destinations = []

    for sub_ptr in unique_ptrs:
        sub_flat = flat(bank, sub_ptr)
        indices_using = ptr_to_indices[sub_ptr]
        indices_str = ", ".join(f"{i}" for i in indices_using[:5])
        if len(indices_using) > 5:
            indices_str += f"... ({len(indices_using)} total)"

        print(f"\n  {'─'*60}")
        print(f"  Sub-table @ 0x{sub_ptr:04X} (flat 0x{sub_flat:06X})")
        print(f"  Used by master indices: {indices_str}")

        # Read sub-table entries (room_id → destination pointer)
        # Figure out how many entries by reading until invalid pointer
        sub_entries = []
        for room_id in range(128):  # reasonable max
            entry_flat = sub_flat + room_id * 2
            if entry_flat + 1 >= len(data):
                break
            dest_ptr = read_u16(data, entry_flat)
            if not is_valid_ptr(dest_ptr):
                break
            sub_entries.append((room_id, dest_ptr))

        if not sub_entries:
            print(f"    (empty or invalid)")
            continue

        print(f"    {len(sub_entries)} room_id entries:")
        print(f"    {'RoomID':>6}  {'DestPtr':>7}  {'DestFlat':>8}  {'Destination Data'}")

        for room_id, dest_ptr in sub_entries:
            dest_flat = flat(bank, dest_ptr)
            # Read destination data (try to decode)
            if dest_flat + 8 <= len(data):
                dest_data = data[dest_flat:dest_flat + 12]
                # Try to interpret: first bytes might be map_type, C925, spawn coords
                dest_hex = dest_data.hex(' ')

                # Heuristic: byte 0 might be map_type, byte 1 might be C925
                # or it could be a more complex structure
                b0 = dest_data[0]
                b1 = dest_data[1]
                b2 = dest_data[2]
                b3 = dest_data[3]

                annotation = ""
                # Check if b0 looks like a known map_type
                if b0 in MAP_TYPE_NAMES:
                    annotation = f"  → {MAP_TYPE_NAMES[b0]}?"

                dest_info = {
                    "master_indices": indices_using,
                    "room_id": room_id,
                    "dest_ptr": f"0x{dest_ptr:04X}",
                    "dest_flat": f"0x{dest_flat:06X}",
                    "raw_bytes": dest_hex[:23],  # first 8 bytes
                    "byte0": b0,
                    "byte1": b1,
                    "byte2": b2,
                    "byte3": b3,
                }
                all_destinations.append(dest_info)

                print(f"    {room_id:6d}  0x{dest_ptr:04X}  0x{dest_flat:06X}  "
                      f"[{dest_hex[:23]}]{annotation}")
            else:
                print(f"    {room_id:6d}  0x{dest_ptr:04X}  0x{dest_flat:06X}  (out of range)")

    return all_destinations


def analyze_destinations(destinations: list):
    """Try to figure out the destination data format."""
    print(f"\n{'='*70}")
    print(f"DESTINATION DATA ANALYSIS")
    print(f"{'='*70}")

    if not destinations:
        print("  No destinations to analyze.")
        return

    # Look at byte 0 distribution (might be map_type)
    b0_counts = {}
    for d in destinations:
        b0 = d["byte0"]
        b0_counts[b0] = b0_counts.get(b0, 0) + 1

    print(f"\n  Byte 0 distribution (top 20, might be map_type):")
    for val, count in sorted(b0_counts.items(), key=lambda x: -x[1])[:20]:
        name = MAP_TYPE_NAMES.get(val, "")
        print(f"    0x{val:02X} ({val:3d}): {count:3d} occurrences  {name}")

    # Look at byte 1 distribution (might be C925 or flags)
    b1_counts = {}
    for d in destinations:
        b1 = d["byte1"]
        b1_counts[b1] = b1_counts.get(b1, 0) + 1

    print(f"\n  Byte 1 distribution (top 20, might be C925):")
    for val, count in sorted(b1_counts.items(), key=lambda x: -x[1])[:20]:
        print(f"    0x{val:02X} ({val:3d}): {count:3d} occurrences")

    # Show some specific known transitions for validation
    print(f"\n  Known transition examples to validate format:")
    # Castle room_ids go to castle sub-rooms
    castle_dests = [d for d in destinations if 0 in d["master_indices"]]
    if castle_dests:
        print(f"\n    Castle (master index 0) destinations:")
        for d in castle_dests[:12]:
            print(f"      room_id {d['room_id']:2d} → [{d['raw_bytes']}]")

    # GreatTree room_ids
    gt_dests = [d for d in destinations if 1 in d["master_indices"]]
    if gt_dests:
        print(f"\n    GreatTree (master index 1) destinations:")
        for d in gt_dests[:12]:
            print(f"      room_id {d['room_id']:2d} → [{d['raw_bytes']}]")

    # Farm room_ids (has room 41 and 42 which we know exist)
    farm_dests = [d for d in destinations if 4 in d["master_indices"]]
    if farm_dests:
        print(f"\n    Farm (master index 4) destinations:")
        for d in farm_dests[:15]:
            print(f"      room_id {d['room_id']:2d} → [{d['raw_bytes']}]")

    # Gate Hub room_ids
    gh_dests = [d for d in destinations if 3 in d["master_indices"]]
    if gh_dests:
        print(f"\n    Gate Hub (master index 3) destinations:")
        for d in gh_dests[:12]:
            print(f"      room_id {d['room_id']:2d} → [{d['raw_bytes']}]")


def main():
    ap = argparse.ArgumentParser(description="Dump DWM1 room routing table")
    ap.add_argument("--rom", default="data/DWM-original.gbc")
    ap.add_argument("--bank", type=lambda x: int(x, 16), default=0x0C,
                    help="Bank to read table from (default: 0C)")
    ap.add_argument("--verbose", "-v", action="store_true")
    ap.add_argument("--all-banks", action="store_true",
                    help="Compare table across banks 0C-0F")
    args = ap.parse_args()

    rom_path = Path(args.rom)
    if not rom_path.exists():
        print(f"ROM not found: {rom_path}")
        return

    data = rom_path.read_bytes()
    print(f"Loaded {rom_path} ({len(data)} bytes)")

    if args.all_banks:
        # Check if tables are identical across banks
        tables = {}
        for b in [0x0C, 0x0D, 0x0E, 0x0F]:
            tbl_flat = flat(b, TABLE_LOCAL)
            # Read 512 bytes of table data for comparison
            tables[b] = data[tbl_flat:tbl_flat + 512]

        print(f"\n  Comparing table data across banks 0C-0F:")
        ref = tables[0x0C]
        for b in [0x0D, 0x0E, 0x0F]:
            if tables[b] == ref:
                print(f"    Bank {b:02X}: identical to 0C")
            else:
                diffs = sum(1 for a, c in zip(ref, tables[b]) if a != c)
                print(f"    Bank {b:02X}: {diffs} bytes differ from 0C")

    destinations = dump_routing_table(data, args.bank, verbose=args.verbose)
    analyze_destinations(destinations)

    # Save results
    out_dir = Path("extracted")
    out_dir.mkdir(exist_ok=True)
    out_path = out_dir / "routing_table.json"
    out_path.write_text(json.dumps(destinations, indent=2))
    print(f"\nSaved {out_path} ({len(destinations)} destination entries)")


if __name__ == "__main__":
    main()
