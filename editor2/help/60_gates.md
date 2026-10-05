# Gates

The Gates tab lists the 32 vanilla gates and your **new gates** (★ = has
custom-room rules, ♛ = custom boss floor, ✎ = hand-made, NEW = a gate of
your own).

**Gate settings** (per gate):

- **floors** — floors in one dive, INCLUDING the boss floor (2-99);
  *Vanilla* resets it.
- **boss floor** — vanilla, another gate's vanilla boss room, or any of your
  rooms (it needs an arrival cell). *Open room* jumps to it.
- **hand-made gate** — your rooms may also take floor 1 (normally the gate's
  own). Give every floor a room served at 100 %.

**Custom rooms in this gate** — rules "serve room R on floors a-b with
chance p % [once per dive] [when flags …]", tried top-down. **Floor plan**
shows, floor by floor, what the game serves.

A room served on a gate floor needs (Rooms tab → *Inside gates*): an
**arrival** cell, a **Stairs down** (More ▾ → Stairs down here), battles off
or "follow the gate", and optionally its own song (without one it plays the
gate's song when the gate has one — Music tab → Gates). Saving: allowed by
default in gate rooms, off in boss rooms.

## New gates

**New gate…** (under the list) makes a brand-new gate (numbers 32-95) as a
**copy of** a vanilla gate: pick the gate it copies, a name and the floor
count. The copy keeps that gate's look — its maze floors, special rooms
(treasure / priest / forest rooms on floors 3, 6, 9 …) and depth tier (item
tier) — and starts with its boss room and monsters. Then make it yours:

- **boss floor** — give it a custom boss room. Keeping the copied gate's
  vanilla boss room works, but that room runs its own story scripts (the
  original gate's cleared flag, boss and King's speech).
- **monsters** — Encounters tab → Gates: the new gate is in the list; give
  its floors your own lists. Floors you leave alone use the copied gate's.
- **custom rooms** — rules on this tab work on new gates like on any gate.
- **entrance** — Rooms tab: select a cell, then More ▾ →
  **Gate entrance here…** and pick the gate. Stepping on that cell starts a dive at floor 1
  (the way the vanilla portals work). The cell gets the portal's **swirl**
  — the still swirl picture and the spinning swirl object on top — like the
  vanilla portals. Repaint or delete either as you like. Until a gate has an
  entrance nothing can enter it (the head line and the build warnings say so).

**Rename…** and **Delete** work on new gates only. Deleting a gate also
removes its custom-room rules and entrances (Undo brings them back). The
name is for the editor; the build does not put it into the game.

## Swirls and "cleared"

Every gate has a **cleared** flag — the head line on this tab names it. The
game's gates use their own (Villager = `$0011` …); a new gate — or a game's
gate you gave a custom boss floor — uses its own project flag (`$17A0` + the
gate number: gate 32 = `$17C0`). Beating a gate's boss turns it ON (for a
re-bossed game gate, the game's own flag too).

The swirl on a portal **spins until its gate is cleared**, then stops (the
still picture stays, and the portal still enters the gate — as in the game).
The editor does this for you:

- **Boss cleared → no swirl.** A gate entrance you add (*Gate entrance
  here…*) gets a swirl object that shows only while its gate is not cleared.
- **A new boss → the swirl comes back.** Give a vanilla gate a custom boss
  floor and its portals in the vanilla rooms spin again until YOUR boss is
  beaten (the gate's own cleared flag, not the game's).
- **Re-route a portal → its swirl follows the new gate.** In a vanilla room
  (e.g. the Villager / Talisman portal room), select a portal's exit and press
  **Lead this portal to another gate…**: walking onto it enters the gate you pick, and
  its swirl spins until THAT gate is cleared. Pick *(back to the gate the
  game gives it)* to undo it. The Gates tab lists re-routed portals as the
  gate's entrances.

In flag lists the cleared flags appear as **gate:N cleared — name**: use
them anywhere a flag can be tested (a state rule, a conversation's *If
flags…*, an encounter variant) — e.g. a guard who moves once your gate is
cleared.


## Maze floors: look, special rooms, contents, item tier (S120)

*Maze floors* (under Gate settings) sets what a gate's random floors are like.
The game keeps three shared tables of **rows**; each gate points at one row of
each. Pick the row of the gates you want yours to feel like — the list names
the gates that use each row and what it rolls:

- **maze look** — which of the 16 maze floor types appear (the pictures beside
  it are the game's own floors, with their chances).
- **special rooms** — what floors 3, 6, 9 … may be instead of a maze, about
  half the time: treasure rooms, the forest maze, the priest, the item shop, the
  Coliseum, the mazes, the conveyor mazes (never in gate 0).
- **contents** — the mix of things lying on the floors (and the treasure
  rooms' chests).
- **item tier** 1-3 — how good the ground items are.

**Vanilla** puts the gate's own rows back (a new gate: its source's). The rows
are shared: picking one never changes another gate.

How a maze floor is put together (pieces, stairs, items) and how to use the
16 maze looks in your own rooms: see **Gate themes**. The size of the maze is
the *Maze size* of the floor's battle list (Encounters tab, 3-15).
