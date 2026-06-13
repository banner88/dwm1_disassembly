#!/usr/bin/env python3
"""
decompile_script.py — Decompile NPC script data into readable pseudo-code.

Usage:
    python3 tools/decompile_script.py <bank> <addr>           # Single script
    python3 tools/decompile_script.py --map <bank> <map_type> # All scripts for a map
    python3 tools/decompile_script.py --all <bank>            # All scripts in bank
"""
import json, os, sys, argparse

ROM_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data', 'DWM-original.gbc')
TEXT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'extracted', 'text_id_map.json')

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dwm.map_names import MAP_NAMES  # canonical room names (97 entries)

# Verified opcode parameter counts from handler analysis + empirical data
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

# Branch opcodes: maps opcode -> index within params[] that holds the target.
# Derived from format_cmd (every opcode whose output contains "goto .addr_").
BRANCH_TARGET_PARAM = {
    0x00: 1,   # if_flag_clear:       [flag_idx, target]
    0x01: 1,   # if_flag_set:         [flag_idx, target]
    0x0E: 1,   # branch_by_screen:    [screen, target]
    0x14: 0,   # goto:                [target]           UNCONDITIONAL
    0x15: 2,   # cond_branch:         [ram_addr, value, target]
    0x27: 0,   # post_battle_check:   [target]
    0x28: 0,   # check_storage_full:  [target]
    0x2C: 0,   # check_inv_full:      [target]
    0x37: 1,   # check_story_region:  [region, target]
}

UNCONDITIONAL_JUMPS = {0x14}  # goto — no fall-through
TERMINATORS = {0x16}          # return — ends current execution path

def _s16(v):
    """Format as signed 16-bit."""
    if v >= 0x8000: return str(v - 0x10000)
    return f'+{v}' if v > 0 else '0'

def load_texts():
    try:
        with open(TEXT_PATH) as f:
            raw = json.load(f)
        return {int(k): (v.get('text','') if isinstance(v,dict) else str(v))[:50]
                for k,v in raw.items()}
    except: return {}

def rw(rom, bank, addr):
    off = bank * 0x4000 + (addr - 0x4000)
    return rom[off] | (rom[off+1] << 8)

def is_opcode(val):
    return (val >> 8) == 0xFF and (val & 0xFF) <= 0x63

def format_cmd(opcode, params):
    """Format a single opcode + params into readable pseudo-code."""
    p = params  # shorthand
    lo = [v & 0xFF for v in p]  # low bytes (C register values)
    
    # Flow control
    if opcode == 0x00: return f'if_flag_clear ${p[0]:04X}, goto .addr_{p[1]:04X}'
    if opcode == 0x01: return f'if_flag_set ${p[0]:04X}, goto .addr_{p[1]:04X}'
    if opcode == 0x08: return 'nop'
    if opcode == 0x0E: return f'branch_by_screen {lo[0]}, goto .addr_{p[1]:04X}'
    if opcode == 0x14: return f'goto .addr_{p[0]:04X}'
    if opcode == 0x15: return f'cond_branch ${p[0]:04X}, ${p[1]:04X}, goto .addr_{p[2]:04X}'
    if opcode == 0x16: return 'return'
    
    # Event flags  
    if opcode == 0x02: return f'clear_flag ${p[0]:04X}'
    if opcode == 0x03: return f'set_flag ${p[0]:04X}'
    
    # NPC movement (VERIFIED: $1A=X-axis, $1B=Y-axis)
    if opcode == 0x0A: return f'npc_move_x npc#{lo[0]}, {_s16(p[1])}'
    if opcode == 0x0B: return f'npc_move_y npc#{lo[0]}, {_s16(p[1])}'
    if opcode == 0x1A: return f'npc_walk_x npc#{lo[0]}, {_s16(p[1])}'
    if opcode == 0x1B: return f'npc_walk_y npc#{lo[0]}, {_s16(p[1])}'
    if opcode == 0x0C: return f'npc_facing npc#{lo[0]}, dir={lo[1]}, ${p[2]:04X}'
    if opcode == 0x0D:
        if lo[0] == 0:
            return f'write_ram [${p[1]:04X}] = ${lo[2]:02X}'
        return f'npc_write npc#{lo[0]}, field[${p[1]:04X}] = ${lo[2]:02X}'
    if opcode == 0x10: return f'npc_moveto npc#{lo[0]}, ${p[1]:04X}'
    if opcode == 0x11: return f'npc_moveto2 npc#{lo[0]}, ${p[1]:04X}, ${p[2]:04X}, ${p[3]:04X}'
    if opcode == 0x1C:
        hi, lo = (p[0] >> 8) & 0xFF, p[0] & 0xFF
        anim = {1:'jump',2:'anim2'}.get(hi, f'anim_{hi}')
        return f'trigger_anim npc#{lo}, {anim}'
    if opcode == 0x1D: return 'lock_movement'
    if opcode == 0x1E: return 'unlock_movement'
    if opcode == 0x22: return 'begin_walk'
    if opcode == 0x44: return 'npc_set_pos_and_face'
    if opcode == 0x46: return f'check_dungeon_flags ${p[0]:04X}'
    if opcode == 0x47: return f'npc_buffer_write npc#{lo[0]}'
    if opcode == 0x48: return f'npc_hide npc#{lo[0]}'
    if opcode == 0x49: return f'npc_show npc#{lo[0]}'
    
    # Timer/delay
    if opcode == 0x09: return f'delay {lo[0]} frames'
    if opcode == 0x19: return 'wait_movement'
    if opcode == 0x4C: return f'long_delay {lo[0]} frames'
    if opcode == 0x3B: return 'map_transition_fade'
    if opcode == 0x3C: return 'set_secondary_delay'
    
    # Screen/map
    if opcode == 0x04: return f'screen_effect ${p[0]:04X}, ${p[1]:04X}'
    if opcode == 0x0F: return f'map_transition map=${lo[0]}, gate=${lo[1]}, ${p[2]:04X}'
    if opcode == 0x17: return f'gate_setup ${p[0]:04X}'
    if opcode == 0x18: return 'fade'
    if opcode == 0x26: return 'suppress_movement'
    if opcode == 0x3A: return f'gate_transition ${p[0]:04X}, ${p[1]:04X}, ${p[2]:04X}'
    if opcode == 0x41: return f'set_bgm ${p[0]:04X}, ${p[1]:04X}'
    if opcode == 0x42: return 'save_map_return'
    if opcode == 0x4D: return 'set_long_delay'
    if opcode == 0x4E: return 'save_gate_info'
    
    # Battle
    if opcode == 0x05: return f'battle enemy=${p[0]:04X}'
    if opcode == 0x1F: return 'arena_battle_setup'
    if opcode == 0x20: return f'set_battle_mode ${p[0]:04X}'
    if opcode == 0x35: return 'boss_encounter_setup'
    if opcode == 0x36: return f'setup_boss ${p[0]:04X}'
    if opcode == 0x59: return f'battle3 ${p[0]:04X}'
    
    # Sound
    if opcode == 0x40: return f'check_monster_bgm ${p[0]:04X}'
    if opcode == 0x4A: return 'read_saved_bgm'
    if opcode == 0x4B: return 'restore_bgm'
    
    # State
    if opcode == 0x06: return 'inc_counter'
    if opcode == 0x07: return f'init_dialog ${p[0]:04X}'
    if opcode == 0x2C: return f'check_inv_full, goto .addr_{p[0]:04X}'
    if opcode == 0x2D: return f'monster_slot_dialogue slot={p[0]:d}'
    if opcode == 0x3D: return 'clear_secondary_delay'
    
    # Monster/inventory
    if opcode == 0x27: return f'post_battle_check, goto .addr_{p[0]:04X}'
    if opcode == 0x28: return f'check_storage_full, goto .addr_{p[0]:04X}'
    if opcode == 0x29: return f'add_monster enemy=${p[0]:04X}'
    if opcode == 0x2A: return f'give_item ${p[0]:04X}'
    if opcode == 0x2B: return f'check_monster_level ${p[0]:04X}'
    
    if opcode == 0x12: return f'write_ram [${p[0]:04X}] = ${p[1]:04X}'
    if opcode == 0x13: return f'write_ram2 [${p[0]:04X}] = ${p[1]:04X}'
    if opcode == 0x24: return 'update_screen_vram'
    if opcode == 0x21: return f'screen_setup ${p[0]:04X}, ${p[1]:04X}'
    if opcode == 0x37: return f'check_story_region ${p[0]:04X}, goto .addr_{p[1]:04X}'
    if opcode == 0x33: return f'skip_data ${p[0]:04X}, ${p[1]:04X}'
    if opcode == 0x31: return f'check_party_level ${p[0]:04X}, ${p[1]:04X}'
    if opcode == 0x51: return f'check_and_branch'
    if opcode == 0x61: return 'call_script_bank_e2'
    if opcode == 0x5A: return 'trigger_battle3'

    # Generic fallback
    pstr = ', '.join(f'${v:04X}' for v in p)
    return f'cmd_{opcode:02X} {pstr}'.strip()


def decompile_script(rom, bank, start_addr, texts, label=None):
    """Decompile a single script, following all branch targets.

    Uses a work queue seeded with start_addr.  For each reachable address,
    decodes linearly until $FFFF, return ($16), goto ($14), or an
    already-visited address.  Branch target addresses are added to the queue.
    """
    base = bank * 0x4000
    branch_targets = set()  # addresses reached via branch opcodes
    decoded = []            # (addr, line_str) tuples
    visited = set()         # decoded addresses

    queue = [start_addr]
    total = 0
    MAX_WORDS = 4096

    while queue:
        pos = queue.pop(0)
        if pos in visited:
            continue
        if not (0x4000 <= pos < 0x7FFF):
            continue

        while total < MAX_WORDS:
            if pos in visited:
                break
            if not (0x4000 <= pos < 0x7FFF):
                break

            off = base + (pos - 0x4000)
            if off + 1 >= base + 0x4000:
                break
            val = rom[off] | (rom[off + 1] << 8)
            visited.add(pos)
            total += 1

            if val == 0xFFFF:
                decoded.append((pos, '    end'))
                break

            if is_opcode(val):
                op = val & 0xFF
                pc = PARAM_COUNTS.get(op, 0)
                params = []
                for i in range(pc):
                    poff = off + (1 + i) * 2
                    pv = rom[poff] | (rom[poff + 1] << 8)
                    params.append(pv)
                    visited.add(pos + (1 + i) * 2)
                    total += 1

                decoded.append((pos, f'    {format_cmd(op, params)}'))

                # Check for branch target
                tidx = BRANCH_TARGET_PARAM.get(op)
                if tidx is not None and tidx < len(params):
                    target = params[tidx]
                    if 0x4000 <= target < 0x8000:
                        branch_targets.add(target)
                        queue.append(target)

                pos += (1 + pc) * 2

                # Unconditional jump or terminator: stop linear
                if op in UNCONDITIONAL_JUMPS or op in TERMINATORS:
                    break
            else:
                # Text ID
                if val in texts:
                    txt = texts[val].replace('\n', ' // ')[:45]
                    decoded.append((pos, f'    say ${val:04X}  ; "{txt}"'))
                else:
                    decoded.append((pos, f'    say ${val:04X}'))
                pos += 2

    # Sort by address and build output
    decoded.sort(key=lambda x: x[0])

    lines = []
    if label:
        lines.append(f'{label}:')

    prev_addr = None
    for addr, line in decoded:
        # Insert separator for non-contiguous blocks
        if prev_addr is not None and addr > prev_addr + 2:
            lines.append('')
        # Insert label at branch targets
        if addr in branch_targets:
            lines.append(f'.addr_{addr:04X}:')
        lines.append(line)
        # Track end of this instruction (find its size from the line)
        prev_addr = addr

    return '\n'.join(lines)


def decompile_map(rom, bank, map_type, texts):
    """Decompile all scripts for a map type."""
    base = bank * 0x4000
    tbl_addr = 0x41BA + map_type * 2
    tbl_ptr = rw(rom, bank, tbl_addr)
    
    name = MAP_NAMES.get(map_type, f'Map{map_type:02X}')
    
    # Read script pointers
    scripts = []
    a = tbl_ptr
    while len(scripts) < 100:
        ptr = rw(rom, bank, a)
        if ptr < 0x4000 or ptr > 0x7FFF: break
        scripts.append(ptr)
        a += 2
    
    output = []
    output.append(f'; === {name} (map_type=${map_type:02X}, bank ${bank:02X}) ===')
    output.append(f'; {len(scripts)} scripts')
    output.append('')
    
    for i, ptr in enumerate(scripts):
        label = f'{name}_Script{i:02d}'
        result = decompile_script(rom, bank, ptr, texts, label)
        output.append(result)
        output.append('')
    
    return '\n'.join(output)


if __name__ == '__main__':
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()
    texts = load_texts()
    
    if len(sys.argv) >= 3 and sys.argv[1] == '--map':
        bank = int(sys.argv[2], 0)
        mt = int(sys.argv[3], 0)
        print(decompile_map(rom, bank, mt, texts))
    elif len(sys.argv) >= 3:
        bank = int(sys.argv[1], 0)
        addr = int(sys.argv[2], 0)
        label = sys.argv[3] if len(sys.argv) > 3 else None
        print(decompile_script(rom, bank, addr, texts, label))
    else:
        print("Usage:")
        print("  decompile_script.py <bank> <addr> [label]")
        print("  decompile_script.py --map <bank> <map_type>")
