{{rammap|game=Dragon Warrior Monsters}}

==WRAM==
 Address Size    Description
 ------- ----    -----------
   C899     2    Pseudo-Random Number
   C8A9     1    ? (related to floor change in Gate)
   C8B5     1    BGM (offset)
                 0x02 - No music
                 0x06 - Title Screen
                 0x09 - BigTree
                 0x0C - Gate music 1
                 0x0F - Gate music 2
                 0x12 - Gate music 3
                 0x15 - Gate music 4
                 0x18 - Gate music 5
                 0x1B - Gate music 6
                 0x1E - Arena
                 0x21 - Ending
                 0x24 - Main Menu
                 0x27 - Battle
                 0x2B - Battle against Mireille
                 0x2E - Gate music 7
                 0x31 - Starry Shrine
                 0x34 - Gate music 8
                 0x37 - Fanfare 1
                 0x3A - Fanfare 2
                 0x3C - Fanfare 3
                 0x3F - 
                 0x41 - Prayer / Heal
                 0x44 - Fanfare 4
                 0x47 - Level Up!
                 0x49 - 
                 0x4B - Monster Encounter 
                 0x4D - Monster Encounter 2
                 0x4F - Game Over
                 0x5D - Test Stereo BGM 1 (also used for intro)
                 0x9D - Test Stereo BGM 2
                 0x9F - 
   C8B7     1    BGM (offset) to load
   C8B8     1    ? (related to BGM)
   C8B9     1    ? (related to BGM)
   C925     1    ? (related to current room or loading next room)
   C935     1    Current Gate
   C939     1    Current Floor
   C968     1    [[Dragon_Warrior_Monsters/Notes#Map_Type_IDs|Map type]]
   C969     1    flag_in_gate
                 00 - Not in a Gate
                 01 - In a Gate
   C96D     1    Gate to warp to
   CA38     1    offset_specific_to_current_gate_and_current_floor + current_floor_threshold
   CA39     2    Counter before random encounter
   CA4B     3    Gold
   CA51    20    Items
   CB0E     3    Experience - Monster n°1
   CBA3     3    Experience - Monster n°2
   CC38     3    Experience - Monster n°3
   CCCD     3    Experience - Monster n°4
   CD62     3    Experience - Monster n°5
   CDF7     3    Experience - Monster n°6
   CE8C     3    Experience - Monster n°7
   CF21     3    Experience - Monster n°8
   CFB6     3    Experience - Monster n°9
   1:D04B   3    Experience - Monster n°10
   1:D0E0   3    Experience - Monster n°11
   1:D175   3    Experience - Monster n°12
   1:D20A   3    Experience - Monster n°13
   1:D29F   3    Experience - Monster n°14
   1:D334   3    Experience - Monster n°15
   1:D3C9   3    Experience - Monster n°16
   1:D45E   3    Experience - Monster n°17
   1:D4F3   3    Experience - Monster n°18
   1:D588   3    Experience - Monster n°19
   1:D61D   3    Experience - Monster n°20
   1:D7B8   1    Main character sprite being displayed
                 00 - Front, still
                 01 - Side, still
                 02 - Back, still
                 03 - Front, walking
                 04 - Side, walking
                 05 - Back, walking
   1:D8D3   1    Copy of current Map type
                 See wC968
   1:D8D4   1    Next step or next room id
   1:D988   1    Current step in Labyrinth
                 From the initial room:
                   RIGHT (north one): Mimic
                   DOWN DOWN DOWN RIGHT (south one): Watabou doll
                   UP UP LEFT (south one): Empty spot
                   UP UP UP LEFT DOWN DOWN LEFT (north one): Boss
   1:D997   1    Current step (?) in Unused Gate
   1:D999   1    Current Arena Battle in Starry Night Tournament (00 01 02), or post-game battle against the King (04)
   1:D9CD   1    Current Coliseum Battle in Gates, and current Arena Battle (except Starry Night Tournament)
   1:D9E9   1    Current step in multi-step screens
   1:DA03   1    Enemy 1 ID
                 Enemy stats ID 1 (while loading battle)
   1:DA05   1    Enemy 2 ID
                 Enemy stats ID 2 (while loading battle)
   1:DA07   1    Enemy 3 ID
                 Enemy stats ID 3 (while loading battle)
   1:DA12   2    Enemy stats ID
   1:DA18  25    Enemy stats being loaded
   1:DA1D   2    Enemy Max HP being loaded
   1:DBAB   2    Enemy 1 HP
   1:DBAD   2    Enemy 2 HP
   1:DBAF   2    Enemy 3 HP
   1:DBBB   2    Enemy 1 Max HP
   1:DBBD   2    Enemy 2 Max HP
   1:DBBF   2    Enemy 3 Max HP
   1:DD23   1    ? (related to random battles or exp)

==HRAM==
 Address Size    Description
 ------- ----    -----------
   FFD5     1    Current Column; or Next step / next room id
   FFD6     1    Current Row
   FFDB     1    High nibble: Current Column
                 Low nibble: ?
   FFDD     1    High nibble: Current Row
                 Low nibble: ?

{{Internal Data|game=Dragon Warrior Monsters}}
