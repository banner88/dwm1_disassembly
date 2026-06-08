"""Scan all room exit data blocks to find every transition in the game.

Parses step blocks → exit_ptr → 7-byte exit entries.
Format: [trigger_X] [trigger_Y] [dest_map_type] [gate_flag] [screen] [spawn_X] [spawn_Y]

Usage: uv run python -m tools.dump_all_exits
"""
import json
from pathlib import Path
from collections import defaultdict
from dwm.rom import ROM, BANK_SIZE

BANK = 0x0B
MAP_PTR_ADDR = 0x4B43

MAP_NAMES = {
    0x00: "Castle", 0x01: "GreatTree", 0x02: "Bazaar", 0x03: "Gate Hub",
    0x04: "Farm", 0x05: "Stable", 0x06: "Arena Lobby", 0x07: "Arena Rooms",
    0x08: "Gate (08)", 0x09: "Starry Shrine", 0x0A: "Secret Passage",
    0x0C: "Egg Evaluator", 0x0D: "Old Man Gate Room", 0x0F: "Vault",
    0x10: "Copycat House", 0x12: "Library", 0x13: "Library Gate Room",
    0x16: "MedalMan", 0x18: "Well",
    0x19: "Goopy Room 1", 0x1A: "Goopy Room 2",
    0x1D: "Monster School", 0x1E: "Restaurant", 0x1F: "Queen Room",
    0x23: "Room of Beginning", 0x24: "Room: Villager/Talisman",
    0x25: "Room: Memories/Bewilder", 0x26: "Room: Peace/Bravery",
    0x27: "Room: Strength/Anger", 0x28: "Room: Joy/Wisdom",
    0x29: "Room: Happiness/Temptation", 0x2A: "Room: Labyrinth/Judgment",
    0x2B: "Room: Reflection", 0x2C: "Room: Ambition/Demolition",
    0x2D: "Room: Mastermind/Control", 0x2E: "Room: Extinction/Sleep",
    0x2F: "Intro Bedroom",
    0x30: "Boss: Beginning (Healer)", 0x31: "Boss: Villager (Dragon)",
    0x32: "Boss: Talisman (Golem)", 0x33: "Boss: Memories (MadCat)",
    0x34: "Boss: Bewilder (FaceTree)", 0x36: "Boss: Peace (FangSlime)",
    0x37: "Boss: Bravery (BigEye)", 0x38: "Boss: Well (Gigantes)",
    0x39: "Boss: Strength (StoneMan)", 0x3A: "Boss: Wisdom (SkyDragon)",
    0x3B: "Boss: Joy (FunkyBird)", 0x3C: "Boss: Anger (BattleRex)",
    0x3D: "Boss: Arena Left (Digster)", 0x3E: "Boss: Happiness (Jamirus)",
    0x3F: "Boss: Temptation (Servant)", 0x41: "Boss: Medal (Lipsy)",
    0x42: "Labyrinth", 0x43: "Boss: Judgment (Akubar)",
    0x44: "Boss: Library (Orochi)", 0x45: "Boss: Reflection (Durran)",
    0x46: "Boss: Ambition (DracoLord)", 0x47: "Boss: Demolition (Hargon/Sidoh)",
    0x48: "Boss: Mastermind (Baramos)", 0x49: "Boss: Control (Zoma)",
    0x4A: "Boss: Extinction (Pizzaro)", 0x4B: "Boss: Sleep (Esterk)",
    0x4C: "Boss: Bazaar Edge (Mirudraas)", 0x4D: "Boss: Arena Right (Mudou)",
    0x4F: "Boss: Unused (DeathMore)",
    0x50: "Gate Floor: Item Shop", 0x51: "Gate Floor: Priest",
    0x52: "Gate Floor: Coliseum", 0x53: "Forest Maze",
    0x5D: "Arena Battle", 0x5E: "Arena Setup Room",
}


def flat(addr):
    return BANK * BANK_SIZE + (addr - 0x4000)


def parse_step_block(d, block_addr):
    bf = flat(block_addr)
    ram_lo = d[bf]
    ram_hi = d[bf + 1]
    ram_ptr = ram_lo | (ram_hi << 8)

    steps = []
    offset = bf + 2
    for i in range(12):
        if offset + 5 >= len(d):
            break
        step_id = d[offset]
        tileset = d[offset + 1]
        interact = d[offset + 2] | (d[offset + 3] << 8)
        exit_ptr = d[offset + 4] | (d[offset + 5] << 8)

        if not (0x4000 <= interact <= 0x7FFF):
            break

        steps.append({
            "step_id": step_id, "tileset": tileset,
            "interact_ptr": interact, "exit_ptr": exit_ptr,
            "interact_flat": flat(interact), "exit_flat": flat(exit_ptr),
        })
        offset += 6

    return ram_ptr, steps


def parse_exit_block(d, exit_ptr, src_mt):
    """Parse exit entries from an exit data block.
    
    Exit blocks may start with interaction-style entries (0x8F, 0x90, etc.)
    followed by raw 7-byte exit entries.
    """
    ef = flat(exit_ptr)
    exits = []
    pos = 0
    max_bytes = 64  # safety limit

    # Skip past any interaction-style header entries
    while pos < max_bytes and ef + pos < len(d):
        byte = d[ef + pos]
        if byte == 0xFF:
            pos += 1  # skip terminator
            break
        elif byte & 0x80:  # 0x8F, 0x90, 0x82, etc.
            pos += 5  # skip 5-byte interaction entry
        else:
            # Found non-interaction data — these are exit entries
            break

    # Now parse 7-byte exit entries
    while pos + 6 < max_bytes and ef + pos + 6 < len(d):
        trig_x = d[ef + pos]
        trig_y = d[ef + pos + 1]
        dest_mt = d[ef + pos + 2]
        gate_flag = d[ef + pos + 3]
        screen = d[ef + pos + 4]
        spawn_x = d[ef + pos + 5]
        spawn_y = d[ef + pos + 6]

        # Validate: dest_mt should be a reasonable map type (< 0x70)
        # gate_flag should be 0 or 1
        # trigger coords should be reasonable (< 20)
        if dest_mt >= 0x70 or gate_flag > 1 or trig_x > 20 or trig_y > 20:
            break

        dest_flat = ef + pos + 2  # flat address of the map_type byte

        exits.append({
            "src_mt": src_mt,
            "src_name": MAP_NAMES.get(src_mt, f"Map_{src_mt:02X}"),
            "trigger_x": trig_x,
            "trigger_y": trig_y,
            "dest_mt": dest_mt,
            "dest_name": MAP_NAMES.get(dest_mt, f"Map_{dest_mt:02X}"),
            "gate_flag": gate_flag,
            "screen": screen,
            "spawn_x": spawn_x,
            "spawn_y": spawn_y,
            "flat": dest_flat,
            "exit_ptr": exit_ptr,
        })

        pos += 7

    return exits


def main():
    rom = ROM(Path("data/DWM-original.gbc"))
    d = rom.data

    ptr_table_flat = flat(MAP_PTR_ADDR)

    all_exits = []
    seen_exit_ptrs = set()

    for mt in range(107):
        lo = d[ptr_table_flat + mt * 2]
        hi = d[ptr_table_flat + mt * 2 + 1]
        ptr = lo | (hi << 8)

        if not (0x4000 <= ptr <= 0x7FFF):
            continue

        # Parse screen blocks to find step blocks
        rf = flat(ptr)
        pos = 0
        for screen_idx in range(16):
            if rf + pos + 7 >= len(d):
                break

            # Read potential pointer
            p1 = d[rf + pos] | (d[rf + pos + 1] << 8)

            # Check if we've hit step block data
            if 0x4000 <= p1 <= 0x7FFF:
                target = flat(p1)
                if target + 1 < len(d) and d[target + 1] == 0xD9:
                    # This is a step block pointer
                    _, steps = parse_step_block(d, p1)
                    for step in steps:
                        ep = step["exit_ptr"]
                        if ep in seen_exit_ptrs:
                            continue
                        seen_exit_ptrs.add(ep)
                        exits = parse_exit_block(d, ep, mt)
                        all_exits.extend(exits)

            pos += 2

            # Check if next looks like step data
            if pos < 128 and rf + pos + 1 < len(d):
                if d[rf + pos + 1] == 0xD9:
                    # Hit step block — parse it
                    step_addr = d[rf + pos] | (d[rf + pos + 1] << 8)
                    if not (0x4000 <= step_addr <= 0x7FFF):
                        # This IS step data at current position
                        local_addr = ptr + pos
                        _, steps = parse_step_block(d, local_addr)
                        for step in steps:
                            ep = step["exit_ptr"]
                            if ep in seen_exit_ptrs:
                                continue
                            seen_exit_ptrs.add(ep)
                            exits = parse_exit_block(d, ep, mt)
                            all_exits.extend(exits)
                    break

    # Deduplicate by flat address
    seen_flats = set()
    unique_exits = []
    for ex in all_exits:
        if ex["flat"] not in seen_flats:
            seen_flats.add(ex["flat"])
            unique_exits.append(ex)

    # Sort by source room then flat address
    unique_exits.sort(key=lambda e: (e["src_mt"], e["flat"]))

    print("=" * 100)
    print(f"ALL EXIT TRANSITIONS ({len(unique_exits)} found)")
    print("=" * 100)

    by_src = defaultdict(list)
    for ex in unique_exits:
        by_src[ex["src_mt"]].append(ex)

    for src_mt in sorted(by_src.keys()):
        exits = by_src[src_mt]
        src_name = MAP_NAMES.get(src_mt, f"Map_{src_mt:02X}")
        print(f"\n--- 0x{src_mt:02X} {src_name} ({len(exits)} exits) ---")
        for ex in exits:
            byte5_val = rom.data[ex["flat"] + 5] if ex["flat"] + 5 < len(rom.data) else 0
            safe = "✅" if byte5_val == 0xFF else f"⚠️b5={byte5_val:02X}"
            print(f"  {safe}  trig=({ex['trigger_x']},{ex['trigger_y']})  "
                  f"→ 0x{ex['dest_mt']:02X} {ex['dest_name']:25s}  "
                  f"scr=0x{ex['screen']:02X} X={ex['spawn_x']} Y={ex['spawn_y']}  "
                  f"flat=0x{ex['flat']:06X}")

    # Generate Python code for EXIT_TRANSITIONS and DEST_SPAWN_DEFAULTS
    print(f"\n{'=' * 100}")
    print("PYTHON CODE: EXIT_TRANSITIONS")
    print("=" * 100)
    for ex in unique_exits:
        src_name = MAP_NAMES.get(ex["src_mt"], f"Map_{ex['src_mt']:02X}")
        dst_name = MAP_NAMES.get(ex["dest_mt"], f"Map_{ex['dest_mt']:02X}")
        label = f"{src_name} → {dst_name}"
        print(f'    ("{label}", 0x{ex["flat"]:06X}, 0x{ex["src_mt"]:02X}, '
              f'0x{ex["dest_mt"]:02X}, 0x{ex["screen"]:02X}, 0x{ex["spawn_x"]:02X}, '
              f'0x{ex["spawn_y"]:02X}),')

    print(f"\n{'=' * 100}")
    print("PYTHON CODE: DEST_SPAWN_DEFAULTS (from entry-side transitions)")
    print("=" * 100)
    # For each destination, find the entry that goes TO it
    dest_entries = defaultdict(list)
    for ex in unique_exits:
        dest_entries[ex["dest_mt"]].append(ex)
    for dmt in sorted(dest_entries.keys()):
        entries = dest_entries[dmt]
        # Pick the first one as default
        ex = entries[0]
        name = MAP_NAMES.get(dmt, f"Map_{dmt:02X}")
        print(f'    0x{dmt:02X}: (0x{ex["screen"]:02X}, 0x{ex["spawn_x"]:02X}, '
              f'0x{ex["spawn_y"]:02X}),  # {name}')

    # Save JSON
    out_path = Path("extracted/all_exits.json")
    out_path.parent.mkdir(exist_ok=True)
    out_path.write_text(json.dumps(unique_exits, indent=2))
    print(f"\nSaved {len(unique_exits)} exits to {out_path}")


if __name__ == "__main__":
    main()
