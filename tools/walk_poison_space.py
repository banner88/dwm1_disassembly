#!/usr/bin/env python3
"""walk_poison_space.py — the dynamic half of tools/audit_patch_space.py (S167): does the
ORIGINAL game ever read the bytes a patched build claims as free?

Method: the original ROM vs the original ROM with every claimed byte changed
(`audit_patch_space.py --poison`). Both run the same corpus in PyBoy; a
sitecustomize hook (written to a temp dir, put on PYTHONPATH — so worker processes of
a census are covered too) swaps the ROM of every PyBoy built on data/DWM-original.gbc
and writes, every 30 frames, a hash of WRAM / VRAM / OAM / HRAM. PyBoy is
deterministic: identical traces = the poisoned bytes were never read on that corpus.
(RAM / VRAM do not show SOUND — audio data is checked with the editor's sound engine,
KEY_LESSONS S167.)

Corpora:
  battle      new game → 8 gates (1 3 6 9 13 17 22 27) → a strong party monster, the field
              menu, 6 battles each played to the end (wins, level-ups)        ~25 min
  cutscenes   tools/census_cutscenes.py (519 scenes; its JSON compared too)  ~15 min × 2
  title       the boot, the title, a new game to the bedroom                 ~1 min

  python3 tools/walk_poison_space.py --poison P.gbc [--corpus battle,cutscenes,title]
  python3 tools/walk_poison_space.py --positive        # control: 2 bytes of the title menu
                                                        # poisoned — the title corpus MUST differ
Measured S167 (the example + the user's builds' claimed bytes): title / cutscenes (68 runs,
31,374 samples, the JSON equal) / battle (4,934 samples) identical; the positive control
differs in 55 samples. (One cutscene run once differed from its first sample — the first
worker of a fresh census; re-run twice it equals the poisoned run: a start-up timing artifact.)
"""
import argparse
import os
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIG = os.path.join(REPO, 'data', 'DWM-original.gbc')

HOOK = r'''
import os, hashlib, sys as _s
_rom = os.environ.get('POISON_ROM')
_dir = os.environ.get('TRACE_DIR')
if _dir:
    import pyboy as _pb
    _Orig = _pb.PyBoy
    _count = [0]
    class _Traced(_Orig):
        def __init__(self, gamerom, *a, **k):
            if _rom and os.path.realpath(str(gamerom)).endswith('DWM-original.gbc'):
                gamerom = _rom
            super().__init__(gamerom, *a, **k)
            _count[0] += 1
            key = hashlib.md5(' '.join(_s.argv[1:]).encode()).hexdigest()[:10]
            self._tr_f = open(os.path.join(_dir, f'trace_{key}_{_count[0]:04d}.txt'), 'w')
            self._tr_n = 0
        def tick(self, *a, **k):
            r = super().tick(*a, **k)
            c = a[0] if a else k.get('count', 1)
            old = self._tr_n
            self._tr_n += c
            if self._tr_n // 30 != old // 30:
                m = self.memory
                h = hashlib.md5(bytes(m[0xC000:0xE000]) + bytes(m[0x8000:0xA000]) +
                                bytes(m[0xFE00:0xFEA0]) + bytes(m[0xFF80:0xFFFF])).hexdigest()[:12]
                self._tr_f.write(f'{self._tr_n} {h}\n')
                self._tr_f.flush()
            return r
    _pb.PyBoy = _Traced
'''

TITLE = r'''
import sys; sys.path.insert(0, {repo!r})
from tools.pyboy_harness import *
p = boot({orig!r})
adv(p, 2000); to_bedroom(p); adv(p, 1500)
print('map', hex(p.memory[MAP_ID]))
'''

BATTLE = r'''
import sys; sys.path.insert(0, {repo!r})
from tools.pyboy_harness import *
p = boot({orig!r}); m = p.memory
assert to_bedroom(p)
adv(p, 200)
def hold(b, n):
    p.button_press(b); adv(p, n); p.button_release(b); adv(p, 4)
def battle(limit=9000):
    m[0xCA39], m[0xCA3A] = 0x01, 0x00
    for _ in range(60):
        hold('left', 18); hold('right', 18)
        if m[0xC88A] != 1 or m[0xC8EB] & 0x40:
            break
    else:
        return 'none'
    for f in range(limit // 8):
        p.button_press('a'); adv(p, 4); p.button_release('a'); adv(p, 4)
        if f > 100 and m[0xC88A] == 1 and m[0xC8EB] == 0:
            break
    adv(p, 120)
    for _ in range(4):
        tap(p, 'b', wait=10)
    return f'end map {{m[MAP_ID]:02X}}'
for gate in (1, 3, 6, 9, 13, 17, 22, 27):
    m[0xD8D7] = 0
    m[0xC96D], m[0xC96E], m[0xC96C], m[0xC88F] = gate, 1, 1, 1
    for _ in range(900):
        m[0xCA39], m[0xCA3A] = 0xFF, 0x7F
        p.tick()
    give_party_monster(p)
    for off, v in ((0x50, 999), (0x52, 999), (0x54, 300), (0x56, 300), (0x58, 600),
                   (0x5A, 600), (0x5C, 400), (0x5E, 200)):
        m[0xCAC1 + off], m[0xCAC1 + off + 1] = v & 0xFF, v >> 8
    m[0xCAC1 + 0x4B] = 3
    adv(p, 60)
    for k in ['a', 'a', 'b', 'b', 'down', 'a', 'a', 'b', 'b', 'right', 'a', 'a', 'b', 'b',
              'down', 'a', 'a', 'down', 'a', 'b', 'b', 'b', 'b']:
        tap(p, k, wait=30)
    for b in range(6):
        print(gate, b, battle())
        m[0xCA39], m[0xCA3A] = 0xFF, 0x7F
'''


def run(corpus, rom, tdir, hookdir, outjson=None):
    env = dict(os.environ, TRACE_DIR=tdir, PYTHONPATH=hookdir + os.pathsep + os.environ.get('PYTHONPATH', ''),
               QT_QPA_PLATFORM='offscreen')
    if rom != ORIG:
        env['POISON_ROM'] = rom
    else:
        env.pop('POISON_ROM', None)
    if corpus == 'cutscenes':
        cmd = [sys.executable, os.path.join(REPO, 'tools', 'census_cutscenes.py'), '--out', outjson, '--jobs', '1']
    else:
        src = (TITLE if corpus == 'title' else BATTLE).format(repo=REPO, orig=ORIG)
        f = os.path.join(hookdir, f'corpus_{corpus}.py')
        open(f, 'w').write(src)
        cmd = [sys.executable, f]
    r = subprocess.run(cmd, cwd=REPO, env=env, capture_output=True, text=True)
    return r.stdout


def compare(a, b):
    same, diff, samples = 0, [], 0
    for n in sorted(os.listdir(a)):
        x = open(os.path.join(a, n)).read()
        y = open(os.path.join(b, n)).read() if os.path.exists(os.path.join(b, n)) else None
        samples += x.count('\n')
        if x == y:
            same += 1
        else:
            diff.append(n)
    return same, diff, samples


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--poison')
    ap.add_argument('--corpus', default='title,battle')
    ap.add_argument('--positive', action='store_true')
    a = ap.parse_args()
    work = tempfile.mkdtemp(prefix='poison_')
    hookdir = os.path.join(work, 'hook')
    os.makedirs(hookdir)
    open(os.path.join(hookdir, 'sitecustomize.py'), 'w').write(HOOK)
    rom = a.poison
    corpora = a.corpus.split(',')
    if a.positive:
        import re
        r = bytearray(open(ORIG, 'rb').read())
        for mm in re.finditer(re.escape(bytes.fromhex('31283ae02a243028')), r):
            r[mm.start()] = 0x2A                          # the title menu's NEW GAME, N -> G
        rom = os.path.join(work, 'positive.gbc')
        open(rom, 'wb').write(bytes(r))
        corpora = ['title']
    if not rom:
        ap.error('--poison ROM (tools/audit_patch_space.py --poison) or --positive')
    bad = 0
    for c in corpora:
        ta, tb = os.path.join(work, c + '_A'), os.path.join(work, c + '_B')
        os.makedirs(ta)
        os.makedirs(tb)
        oa = run(c, ORIG, ta, hookdir, os.path.join(work, c + '_A.json'))
        ob = run(c, rom, tb, hookdir, os.path.join(work, c + '_B.json'))
        same, diff, n = compare(ta, tb)
        extra = ''
        if c == 'cutscenes':
            import json
            ja = json.load(open(os.path.join(work, c + '_A.json')))
            jb = json.load(open(os.path.join(work, c + '_B.json')))
            extra = f', census JSON {"equal" if ja == jb else "DIFFERS"}'
            bad += ja != jb
        print(f'{c}: {same} traces identical, {len(diff)} differ ({n} samples){extra}'
              + ('' if oa == ob else ' — the corpus output differs'))
        for d in diff[:5]:
            print('   differs:', d)
        bad += len(diff) + (oa != ob)
    if a.positive:
        print('positive control:', 'OK (differs)' if bad else 'FAIL (no difference seen)')
        return 0 if bad else 1
    print('ALL IDENTICAL' if not bad else f'{bad} DIFFERENCES — a claimed byte is read (or a timing artifact: re-run the run)')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
