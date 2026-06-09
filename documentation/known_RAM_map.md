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
   CA38     1    Encounter pool index (gate + floor → pool via $01:Call_69e1)
   CA39     2    Counter before random encounter
   CA4B     3    Gold
   CA51    20    Items
   CAC0     1    Current monster slot index (0-19, used by Call_000_223b)
   CAC1   149    Party monster slot 0 (base address; see Party Monster Structure below)
   CB56   149    Party monster slot 1 ($CAC1 + $95 × 1)
   CBEB   149    Party monster slot 2 ($CAC1 + $95 × 2)
                 ... 20 slots total, each $95 (149) bytes
   1:D6B0        End of party/storage monster data (slot 19 + $95)
; Party Monster Structure ($95 = 149 bytes per slot, 20 slots):
;   Base = $CAC1 + slot_index × $95
;   Call_000_223b: HL = field_addr + index × $95
;
;   Offset  Size  Field
;   $00     1     In-use flag
;   $09     1     Species ID
;   $0A     1     Family
;   $14     1     Name data
;   $4B     1     Level
;   $4C     1     Level cap
;   $4D     3     Experience (24-bit)
;   $50     2     HP (16-bit)
;   $52     2     MP
;   $54     2     ATK
;   $56     2     DEF
;   $58     2     AGL
;   $5A     2     INT
;   $62     1     Plus value (0-99)
;   $68     27    Resistances

   1:D7B8   1    Main character sprite being displayed
                 00 - Front, still
                 01 - Side, still
                 02 - Back, still
                 03 - Front, walking
                 04 - Side, walking
                 05 - Back, walking
   1:D8D3   1    Copy of current map_type (selects script data bank)
                 See wC968
   1:D8D4   1    NPC script_id (selects per-NPC script in banks $0C-$0F)
                 Used by ScriptDataLookup: $41BA[map_type×2] → per_map_table[script_id×2] → data
   1:D8D5   2    Script counter (16-bit position in NPC script data)
   1:D8D7   1    Script state flags (bit0=active, bit1=text_queued, bit2=delay,
                 bit3=NPC_walk, bit4/6=pos_update, bit5=movement_lock)
   1:D8D9   2    Queued text ID (16-bit) for ROM0 dispatch
   1:D8DB   1    Delay frame counter (decremented by entry 4)
   1:D8DC   1    NPC number for pending walk-toward (1-based)
   1:D8DD   2    NPC X movement delta (signed 16-bit)
   1:D8DF   2    NPC Y movement delta (signed 16-bit)
   1:D99B  ~32   Event flag bitfield. Flag BC → byte $D99B+(BC/8), bit (BC&7).
                 182 unique flags used. Set by cmd $03, cleared by $02, checked by $00/$01.
   1:D988   1    Current step in Labyrinth
                 From the initial room:
                   RIGHT (north one): Mimic
                   DOWN DOWN DOWN RIGHT (south one): Watabou doll
                   UP UP LEFT (south one): Empty spot
                   UP UP UP LEFT DOWN DOWN LEFT (north one): Boss
   1:D997   1    Current step (?) in Unused Gate
   1:D999   1    Current Arena Battle in Starry Night Tournament (00 01 02), or post-game battle against the King (04)
   1:D9CD   1    Current Coliseum Battle in Gates, and current Arena Battle (except Starry Night Tournament)
   1:D9E6   1    Breeding mutation flag
   1:D9E9   1    Current step in multi-step screens
   1:D9EC   1    Post-battle state machine index (15 states, dispatch at $50:$5F3A)
   1:D9F4   1    Event state machine index (11 states 0-10)
   1:DA03   1    Enemy 1 ID
                 Enemy stats ID 1 (while loading battle)
   1:DA05   1    Enemy 2 ID
                 Enemy stats ID 2 (while loading battle)
   1:DA07   1    Enemy 3 ID
                 Enemy stats ID 3 (while loading battle)
   1:DA12   2    Enemy stats ID (16-bit, input for bank $14 loader)
   1:DA18  25    Enemy stats copy (loaded by Call_014_4849)
   1:DA31   1    Species ID (input for bank $03 monster info loader)
   1:DA33  43    Monster info copy (loaded by Call_003_4446)
                 +$00=family, +$09=HP_growth, +$0F=resistances(27), etc.
   1:DA6F   1    Breeding: parent 1 (pedigree) species ID
   1:DA70   1    Breeding: parent 2 (mate) species or family code ($F0-$F9)
   1:DA71   1    Breeding: result species ($FF = not found)
   1:DA72   1    Breeding: parent 1 family code (family table)
   1:DA73   1    Breeding: parent 1 family code (special table)
   1:DA74   1    Breeding: parent 2 family code (special table)
   1:DA75   1    Breeding: parent 1 party slot index
   1:DA76   1    Breeding: parent 2 party slot index
   1:DA77   1    Breeding: offspring plus value (0-99)
   1:DB55   1    Post-battle flag (always 0 for bosses)
   1:DB73   1    Post-battle gate flag ($FF = skip dispatch)
   1:DB85   1    Joinability: $07=non-joinable, other=recruitable via RNG
   1:DBAB   2    Enemy 1 HP
   1:DBAD   2    Enemy 2 HP
   1:DBAF   2    Enemy 3 HP
   1:DBBB   2    Enemy 1 Max HP
   1:DBBD   2    Enemy 2 Max HP
   1:DBBF   2    Enemy 3 Max HP
   1:DD23   1    ? (related to random battles or exp)
   1:DD61   1    Join candidate species ($FF = none)

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
