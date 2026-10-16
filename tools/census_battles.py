#!/usr/bin/env python3
"""census_battles.py — enemy rows and battle lists at campaign scale, measured in
the game (S149, ROADMAP ARC CAP5; PROJECT_COMPILER §2.57, MONSTER_DATA "Project
enemy rows").

Boots a built ROM to the title screen in PyBoy and stub-calls the game's own
routines (the S130 census_raising technique: wRNG1 / wRNG2 pinned, completion =
a marker byte):

  rows     `ld hl,$1401 / rst $10` (bank $14 entry 1 LoadEnemyStats -> $DA18)
           for EVERY project EID (bank $6B and every battle bank) and a sample of
           vanilla EIDs: the 25 bytes == the project's row (emitters.enemy_row_bytes)
           / the game data.
  create   `ld hl,$1402 / rst $10` (bank $14 entry 2, the monster constructor)
           for every project EID (or every k-th with --step) at two RNG pins:
           the record == simulator/raising.create (species, level, cap, exp,
           stats, WLD, AI, resistances, skills, queue, GENDER), the nickname
           empty, the master = the player, never an egg — and the vanilla
           special rows ($131 / $13C rival tamers, $15E the egg, $1E4 a
           nickname) keep their vanilla extras.
  lists    bank $76 `EncResolve.copy` (game.sym) with HL = every list number
           0-127 and every project list: a vanilla number returns D = itself
           and leaves wEncListBuf alone (bank $01 copies it); a project list
           returns D = $80 and wEncListBuf == its 26 bytes (bank $76 or a
           battle bank's BattleListCopy).

Usage:
  census_battles.py --make DIR [--rows N] [--lists M]   (a census project from
        editor2/example-project + N rows / M lists, built into DIR/build/build)
  census_battles.py --project DIR [--rom ROM] [--step K] [--negative] [--out F]
  census_battles.py --selftest   (verify check 5: the saved census is clean;
                                  offline — the plan's arithmetic; SKIP without
                                  PyBoy / ROM)
--negative pokes four bytes of the built ROM, one per class (the first battle
bank's RowBankTable byte, the first ListBankTable byte, EnemyGenderCode's
`cp $02` and ForeignNamesGate's `cp $02` -> `cp $FF` = the S148 behaviour): each
class must then FAIL. Writes extracted/battles_census.json.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
try:
    from tools.pyboy_harness import boot, adv                     # noqa: E402
except ImportError:
    boot = adv = None
from tools import census_raising as C                              # noqa: E402

OUT = os.path.join(REPO, 'extracted', 'battles_census.json')
DSTORE = C.MARK - 1
SPECIES = [s for s in range(0, 215)]            # monsters 0-214 (Iron Rule 8)
GENDER_CYCLE = ['rolled', 'male', 'female', None]
PLAYER = [0x2D, 0x28, 0x3B, 0x3B, 0x42, 0xF0, 0, 0, 0]


# --------------------------------------------------------------------------- make
def make_project(out_dir, rows, lists):
    """editor2/example-project + `rows` project enemies (species / level / stats /
    joinability / gender varied) + `lists` battle lists drawing from them."""
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)
    shutil.copytree(os.path.join(REPO, 'editor2', 'example-project'), out_dir,
                    ignore=shutil.ignore_patterns('build'))
    pj = os.path.join(out_dir, 'project.json')
    d = json.load(open(pj))
    ens = d.setdefault('progression', {}).setdefault('enemies', [])
    for i in range(rows):
        sp = SPECIES[(i * 37) % len(SPECIES)]
        lv = 1 + (i * 7) % 99
        e = {'id': f'census_{i}', 'eid': 'auto', 'species': sp, 'level': lv,
             'exp': (i * 113) % 60000, 'joinability': i % 8,
             'hp': 10 + (i * 31) % 900, 'mp': (i * 17) % 400, 'atk': 5 + (i * 13) % 500,
             'def': 5 + (i * 11) % 500, 'agl': 5 + (i * 19) % 500, 'int': 5 + (i * 23) % 500,
             'ai_weights': [(i * 3) % 256, (i * 5) % 256, (i * 7) % 256, (i * 9) % 256],
             'skills': [x for x in ((i % 150) + 1, (i * 3) % 150 + 1) if x != 0]}
        g = GENDER_CYCLE[i % len(GENDER_CYCLE)]
        if g:
            e['gender'] = g
        ens.append(e)
    n0 = len(ens)
    cl = d.setdefault('custom', {}).setdefault('encounter_lists', [])
    for k in range(lists):
        pick = [ens[(k * 3 + j * 101) % n0]['id'] for j in range(3)]
        cl.append({'id': f'census_list_{k}', 'name': f'Census list {k}',
                   'rate': k % 8, 'size_chance': [7, 0, 0],
                   'slot_chance': [3, 5, 2, 0, 0], 'eids': pick + [0, 0],
                   'max_count': [1, 1, 1, 1, 1], 'maze_size': 3 + k % 13})
    json.dump(d, open(pj, 'w'), indent=1)
    r = subprocess.run([sys.executable, os.path.join(REPO, 'tools', 'build_project.py'),
                        '--project', out_dir, '--build'], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(r.stdout[-3000:] + r.stderr[-3000:])
    return os.path.join(out_dir, 'build', 'build', 'rom.gbc')


# --------------------------------------------------------------------------- census
def sym_table(rom):
    out = {}
    for line in open(os.path.join(os.path.dirname(rom), 'game.sym')):
        m = re.match(r'([0-9a-f]+):([0-9a-f]+) (\S+)', line)
        if m:
            out[m.group(3)] = (int(m.group(1), 16), int(m.group(2), 16))
    return out


def stub(m, p, code):
    code = list(code) + [0x3E, 0xA5, 0xEA, C.MARK & 0xFF, C.MARK >> 8, 0x18, 0xFE]
    for i, b in enumerate(code):
        m[C.STUB + i] = b
    m[C.MARK] = 0
    C.TAIL_HOOK['sp'] = p.register_file.SP
    p.register_file.PC = C.STUB
    for _ in range(200):
        p.tick(1, False)
        if m[C.MARK] == 0xA5:
            return
    raise SystemExit(f"stub did not return (PC {p.register_file.PC:#06x})")


def negative_rom(rom, sy, prj, cls):
    """One one-byte poke of class `cls` (see the module doc) -> (rom, applied)."""
    from editor2.core import battles as BT
    data = bytearray(open(rom, 'rb').read())
    P = BT.plan(prj)
    off = lambda b, a: b * 0x4000 + (a - 0x4000)                     # noqa: E731
    if cls == 'rows':
        if not any(b['rows'][1] for b in P['banks']):
            return None
        b, a = sy['RowBankTable']
        data[off(b, a) + 2] += 1                    # first row bank's number + 1
    elif cls == 'lists':
        if not any(b['lists'][1] for b in P['banks']):
            return None
        b, a = sy['ListBankTable']
        data[off(b, a) + 2] += 1
    else:
        b, a = sy['EnemyGenderCode']
        assert data[off(b, a) + 2:off(b, a) + 4] == bytes([0xFE, 0x02])
        data[off(b, a) + 3] = 0xFF                   # cp $FF: the unbounded vanilla read
        b, a = sy['ForeignNamesGate']
        assert data[off(b, a):off(b, a) + 2] == bytes([0xFE, 0x02])
        data[off(b, a) + 1] = 0xFF                   # cp $FF: the low-byte name table
    tmp = tempfile.mkdtemp()
    out = os.path.join(tmp, 'negative.gbc')
    open(out, 'wb').write(data)
    shutil.copy(os.path.join(os.path.dirname(rom), 'game.sym'), tmp)
    return out


def census(project, rom, step=1, quiet=False):
    from editor2.core.project import Project
    from editor2.core import battles as BT, emitters as EM, encounters as EN
    from simulator import raising as R
    prj = Project.load(project)
    T = R.project_tables(prj)
    sy = sym_table(rom)
    m_enc = EN.resolve(prj)
    gd = prj.gamedata()
    tmp = tempfile.mkdtemp()
    rc = os.path.join(tmp, 'census.gbc')
    shutil.copy(rom, rc)
    p = boot(rc)
    adv(p, 600)
    m = p.memory
    tail = sy.get('jr_051_5c23', (0x51, 0x5C23))[1]
    C.arm_tail_hook(p, tail)
    for i, b in enumerate(PLAYER):
        m[C.PLAYER_NAME + i] = b
    res = {'rows': 0, 'rows_bad': [], 'create': 0, 'create_bad': [], 'lists': 0,
           'lists_bad': [], 'vanilla_special': [], 'genders': {}}
    rows = prj.quest_enemy_rows()
    by_eid = {e['_eid']: e for e in rows}
    # rows: LoadEnemyStats
    vanilla_sample = list(range(0, 487, 13)) + [486]
    for eid in vanilla_sample + [e['_eid'] for e in rows]:
        m[0xDA12], m[0xDA13] = eid & 0xFF, eid >> 8
        for i in range(25):
            m[0xDA18 + i] = 0xEE
        stub(m, p, [0xF3, 0x21, 0x01, 0x14, 0xD7])
        got = bytes(m[0xDA18 + i] for i in range(25))
        want = bytes(gd.enemy[eid]) if eid < 487 else bytes(EM.enemy_row_bytes(by_eid[eid]))
        res['rows'] += 1
        if got != want:
            res['rows_bad'].append({'eid': eid, 'bank': BT.row_bank_of(prj, eid) if eid >= 519 else 0x14,
                                    'got': got.hex(), 'want': want.hex()})
    # create: project rows
    for k, e in enumerate(rows):
        if k % step:
            continue
        eid = e['_eid']
        for st in (0x1357, 0xBEEF):
            for i in range(C.REC):
                m[C.SLOT0 + i] = 0
            m[0xDA12], m[0xDA13] = eid & 0xFF, eid >> 8
            m[0xDA14] = 0
            m[C.ARENA_TIER] = 0
            C.pin(m, st)
            stub(m, p, [0xF3, 0x21, 0x02, 0x14, 0xD7])
            g = C.read_rec(m, 0)
            mod = R.create(T, eid, R.GameRNG(st))
            d = C.diff(g, C.model_view(mod))
            raw = g['raw']
            extras = {}
            if any(raw[1:9]):
                extras['nickname'] = raw[1:9].hex()
            if list(raw[0x0C:0x15]) != PLAYER:
                extras['master'] = raw[0x0C:0x15].hex()
            if raw[0x63]:
                extras['egg'] = raw[0x63]
            res['create'] += 1
            gk = e.get('gender', 'rolled')
            res['genders'].setdefault(gk, {}).setdefault(str(g['female']), 0)
            res['genders'][gk][str(g['female'])] += 1
            if d or extras:
                res['create_bad'].append({'eid': eid, 'rng': st, 'diff': {k2: list(v) for k2, v in d.items()},
                                          'extras': extras})
    # create: the vanilla special rows keep their extras
    for eid, want in ((0x131, 'master'), (0x13C, 'master'), (0x15E, 'egg'), (0x1E4, 'nickname')):
        for i in range(C.REC):
            m[C.SLOT0 + i] = 0
        m[0xDA12], m[0xDA13] = eid & 0xFF, eid >> 8
        m[0xDA14] = 0
        C.pin(m, 0x1357)
        stub(m, p, [0xF3, 0x21, 0x02, 0x14, 0xD7])
        raw = C.read_rec(m, 0)['raw']
        ok = {'master': list(raw[0x0C:0x15]) != PLAYER, 'egg': raw[0x63] == 1,
              'nickname': any(raw[1:9])}[want]
        res['vanilla_special'].append({'eid': eid, 'kind': want, 'ok': ok})
    # lists: EncResolve.copy
    cb, ca = sy['EncResolve.copy']
    buf = sy['wEncListBuf'][1]
    numbers = list(range(0, 128)) + [m_enc.lists[i]['number'] for i in range(len(m_enc.lists))]
    for n in numbers:
        for i in range(26):
            m[buf + i] = 0xEE
        code = [0xF3, 0x3E, cb, 0xEA, 0x00, 0x21,          # di / ld a,$76 / ld [$2100],a
                0x21, n & 0xFF, n >> 8,                    # ld hl, n
                0x1E, 0x00, 0x06, 0xFF,                    # ld e,0 / ld b,$FF
                0xCD, ca & 0xFF, ca >> 8,                  # call EncResolve.copy
                0x7A, 0xEA, DSTORE & 0xFF, DSTORE >> 8]    # ld a,d / ld [DSTORE],a
        stub(m, p, code)
        d_reg = m[DSTORE]
        got = bytes(m[buf + i] for i in range(26))
        res['lists'] += 1
        if n < 128:
            ok = d_reg == n and got == bytes([0xEE] * 26)
            want = None
        else:
            want = bytes(m_enc.list_bytes(n))
            ok = d_reg == 0x80 and got == want
        if not ok:
            res['lists_bad'].append({'list': n, 'd': d_reg, 'got': got.hex(),
                                     'want': want.hex() if want else 'untouched',
                                     'bank': BT.list_bank_of(prj, n) if n >= 128 else 1})
    p.stop(save=False)
    P = BT.plan(prj)
    res['plan'] = {'rows': P['rows'], 'rows_here': P['rows_here'], 'lists': P['lists'],
                   'lists_here': P['lists_here'],
                   'banks': [{'bank': f"${b['bank']:02X}", 'rows': list(b['rows']),
                              'lists': list(b['lists'])} for b in P['banks']]}
    return res


def summary(res):
    return (f"rows {res['rows'] - len(res['rows_bad'])}/{res['rows']} · create "
            f"{res['create'] - len(res['create_bad'])}/{res['create']} · lists "
            f"{res['lists'] - len(res['lists_bad'])}/{res['lists']} · vanilla extras "
            f"{sum(1 for v in res['vanilla_special'] if v['ok'])}/{len(res['vanilla_special'])}")


def failed(res):
    return bool(res['rows_bad'] or res['create_bad'] or res['lists_bad']
                or not all(v['ok'] for v in res['vanilla_special']))


def selftest():
    from editor2.core import battles as BT
    # offline: the plan's arithmetic
    class Fake:
        def __init__(self, n, m):
            self._rows = [{'_eid': 519 + i, 'id': f'r{i}'} for i in range(n)]
            self.custom = {'encounter_lists': [{}] * m}
            self._ext_taken = []

        def quest_enemy_rows(self):
            return self._rows

        def _take_ext_bank(self, purpose):
            b = 0x80 + len(self._ext_taken)
            self._ext_taken.append((b, purpose))
            return b
    import editor2.core.music as MU
    import editor2.core.tileanim as TA
    real = (MU.song_ext_banks, TA.plan)
    MU.song_ext_banks, TA.plan = (lambda prj: {}), (lambda prj: {})
    try:
        for n, m_ in ((0, 0), (1, 0), (640, 128), (641, 300), (3321, 3968)):
            f = Fake(n, m_)
            P = BT.plan(f)
            covered = P['rows_here'] + sum(b['rows'][1] for b in P['banks'])
            lc = P['lists_here'] + sum(b['lists'][1] for b in P['banks'])
            assert covered == n and lc == m_, (n, m_, P)
            assert P['bytes_6b'] <= 0x4000
            for b in P['banks']:
                used = BT.BATTLE_TEMPLATE_SIZE + 25 * b['rows'][1] + 26 * b['lists'][1]
                assert used <= 0x4000, b
    finally:
        MU.song_ext_banks, TA.plan = real
    print("census_battles selftest: plan arithmetic OK")
    if not os.path.exists(OUT):
        print("  (no saved census — SKIP)")
        return 0
    d = json.load(open(OUT))
    for k in ('census', 'user'):
        if k in d and failed(d[k]):
            print(f"  FAIL: the saved {k} census has mismatches")
            return 1
    if 'negative' in d and not all(d['negative'].get('failed_classes', {}).values()):
        print("  FAIL: the saved negative control did not fail every class")
        return 1
    print("  saved census clean")
    return 0


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--make')
    ap.add_argument('--rows', type=int, default=1500)
    ap.add_argument('--lists', type=int, default=600)
    ap.add_argument('--project')
    ap.add_argument('--rom')
    ap.add_argument('--step', type=int, default=1)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--key', default='census')
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args(argv)
    if a.selftest:
        return selftest()
    if a.make:
        rom = make_project(a.make, a.rows, a.lists)
        print('built', rom)
        return 0
    rom = a.rom or os.path.join(a.project, 'build', 'build', 'rom.gbc')
    from editor2.core.project import Project
    prj = Project.load(a.project)
    saved = json.load(open(a.out)) if os.path.exists(a.out) else {}
    saved['_generator'] = ('tools/census_battles.py (S149) — PyBoy stub calls on a built '
                           'ROM of the project; ROM source data/DWM-original.gbc')
    if a.negative:
        sy = sym_table(rom)
        fc, notes = {}, {}
        for cls in ('rows', 'lists', 'create'):
            nrom = negative_rom(rom, sy, prj, cls)
            if nrom is None:
                continue
            try:
                res = census(a.project, nrom, a.step)
                fc[cls] = bool(res[f"{'create' if cls == 'create' else cls}_bad"])
                notes[cls] = summary(res)
            except SystemExit as e:            # the far call ran into another bank
                fc[cls] = True
                notes[cls] = f"hung: {e}"
            print('NEGATIVE', cls, '->', notes[cls])
        print('failed classes:', fc)
        saved['negative'] = {'failed_classes': fc, 'notes': notes,
                             'project': os.path.basename(a.project.rstrip('/'))}
        json.dump(saved, open(a.out, 'w'), indent=1)
        return 0 if fc and all(fc.values()) else 1
    res = census(a.project, rom, a.step)
    print(summary(res))
    print('genders by setting:', res['genders'])
    for k in ('rows_bad', 'create_bad', 'lists_bad'):
        for x in res[k][:5]:
            print(' ', k, x)
    saved[a.key] = {'summary': summary(res), 'plan': res['plan'], 'genders': res['genders'],
                    'vanilla_special': res['vanilla_special'],
                    'rows_bad': res['rows_bad'][:20], 'create_bad': res['create_bad'][:20],
                    'lists_bad': res['lists_bad'][:20],
                    'project': os.path.basename(a.project.rstrip('/'))}
    json.dump(saved, open(a.out, 'w'), indent=1)
    return 1 if failed(res) else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
