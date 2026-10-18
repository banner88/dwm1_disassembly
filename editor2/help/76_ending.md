# Your title screen and your ending (credits, TO BE CONTINUED)

How to put your romhack's name on the title screen, end your story with a final scene that
rolls the credits, write your own credits pages, and go on after the credits ("…TO BE
CONTINUED", the save, the post-game). Every step names the tab and the button. The example
built while writing this page (S153, open it: `examples/s153_ending_demo/milayous_journey`):

> The title says **Milayou's Journey** under the logo → NEW GAME starts in THE LAST GLADE →
> the ENDING SAGE asks "Shall the tale end?" → YES: the original game's story jumps to its
> very end, the credits roll (the game's pages + two new ones, 2 seconds a page) → THE
> AFTER ROOM → "…TO BE CONTINUED", the save → CONTINUE → the AFTER KEEPER sends the player
> into the game's Castle for the post-game.

**Order of work:** 1 the title → 2 the credits → 3 the room after the credits → 4 the
final scene → 5 TO BE CONTINUED → 6 the post-game → 7 build and test.

## 1. The title screen — Cutscenes → Title & ending… → Title screen

1. **＋ Line** adds a line of text. Each line has:
   - **Text**: letters, digits and the game's punctuation (the dialogue font), at most
     20 letters (the screen is 20 letters wide).
   - **Row**: 0-17 (top to bottom).
   - **Column**: *centred*, or the letter column 0-19 where the line starts.
   - **Colour**: black, orange (the logo's orange) or red. The title has only one
     palette, so these are the only colours.
2. The **picture** on the right is the title as the game draws it, pixel for pixel, so
   what you see there is what the game shows.
3. Rows **0-5, 12-14 and 17** are empty in the game. Rows 6-11 hold the logo and rows
   15-16 the copyright, so a line on those rows covers part of them (the dialog warns).
   The example puts *Milayou's Journey* on row 13, in orange, centred.
4. Up to 8 lines and 128 different letter shapes (a letter used twice counts once). Two
   lines must not overlap.
5. **Song**: the title's music (the game's own is song $06), either one of the game's
   songs or one of your project's songs (Music tab).
6. The title text shows on the **Game Boy Color** only. On an original Game Boy the
   title stays as the game draws it.

## 2. The credits — Cutscenes → Title & ending… → Credits

1. The list shows every page. A new project starts with **the game's 27 pages**. The
   last page is always the **closing page**, with the copyright lines and a Slime.
2. **＋ Page** adds a page after the selected one. **Remove**, **▲** and **▼** remove a page
   or move it. **The game's pages** puts the original 27 back. Up to 64 pages.
3. Each page has:
   - **Role**: the heading, 2 rows of 20 letters (a role line longer than 19 / 18
     letters runs past the picture). A new line in the box starts the next row.
   - **Names**: 12 rows of 11 letters. An empty line leaves an empty row.
   - **Monster**: the monster drawn at the bottom right (any of the game's monsters, or
     one of your new species, 221-239).
4. The **picture** is the page as the game draws it, with the monster in its own
   colours. A letter that falls outside the picture is warned about. The game's own page
   19 already does this ("YONEYAM"); fix it if you like.
5. **Seconds a page**: 5 in the game. The example uses 2.
6. **Credits song** (the game's $21) and **"TO BE CONTINUED" song** (the game's $31).
7. **OK** saves both tabs as one change (Edit → Undo takes it back).

The credits words are the game's own texts (Text tab → Credits). Once your project has
its own pages, the words are edited here, and this dialog is the place for them.

## 3. The room after the credits — Rooms tab

When the credits are over, the game goes on in **a room and a tile you pick** in the
step (part 4). In the game it is the intro bedroom. Make the room as any other (Rooms →
New room…). The example: THE AFTER ROOM (the Farm's tileset, golden colours), with the
AFTER KEEPER.

## 4. The final scene — Cutscenes → ＋ New cutscene… → ＋ Add step → The ending

Any scene can be the final one, whatever starts it (entering, talking, examining, stepping on). The
example is a talk scene on the ENDING SAGE with an **Ask** step. YES runs:

1. **Story point** (optional): the ORIGINAL game's story jumps to a point of its own
   story. Every flag and room state the game's own scripts would have left by then is
   set at once, so the game's rooms (GreatTree, the Castle, the arena, the gates) act as
   at that point. Pick the point in the list. *everything done* = after Monster
   Grandpa's match, the very end. **the arena classes too** (ticked) also marks the arena classes
   won by then. **Your own flags are not touched.**
2. **Set** your own flag (the example: *journey_over*), if a later scene needs to know.
3. **Say** the last words.
4. **Roll the credits**: pick the room, the screen and the tile where the game goes on
   afterwards (THE AFTER ROOM, screen 0, (4, 4)). The scene ends here. Steps after it
   never run (the editor warns).

When the credits are over, the player is on that tile and the room's **entry scenes
play** (that is how part 5 starts).

## 5. "…TO BE CONTINUED" — an entry scene of the room after the credits

1. ＋ New cutscene… in THE AFTER ROOM, trigger **Entering the room (this screen)**, tick
   **Plays once** (the example names its flag *tbc_shown*).
2. Steps: a **Say** if you like, then **The ending → TO BE CONTINUED**.
3. In the game the screen shows "…TO BE CONTINUED". A button asks "save?", and YES saves
   the game ("Saved! Please turn off the power."). Then the game waits for the player to
   switch off. Its words: Text tab → Credits, row 0 of the "TO BE CONTINUED" texts; the
   question and the answers are Dialogue $0256 / $0257 / $0258. Its song: part 2.6.
4. The scene's **Plays once** flag is already ON when the game saves, so CONTINUE does not
   show "TO BE CONTINUED" again.

## 6. The post-game — after CONTINUE

**CONTINUE puts the player back in the room where the save was made** (THE AFTER ROOM).
**The room's entry scenes do NOT play on CONTINUE.** The game's own load runs no entry
scene (measured, S153), so the post-game starts from something the player does:

- a **talk** scene (the example: the AFTER KEEPER, *when tbc_shown is ON*, Plays once:
  "Welcome back!", then **Move the player** to the game's Castle, screen 1, (5, 6)),
- a **step-on** or **examine** scene,
- or simply a **door** out of the room.

The original game's rooms are now as at the story point of part 4.1.

## 7. Build and test

1. **Build**. The build warns about anything that cannot work: a page longer than its
   grid, a monster that is not a monster (TERRY? and the summons, 215-220), steps after
   Roll the credits, a title line on the logo.
2. Test: NEW GAME → the title shows your lines → the final scene → the credits (your
   pages) → the room after them → TO BE CONTINUED → YES (the save) → switch off → CONTINUE
   → the post-game.
3. A shortcut to the final scene: New game… → *one of your rooms* (help: Your own opening).
   A room start has no naming, so `{hero}` prints the game's placeholder, "TERRY0000" (the game
   fills the name with TERRY + four 0s and only the King's naming screen ends it properly). Add a
   **Name the hero** step first if your words use it.

## Limits

| What | Limit |
|---|---|
| Title lines / different letters | 8 / 128 (Game Boy Color only) |
| Credits pages | 64 (the last = the closing page) |
| Role / names | 2 rows × 20 / 12 rows × 11 letters |
| Different story points used | 32 (a point with and without the arena = 2) |
| Seconds a page | 1-60 |
