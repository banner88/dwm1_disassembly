# Limits and known issues

- Rooms (S133): at most **128** rooms of your own (map ids $6B-$EA) — the build
  stops with an error past that (before S133 a room past it read another room's
  data). Layouts, colour grids and tilesets overflow into the 4 MB ROM's new
  banks when $64 / $67 are full (S135), and so do whole rooms (scripts, NPC /
  door lists, states) and texts when $60 is full (S136). The 128-room limit is
  the next to go (ROADMAP ARC CAP3, regions); the room palettes ($17, the
  palette and colour rows of every room state) are the next space to move
  (ARC CAP2c), then a room's own animated tiles ($6C, CAP2d).
- One room's scripts and lists must fit one bank (~15 KB) — the build names a
  room that is bigger. Automatically numbered texts start a new 256-line group
  before one group would pass ~12 KB.
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
- New gates (S115): at most 64 (numbers 32-95). A new gate starts with the
  maze look, special rooms and depth tier of the gate it copies; since S120
  every gate can point at other rows (Gates tab → Maze floors) — the rows
  themselves are shared and not editable. New maze PIECES (screens) are not
  editable yet. Fully hand-made places entered like a gate are **worlds**
  (S123, below).
- Worlds (S123): each world takes one of the 64 new gate numbers (shared with
  new gates). A room belongs to at most one world. Only a conversation (Make
  boss → END boss, or *Turn flags ON* `world cleared — …`) clears a world —
  winning a battle alone does not. Inside a world there are no maze floors or
  stairs; losing works the gate way (home — the Castle or your hub — healed,
  half the gold). A
  world room's music is its own song, else whatever is playing.
- NPC colours (S123): the 8 sprite palettes are the game's own, shared by
  every sprite on the screen (they are not editable here). Monster NPCs keep
  their own colours. Each coloured NPC costs the game a little time per frame:
  measured, a 4-NPC room with 2 coloured NPCs dropped about 1 frame in 80 — use
  colours where they matter. The portal's still swirl picture keeps the room's
  colours; only the spinning swirl changes colour.
- Vanish (S123): the NPC leaves for the moment; it comes back when the screen
  loads again unless its *shown when* flags say otherwise (Make boss sets this
  up).
- Maze size (S122): 3-15 per battle list (1-2 can freeze the game).
- Gate themes (S122): the 16 maze looks only (their sheet slots $00-$3F; $40-$7F
  free); theme rooms do not animate; the damage floors do not hurt in your
  rooms. Per-gate lists per floor, rooms' own lists inside and
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
- Flags (S117, S124): 1,965 named flags of your own (15 left over from the game +
  1,950 new ones; `$0158` is the game's own — a flag on it is moved off when the project opens);
  8 conditions per state rule / variant / NPC; conditions are flags ON / OFF
  joined by AND (no OR yet), and a YES / NO answer. Defeating a
  custom boss of a game's gate does not move that portal room's own step
  counter (other people in that room stay as the game leaves them; the
  swirl itself follows your boss).
- Shops (S117): a shop sells 1-20 items; at most 250 shops; prices are per
  item (every shop), 0-65535 gold; what shops pay is the game's rule (3/4,
  staffs 1/10, the gate shop the full price) and is not editable. Item
  effects are not editable yet.
- Services (S126): the Vault, the farm and the medal count are one for the
  whole game (every NPC of a kind shares them). The gate guide's list is the
  original game's 31 gates. The Medal Man gives 1-8 eggs, at most 999
  medals. A line set's speaker is at most 9 letters; a line too long for its
  box stops the build. The menus' words are per line set; the menus
  themselves (their choices, the naming screen) are the game's.
- Breeding (S127): the ceremony and Grandpa's fee are the game's. At most 4
  random breeders in one room; a breeding pool has 1-16 bands, 1-16 mates a
  band (weights adding up to at most 255), up to 16 story milestones; at most
  100 pools. A random breeder's roll and "done for this visit" are not saved
  (Continue in that room rolls again). While a breeding menu is open, sprites
  over some room tiles are hidden (the game's own rule). See *Breeding NPCs*.
- Cutscenes (S118, S119): Playback needs `pip install pyboy`. A game scene
  that needs a party monster of a given species, a full bag or a won battle
  state is started at its own first step (the window says so). **Your own
  cutscenes** (S119): a screen has 8 NPC slots (actors + cast members + pads);
  a cast member shown or moved by a scene is back in its place, hidden, when
  the room loads again (a lasting change = the room's state rules); "Change
  tiles" lasts until the room loads again too; the flickering appear /
  disappear takes about 4 seconds (the game's own effect); flying is for NPCs
  only; a Flash turns the screen to each palette's FIRST colour (white in the
  game's rooms, your own first colours in your own-colour rooms). A battle in
  a scene keeps everyone where the scene put them (measured S119). **Copied
  rooms:** game steps that draw a tile patch (opcode $24 /
  $61 — Castle and Bazaar doors, chests) work in copies since S119.
- Story (S129): up to 256 story checks in all (yours plus the editor's own:
  one per milestone a *Says by progress* uses, one per quest whose reward needs
  bag room) — the New story check button stops at 224 of yours; up to 255
  different story steps (take / give items, gold); up to 8 conditions a music
  rule or a shop item set. A *random chance* check is rolled each time it is
  read (an *If* and a room state may see different rolls). A room picks its
  state and music when it loads: *Refresh the room* to change them at once. A
  lock needs a screen with one room state. See *Story checks, quests and the
  story spine*.
- Your arena (S128): one per project; the classes won ($CAB4) are one count
  shared with the game's own arena. Monster Grandpa's match stays in the game's
  arena. Up to 8 flag conditions per class. The walk-in, the announcer and
  the choreography are the game's scripts in your copies. A copy of the Arena
  Battle room made before S128 has no night states — make a new one for Starry
  Night. See *Your arena*.
