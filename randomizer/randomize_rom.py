#!/usr/bin/env python3
"""DWM1 randomizer -- CLI entry point.

    python3 randomizer/randomize_rom.py data/DWM-german.gbc --seed 1234 \
        --out out/DWM-german-rando.gbc

Works on the English and German builds unmodified; see randomizer/README.md.
No code patches are applied -- only the monster/enemy/encounter/breeding data
tables are rewritten, so the save format and every engine behaviour are vanilla.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from randomizer import breeding, librarytext, logic, names, plusgrowth
from randomizer.romdata import FAMILY_NAMES, Rom


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Randomize Dragon Warrior Monsters (GBC).")
    p.add_argument("rom", help="input ROM (English or German)")
    p.add_argument("--out", help="output ROM path")
    p.add_argument("--seed", type=int, default=None, help="RNG seed (default: random)")
    p.add_argument("--log", help="spoiler log path (default: alongside --out)")

    p.add_argument("--skills", choices=["bands", "random"], default="bands",
                   help="natural-skill redistribution: difficulty-banded (default) "
                        "or fully random")
    p.add_argument("--skill-bands", type=int, default=6)
    p.add_argument("--skill-jitter", type=float, default=0.15,
                   help="fraction of banded slots additionally swapped globally")
    p.add_argument("--enemy-skills", choices=["species", "random"], default="species",
                   help="enemy movesets drawn from the new species' learnable set "
                        "(default) or from any level-appropriate skill")
    p.add_argument("--encounter-spread", type=int, default=0,
                   help="how many levels an encounter slot may drift when the "
                        "pools are permuted (0 = same level only)")
    p.add_argument("--enemy-skill-down", type=float, default=0.35,
                   help="how much WEAKER a replacement enemy move may be than the "
                        "vanilla move it replaces")
    p.add_argument("--join-jitter", type=float, default=0.28,
                   help="looseness of the level bias on boss joinability "
                        "(vanilla correlates +0.62)")
    p.add_argument("--strat-jitter-boss", type=float, default=0.06)
    p.add_argument("--strat-jitter-arena", type=float, default=0.10)
    p.add_argument("--strat-jitter-wild", type=float, default=0.25,
                   help="looseness of level-vs-quality stratification; wild "
                        "needs a lot (vanilla is only +0.45)")
    p.add_argument("--easy-level", type=int, default=6,
                   help="species first encountered at or below this level are "
                        "kept as base monsters: no specific x specific recipe")
    p.add_argument("--growth-bands", type=int, default=10,
                   help="bands of the vanilla growth ordering to shuffle within; "
                        "lower = closer to vanilla, higher = more chaos")
    p.add_argument("--growth-depth-spread", type=float, default=0.30,
                   help="noise in the depth-vs-growth bias (0 = rigid ladder)")
    p.add_argument("--growth-bias", action="store_true",
                   help="leave growth as a pure global shuffle, uncorrelated "
                        "with breeding depth")
    p.add_argument("--early-skill-floor", type=int, default=20,
                   help="power budget for a species' natural skills at "
                        "first-encounter level 0")
    p.add_argument("--early-skill-slope", type=float, default=6.0,
                   help="extra natural-skill power budget per level of first "
                        "encounter")
    p.add_argument("--no-caster-plus", action="store_true",
                   help="do not extend the plus-value growth bonus to MP and INT "
                        "(this is the ONLY code change the randomizer makes; "
                        "without it, deep breeding rewards physical builds only)")
    p.add_argument("--no-library-text", action="store_true",
                   help="leave the bank $4D library recipe strings at their "
                        "vanilla values (they will then disagree with the "
                        "randomized parent sprites)")
    p.add_argument("--heal-cap", type=float, default=1.0,
                   help="on boss/arena rows, the largest heal allowed as a "
                        "fraction of that row's own max HP (full heals are "
                        "banned outright regardless)")
    p.add_argument("--enemy-skill-up", type=float, default=0.0,
                   help="how much STRONGER a LATE enemy move may be; scales from "
                        "0 at level 12 to this value at level 45, so early gates "
                        "can never exceed vanilla")
    p.add_argument("--resistances", choices=["tier", "vector", "global"], default="tier",
                   help="tier (default): permute each species' 27 values AND swap "
                        "whole vectors within a tier; vector: permute in place only; "
                        "global: shuffle all 27 columns across every species "
                        "(maximum chaos, but flattens the vanilla difficulty curve "
                        "- enemy resistances come from this same table)")

    p.add_argument("--starter", type=int, default=None,
                   help="force the starter species id (0-220)")
    p.add_argument("--starter-min-cap", type=int, default=20,
                   help="minimum level cap for a randomly chosen starter")

    p.add_argument("--no-force-join-first3", action="store_true",
                   help="do not pin the first three gate bosses (EIDs 11/31/32) "
                        "to always-join")
    p.add_argument("--allow-metal-bosses", action="store_true",
                   help="allow metal-body species (Metaly/Metabble/MetalKing) as "
                        "bosses and arena entrants; off by default because metal "
                        "body changes effective difficulty far more than stats do")

    for flag in ("natural-skills", "growth", "resistances", "exp-remap",
                 "enemy-identity", "enemy-moves", "boss-joins", "encounters",
                 "breeding", "starter-pass"):
        p.add_argument(f"--no-{flag}", action="store_true",
                       help=f"skip the {flag.replace('-', ' ')} pass")
    return p


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    seed = args.seed if args.seed is not None else random.randrange(1 << 30)
    rng = random.Random(seed)

    src = Path(args.rom)
    rom = Rom.load(src)
    raw = bytes(rom.data)
    print(f"Loaded {src.name}  md5={rom.layout.md5}")
    print(f"  {rom.layout.describe()}")

    problems = logic.validate_boss_eids(raw)
    for msg in problems:
        print(f"  WARNING: {msg}")

    label = names.load(raw, rom.layout)
    vanilla = copy.deepcopy(rom)
    universe = logic.skill_universe(rom)
    groups = logic.classify_eids(rom)
    vanilla_obtainable = logic.obtainable_species(vanilla, groups)

    rep = logic.Report()
    rep.note(f"Seed {seed}; source md5 {rom.layout.md5} ({rom.layout.region}).")
    rep.note(f"Assignable skill universe: {len(universe)} ids "
             f"(only ids vanilla actually gives to monsters or enemies).")

    if not args.no_natural_skills:
        logic.randomize_natural_skills(rom, rng, args.skills, args.skill_bands,
                                       args.skill_jitter, rep)
    if not args.no_growth:
        logic.randomize_growth(rom, rng, rep, args.growth_bands)
    if not args.no_resistances:
        logic.randomize_resistances(rom, rng, args.resistances, rep)
    if not args.no_exp_remap:
        logic.remap_exp_curves(rom, rep)
    # Joinability is decided BEFORE identity: the identity pass keeps
    # un-raisable rival species off any row the player can recruit.
    if not args.no_boss_joins:
        logic.randomize_boss_joinability(rom, rng,
                                         not args.no_force_join_first3,
                                         args.join_jitter, rep)

    # Breeding runs FIRST so the identity pass can stratify rows by real
    # breeding depth. Roots are the vanilla wild species set, which the wild
    # assignment preserves by construction, so this is not circular.
    depth = {}
    if not args.no_breeding:
        roots = {vanilla.enemies[e].species for e in groups["wild"]
                 if vanilla.enemies[e].join != 7} | {vanilla.enemies[1].species}
        easy = {vanilla.enemies[p.eids[i]].species
                for p in vanilla.pools for i in p.live_slots()
                if vanilla.enemies[p.eids[i]].level <= args.easy_level}
        stats = breeding.regenerate(rom, rng, roots, rep, easy=easy)
        depth = {s: (d if d < 99 else 9) for s, d in stats["depth"].items()}

    identity_done = False
    if not args.no_enemy_identity:
        identity_done = True
        logic.randomize_enemy_species(rom, rng, groups, args.allow_metal_bosses,
                                      depth,
                                      {"boss": args.strat_jitter_boss,
                                       "arena": args.strat_jitter_arena,
                                       "wild": args.strat_jitter_wild}, rep)
    # Second breeding pass against the FINAL roots. Identity assignment adds
    # boss-JOIN species as new tree roots (measured: 6 of them), and each one
    # shortcuts every chain that ran through it -- the first pass built to depth
    # 5 and those roots collapsed it back to 4. Re-running with the real root
    # set is what stops the tree being quietly hobbled.
    if identity_done and not args.no_breeding:
        final_roots = {rom.enemies[e].species for e in groups["wild"]
                       if rom.enemies[e].join != 7} | {rom.enemies[1].species}
        for _f, _j in rom.boss_redirect:
            if rom.enemies[_f].join != 7:
                final_roots.add(rom.enemies[_j].species)
        easy2 = {rom.enemies[p.eids[i]].species
                 for p in rom.pools for i in p.live_slots()
                 if rom.enemies[p.eids[i]].level <= args.easy_level}
        stats2 = breeding.regenerate(rom, rng, final_roots, rep, easy=easy2)
        depth = {s: (d if d < 99 else 9) for s, d in stats2["depth"].items()}

    if not args.no_enemy_moves:
        logic.assert_full_heals(rom)
        logic.randomize_enemy_skills(rom, rng, args.enemy_skills, universe,
                                     args.enemy_skill_down, args.enemy_skill_up,
                                     logic.protected_rows(rom, groups),
                                     args.heal_cap,
                                     logic.vanilla_placement(vanilla), rep)
    if not args.no_encounters:
        logic.shuffle_encounter_pools(rom, rng, args.encounter_spread, rep)
    if depth and args.growth_bias:
        logic.bias_growth_by_depth(rom, rng, depth, args.growth_depth_spread, rep)
    if not args.no_encounters:
        logic.gate_early_skills(rom, rng, args.early_skill_slope,
                                args.early_skill_floor, rep)
    if not args.no_starter_pass:
        logic.setup_starter(rom, rng, args.starter, args.starter_min_cap, rep)
    logic.enforce_obtainability(rom, rng, groups, vanilla_obtainable, rep)

    if not args.no_caster_plus:
        stats = plusgrowth.apply(rom)
        if not plusgrowth.verify(rom):
            raise SystemExit("caster-plus patch failed self-verification")
        rep.note(
            f"Caster plus bonus (THE ONLY CODE CHANGE): the vanilla plus-value "
            f"routine FuncExp_4163 is now also called after the MP and INT curve "
            f"lookups, not just HP and ATK. Byte-neutral in the growth routine "
            f"(ld [nn],a -> call nn); {stats['bytes_written']} bytes of trampoline "
            f"at ${stats['mp_trampoline']:04X}/${stats['int_trampoline']:04X} in "
            f"bank $13's free tail. Breeding depth now grows a caster's MP pool "
            f"and INT, using vanilla's own thresholds and divisors.")

    if not args.no_library_text:
        base = names._locate(raw, names.MONSTER_HINT, names.MONSTER_COUNT)
        stats = librarytext.rewrite(rom, rom.family_recipes,
                                    librarytext.NAME_BANK_BASE + (base - 0x4000))
        rep.note(
            f"Library text: all 221 bank-$4D recipe strings regenerated from the "
            f"randomized FamilyRecipeTable, so the words now match the parent "
            f"sprites. Format proven first by reconstructing {stats['verified']} "
            f"vanilla strings byte-for-byte (the {len(stats['vanilla_quirks'])} "
            f"that differ are vanilla authoring typos). "
            f"{stats['bytes_used']} of {stats['capacity']} bytes used across "
            f"{stats['blocks']} free blocks.")

    sanity(rom, rep)

    out = Path(args.out) if args.out else src.with_name(
        f"{src.stem}-rando-{seed}{src.suffix}")
    out.parent.mkdir(parents=True, exist_ok=True)
    rom.write_all()
    md5 = rom.save(out)
    print(f"\nWrote {out}  md5={md5}")

    log_path = Path(args.log) if args.log else out.with_suffix(".spoiler.txt")
    write_logs(rom, vanilla, rep, label, groups, seed, log_path)
    print(f"Wrote {log_path}")
    print(f"Wrote {log_path.with_suffix('.json')}")
    for line in rep.notes:
        print(f"  - {line}")
    return 0


def sanity(rom: Rom, rep: logic.Report) -> None:
    """Hard structural checks -- refuse to emit a ROM that can crash the engine."""
    errors = []
    for m in rom.monsters:
        if not (0 <= m.family <= 9):
            errors.append(f"species {m.id}: family {m.family}")
        if any(not 0 <= s < 222 for s in m.skills):
            errors.append(f"species {m.id}: skill id out of range {m.skills}")
        if any(not 0 <= g < 32 for g in m.growth):
            errors.append(f"species {m.id}: growth index out of range {m.growth}")
        if any(not 0 <= r <= 3 for r in m.resist):
            errors.append(f"species {m.id}: resistance value out of range")
        if not 0 <= m.exp_table < 32:
            errors.append(f"species {m.id}: exp table {m.exp_table}")
    for e in rom.enemies:
        if not 0 <= e.species < logic.SPECIES_COUNT:
            errors.append(f"EID {e.id}: species {e.species}")
        if any(s != 0xFF and not 0 <= s < 222 for s in e.skills):
            errors.append(f"EID {e.id}: skill id out of range {e.skills}")
        if any(s > 0xFFFF for s in e.stats):
            errors.append(f"EID {e.id}: stat overflow")
    for i, (a, b) in enumerate(rom.family_recipes):
        if (a, b) in ((0xFF, 0xFF), (0x00, 0x00)):
            continue  # $FFFF separator / $0000 terminator: structural, not a recipe
        for v in (a, b):
            if not (v < 222 or 0xF0 <= v <= 0xF9):
                errors.append(f"family recipe {i}: bad matcher {v:#04x}")
    for i, e in enumerate(rom.special_recipes):
        if not e[3] < logic.SPECIES_COUNT:
            errors.append(f"special recipe {i}: result {e[3]}")
    if errors:
        raise SystemExit("SANITY FAILED:\n  " + "\n  ".join(errors[:40]))
    rep.note("Sanity: all species/enemy/recipe fields inside engine-legal ranges.")


def write_logs(rom, vanilla, rep, label, groups, seed, path: Path) -> None:
    sp = label["species"]
    sk = label["skills"]
    lines = [f"Dragon Warrior Monsters randomizer -- seed {seed}", ""]
    lines += [f"* {n}" for n in rep.notes]

    lines += ["", "=" * 72, "STARTER", "=" * 72]
    s = rom.enemies[1].species
    m = rom.monsters[s]
    lines.append(f"  {sp[s]} (species {s}), {FAMILY_NAMES[m.family]}, "
                 f"level cap {m.level_cap}")
    lines.append(f"  natural skills: " + ", ".join(sk[x] for x in m.skills))

    lines += ["", "=" * 72, "BOSSES", "=" * 72]
    for eid in logic.BOSS_EIDS:
        e, o = rom.enemies[eid], vanilla.enemies[eid]
        moves = ", ".join(sk[x] for x in e.skills if x != 0xFF) or "(none)"
        join = "JOINS" if e.join != 7 else "never joins"
        lines.append(f"  EID {eid:3d}  L{e.level:<3} {sp[o.species]:>12} -> "
                     f"{sp[e.species]:<12} [{join}]  {moves}")

    lines += ["", "=" * 72, "ARENA", "=" * 72]
    classes = "G F E D C B A S".split() + ["Starry Night", "King"]
    for g in range(9):
        for match in range(3):
            base = logic.ARENA_BASE + 9 * g + 3 * match
            roster = []
            for slot in range(3):
                e = rom.enemies[base + slot]
                roster.append(f"{sp[e.species]} L{e.level}")
            lines.append(f"  class {classes[g]:>12} match {match + 1}: " +
                         " / ".join(roster))
    king = [f"{sp[rom.enemies[e].species]} L{rom.enemies[e].level}"
            for e in logic.ARENA_KING]
    lines.append(f"  class {'King':>12} final   : " + " / ".join(king))

    lines += ["", "=" * 72, "ENCOUNTER POOLS", "=" * 72]
    for p in rom.pools:
        live = p.live_slots()
        if not live:
            continue
        entries = []
        for i in live:
            e = rom.enemies[p.eids[i]]
            entries.append(f"{sp[e.species]} L{e.level} (w{p.weights[i]})")
        lines.append(f"  pool {p.id:3d}: " + ", ".join(entries))

    lines += ["", "=" * 72, "SPECIES", "=" * 72]
    for m in rom.monsters:
        v = vanilla.monsters[m.id]
        lines.append(f"  {m.id:3d} {sp[m.id]:<12} cap {m.level_cap:2d} "
                     f"exp-curve {v.exp_table}->{m.exp_table} "
                     f"growth {m.growth}")
        lines.append(f"      skills : " + ", ".join(sk[x] for x in m.skills))
        lines.append(f"      resists: " + " ".join(str(x) for x in m.resist[:26]))

    lines += ["", "=" * 72, "BREEDING -- FAMILY DEFAULTS", "=" * 72]
    for slot, (a, b) in enumerate(rom.family_recipes):
        if (a, b) in ((0xFF, 0xFF), (0x00, 0x00)) or slot >= logic.SPECIES_COUNT:
            continue
        lines.append(f"  {_matcher(a, sp)} x {_matcher(b, sp)} -> {sp[slot]}")

    lines += ["", "=" * 72, "BREEDING -- SPECIAL RECIPES", "=" * 72]
    for i, (p1, p2, plus, res, _mod) in enumerate(rom.special_recipes):
        old = vanilla.special_recipes[i][3]
        lines.append(f"  {_matcher(p1, sp)} x {_matcher(p2, sp)} (+{plus}) -> "
                     f"{sp[res]}   [was {sp[old]}]")

    for section, rows in rep.sections.items():
        lines += ["", "=" * 72, section.upper(), "=" * 72]
        lines += [f"  {r}" for r in rows]

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    payload = {
        "seed": seed,
        "source_md5": rom.layout.md5,
        "region": rom.layout.region,
        "notes": rep.notes,
        "starter": {"species": s, "name": sp[s], "skills": rom.monsters[s].skills},
        "species": [
            {"id": m.id, "name": sp[m.id], "family": m.family,
             "level_cap": m.level_cap, "exp_table": m.exp_table,
             "skills": m.skills, "growth": m.growth, "resist": m.resist}
            for m in rom.monsters],
        "enemies": [
            {"eid": e.id, "species": e.species, "name": sp[e.species],
             "level": e.level, "join": e.join, "skills": e.skills}
            for e in rom.enemies],
        "pools": [{"pool": p.id, "eids": p.eids, "weights": p.weights}
                  for p in rom.pools],
        "family_recipes": rom.family_recipes,
        "special_recipes": rom.special_recipes,
        "boss_redirect": rom.boss_redirect,
    }
    path.with_suffix(".json").write_text(json.dumps(payload, indent=1), encoding="utf-8")


def _matcher(v: int, sp: list[str]) -> str:
    if v >= 0xF0:
        return f"[{FAMILY_NAMES[v - 0xF0]}]"
    return sp[v] if v < len(sp) else f"#{v}"


if __name__ == "__main__":
    raise SystemExit(main())
