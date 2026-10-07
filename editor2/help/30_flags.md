# Flags

A **flag** is an on/off switch saved with the game. Your own flags are
**named** (e.g. `lord_beaten`, `bridge_repaired`). The flags are what tie your
story together: a conversation turns a flag ON, a room shows its other state
when that flag is ON, another NPC's conversation checks it with *If flags…*,
a cutscene plays only while it is OFF.

## The Progression & Flags tab

Everything about flags is in one place: the **Progression & Flags** tab.

**Flags page.** On the left, every flag of the game you are making:

- *Your flags* — the ones you named (a flag made for a legacy quest says *(quest)*).
- *Gates and worlds cleared* — each gate's / world's "cleared" flag.
- *The Milly hook* — "the player is Milly", "Milly has arrived".
- *The original game's flags your rooms check* — usually from rooms you
  copied from the game (*Make editable*): their people still talk about the
  original story (arena ranks, Durran, the post-game).
- *Story checks* (S129) — questions the game answers (an item carried, gold,
  monsters owned, the story reached…): read-only, usable wherever a flag is
  checked. **New story check…** makes one; **Edit…**, **Rename…**, **Delete**.
  See *Story checks, quests and the story spine*.
- Pick **Every flag of the original game too** in the box above the list to
  see all 332 of the game's own flags (read-only).

The two count columns are the places **in your game** that turn the flag ON and
that check it (a number in brackets = the original game's own places, for a
flag your game does not touch). ⚠ / ✖ mark flags with a problem.

On the right, the picked flag: its number, whether it is saved, an **In short**
line (the flag's story in one sentence: who turns it ON, who checks it), and in
words

- **Turned ON by** / **Turned OFF by** — "talking to the NPC at (4, 3) — answer
  YES", "the cutscene “Welcome” starts", "winning the boss battle on its last
  floor"…, each with the place (room · screen · state) and **show**, which shows
  the place in the panel on the right (see *The place panel* below);
- **Checked by — and what it changes** — "while ON: the room shows state 2",
  "while OFF: the cutscene plays (once)", "while ON: says «…»; otherwise: …";
  a breeder's done flag shows as "… — a breeding with them is done (after the
  ceremony)", its *offers only when* flags as "the breeder offers to breed";
  a breeding pool's story milestones as "story milestone n of the pool";
- **In the original game** — where the game itself sets and checks it, with the
  words the game shows there.

Each entry is ONE person / spot / room / cutscene — *who* (talking to Santi at
(1, 6), entering the room…) and *where* (room · screen). When one script turns
the flag ON in several branches, they are folded under it with *when* each one
happens — e.g. game flag `$0080` ("you have talked to Santi"): talking to Santi
at (1, 6) in GreatTree "in 9 of its branches: when “arena class E won” is ON ·
when “arena class D won” is ON · …" (so: whatever your progress), and her father
in the Old Man Gate Room checks it "once “Gate of Anger cleared” is ON". A
person is called by **your name** for them (see below), else by the name the
game's own lines give them (*Santi:*), else by the NPC's sprite number.

## The place panel

**show** (and a double-click on the Triggers / Problems pages) opens the place
in a panel on the right of the tab — you stay where you are:

- the room's screen **in the right room state** (a room's people change from
  state to state: in GreatTree, Santi stands on screen 12 only from state 1 on),
  with its NPCs drawn and your names over them; the place's cell is outlined in
  yellow;
- **◀ ▶** step through every place of the entry (the same script often runs at
  several screens, states or cells — e.g. the young Santi on screen 8 at (3, 6)
  in state 0 and at (2, 7) in state 1);
- the **Room state** box shows the same screen in its other states;
- the list under the picture = the screen's NPCs in the game's order (NPC 1,
  2, …) and its examine / step-on spots;
- **Open in the Rooms tab** (or *Open the cutscene*, *Open the battles*…) goes
  there — the Rooms tab opens at that screen and state with the NPC selected;
  ✕ hides the panel.

## Naming NPCs

Click an NPC (on the picture or in the list) and **Name this NPC…** — e.g.
"King — after class B", "Santi's father". In the Rooms tab, the NPC section has
the same **Name…** button. The name shows on the Rooms tab canvas (a tag over
the NPC), in this tab's sentences ("talking to Santi's father at (3, 5)"), on the
Triggers page and in the cutscene storyboards.

- It works in **your rooms** (the name is the NPC's actor name — the same name
  the cutscene editor uses) and in **the original game's rooms**, which are
  otherwise read-only (the name is only for you — saved in your project, never
  in the ROM).
- The same NPC (same sprite on the same cell) in the screen's other states gets
  the name too. An empty name removes it. Naming is one undo step.

Your flags have a **Note** (what the flag means in your story — for you, it is
not in the ROM), **Rename…** (every use follows at once), **Renumber…** and
**Delete** (only when nothing uses it — the list shows where it is used).

**New flag…** makes a flag. You can also make one wherever a flag can be picked
(a talk's *Turn these flags ON / OFF*, a conversation's *If flags…* / *Turn
flags ON / OFF*, a state rule, a cutscene) with **New flag…** / *New named
flag…* there.

**Triggers page.** Every "When … → …" of your game in one list, grouped by
place: *When bell_rung is ON → Harbour shows state 1*, *When you enter the
Roots room and milly_roots_seen is OFF → the cutscene plays (once)*, *When
talking to the NPC at (5, 2) and game flag $0037 “arena class S won” is ON →
says «…»*, *When post_game is ON → the hub is the Castle (rule 1)* (World
tab → Hub). Pick a kind or type words to filter; untick *Show copied game
scripts* to hide the branches of copied game rooms. Double-click a line to
show its place in the panel on the right. A room checks its flags each time it loads; a conversation or
a cutscene checks them when it runs.

**Story page** (S129): the story spine (your chapters in order — *Says by
progress* and *story reached* checks follow it) and every quest (Edit…, Show
giver, Delete). See *Story checks, quests and the story spine*.

**Problems page.** What will not work as written:

- ✖ a flag name that does not exist (renamed or deleted by hand) — the build stops;
- ✖ a story check turned ON / OFF (a check is only read) — the build stops;
- ⚠ checks that are never true because nothing turns their flag ON;
- ⚠ checks waiting for the **original game's** progress (a copied game room
  whose people only change once the player has, say, won arena class S) —
  never true unless the player also plays those game rooms;
- ⚠ a flag of yours on a number the original game also uses (see *Numbers*);
- ⚠ a flag that is not saved (a number outside the saved ranges);
- ℹ flags turned ON that nothing checks, flags nothing uses (they can go).

## Numbers

Every flag has a fixed number. The editor gives a new flag the lowest free
number and writes it into your project; renaming or deleting a flag never moves
another one, so a game saved before still means the same thing. (Projects made
before S124 get their numbers written in the first time they are opened — the
same numbers their last build used, so nothing changes in the game.)

The pool holds **1,965** named flags: 15 spare numbers of the game
(`$0159`-`$0167`) and 1,950 extra ones (`$1000`-`$179D`) that the editor adds
to the game. The extra flags are saved with the game (in a free part of the
save file) and cleared by a new game, exactly like the game's own.

`$0158` used to be handed out too, but the original game uses it (the Arena
Battle room: Milayou's rematch — her first words, or "Are you challenging me
again?"). The editor never gives it out, and **opening a project moves a flag
of yours that sits on `$0158` to a free number by itself** — the open notes
say which one (a save made before keeps the old number, so in that save the
flag reads OFF once).

`$0000`-`$02FF` are the game's (most are story flags), `$1000`-`$17FF` the
editor's extra ones (`$179E`/`$179F` are the Milly hook's, `$17A0`-`$17FF` the
gates').

## Special flags

**Gate cleared flags:** every gate's "cleared" flag is listed as
`gate:N cleared — name` (N = the gate number). It is the game's own flag for
a vanilla gate (Villager = `$0011`), and its own flag for a new gate or a
vanilla gate you gave a custom boss (`$17A0` + the gate number; gate 32 =
`$17C0`) — turned ON when its boss is beaten on its last floor. See *Gates* →
*Swirls and "cleared"*. A **world's** cleared flag is listed as
`world cleared — name (gate N)`; only its end boss's conversation turns it on
(*Worlds*) — a world never reaches a boss floor.

**Boss flags:** *Make boss…* makes each boss its own `…_beaten` flag — a
mini-boss can open a door (a room state), change what people say, switch a
room's battles (an encounter flag variant) or show / hide NPCs, on its own.

**Plays-once flags:** a cutscene that *plays once* has its own flag
(`<scene>_seen`), turned ON when the scene starts.

Vanilla story flags can be used too: pick one of the named ones or type its
number (e.g. `0x0030`, arena class G won). In a new game they stay OFF unless
the player plays the original game's rooms that set them — the Problems page
tells you where your rooms wait for one.
