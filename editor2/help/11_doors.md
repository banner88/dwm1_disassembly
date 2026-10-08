# Doors, teleports and the World tab

A **door** works both ways: step on it and you come out at the door it is
connected to; step on that one and you come back. A **one-way teleport**
only goes there. Both work between your rooms and the game's rooms.

## Add and connect a door

1. Rooms tab → **Select (V)** → click a cell.
2. **+ Door (D)** on the toolbar, or **Add door here** on the *Object* page.
   The door appears at once, marked D? (not connected yet).
3. Double-click it (or **Name / connect…** on the *Object* page). Give it a **Name** and pick the other end under
   *Connected to (two-way)*: one of **Your doors**, or a door of the game
   (*Vanilla doors (the vanilla door will lead here instead)*). Type in the
   search box to find a room or door. The preview shows the other end and the
   green line says where the player arrives, both ways.
4. **OK** — the marker turns D.

The player arrives **standing on the other door's cell**. Arriving never
sets a door off: he steps off and back on to go through again (so two
staircases can land right on each other). A door has one partner: connect it
to a door that is already connected and that door's old partner becomes
unconnected (the dialog warns you). Two game doors cannot be connected to
each other. A door that is not connected does nothing in the game.

**The door panel** (*Object* section, door selected): **this door**,
**connected to**, **arrive there** / **arrive here**, and:

- **in states** — shown when the screen has several states: the door exists
  only in the ticked ones (a door that opens once a boss is beaten).
- **Go to connected door** — jumps to the other end, in whatever room.
- **Disconnect** — both doors stay, unconnected. A game door goes back to
  where the game sends it.
- **Re-aim arrivals** — works out again where the player appears on both
  sides (after repainting walls around a door).
- **Delete door** — removes this door; the door it was connected to stays,
  unconnected.
- Drag the door on the canvas to move it; the other side follows.

**Screen edges.** A door on the edge of a screen that borders another screen
of the same room never fires: walking into that edge scrolls to the next
screen. The editor refuses to put one there, and a door dragged there is
marked D! — move it one cell in.

## Exits that came with a copied room — connect both ends

A copy of a game room keeps the game's exits (and a one-way teleport is an exit
too): they lead somewhere, but they are not doors yet. **Double-click one** —
the same window opens as for a door: *Exit — connect both ends*. Pick the other
end: one of **Your doors**, another of **Your rooms' exits**, or a door of the
game. **OK** makes the exit a door and writes both ends: walking through it takes
the player there, walking back brings him here. A double exit (two cells side by
side, like the Arena Lobby's bottom door) becomes one door — its second cell
follows it (moving, disconnecting, deleting), and a double door of the game is
re-pointed as a whole.

From a game room it works the other way round: open the game's room, double-click
its door, and pick one of your rooms' exits (for example GreatTree's arena door ↔
your Arena Lobby's bottom door).

## Locked doors (S129)

Select a door (or an exit) → **Lock until…** in its panel: the door stays shut
until conditions hold — flags or story checks ("the quest is done", "the bag
holds the Key"). Write the words the player reads pressing A in front of it.
The screen gets a second **room state, the shut look**: the exit is gone there,
its cell a wall, an examine spot says the words; the room shows the open state
while the conditions hold. Paint the closed door in the shut state (it is
selected for you). The room picks its state when it loads — a *Refresh the
room* step right after the flag turns ON opens the door at once. See *Story
checks, quests and the story spine*.

## One-way teleports, step-on triggers, stairs

Select a cell → **More ▾**:

- **One-way teleport here…** — pick the **room** (yours or the game's), the
  **screen** and the cell (click the preview, or **cell x** / **cell y**; for
  a game room **vanilla door** lists its doors). The player arrives exactly
  on that cell; you are warned when it is a wall. On a screen with several
  states, *in every state of this screen (untick: only the state on screen —
  change it later in the door panel)*. Its panel, *One-way exit / teleport*:
  **goes to**, **in states**, **Go to the destination**, **Delete**.
- **Step-on trigger here…** — write what happens (a talk: text, a question,
  flags, moving the player). It runs when the player **walks** onto the cell,
  not when he arrives there through a door. Invisible, marked T. Its panel
  has **script**, **New talk…**, **Edit talk…**, **in states**, **Delete**.
  (Examine spots: see *NPCs*.)
- **Stairs down here (gate rooms)** — the cell gets the next-floor well; its
  panel *Stairs down* goes to *the next floor of the gate being dived*. It
  only works while the room is served inside a gate — see *Gates*.
- **Gate entrance here…** / **World entrance here…** — see *Gates* and
  *Worlds*. A world's portal shows as **P**; the cell where a world's portal
  lands the player shows as **W↓** in that room (drag it to move).

## Game doors into your rooms

Open one of the game's rooms (read-only) and select one of its doors:

- Double-click it → connect it to one of your doors (two-way). A double
  door (two cells side by side) changes as a whole.
- **Route this door into a custom room…** — one way only: pick your room;
  *Route a vanilla door into this room* opens with the *Vanilla door
  (source)* filled in. Choose the arrival **screen** and **arrive at cell x**
  / **arrive at cell y**. The other doors of that screen keep their destinations.
- **Lead this portal to another gate…** — on a gate portal: see *Gates*.

In your own room, *Doors & entrances — how the player gets here* (in *Room /
screen / selection*) lists the room's doors, what each is connected to, and
the game doors routed one-way into it. Double-click a line or **Show** to go
to it; **Remove** deletes the selected door or one-way route. **One-way from
a vanilla door…** opens the same route dialog from here.

## The World tab

A map of how the player gets from room to room: your rooms (a picture of
their first screen) and the game rooms they connect to. The legend gives the
lines: door (two-way), one-way exit, game door → here, script warp (a talk
or script that moves the player), game exit. Hover a line to see what it is.

- Mouse wheel = zoom, drag empty space = move around, **Fit** / **+** / **−**.
- Drag a room to untangle the lines (not saved); **Re-layout** redraws.
- **whole vanilla world** — also every game room and exit (big and slow).
- **only this world** — with a world picked on the left: only its rooms
  (green frames) and the rooms around them.
- Double-click a room to open it on the Rooms tab.

The *Worlds* panel on the left is explained in *Worlds*.
