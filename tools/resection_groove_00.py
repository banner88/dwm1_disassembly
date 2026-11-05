#!/usr/bin/env python3
"""resection_groove_00.py — ROM0 $3B83-$3C02 = the GROOVE ROW TABLE, re-sectioned
as labeled `db` in BOTH trees (S167; byte-neutral in the clean tree).

The table (SOUND_SYSTEM §5 `A3 xx`): 8 rows x 16 signed steps; ROM0
`AudioSetEDZero` reads `$3B83 + (([$E5] & $70) | ([$DE22] & $0F))` — the groove
row a channel's `$A3` command chose (bits 4-6) and the step 0-15 — and adds it to
the note's frequency ([$F6]). mgbdis rendered it as instructions with labels
(`AudioLookup_3B89` …, `AudioWavePatternData`, `ScreenTransA` … `D`) that are
only named by other misassembled data; they are renamed `GrooveRow<r>_<step>`.

S167 (tools/audit_patch_space.py): since S63 every patched build kept
`MapIDClampForPalette` + `ClampFamIdx` at $3BC2-$3BD2 — row 3's last step and all
of row 4 — taken as "17 unreferenced rst $38". Measured with the editor's sound
engine (92 vanilla sounds x 3,600 frames): row 3 step 15 ($3BC2) is read by songs
$0C and $12 (the boss song) — the patched builds played -6 there instead of -1.
The patch tree gets the original bytes back here; the clamp moved to the dead
vanilla master table at $3466 (patches/bank_000.asm).

Usage:  python3 tools/resection_groove_00.py [--check]
        (rewrites disassembly/bank_000.asm + patches/bank_000.asm; then rebuild:
        the clean tree must stay 1ca6579…)
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE, END = 0x3B83, 0x3C03
ROWS = ['vibrato +-1, 2-step', 'vibrato +-1, 4-step', 'vibrato +-2',
        'slow vibrato +-2', 'constant -1 (flat)', 'constant -2', 'constant +1 (sharp)',
        'constant +2']
# address -> the label kept there (other files name these addresses)
RENAME = {
    'AudioLookup_3B89': 0x3B89, 'AudioLookup_3B97': 0x3B97, 'AudioLookup_3BA7': 0x3BA7,
    'AudioWavePatternData': 0x3BC2, 'ScreenTransA': 0x3BF5, 'ScreenTransB': 0x3BFA,
    'ScreenTransC': 0x3C00, 'ScreenTransitionSetup': 0x3C00, 'ScreenTransD': 0x3C01,
}


def new_name(addr):
    r, k = divmod(addr - BASE, 16)
    return f'GrooveRow{r}_{k}'


# names that other files reference -> renamed there too (labels only)
KEEP = {a for n, a in RENAME.items() if n not in ('AudioWavePatternData', 'ScreenTransitionSetup')}


def block(rom):
    out = ['; =============================================================================',
           '; GrooveRowTable — ROM0 $3B83-$3C02 (S167 re-section; tools/resection_groove_00.py)',
           '; =============================================================================',
           '; 8 rows x 16 signed steps. AudioSetEDZero: `ld hl, GrooveRowTable / add hl, de`',
           '; with E = ([$E5] & $70) | ([$DE22] & $0F) — the row chosen by a channel\'s $A3',
           '; command (bits 4-6, $E5 bit 7 = groove on) and the step 0-15 — then adds the byte',
           '; to the note\'s frequency ([$F6]). SOUND_SYSTEM §5. Measured S167 (the editor\'s',
           '; sound engine, 92 vanilla sounds x 3,600 frames): rows 0-3, 6, 7 are read (row 3',
           '; by $0C and the boss song $12), rows 4 / 5 by none — ALL rows are live data: never',
           '; free space (KEY_LESSONS S167). The GrooveRow<r>_<step> labels are only named by',
           '; misassembled data elsewhere (mgbdis), kept so those bytes stay the same.',
           'GrooveRowTable:']
    for r in range(8):
        a = BASE + 16 * r
        out.append(f'; row {r}: {ROWS[r]}')
        cur = []
        for k in range(16):
            ad = a + k
            if ad in KEEP and cur:
                out.append('    db ' + ', '.join(cur))
                cur = []
            if ad in KEEP:
                out.append(f'{new_name(ad)}:')
            cur.append(f'${rom[ad]:02X}')
        out.append('    db ' + ', '.join(cur))
    return out


def rewrite(path, rom, check):
    lines = open(path, encoding='utf-8').read().split('\n')
    # start: the line after DataLookup_3B7C's `ldh [$f0], a`; end: `ScreenTransE:`
    i0 = next(i for i, l in enumerate(lines) if l.startswith('DataLookup_3B7C:'))
    s = next(i for i in range(i0, i0 + 20) if lines[i].strip() == 'ldh [$f0], a') + 1
    e = next(i for i in range(s, s + 400) if lines[i].startswith('ScreenTransE:'))
    old = lines[s:e]
    new = block(rom) + ['']
    if check:
        print(f'{os.path.relpath(path, REPO)}: lines {s + 1}-{e} ({len(old)}) -> {len(new)}')
        return
    lines[s:e] = new
    txt = '\n'.join(lines)
    txt = txt.replace('    ld hl, $3b83\n', '    ld hl, GrooveRowTable  ; $3B83 (S167)\n')
    open(path, 'w', encoding='utf-8').write(txt)


def rename_refs(check):
    pat = re.compile(r'\b(' + '|'.join(n for n, a in RENAME.items() if a in KEEP) + r')\b')
    for tree in ('disassembly', 'patches'):
        d = os.path.join(REPO, tree)
        for fn in sorted(os.listdir(d)):
            if not fn.endswith('.asm'):
                continue
            p = os.path.join(d, fn)
            t = open(p, encoding='utf-8').read()
            t2 = pat.sub(lambda m: new_name(RENAME[m.group(1)]), t)
            if t2 != t:
                print(f'  {tree}/{fn}: {len(pat.findall(t))} references renamed')
                if not check:
                    open(p, 'w', encoding='utf-8').write(t2)


def main():
    check = '--check' in sys.argv
    rom = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    for tree in ('disassembly', 'patches'):
        rewrite(os.path.join(REPO, tree, 'bank_000.asm'), rom, check)
    rename_refs(check)


if __name__ == '__main__':
    main()
