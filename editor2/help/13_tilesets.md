# Tilesets, metatiles and palettes

How a room is drawn:

- **Tileset** — one sheet of 128 small tiles (8×8 pixels) per room. The game
  also loads 48 **shared tiles** (ids 128-175: the bed, carpet and other
  bits some game rooms use, e.g. the roots room) into every room; a copy of
  a game room that uses them draws them like the game does.
- **Metatile** — one cell of the map: four tiles (top-left, top-right,
  bottom-left, bottom-right) and a palette slot (or one per tile). You
  paint metatiles.
- **Walls** — the tileset is split in two: tiles before the split are walls,
  the rest walkable. A cell is a wall when its **bottom-right** tile is on
  the wall side; the other three do not count. (Select a cell: *Walkability
  is decided by the bottom-right subtile*.)

## The Metatiles section

**This room** tab — click a metatile to make it the brush (the canvas
switches to Paint):

- *This room's tiles* — every metatile used on any screen or state of the
  room, plus (for a copy of a game room) everything the original uses, so a
  tile you painted over is still here. The header says how many wall and
  walkable slots are free.
- *My metatiles* — your own. Click **+** to build one.

Corner marks: bottom-right red = wall, green = walkable; top-left orange =
its slot was released (the picture may change on the next import), red = the
picture already changed; top-right teal = it moves in the game. Hover for
details. Right-click → **Open in metatile editor…** (a new metatile starting
from this one) or **Delete** (My metatiles only).

**Borrow** tab — **Room:** any game room or *Gate theme N*. Its metatiles are
drawn in THIS room's colours. Same tileset: click = brush. Other tileset:
click (or right-click → **Import into this tileset**) copies the four tiles
into free slots of your tileset (a tile already there is reused; the
bottom-right one stays on its wall / walkable side). The new metatile lands
in *My metatiles* and becomes the brush. A tile that moves in its own room:
take over that room's animation, or **Import it still (it will not move)**.
If a side is full of unused vocabulary, the editor offers to release it.

**Animate** tab — see *Animated tiles*.

## The metatile editor

Click a slot **TL**, **TR**, **BL** or **BR**, then a tile on the sheet
(red-tinted tiles are on the wall side); the next slot is picked for you.
**Palette slot** sets the slot of all four tiles — or tick **per subtile
(selected slot only)** to change just the selected one. Give it a **Name**.
The preview shows it in the room's colours and says WALL or walkable. **OK**
adds it to *My metatiles* and makes it the brush.

## The Tileset tab — the slot budget

All 128 slots: green placed, violet my metatiles, blue vocabulary (the
original room's tiles), orange released, teal animated (dashed = a hidden
frame the game swaps in — never place it), red dot = picture changed, yellow
line = wall | walkable split. Hover a slot = who uses it; click = highlight
it on the canvas. **draw with palette** picks the colours. The summary
counts free wall / walkable slots.

- **Release unused vocabulary** — the original room's tiles are kept so
  *This room's tiles* still offers them. Ticked, imports and walkability
  flips may use the ones placed nowhere. Untick to protect them again.
- **Purge unused borrowed** / **Purge unused own** — remove every borrowed
  metatile / every one of your own (made here or imported from a PNG) that
  is placed nowhere; the button says how many and what slots that frees.
  Undo brings them back.
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

## BG palettes

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
