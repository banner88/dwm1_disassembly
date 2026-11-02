#!/usr/bin/env python3
"""walk_mirror.py — S161 (ROADMAP E13 note + E17) on the real game (PyBoy on the user's .sav).

The demo (examples/s161_mirror_demo/build_demo.py) = the user's project + THE MIRROR HALL.

E13 note — two skills evolving from ONE skill (Blazemore and the new FLARE both from Blaze,
level 13; the new GLOW from Blaze, level 40). Until S161 a level up teaching both never ended;
since S161 bank $51 LearnUpgradeOrAdd51 learns the second as a new skill.

  siblings  party slot 2 = Blaze only, level 12 (exp at the level-12 mark), MP / INT high:
            beat the TRAINING DUMMY -> the battle ends, the record knows Blazemore AND
            Flare, not Blaze; the level up's lines: Blazemore "becomes" ($0B03, an upgrade in
            Blaze's place) and Flare "learned" ($0B02, the first free slot); never Glow;
  later     the same monster at level 39 (Blaze gone): its next level up never teaches Glow
            (the scanner tests a single prerequisite against the KNOWN skills); control: a
            monster that still knows Blaze at level 39 learns Glow at 40;
  full      party slot 2 = eight skills with Blaze, level 12: the level up overflows (two
            more) -> the game's forget menu, the battle ends, eight skills, Blazemore and
            Flare among them or forgotten by the menu's choice — never a hang;
  plain     (control) party slot 2 = Firebal only at level 9 (Firebane, its one child, at
            10): the original upgrade line ($0B03) and Firebal replaced in place.

E17 — the enemy AI judges a NEW skill AS ITS BASE (bank $57 AIViewArm57 -> bank $72
AIViewArm72: $DB8A = the base during the rule chain; bank $54 Fork54_RecordIndex reads the new
skill's own record for it), then adds its AI preference (bank $72 AIPrefEnd72).

  ai        TWIN battles (the S110 forced-battle rig, the party defending, its HP and status
            held; the RNG re-seeded at every AI state, commit and act — it also steps while the
            CPU idles, so a few more cycles drift it): the STOCK
            MAGE vs the NEW MAGE (high ids) and vs the RECL MAGE (reclaimed ids), the STOCK
            CASTER vs the NEW CASTER — the same decisions (the new ids mapped to their bases),
            the same casts, and the new skills ARE cast; the chain end sees the base's id;
  pref      the PICKY MAGE (PSnow +60, PBang -60), RNG free, against the STOCK MAGE: PBang
            never cast while the stock Bang is, PSnow cast more than the stock SnowStorm; the
            chain end adds +60 to PSnow's bonus and 60 to PBang's penalty;
  veto      the party all asleep: the STOCK CASTER's Sleep and the NEW CASTER's NSleep both
            VETOED by the base's rule (the veto exit sees Sleep's id $15 for NSleep);
  own       the new skill's OWN record in the chain: NBang's MP cost poked to 255 (ROM copy;
            the enemy has 250 MP): NBang vetoed by the MP rule and never cast, while the
            STOCK MAGE's Bang (the base's record, 2 MP) is;
  estimate  the party's damage estimate (bank $58 EstimateView58, stub-called in a live
            battle): NFireb / NBang / NInfer / NSleep == their bases, the ladder sees the base's
            id; NFireb's own power poked higher -> its estimate higher (its own record); an
            outer view (wAIViewId / wAIViewBase set) is put back after the call.

  python3 tools/walk_mirror.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative] [--steps …]

--negative: the S161 fixes removed in the ROM copy — LevelUpS04_LearnScan's `call
LearnUpgradeOrAdd51 / jr c` back to the original `ldh a, [$da] / ld l, a / ld h, $06` (the
siblings / later / full checks must FAIL: the level up never ends), and bank $72 AIViewArm72
returns with the view off and bank $53 DupBase53 tests the raw id (the ai / pref / veto /
estimate / dupcast checks of new skills must FAIL).
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import GAME_MODE, PARTY_LIST                          # noqa: E402
from tools.walk_regions import s_continue                                    # noqa: E402
from tools.walk_skills import SkillWalk, w16                                 # noqa: E402

REC, RECSZ = 0xCAC1, 149
DCEC, DEFEND, ATTACK = 0xDCEC, 0x8D, 0x3A
HP, MAXHP, MP = 0xDBA3, 0xDBB3, 0xDBC3
BLAZE, BLAZEMORE, FIREBAL, FIREBANE = 0, 1, 3, 4
LINE_LEARNED, LINE_BECOMES = 0x0B02, 0x0B03


def rom_off(sym, lab):
    b, a = sym[lab]
    return b * 0x4000 + a - 0x4000


class MirrorWalk(SkillWalk):
    def base(self, k):
        return REC + RECSZ * k

    def rec(self, k, off):
        return self.m[self.base(k) + off]

    def set_rec(self, k, off, v):
        self.m[self.base(k) + off] = v

    def skills(self, k):
        return [self.rec(k, 0x29 + i) for i in range(8)]

    def setup(self, k, level, skills, edge=False):
        """Party slot record k: `skills` (rest $FF), level, exp at that level's mark (the
        species' curve; edge: one short of the next level's, so any win levels up), MaxMP 99
        / INT 99 (Blazemore asks MP 46 / INT 64)."""
        m = self.m
        for i in range(8):
            self.set_rec(k, 0x29 + i, skills[i] if i < len(skills) else 0xFF)
        sp = self.rec(k, 0x09)
        self.set_rec(k, 0x4B, level)
        if self.rec(k, 0x4C) < level + 30:                 # max level
            self.set_rec(k, 0x4C, min(99, level + 30))
        xp = self.T.exp_to_reach(sp, level + 1) - 1 if edge else self.T.exp_to_reach(sp, level)
        for i in range(3):
            self.set_rec(k, 0x4D + i, (xp >> (8 * i)) & 0xFF)
        w16(m, self.base(k) + 0x56, 99)                    # MaxMP
        w16(m, self.base(k) + 0x54, 99)                    # MP
        w16(m, self.base(k) + 0x5E, 99)                    # INT

    def fight_dummy(self, maxf=20000):
        """Talk to the TRAINING DUMMY (screen 1 (8, 5), from below), fight, A until the field
        is back. -> (talk result, back to the field, the level-up lines [(HL, C, $FFD8)])."""
        lines = []
        b, a = self.sym['jr_051_5799']

        def on_place(_):
            rf = self.p.register_file
            if len(lines) < 64:
                lines.append((rf.HL, rf.C, self.m[0xFFD8]))
        self.p.hook_register(b, a, on_place, None)
        try:
            self.goto(self.rooms['hall'], 0, 18, 6)
            self.face('up')
            r = self.talk([True])
            back = self.battle_won(maxf=maxf) if r == 'battle' else False
            self.idle()
        finally:
            self.p.hook_deregister(b, a)
        return r, back, lines


    def spar(self, eid, frames=6000, seed=0x1234, reseed=True, board=None, always=None,
             snap_ids=None, trace=None, ecount=1, hooks=None):
        """A forced battle against enemy row `eid` (the S110 rig: $DA03 / $DA09 / $C8EB bit 6),
        the party DEFENDING ($8D in its queue cells), the foe's HP 400 / MP 250 and the
        party's HP 900 held in phases 4-6; the RNG set to `seed` at the first battle frame
        and (reseed) re-seeded to seed + 97 k at every RNG-using stage: each state of an enemy
        AI decision (bank $57 states 0-5 and 7, actor >= 4), every commit-time target fetch
        ($58:$545B) and act ($53:$520C). The RNG also steps while the
        CPU idles (S86 idle model), so the same code path with a few more cycles (a new id's
        far calls) drifts it — re-seeding at each stage makes equal boards act alike.
        board(m): pokes in phases 4-6;
        always(m): pokes on every battle frame from phase 1. snap_ids: the skills whose chain
        ends are snapshot for sim_check (default: the new skills). trace: a list that gets
        (event, frame, actor, $DB8A, RNG1, RNG2) at every decision start / post, act and
        commit-time target fetch ($58:$545B) and act sub-state 0 ($53:$520C). ecount: enemies
        of the row (1-3); hooks: [(bank, addr, fn(m))] more hooks.
        -> {'dec': [(d9ed, queued skill)], 'acts': [(actor, skill)], 'chain': [($DB8A at
        the chain end, $DD26, $DD27)], 'veto': [$DB8A at the veto exit], 'start': bool}."""
        p, m, S = self.p, self.m, self.sym
        log = {'dec': [], 'acts': [], 'chain': [], 'after': [], 'veto': [], 'start': False}
        k = [0]

        def tr(tag):
            if trace is not None and len(trace) < 3000:
                trace.append((tag, p.frame_count, m[0xDB88], m[0xDB8A], m[0xC899], m[0xC89A]))

        def rs(enemy_only=True):
            if reseed and (m[0xDB88] >= 4 or not enemy_only):
                k[0] += 1
                v = (seed + 97 * k[0]) & 0xFFFF
                m[0xC899], m[0xC89A] = v & 0xFF, v >> 8

        def on_pre(_):
            tr('pre')
            rs()

        def on_pick(_):
            tr('pick')
            rs()

        def on_commit(_):
            tr('commit')
            rs(False)

        def on_act0(_):
            tr('act0')
            rs(False)

        def on_post(_):
            tr('post')
            a = m[0xDB88]
            if a >= 4:
                log['dec'].append((m[0xD9ED], m[DCEC + 2 * a]))

        def on_act(_):
            tr('act')
            log['acts'].append((m[0xDB88], m[0xDB8A]))

        def on_chain(_):
            if m[0xDB88] >= 4:
                log['chain'].append((m[0xDB8A], m[0xDD26], m[0xDD27]))

        def snap(true_id, end):
            """the board the rules read + the outcome, for the simulator twin (sim_check)."""
            return {'id': true_id, 'cat': m[0xDD6A], 'actor': m[0xDB88], 'dd6b': m[0xDD6B],
                    'end': end, 'hp': [m[HP + 2 * j] | m[HP + 2 * j + 1] << 8 for j in range(8)],
                    'maxhp': [m[MAXHP + 2 * j] | m[MAXHP + 2 * j + 1] << 8 for j in range(8)],
                    'mp': [m[MP + 2 * j] | m[MP + 2 * j + 1] << 8 for j in range(8)],
                    'maxmp': [m[0xDBD3 + 2 * j] | m[0xDBD4 + 2 * j] << 8 for j in range(8)],
                    'st': [m[0xDB00 + j] for j in range(66)],
                    'dd1b': [m[0xDD1B + j] for j in range(8)],
                    'res': [m[0xDD28 + j] for j in range(56)]}

        def on_after(_):
            if m[0xDB88] >= 4:
                log['after'].append((m[0xDB8A], m[0xDD26], m[0xDD27]))
                if m[0xDB8A] in (snap_ids or self.basemap) and len(log.setdefault('snaps', [])) < 400:
                    d, p_ = m[0xDD26], m[0xDD27]
                    log['snaps'].append(snap(m[0xDB8A], (0, True) if p_ == 0xFF or d < p_
                                             else ((d - p_) & 0xFF, False)))

        def on_veto(_):
            if m[0xDB88] >= 4:
                log['veto'].append(m[0xDB8A])
                if m[0xDED5] and len(log.setdefault('snaps', [])) < 400:   # wAIViewId
                    log['snaps'].append(dict(snap(m[0xDED5], (0, True)), veto_exit=True))
        regs = [S['AIState0Preamble_6e2a'] + (on_pre,), S['AIState6Post_7859'] + (on_post,),
                S['FarSkillFork'] + (on_act,), S['AIChainApplyDelta_78a2'] + (on_chain,),
                S['AIChainZeroCell_788b'] + (on_veto,),
                (S['AIChainApplyDelta_78a2'][0], S['AIChainApplyDelta_78a2'][1] + 3, on_after)]
        regs += [(0x58, 0x545B, on_commit), (0x53, 0x520C, on_act0),
                 S['AIState5Pick_75a2'] + (on_pick,)]
        for hb, ha, hf in (hooks or ()):
            regs.append((hb, ha, (lambda f_: (lambda _c: f_(m)))(hf)))

        def on_state(t):
            def f(_c):
                tr(t)
                rs()
            return f
        for lab in ('AIState1CategoryScores_7129', 'AIState2CategorySelect_73b9',
                    'AIState3SkillSums_7529', 'AIState4FilterEval_7439',
                    'AIState7ChainWalker_7865'):
            regs.append(S[lab] + (on_state(lab[7:13]),))
        for b, a, fn in regs:
            p.hook_register(b, a, fn, None)
        for j in range(ecount):                     # wTempEnemyId1-3: the same row
            m[0xDA03 + 2 * j], m[0xDA04 + 2 * j] = eid & 0xFF, eid >> 8
        m[0xDA02] = ecount - 1
        m[0xDA09] = 1
        m[0xC905] = 0
        m[0xC8EB] |= 0x40
        seeded = False
        try:
            for i in range(frames):
                if m[GAME_MODE] == 2:
                    ph = m[0xD9EC]
                    if ph >= 1:
                        log['start'] = True
                        if not seeded:
                            m[0xC899], m[0xC89A] = seed & 0xFF, seed >> 8
                            seeded = True
                        if always:
                            always(m)
                    for j in range(3):
                        m[DCEC + 2 * j] = DEFEND
                    if 4 <= ph <= 6:
                        for j in range(3):
                            m[DCEC + 2 * j + 1] = j
                            if m[0xDD1B + j] != 0xFF:
                                w16(m, HP + 2 * j, 900)
                                w16(m, MAXHP + 2 * j, 999)
                        for j in range(ecount):
                            w16(m, HP + 8 + 2 * j, 400)
                            w16(m, MP + 8 + 2 * j, 250)
                        if board:
                            board(m)
                if i % 8 < 4:
                    p.button_press('a')
                else:
                    p.button_release('a')
                p.tick()
                if len(log['acts']) + len(log['chain']) > 4000:
                    log['runaway'] = i
                    break
        finally:
            p.button_release('a')
            for b, a, _fn in regs:
                p.hook_deregister(b, a)
        return log


def lines_str(lines):
    return [(f'${hl:04X}', f'${c:02X}', f'${s:02X}') for hl, c, s in lines]


# ------------------------------------------------------------------ steps
def s_siblings(w):
    print('siblings: Blazemore and Flare both from Blaze at one level up')
    m = w.m
    k = m[PARTY_LIST + 2]
    w.setup(k, 12, [BLAZE])
    r, back, lines = w.fight_dummy()
    sk = w.skills(k)
    lv = w.rec(k, 0x4B)
    w.snap('siblings')
    w.check('the TRAINING DUMMY beaten, the battle ENDS (back to the field) and party slot 2 '
            'reached level 13+', r == 'battle' and back and lv >= 13 and m[GAME_MODE] == 1,
            f'{r}, back {back}, level 12->{lv}')
    w.check(f'it knows Blazemore AND Flare (${w.FLARE:02X}), Blaze is gone',
            BLAZEMORE in sk and w.FLARE in sk and BLAZE not in sk, str([hex(s) for s in sk]))
    bec = [x for x in lines if x[2] == BLAZEMORE]
    lea = [x for x in lines if x[2] == w.FLARE]
    w.check('the lines: Blazemore "becomes" ($0B03, C = Blaze: in its place), Flare "learned" '
            '($0B02, C = $FF: the first free slot) — each once',
            len(bec) == 1 and bec[0][0] == LINE_BECOMES and bec[0][1] == BLAZE
            and len(lea) == 1 and lea[0][0] == LINE_LEARNED and lea[0][1] == 0xFF,
            str(lines_str(lines)))
    w.check(f'never Glow (${w.GLOW:02X}, from Blaze at level 40)', w.GLOW not in sk,
            str([hex(s) for s in sk]))
    w.save('after_siblings')


def s_later(w):
    print('later: Glow (from Blaze, level 40) after Blaze became Blazemore')
    m = w.m
    k = m[PARTY_LIST + 2]
    w.setup(k, 39, [BLAZEMORE, w.FLARE], edge=True)
    r, back, lines = w.fight_dummy()
    sk = w.skills(k)
    w.check('Blazemore + Flare at level 39 -> 40+: the battle ends and Glow is NOT learned '
            '(its one prerequisite, Blaze, is no longer known)',
            r == 'battle' and back and w.rec(k, 0x4B) >= 40 and w.GLOW not in sk,
            f'{r}, back {back}, level {w.rec(k, 0x4B)}, {[hex(s) for s in sk]}, '
            f'lines {lines_str(lines)}')
    w.start('start')
    k = w.m[PARTY_LIST + 2]
    w.setup(k, 39, [BLAZE, BLAZEMORE], edge=True)
    r, back, lines = w.fight_dummy()
    sk = w.skills(k)
    w.check('control — a monster that still knows Blaze (beside Blazemore) at level 39 learns '
            'Glow at 40 (the setup can teach it)',
            r == 'battle' and back and w.GLOW in sk,
            f'{r}, back {back}, level {w.rec(k, 0x4B)}, {[hex(s) for s in sk]}, '
            f'lines {lines_str(lines)}')


def s_full(w):
    print('full: eight skills with Blaze -> two more at one level up -> the forget menu')
    m = w.m
    k = m[PARTY_LIST + 2]
    eight = [BLAZE, 0x15, 0x1C, 0x2B, 0x33, 0x3D, 0x40, 0x56]
    w.setup(k, 12, eight)
    r, back, lines = w.fight_dummy(maxf=40000)
    sk = w.skills(k)
    w.snap('full')
    w.check('the battle ends (the forget menu answered by A), eight skills, Blaze gone, the '
            'two new ones learned or one of them forgotten by the menu',
            r == 'battle' and back and 0xFF not in sk and BLAZE not in sk
            and (BLAZEMORE in sk or w.FLARE in sk) and len(set(sk)) == 8,
            f'{r}, back {back}, level {w.rec(k, 0x4B)}, {[hex(s) for s in sk]}, '
            f'lines {lines_str(lines)}')


def s_plain(w):
    print('plain: the original one-child upgrade (control)')
    m = w.m
    k = m[PARTY_LIST + 2]
    w.setup(k, 9, [FIREBAL])
    r, back, lines = w.fight_dummy()
    sk = w.skills(k)
    up = [x for x in lines if x[2] == FIREBANE]
    w.check('Firebal at level 9 -> Firebane "becomes" ($0B03, C = Firebal) in its place — the '
            'original upgrade unchanged', r == 'battle' and back and up
            and up[0][0] == LINE_BECOMES and up[0][1] == FIREBAL and sk[0] == FIREBANE
            and FIREBAL not in sk, f'{r}, back {back}, {[hex(s) for s in sk]}, '
            f'lines {lines_str(lines)}')


# ------------------------------------------------------------------ E17
SEEDS = (0x1234, 0x5A17, 0x9C3B)


def sim_check(w, snaps, alias=True):
    """The Balance simulator's AI chain (simulator/ai_rules.evaluate_chain, as pacing.ChainRules
    calls it since S161: the BASE's id, the new skill's own record, its preference) on the
    ROM's own board at each chain end of a new skill -> [(id, ROM outcome, simulator)] that
    differ, and how many were compared."""
    from simulator import ai_rules as R
    bad = []
    for sn in snaps:
        sid = sn['id']
        rec = w.data.records.get(sid)
        f = rec['battle_record']['fields'] if rec else {}
        res = sn['res']
        view = R.BattleView(sn['hp'], sn['maxhp'], sn['mp'], sn['maxmp'],
                            [sn['st'][8 * j:8 * j + 8] for j in range(8)], sn['dd1b'],
                            [0] * 8, [None] * 8,
                            lambda s_, e: (res[s_ * 7 + (e >> 2)] >> ((3 - (e & 3)) * 2)) & 3)
        got = R.evaluate_chain(sn['cat'], w.data.core_alias.get(sid, sid) if alias else sid, sn['actor'], view,
                               f.get('mp_cost_byte', 0), f.get('status_id', 0), sn['dd6b'],
                               pref=w.data.ai_pref.get(sid, 0))
        if got != sn['end']:
            bad.append((sid, sn['end'], got))
    return bad, len(snaps)


def mapped(w, seq, j):
    """seq of tuples with the skill id at j: every new skill written as its base."""
    return [tuple(w.basemap.get(x, x) if i == j else x for i, x in enumerate(t)) for t in seq]


def casts(w, log, ids):
    return sum(1 for a, sk in log['acts'] if a >= 4 and sk in ids)


def keep_party_status():
    """always(m) for twin battles: the party's status block ($DB00-$DB17, slots 0-2) as at
    the first battle frame — a status a skill lands (Sleep, Sap …) would change the board
    the next decision reads, and WHETHER it lands rolls after the act's own idle frames,
    which drift with the CPU time of the acting code (a new id's far calls)."""
    snap = {}

    def f(m):
        if not snap:
            snap.update({a: m[a] for a in range(0xDB00, 0xDB18)})
        for a, v in snap.items():
            m[a] = v
    return f


def s_ai(w):
    print('ai: twin battles — a STOCK row and its NEW twin decide alike (RNG re-seeded per decision)')
    for stock, new, what in (('stock_mage', 'new_mage', 'NEW MAGE (high ids)'),
                             ('stock_mage', 'recl_mage', 'RECL MAGE (reclaimed ids)'),
                             ('stock_caster', 'new_caster', 'NEW CASTER (high ids)')):
        same_dec = same_act = True
        n_new = n_stock = n_dec = 0
        snaps, ssnaps = [], []
        chain_base = True
        detail = ''
        for seed in SEEDS:
            w.start('start')
            a = w.spar(w.eids[stock], seed=seed, snap_ids=set(w.basemap.values()),
                       always=keep_party_status())
            ssnaps += a.get('snaps', [])
            w.start('start')
            b = w.spar(w.eids[new], seed=seed, always=keep_party_status())
            snaps += b.get('snaps', [])
            da, db = a['dec'], mapped(w, b['dec'], 1)
            aa = [x for x in a['acts'] if x[0] >= 4]
            ab = mapped(w, [x for x in b['acts'] if x[0] >= 4], 1)
            k = min(len(aa), len(ab))       # the fixed frame window may end one act apart
            aa, ab = aa[:k], ab[:k]         #   (a new id's far calls take a few more cycles):
            k = min(len(da), len(db))       #   the common prefix is compared
            da, db = da[:k], db[:k]
            n_dec += len(da)
            if da != db or not a['start'] or len(da) < 6:
                same_dec = False
                detail = detail or f'seed {seed:#x}: {da[:10]} vs {db[:10]}'
            if aa != ab:
                same_act = False
                detail = detail or f'acts {aa[:10]} vs {ab[:10]}'
            n_new += sum(1 for _a, x in ab if x in set(w.basemap.values()))
            n_stock += sum(1 for _a, x in aa if x in set(w.basemap.values()))
            if any(x[0] in w.basemap for x in b['chain']):
                chain_base = False
        w.check(f'{what} vs STOCK: the same {n_dec} enemy decisions over {len(SEEDS)} battles '
                '(new ids mapped to their bases)', same_dec, detail)
        w.check(f'{what}: the same casts as the stock twin, and new skills ARE cast '
                f'({n_new} new-skill casts / {n_stock} stock)', same_act and n_new > 0
                and n_new == n_stock, detail)
        w.check(f'{what}: at every chain end of a new skill $DB8A held its BASE (the rules '
                'saw the base\'s id)', chain_base, '')
        bad, n = sim_check(w, snaps)
        sbad, sn_ = sim_check(w, ssnaps)
        if sbad:            # the stock twin has no veto-exit snapshots (no view): compare alike
            bad, n = sim_check(w, [x for x in snaps if not x.get('veto_exit')])
        if not sbad:
            w.check(f'{what}: the Balance simulator\'s rule chain (the base\'s id, the new skill\'s '
                    f'record) == the ROM at all {n} chain ends of new skills', n > 0 and not bad,
                    str(bad[:6]))
        else:
            # [S161 FOUND] the model of these BASES differs from the ROM on this board (three
            # live opponents; the S81 sweep had one) — a gap of the stock skills, ROADMAP E17
            # note. What E17 asks: the new skills are modelled exactly as their bases.
            key = lambda xs: sorted((w.basemap.get(i, i), e, g) for i, e, g in xs)
            w.check(f'{what}: the Balance simulator models the new skills exactly as their '
                    f'bases — the same {len(bad)} / {n} chain ends differ from the ROM as for the '
                    f'stock twin\'s own skills ({len(sbad)} / {sn_}: a model gap of the BASES on '
                    'a three-opponent board, ROADMAP E17 note)',
                    n > 0 and key(bad) == key(sbad) and n == sn_,
                    f'new {bad[:4]}, stock {sbad[:4]}')


def s_pref(w):
    print('pref: the PICKY MAGE (PSnow +60, PBang -60), the RNG free')
    P, N = w.P, w.N
    tot_p, tot_s = {}, {}
    ch = []
    snaps = []
    for seed in SEEDS:
        w.start('start')
        a = w.spar(w.eids['picky_mage'], seed=seed, reseed=False)
        w.start('start')
        b = w.spar(w.eids['stock_mage'], seed=seed, reseed=False)
        for x in a['acts']:
            if x[0] >= 4:
                tot_p[x[1]] = tot_p.get(x[1], 0) + 1
        for x in b['acts']:
            if x[0] >= 4:
                tot_s[x[1]] = tot_s.get(x[1], 0) + 1
        ch += a['after']
        snaps += a.get('snaps', [])
    pb, ps = tot_p.get(P['Bang'], 0), tot_p.get(P['Snow'], 0)
    sb, ss = tot_s.get(6, 0), tot_s.get(13, 0)
    w.check(f'PBang (-60) never cast ({pb}), the stock Bang is ({sb})', pb == 0 and sb > 0,
            f'picky {tot_p}, stock {tot_s}')
    w.check(f'PSnow (+60) cast more than the stock SnowStorm ({ps} vs {ss})', ps > ss and ps > 0,
            f'picky {tot_p}, stock {tot_s}')
    snow = {(b_, p_) for x, b_, p_ in ch if x == P['Snow']}
    bang = {(b_, p_) for x, b_, p_ in ch if x == P['Bang']}
    w.check('after the chain end (CustomAI57): PSnow bonus = SnowStorm\'s +40 + 60 = 100, PBang = '
            'Bang\'s +60 with a penalty of 60 (net 0: weight + roll only, below plain Attack); '
            '$DB8A back to the new ids', snow == {(100, 0)} and bang == {(60, 60)},
            f'snow {snow}, bang {bang}')
    bad, n = sim_check(w, snaps)
    w.check(f'the Balance simulator (with the preferences) == the ROM at all {n} chain ends of the '
            'PICKY MAGE\'s skills', n > 0 and not bad, str(bad[:6]))


def s_veto(w):
    print('veto: the party asleep — Sleep and NSleep vetoed alike')

    def asleep(m):
        for j in range(3):
            m[0xDB02 + 8 * j] |= 0x80
    for row, sid, nm in (('stock_caster', 0x15, 'Sleep'), ('new_caster', w.N['Sleep'], 'NSleep')):
        w.start('start')
        r = w.spar(w.eids[row], seed=SEEDS[0], always=asleep)
        c = casts(w, r, {sid})
        v = r['veto'].count(0x15)
        w.check(f'{row}: {nm} never cast against a sleeping party, the veto exit saw Sleep\'s id '
                f'$15 ({v} vetoes)', r['start'] and c == 0 and v > 0,
                f'casts {c}, vetoes {r["veto"][:12]}')
    w.start('start')
    r = w.spar(w.eids['new_caster'], seed=SEEDS[0])
    w.check('control — awake party: the NEW CASTER casts NSleep / NSap',
            casts(w, r, {w.N['Sleep'], w.N['Sap']}) > 0, str(r['acts'][:20]))


def rom_poke(w, lab, off, val):
    b, a = w.sym[lab]
    w.p.memory[b, a + off] = val


def s_own(w):
    print('own: the chain reads the NEW skill\'s record — NBang at 255 MP is vetoed')
    tot = {}
    vetoes = []
    for seed in SEEDS:
        w.start('start')
        rom_poke(w, 'CustomRecord_F0', 4, 255)          # NBang (240): record +4 = battle MP
        r = w.spar(w.eids['new_mage'], seed=seed, reseed=False)
        for x in r['acts']:
            if x[0] >= 4:
                tot[x[1]] = tot.get(x[1], 0) + 1
        vetoes += r['veto']
    nb = tot.get(w.N['Bang'], 0)
    w.check(f'NBang never cast ({nb}) and vetoed at the chain ({vetoes.count(6)} vetoes as Bang\'s '
            'id), the other three still cast', nb == 0 and vetoes.count(6) > 0
            and sum(v for k, v in tot.items() if k in w.basemap) > 0, f'{tot}, vetoes {vetoes[:12]}')


STUB, MARK = 0xDE40, 0xDE3F


def stub_call(w, bank, addr, c=None, maxf=120):
    m, p = w.m, w.p
    code = [0xF3, 0x3E, bank, 0xEA, 0x00, 0x21]
    if c is not None:
        code += [0x0E, c]
    code += [0xCD, addr & 0xFF, addr >> 8, 0x3E, 0xA5, 0xEA, MARK & 0xFF, MARK >> 8, 0x18, 0xFE]
    for i, b in enumerate(code):
        m[STUB + i] = b
    m[MARK] = 0
    p.register_file.PC = STUB
    for _ in range(maxf):
        p.tick(1, False)
        if m[MARK] == 0xA5:
            return True
    return False


def s_estimate(w):
    print('estimate: the party\'s damage estimate of a new skill = its base\'s (stub-called)')
    import io
    w.start('start')
    w.spar(w.eids['stock_mage'], frames=700)
    st = io.BytesIO()
    w.p.save_state(st)
    b58, a58 = w.sym['SaveBtlFX_43ff']
    m = w.m

    def est(sk, pre=None, poke=None):
        st.seek(0)
        w.p.load_state(st)
        m = w.m
        if poke:
            poke()
        m[0xDB8A], m[0xDB88], m[0xDB89] = sk, 0, 4
        m[0xDB56] = m[0xDB57] = 0xEE
        if pre:
            m[0xDED5], m[0xDED6] = pre
        seen = []
        hb, ha = w.sym['AIDamageEstimate_538f']
        pb, pa = 0x54, 0x52C7
        w.p.hook_register(hb, ha, lambda _c: len(seen) < 32 and seen.append(('est', m[0xDB8A])), None)
        w.p.hook_register(pb, pa, lambda _c: len(seen) < 32 and seen.append(('pow', m[0xDB8A])), None)
        ok = stub_call(w, b58, a58, c=4)
        w.p.hook_deregister(hb, ha)
        w.p.hook_deregister(pb, pa)
        return ok, m[0xDB56] | m[0xDB57] << 8, seen, m[0xDB8A], (m[0xDED5], m[0xDED6])
    for nm, base in (('Fireb', 3), ('Bang', 6), ('Infer', 9), ('Sleep', 21)):
        sid = w.N[nm]
        a, b = est(base), est(sid)
        w.check(f'N{nm} (${sid:02X}) estimated as {nm}\'s base ${base:02X}: the same value, the '
                'ladder saw the base\'s id, $DB8A back to the new id, the view off',
                a[0] and b[0] and a[1] == b[1] and b[2] and all(x == base for _k, x in b[2])
                and b[3] == sid and b[4][0] == 0, f'base {a[:3]}, new {b}')
    a = est(w.N['Fireb'])
    b = est(w.N['Fireb'], poke=lambda: rom_poke(w, 'CustomRecord_EF', 11, 200))
    w.check('NFireb\'s OWN power (record +11 poked to 200): its estimate follows its own record',
            a[0] and b[0] and b[1] > a[1], f'{a[1]} -> {b[1]}')
    c = est(w.N['Fireb'], pre=(w.N['Sleep'], 0x15))
    w.check('an outer view (wAIViewId / wAIViewBase = NSleep / Sleep) is put back after the '
            'estimate', c[0] and c[4] == (w.N['Sleep'], 0x15), str(c))


def s_dupcast(w):
    print('dupcast: the enemy duplicate-group-cast conversion tests a new skill as its base')
    rom = open(w.rom, 'rb').read()
    b, a = w.sym['GroupDupSkillList_4ee4']
    o = b * 0x4000 + a - 0x4000
    lst = set()
    while rom[o] != 0xFF:
        lst.add(rom[o])
        o += 1
    import io
    w.start('start')
    w.spar(w.eids['stock_mage'], frames=700)
    st = io.BytesIO()
    w.p.save_state(st)
    bad = []
    lb, la = w.sym['DupCastSkillListCheck_4ed6']
    for sid in range(256):
        st.seek(0)
        w.p.load_state(st)
        ok = stub_call(w, lb, la, c=sid)
        z = bool(w.p.register_file.F & 0x80)
        want = w.basemap.get(sid, sid) in lst
        if not ok or z != want:
            bad.append(hex(sid))
    w.check(f'DupCastSkillListCheck_4ed6 stub-called for ids 0-255: in the list = the BASE in the '
            f'{len(lst)}-id list (NBang ${w.N["Bang"]:02X} as Bang, RBang ${w.R["Bang"]:02X} too)',
            not bad, str(bad[:8]))
    cb, ca = w.sym['jr_053_4ea7']
    conv = {}

    def lowint(m):
        m[0xDD0B + 4] = m[0xDD0B + 5] = 1           # $DD0B != 2: the conversion applies
    for row in ('stock_mage', 'new_mage'):
        n = [0]
        tot = []
        for seed in SEEDS:
            w.start('start')
            r = w.spar(w.eids[row], seed=seed, ecount=2, always=keep_party_status(),
                       board=lowint, hooks=[(cb, ca + 5, lambda m: n.__setitem__(0, n[0] + 1))])
            tot += mapped(w, [x for x in r['acts'] if x[0] >= 4], 1)
        conv[row] = (n[0], sum(1 for _a, x in tot if x == 6), len(tot))
    s_, n_ = conv['stock_mage'], conv['new_mage']
    w.check(f'two STOCK MAGES vs two NEW MAGES (INT mode 1): the second Bang / NBang of a round '
            f'becomes Attack alike — conversions {s_[0]} / {n_[0]}, Bang casts {s_[1]} / {n_[1]}',
            s_[0] > 0 and s_[:2] == n_[:2], f'stock {s_}, new {n_} (conversions, Bang casts, '
            'acts in the frame window)')


# ------------------------------------------------------------------ negative
def negative_rom(w):
    rom = bytearray(open(w.rom, 'rb').read())
    o = rom_off(w.sym, 'LevelUpS04_LearnScan')
    a = w.sym['LearnUpgradeOrAdd51'][1]
    pat = bytes([0xCD, a & 0xFF, a >> 8, 0x38])
    k = rom.find(pat, o, o + 0x60)
    if k < 0:
        raise SystemExit('LevelUpS04_LearnScan: no `call LearnUpgradeOrAdd51 / jr c`')
    rom[k:k + 5] = b'\xF0\xDA\x6F\x26\x06'           # ldh a,[$da] / ld l,a / ld h,$06
    o = rom_off(w.sym, 'AIViewArm72')
    if rom[o:o + 4] != b'\xAF\xEA\xD5\xDE':
        raise SystemExit('AIViewArm72: not `xor a / ld [wAIViewId], a`')
    rom[o + 4] = 0xC9                                 # then ret: the view never on
    o = rom_off(w.sym, 'DupBase53')                   # the list test with the raw id:
    la = w.sym['GroupDupSkillList_4ee4'][1]           #   ld hl, GroupDupSkillList / ret
    rom[o:o + 4] = bytes([0x21, la & 0xFF, la >> 8, 0xC9])
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print('NEGATIVE CONTROL: LevelUpS04_LearnScan back to the original code-1 path; '
          'AIViewArm72 returns with the view off')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--steps', default='siblings,later,full,plain,ai,pref,veto,own,estimate,dupcast')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = MirrorWalk(a.build, a.sav, a.keep)
    d = json.load(open(a.project))
    ids = {r['id']: int(r['mapID'], 16) for r in d['custom']['rooms']}
    w.rooms = {'hall': ids['mirror_hall']}
    from editor2.core.project import Project
    from simulator import raising as RS
    prj = Project(d, os.path.dirname(os.path.abspath(a.project)))
    prj.repo_root = REPO
    w.T = RS.Tables.from_gamedata(prj.gamedata(), prj)
    w.eids = {e['id']: e['_eid'] for e in prj.quest_enemy_rows()}
    sk = d['gamedata']['skills']
    names = {v['name']: int(k) for k, v in sk.items() if isinstance(v, dict) and v.get('name')}
    w.FLARE, w.GLOW = names['Flare'], names['Glow']
    w.N = {n[1:]: i for n, i in names.items() if n[0] == 'N' and n[1:] in
           ('Fireb', 'Bang', 'Infer', 'Snow', 'Sleep', 'Sap', 'Psych', 'Volt')}
    w.P = {n[1:]: i for n, i in names.items() if n[0] == 'P' and n[1:] in ('Fireb', 'Bang', 'Infer', 'Snow')}
    w.R = {n[1:]: i for n, i in names.items() if n[0] == 'R' and 188 <= i <= 211}
    w.basemap = {int(k): v['base'] for k, v in sk.items() if isinstance(v, dict) and 'base' in v}
    from editor2.core import balance as BAL
    w.data = BAL.BattleData(prj)
    if a.negative:
        negative_rom(w)
    s_continue(w)
    w.save('start')
    steps = {'siblings': s_siblings, 'later': s_later, 'full': s_full, 'plain': s_plain,
             'ai': s_ai, 'pref': s_pref, 'veto': s_veto, 'own': s_own, 'estimate': s_estimate,
             'dupcast': s_dupcast}
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
