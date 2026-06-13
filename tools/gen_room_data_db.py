"""Generate labeled db/dw blocks for Bank $0B room data.

Reads the ROM and outputs the room data section ($4B43-end) of bank_00b.asm
with proper labels, field-level db/dw entries, and comments.

Usage:
    python -m tools.gen_room_data_db > output.asm
    python -m tools.gen_room_data_db --stats
"""

import sys
import argparse
from pathlib import Path
from collections import OrderedDict

BANK = 0x0B
BANK_SIZE = 0x4000
TABLE_ADDR = 0x4B43
NUM_ENTRIES = 107  # mt $00-$6A

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dwm.map_names import MAP_NAMES  # canonical room names (97 entries)


def flat(local):
    return BANK * BANK_SIZE + (local - 0x4000)


def r16(rom, off):
    return rom[off] | (rom[off + 1] << 8)


def mt_name(mt):
    return MAP_NAMES.get(mt, f"mt{mt:02X}")


def is_valid_step_block(rom, ptr):
    """Check if ptr points to a valid step block (byte+1 == $D9)."""
    if not (0x4000 <= ptr <= 0x7FFF):
        return False
    f = flat(ptr)
    return f + 1 < len(rom) and rom[f + 1] == 0xD9


def count_sub_screens(rom, sub_ptr):
    """Count sub-table entries using gap-based detection.
    
    Size = (first valid step block pointer - sub_ptr) / 2.
    Falls back to scanning for valid entries up to 32.
    """
    f = flat(sub_ptr)
    # Find the smallest valid step block pointer in the sub-table
    min_block = 0x8000
    for i in range(32):
        val = r16(rom, f + i * 2)
        if val == 0xFFFF:
            continue
        if is_valid_step_block(rom, val):
            min_block = min(min_block, val)
        else:
            break  # hit non-valid, non-$FFFF entry → end of table
    
    if min_block < 0x8000:
        size = (min_block - sub_ptr) // 2
        if size >= 1:
            return size
    return 0


def parse_interact_block(rom, local_addr):
    """Parse 5-byte-entry interact block. Returns (entries, size)."""
    f = flat(local_addr)
    entries = []
    pos = 0
    for _ in range(64):
        if f + pos >= len(rom) or rom[f + pos] == 0xFF:
            pos += 1
            break
        entries.append(bytes(rom[f + pos:f + pos + 5]))
        pos += 5
    return entries, pos


def parse_exit_block(rom, local_addr):
    """Parse 7-byte-entry exit block. Returns (entries, size)."""
    f = flat(local_addr)
    entries = []
    pos = 0
    for _ in range(32):
        if f + pos >= len(rom) or rom[f + pos] == 0xFF:
            pos += 1
            break
        entries.append(bytes(rom[f + pos:f + pos + 7]))
        pos += 7
    return entries, pos


def parse_step_block(rom, local_addr):
    """Parse step block. Returns (ram, steps, total_bytes)."""
    f = flat(local_addr)
    ram = r16(rom, f)
    steps = []
    off = 2
    for _ in range(16):
        step_id = rom[f + off]
        tileset = rom[f + off + 1]
        interact = r16(rom, f + off + 2)
        exit_p = r16(rom, f + off + 4)
        if not (0x4000 <= interact <= 0x7FFF):
            break
        steps.append({
            'step_id': step_id, 'tileset_bank': tileset,
            'interact_ptr': interact, 'exit_ptr': exit_p,
        })
        off += 6
    return ram, steps, off


def format_interact_entry(b):
    typ = b[0]
    if typ >= 0x80:
        type_name = {0x8F: "spawn", 0x90: "walk_exit"}.get(typ, f"spc_{typ:02X}")
        dest = mt_name(b[4]) if b[4] < NUM_ENTRIES else f"${b[4]:02X}"
        return (f"    db ${b[0]:02X}, ${b[1]:02X}, ${b[2]:02X}, ${b[3]:02X}, ${b[4]:02X}"
                f"  ; {type_name} ({b[2]},{b[3]}) mt${b[4]:02X} {dest}")
    else:
        facing = ['down', 'left', 'up', 'right'][(typ >> 4) & 3]
        noint = "noTalk " if typ & 0x40 else ""
        behav = typ & 0x0F
        scr = "none" if b[4] == 0xFF else f"${b[4]:02X}"
        return (f"    db ${b[0]:02X}, ${b[1]:02X}, ${b[2]:02X}, ${b[3]:02X}, ${b[4]:02X}"
                f"  ; NPC {noint}{facing} b={behav} spr=${b[1]:02X} ({b[2]},{b[3]}) script={scr}")


def format_exit_entry(b):
    if b[0] == 0x00:
        return (f"    db ${b[0]:02X}, ${b[1]:02X}, ${b[2]:02X}, ${b[3]:02X}, "
                f"${b[4]:02X}, ${b[5]:02X}, ${b[6]:02X}"
                f"  ; arrival marker (skipped)")
    if b[0] == 0x09:
        return (f"    db ${b[0]:02X}, ${b[1]:02X}, ${b[2]:02X}, ${b[3]:02X}, "
                f"${b[4]:02X}, ${b[5]:02X}, ${b[6]:02X}"
                f"  ; special marker (skipped)")
    dest = mt_name(b[2]) if b[2] < NUM_ENTRIES else f"${b[2]:02X}"
    gate_str = "gate" if b[3] else ""
    scr_idx = b[4] & 0x7F
    y_flag = "+Y8" if b[4] & 0x80 else ""
    return (f"    db ${b[0]:02X}, ${b[1]:02X}, ${b[2]:02X}, ${b[3]:02X}, "
            f"${b[4]:02X}, ${b[5]:02X}, ${b[6]:02X}"
            f"  ; exit ({b[0]},{b[1]})→mt${b[2]:02X} {dest} {gate_str}"
            f" scr={scr_idx}{y_flag} spawn({b[5]},{b[6]})")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", default="data/DWM-original.gbc")
    ap.add_argument("--stats", action="store_true")
    args = ap.parse_args()

    rom = bytearray(Path(args.rom).read_bytes())

    # ── Read pointer table ──
    ptr_table = [r16(rom, flat(TABLE_ADDR + mt * 2)) for mt in range(NUM_ENTRIES)]

    # ── Find unique sub-tables ──
    unique_subs = OrderedDict()
    for mt, ptr in enumerate(ptr_table):
        if ptr == 0xFFFF or not (0x4000 <= ptr <= 0x7FFF):
            continue
        if ptr not in unique_subs:
            unique_subs[ptr] = []
        unique_subs[ptr].append(mt)

    # ── Parse all rooms ──
    rooms = OrderedDict()
    all_step_blocks = OrderedDict()   # addr → data
    all_interact_blocks = OrderedDict()  # addr → data
    all_exit_blocks = OrderedDict()      # addr → data

    for sub_ptr, mt_list in unique_subs.items():
        num_screens = count_sub_screens(rom, sub_ptr)
        if num_screens == 0:
            continue  # Skip invalid sub-tables (mt$68/$69)

        primary_mt = mt_list[0]
        f = flat(sub_ptr)
        screens_raw = [r16(rom, f + i * 2) for i in range(num_screens)]

        parsed_screens = []
        for scr_idx, blk_ptr in enumerate(screens_raw):
            if blk_ptr == 0xFFFF or not is_valid_step_block(rom, blk_ptr):
                parsed_screens.append(None)
                continue

            ram, steps, size = parse_step_block(rom, blk_ptr)
            step_data = {'ptr': blk_ptr, 'ram': ram, 'steps': steps, 'size': size,
                         'mt': primary_mt, 'scr': scr_idx}

            if blk_ptr not in all_step_blocks:
                all_step_blocks[blk_ptr] = step_data

            for step in steps:
                iptr = step['interact_ptr']
                if iptr == 0x4B42 and iptr not in all_interact_blocks:
                    # $4B42 is the $FF byte of `rst $38` in code section —
                    # data reuse as empty interact terminator. Track but don't emit.
                    all_interact_blocks[iptr] = {
                        'entries': [], 'size': 1,
                        'mt': primary_mt, 'scr': scr_idx,
                        'code_reuse': True,
                    }
                elif iptr not in all_interact_blocks and 0x4000 <= iptr <= 0x7FFF:
                    entries, isize = parse_interact_block(rom, iptr)
                    all_interact_blocks[iptr] = {
                        'entries': entries, 'size': isize,
                        'mt': primary_mt, 'scr': scr_idx,
                    }

                eptr = step['exit_ptr']
                if eptr not in all_exit_blocks and 0x4000 <= eptr <= 0x7FFF:
                    entries, esize = parse_exit_block(rom, eptr)
                    all_exit_blocks[eptr] = {
                        'entries': entries, 'size': esize,
                        'mt': primary_mt, 'scr': scr_idx,
                    }
                # exit=$0000 or $FFFF: skip (handled by code, not data)

            parsed_screens.append(step_data)

        rooms[sub_ptr] = {
            'sub_ptr': sub_ptr, 'mt_list': mt_list,
            'primary_mt': primary_mt, 'name': mt_name(primary_mt),
            'num_screens': num_screens, 'screens_raw': screens_raw,
            'screens': parsed_screens,
        }

    if args.stats:
        print(f"Unique sub-tables: {len(rooms)}")
        print(f"Unique step blocks: {len(all_step_blocks)}")
        print(f"Unique interact blocks: {len(all_interact_blocks)}")
        print(f"Unique exit blocks: {len(all_exit_blocks)}")
        total_npcs = sum(sum(1 for e in i['entries'] if e[0] < 0x80)
                        for i in all_interact_blocks.values())
        total_spawns = sum(sum(1 for e in i['entries'] if e[0] >= 0x80)
                         for i in all_interact_blocks.values())
        total_exits = sum(len(i['entries']) for i in all_exit_blocks.values())
        print(f"Total NPC entries: {total_npcs}")
        print(f"Total spawn entries: {total_spawns}")
        print(f"Total exit entries: {total_exits}")
        return

    # ── Build labels (with variant numbering to avoid duplicates) ──
    sub_labels = {}
    for sub_ptr, room in rooms.items():
        sub_labels[sub_ptr] = f"RoomSub_{room['name']}"

    step_labels = {}
    step_ranges = {}  # addr → (start, end) for overlap detection
    for addr, data in all_step_blocks.items():
        step_labels[addr] = f"StepBlk_{mt_name(data['mt'])}_s{data['scr']}"
        step_ranges[addr] = (addr, addr + data['size'])

    # Build set of all occupied ranges (sub-tables + step blocks + interact + exit)
    occupied = []  # (start, end) sorted
    for addr, room in rooms.items():
        if addr >= TABLE_ADDR + NUM_ENTRIES * 2:  # skip ptr-table overlap
            occupied.append((addr, addr + room['num_screens'] * 2))
    for addr, data in all_step_blocks.items():
        occupied.append((addr, addr + data['size']))
    for addr, info in all_interact_blocks.items():
        if not info.get('code_reuse'):
            occupied.append((addr, addr + info['size']))
    for addr, info in all_exit_blocks.items():
        occupied.append((addr, addr + info['size']))
    occupied.sort()

    def is_inside_other_block(addr, size):
        """Check if addr falls inside an existing block's range (even partially)."""
        for ostart, oend in occupied:
            if ostart < addr < oend:  # addr strictly inside another block
                return True
        return False

    # For interact/exit: group by (mt, scr) and number variants
    # Skip labels for blocks inside other blocks' ranges
    interact_labels = {}
    _interact_counters = {}
    for addr, info in sorted(all_interact_blocks.items()):
        if info.get('code_reuse'):
            continue
        if is_inside_other_block(addr, info['size']):
            continue  # inside another block, use raw address
        key = (info['mt'], info['scr'])
        n = _interact_counters.get(key, 0)
        _interact_counters[key] = n + 1
        suffix = f"_v{n}" if n > 0 else ""
        interact_labels[addr] = f"Interact_{mt_name(info['mt'])}_s{info['scr']}{suffix}"

    exit_labels = {}
    _exit_counters = {}
    for addr, info in sorted(all_exit_blocks.items()):
        if is_inside_other_block(addr, info['size']):
            continue
        key = (info['mt'], info['scr'])
        n = _exit_counters.get(key, 0)
        _exit_counters[key] = n + 1
        suffix = f"_v{n}" if n > 0 else ""
        exit_labels[addr] = f"Exit_{mt_name(info['mt'])}_s{info['scr']}{suffix}"

    # ── jr_ labels embedded in pointer table ──
    jr_labels = {0x4B50: "jr_00b_4b50", 0x4B60: "jr_00b_4b60", 0x4B70: "jr_00b_4b70"}

    ptr_table_end = TABLE_ADDR + NUM_ENTRIES * 2  # $4C19

    # ── Build unified address-ordered output ──
    DATA_END = 0x8000    # end of bank

    # ── Output ──
    lines = []
    lines.append("; =============================================================================")
    lines.append("; ROOM DATA SECTION ($4B43 - $7FFF)")
    lines.append("; Generated by tools/gen_room_data_db.py from ROM data")
    lines.append("; =============================================================================")
    lines.append(";")
    lines.append("; Pointer chain: RoomPtrTable[mapID×2] → sub_table → step_block")
    lines.append(";   Sub-table: 8 × dw screen_ptrs ($FFFF = unused screen)")
    lines.append(";   Step block: dw ram_counter + steps × [step_id, tileset_bank, dw interact, dw exit]")
    lines.append(";   Interact: 5-byte entries (NPC/spawn), $FF terminated")
    lines.append(";   Exit: 7-byte entries (walk-on triggers), $FF terminated")
    lines.append(";")
    lines.append("; NPC entry:  [type, sprite, x, y, script]")
    lines.append(";   type bits 5-4=facing (0=down,1=left,2=up,3=right)")
    lines.append(";   type bit 6=non-interactable, bits 3-0=behavior")
    lines.append("; Spawn entry: [type($8F/$90), param, x, y, source_mt]")
    lines.append("; Exit entry: [trig_x, trig_y, dest_mt, gate_flag, screen, spawn_x, spawn_y]")
    lines.append("")

    # ── Build ptr → label mapping for labeled pointer output ──
    ptr_table_end_addr = TABLE_ADDR + NUM_ENTRIES * 2
    ptr_to_label = {}  # ptr_value → label_name
    # Labels for sub-tables that start AFTER the pointer table (clean case)
    for sub_ptr, room in rooms.items():
        if sub_ptr >= ptr_table_end_addr:
            ptr_to_label[sub_ptr] = sub_labels[sub_ptr]
    # Labels for sub-tables that overlap the pointer table
    # Create an inline label at the overlap address
    overlap_labels = {}  # addr_within_ptrtable → label_name
    for sub_ptr, room in rooms.items():
        if TABLE_ADDR <= sub_ptr < ptr_table_end_addr:
            lbl = sub_labels[sub_ptr]
            overlap_labels[sub_ptr] = lbl
            ptr_to_label[sub_ptr] = lbl

    # ── Pointer table ──
    lines.append(f"RoomPtrTable:  ; {NUM_ENTRIES} entries × 2B, indexed by wMapID ($C968)")

    for mt in range(NUM_ENTRIES):
        addr = TABLE_ADDR + mt * 2
        ptr = ptr_table[mt]
        name = mt_name(mt)

        alias_str = ""
        if ptr in rooms and rooms[ptr]['primary_mt'] != mt:
            alias_str = f" (=mt${rooms[ptr]['primary_mt']:02X})"

        # Check if an overlap label needs to be inserted at this address
        if addr in overlap_labels:
            lines.append(f"{overlap_labels[addr]}:  ; overlaps pointer table at ${addr:04X}")

        if addr in jr_labels:
            lo, hi = ptr & 0xFF, (ptr >> 8) & 0xFF
            lines.append(f"    db ${lo:02X}  ; ${mt:02X} {name} ptr low")
            lines.append(f"{jr_labels[addr]}:")
            lines.append(f"    db ${hi:02X}  ; ${mt:02X} {name} ptr high → ${ptr:04X}")
        elif addr + 1 in jr_labels:
            lo, hi = ptr & 0xFF, (ptr >> 8) & 0xFF
            lines.append(f"    db ${lo:02X}  ; ${mt:02X} {name} ptr low")
            lines.append(f"{jr_labels[addr + 1]}:")
            lines.append(f"    db ${hi:02X}  ; ${mt:02X} {name} ptr high → ${ptr:04X}")
        else:
            if ptr == 0xFFFF:
                lines.append(f"    dw $FFFF  ; ${mt:02X} {name} (unused)")
            elif ptr in ptr_to_label:
                lines.append(f"    dw {ptr_to_label[ptr]}  ; ${mt:02X} {name}{alias_str}")
            else:
                lines.append(f"    dw ${ptr:04X}  ; ${mt:02X} {name}{alias_str}")

    lines.append("")
    lines.append("; --- ROOM DATA BLOCKS ---")

    # ── Build address → labels map for ALL blocks ──
    addr_labels = {}  # addr → list of (label, comment)
    addr_block_size = {}  # addr → expected size
    
    for addr, room in rooms.items():
        size = room['num_screens'] * 2
        if addr < ptr_table_end:
            # Overlapping sub-table: label only for the portion after ptr table
            eff_start = ptr_table_end
            overlap = (ptr_table_end - addr) // 2
            remaining = room['num_screens'] - overlap
            if remaining > 0:
                lbl = sub_labels.get(addr, f"RoomSub_{addr:04X}")
                mt_str = ", ".join(f"${mt:02X}" for mt in room['mt_list'])
                comment = f"; ${addr:04X} — mt=[{mt_str}] (first {overlap} slots in ptr table)"
                addr_labels.setdefault(eff_start, []).append((lbl + "_cont", comment))
                addr_block_size[eff_start] = remaining * 2
        else:
            lbl = sub_labels.get(addr, f"RoomSub_{addr:04X}")
            mt_str = ", ".join(f"${mt:02X}" for mt in room['mt_list'])
            comment = f"; ${addr:04X} — mt=[{mt_str}]"
            addr_labels.setdefault(addr, []).append((lbl, comment))
            addr_block_size[addr] = size
    
    for addr, data in all_step_blocks.items():
        lbl = step_labels.get(addr, f"StepBlk_{addr:04X}")
        comment = f"; ${addr:04X} — RAM=${data['ram']:04X}, {len(data['steps'])} steps"
        addr_labels.setdefault(addr, []).append((lbl, comment))
        addr_block_size[addr] = data['size']
    
    for addr, info in all_interact_blocks.items():
        if info.get('code_reuse'):
            continue
        lbl = interact_labels.get(addr)
        if not lbl:
            continue
        n_npc = sum(1 for e in info['entries'] if e[0] < 0x80)
        n_spawn = sum(1 for e in info['entries'] if e[0] >= 0x80)
        desc_parts = []
        if n_spawn: desc_parts.append(f"{n_spawn} spawns")
        if n_npc: desc_parts.append(f"{n_npc} NPCs")
        desc = ", ".join(desc_parts) if desc_parts else "empty"
        comment = f"; ${addr:04X} — {desc}"
        addr_labels.setdefault(addr, []).append((lbl, comment))
        addr_block_size[addr] = info['size']
    
    for addr, info in all_exit_blocks.items():
        lbl = exit_labels.get(addr)
        if not lbl:
            continue
        comment = f"; ${addr:04X} — {len(info['entries'])} exits"
        addr_labels.setdefault(addr, []).append((lbl, comment))
        addr_block_size[addr] = info['size']
    
    # ── Merge blocks into non-overlapping segments ──
    # Sort all blocks by (start_addr, -size) so larger blocks come first
    block_list = []  # (start, end, type, data)
    
    for addr, room in rooms.items():
        size = room['num_screens'] * 2
        if addr < ptr_table_end:
            eff_start = ptr_table_end
            overlap = (ptr_table_end - addr) // 2
            remaining = room['num_screens'] - overlap
            if remaining > 0:
                block_list.append((eff_start, eff_start + remaining * 2, 'sub_cont', 
                                  (room, overlap)))
        else:
            block_list.append((addr, addr + size, 'sub', room))
    
    for addr, data in all_step_blocks.items():
        block_list.append((addr, addr + data['size'], 'step', data))
    
    for addr, info in all_interact_blocks.items():
        if info.get('code_reuse'):
            continue
        block_list.append((addr, addr + info['size'], 'interact', info))
    
    for addr, info in all_exit_blocks.items():
        block_list.append((addr, addr + info['size'], 'exit', info))
    
    block_list.sort(key=lambda x: (x[0], -(x[1] - x[0])))
    
    # Remove fully-overlapped blocks (smaller blocks entirely within a larger one)
    # Keep their labels but skip data emission
    active_blocks = []  # non-overlapping blocks for data emission
    covered_end = ptr_table_end
    for start, end, btype, data in block_list:
        if start < covered_end:
            # This block overlaps — its labels are already in addr_labels
            # Just skip data emission
            continue
        active_blocks.append((start, end, btype, data))
        covered_end = end
    
    # ── Emit blocks in address order with gap filling ──
    cursor = ptr_table_end
    emitted_label_addrs = set()
    
    def emit_labels_at(addr):
        """Emit any labels that should appear at this address (once only)."""
        if addr in addr_labels and addr not in emitted_label_addrs:
            emitted_label_addrs.add(addr)
            for lbl, comment in addr_labels[addr]:
                lines.append("")
                lines.append(f"{lbl}:  {comment}")
    
    def emit_gap(gap_start, gap_end):
        size = gap_end - gap_start
        if size <= 0:
            return
        lines.append("")
        lines.append(f"; --- gap ${gap_start:04X}-${gap_end - 1:04X} ({size} bytes) ---")
        f = flat(gap_start)
        pos = 0
        while pos < size:
            # Check for labels in the middle of the gap
            addr = gap_start + pos
            if addr in addr_labels and addr != gap_start:
                emit_labels_at(addr)
            chunk = min(16, size - pos)
            # Don't cross a label boundary
            for c in range(1, chunk):
                if (gap_start + pos + c) in addr_labels:
                    chunk = c
                    break
            hex_vals = ", ".join(f"${rom[f + pos + i]:02X}" for i in range(chunk))
            lines.append(f"    db {hex_vals}")
            pos += chunk
    
    for start, end, btype, data in active_blocks:
        # Fill gap before this block
        if start > cursor:
            # Check if any labels fall within the gap
            emit_gap(cursor, start)
        
        if btype == 'sub_cont':
            room, overlap_count = data
            remaining = room['num_screens'] - overlap_count
            emit_labels_at(start)
            for i in range(remaining):
                scr_idx = overlap_count + i
                addr = start + i * 2
                # Check for labels at interior positions
                if i > 0 and addr in addr_labels:
                    emit_labels_at(addr)
                scr_ptr = room['screens_raw'][scr_idx] if scr_idx < len(room['screens_raw']) else 0xFFFF
                if scr_ptr == 0xFFFF:
                    lines.append(f"    dw $FFFF  ; screen {scr_idx} (unused)")
                elif scr_ptr in step_labels:
                    lines.append(f"    dw {step_labels[scr_ptr]}  ; screen {scr_idx}")
                else:
                    lines.append(f"    dw ${scr_ptr:04X}  ; screen {scr_idx}")
        
        elif btype == 'sub':
            room = data
            emit_labels_at(start)
            for scr_idx in range(room['num_screens']):
                addr = start + scr_idx * 2
                if scr_idx > 0 and addr in addr_labels:
                    emit_labels_at(addr)
                scr_ptr = room['screens_raw'][scr_idx]
                if scr_ptr == 0xFFFF:
                    lines.append(f"    dw $FFFF  ; screen {scr_idx} (unused)")
                elif scr_ptr in step_labels:
                    lines.append(f"    dw {step_labels[scr_ptr]}  ; screen {scr_idx}")
                else:
                    lines.append(f"    dw ${scr_ptr:04X}  ; screen {scr_idx}")
        
        elif btype == 'step':
            emit_labels_at(start)
            ram = data['ram']
            steps = data['steps']
            lines.append(f"    dw ${ram:04X}  ; RAM step counter")
            for si, step in enumerate(steps):
                addr = start + 2 + si * 6
                if addr in addr_labels:
                    emit_labels_at(addr)
                iptr = step['interact_ptr']
                eptr = step['exit_ptr']
                ilabel = interact_labels.get(iptr, f"${iptr:04X}")
                if eptr == 0xFFFF:
                    elabel = "$FFFF"
                elif eptr == 0x0000:
                    elabel = "$0000"
                else:
                    elabel = exit_labels.get(eptr, f"${eptr:04X}")
                lines.append(f"    db ${step['step_id']:02X}, ${step['tileset_bank']:02X}"
                           f"  ; step {si}: layout=${step['step_id']:02X}"
                           f" bank=${step['tileset_bank']:02X}")
                lines.append(f"    dw {ilabel}  ; → interact/NPC data")
                lines.append(f"    dw {elabel}  ; → exit data")
        
        elif btype == 'interact':
            info = data
            emit_labels_at(start)
            offset = 0
            for e in info['entries']:
                addr = start + offset
                if offset > 0 and addr in addr_labels:
                    emit_labels_at(addr)
                lines.append(format_interact_entry(e))
                offset += 5
            # Check label at terminator position
            term_addr = start + offset
            if term_addr in addr_labels:
                emit_labels_at(term_addr)
            lines.append(f"    db $FF  ; terminator")
        
        elif btype == 'exit':
            info = data
            emit_labels_at(start)
            offset = 0
            for e in info['entries']:
                addr = start + offset
                if offset > 0 and addr in addr_labels:
                    emit_labels_at(addr)
                lines.append(format_exit_entry(e))
                offset += 7
            term_addr = start + offset
            if term_addr in addr_labels:
                emit_labels_at(term_addr)
            lines.append(f"    db $FF  ; terminator")
        
        cursor = max(cursor, end)
    
    # ── Trailing data to end of bank ──
    if cursor < DATA_END:
        trailing_size = DATA_END - cursor
        lines.append("")
        lines.append(f"; --- TRAILING DATA (${cursor:04X}-${DATA_END - 1:04X},"
                    f" {trailing_size} bytes) ---")
        lines.append("; Sprite/tile graphics data")
        f = flat(cursor)
        pos = 0
        while pos < trailing_size:
            chunk = min(16, trailing_size - pos)
            hex_vals = ", ".join(f"${rom[f + pos + i]:02X}" for i in range(chunk))
            lines.append(f"    db {hex_vals}")
            pos += chunk

    print("\n".join(lines))


if __name__ == "__main__":
    main()
