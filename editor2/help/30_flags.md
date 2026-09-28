# Flags

A **flag** is an on/off switch saved with the game. Your own flags are
**named** (e.g. `lord_beaten`) and the editor gives each one a free number
from a safe pool when it builds.

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
