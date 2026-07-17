; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $051", ROMX[$4000], BANK[$51]

    db $51 ; Bank number

    ; Cross-bank dispatch table (19 entries)
    ; Called via: ld hl, $51XX / rst $10
    dw $423E                          ; Entry 0
    dw $43F4                          ; Entry 1
    dw $4A96                          ; Entry 2
    dw $4BE8                          ; Entry 3
    dw $4CB3                          ; Entry 4
    dw $4D16                          ; Entry 5
    dw $4E5E                          ; Entry 6
    dw $4FAA                          ; Entry 7
    dw $50F6                          ; Entry 8
    dw $524A                          ; Entry 9
    dw LoadBtlS_46aa                  ; Entry 10
    dw LoadBtlS_44a9                  ; Entry 11
    dw $5578                          ; Entry 12
    dw LoadBtlS_5b31                  ; Entry 13
    dw $5C33                          ; Entry 14
    dw $537A                          ; Entry 15
    dw $6959                          ; Entry 16
    dw $5569                          ; Entry 17
    dw $7B0F                          ; Entry 18

LoadBattle:
    ld hl, $c817
    ld [hl], $00
    inc hl
    ld [hl], $00
    ld hl, $0801
    rst $10
    ld a, $fc
    call SetGBCPalette
    ld de, $5b00
    ld hl, $9600
    call WaitLCDTransfer
    ld de, $5b01
    ld hl, $8800
    call WaitLCDTransfer
    ld de, $2e00
    ld hl, $8d00
    call WaitLCDTransfer
    ld hl, $8b00
    ld de, $1202
    call SetupVRAMCopy
    call SetBtlS_4107
    call LoadBtlS_40d1
    ld a, [$c86c]
    or a
    jr z, jr_051_4073

    ld a, $ff
    ld [wBGM], a
    ld [wSoundEffect], a
    call InitAudioSystem

jr_051_4073:
    ld b, $27
    ld a, [wMapID]
    cp $5d
    jp nz, Jump_051_408b

    ld hl, $c8ea
    res 7, [hl]
    ld a, [wArenaStarryBattle]
    cp $02
    jr nz, jr_051_408b

    ld b, $2b

Jump_051_408b:
jr_051_408b:
    ld a, b
    call SetBGM
    ld a, $07
    ldh [$b5], a
    ld a, $ff
    ldh [$b6], a
    ld a, $00
    ldh [$bb], a
    ld a, $00
    ldh [$b7], a
    call ApplyScrollRegisters
    call ClearOAMBuffer
    xor a
    ld [$c8a4], a
    ld [$c8a5], a
    xor a
    ld [$c892], a
    xor a
    ld [$dd62], a
    xor a
    ld [$c873], a
    xor a
    ld [$c86e], a
    ld hl, $170a
    rst $10
    ld hl, $5110
    rst $10
    ld a, $03
    ld [$c8a1], a
    call EnableLYCInterrupt
    ld a, $0b
    jp EnableLCDAndInterrupts


LoadBtlS_40d1:
    ld a, [$ca8d]
    or a
    ret z

    ld a, [$ca8e]
    ld d, a
    ld hl, $0107
    rst $10
    ld a, d
    ld [$da15], a
    ld a, [$ca8d]
    cp $01
    ret z

    ld a, [$ca8f]
    ld d, a
    ld hl, $0107
    rst $10
    ld a, d
    ld [$da16], a
    ld a, [$ca8d]
    cp $02
    ret z

    ld a, [$ca90]
    ld d, a
    ld hl, $0107
    rst $10
    ld a, d
    ld [$da17], a
    ret


SetBtlS_4107:
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    call BtlSFunc_419f
    ld a, $04
    ld [wBattleTargetIdx], a
    ld de, $dc40
    ld a, [$c863]
    bit 1, a
    jr z, jr_051_412b

    xor a
    ld [wBattleTargetIdx], a
    ld de, $dc3c

jr_051_412b:
    ld hl, $9000
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_051_413c

    ld a, [de]
    call SaveBtlS_6a67
    jr jr_051_4140

jr_051_413c:
    ld hl, $5801
    rst $10

jr_051_4140:
    ld hl, wBattleTargetIdx
    inc [hl]
    inc de
    ld hl, $9240
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_051_4156

    ld a, [de]
    call SaveBtlS_6a67
    jr jr_051_415a

jr_051_4156:
    ld hl, $5801
    rst $10

jr_051_415a:
    ld hl, wBattleTargetIdx
    inc [hl]
    inc de
    ld hl, $9480
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_051_4170

    ld a, [de]
    call SaveBtlS_6a67
    jr jr_051_4174

jr_051_4170:
    ld hl, $5801
    rst $10

jr_051_4174:
    xor a
    ld hl, wEventStateMachineIndex
    ld bc, $0008
    call FillNBytesWithRegA
    ld hl, $9800
    ld a, l
    ld [$d9f8], a
    ld a, h
    ld [$d9f9], a
    call SetBtlS_742a
    call SetBtlS_7439
    call ClrBtlS_7524
    call LoadBtlS_7628
    call SetBtlS_768a
    call LoadBtlS_79cb
    call ProcessBattleTurn
    ret


BtlSFunc_419f:
    ld d, $00
    ld a, [$c86c]
    or a
    jr z, jr_051_41b0

    ld a, [$c863]
    bit 1, a
    jr z, jr_051_41b0

    ld d, $04

jr_051_41b0:
    ld a, d
    ld [wBattleTargetIdx], a
    call LoadBtlS_7929
    inc d
    ld a, d
    ld [wBattleTargetIdx], a
    call LoadBtlS_7929
    inc d
    ld a, d
    ld [wBattleTargetIdx], a
    call LoadBtlS_7929
    ld hl, $9700
    ld b, $60

jr_051_41cc:
    ld a, $ff
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    dec b
    jr nz, jr_051_41cc

    ld a, [$c86c]
    or a
    ld a, [$ca8d]
    ld [$dd72], a
    jr nz, jr_051_41e3

    or a
    ret z

jr_051_41e3:
    ld d, $00
    ld a, [$c86c]
    or a
    jr z, jr_051_41fc

    ld a, [$c863]
    bit 1, a
    jr z, jr_051_41fc

    ld a, [$db75]
    ld [$dd72], a
    ld d, $04
    jr jr_051_41fc

jr_051_41fc:
    push de
    ld hl, $cac2
    ld a, d
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ld hl, $9700
    call SaveBtlS_73dc
    pop de
    ld a, [$dd72]
    cp $01
    ret z

    inc d
    push de
    ld hl, $cac2
    ld a, d
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ld hl, $9740
    call SaveBtlS_73dc
    pop de
    ld a, [$dd72]
    cp $02
    ret z

    inc d
    push de
    ld hl, $cac2
    ld a, d
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ld hl, $9780
    call SaveBtlS_73dc
    pop de
    ret


    call CallBtlS_4245
    call LoadBattle
    ret


CallBtlS_4245:
    call LoadBtlS_43c9
    call LoadBtlS_4452
    ld a, [$db74]
    or a
    jr nz, jr_051_4257

    ld a, $6d
    ld [$dc40], a
    ret


jr_051_4257:
    xor a
    ld [$da88], a
    ld a, $ff
    ld [$da82], a
    xor a
    ld hl, $db00
    ld bc, $0073
    call FillNBytesWithRegA
    ld hl, $dd1b
    ld bc, $0008
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $db8b
    ld bc, $00d9
    xor a
    call FillNBytesWithRegA
    ld hl, $dc3c
    ld bc, $0008
    ld a, $ff
    call FillNBytesWithRegA
    ld a, $ff
    ld hl, $dd03
    ld bc, $0008
    call FillNBytesWithRegA
    ld a, [$db74]
    or a
    jr z, jr_051_42ae

    ld c, a
    ld b, $00
    xor a
    ld hl, $dd03
    push bc
    call FillNBytesWithRegA
    pop bc
    ld hl, $c876
    xor a
    call FillNBytesWithRegA

jr_051_42ae:
    ld hl, $d9fc
    ld bc, $0006
    xor a
    call FillNBytesWithRegA
    ld a, [$d929]
    ld [$d9fd], a
    xor a
    ld hl, $dd0b
    ld bc, $0010
    call FillNBytesWithRegA
    ld a, $ff
    ld hl, $dc64
    ld bc, $0080
    call FillNBytesWithRegA
    ld a, $ff
    ld hl, $c1ca
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ld a, [$db74]
    ld b, a
    ld c, $00

jr_051_42e1:
    call LoadBtlS_44b2
    inc c
    dec b
    jr nz, jr_051_42e1

    ld a, [$db75]
    ld b, a
    ld c, $04

jr_051_42ee:
    call LoadBtlS_44b2
    inc c
    dec b
    jr nz, jr_051_42ee

    xor a
    ld [$db76], a
    ld [$dd61], a
    xor a
    ld [$d9ed], a
    ld a, $ff
    ld hl, $dce4
    ld bc, $0018
    call FillNBytesWithRegA
    xor a
    ld hl, $dcfc
    ld bc, $0007
    call FillNBytesWithRegA
    ld hl, $ffff
    ld a, l
    ld [$db77], a
    ld a, h
    ld [$db78], a
    xor a
    ld hl, $db4c
    ld bc, $0027
    call FillNBytesWithRegA
    ld hl, $000a
    ld a, l
    ld [$db83], a
    ld a, h
    ld [$db84], a
    ld a, $ff
    ld [$db77], a
    ld [$db78], a
    ld a, [$db74]
    ld d, a
    ld e, $00
    ld a, [$c86c]
    or a
    jr nz, jr_051_4358

    ld hl, $dd1f
    ld b, $00
    ld a, [$db75]
    ld c, a
    or a
    ld a, $00
    call nz, FillNBytesWithRegA

jr_051_4358:
    call SetBtlS_499f
    call SetBtlS_4a28
    ld de, $db8b
    ld bc, $0800

jr_051_4364:
    push bc
    ld a, c
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr z, jr_051_4393

    ld a, c
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [wTempSpeciesId], a
    push de
    ld hl, $0301
    rst $10
    pop de
    ld a, [$da38]
    ld h, a
    ld a, [$da37]
    swap a
    or h
    ld [de], a

jr_051_4393:
    pop bc
    inc de
    inc c
    dec b
    jr nz, jr_051_4364

    ld hl, wMenu_selection
    ld bc, $0008
    xor a
    call FillNBytesWithRegA
    ld hl, $c1c0
    ld bc, $000f
    ld a, $ff
    call FillNBytesWithRegA
    ld a, $00
    ld [$c1c2], a
    ld hl, $c1cd
    ld bc, $0008
    ld a, $80
    call FillNBytesWithRegA
    call SaveBtlS_548c
    call LoadBtlS_5507
    ld hl, $d9ed
    inc [hl]
    ret


LoadBtlS_43c9:
    ld a, [$c86c]
    or a
    jr nz, jr_051_43dc

    ld a, [$da09]
    or a
    jr z, jr_051_43e0

    ld a, [wScriptMapType]
    cp $5d
    jr nz, jr_051_43e4

jr_051_43dc:
    ld a, $02
    jr jr_051_43e6

jr_051_43e0:
    ld a, $00
    jr jr_051_43e6

jr_051_43e4:
    ld a, $01

jr_051_43e6:
    ld [$db73], a
    ld a, [$c86c]
    or a
    ret z

    ld a, $06
    ld [wTextSpeed], a
    ret


    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    ld a, [$db4e]
    ld e, a
    ld a, [$db4f]
    ld d, a

SaveBtlS_4404:
    push hl
    ld a, $1a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $03
    rrc a
    rrc a
    ld c, a
    pop hl
    ld a, [hl+]
    sla a
    sla a
    or [hl]
    inc hl
    sla a
    sla a
    or [hl]
    inc hl
    or c
    ld [de], a
    inc de
    ld b, $05

jr_051_4428:
    ld a, [hl+]
    sla a
    sla a
    or [hl]
    inc hl
    sla a
    sla a
    or [hl]
    inc hl
    sla a
    sla a
    or [hl]
    inc hl
    ld [de], a
    inc de
    dec b
    jr nz, jr_051_4428

    ld a, [hl+]
    sla a
    sla a
    or [hl]
    inc hl
    sla a
    sla a
    or [hl]
    sla a
    sla a
    ld [de], a
    ret


LoadBtlS_4452:
    ld a, [$c86c]
    or a
    jr z, jr_051_4498

    ld bc, $0300

jr_051_445b:
    ld a, c
    ld hl, $cac1
    call ReadMonsterByte
    or a
    jr z, jr_051_4469

    inc c
    dec b
    jr nz, jr_051_445b

jr_051_4469:
    ld a, c
    ld [$db74], a
    ld [$c1d9], a
    ld bc, $0304

jr_051_4473:
    ld a, c
    ld hl, $cac1
    call ReadMonsterByte
    or a
    jr z, jr_051_4481

    inc c
    dec b
    jr nz, jr_051_4473

jr_051_4481:
    ld a, c
    sub $04
    ld [$db75], a
    dec a
    ld [$da02], a
    ld a, [$c863]
    bit 1, a
    ret z

    ld a, [$db75]
    ld [$c1d9], a
    ret


jr_051_4498:
    ld a, [$ca8d]
    ld [$db74], a
    ld [$c1d9], a
    ld a, [$da02]
    inc a
    ld [$db75], a
    ret


LoadBtlS_44a9:
    ld a, [$db4c]
    ld c, a
    ld a, $01
    ld [wBattlePostFlag], a

LoadBtlS_44b2:
    ld a, [$c86c]
    or a
    jr nz, jr_051_44cb

    ld a, c
    cp $04
    jr nc, jr_051_44c4

    call LoadBtlS_44cb
    call SaveBtlS_548c
    ret


jr_051_44c4:
    call LoadEnemyStatsForBattle
    call SaveBtlS_548c
    ret


LoadBtlS_44cb:
jr_051_44cb:
    ld a, c
    ld hl, $caca
    call GetCurrentMonsterPtr
    ld a, c
    ld de, $dc3c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    call LoadBtlS_4669
    ld a, [hl+]
    ld [de], a
    inc hl
    ld a, c
    ld de, $db93
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [hl]
    and $0f
    ld [de], a
    ld a, [hl+]
    swap a
    and $0f
    push af
    ld a, c
    ld de, $dd03
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    pop af
    push af
    and $03
    ld [de], a
    pop af
    push af
    push af
    ld a, c
    ld de, $c876
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    pop af
    rrca
    rrca
    and $03
    ld [de], a
    ld a, c
    bit 2, a
    jr nz, jr_051_4536

    ld a, [$c863]
    bit 1, a
    jr nz, jr_051_4551

    ld a, c
    inc a
    inc a
    ld de, $d9fc
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    pop af
    and $03
    ld [de], a
    jr jr_051_4552

jr_051_4536:
    ld a, [$c863]
    bit 1, a
    jr z, jr_051_4551

    ld a, c
    and $03
    inc a
    inc a
    ld de, $d9fc
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    pop af
    and $03
    ld [de], a
    jr jr_051_4552

jr_051_4551:
    pop af

jr_051_4552:
    ld a, $1d
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    push bc
    ld a, [$db4c]
    or a
    jr nz, jr_051_4567

    call LoadBtlS_46ff
    jr jr_051_456a

jr_051_4567:
    call LoadBtlS_46aa

jr_051_456a:
    pop bc
    pop hl
    ld a, $21
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattlePostFlag]
    or a
    call z, SaveBtlS_4769
    inc hl
    ld de, $db9b
    call LoadBtlS_4692
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [wBattlePostFlag]
    or a
    jr z, jr_051_459e

    inc hl
    inc hl
    ld de, wBattleMaxHP
    call LoadBtlS_469c
    inc hl
    inc hl
    ld de, wBattleMaxMP
    call LoadBtlS_469c
    jr jr_051_45b6

jr_051_459e:
    ld de, wBattleHP
    call LoadBtlS_469c
    ld de, wBattleMaxHP
    call LoadBtlS_469c
    ld de, wBattleMP
    call LoadBtlS_469c
    ld de, wBattleMaxMP
    call LoadBtlS_469c

jr_051_45b6:
    ld de, wBattleATK
    call LoadBtlS_469c
    ld de, wBattleDEF
    call LoadBtlS_469c
    ld de, wBattleAGL
    call LoadBtlS_469c
    ld de, wBattleINT
    call LoadBtlS_469c
    ld de, wBattleLVL
    call LoadBtlS_469c
    inc hl
    inc hl
    ld a, [wBattlePostFlag]
    or a
    jr z, jr_051_45f8

    ld a, [$db4c]
    push hl
    ld hl, $db03
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $30
    pop hl
    jr nz, jr_051_45f8

    inc hl
    inc hl
    inc hl
    inc hl
    jr jr_051_4610

jr_051_45f8:
    ld de, $dc44
    call LoadBtlS_4692
    ld de, $dc54
    call LoadBtlS_4692
    ld de, $dc5c
    call LoadBtlS_4692
    ld de, $dc4c
    call LoadBtlS_4692

jr_051_4610:
    ld a, c
    add a
    add c
    add a
    add c
    ld de, $dd28
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    push bc
    call SaveBtlS_4404
    pop bc
    call SaveBtlS_47a5
    ret


LoadEnemyStatsForBattle:
    push bc
    ld a, c
    sub $04
    ld c, a
    push bc
    ld hl, wTempEnemyId1
    ld a, c
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    ld hl, $1401
    rst $10
    pop bc
    call SaveBtlS_47e0
    ld a, c
    add $04
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call SaveBtlS_4688
    ld a, [hl]
    ld [wTempSpeciesId], a
    push bc
    ld hl, $0301
    rst $10
    pop bc
    call SaveBtlS_494c
    pop bc
    ret


LoadBtlS_4669:
    ld a, [wIsGBC]
    or a
    ret z

    push de
    push hl
    ld h, [hl]
    ld a, $02
    ldh [rSVBK], a
    ld a, c
    ld de, $db00
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, h
    ld [de], a
    ld a, $00
    ldh [rSVBK], a
    pop hl
    pop de
    ret


SaveBtlS_4688:
    push bc
    ld a, c
    add $04
    ld c, a
    call LoadBtlS_4669
    pop bc
    ret


LoadBtlS_4692:
    ld a, c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [hl+]
    ld [de], a
    ret


LoadBtlS_469c:
    ld a, c
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    ret


LoadBtlS_46aa:
    ld a, [$db4c]
    ld c, a
    ld hl, $dc64
    swap a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld b, $08

jr_051_46bb:
    ld a, $00
    ld [hl+], a
    ld a, $ff
    ld [hl+], a
    dec b
    jr nz, jr_051_46bb

    ld a, [$c86c]
    or a
    jr nz, jr_051_46cf

    ld a, c
    cp $04
    jr nc, jr_051_46dc

jr_051_46cf:
    ld a, c
    ld hl, $caea
    call GetCurrentMonsterPtr
    ld a, [$db4c]
    ld c, a
    jr jr_051_46ff

jr_051_46dc:
    ld a, c
    and $03
    ld hl, wTempEnemyId1
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    ld hl, $1401
    rst $10
    ld a, [$db4c]
    ld c, a
    ld hl, $da2d

LoadBtlS_46ff:
jr_051_46ff:
    ld a, [$c86c]
    or a
    jr nz, jr_051_470e

    ld a, c
    cp $04
    jr c, jr_051_470e

    ld b, $04
    jr jr_051_4710

jr_051_470e:
    ld b, $08

jr_051_4710:
    ld de, $dc65
    ld a, c
    swap a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a

jr_051_471c:
    ld a, [hl+]
    ld [de], a
    inc de
    inc de
    ld a, [hl]
    cp $ff
    jr z, jr_051_4728

    dec b
    jr nz, jr_051_471c

jr_051_4728:
    ld a, c
    ld de, $dc65
    swap a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld b, $08
    ld a, [$db4c]
    push af

jr_051_473a:
    ld a, [de]
    cp $ff
    jr z, jr_051_4761

    push bc
    ld a, [de]
    ld [$db4c], a
    xor a
    ld [$db4d], a
    ld a, $01
    ld [$db4e], a
    ld hl, $5400
    rst $10
    ld a, [$db4c]
    swap a
    and $0f
    dec de
    ld [de], a
    inc de
    inc de
    inc de
    pop bc
    dec b
    jr nz, jr_051_473a

jr_051_4761:
    pop af
    ld [$db4c], a
    call SetBtlS_499f
    ret


SaveBtlS_4769:
    push hl
    ld a, c
    ld de, $dd1b
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    bit 7, [hl]
    jr z, jr_051_477d

    ld a, $01
    ld [de], a
    jr jr_051_47a3

jr_051_477d:
    ld a, $00
    ld [de], a
    ld a, [$db73]
    cp $02
    jr z, jr_051_47a3

    ld a, c
    ld de, $db02
    add a
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    bit 0, [hl]
    jr z, jr_051_479b

    ld a, $20
    ld [de], a

jr_051_479b:
    bit 2, [hl]
    jr z, jr_051_47a3

    ld a, [de]
    or $01
    ld [de], a

jr_051_47a3:
    pop hl
    ret


SaveBtlS_47a5:
    push bc
    ld a, c
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    ld a, c
    ld hl, wBattleINT
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld bc, $0014
    call CmpHLvsBC
    jr c, jr_051_47d3

    ld bc, $00b3
    call CmpHLvsBC
    jr c, jr_051_47d7

    ld a, $02
    jr jr_051_47d9

jr_051_47d3:
    ld a, $00
    jr jr_051_47d9

jr_051_47d7:
    ld a, $01

jr_051_47d9:
    pop hl
    ld [hl], a
    pop bc
    ret


    push bc
    jr jr_051_47f2

SaveBtlS_47e0:
    push bc
    ld hl, wJoinability
    ld a, c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da1b]
    ld [hl], a
    ld a, c
    add $04

jr_051_47f2:
    ld c, a
    add a
    ld b, a
    ld hl, $db9b
    ld a, c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da1c]
    ld [hl], a
    ld hl, wBattleHP
    ld a, b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da1d]
    ld [hl+], a
    ld a, [$da1e]
    ld [hl-], a
    ld a, b
    call LoadBtlS_4a61
    ld hl, wBattleMaxHP
    ld a, b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da1d]
    ld [hl+], a
    ld a, [$da1e]
    ld [hl], a
    ld hl, wBattleMP
    ld a, b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da1f]
    ld [hl+], a
    ld a, [$da20]
    ld [hl], a
    ld hl, wBattleMaxMP
    ld a, b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da1f]
    ld [hl+], a
    ld a, [$da20]
    ld [hl], a
    ld hl, wBattleATK
    ld a, b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da21]
    ld [hl+], a
    ld a, [$da22]
    ld [hl], a
    ld hl, wBattleDEF
    ld a, b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da23]
    ld [hl+], a
    ld a, [$da24]
    ld [hl], a
    ld hl, wBattleAGL
    ld a, b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da25]
    ld [hl+], a
    ld a, [$da26]
    ld [hl], a
    ld hl, wBattleINT
    ld a, b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da27]
    ld [hl+], a
    ld a, [$da28]
    ld [hl-], a
    ld a, [hl]
    push af
    ld hl, $dd0b
    ld a, c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop af
    cp $15
    jr c, jr_051_48b0

    cp $b5
    jr c, jr_051_48b4

    ld a, $02
    jr jr_051_48b6

jr_051_48b0:
    ld a, $00
    jr jr_051_48b6

jr_051_48b4:
    ld a, $01

jr_051_48b6:
    ld [hl], a
    ld hl, wBattleLVL
    ld a, b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $ff
    inc hl
    ld [hl], $00
    ld hl, $dc33
    push bc
    ld a, c
    sub $04
    ld c, a
    add a
    add c
    pop bc
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da19]
    ld [hl+], a
    ld a, [$da1a]
    ld [hl+], a
    ld [hl], $00
    ld hl, $dc3c
    ld a, c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da18]
    ld [hl], a
    ld hl, $dc44
    ld a, c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da29]
    ld [hl], a
    ld hl, $dc4c
    ld a, c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da2b]
    ld [hl], a
    ld hl, $dc54
    ld a, c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da2a]
    ld [hl], a
    ld hl, $dc5c
    ld a, c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da2c]
    ld [hl], a
    ld hl, $dc65
    ld a, b
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da2d]
    ld [hl+], a
    inc hl
    ld a, [$da2e]
    ld [hl+], a
    inc hl
    ld a, [$da2f]
    ld [hl+], a
    inc hl
    ld a, [$da30]
    ld [hl], a
    pop bc
    ret


    push bc
    jr jr_051_4950

SaveBtlS_494c:
    push bc
    ld a, c
    add $04

jr_051_4950:
    ld c, a
    ld hl, $db93
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da36]
    or a
    jr z, jr_051_4988

    cp $01
    jr z, jr_051_496c

    cp $02
    jr z, jr_051_4970

    ld b, $e6
    jr jr_051_4972

jr_051_496c:
    ld b, $19
    jr jr_051_4972

jr_051_4970:
    ld b, $80

jr_051_4972:
    push af
    push bc
    push de
    push hl
    call GenerateRNG
    pop hl
    pop de
    pop bc
    pop af
    ld a, [wRNG1]
    cp b
    jr c, jr_051_4986

    xor a
    jr jr_051_4988

jr_051_4986:
    ld a, $01

jr_051_4988:
    ld [hl], a
    ld hl, $da42
    ld de, $dd28
    ld a, c
    add a
    add c
    add a
    add c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    call SaveBtlS_4404
    pop bc
    ret


SetBtlS_499f:
    ld bc, $0800
    ld hl, $db93

jr_051_49a5:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_051_49b4

    ld a, [hl]
    or a
    jr nz, jr_051_49b4

    push hl
    call LoadBtlS_4a00
    pop hl

jr_051_49b4:
    inc c
    inc hl
    dec b
    jr nz, jr_051_49a5

    ld a, [$c86c]
    or a
    ret nz

    ld bc, $0304
    ld hl, $dca5

jr_051_49c4:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_051_49ef

    ld d, $04

jr_051_49cc:
    ld a, [hl]
    cp $ff
    jr z, jr_051_49ef

    cp $97
    jr nz, jr_051_49da

    call WriteBtlS_4a1f
    jr jr_051_49ea

jr_051_49da:
    cp $19
    jr nz, jr_051_49e3

    call WriteBtlS_4a22
    jr jr_051_49ea

jr_051_49e3:
    cp $2a
    jr nz, jr_051_49ea

    call WriteBtlS_4a25

jr_051_49ea:
    inc hl
    inc hl
    dec d
    jr nz, jr_051_49cc

jr_051_49ef:
    inc c
    ld a, c
    swap a
    ld hl, $dc65
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    dec b
    jr nz, jr_051_49c4

    ret


LoadBtlS_4a00:
    ld a, c
    ld hl, $dc65
    swap a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld d, $08

jr_051_4a0e:
    ld a, [hl]
    cp $ff
    ret z

    cp $70
    jr nz, jr_051_4a19

    ld [hl], $dd
    ret


jr_051_4a19:
    inc hl
    inc hl
    dec d
    jr nz, jr_051_4a0e

    ret


WriteBtlS_4a1f:
    ld [hl], $db
    ret


WriteBtlS_4a22:
    ld [hl], $da
    ret


WriteBtlS_4a25:
    ld [hl], $dc
    ret


SetBtlS_4a28:
    ld hl, $dc65
    ld bc, $0808

jr_051_4a2e:
    push bc
    ld a, [hl]
    cp $ff
    push hl
    jr z, jr_051_4a50

    ld a, [hl]
    ld [$db4c], a
    ld a, $00
    ld [$db4d], a
    ld a, $01
    ld [$db4e], a
    ld hl, $5400
    rst $10
    ld a, [$db4c]
    swap a
    and $0f
    jr jr_051_4a52

jr_051_4a50:
    ld a, $00

jr_051_4a52:
    pop hl
    dec hl
    ld [hl+], a
    inc hl
    inc hl
    pop bc
    dec c
    jr nz, jr_051_4a2e

    ld c, $08
    dec b
    jr nz, jr_051_4a2e

    ret


LoadBtlS_4a61:
    ld a, [$db73]
    or a
    ret nz

    push bc
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld b, h
    ld c, l
    call SaveBtlS_5363
    ld a, c
    sub l
    ld c, a
    ld a, b
    sbc h
    ld b, a
    push hl
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a

jr_051_4a7f:
    call CmpHLvsBC
    jr c, jr_051_4a8c

    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    jr jr_051_4a7f

jr_051_4a8c:
    pop bc
    add hl, bc
    pop bc
    ld a, l
    ld [bc], a
    inc bc
    ld a, h
    ld [bc], a
    pop bc
    ret


    ld a, [$d9fd]
    ld [$d929], a
    ld a, [$db74]
    ld b, a
    ld c, $00

jr_051_4aa2:
    call LoadBtlS_4ac0
    ld a, c
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    call LoadBtlS_4af0
    call SaveBtlS_4b36
    call SaveBtlS_4b50
    call LoadBtlS_4b83
    call LoadBtlS_4b96
    inc c
    dec b
    jr nz, jr_051_4aa2

    ret


LoadBtlS_4ac0:
    ld a, c
    ld hl, $cacc
    call GetCurrentMonsterPtr
    ld a, c
    ld de, $dd03
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    push hl
    and $03
    ld l, a
    ld a, c
    ld de, $c876
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    rlca
    rlca
    and $0c
    or l
    pop hl
    swap a
    ld d, a
    ld a, [hl]
    and $0f
    or d
    ld [hl], a
    ret


LoadBtlS_4af0:
    ld a, $00
    ld [hl], a
    ld a, c
    ld de, $db02
    add a
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    and $03
    jr z, jr_051_4b07

    set 2, [hl]

jr_051_4b07:
    ld a, [de]
    bit 5, a
    jr z, jr_051_4b0e

    set 0, [hl]

jr_051_4b0e:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_051_4b18

    set 7, [hl]
    jr jr_051_4b2f

jr_051_4b18:
    ld a, [wBattlePostFlag]
    or a
    jr nz, jr_051_4b2f

    ld a, c
    ld de, $dc5c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    cp $ff
    jr z, jr_051_4b2f

    inc a
    ld [de], a

jr_051_4b2f:
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    ret


SaveBtlS_4b36:
    push bc
    ld a, c
    ld de, wBattleHP
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [hl+], a
    ld c, a
    inc de
    ld a, [de]
    ld [hl+], a
    ld b, a
    call SaveBtlS_4b70
    inc hl
    inc hl
    pop bc
    ret


SaveBtlS_4b50:
    push bc
    ld a, c
    ld de, wBattleMP
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [hl+], a
    ld c, a
    inc de
    ld a, [de]
    ld [hl+], a
    ld b, a
    call SaveBtlS_4b70
    ld a, $0a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop bc
    ret


SaveBtlS_4b70:
    push hl
    ld d, h
    ld e, l
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    jr nc, jr_051_4b81

    dec de
    ld a, h
    ld [de], a
    dec de
    ld a, l
    ld [de], a

jr_051_4b81:
    pop hl
    ret


LoadBtlS_4b83:
    ld a, c
    ld de, wBattleLVL
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    inc hl
    inc hl
    ret


LoadBtlS_4b96:
    ld a, c
    ld de, $dd1b
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    or a
    jr nz, jr_051_4be7

    push hl
    ld a, c
    ld hl, $db03
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 4, [hl]
    pop hl
    jr nz, jr_051_4be7

    ld a, c
    ld de, $dc44
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [hl+], a
    ld a, c
    ld de, $dc54
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [hl+], a
    ld a, c
    ld de, $dc5c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [hl+], a
    ld a, c
    ld de, $dc4c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [hl], a

jr_051_4be7:
    ret


    ld a, $01
    ld [$d9f0], a
    ld a, [$db4c]
    ld [$dd72], a
    and $03
    cp $03
    jr z, jr_051_4c00

    call LoadBtlS_44a9
    call LoadBtlS_4c26
    ret


jr_051_4c00:
    ld a, [$db4c]
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $ff
    ld a, [$db4c]
    and $04
    rrca
    rrca
    and $01
    ld hl, $db00
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    res 2, [hl]
    call LoadBtlS_4c26
    ret


LoadBtlS_4c26:
    ld a, [$dd72]
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    xor a
    ld [hl+], a
    ld [hl], a
    ld a, $1f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, $0f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    pop bc
    jr nc, jr_051_4c58

    ld a, l
    ld [bc], a
    inc bc
    ld a, h
    ld [bc], a

jr_051_4c58:
    ld a, [$dd72]
    ld hl, $db02
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    xor a
    ld [hl+], a
    call BitBtlS_4ca0
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ld a, [$dd72]
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    or a
    ret nz

    ld [hl], $01
    ld a, [$c86c]
    or a
    ret nz

    ld a, [$db4c]
    cp $04
    ret c

    and $03
    cp $03
    ret z

    ld hl, $c1ca
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $ff
    ret


BitBtlS_4ca0:
    bit 4, [hl]
    jr nz, jr_051_4ca7

    bit 5, [hl]
    ret z

jr_051_4ca7:
    push hl
    ld hl, $5110
    rst $10
    ld hl, $1708
    rst $10
    pop hl
    xor a
    ret


    ld a, [$da02]
    ld b, a
    inc b
    ld c, $04
    ld d, $00
    ld a, [$db60]
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld e, [hl]

jr_051_4cc9:
    ld a, c
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp e
    jr nz, jr_051_4cdf

    ld a, [$db60]
    cp c
    jp z, Jump_051_4ce4

    inc d

jr_051_4cdf:
    inc c
    dec b
    jr nz, jr_051_4cc9

    ret


Jump_051_4ce4:
    ld a, d
    or a
    jr nz, jr_051_4cfc

    inc c

jr_051_4ce9:
    ld a, c
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp e
    jr z, jr_051_4cfc

    inc c
    dec b
    jr nz, jr_051_4ce9

    ret


jr_051_4cfc:
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld a, d
    add $0b
    push af

jr_051_4d08:
    ld a, [hl]
    cp $f0
    jr z, jr_051_4d10

    inc hl
    jr jr_051_4d08

jr_051_4d10:
    pop af
    ld [hl+], a
    ld a, $f0
    ld [hl], a
    ret


    ld b, $00
    ld a, [wBattleAttackerIdx]
    and $04
    or $03
    ld [$db4c], a
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], b
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], b
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $1e
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c8
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleMaxHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c8
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleMP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $64
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleMaxMP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $64
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleATK
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $b4
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleDEF
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $96
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleAGL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $50
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleINT
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $96
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    ld a, [$db4c]
    ld hl, wBattleLVL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, $dc44
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, [$db4c]
    ld hl, $dc64
    swap a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $03
    ld [hl+], a
    ld a, $2c
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, $5a
    ld [hl+], a
    ld a, $03
    ld [hl+], a
    ld a, $88
    ld [hl+], a
    ld a, [$db4c]
    ld hl, $dd28
    ld c, a
    add a
    add c
    add a
    add c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $16
    ld [hl+], a
    ld a, $b5
    ld [hl+], a
    ld a, $55
    ld [hl+], a
    ld a, $54
    ld [hl+], a
    ld a, $15
    ld [hl+], a
    ld a, $55
    ld [hl+], a
    ld a, $54
    ld [hl+], a
    ret


    ld b, $00
    ld a, [wBattleAttackerIdx]
    and $04
    or $03
    ld [$db4c], a
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], b
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], b
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $28
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $2c
    ld [hl+], a
    ld a, $01
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleMaxHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $2c
    ld [hl+], a
    ld a, $01
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleMP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c8
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleMaxMP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c8
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleATK
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $d2
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleDEF
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $a0
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleAGL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $78
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleINT
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $64
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    ld a, [$db4c]
    ld hl, wBattleLVL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, $dc44
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, [$db4c]
    ld hl, $dc64
    swap a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $02
    ld [hl+], a
    ld a, $25
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, $5e
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ld a, $7a
    ld [hl+], a
    ld a, [$db4c]
    ld hl, $dd28
    ld c, a
    add a
    add c
    add a
    add c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $3a
    ld [hl+], a
    ld a, $05
    ld [hl+], a
    ld a, $64
    ld [hl+], a
    ld a, $54
    ld [hl+], a
    ld a, $31
    ld [hl+], a
    ld a, $55
    ld [hl+], a
    ld a, $84
    ld [hl+], a
    ret


    ld b, $00
    ld a, [wBattleAttackerIdx]
    and $04
    or $03
    ld [$db4c], a
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], b
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], b
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $32
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c2
    ld [hl+], a
    ld a, $01
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleMaxHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c2
    ld [hl+], a
    ld a, $01
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleMP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c8
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleMaxMP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c8
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleATK
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleDEF
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $be
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleAGL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $96
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleINT
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c8
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $02
    ld a, [$db4c]
    ld hl, wBattleLVL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, $dc44
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, [$db4c]
    ld hl, $dc64
    swap a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $01
    ld [hl+], a
    ld a, $40
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, $55
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, $57
    ld [hl+], a
    ld a, [$db4c]
    ld hl, $dd28
    ld c, a
    add a
    add c
    add a
    add c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $19
    ld [hl+], a
    ld a, $c6
    ld [hl+], a
    ld a, $b5
    ld [hl+], a
    ld a, $44
    ld [hl+], a
    ld a, $19
    ld [hl+], a
    ld a, $55
    ld [hl+], a
    ld a, $54
    ld [hl+], a
    ret


    ld b, $00
    ld a, [wBattleAttackerIdx]
    and $04
    or $03
    ld [$db4c], a
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], b
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], b
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $3c
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $bc
    ld [hl+], a
    ld a, $02
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleMaxHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $bc
    ld [hl+], a
    ld a, $01
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleMP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $90
    ld [hl+], a
    ld a, $01
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleMaxMP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $90
    ld [hl+], a
    ld a, $01
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleATK
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $5e
    ld [hl+], a
    ld a, $01
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleDEF
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $2c
    ld [hl+], a
    ld a, $01
    ld [hl], a
    ld a, [$db4c]
    ld hl, wBattleAGL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $64
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, wBattleINT
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $02
    ld a, [$db4c]
    ld hl, wBattleLVL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    ld [hl+], a
    ld [hl], b
    ld a, [$db4c]
    ld hl, $dc44
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fa
    ld [hl], a
    ld a, [$db4c]
    ld hl, $dc64
    swap a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $01
    ld [hl+], a
    ld a, $62
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, $64
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ld a, $80
    ld [hl+], a
    ld a, [$db4c]
    ld hl, $dd28
    ld c, a
    add a
    add c
    add a
    add c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $1a
    ld [hl+], a
    ld a, $6f
    ld [hl+], a
    ld a, $fa
    ld [hl+], a
    ld a, $a9
    ld [hl+], a
    ld a, $1e
    ld [hl+], a
    ld a, $aa
    ld [hl+], a
    ld a, $a8
    ld [hl+], a
    ret


    ld a, [wBattleAttackerIdx]
    ld hl, $db9b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $32
    ld [hl], a
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleMaxHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $e7
    ld [hl+], a
    ld a, $03
    ld [hl], a
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleMaxMP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $2c
    ld [hl+], a
    ld a, $01
    ld [hl], a
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleATK
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $2c
    ld [hl+], a
    ld a, $01
    ld [hl], a
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleDEF
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c8
    ld [hl+], a
    ld a, $00
    ld [hl], a
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleAGL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c8
    ld [hl+], a
    ld a, $00
    ld [hl], a
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleINT
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $c8
    ld [hl+], a
    ld a, $00
    ld [hl], a
    call LoadBtlS_5339
    ld a, [wBattleAttackerIdx]
    ld hl, $dc64
    swap a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $01
    ld [hl+], a
    ld a, $5e
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, $62
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ld a, $80
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $ff
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $ff
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $ff
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $ff
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $ff
    ld [hl], a
    ld a, [wBattleAttackerIdx]
    ld h, a
    add a
    add h
    add a
    add h
    ld hl, $dd28
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $2a
    ld [hl+], a
    ld a, $aa
    ld [hl+], a
    ld a, $a9
    ld [hl+], a
    ld a, $69
    ld [hl+], a
    ld a, $4f
    ld [hl+], a
    ld a, $aa
    ld [hl+], a
    ld a, $5a
    ld [hl], a
    ld a, [wBattleAttackerIdx]
    call SetBtlS_5355
    ret


LoadBtlS_5339:
    ld a, [wIsGBC]
    or a
    ret z

    ld a, $02
    ldh [rSVBK], a
    ld a, [wBattleAttackerIdx]
    ld hl, $db00
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $dc
    ld a, $00
    ldh [rSVBK], a
    ret


SetBtlS_5355:
    ld hl, $c1cd
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $80
    ld [hl], a
    ret


SaveBtlS_5363:
    push bc
    srl h
    rr l
    ld b, h
    ld c, l
    srl b
    rr c
    add hl, bc
    srl b
    rr c
    srl b
    rr c
    add hl, bc
    pop bc
    ret


    ld a, [$d9f1]
    rst $00
    add h
    ld d, e
    nop
    ld d, h
    rrca
    ld d, h
    ld hl, $d9f1
    inc [hl]
    ld a, [wBattleTargetIdx]
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $ff
    ld a, [wBattleTargetIdx]
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    ld a, [wBattleTargetIdx]
    ld [$db4c], a
    ld a, [$db4c]
    ld [$dd72], a
    and $03
    cp $03
    jr z, jr_051_53d6

    call LoadBtlS_44a9
    ld a, [$c863]
    bit 1, a
    ld a, [wBattleTargetIdx]
    jr nz, jr_051_53cd

    cp $04
    jr c, jr_051_53d1

    cp $07
    jr z, jr_051_53d1

    jr jr_051_5400

jr_051_53cd:
    cp $03
    jr c, jr_051_5400

jr_051_53d1:
    ld hl, $d9f1
    inc [hl]
    ret


jr_051_53d6:
    ld hl, $d9f1
    inc [hl]
    ld a, [$db4c]
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $ff
    ld a, [$db4c]
    and $04
    rrca
    rrca
    and $01
    ld hl, $db00
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    res 2, [hl]
    call LoadBtlS_4c26
    ret


jr_051_5400:
    ld hl, $5801
    rst $10
    ld a, $1a
    ld [$d9ed], a
    ld a, $02
    ld [$d9f1], a
    ret


    ld a, [wBattleTargetIdx]
    ld [$db4c], a
    ld [$dd72], a
    call LoadBtlS_4c26
    ld a, [$c86c]
    or a
    jr nz, jr_051_543f

    ld a, [wBattleTargetIdx]
    cp $04
    jr c, jr_051_543f

    cp $07
    jr z, jr_051_543f

    ld a, [wBattleTargetIdx]
    cp $03
    jr c, jr_051_543f

    jr z, jr_051_543f

    cp $07
    jr z, jr_051_543f

    ld a, [wBattleTargetIdx]
    ld [$dd61], a

jr_051_543f:
    ld hl, $5006
    rst $10
    ld hl, $c180
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleTargetIdx]
    ld [$db50], a
    ld a, [wBattleTargetIdx]
    call CmpBtlS_7a0a
    call LoadBtlS_547f
    and $04
    srl a
    srl a
    add $e3
    ld [$c823], a
    xor a
    ld [$c822], a
    ld hl, $4c00
    rst $10
    ld a, $03
    ld [$d9ed], a
    xor a
    ld [$d9f1], a
    ld a, $02
    ld [$da33], a
    ret


LoadBtlS_547f:
    ld a, [$c863]
    bit 1, a
    ld a, [wBattleTargetIdx]
    ret z

    ld a, [wBattleAttackerIdx]
    ret


SaveBtlS_548c:
    push bc
    push hl
    ld hl, $da33
    ld bc, $002b
    xor a
    call FillNBytesWithRegA
    pop hl
    pop bc
    ret


LoadBtlS_549b:
    ld a, [$c86c]
    or a
    ret nz

    ld a, [$da18]
    ld b, a
    ld a, [$da14]
    ld c, a
    push bc
    ld hl, $c500
    ld bc, $00c0
    ld a, $e0
    call FillNBytesWithRegA
    ld hl, $db02
    ld bc, $0040
    xor a
    call FillNBytesWithRegA
    ld a, [$ca8d]
    ld [$db74], a
    ld [$c1d9], a
    ld b, a
    ld c, $00

jr_051_54ca:
    call LoadBtlS_44cb
    inc c
    dec b
    jr nz, jr_051_54ca

    ld a, [$ca8e]
    ld hl, $9700
    call CmpBtlS_54f6
    ld a, [$ca8f]
    ld hl, $9740
    call CmpBtlS_54f6
    ld a, [$ca90]
    ld hl, $9780
    call CmpBtlS_54f6
    pop bc
    ld a, c
    ld [$da14], a
    ld a, b
    ld [$da18], a
    ret


CmpBtlS_54f6:
    cp $ff
    ret z

    push hl
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    pop hl
    call SaveBtlS_73dc
    ret


LoadBtlS_5507:
    ld a, $ff
    ld hl, $da0a
    ld bc, $0008
    call FillNBytesWithRegA
    ret


    ld bc, $0800

jr_051_5516:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_051_5520

    ld d, $07
    jr jr_051_5559

jr_051_5520:
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 6, [hl]
    jr nz, jr_051_5543

    bit 5, [hl]
    jr nz, jr_051_5547

    bit 4, [hl]
    jr nz, jr_051_554b

    bit 7, [hl]
    jr nz, jr_051_554f

    bit 1, [hl]
    jr nz, jr_051_5553

    bit 0, [hl]
    jr nz, jr_051_5557

    ld d, $00
    jr jr_051_5559

jr_051_5543:
    ld d, $06
    jr jr_051_5559

jr_051_5547:
    ld d, $05
    jr jr_051_5559

jr_051_554b:
    ld d, $04
    jr jr_051_5559

jr_051_554f:
    ld d, $03
    jr jr_051_5559

jr_051_5553:
    ld d, $02
    jr jr_051_5559

jr_051_5557:
    ld d, $01

jr_051_5559:
    ld a, c
    ld hl, $da0a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], d
    inc c
    dec b
    jr nz, jr_051_5516

    ret


    ld a, [$c0dc]
    ld l, a
    ld a, [$c0dd]
    ld h, a
    ld a, [$c0de]
    call SaveBtlS_6a67
    ret


    ld a, [wEventStateMachineIndex]
    rst $00
    and b
    ld d, l
    ld [bc], a
    ld d, [hl]
    jr c, @+$58

    ld [hl], $57
    ld e, a
    ld d, a
    cp d
    ld d, a
    call nz, $ce57
    ld d, a
    ret c

    ld d, a
    ld [c], a
    ld d, a
    rst $20
    ld d, a
    ccf
    ld e, b
    add a
    ld e, c
    db $e3
    ld e, c
    ld a, [de]
    ld e, d
    ld d, e
    ld e, d
    cp h
    ld e, d
    push hl
    ld e, d
    ld a, [$cac0]
    ld hl, $cb0c
    call GetMonsterDataPtr
    ld a, [hl]
    cp $63
    jr c, jr_051_55b7

    ld hl, $d9ec
    inc [hl]
    xor a
    ld [wEventStateMachineIndex], a
    ret


jr_051_55b7:
    ld a, $0a
    ld [$c823], a
    ld a, $0b
    ld [$c822], a
    ld hl, $8820
    ld de, $0a01
    call LoadBtlS_73a3
    ld a, $1b
    ld [$c823], a
    ld a, $0b
    ld [$c822], a
    ld hl, $89c0
    ld de, $0f01
    call LoadBtlS_73a3
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    xor a
    ld hl, wEventStateMachineIndex
    ld bc, $0008
    call FillNBytesWithRegA
    ld hl, $9800
    ld a, l
    ld [$d9f8], a
    ld a, h
    ld [$d9f9], a
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$cac0]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    ld a, [$cac0]
    ld hl, $cb0c
    call GetMonsterDataPtr
    ld a, [hl]
    inc a
    ld hl, $c190
    call ExtractDigits
    ld a, $47
    call SetBGM
    ld hl, DispatchBank42Rst
    call SetupTilemapTransfer
    ld hl, $1302
    rst $10
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$c8d0]
    or a
    jp nz, Jump_051_56ec

    ld a, [$cac0]
    ld hl, $cb13
    call GetMonsterDataPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    sub $e7
    ld l, a
    ld a, h
    sbc $03
    ld h, a
    ld a, h
    or l
    jr nz, jr_051_5660

    xor a
    ld [$c8ca], a

jr_051_5660:
    ld a, [$cac0]
    ld hl, $cb17
    call GetMonsterDataPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    sub $e7
    ld l, a
    ld a, h
    sbc $03
    ld h, a
    ld a, h
    or l
    jr nz, jr_051_567c

    xor a
    ld [$c8cb], a

jr_051_567c:
    ld a, [$cac0]
    ld hl, $cb19
    call GetMonsterDataPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    sub $e7
    ld l, a
    ld a, h
    sbc $03
    ld h, a
    ld a, h
    or l
    jr nz, jr_051_5698

    xor a
    ld [$c8cc], a

jr_051_5698:
    ld a, [$cac0]
    ld hl, $cb1b
    call GetMonsterDataPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    sub $e7
    ld l, a
    ld a, h
    sbc $03
    ld h, a
    ld a, h
    or l
    jr nz, jr_051_56b4

    xor a
    ld [$c8cd], a

jr_051_56b4:
    ld a, [$cac0]
    ld hl, $cb1d
    call GetMonsterDataPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    sub $ff
    ld l, a
    ld a, h
    sbc $01
    ld h, a
    ld a, h
    or l
    jr nz, jr_051_56d0

    xor a
    ld [$c8ce], a

jr_051_56d0:
    ld a, [$cac0]
    ld hl, $cb1f
    call GetMonsterDataPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    sub $ff
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld a, h
    or l
    jr nz, jr_051_56ec

    xor a
    ld [$c8cf], a

Jump_051_56ec:
jr_051_56ec:
    ld a, [$c8ca]
    ld hl, $c1a0
    call ExtractDigits
    ld a, [$c8cb]
    ld hl, $c1a4
    call ExtractDigits
    ld a, [$c8cc]
    ld hl, $c1a8
    call ExtractDigits
    ld a, [$c8cd]
    ld hl, $c1ac
    call ExtractDigits
    ld a, [$c8ce]
    ld hl, $c1b0
    call ExtractDigits
    ld a, [$c8cf]
    ld hl, $c1b4
    call ExtractDigits
    ld hl, $0b1e
    ld a, [$c8d0]
    or a
    jr z, jr_051_572e

    ld hl, $0b1f

jr_051_572e:
    call SetupTilemapTransfer
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $c0d8
    ld bc, $0028
    ld a, $ff
    call FillNBytesWithRegA
    ld a, [$cac0]
    ld hl, $caea
    call GetMonsterDataPtr
    ld de, $c0d8
    ld b, $08

jr_051_5754:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_051_5754

    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $0605
    rst $10
    ldh a, [$d8]
    cp $ff
    jr z, jr_051_57b1

    ld l, a
    ld h, $06
    ld de, $c1a0
    call SetupVRAMParams
    ld c, $ff
    ld hl, $0b02
    ldh a, [$d9]
    or a
    jr z, jr_051_5799

    ld hl, $0b0f
    cp $02
    jr z, jr_051_5799

    ldh a, [$da]
    ld l, a
    ld h, $06
    ld de, $c1b0
    call SetupVRAMParams
    ld hl, DispatchAboveE2
    ldh a, [$da]
    ld c, a

jr_051_5799:
    push bc
    call SetupTilemapTransfer
    pop bc
    ld hl, $c0d8
    ld b, $28

jr_051_57a3:
    ld a, [hl]
    cp c
    jr nz, jr_051_57ac

    ldh a, [$d8]
    ld [hl], a
    jr jr_051_57b0

jr_051_57ac:
    inc hl
    dec b
    jr nz, jr_051_57a3

jr_051_57b0:
    ret


jr_051_57b1:
    ld hl, $0106
    rst $10
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call SetBtlS_580d
    cp $09
    jr nc, jr_051_57f9

    ld a, $10
    ld [wEventStateMachineIndex], a
    ret


jr_051_57f9:
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, $0b04
    call SetupTilemapTransfer
    call SetBtlS_742a
    call SetBtlS_768a
    call ProcessBattleTurn
    ret


SetBtlS_580d:
    ld hl, wDebug_main_menu_option
    ld bc, $0028
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld de, wDebug_main_menu_option
    ld b, $28
    ld c, $00

jr_051_5822:
    ld a, [hl+]
    cp $ff
    jr z, jr_051_582a

    ld [de], a
    inc de
    inc c

jr_051_582a:
    dec b
    jr nz, jr_051_5822

    ld a, c
    push af
    ld hl, $c0d8
    ld de, wDebug_main_menu_option
    ld b, $28

jr_051_5837:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_051_5837

    pop af
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $89c0
    ld de, $5112
    call WaitDMATransfer
    call SetBtlS_580d
    ld [$d9f6], a
    ld hl, wEventStateMachineIndex
    inc [hl]
    call SetBtlS_58f3
    call SetBtlS_592a
    call SetBtlS_742a
    call CallBtlS_5867
    call ProcessBattleTurn
    ret


CallBtlS_5867:
    call SetBtlS_768a
    ld hl, $5505
    rst $10
    ld de, $6e78
    call LoadBtlS_72cc
    ld de, $6fe2
    call LoadBtlS_72cc
    ld de, $7077
    call LoadBtlS_72cc
    call SetBtlS_58a9
    ld hl, $cb17
    ld a, [$cac0]
    call GetMonsterDataPtr
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $0125
    call LoadBtlS_726a
    call FillMemory
    call ClrBtlS_7524
    ld de, $59d7
    ld a, [$d9f6]
    ld c, a
    ld hl, wOPTN_and_Item_selection
    call ReadBtlS_75c5
    ret


SetBtlS_58a9:
    ld hl, $c0d8
    ld a, [wPLAN_selection]
    add a
    add a
    ld b, a
    ld a, [wOPTN_and_Item_selection]
    and $7f
    add b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld e, [hl]
    ld d, $00
    ld hl, $0703
    rst $10
    ld c, e
    ld b, d
    ld a, e
    add $19
    ld e, a
    ld a, d
    adc $fc
    ld d, a
    ld a, d
    or e
    jr z, jr_051_58dd

    ld hl, $0121
    call LoadBtlS_726a
    call FillMemory
    ret


jr_051_58dd:
    ld hl, $cb17
    ld a, [$cac0]
    call GetMonsterDataPtr
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $0121
    call LoadBtlS_726a
    call FillMemory
    ret


SetBtlS_58f3:
    ld de, $c0d8
    ld a, [wPLAN_selection]
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $9360
    call SaveBtlS_590d
    call SaveBtlS_590d
    call SaveBtlS_590d

SaveBtlS_590d:
    push de
    push hl
    ld a, [de]
    ld [$c823], a
    ld a, $06
    ld [$c822], a
    ld de, WaitSTATForOverlayB
    call LoadBtlS_73a3
    pop hl
    ld a, l
    add $90
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


SetBtlS_592a:
    ld hl, $c0d8
    ld a, [wPLAN_selection]
    add a
    add a
    ld b, a
    ld a, [wOPTN_and_Item_selection]
    and $7f
    add b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    ld hl, $9000
    ld de, $1203
    ld a, [$c827]
    ld c, a
    ld a, [$c828]
    ld b, a
    push bc
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    push bc
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld hl, $5602
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ret


    ld de, $59d7
    ld hl, wOPTN_and_Item_selection
    ld a, [$d9f6]
    ld c, a
    ld b, $04
    ld a, [hl+]
    push af
    ld a, [hl-]
    push af
    call LoadBtlS_744a
    pop af
    ld hl, wPLAN_selection
    cp [hl]
    jr z, jr_051_59ad

    call SetBtlS_58f3
    call SetBtlS_592a
    call SetBtlS_58a9
    call ProcessBattleTurn

jr_051_59ad:
    pop af
    ld hl, wOPTN_and_Item_selection
    cp [hl]
    jr z, jr_051_59bd

    call SetBtlS_592a
    call SetBtlS_58a9
    call ProcessBattleTurn

jr_051_59bd:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_051_59d6

    ld a, $59
    call PlaySoundEffect
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, wOPTN_and_Item_selection
    set 7, [hl]
    xor a
    ld [$c8dd], a

jr_051_59d6:
    ret


    ld d, d
    ld bc, $0069
    xor c
    nop
    jp hl


    nop
    add hl, hl
    ld bc, $ffff
    ld a, [$c825]
    or a
    ret nz

    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, $c0d8
    ld a, [wPLAN_selection]
    add a
    add a
    ld b, a
    ld a, [wOPTN_and_Item_selection]
    and $7f
    add b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $06
    ld de, $c180
    call SetupVRAMParams
    ld hl, $0b05
    call SetupTilemapTransfer
    ld de, $2e07
    call LoadBtlS_72cc
    call ProcessBattleTurn
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wEventStateMachineIndex
    inc [hl]
    ld a, $5c
    call PlaySoundEffect
    call SetBtlS_742a
    call CallBtlS_5867
    ld de, $2e07
    call LoadBtlS_72cc
    ld hl, $89c0
    ld de, $5112
    call WaitDMATransfer
    ld de, $6eef
    call LoadBtlS_72cc
    call ClrBtlS_7524
    ld de, $5ab6
    ld a, [$c8dd]
    call BtlSFunc_75e7
    call ProcessBattleTurn
    ret


    ld de, $5ab6
    ld hl, $c8dd
    ld b, $02
    call BtlSFunc_74d3
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_051_5a72

jr_051_5a65:
    ld hl, RunScriptEngine
    call SetupTilemapTransfer
    ld a, $0b
    ld [wEventStateMachineIndex], a
    jr jr_051_5ab5

jr_051_5a72:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_051_5ab5

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8dd]
    cp $81
    jr z, jr_051_5a65

    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, $c8dd
    set 7, [hl]
    ld hl, $c0d8
    ld a, [wPLAN_selection]
    add a
    add a
    ld b, a
    ld a, [wOPTN_and_Item_selection]
    and $7f
    add b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [hl], $ff
    ld l, a
    ld h, $06
    ld de, $c180
    call SetupVRAMParams
    ld hl, $0b06
    call SetupTilemapTransfer

jr_051_5ab5:
    ret


    cpl
    ld bc, $016f
    rst $38
    rst $38
    ld a, [$c825]
    or a
    ret nz

    ld a, [$cac0]
    ld hl, $cb0c
    call GetMonsterDataPtr
    push hl
    ld a, [$cac0]
    ld hl, $cb0d
    call GetMonsterDataPtr
    ld a, [hl]
    dec a
    pop hl
    cp [hl]
    jr nz, jr_051_5ae0

    ld hl, $0b20
    call SetupTilemapTransfer

jr_051_5ae0:
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call SetBtlS_580d
    cp $09
    jr c, jr_051_5b04

    ld hl, RunScriptEngine
    call SetupTilemapTransfer
    ld a, $0b
    ld [wEventStateMachineIndex], a
    xor a
    ld [wOPTN_and_Item_selection], a
    ld [wPLAN_selection], a
    ret


jr_051_5b04:
    call LoadBtlS_5b1c
    call LoadBtlS_5b31
    call SetBtlS_742a
    call SetBtlS_768a
    call ProcessBattleTurn
    xor a
    ld [wEventStateMachineIndex], a
    ld hl, $d9ec
    dec [hl]
    ret


LoadBtlS_5b1c:
    ld a, [$cac0]
    ld hl, $caea
    call GetMonsterDataPtr
    ld de, $c0d8
    ld b, $08

jr_051_5b2a:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_051_5b2a

    ret


LoadBtlS_5b31:
    ld a, [$cac0]
    ld hl, $cb0c
    call GetMonsterDataPtr
    ld a, [hl]
    cp $63
    ret nc

    ld a, [$cac0]
    ld hl, $cb0c
    call GetMonsterDataPtr
    ld a, [hl]
    inc a
    ld [hl], a
    ld a, [$c8d0]
    or a
    jr nz, jr_051_5b99

    ld a, [$c8ca]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call AddMonsterHP
    ld a, [$c8cb]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call AddMonsterMP
    ld a, [$c8cc]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call AddMonsterATK
    ld a, [$c8cd]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call AddMonsterDEF
    ld a, [$c8ce]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call AddMonsterAGL
    ld a, [$c8cf]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call AddMonsterINT
    ret


jr_051_5b99:
    ld a, [$c8ca]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call SubMonsterHP
    ld a, [$c8cb]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call DecrementMonsterMP
    ld a, [$c8cc]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call SubMonsterATK
    ld a, [$c8cd]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call SubMonsterDEF
    ld a, [$c8ce]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call SubMonsterAGL
    ld a, [$c8cf]
    ld l, a
    ld h, $00
    ld a, [$cac0]
    call SubMonsterINT
    ld a, [$cac0]
    ld hl, $cb13
    call GetMonsterDataPtr
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    push bc
    ld a, [$cac0]
    ld hl, $cb11
    call GetMonsterDataPtr
    pop bc
    ld a, c
    sub [hl]
    inc hl
    ld a, b
    sbc [hl]
    jr nc, jr_051_5c02

    ld [hl], b
    dec hl
    ld [hl], c

jr_051_5c02:
    ld a, [$cac0]
    ld hl, $cb17
    call GetMonsterDataPtr
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    push bc
    ld a, [$cac0]
    ld hl, $cb15
    call GetMonsterDataPtr
    pop bc
    ld a, c
    sub [hl]
    inc hl
    ld a, b
    sbc [hl]
    jr nc, jr_051_5c23

    ld [hl], b
    dec hl
    ld [hl], c

jr_051_5c23:
    call LoadBtlS_549b
    call LoadBtlS_6a7e
    call SetBtlS_768a
    call LoadBtlS_79cb
    call ProcessBattleTurn
    ret


    ld a, [wEventStateMachineIndex]
    rst $00
    add c
    ld e, h
    daa
    ld e, l
    ld c, l
    ld e, l
    sub c
    ld e, l
    ld [$4d5d], a
    ld e, [hl]
    ld a, d
    ld e, [hl]
    rst $10
    ld e, [hl]
    xor b
    ld e, a
    ld c, a
    ld h, c
    cp l
    ld h, c
    jp nz, $f961

    ld h, c
    xor d
    ld h, d
    jr jr_051_5cb8

    ld d, e
    ld h, e
    add b
    ld h, e
    db $c2, $63, $01

    ld h, h
    ld l, h
    ld h, h
    db $db
    ld h, h
    ld sp, $6765
    ld h, l
    adc d
    ld h, l
    sbc $65
    ld d, l
    ld h, [hl]
    add b
    ld h, [hl]
    di
    ld h, [hl]
    rla
    ld h, a
    adc c
    ld h, a
    adc c
    ld h, a
    and [hl]
    ld h, a
    or [hl]
    ld h, a
    ldh a, [$67]
    add hl, hl
    ld l, b
    dec a
    ld l, b
    ld a, [hl]
    ld l, b
    ld hl, $1702
    rst $10
    ld hl, $1708
    rst $10
    ld a, $0a
    ld [$c823], a
    ld a, $0b
    ld [$c822], a
    ld hl, $8820
    ld de, $0a01
    call LoadBtlS_73a3
    ld a, $1b
    ld [$c823], a
    ld a, $0b
    ld [$c822], a
    ld hl, $89c0
    ld de, $0f01
    call LoadBtlS_73a3
    ld a, $14
    ld [$da14], a
    ld hl, $1403
    rst $10

jr_051_5cb8:
    ld hl, $1401
    rst $10
    ld hl, $9000
    ld a, [$da18]
    call SaveBtlS_6a67
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    xor a
    ld hl, wEventStateMachineIndex
    ld bc, $0008
    call FillNBytesWithRegA
    ld hl, $9800
    ld a, l
    ld [$d9f8], a
    ld a, h
    ld [$d9f9], a
    ld a, $00
    ld hl, $00c7
    call BtlSFunc_7672
    ld a, [$da18]
    ld hl, $00c7
    call BtlSFunc_6943
    call ProcessBattleTurn
    ld de, $c1c0
    ld a, [$ca8e]
    call CmpBtlS_5d13
    ld a, [$ca8f]
    call CmpBtlS_5d13
    ld a, [$ca90]
    call CmpBtlS_5d13
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


CmpBtlS_5d13:
    cp $ff
    ret z

    push de
    ld hl, $cac2
    call GetMonsterDataPtr
    pop de
    ld b, $08

jr_051_5d20:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_051_5d20

    ret


    ld a, [$da18]
    ld l, a
    ld h, $05
    ld de, $c180
    call SetupVRAMParams
    ld a, $14
    ld hl, $cacc
    call GetMonsterDataPtr
    ld a, [hl]
    ld de, $c180
    call SaveBtlS_6915
    ld hl, $0b10
    call SetupTilemapTransfer
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    ld hl, wEventStateMachineIndex
    inc [hl]
    call SetBtlS_742a
    call SetBtlS_768a
    ld a, $00
    ld hl, $00c7
    call BtlSFunc_7672
    ld a, [$da18]
    ld hl, $00c7
    call BtlSFunc_6943
    ld hl, $89c0
    ld de, $5112
    call WaitDMATransfer
    ld de, $6eef
    call LoadBtlS_72cc
    call ClrBtlS_7524
    ld de, $5de4
    ld a, [wMenu_selection]
    call BtlSFunc_75e7
    call ProcessBattleTurn
    ret


    ld de, $5de4
    ld hl, wMenu_selection
    ld b, $02
    call BtlSFunc_74d3
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_051_5dbc

jr_051_5da3:
    ld a, [$da18]
    ld l, a
    ld h, $05
    ld de, $c180
    call SetupVRAMParams
    ld hl, $0b12
    call SetupTilemapTransfer
    ld a, $1d
    ld [wEventStateMachineIndex], a
    jr jr_051_5de3

jr_051_5dbc:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_051_5de3

    ld a, $59
    call PlaySoundEffect
    ld a, [wMenu_selection]
    cp $81
    jr z, jr_051_5da3

    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, wMenu_selection
    set 7, [hl]
    ld hl, wOPTN_and_Item_selection
    ld bc, $0007
    ld a, $00
    call FillNBytesWithRegA

jr_051_5de3:
    ret


    cpl
    ld bc, $016f
    rst $38
    rst $38
    call SetBtlS_5e34
    or a
    jr z, jr_051_5df7

    ld a, $15
    ld [wEventStateMachineIndex], a
    jr jr_051_5e33

jr_051_5df7:
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, $0b11
    call SetupTilemapTransfer
    call SetBtlS_742a
    call SetBtlS_768a
    ld a, $00
    ld hl, $00c7
    call BtlSFunc_7672
    ld a, [$da18]
    ld hl, $00c7
    call BtlSFunc_6943
    ld hl, $89c0
    ld de, $5112
    call WaitDMATransfer
    ld de, $6eef
    call LoadBtlS_72cc
    ld de, $5de4
    ld a, [wMenu_selection]
    call BtlSFunc_75e7
    call ProcessBattleTurn

jr_051_5e33:
    ret


SetBtlS_5e34:
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_051_5e3b:
    ld a, [de]
    or a
    jr nz, jr_051_5e40

    inc c

jr_051_5e40:
    push bc                     ; CF3 (S60): slot advance -> bank $73 entry 2
    push hl                     ; (DE += $95 with the WRAM<->SRAM boundary hop
    ld hl, $7302                ; at slot 2->3). Same-size 8-byte window.
    rst $10                     ; BC/HL preserved (rst $10 clobbers BC via its
    pop hl                      ; `ld bc,$4001` table index — walkers keep live
    pop bc                      ; counters in BC). A/flags clobbered as vanilla.
    dec b
    jr nz, jr_051_5e3b

    ld a, c
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, $89c0
    ld de, $5112
    call WaitDMATransfer
    ld de, $6eef
    call LoadBtlS_72cc
    call ClrBtlS_7524
    ld de, $5ed1
    ld a, [wOPTN_and_Item_selection]
    call BtlSFunc_75e7
    call ProcessBattleTurn
    ret


    ld de, $5ed1
    ld hl, wOPTN_and_Item_selection
    ld b, $02
    call BtlSFunc_74d3
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_051_5ea5

jr_051_5e8c:
    ld a, [$da18]
    ld l, a
    ld h, $05
    ld de, $c180
    call SetupVRAMParams
    ld hl, $0b12
    call SetupTilemapTransfer
    ld a, $1d
    ld [wEventStateMachineIndex], a
    jr jr_051_5ed0

jr_051_5ea5:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_051_5ed0

    ld a, $59
    call PlaySoundEffect
    ld a, [wOPTN_and_Item_selection]
    cp $81
    jr z, jr_051_5e8c

    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ld hl, wOPTN_and_Item_selection
    set 7, [hl]
    inc hl
    ld [hl], $00
    ld a, $1f
    ld [wEventStateMachineIndex], a

jr_051_5ed0:
    ret


    cpl
    ld bc, $016f
    rst $38
    rst $38
    call SetBtlS_5f2e
    or a
    jr nz, jr_051_5ee9

    ld hl, $0b1c
    call SetupTilemapTransfer
    ld a, $22
    ld [wEventStateMachineIndex], a
    ret


jr_051_5ee9:
    call SetBtlS_5f64
    ld hl, $0b13
    ld a, [$c8e4]
    and $01
    jr z, jr_051_5ef9

    ld hl, $0b22

jr_051_5ef9:
    call SetupTilemapTransfer
    call CallBtlS_5f07
    call ProcessBattleTurn
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


CallBtlS_5f07:
    call SetBtlS_742a
    call SetBtlS_768a
    ld a, $00
    ld hl, $00c7
    call BtlSFunc_7672
    ld a, [$da18]
    ld hl, $00c7
    call BtlSFunc_6943
    ld de, $70ab
    call LoadBtlS_72cc
    ld de, $6823
    ld a, [$c8e4]
    call BtlSFunc_75e7
    ret


SetBtlS_5f2e:
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_051_5f35:
    push de
    ld a, [de]
    or a
    jr z, jr_051_5f53

    ld a, e
    add $63
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld a, [$c8e4]
    and $01
    ld l, a
    ld a, [de]
    ld h, a
    srl a
    or h
    and $01
    xor l
    jr nz, jr_051_5f53

    inc c

jr_051_5f53:
    pop de
    push bc                     ; CF3 (S60): slot advance -> bank $73 entry 2
    push hl                     ; (DE += $95 with the WRAM<->SRAM boundary hop
    ld hl, $7302                ; at slot 2->3). Same-size 8-byte window.
    rst $10                     ; BC/HL preserved (rst $10 clobbers BC via its
    pop hl                      ; `ld bc,$4001` table index — walkers keep live
    pop bc                      ; counters in BC). A/flags clobbered as vanilla.
    dec b
    jr nz, jr_051_5f35

    ld a, c
    ld [$c8e9], a
    ret


SetBtlS_5f64:
    ld hl, $c0d8
    ld bc, $0014
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_051_5f79:
    push de
    ld a, [de]
    or a
    jr z, jr_051_5f9a

    ld a, e
    add $63
    ld e, a
    ld a, d
    adc $00
    ld d, a
    push hl
    ld a, [$c8e4]
    and $01
    ld l, a
    ld a, [de]
    ld h, a
    srl a
    or h
    and $01
    xor l
    pop hl
    jr nz, jr_051_5f9a

    ld [hl], c
    inc hl

jr_051_5f9a:
    pop de
    push bc                     ; CF3 (S60): slot advance -> bank $73 entry 2
    push hl                     ; (DE += $95 with the WRAM<->SRAM boundary hop
    ld hl, $7302                ; at slot 2->3). Same-size 8-byte window.
    rst $10                     ; BC/HL preserved (rst $10 clobbers BC via its
    pop hl                      ; `ld bc,$4001` table index — walkers keep live
    pop bc                      ; counters in BC). A/flags clobbered as vanilla.
    inc c
    dec b
    jr nz, jr_051_5f79

    ret


    ld a, [$c825]
    or a
    ret nz

    call LoadBtlS_5fec
    call SetBtlS_5fbb
    call ProcessBattleTurn
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


SetBtlS_5fbb:
    ld hl, $550c
    rst $10
    ld de, $6f14
    ld a, [$c8e4]
    and $01
    jr z, jr_051_5fcc

    ld de, $70d0

jr_051_5fcc:
    call LoadBtlS_72cc
    call ClrBtlS_7524
    ld de, $61a5
    ld a, [$c8e4]
    and $01
    jr z, jr_051_5fdf

    ld de, $61b1

jr_051_5fdf:
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadBtlS_75c5
    ret


LoadBtlS_5fec:
    ld a, [$c8e3]
    add a
    add a
    ld de, $c0d8
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [$c8e4]
    and $01
    jr z, jr_051_6014

    ld hl, $9240
    call SaveBtlS_605b
    call SaveBtlS_605b
    call SaveBtlS_605b
    call SaveBtlS_605b
    call LoadBtlS_609f
    ret


jr_051_6014:
    ld hl, $88c0
    call SaveBtlS_6020
    call SaveBtlS_6020
    call SaveBtlS_6020

SaveBtlS_6020:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr z, jr_051_6041

    ld a, [de]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    pop hl
    push hl
    call SaveBtlS_73dc
    pop hl
    ld a, l
    add $40
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


jr_051_6041:
    ld b, $20

jr_051_6043:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_051_6043

    pop hl
    ld a, l
    add $40
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


SaveBtlS_605b:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr z, jr_051_6085

    ld hl, $caca
    call GetMonsterDataPtr
    ld a, [hl]
    ld [$c823], a
    ld a, $05
    ld [$c822], a
    ld de, WaitSTATForOverlayB
    pop hl
    push hl
    call LoadBtlS_73a3
    pop hl
    ld a, l
    add $90
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


jr_051_6085:
    ld b, $48

jr_051_6087:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_051_6087

    pop hl
    ld a, l
    add $90
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


LoadBtlS_609f:
    ld a, [$c8e3]
    add a
    add a
    ld de, $c0d8
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $9480
    call SaveBtlS_60b9
    call SaveBtlS_60b9
    call SaveBtlS_60b9

SaveBtlS_60b9:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr z, jr_051_6135

    ld hl, $cb24
    call GetMonsterDataPtr
    ld a, [hl]
    cp $02
    ld a, $98
    jr nz, jr_051_60da

    ld a, l
    add $a8
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, [hl]
    and $01
    add $a7

jr_051_60da:
    ld [$c180], a
    ld a, $f0
    ld [$c181], a
    pop hl
    push hl
    ld a, [$c827]
    ld c, a
    ld a, [$c828]
    ld b, a
    push bc
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    push bc
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld de, $0101
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $02
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4102
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    pop hl
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


jr_051_6135:
    ld b, $08

jr_051_6137:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_051_6137

    pop hl
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


    ld de, $61a5
    ld a, [$c8e4]
    and $01
    jr z, jr_051_615c

    ld de, $61b1

jr_051_615c:
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    call LoadBtlS_744a
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_051_6175

    call LoadBtlS_5fec

jr_051_6175:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_051_618c

    call CallBtlS_67c3
    ld a, $20
    ld [wEventStateMachineIndex], a
    ld hl, $0b1a
    call SetupTilemapTransfer
    jr jr_051_61a4

jr_051_618c:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_051_61a4

    ld a, $59
    call PlaySoundEffect
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, wPLAN_selection
    set 7, [hl]
    inc hl
    ld [hl], $00

jr_051_61a4:
    ret


    add l
    ld bc, $00a1
    pop hl
    nop
    ld hl, $6101
    ld bc, $ffff
    adc e
    ld bc, $00a1
    pop hl
    nop
    ld hl, $6101
    ld bc, $ffff
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call SetBtlS_61cf
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


SetBtlS_61cf:
    ld de, $6f6e
    ld a, [$c8e4]
    and $01
    jr z, jr_051_61dc

    ld de, $7150

jr_051_61dc:
    call LoadBtlS_72cc
    call ClrBtlS_7524
    ld de, $629e
    ld a, [$c8e4]
    and $01
    jr z, jr_051_61ef

    ld de, $62a4

jr_051_61ef:
    ld a, [$c8dd]
    call BtlSFunc_75e7
    call ProcessBattleTurn
    ret


    ld de, $629e
    ld a, [$c8e4]
    and $01
    jr z, jr_051_6206

    ld de, $62a4

jr_051_6206:
    ld hl, $c8dd
    ld b, $02
    call BtlSFunc_74d3
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_051_622b

    ld hl, wEventStateMachineIndex
    dec [hl]
    ld hl, wEventStateMachineIndex
    dec [hl]
    ld hl, wEventStateMachineIndex
    dec [hl]
    ld hl, wEventStateMachineIndex
    dec [hl]
    ld hl, wEventStateMachineIndex
    dec [hl]
    jr jr_051_629d

jr_051_622b:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_051_629d

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8dd]
    cp $81
    jr z, jr_051_624c

    xor a
    ld [$c90d], a
    ld [$c90e], a
    ld a, $19
    ld [wEventStateMachineIndex], a
    jr jr_051_629d

jr_051_624c:
    ld a, [$ca8d]
    cp $01
    jr z, jr_051_6260

    ld a, [$ca8f]
    ld hl, $cb0b
    call GetMonsterDataPtr
    bit 7, [hl]
    jr z, jr_051_6291

jr_051_6260:
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    ld hl, $c0d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$ca8e]
    cp [hl]
    jr nz, jr_051_6291

    ld hl, $0b24
    call SetupTilemapTransfer
    ld de, $2e07
    call LoadBtlS_72cc
    call ProcessBattleTurn
    ld a, $1f
    ld [wEventStateMachineIndex], a
    jr jr_051_629d

jr_051_6291:
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, $c8dd
    set 7, [hl]
    inc hl
    ld [hl], $00

jr_051_629d:
    ret


    ld l, $01
    ld l, [hl]
    ld bc, $ffff
    dec l
    ld bc, $016d
    rst $38
    rst $38
    ld a, [$c825]
    or a
    ret nz

    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    ld hl, $c0d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    push af
    ld hl, $cb24
    call GetMonsterDataPtr
    ld a, [hl]
    or a
    jr z, jr_051_62e0

    pop af
    push af
    ld hl, $0b1d
    call SetupTilemapTransfer
    ld de, $70d0
    call LoadBtlS_72cc
    jr jr_051_62f6

jr_051_62e0:
    pop af
    push af
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    ld hl, $0b14
    call SetupTilemapTransfer

jr_051_62f6:
    pop af
    ld hl, $cac1
    call GetMonsterDataPtr
    ld [hl], $00
    ld hl, $0105
    rst $10
    call LoadBtlS_6a7e
    call SetBtlS_768a
    ld de, $2e07
    call LoadBtlS_72cc
    call ProcessBattleTurn
    ld a, $15
    ld [wEventStateMachineIndex], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wEventStateMachineIndex
    inc [hl]
    ld a, [$da14]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    ld hl, $0b15
    call SetupTilemapTransfer
    call SetBtlS_742a
    call SetBtlS_768a
    ld a, $00
    ld hl, $00c7
    call BtlSFunc_7672
    ld a, [$da18]
    ld hl, $00c7
    call BtlSFunc_6943
    call ProcessBattleTurn
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, $89c0
    ld de, $5112
    call WaitDMATransfer
    ld de, $6eef
    call LoadBtlS_72cc
    call ClrBtlS_7524
    ld de, $63bc
    ld a, [$c8de]
    call BtlSFunc_75e7
    call ProcessBattleTurn
    ret


    ld de, $63bc
    ld hl, $c8de
    ld b, $02
    call BtlSFunc_74d3
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_051_6398

jr_051_6392:
    ld hl, wEventStateMachineIndex
    inc [hl]
    jr jr_051_63bb

jr_051_6398:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_051_63bb

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8de]
    cp $81
    jr z, jr_051_6392

    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, $c8de
    set 7, [hl]
    inc hl
    ld [hl], $00

jr_051_63bb:
    ret


    cpl
    ld bc, $016f
    rst $38
    rst $38
    ld a, [$c825]
    or a
    ret nz

    ld hl, wEventStateMachineIndex
    inc [hl]
    ld a, [$da14]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    ld hl, $0b16
    call SetupTilemapTransfer
    ld a, $1e
    ld [wEventStateMachineIndex], a
    ret


; BATTLE JOIN first-empty scan (S56): returns c = first empty slot (or
; $14 if full). The joined monster is built via the bank $14 builder and,
; if $CA8D < 3, appended to the party list + canonicalized (code below).
SetBtlS_63e8:
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_051_63ef:
    ld a, [de]
    or a
    jr z, jr_051_63ff

    inc c
    push bc                     ; CF3 (S60): slot advance -> bank $73 entry 2
    push hl                     ; (DE += $95 with the WRAM<->SRAM boundary hop
    ld hl, $7302                ; at slot 2->3). Same-size 8-byte window.
    rst $10                     ; BC/HL preserved (rst $10 clobbers BC via its
    pop hl                      ; `ld bc,$4001` table index — walkers keep live
    pop bc                      ; counters in BC). A/flags clobbered as vanilla.
    dec b
    jr nz, jr_051_63ef

jr_051_63ff:
    ld a, c
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$ca8d]
    cp $03
    jr z, jr_051_642b

    ld a, [$ca8d]
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da14]
    ld [hl], a
    ld hl, $ca8d
    inc [hl]
    ld hl, $0105
    rst $10
    ld a, $1e
    ld [wEventStateMachineIndex], a
    ret


jr_051_642b:
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, $0b18
    call SetupTilemapTransfer
    call CallBtlS_643c
    call ProcessBattleTurn
    ret


CallBtlS_643c:
    call SetBtlS_742a
    call SetBtlS_768a
    ld a, $00
    ld hl, $00c7
    call BtlSFunc_7672
    ld a, [$da18]
    ld hl, $00c7
    call BtlSFunc_6943
    ld hl, $89c0
    ld de, $5112
    call WaitDMATransfer
    ld de, $6eef
    call LoadBtlS_72cc
    ld de, $63bc
    ld a, [$c8de]
    call BtlSFunc_75e7
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wEventStateMachineIndex
    inc [hl]
    call SetBtlS_64ac
    call SetBtlS_6499
    call SetBtlS_6482
    call ProcessBattleTurn
    ret


SetBtlS_6482:
    ld hl, $550c
    rst $10
    ld de, $6f14
    call LoadBtlS_72cc
    call ClrBtlS_7524
    ld de, $6527
    ld a, [$c8df]
    call BtlSFunc_75e7
    ret


SetBtlS_6499:
    ld de, $c0d8
    ld hl, $88c0
    call SaveBtlS_6020
    call SaveBtlS_6020
    call SaveBtlS_6020
    call SaveBtlS_6020
    ret


SetBtlS_64ac:
    ld hl, $c0d8
    ld bc, $0004
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld a, [$ca8e]
    cp $ff
    call nz, WriteBtlS_64d9
    ld a, [$ca8f]
    cp $ff
    call nz, WriteBtlS_64d9
    ld a, [$ca90]
    cp $ff
    call nz, WriteBtlS_64d9
    ld a, [$da14]
    call WriteBtlS_64d9
    ret


WriteBtlS_64d9:
    ld [hl+], a
    ret


    ld de, $6527
    ld hl, $c8df
    ld a, [$ca8d]
    inc a
    ld b, a
    call BtlSFunc_74d3
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_051_650a

    ld hl, wEventStateMachineIndex
    dec [hl]
    ld hl, wEventStateMachineIndex
    dec [hl]
    ld hl, wEventStateMachineIndex
    dec [hl]
    ld hl, wEventStateMachineIndex
    dec [hl]
    ld hl, wEventStateMachineIndex
    dec [hl]
    ld hl, wEventStateMachineIndex
    dec [hl]
    jr jr_051_6526

jr_051_650a:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_051_6526

    ld a, $59
    call PlaySoundEffect
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, $c8df
    set 7, [hl]
    inc hl
    ld [hl], $00

jr_051_6526:
    ret


    and c
    nop
    pop hl
    nop
    ld hl, $6101
    ld bc, $ffff
    ld a, [$c825]
    or a
    ret nz

    call SetBtlS_63e8
    ld [$da14], a
    call SetBtlS_6928
    ld a, [$da18]
    ld l, a
    ld h, $05
    ld de, $c180
    call SetupVRAMParams
    ld a, [$da14]
    ld hl, $cacc
    call GetMonsterDataPtr
    ld a, [hl]
    ld de, $c180
    call SaveBtlS_6915
    ld hl, $0b17
    call SetupTilemapTransfer
    ld a, $23
    ld [wEventStateMachineIndex], a
    ret


    ld a, [$c825]
    or a
    ret nz

    call SetBtlS_6574
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


SetBtlS_6574:
    ld de, $6f6e
    call LoadBtlS_72cc
    call ClrBtlS_7524
    ld de, $65d8
    ld a, [$c8e0]
    call BtlSFunc_75e7
    call ProcessBattleTurn
    ret


    ld de, $65d8
    ld hl, $c8e0
    ld b, $02
    call BtlSFunc_74d3
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_051_65aa

    ld hl, wEventStateMachineIndex
    dec [hl]
    ld hl, wEventStateMachineIndex
    dec [hl]
    ld hl, wEventStateMachineIndex
    dec [hl]
    jr jr_051_65d7

jr_051_65aa:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_051_65d7

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8e0]
    cp $81
    jr z, jr_051_65cb

    xor a
    ld [$c90d], a
    ld [$c90e], a
    ld a, $1b
    ld [wEventStateMachineIndex], a
    jr jr_051_65d7

jr_051_65cb:
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld hl, $c8e0
    set 7, [hl]
    inc hl
    ld [hl], $00

jr_051_65d7:
    ret


    ld l, $01
    ld l, [hl]
    ld bc, $ffff
    ld a, [$c825]
    or a
    ret nz

    ld a, [$c8df]
    and $7f
    ld hl, $c0d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    ld a, [$da18]
    ld l, a
    ld h, $05
    ld de, $c190
    call SetupVRAMParams
    ld hl, $0b19
    call SetupTilemapTransfer
    ld de, $2e07
    call LoadBtlS_72cc
    call ProcessBattleTurn
    ld a, [$c8df]
    and $7f
    ld hl, $c0d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $ff
    ld hl, $ca8e
    ld a, [$c0d8]
    call CmpBtlS_6650
    ld a, [$c0d9]
    call CmpBtlS_6650
    ld a, [$c0da]
    call CmpBtlS_6650
    ld a, [$c0db]
    call CmpBtlS_6650
    ld hl, $0105
    rst $10
    ld a, $1d
    ld [wEventStateMachineIndex], a
    ret


CmpBtlS_6650:
    cp $ff
    ret z

    ld [hl+], a
    ret


    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    ld hl, $c0d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$cac0], a
    xor a
    ld [$c906], a
    ld hl, $0701
    rst $10
    ld a, [$c906]
    or a
    ret z

    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld de, $5b00
    ld hl, $9600
    call WaitDMATransfer
    ld de, $5b01
    ld hl, $8800
    call WaitDMATransfer
    ld a, $0a
    ld [$c823], a
    ld a, $0b
    ld [$c822], a
    ld hl, $8820
    ld de, $0a01
    call LoadBtlS_73a3
    ld a, $1b
    ld [$c823], a
    ld a, $0b
    ld [$c822], a
    ld hl, $89c0
    ld de, $0f01
    call LoadBtlS_73a3
    ld hl, $9000
    ld a, [$da18]
    call SaveBtlS_6a67
    call SetBtlS_5f2e
    call SetBtlS_5f64
    call LoadBtlS_5fec
    ld hl, $0b13
    ld a, [$c8e4]
    and $01
    jr z, jr_051_66d7

    ld hl, $0b22

jr_051_66d7:
    call SetupTilemapTransfer
    call RequestScreenUpdate
    call LoadBtlS_6a0d
    call CallBtlS_5f07
    call SetBtlS_5fbb
    call SetBtlS_61cf
    ld hl, $1708
    rst $10
    ld a, $0b
    ld [wEventStateMachineIndex], a
    ret


    ld a, [$c8df]
    and $7f
    ld hl, $c0d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$cac0], a
    xor a
    ld [$c906], a
    ld hl, $0701
    rst $10
    ld a, [$c906]
    or a
    ret z

    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld de, $5b00
    ld hl, $9600
    call WaitDMATransfer
    ld de, $5b01
    ld hl, $8800
    call WaitDMATransfer
    ld a, $0a
    ld [$c823], a
    ld a, $0b
    ld [$c822], a
    ld hl, $8820
    ld de, $0a01
    call LoadBtlS_73a3
    ld a, $1b
    ld [$c823], a
    ld a, $0b
    ld [$c822], a
    ld hl, $89c0
    ld de, $0f01
    call LoadBtlS_73a3
    ld hl, $9000
    ld a, [$da18]
    call SaveBtlS_6a67
    call SetBtlS_5f2e
    call SetBtlS_5f64
    call LoadBtlS_5fec
    ld hl, $0b18
    call SetupTilemapTransfer
    call RequestScreenUpdate
    call LoadBtlS_549b
    call LoadBtlS_6a7e
    call CallBtlS_643c
    call SetBtlS_64ac
    call SetBtlS_6499
    call SetBtlS_6482
    call SetBtlS_6574
    ld hl, $1708
    rst $10
    ld a, $17
    ld [wEventStateMachineIndex], a
    ret


    ld a, [$c825]
    or a
    ret nz

    call LoadBtlS_549b
    call LoadBtlS_6a7e
    call SetBtlS_742a
    call SetBtlS_768a
    call ProcessBattleTurn
    xor a
    ld [wEventStateMachineIndex], a
    ld hl, $d9ec
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $0b1a
    call SetupTilemapTransfer
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call CallBtlS_67c3
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


CallBtlS_67c3:
    call SetBtlS_742a
    call SetBtlS_768a
    ld a, $00
    ld hl, $00c7
    call BtlSFunc_7672
    ld a, [$da18]
    ld hl, $00c7
    call BtlSFunc_6943
    ld de, $70ab
    call LoadBtlS_72cc
    call ClrBtlS_7524
    ld de, $6823
    ld a, [$c8e4]
    call BtlSFunc_75e7
    call ProcessBattleTurn
    ret


    ld de, $6823
    ld hl, $c8e4
    ld b, $02
    call BtlSFunc_74d3
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_051_6809

    ld a, $04
    ld [wEventStateMachineIndex], a
    jr jr_051_6822

jr_051_6809:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_051_6822

    ld a, $59
    call PlaySoundEffect
    xor a
    ld [$c8e2], a
    ld [$c8e3], a
    ld a, $07
    ld [wEventStateMachineIndex], a

Jump_051_6822:
jr_051_6822:
    ret


    cpl
    ld bc, $016f
    rst $38
    rst $38
    ld a, [$c825]
    or a
    ret nz

    call CallBtlS_67c3
    ld a, $20
    ld [wEventStateMachineIndex], a
    ld hl, $0b1a
    call SetupTilemapTransfer
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wGameState
    set 4, [hl]
    ld a, $ff
    ld [$c8ef], a
    xor a
    ld [$c905], a
    ld a, [$da18]
    ld [$c8f5], a
    add $10
    ld [$c8f4], a
    ld a, [$da14]
    ld hl, $cacc
    call GetMonsterDataPtr
    ld a, [hl]
    ld [$c8f6], a
    ld a, [$da14]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld a, l
    ld [$c8f2], a
    ld a, h
    ld [$c8f3], a
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    call SetBtlS_6903
    ld hl, $0901
    rst $10
    call SetBtlS_6903
    ld a, [wGameState]
    bit 4, a
    ret nz

    call SetBtlS_742a
    call ProcessBattleTurn
    ld hl, $5605
    rst $10
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld de, $5b00
    ld hl, $9600
    call WaitDMATransfer
    ld de, $5b01
    ld hl, $8800
    call WaitDMATransfer
    ld a, $0a
    ld [$c823], a
    ld a, $0b
    ld [$c822], a
    ld hl, $8820
    ld de, $0a01
    call LoadBtlS_73a3
    ld a, $1b
    ld [$c823], a
    ld a, $0b
    ld [$c822], a
    ld hl, $89c0
    ld de, $0f01
    call LoadBtlS_73a3
    ld hl, $9000
    ld a, [$da18]
    call SaveBtlS_6a67
    call LoadBtlS_549b
    call LoadBtlS_6a7e
    call SetBtlS_742a
    call SetBtlS_768a
    ld a, $00
    ld hl, $00c7
    call BtlSFunc_7672
    ld a, [$da18]
    ld hl, $00c7
    call BtlSFunc_6943
    call ProcessBattleTurn
    ld a, $0e
    ld [wEventStateMachineIndex], a
    ret


SetBtlS_6903:
    ld hl, wMenu_selection
    ld de, $c876
    ld b, $08

jr_051_690b:
    ld c, [hl]
    ld a, [de]
    ld [hl+], a
    ld a, c
    ld [de], a
    inc de
    dec b
    jr nz, jr_051_690b

    ret


SaveBtlS_6915:
    push af

jr_051_6916:
    ld a, [de]
    inc de
    cp $f0
    jr nz, jr_051_6916

    dec de
    pop af
    and $01
    add $a7
    ld [de], a
    inc de
    ld a, $f0
    ld [de], a
    ret


SetBtlS_6928:
    ld hl, $cac1
    call GetMonsterDataPtr
    ld b, $95
    ld de, $d665

jr_051_6933:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_051_6933

    ld a, [$da18]
    ld hl, $ca94
    call SetBitInArray
    ret


BtlSFunc_6943:
    ld [$c81e], a
    ld a, l
    ld [$c820], a
    ld a, h
    ld [$c821], a
    ld a, [$dd61]
    ld [$c81f], a
    ld hl, $1706
    rst $10
    ret


    ld a, [$c86c]
    or a
    jr z, jr_051_696d

    ld a, [$c863]
    bit 1, a
    jr z, jr_051_696d

    ld a, [$db74]
    ld c, $00
    jr jr_051_6972

jr_051_696d:
    ld a, [$db75]
    ld c, $04

jr_051_6972:
    cp $03
    jr z, jr_051_6992

    cp $02
    jr z, jr_051_6982

    ld a, c
    ld hl, $00c7
    call SaveBtlS_69aa
    ret


jr_051_6982:
    ld a, c
    ld hl, $00c4
    call SaveBtlS_69aa
    inc c
    ld a, c
    ld hl, $00ca
    call SaveBtlS_69aa
    ret


jr_051_6992:
    ld a, c
    ld hl, $00c1
    call SaveBtlS_69aa
    inc c
    ld a, c
    ld hl, $00c7
    call SaveBtlS_69aa
    inc c
    ld a, c
    ld hl, $00cd
    call SaveBtlS_69aa
    ret


SaveBtlS_69aa:
    push bc
    push af
    ld a, l
    ld [$c820], a
    ld a, h
    ld [$c821], a
    pop af
    push af
    ld de, $dc3c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [$c81e], a
    call LoadBtlS_69d4
    pop af
    and $03
    add $04
    ld [$c81f], a
    ld hl, $1706
    rst $10
    pop bc
    ret


LoadBtlS_69d4:
    ld a, [wIsGBC]
    or a
    ret z

    ld a, [$c86c]
    or a
    jr z, jr_051_69ed

    ld a, [$c863]
    bit 1, a
    jr z, jr_051_69ed

    ld a, c
    cp $03
    jr nc, jr_051_6a0c

    jr jr_051_69f6

jr_051_69ed:
    ld a, c
    cp $04
    jr c, jr_051_6a0c

    cp $07
    jr z, jr_051_6a0c

jr_051_69f6:
    ld a, $02
    ldh [rSVBK], a
    ld a, c
    ld hl, $db00
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$c81e], a
    ld a, $00
    ldh [rSVBK], a

jr_051_6a0c:
    ret


LoadBtlS_6a0d:
    ld a, $00
    ld [wBattleTargetIdx], a
    ld hl, $5004
    rst $10
    ld a, $01
    ld [wBattleTargetIdx], a
    ld hl, $5004
    rst $10
    ld a, $02
    ld [wBattleTargetIdx], a
    ld hl, $5004
    rst $10
    ld hl, $9700
    ld b, $60

jr_051_6a2d:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    ld a, $00
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_051_6a2d

    ld a, [$db74]
    or a
    ret z

    ld de, $c1c0
    ld hl, $9700
    call SaveBtlS_73dc
    ld a, [$db74]
    cp $01
    ret z

    ld de, $c1c8
    ld hl, $9740
    call SaveBtlS_73dc
    ld a, [$db74]
    cp $02
    ret z

    ld de, $c1d0
    ld hl, $9780
    call SaveBtlS_73dc
    ret


SaveBtlS_6a67:
    push de
    push hl
    ld l, a
    ld h, $00
    add hl, hl
    ld a, l
    add $9f
    ld l, a
    ld a, h
    adc $2b
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    pop hl
    call WaitDMATransfer
    pop de
    ret


LoadBtlS_6a7e:
    ld a, $00
    ld [wBattleTargetIdx], a
    ld hl, $5004
    rst $10
    ld a, $01
    ld [wBattleTargetIdx], a
    ld hl, $5004
    rst $10
    ld a, $02
    ld [wBattleTargetIdx], a
    ld hl, $5004
    rst $10
    ret


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $70
    ld [hl], c
    ld [hl], d
    ld [hl], e
    jp c, $74e0

    ld [hl], l
    db $76
    ld [hl], a
    db $db
    ldh [$78], a
    ld a, c
    ld a, d
    ld a, e
    call c, $ffe0
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e1
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e1], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e1], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e2
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e2], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e2], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $70
    ld [hl], c
    ld [hl], d
    ld [hl], e
    jp c, $74e0

    ld [hl], l
    db $76
    ld [hl], a
    db $db
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e1
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e1], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e2
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e2], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $70
    ld [hl], c
    ld [hl], d
    ld [hl], e
    jp c, $ffe0

    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e1
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e2
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    and b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add l
    add [hl]
    add a
    adc b
    adc c
    ldh [$86], a
    adc c
    adc d
    adc e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld a, h
    add c
    add b
    ld a, a
    ldh [$e0], a
    ld a, l
    ld a, [hl]
    ld a, a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    and b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc d
    add d
    sbc e
    add d
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sub d
    sub e
    sub h
    add h
    sbc h
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $6c
    ld l, l
    ld l, [hl]
    ld l, a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub [hl]
    adc b
    sub c
    adc l
    add a
    adc d
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc e
    add [hl]
    sub h
    adc d
    sub l
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub [hl]
    sub c
    adc [hl]
    adc c
    add [hl]
    sub b
    adc [hl]
    adc h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub [hl]
    sub b
    adc e
    adc e
    sub c
    adc a
    sub l
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    sub d
    sub e
    sub h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    sbc e
    sbc h
    sbc l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
    and h
    and l
    and [hl]
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    and a
    xor b
    xor c
    xor d
    xor e
    xor h
    xor l
    xor [hl]
    xor a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ld h, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add l
    add [hl]
    add a
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    ld a, [hl]
    add h
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc b
    add a
    adc c
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add l
    add [hl]
    add a
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add [hl]
    adc b
    add a
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    ld h, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    sub d
    sub e
    sub h
    sub l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    sbc e
    sbc h
    sbc l
    sbc [hl]
    sbc a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    and b
    and c
    and d
    and e
    and h
    and l
    and [hl]
    and a
    xor b
    xor c
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    call nc, $d5e0
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    push de
    push de
    sub $ff
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    ld c, b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ld [hl], $37
    jr c, jr_051_6ec6

    ld a, [hl-]
    dec sp
    inc a
    dec a
    ld a, $ff
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ccf
    ld b, b
    ld b, c
    ld b, d
    ld b, e
    ld b, h
    ld b, l
    ld b, [hl]
    ld b, a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ld c, b
    ld c, c
    ld c, d
    ld c, e
    ld c, h
    ld c, l
    ld c, [hl]
    ld c, a
    ld d, b

jr_051_6ec6:
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ld d, c
    ld d, d
    ld d, e
    ld d, h
    ld d, l
    ld d, [hl]
    ld d, a
    ld e, b
    ld e, c
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ld c, $01
    ld a, [$efef]
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    call nc, $d6d5
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc l
    sbc [hl]
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    ld b, b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add d
    add e
    add h
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub b
    sub c
    sub d
    sub e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub h
    sub l
    sub [hl]
    sub a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sbc b
    sbc c
    sbc d
    sbc e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    dec c
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add l
    add [hl]
    add a
    adc b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc c
    adc d
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add d
    add e
    add h
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    ld h, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $00
    ld bc, $0302
    inc b
    dec b
    ld b, $07
    ld [$0a09], sp
    dec bc
    inc c
    dec c
    ld c, $0f
    db $10
    ld de, $d8ff
    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $12
    inc de
    inc d
    dec d
    ld d, $17
    jr @+$1b

    ld a, [de]
    dec de
    inc e
    dec e
    ld e, $1f
    jr nz, jr_051_7055

    ld [hl+], a
    inc hl
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $24
    dec h
    ld h, $27
    jr z, jr_051_707d

    ld a, [hl+]

jr_051_7055:
    dec hl
    inc l
    dec l
    ld l, $2f
    jr nc, jr_051_708d

    ld [hl-], a
    inc sp
    inc [hl]
    dec [hl]
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ret nz

    nop
    ld a, [$efef]
    rst $28

jr_051_707d:
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $9c
    sub $d5
    ldh [$e2], a
    db $e3
    ldh [rIE], a
    ret c

jr_051_708d:
    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    push hl
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    ld c, $01
    ld a, [$efef]
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and b
    and c
    and d
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    and e
    and h
    and l
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    add b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    inc h
    dec h
    ld h, $27
    jr z, @+$2b

    ld a, [hl+]
    dec hl
    inc l
    ld c, b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    dec l
    ld l, $2f
    jr nc, jr_051_7134

    ld [hl-], a
    inc sp
    inc [hl]
    dec [hl]
    ld c, c
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld [hl], $37
    jr c, jr_051_7157

    ld a, [hl-]
    dec sp
    inc a
    dec a
    ld a, $4a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

jr_051_7134:
    cp $e0
    ccf
    ld b, b
    ld b, c
    ld b, d
    ld b, e
    ld b, h
    ld b, l
    ld b, [hl]
    ld b, a
    ld c, e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    inc c
    ld bc, $effa
    rst $28
    rst $28
    rst $28

jr_051_7157:
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and [hl]
    and a
    xor b
    xor c
    xor d
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    adc c
    adc d
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ret nz

    nop
    ld a, [$efef]
    rst $28
    rst $28
    ei
    ret c

    cp $6c
    ld l, l
    ld l, [hl]
    ld l, a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    ld h, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add b
    adc c
    add d
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add h
    add d
    add [hl]
    add c
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add e
    adc d
    add l
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    sub d
    sub e
    sub h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    sbc e
    sbc h
    sbc l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
    and h
    and l
    and [hl]
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    and a
    xor b
    xor c
    xor d
    xor e
    xor h
    xor l
    xor [hl]
    xor a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


SaveBtlS_7247:
    push af
    ld a, l
    and $e0
    push af
    ld a, l
    inc a
    and $1f
    ld l, a
    pop af
    or l
    ld l, a
    pop af
    ret


LoadBtlS_7256:
    ld a, [$d9f8]
    add l
    ld l, a
    ld a, [$d9f9]
    adc h
    and $03
    ld h, a
    ld a, [$d9f9]
    and $fc
    or h
    ld h, a
    ret


LoadBtlS_726a:
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ret


SaveBtlS_7273:
    push bc
    ld b, l
    ld a, l
    and $e0
    ld l, a
    call LoadBtlS_7256
    ld a, b
    and $1f
    jr z, jr_051_7288

    ld b, a

jr_051_7282:
    call SaveBtlS_7247
    dec b
    jr nz, jr_051_7282

jr_051_7288:
    pop bc
    ret


    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    call SaveBtlS_7273
    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a

jr_051_729b:
    ld a, [de]
    inc de
    cp $d9
    ret z

    cp $d8
    jr nz, jr_051_72c4

    ld a, [$d9ea]
    ld l, a
    ld a, [$d9eb]
    ld h, a
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, h
    and $03
    or $98
    ld h, a
    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a
    jr jr_051_729b

jr_051_72c4:
    call Write_gfx_tile
    call SaveBtlS_7247
    jr jr_051_729b

LoadBtlS_72cc:
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    call LoadBtlS_726a
    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a

jr_051_72dd:
    ld a, [de]
    inc de
    cp $d9
    ret z

    cp $d8
    jr nz, jr_051_7300

    ld a, [$d9ea]
    ld l, a
    ld a, [$d9eb]
    ld h, a
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a
    jr jr_051_72dd

jr_051_7300:
    ld [hl+], a
    jr jr_051_72dd

    ld a, [$db74]
    ld c, a
    ld a, [$c863]
    bit 1, a
    jr z, jr_051_7312

    ld a, [$db75]
    ld c, a

jr_051_7312:
    push bc
    ld b, $25
    ld c, $62
    call BtlSFunc_7332
    pop bc
    dec c
    ret z

    push bc
    ld b, $2b
    ld c, $68
    call BtlSFunc_7332
    pop bc
    dec c
    ret z

    push bc
    ld b, $31
    ld c, $6e
    call BtlSFunc_7332
    pop bc
    ret


BtlSFunc_7332:
    ld l, b
    ld h, $98
    ld a, b
    ld de, $c500
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    call Write_gfx_tile
    ld b, $03
    ld l, c
    ld h, $98
    ld a, c
    ld de, $c500
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    call LoadBtlS_738e
    ld b, $03
    ld a, c
    add $20
    ld l, a
    ld h, $98
    ld de, $c500
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    call LoadBtlS_738e
    ret


ProcessBattleTurn:
    ld a, [$d9f8]
    ld l, a
    ld a, [$d9f9]
    ld h, a
    ld de, $c500
    ld c, $12

jr_051_7377:
    ld b, $20
    push hl
    call LoadBtlS_738e
    pop hl
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a
    pop bc
    dec c
    jr nz, jr_051_7377

    ret


LoadBtlS_738e:
jr_051_738e:
    ld a, [de]
    call Write_gfx_tile
    ld a, l
    and $e0
    push af
    ld a, l
    inc a
    and $1f
    ld l, a
    pop af
    or l
    ld l, a
    inc de
    dec b
    jr nz, jr_051_738e

    ret


LoadBtlS_73a3:
    ld a, [$c827]
    ld c, a
    ld a, [$c828]
    ld b, a
    push bc
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    push bc
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld hl, $4102
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ret


SaveBtlS_73dc:
    push hl
    ld hl, $c180
    call Copy4Bytes
    pop hl
    ld a, [$c827]
    ld c, a
    ld a, [$c828]
    ld b, a
    push bc
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    push bc
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld de, $0401
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $02
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4102
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ret


SetBtlS_742a:
    ld hl, $c500
    ld bc, $0240

jr_051_7430:
    ld a, $e0
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, jr_051_7430

    ret


SetBtlS_7439:
    ld hl, $9800
    ld bc, $0400

jr_051_743f:
    ld a, $e0
    call Write_gfx_tile_and_inc_HL
    dec bc
    ld a, b
    or c
    jr nz, jr_051_743f

    ret


LoadBtlS_744a:
    ld a, c
    ld [$c8e1], a
    inc de
    inc de
    ld a, [$c825]
    or a
    jp nz, Jump_051_74b1

    ld a, [wJoypad_Current]
    bit 5, a
    jr z, jr_051_7477

    inc hl
    ld a, [hl]
    dec a
    push af
    push de
    push bc
    ld a, b
    ld b, c
    dec b
    call Div8x8
    ld a, b
    inc a
    pop bc
    pop de
    ld c, a
    pop af
    cp c
    jr c, jr_051_7495

    ld a, c
    dec a
    jr jr_051_7495

jr_051_7477:
    ld a, [wJoypad_Current]
    bit 4, a
    jr z, jr_051_74b1

    inc hl
    ld a, [hl]
    inc a
    push af
    push de
    push bc
    ld a, b
    ld b, c
    dec b
    call Div8x8
    ld a, b
    inc a
    pop bc
    pop de
    ld c, a
    pop af
    cp c
    jr c, jr_051_7495

    ld a, $00

jr_051_7495:
    ld [hl-], a
    dec c
    cp c
    jr nz, jr_051_74f4

    ld a, [$c8e1]
    ld c, a
    push de
    push bc
    ld a, b
    ld b, c
    call Div8x8
    pop bc
    pop de
    or a
    jr z, jr_051_74f4

    dec a
    cp [hl]
    jr nc, jr_051_74f4

    ld [hl], a
    jr jr_051_74f4

Jump_051_74b1:
jr_051_74b1:
    push bc
    push de
    push hl
    call LoadBtlS_758c
    pop hl
    pop de
    pop bc
    push de
    push bc
    ld a, b
    ld b, c
    dec b
    call Div8x8
    ld [$c8e1], a
    ld a, b
    pop bc
    pop de
    ld c, a
    inc hl
    ld a, [hl-]
    cp c
    jr nz, jr_051_74d3

    ld a, [$c8e1]
    inc a
    ld b, a

BtlSFunc_74d3:
jr_051_74d3:
    res 7, [hl]
    ld a, [wJoypad_Current]
    bit 6, a
    jr z, jr_051_74e5

    ld a, [hl]
    dec a
    cp b
    jr c, jr_051_74f3

    dec b
    ld a, b
    jr jr_051_74f3

jr_051_74e5:
    ld a, [wJoypad_Current]
    bit 7, a
    jr z, jr_051_74fc

    ld a, [hl]
    inc a
    cp b
    jr c, jr_051_74f3

    ld a, $00

jr_051_74f3:
    ld [hl], a

jr_051_74f4:
    xor a
    ld [$d9fb], a
    push hl
    push de
    pop de
    pop hl

jr_051_74fc:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_051_7505

    set 7, [hl]

jr_051_7505:
    ld a, [hl]
    call BtlSFunc_7529
    ret


    res 7, [hl]
    ld a, [wJoypad_Current]
    and $c0
    jr z, jr_051_7518

    ld a, [hl]
    xor $01
    jr jr_051_74f3

jr_051_7518:
    ld a, [wJoypad_Current]
    and $30
    jr z, jr_051_74fc

    ld a, [hl]
    xor $02
    jr jr_051_74f3

ClrBtlS_7524:
    xor a
    ld [$d9fb], a
    ret


BtlSFunc_7529:
    ld c, a
    bit 7, a
    jr nz, jr_051_753e

    ld a, [$d9fb]
    and $0f
    push af
    ld a, [$d9fb]
    inc a
    ld [$d9fb], a
    pop af
    ld a, c
    ret nz

jr_051_753e:
    ld c, a
    ld b, $00

jr_051_7541:
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    and l
    cp $ff
    ret z

    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a
    push de
    push bc
    call SaveBtlS_7273
    pop bc
    pop de
    ld a, c
    and $7f
    cp b
    ld a, $e0
    jr nz, jr_051_7573

    ld a, $e9
    bit 7, c
    jr nz, jr_051_7573

    ld a, [$d9fb]
    bit 4, a
    ld a, $e0
    jr nz, jr_051_7573

    ld a, $e8

jr_051_7573:
    call Write_gfx_tile
    push af
    ld a, [$d9ea]
    ld l, a
    ld a, [$d9eb]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    inc b
    jr jr_051_7541

LoadBtlS_758c:
    ld a, b
    cp c
    ret nc

    inc hl
    ld c, [hl]
    dec de
    dec de
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    and l
    cp $ff
    ret z

    dec hl
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    push de
    push bc
    call SaveBtlS_7273
    pop bc
    pop de
    ld a, c
    and $7f
    add $f1
    call Write_gfx_tile
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    ret


ReadBtlS_75c5:
    ld a, [hl+]
    push af
    push hl
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    inc de
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ld a, b
    cp c
    ld a, $ee
    jr nc, jr_051_75de

    ld a, $e7

jr_051_75de:
    ld [hl-], a
    pop bc
    jr nc, jr_051_75e6

    ld a, [bc]
    add $f1
    ld [hl], a

jr_051_75e6:
    pop af

BtlSFunc_75e7:
    ld c, a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a
    push de
    push bc
    call SaveBtlS_7273
    pop bc
    pop de
    ld a, $e9
    bit 7, c
    jr nz, jr_051_7614

    ld a, [$d9fb]
    bit 4, a
    ld a, $e0
    jr nz, jr_051_7614

    ld a, $e8

jr_051_7614:
    push af
    ld a, [$d9ea]
    ld l, a
    ld a, [$d9eb]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    ret


LoadBtlS_7628:
    ld a, [$c86c]
    or a
    jr z, jr_051_763a

    ld a, [$c863]
    bit 1, a
    jr z, jr_051_763a

    ld a, [$db74]
    jr jr_051_763d

jr_051_763a:
    ld a, [$db75]

jr_051_763d:
    cp $03
    jr z, jr_051_765d

    cp $02
    jr z, jr_051_764e

    ld a, $00
    ld hl, $00c7
    call BtlSFunc_7672
    ret


jr_051_764e:
    ld a, $00
    ld hl, $00c4
    call BtlSFunc_7672
    ld hl, $00ca
    call BtlSFunc_7672
    ret


jr_051_765d:
    ld a, $00
    ld hl, $00c1
    call BtlSFunc_7672
    ld hl, $00c7
    call BtlSFunc_7672
    ld hl, $00cd
    call BtlSFunc_7672
    ret


BtlSFunc_7672:
    ld c, $06

jr_051_7674:
    push hl
    push af
    call LoadBtlS_726a
    pop af
    ld b, $06

jr_051_767c:
    ld [hl+], a
    inc a
    dec b
    jr nz, jr_051_767c

    pop hl
    ld de, $0020
    add hl, de
    dec c
    jr nz, jr_051_7674

    ret


SetBtlS_768a:
    ld de, $2e07
    call LoadBtlS_72cc
    ld a, [$d9f3]
    or a
    jp nz, Jump_051_7763

LoadBtlS_7697:
    ld a, [$c86c]
    or a
    jr nz, jr_051_76a2

    ld a, [$ca8d]
    or a
    ret z

jr_051_76a2:
    call SetBtlS_76a7
    jr jr_051_76c7

SetBtlS_76a7:
    ld hl, $775b
    ld a, [$c863]
    bit 1, a
    jr z, jr_051_76b6

    ld a, [$db75]
    jr jr_051_76b9

jr_051_76b6:
    ld a, [$db74]

jr_051_76b9:
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    call LoadBtlS_72cc
    ret


jr_051_76c7:
    ld hl, wBattleHP
    ld a, [$c863]
    bit 1, a
    jr z, jr_051_76d4

    ld hl, $dbab

jr_051_76d4:
    push hl
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $0062
    call LoadBtlS_726a
    call FillMemory
    pop hl
    ld bc, $0020
    add hl, bc
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $0082
    call LoadBtlS_726a
    call FillMemory
    ld a, [$c1d9]
    cp $01
    ret z

    ld hl, $dba5
    ld a, [$c863]
    bit 1, a
    jr z, jr_051_7705

    ld hl, $dbad

jr_051_7705:
    push hl
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $0068
    call LoadBtlS_726a
    call FillMemory
    pop hl
    ld bc, $0020
    add hl, bc
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $0088
    call LoadBtlS_726a
    call FillMemory
    ld a, [$c1d9]
    cp $02
    ret z

    ld hl, $dba7
    ld a, [$c863]
    bit 1, a
    jr z, jr_051_7736

    ld hl, $dbaf

jr_051_7736:
    push hl
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $006e
    call LoadBtlS_726a
    call FillMemory
    pop hl
    ld bc, $0020
    add hl, bc
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $008e
    call LoadBtlS_726a
    call FillMemory
    ret


    rst $00
    db $76
    ld a, [c]
    db $76
    inc hl
    ld [hl], a
    db $76
    ld l, e
    db $76
    ld l, e
    ld a, [de]
    ld l, e
    sbc d
    ld l, d

Jump_051_7763:
    cp $03
    jp z, Jump_051_786b

    call SetBtlS_76a7
    ld hl, $9800
    ld a, l
    ld [$d9f8], a
    ld a, h
    ld [$d9f9], a
    ld a, [$c1d9]
    ld b, a
    ld c, $00
    ld a, [$c863]
    bit 1, a
    jr z, jr_051_7785

    ld c, $04

jr_051_7785:
    ld hl, $78ca
    call $78e2
    push hl
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_051_7796

    ld a, $d9
    jr jr_051_7798

jr_051_7796:
    ld a, $e0

jr_051_7798:
    pop hl
    ld [hl], a
    ld hl, $78d0
    call $78e2
    ld [hl], $de
    inc hl
    ld a, $e4
    ld [hl-], a
    ld a, $20
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $e0
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    inc c
    dec b
    jr nz, jr_051_7785

    ld a, [$d9f3]
    cp $02
    jr z, jr_051_77e6

    call ProcessBattleTurn
    ld hl, $8da0
    ld a, $02
    call SaveBtlS_7906
    ld hl, $8db0
    ld a, $04
    call SaveBtlS_7906
    ld hl, $8dc0
    ld a, $06
    call SaveBtlS_7906
    ld hl, $8dd0
    ld a, $03
    call SaveBtlS_7906
    ld hl, $d9f3
    inc [hl]

jr_051_77e6:
    ld a, [$c1d9]
    ld b, a
    ld c, $00
    ld a, [$c863]
    bit 1, a
    jr z, jr_051_77f5

    ld c, $04

jr_051_77f5:
    ld hl, $78d0
    call $78e2
    inc hl
    inc hl
    push bc
    ld a, c
    ld bc, $db9b
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    ld a, [bc]
    ld c, a
    ld b, $00
    call CopyHLtoDE
    pop bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_051_7863

    ld hl, $78d6
    call $78e2
    push hl
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    pop de
    ld a, [hl]
    or a
    jr z, jr_051_7863

    bit 6, [hl]
    jr z, jr_051_7832

    ld a, $00
    call SaveBtlS_78f8

jr_051_7832:
    inc de
    bit 5, [hl]
    jr z, jr_051_783c

    ld a, $01
    call SaveBtlS_78f8

jr_051_783c:
    inc de
    bit 4, [hl]
    jr z, jr_051_7846

    ld a, $02
    call SaveBtlS_78f8

jr_051_7846:
    inc de
    bit 7, [hl]
    jr z, jr_051_7850

    ld a, $03
    call SaveBtlS_78f8

jr_051_7850:
    inc de
    bit 1, [hl]
    jr z, jr_051_785a

    ld a, $04
    call SaveBtlS_78f8

jr_051_785a:
    bit 0, [hl]
    jr z, jr_051_7863

    ld a, $05
    call SaveBtlS_78f8

jr_051_7863:
    inc c
    dec b
    jr nz, jr_051_77f5

    call ProcessBattleTurn
    ret


Jump_051_786b:
    ld a, [$c1d9]
    ld b, a
    ld c, $00
    ld a, [$c863]
    bit 1, a
    jr z, jr_051_787a

    ld c, $04

jr_051_787a:
    ld hl, $78ca
    call $78e2
    ld a, c
    and $03
    add $da
    ld [hl], a
    ld hl, $78d0
    call $78e2
    ld [hl], $e1
    ld a, $20
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $e2
    ld [hl+], a
    ld a, $e0
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ld a, c
    ld [wBattleAttackerIdx], a
    ld [wBattleTargetIdx], a
    push af
    push bc
    push de
    push hl
    ld hl, $da0a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $ff
    call LoadBtlS_7929
    pop hl
    pop de
    pop bc
    pop af
    inc c
    dec b
    jr nz, jr_051_787a

    xor a
    ld [$d9f3], a
    call LoadBtlS_7697
    call ProcessBattleTurn
    ret


    dec h
    nop
    dec hl
    nop
    ld sp, $6100
    nop
    ld h, a
    nop
    ld l, l
    nop
    add c
    nop
    add a
    nop
    adc l
    nop
    call c, $dbd7
    db $dd
    jp c, Jump_051_79d8

    and $03
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ret


SaveBtlS_78f8:
    push hl
    ld hl, $78dc
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [de], a
    pop hl
    ret


SaveBtlS_7906:
    push hl
    ld hl, $7919
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    pop hl
    call WaitDMATransfer
    ret


    ld [bc], a
    ld e, e
    inc bc
    ld e, e
    inc b
    ld e, e
    dec b
    ld e, e
    ld b, $5b
    rlca
    ld e, e
    ld [$095b], sp
    ld e, e

LoadBtlS_7929:
    ld a, [$c86c]
    or a
    jr z, jr_051_794f

    ld a, [$c863]
    bit 1, a
    jr z, jr_051_794f

    ld a, [wBattleTargetIdx]
    ld c, a
    cp $04
    jr c, jr_051_7943

    cp $07
    ret z

    jr jr_051_7960

jr_051_7943:
    ld a, [wBattleAttackerIdx]
    ld c, a
    cp $04
    ret c

    cp $07
    ret z

    jr jr_051_7960

jr_051_794f:
    ld a, [wBattleTargetIdx]
    ld c, a
    cp $03
    jr c, jr_051_7962

    ld a, [wBattleAttackerIdx]
    ld c, a
    cp $03
    jr c, jr_051_7962

    ret


jr_051_7960:
    xor $04

jr_051_7962:
    push de
    swap a
    ld hl, $8da0
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    ld a, c
    call CheckMonsterSlot
    jr c, jr_051_7998

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 6, [hl]
    jr nz, jr_051_799c

    bit 5, [hl]
    jr nz, jr_051_79a0

    bit 4, [hl]
    jr nz, jr_051_79a4

    bit 7, [hl]
    jr nz, jr_051_79a8

    bit 1, [hl]
    jr nz, jr_051_79ac

    bit 0, [hl]
    jr nz, jr_051_79b0

    ld a, $00
    jr jr_051_79b2

jr_051_7998:
    ld a, $07
    jr jr_051_79b2

jr_051_799c:
    ld a, $06
    jr jr_051_79b2

jr_051_79a0:
    ld a, $05
    jr jr_051_79b2

jr_051_79a4:
    ld a, $04
    jr jr_051_79b2

jr_051_79a8:
    ld a, $03
    jr jr_051_79b2

jr_051_79ac:
    ld a, $02
    jr jr_051_79b2

jr_051_79b0:
    ld a, $01

jr_051_79b2:
    push af
    ld a, c
    ld hl, $da0a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld d, [hl]
    pop af
    cp d
    call nz, WriteBtlS_79c9
    pop hl
    call nz, SaveBtlS_7906
    pop de
    ret


WriteBtlS_79c9:
    ld [hl], a
    ret


LoadBtlS_79cb:
    ld a, [wIsGBC]
    or a
    ret z

    ld a, $01
    ldh [rVBK], a
    ld a, [$d9f8]
    ld l, a

Jump_051_79d8:
    ld a, [$d9f9]
    ld h, a
    ld c, $12

jr_051_79de:
    ld b, $20
    push hl

jr_051_79e1:
    ld a, $00
    call Write_gfx_tile
    ld a, l
    and $e0
    push af
    ld a, l
    inc a
    and $1f
    ld l, a
    pop af
    or l
    ld l, a
    dec b
    jr nz, jr_051_79e1

    pop hl
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a
    pop bc
    dec c
    jr nz, jr_051_79de

    ld a, $00
    ldh [rVBK], a
    ret


CmpBtlS_7a0a:
    cp $03
    jr nc, jr_051_7a28

SaveBtlS_7a0e:
jr_051_7a0e:
    push hl
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    pop hl
    push hl
    call Copy4Bytes
    pop hl

jr_051_7a1d:
    ld a, [hl]
    cp $f0
    ret z

    inc hl
    jr jr_051_7a1d

jr_051_7a24:
    ld a, b
    pop bc
    jr jr_051_7a0e

jr_051_7a28:
    push bc
    ld b, a
    and $03
    cp $03
    ld a, b
    pop bc
    jr z, jr_051_7a51

    push bc
    ld b, a
    ld a, [$c86c]
    or a
    jr nz, jr_051_7a24

    push hl
    ld a, b
    and $03
    ld hl, $c1ca
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    pop hl
    cp $ff
    jr nz, jr_051_7a4e

    ld a, b

jr_051_7a4e:
    pop bc
    jr nz, jr_051_7a79

jr_051_7a51:
    push af
    call BtlSFunc_7a5b
    pop af
    ld hl, $5104
    rst $10
    ret


BtlSFunc_7a5b:
    ld [$db60], a
    push hl
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld l, a
    ld h, $05
    pop de
    ld a, e
    ld [$db5e], a
    ld a, d
    ld [$db5f], a
    call SetupVRAMParams
    ret


jr_051_7a79:
    call SaveBtlS_7a0e
    ld a, $2f
    ld [hl+], a
    ld a, $46
    ld [hl+], a
    ld a, $48
    ld [hl+], a
    ld a, $42
    ld [hl+], a
    ld [hl], $f0
    push hl
    ld hl, $c1ca
    ld a, [$db50]
    and $03
    cp $01
    jr z, jr_051_7aa5

    cp $02
    jr z, jr_051_7aaf

    ld a, [hl+]
    cp [hl]
    jr z, jr_051_7acb

    inc hl
    cp [hl]
    jr z, jr_051_7acb

    jr jr_051_7ada

jr_051_7aa5:
    ld a, [hl+]
    cp [hl]
    jr z, jr_051_7ad0

    ld a, [hl+]
    cp [hl]
    jr z, jr_051_7acb

    jr jr_051_7ada

jr_051_7aaf:
    ld d, $00
    inc hl
    inc hl
    ld a, [hl-]
    dec hl
    cp [hl]
    jr nz, jr_051_7ab9

    inc d

jr_051_7ab9:
    inc hl
    cp [hl]
    jr nz, jr_051_7abe

    inc d

jr_051_7abe:
    ld a, d
    or a
    jr z, jr_051_7ada

    cp $01
    jr z, jr_051_7ad0

    pop hl
    ld a, $03
    jr jr_051_7ad3

jr_051_7acb:
    pop hl
    ld a, $01
    jr jr_051_7ad3

jr_051_7ad0:
    pop hl
    ld a, $02

jr_051_7ad3:
    ld [$db4d], a
    ld [hl+], a
    ld [hl], $f0
    ret


jr_051_7ada:
    pop hl
    xor a
    ld [$db4d], a
    ret


    ld hl, $c1a0
    jr jr_051_7ae8

    ld hl, $c180

jr_051_7ae8:
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleTargetIdx]
    ld [$db50], a
    call CmpBtlS_7a0a
    ret


    ld hl, $c180
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleAttackerIdx]
    ld [$db50], a
    call CmpBtlS_7a0a
    ret


    jr nc, jr_051_7b11

jr_051_7b11:
    ld bc, $82ff
    ld bc, $0700
    ld a, h
    rst $38
    ld bc, $f0ff
    jp nz, $a2ff

    rst $38
    sub d
    rst $38
    adc d
    rst $38
    add [hl]
    rst $38
    add d
    rst $38
    nop
    rst $38
    jr c, @+$01

    ld b, h
    ld bc, $0300
    ld b, h
    rst $38
    jr c, @+$01

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
