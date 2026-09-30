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
- The monster lists (NPC Monsters tab, Enemies species) show the vanilla
  species plus the project's new monster (`custom.species`); renamed
  vanilla species arrive with the Monsters tab (ROADMAP P3.10).
- At most 19 new monsters per project, ids 221-239 (240+ collide with the
  breeding family codes and the library / walking limits). Their names and
  4-letter short names share about 290 bytes of text space: 19 names of 8
  letters fit, 19 names of 9 letters each with its own short name do not
  (the build says so). One family's library tab holds at most 32 monsters —
  spread many new monsters over several families.
- Animated tiles: up to 8 frames per flip, drifting strips at most 2 cells
  wide, 32 animation groups per room, about 15.7 KB of frames for the whole
  project; they do not run on gate maze floors (like the game's own).
