#!/usr/bin/env python3
"""walk_holds.py — S162 (ROADMAP E17 note "Project enemy rows") on the real game (PyBoy on the
user's .sav).

The original game's enemy duplicate-group-cast conversion (bank $53
EnemyDupCastConversion_4e63, §15.8b) turns an enemy's group spell / breath into a plain Attack
when another enemy acted before it in the round — only for rows whose byte in
EnemyDupConvFlagTable_41df (486 bytes, EIDs 0-485) is set, and never for the top INT mode
($DD0B = 2). Its read was unbounded: a project row (EID 519+) read code past the table. Since
S162 bank $53 DupConvFlag53 reads EIDs 0-486 exactly as the original and asks bank $6B entry 2
EnemyHoldsOf for every higher EID (a project row's ProjectEnemyHolds byte, else 0).

The demo (examples/s162_volley_demo/build_demo.py) = the user's project + THE VOLLEY HALL:
the HOLDING / CASTING imps (rows 3 / 4, bank $6B) and the FAR holder / caster (rows 694 /
695, a battle bank $80+), all Bang-only at INT 100.

  table    the ROM's ProjectEnemyHolds == the project's holds_group_spells, row for row;
           every row's bank (bank $6B or the battle bank) as battles.plan says;
  stub     DupConvFlag53 stub-called with HL = EID: EIDs 0-486 = the original table's byte
           (486 = $FE, the next code byte, as the original read it); 487-518 = 0; every project
           row = its own flag; the first EID past the last row, 3839 and $0F00 = 0; BC / DE
           kept; the Balance simulator's flag list (balance.BattleData.dup) agrees;
  live     forced battles (the S110 rig, two enemies of one row, the party defending, the RNG
           free — seeded once): the HOLDING pair converts (the conversion path runs), the
           CASTING pair never does and casts more Bangs; the FAR pair the same from the battle
           bank (the user's CATFLY, EID 521, is in the stub check: 0 now, $03 before S162 — it
           never chose its group skill in a live battle); the original rows unchanged:
           EID 44 (Eyeder, flagged) converts, EID 309 (Rayburn, not flagged) never does;
  talk     the game's own path: the HOLDING PAIR NPC's conversation battle (two rows from a
           battle step) — the conversion runs with the row's EID, the battle ends, the field is
           back.

  python3 tools/walk_holds.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative] [--steps …]

--negative: the S162 read removed in the ROM copy (`call DupConvFlag53` + 6 nops back to the
original 9 bytes `ld a, l / add LOW(table) / ld l, a / ld a, h / adc HIGH(table) / ld h, a /
ld a, [hl]`): the project rows read the code past the table again — the CASTING / FAR CASTER
checks (their EIDs read non-zero code bytes: they convert like the holders, 21 / 21 measured
S162) and the talk check (DupConvFlag53 never runs) must FAIL; the stub check calls the routine
directly and still passes.
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.walk_regions import s_continue                                    # noqa: E402
from tools.walk_mirror import MirrorWalk, rom_off, SEEDS                     # noqa: E402

STUB, MARK, RES = 0xDE40, 0xDE3F, 0xDE3C          # RES: A, B, C, D, E after the call
BANG = 6
ORIG_READ = bytes([0x7D, 0xC6, 0xDF, 0x6F, 0x7C, 0xCE, 0x41, 0x67, 0x7E])


def flag_call(w, eid, maxf=200):
    """DupConvFlag53 stub-called: HL = eid, BC = $1234, DE = $5678 -> (A, BC, DE) or None."""
    m, p = w.m, w.p
    b, a = w.sym['DupConvFlag53']
    code = [0xF3, 0x3E, b, 0xEA, 0x00, 0x21,              # di / ld a, bank / ld [$2100], a
            0x01, 0x34, 0x12, 0x11, 0x78, 0x56,           # ld bc, $1234 / ld de, $5678
            0x21, eid & 0xFF, eid >> 8,                   # ld hl, eid
            0xCD, a & 0xFF, a >> 8,                       # call DupConvFlag53
            0xEA, RES & 0xFF, RES >> 8,                   # ld [RES], a
            0x78, 0xEA, (RES + 1) & 0xFF, (RES + 1) >> 8,  # ld a, b / ld [RES+1], a
            0x79, 0xEA, (RES + 2) & 0xFF, (RES + 2) >> 8,
            0x7A, 0xEA, (RES - 1) & 0xFF, (RES - 1) >> 8,  # d -> RES-1
            0x7B, 0xEA, (RES - 2) & 0xFF, (RES - 2) >> 8,  # e -> RES-2
            0x3E, 0xA5, 0xEA, MARK & 0xFF, MARK >> 8, 0x18, 0xFE]
    for i, x in enumerate(code):
        m[STUB + i] = x
    m[MARK] = 0
    p.register_file.PC = STUB
    for _ in range(maxf):
        p.tick(1, False)
        if m[MARK] == 0xA5:
            return m[RES], m[RES + 1] << 8 | m[RES + 2], m[RES - 1] << 8 | m[RES - 2]
    return None


def conversions(w, eid, seeds=SEEDS, frames=6000):
    """Forced battles vs two enemies of row `eid`, RNG free (seeded once a battle): ->
    (conversions, group-spell acts, all enemy acts, the enemies' $DD0B)."""
    cb, ca = w.sym['jr_053_4ea7']
    n = [0]
    acts, dd0b = [], set()

    def rec_mode(m):
        dd0b.add((m[0xDD0B + 4], m[0xDD0B + 5]))
    for seed in seeds:
        w.start('start')
        r = w.spar(eid, seed=seed, ecount=2, reseed=False, frames=frames, board=rec_mode,
                   hooks=[(cb, ca + 5, lambda m: n.__setitem__(0, n[0] + 1))])
        acts += [sk for a, sk in r['acts'] if a >= 4]
    grp = sum(1 for sk in acts if sk in w.group)
    return n[0], grp, len(acts), sorted(dd0b)


# ------------------------------------------------------------------ steps
def s_table(w):
    print('table: ProjectEnemyHolds == the project, row for row')
    rom = open(w.rom, 'rb').read()
    o = rom_off(w.sym, 'ProjectEnemyHolds')
    rows = w.prj.quest_enemy_rows()
    got = list(rom[o:o + len(rows)])
    want = [1 if e.get('holds_group_spells') else 0 for e in rows]
    bad = [(e['_eid'], g, x) for e, g, x in zip(rows, got, want) if g != x]
    w.check(f'ProjectEnemyHolds: {len(rows)} rows == holds_group_spells '
            f'({sum(want)} hold back)', not bad, str(bad[:6]))
    from editor2.core import battles as BT
    P = BT.plan(w.prj)
    far = [w.eids[k] for k in ('far_holder', 'far_caster')]
    banks = {e: BT.row_bank_of(w.prj, e) for e in far + [w.eids['holding_imp']]}
    w.check(f'the HOLDING imp in bank $6B, the FAR rows in a battle bank (rows here '
            f'{P["rows_here"]}): {", ".join(f"EID {e} ${b:02X}" for e, b in banks.items())}',
            banks[w.eids['holding_imp']] == 0x6B and all(banks[e] >= 0x80 for e in far))


def s_stub(w):
    print('stub: DupConvFlag53 for every kind of EID')
    rom = open(w.rom, 'rb').read()
    t = rom_off(w.sym, 'EnemyDupConvFlagTable_41df')
    w.start('start')
    w.spar(w.eids['holding_imp'], frames=600, reseed=False)
    import io
    st = io.BytesIO()
    w.p.save_state(st)
    rows = w.prj.quest_enemy_rows()
    last = rows[-1]['_eid']
    want = {}
    for e in range(0, 487):
        want[e] = rom[t + e]
    for e in range(487, 519):
        want[e] = 0
    for r in rows:
        if r['_eid'] in (rows[0]['_eid'], rows[1]['_eid'], rows[2]['_eid'], last) or \
                r['id'] in w.eids or r['_eid'] % 37 == 0:
            want[r['_eid']] = 1 if r.get('holds_group_spells') else 0
    for e in (last + 1, 3839, 0x0F00, 0xFFFF):
        want[e] = 0
    bad, regs = [], []
    for e, x in sorted(want.items()):
        st.seek(0)
        w.p.load_state(st)
        got = flag_call(w, e)
        if got is None or got[0] != x:
            bad.append((e, got and got[0], x))
        elif got[1:] != (0x1234, 0x5678):
            regs.append((e, got))
    vb = [b for b in bad if b[0] <= 486]
    pb = [b for b in bad if b[0] > 486]
    w.check(f'EIDs 0-486: the original table byte (EID 486 = ${rom[t + 486]:02X}, the next code '
            f'byte, as the original read it)', not vb, str(vb[:6]))
    w.check(f'EIDs 487-518 = 0, {sum(1 for e in want if 519 <= e <= last)} project rows = their '
            f'own flag (holding ${want[w.eids["holding_imp"]]:02X}, casting '
            f'${want[w.eids["casting_imp"]]:02X}, far ${want[w.eids["far_holder"]]:02X} / '
            f'${want[w.eids["far_caster"]]:02X}), past the last row / 3839 / $0F00 / $FFFF = 0',
            not pb, str(pb[:6]))
    w.check('BC and DE kept across the call (the far path saves them around RST_10)',
            not regs, str(regs[:4]))
    old = [(e, rom[t + e]) for e in (w.eids['casting_imp'], w.eids['far_caster'],
                                     w.eids['catfly'])]
    print(f'   (the original read for those EIDs would give {old} — code bytes past the table)')
    dup = w.data.dup
    sim_bad = [(e, dup[e] if e < len(dup) else 0, x) for e, x in want.items()
               if e < 0xF00 and (1 if (dup[e] if e < len(dup) else 0) else 0) != (1 if x else 0)]
    w.check('the Balance simulator\'s flags (balance.BattleData.dup) == the ROM\'s for those EIDs',
            not sim_bad, str(sim_bad[:6]))


def s_live(w):
    print('live: forced battles, two enemies of one row (RNG free)')
    res = {}
    for k in ('holding_imp', 'casting_imp', 'far_holder', 'far_caster'):
        res[k] = conversions(w, w.eids[k])
    for k in ('orig_44', 'orig_309'):
        res[k] = conversions(w, int(k[5:]))
    for k, v in res.items():
        print(f'   {k}: conversions {v[0]}, group-spell acts {v[1]} of {v[2]}, $DD0B {v[3]}')
    h, c = res['holding_imp'], res['casting_imp']
    w.check(f'the HOLDING pair converts (a second Bang becomes Attack): {h[0]} conversions',
            h[0] > 0 and all(x == (1, 1) for x in h[3]), str(h))
    w.check(f'the CASTING pair never converts and casts more Bangs: {c[0]} conversions, '
            f'{c[1]} / {h[1]} Bangs', c[0] == 0 and c[1] > h[1], str(c))
    fh, fc = res['far_holder'], res['far_caster']
    w.check(f'the FAR pair (a battle bank) converts: {fh[0]}; the FAR CASTERS never: {fc[0]}',
            fh[0] > 0 and fc[0] == 0 and fc[1] > fh[1], f'{fh} {fc}')
    o1, o0 = res['orig_44'], res['orig_309']
    w.check(f'the original rows as before: EID 44 (flagged) converts {o1[0]}, EID 309 (not '
            f'flagged) {o0[0]}', o1[0] > 0 and o0[0] == 0, f'{o1} {o0}')


def watch(w, frames):
    """A few rounds of the battle the game started: the party DEFENDING ($8D in its queue
    cells, as the user is told to do), the enemies' HP held at 900 and the party's at 900 —
    the user's party otherwise one-shots an imp (measured) — A pressed to advance the text."""
    from tools.walk_mirror import DCEC, DEFEND, HP, MAXHP
    from tools.walk_skills import w16
    m, p = w.m, w.p
    for i in range(frames):
        if m[0xD9EC] >= 1:
            for j in range(3):
                m[DCEC + 2 * j] = DEFEND
            if 4 <= m[0xD9EC] <= 6:
                for j in range(3):
                    m[DCEC + 2 * j + 1] = j
                    if m[0xDD1B + j] != 0xFF:
                        w16(m, HP + 2 * j, 900)
                        w16(m, MAXHP + 2 * j, 999)
                for j in range(2):
                    w16(m, HP + 8 + 2 * j, 900)
        if i % 8 < 4:
            p.button_press('a')
        else:
            p.button_release('a')
        p.tick()
    p.button_release('a')


def s_talk(w):
    print('talk: the HOLDING PAIR\'s own conversation battle')
    cb, ca = w.sym['jr_053_4ea7']
    db, da = w.sym['DupConvFlag53']
    n, seen = [0], []

    def on_conv(_):
        n[0] += 1

    def on_read(_):
        rf = w.p.register_file
        if len(seen) < 64:
            seen.append(rf.HL)
    w.p.hook_register(cb, ca + 5, on_conv, None)
    w.p.hook_register(db, da, on_read, None)
    try:
        w.goto(w.rooms['hall'], 0, 5, 6)
        w.face('up')
        r = w.talk([True])
        if r == 'battle':
            watch(w, 5000)
        back = w.battle_won(maxf=40000) if r == 'battle' else False
        w.idle()
    finally:
        w.p.hook_deregister(cb, ca + 5)
        w.p.hook_deregister(db, da)
    eid = w.eids['holding_imp']
    w.check(f'the conversation battle started and ended, the field back ({r}, {back})',
            r == 'battle' and bool(back))
    w.check(f'DupConvFlag53 read the row\'s EID {eid} ({sorted(set(seen))[:4]}) and the '
            f'conversion ran ({n[0]})', eid in seen and n[0] > 0, f'{seen[:6]} {n[0]}')


def negative_rom(w):
    rom = bytearray(open(w.rom, 'rb').read())
    a = w.sym['DupConvFlag53'][1]
    pat = bytes([0xCD, a & 0xFF, a >> 8]) + b'\x00' * 6
    o = rom_off(w.sym, 'EnemyDupCastConversion_4e63')
    k = rom.find(pat, o, o + 0x60)
    if k < 0:
        raise SystemExit('EnemyDupCastConversion_4e63: no `call DupConvFlag53` + 6 nops')
    t = w.sym['EnemyDupConvFlagTable_41df'][1]
    orig = bytearray(ORIG_READ)
    orig[2], orig[6] = t & 0xFF, t >> 8
    rom[k:k + 9] = orig
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print('NEGATIVE CONTROL: the original unbounded flag read (project rows read code again)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--steps', default='table,stub,live,talk')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = MirrorWalk(a.build, a.sav, a.keep)
    d = json.load(open(a.project))
    ids = {r['id']: int(r['mapID'], 16) for r in d['custom']['rooms']}
    w.rooms = {'hall': ids['volley_hall']}
    from editor2.core.project import Project
    from editor2.core import balance as BAL
    prj = Project(d, os.path.dirname(os.path.abspath(a.project)))
    prj.repo_root = REPO
    w.prj = prj
    w.eids = {e['id']: e['_eid'] for e in prj.quest_enemy_rows()
              if e['id'] in ('holding_imp', 'casting_imp', 'far_holder', 'far_caster', 'catfly')}
    w.basemap = {}
    fl = json.load(open(os.path.join(REPO, 'extracted', 'enemy_dupconv_flags.json')))
    w.group = set(fl['dup_skills'])
    w.data = BAL.BattleData(prj)
    if a.negative:
        negative_rom(w)
    s_continue(w)
    w.save('start')
    steps = {'table': s_table, 'stub': s_stub, 'live': s_live, 'talk': s_talk}
    for name in [x for x in a.steps.split(',') if x]:
        try:
            w.start('start')
            steps[name](w)
        except Exception as e:                       # noqa: BLE001 — a step that crashes fails
            import traceback
            traceback.print_exc()
            w.check(f'{name} ran', False, repr(e))
    print(f'WALK: {"PASS" if not w.fails else "FAIL " + str(w.fails)} ({w.checks} checks)')
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
