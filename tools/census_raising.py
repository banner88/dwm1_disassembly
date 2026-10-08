#!/usr/bin/env python3
"""census_raising.py — the S130 raising model (simulator/raising.py) against
the game's own routines, value for value (MONSTER_DATA "Raising a monster
(S130)"; ROADMAP P3.15).

Boots a ROM to the title screen in PyBoy and stub-calls, with wRNG1/wRNG2
PINNED before every call so the model can replay the exact draws:

  create    `ld hl,$1402 / rst $10` (bank $14 entry 2) for every enemy row
            whose species is a monster, at arena tiers 0 and 3 -> the whole
            149-byte record's raising fields (species, level, max level, exp,
            the six stats + HP / MP, AI bytes, known skills, learn queue,
            resistances, WLD).
  level up  per level: `ld hl,$1302 / rst $10` (gains at the old level), then
            the bank $51 learn caller (a hand stub of its state loop around
            `ld hl,$0605 / rst $10`, the $FFD8-$FFDA protocol), the working
            list compacted + copied back (SetBtlS_580d / LoadBtlS_5b1c), then
            `ld hl,$510d / rst $10` (bank $51 entry 13 ApplyLevelUp). Monsters
            are levelled from their row level to their max level and two
            levels past it (the subtract path), at plus 0 and plus 99.
  breed     `ld hl,$1600 / rst $10` (bank $16 entry 0) with two created and
            levelled monsters staged in slots 20 / 21 ($D665 / $D6FA) -> the
            offspring, at plus 0 and with plus-gated resistance rolls.

Usage:
  census_raising.py [--rom ROM] [--project DIR] [--quick] [--out FILE]
  census_raising.py --selftest      (verifier check 5: the saved census is clean
                                     + a quick re-run on the original ROM)
Default ROM = data/DWM-original.gbc with the vanilla tables. --project reads
the tables from that project (pass its built ROM with --rom).
Writes extracted/raising_census.json (default) with the per-kind counts.
"""
import argparse
import json
import os
import random
import shutil
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
try:                                                          # S131: the selftest SKIPs
    from tools.pyboy_harness import boot, adv                 # noqa: E402  without PyBoy
except ImportError:                                           # (the module import used
    boot = adv = None                                         # to crash the verifier)
from simulator import raising as R                            # noqa: E402

STUB = 0xDD40
MARK = STUB - 1
RNG1, RNG2 = 0xC899, 0xC89A
SLOT0 = 0xCAC1
REC = 0x95
CAC0 = 0xCAC0
ARENA_TIER = 0xCAB4
C0D8 = 0xC0D8
STAGE20, STAGE21 = 0xD665, 0xD6FA
PLAYER_NAME = 0xCA42


TAIL_HOOK = {'armed': False, 'sp': None}


def arm_tail_hook(p, addr=0x5C23):
    """The past-the-max-level apply path ends in bank $51's battle-screen
    redraw (`jr_051_5c23`), which waits for a battle screen at the title: hook
    it, and jump to the park once the record is written."""
    def cb(ctx):
        if TAIL_HOOK['armed']:
            # leave bank $51 mid-call: drop its frames (SP as the stub had
            # it) and run the stub's marker write
            p.register_file.SP = TAIL_HOOK['sp']
            p.register_file.PC = STUB + 5
    p.hook_register(0x51, addr, cb, None)




def stub_rst(m, p, hl, park_off=4):
    """di / ld hl,nn / rst $10 / ld a,$A5 / ld [MARK],a / jr $ — run until the
    marker is written (a PC check can land inside an interrupt handler)."""
    code = [0xF3, 0x21, hl & 0xFF, hl >> 8, 0xD7, 0x3E, 0xA5, 0xEA, MARK & 0xFF, MARK >> 8,
            0x18, 0xFE]
    for i, b in enumerate(code):
        m[STUB + i] = b
    m[MARK] = 0
    TAIL_HOOK['sp'] = p.register_file.SP
    p.register_file.PC = STUB
    for _ in range(200):
        p.tick(1, False)
        if m[MARK] == 0xA5:
            return
    raise SystemExit(f"stub {hl:#06x} did not return (PC {p.register_file.PC:#06x} cac0 {m[0xCAC0]} lv {m[0xCB0C]} cap {m[0xCB0D]})")


# the bank $51 learn caller ($5763 state) as one loop: call the scanner until
# $FFD8 = $FF; c = $FF (plain / all-prereqs) or the replaced id ($FFDA) for an
# upgrade; the first $C0D8 byte == c takes the new id.
LEARN_LOOP = [
    0xF3,                    # di
    0x21, 0x05, 0x06,        # loop: ld hl,$0605
    0xD7,                    # rst $10
    0xF0, 0xD8,              # ldh a,[$d8]
    0xFE, 0xFF,              # cp $ff
    0x28, 0x1E,              # jr z,done
    0x0E, 0xFF,              # ld c,$ff
    0xF0, 0xD9,              # ldh a,[$d9]
    0xB7,                    # or a
    0x28, 0x07,              # jr z,scan
    0xFE, 0x02,              # cp 2
    0x28, 0x03,              # jr z,scan
    0xF0, 0xDA,              # ldh a,[$da]
    0x4F,                    # ld c,a
    0x21, 0xD8, 0xC0,        # scan: ld hl,$c0d8
    0x06, 0x28,              # ld b,$28
    0x7E,                    # s1: ld a,[hl]
    0xB9,                    # cp c
    0x20, 0x05,              # jr nz,s2
    0xF0, 0xD8,              # ldh a,[$d8]
    0x77,                    # ld [hl],a
    0x18, 0xDE,              # jr loop
    0x23,                    # s2: inc hl
    0x05,                    # dec b
    0x20, 0xF4,              # jr nz,s1
    0x18, 0xD8,              # jr loop
    0x3E, 0xA5,              # done: ld a,$A5
    0xEA, MARK & 0xFF, MARK >> 8,   # ld [MARK],a
    0x18, 0xFE,              # jr $
]


def _fix_jumps():
    """Resolve the relative jumps above from their labels (kept readable)."""
    c = list(LEARN_LOOP)
    loop, scan, s1, done = 1, 25, 30, 45
    pos = {'jz_done': 9, 'jz_scan1': 16, 'jz_scan2': 20, 'jr_loop1': 37, 'jnz_s2': 32,
           'jnz_s1': 41, 'jr_loop2': 43}
    s2 = 39
    def rel(at, to):
        return (to - (at + 2)) & 0xFF
    c[pos['jz_done'] + 1] = rel(pos['jz_done'], done)
    c[pos['jz_scan1'] + 1] = rel(pos['jz_scan1'], scan)
    c[pos['jz_scan2'] + 1] = rel(pos['jz_scan2'], scan)
    c[pos['jnz_s2'] + 1] = rel(pos['jnz_s2'], s2)
    c[pos['jr_loop1'] + 1] = rel(pos['jr_loop1'], loop)
    c[pos['jnz_s1'] + 1] = rel(pos['jnz_s1'], s1)
    c[pos['jr_loop2'] + 1] = rel(pos['jr_loop2'], loop)
    assert c[scan] == 0x21 and c[s1] == 0x7E and c[s2] == 0x23 and c[loop] == 0x21
    return c


LEARN_CODE = _fix_jumps()


def run_learn(m, p):
    for i, b in enumerate(LEARN_CODE):
        m[STUB + 0x20 + i] = b
    m[MARK] = 0
    p.register_file.PC = STUB + 0x20
    for _ in range(600):
        p.tick(1, False)
        if m[MARK] == 0xA5:
            return
    b = SLOT0 + m[CAC0] * REC
    raise SystemExit('learn loop did not return: species %d level %d skills %s queue %s work %s ffd8 %02x ffd9 %02x ffda %02x' % (
        m[b + 9], m[b + 0x4B], [hex(m[b + 0x29 + i]) for i in range(8)],
        [hex(m[b + 0x31 + i]) for i in range(25) if m[b + 0x31 + i] != 0xFF],
        [hex(m[C0D8 + i]) for i in range(12)], m[0xFFD8], m[0xFFD9], m[0xFFDA]))


def pin(m, state):
    m[RNG1] = state >> 8
    m[RNG2] = state & 0xFF


def w16(m, a):
    return m[a] | m[a + 1] << 8


def read_rec(m, slot):
    b = SLOT0 + slot * REC
    sk = [m[b + 0x29 + i] for i in range(8)]
    q = [m[b + 0x31 + i] for i in range(25)]
    return dict(species=m[b + 9], level=m[b + 0x4B], cap=m[b + 0x4C],
                exp=m[b + 0x4D] | m[b + 0x4E] << 8 | m[b + 0x4F] << 16,
                hp=w16(m, b + 0x50), maxhp=w16(m, b + 0x52), mp=w16(m, b + 0x54),
                maxmp=w16(m, b + 0x56),
                stats=[w16(m, b + 0x52), w16(m, b + 0x56), w16(m, b + 0x58),
                       w16(m, b + 0x5A), w16(m, b + 0x5C), w16(m, b + 0x5E)],
                wld=m[b + 0x60], plus=m[b + 0x62], ai=[m[b + 0x64 + i] for i in range(4)],
                res=[m[b + 0x68 + i] for i in range(27)],
                skills=[s for s in sk if s != 0xFF], queue=[x for x in q if x != 0xFF],
                female=m[b + 0x0B],
                raw=bytes(m[b:b + REC]))


def model_view(mon):
    return dict(species=mon.species, level=mon.level, cap=mon.cap, exp=mon.exp,
                stats=list(mon.stats), wld=mon.wld, plus=mon.plus, ai=list(mon.ai),
                res=list(mon.res), skills=list(mon.skills), queue=list(mon.queue),
                female=mon.female)


FIELDS = ('species', 'level', 'cap', 'exp', 'stats', 'wld', 'plus', 'ai', 'res', 'skills', 'queue', 'female')


def diff(game, model, fields=FIELDS):
    return {k: (game[k], model[k]) for k in fields if game[k] != model[k]}


def to_monster(T, g):
    mon = R.Monster(g['species'], g['level'], g['cap'], g['exp'], list(g['stats']),
                    list(g['skills']), list(g['queue']), list(g['res']), list(g['ai']),
                    plus=g['plus'], wld=g['wld'])
    return mon


def write_rec_fields(m, slot, mon):
    b = SLOT0 + slot * REC
    m[b + 0x4B] = mon.level
    m[b + 0x4C] = mon.cap
    m[b + 0x62] = mon.plus
    for i, v in enumerate(mon.stats):
        m[b + 0x52 + 2 * i if i < 2 else b + 0x58 + 2 * (i - 2)] = v & 0xFF
    # (only used for plus / level pokes; stats are written by the game)


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', default=os.path.join(REPO, 'data', 'DWM-original.gbc'))
    ap.add_argument('--project')
    ap.add_argument('--quick', action='store_true')
    ap.add_argument('--out', default=os.path.join(REPO, 'extracted', 'raising_census.json'))
    ap.add_argument('--seed', type=int, default=130)
    ap.add_argument('--eids', help='only these enemy rows (comma list; debugging)')
    a = ap.parse_args(argv)

    if a.project:
        from editor2.core.project import Project
        prj = Project.load(a.project)
        T = R.project_tables(prj)
    else:
        T = R.vanilla_tables()

    tmp = tempfile.mkdtemp()
    romcopy = os.path.join(tmp, 'census.gbc')
    shutil.copy(a.rom, romcopy)
    p = boot(romcopy)
    adv(p, 600)
    m = p.memory
    tail = 0x5C23
    if a.rom != os.path.join(REPO, 'data', 'DWM-original.gbc'):
        sy = os.path.join(os.path.dirname(a.rom), 'game.sym')
        for line in open(sy):
            if line.strip().endswith(' jr_051_5c23'):
                tail = int(line.split()[0].split(':')[1], 16)
    arm_tail_hook(p, tail)
    # a player name, so pedigree names compare as in a real game (FuncBrd_4313)
    for i, b in enumerate([0x2D, 0x28, 0x3B, 0x3B, 0x42, 0xF0, 0, 0, 0]):
        m[PLAYER_NAME + i] = b
    rnd = random.Random(a.seed)
    bad = {'create': [], 'level': [], 'breed': []}
    n = {'create': 0, 'level': 0, 'breed': 0, 'learned': 0, 'upgrades': 0,
         'subtract': 0, 'plus_rolls': 0, 'resist_rolls': 0, 'all_prereq': 0, 'breed2': 0, 'birth': 0, 'order_control': 0}

    def create_in(slot, eid, tier, state):
        for i in range(REC):
            m[SLOT0 + slot * REC + i] = 0
        m[0xDA12] = eid & 0xFF
        m[0xDA13] = eid >> 8
        m[0xDA14] = slot
        m[ARENA_TIER] = tier
        pin(m, state)
        stub_rst(m, p, 0x1402)
        return read_rec(m, slot)

    eids = [e for e in sorted(T.enemies) if e <= 486 and T.enemy(e)[0] <= 214]
    # rows that know a custom skill (the patched learn fork's custom ids) first
    eids = sorted(eids, key=lambda e: (not any(0xDE <= s < 0xFF for s in T.enemy(e)[21:25]), e))
    if a.quick:
        eids = eids[::9]
    if a.eids:
        eids = [int(x, 0) for x in a.eids.split(',')]
    # ---------------------------------------------------------------- create
    for eid in eids:
        for tier in (0, 3):
            st = rnd.getrandbits(16)
            g = create_in(0, eid, tier, st)
            mod = R.create(T, eid, R.GameRNG(st), arena_tier=tier)
            n['create'] += 1
            d = diff(g, model_view(mod))
            if d:
                bad['create'].append(dict(eid=eid, tier=tier, rng=st, diff=d))
    print(f"create: {n['create']} records, {len(bad['create'])} mismatches")

    # -------------------------------------------------------------- level up
    def level_once(slot, mon, state_g, state_l):
        """game: gains / learn / apply; model: the same with the same pins."""
        m[CAC0] = slot
        pin(m, state_g)
        stub_rst(m, p, 0x1302)
        for i in range(40):
            m[C0D8 + i] = 0xFF
        b = SLOT0 + slot * REC
        for i in range(8):
            m[C0D8 + i] = m[b + 0x29 + i]
        run_learn(m, p)
        work = [m[C0D8 + i] for i in range(40) if m[C0D8 + i] != 0xFF]
        over = len(work) > 8
        for i in range(8):
            m[b + 0x29 + i] = work[i] if i < len(work) else 0xFF
        TAIL_HOOK['armed'] = True
        stub_rst(m, p, 0x510D)
        TAIL_HOOK['armed'] = False
        # control: the same level-up with the learn scan AFTER the gains (the
        # wrong order) — counted, to show the census tells the orders apart
        alt = mon.copy()
        g2, s2 = R.gains(T, alt, R.GameRNG(state_g))
        R.apply_gains(alt, g2, s2)
        alt.level -= 1
        R.learn_scan(T, alt, 'casual')
        alt.level += 1
        # model
        before = set(mon.skills)
        g_, sub = R.gains(T, mon, R.GameRNG(state_g))
        codes = []
        learned = R.learn_scan(T, mon, 'casual', codes=codes)
        n['upgrades'] += codes.count(1)
        n['all_prereq'] += codes.count(2)
        R.apply_gains(mon, g_, sub)
        if alt.skills != mon.skills:
            n['order_control'] += 1
        return learned, sub, over, before

    custom_first = [e for e in eids if any(0xDE <= s < 0xFF for s in T.enemy(e)[21:25])]
    lvl_eids = custom_first + [e for e in (eids[::4] if not a.quick else eids[::3])
                               if e not in custom_first]
    for eid in lvl_eids:
        if os.environ.get('CENSUS_TRACE'):
            print('level eid', eid, flush=True)
        for plus in (0, 99):
            st = rnd.getrandbits(16)
            g = create_in(0, eid, 0, st)
            if plus:
                m[SLOT0 + 0x62] = plus
            mon = R.create(T, eid, R.GameRNG(st))
            mon.plus = plus
            top = min(R.LEVEL_MAX, mon.cap + 2)
            while mon.level < top and mon.level < R.LEVEL_MAX:
                sg = rnd.getrandbits(16)
                learned, sub, over, before = level_once(0, mon, sg, 0)
                gr = read_rec(m, 0)
                n['level'] += 1
                n['learned'] += len(learned)
                n['subtract'] += int(sub)
                n['plus_rolls'] += int(plus > 0 and mon.level > R.PLUS_FROM_LEVEL)
                d = diff(gr, model_view(mon), ('level', 'stats', 'skills', 'queue'))
                if d and not over:
                    bad['level'].append(dict(eid=eid, plus=plus, level=mon.level, rng=sg, diff=d))
                    break
                if over:
                    # the forget menu would ask the player: keep the game's 8
                    mon.skills = list(gr['skills'])
    print(f"level up: {n['level']} level-ups ({n['learned']} skills learned, "
          f"{n['subtract']} past the max level), {len(bad['level'])} mismatches; "
          f"learning on post-gain stats would differ at {n['order_control']}")

    # ----------------------------------------------------------------- breed
    from editor2.core import breeding as BR
    try:
        br = BR.Breeding(prj.gamedata()) if a.project else BR.Breeding(
            __import__('editor2.core.gamedata', fromlist=['Gamedata']).Gamedata({}, REPO))
    except Exception:
        br = None
    species_eids = {}
    for eid in eids:
        species_eids.setdefault(T.enemy(eid)[0], eid)
    sp_list = sorted(species_eids)
    pairs = []
    for _ in range(60 if a.quick else 400):
        pairs.append((rnd.choice(sp_list), rnd.choice(sp_list), rnd.choice((0, 0, 5, 30, 99))))
    for s1, s2, plus in pairs:
        recs = []
        for k, sp in enumerate((s1, s2)):
            st = rnd.getrandbits(16)
            create_in(k, species_eids[sp], 0, st)
            mon = R.create(T, species_eids[sp], R.GameRNG(st))
            lv = min(mon.cap, mon.level + rnd.randrange(0, 25))
            while mon.level < lv:
                sg = rnd.getrandbits(16)
                learned, sub, over, before = level_once(k, mon, sg, 0)
                if over:
                    mon.skills = read_rec(m, k)['skills']
            m[SLOT0 + k * REC + 0x62] = plus
            mon.plus = plus
            recs.append((bytes(m[SLOT0 + k * REC:SLOT0 + (k + 1) * REC]), mon))
        # stage: slot 20 = pedigree, slot 21 = mate; clear the roster
        for i in range(REC):
            m[STAGE20 + i] = recs[0][0][i]
            m[STAGE21 + i] = recs[1][0][i]
        for s in range(3):
            for i in range(REC):
                m[SLOT0 + s * REC + i] = 0
        st = rnd.getrandbits(16)
        pin(m, st)
        stub_rst(m, p, 0x1600)
        g = read_rec(m, 0)
        n['breed'] += 1
        # the resolver's species + plus come from the game (census_breeding
        # proves the resolver); the model makes the rest with the same pin
        mod = R.breed(T, recs[0][1], recs[1][1], g['species'], g['plus'], R.GameRNG(st))
        n['resist_rolls'] += int(g['plus'] > 0)
        d = diff(g, model_view(mod), ('level', 'cap', 'stats', 'ai', 'res', 'skills', 'queue', 'plus', 'female'))
        if br is not None:
            c = br.resolve(s1, s2, plus, plus, recs[0][1].level, recs[1][1].level)
            if (c.species, c.plus) != (g['species'], g['plus']):
                d['resolver'] = ((g['species'], g['plus']), (c.species, c.plus))
        if d:
            bad['breed'].append(dict(p1=s1, p2=s2, plus=plus, rng=st, diff=d))
            continue
        # birth: bank $16 entry 4 (BreedBirthFinalize — master := player,
        # WLD 0, egg flag off, learn queue rebuilt in the same order)
        m[CAC0] = 0
        m[0xCA40] = 0
        stub_rst(m, p, 0x1604)
        gb = read_rec(m, 0)
        n['birth'] += 1
        mod = R.birth(T, mod, recs[0][1], recs[1][1])
        db = diff(gb, model_view(mod), ('queue', 'wld', 'stats', 'skills'))
        if db or m[SLOT0 + 0x63] != 0:
            bad['breed'].append(dict(birth=True, p1=s1, p2=s2, diff=db, egg=m[SLOT0 + 0x63]))
            continue
        # generation 2: the offspring (levelled) x a fresh monster
        lv = rnd.randrange(5, 30)
        while mod.level < min(lv, mod.cap):
            sg = rnd.getrandbits(16)
            level_once(0, mod, sg, 0)
        s3 = rnd.choice(sp_list)
        st3 = rnd.getrandbits(16)
        create_in(1, species_eids[s3], 0, st3)
        mate = R.create(T, species_eids[s3], R.GameRNG(st3))
        mod.female = m[SLOT0 + 0x0B]
        for i in range(REC):
            m[STAGE20 + i] = m[SLOT0 + i]
            m[STAGE21 + i] = m[SLOT0 + REC + i]
        for s in range(3):
            for i in range(REC):
                m[SLOT0 + s * REC + i] = 0
        st = rnd.getrandbits(16)
        pin(m, st)
        stub_rst(m, p, 0x1600)
        g2 = read_rec(m, 0)
        n['breed2'] += 1
        mod2 = R.breed(T, mod, mate, g2['species'], g2['plus'], R.GameRNG(st))
        d2 = diff(g2, model_view(mod2), ('level', 'cap', 'stats', 'ai', 'res', 'skills', 'queue'))
        if d2:
            bad['breed'].append(dict(gen=2, p1=mod.species, p2=s3, rng=st, diff=d2))
    print(f"breed: {n['breed']} offspring + {n['breed2']} second generation, "
          f"{len(bad['breed'])} mismatches")

    out = dict(_generator='tools/census_raising.py <- ' + os.path.basename(a.rom) +
               (f' + project {a.project}' if a.project else ' (vanilla tables)'),
               counts=n, mismatches={k: len(v) for k, v in bad.items()},
               examples={k: v[:12] for k, v in bad.items()})
    if a.out:
        json.dump(out, open(a.out, 'w'), indent=1, default=str)
        f = open(a.out, 'a'); f.write('\n'); f.close()
    p.stop(save=False)
    shutil.rmtree(tmp, ignore_errors=True)
    return 0 if not any(bad.values()) else 1


def selftest():
    """Verifier check 5: the saved census says zero mismatches, and a quick
    re-run against the ORIGINAL ROM still matches (SKIP without PyBoy / ROM)."""
    out = os.path.join(REPO, 'extracted', 'raising_census.json')
    d = json.load(open(out))
    if any(d['mismatches'].values()):
        print('  raising_census.json records mismatches:', d['mismatches'])
        return 1
    rom = os.path.join(REPO, 'data', 'DWM-original.gbc')
    try:
        import pyboy                                           # noqa: F401
    except ImportError:
        print('  SKIP: PyBoy not installed (pip install pyboy) — saved census only')
        return 0
    if not os.path.exists(rom):
        print('  SKIP: no ROM — saved census only')
        return 0
    return main(['--quick', '--out', ''])


if __name__ == '__main__':
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    sys.exit(main(sys.argv[1:]))
