# Dragon Warrior Monsters randomizer

Standalone. Rewrites **data tables only** — no code patches, no script edits, no
text-engine changes beyond the library recipe strings. The SRAM layout and every
engine routine stay vanilla, so **existing saves keep working** and survive a
reseed.

Runs unmodified on both known builds:

| Build | MD5 |
|---|---|
| English (US/EU) | `1ca6579359f21d8e27b446f865bf6b83` |
| German (SGB Enhanced) | `08bca718c62e3c2870a2df107fc0a562` |

## Usage

```
python3 randomizer/randomize_rom.py data/DWM-german.gbc --seed 20260806 \
    --out out/DWM-german-rando.gbc
```

Writes the ROM plus `<out>.spoiler.txt` and `<out>.spoiler.json`. Output is
deterministic for a given seed and input.

Check an edited ROM never got harder than vanilla:

```
python3 randomizer/audit_threat.py data/DWM-german.gbc out/DWM-german-rando.gbc
```

Non-zero exit if any of the 487 enemy rows deals more skill damage than vanilla.
Useful against any edited ROM, not just randomized ones.

## What it randomizes

| # | Thing | How |
|---|---|---|
| 1 | Boss identity + moves | enemy-stats row species + 4 skill bytes; scripts untouched |
| 2 | Boss joinability | row `+3` shuffled; first three gate bosses pinned to always-join |
| 3 | Breeding | 197 family pairs deranged among slots; 825 special results deranged |
| 4 | Encounter tables | live pool slots permuted within EXACT level groups |
| 5 | Natural skills | 663 slots redistributed, global multiset preserved |
| 6 | Stat growth | all six curve columns globally shuffled across species |
| 7 | Resistances | scrambled within tier buckets (see `--resistances`) |
| 8 | Exp curves | the 100-exp-to-level-2 tier (24–31) remapped onto the 10-exp tier (16–23) |
| 9 | Arena | all 90 roster rows + the King fight re-skinned, no duplicate species per match |
| — | Starter | random species, guaranteed able to learn Heal early |

## Design invariants

**Power is preserved by construction.** Every enemy row keeps its vanilla level,
six stat words and exp reward. Only identity, moves and joinability change. Enemy
moves are re-rolled slot by slot against the *enemy-side* power pair
(`SkillRecordData` `$54:$41CF` +15/+17), matching kind, target breadth (one foe
vs all foes) and damage, with an asymmetric band — up to 35% weaker, never
stronger.

**Full heals are banned on bosses and arena entrants.** Skills 45, 47 and 163
(power 999) never appear on any of the 169 boss / arena / boss-join rows, and no
heal may exceed a row's own max HP.

**Every species reachable in vanilla stays reachable.** A breeding-closure
fixpoint (wild recruits + boss joins + starter, closed under both recipe tables)
is compared against the vanilla closure and gaps are repaired.

**The library text is kept honest.** The recipe strings baked into bank `$4D`
(entry = species + 5) are regenerated from the randomized family table, so the
words match the parent sprites.

**Rival/summon species are excluded everywhere.** Species 215–220 (TERRY?, Tatsu,
Diago, Samsi, Bazoo, #220) have level cap 0 and can never be raised.

## Options worth knowing

| Flag | Default | Effect |
|---|---|---|
| `--seed N` | random | reproducibility |
| `--resistances tier\|vector\|global` | `tier` | `tier` and `vector` preserve each species' resistance mass; `global` shuffles all 27 columns across every species — maximum chaos, but it flattens the vanilla difficulty curve, because enemy resistances load from this same table |
| `--skills bands\|random` | `bands` | natural-skill redistribution: matched to monster tier, or fully random |
| `--enemy-skills species\|random` | `species` | prefer moves the new species could actually learn |
| `--enemy-skill-down` / `--enemy-skill-up` | `0.35` / `0.0` | enemy move power band |
| `--heal-cap` | `1.0` | max heal on a protected row, as a fraction of its own HP |
| `--encounter-spread` | `0` | levels an encounter slot may drift (0 = same level only) |
| `--starter N` / `--starter-min-cap` | random / `20` | pin the starter species |
| `--allow-metal-bosses` | off | let Metaly/Metabble/MetalKing be bosses |
| `--no-force-join-first3` | off | stop pinning gate bosses 11/31/32 to always-join |
| `--no-library-text` | off | leave bank `$4D` strings vanilla (they will then disagree with the sprites) |
| `--no-<pass>` | off | skip any individual pass |

## Validation

Two gates, both runnable against any edited ROM:

```
python3 randomizer/profile_check.py <vanilla.gbc> <edited.gbc>   # per-entity envelopes
python3 randomizer/audit_threat.py  <vanilla.gbc> <edited.gbc>   # per-row damage parity
```

`profile_check` is the important one. Every check this project had before S77 was
an aggregate, and aggregates are blind to individual outliers — a species at 23x
vanilla MP growth preserves every distribution being measured. It checks growth
envelopes, skill usage frequency, skill placement floors, base-monster recipes,
per-row threat and pool duplicates, and exits non-zero.

## Additional options (S77)

| Flag | Default | Effect |
|---|---|---|
| `--growth-bands` | `10` | bands of the vanilla growth ordering to shuffle within; lower = closer to vanilla |
| `--easy-level` | `6` | species first met at or below this level stay base monsters (no specific x specific recipe) |
| `--join-jitter` | `0.28` | looseness of the level bias on boss joinability |
| `--strat-jitter-boss/arena/wild` | `0.06/0.10/0.25` | looseness of level-vs-quality stratification |
| `--growth-bias` | off | bias growth by breeding depth so the first breed step is stronger |
| `--no-caster-plus` | off | disable the MP/INT plus-bonus code change |

## Reference

- Region portability, the bank `$14` `+$70` shift, German charmap — `documentation/DATA_STRUCTURES.md` §"Region portability"
- Library recipe text format — `documentation/BREEDING_SYSTEM.md` §"Library recipe TEXT"
- Power calibration numbers — `documentation/BATTLE_SKILL_SYSTEM.md` §"Power calibration"
- Exp/growth curve structure — `documentation/MONSTER_DATA.md` §"Exp curves & growth curves"
- Editor requirements — `documentation/PROJECT_COMPILER.md` §"Coherence sets the editor must maintain"
