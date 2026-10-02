; Disassembly of "game.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $056", ROMX[$4000], BANK[$56]

    db $56 ;rom bank 
    db $01, $49, $08, $49, $0f, $49, $16, $49, $46, $4a, $85, $44, $c7, $44, $3f
    db $40, $64, $40, $67, $68, $82, $68, $a3, $68, $c6, $68, $71, $6a, $c7, $6b, $a8
    db $6c, $0f, $6d, $7d, $6d, $de, $6d, $30, $6e, $96, $6e, $d6, $6e, $25, $6f, $8a
    db $6f, $da, $6f, $0c, $70, $5e, $70, $c1, $70, $37, $71, $b0, $71, $18, $72

    xor a
    ld hl, $9800
    ld de, $4085

jr_056_4046:
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, h
    cp $9b
    jr nz, jr_056_4046

    ld a, l
    cp $ff
    jr nz, jr_056_4046

    ld a, [de]
    ld [hl], a
    ld a, $43
    ld [$c8a1], a
    ld a, $63
    ld [$c8a1], a
    ld a, $01
    jp EnableLCDAndInterrupts


    ld a, [$c842]
    and $01
    cp $01
    jr nz, jr_056_4084

    ld hl, $c8ad
    ld a, [hl+]
    ld [wGameMode], a
    ld a, [hl+]
    ld [$c88b], a
    ld a, [hl+]
    ld [$c88c], a
    ld a, [hl]
    ld [$c88d], a
    ld hl, $c88e
    inc [hl]

jr_056_4084:
    ret


    nop
    ld bc, $0302
    inc b
    dec b
    ld b, $07
    ld [$0a09], sp
    dec bc
    inc c
    dec c
    ld c, $0f
    rst $38
    rst $38

jr_056_4097:
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
    db $10
    ld de, $1312
    inc d
    dec d
    ld d, $17
    jr jr_056_40c8

    ld a, [de]
    dec de

jr_056_40b1:
    inc e
    dec e
    ld e, $1f
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
    jr nz, jr_056_40e8

    ld [hl+], a

jr_056_40c8:
    inc hl
    inc h
    dec h
    ld h, $27
    jr z, jr_056_40f8

    ld a, [hl+]
    dec hl
    inc l
    dec l
    ld l, $2f
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
    jr nc, jr_056_4118

    ld [hl-], a

jr_056_40e8:
    inc sp
    inc [hl]
    dec [hl]
    ld [hl], $37
    jr c, jr_056_4128

    ld a, [hl-]
    dec sp
    inc a
    dec a
    ld a, $3f
    rst $38
    rst $38
    rst $38

jr_056_40f8:
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
    ld b, b
    ld b, c
    ld b, d
    ld b, e
    ld b, h
    ld b, l
    ld b, [hl]
    ld b, a
    ld c, b
    ld c, c
    ld c, d
    ld c, e
    ld c, h
    ld c, l
    ld c, [hl]
    ld c, a
    rst $38
    rst $38
    rst $38

jr_056_4118:
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
    ld d, b
    ld d, c
    ld d, d

jr_056_4128:
    ld d, e
    ld d, h
    ld d, l
    ld d, [hl]
    ld d, a
    ld e, b
    ld e, c
    ld e, d
    ld e, e
    ld e, h
    ld e, l
    ld e, [hl]
    ld e, a
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
    ld l, [hl]
    ld l, a
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
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
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
    sub b
    sub c
    sub d
    sub e
    sub h
    sub l
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
    xor d
    xor e
    xor h
    xor l
    xor [hl]
    xor a
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
    or b
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
    ret nz

    pop bc
    jp nz, $c4c3

    push bc
    add $c7
    ret z

    ret


    jp z, $cccb

    call $cfce
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
    ret nc

    pop de
    jp nc, $d4d3

    push de
    sub $d7
    ret c

    reti


    jp c, $dcdb

    db $dd
    sbc $df
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
    ldh [$e1], a
    ld [c], a
    db $e3
    db $e4
    push hl
    and $e7
    add sp, -$17
    ld [$eceb], a
    db $ed
    xor $ef
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
    ldh a, [$f1]
    ld a, [c]
    di
    db $f4
    push af
    or $f7
    ld hl, sp-$07
    ld a, [$fcfb]
    db $fd
    cp $ff
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

SetB56_4485:
    ld hl, $c829	
    ld a, [hl+]
    or [hl]
    ret z

    ld a, [$c827]	;loads address to start of which vram bank to load to into hl and 
    ld l, a
    ld a, [$c828]
    ld h, a
    ld a, [$c82a]
    ld c, a

jr_056_4497:
    ld a, [$c829]
    ld b, a

jr_056_449b:
    push bc
    ld b, $10
    ld de, $44b7

jr_056_44a1:
    di

jr_056_44a2:		;copy blank tile from rom to vram when in vblank
    ldh a, [rSTAT]
    bit 1, a
    jr nz, jr_056_44a2

    ld a, [de]			;load byte of 2bpp tile into vram
    ld [hl+], a			;
    ei
    inc de
    dec b
    jr nz, jr_056_44a1

    pop bc
    dec b
    jr nz, jr_056_449b

    dec c
    jr nz, jr_056_4497

    ret


    INCBIN "gfx/image_056_44b7.2bpp"	;blank tile

    ld a, d
    ld [$c83a], a
    sub $e0
    rst $00

    ld c, $45
    ld c, $45
    ld c, $45
    ld c, $45
    ld c, $45
    ld c, $45
    ld c, $45
    ld de, $1f45
    ld b, l
    ld d, h
    ld b, l

    db $5e, $45

    ld l, c
    ld b, l
    ld [hl], h
    ld b, l
    and a
    ld b, l

    db $ad, $45, $40, $46, $fe, $46, $2b, $47

    ld c, a
    ld b, a
    ld e, b
    ld b, a
    ld [hl], c
    ld b, a
    ld a, h
    ld b, a

    db $82, $47, $b4, $47

    cp a
    ld b, a

    db $ce, $47, $1b, $48

    ld hl, $3548
    ld c, b
    ld c, c
    ld c, b
    ld c, a
    ld c, b
    ld d, l
    ld c, b
    jp Jump_056_4855


    call SetB56_4855
    ld a, $01
    ld [$c83c], a
    ld a, $ff
    ld [$c83a], a
    ret


    call GetTilemapByte
    ld d, $00
    call ReadNextTextByte
    ld e, a
    call GetTilemapByte
    call ReadNextTextByte
    ld c, a
    ld a, [$c82a]
    call Mul8x8To16
    add hl, de
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, [$c827]
    ld e, a
    ld a, [$c828]
    ld d, a
    add hl, de
    ld a, l
    ld [$c82b], a
    ld a, h
    ld [$c82c], a
    ld a, l
    ld [$c82f], a
    ld a, h
    ld [$c830], a
    ret


    call GetTilemapByte
    call ReadNextTextByte
    call PlaySoundEffect
    ret


    ld hl, $c826
    set 0, [hl]
    ld a, $5b
    ld [$c840], a
    ret


    ld hl, $c826
    set 0, [hl]
    ld a, $5a
    ld [$c840], a
    ret


    ld hl, $c826
    res 7, [hl]
    ld a, [wTextSpeed]
    cp $07
    jr z, jr_056_4593

    ld hl, $45a0
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$c836], a
    ld hl, $c825
    set 7, [hl]
    ret


jr_056_4593:
    ld hl, $c826
    res 7, [hl]
    ld hl, $c825
    set 2, [hl]
    set 5, [hl]
    ret


    ld b, $0c
    inc d
    ld a, [de]
    jr nz, @+$2a

    jr nc, jr_056_45c9

    ld h, $c8
    set 7, [hl]
    ret


    ld a, [$c827]
    ld e, a
    ld a, [$c828]
    ld d, a
    srl d
    rr e
    srl d
    rr e
    srl d
    rr e
    srl d
    rr e
    ld a, [$c829]
    ld c, a

jr_056_45c9:
    ld a, [$c82a]
    ld b, a
    ld a, [$c83e]
    ld l, a
    ld a, [$c83f]
    ld h, a
    push bc

jr_056_45d6:
    ld a, e
    call Write_gfx_tile
    call TilemapNextColumn
    inc e
    dec b
    jr nz, jr_056_45d6

    ld hl, $0020
    call AdjustTilemapOffset
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    call LoadTileE0
    ld a, [$c82a]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld c, l
    ld b, h
    push de
    ld a, [$c827]
    ld e, a
    ld a, [$c828]
    ld d, a
    add hl, de
    pop de

jr_056_4609:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec bc
    dec bc
    ld a, b
    or c
    jr nz, jr_056_4609

    pop bc
    ld hl, $0040
    call AdjustTilemapOffset

jr_056_461f:
    ld a, e
    call Write_gfx_tile
    call TilemapNextColumn
    inc e
    dec b
    jr nz, jr_056_461f

    ld a, [$c82f]
    ld l, a
    ld a, [$c830]
    ld h, a
    ld a, l
    ld [$c82b], a
    ld a, h
    ld [$c82c], a
    ld hl, $c825
    res 1, [hl]
    ret


    ld a, [$c82a]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, [$c827]
    ld e, a
    ld a, [$c828]
    ld d, a
    add hl, de
    ld a, [$c82f]
    ld e, a
    ld a, [$c830]
    ld d, a
    ld a, e
    sub l
    ld e, a
    ld a, d
    sbc h
    ld d, a
    ld a, d
    or e
    jr z, jr_056_4679

    ld a, l
    ld [$c82b], a
    ld a, h
    ld [$c82c], a
    ld a, l
    ld [$c82f], a
    ld a, h
    ld [$c830], a
    call GetTilemapByte
    ret


jr_056_4679:
    ld a, [$c83e]
    ld l, a
    ld a, [$c83f]
    ld h, a
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    call LoadTileE0
    ld a, [$c827]
    ld e, a
    ld a, [$c828]
    ld d, a
    srl d
    rr e
    srl d
    rr e
    srl d
    rr e
    srl d
    rr e
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    ld hl, $0020
    call AdjustTilemapOffset
    ld a, e
    add b
    ld e, a

jr_056_46b5:
    ld a, e
    call Write_gfx_tile
    call TilemapNextColumn
    inc e
    dec b
    jr nz, jr_056_46b5

    ld hl, $0040
    call AdjustTilemapOffset
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    call LoadTileE0
    ld a, [$c82a]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, [$c827]
    ld e, a
    ld a, [$c828]
    ld d, a
    ld c, l
    ld b, h
    add hl, de

jr_056_46e6:
    di
    call WaitVRAM
    ld a, [hl+]
    ei
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, jr_056_46e6

    ld hl, $c825
    set 7, [hl]
    ld a, $04
    ld [$c836], a
    ret


    ld a, [$c825]
    bit 4, a
    jp z, Jump_056_4722

    ld a, [$c825]
    res 4, a
    ld [$c825], a
    call HandleScreenRefresh
    ld a, [$c831]
    ld l, a
    ld a, [$c832]
    ld h, a
    ld a, l
    ld [$c82d], a
    ld a, h
    ld [$c82e], a
    ret


Jump_056_4722:
    xor a
    ld [$c825], a
    xor a
    ld [$c826], a
    ret


    ld a, [$c82a]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, [$c82f]
    ld e, a
    ld a, [$c830]
    ld d, a
    add hl, de
    ld a, l
    ld [$c82b], a
    ld a, h
    ld [$c82c], a
    ld a, l
    ld [$c82f], a
    ld a, h
    ld [$c830], a
    ret


    call HandleScreenRefresh
    call SetB56_4771
    call SetB56_4485
    ld a, [$c827]
    ld l, a
    ld a, [$c828]
    ld h, a
    ld a, l
    ld [$c82b], a
    ld a, h
    ld [$c82c], a
    ld a, l
    ld [$c82f], a
    ld a, h
    ld [$c830], a
    ret


SetB56_4771:
    ld hl, $c826
    res 7, [hl]
    ld hl, $c825
    res 1, [hl]
    ret


    ld hl, $c825
    set 1, [hl]
    ret


    ld hl, $ca42
    ld de, $c0c8
    ld b, $08

jr_056_478a:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_056_478a

    ld a, $f0
    ld [de], a
    ld hl, $c825
    set 4, [hl]
    ld a, [$c82d]
    ld l, a
    ld a, [$c82e]
    ld h, a
    ld a, l
    ld [$c831], a
    ld a, h
    ld [$c832], a
    ld hl, $c0c8
    ld a, l
    ld [$c82d], a
    ld a, h
    ld [$c82e], a
    ret


    ld hl, $c825
    set 2, [hl]
    ld hl, $c826
    res 7, [hl]
    ret


    ld hl, $c825
    set 3, [hl]
    call GetTilemapByte
    call ReadNextTextByte
    ld [$c833], a
    ret


    ld hl, $c825
    set 4, [hl]
    ld a, [$c82d]
    ld l, a
    ld a, [$c82e]
    ld h, a
    ld a, l
    ld [$c831], a
    ld a, h
    ld [$c832], a
    ld a, [$c831]
    add $01
    ld [$c831], a
    ld a, [$c832]
    adc $00
    ld [$c832], a
    ld a, [wGameMode]
    cp $0b
    jr nz, jr_056_4806

    ld hl, $0d8a		;ptr to text "MSGBUF"
    ld a, l			;
    ld [$c82d], a
    ld a, h
    ld [$c82e], a
    ret


jr_056_4806:
    call ReadNextTextByte
    ld de, $c180
    add e
    ld l, a
    ld a, $00
    adc d
    ld h, a
    ld a, l
    ld [$c82d], a
    ld a, h
    ld [$c82e], a
    ret


    ld hl, $c825
    set 5, [hl]
    ret


    ld hl, $c825
    set 6, [hl]
    call GetTilemapByte
    call ReadNextTextByte
    ld [$c835], a
    ld hl, $c826
    res 7, [hl]
    ret


    ld hl, $c825
    set 7, [hl]
    call GetTilemapByte
    call ReadNextTextByte
    ld [$c836], a
    ld hl, $c826
    res 7, [hl]
    ret


    ld hl, $c826
    set 0, [hl]
    ret


    ld hl, $c826
    res 0, [hl]
    ret


;; YES/NO choice box (text code $E7; also $E6): backs the 18 visible BG rows
;; up to $C500 (32 cells per row from the screen's left column), then
;; SetB56_48a1 loads the cursor tiles and draws the 6x5 frame ($48DE, $D8 =
;; next row, $D9 = end) at screen row 8, column 14. Bank $00
;; ClearTextBitsRedraw ($070E) puts the 18 rows back. (S97 r2)
SetB56_4855:
Jump_056_4855:
    ld hl, $c826
    res 7, [hl]
    ld a, $5c
    call PlaySoundEffect
    ld hl, $0000
    call GetTilemapRowAddr
    ld de, $c500
    ld c, $12

jr_056_486a:
    ld b, $20
    push hl

jr_056_486d:
    di
    call WaitVRAM
    ld a, [hl]
    ei
    ld [de], a
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
    jr nz, jr_056_486d

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
    jr nz, jr_056_486a

    call SetB56_48a1
    ld hl, $c825
    set 2, [hl]
    xor a
    ld [$c83c], a
    ret


SetB56_48a1:
    ld de, $560a
    ld hl, $8e50
    call WaitDMATransfer
    ld hl, Boot
    call GetTilemapRowAddr
    ld b, $0e
    call TilemapAdvanceColumns
    ld de, $48de

jr_056_48b8:
    push hl

jr_056_48b9:
    ld a, [de]
    inc de
    cp $d9
    jr z, jr_056_48dc

    cp $d8
    jr nz, jr_056_48d4

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
    jr jr_056_48b8

jr_056_48d4:
    call Write_gfx_tile
    call TilemapNextColumn
    jr jr_056_48b9

jr_056_48dc:
    pop hl
    ret


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
    push hl
    and $e0
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


SetB56_4901:
    ld de, SkillDescModeTable
    call CallTextEngine
    ret


    ld de, SkillDescModeTable
    call RunTextHandler
    ret


CallB56_490f:
    call SetB56_4901
    call RequestScreenUpdate
    ret


    ld hl, $9000
    ld de, $1207
    call SetupVRAMCopy
    ld hl, wDebug_main_menu_option
    ld bc, $0010
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $9c00
    ld bc, $0400
    ld a, $1f
    call FillNBytesWithRegA
    ld hl, $9c00
    ld bc, $1204
    ld a, $80
    call SaveB56_4a0a
    xor a
    ld [$c8da], a
    xor a
    ldh [rVBK], a
    call SetB56_4996
    ld a, $00
    call SetBGM
    ld a, $0a
    ld [$df08], a
    xor a
    ld [$df03], a
    ld a, $98
    ld [$df04], a
    ld a, $8e
    ld [$df05], a
    ld a, $64
    ldh [$b6], a
    ld a, $07
    ldh [$b5], a
    ld h, $98
    ld l, $8e
    ld a, [hl+]
    ld [$df06], a
    ld a, [hl]
    ld [$df07], a
    ld a, $1f
    ld [$c83b], a
    ld a, $7f
    ld [$c83d], a
    xor a
    ld [$df0b], a
    ld [$df0c], a
    ld a, $43
    ld [$c8a1], a
    ld a, $63
    ld [$c8a1], a
    ld a, $01
    jp EnableLCDAndInterrupts


SetB56_4996:
    ld hl, $c817
    ld [hl], $00
    inc hl
    ld [hl], $00
    ld hl, $0801
    rst $10
    ld hl, $9100
    ld a, $00
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld de, $1002
    call LoadB56_49e2
    ld hl, $9300
    ld a, [$c88b]
    inc a
    ld [$c823], a
    ld de, $1004
    call LoadB56_49e2
    call SetB56_4a23
    ld hl, $9823
    ld bc, $1002
    ld a, $10
    call SaveB56_4a0a
    ld hl, $9883
    ld bc, $1004
    ld a, $30
    call SaveB56_4a0a
    call FuncB56_4a2f
    ret


LoadB56_49e2:
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    call CallB56_490f
    ret


LoadB56_49f6:
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    call SetB56_4901
    ret


SaveB56_4a0a:
jr_056_4a0a:
    push hl
    ld d, b

jr_056_4a0c:
    call Write_gfx_tile_and_inc_HL
    inc a
    dec b
    jr nz, jr_056_4a0c

    ld b, d
    ld e, a
    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, e
    dec c
    jr nz, jr_056_4a0a

    ret


SetB56_4a23:
    ld hl, $9800
    ld bc, $0400
    ld a, $1f
    call FillNBytesWithRegA
    ret


FuncB56_4a2f:
    ld b, $04
    ld hl, $988e
    ld c, $6f

jr_056_4a36:
    ld a, $70
    ld [hl+], a
    ld [hl-], a
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, jr_056_4a36

    ret


    call LoadB56_4a50
    call BlinkDebugMsgSelection
    call LoadB56_4dba
    ret


LoadB56_4a50:
    ld a, [wJoypad_current_frame]
    bit 6, a
    jr z, jr_056_4aa6

    ld a, [$df04]
    ld h, a
    ld a, [$df05]
    ld l, a
    ld a, [$df06]
    call Write_gfx_tile_and_inc_HL
    ld a, [$df07]
    call Write_gfx_tile
    ld a, [$df03]
    dec a
    cp $ff
    jr nz, jr_056_4a75

    ld a, $03

jr_056_4a75:
    ld [$df03], a
    ld c, a
    ld a, [$df02]
    add c
    ld [$df00], a
    ld a, [$df03]
    ld c, $20
    call Mul8x8To16
    ld a, l
    add $8e
    ld l, a
    ld a, h
    adc $98
    ld h, a
    ld a, h
    ld [$df04], a
    ld a, l
    ld [$df05], a
    call WaitVRAM
    ld a, [hl+]
    ld [$df06], a
    call WaitVRAM
    ld a, [hl]
    ld [$df07], a

jr_056_4aa6:
    ld a, [wJoypad_current_frame]	;check if down is pressed
    bit 7, a
    jr z, jr_056_4afb

    ld a, [$df04]
    ld h, a
    ld a, [$df05]
    ld l, a
    ld a, [$df06]
    call Write_gfx_tile_and_inc_HL
    ld a, [$df07]
    call Write_gfx_tile
    ld a, [$df03]
    inc a
    cp $04
    jr nz, jr_056_4aca

    xor a

jr_056_4aca:
    ld [$df03], a
    ld c, a
    ld a, [$df02]
    add c
    ld [$df00], a
    ld a, [$df03]
    ld c, $20
    call Mul8x8To16
    ld a, l
    add $8e
    ld l, a
    ld a, h
    adc $98
    ld h, a
    ld a, h
    ld [$df04], a
    ld a, l
    ld [$df05], a
    call WaitVRAM
    ld a, [hl+]
    ld [$df06], a
    call WaitVRAM
    ld a, [hl]
    ld [$df07], a

jr_056_4afb:
    ld a, [$c842]
    bit 4, a
    jp z, Jump_056_4b36

    ld a, [$df0b]
    inc a
    and $07
    ld [$df0b], a
    jr z, jr_056_4b0f

    ret


jr_056_4b0f:
    ld a, [$df07]
    inc a
    cp $80
    jr nz, jr_056_4b2b

    ld a, $70
    ld [$df07], a
    ld a, [$df06]
    inc a
    cp $80
    jr nz, jr_056_4b26

    ld a, $70

jr_056_4b26:
    ld [$df06], a
    jr Increment_msgdebug_option

jr_056_4b2b:
    ld [$df07], a

Increment_msgdebug_option:		
    ld a, [$df01]	
    inc a
    ld [$df01], a
    ret


Jump_056_4b36:
    ld a, [$c842]
    bit 5, a
    jp z, Jump_056_4b71

    ld a, [$df0c]
    inc a
    and $07
    ld [$df0c], a
    jr z, jr_056_4b4a

    ret


jr_056_4b4a:
    ld a, [$df07]
    dec a
    cp $6f
    jr nz, jr_056_4b66

    ld a, $7f
    ld [$df07], a
    ld a, [$df06]
    dec a
    cp $6f
    jr nz, jr_056_4b61

    ld a, $7f

jr_056_4b61:
    ld [$df06], a
    jr jr_056_4b69

jr_056_4b66:
    ld [$df07], a		;tile ID in Message Debug menu option. Current row stored in either df00 or df03. Option itself is stored in df01

jr_056_4b69:;decrese msg debug option
    ld a, [$df01]
    dec a
    ld [$df01], a
    ret


Jump_056_4b71:
    ld a, [wJoypad_current_frame]	;check if the B button is pressed
    bit 2, a				
    jr z, jr_056_4b9e			;if not, skip to the check for the A button

    ld a, [$c88b]			;load msg debug page into a and increment.
    inc a
    cp $0a			
    jr nz, jr_056_4b82			;if it reaches page $0a, skip the jump and reset it to $00

    ld a, $00

jr_056_4b82:
    ld [$c88b], a			;if the next page was not $0a, store the incremented value into the current page number
    ld hl, $c88e			;inc this to change the page
    inc [hl]				;see?
    ld a, [$c88b]
    ld c, $04
    call Mul8x8To16
    ld a, l
    ld [$df02], a
    ld [$df00], a
    ld a, $0c
    call PlaySoundEffect
    ret


jr_056_4b9e:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jp z, Jump_056_4d63

    ld a, [$df01]
    ld b, a
    ld a, [$df00]
    ld hl, $4e24
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    sub b
    jr nc, jr_056_4bce

    ld a, $00
    ld [$c822], a
    ld a, $0b
    ld [$c823], a
    ld de, $1204
    ld hl, $8800
    call LoadB56_49f6
    ret


jr_056_4bce:
    ld a, [$df01]
    ld [$c823], a
    ld a, [$df00]
    ld hl, $4dd4
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$c822], a
    ld hl, $4dfc
    ld a, [$df00]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$df0a], a
    ld de, $1204
    ld hl, $8800
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, [$df0a]
    rst $00

    ld l, $4c
    inc sp
    ld c, h

    db $52, $4c

    ld [hl], c
    ld c, h
    sub b
    ld c, h
    sub l
    ld c, h
    or h
    ld c, h
    db $d3
    ld c, h
    ld a, [c]
    ld c, h
    inc c
    ld c, l
    dec hl
    ld c, l
    ld c, d
    ld c, l
    ld c, a
    ld c, l

    db $54, $4d

    ld e, c
    ld c, l
    ld e, [hl]
    ld c, l
    ld hl, $4100
    rst $10
    ret


    ld a, [$c822]
    cp $00
    jr nz, jr_056_4c4d

    ld a, [$c823]
    cp $e2
    jr c, jr_056_4c4d

    sub $e2
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    jr jr_056_4c52

jr_056_4c4d:
    ld hl, $4200
    rst $10
    ret


jr_056_4c52:
    ld a, [$c822]
    cp $01
    jr nz, jr_056_4c6c

    ld a, [$c823]
    cp $98
    jr c, jr_056_4c6c

    sub $98
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    jr jr_056_4c71

jr_056_4c6c:
    ld hl, $4300
    rst $10
    ret


jr_056_4c71:
    ld a, [$c822]
    cp $01
    jr nz, jr_056_4c8b

    ld a, [$c823]
    cp $44
    jr c, jr_056_4c8b

    sub $44
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    jr jr_056_4c90

jr_056_4c8b:
    ld hl, $4400
    rst $10
    ret


jr_056_4c90:
    ld hl, $4500
    rst $10
    ret


    ld a, [$c822]
    cp $00
    jr nz, jr_056_4caf

    ld a, [$c823]
    cp $c8
    jr c, jr_056_4caf

    sub $c8
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    jr jr_056_4cb4

jr_056_4caf:
    ld hl, $4600
    rst $10
    ret


jr_056_4cb4:
    ld a, [$c822]
    cp $01
    jr nz, jr_056_4cce

    ld a, [$c823]
    cp $74
    jr c, jr_056_4cce

    sub $74
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    jr jr_056_4cd3

jr_056_4cce:
    ld hl, $4700
    rst $10
    ret


jr_056_4cd3:
    ld a, [$c822]
    cp $01
    jr nz, jr_056_4ced

    ld a, [$c823]
    cp $12
    jr c, jr_056_4ced

    sub $12
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    jr jr_056_4cf2

jr_056_4ced:
    ld hl, $4800
    rst $10
    ret


jr_056_4cf2:
    ld a, [$c823]
    add $12
    cp $e0
    jr c, jr_056_4d07

    sub $e0
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    jr jr_056_4d0c

jr_056_4d07:
    ld hl, $4900
    rst $10
    ret


jr_056_4d0c:
    ld a, [$c822]
    cp $02
    jr nz, jr_056_4d26

    ld a, [$c823]
    cp $c0
    jr c, jr_056_4d26

    sub $c0
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    jr jr_056_4d2b

jr_056_4d26:
    ld hl, $4a00
    rst $10
    ret


jr_056_4d2b:
    ld a, [$c822]
    cp $01
    jr nz, jr_056_4d45

    ld a, [$c823]
    cp $68
    jr c, jr_056_4d45

    sub $68
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    jr jr_056_4d54

jr_056_4d45:
    ld hl, $4b00
    rst $10
    ret


    ld hl, $4c00
    rst $10
    ret


    ld hl, $4d00
    rst $10
    ret


jr_056_4d54:
    ld hl, $4e00
    rst $10
    ret


    ld hl, $5906
    rst $10
    ret


    ld hl, $5600
    rst $10
    ret


Jump_056_4d63:
    ld a, [$c842]	;checks if start has been pressed. If it has, exit the function
    and $08
    cp $08
    jr nz, jr_056_4d79

    ld a, $07		;7, the ID for the debug main menu is loaded into the current screen byte.
    ld [wGameMode], a
    xor a
    ld [$c88b], a	;and it is reset to the first page. 
    ld hl, $c88e
    inc [hl]		;and inc c88e to change the screen. 

jr_056_4d79:
    ret


BlinkDebugMsgSelection:		;function for blinking the msg debug selection
    ld a, [$df08]
    cp $00
    jr nz, jr_056_4db5

    ld a, $0a
    ld [$df08], a
    ld a, [$df04]
    ld h, a
    ld a, [$df05]
    ld l, a
    ld a, [$df09]	;msg_debug selection blink flag
    cp $00
    jr nz, jr_056_4da3	

    ld a, $1f
    call Write_gfx_tile_and_inc_HL
    call Write_gfx_tile
    ld a, $01
    ld [$df09], a
    ret


jr_056_4da3:
    ld a, [$df06]
    call Write_gfx_tile_and_inc_HL
    ld a, [$df07]
    call Write_gfx_tile
    ld a, $00
    ld [$df09], a
    ret


jr_056_4db5:
    dec a
    ld [$df08], a
    ret


LoadB56_4dba:
    ld a, [$df06]
    sub $70
    rlca
    rlca
    rlca
    rlca
    ld [$df01], a	;
    ld a, [$df07]
    sub $70
    ld c, a
    ld a, [$df01]
    add c
    ld [$df01], a
    ret


    nop
    ld bc, $0302
    inc b
    dec b
    ld b, $07
    ld [$0a09], sp
    dec bc
    inc c
    dec c
    ld c, $00

    db $01

    ld bc, Boot
    ld bc, $0201
    db $01

    db $01

    nop
    ld bc, $0302
    inc b
    dec b
    ld b, $07
    nop
    ld bc, $0001
    ld bc, $0302
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    db $01

    db $02

    inc bc
    dec b
    ld b, $07
    add hl, bc
    add hl, bc
    ld a, [bc]

    db $0d

    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    inc c
    inc c
    rrca
    ld c, $0e
    ld c, $0e
    add hl, bc
    ld e, a
    ld l, a
    sbc a
    ld a, [bc]
    rst $38
    rst $38
    sub $2b
    dec hl
    daa
    inc h
    ld bc, $0b2f
    rst $38

    db $ff

    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    ret c

    db $ff

    db $fd
    ld [de], a
    ld b, $08
    inc bc
    inc d
    inc d
    nop
    rst $38
    sub $ff
    ld b, $02
    dec c
    nop

   ;@TEXT msgdebug page 1
   
   ;[ MESSEGE
   ;     DEBUG ]
   ;  TESTMES
   ;DEBUGNAME
   ;   SYSMES
   ; MNAMEMES
   
    db $96, $62, $30, $28, $36, $36, $28, $2a, $28, $f1, $62, $62, $62, $62, $62, $27
    db $28, $25, $38, $2a, $62, $97, $f1, $62, $62, $37, $28, $36, $37, $30, $28, $36
    db $f1, $27, $28, $25, $38, $2a, $31, $24, $30, $28, $f1, $62, $62, $62, $36, $3c
    db $36, $30, $28, $36, $f1, $62, $30, $31, $24, $30, $28, $30, $28, $36, $f1
   
   ;@TEXT msgdebug hex digits
   ;0123456789ABCDEF
    db $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $24, $25, $26, $27, $28, $29
   
   ;@TEXT msgdebug page 2
   
   ; KEITOUMES
   ;SYUZOKUMES
   ;TOKUGINAME
   ;   SYUNAME
   
    db $62, $2E, $28, $2C, $37, $32, $38, $30, $28, $36, $F1, $36, $3C, $38, $3D, $32
    db $2E, $38, $30, $28, $36, $F1, $37, $32, $2E, $38, $2A, $2C, $31, $24, $30, $28
    db $F1, $62, $62, $62, $36, $3C, $38, $31, $24, $30, $28, $F0
   
   ;@TEXT msgdebug page 3
   
   ;  ITEMNAME
   ;   ITEMMES
   ;SEIKAKUMES
   ; BTLWINMES
   
    db $62, $62, $2C, $37, $28, $30, $31, $24, $30, $28, $F1, $62, $62, $62, $2C, $37
    db $28, $30, $30, $28, $36, $F1, $36, $28, $2C, $2E, $24, $2E, $38, $30, $28, $36
    db $F1, $62, $25, $37, $2F, $3A, $2C, $31, $30, $28, $36, $F0
   
   ;@TEXT msgdebug page 4 
   
   ; BATTLEMES
   ;  ITEMMES2
   ;TOKUGUMES2
   ;KAIWAMES00
   
    db $62, $25, $24, $37, $37, $2F, $28, $30, $28, $36, $F1, $62, $62, $2C, $37, $28
    db $30, $30, $28, $36, $02, $F1, $37, $32, $2E, $38, $2A, $38, $30, $28, $36, $02
    db $F1, $2E, $24, $2C, $3A, $24, $30, $28, $36, $00, $00, $F0
   
   ;@TEXT msgdebug page 5
   
   ;KAIWAMES01
   ;KAIWAMES02
   ;KAIWAMES03
   ;KAIWAMES04
   
    db $2E, $24, $2C, $3A, $24, $30, $28, $36, $00, $01, $F1, $2E, $24, $2C, $3A, $24
    db $30, $28, $36, $00, $02, $F1, $2E, $24, $2C, $3A, $24, $30, $28, $36, $00, $03
    db $F1, $2E, $24, $2C, $3A, $24, $30, $28, $36, $00, $04, $F0
   
   ;@TEXT msgdebug page 6
   
   ;KAIWAMES05
   ;KAIWAMES06
   ;KAIWAMES07
   ;KAIWAMES08
   
    db $2E, $24, $2C, $3A, $24, $30, $28, $36, $00, $05, $F1, $2E, $24, $2C, $3A, $24
    db $30, $28, $36, $00, $06, $F1, $2E, $24, $2C, $3A, $24, $30, $28, $36, $00, $07
    db $F1, $2E, $24, $2C, $3A, $24, $30, $28, $36, $00, $08, $F0
   
   ;@TEXT msgdebug page 7

   ;KAIWAMES09
   ;    BTLMES
   ;   BTLMES1
   ;   BTLMES2
   
    db $2E, $24, $2C, $3A, $24, $30, $28, $36, $00, $09, $F1, $62, $62, $62, $62, $25
    db $37, $2F, $30, $28, $36, $F1, $62, $62, $62, $25, $37, $2F, $30, $28, $36, $01
    db $F1, $62, $62, $62, $25, $37, $2F, $30, $28, $36, $02, $F0

   ;@TEXT msgdebug page 8
   
   ;   BTLCMD
   ;  BTLMES4
   ;STAFFMES0
   ;STAFFMES1
   
    db $62, $62, $62, $25, $37, $2f, $26, $30, $27, $f1, $62, $62, $25, $37, $2f, $30
    db $28, $36, $04, $f1, $36, $37, $24, $29, $29, $30, $28, $36, $00, $f1, $36, $37
    db $24, $29, $29, $30, $28, $36, $01, $f0
    
   ;@TEXT msgdebug page 9

   ;ENDINGMES
   ;MONHAIMES
   ;MONINFMES
   ;TOKUGIMES
   
    db $28, $31, $27, $2c, $31, $2a, $30, $28, $36, $f1, $30, $32, $31, $2b, $24, $2c
    db $30, $28, $36, $f1, $30, $32, $31, $2c, $31, $29, $30, $28, $36, $f1, $37, $32
    db $2e, $38, $2a, $2c, $30, $28, $36, $f0
    
   ;@TEXT msgdebug page 10

   ; DEMOMES00
   ;DEMONAME00
   ; BOOKMES00
   ; OBJTMES00
   
    db $62, $27, $28, $30, $32, $30, $28, $36, $00, $00, $f1, $27, $28, $30, $32, $31
    db $24, $30, $28, $00, $00, $f1, $62, $25, $32, $32, $2e, $30, $28, $36, $00, $00
    db $f1, $62, $32, $25, $2d, $37, $30, $28, $36, $00, $00, $f0
    
   ;@TEXT msgdebug error

   ;INVALID NUMBER!
   
    db $2c, $31, $39, $24, $2f, $2c, $27, $62, $31, $38, $30, $25, $28, $35, $63
    
    db $f0
    
   ;@TEXT Skill descriptions 
; =============================================================================
; SKILL DESCRIPTIONS ($502F-$664A) — the SKIL-menu info box, text mode 1 of
; SkillDescModeTable. One string per skill id 0-150 / 213-218 (<= 3 lines of
; <= 18 cells, $F1 = next line, $F0 = end); ids 151-212 (internal battle
; actions + battle items) share SkillDesc_Blank, ids 219-255 SkillDesc_None.
; S110 re-section (tools/resection_skill_desc.py; was raw db + mgbdis fake
; code); bytes unchanged. Patched tree: compiler regions gd_skill_desc /
; gd_skill_desc_ptrs (gamedata.skills.<id>.description, PROJECT_COMPILER
; §2.26; BATTLE_SKILL_SYSTEM §14.1).
; =============================================================================
SkillDescStrings:
SkillDesc_000_Blaze:  ; $502F "Inflicts damage/with a small fire/ball"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $F1, $54, $46, $51, $45, $62, $3E, $62, $50, $4A, $3E, $49, $49, $62, $43, $46, $4F, $42, $F1, $3F, $3E, $49, $49, $F0
SkillDesc_001_Blazemore:  ; $5056 "Inflicts damage/with a giant/fire ball"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $F1, $54, $46, $51, $45, $62, $3E, $62, $44, $46, $3E, $4B, $51, $F1, $43, $46, $4F, $42, $62, $3F, $3E, $49, $49, $F0
SkillDesc_002_Blazemost:  ; $507D "Inflicts damage/with pillars of/fire"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $F1, $54, $46, $51, $45, $62, $4D, $46, $49, $49, $3E, $4F, $50, $62, $4C, $43, $F1, $43, $46, $4F, $42, $F0
SkillDesc_003_Firebal:  ; $50A2 "Inflicts damage to/all enemies with/a small blaze"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $F1, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $F1, $3E, $62, $50, $4A, $3E, $49, $49, $62, $3F, $49, $3E, $57, $42, $F0
SkillDesc_004_Firebane:  ; $50D4 "Inflicts damage to/all enemies with/a huge blaze"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $F1, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $F1, $3E, $62, $45, $52, $44, $42, $62, $3F, $49, $3E, $57, $42, $F0
SkillDesc_005_Firebolt:  ; $5105 "Inflicts damage to/all the enemies/with a big blaze"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $F1, $3E, $49, $49, $62, $51, $45, $42, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $54, $46, $51, $45, $62, $3E, $62, $3F, $46, $44, $62, $3F, $49, $3E, $57, $42, $F0
SkillDesc_006_Bang:  ; $5139 "Inflicts damage to/all enemies with/an explosion"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $F1, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $F1, $3E, $4B, $62, $42, $55, $4D, $49, $4C, $50, $46, $4C, $4B, $F0
SkillDesc_007_Boom:  ; $516A "Inflicts damage to/all enemies with/explosions"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $F1, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $F1, $42, $55, $4D, $49, $4C, $50, $46, $4C, $4B, $50, $F0
SkillDesc_008_Explodet:  ; $5199 "Inflicts damage to/all enemies with/a HUGE explosion"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $F1, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $F1, $3E, $62, $2B, $38, $2A, $28, $62, $42, $55, $4D, $49, $4C, $50, $46, $4C, $4B, $F0
SkillDesc_009_Infernos:  ; $51CE "Inflicts damages/to all enemies/with a whirlwind"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $50, $F1, $51, $4C, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $54, $46, $51, $45, $62, $3E, $62, $54, $45, $46, $4F, $49, $54, $46, $4B, $41, $F0
SkillDesc_010_Infermore:  ; $51FF "Inflicts damages/to all enemies/with a tornado"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $50, $F1, $51, $4C, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $54, $46, $51, $45, $62, $3E, $62, $51, $4C, $4F, $4B, $3E, $41, $4C, $F0
SkillDesc_011_Infermost:  ; $522E "Inflicts damages/to all enemies/with a hurricane"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $50, $F1, $51, $4C, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $54, $46, $51, $45, $62, $3E, $62, $45, $52, $4F, $4F, $46, $40, $3E, $4B, $42, $F0
SkillDesc_012_IceBolt:  ; $525F "Freezes all/enemies with ice"
    db $29, $4F, $42, $42, $57, $42, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $62, $46, $40, $42, $F0
SkillDesc_013_SnowStorm:  ; $527C "Turns all enemies/into ice"
    db $37, $52, $4F, $4B, $50, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $46, $4B, $51, $4C, $62, $46, $40, $42, $F0
SkillDesc_014_Blizzard:  ; $5297 "Attacks all/enemies with a/frigid blizzard"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $62, $3E, $F1, $43, $4F, $46, $44, $46, $41, $62, $3F, $49, $46, $57, $57, $3E, $4F, $41, $F0
SkillDesc_015_Bolt:  ; $52C2 "Strikes all/enemies with/lightning"
    db $36, $51, $4F, $46, $48, $42, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $F1, $49, $46, $44, $45, $51, $4B, $46, $4B, $44, $F0
SkillDesc_016_Zap:  ; $52E5 "Strikes all/enemies with/a thunderbolt"
    db $36, $51, $4F, $46, $48, $42, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $F1, $3E, $62, $51, $45, $52, $4B, $41, $42, $4F, $3F, $4C, $49, $51, $F0
SkillDesc_017_Thordain:  ; $530C "Strikes all/enemies with/thunderbolts"
    db $36, $51, $4F, $46, $48, $42, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $F1, $51, $45, $52, $4B, $41, $42, $4F, $3F, $4C, $49, $51, $50, $F0
SkillDesc_018_Beat:  ; $5332 "Instantly knocks/out an enemy"
    db $2C, $4B, $50, $51, $3E, $4B, $51, $49, $56, $62, $48, $4B, $4C, $40, $48, $50, $F1, $4C, $52, $51, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_019_Defeat:  ; $5350 "Instantly knocks/out all enemies"
    db $2C, $4B, $50, $51, $3E, $4B, $51, $49, $56, $62, $48, $4B, $4C, $40, $48, $50, $F1, $4C, $52, $51, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_020_Sacrifice:  ; $5371 "Knocks out the/caster and/all enemies"
    db $2E, $4B, $4C, $40, $48, $50, $62, $4C, $52, $51, $62, $51, $45, $42, $F1, $40, $3E, $50, $51, $42, $4F, $62, $3E, $4B, $41, $F1, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_021_Sleep:  ; $5397 "Puts an enemy/to sleep"
    db $33, $52, $51, $50, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F1, $51, $4C, $62, $50, $49, $42, $42, $4D, $F0
SkillDesc_022_SleepAll:  ; $53AE "Puts all enemies/to sleep"
    db $33, $52, $51, $50, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $51, $4C, $62, $50, $49, $42, $42, $4D, $F0
SkillDesc_023_StopSpell:  ; $53C8 "Suspends all the/enemies from/casting spells"
    db $36, $52, $50, $4D, $42, $4B, $41, $50, $62, $3E, $49, $49, $62, $51, $45, $42, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $43, $4F, $4C, $4A, $F1, $40, $3E, $50, $51, $46, $4B, $44, $62, $50, $4D, $42, $49, $49, $50, $F0
SkillDesc_024_Surround:  ; $53F5 "Engulfs all the/enemies with an/illusion"
    db $28, $4B, $44, $52, $49, $43, $50, $62, $3E, $49, $49, $62, $51, $45, $42, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $62, $3E, $4B, $F1, $46, $49, $49, $52, $50, $46, $4C, $4B, $F0
SkillDesc_025_PanicAll:  ; $541E "Confuses all/enemies"
    db $26, $4C, $4B, $43, $52, $50, $42, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_026_RobMagic:  ; $5433 "Steals enemy's MP"
    db $36, $51, $42, $3E, $49, $50, $62, $42, $4B, $42, $4A, $56, $68, $62, $30, $33, $F0
SkillDesc_027_TakeMagic:  ; $5444 "Absorbs the MP of/a spell cast by/an enemy"
    db $24, $3F, $50, $4C, $4F, $3F, $50, $62, $51, $45, $42, $62, $30, $33, $62, $4C, $43, $F1, $3E, $62, $50, $4D, $42, $49, $49, $62, $40, $3E, $50, $51, $62, $3F, $56, $F1, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_028_Sap:  ; $546F "Lowers an/enemy's DEFENSE"
    db $2F, $4C, $54, $42, $4F, $50, $62, $3E, $4B, $F1, $42, $4B, $42, $4A, $56, $68, $62, $27, $28, $29, $28, $31, $36, $28, $F0
SkillDesc_029_Defence:  ; $5488 "Lowers all the/enemies' DEFENSE"
    db $2F, $4C, $54, $42, $4F, $50, $62, $3E, $49, $49, $62, $51, $45, $42, $F1, $42, $4B, $42, $4A, $46, $42, $50, $5C, $62, $27, $28, $29, $28, $31, $36, $28, $F0
SkillDesc_030_Upper:  ; $54A8 "Increases DEFENSE/for an ally"
    db $2C, $4B, $40, $4F, $42, $3E, $50, $42, $50, $62, $27, $28, $29, $28, $31, $36, $28, $F1, $43, $4C, $4F, $62, $3E, $4B, $62, $3E, $49, $49, $56, $F0
SkillDesc_031_Increase:  ; $54C6 "Increases DEFENSE/for all allies"
    db $2C, $4B, $40, $4F, $42, $3E, $50, $42, $50, $62, $27, $28, $29, $28, $31, $36, $28, $F1, $43, $4C, $4F, $62, $3E, $49, $49, $62, $3E, $49, $49, $46, $42, $50, $F0
SkillDesc_032_Slow:  ; $54E7 "Decreases AGILITY/of an enemy"
    db $27, $42, $40, $4F, $42, $3E, $50, $42, $50, $62, $24, $2A, $2C, $2F, $2C, $37, $3C, $F1, $4C, $43, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_033_SlowAll:  ; $5505 "Decreases AGILITY/of all enemies"
    db $27, $42, $40, $4F, $42, $3E, $50, $42, $50, $62, $24, $2A, $2C, $2F, $2C, $37, $3C, $F1, $4C, $43, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_034_Speed:  ; $5526 "Increases AGILITY/for an ally"
    db $2C, $4B, $40, $4F, $42, $3E, $50, $42, $50, $62, $24, $2A, $2C, $2F, $2C, $37, $3C, $F1, $43, $4C, $4F, $62, $3E, $4B, $62, $3E, $49, $49, $56, $F0
SkillDesc_035_SpeedUp:  ; $5544 "Increases AGILITY/for all allies"
    db $2C, $4B, $40, $4F, $42, $3E, $50, $42, $50, $62, $24, $2A, $2C, $2F, $2C, $37, $3C, $F1, $43, $4C, $4F, $62, $3E, $49, $49, $62, $3E, $49, $49, $46, $42, $50, $F0
SkillDesc_036_Barrier:  ; $5565 "All allies become/more resistant to/breath attacks"
    db $24, $49, $49, $62, $3E, $49, $49, $46, $42, $50, $62, $3F, $42, $40, $4C, $4A, $42, $F1, $4A, $4C, $4F, $42, $62, $4F, $42, $50, $46, $50, $51, $3E, $4B, $51, $62, $51, $4C, $F1, $3F, $4F, $42, $3E, $51, $45, $62, $3E, $51, $51, $3E, $40, $48, $50, $F0
SkillDesc_037_TwinHits:  ; $5598 "Inflicts double/the damage to/an enemy"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $4C, $52, $3F, $49, $42, $F1, $51, $45, $42, $62, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $F1, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_038_MagicWall:  ; $55BF "Increases/resistance to/the enemy spells"
    db $2C, $4B, $40, $4F, $42, $3E, $50, $42, $50, $F1, $4F, $42, $50, $46, $50, $51, $3E, $4B, $40, $42, $62, $51, $4C, $F1, $51, $45, $42, $62, $42, $4B, $42, $4A, $56, $62, $50, $4D, $42, $49, $49, $50, $F0
SkillDesc_039_MagicBack:  ; $55E8 "Reflects the magic/cast by the enemy/for one turn"
    db $35, $42, $43, $49, $42, $40, $51, $50, $62, $51, $45, $42, $62, $4A, $3E, $44, $46, $40, $F1, $40, $3E, $50, $51, $62, $3F, $56, $62, $51, $45, $42, $62, $42, $4B, $42, $4A, $56, $F1, $43, $4C, $4F, $62, $4C, $4B, $42, $62, $51, $52, $4F, $4B, $F0
SkillDesc_040_Bounce:  ; $561A "Reflects the enemy/spells that the/caster receives"
    db $35, $42, $43, $49, $42, $40, $51, $50, $62, $51, $45, $42, $62, $42, $4B, $42, $4A, $56, $F1, $50, $4D, $42, $49, $49, $50, $62, $51, $45, $3E, $51, $62, $51, $45, $42, $F1, $40, $3E, $50, $51, $42, $4F, $62, $4F, $42, $40, $42, $46, $53, $42, $50, $F0
SkillDesc_041_Transform:  ; $564D "Transform into/the same species/as the enemy"
    db $37, $4F, $3E, $4B, $50, $43, $4C, $4F, $4A, $62, $46, $4B, $51, $4C, $F1, $51, $45, $42, $62, $50, $3E, $4A, $42, $62, $50, $4D, $42, $40, $46, $42, $50, $F1, $3E, $50, $62, $51, $45, $42, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_042_Ironize:  ; $567A "Turns all allies/into a protective/lump of iron"
    db $37, $52, $4F, $4B, $50, $62, $3E, $49, $49, $62, $3E, $49, $49, $46, $42, $50, $F1, $46, $4B, $51, $4C, $62, $3E, $62, $4D, $4F, $4C, $51, $42, $40, $51, $46, $53, $42, $F1, $49, $52, $4A, $4D, $62, $4C, $43, $62, $46, $4F, $4C, $4B, $F0
SkillDesc_043_Heal:  ; $56AA "Heals between/30 to 40 HP for an/ally"
    db $2B, $42, $3E, $49, $50, $62, $3F, $42, $51, $54, $42, $42, $4B, $F1, $03, $00, $62, $51, $4C, $62, $04, $00, $62, $2B, $33, $62, $43, $4C, $4F, $62, $3E, $4B, $F1, $3E, $49, $49, $56, $F0
SkillDesc_044_HealMore:  ; $56D0 "Heals between/75 and 90 HP for/all allies"
    db $2B, $42, $3E, $49, $50, $62, $3F, $42, $51, $54, $42, $42, $4B, $F1, $07, $05, $62, $3E, $4B, $41, $62, $09, $00, $62, $2B, $33, $62, $43, $4C, $4F, $F1, $3E, $49, $49, $62, $3E, $49, $49, $46, $42, $50, $F0
SkillDesc_045_HealAll:  ; $56FA "Heals HP to max/for an ally"
    db $2B, $42, $3E, $49, $50, $62, $2B, $33, $62, $51, $4C, $62, $4A, $3E, $55, $F1, $43, $4C, $4F, $62, $3E, $4B, $62, $3E, $49, $49, $56, $F0
SkillDesc_046_HealUs:  ; $5716 "Heals between/90 to 120 HP for/all allies"
    db $2B, $42, $3E, $49, $50, $62, $3F, $42, $51, $54, $42, $42, $4B, $F1, $09, $00, $62, $51, $4C, $62, $01, $02, $00, $62, $2B, $33, $62, $43, $4C, $4F, $F1, $3E, $49, $49, $62, $3E, $49, $49, $46, $42, $50, $F0
SkillDesc_047_HealUsAll:  ; $5740 "Heals HP to max/for all allies"
    db $2B, $42, $3E, $49, $50, $62, $2B, $33, $62, $51, $4C, $62, $4A, $3E, $55, $F1, $43, $4C, $4F, $62, $3E, $49, $49, $62, $3E, $49, $49, $46, $42, $50, $F0
SkillDesc_048_Vivify:  ; $575F "Revives an ally"
    db $35, $42, $53, $46, $53, $42, $50, $62, $3E, $4B, $62, $3E, $49, $49, $56, $F0
SkillDesc_049_Revive:  ; $576F "Revives an ally"
    db $35, $42, $53, $46, $53, $42, $50, $62, $3E, $4B, $62, $3E, $49, $49, $56, $F0
SkillDesc_050_Farewell:  ; $577F "Revives all other/allies but the/caster collapses"
    db $35, $42, $53, $46, $53, $42, $50, $62, $3E, $49, $49, $62, $4C, $51, $45, $42, $4F, $F1, $3E, $49, $49, $46, $42, $50, $62, $3F, $52, $51, $62, $51, $45, $42, $F1, $40, $3E, $50, $51, $42, $4F, $62, $40, $4C, $49, $49, $3E, $4D, $50, $42, $50, $F0
SkillDesc_051_Antidote:  ; $57B1 "Cures poison"
    db $26, $52, $4F, $42, $50, $62, $4D, $4C, $46, $50, $4C, $4B, $F0
SkillDesc_052_NumbOff:  ; $57BE "Cures paralysis/or wakes up/an ally"
    db $26, $52, $4F, $42, $50, $62, $4D, $3E, $4F, $3E, $49, $56, $50, $46, $50, $F1, $4C, $4F, $62, $54, $3E, $48, $42, $50, $62, $52, $4D, $F1, $3E, $4B, $62, $3E, $49, $49, $56, $F0
SkillDesc_053_DeChaos:  ; $57E2 "Cures confusion"
    db $26, $52, $4F, $42, $50, $62, $40, $4C, $4B, $43, $52, $50, $46, $4C, $4B, $F0
SkillDesc_054_CurseOff:  ; $57F2 "Breaks a curse"
    db $25, $4F, $42, $3E, $48, $50, $62, $3E, $62, $40, $52, $4F, $50, $42, $F0
SkillDesc_055_StepGuard:  ; $5801 "Protects from/land hazards/while traveling"
    db $33, $4F, $4C, $51, $42, $40, $51, $50, $62, $43, $4F, $4C, $4A, $F1, $49, $3E, $4B, $41, $62, $45, $3E, $57, $3E, $4F, $41, $50, $F1, $54, $45, $46, $49, $42, $62, $51, $4F, $3E, $53, $42, $49, $46, $4B, $44, $F0
SkillDesc_056_MapMagic:  ; $582C "Reveals the entire/map of the/landscape"
    db $35, $42, $53, $42, $3E, $49, $50, $62, $51, $45, $42, $62, $42, $4B, $51, $46, $4F, $42, $F1, $4A, $3E, $4D, $62, $4C, $43, $62, $51, $45, $42, $F1, $49, $3E, $4B, $41, $50, $40, $3E, $4D, $42, $F0
SkillDesc_057_Chance:  ; $5854 "A random spell,/can be good or bad"
    db $24, $62, $4F, $3E, $4B, $41, $4C, $4A, $62, $50, $4D, $42, $49, $49, $5E, $F1, $40, $3E, $4B, $62, $3F, $42, $62, $44, $4C, $4C, $41, $62, $4C, $4F, $62, $3F, $3E, $41, $F0
SkillDesc_058_Attack:  ; $5877 ""
    db $F0
SkillDesc_059_TwinSlash:  ; $5878 "Fearless attack"
    db $29, $42, $3E, $4F, $49, $42, $50, $50, $62, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_060_Ramming:  ; $5888 "Attacks like a ram/with its true/inner strength"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $49, $46, $48, $42, $62, $3E, $62, $4F, $3E, $4A, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $51, $4F, $52, $42, $F1, $46, $4B, $4B, $42, $4F, $62, $50, $51, $4F, $42, $4B, $44, $51, $45, $F0
SkillDesc_061_Beserker:  ; $58B8 "Attacks like there/is no tomorrow"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $49, $46, $48, $42, $62, $51, $45, $42, $4F, $42, $F1, $46, $50, $62, $4B, $4C, $62, $51, $4C, $4A, $4C, $4F, $4F, $4C, $54, $F0
SkillDesc_062_Kamikaze:  ; $58DA "A suicide attack/to knock out the/enemy"
    db $24, $62, $50, $52, $46, $40, $46, $41, $42, $62, $3E, $51, $51, $3E, $40, $48, $F1, $51, $4C, $62, $48, $4B, $4C, $40, $48, $62, $4C, $52, $51, $62, $51, $45, $42, $F1, $42, $4B, $42, $4A, $56, $F0
SkillDesc_063_Massacre:  ; $5902 "Inflicts great/damage to an ally/or an enemy"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $44, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $62, $3E, $4B, $62, $3E, $49, $49, $56, $F1, $4C, $4F, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_064_EvilSlash:  ; $592F "Attacks like a/ruthless demon"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $49, $46, $48, $42, $62, $3E, $F1, $4F, $52, $51, $45, $49, $42, $50, $50, $62, $41, $42, $4A, $4C, $4B, $F0
SkillDesc_065_ChargeUP:  ; $594D "Inflicts huge/damage to an enemy/on the next turn"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $45, $52, $44, $42, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F1, $4C, $4B, $62, $51, $45, $42, $62, $4B, $42, $55, $51, $62, $51, $52, $4F, $4B, $F0
SkillDesc_066_HighJump:  ; $597F "Jumps into the air/and attacks on/the next turn"
    db $2D, $52, $4A, $4D, $50, $62, $46, $4B, $51, $4C, $62, $51, $45, $42, $62, $3E, $46, $4F, $F1, $3E, $4B, $41, $62, $3E, $51, $51, $3E, $40, $48, $50, $62, $4C, $4B, $F1, $51, $45, $42, $62, $4B, $42, $55, $51, $62, $51, $52, $4F, $4B, $F0
SkillDesc_067_SuckAir:  ; $59AF "Sucks in air power/to inflict damage/on the next turn"
    db $36, $52, $40, $48, $50, $62, $46, $4B, $62, $3E, $46, $4F, $62, $4D, $4C, $54, $42, $4F, $F1, $51, $4C, $62, $46, $4B, $43, $49, $46, $40, $51, $62, $41, $3E, $4A, $3E, $44, $42, $F1, $4C, $4B, $62, $51, $45, $42, $62, $4B, $42, $55, $51, $62, $51, $52, $4F, $4B, $F0
SkillDesc_068_FireSlash:  ; $59E5 "Burning blade/sword attack"
    db $25, $52, $4F, $4B, $46, $4B, $44, $62, $3F, $49, $3E, $41, $42, $F1, $50, $54, $4C, $4F, $41, $62, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_069_BoltSlash:  ; $5A00 "Thunderbolt/sword attack"
    db $37, $45, $52, $4B, $41, $42, $4F, $3F, $4C, $49, $51, $F1, $50, $54, $4C, $4F, $41, $62, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_070_VacuSlash:  ; $5A19 "Whirling vacuum/sword attack"
    db $3A, $45, $46, $4F, $49, $46, $4B, $44, $62, $53, $3E, $40, $52, $52, $4A, $F1, $50, $54, $4C, $4F, $41, $62, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_071_IceSlash:  ; $5A36 "Freezing ice/sword attack"
    db $29, $4F, $42, $42, $57, $46, $4B, $44, $62, $46, $40, $42, $F1, $50, $54, $4C, $4F, $41, $62, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_072_MetalCut:  ; $5A50 "Inflicts great/damage to metal/enemies"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $44, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $62, $4A, $42, $51, $3E, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_073_DrakSlash:  ; $5A77 "Inflicts great/damage to dragons"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $44, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $62, $41, $4F, $3E, $44, $4C, $4B, $50, $F0
SkillDesc_074_BeastCut:  ; $5A98 "Inflicts great/damage to beasts"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $44, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $62, $3F, $42, $3E, $50, $51, $50, $F0
SkillDesc_075_BirdBlow:  ; $5AB8 "Inflicts great/damage to birds"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $44, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $62, $3F, $46, $4F, $41, $50, $F0
SkillDesc_076_DevilCut:  ; $5AD7 "Inflicts great/damage on devils"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $44, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $4C, $4B, $62, $41, $42, $53, $46, $49, $50, $F0
SkillDesc_077_ZombieCut:  ; $5AF7 "Inflict great/damage to zombies"
    db $2C, $4B, $43, $49, $46, $40, $51, $62, $44, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $62, $57, $4C, $4A, $3F, $46, $42, $50, $F0
SkillDesc_078_CleanCut:  ; $5B17 "Inflicts great/damage to/materials"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $44, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $F1, $4A, $3E, $51, $42, $4F, $46, $3E, $49, $50, $F0
SkillDesc_079_MultiCut:  ; $5B3A "Inflicts damage/to all enemies/with many cuts"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $F1, $51, $4C, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $54, $46, $51, $45, $62, $4A, $3E, $4B, $56, $62, $40, $52, $51, $50, $F0
SkillDesc_080_BiAttack:  ; $5B68 "Attacks twice in/one turn"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $51, $54, $46, $40, $42, $62, $46, $4B, $F1, $4C, $4B, $42, $62, $51, $52, $4F, $4B, $F0
SkillDesc_081_QuadHits:  ; $5B82 "Attacks 4 times/in one turn"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $04, $62, $51, $46, $4A, $42, $50, $F1, $46, $4B, $62, $4C, $4B, $42, $62, $51, $52, $4F, $4B, $F0
SkillDesc_082_CallHelp:  ; $5B9E "Calls for a backup"
    db $26, $3E, $49, $49, $50, $62, $43, $4C, $4F, $62, $3E, $62, $3F, $3E, $40, $48, $52, $4D, $F0
SkillDesc_083_YellHelp:  ; $5BB1 "Calls a group of/monsters for help"
    db $26, $3E, $49, $49, $50, $62, $3E, $62, $44, $4F, $4C, $52, $4D, $62, $4C, $43, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $62, $43, $4C, $4F, $62, $45, $42, $49, $4D, $F0
SkillDesc_084_Focus:  ; $5BD4 "Two attacks/on the next/turn"
    db $37, $54, $4C, $62, $3E, $51, $51, $3E, $40, $48, $50, $F1, $4C, $4B, $62, $51, $45, $42, $62, $4B, $42, $55, $51, $F1, $51, $52, $4F, $4B, $F0
SkillDesc_085_SquallHit:  ; $5BF1 "Allows you to/attack first/in the turn"
    db $24, $49, $49, $4C, $54, $50, $62, $56, $4C, $52, $62, $51, $4C, $F1, $3E, $51, $51, $3E, $40, $48, $62, $43, $46, $4F, $50, $51, $F1, $46, $4B, $62, $51, $45, $42, $62, $51, $52, $4F, $4B, $F0
SkillDesc_086_PsycheUp:  ; $5C18 "Inflicts Great/damage to an enemy/at the last turn"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $2A, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F1, $3E, $51, $62, $51, $45, $42, $62, $49, $3E, $50, $51, $62, $51, $52, $4F, $4B, $F0
SkillDesc_087_RainSlash:  ; $5C4B "Attacks all/enemies in one/attack"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $46, $4B, $62, $4C, $4B, $42, $F1, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_088_WindBeast:  ; $5C6D "Attacks an enemy/with a violent/whirlwind"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F1, $54, $46, $51, $45, $62, $3E, $62, $53, $46, $4C, $49, $42, $4B, $51, $F1, $54, $45, $46, $4F, $49, $54, $46, $4B, $41, $F0
SkillDesc_089_Vacuum:  ; $5C97 "Attacks all/enemies with a/giant vacuum"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $62, $3E, $F1, $44, $46, $3E, $4B, $51, $62, $53, $3E, $40, $52, $52, $4A, $F0
SkillDesc_090_Lightning:  ; $5CBF "Inflicts damage on/all enemies with/lightning"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $62, $4C, $4B, $F1, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $F1, $49, $46, $44, $45, $51, $4B, $46, $4B, $44, $F0
SkillDesc_091_RockThrow:  ; $5CED "Throws a huge rock/on all enemies"
    db $37, $45, $4F, $4C, $54, $50, $62, $3E, $62, $45, $52, $44, $42, $62, $4F, $4C, $40, $48, $F1, $4C, $4B, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_092_FireAir:  ; $5D0F "Breathes out fire/to inflict damage/on all enemies"
    db $25, $4F, $42, $3E, $51, $45, $42, $50, $62, $4C, $52, $51, $62, $43, $46, $4F, $42, $F1, $51, $4C, $62, $46, $4B, $43, $49, $46, $40, $51, $62, $41, $3E, $4A, $3E, $44, $42, $F1, $4C, $4B, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_093_BlazeAir:  ; $5D42 "Blows out a blaze/to inflict damage/on all enemies"
    db $25, $49, $4C, $54, $50, $62, $4C, $52, $51, $62, $3E, $62, $3F, $49, $3E, $57, $42, $F1, $51, $4C, $62, $46, $4B, $43, $49, $46, $40, $51, $62, $41, $3E, $4A, $3E, $44, $42, $F1, $4C, $4B, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_094_Scorching:  ; $5D75 "Burns all enemies/with a devastating/flame"
    db $25, $52, $4F, $4B, $50, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $54, $46, $51, $45, $62, $3E, $62, $41, $42, $53, $3E, $50, $51, $3E, $51, $46, $4B, $44, $F1, $43, $49, $3E, $4A, $42, $F0
SkillDesc_095_WhiteFire:  ; $5DA0 "Attacks all/enemies with an/unimaginable blaze"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $62, $3E, $4B, $F1, $52, $4B, $46, $4A, $3E, $44, $46, $4B, $3E, $3F, $49, $42, $62, $3F, $49, $3E, $57, $42, $F0
SkillDesc_096_FrigidAir:  ; $5DCF "Inflicts damage to/all enemies with/its frigid breath"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $F1, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $F1, $46, $51, $50, $62, $43, $4F, $46, $44, $46, $41, $62, $3F, $4F, $42, $3E, $51, $45, $F0
SkillDesc_097_IceAir:  ; $5E05 "Freezes all/enemies"
    db $29, $4F, $42, $42, $57, $42, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_098_IceStorm:  ; $5E19 "Inflicts damage to/all enemies with a/violent ice storm"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $F1, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $62, $3E, $F1, $53, $46, $4C, $49, $42, $4B, $51, $62, $46, $40, $42, $62, $50, $51, $4C, $4F, $4A, $F0
SkillDesc_099_WhiteAir:  ; $5E51 "Attacks all/enemies with an/incandescent air"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $62, $3E, $4B, $F1, $46, $4B, $40, $3E, $4B, $41, $42, $50, $40, $42, $4B, $51, $62, $3E, $46, $4F, $F0
SkillDesc_100_Hellblast:  ; $5E7E "Hell powered/lightning blast/attacks all foes"
    db $2B, $42, $49, $49, $62, $4D, $4C, $54, $42, $4F, $42, $41, $F1, $49, $46, $44, $45, $51, $4B, $46, $4B, $44, $62, $3F, $49, $3E, $50, $51, $F1, $3E, $51, $51, $3E, $40, $48, $50, $62, $3E, $49, $49, $62, $43, $4C, $42, $50, $F0
SkillDesc_101_BigBang:  ; $5EAC "Creates a huge/explosion to/attack all enemies"
    db $26, $4F, $42, $3E, $51, $42, $50, $62, $3E, $62, $45, $52, $44, $42, $F1, $42, $55, $4D, $49, $4C, $50, $46, $4C, $4B, $62, $51, $4C, $F1, $3E, $51, $51, $3E, $40, $48, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_102_MegaMagic:  ; $5EDB "The most powerful/spell that affects/all enemies"
    db $37, $45, $42, $62, $4A, $4C, $50, $51, $62, $4D, $4C, $54, $42, $4F, $43, $52, $49, $F1, $50, $4D, $42, $49, $49, $62, $51, $45, $3E, $51, $62, $3E, $43, $43, $42, $40, $51, $50, $F1, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_103_PoisonHit:  ; $5F0C "Poisons the enemy/that attacked the/ally"
    db $33, $4C, $46, $50, $4C, $4B, $50, $62, $51, $45, $42, $62, $42, $4B, $42, $4A, $56, $F1, $51, $45, $3E, $51, $62, $3E, $51, $51, $3E, $40, $48, $42, $41, $62, $51, $45, $42, $F1, $3E, $49, $49, $56, $F0
SkillDesc_104_NapAttack:  ; $5F35 "Sends the enemy/that attacked/the ally to sleep"
    db $36, $42, $4B, $41, $50, $62, $51, $45, $42, $62, $42, $4B, $42, $4A, $56, $F1, $51, $45, $3E, $51, $62, $3E, $51, $51, $3E, $40, $48, $42, $41, $F1, $51, $45, $42, $62, $3E, $49, $49, $56, $62, $51, $4C, $62, $50, $49, $42, $42, $4D, $F0
SkillDesc_105_Paralyze:  ; $5F65 "Paralyzes the/enemy that/attacked the ally"
    db $33, $3E, $4F, $3E, $49, $56, $57, $42, $50, $62, $51, $45, $42, $F1, $42, $4B, $42, $4A, $56, $62, $51, $45, $3E, $51, $F1, $3E, $51, $51, $3E, $40, $48, $42, $41, $62, $51, $45, $42, $62, $3E, $49, $49, $56, $F0
SkillDesc_106_SleepAir:  ; $5F90 "Send all enemies/to sleep"
    db $36, $42, $4B, $41, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $51, $4C, $62, $50, $49, $42, $42, $4D, $F0
SkillDesc_107_PalsyAir:  ; $5FAA "Paralyzes all/enemies"
    db $33, $3E, $4F, $3E, $49, $56, $57, $42, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_108_PoisonGas:  ; $5FC0 "Poisons all/enemies"
    db $33, $4C, $46, $50, $4C, $4B, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_109_PoisonAir:  ; $5FD4 "Severly poisons/all enemies"
    db $36, $42, $53, $42, $4F, $49, $56, $62, $4D, $4C, $46, $50, $4C, $4B, $50, $F1, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_110_PaniDance:  ; $5FF0 "Confuses all/enemies"
    db $26, $4C, $4B, $43, $52, $50, $42, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_111_Curse:  ; $6005 "Curses all enemies"
    db $26, $52, $4F, $50, $42, $50, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_112_Ahhh:  ; $6018 "Makes you feel/happy"
    db $30, $3E, $48, $42, $50, $62, $56, $4C, $52, $62, $43, $42, $42, $49, $F1, $45, $3E, $4D, $4D, $56, $F0
SkillDesc_113_KODance:  ; $602D "Instantly knocks/out all enemies"
    db $2C, $4B, $50, $51, $3E, $4B, $51, $49, $56, $62, $48, $4B, $4C, $40, $48, $50, $F1, $4C, $52, $51, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_114_SandStorm:  ; $604E "Attacks all/enemies with/a sandstorm"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $F1, $3E, $62, $50, $3E, $4B, $41, $50, $51, $4C, $4F, $4A, $F0
SkillDesc_115_Radiant:  ; $6073 "Blinds all enemies/with its bright/light"
    db $25, $49, $46, $4B, $41, $50, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $3F, $4F, $46, $44, $45, $51, $F1, $49, $46, $44, $45, $51, $F0
SkillDesc_116_EerieLite:  ; $609C "Makes all enemies/less resistant/to magic spells"
    db $30, $3E, $48, $42, $50, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $49, $42, $50, $50, $62, $4F, $42, $50, $46, $50, $51, $3E, $4B, $51, $F1, $51, $4C, $62, $4A, $3E, $44, $46, $40, $62, $50, $4D, $42, $49, $49, $50, $F0
SkillDesc_117_OddDance:  ; $60CD "Drops an enemy's/MP with its odd/dancing steps"
    db $27, $4F, $4C, $4D, $50, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $68, $F1, $30, $33, $62, $54, $46, $51, $45, $62, $46, $51, $50, $62, $4C, $41, $41, $F1, $41, $3E, $4B, $40, $46, $4B, $44, $62, $50, $51, $42, $4D, $50, $F0
SkillDesc_118_RobDance:  ; $60FB "Steals an enemy's/MP with its/mesmerizing dance"
    db $36, $51, $42, $3E, $49, $50, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $68, $F1, $30, $33, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $4A, $42, $50, $4A, $42, $4F, $46, $57, $46, $4B, $44, $62, $41, $3E, $4B, $40, $42, $F0
SkillDesc_119_SideStep:  ; $612A "Sidesteps an/attack"
    db $36, $46, $41, $42, $50, $51, $42, $4D, $50, $62, $3E, $4B, $F1, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_120_LureDance:  ; $613E "Lures an enemy to/a trap with its/dance"
    db $2F, $52, $4F, $42, $50, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $62, $51, $4C, $F1, $3E, $62, $51, $4F, $3E, $4D, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $41, $3E, $4B, $40, $42, $F0
SkillDesc_121_LushLicks:  ; $6166 "Licks an enemy/to stop it from/attacking"
    db $2F, $46, $40, $48, $50, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F1, $51, $4C, $62, $50, $51, $4C, $4D, $62, $46, $51, $62, $43, $4F, $4C, $4A, $F1, $3E, $51, $51, $3E, $40, $48, $46, $4B, $44, $F0
SkillDesc_122_SickLick:  ; $618F "Lowers DEFENSE/by giving an enemy/a sickly lick"
    db $2F, $4C, $54, $42, $4F, $50, $62, $27, $28, $29, $28, $31, $36, $28, $F1, $3F, $56, $62, $44, $46, $53, $46, $4B, $44, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F1, $3E, $62, $50, $46, $40, $48, $49, $56, $62, $49, $46, $40, $48, $F0
SkillDesc_123_LegSweep:  ; $61BF "Trips an enemy by/sweeping its legs"
    db $37, $4F, $46, $4D, $50, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $62, $3F, $56, $F1, $50, $54, $42, $42, $4D, $46, $4B, $44, $62, $46, $51, $50, $62, $49, $42, $44, $50, $F0
SkillDesc_124_BigTrip:  ; $61E3 "Trips all enemies"
    db $37, $4F, $46, $4D, $50, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_125_WarCry:  ; $61F5 "Freezes all/enemies with a/very loud roar"
    db $29, $4F, $42, $42, $57, $42, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $62, $3E, $F1, $53, $42, $4F, $56, $62, $49, $4C, $52, $41, $62, $4F, $4C, $3E, $4F, $F0
SkillDesc_126_Whistle:  ; $621F "Summons monsters"
    db $36, $52, $4A, $4A, $4C, $4B, $50, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $F0
SkillDesc_127_Imitate:  ; $6230 "Imitates the/enemy's attack"
    db $2C, $4A, $46, $51, $3E, $51, $42, $50, $62, $51, $45, $42, $F1, $42, $4B, $42, $4A, $56, $68, $62, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_128_DeMagic:  ; $624B "Dispels magic/effects on all/allies"
    db $27, $46, $50, $4D, $42, $49, $50, $62, $4A, $3E, $44, $46, $40, $F1, $42, $43, $43, $42, $40, $51, $50, $62, $4C, $4B, $62, $3E, $49, $49, $F1, $3E, $49, $49, $46, $42, $50, $F0
SkillDesc_129_Surge:  ; $626F "Cures any ailments/for all allies"
    db $26, $52, $4F, $42, $50, $62, $3E, $4B, $56, $62, $3E, $46, $49, $4A, $42, $4B, $51, $50, $F1, $43, $4C, $4F, $62, $3E, $49, $49, $62, $3E, $49, $49, $46, $42, $50, $F0
SkillDesc_130_UltraDown:  ; $6291 "Greatly weakens/the enemy"
    db $2A, $4F, $42, $3E, $51, $49, $56, $62, $54, $42, $3E, $48, $42, $4B, $50, $F1, $51, $45, $42, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_131_ThickFog:  ; $62AB "Creates a thick/fog to suspend/magic spells"
    db $26, $4F, $42, $3E, $51, $42, $50, $62, $3E, $62, $51, $45, $46, $40, $48, $F1, $43, $4C, $44, $62, $51, $4C, $62, $50, $52, $50, $4D, $42, $4B, $41, $F1, $4A, $3E, $44, $46, $40, $62, $50, $4D, $42, $49, $49, $50, $F0
SkillDesc_132_TatsuCall:  ; $62D7 "Summons Tatsu/monsters to attack/the enemy"
    db $36, $52, $4A, $4A, $4C, $4B, $50, $62, $37, $3E, $51, $50, $52, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $62, $51, $4C, $62, $3E, $51, $51, $3E, $40, $48, $F1, $51, $45, $42, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_133_DiagoCall:  ; $6302 "Summons Diago/monsters to attack/the enemy"
    db $36, $52, $4A, $4A, $4C, $4B, $50, $62, $27, $46, $3E, $44, $4C, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $62, $51, $4C, $62, $3E, $51, $51, $3E, $40, $48, $F1, $51, $45, $42, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_134_SamsiCall:  ; $632D "Summons Samsi/monsters to attack/the enemy"
    db $36, $52, $4A, $4A, $4C, $4B, $50, $62, $36, $3E, $4A, $50, $46, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $62, $51, $4C, $62, $3E, $51, $51, $3E, $40, $48, $F1, $51, $45, $42, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_135_BazooCall:  ; $6358 "Summons Bazoo/monsters to attack/the enemy"
    db $36, $52, $4A, $4A, $4C, $4B, $50, $62, $25, $3E, $57, $4C, $4C, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $62, $51, $4C, $62, $3E, $51, $51, $3E, $40, $48, $F1, $51, $45, $42, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_136_Cover:  ; $6383 "Throws itself in/front of the/attack for an ally"
    db $37, $45, $4F, $4C, $54, $50, $62, $46, $51, $50, $42, $49, $43, $62, $46, $4B, $F1, $43, $4F, $4C, $4B, $51, $62, $4C, $43, $62, $51, $45, $42, $F1, $3E, $51, $51, $3E, $40, $48, $62, $43, $4C, $4F, $62, $3E, $4B, $62, $3E, $49, $49, $56, $F0
SkillDesc_137_Guardian:  ; $63B4 "Takes all the/attacks from all/enemies"
    db $37, $3E, $48, $42, $50, $62, $3E, $49, $49, $62, $51, $45, $42, $F1, $3E, $51, $51, $3E, $40, $48, $50, $62, $43, $4F, $4C, $4A, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_138_TailWind:  ; $63DB "Reflects back Air/attack to an enemy"
    db $35, $42, $43, $49, $42, $40, $51, $50, $62, $3F, $3E, $40, $48, $62, $24, $46, $4F, $F1, $3E, $51, $51, $3E, $40, $48, $62, $51, $4C, $62, $3E, $4B, $62, $42, $4B, $42, $4A, $56, $F0
SkillDesc_139_StormWind:  ; $6400 "Reflects back Air/attacks to all/enemies"
    db $35, $42, $43, $49, $42, $40, $51, $50, $62, $3F, $3E, $40, $48, $62, $24, $46, $4F, $F1, $3E, $51, $51, $3E, $40, $48, $50, $62, $51, $4C, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_140_Dodge:  ; $6429 "Dodges an attack"
    db $27, $4C, $41, $44, $42, $50, $62, $3E, $4B, $62, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_141_Defence:  ; $643A "Prepares to defend/itself for an/enemy attack"
    db $33, $4F, $42, $4D, $3E, $4F, $42, $50, $62, $51, $4C, $62, $41, $42, $43, $42, $4B, $41, $F1, $46, $51, $50, $42, $49, $43, $62, $43, $4C, $4F, $62, $3E, $4B, $F1, $42, $4B, $42, $4A, $56, $62, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_142_StrongD:  ; $6468 "Prepares a strong/defense against/any attack"
    db $33, $4F, $42, $4D, $3E, $4F, $42, $50, $62, $3E, $62, $50, $51, $4F, $4C, $4B, $44, $F1, $41, $42, $43, $42, $4B, $50, $42, $62, $3E, $44, $3E, $46, $4B, $50, $51, $F1, $3E, $4B, $56, $62, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_143_SuckAll:  ; $6495 "Sucks all the air/to inflict damage/on all enemies"
    db $36, $52, $40, $48, $50, $62, $3E, $49, $49, $62, $51, $45, $42, $62, $3E, $46, $4F, $F1, $51, $4C, $62, $46, $4B, $43, $49, $46, $40, $51, $62, $41, $3E, $4A, $3E, $44, $42, $F1, $4C, $4B, $62, $3E, $49, $49, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
SkillDesc_144_BladeD:  ; $64C8 "Defends against/a counterattack"
    db $27, $42, $43, $42, $4B, $41, $50, $62, $3E, $44, $3E, $46, $4B, $50, $51, $F1, $3E, $62, $40, $4C, $52, $4B, $51, $42, $4F, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_145_DanceShut:  ; $64E8 "Suspends all/enemies' Dance/attacks"
    db $36, $52, $50, $4D, $42, $4B, $41, $50, $62, $3E, $49, $49, $F1, $42, $4B, $42, $4A, $46, $42, $50, $5C, $62, $27, $3E, $4B, $40, $42, $F1, $3E, $51, $51, $3E, $40, $48, $50, $F0
SkillDesc_146_MouthShut:  ; $650C "Suspends an/enemy's Air/attack"
    db $36, $52, $50, $4D, $42, $4B, $41, $50, $62, $3E, $4B, $F1, $42, $4B, $42, $4A, $56, $68, $62, $24, $46, $4F, $F1, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_147_Meditate:  ; $652A "Restores 500 HP/by meditation"
    db $35, $42, $50, $51, $4C, $4F, $42, $50, $62, $05, $00, $00, $62, $2B, $33, $F1, $3F, $56, $62, $4A, $42, $41, $46, $51, $3E, $51, $46, $4C, $4B, $F0
SkillDesc_148_Hustle:  ; $6548 "Restores between/70 to 80 HP to all/allies"
    db $35, $42, $50, $51, $4C, $4F, $42, $50, $62, $3F, $42, $51, $54, $42, $42, $4B, $F1, $07, $00, $62, $51, $4C, $62, $08, $00, $62, $2B, $33, $62, $51, $4C, $62, $3E, $49, $49, $F1, $3E, $49, $49, $46, $42, $50, $F0
SkillDesc_149_LifeSong:  ; $6573 "Revives all allies"
    db $35, $42, $53, $46, $53, $42, $50, $62, $3E, $49, $49, $62, $3E, $49, $49, $46, $42, $50, $F0
SkillDesc_150_LifeDance:  ; $6586 "Revives all allies"
    db $35, $42, $53, $46, $53, $42, $50, $62, $3E, $49, $49, $62, $3E, $49, $49, $46, $42, $50, $F0
SkillDesc_Blank:  ; $6599 ""
    db $F0
SkillDesc_213_BeDragon:  ; $659A "Caster transforms/into a dragon"
    db $26, $3E, $50, $51, $42, $4F, $62, $51, $4F, $3E, $4B, $50, $43, $4C, $4F, $4A, $50, $F1, $46, $4B, $51, $4C, $62, $3E, $62, $41, $4F, $3E, $44, $4C, $4B, $F0
SkillDesc_214_Smashlime:  ; $65BA "Inflicts great/damage to slimes"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $44, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $62, $50, $49, $46, $4A, $42, $50, $F0
SkillDesc_215_Sheldodge:  ; $65DA "Inflicts great/damage to bugs"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $44, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $62, $3F, $52, $44, $50, $F0
SkillDesc_216_Branching:  ; $65F8 "Inflicts great/damage to plants"
    db $2C, $4B, $43, $49, $46, $40, $51, $50, $62, $44, $4F, $42, $3E, $51, $F1, $41, $3E, $4A, $3E, $44, $42, $62, $51, $4C, $62, $4D, $49, $3E, $4B, $51, $50, $F0
SkillDesc_217_GigaSlash:  ; $6618 "Most destructive/sword attack"
    db $30, $4C, $50, $51, $62, $41, $42, $50, $51, $4F, $52, $40, $51, $46, $53, $42, $F1, $50, $54, $4C, $4F, $41, $62, $3E, $51, $51, $3E, $40, $48, $F0
SkillDesc_218_LIFE:  ; $6636 "Makes you feel/sick"
    db $30, $3E, $48, $42, $50, $62, $56, $4C, $52, $62, $43, $42, $42, $49, $F1, $50, $46, $40, $48, $F0
SkillDesc_None:  ; $664A ""
    db $F0
SkillDescModeTable:  ; $664B — `ld de, SkillDescModeTable` + CallTextEngine /
;   RunTextHandler (SetB56_4901): text mode 0 = the debug menu strings,
;   mode 1 = the skill descriptions (index = skill id)
    dw SkillDebugTextPtrs, SkillDescPtrTable
SkillDebugTextPtrs:  ; $664F — mode 0: 12 debug-menu strings at $4E4C-$502E
;   ("MESSEGE DEBUG", "TESTMES", ... "INVALID NUMBER!"; left as raw words —
;   their bytes are still mgbdis fake code above)
    dw $4E4C, $4E63, $4E9B, $4EC7, $4EF3, $4F1F
    dw $4F4B, $4F77, $4FA3, $4FCB, $4FF3, $501F
SkillDescPtrTable:  ; $6667 — 256 dw by skill id (mode 1)
    dw SkillDesc_000_Blaze         ; [  0] Blaze
    dw SkillDesc_001_Blazemore     ; [  1] Blazemore
    dw SkillDesc_002_Blazemost     ; [  2] Blazemost
    dw SkillDesc_003_Firebal       ; [  3] Firebal
    dw SkillDesc_004_Firebane      ; [  4] Firebane
    dw SkillDesc_005_Firebolt      ; [  5] Firebolt
    dw SkillDesc_006_Bang          ; [  6] Bang
    dw SkillDesc_007_Boom          ; [  7] Boom
    dw SkillDesc_008_Explodet      ; [  8] Explodet
    dw SkillDesc_009_Infernos      ; [  9] Infernos
    dw SkillDesc_010_Infermore     ; [ 10] Infermore
    dw SkillDesc_011_Infermost     ; [ 11] Infermost
    dw SkillDesc_012_IceBolt       ; [ 12] IceBolt
    dw SkillDesc_013_SnowStorm     ; [ 13] SnowStorm
    dw SkillDesc_014_Blizzard      ; [ 14] Blizzard
    dw SkillDesc_015_Bolt          ; [ 15] Bolt
    dw SkillDesc_016_Zap           ; [ 16] Zap
    dw SkillDesc_017_Thordain      ; [ 17] Thordain
    dw SkillDesc_018_Beat          ; [ 18] Beat
    dw SkillDesc_019_Defeat        ; [ 19] Defeat
    dw SkillDesc_020_Sacrifice     ; [ 20] Sacrifice
    dw SkillDesc_021_Sleep         ; [ 21] Sleep
    dw SkillDesc_022_SleepAll      ; [ 22] SleepAll
    dw SkillDesc_023_StopSpell     ; [ 23] StopSpell
    dw SkillDesc_024_Surround      ; [ 24] Surround
    dw SkillDesc_025_PanicAll      ; [ 25] PanicAll
    dw SkillDesc_026_RobMagic      ; [ 26] RobMagic
    dw SkillDesc_027_TakeMagic     ; [ 27] TakeMagic
    dw SkillDesc_028_Sap           ; [ 28] Sap
    dw SkillDesc_029_Defence       ; [ 29] Defence
    dw SkillDesc_030_Upper         ; [ 30] Upper
    dw SkillDesc_031_Increase      ; [ 31] Increase
    dw SkillDesc_032_Slow          ; [ 32] Slow
    dw SkillDesc_033_SlowAll       ; [ 33] SlowAll
    dw SkillDesc_034_Speed         ; [ 34] Speed
    dw SkillDesc_035_SpeedUp       ; [ 35] SpeedUp
    dw SkillDesc_036_Barrier       ; [ 36] Barrier
    dw SkillDesc_037_TwinHits      ; [ 37] TwinHits
    dw SkillDesc_038_MagicWall     ; [ 38] MagicWall
    dw SkillDesc_039_MagicBack     ; [ 39] MagicBack
    dw SkillDesc_040_Bounce        ; [ 40] Bounce
    dw SkillDesc_041_Transform     ; [ 41] Transform
    dw SkillDesc_042_Ironize       ; [ 42] Ironize
    dw SkillDesc_043_Heal          ; [ 43] Heal
    dw SkillDesc_044_HealMore      ; [ 44] HealMore
    dw SkillDesc_045_HealAll       ; [ 45] HealAll
    dw SkillDesc_046_HealUs        ; [ 46] HealUs
    dw SkillDesc_047_HealUsAll     ; [ 47] HealUsAll
    dw SkillDesc_048_Vivify        ; [ 48] Vivify
    dw SkillDesc_049_Revive        ; [ 49] Revive
    dw SkillDesc_050_Farewell      ; [ 50] Farewell
    dw SkillDesc_051_Antidote      ; [ 51] Antidote
    dw SkillDesc_052_NumbOff       ; [ 52] NumbOff
    dw SkillDesc_053_DeChaos       ; [ 53] DeChaos
    dw SkillDesc_054_CurseOff      ; [ 54] CurseOff
    dw SkillDesc_055_StepGuard     ; [ 55] StepGuard
    dw SkillDesc_056_MapMagic      ; [ 56] MapMagic
    dw SkillDesc_057_Chance        ; [ 57] Chance
    dw SkillDesc_058_Attack        ; [ 58] Attack
    dw SkillDesc_059_TwinSlash     ; [ 59] TwinSlash
    dw SkillDesc_060_Ramming       ; [ 60] Ramming
    dw SkillDesc_061_Beserker      ; [ 61] Beserker
    dw SkillDesc_062_Kamikaze      ; [ 62] Kamikaze
    dw SkillDesc_063_Massacre      ; [ 63] Massacre
    dw SkillDesc_064_EvilSlash     ; [ 64] EvilSlash
    dw SkillDesc_065_ChargeUP      ; [ 65] ChargeUP
    dw SkillDesc_066_HighJump      ; [ 66] HighJump
    dw SkillDesc_067_SuckAir       ; [ 67] SuckAir
    dw SkillDesc_068_FireSlash     ; [ 68] FireSlash
    dw SkillDesc_069_BoltSlash     ; [ 69] BoltSlash
    dw SkillDesc_070_VacuSlash     ; [ 70] VacuSlash
    dw SkillDesc_071_IceSlash      ; [ 71] IceSlash
    dw SkillDesc_072_MetalCut      ; [ 72] MetalCut
    dw SkillDesc_073_DrakSlash     ; [ 73] DrakSlash
    dw SkillDesc_074_BeastCut      ; [ 74] BeastCut
    dw SkillDesc_075_BirdBlow      ; [ 75] BirdBlow
    dw SkillDesc_076_DevilCut      ; [ 76] DevilCut
    dw SkillDesc_077_ZombieCut     ; [ 77] ZombieCut
    dw SkillDesc_078_CleanCut      ; [ 78] CleanCut
    dw SkillDesc_079_MultiCut      ; [ 79] MultiCut
    dw SkillDesc_080_BiAttack      ; [ 80] BiAttack
    dw SkillDesc_081_QuadHits      ; [ 81] QuadHits
    dw SkillDesc_082_CallHelp      ; [ 82] CallHelp
    dw SkillDesc_083_YellHelp      ; [ 83] YellHelp
    dw SkillDesc_084_Focus         ; [ 84] Focus
    dw SkillDesc_085_SquallHit     ; [ 85] SquallHit
    dw SkillDesc_086_PsycheUp      ; [ 86] PsycheUp
    dw SkillDesc_087_RainSlash     ; [ 87] RainSlash
    dw SkillDesc_088_WindBeast     ; [ 88] WindBeast
    dw SkillDesc_089_Vacuum        ; [ 89] Vacuum
    dw SkillDesc_090_Lightning     ; [ 90] Lightning
    dw SkillDesc_091_RockThrow     ; [ 91] RockThrow
    dw SkillDesc_092_FireAir       ; [ 92] FireAir
    dw SkillDesc_093_BlazeAir      ; [ 93] BlazeAir
    dw SkillDesc_094_Scorching     ; [ 94] Scorching
    dw SkillDesc_095_WhiteFire     ; [ 95] WhiteFire
    dw SkillDesc_096_FrigidAir     ; [ 96] FrigidAir
    dw SkillDesc_097_IceAir        ; [ 97] IceAir
    dw SkillDesc_098_IceStorm      ; [ 98] IceStorm
    dw SkillDesc_099_WhiteAir      ; [ 99] WhiteAir
    dw SkillDesc_100_Hellblast     ; [100] Hellblast
    dw SkillDesc_101_BigBang       ; [101] BigBang
    dw SkillDesc_102_MegaMagic     ; [102] MegaMagic
    dw SkillDesc_103_PoisonHit     ; [103] PoisonHit
    dw SkillDesc_104_NapAttack     ; [104] NapAttack
    dw SkillDesc_105_Paralyze      ; [105] Paralyze
    dw SkillDesc_106_SleepAir      ; [106] SleepAir
    dw SkillDesc_107_PalsyAir      ; [107] PalsyAir
    dw SkillDesc_108_PoisonGas     ; [108] PoisonGas
    dw SkillDesc_109_PoisonAir     ; [109] PoisonAir
    dw SkillDesc_110_PaniDance     ; [110] PaniDance
    dw SkillDesc_111_Curse         ; [111] Curse
    dw SkillDesc_112_Ahhh          ; [112] Ahhh
    dw SkillDesc_113_KODance       ; [113] K.O.Dance
    dw SkillDesc_114_SandStorm     ; [114] SandStorm
    dw SkillDesc_115_Radiant       ; [115] Radiant
    dw SkillDesc_116_EerieLite     ; [116] EerieLite
    dw SkillDesc_117_OddDance      ; [117] OddDance
    dw SkillDesc_118_RobDance      ; [118] RobDance
    dw SkillDesc_119_SideStep      ; [119] SideStep
    dw SkillDesc_120_LureDance     ; [120] LureDance
    dw SkillDesc_121_LushLicks     ; [121] LushLicks
    dw SkillDesc_122_SickLick      ; [122] SickLick
    dw SkillDesc_123_LegSweep      ; [123] LegSweep
    dw SkillDesc_124_BigTrip       ; [124] BigTrip
    dw SkillDesc_125_WarCry        ; [125] WarCry
    dw SkillDesc_126_Whistle       ; [126] Whistle
    dw SkillDesc_127_Imitate       ; [127] Imitate
    dw SkillDesc_128_DeMagic       ; [128] DeMagic
    dw SkillDesc_129_Surge         ; [129] Surge
    dw SkillDesc_130_UltraDown     ; [130] UltraDown
    dw SkillDesc_131_ThickFog      ; [131] ThickFog
    dw SkillDesc_132_TatsuCall     ; [132] TatsuCall
    dw SkillDesc_133_DiagoCall     ; [133] DiagoCall
    dw SkillDesc_134_SamsiCall     ; [134] SamsiCall
    dw SkillDesc_135_BazooCall     ; [135] BazooCall
    dw SkillDesc_136_Cover         ; [136] Cover
    dw SkillDesc_137_Guardian      ; [137] Guardian
    dw SkillDesc_138_TailWind      ; [138] TailWind
    dw SkillDesc_139_StormWind     ; [139] StormWind
    dw SkillDesc_140_Dodge         ; [140] Dodge
    dw SkillDesc_141_Defence       ; [141] Defence
    dw SkillDesc_142_StrongD       ; [142] StrongD
    dw SkillDesc_143_SuckAll       ; [143] SuckAll
    dw SkillDesc_144_BladeD        ; [144] BladeD
    dw SkillDesc_145_DanceShut     ; [145] DanceShut
    dw SkillDesc_146_MouthShut     ; [146] MouthShut
    dw SkillDesc_147_Meditate      ; [147] Meditate
    dw SkillDesc_148_Hustle        ; [148] Hustle
    dw SkillDesc_149_LifeSong      ; [149] LifeSong
    dw SkillDesc_150_LifeDance     ; [150] LifeDance
    dw SkillDesc_Blank             ; [151] Run
    dw SkillDesc_Blank             ; [152] Daze
    dw SkillDesc_Blank             ; [153] HitAlly
    dw SkillDesc_Blank             ; [154] HitEnemy
    dw SkillDesc_Blank             ; [155] HitRandom
    dw SkillDesc_Blank             ; [156] Scared
    dw SkillDesc_Blank             ; [157] Dance
    dw SkillDesc_Blank             ; [158] Trip
    dw SkillDesc_Blank             ; [159] Paralyze
    dw SkillDesc_Blank             ; [160] CANTMOVE
    dw SkillDesc_Blank             ; [161] RUN
    dw SkillDesc_Blank             ; [162] CALLHOROR
    dw SkillDesc_Blank             ; [163] HealUsAll
    dw SkillDesc_Blank             ; [164] Smashed
    dw SkillDesc_Blank             ; [165] FILTHZONE
    dw SkillDesc_Blank             ; [166] ALLCHANGE
    dw SkillDesc_Blank             ; [167] BIGSLEEP
    dw SkillDesc_Blank             ; [168] MP0
    dw SkillDesc_Blank             ; [169] ECHO
    dw SkillDesc_Blank             ; [170] CHGDRAGON
    dw SkillDesc_Blank             ; [171] CALLEVIL
    dw SkillDesc_Blank             ; [172] FREEZY
    dw SkillDesc_Blank             ; [173] ALLREVIVE
    dw SkillDesc_Blank             ; [174] RESTOREMP
    dw SkillDesc_Blank             ; [175] METEOR
    dw SkillDesc_Blank             ; [176] HERB
    dw SkillDesc_Blank             ; [177] HEALWATER
    dw SkillDesc_Blank             ; [178] SAGESTONE
    dw SkillDesc_Blank             ; [179] WARLDDEW
    dw SkillDesc_Blank             ; [180] POTION
    dw SkillDesc_Blank             ; [181] ELFWATER
    dw SkillDesc_Blank             ; [182] ANTIDOTE
    dw SkillDesc_Blank             ; [183] MOONHERB
    dw SkillDesc_Blank             ; [184] SKYBELL
    dw SkillDesc_Blank             ; [185] LAUREL
    dw SkillDesc_Blank             ; [186] AWAKESAND
    dw SkillDesc_Blank             ; [187] WARLDLEAF
    dw SkillDesc_Blank             ; [188] LIFEACORN
    dw SkillDesc_Blank             ; [189] MYSTICNUT
    dw SkillDesc_Blank             ; [190] PWRSEED
    dw SkillDesc_Blank             ; [191] DEFSEED
    dw SkillDesc_Blank             ; [192] AGILSEED
    dw SkillDesc_Blank             ; [193] INTSEED
    dw SkillDesc_Blank             ; [194] FEEDMEAT
    dw SkillDesc_Blank             ; [195] BEFFJERKY
    dw SkillDesc_Blank             ; [196] PORKCHOP
    dw SkillDesc_Blank             ; [197] BADMEAT
    dw SkillDesc_Blank             ; [198] SIRLOIN
    dw SkillDesc_Blank             ; [199] BOLTSTAFF
    dw SkillDesc_Blank             ; [200] STAFF
    dw SkillDesc_Blank             ; [201] BLOKSTAFF
    dw SkillDesc_Blank             ; [202] LAVASTAFF
    dw SkillDesc_Blank             ; [203] SNOWSTAFF
    dw SkillDesc_Blank             ; [204] FIRESTAFF
    dw SkillDesc_Blank             ; [205] WARPWING
    dw SkillDesc_Blank             ; [206] TINYMEDAL
    dw SkillDesc_Blank             ; [207] QuestBk
    dw SkillDesc_Blank             ; [208] HORRORBK
    dw SkillDesc_Blank             ; [209] BENICEBK
    dw SkillDesc_Blank             ; [210] CHEATERBK
    dw SkillDesc_Blank             ; [211] SMARTBK
    dw SkillDesc_Blank             ; [212] COMEDYBK
    dw SkillDesc_213_BeDragon      ; [213] BeDragon
    dw SkillDesc_214_Smashlime     ; [214] Smashlime
    dw SkillDesc_215_Sheldodge     ; [215] Sheldodge
    dw SkillDesc_216_Branching     ; [216] Branching
    dw SkillDesc_217_GigaSlash     ; [217] GigaSlash
    dw SkillDesc_218_LIFE          ; [218] LIFE
    dw SkillDesc_None              ; [219] RUN
    dw SkillDesc_None              ; [220] IRONIZE
    dw SkillDesc_None              ; [221] Ahhh
    dw SkillDesc_None              ; [222] -
    dw SkillDesc_None              ; [223] -
    dw SkillDesc_None              ; [224] -
    dw SkillDesc_None              ; [225] -
    dw SkillDesc_None              ; [226] -
    dw SkillDesc_None              ; [227] -
    dw SkillDesc_None              ; [228] -
    dw SkillDesc_None              ; [229] -
    dw SkillDesc_None              ; [230] -
    dw SkillDesc_None              ; [231] -
    dw SkillDesc_None              ; [232] -
    dw SkillDesc_None              ; [233] -
    dw SkillDesc_None              ; [234] -
    dw SkillDesc_None              ; [235] -
    dw SkillDesc_None              ; [236] -
    dw SkillDesc_None              ; [237] -
    dw SkillDesc_None              ; [238] -
    dw SkillDesc_None              ; [239] -
    dw SkillDesc_None              ; [240] -
    dw SkillDesc_None              ; [241] -
    dw SkillDesc_None              ; [242] -
    dw SkillDesc_None              ; [243] -
    dw SkillDesc_None              ; [244] -
    dw SkillDesc_None              ; [245] -
    dw SkillDesc_None              ; [246] -
    dw SkillDesc_None              ; [247] -
    dw SkillDesc_None              ; [248] -
    dw SkillDesc_None              ; [249] -
    dw SkillDesc_None              ; [250] -
    dw SkillDesc_None              ; [251] -
    dw SkillDesc_None              ; [252] -
    dw SkillDesc_None              ; [253] -
    dw SkillDesc_None              ; [254] -
    dw SkillDesc_None              ; [255] -
    jr nz, jr_056_6869

jr_056_6869:
    ld bc, $00ff
    rst $38
    add $01
    ld [bc], a
    ld bc, $01fe
    ld [bc], a
    inc bc
    ld bc, $0001
    xor $ff
    xor $ff
    cp $ff
    sub $01
    ld [bc], a

jr_056_6881:
    nop
    jr nz, jr_056_6884

jr_056_6884:
    ld bc, $82ff
    rst $38
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
    rst $38
    add d
    ld bc, $0114
    ld b, h
    rst $38
    jr c, @+$01

    nop
    jr nz, jr_056_68a5

jr_056_68a5:
    ld bc, $00ff
    rst $38
    ld [bc], a
    rst $38
    inc b
    rst $38
    ld [$10ff], sp
    rst $38
    jr nz, @+$01

    ld b, b
    rst $38
    add b
    rst $38
    nop
    rst $38
    db $10
    rst $38
    sub d
    rst $38
    ld d, h
    rst $38
    jr c, @+$01

    ld d, h
    rst $38
    sub d
    rst $38
    stop
    dec b
    dec b
    dec b
    rst $38
    db $fc
    ld bc, $0f01
    rrca
    ccf
    ccf
    ld a, h
    ld a, h
    ldh a, [$f0]
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    dec b
    ld e, $01
    add b
    add b
    dec b
    rst $38
    db $f4
    rst $38
    rst $38
    ld hl, sp-$08
    ld hl, sp-$08
    dec b
    rst $38
    or $f8
    ld hl, sp+$1c
    dec b
    ld b, b
    dec bc
    rrca
    rrca
    rrca
    rrca
    ld c, $05
    ld d, h
    rlca
    dec b
    ld e, $00
    dec b
    rst $38
    ld hl, sp-$40
    ret nz

    ld hl, sp-$08
    cp $fe
    rra
    rra
    inc bc
    inc bc
    inc bc
    inc bc
    ld bc, $0101
    ld bc, $ff05
    db $f4
    add c
    add c
    add e
    add e
    jp $c3c3


    jp $0707


    rra
    rra
    ld a, [hl]
    ld a, [hl]
    ldh a, [$f0]
    ret nz

    ret nz

    add b
    add b
    dec b
    inc h
    nop
    dec b
    ld e, $00
    inc bc
    inc bc
    dec b
    ld h, h
    ld a, [bc]
    ldh a, [$f0]
    ld a, b
    ld a, b
    inc e
    inc e
    dec b
    ld d, h
    nop
    ld b, $06
    ld bc, $0701
    rlca
    dec b
    ld d, d
    nop
    rrca
    rrca
    rlca
    rlca
    dec b
    and h
    nop
    dec b
    ld h, b
    ld b, $c0
    ret nz

    db $fc
    db $fc
    ld a, a
    ld a, a
    db $fc
    db $fc
    db $fc
    db $fc
    dec b
    ld h, [hl]
    ld [$ffff], sp
    ldh [$e0], a
    ldh a, [$f0]
    ld a, h
    ld a, h
    ccf
    ccf
    rrca
    rrca
    dec b
    ld a, [hl]
    nop
    dec b
    ld h, d
    inc b
    add b
    add b
    dec b
    ld h, b
    ld [bc], a
    dec b
    ld [hl-], a
    ld b, $05
    jr nc, jr_056_697a

    dec b
    ld b, b

jr_056_697a:
    ld a, [bc]
    nop
    nop
    dec b
    ld d, h
    ld [$0e0e], sp
    dec b
    rst $38
    ld hl, sp+$05
    ld h, b
    ld [bc], a
    ld bc, $0501
    ld a, b
    nop
    rrca
    rrca
    cp $fe
    ld hl, sp-$08
    ret nz

    ret nz

    nop
    nop
    jp $83c3


    add e
    add c
    add c
    dec b
    rst $38
    or $05
    sbc d
    nop
    dec b
    or d
    nop
    ld a, [hl]
    ld a, [hl]
    rra
    rra
    rlca
    rlca
    dec b
    rst $38
    or $03
    inc bc
    dec b
    ld h, b
    ld [bc], a
    dec b
    ld d, h
    nop
    inc e
    inc e
    ld a, b
    ld a, b
    dec b
    sub [hl]
    nop
    dec b
    rst $38
    ld a, [$5005]
    nop
    nop
    nop
    dec b
    ld a, h
    ld d, $05
    ld a, [bc]
    inc d
    ld a, [hl]
    ld a, [hl]
    dec b
    ret z

    nop
    rra
    rra
    dec b
    ld e, b
    db $10
    dec b
    rst $38
    ld a, [c]
    jr nz, jr_056_69e0

    call nc, $0515
    rst $38
    ld a, [c]

jr_056_69e0:
    ld [de], a
    ld [de], a
    ld a, [de]
    ld a, [de]
    ld d, $16
    ld [de], a
    ld [de], a
    ld [de], a
    ld [de], a
    dec b
    add d
    inc d
    dec b
    ld a, h
    nop
    dec b
    ld a, h
    ld b, $05
    inc h
    ld b, $05
    rst $38
    ld a, [c]
    ldh a, [$f0]
    add b
    add b
    ldh [$e0], a
    add b
    add b
    ldh a, [$f0]
    dec b
    rst $38
    ld a, [c]
    inc e
    inc e
    ld [de], a
    ld [de], a
    dec b
    inc h
    jr nz, jr_056_6a13

    db $ec
    inc d
    ld bc, $0201

jr_056_6a13:
    ld [bc], a
    inc bc
    inc bc
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    dec b
    ld [bc], a
    inc d
    ld b, b
    ld b, b
    ret nz

    ret nz

    ld b, b
    ld b, b
    ld b, b
    ld b, b
    dec b
    rst $38
    ld a, [c]
    jr nc, jr_056_6a5a

    ld c, b
    ld c, b
    ld b, b
    ld b, b
    ld c, b
    ld c, b
    jr nc, jr_056_6a62

    dec b
    rst $38
    ld a, [c]
    ld c, $0e
    inc b
    dec b
    ld h, [hl]
    inc hl
    dec b
    ld a, [bc]
    inc b
    dec b
    or $1a
    dec b
    ld hl, sp+$18
    dec b
    ret nc

    ld d, $c0
    ret nz

    dec b
    sbc d
    inc d
    inc a
    inc a
    jr nz, jr_056_6a70

    jr c, jr_056_6a8a

    jr nz, jr_056_6a74

    inc a
    inc a
    dec b
    and b
    rst $38
    ld c, l

jr_056_6a5a:
    dec b
    dec c
    ccf
    ld c, l
    dec b
    ld l, l
    ccf
    ld c, l

jr_056_6a62:
    dec b
    call $4d3f
    dec b
    dec l
    ld c, a
    ld c, l
    dec b
    adc l
    ld c, a
    ld c, l
    dec b
    db $ed

jr_056_6a70:
    ld c, [hl]
    ld b, b
    ld [bc], a
    inc b

jr_056_6a74:
    inc b
    rst $38
    db $fc
    ld bc, $0f01
    rrca
    ccf
    ccf
    ld a, h
    ld a, h
    ldh a, [$f0]
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    inc b
    ld e, $01
    add b

jr_056_6a8a:
    add b
    inc b
    rst $38
    db $f4
    rst $38
    rst $38
    ld hl, sp-$08
    ld hl, sp-$08
    inc b
    rst $38
    or $f8
    ld hl, sp+$1c
    inc b
    ld b, b
    dec bc
    rrca
    rrca
    rrca
    rrca
    ld c, $04
    ld d, h
    rlca
    inc b
    ld e, $00
    inc b
    rst $38
    ld hl, sp-$40
    ret nz

    ld hl, sp-$08
    cp $fe
    rra
    rra
    inc bc
    inc bc
    inc bc
    inc bc
    ld bc, $0101
    ld bc, $ff04
    db $f4
    add c
    add c
    add e
    add e
    jp $c3c3


    jp $0707


    rra
    rra
    ld a, [hl]
    ld a, [hl]
    ldh a, [$f0]
    ret nz

    ret nz

    add b
    add b
    inc b
    inc h
    nop
    inc b
    ld e, $00
    inc bc
    inc bc
    inc b
    ld h, h
    ld a, [bc]
    ldh a, [$f0]
    ld a, b
    ld a, b
    inc e
    inc e
    inc b
    ld d, h
    nop
    ld b, $06
    ld bc, $0701
    rlca
    inc b
    ld d, d
    nop
    rrca
    rrca
    rlca
    rlca
    inc b
    and h
    nop
    inc b
    ld h, b
    ld b, $c0
    ret nz

    db $fc
    db $fc
    ld a, a
    ld a, a
    db $fc
    db $fc
    db $fc
    db $fc
    inc b
    ld h, [hl]
    ld [$ffff], sp
    ldh [$e0], a
    ldh a, [$f0]
    ld a, h
    ld a, h
    ccf
    ccf
    rrca
    rrca
    inc b
    ld a, [hl]
    nop
    inc b
    ld h, d
    inc b
    add b
    add b
    inc b
    ld h, b
    ld [bc], a
    inc b
    ld [hl-], a
    ld b, $04
    jr nc, jr_056_6b25

    inc b
    ld b, b

jr_056_6b25:
    ld a, [bc]
    nop
    nop
    inc b
    ld d, h
    ld [$0e0e], sp
    inc b
    rst $38
    ld hl, sp+$04
    ld h, b
    ld [bc], a
    ld bc, $0401
    ld a, b
    nop
    rrca
    rrca
    cp $fe
    ld hl, sp-$08
    ret nz

    ret nz

    nop
    nop
    jp $83c3


    add e
    add c
    add c
    inc b
    rst $38
    or $04
    sbc d
    nop
    inc b
    or d
    nop
    ld a, [hl]
    ld a, [hl]
    rra
    rra
    rlca
    rlca
    inc b
    rst $38
    or $03
    inc bc
    inc b
    ld h, b
    ld [bc], a
    inc b
    ld d, h
    nop
    inc e
    inc e
    ld a, b
    ld a, b
    inc b
    sub [hl]
    nop
    inc b
    rst $38
    ld a, [$5004]
    nop
    nop
    nop
    inc b
    ld a, h
    ld d, $04
    ld a, [bc]
    inc d
    ld a, [hl]
    ld a, [hl]
    inc b
    ret z

    nop
    rra
    rra
    inc b
    ld e, b
    db $10
    inc b
    rst $38
    ld a, [c]
    jr nz, jr_056_6b8a

    call nc, $0415
    rst $38

jr_056_6b8a:
    ld a, [c]
    ld [de], a
    ld [de], a
    ld a, [de]
    ld a, [de]
    ld d, $16
    ld [de], a
    ld [de], a
    ld [de], a
    ld [de], a
    inc b
    add d
    inc d
    inc b
    ld a, h
    nop
    inc b
    ld a, h
    ld b, $04
    inc h
    ld b, $04
    rst $38
    ld a, [c]
    ldh a, [$f0]
    add b
    add b
    ldh [$e0], a
    add b
    add b
    ldh a, [$f0]
    inc b
    rst $38
    ld a, [c]
    inc e
    inc e
    ld [de], a
    ld [de], a
    inc b
    inc h
    jr nz, @+$06

    db $ec
    inc d
    ld bc, $0201
    ld [bc], a
    inc bc
    inc bc
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    inc bc
    ld bc, $01ff
    rst $38
    cp $18
    ld bc, $0712
    rra
    rst $38
    nop
    rst $38
    inc a
    ld bc, $0712
    inc a
    rst $38
    nop
    rst $38
    ld [hl], c
    rst $38
    reti


    rst $38
    pop bc
    ld bc, $0136
    reti


    rst $38
    ld [hl], c
    rst $38
    nop
    rst $38
    di
    rst $38
    add e
    rst $38
    add e
    ld bc, $0542
    nop
    rst $38
    inc hl
    rst $38
    ld h, $ff
    and a
    rst $38
    and e
    rst $38
    ld h, c
    rst $38
    ld h, h
    rst $38
    daa
    rst $38
    nop
    rst $38
    rst $08
    rst $38
    ld c, h
    rst $38
    inc c
    rst $38
    adc a
    rst $38
    call z, $ccff
    rst $38
    adc a
    rst $38
    nop
    rst $38
    sbc [hl]
    rst $38
    dec de
    rst $38
    dec de
    rst $38
    sbc e
    ld bc, $0174
    sbc [hl]
    ld bc, $0f00
    nop
    ld a, c
    rst $38
    ld h, l
    rst $38
    ld h, h
    rst $38
    ld a, b
    rst $38
    ld h, h
    ld bc, $0196
    nop
    rst $38
    ld [$98ff], sp
    rst $38
    sub b
    rst $38
    ldh a, [rIE]
    ld h, b
    ld bc, $01aa
    nop
    rst $38
    inc bc
    ld bc, $09b2
    nop
    rst $38
    daa
    rst $38
    inc hl
    rst $38
    and e
    rst $38
    and e
    rst $38
    ld h, e
    rst $38
    ld h, e
    ld bc, $015e
    sbc c
    rst $38
    add hl, de
    rst $38
    dec e
    rst $38
    dec e
    ld bc, $0174
    sbc c
    rst $38
    nop
    rst $38
    ccf
    rst $38
    inc c
    ld bc, $07e4
    nop
    rst $38
    ld a, $ff
    jr nc, @+$01

    jr nc, jr_056_6c72

    ld a, [c]

jr_056_6c72:
    dec b
    nop
    ld bc, $019a
    ld [hl], h
    rst $38
    ld [hl], h
    rst $38
    ld l, h
    rst $38
    ld l, h
    rst $38
    ld h, h
    rst $38
    nop
    rst $38
    ldh a, [rIE]
    reti


    ld bc, StoreRunLength
    ldh a, [rIE]
    nop
    rst $38
    ldh [rIE], a
    or b
    ld bc, $1524
    ldh [rSB], a
    and b
    rst $38
    ld c, l
    ld bc, $1f8f
    ld c, l
    ld bc, $1fef
    ld c, l
    ld bc, $2f4f
    ld c, l
    ld bc, $2faf
    dec a
    sub b
    nop
    ld bc, $00ff
    rst $38
    ldh a, [rIE]
    adc b
    rst $38
    adc b
    ld bc, $0502
    nop
    rst $38
    ld hl, sp-$01
    add b
    rst $38
    add b
    ld bc, $0512
    nop
    rst $38
    ld [hl], b
    rst $38
    adc b
    rst $38
    add b
    rst $38
    cp h
    rst $38
    adc b
    rst $38
    sbc b
    rst $38
    ld l, b
    rst $38
    nop
    rst $38
    ld b, h
    rst $38
    ld b, [hl]
    rst $38
    ld b, l
    rst $38
    ld b, l
    rst $38
    ld b, h
    ld bc, $013a
    ld bc, $0631
    call nz, $3c01
    dec b
    ld bc, $023b
    ld bc, $064b
    ld h, h
    rst $38
    ld d, h
    rst $38
    ld d, h
    rst $38
    ld c, h
    ld bc, Goto_EvtDemo
    jr c, @+$01

    ld b, h
    rst $38
    ld b, b
    rst $38
    ld e, [hl]
    rst $38
    ld b, h
    rst $38
    ld c, h
    rst $38
    inc [hl]
    rst $38
    nop
    rst $38
    jr @+$01

    jr @+$01

    ld bc, $f0ff
    ld bc, $0183
    sub b
    nop
    ld bc, $00ff
    rst $38
    adc b
    ld bc, $0302
    ld d, b
    rst $38
    ld d, b
    rst $38
    jr nz, jr_056_6d20

    nop

jr_056_6d20:
    rlca
    ld bc, $0003
    adc a
    rst $38
    nop
    rst $38
    ld [$2201], sp
    rlca
    ld bc, $001f
    ld [bc], a
    rst $38
    dec b
    ld bc, HeaderTitle
    rrca
    rst $38
    ld [$88ff], sp
    rst $38
    nop
    rst $38
    rlca
    ld bc, $0122
    dec bc
    rst $38
    adc b
    rst $38
    adc c
    rst $38
    add [hl]
    ld bc, $0140
    add h
    rst $38
    inc b
    rst $38
    rst $00
    rst $38
    add h
    rst $38
    add h
    rst $38
    add a
    rst $38
    nop
    rst $38
    rst $00
    rst $38
    inc b
    ld bc, $0156
    dec b
    rst $38
    inc b
    rst $38
    db $c4, $ff, $00
    rst $38
    add b
    rst $38
    ld b, b
    rst $38
    ld b, b
    rst $38
    add b
    ld bc, $0370
    nop
    rst $38
    jr @+$01

    jr @+$01

    ld bc, $f0ff
    ld bc, $0183
    sub b
    nop
    ld bc, $00ff
    rst $38
    ld hl, sp-$01
    jr nz, jr_056_6d88

    inc b

jr_056_6d88:
    rlca
    nop
    rst $38
    jr nz, @+$01

    ld d, b
    ld bc, $0114
    ld hl, sp-$01
    adc b
    rst $38
    adc b
    rst $38
    nop
    rst $38
    add b
    ld bc, $0722
    ld hl, sp-$01
    nop
    rst $38
    add a
    ld bc, $011c
    add a
    rst $38
    add b
    ld bc, $0136
    nop
    rst $38
    ld [$8dff], sp
    rst $38
    ld a, [bc]
    rst $38
    ld a, [bc]
    ld bc, $011c
    ld [$00ff], sp
    rst $38
    add d
    rst $38
    add l
    ld bc, $0154
    adc a
    ld bc, $031c
    ld [$0cff], sp
    ld bc, HeaderSGBFlag
    adc c
    ld bc, $0f1c
    nop
    add b
    rst $38
    nop
    rst $38
    jr @+$01

    jr @+$01

    ld bc, $f0ff
    ld bc, $0183
    sub b
    nop
    ld bc, $00ff
    rst $38
    adc b
    rst $38
    ret c

    rst $38
    xor b
    rst $38
    xor b
    rst $38
    adc b
    ld bc, $010a
    nop
    rst $38
    ld hl, sp-$01
    add b
    rst $38
    add b
    ld bc, $0512
    ld bc, $0e01
    ld [hl], b
    ld bc, $030a
    ld bc, $000b
    ld [hl], b
    rst $38
    nop
    rst $38
    ldh a, [rSB]
    ld a, [bc]
    ld bc, $fff0
    and b
    rst $38
    sub b
    ld bc, $010e
    jr nz, jr_056_6e17

    ld d, d

jr_056_6e17:
    add hl, bc
    ld bc, $0e11
    ld bc, $0033
    add b
    rst $38
    ld [hl], b
    rst $38
    ld [$3c01], sp
    inc bc
    jr @+$01

    jr @+$01

    ld bc, $f0ff
    ld bc, $0183
    sub b
    nop
    ld bc, $00ff
    rst $38
    ldh a, [rIE]
    adc b
    rst $38
    adc b
    ld bc, $0502
    nop
    rst $38
    ld hl, sp-$01
    add b
    rst $38
    add b
    ld bc, $0512
    nop
    ld bc, HeaderLogo
    adc b
    rst $38
    xor b
    rst $38
    xor b
    rst $38
    ret c

    rst $38
    adc b
    rst $38
    nop
    rst $38
    add h
    ld bc, $0732
    add a
    rst $38
    nop
    rst $38
    rrca
    rst $38
    ld [$4401], sp
    dec b
    rst $08
    ld bc, $0140
    ld bc, $0005
    adc a
    ld bc, HeaderLogo
    rrca
    rst $38
    nop
    rst $38
    adc a
    ld bc, HeaderNewLicenseeCode
    adc a
    rst $38
    ld a, [bc]
    rst $38
    add hl, bc
    ld bc, $012e
    nop
    ld bc, $0114
    ld bc, $f0ff
    ld bc, $0073
    nop
    rst $38
    jr @+$01

    jr jr_056_6e92

    ld [hl], b

jr_056_6e92:
    ld bc, $8301
    ld bc, $0090
    ld bc, $00ff
    rst $38
    ldh a, [rIE]
    adc b
    rst $38
    adc b
    rst $38
    ldh a, [rIE]
    add b
    ld bc, $010a
    nop
    rst $38
    ld hl, sp+$01
    ld a, [bc]
    ld bc, $1301
    inc b
    nop
    rst $38
    jr nz, @+$01

    ld d, b
    ld bc, $0124
    ld hl, sp+$01
    inc b
    ld bc, $ff00
    ld [hl], b
    rst $38
    adc b
    ld bc, $030a
    adc b
    rst $38
    ld [hl], b
    ld bc, $0f10
    nop
    ld bc, $0f51
    dec e
    jr @+$01

    jr jr_056_6ed5

    ld a, [hl]

jr_056_6ed5:
    ld b, $90
    nop
    ld bc, $00ff
    rst $38
    ldh a, [rIE]
    adc b
    rst $38
    adc b
    ld bc, $0502
    ld bc, CopyDEtoHLByte
    and b
    rst $38
    sub b
    rst $38
    adc b
    rst $38
    nop
    rst $38
    jr nz, @+$01

    ld d, b
    ld bc, $0124
    ld hl, sp+$01
    inc b
    ld bc, Boot
    inc b
    ld bc, $0501
    nop
    ld bc, $0025
    jr nz, @+$01

    nop
    rst $38
    ld hl, sp-$01
    add b
    rst $38
    add b
    ld bc, $0542
    ld bc, $0e11
    ld bc, $0237
    jr nz, jr_056_6f18

    ld l, b

jr_056_6f18:
    inc bc
    ld bc, $f0ff
    ld bc, $0a71
    jr @+$01

    jr jr_056_6f24

    ld a, [hl]

jr_056_6f24:
    ld b, $90
    nop
    ld bc, $00ff
    rst $38
    ld [hl], b
    rst $38
    adc b
    rst $38
    add b
    rst $38
    ld [hl], b
    rst $38
    ld [$88ff], sp
    rst $38
    ld [hl], b
    rst $38
    nop
    rst $38
    ld hl, sp-$01
    jr nz, jr_056_6f40

    inc d

jr_056_6f40:
    rlca
    nop
    rst $38
    ldh a, [rIE]
    adc b
    rst $38
    adc b
    rst $38
    ldh a, [rIE]
    and b
    rst $38
    sub b
    rst $38
    adc b
    ld bc, $0110
    add b
    rst $38
    add b
    ld bc, $0532
    nop
    rst $38
    adc b
    rst $38
    ret z

    rst $38
    xor b
    rst $38
    xor b
    rst $38
    sbc b
    ld bc, $0124
    ld bc, $0401
    cp h
    rst $38
    adc b
    rst $38
    sbc b
    rst $38
    ld l, b
    ld bc, $0f10
    nop
    ld bc, $0025
    adc b
    rst $38
    ld hl, sp+$01
    ld [hl], d
    inc bc
    nop
    rst $38
    jr @+$01

    jr @+$01

    ld bc, $f0ff
    ld bc, $0183
    sub b
    nop
    ld bc, $00ff
    rst $38
    jr nz, @+$01

    ld d, b
    ld bc, HeaderLogo
    ld hl, sp-$01
    adc b
    rst $38
    adc b
    rst $38
    nop
    rst $38
    adc b
    rst $38
    ret z

    rst $38
    xor b
    rst $38
    xor b
    rst $38
    sbc b
    ld bc, $030c
    ld [hl], b
    rst $38
    adc b
    rst $38
    add b
    rst $38
    cp h
    rst $38
    adc b
    rst $38
    sbc b
    rst $38
    ld l, b
    rst $38
    nop
    rst $38
    ld hl, sp-$01
    add b
    rst $38
    add b
    ld bc, $0532
    nop
    rst $38
    ldh a, [rSB]
    inc c
    ld bc, $fff0
    and b
    rst $38
    sub b
    ld bc, $010e
    ld bc, $0f51
    dec e
    jr @+$01

    jr jr_056_6fd9

    ld a, [hl]

jr_056_6fd9:
    ld b, $90
    nop
    ld bc, $00ff
    rst $38
    ld [$0201], sp
    inc bc
    adc b
    rst $38
    adc b
    rst $38
    ld [hl], b
    rst $38
    nop
    rst $38
    ld [hl], b
    ld bc, $010a
    ld bc, $0215
    ld bc, $000f
    ld bc, $000b
    ld d, b
    rst $38
    jr nz, @+$03

    jr z, jr_056_7002

    ld bc, $f0ff

jr_056_7002:
    ld bc, $0f31
    dec sp
    jr @+$01

    jr jr_056_700b

    ld a, [hl]

jr_056_700b:
    ld b, $90
    nop
    ld bc, $00ff
    rst $38
    adc b
    ld bc, $0102
    xor b
    rst $38
    xor b
    rst $38
    ret c

    rst $38
    adc b
    rst $38
    nop
    rst $38
    jr nz, jr_056_7023

    ld [de], a

jr_056_7023:
    add hl, bc
    nop
    rst $38
    ld [hl], b
    rst $38
    adc b
    rst $38
    add b
    rst $38
    ld [hl], b
    rst $38
    ld [$88ff], sp
    rst $38
    ld [hl], b
    rst $38
    nop
    rst $38
    ldh [rIE], a
    sub b
    ld bc, $0302
    sub b
    rst $38
    ldh [rSB], a
    jr nz, jr_056_7045

    ld bc, $0445

jr_056_7045:
    ld bc, $002f
    adc b
    rst $38
    ret c

    ld bc, $0108
    ld bc, $0203
    ld bc, $f0ff
    ld bc, $0f61
    dec bc
    jr @+$01

    jr jr_056_705d

    ld a, [hl]

jr_056_705d:
    ld b, $90
    nop
    ld bc, $00ff
    rst $38
    adc b
    ld bc, $0102
    ld hl, sp+$01
    ld [bc], a
    inc bc
    nop
    rst $38
    jr nz, @+$01

    ld d, b
    ld bc, $0114
    ld bc, $0209
    nop
    rst $38
    ldh a, [rSB]
    ld [bc], a
    ld bc, $fff0
    add b
    ld bc, $012a
    ld bc, $0e21
    adc b
    rst $38
    adc h
    rst $38
    adc d
    rst $38
    adc d
    rst $38
    adc c
    ld bc, $030c
    adc a
    ld bc, $0102
    ld bc, $0453
    nop
    rst $38
    add a
    rst $38
    ld [$08ff], sp
    rst $38
    add a
    rst $38
    nop
    ld bc, $0366
    ld c, $ff
    sub c
    rst $38
    db $10
    rst $38
    ld c, $ff
    add c
    rst $38
    sub c
    rst $38
    ld c, $ff
    nop
    rst $38
    jr @+$01

    jr @+$01

    ld bc, $f0ff
    ld bc, $0183
    sub b
    nop
    ld bc, $00ff
    rst $38
    ei
    rst $38
    ld [hl+], a
    rst $38
    ld [hl+], a
    rst $38
    inc hl
    ld bc, $0304
    nop
    rst $38
    db $e4
    rst $38
    ld b, $ff
    dec b
    rst $38
    push hl
    rst $38
    inc b
    rst $38
    inc b
    rst $38
    db $e4
    rst $38
    nop
    rst $38
    ld c, a
    rst $38
    ret z

    rst $38
    ld c, b
    rst $38
    ld c, a
    rst $38
    ld c, b
    ld bc, $012a
    nop
    rst $38
    rra
    rst $38
    add h
    rst $38
    add h
    ld bc, $011a
    ld bc, $001b
    nop
    rst $38
    ld [$14ff], sp
    ld bc, HeaderNewLicenseeCode
    ld a, $01
    inc b
    ld bc, $ff00
    ld a, h
    rst $38
    db $10
    ld bc, $0754
    nop
    rst $38
    ld b, a
    ld bc, $032a
    ld bc, $002b
    ld b, a
    rst $38
    nop
    rst $38
    ld de, $99ff
    rst $38
    sub l
    rst $38
    sub l
    rst $38
    sub e
    rst $38
    sub c
    rst $38
    ld de, $00ff
    rst $38
    jr @+$01

    jr @+$01

    ld bc, $f0ff
    ld bc, $0183
    sub b
    nop
    ld bc, $00ff
    rst $38
    add b
    ld bc, $0302
    add c
    rst $38
    add c
    rst $38
    ld sp, hl
    rst $38
    nop
    rst $38
    ld b, c
    rst $38
    and c
    ld bc, $0114
    pop af
    rst $38
    ld de, $11ff
    rst $38
    nop
    rst $38
    pop hl
    rst $38
    ld de, $10ff
    rst $38
    ldh [rIE], a
    db $10
    ld bc, $0126
    nop
    rst $38
    inc de
    rst $38
    ld [de], a
    rst $38
    and d
    rst $38
    ld b, e
    rst $38
    ld b, d
    ld bc, $013a
    nop
    rst $38
    pop bc
    rst $38
    ld hl, $21ff
    rst $38
    pop bc
    rst $38
    add c
    rst $38
    ld b, c
    rst $38
    ld hl, $00ff
    rst $38
    ld [$0cff], sp
    rst $38
    ld a, [bc]
    rst $38
    ld a, [bc]
    rst $38
    add hl, bc
    rst $38
    ld [$08ff], sp
    rst $38
    nop
    rst $38
    adc a
    rst $38
    add d
    ld bc, $0764
    nop
    rst $38
    sub c
    ld bc, $011c
    rra
    ld bc, $011c
    ld bc, $001f
    jr @+$01

    jr @+$01

    ld bc, $f0ff
    ld bc, $0183
    sub b
    nop
    ld bc, $00ff
    rst $38
    add hl, bc
    ld bc, $0302
    adc c
    rst $38
    adc c
    rst $38
    ld [hl], b
    rst $38
    nop
    rst $38
    inc de
    rst $38
    ld [de], a
    ld bc, $0514
    db $e3
    rst $38
    nop
    rst $38
    add e
    rst $38
    ld b, h
    rst $38
    inc h
    rst $38
    dec h
    rst $38
    inc h
    rst $38
    ld b, h
    rst $38
    add e
    rst $38
    nop
    rst $38
    adc b
    rst $38
    ld c, l
    rst $38
    ld a, [bc]
    rst $38
    ld [$48ff], a
    rst $38
    ret z

    rst $38
    ld c, b
    rst $38
    nop
    rst $38
    sbc a
    rst $38
    sub b
    rst $38
    sub b
    ld bc, $0542
    nop
    rst $38
    ld [hl+], a
    rst $38
    ld [hl-], a
    rst $38
    ld a, [hl+]
    rst $38
    ld a, [hl+]
    rst $38
    ld h, $ff
    ld [hl+], a
    rst $38
    ld [hl+], a
    rst $38
    nop
    rst $38
    ld a, h
    rst $38
    db $10
    ld bc, $0764
    ld bc, $f0ff
    ld bc, $0a71
    jr @+$01

    jr jr_056_7217

    ld a, [hl]

jr_056_7217:
    ld b, $90
    nop
    ld bc, $00ff
    rst $38
    pop af
    rst $38
    adc c
    rst $38
    adc c
    rst $38
    pop af
    rst $38
    and c
    rst $38
    sub c
    rst $38
    adc c
    rst $38
    nop
    rst $38
    di
    rst $38
    ld [bc], a
    rst $38
    ld [bc], a
    ld bc, $0312
    ld a, [c]
    rst $38
    nop
    rst $38
    db $e4
    rst $38
    inc b
    rst $38
    inc b
    rst $38
    call nz, $2401
    ld bc, $ff07
    nop
    rst $38
    rrca
    rst $38
    ld [$08ff], sp
    ld bc, Goto_Game
    rst $08
    rst $38
    nop
    rst $38
    adc [hl]
    rst $38
    ld de, $10ff
    rst $38
    sub b
    rst $38
    ld de, $11ff
    rst $38
    adc [hl]
    rst $38
    nop
    rst $38
    ld a, $01
    inc [hl]
    ld bc, $5501
    inc b
    nop
    rst $38
    ld b, a
    rst $38
    ld c, b
    ld bc, CallTextRenderer
    ld b, a
    rst $38
    nop
    rst $38
    ld de, $99ff
    rst $38
    sub l
    rst $38
    sub l
    rst $38
    sub e
    rst $38
    sub c
    rst $38
    ld de, $00ff
    rst $38
    jr @+$01

    jr @+$01

    ld bc, $f0ff
    ld bc, $0183
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
