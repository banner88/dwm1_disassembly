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

USAGE
  python3 tools/census_skill_clone.py --rom <build>/rom.gbc --sym <build>/game.sym \\
      --sav <a real .sav> [--bases 0-221] [--out extracted/skill_clone_census.json] [--reclaim]
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', required=True)
    ap.add_argument('--sym', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--bases', default='0-221')
    ap.add_argument('--out', default=os.path.join(REPO, 'extracted', 'skill_clone_census.json'))
    ap.add_argument('--reclaim', action='store_true',
                    help='S160: also the twins at the reclaimed ids $BC / $CC (the `reclaim` section)')
    a = ap.parse_args()
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
