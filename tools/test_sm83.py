#!/usr/bin/env python3
"""test_sm83.py — S116: check dwm/sm83.py against the SingleStepTests SM83 suite
(https://github.com/SingleStepTests/sm83, directory v1/: 500 opcode files x 1,000
cases; registers + memory before / after one instruction).

  git clone --depth 1 https://github.com/SingleStepTests/sm83.git /tmp/sm83
  python3 tools/test_sm83.py /tmp/sm83/v1 [--per-file N]

Skipped: HALT ($76), STOP ($10) (the interpreter raises instead of halting), the
11 illegal opcodes, and EI's delayed IME (the interpreter sets IME at once; DI /
EI / RETI are checked for registers only).
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dwm.sm83 import CPU, A, F, B, C, D, E, H, L, SP, PC

SKIP = {0x76, 0x10, 0xD3, 0xDB, 0xDD, 0xE3, 0xE4, 0xEB, 0xEC, 0xED, 0xF4, 0xFC, 0xFD}
NAMES = {'a': A, 'f': F, 'b': B, 'c': C, 'd': D, 'e': E, 'h': H, 'l': L, 'sp': SP, 'pc': PC}


def main():
    d = sys.argv[1]
    per = int(sys.argv[sys.argv.index('--per-file') + 1]) if '--per-file' in sys.argv else None
    mem = {}
    cpu = CPU(lambda a: mem.get(a, 0), lambda a, v: mem.__setitem__(a, v & 0xFF))
    bad = total = 0
    for fn in sorted(os.listdir(d)):
        op = int(fn[:2], 16)
        if fn.startswith('cb'):
            pass
        elif op in SKIP:
            continue
        cases = json.load(open(os.path.join(d, fn)))
        if per:
            cases = cases[:per]
        fails = 0
        for t in cases:
            ini, fin = t['initial'], t['final']
            mem.clear()
            for a, v in ini['ram']:
                mem[a] = v
            for k, i in NAMES.items():
                cpu.R[i] = ini[k]
            pc = cpu.R[PC]
            o = mem.get(pc, 0)
            cpu.R[PC] = (pc + 1) & 0xFFFF
            cpu._ops[o]()
            ok = all(cpu.R[i] == fin[k] for k, i in NAMES.items()) and \
                all(mem.get(a, 0) == v for a, v in fin['ram'])
            total += 1
            if not ok:
                fails += 1
                if fails <= 2:
                    print('FAIL', t['name'], {k: (cpu.R[i], fin[k]) for k, i in NAMES.items()
                                               if cpu.R[i] != fin[k]})
        bad += fails
    print(f'{total} cases, {bad} failed')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
