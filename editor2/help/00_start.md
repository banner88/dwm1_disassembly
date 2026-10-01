# Getting started

The editor works on a **project** — a folder with `project.json` and its
assets. Everything you change is saved into the project; the game ROM is
built from it (the original ROM is never changed).

**Tabs**

- **Rooms** — paint rooms, their screens and states; NPCs, doors, spots,
  talk and conversations; "Inside gates" settings for gate / boss floors.
- **Import art** — turn a PNG rip into a room tileset.
- **Gates** — which custom rooms appear on which gate floors, and per-gate
  settings (floor count, boss floor, hand-made gates, project enemies).
- **Families** — which monsters belong to which family, arena dialogue,
  Spirit's default names.
- **Monsters** — every monster's species data (family, growth, resistances,
  natural skills …), every battle row it appears in (stats, AI, joining), and
  new monsters cut from a sprite sheet.
- **World** — the graph of rooms and the doors between them (mouse wheel =
  zoom, drag empty space = move around, Fit / + / −).
- **Build & Play** — build the ROM (Ctrl+B) and run it (Ctrl+R).
- **Help** — this tab (F1).

Tabs marked with a roadmap box (Skills, Breeding, …) are not built yet.

**Every edit can be undone** (Edit → Undo / Redo; View → History shows
the list). File → Save saves the project.

**Testing:** build, then load the ROM with your own save in your emulator.
Build warnings are listed in the Build log at the bottom — read them.
