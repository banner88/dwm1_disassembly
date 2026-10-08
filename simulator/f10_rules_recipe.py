#!/usr/bin/env python3
"""S130 F10: generates the AI-chain corpus recipe for
simulator/measure_f10_rules.py (simulator/f10_rules_events.json): random but
seeded per-round boards around the DeMagic/ThickFog rule conditions.
Usage: python3 simulator/f10_rules_recipe.py > recipe.txt  (one battle per line),
then per line: python3 simulator/measure_f10_rules.py <line> --out
simulator/f10_rules_events.json; gzip -9 it (simulator/validate_f10_rules.py:
332 cat-2 chain runs, 0 mismatches)."""
import random

R = random.Random(130)
BIG = [0x02, 0x05, 0x08, 0x0B, 0x0E, 0x11, 0x12, 0x13]
OTHER = [0x00, 0x03, 0x2B, 0x3A, 0x5E, 0x15, 0x29, 0x80, 0xD5, 0x42, 0x6F]


def pick_bits(p, mask):
    return sum(1 << k for k in range(8) if (mask >> k) & 1 and R.random() < p)


NO69 = {3: ~0xC2 & 0xFF, 4: ~0x10 & 0xFF, 5: 0xFF, 7: ~0x03 & 0xFF, 8: ~0x80 & 0xFF}
lines = []
for n in range(28):
    eid = 7
    dd0b = 2 if n % 2 else 1
    args = [f'r{n:02d}', str(eid), '--php 900 --pmp 250 --ehp 9999 --emp 200', '--rounds 10',
            f'--skip {3 * n}', f'--poke all:DD0F={dd0b}']
    # the enemy option list: DeMagic + ThickFog + 0-3 own skills (593d's k)
    own = [(2, 0x80), (2, 0x83)] + [(R.choice([1, 2, 3]), R.choice(BIG + OTHER)) for _ in range(R.randint(0, 3))]
    args.append('--elist 4:' + ','.join(f'{t}:{s:#x}' for t, s in own))
    for rnd in range(11):
        dens = R.choice([0.0, 0.04, 0.08, 0.2, 0.4])
        mode = R.choice(['free', 'no69', 'no69'])   # no69: none of AIRule_69cb's bits
        for s in range(3):
            base = 0xDB00 + 8 * s
            vals = {3: pick_bits(dens, 0xFF), 4: pick_bits(dens, 0xFF), 5: pick_bits(dens, 0xC0) | (pick_bits(dens / 3, 0x3F)),
                    7: pick_bits(dens, 0xCF), 8: pick_bits(dens, 0xFF)}
            if mode == 'no69':
                vals = {k: v & NO69[k] for k, v in vals.items()}
            if s == 0 and R.random() < 0.2:
                vals[2] = R.choice([0x80, 0x40, 0x10, 0x01])
            for off, v in vals.items():
                args.append(f'--poke {rnd}:{base + off:04X}={v:#x}')
            # option list ($DC64+16s): 0-4 entries
            k = R.choice([0, 1, 2, 3, 4])
            ent = [(R.choice([1, 1, 2, 3]), R.choice(BIG + OTHER)) for _ in range(k)]
            ent = [(2 if sk in (0x80, 0x83) else tg, sk) for tg, sk in ent] + [(0, 0xFF)] * (8 - k)
            for j, (tg, sk) in enumerate(ent):
                args.append(f'--poke {rnd}:{0xDC64 + 16 * s + 2 * j:04X}={tg:#x}')
                args.append(f'--poke {rnd}:{0xDC65 + 16 * s + 2 * j:04X}={sk:#x}')
        args.append(f'--poke {rnd}:DB00={pick_bits(dens, 0x2C) & 0xF7:#x}')   # party side: bits 2/5 (no seal)
        args.append(f'--poke {rnd}:DB01={(0x08 if R.random() < 0.15 else 0) | pick_bits(dens, 0x24):#x}')
    lines.append(' '.join(args))
print('\n'.join(lines))
