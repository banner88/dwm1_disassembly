# Import art

Turn a PNG — a map rip, a mock-up — into tiles, metatiles and screens of a
room of your own. The editor proposes a grid and colours; your eye decides.

**Before you start:** art needs free tileset slots. Rooms tab → **New** →
tick *start with a BLANK tileset (for imported PNG art)* (the palette still
comes from the room you pick above it), or **New room…** on this tab. A room
you have: inspector → *tileset* → **Change…** → **New blank tileset (for
imported PNG art)** (*wall | walkable split at* sets where wall slots end).

**1 · Image and target room** — **Open PNG…** copies the picture into the
project; every PNG you open stays in the *image* list with its panels, masks
and walls. **Remove** takes it off the list (tiles already imported stay).
*into room* is the room the art goes to; the line below says how many wall
and walkable slots its tileset has free.

On opening, the editor guesses the **key colours** (never art): the commonest
colour round the edge, plus every colour the Game Boy Color cannot show
exactly (smoothed caption text). Each area not in key colour becomes a
**panel** with its own grid.

**Tools** (above the picture): **Select (S)** — drag a rectangle of cells,
click toggles one, Shift adds. **Mask (M)** — block cells out. **Wall (X)** —
mark cells the player cannot enter; with **Wall: same tile everywhere** (on)
one click marks every identical cell. **Panel (P)** — drag a rectangle to add
a panel. **Key colour (K)** — click a colour to make it a key colour, or not.
**Zoom**, or Ctrl+wheel; drag with the middle button to scroll. Red-tinted
cells touch a key colour and are never imported; dark cells are masked;
yellow = selected; a red outline = wall.

**2 · Line up the grid (per panel)** — pick a panel in the list and move its
grid with *offset x* / *y* (0-15), or the arrow keys (1 pixel; Shift = 8).
**Auto-align** picks the offset with the fewest different 8×8 tiles, trying
only 8-pixel steps from the panel's corner — check it by eye. **Re-detect
panels** replaces all panels with fresh guesses; **Delete panel**; **Select
whole panel**.

**3 · Palettes (room slots 0-3)** — each row shows a slot's colours now and
→ what the import would make them. Each 8×8 piece uses one slot; colours a
slot lacks become the nearest one (the line below says how many pieces come
out exact). With nothing selected, the whole chosen panel is fitted.

- **Own colour 1 — three colours per slot (recommended)**: colour 3 stays
  black, the other three are yours. Unticked: colour 1 is the game's cream,
  so two colours per slot.
- **keep** a slot the room already uses — its colours stay and the import
  fits around them. A warning says when an import would recolour a slot
  that the room already draws with.
- **Show as GBC** lays the fitted result over the picture.

The colours go into the palette of the screen picked under *stamp onto
screen*.

**4 · Import** — the top line says how many new tile slots the import needs
(identical tiles already in the tileset are reused) and whether it fits. If
it does not: select fewer cells, *Release unused vocabulary* (Rooms tab →
**Tileset** tab), or a room with a blank tileset.

- **Unmarked cells must be walkable** (off): only cells you marked with
  **Wall (X)** are made walls; the rest are placed wherever there is room,
  and you set walkability afterwards with **Walk** on the Rooms tab. On:
  unmarked cells are always walkable — this can cost extra slots.
- **Add selected cells to My metatiles** — tiles, colours and metatiles only
  (an identical metatile is not added twice); nothing is painted.
- **Stamp selection onto the room (and add metatiles)** — the same, then the
  selection's top-left cell is painted on the chosen screen at *at cell* x
  (0-9), y (0-7), on the screen's first state. **spill onto the neighbouring
  screens** (on): a selection bigger than the screen carries on right and
  down, adding screens, up to the 4×4 grid; unticked, cells past the 10×8
  screen are left out. Screens it paints on get the import's palette.

A room still on a game room's tileset gets its own copy first. If the slots
run out, nothing changes. Every import, and every grid, mask, wall or key
colour edit, can be undone.

**Import into this tileset** is a different thing: Tiles page → **Borrow**
tab, a room on another tileset → click a metatile (or right-click → *Import
into this tileset*) copies that game tile into your room's tileset.
