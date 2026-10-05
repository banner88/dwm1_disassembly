# Gate themes — the maze looks in your own rooms

The gates' random floors come in **16 looks** (the game's *floor types*):
grassland, grey rock, sand, red rock, ice blocks, purple brick (two), yellow
brick, boulders, forest, yellow brick and tiles, green mountains (two), sea
islands (two) and snowy mountains. Any of them can be the **tiles and
colours of a room of your own** — a **Gate theme**.

**New room** → *Or a gate theme*: pick one. The room draws with that theme's
tiles in the theme's own colours (a new palette for the room, editable like
any other — e.g. make a night version) and starts as one screen of the
theme's plain floor. Its **Metatiles** picker offers the maze's own pieces,
already in the right colours: walls, floors, water, trees, mounds, rocks, and
the maze stairs.

**Change tileset → A gate theme** does the same for a room you already have.
*and the theme's colours* (ticked) makes the theme's colours the room's
palette; screens / states with a palette of their own keep it. The screens
keep their tile numbers — repaint them, or use *Maze screen…*.

**Maze screen…** (on the screen / state row, next to *+ Add state*): fills
this screen (this state) with one of the **254 screens** the gates' mazes are
made of. Each maze *piece* is a set of open sides (↑ ↓ ← →) drawn 13 ways;
the ready-made *pattern floors* have screens of their own. Tick the sides a
screen must open to (*exactly these sides* for just those); the pictures are
in the room's theme (or any theme you choose). The tiles AND the palette
slots are replaced; exits, NPCs and doors stay. Undo brings the old screen
back. In a room that is not on a gate theme the screen shows that room's own
tiles in those places — change the tileset first.

**Borrow** works both ways: the 16 themes are in the Borrow list (*Gate theme
N: …*), so a theme's metatiles can be brought into any room; and a theme
room can borrow from any game room. Every theme uses sheet slots $00-$3F;
**$40-$7F (64 slots) are free** for borrowed or imported tiles.

**Stairs down here** in a theme room paints the theme's own stairs (the same
picture the game puts on a maze floor) — no import. The picture is only a
picture: the *Stairs down* exit on that cell is what takes the player down.

Good to know:

- The red, blue and brown "damage" floors of themes 3, 6, 12 and 14 do **no
  damage** in your rooms — the game hurts only on its own maze floors.
- Theme rooms do not animate (the maze floors never do).
- Copies of a theme sheet (*Own copy of the current tileset*) stay the theme.

## How the gates build a floor (traced S122)

A maze floor is made fresh on every visit from a 4 × 4 grid of screens:

- 3 floors in 5 are **carved**: a first piece in the middle, then up to
  *maze size* more pieces that fit the open sides of their neighbours; then
  every screen is closed off where nothing joins it — so a floor is always
  one connected maze of 2 to *maze size* + 1 screens.
- 1 in 5 is carved with the **plain** drawing of every piece; 1 in 5 is one of
  **21 ready-made pattern floors**.
- Then the **stairs** (never where they would block a corridor), a **wandering
  NPC** sometimes, **your arrival** and the **items** (the gate's contents row)
  are placed at random spots.

The *maze size* of a floor comes from its battle list (Encounters tab):
**3-15** only — 1 or 2 can carve an empty floor that freezes the game, and
0 or 16+ write past the maze grid (the build refuses them).
