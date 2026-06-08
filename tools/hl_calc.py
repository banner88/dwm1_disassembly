"""Paste PC and HL from SameBoy registers output, get the answer.

Usage:
  python -m tools.hl_calc 45ab 4e10
  python -m tools.hl_calc 45af 599a
  python -m tools.hl_calc 524b d7ba
  python -m tools.hl_calc              # interactive mode
"""
import sys

BANK = 0x0B
BANK_SIZE = 0x4000

MAP_TYPES = {
    0x00: "Castle", 0x01: "GreatTree", 0x02: "Bazaar", 0x03: "Gate Hub",
    0x04: "Farm", 0x05: "Stable", 0x06: "Arena Lobby", 0x07: "Arena Rooms",
    0x08: "Gate tileset", 0x09: "Starry Shrine", 0x0A: "Secret Passage",
    0x0C: "Gate tileset 2", 0x0D: "Old Man Gate", 0x10: "Copycat Room",
    0x12: "Library", 0x16: "MedalMan Room", 0x18: "Well",
    0x1B: "Slime King room", 0x1C: "Coffin room",
    0x23: "Room of Beginning", 0x24: "Room of Villager/Talisman",
    0x42: "Labyrinth", 0x53: "Forest Maze",
}

def calc(pc_hex, hl_hex, dest_hex=None):
    pc = int(pc_hex, 16)
    hl = int(hl_hex, 16)

    if pc in (0x524b, 0x52e8):
        print(f"  RAM-based door (not directly patchable in ROM)")
        print(f"  examine/12 ${hl - 1:04X}")
        return
    if pc == 0x46c1:
        print(f"  Gate floor transition (RAM, not patchable)")
        return
    if pc == 0x45ab:
        addr = hl - 1
    elif pc == 0x45af:
        addr = hl - 2
    else:
        print(f"  Unknown PC ${pc:04X}, guessing HL-1")
        addr = hl - 1

    flat_addr = BANK * BANK_SIZE + (addr - 0x4000)
    print(f"  examine/12 ${addr:04X}")
    print(f"  Patchable byte: 0x{flat_addr:06X}")
    if dest_hex:
        d = int(dest_hex, 16)
        print(f"  Destination: 0x{d:02X} = {MAP_TYPES.get(d, '???')}")

def main():
    if len(sys.argv) >= 3:
        calc(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
        return
    print("Paste PC and HL from registers. Type q to quit.\n")
    while True:
        try:
            line = input("PC HL dest (e.g. 45ab 4e10 04): ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if not line or line == 'q':
            break
        parts = line.split()
        calc(parts[0], parts[1], parts[2] if len(parts) > 2 else None)
        print()

if __name__ == "__main__":
    main()
