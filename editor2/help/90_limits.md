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
- The monster lists (NPC Monsters tab, Enemies species) show the VANILLA
  species; project-made monsters / renamed species arrive with the Monsters
  tab (ROADMAP P3.9 / P3.10).
- Animated tiles: up to 8 frames per flip, drifting strips at most 2 cells
  wide, 32 animation groups per room, about 15.7 KB of frames for the whole
  project; they do not run on gate maze floors (like the game's own).
