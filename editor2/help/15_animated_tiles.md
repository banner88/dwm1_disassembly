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

**Change or remove:** the list *Animations in this room* → **Edit** (its
cells are selected and it loads below; **Save changes**) or **Remove** (the
tiles show their first frame again). Everything is one undo step.

**The numbers at the top**

- **Load** — how much the room changes per game frame compared with what
  the game safely does (8 tiles a frame). Under 100 %: everything runs at
  the speed you set. Over 100 %: the busiest steps wait a frame or two.
- **Free tiles on this tileset** — only *only the selected cells* uses them.
  Frames never use tileset space.
- **Frame storage** — your frames live in ROM banks of their own, not on the
  tileset. One room's animations must fit one bank (about 15.8 KB); the whole
  project has no limit of its own — when bank $6C is full, the next rooms'
  animations go to new banks of the 4 MB ROM (S139; the **$6C** and **new**
  bars at the bottom show it). A 2-frame flip of 4 tiles is 0.1 KB; a drifting
  strip 4 tiles wide is 2 KB per row (it needs 32 one-pixel frames).
- **Animation groups** — up to 32 per room (every 8 tiles of one animation
  is one group).

**Copy a vanilla room's animation…** (bottom of the Animate tab) — optional:
also play one of the game's own room animations here (it moves fixed tiles
of the sheet; a room copied from a vanilla room plays that room's by
default). Your own animations run next to it. *Make the selected cell
still* stops a cell that the vanilla animation moves.

Animations pause while a text box or menu is open, like the game's own.
