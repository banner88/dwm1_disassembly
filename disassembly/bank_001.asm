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
    ; Entry 12
    dw LoadNextDungeonFloor
    ; Entry 13: Load next dungeon floor ($69E1)

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
    call WaitInputRelease
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


LoadNewBGMIdIntoA:
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

    cp $61 ;maps do not go above 5F. This is unused. w
    jr nc, jr_001_4358

jr_001_4346:
    ld hl, $4373
    ld a, [wMapID]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld b, [hl]
    ld a, b
    cp $09
    ret nz

    ret


jr_001_4358:
    ld a, [wCurrentFloor]
    ld b, a
    ld a, [wLastFloor]
    sub $02
    cp b
    ld a, $34
    ret nz

    ld hl, $4373
    ld a, [wBossMapType]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ret


    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    ld e, $1e
    ld sp, $0931
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    ld e, $1e
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    sbc l
    inc [hl]
    inc c
    inc c
    jr jr_001_43bd

    inc c
    ld l, $18
    rrca
    jr @+$14

    ld l, $1b
    ld [de], a
    dec de
    dec de
    dec de
    dec de
    dec de
    dec de
    ld [de], a
    dec de
    inc c
    rrca
    ld [de], a
    ld [de], a

jr_001_43bd:
    dec d
    dec d
    jr jr_001_43dc

    dec de
    dec de
    inc [hl]
    inc [hl]
    ld h, c
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    ld h, c
    ld [bc], a
    ld [bc], a
    dec de
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]

jr_001_43dc:
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]
    inc [hl]

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
    ldh a, [$d5]
    cp $5e
    jr z, jr_001_4425

    cp $5d
    jr nz, jr_001_4412

    ld a, $01
    ret


jr_001_4412:
    ldh a, [$d5]
    cp $2f
    jr nz, jr_001_441b

    ld a, $02
    ret


jr_001_441b:
    ldh a, [$d5]
    cp $30
    ld a, $03
    ret c

    ld a, $00
    ret


jr_001_4425:
    ld a, [$c81b]
    ret


LoadFieldTilesDMA:
    ld de, $2f00
    ld hl, $8000
    call WaitDMATransfer
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
    ld a, [wMapID]
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
    call WaitInputRelease
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
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    inc b
    ld a, b
    cp $14
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
    ld b, $14

jr_001_473d:
    ld a, [hl]
    or a
    jr z, jr_001_4743

    ld [hl], $01

jr_001_4743:
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
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
    ld hl, $c0d8
    ld bc, $0014
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_001_47ad:
    ld a, [de]
    or a
    jr z, jr_001_47b3

    ld [hl], c
    inc c

jr_001_47b3:
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    inc hl
    dec b
    jr nz, jr_001_47ad

    ld c, $14

jr_001_47c1:
    ld hl, $cac1
    ld b, $13

jr_001_47c6:
    ld a, [hl]
    or a
    call z, SaveRegsAndSetupDE
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
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
    ld hl, $0106
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
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
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

    ld hl, $c0d8
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


; Overworld WALKING-follower art loader (called 3x: party slots 0/1/2 via $cac0).
; For each slot: reads species at $caca, +$10, indexes ScreenTransDataTable -> gfx-ID, DMAs the
; 16-tile art to VRAM tiles $20/$30/$40, and returns $ffc7=species+$10 (stored to $ca91/92/93 by
; the caller; the metasprite engine reads tile base $ffc9=$20/$30/$40 and sprite-type $ffc7 from
; these). NOTE for NEW species (id>=215): the patches/ build inserts a species clamp before the
; $caca read (ReadActiveMonsterByteSpeciesClamped); narrow it to >=225 or the new species' overworld
; art falls back to species 214. See MONSTER_DATA.md "NEW species followers".
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
    call ReadActiveMonsterByte
    add $10

jr_001_49a2:
    push af
    ld l, a
    ld h, $00
    add hl, hl
    ld a, l
    add LOW(ScreenTransDataTable)   ; [1/8] follower gfx-ID copy (overworld). A swap/new
    ld l, a                         ;   species must repoint ALL 8 copies:
    ld a, h                         ;   $01/$06/$07/$09/$0b/$12/$18/$59 (see MONSTER_DATA).
    adc HIGH(ScreenTransDataTable)
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [$cac0]
    add $82
    ld h, a
    ld l, $00
    call WaitDMATransfer
    ld hl, $cacb
    call ReadActiveMonsterByte
    add a
    ld hl, FollowerFamilyGfxTable
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
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
    ; species 0.. followers (index = species + $10):
    dw $2f01, $2f02, $2f03, $2f04, $2f05, $2f06, $2f07, $2f08
    dw $2f09, $2f0a, $2f0b, $2f0c, $2f0d, $2f0e, $2f0f, $2f10
    dw $3800, $3801, $3802, $3803, $3804, $3805, $3806, $3807
    dw $3808, $3809, $380a, $380b, $380c, $380d, $380e, $380f
    dw $3810, $3811, $3812, $3813, $3814, $3815, $3816, $3817
    dw $3818, $3819, $381a, $381b, $381c, $381d, $381e, $381f
    dw $3820, $3821, $3822, $3823, $3824, $3825, $3826, $3827
    dw $3828, $3829, $382a, $382b, $382c, $382d, $382e, $382f
    dw $3830, $3831, $3832, $3833, $3834, $3835, $3836, $3837
    dw $3838, $3839, $383a, $383b, $383c, $383d, $383e, $383f
    dw $3840, $3841, $3842, $3843, $3844, $3845, $3846, $3847
    dw $3900, $3901, $3902, $3903, $3904, $3905, $3906, $3907
    dw $3908, $3909, $390a, $390b, $390c, $390d, $390e, $390f
    dw $3910, $3911, $3912, $3913, $3914, $3915, $3916, $3917
    dw $3918, $3919, $391a, $391b, $391c, $391d, $391e, $391f
    dw $3920, $3921, $3922, $3923, $3924, $3925, $3926, $3927
    dw $3928, $3929, $392a, $392b, $392c, $392d, $392e, $392f
    dw $3930, $3931, $3932, $3933, $3934, $3935, $3936, $3937
    dw $3938, $3939, $393a, $393b, $393c, $393d, $393e, $393f
    dw $3940, $3941, $3942, $3943, $3944, $3945, $3946, $3947
    dw $3a00, $3a01, $3a02, $3a03, $3a04, $3a05, $3a06, $3a07
    dw $3a08, $3a09, $3a0a, $3a0b, $3a0c, $3a0d, $3a0e, $3a0f
    dw $3a10, $3a11, $3a12, $3a13, $3a14, $3a15, $3a16, $3a17
    dw $3a18, $3a19, $3a1a, $3a1b, $3a1c, $3a1d, $3a1e, $3a1f
    dw $3a20, $3a21, $3a22, $3a23, $3a24, $3a25, $3a26, $3a27
    dw $3a28, $3a29, $3a2a, $3a2b, $3a2c, $3a2d, $3a2e, $3a2f
    dw $3a30, $3a31, $3a32, $3a33, $3a34, $3a35, $3a36

FollowerFamilyGfxTable:
    ; Family-shared follower block (2nd DMA in GetActiveMonsterStatus,
    ; via `ld hl, FollowerFamilyGfxTable` + family-byte index). 10 entries,
    ; families 0-9 -> $2E03..$2E0C (B9 ClampFamIdx keeps family>=10 in range).
    dw $2e03, $2e04, $2e05, $2e06, $2e07, $2e08, $2e09, $2e0a
    dw $2e0b, $2e0c

IteratePartySlots20:
    ld hl, $cac1
    ld b, $14
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
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
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
    ld a, [wMapID]
    ld [wScriptMapType], a            ; map type = current map
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
    call WaitInputRelease
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
    call WaitInputRelease
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
    call WaitInputRelease
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
    call WaitInputRelease
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
    call WaitInputRelease

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
; NPCTalkHandler — "Player pressed A near NPC" dispatcher
; ===========================================================================
; Called when the player presses A while facing an NPC.
; Reads player position from HRAM ($FF92-$FF96), calls bank $0B entry 5
; to find the NPC at the facing position and retrieve its script_id.
;
; If an NPC is found ($FFD5 != $FF):
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
    ldh [$db], a             ; Store to $FFDB (facing position low)
    ld a, h
    ldh [$dc], a             ; Store to $FFDC (facing position high)
    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, l
    ldh [$dd], a             ; Store to $FFDD (facing tile low)
    ld a, h
    ldh [$de], a             ; Store to $FFDE (facing tile high)
    ld hl, $0b05             ; Bank $0B entry 5: NPC lookup at facing position
    rst $10                  ; Returns script_id in $FFD5 ($FF if no NPC)
    ldh a, [$d5]             ; Read script_id result
    cp $ff
    ret z                    ; No NPC found → return

    ld [wScriptNPCId], a            ; ★ Store NPC script_id for script bank lookup
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

    ld a, [wMapID]
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
    call WaitInputRelease
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
    call WaitInputRelease
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
    call WaitInputRelease
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
    call WaitInputRelease
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
    ld a, [wEncounterPoolIndex]
    add $0a
    ld c, a
    ld a, [wCurrentFloor]
    inc a
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
    call CheckGateworldForNPC
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


CheckGateworldForNPC:
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
    jr z, jr_001_5dd5

    cp $10
    jr z, jr_001_5de6

    cp $11
    jr z, jr_001_5df7

    cp $12
    jr z, jr_001_5e08

    ret


jr_001_5dd5:
    ld hl, Boot
    ld a, l
    ldh [$a1], a
    ld a, h
    ldh [$a2], a
    ld hl, $ff90
    set 1, [hl]
    set 0, [hl]
    ret


jr_001_5de6:
    ld hl, $ff00
    ld a, l
    ldh [$a1], a
    ld a, h
    ldh [$a2], a
    ld hl, $ff90
    set 1, [hl]
    set 0, [hl]
    ret


jr_001_5df7:
    ld hl, Boot
    ld a, l
    ldh [$a3], a
    ld a, h
    ldh [$a4], a
    ld hl, $ff90
    set 1, [hl]
    set 0, [hl]
    ret


jr_001_5e08:
    ld hl, $ff00
    ld a, l
    ldh [$a3], a
    ld a, h
    ldh [$a4], a
    ld hl, $ff90
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

    ld a, [wMapID]
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

; Per-room VRAM update function
; Called from main game loop. Checks various state flags, then dispatches
; to a per-room handler via rst $00 indexed by wMapID.
; NOT the NPC text system — handlers do palette animation and tile swaps.
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
    bit 5, a
    ret nz

    bit 6, a
    ret nz

    bit 2, a
    ret nz

    bit 1, a
    ret nz

    bit 3, a
    ret nz

    bit 7, a
    ret nz

    bit 4, a
    jr z, jr_001_6115

    ld a, [$c8ef]
    cp $0f
    ret z

; The actual dispatch point: ld a,[wMapID]; rst $00
; Jump table follows (107 entries indexed by map_type)
PerRoomDispatchEntry:
jr_001_6115:  ; original label
    ld a, [wMapID]
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

; Castle ($00): LD HL,$94D0; CALL $65E0 — VRAM update
Handler_Castle:
label1_61f9:  ; original label
    ld hl, $94d0
    call CheckVisualEffectType
    ret

; GreatTree ($01): CALL $659F — story event visual effect
Handler_GreatTree:
label1_6200:  ; original label
    call GetVisualEffectMask
    ret

; Bazaar ($02): RET — no visual update
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

; GateHub ($03-$07): RET — no visual update
Handler_GateHub:
label1_621f:  ; original label
    ret

; GateHub2 ($08): Palette animation
; Reads $C8A6/$C8A7 as 16-bit counter, shifts right 5, indexes palette table
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

; StarryShrine ($09): RET — no visual update
Handler_StarryShrine:
label1_62b2:  ; original label
    ret

; SecretPassage ($0A): CALL $659F
Handler_SecretPassage:
label1_62b3:  ; original label
    call GetVisualEffectMask
    ret

; $0B-$0F: RET
Handler_RET_Group1:
label1_62b7:  ; original label
    ret

; $10-$18 (Copycat through Well): RET
Handler_RET_Group2:
label1_62b8:  ; original label
    ret

; GoopyRoom1/2 ($19/$1A): VRAM tile swap
; Checks $C8A6 AND $1F == 3, then copies tiles $9320↔$93D0
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

label1_62cd:
    ret

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

label1_62e2:
    ret

label1_62e3:
    ret

label1_62e4:
    ret

; Map $20/$21 (Castle aliases): VRAM tile swap
; Same pattern: $C8A6 check, copies $9320↔$9380
; THIS is what crashes when custom room NPCs are talked to:
; $C8A6 AND $1F == 3 passes, then copies garbage VRAM addresses
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

label1_62f9:
    ret

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

label1_630e:
    ret

label1_630f:
    ret

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

label1_6335:
    ret

label1_6336:
    ld hl, $9250
    call CheckVisualEffectType
    ret

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

label1_6376:
    ret

label1_6377:
    ld hl, $9180
    call CheckVisualEffectType
    ret

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

label1_63b1:
    ld hl, $91e0
    call CheckVisualEffectType
    ret

label1_63b8:
    ret

label1_63b9:
    ret

label1_63ba:
    ret

label1_63bb:
    ret

label1_63bc:
    ret

label1_63bd:
    ret

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

label1_63d2:
    ret

label1_63d3:
    ret

label1_63d4:
    ret

label1_63d5:
    ret

label1_63d6:
    ld hl, $9560
    call CheckVisualEffectType
    ret

label1_63dd:
    ld hl, $90a0
    call CheckVisualEffectType
    ret

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

label1_63f8:
    ret

label1_63f9:
    ret

label1_63fa:
    ret

label1_63fb:
    ret

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

label1_6422:
    ret

label1_6423:
    ld hl, $9460
    call CheckVisualEffectType
    ret

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

label1_648d:
    ret

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

label1_64b4:
    ret

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

label1_64da:
    ret

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

label1_64ef:
    ret

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

label1_6542:
    ret

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

label1_659e:
    ret


; Text/event visual helper
; Checks $C8A6 AND $1F for values $05, $07
; Different paths for different interaction states
; Reads from $9400, calls $65D4, $66BC, $668F
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

VRAMEffectStep:
    call VRAMRotateRight
    call VRAMRotateRight
    call VRAMRotateRight
    jp Jump_001_6636


; VRAM update helper (used by Castle handler)
; Checks $C8A6 AND $7F against values $07, $27, $47, $67
; Different VRAM copy operations for each
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


; VRAM tile swap routine
; DI; copies B bytes between [HL] and [DE] (swap, not just copy)
; Used by room handlers for animated tile effects
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


; VRAM tile copy routine (one-way)
; DI; copies tiles from [HL] area using VRAM-safe timing
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
; ENCOUNTER POOL FORMAT (26 bytes each at $6AAE + pool_index × 26):
;   +0:  header (10 bytes, includes floor range info)
;   +10: EID slots (5 × 2 bytes LE) — enemy stats IDs for this pool
;   +20: weights (5 × 1 byte) — probability weights for each slot
;        (unused slots have EID $0000 and weight 0)
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
    ld a, [wEncounterPoolIndex]
    ld bc, $001a
    call Mul16x8To24
    ld a, l
    add LOW(EncounterPoolData + 2)
    ld l, a
    ld a, h
    adc HIGH(EncounterPoolData + 2)
    ld h, a
    ld b, $00
    ld de, $c0d8
    call LookupEncounterEntry
    call LookupEncounterEntry
    call LookupEncounterEntry
    ld hl, $c0d8
    call CalcEncounterPoolIdx
    ld [$da02], a
    ld a, [wEncounterPoolIndex]
    ld bc, $001a
    call Mul16x8To24
    ld a, l
    add LOW(EncounterPoolData + 5)
    ld l, a
    ld a, h
    adc HIGH(EncounterPoolData + 5)
    ld h, a
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
    ld a, [wEncounterPoolIndex]
    ld bc, $001a
    call Mul16x8To24
    ld a, l
    add LOW(EncounterPoolData + 10)
    ld l, a
    ld a, h
    adc HIGH(EncounterPoolData + 10)
    ld h, a
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


SaveRegsForEncounter:
    push af
    push bc
    ld a, [wEncounterPoolIndex]
    ld bc, $001a
    call Mul16x8To24
    ld a, l
    add LOW(EncounterPoolData + 20)
    ld l, a
    ld a, h
    adc HIGH(EncounterPoolData + 20)
    ld h, a
    pop bc
    pop af
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ret


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


LookupEncounterEntry:
    ld a, [hl]
    push hl
    ld hl, $69c0
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


    nop
    ld a, [bc]
    inc d
    ld e, $28
    ld [hl-], a
    ld b, [hl]
    ld h, h


LoadFloorAndEncounterData:
    call LoadNextDungeonFloor
    ld a, [wEncounterPoolIndex]
    ld bc, $001a
    call Mul16x8To24
    ld a, l
    add LOW(EncounterPoolData + 25)
    ld l, a
    ld a, h
    adc HIGH(EncounterPoolData + 25)
    ld h, a
    ld a, [hl]
    ld [$c93d], a
    ret


; EncounterPoolSelect — Determine encounter pool index from gate + floor
; Input: wGateID = current gate, $C939 = current floor number
; Output: $CA38 = pool index
; Algorithm:
;   1. Read base pool index from $6A22[wGateID]
;   2. Read floor breakpoint table pointer from $6A42[wGateID × 2]
;   3. Walk breakpoints to find which sub-pool matches current floor
;   4. Pool index = base + floor_offset
;   5. Calculate pool data address = $6AAE + pool_index × 26($1A)
LoadNextDungeonFloor:
    ld a, [wGateID]
    ld hl, GateBasePoolIndex             ; per-gate base pool index table
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]               ; A = base pool index for this gate
    push af
    ld a, [wGateID]
    add a                    ; × 2 for pointer table
    ld hl, GateFloorBreakpoints             ; per-gate floor breakpoint pointer table
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]              ; read pointer (little-endian)
    ld h, [hl]
    ld l, a                  ; HL = floor breakpoint list for this gate
    ld c, $ff                ; C = floor sub-index counter

jr_001_6a01:
    ld a, [wCurrentFloor]            ; current floor
    inc a
    cp [hl]                  ; compare with breakpoint
    inc c                    ; advance sub-index
    inc hl
    jr nc, jr_001_6a01       ; if floor >= breakpoint, keep checking

    pop af                   ; A = base pool index
    add c                    ; + floor sub-index
    ld [wEncounterPoolIndex], a            ; store final pool index
    ld bc, $001a
    call Mul16x8To24
    ld a, l
    add LOW(EncounterPoolData)
    ld l, a
    ld a, h
    adc HIGH(EncounterPoolData)
    ld h, a
    ld a, [hl]
    ld [$c8a9], a
    ret



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
    dw $6AA3  ; [23] Gate of Demolition (Hargon)
    dw $6AA3  ; [24] Gate of Demolition (Sidoh)
    dw $6AA3  ; [25] Gate of Mastermind
    dw $6AA3  ; [26] Gate of Control
    dw $6AA3  ; [27] Gate of Extinction
    dw $6AA3  ; [28] Gate of Sleep
    dw $6AA3  ; [29] Bazaar Edge Gate
    dw $6AA3  ; [30] Arena - Right Gate
    dw $6AA7  ; [31] Unused Gate (99 Floors)

; Floor breakpoint data ($6A82)
; Variable-length lists of floor thresholds, $FF-terminated
; Referenced by pointers above
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

EncounterPoolData:
; --- Pool 0 ($6AAE): Gate of Beginning ---
EncounterPool_000:
    db $03, $01, $07, $00, $00, $03, $05, $02, $00, $00  ; Header
    dw 2, 4, 3, 0, 0  ; EIDs: Slime, Dracky, Anteater, (none), (none)
    db 1, 1, 1, 0, 0  ; Weights
    db 8  ; Extra

; --- Pool 1 ($6AC8): Gate of Villager ---
EncounterPool_001:
    db $03, $02, $05, $05, $00, $03, $03, $02, $02, $00  ; Header
    dw 5, 6, 3, 14, 0  ; EIDs: Stubsuck, GoHopper, Anteater, Picky, (none)
    db 3, 3, 3, 1, 0  ; Weights
    db 8  ; Extra

; --- Pool 2 ($6AE2): Gate of Villager ---
EncounterPool_002:
    db $03, $03, $03, $05, $02, $03, $03, $03, $01, $00  ; Header
    dw 5, 6, 7, 15, 0  ; EIDs: Stubsuck, GoHopper, Gremlin, PillowRat, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 8  ; Extra

; --- Pool 3 ($6AFC): Gate of Talisman ---
EncounterPool_003:
    db $03, $03, $03, $05, $02, $03, $03, $02, $02, $00  ; Header
    dw 8, 10, 3, 13, 0  ; EIDs: Spooky, ArmyAnt, Anteater, MiniDrak, (none)
    db 3, 3, 3, 1, 0  ; Weights
    db 8  ; Extra

; --- Pool 4 ($6B16): Gate of Talisman ---
EncounterPool_004:
    db $03, $03, $03, $05, $02, $03, $03, $03, $01, $00  ; Header
    dw 8, 9, 10, 14, 0  ; EIDs: Spooky, Goopi, ArmyAnt, Picky, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 8  ; Extra

; --- Pool 5 ($6B30): Gate of Memories ---
EncounterPool_005:
    db $03, $03, $03, $06, $00, $03, $03, $02, $02, $00  ; Header
    dw 9, 15, 17, 19, 0  ; EIDs: Goopi, PillowRat, DragonKid, Catapila, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 8  ; Extra

; --- Pool 6 ($6B4A): Gate of Memories ---
EncounterPool_006:
    db $03, $03, $02, $03, $05, $04, $03, $02, $01, $00  ; Header
    dw 14, 20, 19, 25, 0  ; EIDs: Picky, FairyRat, Catapila, SpotSlime, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 8  ; Extra

; --- Pool 7 ($6B64): Gate of Bewilder ---
EncounterPool_007:
    db $03, $03, $03, $06, $00, $03, $03, $02, $02, $00  ; Header
    dw 13, 21, 17, 25, 0  ; EIDs: MiniDrak, BigRoost, DragonKid, SpotSlime, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 8  ; Extra

; --- Pool 8 ($6B7E): Gate of Bewilder ---
EncounterPool_008:
    db $03, $03, $02, $03, $05, $04, $03, $02, $01, $00  ; Header
    dw 18, 22, 25, 16, 0  ; EIDs: EvilSeed, Demonite, SpotSlime, Hork, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 8  ; Extra

; --- Pool 9 ($6B98): Bazaar Gate ---
EncounterPool_009:
    db $04, $03, $03, $05, $02, $03, $03, $02, $02, $00  ; Header
    dw 20, 21, 25, 26, 0  ; EIDs: FairyRat, BigRoost, SpotSlime, Crestpent, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 10 ($6BB2): Bazaar Gate ---
EncounterPool_010:
    db $04, $03, $03, $05, $02, $04, $03, $02, $01, $00  ; Header
    dw 21, 17, 19, 27, 0  ; EIDs: BigRoost, DragonKid, Catapila, BeanMan, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 11 ($6BCC): Bazaar Gate ---
EncounterPool_011:
    db $04, $03, $03, $04, $03, $04, $03, $02, $01, $00  ; Header
    dw 22, 19, 16, 28, 0  ; EIDs: Demonite, Catapila, Hork, 1EyeClown, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 12 ($6BE6): Gate of Peace ---
EncounterPool_012:
    db $03, $03, $03, $05, $02, $03, $03, $03, $01, $00  ; Header
    dw 21, 25, 29, 26, 0  ; EIDs: BigRoost, SpotSlime, CoilBird, Crestpent, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 13 ($6C00): Gate of Peace ---
EncounterPool_013:
    db $03, $03, $02, $05, $03, $04, $03, $02, $01, $00  ; Header
    dw 17, 26, 23, 33, 0  ; EIDs: DragonKid, Crestpent, BoneSlave, Almiraj, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 14 ($6C1A): Gate of Peace ---
EncounterPool_014:
    db $03, $03, $03, $04, $03, $04, $03, $02, $01, $00  ; Header
    dw 16, 26, 33, 34, 0  ; EIDs: Hork, Crestpent, Almiraj, BullBird, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 15 ($6C34): Gate of Bravery ---
EncounterPool_015:
    db $03, $03, $03, $05, $02, $03, $03, $03, $01, $00  ; Header
    dw 22, 27, 28, 35, 0  ; EIDs: Demonite, BeanMan, 1EyeClown, FloraMan, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 16 ($6C4E): Gate of Bravery ---
EncounterPool_016:
    db $03, $03, $02, $05, $03, $04, $03, $02, $01, $00  ; Header
    dw 27, 35, 24, 36, 0  ; EIDs: BeanMan, FloraMan, SabreMan, GiantWorm, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 17 ($6C68): Gate of Bravery ---
EncounterPool_017:
    db $03, $03, $03, $04, $03, $04, $03, $02, $01, $00  ; Header
    dw 27, 35, 36, 34, 0  ; EIDs: BeanMan, FloraMan, GiantWorm, BullBird, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 18 ($6C82): Well Gate ---
EncounterPool_018:
    db $04, $03, $00, $06, $03, $03, $03, $03, $01, $00  ; Header
    dw 23, 33, 35, 38, 0  ; EIDs: BoneSlave, Almiraj, FloraMan, GiantSlug, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 3  ; Extra

; --- Pool 19 ($6C9C): Well Gate ---
EncounterPool_019:
    db $04, $03, $00, $06, $03, $04, $03, $02, $01, $00  ; Header
    dw 33, 40, 35, 38, 0  ; EIDs: Almiraj, TreeSlime, FloraMan, GiantSlug, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 3  ; Extra

; --- Pool 20 ($6CB6): Well Gate ---
EncounterPool_020:
    db $04, $03, $00, $06, $03, $04, $03, $02, $01, $00  ; Header
    dw 36, 34, 35, 39, 0  ; EIDs: GiantWorm, BullBird, FloraMan, MudDoll, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 3  ; Extra

; --- Pool 21 ($6CD0): Well Gate ---
EncounterPool_021:
    db $04, $03, $00, $06, $03, $03, $02, $02, $02, $01  ; Header
    dw 34, 24, 35, 39, 30  ; EIDs: BullBird, SabreMan, FloraMan, MudDoll, Metaly
    db 3, 3, 3, 3, 3  ; Weights
    db 3  ; Extra

; --- Pool 22 ($6CEA): Gate of Strength ---
EncounterPool_022:
    db $03, $03, $01, $05, $04, $03, $03, $02, $02, $00  ; Header
    dw 39, 40, 37, 47, 0  ; EIDs: MudDoll, TreeSlime, SkulRider, FairyDrak, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 23 ($6D04): Gate of Strength ---
EncounterPool_023:
    db $03, $03, $01, $05, $04, $03, $03, $03, $01, $00  ; Header
    dw 39, 37, 47, 43, 0  ; EIDs: MudDoll, SkulRider, FairyDrak, WingTree, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 24 ($6D1E): Gate of Strength ---
EncounterPool_024:
    db $03, $03, $01, $05, $04, $04, $03, $02, $01, $00  ; Header
    dw 40, 37, 43, 46, 0  ; EIDs: TreeSlime, SkulRider, WingTree, DrakSlime, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 25 ($6D38): Gate of Strength ---
EncounterPool_025:
    db $03, $03, $01, $05, $04, $04, $03, $02, $01, $00  ; Header
    dw 40, 43, 47, 46, 0  ; EIDs: TreeSlime, WingTree, FairyDrak, DrakSlime, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 26 ($6D52): Gate of Anger ---
EncounterPool_026:
    db $03, $03, $01, $05, $04, $03, $03, $02, $02, $00  ; Header
    dw 36, 38, 41, 42, 0  ; EIDs: GiantWorm, GiantSlug, Poisongon, CatFly, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 27 ($6D6C): Gate of Anger ---
EncounterPool_027:
    db $03, $03, $01, $05, $04, $03, $03, $03, $01, $00  ; Header
    dw 38, 41, 42, 44, 0  ; EIDs: GiantSlug, Poisongon, CatFly, Eyeder, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 28 ($6D86): Gate of Anger ---
EncounterPool_028:
    db $03, $03, $01, $05, $04, $04, $03, $02, $01, $00  ; Header
    dw 42, 41, 44, 45, 0  ; EIDs: CatFly, Poisongon, Eyeder, Putrepup, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 29 ($6DA0): Gate of Anger ---
EncounterPool_029:
    db $03, $03, $01, $05, $04, $04, $03, $02, $01, $00  ; Header
    dw 42, 44, 45, 46, 0  ; EIDs: CatFly, Eyeder, Putrepup, DrakSlime, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 30 ($6DBA): Farm Gate ---
EncounterPool_030:
    db $04, $03, $00, $05, $05, $03, $03, $02, $02, $00  ; Header
    dw 47, 49, 50, 48, 0  ; EIDs: FairyDrak, Butterfly, MadRaven, Skullroo, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 31 ($6DD4): Farm Gate ---
EncounterPool_031:
    db $04, $03, $00, $05, $05, $03, $03, $03, $01, $00  ; Header
    dw 47, 50, 48, 57, 0  ; EIDs: FairyDrak, MadRaven, Skullroo, Mudron, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 32 ($6DEE): Farm Gate ---
EncounterPool_032:
    db $04, $03, $00, $05, $05, $04, $03, $02, $01, $00  ; Header
    dw 46, 50, 48, 58, 0  ; EIDs: DrakSlime, MadRaven, Skullroo, Facer, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 33 ($6E08): Farm Gate ---
EncounterPool_033:
    db $04, $03, $00, $05, $05, $04, $03, $02, $01, $00  ; Header
    dw 46, 48, 57, 58, 0  ; EIDs: DrakSlime, Skullroo, Mudron, Facer, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 34 ($6E22): Gate of Joy ---
EncounterPool_034:
    db $03, $03, $01, $04, $05, $03, $03, $02, $02, $00  ; Header
    dw 59, 60, 62, 61, 0  ; EIDs: Snaily, Saccer, Gulpple, MadPecker, (none)
    db 3, 3, 3, 1, 0  ; Weights
    db 15  ; Extra

; --- Pool 35 ($6E3C): Gate of Joy ---
EncounterPool_035:
    db $03, $03, $01, $04, $05, $03, $03, $03, $01, $00  ; Header
    dw 59, 60, 62, 61, 0  ; EIDs: Snaily, Saccer, Gulpple, MadPecker, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 36 ($6E56): Gate of Joy ---
EncounterPool_036:
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 60, 62, 63, 61, 0  ; EIDs: Saccer, Gulpple, EyeBall, MadPecker, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 37 ($6E70): Gate of Joy ---
EncounterPool_037:
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 60, 63, 65, 64, 0  ; EIDs: Saccer, EyeBall, Babble, Mummy, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 38 ($6E8A): Gate of Joy ---
EncounterPool_038:
    db $04, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 65, 63, 61, 64, 0  ; EIDs: Babble, EyeBall, MadPecker, Mummy, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 39 ($6EA4): Gate of Wisdom ---
EncounterPool_039:
    db $03, $03, $01, $04, $05, $03, $03, $02, $02, $00  ; Header
    dw 58, 67, 68, 66, 0  ; EIDs: Facer, Tonguella, Florajay, Pteranod, (none)
    db 3, 3, 3, 1, 0  ; Weights
    db 15  ; Extra

; --- Pool 40 ($6EBE): Gate of Wisdom ---
EncounterPool_040:
    db $03, $03, $01, $04, $05, $03, $03, $03, $01, $00  ; Header
    dw 58, 67, 68, 66, 0  ; EIDs: Facer, Tonguella, Florajay, Pteranod, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 41 ($6ED8): Gate of Wisdom ---
EncounterPool_041:
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 67, 68, 66, 70, 0  ; EIDs: Tonguella, Florajay, Pteranod, ArmorPede, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 42 ($6EF2): Gate of Wisdom ---
EncounterPool_042:
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 67, 66, 69, 70, 0  ; EIDs: Tonguella, Pteranod, MadPlant, ArmorPede, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 43 ($6F0C): Gate of Wisdom ---
EncounterPool_043:
    db $04, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 66, 69, 71, 70, 0  ; EIDs: Pteranod, MadPlant, MedusaEye, ArmorPede, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 44 ($6F26): Arena - Left Gate ---
EncounterPool_044:
    db $04, $03, $00, $03, $06, $03, $03, $02, $02, $00  ; Header
    dw 73, 72, 71, 74, 0  ; EIDs: WingSlime, MadCandle, MedusaEye, MadGopher, (none)
    db 3, 3, 3, 1, 0  ; Weights
    db 3  ; Extra

; --- Pool 45 ($6F40): Arena - Left Gate ---
EncounterPool_045:
    db $04, $03, $00, $03, $06, $03, $03, $03, $01, $00  ; Header
    dw 73, 72, 71, 74, 0  ; EIDs: WingSlime, MadCandle, MedusaEye, MadGopher, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 46 ($6F5A): Arena - Left Gate ---
EncounterPool_046:
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00  ; Header
    dw 72, 71, 74, 81, 0  ; EIDs: MadCandle, MedusaEye, MadGopher, Slabbit, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 47 ($6F74): Arena - Left Gate ---
EncounterPool_047:
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00  ; Header
    dw 72, 74, 83, 81, 0  ; EIDs: MadCandle, MadGopher, WindBeast, Slabbit, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 48 ($6F8E): Arena - Left Gate ---
EncounterPool_048:
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00  ; Header
    dw 74, 83, 81, 82, 0  ; EIDs: MadGopher, WindBeast, Slabbit, Gasgon, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 49 ($6FA8): Gate of Happiness ---
EncounterPool_049:
    db $03, $03, $01, $04, $05, $03, $03, $02, $02, $00  ; Header
    dw 85, 86, 87, 82, 0  ; EIDs: Oniono, Gophecada, Pixy, Gasgon, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 50 ($6FC2): Gate of Happiness ---
EncounterPool_050:
    db $03, $03, $01, $04, $05, $03, $03, $03, $01, $00  ; Header
    dw 85, 86, 87, 88, 0  ; EIDs: Oniono, Gophecada, Pixy, DeadNite, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 51 ($6FDC): Gate of Happiness ---
EncounterPool_051:
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 85, 86, 87, 88, 0  ; EIDs: Oniono, Gophecada, Pixy, DeadNite, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 52 ($6FF6): Gate of Happiness ---
EncounterPool_052:
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 86, 87, 88, 84, 0  ; EIDs: Gophecada, Pixy, DeadNite, StubBird, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 53 ($7010): Gate of Happiness ---
EncounterPool_053:
    db $04, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 86, 88, 89, 84, 0  ; EIDs: Gophecada, DeadNite, SpikyBoy, StubBird, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 54 ($702A): Gate of Temptation ---
EncounterPool_054:
    db $03, $03, $01, $04, $05, $03, $03, $02, $02, $00  ; Header
    dw 89, 91, 92, 90, 0  ; EIDs: SpikyBoy, KingCobra, Mommonja, SlimeNite, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 55 ($7044): Gate of Temptation ---
EncounterPool_055:
    db $03, $03, $01, $04, $05, $03, $03, $03, $01, $00  ; Header
    dw 89, 91, 92, 90, 0  ; EIDs: SpikyBoy, KingCobra, Mommonja, SlimeNite, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 56 ($705E): Gate of Temptation ---
EncounterPool_056:
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 91, 92, 90, 94, 0  ; EIDs: KingCobra, Mommonja, SlimeNite, StagBug, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 57 ($7078): Gate of Temptation ---
EncounterPool_057:
    db $03, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 91, 90, 93, 94, 0  ; EIDs: KingCobra, SlimeNite, MistyWing, StagBug, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 58 ($7092): Gate of Temptation ---
EncounterPool_058:
    db $04, $03, $01, $04, $05, $04, $03, $02, $01, $00  ; Header
    dw 90, 93, 95, 94, 0  ; EIDs: SlimeNite, MistyWing, DarkEye, StagBug, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 59 ($70AC): Medal Gate ---
EncounterPool_059:
    db $04, $03, $00, $03, $06, $03, $03, $02, $02, $00  ; Header
    dw 96, 98, 107, 105, 0  ; EIDs: NiteWhip, BoxSlime, Gismo, Orc, (none)
    db 3, 3, 3, 1, 0  ; Weights
    db 3  ; Extra

; --- Pool 60 ($70C6): Medal Gate ---
EncounterPool_060:
    db $04, $03, $00, $03, $06, $03, $03, $03, $01, $00  ; Header
    dw 96, 98, 107, 105, 0  ; EIDs: NiteWhip, BoxSlime, Gismo, Orc, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 61 ($70E0): Medal Gate ---
EncounterPool_061:
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00  ; Header
    dw 98, 107, 105, 97, 0  ; EIDs: BoxSlime, Gismo, Orc, RogueNite, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 62 ($70FA): Medal Gate ---
EncounterPool_062:
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00  ; Header
    dw 98, 105, 106, 97, 0  ; EIDs: BoxSlime, Orc, Reaper, RogueNite, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 63 ($7114): Medal Gate ---
EncounterPool_063:
    db $04, $03, $00, $03, $06, $04, $03, $02, $01, $00  ; Header
    dw 105, 106, 107, 97, 0  ; EIDs: Orc, Reaper, Gismo, RogueNite, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 3  ; Extra

; --- Pool 64 ($712E): Gate of Labyrinth ---
EncounterPool_064:
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01  ; Header
    dw 108, 109, 112, 113, 107  ; EIDs: RockSlime, Chamelgon, CactiBall, TailEater, Gismo
    db 3, 3, 3, 3, 2  ; Weights
    db 15  ; Extra

; --- Pool 65 ($7148): Gate of Labyrinth ---
EncounterPool_065:
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01  ; Header
    dw 108, 111, 112, 113, 107  ; EIDs: RockSlime, DuckKite, CactiBall, TailEater, Gismo
    db 3, 3, 3, 3, 2  ; Weights
    db 15  ; Extra

; --- Pool 66 ($7162): Gate of Labyrinth ---
EncounterPool_066:
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01  ; Header
    dw 108, 111, 112, 107, 114  ; EIDs: RockSlime, DuckKite, CactiBall, Gismo, AgDevil
    db 3, 3, 3, 2, 2  ; Weights
    db 15  ; Extra

; --- Pool 67 ($717C): Gate of Labyrinth ---
EncounterPool_067:
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01  ; Header
    dw 108, 111, 113, 107, 114  ; EIDs: RockSlime, DuckKite, TailEater, Gismo, AgDevil
    db 3, 3, 3, 2, 2  ; Weights
    db 15  ; Extra

; --- Pool 68 ($7196): Gate of Labyrinth ---
EncounterPool_068:
    db $04, $03, $01, $04, $05, $02, $02, $02, $02, $02  ; Header
    dw 108, 111, 107, 114, 115  ; EIDs: RockSlime, DuckKite, Gismo, AgDevil, WindMerge
    db 3, 3, 3, 3, 2  ; Weights
    db 15  ; Extra

; --- Pool 69 ($71B0): Gate of Judgement ---
EncounterPool_069:
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01  ; Header
    dw 116, 119, 120, 121, 117  ; EIDs: WeedBug, HammerMan, MadGoose, TreeBoy, SpotKing
    db 3, 3, 3, 3, 2  ; Weights
    db 15  ; Extra

; --- Pool 70 ($71CA): Gate of Judgement ---
EncounterPool_070:
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01  ; Header
    dw 119, 120, 121, 122, 117  ; EIDs: HammerMan, MadGoose, TreeBoy, Droll, SpotKing
    db 3, 3, 3, 3, 2  ; Weights
    db 15  ; Extra

; --- Pool 71 ($71E4): Gate of Judgement ---
EncounterPool_071:
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01  ; Header
    dw 119, 121, 122, 117, 118  ; EIDs: HammerMan, TreeBoy, Droll, SpotKing, LizardFly
    db 3, 3, 3, 2, 2  ; Weights
    db 15  ; Extra

; --- Pool 72 ($71FE): Gate of Judgement ---
EncounterPool_072:
    db $03, $03, $01, $04, $05, $03, $02, $02, $02, $01  ; Header
    dw 119, 121, 129, 117, 118  ; EIDs: HammerMan, TreeBoy, GiantMoth, SpotKing, LizardFly
    db 3, 3, 3, 2, 2  ; Weights
    db 15  ; Extra

; --- Pool 73 ($7218): Gate of Judgement ---
EncounterPool_073:
    db $04, $03, $01, $04, $05, $02, $02, $02, $02, $02  ; Header
    dw 119, 120, 129, 117, 118  ; EIDs: HammerMan, MadGoose, GiantMoth, SpotKing, LizardFly
    db 3, 3, 3, 3, 2  ; Weights
    db 15  ; Extra

; --- Pool 74 ($7232): Library Gate ---
EncounterPool_074:
    db $04, $03, $00, $03, $06, $03, $02, $02, $02, $01  ; Header
    dw 130, 132, 136, 137, 131  ; EIDs: ArcDemon, CurseLamp, AmberWeed, ArmyCrab, MadSpirit
    db 3, 3, 3, 3, 2  ; Weights
    db 3  ; Extra

; --- Pool 75 ($724C): Library Gate ---
EncounterPool_075:
    db $04, $03, $00, $03, $06, $03, $02, $02, $02, $01  ; Header
    dw 130, 132, 134, 137, 131  ; EIDs: ArcDemon, CurseLamp, WildApe, ArmyCrab, MadSpirit
    db 3, 3, 3, 3, 2  ; Weights
    db 3  ; Extra

; --- Pool 76 ($7266): Library Gate ---
EncounterPool_076:
    db $04, $03, $00, $03, $06, $03, $02, $02, $02, $01  ; Header
    dw 130, 132, 134, 137, 133  ; EIDs: ArcDemon, CurseLamp, WildApe, ArmyCrab, Tortragon
    db 3, 3, 3, 3, 2  ; Weights
    db 3  ; Extra

; --- Pool 77 ($7280): Library Gate ---
EncounterPool_077:
    db $04, $03, $00, $03, $06, $03, $02, $02, $02, $01  ; Header
    dw 130, 131, 134, 137, 133  ; EIDs: ArcDemon, MadSpirit, WildApe, ArmyCrab, Tortragon
    db 3, 3, 3, 3, 2  ; Weights
    db 3  ; Extra

; --- Pool 78 ($729A): Library Gate ---
EncounterPool_078:
    db $04, $03, $00, $03, $06, $02, $02, $02, $02, $02  ; Header
    dw 130, 131, 133, 134, 135  ; EIDs: ArcDemon, MadSpirit, Tortragon, WildApe, LandOwl
    db 3, 3, 3, 3, 2  ; Weights
    db 3  ; Extra

; --- Pool 79 ($72B4): Gate of Reflection ---
EncounterPool_079:
    db $03, $03, $00, $03, $06, $03, $02, $02, $02, $01  ; Header
    dw 138, 139, 140, 141, 142  ; EIDs: EvilBeast, Shadow, EvilWand, SlimeBorg, LizardMan
    db 3, 3, 3, 3, 2  ; Weights
    db 15  ; Extra

; --- Pool 80 ($72CE): Gate of Reflection ---
EncounterPool_080:
    db $03, $03, $00, $03, $06, $03, $02, $02, $02, $01  ; Header
    dw 138, 139, 141, 142, 143  ; EIDs: EvilBeast, Shadow, SlimeBorg, LizardMan, Grizzly
    db 3, 3, 3, 3, 2  ; Weights
    db 15  ; Extra

; --- Pool 81 ($72E8): Gate of Reflection ---
EncounterPool_081:
    db $03, $03, $00, $03, $06, $03, $02, $02, $02, $01  ; Header
    dw 142, 141, 144, 145, 143  ; EIDs: LizardMan, SlimeBorg, Wyvern, FireWeed, Grizzly
    db 3, 3, 3, 3, 2  ; Weights
    db 15  ; Extra

; --- Pool 82 ($7302): Gate of Reflection ---
EncounterPool_082:
    db $03, $03, $00, $03, $06, $03, $02, $02, $02, $01  ; Header
    dw 142, 144, 146, 157, 143  ; EIDs: LizardMan, Wyvern, MadHornet, Lionex, Grizzly
    db 3, 3, 3, 3, 2  ; Weights
    db 15  ; Extra

; --- Pool 83 ($731C): Gate of Reflection ---
EncounterPool_083:
    db $03, $03, $00, $03, $06, $03, $02, $02, $02, $01  ; Header
    dw 144, 146, 157, 158, 143  ; EIDs: Wyvern, MadHornet, Lionex, RotRaven, Grizzly
    db 3, 3, 3, 3, 2  ; Weights
    db 15  ; Extra

; --- Pool 84 ($7336): Gate of Reflection ---
EncounterPool_084:
    db $04, $03, $00, $03, $06, $02, $02, $02, $02, $02  ; Header
    dw 143, 146, 157, 158, 159  ; EIDs: Grizzly, MadHornet, Lionex, RotRaven, JewelBag
    db 3, 3, 3, 3, 3  ; Weights
    db 15  ; Extra

; --- Pool 85 ($7350): Gate of Ambition ---
EncounterPool_085:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 6, 10, 19, 36, 0  ; EIDs: GoHopper, ArmyAnt, Catapila, GiantWorm, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 86 ($736A): Gate of Ambition ---
EncounterPool_086:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 38, 44, 49, 70, 0  ; EIDs: GiantSlug, Eyeder, Butterfly, ArmorPede, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 87 ($7384): Gate of Ambition ---
EncounterPool_087:
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 86, 94, 113, 116, 0  ; EIDs: Gophecada, StagBug, TailEater, WeedBug, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 88 ($739E): Gate of Ambition ---
EncounterPool_088:
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 122, 129, 137, 146, 0  ; EIDs: Droll, GiantMoth, ArmyCrab, MadHornet, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 89 ($73B8): Gate of Demolition (Hargon) ---
EncounterPool_089:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 5, 18, 27, 35, 0  ; EIDs: Stubsuck, EvilSeed, BeanMan, FloraMan, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 90 ($73D2): Gate of Demolition (Hargon) ---
EncounterPool_090:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 43, 62, 69, 85, 0  ; EIDs: WingTree, Gulpple, MadPlant, Oniono, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 91 ($73EC): Gate of Demolition (Hargon) ---
EncounterPool_091:
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 112, 121, 136, 145, 0  ; EIDs: CactiBall, TreeBoy, AmberWeed, FireWeed, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 92 ($7406): Gate of Demolition (Hargon) ---
EncounterPool_092:
    ; Header
    db $04
EncounterDataTable_1:
    db $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 145, 163, 169, 189, 0  ; EIDs
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 93 ($7420): Gate of Demolition (Sidoh) ---
EncounterPool_093:
    ; Header
EncounterDataTable_2:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00
    dw 4, 14, 21, 34, 0  ; EIDs
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 94 ($743A): Gate of Demolition (Sidoh) ---
EncounterPool_094:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 50, 61, 68, 84, 0  ; EIDs: MadRaven, MadPecker, Florajay, StubBird, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 95 ($7454): Gate of Demolition (Sidoh) ---
EncounterPool_095:
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 93, 111, 120, 135, 0  ; EIDs: MistyWing, DuckKite, MadGoose, LandOwl, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 96 ($746E): Gate of Demolition (Sidoh) ---
EncounterPool_096:
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    ; EIDs (split by label)
    db $90, $00, $A2
EncounterWeightTable:
    db $00, $C5, $00, $C6, $00, $00, $00
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 97 ($7488): Gate of Mastermind ---
EncounterPool_097:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 2, 25, 30, 40, 0  ; EIDs: Slime, SpotSlime, Metaly, TreeSlime, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 98 ($74A2): Gate of Mastermind ---
EncounterPool_098:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 46, 59, 65, 73, 0  ; EIDs: DrakSlime, Snaily, Babble, WingSlime, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 99 ($74BC): Gate of Mastermind ---
EncounterPool_099:
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 81, 90, 98, 108, 0  ; EIDs: Slabbit, SlimeNite, BoxSlime, RockSlime, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 100 ($74D6): Gate of Mastermind ---
EncounterPool_100:
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 108, 117, 141, 181, 0  ; EIDs: RockSlime, SpotKing, SlimeBorg, Metabble, (none)
    db 3, 3, 3, 2, 0  ; Weights
    db 15  ; Extra

; --- Pool 101 ($74F0): Gate of Control ---
EncounterPool_101:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 7, 22, 28, 37, 0  ; EIDs: Gremlin, Demonite, 1EyeClown, SkulRider, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 102 ($750A): Gate of Control ---
EncounterPool_102:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 63, 71, 87, 95, 0  ; EIDs: EyeBall, MedusaEye, Pixy, DarkEye, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 103 ($7524): Gate of Control ---
EncounterPool_103:
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 105, 114, 130, 138, 0  ; EIDs: Orc, AgDevil, ArcDemon, EvilBeast, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 104 ($753E): Gate of Control ---
EncounterPool_104:
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 157, 164, 170, 190, 0  ; EIDs: Lionex, Grendal, Ogre, GoatHorn, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 105 ($7558): Gate of Extinction ---
EncounterPool_105:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 8, 16, 23, 45, 0  ; EIDs: Spooky, Hork, BoneSlave, Putrepup, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 106 ($7572): Gate of Extinction ---
EncounterPool_106:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 57, 64, 88, 96, 0  ; EIDs: Mudron, Mummy, DeadNite, NiteWhip, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 107 ($758C): Gate of Extinction ---
EncounterPool_107:
    db $03, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 106, 115, 131, 139, 0  ; EIDs: Reaper, WindMerge, MadSpirit, Shadow, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 108 ($75A6): Gate of Extinction ---
EncounterPool_108:
    db $04, $03, $00, $00, $07, $02, $02, $02, $02, $02  ; Header
    dw 158, 165, 171, 186, 191  ; EIDs: RotRaven, DarkCrab, Skullgon, Skeletor, DeadNoble
    db 3, 3, 3, 3, 3  ; Weights
    db 15  ; Extra

; --- Pool 109 ($75C0): Gate of Sleep ---
EncounterPool_109:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 9, 24, 29, 39, 0  ; EIDs: Goopi, SabreMan, CoilBird, MudDoll, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 110 ($75DA): Gate of Sleep ---
EncounterPool_110:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 58, 72, 89, 97, 0  ; EIDs: Facer, MadCandle, SpikyBoy, RogueNite, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 111 ($75F4): Gate of Sleep ---
EncounterPool_111:
    db $03, $03, $00, $00, $07, $02, $02, $02, $02, $02  ; Header
    dw 107, 132, 140, 159, 166  ; EIDs: Gismo, CurseLamp, EvilWand, JewelBag, MadMirror
    db 3, 3, 3, 3, 3  ; Weights
    db 15  ; Extra

; --- Pool 112 ($760E): Gate of Sleep ---
EncounterPool_112:
    db $04, $03, $00, $00, $07, $02, $02, $02, $02, $02  ; Header
    dw 172, 183, 187, 192, 193  ; EIDs: Voodoll, Balzak, MetalDrak, Roboster, BombCrag
    db 3, 3, 3, 3, 3  ; Weights
    db 15  ; Extra

; --- Pool 113 ($7628): Bazaar Edge Gate ---
EncounterPool_113:
    db $02, $03, $00, $00, $07, $02, $02, $02, $02, $02  ; Header
    dw 15, 20, 33, 42, 48  ; EIDs: PillowRat, FairyRat, Almiraj, CatFly, Skullroo
    db 3, 3, 3, 3, 3  ; Weights
    db 15  ; Extra

; --- Pool 114 ($7642): Bazaar Edge Gate ---
EncounterPool_114:
    db $02, $03, $00, $00, $07, $02, $02, $02, $02, $02  ; Header
    dw 60, 67, 74, 83, 92  ; EIDs: Saccer, Tonguella, MadGopher, WindBeast, Mommonja
    db 3, 3, 3, 3, 3  ; Weights
    db 15  ; Extra

; --- Pool 115 ($765C): Bazaar Edge Gate ---
EncounterPool_115:
    db $03, $03, $00, $00, $07, $02, $02, $02, $02, $02  ; Header
    dw 110, 119, 134, 143, 161  ; EIDs: Goategon, HammerMan, WildApe, Grizzly, SuperTen
    db 3, 3, 3, 3, 3  ; Weights
    db 15  ; Extra

; --- Pool 116 ($7676): Bazaar Edge Gate ---
EncounterPool_116:
    db $04, $03, $00, $00, $07, $02, $02, $02, $02, $02  ; Header
    dw 168, 174, 182, 185, 195  ; EIDs: Yeti, IronTurt, GulpBeast, Trumpeter, Unicorn
    db 3, 3, 3, 3, 3  ; Weights
    db 15  ; Extra

; --- Pool 117 ($7690): Arena - Right Gate ---
EncounterPool_117:
    db $02, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 13, 17, 26, 41, 0  ; EIDs: MiniDrak, DragonKid, Crestpent, Poisongon, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 118 ($76AA): Arena - Right Gate ---
EncounterPool_118:
    db $02, $03, $00, $00, $07, $02, $02, $02, $02, $02  ; Header
    dw 47, 66, 82, 91, 109  ; EIDs: FairyDrak, Pteranod, Gasgon, KingCobra, Chamelgon
    db 3, 3, 3, 3, 3  ; Weights
    db 15  ; Extra

; --- Pool 119 ($76C4): Arena - Right Gate ---
EncounterPool_119:
    db $03, $03, $00, $00, $07, $02, $02, $02, $02, $02  ; Header
    dw 118, 133, 142, 160, 167  ; EIDs: LizardFly, Tortragon, LizardMan, Swordgon, WingSnake
    db 3, 3, 3, 3, 3  ; Weights
    db 15  ; Extra

; --- Pool 120 ($76DE): Arena - Right Gate ---
EncounterPool_120:
    db $04, $03, $00, $00, $07, $02, $02, $02, $02, $02  ; Header
    dw 173, 184, 188, 194, 196  ; EIDs: Rayburn, Spikerous, MadDragon, Andreal, GreatDrak
    db 3, 3, 3, 3, 3  ; Weights
    db 15  ; Extra

; --- Pool 121 ($76F8): Unused Gate (99 Floors) ---
EncounterPool_121:
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 186, 185, 187, 188, 0  ; EIDs: Skeletor, Trumpeter, MetalDrak, MadDragon, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 122 ($7712): Unused Gate (99 Floors) ---
EncounterPool_122:
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 187, 188, 189, 190, 0  ; EIDs: MetalDrak, MadDragon, Snapper, GoatHorn, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 123 ($772C): Unused Gate (99 Floors) ---
EncounterPool_123:
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 189, 190, 191, 192, 0  ; EIDs: Snapper, GoatHorn, DeadNoble, Roboster, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 124 ($7746): Unused Gate (99 Floors) ---
EncounterPool_124:
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 191, 192, 193, 194, 0  ; EIDs: DeadNoble, Roboster, BombCrag, Andreal, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 125 ($7760): Unused Gate (99 Floors) ---
EncounterPool_125:
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 193, 194, 195, 196, 0  ; EIDs: BombCrag, Andreal, Unicorn, GreatDrak, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 126 ($777A): Unused Gate (99 Floors) ---
EncounterPool_126:
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 195, 196, 197, 198, 0  ; EIDs: Unicorn, GreatDrak, ZapBird, WhipBird, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

; --- Pool 127 ($7794): Unused Gate (99 Floors) ---
EncounterPool_127:
    db $04, $03, $00, $00, $07, $03, $03, $02, $02, $00  ; Header
    dw 197, 198, 30, 181, 0  ; EIDs: ZapBird, WhipBird, Metaly, Metabble, (none)
    db 3, 3, 3, 3, 0  ; Weights
    db 15  ; Extra

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
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    db $01
