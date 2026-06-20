#!/usr/bin/env python3
"""
resection_battle_gfx_table.py — re-section the misassembled monster BATTLE
gfx-ID table in disassembly/bank_000.asm into a labeled dw/db block.

The table at $00:$2B9F is read by SetFld_466d ($07): species*2 + $2B9F -> 2-byte
gfx-ID (bank<<8 | index). mgbdis mis-decoded the whole surrounding data blob
($2B91..$2DA7: a lead-in pointer fragment, the 221-entry battle table, and a
$320F filler run) as fake instructions with hallucinated labels (TilemapScrollCalc,
WriteTileSequence, ...). 23 of those labels are cross-referenced from OTHER banks'
equally-misassembled data, so they must survive at their exact addresses or the
references won't resolve / will emit different bytes.

ROBUST METHOD (no opcode sizing): replace the source lines strictly between two
REAL label anchors whose addresses come from the linker symbol map
(Data_2B91 @ $2B91 .. TileRotatePadding @ $2DA8), and emit the EXACT ROM bytes
for that whole [$2B91,$2DA8) range — the 221 table entries as `dw`
(MonsterBattleGfxTable), the lead-in and filler as `dw`/`db`, with every
referenced label re-created at its exact byte offset. Because every emitted byte
is sourced from the ROM and every referenced label sits at its exact address,
the build stays byte-perfect (verify_integrity.py check 1).

LABELS/COMMENTS ONLY — zero byte impact. Idempotent (refuses if already done).
"""
import os, sys, subprocess

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM  = os.path.join(REPO, 'disassembly', 'bank_000.asm')
ROM  = os.path.join(REPO, 'data', 'DWM-original.gbc')

START_LABEL = 'Data_2B91'
END_LABEL   = 'TilemapRotateWrite'   # placeholder; resolved from sym below
# Actual anchors (addresses verified from the clean symbol map):
START_ADDR  = 0x2B91
END_ADDR    = 0x2DA8                  # TileRotatePadding — first label past the $320F filler
TABLE_START = 0x2B9F
NUM_SPECIES = 221                     # extension knob (vanilla = 221)
TABLE_END   = TABLE_START + NUM_SPECIES*2   # $2D59 (exclusive)

# Referenced fake labels in [$2B91,$2DA8) that MUST be preserved at exact addresses.
PRESERVE = {
    0x2B91: 'Data_2B91',
    0x2BBC: 'Data_2BBC',
    0x2BC4: 'TilemapScrollCalc',
    0x2BCC: 'BitComplementAndBranch',
    0x2BDD: 'TilemapDrawRegion',
    0x2BEE: 'TilemapFillBorder01',
    0x2BFE: 'WriteTileBorderMid',
    0x2C0E: 'WriteTileBorderBot',
    0x2C67: 'TileSequenceMid',
    0x2CA4: 'TileSeqIncrementC',
    0x2CB4: 'TileSeqIncrementD',
    0x2CEC: 'TileDataBlock2',
    0x2CF3: 'TileDataContinue',
    0x2CFB: 'TilemapWriteByte',
    0x2CFC: 'TilemapWriteByte2',
    0x2CFF: 'TilemapNextTile',
    0x2D03: 'TileNextInSeq',
    0x2D0F: 'TileAddDE',
    0x2D35: 'TileStoreReverse',
    0x2D42: 'TileStoreReverseLoop',
    0x2D52: 'TileStoreEnd',
    0x2D53: 'TilemapRotateWrite',
    0x2D56: 'WriteRotatedBytesDown',
}

def main():
    rom = open(ROM,'rb').read()
    lines = open(ASM).read().split('\n')
    if any('MonsterBattleGfxTable:' in l for l in lines):
        sys.exit('Already re-sectioned (MonsterBattleGfxTable present). Nothing to do.')

    # locate anchor lines by exact label text
    try:
        start_line = next(i for i,l in enumerate(lines) if l.strip()==START_LABEL+':')
        end_line   = next(i for i,l in enumerate(lines) if l.strip()=='TileRotatePadding:')
    except StopIteration:
        sys.exit('Anchor label not found; aborting.')

    out = []
    addr = START_ADDR
    words = []   # pending aligned dw entries (only within the table range)
    def flush_words():
        nonlocal words
        for k in range(0, len(words), 8):
            out.append('    dw ' + ', '.join(words[k:k+8]))
        words = []

    def emit_table_comment():
        out.append('; --- Monster BATTLE sprite gfx-ID table (GFX-1) ---')
        out.append('; Read by SetFld_466d ($07): A=species; word = [$2B9F + species*2].')
        out.append('; gfx-ID = (bank<<8)|index -> per-bank pointer table $<bank>:$4001+index*2')
        out.append('; -> LZ stream -> DMA to VRAM $8B00. 221 entries; banks $2F,$32-$36.')

    while addr < END_ADDR:
        if addr in PRESERVE:
            flush_words()
            out.append(f'{PRESERVE[addr]}:')
            if addr == TABLE_START:
                emit_table_comment()
        if addr == TABLE_START and TABLE_START not in PRESERVE:
            flush_words(); emit_table_comment(); out.append('MonsterBattleGfxTable:')
        elif addr == TABLE_START:
            out.append('MonsterBattleGfxTable:')

        in_table = (TABLE_START <= addr < TABLE_END)
        word_aligned_in_table = in_table and ((addr - TABLE_START) % 2 == 0)
        next_has_label = (addr+1) in PRESERVE

        if word_aligned_in_table and (addr+1) < TABLE_END and not next_has_label:
            words.append(f'${rom[addr] | (rom[addr+1]<<8):04x}')
            addr += 2
            continue

        # byte granularity (lead-in, filler, or word straddling a preserved label)
        flush_words()
        tag = ''
        if in_table:
            sp = (addr-TABLE_START)//2
            tag = f'   ; sp{sp} {"lo" if (addr-TABLE_START)%2==0 else "hi"}'
        out.append(f'    db ${rom[addr]:02x}{tag}')
        addr += 1
    flush_words()

    new_lines = lines[:start_line] + out + lines[end_line:]
    open(ASM,'w').write('\n'.join(new_lines)+'\n')

    emitted = sum(_dbdw_bytes(l) for l in out)
    print(f'Re-sectioned [${START_ADDR:04x},${END_ADDR:04x}) = {emitted} bytes '
          f'(expect {END_ADDR-START_ADDR}); {NUM_SPECIES} table entries; '
          f'{len(PRESERVE)} labels preserved.')

def _dbdw_bytes(line):
    s = line.split(';')[0].strip()
    if s.startswith('db '): return len(s[3:].split(','))
    if s.startswith('dw '): return 2*len(s[3:].split(','))
    return 0

if __name__=='__main__':
    main()
