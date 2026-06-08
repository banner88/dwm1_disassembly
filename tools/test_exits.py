"""Verify exit data in ROM and generate test patches for room re-routing.

Reads the built ROM (or original) and confirms what bytes are at known exit offsets.
Also generates safe test patches to verify the exit system works.

Usage:
  python -m tools.test_exits                    # verify original ROM
  python -m tools.test_exits --rom data/DWM-hacked.gbc  # verify patched ROM
  python -m tools.test_exits --generate-patch castle-swap  # generate a test patch
  python -m tools.test_exits --generate-patch greattree-all  # patch all Library steps
"""

import argparse
import json
from pathlib import Path

BANK_SIZE = 0x4000


def flat(bank: int, local: int) -> int:
    return bank * BANK_SIZE + (local - 0x4000) if bank else local


def read_rom_bytes(data: bytes, offset: int, length: int) -> bytes:
    return data[offset:offset + length]


# ── Known exit locations from dump_map_table output ──────────────

# Castle (0x00) C925=0: ALL steps share exit table at 0x4C95
# Flat base = flat(0x0B, 0x4C95) = 0x02CC95
# Exit entries are 5 bytes each: [type, param, col, row, room_id]
CASTLE_EXIT_TABLE = 0x02CC95
CASTLE_EXITS = [
    # (offset_from_base, description, original_bytes)
    (0,  "Castle door → room 1",  "8f ff 01 01 01"),
    (5,  "Castle door → room 2",  "8f ff 02 01 02"),
    (10, "Castle door → room 3",  "8f ff 03 02 03"),
    (15, "Castle door → room 4",  "8f ff 04 02 04"),
    (20, "Castle door → room 5",  "8f ff 02 07 05"),
    (25, "Castle door → room 6",  "8f ff 03 07 06"),
    (30, "Castle door → room 7",  "8f ff 04 07 07"),
    (35, "Castle door → room 8",  "8f ff 05 07 08"),
    (40, "Castle door → room 19", "8f ff 06 07 13"),
]

# GreatTree (0x01) C925=0: Library exit at (6,6) in steps 2, 3, 4
GREATTREE_LIBRARY_EXITS = [
    # (flat_offset_of_room_id_byte, step, original_value, description)
    (0x02CEF1, 2, 0x12, "GreatTree step 2: Library exit room_id"),
    (0x02CEFC, 3, 0x12, "GreatTree step 3: Library exit room_id"),
    (0x02CF02, 4, 0x12, "GreatTree step 4: Library exit room_id"),
]

# Stable (0x05) C925=1: exits to room 8 (shared across steps 0-1)
STABLE_EXITS = [
    (0x02D8B8, "Stable C925=1 step 0: door → room 8 (byte 3)", 0x08),
    (0x02D8BD, "Stable C925=1 step 0: door → room 8 (byte 4)", 0x08),
    (0x02D8CD, "Stable C925=1 step 1: door → room 8 (byte 3)", 0x08),
    (0x02D8D2, "Stable C925=1 step 1: door → room 8 (byte 4)", 0x08),
]

# Boss Room - Gate of Bewilder (0x34): coord exits
BEWILDER_BOSS_EXITS = [
    (0x02EB7A, "Bewilder boss: (7,1)→room 7", 0x07),
    (0x02EB7F, "Bewilder boss: (4,4)→room 8", 0x08),
    (0x02EB84, "Bewilder boss: (5,5)→room 9", 0x09),
    (0x02EB89, "Bewilder boss: (1,3)→room 10", 0x0A),
]


def verify_exits(data: bytes, rom_name: str):
    """Check known exit bytes in the ROM and report matches/mismatches."""
    print(f"\n{'='*60}")
    print(f"EXIT VERIFICATION: {rom_name}")
    print(f"{'='*60}")

    # Castle exit table
    print(f"\n  Castle exit table @ 0x{CASTLE_EXIT_TABLE:06X}:")
    for off, desc, expected_hex in CASTLE_EXITS:
        addr = CASTLE_EXIT_TABLE + off
        actual = data[addr:addr + 5]
        expected = bytes.fromhex(expected_hex.replace(" ", ""))
        match = "✓" if actual == expected else "✗ MISMATCH"
        print(f"    0x{addr:06X}: {actual.hex(' ')}  {match}  ({desc})")
        if actual != expected:
            print(f"             expected: {expected.hex(' ')}")

    # GreatTree Library exits
    print(f"\n  GreatTree Library exits:")
    for addr, step, expected_val, desc in GREATTREE_LIBRARY_EXITS:
        actual = data[addr]
        match = "✓" if actual == expected_val else f"✗ got 0x{actual:02X}"
        print(f"    0x{addr:06X}: 0x{actual:02X}  {match}  ({desc})")

    # Show context around each GreatTree exit (the full 5-byte entry)
    print(f"\n  GreatTree Library exit context (5 bytes each):")
    for addr, step, _, desc in GREATTREE_LIBRARY_EXITS:
        entry_start = addr - 4  # room_id is byte 4 of the 5-byte entry
        entry = data[entry_start:entry_start + 5]
        # Also show what comes after (next entry or terminator)
        after = data[addr + 1:addr + 9]
        print(f"    step {step}: [{entry.hex(' ')}] followed by [{after.hex(' ')}]")

    # Stable exits
    print(f"\n  Stable exits:")
    for addr, desc, expected_val in STABLE_EXITS:
        actual = data[addr]
        match = "✓" if actual == expected_val else f"✗ got 0x{actual:02X}"
        print(f"    0x{addr:06X}: 0x{actual:02X}  {match}  ({desc})")


def verify_room_id_hypothesis(data: bytes):
    """Check if room_ids could be map_type IDs or something else."""
    print(f"\n{'='*60}")
    print(f"ROOM ID ANALYSIS")
    print(f"{'='*60}")

    # Collect all room_ids from known exits, grouped by source map_type
    # This helps determine if room_ids are local or global
    print(f"\n  Castle (map 0x00) exit room_ids: 1,2,3,4,5,6,7,8,19")
    print(f"    → If global map_types: 01=GreatTree, 02=Bazaar, 03=GateHub...")
    print(f"    → If local: rooms within the Castle area")
    print(f"    → Castle has only 2 C925 sub-rooms, so IDs 1-8 aren't C925 values")

    print(f"\n  GreatTree (map 0x01) exit room_ids: 18")
    print(f"    → 18 decimal = 0x12 = Library map_type (could be coincidence)")

    print(f"\n  Farm (map 0x04) exit room_ids: 2,6,7,16,41,42")
    print(f"    → 41=0x29 (Happiness room?), 42=0x2A (Labyrinth room?) → NO MATCH")
    print(f"    → These are clearly local IDs, not map_types")

    print(f"\n  Gate Hub (map 0x03) exit room_ids: 1,2,3,5,6,7")
    print(f"    → If local: the gate doors within the Chamber")

    print(f"\n  CONCLUSION: room_ids are LOCAL transition IDs, not map_types.")
    print(f"  The game has a separate routing table that maps")
    print(f"  (current_map_type, room_id) → (next_map_type, spawn_position)")
    print(f"  This table is probably in a different bank or in the event system.")


def generate_patch(patch_type: str) -> dict:
    """Generate test patches for edits.json."""
    patches = {}

    if patch_type == "castle-swap":
        # Swap Castle exit to room 1 ↔ room 2
        # These are at offsets 0 and 5 from the exit table base
        # Byte 4 of each 5-byte entry is the room_id
        addr1 = CASTLE_EXIT_TABLE + 4   # room_id for "→ room 1"
        addr2 = CASTLE_EXIT_TABLE + 9   # room_id for "→ room 2"
        patches[f"0x{addr1:05X}"] = "02"  # room 1 → room 2
        patches[f"0x{addr2:05X}"] = "01"  # room 2 → room 1
        print(f"\n  Castle door swap: room 1 ↔ room 2")
        print(f"    0x{addr1:05X}: 01 → 02 (first door now goes to room 2)")
        print(f"    0x{addr2:05X}: 02 → 01 (second door now goes to room 1)")
        print(f"    All 4 Castle steps share this exit table, so one patch covers all.")
        print(f"    TEST: Walk through the first door in the Castle throne room.")
        print(f"          You should end up in the room that door 2 normally leads to.")

    elif patch_type == "greattree-all":
        # Change Library exit destination in ALL steps
        new_room_id = 0x01  # Try room 1 (probably GreatTree sub-area)
        for addr, step, orig, desc in GREATTREE_LIBRARY_EXITS:
            patches[f"0x{addr:06X}"] = f"{new_room_id:02X}"
            print(f"    0x{addr:06X}: 0x{orig:02X} → 0x{new_room_id:02X} ({desc})")
        print(f"\n    Changed Library exit in ALL 3 steps to room_id {new_room_id}.")
        print(f"    TEST: Walk to Library entrance in GreatTree. You should go")
        print(f"    to wherever room_id 1 leads (probably a GreatTree sub-area).")

    elif patch_type == "castle-block":
        # Set one Castle exit to 0xFF (which the code checks as "no exit")
        addr = CASTLE_EXIT_TABLE + 4  # room_id for first door
        patches[f"0x{addr:05X}"] = "FF"
        print(f"\n  Castle door block: first door → 0xFF (should become impassable)")
        print(f"    0x{addr:05X}: 01 → FF")
        print(f"    TEST: First door in Castle should no longer work.")

    elif patch_type == "stable-swap":
        # Stable has cleaner data: exits to room 8, room 12-15
        # Swap room 8 exits to room 12
        for addr, desc, orig in STABLE_EXITS:
            patches[f"0x{addr:06X}"] = "0C"
        print(f"\n  Stable: redirect all 'room 8' exits to 'room 12'")
        print(f"    TEST: In the Stable, door that goes to pen should go somewhere else.")

    else:
        print(f"  Unknown patch type: {patch_type}")
        print(f"  Available: castle-swap, greattree-all, castle-block, stable-swap")
        return {}

    return patches


def search_transition_table(data: bytes):
    """Search for the routing table that maps room_ids to map_types.

    The game must have a table somewhere that says:
      "when leaving map_type X via room_id Y, load map_type Z at position W"

    Strategy: search for known (map_type, room_id) → map_type mappings.
    We know GreatTree room_id 18 → Library (map_type 0x12).
    Search for bytes 0x12 near bytes 0x01 (GreatTree map_type) or 0x12 (18).
    """
    print(f"\n{'='*60}")
    print(f"TRANSITION TABLE SEARCH")
    print(f"{'='*60}")

    # The value at $D8D4 (next room id) gets processed somewhere.
    # Let's search for code that reads $D8D4
    target = bytes([0xFA, 0xD4, 0xD8])  # LD A, ($D8D4)
    print(f"\n  Searching for 'LD A, ($D8D4)' [FA D4 D8]...")
    hits = []
    i = 0
    while True:
        idx = data.find(target, i)
        if idx < 0:
            break
        bank = idx // BANK_SIZE
        local = (idx % BANK_SIZE) + (0 if bank == 0 else 0x4000)
        hits.append((idx, bank, local))
        i = idx + 1

    for idx, bank, local in hits[:20]:
        ctx_before = data[max(0, idx - 8):idx]
        ctx_after = data[idx + 3:idx + 16]
        print(f"    0x{idx:06X} (bank {bank:02X}:{local:04X})  "
              f"...{ctx_before.hex(' ')} [FA D4 D8] {ctx_after.hex(' ')}...")

    # Also search for code that writes to $C968 (map_type)
    target2 = bytes([0xEA, 0x68, 0xC9])  # LD ($C968), A
    print(f"\n  Searching for 'LD ($C968), A' [EA 68 C9]...")
    hits2 = []
    i = 0
    while True:
        idx = data.find(target2, i)
        if idx < 0:
            break
        bank = idx // BANK_SIZE
        local = (idx % BANK_SIZE) + (0 if bank == 0 else 0x4000)
        hits2.append((idx, bank, local))
        i = idx + 1

    for idx, bank, local in hits2[:20]:
        ctx_before = data[max(0, idx - 8):idx]
        ctx_after = data[idx + 3:idx + 12]
        print(f"    0x{idx:06X} (bank {bank:02X}:{local:04X})  "
              f"...{ctx_before.hex(' ')} [EA 68 C9] {ctx_after.hex(' ')}...")

    # Search for reads of $C925 (room index within map_type)
    target3 = bytes([0xFA, 0x25, 0xC9])  # LD A, ($C925)
    print(f"\n  Searching for 'LD A, ($C925)' [FA 25 C9] (first 10)...")
    hits3 = []
    i = 0
    while True:
        idx = data.find(target3, i)
        if idx < 0:
            break
        bank = idx // BANK_SIZE
        local = (idx % BANK_SIZE) + (0 if bank == 0 else 0x4000)
        hits3.append((idx, bank, local))
        i = idx + 1

    for idx, bank, local in hits3[:10]:
        ctx_after = data[idx + 3:idx + 12]
        print(f"    0x{idx:06X} (bank {bank:02X}:{local:04X})  "
              f"[FA 25 C9] {ctx_after.hex(' ')}...")

    print(f"\n  Total hits: $D8D4 reads={len(hits)}, $C968 writes={len(hits2)}, "
          f"$C925 reads={len(hits3)}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", default="data/DWM-original.gbc")
    ap.add_argument("--generate-patch", metavar="TYPE",
                    help="Generate test patch: castle-swap, greattree-all, "
                         "castle-block, stable-swap")
    ap.add_argument("--search", action="store_true",
                    help="Search for transition table code references")
    ap.add_argument("--apply", action="store_true",
                    help="Write generated patch to edits.json (merge with existing)")
    args = ap.parse_args()

    rom_path = Path(args.rom)
    if not rom_path.exists():
        print(f"ROM not found: {rom_path}")
        return

    data = rom_path.read_bytes()
    print(f"Loaded {rom_path} ({len(data)} bytes)")

    # Always verify
    verify_exits(data, rom_path.name)
    verify_room_id_hypothesis(data)

    # Search for transition code
    if args.search:
        search_transition_table(data)

    # Generate patch
    if args.generate_patch:
        print(f"\n{'='*60}")
        print(f"GENERATING TEST PATCH: {args.generate_patch}")
        print(f"{'='*60}")

        patches = generate_patch(args.generate_patch)
        if patches:
            print(f"\n  raw_bytes to add to edits.json:")
            for k, v in patches.items():
                print(f'    "{k}": "{v}"')

            if args.apply:
                edits_path = Path("extracted/edits.json")
                if edits_path.exists():
                    edits = json.loads(edits_path.read_text())
                else:
                    edits = {"monster_stats": {}, "text": {}, "raw_bytes": {}}
                edits.setdefault("raw_bytes", {}).update(patches)
                edits_path.write_text(json.dumps(edits, indent=2))
                print(f"\n  ✓ Written to {edits_path}")
                print(f"    Now run: uv run python -m tools.build_rom")
            else:
                print(f"\n  Add --apply to write to edits.json automatically.")
                print(f"  Or copy the raw_bytes entries manually.")


if __name__ == "__main__":
    main()
