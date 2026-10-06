# Worlds

A **world** is a place of your own rooms that the player enters through a
swirling **portal**, exactly like a gate: the same wave and cream fade, the
same rules (lose a battle and you wake up at home — the Castle, where the
priest heals the party, or your own hub (see *The hub*) — and half your gold
is gone). But a world is not a random maze: inside it
is your rooms, joined by doors, each with its own battles (or none), saving,
people, mini-bosses and an end boss. Beating the end boss **clears** the world:
the portal's swirl stops, or keeps spinning in another colour (green, say).

## Make one, step by step

1. **World tab → New world…** — a name, and its **start room**: a NEW room in
   one of the 16 gate looks (see *Gate themes*), or one of your rooms. The room
   is drawn on the right: **click the cell** where the portal drops the player
   (green **LAND**). A wall cell is refused.
2. **More rooms** — World tab → *New room…* (a gate look) or *Add room…* (one
   of yours). Join them with **doors** on the Rooms tab (*Add door here*,
   double-click to connect). The World tab lists which rooms the doors join.
3. **The portal** — World tab → *The way in* → **Add portal…**: pick one of
   your rooms outside the world, **click the cell** for the swirl (blue
   **PORTAL**). Or on the Rooms tab: select a cell → **More ▾ →
   World entrance here…**. The cell gets the swirl picture and the spinning swirl. You can
   have several portals.
4. **A way out** — a door or one-way exit from a world room back to your other
   rooms, and/or the end boss's helper (step 6).
5. **Battles** — Encounters tab → *Rooms*: give each room with battles a list
   of its own. Rooms without battles are "calm". A **flag variant** switches the
   list later — e.g. other monsters once the world is cleared
   (`world cleared — <name>` in the flag list).
6. **Bosses** — select an NPC (a person, an object or a monster) → **Make
   boss…**: what it says, a battle of 1-3 enemies, what it says after, its own
   **beaten** flag (made for you), and:
   - **END boss of world** — it also clears the world;
   - **afterwards** — the player stays, or the **helper** (Warubou) flies in,
     can say something, and takes the player somewhere (by default: in front of
     the world's portal, so you see the swirl change).

   A beaten boss **flickers out at once** (the Vanish step) and stays gone for
   good (it is shown only while its flag is OFF). An NPC standing in a doorway
   is a guard: once beaten, the way is open.
7. **Build**, then walk into the portal on your save.

## The World tab — Worlds panel

**The way in** — two pictures side by side:

- **① The portal** — the room with the swirl the player steps on, the portal
  cell outlined in blue. With several portals, ◀ ▶ step through them.
  **Add portal…** (pick a room, click the cell), **Go to** (opens that room on
  the Rooms tab with the portal selected), **Remove** (the exit and the
  spinning swirl go; the still swirl picture stays painted — repaint it).
- **② Lands here** — the world's start room, the landing cell outlined in
  green. **Change…** (pick the room, click the cell), **Go to**.

On the Rooms tab the same two places are marked on the canvas: **P** = a
portal into a world (hover: where it lands you), **W↓** = where a world's
portal lands the player — drag it to move the landing.

**This world:**

- **after clearing, the swirl** — *stops* (the game's way) or **turns** one of
  the 8 sprite colours: grey / red, **green**, blue (its own), yellow, purple,
  grey, orange, brown.
- **saving (JOURNAL)** — *in rooms without battles* (default), *in every room*,
  or *nowhere*. A room can still decide for itself: Rooms tab → *Inside gates
  and worlds* → **save**.
- **cleared** — the world's cleared flag (`$17A0` + its number). Only a boss
  conversation turns it on (Make boss → END boss does it).
- **Its rooms** — per room: its battles (list number, flag variants), whether
  you can save there, its bosses (★ = the start room, END boss marked), and the
  rooms its doors lead to. Double-click = open it. **Music for every room…**
  gives every room without a song of its own the same song.
- **Still needs** — what the world lacks: a portal, a room no door reaches,
  nothing that clears it, no way out, a room with battles but no list.
- **only this world** (graph) — just the world's rooms (green frames) and the
  rooms around them.

**Rename… / Delete** (under the list) rename or delete the selected world.

The Gates tab lists the world as **WORLD** (a world uses one of the new gate
numbers 32-95); its maze settings there do not apply.

## Flags and triggers

Everything that can test a flag can react to bosses and to the world: a door
that opens (a room **state** shown when `fern_lord_beaten` is ON), a person
whose words change (*If flags…* in a conversation), an NPC that appears or
goes away (*shown when*), battle lists (flag variants), and the portal swirl.
Mini-bosses each have their own flag; the end boss also turns on the world's.

## NPC colours

Any NPC (not monster NPCs, which walk in their own colours) can be drawn in
one of the game's 8 sprite palettes: NPC section → **colour**. The swatch shows
each palette's main colour. Handy for a red guard, a green villager, a second
portal colour …

## Good to know

- Inside a world there is no maze and no stairs: the world's rooms are
  ordinary rooms of yours; only the way in (the portal) and losing a battle
  work the gate way.
- An ordinary gate can turn its swirl a colour too: Gates tab → *after
  clearing, the swirl*.
- The swirl's spinning object takes the colour; the still swirl picture under
  it keeps the room's colours.
- A world room's music: its own song, else whatever is playing (when you come
  through the portal: the gate theme). Use *Music for every room…*.
- A room belongs to at most one world. Deleting a world removes its portals
  and swirls; its rooms stay.
