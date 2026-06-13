"""Analyze how many screens each room has, explaining teleport crashes.

Theory: entry byte 2 is a screen index. If destination has fewer screens
than the byte 2 value, the game reads out of bounds → crash.

Usage: uv run python -m tools.analyze_screens
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dwm.rom import ROM, BANK_SIZE
from dwm.map_names import MAP_NAMES  # canonical room names (97 entries)

BANK = 0x0B
MAP_PTR_ADDR = 0x4B43

# Known entry transitions with their byte 2 values
ENTRY_BYTE2 = {
    "Castle stairs DOWN": 0x01,
    "Castle stairs UP": 0x05,
    "GreatTree scr1 → Castle": 0x05,
    "GreatTree scr2 → MedalMan": 0x00,
    "GreatTree scr3 → Arena": 0x01,
    "GreatTree scr5 → Library": 0x04,
    "GreatTree scr5 → Well": 0x00,
    "GreatTree scr6 → Vault": 0x00,
    "GreatTree scr7 → Shrine": 0x04,
    "GreatTree scr7 → OldMan": 0x00,
    "GreatTree scr7 → Copycat": 0x00,
    "GreatTree scr8 → Renamer": 0x00,
    "Gate Hub → sub2": 0x04,
    "Gate Hub → Beginning": 0x00,
    "Farm → Stable": 0x02,
    "Farm → Castle": 0x05,
    "Stable → Farm": 0x04,
    "Arena → MonsterSchool": 0x00,
    "Arena → QueenRoom": 0x00,
    "Arena → Restaurant": 0x00,
    "RoomOfBeginning → Gate": 0x00,
    "BossRoom → Castle": 0x01,
}


def flat(addr):
    return BANK * BANK_SIZE + (addr - 0x4000)


def count_screens(rom_data, room_ptr):
    """Count screen blocks for a room by looking for pointer pairs."""
    rf = flat(room_ptr)
    screens = 0
    pos = 0
    
    for i in range(16):  # max 16 screens
        if rf + pos + 1 >= len(rom_data):
            break
        
        # Read first 2 bytes of potential screen block
        p1 = rom_data[rf + pos] | (rom_data[rf + pos + 1] << 8)
        
        # Check if this looks like a valid screen block
        # Screen blocks contain pointers ($4000-$7FFF) or $FFFF
        if 0x4000 <= p1 <= 0x7FFF or p1 == 0xFFFF:
            # Check if the pointed-to data starts with a step block (byte[1] = 0xD9)
            if 0x4000 <= p1 <= 0x7FFF:
                target = flat(p1)
                if target + 1 < len(rom_data) and rom_data[target + 1] == 0xD9:
                    # This pointer goes to a step block — we've gone past the screen table
                    break
            
            # Count pointers in this screen block (up to 4 pointers = 8 bytes)
            has_valid_ptr = False
            for slot in range(4):
                sp = rom_data[rf + pos + slot*2] | (rom_data[rf + pos + slot*2 + 1] << 8)
                if 0x4000 <= sp <= 0x7FFF:
                    has_valid_ptr = True
            
            if has_valid_ptr or p1 == 0xFFFF:
                screens += 1
                pos += 8  # 4 pointers × 2 bytes each
            else:
                break
        else:
            # Check if this is actually step block data (byte[1] = 0xD9)
            if pos > 0 and rom_data[rf + pos + 1] == 0xD9:
                break
            # Not a pointer, not step data — might be end of table
            break
    
    return max(screens, 1)  # at least 1 screen


def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    d = rom.data
    
    ptr_table_flat = flat(MAP_PTR_ADDR)
    
    print("=" * 80)
    print("SCREEN COUNT PER ROOM")
    print("=" * 80)
    print()
    print("Theory: entry byte 2 is a SCREEN INDEX. If byte 2 >= room's screen count,")
    print("the game reads out of bounds and crashes.")
    print()
    
    screen_counts = {}
    
    for mt in range(107):
        lo = d[ptr_table_flat + mt * 2]
        hi = d[ptr_table_flat + mt * 2 + 1]
        ptr = lo | (hi << 8)
        
        if not (0x4000 <= ptr <= 0x7FFF):
            continue
        
        screens = count_screens(d, ptr)
        screen_counts[mt] = screens
        name = MAP_NAMES.get(mt, "")
        
        if name or screens > 1:
            print(f"  0x{mt:02X} {name:25s}  {screens} screen(s)  ptr=${ptr:04X}")
    
    print()
    print("=" * 80)
    print("COMPATIBILITY MATRIX")
    print("=" * 80)
    print()
    print("Entry byte 2 → which destinations are SAFE:")
    print()
    
    for b2 in sorted(set(ENTRY_BYTE2.values())):
        safe = [mt for mt, sc in screen_counts.items() if sc > b2]
        unsafe = [mt for mt, sc in screen_counts.items() if sc <= b2 and mt in MAP_NAMES]
        
        entries_with_b2 = [name for name, val in ENTRY_BYTE2.items() if val == b2]
        
        print(f"  byte2=0x{b2:02X} (used by: {', '.join(entries_with_b2[:3])})")
        print(f"    SAFE for {len(safe)} rooms (screen count > {b2})")
        if unsafe:
            unsafe_names = [f"0x{mt:02X} {MAP_NAMES.get(mt, '')}" for mt in unsafe[:10]]
            print(f"    CRASHES on: {', '.join(unsafe_names)}")
        print()
    
    print("=" * 80)
    print("RECOMMENDATION")
    print("=" * 80)
    print()
    print("When redirecting an entrance to a single-screen room, ALWAYS set byte 2 = 0x00.")
    print("byte 2 = 0x00 is safe for ALL destinations.")
    print()
    print("The entrance editor should patch byte 2 (at entry_addr + 2) alongside bytes 0, 3, 4.")
    print()
    
    # Output screen counts for the editor to use
    import json
    out = {f"0x{mt:02X}": sc for mt, sc in screen_counts.items()}
    Path("extracted/screen_counts.json").write_text(json.dumps(out, indent=2))
    print("Saved extracted/screen_counts.json")


if __name__ == "__main__":
    main()
