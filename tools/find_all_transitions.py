"""Find all patchable room transition bytes (entry AND exit) in Bank 0B.

Strategy:
  1. Follow map table structure to find each room's data areas
  2. Scan NPC/interaction data blocks for transition patterns
  3. Cross-reference with confirmed addresses from SameBoy debugging
  4. Output a complete catalog of patchable bytes

Usage:
  python -m tools.find_all_transitions
  python -m tools.find_all_transitions --csv   # output as CSV for spreadsheet
"""

import argparse
import json
from pathlib import Path

BANK_SIZE = 0x4000
BANK_0B = 0x0B

MAP_TYPES = {
    0x00: "Castle", 0x01: "GreatTree", 0x02: "Bazaar", 0x03: "Gate Hub",
    0x04: "Farm", 0x05: "Stable", 0x06: "Arena Lobby", 0x07: "Arena Rooms",
    0x08: "Gate tileset", 0x09: "Starry Shrine", 0x0A: "Secret Passage",
    0x0B: "Castle alias", 0x0C: "Renamer Room", 0x0D: "Old Man Gate",
    0x0F: "Vault", 0x10: "Copycat Room", 0x12: "Library",
    0x13: "GreatTree Hub 2", 0x16: "MedalMan Room", 0x18: "Well",
    0x1B: "SlimeKing Room", 0x1C: "Coffin Room", 0x1D: "Monster School",
    0x1E: "Restaurant", 0x1F: "Queen Room",
    0x23: "Room of Beginning", 0x24: "Room of Villager/Talisman",
    0x25: "Room of Memories/Bewilder", 0x26: "Room of Peace/Bravery",
    0x27: "Room of Strength/Anger", 0x28: "Room of Joy/Wisdom",
    0x29: "Room of Happiness/Temptation", 0x2A: "Room of Labyrinth/Judgment",
    0x2B: "Room of Reflection", 0x2C: "Room of Ambition/Demolition",
    0x2D: "Room of Mastermind/Control", 0x2E: "Room of Extinction/Sleep",
    0x30: "Boss: Beginning", 0x31: "Boss: Villager", 0x32: "Boss: Talisman",
    0x33: "Boss: Memories", 0x34: "Boss: Bewilder", 0x36: "Boss: Peace",
    0x37: "Boss: Bravery", 0x42: "Labyrinth", 0x46: "Boss: Ambition",
    0x4D: "Boss: Arena Right", 0x4F: "Boss: Unused Gate",
    0x52: "Coliseum", 0x53: "Forest Maze", 0x5D: "Arena Battle",
}

# Confirmed transitions from SameBoy debugging sessions
CONFIRMED = {
    # ENTRY transitions (entering a room)
    0x02CE08: ("entry", "Castle stairs DOWN", 0x03, "Gate Hub"),
    0x02CE0F: ("entry", "Castle stairs UP", 0x04, "Farm"),
    0x02CFC1: ("entry", "GreatTree scr1 → Castle", 0x00, "Castle"),
    0x02CFD0: ("entry", "GreatTree scr2 → MedalMan", 0x16, "MedalMan Room"),
    0x02CFD8: ("entry", "GreatTree scr3 → Arena", 0x06, "Arena Lobby"),
    0x02CFE8: ("entry", "GreatTree scr5 → Library", 0x12, "Library"),
    0x02CFEF: ("entry", "GreatTree scr5 → Well", 0x18, "Well"),
    0x02CFF7: ("entry", "GreatTree scr6 → Vault", 0x0F, "Vault"),
    0x02D006: ("entry", "GreatTree scr7 → Starry Shrine", 0x09, "Starry Shrine"),
    0x02D00D: ("entry", "GreatTree scr7 → Old Man Gate", 0x0D, "Old Man Gate"),
    0x02D014: ("entry", "GreatTree scr7 → Copycat House", 0x10, "Copycat Room"),
    0x02D032: ("entry", "GreatTree scr8 → Renamer", 0x0C, "Renamer Room"),
    0x02D492: ("entry", "Gate Hub → sub-level 2", 0x03, "Gate Hub"),
    0x02D524: ("entry", "Gate Hub → Room of Beginning", 0x23, "Room of Beginning"),
    0x02D541: ("entry", "Gate Hub sub2 → sub1", 0x03, "Gate Hub"),
    0x02D82B: ("entry", "Farm → Stable", 0x05, "Stable"),
    0x02D833: ("entry", "Farm → Castle stairs", 0x00, "Castle"),
    0x02D998: ("entry", "Stable → Farm stairs", 0x04, "Farm"),
    0x02DC2B: ("entry", "Arena → Monster School", 0x1D, "Monster School"),
    0x02DC34: ("entry", "Arena → Queen Room", 0x1F, "Queen Room"),
    0x02DC61: ("entry", "Arena → Restaurant", 0x1E, "Restaurant"),
    0x02E49E: ("entry", "Queen Room → Arena", 0x07, "Arena Rooms"),
    0x02E4D5: ("entry", "Room of Beginning → Gate", 0x00, "Gate (flag=01)"),
    0x02EACE: ("entry", "Boss Room gate → Castle", 0x00, "Castle"),
    # EXIT transitions (leaving a room)
    0x02E070: ("exit", "Library EXIT", 0x01, "GreatTree scr5"),
    0x02DE62: ("exit", "Starry Shrine EXIT", 0x01, "GreatTree scr7"),
}


def flat(bank, local):
    if bank == 0:
        return local
    return bank * BANK_SIZE + (local - 0x4000)


def local_from_flat(flat_addr):
    bank = flat_addr // BANK_SIZE
    offset = (flat_addr % BANK_SIZE) + (0 if bank == 0 else 0x4000)
    return bank, offset


def read_u16(data, offset):
    return data[offset] | (data[offset + 1] << 8)


def is_valid_ptr(ptr):
    return 0x4000 <= ptr <= 0x7FFF


def scan_for_transitions(data):
    """Scan Bank 0B data areas for transition patterns.
    
    Transition data format: [map_type] [gate_flag] [spawn_bytes...]
    - map_type: known value 0x00-0x64
    - gate_flag: 0x00 (normal) or 0x01 (entering gate) or 0xFF (?)
    
    We look for these patterns in the data regions of Bank 0B
    (after the code region, roughly $4B43-$7FFF).
    """
    valid_map_types = set(MAP_TYPES.keys())
    bank_start = flat(BANK_0B, 0x4000)
    data_start = flat(BANK_0B, 0x4B43)
    data_end = flat(BANK_0B, 0x7FFF)
    
    candidates = []
    for i in range(data_start, min(data_end, len(data) - 12)):
        b0 = data[i]      # potential map_type
        b1 = data[i + 1]  # potential gate_flag
        
        if b0 not in valid_map_types:
            continue
        if b1 not in (0x00, 0x01):
            continue
        
        # Additional heuristic: bytes 2-5 should look like spawn data
        # Spawn bytes are typically small values (positions/coordinates)
        # Skip if they look like code (opcodes) or pointers
        b2 = data[i + 2]
        b3 = data[i + 3]
        
        local = (i - bank_start) + 0x4000
        candidates.append({
            "flat": f"0x{i:06X}",
            "bank_addr": f"0B:{local:04X}",
            "map_type": b0,
            "map_name": MAP_TYPES.get(b0, "???"),
            "gate_flag": b1,
            "data": data[i:i + 12].hex(" "),
            "confirmed": i in CONFIRMED,
        })
    
    return candidates


def find_room_transitions(data):
    """Follow the map table structure to find transition data for each room."""
    TABLE_LOCAL = 0x4B43
    table_flat = flat(BANK_0B, TABLE_LOCAL)
    
    room_info = []
    
    for map_type in range(0x65):
        ptr_off = table_flat + map_type * 2
        if ptr_off + 1 >= len(data):
            break
        sub_ptr = read_u16(data, ptr_off)
        if not is_valid_ptr(sub_ptr):
            continue
        
        sub_flat = flat(BANK_0B, sub_ptr)
        for c925 in range(32):
            room_ptr_off = sub_flat + c925 * 2
            if room_ptr_off + 1 >= len(data):
                break
            room_data_ptr = read_u16(data, room_ptr_off)
            if not is_valid_ptr(room_data_ptr):
                break
            
            room_flat = flat(BANK_0B, room_data_ptr)
            if room_flat + 1 >= len(data):
                break
            
            ram_counter = read_u16(data, room_flat)
            if not (0xC000 <= ram_counter <= 0xDFFF):
                break
            
            # Get the NPC data pointer from step 0
            base = room_flat + 2
            if base + 5 >= len(data):
                continue
            
            exit_ptr = read_u16(data, base + 2)
            npc_ptr = read_u16(data, base + 4)
            
            if not is_valid_ptr(npc_ptr):
                continue
            
            npc_flat = flat(BANK_0B, npc_ptr)
            
            # Scan past NPC entries (7 bytes each, terminated by 0xFF)
            pos = npc_flat
            npc_count = 0
            while pos < len(data) and data[pos] != 0xFF:
                pos += 7
                npc_count += 1
                if npc_count > 20:
                    break
            
            if pos < len(data) and data[pos] == 0xFF:
                pos += 1  # skip terminator
            
            # Scan the area after NPC data for transition patterns
            # Look in a window of ~100 bytes
            search_start = pos
            search_end = min(pos + 200, len(data) - 12)
            
            transitions_found = []
            for j in range(search_start, search_end):
                b0 = data[j]
                b1 = data[j + 1]
                
                if b0 in MAP_TYPES and b1 in (0x00, 0x01):
                    local_j = (j - flat(BANK_0B, 0x4000)) + 0x4000
                    entry = {
                        "flat": j,
                        "bank_local": local_j,
                        "map_type_dest": b0,
                        "dest_name": MAP_TYPES.get(b0, "???"),
                        "gate_flag": b1,
                        "data_hex": data[j:j + 12].hex(" "),
                        "confirmed": j in CONFIRMED,
                    }
                    transitions_found.append(entry)
            
            if transitions_found:
                room_info.append({
                    "source_map_type": map_type,
                    "source_name": MAP_TYPES.get(map_type, f"0x{map_type:02X}"),
                    "c925": c925,
                    "npc_ptr": f"0x{npc_ptr:04X}",
                    "npc_count": npc_count,
                    "transitions": transitions_found,
                })
    
    return room_info


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", default="data/DWM-original.gbc")
    ap.add_argument("--csv", action="store_true", help="Output as CSV")
    args = ap.parse_args()
    
    rom_path = Path(args.rom)
    if not rom_path.exists():
        print(f"ROM not found: {rom_path}")
        return
    
    data = rom_path.read_bytes()
    print(f"Loaded {rom_path} ({len(data)} bytes)")
    
    # Print confirmed transitions
    print(f"\n{'='*70}")
    print(f"CONFIRMED TRANSITIONS (from SameBoy debugging)")
    print(f"{'='*70}")
    
    entries = sorted(CONFIRMED.items())
    entry_transitions = [(k, v) for k, v in entries if v[0] == "entry"]
    exit_transitions = [(k, v) for k, v in entries if v[0] == "exit"]
    
    print(f"\n  ENTRY transitions ({len(entry_transitions)}):")
    print(f"  {'Flat':>10}  {'Byte':>4}  {'Description':<35}  {'Destination'}")
    for addr, (typ, desc, val, dest) in entry_transitions:
        print(f"  0x{addr:06X}  0x{val:02X}  {desc:<35}  {dest}")
    
    print(f"\n  EXIT transitions ({len(exit_transitions)}):")
    print(f"  {'Flat':>10}  {'Byte':>4}  {'Description':<35}  {'Returns to'}")
    for addr, (typ, desc, val, dest) in exit_transitions:
        print(f"  0x{addr:06X}  0x{val:02X}  {desc:<35}  {dest}")
    
    # Find transitions per room
    print(f"\n{'='*70}")
    print(f"SCANNING ROOM DATA FOR TRANSITION PATTERNS")
    print(f"{'='*70}")
    
    room_info = find_room_transitions(data)
    
    all_transitions = []
    for room in room_info:
        for t in room["transitions"]:
            t["source"] = room["source_name"]
            t["source_map_type"] = room["source_map_type"]
            t["c925"] = room["c925"]
            all_transitions.append(t)
    
    # Deduplicate by flat address
    seen = {}
    for t in all_transitions:
        key = t["flat"]
        if key not in seen or t["confirmed"]:
            seen[key] = t
    
    unique = sorted(seen.values(), key=lambda t: t["flat"])
    confirmed_count = sum(1 for t in unique if t["confirmed"])
    
    print(f"\n  Found {len(unique)} candidate transition bytes "
          f"({confirmed_count} confirmed)")
    
    # Print grouped by source room
    current_source = None
    for t in unique:
        src = f"{t['source']} c925={t['c925']}"
        if src != current_source:
            current_source = src
            print(f"\n  {src}:")
        
        conf = " ✓" if t["confirmed"] else ""
        print(f"    0x{t['flat']:06X}  → 0x{t['map_type_dest']:02X} "
              f"({t['dest_name']})  "
              f"gate={t['gate_flag']}  [{t['data_hex'][:23]}]{conf}")
    
    # Save complete catalog
    out_dir = Path("extracted")
    out_dir.mkdir(exist_ok=True)
    
    catalog = {
        "confirmed_entries": {f"0x{k:06X}": {
            "type": v[0], "description": v[1],
            "map_type": v[2], "destination": v[3]
        } for k, v in CONFIRMED.items()},
        "scanned_candidates": [{
            "flat": f"0x{t['flat']:06X}",
            "source": t["source"],
            "c925": t["c925"],
            "dest_map_type": t["map_type_dest"],
            "dest_name": t["dest_name"],
            "gate_flag": t["gate_flag"],
            "data": t["data_hex"],
            "confirmed": t["confirmed"],
        } for t in unique],
    }
    
    out_path = out_dir / "all_transitions.json"
    out_path.write_text(json.dumps(catalog, indent=2))
    print(f"\n  Saved {out_path}")
    
    if args.csv:
        csv_path = out_dir / "transitions.csv"
        with open(csv_path, "w") as f:
            f.write("flat_addr,source,c925,dest_map_type,dest_name,gate_flag,confirmed,data_hex\n")
            for t in unique:
                f.write(f"0x{t['flat']:06X},{t['source']},{t['c925']},"
                        f"0x{t['map_type_dest']:02X},{t['dest_name']},"
                        f"{t['gate_flag']},{t['confirmed']},{t['data_hex']}\n")
        print(f"  Saved {csv_path}")
    
    # Summary stats
    print(f"\n{'='*70}")
    print(f"SUMMARY")
    print(f"{'='*70}")
    print(f"  Confirmed entry transitions: {len(entry_transitions)}")
    print(f"  Confirmed exit transitions:  {len(exit_transitions)}")
    print(f"  Total scanned candidates:    {len(unique)}")
    print(f"  Rooms with transitions:      {len(room_info)}")
    
    print(f"\n  To find MORE exit transitions manually:")
    print(f"    breakpoint $0B:$45AB")
    print(f"    Enter a room, continue. Leave the room.")
    print(f"    registers → HL-1 = exit byte address")


if __name__ == "__main__":
    main()
