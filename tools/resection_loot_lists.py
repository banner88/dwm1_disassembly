#!/usr/bin/env python3
"""resection_loot_lists.py — S157 (ROADMAP E9, the one-only rule): the two short item
lists of the random gates as labelled `db` rows (both trees; zero byte impact).

  * bank $16 `RareChestItems` ($16:$6E04, 16 B): the one-rare-chest treasure room's
    item, one of 16 (CallBrd_6ddb: wRNG1 & 3 = the chest $D9CF + 0-3, wRNG1 & 15 = the
    row). It was an unlabelled `db` row read through `ld de, $6e04`.
  * bank $04 `ColiseumPrizesLow` / `ColiseumPrizesHigh` ($04:$6F44 / $6F54, 16 B each):
    the gate Coliseum's prize (op $5C ColiseumInitPrize: [$D9CF] < 9 -> the low list,
    else the high one; wRNG1 & 15 = the row -> [$D9D0]; op $5D gives it). mgbdis
    decoded them as fake code between SaveScr_6f35 and ScriptCmd5D_GiveColiseumPrize
    (one fake `jr nz, FindEmptySlotLoop` among them).

The values come from the ROM; the item names from editor2/core/shops.item_names.
In the PATCHED tree each list sits inside a compiler region (`gd_rare_chest`,
`gd_coliseum_prizes`; editor2/core/loot.py) — written here with the original bytes.
Idempotent; `--check` verifies already re-sectioned files against the ROM.

    python3 tools/resection_loot_lists.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
TREES = {'clean': os.path.join(REPO, 'disassembly'), 'patched': os.path.join(REPO, 'patches')}

RARE_ADDR, PRIZE_ADDR = 0x6E04, 0x6F44


def _b(rom, bank, addr, n):
    o = bank * 0x4000 + addr - 0x4000
    return rom[o:o + n]


def names():
    from editor2.core.shops import item_names
    return item_names(REPO)


def db_row(bs, nm):
    return ("    db " + ", ".join(f"${x:02x}" for x in bs)
            + "   ; " + " ".join(nm.get(x, f"${x:02X}") for x in bs))


RARE_HEAD = """\
; RareChestItems ($16:$6E04; labelled S157): the one-rare-chest treasure room's item —
; CallBrd_6ddb puts row (wRNG1 & 15) into chest $D9CF + (wRNG1 & 3), the other chests
; stay empty (SpecialRoom1_OneRareChest). 16 rows, each 1/16."""

PRIZE_HEAD = """\
; ColiseumPrizesLow / ColiseumPrizesHigh ($04:$6F44 / $6F54; re-sectioned S157 — mgbdis
; decoded them as code): the gate Coliseum's prize. Op $5C ColiseumInitPrize picks the
; LOW list when [$D9CF] < 9, else the HIGH one, row wRNG1 & 15 -> [$D9D0]; op $5D
; (ScriptCmd5D_GiveColiseumPrize) gives it after the win. 16 rows each, 1/16 a row."""


def region(name, lines, patched):
    if not patched:
        return lines
    return ([f"; @BUILD_PROJECT BEGIN {name}"] + lines + [f"; @BUILD_PROJECT END {name}"])


def rare_block(rom, nm, patched):
    return (RARE_HEAD.split('\n')
            + region('gd_rare_chest',
                     ["RareChestItems:", db_row(_b(rom, 0x16, RARE_ADDR, 16), nm)], patched))


def prize_block(rom, nm, patched):
    lo, hi = _b(rom, 0x04, PRIZE_ADDR, 16), _b(rom, 0x04, PRIZE_ADDR + 16, 16)
    return (PRIZE_HEAD.split('\n')
            + region('gd_coliseum_prizes',
                     ["ColiseumPrizesLow:", db_row(lo, nm), "ColiseumPrizesHigh:", db_row(hi, nm)],
                     patched))


def fix16(path, rom, nm, patched):
    s = open(path).read()
    lines = s.split('\n')
    if 'RareChestItems:' in s:
        i = next(k for k, ln in enumerate(lines) if ln.strip() == 'RareChestItems:')
        h = i
        while h > 0 and (lines[h - 1].startswith(';')):
            h -= 1
        j = i + 2
        while j < len(lines) and lines[j].startswith('; @BUILD_PROJECT END'):
            j += 1
    else:
        want = db_row(_b(rom, 0x16, RARE_ADDR, 16), nm).split(';')[0].rstrip()
        i = next(k for k, ln in enumerate(lines) if ln.rstrip() == want)
        h, j = i, i + 1
    lines = lines[:h] + rare_block(rom, nm, patched) + lines[j:]
    s = '\n'.join(lines)
    s = s.replace('    ld de, $6e04\n', '    ld de, RareChestItems   ; S157 (was $6e04)\n')
    return s


def fix04(path, rom, nm, patched):
    s = open(path).read()
    lines = s.split('\n')
    end = next(k for k, ln in enumerate(lines) if ln.startswith('ScriptCmd5D_GiveColiseumPrize:'))
    if 'ColiseumPrizesLow:' in s:
        i = next(k for k, ln in enumerate(lines) if ln.strip() == 'ColiseumPrizesLow:')
        h = i
        while h > 0 and lines[h - 1].startswith(';'):
            h -= 1
    else:
        a = next(k for k, ln in enumerate(lines) if ln.startswith('SaveScr_6f35:'))
        r = next(k for k in range(a, end) if lines[k].strip() == 'ret')
        h = r + 1
        while lines[h].strip() == '':
            h += 1
        assert lines[h].strip() == 'inc bc', lines[h]
    lines = lines[:h] + prize_block(rom, nm, patched) + [''] + lines[end:]
    s = '\n'.join(lines)
    s = s.replace('    ld hl, $6f44\n', '    ld hl, ColiseumPrizesLow    ; S157 (was $6f44)\n')
    s = s.replace('    ld hl, $6f54\n', '    ld hl, ColiseumPrizesHigh   ; S157 (was $6f54)\n')
    return s


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    rom = open(ROM, 'rb').read()
    nm = names()
    bad = 0
    for tree, d in TREES.items():
        patched = tree == 'patched'
        for fn, fix in (('bank_016.asm', fix16), ('bank_004.asm', fix04)):
            p = os.path.join(d, fn)
            new = fix(p, rom, nm, patched)
            old = open(p).read()
            if a.check:
                if new != old:
                    print(f"DIFF {p}")
                    bad += 1
                else:
                    print(f"ok   {p}")
            elif new != old:
                open(p, 'w').write(new)
                print(f"wrote {p}")
            else:
                print(f"same  {p}")
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
