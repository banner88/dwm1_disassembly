; =============================================================================
; BANK $01 — GAME LOOP, ENCOUNTERS, TEXT DISPATCH, GATE DATA
; =============================================================================
; Contains:
;   - Game initialization and main field loop (entries 0-1)
;   - Random encounter monster selection (entry 11 at $683E)
;   - Load next dungeon floor (entry 13 at $69E1)
;   - Per-room VRAM update dispatch ($60E7, table at $6119)
;     NOTE: The $6119 table was previously identified as "NPC text dispatch"
;     but it actually handles VISUAL EFFECTS (palette animation, tile swaps).
;     The actual NPC dialogue mechanism is UNKNOWN — needs SameBoy tracing.
;   - Gate encounter pool data ($6A22, $6A42, $6AAE)
;
; KEY DISCOVERY: The dispatch table at $6119 does NOT handle NPC dialogue.
; It runs per-room visual updates. Rooms with RET handlers have no visual
; effects, NOT "no text." NPC text dispatch is a separate, undocumented system.
;
; Sources: Mallos31/dwm disassembly, NiyaDev/DWM, user reverse-engineering
; =============================================================================

; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $001", ROMX[$4000], BANK[$1]

    db $01

    ; Bank $01 jump table (14 entries, called via rst $10 with H=$01)
    dw GameInit
    ; Entry 0: Game initialization
    dw MainFieldLoop
    ; Entry 1: Main game loop / field update
    dw ClearAnimationState
    ; Entry 2
    dw SetupPartyBattleData
    ; Entry 3: Battle encounter data setup
    dw label1_4845
    ; Entry 4: Pre-battle preparation
    dw ReadPartySlotInfo
    ; Entry 5
    dw ScanPartySlotTable
    ; Entry 6
    dw GetMonsterSkillDataPtr
    ; Entry 7
    dw CheckFieldMovementAllowed
    ; Entry 8
    dw IteratePartySlots20
    ; Entry 9
    dw CheckNPCInteraction
    ; Entry 10: Unknown — possibly NPC text?
    dw label1_683e
    ; Entry 11: Random encounter monster selection ($683E)
    dw LoadFloorAndEncounterData
    ; Entry 12: the pool's maze size -> $C93D (floor setup, bank $16 entry 5)
    dw LoadNextDungeonFloor
    ; Entry 13: gate + floor -> the encounter pool + its rate code ($69E1; every
    ;   encounter step; S114 patched: the bank $76 EncResolve fork)

GameInit:
    ld hl, sp+$00
    ld a, l
    ld [$da7b], a
    ld a, h
    ld [$da7c], a
    xor a
    ld hl, $c827
    ld bc, $0012
    call FillNBytesWithRegA
    call InitAudioSystem
    xor a
    ld [wCurrPlayingBGM], a
    xor a
    ld [$c88f], a
    call SaveMapStateToHRAM
    call SetColorMode
    call LoadMapMetadata
    ld hl, $8b00
    ld de, $1202
    call SetupVRAMCopy
    ld a, $fc
    call SetGBCPalette
    call InitFieldState
    ld a, $07
    ldh [$b5], a
    ld a, $ff
    ldh [$b6], a
    ld a, $7f
    ldh [rLYC], a
    ld a, $63
    ld [$c8a1], a
    ld a, $01
    ld [$c892], a
    call EnableLYCInterrupt
    ld a, $03
    jp EnableLCDAndInterrupts


InitFieldState:
    call ClearAnimationState
    call CheckScreenLock
    call LoadFieldTilesDMA
    ld hl, $1702
    rst $10
    ld a, [$c8ab]
    or a
    call nz, ClearFieldAnimFlag
    call ReadPartySlotInfo
    call SetupPartyBattleData
    ld hl, $0b02
    rst $10
    ld hl, $0b07
    rst $10
    call CheckBattleModeFlag
    ld a, [$c8a6]
    push af
    xor a
    ld [$c8a6], a
    ld hl, $0603
    rst $10
    pop af
    ld [$c8a6], a
    ld hl, $d7b6
    ld a, l
    ld [$d7b4], a
    ld a, h
    ld [$d7b5], a
    xor a
    ld [$d7ba], a
    ld [$d7bb], a
    ld [$d7b6], a
    ldh a, [$8a]
    ld [$d7b7], a
    ldh a, [$8f]
    add $00
    ld [$d7b8], a
    ld hl, $0200
    rst $10
    ld a, [$d7ba]
    ldh [$8b], a
    ldh a, [$92]
    ldh [$a5], a
    ldh a, [$93]
    ldh [$a6], a
    ldh a, [$95]
    ldh [$a7], a
    ldh a, [$96]
    ldh [$a8], a
    call TileAtPixel
    ld a, [wMapID]
    ld [$c96a], a
    ld a, [wInGateworld]
    ld [$c96b], a
    ld a, [wInGateworld]
    or a
    jr nz, jr_001_4105

    ld a, [wMapID]
    cp MAP_CSLBG
    jr nz, jr_001_4105

    ld hl, $5605
    rst $10
    jr jr_001_410b

jr_001_4105:
    call UpdateOAMSprites
    call GetBGMapAddress

jr_001_410b:
    ld a, $01
    ld [$c8ea], a
    xor a
    ld [$c8a8], a
    xor a
    ld [wIsPlayerChangingMaps], a
    xor a
    ld [$c740], a
    ld [$c741], a
    ld a, $ff
    ld [$c742], a
    ldh a, [$b7]
    ldh [$b9], a
    ldh a, [$b8]
    ldh [$ba], a
    ldh a, [$bb]
    ldh [$bd], a
    ldh a, [$bc]
    ldh [$be], a
    ld hl, $010a
    rst $10
    ret


Jump_001_4139:
    ld a, [$c88f]
    cp $02
    jp z, Jump_001_41dc

    ld a, [$c850]
    or a
    ret nz

    call SaveMapStateToHRAM
    ld b, a
    ld a, [$c81b]
    cp b
    jr z, jr_001_4155

    ld hl, $c88e
    inc [hl]
    ret


jr_001_4155:
    xor a
    ldh [rBGP], a
    ldh [rOBP0], a
    ldh [rOBP1], a
    ld hl, $9800
    ld b, $00

jr_001_4161:
    ld a, $e0
    call Write_gfx_tile_and_inc_HL
    call Write_gfx_tile_and_inc_HL
    call Write_gfx_tile_and_inc_HL
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_001_4161

    call InitFieldState
    call ApplyScrollRegisters
    ld a, [$c817]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ld a, l
    ld [$c85b], a
    ld a, h
    ld [$c85c], a
    inc hl
    ld a, l
    ld [$c85d], a
    ld a, h
    ld [$c85e], a
    inc hl
    ld a, l
    ld [$c85f], a
    ld a, h
    ld [$c860], a
    inc hl
    ld a, l
    ld [$c861], a
    ld a, h
    ld [$c862], a
    ld a, $b1
    ld [$c777], a
    ld a, [$c818]
    ld [$c778], a
    ld a, $ff
    ld [$c774], a
    ld hl, $0800
    rst $10
    call DisableSRAM
    ld hl, $0802
    rst $10
    xor a
    ld [$c842], a
    ld [$c843], a
    xor a
    ld [wJoypad_current_frame], a
    ld [wJoypad_Current], a
    xor a
    ld [$c848], a
    ld [$c849], a
    call ProcessFieldInput
    ld a, $02
    ld [$c88f], a
    ret


Jump_001_41dc:
    xor a
    ld [$c842], a
    ld [$c843], a
    xor a
    ld [wJoypad_current_frame], a
    ld [wJoypad_Current], a
    xor a
    ld [$c848], a
    ld [$c849], a
    call ProcessFieldInput
    xor a
    ld [$c88f], a
    ld hl, wBGPalette
    ld a, $d2
    ld [hl+], a
    ld a, $d2
    ld [hl+], a
    ld a, $e2
    ld [hl], a
    ld hl, $c89e
    ld a, [wBGPalette]
    ld [hl+], a
    ld a, [wObj1Palette]
    ld [hl+], a
    ld a, [wObj2Palette]
    ld [hl], a
    call CachePalettesToHRAM
    ld a, $fd
    call SetGBCPalette
    ret


ClearAnimationState:
    xor a
    ld [$c8aa], a
    xor a
    ldh [$d3], a
    ld a, $80
    ldh [$d4], a
    xor a
    ld [$c915], a
    ld [$c916], a
    ld a, [$c8ea]
    or a
    ret nz

    xor a
    ld [$c93e], a
    xor a
    ld [wMonsterInfoToggle], a
    xor a
    ld [$c8ec], a
    xor a
    ld [wGameState], a
    xor a
    ld [wScriptStateFlags], a
    ld [$d8d8], a
    ld a, $04
    ld [wTextSpeed], a
    ld hl, $0064
    ld a, l
    ld [$ca3b], a
    ld a, h
    ld [$ca3c], a
    ld hl, $0014
    ld a, l
    ld [$ca3d], a
    ld a, h
    ld [$ca3e], a
    ld hl, $d92a
    ld bc, $00c0
    ld a, $00
    call FillNBytesWithRegA
    ld a, [wInGateworld]
    or a
    jr nz, jr_001_427d

    ld a, [wMapID]
    cp MAP_NEST
    jr z, jr_001_4291

jr_001_427d:
    ld a, $d3
    ld [$ca42], a
    ld a, $d4
    ld [$ca43], a
    ld a, $d5
    ld [$ca44], a
    ld a, $d6
    ld [$ca45], a

jr_001_4291:
    ld a, [wRNG1]
    ld [$ca4a], a
    ld a, [$c8ab]
    or a
    ret nz

    ld a, $00
    ld [$ca8d], a
    ld a, $ff
    ld [$ca8e], a
    ld a, $ff
    ld [$ca8f], a
    ld a, $ff
    ld [$ca90], a
    ld a, $00
    ld [wCurrGoldLo], a
    ld a, $00
    ld [wCurrGoldMid], a
    ld a, $00
    ld [wCurrGoldHi], a
    ld hl, wInventory
    ld bc, $0014
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, wBankSlots
    ld bc, $0028
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $cac1
    ld b, $14
    ld de, $0095

jr_001_42dd:
    ld [hl], $00
    add hl, de
    dec b
    jr nz, jr_001_42dd

    ret


CheckScreenLock:
    ld a, [$c88e]
    or a
    jr nz, jr_001_42f6

    ld a, [$c88f]
    or a
    jr z, jr_001_42f6

    ld a, [$d9e9]
    ld [$d988], a

jr_001_42f6:
    xor a
    ld [$d9e9], a
    ld hl, $0b00
    rst $10
    ld a, [wCurrPlayingBGM]
    ld b, a
    push bc
    call LoadNewBGMIdIntoA
    pop bc
    cp b
    call nz, SetBGM
    ld a, [$c88f]
    or a
    ret nz

    ld de, $2e00
    ld hl, $8d00
    call WaitLCDTransfer
    ret


LoadMapMetadata:
    ld hl, $2add
    ld a, [hl]
    ld [$c817], a
    ld hl, $2ade
    ld a, [hl]
    ld [$c818], a
    ld hl, $0801
    rst $10
    ret


; --- S64 M3b: room-default music override (same-size rewrite, 70-byte
; footprint $432D-$4372 preserved; RoomBGMTable stays fixed at $4373).
; The override dispatch (7 B) is funded by: dropping the redundant second
; `ld a, [wMapID]` (A still holds wMapID through the compare chain, -3 B),
; the `adc h / sub l` hi-byte idiom at both table lookups (-2 B), and the
; vestigial `ld b,[hl] / ld a,b / cp $09 / ret nz / ret` tail -> `ld a,[hl] /
; ret` (-4 B; the caller overwrites those flags with its own `cp b` before
; acting, single call site, so behavior is identical). Net -9, +7, 2 pad.
; rst $10 clobbers A on return (bank-restore pop af) but preserves DE, so the
; resolver hands the id back in E; 0 = no assignment -> vanilla logic intact.
LoadNewBGMIdIntoA:
    ld hl, $7102                     ; bank $71 entry 2: CustomRoomBGMResolve
    rst $10                          ; -> E = assigned BGM id, or 0
    ld a, e
    or a
    ret nz                           ; assigned id wins (any mapID $00-$7F)

    ld a, [wInGateworld]
    or a
    jr nz, jr_001_4358

    ld a, [wMapID]
    cp MAP_ITEMSP
    jr c, jr_001_4346

    cp MAP_COLISUM
    jr z, jr_001_4346

    cp MAP_BTLDEMO
    jr c, jr_001_4358

    cp $61 ;mapIDs $5D-$60 use the table; >= $61 falls to the gate path
    jr nc, jr_001_4358

jr_001_4346:
    ; A = wMapID here on ALL entry paths (cp does not modify A)
    ld hl, RoomBGMTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl]
    ret


jr_001_4358:                      ; gate floors + every unassigned mapID >= $61
    ld a, [wCurrentFloor]         ;   (all custom rooms): $34, the gate theme —
    ld b, a                       ;   EXCEPT when wCurrentFloor == wLastFloor-2,
    ld a, [wLastFloor]            ;   i.e. the floor BEFORE the boss floor (floor
    sub $02                       ;   N-1 of N, 1-based), which already plays the
    cp b                          ;   boss room's RoomBGMTable entry; the boss
    ld a, $34                     ;   floor keeps it (PyBoy S100, Bazaar Gate:
    ret nz                        ;   floors 7 $34, 8 $0C, 9 $0C)

    ld hl, RoomBGMTable
    ld a, [wBossMapType]
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl]
    ret

    rst $38                          ; 2-byte pad: rewrite is 68 B, footprint 70
    rst $38


; Per-map default BGM table, 1 byte per mapID, $70 entries ($4373-$43E2).
; (Re-sectioned S64; see disassembly/bank_001.asm for the vanilla notes.)
; PATCHED TREE NOTE: LoadNewBGMIdIntoA above is rewritten same-size (S64) to
; consult bank $71 entry 2 (CustomRoomBGMResolve) FIRST — a nonzero resolver
; result overrides this table AND the gate path for any mapID $00-$7F, which
; is what makes assigned room music survive save/reload (the load path calls
; the same derivation). Resolver returns 0 -> vanilla logic below unchanged.
RoomBGMTable:
    db $09, $09, $09, $09, $09, $09, $1E, $1E, $31, $31, $09, $09, $09, $09, $09, $09 ; mapIDs $00-$0F
    db $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $1E, $1E, $09 ; mapIDs $10-$1F
    db $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $9D ; mapIDs $20-$2F
    db $34, $0C, $0C, $18, $15, $0C, $2E, $18, $0F, $18, $12, $2E, $1B, $12, $1B, $1B ; mapIDs $30-$3F
    db $1B, $1B, $1B, $1B, $12, $1B, $0C, $0F, $12, $12, $15, $15, $18, $1B, $1B, $1B ; mapIDs $40-$4F
    db $34, $34, $61, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $61, $02, $02 ; mapIDs $50-$5F
    db $1B, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34 ; mapIDs $60-$6F

SaveMapStateToHRAM:
    ld a, [wMapID]
    ldh [$d5], a
    ld a, [wInGateworld]
    ldh [$d6], a
    ld a, [wIsPlayerChangingMaps]
    or a
    jr z, jr_001_43fd

    ld a, [wWarpGateId]
    ldh [$d5], a
    ld a, [wWarpFlag]
    ldh [$d6], a

jr_001_43fd:
    ldh a, [$d6]
    or a
    jr z, jr_001_4405

    ld a, $00
    ret


jr_001_4405:
    ; S128 (ROADMAP P3.14e3): same-size rewrite of the destination class
    ; (36 B, $4405-$4428): the destination map id goes through ROM0 ArenaAlias
    ; ONCE (a project's arena copies read as $06 / $5D) instead of being
    ; re-read from $FFD5 three times. Class: $5E -> the current one, $5D (the
    ; Arena Battle room) 1, $2F (the intro bedroom) 2, < $30 (towns) 3, else 0
    ; (gates, special rooms, custom rooms). The class picks the Super Game Boy
    ; border / colour mode (SetColorMode, $C81B); a change of class takes the
    ; full re-init path (Jump_001_4139). F on return: undefined (callers read A).
    ldh a, [$d5]
    call ArenaAlias
    cp $5e
    jr z, jr_001_4425
    cp $5d
    jr nz, .notArena
    ld a, $01
    ret
.notArena:
    cp $2f
    jr nz, .notBedroom
    ld a, $02
    ret
.notBedroom:
    cp $30
    ld a, $03
    ret c
    xor a
    ret
    nop
    nop
jr_001_4425:
    ld a, [$c81b]
    ret


; LoadFieldTilesDMA (S121 trace): the field's two sprite sheets -> VRAM — gfx-ID
; $2F00 = the PLAYER's sheet (Terry, 20 tiles) at $8000 (tile base $00 of the
; player shape), $2E1D at $8180. The NPC sheets are ROM0 $2ADF[sprite id] (16 tiles).
LoadFieldTilesDMA:
; S121 (the Milly hook): the player's sheet -> VRAM $8000 (gfx-ID $2F00 = Terry);
; region milly_player_sheet = these 9 bytes, or a same-size call into bank $79
; entry 1 (MillyPlayerSheet: Milly's NPC sheet once flag $179F is set).
; @BUILD_PROJECT BEGIN milly_player_sheet
    ld de, $2f00
    ld hl, $8000
    call WaitDMATransfer
; @BUILD_PROJECT END milly_player_sheet
    ld de, $2e1d
    ld hl, $8180
    call WaitDMATransfer
    xor a
    ldh [$a1], a
    ldh [$a2], a
    ldh [$a3], a
    ldh [$a4], a
    ldh [$91], a
    ldh [$94], a
    ld a, [wIsPlayerChangingMaps]
    or a
    jr z, jr_001_4464

    ld a, [wWarpSpawnXLo]
    ldh [$92], a
    ld a, [wWarpSpawnXHi]
    ldh [$93], a
    ld a, [wWarpSpawnYLo]
    ldh [$95], a
    ld a, [wWarpSpawnYHi]
    ldh [$96], a
    jr jr_001_4498

jr_001_4464:
    ld a, [$c8ea]
    or a
    jp nz, Jump_001_44ba

    ld hl, $ff8a
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ldh [$8f], a
    ldh [$8e], a
    ldh [$90], a
    ld [$d7bd], a
    call MapIDClampForPalette       ; ROM0: A=mapID or $16 for custom rooms
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ld a, l
    add LOW(NPCWalkDataTable)
    ld l, a
    ld a, h
    adc HIGH(NPCWalkDataTable)
    ld h, a
    ld a, [hl+]
    ldh [$92], a
    ld a, [hl+]
    ldh [$93], a
    ld a, [hl+]
    ldh [$95], a
    ld a, [hl]
    ldh [$96], a

jr_001_4498:
    ld b, $31
    ld hl, $c973

jr_001_449d:
    ldh a, [$92]
    ld [hl+], a
    ldh a, [$95]
    ld [hl+], a
    ldh a, [$93]
    swap a
    ld c, a
    ldh a, [$96]
    or c
    ld [hl+], a
    ldh a, [$8b]
    ld c, a
    ldh a, [$8d]
    or c
    ld [hl+], a
    dec b
    jr nz, jr_001_449d

    xor a
    ld [$ca37], a

Jump_001_44ba:
    ldh a, [$92]
    ldh [$a5], a
    ldh a, [$93]
    ldh [$a6], a
    ldh a, [$95]
    ldh [$a7], a
    ldh a, [$96]
    ldh [$a8], a
    call TileAtPixel
    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    swap h
    swap l
    ld a, h
    and $f0
    ld h, a
    ld a, l
    and $0f
    or h
    ldh [$97], a
    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    swap h
    swap l
    ld a, h
    and $f0
    ld h, a
    ld a, l
    and $0f
    or h
    ldh [$98], a
    ldh a, [$92]
    ldh [$99], a
    ldh a, [$93]
    ldh [$9a], a
    ldh a, [$95]
    ldh [$9b], a
    ldh a, [$96]
    ldh [$9c], a
    ret


; S66 A'1 NOTE: auto-label is MISLEADING — this is the DEFAULT PLAYER SPAWN
; table (4 bytes/map: X lo/hi, Y lo/hi -> hram $92/$93/$95/$96), used on the
; non-warp room-init path (jr_001_4464) when wIsPlayerChangingMaps = 0.
; Indexed by RAW mapID x4 (16-bit math). 107 vanilla entries: custom rooms
; ($6B+) read past the end — pre-existing, empirically benign on every proven
; path (v7 save-in-room -> reload OK: position comes from the save image, not
; this table). Crossing mapID $7F changes nothing here. If the editor ever
; relies on non-warp default spawns in custom rooms, emit a custom table
; instead. (Bytes below are table data mis-decoded as instructions.)
NPCWalkDataTable:
    ld hl, sp+$00
    ret c

    nop
    add sp, $00
    cp b
    nop
    ld c, b
    nop
    jr c, jr_001_4512

jr_001_4512:
    add sp, $00
    ret z

    nop
    add sp, $00
    xor b
    nop
    ld c, b
    nop
    jr c, jr_001_451e

jr_001_451e:
    add sp, $00
    jr c, jr_001_4522

jr_001_4522:
    add sp, $00
    jr c, jr_001_4526

jr_001_4526:
    ld c, b
    nop
    jr c, jr_001_452a

jr_001_452a:
    add sp, $00
    ld c, b
    nop
    ld c, b
    nop
    jr c, jr_001_4532

jr_001_4532:
    ld c, b
    nop
    jr c, jr_001_4536

jr_001_4536:
    ld c, b
    nop
    ld c, b
    nop
    ld c, b
    nop
    jr c, jr_001_453e

jr_001_453e:
    ld c, b
    nop
    jr c, jr_001_4542

jr_001_4542:
    ld c, b
    nop
    jr c, jr_001_4546

jr_001_4546:
    ld c, b
    nop
    jr c, jr_001_454a

jr_001_454a:
    ld c, b
    nop
    jr c, jr_001_454e

jr_001_454e:
    ld c, b
    nop
    jr c, jr_001_4552

jr_001_4552:
    ld c, b
    nop
    jr c, jr_001_4556

jr_001_4556:
    ld c, b
    nop
    jr c, jr_001_455a

jr_001_455a:
    ld c, b
    nop
    jr c, jr_001_455e

jr_001_455e:
    jr c, jr_001_4560

jr_001_4560:
    jr c, jr_001_4562

jr_001_4562:
    ld c, b
    nop
    jr c, jr_001_4566

jr_001_4566:
    ld c, b
    nop
    jr c, jr_001_456a

jr_001_456a:
    ld c, b
    nop
    ld e, b
    nop
    ld e, b
    nop
    ld l, b
    nop
    ld c, b
    nop
    jr c, jr_001_4576

jr_001_4576:
    ld c, b
    nop
    jr c, jr_001_457a

jr_001_457a:
    ld c, b
    nop
    jr c, jr_001_457e

jr_001_457e:
    ld c, b
    nop
    jr c, jr_001_4582

jr_001_4582:
    ld c, b
    nop
    jr c, jr_001_4586

jr_001_4586:
    ld c, b
    nop
    jr c, jr_001_458a

jr_001_458a:
    ld c, b
    nop
    jr c, jr_001_458e

jr_001_458e:
    ld c, b
    nop
    jr c, jr_001_4592

jr_001_4592:
    ld c, b
    nop
    jr c, jr_001_4596

jr_001_4596:
    ld c, b
    nop
    jr c, jr_001_459a

jr_001_459a:
    ld c, b
    nop
    jr c, jr_001_459e

jr_001_459e:
    ld c, b
    nop
    jr c, jr_001_45a2

jr_001_45a2:
    ld c, b
    nop
    jr c, jr_001_45a6

jr_001_45a6:
    ld c, b
    nop
    jr c, jr_001_45aa

jr_001_45aa:
    ld c, b
    nop
    jr c, jr_001_45ae

jr_001_45ae:
    ld c, b
    nop
    jr c, jr_001_45b2

jr_001_45b2:
    ld c, b
    nop
    jr c, jr_001_45b6

jr_001_45b6:
    ld c, b
    nop
    jr c, jr_001_45ba

jr_001_45ba:
    ld c, b
    nop
    jr c, jr_001_45be

jr_001_45be:
    ld c, b
    nop
    jr c, jr_001_45c2

jr_001_45c2:
    ld c, b
    nop
    cp b
    nop
    ld c, b
    nop
    jr c, jr_001_45ca

jr_001_45ca:
    ld c, b
    nop
    jr c, jr_001_45ce

jr_001_45ce:
    ld c, b
    nop
    jr c, jr_001_45d2

jr_001_45d2:
    ld c, b
    nop
    jr c, jr_001_45d6

jr_001_45d6:
    ld c, b
    nop
    jr c, jr_001_45da

jr_001_45da:
    ld c, b
    nop
    jr c, jr_001_45de

jr_001_45de:
    ld c, b
    nop
    jr c, jr_001_45e2

jr_001_45e2:
    ld c, b
    nop
    jr c, jr_001_45e6

jr_001_45e6:
    ld c, b
    nop
    jr c, jr_001_45ea

jr_001_45ea:
    ld c, b
    nop
    jr c, jr_001_45ee

jr_001_45ee:
    ld c, b
    nop
    jr c, jr_001_45f2

jr_001_45f2:
    ld c, b
    nop
    jr c, jr_001_45f6

jr_001_45f6:
    ld c, b
    nop
    jr c, jr_001_45fa

jr_001_45fa:
    ld c, b
    nop
    ld a, b
    nop
    ld c, b
    nop
    jr c, jr_001_4602

jr_001_4602:
    ld c, b
    nop
    jr c, jr_001_4606

jr_001_4606:
    ld c, b
    nop
    jr c, jr_001_460a

jr_001_460a:
    ld c, b
    nop
    jr c, jr_001_460e

jr_001_460e:
    ld c, b
    nop
    jr c, jr_001_4612

jr_001_4612:
    ld c, b
    nop
    jr c, jr_001_4616

jr_001_4616:
    ld c, b
    nop
    jr c, jr_001_461a

jr_001_461a:
    ld c, b
    nop
    ld a, b
    nop
    ld c, b
    nop
    ld c, b
    nop
    ld c, b
    nop
    ld c, b
    nop
    ld c, b
    nop
    jr c, jr_001_462a

jr_001_462a:
    ld c, b
    nop
    jr c, jr_001_462e

jr_001_462e:
    ld c, b
    nop
    jr c, jr_001_4632

jr_001_4632:
    ld c, b
    nop
    jr c, jr_001_4636

jr_001_4636:
    ld c, b
    nop
    ld c, b
    nop
    ld c, b
    nop
    jr c, jr_001_463e

jr_001_463e:
    ld c, b
    nop
    ld c, b
    nop
    ld c, b
    nop
    ld l, b
    nop
    ld c, b
    nop
    ld l, b
    nop
    ld c, b
    nop
    ld l, b
    nop
    ld l, b
    nop
    ld l, b
    nop
    ld c, b
    nop
    ld l, b
    nop
    ret c

    nop
    ret c

    nop
    ld c, b
    nop
    ld l, b
    ld bc, $00e8
    cp b
    nop
    ld hl, sp+$00
    cp b
    nop
    jr jr_001_4668

jr_001_4668:
    jr z, jr_001_466a

jr_001_466a:
    jr jr_001_466c

jr_001_466c:
    jr z, jr_001_466e

jr_001_466e:
    ld c, b
    nop
    ld c, b
    nop
    ld c, b
    nop
    ld c, b
    nop
    ld l, b
    nop
    ld c, b
    nop
    ld c, b
    nop
    jr c, jr_001_467e

jr_001_467e:
    ld c, b
    nop
    jr c, jr_001_4682

jr_001_4682:
    ld c, b
    nop
    jr c, ScanPartySlotTable

ScanPartySlotTable:
    ld hl, $cac1
    ld b, $00

jr_001_468b:
    ld a, [hl]
    or a
    jr z, jr_001_4696

    push hl
    push bc
    call GetPartySlotByIndex
    pop bc
    pop hl

jr_001_4696:
    call CF3AdvHLHead           ; CF3 (S60): slot advance (HL form) -> ROM0
    nop                         ; head moves the pointer through DE into bank
    nop                         ; $73 entry 2 (boundary-hopping advance).
    nop                         ; Same-size 8-byte window; DE preserved by the
    nop                         ; helper, A/flags clobbered as vanilla did.
    nop
    inc b
    ld a, b
    cp $28  ; FX1: 40 slots
    jr nz, jr_001_468b

    ret


GetPartySlotByIndex:
    push bc
    ld a, b
    ld hl, $caea
    call GetMonsterDataPtr
    pop bc
    ld c, $08

jr_001_46b0:
    ld a, [hl+]
    cp $ff
    push hl
    push bc
    call nz, PreparePartyDataRead
    pop bc
    pop hl
    dec c
    jr nz, jr_001_46b0

    ret


PreparePartyDataRead:
    ld d, a
    push de
    ld a, b
    ld hl, $caf2
    call GetMonsterDataPtr
    pop de
    push hl
    ld c, $19

jr_001_46cb:
    ld a, [hl]
    cp d
    jr nz, jr_001_46d1

    ld [hl], $ff

jr_001_46d1:
    inc hl
    dec c
    jr nz, jr_001_46cb

    pop hl
    push hl
    ld de, wDebug_main_menu_option
    ld b, $19

jr_001_46dc:
    ld a, [hl]
    ld [de], a
    ld a, $ff
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_001_46dc

    pop hl
    ld de, wDebug_main_menu_option
    ld b, $19

jr_001_46eb:
    ld a, [de]
    cp $ff
    jr z, jr_001_46f1

    ld [hl+], a

jr_001_46f1:
    inc de
    dec b
    jr nz, jr_001_46eb

    ret


ReadPartySlotInfo:
    ld a, [$ca8e]
    cp $ff
    jr z, jr_001_470c

    ld hl, $cac1
    call GetMonsterDataPtr
    ld a, [hl]
    or a
    jr nz, jr_001_470c

    ld a, $ff
    ld [$ca8e], a

jr_001_470c:
    ld a, [$ca8f]
    cp $ff
    jr z, jr_001_4722

    ld hl, $cac1
    call GetMonsterDataPtr
    ld a, [hl]
    or a
    jr nz, jr_001_4722

    ld a, $ff
    ld [$ca8f], a

jr_001_4722:
    ld a, [$ca90]
    cp $ff
    jr z, jr_001_4738

    ld hl, $cac1
    call GetMonsterDataPtr
    ld a, [hl]
    or a
    jr nz, jr_001_4738

    ld a, $ff
    ld [$ca90], a

jr_001_4738:
    ld hl, $cac1
    ld b, $28  ; FX1: 40 slots

jr_001_473d:
    ld a, [hl]
    or a
    jr z, jr_001_4743

    ld [hl], $01

jr_001_4743:
    call CF3AdvHLHead           ; CF3 (S60): slot advance (HL form) -> ROM0
    nop                         ; head moves the pointer through DE into bank
    nop                         ; $73 entry 2 (boundary-hopping advance).
    nop                         ; Same-size 8-byte window; DE preserved by the
    nop                         ; helper, A/flags clobbered as vanilla did.
    nop
    dec b
    jr nz, jr_001_473d

    ld a, [$ca8e]
    call RetIfSlotInvalid
    ld a, [$ca8f]
    call RetIfSlotInvalid
    ld a, [$ca90]
    call RetIfSlotInvalid
    ld a, [$ca8e]
    cp $ff
    jr nz, jr_001_4774

    ld hl, $ca8e
    ld a, [$ca8f]
    ld [hl+], a
    ld a, [$ca90]
    ld [hl+], a
    ld [hl], $ff

jr_001_4774:
    ld a, [$ca8e]
    cp $ff
    jr nz, jr_001_4788

    ld hl, $ca8e
    ld a, [$ca8f]
    ld [hl+], a
    ld a, [$ca90]
    ld [hl+], a
    ld [hl], $ff

jr_001_4788:
    ld a, [$ca8f]
    cp $ff
    jr nz, jr_001_4798

    ld hl, $ca8f
    ld a, [$ca90]
    ld [hl+], a
    ld [hl], $ff

jr_001_4798:
    ld hl, wMonList  ; FX1: compaction map -> wMonList
    ld bc, $0028  ; FX1: 40 slots
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, wMonList  ; FX1: compaction map -> wMonList
    ld de, $cac1
    ld b, $28  ; FX1: 40 slots
    ld c, $00

jr_001_47ad:
    ld a, [de]
    or a
    jr z, jr_001_47b3

    ld [hl], c
    inc c

jr_001_47b3:
    push bc                     ; CF3 (S60): slot advance -> bank $73 entry 2
    push hl                     ; (DE += $95 with the WRAM<->SRAM boundary hop
    ld hl, $7302                ; at slot 2->3). Same-size 8-byte window.
    rst $10                     ; BC/HL preserved (rst $10 clobbers BC via its
    pop hl                      ; `ld bc,$4001` table index — walkers keep live
    pop bc                      ; counters in BC). A/flags clobbered as vanilla.
    inc hl
    dec b
    jr nz, jr_001_47ad

    ld c, $28  ; FX1: 40 slots

jr_001_47c1:
    ld hl, $cac1
    ld b, $27  ; FX1: 40 slots

jr_001_47c6:
    ld a, [hl]
    or a
    call z, SaveRegsAndSetupDE
    call CF3AdvHLHead           ; CF3 (S60): slot advance (HL form) -> ROM0
    nop                         ; head moves the pointer through DE into bank
    nop                         ; $73 entry 2 (boundary-hopping advance).
    nop                         ; Same-size 8-byte window; DE preserved by the
    nop                         ; helper, A/flags clobbered as vanilla did.
    nop
    dec b
    jr nz, jr_001_47c6

    dec c
    jr nz, jr_001_47c1

    ld a, [$ca8e]
    call RetIfSlotInvalid2
    ld [$ca8e], a
    ld a, [$ca8f]
    call RetIfSlotInvalid2
    ld [$ca8f], a
    ld a, [$ca90]
    call RetIfSlotInvalid2
    ld [$ca90], a
    ld hl, $ca8e
    ld b, $03
    ld c, $00

jr_001_47fb:
    ld a, [hl+]
    cp $ff
    jr z, jr_001_4801

    inc c

jr_001_4801:
    dec b
    jr nz, jr_001_47fb

    ld a, c
    ld [$ca8d], a
    ; CF3 step 1 (S58): canonicalizer tail retargeted $0106 -> $7301
    ; (same-size operand edit at $01:$4809-$480A). Bank $73 entry 1
    ; CF3PartyFirstSort establishes "party at slots 0-2 in list order"
    ; after every canonicalize, then nest-calls the displaced $0106
    ; (ScanPartySlotTable) itself. See patches/bank_073.asm.
    ld hl, $7301
    rst $10
    ret


RetIfSlotInvalid:
    cp $ff
    ret z

    ld hl, $cac1
    call GetMonsterDataPtr
    ld [hl], $02
    ret


SaveRegsAndSetupDE:
    push bc
    push hl
    ld e, l
    ld d, h
    push bc                     ; CF3 (S60): slot advance -> bank $73 entry 2
    push hl                     ; (DE += $95 with the WRAM<->SRAM boundary hop
    ld hl, $7302                ; at slot 2->3). Same-size 8-byte window.
    rst $10                     ; BC/HL preserved (rst $10 clobbers BC via its
    pop hl                      ; `ld bc,$4001` table index — walkers keep live
    pop bc                      ; counters in BC). A/flags clobbered as vanilla.
    ld a, [de]
    or a
    jr z, jr_001_4834

    ld b, $95

jr_001_482b:
    ld c, [hl]
    ld a, [de]
    ld [hl+], a
    ld a, c
    ld [de], a
    inc de
    dec b
    jr nz, jr_001_482b

jr_001_4834:
    pop hl
    pop bc
    ret


RetIfSlotInvalid2:
    cp $ff
    ret z

    ld hl, wMonList  ; FX1: compaction map -> wMonList
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ret

label1_4845:
    ld a, [$ca8d]
    or a
    jr nz, jr_001_4869

    jr jr_001_4854

    ret


SetupPartyBattleData:
    ld a, [$ca8d]
    or a
    jr nz, jr_001_4862

jr_001_4854:
    ld hl, $8dc0
    ld b, $10

jr_001_4859:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_001_4859

    ret


jr_001_4862:
    call SetupMenuOptions
    call LoadPartySpriteVRAM
    ret


SetupMenuOptions:
jr_001_4869:
    ld hl, wDebug_main_menu_option
    ld bc, $0004
    ld a, $ff
    call FillNBytesWithRegA
    ld a, [$ca8d]
    or a
    jr z, jr_001_48c1

    ld hl, wDebug_main_menu_option
    push hl
    ld a, $00
    ld hl, $cb0b
    call ReadMonsterByte
    pop hl
    bit 7, a
    jr nz, jr_001_488f

    ld a, [$ca8e]
    ld [hl+], a

jr_001_488f:
    ld a, [$ca8d]
    cp $01
    jr z, jr_001_48c1

    push hl
    ld a, $01
    ld hl, $cb0b
    call ReadMonsterByte
    pop hl
    bit 7, a
    jr nz, jr_001_48a8

    ld a, [$ca8f]
    ld [hl+], a

jr_001_48a8:
    ld a, [$ca8d]
    cp $02
    jr z, jr_001_48c1

    push hl
    ld a, $02
    ld hl, $cb0b
    call ReadMonsterByte
    pop hl
    bit 7, a
    jr nz, jr_001_48c1

    ld a, [$ca90]
    ld [hl+], a

jr_001_48c1:
    ld a, [$ca8d]
    or a
    jr z, jr_001_492f

    push hl
    ld a, $00
    ld hl, $cb0b
    call ReadMonsterByte
    pop hl
    bit 7, a
    jr z, jr_001_48e5

    ld a, [$ca8e]
    ld [hl+], a
    push hl
    ld a, $00
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    ld [hl], $80
    pop hl

jr_001_48e5:
    ld a, [$ca8d]
    cp $01
    jr z, jr_001_492f

    push hl
    ld a, $01
    ld hl, $cb0b
    call ReadMonsterByte
    pop hl
    bit 7, a
    jr z, jr_001_490a

    ld a, [$ca8f]
    ld [hl+], a
    push hl
    ld a, $01
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    ld [hl], $80
    pop hl

jr_001_490a:
    ld a, [$ca8d]
    cp $02
    jr z, jr_001_492f

    push hl
    ld a, $02
    ld hl, $cb0b
    call ReadMonsterByte
    pop hl
    bit 7, a
    jr z, jr_001_492f

    ld a, [$ca90]
    ld [hl+], a
    push hl
    ld a, $02
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    ld [hl], $80
    pop hl

jr_001_492f:
    ld a, [wDebug_main_menu_option]
    ld [$ca8e], a
    ld a, [$c0a1]
    ld [$ca8f], a
    ld a, [$c0a2]
    ld [$ca90], a
    ret


LoadPartySpriteVRAM:
    ld hl, $8da0
    ld b, $18

jr_001_4947:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_001_4947

    ld a, [$ca8d]
    or a
    ret z

    ld a, $00
    ld [$cac0], a
    call GetActiveMonsterStatus
    ld [$ca91], a
    ld a, [$ca8d]
    cp $01
    ret z

    ld a, $01
    ld [$cac0], a
    call GetActiveMonsterStatus
    ld [$ca92], a
    ld a, [$ca8d]
    cp $02
    ret z

    ld a, $02
    ld [$cac0], a
    call GetActiveMonsterStatus
    ld [$ca93], a
    ret


GetActiveMonsterStatus:
    ld hl, $cac1
    call ReadActiveMonsterByte
    or a
    ret z

    ld hl, $cb0b
    call ReadActiveMonsterByte
    bit 7, a
    ld a, $01
    jr nz, jr_001_49a2

    ld hl, $caca
    call ReadActiveMonsterByteSpeciesClamped
    add $10

jr_001_49a2:
    push af
    ld l, a
    ld h, $00
    add hl, hl
    call FollowerArtResolve01         ; FORK: id 221-239 -> computed new-species follower gfx-ID (S105 G3); else normal (byte-neutral 8->3+5)
    nop
    nop
    nop
    nop
    nop
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [$cac0]
    add $82
    ld h, a
    ld l, $00
    call WaitDMATransfer
    ; S104 FORK (same-size, 19 B = 6 + 13 nops): the family-icon gfx id comes
    ; from bank $6D entry 0 FamilyIconGfxActive (families 0-9 = the vanilla
    ; FollowerFamilyGfxTable values, Spirit = its own icon $6D04). Was
    ; `ld hl,$cacb / call ClampFamIdx / add a / ld hl,FollowerFamilyGfxTable /
    ; ... / ld e,[hl] / inc hl / ld d,[hl]` (B9 clamped Spirit to the ??? icon).
    push bc
    ld hl, $6D00
    rst $10                           ; DE = family-icon gfx id
    pop bc
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld a, [$cac0]
    swap a
    add $a0
    ld l, a
    ld h, $8d
    call WaitDMATransfer
    pop af
    ret


ScreenTransDataTable:
    ; Follower (walking) gfx-ID table. GetActiveMonsterStatus ($4986)
    ; indexes this by (species + $10)*2 -> 2-byte gfx-ID (bank<<8|index),
    ; resolved by DecompressTileLayout ($00:$1627) via $<bank>:$4001+index*2.
    ; entry 0 = default; entries 1-15 = bit-7 special case (loader forces
    ; index 1 -> $3140); entries 16.. = species 0..214 followers.
    dw $2f00, $3140, $3140, $3140, $3140, $3140, $3140, $3140
    dw $3140, $3140, $3140, $3140, $3140, $3140, $3140, $3140
    ; species 0-214 (index = species + $10) = compiler region art_walk_01
    ; (gamedata.art follower.art; S107 — the same rows as the 7 other copies)
; @BUILD_PROJECT BEGIN art_walk_01
    dw $2F01   ; [0] DrakSlime
    dw $2F02   ; [1] SpotSlime
    dw $2F03   ; [2] WingSlime
    dw $2F04   ; [3] TreeSlime
    dw $2F05   ; [4] Snaily
    dw $2F06   ; [5] SlimeNite
    dw $2F07   ; [6] Babble
    dw $2F08   ; [7] BoxSlime
    dw $2F09   ; [8] Slime
    dw $2F0A   ; [9] Healer
    dw $2F0B   ; [10] FangSlime
    dw $2F0C   ; [11] RockSlime
    dw $2F0D   ; [12] SlimeBorg
    dw $2F0E   ; [13] Slabbit
    dw $2F0F   ; [14] SpotKing
    dw $2F10   ; [15] KingSlime
    dw $3800   ; [16] Metaly
    dw $3801   ; [17] Metabble
    dw $3802   ; [18] MetalKing
    dw $3803   ; [19] GoldSlime
    dw $3804   ; [20] DragonKid
    dw $3805   ; [21] Tortragon
    dw $3806   ; [22] Pteranod
    dw $3807   ; [23] Gasgon
    dw $3808   ; [24] FairyDrak
    dw $3809   ; [25] LizardMan
    dw $380A   ; [26] Poisongon
    dw $380B   ; [27] Swordgon
    dw $380C   ; [28] Dragon
    dw $380D   ; [29] MiniDrak
    dw $380E   ; [30] MadDragon
    dw $380F   ; [31] Rayburn
    dw $3810   ; [32] Chamelgon
    dw $3811   ; [33] LizardFly
    dw $3812   ; [34] Andreal
    dw $3813   ; [35] KingCobra
    dw $3814   ; [36] Spikerous
    dw $3815   ; [37] GreatDrak
    dw $3816   ; [38] Crestpent
    dw $3817   ; [39] WingSnake
    dw $3818   ; [40] Coatol
    dw $3819   ; [41] Orochi
    dw $381A   ; [42] BattleRex
    dw $381B   ; [43] SkyDragon
    dw $381C   ; [44] Divinegon
    dw $381D   ; [45] Tonguella
    dw $381E   ; [46] Almiraj
    dw $381F   ; [47] CatFly
    dw $3820   ; [48] PillowRat
    dw $3821   ; [49] Saccer
    dw $3822   ; [50] GulpBeast
    dw $3823   ; [51] Skullroo
    dw $3824   ; [52] WindBeast
    dw $3825   ; [53] Anteater
    dw $3826   ; [54] SuperTen
    dw $3827   ; [55] IronTurt
    dw $3828   ; [56] Mommonja
    dw $3829   ; [57] HammerMan
    dw $382A   ; [58] Grizzly
    dw $382B   ; [59] Yeti
    dw $382C   ; [60] MadGopher
    dw $382D   ; [61] FairyRat
    dw $382E   ; [62] Unicorn
    dw $382F   ; [63] Goategon
    dw $3830   ; [64] WildApe
    dw $3831   ; [65] Trumpeter
    dw $3832   ; [66] KingLeo
    dw $3833   ; [67] DarkHorn
    dw $3834   ; [68] MadCat
    dw $3835   ; [69] BigEye
    dw $3836   ; [70] Picky
    dw $3837   ; [71] Wyvern
    dw $3838   ; [72] BullBird
    dw $3839   ; [73] Florajay
    dw $383A   ; [74] DuckKite
    dw $383B   ; [75] MadPecker
    dw $383C   ; [76] MadRaven
    dw $383D   ; [77] MistyWing
    dw $383E   ; [78] Dracky
    dw $383F   ; [79] BigRoost
    dw $3840   ; [80] StubBird
    dw $3841   ; [81] LandOwl
    dw $3842   ; [82] MadGoose
    dw $3843   ; [83] MadCondor
    dw $3844   ; [84] Blizzardy
    dw $3845   ; [85] Phoenix
    dw $3846   ; [86] ZapBird
    dw $3847   ; [87] WhipBird
    dw $3900   ; [88] FunkyBird
    dw $3901   ; [89] RainHawk
    dw $3902   ; [90] MadPlant
    dw $3903   ; [91] FireWeed
    dw $3904   ; [92] FloraMan
    dw $3905   ; [93] WingTree
    dw $3906   ; [94] CactiBall
    dw $3907   ; [95] Gulpple
    dw $3908   ; [96] Toadstool
    dw $3909   ; [97] AmberWeed
    dw $390A   ; [98] Stubsuck
    dw $390B   ; [99] Oniono
    dw $390C   ; [100] DanceVegi
    dw $390D   ; [101] TreeBoy
    dw $390E   ; [102] FaceTree
    dw $390F   ; [103] HerbMan
    dw $3910   ; [104] BeanMan
    dw $3911   ; [105] EvilSeed
    dw $3912   ; [106] ManEater
    dw $3913   ; [107] Snapper
    dw $3914   ; [108] Rosevine
    dw $3915   ; [109] Watabou
    dw $3916   ; [110] GiantSlug
    dw $3917   ; [111] Catapila
    dw $3918   ; [112] Gophecada
    dw $3919   ; [113] Butterfly
    dw $391A   ; [114] WeedBug
    dw $391B   ; [115] GiantWorm
    dw $391C   ; [116] Lipsy
    dw $391D   ; [117] StagBug
    dw $391E   ; [118] ArmyAnt
    dw $391F   ; [119] GoHopper
    dw $3920   ; [120] TailEater
    dw $3921   ; [121] ArmorPede
    dw $3922   ; [122] Eyeder
    dw $3923   ; [123] GiantMoth
    dw $3924   ; [124] Droll
    dw $3925   ; [125] ArmyCrab
    dw $3926   ; [126] MadHornet
    dw $3927   ; [127] HornBeet
    dw $3928   ; [128] Armorpion
    dw $3929   ; [129] Digster
    dw $392A   ; [130] Pixy
    dw $392B   ; [131] ArcDemon
    dw $392C   ; [132] AgDevil
    dw $392D   ; [133] Demonite
    dw $392E   ; [134] DarkEye
    dw $392F   ; [135] EyeBall
    dw $3930   ; [136] SkulRider
    dw $3931   ; [137] EvilBeast
    dw $3932   ; [138] 1EyeClown
    dw $3933   ; [139] Gremlin
    dw $3934   ; [140] MedusaEye
    dw $3935   ; [141] Lionex
    dw $3936   ; [142] GoatHorn
    dw $3937   ; [143] Orc
    dw $3938   ; [144] Ogre
    dw $3939   ; [145] GateGuard
    dw $393A   ; [146] ChopClown
    dw $393B   ; [147] Grendal
    dw $393C   ; [148] Akubar
    dw $393D   ; [149] MadKnight
    dw $393E   ; [150] Gigantes
    dw $393F   ; [151] Centasaur
    dw $3940   ; [152] EvilArmor
    dw $3941   ; [153] Jamirus
    dw $3942   ; [154] Durran
    dw $3943   ; [155] Spooky
    dw $3944   ; [156] Skullgon
    dw $3945   ; [157] Putrepup
    dw $3946   ; [158] RotRaven
    dw $3947   ; [159] Mummy
    dw $3A00   ; [160] DarkCrab
    dw $3A01   ; [161] DeadNite
    dw $3A02   ; [162] Shadow
    dw $3A03   ; [163] Hork
    dw $3A04   ; [164] Mudron
    dw $3A05   ; [165] NiteWhip
    dw $3A06   ; [166] MadSpirit
    dw $3A07   ; [167] WindMerge
    dw $3A08   ; [168] Reaper
    dw $3A09   ; [169] DeadNoble
    dw $3A0A   ; [170] WhiteKing
    dw $3A0B   ; [171] BoneSlave
    dw $3A0C   ; [172] Skeletor
    dw $3A0D   ; [173] Servant
    dw $3A0E   ; [174] Copycat
    dw $3A0F   ; [175] JewelBag
    dw $3A10   ; [176] EvilWand
    dw $3A11   ; [177] MadCandle
    dw $3A12   ; [178] CoilBird
    dw $3A13   ; [179] Facer
    dw $3A14   ; [180] SpikyBoy
    dw $3A15   ; [181] MadMirror
    dw $3A16   ; [182] RogueNite
    dw $3A17   ; [183] Goopi
    dw $3A18   ; [184] Voodoll
    dw $3A19   ; [185] MetalDrak
    dw $3A1A   ; [186] Balzak
    dw $3A1B   ; [187] SabreMan
    dw $3A1C   ; [188] CurseLamp
    dw $3A1D   ; [189] Roboster
    dw $3A1E   ; [190] EvilPot
    dw $3A1F   ; [191] Gismo
    dw $3A20   ; [192] LavaMan
    dw $3A21   ; [193] IceMan
    dw $3A22   ; [194] Mimic
    dw $3A23   ; [195] MudDoll
    dw $3A24   ; [196] Golem
    dw $3A25   ; [197] StoneMan
    dw $3A26   ; [198] BombCrag
    dw $3A27   ; [199] GoldGolem
    dw $3A28   ; [200] DracoLord
    dw $3A29   ; [201] DracoLord
    dw $3A2A   ; [202] Hargon
    dw $3A2B   ; [203] Sidoh
    dw $3A2C   ; [204] Baramos
    dw $3A2D   ; [205] Zoma
    dw $3A2E   ; [206] Pizzaro
    dw $3A2F   ; [207] Esterk
    dw $3A30   ; [208] Mirudraas
    dw $3A31   ; [209] Mirudraas
    dw $3A32   ; [210] Mudou
    dw $3A33   ; [211] DeathMore
    dw $3A34   ; [212] DeathMore
    dw $3A35   ; [213] DeathMore
    dw $3A36   ; [214] Darkdrium
; @BUILD_PROJECT END art_walk_01

FollowerFamilyGfxTable:
    ; Family-shared follower block (2nd DMA in GetActiveMonsterStatus,
    ; via `ld hl, FollowerFamilyGfxTable` + family-byte index). 10 entries,
    ; families 0-9 -> $2E03..$2E0C. S104: DEAD — GetActiveMonsterStatus far-calls
    ; bank $6D entry 0 FamilyIconGfxActive (same values + Spirit's own icon).
    dw $2e03, $2e04, $2e05, $2e06, $2e07, $2e08, $2e09, $2e0a
    dw $2e0b, $2e0c

; Bank $01 entry 9 — HEAL ALL (S125; PyBoy-measured): for each of the 20 monster
; records at $CAC1 (stride $95) whose flag byte is non-zero: status (+$4A) := 0,
; then HP +$50 := max HP +$52 and MP +$54 := max MP +$56 (words). Script op $27 (`refresh_party`,
; bank $04 ScriptCmd27_RefreshParty) runs it, then entry 3 — the cutscene /
; conversation Heal step. (The name predates the decode; kept for the tools.)
IteratePartySlots20:
    ld hl, $cac1
    ld b, $28  ; FX1: 40 slots
jr_001_4bc6:
    push hl
    ld a, [hl]
    or a
    jr z, jr_001_4c03

jr_001_4bcb:
    ld a, l
    add $4a
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld [hl], $00
    ld a, l
    add $08
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld e, l
    ld d, h
    ld a, e
    add $fe
    ld e, a
    ld a, d
    adc $ff
    ld d, a
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl]
    ld [de], a
    ld a, l
    add $03
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld e, l
    ld d, h
    ld a, e
    add $fe
    ld e, a
    ld a, d
    adc $ff
    ld d, a
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl]
    ld [de], a

jr_001_4c03:
    pop hl
    call CF3AdvHLHead           ; CF3 (S60): slot advance (HL form) -> ROM0
    nop                         ; head moves the pointer through DE into bank
    nop                         ; $73 entry 2 (boundary-hopping advance).
    nop                         ; Same-size 8-byte window; DE preserved by the
    nop                         ; helper, A/flags clobbered as vanilla did.
    nop
    dec b
    jr nz, jr_001_4bc6

    ret


CheckBattleModeFlag:
    ld a, [$c8ea]
    cp $80
    ret z

    ld hl, $d8e9
    ld bc, $0040
    xor a
    call FillNBytesWithRegA
    xor a
    ld [$d9cb], a
    ld [$d9cc], a
    xor a
    ld [$d9df], a
    ld [$d9e0], a
    ld a, [wScriptStateFlags]
    or a
    ret nz

; ---------------------------------------------------------------------------
; RoomEntryScript — Trigger script_id $00 on room load
; ---------------------------------------------------------------------------
; Called when entering a room. Sets script_id = $00 (the room's entry script)
; and dispatches to the script engine. Script $00 in each map's script data
; handles room initialization events (NPCs appearing, cutscenes, etc.)
;
; Overworld: $D8D3 = wMapID (actual map type)
; Gate world: $D8D3 = $70 (fixed gate world map type)
; ---------------------------------------------------------------------------
    ld a, [wInGateworld]
    or a
    jr nz, jr_001_4c49

    ld a, $00
    ld [wScriptNPCId], a            ; script_id = $00 (room entry script)
    ; S70: REVERTED to the vanilla instruction (ld a,[wMapID] — 3 bytes, same
    ; size as the old `call MapIDClampForPalette`). The clamp predated the S42
    ; GateAwareDispatch routing and sent custom rooms to Castle's script 0 at
    ; initial entry (PROJECT_COMPILER.md §7 "initial room entry"). With raw
    ; wMapID, custom rooms ($6B+) take the SAME proven dispatch chain the
    ; scroll/reload path uses (MapTypeDispatch >= $40 -> DispatchBank0F_Ext ->
    ; GateAwareDispatch -> CustomScriptRead), so entry scripts (index 0) now
    ; fire at initial entry too — the entry-cutscene enabler. Vanilla rooms:
    ; byte-different, behavior-identical (clamp was identity for < $6B).
    ld a, [wMapID]
    ld [wScriptMapType], a            ; map type = current map (raw, incl. custom)
    ld hl, $0405             ; Bank $04 entry 5: ScriptInit
    rst $10
    ret


jr_001_4c49:
    ld a, $00
    ld [wScriptNPCId], a            ; script_id = $00 (room entry script)
    ld a, $70
    ld [wScriptMapType], a            ; map type = $70 (gate world)
    ld hl, $0405             ; Bank $04 entry 5: ScriptInit
    rst $10
    ret

GetMonsterSkillDataPtr:
    ld a, d
    ld hl, $cb25
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    call ClassifyMonsterTier
    ld a, $09
    call Mul8x8To16
    ld b, l
    ld a, e
    add $01
    ld e, a
    ld a, d
    adc $00
    ld d, a
    call ClassifyMonsterTier
    ld a, c
    add a
    add c
    add b
    ld b, a
    ld a, e
    add $02
    ld e, a
    ld a, d
    adc $00
    ld d, a
    call ClassifyMonsterTier
    ld a, c
    add b
    ld d, a
    ret


ClassifyMonsterTier:
    ld a, [de]
    ld c, $00
    cp $c0
    ret nc

    inc c
    cp $40
    ret nc

    inc c
    ret


ClearFieldAnimFlag:
    xor a
    ld [$c8ab], a

    ;Makes player's name corrupted as these
    ;Japanese characters no longer exist.
    ld a, $6e ;Character Te - テ
    ld [$ca42], a
    ld a, $86 ;Character Ri - リ
    ld [$ca43], a
    ld a, $9c ;Character ー
    ld [$ca44], a
    ld a, $f0

    ;Sets following monsters to first, second, and third monsters in farm.
    ld [$ca45], a
    ld a, $00
    ld [$ca8e], a
    ld a, $01
    ld [$ca8f], a
    ld a, $02
    ld [$ca90], a

    ld b, $14
    ld c, $00

jr_001_4cc0:
    push bc
    ld a, c
    call RollRandomEncounter
    pop bc
    inc c
    dec b
    jr nz, jr_001_4cc0

    ld a, $00
    ld [wCurrGoldLo], a
    ld a, $54
    ld [wCurrGoldMid], a
    ld a, $01
    ld [wCurrGoldHi], a
    ld a, ITEM_HERB
    ld [wInventory], a
    ld a, ITEM_LOVEWATER
    ld [$ca52], a
    ld a, ITEM_SAGE_STONE
    ld [$ca53], a
    ld a, ITEM_WORLD_DEW
    ld [$ca54], a
    ld a, ITEM_POTION
    ld [$ca55], a
    ld a, ITEM_ELF_WATER
    ld [$ca56], a
    ld a, ITEM_ANTIDOTE
    ld [$ca57], a
    ld a, ITEM_MOON_HERB
    ld [$ca58], a
    ret


RollRandomEncounter:
    push af
    ld [$da14], a
    call GenerateRNG
    ld a, [wRNG1]
    and $3f
    inc a
    ld [wTempEnemyStatsId], a
    xor a
    ld [$da13], a
    ld hl, $1402
    rst $10
    pop af
    push af
    call GenerateRNG
    and $7f
    ld [wTempSpeciesId], a
    ld hl, $cad6
    ld c, a
    pop af
    call WriteMonsterDataByte
    push af
    pop af
    push af
    call GenerateRNG
    and $7f
    ld [wTempSpeciesId], a
    ld hl, $cad7
    ld c, a
    pop af
    call WriteMonsterDataByte
    push af
    pop af
    push af
    ld hl, $cacb
    call GetMonsterDataPtr
    ld a, [hl]
    ld c, a
    pop af
    ld hl, $cac2
    call GetMonsterDataForParty
    push af
    call GenerateRNG
    ld a, [wRNG1]
    and $07
    ld c, a
    pop af
    ld hl, $cad8
    call GetMonsterDataForParty
    push af
    call GenerateRNG
    ld a, [wRNG1]
    and $07
    ld c, a
    pop af
    ld hl, $cae1
    call GetMonsterDataForParty
    push af
    ld hl, $cad6
    call GetMonsterDataPtr
    ld a, [hl]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld a, [$da33]
    ld c, a
    pop af
    ld hl, $cb44
    call GetMonsterDataForParty
    push af
    ld hl, $cad7
    call GetMonsterDataPtr
    ld a, [hl]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld a, [$da33]
    ld c, a
    pop af
    ld hl, $cb4d
    call GetMonsterDataForParty
    ret


WriteMonsterDataByte:
    push af
    call GetMonsterDataPtr
    ld [hl], c
    pop af
    ret


    push af
    call GetMonsterDataPtr
    ld [hl], c
    inc hl
    ld [hl], b
    pop af
    ret


GetMonsterDataForParty:
    push af
    push bc
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    call GenerateRNG
    ld a, [wRNG1]
    and $0f
    pop bc
    swap c
    or c
    ld l, a
    ld h, $03
    call SetupVRAMParams
    pop af
    ret

MainFieldLoop:
    ld a, [$c88f]
    or a
    jp nz, Jump_001_4139

ProcessFieldInput:
    jr jr_001_4dfc

    ld a, [wJoypad_current_frame]
    and $04
    jr z, jr_001_4dfc

    ld a, [$c8aa]
    or a
    jr nz, jr_001_4df3

    ldh a, [rNR50]
    ld [$c8aa], a
    xor a
    ldh [rNR50], a
    jr jr_001_4dfc

jr_001_4df3:
    ld a, [$c8aa]
    ldh [rNR50], a
    xor a
    ld [$c8aa], a

jr_001_4dfc:
    ld a, [$c8aa]
    or a
    jr nz, jr_001_4e0b

    call VisualEffectsDispatch
    call IncrementVisualStep
    call CheckScriptActive

jr_001_4e0b:
    ld hl, $0404
    rst $10
    ld hl, $0606
    rst $10
    call CheckScriptBeforeAction
    ld hl, $0601
    rst $10
    call CheckFieldEventFlag
    call CheckPaletteAnimActive
    ld a, [$c8aa]
    or a
    jr nz, jr_001_4e29

    call IncrementEncounterCounter

jr_001_4e29:
    ret


    ld a, [$c886]
    ld b, a
    ld a, [$c888]
    add b
    ld [$c888], a
    ld a, [$c889]
    adc $00
    ld [$c889], a
    ld a, [$c8a4]
    and $3f
    jr nz, jr_001_4e5b

    ld a, [$c888]
    ld b, a
    ld a, [$c889]
    rl b
    rla
    rl b
    rla
    ld [$c887], a
    xor a
    ld [$c888], a
    ld [$c889], a

jr_001_4e5b:
    ld hl, wDebug_main_menu_option
    ld a, [$c887]
    ld b, a
    ld a, $91
    sub b
    ld c, a
    ld b, $00
    call ExtractHundreds
    ld hl, $ffc3
    ld a, $80
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $78
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00

WriteFieldDataBytes:
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, [wDebug_main_menu_option]
    ldh [$c9], a
    ld hl, $0401
    rst $10
    ld a, $88
    ldh [$c3], a
    ld a, [$c0a1]
    ldh [$c9], a
    ld hl, $0401
    rst $10

SetTimerHRAM90:
Jump_001_4e9c:
    ld a, $90
    ldh [$c3], a
    ld a, [$c0a2]
    ldh [$c9], a
    ld hl, $0401
    rst $10
    ret


IncrementVisualStep:
    ld a, [$c8a6]
    add $01
    ld [$c8a6], a
    ld a, [$c8a7]
    adc $00
    ld [$c8a7], a
    ld a, [$c8a8]
    or a
    jr z, jr_001_4ed2

    dec a
    ld [$c8a8], a
    or a
    jr nz, jr_001_4ed2

    ld a, [$c850]
    or a
    jr nz, jr_001_4ed2

    ld a, $d2
    ld [wBGPalette], a

jr_001_4ed2:
    ld a, [wGameState]
    bit 5, a
    jr nz, jr_001_4ef9

    bit 6, a
    jr nz, jr_001_4ef9

    ld a, [$c850]
    or a
    jr nz, jr_001_4ef9

    ld a, [$c8a8]
    or a
    jr nz, jr_001_4ef3

    call CheckGameStateBit2
    call CheckGameStateThenCoords
    ld hl, $0602
    rst $10

jr_001_4ef3:
    call CallBank06AndProcess
    call CompareScreenPosition

jr_001_4ef9:
    ret


CheckScriptActive:
    ld a, [wScriptStateFlags]
    or a
    ret nz

    ld a, [wGameState]
    bit 1, a
    ret nz

    bit 7, a
    ret nz

    bit 4, a
    ret nz

    bit 3, a
    ret nz

    bit 2, a
    ret nz

    ld hl, $ffb7
    ldh a, [$92]
    sub [hl]
    ld e, a
    inc hl
    ldh a, [$93]
    sbc [hl]
    bit 7, a
    jr nz, jr_001_4f49

    or a
    jr nz, jr_001_4f50

    ld a, e
    cp $07
    jr c, jr_001_4f49

    cp $99
    jr nc, jr_001_4f50

    ld hl, $ffbb
    ldh a, [$95]
    sub [hl]
    ld e, a
    inc hl
    ldh a, [$96]
    sbc [hl]
    bit 7, a
    jr nz, jr_001_4f57

    or a
    jr nz, jr_001_4f5e

    ld a, e
    cp $07
    jr c, jr_001_4f57

    cp $79
    jr nc, jr_001_4f5e

    jr jr_001_4f6f

jr_001_4f49:
    ld a, $00
    ld [$c91d], a
    jr jr_001_4f63

jr_001_4f50:
    ld a, $01
    ld [$c91d], a
    jr jr_001_4f63

jr_001_4f57:
    ld a, $02
    ld [$c91d], a
    jr jr_001_4f63

jr_001_4f5e:
    ld a, $03
    ld [$c91d], a

jr_001_4f63:
    ld hl, wGameState
    set 2, [hl]
    xor a
    ld [$c91e], a
    ld [$c91f], a

jr_001_4f6f:
    ret


CheckGameStateBit2:
    ld a, [wGameState]
    bit 2, a
    jp nz, Jump_001_5253

    bit 0, a
    jp nz, Jump_001_51fd

    bit 1, a
    jp nz, Jump_001_5253

    bit 7, a
    jp nz, Jump_001_5253

    bit 4, a
    jp nz, Jump_001_5253

    bit 3, a
    jp nz, Jump_001_5253

    ld hl, $ff90
    res 4, [hl]
    ldh a, [$90]
    bit 6, a
    jp nz, Jump_001_5253

    ldh a, [$90]
    bit 7, a
    jp nz, Jump_001_51fd

    bit 0, a
    jp nz, Jump_001_51b2

    ld a, [wScriptStateFlags]
    or a
    jp nz, Jump_001_51b2

    ld hl, $ffb7
    ldh a, [$92]
    sub [hl]
    ld e, a
    inc hl
    ldh a, [$93]
    sbc [hl]
    or a
    jp nz, Jump_001_51b2

    ld a, e
    cp $07
    jp c, Jump_001_51b2

    cp $99
    jp nc, Jump_001_51b2

    ld hl, $ffbb
    ldh a, [$95]
    sub [hl]
    ld e, a
    inc hl
    ldh a, [$96]
    sbc [hl]
    or a
    jp nz, Jump_001_51b2

    ld a, e
    cp $07
    jp c, Jump_001_51b2

    cp $79
    jp nc, Jump_001_51b2

    ld hl, $00c0
    ld a, [$c842]
    bit 4, a
    jr z, jr_001_5056

    ld a, $00
    ldh [$8d], a
    ld a, $01
    ldh [$8f], a
    call RetIfInGateworld
    ldh a, [$8e]
    push af
    ld a, $03
    ldh [$8e], a
    pop af
    cp $03
    jr z, jr_001_5012

    xor a
    ldh [$a1], a
    ldh [$a2], a
    ld a, $05
    ld [$c8a8], a
    jp Jump_001_51b2


jr_001_5012:
    ld a, l
    ldh [$a1], a
    ld a, h
    ldh [$a2], a
    ldh a, [$95]
    and $0f
    cp $08
    jr nz, jr_001_5046

    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ldh a, [$95]
    ldh [$a7], a
    ldh a, [$96]
    ldh [$a8], a
    call TileAtPixel
    ldh a, [$a9]
    cp $ff
    jp nz, Jump_001_51b2

jr_001_5046:
    xor a
    ldh [$a1], a
    ldh [$a2], a
    call GetScrollPositionHL
    ld hl, $ff90
    set 4, [hl]
    jp Jump_001_51b2


jr_001_5056:
    ld a, [$c842]
    bit 5, a
    jr z, jr_001_50cf

    ld a, l
    cpl
    add $01
    ld l, a
    ld a, h
    cpl
    adc $00
    ld h, a
    ld a, $20
    ldh [$8d], a
    ld a, $01
    ldh [$8f], a
    call RetIfInGateworld
    ldh a, [$8e]
    push af
    ld a, $01
    ldh [$8e], a
    pop af
    cp $01
    jr z, jr_001_508b

    xor a
    ldh [$a1], a
    ldh [$a2], a
    ld a, $05
    ld [$c8a8], a
    jp Jump_001_51b2


jr_001_508b:
    ld a, l
    ldh [$a1], a
    ld a, h
    ldh [$a2], a
    ldh a, [$95]
    and $0f
    cp $08
    jr nz, jr_001_50bf

    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, l
    sub $10
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ldh a, [$95]
    ldh [$a7], a
    ldh a, [$96]
    ldh [$a8], a
    call TileAtPixel
    ldh a, [$a9]
    cp $ff
    jp nz, Jump_001_51b2

jr_001_50bf:
    xor a
    ldh [$a1], a
    ldh [$a2], a
    call RetIfScreenBusy
    ld hl, $ff90
    set 4, [hl]
    jp Jump_001_51b2


jr_001_50cf:
    ld hl, $00c0
    ld a, [$c842]
    bit 7, a
    jp z, Jump_001_5145

    ld a, $00
    ldh [$8d], a
    ld a, $00
    ldh [$8f], a
    call RetIfInGateworld
    ldh a, [$8e]
    push af
    ld a, $00
    ldh [$8e], a
    pop af
    cp $00
    jr z, jr_001_50fe

    xor a
    ldh [$a3], a
    ldh [$a4], a
    ld a, $05
    ld [$c8a8], a
    jp Jump_001_51b2


jr_001_50fe:
    ld a, l
    ldh [$a3], a
    ld a, h
    ldh [$a4], a
    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, l
    sub $08
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld a, l
    and $f0
    ld l, a
    ld a, l
    add $18
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    ldh a, [$92]
    ldh [$a5], a
    ldh a, [$93]
    ldh [$a6], a
    call TileAtPixel
    ldh a, [$a9]
    cp $ff
    jp nz, Jump_001_51b2

    xor a
    ldh [$a3], a
    ldh [$a4], a
    call GetScrollPosition2
    ld hl, $ff90
    set 4, [hl]
    jr jr_001_51b2

Jump_001_5145:
    ld a, [$c842]
    bit 6, a
    jp z, Jump_001_51ea

    ld a, l
    cpl
    add $01
    ld l, a
    ld a, h
    cpl
    adc $00
    ld h, a
    ld a, $00
    ldh [$8d], a
    ld a, $02
    ldh [$8f], a
    ldh a, [$8e]
    push af
    ld a, $02
    ldh [$8e], a
    pop af
    cp $02
    jr z, jr_001_5178

    xor a
    ldh [$a3], a
    ldh [$a4], a
    ld a, $05
    ld [$c8a8], a
    jp Jump_001_51b2


jr_001_5178:
    ld a, l
    ldh [$a3], a
    ld a, h
    ldh [$a4], a
    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, l
    sub $10
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    ldh a, [$92]
    ldh [$a5], a
    ldh a, [$93]
    ldh [$a6], a
    call TileAtPixel
    ldh a, [$a9]
    cp $ff
    jr nz, jr_001_51b2

    xor a
    ldh [$a3], a
    ldh [$a4], a
    call RetIfScrollActive
    ld hl, $ff90
    set 4, [hl]
    jr jr_001_51b2

Jump_001_51b2:
jr_001_51b2:
    ldh a, [$90]
    bit 1, a
    jr nz, jr_001_51ea

    ldh a, [$8f]
    add $03
    ld b, a
    ld a, [$d7b8]
    cp b
    jr z, jr_001_51d1

    ld a, b
    ld [$d7b8], a
    xor a
    ld [$d7ba], a
    ld [$d7bb], a
    ld [$d7b6], a

jr_001_51d1:
    ld hl, $d7b6
    ld a, l
    ld [$d7b4], a
    ld a, h
    ld [$d7b5], a
    ldh a, [$8a]
    ld [$d7b7], a
    ld hl, $0200
    rst $10
    ld a, [$d7ba]
    ldh [$8b], a

Jump_001_51ea:
jr_001_51ea:
    ldh a, [$92]
    ldh [$a5], a
    ldh a, [$93]
    ldh [$a6], a
    ldh a, [$95]
    ldh [$a7], a
    ldh a, [$96]
    ldh [$a8], a
    call TileAtPixel

Jump_001_51fd:
    ldh a, [$90]
    bit 0, a
    jp nz, Jump_001_5253

    ld a, [wScriptStateFlags]
    or a
    jp nz, Jump_001_5212

    ld a, [$c842]
    and $f0
    jr nz, jr_001_5253

Jump_001_5212:
    ld c, $00
    ld a, [wScriptStateFlags]
    or a
    jr z, jr_001_521c

    ld c, $06

jr_001_521c:
    ldh a, [$8f]
    add c
    ld b, a
    ld a, [$d7b8]
    cp b
    jr z, jr_001_5234

    ld a, b
    ld [$d7b8], a
    xor a
    ld [$d7ba], a
    ld [$d7bb], a
    ld [$d7b6], a

jr_001_5234:
    ld hl, $d7b6
    ld a, l
    ld [$d7b4], a
    ld a, h
    ld [$d7b5], a
    ldh a, [$8a]
    ld [$d7b7], a
    ld hl, $0200
    rst $10
    ld a, [$d7b6]
    or a
    jr z, jr_001_5253

    ld a, [$d7ba]
    ldh [$8b], a

Jump_001_5253:
jr_001_5253:
    ret


RetIfInGateworld:
    ld a, [wInGateworld]
    or a
    ret nz

    ld a, [wMapID]
    cp MAP_IN_WELL
    ret nz

    ldh a, [$95]
    ld e, a
    ldh a, [$96]
    ld d, a
    ld a, e
    sub $90
    ld e, a
    ld a, d
    sbc $00
    ld d, a
    ret nc

    ld a, $00
    ldh [$8d], a
    ld a, $02
    ldh [$8f], a
    ret


CheckGameStateThenCoords:
    ld a, [wGameState]
    bit 2, a
    jr z, jr_001_5287

    call CalcGateDataOffset
    call CalcGateDataOffset
    call ReadPlayerCoords

ReadPlayerCoords:
jr_001_5287:
    ld hl, $ffa1
    ld a, [hl+]
    or [hl]
    jr z, jr_001_52ac

    ld b, $00
    ldh a, [$a2]
    bit 7, a
    jr z, jr_001_5297

    dec b

jr_001_5297:
    ld hl, $ff91
    ldh a, [$a1]
    add [hl]
    ld [hl+], a
    ldh a, [$a2]
    adc [hl]
    ld [hl+], a
    ld a, b
    adc [hl]
    ld [hl], a
    ld hl, $ff90
    set 0, [hl]
    jr jr_001_52cf

jr_001_52ac:
    ld hl, $ffa3
    ld a, [hl+]
    or [hl]
    jr z, jr_001_52cf

    ld b, $00
    ldh a, [$a4]
    bit 7, a
    jr z, jr_001_52bc

    dec b

jr_001_52bc:
    ld hl, $ff94
    ldh a, [$a3]
    add [hl]
    ld [hl+], a
    ldh a, [$a4]
    adc [hl]
    ld [hl+], a		;breaks when updating playing position.
    ld a, b
    adc [hl]
    ld [hl], a
    ld hl, $ff90
    set 0, [hl]

jr_001_52cf:
    ldh a, [$93]
    or a
    jr nz, jr_001_52e8

    ldh a, [$92]
    cp $08
    jr nc, jr_001_52e8

    ld a, $00
    ldh [$91], a
    ld a, $08
    ldh [$92], a
    ld a, $00
    ldh [$93], a
    jr jr_001_530a

jr_001_52e8:
    ldh a, [$9d]
    ld l, a
    ldh a, [$9e]
    ld h, a
    ld a, l
    sub $08
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ldh a, [$93]
    cp h
    jr c, jr_001_530a

    ldh a, [$92]
    cp l
    jr c, jr_001_530a

    ld a, $00
    ldh [$91], a
    ld a, l
    ldh [$92], a
    ld a, h
    ldh [$93], a

jr_001_530a:
    ldh a, [$96]
    or a
    jr nz, jr_001_5323

    ldh a, [$95]
    cp $08
    jr nc, jr_001_5323

    ld a, $00
    ldh [$94], a
    ld a, $08
    ldh [$95], a
    ld a, $00
    ldh [$96], a
    jr jr_001_5345

jr_001_5323:
    ldh a, [$9f]
    ld l, a
    ldh a, [$a0]
    ld h, a
    ld a, l
    sub $08
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ldh a, [$96]
    cp h
    jr c, jr_001_5345

    ldh a, [$95]
    cp l
    jr c, jr_001_5345

    ld a, $00
    ldh [$94], a
    ld a, l
    ldh [$95], a
    ld a, h
    ldh [$96], a

jr_001_5345:
    ldh a, [$90]
    bit 0, a
    jp z, Jump_001_53ce

    ldh a, [$92]
    and $0f
    cp $08
    jr nz, jr_001_5359

    xor a
    ldh [$a1], a
    ldh [$a2], a

jr_001_5359:
    ldh a, [$95]
    and $0f
    cp $08
    jr nz, jr_001_5366

    xor a
    ldh [$a3], a
    ldh [$a4], a

jr_001_5366:
    ld hl, $ffa1
    ld a, [hl+]
    or [hl]
    jr nz, jr_001_53ce

    ld hl, $ffa3
    ld a, [hl+]
    or [hl]
    jr nz, jr_001_53ce

    ld hl, $ff90
    res 0, [hl]
    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    swap h
    swap l
    ld a, h
    and $f0
    ld h, a
    ld a, l
    and $0f
    or h
    ld b, a
    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    swap h
    swap l
    ld a, h
    and $f0
    ld h, a
    ld a, l
    and $0f
    or h
    ld c, a
    ldh a, [$97]
    cp b
    jr nz, jr_001_53a9

    ldh a, [$98]
    cp c
    jr z, jr_001_53ce

jr_001_53a9:
    ld a, b
    ldh [$97], a
    ld a, c
    ldh [$98], a
    call CopyPlayerCoordsToHRAM
    call RetIfNotGateworld2
    call RetIfNotGateworld3
    ld hl, $0b06
    rst $10
    call CopyPlayerCoordsAndGetNextRoom
    call CheckGateworldField
    call CheckOverworldVsGate
    call CheckGateworldForSpawn
    call InitNPCMovementZero
    call CheckNPCInteraction

Jump_001_53ce:
jr_001_53ce:
    ret


CompareScreenPosition:
    ld hl, $ff99
    ldh a, [$92]
    cp [hl]
    jr nz, jr_001_53e9

    inc hl
    ldh a, [$93]
    cp [hl]
    jr nz, jr_001_53e9

    inc hl
    ldh a, [$95]
    cp [hl]
    jr nz, jr_001_53e9

    inc hl
    ldh a, [$96]
    cp [hl]
    jr z, jr_001_53ec

jr_001_53e9:
    call CalcGateDataOffset

jr_001_53ec:
    ldh a, [$92]
    ldh [$99], a
    ldh a, [$93]
    ldh [$9a], a
    ldh a, [$95]
    ldh [$9b], a
    ldh a, [$96]
    ldh [$9c], a
    call LoadNPCDataTable
    ld a, [$d7b8]
    cp $03
    jr z, jr_001_540f

    cp $04
    jr z, jr_001_540f

    cp $05
    jr z, jr_001_540f

    ret


jr_001_540f:
    ld hl, $ff90
    bit 5, [hl]
    jr nz, jr_001_5425

    bit 4, [hl]
    ret z

    ld hl, $ffa1
    ld a, [hl+]
    or [hl]
    ret nz

    ld hl, $ffa3
    ld a, [hl+]
    or [hl]
    ret nz

jr_001_5425:
    ld a, [$c850]
    or a
    ret nz

    ld a, [$d7b6]
    or a
    ret nz

    ld a, [wScriptStateFlags]
    or a
    ret nz

    ld a, $54
    call PlaySoundEffect
    ld a, $80
    ldh [$91], a
    ldh [$94], a
    ret


LoadNPCDataTable:
    ld hl, $d7d2

jr_001_5443:
    ld a, [hl]
    cp $ff
    ret z

    push hl
    ld a, l
    add $18
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld e, l
    ld d, h
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl], a
    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_001_5443

    ret


RetIfScreenBusy:
    ldh a, [$93]
    or a
    ret nz

    ldh a, [$92]
    cp $08
    ret nz

    ld a, $00
    ldh [$91], a
    ld a, $08
    ldh [$92], a
    ld a, $00
    ldh [$93], a
    ld hl, $0b09
    rst $10
    ret


GetScrollPositionHL:
    ldh a, [$9d]
    ld l, a
    ldh a, [$9e]
    ld h, a
    ld a, l
    sub $08
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ldh a, [$93]
    cp h
    ret c

    ldh a, [$92]
    cp l
    ret nz

    ld a, $00
    ldh [$91], a
    ld a, l
    ldh [$92], a
    ld a, h
    ldh [$93], a
    ld hl, $0b09
    rst $10
    ret


RetIfScrollActive:
    ldh a, [$96]
    or a
    ret nz

    ldh a, [$95]
    cp $08
    ret nz

    ld a, $00
    ldh [$94], a
    ld a, $08
    ldh [$95], a
    ld a, $00
    ldh [$96], a
    ld hl, $0b09
    rst $10
    ret


GetScrollPosition2:
    ldh a, [$9f]
    ld l, a
    ldh a, [$a0]
    ld h, a
    ld a, l
    sub $08
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ldh a, [$96]
    cp h
    ret c

    ldh a, [$95]
    cp l
    ret nz

    ld a, $00
    ldh [$94], a
    ld a, l
    ldh [$95], a
    ld a, h
    ldh [$96], a
    ld hl, $0b09
    rst $10
    ret


; CheckSpecialMapExits: Z when wMapID is a walkable special room of a gate floor —
; the forest maze MAP_MAZEWOD $53 and its other rooms $61-$64 (one screen each, joined
; by edge exits; dwm/map_names' old "Forest Maze Gate Floor 1-4" was a misnomer), the
; conveyor mazes MAP_SLDFLR1-3 $54-$56 and Maze 1-3 $57-$59 (S131; bank $0B runs
; EncounterStep per step in the same rooms, Jump_00b_4674).
CheckSpecialMapExits:
    ld a, [wMapID]
    cp MAP_MAZEWOD
    ret z

    cp $61
    ret z

    cp $62
    ret z

    cp $63
    ret z

    cp $64
    ret z

    cp MAP_SLDFLR1
    ret z

    cp MAP_SLDFLR2
    ret z

    cp MAP_SLDFLR3
    ret z

    cp MAP_MAZE1
    ret z

    cp MAP_MAZE2
    ret z

    cp MAP_MAZE3
    ret z

    ret


CheckGateworldField:
    ld a, [wInGateworld]
    or a
    jr nz, jr_001_551a

    call CheckSpecialMapExits
    ret nz

jr_001_551a:
    ld a, [$c850]
    or a
    ret nz

    ld a, [wGameState]
    bit 6, a
    ret nz

    bit 2, a
    ret nz

    bit 0, a
    ret nz

    ld a, [$ca3b]
    ld l, a
    ld a, [$ca3c]
    ld h, a
    dec hl
    ld a, l
    ld [$ca3b], a
    ld a, h
    ld [$ca3c], a
    ld a, h
    or l
    jr nz, jr_001_555d

    ld hl, $0064
    ld a, l
    ld [$ca3b], a
    ld a, h
    ld [$ca3c], a
    ld a, [$ca8e]
    call RetIfInvalidFF
    ld a, [$ca8f]
    call RetIfInvalidFF
    ld a, [$ca90]
    call RetIfInvalidFF

jr_001_555d:
    ld a, [$ca3d]
    ld l, a
    ld a, [$ca3e]
    ld h, a
    dec hl
    ld a, l
    ld [$ca3d], a
    ld a, h
    ld [$ca3e], a
    ld a, h
    or l
    jr nz, jr_001_558b

    ld hl, $0014
    ld a, l
    ld [$ca3d], a
    ld a, h
    ld [$ca3e], a
    ld b, $14
    ld c, $00

jr_001_5581:
    push bc
    ld a, c
    call RetIfInvalidFF_2
    pop bc
    inc c
    dec b
    jr nz, jr_001_5581

jr_001_558b:
    ret


RetIfInvalidFF:
    cp $ff
    ret z

    ld hl, $cac1
    call GetMonsterDataPtr
    ld a, [hl]
    cp $02
    ret nz

    ld a, l
    add $4a
    ld l, a
    ld a, h
    adc $00
    ld h, a
    bit 7, [hl]
    ret nz

    ld a, l
    add $16
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    or a
    ret z

    dec [hl]
    ret


RetIfInvalidFF_2:
    cp $ff
    ret z

    ld hl, $cac1
    call GetMonsterDataPtr
    ld a, [hl]
    cp $01
    ret nz

    ld a, l
    add $4a
    ld l, a
    ld a, h
    adc $00
    ld h, a
    bit 7, [hl]
    ret nz

    ld a, l
    add $16
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    cp $ff
    ret z

    inc [hl]
    ret


; ===========================================================================
; StepTrigger dispatcher (S98 correction — NOT an A-press/NPC handler)
; ===========================================================================
; Runs on EVERY tile change (the bank $01 movement path, right after bank
; $0B Entry 6's exit check). Copies the player's OWN position ($FF92-$FF96)
; to the probe HRAM $FFDB-$FFDE and calls bank $0B entry 5
; (RoomEntry5_StepTriggerLookup): a $9x STEP-ON trigger in the interact block
; at the player's cell returns its script index (PyBoy S98: walking onto a
; custom-room $90 cell opens its text; warping onto it does not). A presses
; go through bank $06 -> bank $0B entry 4 instead (NPCs + $8x examine spots).
;
; If a trigger is found ($FFD5 != $FF):
;   1. $D8D4 ← script_id (from NPC ROM data byte 4)
;   2. $D8D3 ← wMapID (current map type)
;   3. $D8D7 ← 0 (clear script state)
;   4. Calls bank $04 entry 5 (ScriptInit) to begin script execution
;   5. If script produced text (bit 1 of $D8D7): sets up text display mode
;
; This is the bridge between player input and the script engine.
; ===========================================================================
CopyPlayerCoordsAndGetNextRoom:
    ldh a, [$92]             ; Player position (from HRAM)
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, l
    ldh [$db], a             ; probe X = player X (own cell, not facing)
    ld a, h
    ldh [$dc], a             ; probe X high
    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, l
    ldh [$dd], a             ; probe Y = player Y
    ld a, h
    ldh [$de], a             ; probe Y high
    ld hl, $0b05             ; Bank $0B entry 5: $9x step-on trigger at the player cell
    rst $10                  ; Returns script_id in $FFD5 ($FF if none)
    ldh a, [$d5]             ; Read script_id result
    cp $ff
    ret z                    ; No NPC found → return

    ld [wScriptNPCId], a            ; ★ trigger's script index -> script engine
    ld a, [wMapID]
    ld [wScriptMapType], a            ; Store map type for script bank selection
    xor a
    ld [wScriptStateFlags], a            ; Clear script state flags
    ld hl, $0405             ; Bank $04 entry 5: ScriptInit
    rst $10                  ; Execute NPC script (may queue text)
    ld a, [wScriptStateFlags]
    or a
    ret z                    ; Script produced nothing → return

    bit 1, a
    ret z                    ; No text queued → return

    ; Script queued text → set up text display mode
    ld hl, $ffff
    ld a, l
    ld [$c917], a
    ld a, h
    ld [$c918], a
    ld hl, wGameState
    set 0, [hl]              ; Enable text display mode
    xor a
    ld [$c915], a
    ld [$c916], a
    ret


CalcGateDataOffset:
    ld a, [$ca37]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ld a, l
    add $73
    ld l, a
    ld a, h
    adc $c9
    ld h, a
    ldh a, [$92]
    ld [hl+], a
    ldh a, [$95]
    ld [hl+], a
    ldh a, [$93]
    swap a
    ld c, a
    ldh a, [$96]
    or c
    ld [hl+], a
    ldh a, [$8b]
    ld c, a
    ldh a, [$8d]
    or c
    ld [hl+], a
    ld a, [$ca37]
    inc a
    ld [$ca37], a
    cp $31
    ret c

    xor a
    ld [$ca37], a
    ret


CheckScriptBeforeAction:
    ld a, [wScriptStateFlags]
    or a
    jr nz, jr_001_5690

    ld a, [wInGateworld]
    or a
    jr nz, jr_001_568c

    call ArenaMapID          ; S128: was ld a, [wMapID] — your arena copies count as $06 / $5D
    cp MAP_BATTLE1 ;arena entrance
    jr z, jr_001_5690

    cp MAP_BTLDEMO
    jr z, jr_001_5690

    ld a, [$d92b]
    cp $07
    jr nz, jr_001_568c

    ld a, [$da09]
    cp $03
    jr nz, jr_001_568c

    ld a, [$c8ed]
    cp $0e
    jr nz, jr_001_568c

    jr jr_001_5690

jr_001_568c:
    xor a
    ld [$c8ed], a

jr_001_5690:
    ld a, [$c8ec]
    or a
    ret nz

    ld a, [wGameState]
    bit 1, a
    ret nz

    bit 3, a
    ret nz

    bit 7, a
    ret nz

    bit 4, a
    jr z, jr_001_56ab

    ld a, [$c8ef]
    cp $0f
    ret z

; The PLAYER's sprite (S121 trace): HRAM $FFC3-$FFCA <- X ($FF92/93), Y + 8
; ($FF95/96), sprite type $FF8A (0 = the player shape), frame $FF8B (0-5 = down
; A/B, side A/B, up A/B; side frames face RIGHT, OAM attr $FF8D bit 5 = X-flip
; for left), tile base $FF8C, attr $FF8D; then `ld hl, $0402 / rst $10` below:
; bank $04 entry 2 builds it (type < $10: palette data_4157, frames data_4137).
jr_001_56ab:
    ldh a, [$90]
    bit 6, a
    ret nz

    ld hl, $ffc3
    ldh a, [$92]
    ld [hl+], a
    ldh a, [$93]
    ld [hl+], a
    ldh a, [$95]
    add $08
    ld [hl+], a
    ldh a, [$96]
    adc $00
    ld [hl+], a
    ldh a, [$8a]
    ld [hl+], a
    ldh a, [$8b]
    ld [hl+], a
    ldh a, [$8c]
    ld [hl+], a
    ldh a, [$8d]
    ld [hl], a
    ldh a, [$c8]
    cp $ff
    ret z

    ld a, [$c8ed]
    bit 0, a
    jr nz, jr_001_56df

    ld hl, $0402
    rst $10

jr_001_56df:
    ld a, [$ca8d]
    cp $00
    ret z

    ld a, [$ca91]
    ldh [$c7], a
    ld a, $20
    ldh [$c9], a
    ld b, $10
    ld a, [$c8ed]
    bit 1, a
    call z, AdjustGateFloorIndex
    ld a, [$ca8d]
    cp $01
    ret z

    ld a, [$ca92]
    ldh [$c7], a
    ld a, $30
    ldh [$c9], a
    ld b, $20
    ld a, [$c8ed]
    bit 2, a
    call z, AdjustGateFloorIndex
    ld a, [$ca8d]
    cp $02
    ret z

    ld a, [$ca93]
    ldh [$c7], a
    ld a, $40
    ldh [$c9], a
    ld b, $30
    ld a, [$c8ed]
    bit 3, a
    call z, AdjustGateFloorIndex
    ret


AdjustGateFloorIndex:
    ld a, [$ca37]
    sub b
    jr nc, jr_001_5733

    add $31

jr_001_5733:
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ld a, l
    add $73
    ld l, a
    ld a, h
    adc $c9
    ld h, a
    ld e, l
    ld d, h
    ld hl, $ffc3
    ld a, [de]
    ld [hl+], a
    inc de
    inc de
    ld a, [de]
    swap a
    and $0f
    ld [hl+], a
    dec de
    ld a, [de]
    inc de
    add $08
    ld [hl+], a
    ld a, [de]
    inc de
    adc $00
    and $0f
    ld [hl+], a
    inc hl
    ld a, [de]
    and $0f
    ld [hl+], a
    inc hl
    ld a, [de]
    and $f0
    ld [hl+], a
    inc de
    call CheckNPCMovement
    ld hl, $0402
    rst $10
    ret


CheckNPCMovement:
    ld a, [$d7b8]
    cp $00
    jr z, jr_001_578b

    cp $01
    jr z, jr_001_578b

    cp $02
    jr z, jr_001_578b

    cp $03
    jr z, jr_001_578b

    cp $04
    jr z, jr_001_578b

    cp $05
    jr z, jr_001_578b

    ret


jr_001_578b:
    ldh a, [$c8]
    and $fe
    ld b, a
    ldh a, [$8b]
    and $01
    add b
    ldh [$c8], a
    ret


CallBank06AndProcess:
    ld hl, $0600
    rst $10
    call RetIfNotGateworld
    ld hl, $ff90
    bit 5, [hl]
    jr nz, jr_001_57ab

    xor a
    ld [$d7bc], a
    ret


jr_001_57ab:
    ld a, [$d7bc]
    inc a
    ld [$d7bc], a
    cp $02
    jp nz, Jump_001_5921

    xor a
    ld [$d7bc], a
    xor a
    ldh [$a1], a
    ldh [$a2], a
    xor a
    ldh [$a3], a
    ldh [$a4], a
    ld hl, $ff90
    res 0, [hl]
    ldh a, [$92]
    and $f0
    add $08
    ldh [$92], a
    ldh a, [$95]
    and $f0
    add $08
    ldh [$95], a
    ldh a, [$92]
    ldh [$a5], a
    ldh a, [$93]
    ldh [$a6], a
    ldh a, [$95]
    ldh [$a7], a
    ldh a, [$96]
    ldh [$a8], a
    call TileAtPixel
    ldh a, [$a9]
    cp $ff
    jr z, jr_001_57fc

    ld hl, $0600
    rst $10
    ldh a, [$90]
    bit 5, a
    ret z

jr_001_57fc:
    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    ldh a, [$92]
    ldh [$a5], a
    ldh a, [$93]
    ldh [$a6], a
    call TileAtPixel
    ldh a, [$a9]
    cp $ff
    jr z, jr_001_5852

    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$95], a
    ld a, h
    ldh [$96], a
    ld hl, $0600
    rst $10
    ldh a, [$90]
    bit 5, a
    ret z

    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, l
    sub $10
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld a, l
    ldh [$95], a
    ld a, h
    ldh [$96], a

jr_001_5852:
    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, l
    sub $10
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    ldh a, [$92]
    ldh [$a5], a
    ldh a, [$93]
    ldh [$a6], a
    call TileAtPixel
    ldh a, [$a9]
    cp $ff
    jr z, jr_001_58a8

    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, l
    sub $10
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld a, l
    ldh [$95], a
    ld a, h
    ldh [$96], a
    ld hl, $0600
    rst $10
    ldh a, [$90]
    bit 5, a
    ret z

    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$95], a
    ld a, h
    ldh [$96], a

jr_001_58a8:
    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, l
    sub $10
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ldh a, [$95]
    ldh [$a7], a
    ldh a, [$96]
    ldh [$a8], a
    call TileAtPixel
    ldh a, [$a9]
    cp $ff
    jr z, jr_001_58fe

    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, l
    sub $10
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld a, l
    ldh [$92], a
    ld a, h
    ldh [$93], a
    ld hl, $0600
    rst $10
    ldh a, [$90]
    bit 5, a
    ret z

    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$92], a
    ld a, h
    ldh [$93], a

jr_001_58fe:
    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$92], a
    ld a, h
    ldh [$93], a
    ld hl, $0600
    rst $10
    ldh a, [$90]
    bit 5, a
    jr nz, jr_001_58fe

    ret


    xor a
    ld [$d7bc], a

Jump_001_5921:
    ldh a, [$99]
    ldh [$92], a
    ldh a, [$9a]
    ldh [$93], a
    ldh a, [$9b]
    ldh [$95], a
    ldh a, [$9c]
    ldh [$96], a
    call LoadNPCDataTable2
    ret


LoadNPCDataTable2:
    ld hl, $d7d2

jr_001_5938:
    ld a, [hl]
    cp $ff
    ret z

    call AdvanceNPCPointer
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_001_5938

    ret


; S97 annotation: per NPC slot (HL = slot) — if bank $06 entry 0 flagged the
; slot as blocked by the player (+$05 bit 5) and its PREVIOUS position
; (+$1C..+$1F, copied from +$18..+$1B every frame by LoadNPCDataTable) is
; tile-aligned, the current position +$18..+$1B is restored from it (the NPC's
; step is undone) and the pause timer +$07 := $20. Measured S97: a walker
; whose next tile holds the player waits there.
AdvanceNPCPointer:
    push hl
    ld a, l
    add $05
    ld l, a
    ld a, h
    adc $00
    ld h, a
    bit 5, [hl]
    jr z, jr_001_599c

    ld a, l
    add $13
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld e, l
    ld d, h
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hl+]
    and $0f
    cp $08
    jr nz, jr_001_599c

    inc hl
    ld a, [hl-]
    and $0f
    cp $08
    jr nz, jr_001_599c

    dec hl
    ld a, [hl+]
    ld [de], a
    ld c, a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    ld b, a
    inc de
    ld a, [hl]
    ld [de], a
    ld a, c
    and $0f
    cp $08
    jr nz, jr_001_599c

    ld a, b
    and $0f
    cp $08
    jr nz, jr_001_599c

    pop hl
    push hl
    ld a, l
    add $07
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld [hl], $20

jr_001_599c:
    pop hl
    ret


    ldh a, [$8a]
    ld [$d7b7], a
    ld a, l
    ld [$d7b8], a
    ld a, h
    ld [$d7b9], a
    ld hl, $d7b6
    ld a, l
    ld [$d7b4], a
    ld a, h
    ld [$d7b5], a
    xor a
    ld [$d7b6], a
    ld hl, $0200
    rst $10
    ld a, [$d7ba]
    ldh [$8b], a
    ret


RetIfNotGateworld:
    ld a, [wInGateworld]
    or a
    ret z

    ld hl, $d793

jr_001_59cc:
    ld a, [hl]
    cp $ff
    ret z

    push hl
    and $f8
    jr z, jr_001_59f3

    bit 7, a
    jr nz, jr_001_59f3

    inc hl
    inc hl
    ld de, $ff92
    call SwapNibbles
    jr nc, jr_001_59f3

    inc hl
    ld de, $ff95
    call SwapNibbles
    jr nc, jr_001_59f3

    pop hl
    ld hl, $ff90
    set 5, [hl]
    ret


jr_001_59f3:
    pop hl
    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_001_59cc

SwapNibbles:
    ld a, [hl]
    swap a
    ld b, a
    and $f0
    or $08
    ld c, a
    ld a, b
    and $0f
    ld b, a
    ld a, [de]
    inc de
    sub c
    ld c, a
    ld a, [de]
    sbc b
    ld b, a
    bit 7, b
    jr z, jr_001_5a20

    ld a, c
    cpl
    add $01
    ld c, a
    ld a, b
    cpl
    adc $00
    ld b, a

jr_001_5a20:
    ld a, c
    sub $10
    ld c, a
    ld a, b
    sbc $00
    ld b, a
    ret


RetIfNotGateworld2:
    ld a, [wInGateworld]
    or a
    ret z

    ld a, [$d793]
    cp $ff
    ret z

    ld hl, $d793

jr_001_5a37:
    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    bit 7, a
    ret z

    cp $ff
    jr nz, jr_001_5a37

    ld a, $04
    ld [$c92d], a
    ret


RetIfNotGateworld3:
    ld a, [wInGateworld]
    or a
    ret z

    ld a, [$c92e]
    inc a
    ld [$c92e], a
    cp $c8
    ret c

    xor a
    ld [$c92e], a
    ld a, $07
    ld [$c92d], a
    ret


CopyPlayerCoordsToHRAM:
    ldh a, [$97]
    ldh [$db], a
    ldh a, [$98]
    ldh [$dd], a
    xor a
    ld [$d78f], a

CheckFieldMovementAllowed:
    ld a, [$c850]
    or a
    ret nz

    ld a, [wInGateworld]
    or a
    ret z

    ld hl, $d793

jr_001_5a7f:
    ld a, [hl]
    cp $ff
    ret z

    push hl
    bit 7, a
    jr nz, jr_001_5aa0

    ld a, [$d78f]
    or a
    jr z, jr_001_5a93

    ld a, [hl]
    and $78
    jr z, jr_001_5aa0

jr_001_5a93:
    inc hl
    inc hl
    ldh a, [$db]
    cp [hl]
    jr nz, jr_001_5aa0

    inc hl
    ldh a, [$dd]
    cp [hl]
    jr z, jr_001_5aab

jr_001_5aa0:
    pop hl
    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_001_5a7f

jr_001_5aab:
    xor a
    ld [$c92e], a
    pop hl
    inc hl
    ld a, [hl]
    ld [$d78f], a
    dec hl
    cp $ff
    jp z, Jump_001_5b57

    cp $00
    jp nz, Jump_001_5b43

    push hl
    ld hl, $010d
    rst $10
    ld a, [wBossTileset]
    cp $01
    jr nz, jr_001_5ae0

    ld a, [wRNG1]
    ld b, a
    ld a, $0d
    call Div8x8
    add $07
    ld [wGroundItemData], a
    xor a
    ld [$d792], a
    jr jr_001_5b22

jr_001_5ae0:
    cp $02
    jr nz, jr_001_5af8

    ld a, [wRNG1]
    ld b, a
    ld a, $1e
    call Div8x8
    add $28
    ld [wGroundItemData], a
    xor a
    ld [$d792], a
    jr jr_001_5b22

jr_001_5af8:
    ld a, [wEncounterPoolIndex]   ; the gold lying on depth-tier-3 gate floors:
    add $0a                       ;   (pool + 10) * (floor + 1) * (50..99) / 100 —
    ld c, a                       ;   wEncounterPoolIndex's one reader besides the
    ld a, [wCurrentFloor]         ;   list fetch (S114: EncResolve keeps the
    inc a                         ;   floor's VANILLA pool number here)
    call Mul8x8To16
    push hl
    ld a, [wRNG1]
    ld b, a
    ld a, $32
    call Div8x8
    add $32
    pop bc
    call Mul16x8To24
    ld a, $64
    call Div24x8To16
    ld a, l
    ld [wGroundItemData], a
    ld a, h
    ld [$d792], a

jr_001_5b22:
    ld hl, wGroundItemData
    ld a, [wCurrGoldLo]
    add [hl]
    ld e, a
    inc hl
    ld a, [wCurrGoldMid]
    adc [hl]
    ld d, a
    inc hl
    ld a, [wCurrGoldHi]
    adc $00
    ld c, a
    pop hl
    ld a, e
    sub $a0
    ld a, d
    sbc $86
    ld a, c
    sbc $01
    jr jr_001_5b57

Jump_001_5b43:
    ld de, wInventory
    ld b, $14

jr_001_5b48:
    ld a, [de]
    or a
    jr z, jr_001_5b57

    cp $ff
    jr z, jr_001_5b57

    inc de
    dec b
    jr nz, jr_001_5b48

    jp Jump_001_5bfd


Jump_001_5b57:
jr_001_5b57:
    set 7, [hl]
    ld a, [hl]
    and $78
    jr z, jr_001_5b68

    set 5, [hl]
    inc hl
    ld [hl], $20
    ld a, $53
    call PlaySoundEffect

jr_001_5b68:
    ld a, [$d78f]
    cp $ff
    jr nz, jr_001_5b87

    ld hl, wGameState
    set 0, [hl]
    xor a
    ld [$c915], a
    ld [$c916], a
    ld hl, $0217
    ld a, l
    ld [$c917], a
    ld a, h
    ld [$c918], a
    ret


jr_001_5b87:
    or a
    jr nz, jr_001_5bc3

    ld hl, wGameState
    set 0, [hl]
    xor a
    ld [$c915], a
    ld [$c916], a
    ld a, [wGroundItemData]
    ldh [$d5], a
    ld a, [$d792]
    ldh [$d6], a
    ld a, $00
    ldh [$d7], a
    ld hl, $c180
    call FormatLargeNumber
    ld hl, $0215
    ld a, l
    ld [$c917], a
    ld a, h
    ld [$c918], a
    ld a, [wGroundItemData]
    ld l, a
    ld a, [$d792]
    ld h, a
    ld e, $00
    call CompareGold
    ret


jr_001_5bc3:
    ld hl, wGameState
    set 0, [hl]
    xor a
    ld [$c915], a
    ld [$c916], a
    ld a, [$d78f]
    ld l, a
    ld h, $08
    ld de, $c180
    call SetupVRAMParams
    ld hl, $0208
    ld a, l
    ld [$c917], a
    ld a, h
    ld [$c918], a
    ld hl, wInventory
    ld b, $14

jr_001_5beb:
    ld a, [hl]
    or a
    jr z, jr_001_5bf3

    cp $ff
    jr nz, jr_001_5bf8

jr_001_5bf3:
    ld a, [$d78f]
    ld [hl], a
    ret


jr_001_5bf8:
    inc hl
    dec b
    jr nz, jr_001_5beb

    ret


Jump_001_5bfd:
    ld a, [hl]
    and $78
    jr z, jr_001_5c09

    set 5, [hl]
    ld a, $53
    call PlaySoundEffect

jr_001_5c09:
    ld hl, wGameState
    set 0, [hl]
    xor a
    ld [$c915], a
    ld [$c916], a
    ld a, [$d78f]
    ld l, a
    ld h, $08
    ld de, $c180
    call SetupVRAMParams
    ld hl, $0211
    ld a, l
    ld [$c917], a
    ld a, h
    ld [$c918], a
    ret


    ld a, [hl]
    and $78
    jr z, jr_001_5c39

    set 5, [hl]
    ld a, $53
    call PlaySoundEffect

jr_001_5c39:
    ld hl, wGameState
    set 0, [hl]
    xor a
    ld [$c915], a
    ld [$c916], a
    ld a, [wGroundItemData]
    ldh [$d5], a
    ld a, [$d792]
    ldh [$d6], a
    ld a, $00
    ldh [$d7], a
    ld hl, $c180
    call FormatLargeNumber
    ld hl, $0216
    ld a, l
    ld [$c917], a
    ld a, h
    ld [$c918], a
    ret


CheckOverworldVsGate:
    ld a, [wInGateworld]
    or a
    jr nz, jr_001_5c6f

    call CheckSpecialMapExits
    ret nz

jr_001_5c6f:
    ld a, [$c850]
    or a
    ret nz

    ld a, [wGameState]
    bit 5, a
    ret nz

    bit 6, a
    ret nz

    bit 2, a
    ret nz

    bit 0, a
    ret nz

    ld a, [$ca3b]
    ld l, a
    ld a, [$ca3c]
    ld h, a
    ld a, $0a
    call Div16x8To16
    cp $01
    jr nz, jr_001_5cac

    ld hl, $0001
    ld a, $00
    call ComparePartySlotCount
    ld a, $01
    call ComparePartySlotCount
    ld a, $02
    call ComparePartySlotCount
    call UpdateOAMSprites
    call GetBGMapAddress

jr_001_5cac:
    ld a, [$ca3b]
    ld l, a
    ld a, [$ca3c]
    ld h, a
    ld a, $05
    call Div16x8To16
    cp $04
    jr nz, jr_001_5cd2

    ld a, $00
    call CheckInteractionBit
    ld a, $01
    call CheckInteractionBit
    ld a, $02
    call CheckInteractionBit
    call UpdateOAMSprites
    call GetBGMapAddress

jr_001_5cd2:
    ret


ComparePartySlotCount:
    ld b, a
    ld a, [$ca8d]
    cp b
    ret z

    ret c

    ld a, b
    push bc
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    bit 0, [hl]
    pop bc
    ret nz

    push bc
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    bit 7, [hl]
    pop bc
    ret nz

    ld a, b
    ld hl, $0001
    call GetMonsterSlotAndPush
    ret


    ld b, a
    ldh a, [$90]
    bit 1, a
    ret nz

    ld a, [$ca8d]
    cp b
    ret z

    ret c

    ld a, b
    push bc
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    bit 0, [hl]
    pop bc
    ret z

    push bc
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    bit 7, [hl]
    pop bc
    ret nz

    ld a, b
    ld hl, $0001
    call GetMonsterHPContext
    ld a, $6c
    call PlaySoundEffect
    ld a, $08
    ld [$c8a8], a
    ld a, $2d
    ld [wBGPalette], a
    ret


CheckInteractionBit:
    ld b, a
    ldh a, [$90]
    bit 1, a
    ret nz

    ld a, [$ca8d]
    cp b
    ret z

    ret c

    ld a, b
    push bc
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    bit 2, [hl]
    pop bc
    ret z

    push bc
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    bit 7, [hl]
    pop bc
    ret nz

    ld a, b
    ld hl, $0001
    call GetMonsterLevelPtr
    ld a, $6c
    call PlaySoundEffect
    ld a, $08
    ld [$c8a8], a
    ld a, $2d
    ld [wBGPalette], a
    ret


CheckNPCInteraction:
    ldh a, [$90]
    bit 7, a
    ret nz

    bit 1, a
    jr z, jr_001_5d9c

    ld hl, $ff90
    res 1, [hl]
    call ConveyorBeltPush
    ldh a, [$90]
    bit 1, a
    ret nz

    ld a, [wGameState]
    bit 2, a
    ret nz

    ld a, $01
    ld [wScriptNPCId], a
    ld a, $54
    ld [wScriptMapType], a
    xor a
    ld [wScriptStateFlags], a
    ld hl, $0405
    rst $10
    ret


; ConveyorBeltPush (S131, was the misnomer CheckGateworldForNPC; PyBoy-measured):
; in the walkable special rooms only (wInGateworld 0 and CheckSpecialMapExits Z —
; in practice the conveyor mazes $54-$56, the only rooms with these tiles) the
; class of the standing cell ($AA >> 2) sets a forced velocity and $FF90 bits 1:0:
; $0F right (X $0100), $10 left (X $FF00), $11 down (Y $0100), $12 up (Y $FF00).
; The player rides until a cell of another class; every cell ridden is an ordinary
; step (bank $0B -> bank $16 EncounterStep, the conveyor drain $50 x RateMod / 64).
; GATE_GENERATION §4.4 "Special rooms (S131)"; editor2/core/dive.py BELT_DIR.
ConveyorBeltPush:
jr_001_5d9c:
    ld a, [wInGateworld]
    or a
    ret nz

    ld a, [$c850]
    cpl
    inc a
    bit 7, a
    ret nz

    ld a, [$c88f]
    or a
    ret nz

    ld a, [wGameState]
    bit 6, a
    ret nz

    bit 2, a
    ret nz

    bit 0, a
    ret nz

    call CheckSpecialMapExits
    ret nz

    ldh a, [$aa]
    srl a
    srl a
    cp $0f
    jr z, BeltRight_5dd5

    cp $10
    jr z, BeltLeft_5de6

    cp $11
    jr z, BeltDown_5df7

    cp $12
    jr z, BeltUp_5e08

    ret


BeltRight_5dd5:
    ld hl, Boot
    ld a, l
    ldh [$a1], a
    ld a, h
    ldh [$a2], a
    ld hl, $ff90
    set 1, [hl]
    set 0, [hl]
    ret


BeltLeft_5de6:
    ld hl, $ff00
    ld a, l
    ldh [$a1], a
    ld a, h
    ldh [$a2], a
    ld hl, $ff90
    set 1, [hl]
    set 0, [hl]
    ret


BeltDown_5df7:
    ld hl, Boot
    ld a, l
    ldh [$a3], a
    ld a, h
    ldh [$a4], a
    ld hl, $ff90
    set 1, [hl]
    set 0, [hl]
    ret


BeltUp_5e08:
    ld hl, $ff00
    ld a, l
    ldh [$a3], a
    ld a, h
    ldh [$a4], a
    ld hl, $ff90                ; $FF90 bits 1:0 = a forced move is running
    set 1, [hl]
    set 0, [hl]
    ret


CheckGateworldForSpawn:
    ld a, [wInGateworld]
    or a
    jr nz, jr_001_5e23

    call CheckSpecialMapExits
    ret nz

jr_001_5e23:
    ld a, [$c850]
    or a
    ret nz

    ld a, [wGameState]
    bit 6, a
    ret nz

    bit 2, a
    ret nz

    bit 0, a
    ret nz

    ld a, [$c93e]
    bit 0, a
    ret nz

    ldh a, [$aa]
    srl a
    srl a
    cp $0e
    jr nz, jr_001_5e7c

    call MapIDClampForPalette       ; ROM0: A=mapID or $16 for custom rooms
    ld hl, $5e7d
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    or a
    jr z, jr_001_5e7c

    ld c, a
    ld l, a
    ld h, $00
    ld a, $00
    call ComparePartySlotCount2
    ld a, $01
    call ComparePartySlotCount2
    ld a, $02
    call ComparePartySlotCount2
    ld a, $6c
    call PlaySoundEffect
    ld a, $08
    ld [$c8a8], a
    ld a, $2d
    ld [wBGPalette], a
    call UpdateOAMSprites
    call GetBGMapAddress

jr_001_5e7c:
    ret


    nop
    nop
    nop
    dec b
    nop
    nop
    ld a, [bc]
    nop
    nop
    nop
    nop
    nop
    ld [bc], a
    nop
    ld [bc], a

Jump_001_5e8c:
    nop

ComparePartySlotCount2:
    ld b, a
    ld a, [$ca8d]
    cp b
    ret z

    ret c

    ld a, b
    push bc
    push hl
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    bit 7, [hl]
    pop hl
    pop bc
    ret nz

    push hl
    ld a, b
    call GetMonsterLevelPtr
    pop hl
    ret


InitNPCMovementZero:
    ld c, $00
    ld a, $00
    call ComparePartySlotCount3
    ld a, $01
    call ComparePartySlotCount3
    ld a, $02
    call ComparePartySlotCount3
    ld a, c
    or a
    ret z

    push bc
    ld c, $00
    ld a, $00
    call ProcessNPCSpriteData
    ld a, $01
    call ProcessNPCSpriteData
    ld a, $02
    call ProcessNPCSpriteData
    ld a, [$ca8d]
    cp c
    pop bc
    jr nz, jr_001_5f01

    call SetupPartyBattleData
    call UpdateOAMSprites
    call GetBGMapAddress
    ld hl, $ff90
    res 1, [hl]
    ld a, $4f
    call SetBGM
    ld hl, $021a
    ld a, l
    ld [$c917], a
    ld a, h
    ld [$c918], a
    ld hl, wGameState
    set 0, [hl]
    xor a
    ld [$c915], a
    ld [$c916], a
    ret


jr_001_5f01:
    ld a, $17
    add c
    ld l, a
    ld h, $02
    ld a, l
    ld [$c917], a
    ld a, h
    ld [$c918], a
    ld hl, wGameState
    set 0, [hl]
    xor a
    ld [$c915], a
    ld [$c916], a
    call SetupPartyBattleData
    call UpdateOAMSprites
    call GetBGMapAddress
    ret


ComparePartySlotCount3:
    ld b, a
    ld a, [$ca8d]
    cp b
    jr z, jr_001_5f74

    jr c, jr_001_5f74

    ld a, b
    push bc
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    bit 7, [hl]
    pop bc
    jr nz, jr_001_5f74

    ld a, b
    push bc
    ld hl, $cb11
    call ReadMonsterWord
    ld a, b
    or c
    pop bc
    jr nz, jr_001_5f74

    ld a, b
    push bc
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    set 7, [hl]
    pop bc
    ld a, c
    push bc
    swap a
    ld hl, $c180
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    ld hl, $cac2
    ld a, b
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    pop hl
    call Copy4Bytes
    pop bc
    inc c
    ld a, $01
    or a
    ret


jr_001_5f74:
    xor a
    ret


ProcessNPCSpriteData:
    ld b, a
    ld a, [$ca8d]
    cp b
    ret z

    ret c

    ld a, b
    push bc
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    bit 7, [hl]
    pop bc
    ret z

    inc c
    ret


CheckFieldEventFlag:
    ld a, [$c8ec]
    or a
    ret nz

    ld a, [wGameState]
    bit 1, a
    ret nz

    bit 3, a
    ret nz

    bit 7, a
    ret nz

    bit 4, a
    jr z, jr_001_5fa6

    ld a, [$c8ef]
    cp $0f
    ret z

jr_001_5fa6:
    ld a, [wInGateworld]
    or a
    ret z

    ld de, $d793

jr_001_5fae:
    ld a, [de]
    cp $ff
    ret z

    push de
    call CheckDirectionBit7
    pop de
    ld a, e
    add $04
    ld e, a
    ld a, d
    adc $00
    ld d, a
    jr jr_001_5fae

CheckDirectionBit7:
    bit 7, a
    jr z, jr_001_5fde

    and $78
    ret z

    inc de
    ld a, [de]
    or a
    ret z

    ld a, [wGameState]
    bit 0, a
    jr nz, jr_001_5fdd

    bit 6, a
    jr nz, jr_001_5fdd

    ld a, [de]
    dec a
    ld [de], a
    and $01
    ret z

jr_001_5fdd:
    dec de

jr_001_5fde:
    ld a, [de]
    and $7f
    ld c, a
    inc de
    ld a, [de]
    ld b, a
    inc de
    ld a, c
    cp $08
    jr nc, jr_001_5ff6

    ld a, b
    ld hl, $60b7
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]

jr_001_5ff6:
    push af
    ld hl, $6037
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ldh [$c9], a
    pop af
    ld hl, $6077
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ldh [$ca], a
    ld hl, $ffc3
    ld a, [de]
    swap a
    ld c, a
    and $f0
    ld [hl+], a
    ld a, c
    and $0f
    ld [hl+], a
    inc de
    ld a, [de]
    swap a
    ld c, a
    and $f0
    ld [hl+], a
    ld a, c
    and $0f
    ld [hl+], a
    ld a, $01
    ldh [$c7], a
    ld a, $00
    ldh [$c8], a
    ld hl, $0400
    rst $10
    ret


    ld d, b
    ld d, h
    ld e, b
    ld e, h
    ld h, b
    ld h, h
    ld l, b
    ld l, h
    jr jr_001_6059

    jr jr_001_605b

    jr jr_001_605d

    jr jr_001_605f

    jr jr_001_6061

    jr jr_001_6063

    jr jr_001_6065

    jr jr_001_6067

    jr jr_001_6069

    jr jr_001_606b

    jr jr_001_606d

    jr jr_001_606f

    inc e
    inc e

jr_001_6059:
    inc e
    inc e

jr_001_605b:
    inc e
    inc e

jr_001_605d:
    inc e
    inc e

jr_001_605f:
    inc e
    inc e

jr_001_6061:
    inc e
    inc e

jr_001_6063:
    inc e
    inc e

jr_001_6065:
    inc e
    inc e

jr_001_6067:
    inc e
    inc e

jr_001_6069:
    inc e
    inc e

jr_001_606b:
    inc e
    inc e

jr_001_606d:
    inc e
    inc e

jr_001_606f:
    inc e
    inc e
    inc e
    inc e
    inc e
    inc e
    inc e
    inc e
    ld bc, $0602
    rlca
    nop
    rlca
    inc bc
    inc bc
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rlca
    nop
    ld bc, Boot
    ld bc, $0001
    nop
    ld [bc], a
    nop
    ld bc, $0300
    inc bc
    inc bc
    inc bc
    inc bc
    inc bc
    inc b
    inc b
    inc b
    inc b
    inc b
    dec b
    dec b
    dec b
    dec b
    dec b
    ld b, $07
    nop
    nop
    nop
    nop
    nop
    nop
    dec b
    nop
    dec b
    ld bc, $0000
    nop
    nop
    dec b
    nop
    dec b

; Per-room VRAM update = ROOM TILE ANIMATION (S99 census: ROOM_DATA_FORMAT
; "Animated tiles", extracted/room_animations.json). Called once per
; MainFieldLoop pass; after its guards it runs map ID's handler through the
; 112-entry rst $00 table at $6119. Handlers ROLL tiles 1 px in place
; (RollTilePairWobble / GreatTreeSway / RollTileRight/Left) or SWAP a shown
; tile with its hidden second frame elsewhere in the sheet (VRAMSwapBytes),
; timed by the field frame counter $C8A6/$C8A7. This is the ONLY BG tile
; animation in the ROM; gate floors never animate (wInGateworld guard).
PerRoomVRAMDispatch:
VisualEffectsDispatch:  ; original label
    ld a, [$c850]
    or a
    ret nz

    ld a, [$c88f]
    or a
    ret nz

    ld a, [wInGateworld]
    or a
    ret nz

    ld a, [wGameState]
    ; --- S99 same-size rewrite ($60F9-$6118, 32 B; the table stays at $6119).
    ; Vanilla tested bits 5,6,2,1,3,7 one `bit/ret nz` at a time (18 B) then
    ; bit 4. One mask does the same: any of bits 1-3,5-7 -> return; bit 4
    ; alone -> the $C8EF check; bit 0 is ignored in both versions. The freed
    ; bytes pay for the custom-room animation source lookup below.
    and $fe                     ; drop bit 0 (never tested)
    jr z, PerRoomDispatchEntry  ; nothing set -> dispatch
    cp $10                      ; only bit 4 set?
    ret nz                      ; any of bits 1-3,5-7 -> no animation this frame

    ld a, [$c8ef]
    cp $0f
    ret z

; The dispatch: A = animation index, then rst $00 on the 112-entry table.
; Vanilla rooms: A = wMapID (vanilla-identical). Custom rooms (>= $6B): bank
; $71 entry 3 CustomAnimSource returns E = the room's animation SOURCE — the
; vanilla map ID whose handler runs (project.json custom.rooms[].animation,
; S99; $6B = the table's own bare-`ret` row = no animation). Replaces the
; S1-era `call MapIDClampForDispatch` (every custom room ran Castle's
; handler — tiles 77-78 rolled in every custom room, clones never animated;
; the "a bare ret corrupts the palette" reason was measured false S99,
; DOC_AUDIT S99). rst $10 clobbers A, so the result comes back in E.
PerRoomDispatchEntry:
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jr c, jr_001_6115           ; vanilla room: index = mapID
    ld hl, $7103                ; bank $71 entry 3: CustomAnimSource
    rst $10
    ld a, e                     ; A = animation source map ID
    nop                         ; pad: rst $00 must sit at $6118 (table base)
    nop
    nop
    nop
    nop
    nop
jr_001_6115:  ; original label (now the rst itself)
    ASSERT @ == $6118, "PerRoomVRAMDispatch rewrite must keep rst $00 at $6118"
    rst $00

    dw label1_61f9
    dw label1_6200
    dw label1_6204
    dw label1_621f
    dw label1_621f
    dw label1_621f
    dw label1_621f
    dw label1_621f
    dw label1_6220
    dw label1_62b2
    dw label1_62b3
    dw label1_62b7
    dw label1_62b7
    dw label1_62b7
    dw label1_62b7

  Jump_001_6137:
    dw label1_62b7
    dw label1_62b8
    dw label1_62b8
    dw label1_62b8
    dw label1_62b8
    dw label1_62b8
    dw label1_62b8
    dw label1_62b8
    dw label1_62b8
    dw label1_62b8
    dw label1_62b9
    dw label1_62b9
    dw label1_62cd
    dw label1_62ce
    dw label1_62e2
    dw label1_62e3
    dw label1_62e4
    dw label1_62e5
    dw label1_62e5
    dw label1_62f9
    dw label1_62fa
    dw label1_630e
    dw label1_630f
    dw label1_6310
    dw label1_6335
    dw label1_6336
    dw label1_633d
    dw label1_6362
    dw label1_6376
    dw label1_6362
    dw label1_6377
    dw label1_637e
    dw label1_639d
    dw label1_63b1
    dw label1_63b8
    dw label1_63b9
    dw label1_63ba
    dw label1_63bb
    dw label1_63bc
    dw label1_63bd
    dw label1_63be
    dw label1_63d2
    dw label1_63d3
    dw label1_63d4
    dw label1_63d5
    dw label1_63d6
    dw label1_63dd
    dw label1_63be
    dw label1_63e4
    dw label1_63f8
    dw label1_63f9
    dw label1_63fa
    dw label1_63fb
    dw label1_63fc
    dw label1_6422
    dw label1_6423
    dw label1_642a
    dw label1_6449
    dw label1_645d
    dw label1_648d
    dw label1_648e
    dw label1_64b4
    dw label1_64b5
    dw label1_64da
    dw label1_64db
    dw label1_64ef
    dw label1_64ef
    dw label1_64f0
    dw label1_6542
    dw label1_6542
    dw label1_6542
    dw label1_6542
    dw label1_6542
    dw label1_6542
    dw label1_6542
    dw label1_6542
    dw label1_6542
    dw label1_6542
    dw label1_6543
    dw label1_659e
    dw label1_659e
    dw label1_63fa
    dw label1_6542
    dw label1_6542
    dw label1_6542
    dw label1_6542
    dw label1_63fa
    dw label1_63fa
    dw label1_63fa
    dw label1_63fa
    dw label1_63fa
    dw label1_63fa
    dw label1_63fa
    dw label1_63fa
    dw label1_63fa
    dw label1_63fa
    dw label1_63fa

; Room animation for map $00 (Castle)
;   ROLL tiles 77-78 1 px sideways every 32 frames (3 right : 1 left per 128)
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_Castle:
Handler_Castle:
label1_61f9:  ; original label
    ld hl, $94d0
    call CheckVisualEffectType
    ret

; Room animation for map $01 (GreatTree)
;   SWAY tiles 64-79: 4-tile groups roll 1 px in alternating directions every 32 frames (direction set flips every 512 frames, $C8A7 bit 1)
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_GreatTree:
Handler_GreatTree:
label1_6200:  ; original label
    call GetVisualEffectMask
    ret

; No room animation: map $02
RoomAnimNone_02:
Handler_Bazaar:
label1_6204:  ; original label
    ret


    ld hl, $9210
    call VRAMRotateRight
    ld hl, $93f0
    call VRAMRotateRight
    ret


    ld hl, $9210
    call VRAMRotateLeft
    ld hl, $93f0
    call VRAMRotateLeft
    ret

; No room animation: maps $03, $04, $05, $06, $07
RoomAnimNone_03:
Handler_GateHub:
label1_621f:  ; original label
    ret

; Map $08 (Starry Shrine breeding cutscene): pulses the DMG palette byte
; wBGPalette from a table on the frame counter — no tile animation (S99)
RoomAnim_StarryShrineCutscenePalette:
Handler_GateHub2_Palette:
label1_6220:  ; original label
    ld a, [$d9cb]
    cp $02
    jp z, $62b1

    or a
    jr nz, jr_001_6260

    ld a, [$c8a6]
    ld l, a
    ld a, [$c8a7]
    ld h, a
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    ld a, l
    and $07
    ld hl, $6258
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [wBGPalette], a
    ret


    db $d2, $d2, $d2, $d1, $c1, $c1, $c1, $d1

jr_001_6260:
    ld a, [$c8a6]
    ld l, a
    ld a, [$c8a7]
    ld h, a
    ld c, l
    ld b, h
    add hl, hl
    add hl, bc
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    ld a, l
    and $1f
    ld hl, $6291
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [wBGPalette], a
    ret


    db $e7, $e7, $e7, $e7, $e7, $e7, $e7, $e6, $e6, $e6, $d2, $d2, $d2, $d1, $d1, $d1
    db $c1, $c1, $c1, $c1, $c1, $c1, $c1, $d1, $d1, $d1, $d2, $d2, $d2, $e6, $e6, $e6


label1_b2b1:
    ret

; No room animation: map $09
RoomAnimNone_09:
Handler_StarryShrine:
label1_62b2:  ; original label
    ret

; Room animation for map $0A (Secret Passage)
;   SWAY tiles 64-79: 4-tile groups roll 1 px in alternating directions every 32 frames (direction set flips every 512 frames, $C8A7 bit 1)
;   map $0A: INERT in vanilla — those slots are blank in its sheet
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_SecretPassage:
Handler_SecretPassage:
label1_62b3:  ; original label
    call GetVisualEffectMask
    ret

; No room animation: maps $0B, $0C, $0D, $0E, $0F
RoomAnimNone_0B:
Handler_RET_Group1:
label1_62b7:  ; original label
    ret

; No room animation: maps $10, $11, $12, $13, $14, $15, $16, $17, $18
RoomAnimNone_10:
Handler_RET_Group2:
label1_62b8:  ; original label
    ret

; Room animation for maps $19, $1A (Goopy Room 1 (scr8); Goopy Room 2 (scr8))
;   SWAP tiles 50-51 <-> 61-62 every 32 frames
;   map $19: INERT in vanilla — those slots are blank in its sheet
;   map $1A: INERT in vanilla — those slots are blank in its sheet
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_GoopyRoom1:
Handler_GoopyRooms:
label1_62b9:  ; original label
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $9320
    ld de, $93d0
    ld b, $20
    call VRAMCopyTile
    ret

; No room animation: map $1B
RoomAnimNone_1B:
label1_62cd:
    ret

; Room animation for map $1C (Stable: Coffin Room)
;   SWAP tiles 36-37 <-> 44-45 every 32 frames
;   placed on screen: 36-37; hidden second frames: 44-45
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_StableCoffinRoom:
label1_62ce:
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $9240
    ld de, $92c0
    ld b, $20
    call VRAMCopyTile
    ret

; No room animation: map $1D
RoomAnimNone_1D:
label1_62e2:
    ret

; No room animation: map $1E
RoomAnimNone_1E:
label1_62e3:
    ret

; No room animation: map $1F
RoomAnimNone_1F:
label1_62e4:
    ret

; Room animation for maps $20, $21 (map $20; map $21)
;   SWAP tiles 50-51 <-> 56-57 every 32 frames
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_Map20:
Handler_Map20:
label1_62e5:  ; original label
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $9320
    ld de, $9380
    ld b, $20
    call VRAMCopyTile
    ret

; No room animation: map $22
RoomAnimNone_22:
label1_62f9:
    ret

; Room animation for map $23 (Room of Beginning)
;   SWAP tiles 19-22 <-> 25-28 every 32 frames
;   placed on screen: 19-22; hidden second frames: 25-28
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_RoomOfBeginning:
label1_62fa:
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $9130
    ld de, $9190
    ld b, $40
    call VRAMCopyTile
    ret

; No room animation: map $24
RoomAnimNone_24:
label1_630e:
    ret

; No room animation: map $25
RoomAnimNone_25:
label1_630f:
    ret

; Room animation for map $26 (Room: Peace/Bravery)
;   SWAP tiles 6-7,22-23 <-> 32-35 every 32 frames
;   ROLL tiles 36-37 1 px sideways every 32 frames (3 right : 1 left per 128)
;   placed on screen: 6-7,22-23,36-37; hidden second frames: 32-35
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_RoomPeaceBravery:
label1_6310:
    ld hl, $9240
    call CheckVisualEffectType
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $9060
    ld de, $9200
    ld b, $20
    call VRAMCopyTile
    ld hl, $9160
    ld de, $9220
    ld b, $20
    call VRAMCopyTile
    ret

; No room animation: map $27
RoomAnimNone_27:
label1_6335:
    ret

; Room animation for map $28 (Room: Joy/Wisdom)
;   ROLL tiles 37-38 1 px sideways every 32 frames (3 right : 1 left per 128)
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_RoomJoyWisdom:
label1_6336:
    ld hl, $9250
    call CheckVisualEffectType
    ret

; Room animation for map $29 (Room: Happiness/Temptation)
;   SWAP tiles 6-7,14-15 <-> 12-13,22-23 every 32 frames
;   ROLL tiles 10-11 1 px sideways every 32 frames (3 right : 1 left per 128)
;   placed on screen: 6-7,10-11,22-23; hidden second frames: 12-15
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_RoomHappinessTemptation:
label1_633d:
    ld hl, $90a0
    call CheckVisualEffectType
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $9060
    ld de, $90c0
    ld b, $20
    call VRAMCopyTile
    ld hl, $9160
    ld de, $90e0
    ld b, $20
    call VRAMCopyTile
    ret

; Room animation for maps $2A, $2C (Room: Labyrinth/Judgment; Room: Ambition/Demolition)
;   SWAP tiles 6-9 <-> 26-29 every 32 frames
;   placed on screen: 6-9; hidden second frames: 26-29
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_RoomLabyrinthJudgment:
label1_6362:
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $9060
    ld de, $91a0
    ld b, $40
    call VRAMCopyTile
    ret

; No room animation: map $2B
RoomAnimNone_2B:
label1_6376:
    ret

; Room animation for map $2D (Room: Mastermind/Control)
;   ROLL tiles 24-25 1 px sideways every 32 frames (3 right : 1 left per 128)
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_RoomMastermindControl:
label1_6377:
    ld hl, $9180
    call CheckVisualEffectType
    ret

; Room animation for map $2E (Room: Extinction/Sleep)
;   SWAP tiles 6-7,22-23 <-> 32-35 every 32 frames
;   placed on screen: 6-7,22-23; hidden second frames: 32-35
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_RoomExtinctionSleep:
label1_637e:
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $9060
    ld de, $9200
    ld b, $20
    call VRAMCopyTile
    ld hl, $9160
    ld de, $9220
    ld b, $20
    call VRAMCopyTile
    ret

; Room animation for map $2F (Intro Bedroom (2-screen, crashes))
;   SWAP tiles 78 <-> 79 every 32 frames
;   placed on screen: 78; hidden second frames: 79
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_IntroBedroom:
label1_639d:
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $94e0
    ld de, $94f0
    ld b, $10
    call VRAMCopyTile
    ret

; Room animation for map $30 (Boss: Beginning (Healer))
;   ROLL tiles 30-31 1 px sideways every 32 frames (3 right : 1 left per 128)
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossBeginning:
label1_63b1:
    ld hl, $91e0
    call CheckVisualEffectType
    ret

; No room animation: map $31
RoomAnimNone_31:
label1_63b8:
    ret

; No room animation: map $32
RoomAnimNone_32:
label1_63b9:
    ret

; No room animation: map $33
RoomAnimNone_33:
label1_63ba:
    ret

; No room animation: map $34
RoomAnimNone_34:
label1_63bb:
    ret

; No room animation: map $35
RoomAnimNone_35:
label1_63bc:
    ret

; No room animation: map $36
RoomAnimNone_36:
label1_63bd:
    ret

; Room animation for maps $37, $3E (Boss: Bravery (BigEye); Boss: Happiness (Jamirus))
;   SWAP tiles 35 <-> 36 every 32 frames
;   placed on screen: 35; hidden second frames: 36
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossBravery:
label1_63be:
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $9230
    ld de, $9240
    ld b, $10
    call VRAMCopyTile
    ret

; No room animation: map $38
RoomAnimNone_38:
label1_63d2:
    ret

; No room animation: map $39
RoomAnimNone_39:
label1_63d3:
    ret

; No room animation: map $3A
RoomAnimNone_3A:
label1_63d4:
    ret

; No room animation: map $3B
RoomAnimNone_3B:
label1_63d5:
    ret

; Room animation for map $3C (Boss: Anger (BattleRex))
;   ROLL tiles 86-87 1 px sideways every 32 frames (3 right : 1 left per 128)
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossAnger:
label1_63d6:
    ld hl, $9560
    call CheckVisualEffectType
    ret

; Room animation for map $3D (Boss: Arena Left (Digster))
;   ROLL tiles 10-11 1 px sideways every 32 frames (3 right : 1 left per 128)
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossArenaLeft:
label1_63dd:
    ld hl, $90a0
    call CheckVisualEffectType
    ret

; Room animation for map $3F (Boss: Temptation (Servant))
;   SWAP tiles 56-59 <-> 60-63 every 32 frames
;   placed on screen: 56-59; hidden second frames: 60-63
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossTemptation:
label1_63e4:
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $9380
    ld de, $93c0
    ld b, $40
    call VRAMCopyTile
    ret

; No room animation: map $40
RoomAnimNone_40:
label1_63f8:
    ret

; No room animation: map $41
RoomAnimNone_41:
label1_63f9:
    ret

; No room animation: maps $42, $60, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F
RoomAnimNone_42:
label1_63fa:
    ret

; No room animation: map $43
RoomAnimNone_43:
label1_63fb:
    ret

; Room animation for map $44 (Boss: Library (Orochi))
;   SWAP tiles 14 <-> 15 every 64 frames
;   SWAP tiles 30 <-> 31 every 64 frames
;   placed on screen: 14-15; hidden second frames: 30-31
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossLibrary:
label1_63fc:
    ld a, [$c8a6]
    and $3f
    cp $03
    ld hl, $90e0
    ld de, $90f0
    ld b, $10
    call z, VRAMCopyTile
    ld a, [$c8a6]
    and $3f
    cp $23
    ret nz

    ld hl, $91e0
    ld de, $91f0
    ld b, $10
    call VRAMCopyTile
    ret

; No room animation: map $45
RoomAnimNone_45:
label1_6422:
    ret

; Room animation for map $46 (Boss: Ambition (DracoLord))
;   ROLL tiles 70-71 1 px sideways every 32 frames (3 right : 1 left per 128)
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossAmbition:
label1_6423:
    ld hl, $9460
    call CheckVisualEffectType
    ret

; Room animation for map $47 (Boss: Demolition (Hargon/Sidoh))
;   SWAP tiles 76,78 <-> 90-91 every 32 frames
;   placed on screen: 76,78; hidden second frames: 90-91
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossDemolition:
label1_642a:
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $94c0
    ld de, $95a0
    ld b, $10
    call VRAMCopyTile
    ld hl, $94e0
    ld de, $95b0
    ld b, $10
    call VRAMCopyTile
    ret

; Room animation for map $48 (Boss: Mastermind (Baramos))
;   SWAP tiles 25 <-> 26 every 32 frames
;   placed on screen: 25; hidden second frames: 26
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossMastermind:
label1_6449:
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $9190
    ld de, $91a0

VRAMCopyTile16:
    ld b, $10
    call VRAMCopyTile
    ret

; Room animation for map $49 (Boss: Control (Zoma))
;   SWAP tiles 42-43,58-59,64-65 <-> 44-45,60-61,66-67 every 32 frames
;   ROLL tiles 49-50 1 px sideways every 32 frames (3 right : 1 left per 128)
;   placed on screen: 42-43,49-50,58-59,64-65; hidden second frames: 44-45,60-61,66-67
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossControl:
label1_645d:
    ld hl, $9310
    call CheckVisualEffectType
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $92a0
    ld de, $92c0
    ld b, $20
    call VRAMCopyTile
    ld hl, $93a0
    ld de, $93c0
    ld b, $20
    call VRAMCopyTile
    ld hl, $9400
    ld de, $9420
    ld b, $20

VRAMCopyTileAndRet:
    call VRAMCopyTile
    ret

; No room animation: map $4A
RoomAnimNone_4A:
label1_648d:
    ret

; Room animation for map $4B (Boss: Sleep (Esterk))
;   SWAP tiles 12 <-> 13 every 32 frames
;   SWAP tiles 14 <-> 15 every 32 frames
;   placed on screen: 12,14; hidden second frames: 13,15
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossSleep:
label1_648e:
    ld a, [$c8a6]
    and $1f
    cp $03
    ld hl, $90c0
    ld de, $90d0
    ld b, $10
    call z, VRAMCopyTile
    ld a, [$c8a6]
    and $1f
    cp $13
    ret nz

    ld hl, $90e0
    ld de, $90f0
    ld b, $10
    call VRAMCopyTile
    ret

; No room animation: map $4C
RoomAnimNone_4C:
label1_64b4:
    ret

; Room animation for map $4D (Boss: Arena Right (Mudou))
;   SWAP tiles 10-11,32-33 <-> 12-13,34-35 every 32 frames
;   ROLL tiles 52-53 1 px sideways every 32 frames (3 right : 1 left per 128)
;   placed on screen: 10-11,32-33,52-53; hidden second frames: 12-13,34-35
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossArenaRight:
label1_64b5:
    ld hl, $9340
    call CheckVisualEffectType
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $90a0
    ld de, $90c0
    ld b, $20
    call VRAMCopyTile
    ld hl, $9200
    ld de, $9220
    ld b, $20
    call VRAMCopyTile
    ret

; No room animation: map $4E
RoomAnimNone_4E:
label1_64da:
    ret

; Room animation for map $4F (Boss: Unused (DarkDrium))
;   SWAP tiles 92-93 <-> 94-95 every 32 frames
;   placed on screen: 92-93; hidden second frames: 94-95
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_BossUnused:
label1_64db:
    ld a, [$c8a6]
    and $1f
    cp $03
    ret nz

    ld hl, $95c0
    ld de, $95e0
    ld b, $20
    call VRAMCopyTile
    ret

; No room animation: maps $50, $51
RoomAnimNone_50:
label1_64ef:
    ret

; Room animation for map $52 (Gate Floor: Coliseum)
;   SWAP tiles 13,28 <-> 27,29 every 32 frames
;   SWAP tiles 32-33 <-> 34-35 every 25 frames
;   placed on screen: 27-28,32-33; hidden second frames: 13,29,34-35
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_GateFloorColiseum:
label1_64f0:
    ld a, [$c8a6]
    ld l, a
    ld a, [$c8a7]
    ld h, a
    ld a, l
    add $05
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, $20
    call Div16x8To16
    or a
    jr nz, jr_001_651e

    ld hl, $91b0
    ld de, $90d0
    ld b, $10
    call VRAMCopyTile
    ld hl, $91c0
    ld de, $91d0
    ld b, $10
    call VRAMCopyTile

jr_001_651e:
    ld a, [$c8a6]
    ld l, a
    ld a, [$c8a7]
    ld h, a
    ld a, l
    add $0a
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, $19
    call Div16x8To16
    or a
    jr nz, jr_001_6541

    ld hl, $9200
    ld de, $9220
    ld b, $20
    call VRAMCopyTile

jr_001_6541:
    ret

; No room animation: maps $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $61, $62, $63, $64
RoomAnimNone_53:
label1_6542:
    ret

; Room animation for map $5D (Arena Battle)
;   SWAP tiles 60-61 <-> 68-69 every 32 frames
;   SWAP tiles 62-63,74-75 <-> 70-71,82-83 every 32 frames
;   SWAP tiles 72-73 <-> 80-81 every 16 frames
;   (measured S99: tools/census_room_animation.py; ROOM_DATA_FORMAT "Animated tiles")
RoomAnim_ArenaBattle:
label1_6543:
    ld a, [$c8a6]
    and $07
    ret nz

    ld a, [$c8a6]
    ld b, a
    ld a, $38
    call Div8x8
    or a
    jr nz, jr_001_6560

    ld hl, $93c0
    ld de, $9440
    ld b, $20
    call VRAMCopyTile

jr_001_6560:
    ld a, [$c8a6]
    add $08
    ld b, a
    ld a, $20
    call Div8x8
    or a
    jr nz, jr_001_6584

    ld hl, $93e0
    ld de, $9460
    ld b, $20
    call VRAMCopyTile
    ld hl, $9520
    ld de, $94a0
    ld b, $20
    call VRAMCopyTile

jr_001_6584:
    ld a, [$c8a6]
    add $10
    ld b, a
    ld a, $18
    call Div8x8
    or a
    jr nz, jr_001_659d

    ld hl, $9500
    ld de, $9480
    ld b, $20
    call VRAMCopyTile

jr_001_659d:
    ret

; No room animation: maps $5E, $5F
RoomAnimNone_5E:
label1_659e:
    ret


; GreatTree / Secret Passage SWAY (S99, measured): when $C8A6 & $1F == 5
; (every 32 frames) roll tiles 64-79 ($9400-$94FF) 1 px in 4-tile groups of
; alternating direction — R,L,R,L while $C8A7 bit 1 is set, L,R,L,R while
; clear (the set flips every 512 frames): swaying foliage.
GreatTreeSway:
TextHelper_659F:
GetVisualEffectMask:  ; original label
    ld a, [$c8a6]
    and $1f
    cp $05
    jr z, jr_001_65a9

    ret


jr_001_65a9:
    ld a, [$c8a7]
    bit 1, a
    jr z, jr_001_65c8

    ld hl, $9400
    call VRAMEffectStep
    call VRAMEffectSetup
    call VRAMEffectStep

RollTilesLeft4:                 ; roll the 4 tiles at HL 1 px left, HL += $40
VRAMEffectSetup:
    call VRAMRotateLeft
    call VRAMRotateLeft
    call VRAMRotateLeft
    jp Jump_001_668f


jr_001_65c8:
    ld hl, $9400
    call VRAMEffectSetup
    call VRAMEffectStep
    call VRAMEffectSetup

RollTilesRight4:                ; roll the 4 tiles at HL 1 px right, HL += $40
VRAMEffectStep:
    call VRAMRotateRight
    call VRAMRotateRight
    call VRAMRotateRight
    jp Jump_001_6636


; Tile-pair WOBBLE roll (S99, measured): HL = first of 2 tiles. On
; $C8A6 & $7F == $07/$27/$47 roll both tiles 1 px right, on $67 1 px left —
; one step every 32 frames, net 2 px right per 128 (flowing water / flame).
; Used by Castle (77-78) and 9 more rooms (census).
RollTilePairWobble:
TextHelper_65E0:
CheckVisualEffectType:  ; original label
    ld a, [$c8a6]
    and $7f
    cp $07
    jr z, jr_001_65f6

    cp $27
    jr z, jr_001_65f6

    cp $47
    jr z, jr_001_65f6

    cp $67
    jr z, jr_001_65fc

    ret


jr_001_65f6:
    call VRAMRotateRight
    jp Jump_001_6636


jr_001_65fc:
    call VRAMRotateLeft
    jp Jump_001_668f


; VRAM byte SWAP (S99): exchanges B bytes between [HL] and [DE] (VRAM-safe,
; di/WaitVRAM per byte). Room handlers call it every 32 (or 64/25/16) frames
; to flip a shown tile with its hidden second frame — a 2-frame animation
; whose other frame lives in the same 128-tile sheet.
VRAMSwapBytes:
VRAMTileSwap_6602:
VRAMCopyTile:  ; original label
jr_001_6602:
    di
    call WaitVRAM
    ld c, [hl]
    ld a, [de]
    ld [hl+], a
    ld a, c
    ld [de], a
    ei
    inc de
    dec b
    jr nz, jr_001_6602

    ret


CheckPaletteAnimActive:
    ld a, [$c850]
    or a
    ret nz

    ld a, [$c88f]
    or a
    ret nz

    ld a, [wInGateworld]
    or a
    ret nz

    ld a, [wScriptStateFlags]
    or a
    ret nz

    ld a, [wMapID]
    cp $08
    ret nz

    ld a, [$d951]
    cp $07
    ret nz

    ld hl, $0203
    rst $10
    ret


; Roll ONE tile 1 px RIGHT (S99; was mis-described as a one-way copy):
; `rrc` on all 16 bytes at HL (pixels move right, wrapping); HL += 16.
RollTileRight:
VRAMTileCopy_6636:
VRAMRotateRight:  ; original label
Jump_001_6636:
    di
    call WaitVRAM
    rrc [hl]
    inc l
    rrc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rrc [hl]
    inc l
    rrc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rrc [hl]
    inc l
    rrc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rrc [hl]
    inc l
    rrc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rrc [hl]
    inc l
    rrc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rrc [hl]
    inc l
    rrc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rrc [hl]
    inc l
    rrc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rrc [hl]
    inc l
    rrc [hl]
    ei
    inc hl
    ret


; Roll ONE tile 1 px LEFT: `rlc` on all 16 bytes at HL; HL += 16 (S99).
RollTileLeft:
VRAMRotateLeft:
Jump_001_668f:
    di
    call WaitVRAM
    rlc [hl]
    inc l
    rlc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rlc [hl]
    inc l
    rlc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rlc [hl]
    inc l
    rlc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rlc [hl]
    inc l
    rlc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rlc [hl]
    inc l
    rlc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rlc [hl]
    inc l
    rlc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rlc [hl]
    inc l
    rlc [hl]
    ei
    inc hl
    di
    call WaitVRAM
    rlc [hl]
    inc l
    rlc [hl]
    ei
    inc hl
    ret


    ld e, l
    ld d, h
    dec de
    dec de
    di
    call WaitVRAM
    ld c, [hl]
    dec hl
    ld b, [hl]
    inc hl
    ei
    push bc
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl-], a
    dec de
    ei
    pop bc
    di
    call WaitVRAM
    ld [hl], c
    dec hl
    ld [hl], b
    ei
    ret


    ld e, l
    ld d, h
    inc de
    inc de
    di
    call WaitVRAM
    ld c, [hl]
    inc hl
    ld b, [hl]
    dec hl
    ei
    push bc
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    di
    call WaitVRAM
    ld a, [de]
    ld [hl+], a
    inc de
    ei
    pop bc
    di
    call WaitVRAM
    ld [hl], c
    inc hl
    ld [hl], b
    ei
    ret


IncrementEncounterCounter:
    ld a, [$cab5]
    inc a
    ld [$cab5], a
    cp $3c
    ret nz

    xor a
    ld [$cab5], a
    ld a, [$cab6]
    inc a
    ld [$cab6], a
    cp $3c
    ret nz

    xor a
    ld [$cab6], a
    ld a, [$cab7]
    inc a
    ld [$cab7], a
    cp $3c
    ret nz

    xor a
    ld [$cab7], a
    ld a, [$cab8]
    inc a
    ld [$cab8], a
    cp $64
    ret nz

    ld a, $63
    ld [$cab8], a
    ld a, $3b
    ld [$cab7], a
    ld [$cab6], a
    xor a
    ld [$cab5], a
    ret

; Entry 11: Random encounter monster selection
; Reads $CA38 (encounter pool index), calculates pool offset
; Uses weighted random selection ($6989) to pick monsters
; Writes enemy IDs to $DA03/$DA05/$DA07
;
; ENCOUNTER POOL FORMAT (26 bytes each at $6AAE + pool_index × 26; decoded
; S103 from this routine + LoadNextDungeonFloor / LoadFloorAndEncounterData,
; the 2-3 monster rule PyBoy-measured — DATA_STRUCTURES "Encounter pool entry"):
;   +0:  encounter RATE code -> wC8A9 ($C8A9, EncounterRateModifierTable index)
;   +1:  not read by any pool reader (vanilla 1-3)
;   +2..+4: chance CODES for a group of 1 / 2 / 3 monsters -> $DA02
;   +5..+9: chance CODES per EID slot (who is drawn)
;        a code is a percentage via EncounterChancePercent (0,10,20,30,40,50,
;        70,100); LookupEncounterEntry accumulates them into $C0D8 and
;        CalcEncounterPoolIdx draws RNG mod 100 against the running sums
;   +10: EID slots (5 × 2 bytes LE) — enemy stats IDs for this pool
;   +20: MAX COUNT per slot (not a weight): 1 = this monster only ever comes
;        ALONE (a first pick with 1 ends the group), otherwise the 2nd/3rd
;        draw is repeated until a slot's max >= its copies so far (incl. the
;        new one) and != 1 — so 0 = never 2nd/3rd. A pool whose first pick can
;        have max 0 with no slot allowed twice re-draws forever (measured S103:
;        28,257 passes, the battle never starts).
;   +25: MAZE SIZE -> $C93D (the bank $16 maze carve count; vanilla 3/8/15)
;   Pool index determined by LoadNextDungeonFloor from gate ID + current floor
;
; GATE → POOL MAPPING:
;   $6A22: per-gate base pool index (32 bytes, one per gate)
;   $6A42: per-gate floor breakpoint table pointers (32 × 2 bytes)
;          Each points to a list of floor thresholds used to select
;          which pool within the gate to use
;   $6AAE: encounter pool data blocks (128 pools × 26 bytes)
;   See dump_encounters.py for full decoded pool data
EncounterMonsterSelect:
label1_683e:  ; original label
    call LoadNextDungeonFloor
    ld hl, wEncListBuf + 2           ; S114: the list in use, +2 = the 1/2/3-monster
    ld bc, $0000                        ;   codes (was EncounterPoolData + number*26 + 2
    ds 11, $00                          ;   via Mul16x8To24, 17 B, which also left BC = 0)
    ld b, $00
    ld de, $c0d8
    call LookupEncounterEntry
    call LookupEncounterEntry
    call LookupEncounterEntry
    ld hl, $c0d8
    call CalcEncounterPoolIdx
    ld [$da02], a
    ld hl, wEncListBuf + 5           ; S114: the list in use, +5 = the slot codes
    ld bc, $0000                        ;   (was EncounterPoolData + number*26 + 5 via
    ds 11, $00                          ;   Mul16x8To24, which left BC = 0 — the sums
                                        ;   below start from B: KEY_LESSONS S114)
    ld de, $c0d8
    call LookupEncounterEntry
    call LookupEncounterEntry
    call LookupEncounterEntry
    call LookupEncounterEntry
    call LookupEncounterEntry

    ;initialize enemy monster slots
    ld a, $ff
    ld [wTempEnemyId1], a
    ld [$da05], a
    ld [$da07], a
    ld hl, $c0d8
    call CalcEncounterPoolIdx
    ld [wTempEnemyId1], a
    call SaveRegsForEncounter
    cp $01
    jr z, jr_001_68d8

    ld a, [$da02]
    or a
    jr z, jr_001_68d8

jr_001_68ad:
    ld hl, $c0d8
    call CalcEncounterPoolIdx
    ld [$da05], a
    call SetupEncounterCalc
    jr c, jr_001_68ad

    cp $01
    jr z, jr_001_68ad

    ld a, [$da02]
    cp $01
    jr z, jr_001_68d8

jr_001_68c6:
    ld hl, $c0d8
    call CalcEncounterPoolIdx
    ld [$da07], a
    call SetupEncounterCalc
    jr c, jr_001_68c6

    cp $01
    jr z, jr_001_68c6

jr_001_68d8:
    ld hl, wEncListBuf + 10          ; S114: the list in use, +10 = the five EIDs
    ld bc, $0000                        ;   (was EncounterPoolData + number*26 + 10
    ds 11, $00                          ;   via Mul16x8To24, 17 B, BC = 0 kept)
    ld a, [wTempEnemyId1]
    cp $ff
    jr z, jr_001_6940

    add a
    push hl
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [wTempEnemyId1], a	;load new monster ID into monster slot 1
    ld a, [hl]
    ld [$da04], a
    ld a, $00
    ld [$da02], a
    pop hl
    ld a, [$da05]
    cp $ff
    jr z, jr_001_6940

    add a
    push hl
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$da05], a
    ld a, [hl]
    ld [$da06], a
    ld a, $01
    ld [$da02], a
    pop hl
    ld a, [$da07]
    cp $ff
    jr z, jr_001_6940

    add a
    push hl
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$da07], a
    ld a, [hl]
    ld [$da08], a
    ld a, $02
    ld [$da02], a
    pop hl

jr_001_6940:
    ret


; SetupEncounterCalc: in A = the slot just drawn for monster 2/3 (already
; stored); B := how many picks so far use that slot (itself included), A :=
; that slot's max count (pool +20); callers retry while max < B (carry) or
; max == 1 (only-alone slots never join a group).
SetupEncounterCalc:
    ld b, $00
    push af
    ld c, a
    ld a, [wTempEnemyId1]
    cp $ff
    jr z, jr_001_6966

    cp c
    jr nz, jr_001_6950

    inc b

jr_001_6950:
    ld a, [$da05]
    cp $ff
    jr z, jr_001_6966

    cp c
    jr nz, jr_001_695b

    inc b

jr_001_695b:
    ld a, [$da07]
    cp $ff
    jr z, jr_001_6966

    cp c
    jr nz, jr_001_6966

    inc b

jr_001_6966:
    pop af
    call SaveRegsForEncounter
    cp b
    ret


; SaveRegsForEncounter: A = slot index -> A = pool +20 byte (the slot's max
; count); BC preserved. Monster 1 with max 1 = the group ends at one.
SaveRegsForEncounter:
    push af
    push bc
    ld hl, wEncListBuf + 20          ; S114: the list in use, +20 = the max counts
    ld bc, $0000                        ;   (was EncounterPoolData + number*26 + 20
    ds 11, $00                          ;   via Mul16x8To24, 17 B; BC is popped below)
    pop bc
    pop af
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ret


; CalcEncounterPoolIdx: RNG mod 100 against the cumulative % list at HL;
; returns the index of the first entry whose running sum is 100 or >= the draw
; (leading zero sums skipped). The draw = (wRNG2:wRNG1) mod 100 after a
; GenerateRNG — L is loaded from wRNG1, H from wRNG2 (measured S114, 15,192
; draws == editor2/core/encounters.simulate_battle): so the first entry with a
; chance also takes draw 0 and the entry ending at 100 loses one (30/50/20 % ->
; 31/50/19). A list that never reaches 100 walks past its end (the compiler
; refuses such pools, S103).
CalcEncounterPoolIdx:
    push hl
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, $64
    call Div16x8To16
    pop hl
    ld c, a
    ld b, $ff

jr_001_699e:
    ld a, [hl]
    inc b
    inc hl
    or a
    jr z, jr_001_699e

    cp $64
    jr z, jr_001_69ab

    cp c
    jr c, jr_001_699e

jr_001_69ab:
    ld a, b
    ret


; LookupEncounterEntry: in HL -> a pool chance CODE, B = running sum, DE ->
; the $C0D8 list; appends B += EncounterChancePercent[code] (cumulative %).
LookupEncounterEntry:
    ld a, [hl]
    push hl
    ld hl, EncounterChancePercent
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    pop hl
    add b
    ld b, a
    ld [de], a
    inc de
    inc hl
    ret


; EncounterChancePercent ($69C0, re-sectioned S103 from 7 mis-decoded
; instructions; byte-neutral): pool chance code (0-7) -> percent, read by
; LookupEncounterEntry for the group-size (+2..+4) and slot (+5..+9) codes.
EncounterChancePercent:
    db 0, 10, 20, 30, 40, 50, 70, 100


LoadFloorAndEncounterData:
    ; pool +25 (maze size) -> $C93D, read by the bank $16 maze builder
    call LoadNextDungeonFloor
    ld hl, wEncListBuf + 25          ; S114: the list in use, +25 = the maze size
    ld bc, $0000                        ;   (was EncounterPoolData + number*26 + 25
    ds 11, $00                          ;   via Mul16x8To24, 17 B, BC = 0 kept)
    ld a, [hl]
    ld [$c93d], a
    ret


; EncounterPoolSelect — Determine encounter pool index from gate + floor
; Bank $01 entry $0D. Called at EVERY encounter step (bank $16 entry 8, before
; the counter drain — it is what loads the rate code into wC8A9), at floor setup
; (LoadFloorAndEncounterData, entry $0C), by EncounterMonsterSelect (entry $0B)
; and by the floor-gold code ($5AF8). The floor in the walk is the game's
; numbering (wCurrentFloor + 1): sub-index = how many breakpoints are <= it
; (measured S114 for every vanilla gate floor; DATA_STRUCTURES "Encounter list
; choice (S114)"). In patched builds this routine is a same-size fork into bank
; $76 EncResolve (PROJECT_COMPILER §2.30).
; Input: wGateID = current gate, $C939 = current floor number
; Output: $CA38 = pool index
; Algorithm:
;   1. Read base pool index from $6A22[wGateID]
;   2. Read floor breakpoint table pointer from $6A42[wGateID × 2]
;   3. Walk breakpoints to find which sub-pool matches current floor
;   4. Pool index = base + floor_offset
;   5. Calculate pool data address = $6AAE + pool_index × 26($1A)
LoadNextDungeonFloor:
    ; S114 (P3.13a) SAME-SIZE FORK (65 B, like the vanilla walk it replaces):
    ; bank $76 EncResolve chooses the list — the vanilla gate+floor rule (its
    ; tables copied there), a gate's own plan, or a custom room's own list,
    ; with flag variants (PROJECT_COMPILER §2.30). A vanilla list (0-127) is
    ; copied from EncounterPoolData below; a project list (128+) is already in
    ; wEncListBuf. wEncounterPoolIndex keeps the floor's VANILLA number for its
    ; other reader (depth-tier-3 floor gold, $5AF8); the readers of the list
    ; bytes read wEncListBuf. GateBasePoolIndex / GateFloorBreakpoints /
    ; FloorBreakpointData below are no longer read in the patched build.
    ld hl, $7600                        ; bank $76 entry 0 EncResolve
    rst $10                             ; D = list, E = value, B = rate ($FF = own)
    ld a, e
    ld [wEncounterPoolIndex], a
    ld a, d
    bit 7, a
    jr nz, .listInBuf                   ; a project list: copied by bank $76
    push bc
    ld bc, $001a
    call Mul16x8To24                    ; HL = list * 26
    ld de, EncounterPoolData
    add hl, de
    ld de, wEncListBuf
    ld c, $1a
.copy:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .copy
    pop bc
.listInBuf:
    ld a, b
    cp $ff
    jr nz, .rate                        ; the room's own rate code
    ld a, [wEncListBuf]                 ; list +0 = rate code
.rate:
    ld [$c8a9], a                       ; wC8A9 (EncounterRateModifierTable index)
    ret
    ds 17, $00                          ; pad to the vanilla routine's 65 B



; ---------------------------------------------------------------
; Encounter Data ($6A22-$77AD)
; ---------------------------------------------------------------

; Gate base pool index table ($6A22)
; 32 bytes: gate_id → base pool index in pool data at $6AAE
GateBasePoolIndex:
    db 0, 1, 3, 5, 7, 9, 12, 15  ; Gates 0-7
    db 18, 22, 26, 30, 34, 39, 44, 49  ; Gates 8-15
    db 54, 59, 64, 69, 74, 79, 85, 89  ; Gates 16-23
    db 93, 97, 101, 105, 109, 113, 117, 121  ; Gates 24-31

; Floor breakpoint table pointers ($6A42)
; 32 × dw: gate_id → pointer to floor threshold list
GateFloorBreakpoints:
    dw $6A82  ; [0] Gate of Beginning
    dw $6A83  ; [1] Gate of Villager
    dw $6A83  ; [2] Gate of Talisman
    dw $6A83  ; [3] Gate of Memories
    dw $6A83  ; [4] Gate of Bewilder
    dw $6A83  ; [5] Bazaar Gate
    dw $6A86  ; [6] Gate of Peace
    dw $6A86  ; [7] Gate of Bravery
    dw $6A86  ; [8] Well Gate
    dw $6A8A  ; [9] Gate of Strength
    dw $6A8A  ; [10] Gate of Anger
    dw $6A8A  ; [11] Farm Gate
    dw $6A8E  ; [12] Gate of Joy
    dw $6A83  ; [13] Gate of Wisdom
    dw $6A8E  ; [14] Arena - Left Gate
    dw $6A93  ; [15] Gate of Happiness
    dw $6A93  ; [16] Gate of Temptation
    dw $6A86  ; [17] Medal Gate
    dw $6A98  ; [18] Gate of Labyrinth
    dw $6A98  ; [19] Gate of Judgement
    dw $6A98  ; [20] Library Gate
    dw $6A9D  ; [21] Gate of Reflection
    dw $6AA3  ; [22] Gate of Ambition
    dw $6AA3  ; [23] Gate of Demolition
    dw $6AA3  ; [24] Gate of Mastermind
    dw $6AA3  ; [25] Gate of Control
    dw $6AA3  ; [26] Gate of Extinction
    dw $6AA3  ; [27] Gate of Sleep
    dw $6AA3  ; [28] Bazaar Edge Gate
    dw $6AA3  ; [29] Arena - Right Gate
    dw $6AA3  ; [30] Old Man's Gate
    dw $6AA7  ; [31] Unused Gate

; Floor breakpoint data ($6A82)
; Variable-length lists of floor thresholds, $FF-terminated
; Referenced by pointers above. A gate's sub-index = how many of its breakpoints
; are <= the floor (1 = the first floor): Villager [3, 6] -> floors 1-2 pool 1,
; floors 3-5 pool 2 (floor 5 is its boss floor). Pools 42, 43, 63 are reached by
; no gate floor (S114, extracted/encounters.json).
FloorBreakpointData:
    db $FF, $03, $06, $FF, $04, $06, $09, $FF, $04, $06, $09, $FF, $04, $06, $09, $0D  ; $6A82
    db $FF, $05, $09, $0D, $11, $FF, $06, $0B, $10, $15, $FF, $06, $0B, $10, $15, $1A  ; $6A92
    db $FF, $06, $0B, $15, $FF, $06, $0B, $15, $29, $3D, $51, $FF  ; $6AA2

; ---------------------------------------------------------------
; Encounter Pool Data ($6AAE)
; 128 pools x 26 bytes = 3328 bytes
;
; Format (26 bytes per pool):
;   +$00-$09  Header (10 bytes)
;   +$0A-$13  EID slots (5 x 2 bytes LE, $0000 = unused)
;   +$14-$18  Weights (5 x 1 byte, 0 = unused)
;   +$19      Unknown (usually 8 or 15)
; ---------------------------------------------------------------

; @BUILD_PROJECT BEGIN gd_encounter_pools
; (generated by editor2 `gd_encounters` from gamedata.encounters. 26 B:
;  +0 rate code -> wC8A9 (EncounterRateModifierTable), +1 unread, +2..+4 chance
;  codes for 1/2/3 monsters, +5..+9 chance codes per slot (code -> % via
;  EncounterChancePercent $01:$69C0), +10 five EIDs, +20 per-slot max count
;  (1 = only ever alone, 0 = never as the 2nd/3rd monster), +25 maze size
;  -> $C93D (the bank-$16 maze carve count: vanilla 3 / 8 / 15) — S103
;  static decode of bank $01 EncounterMonsterSelect / LoadFloorAndEncounterData)
EncounterPoolData:
EncounterPool_000:  ; EID 2 10%, EID 4 10%, EID 3 10%, EID 520 70%  ; EDITED (project gamedata)
    db $03, $01, $07, $00, $00, $01, $01, $01, $06, $00
    dw 2, 4, 3, 520, 0
    db $01, $01, $01, $01, $00, $08
EncounterPool_001:  ; EID 5 30%, EID 6 30%, EID 3 20%, EID 14 20%
    db $03, $02, $05, $05, $00, $03, $03, $02, $02, $00
    dw 5, 6, 3, 14, 0
    db $03, $03, $03, $01, $00, $08
EncounterPool_002:  ; EID 5 30%, EID 6 30%, EID 7 30%, EID 15 10%
    db $03, $03, $03, $05, $02, $03, $03, $03, $01, $00
    dw 5, 6, 7, 15, 0
    db $03, $03, $03, $02, $00, $08
EncounterPool_003:  ; EID 8 30%, EID 10 30%, EID 3 20%, EID 13 20%
    db $03, $03, $03, $05, $02, $03, $03, $02, $02, $00
    dw 8, 10, 3, 13, 0
    db $03, $03, $03, $01, $00, $08
EncounterPool_004:  ; EID 8 30%, EID 9 30%, EID 10 30%, EID 14 10%
    db $03, $03, $03, $05, $02, $03, $03, $03, $01, $00
    dw 8, 9, 10, 14, 0
    db $03, $03, $03, $02, $00, $08
EncounterPool_005:  ; EID 9 30%, EID 15 30%, EID 17 20%, EID 19 20%
    db $03, $03, $03, $06, $00, $03, $03, $02, $02, $00
    dw 9, 15, 17, 19, 0
    db $03, $03, $03, $02, $00, $08
EncounterPool_006:  ; EID 14 40%, EID 20 30%, EID 19 20%, EID 25 10%
    db $03, $03, $02, $03, $05, $04, $03, $02, $01, $00
    dw 14, 20, 19, 25, 0
    db $03, $03, $03, $02, $00, $08
EncounterPool_007:  ; EID 13 30%, EID 21 30%, EID 17 20%, EID 25 20%
    db $03, $03, $03, $06, $00, $03, $03, $02, $02, $00
    dw 13, 21, 17, 25, 0
    db $03, $03, $03, $02, $00, $08
EncounterPool_008:  ; EID 18 40%, EID 22 30%, EID 25 20%, EID 16 10%
    db $03, $03, $02, $03, $05, $04, $03, $02, $01, $00
    dw 18, 22, 25, 16, 0
    db $03, $03, $03, $02, $00, $08
EncounterPool_009:  ; EID 20 30%, EID 21 30%, EID 25 20%, EID 26 20%
    db $04, $03, $03, $05, $02, $03, $03, $02, $02, $00
    dw 20, 21, 25, 26, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_010:  ; EID 21 40%, EID 17 30%, EID 19 20%, EID 27 10%
    db $04, $03, $03, $05, $02, $04, $03, $02, $01, $00
    dw 21, 17, 19, 27, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_011:  ; EID 22 40%, EID 19 30%, EID 16 20%, EID 28 10%
    db $04, $03, $03, $04, $03, $04, $03, $02, $01, $00
    dw 22, 19, 16, 28, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_012:  ; EID 21 30%, EID 25 30%, EID 29 30%, EID 26 10%
    db $03, $03, $03, $05, $02, $03, $03, $03, $01, $00
    dw 21, 25, 29, 26, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_013:  ; EID 17 40%, EID 26 30%, EID 23 20%, EID 33 10%
    db $03, $03, $02, $05, $03, $04, $03, $02, $01, $00
    dw 17, 26, 23, 33, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_014:  ; EID 16 40%, EID 26 30%, EID 33 20%, EID 34 10%
    db $03, $03, $03, $04, $03, $04, $03, $02, $01, $00
    dw 16, 26, 33, 34, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_015:  ; EID 22 30%, EID 27 30%, EID 28 30%, EID 35 10%
    db $03, $03, $03, $05, $02, $03, $03, $03, $01, $00
    dw 22, 27, 28, 35, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_016:  ; EID 27 40%, EID 35 30%, EID 24 20%, EID 36 10%
    db $03, $03, $02, $05, $03, $04, $03, $02, $01, $00
    dw 27, 35, 24, 36, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_017:  ; EID 27 40%, EID 35 30%, EID 36 20%, EID 34 10%
    db $03, $03, $03, $04, $03, $04, $03, $02, $01, $00
    dw 27, 35, 36, 34, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_018:  ; EID 23 30%, EID 33 30%, EID 35 30%, EID 38 10%
    db $04, $03, $00, $06, $03, $03, $03, $03, $01, $00
    dw 23, 33, 35, 38, 0
    db $03, $03, $03, $03, $00, $03
EncounterPool_019:  ; EID 33 40%, EID 40 30%, EID 35 20%, EID 38 10%
    db $04, $03, $00, $06, $03, $04, $03, $02, $01, $00
    dw 33, 40, 35, 38, 0
    db $03, $03, $03, $03, $00, $03
EncounterPool_020:  ; EID 36 40%, EID 34 30%, EID 35 20%, EID 39 10%
    db $04, $03, $00, $06, $03, $04, $03, $02, $01, $00
    dw 36, 34, 35, 39, 0
    db $03, $03, $03, $03, $00, $03
EncounterPool_021:  ; EID 34 30%, EID 24 20%, EID 35 20%, EID 39 20%, EID 30 10%
    db $04, $03, $00, $06, $03, $03, $02, $02, $02, $01
    dw 34, 24, 35, 39, 30
    db $03, $03, $03, $03, $03, $03
EncounterPool_022:  ; EID 39 30%, EID 40 30%, EID 37 20%, EID 47 20%
    db $03, $03, $01, $05, $04, $03, $03, $02, $02, $00
    dw 39, 40, 37, 47, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_023:  ; EID 39 30%, EID 37 30%, EID 47 30%, EID 43 10%
    db $03, $03, $01, $05, $04, $03, $03, $03, $01, $00
    dw 39, 37, 47, 43, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_024:  ; EID 40 40%, EID 37 30%, EID 43 20%, EID 46 10%
    db $03, $03, $01, $05, $04, $04, $03, $02, $01, $00
    dw 40, 37, 43, 46, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_025:  ; EID 40 40%, EID 43 30%, EID 47 20%, EID 46 10%
    db $03, $03, $01, $05, $04, $04, $03, $02, $01, $00
    dw 40, 43, 47, 46, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_026:  ; EID 36 30%, EID 38 30%, EID 41 20%, EID 42 20%
    db $03, $03, $01, $05, $04, $03, $03, $02, $02, $00
    dw 36, 38, 41, 42, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_027:  ; EID 38 30%, EID 41 30%, EID 42 30%, EID 44 10%
    db $03, $03, $01, $05, $04, $03, $03, $03, $01, $00
    dw 38, 41, 42, 44, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_028:  ; EID 42 40%, EID 41 30%, EID 44 20%, EID 45 10%
    db $03, $03, $01, $05, $04, $04, $03, $02, $01, $00
    dw 42, 41, 44, 45, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_029:  ; EID 42 40%, EID 44 30%, EID 45 20%, EID 46 10%
    db $03, $03, $01, $05, $04, $04, $03, $02, $01, $00
    dw 42, 44, 45, 46, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_030:  ; EID 47 30%, EID 49 30%, EID 50 20%, EID 48 20%
    db $04, $03, $00, $05, $05, $03, $03, $02, $02, $00
    dw 47, 49, 50, 48, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_031:  ; EID 47 30%, EID 50 30%, EID 48 30%, EID 57 10%
    db $04, $03, $00, $05, $05, $03, $03, $03, $01, $00
    dw 47, 50, 48, 57, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_032:  ; EID 46 40%, EID 50 30%, EID 48 20%, EID 58 10%
    db $04, $03, $00, $05, $05, $04, $03, $02, $01, $00
    dw 46, 50, 48, 58, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_033:  ; EID 46 40%, EID 48 30%, EID 57 20%, EID 58 10%
    db $04, $03, $00, $05, $05, $04, $03, $02, $01, $00
    dw 46, 48, 57, 58, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_034:  ; EID 59 30%, EID 60 30%, EID 62 20%, EID 61 20%
    db $03, $03, $01, $04, $05, $03, $03, $02, $02, $00
    dw 59, 60, 62, 61, 0
    db $03, $03, $03, $01, $00, $0F
EncounterPool_035:  ; EID 59 30%, EID 60 30%, EID 62 30%, EID 61 10%
    db $03, $03, $01, $04, $05, $03, $03, $03, $01, $00
    dw 59, 60, 62, 61, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_036:  ; EID 60 40%, EID 62 30%, EID 63 20%, EID 61 10%
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 60, 62, 63, 61, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_037:  ; EID 60 40%, EID 63 30%, EID 65 20%, EID 64 10%
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 60, 63, 65, 64, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_038:  ; EID 65 40%, EID 63 30%, EID 61 20%, EID 64 10%
    db $04, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 65, 63, 61, 64, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_039:  ; EID 58 30%, EID 67 30%, EID 68 20%, EID 66 20%
    db $03, $03, $01, $04, $05, $03, $03, $02, $02, $00
    dw 58, 67, 68, 66, 0
    db $03, $03, $03, $01, $00, $0F
EncounterPool_040:  ; EID 58 30%, EID 67 30%, EID 68 30%, EID 66 10%
    db $03, $03, $01, $04, $05, $03, $03, $03, $01, $00
    dw 58, 67, 68, 66, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_041:  ; EID 67 40%, EID 68 30%, EID 66 20%, EID 70 10%
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 67, 68, 66, 70, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_042:  ; EID 67 40%, EID 66 30%, EID 69 20%, EID 70 10%
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 67, 66, 69, 70, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_043:  ; EID 66 40%, EID 69 30%, EID 71 20%, EID 70 10%
    db $04, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 66, 69, 71, 70, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_044:  ; EID 73 30%, EID 72 30%, EID 71 20%, EID 74 20%
    db $04, $03, $00, $03, $06, $03, $03, $02, $02, $00
    dw 73, 72, 71, 74, 0
    db $03, $03, $03, $01, $00, $03
EncounterPool_045:  ; EID 73 30%, EID 72 30%, EID 71 30%, EID 74 10%
    db $04, $03, $00, $03, $06, $03, $03, $03, $01, $00
    dw 73, 72, 71, 74, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_046:  ; EID 72 40%, EID 71 30%, EID 74 20%, EID 81 10%
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00
    dw 72, 71, 74, 81, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_047:  ; EID 72 40%, EID 74 30%, EID 83 20%, EID 81 10%
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00
    dw 72, 74, 83, 81, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_048:  ; EID 74 40%, EID 83 30%, EID 81 20%, EID 82 10%
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00
    dw 74, 83, 81, 82, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_049:  ; EID 85 30%, EID 86 30%, EID 87 20%, EID 82 20%
    db $03, $03, $01, $04, $05, $03, $03, $02, $02, $00
    dw 85, 86, 87, 82, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_050:  ; EID 85 30%, EID 86 30%, EID 87 30%, EID 88 10%
    db $03, $03, $01, $04, $05, $03, $03, $03, $01, $00
    dw 85, 86, 87, 88, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_051:  ; EID 85 40%, EID 86 30%, EID 87 20%, EID 88 10%
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 85, 86, 87, 88, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_052:  ; EID 86 40%, EID 87 30%, EID 88 20%, EID 84 10%
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 86, 87, 88, 84, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_053:  ; EID 86 40%, EID 88 30%, EID 89 20%, EID 84 10%
    db $04, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 86, 88, 89, 84, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_054:  ; EID 89 30%, EID 91 30%, EID 92 20%, EID 90 20%
    db $03, $03, $01, $04, $05, $03, $03, $02, $02, $00
    dw 89, 91, 92, 90, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_055:  ; EID 89 30%, EID 91 30%, EID 92 30%, EID 90 10%
    db $03, $03, $01, $04, $05, $03, $03, $03, $01, $00
    dw 89, 91, 92, 90, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_056:  ; EID 91 40%, EID 92 30%, EID 90 20%, EID 94 10%
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 91, 92, 90, 94, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_057:  ; EID 91 40%, EID 90 30%, EID 93 20%, EID 94 10%
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 91, 90, 93, 94, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_058:  ; EID 90 40%, EID 93 30%, EID 95 20%, EID 94 10%
    db $04, $03, $01, $04, $05, $04, $03, $02, $01, $00
    dw 90, 93, 95, 94, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_059:  ; EID 96 30%, EID 98 30%, EID 107 20%, EID 105 20%
    db $04, $03, $00, $03, $06, $03, $03, $02, $02, $00
    dw 96, 98, 107, 105, 0
    db $03, $03, $03, $01, $00, $03
EncounterPool_060:  ; EID 96 30%, EID 98 30%, EID 107 30%, EID 105 10%
    db $04, $03, $00, $03, $06, $03, $03, $03, $01, $00
    dw 96, 98, 107, 105, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_061:  ; EID 98 40%, EID 107 30%, EID 105 20%, EID 97 10%
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00
    dw 98, 107, 105, 97, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_062:  ; EID 98 40%, EID 105 30%, EID 106 20%, EID 97 10%
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00
    dw 98, 105, 106, 97, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_063:  ; EID 105 40%, EID 106 30%, EID 107 20%, EID 97 10%
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00
    dw 105, 106, 107, 97, 0
    db $03, $03, $03, $02, $00, $03
EncounterPool_064:  ; EID 108 30%, EID 109 20%, EID 112 20%, EID 113 20%, EID 107 10%
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01
    dw 108, 109, 112, 113, 107
    db $03, $03, $03, $03, $02, $0F
EncounterPool_065:  ; EID 108 30%, EID 111 20%, EID 112 20%, EID 113 20%, EID 107 10%
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01
    dw 108, 111, 112, 113, 107
    db $03, $03, $03, $03, $02, $0F
EncounterPool_066:  ; EID 108 30%, EID 111 20%, EID 112 20%, EID 107 20%, EID 114 10%
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01
    dw 108, 111, 112, 107, 114
    db $03, $03, $03, $02, $02, $0F
EncounterPool_067:  ; EID 108 30%, EID 111 20%, EID 113 20%, EID 107 20%, EID 114 10%
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01
    dw 108, 111, 113, 107, 114
    db $03, $03, $03, $02, $02, $0F
EncounterPool_068:  ; EID 108 20%, EID 111 20%, EID 107 20%, EID 114 20%, EID 115 20%
    db $04, $03, $01, $04, $05, $02, $02, $02, $02, $02
    dw 108, 111, 107, 114, 115
    db $03, $03, $03, $03, $02, $0F
EncounterPool_069:  ; EID 116 30%, EID 119 20%, EID 120 20%, EID 121 20%, EID 117 10%
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01
    dw 116, 119, 120, 121, 117
    db $03, $03, $03, $03, $02, $0F
EncounterPool_070:  ; EID 119 30%, EID 120 20%, EID 121 20%, EID 122 20%, EID 117 10%
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01
    dw 119, 120, 121, 122, 117
    db $03, $03, $03, $03, $02, $0F
EncounterPool_071:  ; EID 119 30%, EID 121 20%, EID 122 20%, EID 117 20%, EID 118 10%
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01
    dw 119, 121, 122, 117, 118
    db $03, $03, $03, $02, $02, $0F
EncounterPool_072:  ; EID 119 30%, EID 121 20%, EID 129 20%, EID 117 20%, EID 118 10%
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01
    dw 119, 121, 129, 117, 118
    db $03, $03, $03, $02, $02, $0F
EncounterPool_073:  ; EID 119 20%, EID 120 20%, EID 129 20%, EID 117 20%, EID 118 20%
    db $04, $03, $01, $04, $05, $02, $02, $02, $02, $02
    dw 119, 120, 129, 117, 118
    db $03, $03, $03, $03, $02, $0F
EncounterPool_074:  ; EID 130 30%, EID 132 20%, EID 136 20%, EID 137 20%, EID 131 10%
    db $04, $03, $00, $03, $06, $03, $02, $02, $02, $01
    dw 130, 132, 136, 137, 131
    db $03, $03, $03, $03, $02, $03
EncounterPool_075:  ; EID 130 30%, EID 132 20%, EID 134 20%, EID 137 20%, EID 131 10%
    db $04, $03, $00, $03, $06, $03, $02, $02, $02, $01
    dw 130, 132, 134, 137, 131
    db $03, $03, $03, $03, $02, $03
EncounterPool_076:  ; EID 130 30%, EID 132 20%, EID 134 20%, EID 137 20%, EID 133 10%
    db $04, $03, $00, $03, $06, $03, $02, $02, $02, $01
    dw 130, 132, 134, 137, 133
    db $03, $03, $03, $03, $02, $03
EncounterPool_077:  ; EID 130 30%, EID 131 20%, EID 134 20%, EID 137 20%, EID 133 10%
    db $04, $03, $00, $03, $06, $03, $02, $02, $02, $01
    dw 130, 131, 134, 137, 133
    db $03, $03, $03, $03, $02, $03
EncounterPool_078:  ; EID 130 20%, EID 131 20%, EID 133 20%, EID 134 20%, EID 135 20%
    db $04, $03, $00, $03, $06, $02, $02, $02, $02, $02
    dw 130, 131, 133, 134, 135
    db $03, $03, $03, $03, $02, $03
EncounterPool_079:  ; EID 138 30%, EID 139 20%, EID 140 20%, EID 141 20%, EID 142 10%
    db $03, $03, $00, $03, $06, $03, $02, $02, $02, $01
    dw 138, 139, 140, 141, 142
    db $03, $03, $03, $03, $02, $0F
EncounterPool_080:  ; EID 138 30%, EID 139 20%, EID 141 20%, EID 142 20%, EID 143 10%
    db $03, $03, $00, $03, $06, $03, $02, $02, $02, $01
    dw 138, 139, 141, 142, 143
    db $03, $03, $03, $03, $02, $0F
EncounterPool_081:  ; EID 142 30%, EID 141 20%, EID 144 20%, EID 145 20%, EID 143 10%
    db $03, $03, $00, $03, $06, $03, $02, $02, $02, $01
    dw 142, 141, 144, 145, 143
    db $03, $03, $03, $03, $02, $0F
EncounterPool_082:  ; EID 142 30%, EID 144 20%, EID 146 20%, EID 157 20%, EID 143 10%
    db $03, $03, $00, $03, $06, $03, $02, $02, $02, $01
    dw 142, 144, 146, 157, 143
    db $03, $03, $03, $03, $02, $0F
EncounterPool_083:  ; EID 144 30%, EID 146 20%, EID 157 20%, EID 158 20%, EID 143 10%
    db $03, $03, $00, $03, $06, $03, $02, $02, $02, $01
    dw 144, 146, 157, 158, 143
    db $03, $03, $03, $03, $02, $0F
EncounterPool_084:  ; EID 143 20%, EID 146 20%, EID 157 20%, EID 158 20%, EID 159 20%
    db $04, $03, $00, $03, $06, $02, $02, $02, $02, $02
    dw 143, 146, 157, 158, 159
    db $03, $03, $03, $03, $03, $0F
EncounterPool_085:  ; EID 6 30%, EID 10 30%, EID 19 20%, EID 36 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 6, 10, 19, 36, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_086:  ; EID 38 30%, EID 44 30%, EID 49 20%, EID 70 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 38, 44, 49, 70, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_087:  ; EID 86 30%, EID 94 30%, EID 113 20%, EID 116 20%
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 86, 94, 113, 116, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_088:  ; EID 122 30%, EID 129 30%, EID 137 20%, EID 146 20%
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 122, 129, 137, 146, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_089:  ; EID 5 30%, EID 18 30%, EID 27 20%, EID 35 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 5, 18, 27, 35, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_090:  ; EID 43 30%, EID 62 30%, EID 69 20%, EID 85 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 43, 62, 69, 85, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_091:  ; EID 112 30%, EID 121 30%, EID 136 20%, EID 145 20%
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 112, 121, 136, 145, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_092:  ; EID 145 30%, EID 163 30%, EID 169 20%, EID 189 20%
    db $04
EncounterDataTable_1:  ; (referenced from elsewhere in the bank)
    db $03, $00, $00, $07, $03, $03, $02, $02, $00, $91, $00, $A3, $00, $A9, $00, $BD, $00, $00, $00, $03, $03, $03, $03, $00, $0F
EncounterDataTable_2:  ; (referenced from elsewhere in the bank)
EncounterPool_093:  ; EID 4 30%, EID 14 30%, EID 21 20%, EID 34 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 4, 14, 21, 34, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_094:  ; EID 50 30%, EID 61 30%, EID 68 20%, EID 84 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 50, 61, 68, 84, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_095:  ; EID 93 30%, EID 111 30%, EID 120 20%, EID 135 20%
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 93, 111, 120, 135, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_096:  ; EID 144 30%, EID 162 30%, EID 197 20%, EID 198 20%
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00, $90, $00, $A2
EncounterWeightTable:  ; (referenced from elsewhere in the bank)
    db $00, $C5, $00, $C6, $00, $00, $00, $03, $03, $03, $03, $00, $0F
EncounterPool_097:  ; EID 2 30%, EID 25 30%, EID 30 20%, EID 40 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 2, 25, 30, 40, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_098:  ; EID 46 30%, EID 59 30%, EID 65 20%, EID 73 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 46, 59, 65, 73, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_099:  ; EID 81 30%, EID 90 30%, EID 98 20%, EID 108 20%
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 81, 90, 98, 108, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_100:  ; EID 108 30%, EID 117 30%, EID 141 20%, EID 181 20%
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 108, 117, 141, 181, 0
    db $03, $03, $03, $02, $00, $0F
EncounterPool_101:  ; EID 7 30%, EID 22 30%, EID 28 20%, EID 37 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 7, 22, 28, 37, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_102:  ; EID 63 30%, EID 71 30%, EID 87 20%, EID 95 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 63, 71, 87, 95, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_103:  ; EID 105 30%, EID 114 30%, EID 130 20%, EID 138 20%
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 105, 114, 130, 138, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_104:  ; EID 157 30%, EID 164 30%, EID 170 20%, EID 190 20%
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 157, 164, 170, 190, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_105:  ; EID 8 30%, EID 16 30%, EID 23 20%, EID 45 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 8, 16, 23, 45, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_106:  ; EID 57 30%, EID 64 30%, EID 88 20%, EID 96 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 57, 64, 88, 96, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_107:  ; EID 106 30%, EID 115 30%, EID 131 20%, EID 139 20%
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 106, 115, 131, 139, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_108:  ; EID 158 20%, EID 165 20%, EID 171 20%, EID 186 20%, EID 191 20%
    db $04, $03, $00, $00, $07, $02, $02, $02, $02, $02
    dw 158, 165, 171, 186, 191
    db $03, $03, $03, $03, $03, $0F
EncounterPool_109:  ; EID 9 30%, EID 24 30%, EID 29 20%, EID 39 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 9, 24, 29, 39, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_110:  ; EID 58 30%, EID 72 30%, EID 89 20%, EID 97 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 58, 72, 89, 97, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_111:  ; EID 107 20%, EID 132 20%, EID 140 20%, EID 159 20%, EID 166 20%
    db $03, $03, $00, $00, $07, $02, $02, $02, $02, $02
    dw 107, 132, 140, 159, 166
    db $03, $03, $03, $03, $03, $0F
EncounterPool_112:  ; EID 172 20%, EID 183 20%, EID 187 20%, EID 192 20%, EID 193 20%
    db $04, $03, $00, $00, $07, $02, $02, $02, $02, $02
    dw 172, 183, 187, 192, 193
    db $03, $03, $03, $03, $03, $0F
EncounterPool_113:  ; EID 15 20%, EID 20 20%, EID 33 20%, EID 42 20%, EID 48 20%
    db $02, $03, $00, $00, $07, $02, $02, $02, $02, $02
    dw 15, 20, 33, 42, 48
    db $03, $03, $03, $03, $03, $0F
EncounterPool_114:  ; EID 60 20%, EID 67 20%, EID 74 20%, EID 83 20%, EID 92 20%
    db $02, $03, $00, $00, $07, $02, $02, $02, $02, $02
    dw 60, 67, 74, 83, 92
    db $03, $03, $03, $03, $03, $0F
EncounterPool_115:  ; EID 110 20%, EID 119 20%, EID 134 20%, EID 143 20%, EID 161 20%
    db $03, $03, $00, $00, $07, $02, $02, $02, $02, $02
    dw 110, 119, 134, 143, 161
    db $03, $03, $03, $03, $03, $0F
EncounterPool_116:  ; EID 168 20%, EID 174 20%, EID 182 20%, EID 185 20%, EID 195 20%
    db $04, $03, $00, $00, $07, $02, $02, $02, $02, $02
    dw 168, 174, 182, 185, 195
    db $03, $03, $03, $03, $03, $0F
EncounterPool_117:  ; EID 13 30%, EID 17 30%, EID 26 20%, EID 41 20%
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 13, 17, 26, 41, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_118:  ; EID 47 20%, EID 66 20%, EID 82 20%, EID 91 20%, EID 109 20%
    db $02, $03, $00, $00, $07, $02, $02, $02, $02, $02
    dw 47, 66, 82, 91, 109
    db $03, $03, $03, $03, $03, $0F
EncounterPool_119:  ; EID 118 20%, EID 133 20%, EID 142 20%, EID 160 20%, EID 167 20%
    db $03, $03, $00, $00, $07, $02, $02, $02, $02, $02
    dw 118, 133, 142, 160, 167
    db $03, $03, $03, $03, $03, $0F
EncounterPool_120:  ; EID 173 20%, EID 184 20%, EID 188 20%, EID 194 20%, EID 196 20%
    db $04, $03, $00, $00, $07, $02, $02, $02, $02, $02
    dw 173, 184, 188, 194, 196
    db $03, $03, $03, $03, $03, $0F
EncounterPool_121:  ; EID 186 30%, EID 185 30%, EID 187 20%, EID 188 20%
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 186, 185, 187, 188, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_122:  ; EID 187 30%, EID 188 30%, EID 189 20%, EID 190 20%
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 187, 188, 189, 190, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_123:  ; EID 189 30%, EID 190 30%, EID 191 20%, EID 192 20%
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 189, 190, 191, 192, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_124:  ; EID 191 30%, EID 192 30%, EID 193 20%, EID 194 20%
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 191, 192, 193, 194, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_125:  ; EID 193 30%, EID 194 30%, EID 195 20%, EID 196 20%
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 193, 194, 195, 196, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_126:  ; EID 195 30%, EID 196 30%, EID 197 20%, EID 198 20%
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 195, 196, 197, 198, 0
    db $03, $03, $03, $03, $00, $0F
EncounterPool_127:  ; EID 197 30%, EID 198 30%, EID 30 20%, EID 181 20%
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 197, 198, 30, 181, 0
    db $03, $03, $03, $03, $00, $0F
; @BUILD_PROJECT END gd_encounter_pools

    ld e, d
    rst $20
    ret


    rst $10
    ret nz

    ld a, $07
    ld [$c980], a
    ld a, $06
    ld [$c981], a
    ret


    rst $30
    cp $e8
    ld h, d
    ld l, $12
    jr c, jr_001_77d6

    ld a, [hl-]
    cp $02
    jr c, jr_001_77d0

    ret nz

    ld a, [hl]
    cp $80
    ret nc

jr_001_77d0:
    ld bc, $000c
    jp $0598


jr_001_77d6:
    cp $3c
    ret c

    cp $48
    ld bc, $0120
    jp nc, Jump_000_055a

    ld a, [hl-]
    cp $01
    ret c

    jr nz, jr_001_77eb

    ld a, [hl]
    cp $80
    ret c

jr_001_77eb:
    ld bc, $fff8
    jp $0598


    ld a, [$ca96]
    bit 5, a
    ld a, $03
    jr nz, jr_001_7851

    ld a, [$cac1]
    and a
    ret nz

    call ScreenRefreshVBlank
    jr c, jr_001_7827

    ld a, [$cc08]
    ldh [$d8], a
    ld a, $61
    rst $20
    call ScreenRefreshVBlank
    ldh a, [$d8]
    rst $20
    ret nc

    ld hl, $cc0f
    ld a, [$c00f]
    cp $6a
    ret nc

    sub $0c
    cp [hl]
    ld h, $c0
    jr nc, jr_001_7825

    inc [hl]
    ret


jr_001_7825:
    dec [hl]
    ret


jr_001_7827:
    ld hl, $cac0
    set 0, [hl]
    ld hl, $c007
    res 0, [hl]
    ld bc, $785b
    call $02be
    ld l, $10
    ld [hl], $02
    ld a, $80
    call ShowTextAndWait
    call $050b
    call $7860
    ld e, $01
    ld a, [de]
    cp $02
    ld a, $06
    jr z, jr_001_7851

    ld a, $07

jr_001_7851:
    call $07d8
    ld hl, $c98b
    set 1, [hl]
    pop bc
    ret


    ld [$0858], sp
    ld e, c
    cp $26
    ret nz

    ld bc, $0000
    call $05ff
    push bc
    ld h, $d0
    call $07b8
    ld [hl], $64
    pop bc
    call TriggerMapRedraw
    ld d, $d0
    call GameStateBit_0686
    ld a, $1f
    rst $20
    ld bc, Boot
    call $0552
    ld bc, $fe00
    call CallTextRenderer
    ld d, $cc
    ret


    ld e, $01
    ld a, [de]
    cp $01
    jr z, jr_001_78a5

    jr nc, jr_001_78c8

    rst $10
    ret nz

    ld [hl], $18
    rst $38
    ld bc, $0080
    call CallTextRenderer
    ld bc, $ff80
    jp $0552


jr_001_78a5:
    ld e, $0f
    ld a, [de]
    cp $98
    jr nc, jr_001_78bf

    ld bc, $fff8
    call $058e
    rst $10
    ret nz

    ld [hl], $28
    ld bc, Boot
    call CrossBankCallRst10
    jp $057c


jr_001_78bf:
    call StoreMapPointerRegs
    rst $38
    ld a, $80
    jp Jump_ShowTextAndWait


jr_001_78c8:
    rst $10
    ret nz

    ld a, $03
    ld [$c9c0], a
    jp NextTilemapByte


    ld bc, $000c
    jp $058e


    jp CheckInputMaskedJP


    call $0043
    db $e4
    ld a, b
    ld b, $79
    dec de
    ld a, c
    ld a, [$ca86]
    cp $08
    ret c

    rst $38
    ld bc, $78fd
    call WaitForJoypadInput
    ld bc, $f010
    call $05e2
    ld bc, $0280
    jp $0552


    ld [$045d], sp
    ld e, [hl]
    ld [$045f], sp
    ld e, [hl]
    cp $01
    db $fd
    ld a, b
    call $0298
    call $075c
    ret nc

    rst $38
    ld a, $80
    call ShowTextAndWait
    ld l, $10
    ld [hl], $02
    ret


    rst $10
    ret nz

    ld a, $01
    call $07d8
    call SetROMBankHigh
    ld bc, $1000
    call $0612
    call $05e2
    ld l, $10
    ld [hl], $01
    ld a, [$cc01]
    cp $03
    jr nc, jr_001_7948

    ld bc, $0280
    call SetupTextBankSwitch
    jp z, Jump_000_055a

    ld bc, $ff00
    jp Jump_000_055a


jr_001_7948:
    ld bc, $0080
    jp RetStub054A


    ret


    ld e, $01
    ld a, [de]
    cp $08
    push af
    call c, GameStateUpdate_036F
    pop af
    rst $00

    dw label796e
    dw label7992
    dw label79fc
    dw label7a1c
    dw label7a34
    dw label7a44
    dw label7a49
    dw label7a4e
    dw label7a69
    dw label7ac5

  label796e:
    ld e, $02
    ld a, [de]
    and a
    jr nz, jr_001_7983

    call LookupGateThreshold
    ld a, [$ca86]
    cp $03
    ret nz

    call $050b
    jp Jump_001_6137


jr_001_7983:
    rst $38
    ld a, $5c
    rst $20
    ld a, $40
    call ShowTextAndWait
    ld bc, $9843
    jp Jump_000_3722


label7992:
    call LookupGateThreshold
    rst $10
    ret nz

    ld [hl], $20
    rst $38
    ld a, $3e
    call BankTrampolineTable
    call SetViewportParams
    ld hl, $c014
    add [hl]
    ld hl, $c00f
    add [hl]
    bit 0, a
    jr nz, jr_001_79c3

    ld e, $02
    ld a, [de]
    cp $0a
    jr nc, jr_001_79c3

    ld a, $09
    ld bc, EncounterPool_095
    call WriteNPCField1C
    ld hl, $7ba8
    jp $091e


jr_001_79c3:
    ld a, $0b
    ld bc, $7464
    call WriteNPCField1C
    ld hl, $7b8f
    jp $091e


WriteNPCField1C:
    ld e, $1c
    ld [de], a
    push bc
    call $07cc
    pop bc
    ret nz

    ld [hl], $65
    ld d, h
    ld a, $5b
    rst $20
    call CheckState_C83c_068A
    call ScreenProcessB
    ld bc, $fe00
    call $0552
    db $cd, $cf, $01
    ld b, h
    ld c, l
    ld hl, $c0c0
    call TextIdDispatch
    ld d, $cc
    jp $07d3

label79fc:
    rst $10
    ret nz

    ld [hl], $08
    ld hl, $7b71
    call $091e
    ld e, $02
    ld a, [de]
    cp $10
    ld a, $04
    jp nc, $07d8

    ld hl, $8f8e
    call CallAudioSetup
    rst $38
    ld h, d
    ld l, $1c
    inc [hl]
    ret

label7a1c:
    rst $10
    ret nz

    ld a, $40
    ld l, $02
    sub [hl]
    sub [hl]
    sub [hl]
    sub [hl]
    call ShowTextAndWait
    ld hl, $8e8f
    call CallAudioSetup
    ld a, $01
    jp $07d8

label7a34:
    ld bc, $7bbb

jr_001_7a37:
    rst $10
    ret nz

    ld [hl], $20
    rst $38
    ld h, b
    ld l, c
    call $091e
    jp $050b

label7a44:
    ld bc, $7bc0
    jr jr_001_7a37

label7a49:
    ld bc, $7bc5
    jr jr_001_7a37

label7a4e:
    rst $10
    ret nz

    rst $38
    ld bc, $8000
    call $05e2
    ld c, $00
    ld a, $60
    call $6371
    ld bc, $0400
    call CallTextRenderer
    ld a, $48
    jp Jump_000_0515


label7a69:
    call VRAMCopyTileAndRet
    ret z

    ld d, $c0
    call CheckFieldStateDD20
    ld d, $cc
    jr z, jr_001_7a90

    ld a, [$c00f]
    add $08
    cp $6a
    jr nc, jr_001_7abf

    ld d, $c0
    call MenuEndDraw
    ld d, $cc
    jr nz, jr_001_7abf

    ld a, [$c00f]
    add $08
    ld [$c00f], a

jr_001_7a90:
    ld bc, $fcf4
    ld hl, $c0c0
    call $6461
    ld bc, $e4fc
    ld hl, $7bd4
    call VRAMCopyTile16
    ld bc, $04fc
    ld hl, $7be0
    call VRAMCopyTile16
    call $6583
    ret c

    ld a, $1a
    call BankTrampolineTable
    ld a, $20
    call SubtractTileOffset16
    rst $38
    ld a, $40
    jp Jump_ShowTextAndWait


jr_001_7abf:
    ld a, $01
    ld [$cac1], a
    ret

label7ac5:
    ld a, [$c001]
    cp $03
    jr nc, jr_001_7ad6

    ld hl, $cac0
    set 0, [hl]
    ld hl, $c007
    set 0, [hl]

jr_001_7ad6:
    rst $10
    ret nz

    ld a, [$cac1]
    and a
    ret nz

    call ReadJoypad
    ld a, $ac
    ld [hl], a
    ld [$ca96], a
    ld hl, $cac0
    res 0, [hl]
    call TilemapRecombineAddr
    jp Jump_001_5e8c


    ld e, $01
    ld a, [de]
    and a
    jp nz, WriteTileBytePair

    ld bc, $fffc
    call $0598
    call CheckState_C82d_0838
    ret z

    rst $38
    call $05c6
    ld bc, Boot
    jp Jump_CallTextRenderer


LookupGateThreshold:
    ld hl, $7b65
    ld a, [$c982]
    bit 3, a
    jp z, $091e

    ld hl, $7b6b
    jp $091e


CallAudioSetup:
    push hl
    call $372a
    ld e, $02
    ld a, [de]
    cp $0b
    jr c, jr_001_7b46

    xor a
    call LoadGateEncounterRates
    call AudioJumpToFreqCalc
    ld e, $01
    ld a, [de]
    cp $03
    jr z, jr_001_7b46

    ld h, d
    ld l, $02
    ld a, $10
    sub [hl]
    add a
    dec a
    ld e, $1c
    ld [de], a
    ld a, $8e
    call LoadGateEncounterRates

jr_001_7b46:
    pop hl
    ld e, $1c
    ld a, [de]
    ld e, a

jr_001_7b4b:
    ld a, h
    call LoadGateEncounterRates
    dec e
    ret z

    ld a, l
    call LoadGateEncounterRates
    dec e
    ret z

    jr jr_001_7b4b

LoadGateEncounterRates:
    call RunScriptEngine
    dec c
    call RunScriptEngine
    inc c
    ld a, $20
    rst $18
    ret


    inc h
    sbc c
    ld b, b
    ld b, c
    ld b, d
    rst $38
    inc h
    sbc c
    ld h, a
    ld b, c
    ld l, b
    rst $38
    inc h
    sbc c
    ld b, b
    ld b, c
    ld b, d
    ld b, e
    cp $43
    sbc c
    nop
    ld b, h
    ld b, l
    ld b, [hl]
    ld b, a
    cp $63
    sbc c
    nop
    ld c, b
    ld c, c
    ld c, d
    ld c, e
    cp $84
    sbc c
    ld c, h
    ld c, l
    ld c, [hl]
    ld c, a
    rst $38
    dec h
    sbc c
    ld d, h
    ld d, l
    ld d, [hl]
    cp $46
    sbc c
    ld d, a
    ld e, b
    cp $64
    sbc c
    ld e, c
    ld c, c
    ld e, d
    ld e, e
    cp $84
    sbc c
    ld e, h
    ld e, l
    ld e, [hl]
    ld e, a
    rst $38
    inc h
    sbc c
    ld h, b
    ld h, c
    cp $43
    sbc c
    ld h, d
    ld h, e
    cp $63
    sbc c
    ld h, h
    ld h, l
    cp $84
    sbc c
    ld h, [hl]
    rst $38
    ld b, h
    sbc c
    ld l, e
    ld l, h
    rst $38
    ld b, h
    sbc c
    ld l, c
    ld l, d
    rst $38
    ld b, h
    sbc c
    ld l, l
    ld l, [hl]
    cp $64
    sbc c
    ld l, a
    ld [hl], b
    cp $84
    sbc c
    ld [hl], c
    ld [hl], d
    rst $38
    nop
    nop
    nop
    nop
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    ld a, d
    ld a, [hl]
    ld a, e
    nop
    ld [hl], h
    ld [hl], h
    ld [hl], h
    ld [hl], h
    ld [hl], h
    ld [hl], h
    ld [hl], h
    ld [hl], h

CalcGateMonsterLevel:
    call CallTextRenderer
    ld bc, $0200
    call $0552
    ld a, [$c00f]
    ld c, a
    ld b, $60
    call CheckState_C83c_068A
    ld l, $00
    ld [hl], $66
    ld a, $5a
    rst $20
    inc d
    ret


    rst $30
    cp $98
    ret c

    jp NextTilemapByte


    ld e, $01
    ld a, [de]
    and a
    jr nz, jr_001_7c23

    call SetJoypadResult
    rst $38
    ld bc, $7d53
    call $02be
    ld a, $48
    jp Jump_000_0515


jr_001_7c23:
    ld bc, $7d53
    call $06b1
    ret nz

    jp NextTilemapByte


    call DispatchCD90
    ld b, h
    ld a, h
    ld a, $59
    ld e, d
    ld a, h
    ld [hl], c
    ld a, h
    add h
    ld a, h
    sbc l
    ld a, h
    push bc
    ld a, h
    pop de
    ld a, h
    jr nc, jr_001_7cbf

    ld b, b
    ld a, l
    call WriteFieldDataBytes
    call $0547
    call $23f5
    call GameStateBit_0686
    ld a, $61
    call $0510
    ld a, $60
    jp PaletteStoreCD80


    call CallScriptByType
    jp nz, $4e8d

    ld bc, $ffa0
    call CrossBankCallRst10
    ld a, $52
    rst $20
    ld a, $21
    call BankTrampolineTable
    jp PaletteStoreCD80Alt


    ld a, [$c00f]
    cp $38
    jp nz, RestoreBankAfterTile

    ld [$c01a], a
    ld a, $c0
    ld [$ca80], a
    jp PaletteStoreCD80Alt


    call SetTimerHRAM90
    cp $05
    ret nz

    ld bc, $7d4e
    call $02be
    inc d
    ld bc, $9c1c
    call $05e2
    call $23f5
    jp PaletteStoreCD80Alt


    call SetTimerHRAM90
    call CheckCursorInput
    ld bc, $7d4e
    jp nz, $0298

    ld d, $cc
    ld bc, $ff40
    call CalcGateMonsterLevel
    ld bc, $0000
    call CalcGateMonsterLevel
    ld bc, $00c0
    call CalcGateMonsterLevel
    ld a, $44

jr_001_7cbf:
    call BankTrampolineTable
    jp PaletteStoreCD80Alt


    ld a, [$cc00]
    or a
    jp nz, Jump_001_4e9c

    ld a, $20
    jp PaletteStoreCD80


    call SetTimerHRAM90
    ld a, [$c982]
    and $07
    ret nz

    call CallScriptByType
    jr z, jr_001_7cf9

    call $07cc
    ld d, h
    ld [hl], $67
    call SetViewportParams
    inc [hl]
    and $3f
    add $14
    ld c, a
    call SetViewportParams
    and $0f
    add $94
    ld b, a
    jp $05e2


jr_001_7cf9:
    ld a, $52
    rst $20
    ld bc, $0038
    call CrossBankCallRst10
    ld d, $c1
    ld bc, $f820
    call $08ba
    xor a
    call RunScriptEngine
    ld bc, $00f8
    call $08ba
    ld a, $8b
    call RunScriptEngine
    inc a
    inc b
    call RunScriptEngine
    ld bc, $0000
    call $08ba
    ld de, $0107
    call $0b0c
    call CrossBankCallRet
    jp PaletteStoreCD80Alt


    ld a, [$c00f]
    cp $57
    jp nz, SerialTransferEpilogue

    ld [$c01a], a
    ld a, $c0
    jp PaletteStoreCD80


    call CallScriptByType
    jp nz, Jump_001_4e9c

    ld a, $5d
    ld [$c00f], a
    jp $4d80


    inc [hl]
    ld d, e
    ld bc, $ff54
    ld [$0856], sp
    ld d, a
    ld [$ff58], sp
    ld bc, $9982
    call EncounterWeightTable
    ld hl, $1f76
    call ReadHRAM_d6_2042
    xor a
    ld [$c995], a
    ld de, $4f00
    call SubHLFromHRAM_A5
    call GetSpriteAddress
    call ReadMenuDisplayData
    jp $15f7


    call LookupDoublePtrTable
    ret nz

    ld a, $50
    call $0510
    call $1e43
    ld a, $5c
    jp Jump_000_15f4


    ld a, [$cdff]
    inc a
    jr z, jr_001_7d9c

    ld a, [$cdaa]
    rst $00

    dw label7dba
    dw label7dc6
    dw label7dde
    dw label7de6

jr_001_7d9c:
    ld a, [$cda5]
    cp $06
    jr z, jr_001_7db4

    dec a
    res 2, a
    ld [$cdaa], a

ReadMenuDisplayData:
jr_001_7da9:
    ld hl, $cda5
    ld a, [hl]
    inc [hl]
    ld hl, $5bf8
    jp $095a


jr_001_7db4:
    xor a
    call TextEndOfLine
    jr jr_001_7da9

label7dba:
    call LoadEncounterTable

jr_001_7dbd:
    call EncounterDataTable_1
    ld bc, $98a3
    jp Jump_000_0aea

label7dc6:
    call SubHLFromHRAM_A7
    ld de, CheckNPCMovement
    ld bc, $9912

ProcessEncounterSetup:
jr_001_7dcf:
    call LoadEncounterTable
    jp Jump_RunScriptEngine


LoadEncounterTable:
    call EncounterDataTable_2
    ld hl, $c981
    ld [hl], $04
    ret

label7dde:
    ld de, $544d
    ld bc, $990d
    jr jr_001_7dcf

label7de6:
    ld de, $5546
    ld bc, $98ef
    call ProcessEncounterSetup
    inc a
    inc c
    jp Jump_RunScriptEngine


    call EncounterDataTable_2
    jr jr_001_7dbd

    xor a
    db $cd, $2b, $05
    xor a
    jp Jump_000_15f4


    call DispatchCD90
    ld a, [bc]
    ld a, [hl]
    sub a
    ld a, [hl]
    jp z, $cd7e

    pop de
    rra
    ld b, $ab
    call $2043
    call SubHLFromHRAM_A7
    ld bc, $1148
    call EnableLCD
    call LoadSpriteSheetData
    ld a, [$cda5]
    cp $04
    jr z, jr_001_7e38

    cp $07
    call z, $7e8d
    inc d

jr_001_7e2b:
    call $069e
    ld e, $00

jr_001_7e30:
    ld d, $68
    call $1e99
    jp PaletteStoreCD80Alt


jr_001_7e38:
    inc d
    ld bc, $bc7c
    call $05e2
    call GameStateBit_0686
    ld a, $12
    rst $20
    ld bc, $1c2f
    call $1196
    ld e, $50
    jr jr_001_7e30

LoadSpriteSheetData:
    ld d, $c0
    ld hl, $7e6d
    ld a, [$cda5]
    add a
    add a
    rst $28
    call IterateTableEntry
    inc d

IterateTableEntry:
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    push hl
    call $05e2
    ld l, $08
    inc [hl]
    pop hl
    jp Jump_000_0686


    jr z, jr_001_7e2b

    ld [hl], h
    db $e4
    jr z, @-$42

    ld [hl], h
    and $24
    cp h
    ld [hl], h
    ld [$c028], a
    ld [hl], h
    ld [c], a
    jr @-$42

    ld c, l
    and $24
    cp h
    ld [hl], h
    db $e4
    jr nz, @-$42

    ld [hl], h
    and $1f
    cp h
    ld l, h
    and $3e
    ld sp, $8fcd
    ld b, $06
    db $eb
    jp $2043


    call GetSpriteAddress
    ld hl, $c014
    dec [hl]
    inc h
    inc [hl]
    inc h
    dec [hl]
    ld hl, $c992
    inc [hl]
    ret nz

    ld hl, $cde0
    xor a
    rst $08
    call $091e
    ld bc, $cde0
    ld a, l
    ld [bc], a
    inc c
    ld a, h
    ld [bc], a
    ld a, [$cda5]
    cp $04
    call z, CalcCoordJumpMath
    ld a, $f0
    jp PaletteStoreCD80


CalcCoordJumpMath:
    ld de, CheckGameStateBit2
    jp Jump_000_1e65


    call CallScriptByType
    ret nz

    call AddHLToHRAM
    call CrossBankCallRet
    ld hl, $cda5
    ld a, [hl]
    inc [hl]
    cp $07
    jp nz, PaletteClearCD90

    xor a
    db $cd, $2b, $05
    ld a, $0e
    jp Jump_000_15e6


    ld l, c
    sbc b
    dec de
    rla
    dec h
    jr jr_001_7f02

    dec d
    cp $ac
    sbc b
    dec de
    rla
    inc hl
    inc hl
    inc de
    cp $78
    sbc b
    dec e
    add hl, de
    add hl, hl
    add hl, hl
    inc de
    cp $bb
    sbc b

jr_001_7f02:
    dec e
    inc d
    ld h, $19
    ld de, $69ff
    sbc b
    db $10
    ld de, $1c17
    ld [hl+], a
    inc de
    cp $ad
    sbc b
    dec e
    rla
    inc e
    ld [hl+], a
    cp $98
    sbc b
    ld e, $17
    dec d
    dec d
    dec de
    ld [de], a
    ld de, $ff11
    adc c
    sbc b
    jr nz, jr_001_7f39

    ld a, [de]
    jr @+$18

    inc hl
    cp $98
    sbc b
    ld e, $19
    ld e, $19
    rst $38
    ld l, c
    sbc b
    dec h
    jr nz, @+$1b

    dec d

jr_001_7f39:
    ld de, $1314
    cp $a9
    sbc b
    jr jr_001_7f61

    inc d
    nop
    ld de, BankSwitch_1616
    inc hl
    cp $78
    sbc b
    inc e
    ld [de], a
    ld de, $1a12
    add hl, de
    jr jr_001_7f65

    cp $ba
    sbc b
    inc e
    ld d, $13
    ld d, $18
    inc d
    rst $38
    adc c
    sbc c
    dec de
    ld d, $16

jr_001_7f61:
    ld [hl+], a
    daa
    ld d, $15

jr_001_7f65:
    ld a, [de]
    cp $98
    sbc c
    dec h
    daa
    inc d
    inc d
    jr jr_001_7f88

    inc d
    cp $00
    sbc h
    ld de, $1819
    jr @+$13

    inc d
    cp $41
    sbc h
    dec de
    inc d
    inc d
    db $10
    inc d
    dec d
    rst $38
    ld l, c
    sbc b
    rra
    ld d, $1f

jr_001_7f88:
    ld d, $fe
    xor l
    sbc b
    dec e
    ld d, $1d
    ld d, $fe
    sbc b
    sbc b
    dec h
    inc hl
    inc d
    inc d
    add hl, hl
    inc d
    dec d
    rst $38
    ld l, c
    sbc b
    inc e
    ld d, $23
    inc e
    ld d, $15
    dec e
    cp $ab
    sbc b
    inc e
    ld d, $23
    dec e
    ld d, $15
    cp $98
    sbc b
    inc d
    ld de, $131a
    dec d
    ld [de], a
    rst $38
    ld l, c
    sbc b
    ld a, [de]
    ld d, $23
    jr jr_001_7fd0

    inc hl
    ld [de], a
    cp $ae
    sbc b
    ld a, [de]
    ld [de], a

jr_001_7fc5:
    jr z, jr_001_7fc5

    ld a, b
    sbc b
    dec de
    ld [de], a
    dec de
    dec h
    cp $bb
    sbc b

jr_001_7fd0:
    dec de
    rla
    inc hl
    inc hl
    inc de
; =============================================================================
; FollowerArtResolve01 — Phase N follower-art fork for the $01 ScreenTransData copy.
; Reader passes HL = (species+$10)*2. id 221-239 (HL>=$1DA) -> the gfx-ID
; $7E00+(species-221)*2 is computed into wNewSpeciesGid (S105 G3; was a
; one-entry table for id 224); else the original add-base into
; ScreenTransDataTable (byte-identical to vanilla for species 0-220).
; Byte-neutral: 32 of the 33 trailing $FF padding bytes, leaving the clamp in place.
; =============================================================================
FollowerArtResolve01:                ; in: HL = (species+$10)*2
    ld a, h
    cp $01
    jr c, .normal                    ; h==0 -> HL<$100 (species<128)
    jr nz, .high                     ; h>=2 -> HL>=$200 (species>=240)
    ld a, l
    cp $da
    jr c, .normal                    ; HL<$1DA -> species<221
.high:                               ; species 221-239: the gfx-ID is COMPUTED (S105 G3)
    ld a, l                          ; L = low byte of (species+$10)*2
    sub $da                          ; = (species-221)*2 = the follower's index in bank $7E
    ld [wNewSpeciesGid], a
    ld a, $7e                        ; overflow bank $7E (compiler bank species7e)
    ld [wNewSpeciesGid+1], a
    ld hl, wNewSpeciesGid            ; caller reads the word at HL (DE is dead here)
    ret
.normal:
    ld de, ScreenTransDataTable
    add hl, de
    ret
    rst $38                          ; 1-byte padding refill (resolver=32B, run was 33B)
; --- Phase N: clamp species>=240 to a valid follower ---
; Lives in bank $01 end-of-bank padding (same bank as caller). Reached via the
; repointed species read in GetActiveMonsterStatus. Ids 221-239 are the new-species
; range (S105 G3: every bank-$7E follower slot 0-37 holds a real stream, gaps alias
; one); 240+ cannot be followers (species+$10 wraps in the bank-$04 router), so
; borrow species 214 to avoid a garbage-gfxID decompress crash.
ReadActiveMonsterByteSpeciesClamped:
    call ReadActiveMonsterByte        ; A = active monster species (ReadActiveMonsterByte is ROM0)
    cp $f0                            ; >= 240? (S105: was $e1 — only 224 passed)
    ret c                             ; no (0-239) -> real species
    ld a, $d6                         ; yes (240-255, no real monster) -> clamp to species 214
    ret
    db $01
