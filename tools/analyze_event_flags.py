#!/usr/bin/env python3
"""
analyze_event_flags.py — Event flag usage analysis from branch-following
script data.

Reads extracted/all_scripts.json (produced by dump_all_scripts.py with
work-queue branch following) to find all set_flag ($03), clear_flag ($02),
if_flag_set ($01), if_flag_clear ($00) operations across all scripts.

Previous versions scanned ROM linearly and missed ~70% of flag-set
operations hidden behind branches. This version inherits the 93.5%
coverage of dump_all_scripts.py (810/866 WriteRAM ops found).

Produces:
  - Per-flag usage table with set/clear/check counts and locations
  - Free flag slot map (with collision warnings for WriteRAM-targeted bytes)
  - Anomaly detection (set-only, check-only flags)
  - JSON export (extracted/event_flags_complete.json)

Usage:
    python3 tools/analyze_event_flags.py              # Full report
    python3 tools/analyze_event_flags.py --json        # JSON export
    python3 tools/analyze_event_flags.py --free        # Free slots only
    python3 tools/analyze_event_flags.py --flag 0x00F1 # Single flag detail
"""
import json, os, sys
from collections import defaultdict
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
SCRIPTS_PATH = BASE / 'extracted' / 'all_scripts.json'
OUTPUT_PATH  = BASE / 'extracted' / 'event_flags_complete.json'

sys.path.insert(0, str(BASE))
from dwm.map_names import MAP_NAMES


# --- Flag byte collision zones (WriteRAM targets that share bytes with
#     event flag indices). Custom flags must NOT be allocated here. ---
COLLISION_ZONES = {
    0xD9CB: ('unverified',              range(0x0180, 0x0188)),
    0xD9CD: ('Current Coliseum Battle', range(0x0190, 0x0198)),
    0xD9CE: ('Arena round counter',     range(0x0198, 0x01A0)),
    0xD9CF: ('Gate room reset 1',       range(0x01A0, 0x01A8)),
    0xD9D0: ('Gate room reset 2',       range(0x01A8, 0x01B0)),
    0xD9D1: ('Gate room reset 3',       range(0x01B0, 0x01B8)),
    0xD9D2: ('Gate room reset 4',       range(0x01B8, 0x01C0)),
    0xD9D3: ('Gate room reset 5',       range(0x01C0, 0x01C8)),
    0xD9D4: ('Gate room reset 6',       range(0x01C8, 0x01D0)),
    0xD9D5: ('Gate room reset 7',       range(0x01D0, 0x01D8)),
    0xD9D6: ('Gate room reset 8',       range(0x01D8, 0x01E0)),
    0xD9E3: ('Story progression ctr',   range(0x0240, 0x0248)),
    0xD9E6: ('Breeding mutation flag',  range(0x0258, 0x0260)),
    0xD9E9: ('Current step (multi)',    range(0x0270, 0x0278)),
}
COLLISION_FLAG_INDICES = set()
for _, (_, r) in COLLISION_ZONES.items():
    COLLISION_FLAG_INDICES.update(r)

# SRAM save range ends at $D9E9, so flags at byte $D9EA+ won't persist
SRAM_END_BYTE = 0xD9E9
SRAM_END_FLAG = (SRAM_END_BYTE - 0xD99B + 1) * 8 - 1  # $0277


def load_flag_ops():
    """Extract all flag operations from all_scripts.json."""
    if not SCRIPTS_PATH.exists():
        print(f"ERROR: {SCRIPTS_PATH} not found.", file=sys.stderr)
        print("Run: python3 tools/dump_all_scripts.py", file=sys.stderr)
        sys.exit(1)

    with open(SCRIPTS_PATH) as f:
        data = json.load(f)

    flag_ops = []
    for script in data['scripts']:
        map_name = script.get('map_name', f"Map_{script.get('map_type', 0):02X}")
        sid = script.get('script_id', 0)
        bank = script.get('bank', 0)
        cmds = script.get('commands', [])

        for i, cmd in enumerate(cmds):
            if cmd.get('type') != 'opcode':
                continue
            op = cmd['opcode']
            if op not in (0x00, 0x01, 0x02, 0x03):
                continue
            # Next command should be param with the flag index
            if i + 1 >= len(cmds) or cmds[i + 1].get('type') != 'param':
                continue
            flag_idx = cmds[i + 1]['value']
            op_name = {0x00: 'if_flag_clear', 0x01: 'if_flag_set',
                       0x02: 'clear_flag',    0x03: 'set_flag'}[op]
            flag_ops.append({
                'flag': flag_idx,
                'op': op_name,
                'map': map_name,
                'script_id': sid,
                'bank': bank,
            })

    return flag_ops, data.get('script_count', 0)


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
        sets   = [o for o in ops if o['op'] == 'set_flag']
        clears = [o for o in ops if o['op'] == 'clear_flag']
        checks = [o for o in ops if o['op'].startswith('if_flag')]
        maps_involved = sorted(set(o['map'] for o in ops))

        # Deduplicate set/clear/check locations (same map+script counted once)
        def dedup_locs(op_list):
            seen = set()
            out = []
            for o in op_list:
                key = f"{o['map']}_Script{o['script_id']:02d}"
                if key not in seen:
                    seen.add(key)
                    out.append(key)
            return out

        anomaly = None
        if len(sets) > 0 and len(checks) == 0:
            anomaly = 'set_never_checked'
        if len(checks) > 0 and len(sets) == 0 and len(clears) == 0:
            anomaly = 'checked_never_set_in_scripts'

        results[fid] = {
            'flag_id': f'${fid:04X}',
            'byte': f'${byte_addr:04X}',
            'bit': bit,
            'total_uses': len(ops),
            'set_count': len(sets),
            'clear_count': len(clears),
            'check_count': len(checks),
            'maps': maps_involved,
            'set_locations': dedup_locs(sets),
            'clear_locations': dedup_locs(clears),
            'check_locations': dedup_locs(checks),
            'anomaly': anomaly,
        }

    return results


def find_free_slots(flag_results):
    """Find contiguous free flag ranges."""
    used = set(flag_results.keys())
    if not used:
        return []
    max_possible = (0xD9FF - 0xD99B + 1) * 8 - 1  # $0327

    all_indices = set(range(0, max_possible + 1))
    free = sorted(all_indices - used)

    # Group into contiguous ranges
    ranges = []
    if free:
        start = end = free[0]
        for f in free[1:]:
            if f == end + 1:
                end = f
            else:
                ranges.append((start, end))
                start = end = f
        ranges.append((start, end))

    return ranges


def print_report(flag_results, free_ranges, script_count):
    """Print the full text report."""
    used = sorted(flag_results.keys())
    min_f, max_f = min(used), max(used)
    total_ops = sum(r['total_uses'] for r in flag_results.values())
    total_sets = sum(r['set_count'] for r in flag_results.values())
    flags_with_sets = sum(1 for r in flag_results.values() if r['set_count'] > 0)

    print("=" * 70)
    print("DWM1 EVENT FLAG ANALYSIS — Branch-Following Script Data")
    print("=" * 70)
    print(f"Source:                extracted/all_scripts.json")
    print(f"Scripts analyzed:      {script_count}")
    print(f"Total flag operations: {total_ops}")
    print(f"  set_flag:            {total_sets} ({flags_with_sets} unique flags)")
    print(f"Unique flags used:     {len(used)}")
    print(f"Used range:            ${min_f:04X} - ${max_f:04X}")
    print(f"WRAM range:            ${0xD99B + min_f//8:04X} - ${0xD99B + max_f//8:04X}")
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
    safe_free = 0
    for s, e in free_ranges:
        count = e - s + 1
        total_free += count
        byte_s = 0xD99B + (s // 8)
        byte_e = 0xD99B + (e // 8)
        # Check for collision or out-of-save-range
        collision = any(f in COLLISION_FLAG_INDICES for f in range(s, e + 1))
        past_sram = s > SRAM_END_FLAG
        label = ""
        if collision:
            label = " [COLLISION — WriteRAM target]"
        elif past_sram:
            label = " [OUTSIDE SRAM — will not persist in save]"
        else:
            safe_free += count
        print(f"  ${s:04X}-${e:04X}: {count:>4} flags (${byte_s:04X}-${byte_e:04X}){label}")
    print(f"\nTotal free: {total_free}   Safe+persistent: {safe_free}")
    print()

    # Anomalies
    set_only   = [fid for fid, r in flag_results.items()
                  if r['anomaly'] == 'set_never_checked']
    check_only = [fid for fid, r in flag_results.items()
                  if r['anomaly'] == 'checked_never_set_in_scripts']
    print("=" * 70)
    print("ANOMALIES")
    print("=" * 70)
    print(f"\nSet in scripts but NEVER checked ({len(set_only)}):")
    for fid in set_only:
        r = flag_results[fid]
        print(f"  {r['flag_id']} — set in: {', '.join(r['set_locations'][:5])}")

    print(f"\nChecked but never set/cleared in ANY decoded script ({len(check_only)}):")
    print("  (May be set in unreached branches — 6.5% of script data is")
    print("   not covered by branch following. Or set by engine code.)")
    for fid in check_only:
        r = flag_results[fid]
        print(f"  {r['flag_id']} ({r['check_count']} checks) — {', '.join(r['maps'][:5])}")

    # Top flags
    print()
    print("=" * 70)
    print("TOP 20 MOST-CHECKED FLAGS")
    print("=" * 70)
    by_checks = sorted(flag_results.items(),
                       key=lambda x: x[1]['check_count'], reverse=True)
    for fid, r in by_checks[:20]:
        set_info = f", set in {', '.join(r['set_locations'][:2])}" if r['set_count'] else ", ENGINE-SET"
        if r['anomaly'] == 'checked_never_set_in_scripts':
            set_info = ", NOT FOUND in decoded scripts"
        print(f"  {r['flag_id']} ({r['byte']}.{r['bit']}): {r['check_count']:>3} checks"
              f"{set_info}")


def export_json(flag_results, free_ranges, script_count):
    """Export analysis to JSON."""
    total_sets = sum(r['set_count'] for r in flag_results.values())
    flags_with_sets = sum(1 for r in flag_results.values() if r['set_count'] > 0)
    export = {
        '_generator': 'tools/analyze_event_flags.py (from extracted/all_scripts.json)',
        '_note': 'Branch-following data. 93.5% coverage of script code paths.',
        'summary': {
            'total_flags': len(flag_results),
            'total_operations': sum(r['total_uses'] for r in flag_results.values()),
            'total_set_ops': total_sets,
            'flags_with_sets': flags_with_sets,
            'scripts_analyzed': script_count,
            'used_range': [min(flag_results.keys()), max(flag_results.keys())],
            'wram_range': [f'${0xD99B + min(flag_results.keys())//8:04X}',
                           f'${0xD99B + max(flag_results.keys())//8:04X}'],
        },
        'flags': {f'${fid:04X}': r for fid, r in flag_results.items()},
        'free_ranges': [{'start': f'${s:04X}', 'end': f'${e:04X}', 'count': e - s + 1}
                        for s, e in free_ranges],
        'collision_zones': {
            f'${addr:04X}': {
                'name': name,
                'flag_range': f'${r.start:04X}-${r.stop-1:04X}',
            }
            for addr, (name, r) in COLLISION_ZONES.items()
        },
        'sram_end_flag': f'${SRAM_END_FLAG:04X}',
    }
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(export, f, indent=2)
    print(f"Exported {len(flag_results)} flags to {OUTPUT_PATH}")


if __name__ == '__main__':
    flag_ops, script_count = load_flag_ops()
    flag_results = analyze_flags(flag_ops)
    free_ranges = find_free_slots(flag_results)

    if '--json' in sys.argv:
        export_json(flag_results, free_ranges, script_count)
    elif '--free' in sys.argv:
        for s, e in free_ranges:
            count = e - s + 1
            byte_s = 0xD99B + (s // 8)
            byte_e = 0xD99B + (e // 8)
            collision = any(f in COLLISION_FLAG_INDICES for f in range(s, e + 1))
            past_sram = s > SRAM_END_FLAG
            tag = ''
            if collision:   tag = ' [COLLISION]'
            elif past_sram: tag = ' [NO PERSIST]'
            print(f"${s:04X}-${e:04X}: {count} flags (${byte_s:04X}-${byte_e:04X}){tag}")
    elif '--flag' in sys.argv:
        idx = sys.argv.index('--flag')
        target = int(sys.argv[idx + 1], 0)
        if target in flag_results:
            r = flag_results[target]
            print(f"Flag {r['flag_id']} ({r['byte']} bit {r['bit']})")
            print(f"  Uses: {r['total_uses']} ({r['set_count']} set, "
                  f"{r['clear_count']} clear, {r['check_count']} check)")
            print(f"  Maps: {', '.join(r['maps'])}")
            if r['set_locations']:
                print(f"  Set in:")
                for loc in r['set_locations']:
                    print(f"    {loc}")
            if r['clear_locations']:
                print(f"  Cleared in:")
                for loc in r['clear_locations']:
                    print(f"    {loc}")
            if r['check_locations']:
                print(f"  Checked in:")
                for loc in r['check_locations']:
                    print(f"    {loc}")
            if r['anomaly']:
                print(f"  ANOMALY: {r['anomaly']}")
        else:
            print(f"Flag ${target:04X} not used in any decoded script. "
                  f"AVAILABLE for custom use.")
    else:
        print_report(flag_results, free_ranges, script_count)
