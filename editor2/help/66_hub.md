# The hub (home)

The **hub** is where the game sends the player **home**. In the original game
that is always the Castle. With a hub of your own, these all go to your room
instead:

- a **lost battle** (any battle, inside a gate or out);
- the party **falling on damage floors**;
- the **WarpWing** item (and the custom **Anchor** skill's gate exit);
- a lost **Starry Night / arena final**;
- a scene or conversation that moves the player **home** (see below).

The penalties stay as in the game: after a loss or a fall the player keeps
**half the gold** and loses the items that are not kept on a loss.

## Set it, step by step

1. **World tab → Hub → Add rule…** — pick the room and **click the cell**
   where the player arrives (a wall cell is refused). Leave *when* empty: this
   room is home from the start.
2. **Moving home later** — **Add rule…** again with a condition: *when*
   `post_game` (a flag) is **set**, home is another room, or **the Castle**
   (the original game, with its priest and King). Rules are tried **in order**
   and the first that holds wins; a rule with conditions is put before the one
   without. ▲ / ▼ change the order. With no rule that holds, home is the
   Castle.
3. **Add the arrival scenes** — three entry scenes in the hub room
   (Cutscenes tab): after a loss (a line + **Heal**), after the WarpWing (a
   line + **Heal**), sent home by a script (a line). Edit them like any scene.
4. **Build** and lose a battle on purpose: you wake up in your hub.

The Rooms tab marks the arrival cell with a gold **H**.

## Arrival scenes

A scene that plays **on entry** can be limited to arrivals home: in the
cutscene editor, **Arrival home… ▾** and tick the reasons (*lost a battle*,
*the party fell*, *WarpWing / Anchor*, *lost the Starry / arena final*, *sent
home by a script*). Such a scene plays once per arrival, before the room's
other entry scenes. A reason that no scene takes still **heals the party**
(the Castle's priest heals too) — so if you write a scene for a loss, give it a
**Heal** step: the build warns when one is missing. An arrival scene must be on
the screen the hub rule lands on, in a hub room (the build warns otherwise).

## Sending the player home yourself

- Cutscenes: **Warp the player → home — the hub**.
- Conversations: **Move the player** or **Helper takes the player away →
  Home — the hub**. For the helper, the *at the Castle* event (priest heal or
  King's speech) is used when home is the Castle.

The arrival reason is then *sent home by a script*.

## The Heal step

**Heal the party** (cutscenes and conversations): every monster, in the party
and on the farm, gets its HP and MP back and its ailments cured — the game's
own heal. It shows nothing; say it in a text.

## Good to know

- One hub at a time: the rules pick one. A typical game: your hub for the main
  game (`post_game` OFF), the Castle once the story is over (`post_game` ON).
- The WarpWing's description in the item menu still reads "Warps back to
  castle instantly" — the game's own text (item descriptions are read-only
  for now, Dialogue tab).
- Only your own rooms (or the Castle) can be the hub.
