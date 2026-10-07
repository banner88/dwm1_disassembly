# Story checks, quests and the story spine

S129 adds the tools that tie a story together without a flag for everything:
**story checks** (questions the game answers), **story steps** (take items,
gold, refresh the room…), the **story spine** (your chapters in order),
**quests**, **locked exits**, **music by flag** and **shop item sets**.

## Story checks — questions the game answers

A story check is a named question about the player's game — *does the bag
hold 3 TinyMedals?*, *at least 1,000 gold?*, *a dragon in the party?* You use
it **wherever a flag can be checked**: an *If flags…* step, a room state rule,
an NPC's *shown when*, a cutscene's start, a quest, music by flag, a shop's
item set, an arena class, a hub rule. ON = the answer is yes, OFF = no.

Make one with **New story check…** (Progression & Flags → Flags, and next to
every flag-condition list). The kinds:

| Asks | ON while… |
|---|---|
| has an item | the bag holds at least *n* of the item |
| has gold | the purse holds at least the amount |
| owns a monster (kind) | a monster of that kind is owned — anywhere (party or farm) or in the party |
| owns a monster (family) | the same for a family (slime, dragon…) |
| owns monsters | at least *n* monsters owned (or in the party); eggs do not count |
| party level | a party monster / the party's average / every party monster is at that level or higher |
| monsters seen | at least *n* kinds in the Library |
| random chance | a dice roll each time it is read (e.g. 30 %) |
| arena classes won | at least *n* classes |
| room in the bag | at least *n* free slots |
| story reached | that milestone of the story spine — or a later one — is reached |
| all of (AND) / any of (OR) | flags and other checks; "NOT" = a condition with *must be OFF* |

A check is **only read**: nothing turns it ON or OFF (a *Turn flags ON* of a
check stops the build — the Problems page says where). It is worked out each
time something reads it, so it is never saved and never out of date. In the
Flags page the checks have their own group (*Story checks*): **Edit…** what it
asks, **Rename…** (every use follows), **Delete** (when nothing uses it).

*In the game:* check *n* is the flag number `$1800 + n` — a "virtual" flag:
the game's own flag reader passes it to the check's code. Everything that
reads a flag reads a check the same way.

## Story steps (conversations and cutscenes)

| Step | What it does |
|---|---|
| Give an item | *n* of an item — all of them or none (no room: the *full* words) |
| Give a monster | an enemy row joins (no room on the farm: the *full* words) |
| Take an item | up to *n* of an item out of the bag (check first with an *If* + a story check) |
| Give / take gold | never below 0, never above 99,999 |
| Refresh the room | the room loads again where the player stands: its state rules pick again (a door unlocked this moment opens), the music by flag too. Nothing after it runs |
| Says by progress | (conversations) different words by the latest milestone reached; *Before the story* when none is |

## The story spine

**Progression & Flags → Story.** Your chapters in order, each a flag your game
turns ON when the story gets there (e.g. *met_the_king* "Chapter 1 — the
King"). **Add milestone…** (after the selected one), **Rename…**, **Earlier** /
**Later**, **Remove**, **Show flag**. A conversation's *Says by progress* and a
*story reached* check follow this order: "reached chapter 2" is ON once chapter
2's flag **or a later chapter's** is ON — so a player who skips a step still
counts as further on.

## Quests

Rooms tab → select the NPC → **Quest…** (the NPC's old words are replaced —
it asks first). The quest window:

- **What it asks** — *Offered only when* (empty = always), the **objective**
  (flags or story checks that must hold to finish — e.g. a check "the bag holds
  3 TinyMedals"; **New story check…** is right there), the items **handed
  over** when it is finished;
- **Reward** — items, gold, a monster joins, flags turned ON / OFF, *refresh
  the room afterwards* (a door the quest unlocks opens at once);
- **Words** — the offer (the YES / NO question), YES, NO, under way, finished,
  afterwards, not offered yet, bag full. The offer and the finished words are
  needed.

The quest makes two flags of its own, `<quest>_started` and `<quest>_done`
(fixed numbers like every flag) — use them anywhere: a door that opens, an NPC
that appears, a milestone. In the game the NPC: *done* → the afterwards words;
*under way* → objective holds (and the bag has room for the reward) → hands
over, the finished words, the reward, *done* ON; else the under-way words; *not
started* → the offer (or *not offered yet*) → YES: *started* ON.

All quests are listed on **Progression & Flags → Story** (**Edit…**, **Show
giver**, **Delete** — the flags stay).

## Locked exits

Rooms tab → select a door (or an exit) → **Lock until…**: pick the conditions
(flags / story checks) and the words said when the player presses A in front
of it. The screen gets a **second room state — the shut look**: a copy of the
screen where the exit is gone, its cell is a wall and an examine spot says the
words. The room shows the open state while the conditions hold. **Paint the
closed door** in the shut state (the editor selects it for you). The screen
must have one state (a screen with several: make the shut state by hand).
A room picks its state when it loads — add a *Refresh the room* step right
after the flag turns ON to open it at once (a quest: *refresh the room
afterwards*).

## Music by flag

Music tab → Rooms (your rooms) or Gates → **Music by flag…**: rules *song while
conditions*; the FIRST rule whose conditions all hold plays, none = the usual
song. Read when the room / gate floor loads.

## Shop item sets

Shops tab → a shop → **Item sets by flag…**: other lists the shop sells while
conditions hold (the first set whose conditions hold; none = the shop's own
list). Read each time BUY opens, so a flag turned ON shows at once.
