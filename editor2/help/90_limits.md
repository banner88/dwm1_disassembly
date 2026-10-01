# Limits and known issues

- 8 NPCs per screen (engine cap); up to 4 different monster NPCs per screen.
- Monster species Diago, Samsi, Bazoo and the last row cannot be NPCs
  (crash); Tatsu draws blank.
- After a battle started by talking to a monster NPC, that monster is not
  drawn again until the screen reloads (like a vanilla boss leaving).
- In a 2-3 enemy battle only the enemy knocked out last can join.
- Gate floor-type rows, per-gate monster pools / floor bands, battles inside
  a dive per room, more than 32 gates and gate entrances are not editable
  yet (ROADMAP P3.7b part 2).
- Original monsters cannot be renamed yet (Monsters tab part 3). They can
  get new art (S107): new art walks in one of the game's 155 walk styles
  (picked to fit the sheet's six frames; the original art keeps its own) and
  uses one of the game's 8 shared walking palettes. A walk style the game
  keeps only for monsters of the other half (0-127 / 128 and up, plus your
  new species) is copied — about 60-80 bytes each of a 1.4 KB / 1.6 KB
  reserve, so roughly 20 different copied styles per half; a battle picture has 2 free
  colours plus black and the cream (which also draws white parts). The art
  of re-drawn original monsters shares three banks (about 49 KB): about 58
  monsters with new battle AND walking art fit.
- TERRY? and the summons (Tatsu, Diago, Samsi, Bazoo, the empty slot) are
  not monsters: only their moves and stats can change — no art, name or
  family.
- At most 19 new monsters per project, ids 221-239 (240+ collide with the
  breeding family codes and the library / walking limits). Their names and
  4-letter short names share about 290 bytes of text space: 19 names of 8
  letters fit, 19 names of 9 letters each with its own short name do not
  (the build says so). One family's library tab holds at most 32 monsters —
  spread many new monsters over several families.
- Animated tiles: up to 8 frames per flip, drifting strips at most 2 cells
  wide, 32 animation groups per room, about 15.7 KB of frames for the whole
  project; they do not run on gate maze floors (like the game's own).
