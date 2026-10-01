# Game data (monsters, skills, breeding)

The game's own tables — every monster's family, growth and resistances,
the wild and boss battle rows, the gate encounter lists, skills (MP cost,
learning requirements, power), the experience and growth curves and the
breeding recipes — can be changed by the project.

**The Monsters tab edits the species rows and the battle rows, and puts a
row into a gate's wild list (Monsters help); skills, breeding and the rest of
the encounter lists are still edited in `project.json` (the `gamedata`
section) until their tabs come.** The project only stores what you change: an empty `gamedata`
is the original game.

What the build does for you:

- **Library text follows the recipe.** Change how a monster is bred and the
  encyclopedia page shows the new parents (the game stores that text
  separately — the build rewrites it).
- **Library tabs follow the family.** Move a monster to another family and
  it is listed under that family's tab.
- **Checks that stop the build** (ERROR): values the game cannot use (a
  growth curve above 31, a learning row for the four skills that have none,
  a monster family of a combat-only species), encounter lists whose chances
  do not add up to 100 %, an encounter slot without a monster, a list that
  would make the game draw the second or third monster forever (freeze), a
  breeding recipe that can never happen because an earlier one always wins.
- **Warnings** (WARN): changing a battle row's species also changes its
  resistances (they belong to the species); changing a boss's species
  without its join row; the same monster twice in one encounter list.

**Families** (the **Families** tab). There are 11: Slime, Dragon, Beast,
Bird, Plant, Bug, Devil, Zombie, Material, ??? (Boss) and **Spirit**. Spirit
has no members in the original game. On the tab: pick a family, see its
monsters, move one to another family or add any monster to it; choose how
the family's monsters talk in the arena lobby (the game has four sets of
lines: Slime / Plant / Zombie, Dragon / Bird / Material, Beast / Bug / Devil,
???); for Spirit, its 8 default names — when a monster joins or hatches, the
naming screen fills in one of its family's names at random (up to 4 letters;
the other families keep the game's own 16 each); and every family's **icon**
— an 8 × 8 picture in 4 shades (1 = the cream background, 3 = black, 0 and 2
take each screen's own colours: green on the INFO page, orange and gold in
the continue box and the JOURNAL). Paint it with the left mouse button, pick
a shade with the right one, or import an 8 × 8 PNG (darkest colour → black,
lightest → background); **Back to the original icon** undoes it. The game
shows the one picture everywhere: the INFO page, the library tabs, family
recipes, the field status bar, lists, the JOURNAL and the continue box. In
`project.json` these are
`gamedata.monsters.<id>.family` (`"Spirit"` or 0-10) and
`gamedata.families.<family>.dialogue` (`A`-`D` or a family name) /
`gamedata.families.spirit.names` / `gamedata.families.<family>.icon` (8 rows of 8
digits 0-3). Everything that shows or uses a family follows: the
library tab and recipe text, the INFO page and status icon, the arena lobby
dialogue, the default names offered when you name a new monster, and
breeding. In a breeding recipe write `"Spirit"` as either parent. (The old
`"AnyFamily"` spelling is gone: that code now means Spirit.)

A monster you already own keeps, on its INFO page and status icon, the family
it had when it joined (the game stores it with the monster); breeding, the
arena dialogue and the library use the species' family at once. Monsters that
join or hatch after the change show the new one everywhere.

The six species that only exist in battles (the rival TERRY?, the four
summons and one unused slot) cannot be moved to another family or given a
breeding recipe.

**New monsters** (`custom.species` in `project.json`; the Monsters tab
makes them from a sprite sheet — Monsters help). A project can add up to **19** brand-new monsters,
ids **221-239**, in any order and with gaps (0-220 are the original monsters;
240 and up are impossible in this game). A project without one builds the
original game's data: since S105 no test monster is built into every project
any more. An entry gives:

- `id` (221-239, each once);
- `name` (up to 9 letters) and `short_name` (up to 4 — the name the naming
  screen suggests and the "take X with you" line; default = first 4 letters);
- `info` — start from an existing monster's row (`clone_from`) and change
  any of the same fields as `gamedata.monsters` (family, growth, resistances,
  skills, level cap …);
- `description_from` — the encyclopedia description of an existing monster;
- `battle` — its battle picture (`art`: an art file in the project's
  assets, `palette`: 4 colours, the 2nd is the cream backdrop and the 4th
  black) and `follower` — its walking picture (`art`), which monster it
  walks like (`walks_like`, one of the monsters 128-214) and its colour
  (`palette`, 0-7). The Monsters tab writes these from a sprite sheet and
  records the boxes it used under `source`.

Its wild or boss battle rows are ordinary **project enemies** with that
species (Enemies help). An encounter list can name a project enemy by its
id. The encyclopedia shows the recipe that really breeds it (the first
breeding recipe with it as the result), or "?????" if nothing does.

**Custom skills work in every project.** The dialogs of the field skill
Anchor ("Set an anchor here …", "No anchor is set!") are built into the
editor and added to every build — they no longer need a room of the example
project. They take the first free text numbers after your own dialogue.
