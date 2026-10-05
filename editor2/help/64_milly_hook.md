# The Milly hook

**Cutscenes → Milly hook…** turns the game into Milayou's story from the intro on.

**What changes when it is ticked ("Apply the Milly patch"):**

- In the intro, when Warubou drags Milayou into the dresser, the dresser glows and the
  screen **whirls** (the same effect and sound as when Terry steps into it) — Terry and
  Watabou never come; the game goes on in the room you pick.
- From that moment the player is **MILLY**: her own sprite in every room (walking all
  four ways), the hero icon on the naming screen, the default name **MILLY** (4 letters,
  like any name). Her monsters follow her as usual; battles, menus and saves keep her.
- Untick it and the game is as before (Terry). Nothing else in the project changes.

**Where Milly arrives:** one of your rooms, the screen, the tile (shown as **M** on the
picture) and which way she faces. **Arrive spinning** = she spins in like Terry does in
the tree roots; unticked she simply appears. (This little arrival scene is made for you;
your room's own entry scene, if it has one, plays right after it.)

**Roots room (Milly):** **Create the roots room** copies the game's tree-root chamber
(where Terry spins in after his dresser) into your project. Instead of the old man, grey
**Warubou** walks up, talks (4 text boxes) and leads her out of the room. When no
arrival is set yet, Milly arrives there.

- **Warubou leads her to** — where the scene sends her at the end: GreatTree (like
  Terry), any of your rooms, or any game room; the screen (only the screens that room
  has) and the tile there.
- **Warubou asks her name** — his text box(es), then the game's naming screen (it
  offers MILLY), then another text box ("MILLY, eh?" — use Insert ▾ → the hero's name).
  On for a new roots room; unticking removes the naming screen and the box after it.
- **Edit the scene…** opens the scene in the cutscene editor: change his lines (the
  speaker and voice too), the walks, add steps — for example **Name the hero** after his
  lines (or tick *Warubou asks her name*).
- It is an ordinary room of yours: paint it, add NPCs, or send Milly somewhere else
  entirely (pick another room above).

**Flags:** the hook has two flags of its own, listed in the flag pickers while it is
on: **the player is Milly** (set at the dresser) and **Milly's arrival scene has played**.
Use them in your scenes or NPC conditions.

**Good to know:**

- The arrival room must be one of your rooms (copy a game room first if you want her in
  one). The build stops with a message when the room, screen or tile is gone.
- Terry still appears where the game shows him as an NPC (they never meet in the
  romhack anyway).
- Starting monsters are up to your project (a *Give a monster* step in a scene).
- Not covered: the debug menu and the link-cable battle screens still draw Terry.
