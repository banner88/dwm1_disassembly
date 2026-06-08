"""Copy an existing room's data and load it through the cross-bank trampoline.

This proves the infrastructure works by using KNOWN-GOOD room data
instead of hand-crafted data. If the copied room appears correctly,
the trampoline + copy routine + WRAM layout all work.

Usage: python copy_room_test.py data/DWM-original.gbc
"""
import struct, json, sys

rom_path = sys.argv[1] if len(sys.argv) > 1 else "data/DWM-original.gbc"
d = open(rom_path, 'rb').read()
base = 0x0B * 0x4000

def read_room_chain(mt):
    """Read a room's full data chain and repackage for WRAM $D378."""
    ptr_off = 0x4B43 + mt * 2
    flat = base + (ptr_off - 0x4000)
    room_ptr = struct.unpack_from('<H', d, flat)[0]
    room_flat = base + (room_ptr - 0x4000)

    step_ptr = struct.unpack_from('<H', d, room_flat)[0]
    step_flat = base + (step_ptr - 0x4000)

    ram_flag = struct.unpack_from('<H', d, step_flat)[0]
    step_id = d[step_flat + 2]
    tileset = d[step_flat + 3]
    interact_ptr = struct.unpack_from('<H', d, step_flat + 4)[0]
    exit_ptr_val = struct.unpack_from('<H', d, step_flat + 6)[0]

    # Read interact block (up to FF terminator)
    iflt = base + (interact_ptr - 0x4000)
    idata = []
    for i in range(24):
        b = d[iflt + i]
        idata.append(b)
        if b == 0xFF:
            break

    # Read exit block
    eflt = base + (exit_ptr_val - 0x4000)
    edata = []
    for i in range(24):
        b = d[eflt + i]
        edata.append(b)
        if b == 0xFF:
            break

    print(f"  ptr=${room_ptr:04X}  step=${step_ptr:04X}  flag=${ram_flag:04X}")
    print(f"  step_id={step_id}  tileset=0x{tileset:02X}")
    print(f"  interact=${interact_ptr:04X} ({len(idata)}B): {' '.join(f'{b:02X}' for b in idata)}")
    print(f"  exit    =${exit_ptr_val:04X} ({len(edata)}B): {' '.join(f'{b:02X}' for b in edata)}")

    # Build 128-byte WRAM-format room data
    W = 0xD378
    buf = bytearray(128)
    # Screen ptrs: slot 0 → step block, rest unused
    struct.pack_into('<H', buf, 0x00, W + 0x08)
    buf[2] = buf[3] = buf[4] = buf[5] = buf[6] = buf[7] = 0xFF
    # Step block at offset 0x08
    struct.pack_into('<H', buf, 0x08, 0xD377)  # safe RAM flag
    buf[0x0A] = 0x00          # step index 0
    buf[0x0B] = tileset       # ORIGINAL tileset
    struct.pack_into('<H', buf, 0x0C, W + 0x20)  # interact → WRAM
    struct.pack_into('<H', buf, 0x0E, W + 0x50)  # exit → WRAM
    # Step 1 (empty fallback)
    buf[0x10] = 0x01; buf[0x11] = tileset
    struct.pack_into('<H', buf, 0x12, W + 0x38)
    struct.pack_into('<H', buf, 0x14, W + 0x68)
    # Interact block at offset 0x20 (ORIGINAL NPC data)
    for i, b in enumerate(idata):
        buf[0x20 + i] = b
    buf[0x38] = 0xFF
    # Exit block at offset 0x50 (ORIGINAL exit data)
    for i, b in enumerate(edata):
        buf[0x50 + i] = b
    buf[0x68] = 0xFF

    return " ".join(f"{b:02X}" for b in buf), tileset


# Show candidates
rooms = {
    0x1B: "Stable: KingSlime Room",
    0x1C: "Stable: Coffin Room",
    0x08: "Starry Shrine Cutscene",
    0x17: "Copycat House",
}

print("=" * 60)
print("Room data extraction for cross-bank copy test")
print("=" * 60)

results = {}
for mt, name in rooms.items():
    print(f"\n0x{mt:02X} {name}:")
    try:
        hex_data, tileset = read_room_chain(mt)
        results[mt] = (hex_data, name, tileset)
        print(f"  ✓ Ready")
    except Exception as e:
        print(f"  ✗ {e}")

# Pick the first successful room
if not results:
    print("\nNo rooms could be read!")
    sys.exit(1)

chosen_mt = list(results.keys())[0]
room_hex, room_name, tileset = results[chosen_mt]
print(f"\n{'=' * 60}")
print(f"Using: 0x{chosen_mt:02X} {room_name} (tileset=0x{tileset:02X})")
print(f"{'=' * 60}")

# Build the full edits.json with ALL infrastructure
# Using the WRAM-pointer approach (pointer table → $D378)
# Only patching $4287 (confirmed working)
edits = {"monster_stats": {}, "text": {}, "raw_bytes": {}}

# Trampoline: read ptr → Steps 2-4 → check bit 7 → copy if WRAM
tramp = (
    "2A 66 6F "                                     # read pointer (3)
    "FA 25 C9 87 85 6F 3E 00 8C 67 "               # Steps 2-4 part 1 (10)
    "2A 66 6F "                                     # step_block_ptr (3)
    "5E 23 56 23 "                                  # RAM flag addr (4)
    "1A 5F 87 83 87 85 6F "                         # step index (7)
    "3E 00 8C 67 "                                  # high byte (4)
    "23 23 "                                        # skip id+tileset (2)
    "2A 66 6F "                                     # interact_ptr (3)
    "CB 7C "                                        # bit 7,h (2)
    "28 0A "                                        # jr z, .ret +10 (2)
    "E5 "                                           # push hl (1)
    "3E 68 "                                        # ld a,$68 (2)
    "21 00 40 "                                     # ld hl,$4000 (3)
    "CD E8 3F "                                     # call copy (3)
    "E1 "                                           # pop hl (1)
    "C9 "                                           # ret (1)
    "FF"                                            # pad (1)
)
assert len(tramp.split()) == 52, f"Trampoline is {len(tramp.split())} bytes!"

edits['raw_bytes'] = {
    "0x02C287": "C3 A9 77",                         # jp trampoline
    "0x02F7A9": tramp,                               # trampoline
    "0x003FE8": "F3 EA 00 21 11 78 D3 06 80 2A 12 13 05 20 FA 3E 0B EA 00 21 FB C9",  # copy routine
    "0x02CC0D": "78 D3",                             # ptr table 0x65 → $D378 (WRAM)
    "0x1A0000": room_hex,                            # room data (COPIED from existing room!)
    "0x02CFEF": "65",                                # route well → 0x65
    "0x02CFF1": "00",                                # screen = 0
}

json.dump(edits, open('edits.json', 'w'), indent=2)
print(f"\nWrote edits.json with copied room data from 0x{chosen_mt:02X}")
print(f"Room: {room_name}")
print(f"Infrastructure: $4287 trampoline + $3FE8 copy + $D378 WRAM")
print(f"\nBuild and enter the Well to see the copied room.")
