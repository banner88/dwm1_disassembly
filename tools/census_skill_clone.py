#!/usr/bin/env python3
"""
census_skill_clone.py — S111 (ROADMAP P3.11d): which STOCK skills a NEW custom
skill (ids $EF-$FE since S155; $EA-$FE before) may be based on — MEASURED in PyBoy, the data behind
`gamedata.skills.<239-254>.base` (editor2/core/custom_skills.py clone_problem;
PROJECT_COMPILER §2.27; BATTLE_SKILL_SYSTEM §13.9).

A new skill runs its base's effect code with ITS OWN id in $DB8A (bank $72
FarSkillFork -> CustomBaseTable), so every table keyed by the id reads the new
skill's row — but effect code that compares $DB8A with its own id (or an id
range) sees a different number. This census compares, for each base, the base
itself with a clone of it on a real save.

METHOD: one CONTINUE'd savestate of a real .sav on a build with the S111
engine and no new skill; per base B, the clone id $EF (S155; $EA before) is made B's twin by
writing ROM bytes in the loaded cartridge (exactly what a project with
gamedata.skills.239 = {"base": B} compiles to): CustomBaseTable / the AI target
row / looks / sounds / announce = B, CustomRecordPtrTable[$EF] = B's own record
($54:$41CF + 19*B), CustomMPCostTable[$EF] = B's MP, the name pointer = B's
name. Then two rig battles from the same state (the S110 forcing,
census_skill_present.run; wRNG1 / wRNG2 pinned each frame so the rolls repeat):
B cast by party slot 0, then $EF. Logged per run: the acts, the battle
messages ($4C:$42D1 hook: message id, subject), the HP / MP changes of all 8
slots. result = 'same' when the clone acted as often as B (>= 1) and its
message list and HP / MP changes are identical; else 'differs' (why) or
'nocast' (B itself never acts in a battle — field-only, items).

S160 (ROADMAP E13) --reclaim: the 14 RECLAIMED ids ($BC-$C1 / $CC-$D3, the battle skills of
14 field-only items) hold new skills too, in the id's STOCK rows (BATTLE_SKILL_SYSTEM §13.12):
per base B the census also makes $BC and $CC B's twins (ReclaimBaseTable / ReclaimTargetTable
/ StockPresentTable / StockSfxTable / StockElemTable / the record pointer $54:$4013 / the
$07 MP word / AnnounceTemplateTable / the name pointer) and casts them from the same state:
result 'same' when the twin = B (the S111 rule) — written to the JSON's `reclaim` section
({base: {'BC': …, 'CC': …, 'as_EF': bool, 'EF_now': …}}, as_EF = both twins == the $EF twin
exactly (lines, HP / MP changes, acts: the parity the engine's id views give), EF_now = this
run's $EF twin vs B). With --reclaim the recorded `results` are KEPT (the compiler's rule for
every new skill; S160 re-measured them on the user's save: 8 of 155 flip, from the compare's
700-frame window — KEY_LESSONS S160); bases missing from the file are measured.

S164 (ROADMAP E13 note "the clone census re-measure is timing-sensitive") --whole: the compare
of S111 ran a fixed 700-frame window after the first act with the RNG pinned once a frame — the
RNG also steps while the CPU idles (S86), so the copy's extra cycles (its far calls) moved a later
roll inside a frame and the window cut the battles at different points (8 bases flipped between
runs). --whole is the S163 twin-walk method (tools/walk_actbase.py) applied to every base: the
RNG pinned at EVERY BattleRNG call, three pinned seeds (a roll that misses under one lands under
another), and per seed the battle messages (message, line, skill, subject, $DB56) AND the board
after each message (the eight combatants' HP, MP, status $DB00-$DB41, $DD1B) compared over the
common prefix of two 2,600-frame battles (>= 5 messages, the copy cast as often as the base, one
apart only where the window cut). Run on the CURRENT engine (S163: a new skill also acts AS ITS
BASE where the effect code asks for the id), so the 41 S111 'differs' verdicts are re-judged. The
build is a compiled project (CustomBaseTable … labels in game.sym); the copy is poked into the
loaded cartridge exactly as before (poke_clone / poke_reclaim). Vivify / Revive / Farewell get a
fallen ally (slot 1) and Vivify / Revive target it (walk_actbase's board).

USAGE
  python3 tools/census_skill_clone.py --rom <build>/rom.gbc --sym <build>/game.sym \\
      --sav <a real .sav> [--bases 0-221] [--out extracted/skill_clone_census.json] [--reclaim]
  python3 tools/census_skill_clone.py --whole --build <build dir> --sav <a real .sav> \\
      [--bases 0-221] [--out …] [--reclaim]          # S164: the default method since S164
"""
import argparse
import io
import json
import os
import sys
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import GAME_MODE  # noqa: E402
from tools.census_skill_present import continue_game, parse_sym  # noqa: E402

CLONE = 0xEF            # S155: the first NEW id ($EA is Plunder's, held)
DCEC = 0xDCEC
HP_A, MP_A, MAXHP_A = 0xDBA3, 0xDBC3, 0xDBB3
FRAMES = 1800


def poke_clone(p, S, base, van):
    """Make id CLONE ($EF) = base's twin, in the loaded cartridge (ROM writes)."""
    i = CLONE - 0xDE

    def w(label, off, val):
        b, a = S[label]
        p.memory[b, a + off] = val
    w('CustomBaseTable', i, base)
    w('CustomTargetBaseTable', i, base)
    w('CustomProxyTable', i, base)
    w('CustomSfxTable', i, base)
    w('CustomElemTable', i, 0xFF)
    rec = 0x41CF + 19 * base
    w('CustomRecordPtrTable', 2 * i, rec & 0xFF)
    w('CustomRecordPtrTable', 2 * i + 1, rec >> 8)
    mp = van['mp'][base] if van['mp'][base] <= 255 else 0
    w('CustomMPCostTable', 2 * i, mp & 0xFF)
    w('CustomMPCostTable', 2 * i + 1, mp >> 8)
    w('CustomAnnounceTable', CLONE - 0xE2, van['announce'][base])
    nb, na = S['SkillNamePtrTable']
    lo, hi = p.memory[nb, na + 2 * base], p.memory[nb, na + 2 * base + 1]
    p.memory[nb, na + 2 * CLONE] = lo
    p.memory[nb, na + 2 * CLONE + 1] = hi


def poke_reclaim(p, S, base, van, rid):
    """[S160] Make the RECLAIMED id `rid` ($BC-$C1 / $CC-$D3) = base's twin, in the loaded
    cartridge: its stock rows (the record pointer, the $07 MP word, the announce slot, the
    look, the sounds, the element, the name pointer) + ReclaimBaseTable / ReclaimTargetTable."""
    k = rid - 0xBC

    def w(label, off, val):
        b, a = S[label]
        p.memory[b, a + off] = val
    w('ReclaimBaseTable', k, base)
    w('ReclaimTargetTable', k, base)
    w('StockPresentTable', rid, base)
    w('StockSfxTable', rid, base)
    w('StockElemTable', rid, 0xFF)
    w('AnnounceTemplateTable', rid, van['announce'][base])
    rec = 0x41CF + 19 * base
    p.memory[0x54, 0x4013 + 2 * rid] = rec & 0xFF
    p.memory[0x54, 0x4013 + 2 * rid + 1] = rec >> 8
    mp = van['mp'][base] if van['mp'][base] <= 255 else 0
    p.memory[0x07, 0x570C + 2 * rid] = mp & 0xFF
    p.memory[0x07, 0x570C + 2 * rid + 1] = mp >> 8
    nb, na = S['SkillNamePtrTable']
    lo, hi = p.memory[nb, na + 2 * base], p.memory[nb, na + 2 * base + 1]
    p.memory[nb, na + 2 * rid] = lo
    p.memory[nb, na + 2 * rid + 1] = hi


def run(p, sid, caster, target, ecount):
    m = p.memory
    msgs = []

    def on_msg(_):
        msgs.append((m[0xC823], m[0xDB89]))
    p.hook_register(0x4C, 0x42D1, on_msg, None)
    m[0xDA03] = 3; m[0xDA04] = 0
    m[0xDA02] = (ecount - 1) & 3
    for k in range(1, ecount):
        m[0xDA03 + 2 * k], m[0xDA04 + 2 * k] = 3, 0
    m[0xDA09] = 1; m[0xC905] = 0; m[0xC8EB] |= 0x40
    acts, prev, after, changes = 0, None, None, []
    hp_prev = None
    for i in range(FRAMES):
        if m[GAME_MODE] == 2:
            ph = m[0xD9EC]
            m[0xC899] = 0x5A; m[0xC89A] = 0xA5          # pin the RNG (repeatable rolls)
            for k in range(3):
                m[DCEC + 2 * k] = sid if k == caster else 0x8D
            for s in range(ecount):
                m[DCEC + 8 + 2 * s] = 0x8D
            if 4 <= ph <= 6:
                for k in range(3):
                    m[DCEC + 2 * k + 1] = target if k == caster else k
                for s in range(ecount):
                    m[DCEC + 9 + 2 * s] = 4 + s
                    m[HP_A + 8 + 2 * s] = 0xE7; m[HP_A + 9 + 2 * s] = 3
                    m[MAXHP_A + 8 + 2 * s] = 0xE7; m[MAXHP_A + 9 + 2 * s] = 3
                m[MP_A + 2 * caster] = 200; m[MP_A + 2 * caster + 1] = 0
                for k in range(3):
                    m[HP_A + 2 * k] = 100; m[HP_A + 2 * k + 1] = 0
                    m[MAXHP_A + 2 * k] = 200; m[MAXHP_A + 2 * k + 1] = 0
            hp = tuple(m[HP_A + 2 * s] | m[HP_A + 2 * s + 1] << 8 for s in range(8)) + \
                tuple(m[MP_A + 2 * s] for s in range(3))
            if hp_prev is not None and hp != hp_prev and ph == 7:
                changes.append(tuple(b - a for a, b in zip(hp_prev, hp)))
            hp_prev = hp
            cur = (ph, m[0xD9ED], m[0xDB8A], m[0xDB88])
            if cur == (7, 1, sid, caster) and prev != cur:
                acts += 1
                if after is None:
                    after = i
            prev = cur
            if after is not None and i - after > 700:
                break
        if i % 8 < 4:
            p.button_press('a')
        else:
            p.button_release('a')
        p.tick()
    p.hook_deregister(0x4C, 0x42D1)
    return acts, msgs, changes


def compare(a, b):
    (ka, ma, ca), (kb, mb, cb) = a, b
    if ka == 0:
        return 'nocast', 'the stock skill never acts in a rig battle'
    if kb == 0:
        return 'differs', 'the copy never acted'
    if [x for x, _t in ma] != [x for x, _t in mb]:
        return 'differs', f"battle lines {[hex(x) for x, _ in ma][:8]} vs {[hex(x) for x, _ in mb][:8]}"
    if [t for _x, t in ma] != [t for _x, t in mb]:
        return 'differs', 'the lines name other targets'
    if ca != cb:
        return 'differs', f"HP / MP changes {ca[:3]} vs {cb[:3]}"
    return 'same', ''


# ------------------------------------------------------------------ S164: --whole
SEEDS = [(0x5A, 0xA5), (0x08, 0x31), (0xE7, 0x6C)]     # walk_actbase's pinned RNG pairs
DEAD_ALLY = {48: 1, 49: 1, 50: None}                   # base -> its target with slot 1 fallen
WHOLE_FRAMES = 2600


def battle_whole(w, sid, target, ecount, seed, board_dead):
    """One forced battle (the S110 rig of walk_reclaim, + `ecount` enemies): party slot 0 acts
    `sid` on `target`, the others Attack-with-curse (walk_skills.CURSE_ATTACK — the rig of
    walk_actbase), the foes by their AI, HP held (foes 999, party 400 / 999 so a heal shows its size), the RNG pinned at every frame AND
    every BattleRNG call. -> (msgs, states, casts)."""
    from tools.walk_skills import r16, w16, HP, MAXHP, MP, CURSE_ATTACK
    from tools.walk_reclaim import WCUSTOMLINE
    p, m = w.p, w.m
    msgs, states, acts = [], [], []

    def snapshot():
        return (tuple(r16(m, HP + 2 * j) for j in range(8)),
                tuple(r16(m, MP + 2 * j) for j in range(8)),
                tuple(m[0xDB00 + j] for j in range(0x42)),
                tuple(m[0xDD1B + j] for j in range(8)))

    def on_msg(_):
        msgs.append((m[0xC823], m[WCUSTOMLINE], m[0xDB8A], m[0xDB89], r16(m, 0xDB56)))

    def on_state(_):
        states.append(snapshot())

    def on_act(_):
        acts.append((m[0xDB88], m[0xDB8A]))

    def pin(_):
        m[0xC899], m[0xC89A] = seed

    def pin_far(_):
        # GenerateRNG called by battle code (its return address in a ROMX bank: the damage
        # rolls of bank $53, the AI's of banks $57 / $58 …) — pinned too; the per-frame idle
        # steps (called from ROM0) run free, so the CPU time of the acting code cannot move a
        # later roll (S164: Thordain / SleepAir drifted at their last message with only
        # BattleRNG pinned)
        sp = p.register_file.SP
        if (m[sp] | m[sp + 1] << 8) >= 0x4000:
            m[0xC899], m[0xC89A] = seed
    regs = [(0x4C, 0x42D1, on_msg), (0x4C, 0x735E, on_state), w.sym['FarSkillFork'] + (on_act,),
            w.sym['BattleRNG'] + (pin,), w.sym['GenerateRNG'] + (pin_far,)]
    for b, a, fn in regs:
        p.hook_register(b, a, fn, None)
    m[0xDA02] = (ecount - 1) & 3
    for k in range(ecount):
        m[0xDA03 + 2 * k], m[0xDA04 + 2 * k] = 3, 0
    m[0xDA09], m[0xC905] = 1, 0
    m[0xC8EB] |= 0x40
    for i in range(WHOLE_FRAMES):
        if m[GAME_MODE] == 2:
            ph = m[0xD9EC]
            m[0xC899], m[0xC89A] = seed
            for k in range(3):
                m[DCEC + 2 * k] = sid if k == 0 else CURSE_ATTACK
            if 4 <= ph <= 6:
                for k in range(3):
                    m[DCEC + 2 * k + 1] = target if k == 0 else k
                for s_ in range(ecount):
                    w16(m, HP + 8 + 2 * s_, 999)
                    w16(m, MAXHP + 8 + 2 * s_, 999)
                    w16(m, MP + 8 + 2 * s_, 250)
                w16(m, MP, 200)
                for k in range(3):
                    if m[0xDD1B + k] != 0xFF:
                        w16(m, HP + 2 * k, 400)          # 400 / 999: a heal shows its size
                        w16(m, MAXHP + 2 * k, 999)
                if board_dead:
                    w16(m, HP + 2, 0)                    # party slot 1 fallen, processed
                    m[0xDD1B + 1] = 1
        if i % 8 < 4:
            p.button_press('a')
        else:
            p.button_release('a')
        p.tick()
        if len(msgs) > 3000:
            break
    p.button_release('a')
    for b, a, _fn in regs:
        p.hook_deregister(b, a)
    return msgs, states, sum(1 for c, k in acts if c == 0 and k == sid)


def compare_whole(base, new, ra, rb):
    """walk_actbase's verdict on one seed: the common prefix of messages (the new id written as
    the base) and boards. -> (result, why, n)."""
    (ma, sa, ca), (mb, sb, cb) = ra, rb
    if ca == 0:
        return 'nocast', 'the stock skill never acts in a rig battle', 0
    if cb == 0:
        return 'differs', 'the copy never acted', 0
    mb = [tuple(base if (j == 2 and x == new) else x for j, x in enumerate(t)) for t in mb]
    n_ = min(len(ma), len(mb), len(sa), len(sb))
    # the window may also end inside an act that has reached FarSkillFork but printed nothing
    # yet (a reclaimed twin's longer far calls, S164: CallHelp / RainSlash 5 vs 4 under one
    # seed with every message equal): one cast apart is the window, more is a difference
    if abs(ca - cb) > 1:
        return 'differs', f'casts {ca} vs {cb}', n_
    for k in range(n_):
        if ma[k] != mb[k]:
            return 'differs', f'messages differ at {k} of {n_}: {ma[k:k + 2]} vs {mb[k:k + 2]}', n_
        if sa[k] != sb[k]:
            parts = []
            for part, (x, y) in zip(('hp', 'mp', 'status', 'dd1b'), zip(sa[k], sb[k])):
                if x != y:
                    parts.append((part, [(i, u, v) for i, (u, v) in enumerate(zip(x, y)) if u != v][:3]))
            return 'differs', f'board differs after message {k} of {n_}: {parts}', n_
    if n_ < 5:
        return 'differs', f'only {n_} messages compared', n_
    return 'same', '', n_


def main_whole(a):
    from tools.walk_regions import s_continue
    from tools.walk_reclaim import ReclaimWalk
    keep = a.keep or os.path.join('/tmp', 'census_skill_clone_whole')
    os.makedirs(keep, exist_ok=True)
    w = ReclaimWalk(a.build, a.sav, keep)
    S = parse_sym(os.path.join(a.build, 'game.sym'))
    v = json.load(open(os.path.join(REPO, 'extracted', 'gamedata_vanilla.json')))['tables']
    van = {'records': [bytes.fromhex(r) for r in v['skill_records']['rows']],
           'mp': [int.from_bytes(bytes.fromhex(r), 'little') for r in v['skill_mp']['rows']],
           'announce': [bytes.fromhex(r)[0] for r in v['skill_announce']['rows']]}
    recs = {r['id']: r for r in json.load(open(os.path.join(REPO, 'extracted',
                                                            'skill_records.json')))['records']}
    if a.negative:
        # the act-time base view of S163 put back to the original bytes in the ROM copy
        # (walk_actbase's negative control): the bases whose effect asks for the id must differ
        from tools.walk_actbase import negative_rom
        negative_rom(w)
    s_continue(w)
    st = io.BytesIO()
    w.p.save_state(st)
    old = json.load(open(a.out)) if os.path.exists(a.out) else {}
    results = {} if a.fresh else dict(old.get('results', {}))
    reclaim = {} if a.fresh else dict(old.get('reclaim', {}))
    lo, hi = (int(x) for x in a.bases.split('-'))
    t0 = time.time()

    def save():
        out = {'_generator': (
                   f"tools/census_skill_clone.py --whole (S164; S111 method before, S160 --reclaim) on "
                   f"{os.path.basename(os.path.normpath(a.build))} (the CURRENT engine: a new skill acts as "
                   "its base, S163) + a real .sav; PyBoy, the stock skill vs its copy at id $EF (results) "
                   "and at the reclaimed ids $BC / $CC (reclaim), party slot 0 casting, the RNG pinned at "
                   "every BattleRNG call under 3 seeds, messages + the board after each compared"),
               'results': dict(sorted(results.items(), key=lambda kv: int(kv[0])))}
        if reclaim:
            out['reclaim'] = dict(sorted(reclaim.items(), key=lambda kv: int(kv[0])))
        json.dump(out, open(a.out, 'w'), indent=1)

    def judge(base, sid, poke, target, ecount, dead):
        verdicts = []
        for seed in SEEDS:
            st.seek(0); w.p.load_state(st)
            ra = battle_whole(w, base, target, ecount, seed, dead)
            st.seek(0); w.p.load_state(st)
            poke()
            rb = battle_whole(w, sid, target, ecount, seed, dead)
            verdicts.append(compare_whole(base, sid, ra, rb) + ((ra[2], rb[2]),))
        res = [x[0] for x in verdicts]
        if all(r == 'nocast' for r in res):
            return 'nocast', verdicts[0][1], verdicts
        bad = [x for x in verdicts if x[0] not in ('same',)]
        if not bad:
            return 'same', '', verdicts
        return 'differs', bad[0][1], verdicts

    for base in range(lo, hi + 1):
        r = recs.get(base, {})
        if r.get('kind', 'skill') != 'skill':
            results[str(base)] = {'name': r.get('name', ''), 'result': 'not a skill'}
            continue
        tm = van['records'][base][2]
        target = 4 if tm & 0x10 else 0
        ecount = 3 if tm == 0x12 else 1
        dead = base in DEAD_ALLY
        if DEAD_ALLY.get(base) is not None:
            target = DEAD_ALLY[base]
        res, why, ver = judge(base, CLONE, lambda: poke_clone(w.p, S, base, van), target, ecount, dead)
        prev = old.get('results', {}).get(str(base), {})
        results[str(base)] = {'name': r.get('name', ''), 'result': res, 'why': why,
                              'casts': [list(x[3]) for x in ver], 'messages': [x[2] for x in ver],
                              'method': 'whole (S164)',
                              'was': prev.get('result') if prev.get('result') != res else None}
        if results[str(base)]['was'] is None:
            del results[str(base)]['was']
        line = f"{base:3d} {r.get('name', ''):10s} {res:8s} {why[:80]}"
        if a.reclaim and res == 'same':
            ent = {'name': r.get('name', '')}
            same_ef = True
            for rid in (0xBC, 0xCC):
                rr, rw, rv = judge(base, rid, lambda rid=rid: poke_reclaim(w.p, S, base, van, rid),
                                   target, ecount, dead)
                ent[f'{rid:02X}'] = {'result': rr, 'why': rw, 'casts': [list(x[3]) for x in rv]}
                same_ef = same_ef and rr == 'same'
                line += f" | ${rid:02X} {rr}"
            ent['as_EF'] = same_ef
            reclaim[str(base)] = ent
        elif a.reclaim:
            reclaim.pop(str(base), None)
        save()
        print(f"{line}  ({time.time() - t0:.0f} s)", flush=True)
    save()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom')
    ap.add_argument('--sym')
    ap.add_argument('--sav', required=True)
    ap.add_argument('--whole', action='store_true',
                    help='S164: whole-battle twin compare (RNG pinned at every BattleRNG call, 3 seeds)')
    ap.add_argument('--build', help='--whole: a compiled project build dir (rom.gbc, game.sym, manifest.json)')
    ap.add_argument('--keep', help='--whole: a scratch dir for the walk ROM copy')
    ap.add_argument('--fresh', action='store_true', help='--whole: start from an empty results map')
    ap.add_argument('--negative', action='store_true',
                    help='--whole: the S163 act-time view calls back to the original bytes (a control)')
    ap.add_argument('--bases', default='0-221')
    ap.add_argument('--out', default=os.path.join(REPO, 'extracted', 'skill_clone_census.json'))
    ap.add_argument('--reclaim', action='store_true',
                    help='S160: also the twins at the reclaimed ids $BC / $CC (the `reclaim` section)')
    a = ap.parse_args()
    if a.whole:
        return main_whole(a)
    if not (a.rom and a.sym):
        ap.error('--rom and --sym are needed without --whole')
    lo, hi = (int(x) for x in a.bases.split('-'))
    S = parse_sym(a.sym)
    v = json.load(open(os.path.join(REPO, 'extracted', 'gamedata_vanilla.json')))['tables']
    van = {'records': [bytes.fromhex(r) for r in v['skill_records']['rows']],
           'mp': [int.from_bytes(bytes.fromhex(r), 'little') for r in v['skill_mp']['rows']],
           'announce': [bytes.fromhex(r)[0] for r in v['skill_announce']['rows']]}
    recs = {r['id']: r for r in json.load(open(os.path.join(REPO, 'extracted',
                                                            'skill_records.json')))['records']}
    p = continue_game(a.rom, a.sav)
    st = io.BytesIO(); p.save_state(st)
    results, reclaim, old = {}, {}, {}
    if os.path.exists(a.out):
        old = json.load(open(a.out))
        results = old.get('results', {})
        reclaim = old.get('reclaim', {})
    t0 = time.time()

    def save():
        gen = old.get('_generator') if not a.reclaim else None
        out = {'_generator': gen or (
                   f"tools/census_skill_clone.py (S111; S160 --reclaim) on {os.path.basename(a.rom)} "
                   "+ a real .sav; PyBoy, the stock skill vs its copy at id $EF (results) and at "
                   "the reclaimed ids $BC / $CC (reclaim), RNG pinned, party slot 0 casting"),
               'results': dict(sorted(results.items(), key=lambda kv: int(kv[0])))}
        if reclaim:
            out['reclaim'] = dict(sorted(reclaim.items(), key=lambda kv: int(kv[0])))
        json.dump(out, open(a.out, 'w'), indent=1)

    for base in range(lo, hi + 1):
        r = recs.get(base, {})
        if r.get('kind', 'skill') != 'skill':
            results[str(base)] = {'name': r.get('name', ''), 'result': 'not a skill'}
            continue
        tm = van['records'][base][2]
        target = 4 if tm & 0x10 else 0
        ecount = 3 if tm == 0x12 else 1
        st.seek(0); p.load_state(st)
        ra = run(p, base, 0, target, ecount)
        st.seek(0); p.load_state(st)
        poke_clone(p, S, base, van)
        rb = run(p, CLONE, 0, target, ecount)
        res, why = compare(ra, rb)
        line = f"{base:3d} {r.get('name', ''):10s} {res:8s} {why[:70]}"
        if not a.reclaim or str(base) not in results:
            results[str(base)] = {'name': r.get('name', ''), 'result': res, 'why': why,
                                  'acts': [ra[0], rb[0]]}
        if a.reclaim:                                   # [S160] the reclaimed twins
            # the recorded S111 `results` stay (the compiler's rule for every new skill);
            # this run's $EF twin is kept here beside the reclaimed ones (EF_now)
            ent = {'name': r.get('name', ''), 'EF_now': {'result': res, 'why': why,
                                                        'acts': [ra[0], rb[0]]}}
            same_ef = True
            for rid in (0xBC, 0xCC):
                st.seek(0); p.load_state(st)
                poke_reclaim(p, S, base, van, rid)
                rc = run(p, rid, 0, target, ecount)
                rr, rw = compare(ra, rc)
                ent[f'{rid:02X}'] = {'result': rr, 'why': rw, 'acts': rc[0]}
                same_ef = same_ef and rc[1:] == rb[1:] and rc[0] == rb[0]
                line += f" | ${rid:02X} {rr}"
            ent['as_EF'] = same_ef
            reclaim[str(base)] = ent
            line += f" | as $EF {same_ef}"
        save()
        print(f"{line}  ({time.time() - t0:.0f} s)", flush=True)
    save()


if __name__ == '__main__':
    main()
