#!/usr/bin/env python3
"""census_vram_bank1.py — does the ORIGINAL game ever write VRAM bank 1's TILE area, or draw a
background cell from it? (S168, ROADMAP P3.3g — "page 2": a custom room's second 128 tiles
live in VRAM bank 1 $9000-$97FF, picked per cell by attribute bit 3.)

Method: a sitecustomize hook (temp dir on PYTHONPATH, so census worker processes are covered
too) wraps every PyBoy built on data/DWM-original.gbc. On its first frame the hook SEEDS
VRAM bank 1 $8000-$97FF with a pattern (a write of zeros or of the game's own bytes is seen
too); every 15 frames it compares the area with the seed and logs each NEW changed run
(frame, address range, map id, game mode $C88A), and counts the background cells of both
attribute maps ($9800 / $9C00, bank 1) whose attribute has bit 3 (= drawn from bank 1).
The corpora are tools/walk_poison_space.py's (S167): `title`, `battle` (8 gates, 6 battles
each, the field menu) and `cutscenes` (tools/census_cutscenes.py, 519 scenes).

  python3 tools/census_vram_bank1.py [--corpus title,battle,cutscenes] [--rom R.gbc]
          [--json extracted/vram_bank1_census.json]

`--positive` = control: the hook itself writes one bank-1 tile byte at frame 600 and sets
one attribute bit 3 — both MUST be reported.
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIG = os.path.join(REPO, 'data', 'DWM-original.gbc')
sys.path.insert(0, os.path.join(REPO, 'tools'))
import walk_poison_space as WPS  # noqa: E402  (the S167 corpora)

HOOK = r'''
import os, sys as _s, json as _j
_dir = os.environ.get('VB1_DIR')
_rom = os.environ.get('VB1_ROM')
_pos = os.environ.get('VB1_POSITIVE')
if _dir:
    import pyboy as _pb
    _Orig = _pb.PyBoy
    _count = [0]
    def _seed(a):
        return (a * 7 + (a >> 8) * 13 + 0x5A) & 0xFF
    class _Traced(_Orig):
        def __init__(self, gamerom, *a, **k):
            if _rom and os.path.realpath(str(gamerom)).endswith('DWM-original.gbc'):
                gamerom = _rom
            super().__init__(gamerom, *a, **k)
            _count[0] += 1
            self._vb_n = 0
            self._vb_seeded = False
            self._vb_cur = None
            self._vb_log = open(os.path.join(_dir, f'log_{os.getpid()}_{_count[0]:04d}.jsonl'), 'w')
            self._vb_attr_seen = set()
        def _vb_sample(self):
            m = self.memory
            cur = bytes(m[1, 0x8000:0x9800])
            if self._vb_cur is not None and cur != self._vb_cur:
                runs, a = [], 0
                while a < len(cur):
                    if cur[a] != self._vb_cur[a]:
                        b = a
                        while b < len(cur) and cur[b] != self._vb_cur[b]:
                            b += 1
                        runs.append([0x8000 + a, 0x8000 + b - 1])
                        a = b
                    else:
                        a += 1
                self._vb_log.write(_j.dumps({'kind': 'tiles', 'frame': self._vb_n, 'runs': runs[:40],
                    'nruns': len(runs), 'map': m[0xC968], 'gate': m[0xC969], 'mode': m[0xC88A],
                    'state': m[0xC8EB]}) + '\n')
                self._vb_log.flush()
            self._vb_cur = cur
            for base in (0x9800, 0x9C00):
                attrs = bytes(m[1, base:base + 0x3FF]) + bytes([m[1, base + 0x3FF]])  # PyBoy: a slice may not end at $A000
                n = sum(1 for x in attrs if x & 0x08)
                if n:
                    key = (base, m[0xC968], m[0xC88A], n)
                    if key not in self._vb_attr_seen:
                        self._vb_attr_seen.add(key)
                        self._vb_log.write(_j.dumps({'kind': 'attr', 'frame': self._vb_n, 'base': base,
                            'cells': n, 'map': m[0xC968], 'gate': m[0xC969], 'mode': m[0xC88A],
                            'state': m[0xC8EB]}) + '\n')
                        self._vb_log.flush()
        def tick(self, *a, **k):
            r = super().tick(*a, **k)
            c = a[0] if a else k.get('count', 1)
            old = self._vb_n
            self._vb_n += c
            m = self.memory
            if not self._vb_seeded:
                for x in range(0x8000, 0x9800):
                    m[1, x] = _seed(x)
                self._vb_seeded = True
                self._vb_cur = bytes(m[1, 0x8000:0x9800])
            if _pos and old < 600 <= self._vb_n:
                m[1, 0x9123] = m[1, 0x9123] ^ 0xFF
                m[1, 0x9800] = m[1, 0x9800] | 0x08
            if self._vb_n // 15 != old // 15:
                self._vb_sample()
            return r
    _pb.PyBoy = _Traced
'''


def run(corpus, rom, logdir, hookdir, positive=False):
    env = dict(os.environ, VB1_DIR=logdir,
               PYTHONPATH=hookdir + os.pathsep + os.environ.get('PYTHONPATH', ''),
               QT_QPA_PLATFORM='offscreen')
    env.pop('VB1_ROM', None)
    env.pop('VB1_POSITIVE', None)
    if rom and os.path.realpath(rom) != os.path.realpath(ORIG):
        env['VB1_ROM'] = rom
    if positive:
        env['VB1_POSITIVE'] = '1'
    if corpus == 'cutscenes':
        out = os.path.join(logdir, 'cutscenes.json')
        cmd = [sys.executable, os.path.join(REPO, 'tools', 'census_cutscenes.py'), '--out', out, '--jobs', '1']
    else:
        src = (WPS.TITLE if corpus == 'title' else WPS.BATTLE).format(repo=REPO, orig=ORIG)
        f = os.path.join(hookdir, f'corpus_{corpus}.py')
        open(f, 'w').write(src)
        cmd = [sys.executable, f]
    r = subprocess.run(cmd, cwd=REPO, env=env, capture_output=True, text=True)
    return r.returncode, r.stdout[-2000:], r.stderr[-2000:]


def collect(logdir):
    tiles, attrs, runs = [], [], 0
    for n in sorted(os.listdir(logdir)):
        if not n.startswith('log_'):
            continue
        runs += 1
        for line in open(os.path.join(logdir, n)):
            e = json.loads(line)
            (tiles if e['kind'] == 'tiles' else attrs).append(e)
    return runs, tiles, attrs


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--corpus', default='title,battle,cutscenes')
    ap.add_argument('--rom', default=ORIG)
    ap.add_argument('--json')
    ap.add_argument('--positive', action='store_true')
    a = ap.parse_args()
    work = tempfile.mkdtemp(prefix='vb1_')
    hookdir = os.path.join(work, 'hook')
    os.makedirs(hookdir)
    open(os.path.join(hookdir, 'sitecustomize.py'), 'w').write(HOOK)
    corpora = ['title'] if a.positive else a.corpus.split(',')
    result = {'_generator': 'tools/census_vram_bank1.py (S168) on ' + os.path.basename(a.rom),
              'corpora': {}}
    for c in corpora:
        logdir = os.path.join(work, c)
        os.makedirs(logdir)
        rc, out, err = run(c, a.rom, logdir, hookdir, a.positive)
        runs, tiles, attrs = collect(logdir)
        result['corpora'][c] = {'emulator_runs': runs, 'returncode': rc,
                                'corpus_output_tail': out.splitlines()[-60:],
                                'tile_writes': tiles, 'attr_bit3': attrs}
        print(f'{c}: {runs} PyBoy runs, rc {rc}; bank-1 tile-area changes: {len(tiles)}; '
              f'screens with attr bit 3: {len(attrs)}')
        for e in tiles[:12]:
            print('   tiles', e['frame'], [f'${x:04X}-${y:04X}' for x, y in e['runs'][:6]], 'runs', e['nruns'],
                  f"map ${e['map']:02X} gate {e['gate']} mode {e['mode']} state ${e['state']:02X}")
        for e in attrs[:12]:
            print('   attr ', e['frame'], f"${e['base']:04X}", e['cells'], 'cells',
                  f"map ${e['map']:02X} gate {e['gate']} mode {e['mode']}")
        if rc:
            print(err)
    if a.json:
        with open(a.json, 'w') as f:
            json.dump(result, f, indent=1)
    if a.positive:
        t = result['corpora']['title']
        ok = bool(t['tile_writes']) and bool(t['attr_bit3'])
        print('positive control:', 'OK (both reported)' if ok else 'FAIL')
        return 0 if ok else 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
