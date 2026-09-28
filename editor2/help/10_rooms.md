# Rooms, screens and states

**New room:** Rooms tab → **New** under the room list → name + the vanilla
room whose tileset it uses. **Copy / Rename / Delete** sit next to it. A
vanilla room is read-only until you **Make editable** (it is copied into the
project).

**Screens:** a room is up to a 4×4 grid of screens (10×8 cells each). The
mini-map shows them; click a **+** square to add a screen, click a screen
to show it.

**Painting:** pick a metatile (Metatiles section) and paint with the canvas
tools; the Walk tool shows / flips walkability. Palettes are in the
BG palettes section.

**States:** a screen can have several **states** (versions) — e.g. "boss
present" and "boss beaten". **+ Add state** (duplicate this state, with or
without its own layout copy, or an empty state); **− Remove state**; ◀ ▶
switch the state shown.

**State rules** (Room / screen / selection → *State rules — which state
shows when*): **Add…** a rule "show state N when these flags are ON / OFF".
Rules are checked top-down every time a screen loads; the first that holds
wins. Flags are saved with the game, so this is how a room remembers its
version. See *Boss floors → the "beaten" version*.
