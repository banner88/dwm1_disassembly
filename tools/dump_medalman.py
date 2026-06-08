"""Dump all interaction data blocks for MedalMan room (map_type 0x16).
Run: uv run python -m tools.dump_medalman
"""
from pathlib import Path
from dwm.rom import ROM, BANK_SIZE

BANK = 0x0B

def flat(addr):
    return BANK * BANK_SIZE + (addr - 0x4000)

def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    d = rom.data

    # MedalMan step block starts at $613B
    # Format: [D9_ptr 2B] then repeating [step_id tileset interact_ptr exit_ptr] (6B each)
    step_block = 0x613B
    sf = flat(step_block)

    print("MedalMan Room (0x16) — Step Block at $613B")
    print("=" * 70)

    # Read RAM ptr
    ram_ptr = d[sf] | (d[sf+1] << 8)
    print(f"Step state RAM: ${ram_ptr:04X}\n")

    # Parse step entries until we hit something that doesn't look like a step
    # Step format: [step_id] [tileset] [interact_lo] [interact_hi] [exit_lo] [exit_hi]
    offset = sf + 2
    steps = []
    for i in range(8):  # max 8 steps
        step_id = d[offset]
        tileset = d[offset + 1]
        interact = d[offset + 2] | (d[offset + 3] << 8)
        exit_ptr = d[offset + 4] | (d[offset + 5] << 8)

        if not (0x4000 <= interact <= 0x7FFF):
            break

        steps.append((step_id, tileset, interact, exit_ptr))
        offset += 6

    print(f"Found {len(steps)} step entries:\n")

    for i, (sid, ts, interact, exit_p) in enumerate(steps):
        iflat = flat(interact)
        eflat = flat(exit_p)

        # Dump 32 bytes of interaction data
        idata = d[iflat:iflat + 32]
        edata = d[eflat:eflat + 16]

        print(f"Step {i}: id=0x{sid:02X} tileset=0x{ts:02X}")
        print(f"  Interact: ${interact:04X} (flat 0x{iflat:06X})")
        print(f"    {' '.join(f'{b:02X}' for b in idata)}")

        # Parse entries
        pos = 0
        entry_num = 0
        while pos < len(idata):
            byte = idata[pos]
            if byte == 0xFF:
                print(f"    [{pos:2d}] FF — terminator")
                break
            elif byte & 0x80:  # bit 7 set: 0x8F, 0x82, 0x81, 0x80, 0x90, etc
                if pos + 4 < len(idata):
                    entry = idata[pos:pos+5]
                    print(f"    [{pos:2d}] {' '.join(f'{b:02X}' for b in entry)}  "
                          f"← type 0x{byte:02X} entry")
                    pos += 5
                else:
                    break
            else:  # bit 7 clear: could be NPC entry
                if pos + 4 < len(idata):
                    entry = idata[pos:pos+5]
                    print(f"    [{pos:2d}] {' '.join(f'{b:02X}' for b in entry)}  "
                          f"← NPC? type=0x{byte:02X} bytes: "
                          f"0x{entry[1]:02X} 0x{entry[2]:02X} 0x{entry[3]:02X} 0x{entry[4]:02X}")
                    pos += 5
                else:
                    break
            entry_num += 1
            if entry_num > 10:
                break

        print(f"  Exit: ${exit_p:04X} (flat 0x{eflat:06X})")
        print(f"    {' '.join(f'{b:02X}' for b in edata)}")
        print()

    # Also dump Castle throne room (step 01-04 all use $4C95)
    print("=" * 70)
    print("Castle (0x00) — Interaction data at $4C95")
    print("=" * 70)
    castle_interact = 0x4C95
    cf = flat(castle_interact)
    cdata = d[cf:cf + 80]

    pos = 0
    entry_num = 0
    while pos < len(cdata):
        byte = cdata[pos]
        if byte == 0xFF:
            print(f"  [{pos:2d}] FF — terminator")
            pos += 1
            # Check if there's more data after terminator
            if pos < len(cdata) and cdata[pos] != 0xFF:
                print(f"  --- data continues after terminator ---")
                continue
            break
        elif byte & 0x80:
            if pos + 4 < len(cdata):
                entry = cdata[pos:pos+5]
                print(f"  [{pos:2d}] {' '.join(f'{b:02X}' for b in entry)}  "
                      f"← type 0x{byte:02X}")
                pos += 5
            else:
                break
        else:
            if pos + 4 < len(cdata):
                entry = cdata[pos:pos+5]
                print(f"  [{pos:2d}] {' '.join(f'{b:02X}' for b in entry)}  "
                      f"← NPC? 0x{byte:02X}")
                pos += 5
            else:
                break
        entry_num += 1
        if entry_num > 30:
            print("  ... (truncated)")
            break


if __name__ == "__main__":
    main()
