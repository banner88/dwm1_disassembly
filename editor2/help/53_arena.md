# Arena

The **Arena** tab edits the arena: the eight classes **G F E D C B A S**,
the **Starry Night** tournament and the **King** (the Master Monster Tamer).
Pick one on the left; bold = changed from the original game, and the numbers
after a name are its team sizes when they are not 3.

**Entry fee** (classes only) — the gold the class menu at the lobby shows
and takes when you register (0-65535). **Original fee** puts it back.

**Winning it** — what the game does when the class is won (the rank flag,
the arena progress that also makes chest Mimics stronger, the world
changes). It is shown for reference; event flags are edited on the
Progression & Flags tab (not built yet).

## A match

Each class and Starry Night fight three matches, the King one.

- **Master** — who stands for the match in the Arena Battle room before the
  fight. Click it to pick a person (the same sprites as room NPCs) or any
  monster (it walks like that monster). **Original master** puts it back.
- **Monsters: 1 / 2 / 3** — how many monsters the team has. A smaller team
  fights only its first monsters; the others are not shown in the room and
  not loaded (their rows are grey: "not fought").
- **The team** — one row per monster. These are the game's **enemy rows**
  (the EID is shown), so a change here is the same as on the Monsters tab's
  "Where you meet it" page: the monster (pick it from the list), level, HP,
  MP, ATK, DEF, AGL, INT, exp, AI weights (four numbers 0-255) and up to 4
  battle skills (names, comma-separated). Double-click a number to change it.
- **Back to the original match** — master, team size and all three rows as in
  the original game.

## What the game does

The arena has no team list: match *m* of class *c* always fights the enemy
rows $E0 + 9·c + 3·m + 1, 2, 3 (the King: rows 481-483). The editor keeps
them where the game looks for them. Your project also gets a small new part
of the game (bank $6E) that tells the arena how many of the three rows to
use — with every team at 3 it does exactly what the original did.

## Limits

- TERRY? and the summons (Tatsu, Diago, Samsi, Bazoo, the empty slot) cannot
  be in a team or be a master: they are not monsters (some of them freeze the
  arena room). A team's unused rows may hold anything.
- A new monster with id 239 cannot be a master and is not drawn in the room
  before its fight (it still fights): the room draws a monster with the
  number id + 16, and 255 means "nothing".
- How many classes and matches there are cannot be changed. The announcer,
  the masters' words and the class names are text (the Dialogue tab lists
  them; editing dialogue comes later). Winning a class gives no prize in the
  original game.
