#!/usr/bin/env python3
"""walk_skills.py — S155: the new built-in custom skills (Repel, LoneWolf, Punish,
Finish, Rupture, Blunt — "Rust" until S155 r3; the labels keep Rust) on the real game
(PyBoy on the user's .sav).

The demo (examples/s155_dojo_demo/build_demo.py) = the user's project + THE WOLF DOJO
(gift monsters, a farm keeper, three sparring bosses) + THE WOLF DEN (random battles).

  gift     the GIFT MASTER (YES) gives LONEWOLF (LoneWolf / Punish / Finish /
           Rupture), (NO, YES) BLUNTER (Blunt / Repel / PoisonHit / Surge): the records
           carry the skills;
  numbers  forced battles (the S110 rig: the queue written each frame, the RNG pinned,
           the foe's HP held) on a slot-1 caster: the handler's $DB56 before / after,
           the bonus line (wCustomLine, rendered in the announce slot BEFORE the attack
           animation starts — S155 r2) and the hit's own message, the damage sound on
           its frame (bank $55 entry 2) — LoneWolf in a party of
           two x2, an enemy alone x4; Punish x1 / x2 (two buffs); Finish at full HP
           (x0.2, at least 1) / at 100 of 999 HP (x1.8); Rupture x3 on a poisoned foe
           (the poison cleared) / "But nothing happens!" ($BB) without one; Blunt -9 ATK
           twice then $BB at ATK 1; DeMagic and Surge put the ATK back;
           Tremor turning on its own side: the "allies are caught" banner first, the
           ally's damage sound with its "receives" text (S155 r2);
           [S155 r3] the line on EVERY cast (CustomLineAlways, the default; with
           --line-bonus the ROM copy has it 0: only with the bonus, the r2 behaviour);
           a poisoned foe's tick: the stock $FD render after it (LoadB4c_Fork_stockfd)
           reads the vanilla empty string (it showed MagicBurn's line until S155 r3);
  bosses   the three sparring bosses (a conversation battle, INT 200): the LONE WOLF
           casts LoneWolf alone (x4 line), the BURSTER bursts the VIPER's poison
           (Rupture on a poisoned party slot), the BLUNT KNIGHT blunts;
  repel    THE WOLF DEN: battles without Repel; Repel cast from the field menu: the
           Repellant flag ($C93E bit 1) set, 4 MP spent, no battle in 150 steps; a
           second cast fizzles (MP kept); out to the dojo (the flag cleared) and back:
           battles again; in Cities_FOUNT (no battles) it fizzles, no MP spent;
  noskill  [S155 r4] the real menus in the VIPER + BURSTER battle: PX DEF, HL ATK with the
           cursor on the BURSTER, B, HL SKIL -> "HL doesn't have any skill" (the original
           game printed the foe's name: $C180 held the target list's last name).

  python3 tools/walk_skills.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative] [--line-bonus]

--negative: the ROM copy without the S155 effects (the five bank $72 handlers,
CustomAIRule72 and SlashLine72 return at once — the damage roll stays, a plain hit —,
AnchorField14Tail's `cp ID_REPEL` never matches and the $4019[$FD] row names MagicBurn's
line again, the pre-r3 bug): the S155 effect checks must FAIL
(the gifts, the casts the bosses' AI still makes and the den's battles without Repel pass).
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import io
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, GAME_MODE, MAP_ID, PARTY_SLOT0  # noqa: E402
from tools.walk_regions import Walk, s_continue                           # noqa: E402

REPEL, LONEWOLF, PUNISH, FINISH, RUPTURE, RUST = 0xDE, 0xDF, 0xEB, 0xEC, 0xED, 0xEE
POISONHIT, SURGE, DEMAGIC, CURSE_ATTACK = 0x67, 0x81, 0x80, 0x93
DCEC = 0xDCEC
HP, MAXHP, MP, ATK = 0xDBA3, 0xDBB3, 0xDBC3, 0xDBE3
REC = 149                                   # a monster record (PARTY_SLOT0 + 149 k)
REPELLANT = 0xC93E                          # bit 1 (bank $16 label16_6f05)
WCUSTOMLINE = 0xDEC0


def w16(m, a, v):
    m[a] = v & 0xFF
    m[a + 1] = v >> 8


def r16(m, a):
    return m[a] | m[a + 1] << 8


class SkillWalk(Walk):
    def rig(self, caster, skill, target, ecount=1, frames=2600, board=None, handlers=(),
            others=CURSE_ATTACK, ehp=999, pin=True, free_enemies=False, party_hp=None,
            sched=None):
        """A forced battle (census_skill_present's S110 recipe): wild battle of EID 3,
        every actor's skill byte written each frame, targets / HP in phases 4-6.
        Returns {'msgs': [(msg, wCustomLine, skill, subject, $DB56)], 'hand': [(label,
        attacker, target, $DB56)], 'acts': n, 'atk': [ATK x8 per phase 9]}."""
        p, m = self.p, self.m
        log = {'msgs': [], 'hand': [], 'acts': 0, 'atk': []}

        log['ev'] = []

        def on_msg(_):
            log['msgs'].append((m[0xC823], m[WCUSTOMLINE], m[0xDB8A], m[0xDB89],
                                r16(m, 0xDB56)))
            log['ev'].append((p.frame_count, 'msg', m[0xC823], m[WCUSTOMLINE], m[0xDB8A],
                              m[0xD9EE], r16(m, 0xDB56)))
        p.hook_register(0x4C, 0x42D1, on_msg, None)

        def on_vis(_):
            log['ev'].append((p.frame_count, 'vis', m[0xDB8A], m[0xD9EE]))

        def on_snd(_):
            log['ev'].append((p.frame_count, 'snd', m[0xDB8A], m[0xD9EE]))
        p.hook_register(0x5F, 0x52F0, on_vis, None)        # bank $5F entry 6: a visual
        p.hook_register(0x55, 0x4035, on_snd, None)        # bank $55 entry 2: the damage sound
        for h in handlers:
            b, a = self.sym[h]

            def cb(_ctx, h=h):
                log['hand'].append((h, m[0xDB88], m[0xDB89], r16(m, 0xDB56)))
            p.hook_register(b, a, cb, None)
        m[0xDA03], m[0xDA04] = 3, 0
        m[0xDA02] = (ecount - 1) & 3
        for k in range(1, ecount):
            m[0xDA03 + 2 * k], m[0xDA04 + 2 * k] = 3, 0
        m[0xDA09] = 1
        m[0xC905] = 0
        m[0xC8EB] |= 0x40
        prev = None
        nact = 0
        prevph = None
        for i in range(frames):
            if sched:
                skill = sched[min(nact, len(sched) - 1)]
            if m[GAME_MODE] == 2:
                ph = m[0xD9EC]
                if pin:
                    m[0xC899], m[0xC89A] = 0x5A, 0xA5
                for k in range(3):
                    m[DCEC + 2 * k] = skill if k == caster else others
                if not free_enemies:
                    for s in range(ecount):
                        m[DCEC + 8 + 2 * s] = skill if caster == 4 + s else others
                if 4 <= ph <= 6:
                    for k in range(3):
                        m[DCEC + 2 * k + 1] = target if k == caster else k
                    for s in range(ecount):
                        if not free_enemies:
                            m[DCEC + 9 + 2 * s] = target if caster == 4 + s else 4 + s
                        if ehp is not None:
                            w16(m, HP + 8 + 2 * s, ehp)
                            w16(m, MAXHP + 8 + 2 * s, 999)
                    w16(m, MP + 2 * caster, 200)
                    if party_hp is not None:
                        for k in range(3):
                            if m[0xDD1B + k] != 0xFF:
                                w16(m, HP + 2 * k, party_hp)
                                w16(m, MAXHP + 2 * k, 999)
                    if board:
                        board(m)
                cur = (ph, m[0xD9ED], m[0xDB8A], m[0xDB88])
                if cur[0] == 7 and cur[1] == 1 and cur[2] == skill and prev != cur:
                    log['acts'] += 1
                if ph == 9 and prevph != 9:
                    nact += 1
                    log['atk'].append(tuple(r16(m, ATK + 2 * s) for s in range(8)))
                prevph = ph
                prev = cur
            if i % 8 < 4:
                p.button_press('a')
            else:
                p.button_release('a')
            p.tick()
        p.button_release('a')
        p.hook_deregister(0x4C, 0x42D1)
        p.hook_deregister(0x5F, 0x52F0)
        p.hook_deregister(0x55, 0x4035)
        for h in handlers:
            b, a = self.sym[h]
            p.hook_deregister(b, a)
        return log

    def rec_byte(self, k, off):
        """Monster slot k's record byte: slots 0-2 in WRAM ($CAC1 + 149 k), 3-19 in SRAM
        bank 0 from $A3BA (S60 CF3, known_RAM_map)."""
        if k < 3:
            return self.m[PARTY_SLOT0 + REC * k + off]
        return self.p.memory[0, 0xA3BA + REC * (k - 3) + off]

    def records(self):
        out = []
        for k in range(20):
            f = self.rec_byte(k, 0)
            if f in (1, 2):
                out.append((k, f, [self.rec_byte(k, 0x29 + i) for i in range(8)]))
        return out


H = ['SkillLoneWolf', 'SkillPunish', 'SkillFinish', 'SkillRupture', 'SkillRust']


def roll_and_after(w, log, skill):
    """(the handler's input $DB56, the hit message's number, the hit message id, line)."""
    hb = [h[3] for h in log['hand']]
    fd = [(a, b, e) for a, b, c, d, e in log['msgs'] if c == skill and a not in (0x5D, 0x23)]
    return (hb[0] if hb else None), (fd[0] if fd else None)


def beats(log, skill):
    """[S155 r2] the first action of `skill`: the handler's input $DB56 (roll), the
    bonus line (wCustomLine of the $FD render in the announce slot, d9ee 3) and its
    frame, the attack animation's start (bank $5F entry 6 in d9ee 5), the hit
    message after it (id, number, frame) and the damage sound's frame (bank $55
    entry 2)."""
    out = {'roll': None, 'line': 0, 'line_f': None, 'slash_f': None, 'hit': None,
           'hit_f': None, 'snd_f': None}
    hb = [h[3] for h in log['hand']]
    out['roll'] = hb[0] if hb else None
    for e in log['ev']:
        f, kind = e[0], e[1]
        if kind == 'msg' and e[4] == skill and e[2] == 0xFD and e[5] == 3 and out['line_f'] is None \
                and out['hit'] is None:
            out['line'], out['line_f'] = e[3], f
        elif kind == 'vis' and e[2] == skill and e[3] == 5 and out['slash_f'] is None:
            out['slash_f'] = f
        elif kind == 'snd' and e[2] == skill and out['snd_f'] is None:
            out['snd_f'] = f
        elif kind == 'msg' and e[4] == skill and e[5] == 16 and out['hit'] is None:
            out['hit'], out['hit_f'] = (e[2], e[6]), f
    return out


def order_ok(bt):
    """The line (if any) before the attack animation; the damage sound with the hit's text."""
    return ((bt['line_f'] is None or (bt['slash_f'] is not None and bt['line_f'] < bt['slash_f']))
            and bt['snd_f'] is not None and bt['hit_f'] is not None
            and abs(bt['hit_f'] - bt['snd_f']) <= 1)


def s_gift(w):
    print('gift: the GIFT MASTER')
    mid = w.rooms['dojo']
    w.goto(mid, 0, 5, 6)
    before = w.records()
    w.face('up')
    r = w.talk([True])
    w.idle()
    after = w.records()
    new = [x for x in after if x not in before]
    w.check('the GIFT MASTER (YES) gives LONEWOLF with LoneWolf / Punish / Finish / Rupture',
            any(x[2][:4] == [LONEWOLF, PUNISH, FINISH, RUPTURE] for x in new),
            f'{r}; new {[(k, f, [hex(s) for s in sk[:4]]) for k, f, sk in new]}')
    w.face('up')
    w.talk([False, True])
    w.idle()
    new2 = [x for x in w.records() if x not in after]
    w.check('(NO, YES) gives RUSTER with Rust / Repel / PoisonHit / Surge',
            any(x[2][:4] == [RUST, REPEL, POISONHIT, SURGE] for x in new2),
            f'new {[(k, f, [hex(s) for s in sk[:4]]) for k, f, sk in new2]}')
    w.snap('gift')


def s_numbers(w):
    print('numbers: forced battles (the RNG pinned)')
    st = io.BytesIO()
    w.p.save_state(st)

    def run(sk, caster, tgt, **kw):
        st.seek(0)
        w.p.load_state(st)
        return w.rig(caster, sk, tgt, handlers=H, others=CURSE_ATTACK, **kw)

    # LoneWolf: party of two (the save's party) x2; an enemy alone x4. [S155 r2] the
    # line comes BEFORE the attack (the announce slot), the hit keeps the game's own
    # message, the damage sound on its frame
    def chk(what, bt, line, mult, plain=None):
        r = bt['roll']
        want = (plain(r) if plain else min(999, r * mult // 100)) if r is not None else None
        good = (r is not None and bt['hit'] is not None and bt['hit'][0] != 0xFD
                and bt['hit'][1] == want and bt['line'] == line and order_ok(bt))
        w.check(what, good, f"roll {r}, line {bt['line']} @{bt['line_f']}, slash @"
                f"{bt['slash_f']}, hit {bt['hit']} @{bt['hit_f']}, sound @{bt['snd_f']}")
    chk('LoneWolf, a party of two: line 1 before the attack, the hit x2 with its sound',
        beats(run(LONEWOLF, 1, 4), LONEWOLF), 1, 200)
    chk('LoneWolf, an enemy alone: line 1 first, x4, the sound with "receives"',
        beats(run(LONEWOLF, 4, 0), LONEWOLF), 1, 400)
    # Punish: no buff x1 (the line only when CustomLineAlways has it — S155 r3);
    # Bounce + Barrier on the foe = 2 buffs x2
    al = w.line_always
    chk(f'Punish, no buff: {"line 2 first (every cast)" if al & 2 else "no line"}, x1',
        beats(run(PUNISH, 1, 4), PUNISH), 2 if al & 2 else 0, 100)

    def two_buffs(m):
        m[0xDB04 + 8 * 4] |= 0x06
    chk('Punish, two buffs: line 2 first, x2 (50 % each)',
        beats(run(PUNISH, 1, 4, board=two_buffs), PUNISH), 2, 200)
    # Finish: full HP x0.2 (at least 1, no line); 100 of 999 HP x1.8
    chk(f'Finish at full HP: {"line 3 first (every cast)" if al & 4 else "no line"}, x0.2, '
        'at least 1', beats(run(FINISH, 1, 4), FINISH), 3 if al & 4 else 0,
        20, plain=lambda r: max(1, r * 20 // 100))
    chk('Finish at 100 / 999 HP: line 3 first, x1.8', beats(run(FINISH, 1, 4, ehp=100), FINISH),
        3, 180)
    # Rupture: poisoned + StopSpell -> x3, both gone; nothing -> $BB
    seen = []

    def poison(m):
        if not seen:
            m[0xDB02 + 8 * 4] |= 0x01
            m[0xDB03 + 8 * 4] |= 0x01
            seen.append(1)
    chk('Rupture on a poisoned + StopSpelled foe: line 4 first, x3',
        beats(run(RUPTURE, 1, 4, board=poison), RUPTURE), 4, 300)
    w.check('… and the ailments are gone after it',
            (w.m[0xDB02 + 8 * 4], w.m[0xDB03 + 8 * 4] & 0xC3) == (0, 0),
            f'+2 ${w.m[0xDB02 + 8 * 4]:02X} +3 ${w.m[0xDB03 + 8 * 4]:02X}')
    lg = run(RUPTURE, 1, 4)
    fails = [a for a, _b, c, *_r in lg['msgs'] if a == 0xBB and c == RUPTURE]
    bt = beats(lg, RUPTURE)
    w.check('Rupture without an ailment: "But nothing happens!" ($BB)'
            + (', its line first (every cast)' if al & 8 else ''),
            bool(fails) and bt['line'] == (4 if al & 8 else 0),
            f"msgs {[hex(a) for a, *_r in lg['msgs'][:10]]}, line {bt['line']}")
    # [S155 r3] the poison tick: a poisoned foe loses HP ($E1), then the game renders a
    # stock $FD (LoadB4c_Fork_stockfd -> the $4019 table's $FD row) — the vanilla empty
    # string; it named MagicBurn's line S2d-S155 r2 ("… burns half its MP!")
    fd = []
    b_, a_ = w.sym['LoadB4c_Fork_stockfd']

    def on_fd(_c):
        ptr = w.p.memory[0x4C, 0x4213] | w.p.memory[0x4C, 0x4214] << 8
        fd.append((m[0xDB8A], ptr, w.p.memory[0x4C, ptr]))
    m = w.m
    w.p.hook_register(b_, a_, on_fd, None)

    def poison_foe(mm):
        mm[0xDB02 + 8 * 4] |= 0x01
    lg = run(LONEWOLF, 1, 4, frames=3600, board=poison_foe)
    w.p.hook_deregister(b_, a_)
    ticks = [a for a, *_r in lg['msgs'] if a == 0xE1]
    w.check('the poison tick ($E1), then the stock $FD: the empty string (not MagicBurn\'s line)',
            ticks and fd and all(c == 0xF0 for _s, _p, c in fd),
            f'ticks {len(ticks)}, stock $FD renders {[(hex(s_), hex(p_), hex(c)) for s_, p_, c in fd[:4]]}')
    # [S155 r2] the older custom skills follow the same rule: Tremor's sweep turning
    # on its own side shows the "allies are caught" banner FIRST, then the ally's damage
    # sound + shake land with its "receives … damage" text (were under the banner)
    lg = run(0xE5, 1, 4, frames=3200)
    ev = [e for e in lg['ev'] if (e[1] == 'msg' and e[4] == 0xE5) or (e[1] == 'snd' and e[2] == 0xE5)]
    ban = next((e[0] for e in ev if e[1] == 'msg' and e[2] == 0xFD and e[5] == 15), None)
    ally = next((e[0] for e in ev if e[1] == 'msg' and e[2] == 0x83), None)
    snds = [e[0] for e in ev if e[1] == 'snd']
    w.check('Tremor: the allies banner first, the ally\'s damage sound with its "receives" text',
            ban is not None and ally is not None and ban < ally
            and any(abs(f - ally) <= 1 for f in snds) and not any(ban <= f < ally - 1 for f in snds),
            f'banner @{ban}, ally hit @{ally}, sounds {snds}')
    # Blunt (Rust): the enemy's ATK -9 once (half its base 19); [S155 r5] it does NOT
    # stack (the user: "MadKnight cast blunt like 6 times in a row … Blunt should NOT
    # stack"): every later Blunt on it is "But nothing happens!" ($BB), ATK stays 10
    lg = run(RUST, 1, 4, frames=5200, board=lambda m: m.__setitem__(0xDD2B + 7 * 4,
                                                                      m[0xDD2B + 7 * 4] & 0xCF))
    lost = [e for a, b_, c, d, e in lg['msgs'] if a == 0xFD and b_ == 5]
    bb = [a for a, _b, c, *_r in lg['msgs'] if a == 0xBB and c == RUST]
    w.check('Blunt: the foe loses ATK once (line 5, the amount = the ATK lost); the next ones '
            '$BB (no stacking), ATK stays 10',
            lost == [9] and len(bb) >= 2 and r16(w.m, ATK + 8) == 10, f'lost {lost}, $BB {len(bb)}, '
            f'ATK now {r16(w.m, ATK + 8)}')
    # DeMagic / Surge put a blunted ATK back: slot 1 blunts the foe (DeMagic: all foes)
    # or its own ally slot 0 (Surge: an ally) twice (the second fails), the cure, then
    # Blunt again — it lands (the slot is no longer blunted, S155 r5)
    for nm, fix, tgt in (('DeMagic', DEMAGIC, 4), ('Surge', SURGE, 0)):
        def nores(m, t=tgt):
            m[0xDD2B + 7 * t] &= 0xCF
        st.seek(0)
        w.p.load_state(st)
        lg = w.rig(1, RUST, tgt, frames=8000, handlers=H, others=CURSE_ATTACK, board=nores,
                   sched=[RUST, RUST, fix, RUST, fix], party_hp=900)
        seq = [a[tgt] for a in lg['atk']]
        w.check(f'{nm} puts a blunted ATK back (slot {tgt}); Blunt does not stack before it '
                'and lands again after it',
                len(seq) >= 4 and seq[0] < seq[2] and seq[1] == seq[0] and seq[3] < seq[2],
                f'ATK after each round {seq[:6]}')


def boss_battle(w, x, y, frames, hooks, keep_alive=True, above=False):
    """Talk to the sparring boss at (x, y) of dojo screen 1 (from below, or from above
    when the row below is the wall), YES; the battle runs with A presses (the party
    fights), HP held; hooks: {label: fn}."""
    mid = w.rooms['dojo']
    w.goto(mid, 0, 10 + x, y - 1 if above else y + 1)
    w.face('down' if above else 'up')
    r = w.talk([True])
    if r != 'battle':
        return r
    p, m = w.p, w.m
    for lab, fn in hooks.items():
        b, a = w.sym[lab]
        p.hook_register(b, a, fn, None)
    for i in range(frames):
        if m[GAME_MODE] == 2 and keep_alive and 4 <= m[0xD9EC] <= 6:
            for k in range(3):
                if m[0xDD1B + k] == 0:
                    w16(m, HP + 2 * k, 400)
                    w16(m, MAXHP + 2 * k, 999)
            for s in range(3):
                if m[0xDD1B + 4 + s] == 0 and r16(m, HP + 8 + 2 * s) < 150:
                    w16(m, HP + 8 + 2 * s, 300)
        if i % 8 < 4:
            p.button_press('a')
        else:
            p.button_release('a')
        p.tick()
    p.button_release('a')
    for lab in hooks:
        b, a = w.sym[lab]
        p.hook_deregister(b, a)
    w.battle_won()
    w.idle()
    return 'battle'


def s_bosses(w):
    print('bosses: the three sparring battles (the enemy AI, INT 200)')
    m = w.m
    got = []
    lines = []

    def lw(_c):
        got.append((m[0xDB88], m[0xDB89]))

    def line(_c):
        lines.append((m[0xC823], m[WCUSTOMLINE]))
    r = boss_battle(w, 3, 2, 9000, {'SkillLoneWolf': lw})
    w.check('the LONE WOLF battle starts (YES)', r == 'battle', r)
    w.check('the LONE WOLF (alone, slot 4) casts LoneWolf', any(a == 4 for a, _t in got),
            f'casts {got[:6]}')
    rup = []

    def ru(_c):
        t = m[0xDB89]
        rup.append((m[0xDB88], t, m[0xDB02 + 8 * t], m[0xDB03 + 8 * t] & 0xC3))
    r = boss_battle(w, 6, 4, 14000, {'SkillRupture': ru})
    w.check('the VIPER + BURSTER battle starts', r == 'battle', r)
    w.check('the BURSTER (slot 5) casts Rupture on a party monster with an ailment',
            any(a == 5 and t < 3 and (s2 or s3) for a, t, s2, s3 in rup), f'casts {rup[:6]}')
    rus = []

    def rs(_c):
        rus.append((m[0xDB88], m[0xDB89], r16(m, ATK + 2 * (m[0xDB89] & 7))))
    r = boss_battle(w, 3, 6, 9000, {'SkillRust': rs}, above=True)
    w.check('the BLUNT KNIGHT battle starts', r == 'battle', r)
    w.check('the BLUNT KNIGHT (slot 4) casts Blunt on a party monster', any(
        a == 4 and t < 3 for a, t, _x in rus), f'casts {rus[:6]}')
    first = {}
    for _a, t, x in rus:
        first.setdefault(t, x)
    w.check('[S155 r5] the BLUNT KNIGHT never casts Blunt on a monster it already blunted',
            rus and all(x == first[t] for _a, t, x in rus), f'casts {rus[:8]}')


def walk_battles(w, n):
    """n steps back and forth; -> the battles met (each won at once)."""
    m = w.m
    k = 0
    for i in range(n):
        d = ('left', 'right', 'up', 'down')[(i // 3) % 4]
        w.step(d)
        if m[GAME_MODE] == 2:
            k += 1
            w.battle_won()
            w.idle()
    return k


def field_cast(w, slot0_skill=REPEL):
    """Party monster 0's first skill := Repel (MP 50), cast from the field menu
    (A, down, A = SKILL, A = the monster, A = the skill). -> MP before / after."""
    m = w.m
    rec = PARTY_SLOT0 + REC * m[0xCA8E]
    m[rec + 0x29] = slot0_skill
    mp0 = r16(m, rec + 0x54)
    if mp0 < 20:
        w16(m, rec + 0x54, 50)
        mp0 = 50
    tap(w.p, 'a', hold=3, wait=90)
    tap(w.p, 'down', hold=8, wait=40)
    tap(w.p, 'a', hold=3, wait=60)
    tap(w.p, 'a', hold=3, wait=60)
    tap(w.p, 'a', hold=3, wait=60)
    for _ in range(6):
        adv(w.p, 30)
    for _ in range(5):
        tap(w.p, 'b', wait=30)
    w.idle()
    return mp0, r16(m, rec + 0x54)


def s_repel(w):
    print('repel: THE WOLF DEN')
    m = w.m
    den, dojo = w.rooms['den'], w.rooms['dojo']
    w.goto(den, 0, 5, 5)
    m[REPELLANT] &= ~0x02
    w.check('the WOLF DEN: battles without Repel', walk_battles(w, 90) > 0)
    w.goto(den, 0, 5, 5)
    mp0, mp1 = field_cast(w)
    w.snap('repel_cast')
    w.check('Repel cast in the den: the Repellant flag set, 4 MP spent',
            m[REPELLANT] & 0x02 and mp0 - mp1 == 4, f'$C93E {m[REPELLANT]:02X}, MP {mp0}->{mp1}')
    n = walk_battles(w, 150)
    w.check('… no battle in 150 steps', n == 0, f'{n} battles')
    mp2, mp3 = field_cast(w)
    w.check('a second cast fizzles (MP kept)', mp2 == mp3, f'MP {mp2}->{mp3}')
    w.goto(den, 0, 2, 3)
    w.face('up')
    r = w.talk([True])
    w.idle()
    w.check('the DEN KEEPER (YES) -> the dojo; the Repellant flag cleared on arrival',
            m[MAP_ID] == dojo and not m[REPELLANT] & 0x02, f'{r}, map ${m[MAP_ID]:02X}, '
            f'$C93E {m[REPELLANT]:02X}')
    w.goto(dojo, 0, 25, 5)
    w.face('up')
    r = w.talk([True])
    w.idle()
    w.check('the DEN GUIDE (YES) -> the den; battles again',
            m[MAP_ID] == den and walk_battles(w, 90) > 0, f'{r}, map ${m[MAP_ID]:02X}')
    w.goto(w.rooms['cities_fount'], 0, 4, 5)
    mp0, mp1 = field_cast(w)
    w.check('Repel in Cities_FOUNT (no battles there) fizzles, no MP spent',
            mp0 == mp1 and not m[REPELLANT] & 0x02, f'MP {mp0}->{mp1}, $C93E {m[REPELLANT]:02X}')


DEBUG = os.environ.get('WALK_DEBUG')


def s_noskill(w):
    """[S155 r4] the original game's "[INS 00] doesn't have any skill" (battle_command
    #2) trusted $C180: ATK's target list writes the foes' names there, so ATK -> B ->
    SKIL on a monster without skills named the foe last pointed at (the user: "BombCrag
    doesn't have any skills"). The VIPER + BURSTER battle through the real menus: PX
    DEF; HL ATK, the cursor on the BURSTER (BombCrag), B; HL SKIL -> the message."""
    print('noskill: ATK -> target list -> B -> SKIL on a monster without skills')
    m, p = w.m, w.p
    mid = w.rooms['dojo']
    w.goto(mid, 0, 16, 5)
    w.face('up')
    r = w.talk([True])
    w.check('the VIPER + BURSTER battle starts', r == 'battle', r)
    got = []
    p.hook_register(0x4C, 0x42D1, lambda _c: got.append(
        (m[0xC822], m[0xC823], m[0xC8DD] & 3, bytes(m[0xC180 + i] for i in range(5)))), None)
    plan, k, cur_cmd, held, until = ['d', 'a1b', 's'], 0, None, None, 0
    for i in range(6000):
        if m[GAME_MODE] == 2 and m[0xD9EC] == 4:
            btn = None
            f4, f5, f7 = m[0xD9F4], m[0xD9F5], m[0xD9F7]
            if m[0xC825] or f7 == 9:
                btn = 'a' if i % 30 == 0 else None
            elif f4 == 2:
                c = m[0xC8DA] & 3
                btn = 'a' if c == 1 else ('down' if c < 1 else 'up')
            elif f4 == 3 and m[0xC8DA] == 0x81 and f5 == 4:
                c = m[0xC8DC] & 3
                btn = 'a' if c == 3 else ('down' if c < 3 else 'up')
            elif f4 == 3 and m[0xC8DA] == 0x04 and f7 == 2:
                want = {'a': 0, 's': 1, 'd': 2}[plan[k][0]] if k < len(plan) else None
                c = m[0xC8DE] & 3
                btn = None if want is None else 'a' if c == want else ('down' if c < want else 'up')
                if btn == 'a' and held is None and i >= until:
                    cur_cmd = plan[k]
                    k += 1
            elif f4 == 3 and m[0xC8DA] == 0x04 and f7 in (6, 8):
                t = int(cur_cmd[1]) if cur_cmd and len(cur_cmd) > 1 else 0
                c = m[0xDD72] & 3
                btn = ('b' if cur_cmd.endswith('b') else 'a') if c == t else \
                    ('down' if c < t else 'up')
            if held is not None and i >= until:
                p.button_release(held)
                held, until = None, i + 16
            elif held is None and btn and i >= until:
                p.button_press(btn)
                held, until = btn, i + 4
        elif m[GAME_MODE] == 2:
            if held:
                p.button_release(held)
                held = None
            for s_ in range(2):
                if m[0xDD1B + s_] == 0:
                    w16(m, HP + 2 * s_, 200)
            if i % 8 < 4:
                p.button_press('a')
            else:
                p.button_release('a')
        if DEBUG and i % 50 == 0:
            print('dbg', i, m[GAME_MODE], m[0xD9EC], m[0xD9F4], m[0xD9F5], m[0xD9F7], hex(m[0xC8DA]), m[0xC825], k, held)
        p.tick()
        if any(g[:2] == (2, 2) for g in got):
            break
    p.hook_deregister(0x4C, 0x42D1)
    if held:
        p.button_release(held)
    msg = [g for g in got if g[:2] == (2, 2)]
    slot = msg[0][2] if msg else None
    name = bytes(w.rec_byte(m[0xCA8E + slot], 0x01 + i) for i in range(4)) if msg else b''
    shown = msg[0][3] if msg else b''
    w.check('ATK -> target list -> B -> SKIL: "… doesn\'t have any skill" names the monster '
            'commanded (not the foe)', msg and slot == 1 and shown[:shown.find(0xF0) if 0xF0 in shown
                                                              else 4] == name[:name.find(0xF0) if 0xF0 in name else 4],
            f'slot {slot}, $C180 {shown.hex()}, the monster {name.hex()}')
    w.snap('noskill')


def negative_rom(w):
    """The S155 effects removed in the ROM copy: the five battle handlers and the AI rule
    return at once (`ret`; the damage roll and the descriptor stay — a plain hit), and Repel
    is never matched in AnchorField14Tail (the field menu fizzles)."""
    rom = bytearray(open(w.rom, 'rb').read())
    for lab in ('SkillLoneWolf', 'SkillPunish', 'SkillFinish', 'SkillRupture', 'SkillRust',
                'CustomAIRule72', 'SlashLine72'):
        b, a = w.sym[lab]
        rom[b * 0x4000 + a - 0x4000] = 0xC9            # ret
    b, a = w.sym['AnchorField14Tail']
    o = b * 0x4000 + a - 0x4000
    k = rom.find(bytes([0xFE, REPEL, 0xCA]), o, o + 16)
    if k < 0:
        raise SystemExit('AnchorField14Tail: no `cp ID_REPEL / jp z` found')
    rom[k + 1] = 0x00                               # cp $00: never Repel
    b, a = w.sym['CustomMsg_E0_MagicBurn']          # the pre-r3 $4019[$FD] row
    rom[0x4C * 0x4000 + 0x4213 - 0x4000:0x4C * 0x4000 + 0x4215 - 0x4000] = bytes([a & 0xFF, a >> 8])
    b, a = w.sym['NoSkillName50']                   # [S155 r4] the buffer trusted again
    rom[b * 0x4000 + a - 0x4000] = 0xC9
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print('NEGATIVE CONTROL: the S155 handlers + CustomAIRule72 + SlashLine72 = ret; AnchorField14Tail never '
          'sees Repel; $4019[$FD] = MagicBurn\'s line; NoSkillName50 = ret')


def line_bonus_rom(w):
    """[S155 r3] CustomLineAlways = 0 in the ROM copy: the lines only with the bonus."""
    rom = bytearray(open(w.rom, 'rb').read())
    b, a = w.sym['CustomLineAlways']
    rom[b * 0x4000 + a - 0x4000] = 0
    open(w.rom, 'wb').write(rom)
    print('LINE-BONUS: CustomLineAlways = 0 (the lines only when the bonus applies)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--line-bonus', action='store_true')
    ap.add_argument('--steps', default='gift,numbers,bosses,repel,noskill')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = SkillWalk(a.build, a.sav, a.keep)
    d = json.load(open(a.project))
    ids = {r['id']: int(r['mapID'], 16) for r in d['custom']['rooms']}
    w.rooms = {'cities_fount': ids['cities_fount'], 'dojo': ids['wolf_dojo'],
               'den': ids['wolf_den']}
    if a.negative:
        negative_rom(w)
    if a.line_bonus:
        line_bonus_rom(w)
    b, ad = w.sym['CustomLineAlways']
    w.line_always = open(w.rom, 'rb').read()[b * 0x4000 + ad - 0x4000]
    s_continue(w)
    w.save('start')
    steps = {'gift': s_gift, 'numbers': s_numbers, 'bosses': s_bosses, 'repel': s_repel,
             'noskill': s_noskill}
    for name in a.steps.split(','):
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
