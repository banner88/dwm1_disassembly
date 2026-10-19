# The memorial: statues of the monsters that left

A **memorial statue** stands in one of your rooms and shows a monster that **won a boss
battle, an arena class or Starry Night** with the player and has **left** since: bred
away, released at the farm, traded. Every statue of a room shows a **different** monster,
picked at random each time the player comes into the room. Examining a statue says its
words, by default:

> In memory of SLIB, a level 23 DrakSlime.

A statue is a **pedestal with the monster standing on it**, grey, on the floor of the
room. A statue with no monster to show is just the pedestal, and it says "A blank
statue, quiet and cold." The example built while writing this page (S154, the user's
project + `examples/s154_memorial_demo/build_demo.py`):

> In Cities_FOUNT the MEMORIAL GUIDE sends you to THE MEMORIAL HALL: three statues on
> the back row, the CHAMPION (beat him: your party is remembered), the MASON (YES: the
> hall's second room state has five statues), and east the FARM KEEPER, the BREEDER
> (breed a monster away) and the EXIT GUIDE. THE MEMORIAL CRYPT, deep in gate 2 (floor 2),
> has two more statues.

**Order of work:** 1 the room → 2 the statues → 3 their pictures → 4 their colours →
5 their words → 6 more statues later in the game → 7 in a gate → 8 build and test.

## 1. A room for the statues — Rooms tab

Any room of your project can have statues (not the game's own rooms). New room… makes a
fresh one. Up to **8 statues a room**.

## 2. Add a statue — Rooms tab, Select tool

A statue takes **two cells**: its **pedestal** and, on the cell above it, the
**monster** standing on it.

1. Click the cell where the pedestal goes (the Select tool, **V**). Pick a cell below the
   top row, because the monster needs the cell above.
2. Press **＋ Statue (U)** on the tool bar.
3. The editor does the following:
   - **The pedestal cell** gets the room's **Pedestal** metatile. The room's first statue
     makes it (a stone column drawn over the floor that was on the cell). Every later
     statue of the room uses the same one.
   - **The cell above** gets 4 new tiles of its own, the statue's **monster cell**. They
     start as a copy of what was drawn there (the floor or the wall behind). The game
     draws the monster over them.
   - **Both cells** use the statue palette (part 4).
   - **Both cells are solid**: their bottom-right tiles are on the wall side.
4. If the tileset is full of the room's vocabulary (a gate-theme room, for example), the
   editor asks whether to **release the unused vocabulary** (the maze tiles the room never
   draws). Yes frees them.
5. The statue shows on the canvas with an **M** on its pedestal. Click it to open the
   *Memorial statue* panel on the Object page. The status line says which palette slot
   the statue got.

What happens in the game: the pedestal is an **examine spot** (A while facing it, from
any side). Statues fill in their **order**: statue 1 gets a monster first. The panel's
**Earlier** / **Later** buttons change that order. It matters when fewer monsters have
left than the room has statues.

## 3. The pictures — Draw tab / Tileset tab

- **The pedestal** is an ordinary metatile named **Pedestal** in the room's tileset. Redraw
  it in the **Draw** tab, for example as a plinth, a broken column or a tombstone. Every
  statue of the room shows the change.
- **The monster cell**: when a monster stands there, the game draws its **standing
  picture** (its walking frame "facing down", as the game draws it) over those 4 tiles,
  bottom-aligned, so it stands on the pedestal. Where the monster has no pixel, the
  tiles show through. Because they hold a copy of the floor behind, the statue looks
  **see-through**. With no monster, the cell just shows the floor.
- The monster cell's 4 tiles belong to the statue. The Tileset tab marks them
  **statue**, and nothing else may use them. If you redraw the floor around the statue,
  redraw those 4 tiles too, or the old floor shows behind the monster.
- A monster picture is 16 × 16. 194 of the 215 monsters fit exactly; the rest are moved
  to stand centred on the bottom row. None is cut.
- It works for **monsters with new art** (Monsters tab, a new walking picture and its
  layout) and for **your new species**. The game draws the art the build gives that
  monster.

## 4. Its colours — automatic (Palettes to change the grey)

A Game Boy Color background tile has no see-through colour. Each 8 × 8 tile draws with
one palette slot of 4 colours, and colours 1 and 3 are always the engine's cream and
black. So the editor sets up the statue's colours as follows:

- It looks at the 4 colours the monster cell's background uses. It picks **colour 0 or
  colour 2**, whichever the background does not use.
- It gives the statue a **palette slot** whose colours are the background's own, except
  that the picked colour is **grey** (`$4210`). This is an existing slot that already
  has those colours, or else a free slot (0-3) that no screen of any room drawing with
  that palette uses.
- The monster is drawn in **cream (its light shade), the grey (its middle shade) and
  black (its outline)**. The background keeps its exact colours.

To change the grey, edit that colour of the statue's slot in **Palettes**. The panel
says which slot and colour it is. Some limits:

- **No free slot**: the statue uses the background's own slot, and the monster's middle
  shade shows that slot's colour instead of grey. The status line says so. Free a slot
  and add the statue again for a grey statue.
- **A background drawn with two palette slots in one cell** (some of the game's own
  cells mix slots): some background pixels show the nearest colour. The status line
  counts them, and you can touch them up in the Draw tab.

## 5. Its words — the panel's buttons

- **Memorial settings…** (every statue's words, unless one has its own):
  - **remembers up to** 8-120 monsters (120 by default). When it is full, the monster
    remembered longest ago is forgotten.
  - **A statue says**: the words when it shows a monster. Three inserts work here and
    **only here**: `{fallen}` = the monster's nickname, `{fallen_level}` = its level
    when it last won, `{fallen_species}` = its kind (DrakSlime…). The game box previews
    them as "Slib", "23", "DrakSlime".
  - **An empty statue says**: the words with no monster on it.
- **Its words…**: tick *This statue has words of its own* and write them (the same
  inserts), or untick to go back to the memorial's.
- Using the inserts anywhere else is refused by the build. Outside a statue's words the
  game would print whatever happens to be in memory, and could crash.

## 6. More statues later in the game — room states

A room's **states** (Screen page) can hold different statues. The user's wish: "maybe I
want to have more statues as game goes on". The example's hall:

1. Screen page → **Duplicate state** of state 0. State 1 has the same three statues.
2. In state 1 add two more with **＋ Statue**. They use the room's Pedestal too.
3. Room page → State rules: state 1 when the flag `memorial_hall_grown` is ON (the MASON
   turns it ON and refreshes the room).

When you add a statue in a state where the room's other statues do not stand yet, the
editor asks whether it is **a new statue** or **one of the room's statues** (the same
monster wherever it stands). The panel's **in states** boxes do the same for the
selected statue.

## 7. In a gate — Gates tab

A room with statues can be served on gate floors like any room (Gates tab → the gate →
add the room to a floor, or Rooms → "Inside gates and worlds"). It needs a gate arrival
cell and Stairs down. The example's CRYPT is gate 2's floor 2, once a dive.

## 8. What counts, and what the player sees

- **Remembered**: every monster in the party (fainted ones too) when the player **wins**:
  - a boss battle: every gate boss of the game, a new boss of a gate (yours or a
    re-bossed one), every battle of a project conversation (Make boss…, the Battle step).
    Also the three bosses the game fights with a plain battle: Digster, Durran, Terry;
  - an **arena class** (its third match),
  - **Starry Night** (the final).
- **Not remembered**: wild battles, the game's other scripted battles, a lost or fled
  battle, a class's first two matches, Starry Night's first rounds, Monster Grandpa's
  match. A monster that **joins** in that battle is not a winner of it.
- A monster is remembered **once**. Another win only updates its level (and nickname).
- It is on a statue only after it has **left the player**. The game looks at the farm
  and the party (and the sleeping farm, when you use it) each time the room loads.
- **Each visit** (entering the room from another place) picks again. A battle in the
  room, the menu or the breeding screens keep the statues as they were.
- Statues on another screen of the room are picked at the same time (one pick per room).
- The memorial follows the **save**. A reset without saving forgets the victories since
  the last save, like the rest of the game. A save made before the memorial existed
  starts with an empty memorial; past victories are not known.

## Good to know

- How the game knows the monster left: at a win it marks the monster's record with a
  number (the 27th resistance byte, which no skill uses). The statue's monster is "gone"
  when no monster with that number and species is in the farm or the party. Keep
  every monster's **27th resistance at 0** in the Monsters tab; the build refuses
  otherwise while the project has statues.
- The memorial lives in the save's bank 3 (about 1 KB for 120 monsters). See the
  Capacity tab.
- Build → Play here in the hall: the statues are empty until a monster has won and left.
  On your own save, win a boss, breed one of the winners, then visit the hall.
