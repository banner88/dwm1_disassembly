#!/usr/bin/env python3
"""
census_skill_element.py — S111 (ROADMAP P3.11c/d): which skills' DAMAGE is cut
by a resistance, through which ladder, and WHICH resistance (the skill's
"element") — MEASURED in PyBoy, the data behind `gamedata.skills.<id>.element`
(editor2/core/custom_skills.py; BATTLE_SKILL_SYSTEM §15.3 "Element override").

The element is not a record field: each damage handler in bank $52 reads one
2-bit resistance level of the target itself (`call BattleFunc_67bb..67d9` =
packed byte $DD28+k of the target's 7, then a shift + `and $03`) and passes it
in A to one of three damage ladders: CheckTargetGuardA ($6756, spells),
ResLadderBreath_676c (breaths / BigBang / RockThrow / MegaMagic),
ResLadderElemSlash_6782 (elemental slashes). Resistance t sits at packed
position t+1 (byte (t+1)//4, bit pair 3-((t+1)%4), MSB first).

METHOD: one CONTINUE'd savestate of a real .sav; per skill, the S110 rig
(census_skill_present.run's forcing; wRNG1 / wRNG2 pinned each frame, as in
census_skill_clone.py — unpinned, CallHelp's helper drifted between builds) with every combatant's 7 packed bytes
poked to $1B each frame (= pairs 0,1,2,3 in every byte, so the level the
ladder receives IS the pair index), hooks on the 7 byte-select routines (which
byte k) and the 3 ladders (which ladder, A = level). An event counts only
while $DB8A == the skill. element = 4k + level - 1.

USAGE
  python3 tools/census_skill_element.py --rom <build>/rom.gbc --sym <build>/game.sym \\
      --sav <a real .sav> [--skills 0-221] [--out extracted/skill_element_census.json]
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

DCEC = 0xDCEC
HP_A, MP_A, MAXHP_A = 0xDBA3, 0xDBC3, 0xDBB3
PACKED = 0xDD28
SELECTORS = ['BattleFunc_67bb', 'GetBattleStatAddr1', 'BattleFunc_67c5', 'BattleFunc_67ca',
             'BattleFunc_67cf', 'BattleFunc_67d4', 'BattleFunc_67d9']
LADDERS = {'CheckTargetGuardA': 'spell', 'ResLadderBreath_676c': 'breath',
           'ResLadderElemSlash_6782': 'slash'}
FRAMES = 1500


def run(p, S, sid, caster, target):
    m = p.memory
    ev, state = [], {'k': None}

    def sel(k):
        def cb(_):
            if m[0xDB8A] == sid:
                state['k'] = k
        return cb

    def lad(name):
        def cb(_):
            if m[0xDB8A] == sid:
                ev.append((name, state['k'], p.register_file.A, m[0xDB89]))
        return cb
    hooks = []
    for k, nm in enumerate(SELECTORS):
        b, a = S[nm]
        p.hook_register(b, a, sel(k), None); hooks.append((b, a))
    for nm in LADDERS:
        b, a = S[nm]
        p.hook_register(b, a, lad(nm), None); hooks.append((b, a))
    m[0xDA03] = 3; m[0xDA04] = 0; m[0xDA02] = 0
    m[0xDA09] = 1; m[0xC905] = 0; m[0xC8EB] |= 0x40
    acts, prev, after = 0, None, None
    for i in range(FRAMES):
        if m[GAME_MODE] == 2:
            ph = m[0xD9EC]
            m[0xC899] = 0x5A; m[0xC89A] = 0xA5          # pin the RNG (repeatable runs)
            for k in range(3):
                m[DCEC + 2 * k] = sid if k == caster else 0x8D
            m[DCEC + 8] = 0x8D
            if 4 <= ph <= 6:
                for k in range(3):
                    m[DCEC + 2 * k + 1] = target if k == caster else k
                m[DCEC + 9] = 4
                m[HP_A + 8] = 0xE7; m[HP_A + 9] = 3; m[MAXHP_A + 8] = 0xE7; m[MAXHP_A + 9] = 3
                m[MP_A + 2 * caster] = 200; m[MP_A + 2 * caster + 1] = 0
                m[HP_A] = 200; m[HP_A + 1] = 0; m[MAXHP_A] = 200; m[MAXHP_A + 1] = 0
            for o in range(8 * 7):
                m[PACKED + o] = 0x1B
            cur = (ph, m[0xD9ED], m[0xDB8A], m[0xDB88])
            if cur == (7, 1, sid, caster) and prev != cur:
                acts += 1
                if after is None:
                    after = i
            prev = cur
            if after is not None and i - after > 400:
                break
        if i % 8 < 4:
            p.button_press('a')
        else:
            p.button_release('a')
        p.tick()
    for b, a in hooks:
        p.hook_deregister(b, a)
    return acts, ev


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', required=True)
    ap.add_argument('--sym', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--skills', default='0-221')
    ap.add_argument('--out', default=os.path.join(REPO, 'extracted', 'skill_element_census.json'))
    a = ap.parse_args()
    lo, hi = (int(x) for x in a.skills.split('-'))
    S = parse_sym(a.sym)
    recs = {r['id']: r for r in json.load(open(os.path.join(REPO, 'extracted',
                                                            'skill_records.json')))['records']}
    van = json.load(open(os.path.join(REPO, 'extracted', 'gamedata_vanilla.json')))
    raw = [bytes.fromhex(r) for r in van['tables']['skill_records']['rows']]
    p = continue_game(a.rom, a.sav)
    base = io.BytesIO(); p.save_state(base)
    results = {}
    if os.path.exists(a.out):
        results = json.load(open(a.out)).get('results', {})
    t0 = time.time()

    def save():
        out = {'_generator': (f"tools/census_skill_element.py (S111) on {os.path.basename(a.rom)} "
                              "+ a real .sav; PyBoy, RNG pinned, packed resistances poked to $1B, hooks on the "
                              "7 byte selectors + 3 damage ladders"),
               'ladders': LADDERS,
               'results': dict(sorted(results.items(), key=lambda kv: int(kv[0])))}
        json.dump(out, open(a.out, 'w'), indent=1)

    for sid in range(lo, hi + 1):
        tm = raw[sid][2]
        target = 4 if tm & 0x10 else 0
        base.seek(0); p.load_state(base)
        acts, ev = run(p, S, sid, 0, target)
        hits = sorted({(LADDERS[n], k, lv) for n, k, lv, _t in ev if k is not None})
        els = sorted({(lad, 4 * k + lv - 1) for lad, k, lv in hits})
        results[str(sid)] = {'name': recs.get(sid, {}).get('name', ''), 'acts': acts,
                             'ladders': [{'ladder': l_, 'element': e} for l_, e in els]}
        save()
        print(f"{sid:3d} {recs.get(sid, {}).get('name', ''):10s} acts={acts} "
              f"{[(l_, e) for l_, e in els]}  ({time.time() - t0:.0f} s)", flush=True)
    save()


if __name__ == '__main__':
    main()
