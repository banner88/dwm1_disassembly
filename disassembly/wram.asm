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

    ds $790

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

    ds $12

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

    ds ($DB88 - $DB86) ; $DB86-87 free gap. [S45] $DB86 used by S2 skill-alias
                        ; framework as the custom-skill real-id stash (BATTLE_SKILL_SYSTEM.md)

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
