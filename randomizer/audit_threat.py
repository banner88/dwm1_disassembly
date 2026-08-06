#!/usr/bin/env python3
"""Threat-parity audit: prove a randomized ROM is no more dangerous than vanilla.

This exists because of a real regression (S76): the first version of the enemy
moveset pass gated replacements on `SkillLearnReqTable`, which is a LEARN gate,
not a DAMAGE gate.  Breath skills are species-gated in vanilla rather than
stat-gated, so level-2 enemies passed the check for FireAir and then hit the
whole party for a flat 10-16 -- Gate of Beginning became unsurvivable while
every stat in the ROM was still "preserved".

    python3 randomizer/audit_threat.py data/DWM-german.gbc out/DWM-german-rando.gbc

Reports, per encounter pool and per boss, the worst-case incoming damage from
the enemy-side power pair, and flags any pool that got harder.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from randomizer import logic, names
from randomizer.romdata import Rom


def worst_skill(rom: Rom, enemy) -> tuple[int, str]:
    """Highest enemy-side damage this row can deal with a single move."""
    best, who = 0, "-"
    for sid in enemy.skills:
        if sid == 0xFF:
            continue
        rec = rom.skill_records[sid]
        if not rec.is_damaging:
            continue
        # An all-foes move is counted at full value against each party member.
        if rec.enemy_max > best:
            best, who = rec.enemy_max, sid
    return best, who


def pool_threat(rom: Rom, pool) -> tuple[int, int, list]:
    rows = []
    max_skill = max_atk = 0
    for i in pool.live_slots():
        e = rom.enemies[pool.eids[i]]
        dmg, sid = worst_skill(rom, e)
        rows.append((pool.eids[i], e.level, e.species, e.stats[2], dmg, sid))
        max_skill = max(max_skill, dmg)
        max_atk = max(max_atk, e.stats[2])
    return max_skill, max_atk, rows


def main(argv) -> int:
    if len(argv) < 3:
        print(__doc__)
        return 2
    van = Rom.load(argv[1])
    new = Rom.load(argv[2])
    nm = names.load(open(argv[2], "rb").read())
    sp, sk = nm["species"], nm["skills"]

    # --- primary check: per-ROW parity. This is the invariant the design
    # actually guarantees. Pool-level maxima move around simply because EIDs are
    # permuted between pools of the SAME level, which is not a regression.
    worse = []
    for eid in range(len(new.enemies)):
        vd, _ = worst_skill(van, van.enemies[eid])
        nd, _ = worst_skill(new, new.enemies[eid])
        if nd > vd:
            worse.append((eid, vd, nd))
    print(f"ROW PARITY: {len(worse)} of {len(new.enemies)} enemy rows deal more "
          f"skill damage than vanilla")
    for eid, vd, nd in worse[:20]:
        print(f"  EID {eid:3d} {sp[new.enemies[eid].species]:<13} {vd} -> {nd}")
    print()

    print(f"{'pool':>5} {'lvl':>7} | {'vanilla':>18} | {'randomized':>18} | verdict")
    print("-" * 82)
    regressions = []
    for pid in range(len(new.pools)):
        if not new.pools[pid].live_slots():
            continue
        vs, va, _ = pool_threat(van, van.pools[pid])
        ns, na, rows = pool_threat(new, new.pools[pid])
        lv = f"{min(r[1] for r in rows)}-{max(r[1] for r in rows)}"
        verdict = "ok"
        if ns > vs or na > va:
            verdict = f"HARDER (skill {vs}->{ns}, atk {va}->{na})"
            regressions.append(pid)
        print(f"{pid:5d} {lv:>7} | skill {vs:3d} atk {va:4d} | "
              f"skill {ns:3d} atk {na:4d} | {verdict}")

    print("\nFirst four pools in detail (randomized):")
    for pid in range(4):
        for eid, lvl, species, atk, dmg, sid in pool_threat(new, new.pools[pid])[2]:
            move = sk[sid] if sid != "-" else "-"
            print(f"  pool {pid} EID {eid:3d} L{lvl:<3} {sp[species]:<13} "
                  f"ATK {atk:3d}  worst move {move} ({dmg})")

    print("\nBosses:")
    bad = 0
    for eid in logic.BOSS_EIDS:
        v, n = van.enemies[eid], new.enemies[eid]
        vd, _ = worst_skill(van, v)
        nd, _ = worst_skill(new, n)
        tag = ""
        if nd > vd:
            tag = f"  <-- HARDER ({vd} -> {nd})"
            bad += 1
        print(f"  EID {eid:3d} L{n.level:<3} {sp[n.species]:<13} worst move "
              f"{nd:3d} (vanilla {vd:3d}){tag}")

    print(f"\npool-max drift (informational, EIDs permute between same-level "
          f"pools): {len(regressions)} pools")
    print(f"bosses that got harder: {bad}")
    print(f"ENEMY ROWS THAT GOT HARDER: {len(worse)}  <-- this is the check that matters")
    return 1 if (worse or bad) else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
