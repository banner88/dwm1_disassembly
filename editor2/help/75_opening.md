# Your own opening (New game, first monster, first gate)

How to replace the game's opening with your own, from **NEW GAME** to the first gate,
with nothing but the editor. Every step names the tab and the button. The example built
while writing this page (S152, open it: `examples/s152_opening_demo/greatlog_opening`):

> Warubou greets Milly in the roots room and asks her name → he walks her up two path
> screens and into a door (no control) → the GreatLog King's throne room and his scene →
> control → up the stairs to a new farm, where LOGGO gives her first monster → a guard
> who steps aside once she has it → the glade's portal → a new 3-floor gate with a boss.

**Order of work** (each part needs the ones before it): 1 rooms → 2 doors → 3 roots
room → 4 New game → 5 the walk → 6 the throne room → 7 the first monster → 8 the guard
→ 9 the gate → 10 build and test. The flags you make on the way are listed at the end.

## 1. The rooms — Rooms tab

1. **New room…** — a name and the game room whose tileset it uses. The example: GREATLOG
   PATH (GreatTree), GREATLOG THRONE (Castle), GREATLOG FARM (Farm), STUMP HOLLOW (a gate
   theme — the boss floor).
2. More screens: the **+** on the mini-map beside a screen (the path: a screen below
   screen 0 = screen 4; the farm: a screen right of screen 0 = screen 1, the glade).
3. Paint each screen with the metatile picker (the room's own tiles, or *borrow tiles
   from another room*). **Walkable** cells are the ones the player can step on — keep a
   walkable path wherever a scene walks someone.
4. Your own colours (optional): change a colour in the palette panel — the editor asks
   to copy the borrowed palette into your project (*Yes*), then the colours are yours.
5. **Music**: each room's song in the inspector. A boss floor without a song makes the
   build warn — give it one.

## 2. Doors — Rooms tab

1. Select the tile, **+ Door (D)**. Put a door ON the tile you see the opening on (the
   hole in the tree, the top step of the stairs) — not on the wall above it.
2. Double-click one door, then the other: they connect both ways. The player arrives on
   the door tile.
3. The example: the path's door (the hole, screen 0) ↔ the throne room's stairs down;
   the throne room's stairs up ↔ the farm's door.
4. A door that a scene walks the player INTO needs a room state of its own — see part 5,
   step 6.

## 3. The roots room — Cutscenes → Milly hook…

1. **Create the roots room** — the tree-root chamber, with Warubou instead of the old
   man. Tick **Apply the Milly patch** (the player is MILLY: her sprite, her name).
2. **Warubou asks her name** is on for a new roots room: his words, the naming screen
   (it offers MILLY), then his next words. Change his lines with **Edit the scene…**.
3. **Warubou leads her to**: GREATLOG PATH, **screen 4**, the tile she arrives on (the
   example: (4, 6)). OK.

## 4. Where a new game starts — Cutscenes → New game…

1. **The game starts in** — *the game's intro* (the bedroom: Terry, Milayou, Warubou, the
   dresser; with the Milly hook the dresser whirls Milly to the roots room) or *one of
   your rooms*: the room, the screen, the tile (**S** on the picture) and the facing. With
   a room start there is no bedroom and no dresser. The example: the roots room, screen
   0, (5, 4), facing down.
2. **The original game's story** — *as it is* (walk into the game's Castle and the
   Minister / King opening plays and gives Slib) or *as after the original opening* (the
   opening's flags ON: arrived at the Castle, the starter given, Pulio met, the first
   monster taken, the second audience; the Castle, GreatTree, Gate Hub and farm rooms in
   their after-the-opening state). Pick this when your story replaces the game's opening.
3. *The game's intro* + *as after the original opening* needs the Milly hook (the dialog
   says so and refuses otherwise).
4. Gold, items and the party start empty, as in the game.

## 5. The walk up the path (no control) — Rooms tab + Cutscenes

A scene plays on **one screen**, and the player cannot walk off it in a scene. The
game's own way (the old man walking Terry up GreatTree): one scene per screen, joined by
a warp; the helper is an NPC of each screen.

1. **Flags** (any flag picker → **New flag…**): *path walk 1*, *path walk 2*.
2. **Warubou on screen 4** (Rooms tab): select (4, 5) → **Add NPC here…** (his sprite),
   facing up; name him (**Name an NPC…** in the cutscene editor, or right-click him on
   its picture) "Warubou"; NPC panel → **shown when → Flags…**: *path walk 1* OFF.
3. **Warubou on screen 0**: the same at (4, 6), shown when *path walk 1* ON **and**
   *path walk 2* OFF. He is standing there when the screen fades in, and gone for good
   once the walk is done.
4. **Scene 1 — screen 4** (Cutscenes → **＋ New cutscene…**): the room, screen 4, *Plays
   when* = arriving on the screen; **Plays once** with its flag = *path walk 1*; *Player
   starts at* (4, 6), facing up. Steps (**＋ Add step ▾**):
   1. *Say* (speaker Warubou): "This way. Up the path!"
   2. *Walk to a tile*: Warubou → (4, 0), tick **the next step starts at once**.
   3. *Walk to a tile*: the player → (4, 1).
   4. *Wait until everyone stops*.
   5. **Warp the player**: this room, screen 0, (4, 7).
5. **Scene 2 — screen 0**: arriving, **Plays once** = *path walk 2*, *Player starts at*
   (4, 7) facing up. Steps:
   1. *Walk to a tile*: Warubou → (4, 3), **the next step starts at once**.
   2. *Walk to a tile*: the player → (4, 4). *Wait until everyone stops*.
   3. *Turn to face*: Warubou down. *Say*: "The KING waits inside. In you go!"
   4. *Turn to face*: Warubou up. *Walk to a tile*: Warubou → (4, 2) (the hole).
   5. *Sound effect* `$51` (the door sound). *Disappear*: Warubou.
   6. *Walk to a tile*: the player → (4, 2). *Sound effect* `$51`. *Wait* 16.
      *Disappear*: the player. *Wait* 32.
   7. **Warp the player**: GREATLOG THRONE, screen 0, (2, 5) — beside the stairs.
   (A player who disappeared before a warp is shown again when she arrives — the editor
   adds that for you.)
6. **The door must not be there while scene 2 plays** — a door fires the moment the
   player steps on it, even in a scene (the next room loads, the scene goes on there, its
   Warp loads the room AGAIN). As the game does on GreatTree:
   1. Screen 0: **+ Add state → Duplicate this state (shares layout)** (state 1).
   2. The door in state 1 only (in the door's window untick *in every state of this
      screen*; in state 0 delete it).
   3. **State rules → Add…**: state 1 when *path walk 2* is ON.
   While the walk plays (*path walk 2* still OFF when the screen loads) there is no door;
   afterwards the door works both ways. The build refuses a scene whose player walks onto
   a door that is there while it plays, and says so.
7. ▶ **Play** in the scene editor plays a scene in the real game.

## 6. The throne room — Rooms tab + Cutscenes

1. NPCs (**Add NPC here…**): the King (4, 2) facing down, Warubou (6, 5), a guard
   (7, 3). Name them King / Warubou / Guard.
2. Flag *met king* (**New flag…**).
3. **The King's scene** (**＋ New cutscene…**, screen 0, arriving, **Plays once** = *met
   king*, *Player starts at* (2, 5) facing right):
   1. *Walk to a tile*: the player → (4, 4). *Turn to face*: the player up.
   2. *Say* (speaker King): his welcome — **Insert ▾ → the hero's name** puts her name in.
   3. *Turn to face*: Warubou up. *Say* (Warubou).
   4. *Say* (King): "Climb the STAIRS on the right to the GREATLOG FARM. LOGGO will give
      you your first monster."
   When the scene ends the player has control.
4. Their words afterwards (Rooms tab → select the NPC → **New conversation…**): the
   King: *If flags…* *first monster given* ON → "A fine partner!", otherwise → "LOGGO is
   up the stairs". Warubou and the guard: one *Say* each.

## 7. The first monster — Rooms tab → the NPC → Service…

1. The farm (screen 0): **Add NPC here…** LOGGO's sprite at (6, 3) — leave the rows above
   him clear (NPCs near the top can show over the farm window).
2. Select him → **Service…** → **Farm keeper**.
3. *menu lines*: the game's (Pulio's) or **a new line set…** (its words and speaker on
   the Services tab).
4. Tick **hands over the first monster (once)**:
   - *the monster*: a species and a level (the example: DragonKid, level 1);
   - his words the first time (*speaker* LOGGO), e.g. "This DragonKid is yours now! Give
     it a name, then choose PICK UP";
   - *remembered by flag*: *first monster given* (made for you);
   - **the player names it** (the naming screen; unticked it gets its species' name).
5. In the game: the first talk says those words, puts the monster into the **farm**, the
   naming screen opens, then the farm menu — **PICK UP** takes it into the party (the
   game's own way: Pulio and Slib). Later talks: the farm as usual.

Elsewhere a scene step does it: *Give a monster* — into the farm, or ticked **straight
into the party** — with **the player names it**.

## 8. Locking the way until then — the guard

1. Flag *guard moved* (**New flag…**). The guard: **Add NPC here…** at (9, 4), named LOG
   GUARD — standing in the gap to the glade.
2. **+ Add state → Duplicate this state (shares layout)** → in state 1 move the guard
   aside (8, 5). **State rules → Add…**: state 1 when *guard moved* is ON.
3. Two talk scenes (**＋ New cutscene…**, *Plays when* = talking to LOG GUARD):
   - **Only when flags… ▾** *first monster given* OFF: *Say* "No monster, no GATE GLADE!
     LOGGO keeps your first monster."
   - *first monster given* ON, **Plays once** = *guard moved*: *Say* "You are a real master
     now", *Walk to a tile* LOG GUARD → (8, 5), *Turn to face* down.
4. His words in state 1: select him in state 1 → **New conversation…** ("Step on the
   swirl to enter GREATLOG GATE!"). The next time the room loads, state 1 shows him aside.

## 9. The gate — Gates tab + Rooms tab

1. **Gates tab → New gate…**: *copy of* a game gate (its floors and enemies), a *name*
   (GREATLOG GATE), *floors* = 3 (the boss floor included).
2. The boss floor STUMP HOLLOW (part 1, a gate theme): Rooms tab → **Inside gates and
   worlds** → select the arrival tile → **Selected cell**; a song.
3. Gates tab → the gate → **boss floor** = STUMP HOLLOW (the line turns green when ready).
4. The boss's enemy: Gates tab → **Project enemies…** (or the Enemies tab) — species,
   level, stats.
5. The boss NPC: STUMP HOLLOW → select (4, 3) → **Add NPC here…** → **Monsters** tab (the
   monster's own sprite). Select it → **Make boss…**: *boss name*, *its flag* (made for
   you), *Before the battle it says*, *enemies* (your enemy), *After the win*: **the helper
   takes the player to:** GREATLOG FARM screen 1 (5, 5) — the glade — *the helper says
   first*: "Back to the glade!".
6. The portal: GREATLOG FARM screen 1 → select the tile → **More ▾ → Gate entrance
   here…** → GREATLOG GATE. The swirl is painted for you; it spins until the gate's boss
   is beaten, then stops.
7. A keeper by the portal (optional): **Add NPC here…** + **New conversation…** telling
   the player what the swirl is.

## 10. Build and test

1. **Build** (Ctrl+B). Read the warnings in the build log — too many NPCs on one row
   hides some and slows the game; every room of yours should build without a warning.
2. NEW GAME in the emulator (no save needed): the roots room, the naming, the walk, the
   King, the stairs, LOGGO, PICK UP, the guard, the portal, the boss, back to the glade.

## The flags of this opening

| Flag | Turned ON by | Read by |
|---|---|---|
| path walk 1 | scene 1 (Plays once) | Warubou shown on screen 4 (OFF) / screen 0 (ON) |
| path walk 2 | scene 2 (Plays once) | Warubou on screen 0 (OFF); the path's door state (ON) |
| met king | the King's scene (Plays once) | — |
| first monster given | LOGGO's first talk | the King's words, the guard's two scenes |
| guard moved | the guard's second scene | the farm's state rule (the guard aside) |
| (the boss's flag) | Make boss… (after the win) | the gate's cleared swirl |

## Good to know (found while building the example)

- One scene, one screen: chain screens with one *arriving on the screen* scene each,
  joined by *Warp the player* (walking the player off the edge in a scene is refused —
  in the first test build it left Milly out of sight below the screen).
- A door the scene walks the player into must be absent while the scene plays (part 5,
  step 6) — in a test build it fired mid-scene and the next room loaded twice.
- A given monster used to arrive nameless ("0000") — it is named now (its species'
  name, or the naming screen).
- Flag names are kept as slugs: *first monster given* is the flag
  `first_monster_given` in every flag picker.
- *Duplicate this state* copies the NPCs with their names — they keep their names in
  the new state; do not name them again.
- A speaker's name takes room in the box ("LOGGO: …"); **Fit** wraps the text.
- NPCs near the top of the screen can show over a service menu window (the farm's) —
  try the menu in the game and keep the keeper's surroundings clear.
- The game's own Castle, farm and Gate Hub still exist; with *as after the original
  opening* they behave as after the opening (no Minister scene, no Slib).
