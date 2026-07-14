section "WRAM Bank0", wram0[$c000]

; *******************************************************************
; *                                                                 *
; *             >> LABEL GUIDELINE <<                               *
; *                                                                 *
; *         ; Description of the usage of this memory address.      *
; *         ; Possible values:                                      *
; *         ; 0 = meaning 0,                                        *
; *         ; 1 = meaning 1,                                        *
; *         ; 2 = meaning 2                                         *
; *         label::                                                 *
; *           db ; address as 4 hex value                           *
; *                                                                 *
; *******************************************************************

wRamStart::
  ds $A0


;Main debug menu option is stored here. It is used in the calculation of vram tile offsets. LIKELY USED BY OTHER THINGS
wDebug_main_menu_option:: db ;c0a0


    ds $77B

wIsSGB:: db ;c81c

wIsGBC:: db ;c81d

    ds $28

wJoypad_current_frame:: db ;c846

;Current button being pressed
;00 = none
;01 = A
;02 = B
;04 = Select
;08 = Start
;10 = Right
;20 = Left
;40 = Up
;80 = Down
wJoypad_Current:: db ;c847

    ds $42

wGameMode:: db	;c88a

    ds $e

wRNG1:: db ;c899


wRNG2:: db ;c89a


wBGPalette:: db ;c89b


wObj1Palette:: db ;c89c


wObj2Palette:: db ;c89d


wTempBGPal:: db ;c89e


wTempObj1Pal:: db ;c89f


wTempObj2Pal:: db ;c8a0


    ds $14

wCurrPlayingBGM:: db ;c8b5


wc8b6:: db

wBGM::
  db ;c8b7

wSoundEffect::
  db ;c8b8

wc8b9::
  ds $21

;Currently selected option in menu.
;Menues known to use this byte: Battle, Main, Buy/Sell/Exit,
;0 = FIGHT or INFO
;1 = PLAN or ITEM
;2 = ITEM or SKIL
;3 = RUN or OPTN
wMenu_selection:: db ;c8da

;byte responsible for the currently selected option in the OPTN menu. Also used by the item menu in battle.
wOPTN_and_Item_selection:: db ;c8db

wPLAN_selection:: db ;c8dc

    ds $E

;00 = normal
;01 = text box open
;02 = main menu open
;04 = Entering new area. Monsters group under terry.
;08 = Map open
;10 = Shop menu open
;20 = Warping
;40 = Entering Battle
;80 = unknown. Blank screen with YES NO when forced.
wGameState:: db	;c8eb

    ds $2

wTextSpeed:: db ;c8ee

    ds $1d

wCursorBlinkTimer:: db ;c90c

    ds $18

wScreenIndex:: db ;c925 — sub-map/screen index for room loading

    ds $0F

wGateID:: db ;c935

; Gate floor configuration (loaded from GateFloorDataTable $16:$70A6)
wFloorType1:: db ;c936 — → FloorTypeSelectionTable index
wFloorType2:: db ;c937 — → FloorTypeSelectionTable2 index
wFloorType3:: db ;c938 — → FloorTypeSelectionTable3 index
wCurrentFloor:: db ;c939 — current dungeon floor number
wLastFloor:: db ;c93a — floor count before boss
wBossMapType:: db ;c93b — boss room map_type
wBossTileset:: db ;c93c — boss room tileset

    ds $2B

wMapID:: db	;c968


;Set when in a gateworld, reset when in GreatTree.
wInGateworld:: db ;c969

    ds $2

wIsPlayerChangingMaps:: db ;c96c

; Warp destination (set during room transitions)
wWarpGateId:: db ;c96d — target gate/map ID
wWarpFlag:: db ;c96e — warp type flag
wWarpSpawnXLo:: db ;c96f — spawn X coordinate (lo)
wWarpSpawnXHi:: db ;c970 — spawn X coordinate (hi)
wWarpSpawnYLo:: db ;c971 — spawn Y coordinate (lo)
wWarpSpawnYHi:: db ;c972 — spawn Y coordinate (hi)

    ds $C5

; Encounter state
wEncounterPoolIndex:: db ;ca38 — result of gate+floor threshold lookup
wEncounterCounterLo:: db ;ca39 — steps until next encounter (lo)
wEncounterCounterHi:: db ;ca3a — steps until next encounter (hi)

    ds $04

;00 = HP and MP
;01 = Level and Status
wMonsterInfoToggle:: db ;ca3f

    ds $b

;current gold held by Terry. In order Lo Mid Hi maxes out at 9F8601 which reversed is 01869F or 99,999 in decimal
wCurrGoldLo:: db ;ca4b

wCurrGoldMid:: db ;ca4c

wCurrGoldHi:: db ;ca4d

wBankGoldLo:: db

wBankGoldMid:: db

wBankGoldHi:: db

;the 20 slots of the player's inventory.
wInventory:: ds 20 ;ca51

wBankSlots:: ds 40 ;ca65


section "WRAM Bank1", wramx[$D000], bank[1]

wram1Start:: db

    ds $377

; Custom room overflow BUFFERS ($D379-$D477)
; Used to buffer NPC/exit data from overflow banks ($60+) for cross-bank rooms.
;
; !!! KNOWN COLLISION (S54, scoped down S55) — THESE BUFFERS SIT INSIDE THE
; !!! PARTY/STORAGE MONSTER ARRAY ($CAC1-$D664, 20 slots x $95, indexed via
; !!! GetMonsterDataPtr — zero literal refs, which is how the old "unclaimed"
; !!! grep audit missed it). Slots 14-15 overlay the buffers.
; !!! S55 STATUS — ACCEPTED LEGACY HAZARD, exploration overlay only:
; !!!  * forward corruption (a give into slots 14-15) is TRANSIENT — the
; !!!    buffers self-heal (re-copied by every CustomReadInteract /
; !!!    CustomExitCheck call). The S53 give-then-scroll CRASH is fixed:
; !!!    counters/scratch moved to $DE74 (see below), out of the array.
; !!!  * reverse corruption (buffer copies spraying stored monsters #15-16)
; !!!    REMAINS — keep the array <=14 occupied when using custom rooms.
; !!!  * PHANTOM SPAWNING (confirmed S58, user repro + byte trace): the <=14
; !!!    rule protects REAL monsters only. EMPTY slots 15/16 still get their
; !!!    in-use flag bytes sprayed by the copies — slot 15 flag $D37C = NPC
; !!!    buffer byte 3, slot 16 flag $D411 = exit buffer byte 24 — and any
; !!!    nonzero value there is normalized to a "real" farm monster by the
; !!!    next canonicalize (garbage species/name, level 0, 0 HP/MP; CF2's
; !!!    drain will then level such fossils into visibility). Each custom-
; !!!    room visit can mint up to 2 per canonicalize-with-sprayed-flag.
; !!!    USER RULING (S58, reaffirming S55): ACCEPTED on the exploration
; !!!    overlay — release phantoms in-game as they appear; no interim
; !!!    patch; the CF3 buffer relocation retires the whole hazard class.
; !!! The buffers were NOT relocated: S55 vetting proved no free WRAM block
; !!! >=106 B exists outside the array (attr staging owns $C200-$C2FF, screen
; !!! staging owns $C300-$C4FF — both SRAM-save-copied; audio owns
; !!! $DD80-$DE2B). The editor-era fix is the Cold Farm arc (farm slots ->
; !!! SRAM, ~2.5 KB freed; ROADMAP), which retires this hazard structurally.
CUSTOM_ROOM_START EQU $6B ; first custom map type (107 = one past last original)
    ds 1 ;d378 — freed S55 (wCustomRoomFlag moved to $DE88); inside monster slot 14
wCustomNPCBuffer:: ds 128 ;d379 — NPC interact data copied from overflow bank ($FF terminated)
wCustomExitBuffer:: ds 127 ;d3f9 — exit data copied from overflow bank ($FF terminated)

    ds 20 ;d478-d48b — freed S55 (step counters, wRoomRecScratch, wRoomEncFlag,
          ; Tame vars moved to $DE74 — a slot-16 give landed SkyDragon's
          ; resistance bytes exactly here, the S53/S54 crash vector). Inside
          ; monster slots 16 — do NOT re-place anything here.
    ds $305                         ; gap ($D48C-$D790)

wGroundItemData:: db ;d791

    ds $141

; Script engine state ($D8D3-$D8DF)
wScriptMapType:: db ;d8d3 — copy of current map_type (selects script data bank)
wScriptNPCId:: db ;d8d4 — NPC script_id (selects per-NPC script)
wScriptCounter:: dw ;d8d5 — 16-bit position in NPC script data
wScriptStateFlags:: db ;d8d7 — bit0=active, bit1=text_queued, bit2=delay
    ds 1 ;d8d8
wScriptQueuedTextId:: dw ;d8d9 — queued text ID for ROM0 dispatch
wScriptDelayCounter:: db ;d8db — delay frame counter
wScriptNPCWalkTarget:: db ;d8dc — NPC number for pending walk-toward
wScriptNPCDeltaX:: dw ;d8dd — NPC X movement delta (signed)
wScriptNPCDeltaY:: dw ;d8df — NPC Y movement delta (signed)

    ds $B8

wArenaStarryBattle:: db ;d999 — current Starry Night Tournament battle (0/1/2), or post-game (4)
    ds 1

; Event flag bitfield ($D99B+)
; Flag BC → byte $D99B+(BC/8), bit (BC&7)
wEventFlags:: ds 32 ;d99b

    ds $0D                          ; d9bb-d9c7 (incl. $D9C6-$D9C7 = flag-pool
                                    ; bytes, flags $0158-$0167 — see EVENT_FLAGS)
; [CF2] Pending farm exp accumulator, 24-bit LE, clamp $98967F. Fed per battle
; by bank $50 CF2FarmShareDivert (total/16); drained by bank $73 entry 0 at
; the map-change commit (bank $0B Entry 0) when the destination is non-gate.
; PERSISTENT BY DESIGN: $D9C8-$D9CA sit inside the $C8EA-$D9E9 save image
; (in-gate save rooms exist, so pending must survive save+reload), are
; boot-cleared by ClearAllWRAM, and are the top 3 bytes of the S8-verified
; clean event-flag block — flag indices $0168-$017F are RETIRED from the
; allocator pool in exchange (EVENT_FLAGS.md; editor2/core/project.py).
wPendingFarmExp:: ds 3 ;d9c8

    ds $02                          ; d9cb-d9cc

wColiseumBattle:: db ;d9cd — current consecutive battle in gates/arena
wArenaGroup:: db ;d9ce — arena battle group index

    ds $25

wEventStateMachineIndex:: db ;d9f4 — 11 states (0-10), dispatch at $50:$4017

    ds $0E

; Temp workspace: enemy stats, monster info, breeding vars ($DA00-$DA7F)
wTempEnemyId1:: db ;da03
    ds 1
wTempEnemyId2:: db ;da05
    ds 1
wTempEnemyId3:: db ;da07

    ds $0A

wTempEnemyStatsId:: dw ;da12
    ds 4
wTempEnemyStats:: ds 25 ;da18 — copy loaded by LoadEnemyStats

    ds ($DA31 - ($DA18 + 25))

wTempSpeciesId:: db ;da31
    ds 1
wTempMonsterInfo:: ds 43 ;da33 — copy loaded by bank $03

    ds ($DA6F - ($DA33 + 43))

; Breeding workspace
wBreedParent1Species:: db ;da6f
wBreedParent2Species:: db ;da70 — species or family code ($F0-$F9)
wBreedResultSpecies:: db ;da71 — $FF = not found
wBreedParent1Family:: db ;da72
wBreedParent1FamilySpecial:: db ;da73
wBreedParent2FamilySpecial:: db ;da74
wBreedParent1Slot:: db ;da75
wBreedParent2Slot:: db ;da76
wBreedOffspringPlus:: db ;da77

    ds ($DB55 - $DA78)

; Battle state
wBattlePostFlag:: db ;db55 — 0 for bosses

    ds ($DB85 - $DB56)

wJoinability:: db ;db85 — $07=non-joinable, other=recruitable via RNG

    ds ($DB88 - $DB86)

; Battle combatant index registers
wBattleAttackerIdx:: db ;db88 — attacker combatant index
wBattleTargetIdx:: db ;db89 — target combatant index

    ds ($DB9B - $DB8A)

wBattleCombatantIds:: ds 8 ;db9b — monster ID per combatant slot

    ds ($DBA3 - ($DB9B + 8))

; Battle stat lookup tables
; 6 tables × 16 bytes each. Indexed by combatant (0-2=party, 4-6=enemy).
; Each entry is a 16-bit stat value (LE).
; Initialized by Bank $51 battle setup. HP/MaxHP and MP/MaxMP pairs
; start equal; HP/MP modified during battle.
wBattleHP:: ds 16 ;dba3 — current HP per combatant
wBattleMaxHP:: ds 16 ;dbb3 — max HP per combatant
wBattleMP:: ds 16 ;dbc3 — current MP per combatant
wBattleMaxMP:: ds 16 ;dbd3 — max MP per combatant
wBattleATK:: ds 16 ;dbe3 — attack per combatant
wBattleDEF:: ds 16 ;dbf3 — defense per combatant
wBattleAGL:: ds 16 ;dc03 — agility per combatant
wBattleINT:: ds 16 ;dc13 — intelligence per combatant
wBattleLVL:: ds 16 ;dc23 — level per combatant (tentative)

    ds ($DE74 - ($DC23 + 16))       ; gap ($DC33-$DE73): battle vars, AI score
                                    ; table $DCE4, action queue $DCEC, AUDIO
                                    ; channel state $DD80-$DE2B (6 x 26 B +
                                    ; scalars to $DE2B — S55 correction: NOT
                                    ; battle structs). $DE2C-$DE73 = margin.

; =============================================================================
; Custom room state — RELOCATED HERE S55 (was $D378/$D478-$D48B, inside the
; party/storage monster array — the S53/S54 egg-give corruption root cause).
; $DE74-$DEDD vetted S55: full-corpus scan shows zero real claimants above the
; audio engine's $DE2B ceiling (every $DE30-$DEFF literal is data-as-code junk
; from gfx/audio data banks); SVBK bank-2 windows (banks $51/$52) touch $DB00+
; only; stack ($DFFF down) is fenced by vanilla's own $DF00-$DF0D vars.
; Evidence: tools/audit_wram.py / extracted/wram_usage.json (S55 regen).
; NOT in the SRAM save range ($C8EA-$D9E9) — counters are TRANSIENT by design
; (user decision S55): persistent room state = event flags + entry scripts.
; INITIALIZATION (S55 crash post-mortem — vetted-unclaimed is NOT initialized):
; the old block was defined for free (inside BOTH the boot clear $C000-$DDFF
; AND the save image); this block is above/outside both. Two fixes:
;  * ClearAllWRAM count $1E00->$1EE0 (patches/bank_000.asm) — boot now zeroes
;    $C000-$DEDF, covering this block + reserve.
;  * wCustomRoomFlag is DERIVED (:= wMapID >= CUSTOM_ROOM_START) every
;    movement frame at CopyCustomRoomRecord head (bank $71 template) — it can
;    never be restored from a save again, so it is never trusted as state.
; Load-inside-a-custom-room shows step-0 content (counters not in the save
; image) — expected under transient semantics, NOT a bug.
; Reserve after the block: $DE89-$DEDD (85 B) for counter-region growth.
; =============================================================================
; @BUILD_PROJECT BEGIN wram_step_counters
wCustomStep_Room6B_S0:: db ;de74 — Room $6B screen 0 step counter
wCustomStep_Room6B_S1:: db ;de75 — Room $6B screen 1 step counter
wCustomStep_Room6C_S0:: db ;de76 — Room $6C screen 0 step counter
wCustomStep_Room6C_S1:: db ;de77 — Room $6C screen 1 step counter
wCustomStep_Room6C_S5:: db ;de78 — Room $6C screen 5 step counter
wCustomStep_Room6D_S0:: db ;de79 — Room $6D screen 0 step counter (Pillar B)
wCustomStep_Room70_S0:: db ;de7a — Room $70 screen 0 step counter (keystone proof room)
; @BUILD_PROJECT END wram_step_counters

; Custom-room dispatch scratch, populated by bank $71 via rst $10.
; wRoomRecScratch: the 8-byte $26DD-style record (tileset/dims/threshold) for the
;   current mapID, far-copied from ROM0 ($26DD/$2A5D, mapIDs <$70) or bank $71's
;   Custom26DDTable (mapIDs $70+). Read by the GFX loaders (offset 0) and the
;   collision threshold reader (offset 6). Self-heals per movement frame.
; wRoomEncFlag: set by bank $71 entry 1 (CustomEncResolve) — $01 if the current
;   custom room has encounters enabled (RoomEncTable), else $00.
wRoomRecScratch:: ds 8 ;de7b
wRoomEncFlag:: db ;de83

wTameDelay:: db ;de84 — [S2e] Tame heart->message delay counter (frames)
wTameBGSave:: ds 3 ;de85 — [S2e] RESERVED (flicker removed S52; BATTLE_SKILL_SYSTEM §11.7)
wCustomRoomFlag:: db ;de88 — $00=normal room, $01=custom room active (bank $0B readers)
