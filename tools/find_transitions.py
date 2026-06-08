"""Find all room transition data blocks in Bank 0B and export IPS patches.

Part 1: Scans the interaction data blocks (pointed to by bytes 4-5 of step entries)
        and the exit data blocks to find transition destination bytes.
        
Part 2: Converts edits.json raw_bytes to IPS patch format.

Usage:
  python -m tools.find_transitions                    # find all transitions
  python -m tools.find_transitions --export-ips       # also export IPS patch
  python -m tools.find_transitions --export-ips-only  # just export IPS
"""

import argparse
import json
import struct
from pathlib import Path

BANK_SIZE = 0x4000
BANK_0B = 0x0B

MAP_TYPE_NAMES = {
    0x00: "Castle", 0x01: "GreatTree", 0x02: "Bazaar", 0x03: "Gate Hub",
    0x04: "Farm", 0x05: "Stable", 0x06: "Arena Lobby", 0x07: "Arena Rooms",
    0x08: "Gate tileset", 0x09: "Starry Shrine", 0x0A: "Secret Passage",
    0x0C: "Gate tileset 2", 0x0D: "Old Man Gate", 0x0E: "Gate tileset 3",
    0x0F: "Unknown 0F", 0x10: "Copycat Room", 0x12: "Library",
    0x13: "Unknown 13", 0x16: "MedalMan Room", 0x18: "Well",
    0x19: "Unknown 19", 0x1A: "Unknown 1A", 0x1B: "Unknown 1B",
    0x1C: "Unknown 1C", 0x1D: "Unknown 1D", 0x1E: "Unknown 1E",
    0x1F: "Unknown 1F", 0x23: "Room of Beginning",
    0x24: "Room of Villager/Talisman", 0x25: "Room of Memories/Bewilder",
    0x26: "Room of Peace/Bravery", 0x27: "Room of Strength/Anger",
    0x28: "Room of Joy/Wisdom", 0x29: "Room of Happiness/Temptation",
    0x2A: "Room of Labyrinth/Judgment", 0x2B: "Room of Reflection",
    0x2C: "Room of Ambition/Demolition", 0x2D: "Room of Mastermind/Control",
    0x2E: "Room of Extinction/Sleep",
    0x30: "Boss: Beginning", 0x31: "Boss: Villager", 0x32: "Boss: Talisman",
    0x33: "Boss: Memories", 0x34: "Boss: Bewilder", 0x36: "Boss: Peace",
    0x37: "Boss: Bravery", 0x42: "Labyrinth", 0x46: "Boss: Ambition",
    0x4D: "Boss: Arena Right", 0x4F: "Boss: Unused Gate",
    0x52: "Coliseum", 0x53: "Forest Maze",
    0x54: "Conveyor Belt 1", 0x55: "Conveyor Belt 2", 0x56: "Conveyor Belt 3",
    0x57: "Maze 1", 0x58: "Maze 2", 0x59: "Maze 3",
    0x5A: "Treasure Chest 1", 0x5C: "Treasure Chest 3", 0x5D: "Arena Battle",
}


def flat(bank, local):
    if bank == 0:
        return local
    return bank * BANK_SIZE + (local - 0x4000)


def read_u16(data, offset):
    return data[offset] | (data[offset + 1] << 8)


def is_valid_ptr(ptr):
    return 0x4000 <= ptr <= 0x7FFF


# ── Part 1: Find transitions by scanning Bank 0B interaction data ──

def find_transitions(data):
    """Find transition destination bytes by following the map table structure."""
    
    TABLE_LOCAL = 0x4B43
    table_flat = flat(BANK_0B, TABLE_LOCAL)
    
    transitions = []
    
    # Read map type pointer table
    for map_type in range(0x65):
        ptr_off = table_flat + map_type * 2
        if ptr_off + 1 >= len(data):
            break
        sub_ptr = read_u16(data, ptr_off)
        if not is_valid_ptr(sub_ptr):
            continue
        
        # Read sub-rooms
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
            
            # Check RAM counter validity
            ram_counter = read_u16(data, room_flat)
            if not (0xC000 <= ram_counter <= 0xDFFF):
                break
            
            # Read step entries (6 bytes each, starting at room_data + 2)
            base = room_flat + 2
            for step in range(16):
                entry_flat = base + step * 6
                if entry_flat + 5 >= len(data):
                    break
                
                bytes_01 = read_u16(data, entry_flat)
                exit_ptr = read_u16(data, entry_flat + 2)
                npc_ptr = read_u16(data, entry_flat + 4)
                
                if not is_valid_ptr(exit_ptr) or not is_valid_ptr(npc_ptr):
                    break
                
                # Scan exit data for 0x90 entries (walk-on map_type destinations)
                exit_flat = flat(BANK_0B, exit_ptr)
                pos = exit_flat
                for _ in range(32):
                    if pos >= len(data):
                        break
                    b = data[pos]
                    if b == 0xFF:
                        break
                    if not (b & 0x80):
                        break  # non-coord entry terminates exit search
                    if (b & 0xF0) == 0x90 and pos + 4 < len(data):
                        # 0x90 coordinate exit: [type, param, X, Y, dest_map_type]
                        dest_map_type = data[pos + 4]
                        transitions.append({
                            "type": "walk_on_0x90",
                            "map_type": map_type,
                            "map_name": MAP_TYPE_NAMES.get(map_type, ""),
                            "c925": c925,
                            "step": step,
                            "x": data[pos + 2],
                            "y": data[pos + 3],
                            "dest_map_type": dest_map_type,
                            "dest_name": MAP_TYPE_NAMES.get(dest_map_type, ""),
                            "flat_addr": f"0x{pos + 4:06X}",
                            "bank_addr": f"0B:{exit_ptr + (pos - exit_flat) + 4:04X}",
                        })
                    pos += 5  # all bit-7-set entries are 5 bytes
                
                # Scan NPC/interaction data for door transitions
                # The interaction handler reads transition data blocks that contain
                # [dest_map_type, in_gate_flag, ...] sequences.
                # We know these are accessed via $0B:$45AB using LDI from HL.
                # The NPC entries are 7 bytes each, terminated by 0xFF.
                # Door transitions might be embedded after or within the NPC data,
                # or pointed to by NPC entry fields.
                npc_flat = flat(BANK_0B, npc_ptr)
                npc_pos = npc_flat
                for _ in range(32):
                    if npc_pos >= len(data):
                        break
                    npc_type = data[npc_pos]
                    if npc_type == 0xFF:
                        break
                    if npc_pos + 6 >= len(data):
                        break
                    
                    # NPC entry: [type, param, x, y, byte4, byte5, byte6]
                    entry_bytes = data[npc_pos:npc_pos + 7]
                    npc_pos += 7
    
    return transitions


def scan_known_pattern(data):
    """Search Bank 0B for transition data blocks using known patterns.
    
    We know the code at $45AB does:
      LD A, [HLI]    ; read dest_map_type
      LD [$C96D], A   ; store it
      LD A, [HLI]    ; read in_gate_flag
      LD [$C96E], A   ; store it
      
    So transition data is: [map_type_byte] [gate_flag_byte] [more_data...]
    The gate_flag is typically 0xFF (not a gate) or 0x00-0x01.
    
    Search for bytes that look like [known_map_type] [FF or 00] in the
    data region of Bank 0B.
    """
    
    bank_start = flat(BANK_0B, 0x4000)
    # Data starts after the code area. The map table is at $4B43,
    # and data extends from there to $7FFF
    data_start = flat(BANK_0B, 0x4B43)
    data_end = flat(BANK_0B, 0x7FFF)
    
    known_map_types = set(MAP_TYPE_NAMES.keys())
    
    candidates = []
    for i in range(data_start, min(data_end, len(data) - 1)):
        b0 = data[i]
        b1 = data[i + 1]
        
        if b0 in known_map_types and b1 in (0xFF, 0x00):
            # Check that this isn't in the middle of a known structure
            # (like an exit table entry or NPC entry)
            local = (i - bank_start) + 0x4000
            candidates.append({
                "flat": f"0x{i:06X}",
                "bank_addr": f"0B:{local:04X}",
                "dest_map_type": b0,
                "dest_name": MAP_TYPE_NAMES.get(b0, ""),
                "gate_flag": f"0x{b1:02X}",
                "context": data[max(0,i-2):i+8].hex(" "),
            })
    
    return candidates


# ── Part 2: IPS Patch Export ──

def export_ips(edits_path, rom_path, ips_path):
    """Convert edits.json raw_bytes to IPS patch format.
    
    IPS format:
      Header: "PATCH" (5 bytes)
      Records: [3-byte offset] [2-byte size] [data bytes]
      Footer: "EOF" (3 bytes)
    """
    
    if not edits_path.exists():
        print(f"  No edits.json found at {edits_path}")
        return
    
    edits = json.loads(edits_path.read_text())
    raw_bytes = edits.get("raw_bytes", {})
    
    if not raw_bytes:
        print(f"  No raw_bytes entries in edits.json")
        return
    
    # Also include monster_stats and text edits by comparing original vs hacked ROM
    rom_data = None
    hacked_path = Path("data/DWM-hacked.gbc")
    orig_path = Path(rom_path)
    
    patches = []
    
    # Method 1: raw_bytes entries (direct offsets)
    for offset_str, hex_str in sorted(raw_bytes.items()):
        offset = int(offset_str, 16)
        patch_bytes = bytes.fromhex(hex_str.replace(" ", ""))
        patches.append((offset, patch_bytes))
    
    # Method 2: if hacked ROM exists, diff against original for ALL changes
    if hacked_path.exists() and orig_path.exists():
        orig = orig_path.read_bytes()
        hacked = hacked_path.read_bytes()
        if len(orig) == len(hacked):
            # Find all changed byte runs
            i = 0
            while i < len(orig):
                if orig[i] != hacked[i]:
                    # Start of a changed region
                    start = i
                    while i < len(orig) and orig[i] != hacked[i]:
                        i += 1
                    patches.append((start, bytes(hacked[start:i])))
                else:
                    i += 1
    
    if not patches:
        print("  No patches to export")
        return
    
    # Merge overlapping/adjacent patches
    patches.sort()
    merged = []
    for offset, patch_data in patches:
        if merged and offset <= merged[-1][0] + len(merged[-1][1]):
            # Overlapping or adjacent — merge
            prev_offset, prev_data = merged[-1]
            end = max(prev_offset + len(prev_data), offset + len(patch_data))
            # Build merged data
            new_data = bytearray(end - prev_offset)
            new_data[:len(prev_data)] = prev_data
            rel_offset = offset - prev_offset
            new_data[rel_offset:rel_offset + len(patch_data)] = patch_data
            merged[-1] = (prev_offset, bytes(new_data))
        else:
            merged.append((offset, patch_data))
    
    # Write IPS file
    with open(ips_path, "wb") as f:
        f.write(b"PATCH")
        for offset, patch_data in merged:
            # IPS uses 3-byte big-endian offset, 2-byte big-endian size
            if offset > 0xFFFFFF:
                print(f"  WARNING: offset 0x{offset:X} exceeds IPS 24-bit limit, skipping")
                continue
            if len(patch_data) > 0xFFFF:
                # Split into chunks
                for chunk_start in range(0, len(patch_data), 0xFFFF):
                    chunk = patch_data[chunk_start:chunk_start + 0xFFFF]
                    chunk_offset = offset + chunk_start
                    f.write(struct.pack(">I", chunk_offset)[1:])  # 3 bytes
                    f.write(struct.pack(">H", len(chunk)))
                    f.write(chunk)
            else:
                f.write(struct.pack(">I", offset)[1:])  # 3 bytes
                f.write(struct.pack(">H", len(patch_data)))
                f.write(patch_data)
        f.write(b"EOF")
    
    total_bytes = sum(len(d) for _, d in merged)
    print(f"  IPS patch: {ips_path}")
    print(f"    {len(merged)} record(s), {total_bytes} bytes patched")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", default="data/DWM-original.gbc")
    ap.add_argument("--export-ips", action="store_true",
                    help="Export edits.json as IPS patch")
    ap.add_argument("--export-ips-only", action="store_true",
                    help="Only export IPS, skip transition search")
    ap.add_argument("--scan-pattern", action="store_true",
                    help="Also do pattern-based search for transition data")
    args = ap.parse_args()
    
    rom_path = Path(args.rom)
    
    if args.export_ips or args.export_ips_only:
        print("Exporting IPS patch...")
        export_ips(
            Path("extracted/edits.json"),
            rom_path,
            Path("data/DWM-hack.ips"),
        )
        if args.export_ips_only:
            return
    
    if not rom_path.exists():
        print(f"ROM not found: {rom_path}")
        return
    
    data = rom_path.read_bytes()
    print(f"Loaded {rom_path} ({len(data)} bytes)")
    
    # Find transitions from map table structure
    print(f"\n{'='*60}")
    print("WALK-ON TRANSITIONS (0x90 exits)")
    print(f"{'='*60}")
    transitions = find_transitions(data)
    
    walk_ons = [t for t in transitions if t["type"] == "walk_on_0x90"]
    
    # Deduplicate by flat_addr (same byte patched multiple times across steps)
    seen = {}
    for t in walk_ons:
        key = t["flat_addr"]
        if key not in seen:
            seen[key] = t
    
    unique_walk_ons = sorted(seen.values(), key=lambda t: t["flat_addr"])
    
    print(f"\n  {len(unique_walk_ons)} unique walk-on exit destinations:")
    for t in unique_walk_ons:
        print(f"    {t['flat_addr']}  map {t['map_type']:02X} ({t['map_name']}) "
              f"c925={t['c925']} ({t['x']},{t['y']}) "
              f"→ 0x{t['dest_map_type']:02X} ({t['dest_name']})")
    
    # Pattern-based search
    if args.scan_pattern:
        print(f"\n{'='*60}")
        print("PATTERN-BASED TRANSITION CANDIDATES")
        print(f"{'='*60}")
        candidates = scan_known_pattern(data)
        print(f"\n  {len(candidates)} candidate transition bytes:")
        for c in candidates[:100]:
            print(f"    {c['flat']}  {c['bank_addr']}  "
                  f"→ 0x{c['dest_map_type']:02X} ({c['dest_name']})  "
                  f"flag={c['gate_flag']}  ctx=[{c['context']}]")
        if len(candidates) > 100:
            print(f"    ... and {len(candidates) - 100} more")
    
    # Known confirmed transitions
    print(f"\n{'='*60}")
    print("CONFIRMED TRANSITION BYTES (from debugging)")
    print(f"{'='*60}")
    confirmed = [
        ("0x02CE0F", "0B:4E0F", 0x04, "Castle stairs → Farm"),
        ("0x02CFE8", "0B:4FE8", 0x12, "GreatTree screen 5 → Library"),
    ]
    print(f"\n  {'Flat':>10}  {'Bank:Addr':>10}  {'Byte':>4}  Description")
    for flat_s, bank_s, val, desc in confirmed:
        name = MAP_TYPE_NAMES.get(val, "")
        print(f"  {flat_s:>10}  {bank_s:>10}  0x{val:02X}  {desc} ({name})")
    
    print(f"\n  To find more: watch $C96D in SameBoy, walk through any door,")
    print(f"  backstep, read HL-1 from registers → that's the patchable byte.")
    
    # Save
    out = Path("extracted/transitions.json")
    out.write_text(json.dumps({
        "walk_on_exits": unique_walk_ons,
        "confirmed": [{"flat": f, "bank": b, "value": v, "desc": d} 
                       for f, b, v, d in confirmed],
    }, indent=2))
    print(f"\n  Saved {out}")


if __name__ == "__main__":
    main()
