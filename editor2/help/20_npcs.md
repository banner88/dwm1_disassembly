# NPCs, monsters, spots and doors

Select a cell (Select tool, V), then in *Room / screen / selection*:

- **Add NPC here…** — pick a sprite. The **People & objects** tab lists the
  vanilla NPC sprites; the **Monsters** tab lists every monster, drawn like
  its follower (up to **4 different monsters per screen**; Diago, Samsi,
  Bazoo and the last species are not offered — they crash the game).
- **Add examine spot here…** / More ▾ → **Step-on trigger here…** — text or
  actions without a visible NPC.
- **Add door here** — a door you connect to another door (double-click).
  More ▾ → **One-way teleport here…**, **Stairs down here (gate rooms)**.

Select an NPC to edit it in the *Object* section: sprite, facing, behaviour
(stand / walk / spin …), hidden, which script it runs, and which states it
is present in. Drag it on the canvas to move it.

An NPC says or does something through a **talk** (New talk…: text, an
optional YES/NO, flags, moving the player) or a **conversation** (New
conversation…: the full step tree — see *Conversations*).

The engine caps a screen at 8 NPCs; many different sprites on one screen
can draw blank (sprite memory) — repeats are free.
