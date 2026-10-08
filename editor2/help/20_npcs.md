# NPCs, monsters, spots and doors

Select a cell (Select tool, V), then on the **Object** page (or **+ NPC (N)** on the toolbar):

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

**name** (S124 r3): **Name…** gives the NPC your own name ("King — after class
B"), shown as a tag over it on the canvas, in the Progression & Flags tab and in
the cutscene storyboards. It works on the original game's rooms too (they are
otherwise read-only — the name is only for you, never in the ROM). The same NPC
in the screen's other states gets the name too. See *Flags* → *Naming NPCs*.

**colour** (S123): draw a person or an object in one of the game's 8 sprite
palettes instead of its own — grey / red, green, blue, yellow, purple, grey,
orange, brown (the swatch shows each one's main colour; the canvas previews
it). *own colours* = as the game draws it. Monster NPCs keep their own colours.

**Make boss…** (S123): turns the selected NPC into a boss in one go — what it
says, a battle (1-3 enemies), what it says after, its own **beaten** flag, END
boss of a world (also clears the world), and whether the helper then takes the
player somewhere. It writes an ordinary conversation (Say → Battle → Turn flags
ON → Vanish → …) you can edit afterwards, and makes the NPC *shown when* its
beaten flag is OFF, so it stays gone. See *Worlds*.

**Quest…** (S129): the selected NPC gives a quest — the offer (YES / NO), an
objective (flags or story checks, e.g. "the bag holds 3 TinyMedals"), items
handed over, a reward (items, gold, a monster, flags, refresh the room) and the
words for every stage. It replaces what the NPC said (it asks first); **Edit
talk…** on a quest giver opens the quest again. The quest's own flags
`<quest>_started` / `<quest>_done` can be used anywhere. See *Story checks,
quests and the story spine*.

**Shown when…** (S120): the *shown when* row → **Flags…** — the NPC is there only
while the listed flags are ON / OFF (all of them). The game checks when the
screen loads: a flag a talk sets shows / hides the NPC the next time you enter
or scroll back. To make an NPC leave **at once** (a beaten boss, a guard that
steps aside), end its conversation with a **Vanish** step (see
*Conversations*).

**Play the game here** (S120; S132: **▶ Play here** on the screen / state row — see
*Play here*): select a cell, More ▾ → **▶ Play the game here**
— your last build starts in this room on that cell, in the Playback window (a
new game, or the save picked on the Cutscenes tab). Build first.

An NPC says or does something through a **talk** (New talk…: text, an
optional YES/NO, flags, moving the player) or a **conversation** (New
conversation…: the full step tree — see *Conversations*). **Shopkeeper…**
makes the NPC sell a shop (its own greeting, then the game's BUY / SELL —
see *Shops*). **Service…** makes it the Vault keeper, a farm keeper, the
librarian, the Monster Namer, the Medal Man, the egg appraiser, the gate
guide, **Grandpa** (breeding and hatching) or a **breeder** offering their
own monster — the game's menus, in any room (see *Services* and *Breeding
NPCs*).

The spinning **swirl** objects on gate entrances are NPCs too (sprite
`$4D`): they show only until their gate is cleared — or, when the gate (or
world) says *after clearing, the swirl turns* a colour, they keep spinning in
that colour (see *Gates* and *Worlds*).

The engine caps a screen at 8 NPCs; many different sprites on one screen
can draw blank (sprite memory) — repeats are free.

**Sprite limits (the Game Boy's own).** It draws at most 10 sprite pieces
on one line of the screen, and you and your 3 monsters walking in a line
use 8 of them — so on a row of the room only **one** NPC stays visible
while your party walks along that row; the later ones in the NPC list
vanish until you leave the row. It also draws 40 pieces in all: with your
party, about **6 NPCs** per screen. Put NPCs on different rows. The Rooms
tab (the note above the canvas) and the build warnings tell you when a
screen goes over.


## Text: speakers, voices, names (S120)

Every text editor (talk, conversation, cutscene) has the same box editor:

- **Speaker** — `"*:"` (most people), **a name…** ("Milayou:"), **the hero's
  name**, or **nobody** (signs, narration). The label uses the first line's
  cells: `*:` leaves 16, "Milayou:" 10, the hero's name + ":" 13, nobody 18.
- **Voice** — the blip each letter makes: **low** (the King, the bosses, most
  people), **high** (Milayou, Pulio, Watabou) or **silent** (the hero's own
  lines). It changes nothing else: both voices draw the same box.
- **Insert ▾** — **the hero's name** (`{hero}`, counts 4 cells — a name is at most
  4 letters; the default the naming box offers is **TERRY** — **MILLY** with the
  Milly hook (Cutscenes → Milly hook…) — drawn in 4 cells, and the preview shows it) and **the lead monster's kind** (`{lead}`, the
  species name of the first party monster, counts 9 cells).
- **Letters**: besides letters, digits and `. , ; ! ? '` the font has
  `" - & ( ) + : / ~ [ ] *` and `…`. **Contractions** — `don't`, `it's`,
  `I'll`, `you're`, `I'm`, `you've`, `I'd` … — are written the game's way: the
  apostrophe and the letter after it are **one** cell.
