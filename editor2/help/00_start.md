# Getting started

The editor works on a **project** — a folder with `project.json` and its
assets. Everything you change is saved into the project; the game ROM is
built from it (the original ROM is never changed).

**Tabs**

- **Rooms** — paint rooms, their screens and states; NPCs, doors, spots,
  talk and conversations; "Inside gates" settings for gate / boss floors.
- **Import art** — turn a PNG rip into a room tileset.
- **Gates** — which custom rooms appear on which gate floors, per-gate
  settings (floor count, boss floor, hand-made gates, project enemies) and
  **new gates** of your own (a copy of a vanilla gate; entrances on the Rooms
  tab).
- **Families** — which monsters belong to which family, family icons,
  arena dialogue, Spirit's default names.
- **Monsters** — every monster's species data (family, growth, resistances,
  natural skills …), every battle row it appears in (stats, AI, joining), new
  monsters cut from a sprite sheet, and new art for the original monsters.
- **Dialogue** — every text of the game, searchable (read-only for now).
- **Arena** — the classes, Starry Night and the King: entry fees, each
  match's master, 1-3 monster teams and the teams' monsters and stats.
- **Skills** — every original skill: name and SKIL text, MP, when monsters
  learn it, power, targets, how the monster AI treats it, its battle rules and
  which skill's animation and sounds it plays — or which animation, screen
  effect or nothing it shows.
- **Animations** — new battle animations made from the frames of the game's
  45, with a playing preview and their sounds.
- **Breeding** — every monster's breeding depth and how you get it, the
  recipes that make it and what it makes, the special and family recipe
  tables, "Try a cross", and a tree generator.
- **Encounters** — every wild-monster list (the game's 128 and your own),
  which list each gate floor and each room uses, flag variants that switch
  them, and battle rates.
- **World** — the graph of rooms and the doors between them (mouse wheel =
  zoom, drag empty space = move around, Fit / + / −).
- **Build & Play** — build the ROM (Ctrl+B) and run it (Ctrl+R).
- **Help** — this tab (F1).

Tabs marked with a roadmap box (Music, …) are not built yet.

**Every edit can be undone** (Edit → Undo / Redo; View → History shows
the list). File → Save saves the project.

**Testing:** build, then load the ROM with your own save in your emulator.
Build warnings are listed in the Build log at the bottom — read them.
