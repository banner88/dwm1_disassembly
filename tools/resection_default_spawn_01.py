#!/usr/bin/env python3
"""resection_default_spawn_01.py — S152: bank $01's DEFAULT PLAYER SPAWN table
as labelled `dw` rows (both trees; zero byte impact).

The table at $01:$4506 (auto-label `NPCWalkDataTable` — a misnomer, S66) is read
by LoadFieldTilesDMA (`jr_001_4464`) on the NON-warp room load: wIsPlayerChangingMaps
= 0 and $C8EA = 0, i.e. a NEW GAME (measured S152, PyBoy: the new game's room =
the bedroom $2F -> row $2F = (4, 11), Terry's bed). 4 bytes a map: X lo, X hi,
Y lo, Y hi (pixels, cell * 16 + 8) -> HRAM $FF92 / $FF93 / $FF95 / $FF96.

S152 correction: the table has **96** rows (maps $00-$5F) — it ends where
`ScanPartySlotTable` ($01:$4686 = $4506 + $60 * 4) begins; maps $60-$6A would
read that routine's code (the S66 note said 107; never reached: only a new game
takes this path). Patched builds read it through ROM0 MapIDClampForPalette (a
custom room -> row $16).

Rewrites the mis-decoded instruction block between `DefaultSpawnTable:` (or the
old `NPCWalkDataTable:`) and `ScanPartySlotTable:` into 96 `dw x, y` rows with
the cell in a comment, and renames the label (+ its two LOW / HIGH references).
Idempotent. The row values come from the ROM; `--check` verifies an already
re-sectioned file against it.

    python3 tools/resection_default_spawn_01.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
TREES = [os.path.join(REPO, 'disassembly', 'bank_001.asm'),
         os.path.join(REPO, 'patches', 'bank_001.asm')]
START, ROWS = 0x4506, 0x60
OLD, NEW = 'NPCWalkDataTable', 'DefaultSpawnTable'
END_LABEL = 'ScanPartySlotTable:'

HEADER = """\
; DefaultSpawnTable (S66 note; re-sectioned + renamed S152 — was the auto-label
; NPCWalkDataTable): the DEFAULT PLAYER SPAWN per map, 4 bytes a map (X lo/hi,
; Y lo/hi in pixels = cell * 16 + 8 -> HRAM $92/$93/$95/$96), read by the
; NON-warp room load (jr_001_4464: wIsPlayerChangingMaps = 0 and $C8EA = 0) —
; only a NEW GAME takes that path (measured S152, PyBoy: map $2F -> (4, 11),
; Terry's bed in the intro bedroom). 96 rows, maps $00-$5F: the table ends where
; ScanPartySlotTable begins ($4506 + $60 * 4 = $4686), so maps $60-$6A would
; read code (never reached; the S66 note said 107). Patched builds index it
; through ROM0 MapIDClampForPalette (a custom room -> row $16) and a new game
; can start elsewhere: custom.new_game (bank $79 entry 2 NewGameStart puts the
; start cell in the warp mailbox, so this table is not read).
"""


def rows(rom):
    out = []
    for m in range(ROWS):
        o = 0x4000 * 1 + (START - 0x4000) + 4 * m
        x = rom[o] | rom[o + 1] << 8
        y = rom[o + 2] | rom[o + 3] << 8
        cx, cy = (x - 8) // 16, (y - 8) // 16
        out.append(f'    dw ${x:04X}, ${y:04X}   ; map ${m:02X}: cell ({cx}, {cy})')
    return out


def rewrite(path, rom):
    s = open(path).read()
    lines = s.split('\n')
    try:
        i = next(k for k, ln in enumerate(lines) if ln.strip() in (OLD + ':', NEW + ':'))
    except StopIteration:
        raise SystemExit(f'{path}: no {OLD}: / {NEW}: label')
    j = next(k for k in range(i, len(lines)) if lines[k].strip() == END_LABEL)
    # the comment block right above the label (the S66 note / an older header)
    h = i
    while h > 0 and lines[h - 1].startswith(';'):
        h -= 1
    new = HEADER.rstrip('\n').split('\n') + [NEW + ':'] + rows(rom) + ['']
    lines = lines[:h] + new + lines[j:]
    s = '\n'.join(lines)
    s = s.replace(f'LOW({OLD})', f'LOW({NEW})').replace(f'HIGH({OLD})', f'HIGH({NEW})')
    return s


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    rom = open(ROM, 'rb').read()
    bad = 0
    for p in TREES:
        new = rewrite(p, rom)
        if a.check:
            if open(p).read() != new:
                print(f'NOT re-sectioned / stale: {p}')
                bad += 1
            else:
                print(f'ok: {p}')
        else:
            open(p, 'w').write(new)
            print(f'rewrote {p}')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
