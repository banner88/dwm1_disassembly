#!/usr/bin/env python3
"""
census_skill_present.py — S110 (ROADMAP P3.11): which vanilla skills can LEND
their presentation (animation + flash + cast / hit sounds) to another skill
without stalling the battle — the data behind `gamedata.skills.<id>.looks_like`
(editor2/core/skills.py lend_problem; PROJECT_COMPILER §2.26;
BATTLE_SKILL_SYSTEM §11.8).

METHOD (PyBoy, on a build with the S110 engine — bank $5f StockPresentTable /
bank $55 StockSfxTable):
  * (the party's other slots and the enemies are forced to guard — Defence
    $8D — and the enemies kept at 999 HP: a strong save one-shots a 250-HP
    enemy inside a frame. The SKILL bytes are forced every frame because the
    tactics / enemy AI picks the action at act time and would replace the
    borrower with Attack; the TARGET bytes only in phases 4-6 — run()'s doc.
    An S110 first pass that forced nothing in phase 7 measured mostly Attacks
    and was discarded.)
  * one CONTINUE'd savestate from a real .sav, then per (donor, borrower) run:
    write StockPresentTable[borrower] = StockSfxTable[borrower] = donor
    straight into the loaded ROM (these two bytes are the whole difference a
    `looks_like` build makes), start the S75 TriggerBattle-mimic rig battle
    (simulator/measure_rig.py) against EID 3 (1 or 3 enemies), force the
    borrower into the caster's queue every frame, keep everyone alive, mash A
    on the S70 cadence for 2,400 frames;
  * log every change of the action machine ($D9EC/$D9ED/$D9EE/$DB82/$DA82/
    $DB8A); result 'ok' = the borrower was acted >= 2 times and the machine
    never froze for >= 600 frames; 'stall' = a frozen gap >= 600 frames (the
    $52:$6C4D done-spin class, BATTLE_SKILL_SYSTEM §13.2); 'nocast' = fewer
    than 2 actions without a stall.
  * borrowers (the caster's side and the skill's target kind):
      party/foe1  Blaze ($00) -> enemy 4          party/foeall Firebal ($03), 3 enemies
      party/ally1 Heal ($2B) -> party 0           party/allyall HealUs ($2D)
      party/self  ChargeUP ($41)
      enemy/foe1  Blaze, cast by enemy 4 -> party 0
      enemy/ally1 Heal, cast by enemy 4 on itself
    the donor = the borrower itself is the baseline (must be 'ok').

USAGE
  python3 tools/census_skill_present.py --rom <build>/rom.gbc --sym <build>/game.sym \\
      --sav <a real .sav> [--donors 0-221] [--out extracted/skill_present_census.json]
"""
import argparse
import io
import json
import os
import sys
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import (boot_with_sav, adv, tap, GAME_MODE, TEXTBOX,  # noqa: E402
                                 PARTY_COUNT)

DCEC = 0xDCEC
HP_A, MP_A, MAXHP_A = 0xDBA3, 0xDBC3, 0xDBB3
FRAMES, STALL = 2400, 600

# key: (caster slot, skill, target, enemy count)
BORROWERS = {
    'party/foe1':    (0, 0x00, 4, 1),
    'party/foeall':  (0, 0x03, 4, 3),
    'party/ally1':   (0, 0x2B, 0, 1),
    'party/allyall': (0, 0x2D, 0, 1),
    'party/self':    (0, 0x41, 0, 1),
    'enemy/foe1':    (4, 0x00, 0, 1),
    'enemy/ally1':   (4, 0x2B, 4, 1),
}


def parse_sym(path):
    out = {}
    for line in open(path):
        p = line.split()
        if len(p) == 2 and ':' in p[0]:
            b, a = p[0].split(':')
            out[p[1]] = (int(b, 16), int(a, 16))
    return out


def continue_game(rom, sav):
    p = boot_with_sav(rom, sav)
    adv(p, 400); tap(p, 'start'); adv(p, 120); tap(p, 'a'); adv(p, 120)
    tap(p, 'a'); adv(p, 200); tap(p, 'a')
    for _ in range(60):
        if p.memory[GAME_MODE] == 1 and p.memory[TEXTBOX] == 0:
            break
        tap(p, 'a', wait=20)
    for _ in range(10):
        tap(p, 'b', wait=20)
    adv(p, 120)
    if p.memory[PARTY_COUNT] == 0:
        raise SystemExit('the save has no party — use a save with monsters')
    return p


def run(p, caster, skill, target, ecount, eid=3, trace=None):
    """One rig battle. FORCING (S110, measured): under FIGHT both the party and
    the enemies choose their action AT ACT TIME (act state $18 = bank $57 entry
    0, the AI machine) and overwrite the queue, so the SKILL bytes are forced
    every frame; the TARGET bytes and the keep-alive HP only in phases 4-6 (a
    group skill steps its queue target per victim in phase 7 — KEY_LESSONS S85
    / S110). An act = the caster entering act state 1 with the skill in $DB8A
    (where the MP is charged)."""
    m = p.memory
    m[0xDA03] = eid & 0xFF; m[0xDA04] = eid >> 8
    m[0xDA02] = (ecount - 1) & 3
    for k in range(1, ecount):
        m[0xDA03 + 2 * k], m[0xDA04 + 2 * k] = m[0xDA03], m[0xDA04]
    m[0xDA09] = 1; m[0xC905] = 0; m[0xC8EB] |= 0x40
    last, last_f, gap, acts, prev, seen = None, 0, 0, 0, None, False
    for i in range(FRAMES):
        if m[GAME_MODE] == 2:
            seen = True
            ph = m[0xD9EC]
            for k in range(3):                      # the party guards (Defence $8D)
                m[DCEC + 2 * k] = skill if k == caster else 0x8D
            for s in range(ecount):                 # and so do the enemies
                m[DCEC + 8 + 2 * s] = skill if caster == 4 + s else 0x8D
            if 4 <= ph <= 6:
                for k in range(3):
                    m[DCEC + 2 * k + 1] = target if k == caster else k
                for s in range(ecount):
                    m[DCEC + 9 + 2 * s] = target if caster == 4 + s else 4 + s
                    m[HP_A + 8 + 2 * s] = 0xE7; m[HP_A + 9 + 2 * s] = 3       # 999
                    m[MAXHP_A + 8 + 2 * s] = 0xE7; m[MAXHP_A + 9 + 2 * s] = 3
                m[MP_A + 2 * caster] = 200; m[MP_A + 2 * caster + 1] = 0
                m[HP_A] = 200; m[HP_A + 1] = 0; m[MAXHP_A] = 200; m[MAXHP_A + 1] = 0
            st = (ph, m[0xD9ED], m[0xD9EE], m[0xDB82], m[0xDA82], m[0xDB8A])
            if st != last:
                if trace is not None:
                    trace.append((i,) + st + (m[0xDB88],))
                if last is not None:
                    gap = max(gap, i - last_f)
                last, last_f = st, i
            cur = (ph, m[0xD9ED], m[0xDB8A], m[0xDB88])
            if cur == (7, 1, skill, caster) and prev != cur:
                acts += 1
            prev = cur
        if i % 24 < 3:
            p.button_press('a')
        else:
            p.button_release('a')
        p.tick()
    if seen:
        gap = max(gap, FRAMES - last_f)
    res = 'stall' if gap >= STALL else ('ok' if acts >= 2 else 'nocast')
    return res, gap, acts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', required=True)
    ap.add_argument('--sym', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--donors', default='0-221')
    ap.add_argument('--out', default=os.path.join(REPO, 'extracted', 'skill_present_census.json'))
    ap.add_argument('--redo', action='store_true', help='re-measure donors already in --out')
    a = ap.parse_args()
    lo, hi = (int(x) for x in a.donors.split('-'))
    S = parse_sym(a.sym)
    tabs = [S['StockPresentTable'], S['StockSfxTable']]
    p = continue_game(a.rom, a.sav)
    base = io.BytesIO(); p.save_state(base)
    names = {}
    try:
        names = {r['id']: r['name'] for r in json.load(open(os.path.join(
            REPO, 'extracted', 'skill_records.json')))['records']}
    except (OSError, ValueError):
        pass
    results, t0 = {}, time.time()
    if os.path.exists(a.out):                  # resume / merge (written per donor)
        try:
            results = json.load(open(a.out)).get('results', {})
        except ValueError:
            results = {}

    def save():
        out = {'_generator': (f"tools/census_skill_present.py (S110) on "
                              f"{os.path.basename(a.rom)} + a real .sav; PyBoy, {FRAMES} frames "
                              f"per run, stall = a frozen action machine >= {STALL} frames"),
               'borrowers': {k: {'caster_slot': v[0], 'skill': v[1], 'target': v[2],
                                 'enemies': v[3]} for k, v in BORROWERS.items()},
               'results': dict(sorted(results.items(), key=lambda kv: int(kv[0])))}
        json.dump(out, open(a.out, 'w'), indent=1)

    for donor in range(lo, hi + 1):
        if str(donor) in results and not a.redo:
            continue
        row = {}
        for key, (caster, skill, target, ecount) in BORROWERS.items():
            base.seek(0); p.load_state(base)
            for b, ad in tabs:
                for sid in range(222):
                    p.memory[b, ad + sid] = sid
                p.memory[b, ad + skill] = donor
            res, gap, acts = run(p, caster, skill, target, ecount)
            row[key] = {'result': res, 'gap': gap, 'acts': acts}
        results[str(donor)] = {'name': names.get(donor, ''), 'runs': row}
        save()
        bad = [k for k, v in row.items() if v['result'] != 'ok']
        print(f"{donor:3d} {names.get(donor, ''):10s} "
              + (' '.join(f"{k}={row[k]['result']}" for k in bad) if bad else 'all ok')
              + f"   ({time.time() - t0:.0f} s)", flush=True)
    save()
    print('wrote', a.out)


if __name__ == '__main__':
    main()
