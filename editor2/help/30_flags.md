# Flags

A **flag** is an on/off switch saved with the game. Your own flags are
**named** (e.g. `lord_beaten`) and the editor gives each one a free number
from a safe pool when it builds. The pool holds **1,968** flags: 16 spare
vanilla numbers (`$0158`-`$0167`) and 1,952 extra ones (`$1000`-`$179F`)
that the editor adds to the game. The extra flags are saved with the game
(in a free part of the save file) and cleared by a new game, exactly like
the game's own.

**Making a flag:** there is no separate list to fill in first — wherever a
flag can be picked (a talk's *Turn these flags ON / OFF*, a conversation's
*If flags…* / *Turn flags ON* / *Turn flags OFF*, a state rule), press
**New flag…** (or *New named flag…*) and type a name. It is created when you
press OK. Afterwards it appears in every flag list as *(project flag)*.

Vanilla story flags can be used too: pick one of the named ones or type its
number (e.g. `0x0030`, arena class G cleared). EVENT_FLAGS.md lists them.

Flags are what connects things: a conversation turns a flag ON, a state rule
shows the room's other state when that flag is ON, another NPC's conversation
checks it with *If flags…*.

**Gate cleared flags:** every gate's "cleared" flag is listed as
`gate:N cleared — name` (N = the gate number). It is the game's own flag for
a vanilla gate (Villager = `$0011`), and its own flag for a new gate or a
vanilla gate you gave a custom boss (`$17A0` + the gate number; gate 32 =
`$17C0`). See *Gates* → *Swirls and "cleared"*.

**Numbers:** `$0000`-`$02FF` are the game's (most are story flags — only
`$0158`-`$0167` are free), `$1000`-`$17FF` the editor's extra ones
(`$17A0`-`$17FF` are kept for the gates).
