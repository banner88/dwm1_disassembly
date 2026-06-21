#!/usr/bin/env python3
"""
resection_follower_gfx_table.py — re-section the misassembled monster FOLLOWER
(walking) gfx-ID table in disassembly/bank_001.asm into labeled dw blocks.

The follower load (GetActiveMonsterStatus @ $01:$4986) indexes a 2-byte gfx-ID
table at $01:$49DF (ScreenTransDataTable) by (species + $10)*2, then does a
SECOND, family-shared DMA from a 10-entry table at $01:$4BAD (families 0-9 ->
$2E03..$2E0C). mgbdis mis-decoded both tables (and the gap) as fake instructions
(`ld sp,$3140`, `jr c,...`) with 12 hallucinated `jr_001_4axx` labels.

UNLIKE the battle table (Session 22), every one of those 12 fake labels is
referenced ONLY internally by the fake `jr c` lines inside the same block, and
NOTHING outside [$49DF,$4BC1) references any address in the range (verified
tree-wide). So the re-section is fully self-contained: converting the block to
`dw` deletes the fake labels and the fake `jr`s that referenced them together,
with no link errors and no labels to preserve.

ROBUST METHOD (no opcode sizing — same as resection_battle_gfx_table.py):
replace the source lines strictly between two REAL label anchors
(ScreenTransDataTable @ $49DF .. IteratePartySlots20 @ $4BC1) and emit the EXACT
ROM bytes for that whole [$49DF,$4BC1) range as `dw`:

  ScreenTransDataTable:    $49DF..$4BAC  231 entries (462 B)
      entry 0      = null/default ($2F00)
      entries 1-15 = the bit-7 special case (loader forces index 1 -> $3140)
      entries 16.. = species 0..214 followers, index (species+$10)
  FollowerFamilyGfxTable:  $4BAD..$4BC0  10 entries (20 B), families 0-9

Also labelizes the loader's raw `ld hl, $4bad` -> `ld hl, FollowerFamilyGfxTable`
(zero-byte: the label resolves to $4BAD).

LABELS/COMMENTS ONLY — zero byte impact. Idempotent (refuses if already done).
Build MUST stay 1ca6579359f21d8e27b446f865bf6b83 after running (verify check 1).
"""
import os, sys, subprocess, hashlib

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM  = os.path.join(REPO, 'disassembly', 'bank_001.asm')
ROM  = os.path.join(REPO, 'data', 'DWM-original.gbc')

START_LABEL = 'ScreenTransDataTable'   # @ $49DF
END_LABEL   = 'IteratePartySlots20'    # @ $4BC1 (first real code past the tables)
START_ADDR  = 0x49DF
END_ADDR    = 0x4BC1                    # exclusive

SPECIES_TABLE_END = 0x4BAD             # ScreenTransDataTable ends here; family table begins
FAMILY_TABLE_END  = 0x4BC1             # FollowerFamilyGfxTable ends here
NUM_SPECIES_FOLLOWERS = 215            # species 0..214 have followers (215..220 are non-collectible)


def rom_bank1(rom, addr):
    """Bank 1 in-bank addr ($4000..$7FFF) maps 1:1 to file offset."""
    return rom[addr]


def dw_lines(rom, start, end, per_line=8):
    """Emit `dw $xxxx, ...` lines for [start,end) (end-start must be even)."""
    out, addr = [], start
    row = []
    while addr < end:
        val = rom[addr] | (rom[addr + 1] << 8)
        row.append(f'${val:04x}')
        addr += 2
        if len(row) == per_line:
            out.append('    dw ' + ', '.join(row))
            row = []
    if row:
        out.append('    dw ' + ', '.join(row))
    return out


def build_block(rom):
    lines = []
    lines.append(f'{START_LABEL}:')
    lines.append('    ; Follower (walking) gfx-ID table. GetActiveMonsterStatus ($4986)')
    lines.append('    ; indexes this by (species + $10)*2 -> 2-byte gfx-ID (bank<<8|index),')
    lines.append('    ; resolved by DecompressTileLayout ($00:$1627) via $<bank>:$4001+index*2.')
    lines.append('    ; entry 0 = default; entries 1-15 = bit-7 special case (loader forces')
    lines.append('    ; index 1 -> $3140); entries 16.. = species 0..214 followers.')
    # entry 0 + entries 1..15 (the $10 header), then species follower entries
    # Emit header (entries 0..15 = 16 entries = 32 bytes) then species entries.
    header_end = START_ADDR + 16 * 2          # $49FF
    lines += dw_lines(rom, START_ADDR, header_end)
    lines.append('    ; species 0.. followers (index = species + $10):')
    lines += dw_lines(rom, header_end, SPECIES_TABLE_END)
    lines.append('')
    lines.append('FollowerFamilyGfxTable:')
    lines.append('    ; Family-shared follower block (2nd DMA in GetActiveMonsterStatus,')
    lines.append('    ; via `ld hl, FollowerFamilyGfxTable` + family-byte index). 10 entries,')
    lines.append('    ; families 0-9 -> $2E03..$2E0C (B9 ClampFamIdx keeps family>=10 in range).')
    lines += dw_lines(rom, SPECIES_TABLE_END, FAMILY_TABLE_END)
    return '\n'.join(lines)


def main():
    rom = open(ROM, 'rb').read()
    src = open(ASM).read()

    if 'FollowerFamilyGfxTable:' in src:
        print('Already re-sectioned (FollowerFamilyGfxTable present). No change.')
        return

    sline = f'{START_LABEL}:'
    eline = f'{END_LABEL}:'
    if sline not in src or eline not in src:
        sys.exit(f'anchor labels not found ({START_LABEL} / {END_LABEL})')

    a = src.index(sline)
    b = src.index(eline)
    if not (a < b):
        sys.exit('anchors out of order')

    block = build_block(rom) + '\n\n'
    new_src = src[:a] + block + src[b:]

    # Labelize the loader's raw family-table reference (zero-byte).
    new_src = new_src.replace('    ld hl, $4bad\n',
                              '    ld hl, FollowerFamilyGfxTable\n')

    open(ASM, 'w').write(new_src)
    print(f're-sectioned {START_ADDR:#06x}..{END_ADDR:#06x} '
          f'({END_ADDR-START_ADDR} bytes) into ScreenTransDataTable + '
          f'FollowerFamilyGfxTable; labelized loader ref.')


if __name__ == '__main__':
    main()
