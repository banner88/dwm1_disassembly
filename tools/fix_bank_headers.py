#!/usr/bin/env python3
"""
fix_bank_headers.py — Replace misassembled dispatch table headers with proper db/dw.

Phase 1 (gap=0): Label exists at header end → full replacement.
Phase 2 (gap>0): No label at header end → use ROM opcode sizes to find
the cut point, insert label, replace header.

Preserves: INCLUDE directives, referenced labels within header.

Usage:
  python3 tools/fix_bank_headers.py              # dry-run
  python3 tools/fix_bank_headers.py --apply       # apply
"""

import struct, sys, os, re

ROM_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'DWM-original.gbc')
ASM_DIR = os.path.join(os.path.dirname(__file__), '..', 'disassembly')
SYM_PATH = os.path.join(ASM_DIR, 'game.sym')


def read_dispatch_table(rom, bank):
    off = bank * 0x4000
    if off >= len(rom) or rom[off] != bank: return []
    ptrs, pos, first = [], off + 1, None
    while pos < off + 0x4000:
        ptr = struct.unpack_from('<H', rom, pos)[0]
        if first is None: first = ptr
        if ptr < 0x4000 or ptr >= 0x8000: break
        if 0x4000 + (pos - off) >= first: break
        ptrs.append(ptr)
        pos += 2
    return ptrs


def parse_sym(sym_path):
    sym = {}
    with open(sym_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith(';'): continue
            parts = line.split(None, 1)
            if len(parts) != 2: continue
            b, a = parts[0].split(':')
            sym.setdefault(int(b, 16), {})[int(a, 16)] = parts[1]
    return sym


def opcode_size(rom, pos):
    """Size of GB instruction at rom[pos], using the ROM as ground truth."""
    b = rom[pos]
    if b == 0xCB: return 2
    THREE = {0x01,0x11,0x21,0x31, 0xC3,0xC2,0xCA,0xD2,0xDA,
             0xCD,0xC4,0xCC,0xD4,0xDC, 0xEA,0xFA, 0x08}
    if b in THREE: return 3
    TWO = {0x18,0x20,0x28,0x30,0x38, 0x06,0x0E,0x16,0x1E,0x26,0x2E,0x36,0x3E,
           0xC6,0xCE,0xD6,0xDE,0xE6,0xEE,0xF6,0xFE, 0xE0,0xF0,0xE8,0xF8, 0x10}
    if b in TWO: return 2
    return 1


def is_skip_line(line):
    """True if line generates 0 assembled bytes."""
    s = line.strip()
    if not s or s.startswith(';'): return True
    clean = s.split(';')[0].strip()
    if clean.endswith(':') and (' ' not in clean or '::' in clean): return True
    if clean.upper().startswith(('INCLUDE', 'SECTION', 'DEF ', 'MACRO', 'ENDM', 'ENDC', 'IF ', 'ELSE')): return True
    return False


def asm_line_bytes(line):
    """Return byte count for db/dw/ds directives, or 0 if not a directive."""
    s = line.strip().split(';')[0].strip()
    m = re.match(r'db\s+(.+)', s, re.I)
    if m: return len([v for v in m.group(1).split(',') if v.strip()])
    m = re.match(r'dw\s+(.+)', s, re.I)
    if m: return 2 * len([v for v in m.group(1).split(',') if v.strip()])
    m = re.match(r'ds\s+(\$?[0-9a-fA-Fx]+)', s, re.I)
    if m:
        v = m.group(1)
        return int(v, 16) if v.startswith(('$', '0x')) else int(v)
    return 0


def find_cut_line(lines, section_idx, bank, header_size, rom):
    """Find the asm line where the header ends, using ROM opcode sizes."""
    bank_offset = bank * 0x4000
    rom_pos = 0
    asm_line = section_idx + 1
    prev_line = asm_line
    prev_pos = 0

    while rom_pos < header_size and asm_line < len(lines):
        if is_skip_line(lines[asm_line]):
            asm_line += 1
            continue

        # Check for db/dw directives
        dir_bytes = asm_line_bytes(lines[asm_line])
        if dir_bytes > 0:
            sz = dir_bytes
        else:
            sz = opcode_size(rom, bank_offset + rom_pos)

        prev_line = asm_line
        prev_pos = rom_pos
        rom_pos += sz
        asm_line += 1

        if rom_pos > header_size:
            # Instruction crosses boundary — cut before it
            return prev_line, prev_pos

    return asm_line, rom_pos


def find_label_line(lines, label_name):
    for i, line in enumerate(lines):
        s = line.strip()
        if s == f'{label_name}:' or s == f'{label_name}::':
            return i
    return None


def is_header_ok(lines):
    in_section = False
    for line in lines:
        if 'SECTION' in line and 'ROMX' in line:
            in_section = True; continue
        if not in_section: continue
        s = line.strip()
        if s == '' or s.startswith(';'): continue
        if s.upper().startswith('INCLUDE'): continue
        return bool(re.match(r'db\s+\$[0-9a-fA-F]+', s, re.I))
    return False


def generate_header(bank, ptrs, num_complete_entries, header_labels, sym_bank):
    """Generate db/dw header lines with interleaved labels."""
    offset_labels = {}
    for addr, labels in header_labels.items():
        offset_labels[addr - 0x4000] = labels  # list of labels

    out = []
    # Bank byte
    if 0 in offset_labels:
        for lbl in offset_labels[0]:
            out.append(f'{lbl}:')
    out.append(f'    db ${bank:02X} ; Bank number')
    out.append('')
    out.append(f'    ; Cross-bank dispatch table ({len(ptrs)} entries)')
    out.append(f'    ; Called via: ld hl, ${bank:02X}XX / rst $10')

    for i in range(num_complete_entries):
        ptr = ptrs[i]
        entry_offset = 1 + 2 * i
        high_offset = entry_offset + 1

        if entry_offset in offset_labels:
            for lbl in offset_labels[entry_offset]:
                out.append(f'{lbl}:')

        if high_offset in offset_labels:
            lo, hi = ptr & 0xFF, (ptr >> 8) & 0xFF
            lbl = sym_bank.get(ptr, f'${ptr:04X}')
            out.append(f'    db ${lo:02X}                            ; Entry {i} low ({lbl})')
            for lbl in offset_labels[high_offset]:
                out.append(f'{lbl}:')
            out.append(f'    db ${hi:02X}                            ; Entry {i} high')
        else:
            lbl = sym_bank.get(ptr, f'${ptr:04X}')
            out.append(f'    dw {lbl:<30s} ; Entry {i}')

    if num_complete_entries < len(ptrs):
        remaining = len(ptrs) - num_complete_entries
        out.append(f'    ; NOTE: last {remaining} entry/entries ({remaining*2}B) merged into following instruction')

    return out


def fix_bank(asm_path, bank, ptrs, sym_bank, rom, apply=False):
    with open(asm_path, 'r') as f:
        lines = f.read().split('\n')

    if is_header_ok(lines):
        return False, 'already OK'

    header_size = 1 + 2 * len(ptrs)
    hdr_end_addr = 0x4000 + header_size

    # Find SECTION line
    section_idx = None
    for i, line in enumerate(lines):
        if 'SECTION' in line and 'ROMX' in line:
            section_idx = i; break
    if section_idx is None:
        return False, 'no SECTION'

    # Phase 1: check for label at exact header end
    cut_label = sym_bank.get(hdr_end_addr)
    if cut_label:
        cut_line = find_label_line(lines, cut_label)
        if cut_line is None:
            return False, f'cannot find label {cut_label}'
        consumed = header_size
    else:
        # Phase 2: ROM-based cut finding
        cut_line, consumed = find_cut_line(lines, section_idx, bank, header_size, rom)

    num_complete_entries = (consumed - 1) // 2  # subtract bank byte, divide by 2

    # Find ALL labels in the header region of the asm file
    # (asm may have multiple labels at same address, e.g. Call_ and Jump_)
    header_labels = {}
    for idx in range(section_idx + 1, cut_line):
        s = lines[idx].strip()
        if (s.endswith(':') or '::' in s) and not s.startswith(';'):
            label = s.rstrip(':').rstrip(':')
            if not label: continue
            # Check if referenced AFTER the cut point
            for line in lines[cut_line:]:
                ls = line.strip()
                if label in ls and not ls.startswith(label):
                    # Get address from sym_bank (reverse lookup)
                    addr = None
                    for a, l in sym_bank.items():
                        if l == label:
                            addr = a; break
                    if addr is None:
                        # Try to find by matching label patterns
                        m = re.match(r'(?:Call|Jump|jr|label)_[0-9a-f]+_([0-9a-f]+)', label, re.I)
                        if m:
                            addr = int(m.group(1), 16)
                    if addr is not None and 0x4000 <= addr < 0x4000 + consumed:
                        header_labels.setdefault(addr, []).append(label)
                    break

    # Preserve INCLUDE and comment lines after SECTION
    preserved = []
    scan = section_idx + 1
    while scan < cut_line:
        s = lines[scan].strip()
        if s.startswith(';') or s == '' or s.upper().startswith('INCLUDE'):
            preserved.append(lines[scan])
            scan += 1
        else:
            break

    # Generate header
    hdr = generate_header(bank, ptrs, num_complete_entries, header_labels, sym_bank)

    # Build new file
    new = lines[:section_idx + 1]
    if preserved:
        new.extend(preserved)
    else:
        new.append('')
    new.extend(hdr)
    new.append('')

    # Insert entry point label if none exists
    first_addr = ptrs[0]
    if consumed == header_size and not cut_label:
        # No label at header end, insert one
        new.append(f'; --- Dispatch entry 0 (${first_addr:04X}) ---')
        new.append(f'DispatchEntry_{bank:02X}_0:')

    new.extend(lines[cut_line:])

    replaced = cut_line - section_idx - 1 - len(preserved)
    partial = f' (partial: {consumed}/{header_size}B)' if consumed < header_size else ''
    preserved_str = f', preserved {len(header_labels)} labels' if header_labels else ''

    if apply:
        with open(asm_path, 'w') as f:
            f.write('\n'.join(new))

    return True, f'replaced {replaced} lines → {num_complete_entries}/{len(ptrs)} entries{partial}{preserved_str}'


def main():
    apply = '--apply' in sys.argv
    verbose = '-v' in sys.argv

    with open(ROM_PATH, 'rb') as f:
        rom = f.read()

    sym = parse_sym(SYM_PATH)
    fixed = ok = 0

    for bank in range(1, 128):
        ptrs = read_dispatch_table(rom, bank)
        if not ptrs: continue
        asm = os.path.join(ASM_DIR, f'bank_{bank:03x}.asm')
        if not os.path.exists(asm): continue

        changed, msg = fix_bank(asm, bank, ptrs, sym.get(bank, {}), rom, apply)
        if changed:
            print(f'Bank ${bank:02X}: {msg}')
            fixed += 1
        else:
            if verbose: print(f'Bank ${bank:02X}: {msg}')
            ok += 1

    print(f'\n{"="*60}')
    print(f'{fixed} fixed, {ok} already OK')
    if not apply and fixed:
        print('Run with --apply to write changes')


if __name__ == '__main__':
    main()
