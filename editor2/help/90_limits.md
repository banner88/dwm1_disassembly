# Limits and known issues

- 8 NPCs per screen (engine cap); up to 4 different monster NPCs per screen.
- Sprite limits (hardware, S117b): one NPC per row stays visible while you
  and 3 monsters walk along that row (10 sprite pieces per line, your party
  uses 8); about 6 NPCs per screen are drawn with your party (40 pieces).
  Shown as warnings — see *NPCs*.
- Monster species Diago, Samsi, Bazoo and the last row cannot be NPCs
  (crash); Tatsu draws blank.
- After a battle started by talking to a monster NPC, that monster is not
  drawn again until the screen reloads (like a vanilla boss leaving).
- In a 2-3 enemy battle only the enemy knocked out last can join.
- New gates (S115): at most 64 (numbers 32-95). A new gate shares the maze
  look, special rooms and depth tier of the gate it copies — its own floor
  types are not editable yet, nor are any gate's floor-type rows (ROADMAP
  P3.7b part 2). Fully custom branching gates are the next step of the
  new-gates arc (NG3). Per-gate lists per floor, rooms' own lists inside and
  outside dives and flag variants are on the Encounters tab (S114).
- Encounters: at most 128 lists of your own (numbers 128-255); 8 flag
  conditions per variant. A battle rate is one of the game's 8 codes; on gate
  floors the floor type also changes how often battles come (not shown yet).
- Monster names are up to 9 characters, default nicknames up to 4,
  library descriptions 3 lines of 18 cells (S108). The 215 names have 1,903
  bytes, the nicknames 645, the descriptions 9,031 (+ about 2 KB free at the
  end of their bank); names / nicknames longer than the block share the
  ≈ 290 free bytes with the new monsters' names. Words written into dialogue
  keep the old name (the Dialogue tab lists them; editing dialogue comes
  later).
- Original monsters can get new art (S107): new art walks in one of the game's 155 walk styles
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
- Arena (S109): a team has 1-3 monsters; the number of classes and matches is
  fixed; entry fees are 0-65535 gold; TERRY? and the summons cannot fight in
  or lead a team; the announcer and the masters' words are text (not editable
  yet).
- Flags (S117): 1,968 named flags of your own (16 left over from the game +
  1,952 new ones); 8 conditions per state rule / variant / NPC. Defeating a
  custom boss of a game's gate does not move that portal room's own step
  counter (other people in that room stay as the game leaves them; the
  swirl itself follows your boss).
- Shops (S117): a shop sells 1-20 items; at most 250 shops; prices are per
  item (every shop), 0-65535 gold; what shops pay is the game's rule (3/4,
  staffs 1/10, the gate shop the full price) and is not editable. Item
  effects are not editable yet.
- Cutscenes (S118): the Cutscenes tab shows and plays scenes; writing your
  own cutscenes is the next step (the cutscene editor). Playback needs
  `pip install pyboy`. A game scene that needs a party monster of a given
  species, a full bag or a won battle state is started at its own first
  step (the window says so). **Cloned rooms:** a game script that draws a
  tile patch (opcode $24 / $61 — Castle and Bazaar doors, treasure chests)
  reads its patch from the game's script bank, which a cloned room does not
  have (read from the code; not yet tested) — avoid those steps in clones
  until the cutscene editor handles them.
