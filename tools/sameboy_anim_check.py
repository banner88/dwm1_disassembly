#!/usr/bin/env python3
"""sameboy_anim_check.py — cross-check a room's OWN tile animations
(custom.rooms[].tile_anims, bank $6C — PROJECT_COMPILER §2.19) in SameBoy,
whose PPU blocks VRAM writes during pixel transfer (mode 3) the way the
hardware does: a copy started at the wrong moment shows up as a tile that
matches none of its authored frames (S102 negative control: removing the
HBlank wait gave 631 bad tile-frames in 600 frames; the real build 0).

Boots <project>/build/build/rom.gbc with a battery save (CONTINUE), warps to
the room (the pyboy_harness warp mailbox), then for N frames compares the VRAM
of every animated slot with its authored frames.

Setup once (SameBoy core + CGB boot ROM, needs clang + RGBDS):
    git clone --depth 1 https://github.com/LIJI32/SameBoy.git /tmp/sameboy
    make -C /tmp/sameboy tester CONF=release
usage:
    python3 tools/sameboy_anim_check.py --project P --map 6C --x 5 --y 6 \
        --sav my.sav [--frames 600] [--sameboy /tmp/sameboy]
Exit 0 = every frame matched; 3 = mismatches (printed).
"""
import argparse
import os
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)


def expect_file(project, mid, out):
    from editor2.core.document import Document
    from editor2.core import tileanim as TA
    d = Document(project)
    room = next(r for r in d.rooms if int(str(r['mapID']), 0) == mid)
    sheet = bytes(d.read_sheet(room['record']['tileset']))
    slots = {}
    for it in room.get('tile_anims') or []:
        for part, blocks, _seq in TA.groups(it, sheet):
            for k, s in enumerate(part):
                slots[s] = list(dict.fromkeys(b[k * 16:k * 16 + 16] for b in blocks))
    with open(out, 'wb') as f:
        f.write(bytes([len(slots)]))
        for s, frs in slots.items():
            f.write(bytes([s, len(frs)]))
            f.write(b''.join(frs))
    return len(slots)


def build_harness(sb, exe):
    objs = os.path.join(sb, 'build', 'obj', 'Core')
    cmd = ['clang', '-O2', '-flto', '-std=gnu11', '-D_GNU_SOURCE', f'-I{sb}', '-o', exe,
           os.path.join(REPO, 'tools', 'sameboy', 'dwmcheck.c')] + \
        sorted(os.path.join(objs, n) for n in os.listdir(objs) if n.endswith('.o')) + ['-lm']
    subprocess.run(cmd, check=True, stderr=subprocess.DEVNULL)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--project', required=True)
    ap.add_argument('--map', required=True, help='hex map id, e.g. 6C')
    ap.add_argument('--x', type=int, default=4)
    ap.add_argument('--y', type=int, default=4)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--frames', type=int, default=600)
    ap.add_argument('--sameboy', default='/tmp/sameboy')
    ap.add_argument('--rom', default=None)
    a = ap.parse_args()
    mid = int(a.map, 16)
    tmp = tempfile.mkdtemp()
    exe = os.path.join(tmp, 'dwmcheck')
    build_harness(a.sameboy, exe)
    exp = os.path.join(tmp, 'expect.bin')
    n = expect_file(a.project, mid, exp)
    rom = a.rom or os.path.join(a.project, 'build', 'build', 'rom.gbc')
    print(f'{n} animated slot(s) in map ${mid:02X}')
    r = subprocess.run([exe, os.path.join(a.sameboy, 'build', 'bin', 'tester', 'cgb_boot.bin'),
                        rom, a.sav, exp, f'{mid:02X}', str(a.x), str(a.y), str(a.frames),
                        os.path.join(tmp, 'shot')])
    sys.exit(r.returncode)


if __name__ == '__main__':
    main()
