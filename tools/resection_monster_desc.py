#!/usr/bin/env python3
"""
resection_monster_desc.py — bank $4D: the 215 monster DESCRIPTIONS (the library
detail page's line 2, text mode 1) as labelled `db` rows, and the mode-1
pointer words (dispatch entries 261-475) as label references. S108, ROADMAP
P3.10 part 3 (Iron Rule 6: the block was mgbdis fake code in both trees).

WHAT
  * `$4D:$53D3-$7719` = 215 strings, one per species 0-214, in id order, no
    gaps, no sharing (ROM-verified S108): up to 3 lines of <= 18 cells,
    lines split by $F1, terminated by $F0. Extra glyphs: $9C '-', $B6 '&',
    $67 "'t", $68 "'s".
  * Each becomes `MonsterDesc_NNN_<Name>:` + one `db` row (decoded text in a
    comment). The byte after the block ($771A, the first byte of the bank's
    zero tail) was fused with the last terminator into a fake `ldh a, [rP1]`
    (= $F0 $00); it is re-emitted as `db $00`.
  * The pointer table words `dw $XXXX ; Entry 261..475` become
    `dw MonsterDesc_NNN_<Name>` (each checked against the ROM word).
  * No label inside the old fake-code run is referenced from anywhere
    (census at --apply time; it refuses otherwise).

  Labels/comments only: the clean build must stay 1ca6579…; the patched tree
  gets the same edit (its region is byte-identical; the compiler later owns it
  as the region `gd_monster_desc`, PROJECT_COMPILER §2.24).

USAGE
  python3 tools/resection_monster_desc.py            # plan (counts, no write)
  python3 tools/resection_monster_desc.py --apply    # both trees + clean build md5 check
"""
import glob
import hashlib
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from dwm.text import TABLE  # noqa: E402

ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'
BANK = 0x4D
BLOCK_START, BLOCK_END = 0x53D3, 0x771A          # [start, end)
TABLE_BASE, FIRST_ENTRY, COUNT = 0x4001, 261, 215
EXTRA = {0x9C: '-', 0xB6: '&', 0x67: "'t", 0x68: "'s", 0xF1: '/'}


def rom():
    return open(ROM, 'rb').read()


def word(R, addr):
    o = BANK * 0x4000 + addr - 0x4000
    return R[o] | R[o + 1] << 8


def string(R, addr):
    o = BANK * 0x4000 + addr - 0x4000
    e = R.index(b'\xf0', o)
    return R[o:e + 1]


def species_names(R):
    out = []
    for i in range(COUNT):
        o = 0x41 * 0x4000 + 0x4339 + 2 * i - 0x4000
        p = R[o] | R[o + 1] << 8
        q = 0x41 * 0x4000 + p - 0x4000
        e = R.index(b'\xf0', q)
        out.append(''.join(TABLE.get(b, '') for b in R[q:e]))
    return out


def decode(bs):
    return ''.join(EXTRA.get(b) or TABLE.get(b) or '{%02X}' % b for b in bs if b != 0xF0)


def label(i, name):
    return f"MonsterDesc_{i:03d}_{re.sub(r'[^A-Za-z0-9]', '', name) or 'X'}"


def plan(R):
    names = species_names(R)
    rows, a = [], BLOCK_START
    for i in range(COUNT):
        p = word(R, TABLE_BASE + 2 * (FIRST_ENTRY + i))   # entry N at $4001 + 2N
        if p != a:
            raise SystemExit(f'species {i}: pointer ${p:04X} != expected ${a:04X} (block not in id order)')
        s = string(R, p)
        rows.append((i, label(i, names[i]), p, s))
        a += len(s)
    if a != BLOCK_END:
        raise SystemExit(f'block ends at ${a:04X}, expected ${BLOCK_END:04X}')
    return rows


def block_text(R, rows):
    out = ['; ' + '=' * 77,
           '; MONSTER DESCRIPTIONS ($53D3-$7719) — text mode 1 (base $420B = dispatch',
           '; entries 261-475), one string per species 0-214, id order. Library detail',
           '; page line 2: <= 3 lines of <= 18 cells, $F1 = next line, $F0 = end.',
           "; Glyphs beyond the charmap letters: $9C '-', $B6 '&', $67 \"'t\", $68 \"'s\".",
           '; S108 re-section (tools/resection_monster_desc.py; was mgbdis fake code);',
           '; bytes unchanged. Patched tree: the compiler region gd_monster_desc',
           '; (gamedata.monster_text, PROJECT_COMPILER §2.24).',
           '; ' + '=' * 77]
    for i, lab, p, s in rows:
        out.append(f'{lab}:  ; ${p:04X} "{decode(s)}"')
        out.append('    db ' + ', '.join(f'${b:02X}' for b in s))
    out.append('; $771A: first byte of the bank\'s zero tail (was fused with the last')
    out.append(';        terminator into a fake `ldh a, [rP1]` = $F0 $00)')
    out.append('    db $00')
    return out


def apply_tree(path, R, rows, write):
    L = open(path).read().split('\n')
    if any(l.startswith('MonsterDesc_000_') for l in L):
        print(f'{path}: already re-sectioned')
        return False
    s = next(i for i, l in enumerate(L) if 'split from a mis-decoded' in l and '$53D3' in l)
    e = next(i for i in range(s, len(L)) if L[i].strip() == 'ldh a, [rP1]')
    labs = [m.group(1) for l in L[s:e + 1] for m in [re.match(r'^([A-Za-z_][\w.]*):', l)] if m]
    rest = '\n'.join(L[:s] + L[e + 1:])
    tree = os.path.dirname(path)
    others = ''.join(open(f).read() for f in glob.glob(os.path.join(tree, '*.asm'))
                     if not f.endswith('bank_04d.asm'))
    used = [x for x in labs if re.search(r'\b' + re.escape(x) + r'\b', rest + others)]
    if used:
        raise SystemExit(f'{path}: labels inside the region are referenced: {used}')
    # pointer words
    n = 0
    for k, l in enumerate(L):
        m = re.match(r'(\s+dw )\$([0-9A-Fa-f]{4})(\s*; Entry (\d+))\s*$', l)
        if m and FIRST_ENTRY <= int(m.group(4)) < FIRST_ENTRY + COUNT:
            i = int(m.group(4)) - FIRST_ENTRY
            if int(m.group(2), 16) != rows[i][2]:
                raise SystemExit(f'{path}: Entry {m.group(4)} = ${m.group(2)} != ROM ${rows[i][2]:04X}')
            L[k] = f'{m.group(1)}{rows[i][1]:<30}{m.group(3)} (${rows[i][2]:04X})'
            n += 1
    if n != COUNT:
        raise SystemExit(f'{path}: found {n} mode-1 pointer words, expected {COUNT}')
    L = L[:s] + block_text(R, rows) + L[e + 1:]
    print(f'{path}: region lines {s + 1}-{e + 1} ({e - s + 1}) -> {COUNT} rows; {n} pointer words; '
          f'{len(labs)} dead fake labels dropped')
    if write:
        open(path, 'w').write('\n'.join(L))
    return True


def clean_md5():
    dis = os.path.join(REPO, 'disassembly')
    for f in ('game.o', 'game.gbc', 'game.sym', 'game.map'):
        try:
            os.remove(os.path.join(dis, f))
        except FileNotFoundError:
            pass
    subprocess.run(['make'], cwd=dis, check=True, capture_output=True)
    return hashlib.md5(open(os.path.join(dis, 'game.gbc'), 'rb').read()).hexdigest()


def main():
    R = rom()
    rows = plan(R)
    write = '--apply' in sys.argv
    for tree in ('disassembly', 'patches'):
        apply_tree(os.path.join(REPO, tree, 'bank_04d.asm'), R, rows, write)
    if write:
        m = clean_md5()
        print('clean build md5', m, 'OK' if m == ORIGINAL_MD5 else 'MISMATCH')
        if m != ORIGINAL_MD5:
            sys.exit(1)


if __name__ == '__main__':
    main()
