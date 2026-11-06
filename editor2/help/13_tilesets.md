# Tilesets, metatiles and palettes

How a room is drawn:

- **Tileset** — the sheet of small tiles (8×8 pixels) a room is painted
  from: **256 tiles in two pages of 128**. **Page 1** is the sheet the game
  always had; **page 2** is 128 more tiles the game keeps in the second half
  of the Game Boy Color's video memory (GBC only — on an original Game Boy a
  page-2 tile would show the page-1 tile with the same number). You never
  pick a page: imports, borrowed tiles, drawn tiles and walkability twins fill
  page 1 first and spill onto page 2 by themselves, and every room drawing
  with that tileset can use both pages. A tileset whose page 2 is empty costs
  nothing extra; one with page 2 takes 2 KB more ROM. The game also loads 48
  **shared tiles** (ids 128-175: the bed, carpet and other bits some game
  rooms use, e.g. the roots room) into every room; a copy of a game room that
  uses them draws them like the game does.
- **Metatile** — one cell of the map: four tiles (top-left, top-right,
  bottom-left, bottom-right) and a palette slot (or one per tile). You
  paint metatiles.
- **Walls** — the tileset is split in two: tiles before the split are walls,
  the rest walkable. A cell is a wall when its **bottom-right** tile is on
  the wall side; the other three do not count. (Select a cell: *Walkability
  is decided by the bottom-right subtile*.) Page 2 is split at the same
  place: page-2 tile 5 is a wall exactly when page-1 tile 5 is (the game
  only looks at the tile's number). You do not need to think about it — the
  **Walkability** click finds or makes the twin it needs on either page.

## The Tiles page

**This room** tab — click a metatile to make it the brush (the canvas
switches to Paint):

- *This room's tiles* — every metatile used on any screen or state of the
  room, plus (for a copy of a game room) everything the original uses, so a
  tile you painted over is still here. The header says how many wall and
  walkable slots are free.
- *My metatiles* — your own. Click **+** to build one.
- *Parked* (S171 r5) — metatiles kept with their own pictures that use **no** tileset
  slot (dashed grey frame, grey corner mark). Only tiles placed on a screen hold slots:
  when an import, a drawing or a re-plan needs room and the tileset is full, the editor
  parks every *My metatile* that no screen shows (animated ones and statue / service
  tiles stay). Click a parked one = it comes back into the tileset (the same picture;
  if the palette changed since, each piece takes the row closest to its real colours)
  and becomes the brush — parking other unplaced ones first if the sheet is full.
  Right-click → **Delete this parked metatile**.

**Copy in row ▸ 0-3** (right-click a tile of *This room's tiles*, *My metatiles* or
*Parked*, S171 r6): the same tiles in another row's colours — a new *My metatile* (a parked
copy for a parked one) and the brush. The tiles are the same, so it uses **no** tileset slot.

Corner marks: bottom-right red = wall, green = walkable; top-left orange =
its slot was released (the picture may change on the next import), red = the
picture already changed; top-right teal = it moves in the game. Hover for
details. Right-click → **Open in metatile editor…** (a new metatile starting
from this one) or **Delete** (My metatiles only).

**Borrow** tab — two lists, each A-Z; picking in one clears the other.
**Your room:** any room of your project (S171 r3) — its metatiles on every screen
and its *My metatiles*, including tiles you imported from a PNG and page-2 tiles.
**Game room:** any game room or *Gate theme N*. Same tileset: click = brush. Other
tileset: click (or right-click → **Import into this tileset**) copies the four tiles
into free slots of your tileset (a tile already there is reused; the bottom-right one
stays on its wall / walkable side). The new metatile lands in *My metatiles* and becomes
the brush.

**Match colours** (ticked, S171 r4): the tiles show in their OWN colours, and each 8×8
piece of an import goes to the row of THIS room whose colours look closest — its pixels
renumbered to them. The status line says how close they came (*exact / close / rough*);
the editor remembers the real colours, so **Re-plan colours** (below) can fit the rows to
them later. Unticked: the old way — the tiles drawn in this room's colours, colour numbers
and rows copied as they are. A tile that moves in its own room keeps the old way: take
over that room's animation, or **Import it still (it will not move)**.

**colours** (S171 r6): *into the closest row* (each 8×8 piece where it looks closest) or
*into row N* (every piece in the row you pick — some tiles in one colour set, others in
another). Either way each colour of the art gets its own colour number: two colours are
never merged into one, so the shapes stay (only a picture with more than 4 colours in one
8×8 piece must merge). **show as they will look here** draws the tiles and picture cells
as the import would put them in this room.

**Several at once:** Ctrl / Shift + click tiles (yellow frame), then **Import the
selected (N)** — one undo step.

**A picture (PNG)…** — borrow straight from a PNG, no helper room: its 16×16 cells show
in their own colours (each panel on its own grid, as the Import art tab would guess;
untick *grid found by itself* to set x / y yourself; identical cells once). Click = import
one; Ctrl / Shift + click = several. **walkable / wall** = the side they go to. Picking a
room in a list closes the picture.
If a side is full on both pages, the editor first parks the unplaced *My metatiles* (see
*Parked* above); if the tiles **placed on screens** fill it, the import is parked instead
(the status line says so) — it takes slots when you paint with it, which then says what
fills the tileset. If unused vocabulary would free a side, the editor offers to release
it (page 2 is used first — see *Page 2* below).

**Animate** tab — see *Animated tiles*.

## The metatile editor

Click a slot **TL**, **TR**, **BL** or **BR**, then a tile on the sheet
(red-tinted tiles are on the wall side); the next slot is picked for you.
The sheet shows page 1 above the blue line and page 2 below it; a page-2
tile is labelled *p2 $NN*.
**Palette slot** sets the slot of all four tiles — or tick **per subtile
(selected slot only)** to change just the selected one. Give it a **Name**.
The preview shows it in the room's colours and says WALL or walkable. **OK**
adds it to *My metatiles* and makes it the brush.

## The Tileset tab — the slot budget

All 256 slots — page 1 on top, page 2 below the blue line: green placed,
violet my metatiles, blue vocabulary (the original room's tiles), orange
released, teal animated (dashed = a hidden frame the game swaps in — never
place it), brown kept free for a service menu (see *Services* — Grandpa's,
a breeder's, the farm's or the egg appraiser's screen draws its words there
while the room shows), red dot = picture changed, yellow line = wall | walkable split
(drawn on both pages). Hover a slot = who uses it (*page 2 slot $NN* on page
2); click = highlight it on the canvas. **draw with palette** picks the
colours. The summary counts free wall / walkable slots and how many of them
are on each page.

- **Release unused vocabulary** — the original room's tiles are kept so
  *This room's tiles* still offers them. Ticked, imports and walkability
  flips may use the ones placed nowhere. Untick to protect them again.
- **Park unplaced (N)** — park every *My metatile* placed nowhere (S171 r5, was *Purge
  unused*): it stays in the picker under *Parked* with its picture, but frees its slots;
  the button says how many and what slots that frees. Imports do this on their own when
  the tileset is full. The summary counts the parked ones (0 slots).
- **Delete parked (N)** — forget the parked metatiles (they use no slot; this only tidies
  the picker). Undo brings them back.
- **Give this room its own copy** — shown when other rooms draw with the
  same tileset (*SHARED with: …*): this room gets a copy of its own.

A game room shows *Vanilla room — clone it to see its slot budget as yours.*

**Walkability (W)** (or **Walk** on the toolbar) flips a cell between wall
and walkable: the editor gives its bottom-right tile a twin on the other
side of the split, so it needs a free slot and a tileset in your project (it
offers to copy the game's). Use it rather than **collision ≥** in the *Room*
group.

## Change tileset

*Room* group → **tileset** → **Change…**: **Another room's tileset
(vanilla)**, **A tileset in this project** (with the rooms that use each),
**New blank tileset (for imported PNG art)** (every slot free — fill it from
the Import art tab), **Own copy of the current tileset** (when shared) or a
gate theme (see *Gate themes*). **wall | walkable split at** applies to
project and blank tilesets. Your screens keep their tile numbers: they draw
with the new sheet until repainted. Undo restores the old one. **New** room
offers **start with a BLANK tileset (for imported PNG art)** too.

## BG palettes (the Palettes page)

Rows 0-3, four colours each, are the room's palettes; **show system 4-7**
also shows the shared menu / monster palettes (read-only). A cell uses the
palette slot of its metatile; **Palettes** on the canvas toolbar shows them.

- Double-click a colour to edit it. Colours marked L are fixed by the
  game: colour 3 is black, colour 1 is cream unless **own colour 1** is
  ticked (your rooms: three colours of your own per slot).
- In a room still on the game's palette, double-clicking first offers to
  copy the palette into your project; in a game room, to clone the room.
- *Room* group → **palette**: *(borrow vanilla source palette)*, one of your
  palettes, or *copy from vanilla …* (copied in as a new one). *Screen &
  state* → **palette here**: *(room palette)* or another one just for this
  screen / state (a night version). A palette can serve several rooms and
  screens — a colour you change, changes in all of them.
- A gate theme with its colours: the status line says *Theme colours set as
  the room's palette* and which screens kept their own (see *Gate themes*).
- **attr grid** (*Screen & state*) says where the screen's palette slots come
  from; in a game room it reads *vanilla attr*.

## Re-plan colours (re-roll)

A room's screen has **4 colour rows** (black + three colours of your own each, or two +
the game's cream); every 8×8 piece is drawn in one row. Tiles gathered from different
places rarely share rows. **Palettes → Re-plan colours… (re-roll)** works out the 4 rows
that draw ALL the room's tiles best — from their real colours where the editor knows them
(anything brought in with *Match colours* or a picture since S171 r4), else from how they
look now:

- the first picture is *the rows as they are* (with its score), then four **plans** — the
  first starts from the rows as they are, the others try other rows; each shows the screen,
  its rows and a score (*% of tiles exact · error*, lower error = closer);
- **Re-roll** — four other plans; **Keep a row as it is** — tick it and the plans fit the
  others around it; **Own colour 1** — three colours of your own per row (recommended);
- **Apply** — the palette rows, every piece's row and its renumbered tile, the cells and
  *My metatiles*: one undo step. A tile wanted in two colourings (or also drawn in another
  room) gets a second slot on the same wall / walkable side — the message says how many.

It covers the screens of this room drawing with the palette of the screen shown (a screen
with its own palette is planned on its own). A room that still draws with the game's
tileset or palette gets its own copy first. It refuses while a screen shares its drawing
with a room of other colours (the message names it).

## Page 2 — the second 128 tiles

- **When it opens** — by itself, the first time page 1 has no free slot for
  what you import, borrow, draw or flip. Nothing to switch on. The Tileset
  tab then shows the new tiles below the blue line.
- **In the game** — the room loads its page 2 every time it loads (and after
  a menu, a battle or a save): about half a frame. Text boxes, menus, shops,
  the Vault, Grandpa's and every other window keep their letters clean over
  page-2 tiles, and battles leave them as they were.
- **Animated tiles** work on page 2 like on page 1 (see *Animated tiles*).
- **Grandpa, breeders, the farm keeper, the egg appraiser** draw their menus
  into page-1 slots while the room shows (breeding: 56 of them, $38-$7F). A
  room with one of them keeps those slots empty: making the NPC (or opening
  an older project) moves the tiles there to page 2 — nothing changes on
  screen (S168 r2).
- **Memorial statues** draw their monster into page 1: when page 1 is full,
  adding a statue moves a few ordinary tiles to page 2 first (nothing changes
  on screen).
- **GBC only** — the second page lives in memory only the Game Boy Color has.
