"""Check byte 5 of all exit transitions — 0xFF = safe to redirect, other = unsafe.
Usage: uv run python -m tools.check_exit_byte5
"""
from pathlib import Path
from dwm.rom import ROM, BANK_SIZE

BANK = 0x0B

EXIT_TRANSITIONS = [
    ("Castle → GreatTree",                    0x02CE16),
    ("Bazaar → GreatTree",                    0x02D2C5),
    ("Gate Hub sub1 → Castle",                0x02D51D),
    ("Gate Hub sub2 → sub1",                  0x02D541),
    ("Farm → Castle",                         0x02D833),
    ("Stable → Farm",                         0x02D998),
    ("Arena → GreatTree scr3",                0x02DA1D),
    ("Starry Shrine → GreatTree scr7",        0x02DE62),
    ("Renamer → GreatTree",                   0x02DEBA),
    ("Old Man Gate Room → GreatTree",         0x02DF3D),
    ("Vault → GreatTree",                     0x02DF6B),
    ("Copycat House → GreatTree",             0x02DFC6),
    ("Library → GreatTree scr5",              0x02E070),
    ("MedalMan → GreatTree",                  0x02E1CD),
    ("Well → GreatTree",                      0x02E2AC),
    ("Monster School → Arena",                0x02E3F0),
    ("Restaurant → Arena",                    0x02E432),
    ("Gate of Beginning Room → GateHub",      0x02E4C7),
    ("Gate Room (Villager/Talisman) → GateHub",0x02E525),
    ("Gate Room (Memories/Bewilder) → GateHub",0x02E583),
    ("Gate Room (Peace/Bravery) → GateHub",   0x02E5E1),
    ("Boss Room → Castle",                    0x02EACE),
]

def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    d = rom.data

    print("EXIT BYTE 5 ANALYSIS")
    print("=" * 80)
    print()
    print("Byte 5 = 0xFF → SAFE to change destination")
    print("Byte 5 ≠ 0xFF → UNSAFE (destination change crashes)")
    print()

    safe = []
    unsafe = []

    for label, addr in EXIT_TRANSITIONS:
        # addr is the map_type byte position
        # bytes: [map_type] [flag] [screen] [X] [Y] [byte5]
        b0 = d[addr]      # map_type
        b1 = d[addr + 1]  # gate flag
        b2 = d[addr + 2]  # screen
        b3 = d[addr + 3]  # X
        b4 = d[addr + 4]  # Y
        b5 = d[addr + 5]  # byte 5

        # Also check trigger coords (2 bytes before map_type)
        trig_x = d[addr - 2] if addr >= 2 else 0
        trig_y = d[addr - 1] if addr >= 1 else 0

        status = "✅ SAFE" if b5 == 0xFF else f"⚠️ UNSAFE (byte5=0x{b5:02X})"

        entry = {
            "label": label, "addr": addr,
            "data": f"{b0:02X} {b1:02X} {b2:02X} {b3:02X} {b4:02X} {b5:02X}",
            "trigger": f"({trig_x},{trig_y})",
            "byte5": b5,
        }

        if b5 == 0xFF:
            safe.append(entry)
        else:
            unsafe.append(entry)

        print(f"  {status}  {label:45s}  0x{addr:06X}  [{entry['data']}]  trigger{entry['trigger']}")

    print(f"\n{'=' * 80}")
    print(f"SAFE exits (can change destination):   {len(safe)}/{len(EXIT_TRANSITIONS)}")
    print(f"UNSAFE exits (coord-only changes):     {len(unsafe)}/{len(EXIT_TRANSITIONS)}")

    if unsafe:
        print(f"\nUNSAFE exits — can change screen/X/Y but NOT destination:")
        for e in unsafe:
            print(f"  {e['label']:45s}  byte5=0x{e['byte5']:02X}")

    print(f"\nSAFE exits — full destination redirect supported:")
    for e in safe:
        print(f"  {e['label']}")


if __name__ == "__main__":
    main()
