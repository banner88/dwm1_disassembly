# Monsters

The **Monsters** tab lists every monster: your new species first, then the
215 original monsters, then the 6 that only exist in battles (the rival
TERRY?, the four summons, one unused slot). Each shows its walking picture;
type in the box at the top to find one by name or number. Selecting one shows
its battle picture and its four walking directions (animated) and three pages.

**What a "species" is in this game.** Every Slime shares the Slime species:
family, level cap, exp curve, how often it is female, whether it flies or has
a metal body, its tier, the three skills it learns by itself, the six growth
curves and the 27 resistances. A species has **no fighting stats of its
own** — HP, ATK, exp reward, battle skills and AI belong to each **enemy row**
(the wild Slime of a gate, a boss, an arena fighter, the starter …). A monster
that joins you copies the stats and AI of the row it joined from (each one
rolled to 80-100 %).

## Species page

- **Family** — the same as moving it on the Families tab (library tab,
  breeding, arena dialogue, default names follow). Combat-only entries cannot
  change family.
- **Level cap**, **Exp curve** (32 curves; the box shows what level 99 needs,
  and how many species use that curve), **Female**, **flies** (LegSweep and
  the Earthquake skills miss it), **metal body**, **Tier** (0 starter, 3-6
  normal, 7 endgame boss).
- **Learns by itself** — the three natural skills. The level and stats each
  skill needs, and what it upgrades into, belong to the skill (Skills tab).
  A monster learns them when it levels up and meets those needs — not when
  it joins.
- **Growth** — which of the 32 growth curves each stat uses; the chart shows
  the six stats from level 1 to 99. The curves are shared, so this only
  changes this species. Growth matters for monsters you raise; enemies use
  their row's stats.
- **Resistances** — none (full effect), some (−15 %), strong (−50 %),
  immune. (Breath attacks: 1 / 0.75 / 0.4 / 0; status effects: always /
  85 % / 50 % / never.)
- **Reset** puts the species back as in the original game (a new species:
  back to the monster it starts from). Changed resistances are bold.

## Where you meet it

Every enemy row of the species with where the game uses it: gate encounter
lists (your project's), gate bosses and their join versions, arena classes,
coliseum / random / mimic battles, script battles, the starter, and your own
enemies. Double-click a number to change it: level, HP, MP, ATK, DEF, AGL,
INT, exp reward, **Joins** (0 = always, 7 = never, anything else = a chance),
**AI weights** (four numbers 0-255) and **Battle skills** (up to 4 skill
names, separated by commas). Bold rows differ from the original game. Only
the changes are saved (`gamedata.enemies`); your own enemies are edited in
`progression.enemies`, like in the Enemies dialog.

## New species from a sprite sheet

**New species from a sprite sheet…** (below the list) opens a sheet — any
PNG where each monster is a battle pose with its six walking frames to its
right (two columns: frame a / b; rows: facing down, sideways, up), on a plain
background colour, like the DWM2 family sheets. The editor finds every
monster on the sheet and outlines it; click one:

- the **red box** is the battle pose — drag it, drag its corner square to
  resize it (or Shift + arrow keys); the **cyan / blue squares** are the
  walking frames — drag any of them; arrow keys move the selected box one
  pixel. **Add boxes here** makes a new set of boxes for a monster the
  reader missed (sheets where a monster has only one column of frames, for
  example).
- the right side shows exactly what the game will draw. **Battle**: 48 × 48
  on the cream backdrop. A battle monster has 4 colours: black, the cream
  (the game uses it for the backdrop AND for white / cream parts of the
  monster — every original monster does), and two free colours. A sheet
  monster drawn in black, white and two colours comes out exactly; extra
  colours merge into the nearest. Click a free colour square to change it,
  **Auto colours** to go back. A pose bigger than
  48 × 48 is shrunk (the note turns red) — tighten the red box to crop
  instead. **Walking**: the game has 8 shared walking palettes (cream, one
  colour, black); the editor picks the closest, you can pick another. It
  stores 4 frames (down, sideways a and b, up); the second down / up frame is
  the first mirrored, like the original monsters that walk this way.
- name (up to 9 letters), nickname (4), the id (221-239), **Copy data from**
  (the original monster whose family, level cap, growth, resistances, 3 skills
  and library text the new one starts with — only the art is new; change any
  of it on the Species page afterwards; default Dragon) and its family.

**Create species** copies the sheet into the project (`assets/sheets/`), writes
the two art files (`assets/species/`) and remembers the boxes, so **Re-cut the
art from a sprite sheet…** (Name & art page) reopens the same monster with the
same boxes. One undo step removes all of it.

## Name & art (new species)

Name, nickname, whose library description it uses, its walking palette and
battle colours, re-cut the art, **Remove this species** (refused while an
enemy, a monster NPC or a breeding recipe still uses it). The encyclopedia
recipe is the first special breeding recipe that makes it (Breeding).

The meters under the list: new species used of 19, the bytes their names
take of the ≈ 290 the game has free, and the art bytes of the 16 KB art bank.

## Putting a monster in a gate

A wild monster is an **enemy row** in a gate floor's **encounter list**.

1. On **Where you meet it**, click **New enemy row for this monster** (a new
   species has no row yet). It starts as a copy of the monster's first original
   row, or of the gentle wild Slime; set its level, stats, exp and **Joins** in
   the table.
2. Select the row and click **Put the selected row in a gate…**. Pick the gate
   floors (some lists serve several floors or gates — the name says which). The
   first free slot is selected: **Put … in the selected slot**, then set the
   chances so the **total is exactly 100 %** (every original list is). "Real
   chance" shows what each slot really gets. OK — one undo step.
3. Build. The row's "Where" column now names the gate.

For a boss, use the row in a boss floor's conversation (Battle step — Boss
floors help). The full Encounters tab (all lists at once, list size, rate,
monsters per battle) comes later.

