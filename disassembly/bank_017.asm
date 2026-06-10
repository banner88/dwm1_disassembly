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

    ld hl, $476f
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
    ld a, [$c925]
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
    call Call_017_46a1
    jp Jump_017_4102


Jump_017_4064:
    ld de, $5215
    ld a, [$c93f]
    cp $02
    jr nz, jr_017_4071

    ld de, $5415

jr_017_4071:
    ld a, [$c925]
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
    call Call_017_46a1
    jr jr_017_4102


label17_409e:
    ld a, [wInGateworld]
    or a
    jp nz, Jump_017_40da

    ld hl, $476f
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
    ld a, [$c925]
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
    call Call_000_14cf
    ret


Jump_017_40da:
    ld de, $5215
    ld a, [$c93f]
    cp $02
    jr nz, jr_017_40e7

    ld de, $5415

jr_017_40e7:
    ld a, [$c925]
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
    call Call_000_14cf
    ret


Call_017_4102:
Jump_017_4102:
jr_017_4102:
    ld a, [wIsGBC]
    or a
    ret z

    ld hl, $5655
    ld c, $07
    ld b, $01
    call Call_017_46a1
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
    call Call_000_1aa6
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
    call Call_000_1aa6
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
    call Call_017_46bf
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
    add $fd
    ld l, a
    ld a, h
    adc $62
    ld h, a
    ld a, [$c81f]
    ld c, a
    ld b, $01
    call Call_017_46a1
    call Call_017_4102

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
    call Call_017_4265
    dec b
    jr nz, jr_017_4229

    di
    call Call_000_1aa6
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
    call Call_017_4265
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
    call Call_000_1aa6
    ld a, $00
    ldh [rVBK], a
    ei
    ret


Call_017_4265:
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

    call Call_000_1aa6
    ld a, $80
    ldh [rBCPS], a
    ld hl, $c797
    call Call_017_42ac
    call Call_017_42ac
    call Call_017_42ac
    call Call_017_42ac
    call Call_017_42ac
    call Call_017_42ac
    call Call_017_42ac
    call Call_017_42ac
    ld a, [wBGPalette]
    ld [$c89e], a
    jp Jump_017_4341


Call_017_42ac:
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
    call Call_000_1aa6
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
    call Call_000_1aa6
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
    call Call_000_1aa6
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
    call Call_000_1aa6
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

    call Call_000_1aa6
    ld a, $80
    ldh [rOCPS], a
    ld hl, $c7d7
    call Call_017_4376
    call Call_017_4376
    call Call_017_4376
    call Call_017_4376
    call Call_017_4376
    call Call_017_4376
    call Call_017_4376
    call Call_017_4376
    ld a, [wObj1Palette]
    ld [$c89f], a
    jp Jump_017_440b


Call_017_4376:
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
    call Call_000_1aa6
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
    call Call_000_1aa6
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
    call Call_000_1aa6
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
    call Call_000_1aa6
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
    call Call_000_1bd5
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
    call Call_000_1aa6
    ld a, $80
    ldh [rBCPS], a
    ei
    ld b, $20

jr_017_444c:
    di
    call Call_000_1aa6
    ld a, $ff
    ldh [rBCPD], a
    ld a, $7f
    ldh [rBCPD], a
    ei
    dec b
    jr nz, jr_017_444c

    di
    call Call_000_1aa6
    ld a, $80
    ldh [rOCPS], a
    ei
    ld b, $20

jr_017_4467:
    di
    call Call_000_1aa6
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
    call Call_017_44d8
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
    call Call_017_45bb
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


Call_017_44d8:
    di
    call Call_000_1aa6
    ld a, $80
    ldh [rBCPS], a
    ei
    ld hl, $c797
    call Call_017_4552
    call Call_017_4552
    call Call_017_4552
    call Call_017_4552
    call Call_017_4552
    call Call_017_4552
    call Call_017_4552
    call Call_017_4552
    di
    call Call_000_1aa6
    ld a, $80
    ldh [rOCPS], a
    ei
    ld hl, $c7d7
    call Call_017_4521
    call Call_017_4521
    call Call_017_4521
    call Call_017_4521
    call Call_017_4521
    call Call_017_4521
    call Call_017_4521
    call Call_017_4521
    ret


Call_017_4521:
    call Call_017_452a
    call Call_017_452a
    call Call_017_452a

Call_017_452a:
    ld a, [$c856]
    ld d, a
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    ld de, $0000
    call Call_017_457f
    call Call_017_457f
    call Call_017_457f
    rr b
    rr c
    rr d
    rr e
    di
    call Call_000_1aa6
    ld a, e
    ldh [rOCPD], a
    ld a, d
    ldh [rOCPD], a
    ei
    ret


Call_017_4552:
    call Call_017_455b
    call Call_017_455b
    call Call_017_455b

Call_017_455b:
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    ld de, $0000
    call Call_017_457f
    call Call_017_457f
    call Call_017_457f
    rr b
    rr c
    rr d
    rr e
    di
    call Call_000_1aa6
    ld a, e
    ldh [rBCPD], a
    ld a, d
    ldh [rBCPD], a
    ei
    ret


Call_017_457f:
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


Call_017_45bb:
    di
    call Call_000_1aa6
    ld a, $80
    ldh [rBCPS], a
    ei
    ld hl, $c797
    call Call_017_4635
    call Call_017_4635
    call Call_017_4635
    call Call_017_4635
    call Call_017_4635
    call Call_017_4635
    call Call_017_4635
    call Call_017_4635
    di
    call Call_000_1aa6
    ld a, $80
    ldh [rOCPS], a
    ei
    ld hl, $c7d7
    call Call_017_4604
    call Call_017_4604
    call Call_017_4604
    call Call_017_4604
    call Call_017_4604
    call Call_017_4604
    call Call_017_4604
    call Call_017_4604
    ret


Call_017_4604:
    call Call_017_460d
    call Call_017_460d
    call Call_017_460d

Call_017_460d:
    ld a, [$c856]
    ld d, a
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    ld de, $0000
    call Call_017_4662
    call Call_017_4662
    call Call_017_4662
    rr b
    rr c
    rr d
    rr e
    di
    call Call_000_1aa6
    ld a, e
    ldh [rOCPD], a
    ld a, d
    ldh [rOCPD], a
    ei
    ret


Call_017_4635:
    call Call_017_463e
    call Call_017_463e
    call Call_017_463e

Call_017_463e:
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    ld de, $0000
    call Call_017_4662
    call Call_017_4662
    call Call_017_4662
    rr b
    rr c
    rr d
    rr e
    di
    call Call_000_1aa6
    ld a, e
    ldh [rBCPD], a
    ld a, d
    ldh [rBCPD], a
    ei
    ret


Call_017_4662:
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


Call_017_46a1:
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


Call_017_46bf:
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
    call Call_000_1aa6
    ld a, $80
    ldh [rBCPS], a
    ei
    ld hl, $c797
    ld b, $40

jr_017_46f0:
    di
    call Call_000_1aa6
    ld a, [hl+]
    ldh [rBCPD], a
    ei
    dec b
    jr nz, jr_017_46f0

    di
    call Call_000_1aa6
    ld a, $80
    ldh [rOCPS], a
    ei
    ld b, $40

jr_017_4706:
    di
    call Call_000_1aa6
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
    add $bd
    ld l, a
    ld a, h
    adc $69
    ld h, a
    ld c, $00
    ld b, $08
    call Call_017_46a1
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
    add $fd
    ld l, a
    ld a, h
    adc $6a
    ld h, a
    ld c, $00
    ld b, $01
    call Call_017_46bf
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
    add $0d
    ld l, a
    ld a, h
    adc $6b
    ld h, a
    ld c, $00
    ld b, $01
    call Call_017_46bf
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
    dw $483F  ; $00 Castle
    dw $489D  ; $01 GreatTree
    dw $4925  ; $02 Bazaar
    dw $499D  ; $03 GateHub
    dw $49F5  ; $04 Farm
    dw $4A6D  ; $05 Stable
    dw $4A99  ; $06 ArenaLobby
    dw $4AB3  ; $07 ArenaRooms
    dw $4B07  ; $08 Gate_08
    dw $4B2F  ; $09 StarryShrine
    dw $4B65  ; $0A SecretPassage
    dw $483F  ; $0B 
    dw $4B79  ; $0C Gate_0C
    dw $4B81  ; $0D OldManGate
    dw $483F  ; $0E 
    dw $4B8D  ; $0F 
    dw $4B95  ; $10 CopycatRoom
    dw $483F  ; $11 
    dw $4BA1  ; $12 Library
    dw $4BC1  ; $13 
    dw $483F  ; $14 
    dw $483F  ; $15 
    dw $4BCD  ; $16 MedalManRoom
    dw $4B95  ; $17 
    dw $4BE9  ; $18 Well
    dw $4C0D  ; $19 
    dw $4C15  ; $1A 
    dw $4C1D  ; $1B 
    dw $4C2D  ; $1C 
    dw $4C39  ; $1D 
    dw $4C41  ; $1E 
    dw $4C4D  ; $1F 
    dw $483F  ; $20 
    dw $483F  ; $21 
    dw $483F  ; $22 
    dw $4C5D  ; $23 
    dw $4C69  ; $24 
    dw $4C7D  ; $25 
    dw $4C91  ; $26 
    dw $4CA5  ; $27 
    dw $4CB5  ; $28 
    dw $4CC9  ; $29 
    dw $4CDD  ; $2A 
    dw $4CF1  ; $2B 
    dw $4CFD  ; $2C 
    dw $4D11  ; $2D 
    dw $4D25  ; $2E 
    dw $4D39  ; $2F Room_2F
    dw $4D6D  ; $30 
    dw $4D79  ; $31 
    dw $4D85  ; $32 
    dw $4D91  ; $33 
    dw $4D9D  ; $34 
    dw $4DA9  ; $35 
    dw $4DB5  ; $36 
    dw $4DC1  ; $37 
    dw $4DCD  ; $38 
    dw $4DD9  ; $39 
    dw $4DE5  ; $3A 
    dw $4DF1  ; $3B 
    dw $4DFD  ; $3C 
    dw $4E0D  ; $3D 
    dw $4E19  ; $3E 
    dw $4E25  ; $3F 
    dw $4E31  ; $40 
    dw $4E39  ; $41 
    dw $4E4D  ; $42 Labyrinth
    dw $4E85  ; $43 
    dw $4E91  ; $44 
    dw $4E9D  ; $45 
    dw $4EAD  ; $46 
    dw $4EB9  ; $47 
    dw $4EC9  ; $48 
    dw $4ED5  ; $49 
    dw $4EE1  ; $4A 
    dw $4EED  ; $4B 
    dw $4EF9  ; $4C 
    dw $4F05  ; $4D 
    dw $4F11  ; $4E 
    dw $4F31  ; $4F 
    dw $4F3D  ; $50 
    dw $4F45  ; $51 
    dw $4F4D  ; $52 
    dw $4F55  ; $53 
    dw $4F7D  ; $54 
    dw $4FDB  ; $55 
    dw $5039  ; $56 
    dw $5097  ; $57 
    dw $50F5  ; $58 
    dw $5153  ; $59 
    dw $51B1  ; $5A 
    dw $51B9  ; $5B 
    dw $51C1  ; $5C 
    dw $51C9  ; $5D ArenaBattle
    dw $51E1  ; $5E Room_5E
    dw $4F3D  ; $5F 
    dw $4E4F  ; $60 LabyrinthFinal
    dw $4F57  ; $61 
    dw $4F59  ; $62 
    dw $4F5B  ; $63 
    dw $4F5D  ; $64 
    dw $4E4F  ; $65 
    dw $4E4F  ; $66 
    dw $4E4F  ; $67 
    dw $484F  ; $68 
    dw $4861  ; $69 
    dw $FFFF  ; $6A  (invalid)

; --- Per-room screen/step attribute entries ($4845-$5214, 2512 bytes) ---
; Structure: [ram_addr:2] + step × [attr_idx:1, attr_bank:1, pal_ptr:2]
    db $FF, $FF, $FF, $FF, $87, $48, $FF, $FF, $FF, $FF, $2A, $D9, $00, $3C, $5D, $56
    db $01, $3C, $5D, $56, $02, $3C, $5D, $56, $03, $3C, $5D, $56, $2B, $D9, $04, $3C
    db $5D, $56, $05, $3C, $5D, $56, $05, $3C, $5D, $56, $05, $3C, $5D, $56, $05, $3C
    db $5D, $56, $05, $3C, $5D, $56, $04, $3C, $5D, $56, $04, $3C, $5D, $56, $04, $3C
    db $5D, $56, $2C, $D9, $06, $3C, $5D, $56, $06, $3C, $5D, $56, $06, $3C, $5D, $56
    db $06, $3C, $5D, $56, $06, $3C, $5D, $56, $BD, $48, $D3, $48, $FF, $FF, $FF, $FF
    db $D9, $48, $EB, $48, $FF, $FF, $FF, $FF, $F1, $48, $FF, $48, $FF, $FF, $FF, $FF
    db $05, $49, $17, $49, $FF, $FF, $FF, $FF, $2D, $D9, $07, $3C, $7D, $56, $07, $3C
    db $7D, $56, $07, $3C, $7D, $56, $07, $3C, $7D, $56, $07, $3C, $7D, $56, $2E, $D9
    db $08, $3C, $7D, $56, $2F, $D9, $09, $3C, $7D, $56, $09, $3C, $7D, $56, $09, $3C
    db $7D, $56, $09, $3C, $7D, $56, $30, $D9, $0A, $3C, $7D, $56, $31, $D9, $0B, $3C
    db $7D, $56, $0B, $3C, $7D, $56, $0B, $3C, $7D, $56, $32, $D9, $0C, $3C, $7D, $56
    db $33, $D9, $0D, $3C, $7D, $56, $0D, $3C, $7D, $56, $0E, $3C, $7D, $56, $0E, $3C
    db $7D, $56, $34, $D9, $0F, $3C, $7D, $56, $10, $3C, $7D, $56, $11, $3C, $7D, $56
    db $35, $49, $3F, $49, $4D, $49, $FF, $FF, $5B, $49, $69, $49, $77, $49, $FF, $FF
    db $35, $D9, $12, $3C, $9D, $56, $12, $3C, $9D, $56, $36, $D9, $13, $3C, $9D, $56
    db $13, $3C, $9D, $56, $13, $3C, $9D, $56, $37, $D9, $14, $3C, $9D, $56, $15, $3C
    db $9D, $56, $15, $3C, $9D, $56, $38, $D9, $16, $3C, $9D, $56, $17, $3C, $9D, $56
    db $16, $3C, $9D, $56, $39, $D9, $18, $3C, $9D, $56, $19, $3C, $9D, $56, $19, $3C
    db $9D, $56, $3A, $D9, $1A, $3C, $9D, $56, $1B, $3C, $9D, $56, $1B, $3C, $9D, $56
    db $1C, $3C, $9D, $56, $1C, $3C, $9D, $56, $1D, $3C, $9D, $56, $1D, $3C, $9D, $56
    db $1D, $3C, $9D, $56, $1D, $3C, $9D, $56, $AD, $49, $BF, $49, $FF, $FF, $FF, $FF
    db $D5, $49, $EB, $49, $FF, $FF, $FF, $FF, $3B, $D9, $1E, $3C, $BD, $56, $1F, $3C
    db $BD, $56, $20, $3C, $BD, $56, $21, $3C, $BD, $56, $3C, $D9, $22, $3C, $BD, $56
    db $23, $3C, $BD, $56, $23, $3C, $BD, $56, $24, $3C, $BD, $56, $25, $3C, $BD, $56
    db $3D, $D9, $26, $3C, $BD, $56, $27, $3C, $BD, $56, $28, $3C, $BD, $56, $29, $3C
    db $BD, $56, $29, $3C, $BD, $56, $3E, $D9, $2A, $3C, $BD, $56, $2B, $3C, $BD, $56
    db $05, $4A, $17, $4A, $25, $4A, $FF, $FF, $3B, $4A, $4D, $4A, $5B, $4A, $FF, $FF
    db $3F, $D9, $2C, $3C, $DD, $56, $2C, $3C, $DD, $56, $2C, $3C, $DD, $56, $2C, $3C
    db $DD, $56, $40, $D9, $2D, $3C, $DD, $56, $2D, $3C, $DD, $56, $2D, $3C, $DD, $56
    db $41, $D9, $2E, $3C, $DD, $56, $2E, $3C, $DD, $56, $2F, $3C, $DD, $56, $2F, $3C
    db $DD, $56, $2F, $3C, $DD, $56, $42, $D9, $30, $3C, $DD, $56, $30, $3C, $DD, $56
    db $30, $3C, $DD, $56, $30, $3C, $DD, $56, $43, $D9, $31, $3C, $DD, $56, $31, $3C
    db $DD, $56, $31, $3C, $DD, $56, $44, $D9, $32, $3C, $DD, $56, $32, $3C, $DD, $56
    db $32, $3C, $DD, $56, $32, $3C, $DD, $56, $73, $4A, $7D, $4A, $87, $4A, $45, $D9
    db $33, $3C, $FD, $56, $34, $3C, $FD, $56, $46, $D9, $35, $3C, $FD, $56, $35, $3C
    db $FD, $56, $47, $D9, $36, $3C, $FD, $56, $36, $3C, $FD, $56, $36, $3C, $FD, $56
    db $36, $3C, $FD, $56, $A1, $4A, $A7, $4A, $AD, $4A, $FF, $FF, $48, $D9, $37, $3C
    db $1D, $57, $49, $D9, $38, $3C, $1D, $57, $4A, $D9, $39, $3C, $1D, $57, $C3, $4A
    db $C9, $4A, $EB, $4A, $FF, $FF, $F1, $4A, $FB, $4A, $01, $4B, $FF, $FF, $4B, $D9
    db $3A, $3C, $3D, $57, $4C, $D9, $3B, $3C, $3D, $57, $3C, $3C, $3D, $57, $3D, $3C
    db $3D, $57, $3D, $3C, $3D, $57, $3E, $3C, $3D, $57, $3E, $3C, $3D, $57, $3E, $3C
    db $3D, $57, $3E, $3C, $3D, $57, $4D, $D9, $3F, $3C, $3D, $57, $4E, $D9, $40, $3C
    db $3D, $57, $40, $3C, $3D, $57, $4F, $D9, $41, $3C, $3D, $57, $50, $D9, $42, $3C
    db $3D, $57, $09, $4B, $51, $D9, $43, $3C, $5D, $57, $43, $3C, $5D, $57, $43, $3C
    db $5D, $57, $43, $3C, $5D, $57, $43, $3C, $5D, $57, $43, $3C, $5D, $57, $43, $3C
    db $5D, $57, $43, $3C, $5D, $57, $43, $3C, $5D, $57, $FF, $FF, $3F, $4B, $FF, $FF
    db $FF, $FF, $4D, $4B, $5B, $4B, $FF, $FF, $FF, $FF, $52, $D9, $44, $3C, $7D, $57
    db $44, $3C, $7D, $57, $44, $3C, $7D, $57, $53, $D9, $45, $3C, $7D, $57, $45, $3C
    db $7D, $57, $45, $3C, $7D, $57, $54, $D9, $46, $3C, $7D, $57, $46, $3C, $7D, $57
    db $6D, $4B, $73, $4B, $FF, $FF, $FF, $FF, $55, $D9, $47, $3C, $9D, $57, $56, $D9
    db $48, $3C, $9D, $57, $7B, $4B, $57, $D9, $49, $3C, $BD, $57, $83, $4B, $58, $D9
    db $4A, $3C, $DD, $57, $4A, $3C, $DD, $57, $8F, $4B, $59, $D9, $4B, $3C, $FD, $57
    db $97, $4B, $5A, $D9, $4C, $3C, $1D, $58, $4D, $3C, $1D, $58, $B1, $4B, $FF, $FF
    db $FF, $FF, $FF, $FF, $B7, $4B, $FF, $FF, $FF, $FF, $FF, $FF, $5B, $D9, $4E, $3C
    db $3D, $58, $5C, $D9, $4F, $3C, $3D, $58, $4F, $3C, $3D, $58, $C3, $4B, $5D, $D9
    db $50, $3C, $3D, $58, $50, $3C, $3D, $58, $CF, $4B, $5E, $D9, $51, $3C, $5D, $58
    db $52, $3C, $5D, $58, $52, $3C, $5D, $58, $51, $3C, $5D, $58, $52, $3C, $5D, $58
    db $52, $3C, $5D, $58, $F9, $4B, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $4B, $FF, $FF
    db $FF, $FF, $FF, $FF, $5F, $D9, $53, $3C, $7D, $58, $60, $D9, $54, $3C, $7D, $58
    db $55, $3C, $7D, $58, $55, $3C, $7D, $58, $0F, $4C, $61, $D9, $56, $3C, $9D, $58
    db $17, $4C, $62, $D9, $57, $3C, $BD, $58, $1F, $4C, $63, $D9, $58, $3C, $DD, $58
    db $58, $3C, $DD, $58, $58, $3C, $DD, $58, $2F, $4C, $64, $D9, $59, $3C, $FD, $58
    db $59, $3C, $FD, $58, $3B, $4C, $65, $D9, $5A, $3C, $1D, $59, $43, $4C, $66, $D9
    db $5B, $3C, $1D, $59, $5B, $3C, $1D, $59, $4F, $4C, $67, $D9, $5C, $3C, $3D, $59
    db $5C, $3C, $3D, $59, $5C, $3C, $3D, $59, $5F, $4C, $68, $D9, $5D, $3C, $5D, $59
    db $5D, $3C, $5D, $59, $6B, $4C, $69, $D9, $5E, $3C, $7D, $59, $5E, $3C, $7D, $59
    db $5E, $3C, $7D, $59, $5E, $3C, $7D, $59, $7F, $4C, $6A, $D9, $5F, $3C, $9D, $59
    db $5F, $3C, $9D, $59, $5F, $3C, $9D, $59, $5F, $3C, $9D, $59, $93, $4C, $6B, $D9
    db $60, $3C, $BD, $59, $60, $3C, $BD, $59, $60, $3C, $BD, $59, $60, $3C, $BD, $59
    db $A7, $4C, $6C, $D9, $61, $3C, $DD, $59, $61, $3C, $DD, $59, $61, $3C, $DD, $59
    db $B7, $4C, $6D, $D9, $62, $3C, $FD, $59, $62, $3C, $FD, $59, $62, $3C, $FD, $59
    db $62, $3C, $FD, $59, $CB, $4C, $6E, $D9, $63, $3C, $1D, $5A, $63, $3C, $1D, $5A
    db $63, $3C, $1D, $5A, $63, $3C, $1D, $5A, $DF, $4C, $6F, $D9, $64, $3C, $3D, $5A
    db $64, $3C, $3D, $5A, $64, $3C, $3D, $5A, $64, $3C, $3D, $5A, $F3, $4C, $70, $D9
    db $65, $3C, $5D, $5A, $65, $3C, $5D, $5A, $FF, $4C, $71, $D9, $66, $3C, $7D, $5A
    db $66, $3C, $7D, $5A, $66, $3C, $7D, $5A, $66, $3C, $7D, $5A, $13, $4D, $72, $D9
    db $67, $3C, $9D, $5A, $67, $3C, $9D, $5A, $67, $3C, $9D, $5A, $67, $3C, $9D, $5A
    db $27, $4D, $73, $D9, $68, $3C, $BD, $5A, $68, $3C, $BD, $5A, $68, $3C, $BD, $5A
    db $68, $3C, $BD, $5A, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $45, $4D, $63, $4D
    db $74, $D9, $69, $3C, $DD, $5A, $69, $3C, $DD, $5A, $69, $3C, $DD, $5A, $69, $3C
    db $DD, $5A, $69, $3C, $DD, $5A, $69, $3C, $DD, $5A, $69, $3C, $DD, $5A, $75, $D9
    db $6A, $3C, $DD, $5A, $6A, $3C, $DD, $5A, $6F, $4D, $76, $D9, $6B, $3C, $FD, $5A
    db $6C, $3C, $FD, $5A, $7B, $4D, $77, $D9, $6D, $3C, $1D, $5B, $6E, $3C, $1D, $5B
    db $87, $4D, $78, $D9, $6F, $3C, $3D, $5B, $70, $3C, $3D, $5B, $93, $4D, $79, $D9
    db $71, $3C, $5D, $5B, $72, $3C, $5D, $5B, $9F, $4D, $7A, $D9, $73, $3C, $7D, $5B
    db $74, $3C, $7D, $5B, $AB, $4D, $7B, $D9, $75, $3C, $9D, $5B, $76, $3C, $9D, $5B
    db $B7, $4D, $7C, $D9, $77, $3C, $BD, $5B, $78, $3C, $BD, $5B, $C3, $4D, $7D, $D9
    db $79, $3C, $DD, $5B, $7A, $3C, $DD, $5B, $CF, $4D, $7E, $D9, $7B, $3C, $FD, $5B
    db $7C, $3C, $FD, $5B, $DB, $4D, $7F, $D9, $7D, $3C, $1D, $5C, $7E, $3C, $1D, $5C
    db $E7, $4D, $80, $D9, $7F, $3C, $3D, $5C, $80, $3C, $3D, $5C, $F3, $4D, $81, $D9
    db $81, $3C, $5D, $5C, $82, $3C, $5D, $5C, $FF, $4D, $82, $D9, $83, $3C, $7D, $5C
    db $85, $3C, $7D, $5C, $84, $3C, $7D, $5C, $0F, $4E, $83, $D9, $86, $3C, $9D, $5C
    db $86, $3C, $9D, $5C, $1B, $4E, $84, $D9, $87, $3C, $BD, $5C, $88, $3C, $BD, $5C
    db $27, $4E, $85, $D9, $89, $3C, $DD, $5C, $8A, $3C, $FD, $5C, $33, $4E, $86, $D9
    db $8B, $3C, $1D, $5D, $3B, $4E, $87, $D9, $8C, $3C, $1D, $5D, $8C, $3C, $1D, $5D
    db $8C, $3C, $1D, $5D, $8D, $3C, $1D, $5D, $51, $4E, $7B, $4E, $88, $D9, $8E, $3C
    db $3D, $5D, $8E, $3C, $3D, $5D, $8E, $3C, $3D, $5D, $8E, $3C, $3D, $5D, $8E, $3C
    db $3D, $5D, $8E, $3C, $3D, $5D, $8E, $3C, $3D, $5D, $8E, $3C, $3D, $5D, $8E, $3C
    db $3D, $5D, $8E, $3C, $3D, $5D, $89, $D9, $8F, $3C, $5D, $5D, $8F, $3C, $5D, $5D
    db $87, $4E, $8A, $D9, $90, $3C, $7D, $5D, $91, $3C, $7D, $5D, $93, $4E, $8B, $D9
    db $92, $3C, $9D, $5D, $93, $3C, $9D, $5D, $9F, $4E, $8C, $D9, $94, $3C, $BD, $5D
    db $95, $3C, $BD, $5D, $94, $3C, $BD, $5D, $AF, $4E, $8D, $D9, $96, $3C, $DD, $5D
    db $97, $3C, $DD, $5D, $BB, $4E, $8E, $D9, $98, $3C, $FD, $5D, $98, $3C, $FD, $5D
    db $99, $3C, $FD, $5D, $CB, $4E, $8F, $D9, $9A, $3C, $1D, $5E, $9B, $3C, $1D, $5E
    db $D7, $4E, $90, $D9, $9C, $3C, $3D, $5E, $9D, $3C, $3D, $5E, $E3, $4E, $91, $D9
    db $9E, $3C, $5D, $5E, $9F, $3C, $5D, $5E, $EF, $4E, $92, $D9, $A0, $3C, $7D, $5E
    db $A1, $3C, $7D, $5E, $FB, $4E, $93, $D9, $A2, $3C, $9D, $5E, $A3, $3C, $9D, $5E
    db $07, $4F, $94, $D9, $A4, $3C, $BD, $5E, $A5, $3C, $BD, $5E, $21, $4F, $FF, $FF
    db $FF, $FF, $FF, $FF, $2B, $4F, $FF, $FF, $FF, $FF, $FF, $FF, $95, $D9, $A6, $3C
    db $DD, $5E, $A7, $3C, $DD, $5E, $96, $D9, $A8, $3C, $DD, $5E, $33, $4F, $97, $D9
    db $A9, $3C, $FD, $5E, $AA, $3C, $FD, $5E, $3F, $4F, $98, $D9, $AB, $3C, $1D, $5F
    db $47, $4F, $98, $D9, $AC, $3C, $3D, $5F, $4F, $4F, $98, $D9, $AD, $3C, $5D, $5F
    db $5F, $4F, $65, $4F, $6B, $4F, $71, $4F, $77, $4F, $98, $D9, $AE, $3C, $7D, $5F
    db $98, $D9, $AF, $3C, $7D, $5F, $98, $D9, $B0, $3C, $7D, $5F, $98, $D9, $B1, $3C
    db $7D, $5F, $98, $D9, $B2, $3C, $7D, $5F, $95, $4F, $9B, $4F, $A1, $4F, $FF, $FF
    db $A7, $4F, $AD, $4F, $B3, $4F, $FF, $FF, $B9, $4F, $BF, $4F, $C5, $4F, $FF, $FF
    db $98, $D9, $B3, $3C, $9D, $5F, $98, $D9, $B4, $3C, $9D, $5F, $98, $D9, $B5, $3C
    db $9D, $5F, $98, $D9, $B6, $3C, $9D, $5F, $98, $D9, $B7, $3C, $9D, $5F, $98, $D9
    db $B8, $3C, $9D, $5F, $98, $D9, $B9, $3C, $9D, $5F, $98, $D9, $BA, $3C, $9D, $5F
    db $98, $D9, $BB, $3C, $9D, $5F, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $08, $02
    db $00, $80, $00, $00, $00, $FF, $F3, $4F, $F9, $4F, $FF, $4F, $FF, $FF, $05, $50
    db $0B, $50, $11, $50, $FF, $FF, $17, $50, $1D, $50, $23, $50, $FF, $FF, $98, $D9
    db $BC, $3C, $BD, $5F, $98, $D9, $BD, $3C, $BD, $5F, $98, $D9, $BE, $3C, $BD, $5F
    db $98, $D9, $BF, $3C, $BD, $5F, $98, $D9, $C0, $3C, $BD, $5F, $98, $D9, $C1, $3C
    db $BD, $5F, $98, $D9, $C2, $3C, $BD, $5F, $98, $D9, $C3, $3C, $BD, $5F, $98, $D9
    db $C4, $3C, $BD, $5F, $FF, $FF, $FF, $FF, $FF, $FF, $06, $06, $00, $80, $00, $00
    db $00, $FF, $FF, $FF, $51, $50, $57, $50, $5D, $50, $FF, $FF, $63, $50, $69, $50
    db $6F, $50, $FF, $FF, $75, $50, $7B, $50, $81, $50, $FF, $FF, $98, $D9, $C5, $3C
    db $DD, $5F, $98, $D9, $C6, $3C, $DD, $5F, $98, $D9, $C7, $3C, $DD, $5F, $98, $D9
    db $C8, $3C, $DD, $5F, $98, $D9, $C9, $3C, $DD, $5F, $98, $D9, $CA, $3C, $DD, $5F
    db $98, $D9, $CB, $3C, $DD, $5F, $98, $D9, $CC, $3C, $DD, $5F, $98, $D9, $CD, $3C
    db $DD, $5F, $FF, $FF, $03, $03, $00, $80, $00, $00, $00, $FF, $FF, $FF, $FF, $FF
    db $FF, $FF, $AF, $50, $B5, $50, $BB, $50, $FF, $FF, $C1, $50, $C7, $50, $CD, $50
    db $FF, $FF, $D3, $50, $D9, $50, $DF, $50, $FF, $FF, $98, $D9, $CE, $3C, $FD, $5F
    db $98, $D9, $CF, $3C, $FD, $5F, $98, $D9, $D0, $3C, $FD, $5F, $98, $D9, $D1, $3C
    db $FD, $5F, $98, $D9, $D2, $3C, $FD, $5F, $98, $D9, $D3, $3C, $FD, $5F, $98, $D9
    db $D4, $3C, $FD, $5F, $98, $D9, $D5, $3C, $FD, $5F, $98, $D9, $D6, $3C, $FD, $5F
    db $FF, $FF, $FF, $FF, $FF, $FF, $01, $06, $00, $80, $00, $00, $00, $FF, $FF, $FF
    db $0D, $51, $13, $51, $19, $51, $FF, $FF, $1F, $51, $25, $51, $2B, $51, $FF, $FF
    db $31, $51, $37, $51, $3D, $51, $FF, $FF, $98, $D9, $D7, $3C, $1D, $60, $98, $D9
    db $D8, $3C, $1D, $60, $98, $D9, $D9, $3C, $1D, $60, $98, $D9, $DA, $3C, $1D, $60
    db $98, $D9, $DB, $3C, $1D, $60, $98, $D9, $DC, $3C, $1D, $60, $98, $D9, $DD, $3C
    db $1D, $60, $98, $D9, $DE, $3C, $1D, $60, $98, $D9, $DF, $3C, $1D, $60, $FF, $FF
    db $FF, $FF, $FF, $FF, $FF, $03, $06, $00, $80, $00, $00, $00, $FF, $FF, $6B, $51
    db $71, $51, $77, $51, $FF, $FF, $7D, $51, $83, $51, $89, $51, $FF, $FF, $8F, $51
    db $95, $51, $9B, $51, $FF, $FF, $98, $D9, $E0, $3C, $3D, $60, $98, $D9, $E1, $3C
    db $3D, $60, $98, $D9, $E2, $3C, $3D, $60, $98, $D9, $E3, $3C, $3D, $60, $98, $D9
    db $E4, $3C, $3D, $60, $98, $D9, $E5, $3C, $3D, $60, $98, $D9, $E6, $3C, $3D, $60
    db $98, $D9, $E7, $3C, $3D, $60, $98, $D9, $E8, $3C, $3D, $60, $FF, $FF, $FF, $FF
    db $FF, $FF, $FF, $FF, $08, $06, $00, $80, $00, $00, $00, $FF, $B3, $51, $98, $D9
    db $E9, $3C, $5D, $60, $BB, $51, $98, $D9, $EA, $3C, $7D, $60, $C3, $51, $98, $D9
    db $EB, $3C, $9D, $60, $CB, $51, $99, $D9, $EC, $3C, $BD, $60, $ED, $3C, $BD, $60
    db $ED, $3C, $BD, $60, $ED, $3C, $BD, $60, $ED, $3C, $BD, $60, $E3, $51, $9A, $D9
    db $EE, $3C, $DD, $60, $EE, $3C, $DD, $60, $EE, $3C, $DD, $60, $EE, $3C, $DD, $60
    db $FD, $60, $1D, $61, $3D, $61, $5D, $61, $7D, $61, $9D, $61, $BD, $61, $DD, $61
    db $FD, $61, $1D, $62, $3D, $62, $5D, $62, $7D, $62, $9D, $62, $BD, $62, $DD, $62

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
    db $EE, $04, $FF, $6B, $7A, $02, $00, $00, $BD, $01, $FF, $6B, $5F, $03, $00, $00
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
    db $AA, $0D, $FF, $6B, $E0, $7E, $00, $00, $33, $46, $BE, $77, $F8, $5E, $44, $08
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
    db $28, $7F, $FF, $6B, $F9, $7F, $00, $00, $00, $00, $FF, $6B, $8F, $7F, $1F, $7C
    db $10, $42, $1F, $7C, $1F, $7C, $1F, $7C, $00, $00, $FF, $02, $17, $00, $DF, $01
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
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
