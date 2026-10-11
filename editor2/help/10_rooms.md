# Rooms, screens and states

**New room:** Rooms tab → **New** under the room list → name + the game
room whose tileset it uses — or a **gate theme** (one of the 16 maze looks of
the gates, in their colours: see *Gate themes*). **Copy / Rename / Area… / Delete** sit next to it. A
game room is read-only until you **Make editable** (it is copied into the
project).

**Rooms by name (S143).** The editor shows every room — yours and the game's — by its
NAME only, never a map id or a region: in the room lists, in every place you pick a
room (doors, teleports, conversation and cutscene moves, gates, the hub, worlds, the
arena, Borrow, Import art, music), in the World tab and in the Build log. So room names
are **unique**: New / Copy / Make editable pick a free name ("Cave 2" when there is a
"Cave"), and Rename refuses a name another room has. A project saved with two rooms of
one name gets the second renamed ("GreatTree 2") when it opens (the Build log says so —
Save to keep it). The game's own rooms keep the names you know; the eight unused map
ids that only hold the Castle's room data are listed as **Castle (unused copy 1-8)**,
and the copy of the gate item shop's data as *Gate Floor: Item Shop (unused copy)*.
When one of your rooms has the same name as a game room (a copy keeps the game's name),
the game's is shown as "GreatTree (game room)". **View → Show technical ids** puts each
room's map id (and region, "region 1 $6B") after its name everywhere, for debugging in
SameBoy — off by default; the stored destinations never change.

**Areas (S143):** one level of named folders for your rooms. The room list shows each
area as a folder with its room count ("No area" last); **Area…** (or right-click a room
→ *Put in area… / Move to*), the **area** box on the Room page, or dragging a room onto
a folder moves it; type a new name to make a new area. Right-click a folder to rename,
move up / down or delete an area (its rooms stay, with no area). The **search box**
above the lists filters your rooms and the game's by name or area. Every room picker
lists your rooms by area, and the World tab can show one area. Areas are only for you
— the game never sees them.

**Picking a room (S143):** every room choice is one searchable list — click it and pick,
or TYPE any part of a name or an area and choose from what matches (Enter / click). Your
rooms come under their areas, the game's rooms under their groups (Castle & GreatTree,
Arena & Starry Shrine, Travelers' gate rooms, Boss rooms, Gate floors & mazes).

**Copy** (S142) makes a room of its own: its own screens, its own tileset copy,
its own **scripts and texts** (change what a copied NPC says and the original
still says its old words — before S142 a copy's NPCs ran the original's
scripts, and a copied breeder stopped the build) and its own **doors**, which
start **unconnected** (a door leads both ways, so the original's partner door
keeps leading to the original): connect them where the copy should lead. The
status line says how many. A quest stays with the original giver (the copy's
NPC keeps the giver's own conversation, without the quest); flags are not
copied — a copied conversation turns the same flags on as the original.

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
inside gates and worlds). Engine numbers (attr grids, layout ids — and, with View →
Show technical ids, the room's id and map id) sit in a folded *Technical* box at the
bottom of Room / Screen. Your 129th room and on go into a later REGION by themselves
(see *Limits*); you never pick one. Choosing Paint or Eyedrop
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
