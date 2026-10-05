# Boss floors — step by step

1. **Room:** Rooms tab → **New** → name + tileset. Add screens on the
   mini-map (**+**) if you want more than one.
2. **Inside gates and worlds:** select the cell where the player appears → **Selected
   cell** (arrival). Pick a **music** song. (Saving is off automatically;
   no Stairs down needed — the boss room ends the dive.)
3. **Enemy:** Gates tab → **Project enemies…** → *Add from vanilla…*, set
   stats, *joins?*, and **Make join version** if it can join.
4. **Boss NPC:** select a cell → **Add NPC here…** → **Monsters** tab.
5. **Conversation:** with the NPC selected → **New conversation…**, e.g.
   - `Say` "…" → `Battle` (your enemy ★) → `Turn flags ON` **New flag…**
     `lord_beaten` → `Helper takes the player away` (destination; tick
     *Warubou says something first* for a line; at the Castle choose
     nothing / the priest's heal / the King's speech).
   - Or with a question: `Ask YES / NO`, the battle etc. under *If YES*,
     a `Say` + `Stop here` under *If NO*.
   - **Quicker** (S123): select the NPC → **Make boss…** — the texts, 1-3
     enemies (your ★ ones or the game's), the beaten flag (made for you), and
     *afterwards*: the helper takes the player away (to the Castle with the
     priest's heal, say) or the player stays and the boss **vanishes**. It
     writes the conversation above; edit it afterwards like any other.
   - A fight when the player arrives: *Inside gates and worlds* → **Arrival
     conversation…** (start with *If flags…* `lord_beaten` OFF).
6. **Hook it up:** Gates tab → the gate → **floors** and **boss floor** =
   your room (the line under it turns green when the room is ready).
7. **Build**, then dive into that gate on your save.

**The "beaten" version of the room** (the boss gone, an exit open, …):

1. On the boss screen: **+ Add state** → *Duplicate this state* → in the
   new state (state 1) delete the boss NPC, add an exit, change tiles …
2. *State rules* → **Add…** → state **1** when `lord_beaten` is **ON**.
3. The conversation turns `lord_beaten` ON after the battle (step 5).
   The next time the room loads it shows state 1.

**Or, without a second state:** a boss that stays in the room ends its
conversation with a **Vanish** step (it flickers out at once) and has *shown
when* `lord_beaten` OFF (it stays gone) — *Make boss…* does both. A boss that
stands in a doorway opens the way by leaving.

Mini-bosses and bosses outside gates — in a **world** or in any room of yours
— work the same way (see *Worlds*).

The helper lands next to the player automatically. If the player talks to
the boss from its right, the helper lands on the boss's cell (the boss is
not drawn after its battle anyway).
