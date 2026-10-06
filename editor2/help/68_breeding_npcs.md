# Breeding NPCs (Grandpa, breeders, breeding pools)

Breeding works in **your own rooms**. Rooms tab → select an NPC →
**Service…** → pick:

- **Grandpa (breeding)** — the Starry Shrine's Grandpa: **BREED** (your
  pedigree + a mate from your party or farm), **HATCH** (an egg from the
  farm), **EXIT**. After the night ceremony the game comes back to this
  room: Grandpa turns to you ("Inside it is a baby …! Costs …G to hatch it.
  Okay?"), then the naming screen and "Take … with you now?" — all in your
  room. The fee is the game's: (the egg's plus + 1) × 10 G.
- **Breeder (my monster)** — a master who offers **one of their own
  monsters** as the mate ("Why not breed with my …?" — the monster's name is
  filled in). After the ceremony the game comes back here: they turn to you
  and say "I hope a strong monster will be born!" and the egg goes to the
  farm (Grandpa hatches it).

The ceremony itself (the starry night, "… & … disappeared.", "… was born.
Give it a name.") is the game's own and is not changed.

## A breeder's options

In **Service…** with *Breeder* picked:

- **a monster at a level you choose** (the usual choice) — pick the species
  and the level. The editor makes the mate as one of your enemies (you see it
  in Monsters → enemies, noted "a breeding mate"): the species' own row nearest
  that level (never a boss's fight row), its stats grown with the species'
  growth curves — about what raising it would give. Picking the same species
  and level again re-uses it. The mate's **level and stats count**: the egg's
  "+" grows with the two parents' levels, and the baby starts with a share of
  both parents' stats.
- **an enemy row as it is** — your own enemies or the game's rows, each a
  species at the level the game gave it (Slime Lv 1, CatFly Lv 20 …).
- **rolled from a breeding pool** — the mate is picked from a **pool**
  (below) **each time the room appears**; while you stay in the room it stays
  the same (talking again, battles in the room). After one breeding that
  breeder is **done until the room appears again** (it says *afterwards*).
- **first words** — what they say before the question (optional). Like every
  text in the editor, it is typed box by box, each box beside the game's own
  picture of it (red = it does not fit: **Fit** wraps it into boxes; OK waits
  until every box fits). The three texts (first words / not yet / afterwards)
  are tabs under the breeder's options.
- **first visit** (the tick box above the breeder's options) — words said the
  very first time instead of the first words, remembered by a flag (as for the
  other service NPCs). The text editor shows once it is ticked.
- **offers only when** — flag names (comma separated; `!name` = must be OFF):
  e.g. `beat_boss2` → they offer only after that boss. Otherwise they say
  **not yet**.
- **done flag** — turned **ON** when a breeding with them is done (after the
  ceremony). Use it anywhere (a conversation, a room state, a cutscene).
- **only once** — with the done flag ON they say **afterwards** instead of
  offering ("breed once, then new words").

## Breeding pools (Services tab → Breeding pools)

A pool is a list of **bands**; each band has **mates** with weights. When a
random breeder's room appears, the game picks **the band nearest the
player** on the scales you tick, then a mate by weight:

- **the party's average level** (the 1-3 monsters with you)
- **arena classes won** (0-8)
- **monsters seen** (the Library)
- **story milestones** — flags you list in story order; the player's value
  is how many of them are ON.

Each band row: **name**, its place on each scale (level 0-99 / arena classes
0-8 / monsters seen / story = how many milestones are ON — only the ticked
scales count), **mates** written as enemy rows with
a weight: `306×3, 305` = CatFly (row 306) three times as likely as
LizardMan (305). **add mate** puts the picked monster into the selected band;
**Apply bands** keeps the table (a band out of range is refused and shown).

"Nearest": each ticked scale counts on about 0-100 points (level as is,
arena class × 12, monsters seen ÷ 2, story = milestones ON × 100 ÷ their
number); the band with the smallest total distance wins; a tie goes to the
upper row. **Try it** shows which band a player with the given values gets
and each mate's chance.

## A room that appears at random

To make a "wandering breeder" room: give the room **Inside gates** settings
(arrival, Stairs down), put the breeder in it, then on the **Gates** tab add
a rule with **every gate** ticked, **at most once per dive** (it then shows
up at most once in each dive), and — if you like — **the chance follows the
party's average level** (e.g. 10 % at level 5 → 60 % at level 40). See
*Gates*.

## Where the text box opens

Every text of Grandpa and of a breeder opens at the **bottom** of the screen,
wherever the player stands (the game's breeding menus are drawn for a bottom
box; talked to from the lower half, the box would otherwise open at the top
and jump).

## Lines

Grandpa's menu lines and a breeder's lines are **line sets** like the other
services (Services tab → Menu lines). Grandpa's two ceremony lines (+13, +22)
are said by the ceremony and keep the game's words.

## Limits

- At most **4 random breeders in one room** (each needs its own slot).
- One breeding NPC per script (the Service… dialog makes one per NPC).
- A pool: 1-16 bands, 1-16 mates a band, the weights of a band add up to at
  most 255; up to 16 milestones.
- While a breeding menu is open, the player or an NPC standing on some room
  tiles can be hidden (the game hides sprites over the menu's own icons —
  tiles numbered from 64 for Grandpa, 120 for a breeder). Everything is back
  when the menu closes.
- A random breeder's "done" is not saved: after a reset and Continue in that
  room it offers again (a new roll).
- Placing people: the Game Boy draws at most 10 sprite pieces on one line and
  the player alone takes 8 — an NPC on the same row as the player (or the
  arrival cell) can vanish while the player stands there. Put NPCs one row
  above or below where the player walks.
