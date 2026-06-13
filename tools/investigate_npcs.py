"""Investigate NPC spawn data by parsing the map pointer table.

Starting point: Bank 0B, $4B43 (flat 0x2CB43) — the map pointer table.
Each map_type should have an entry pointing to room data within Bank 0B.

Usage:
    uv run python -m tools.investigate_npcs
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dwm.rom import ROM, BANK_SIZE
from dwm.map_names import MAP_NAMES  # canonical room names (97 entries)

# Map pointer table location
MAP_PTR_BANK = 0x0B
MAP_PTR_ADDR = 0x4B43
MAP_PTR_FLAT = MAP_PTR_BANK * BANK_SIZE + (MAP_PTR_ADDR - 0x4000)

# Room loading table (8 bytes per map_type, Bank 0, $26DD)
ROOM_LOAD_TABLE = 0x26DD


def flat_0b(addr):
    """Convert Bank 0B local address to flat ROM offset."""
    return MAP_PTR_BANK * BANK_SIZE + (addr - 0x4000)


def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    data = rom.data

    print("=" * 70)
    print("MAP POINTER TABLE — Bank 0B, $4B43")
    print("=" * 70)

    # Step 1: Determine table size
    # Read pointers until we hit something that looks like non-pointer data
    # Pointers should be in range $4000-$7FFF (Bank 0B address space)
    max_map_types = 128  # reasonable upper bound
    pointers = []

    for i in range(max_map_types):
        offset = MAP_PTR_FLAT + i * 2
        lo = data[offset]
        hi = data[offset + 1]
        ptr = lo | (hi << 8)

        # Valid Bank 0B pointer?
        if 0x4000 <= ptr <= 0x7FFF:
            pointers.append((i, ptr))
        else:
            # Could be end of table or different format
            # Record it but flag it
            pointers.append((i, ptr))
            if ptr < 0x4000 or ptr > 0x7FFF:
                # Check if next few are also invalid — probably past end of table
                next_ptr = data[offset + 2] | (data[offset + 3] << 8)
                if next_ptr < 0x4000 or next_ptr > 0x7FFF:
                    break

    print(f"\nFound {len(pointers)} entries in map pointer table\n")

    # Step 2: Dump the pointer table
    print(f"{'MT':>4s}  {'Ptr':>6s}  {'Flat':>8s}  {'Name':<25s}  First 16 bytes of target")
    print("-" * 90)

    for map_type, ptr in pointers:
        name = MAP_NAMES.get(map_type, "")
        if 0x4000 <= ptr <= 0x7FFF:
            flat = flat_0b(ptr)
            target_bytes = data[flat:flat + 16]
            hex_str = " ".join(f"{b:02X}" for b in target_bytes)
            print(f"0x{map_type:02X}  ${ptr:04X}  0x{flat:06X}  {name:<25s}  {hex_str}")
        else:
            print(f"0x{map_type:02X}  ${ptr:04X}  {'N/A':>8s}  {name:<25s}  (invalid pointer)")

    print()

    # Step 3: Analyze room data for a few known rooms
    print("=" * 70)
    print("ROOM DATA ANALYSIS — Known Rooms")
    print("=" * 70)

    # Focus on rooms with known NPC counts
    analysis_rooms = [
        (0x00, "Castle", "King, guards, NPCs"),
        (0x01, "GreatTree", "Many NPCs across screens"),
        (0x02, "Bazaar", "Shop NPCs"),
        (0x12, "Library", "Librarian NPC"),
        (0x16, "MedalMan", "MedalMan NPC"),
        (0x09, "Starry Shrine", "Shrine keeper"),
        (0x1F, "Queen Room", "Queen NPC"),
    ]

    for map_type, name, npcs in analysis_rooms:
        if map_type >= len(pointers):
            continue

        _, ptr = pointers[map_type]
        if not (0x4000 <= ptr <= 0x7FFF):
            continue

        flat = flat_0b(ptr)
        print(f"\n--- Map 0x{map_type:02X}: {name} (known NPCs: {npcs}) ---")
        print(f"    Pointer: ${ptr:04X} → flat 0x{flat:06X}")

        # Dump first 64 bytes of room data
        room_data = data[flat:flat + 64]
        for row in range(4):
            offset = row * 16
            hex_part = " ".join(f"{b:02X}" for b in room_data[offset:offset + 16])
            ascii_part = "".join(
                chr(b) if 32 <= b < 127 else "." for b in room_data[offset:offset + 16]
            )
            print(f"    +{offset:02X}: {hex_part}  {ascii_part}")

        # Look for sub-pointers (2-byte values in $4000-$7FFF range)
        print(f"    Sub-pointers found:")
        for j in range(0, min(32, len(room_data) - 1), 2):
            sub_ptr = room_data[j] | (room_data[j + 1] << 8)
            if 0x4000 <= sub_ptr <= 0x7FFF:
                sub_flat = flat_0b(sub_ptr)
                # Peek at what the sub-pointer points to
                peek = data[sub_flat:sub_flat + 8]
                peek_hex = " ".join(f"{b:02X}" for b in peek)
                print(f"      +{j:02X}: ${sub_ptr:04X} → flat 0x{sub_flat:06X}  [{peek_hex}]")

    # Step 4: Room loading table at $26DD (Bank 0, 8 bytes per map_type)
    print()
    print("=" * 70)
    print("ROOM LOADING TABLE — Bank 0, $26DD (8 bytes per map_type)")
    print("=" * 70)
    print(f"\n{'MT':>4s}  {'Name':<25s}  8 bytes (tileset ptr, spawn pos)")
    print("-" * 70)

    for map_type in range(min(40, max_map_types)):
        name = MAP_NAMES.get(map_type, "")
        offset = ROOM_LOAD_TABLE + map_type * 8
        entry = data[offset:offset + 8]
        hex_str = " ".join(f"{b:02X}" for b in entry)
        print(f"0x{map_type:02X}  {name:<25s}  {hex_str}")

    # Step 5: Look for NPC-like patterns
    # NPCs typically have: X coord, Y coord, sprite ID, direction, script pointer
    # Search room data for small coordinate-like values followed by sprite IDs
    print()
    print("=" * 70)
    print("NPC PATTERN SEARCH")
    print("=" * 70)
    print("Looking for repeating patterns of (sprite_id, x, y, ...) in room data...")

    for map_type, name, npcs in analysis_rooms[:3]:
        if map_type >= len(pointers):
            continue
        _, ptr = pointers[map_type]
        if not (0x4000 <= ptr <= 0x7FFF):
            continue

        flat = flat_0b(ptr)
        # Dump more room data (256 bytes) and look for patterns
        room_data = data[flat:flat + 256]

        print(f"\n  Map 0x{map_type:02X} ({name}):")

        # Look for sequences of small values that could be NPC spawn entries
        # Typical NPC entry might be: [sprite_id] [x] [y] [direction] [script_ptr_lo] [script_ptr_hi]
        # X/Y coords in DWM rooms are typically 0x00-0x0A
        # Sprite IDs might be small (0x01-0x20 range)

        # Find runs of bytes where multiple consecutive groups have plausible coord values
        for start in range(0, len(room_data) - 12):
            # Check for a few consecutive potential NPC entries at various strides
            for stride in [4, 5, 6, 7, 8]:
                valid = 0
                for k in range(4):  # check 4 consecutive entries
                    base = start + k * stride
                    if base + stride > len(room_data):
                        break
                    # Heuristic: at least 2 bytes in 0x00-0x0A range (coords)
                    small_bytes = sum(1 for b in room_data[base:base + stride] if b <= 0x0A)
                    if small_bytes >= 2:
                        valid += 1
                if valid >= 3:
                    entries_hex = " | ".join(
                        " ".join(f"{room_data[start + k * stride + j]:02X}"
                                 for j in range(stride)
                                 if start + k * stride + j < len(room_data))
                        for k in range(4)
                    )
                    print(f"    +0x{start:02X} stride={stride}: {entries_hex}")
                    break  # only report first stride match at this offset

    print()
    print("=" * 70)
    print("NEXT STEPS")
    print("=" * 70)
    print("""
1. Look at the room data dumps above. The map pointer table entries should
   point to "room headers" that contain sub-pointers to:
   - Tilemap data (wall/floor layout)
   - Collision map
   - NPC spawn table
   - Exit/interaction data (we already know some of this from routing)

2. Compare Castle (many NPCs) vs Library (1 NPC) to spot the NPC count
   and NPC data pointer in the room header.

3. Use SameBoy to trace NPC loading:
   breakpoint $0B:$4088    (room loading)
   Enter Castle, step through the code to find where NPC data is read.

4. Or use: watch/w $C900 to $C93F
   (if NPCs are stored near the map_type at $C968, their data might be nearby)
""")


if __name__ == "__main__":
    main()
