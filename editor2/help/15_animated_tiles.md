# Animated tiles

Make any tiles of a custom room move — clouds, water, torches, flags,
sparkles — drawn by you, at the speed you choose.

**Step by step**

1. Rooms tab → open the room → **Select tool (V)**.
2. Click a cell, or **drag** over several (Shift+click extends). Or just
   **double-click** a cell.
3. Tiles page → **Animate** tab → **Use the selected cells**.
4. **How it moves**:
   - **Flip through frames** — all frames are shown **side by side**; paint
     straight on any of them (frame 1 is the map as drawn and stays fixed).
     **+ Add frame** (up to 8) copies the yellow frame; the yellow frame is
     the one the tools act on; **Size − +** makes the frames bigger or
     smaller. **Parts:** Ctrl+click picks one 8×8 tile, Ctrl+Shift+click a
     whole 16×16 cell (outlined on every frame; Ctrl+click it again or
     **Whole frame** = back to the whole frame). Shift ◀▶▲▼, Mirror, Clear
     and Copy previous act on that part only. **Copy** takes the part from
     the yellow frame (frame 1 too); **Paste** puts it into the part of the
     yellow frame — a smaller piece repeats to fill it (one tile pasted on a
     cell fills its four tiles). **Undo** steps back. Tiles you leave the same do not
     move. *Loop* (1 2 3 1 2 3) or *back and forth* (1 2 3 2 1).
   - **Drift right / Drift left** — the picture scrolls 1 pixel per step and
     wraps round inside the selected cells (water, conveyors, a cloud
     drifting in its box). *The selection moves as one picture* = pixels
     flow from tile to tile (at most 2 cells wide); unticked = every 8×8
     tile scrolls on its own (seamless textures).
   - **Sway** — 1-3 pixels one way, then the other (leaves, grass — like
     the GreatTree).
5. **Speed** — pick a preset or type the exact number of game frames per
   step (the game runs about 60 frames a second; the game's own animations
   use 32). The line under it says how many changes per second that is.
6. **What moves** — *only the selected cells* (the editor gives them their
   own copy of each tile, so nothing else changes — this is the only thing
   that uses free tiles) or *every place in this room drawn with these
   tiles* (free: e.g. every tree of the room sways).
7. **Create animation**. The canvas starts playing it (**■ Stop** /
   **▶ Play** on the screen row); the **Anim** layer outlines moving tiles.

**Import frames from a PNG (S173 r3).** Drawn your animation in a paint program? Select the
cells on the canvas (Select tool, click or drag), then Animate tab → **Import frames from
PNG…**. The PNG holds the frames **side by side** (or one under the other), each the size of
the selection — 16 pixels a cell: one cell = 16×16 frames, one cell over another = 16×32 —
at 1× or any whole zoom (2×, 3× …, every block one colour). **See-through pixels** (S173 r4):
a fully clear pixel keeps what the map shows there; a **half-clear** pixel is **light** — its
colour, except where the map is black (the wall's grain shows through a glow). So a torch with
a halo can be drawn with NO wall in it and fits whatever wall it lands on. A window shows the
frames as the game will draw them (over the wall that is there) and what happens:

- every 8×8 piece is drawn with a **palette row that holds all its colours** (in every
  frame). When no row does, a row that nothing using this palette draws gets the piece's
  colours — several pieces share it when their colours fit 4 (one of them black). A row whose
  colour 1 is not the cream turns **own colour 1** on (your rows keep their cream). When no
  row is left, the nearest colours are used and the window says how many pixels;
- **frame 1 becomes the cells' tiles** (each on the same wall / walkable side as before),
  the other frames the animation (*Flip through frames*); **speed** 32 by default — the
  game's own torches swap every 32 game frames — loop or back and forth, and a name;
- the cells join **My metatiles**: paint them anywhere else in the room and they move too,
  for no extra tiles.

An import CHANGES the cells' tiles for good. For a picture you may want to move or remove
later — a wall torch — use a **stamp** instead (S174, Rooms → **Stamps** page + the **Stamp
tool (T)**, see *Rooms*): the same PNG, but the tiles under it are never changed; the build
draws it in.

One undo step. With one frame it just places the picture. Measured in the game
(`tools/walk_anim_import.py`): the rows in the palette, only the imported frames, a step
every 32 frames, walls kept.

**Change or remove:** the list *Animations in this room* → **Edit** (its
cells are selected and it loads below; **Save changes**) or **Remove** (the
tiles show their first frame again). Everything is one undo step.

**The numbers at the top**

- **Load** — how much the room changes per game frame compared with what
  the game safely does (8 tiles a frame). Under 100 %: everything runs at
  the speed you set. Over 100 %: the busiest steps wait a frame or two.
- **Free tiles on this tileset** — only *only the selected cells* uses them
  (both pages of the tileset count). Frames never use tileset space. Tiles on
  page 2 animate exactly like page-1 tiles.
- **Frame storage** — your frames live in ROM banks of their own, not on the
  tileset. One room's animations must fit one bank (about 15.8 KB); the whole
  project has no limit of its own — when bank $6C is full, the next rooms'
  animations go to new banks of the 4 MB ROM (S139; the **$6C** and **new**
  bars at the bottom show it). A 2-frame flip of 4 tiles is 0.1 KB; a drifting
  strip 4 tiles wide is 2 KB per row (it needs 32 one-pixel frames).
- **Animation groups** — up to 32 per room (every 8 tiles of one animation
  is one group).

**The Still tool (S173) — a tile that never moves.** **Still (S)** on the tool bar, then
click a MOVING cell (the **Anim** layer outlines them): a window shows every picture that
cell shows while the room animates — the game's animation (the GreatTree sway, water …)
or one of your own. Pick one (**at rest** = the map as drawn; while **▶ Play** runs, the
picture on screen is picked first) → **Make the still tile**: the cell you clicked now
shows that picture and never moves (S173 r2 — before, only the tile was made and the cell
kept moving in the game). The new tile is also in *My metatiles* and becomes your brush
(Paint) for any other cell; other cells drawn with the moving tile keep moving. It costs one free tile of the tileset for each moving 8×8 quarter (none when that
picture is already on the tileset). One undo step. Measured in the game: the still copy
never changes over 1,200 frames while the original keeps moving (`tools/walk_still.py`).

**Copy a vanilla room's animation…** (bottom of the Animate tab) — optional:
also play one of the game's own room animations here (it moves fixed tiles
of the sheet; a room copied from a vanilla room plays that room's by
default). Your own animations run next to it. *Make the selected cell
still* stops EVERY cell of the room drawn with that tile (the vanilla animation's tiles
only; it keeps the resting picture) — the Still tool above makes a new still tile instead
and changes nothing on the map.

Animations pause while a text box or menu is open, like the game's own.
