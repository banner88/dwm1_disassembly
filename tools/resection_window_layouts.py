#!/usr/bin/env python3
"""resection_window_layouts.py — S165 / S166 (ROADMAP Phase F T-follow (a), Iron Rule 6): the window
LAYOUT STREAMS of banks $07 (the field menus), $15 (the title menu, the link windows) and — S166 —
$09 (shop, Vault, gate list, naming), $0A (Grandpa, the egg appraiser), $12 (the farm, the namer,
the library: its S26 / S27 `LibWinLayout_*` run re-emitted in the same format, labels kept), $18
(the link mode), $50 / $51 (the battle) as labeled `db` in BOTH trees, every `ld de, $<stream>`
named, and the 16 drawer entries named.

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

# (bank, start, end): the runs re-sectioned (all their streams code-referenced, contiguous) —
# one list with the compiler (editor2/core/window_words.py RUNS)
sys.path.insert(0, REPO)
from editor2.core import window_words as _WW            # noqa: E402
RUNS = list(_WW.RUNS)
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
    glob = False                     # S166: after a global label the probe is a LOCAL label, so
    for i, l in enumerate(lines):    # it never cuts a `.local` label off its parent (bank $09)
        s = l.strip()
        if re.match(r'^[A-Za-z_]\w*:', l):
            glob = True
        if s and not s.startswith(';') and not (s.endswith(':') and ' ' not in s):
            probed.append(f'.Lprobe_{i}:' if glob else f'Lprobe_{i}:')
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
    for m in re.finditer(rf'^{bank:02x}:([0-9a-f]{{4}}) (?:\w+\.)?(Lprobe_\d+)$', sym, re.M | re.I):
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
        txt = open(asm).read()
        runs = [(s, e) for b, s, e in RUNS if b == bank
                and f'window layout streams ${s:04X}-' not in txt]
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
        repl, deref = [], []
        # every run's line span first: a fake-code reference from one run into another is data
        spans = []
        for s, e in runs:
            idx = sorted(i for i, a in addr.items() if s <= a < e)
            nxt = min((i for i, a in addr.items() if a >= e), default=len(lines))
            spans.append((idx[0], nxt))
        for s, e in runs:
            idx = sorted(i for i, a in addr.items() if s <= a < e)
            first, last = idx[0], idx[-1]
            new_labels = set()
            a_ = s
            while a_ < e:
                new_labels.add(_WW.label(bank, a_))
                a_ += cen['layouts'][f'{bank:02X}:{a_:04X}']['len']
            # the first instruction line at/after s must start exactly at s
            if addr[first] != s:
                sys.exit(f'${bank:02X}: run ${s:04X} starts inside the line at ${addr[first]:04X}')
            nxt = min((i for i, a in addr.items() if a >= e), default=None)
            if nxt is None or addr[nxt] != e:
                sys.exit(f'${bank:02X}: run end ${e:04X} is not a line boundary')
            hi = nxt
            while hi > last + 1 and re.match(r'^[A-Za-z_]\w*:', lines[hi - 1]):
                hi -= 1                          # a label of the next line stays with it
            lab0 = first          # S166: the run's own first label (bank $12) goes with the run
            while lab0 > 0 and (re.match(r'^[A-Za-z_]\w*:', lines[lab0 - 1]) or
                                lines[lab0 - 1].startswith(';')):
                m0 = re.match(r'^([A-Za-z_]\w*):', lines[lab0 - 1])
                if m0 and m0.group(1) not in new_labels:
                    break
                lab0 -= 1
            if any(re.match(r'^([A-Za-z_]\w*):', lines[j]) for j in range(lab0, first)):
                while not re.match(r'^[A-Za-z_]\w*:', lines[lab0]):
                    lab0 += 1                 # keep the comment lines above the label
                first = lab0
            # labels inside [first, hi): none may be referenced from outside
            inner = [lines[i].split(':')[0] for i in range(first, hi)
                     if re.match(r'^[A-Za-z_]\w*:', lines[i])]
            for lab in inner:
                if lab in new_labels:
                    continue                         # re-emitted with the same name (bank $12)
                if _referenced_outside(lines, lab, first, hi, spans):
                    # S166: an mgbdis auto label inside a run that FAKE code in a data gap jumps to
                    # (bank $09 `jr z, jr_009_7cc9`): the reference becomes the same address as a
                    # number (byte-neutral; the gap is data, the jump never runs)
                    li = lines.index(lab + ':')
                    at = min((addr[i] for i in addr if i > li), default=None)
                    if not re.match(r'^(jr|jp|call|Jump|Call)_0[0-9a-f]{2}_[0-9a-f]{4}$', lab) or at is None:
                        sys.exit(f'${bank:02X}: label {lab} inside the run is referenced elsewhere')
                    deref.append((lab, at))
            old = '\n'.join(lines[first:hi])
            new = block_for(rom, bank, s, e, cen)
            # the k-th copy of the run's text in the clean tree = the k-th in the patched tree
            # (S166: bank $0A's two YES / NO streams $6F3C / $70C5 decode to the same lines)
            clean_before = '\n'.join(lines[:first]).count(old)
            cnt = ptext.count(old)
            if cnt != '\n'.join(lines).count(old) or cnt == 0:
                sys.exit(f'${bank:02X}: the patched tree does not hold the run ${s:04X} verbatim '
                         f'({cnt} copies)')
            region = f'win_words_{bank:02x}_{s:04x}'
            pnew = [f'; @BUILD_PROJECT BEGIN {region}'] + new + [f'; @BUILD_PROJECT END {region}']
            at = -1
            for _k in range(clean_before + 1):
                at = ptext.index(old, at + 1)
            ptext = ptext[:at] + '\n'.join(pnew) + ptext[at + len(old):]
            repl.append((first, hi, new))
            done.append((bank, s, e, hi - first, region))
        for first, hi, new in sorted(repl, reverse=True):
            lines[first:hi] = new
        for lab, at in deref:
            pat = re.compile(rf'\b{re.escape(lab)}\b')
            lines = [pat.sub(f'${at:04x}', l) if not l.startswith(lab + ':') else l for l in lines]
            ptext = pat.sub(f'${at:04x}', ptext)
            print(f'${bank:02X}: {lab} (inside a run) referenced from fake code -> ${at:04x}')
        if apply:
            open(asm, 'w').write('\n'.join(lines))
            open(patf, 'w').write(ptext)
    return done


def _referenced_outside(lines, lab, a, b, spans=()):
    pat = re.compile(rf'\b{re.escape(lab)}\b')
    return any(pat.search(l) for i, l in enumerate(lines)
               if not (a <= i < b) and not any(x <= i < y for x, y in spans)
               and not l.startswith(lab + ':'))


DRAWER_NOTE = ('; [S165] {name}: draw a window LAYOUT STREAM (DE = the stream: dw position, cells, $D8 '
               'newline, $D9 end) — {how}. DATA_STRUCTURES "Window layout streams (S165)".')


def drawers():
    """{bank: [(entry, name)]} from the census (entry A 'vram' = WinLayoutDrawVram<BB>, B =
    WinLayoutDraw<BB>)."""
    cen = json.load(open(CENSUS))
    out = {}
    for b, ents in cen['drawers'].items():
        bank = int(b, 16)
        out[bank] = [(int(e['entry'][1:], 16),
                      f"WinLayoutDraw{'Vram' if e['kind'] == 'vram' else ''}{bank:02X}") for e in ents]
    return out


def name_drawers(apply):
    """Name the drawer entries (both trees) — a new label line above the entry (an existing auto
    label stays: no reference changes) with a one-line note."""
    out = []
    for bank, ents in drawers().items():
        asm = os.path.join(DIS, f'bank_{bank:03x}.asm')
        texts = {t: open(os.path.join(t, f'bank_{bank:03x}.asm')).read() for t in (DIS, PAT)}
        todo = [(a, n) for a, n in ents if f'\n{n}:' not in texts[DIS]]
        if not todo:
            continue
        lines, addr = line_addrs(asm, bank)
        for a, name in todo:
            idx = [i for i, x in addr.items() if x == a]
            if not idx:
                sys.exit(f'${bank:02X}:{a:04X}: no line starts at the drawer entry')
            i = min(idx)
            while i > 0 and re.match(r'^[A-Za-z_]\w*:', lines[i - 1]):
                i -= 1                                   # above the entry's labels
            how = ('the BG map $9800+ (the row wraps at 32: `and $03 / or $98`), cells through '
                   'Write_gfx_tile' if 'Vram' in name else 'the screen buffer, cells `ld [hl+], a`')
            note = DRAWER_NOTE.format(name=name, how=how)
            if bank not in (0x07, 0x15):
                note = note.replace('[S165]', '[S166]')
            ctx = '\n'.join(lines[i:i + 6])
            k = '\n'.join(lines[:i]).count(ctx)      # the k-th copy (the drawers come in pairs)
            n_clean = '\n'.join(lines).count(ctx)
            for t in (DIS, PAT):
                if texts[t].count(ctx) != n_clean:
                    sys.exit(f'${bank:02X}:{a:04X}: the entry\'s lines differ between the trees ({t})')
                at = -1
                for _k in range(k + 1):
                    at = texts[t].index(ctx, at + 1)
                texts[t] = texts[t][:at] + f'{note}\n{name}:\n' + texts[t][at:]
            out.append((bank, name))
        if apply:
            for t, v in texts.items():
                open(os.path.join(t, f'bank_{bank:03x}.asm'), 'w').write(v)
    return out


def name_refs(apply):
    """`ld de, $<stream>` -> `ld de, <label>` in both trees (the same value: byte-neutral)."""
    cen = json.load(open(CENSUS))
    n = 0
    for bank in sorted({b for b, _s, _e in RUNS}):
        addrs = {L['addr'] for L in cen['layouts'].values() if L['bank'] == bank
                 and _WW._in_runs(bank, L['addr'])}
        for t in (DIS, PAT):
            p = os.path.join(t, f'bank_{bank:03x}.asm')
            txt = open(p).read()

            def sub(m):
                a = int(m.group(1), 16)
                return f'ld de, {_WW.label(bank, a)}' if a in addrs else m.group(0)
            new, k = re.subn(r'ld de, \$([0-9a-fA-F]{4})\b', sub, txt)
            k = sum(1 for m in re.finditer(r'ld de, \$([0-9a-fA-F]{4})\b', txt)
                    if int(m.group(1), 16) in addrs)
            n += k
            if apply and k:
                open(p, 'w').write(new)
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    a = ap.parse_args()
    done = resection(a.apply)
    for b, s, e, n, region in done:
        print(f'${b:02X} ${s:04X}-${e:04X}: {n} source lines -> db (region {region})')
    nd = name_drawers(a.apply)
    print(f'{len(nd)} drawer labels added')
    print(f'{name_refs(a.apply)} `ld de, $<stream>` named (both trees)')
    if a.apply:
        ok, log = build()
        got = md5(os.path.join(DIS, 'game.gbc')) if ok else None
        print('clean build:', got)
        if got != ORIGINAL_MD5:
            sys.exit('NOT byte-perfect\n' + log[-2000:])


if __name__ == '__main__':
    main()
