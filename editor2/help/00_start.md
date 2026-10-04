# Getting started

The editor works on a **project** — a folder with `project.json` and its
assets. Everything you change is saved into the project; the game ROM is
built from it (the original ROM is never changed).

**Tabs**

- **Rooms** — paint rooms, their screens and states; NPCs, doors, spots,
  talk and conversations; "Inside gates" settings for gate / boss floors.
- **Import art** — turn a PNG rip into a room tileset.
- **Cutscenes** — every scene of the game and of your rooms as a storyboard
  (steps in words, pictures recorded from the game) and **▶ Play**: the
  game plays the scene right here, with sound, set up for you (the intro
  chain included); **＋ New cutscene** makes your own scenes on the room
  itself, in tiles, with named NPCs and cast members, previewed instantly or
  played in the game.
- **Gates** — which custom rooms appear on which gate floors, per-gate
  settings (floor count, boss floor, hand-made gates, project enemies) and
  **new gates** of your own (a copy of a vanilla gate; entrances on the Rooms
  tab). A portal's swirl spins until its gate's boss is beaten.
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
- **Music** — every song (the game's, DWM2's, MIDI files you import) with ▶
  preview on the game's own sound engine, your names for them, and the song of
  each room, gate and kind of battle.
- **Shops** — the game's five shops and your own: what each sells (up to 20
  items) and every item's price; an NPC sells a shop via Rooms tab → NPC →
  Shopkeeper….
- **World** — the graph of rooms and the doors between them (mouse wheel =
  zoom, drag empty space = move around, Fit / + / −).
- **Build & Play** — build the ROM (Ctrl+B) and run it (Ctrl+R).
- **Help** — this tab (F1).

Tabs marked with a roadmap box (Progression & Flags, Balance) are not built yet.

**Every edit can be undone** (Edit → Undo / Redo; View → History shows
the list). File → Save saves the project.

**Testing:** build, then load the ROM with your own save in your emulator.
Build warnings are listed in the Build log at the bottom — read them.
