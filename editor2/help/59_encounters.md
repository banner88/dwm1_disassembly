# Encounters

The **Encounters** tab decides which wild monsters you meet, where, and how
often. Every answer comes from a copy of the game's own choice and battle
draw that was checked against the game (for every gate floor and thousands of
battles).

## Lists

A battle draws its monsters from a **list**:

- **Five slots** — each an enemy row (a monster at a level, with its stats),
  its **chance** and **Most in one battle** (1 = this monster only ever
  comes alone; 0 = never as the 2nd or 3rd monster; 2-3 = up to that many
  copies together).
- **Monsters per battle** — the chance of a battle with 1, 2 or 3 monsters.
- **Battle rate** — how often battles come (0 very rare … 3 normal … 7
  relentless). Outside gates the editor shows the average number of steps
  between battles; on gate floors the floor type changes it.
- **Maze size** — gate floors only: how many pieces the maze is carved from
  (the game uses 3, 8 or 15).

The game has **128 lists** (0-127); several gates share some of them. **New
list (copy)** makes a list of your own (numbers 128 and up, at most 128) from
the selected one; your lists have names. A list nothing uses is grey.

**Real chance:** the game draws a number 0-99 and takes the first slot whose
running total reaches it, so the first slot with a chance gets one point
more and the slot that ends at 100 one point less (30 / 50 / 20 % really is
31 / 50 / 19 %). The chances must add up to exactly 100 %: change the slots,
watch the total, then **Apply** (one undo step) — or **Revert**.

**Battles it gives most often** lists the commonest groups. **Used by**
lists every gate floor and room that uses the list. How long a fight against
the list takes for a party is a later Balance tab — the levels are shown for
now.

## Gates

Pick a gate: the list of every floor (the last floor is the boss floor — no
maze, no battles). Your **new gates** (Gates tab → New gate…) are at the end
of the list; their floors start on the rule of the gate they copy. A floor on
**the game's rule** keeps the original list (it follows the gate's floor
count). Pick another list for a floor and the gate
uses yours there; set it back to the original list to return to the game's
rule. **Shared:** when one of the gate's lists is also used elsewhere, the tab
says so — changing that list changes it there too. To change only this gate,
make a copy (Lists → New list) and give the copy to the floors.

**Flag variants:** "+ Flag variant…" — when all its flag conditions hold, the
gate uses the variant's lists instead (pick the variant under **Show** and
set its floors; floors you leave alone keep the gate's own plan). The first
variant whose flags hold wins. Example: after the player beats a boss (a flag
set), the Gate of Villager gets stronger monsters.

## Rooms

Every custom room's battles:

- **No battles.**
- **A gate floor's list** — the room uses what that gate floor uses (with its
  plan and variants). The room sets the gate number while you walk there, so
  never use this in a room that is served inside a gate.
- **The dive's own list** — for rooms served on gate floors (Gates tab): the
  floor's list.
- **Its own list** — a list for this room alone, with **flag variants** ("when
  these flags hold, use that list"). Works inside and outside gates.
- **Own battle rate** — a rate for this room, whatever list it uses.

The Rooms tab's "Inside gates" box shows "its own list" for such rooms; the
list itself is set here.
