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
  (the way the vanilla portals work). The cell gets the next-floor hole
  picture; repaint it as you like. Until a gate has an entrance nothing can
  enter it (the head line and the build warnings say so).

**Rename…** and **Delete** work on new gates only. Deleting a gate also
removes its custom-room rules and entrances (Undo brings them back). The
name is for the editor; the build does not put it into the game.
