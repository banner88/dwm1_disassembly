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
   C88A     4    wGameMode + sub-modes $C88B-$C88D (S68): top-level mode,
                 ROM0 dispatch $00:$030F (init) / $00:$050F (per-frame).
                 1=field (bank $01), 2=battle (bank $50); full table in
                 ARCHITECTURE "Top-level game mode".
   C88E     1    Mode-change latch (inc'd on every wGameMode write; main
                 loop re-runs the mode INIT table when set) [S68]
   C8AD     4    Saved wGameMode block for overlay modes 7/$0C (restored on
                 overlay exit) [S68]
   C899     2    Pseudo-Random Number (wRNG1/wRNG2) — stays the LIVE,
                 per-frame-advancing RNG pair during battle (HW-pinned S68:
                 two adjacent examines differ); battle engine save/restores
                 it via $C1ED/EE ($52:$556D, phase-6 cycle). LoadBtl_5d29's
                 &$1F==$1F checks on it = the 1/32-per-side random
                 battle-intro event roll [S68]
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
   C8EA     1    Field-live/battle-resume flag (S68): field init sets 1;
                 BattleExitHandler sets bit 7; nonzero -> bank $01
                 ClearAnimationState SKIPS its reset, so script state
                 $D8D5-7 survives and the NPC script RESUMES after a won
                 battle. Cleared (res 7) on loss/arena warps -> full re-entry.
   C8EB     1    wGameState flags. Bit 6 = battle REQUEST latch (set by wild
                 encounters + script battle opcodes; the ROM's only res 6 is
                 $13:$73F5 in the $C905 battle-transition machine) [S68]
   C8ED     1    Follower-render suppression mask (bits 1-3 = the 3
                 followers); boss win ($DA09==3) sets $0E, kept by bank $01
                 only while $D92B==7 — cosmetic [S68]
   C905     1    Battle-transition machine state (bank $13 label13_7366:
                 BGM $4B/$4D, random wipe $C906, sets wGameMode=2) [S68]
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
                 **S60 (CF3): SUPERSEDED for $CC80-$D664** — farm slots 3-19
                 moved to SRAM $A3BA-$AD9E (live in the save image); the WRAM
                 window is FREED. (An earlier "link+arena still time-share it
                 as scratch" clause here was UNSOURCED and is refuted by the
                 S56 access map — no non-array writer into the window exists;
                 link/trade uses staging $D665/$D6FA, outside it. S65 /
                 DOC_AUDIT.) **S65 layout of the window**: wCustomNPCBuffer
                 $CC80 (128 B) / wCustomExitBuffer $CD00 (127 B) /
                 step-counter region $CD80-$CFFF (compiler-owned, 640 B) /
                 wCustomPool $D001-$D664 (1,636 B transient reserve).
                 TRANSIENT permanently: the window's SRAM image is the live
                 farm, so the CF3 copy skips it BOTH ways; init guaranteed
                 zeroed at power-on/new-game/restore (bank $73 entry 6
                 tail-clear, S65). Vanilla literal refs inside the window are
                 data-as-code artifacts ($CD = the CALL opcode minting fake
                 $CDxx operands) — structural proof: the vanilla array lived
                 here. Party 0-2 ($CAC1-$CC7F) + staging $14/$15
                 ($D665-$D78E) remain live WRAM. See MONSTER_DATA "CF3 as
                 built (S60)"; patches/wram.asm banner.
   1:D664        TRUE end of party/storage monster data (slot 19 = $D5D0 +
                 $95 - 1). The old "D6B0" figure here was wrong (S54).
                 History: custom state $D378/$D478-$D48B (S53) → refuted S54
                 (inside slots 14-16; egg-give crash) → scratch/counters to
                 $DE74 (S55) → buffers stayed $D379-$D477 as accepted hazard
                 (phantom spawns, S58) → hazard structurally retired by CF3
                 (S60) → buffers/counters migrated INTO the freed window at
                 $CC80/$CD00/$CD80 (S65; see row above).
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
   1:D9C8   3    [CF2, S57] wPendingFarmExp — pending farm exp, 24-bit LE,
                 clamp $98967F. Fed per battle by bank $50 CF2FarmShareDivert
                 (total/16); drained by bank $73 entry 0 at the bank-$0B
                 map-change commit when the destination is non-gate. Carved
                 from the clean event-flag block (flags $0168-$017F RETIRED —
                 EVENT_FLAGS.md); inside the save image ON PURPOSE (in-gate
                 save rooms exist). Vanilla never touches these bytes.
   1:D988   1    Current step in Labyrinth (part of step counter range above)
                 From the initial room:
                   RIGHT (north one): Mimic
                   DOWN DOWN DOWN RIGHT (south one): Watabou doll
                   UP UP LEFT (south one): Empty spot
                   UP UP UP LEFT DOWN DOWN LEFT (north one): Boss
   1:D997   1    Current step (?) in Unused Gate
   1:D999   1    wArenaStarryBattle — step counter of map $5D (Arena Battle
                 room; zero literal code refs, accessed via the step system).
                 Written by Arena Lobby scr6: 0 = normal arena, 1 = Starry
                 Night, 4 = King battle. Bank $50 post-battle advances the
                 Starry phase 1→2→3 ($50:Jump_050_640a). [S67]
   1:D9CD   1    wColiseumBattle — match index 0-2 within an arena class OR
                 within the in-gate Coliseum trio; also used during Starry
                 Night. Sentinels: $FE = class complete (Arena Lobby scr0
                 victory processing), $FF = lost. Feeds the $1F/$50 arena
                 formula EID = $E0 + 9*group + 3*battle + slot. [S67]
                 CAUTION: shares byte with event flag indices $0190-$0197
   1:D9CE   1    wArenaGroup — arena GROUP: 0-7 = classes G F E D C B A S
                 (bank $09 menu: 4*[$C8E3]+([$C8E2]&$7F)), 8 = Starry Night,
                 9 = King (both written by Arena Lobby scr6). Arena Lobby
                 scr0 branches 0-7 for the per-class victory cascade.
                 (Old "round counter / 254" description was S-era guesswork;
                 the $FE sentinel lives in $D9CD.) [S67]
                 CAUTION: shares byte with event flag indices $0198-$019F
   1:D9CF  ~8    Multi-use block $D9CF-$D9DE. Gate-room context: reset
                 counters written 0 on entry. In-gate COLISEUM context (map
                 $52): $D9CF = lifetime visit counter (bit7 = cap; ≥9 →
                 better prize table), $D9D0 = rolled prize item id,
                 $D9D1-$D9D6 / $D9D9-$D9DE = pending foreign-master parties
                 2 and 3 (3 × 16-bit EIDs each), chained by $50:SetBtl_67ae.
                 [S67] Shares bytes with flag indices $01A0-$01DF.
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
   1:D9EC   1    Battle PHASE machine index — 18 states (S68; not 15), the
                 whole battle: intro 0-3, main 4-8, sequencer 9, post-battle
                 $0A-$0D, exit $0E-$11. Dispatch BattlePhaseTable $50:$5F3A,
                 gated by $DB73. Renamed refs: Jump_050_640a is now
                 BattleExitHandler; Jump_050_6aac is BattlePhase09_TurnSequencer.
   1:D9ED   1    Battle phase-9 sub-state (6 states, BattlePhase09SubTable
                 $50:$6AB0) [S68]
   1:D9F4   1    NESTED battle sub-machine index (11 states 0-10; ticked from
                 battle phase $04 via LoadBtl_4017 — battle-scoped, NOT the
                 main game state; wEventStateMachineIndex label is historical)
                 [S68]
   1:DA02   1    Enemy COUNT − 1 (0/1/2 → 1-3 enemies). [S67, code-derived]
   1:DA33   1    Battle frame-delay counter (phases $00/$07/$08/$0A) [S68]
   1:DA03   2    Enemy 1 stats EID, 16-bit LE (wTempEnemyId1 = low byte)
   1:DA05   2    Enemy 2 stats EID, 16-bit LE
   1:DA07   2    Enemy 3 stats EID, 16-bit LE
   1:DA09   1    Battle mode: 0 = field-touch (bank $06), 1 = scripted preset
                 (opcodes $05/$20/$36), 2 = party-scaled random ($52),
                 3 = boss ($5A/$5B). [S67; mode 1 + $DA02 semantics USER-VERIFIED
                 on HW (arena, SameBoy watchpoints); modes 0/2/3 code-derived]
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
   1:DB55   1    wBattlePostFlag = battle OUTCOME: 0=win, 1=loss, 2=neutral
                 (S68; set by bank $52 KO scans ~$76E0/$7727, XOR'd for link
                 peer at $52:$774F; loss skips exp+join and triggers the
                 Castle warp + gold/item penalty in BattleExitHandler).
                 HW-pinned S68: FLEE ends at 2 (resolver $50:$5808 — jumps
                 phase $0A, masks exp targets $DD1F-22 = $FF; $DB73-armed
                 edge -> 1); CAUGHT monster = plain win 0 ($52:$7729 via
                 phase-7 turn engine, backtrace-verified). Also briefly the
                 1/32 random intro-event marker at battle phase 2
                 (LoadBtl_5d29 rolls live RNG $C899/$C89A &$1F==$1F).
   1:DB73   1    Battle phase-machine freeze gate: $FF = frozen (set on loss
                 for defeat jingle/fade; released at BattlePhaseFreezeWait
                 $50:$5F5E when [$DD80]&[$DD9A]==$FF) [S68]
   1:DB85   1    Joinability: $07=non-joinable, other=recruitable via RNG
   1:DD62   1    Battle-running latch (S68): nonzero -> bank $50 entry 1 runs
                 bank $02 entry 0 per-frame; ==0 -> the $D9EC phase machine
                 dispatches. Cleared by BattleInit.
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
   1:DE74  106   CUSTOM SCRATCH BLOCK (S55 relocation; counters MIGRATED OUT
                 S65): $DE74-$DE7A static pad (step counters now at $CD80
                 region, see the $CC80 window row), wRoomRecScratch $DE7B,
                 wRoomEncFlag $DE83, Tame vars $DE84-$DE87, wCustomRoomFlag
                 $DE88, CF3 mailbox $DE89-$DE8A, E3 banked-copy mailbox
                 $DE8B-$DE91 (S69: wSRAMXferBank db, wSRAMXferSrc/Dst/Len dw
                 — params for CF3SRAMBankedCopy, bank $73 entry 9, the ONLY
                 path to SRAM banks 1-3 under the RAMB pin; see ARCHITECTURE
                 "SRAM banking as built S69"), wSnapBounce $DE92-$DEB1 (S69v2: 32-B
                 bounce for CF3SnapXfer — roster snapshot staging, banks
                 can't see each other); $DEB2-$DEDD reserved.
                 Vetted: no real claimant above the audio ceiling $DE2B
                 (full-corpus scan; $DE30-$DEFF literals are all data-as-code
                 junk); SVBK windows touch $DB00+ only; NOT in save range.
                 INIT (S55v2): vanilla ClearAllWRAM stops at $DDFF — the
                 patched build extends it to $DEDF so this block is boot-
                 zeroed (STILL REQUIRED post-S65: the scratch vars remain);
                 wCustomRoomFlag is derived from wMapID per movement
                 frame (never restored from saves). See KEY_LESSONS S55.

   0:FFA3        HRAM shadow of the MBC5 RAM-bank register ($4100 writes are
                 paired with it: bank_040 multi-bank SRAM wipe, bank_020 ×4,
                 boot init). Dead-store convention on the 8 KB cart; LIVE
                 under a 32 KB expansion — see ARCHITECTURE "SRAM banking"
                 (S65 audit) before touching.

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
