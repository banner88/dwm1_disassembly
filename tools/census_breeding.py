#!/usr/bin/env python3
"""census_breeding.py — the game's breeding resolver vs editor2/core/breeding.py
(ROADMAP P3.12, S113; BREEDING_SYSTEM "The resolver as measured (S113)").

Builds a project (or takes --rom), boots it in PyBoy to the title screen and
stub-calls bank $16 entry 2 (BreedResolveOffspring, `ld hl,$1602 / rst $10`,
the scripts' own far call) for:

  * every ordered pair of breedable parents (0-214 + the project's new
    species), plus 0, level 1 — the offspring species and plus;
  * a plus / level sweep: every pair a plus-gated special row can fire for,
    at parents' plus 0-99, and a seeded random sample of
    (parents, plus 1, plus 2, level 1, level 2);

and compares $DA71 (species) / $DA77 (plus) with `Breeding.resolve`. The
parents' plus / level are read from roster slots 0 / 1 ($DA75 / $DA76 = 0 / 1).

Then the EGG ITSELF (S113 — this is what found the FX1 staging-index bug): it
stub-calls bank $16 entry 0 BreedCreateOffspring (`ld hl,$1600 / rst $10`)
with the two parents in the real staging records ($D665 / $D6FA: species,
plus, level) and reads the monster it created (roster slot 0 at the title
screen: species +$09, plus +$62) — `--create N` cases (default 400: every
plus-gated row's parents at plus 3-6 and levels 1-60, then random).
Hooks: BreedRareMutation_Unreferenced ($16:$44DA) must never execute and the
rare-breed flag $D9E6 must stay 0; BreedClearRareFlag is hooked for the first
calls to show the resolver's Step 3 runs.

  python3 tools/census_breeding.py --project editor2/example-project
  python3 tools/census_breeding.py --project P --rom P/build/rom.gbc --out x.json
  python3 tools/census_breeding.py --project P --negative   # twin without the family second pass: must report mismatches

Writes extracted/breeding_census.json (or --out) and exits 1 on any mismatch.
"""
import argparse
import copy
import hashlib
import io
import json
import os
import random
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
OUT = os.path.join(REPO, 'extracted', 'breeding_census.json')
STUB = 0xDD40                         # battle WRAM: unused at the title screen (S113: $D700 sits inside staging record 2)
SLOT = 0x95
PLUS_F, LEVEL_F = 0xCB23, 0xCB0C      # roster +$62 plus, +$4B level (slot 0)
DA6F, DA70, DA71, DA75, DA76, DA77 = 0xDA6F, 0xDA70, 0xDA71, 0xDA75, 0xDA76, 0xDA77
RARE_FLAG = 0xD9E6


def sym(path):
    out = {}
    for line in open(path):
        parts = line.split()
        if len(parts) == 2 and ':' in parts[0]:
            b, a = parts[0].split(':')
            out[parts[1]] = (int(b, 16), int(a, 16))
    return out


def build(project, outdir):
    subprocess.run([sys.executable, os.path.join(REPO, 'tools', 'build_project.py'),
                    '--project', project, '--build', '--out', outdir],
                   check=True, stdout=subprocess.DEVNULL)
    return os.path.join(outdir, 'build', 'rom.gbc'), os.path.join(outdir, 'build', 'game.sym')


def twin_for(project):
    from editor2.core.project import Project
    from editor2.core.breeding import Breeding
    data = json.load(open(os.path.join(project, 'project.json')))
    pr = Project(data, project)
    g = pr.gamedata()
    return Breeding(g), sorted(pr.new_species_ids()), g


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--project', required=True)
    ap.add_argument('--rom')
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--sample', type=int, default=6000)
    ap.add_argument('--label', help='what the project is (for _generator; default its path)')
    ap.add_argument('--create', type=int, default=400,
                    help='egg-creation cases through BreedCreateOffspring (0 = skip)')
    ap.add_argument('--expect-egg-bug', action='store_true',
                    help='a build from before the S113 staging-index fix: the egg '
                         'mismatches must appear (the resolver itself still matches)')
    ap.add_argument('--negative', action='store_true',
                    help='perturb the twin (family table: no second pass) — '
                         'the census must then report mismatches')
    a = ap.parse_args()
    project = os.path.abspath(a.project)
    if a.rom:
        rom, symp = a.rom, os.path.join(os.path.dirname(a.rom), 'game.sym')
    else:
        rom, symp = build(project, os.path.join('/tmp', 'census_breeding_build'))
    S = sym(symp)
    twin, new_ids, g = twin_for(project)
    if a.negative:
        # the family table WITHOUT its second pass (mate as a family code)
        twin.family_hit = lambda p1, p2: twin._family_pass(p1, twin.fam_code(p1), p2)

    from tools.pyboy_harness import adv, boot
    import shutil
    romcopy = '/tmp/census_breeding_rom.gbc'
    shutil.copy(rom, romcopy)
    if os.path.exists(romcopy + '.ram'):
        os.remove(romcopy + '.ram')
    p = boot(romcopy)
    adv(p, 600)
    m = p.memory
    hits = {'mutation': 0, 'clear_flag': 0}

    def on_mut(_):
        hits['mutation'] += 1

    def on_clear(_):
        hits['clear_flag'] += 1
    mb, ma = S['BreedRareMutation_Unreferenced']
    p.hook_register(mb, ma, on_mut, None)
    cb, ca = S['BreedClearRareFlag']
    p.hook_register(cb, ca, on_clear, None)
    clear_hooked = True

    code = [0xF3, 0x21, 0x02, 0x16, 0xD7, 0x18, 0xFE]   # di / ld hl,$1602 / rst $10 / jr $
    for i, b in enumerate(code):
        m[STUB + i] = b
    park = STUB + 5
    calls = [0]

    def call(p1, p2, plus1, plus2, lvl1, lvl2):
        m[DA6F], m[DA70] = p1, p2
        m[DA75], m[DA76] = 0, 1
        m[PLUS_F], m[PLUS_F + SLOT] = plus1, plus2
        m[LEVEL_F], m[LEVEL_F + SLOT] = lvl1, lvl2
        m[RARE_FLAG] = 0
        p.register_file.PC = STUB
        for _ in range(12):
            p.tick(1, False)
            if p.register_file.PC == park:
                break
        else:
            raise SystemExit(f'resolver did not return for {p1} x {p2}')
        calls[0] += 1
        return m[DA71], m[DA77], m[RARE_FLAG]

    parents = list(range(215)) + list(new_ids)
    cases = []
    for p1 in parents:
        for p2 in parents:
            cases.append((p1, p2, 0, 0, 1, 1))
    gated = [e for e in twin.special if e[2] > 0]
    fam_members = {}
    for sp in parents:
        fam_members.setdefault(twin.fam_code(sp), []).append(sp)
    rng = random.Random(113)
    for e in gated:
        ps1 = fam_members.get(e[0], []) if e[0] >= 0xF0 else [e[0]]
        ps2 = fam_members.get(e[1], []) if e[1] >= 0xF0 else [e[1]]
        for p1 in ps1[:6]:
            for p2 in ps2[:6]:
                for plus in range(0, 100, 1):
                    cases.append((p1, p2, plus, rng.randrange(0, plus + 1), 1, 1))
    for _ in range(a.sample):
        cases.append((rng.choice(parents), rng.choice(parents), rng.randrange(100),
                      rng.randrange(100), rng.randrange(1, 100), rng.randrange(1, 100)))

    bad, how = [], {'special': 0, 'family': 0, 'parent': 0}
    flag_set = 0
    for k, c in enumerate(cases):
        if clear_hooked and k == 300:
            p.hook_deregister(cb, ca)          # the per-hit cost: keep it short
            clear_hooked = False
        sp, plus, flag = call(*c)
        want = twin.resolve(*c)
        how[want.how] += 1
        if flag:
            flag_set += 1
        if (sp, plus) != (want.species, want.plus):
            bad.append({'case': list(c), 'game': [sp, plus],
                        'twin': [want.species, want.plus, want.how, want.index]})
    # ---- the egg itself: BreedCreateOffspring with the real staging records
    STAGE1, STAGE2 = 0xD665, 0xD6FA
    ccode = [0xF3, 0x21, 0x00, 0x16, 0xD7, 0x18, 0xFE]   # di / ld hl,$1600 / rst $10 / jr $
    ccases = []
    for e in gated:
        ps1 = fam_members.get(e[0], []) if e[0] >= 0xF0 else [e[0]]
        ps2 = fam_members.get(e[1], []) if e[1] >= 0xF0 else [e[1]]
        for p1 in ps1[:2]:
            for p2 in ps2[:2]:
                for plus in (2, 3, 4, 5):
                    for lv in (10, 30, 50):
                        ccases.append((p1, p2, plus, 0, lv, lv))
    while len(ccases) < a.create:
        ccases.append((rng.choice(parents), rng.choice(parents), rng.randrange(100),
                       rng.randrange(100), rng.randrange(1, 100), rng.randrange(1, 100)))
    ccases = ccases[:a.create]
    cbad = []
    for c in ccases:
        p1, p2, pl1, pl2, lv1, lv2 = c
        for base, sp_, pl, lv in ((STAGE1, p1, pl1, lv1), (STAGE2, p2, pl2, lv2)):
            m[base + 0x09] = sp_
            m[base + 0x62] = pl
            m[base + 0x4B] = lv
        m[0xCAC1] = 0                                   # roster slot 0 empty
        for i, b in enumerate(ccode):
            m[STUB + i] = b
        p.register_file.PC = STUB
        for _ in range(60):
            p.tick(1, False)
            if p.register_file.PC == park:
                break
        else:
            raise SystemExit(f'BreedCreateOffspring did not return for {c}')
        slot = m[0xCAC0]
        got = (m[0xCAC1 + 0x09], m[0xCAC1 + 0x62]) if slot == 0 else (None, None)
        want = twin.resolve(*c)
        if got != (want.species, min(want.plus, 99)):
            cbad.append({'case': list(c), 'slot': slot, 'egg': list(got),
                         'twin': [want.species, want.plus, want.how, want.index]})
        m[0xCAC1] = 0
    p.stop()
    md5 = hashlib.md5(open(rom, 'rb').read()).hexdigest()
    res = {
        '_generator': ('tools/census_breeding.py (S113): PyBoy stub-calls of bank $16 '
                       'entry 2 BreedResolveOffspring vs editor2/core/breeding.py on '
                       f'the build of {a.label or os.path.relpath(project, REPO)}'),
        'rom_md5': md5,
        'negative_control': a.negative,
        'calls': calls[0],
        'cases': {'pairs_plus0': len(parents) ** 2, 'plus_gated_sweep':
                  len(cases) - len(parents) ** 2 - a.sample, 'random': a.sample},
        'parents': f'0-214 + new species {new_ids}',
        'twin_paths': how,
        'mismatches': len(bad),
        'first_mismatches': bad[:40],
        'mutation_routine_hits': hits['mutation'],
        'clear_flag_hits_first_300_calls': hits['clear_flag'],
        'rare_flag_set_after_call': flag_set,
        'special_rows': len(twin.special),
        'egg_cases': len(ccases),
        'egg_mismatches': len(cbad),
        'first_egg_mismatches': cbad[:20],
    }
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    json.dump(res, open(a.out, 'w'), indent=1)
    print(json.dumps({k: v for k, v in res.items()
                      if k not in ('first_mismatches', 'first_egg_mismatches')}, indent=1))
    if cbad:
        print('first egg mismatches:', json.dumps(cbad[:3]))
    ok = not bad and not cbad and hits['mutation'] == 0 and flag_set == 0
    if a.negative:
        print('NEGATIVE CONTROL:', 'detected (good)' if bad else 'NOT detected (bad)')
        return 0 if bad else 1
    if a.expect_egg_bug:
        print('PRE-FIX BUILD:', 'egg plus wrong as expected' if cbad else 'NOT reproduced')
        return 0 if cbad and not bad else 1
    print('CENSUS:', 'PASS' if ok else 'FAIL')
    return 0 if ok else 1


if __name__ == '__main__':
    raise SystemExit(main())
