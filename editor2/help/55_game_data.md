# Game data (monsters, skills, breeding)

The game's own tables — every monster's family, growth and resistances,
the wild and boss battle rows, the gate encounter lists, skills (MP cost,
learning requirements, power), the experience and growth curves and the
breeding recipes — can be changed by the project.

**Today these are edited in `project.json` (the `gamedata` section); the
Monsters / Skills / Breeding / Encounters tabs that edit them in the editor
come next.** The project only stores what you change: an empty `gamedata`
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
the other families keep the game's own 16 each). In `project.json` these are
`gamedata.monsters.<id>.family` (`"Spirit"` or 0-10) and
`gamedata.families.<family>.dialogue` (`A`-`D` or a family name) /
`gamedata.families.spirit.names`. Everything that shows or uses a family follows: the
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
