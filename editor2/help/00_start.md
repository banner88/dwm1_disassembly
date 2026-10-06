# Getting started

The editor works on a **project** — a folder with `project.json` and its
assets. Everything you change is saved into the project; the game ROM is
built from it (the original ROM is never changed).

**Tabs**

- **Rooms** — paint rooms, their screens and states; NPCs, doors, spots,
  talk and conversations; NPC colours and **Make boss…**; "Inside gates and
  worlds" settings for gate / boss floors and world rooms. See *Rooms*,
  *Doors, teleports and the World tab*, *Tilesets, metatiles and palettes*.
- **Import art** — turn a PNG rip into a room tileset (see *Import art*).
- **Cutscenes** — every scene of the game and of your rooms as a storyboard
  (steps in words, pictures recorded from the game) and **▶ Play**: the
  game plays the scene right here, with sound, set up for you (the intro
  chain included); **＋ New cutscene** makes your own scenes on the room
  itself, in tiles, with named NPCs and cast members, previewed instantly or
  played in the game.
- **Gates** — which custom rooms appear on which gate floors, per-gate
  settings (floor count, boss floor, hand-made gates, project enemies) and
  **new gates** of your own (a copy of a vanilla gate; entrances on the Rooms
  tab). A portal's swirl spins until its gate's boss is beaten — or, per
  gate, turns another colour instead. A **world** shows here as WORLD.
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
- **Services** — the Vault, farm, library, namer, Medal Man, egg appraiser
  and gate guide NPCs you placed (Rooms tab → NPC → Service…), what their
  menus say (line sets), and the Medal Man's rewards.
- **Progression & Flags** — every flag of your game: what turns it ON / OFF
  and what checks it, in words; **show** draws the place (the room screen in
  its state, the NPC outlined) in a panel on the right, where you can also
  **name NPCs** (yours and the original game's); your flags' notes, Rename /
  Renumber / Delete; every "When … → …" trigger; the Problems (checks that are
  never true, copied rooms waiting for the original game's progress) — see
  *Flags*.
- **World** — the graph of rooms and the doors between them (mouse wheel =
  zoom, drag empty space = move around, Fit / + / −), and the **Worlds**
  panel: your own worlds — places of hand-made rooms entered through a portal
  like a gate, with per-room battles, mini-bosses and an end boss that clears
  the world (see *Worlds*); and the **Hub** box: where a lost battle, the
  WarpWing or "home" send the player — your room instead of the Castle,
  changing with flags (see *The hub*).
- **Build & Play** — build the ROM (Ctrl+B) and run it (Ctrl+R).
- **Help** — this tab (F1).

Tabs marked with a roadmap box (Balance) are not built yet. Story milestones,
quests and new kinds of checks (items, gold, monsters) are coming to
Progression & Flags (ROADMAP P3.14b-d).

**Every edit can be undone** (Edit → Undo / Redo; View → History shows
the list). File → Save saves the project.

**Testing:** build, then load the ROM with your own save in your emulator.
Build warnings are listed in the Build log at the bottom — read them.
