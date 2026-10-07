# Your arena

Your project can have **its own arena**: the game's **Arena Lobby** and
**Arena Battle room**, copied into your project so you can change their tiles,
NPCs and doors — with everything the arena does: the receptionist's class
menu, your party disappearing through the door one by one, the walk-in of the
master and his monsters, the announcer, the crowd, three matches, Starry Night.

**Arena tab → ★ Your arena → Make your arena** copies both rooms (the Arena
Battle room with all its states — Starry Night is fought at night). They are
ordinary rooms of yours from then on: open them on the Rooms tab (**Open**),
paint them, move the NPCs, and give the lobby's doors other destinations
(its bottom door leads to GreatTree until you change it). The Arena Battle
room has two looks, as in the game: the **day** arena (state 0, the classes)
and the **night** arena (states 1-4, Starry Night) — paint the night one once
and it shows in every Starry Night match. What you paint stays after each
match (the game redraws the room from your copy). Lead into the lobby
from any of your rooms with a door or a "move" (a conversation, a scene).

The teams, masters and entry fees are the class pages of the Arena tab, as
before — they are the same for your arena and the game's.

## The ★ Your arena page

- **Lobby / Arena** — the two rooms (copies of the Arena Lobby / the Arena
  Battle room; "Use these rooms" if you made other copies).
- **Back in the lobby** — the cell a lost match and a won class put you on
  (click it on the picture; the game's is screen 1, (4, 4) — in front of the
  desk).
- **The receptionist says** — after a lost match, when you back out of the
  class menu, and when you pick a class that is not open yet. Empty = the
  game's words.
- **Remove your arena** — your rooms stay, as ordinary copies.

The receptionist is the counter in front of her (the lobby's script 6): you
talk across it, as in the game. A class menu line can also be changed with a
line set of the kind **Arena desk** (Services tab).

## In your arena (each class page)

- **opens when** — flags that must hold (none = always open). A class that
  is not open shows **-** in the class menu and the receptionist says your
  "not open yet" words.
- **A win turns this flag ON** — your own flag (New flag… makes one). A win
  also turns ON the flags of the classes below it that have one, and the menu
  marks them won (★) — the game's own rule.
- **What the receptionist says after the win** — empty = the game's
  "Well done! You survived … class!".
- **After a win** — stay in the lobby, go to a room (pick the cell), or go to
  the **hub** (World tab; the hub's arrival scenes can play for "won an arena
  class").

## Starry Night

On the Starry Night page: **The receptionist offers Starry Night** — when
its flags hold, she asks first (YES → the tournament, NO → her words), else
the class menu. Its **won flag** stops the offer. **After a win**: the lobby,
a room, the hub — or **the game's ending** (the original scene after the
final, the night Farm, the credits; the game then continues in its own
GreatTree post-game). The three tournament matches and the final are the
Starry Night teams on its page. Losing a Starry Night match sends you to the
hub (World tab), as in the game.

## What the game does

The engine knew the arena by its two room numbers; with your arena it treats
your two copies the same way (the follower monsters hiding in the lobby,
the walk-in, the next match after each win, the arena's battle type and
music, the escape spell refused there, your monsters sitting at the lobby's
table). The game's own arena still works as before — for your post-game.

## Limits

- One arena per project (the classes won, $CAB4, are one count for the whole
  game, shared with the game's own arena).
- Monster Grandpa's match (GoldSlime, Divinegon, Rosevine) is not offered in your arena;
  it stays in the game's arena.
- The walk-in, the announcer's lines and the arena's choreography are the
  game's (they are scripts of the copies — edit them on the Rooms tab like any
  copied room's script). A lost class match costs nothing, as in the game.
- A copy of the Arena Battle room made before this version has only its day
  state: make a new one (the build says so) before using Starry Night.
