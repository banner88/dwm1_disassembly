# Conversations

A conversation is a list of **steps**, run top to bottom. Open it with
**New conversation…** (NPC selected) or **Arrival conversation…** (Inside
gates and worlds section — runs when the player arrives on the room, optionally on one
screen only). Edit an existing one with **Edit talk…**.

**+ Add step ▾** adds after the selected step, or INTO the selected branch
(the italic *If YES / If NO / Then / Otherwise* rows). ▲ ▼ reorder, Remove
deletes. The line at the bottom lists problems; OK is enabled when there are
none.

| Step | What it does |
|---|---|
| Say | text boxes (the preview is the game's own font) |
| Ask YES / NO | text whose last box is the question; *If YES* and *If NO* branches, then both continue |
| If flags… | all listed flags ON (and the second list OFF) → *Then*, else *Otherwise* |
| Turn flags ON / OFF | set / clear flags (New flag… makes one) |
| Battle | 1-3 enemies; the steps after it run only if the player WINS (a loss = back to the castle, as vanilla) |
| Helper takes the player away | the boss exit: Warubou flies in next to the player, spins, can speak, and the screen fades to the destination |
| Move the player | a plain warp to a room / screen / cell |
| Vanish (this NPC leaves) | the NPC talking **flickers out** (the game's own vanish) or disappears **at once**, there and then. To keep it gone, give it *shown when* a flag (set before the Vanish) is OFF — *Make boss…* does both |
| Stop here | ends the conversation |

**You do not need any *If*.** A straight boss is simply:
`Say` → `Battle` → `Helper takes the player away`. A boss that stays in the
room: `Say` → `Battle` → `Turn flags ON` (its beaten flag) → `Vanish` →
`Say` … — NPC → **Make boss…** builds this for you.

**The helper step** (top to bottom in the editor):

- **Warubou says something first** — tick the box at the top and type the
  text (boxes, like a Say step). Leave it unticked for a silent exit.
- **takes the player to** — the Castle throne room (where vanilla bosses
  send you) or any of your rooms, plus screen and cell.
- **at the Castle** (only when the destination is the Castle):
  - *nothing happens* — you just stand in the throne room;
  - *the priest blesses + heals the party* — the vanilla return from a gate
    (afterwards the castle NPC offers the herb again);
  - *the King's speech after a gate boss* — pick which gate's speech. It
    changes no story flags. ⚠ marks the two speeches that also change what a
    castle NPC says until your next normal gate return.
  Choosing an event moves the destination to the throne spot automatically.
- **landing** — next to the player on their left, turned to them (default),
  or a fixed cell.
- **helper sprite** — Warubou ($39) by default ($21 = vanilla Watabou).

Nothing after a helper step runs.

**Joining** is the enemy's own setting (see *Enemies*). In a 2-3 enemy
battle only the enemy knocked out LAST can join.

**Arrival conversations** run on every arrival (also after a battle or
loading a save) — start with *If flags…* so a finished fight does not
start again.


**Texts (S120):** each Say / Ask text has its own **Speaker** and **Voice** and
the **Insert ▾** menu (the hero's name, the lead monster's kind) — see *NPCs*,
"Text: speakers, voices, names". An Ask inside a YES or NO branch is a question
inside the answer (as deep as you like); the branches join again after it.
