# Resistances (and Earth)

The **Resistances** tab shows every monster's 27 resistances at once and, for each
resistance, what it protects against and which skills test it — including the
changes you make. (The Monsters tab shows the same levels for one monster.)

## What a level does

Every monster has a level **0-3** in each resistance: **0** = none (the full effect),
**1** = some, **2** = strong, **3** = immune. A skill reads ONE resistance of its target
through one of the game's ladders:

| level | spell damage | breath damage | elemental slash | hit chance | status ladder |
|---|---|---|---|---|---|
| 0 | ×1 | ×1 | ×1.31 | always | 75 % |
| 1 | ×0.85 | ×0.75 | ×1.16 | 84 % | 50 % |
| 2 | ×0.5 | ×0.4 | ×0.75 | 50 % | 25 % |
| 3 | 0 | 0 | ×0.3 | never | never |

(An elemental slash — FireSlash, BoltSlash, VacuSlash, IceSlash — hits a target with
no resistance HARDER than a plain hit: the game's own rule. Guard skills and a few
marks change these rows in battle.) The tab's right side shows the ladders the
selected resistance's skills actually use.

**Enemies use their species' levels** — there is no per-enemy copy, so a change hits
every enemy of that species. A monster you **already own** keeps the levels it was made
with; a new one (a join, a gift, an egg) starts from its species' row (breeding can add
to that from the parents).

## The groups

The 27 are shown in six groups (the stored names are the community FAQ's, kept so old
projects load; the brackets say what each is):

- **Elemental spells** — Fire (the **Blaze** line), Heat (the **Firebal** line — a
  separate resistance in the game: fire *spells* and *fireballs* are told apart),
  Explosion (Bang line), Wind (Infernos line, Vacuum, WindBeast, the wind slashes),
  Lightning (Bolt / Zap / Thordain, Lightning, Hellblast), Ice (IceBolt line), **Earth**.
- **Breaths** — FireBreath, IceBreath.
- **Status ailments** — Sleep, Confusion, Poison, Paralyze, Curse, Accuracy (blinding:
  Surround, SandStorm, Radiant), MissATurn (the target loses its turn: LureDance,
  LegSweep, WarCry …), Death (Beat, Defeat, K.O.Dance, EerieLite).
- **Stat down / drain** — DefDown (Sap, Defence, SickLick), AglDown (Slow, SlowAll),
  MP (RobMagic, RobDance, OddDance).
- **Seals** — SpellBlock (StopSpell), DanceBlock (DanceShut), BreathBlock (MouthShut).
- **Special attacks** — Sacrifice (Sacrifice, Kamikaze, Ramming), MegaMagic, GigaSlash,
  Aid (RockThrow and the helpers CallHelp / YellHelp bring).

## Editing levels

- Select cells — drag, Shift / Ctrl-click, or a whole column by clicking its header
  (click again to sort by it) — and press **0**, **1**, **2** or **3**, or use the
  **Set selected** buttons. **Original** puts the selected cells back to the original
  game (a new species: the monster it starts from). One undo step each time.
- Double-click a cell = its level + 1 (3 → 0).
- `*` and bold = changed from the original. The monster's name stays on the left while
  you scroll sideways.
- Filters: a name, a family, **Changed from the original**, **Your new species**,
  **TERRY? + the summons** (215-219: only their stats, moves and resistances may change).
  **Every group** / one group hides the other columns.

## Which skills test which resistance

**This resistance** (click a column or a cell) lists every skill that tests it now;
**Skills by resistance** lists them all, group by group, with **Tests no resistance**
at the end (damage skills with no element: physical attacks, most built-in custom
skills). Bold = not the original game's (a changed skill, your new skill, a built-in).

**Moving a skill:** right-click it → **Test another resistance ▸** (a group, a
resistance), **Back to its own**, or **No resistance**. Several selected skills move
together. This is the same setting as the Skills tab's **Element** (double-click a skill
to open it there). Only skills whose DAMAGE tests a resistance can move — the 38 damage
skills of the game (measured), your new skills built on one of them, and the built-in
custom damage skills (MagicBurn, Tame ×3, Tremor / Quake / QuakeMore / QuakeMost, Mourn,
LoneWolf, Punish, Finish, Rupture). A status skill (Sleep, Poison, Beat …) tests the
resistance its code picks: it is listed, but marked *fixed*. A new skill built on a
status skill tests what that skill tests.

The monster AI follows the move: an enemy does not waste a skill on a party that is
immune (level 3, every monster) to the skill's element — Earth included.

## Earth (new)

The game has a 27th resistance slot that nothing used (0 in every monster). It is now
**Earth**: give monsters an Earth level here, and give skills the Earth element —
Tremor / Quake / QuakeMore / QuakeMost (they have no element until you give them one),
a new skill (Skills tab → **New skill…** on a damage skill, then **Element → Earth**),
or a game skill moved to Earth. Earth works like the other elements: the spell ladder
for built-in and spell-based skills, the skill's own ladder otherwise; enemies use their
species' Earth; the AI reads it.

Projects made before S159 open as before (the old name "Unused" reads as Earth; every
level is 0). The memorial's statues keep working: a monster's Earth level and its
memorial mark share one byte of its record (levels 0-3 only).

Seen in a test (S159, the same before S159): an enemy whose skills were only a new skill
built on Bang never cast it — the AI picked attacks; with a game skill beside it, it cast
the game skill. Give enemies a game skill too until this is looked into.
