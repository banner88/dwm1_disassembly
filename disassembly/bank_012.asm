; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $012", ROMX[$4000], BANK[$12]

INCLUDE "items.inc"

    db $12 ; Bank number

    ; Cross-bank dispatch table (1 entries)
    ; Called via: ld hl, $12XX / rst $10
    dw label12_4003                   ; Entry 0

label12_4003:
    ld a, [$c8ef]
    rst $00

    ;function pointers
    dw label12_4027
    dw label12_4027
    dw label12_4027
    db $2d, $44
    dw label12_4027
    dw label12_4027
    dw label12_4027
    dw label12_4027
    db $61, $60
    db $42, $68
    db $fe, $6a
    dw label12_4027
    dw label12_4027
    dw label12_4027
    dw label12_4027
    dw label12_4027

label12_4027:
    ret


ReadItem_4028:
    ld a, [hl]
    add $04
    ld [hl+], a
    ld a, [hl]
    adc $00
    ld [hl-], a
    ld a, [hl]
    and $f8
    ld [hl], a
    ret


SaveItem_4035:
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


LoadItem_4044:
    ld a, [$c909]
    add l
    ld l, a
    ld a, [$c90a]
    adc h
    and $03
    ld h, a
    ld a, [$c90a]
    and $fc
    or h
    ld h, a
    ret


LoadItem_4058:
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ret


SaveItem_4061:
    push bc
    ld b, l
    ld a, l
    and $e0
    ld l, a
    call LoadItem_4044
    ld a, b
    and $1f
    jr z, jr_012_4076

    ld b, a

jr_012_4070:
    call SaveItem_4035
    dec b
    jr nz, jr_012_4070

jr_012_4076:
    pop bc
    ret


    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    call SaveItem_4061
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a

jr_012_4087:
    ld a, [de]
    inc de
    cp $d9
    ret z

    cp $d8
    jr nz, jr_012_40ac

    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
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
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    jr jr_012_4087

jr_012_40ac:
    call Write_gfx_tile
    call SaveItem_4035
    jr jr_012_4087

ReadPtrFromDE:
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    call LoadItem_4058
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a

jr_012_40c3:
    ld a, [de]
    inc de
    cp $d9
    ret z

    cp $d8
    jr nz, jr_012_40e2

    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    jr jr_012_40c3

jr_012_40e2:
    ld [hl+], a
    jr jr_012_40c3

GetScreenPos:
    ld a, [$c909]
    ld l, a
    ld a, [$c90a]
    ld h, a
    ld de, $c500
    ld c, $12

jr_012_40f2:
    ld b, $20
    push hl

jr_012_40f5:
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
    jr nz, jr_012_40f5

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
    jr nz, jr_012_40f2

    ret


LoadItem_411a:
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


SaveItem_4153:
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


    ld [$c180], a
    ld a, $f0
    ld [$c181], a
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
    ret


SetItem_41ef:
    ld hl, $c500
    ld de, $c300
    ld bc, $0200

jr_012_41f8:
    ld a, [de]
    inc de
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, jr_012_41f8

    ld de, $c1c0
    ld c, $02

jr_012_4205:
    ld b, $14

jr_012_4207:
    ld a, [de]
    inc de
    ld [hl+], a
    dec b
    jr nz, jr_012_4207

    ld a, e
    add $0c
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld a, l
    add $0c
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec c
    jr nz, jr_012_4205

    ret


SetItem_4221:
    ld hl, $c500
    ld bc, $0240

jr_012_4227:
    ld a, $e0
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, jr_012_4227

    ret


    ld hl, $9800
    ld bc, $0400

jr_012_4236:
    ld a, $e0
    call Write_gfx_tile_and_inc_HL
    dec bc
    ld a, b
    or c
    jr nz, jr_012_4236

    ret


LoadItem_4241:
    ld a, c
    ld [$c8e1], a
    inc de
    inc de
    ld a, [$c825]
    or a
    jp nz, Jump_012_42a8

    ld a, [wJoypad_Current]
    bit 5, a
    jr z, jr_012_426e

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
    jr c, jr_012_428c

    ld a, c
    dec a
    jr jr_012_428c

jr_012_426e:
    ld a, [wJoypad_Current]
    bit 4, a
    jr z, jr_012_42a8

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
    jr c, jr_012_428c

    ld a, $00

jr_012_428c:
    ld [hl-], a
    dec c
    cp c
    jr nz, jr_012_42eb

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
    jr z, jr_012_42eb

    dec a
    cp [hl]
    jr nc, jr_012_42eb

    ld [hl], a
    jr jr_012_42eb

Jump_012_42a8:
jr_012_42a8:
    push bc
    push de
    push hl
    call LoadItem_4387
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
    jr nz, jr_012_42ca

    ld a, [$c8e1]
    inc a
    ld b, a

FuncItem_42ca:
jr_012_42ca:
    res 7, [hl]
    ld a, [wJoypad_Current]
    bit 6, a
    jr z, jr_012_42dc

    ld a, [hl]
    dec a
    cp b
    jr c, jr_012_42ea

    dec b
    ld a, b
    jr jr_012_42ea

jr_012_42dc:
    ld a, [wJoypad_Current]
    bit 7, a
    jr z, jr_012_42f3

    ld a, [hl]
    inc a
    cp b
    jr c, jr_012_42ea

    ld a, $00

jr_012_42ea:
    ld [hl], a

jr_012_42eb:
    xor a
    ld [wCursorBlinkTimer], a
    push hl
    push de
    pop de
    pop hl

jr_012_42f3:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_012_42fc

    set 7, [hl]

jr_012_42fc:
    ld a, [hl]
    call FuncItem_4328
    ret


    res 7, [hl]
    ld a, [wJoypad_Current]
    bit 5, a
    jr z, jr_012_4313

    ld a, [hl]
    dec a
    cp b
    jr c, jr_012_42ea

    dec b
    ld a, b
    jr jr_012_42ea

jr_012_4313:
    ld a, [wJoypad_Current]
    bit 4, a
    jr z, jr_012_42f3

    ld a, [hl]
    inc a
    cp b
    jr c, jr_012_42ea

    ld a, $00
    jr jr_012_42ea

ClrItem_4323:
    xor a
    ld [wCursorBlinkTimer], a
    ret


FuncItem_4328:
    ld c, a
    bit 7, a
    jr nz, jr_012_433d

    ld a, [wCursorBlinkTimer]
    and $0f
    push af
    ld a, [wCursorBlinkTimer]
    inc a
    ld [wCursorBlinkTimer], a
    pop af
    ld a, c
    ret nz

jr_012_433d:
    ld c, a
    ld b, $00

jr_012_4340:
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
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    push de
    push bc
    call SaveItem_4061
    pop bc
    pop de
    ld a, c
    and $7f
    cp b
    ld a, $e0
    jr nz, jr_012_4370

    ld a, $e9
    bit 7, c
    jr nz, jr_012_4370

    ld a, [wCursorBlinkTimer]
    bit 4, a
    ld a, $e0
    jr nz, jr_012_4370

    ld a, $e8

jr_012_4370:
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
    inc b
    jr jr_012_4340

LoadItem_4387:
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
    call SaveItem_4061
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


ReadItem_43c0:
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
    jr nc, jr_012_43d9

    ld a, $e7

jr_012_43d9:
    ld [hl-], a
    pop bc
    jr nc, jr_012_43e1

    ld a, [bc]
    add $f1
    ld [hl], a

jr_012_43e1:
    pop af

FuncItem_43e2:
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
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    push de
    push bc
    call SaveItem_4061
    pop bc
    pop de
    ld a, $e9
    bit 7, c
    jr nz, jr_012_440d

    ld a, [wCursorBlinkTimer]
    bit 4, a
    ld a, $e0
    jr nz, jr_012_440d

    ld a, $e8

jr_012_440d:
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


AddCursorOffset:
    ld a, [$c8f0]
    add l
    ld l, a
    ld a, [$c8f1]
    adc h
    ld h, a
    call TextBankDispatch
    ret


    ld a, [$c905]
    rst $00
    dec sp
    ld b, h
    or h
    ld b, h
    db $e4
    ld b, h
    ld b, b
    ld b, l
    ld d, b
    ld b, l
    ld hl, $ffb7
    call ReadItem_4028
    ld hl, $ffbb
    call ReadItem_4028
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ldh a, [$bb]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ldh a, [$b7]
    rrca
    rrca
    rrca
    add l
    ld l, a
    ld a, h
    adc $98
    ld h, a
    ld a, h
    and $03
    or $98
    ld h, a
    ld a, l
    ld [$c909], a
    ld a, h
    ld [$c90a], a
    call SetItem_41ef
    ld de, MenuBorderRightEdge
    ld hl, $8800
    call WaitDMATransfer
    ld a, $02
    ld [$c822], a
    ld a, $44
    ld [$c823], a
    ld hl, $9600
    ld de, $0501
    call LoadItem_411a
    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    call ClrItem_4323
    ld a, $60
    ldh [$d4], a
    ld hl, $0105
    rst $10
    ld hl, $c905
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $c905
    inc [hl]
    xor a
    ld [$c8ec], a
    call SetItem_41ef
    call SetItem_44cb
    call GetScreenPos
    ret


SetItem_44cb:
    ld de, $710c
    call ReadPtrFromDE
    ld de, $2e07
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $4532
    ld a, [wMenu_selection]
    call FuncItem_43e2
    ret


    ld de, $4532
    ld hl, wMenu_selection
    ld b, $06
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    and $0a
    jr z, jr_012_4500

    ld hl, $c905
    inc [hl]
    ld hl, $c905
    inc [hl]
    jr jr_012_4531

jr_012_4500:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_012_4531

    ld a, $59
    call PlaySoundEffect
    ld hl, $c905
    inc [hl]
    xor a
    ld [$c906], a
    ld hl, wMenu_selection
    set 7, [hl]
    ld hl, wOPTN_and_Item_selection
    ld bc, $0007
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    jr jr_012_4531

jr_012_4531:
    ret


    ld hl, $6100
    nop
    and c
    nop
    pop hl
    nop
    ld hl, $6101
    ld bc, $ffff
    ld a, [wMenu_selection]
    rst $00
    adc b
    ld b, l
    dec hl
    ld c, h
    xor a
    ld d, h
    add $59
    db $ec
    ld e, l
    ld d, b
    ld b, l
    call SetItem_41ef
    ld de, $2e07
    call ReadPtrFromDE
    call GetScreenPos
    call UpdateOAMSprites
    ld hl, $c13c
    ld de, $c1c0
    call FuncItem_457f
    ld hl, $c150
    ld de, $c1e0
    call FuncItem_457f
    ld a, $80
    ldh [$d3], a
    ld hl, wGameState
    res 4, [hl]
    xor a
    ld [$c905], a
    ret


FuncItem_457f:
    ld b, $14

jr_012_4581:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_012_4581

    ret


    ld a, [$c906]
    rst $00
    cp d
    ld b, l
    dec bc
    ld b, [hl]
    ld c, b
    ld b, a
    or a
    ld b, a
    jp nz, $ea47

    ld b, a
    ld b, c
    ld c, b
    ld h, h
    ld c, b
    adc b
    ld c, b
    xor e
    ld c, b
    ld a, [bc]
    ld c, c
    ld a, [de]
    ld c, c
    ld b, d
    ld c, c
    sub e
    ld c, c
    and h
    ld c, c
    add hl, de
    ld c, d
    adc a
    ld c, d
    sbc d
    ld c, d
    db $c2, $4a, $1e

    ld c, e
    ld l, e
    ld c, e
    adc a
    ld c, e
    cp d
    ld c, e
    ld a, [$ca8d]
    cp $00
    jr z, jr_012_45ec

    cp $01
    jr nz, jr_012_45e1

    ld hl, $0004
    call AddCursorOffset
    call SetItem_4cb7
    or a
    jr nz, jr_012_45d7

    ld a, $07
    ld [$c906], a
    ret


jr_012_45d7:
    xor a
    ld [$c8dd], a
    ld a, $0a
    ld [$c906], a
    ret


jr_012_45e1:
    ld hl, $0003
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


Jump_012_45ec:
jr_012_45ec:
    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $06e1
    call TextBankDispatch
    ld a, $01
    ld [$c905], a
    ret


    ld a, [$c825]
    or a
    ret nz

    call LoadItem_4682
    call SetItem_4643
    call CallItem_4621
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


CallItem_4621:
    call SetItem_41ef
    call SetItem_44cb
    ld de, $71aa
    call ReadPtrFromDE
    ld de, $759a
    call ReadPtrFromDE
    call LoadItem_46fd
    call ClrItem_4323
    ld de, $47af
    ld a, [wOPTN_and_Item_selection]
    call FuncItem_43e2
    ret


SetItem_4643:
    ld hl, $8800
    ld a, $01
    call FuncItem_465c
    ld hl, $8840
    ld a, $02
    call FuncItem_465c
    ld hl, $8880
    ld a, $03
    call FuncItem_465c
    ret


FuncItem_465c:
    ld b, a
    ld a, [$ca8d]
    cp b
    jr nc, jr_012_4672

    ld b, $20

jr_012_4665:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_012_4665

    ret


jr_012_4672:
    push hl
    ld a, b
    dec a
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    pop hl
    call SaveItem_4153
    ret


LoadItem_4682:
    ld a, [wOPTN_and_Item_selection]
    and $7f
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]

SaveItem_4691:
    push af
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $9650
    call SaveItem_4153
    pop af
    ld hl, $cacc
    call GetMonsterDataPtr
    ld a, [hl]
    ld hl, $9690
    and $01
    add $a7
    ld [$c180], a
    ld a, $f0
    ld [$c181], a
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
    ret


LoadItem_46fd:
    ld a, [wOPTN_and_Item_selection]
    and $7f
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]

SaveItem_470c:
    push af
    ld hl, $cb0c
    call GetMonsterDataPtr
    ld c, [hl]
    ld b, $00
    ld hl, $016a
    call LoadItem_4058
    ld a, $de
    ld [hl+], a
    ld a, $e0
    ld [hl+], a
    ld a, $e0
    ld [hl-], a
    call SetItem_601b
    pop af
    ld hl, $cac1
    call GetMonsterDataPtr
    ld a, [hl]
    cp $02
    jr nz, jr_012_473e

    ld hl, $0172
    call LoadItem_4058
    ld a, $e3
    ld [hl], a
    ret


jr_012_473e:
    ld hl, $0172
    call LoadItem_4058
    ld a, $e0
    ld [hl], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld de, $47af
    ld hl, wOPTN_and_Item_selection
    ld a, [$ca8d]
    ld b, a
    ld a, [hl]
    push af
    call FuncItem_42ca
    pop af
    ld hl, wOPTN_and_Item_selection
    cp [hl]
    jr z, jr_012_4772

    call LoadItem_4682
    ld de, $759a
    call ReadPtrFromDE
    call LoadItem_46fd
    call GetScreenPos

jr_012_4772:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_4799

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    jr jr_012_47ae

jr_012_4799:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_47ae

    ld a, $59
    call PlaySoundEffect
    xor a
    ld [wPLAN_selection], a
    ld hl, $c906
    inc [hl]

Jump_012_47ae:
jr_012_47ae:
    ret


    ld l, [hl]
    nop
    xor [hl]
    nop
    xor $00
    rst $38
    rst $38
    ld hl, $0005
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    call SetItem_47d7
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


SetItem_47d7:
    ld de, $7b42
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $483b
    ld a, [wPLAN_selection]
    call FuncItem_43e2
    ret


    ld de, $483b
    ld hl, wPLAN_selection
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_4813

    ld hl, $5605
    rst $10
    call CallItem_4621
    call GetScreenPos
    ld hl, $0003
    call AddCursorOffset
    ld a, $02
    ld [$c906], a
    jr jr_012_483a

jr_012_4813:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_483a

    ld a, $59
    call PlaySoundEffect
    ld a, [wPLAN_selection]
    cp $81
    jr z, jr_012_4836

    xor a
    ld [$c90d], a
    ld [$c90e], a
    ld a, $08
    ld [$c906], a
    jp Jump_012_483a


jr_012_4836:
    ld hl, $c906
    inc [hl]

Jump_012_483a:
jr_012_483a:
    ret


    ld hl, $6101
    ld bc, $ffff
    ld a, [wOPTN_and_Item_selection]
    and $7f
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $ff
    ld hl, $0105
    rst $10
    ld hl, $0103
    rst $10
    ld hl, $0006
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    ret


    ld hl, $ca8e
    ld a, l
    ld [$c930], a
    ld a, h
    ld [$c931], a
    ld a, [wOPTN_and_Item_selection]
    and $7f
    ld [$c932], a
    ld a, [$ca8d]
    ld [$c933], a
    ld hl, $0702
    rst $10
    ld a, $01
    ld [$c8ec], a
    ret


    ld a, [wOPTN_and_Item_selection]
    and $80
    ld b, a
    ld a, [$c934]
    or b
    ld [wOPTN_and_Item_selection], a
    ld de, MenuBorderRightEdge
    ld hl, $8800
    call WaitDMATransfer
    ld a, $02
    ld [$c822], a
    ld a, $44
    ld [$c823], a
    ld hl, $9600
    ld de, $0501
    call LoadItem_411a
    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    call LoadItem_4682
    call SetItem_4643
    ld hl, $5605
    rst $10
    call CallItem_4621
    call SetItem_47d7
    call GetScreenPos
    ld hl, $0005
    call AddCursorOffset
    ld a, $05
    ld [$c906], a
    xor a
    ld [$c8ec], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $0007
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    call SetItem_492f
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


SetItem_492f:
    ld de, $6f54
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $498d
    ld a, [$c8dd]
    call FuncItem_43e2
    ret


    ld de, $498d
    ld hl, $c8dd
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_4974

jr_012_4954:
    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    jr jr_012_498c

jr_012_4974:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_498c

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8dd]
    cp $81
    jr z, jr_012_4954

    ld hl, $c906
    inc [hl]

Jump_012_498c:
jr_012_498c:
    ret


    ld hl, $6101
    ld bc, $ffff
    call SetItem_4cb7
    call SetItem_4ce5
    ld hl, $0008
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call LoadItem_49e5
    call LoadItem_4d5d
    call CallItem_49ba
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


CallItem_49ba:
    call SetItem_41ef
    call SetItem_44cb
    ld de, $759a
    call ReadPtrFromDE
    call LoadItem_49ff
    ld de, $71f4
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $4e26
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadItem_43c0
    call SetItem_492f
    ret


LoadItem_49e5:
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
    call SaveItem_4691
    ret


LoadItem_49ff:
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
    call SaveItem_470c
    ret


    ld a, [$c825]
    or a
    ret nz

    ld de, $4e26
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    ld a, [hl]
    push af
    call LoadItem_4241
    pop af
    ld hl, $c8e2
    cp [hl]
    jr z, jr_012_4a42

    call LoadItem_49e5
    call LoadItem_49ff
    call GetScreenPos

jr_012_4a42:
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_012_4a55

    call LoadItem_4d5d
    call LoadItem_49e5
    call LoadItem_49ff
    call GetScreenPos

jr_012_4a55:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_4a79

    ld hl, $5605
    rst $10
    call SetItem_41ef
    call SetItem_44cb
    call SetItem_492f
    call GetScreenPos
    ld hl, $0007
    call AddCursorOffset
    ld a, $0c
    ld [$c906], a
    jr jr_012_4a8e

jr_012_4a79:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_4a8e

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]
    xor a
    ld [wPLAN_selection], a

Jump_012_4a8e:
jr_012_4a8e:
    ret


    ld hl, $0009
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    call SetItem_4aaf
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


SetItem_4aaf:
    ld de, $7b42
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $4b18
    ld a, [wPLAN_selection]
    call FuncItem_43e2
    ret


    ld de, $4b18
    ld hl, wPLAN_selection
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_4af1

    ld hl, $5605
    rst $10
    call LoadItem_49e5
    call LoadItem_4d5d
    call CallItem_49ba
    call GetScreenPos
    ld hl, $0008
    call AddCursorOffset
    ld a, $0f
    ld [$c906], a
    jr jr_012_4b17

jr_012_4af1:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_4b17

    ld a, $59
    call PlaySoundEffect
    ld a, [wPLAN_selection]
    cp $81
    jr z, jr_012_4b13

    xor a
    ld [$c90d], a
    ld [$c90e], a
    ld a, $15
    ld [$c906], a
    jr jr_012_4b17

jr_012_4b13:
    ld hl, $c906
    inc [hl]

Jump_012_4b17:
jr_012_4b17:
    ret


    ld hl, $6101
    ld bc, $ffff
    ld a, [$ca8e]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
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
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c190
    call Copy4Bytes
    pop af
    ld [$ca8e], a
    ld hl, $0105
    rst $10
    ld hl, $0103
    rst $10
    ld hl, $000a
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    ret


    ld hl, $c0d8
    ld a, l
    ld [$c930], a
    ld a, h
    ld [$c931], a
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    ld a, a
    ld [$c932], a
    ld a, [$c8e9]
    ld [$c933], a
    ld hl, $0702
    rst $10
    ld a, $01
    ld [$c8ec], a
    ret


    ld a, [$c8e2]
    and $80
    ld b, a
    ld a, [$c934]
    and $03
    or b
    ld [$c8e2], a
    ld a, [$c934]
    srl a
    srl a
    ld [$c8e3], a
    ld de, MenuBorderRightEdge
    ld hl, $8800
    call WaitDMATransfer
    ld a, $02
    ld [$c822], a
    ld a, $44
    ld [$c823], a
    ld hl, $9600
    ld de, $0501
    call LoadItem_411a
    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    call SetItem_4cb7
    call SetItem_4ce5
    call LoadItem_4d5d
    ld hl, $5605
    rst $10
    call LoadItem_49e5
    call CallItem_49ba
    call SetItem_4aaf
    call GetScreenPos
    ld hl, $0009
    call AddCursorOffset
    ld a, $12
    ld [$c906], a
    xor a
    ld [$c8ec], a
    ret


    ld a, [$c906]
    rst $00
    ld l, l
    ld c, h
    rra
    ld c, l
    or c
    ld c, l
    ld [hl-], a
    ld c, [hl]
    dec a
    ld c, [hl]
    ld h, l
    ld c, [hl]
    cp h
    ld c, [hl]
    dec de
    ld c, a
    ccf
    ld c, a
    ld l, d
    ld c, a
    push de
    ld c, a
    push hl
    ld c, a
    dec c
    ld d, b
    ld e, a
    ld d, b
    ld l, l
    ld d, b
    xor [hl]
    ld d, b
    jr nz, @+$53

    dec hl
    ld d, c
    ld d, e
    ld d, c
    xor e
    ld d, c
    db $10
    ld d, d
    inc [hl]
    ld d, d
    ld e, a
    ld d, d
    call $d852
    ld d, d
    add hl, sp
    ld d, e
    and c
    ld d, e
    xor h
    ld d, e
    call nc, TilemapRotateWrite
    ld d, h
    ld d, b
    ld d, h
    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    call SetItem_4cb7
    or a
    jr nz, jr_012_4c92

    ld hl, $000c
    call AddCursorOffset
    ld a, $07
    ld [$c906], a
    ret


jr_012_4c92:
    ld a, [$ca8d]
    cp $03
    jr nz, jr_012_4ca9

    ld hl, $000d
    call AddCursorOffset
    xor a
    ld [$c8dd], a
    ld a, $0a
    ld [$c906], a
    ret


jr_012_4ca9:
    call SetItem_4ce5
    ld hl, $000b
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


SetItem_4cb7:
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_012_4cbe:
    push de
    ld a, [de]
    or a
    jr z, jr_012_4cd4

    cp $02
    jr z, jr_012_4cd4

    ld a, e
    add $63
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld a, [de]
    or a
    jr nz, jr_012_4cd4

    inc c

jr_012_4cd4:
    pop de
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    dec b
    jr nz, jr_012_4cbe

    ld a, c
    ld [$c8e9], a
    ret


SetItem_4ce5:
    ld hl, $c0d8
    ld bc, $0014
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_012_4cfa:
    push de
    ld a, [de]
    or a
    jr z, jr_012_4d11

    cp $02
    jr z, jr_012_4d11

    ld a, e
    add $63
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld a, [de]
    or a
    jr nz, jr_012_4d11

    ld [hl], c
    inc hl

jr_012_4d11:
    pop de
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    inc c
    dec b
    jr nz, jr_012_4cfa

    ret


    ld a, [$c825]
    or a
    ret nz

    call LoadItem_49e5
    call LoadItem_4d5d
    call CallItem_4d32
    ld hl, $c906
    inc [hl]
    ret


CallItem_4d32:
    call SetItem_41ef
    call SetItem_44cb
    ld de, $759a
    call ReadPtrFromDE
    call LoadItem_49ff
    ld de, $71f4
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $4e26
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadItem_43c0
    call GetScreenPos
    ret


LoadItem_4d5d:
    ld a, [$c8e3]
    add a
    add a
    ld de, $c0d8
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $8800
    call SaveItem_4d77
    call SaveItem_4d77
    call SaveItem_4d77

SaveItem_4d77:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr z, jr_012_4d97

    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    pop hl
    push hl
    call SaveItem_4153
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


jr_012_4d97:
    ld b, $20

jr_012_4d99:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_012_4d99

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


    ld a, [$c825]
    or a
    ret nz

    ld de, $4e26
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    ld a, [hl]
    push af
    call LoadItem_4241
    pop af
    ld hl, $c8e2
    cp [hl]
    jr z, jr_012_4dda

    call LoadItem_49e5
    call LoadItem_49ff
    call GetScreenPos

jr_012_4dda:
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_012_4ded

    call LoadItem_4d5d
    call LoadItem_49e5
    call LoadItem_49ff
    call GetScreenPos

jr_012_4ded:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_4e14

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    jr jr_012_4e25

jr_012_4e14:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_4e25

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]

Jump_012_4e25:
jr_012_4e25:
    ret


    ld d, d
    ld bc, $006e
    xor [hl]
    nop
    xor $00
    ld l, $01
    rst $38
    rst $38
    ld hl, $000e
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    call SetItem_4e52
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


SetItem_4e52:
    ld de, $7b42
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $4eb6
    ld a, [wPLAN_selection]
    call FuncItem_43e2
    ret


    ld de, $4eb6
    ld hl, wPLAN_selection
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_4e8e

    ld hl, $5605
    rst $10
    call CallItem_4d32
    call GetScreenPos
    ld hl, $000b
    call AddCursorOffset
    ld a, $02
    ld [$c906], a
    jr jr_012_4eb5

jr_012_4e8e:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_4eb5

    ld a, $59
    call PlaySoundEffect
    ld a, [wPLAN_selection]
    cp $81
    jr z, jr_012_4eb1

    xor a
    ld [$c90d], a
    ld [$c90e], a
    ld a, $08
    ld [$c906], a
    jp Jump_012_4eb5


jr_012_4eb1:
    ld hl, $c906
    inc [hl]

Jump_012_4eb5:
jr_012_4eb5:
    ret


    ld hl, $6101
    ld bc, $ffff
    ld a, [$ca8d]
    or a
    jr nz, jr_012_4eef

    xor a
    ld [$ca8e], a
    ld a, $02
    ld [$cac1], a
    ld a, $ff
    ld [$ca8f], a
    ld a, $ff
    ld [$ca90], a
    ld a, $01
    ld [$ca8d], a
    ld hl, $0103
    rst $10
    ld bc, $0007
    call SetEventFlag
    ld hl, $000f
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


jr_012_4eef:
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
    ld [$ca90], a
    ld hl, $0105
    rst $10
    ld hl, $0103
    rst $10
    ld hl, $000f
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    ret


    ld hl, $c0d8
    ld a, l
    ld [$c930], a
    ld a, h
    ld [$c931], a
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    ld a, a
    ld [$c932], a
    ld a, [$c8e9]
    ld [$c933], a
    ld hl, $0702
    rst $10
    ld a, $01
    ld [$c8ec], a
    ret


    ld a, [$c8e2]
    and $80
    ld b, a
    ld a, [$c934]
    and $03
    or b
    ld [$c8e2], a
    ld a, [$c934]
    srl a
    srl a
    ld [$c8e3], a
    ld de, MenuBorderRightEdge
    ld hl, $8800
    call WaitDMATransfer
    ld a, $02
    ld [$c822], a
    ld a, $44
    ld [$c823], a
    ld hl, $9600
    ld de, $0501
    call LoadItem_411a
    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    call LoadItem_49e5
    call LoadItem_4d5d
    ld hl, $5605
    rst $10
    call CallItem_4d32
    call SetItem_4e52
    call GetScreenPos
    ld hl, $000e
    call AddCursorOffset
    ld a, $05
    ld [$c906], a
    xor a
    ld [$c8ec], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $0010
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    call SetItem_4ffa
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


SetItem_4ffa:
    ld de, $6f54
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $5059
    ld a, [$c8dd]
    call FuncItem_43e2
    ret


    ld de, $5059
    ld hl, $c8dd
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_503f

jr_012_501f:
    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    jr jr_012_5058

jr_012_503f:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_5058

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8dd]
    cp $81
    jr z, jr_012_501f

    ld a, $17
    ld [$c906], a

Jump_012_5058:
jr_012_5058:
    ret


    ld hl, $6101
    ld bc, $ffff
    call SetItem_4ce5
    ld hl, $0013
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call LoadItem_49e5
    call LoadItem_4d5d
    call CallItem_5083
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


CallItem_5083:
    call SetItem_41ef
    call SetItem_44cb
    ld de, $759a
    call ReadPtrFromDE
    call LoadItem_49ff
    ld de, $71f4
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $4e26
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadItem_43c0
    call SetItem_4ffa
    ret


    ld a, [$c825]
    or a
    ret nz

    ld de, $4e26
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    ld a, [hl]
    push af
    call LoadItem_4241
    pop af
    ld hl, $c8e2
    cp [hl]
    jr z, jr_012_50d7

    call LoadItem_49e5
    call LoadItem_49ff
    call GetScreenPos

jr_012_50d7:
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_012_50ea

    call LoadItem_4d5d
    call LoadItem_49e5
    call LoadItem_49ff
    call GetScreenPos

jr_012_50ea:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_510a

    call LoadItem_5313
    call SetItem_4643
    call CallItem_52ee
    ld hl, $0011
    call AddCursorOffset
    call GetScreenPos
    ld a, $19
    ld [$c906], a
    jr jr_012_511f

jr_012_510a:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_511f

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]
    xor a
    ld [wPLAN_selection], a

Jump_012_511f:
jr_012_511f:
    ret


    ld hl, $0014
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    call SetItem_5140
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


SetItem_5140:
    ld de, $7b42
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $51a5
    ld a, [wPLAN_selection]
    call FuncItem_43e2
    ret


    ld de, $51a5
    ld hl, wPLAN_selection
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_517e

    call LoadItem_49e5
    call LoadItem_4d5d
    call CallItem_5083
    ld hl, $0013
    call AddCursorOffset
    call GetScreenPos
    ld a, $0f
    ld [$c906], a
    jr jr_012_51a4

jr_012_517e:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_51a4

    ld a, $59
    call PlaySoundEffect
    ld a, [wPLAN_selection]
    cp $81
    jr z, jr_012_51a0

    xor a
    ld [$c90d], a
    ld [$c90e], a
    ld a, $15
    ld [$c906], a
    jr jr_012_51a4

jr_012_51a0:
    ld hl, $c906
    inc [hl]

Jump_012_51a4:
jr_012_51a4:
    ret


    ld hl, $6101
    ld bc, $ffff
    ld a, [$c8de]
    and $7f
    ld hl, $ca8e
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
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c190
    call Copy4Bytes
    ld a, [$c8de]
    and $7f
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop af
    ld [hl], a
    ld hl, $0105
    rst $10
    ld hl, $0103
    rst $10
    ld hl, $0015
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    ret


    ld hl, $c0d8
    ld a, l
    ld [$c930], a
    ld a, h
    ld [$c931], a
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    ld a, a
    ld [$c932], a
    ld a, [$c8e9]
    ld [$c933], a
    ld hl, $0702
    rst $10
    ld a, $01
    ld [$c8ec], a
    ret


    ld a, [$c8e2]
    and $80
    ld b, a
    ld a, [$c934]
    and $03
    or b
    ld [$c8e2], a
    ld a, [$c934]
    srl a
    srl a
    ld [$c8e3], a
    ld de, MenuBorderRightEdge
    ld hl, $8800
    call WaitDMATransfer
    ld a, $02
    ld [$c822], a
    ld a, $44
    ld [$c823], a
    ld hl, $9600
    ld de, $0501
    call LoadItem_411a
    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    call SetItem_4ce5
    call LoadItem_49e5
    call LoadItem_4d5d
    ld hl, $5605
    rst $10
    call CallItem_5083
    call SetItem_5140
    call GetScreenPos
    ld hl, $0014
    call AddCursorOffset
    ld a, $12
    ld [$c906], a
    xor a
    ld [$c8ec], a
    ret


    ld hl, $0011
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call LoadItem_5313
    call SetItem_4643
    call CallItem_52ee
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


CallItem_52ee:
    call SetItem_41ef
    call SetItem_44cb
    ld de, $71aa
    call ReadPtrFromDE
    ld de, $759a
    call ReadPtrFromDE
    call LoadItem_5326
    call ClrItem_4323
    ld de, $5399
    ld a, [$c8de]
    call FuncItem_43e2
    call SetItem_4ffa
    ret


LoadItem_5313:
    ld a, [$c8de]
    and $7f
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    call SaveItem_4691
    ret


LoadItem_5326:
    ld a, [$c8de]
    and $7f
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    call SaveItem_470c
    ret


    ld a, [$c825]
    or a
    ret nz

    ld de, $5399
    ld hl, $c8de
    ld a, [$ca8d]
    ld b, a
    ld a, [hl]
    push af
    call FuncItem_42ca
    pop af
    ld hl, $c8de
    cp [hl]
    jr z, jr_012_5363

    call LoadItem_5313
    ld de, $759a
    call ReadPtrFromDE
    call LoadItem_5326
    call GetScreenPos

jr_012_5363:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_5383

    call SetItem_41ef
    call SetItem_44cb
    call SetItem_4ffa
    ld hl, $0010
    call AddCursorOffset
    call GetScreenPos
    ld a, $0c
    ld [$c906], a
    jr jr_012_5398

jr_012_5383:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_5398

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]
    xor a
    ld [wPLAN_selection], a

Jump_012_5398:
jr_012_5398:
    ret


    ld l, [hl]
    nop
    xor [hl]
    nop
    xor $00
    rst $38
    rst $38
    ld hl, $0012
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    call SetItem_53c1
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


SetItem_53c1:
    ld de, $7b42
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $5427
    ld a, [wPLAN_selection]
    call FuncItem_43e2
    ret


    ld de, $5427
    ld hl, wPLAN_selection
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_53ff

    call LoadItem_5313
    call SetItem_4643
    call CallItem_52ee
    ld hl, $0011
    call AddCursorOffset
    call GetScreenPos
    ld a, $19
    ld [$c906], a
    jr jr_012_5426

jr_012_53ff:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_5426

    ld a, $59
    call PlaySoundEffect
    ld a, [wPLAN_selection]
    cp $81
    jr z, jr_012_5421

    xor a
    ld [$c90d], a
    ld [$c90e], a
    ld a, $1d
    ld [$c906], a
    jr jr_012_5426

jr_012_5421:
    ld a, $0d
    ld [$c906], a

Jump_012_5426:
jr_012_5426:
    ret


    ld hl, $6101
    ld bc, $ffff
    ld hl, $ca8e
    ld a, l
    ld [$c930], a
    ld a, h
    ld [$c931], a
    ld a, [$c8de]
    and $7f
    ld [$c932], a
    ld a, [$ca8d]
    ld [$c933], a
    ld hl, $0702
    rst $10
    ld a, $01
    ld [$c8ec], a
    ret


    ld a, [$c8de]
    and $80
    ld b, a
    ld a, [$c934]
    or b
    ld [$c8de], a
    ld de, MenuBorderRightEdge
    ld hl, $8800
    call WaitDMATransfer
    ld a, $02
    ld [$c822], a
    ld a, $44
    ld [$c823], a
    ld hl, $9600
    ld de, $0501
    call LoadItem_411a
    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    call LoadItem_5313
    call SetItem_4643
    ld hl, $5605
    rst $10
    call CallItem_52ee
    call SetItem_53c1
    call GetScreenPos
    ld hl, $0012
    call AddCursorOffset
    ld a, $1c
    ld [$c906], a
    xor a
    ld [$c8ec], a
    ret


    ld a, [$c906]
    rst $00
    push bc
    ld d, h
    ret c

    ld d, h
    ei
    ld d, l
    ld d, b
    ld d, [hl]
    ld [$8056], a
    ld e, b
    dec hl
    ld e, c
    ld d, c
    ld e, c
    and d
    ld e, c
    ld a, [$ca8d]
    cp $00
    jp z, Jump_012_45ec

    ld hl, $0016
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call CallItem_54e5
    ld hl, $c906
    inc [hl]
    ret


CallItem_54e5:
    call SetItem_41ef
    call SetItem_44cb
    ld de, $7768
    call ReadPtrFromDE
    call SetItem_5504
    call ClrItem_4323
    ld de, $564a
    ld a, [wOPTN_and_Item_selection]
    call FuncItem_43e2
    call GetScreenPos
    ret


SetItem_5504:
    ld hl, $00a6
    call CallItem_551d
    ld hl, $00e6
    call CallItem_5551
    ld hl, $0126
    call CallItem_5581
    ld hl, $0166
    call CallItem_55be
    ret


CallItem_551d:
    call LoadItem_4058
    push hl
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_012_5528:
    push de
    ld a, [de]
    or a
    jr z, jr_012_553e

    cp $02
    jr z, jr_012_553e

    ld a, e
    add $63
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld a, [de]
    or a
    jr nz, jr_012_553e

    inc c

jr_012_553e:
    pop de
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    dec b
    jr nz, jr_012_5528

    pop hl
    ld b, $00
    call CopyHLtoDE
    ret


CallItem_5551:
    call LoadItem_4058
    push hl
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_012_555c:
    push de
    ld a, [de]
    or a
    jr z, jr_012_556e

    ld a, e
    add $63
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld a, [de]
    or a
    jr z, jr_012_556e

    inc c

jr_012_556e:
    pop de
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    dec b
    jr nz, jr_012_555c

    pop hl
    ld b, $00
    call CopyHLtoDE
    ret


CallItem_5581:
    call LoadItem_4058
    ld c, $00
    ld a, [$ca41]
    bit 7, a
    jr z, jr_012_55b8

    push hl
    ld hl, $b124
    ld b, $14
    ld c, $00

jr_012_5595:
    push hl
    call EnableSRAM
    or a
    jr z, jr_012_55ab

    ld a, l
    add $63
    ld l, a
    ld a, h
    adc $00
    ld h, a
    call EnableSRAM
    or a
    jr nz, jr_012_55ab

    inc c

jr_012_55ab:
    pop hl
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, jr_012_5595

    pop hl

jr_012_55b8:
    ld b, $00
    call CopyHLtoDE
    ret


CallItem_55be:
    call LoadItem_4058
    ld c, $00
    ld a, [$ca41]
    bit 7, a
    jr z, jr_012_55f5

    push hl
    ld hl, $b124
    ld b, $14
    ld c, $00

jr_012_55d2:
    push hl
    call EnableSRAM
    or a
    jr z, jr_012_55e8

    ld a, l
    add $63
    ld l, a
    ld a, h
    adc $00
    ld h, a
    call EnableSRAM
    or a
    jr z, jr_012_55e8

    inc c

jr_012_55e8:
    pop hl
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, jr_012_55d2

    pop hl

jr_012_55f5:
    ld b, $00
    call CopyHLtoDE
    ret


    ld de, $564a
    ld hl, wOPTN_and_Item_selection
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_562d

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    jr jr_012_5649

jr_012_562d:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_5649

    ld a, $59
    call PlaySoundEffect
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c906
    inc [hl]

Jump_012_5649:
jr_012_5649:
    ret


    and c
    nop
    pop hl
    nop
    rst $38
    rst $38
    call SetItem_5670
    or a
    jr nz, jr_012_5662

    ld hl, $0017
    call AddCursorOffset
    ld a, $08
    ld [$c906], a
    ret


jr_012_5662:
    call SetItem_56a6
    ld hl, $0018
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


SetItem_5670:
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_012_5677:
    push de
    ld a, [de]
    or a
    jr z, jr_012_5695

    ld a, e
    add $63
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld a, [wOPTN_and_Item_selection]
    and $01
    ld l, a
    ld a, [de]
    ld h, a
    srl a
    or h
    and $01
    xor l
    jr nz, jr_012_5695

    inc c

jr_012_5695:
    pop de
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    dec b
    jr nz, jr_012_5677

    ld a, c
    ld [$c8e9], a
    ret


SetItem_56a6:
    ld hl, $c0d8
    ld bc, $0014
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_012_56bb:
    push de
    ld a, [de]
    or a
    jr z, jr_012_56dc

    ld a, e
    add $63
    ld e, a
    ld a, d
    adc $00
    ld d, a
    push hl
    ld a, [wOPTN_and_Item_selection]
    and $01
    ld l, a
    ld a, [de]
    ld h, a
    srl a
    or h
    and $01
    xor l
    pop hl
    jr nz, jr_012_56dc

    ld [hl], c
    inc hl

jr_012_56dc:
    pop de
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    inc c
    dec b
    jr nz, jr_012_56bb

    ret


    ld a, [$c825]
    or a
    ret nz

    call LoadItem_49e5
    call LoadItem_5751
    call CallItem_56fd
    ld hl, $c906
    inc [hl]
    ret


CallItem_56fd:
    call SetItem_41ef
    call SetItem_44cb
    ld de, $7768
    call ReadPtrFromDE
    call SetItem_5504
    call ClrItem_4323
    ld de, $564a
    ld a, [wOPTN_and_Item_selection]
    call FuncItem_43e2
    ld de, $77cd
    ld a, [wOPTN_and_Item_selection]
    and $01
    jr nz, jr_012_572e

    ld de, $759a
    call ReadPtrFromDE
    call LoadItem_49ff
    ld de, $71f4

jr_012_572e:
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $5913
    ld a, [wOPTN_and_Item_selection]
    and $01
    jr z, jr_012_5741

    ld de, $591f

jr_012_5741:
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadItem_43c0
    call GetScreenPos
    ret


LoadItem_5751:
    ld a, [$c8e3]
    add a
    add a
    ld de, $c0d8
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [wOPTN_and_Item_selection]
    and $01
    jr nz, jr_012_5776

    ld hl, $8800
    call SaveItem_4d77
    call SaveItem_4d77
    call SaveItem_4d77
    call SaveItem_4d77
    ret


jr_012_5776:
    ld hl, $9650
    call SaveItem_578c
    call SaveItem_578c
    call SaveItem_578c
    ld hl, $8800
    call SaveItem_578c
    call LoadItem_57d0
    ret


SaveItem_578c:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr z, jr_012_57b6

    ld hl, $caca
    call GetMonsterDataPtr
    ld a, [hl]
    ld [$c823], a
    ld a, $05
    ld [$c822], a
    ld de, WaitSTATForOverlayB
    pop hl
    push hl
    call LoadItem_411a
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


jr_012_57b6:
    ld b, $48

jr_012_57b8:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_012_57b8

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


LoadItem_57d0:
    ld a, [$c8e3]
    add a
    add a
    ld de, $c0d8
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $88c0
    call SaveItem_57ea
    call SaveItem_57ea
    call SaveItem_57ea

SaveItem_57ea:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr z, jr_012_5866

    ld hl, $cb24
    call GetMonsterDataPtr
    ld a, [hl]
    cp $02
    ld a, $98
    jr nz, jr_012_580b

    ld a, l
    add $a8
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, [hl]
    and $01
    add $a7

jr_012_580b:
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


jr_012_5866:
    ld b, $08

jr_012_5868:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_012_5868

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


    ld a, [$c825]
    or a
    ret nz

    ld de, $5913
    ld a, [wOPTN_and_Item_selection]
    and $01
    jr z, jr_012_5892

    ld de, $591f

jr_012_5892:
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    ld a, [hl]
    push af
    call LoadItem_4241
    pop af
    ld hl, $c8e2
    cp [hl]
    jr z, jr_012_58ba

    ld a, [wOPTN_and_Item_selection]
    and $01
    jr nz, jr_012_58ba

    call LoadItem_49e5
    call LoadItem_49ff
    call GetScreenPos

jr_012_58ba:
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_012_58d4

    call LoadItem_5751
    ld a, [wOPTN_and_Item_selection]
    and $01
    jr nz, jr_012_58d4

    call LoadItem_49e5
    call LoadItem_49ff
    call GetScreenPos

jr_012_58d4:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_58fa

    call CallItem_54e5
    ld hl, $0016
    call AddCursorOffset
    xor a
    ld [$c8ec], a
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    jr jr_012_5912

jr_012_58fa:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_5912

    ld a, $59
    call PlaySoundEffect
    xor a
    ld [$c90d], a
    ld [$c90e], a
    ld hl, $c906
    inc [hl]

Jump_012_5912:
jr_012_5912:
    ret


    ld d, d
    ld bc, $006e
    xor [hl]
    nop
    xor $00
    ld l, $01
    rst $38
    rst $38
    sub d
    ld bc, $00a8
    add sp, $00
    jr z, jr_012_5928

    ld l, b

jr_012_5928:
    ld bc, $ffff
    ld hl, $c0d8
    ld a, l
    ld [$c930], a
    ld a, h
    ld [$c931], a
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    ld a, a
    ld [$c932], a
    ld a, [$c8e9]
    ld [$c933], a
    ld hl, $0702
    rst $10
    ret


    ld a, [$c8e2]
    and $80
    ld b, a
    ld a, [$c934]
    and $03
    or b
    ld [$c8e2], a
    ld a, [$c934]
    srl a
    srl a
    ld [$c8e3], a
    ld de, MenuBorderRightEdge
    ld hl, $8800
    call WaitDMATransfer
    ld a, $02
    ld [$c822], a
    ld a, $44
    ld [$c823], a
    ld hl, $9600
    ld de, $0501
    call LoadItem_411a
    ld hl, $5605
    rst $10
    call LoadItem_49e5
    call LoadItem_5751
    call CallItem_56fd
    ld hl, $0018
    call AddCursorOffset
    call RequestScreenUpdate
    ld a, $05
    ld [$c906], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    ret


    ld a, [$c906]
    rst $00
    db $e4
    ld e, c
    rst $30
    ld e, c
    inc hl
    ld e, d
    sub h
    ld e, d
    ld [hl], $5b
    sbc l
    ld e, e
    ld c, b
    ld e, h
    ld d, e
    ld e, h
    add l
    ld e, h
    rst $18
    ld e, h
    ccf
    ld e, l
    ld h, e
    ld e, l
    adc [hl]
    ld e, l
    ld a, [$ca8d]
    cp $00
    jp z, Jump_012_45ec

    ld hl, $001a
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call CallItem_5a07
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


CallItem_5a07:
    call SetItem_41ef
    call SetItem_44cb
    ld de, $7768
    call ReadPtrFromDE
    call SetItem_5504
    call ClrItem_4323
    ld de, $5a8e
    ld a, [wOPTN_and_Item_selection]
    call FuncItem_43e2
    ret


    ld de, $5a8e
    ld hl, wOPTN_and_Item_selection
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_5a55

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    jr jr_012_5a74

jr_012_5a55:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_5a74

    ld a, $59
    call PlaySoundEffect
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    call LoadItem_5a75
    ld hl, $c906
    inc [hl]

Jump_012_5a74:
jr_012_5a74:
    ret


LoadItem_5a75:
    ld a, $02
    ld [$c822], a
    ld a, [wOPTN_and_Item_selection]
    and $01
    add $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ret


    and c
    nop
    pop hl
    nop
    rst $38
    rst $38
    call SetItem_5ab4
    or a
    jr nz, jr_012_5aa6

    ld hl, $001b
    call AddCursorOffset
    ld a, $0a
    ld [$c906], a
    ret


jr_012_5aa6:
    call SetItem_5aee
    ld hl, $001c
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


SetItem_5ab4:
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_012_5abb:
    push de
    ld a, [de]
    or a
    jr z, jr_012_5add

    cp $02
    jr z, jr_012_5add

    ld a, e
    add $63
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld a, [wOPTN_and_Item_selection]
    and $01
    ld l, a
    ld a, [de]
    ld h, a
    srl a
    or h
    and $01
    xor l
    jr nz, jr_012_5add

    inc c

jr_012_5add:
    pop de
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    dec b
    jr nz, jr_012_5abb

    ld a, c
    ld [$c8e9], a
    ret


SetItem_5aee:
    ld hl, $c0d8
    ld bc, $0014
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_012_5b03:
    push de
    ld a, [de]
    or a
    jr z, jr_012_5b28

    cp $02
    jr z, jr_012_5b28

    ld a, e
    add $63
    ld e, a
    ld a, d
    adc $00
    ld d, a
    push hl
    ld a, [wOPTN_and_Item_selection]
    and $01
    ld l, a
    ld a, [de]
    ld h, a
    srl a
    or h
    and $01
    xor l
    pop hl
    jr nz, jr_012_5b28

    ld [hl], c
    inc hl

jr_012_5b28:
    pop de
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    inc c
    dec b
    jr nz, jr_012_5b03

    ret


    ld a, [$c825]
    or a
    ret nz

    call LoadItem_49e5
    call LoadItem_5751
    call SetItem_41ef
    call CallItem_5b4f
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


CallItem_5b4f:
    call SetItem_44cb
    ld de, $7768
    call ReadPtrFromDE
    call SetItem_5504
    call ClrItem_4323
    ld de, $5a8e
    ld a, [wOPTN_and_Item_selection]
    call FuncItem_43e2
    ld de, $77cd
    ld a, [wOPTN_and_Item_selection]
    and $01
    jr nz, jr_012_5b7d

    ld de, $759a
    call ReadPtrFromDE
    call LoadItem_49ff
    ld de, $71f4

jr_012_5b7d:
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $5c30
    ld a, [wOPTN_and_Item_selection]
    and $01
    jr z, jr_012_5b90

    ld de, $5c3c

jr_012_5b90:
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadItem_43c0
    ret


    ld a, [$c825]
    or a
    ret nz

    ld de, $5c30
    ld a, [wOPTN_and_Item_selection]
    and $01
    jr z, jr_012_5baf

    ld de, $5c3c

jr_012_5baf:
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    ld a, [hl]
    push af
    call LoadItem_4241
    pop af
    ld hl, $c8e2
    cp [hl]
    jr z, jr_012_5bd7

    ld a, [wOPTN_and_Item_selection]
    and $01
    jr nz, jr_012_5bd7

    call LoadItem_49e5
    call LoadItem_49ff
    call GetScreenPos

jr_012_5bd7:
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_012_5bf1

    call LoadItem_5751
    ld a, [wOPTN_and_Item_selection]
    and $01
    jr nz, jr_012_5bf1

    call LoadItem_49e5
    call LoadItem_49ff
    call GetScreenPos

jr_012_5bf1:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_5c1a

    call CallItem_5a07
    call GetScreenPos
    ld hl, $001a
    call AddCursorOffset
    xor a
    ld [$c8ec], a
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    jr jr_012_5c2f

jr_012_5c1a:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_5c2f

    ld a, $59
    call PlaySoundEffect
    xor a
    ld [$c8de], a
    ld hl, $c906
    inc [hl]

Jump_012_5c2f:
jr_012_5c2f:
    ret


    ld d, d
    ld bc, $006e
    xor [hl]
    nop
    xor $00
    ld l, $01
    rst $38
    rst $38
    sub d
    ld bc, $00a8
    add sp, $00
    jr z, jr_012_5c45

    ld l, b

jr_012_5c45:
    ld bc, $ffff
    ld hl, $001d
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    call SetItem_5c68
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


SetItem_5c68:
    ld de, $7b42
    ld a, [wOPTN_and_Item_selection]
    and $01
    jr z, jr_012_5c75

    ld de, $7b6c

jr_012_5c75:
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $5cd9
    ld a, [$c8de]
    call FuncItem_43e2
    ret


    ld de, $5cd9
    ld hl, $c8de
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_5cb1

    xor a
    ld [$c8ec], a
    call SetItem_41ef
    call CallItem_5b4f
    ld hl, $001c
    call AddCursorOffset
    call GetScreenPos
    ld a, $05
    ld [$c906], a
    jr jr_012_5cd8

jr_012_5cb1:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_5cd8

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8de]
    cp $81
    jr z, jr_012_5cd4

    xor a
    ld [$c90d], a
    ld [$c90e], a
    ld a, $0b
    ld [$c906], a
    jp Jump_012_5cd8


jr_012_5cd4:
    ld hl, $c906
    inc [hl]

Jump_012_5cd8:
jr_012_5cd8:
    ret


    ld hl, $6101
    ld bc, $ffff
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
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    pop af
    push af
    ld hl, $cac1
    call GetMonsterDataPtr
    ld [hl], $00
    pop af
    ld hl, $cb24
    call GetMonsterDataPtr
    ld a, [hl]
    or a
    jr z, jr_012_5d2c

    ld hl, $0105
    rst $10
    ld hl, $0103
    rst $10
    ld hl, $0b1d
    call SetupTilemapTransfer
    ld hl, $c906
    inc [hl]
    ret


jr_012_5d2c:
    ld hl, $0105
    rst $10
    ld hl, $0103
    rst $10
    ld hl, $001e
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    ret


    ld hl, $c0d8
    ld a, l
    ld [$c930], a
    ld a, h
    ld [$c931], a
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    ld a, a
    ld [$c932], a
    ld a, [$c8e9]
    ld [$c933], a
    ld hl, $0702
    rst $10
    ld a, $01
    ld [$c8ec], a
    ret


    ld a, [$c8e2]
    and $80
    ld b, a
    ld a, [$c934]
    and $03
    or b
    ld [$c8e2], a
    ld a, [$c934]
    srl a
    srl a
    ld [$c8e3], a
    ld de, MenuBorderRightEdge
    ld hl, $8800
    call WaitDMATransfer
    ld a, $02
    ld [$c822], a
    ld a, $44
    ld [$c823], a
    ld hl, $9600
    ld de, $0501
    call LoadItem_411a
    call LoadItem_5a75
    call LoadItem_49e5
    call LoadItem_5751
    ld hl, $5605
    rst $10
    call SetItem_41ef
    call CallItem_5b4f
    call SetItem_5c68
    call GetScreenPos
    ld hl, $001d
    call AddCursorOffset
    ld a, $08
    ld [$c906], a
    xor a
    ld [$c8ec], a
    ret


    ld a, [$c906]
    rst $00
    cp $5d
    ld e, b
    ld e, [hl]
    add c
    ld e, [hl]
    jp nc, DataLookup_295E

    ld e, a
    dec a
    ld e, a
    rst $30
    ld e, a
    ld a, [$ca8d]
    cp $00
    jp z, Jump_012_45ec

    ld hl, $cac1
    ld b, $14

jr_012_5e0b:
    ld a, [hl]
    cp $01
    jr z, jr_012_5e4d

    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, jr_012_5e0b

    ld a, [$ca41]
    bit 7, a
    jr z, jr_012_5e3c

    ld hl, $b124
    ld b, $14

jr_012_5e27:
    push hl
    push bc
    call EnableSRAM
    pop bc
    pop hl
    or a
    jr nz, jr_012_5e48

    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, jr_012_5e27

jr_012_5e3c:
    ld hl, $06cc
    call TextBankDispatch
    ld a, $06
    ld [$c906], a
    ret


jr_012_5e48:
    ld hl, $0025
    jr jr_012_5e50

jr_012_5e4d:
    ld hl, $0022

jr_012_5e50:
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call CallItem_5e65
    ld hl, $c906
    inc [hl]
    ret


CallItem_5e65:
    call SetItem_41ef
    call SetItem_44cb
    ld de, $78ab
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $5ecc
    ld a, [wPLAN_selection]
    call FuncItem_43e2
    call GetScreenPos
    ret


    ld de, $5ecc
    ld hl, $c8e2
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_5eb3

jr_012_5e93:
    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    jr jr_012_5ecb

jr_012_5eb3:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_5ecb

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8e2]
    cp $81
    jr z, jr_012_5e93

    ld hl, $c906
    inc [hl]

Jump_012_5ecb:
jr_012_5ecb:
    ret


    cpl
    ld bc, $016f
    rst $38
    rst $38
    ld a, [$c825]
    or a
    ret nz

    call SetItem_5fde
    ld hl, $cac1
    ld b, $14

jr_012_5edf:
    ld a, [hl]
    cp $01
    jr z, jr_012_5ef4

    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, jr_012_5edf

    ld hl, $0026
    jr jr_012_5f1d

jr_012_5ef4:
    ld a, [$ca41]
    bit 7, a
    jr z, jr_012_5f15

    ld hl, $b124
    ld b, $14

jr_012_5f00:
    push hl
    push bc
    call EnableSRAM
    pop bc
    pop hl
    or a
    jr nz, jr_012_5f1a

    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, jr_012_5f00

jr_012_5f15:
    ld hl, $0023
    jr jr_012_5f1d

jr_012_5f1a:
    ld hl, $0024

jr_012_5f1d:
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $0022
    call AddCursorOffset
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld bc, $0000

jr_012_5f58:
    ld a, b
    ld hl, $cac1
    call GetMonsterDataPtr
    ld a, [hl]
    cp $02
    jr z, jr_012_5f68

    call SaveItem_5fb3
    inc c

jr_012_5f68:
    inc b
    ld a, b
    cp $14
    jr nz, jr_012_5f58

    ld hl, $0105
    rst $10
    ld a, [wGameState]
    push af
    xor a
    ld [wGameState], a
    ld a, [$c905]
    push af
    xor a
    ld [$c905], a
    ld a, [wScriptStateFlags]
    push af
    xor a
    ld [wScriptStateFlags], a
    ld a, [$c8ec]
    push af
    xor a
    ld [$c8ec], a
    di
    call SaveGameState
    ei
    pop af
    ld [$c8ec], a
    pop af
    ld [wScriptStateFlags], a
    pop af
    ld [$c905], a
    pop af
    ld [wGameState], a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    ret


SaveItem_5fb3:
    push bc
    ld a, b
    ld hl, $cac1
    call GetMonsterDataPtr
    push hl
    ld a, c
    ld c, $95
    call Mul8x8To16
    ld a, l
    add $24
    ld l, a
    ld a, h
    adc $b1
    ld h, a
    pop de
    ld b, $95

jr_012_5fcd:
    ld a, [de]
    push af
    call EnableSRAM
    ld [de], a
    pop af
    call DisableIntAndPush
    inc de
    inc hl
    dec b
    jr nz, jr_012_5fcd

    pop bc
    ret


SetItem_5fde:
    ld hl, $ca41
    bit 7, [hl]
    ret nz

    set 7, [hl]
    ld hl, $b124
    ld bc, $0ba4

jr_012_5fec:
    xor a
    call DisableIntAndPush
    inc hl
    dec bc
    ld a, b
    or c
    jr nz, jr_012_5fec

    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $02
    ld [$c822], a
    ld a, $33
    ld [$c823], a
    ld hl, $8aa0
    ld de, CopyDEtoHLByte
    call LoadItem_411a
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c905], a
    ret


SetItem_601b:
    ld de, $000a
    push bc
    call SaveItem_6037
    pop bc
    or a
    jr z, jr_012_6032

    ld de, $000a
    call SaveItem_6037
    call CalcItem_604c
    call SaveItem_6052

jr_012_6032:
    ld a, c
    call CalcItem_604c
    ret


SaveItem_6037:
    push hl
    ld h, $ff

jr_012_603a:
    inc h
    ld a, c
    sub e
    ld c, a
    ld a, b
    sbc d
    ld b, a
    jr nc, jr_012_603a

    ld a, c
    add e
    ld c, a
    ld a, b
    adc d
    ld b, a
    ld a, h
    pop hl
    ret


CalcItem_604c:
    add $f0
    call Write_gfx_tile
    ret


SaveItem_6052:
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


    ld a, [$c905]
    rst $00
    ld l, a
    ld h, b
    call z, $d160
    ld h, b
    ldh a, [$60]
    di
    ld h, b
    ld hl, $ffb7
    call ReadItem_4028
    ld hl, $ffbb
    call ReadItem_4028
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ldh a, [$bb]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ldh a, [$b7]
    rrca
    rrca
    rrca
    add l
    ld l, a
    ld a, h
    adc $98
    ld h, a
    ld a, h
    and $03
    or $98
    ld h, a
    ld a, l
    ld [$c909], a
    ld a, h
    ld [$c90a], a
    ld hl, $170a
    rst $10
    call SetItem_4221
    ld de, $2e07
    call ReadPtrFromDE
    call GetScreenPos
    ld de, $2e14
    ld hl, $9000
    call WaitDMATransfer
    call ClrItem_4323
    ld a, $01
    ld [$c8ec], a
    ld hl, $c905
    inc [hl]
    ret


    ld hl, $c905
    inc [hl]
    ret


    ld hl, $c905
    inc [hl]
    xor a
    ld [$c906], a
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ret


    jp Jump_012_6119


    call SetItem_4221
    call GetScreenPos
    ld hl, $0b01
    rst $10
    ld hl, $0b02
    rst $10
    call UpdateOAMSprites
    call GetBGMapAddress
    ld hl, $0604
    rst $10
    xor a
    ld [$c8ec], a
    ld hl, wGameState
    res 4, [hl]
    xor a
    ld [$c905], a
    ret


Jump_012_6119:
    ld a, [$c906]
    rst $00
    inc sp
    ld h, c
    jr c, @+$63

    cp b
    ld h, c
    inc [hl]
    ld h, d
    sbc a
    ld h, d
    ld a, [hl+]
    ld h, e
    xor h
    ld h, e
    ret


    ld h, h
    ld d, h
    ld h, l
    ld l, c
    ld h, l
    ld a, d
    ld h, l
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call LoadItem_616e
    call CallItem_614e
    call SetItem_61a0
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


CallItem_614e:
    call SetItem_4221
    ld de, $2e07
    call ReadPtrFromDE
    ld de, $78d0
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $6226
    ld b, $05
    ld c, $0a
    ld hl, wMenu_selection
    call ReadItem_43c0
    ret


LoadItem_616e:
    ld a, [wOPTN_and_Item_selection]
    ld b, a
    add a
    add a
    add b
    ld hl, $9670
    call SaveItem_6184
    call SaveItem_6184
    call SaveItem_6184
    call SaveItem_6184

SaveItem_6184:
    push af
    push hl
    ld [$c823], a
    ld a, $04
    ld [$c822], a
    ld de, $0501
    call LoadItem_411a
    pop hl
    ld a, l
    add $50
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop af
    inc a
    ret


SetItem_61a0:
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    call SetItem_6242
    call LoadItem_62ce
    ld de, $7935
    call ReadPtrFromDE
    ret


    ld de, $6226
    ld hl, wMenu_selection
    ld c, $0a
    ld b, $05
    ld a, [hl+]
    push af
    ld a, [hl-]
    push af
    call LoadItem_4241
    pop af
    ld hl, wOPTN_and_Item_selection
    cp [hl]
    jr z, jr_012_61d9

    call LoadItem_616e
    call SetItem_61a0
    call GetScreenPos

jr_012_61d9:
    pop af
    ld hl, wMenu_selection
    cp [hl]
    jr z, jr_012_61e6

    call SetItem_61a0
    call GetScreenPos

jr_012_61e6:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_6219

    call SetItem_6242
    ld a, [$c8e8]
    or a
    jr nz, jr_012_6205

    ld hl, $0004
    call AddCursorOffset
    ld a, $09
    ld [$c906], a
    jp Jump_012_6225


jr_012_6205:
    ld a, $59
    call PlaySoundEffect
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c906
    inc [hl]

Jump_012_6219:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jp z, Jump_012_6225

    ld hl, $c905
    inc [hl]

Jump_012_6225:
    ret


    ld b, [hl]
    ld bc, $0021
    ld h, c
    nop
    and c
    nop
    pop hl
    nop
    ld hl, $ff01
    rst $38
    call SetItem_6242
    ld hl, $0003
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


SetItem_6242:
    ld hl, $c0d8
    ld bc, $0020
    ld a, $ff
    call FillNBytesWithRegA
    ld a, [wOPTN_and_Item_selection]
    ld b, a
    add a
    add a
    add b
    ld b, a
    ld a, [wMenu_selection]
    and $7f
    add b
    ld [$cac0], a
    ld hl, $6294
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld c, [hl]
    ld b, a
    ld d, $00
    ld e, $00
    ld hl, $c0d8

jr_012_6271:
    push bc
    push de
    push hl
    ld hl, $ca94
    ld a, b
    call TestBitInArray
    pop hl
    pop de
    pop bc
    ld [hl], $e0
    jr z, jr_012_6284

    ld [hl], b
    inc e

jr_012_6284:
    inc d
    inc hl
    inc b
    ld a, b
    cp c
    jr nz, jr_012_6271

    ld a, d
    ld [$c8e9], a
    ld a, e
    ld [$c8e8], a
    ret


    nop
    inc d
    dec l
    ld b, [hl]
    ld e, d
    ld l, [hl]
    add d
    sbc e
    xor a
    ret z

    rst $10
    ld a, [$c825]
    or a
    ret nz

    call LoadItem_62ce
    call CallItem_62af
    ld hl, $c906
    inc [hl]
    ret


CallItem_62af:
    call CallItem_614e
    ld de, $7935
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $639e
    ld b, $05
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadItem_43c0
    call GetScreenPos
    ret


LoadItem_62ce:
    ld a, [$c8e3]
    ld b, a
    add a
    add a
    add b
    ld de, $c0d8
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $8800
    call SaveItem_62ed
    call SaveItem_62ed
    call SaveItem_62ed
    call SaveItem_62ed

SaveItem_62ed:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr z, jr_012_6310

    ld [$c823], a
    ld a, $05
    ld [$c822], a
    ld de, WaitSTATForOverlayB
    pop hl
    push hl
    call LoadItem_411a
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


Jump_012_6310:
jr_012_6310:
    ld b, $48

jr_012_6312:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_012_6312

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


    ld de, $639e
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $05
    inc hl
    ld a, [hl-]
    push af
    ld a, [hl]
    push af
    call LoadItem_4241
    pop af
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_012_6349

    call LoadItem_62ce

jr_012_6349:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_6369

    call CallItem_614e
    ld de, $7935
    call ReadPtrFromDE
    call GetScreenPos
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c906], a
    jr jr_012_639d

jr_012_6369:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_639d

    ld a, [$c8e3]
    ld b, a
    add a
    add a
    add b
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    ld [wPLAN_selection], a
    ld hl, $c0d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$cac0], a
    cp $e0
    jp z, Jump_012_639d

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]

Jump_012_639d:
jr_012_639d:
    ret


    ld d, d
    ld bc, $0029
    ld l, c
    nop
    xor c
    nop
    jp hl


    nop
    add hl, hl
    ld bc, $ffff
    call SetItem_4221
    call GetScreenPos
    call LoadItem_63d0
    call SetItem_63bd
    ld hl, $c906
    inc [hl]
    ret


SetItem_63bd:
    ld de, $2e26
    ld hl, $8a50
    call WaitDMATransfer
    ld de, $79c6
    call ReadPtrFromDE
    call GetScreenPos
    ret


LoadItem_63d0:
    ld a, [$cac0]
    ld [$c823], a
    ld a, $05
    ld [$c822], a
    ld hl, $9140
    ld de, WaitSTATForOverlayB
    call LoadItem_411a
    ld hl, $ca94
    ld a, [$cac0]
    call TestBitInArray
    ld a, $ff
    jr z, jr_012_63f4

    ld a, [$cac0]

jr_012_63f4:
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $91d0
    ld de, $1201
    call LoadItem_6456
    ld a, [$cac0]
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    ld hl, $94a0
    ld de, $1203
    call LoadItem_6456
    call LoadItem_648f
    ld a, [$cac0]
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
    ld hl, $8800
    call WaitDMATransfer
    ld hl, $0021
    ld a, l
    ld [$c820], a
    ld a, h
    ld [$c821], a
    ld a, [$cac0]
    ld [$c81e], a
    ld a, $04
    ld [$c81f], a
    ld hl, $1706
    rst $10
    ld hl, $1708
    rst $10
    call LoadItem_65a8
    ret


LoadItem_6456:
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
    ld hl, $4d02
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


LoadItem_648f:
    ld a, [$cac0]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld de, $da39
    ld hl, $92f0
    call SaveItem_64a5
    call SaveItem_64a5

SaveItem_64a5:
    push de
    push hl
    ld a, [de]
    cp $ff
    jp z, Jump_012_6310

    ld [$c823], a
    ld a, $06
    ld [$c822], a
    ld de, WaitSTATForOverlayB
    pop hl
    push hl
    call LoadItem_411a
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


    ld a, [$c8e9]
    or a
    jr z, jr_012_6526

    cp $01
    jr z, jr_012_6526

    ld a, [wJoypad_current_frame]
    bit 5, a
    jr z, jr_012_64fd

jr_012_64da:
    ld a, [$c8e9]
    ld c, a
    cp $01
    jr z, jr_012_64fd

    ld a, [wPLAN_selection]
    dec a
    ld [wPLAN_selection], a
    cp c
    jr c, jr_012_64f1

    dec c
    ld a, c
    ld [wPLAN_selection], a

jr_012_64f1:
    call LoadItem_6544
    jr z, jr_012_64da

    ld a, $0a
    ld [$c906], a
    jr jr_012_6543

jr_012_64fd:
    ld a, [wJoypad_current_frame]
    bit 4, a
    jr z, jr_012_6526

jr_012_6504:
    ld a, [$c8e9]
    ld c, a
    cp $01
    jr z, jr_012_6526

    ld a, [wPLAN_selection]
    inc a
    ld [wPLAN_selection], a
    cp c
    jr c, jr_012_651a

    xor a
    ld [wPLAN_selection], a

jr_012_651a:
    call LoadItem_6544
    jr z, jr_012_6504

    ld a, $0a
    ld [$c906], a
    jr jr_012_6543

jr_012_6526:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr nz, jr_012_6535

    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_6540

jr_012_6535:
    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]
    jr jr_012_6543

Jump_012_6540:
    call SetItem_67c0

jr_012_6543:
    ret


LoadItem_6544:
    ld a, [wPLAN_selection]
    ld hl, $c0d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $e0
    ret


    call SetItem_4221
    call GetScreenPos
    call LoadItem_616e
    call LoadItem_62ce
    call CallItem_62af
    ld a, $05
    ld [$c906], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c906], a
    ret


    ld a, [wPLAN_selection]
    ld hl, $c0d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$cac0], a
    call LoadItem_63d0
    call SetItem_63bd
    ld a, $07
    ld [$c906], a
    ld a, [wPLAN_selection]
    ld b, a
    ld a, $05
    call Div8x8
    or $80
    ld [$c8e2], a
    ld a, b
    ld [$c8e3], a
    ret


LoadItem_65a8:
    ld a, [$cac0]
    ld [$da6f], a
    ld hl, $1601
    rst $10
    ld a, [$da71]
    ld hl, $8600
    call CmpItem_65cb
    ld [$da71], a
    ld a, [$da72]
    ld hl, $8700
    call CmpItem_65cb
    ld [$da72], a
    ret


CmpItem_65cb:
    cp $ff
    ret z

    cp $fa
    jr z, jr_012_65ef

    cp $f0
    jr nc, jr_012_65ef

    push af
    push hl
    add $10
    ld l, a
    ld h, $00
    add hl, hl
    ld a, l
    add LOW(ItemSlotPtrTable)
    ld l, a
    ld a, h
    adc HIGH(ItemSlotPtrTable)
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    pop hl
    call WaitDMATransfer
    pop af
    ret


jr_012_65ef:
    ld a, $ff
    ret


ItemSlotPtrTable:
    nop
    cpl
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $2f01
    ld [bc], a
    cpl
    inc bc
    cpl
    inc b
    cpl
    dec b
    cpl
    ld b, $2f
    rlca
    cpl
    ld [$092f], sp
    cpl
    ld a, [bc]
    cpl
    dec bc
    cpl
    inc c
    cpl
    dec c
    cpl
    ld c, $2f
    rrca
    cpl
    db $10
    cpl
    nop
    jr c, @+$03

    jr c, jr_012_6639

    jr c, @+$05

jr_012_6639:
    jr c, jr_012_663f

    jr c, @+$07

    jr c, jr_012_6645

jr_012_663f:
    jr c, @+$09

    jr c, jr_012_664b

    jr c, @+$0b

jr_012_6645:
    jr c, jr_012_6651

    jr c, @+$0d

    jr c, jr_012_6657

jr_012_664b:
    jr c, @+$0f

    jr c, jr_012_665d

    jr c, @+$11

jr_012_6651:
    jr c, jr_012_6663

    jr c, @+$13

    jr c, jr_012_6669

jr_012_6657:
    jr c, @+$15

    jr c, jr_012_666f

    jr c, @+$17

jr_012_665d:
    jr c, jr_012_6675

    jr c, @+$19

    jr c, jr_012_667b

jr_012_6663:
    jr c, @+$1b

    jr c, jr_012_6681

    jr c, @+$1d

jr_012_6669:
    jr c, jr_012_6687

    jr c, @+$1f

    jr c, jr_012_668d

jr_012_666f:
    jr c, @+$21

    jr c, jr_012_6693

    jr c, @+$23

jr_012_6675:
    jr c, jr_012_6699

    jr c, @+$25

    jr c, jr_012_669f

jr_012_667b:
    jr c, @+$27

    jr c, jr_012_66a5

    jr c, @+$29

jr_012_6681:
    jr c, jr_012_66ab

    jr c, @+$2b

    jr c, jr_012_66b1

jr_012_6687:
    jr c, @+$2d

    jr c, jr_012_66b7

    jr c, @+$2f

jr_012_668d:
    jr c, jr_012_66bd

    jr c, @+$31

    jr c, jr_012_66c3

jr_012_6693:
    jr c, @+$33

    jr c, jr_012_66c9

    jr c, jr_012_66cc

jr_012_6699:
    jr c, @+$36

    jr c, jr_012_66d2

    jr c, jr_012_66d5

jr_012_669f:
    jr c, jr_012_66d8

    jr c, jr_012_66db

    jr c, jr_012_66de

jr_012_66a5:
    jr c, jr_012_66e1

    jr c, jr_012_66e4

    jr c, jr_012_66e7

jr_012_66ab:
    jr c, jr_012_66ea

    jr c, jr_012_66ed

    jr c, jr_012_66f0

jr_012_66b1:
    jr c, @+$42

    jr c, jr_012_66f6

    jr c, jr_012_66f9

jr_012_66b7:
    jr c, jr_012_66fc

    jr c, @+$46

    jr c, jr_012_6702

jr_012_66bd:
    jr c, @+$48

    jr c, jr_012_6708

    jr c, jr_012_66c3

jr_012_66c3:
    add hl, sp
    ld bc, $0239
    add hl, sp
    inc bc

jr_012_66c9:
    add hl, sp
    inc b
    add hl, sp

jr_012_66cc:
    dec b
    add hl, sp
    ld b, $39
    rlca
    add hl, sp

jr_012_66d2:
    ld [$0939], sp

jr_012_66d5:
    add hl, sp
    ld a, [bc]
    add hl, sp

jr_012_66d8:
    dec bc
    add hl, sp
    inc c

jr_012_66db:
    add hl, sp
    dec c
    add hl, sp

jr_012_66de:
    ld c, $39
    rrca

jr_012_66e1:
    add hl, sp
    db $10
    add hl, sp

jr_012_66e4:
    ld de, $1239

jr_012_66e7:
    add hl, sp
    inc de
    add hl, sp

jr_012_66ea:
    inc d
    add hl, sp
    dec d

jr_012_66ed:
    add hl, sp
    ld d, $39

jr_012_66f0:
    rla
    add hl, sp
    jr jr_012_672d

    add hl, de
    add hl, sp

jr_012_66f6:
    ld a, [de]
    add hl, sp
    dec de

jr_012_66f9:
    add hl, sp
    inc e
    add hl, sp

jr_012_66fc:
    dec e
    add hl, sp
    ld e, $39
    rra
    add hl, sp

jr_012_6702:
    jr nz, jr_012_673d

    ld hl, $2239
    add hl, sp

jr_012_6708:
    inc hl
    add hl, sp
    inc h
    add hl, sp
    dec h
    add hl, sp
    ld h, $39
    daa
    add hl, sp
    jr z, jr_012_674d

    add hl, hl
    add hl, sp
    ld a, [hl+]
    add hl, sp
    dec hl
    add hl, sp
    inc l
    add hl, sp
    dec l
    add hl, sp
    ld l, $39
    cpl
    add hl, sp
    jr nc, jr_012_675d

    ld sp, $3239
    add hl, sp
    inc sp
    add hl, sp
    inc [hl]
    add hl, sp
    dec [hl]

jr_012_672d:
    add hl, sp
    ld [hl], $39
    scf
    add hl, sp
    jr c, jr_012_676d

    add hl, sp
    add hl, sp
    ld a, [hl-]
    add hl, sp
    dec sp
    add hl, sp
    inc a
    add hl, sp
    dec a

jr_012_673d:
    add hl, sp
    ld a, $39
    ccf
    add hl, sp
    ld b, b
    add hl, sp
    ld b, c
    add hl, sp
    ld b, d
    add hl, sp
    ld b, e
    add hl, sp
    ld b, h
    add hl, sp
    ld b, l

jr_012_674d:
    add hl, sp
    ld b, [hl]
    add hl, sp
    ld b, a
    add hl, sp
    nop
    ld a, [hl-]
    ld bc, $023a
    ld a, [hl-]
    inc bc
    ld a, [hl-]
    inc b
    ld a, [hl-]
    dec b

jr_012_675d:
    ld a, [hl-]
    ld b, $3a
    rlca
    ld a, [hl-]
    ld [$093a], sp
    ld a, [hl-]
    ld a, [bc]
    ld a, [hl-]
    dec bc
    ld a, [hl-]
    inc c
    ld a, [hl-]
    dec c

jr_012_676d:
    ld a, [hl-]
    ld c, $3a
    rrca
    ld a, [hl-]
    db $10
    ld a, [hl-]
    ld de, $123a
    ld a, [hl-]
    inc de
    ld a, [hl-]
    inc d
    ld a, [hl-]
    dec d
    ld a, [hl-]
    ld d, $3a
    rla
    ld a, [hl-]
    jr jr_012_67be

    add hl, de
    ld a, [hl-]
    ld a, [de]
    ld a, [hl-]
    dec de
    ld a, [hl-]
    inc e
    ld a, [hl-]
    dec e
    ld a, [hl-]
    ld e, $3a
    rra
    ld a, [hl-]
    jr nz, @+$3c

    ld hl, $223a
    ld a, [hl-]
    inc hl
    ld a, [hl-]
    inc h
    ld a, [hl-]
    dec h
    ld a, [hl-]
    ld h, $3a
    daa
    ld a, [hl-]
    jr z, jr_012_67de

    add hl, hl
    ld a, [hl-]
    ld a, [hl+]
    ld a, [hl-]
    dec hl
    ld a, [hl-]
    inc l
    ld a, [hl-]
    dec l
    ld a, [hl-]
    ld l, $3a
    cpl
    ld a, [hl-]
    jr nc, jr_012_67ee

    ld sp, $323a
    ld a, [hl-]
    inc sp
    ld a, [hl-]
    inc [hl]
    ld a, [hl-]
    dec [hl]
    ld a, [hl-]

jr_012_67be:
    ld [hl], $3a

SetItem_67c0:
    ld hl, $ca94
    ld a, [$cac0]
    call TestBitInArray
    ret z

    ld a, [$da71]
    cp $ff
    jr z, jr_012_67d4

    cp $f0
    ret nc

jr_012_67d4:
    ld a, [$da72]
    cp $ff
    jr z, jr_012_67de

    cp $f0
    ret nc

jr_012_67de:
    ld a, [$da71]
    cp $ff
    jr z, jr_012_6810

    push af
    ld hl, $ffc3
    ld a, $48
    ld [hl+], a
    ld a, $00

jr_012_67ee:
    ld [hl+], a
    ld a, $28
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    pop af
    add $10
    ld [hl+], a
    ld b, $00
    ld a, [$c8a4]
    bit 4, a
    jr z, jr_012_6804

    ld b, $01

jr_012_6804:
    ld a, b
    ld [hl+], a
    ld a, $60
    ld [hl+], a
    ld a, $00
    ld [hl], a
    ld hl, $0403
    rst $10

jr_012_6810:
    ld a, [$da72]
    cp $ff
    ret z

    push af
    ld hl, $ffc3
    ld a, $48
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $38
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    pop af
    add $10
    ld [hl+], a
    ld b, $00
    ld a, [$c8a4]
    bit 4, a
    jr z, jr_012_6835

    ld b, $01

jr_012_6835:
    ld a, b
    ld [hl+], a
    ld a, $70
    ld [hl+], a
    ld a, $00
    ld [hl], a
    ld hl, $0403
    rst $10
    ret


    ld a, [$c905]
    rst $00
    ld d, b
    ld l, b
    and b
    ld l, b
    and l
    ld l, b
    call nz, $c668
    ld l, b
    ld hl, $ffb7
    call ReadItem_4028
    ld hl, $ffbb
    call ReadItem_4028
    ld a, $ff
    ld [$c8f4], a
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ldh a, [$bb]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ldh a, [$b7]
    rrca
    rrca
    rrca
    add l
    ld l, a
    ld a, h
    adc $98
    ld h, a
    ld a, h
    and $03
    or $98
    ld h, a
    ld a, l
    ld [$c909], a
    ld a, h
    ld [$c90a], a
    call SetItem_41ef
    ld de, MenuBorderFill
    ld hl, $8800
    call WaitDMATransfer
    call ClrItem_4323
    ld hl, $c905
    inc [hl]
    ret


    ld hl, $c905
    inc [hl]
    ret


    ld hl, $c905
    inc [hl]
    xor a
    ld [$c906], a
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ret


    jr jr_012_68dc

    call SetItem_41ef
    ld de, $2e07
    call ReadPtrFromDE
    call GetScreenPos
    ld hl, wGameState
    res 4, [hl]
    xor a
    ld [$c905], a
    ret


jr_012_68dc:
    ld a, [$c906]
    rst $00
    ld a, [c]
    ld l, b
    jr z, jr_012_694d

    xor a
    ld l, c
    rst $30
    ld l, c
    ld b, $6a
    ld a, [hl+]
    ld l, d
    ld l, b
    ld l, d
    db $e3
    ld l, d
    db $ed
    ld l, d
    call LoadItem_6903
    call SetItem_690a
    ld hl, $0003
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ret


LoadItem_6903:
    ld a, [$ca8d]
    ld [$c8e9], a
    ret


SetItem_690a:
    ld hl, $c0d8
    ld bc, $0014
    ld a, $ff
    call FillNBytesWithRegA
    ld a, [$ca8e]
    ld [$c0d8], a
    ld a, [$ca8f]
    ld [$c0d9], a
    ld a, [$ca90]
    ld [$c0da], a
    ret


    ld a, [$c825]
    or a
    ret nz

    call LoadItem_695d
    call CallItem_6938
    ld hl, $c906
    inc [hl]
    ret


CallItem_6938:
    call SetItem_41ef
    ld de, $2e07
    call ReadPtrFromDE
    ld de, $724e
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $69ed

jr_012_694d:
    ld b, $03
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadItem_43c0
    call GetScreenPos
    ret


LoadItem_695d:
    ld a, [$c8e3]
    add a
    add a
    ld de, $c0d8
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $8800
    call SaveItem_6974
    call SaveItem_6974

SaveItem_6974:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr z, jr_012_6995

    ld a, [de]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    pop hl
    push hl
    call SaveItem_4153
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


jr_012_6995:
    ld b, $20

jr_012_6997:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_012_6997

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


    ld de, $69ed
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $03
    inc hl
    ld a, [hl-]
    push af
    ld a, [hl]
    push af
    call LoadItem_4241
    pop af
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_012_69ce

    call LoadItem_695d

jr_012_69ce:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_69db

    ld hl, $c905
    inc [hl]
    jr jr_012_69ec

jr_012_69db:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_69ec

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]

Jump_012_69ec:
jr_012_69ec:
    ret


    dec b
    ld bc, $0061
    and c
    nop
    pop hl
    nop
    rst $38
    rst $38
    ld hl, $0005
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    xor a
    ld [$c8de], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    ld de, $6dcb
    call ReadPtrFromDE
    call ClrItem_4323
    ld de, $6a62
    ld a, [$c8de]
    call FuncItem_43e2
    call GetScreenPos
    ld hl, $c906
    inc [hl]
    ret


    ld de, $6a62
    ld hl, $c8de
    ld b, $02
    call FuncItem_42ca
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_012_6a49

jr_012_6a3c:
    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c906], a
    jr jr_012_6a61

jr_012_6a49:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_012_6a61

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8de]
    cp $81
    jr z, jr_012_6a3c

    ld hl, $c906
    inc [hl]

Jump_012_6a61:
jr_012_6a61:
    ret


    cpl
    ld bc, $016f
    rst $38
    rst $38
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
    ld hl, $cacd
    call GetMonsterDataPtr
    ld de, $ca42
    ld b, $09

jr_012_6a8c:
    ld a, [de]
    cp [hl]
    jr z, jr_012_6a9f

    ld hl, $0004
    call AddCursorOffset
    ld hl, $c906
    inc [hl]
    ld hl, $c906
    inc [hl]
    ret


jr_012_6a9f:
    inc de
    inc hl
    dec b
    jr nz, jr_012_6a8c

    ld a, [$cac0]
    ld hl, $caca
    call GetMonsterDataPtr
    ld a, [hl]
    add $10
    ld [$c8f4], a
    ld a, [$cac0]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld a, l
    ld [$c8f2], a
    ld a, h
    ld [$c8f3], a
    ld a, [$cac0]
    ld hl, $cacc
    call GetMonsterDataPtr
    ld a, [hl]
    ld [$c8f6], a
    ld a, [$cac0]
    ld hl, $caca
    call GetMonsterDataPtr
    ld a, [hl]
    ld [$c8f5], a
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $c905
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $0001
    call AddCursorOffset
    ld a, $01
    ld [$c906], a
    ret


    ld a, [$c905]
    rst $00
    ld c, $6b
    ld a, h
    ld l, e
    xor $6b
    sub b
    ld l, h
    xor d
    ld l, h
    ld a, [de]
    ld l, l
    ld hl, wInventory
    ld b, $14
    ld c, $00

jr_012_6b15:
    ld a, [hl]
    cp ITEM_TINY_MEDAL
    jr nz, jr_012_6b1d

    ld [hl], $ff
    inc c

jr_012_6b1d:
    inc hl
    dec b
    jr nz, jr_012_6b15

    ld a, c
    ld [$c907], a
    or a
    jr z, jr_012_6b77

    ld a, [$c903]
    ld l, a
    ld a, [$c904]
    ld h, a
    ld a, [$c907]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, l
    ld [$c903], a
    ld a, h
    ld [$c904], a
    ld a, l
    sub $e7
    ld l, a
    ld a, h
    sbc $03
    ld h, a
    jr c, jr_012_6b56

    ld hl, $03e7
    ld a, l
    ld [$c903], a
    ld a, h
    ld [$c904], a

jr_012_6b56:
    ld hl, $0305
    rst $10
    ld a, [$d9e1]
    cp $04
    jr z, jr_012_6b6c

    ld hl, $0001
    call AddCursorOffset
    ld hl, $c905
    inc [hl]
    ret


jr_012_6b6c:
    ld hl, $000f
    call AddCursorOffset
    ld hl, $c905
    inc [hl]
    ret


jr_012_6b77:
    ld hl, $c905
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$c903]
    ld c, a
    ld a, [$c904]
    ld b, a
    ld hl, $c180
    call FormatDecimalDigits
    ld a, [$d9e1]
    cp $04
    jr z, jr_012_6bd0

    ld a, [$d9e1]
    add a
    add a
    ld hl, $6d29
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    push bc
    ld hl, $c190
    call FormatDecimalDigits
    pop bc
    ld a, [$c903]
    ld l, a
    ld a, [$c904]
    ld h, a
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    jr c, jr_012_6bca

    ld hl, $0002
    call AddCursorOffset
    ld hl, $c905
    inc [hl]
    ret


jr_012_6bca:
    ld a, $04
    ld [$c905], a
    ret


jr_012_6bd0:
    ld a, [$c907]
    or a
    jr z, jr_012_6bca

    ld a, [$c907]
    ld c, a
    ld b, $00
    ld hl, $c180
    call FormatDecimalDigits
    ld hl, $0010
    call AddCursorOffset
    ld a, $04
    ld [$c905], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $cac1
    ld b, $14
    ld c, $00

jr_012_6bfa:
    ld a, [hl]
    or a
    jr z, jr_012_6c0a

    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    inc c
    dec b
    jr nz, jr_012_6bfa

jr_012_6c0a:
    ld a, c
    cp $14
    jr nc, jr_012_6c84

    ld a, c
    ld [$da14], a
    ld a, [$d9e1]
    add a
    add a
    ld hl, $6d2b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, c
    ld [wTempEnemyStatsId], a
    ld a, b
    ld [$da13], a
    ld hl, $1402
    rst $10
    ld a, [$da14]
    ld hl, $cb24
    call GetMonsterDataPtr
    ld [hl], $01
    ld a, [$d9e1]
    ld bc, $0050
    cp $00
    jr z, jr_012_6c78

    ld bc, $0051
    cp $01
    jr z, jr_012_6c78

    ld bc, $0052
    cp $02
    jr z, jr_012_6c78

    ld bc, $0053
    cp $03
    jr z, jr_012_6c78

    ld bc, $0054
    cp $04
    jr z, jr_012_6c78

    ld bc, $0055
    cp $05
    jr z, jr_012_6c78

    ld bc, $0056
    cp $06
    jr z, jr_012_6c78

    ld bc, $0057
    cp $07
    jr z, jr_012_6c78

    jr jr_012_6c7b

jr_012_6c78:
    call SetEventFlag

jr_012_6c7b:
    ld hl, $d9e1
    inc [hl]
    ld hl, $c905
    inc [hl]
    ret


jr_012_6c84:
    ld hl, $000b
    call AddCursorOffset
    ld a, $05
    ld [$c905], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$d9e1]
    ld hl, $0002
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call AddCursorOffset
    ld a, $05
    ld [$c905], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$c903]
    ld c, a
    ld a, [$c904]
    ld b, a
    ld hl, $c180
    call FormatDecimalDigits
    ld a, [$d9e1]
    cp $04
    jr z, jr_012_6d0f

    ld a, [$d9e1]
    add a
    add a
    ld hl, $6d29
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $c190
    call FormatDecimalDigits
    ld a, [$d9e1]
    add a
    add a
    ld hl, $6d2b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, c
    ld [wTempEnemyStatsId], a
    ld a, b
    ld [$da13], a
    ld hl, $1400
    rst $10
    ld a, [$da18]
    ld l, a
    ld h, $05
    ld de, $c1a0
    call SetupVRAMParams
    ld hl, $000c
    call AddCursorOffset
    ld hl, $c905
    inc [hl]
    ret


jr_012_6d0f:
    ld hl, $0011
    call AddCursorOffset
    ld hl, $c905
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wGameState
    res 4, [hl]
    xor a
    ld [$c905], a
    ret


    dec c
    nop
    ld d, b
    ld bc, $0012
    ld d, c
    ld bc, $0019
    ld d, e
    ld bc, $001e
    ld d, h
    ld bc, $ffff
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

    cp $b0
    or c
    or d
    or e
    or h
    or l
    or [hl]
    or a
    cp b
    cp c
    cp d
    cp e
    cp h
    cp l
    cp [hl]
    cp a
    ret nz

    pop bc
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

    cp $c2
    jp $c5c4


    add $c7
    ret z

    ret


    jp z, $cccb

    call $cfce
    ret nc

    pop de
    jp nc, $ffd3

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
    ld sp, $e032
    rst $38
    ret c

    db $fc
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
    sbc h
    ldh [rIE], a
    ret c

    db $fc
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
    xor b
    and a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    inc c
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $dd
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


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and h
    xor d
    call nc, $e0e0
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sub $d5
    sbc $de
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    push de
    xor e
    and l
    xor c
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    add c
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
    ei
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
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
    rst $38
    ret c

    cp $e0
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
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
    rst $38
    ret c

    cp $e0
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
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
    rst $38
    ret c

    cp $e0
    sbc e
    sbc h
    sbc l
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
    ldh [$e0], a
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
    xor $fd
    reti


    ld b, b
    ld bc, $effa
    rst $28
    ei
    ret c

    cp $e0
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    db $fd
    reti


    ld b, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ldh [$e5], a
    ldh [$e0], a
    rst $38
    ret c

    db $fc
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
    call nc, $d6d5
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc l
    sbc h
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    adc b
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
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
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
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
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
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
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
    sbc e
    sbc h
    sbc l
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
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


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and h
    push de
    and a
    xor b
    xor c
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    xor d
    xor e
    xor h
    ldh [$e0], a
    rst $38
    ret c

    db $fc
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
    ei
    ret c

    cp $e0
    and h
    and l
    and [hl]
    and a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    xor b
    xor c
    xor d
    xor e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    ld l, b
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
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
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
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
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
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
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
    sbc e
    sbc h
    sbc l
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
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


    ld l, h
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $dd
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


    ld b, [hl]
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
    ei
    ret c

    cp $a0
    and c
    and d
    and e
    ldh [$dd], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
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
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub d
    sbc b
    sbc h
    db $e3
    ldh [$9c], a
    sub e
    sub e
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
    db $e3
    sub l
    sub c
    sub [hl]
    ldh [$9a], a
    db $e3
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
    sub c
    sub h
    push de
    sub c
    sub [hl]
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
    sub $d5
    db $e3
    sub b
    sbc b
    sub b
    sbc c
    push de
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
    sub $97
    push de
    push de
    db $e3
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
    push de
    and d
    sub l
    sbc c
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    dec c
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc e
    sub h
    sbc h
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
    add b
    add c
    add d
    add e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add h
    add l
    add [hl]
    add a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc b
    adc c
    adc d
    adc e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    dec c
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc e
    sub h
    sbc h
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
    add b
    add c
    add d
    add e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add h
    add l
    add [hl]
    add a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc b
    adc c
    adc d
    adc e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc e
    sub h
    sbc h
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
    add b
    add c
    add d
    add e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add h
    add l
    add [hl]
    add a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc b
    adc c
    adc d
    adc e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc e
    sub h
    sbc h
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
    add b
    add c
    add d
    add e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add h
    add l
    add [hl]
    add a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc b
    adc c
    adc d
    adc e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    dec c
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub l
    sbc l
    sub e
    sbc h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sbc h
    sub [hl]
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
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
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $9e
    sub b
    sub $99
    push de
    sbc b
    db $e4
    and b
    and c
    and d
    and e
    ldh [$e0], a
    ldh [$e4], a
    ldh [$e0], a
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
    rst $38
    ret c

    cp $da
    and h
    and l
    and [hl]
    and a
    ldh [$db], a
    xor b
    xor c
    xor d
    xor e
    ldh [$dc], a
    xor h
    xor l
    xor [hl]
    xor a
    rst $38
    ret c

    cp $e0
    sbc a
    db $e4
    ldh [$e0], a
    ldh [$e0], a
    sbc a
    db $e4
    ldh [$e0], a
    ldh [$e0], a
    sbc a
    db $e4
    ldh [$e0], a
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
    xor $fd
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
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $84
    ldh [$80], a
    ldh [$91], a
    sub a
    sub b
    sub $d6
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
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
    rst $38
    ret c

    cp $85
    ldh [$81], a
    ldh [$91], a
    sub a
    sub b
    sub $d6
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
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
    rst $38
    ret c

    cp $86
    ldh [$82], a
    ldh [$91], a
    sub a
    sub b
    sub $d6
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
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
    rst $38
    ret c

    cp $87
    ldh [$83], a
    ldh [$91], a
    sub a
    sub b
    sub $d6
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
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
    xor $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    adc d
    sbc b
    push de
    push de
    sub d
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub h
    sub b
    sbc c
    sub c
    sub h
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld b, b
    ld b, c
    ld b, d
    ld b, e
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $fd
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
    sbc e
    sub h
    sbc h
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
    ld h, c
    ld h, d
    ld h, e
    ld h, h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld l, l
    ld l, [hl]
    ld l, a
    ld [hl], b
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
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
    sbc e
    sub h
    sbc h
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
    ld h, c
    ld h, d
    ld h, e
    ld h, h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld l, l
    ld l, [hl]
    ld l, a
    ld [hl], b
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    add hl, bc
    ld bc, $effa
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
    ldh [$e0], a
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
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
    ldh [$e0], a
    db $76
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    xor c
    nop
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
    ldh [$e0], a
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    ld c, c
    ld bc, $effa
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
    ldh [$e0], a
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    ld b, b
    ld bc, $effa
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
    ldh [$e0], a
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ld a, h
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    add a
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
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    ld l, l
    and b
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
    ld l, [hl]
    ld l, a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    and c
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
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ld a, h
    ld a, l
    ld a, [hl]
    ld a, a
    and d
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
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    and e
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
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    push de
    rst $18
    sbc a
    sbc $e0
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    xor b
    sbc $d5
    sub $d6
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    push de
    and l
    and c
    and e
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    add a
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
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    ld a, b
    sbc e
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
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    sbc h
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
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    sbc l
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
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    sbc [hl]
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
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and h
    and l
    and [hl]
    and a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    xor b
    xor c
    xor d
    xor e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    xor h
    xor l
    xor [hl]
    xor a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
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
    ei
    ret c

    cp $e0
    ldh [$9e], a
    sbc a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$a0], a
    and c
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $63
    ldh [$9e], a
    sbc a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $63
    ldh [$a0], a
    and c
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    add a
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
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    ld l, l
    adc h
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
    ld l, [hl]
    ld l, a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    adc l
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
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ld a, h
    ld a, l
    ld a, [hl]
    ld a, a
    adc [hl]
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
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    adc a
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
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub l
    sbc l
    sub e
    sbc h
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc h
    sub [hl]
    ldh [$e0], a
    ldh [rIE], a
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
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and c
    and a
    xor c
    and h
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    and h
    and d
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
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
    sbc h
    ldh [rIE], a
    ret c

    db $fc
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

    cp $e0
    ld h, a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ld l, h
    ld l, l
    ld l, [hl]
    ld l, a
    ld [hl], b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    db $76
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ld a, e
    ld a, h
    ld a, l
    ld a, [hl]
    ld a, a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ld [$fa00], sp
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
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
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
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
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
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
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
    sbc e
    sbc h
    sbc l
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
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
    and h
    and l
    and [hl]
    and a
    xor b
    xor c
    xor d
    xor e
    xor h
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


    nop
    nop
    ld bc, $0202
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    inc bc
    ret c

    inc b
    add b
    add c
    add d
    add e
    add h
    add l
    nop
    nop
    inc d
    dec d
    ld d, $17
    jr jr_012_7a05

    ld a, [de]
    dec de
    inc e
    nop
    dec b
    ret c

    inc b
    add [hl]
    add a
    adc b
    adc c
    adc d
    adc e
    nop
    ld a, [bc]
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    inc c

jr_012_7a05:
    dec b
    ret c

    inc b
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec b
    ret c

    inc b
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    ld de, $0000
    dec e
    ld e, $1f
    jr nz, jr_012_7a4c

    ld [hl+], a
    inc hl
    inc h
    dec h
    dec b
    ret c

    inc b
    sbc b
    sbc c
    sbc d
    sbc e
    sbc h
    sbc l
    ld [de], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec b
    ret c

    inc b
    sbc [hl]
    sbc a
    and b
    and c
    and d

jr_012_7a4c:
    and e
    nop
    nop
    nop
    ld h, $27
    jr z, jr_012_7a7d

    ld a, [hl+]
    dec hl
    inc l
    dec l
    ld l, $05
    ret c

    inc b
    dec c
    ld c, $0e
    ld c, $0e
    ld c, $0e
    ld c, $0e
    ld c, $0e
    ld c, $0e
    ld c, $0e
    ld c, $0e
    rrca
    dec b
    ret c

    inc b
    and l
    and [hl]
    and a
    xor b
    xor c
    xor d
    nop
    nop
    nop
    cpl
    jr nc, jr_012_7aae

jr_012_7a7d:
    ld [hl-], a
    inc sp
    inc [hl]
    dec [hl]
    ld [hl], $37
    dec b
    ret c

    inc b
    db $10
    db $10
    db $10
    db $10
    db $10
    db $10
    db $10
    stop
    jr c, jr_012_7aca

    ld a, [hl-]
    dec sp
    inc a
    dec a
    ld a, $3f
    ld b, b
    dec b
    ret c

    inc b
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld b, c
    ld b, d
    ld b, e
    ld b, h
    ld b, l
    ld b, [hl]
    ld b, a
    ld c, b
    ld c, c
    dec b

jr_012_7aae:
    ret c

    inc b
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec b
    ret c

    inc b
    ld c, d
    ld c, e
    ld c, h
    ld c, l
    ld c, [hl]

jr_012_7aca:
    ld c, a
    ld d, b
    ld d, c
    ld d, d
    ld d, e
    ld d, h
    ld d, l
    ld d, [hl]
    ld d, a
    ld e, b
    ld e, c
    ld e, d
    ld e, e
    dec b
    ret c

    inc b
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    dec b
    ret c

    inc b
    ld e, h
    ld e, l
    ld e, [hl]
    ld e, a
    ld h, b
    ld h, c
    ld h, d
    ld h, e
    ld h, h
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    ld l, l
    dec b
    ret c

    inc b
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    dec b
    ret c

    inc b
    ld l, [hl]
    ld l, a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ld a, h
    ld a, l
    ld a, [hl]
    ld a, a
    dec b
    ret c

    ld b, $07
    ld [$0808], sp
    ld [$0808], sp
    ld [$0808], sp
    ld [$0808], sp
    ld [$0808], sp
    ld [$0908], sp
    reti


    nop
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub l
    sbc l
    sub e
    sbc h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sbc h
    sub [hl]
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub l
    sbc l
    sub e
    sbc h
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc h
    sub [hl]
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
