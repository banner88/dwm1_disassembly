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

; S133 census: written at field init (bank $01 InitFieldState) and by the two
; new-game / link map seeds (bank $15), saved with the image ($A0A4/$A0A5) —
; and NEVER READ, by literal or by pointer, in either tree. Dead mirrors of
; wMapID / wInGateworld (not a "previous map" anyone consults).
wMapIDMirror:: db ;c96a — write-only copy of wMapID (S133)
wInGateworldMirror:: db ;c96b — write-only copy of wInGateworld (S133)

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

    ds $34 ; ca8d-cac0 — party list ($CA8D/$CA8E-$CA90), library seen-bits
           ; ($CA94-$CAB1), selection registers ($CAC0 etc.) — LIVE vanilla

; Party monster records, slots 0-2 ONLY ($95 B each) — LIVE. Post-CF3 (S60)
; the party stays hot in WRAM; farm slots 3-19 are SRAM-resident at
; $A1FB+s*$95 (MONSTER_DATA "CF3 as built"). The vanilla array extent
; $CAC1-$D664 (20 slots) ends here at slot 2.
    ds $1BF ; cac1-cc7f

; =============================================================================
; CF3-FREED WINDOW $CC80-$D664 (freed S60; custom-room/editor layout S65)
; This is the vanilla WRAM shadow of farm slots 3-19. Post-CF3 it is DEAD to
; the engine: GetMonsterDataPtr forks slots >=3 to SRAM, all 48 walker
; advances hop the boundary, trade-recv and new-game clear are redirected
; (patches/bank_073.asm). The S54/S55/S58 buffer-overlay hazard class
; (real-monster corruption + phantom spawning) is structurally retired.
;
; PERSISTENCE: TRANSIENT, permanently. The window's save-image address is
; SRAM $A3BA-$AD9E ($C8EA->$A024 copy) — exactly where CF3's live farm
; records now reside — so CF3CopyToSRAM/CF3CopyFromSRAM (bank $73 entries
; 5/6) SKIP it in BOTH directions. Nothing here is saved or restored; the
; S58 "EXPLOIT the vanilla block copy" plan is dead as-built and cannot be
; revived without evicting the farm. Persistent room/editor state = event
; flags + entry scripts (user decision S55, reaffirmed S65); larger
; persistent state = future SRAM expansion (ROADMAP E3).
; INIT: inside the original ClearAllWRAM span ($C000+) — zeroed at boot for
; free (unlike the S55 $DE74 move, which needed the $1EE0 extension).
; Layout: $CC80 NPC buffer / $CD00 exit buffer / $CD80-$CFFF step-counter
; region (compiler-owned) / $D001-$D664 wCustomPool transient reserve.
; =============================================================================
wCustomNPCBuffer:: ds 128 ;cc80 — NPC interact data copied from overflow bank ($FF terminated; relocated S65, was $D379)
wCustomExitBuffer:: ds 127 ;cd00-cd7e — exit data copied from overflow bank ($FF terminated; relocated S65, was $D3F9)
    ds 1 ;cd7f — pad to the counter-region base

; Custom step-counter region ($CD80-$CFFF, 640 B, compiler-owned; migrated
; S65 from $DE74 where the S55-vetted reserve capped at ~106 B — campaign
; scale needs one counter per authored screen). TRANSIENT (see banner):
; load-inside-a-custom-room shows step-0 content by design.
; @BUILD_PROJECT BEGIN wram_step_counters
wCustomStepZero:: db ;cd80 — S146: the one-state screens' shared counter — always 0 (nothing writes it; the original game's $D998 rule)
wCustomStep_Room6C_S0:: db ;cd81 — Room $6C screen 0 step counter (dusk_mirror)
wCustomStep_ArenaClone_S1:: db ;cd82 — Room $72 screen 1 step counter (arena_clone)
    ds 1 ; reserved hole (explicit addresses above leave a gap)
wCustomStep_Room6C_S5:: db ;cd84 — Room $6C screen 5 step counter (legacy hole — kept at base+4 so the relative counter layout matches the proven S55 shape; S65 migration moved the base $DE74→$CD80)
    ds 635 ; reserved (padded to region_size; region ends at $D000 — PROJECT_COMPILER.md §2.6)
wCustomStep_Room6B_S0 EQU wCustomStepZero ; Room $6B screen 0 step counter (gate_island) — one state: the shared zero byte
wCustomStep_Room6B_S4 EQU wCustomStepZero ; Room $6B screen 4 step counter (gate_island) — one state: the shared zero byte
wCustomStep_Room6C_S4 EQU wCustomStepZero ; Room $6C screen 4 step counter (dusk_mirror) — one state: the shared zero byte
wCustomStep_Room6D_S0 EQU wCustomStepZero ; Room $6D screen 0 step counter (gate_rotation) — one state: the shared zero byte
wCustomStep_Room70_S0 EQU wCustomStepZero ; Room $70 screen 0 step counter (ember_keystone) — one state: the shared zero byte
wCustomStep_Room71_S0 EQU wCustomStepZero ; Room $71 screen 0 step counter (medal_vault) — one state: the shared zero byte
wCustomStep_Room72_S0 EQU wCustomStepZero ; Room $72 screen 0 step counter (arena_clone) — one state: the shared zero byte
wCustomStep_Room72_S2 EQU wCustomStepZero ; Room $72 screen 2 step counter (arena_clone) — one state: the shared zero byte
wCustomStep_Room73_S0 EQU wCustomStepZero ; Room $73 screen 0 step counter (island_copy) — one state: the shared zero byte
wCustomStep_Room73_S4 EQU wCustomStepZero ; Room $73 screen 4 step counter (island_copy) — one state: the shared zero byte
wCustomStepRegional EQU $CD80 ; S140: the regions' shared counters start here
; @BUILD_PROJECT END wram_step_counters


section "WRAM Bank1", wramx[$D000], bank[1]

wram1Start:: db

CUSTOM_ROOM_START EQU $6B ; first custom map type (107 = one past last original)
REGION_IDS EQU $80 ; S140 (ARC CAP3a): place ids per region, $6B-$EA (PlaceNum<bank>)
LINK_ID_FIRST EQU $EB ; S140: exit-row link ids $EB-$FE (CopyExitListToBuffer -> RegionCommit)
LINK_IDS EQU 20 ; S140: $EB + 19 = $FE ($FF ends an exit list)

; CF3-freed window continues into WRAM bank 1 ($D001-$D664; banner at $CC80).
; wCustomPool: reserved TRANSIENT editor scratch pool (never saved/restored —
; the CF3 copy skips this window's SRAM image in both directions; see the
; $CC80 banner). Future subsystems carve named spans from the TOP ($D001+)
; and document them here. The historical buffer/counter addresses inside
; ($D379/$D3F9/$D478-$D48B) are plain pool bytes since the S65 relocation.
; FX1 (S71): wMonList — the roster display-list / compaction-map buffer.
; Vanilla built monster slot-index lists AND the canonicalizer's old->new
; compaction map at $C0D8, whose safe extent is only ~36 B ($C0FC/$C0FD are
; live bank $02 state, $C100 is per-screen content). At 40 array slots the
; map is 40 B and farm lists reach 37 entries, so every MONSTER-list use of
; $C0D8 (canonicalizer map + count/list-builder pairs + $C0D8[cursor]
; consumers in banks $01/$0A/$12/$15/$18/$51) is repointed here. Non-roster
; $C0D8 scratch users (breeding family buffer, skill working copy, master
; availability, the 4-entry drop/pick working set $C0D8-$C0DB) STAY at $C0D8.
; Transient by design (init-zero guaranteed by the window-clear chain).
wMonList:: ds 64 ;d001-d040 — 40 used at TOTAL_SLOTS=40; 64 reserved
; S97 round 2: dialog-box + YES/NO-box attribute saves for free-colour custom
; rooms (bank $73 entries 14-18): 5 box rows x 20 cells and the 6x5 choice box
; of the room's GBC attributes, a "saved" bitmask, one scratch byte.
; Transient by design (a warp mid-dialog leaves stale mask bits 0-4: harmless,
; every box draw rewrites a row's bit before any close reads it).
wBoxAttrSave:: ds 100 ;d041-d0a4 — room attrs under the dialog box (row*20+col)
wBoxAttrMask:: db ;d0a5 — bits 0-4: dialog box row r set to palette 7 (restore on close); bit 5: the YES/NO box (wChoiceAttrSave)
wBoxAttrRow:: db ;d0a6 — scratch: the row being restored
wChoiceAttrSave:: ds 30 ;d0a7-d0c4 — room attrs under the YES/NO choice box (6x5, row-major; S97 r2)
; S102: own tile animations (bank $6C CustomTileAnimate; PROJECT_COMPILER
; §2.19). Transient by design: wTileAnimRoom = the custom map ID whose timers
; are live — any other value (boot zero, another room, a reload) restarts
; them from the room's data, and every step copies a WHOLE frame, so nothing
; here has to survive a save or a battle. 2 bytes per group (timer, step);
; TILEANIM_MAX_GROUPS groups per room (the compiler refuses more).
TILEANIM_MAX_GROUPS EQU 32
wTileAnimRoom:: db ;d0c5 — map ID the state below belongs to
wTileAnimLeft:: db ;d0c6 — tiles still allowed this frame (TILEANIM_CAP budget)
wTileAnimVBK:: db ;d0c7 — rVBK on entry (restored on exit)
wTileAnimSrc:: dw ;d0c8-d0c9 — frame block pointer of the step being copied
wTileAnimState:: ds 2 * TILEANIM_MAX_GROUPS ;d0ca-d109 — per group: timer, step
; S105 (G3 capacity): the follower gfx-ID a new species' fork computes. The
; eight FollowerArtResolveXX forks return HL -> a gfx-ID WORD that the caller
; reads at once (ld e,[hl] / inc hl / ld d,[hl]); for species 221-239 the fork
; writes $7E00 + (species-221)*2 here and returns HL = wNewSpeciesGid (no
; per-bank tables). Transient: written right before every read.
wNewSpeciesGid:: dw ;d10a-d10b — computed new-species follower gfx-ID (lo, hi=$7E)
; S111: the learn scanner's row buffer for the custom skills (bank $06
; LearnLoopFork / bank $72 CustomLearnRow72 copy one 18-byte CustomLearnTable
; row here right before the scanner reads it). Transient by design.
wLearnRowBuf:: ds 18 ;d10c-d11d — one custom-skill learn row
; S114 (P3.13a): the encounter list in use. Bank $01 LoadNextDungeonFloor
; (same-size fork) copies the list bank $76 EncResolve chose here — a vanilla
; list from bank $01 EncounterPoolData, a project list from bank $76 — and
; EncounterMonsterSelect / SaveRegsForEncounter / LoadFloorAndEncounterData
; read it instead of EncounterPoolData + number*26. Every reader runs right
; after LoadNextDungeonFloor in the same routine, so it is transient by design.
wEncListBuf:: ds 26 ;d11e-d137 — the 26-byte encounter list in use
; S115 (ROADMAP NG1, new gates): the 8-byte GateFloorDataTable-format row of a
; NEW gate (wGateID >= 32). Bank $16 GateRowPtr (the two same-size reader
; forks in entry 5) far-calls bank $76 entry 1 NewGateRowCopy, which copies
; NewGateRows[wGateID-32] here, and the readers take HL = wGateRowBuf instead
; of GateFloorDataTable + wGateID*8. Written right before every read, so it
; is transient by design.
wGateRowBuf:: ds 8 ;d138-d13f — the current new gate's 8-byte row
; S117 (FLAG EXPANSION): the extended event flags, indices $1000-$17FF
; (2,048 flags, MSB-first like the vanilla bitfield). Every flag op reaches
; them through ROM0 ComputeFlagAddress -> bank $73 entry 21 FlagAddr. NOT
; transient: bank $73 ExtFlagsCommit / ExtFlagsRestore carry them through
; the explicit save (SRAM bank 3, magic "X1"); new game zeroes them
; (CF3NewGameClear covers $C8EA-$D9E9).
wExtFlags:: ds 256 ;d140-d23f — extended event flags $1000-$17FF (saved via SRAM bank 3)
; S117 (P3.13c Shops): which shop list a shopkeeper sells — a `shop` script
; writes list index + 1 right before opcode $04 $0000 $0680; bank $77 ShopFill
; reads it at every BUY (0 = the vanilla room rule) and bank $77 ShopClose
; clears it when the shop closes. Transient by design.
wShopID:: db ;d240 — the next shop's list (index + 1), 0 = by room (bank $77 ShopFill)
; S117b: bank $77 ScreenPush scratch (the bank $09 screen push writes palette
; attributes in free-colour custom rooms). Transient by design.
wPushAttrOn:: db ;d241 — $80 = this push also writes attributes
wPushAttrRow:: db ;d242 — the row being written (0-17)
; S121 (the Milly hook): the player shape's frame tables while the player is Milly
; (bank $79 entry 1 MillyPlayerSheet copies them here at every field tile load once
; flag $179F is set; bank $79 entry 0 hands their address to bank $04's metasprite
; builders, which read them with bank $04 mapped). Transient by design: rebuilt per
; load; entry 0 falls back to Terry's tables while the high byte at +1 is zero.
wMillyLayout:: ds 160 ;d243-d2e2 — Milly's level-1/2 frame tables
; S123 (NPC colours): bank $60 CopyNPCListToBuffer writes, per NPC slot, $80 |
; OBJ palette (0 = the sprite's own) from the room list's $A2 prefixes, tagged
; with the map / screen it was copied for; bank $60 entry 11 NpcColourDraw reads
; them at every field NPC draw. Transient by design (rebuilt at every list copy).
wNpcColour:: ds 8 ;d2e3-d2ea — per NPC slot: $80 | palette, 0 = own colours
wNpcColourMap:: db ;d2eb — wMapID of the last list copy
wNpcColourScr:: db ;d2ec — wScreenIndex of the last list copy
wNpcColourNext:: db ;d2ed — copy scratch: the colour for the next NPC entry
wNpcColourK:: db ;d2ee — copy scratch: NPC entries seen so far
; S125 (ROADMAP P3.14d, the hub): why the player was sent to the project's hub.
; Bank $71 entry 9 HubWarp (the four engine Castle warps) and the compiler's
; "go to the hub" script ladders write it right before the warp; the hub
; room's arrival scenes test it (op $15) and the hub room's entry script
; clears it, so it lives for one arrival. 0 = no hub arrival (also after a
; warp to the vanilla Castle, which keeps its own $D92B code). Transient:
; the window-clear chain zeroes it at power-on / new game / CONTINUE.
wHubReason:: db ;d2ef — 0 none, HUB_LOST .. HUB_CONTINUE (below)
HUB_LOST EQU 1          ; a battle was lost (bank $50 BattleExitHandler)
HUB_WIPED EQU 2         ; the party fell on damage floors (bank $06, message $021A)
HUB_WARPWING EQU 3      ; the WarpWing item (bank $07 item menu)
HUB_FINAL_LOST EQU 4    ; the Starry Night final was lost (bank $50)
HUB_HOME EQU 5          ; a script sent the player home (helper / move "hub")
HUB_ARENA_WON EQU 6     ; a script after an arena class was won
HUB_CONTINUE EQU 7      ; S138: CONTINUE of a save in a place the build lacks (bank $71 entry 10)
; S126 (ROADMAP P3.14e1, service NPCs): the room's tile slots $60-$7F ($9600-
; $97FF, VRAM bank 0) while the farm (screen effect 3) or the egg appraiser (7)
; draws its icons over them in a CUSTOM room: bank $77 entry 6 ServiceOpenTiles
; saves them once per screen (wServiceTileSaved := 1), entries 4 / 5 (the
; closes) copy them back and clear the flag. Transient by design (one screen);
; the window-clear chain zeroes the flag at power-on / new game / CONTINUE.
wServiceTileSave:: ds 512 ;d2f0-d4ef — saved room tiles $60-$7F
wServiceTileSaved:: db ;d4f0 — 1 = wServiceTileSave holds this screen's room tiles
; S126: which of the project's service line sets the screen effect speaks — a
; service / shop script writes the set's number right before opcode $04 and 0
; right after it (the opcode waits for the screen to close); bank $77 entry 3
; SayText reads it (0 = only the lines that apply to every NPC of the kind).
wServiceLines:: db ;d4f1 — the active line set (0 = none)
; S127 (ROADMAP P3.14e2, breeding NPCs): the breeding NPC the player talked to
; last (the compiler's breeder number, 1-255; a breeder / Grandpa script writes
; it right before its menu) — the room's generated return script (after the
; breeding ceremony, $D951 = $F0 / $F1 / $F2) reads it to know which NPC turns
; to the player, speaks and records the breeding. Transient.
wBreedLast:: db ;d4f2 — 0 none, else the breeder number
; S127: the RANDOM breeders of the room on screen — 4 slots of [state, pool,
; enemy row lo, hi]. A random breeder's script writes its pool number to the
; slot and gives op $42 the pseudo enemy row $0F00 + slot; bank $14
; LoadEnemyStatsExt hands that to bank $77 entry 8 BreedSlotEID, which rolls the
; slot once (state 0 -> 1: the pool's band for the player's progress, then a
; weighted mate) and answers the real row. State 2 = this appearance's breeding
; is done (the return script writes it). Bank $73 entry 0 (the map-change
; commit) clears every state — a new appearance re-rolls — except on the way
; into / back from the ceremony (map $08 / $D951 >= $F0). Transient.
wBreedSlots:: ds 16 ;d4f3-d502 — 4 x [state, pool, row lo, row hi]
BREED_SLOTS EQU 4
; S127: BreedRoll's scratch — the player's progress on the pool's four scales
; (average party level; arena classes won x 12; monsters seen / 2; the pool's
; story milestones reached x the pool's step), then the pool's measure mask and
; story step. Only live inside one roll.
wBreedVals:: ds 4 ;d503-d506 — level, arena, seen, story (scaled 0-~120)
wBreedMask:: db ;d507 — bit 0 level, 1 arena, 2 seen, 3 story
wBreedStep:: db ;d508 — the story scale: 100 / milestones
; S129 (ROADMAP P3.14b, story checks): the answer of the last story check read
; (bank $77 entry 11 StoryCheck: $FF holds / $00 not) — bank $73 FlagAddr hands
; this byte to ComputeFlagAddress for a virtual flag $1800-$18FF, whose caller
; tests it at once. Transient by design.
wStoryFlag:: db ;d509 — the last story check's answer
; S136 (ROADMAP ARC CAP2b, place banks): the current call's place index inside
; its home bank — bank $60 PlaceOf writes it right before EVERY forwarded call
; (entries 0/1/2/4/5/8/9/10) and the home bank's readers (place_readers.asm)
; index their tables with it. Not a cache: nothing reads it outside one call.
wPlaceIdx:: db ;d50a — the place's index in its home bank (one call's scratch)
; S137 (ROADMAP ARC CAP2c) — the RENDER WALK block. Bank $17 entries 0 / 1 walk
; table[A] dw -> [wScreenIndex] dw -> [counter ptr:2] -> + [counter]*4 ->
; [attr_entry, attr_bank, pal_ptr:2]; a custom room's rows and palettes now
; live in its HOME BANK, so CustomAttrCheck far-calls bank $60 entry 13, whose
; reader (place_readers.asm CustomRenderCopy) rebuilds this block for the
; current screen + state on EVERY call and returns HL = wRenderTable, A = 0:
; the unchanged bank $17 walk then reads WRAM. Not a cache — written right
; before each walk. Transient.
wRenderTable:: dw ;d50b — wRenderScr - 2 * wScreenIndex (the walk adds it back)
wRenderScr:: dw ;d50d — = wRenderRow
wRenderRow:: ds 6 ;d50f — dw wRenderZero, db attr entry, attr bank, dw palette
wRenderZero:: db ;d515 — always 0 (the "step counter" the walk reads)
wRenderPal:: ds 32 ;d516-d535 — slots 0-3 of a place palette (bank $17 LoadPal_46a1 copies from here)
; S140 (ROADMAP ARC CAP3a) — REGIONS. A custom place is (wMapRegion, wMapID);
; every per-place table is indexed by its PLACE NUMBER (PlaceNum<bank>,
; editor2/core/templates/place_number.asm). wMapRegion is SAVED through SRAM bank
; 3 (bank $73 ExtFlagsCommit / ExtFlagsRestore, magic "X2" + $A002 — this
; window is outside the save image) and zeroed by a new game (CF3NewGameClear
; covers $C8EA-$D9E9). It changes only at the room commit (bank $73 entry 0
; RegionCommit), a gate insert / the boss floor (entry 22) and a load.
; wWarpRegion = the next commit's region + 1 (0 = none; the hub). wExitLinks =
; per LINK id $EB + k: [region, real map id] of the exit row the current exit
; list gave that id (place_readers.asm CopyExitListToBuffer).
wMapRegion:: db ;d536 — the current custom place's region (0 = map ids $6B-$EA as written)
wWarpRegion:: db ;d537 — region + 1 for the next room commit (0 = keep the region)
wExitLinks:: ds 2 * LINK_IDS ;d538-d55f — per link id: region, real map id
; S141 (ROADMAP ARC CAP3b r3): the NPC sheet being loaded (bank $0B CmpRoom_4839 / bank $06
; ReloadNPCSheets hand their sheet index c to bank $77 entries 12 / 13 NpcSheetLoad here).
wNpcSheetIdx:: db ;d560 — the cache index c of the NPC sprite sheet being DMA'd
; S150 (ROADMAP P3.6 / Phase F T-author) — EDITED GAME TEXT, one text lookup's scratch:
; ROM0 SaveBankAndSwitchCopy sets wTextOvrMode = 1 right before RunTextHandler's lookup
; (a COPY into [$C837]); bank $60 entry 14 / the text home bank's TextOvrFind read and
; clear it in the same lookup. wTextOvrPtr = an edited text's address (or the copy
; buffer) — SaveBankAndSwitch's level-2 read fetches it from here (DE = wTextOvrPtr -
; 2 * id; WRAM reads the same whatever ROM bank is mapped). Transient.
wTextOvrMode:: db ;d561 — 1 = the current text lookup is a copy (RunTextHandler)
wTextOvrPtr:: dw ;d562 — the edited text's address for SaveBankAndSwitch's level 2
; S151 (ROADMAP E9) — ITEMS: an item's BEHAVIOUR id. Bank $77 entry 16 ItemRecordCopy
; (every item record copy — bank $03 entry 2) writes wItemBase = the item's base: the id
; itself for the game's 44 items, the item a project item works like (custom.items[].base)
; for ids 44+. The dispatches that pick code by the item (bank $03 entries 3 / 4, bank $07
; ItemBase07, bank $09 ShopSellPrice) read it instead of [$DA5E]. wItemInUse = the item the
; hero picked in battle (bank $77 entry 18 BattleItemPick): the battle names it from here
; (banks $52 / $54 read it where they used to compute skill − $AF). Transient.
ITEM_FIRST_NEW EQU $2C ; S151: the first project item id (the game's items are 0-43)
; S160 (ROADMAP E13) — 14 RECLAIMED skill ids: the battle skills of the items LifeAcorn,
; MysticNut, the four seeds ($BC-$C1 = items 13-18) and WarpWing, TinyMedal, the six books
; ($CC-$D3 = items 29-36) — items the game never lets the hero use in battle (record +10
; = 1) — hold NEW skills (each runs a stock skill's effect, its BASE). A reclaimed id keeps
; its stock rows (record, both MP copies, name, SKIL text, look, sound, element, learn
; row, announce slot = the skill's data); bank $72 ReclaimBaseTable names its base, bank
; $58 ReclaimTargetTable its AI target row; the game's id-range code sees it as a new
; skill (RECLAIM_VIEW) at the sites where an item id would behave otherwise
; (BATTLE_SKILL_SYSTEM §13.12); bank $77 refuses the 14 items in battle by their base.
RECLAIM_A EQU $BC       ; S160: the first reclaimed id (LifeAcorn's battle skill)
RECLAIM_A_END EQU $C2   ; S160: one past the first run ($BC-$C1)
RECLAIM_B EQU $CC       ; S160: the second run (WarpWing's battle skill)
RECLAIM_B_END EQU $D4   ; S160: one past the second run ($CC-$D3)
RECLAIM_VIEW EQU $EF    ; S160: the id the game's id-range code sees for a reclaimed id (a new skill's)
RECLAIM_ROWS EQU 24     ; S160: ReclaimBaseTable / ReclaimTargetTable rows ($BC-$D3; $C2-$CB = $FF)
CUSTOM_MSG_ROWS EQU 33  ; S160: bank $4C CustomMsgPtrTable rows of $DE-$FE (the 14 reclaimed ids follow)
wItemBase:: db ;d564 — the behaviour id of the item last copied to $DA62 (S151)
wItemInUse:: db ;d565 — the item the hero uses in battle (S151)
; S153 (ROADMAP E5) — THE ENDING: where the field goes after the credits. A project's
; "Roll the credits" step runs bank $77 story command 6 credits_after just before the
; mode change (op $3E, game mode 4): +0 = 1 (set), +1 the map id, +2 the region + 1
; (0 = region 0), +3 / +4 X px, +5 / +6 Y px. Bank $5F CreditsDone (region credits_after)
; far-calls bank $79 entry 4 CreditsAfter, which writes the warp mailbox from it (+0 = 0:
; the game's own intro bedroom) and clears +0. Transient (set and used in one ending).
wCreditsAfter:: ds 7 ;d566-d56c
; S154 — THE MEMORIAL (statues of the monsters that won a boss / an arena class / Starry
; Night and are no longer with the player; PROJECT_COMPILER §2.62, DATA_STRUCTURES "The
; memorial (S154)"). The list itself lives in SRAM bank 3 ($A110+, 8 B an entry, a ring of
; MEM_RING entries — bank $79 entries 6-9); wMemCount / wMemHead say which entries are
; live and ride the EXPLICIT save (bank $73 MemorialCommit / MemorialRestore, magic "M1"
; at bank 3 $A003): this window is zeroed by a new game and at every load before the
; restore, so a reset without saving forgets the victories since the save. The rest is
; transient: wMemPartyN = the party count at the battle's start (bank $50 phase 0; a
; monster that JOINS in that battle comes after it in the party list), wMemPlace = the
; place of the last full room load (region, map id — a different one re-rolls the
; statues), wMemPicks = the ring entry each statue of the room shows ($FF none),
; wMemGone = the roll's bitmap (live entry i = bit i), wMemDraw = the picture bank's
; input (species, the 4 tile ids, the shade map — S154 r2), wMemCur = one entry's fields (tag, species, level,
; nickname 4), wMemTmp = loop scratch.
wMemCount:: db ;d56d — live entries (saved)
wMemHead:: db ;d56e — the ring index of the oldest live entry (saved)
wMemPartyN:: db ;d56f — the party count when the battle started
wMemPlace:: ds 2 ;d570 — region, map id of the last full room load
wMemPicks:: ds 8 ;d572 — per statue of the room: the ring entry shown, $FF = none
wMemGone:: ds 16 ;d57a — the roll: live entry i has left the player (bit i)
wMemDraw:: ds 6 ;d58a — species, tile ids TL / TR / BL / BR, the shade map (the picture bank's input)
wMemCur:: ds 7 ;d590 — tag, species, level, nickname (4)
wMemTmp:: ds 2 ;d597 — scratch
; S158 — THE BREEDING HINTS (monuments and archives; PROJECT_COMPILER §2.66,
; DATA_STRUCTURES "Breeding hints (S158)", bank $79 entries 10-12). What the player
; knows lives in SRAM bank 3 (two bitsets, written at once); this is transient:
; wHintPlace = the visit (region, map id, gate, floor of the last room load — another
; one clears the latches), wHintLatch = per monument slot of the room the hint it
; showed this visit + 1 (0 = none yet) — MUST follow wHintPlace (HintRoomNote clears
; both in one run), wHintCur = the hint the inserts hold, wHintSay = 1: the next
; shown text is its riddle (bank $60 TextOverride), wHintRow = the special-table row
; the last breeding scan matched ($FFFF none; bank $69), wHintCursor = an archive's
; next position, wHintN / wHintK / wHintTmp = scratch.
wHintPlace:: ds 4 ;d599 — region, map id, gate, floor of the last room load
wHintLatch:: ds 16 ;d59d — per monument slot (8): the hint shown this visit + 1
wHintCur:: dw ;d5ad — the hint in the inserts
wHintSay:: db ;d5af — 1 = the next shown text is the hint's riddle
wHintRow:: dw ;d5b0 — the special row the last scan matched ($FFFF none)
wHintCursor:: dw ;d5b2 — the archive's next list position
wHintN:: dw ;d5b4 — candidates counted
wHintK:: dw ;d5b6 — a hint (scratch)
wHintTmp:: ds 4 ;d5b8 — the monument's slot / families lo / hi / scratch
wCustomPool:: ds $5A4 - 132 - 5 - 2 * TILEANIM_MAX_GROUPS - 2 - 18 - 26 - 8 - 256 - 1 - 2 - 160 - 12 - 1 - 514 - 23 - 1 - 1 - 43 - 2 - 2 * LINK_IDS - 1 - 3 - 2 - 7 - 44 - 35 ;d5bc-d5e4 — transient reserve (was $664; FX1 carved 64+128; S97 132; S102 69; S105 2; S111 18; S114 26; S115 8; S117 256 wExtFlags + 1 wShopID; S117b 2 push scratch; S121 160 wMillyLayout; S123 12 NPC colours; S125 1 wHubReason; S126 514: the service tile save + wServiceLines; S127 23: wBreedLast + wBreedSlots + the roll scratch; S129 1: wStoryFlag; S136 1: wPlaceIdx; S137 43: the render walk block; S140 42: wMapRegion + wWarpRegion + wExitLinks; S141 1: wNpcSheetIdx; S150 3: wTextOvrMode + wTextOvrPtr; S151 2: wItemBase + wItemInUse; S153 7: wCreditsAfter; S154 43: the memorial; S154 r2 + 1: the shade map; S158 35: the breeding hints)
; FX1 (S71): wPoolBounce — 128-byte staging for sleep-pool bank-2 record
; swaps (per-byte scratch in CF3PoolSwapRecord). Transient. (The v1 drain's
; halved-pending scratch use was removed with the S71v2 exp-scale veto.)
wPoolBounce:: ds 128 ;d5e5-d664 (end = vanilla array end $D664)

; Staging pseudo-slots $14/$15 ($D665/$D6FA, $95 B each) — LIVE vanilla:
; breeding parents, trade transit, menu scratch (S56; GetMonsterDataPtr
; masks and $7F, so these are addressable array indices). NOT freed by CF3.
    ds $12A ;d665-d78e
    ds 2 ;d78f-d790

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

    ds 8                            ; d9cf-d9d6 (poisoned bytes — see EVENT_FLAGS)

; [ANCHOR S73] Persistent anchor state (custom skill $E4 "Anchor").
; $D9D7-$D9D8 are the OTHER safe pair from the S57 per-byte audit (flag
; indices $01E0-$01EF, zero engine literals, zero script refs) — appropriated
; following the CF2/wPendingFarmExp precedent; flags $01E0-$01EF are RETIRED
; from the allocator pool in exchange (EVENT_FLAGS.md; editor2/core/project.py
; FLAG_SAFE_RANGES). Inside the $C8EA-$D9E9 save image -> persists through
; save+reload; boot/new-game zeroed. VALIDITY = wAnchorFloor != 0 (floors are
; 1-based; gate 0 is a legal anchor target, so the gate byte can't be the
; sentinel). Pre-anchor saves load floor 0 = "no anchor" (clean migration).
wAnchorGate:: db ;d9d7 — anchored gate id (0-31); meaningful only if floor != 0
wAnchorFloor:: db ;d9d8 — anchored floor (1-based); 0 = no anchor set

    ds $1B                          ; d9d9-d9f3 (poisoned bytes — see EVENT_FLAGS)

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
wBattlePostFlag:: db ;db55 — battle OUTCOME: 0=win, 1=loss, 2=neutral/undecided — FLEE ends at 2 (no exp/join, no loss penalty; HW-pinned S68), caught monster = win 0. Briefly reused as the 1/32 random intro-event marker at battle phase 2. Set by bank $52 KO scans; "0 for bosses" was a win-path observation

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
wBattleLVL:: ds 16 ;dc23 — [S87] MISNOMER: per-combatant WLD (wildness) word, from record slot+$60; enemies forced $00FF. The obedience gate's level term (bank $57 $7a03/$7a5d). Display level lives in $db9b.

    ds ($DE74 - ($DC23 + 16))       ; gap ($DC33-$DE73): battle vars, AI score
                                    ; table $DCE4, action queue $DCEC, AUDIO
                                    ; channel state $DD80-$DE2B (6 x 26 B +
                                    ; scalars to $DE2B — S55 correction: NOT
                                    ; battle structs). $DE2C-$DE73 = margin.

; =============================================================================
; Custom-room dispatch scratch block ($DE74-$DE8A).
; History: S55 relocated ALL custom room state here (out of the monster
; array — the S53/S54 egg-give corruption); S65 migrated the step-counter
; REGION onward into the CF3-freed window ($CD80, see the $CC80 banner)
; because the reserve here caps at ~106 B, far short of campaign scale.
; The scratch vars below STAY: their addresses are label-resolved by engine
; patches in banks $00/$0B/$71 and there is no scaling pressure on them.
; $DE74-$DEDD vetted S55: full-corpus scan shows zero real claimants above the
; audio engine's $DE2B ceiling (every $DE30-$DEFF literal is data-as-code junk
; from gfx/audio data banks); SVBK bank-2 windows (banks $51/$52) touch $DB00+
; only; stack ($DFFF down) is fenced by vanilla's own $DF00-$DF0D vars.
; Evidence: tools/audit_wram.py / extracted/wram_usage.json.
; NOT in the SRAM save range ($C8EA-$D9E9) — TRANSIENT by design
; (user decision S55): persistent room state = event flags + entry scripts.
; INITIALIZATION (S55 crash post-mortem — vetted-unclaimed is NOT initialized):
; this block is outside both the boot clear's vanilla span and the save image:
;  * ClearAllWRAM count $1E00->$1EE0 (patches/bank_000.asm) — boot zeroes
;    $C000-$DEDF, covering this block + reserve. STILL REQUIRED post-S65
;    (scratch/Tame/flag/mailbox live here even though the counters left).
;  * wCustomRoomFlag is DERIVED (:= wMapID >= CUSTOM_ROOM_START) every
;    movement frame at CopyCustomRoomRecord head (bank $71 template) — it can
;    never be restored from a save again, so it is never trusted as state.
; Reserve after the block: $DE8B-$DEDD (83 B) free for future scratch
; ($DE89-$DE8A carved S60 for the CF3 copy-husk mailbox, defined at EOF).
; =============================================================================
wCustomY7Cmp:: db ;de74 — Entry 6 scan-loop y-skip compare value (S70v3).
         ; Written by bank $60 entry 7 fresh before EVERY exit scan:
         ; $07 on the vanilla branch (y=7 rows skipped, original engine
         ; semantics), $FE on the CustomExitCheck branch (never matches a
         ; real trigger_y, so custom-room y=7 rows become walk-on exits).
         ; Boot-zeroed by the $1EE0 clear; $00 is harmless (y=0 rows are
         ; already skipped by the preceding `or a` check).
    ds 6 ;de75-de7a — legacy pad remainder (step counters migrated to the
         ; $CD80 region, S65); keeps wRoomRecScratch pinned at $DE7B

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

; CF3 (S60): 2-byte pointer mailbox for the CopySRAMBlock/CopyFromSRAM ROM0
; husks — rst $10 consumes HL, so the husk stashes its HL argument here for
; the bank $73 copy callees (entries 5/6). Written/read only inside those
; calls (the save cluster runs with interrupts quiesced; nothing else
; touches it between store and use). Carved from the $DE89-$DEDD reserve —
; counter-region growth now starts at $DE8B (83 B left).
wCF3CopyMbxLo:: db ;de89
wCF3CopyMbxHi:: db ;de8a

; E3 (S69): parameter block for CF3SRAMBankedCopy (bank $73 entry 9) — the
; ONLY sanctioned path to SRAM banks 1-3 under the 32 KB expansion (RAMB is
; pinned 0 everywhere else; see ARCHITECTURE "SRAM banking as built S69").
; Written by the caller immediately before `ld hl,$7309 / rst $10`; transient
; (outside the save image), boot-zeroed by ClearAllWRAM. Carved from the
; $DE8B-$DEDD reserve — 76 B left, growth starts $DE92.
wSRAMXferBank:: db ;de8b — target RAMB 0-3 (bank of the SRAM side)
wSRAMXferSrc::  dw ;de8c — source address (LE)
wSRAMXferDst::  dw ;de8e — destination address (LE)
wSRAMXferLen::  dw ;de90 — byte count (LE, >=1; $0000 = no-op)

; S69v2: 32-byte bounce buffer for CF3SnapXfer (roster snapshot, bank $73) —
; SRAM banks can't see each other, so bank0<->bank1 chunks stage here.
; Transient; live only inside the save/load funnels. Reserve now 42 B,
; growth starts $DEB2.
wSnapBounce:: ds 32 ;de92-deb1

; [ANCHOR S73] Transient anchor plumbing (outside the save image by design:
; cast->arrival is one uninterruptible transition, nothing here must survive
; a save). Boot-zeroed by the $1EE0 ClearAllWRAM extension.
; wAnchorArm protocol: 0 idle; 1 = gate-side YES (commit hook stores
; gate+floor from live wGateID/wCurrentFloor, then 0); 2 = town-side YES
; (commit hook installs wGateID/wCurrentFloor-1, deducts 3/4 of the caster's
; current MP, clears the stored anchor, then sets 3); 3 = consumed by
; GateDecisionFork inside entry-5 to FORCE the standard-maze path (then 0).
; Reserve now 40 B, growth starts $DEB4.
wAnchorArm:: db ;deb2 — see protocol above (written by script write_ram + ASM)
wAnchorCaster:: db ;deb3 — caster party slot (0-2), captured at cast time
; [QUAKE] Earthquake ($E5-$E8) battle-sweep state. Reset per cast by
; AnnounceIdxFork (bank $58) and on sweep finish (QuakeSweep72).
wQuakePhase:: db ;deb4 — 0 idle / 1 first-side sweep ran (shake+SFX fired) /
                ;        2 crossed to the caster's own side (allies)
wQuakeAllyMsg:: db ;deb5 — 1 = "seismic wave" ally message pending (rendered by
                ;   the widened TameGateHook via the $FD escape, then cleared)
wQuakeCaster:: db ;deb6 — TRUE caster slot, captured at the first handler run
                ;   ($db88 is REWRITTEN to the current target mid-sweep by the
                ;   per-target redirect $53:CallBtlC_5e38 — measured S74 — so
                ;   every later caster/side test must use this instead)
wQuakeBursts:: db ;deb7 — remaining shake bursts (tier count 1..4 at cast; the
                ;   step-2 tick QuakeStepTick72 consumes them: burst/gap/burst)
wQuakePause:: db ;deb8 — inter-burst gap countdown; $FF = terminal (stopper SE
                ;   already queued). Only read while the shake train is armed.
wQuakeArmed:: db ;deb9 — 1 while the cast-anim-slot shake train is running
                ;   (armed by QuakeAnimHold72 on entering d9ee==3; cleared when
                ;   the train completes and the anim slot is released; also
                ;   hard-cleared by the handler's phase-0 init).
; [MOURN S75] Mourn ($E9) battle state. Reset per cast by the handler.
wMournBoosted:: db ;deba — 1 if dead allies were found (triggers the boost
                ;   banner "The fallen lend power!" via MournGate_delay in
                ;   bank $53; cleared after render). 0 = no dead allies.
wMournSlashes:: db ;debb — double-slash replay counter (starts at 2; decremented
                ;   by QuakeAnimHold72's .mourn path each time $da82→1;
                ;   release at 0). Transient to the cast-anim slot.
; [S100] Gate dive state for once-per-dive custom gate rooms (bank $71 entry 4
; CustomGateInsert, ROADMAP P3.7b). Outside the WRAM save image, so it rides
; the explicit save through SRAM $BFCA/$BFCB (bank $73 entries 5/6, the
; main-image detectors) — a save made in a special room mid-dive keeps which
; once-per-dive rooms were already served. Boot-zeroed by ClearAllWRAM.
; Reserve now 32 B, growth starts $DEBE.
wGateDiveGate:: db ;debc — wGateID+1 of the dive in progress (0 = none)
wGateDiveMask:: db ;debd — once-per-dive rule bits served this dive (per gate, max 8)
; [S155] the S155 custom skills (BATTLE_SKILL_SYSTEM §13.10). Transient (outside the
; save image), boot-zeroed by ClearAllWRAM. Reserve now 18 B, growth starts $DECC (S155 r5); S156 wSteal: 12 B, $DED2.
wCustomJump:: dw ;debe — the bank-$52 address the dispatcher jumps to for an S155
                ;   battle skill (FarSkillFork returns HL = this cell; RST_08 reads it)
wCustomLine:: db ;dec0 — the extra battle line pending (bank $4C CustomLinePtrs,
                ;   1-based; 0 = none): the hit message $FD renders it, then clears it
wCustomLineSkill:: db ;dec1 — the skill id that set wCustomLine (a $FD of any other
                ;   skill ignores + clears it); also cleared in every action's cast slot
wRepelArmed:: db ;dec2 — 1 = Repel set $C93E bit 1 OUTSIDE a gate floor: the bank $73
                ;   commit clears both when the party arrives in another place
wRepelPlace:: ds 2 ;dec3 — the place Repel was cast in (wMapRegion, wMapID)
wCustomTmp:: ds 4 ;dec5 — MulPct72 scratch (bank $72)
wLineShown:: db ;dec9 — [S155 r2] 1 = this action's bonus line was decided in its
                ;   announce slot (bank $72 LineSlot72; cleared outside the slot)
wQuakeHitLate:: db ;deca — [S155 r2] 1 = the Quake crossover's ally hit has its damage
                ;   sound + hit reaction held for the banner (bank $53 QuakeLateFire53)
wBlunted:: db ;decb — [S155 r5] bit s = battle slot s is BLUNTED (its ATK lowered by
                ;   Blunt; Blunt does not stack: another one fails, the AI skips it).
                ;   Zeroed by bank $50 BattleInit; cleared per slot when DeMagic /
                ;   Surge give the ATK back (bank $53 RestoreATK53).
; [S156] Plunder (BATTLE_SKILL_SYSTEM §13.11). Transient, boot-zeroed. 12 B left, $DED2 (S157: 9 B, $DED5).
wSteal:: ds 6 ;decc — bank $72 SkillPlunder / ScoreSteal72: +0 the caster, +1 the target
                ;   (the slot tested), +2 1 = only the buffs the caster lacks, +3 the
                ;   pick (counts down), +4 the StealTable row, +5 its name's skill id

; [S157] ONE-ONLY items (ROADMAP E9; DATA_STRUCTURES "One-only items (S157)", bank $77
; entries 19-22). Transient, boot-zeroed. 9 B left, growth starts $DED5.
wOneOnlyItem:: db ;ded2 — the item a script give op ($2A / $37 / $54 / $57 / $5D, bank $04)
                ;   hands bank $77 entry 19 GiveOne
wOneOnlyRes:: db ;ded3 — GiveOne's result: 1 = done (given, or a one-only item already
                ;   held), 0 = the bag is full (op $5D waits, as the game did)
wOneOnlySay:: db ;ded4 — 1 = the next SHOWN text is the "already has one" line (set by
                ;   bank $77 entry 20 BagFullCheck, consumed by bank $60 TextOverride ->
                ;   bank $77 entry 22 OneOnlySay; cleared at every op $2C)
