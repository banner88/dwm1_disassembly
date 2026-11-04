#!/usr/bin/env python3
"""resection_window_layouts.py — S165 (ROADMAP Phase F T-follow (a), Iron Rule 6): the window
LAYOUT STREAMS of banks $07 (the field menus) and $15 (the title menu, the map / arena windows)
as labeled `db` in BOTH trees, and the 16 drawer entries named.

mgbdis decoded the streams as instructions (`ldh [$e0], a`, `ret c` …). This tool:

  * finds each run's source lines with a zero-byte probe build of the CLEAN tree (every line's
    address from game.sym — no opcode-size summing, the S22 trap), snaps the run to whole lines,
    and replaces them with one block per stream:

        WinLayout_07_704D:           ; field menu: INFO ITEM / SKIL OPTN
            dw $0000                 ; position: row 0, column 0
            db $fa, $ef, …, $fb      ; row 0
            db $d8                   ; NEWLINE
            …
            db $d9                   ; END

    the words decoded with the stream's font (extracted/window_layouts.json, the field font /
    the text font) in the comments; a line the run's first line shares with code before it is
    split off as `db` (the bytes stay);
  * applies the SAME text replacement to the patched tree (patches/bank_0xx.asm), whose lines
    over the run are byte-for-byte the clean ones (checked: the old block must occur exactly
    once there), and puts the patched run inside a compiler region `win_words_<bank>_<start>`
    (editor2/core/window_words.py — the editable words);
  * names the drawer entries in both trees (WinLayoutDraw<bank> = entry B, the screen buffer;
    WinLayoutDrawVram<bank> = entry A, the BG map) for the banks touched.

Checks (exit 1 on failure): the clean build stays 1ca6579…; any label inside a run that code
outside it references is refused (none — the runs are data). Idempotent: a run whose first
label exists is skipped.

    python3 tools/resection_window_layouts.py [--apply]
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
DIS = os.path.join(REPO, 'disassembly')
PAT = os.path.join(REPO, 'patches')
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'
CENSUS = os.path.join(REPO, 'extracted', 'window_layouts.json')

# (bank, start, end): the runs re-sectioned (all their streams code-referenced, contiguous)
RUNS = [(0x07, 0x704D, 0x7D98), (0x15, 0x647D, 0x64F4), (0x15, 0x6716, 0x694E)]
# what each screen is (the label comments): editor2/core/window_words.py WHAT
_WHAT_UNUSED = {
    (0x07, 0x704D): 'the field menu', (0x07, 0x7090): 'the gold box', (0x07, 0x70AD): 'INFO: who',
    (0x07, 0x70F7): 'the INFO page: stats', (0x07, 0x71AF): 'the INFO page: HP / MP',
    (0x07, 0x727B): 'the INFO page 2: name / family / master',
    (0x07, 0x7333): 'the INFO page 2: next level',
    (0x07, 0x7687): 'SKIL: who', (0x07, 0x78D9): 'SKIL: the MP box',
    (0x07, 0x798B): 'ITEM: the item window', (0x07, 0x7A61): 'OPTN', (0x07, 0x7C44): 'OPTN: yes / no',
    (0x07, 0x7C69): 'OPTN: CH PLAN (the tactics)', (0x07, 0x7BCA): 'OPTN: JOURNAL (the save box)',
    (0x15, 0x647D): 'the title menu',
}


def md5(p):
    return hashlib.md5(open(p, 'rb').read()).hexdigest()


def build():
    for f in ('game.o', 'game.gbc', 'game.sym', 'game.map'):
        if os.path.exists(os.path.join(DIS, f)):
            os.remove(os.path.join(DIS, f))
    r = subprocess.run('make', cwd=DIS, shell=True, capture_output=True, text=True)
    return os.path.exists(os.path.join(DIS, 'game.gbc')), r.stdout + r.stderr


def line_addrs(asm, bank):
    """{line index: address} by a zero-byte probe build (resection_text_bank's method)."""
    lines = open(asm).read().split('\n')
    probed, probe_of = [], {}
    for i, l in enumerate(lines):
        s = l.strip()
        if s and not s.startswith(';') and not (s.endswith(':') and ' ' not in s):
            probed.append(f'Lprobe_{i}:')
            probe_of[f'Lprobe_{i}'] = i
        probed.append(l)
    bak = asm + '.probebak'
    shutil.copy(asm, bak)
    try:
        open(asm, 'w').write('\n'.join(probed))
        ok, log = build()
        if not ok:
            sys.exit('probe build failed:\n' + log[-2000:])
        if md5(os.path.join(DIS, 'game.gbc')) != ORIGINAL_MD5:
            sys.exit('probe build not byte-perfect')
        sym = open(os.path.join(DIS, 'game.sym')).read()
    finally:
        shutil.move(bak, asm)
    got = {}
    for m in re.finditer(rf'^{bank:02x}:([0-9a-f]{{4}}) (Lprobe_\d+)$', sym, re.M | re.I):
        got[probe_of[m.group(2)]] = int(m.group(1), 16)
    return lines, got


def block_for(rom, bank, start, end, cen):
    """The run's text = the compiler region's body with no edits (editor2/core/window_words.py
    run_block — one generator, so --apply of an unedited project changes nothing)."""
    from editor2.core import window_words as WW
    return WW.run_block({}, bank, start, end, REPO).rstrip('\n').split('\n')


def resection(apply):
    rom = open(ROM, 'rb').read()
    cen = json.load(open(CENSUS))
    done = []
    for bank in sorted({b for b, _s, _e in RUNS}):
        asm = os.path.join(DIS, f'bank_{bank:03x}.asm')
        patf = os.path.join(PAT, f'bank_{bank:03x}.asm')
        runs = [(s, e) for b, s, e in RUNS if b == bank
                and f'WinLayout_{bank:02X}_{s:04X}:' not in open(asm).read()]
        if not runs:
            continue
        lines, addr = line_addrs(asm, bank)
        ptext = open(patf).read()
        # every label defined in the file, and the lines that reference each
        defs = {}
        for i, l in enumerate(lines):
            mm = re.match(r'^([A-Za-z_]\w*):', l)
            if mm:
                defs[mm.group(1)] = i
        repl = []
        for s, e in runs:
            idx = sorted(i for i, a in addr.items() if s <= a < e)
            first, last = idx[0], idx[-1]
            # the first instruction line at/after s must start exactly at s
            if addr[first] != s:
                sys.exit(f'${bank:02X}: run ${s:04X} starts inside the line at ${addr[first]:04X}')
            nxt = min((i for i, a in addr.items() if a >= e), default=None)
            if nxt is None or addr[nxt] != e:
                sys.exit(f'${bank:02X}: run end ${e:04X} is not a line boundary')
            hi = nxt
            while hi > last + 1 and re.match(r'^[A-Za-z_]\w*:', lines[hi - 1]):
                hi -= 1                          # a label of the next line stays with it
            # labels inside [first, hi): none may be referenced from outside
            inner = [lines[i].split(':')[0] for i in range(first, hi)
                     if re.match(r'^[A-Za-z_]\w*:', lines[i])]
            for lab in inner:
                if _referenced_outside(lines, lab, first, hi):
                    sys.exit(f'${bank:02X}: label {lab} inside the run is referenced elsewhere')
            old = '\n'.join(lines[first:hi])
            new = block_for(rom, bank, s, e, cen)
            if ptext.count(old) != 1:
                sys.exit(f'${bank:02X}: the patched tree does not hold the run ${s:04X} verbatim '
                         f'({ptext.count(old)} copies)')
            region = f'win_words_{bank:02x}_{s:04x}'
            pnew = [f'; @BUILD_PROJECT BEGIN {region}'] + new + [f'; @BUILD_PROJECT END {region}']
            ptext = ptext.replace(old, '\n'.join(pnew), 1)
            repl.append((first, hi, new))
            done.append((bank, s, e, hi - first, region))
        for first, hi, new in sorted(repl, reverse=True):
            lines[first:hi] = new
        if apply:
            open(asm, 'w').write('\n'.join(lines))
            open(patf, 'w').write(ptext)
    return done


def _referenced_outside(lines, lab, a, b):
    pat = re.compile(rf'\b{re.escape(lab)}\b')
    return any(pat.search(l) for i, l in enumerate(lines)
               if not (a <= i < b) and not l.startswith(lab + ':'))


DRAWERS = {0x07: [(0x68A0, 'WinLayoutDrawVram07'), (0x68DC, 'WinLayoutDraw07')],
           0x15: [(0x5D53, 'WinLayoutDrawVram15'), (0x5D8F, 'WinLayoutDraw15')]}
DRAWER_NOTE = ('; [S165] {name}: draw a window LAYOUT STREAM (DE = the stream: dw position, cells, $D8 '
               'newline, $D9 end) — {how}. DATA_STRUCTURES "Window layout streams (S165)".')


def name_drawers(apply):
    """Rename the drawer labels (both trees, every reference) and comment them."""
    out = []
    for bank, ents in DRAWERS.items():
        for tree in (DIS, PAT):
            p = os.path.join(tree, f'bank_{bank:03x}.asm')
            t = open(p).read()
            for addr, name in ents:
                if f'\n{name}:' in t:
                    continue
                how = ('the BG map $9800+ (the row wraps at 32: `and $03 / or $98`), cells through '
                       'Write_gfx_tile' if 'Vram' in name else 'the screen buffer (LoadMap_5d33 / '
                       'the bank\'s own position helper), cells `ld [hl+], a`')
                note = DRAWER_NOTE.format(name=name, how=how)
                old = None
                for cand in (f'LoadFld_{addr:04x}', f'LoadMap_{addr:04x}'):
                    if re.search(rf'^{cand}:', t, re.M):
                        old = cand
                        break
                if old:
                    t = re.sub(rf'^{old}:', f'{note}\n{name}:\n{old}:', t, count=1, flags=re.M)
                else:
                    # the unlabelled entry A of bank $15 ($5D53): after `jr_015_5d51: pop bc / ret`
                    mm = re.search(r'(jr_015_5d51:\n    pop bc\n    ret\n\n?)', t)
                    if not mm or bank != 0x15:
                        sys.exit(f'${bank:02X}:{addr:04X}: drawer label not found')
                    t = t.replace(mm.group(1), mm.group(1) + f'{note}\n{name}:\n', 1)
                out.append((tree.split('/')[-1], bank, name))
            if apply:
                open(p, 'w').write(t)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    a = ap.parse_args()
    done = resection(a.apply)
    for b, s, e, n, region in done:
        print(f'${b:02X} ${s:04X}-${e:04X}: {n} source lines -> db (region {region})')
    nd = name_drawers(a.apply)
    print(f'{len(nd)} drawer labels added')
    if a.apply:
        ok, log = build()
        got = md5(os.path.join(DIS, 'game.gbc')) if ok else None
        print('clean build:', got)
        if got != ORIGINAL_MD5:
            sys.exit('NOT byte-perfect\n' + log[-2000:])


if __name__ == '__main__':
    main()
