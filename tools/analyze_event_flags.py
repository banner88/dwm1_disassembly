#!/usr/bin/env python3
"""
analyze_event_flags.py — Complete static analysis of all event flag usage
across all 530 NPC scripts in DWM1.

Traces set_flag ($03), clear_flag ($02), if_flag_set ($01), if_flag_clear ($00)
across banks $0C/$0D/$0E/$0F to produce:
  - Per-flag usage table with set/clear/check counts and locations
  - Free flag slot map
  - Anomaly detection (set-only, check-only flags)
  - JSON export for other tools

Usage:
    python3 tools/analyze_event_flags.py              # Full report
    python3 tools/analyze_event_flags.py --json        # JSON export
    python3 tools/analyze_event_flags.py --free        # Free slots only
    python3 tools/analyze_event_flags.py --flag 0x00F1 # Single flag detail
"""
import json, os, sys
from collections import defaultdict

ROM_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data', 'DWM-original.gbc')
TEXT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'extracted', 'text_id_map.json')
OUTPUT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'extracted', 'event_flags_complete.json')

MAP_NAMES = {
    0x00:'Castle',0x01:'GreatTree',0x02:'Bazaar',0x03:'GateHub',
    0x04:'Farm',0x05:'Stable',0x06:'ArenaLobby',0x07:'ArenaRooms',
    0x09:'MonsterShrine',0x0C:'GateTileset',0x10:'CopycatRoom',
    0x16:'MedalMan',0x18:'Well',0x24:'RoomVillagerTalisman',
    0x25:'RoomMemoriesBewilder',0x26:'RoomPeaceBravery',
    0x28:'RoomJoyWisdom',0x29:'RoomHappinessTemptation',
    0x2A:'RoomLabyrinthJudgment',0x2C:'RoomAmbitionDemolition',
    0x2D:'RoomMastermindControl',0x2F:'Bedroom',
    0x30:'BossBeginning',0x31:'BossVillager',0x32:'BossTalisman',
    0x33:'BossMemories',0x34:'BossBewilder',0x36:'BossPeace',
    0x37:'BossBravery',0x46:'BossAmbition',
}

PARAM_COUNTS = {
    0x00:2, 0x01:2, 0x02:1, 0x03:1, 0x04:2, 0x05:1, 0x06:0, 0x07:1,
    0x08:0, 0x09:1, 0x0A:2, 0x0B:2, 0x0C:3, 0x0D:3, 0x0E:2, 0x0F:3,
    0x10:2, 0x11:4, 0x12:2, 0x13:2, 0x14:1, 0x15:3, 0x16:0, 0x17:1,
    0x18:0, 0x19:0, 0x1A:2, 0x1B:2, 0x1C:1, 0x1D:0, 0x1E:0, 0x1F:0,
    0x20:1, 0x21:2, 0x22:0, 0x23:0, 0x24:0, 0x25:0, 0x26:0, 0x27:1,
    0x28:1, 0x29:1, 0x2A:1, 0x2B:1, 0x2C:1, 0x2D:1, 0x2E:1, 0x2F:2,
    0x30:1, 0x31:2, 0x32:1, 0x33:2, 0x34:0, 0x35:0, 0x36:1, 0x37:2,
    0x38:1, 0x39:0, 0x3A:3, 0x3B:0, 0x3C:0, 0x3D:0, 0x3E:0, 0x3F:2,
    0x40:1, 0x41:2, 0x42:0, 0x43:0, 0x44:0, 0x45:0, 0x46:1, 0x47:1,
    0x48:1, 0x49:1, 0x4A:0, 0x4B:0, 0x4C:1, 0x4D:0, 0x4E:0, 0x4F:0,
    0x50:0, 0x51:0, 0x52:0, 0x53:0, 0x54:0, 0x55:0, 0x56:0, 0x57:0,
    0x58:1, 0x59:1, 0x5A:0, 0x5B:0, 0x5C:0, 0x5D:2, 0x5E:1, 0x5F:0,
    0x60:0, 0x61:0, 0x62:1, 0x63:0,
}

BANK_RANGES = {
    0x0C: range(0x00, 0x06),
    0x0D: range(0x06, 0x20),
    0x0E: range(0x20, 0x40),
    0x0F: range(0x40, 0x60),
}

def rw(rom, bank, addr):
    off = bank * 0x4000 + (addr - 0x4000)
    return rom[off] | (rom[off+1] << 8)


def scan_all_flags(rom):
    """Scan all scripts across all 4 banks for flag operations."""
    flag_ops = []
    for bank, mt_range in BANK_RANGES.items():
        master = 0x41BA
        for mt in mt_range:
            ptr = rw(rom, bank, master + mt * 2)
            if ptr < 0x4000 or ptr >= 0x8000:
                continue
            map_name = MAP_NAMES.get(mt, f'Map_{mt:02X}')
            script_ptrs = []
            pos = ptr
            while True:
                sp = rw(rom, bank, pos)
                if sp < 0x4000 or sp >= 0x8000:
                    break
                script_ptrs.append(sp)
                pos += 2
                if len(script_ptrs) > 100:
                    break
            for sid, saddr in enumerate(script_ptrs):
                cur = saddr
                safety = 0
                while safety < 500:
                    safety += 1
                    w = rw(rom, bank, cur)
                    cur += 2
                    if w == 0xFFFF:
                        break
                    if (w >> 8) == 0xFF:
                        op = w & 0xFF
                        if op > 0x63:
                            break
                        pc = PARAM_COUNTS.get(op, 0)
                        params = []
                        for _ in range(pc):
                            params.append(rw(rom, bank, cur))
                            cur += 2
                        if op in (0x00, 0x01, 0x02, 0x03) and len(params) >= 1:
                            op_name = {0x00:'if_flag_clear', 0x01:'if_flag_set',
                                       0x02:'clear_flag', 0x03:'set_flag'}[op]
                            flag_ops.append({
                                'flag': params[0],
                                'op': op_name,
                                'map': map_name,
                                'script_id': sid,
                                'bank': bank,
                                'script_addr': saddr,
                            })
    return flag_ops


def analyze_flags(flag_ops):
    """Build per-flag analysis from raw operations."""
    by_flag = defaultdict(list)
    for entry in flag_ops:
        by_flag[entry['flag']].append(entry)

    results = {}
    for fid in sorted(by_flag.keys()):
        ops = by_flag[fid]
        byte_addr = 0xD99B + (fid // 8)
        bit = 7 - (fid & 7)
        sets = [o for o in ops if o['op'] == 'set_flag']
        clears = [o for o in ops if o['op'] == 'clear_flag']
        checks = [o for o in ops if o['op'].startswith('if_flag')]
        maps_involved = sorted(set(o['map'] for o in ops))

        results[fid] = {
            'flag_id': f'${fid:04X}',
            'byte': f'${byte_addr:04X}',
            'bit': bit,
            'total_uses': len(ops),
            'set_count': len(sets),
            'clear_count': len(clears),
            'check_count': len(checks),
            'maps': maps_involved,
            'set_locations': [f"{o['map']}_Script{o['script_id']:02d}" for o in sets],
            'clear_locations': [f"{o['map']}_Script{o['script_id']:02d}" for o in clears],
            'check_locations': [f"{o['map']}_Script{o['script_id']:02d}" for o in checks],
            'anomaly': None,
        }
        if len(sets) > 0 and len(checks) == 0:
            results[fid]['anomaly'] = 'set_never_checked'
        if len(checks) > 0 and len(sets) == 0 and len(clears) == 0:
            results[fid]['anomaly'] = 'checked_never_set_in_scripts'

    return results


def find_free_slots(flag_results):
    """Find contiguous free flag ranges."""
    used = set(flag_results.keys())
    if not used:
        return []
    min_f, max_f = min(used), max(used)

    # Free slots within the used range
    free_in_range = sorted(set(range(min_f, max_f + 1)) - used)

    # Group into contiguous ranges
    ranges = []
    if free_in_range:
        start = end = free_in_range[0]
        for f in free_in_range[1:]:
            if f == end + 1:
                end = f
            else:
                ranges.append((start, end))
                start = end = f
        ranges.append((start, end))

    # Free after used range (up to $D9FF)
    max_possible = (0xD9FF - 0xD99B + 1) * 8 - 1  # $0327
    if max_f < max_possible:
        ranges.append((max_f + 1, max_possible))

    return ranges


def print_report(flag_results, free_ranges):
    """Print the full text report."""
    used = sorted(flag_results.keys())
    min_f, max_f = min(used), max(used)
    total_ops = sum(r['total_uses'] for r in flag_results.values())

    print("=" * 70)
    print("DWM1 EVENT FLAG ANALYSIS — Complete Static Analysis")
    print("=" * 70)
    print(f"Total flag operations: {total_ops}")
    print(f"Unique flags used:     {len(used)}")
    print(f"Used range:            ${min_f:04X} - ${max_f:04X}")
    print(f"WRAM range:            ${0xD99B + min_f//8:04X} - ${0xD99B + max_f//8:04X}")
    print(f"Bytes occupied:        {max_f//8 - min_f//8 + 1}")
    print()

    # Per-flag table
    print("-" * 70)
    print(f"{'Flag':>7} {'Byte':>7} {'Bit':>3} {'Uses':>5} {'Set':>4} {'Clr':>4} {'Chk':>4}  Maps")
    print("-" * 70)
    for fid in used:
        r = flag_results[fid]
        anomaly_mark = '*' if r['anomaly'] else ' '
        maps_str = ', '.join(r['maps'][:5])
        if len(r['maps']) > 5:
            maps_str += f' +{len(r["maps"])-5}'
        print(f"{r['flag_id']:>7} {r['byte']:>7} {r['bit']:>3} {r['total_uses']:>5} "
              f"{r['set_count']:>4} {r['clear_count']:>4} {r['check_count']:>4}{anomaly_mark} {maps_str}")
    print()

    # Free ranges
    print("=" * 70)
    print("FREE FLAG SLOTS")
    print("=" * 70)
    total_free = 0
    for s, e in free_ranges:
        count = e - s + 1
        total_free += count
        byte_s = 0xD99B + (s // 8)
        byte_e = 0xD99B + (e // 8)
        label = ""
        if s > max_f:
            label = " [AFTER USED RANGE]"
        elif count >= 8:
            label = " [LARGE BLOCK]"
        print(f"  ${s:04X}-${e:04X}: {count:>4} flags (${byte_s:04X}-${byte_e:04X}){label}")
    print(f"\nTotal free flags: {total_free}")
    print()

    # Anomalies
    set_only = [fid for fid, r in flag_results.items() if r['anomaly'] == 'set_never_checked']
    check_only = [fid for fid, r in flag_results.items() if r['anomaly'] == 'checked_never_set_in_scripts']
    print("=" * 70)
    print("ANOMALIES")
    print("=" * 70)
    print(f"\nSet in scripts but NEVER checked ({len(set_only)}):")
    for fid in set_only:
        r = flag_results[fid]
        print(f"  {r['flag_id']} — set in: {', '.join(r['set_locations'])}")

    print(f"\nChecked but never set/cleared in scripts ({len(check_only)}):")
    print("  (These flags are set by game engine code, not NPC scripts)")
    for fid in check_only:
        r = flag_results[fid]
        print(f"  {r['flag_id']} ({r['check_count']} checks) — {', '.join(r['maps'][:5])}")

    # Top flags
    print()
    print("=" * 70)
    print("TOP 20 MOST-CHECKED FLAGS")
    print("=" * 70)
    by_checks = sorted(flag_results.items(), key=lambda x: x[1]['check_count'], reverse=True)
    for fid, r in by_checks[:20]:
        print(f"  {r['flag_id']} ({r['byte']}.{r['bit']}): {r['check_count']:>3} checks, "
              f"{r['set_count']} sets — {len(r['maps'])} maps")


def export_json(flag_results, free_ranges):
    """Export analysis to JSON."""
    export = {
        'summary': {
            'total_flags': len(flag_results),
            'total_operations': sum(r['total_uses'] for r in flag_results.values()),
            'used_range': [min(flag_results.keys()), max(flag_results.keys())],
            'wram_range': [f'${0xD99B + min(flag_results.keys())//8:04X}',
                           f'${0xD99B + max(flag_results.keys())//8:04X}'],
        },
        'flags': {f'${fid:04X}': r for fid, r in flag_results.items()},
        'free_ranges': [{'start': f'${s:04X}', 'end': f'${e:04X}', 'count': e-s+1}
                        for s, e in free_ranges],
    }
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(export, f, indent=2)
    print(f"Exported to {OUTPUT_PATH}")


if __name__ == '__main__':
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()

    flag_ops = scan_all_flags(rom)
    flag_results = analyze_flags(flag_ops)
    free_ranges = find_free_slots(flag_results)

    if '--json' in sys.argv:
        export_json(flag_results, free_ranges)
    elif '--free' in sys.argv:
        for s, e in free_ranges:
            count = e - s + 1
            print(f"${s:04X}-${e:04X}: {count} flags (${0xD99B+s//8:04X}-${0xD99B+e//8:04X})")
    elif '--flag' in sys.argv:
        idx = sys.argv.index('--flag')
        target = int(sys.argv[idx + 1], 0)
        if target in flag_results:
            r = flag_results[target]
            print(f"Flag {r['flag_id']} ({r['byte']} bit {r['bit']})")
            print(f"  Uses: {r['total_uses']} ({r['set_count']} set, {r['clear_count']} clear, {r['check_count']} check)")
            print(f"  Maps: {', '.join(r['maps'])}")
            if r['set_locations']:
                print(f"  Set in: {', '.join(r['set_locations'])}")
            if r['clear_locations']:
                print(f"  Cleared in: {', '.join(r['clear_locations'])}")
            if r['check_locations']:
                print(f"  Checked in:")
                for loc in r['check_locations']:
                    print(f"    {loc}")
            if r['anomaly']:
                print(f"  ANOMALY: {r['anomaly']}")
        else:
            print(f"Flag ${target:04X} is not used in any script. AVAILABLE for custom use.")
    else:
        print_report(flag_results, free_ranges)
