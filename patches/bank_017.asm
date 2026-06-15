; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $017", ROMX[$4000], BANK[$17]

    db $17 ;ROM BANK

    dw label17_401d
    dw label17_409e
    dw label17_41c0
    dw label17_4272
    dw label17_4410
    dw label17_4478
    dw label17_41d0
    dw label17_41f2
    dw label17_46dd
    dw Jump_017_4102
    dw label17_4192
    dw label17_4712
    dw label17_4733
    dw label17_4751


label17_401d:
    ld a, [wIsGBC]
    or a
    ret z

    ld a, [wInGateworld]
    or a
    jp nz, Jump_017_4064

    ld hl, AttrPtrTable
    call MapIDClampForPalette   ; ROM0 helper: clamps mapID for custom rooms
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [wScreenIndex]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    inc hl
    ld a, [de]
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld c, $00
    ld b, $04
    call CustomPalCheck         ; intercept: custom rooms → merged palette colors
    jp Jump_017_4102


Jump_017_4064:
    ld de, GateAttrTable_A
    ld a, [$c93f]
    cp $02
    jr nz, jr_017_4071

    ld de, GateAttrTable_B

jr_017_4071:
    ld a, [wScreenIndex]
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $00
    add hl, hl
    add hl, de
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld hl, $51f5
    ld a, [wMapID]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld c, $00
    ld b, $04
    call LoadPal_46a1
    jr jr_017_4102


label17_409e:
    ld a, [wInGateworld]
    or a
    jp nz, Jump_017_40da

    ld hl, AttrPtrTable
    call CustomAttrCheck        ; intercept: custom rooms → bank $64 attr data
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [wScreenIndex]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    inc hl
    ld a, [de]
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    inc hl
    ld hl, $c200
    call WaitLCDTransfer
    ret


Jump_017_40da:
    ld de, GateAttrTable_A
    ld a, [$c93f]
    cp $02
    jr nz, jr_017_40e7

    ld de, GateAttrTable_B

jr_017_40e7:
    ld a, [wScreenIndex]
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $00
    add hl, hl
    add hl, de
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld hl, $c200
    call WaitLCDTransfer
    ret


LoadPal_4102:
Jump_017_4102:
jr_017_4102:
    ld a, [wIsGBC]
    or a
    ret z

    ld hl, $5655
    ld c, $07
    ld b, $01
    call CustomPalCheck         ; intercept: custom rooms skip slot 7 overwrite
    ld a, [$c7d1]
    ld l, a
    ld a, [$c7d2]
    ld h, a
    ld a, l
    ld [$c799], a
    ld a, h
    ld [$c79a], a
    ld a, l
    ld [$c7a1], a
    ld a, h
    ld [$c7a2], a
    ld a, l
    ld [$c7a9], a
    ld a, h
    ld [$c7aa], a
    ld a, l
    ld [$c7b1], a
    ld a, h
    ld [$c7b2], a
    ld a, l
    ld [$c7b9], a
    ld a, h
    ld [$c7ba], a
    ld a, l
    ld [$c7c1], a
    ld a, h
    ld [$c7c2], a
    ld a, l
    ld [$c7c9], a
    ld a, h
    ld [$c7ca], a
    ld a, [$c7d5]
    ld l, a
    ld a, [$c7d6]
    ld h, a
    ld a, l
    ld [$c79d], a
    ld a, h
    ld [$c79e], a
    ld a, l
    ld [$c7a5], a
    ld a, h
    ld [$c7a6], a
    ld a, l
    ld [$c7ad], a
    ld a, h
    ld [$c7ae], a
    ld a, l
    ld [$c7b5], a
    ld a, h
    ld [$c7b6], a
    ld a, l
    ld [$c7bd], a
    ld a, h
    ld [$c7be], a
    ld a, l
    ld [$c7c5], a
    ld a, h
    ld [$c7c6], a
    ld a, l
    ld [$c7cd], a
    ld a, h
    ld [$c7ce], a
    ret

label17_4192:
    ld a, [wIsGBC]
    or a
    ret z

    di
    call WaitVRAM
    ld a, $01
    ldh [rVBK], a
    ei
    ld b, $00
    ld hl, $9800

jr_017_41a5:
    ld a, $07
    call Write_gfx_tile_and_inc_HL
    call Write_gfx_tile_and_inc_HL
    call Write_gfx_tile_and_inc_HL
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_017_41a5

    di
    call WaitVRAM
    ld a, $00
    ldh [rVBK], a
    ei
    ret

label17_41c0:
    ld a, [wIsGBC]
    or a
    ret z

    ld hl, $5615
    ld c, $00
    ld b, $08
    call LoadPal_46bf
    ret

label17_41d0:
    ld a, [wIsGBC]
    or a
    ret z

    ld a, [$c81e]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, l
    add LOW(RoomAttrDataBlocks)
    ld l, a
    ld a, h
    adc HIGH(RoomAttrDataBlocks)
    ld h, a
    ld a, [$c81f]
    ld c, a
    ld b, $01
    call LoadPal_46a1
    call LoadPal_4102

label17_41f2:
    ld a, [wIsGBC]
    or a
    ret z

    ldh a, [$bb]
    and $f8
    ld l, a
    xor a
    sla l
    rla
    sla l
    rla
    ld h, $98
    add h
    ld h, a
    ldh a, [$b7]
    rrca
    rrca
    rrca
    and $1f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$c820]
    ld c, a
    ld a, [$c821]
    ld b, a
    ld a, c
    and $e0
    ld c, a
    add hl, bc
    res 2, h
    ld a, [$c820]
    and $1f
    ld b, a

jr_017_4229:
    call LoadPal_4265
    dec b
    jr nz, jr_017_4229

    di
    call WaitVRAM
    ld a, $01
    ldh [rVBK], a
    ei
    ld c, $06

jr_017_423a:
    ld b, $06
    push hl

jr_017_423d:
    ld a, [$c81f]
    call Write_gfx_tile
    call LoadPal_4265
    dec b
    jr nz, jr_017_423d

    pop hl
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
    dec c
    jr nz, jr_017_423a

    di
    call WaitVRAM
    ld a, $00
    ldh [rVBK], a
    ei
    ret


LoadPal_4265:
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
    ret

label17_4272:
    ld a, [wIsGBC]
    or a
    ret z

    ld hl, $c89e
    ld a, [wBGPalette]
    cp [hl]
    jp z, Jump_017_4341

    call WaitVRAM
    ld a, $80
    ldh [rBCPS], a
    ld hl, $c797
    call SavePal_42ac
    call SavePal_42ac
    call SavePal_42ac
    call SavePal_42ac
    call SavePal_42ac
    call SavePal_42ac
    call SavePal_42ac
    call SavePal_42ac
    ld a, [wBGPalette]
    ld [$c89e], a
    jp Jump_017_4341


SavePal_42ac:
    push hl
    ld a, [wBGPalette]
    and $03
    ld de, $440c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call WaitVRAM
    ld a, [hl+]
    ldh [rBCPD], a
    ld a, [hl]
    ldh [rBCPD], a
    pop hl
    push hl
    ld a, [wBGPalette]
    srl a
    srl a
    and $03
    ld de, $440c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call WaitVRAM
    ld a, [hl+]
    ldh [rBCPD], a
    ld a, [hl]
    ldh [rBCPD], a
    pop hl
    push hl
    ld a, [wBGPalette]
    swap a
    and $03
    ld de, $440c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call WaitVRAM
    ld a, [hl+]
    ldh [rBCPD], a
    ld a, [hl]
    ldh [rBCPD], a
    pop hl
    push hl
    ld a, [wBGPalette]
    swap a
    srl a
    srl a
    and $03
    ld de, $440c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call WaitVRAM
    ld a, [hl+]
    ldh [rBCPD], a
    ld a, [hl]
    ldh [rBCPD], a
    pop hl
    ld a, l
    add $08
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ret


Jump_017_4341:
    ld hl, $c89f
    ld a, [wObj1Palette]
    cp [hl]
    jp z, Jump_017_440b

    call WaitVRAM
    ld a, $80
    ldh [rOCPS], a
    ld hl, $c7d7
    call SavePal_4376
    call SavePal_4376
    call SavePal_4376
    call SavePal_4376
    call SavePal_4376
    call SavePal_4376
    call SavePal_4376
    call SavePal_4376
    ld a, [wObj1Palette]
    ld [$c89f], a
    jp Jump_017_440b


SavePal_4376:
    push hl
    ld a, [wObj1Palette]
    and $03
    ld de, $440c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call WaitVRAM
    ld a, [hl+]
    ldh [rOCPD], a
    ld a, [hl]
    ldh [rOCPD], a
    pop hl
    push hl
    ld a, [wObj1Palette]
    srl a
    srl a
    and $03
    ld de, $440c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call WaitVRAM
    ld a, [hl+]
    ldh [rOCPD], a
    ld a, [hl]
    ldh [rOCPD], a
    pop hl
    push hl
    ld a, [wObj1Palette]
    swap a
    and $03
    ld de, $440c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call WaitVRAM
    ld a, [hl+]
    ldh [rOCPD], a
    ld a, [hl]
    ldh [rOCPD], a
    pop hl
    push hl
    ld a, [wObj1Palette]
    swap a
    srl a
    srl a
    and $03
    ld de, $440c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call WaitVRAM
    ld a, [hl+]
    ldh [rOCPD], a
    ld a, [hl]
    ldh [rOCPD], a
    pop hl
    ld a, l
    add $08
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ret


Jump_017_440b:
    ret


    db $02, $04, $00, $06

label17_4410:
    ld a, [$c850]
    ld b, a
    bit 7, b
    jr nz, jr_017_442e

    ld a, $00
    ld [$c856], a
    ld a, [$c850]
    srl a
    srl a
    ld [$c857], a
    ld [$c858], a
    call CheckAnimBusy
    ret


jr_017_442e:
    ld a, $20
    ld [$c856], a
    ld a, [$c850]
    cpl
    srl a
    srl a
    ld [$c857], a
    ld [$c858], a
    di
    call WaitVRAM
    ld a, $80
    ldh [rBCPS], a
    ei
    ld b, $20

jr_017_444c:
    di
    call WaitVRAM
    ld a, $ff
    ldh [rBCPD], a
    ld a, $7f
    ldh [rBCPD], a
    ei
    dec b
    jr nz, jr_017_444c

    di
    call WaitVRAM
    ld a, $80
    ldh [rOCPS], a
    ei
    ld b, $20

jr_017_4467:
    di
    call WaitVRAM
    ld a, $ff
    ldh [rOCPD], a
    ld a, $7f
    ldh [rOCPD], a
    ei
    dec b
    jr nz, jr_017_4467

    ret

label17_4478:
    ld a, [$c850]
    bit 7, a
    jr nz, jr_017_44aa

    ld a, [$c858]
    or a
    jr z, jr_017_448a

    dec a
    ld [$c858], a
    ret


jr_017_448a:
    ld a, [$c856]
    add $05
    cp $1f
    jr c, jr_017_4495

    ld a, $1f

jr_017_4495:
    ld [$c856], a
    call IntPal_44d8
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    cp $1f
    jp z, Jump_017_44d3

    ret


jr_017_44aa:
    ld a, [$c858]
    or a
    jr z, jr_017_44b5

    dec a
    ld [$c858], a
    ret


jr_017_44b5:
    ld a, [$c856]
    sub $05
    bit 7, a
    jr z, jr_017_44bf

    xor a

jr_017_44bf:
    ld [$c856], a
    call IntPal_45bb
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    or a
    jp z, Jump_017_44d3

    ret


Jump_017_44d3:
    xor a
    ld [$c850], a
    ret


IntPal_44d8:
    di
    call WaitVRAM
    ld a, $80
    ldh [rBCPS], a
    ei
    ld hl, $c797
    call CallPal_4552
    call CallPal_4552
    call CallPal_4552
    call CallPal_4552
    call CallPal_4552
    call CallPal_4552
    call CallPal_4552
    call CallPal_4552
    di
    call WaitVRAM
    ld a, $80
    ldh [rOCPS], a
    ei
    ld hl, $c7d7
    call CallPal_4521
    call CallPal_4521
    call CallPal_4521
    call CallPal_4521
    call CallPal_4521
    call CallPal_4521
    call CallPal_4521
    call CallPal_4521
    ret


CallPal_4521:
    call LoadPal_452a
    call LoadPal_452a
    call LoadPal_452a

LoadPal_452a:
    ld a, [$c856]
    ld d, a
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    ld de, $0000
    call SavePal_457f
    call SavePal_457f
    call SavePal_457f
    rr b
    rr c
    rr d
    rr e
    di
    call WaitVRAM
    ld a, e
    ldh [rOCPD], a
    ld a, d
    ldh [rOCPD], a
    ei
    ret


CallPal_4552:
    call FuncPal_455b
    call FuncPal_455b
    call FuncPal_455b

FuncPal_455b:
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    ld de, $0000
    call SavePal_457f
    call SavePal_457f
    call SavePal_457f
    rr b
    rr c
    rr d
    rr e
    di
    call WaitVRAM
    ld a, e
    ldh [rBCPD], a
    ld a, d
    ldh [rBCPD], a
    ei
    ret


SavePal_457f:
    push de
    ld a, c
    and $1f
    ld d, a
    ld a, [$c856]
    cp d
    jr nc, jr_017_458b

    ld a, d

jr_017_458b:
    ld e, a
    ld a, c
    and $e0
    or e
    ld c, a
    pop de
    rr b
    rr c
    rr d
    rr e
    rr b
    rr c
    rr d
    rr e
    rr b
    rr c
    rr d
    rr e
    rr b
    rr c
    rr d
    rr e
    rr b
    rr c
    rr d
    rr e
    ret


IntPal_45bb:
    di
    call WaitVRAM
    ld a, $80
    ldh [rBCPS], a
    ei
    ld hl, $c797
    call CallPal_4635
    call CallPal_4635
    call CallPal_4635
    call CallPal_4635
    call CallPal_4635
    call CallPal_4635
    call CallPal_4635
    call CallPal_4635
    di
    call WaitVRAM
    ld a, $80
    ldh [rOCPS], a
    ei
    ld hl, $c7d7
    call CallPal_4604
    call CallPal_4604
    call CallPal_4604
    call CallPal_4604
    call CallPal_4604
    call CallPal_4604
    call CallPal_4604
    call CallPal_4604
    ret


CallPal_4604:
    call LoadPal_460d
    call LoadPal_460d
    call LoadPal_460d

LoadPal_460d:
    ld a, [$c856]
    ld d, a
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    ld de, $0000
    call SavePal_4662
    call SavePal_4662
    call SavePal_4662
    rr b
    rr c
    rr d
    rr e
    di
    call WaitVRAM
    ld a, e
    ldh [rOCPD], a
    ld a, d
    ldh [rOCPD], a
    ei
    ret


CallPal_4635:
    call FuncPal_463e
    call FuncPal_463e
    call FuncPal_463e

FuncPal_463e:
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    ld de, $0000
    call SavePal_4662
    call SavePal_4662
    call SavePal_4662
    rr b
    rr c
    rr d
    rr e
    di
    call WaitVRAM
    ld a, e
    ldh [rBCPD], a
    ld a, d
    ldh [rBCPD], a
    ei
    ret


SavePal_4662:
    push de
    ld a, c
    and $1f
    ld d, a
    ld a, [$c856]
    add d
    cp $1f
    jr c, jr_017_4671

    ld a, $1f

jr_017_4671:
    ld e, a
    ld a, c
    and $e0
    or e
    ld c, a
    pop de
    rr b
    rr c
    rr d
    rr e
    rr b
    rr c
    rr d
    rr e
    rr b
    rr c
    rr d
    rr e
    rr b
    rr c
    rr d
    rr e
    rr b
    rr c
    rr d
    rr e
    ret


LoadPal_46a1:
    ld a, [wIsGBC]
    or a
    ret z

    ld a, b
    add a
    add a
    add a
    ld b, a
    ld a, c
    add a
    add a
    add a
    ld de, $c797
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a

jr_017_46b8:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_017_46b8

    ret


LoadPal_46bf:
    ld a, [wIsGBC]
    or a
    ret z

    ld a, b
    add a
    add a
    add a
    ld b, a
    ld a, c
    add a
    add a
    add a
    ld de, $c7d7
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a

jr_017_46d6:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_017_46d6

    ret

label17_46dd:
    ld a, [wIsGBC]
    or a
    ret z

    di
    call WaitVRAM
    ld a, $80
    ldh [rBCPS], a
    ei
    ld hl, $c797
    ld b, $40

jr_017_46f0:
    di
    call WaitVRAM
    ld a, [hl+]
    ldh [rBCPD], a
    ei
    dec b
    jr nz, jr_017_46f0

    di
    call WaitVRAM
    ld a, $80
    ldh [rOCPS], a
    ei
    ld b, $40

jr_017_4706:
    di
    call WaitVRAM
    ld a, [hl+]
    ldh [rOCPD], a
    ei
    dec b
    jr nz, jr_017_4706

    ret


label17_4712:
    ld a, [wIsGBC]
    or a
    ret z

    ld a, [$c81e]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, l
    add LOW(PaletteColorData)
    ld l, a
    ld a, h
    adc HIGH(PaletteColorData)
    ld h, a
    ld c, $00
    ld b, $08
    call LoadPal_46a1
    ret

label17_4733:
    ld a, [wIsGBC]
    or a
    ret z

    ld a, [$c81e]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, l
    add LOW(AttrMapData)
    ld l, a
    ld a, h
    adc HIGH(AttrMapData)
    ld h, a
    ld c, $00
    ld b, $01
    call LoadPal_46bf
    ret


label17_4751:
    ld a, [wIsGBC]
    or a
    ret z

    ld a, [$c81e]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, l
    add LOW(AttrMapDataB)
    ld l, a
    ld a, h
    adc HIGH(AttrMapDataB)
    ld h, a
    ld c, $00
    ld b, $01
    call LoadPal_46bf
    ret



; =============================================================================
; ATTRIBUTE DATA SECTION ($476F - $7FFF)
; =============================================================================
;
; Room attribute lookup: AttrPtrTable[mapID×2] → per-room screen table
;   Screen table[screen×2] → per-screen entry
;   Entry: [ram_addr:2] + step × [attr_idx:1, attr_bank:1, pal_ptr:2]
;
; Gate attr tables: $5215 (table A) and $5415 (table B)
;   Indexed by $C940[screen_index], entries are [attr_idx, attr_bank]

AttrPtrTable:  ; $476F — 107 entries × 2B, indexed by wMapID
    dw RoomAttr_Castle  ; $00 Castle
    dw RoomAttr_GreatTree  ; $01 GreatTree
    dw RoomAttr_Bazaar  ; $02 Bazaar
    dw RoomAttr_GateHub  ; $03 GateHub
    dw RoomAttr_Farm  ; $04 Farm
    dw RoomAttr_Stable  ; $05 Stable
    dw RoomAttr_ArenaLobby  ; $06 ArenaLobby
    dw RoomAttr_ArenaRooms  ; $07 ArenaRooms
    dw RoomAttr_Gate_08  ; $08 Gate_08
    dw RoomAttr_StarryShrine  ; $09 StarryShrine
    dw RoomAttr_SecretPassage  ; $0A SecretPassage
    dw $483F  ; $0B 
    dw RoomAttr_Gate_0C  ; $0C Gate_0C
    dw RoomAttr_OldManGate  ; $0D OldManGate
    dw $483F  ; $0E 
    dw RoomAttr_Room_0F  ; $0F 
    dw RoomAttr_CopycatRoom  ; $10 CopycatRoom
    dw $483F  ; $11 
    dw RoomAttr_Library  ; $12 Library
    dw RoomAttr_Room_13  ; $13 
    dw $483F  ; $14 
    dw $483F  ; $15 
    dw RoomAttr_MedalManRoom  ; $16 MedalManRoom
    dw $4B95  ; $17 
    dw RoomAttr_Well  ; $18 Well
    dw RoomAttr_Map19  ; $19 
    dw RoomAttr_Map1A  ; $1A 
    dw RoomAttr_Map1B  ; $1B 
    dw RoomAttr_Map1C  ; $1C 
    dw RoomAttr_Map1D  ; $1D 
    dw RoomAttr_Map1E  ; $1E 
    dw RoomAttr_Map1F  ; $1F 
    dw $483F  ; $20 
    dw $483F  ; $21 
    dw $483F  ; $22 
    dw RoomAttr_BossRoom_Beginning  ; $23 
    dw RoomAttr_BossRoom_VilTalis  ; $24 
    dw RoomAttr_BossRoom_MemBewil  ; $25 
    dw RoomAttr_BossRoom_PeaceBrave  ; $26 
    dw RoomAttr_Map27  ; $27 
    dw RoomAttr_Map28  ; $28 
    dw RoomAttr_Map29  ; $29 
    dw RoomAttr_Map2A  ; $2A 
    dw RoomAttr_Map2B  ; $2B 
    dw RoomAttr_Map2C  ; $2C 
    dw RoomAttr_Map2D  ; $2D 
    dw RoomAttr_Map2E  ; $2E 
    dw RoomAttr_Map2F  ; $2F Room_2F
    dw RoomAttr_Boss_Beginning  ; $30 
    dw RoomAttr_Boss_Villager  ; $31 
    dw RoomAttr_Boss_Talisman  ; $32 
    dw RoomAttr_Boss_Memories  ; $33 
    dw RoomAttr_Map34  ; $34 
    dw RoomAttr_Map35  ; $35 
    dw RoomAttr_Map36  ; $36 
    dw RoomAttr_Map37  ; $37 
    dw RoomAttr_Map38  ; $38 
    dw RoomAttr_Map39  ; $39 
    dw RoomAttr_Map3A  ; $3A 
    dw RoomAttr_Map3B  ; $3B 
    dw RoomAttr_Map3C  ; $3C 
    dw RoomAttr_Map3D  ; $3D 
    dw RoomAttr_Map3E  ; $3E 
    dw RoomAttr_Map3F  ; $3F 
    dw RoomAttr_Map40  ; $40 
    dw RoomAttr_Map41  ; $41 
    dw RoomAttr_Labyrinth  ; $42 Labyrinth
    dw RoomAttr_Map43  ; $43 
    dw RoomAttr_Map44  ; $44 
    dw RoomAttr_Map45  ; $45 
    dw RoomAttr_Map46  ; $46 
    dw RoomAttr_Map47  ; $47 
    dw RoomAttr_Map48  ; $48 
    dw RoomAttr_Map49  ; $49 
    dw RoomAttr_Map4A  ; $4A 
    dw RoomAttr_Map4B  ; $4B 
    dw RoomAttr_Map4C  ; $4C 
    dw RoomAttr_Map4D  ; $4D 
    dw RoomAttr_Map4E  ; $4E 
    dw RoomAttr_Map4F  ; $4F 
    dw RoomAttr_Map50  ; $50 
    dw RoomAttr_Map51  ; $51 
    dw RoomAttr_Map52  ; $52 
    dw RoomAttr_Map53  ; $53 
    dw RoomAttr_Map54  ; $54 
    dw RoomAttr_Map55  ; $55 
    dw RoomAttr_Map56  ; $56 
    dw RoomAttr_Map57  ; $57 
    dw RoomAttr_Map58  ; $58 
    dw RoomAttr_Map59  ; $59 
    dw RoomAttr_Map5A  ; $5A 
    dw RoomAttr_Map5B  ; $5B 
    dw RoomAttr_Map5C  ; $5C 
    dw RoomAttr_ArenaBattle  ; $5D ArenaBattle
    dw RoomAttr_Map5E  ; $5E Room_5E
    dw $4F3D  ; $5F 
    dw RoomAttr_LabyrinthBoss  ; $60 LabyrinthFinal
    dw RoomAttr_Map61  ; $61 
    dw RoomAttr_Map62  ; $62 
    dw RoomAttr_Map63  ; $63 
    dw RoomAttr_Map64  ; $64 
    dw $4E4F  ; $65 
    dw $4E4F  ; $66 
    dw $4E4F  ; $67 
RoomAttr_Castle: ; $483F — Castle screen table (overlaps AttrPtrTable entries $68-$6A)
    dw RoomAttr_Map68  ; $68 
    dw RoomAttr_Map69  ; $69 
    dw $FFFF  ; $6A  (invalid)

; --- Per-room screen/step attribute entries ($4845-$5214, 2512 bytes) ---
; Labels mark the start of each room's attribute data block.
; Each block: screen table (pointer pairs) + per-screen attribute entries.
; Attr entry: [wram_addr:2] + steps * [attr_idx:1, attr_bank:1, pal_ptr:2]
    db $ff, $ff, $ff, $ff, $87, $48, $ff, $ff, $ff, $ff
RoomAttr_Map68:
    db $2a, $d9, $00, $3c, $5d, $56, $01, $3c, $5d, $56, $02, $3c, $5d, $56, $03, $3c
    db $5d, $56
RoomAttr_Map69:
    db $2b, $d9, $04, $3c, $5d, $56, $05, $3c, $5d, $56, $05, $3c, $5d, $56, $05, $3c
    db $5d, $56, $05, $3c, $5d, $56, $05, $3c, $5d, $56, $04, $3c, $5d, $56, $04, $3c
    db $5d, $56, $04, $3c, $5d, $56, $2c, $d9, $06, $3c, $5d, $56, $06, $3c, $5d, $56
    db $06, $3c, $5d, $56, $06, $3c, $5d, $56, $06, $3c, $5d, $56
RoomAttr_GreatTree:
    db $bd, $48, $d3, $48, $ff, $ff, $ff, $ff, $d9, $48, $eb, $48, $ff, $ff, $ff, $ff
    db $f1, $48, $ff, $48, $ff, $ff, $ff, $ff, $05, $49, $17, $49, $ff, $ff, $ff, $ff
    db $2d, $d9, $07, $3c, $7d, $56, $07, $3c, $7d, $56, $07, $3c, $7d, $56, $07, $3c
    db $7d, $56, $07, $3c, $7d, $56, $2e, $d9, $08, $3c, $7d, $56, $2f, $d9, $09, $3c
    db $7d, $56, $09, $3c, $7d, $56, $09, $3c, $7d, $56, $09, $3c, $7d, $56, $30, $d9
    db $0a, $3c, $7d, $56, $31, $d9, $0b, $3c, $7d, $56, $0b, $3c, $7d, $56, $0b, $3c
    db $7d, $56, $32, $d9, $0c, $3c, $7d, $56, $33, $d9, $0d, $3c, $7d, $56, $0d, $3c
    db $7d, $56, $0e, $3c, $7d, $56, $0e, $3c, $7d, $56, $34, $d9, $0f, $3c, $7d, $56
    db $10, $3c, $7d, $56, $11, $3c, $7d, $56
RoomAttr_Bazaar:
    db $35, $49, $3f, $49, $4d, $49, $ff, $ff, $5b, $49, $69, $49, $77, $49, $ff, $ff
    db $35, $d9, $12, $3c, $9d, $56, $12, $3c, $9d, $56, $36, $d9, $13, $3c, $9d, $56
    db $13, $3c, $9d, $56, $13, $3c, $9d, $56, $37, $d9, $14, $3c, $9d, $56, $15, $3c
    db $9d, $56, $15, $3c, $9d, $56, $38, $d9, $16, $3c, $9d, $56, $17, $3c, $9d, $56
    db $16, $3c, $9d, $56, $39, $d9, $18, $3c, $9d, $56, $19, $3c, $9d, $56, $19, $3c
    db $9d, $56, $3a, $d9, $1a, $3c, $9d, $56, $1b, $3c, $9d, $56, $1b, $3c, $9d, $56
    db $1c, $3c, $9d, $56, $1c, $3c, $9d, $56, $1d, $3c, $9d, $56, $1d, $3c, $9d, $56
    db $1d, $3c, $9d, $56, $1d, $3c, $9d, $56
RoomAttr_GateHub:
    db $ad, $49, $bf, $49, $ff, $ff, $ff, $ff, $d5, $49, $eb, $49, $ff, $ff, $ff, $ff
    db $3b, $d9, $1e, $3c, $bd, $56, $1f, $3c, $bd, $56, $20, $3c, $bd, $56, $21, $3c
    db $bd, $56, $3c, $d9, $22, $3c, $bd, $56, $23, $3c, $bd, $56, $23, $3c, $bd, $56
    db $24, $3c, $bd, $56, $25, $3c, $bd, $56, $3d, $d9, $26, $3c, $bd, $56, $27, $3c
    db $bd, $56, $28, $3c, $bd, $56, $29, $3c, $bd, $56, $29, $3c, $bd, $56, $3e, $d9
    db $2a, $3c, $bd, $56, $2b, $3c, $bd, $56
RoomAttr_Farm:
    db $05, $4a, $17, $4a, $25, $4a, $ff, $ff, $3b, $4a, $4d, $4a, $5b, $4a, $ff, $ff
    db $3f, $d9, $2c, $3c, $dd, $56, $2c, $3c, $dd, $56, $2c, $3c, $dd, $56, $2c, $3c
    db $dd, $56, $40, $d9, $2d, $3c, $dd, $56, $2d, $3c, $dd, $56, $2d, $3c, $dd, $56
    db $41, $d9, $2e, $3c, $dd, $56, $2e, $3c, $dd, $56, $2f, $3c, $dd, $56, $2f, $3c
    db $dd, $56, $2f, $3c, $dd, $56, $42, $d9, $30, $3c, $dd, $56, $30, $3c, $dd, $56
    db $30, $3c, $dd, $56, $30, $3c, $dd, $56, $43, $d9, $31, $3c, $dd, $56, $31, $3c
    db $dd, $56, $31, $3c, $dd, $56, $44, $d9, $32, $3c, $dd, $56, $32, $3c, $dd, $56
    db $32, $3c, $dd, $56, $32, $3c, $dd, $56
RoomAttr_Stable:
    db $73, $4a, $7d, $4a, $87, $4a, $45, $d9, $33, $3c, $fd, $56, $34, $3c, $fd, $56
    db $46, $d9, $35, $3c, $fd, $56, $35, $3c, $fd, $56, $47, $d9, $36, $3c, $fd, $56
    db $36, $3c, $fd, $56, $36, $3c, $fd, $56, $36, $3c, $fd, $56
RoomAttr_ArenaLobby:
    db $a1, $4a, $a7, $4a, $ad, $4a, $ff, $ff, $48, $d9, $37, $3c, $1d, $57, $49, $d9
    db $38, $3c, $1d, $57, $4a, $d9, $39, $3c, $1d, $57
RoomAttr_ArenaRooms:
    db $c3, $4a, $c9, $4a, $eb, $4a, $ff, $ff, $f1, $4a, $fb, $4a, $01, $4b, $ff, $ff
    db $4b, $d9, $3a, $3c, $3d, $57, $4c, $d9, $3b, $3c, $3d, $57, $3c, $3c, $3d, $57
    db $3d, $3c, $3d, $57, $3d, $3c, $3d, $57, $3e, $3c, $3d, $57, $3e, $3c, $3d, $57
    db $3e, $3c, $3d, $57, $3e, $3c, $3d, $57, $4d, $d9, $3f, $3c, $3d, $57, $4e, $d9
    db $40, $3c, $3d, $57, $40, $3c, $3d, $57, $4f, $d9, $41, $3c, $3d, $57, $50, $d9
    db $42, $3c, $3d, $57
RoomAttr_Gate_08:
    db $09, $4b, $51, $d9, $43, $3c, $5d, $57, $43, $3c, $5d, $57, $43, $3c, $5d, $57
    db $43, $3c, $5d, $57, $43, $3c, $5d, $57, $43, $3c, $5d, $57, $43, $3c, $5d, $57
    db $43, $3c, $5d, $57, $43, $3c, $5d, $57
RoomAttr_StarryShrine:
    db $ff, $ff, $3f, $4b, $ff, $ff, $ff, $ff, $4d, $4b, $5b, $4b, $ff, $ff, $ff, $ff
    db $52, $d9, $44, $3c, $7d, $57, $44, $3c, $7d, $57, $44, $3c, $7d, $57, $53, $d9
    db $45, $3c, $7d, $57, $45, $3c, $7d, $57, $45, $3c, $7d, $57, $54, $d9, $46, $3c
    db $7d, $57, $46, $3c, $7d, $57
RoomAttr_SecretPassage:
    db $6d, $4b, $73, $4b, $ff, $ff, $ff, $ff, $55, $d9, $47, $3c, $9d, $57, $56, $d9
    db $48, $3c, $9d, $57
RoomAttr_Gate_0C:
    db $7b, $4b, $57, $d9, $49, $3c, $bd, $57
RoomAttr_OldManGate:
    db $83, $4b, $58, $d9, $4a, $3c, $dd, $57, $4a, $3c, $dd, $57
RoomAttr_Room_0F:
    db $8f, $4b, $59, $d9, $4b, $3c, $fd, $57
RoomAttr_CopycatRoom:
    db $97, $4b, $5a, $d9, $4c, $3c, $1d, $58, $4d, $3c, $1d, $58
RoomAttr_Library:
    db $b1, $4b, $ff, $ff, $ff, $ff, $ff, $ff, $b7, $4b, $ff, $ff, $ff, $ff, $ff, $ff
    db $5b, $d9, $4e, $3c, $3d, $58, $5c, $d9, $4f, $3c, $3d, $58, $4f, $3c, $3d, $58
RoomAttr_Room_13:
    db $c3, $4b, $5d, $d9, $50, $3c, $3d, $58, $50, $3c, $3d, $58
RoomAttr_MedalManRoom:
    db $cf, $4b, $5e, $d9, $51, $3c, $5d, $58, $52, $3c, $5d, $58, $52, $3c, $5d, $58
    db $51, $3c, $5d, $58, $52, $3c, $5d, $58, $52, $3c, $5d, $58
RoomAttr_Well:
    db $f9, $4b, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $4b, $ff, $ff, $ff, $ff, $ff, $ff
    db $5f, $d9, $53, $3c, $7d, $58, $60, $d9, $54, $3c, $7d, $58, $55, $3c, $7d, $58
    db $55, $3c, $7d, $58
RoomAttr_Map19:
    db $0f, $4c, $61, $d9, $56, $3c, $9d, $58
RoomAttr_Map1A:
    db $17, $4c, $62, $d9, $57, $3c, $bd, $58
RoomAttr_Map1B:
    db $1f, $4c, $63, $d9, $58, $3c, $dd, $58, $58, $3c, $dd, $58, $58, $3c, $dd, $58
RoomAttr_Map1C:
    db $2f, $4c, $64, $d9, $59, $3c, $fd, $58, $59, $3c, $fd, $58
RoomAttr_Map1D:
    db $3b, $4c, $65, $d9, $5a, $3c, $1d, $59
RoomAttr_Map1E:
    db $43, $4c, $66, $d9, $5b, $3c, $1d, $59, $5b, $3c, $1d, $59
RoomAttr_Map1F:
    db $4f, $4c, $67, $d9, $5c, $3c, $3d, $59, $5c, $3c, $3d, $59, $5c, $3c, $3d, $59
RoomAttr_BossRoom_Beginning:
    db $5f, $4c, $68, $d9, $5d, $3c, $5d, $59, $5d, $3c, $5d, $59
RoomAttr_BossRoom_VilTalis:
    db $6b, $4c, $69, $d9, $5e, $3c, $7d, $59, $5e, $3c, $7d, $59, $5e, $3c, $7d, $59
    db $5e, $3c, $7d, $59
RoomAttr_BossRoom_MemBewil:
    db $7f, $4c, $6a, $d9, $5f, $3c, $9d, $59, $5f, $3c, $9d, $59, $5f, $3c, $9d, $59
    db $5f, $3c, $9d, $59
RoomAttr_BossRoom_PeaceBrave:
    db $93, $4c, $6b, $d9, $60, $3c, $bd, $59, $60, $3c, $bd, $59, $60, $3c, $bd, $59
    db $60, $3c, $bd, $59
RoomAttr_Map27:
    db $a7, $4c, $6c, $d9, $61, $3c, $dd, $59, $61, $3c, $dd, $59, $61, $3c, $dd, $59
RoomAttr_Map28:
    db $b7, $4c, $6d, $d9, $62, $3c, $fd, $59, $62, $3c, $fd, $59, $62, $3c, $fd, $59
    db $62, $3c, $fd, $59
RoomAttr_Map29:
    db $cb, $4c, $6e, $d9, $63, $3c, $1d, $5a, $63, $3c, $1d, $5a, $63, $3c, $1d, $5a
    db $63, $3c, $1d, $5a
RoomAttr_Map2A:
    db $df, $4c, $6f, $d9, $64, $3c, $3d, $5a, $64, $3c, $3d, $5a, $64, $3c, $3d, $5a
    db $64, $3c, $3d, $5a
RoomAttr_Map2B:
    db $f3, $4c, $70, $d9, $65, $3c, $5d, $5a, $65, $3c, $5d, $5a
RoomAttr_Map2C:
    db $ff, $4c, $71, $d9, $66, $3c, $7d, $5a, $66, $3c, $7d, $5a, $66, $3c, $7d, $5a
    db $66, $3c, $7d, $5a
RoomAttr_Map2D:
    db $13, $4d, $72, $d9, $67, $3c, $9d, $5a, $67, $3c, $9d, $5a, $67, $3c, $9d, $5a
    db $67, $3c, $9d, $5a
RoomAttr_Map2E:
    db $27, $4d, $73, $d9, $68, $3c, $bd, $5a, $68, $3c, $bd, $5a, $68, $3c, $bd, $5a
    db $68, $3c, $bd, $5a
RoomAttr_Map2F:
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $45, $4d, $63, $4d, $74, $d9, $69, $3c
    db $dd, $5a, $69, $3c, $dd, $5a, $69, $3c, $dd, $5a, $69, $3c, $dd, $5a, $69, $3c
    db $dd, $5a, $69, $3c, $dd, $5a, $69, $3c, $dd, $5a, $75, $d9, $6a, $3c, $dd, $5a
    db $6a, $3c, $dd, $5a
RoomAttr_Boss_Beginning:
    db $6f, $4d, $76, $d9, $6b, $3c, $fd, $5a, $6c, $3c, $fd, $5a
RoomAttr_Boss_Villager:
    db $7b, $4d, $77, $d9, $6d, $3c, $1d, $5b, $6e, $3c, $1d, $5b
RoomAttr_Boss_Talisman:
    db $87, $4d, $78, $d9, $6f, $3c, $3d, $5b, $70, $3c, $3d, $5b
RoomAttr_Boss_Memories:
    db $93, $4d, $79, $d9, $71, $3c, $5d, $5b, $72, $3c, $5d, $5b
RoomAttr_Map34:
    db $9f, $4d, $7a, $d9, $73, $3c, $7d, $5b, $74, $3c, $7d, $5b
RoomAttr_Map35:
    db $ab, $4d, $7b, $d9, $75, $3c, $9d, $5b, $76, $3c, $9d, $5b
RoomAttr_Map36:
    db $b7, $4d, $7c, $d9, $77, $3c, $bd, $5b, $78, $3c, $bd, $5b
RoomAttr_Map37:
    db $c3, $4d, $7d, $d9, $79, $3c, $dd, $5b, $7a, $3c, $dd, $5b
RoomAttr_Map38:
    db $cf, $4d, $7e, $d9, $7b, $3c, $fd, $5b, $7c, $3c, $fd, $5b
RoomAttr_Map39:
    db $db, $4d, $7f, $d9, $7d, $3c, $1d, $5c, $7e, $3c, $1d, $5c
RoomAttr_Map3A:
    db $e7, $4d, $80, $d9, $7f, $3c, $3d, $5c, $80, $3c, $3d, $5c
RoomAttr_Map3B:
    db $f3, $4d, $81, $d9, $81, $3c, $5d, $5c, $82, $3c, $5d, $5c
RoomAttr_Map3C:
    db $ff, $4d, $82, $d9, $83, $3c, $7d, $5c, $85, $3c, $7d, $5c, $84, $3c, $7d, $5c
RoomAttr_Map3D:
    db $0f, $4e, $83, $d9, $86, $3c, $9d, $5c, $86, $3c, $9d, $5c
RoomAttr_Map3E:
    db $1b, $4e, $84, $d9, $87, $3c, $bd, $5c, $88, $3c, $bd, $5c
RoomAttr_Map3F:
    db $27, $4e, $85, $d9, $89, $3c, $dd, $5c, $8a, $3c, $fd, $5c
RoomAttr_Map40:
    db $33, $4e, $86, $d9, $8b, $3c, $1d, $5d
RoomAttr_Map41:
    db $3b, $4e, $87, $d9, $8c, $3c, $1d, $5d, $8c, $3c, $1d, $5d, $8c, $3c, $1d, $5d
    db $8d, $3c, $1d, $5d
RoomAttr_Labyrinth:
    db $51, $4e
RoomAttr_LabyrinthBoss:
    db $7b, $4e, $88, $d9, $8e, $3c, $3d, $5d, $8e, $3c, $3d, $5d, $8e, $3c, $3d, $5d
    db $8e, $3c, $3d, $5d, $8e, $3c, $3d, $5d, $8e, $3c, $3d, $5d, $8e, $3c, $3d, $5d
    db $8e, $3c, $3d, $5d, $8e, $3c, $3d, $5d, $8e, $3c, $3d, $5d, $89, $d9, $8f, $3c
    db $5d, $5d, $8f, $3c, $5d, $5d
RoomAttr_Map43:
    db $87, $4e, $8a, $d9, $90, $3c, $7d, $5d, $91, $3c, $7d, $5d
RoomAttr_Map44:
    db $93, $4e, $8b, $d9, $92, $3c, $9d, $5d, $93, $3c, $9d, $5d
RoomAttr_Map45:
    db $9f, $4e, $8c, $d9, $94, $3c, $bd, $5d, $95, $3c, $bd, $5d, $94, $3c, $bd, $5d
RoomAttr_Map46:
    db $af, $4e, $8d, $d9, $96, $3c, $dd, $5d, $97, $3c, $dd, $5d
RoomAttr_Map47:
    db $bb, $4e, $8e, $d9, $98, $3c, $fd, $5d, $98, $3c, $fd, $5d, $99, $3c, $fd, $5d
RoomAttr_Map48:
    db $cb, $4e, $8f, $d9, $9a, $3c, $1d, $5e, $9b, $3c, $1d, $5e
RoomAttr_Map49:
    db $d7, $4e, $90, $d9, $9c, $3c, $3d, $5e, $9d, $3c, $3d, $5e
RoomAttr_Map4A:
    db $e3, $4e, $91, $d9, $9e, $3c, $5d, $5e, $9f, $3c, $5d, $5e
RoomAttr_Map4B:
    db $ef, $4e, $92, $d9, $a0, $3c, $7d, $5e, $a1, $3c, $7d, $5e
RoomAttr_Map4C:
    db $fb, $4e, $93, $d9, $a2, $3c, $9d, $5e, $a3, $3c, $9d, $5e
RoomAttr_Map4D:
    db $07, $4f, $94, $d9, $a4, $3c, $bd, $5e, $a5, $3c, $bd, $5e
RoomAttr_Map4E:
    db $21, $4f, $ff, $ff, $ff, $ff, $ff, $ff, $2b, $4f, $ff, $ff, $ff, $ff, $ff, $ff
    db $95, $d9, $a6, $3c, $dd, $5e, $a7, $3c, $dd, $5e, $96, $d9, $a8, $3c, $dd, $5e
RoomAttr_Map4F:
    db $33, $4f, $97, $d9, $a9, $3c, $fd, $5e, $aa, $3c, $fd, $5e
RoomAttr_Map50:
    db $3f, $4f, $98, $d9, $ab, $3c, $1d, $5f
RoomAttr_Map51:
    db $47, $4f, $98, $d9, $ac, $3c, $3d, $5f
RoomAttr_Map52:
    db $4f, $4f, $98, $d9, $ad, $3c, $5d, $5f
RoomAttr_Map53:
    db $5f, $4f
RoomAttr_Map61:
    db $65, $4f
RoomAttr_Map62:
    db $6b, $4f
RoomAttr_Map63:
    db $71, $4f
RoomAttr_Map64:
    db $77, $4f, $98, $d9, $ae, $3c, $7d, $5f, $98, $d9, $af, $3c, $7d, $5f, $98, $d9
    db $b0, $3c, $7d, $5f, $98, $d9, $b1, $3c, $7d, $5f, $98, $d9, $b2, $3c, $7d, $5f
RoomAttr_Map54:
    db $95, $4f, $9b, $4f, $a1, $4f, $ff, $ff, $a7, $4f, $ad, $4f, $b3, $4f, $ff, $ff
    db $b9, $4f, $bf, $4f, $c5, $4f, $ff, $ff, $98, $d9, $b3, $3c, $9d, $5f, $98, $d9
    db $b4, $3c, $9d, $5f, $98, $d9, $b5, $3c, $9d, $5f, $98, $d9, $b6, $3c, $9d, $5f
    db $98, $d9, $b7, $3c, $9d, $5f, $98, $d9, $b8, $3c, $9d, $5f, $98, $d9, $b9, $3c
    db $9d, $5f, $98, $d9, $ba, $3c, $9d, $5f, $98, $d9, $bb, $3c, $9d, $5f, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $08, $02, $00, $80, $00, $00, $00, $ff
RoomAttr_Map55:
    db $f3, $4f, $f9, $4f, $ff, $4f, $ff, $ff, $05, $50, $0b, $50, $11, $50, $ff, $ff
    db $17, $50, $1d, $50, $23, $50, $ff, $ff, $98, $d9, $bc, $3c, $bd, $5f, $98, $d9
    db $bd, $3c, $bd, $5f, $98, $d9, $be, $3c, $bd, $5f, $98, $d9, $bf, $3c, $bd, $5f
    db $98, $d9, $c0, $3c, $bd, $5f, $98, $d9, $c1, $3c, $bd, $5f, $98, $d9, $c2, $3c
    db $bd, $5f, $98, $d9, $c3, $3c, $bd, $5f, $98, $d9, $c4, $3c, $bd, $5f, $ff, $ff
    db $ff, $ff, $ff, $ff, $06, $06, $00, $80, $00, $00, $00, $ff, $ff, $ff
RoomAttr_Map56:
    db $51, $50, $57, $50, $5d, $50, $ff, $ff, $63, $50, $69, $50, $6f, $50, $ff, $ff
    db $75, $50, $7b, $50, $81, $50, $ff, $ff, $98, $d9, $c5, $3c, $dd, $5f, $98, $d9
    db $c6, $3c, $dd, $5f, $98, $d9, $c7, $3c, $dd, $5f, $98, $d9, $c8, $3c, $dd, $5f
    db $98, $d9, $c9, $3c, $dd, $5f, $98, $d9, $ca, $3c, $dd, $5f, $98, $d9, $cb, $3c
    db $dd, $5f, $98, $d9, $cc, $3c, $dd, $5f, $98, $d9, $cd, $3c, $dd, $5f, $ff, $ff
    db $03, $03, $00, $80, $00, $00, $00, $ff, $ff, $ff, $ff, $ff, $ff, $ff
RoomAttr_Map57:
    db $af, $50, $b5, $50, $bb, $50, $ff, $ff, $c1, $50, $c7, $50, $cd, $50, $ff, $ff
    db $d3, $50, $d9, $50, $df, $50, $ff, $ff, $98, $d9, $ce, $3c, $fd, $5f, $98, $d9
    db $cf, $3c, $fd, $5f, $98, $d9, $d0, $3c, $fd, $5f, $98, $d9, $d1, $3c, $fd, $5f
    db $98, $d9, $d2, $3c, $fd, $5f, $98, $d9, $d3, $3c, $fd, $5f, $98, $d9, $d4, $3c
    db $fd, $5f, $98, $d9, $d5, $3c, $fd, $5f, $98, $d9, $d6, $3c, $fd, $5f, $ff, $ff
    db $ff, $ff, $ff, $ff, $01, $06, $00, $80, $00, $00, $00, $ff, $ff, $ff
RoomAttr_Map58:
    db $0d, $51, $13, $51, $19, $51, $ff, $ff, $1f, $51, $25, $51, $2b, $51, $ff, $ff
    db $31, $51, $37, $51, $3d, $51, $ff, $ff, $98, $d9, $d7, $3c, $1d, $60, $98, $d9
    db $d8, $3c, $1d, $60, $98, $d9, $d9, $3c, $1d, $60, $98, $d9, $da, $3c, $1d, $60
    db $98, $d9, $db, $3c, $1d, $60, $98, $d9, $dc, $3c, $1d, $60, $98, $d9, $dd, $3c
    db $1d, $60, $98, $d9, $de, $3c, $1d, $60, $98, $d9, $df, $3c, $1d, $60, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $03, $06, $00, $80, $00, $00, $00, $ff, $ff
RoomAttr_Map59:
    db $6b, $51, $71, $51, $77, $51, $ff, $ff, $7d, $51, $83, $51, $89, $51, $ff, $ff
    db $8f, $51, $95, $51, $9b, $51, $ff, $ff, $98, $d9, $e0, $3c, $3d, $60, $98, $d9
    db $e1, $3c, $3d, $60, $98, $d9, $e2, $3c, $3d, $60, $98, $d9, $e3, $3c, $3d, $60
    db $98, $d9, $e4, $3c, $3d, $60, $98, $d9, $e5, $3c, $3d, $60, $98, $d9, $e6, $3c
    db $3d, $60, $98, $d9, $e7, $3c, $3d, $60, $98, $d9, $e8, $3c, $3d, $60, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $08, $06, $00, $80, $00, $00, $00, $ff
RoomAttr_Map5A:
    db $b3, $51, $98, $d9, $e9, $3c, $5d, $60
RoomAttr_Map5B:
    db $bb, $51, $98, $d9, $ea, $3c, $7d, $60
RoomAttr_Map5C:
    db $c3, $51, $98, $d9, $eb, $3c, $9d, $60
RoomAttr_ArenaBattle:
    db $cb, $51, $99, $d9, $ec, $3c, $bd, $60, $ed, $3c, $bd, $60, $ed, $3c, $bd, $60
    db $ed, $3c, $bd, $60, $ed, $3c, $bd, $60
RoomAttr_Map5E:
    db $e3, $51, $9a, $d9, $ee, $3c, $dd, $60, $ee, $3c, $dd, $60, $ee, $3c, $dd, $60
    db $ee, $3c, $dd, $60, $fd, $60, $1d, $61, $3d, $61, $5d, $61, $7d, $61, $9d, $61
    db $bd, $61, $dd, $61, $fd, $61, $1d, $62, $3d, $62, $5d, $62, $7d, $62, $9d, $62
    db $bd, $62, $dd, $62

GateAttrTable_A:  ; $5215 — 256 entries × 2B (attr_idx, attr_bank)
; Used when $C93F == 0. Indexed by $C940[screen_index].
    db $00, $3D  ; [  0] attr_idx=$00 bank=$3D
    db $01, $3D  ; [  1] attr_idx=$01 bank=$3D
    db $02, $3D  ; [  2] attr_idx=$02 bank=$3D
    db $03, $3D  ; [  3] attr_idx=$03 bank=$3D
    db $04, $3D  ; [  4] attr_idx=$04 bank=$3D
    db $05, $3D  ; [  5] attr_idx=$05 bank=$3D
    db $06, $3D  ; [  6] attr_idx=$06 bank=$3D
    db $07, $3D  ; [  7] attr_idx=$07 bank=$3D
    db $08, $3D  ; [  8] attr_idx=$08 bank=$3D
    db $09, $3D  ; [  9] attr_idx=$09 bank=$3D
    db $0A, $3D  ; [ 10] attr_idx=$0A bank=$3D
    db $0B, $3D  ; [ 11] attr_idx=$0B bank=$3D
    db $B5, $3D  ; [ 12] attr_idx=$B5 bank=$3D
    db $00, $3D  ; [ 13] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 14] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 15] attr_idx=$00 bank=$3D
    db $0C, $3D  ; [ 16] attr_idx=$0C bank=$3D
    db $0D, $3D  ; [ 17] attr_idx=$0D bank=$3D
    db $0E, $3D  ; [ 18] attr_idx=$0E bank=$3D
    db $0F, $3D  ; [ 19] attr_idx=$0F bank=$3D
    db $10, $3D  ; [ 20] attr_idx=$10 bank=$3D
    db $11, $3D  ; [ 21] attr_idx=$11 bank=$3D
    db $12, $3D  ; [ 22] attr_idx=$12 bank=$3D
    db $13, $3D  ; [ 23] attr_idx=$13 bank=$3D
    db $14, $3D  ; [ 24] attr_idx=$14 bank=$3D
    db $15, $3D  ; [ 25] attr_idx=$15 bank=$3D
    db $16, $3D  ; [ 26] attr_idx=$16 bank=$3D
    db $17, $3D  ; [ 27] attr_idx=$17 bank=$3D
    db $B6, $3D  ; [ 28] attr_idx=$B6 bank=$3D
    db $00, $3D  ; [ 29] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 30] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 31] attr_idx=$00 bank=$3D
    db $18, $3D  ; [ 32] attr_idx=$18 bank=$3D
    db $19, $3D  ; [ 33] attr_idx=$19 bank=$3D
    db $1A, $3D  ; [ 34] attr_idx=$1A bank=$3D
    db $1B, $3D  ; [ 35] attr_idx=$1B bank=$3D
    db $1C, $3D  ; [ 36] attr_idx=$1C bank=$3D
    db $1D, $3D  ; [ 37] attr_idx=$1D bank=$3D
    db $1E, $3D  ; [ 38] attr_idx=$1E bank=$3D
    db $1F, $3D  ; [ 39] attr_idx=$1F bank=$3D
    db $20, $3D  ; [ 40] attr_idx=$20 bank=$3D
    db $21, $3D  ; [ 41] attr_idx=$21 bank=$3D
    db $22, $3D  ; [ 42] attr_idx=$22 bank=$3D
    db $23, $3D  ; [ 43] attr_idx=$23 bank=$3D
    db $B7, $3D  ; [ 44] attr_idx=$B7 bank=$3D
    db $00, $3D  ; [ 45] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 46] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 47] attr_idx=$00 bank=$3D
    db $24, $3D  ; [ 48] attr_idx=$24 bank=$3D
    db $25, $3D  ; [ 49] attr_idx=$25 bank=$3D
    db $26, $3D  ; [ 50] attr_idx=$26 bank=$3D
    db $27, $3D  ; [ 51] attr_idx=$27 bank=$3D
    db $28, $3D  ; [ 52] attr_idx=$28 bank=$3D
    db $29, $3D  ; [ 53] attr_idx=$29 bank=$3D
    db $2A, $3D  ; [ 54] attr_idx=$2A bank=$3D
    db $2B, $3D  ; [ 55] attr_idx=$2B bank=$3D
    db $2C, $3D  ; [ 56] attr_idx=$2C bank=$3D
    db $2D, $3D  ; [ 57] attr_idx=$2D bank=$3D
    db $2E, $3D  ; [ 58] attr_idx=$2E bank=$3D
    db $2F, $3D  ; [ 59] attr_idx=$2F bank=$3D
    db $B8, $3D  ; [ 60] attr_idx=$B8 bank=$3D
    db $00, $3D  ; [ 61] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 62] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 63] attr_idx=$00 bank=$3D
    db $30, $3D  ; [ 64] attr_idx=$30 bank=$3D
    db $31, $3D  ; [ 65] attr_idx=$31 bank=$3D
    db $32, $3D  ; [ 66] attr_idx=$32 bank=$3D
    db $33, $3D  ; [ 67] attr_idx=$33 bank=$3D
    db $34, $3D  ; [ 68] attr_idx=$34 bank=$3D
    db $35, $3D  ; [ 69] attr_idx=$35 bank=$3D
    db $36, $3D  ; [ 70] attr_idx=$36 bank=$3D
    db $37, $3D  ; [ 71] attr_idx=$37 bank=$3D
    db $38, $3D  ; [ 72] attr_idx=$38 bank=$3D
    db $39, $3D  ; [ 73] attr_idx=$39 bank=$3D
    db $3A, $3D  ; [ 74] attr_idx=$3A bank=$3D
    db $3B, $3D  ; [ 75] attr_idx=$3B bank=$3D
    db $B9, $3D  ; [ 76] attr_idx=$B9 bank=$3D
    db $00, $3D  ; [ 77] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 78] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 79] attr_idx=$00 bank=$3D
    db $3C, $3D  ; [ 80] attr_idx=$3C bank=$3D
    db $3D, $3D  ; [ 81] attr_idx=$3D bank=$3D
    db $3E, $3D  ; [ 82] attr_idx=$3E bank=$3D
    db $3F, $3D  ; [ 83] attr_idx=$3F bank=$3D
    db $40, $3D  ; [ 84] attr_idx=$40 bank=$3D
    db $41, $3D  ; [ 85] attr_idx=$41 bank=$3D
    db $42, $3D  ; [ 86] attr_idx=$42 bank=$3D
    db $43, $3D  ; [ 87] attr_idx=$43 bank=$3D
    db $44, $3D  ; [ 88] attr_idx=$44 bank=$3D
    db $45, $3D  ; [ 89] attr_idx=$45 bank=$3D
    db $46, $3D  ; [ 90] attr_idx=$46 bank=$3D
    db $47, $3D  ; [ 91] attr_idx=$47 bank=$3D
    db $BA, $3D  ; [ 92] attr_idx=$BA bank=$3D
    db $00, $3D  ; [ 93] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 94] attr_idx=$00 bank=$3D
    db $00, $3D  ; [ 95] attr_idx=$00 bank=$3D
    db $48, $3D  ; [ 96] attr_idx=$48 bank=$3D
    db $49, $3D  ; [ 97] attr_idx=$49 bank=$3D
    db $4A, $3D  ; [ 98] attr_idx=$4A bank=$3D
    db $4B, $3D  ; [ 99] attr_idx=$4B bank=$3D
    db $4C, $3D  ; [100] attr_idx=$4C bank=$3D
    db $4D, $3D  ; [101] attr_idx=$4D bank=$3D
    db $4E, $3D  ; [102] attr_idx=$4E bank=$3D
    db $4F, $3D  ; [103] attr_idx=$4F bank=$3D
    db $50, $3D  ; [104] attr_idx=$50 bank=$3D
    db $51, $3D  ; [105] attr_idx=$51 bank=$3D
    db $52, $3D  ; [106] attr_idx=$52 bank=$3D
    db $53, $3D  ; [107] attr_idx=$53 bank=$3D
    db $BB, $3D  ; [108] attr_idx=$BB bank=$3D
    db $00, $3D  ; [109] attr_idx=$00 bank=$3D
    db $00, $3D  ; [110] attr_idx=$00 bank=$3D
    db $00, $3D  ; [111] attr_idx=$00 bank=$3D
    db $54, $3D  ; [112] attr_idx=$54 bank=$3D
    db $55, $3D  ; [113] attr_idx=$55 bank=$3D
    db $56, $3D  ; [114] attr_idx=$56 bank=$3D
    db $57, $3D  ; [115] attr_idx=$57 bank=$3D
    db $58, $3D  ; [116] attr_idx=$58 bank=$3D
    db $59, $3D  ; [117] attr_idx=$59 bank=$3D
    db $5A, $3D  ; [118] attr_idx=$5A bank=$3D
    db $5B, $3D  ; [119] attr_idx=$5B bank=$3D
    db $5C, $3D  ; [120] attr_idx=$5C bank=$3D
    db $5D, $3D  ; [121] attr_idx=$5D bank=$3D
    db $5E, $3D  ; [122] attr_idx=$5E bank=$3D
    db $5F, $3D  ; [123] attr_idx=$5F bank=$3D
    db $BC, $3D  ; [124] attr_idx=$BC bank=$3D
    db $00, $3D  ; [125] attr_idx=$00 bank=$3D
    db $00, $3D  ; [126] attr_idx=$00 bank=$3D
    db $00, $3D  ; [127] attr_idx=$00 bank=$3D
    db $60, $3D  ; [128] attr_idx=$60 bank=$3D
    db $61, $3D  ; [129] attr_idx=$61 bank=$3D
    db $62, $3D  ; [130] attr_idx=$62 bank=$3D
    db $63, $3D  ; [131] attr_idx=$63 bank=$3D
    db $64, $3D  ; [132] attr_idx=$64 bank=$3D
    db $65, $3D  ; [133] attr_idx=$65 bank=$3D
    db $66, $3D  ; [134] attr_idx=$66 bank=$3D
    db $67, $3D  ; [135] attr_idx=$67 bank=$3D
    db $68, $3D  ; [136] attr_idx=$68 bank=$3D
    db $69, $3D  ; [137] attr_idx=$69 bank=$3D
    db $6A, $3D  ; [138] attr_idx=$6A bank=$3D
    db $6B, $3D  ; [139] attr_idx=$6B bank=$3D
    db $BD, $3D  ; [140] attr_idx=$BD bank=$3D
    db $00, $3D  ; [141] attr_idx=$00 bank=$3D
    db $00, $3D  ; [142] attr_idx=$00 bank=$3D
    db $00, $3D  ; [143] attr_idx=$00 bank=$3D
    db $6C, $3D  ; [144] attr_idx=$6C bank=$3D
    db $6D, $3D  ; [145] attr_idx=$6D bank=$3D
    db $6E, $3D  ; [146] attr_idx=$6E bank=$3D
    db $6F, $3D  ; [147] attr_idx=$6F bank=$3D
    db $70, $3D  ; [148] attr_idx=$70 bank=$3D
    db $71, $3D  ; [149] attr_idx=$71 bank=$3D
    db $72, $3D  ; [150] attr_idx=$72 bank=$3D
    db $73, $3D  ; [151] attr_idx=$73 bank=$3D
    db $74, $3D  ; [152] attr_idx=$74 bank=$3D
    db $75, $3D  ; [153] attr_idx=$75 bank=$3D
    db $76, $3D  ; [154] attr_idx=$76 bank=$3D
    db $77, $3D  ; [155] attr_idx=$77 bank=$3D
    db $BE, $3D  ; [156] attr_idx=$BE bank=$3D
    db $00, $3D  ; [157] attr_idx=$00 bank=$3D
    db $00, $3D  ; [158] attr_idx=$00 bank=$3D
    db $00, $3D  ; [159] attr_idx=$00 bank=$3D
    db $78, $3D  ; [160] attr_idx=$78 bank=$3D
    db $79, $3D  ; [161] attr_idx=$79 bank=$3D
    db $7A, $3D  ; [162] attr_idx=$7A bank=$3D
    db $7B, $3D  ; [163] attr_idx=$7B bank=$3D
    db $7C, $3D  ; [164] attr_idx=$7C bank=$3D
    db $7D, $3D  ; [165] attr_idx=$7D bank=$3D
    db $7E, $3D  ; [166] attr_idx=$7E bank=$3D
    db $7F, $3D  ; [167] attr_idx=$7F bank=$3D
    db $80, $3D  ; [168] attr_idx=$80 bank=$3D
    db $81, $3D  ; [169] attr_idx=$81 bank=$3D
    db $82, $3D  ; [170] attr_idx=$82 bank=$3D
    db $83, $3D  ; [171] attr_idx=$83 bank=$3D
    db $BF, $3D  ; [172] attr_idx=$BF bank=$3D
    db $00, $3D  ; [173] attr_idx=$00 bank=$3D
    db $00, $3D  ; [174] attr_idx=$00 bank=$3D
    db $00, $3D  ; [175] attr_idx=$00 bank=$3D
    db $84, $3D  ; [176] attr_idx=$84 bank=$3D
    db $85, $3D  ; [177] attr_idx=$85 bank=$3D
    db $86, $3D  ; [178] attr_idx=$86 bank=$3D
    db $87, $3D  ; [179] attr_idx=$87 bank=$3D
    db $88, $3D  ; [180] attr_idx=$88 bank=$3D
    db $89, $3D  ; [181] attr_idx=$89 bank=$3D
    db $8A, $3D  ; [182] attr_idx=$8A bank=$3D
    db $8B, $3D  ; [183] attr_idx=$8B bank=$3D
    db $8C, $3D  ; [184] attr_idx=$8C bank=$3D
    db $8D, $3D  ; [185] attr_idx=$8D bank=$3D
    db $8E, $3D  ; [186] attr_idx=$8E bank=$3D
    db $8F, $3D  ; [187] attr_idx=$8F bank=$3D
    db $C0, $3D  ; [188] attr_idx=$C0 bank=$3D
    db $00, $3D  ; [189] attr_idx=$00 bank=$3D
    db $00, $3D  ; [190] attr_idx=$00 bank=$3D
    db $00, $3D  ; [191] attr_idx=$00 bank=$3D
    db $90, $3D  ; [192] attr_idx=$90 bank=$3D
    db $91, $3D  ; [193] attr_idx=$91 bank=$3D
    db $92, $3D  ; [194] attr_idx=$92 bank=$3D
    db $93, $3D  ; [195] attr_idx=$93 bank=$3D
    db $94, $3D  ; [196] attr_idx=$94 bank=$3D
    db $95, $3D  ; [197] attr_idx=$95 bank=$3D
    db $96, $3D  ; [198] attr_idx=$96 bank=$3D
    db $97, $3D  ; [199] attr_idx=$97 bank=$3D
    db $98, $3D  ; [200] attr_idx=$98 bank=$3D
    db $99, $3D  ; [201] attr_idx=$99 bank=$3D
    db $9A, $3D  ; [202] attr_idx=$9A bank=$3D
    db $9B, $3D  ; [203] attr_idx=$9B bank=$3D
    db $C1, $3D  ; [204] attr_idx=$C1 bank=$3D
    db $00, $3D  ; [205] attr_idx=$00 bank=$3D
    db $00, $3D  ; [206] attr_idx=$00 bank=$3D
    db $00, $3D  ; [207] attr_idx=$00 bank=$3D
    db $9C, $3D  ; [208] attr_idx=$9C bank=$3D
    db $9D, $3D  ; [209] attr_idx=$9D bank=$3D
    db $9E, $3D  ; [210] attr_idx=$9E bank=$3D
    db $9F, $3D  ; [211] attr_idx=$9F bank=$3D
    db $A0, $3D  ; [212] attr_idx=$A0 bank=$3D
    db $A1, $3D  ; [213] attr_idx=$A1 bank=$3D
    db $A2, $3D  ; [214] attr_idx=$A2 bank=$3D
    db $A3, $3D  ; [215] attr_idx=$A3 bank=$3D
    db $A4, $3D  ; [216] attr_idx=$A4 bank=$3D
    db $A5, $3D  ; [217] attr_idx=$A5 bank=$3D
    db $A6, $3D  ; [218] attr_idx=$A6 bank=$3D
    db $A7, $3D  ; [219] attr_idx=$A7 bank=$3D
    db $C2, $3D  ; [220] attr_idx=$C2 bank=$3D
    db $00, $3D  ; [221] attr_idx=$00 bank=$3D
    db $00, $3D  ; [222] attr_idx=$00 bank=$3D
    db $00, $3D  ; [223] attr_idx=$00 bank=$3D
    db $A8, $3D  ; [224] attr_idx=$A8 bank=$3D
    db $A9, $3D  ; [225] attr_idx=$A9 bank=$3D
    db $AA, $3D  ; [226] attr_idx=$AA bank=$3D
    db $AB, $3D  ; [227] attr_idx=$AB bank=$3D
    db $AC, $3D  ; [228] attr_idx=$AC bank=$3D
    db $AD, $3D  ; [229] attr_idx=$AD bank=$3D
    db $AE, $3D  ; [230] attr_idx=$AE bank=$3D
    db $AF, $3D  ; [231] attr_idx=$AF bank=$3D
    db $B0, $3D  ; [232] attr_idx=$B0 bank=$3D
    db $B1, $3D  ; [233] attr_idx=$B1 bank=$3D
    db $B2, $3D  ; [234] attr_idx=$B2 bank=$3D
    db $B3, $3D  ; [235] attr_idx=$B3 bank=$3D
    db $C3, $3D  ; [236] attr_idx=$C3 bank=$3D
    db $00, $3D  ; [237] attr_idx=$00 bank=$3D
    db $00, $3D  ; [238] attr_idx=$00 bank=$3D
    db $00, $3D  ; [239] attr_idx=$00 bank=$3D
    db $B4, $3D  ; [240] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [241] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [242] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [243] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [244] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [245] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [246] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [247] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [248] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [249] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [250] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [251] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [252] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [253] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [254] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [255] attr_idx=$B4 bank=$3D

GateAttrTable_B:  ; $5415 — 256 entries × 2B (attr_idx, attr_bank)
; Used when $C93F == 1. Indexed by $C940[screen_index].
    db $00, $3E  ; [  0] attr_idx=$00 bank=$3E
    db $01, $3E  ; [  1] attr_idx=$01 bank=$3E
    db $02, $3E  ; [  2] attr_idx=$02 bank=$3E
    db $03, $3E  ; [  3] attr_idx=$03 bank=$3E
    db $04, $3E  ; [  4] attr_idx=$04 bank=$3E
    db $05, $3E  ; [  5] attr_idx=$05 bank=$3E
    db $06, $3E  ; [  6] attr_idx=$06 bank=$3E
    db $07, $3E  ; [  7] attr_idx=$07 bank=$3E
    db $08, $3E  ; [  8] attr_idx=$08 bank=$3E
    db $09, $3E  ; [  9] attr_idx=$09 bank=$3E
    db $0A, $3E  ; [ 10] attr_idx=$0A bank=$3E
    db $0B, $3E  ; [ 11] attr_idx=$0B bank=$3E
    db $0C, $3E  ; [ 12] attr_idx=$0C bank=$3E
    db $0D, $3E  ; [ 13] attr_idx=$0D bank=$3E
    db $00, $3E  ; [ 14] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 15] attr_idx=$00 bank=$3E
    db $0E, $3E  ; [ 16] attr_idx=$0E bank=$3E
    db $0F, $3E  ; [ 17] attr_idx=$0F bank=$3E
    db $10, $3E  ; [ 18] attr_idx=$10 bank=$3E
    db $11, $3E  ; [ 19] attr_idx=$11 bank=$3E
    db $12, $3E  ; [ 20] attr_idx=$12 bank=$3E
    db $13, $3E  ; [ 21] attr_idx=$13 bank=$3E
    db $14, $3E  ; [ 22] attr_idx=$14 bank=$3E
    db $00, $3E  ; [ 23] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 24] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 25] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 26] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 27] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 28] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 29] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 30] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 31] attr_idx=$00 bank=$3E
    db $15, $3E  ; [ 32] attr_idx=$15 bank=$3E
    db $16, $3E  ; [ 33] attr_idx=$16 bank=$3E
    db $17, $3E  ; [ 34] attr_idx=$17 bank=$3E
    db $18, $3E  ; [ 35] attr_idx=$18 bank=$3E
    db $19, $3E  ; [ 36] attr_idx=$19 bank=$3E
    db $1A, $3E  ; [ 37] attr_idx=$1A bank=$3E
    db $1B, $3E  ; [ 38] attr_idx=$1B bank=$3E
    db $00, $3E  ; [ 39] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 40] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 41] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 42] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 43] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 44] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 45] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 46] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 47] attr_idx=$00 bank=$3E
    db $1C, $3E  ; [ 48] attr_idx=$1C bank=$3E
    db $1D, $3E  ; [ 49] attr_idx=$1D bank=$3E
    db $1E, $3E  ; [ 50] attr_idx=$1E bank=$3E
    db $1F, $3E  ; [ 51] attr_idx=$1F bank=$3E
    db $20, $3E  ; [ 52] attr_idx=$20 bank=$3E
    db $21, $3E  ; [ 53] attr_idx=$21 bank=$3E
    db $22, $3E  ; [ 54] attr_idx=$22 bank=$3E
    db $00, $3E  ; [ 55] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 56] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 57] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 58] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 59] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 60] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 61] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 62] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 63] attr_idx=$00 bank=$3E
    db $23, $3E  ; [ 64] attr_idx=$23 bank=$3E
    db $24, $3E  ; [ 65] attr_idx=$24 bank=$3E
    db $25, $3E  ; [ 66] attr_idx=$25 bank=$3E
    db $26, $3E  ; [ 67] attr_idx=$26 bank=$3E
    db $27, $3E  ; [ 68] attr_idx=$27 bank=$3E
    db $28, $3E  ; [ 69] attr_idx=$28 bank=$3E
    db $29, $3E  ; [ 70] attr_idx=$29 bank=$3E
    db $00, $3E  ; [ 71] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 72] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 73] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 74] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 75] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 76] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 77] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 78] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 79] attr_idx=$00 bank=$3E
    db $2A, $3E  ; [ 80] attr_idx=$2A bank=$3E
    db $2B, $3E  ; [ 81] attr_idx=$2B bank=$3E
    db $2C, $3E  ; [ 82] attr_idx=$2C bank=$3E
    db $2D, $3E  ; [ 83] attr_idx=$2D bank=$3E
    db $00, $3E  ; [ 84] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 85] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 86] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 87] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 88] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 89] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 90] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 91] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 92] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 93] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 94] attr_idx=$00 bank=$3E
    db $00, $3E  ; [ 95] attr_idx=$00 bank=$3E
    db $2E, $3E  ; [ 96] attr_idx=$2E bank=$3E
    db $2F, $3E  ; [ 97] attr_idx=$2F bank=$3E
    db $30, $3E  ; [ 98] attr_idx=$30 bank=$3E
    db $31, $3E  ; [ 99] attr_idx=$31 bank=$3E
    db $32, $3E  ; [100] attr_idx=$32 bank=$3E
    db $00, $3E  ; [101] attr_idx=$00 bank=$3E
    db $00, $3E  ; [102] attr_idx=$00 bank=$3E
    db $00, $3E  ; [103] attr_idx=$00 bank=$3E
    db $00, $3E  ; [104] attr_idx=$00 bank=$3E
    db $00, $3E  ; [105] attr_idx=$00 bank=$3E
    db $00, $3E  ; [106] attr_idx=$00 bank=$3E
    db $00, $3E  ; [107] attr_idx=$00 bank=$3E
    db $00, $3E  ; [108] attr_idx=$00 bank=$3E
    db $00, $3E  ; [109] attr_idx=$00 bank=$3E
    db $00, $3E  ; [110] attr_idx=$00 bank=$3E
    db $00, $3E  ; [111] attr_idx=$00 bank=$3E
    db $33, $3E  ; [112] attr_idx=$33 bank=$3E
    db $34, $3E  ; [113] attr_idx=$34 bank=$3E
    db $35, $3E  ; [114] attr_idx=$35 bank=$3E
    db $36, $3E  ; [115] attr_idx=$36 bank=$3E
    db $37, $3E  ; [116] attr_idx=$37 bank=$3E
    db $00, $3E  ; [117] attr_idx=$00 bank=$3E
    db $00, $3E  ; [118] attr_idx=$00 bank=$3E
    db $00, $3E  ; [119] attr_idx=$00 bank=$3E
    db $00, $3E  ; [120] attr_idx=$00 bank=$3E
    db $00, $3E  ; [121] attr_idx=$00 bank=$3E
    db $00, $3E  ; [122] attr_idx=$00 bank=$3E
    db $00, $3E  ; [123] attr_idx=$00 bank=$3E
    db $00, $3E  ; [124] attr_idx=$00 bank=$3E
    db $00, $3E  ; [125] attr_idx=$00 bank=$3E
    db $00, $3E  ; [126] attr_idx=$00 bank=$3E
    db $00, $3E  ; [127] attr_idx=$00 bank=$3E
    db $38, $3E  ; [128] attr_idx=$38 bank=$3E
    db $39, $3E  ; [129] attr_idx=$39 bank=$3E
    db $3A, $3E  ; [130] attr_idx=$3A bank=$3E
    db $3B, $3E  ; [131] attr_idx=$3B bank=$3E
    db $3C, $3E  ; [132] attr_idx=$3C bank=$3E
    db $00, $3E  ; [133] attr_idx=$00 bank=$3E
    db $00, $3E  ; [134] attr_idx=$00 bank=$3E
    db $00, $3E  ; [135] attr_idx=$00 bank=$3E
    db $00, $3E  ; [136] attr_idx=$00 bank=$3E
    db $00, $3E  ; [137] attr_idx=$00 bank=$3E
    db $00, $3E  ; [138] attr_idx=$00 bank=$3E
    db $00, $3E  ; [139] attr_idx=$00 bank=$3E
    db $00, $3E  ; [140] attr_idx=$00 bank=$3E
    db $00, $3E  ; [141] attr_idx=$00 bank=$3E
    db $00, $3E  ; [142] attr_idx=$00 bank=$3E
    db $00, $3E  ; [143] attr_idx=$00 bank=$3E
    db $3D, $3E  ; [144] attr_idx=$3D bank=$3E
    db $3E, $3E  ; [145] attr_idx=$3E bank=$3E
    db $3F, $3E  ; [146] attr_idx=$3F bank=$3E
    db $40, $3E  ; [147] attr_idx=$40 bank=$3E
    db $41, $3E  ; [148] attr_idx=$41 bank=$3E
    db $00, $3E  ; [149] attr_idx=$00 bank=$3E
    db $00, $3E  ; [150] attr_idx=$00 bank=$3E
    db $00, $3E  ; [151] attr_idx=$00 bank=$3E
    db $00, $3E  ; [152] attr_idx=$00 bank=$3E
    db $00, $3E  ; [153] attr_idx=$00 bank=$3E
    db $00, $3E  ; [154] attr_idx=$00 bank=$3E
    db $00, $3E  ; [155] attr_idx=$00 bank=$3E
    db $00, $3E  ; [156] attr_idx=$00 bank=$3E
    db $00, $3E  ; [157] attr_idx=$00 bank=$3E
    db $00, $3E  ; [158] attr_idx=$00 bank=$3E
    db $00, $3E  ; [159] attr_idx=$00 bank=$3E
    db $42, $3E  ; [160] attr_idx=$42 bank=$3E
    db $43, $3E  ; [161] attr_idx=$43 bank=$3E
    db $44, $3E  ; [162] attr_idx=$44 bank=$3E
    db $45, $3E  ; [163] attr_idx=$45 bank=$3E
    db $00, $3E  ; [164] attr_idx=$00 bank=$3E
    db $00, $3E  ; [165] attr_idx=$00 bank=$3E
    db $00, $3E  ; [166] attr_idx=$00 bank=$3E
    db $00, $3E  ; [167] attr_idx=$00 bank=$3E
    db $00, $3E  ; [168] attr_idx=$00 bank=$3E
    db $00, $3E  ; [169] attr_idx=$00 bank=$3E
    db $00, $3E  ; [170] attr_idx=$00 bank=$3E
    db $00, $3E  ; [171] attr_idx=$00 bank=$3E
    db $00, $3E  ; [172] attr_idx=$00 bank=$3E
    db $00, $3E  ; [173] attr_idx=$00 bank=$3E
    db $00, $3E  ; [174] attr_idx=$00 bank=$3E
    db $00, $3E  ; [175] attr_idx=$00 bank=$3E
    db $46, $3E  ; [176] attr_idx=$46 bank=$3E
    db $47, $3E  ; [177] attr_idx=$47 bank=$3E
    db $00, $3E  ; [178] attr_idx=$00 bank=$3E
    db $00, $3E  ; [179] attr_idx=$00 bank=$3E
    db $00, $3E  ; [180] attr_idx=$00 bank=$3E
    db $00, $3E  ; [181] attr_idx=$00 bank=$3E
    db $00, $3E  ; [182] attr_idx=$00 bank=$3E
    db $00, $3E  ; [183] attr_idx=$00 bank=$3E
    db $00, $3E  ; [184] attr_idx=$00 bank=$3E
    db $00, $3E  ; [185] attr_idx=$00 bank=$3E
    db $00, $3E  ; [186] attr_idx=$00 bank=$3E
    db $00, $3E  ; [187] attr_idx=$00 bank=$3E
    db $00, $3E  ; [188] attr_idx=$00 bank=$3E
    db $00, $3E  ; [189] attr_idx=$00 bank=$3E
    db $00, $3E  ; [190] attr_idx=$00 bank=$3E
    db $00, $3E  ; [191] attr_idx=$00 bank=$3E
    db $48, $3E  ; [192] attr_idx=$48 bank=$3E
    db $49, $3E  ; [193] attr_idx=$49 bank=$3E
    db $00, $3E  ; [194] attr_idx=$00 bank=$3E
    db $00, $3E  ; [195] attr_idx=$00 bank=$3E
    db $00, $3E  ; [196] attr_idx=$00 bank=$3E
    db $00, $3E  ; [197] attr_idx=$00 bank=$3E
    db $00, $3E  ; [198] attr_idx=$00 bank=$3E
    db $00, $3E  ; [199] attr_idx=$00 bank=$3E
    db $00, $3E  ; [200] attr_idx=$00 bank=$3E
    db $00, $3E  ; [201] attr_idx=$00 bank=$3E
    db $00, $3E  ; [202] attr_idx=$00 bank=$3E
    db $00, $3E  ; [203] attr_idx=$00 bank=$3E
    db $00, $3E  ; [204] attr_idx=$00 bank=$3E
    db $00, $3E  ; [205] attr_idx=$00 bank=$3E
    db $00, $3E  ; [206] attr_idx=$00 bank=$3E
    db $00, $3E  ; [207] attr_idx=$00 bank=$3E
    db $4A, $3E  ; [208] attr_idx=$4A bank=$3E
    db $4B, $3E  ; [209] attr_idx=$4B bank=$3E
    db $00, $3E  ; [210] attr_idx=$00 bank=$3E
    db $00, $3E  ; [211] attr_idx=$00 bank=$3E
    db $00, $3E  ; [212] attr_idx=$00 bank=$3E
    db $00, $3E  ; [213] attr_idx=$00 bank=$3E
    db $00, $3E  ; [214] attr_idx=$00 bank=$3E
    db $00, $3E  ; [215] attr_idx=$00 bank=$3E
    db $00, $3E  ; [216] attr_idx=$00 bank=$3E
    db $00, $3E  ; [217] attr_idx=$00 bank=$3E
    db $00, $3E  ; [218] attr_idx=$00 bank=$3E
    db $00, $3E  ; [219] attr_idx=$00 bank=$3E
    db $00, $3E  ; [220] attr_idx=$00 bank=$3E
    db $00, $3E  ; [221] attr_idx=$00 bank=$3E
    db $00, $3E  ; [222] attr_idx=$00 bank=$3E
    db $00, $3E  ; [223] attr_idx=$00 bank=$3E
    db $4C, $3E  ; [224] attr_idx=$4C bank=$3E
    db $4D, $3E  ; [225] attr_idx=$4D bank=$3E
    db $00, $3E  ; [226] attr_idx=$00 bank=$3E
    db $00, $3E  ; [227] attr_idx=$00 bank=$3E
    db $00, $3E  ; [228] attr_idx=$00 bank=$3E
    db $00, $3E  ; [229] attr_idx=$00 bank=$3E
    db $00, $3E  ; [230] attr_idx=$00 bank=$3E
    db $00, $3E  ; [231] attr_idx=$00 bank=$3E
    db $00, $3E  ; [232] attr_idx=$00 bank=$3E
    db $00, $3E  ; [233] attr_idx=$00 bank=$3E
    db $00, $3E  ; [234] attr_idx=$00 bank=$3E
    db $00, $3E  ; [235] attr_idx=$00 bank=$3E
    db $00, $3E  ; [236] attr_idx=$00 bank=$3E
    db $00, $3E  ; [237] attr_idx=$00 bank=$3E
    db $00, $3E  ; [238] attr_idx=$00 bank=$3E
    db $00, $3E  ; [239] attr_idx=$00 bank=$3E
    db $B4, $3D  ; [240] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [241] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [242] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [243] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [244] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [245] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [246] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [247] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [248] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [249] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [250] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [251] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [252] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [253] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [254] attr_idx=$B4 bank=$3D
    db $B4, $3D  ; [255] attr_idx=$B4 bank=$3D

; --- LZSS attribute data ($5615-$7FFF, 10731 bytes) ---
    db $AD, $35, $7F, $4B, $9F, $00, $42, $00, $AD, $35, $7F, $4B, $20, $17, $42, $00
    db $00, $7C, $7F, $4B, $AB, $7D, $42, $00, $00, $7C, $7F, $4B, $FF, $02, $42, $00
    db $B9, $36, $7F, $4B, $B6, $58, $42, $00, $00, $7C, $7F, $4B, $0F, $42, $42, $00
    db $00, $7C, $7F, $4B, $1F, $02, $42, $00, $00, $7C, $7F, $4B, $18, $22, $42, $00
    db $39, $01, $FF, $6B, $3F, $03, $00, $00, $7C, $08, $FF, $6B, $7C, $08, $00, $00
    db $15, $00, $FF, $6B, $9F, $02, $00, $00, $AE, $29, $FF, $6B, $D6, $4A, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $70, $01, $FF, $6B, $37, $1A, $00, $00
    db $20, $17, $FF, $6B, $F0, $03, $00, $00, $20, $17, $FF, $6B, $37, $1A, $00, $00
    db $20, $17, $FF, $6B, $42, $7F, $00, $00, $20, $17, $FF, $6B, $F0, $03, $00, $00
    db $20, $17, $FF, $6B, $42, $7F, $00, $00, $15, $00, $FF, $6B, $9F, $02, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $AC, $39, $FF, $6B, $70, $22, $00, $00
    db $AC, $39, $FF, $6B, $70, $22, $00, $00, $09, $15, $FF, $6B, $70, $22, $00, $00
    db $2C, $19, $FF, $6B, $B2, $19, $00, $00, $20, $17, $FF, $6B, $F0, $03, $00, $00
    db $30, $01, $FF, $6B, $F4, $11, $00, $00, $51, $00, $FF, $6B, $75, $01, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $CB, $01, $57, $37, $AD, $1E, $80, $00
    db $30, $01, $57, $37, $F4, $11, $42, $00, $85, $49, $57, $37, $AD, $3E, $44, $00
    db $20, $1E, $36, $1F, $EC, $02, $80, $00, $D0, $19, $FF, $6B, $3D, $43, $00, $00
    db $32, $05, $FF, $6B, $9F, $02, $00, $00, $32, $05, $FF, $6B, $99, $2E, $00, $00
    db $32, $05, $FF, $6B, $99, $2E, $00, $00, $32, $05, $FF, $6B, $99, $2E, $00, $00
    db $6D, $4D, $FF, $6B, $99, $2E, $00, $00, $32, $05, $FF, $6B, $99, $2E, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $ED, $04, $FF, $6B, $1A, $1A, $00, $00
    db $15, $20, $FF, $6B, $1F, $20, $00, $00, $42, $7D, $FF, $6B, $75, $7E, $00, $00
    db $2E, $15, $FF, $6B, $3A, $2E, $00, $00, $0B, $7C, $FF, $6B, $12, $7F, $00, $00
    db $CE, $39, $FF, $6B, $51, $3A, $00, $00, $20, $17, $FF, $6B, $F0, $03, $00, $00
    db $15, $00, $FF, $6B, $9F, $02, $00, $00, $AE, $29, $FF, $6B, $D6, $4A, $00, $00
    db $15, $00, $FF, $6B, $7C, $08, $00, $00, $00, $7C, $00, $7C, $00, $7C, $00, $7C
    db $00, $7C, $00, $7C, $00, $7C, $00, $7C, $ED, $04, $FF, $6B, $15, $1A, $00, $00
    db $20, $06, $FF, $6B, $3A, $02, $00, $00, $20, $17, $FF, $6B, $9F, $03, $00, $00
    db $18, $24, $FF, $6B, $5C, $41, $00, $00, $ED, $04, $FF, $6B, $15, $1A, $00, $00
    db $ED, $04, $FF, $6B, $3A, $02, $00, $00, $0F, $7C, $FF, $6B, $42, $7F, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $ED, $04, $FF, $6B, $15, $1A, $00, $00
    db $F2, $04, $FF, $6B, $DA, $3A, $00, $00, $2C, $19, $FF, $6B, $CF, $31, $00, $00
    db $15, $00, $FF, $6B, $FF, $02, $00, $00, $ED, $04, $FF, $6B, $15, $1A, $00, $00
    db $ED, $04, $FF, $6B, $3A, $02, $00, $00, $20, $17, $FF, $6B, $9F, $03, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $ED, $04, $FF, $6B, $15, $1A, $00, $00
    db $18, $00, $FF, $6B, $3A, $02, $00, $00, $20, $06, $FF, $6B, $3A, $02, $42, $00
    db $00, $7D, $FF, $6B, $42, $7F, $42, $00, $ED, $04, $FF, $6B, $15, $1A, $00, $00
    db $EC, $04, $FF, $6B, $3A, $02, $00, $00, $00, $7C, $00, $7C, $00, $7C, $00, $7C
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $86, $01, $F0, $42, $0C, $22, $80, $00
    db $EC, $04, $FD, $2A, $F6, $01, $42, $00, $EA, $04, $B8, $3A, $CE, $39, $42, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $32, $05, $FF, $6B, $99, $2E, $00, $00
    db $F1, $04, $FF, $6B, $9F, $02, $00, $00, $00, $7D, $FF, $6B, $42, $7F, $00, $00
    db $17, $14, $FF, $6B, $99, $2E, $00, $00, $32, $05, $FF, $6B, $99, $2E, $00, $00
    db $F1, $04, $FF, $6B, $9F, $02, $00, $00, $00, $7D, $FF, $6B, $42, $7F, $00, $00
    db $17, $14, $FF, $6B, $99, $2E, $00, $00, $20, $17, $FF, $6B, $F0, $03, $00, $00
    db $15, $00, $FF, $6B, $9A, $01, $00, $00, $00, $7D, $FF, $6B, $42, $7F, $00, $00
    db $15, $00, $FF, $6B, $9A, $01, $00, $00, $20, $17, $FF, $6B, $F0, $03, $00, $00
    db $00, $7D, $FF, $6B, $15, $1A, $00, $00, $6B, $2D, $FF, $6B, $7C, $08, $00, $00
    db $ED, $04, $FF, $6B, $3A, $02, $00, $00, $ED, $04, $FF, $6B, $15, $1A, $00, $00
    db $E9, $5C, $FF, $6B, $2B, $7E, $00, $00, $20, $02, $FF, $6B, $FF, $7F, $42, $00
    db $EC, $04, $FF, $6B, $F6, $01, $42, $00, $0C, $7C, $FF, $6B, $AB, $7E, $00, $00
    db $12, $18, $FF, $6B, $BA, $34, $00, $00, $20, $17, $FF, $6B, $9F, $03, $00, $00
    db $70, $01, $FF, $6B, $37, $1A, $00, $00, $AC, $39, $FF, $6B, $D6, $4A, $00, $00
    db $6A, $25, $FF, $6B, $F0, $42, $00, $00, $9F, $02, $FF, $6B, $7C, $08, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $AC, $39, $FF, $6B, $D6, $4A, $42, $00
    db $AE, $29, $30, $22, $D6, $4A, $42, $00, $EA, $04, $90, $42, $C9, $31, $42, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $AC, $39, $FF, $6B, $D6, $4A, $42, $00
    db $6A, $25, $90, $42, $C9, $31, $42, $00, $EA, $04, $1F, $13, $79, $1A, $42, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $AC, $39, $FF, $6B, $D6, $4A, $42, $00
    db $EA, $04, $90, $42, $C9, $31, $42, $00, $78, $04, $9F, $03, $76, $36, $85, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $AE, $29, $FF, $6B, $D6, $4A, $42, $00
    db $6A, $25, $90, $42, $C9, $31, $42, $00, $EA, $04, $3D, $43, $36, $1A, $42, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $AC, $39, $FF, $6B, $D6, $4A, $42, $00
    db $EA, $04, $90, $42, $C9, $31, $42, $00, $EA, $04, $1F, $13, $79, $1A, $42, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $AE, $29, $FF, $6B, $D6, $4A, $42, $00
    db $EA, $04, $90, $42, $C9, $31, $42, $00, $78, $04, $9F, $03, $76, $36, $85, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $AE, $29, $FF, $6B, $D6, $4A, $42, $00
    db $EA, $04, $90, $42, $C9, $31, $42, $00, $78, $04, $9F, $03, $76, $36, $85, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $AE, $29, $FF, $6B, $D6, $4A, $42, $00
    db $EA, $04, $90, $42, $C9, $31, $42, $00, $EA, $04, $1F, $13, $79, $1A, $42, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $AE, $29, $FF, $6B, $D6, $4A, $42, $00
    db $EA, $04, $90, $42, $C9, $31, $42, $00, $78, $04, $9F, $03, $76, $36, $85, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $AE, $29, $FF, $6B, $D6, $4A, $42, $00
    db $EA, $04, $90, $42, $C9, $31, $42, $00, $EA, $04, $1F, $13, $79, $1A, $42, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $AE, $29, $FF, $6B, $D6, $4A, $42, $00
    db $78, $04, $9F, $03, $76, $36, $85, $00, $EA, $04, $1F, $13, $79, $1A, $42, $00
    db $00, $7D, $F7, $7F, $42, $7F, $E3, $48, $EE, $64, $FF, $6B, $33, $7E, $00, $00
    db $7F, $00, $FF, $6B, $1F, $02, $00, $00, $20, $07, $FF, $6B, $33, $7E, $00, $00
    db $2F, $09, $FF, $6B, $57, $1A, $00, $00, $69, $05, $FF, $6B, $51, $02, $00, $00
    db $07, $15, $FF, $6B, $2D, $32, $00, $00, $50, $00, $FF, $6B, $9F, $02, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $D0, $00, $FF, $6B, $12, $22, $00, $00
    db $4A, $1D, $FF, $6B, $94, $3E, $00, $00, $52, $00, $FF, $6B, $3F, $01, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $23, $02, $FF, $6B, $EE, $03, $00, $00
    db $69, $41, $FF, $6B, $B3, $5E, $00, $00, $13, $4D, $FF, $6B, $5D, $02, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $E8, $00, $FF, $6B, $BB, $16, $00, $00
    db $0A, $09, $FF, $6B, $57, $0E, $00, $00, $E8, $00, $FF, $6B, $10, $1A, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $49, $02, $FF, $6B, $EE, $03, $00, $00
    db $6F, $05, $FF, $6B, $BB, $02, $00, $00, $CD, $00, $FF, $6B, $34, $12, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $2B, $02, $FF, $6B, $EE, $03, $00, $00
    db $0E, $05, $FF, $6B, $BA, $16, $00, $00, $13, $4D, $FF, $6B, $5D, $02, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $32, $1C, $FF, $6B, $BF, $4D, $00, $00
    db $32, $1C, $FF, $6B, $18, $46, $00, $00, $52, $00, $FF, $6B, $7F, $01, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $0A, $51, $FF, $6B, $11, $7F, $00, $00
    db $2A, $21, $FF, $6B, $74, $46, $00, $00, $52, $00, $FF, $6B, $3F, $01, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $66, $00, $FF, $6B, $75, $01, $00, $00
    db $8C, $19, $FF, $6B, $B5, $3E, $00, $00, $00, $7C, $00, $7C, $00, $7C, $00, $7C
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $E5, $30, $FF, $6B, $F4, $62, $00, $00
    db $A5, $28, $FF, $6B, $CD, $41, $00, $00, $50, $00, $FF, $6B, $9F, $02, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $2A, $15, $FF, $6B, $B7, $2A, $00, $00
    db $05, $19, $FF, $6B, $A9, $35, $00, $00, $53, $0D, $FF, $6B, $1A, $02, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $06, $35, $FF, $6B, $91, $7E, $00, $00
    db $0C, $21, $FF, $6B, $99, $5E, $00, $00, $52, $00, $FF, $6B, $3F, $01, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $4D, $01, $FF, $6B, $97, $3A, $00, $00
    db $68, $01, $FF, $6B, $6D, $0E, $00, $00, $3F, $01, $FF, $6B, $D9, $3E, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $49, $02, $FF, $6B, $EE, $03, $00, $00
    db $70, $1D, $00, $7C, $00, $7C, $00, $00, $40, $26, $FF, $6B, $E0, $3B, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $0E, $0D, $FF, $6B, $7F, $22, $00, $00
    db $14, $00, $FF, $6B, $9F, $01, $00, $00, $50, $0D, $FF, $6B, $FD, $01, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $52, $00, $FF, $6B, $3F, $01, $00, $00
    db $00, $7C, $00, $7C, $00, $7C, $00, $7C, $10, $00, $FF, $6B, $DF, $05, $00, $00
    db $00, $7C, $00, $7C, $00, $7C, $00, $7C, $49, $02, $00, $7C, $EE, $03, $00, $00
    db $4F, $11, $FF, $6B, $98, $16, $00, $00, $CC, $21, $FF, $6B, $34, $43, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $6D, $14, $FF, $6B, $98, $42, $00, $00
    db $ED, $00, $FF, $6B, $B9, $32, $00, $00, $00, $7C, $00, $7C, $00, $7C, $00, $7C
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $13, $01, $FF, $6B, $F7, $1D, $00, $00
    db $15, $02, $FF, $6B, $16, $1B, $00, $00, $50, $00, $FF, $6B, $9F, $02, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $13, $01, $FF, $6B, $F7, $1D, $00, $00
    db $15, $02, $FF, $6B, $16, $1B, $00, $00, $50, $00, $FF, $6B, $9F, $02, $00, $00
    db $00, $7D, $FF, $6B, $55, $7D, $00, $00, $C7, $18, $FF, $6B, $11, $42, $00, $00
    db $A7, $34, $FF, $6B, $73, $72, $00, $00, $A7, $34, $FF, $6B, $11, $42, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $4B, $25, $FF, $6B, $10, $36, $00, $00
    db $13, $01, $FF, $6B, $10, $36, $00, $00, $DF, $01, $FF, $6B, $FF, $1A, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $26, $19, $FF, $6B, $70, $42, $00, $00
    db $64, $11, $FF, $6B, $42, $6B, $00, $00, $67, $1D, $FF, $6B, $8E, $3A, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $52, $00, $FF, $6B, $3F, $01, $00, $00
    db $EC, $14, $FF, $6B, $D6, $19, $00, $00, $EC, $14, $FF, $6B, $DD, $19, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $89, $08, $FF, $6B, $70, $1D, $00, $00
    db $4C, $01, $FF, $6B, $D6, $1A, $00, $00, $52, $00, $FF, $6B, $3F, $01, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $52, $00, $FF, $6B, $3F, $01, $00, $00
    db $8F, $34, $FF, $6B, $38, $5E, $00, $00, $52, $00, $FF, $6B, $9F, $02, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $6B, $24, $FF, $6B, $29, $5D, $00, $00
    db $F2, $34, $FF, $6B, $98, $5E, $00, $00, $F2, $34, $FF, $6B, $3F, $01, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $26, $01, $FF, $6B, $91, $16, $00, $00
    db $26, $01, $FF, $6B, $18, $23, $00, $00, $26, $01, $FF, $6B, $0E, $2A, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $2A, $01, $FF, $6B, $97, $16, $00, $00
    db $69, $11, $FF, $6B, $52, $2A, $00, $00, $00, $7C, $00, $7C, $00, $7C, $00, $7C
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $42, $40, $FF, $6B, $87, $61, $00, $00
    db $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $4E, $01, $FF, $6B, $35, $2A, $00, $00
    db $52, $00, $FF, $6B, $3F, $01, $00, $00, $B5, $04, $FF, $6B, $FE, $01, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $CD, $25, $FF, $6B, $D4, $46, $00, $00
    db $0B, $11, $FF, $6B, $CF, $21, $00, $00, $49, $09, $FF, $6B, $D5, $3E, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $4A, $25, $FF, $6B, $30, $4A, $00, $00
    db $4A, $25, $FF, $6B, $30, $4A, $00, $00, $6B, $21, $FF, $6B, $31, $3E, $00, $00
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00, $50, $01, $FF, $6B, $59, $12, $00, $00
    db $EC, $00, $FF, $6B, $59, $12, $00, $00, $0E, $14, $FF, $6B, $7D, $14, $00, $00
    db $4D, $2C, $FF, $6B, $B8, $3C, $00, $00, $51, $00, $FF, $6B, $9C, $1C, $00, $00
    db $06, $19, $FF, $6B, $50, $46, $00, $00, $2D, $05, $FF, $6B, $5B, $02, $00, $00
    db $23, $05, $FF, $6B, $8F, $02, $00, $00, $6E, $05, $FF, $6B, $37, $02, $00, $00
    db $E6, $18, $FF, $6B, $50, $46, $00, $00, $4C, $28, $FF, $6B, $B6, $24, $00, $00
    db $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $A0, $01, $FF, $6B, $A6, $02, $00, $00, $89, $05, $FF, $6B, $11, $02, $00, $00
    db $A0, $01, $FF, $6B, $A6, $02, $00, $00, $29, $65, $FF, $6B, $0F, $7F, $00, $00
    db $6B, $04, $FF, $6B, $77, $0D, $00, $00, $AE, $08, $FF, $6B, $76, $0D, $00, $00
    db $0F, $09, $FF, $6B, $38, $02, $00, $00, $73, $01, $FF, $6B, $DD, $02, $00, $00
    db $C4, $18, $FF, $6B, $4B, $32, $00, $00, $05, $1D, $FF, $6B, $0B, $32, $00, $00
    db $28, $11, $FF, $6B, $AD, $15, $00, $00, $07, $02, $FF, $6B, $70, $03, $00, $00
    db $C6, $0C, $FF, $6B, $10, $1E, $00, $00, $28, $0D, $FF, $6B, $CE, $15, $00, $00
    db $02, $45, $FF, $6B, $C7, $61, $00, $00, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $08, $0D, $FF, $6B, $70, $2E, $00, $00, $28, $0D, $FF, $6B, $ED, $21, $00, $00
    db $E3, $2C, $FF, $6B, $AA, $55, $00, $00, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $C6, $24, $FF, $6B, $0F, $52, $00, $00, $07, $31, $FF, $6B, $AA, $41, $00, $00
    db $AB, $14, $FF, $6B, $74, $1D, $00, $00, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $8B, $14, $FF, $6B, $96, $29, $00, $00, $AD, $14, $FF, $6B, $33, $21, $00, $00
    db $26, $15, $FF, $6B, $2A, $32, $00, $00, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $2D, $1C, $FF, $6B, $F8, $44, $00, $00, $0E, $14, $FF, $6B, $7D, $14, $00, $00
    db $54, $01, $FF, $6B, $1A, $02, $00, $00, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $2D, $1C, $FF, $6B, $F8, $44, $00, $00, $0E, $14, $FF, $6B, $7D, $14, $00, $00
    db $54, $01, $FF, $6B, $1A, $02, $00, $00, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $2D, $1C, $FF, $6B, $F8, $44, $00, $00, $0E, $14, $FF, $6B, $7D, $14, $00, $00
    db $54, $01, $FF, $6B, $1A, $02, $00, $00, $43, $25, $FF, $6B, $16, $0C, $00, $00
    db $EA, $04, $FF, $6B, $FF, $16, $00, $00, $43, $25, $FF, $6B, $E5, $62, $00, $00
    db $EE, $00, $FF, $6B, $18, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $FF, $6B, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $EB, $08, $FF, $6B, $B4, $11, $00, $00
    db $C8, $21, $FF, $6B, $F0, $2E, $00, $00, $C8, $21, $FF, $6B, $F0, $2E, $00, $00
    db $EB, $08, $FF, $6B, $B4, $11, $00, $00, $AB, $14, $FF, $6B, $35, $29, $00, $00
    db $07, $2D, $FF, $6B, $0F, $4A, $00, $00, $07, $2D, $FF, $6B, $0F, $4A, $00, $00
    db $AB, $14, $FF, $6B, $35, $29, $00, $00, $CE, $08, $FF, $6B, $13, $05, $00, $00
    db $51, $05, $FF, $6B, $BA, $1A, $00, $00, $51, $05, $FF, $6B, $BA, $1A, $00, $00
    db $CE, $08, $FF, $6B, $13, $05, $00, $00, $14, $00, $FF, $6B, $1F, $15, $00, $00
    db $8F, $08, $FF, $6B, $78, $0D, $00, $00, $8F, $08, $FF, $6B, $78, $0D, $00, $00
    db $90, $14, $FF, $6B, $D4, $1C, $00, $00, $00, $7D, $FF, $6B, $20, $7F, $00, $00
    db $A4, $4C, $FF, $6B, $EA, $7D, $00, $00, $A4, $4C, $FF, $6B, $EA, $7D, $00, $00
    db $00, $7D, $FF, $6B, $20, $7F, $00, $00, $45, $11, $FF, $6B, $4A, $2A, $00, $00
    db $8B, $28, $FF, $6B, $54, $5D, $00, $00, $8B, $28, $FF, $6B, $54, $5D, $00, $00
    db $45, $11, $FF, $6B, $4A, $2A, $00, $00, $05, $7C, $FF, $6B, $1F, $7C, $00, $00
    db $8B, $28, $FF, $6B, $54, $5D, $00, $00, $8B, $28, $FF, $6B, $54, $5D, $00, $00
    db $45, $11, $FF, $6B, $4A, $2A, $00, $00, $E8, $1D, $FF, $6B, $6C, $1E, $00, $00
    db $2C, $01, $FF, $6B, $36, $02, $00, $00, $2C, $01, $FF, $6B, $36, $02, $00, $00
    db $E8, $1D, $FF, $6B, $6C, $1E, $00, $00, $CC, $10, $FF, $6B, $32, $1D, $00, $00
    db $4A, $19, $FF, $6B, $94, $42, $00, $00, $4A, $19, $FF, $6B, $94, $42, $00, $00
    db $CC, $10, $FF, $6B, $32, $1D, $00, $00, $A0, $01, $FF, $6B, $A6, $02, $00, $00
    db $A0, $01, $FF, $6B, $C9, $02, $00, $00, $A0, $01, $FF, $6B, $C9, $02, $00, $00
    db $A0, $01, $FF, $6B, $A6, $02, $00, $00, $C9, $21, $FF, $6B, $E8, $56, $00, $00
    db $2C, $01, $FF, $6B, $36, $02, $00, $00, $2C, $01, $FF, $6B, $36, $02, $00, $00
    db $C9, $21, $FF, $6B, $E8, $56, $00, $00, $EE, $04, $FF, $6B, $7A, $02, $00, $00
    db $CA, $4D, $FF, $6B, $B2, $76, $00, $00, $CA, $4D, $FF, $6B, $B2, $76, $00, $00
    db $C1, $01, $FF, $6B, $CD, $03, $00, $00, $0D, $2C, $FF, $6B, $15, $3C, $00, $00
    db $CA, $4D, $FF, $6B, $B2, $76, $00, $00, $CA, $4D, $FF, $6B, $B2, $76, $00, $00
    db $C1, $01, $FF, $6B, $CD, $03, $00, $00, $EE, $04, $FF, $6B, $7A, $02, $00, $00
    db $40, $7D, $FF, $6B, $81, $7F, $00, $00, $F0, $00, $FF, $6B, $1A, $02, $00, $00
    db $A1, $01, $FF, $6B, $AA, $03, $00, $00, $0D, $2C, $FF, $6B, $15, $3C, $00, $00
    db $40, $7D, $FF, $6B, $81, $7F, $00, $00, $F0, $00, $FF, $6B, $1A, $02, $00, $00
    db $A1, $01, $FF, $6B, $AA, $03, $00, $00, $EE, $04, $FF, $6B, $7A, $02, $00, $00
    db $CA, $4D, $FF, $6B, $B2, $76, $00, $00, $CA, $4D, $FF, $6B, $B2, $76, $00, $00
    db $EE, $04, $FF, $6B, $7A, $02, $00, $00
RoomAttrDataBlocks:
    db $BD, $01, $FF, $6B, $5F, $03, $00, $00
    db $BD, $01, $FF, $6B, $5F, $03, $00, $00, $00, $26, $FF, $6B, $80, $47, $00, $00
    db $34, $00, $FF, $6B, $B4, $78, $00, $00, $02, $06, $FF, $6B, $90, $03, $00, $00
    db $00, $7D, $FF, $6B, $40, $1B, $00, $00, $C1, $01, $FF, $6B, $6C, $03, $00, $00
    db $16, $0C, $FF, $6B, $7E, $15, $00, $00, $0F, $5C, $FF, $6B, $A0, $7E, $00, $00
    db $E1, $7C, $FF, $6B, $BF, $02, $00, $00, $20, $46, $FF, $6B, $8D, $03, $00, $00
    db $F0, $00, $FF, $6B, $FA, $05, $00, $00, $E4, $34, $FF, $6B, $EE, $39, $00, $00
    db $15, $24, $FF, $6B, $1F, $61, $00, $00, $BD, $01, $FF, $6B, $5F, $03, $00, $00
    db $E4, $74, $FF, $6B, $40, $7E, $00, $00, $6A, $29, $FF, $6B, $51, $4A, $00, $00
    db $6A, $29, $FF, $6B, $51, $4A, $00, $00, $6A, $29, $FF, $6B, $51, $4A, $00, $00
    db $DF, $01, $FF, $6B, $1F, $03, $00, $00, $DE, $01, $FF, $6B, $7F, $03, $00, $00
    db $55, $01, $FF, $6B, $80, $7E, $00, $00, $CA, $55, $FF, $6B, $71, $73, $00, $00
    db $37, $1C, $FF, $6B, $9F, $02, $00, $00, $11, $2C, $FF, $6B, $9D, $20, $00, $00
    db $E8, $0D, $FF, $6B, $27, $5B, $00, $00, $69, $0D, $FF, $6B, $D7, $02, $00, $00
    db $0A, $68, $FF, $6B, $00, $7E, $00, $00, $C3, $01, $FF, $6B, $A0, $32, $00, $00
    db $19, $01, $FF, $6B, $BF, $02, $00, $00, $20, $4D, $FF, $6B, $80, $7E, $00, $00
    db $52, $02, $FF, $6B, $9F, $03, $00, $00, $A0, $01, $FF, $6B, $A0, $06, $00, $00
    db $86, $02, $FF, $6B, $B6, $03, $00, $00, $8C, $31, $FF, $6B, $B2, $4E, $00, $00
    db $46, $15, $FF, $6B, $DD, $08, $00, $00, $F1, $00, $FF, $6B, $51, $3E, $00, $00
    db $EE, $10, $FF, $6B, $5C, $07, $00, $00, $9C, $1C, $FF, $6B, $C5, $06, $00, $00
    db $A1, $01, $FF, $6B, $60, $7E, $00, $00, $E3, $05, $FF, $6B, $F8, $00, $00, $00
    db $31, $01, $FF, $6B, $86, $02, $00, $00, $00, $1E, $FF, $6B, $6F, $07, $00, $00
    db $08, $02, $FF, $6B, $7F, $02, $00, $00, $26, $12, $FF, $6B, $0C, $1B, $00, $00
    db $13, $01, $FF, $6B, $1A, $02, $00, $00, $F9, $01, $FF, $6B, $F7, $7C, $00, $00
    db $D9, $00, $FF, $6B, $3F, $02, $00, $00, $07, $02, $FF, $6B, $33, $03, $00, $00
    db $60, $59, $FF, $6B, $B7, $01, $00, $00, $F2, $00, $FF, $6B, $90, $02, $00, $00
    db $79, $01, $FF, $6B, $5F, $03, $00, $00, $A0, $69, $FF, $6B, $00, $7F, $00, $00
    db $E3, $64, $FF, $6B, $23, $7E, $00, $00, $71, $6C, $FF, $6B, $7F, $02, $00, $00
    db $37, $01, $FF, $6B, $34, $03, $00, $00, $0E, $3E, $FF, $6B, $FF, $6B, $00, $00
    db $36, $24, $FF, $6B, $7F, $02, $00, $00, $26, $35, $FF, $6B, $0C, $4A, $00, $00
    db $12, $01, $FF, $6B, $1F, $5E, $00, $00, $6C, $6C, $FF, $6B, $87, $7A, $00, $00
    db $D1, $74, $FF, $6B, $DF, $79, $00, $00, $1B, $01, $FF, $6B, $D9, $71, $00, $00
    db $E0, $79, $FF, $6B, $3E, $02, $00, $00, $6C, $48, $FF, $6B, $D6, $6C, $00, $00
    db $44, $61, $FF, $6B, $F0, $76, $00, $00, $2D, $06, $FF, $6B, $C4, $7A, $00, $00
    db $4C, $02, $FF, $6B, $BF, $02, $00, $00, $BC, $00, $FF, $6B, $5F, $02, $00, $00
    db $EF, $00, $FF, $6B, $D8, $01, $00, $00, $B8, $58, $FF, $6B, $7F, $02, $00, $00
    db $BC, $01, $FF, $6B, $5F, $03, $00, $00, $4E, $1C, $FF, $6B, $53, $01, $00, $00
    db $57, $18, $FF, $6B, $2A, $7E, $00, $00, $95, $58, $FF, $6B, $50, $03, $00, $00
    db $5B, $02, $FF, $6B, $76, $6D, $00, $00, $E9, $01, $FF, $6B, $BB, $02, $00, $00
    db $DD, $00, $FF, $6B, $BF, $02, $00, $00, $7B, $00, $FF, $6B, $97, $2A, $00, $00
    db $37, $58, $FF, $6B, $FF, $02, $00, $00, $E0, $7D, $FF, $6B, $5F, $02, $00, $00
    db $0F, $3C, $FF, $6B, $37, $58, $00, $00, $03, $02, $FF, $6B, $36, $7D, $00, $00
    db $4D, $5C, $FF, $6B, $76, $6D, $00, $00, $61, $69, $FF, $6B, $2A, $7F, $00, $00
    db $FD, $00, $FF, $6B, $DF, $02, $00, $00, $ED, $7C, $FF, $6B, $69, $7E, $00, $00
    db $DB, $00, $FF, $6B, $7F, $02, $00, $00, $52, $7D, $FF, $6B, $8A, $7F, $00, $00
    db $4F, $7C, $FF, $6B, $5F, $65, $00, $00, $00, $02, $FF, $6B, $8D, $03, $00, $00
    db $70, $64, $FF, $6B, $E8, $7E, $00, $00, $B2, $60, $FF, $6B, $6E, $7E, $00, $00
    db $C4, $01, $FF, $6B, $F1, $02, $00, $00, $E1, $01, $FF, $6B, $2A, $03, $00, $00
    db $05, $02, $FF, $6B, $8D, $03, $00, $00, $70, $64, $FF, $6B, $36, $03, $00, $00
    db $C1, $6D, $FF, $6B, $FF, $01, $00, $00, $10, $01, $FF, $6B, $1B, $02, $00, $00
    db $B5, $01, $FF, $6B, $D0, $02, $00, $00, $DA, $00, $FF, $6B, $5F, $02, $00, $00
    db $10, $01, $FF, $6B, $7F, $02, $00, $00, $C5, $01, $FF, $6B, $14, $02, $00, $00
    db $C1, $01, $FF, $6B, $17, $02, $00, $00, $E1, $11, $FF, $6B, $2C, $03, $00, $00
    db $56, $30, $FF, $6B, $7E, $02, $00, $00, $5B, $00, $FF, $6B, $D3, $78, $00, $00
    db $40, $02, $FF, $6B, $93, $03, $00, $00, $54, $00, $FF, $6B, $1F, $01, $00, $00
    db $E0, $58, $FF, $6B, $A6, $7E, $00, $00, $18, $00, $FF, $6B, $71, $03, $00, $00
    db $12, $48, $FF, $6B, $C9, $02, $00, $00, $10, $38, $FF, $6B, $7F, $02, $00, $00
    db $7B, $00, $FF, $6B, $CE, $7D, $00, $00, $60, $6D, $FF, $6B, $40, $47, $00, $00
    db $50, $44, $FF, $6B, $18, $5D, $00, $00, $9C, $01, $FF, $6B, $4E, $03, $00, $00
    db $78, $01, $FF, $6B, $3F, $02, $00, $00, $61, $09, $FF, $6B, $A1, $1E, $00, $00
    db $BD, $01, $FF, $6B, $4F, $03, $00, $00, $55, $44, $FF, $6B, $76, $3E, $00, $00
    db $16, $04, $FF, $6B, $9F, $01, $00, $00, $6F, $5C, $FF, $6B, $FF, $02, $00, $00
    db $52, $01, $FF, $6B, $7E, $02, $00, $00, $10, $30, $FF, $6B, $9D, $51, $00, $00
    db $18, $00, $FF, $6B, $DE, $01, $00, $00, $11, $04, $FF, $6B, $BF, $02, $00, $00
    db $AF, $00, $FF, $6B, $9B, $01, $00, $00, $5B, $01, $FF, $6B, $BF, $02, $00, $00
    db $6D, $40, $FF, $6B, $BD, $04, $00, $00, $60, $79, $FF, $6B, $3F, $02, $00, $00
    db $C3, $01, $FF, $6B, $B9, $64, $00, $00, $E3, $58, $FF, $6B, $E7, $7E, $00, $00
    db $F0, $04, $FF, $6B, $78, $34, $00, $00, $60, $6D, $FF, $6B, $57, $7D, $00, $00
    db $40, $69, $FF, $6B, $A4, $7E, $00, $00, $60, $6D, $FF, $6B, $9F, $02, $00, $00
    db $71, $45, $FF, $6B, $18, $6A, $00, $00, $9B, $00, $FF, $6B, $7F, $02, $00, $00
    db $36, $01, $FF, $6B, $BC, $71, $00, $00, $5F, $02, $FF, $6B, $00, $7A, $00, $00
    db $77, $40, $FF, $6B, $9F, $02, $00, $00, $43, $65, $FF, $6B, $DA, $00, $00, $00
    db $32, $01, $FF, $6B, $5D, $02, $00, $00, $26, $65, $FF, $6B, $68, $0F, $00, $00
    db $6D, $40, $FF, $6B, $17, $59, $00, $00, $86, $7D, $FF, $6B, $B9, $58, $00, $00
    db $A6, $01, $FF, $6B, $A0, $7E, $00, $00, $BB, $00, $FF, $6B, $9F, $02, $00, $00
    db $C3, $1D, $FF, $6B, $4F, $7E, $00, $00, $80, $65, $FF, $6B, $20, $77, $00, $00
    db $A0, $71, $FF, $6B, $20, $77, $00, $00, $E7, $41, $FF, $6B, $1A, $00, $00, $00
    db $14, $44, $FF, $6B, $7F, $02, $00, $00, $11, $58, $FF, $6B, $DF, $01, $00, $00
    db $15, $58, $FF, $6B, $FF, $02, $00, $00, $F3, $25, $FF, $6B, $F9, $3E, $00, $00
    db $0C, $60, $FF, $6B, $20, $7A, $00, $00, $A0, $19, $FF, $6B, $76, $74, $00, $00
    db $CC, $78, $FF, $6B, $F7, $70, $C4, $00, $E8, $6C, $FF, $6B, $B1, $7E, $E0, $10
    db $10, $34, $FF, $6B, $96, $01, $00, $00, $0B, $42, $FF, $6B, $3F, $03, $00, $00
    db $C0, $75, $FF, $6B, $78, $01, $85, $00, $14, $44, $FF, $6B, $3F, $03, $00, $18
    db $7F, $02, $FF, $6B, $80, $7E, $00, $18, $0F, $38, $FF, $6B, $39, $69, $00, $18
    db $40, $61, $FF, $6B, $E3, $7E, $00, $18, $DC, $00, $FF, $6B, $BF, $02, $A6, $00
    db $58, $20, $FF, $6B, $E8, $7D, $A6, $00, $11, $30, $FF, $6B, $ED, $02, $60, $18
    db $E4, $05, $FF, $6B, $FD, $01, $00, $00, $31, $20, $FF, $6B, $1A, $5D, $00, $00
    db $29, $1D, $FF, $6B, $90, $41, $00, $00, $A0, $75, $FF, $6B, $5F, $03, $60, $10
    db $16, $0C, $FF, $6B, $1F, $03, $00, $00, $EF, $00, $FF, $6B, $1A, $02, $00, $00
    db $1F, $02, $FF, $6B, $0A, $7F, $00, $00, $E9, $7D, $FF, $6B, $FF, $02, $00, $00
    db $49, $02, $FF, $6B, $1F, $03, $00, $00, $44, $02, $FF, $6B, $6D, $03, $00, $00
    db $17, $14, $FF, $6B, $5F, $03, $00, $00, $33, $50, $FF, $6B, $24, $7E, $00, $00
    db $53, $01, $FF, $6B, $5C, $02, $00, $00, $0C, $44, $FF, $6B, $15, $58, $00, $00
    db $C9, $71, $FF, $6B, $54, $7F, $00, $00, $29, $71, $FF, $6B, $C4, $7E, $00, $00
    db $DF, $02, $FF, $6B, $0B, $7F, $00, $00, $FA, $00, $FF, $6B, $BF, $02, $00, $00
    db $58, $01, $FF, $6B, $C5, $7E, $00, $00, $38, $01, $FF, $6B, $1F, $03, $00, $00
    db $CD, $4D, $FF, $6B, $D4, $62, $00, $00, $18, $00, $FF, $6B, $5F, $02, $00, $00
    db $9E, $02, $FF, $6B, $09, $7E, $00, $00, $53, $5C, $FF, $6B, $41, $0A, $00, $00
    db $C2, $01, $FF, $6B, $FC, $01, $00, $00, $D3, $00, $FF, $6B, $5B, $02, $00, $00
    db $CE, $25, $FF, $6B, $B5, $4A, $00, $00, $86, $61, $FF, $6B, $6C, $72, $00, $00
    db $71, $60, $FF, $6B, $FF, $02, $00, $00, $89, $75, $FF, $6B, $B9, $68, $60, $10
    db $AA, $01, $FF, $6B, $78, $6C, $00, $00, $B9, $00, $FF, $6B, $0C, $7E, $00, $00
    db $A7, $01, $FF, $6B, $20, $7E, $00, $00, $69, $02, $FF, $6B, $5A, $6D, $00, $00
    db $58, $00, $FF, $6B, $9F, $02, $00, $00, $81, $01, $FF, $6B, $EB, $0E, $00, $00
    db $F3, $00, $FF, $6B, $DF, $02, $00, $00, $53, $4C, $FF, $6B, $10, $03, $00, $00
    db $17, $10, $FF, $6B, $3F, $49, $00, $00, $36, $01, $FF, $6B, $51, $03, $A3, $00
    db $53, $4C, $FF, $6B, $F9, $03, $02, $00, $17, $10, $FF, $6B, $5F, $59, $00, $08
    db $17, $10, $FF, $6B, $39, $75, $00, $08, $83, $55, $FF, $6B, $DD, $01, $00, $00
    db $AA, $0D, $FF, $6B, $E0, $7E, $00, $00
PaletteColorData:
    db $33, $46, $BE, $77, $F8, $5E, $44, $08
    db $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C
    db $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C
    db $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C, $00, $7C
    db $00, $7C, $00, $7C, $00, $7C, $00, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $A0, $31, $FF, $6B, $4E, $5E, $00, $00, $A0, $31, $FF, $6B, $8F, $66, $00, $00
    db $A0, $31, $FF, $6B, $D0, $6E, $00, $00, $48, $5E, $FF, $6B, $11, $7B, $00, $00
    db $12, $00, $FF, $6B, $DE, $01, $00, $00, $15, $00, $FF, $6B, $1F, $02, $00, $00
    db $17, $00, $FF, $6B, $9F, $02, $00, $00, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $47, $1D, $FF, $6B, $EC, $29, $00, $00, $47, $1D, $FF, $6B, $EC, $29, $00, $00
    db $62, $19, $FF, $6B, $24, $36, $00, $00, $E5, $6E, $FF, $6B, $F3, $7F, $00, $00
    db $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $A0, $31, $FF, $6B, $E8, $66, $00, $00, $A0, $31, $FF, $6B, $09, $6B, $00, $00
    db $0D, $01, $FF, $6B, $9F, $02, $00, $00, $6A, $49, $FF, $6B, $1F, $7C, $00, $00
    db $6A, $49, $FF, $6B, $1F, $7C, $00, $00, $E6, $6E, $FF, $6B, $F3, $7F, $00, $00
    db $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C, $1F, $7C
    db $03, $01, $FF, $6B, $A2, $02, $00, $00, $0C, $05, $FF, $6B, $42, $02, $00, $00
    db $11, $01, $FF, $6B, $F9, $7F, $00, $00, $11, $01, $FF, $6B, $F9, $7F, $00, $00
    db $11, $01, $FF, $6B, $F9, $7F, $00, $00, $11, $01, $FF, $6B, $F9, $7F, $00, $00
    db $28, $7F, $FF, $6B, $F9, $7F, $00, $00
AttrMapData:
    db $00, $00, $FF, $6B, $8F, $7F, $1F, $7C
    db $10, $42, $1F, $7C, $1F, $7C, $1F, $7C
AttrMapDataB:
    db $00, $00, $FF, $02, $17, $00, $DF, $01
    db $00, $00, $FF, $02, $17, $00, $DF, $01, $00, $00, $FF, $02, $17, $00, $DF, $01
    db $00, $00, $5F, $03, $1F, $00, $FF, $01, $00, $00, $5F, $03, $1F, $00, $FF, $01
    db $00, $00, $5F, $03, $1F, $00, $FF, $01, $00, $00, $FF, $7F, $FF, $4B, $FF, $02
    db $00, $00, $FF, $7F, $7F, $03, $B8, $4A, $00, $00, $FF, $7F, $FF, $03, $15, $7E
    db $00, $00, $FF, $4B, $72, $53, $C5, $2A, $00, $00, $FF, $4B, $72, $53, $C5, $2A
    db $00, $00, $FF, $4B, $72, $53, $C5, $2A, $00, $00, $34, $7F, $0C, $5A, $C0, $7D
    db $00, $00, $34, $7F, $0C, $5A, $C0, $7D, $00, $00, $34, $7F, $0C, $5A, $C0, $7D
    db $00, $00, $FF, $03, $72, $53, $37, $7D, $00, $00, $FF, $03, $72, $53, $37, $7D
    db $00, $00, $FF, $03, $72, $53, $37, $7D, $00, $00, $DF, $2D, $B8, $4A, $F2, $7D
    db $00, $00, $E0, $4B, $FF, $02, $C8, $7D, $00, $00, $FF, $02, $B9, $60, $00, $00
    db $00, $00, $1C, $4B, $7B, $3D, $00, $00, $00, $00, $E0, $4B, $3F, $7E, $F3, $64
    db $00, $00, $B2, $56, $37, $1E, $F3, $64, $00, $00, $1C, $4B, $9F, $11, $B1, $20
    db $00, $00, $72, $5F, $37, $7D, $B1, $20, $00, $00, $F5, $6B, $0C, $5A, $C8, $7D
    db $00, $00, $1C, $4B, $F4, $1D, $E9, $00, $00, $00, $FF, $02, $FF, $00, $B1, $00
    db $00, $00, $FF, $4B, $7F, $01, $00, $00, $00, $00, $FF, $4B, $7F, $01, $00, $00
    db $00, $00, $FF, $4B, $B5, $7D, $00, $00, $00, $00, $FF, $4B, $72, $53, $C5, $2A
    db $00, $00, $34, $7F, $0C, $5A, $C0, $7D, $00, $00, $1C, $4B, $F4, $1D, $E9, $00
    db $00, $00, $FF, $5F, $FF, $16, $E9, $00, $00, $00, $FF, $5F, $EB, $6B, $E9, $00
    db $00, $00, $FF, $5F, $DF, $01, $E9, $00, $00, $00, $59, $7F, $37, $7D, $E9, $00
    db $00, $00, $FF, $5F, $BF, $03, $DF, $01, $00, $00, $9F, $33, $91, $69, $BF, $60
    db $00, $00, $D9, $7F, $FF, $47, $37, $7D, $00, $00, $F9, $63, $DF, $01, $15, $00
    db $00, $00, $FD, $7F, $A5, $7E, $0E, $7F, $00, $00, $FF, $7F, $FF, $7F, $BF, $01

; ---------------------------------------------------------------------------
; CustomAttrCheck: intercept for entry 1 (attr map decompression)
; Called instead of MapIDClampForPalette in label17_409e.
; For vanilla rooms + Room $6C+: falls through to MapIDClampForPalette.
; For Room $6B only: pops return address, directly decompresses custom attr
;   data from bank $64 entry 1, then returns to entry 1's caller.
; Size: 22 bytes (+ 10 padding = 32 total, replacing 2 lines of $00)
; When adding more custom rooms with custom attr: extend with cp $6C/jr z etc.
; ---------------------------------------------------------------------------
CustomAttrCheck:
    ld a, [wMapID]             ; 3B — check actual room
    cp $6B                     ; 2B — Room $6B only (has custom attr data)
    jr z, .customAttr          ; 2B — exact match only; $6C+ falls through
    jp MapIDClampForPalette    ; 3B — vanilla + other custom: normal path
.customAttr:
    pop hl                     ; 1B — discard return into entry 1 table lookup
    ld d, $64                  ; 2B — bank $64 (custom layout/attr bank)
    ld e, $01                  ; 2B — entry 1 = CustomAttr_Room6B
    ld hl, $c200               ; 3B — attr decompression destination
    call WaitLCDTransfer       ; 3B — decompress + copy to VRAM
    ret                        ; 1B — return to entry 1's caller (rst $10 / caller bank)

; CustomPalCheck: intercept for entry 0 (palette color loading)
; For Room $6B, redirects HL to merged palette colors instead of source pal_ptr
; ALSO forces B=$08 C=$00 to load ALL 8 palettes (vanilla only loads 4)
CustomPalCheck:
    push af
    ld a, [wMapID]
    cp $6B
    jr z, .customPal
    pop af
    jp LoadPal_46a1             ; normal path: HL=pal_ptr from step entry
.customPal:
    pop af
    ld hl, CustomPaletteColors_6B
    ld b, $08                   ; load ALL 8 palettes (not just first 4)
    ld c, $00                   ; start at palette slot 0
    jp LoadPal_46a1             ; load from merged palette data

; CustomPaletteColors_6B: 64 bytes (8 palettes × 4 colors × 2 bytes)
; Generated by tools/build_combined_tileset.py
; Format: RGB15 LE pairs — [lo, hi] per color, 4 colors per palette
;   Palette 0: from 30:12 pal 1
;   Palette 1: from 30:12 pal 0
;   Palette 2: from 29:01 pal 0
;   Palette 3: from 29:01 pal 3
;   Palette 4: from 30:25 pal 1
;   Palette 5: from 30:10 pal 2
;   Palette 6: from 26:21 pal 0
;   Palette 7: from 26:21 pal 1
CustomPaletteColors_6B:
    db $FF, $7F, $B1, $5A, $8C, $21, $00, $00  ; palette 0
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00  ; palette 1
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00  ; palette 2
    db $00, $7D, $FF, $6B, $42, $7F, $00, $00  ; palette 3
    db $7F, $3F, $DA, $01, $15, $14, $00, $00  ; palette 4
    db $AE, $29, $FF, $6B, $D6, $4A, $00, $00  ; palette 5
    db $EC, $04, $FF, $6B, $3A, $02, $00, $00  ; palette 6
    db $15, $00, $FF, $6B, $9F, $02, $00, $00  ; palette 7
