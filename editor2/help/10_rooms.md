# Rooms, screens and states

**New room:** Rooms tab → **New** under the room list → name + the vanilla
room whose tileset it uses — or a **gate theme** (one of the 16 maze looks of
the gates, in their colours: see *Gate themes*). **Copy / Rename / Delete** sit next to it. A
vanilla room is read-only until you **Make editable** (it is copied into the
project).

**Screens:** a room is up to a 4×4 grid of screens (10×8 cells each). The
mini-map shows them; click a **+** square to add a screen, click a screen
to show it.

**Maze screen…** (on the screen / state row) fills the shown screen and
state with one of the gates' maze screens, tiles and palette slots — see
*Gate themes*.

**The right side — pages (S132).** The tabs down the right edge each open ONE page
at full height (no scrolling through stacked sections): **Tiles** (the metatiles
to paint with, Borrow, Tileset, Animate, **Draw**), **Palettes** (the room's colours,
**Borrow palette…**, which palette the room / this screen uses), **Object** (the
selected cell, NPC, door, exit or spot — opens by itself when you click one),
**Room** (name, tileset, size, music, doors that lead here, state rules),
**Screen** (the screen / state on the canvas) and **Gates** (only for rooms used
inside gates and worlds). Engine numbers (map id, attr grids, layout ids) sit in a
folded *Technical* box at the bottom of Room / Screen. Choosing Paint or Eyedrop
opens Tiles. The editor remembers the page you used last.

**Painting:** pick a metatile (Tiles page) and paint with the canvas tools; the
Walk tool shows / flips walkability. Painting is immediate (S132: only the cells
you paint are redrawn; the side panels update once when you let go; the bank
space meter measures in a fraction of a second).

**Borrow palette…** (Palettes page): any room's colours — one of your rooms, a
game room at any screen and step (the Servant room on fire, the night Farm …) or
a gate theme. Left: pick the room (type to filter), its screen and state; middle:
that screen in its own colours; right: YOUR screen re-coloured as it would be.
Take **the whole palette** — for the whole room or only this screen / state (your
own room's palette can be **shared** instead of copied: then a colour edit shows
in both rooms) — or **only some rows**: "my slot 2 ← their row 1". If other
places use your palette, *Only here* copies it first so they keep their colours.
One undo step. The palette combos name the rooms that use each palette.

**Draw** (Tiles page → Draw tab): paint a metatile pixel by pixel. Load the
selected cell, the brush, or a blank tile; each 8×8 quarter paints in its own
palette (left = paint, Shift = fill, right = pick a colour; Ctrl+click picks a
quarter for the tools: flip, shift, copy / paste, clear, undo, revert). Then
**Redraw it everywhere it is drawn** (the tiles themselves change — the line says
how many cells in which rooms; nothing is spent) or **Save as a new metatile**
(free tileset slots, the walkable / wall side you tick; put it on the selected
cells, on every cell of the room drawing the original, or only into My
metatiles). Tiles the room animates are changed in the Animate tab; the common
font / frame tiles ($80-$AF) only as a new metatile.

**States:** a screen can have several **states** (versions) — e.g. "boss
present" and "boss beaten". **+ Add state** (duplicate this state, with or
without its own layout copy, or an empty state); **− Remove state**; ◀ ▶
switch the state shown.

**State rules** (Room page → *State rules — which state shows when*): **Add…** a rule "show state N when these flags are ON / OFF".
Rules are checked top-down every time a screen loads; the first that holds
wins. Flags are saved with the game, so this is how a room remembers its
version. See *Boss floors → the "beaten" version*.

**A copy of a game room follows the game's state** (*Follow the game's room
state*, in the State rules section — on for every copy): its states change
when the game's story changes the original's (the Castle moves GreatTree to
"the man by the cliff"), and they are saved with the game, exactly like the
original. Untick it for a copy that should keep its own state (a copied boss
room you use for a NEW boss — otherwise beating the original boss shows the
copy beaten too). A copy with state rules uses its own state.

**Inside gates and worlds** (the **Gates** page): the room's
settings for gate floors (arrival cell, music, battles, saving, arrival
conversation, stairs) — and, for a room of a **world**, which world it belongs
to and whether the player can save there (see *Worlds*).

**Animated tiles:** select cells → Tiles page → **Animate** tab. See the
*Animated tiles* topic.
