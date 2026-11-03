#!/usr/bin/env python3
"""walk_aifix.py — S164 (ROADMAP E17 note "the original AI's bugs", gamedata.ai_fixes) on the
real game (PyBoy on the user's .sav).

The demo (examples/s164_conflux_demo/build_demo.py) switches all five fixes ON and adds the
TACTICIAN (Bang, Sleep, DeMagic, TwinSlash) and the WARDEN (DrakSlash, Upper, Increase,
Surround), INT 200 (the cleverest AI, $DD0B = 2). Forced battles (the S110 rig: the party
defending, HP held, the RNG re-seeded at every AI stage — walk_mirror.spar) on boards that
make the original rules and the fixed ones disagree:
  lone     party slots 1 / 2 fallen, slot 0 alive (one foe, in the FIRST opposing slot);
  dragon   all three alive, party slot 1 a dragon (DrakSlash's family) — not slot 0;
  buffed   all three alive, party slot 2 with a raised DEF (+3 bit 2 — DeMagic's "a buff to
           remove"), slots 0 / 1 without;
  (the WARDEN's Upper / Increase take AIRule_551b's +10 on the user's party under the original
  rules — the opposing ATK sum divided by its own high byte — and not under the fixed ones:
  the dragon board shows it; a board with the party surrounded every frame stalled the battle
  — no enemy decision in 5,000 frames — and was dropped.)
At every enemy rule chain the WRAM / HRAM the chain walker starts from is captured
(AIState7ChainWalker_7865) with the chain's end ($78A2 / the veto $788B), and:
  model    the Balance simulator (simulator/ai_rules.evaluate_chain with the project's
           switches) on that board == the live chain end — for every chain;
  differs  the same image run by the ORIGINAL rules (simulator/rom_rules.Oracle over a ROM
           copy whose five regions are the original bytes) decides otherwise on some chains of
           each board, and the switches explain it (the model without them == the original);
  casts    on the lone board the TACTICIAN casts Bang less often than the original rules'
           chains would rank it (counts).

  python3 tools/walk_aifix.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative]

--negative: the five regions put back to the original bytes in the ROM copy: the `model`
checks (the model WITH the switches) must FAIL wherever the fixes matter.
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
sys.path.insert(0, os.path.join(REPO, 'simulator'))
from tools.walk_regions import s_continue                                    # noqa: E402
from tools.walk_mirror import MirrorWalk                                     # noqa: E402
from tools.walk_skills import w16                                            # noqa: E402
from editor2.core import ai_fixes as AF                                      # noqa: E402
import ai_rules as R                                                         # noqa: E402
from rom_rules import Oracle                                                 # noqa: E402
from validate_ai_fixes import view_of_wram, REC                              # noqa: E402

HP = 0xDBA3
# one instruction into each (walk_mirror.spar hooks the heads themselves): the walker's
# `ld l, a` ($7868, nothing written yet), the chain end's `add l` ($78A8, after CustomAI57 /
# the $DCE4 pointer: $DD26 / $DD27 final), the veto's `ld [$dd26], a` ($788C, the veto)
WALKER, CHAIN_END, VETO = (0x57, 0x7868), (0x57, 0x78A8), (0x57, 0x788C)
BANG = 6
DRAGON_SPECIES = 20                     # DragonKid (family 1: DrakSlash's)


def boards():
    def lone(m):
        for j in (1, 2):                    # the FIRST opposing slot is the one left
            w16(m, HP + 2 * j, 0)
            m[0xDD1B + j] = 1

    def dragon(m):
        m[0xDC3C + 1] = DRAGON_SPECIES

    def buffed(m):
        m[0xDB00 + 8 * 2 + 3] |= 0x04
        for j in (0, 1):
            m[0xDB00 + 8 * j + 3] &= ~0x3C

    return {'lone': lone, 'dragon': dragon, 'buffed': buffed}


def run_board(w, eid, board, frames=5000, seed=0x1234):
    m = w.m
    caps = []
    cur = {}

    def at_walker(_m):
        if m[0xDB88] >= 4:
            cur['w'] = bytes(m[0xC000 + i] for i in range(0x2000))
            cur['h'] = bytes(m[0xFF80 + i] for i in range(0x7F))
            cur['info'] = (m[0xDD6A], m[0xDB88], m[0xDB8A], m[0xDD6B])

    def at_end(kind):
        def f(_m):
            if 'w' in cur and m[0xDB88] >= 4:
                caps.append(dict(cur, end=(kind, m[0xDD26], m[0xDD27])))
                cur.clear()
        return f
    hooks = [WALKER + (at_walker,), CHAIN_END + (at_end('end'),), VETO + (at_end('vet'),)]
    log = w.spar(eid, frames=frames, seed=seed, board=board, always=board, hooks=hooks,
                 snap_ids=set())
    return caps, log


def outcome(end):
    kind, b, p = end
    if kind == 'vet':
        return (0, True)
    return (0, True) if b < p else ((b - p) & 0xFF, False)


DEBUG = os.environ.get('WALK_DEBUG')


def judge(w, caps, fixes):
    """-> (chains, chains where the model is exact for the ORIGINAL rules (model without the
    switches == the original-rules ROM on the same image), model-with-switches mismatches
    there, chains there the original rules decide otherwise). A chain where the S163 model is
    not exact for the original rules (a rule it does not model — $4DF9, $4B8C …) says nothing
    about the switches and is set aside (counted)."""
    bad, differ, exact = [], 0, 0
    for c in caps:
        cat, actor, sid, dd6b = c['info']
        f = (REC.get(sid) or {}).get('battle_record', {}).get('fields', {})
        cost = REC.get(sid, {}).get('mp_cost', 0)
        cost = cost if isinstance(cost, int) else 0
        view = view_of_wram(c['w'])

        def model(fx):
            return R.evaluate_chain(cat, sid, actor, view, cost, f.get('status_id', 0), dd6b,
                                    fixes=fx)
        live = outcome(c['end'])
        _f, oe = w.orig.chain(c['w'], c['h'])
        orig = oe and outcome(oe)
        if DEBUG:
            print('   ', sid, REC.get(sid, {}).get('name'), 'live', live, 'orig', orig,
                  'model+', model(fixes), 'model0', model(frozenset()),
                  'fired', [(hex(x[0]), x[1], x[2]) for x in _f])
        if orig is None or model(frozenset()) != orig:
            continue
        exact += 1
        if model(fixes) != live:
            bad.append((sid, live, model(fixes)))
        if orig != live:
            differ += 1
    return len(caps), exact, bad, differ


def s_boards(w):
    for name, fn in boards().items():
        eid = w.eids['warden'] if name == 'dragon' else w.eids['tactician']
        w.start('start')
        caps, log = run_board(w, eid, fn)
        n, exact, bad, differ = judge(w, caps, w.fixes)
        w.check(f'{name}: {n} enemy rule chains captured live ({exact} where the S163 model is '
                f'exact for the original rules); there the Balance simulator WITH the switches '
                f'== the live chain end', exact >= 4 and not bad,
                f'{len(bad)} differ: {bad[:4]}; decisions {len(log["dec"])}, start {log["start"]}')
        w.check(f'{name}: the ORIGINAL rules (the same images run by a ROM with the original '
                f'bytes) decide otherwise on {differ} of them — the switches act in the live game',
                differ >= 1, f'{differ} / {exact}')
        if name == 'lone':
            fixed = sum(1 for c in caps if c['info'][2] == BANG and not outcome(c['end'])[1])
            o_ok = 0
            for c in caps:
                if c['info'][2] == BANG:
                    _f, oe = w.orig.chain(c['w'], c['h'])
                    if oe is not None and not outcome(oe)[1]:
                        o_ok += 1
            sc_f = [outcome(c['end'])[0] for c in caps if c['info'][2] == BANG]
            sc_o = []
            for c in caps:
                if c['info'][2] == BANG:
                    _f, oe = w.orig.chain(c['w'], c['h'])
                    sc_o.append(outcome(oe)[0] if oe else None)
            w.check('lone: Bang scores lower under the fixed rules against one foe (no +20 for a '
                    'group spell: 2+ foes are not there)', sc_f and all(
                        a < b for a, b in zip(sc_f, sc_o) if b is not None),
                    f'fixed {sc_f[:6]} vs original {sc_o[:6]} (kept {fixed} / {o_ok})')


def negative_rom(w):
    from editor2.core.compiler import splice                      # noqa: F401 (doc: same regions)
    rom = bytearray(open(w.rom, 'rb').read())
    orig = open(w.orig_rom, 'rb').read()
    b = 0x57 * 0x4000
    rom[b:b + 0x4000] = orig[b:b + 0x4000]
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print('NEGATIVE CONTROL: bank $57 of the ROM copy = the original rules (the five regions '
          'off)')


def orig_rules_rom(w, keep):
    """The ROM copy with bank $57's five regions back to the original text (the build's own
    other bytes): the demo rebuilt? — no: the regions only change bank $57, so the original
    rules = bank $57 of a build without switches (any project, the same bank $57 otherwise)."""
    rom = bytearray(open(w.rom, 'rb').read())
    src = w.args.orig_bank57
    o = open(src, 'rb').read()
    b = 0x57 * 0x4000
    rom[b:b + 0x4000] = o[b:b + 0x4000]
    path = os.path.join(keep, 'orig_rules.gbc')
    open(path, 'wb').write(rom)
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--orig-bank57', required=True,
                    help='a ROM built WITHOUT switches (its bank $57 = the original rules; the '
                         'regions are the only bank $57 bytes the switches change)')
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = MirrorWalk(a.build, a.sav, a.keep)
    w.args = a
    w.basemap = {}                     # spar's default snapshot set (none here)
    d = json.load(open(a.project))
    from editor2.core.project import Project
    prj = Project(d, os.path.dirname(os.path.abspath(a.project)))
    prj.repo_root = REPO
    w.eids = {e['id']: e['_eid'] for e in prj.quest_enemy_rows()}
    w.fixes = AF.fixes_of(prj)
    w.orig_rom = orig_rules_rom(w, a.keep)
    from tools.walk_regions import read_sym
    w.orig = Oracle(open(w.orig_rom, 'rb').read(), read_sym(os.path.join(a.build, 'game.sym')))
    print('switches ON:', ', '.join(sorted(w.fixes)) or 'none')
    if a.negative:
        negative_rom(w)
    s_continue(w)
    w.save('start')
    try:
        s_boards(w)
    except Exception as e:                           # noqa: BLE001
        import traceback
        traceback.print_exc()
        w.check('boards ran', False, repr(e))
    print(f'WALK: {"PASS" if not w.fails else "FAIL " + str(w.fails)} ({w.checks} checks)')
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
