#!/usr/bin/env python3
"""walk_reclaim.py — S160 (ROADMAP E13): the 14 RECLAIMED skill ids on the real game (PyBoy
on the user's .sav).

Since S160 a NEW skill can sit on the battle-skill id of LifeAcorn, MysticNut, the four seeds
($BC-$C1), WarpWing, TinyMedal or the six books ($CC-$D3); it must act EXACTLY like a new
skill on a high id ($EF-$FE). The demo (examples/s160_twin_demo/build_demo.py) = the user's
project + THE TWIN HALL: 14 TWIN pairs (the same base, the same data; "H…" on $EF-$FC, "R…"
on the 14 reclaimed ids) + HSnow / HHell ($FD / $FE).

  gift     the GIFT KEEPER (YES) gives HIGHTWIN (HFireb / HInfer / HAntid / HMulti) and
           RECLTWIN (the R twins): the records carry the ids;
  twins    every pair, cast by party slot 0 at the foe (the S110 forced-battle rig, the RNG
           pinned, from ONE saved state): the battle messages (id, number $DB56, subject,
           wCustomLine) the same, the skill id aside; HFireb / RFireb render their OWN
           announce lines (the text engine's address = CustomMsgPtrTable row 17 / row 33);
  enemy    the sparring rows in pairs (the enemy AI free, INT 200, the RNG pinned, the party
           defending): HIGH vs RECL SLASHER (EvilSlash / Beserker / SquallHit / Whistle) and
           HIGH vs RECL CASTER (Sleep / Sap / PsycheUp / BoltSlash): the same enemy actions
           (actor, skill twin-mapped, target) — and no new skill cast, either kind (ROADMAP
           E17). The two id-range routines STUB-CALLED in a live battle (a forked copy each,
           so a CPU lock-up is caught): bank $58 SaveBtlFX_43ff (the AI damage estimate, bank
           $52 entry 3 — reached in play only by a party monster's own target pick) of the
           five Attack-row twins: H == R, AIDamageEstimate_538f sees $EF; bank $57 AIRule_4785
           with every party monster paralysed: stock Sleep vetoed, six twin pairs not;
  items    a LifeAcorn / a WarpWing in the bag: the battle ITEM menu refuses them ("Can't use
           this item in battle!", message $F2; no skill acts, the bag keeps them) though
           their ids hold RFireb / RMulti; a Herb is accepted (the control); in the field
           the LifeAcorn raises the lead monster's max HP as always (and is used up);
  learn    party slot 2 = Blazemost + Firebolt, INT 950: beat the TRAINING DUMMY — the level
           up teaches HFireb (from Blazemost) AND RFireb (from Firebolt), NEVER HBang / RBang (two
           prerequisites: the learn scanner's code 2 is fenced for new skills, bank $06
           LearnFence06 — both kinds alike);
  freeze   (the hazard behind the compiler's S160 warning) in a ROM copy RFireb's learn row
           names Blazemost too: the same level up never ends — bank $51 LevelUpS04_LearnScan
           replaces Blazemost with the first, finds no Blazemost for the second and the scanner
           offers it again, forever (any two skills evolving from one skill alone).

  python3 tools/walk_reclaim.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative] [--steps …]

--negative: the S160 views removed in the ROM copy — bank $72 ReclaimBase72 and bank $4C
ReclaimLine4C return at once (a reclaimed id runs its old item effect / the stock $FD line),
bank $58 FxEstimate58 = the original `ld hl,$5203 / rst $10` (the estimate indexes past its
table), bank $57 AIRule_4785 reads $DB8A raw, bank $77 ReclaimedSkill77 says "not reclaimed",
bank $06 LearnFence06 fences custom ids $DA+ only: the twins / enemy / items / learn checks
of the reclaimed side must FAIL (S160: 33 FAIL; the five reclaimed estimates lock the CPU up).
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import io
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, GAME_MODE, PARTY_LIST              # noqa: E402
from tools.walk_regions import s_continue                                    # noqa: E402
from tools.walk_skills import SkillWalk, r16, w16, HP, MAXHP, MP, CURSE_ATTACK, WCUSTOMLINE  # noqa: E402

DCEC = 0xDCEC
REC, RECSZ = 0xCAC1, 149
BAG = 0xCA51
BLAZEMOST, FIREBOLT, HERB, LIFEACORN, WARPWING = 2, 5, 1, 13, 29
DEFEND = 0x8D
RECLAIMED = list(range(0xBC, 0xC2)) + list(range(0xCC, 0xD4))


def rom_off(sym, lab):
    b, a = sym[lab]
    return b * 0x4000 + a - 0x4000


class ReclaimWalk(SkillWalk):
    def rec(self, k, off):
        return self.m[REC + RECSZ * k + off]

    def set_rec(self, k, off, v):
        self.m[REC + RECSZ * k + off] = v

    def battle(self, eid, frames, party=DEFEND, enemy=None, caster=None, skill=None, target=4,
               board=None, hooks=None, paralyse=False, etarget=None):
        """A forced battle against enemy row `eid` (the S110 rig: started from the field
        through $DA03 / $DA09 / $C8EB bit 6, the RNG pinned every frame). The party acts
        `party` (or party slot `caster` acts `skill` on `target`); the enemy's action is
        forced to `enemy` or left to its AI (None). HP held (the foe at 999, the party 900).
        hooks: {(bank, addr): fn(log)}. -> {'msgs': [(msg, line, skill, subject, $DB56)],
        'acts': [(actor, skill, target, $DB56)], 'text': [(bank, addr)], 'start': bool}."""
        p, m = self.p, self.m
        log = {'msgs': [], 'acts': [], 'text': [], 'start': False, 'est': []}

        def on_msg(_):
            log['msgs'].append((m[0xC823], m[WCUSTOMLINE], m[0xDB8A], m[0xDB89],
                                r16(m, 0xDB56)))

        def on_act(_):
            log['acts'].append((m[0xDB88], m[0xDB8A], m[0xDB89]))

        def on_text(_):
            log['text'].append((m[0xC824], m[0xC82D] | m[0xC82E] << 8, m[0xDB8A]))

        def on_est(_):
            log['est'].append(m[0xDB8A])
        regs = [(0x4C, 0x42D1, on_msg), self.sym['FarSkillFork'] + (on_act,),
                (0, 0x05E3, on_text), self.sym['AIDamageEstimate_538f'] + (on_est,)
                if 'AIDamageEstimate_538f' in self.sym else (0x52, 0x538F, on_est)]
        for (b, a), fn in (hooks or {}).items():
            regs.append((b, a, lambda _c, fn=fn: fn(log)))
        for b, a, fn in regs:
            p.hook_register(b, a, fn, None)
        m[0xDA03], m[0xDA04] = eid & 0xFF, eid >> 8
        m[0xDA02] = 0
        m[0xDA09] = 1
        m[0xC905] = 0
        m[0xC8EB] |= 0x40
        for i in range(frames):
            if m[GAME_MODE] == 2:
                ph = m[0xD9EC]
                if ph >= 1:
                    log['start'] = True
                m[0xC899], m[0xC89A] = 0x5A, 0xA5
                for k in range(3):
                    m[DCEC + 2 * k] = skill if k == caster else party
                if enemy is not None:
                    m[DCEC + 8] = enemy
                if paralyse:
                    for k in range(3):
                        m[0xDB04 + 8 * k] |= 0x40
                if 4 <= ph <= 6:
                    for k in range(3):
                        m[DCEC + 2 * k + 1] = target if k == caster else k
                    if enemy is not None and etarget is not None:
                        m[DCEC + 9] = etarget
                    w16(m, HP + 8, 999)
                    w16(m, MAXHP + 8, 999)
                    w16(m, MP + 8, 250)
                    if caster is not None:
                        w16(m, MP + 2 * caster, 200)
                    for k in range(3):
                        if m[0xDD1B + k] != 0xFF:
                            w16(m, HP + 2 * k, 900)
                            w16(m, MAXHP + 2 * k, 999)
                    if board:
                        board(m)
            if i % 8 < 4:
                p.button_press('a')
            else:
                p.button_release('a')
            p.tick()
            if len(log['msgs']) + len(log['acts']) + len(log['text']) + len(log['est']) > 4000:
                log['runaway'] = i                  # code looping through a hooked address
                break
        p.button_release('a')
        for b, a, _fn in regs:
            p.hook_deregister(b, a)
        return log


def twin_map(w):
    """{reclaimed id: its high twin}, {high: reclaimed}."""
    r2h = {w.R[n]: w.H[n] for n in w.R}
    return r2h, {v: k for k, v in r2h.items()}


def norm(seq, r2h):
    """A log's tuples with every reclaimed id written as its high twin."""
    return [tuple(r2h.get(x, x) if j == 2 else x for j, x in enumerate(t)) for t in seq]


def norm_acts(seq, r2h):
    return [(a, r2h.get(s, s), t) for a, s, t in seq]


# ------------------------------------------------------------------ steps
def s_gift(w):
    print('gift: the GIFT KEEPER')
    w.goto(w.rooms['hall'], 0, 5, 6)
    before = [(k, w.rec_byte(k, 0), w.rec_byte(k, 9), w.rec_byte(k, 0x29)) for k in range(20)]
    w.face('up')
    r = w.talk([True])
    w.idle()
    got = [[w.rec_byte(k, 0x29 + i) for i in range(4)] for k in range(20)
           if w.rec_byte(k, 0) in (1, 2)
           and (k, w.rec_byte(k, 0), w.rec_byte(k, 9), w.rec_byte(k, 0x29)) not in before]
    hs = [w.H[t] for t in ('Fireb', 'Infer', 'Antid', 'Multi')]
    rs = [w.R[t] for t in ('Fireb', 'Infer', 'Antid', 'Multi')]
    w.check('the GIFT KEEPER (YES) gives HIGHTWIN (HFireb / HInfer / HAntid / HMulti) and '
            'RECLTWIN (the R twins, ids 188 / 190 / 193 / 204)', hs in got and rs in got,
            f'{r}; new {got}')
    w.snap('gift')


def s_twins(w):
    print('twins: every pair cast by party slot 0 (one saved state, the RNG pinned)')
    r2h, _h2r = twin_map(w)
    st = io.BytesIO()
    w.p.save_state(st)
    tbl = rom_off(w.sym, 'CustomMsgPtrTable')
    romb = open(w.rom, 'rb').read()

    def row_ptr(k):
        return romb[tbl + 2 * k] | romb[tbl + 2 * k + 1] << 8

    def run(sk):
        st.seek(0)
        w.p.load_state(st)
        return w.battle(3, 2600, party=CURSE_ATTACK, enemy=CURSE_ATTACK, caster=0, skill=sk)
    for n in w.R:
        hi, re = w.H[n], w.R[n]
        a, b = run(hi), run(re)
        ah = [t for t in a['msgs']]
        bh = norm(b['msgs'], r2h)
        acted_a = sum(1 for x in a['acts'] if x[0] == 0 and x[1] == hi)
        acted_b = sum(1 for x in b['acts'] if x[0] == 0 and x[1] == re)
        w.check(f'H{n} (${hi:02X}) and R{n} (${re:02X}): {acted_a} / {acted_b} casts, the same '
                f'{len(ah)} battle messages (id, line, subject, number)',
                acted_a > 0 and acted_a == acted_b and ah == bh,
                '' if ah == bh else f'first difference at '
                f'{next((i for i, (x, y) in enumerate(zip(ah, bh)) if x != y), min(len(ah), len(bh)))}: '
                f'{ah[:12]} vs {bh[:12]}')
        if n == 'Fireb':
            ha = {ad for _b, ad, s in a['text'] if s == hi}
            ra = {ad for _b, ad, s in b['text'] if s == re}
            k = w.R[n] - 0xBC + 33
            w.check(f'HFireb / RFireb render their own announce lines (the text engine reads '
                    f'CustomMsgPtrTable row {hi - 0xDE} / row {k})',
                    row_ptr(hi - 0xDE) in ha and row_ptr(k) in ra
                    and row_ptr(hi - 0xDE) != row_ptr(k),
                    f'rows ${row_ptr(hi - 0xDE):04X} / ${row_ptr(k):04X}; read '
                    f'{sorted(hex(x) for x in ha)[:8]} / {sorted(hex(x) for x in ra)[:8]}')


STUB, MARK = 0xDE40, 0xDE3F          # the audio engine's free margin ($DE2C-$DE73)


def stub_call(w, bank, addr, c=None, maxf=120):
    """di / ld a,bank / ld [$2100],a / (ld c,n) / call addr / ld a,$A5 / ld [MARK],a / jr $
    from WRAM, in the live battle (the caller reloads its state afterwards). -> True when
    the routine returned."""
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


def forked(fn, timeout=60):
    """Run fn() (-> a JSON-able value) in a forked copy of this process (the emulator state
    and all); -> its value, or 'hung' when the copy does not finish in `timeout` s (a CPU
    lock-up inside PyBoy's tick cannot be interrupted from Python — the negative ROM's
    estimate jumps into code read as a pointer)."""
    import select
    import signal
    rfd, wfd = os.pipe()
    pid = os.fork()
    if pid == 0:                                        # the child
        os.close(rfd)
        try:
            out = json.dumps(fn())
        except Exception as e:                          # noqa: BLE001
            out = json.dumps(f'error {e!r}')
        os.write(wfd, out.encode())
        os._exit(0)
    os.close(wfd)
    r, _w, _x = select.select([rfd], [], [], timeout)
    if not r:
        os.kill(pid, signal.SIGKILL)
        os.waitpid(pid, 0)
        os.close(rfd)
        return 'hung'
    data = b''
    while True:
        chunk = os.read(rfd, 65536)
        if not chunk:
            break
        data += chunk
    os.close(rfd)
    os.waitpid(pid, 0)
    return json.loads(data.decode()) if data else 'hung'


def s_enemy(w):
    print('enemy: the enemy AI and its two id-range routines')
    r2h, _ = twin_map(w)
    m = w.m
    st = io.BytesIO()
    w.p.save_state(st)

    def run(eid, par):
        st.seek(0)
        w.p.load_state(st)

        def board(mm):
            if par:
                for k in range(3):
                    mm[0xDB02 + 8 * k] |= 0x40
        return w.battle(eid, 9000, party=DEFEND, board=board)
    # (1) the sparring rows in pairs, the AI free: the same battle
    for hi, re, what in (('high_slasher', 'recl_slasher', 'SLASHER'),
                         ('high_caster', 'recl_caster', 'CASTER')):
        for par in (False,):                 # (a party all paralysed loses the battle)
            a, b = run(w.eids[hi], par), run(w.eids[re], par)
            ea = [x for x in a['acts'] if x[0] >= 4]
            eb = norm_acts([x for x in b['acts'] if x[0] >= 4], r2h)
            new_a = sum(1 for x in ea if x[1] >= 0xEF)
            tag = ' (every party monster PARALYSED)' if par else ''
            w.check(f'HIGH vs RECL {what}{tag} (INT 200, the AI free): the same {len(ea)} enemy '
                    f'actions (actor, skill twin-mapped, target); new skills cast: {new_a} '
                    f'[ROADMAP E17: the AI casts no new skill, either kind]',
                    a['start'] and len(ea) > 4 and ea == eb,
                    f'{[(x[0], hex(x[1]), x[2]) for x in ea[:8]]} vs '
                    f'{[(x[0], hex(x[1]), x[2]) for x in eb[:8]]}')
    # (2) the routines themselves, called in a live battle (phase 4)
    st.seek(0)
    w.p.load_state(st)
    w.battle(w.eids['high_slasher'], 700, party=DEFEND)
    st2 = io.BytesIO()
    w.p.save_state(st2)
    b58, a58 = w.sym['SaveBtlFX_43ff']
    b57, a57 = w.sym['AIRule_4785']
    seen = []

    def est(sk):
        def run_():
            st2.seek(0)
            w.p.load_state(st2)
            m[0xDB8A], m[0xDB88], m[0xDB89] = sk, 0, 4
            m[0xDB56] = m[0xDB57] = 0xEE
            seen.clear()
            bh, ah = w.sym['AIDamageEstimate_538f']
            w.p.hook_register(bh, ah, lambda _c: len(seen) < 64 and seen.append(m[0xDB8A]), None)
            ok = stub_call(w, b58, a58, c=4)
            w.p.hook_deregister(bh, ah)
            return [ok, r16(m, 0xDB56), list(seen)]
        r = forked(run_)
        return tuple(r) if isinstance(r, list) else (False, None, [r])

    def veto(sk):
        def run_():
            st2.seek(0)
            w.p.load_state(st2)
            m[0xDB8A], m[0xDB88] = sk, 4
            m[0xDD27] = 0
            for k in range(3):
                m[0xDB02 + 8 * k] |= 0x40
            ok = stub_call(w, b57, a57)
            return [ok, m[0xDD27]]
        r = forked(run_)
        return tuple(r) if isinstance(r, list) else (False, r)
    for n in ('Beser', 'Evil', 'Squal', 'Psych', 'Whist'):
        hi, re = w.H[n], w.R[n]
        a, b = est(hi), est(re)
        w.check(f'the AI damage estimate (bank $58 SaveBtlFX_43ff -> bank $52 entry 3) of H{n} '
                f'(${hi:02X}) and R{n} (${re:02X}): both return, the same value',
                a[0] and b[0] and a[1] == b[1],
                f'H {a}, R {b}')
        w.check(f'… AIDamageEstimate_538f never reads R{n}\'s raw id (it would index past its '
                '28-row table)', b[0] and b[2] and not any(x in RECLAIMED for x in b[2]),
                f'$DB8A seen {[hex(x) if isinstance(x, int) else x for x in b[2]]}')
    sleep = veto(0x15)
    w.check('control — AIRule_4785, every opponent paralysed: the stock Sleep ($15) is VETOED '
            '($DD27 = $FF)', sleep == (True, 0xFF), str(sleep))
    for n in ('Sleep', 'Sap', 'Psych', 'Volt', 'Evil', 'Whist'):
        hi, re = w.H[n], w.R[n]
        a, b = veto(hi), veto(re)
        w.check(f'AIRule_4785, every opponent paralysed: H{n} (${hi:02X}) and R{n} '
                f'(${re:02X}) the same — not vetoed (a new skill; ${re:02X} lies in the stock '
                'veto range $88-$D9)', a[0] and b[0] and a == b == (True, 0), f'H {a}, R {b}')


def battle_menu_item(w, slot):
    """In a battle's first command menu: ITEM (FIGHT ITEM / PLAN RUN: right, A), the bag
    slot (4 a page), A, then US + the lead monster when it asks. -> True when the menu
    was reached."""
    p, m = w.p, w.m
    for _ in range(300):
        adv(p, 10)
        if m[GAME_MODE] == 2 and m[0xD9EC] == 4 and m[0xD9F4] == 2:    # FIGHT / ITEM up
            break
    else:
        return False
    adv(p, 60)
    tap(p, 'right', hold=6, wait=30)
    tap(p, 'a', hold=3, wait=60)
    for _ in range(slot // 4):
        tap(p, 'right', hold=8, wait=30)
    for _ in range(slot % 4):
        tap(p, 'down', hold=8, wait=30)
    tap(p, 'a', hold=3, wait=60)
    return True


def s_items(w):
    print('items: the field-only items in the battle ITEM menu and in the field')
    m, p = w.m, w.p
    st = io.BytesIO()
    w.p.save_state(st)
    r2h, h2r = twin_map(w)
    for item in (LIFEACORN, WARPWING, HERB):
        st.seek(0)
        w.p.load_state(st)
        for i in range(20):
            if m[BAG + i] in (0xFF, item):
                m[BAG + i] = item
                slot = i
                break
        n0 = sum(1 for i in range(20) if m[BAG + i] == item)
        msgs, acts = [], []

        def on_msg(_):
            msgs.append((m[0xC822], m[0xC823]))       # (mode, id): $F2 = the refusal

        def on_act(_):
            acts.append((m[0xDB88], m[0xDB8A]))
        b4, a4 = 0x4C, 0x42D1                         # the battle-message renderer ($F200)
        bf, af = w.sym['FarSkillFork']
        p.hook_register(b4, a4, on_msg, None)
        p.hook_register(bf, af, on_act, None)
        m[0xDA03], m[0xDA04] = 3, 0
        m[0xDA02] = 0
        m[0xDA09] = 1
        m[0xC905] = 0
        m[0xC8EB] |= 0x40
        reached = battle_menu_item(w, slot)
        m[0xDBA3], m[0xDBA4] = 1, 0                   # the lead monster hurt (a Herb has work)
        w.snap(f'item_{item}')
        tap(p, 'a', hold=3, wait=60)                  # US (when it asks)
        tap(p, 'a', hold=3, wait=60)                  # the lead monster
        for _ in range(60):
            adv(p, 10)
        p.hook_deregister(b4, a4)
        p.hook_deregister(bf, af)
        refused = any(x[1] == 0xF2 for x in msgs)
        hero = [(a, s) for a, s in acts if s in RECLAIMED or s in (0xB0, 0xBC, 0xCC)]
        n1 = sum(1 for i in range(20) if m[BAG + i] == item)
        if item == HERB:
            w.check('control — a Herb in the battle ITEM menu: accepted (no "Can\'t use…"), '
                    'one used', reached and not refused and n1 == n0 - 1,
                    f'msgs {[hex(b) for _a, b in msgs[:8]]}, bag {n0}->{n1}')
        else:
            nm = 'LifeAcorn' if item == LIFEACORN else 'WarpWing'
            sid = item + 0xAF
            w.check(f'{nm} (battle id ${sid:02X} = {"RFireb" if item == LIFEACORN else "RMulti"} '
                    'now) in the battle ITEM menu: "Can\'t use this item in battle!" ($F2), '
                    'no skill acts, the bag keeps it',
                    reached and refused and not hero and n1 == n0,
                    f'msgs {[hex(b) for _a, b in msgs[:8]]}, acts {hero[:4]}, bag {n0}->{n1}')
    # the field: the LifeAcorn as always
    st.seek(0)
    w.p.load_state(st)
    w.goto(w.rooms['hall'], 0, 5, 1)
    w.face('up')
    for i in range(20):
        if m[BAG + i] in (0xFF, LIFEACORN):
            m[BAG + i] = LIFEACORN
            slot = i
            break
    lead = REC + RECSZ * m[PARTY_LIST]
    hp0 = r16(m, lead + 0x52)
    n0 = sum(1 for i in range(20) if m[BAG + i] == LIFEACORN)
    tap(p, 'a', hold=3, wait=90)
    tap(p, 'right', hold=8, wait=40)
    tap(p, 'a', hold=3, wait=60)                          # ITEM
    for _ in range(slot // 5):
        tap(p, 'right', hold=8, wait=30)
    for _ in range(slot % 5):
        tap(p, 'down', hold=8, wait=20)
    tap(p, 'a', hold=3, wait=60)                          # USE / DEL
    tap(p, 'a', hold=3, wait=60)                          # USE
    tap(p, 'a', hold=3, wait=60)                          # the lead monster
    for _ in range(6):
        adv(p, 40)
        tap(p, 'a', hold=3, wait=20)
    w.snap('field_lifeacorn')
    for _ in range(6):
        tap(p, 'b', hold=3, wait=30)
    w.idle()
    hp1 = r16(m, lead + 0x52)
    n1 = sum(1 for i in range(20) if m[BAG + i] == LIFEACORN)
    w.check('the field: the LifeAcorn raises the lead monster\'s max HP (used up) — its field '
            'effect untouched', hp1 > hp0 and n1 == n0 - 1, f'max HP {hp0}->{hp1}, bag {n0}->{n1}')


def s_learn(w):
    print('learn: a level up teaches HFireb + RFireb, never HBang / RBang (two prereqs)')
    m = w.m
    k = m[PARTY_LIST + 2]
    w.set_rec(k, 0x29, BLAZEMOST)
    w.set_rec(k, 0x2A, FIREBOLT)
    for i in range(2, 8):
        w.set_rec(k, 0x29 + i, 0xFF)
    w16(m, REC + RECSZ * k + 0x5E, 950)                   # INT (the learn rows ask 900)
    lv0 = w.rec(k, 0x4B)
    xp0 = w.rec(k, 0x4D) | w.rec(k, 0x4E) << 8 | w.rec(k, 0x4F) << 16
    w.goto(w.rooms['hall'], 0, 18, 6)                     # screen 1 (8, 5), from below
    w.face('up')
    r = w.talk([True])
    won = w.battle_won() if r == 'battle' else False
    w.idle()
    sk = [w.rec(k, 0x29 + i) for i in range(8)]
    lv1 = w.rec(k, 0x4B)
    xp1 = w.rec(k, 0x4D) | w.rec(k, 0x4E) << 8 | w.rec(k, 0x4F) << 16
    w.snap('learn')
    w.check('the TRAINING DUMMY beaten: party slot 2 levelled up', r == 'battle' and lv1 > lv0,
            f'{r}, won {won}, level {lv0}->{lv1}, exp {xp0}->{xp1}')
    w.check(f'it learned HFireb (${w.H["Fireb"]:02X}) AND RFireb (${w.R["Fireb"]:02X}) — one '
            'prerequisite each (Blazemost / Firebolt)', w.H['Fireb'] in sk and w.R['Fireb'] in sk,
            str([hex(s) for s in sk]))
    w.check(f'never HBang (${w.H["Bang"]:02X}) / RBang (${w.R["Bang"]:02X}) — two '
            'prerequisites (Blazemost + Firebolt): fenced for both kinds',
            w.H['Bang'] not in sk and w.R['Bang'] not in sk, str([hex(s) for s in sk]))


def s_freeze(w):
    print('freeze: two skills evolving from ONE skill (the compiler warns) — measured')
    rom = bytearray(open(w.rom, 'rb').read())
    o = 0x06 * 0x4000 + 0x50E0 - 0x4000 + 18 * w.R['Fireb'] + 13
    rom[o] = BLAZEMOST                                   # RFireb from Blazemost, as HFireb
    alt = os.path.join(w.keep, 'walk_freeze.gbc')
    open(alt, 'wb').write(rom)
    keep_rom, w.rom = w.rom, alt
    try:
        w.start('start')
        m, p = w.m, w.p
        k = m[PARTY_LIST + 2]
        w.set_rec(k, 0x29, BLAZEMOST)
        for i in range(1, 8):
            w.set_rec(k, 0x29 + i, 0xFF)
        w16(m, REC + RECSZ * k + 0x5E, 950)
        w.goto(w.rooms['hall'], 0, 18, 6)
        w.face('up')
        r = w.talk([True])
        back = w.battle_won(maxf=12000) if r == 'battle' else False
        w.snap('freeze')
        w.check('HFireb and RFireb both from Blazemost (ROM copy): the level up never ends — '
                'the learn step offers the second forever (the warning is real)',
                r == 'battle' and not back and m[GAME_MODE] == 2,
                f'{r}, back to the field {back}, level {w.rec(k, 0x4B)}, skills '
                f'{[hex(w.rec(k, 0x29 + i)) for i in range(4)]}')
    finally:
        w.rom = keep_rom


# ------------------------------------------------------------------ negative
def negative_rom(w):
    rom = bytearray(open(w.rom, 'rb').read())
    sym = w.sym
    rom[rom_off(sym, 'ReclaimBase72')] = 0xC9                      # ret: the id unchanged
    o = rom_off(sym, 'ReclaimLine4C')
    rom[o:o + 2] = b'\x37\xC9'                                     # scf / ret: stock $FD
    o = rom_off(sym, 'SaveBtlFX_43ff')
    k = rom.find(bytes([0xCD]) + bytes([sym['FxEstimate58'][1] & 0xFF,
                                        sym['FxEstimate58'][1] >> 8]) + b'\x00', o, o + 0x40)
    if k < 0:
        raise SystemExit('SaveBtlFX_43ff: no `call FxEstimate58 / nop`')
    rom[k:k + 4] = b'\x21\x03\x52\xD7'                             # ld hl,$5203 / rst $10
    o = rom_off(sym, 'SkillView57')
    rom[o + 3:o + 4] = b'\xC9'                                     # ld a,[$db8a] / ret
    o = rom_off(sym, 'ReclaimedSkill77')
    rom[o:o + 2] = b'\xA7\xC9'                                     # and a / ret: never
    o = rom_off(sym, 'LearnFence06')
    k = rom.find(b'\xD8', o, o + 8)                                # the first `ret c` ($DA+)
    rom[k + 1] = 0xC9                                              # then: open
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print('NEGATIVE CONTROL: ReclaimBase72 / ReclaimLine4C return at once, FxEstimate58 = the '
          'original estimate call, SkillView57 = $DB8A raw, ReclaimedSkill77 never, LearnFence06 '
          '= custom $DA+ only')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--steps', default='gift,twins,enemy,items,learn,freeze')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = ReclaimWalk(a.build, a.sav, a.keep)
    d = json.load(open(a.project))
    ids = {r['id']: int(r['mapID'], 16) for r in d['custom']['rooms']}
    w.rooms = {'hall': ids['twin_hall']}
    from editor2.core.project import Project
    prj = Project(d, os.path.dirname(os.path.abspath(a.project)))
    prj.repo_root = REPO
    w.eids = {e['id']: e['_eid'] for e in prj.quest_enemy_rows()}
    sk = d['gamedata']['skills']
    names = {v['name']: int(k) for k, v in sk.items() if isinstance(v, dict) and v.get('name')}
    w.H = {n[1:]: i for n, i in names.items() if n[0] == 'H' and i >= 0xEF}
    w.R = {n[1:]: i for n, i in names.items() if n[0] == 'R' and i in RECLAIMED}
    if a.negative:
        negative_rom(w)
    s_continue(w)
    w.save('start')
    steps = {'gift': s_gift, 'twins': s_twins, 'enemy': s_enemy, 'items': s_items,
             'learn': s_learn, 'freeze': s_freeze}
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
