{{rammap|game=Dragon Warrior Monsters}}

==WRAM==
 Address Size    Description
 ------- ----    -----------
   C200   256    Attr decompression staging (S55): every attr stream declares
                 a 256-B decompressed length to $C200 (loader reads 2-byte
                 declen from the stream head; users in banks
                 $00/$06/$07/$0B/$17). Save-copied to SRAM $BEC8 x$100.
   C300   512    Screen staging block (S55): tile-id shadow + pair, treated
                 as ONE $200 unit (bank $06 bulk copy $C500->$C300 x$0200;
                 save-copied to SRAM $BCC8 x$200). The old "256 B" extent
                 was too small. Tile under player read from here ($00:$1E96).
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
   C935     1    Current Gate (wGateID)
   C936     3    Floor type 1/2/3 (maze biome / special-room / contents rolls)
   C939     1    Current Floor
   C93A     1    Last floor (floors before boss)
   C93B     1    Boss room map type
   C93C     1    Boss/floor tileset = DEPTH TIER 1/2/3 (also item-tier select)
   C93F     1    Floor shape mode ([$16:$6056 + RNG%5])
   C940    16    Floor screen GRID (4×4): byte = (piece<<4)|variant; $Fx = empty
   C950    16    Floor grid paired per-cell state buffer
   C960     1    Staircase screen index (down-stairs cell)
   C100    16    Per-screen content state (item/master placement)
   C968     1    [[Dragon_Warrior_Monsters/Notes#Map_Type_IDs|Map type]] (wMapID)
   C969     1    flag_in_gate (wInGateworld)
                 00 - Not in a Gate (or fixed special-room template)
                 01 - In a Gate (procedural maze mode)
   C96D     1    Gate to warp to
   CA38     1    Encounter pool index (gate + floor → pool via $01:Call_69e1)
;  Gate floor generation pipeline (these vars): see GATE_GENERATION.md
   CA39     2    Counter before random encounter
   CA40     1    Breeding/hatch offspring slot (S56): first-empty index chosen
                 by $16:jr_016_402d, persisted for the script-side finalizer
                 $04:label4_64c2 ($CAC0 := [$CA40] then bank $16 entry 4)
   CA41     1    bit7 = farm SLEEP pool active (SRAM $B124; see sleep row
                 below / ARCHITECTURE SRAM map). Other bits unknown.
   CA42     9    Monster-name text scratch (S56): nickname (+$0C, 8-9 B) of
                 the current/new monster copied here for the text engine
                 (writers: $14 builder, $12 farm detail, $01 placeholder
                 codes $D3/$D4/$D5)
   CA4B     3    Gold
   CA51    20    Items
   CAB9     1    Starry Night cutscene selector. Set by engine (bank $2D).
                 Castle script 0 branches on values 1/2 to choose post-
                 tournament path. Value determines which variant of the
                 Starry Night victory cutscene plays (sets flag $00F1).
   CA94    30    Library "seen" species bit array (bit N = species N seen).
                 Set via SetBitInArray on add-to-storage ($14:label14_40b4);
                 bank $07 completion counters scan bits 0-$EF (240 bits →
                 $CA94-$CAB1). New species 224's bit lands at $CAB0 — inside
                 the scanned extent (benign) but it COUNTS toward the
                 100-monster library reward checks (S54).
   CA8D     1    PARTY COUNT (0-3) (S56). Recounted by the canonicalizer
                 ReadPartySlotInfo ($01:$46F6, bank $01 entry 5).
   CA8E     3    PARTY SLOT LIST (S56): three indices into the 20-slot
                 monster array ($FF = empty entry). Party membership is
                 list+flag, NOT positional — see MONSTER_DATA "Party/farm
                 boundary semantics". Battle copies it to $DA15-$DA17.
   CA91     3    Per-party-member follower sprite-type cache
                 (species+$10, positions 0/1/2; loader $01:LoadPartySpriteVRAM)
   CAC0     1    Current monster slot index (used by Call_000_223b/
                 GetMonsterDataPtr; 0-19 real, $14/$15 staging; one bank $12
                 site reuses it as a flat family index scratch)
   CAC1   149    Party monster slot 0 (base address; see Party Monster
                 Structure below). In-use flag +$00 is TRI-STATE (S56):
                 $00 empty / $01 farm / $02 party.
   CB56   149    Party monster slot 1 ($CAC1 + $95 × 1)
   CBEB   149    Party monster slot 2 ($CAC1 + $95 × 2)
                 ... 20 slots total, each $95 (149) bytes.
                 Slots hold party + farm + eggs under ONE 20-slot limit.
                 Access is INDEXED ONLY (GetMonsterDataPtr: HL = field + A×$95)
                 — there are ZERO literal refs to slot 3-19 addresses. Do not
                 place anything at $CAC4-$D664 (see audit_wram.py, S54).
   1:D664        TRUE end of party/storage monster data (slot 19 = $D5D0 +
                 $95 - 1). The old "D6B0" figure here was wrong (S54).
                 S55 UPDATE: step counters/scratch/flags relocated to $DE74
                 (crash vector fixed). The NPC/exit BUFFERS ($D379-$D477)
                 remain inside slots 14-15 as an ACCEPTED legacy hazard of
                 the exploration overlay (self-healing per read; reverse
                 corruption of stored monsters #15-16 remains) — keep the
                 array ≤14 occupied when using custom rooms. Editor-era fix:
                 Cold Farm arc (ROADMAP).
                 STAGING PSEUDO-SLOTS (S56): GetMonsterDataPtr masks $7F, and
                 indices $14/$15 address two more 149-B slots at $D665-$D6F9
                 and $D6FA-$D78E (inside the save image): breeding parents
                 (both parents copied+deleted there before bank $16 runs;
                 parent fields read as +$0BA4/+$0BA4+$95), link-trade
                 transit, and bank $15 menu scratch. Do not place anything
                 at $D665-$D78E either.
                 SLEEP POOL (S55): a SECOND 20-slot x $95 monster array lives
                 in SRAM at $B124-$BCC7 (never WRAM-resident): the farm
                 "sleep" batch. Gated by $CA41 bit 7; scanned in-place by
                 bank $07 (EnableSRAM per access) e.g. for library counting.
                 One-way archival (no wake path known; FAQ + user).
; Party Monster Structure ($95 = 149 bytes per slot, 20 slots):
;   Base = $CAC1 + slot_index × $95
;   Call_000_223b: HL = field_addr + index × $95
;
;   Offset  Size  Field
;   $00     1     In-use flag: $00 empty / $01 farm / $02 party (S56)
;   $09     1     Species ID
;   $0A     1     Family
;   $0C     9     Nickname (S56; the old "$14 Name data 1 B" row was the
;                 last byte of this field)
;   $29     8     $FF-terminated ID list A (semantics unverified; sanitized
;                 by $01:ScanPartySlotTable) (S56)
;   $31     25    $FF-terminated ID list B (same sanitizer) (S56)
;   $4A     1     Battle status; bit7 = KO/incapacitated (no exp, not
;                 counted for the party share; bulk-cleared by
;                 $01:IteratePartySlots20) (S56)
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
   1:D92A ~113   Room step counters ($D92A–$D99A). One byte per screen, value
                 selects which step entry (NPC set + exit set + tile layout) is
                 active. Set by script opcode $12 (WriteRAM). Full mapping in
                 StepBlk_* labels in patches/bank_00b.asm. Key addresses:
                   $D92A-$D92C  Castle screens 0/1/5
                   $D92D-$D934  GreatTree (8 screens)
                   $D935-$D93A  Bazaar (6 screens)
                   $D93F-$D944  Farm (6 screens)
                   $D977-$D97A  Boss rooms (Villager/Talisman/Memories/Bewilder)
                   $D998        Shared by maze/conveyor/forest rooms
                   $D99A        Last used (Room_5E)
                 Custom rooms: $D95E (room $6B, shares with MedalManRoom),
                 $D9A0-$D9A2 (room $6C, unique). See ROOM_DATA_FORMAT.md.
   1:D99B  ~32   Event flag bitfield. Flag BC → byte $D99B+(BC/8), bit (BC&7).
                 182 unique flags used. Set by cmd $03, cleared by $02, checked by $00/$01.
   1:D988   1    Current step in Labyrinth (part of step counter range above)
                 From the initial room:
                   RIGHT (north one): Mimic
                   DOWN DOWN DOWN RIGHT (south one): Watabou doll
                   UP UP LEFT (south one): Empty spot
                   UP UP UP LEFT DOWN DOWN LEFT (north one): Boss
   1:D997   1    Current step (?) in Unused Gate
   1:D999   1    Current Arena Battle in Starry Night Tournament (00 01 02), or post-game battle against the King (04)
   1:D9CD   1    Current Coliseum Battle in Gates, and current Arena Battle (except Starry Night Tournament)
                 CAUTION: shares byte with event flag indices $0190-$0197
   1:D9CE   1    Arena round counter (within a class). Arena Lobby script 0
                 branches on values 0-7 to determine match progression.
                 254 = arena unavailable (mandatory gate sequence active).
                 CAUTION: shares byte with event flag indices $0198-$019F
   1:D9CF  ~8    Gate room reset counters ($D9CF-$D9D6). Written to 0 on gate
                 room entry. Shares bytes with flag indices $01A0-$01DF.
   1:D9E3   1    Story progression counter. Boss-defeat scripts set this to
                 increasing values:
                   48 after first boss (Beginning/Healer)
                   50 after second boss (Villager/Dragon)
                   ... increasing with each boss defeated ...
                   77+ late-game
                 Room-entry scripts (script_id=0) for Castle, GreatTree, etc.
                 branch on this value (via opcode $15 / cond_branch) to decide
                 which cutscene to play and which step counters to advance.
                 CAUTION: shares byte with event flag indices $0240-$0247.
                 Editor must never allocate custom flags at those indices.
   1:D9E6   1    Breeding mutation flag
                 CAUTION: shares byte with event flag indices $0258-$025F
   1:D9E9   1    Current step in multi-step screens
                 CAUTION: shares byte with event flag indices $0270-$0277.
                 Last byte included in SRAM save range ($C8EA-$D9E9).
   1:D9EC   1    Post-battle state machine index (15 states, dispatch at $50:$5F3A)
   1:D9F4   1    Event state machine index (11 states 0-10)
   1:DA03   1    Enemy 1 ID
                 Enemy stats ID 1 (while loading battle)
   1:DA05   1    Enemy 2 ID
                 Enemy stats ID 2 (while loading battle)
   1:DA07   1    Enemy 3 ID
                 Enemy stats ID 3 (while loading battle)
   1:DA12   2    Enemy stats ID (16-bit, input for bank $14 loader;
                 = wTempEnemyStatsId)
   1:DA14   1    Give/creation target slot (S56): first-empty scan result;
                 consumed by the bank $14 record builder ($1402)
   1:DA15   3    Battle position -> array slot cache (S56): validated copy
                 of $CA8E-$CA90 made at battle setup ($51:LoadBtlS_40d1)
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
   1:DD23   3    Battle exp total, 24-bit (SOLVED S56; was "? related to
                 random battles or exp"): party share = total / eligible
                 party count; farm share = total/16 each (exp walker
                 $50:$61E2; see MONSTER_DATA)
   1:DD61   1    Join candidate species ($FF = none)

; ===================================================================
; Battle skill-cast vars (Session S45 — see BATTLE_SKILL_SYSTEM.md).
; CONFIDENCE VARIES — items marked (INFERRED) were deduced from behaviour
; or literal base addresses, NOT from fully decoding the index math.
; The hard lesson: a literal-reference "free RAM" scan is BLIND to arrays
; accessed via base+offset. $DD80-$DE4F and $DBA3-$DC33 below are such
; arrays — DO NOT use any byte in them as scratch.
; ===================================================================
   1:DB56   2    Computed damage number (handler writes here; consumer applies)
   1:DB86   1    *** OUR custom-skill stash (real id, single). Was an unused ds
                 gap between $DB85 and wBattleAttackerIdx $DB88. VERIFIED free
                 by in-game test. Only writer = AliasCommit (patches/bank_050).
   1:DB88   1    wBattleAttackerIdx — attacker combatant index (re-derived;
                 NOTE: repurposed during target processing, unreliable at
                 effect-dispatch time)
   1:DB89   1    wBattleTargetIdx — target combatant index
   1:DB8A   1    Working skill id (re-derived from $DCEC each cast; ~35 writers)
   1:DB4C   1    Record-lookup index (re-derived FROM $DB8A during the cast)
   1:DB4F   1    "Selected skill" (targeting helper)
   1:DBA3  96    Battle stat tables, 16 bytes each (2 B/combatant), indexed by
                 combatant 0-2 party / 4-6 enemy: HP $DBA3, MaxHP $DBB3,
                 MP $DBC3, MaxMP $DBD3, ATK $DBE3, DEF $DBF3, AGL $DC03,
                 INT $DC13, LVL $DC23. (S52: NO conflict with "$DBAB Enemy 1
                 HP" — $DBA3 + 2*4 = $DBAB, enemy 1 = combatant 4. HW-confirmed:
                 the $DBAB watchpoint fired on enemy damage; writer $51:$4a61,
                 damage-apply $51:$47e0.)
   1:DA34   1    Battle-animation frame DIVIDER for bank $5f entry 5 (tick runs
                 its phase every 5th frame). [S52, HW + static]
   1:DA81   1    Layer-2 presentation command (sound+flash channel; §11.4).
   1:DA82   1    Animation done-flag (1 = phase machine finished). [S52]
   1:DA83   1    Animation PHASE for $5f entry 5 (rst $00 dispatch, ptr table
                 $5f:$4b28; one phase = the per-enemy hit-blink). [S52, HW]
   1:DA84   1    Phase STEP counter / blink toggle (sub-dispatch $5f:$4b99:
                 0=blank frame $4ba5, 1=enemy frame $4bcb). [S52, HW]
   1:DA85   1    Phase frame counter (blink uses 6). [S52, HW]
   1:C500 $240   Battle enemy TILE buffer — the enemy is BG-DRAWN from here to
                 the $98xx map by LoadBtl_7627 ($50:$7627; slots at BG cols
                 $25/$2b/$31); $E0 = blank. NOT OBJ (§11.7). [S52]
   1:DD60   1    Player-hit reaction ACTIVE flag (screen shake; ticked by banks
                 $5c/$5d/$5e entry 0 with $DD62/$DD65/$DD66/$DD68 + hFFC3).
                 [S52, partial]
   1:DCEC  ~16   Action queue: 2 bytes/combatant {skill id, target}, indexed by
                 combatant*2. The single source the cast re-derives $DB8A from.
   1:DD6F   1    (INFERRED) Damage descriptor bitfield (bit5 = apply $DB56/57)
   1:DD70   2    (INFERRED) Animation pointer (Blaze = $B882)
   1:DD80  172   AUDIO ENGINE channel state + scalars (S55 correction — the
                 old "(INFERRED) battle struct array, ~8 slots to $DE4F" label
                 was WRONG): ClearAudioChannels (bank $00, ~$3343 region)
                 inits 6 channels x 26 B ($1A stride) from $DD80 = $DD80-$DE1B;
                 engine scalars continue to $DE2B ($DE1C-$DE2B: state, frame,
                 $DE22/$DE23/$DE29 counters). Still *** OFF-LIMITS as scratch
                 (S45's corruption when writing $DDF0/$DDFE stands — those are
                 audio channel bytes).
   1:DE74  106   CUSTOM ROOM STATE (S55 relocation; was $D378/$D478-$D48B
                 inside the monster array): step counters $DE74+ (compiler
                 region), wRoomRecScratch $DE7B, wRoomEncFlag $DE83, Tame vars
                 $DE84-$DE87, wCustomRoomFlag $DE88; $DE89-$DEDD reserved.
                 Vetted: no real claimant above the audio ceiling $DE2B
                 (full-corpus scan; $DE30-$DEFF literals are all data-as-code
                 junk); SVBK windows touch $DB00+ only; NOT in save range.
                 INIT (S55v2): vanilla ClearAllWRAM stops at $DDFF — the
                 patched build extends it to $DEDF so this block is boot-
                 zeroed; wCustomRoomFlag is derived from wMapID per movement
                 frame (never restored from saves). See KEY_LESSONS S55.

 ; GBC WRAM BANKING (S55): $D000-$DFFF is switchable via SVBK ($FF70), banks
 ; 1-7 (32 KB total WRAM). The ENTIRE ROM contains only five SVBK writes:
 ; boot init (bank 1; SVBK=0 maps bank 1) and four battle windows in banks
 ; $51/$52 that briefly select bank 2 to park per-combatant bytes at $DB00+
 ; and switch straight back. Banks 3-7 = 16 KB VIRGIN RAM — unusable for
 ; anything vanilla code reads (vanilla runs SVBK=1; per-frame audio ticks
 ; $DD80+ in bank 1, so foreign-bank access needs di/ei wrapping), but
 ; available to future editor-era systems whose accessors we emit ourselves.

==HRAM==
 Address Size    Description
 ------- ----    -----------
   FFD5     1    Current Column; or Next step / next room id
   FFD6     1    Current Row
   FFDB     1    High nibble: Current Column
                 Low nibble: ?
   FFDD     1    High nibble: Current Row
                 Low nibble: ?
   FFAA     1    Tile id under the player (from $C300 buffer; $00:$1E96).
                 Behavior class = $AA>>2: $0E (ids $38-$3B)=damage tile,
                 $0F ($3C-$3F)=staircase. See GATE_GENERATION.md §5.1.

{{Internal Data|game=Dragon Warrior Monsters}}
