; =============================================================================
; BANK $41 — NAME TABLES (MONSTERS, SKILLS, PERSONALITIES, ITEMS)
; =============================================================================
; Contains:
;   - Master string table pointer at $4007 (points to sub-tables)
;   - Monster name pointer table at $4339 (256 × 2 bytes → name addresses)
;   - Monster name strings at $5B1F (222 unique, $F0 terminated, charmap encoded)
;   - Skill name strings at $628E (256 entries, $F0 terminated, charmap encoded)
;   - Personality name pointer table at $4997 (27 × 2 bytes)
;   - Personality name strings at $7159 ($F0 terminated)
;   - Various other string tables (items, families, etc.)
;
; TEXT ENCODING: Uses charmap.asm (A=$24, a=$3E, space=$62, etc.)
;   Names terminated by $F0. Edit strings directly: db "NewName", $F0
;   NOTE: Changing name LENGTH requires updating the pointer table at $4339
;   unless pointer table is converted to label-based (future work).
;
; Sources: dump_monster_names.py, known_ROM_map.md, charmap.asm
; =============================================================================

; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $041", ROMX[$4000], BANK[$41]

    ld b, c
    sub e
    ld c, d
    sbc d
    ld c, d
    and c
    ld c, d
    dec h
    ld b, b
    add hl, sp
    ld b, b
    ld bc, $e341
    ld b, c
    inc hl
    ld b, e
    add hl, sp
    ld b, e
    add hl, sp
    ld b, l
    add hl, sp
    ld b, a
    rst $20
    ld c, b
    ccf
    ld c, c
    sub a
    ld c, c
    call $1749
    ld c, d
    dec de
    ld c, d
    ld a, e
    ld c, d
    xor b
    ld c, d
    xor b
    ld c, d
    xor b
    ld c, d
    xor b
    ld c, d
    dec h
    ld c, e
    ld [hl], c
    ld c, e
    add e
    ld c, e
    sbc e
    ld c, e
    pop bc
    ld c, e
    ld [de], a
    ld c, h
    ld e, [hl]
    ld c, h
    ld h, l
    ld c, h
    ld l, l
    ld c, h
    ld l, l
    ld c, h
    ld [hl], l
    ld c, h
    ld a, h
    ld c, h
    add h
    ld c, h
    adc e
    ld c, h
    sub e
    ld c, h
    sbc b
    ld c, h
    sbc [hl]
    ld c, h
    and [hl]
    ld c, h
    xor [hl]
    ld c, h
    or e
    ld c, h
    cp e
    ld c, h
    jp $c44c


    ld c, h
    call z, $d44c
    ld c, h
    push de
    ld c, h
    db $dd
    ld c, h
    push hl
    ld c, h
    and $4c
    xor $4c
    db $f4
    ld c, h
    push af
    ld c, h
    or $4c
    rst $38
    ld c, h
    nop
    ld c, l
    ld [$104d], sp
    ld c, l
    jr jr_041_40c6

    jr nz, jr_041_40c8

    jr z, jr_041_40ca

    cpl
    ld c, l
    inc sp
    ld c, l
    ld a, [hl-]
    ld c, l
    dec sp
    ld c, l
    inc a
    ld c, l
    dec a
    ld c, l
    ld b, l
    ld c, l
    ld c, l
    ld c, l
    ld d, l
    ld c, l
    ld e, l
    ld c, l
    ld h, l
    ld c, l
    ld l, l
    ld c, l
    ld [hl], l
    ld c, l
    ld a, l
    ld c, l
    add l
    ld c, l
    adc l
    ld c, l
    sub l
    ld c, l
    sbc l
    ld c, l
    and h
    ld c, l
    xor h
    ld c, l
    or e
    ld c, l
    cp d
    ld c, l
    cp a
    ld c, l
    rst $00
    ld c, l
    rst $08
    ld c, l
    sub $4d
    db $dd
    ld c, l
    and $4d
    db $ec
    ld c, l
    di
    ld c, l
    ld a, [HeaderComplementCheck]
    ld c, [hl]
    ld [$0e4e], sp
    ld c, [hl]
    ld d, $4e
    dec e
    ld c, [hl]
    inc h

jr_041_40c6:
    ld c, [hl]
    dec hl

jr_041_40c8:
    ld c, [hl]
    ld [hl-], a

jr_041_40ca:
    ld c, [hl]
    add hl, sp
    ld c, [hl]
    ld b, b
    ld c, [hl]
    ld c, b
    ld c, [hl]
    ld d, b
    ld c, [hl]
    ld e, b
    ld c, [hl]
    ld h, b
    ld c, [hl]
    ld h, a
    ld c, [hl]
    ld l, l
    ld c, [hl]
    ld [hl], l
    ld c, [hl]
    ld a, l
    ld c, [hl]
    add l
    ld c, [hl]
    adc l
    ld c, [hl]
    sub h
    ld c, [hl]
    sbc e
    ld c, [hl]
    and e
    ld c, [hl]
    xor e
    ld c, [hl]
    or e
    ld c, [hl]
    cp e
    ld c, [hl]
    jp $c94e


    ld c, [hl]
    rst $08
    ld c, [hl]
    push de
    ld c, [hl]
    call c, $e34e
    ld c, [hl]
    ld [$f24e], a
    ld c, [hl]
    ld hl, sp+$4e
    ld sp, hl
    ld c, [hl]
    db $fc
    ld c, [hl]
    dec c
    ld c, a
    jr nz, @+$51

    inc sp
    ld c, a
    ld b, d
    ld c, a
    ld e, b
    ld c, a
    ld l, d
    ld c, a
    add d
    ld c, a
    sub b
    ld c, a
    xor c
    ld c, a
    add $4f
    db $d3
    ld c, a
    ldh [rVBK], a
    and $4f
    ld [$044f], a
    ld d, b
    ld c, $50
    add hl, sp
    ld d, b
    ld b, a
    ld d, b
    ld e, b
    ld d, b
    ld l, a
    ld d, b
    ld a, l
    ld d, b
    sbc e
    ld d, b
    ret nz

    ld d, b
    call z, $e450
    ld d, b
    ei
    ld d, b
    ld a, [hl+]
    ld d, c
    ld c, c
    ld d, c
    add a
    ld d, c
    and e
    ld d, c
    or [hl]
    ld d, c
    push bc
    ld d, c
    rst $10
    ld d, c
    jp hl


    ld d, c
    ld b, $52
    inc d
    ld d, d
    ld [hl], $52
    ld d, c
    ld d, d
    ld l, d
    ld d, d
    ld a, e
    ld d, d
    xor l
    ld d, d
    call $e552
    ld d, d
    db $ed
    ld d, d
    ld bc, $1153
    ld d, e
    inc e
    ld d, e
    ld [hl], e
    ld d, e
    ld a, h
    ld d, e
    sub [hl]
    ld d, e
    sbc l
    ld d, e
    and h
    ld d, e
    and a
    ld d, e
    xor d
    ld d, e
    or a
    ld d, e
    push bc
    ld d, e
    call $da53
    ld d, e
    call c, $de53
    ld d, e
    ldh [rHDMA3], a
    ld [c], a
    ld d, e
    db $e4
    ld d, e
    and $53
    add sp, $53
    ld [$0e53], a
    ld d, h
    inc d
    ld d, h
    ld d, c
    ld d, h
    ld e, h
    ld d, h
    ld l, b
    ld d, h
    ld a, h
    ld d, h
    sub c
    ld d, h
    and c
    ld d, h
    rst $38
    ld d, h
    jr nz, @+$57

    inc a
    ld d, l
    ld e, e
    ld d, l
    sbc b
    ld d, l
    call nc, $f055
    ld d, l
    ld sp, hl
    ld d, l
    ld de, $3256
    ld d, [hl]
    scf
    ld d, [hl]
    ld d, e
    ld d, [hl]
    ld [hl], l
    ld d, [hl]
    sbc l
    ld d, [hl]
    xor b
    ld d, [hl]
    xor b
    ld d, [hl]
    xor b
    ld d, [hl]
    db $eb
    ld d, [hl]
    ld d, $57
    inc sp
    ld d, a
    ld a, $57
    ld c, b
    ld d, a
    ld d, d
    ld d, a
    ld e, h
    ld d, a
    ld h, [hl]
    ld d, a
    ld l, l
    ld d, a
    db $76
    ld d, a
    add b
    ld d, a
    add a
    ld d, a
    adc h
    ld d, a
    sub h
    ld d, a
    sbc a
    ld d, a
    xor e
    ld d, a
    or [hl]
    ld d, a
    ret nz

    ld d, a
    call z, $cd57
    ld d, a
    ld bc, $0658
    ld e, b
    dec bc
    ld e, b
    db $10
    ld e, b
    dec d
    ld e, b
    ld a, [de]
    ld e, b
    add hl, hl
    ld e, b
    ld l, $58
    ld [hl-], a
    ld e, b
    ld [hl], $58
    ld a, [hl-]
    ld e, b
    ccf
    ld e, b
    ld b, h
    ld e, b
    ld c, c
    ld e, b
    ld c, [hl]
    ld e, b
    ld d, d
    ld e, b
    ld d, a
    ld e, b
    ld e, h
    ld e, b
    ld h, b
    ld e, b
    ld h, l
    ld e, b
    ld l, d
    ld e, b
    ld l, a
    ld e, b
    ld [hl], e
    ld e, b
    ld a, b
    ld e, b
    ld a, l
    ld e, b
    add d
    ld e, b
    add a
    ld e, b
    adc h
    ld e, b
    sub c
    ld e, b
    sub [hl]
    ld e, b
    sbc e
    ld e, b
    and b
    ld e, b
    and l
    ld e, b
    xor d
    ld e, b
    xor a
    ld e, b
    or h
    ld e, b
    cp c
    ld e, b
    cp l
    ld e, b
    jp nz, $c758

    ld e, b
    bit 3, b
    ret nc

    ld e, b
    push de
    ld e, b
    jp c, $df58

    ld e, b
    db $e4
    ld e, b
    jp hl


    ld e, b
    xor $58
    di
    ld e, b
    ld hl, sp+$58
    db $fd
    ld e, b
    ld [bc], a
    ld e, c
    rlca
    ld e, c
    inc c
    ld e, c
    ld de, $1659
    ld e, c
    ld a, [de]
    ld e, c
    rra
    ld e, c
    inc h
    ld e, c
    add hl, hl
    ld e, c
    dec l
    ld e, c
    ld [hl-], a
    ld e, c
    ld [hl], $59
    dec sp
    ld e, c
    ld b, b
    ld e, c
    ld b, l
    ld e, c
    ld c, d
    ld e, c
    ld c, a
    ld e, c
    ld d, h
    ld e, c
    ld e, c
    ld e, c
    ld e, [hl]
    ld e, c
    ld h, d
    ld e, c
    ld h, a
    ld e, c
    ld l, h
    ld e, c
    ld [hl], b
    ld e, c
    ld [hl], l
    ld e, c
    ld a, d
    ld e, c
    ld a, [hl]
    ld e, c
    add d
    ld e, c
    add a
    ld e, c
    adc h
    ld e, c
    sub c
    ld e, c
    sub [hl]
    ld e, c
    sbc d
    ld e, c
    sbc a
    ld e, c
    and h
    ld e, c
    xor c
    ld e, c
    xor [hl]
    ld e, c
    or e
    ld e, c
    cp b
    ld e, c
    cp l
    ld e, c
    jp nz, $c759

    ld e, c
    call z, $d059
    ld e, c
    push de
    ld e, c
    jp c, $df59

    ld e, c
    db $e4
    ld e, c
    jp hl


    ld e, c
    xor $59
    di
    ld e, c
    ld hl, sp+$59
    db $fd
    ld e, c
    ld [bc], a
    ld e, d
    rlca
    ld e, d
    inc c
    ld e, d
    ld de, $165a
    ld e, d
    ld a, [de]
    ld e, d
    rra
    ld e, d
    inc hl
    ld e, d
    daa
    ld e, d
    dec hl
    ld e, d
    cpl
    ld e, d
    inc sp
    ld e, d
    jr c, jr_041_4327

    dec a
    ld e, d
    ld b, d
    ld e, d
    ld b, a
    ld e, d
    ld c, h
    ld e, d
    ld d, c
    ld e, d
    ld d, l
    ld e, d
    ld e, d
    ld e, d
    ld e, a
    ld e, d
    ld h, e
    ld e, d
    ld l, b
    ld e, d
    ld l, l
    ld e, d
    ld [hl], c
    ld e, d
    db $76
    ld e, d
    ld a, e
    ld e, d
    ld a, a
    ld e, d
    add h
    ld e, d
    adc b
    ld e, d
    adc h
    ld e, d
    sub b
    ld e, d
    sub l
    ld e, d
    sbc d
    ld e, d
    sbc a
    ld e, d
    and e
    ld e, d
    and a
    ld e, d
    xor h
    ld e, d
    or c
    ld e, d
    or [hl]
    ld e, d
    cp e
    ld e, d
    ret nz

    ld e, d
    push bc
    ld e, d
    jp z, $cf5a

    ld e, d
    call nc, $d95a
    ld e, d
    sbc $5a
    db $e3
    ld e, d
    add sp, $5a
    db $ed
    ld e, d
    ld a, [c]
    ld e, d
    rst $30
    ld e, d
    ei
    ld e, d
    nop
    ld e, e
    dec b
    ld e, e
    ld a, [bc]
    ld e, e
    inc c
    ld e, e

jr_041_4327:
    ld c, $5b
    db $10
    ld e, e
    ld [de], a
    ld e, e
    inc d
    ld e, e
    ld d, $5b
    jr jr_041_438e

    ld a, [de]
    ld e, e
    inc e
    ld e, e
    ld e, $5b
    rra
    ld e, e
    add hl, hl
    ld e, e
    inc sp
    ld e, e
    dec a
    ld e, e
    ld b, a
    ld e, e
    ld c, [hl]
    ld e, e
    ld e, b
    ld e, e
    ld e, a
    ld e, e
    ld l, b
    ld e, e
    ld l, [hl]
    ld e, e
    ld [hl], l
    ld e, e
    ld a, a
    ld e, e
    adc c
    ld e, e
    sub e
    ld e, e
    sbc e
    ld e, e
    and h
    ld e, e
    xor [hl]
    ld e, e
    or l
    ld e, e
    cp [hl]
    ld e, e
    ret z

    ld e, e
    jp nc, $dc5b

    ld e, e
    and $5b
    rst $28
    ld e, e
    or $5b
    nop
    ld e, h
    ld a, [bc]
    ld e, h
    inc d
    ld e, h
    dec e
    ld e, h
    inc h
    ld e, h
    dec l
    ld e, h
    scf
    ld e, h
    ccf
    ld e, h
    ld c, c
    ld e, h
    ld d, e
    ld e, h
    ld e, e
    ld e, h
    ld h, l
    ld e, h
    ld l, a
    ld e, h
    ld a, c
    ld e, h
    add e
    ld e, h
    adc l
    ld e, h
    sub h
    ld e, h
    sbc e

jr_041_438e:
    ld e, h
    and l
    ld e, h
    xor a
    ld e, h
    cp c
    ld e, h
    jp $cb5c


    ld e, h
    jp nc, $dc5c

    ld e, h
    db $e3
    ld e, h
    db $ed
    ld e, h
    or $5c
    nop
    ld e, l
    add hl, bc
    ld e, l
    ld [de], a
    ld e, l
    dec de
    ld e, l
    inc h
    ld e, l
    ld l, $5d
    ld [hl], $5d
    dec sp
    ld e, l
    ld b, l
    ld e, l
    ld c, [hl]
    ld e, l
    ld d, [hl]
    ld e, l
    ld e, a
    ld e, l
    ld h, a
    ld e, l
    ld [hl], c
    ld e, l
    ld a, c
    ld e, l
    add d
    ld e, l
    adc c
    ld e, l
    sub b
    ld e, l
    sub [hl]
    ld e, l
    sbc l
    ld e, l
    and [hl]
    ld e, l
    xor a
    ld e, l
    cp b
    ld e, l
    jp nz, $cb5d

    ld e, l
    push de
    ld e, l
    call c, $e55d
    ld e, l
    xor $5d
    or $5d
    rst $38
    ld e, l
    add hl, bc
    ld e, [hl]
    inc de
    ld e, [hl]
    dec de
    ld e, [hl]
    inc hl
    ld e, [hl]
    inc l
    ld e, [hl]
    ld [hl], $5e
    ccf
    ld e, [hl]
    ld c, b
    ld e, [hl]
    ld d, c
    ld e, [hl]
    ld e, d
    ld e, [hl]
    ld h, e
    ld e, [hl]
    ld l, l
    ld e, [hl]
    ld [hl], l
    ld e, [hl]
    ld a, a
    ld e, [hl]
    adc c
    ld e, [hl]
    sub d
    ld e, [hl]
    sbc c
    ld e, [hl]
    and e
    ld e, [hl]
    xor e
    ld e, [hl]
    or h
    ld e, [hl]
    cp h
    ld e, [hl]
    call nz, $cd5e
    ld e, [hl]
    sub $5e
    sbc $5e
    rst $20
    ld e, [hl]
    rst $28
    ld e, [hl]
    ld sp, hl
    ld e, [hl]
    ld [bc], a
    ld e, a
    inc c
    ld e, a
    ld d, $5f
    ld e, $5f
    jr z, jr_041_4482

    ld l, $5f
    ld [hl], $5f
    ld a, $5f
    ld b, a
    ld e, a
    ld d, c
    ld e, a
    ld e, e
    ld e, a
    ld h, d
    ld e, a
    ld l, h
    ld e, a
    ld [hl], d
    ld e, a
    ld a, e
    ld e, a
    add l
    ld e, a
    adc [hl]
    ld e, a
    sbc b
    ld e, a
    and b
    ld e, a
    and l
    ld e, a
    xor [hl]
    ld e, a
    or [hl]
    ld e, a
    cp a
    ld e, a
    rst $00
    ld e, a
    rst $08
    ld e, a
    reti


    ld e, a
    db $e3
    ld e, a
    db $ed
    ld e, a
    push af
    ld e, a
    rst $38
    ld e, a
    ld b, $60
    rrca
    ld h, b
    inc de
    ld h, b
    jr jr_041_44bd

    ld [hl+], a
    ld h, b
    inc l
    ld h, b
    inc [hl]
    ld h, b
    dec sp
    ld h, b
    ld b, l
    ld h, b
    ld c, [hl]
    ld h, b
    ld e, b
    ld h, b
    ld h, d
    ld h, b
    ld l, d
    ld h, b
    ld [hl], c
    ld h, b
    ld a, b
    ld h, b
    add c
    ld h, b
    adc d
    ld h, b
    sub e
    ld h, b
    sbc c
    ld h, b
    and d
    ld h, b
    xor e
    ld h, b
    or d
    ld h, b
    or a

jr_041_4482:
    ld h, b
    cp [hl]
    ld h, b
    rst $00
    ld h, b
    pop de
    ld h, b
    db $db
    ld h, b
    ld [c], a
    ld h, b
    db $ec
    ld h, b
    or $60
    nop
    ld h, c
    add hl, bc
    ld h, c
    ld de, $1961
    ld h, c
    ld [hl+], a
    ld h, c
    dec hl
    ld h, c
    dec [hl]
    ld h, c
    ld a, $61
    ld b, h
    ld h, c
    ld c, l
    ld h, c
    ld d, a
    ld h, c
    ld h, c
    ld h, c
    ld h, a
    ld h, c
    ld l, a
    ld h, c
    ld a, c
    ld h, c
    add b
    ld h, c
    adc c
    ld h, c
    sub e
    ld h, c
    sbc h
    ld h, c
    and h
    ld h, c
    xor d
    ld h, c
    or d
    ld h, c

jr_041_44bd:
    cp c
    ld h, c
    cp a
    ld h, c
    rst $00
    ld h, c
    call $d661
    ld h, c
    rst $18
    ld h, c
    jp hl


    ld h, c
    di
    ld h, c
    db $fd
    ld h, c
    inc b
    ld h, d
    ld a, [bc]
    ld h, d
    ld [de], a
    ld h, d
    rla
    ld h, d
    rra
    ld h, d
    ld h, $62
    jr nc, jr_041_453f

    ld a, [hl-]
    ld h, d
    ld b, b
    ld h, d
    ld c, d
    ld h, d
    ld d, h
    ld h, d
    ld e, [hl]
    ld h, d
    ld l, b
    ld h, d
    ld l, a
    ld h, d
    ld [hl], l
    ld h, d
    ld a, e
    ld h, d
    add c
    ld h, d
    add a
    ld h, d
    add a
    ld h, d
    add a
    ld h, d
    add a
    ld h, d
    add a
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc b
    ld h, d
    adc [hl]
    ld h, d
    sub h
    ld h, d
    sbc [hl]
    ld h, d

jr_041_453f:
    xor b
    ld h, d
    or b
    ld h, d
    cp c
    ld h, d
    jp nz, $c762

    ld h, d
    call z, $d562
    ld h, d
    sbc $62
    add sp, $62
    ld a, [c]
    ld h, d
    ld a, [$0462]
    ld h, e
    dec c
    ld h, e
    ld [de], a
    ld h, e
    ld d, $63
    rra
    ld h, e
    inc h
    ld h, e
    dec hl
    ld h, e
    dec [hl]
    ld h, e
    dec sp
    ld h, e
    ld b, h
    ld h, e
    ld c, [hl]
    ld h, e
    ld d, a
    ld h, e
    ld h, b
    ld h, e
    ld l, c
    ld h, e
    ld [hl], e
    ld h, e
    ld [hl], a
    ld h, e
    ld a, a
    ld h, e
    add l
    ld h, e
    adc [hl]
    ld h, e
    sub e
    ld h, e
    sbc e
    ld h, e
    and c
    ld h, e
    xor c
    ld h, e
    or c
    ld h, e
    cp d
    ld h, e
    call nz, $ce63
    ld h, e
    push de
    ld h, e
    rst $18
    ld h, e
    rst $20
    ld h, e
    db $ec
    ld h, e
    push af
    ld h, e
    db $fd
    ld h, e
    inc b
    ld h, h
    ld c, $64
    dec d
    ld h, h
    inc e
    ld h, h
    dec h
    ld h, h
    ld l, $64
    ld [hl], $64
    ld a, $64
    ld b, a
    ld h, h
    ld d, c
    ld h, h
    ld e, d
    ld h, h
    ld h, c
    ld h, h
    ld l, b
    ld h, h
    ld [hl], d
    ld h, h
    ld a, d
    ld h, h
    add e
    ld h, h
    adc h
    ld h, h
    sub l
    ld h, h
    sbc a
    ld h, h
    xor b
    ld h, h
    or c
    ld h, h
    cp c
    ld h, h
    jp $cd64


    ld h, h
    rst $10
    ld h, h
    ldh [$64], a
    jp hl


    ld h, h
    di
    ld h, h
    db $fc
    ld h, h
    dec b
    ld h, l
    ld c, $65
    jr @+$67

    ld hl, $2a65
    ld h, l
    inc sp
    ld h, l
    inc a
    ld h, l
    ld b, l
    ld h, l
    ld c, [hl]
    ld h, l
    ld d, h
    ld h, l
    ld e, [hl]
    ld h, l
    ld h, a
    ld h, l
    ld [hl], c
    ld h, l
    ld a, e
    ld h, l
    add d
    ld h, l
    adc h
    ld h, l
    sub [hl]
    ld h, l
    sbc [hl]
    ld h, l
    and a
    ld h, l
    or c
    ld h, l
    cp e
    ld h, l
    push bc
    ld h, l
    call z, $d565
    ld h, l
    sbc $65
    add sp, $65
    ldh a, [$65]
    ld a, [$0465]
    ld h, [hl]
    ld c, $66
    rla
    ld h, [hl]
    jr nz, jr_041_4677

    add hl, hl
    ld h, [hl]
    inc sp
    ld h, [hl]
    dec a
    ld h, [hl]
    ld b, a
    ld h, [hl]
    ld c, l
    ld h, [hl]
    ld d, d
    ld h, [hl]
    ld e, h
    ld h, [hl]
    ld h, [hl]
    ld h, [hl]
    ld l, [hl]
    ld h, [hl]
    ld a, b
    ld h, [hl]
    add c
    ld h, [hl]
    adc d
    ld h, [hl]
    sub e
    ld h, [hl]
    sbc l
    ld h, [hl]
    and a
    ld h, [hl]
    or b
    ld h, [hl]
    cp c
    ld h, [hl]
    pop bc
    ld h, [hl]
    ret z

    ld h, [hl]
    ret nc

    ld h, [hl]
    ret c

    ld h, [hl]
    ldh [$66], a
    and $66
    ldh a, [$66]
    ld sp, hl
    ld h, [hl]
    inc bc
    ld h, a
    dec c
    ld h, a
    rla
    ld h, a
    ld hl, $2767
    ld h, a
    jr nc, jr_041_46b6

    add hl, sp
    ld h, a
    ld b, e
    ld h, a
    ld c, c
    ld h, a
    ld d, c
    ld h, a
    ld e, c
    ld h, a
    ld h, c
    ld h, a
    ld l, b
    ld h, a
    ld [hl], d
    ld h, a
    ld a, h
    ld h, a
    add l
    ld h, a
    adc h
    ld h, a
    sub l
    ld h, a
    sbc a
    ld h, a
    and e
    ld h, a
    xor b
    ld h, a
    or b
    ld h, a
    cp c
    ld h, a
    jp $ca67


    ld h, a
    ret nc

    ld h, a

jr_041_4677:
    push de
    ld h, a
    sbc $67
    rst $20
    ld h, a
    db $eb
    ld h, a
    push af
    ld h, a
    rst $38
    ld h, a
    rlca
    ld l, b
    ld de, $1b68
    ld l, b
    inc h
    ld l, b
    jr z, jr_041_46f5

    dec l
    ld l, b
    scf
    ld l, b
    ld b, b
    ld l, b
    ld b, a
    ld l, b
    ld d, c
    ld l, b
    ld e, e
    ld l, b
    ld h, d
    ld l, b
    ld h, a
    ld l, b
    ld [hl], c
    ld l, b
    ld a, e
    ld l, b
    add h
    ld l, b
    adc e
    ld l, b
    sub h
    ld l, b
    sbc l
    ld l, b
    and [hl]
    ld l, b
    xor [hl]
    ld l, b
    or l
    ld l, b
    cp a
    ld l, b
    ret


    ld l, b
    db $d3
    ld l, b
    db $dd

jr_041_46b6:
    ld l, b
    push hl
    ld l, b
    db $ed
    ld l, b
    or $68
    cp $68
    rlca
    ld l, c
    ld de, $1a69
    ld l, c
    ld [hl+], a
    ld l, c
    ld a, [hl+]
    ld l, c
    inc [hl]
    ld l, c
    ld a, [hl-]
    ld l, c
    ld b, h
    ld l, c
    ld c, [hl]
    ld l, c
    ld e, b
    ld l, c
    ld h, d
    ld l, c
    ld l, e
    ld l, c
    ld [hl], l
    ld l, c
    ld a, l
    ld l, c
    add [hl]
    ld l, c
    adc a
    ld l, c
    sbc c
    ld l, c
    and c
    ld l, c
    xor d
    ld l, c
    or e
    ld l, c
    cp l
    ld l, c
    rst $00
    ld l, c
    pop de
    ld l, c
    db $db
    ld l, c
    ldh [rBCPD], a
    db $e4
    ld l, c
    db $ec
    ld l, c

jr_041_46f5:
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    pop af
    ld l, c
    ld a, [c]
    ld l, c
    push af
    ld l, c
    ld hl, sp+$69
    ei
    ld l, c
    cp $69
    ld bc, $046a
    ld l, d
    rlca
    ld l, d
    ld a, [bc]
    ld l, d
    dec c
    ld l, d
    db $10
    ld l, d
    inc de
    ld l, d
    ld d, $6a
    add hl, de
    ld l, d
    inc e
    ld l, d
    rra
    ld l, d
    ld [hl+], a
    ld l, d
    dec h
    ld l, d
    jr z, jr_041_47c9

    dec hl
    ld l, d
    ld l, $6a
    ld sp, $346a
    ld l, d
    scf
    ld l, d
    ld a, [hl-]
    ld l, d
    dec a
    ld l, d
    ld b, b
    ld l, d
    ld b, e
    ld l, d
    ld b, [hl]
    ld l, d
    ld c, c
    ld l, d
    ld c, h
    ld l, d
    ld c, a
    ld l, d
    ld d, d
    ld l, d
    ld d, l
    ld l, d
    ld e, b
    ld l, d
    ld e, e
    ld l, d
    ld e, [hl]
    ld l, d
    ld h, c
    ld l, d
    ld h, h
    ld l, d
    ld h, a
    ld l, d
    ld l, d
    ld l, d
    ld l, l
    ld l, d
    ld [hl], b
    ld l, d
    ld [hl], e
    ld l, d
    db $76
    ld l, d
    ld a, c
    ld l, d
    ld a, h
    ld l, d
    ld a, a
    ld l, d
    add d
    ld l, d
    add l
    ld l, d
    adc b
    ld l, d
    adc e
    ld l, d
    adc [hl]
    ld l, d
    sub c
    ld l, d
    sub h
    ld l, d
    sub a
    ld l, d
    sbc d
    ld l, d
    sbc l
    ld l, d
    and b
    ld l, d
    and e
    ld l, d
    and [hl]
    ld l, d
    xor c
    ld l, d
    xor h
    ld l, d
    xor a
    ld l, d
    or d
    ld l, d
    or l
    ld l, d
    cp b
    ld l, d
    cp e
    ld l, d
    cp [hl]
    ld l, d
    pop bc
    ld l, d
    call nz, $c76a
    ld l, d

jr_041_47c9:
    jp z, $cd6a

    ld l, d
    ret nc

    ld l, d
    db $d3
    ld l, d
    sub $6a
    reti


    ld l, d
    call c, $df6a
    ld l, d
    ld [c], a
    ld l, d
    push hl
    ld l, d
    add sp, $6a
    db $eb
    ld l, d
    xor $6a
    pop af
    ld l, d
    db $f4
    ld l, d
    rst $30
    ld l, d
    ld a, [$fd6a]
    ld l, d
    nop
    ld l, e
    inc bc
    ld l, e
    ld b, $6b
    add hl, bc
    ld l, e
    inc c
    ld l, e
    rrca
    ld l, e
    ld [de], a
    ld l, e
    dec d
    ld l, e
    jr jr_041_486a

    dec de
    ld l, e
    ld e, $6b
    ld hl, $246b
    ld l, e
    daa
    ld l, e
    ld a, [hl+]
    ld l, e
    dec l
    ld l, e
    jr nc, @+$6d

    inc sp
    ld l, e
    ld [hl], $6b
    add hl, sp
    ld l, e
    inc a
    ld l, e
    ccf
    ld l, e
    ld b, d
    ld l, e
    ld b, l
    ld l, e
    ld c, b
    ld l, e
    ld c, e
    ld l, e
    ld c, [hl]
    ld l, e
    ld d, c
    ld l, e
    ld d, h
    ld l, e
    ld d, a
    ld l, e
    ld e, d
    ld l, e
    ld e, l
    ld l, e
    ld h, b
    ld l, e
    ld h, e
    ld l, e
    ld h, [hl]
    ld l, e
    ld l, c
    ld l, e
    ld l, h
    ld l, e
    ld l, a
    ld l, e
    ld [hl], d
    ld l, e
    ld [hl], l
    ld l, e
    ld a, b
    ld l, e
    ld a, e
    ld l, e
    ld a, [hl]
    ld l, e
    add c
    ld l, e
    add h
    ld l, e
    add a
    ld l, e
    adc d
    ld l, e
    adc l
    ld l, e
    sub b
    ld l, e
    sub e
    ld l, e
    sub [hl]
    ld l, e
    sbc c
    ld l, e
    sbc h
    ld l, e
    sbc a
    ld l, e
    and d
    ld l, e
    and l
    ld l, e
    xor b
    ld l, e
    xor e
    ld l, e
    xor [hl]
    ld l, e
    or c
    ld l, e
    or h
    ld l, e
    or a
    ld l, e
    cp d

jr_041_486a:
    ld l, e
    cp l
    ld l, e
    ret nz

    ld l, e
    jp $c66b


    ld l, e
    ret


    ld l, e
    call z, $cf6b
    ld l, e
    jp nc, $d56b

    ld l, e
    ret c

    ld l, e
    db $db
    ld l, e
    sbc $6b
    pop hl
    ld l, e
    db $e4
    ld l, e
    rst $20
    ld l, e
    ld [$ed6b], a
    ld l, e
    ldh a, [rOCPD]
    di
    ld l, e
    or $6b
    ld sp, hl
    ld l, e
    db $fc
    ld l, e
    rst $38
    ld l, e
    ld [bc], a
    ld l, h
    dec b
    ld l, h
    ld [$0b6c], sp
    ld l, h
    ld c, $6c
    ld de, $146c
    ld l, h
    rla
    ld l, h
    ld a, [de]
    ld l, h
    dec e
    ld l, h
    jr nz, jr_041_491b

    inc hl
    ld l, h
    ld h, $6c
    add hl, hl
    ld l, h
    inc l
    ld l, h
    cpl
    ld l, h
    ld [hl-], a
    ld l, h
    dec [hl]
    ld l, h
    jr c, jr_041_492b

    dec sp
    ld l, h
    ld a, $6c
    ld b, c
    ld l, h
    ld b, h
    ld l, h
    ld b, a
    ld l, h
    ld c, d
    ld l, h
    ld c, l
    ld l, h
    ld d, b
    ld l, h
    ld d, e
    ld l, h
    ld d, [hl]
    ld l, h
    ld e, c
    ld l, h
    ld e, h
    ld l, h
    ld e, a
    ld l, h
    ld h, d
    ld l, h
    ld h, l
    ld l, h
    ld l, b
    ld l, h
    ld l, e
    ld l, h
    ld l, [hl]
    ld l, h
    ld [hl], c
    ld l, h
    ld [hl], h
    ld l, h
    ld [hl], a
    ld l, h
    ld a, b
    ld l, h
    ld a, l
    ld l, h
    add a
    ld l, h
    sub c
    ld l, h
    sbc d
    ld l, h
    and c
    ld l, h
    xor d
    ld l, h
    or e
    ld l, h
    cp h
    ld l, h
    call nz, $cb6c
    ld l, h
    push de
    ld l, h
    rst $18
    ld l, h
    jp hl


    ld l, h
    di
    ld l, h
    ei
    ld l, h
    inc bc
    ld l, l
    dec bc
    ld l, l
    inc de
    ld l, l
    dec e
    ld l, l
    ld h, $6d
    ld a, [hl+]
    ld l, l
    ld [hl-], a
    ld l, l
    ld a, [hl-]
    ld l, l
    ld b, h
    ld l, l

jr_041_491b:
    ld c, [hl]
    ld l, l
    ld e, b
    ld l, l
    ld h, d
    ld l, l
    ld l, h
    ld l, l
    ld [hl], l
    ld l, l
    ld a, a
    ld l, l
    add a
    ld l, l
    sub b
    ld l, l

jr_041_492b:
    sbc c
    ld l, l
    and e
    ld l, l
    xor e
    ld l, l
    or h
    ld l, l
    cp [hl]
    ld l, l
    ret z

    ld l, l
    jp nc, $dc6d

    ld l, l
    and $6d
    xor $6d
    rst $30
    ld l, l
    ld hl, sp+$6d
    dec d
    ld l, [hl]
    ld [hl-], a
    ld l, [hl]
    ld c, a
    ld l, [hl]
    ld h, a
    ld l, [hl]
    add h
    ld l, [hl]
    sub a
    ld l, [hl]
    and l
    ld l, [hl]
    or l
    ld l, [hl]
    add $6e
    push de
    ld l, [hl]
    and $6e
    or $6e
    inc c
    ld l, a
    ld [hl+], a
    ld l, a
    ld a, $6f
    ld e, e
    ld l, a
    ld [hl], e
    ld l, a
    adc a
    ld l, a
    adc a
    ld l, a
    adc a
    ld l, a
    adc a
    ld l, a
    adc a
    ld l, a
    sbc a
    ld l, a
    jp nz, $dd6f

    ld l, a
    rst $30
    ld l, a
    rrca
    ld [hl], b
    ld l, $70
    ld c, l
    ld [hl], b
    ld l, [hl]
    ld [hl], b
    ld l, [hl]
    ld [hl], b
    ld l, [hl]
    ld [hl], b
    ld l, [hl]
    ld [hl], b
    ld l, [hl]
    ld [hl], b
    ld l, [hl]
    ld [hl], b
    adc e
    ld [hl], b
    xor l
    ld [hl], b
    call $e470
    ld [hl], b
    db $f4
    ld [hl], b
    ld d, $71
    jr c, jr_041_4a08

    ld e, c
    ld [hl], c
    ld h, d
    ld [hl], c
    ld l, c
    ld [hl], c
    ld [hl], e
    ld [hl], c
    ld a, l
    ld [hl], c
    add d
    ld [hl], c
    adc e
    ld [hl], c
    sub b
    ld [hl], c
    sub a
    ld [hl], c
    and b
    ld [hl], c
    xor d
    ld [hl], c
    or c
    ld [hl], c
    or [hl]
    ld [hl], c
    cp a
    ld [hl], c
    ret z

    ld [hl], c
    adc $71
    rst $10
    ld [hl], c
    db $dd
    ld [hl], c
    push hl
    ld [hl], c
    db $ec
    ld [hl], c
    or $71
    rst $38
    ld [hl], c
    rlca
    ld [hl], d
    db $10
    ld [hl], d
    add hl, de
    ld [hl], d
    dec e
    ld [hl], d
    inc h
    ld [hl], d
    add hl, hl
    ld [hl], d
    ld b, a
    ld [hl], d
    ld h, b
    ld [hl], d
    adc e
    ld [hl], d
    and c
    ld [hl], d
    push hl
    ld [hl], d
    rst $30
    ld [hl], d
    ld b, $73
    dec e
    ld [hl], e
    dec [hl]
    ld [hl], e
    ld b, b
    ld [hl], e
    ld c, c
    ld [hl], e
    ld c, a
    ld [hl], e
    ld e, [hl]
    ld [hl], e
    ld e, [hl]
    ld [hl], e
    ld a, b
    ld [hl], e
    xor b
    ld [hl], e
    ld hl, sp+$73
    ld e, h
    ld [hl], h
    ld a, b
    ld [hl], h
    sub [hl]
    ld [hl], h
    or c
    ld [hl], h
    call c, $f574
    ld [hl], h
    ld [$2875], sp
    ld [hl], l
    ld b, c
    ld [hl], l
    ld c, l
    ld [hl], l
    ld e, h
    ld [hl], l
    ld l, b

jr_041_4a08:
    ld [hl], l
    adc b
    ld [hl], l
    pop af
    ld [hl], l
    ld e, d
    db $76
    ld a, e
    db $76
    adc a
    db $76
    or e
    db $76
    db $cd, $76, $01
    ld [hl], a
    ld bc, $3977
    ld [hl], a
    ld c, [hl]
    ld [hl], a
    ld l, e
    ld [hl], a
    add c
    ld [hl], a
    sbc b
    ld [hl], a
    xor d
    ld [hl], a
    pop de
    ld [hl], a
    push hl
    ld [hl], a
    rst $30
    ld [hl], a
    dec b
    ld a, b
    jr nz, jr_041_4aa9

    ld l, $78
    ld d, c
    ld a, b
    ld e, a
    ld a, b
    ld l, h
    ld a, b
    add a
    ld a, b
    and d
    ld a, b
    cp d
    ld a, b
    jp nc, $ea78

    ld a, b
    ld [bc], a
    ld a, c
    jr jr_041_4ac0

    ld b, e
    ld a, c
    sub h
    ld a, c
    or e
    ld a, c
    and $79
    ld [bc], a
    ld a, d
    ld h, $7a
    ld b, e
    ld a, d
    ld e, [hl]
    ld a, d
    ld l, a
    ld a, d
    add b
    ld a, d
    sbc c
    ld a, d
    adc $7a
    cp $7a
    dec [hl]
    ld a, e
    ld l, b
    ld a, e
    sub h
    ld a, e
    add $7b
    pop af
    ld a, e
    inc bc
    ld a, h
    daa
    ld a, h
    ld e, l
    ld a, h
    ld l, h
    ld a, h
    sub d
    ld a, h
    and h
    ld a, h
    jp $e37c


    ld a, h
    db $fd
    ld a, h
    dec bc
    ld a, l
    ld hl, $357d
    ld a, l
    ld b, a
    ld a, l
    ld d, a
    ld a, l
    ld l, h
    ld a, l
    ld a, d
    ld a, l
    sbc c
    ld a, l
    rst $00
    ld a, l
    push de
    ld a, l
    and $7d

Call_041_4a93:
    ld de, $4007
    call Call_000_05b6
    ret


    ld de, $4007
    call Call_000_05f6
    ret


    call Call_041_4a93
    call Call_000_0609
    ret


    sub [hl]

jr_041_4aa9:
    ld h, d
    daa
    jr z, jr_041_4ad2

    jr c, jr_041_4ad9

    ld h, d
    jr nc, jr_041_4ae4

    daa
    jr z, @-$0d

    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld [hl], $28
    cpl
    jr z, jr_041_4ae4

    scf
    ld h, d

jr_041_4ac0:
    ld h, d
    ld h, d
    sub a
    pop af
    ld h, d
    ld bc, $2aa3
    ld [hl-], a
    scf
    ld [hl-], a
    ld h, d
    inc sp
    dec [hl]
    ld [hl-], a
    ld a, [hl+]
    dec [hl]
    inc h

jr_041_4ad2:
    jr nc, jr_041_4b36

    ld h, d
    ld [bc], a
    and e
    jr nc, jr_041_4b0b

jr_041_4ad9:
    ld sp, $3736
    jr z, jr_041_4b13

    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, d

jr_041_4ae4:
    ld h, d
    inc bc
    and e
    ld a, [hl+]
    inc h
    jr nc, jr_041_4b13

    ld h, d
    jr z, jr_041_4b15

    inc l
    scf
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    inc b
    and e
    ld [hl], $32
    jr c, jr_041_4b2c

    daa
    ld h, d
    scf
    jr z, jr_041_4b36

    scf
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    dec b
    and e
    dec h
    inc h
    scf
    scf

jr_041_4b0b:
    cpl
    jr z, jr_041_4b70

    jr z, jr_041_4b37

    inc l
    scf
    ld h, d

jr_041_4b13:
    ld h, d
    ld h, d

jr_041_4b15:
    ld h, d
    sbc h
    ld h, d
    ld h, d
    dec [hl]
    jr z, jr_041_4b53

    jr c, jr_041_4b53

    ld sp, $6262
    sbc h
    ld h, d
    ld h, d
    ldh a, [$62]
    ld h, d
    sbc h
    ld h, d
    jr z, jr_041_4b52

    inc l

jr_041_4b2c:
    scf
    ld h, d
    sbc h
    pop af
    pop af
    jr nc, jr_041_4b57

    inc sp
    scf
    inc a

jr_041_4b36:
    inc sp

jr_041_4b37:
    jr z, @-$0d

    add hl, hl
    cpl
    ld [hl-], a
    ld [hl-], a
    dec [hl]
    ld h, d
    ld h, d
    pop af
    inc h
    cpl
    cpl
    inc a
    ld h, d
    ld h, d
    ld h, d
    pop af
    jr nc, jr_041_4b7d

    ld sp, $3736
    dec [hl]
    ld bc, $30f1

jr_041_4b52:
    ld [hl-], a

jr_041_4b53:
    ld sp, $3736
    dec [hl]

jr_041_4b57:
    ld [bc], a
    pop af
    jr nc, jr_041_4b8d

    ld sp, $3736
    dec [hl]
    inc bc
    pop af
    ld h, d
    daa
    jr c, @+$32

    jr nc, jr_041_4ba3

    ld h, d
    pop af
    ld h, d
    daa
    jr z, jr_041_4b92

    jr c, @+$2c

    ld h, d

jr_041_4b70:
    ldh a, [$62]
    nop
    ld bc, $0302
    inc b
    dec b
    ld b, $07
    ld [$2409], sp

jr_041_4b7d:
    dec h
    ld h, $27
    jr z, jr_041_4bab

    ldh a, [$62]
    ld h, d
    sbc h
    ld h, d

jr_041_4b87:
    ld [hl], $32
    jr c, jr_041_4bbc

    daa
    ld h, d

jr_041_4b8d:
    sbc h
    pop af
    pop af
    ld h, d
    ld h, d

jr_041_4b92:
    dec h
    ld a, [hl+]
    jr nc, jr_041_4b87

    ld h, d
    ld h, d
    ld [hl], $28
    ldh a, [$9c]
    ld h, d
    ld a, [hl+]
    ld [hl-], a
    scf
    ld [hl-], a
    inc sp
    dec [hl]

jr_041_4ba3:
    ld a, [hl+]
    ld h, d
    sbc h
    pop af
    pop af
    pop af
    ld h, d
    inc sp

jr_041_4bab:
    dec [hl]
    ld a, [hl+]
    ld sp, $0132
    pop af
    ld h, d
    inc sp
    dec [hl]
    ld a, [hl+]
    ld sp, $0232
    pop af
    ld h, d
    inc sp
    dec [hl]

jr_041_4bbc:
    ld a, [hl+]
    ld sp, $0332
    ldh a, [$37]
    inc l
    scf
    cpl
    jr z, @+$64

    sbc l
    ld bc, $6262
    ld a, [hl+]
    inc h
    jr nc, jr_041_4bf7

    ld h, d
    ld h, d
    ld h, d
    dec h
    inc h
    scf
    scf
    cpl
    jr z, jr_041_4c3b

    jr z, jr_041_4c14

    scf
    daa
    jr z, jr_041_4c0f

    ld [hl-], a
    ld h, d
    ld h, d
    ld [hl], $37
    inc h
    add hl, hl
    add hl, hl
    ld h, d
    ld h, d
    ld h, d
    jr z, jr_041_4c15

    add hl, hl
    jr z, jr_041_4c15

    scf
    ld h, d
    ld h, d
    dec [hl]
    jr z, jr_041_4c2b

    jr c, jr_041_4c26

jr_041_4bf7:
    scf
    ld h, d
    daa
    jr z, @+$27

    jr c, jr_041_4c28

    ld h, d
    sbc l
    ld [bc], a
    ld [hl-], a
    dec h
    dec l
    scf
    jr z, jr_041_4c3d

    scf
    ld h, d
    ld sp, $6232
    jr nc, jr_041_4c40

    dec [hl]

jr_041_4c0f:
    jr z, jr_041_4c70

    ld e, a
    sbc h
    ld h, d

jr_041_4c14:
    dec h

jr_041_4c15:
    inc h
    scf
    scf
    cpl
    jr z, jr_041_4c7d

    sbc h
    pop af
    pop af
    jr z, @+$33

    jr z, @+$32

    inc a
    ld h, d
    ld h, d
    pop af

jr_041_4c26:
    jr nc, jr_041_4c5a

jr_041_4c28:
    ld sp, $3736

jr_041_4c2b:
    dec [hl]
    ld bc, $30f1
    ld [hl-], a
    ld sp, $3736
    dec [hl]
    ld bc, $30f1
    ld [hl-], a
    ld sp, $3736

jr_041_4c3b:
    dec [hl]
    ld [bc], a

jr_041_4c3d:
    pop af
    jr nc, @+$34

jr_041_4c40:
    ld sp, $3736
    dec [hl]
    ld [bc], a
    pop af
    jr nc, jr_041_4c7a

    ld sp, $3736
    dec [hl]
    inc bc
    pop af
    jr nc, jr_041_4c82

    ld sp, $3736
    dec [hl]
    inc bc
    pop af
    ld h, d
    daa
    jr c, jr_041_4c8a

jr_041_4c5a:
    jr nc, jr_041_4c98

    ld h, d

jr_041_4c5d:
    pop af
    ld sp, $3532
    jr nc, jr_041_4c87

    cpl
    ldh a, [rNR50]
    ld h, $35
    jr z, jr_041_4c8e

    scf
    jr z, jr_041_4c5d

    ld [hl], $37
    inc h

jr_041_4c70:
    ld a, [hl+]
    jr z, jr_041_4c9f

    daa

jr_041_4c74:
    ldh a, [rNR52]
    inc h
    ld [hl], $37
    cpl

jr_041_4c7a:
    jr z, @-$0e

    add hl, sp

jr_041_4c7d:
    inc l
    cpl
    cpl
    inc h
    ld a, [hl+]

jr_041_4c82:
    jr z, jr_041_4c74

    dec h
    inc h
    dec a

jr_041_4c87:
    inc h

jr_041_4c88:
    inc h
    dec [hl]

jr_041_4c8a:
    ldh a, [$37]
    dec [hl]
    add hl, sp

jr_041_4c8e:
    ld a, [hl+]
    inc h
    scf
    jr z, @-$0e

    add hl, hl
    inc h
    dec [hl]
    jr nc, jr_041_4c88

jr_041_4c98:
    ld [hl], $2b
    inc sp
    dec [hl]
    daa
    ldh a, [rNR51]

jr_041_4c9f:
    inc h
    scf
    scf
    cpl
    jr z, @+$03

    ldh a, [rNR51]
    inc h
    scf
    scf
    cpl
    jr z, jr_041_4caf

    ldh a, [$31]

jr_041_4caf:
    jr z, jr_041_4ce7

    scf
    ldh a, [$36]
    scf
    dec [hl]
    daa
    ld sp, $312a
    ldh a, [$3a]
    scf
    jr nc, jr_041_4ce7

    daa
    inc h
    cpl
    ldh a, [$f0]
    jr z, jr_041_4cf0

    ld h, $31
    ld [hl], $2f
    scf
    ldh a, [$33]
    dec [hl]
    daa
    inc sp
    dec [hl]
    ld sp, $f037
    ldh a, [rNR52]
    dec hl
    ld l, $36
    scf
    ld sp, $f027
    ld h, $38
    scf
    inc a
    ld a, [hl+]
    dec [hl]
    cpl
    ldh a, [$f0]
    cpl

jr_041_4ce7:
    inc l
    dec h
    dec [hl]
    inc h
    dec [hl]
    inc a
    ldh a, [$36]
    scf

jr_041_4cf0:
    inc h
    ld h, $2e
    ldh a, [$f0]
    ldh a, [$30]
    jr z, @+$29

    inc h
    cpl
    jr nc, jr_041_4d21

    ld sp, $f0f0
    inc l
    ld sp, $3a62
    jr z, @+$31

    cpl
    ldh a, [$30]
    daa
    inc a
    dec hl
    inc h
    ld sp, $f027
    ld [hl], $33
    ld [hl-], a
    ld sp, $2836
    dec [hl]
    ldh a, [$36]
    scf
    inc h
    dec h
    cpl
    jr z, jr_041_4d4e

    ldh a, [$36]

jr_041_4d21:
    scf
    inc h
    dec h
    cpl
    jr z, @+$37

    ldh a, [$36]
    ld h, $2b
    ld [hl-], a
    ld [hl-], a
    cpl
    ldh a, [rNR51]
    inc h
    dec [hl]
    ldh a, [$34]
    jr c, @+$2a

    jr z, @+$2a

    ld sp, $f0f0
    ldh a, [$f0]
    ld h, $2b
    jr nc, jr_041_4d66

    dec [hl]
    ld [hl-], a
    inc sp
    ldh a, [rNR52]
    dec hl
    jr nc, @+$27

    dec [hl]
    ld h, d
    ld a, [hl+]
    ldh a, [rNR52]

jr_041_4d4e:
    dec hl
    jr nc, jr_041_4d76

    dec [hl]
    ld h, d
    add hl, hl
    ldh a, [rNR52]
    dec hl
    jr nc, jr_041_4d7e

    dec [hl]
    ld h, d
    jr z, @-$0e

    ld h, $2b
    jr nc, @+$27

    dec [hl]
    ld h, d
    daa
    ldh a, [rNR52]

jr_041_4d66:
    dec hl
    jr nc, jr_041_4d8e

    dec [hl]
    ld h, d
    ld h, $f0
    ld h, $2b
    jr nc, jr_041_4d96

    dec [hl]
    ld h, d
    dec h
    ldh a, [rNR52]

jr_041_4d76:
    dec hl
    jr nc, jr_041_4d9e

    dec [hl]
    ld h, d
    inc h
    ldh a, [rNR52]

jr_041_4d7e:
    dec hl
    jr nc, jr_041_4da6

    dec [hl]
    ld h, d
    ld [hl], $f0
    ld h, $2b
    jr nc, jr_041_4dae

    dec [hl]
    ld h, d
    ld bc, $26f0

jr_041_4d8e:
    dec hl
    jr nc, jr_041_4db6

    dec [hl]
    ld h, d
    ld [bc], a
    ldh a, [rNR52]

jr_041_4d96:
    dec hl
    jr nc, jr_041_4dbe

    dec [hl]
    ld h, d
    inc bc
    ldh a, [$37]

jr_041_4d9e:
    jr z, @+$37

    dec [hl]
    inc a
    ld [hl], $f0
    ld [hl-], a
    cpl

jr_041_4da6:
    daa
    ld a, [hl-]
    jr z, jr_041_4dd9

    cpl
    ldh a, [$36]
    ld h, d

jr_041_4dae:
    ld h, $24
    add hl, sp
    jr z, @-$0e

    jr nc, @+$2a

    cpl

jr_041_4db6:
    ld l, $2c
    daa
    ldh a, [$31]
    jr z, @+$38

    scf

jr_041_4dbe:
    ldh a, [$2c]
    cpl
    jr nc, @+$3c

    ld [hl-], a
    ld [hl-], a
    daa
    ldh a, [$37]
    ld [hl-], a
    jr nc, jr_041_4df2

    ld [hl-], a
    cpl
    inc h
    ldh a, [rNR52]
    inc h
    ld [hl], $2c
    ld sp, $f032
    ld a, [hl+]
    ld [hl-], a
    daa

jr_041_4dd9:
    scf
    ld a, [hl-]
    dec [hl]
    ldh a, [$2f]
    ld [hl-], a
    ld sp, $2427
    dec [hl]
    ld a, [hl+]
    dec [hl]
    ldh a, [$35]
    jr z, jr_041_4e1a

    jr c, jr_041_4e1a

    ldh a, [rNR50]
    dec [hl]
    inc sp
    scf
    ld a, [hl-]

jr_041_4df1:
    dec [hl]

jr_041_4df2:
    ldh a, [$27]
    inc h
    ld sp, $2826
    dec [hl]
    ldh a, [$37]
    ld h, d
    ld h, $24
    add hl, sp
    jr z, jr_041_4df1

    ld [hl], $33
    dec [hl]
    inc l
    ld sp, $f02a
    dec hl
    inc h
    inc sp
    inc sp
    inc a
    ldh a, [$2f]
    inc l
    add hl, hl
    jr z, jr_041_4e39

    ld [hl-], a
    daa
    ldh a, [$37]
    dec [hl]
    inc l
    inc h

jr_041_4e1a:
    cpl

jr_041_4e1b:
    ld bc, $37f0
    dec [hl]
    inc l
    inc h
    cpl
    ld [bc], a
    ldh a, [$30]
    ld h, d
    ld h, $24
    add hl, sp

jr_041_4e29:
    jr z, jr_041_4e1b

    inc sp
    dec [hl]
    inc l
    ld [hl], $32
    ld sp, $3df0
    ld h, d
    ld h, $24
    add hl, sp
    jr z, jr_041_4e29

jr_041_4e39:
    dec hl
    jr z, jr_041_4e6b

    ld h, $2f
    daa
    ldh a, [$27]
    dec [hl]
    ld a, [hl+]
    ld h, $36
    scf
    cpl
    ldh a, [$2b]
    dec [hl]
    ld a, [hl+]
    ld sp, $3626
    cpl
    ldh a, [rNR51]
    dec [hl]
    jr nc, @+$38

    ld h, $36
    cpl
    ldh a, [$3d]
    ld [hl-], a
    jr nc, jr_041_4e80

    ld h, $36
    cpl
    ldh a, [$30]
    scf
    ld h, d
    scf
    ld [hl-], a
    inc sp
    ldh a, [rNR50]
    scf
    scf
    ld [hl-], a

jr_041_4e6b:
    jr nc, @-$0e

    jr z, jr_041_4ea8

    inc l
    cpl
    ld h, d
    jr nc, @+$39

    ldh a, [$30]
    jr c, jr_041_4e9f

    ld [hl-], a
    ld h, $36
    cpl
    ldh a, [rNR51]
    scf
    ld a, [hl-]

jr_041_4e80:
    jr z, jr_041_4ea8

    ld [hl], $2f
    ldh a, [$36]
    ld h, $35
    scf
    jr nc, jr_041_4eaf

    inc sp
    ldh a, [$2c]
    scf
    jr z, jr_041_4ec1

    ld [hl], $33

jr_041_4e93:
    ldh a, [rNR52]
    dec hl
    jr c, @+$37

    ld h, $2b
    ldh a, [rNR52]
    ld [hl-], a
    cpl
    inc l

jr_041_4e9f:
    ld [hl], $38
    jr nc, jr_041_4e93

    jr nc, @+$26

    dec a
    jr z, jr_041_4ee2

jr_041_4ea8:
    ld [hl-], a
    daa
    ldh a, [$36]
    cpl
    daa
    add hl, hl

jr_041_4eaf:
    cpl
    dec [hl]
    ld bc, $36f0
    cpl
    daa
    add hl, hl
    cpl
    dec [hl]
    ld [bc], a
    ldh a, [$36]
    cpl
    daa
    add hl, hl
    cpl
    dec [hl]

jr_041_4ec1:
    inc bc
    ldh a, [$30]
    inc h
    dec a
    jr z, @+$03

    ldh a, [$30]
    inc h
    dec a
    jr z, jr_041_4ed0

    ldh a, [$30]

jr_041_4ed0:
    inc h
    dec a
    jr z, @+$05

    ldh a, [$30]
    jr nc, @+$28

    dec [hl]
    jr nc, @+$03

    ldh a, [$30]
    jr nc, jr_041_4f05

    dec [hl]
    jr nc, jr_041_4ee4

jr_041_4ee2:
    ldh a, [$30]

jr_041_4ee4:
    jr nc, jr_041_4f0c

    dec [hl]
    jr nc, jr_041_4eec

    ldh a, [rNR51]
    scf

jr_041_4eec:
    cpl
    daa
    jr z, @+$32

    ld [hl-], a
    ldh a, [rNR52]
    ld [hl], $2f
    dec h
    ld a, [hl+]
    ldh a, [$f0]
    ld sp, hl
    nop
    ldh a, [$3a]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, c

jr_041_4f05:
    ld d, d
    ld c, d
    ld c, l
    pop af
    ld sp, hl
    db $10
    ld h, h

jr_041_4f0c:
    ldh a, [$f9]
    nop
    ld h, d
    ld b, c
    ld d, d
    ld c, d
    ld c, l
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld a, $54
    ld a, $56
    ld h, e
    rst $30
    ldh a, [rNR52]
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, c
    ld d, d
    ld c, d
    ld c, l
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld bc, $f962
    db $10
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld b, h
    ld a, $53
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld a, [$f2f7]
    ld bc, $f962
    jr nz, jr_041_4fb4

    pop af
    rst $30
    ldh a, [$31]
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld d, b
    ld e, a
    rst $30
    ldh a, [$35]
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, h
    rst $30
    ldh a, [$f6]
    ld h, d
    ld b, e
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    pop af
    ld bc, $f962
    nop
    rst $30
    ldh a, [$2c]
    ld d, b
    ld h, d
    ld sp, hl
    nop
    ld h, d
    ld c, h
    ld c, b
    ld a, $56
    pop af
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, h
    ldh a, [$33]
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, h

jr_041_4fb4:
    ld d, b
    ld b, d
    pop af
    ld a, $4b
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$33]
    jr c, jr_041_5000

    ld h, d
    scf
    inc h
    ld l, $28
    jr z, @+$3d

    inc l
    scf
    ldh a, [$2c]
    scf
    jr z, jr_041_5007

    ld a, [hl+]
    ld [hl-], a
    cpl
    daa
    jr z, jr_041_5018

    inc l
    scf
    ldh a, [$28]
    ld c, d
    ld c, l
    ld d, c
    ld d, [hl]
    ldh a, [$28]
    ld b, h
    ld b, h
    ldh a, [$3a]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld a, $50
    ld a, [$f2f7]
    ld sp, hl

jr_041_5000:
    nop
    ld h, h
    pop af
    ldh a, [$28]
    dec sp
    inc l

jr_041_5007:
    scf
    ld h, d
    inc l
    ld sp, $3229
    ldh a, [$29]
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld bc, $f962
    nop

jr_041_5018:
    ld e, a
    pop af
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, b
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld a, [$f2f7]
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    pop af
    rst $30
    ldh a, [$2a]
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    pop af
    ld sp, hl
    nop
    ld h, e
    rst $30
    ldh a, [$27]
    ld d, d
    ld c, d
    ld c, l
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld h, h
    ldh a, [$27]
    ld d, d
    ld c, d
    ld c, l
    ld b, d
    ld b, c
    ld h, d
    ld sp, hl
    db $10
    pop af
    ld a, $4b
    ld b, c
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    ld h, d
    ld sp, hl
    nop
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld b, e
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    pop af
    ld sp, hl
    nop
    ld a, [hl+]
    ld e, a
    rst $30
    ldh a, [$29]
    ld b, [hl]
    ld c, e
    ld b, c
    ld d, b
    ld h, d
    ld sp, hl
    nop
    ld a, [hl+]
    ld e, a
    pop af
    ld h, $3e
    ld c, e
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $50
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld d, l
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $62
    jr nc, jr_041_5100

    ld c, d
    ld b, [hl]
    ld b, b
    ld h, e
    rst $30
    ldh a, [$f9]
    nop
    pop af
    ld b, e
    ld a, $46
    ld c, e
    ld d, c
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    pop af
    ld b, e
    ld a, $46
    ld c, e
    ld d, c
    ld d, b
    ld e, a
    rst $30
    ld a, [c]
    ld sp, hl
    db $10
    pop af
    ld b, e
    ld a, $46
    ld c, e
    ld d, c
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f6]
    ld l, b
    ld h, d
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld d, h
    ld b, [hl]
    ld c, l
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    rst $30
    ldh a, [$31]
    ld c, h
    ld d, c
    ld h, d
    ld c, a

jr_041_5100:
    ld b, d
    ld a, $41
    ld d, [hl]
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    pop af
    ld c, c
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    ld d, d
    ld c, l
    ld e, a
    ld a, [$f2f7]
    ld h, $45
    ld b, d
    ld b, b
    ld c, b
    ld h, d
    ld a, $4b
    ld b, c
    pop af
    ld d, c
    ld c, a
    ld d, [hl]
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld e, a
    rst $30
    ldh a, [rNR52]
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    pop af
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ldh a, [rNR52]
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    pop af
    ld c, l
    ld a, $4f
    ld d, c
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$36]
    ld a, $4a
    ld b, d
    ld h, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld e, a
    pop af
    ld h, $3e
    ld c, e
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld e, a
    rst $30
    ldh a, [$32]
    ld c, e
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld c, l
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld e, a
    ldh a, [$3a]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, h
    ldh a, [$35]
    ld b, d
    ld b, e
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld e, a
    ldh a, [rNR51]
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, a
    ld b, d
    ld b, e
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld e, a
    ldh a, [$36]
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, d
    ld c, c
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    pop af
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, e
    ldh a, [rNR52]
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    and b
    ld d, b
    and c
    pop af
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld e, a
    ldh a, [$3a]
    ld b, l
    ld a, $51
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    pop af
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld h, h
    ldh a, [rNR52]
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $4b
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    rst $30
    ldh a, [$36]
    ld d, d
    ccf
    ld c, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld a, $62
    ld c, l
    ld c, a
    ld b, [hl]
    ld d, a
    ld b, d
    ld h, h
    rst $30
    ldh a, [$31]
    ld c, h
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    pop af
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    ld a, [$f2f7]
    scf
    ld b, l
    ld d, d
    ld d, b
    ld e, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld h, d
    ld c, l
    ld c, a
    ld b, [hl]
    ld d, a
    ld b, d
    ld e, a
    pop af
    rst $30
    ldh a, [rNR52]
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    pop af
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld b, [hl]
    ld d, a
    ld b, d
    ld h, h
    ldh a, [rNR50]
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, h
    ldh a, [$29]
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    ld h, e
    ldh a, [$35]
    ld b, d
    ld b, e
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld e, a
    ldh a, [rNR51]
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld b, e
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld e, a
    ldh a, [$31]
    ld c, h
    ld h, d
    ld c, l
    ld c, a
    ld b, [hl]
    ld d, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$3c]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld a, [$f2f7]
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    pop af
    ld a, [$f2f7]
    dec h
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    pop af
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ccf
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, h
    ld c, c
    ld b, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$31]
    ld c, h
    ld h, d
    ld [hl], $3e
    ld d, e
    ld b, d
    ld e, a
    ldh a, [$35]
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld e, a
    rst $30
    ldh a, [$62]
    ld h, d
    dec de
    inc d
    inc e
    dec e
    ldh a, [rBCPD]
    ld h, a
    dec d
    ld l, a
    inc e
    dec e
    ldh a, [$2b]
    inc sp
    ldh a, [$30]
    inc sp
    ldh a, [rNR50]
    scf
    scf
    inc h
    ld h, $2e
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ldh a, [$27]
    jr z, jr_041_53e3

    jr z, jr_041_53ed

    ld [hl], $28
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ldh a, [rNR50]
    ld a, [hl+]
    inc l
    cpl
    inc l
    scf
    inc a
    ldh a, [$2c]
    ld sp, $2837
    cpl
    cpl
    inc l
    ld a, [hl+]
    jr z, jr_041_5408

    ld h, $28
    ldh a, [$ae]
    ldh a, [$af]
    ldh a, [$a9]
    ldh a, [$b0]
    ldh a, [$b1]

jr_041_53e3:
    ldh a, [$ad]
    ldh a, [$b2]
    ldh a, [$b3]
    ldh a, [rNR52]
    ld a, $4b

jr_041_53ed:
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, d
    ld b, l

jr_041_5408:
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [rNR34]
    ld e, c
    inc de
    or h
    ld h, d
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    pop af
    ld a, $49
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld h, d
    ld b, d
    ld d, l
    ld b, [hl]
    ld d, b
    ld d, c
    ld d, b
    ld e, a
    ld a, [$f2f7]
    inc l
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    pop af
    ld sp, hl
    nop
    ld h, d
    ld c, h
    ld c, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$f2f7]
    ld sp, hl
    db $10
    ld h, h
    pop af
    ldh a, [$3c]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, e
    ld a, [$f0f7]
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld h, e
    ld a, [$f0f7]
    ld sp, hl
    nop
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld c, a
    ld b, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    pop af
    ld sp, hl
    db $10
    ld e, a
    rst $30
    ldh a, [$f9]
    db $10
    ld h, d
    ld d, h
    ld a, $50
    pop af
    ld d, c
    ld a, $48
    ld b, d
    ld c, e
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    nop
    ld e, a
    rst $30
    ldh a, [$3a]
    dec hl
    ld [hl-], a
    inc l
    ld sp, $3229
    ld [hl-], a
    ld l, $30
    ld [hl-], a
    ld sp, $2a28
    ld a, [hl+]
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $43
    ld a, $4f
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld h, e
    ld a, [$eff7]
    xor $27
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4f
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$f9]
    db $10
    ld h, d
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$f2f7]
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld e, a
    pop af
    rst $30
    ldh a, [$35]
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    ldh a, [$2c]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    pop af
    ld [hl-], a
    ld l, $62
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, h
    ldh a, [$27]
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld c, a
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$f2f7]
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    pop af
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$37]
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    pop af
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$f2f7]
    ld b, b
    ld d, d
    ld c, a
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld c, l
    ld a, $4f
    ld d, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    rst $30
    ldh a, [$35]
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    ldh a, [$31]
    ld c, h
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld e, a
    rst $30
    ldh a, [$35]
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, h
    ldh a, [$f9]
    db $10
    ld h, d
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$f2f7]
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld e, a
    pop af
    rst $30
    ldh a, [$2c]
    scf
    jr z, jr_041_5666

    ldh a, [$3a]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    pop af
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld h, h
    and $f0
    ld [hl], $3e
    ld d, e
    ld b, d
    ld b, c
    ld h, e
    ld h, d
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    pop af

jr_041_5666:
    ld c, h
    ld b, e
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld e, a
    ldh a, [$37]
    ld b, l
    ld a, $4b
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    pop af
    rst $30
    ld a, [c]
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld e, a
    ldh a, [rLCDC]
    ld b, l
    ld b, d
    ld c, e
    ld e, a
    ld b, a
    ld e, a
    ld c, e
    or h
    sbc e
    ldh a, [$3c]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$f2f7]
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld c, l
    ld a, $4f
    ld d, c
    ld d, [hl]
    pop af
    ld a, $50
    ld h, d
    ld a, $62
    ld c, l
    ld c, a
    ld b, [hl]
    ld d, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$33]
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $f1
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$f2f7]
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    pop af
    rst $30
    ldh a, [$37]
    ld c, h
    ld c, h
    ld h, d
    ccf
    ld a, $41
    ld e, a
    ld e, a
    ld e, a
    pop af
    dec h
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld a, $46
    ld c, c
    ld b, d
    ld b, c
    ld e, a
    rst $30
    ldh a, [rNR51]
    jr z, jr_041_5760

jr_041_5736:
    inc l
    ld sp, $2c31
    ld sp, $a32a
    ldh a, [$39]
    inc l
    cpl
    cpl
    inc h
    ld a, [hl+]
    jr z, jr_041_577b

    and e
    ldh a, [$37]
    inc h
    cpl
    inc l
    ld [hl], $30
    inc h
    ld sp, $f0a3
    jr nc, jr_041_577c

    jr nc, jr_041_5788

    dec [hl]
    inc l
    jr z, jr_041_5790

    and e
    ldh a, [rNR51]
    jr z, jr_041_5799

    inc l

jr_041_5760:
    cpl
    daa
    jr z, jr_041_5799

    and e
    ldh a, [$33]
    jr z, jr_041_578d

    ld h, $28
    and e
    ldh a, [rNR51]
    dec [hl]
    inc h
    add hl, sp
    jr z, jr_041_57a8

    inc a
    and e
    ldh a, [$36]
    scf
    dec [hl]
    jr z, jr_041_57ac

jr_041_577b:
    ld a, [hl+]

jr_041_577c:
    scf
    dec hl
    and e
    ldh a, [rNR50]
    ld sp, $282a
    dec [hl]
    and e
    ldh a, [$2d]

jr_041_5788:
    ld [hl-], a
    inc a
    and e
    ldh a, [$3a]

jr_041_578d:
    inc l
    ld [hl], $27

jr_041_5790:
    ld [hl-], a
    jr nc, jr_041_5736

    ldh a, [$2b]
    inc h
    inc sp
    inc sp
    inc l

jr_041_5799:
    ld sp, $3628
    ld [hl], $a3
    ldh a, [$37]
    jr z, jr_041_57d2

    inc sp
    scf
    inc h
    scf
    inc l
    ld [hl-], a

jr_041_57a8:
    ld sp, $f0a3
    cpl

jr_041_57ac:
    inc h
    dec h
    inc a
    dec [hl]
    inc l
    ld sp, $2b37
    and e
    ldh a, [$2d]
    jr c, jr_041_57e0

    ld a, [hl+]
    jr nc, @+$2a

    ld sp, $a337
    ldh a, [$35]
    jr z, jr_041_57ec

    cpl
    jr z, jr_041_57ec

    scf
    inc l
    ld [hl-], a
    ld sp, $f0a3
    ldh a, [$37]
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d

jr_041_57d2:
    ld [hl-], a
    ld c, l
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld d, d
    ld c, e
    ld a, $53

jr_041_57e0:
    ld a, $46
    ld c, c
    ld a, $3f
    ld c, c
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l

jr_041_57ec:
    ld a, [$f2f7]
    ld [hl], $52
    ld c, l
    ld b, d
    ld c, a
    ld h, d
    ld a, [hl+]
    ld a, $4a
    ld b, d
    ld h, d
    dec h
    ld c, h
    ld d, [hl]
    ld e, a
    pop af
    rst $30
    ldh a, [$36]
    cpl
    inc l
    dec [hl]
    ldh a, [$36]
    cpl
    jr c, jr_041_583d

    ldh a, [$35]
    jr c, jr_041_583c

    inc a

jr_041_580f:
    ldh a, [$36]
    inc h
    cpl
    inc a
    ldh a, [$33]
    ld [hl-], a
    ld [hl], $3c
    ldh a, [$33]
    jr z, jr_041_5854

    jr z, jr_041_580f

    ld [hl], $2f
    inc h
    ld h, $f0
    jr nc, jr_041_584e

    cpl
    scf
    ldh a, [$36]
    cpl
    jr z, jr_041_5855

    ldh a, [rNR52]
    inc h
    cpl
    ldh a, [$36]
    inc l
    cpl
    ldh a, [$36]
    inc h
    cpl
    ldh a, [$30]
    inc l

jr_041_583c:
    cpl

jr_041_583d:
    inc l

jr_041_583e:
    ldh a, [$2f]
    inc l
    jr nc, jr_041_586b

    ldh a, [$30]
    inc h
    dec [hl]

jr_041_5847:
    ld h, $f0
    inc h
    jr c, jr_041_5883

    jr nc, jr_041_583e

jr_041_584e:
    dec [hl]
    jr z, jr_041_588c

    ldh a, [$30]
    ld [hl-], a

jr_041_5854:
    add hl, sp

jr_041_5855:
    jr z, jr_041_5847

    ld h, $2f
    ld [hl-], a
    ld a, [hl-]
    ldh a, [$37]
    inc h
    inc sp
    ldh a, [$2e]
    inc l
    scf

jr_041_5863:
    jr z, jr_041_5855

    ld a, [hl-]
    inc l
    cpl
    daa
    ldh a, [$2a]

jr_041_586b:
    jr z, jr_041_5895

    ld l, $f0
    scf
    inc l
    jr z, jr_041_5863

    daa
    dec [hl]
    inc h
    ld h, $f0
    ld h, $24
    dec [hl]
    inc a
    ldh a, [rNR51]
    jr z, jr_041_58b7

    dec hl
    ldh a, [$2f]

jr_041_5883:
    jr c, @+$31

    jr c, @-$0e

    inc l
    ld [hl], $3c
    ld [hl], $f0

jr_041_588c:
    ld h, $2b
    jr z, jr_041_58c6

    ldh a, [$2a]
    inc l
    dec [hl]
    cpl

jr_041_5895:
    ldh a, [rNR51]
    jr z, jr_041_58c8

    cpl
    ldh a, [$36]
    inc h
    add hl, sp
    inc a
    ldh a, [$33]
    jr c, jr_041_58d1

    inc a
    ldh a, [rNR51]
    jr c, jr_041_58d6

    inc a
    ldh a, [rNR51]
    ld [hl-], a
    ld sp, $f02a
    ld a, [hl+]
    jr c, jr_041_58e3

    inc a
    ldh a, [$36]
    jr c, jr_041_58e8

jr_041_58b7:
    inc a
    ldh a, [$30]
    inc h
    dec sp
    ldh a, [$27]
    jr z, jr_041_58ef

    ld [hl-], a
    ldh a, [$31]
    jr z, jr_041_58fe

    inc a

jr_041_58c6:
    ldh a, [$37]

jr_041_58c8:
    inc l
    cpl
    ldh a, [$3c]
    jr z, jr_041_5905

    inc h
    ldh a, [$36]

jr_041_58d1:
    inc h
    ld [hl], $24
    ldh a, [$30]

jr_041_58d6:
    ld [hl-], a
    ld l, $32
    ldh a, [$2e]
    inc h
    dec [hl]
    inc a
    ldh a, [rNR51]
    inc h
    dec h
    inc a

jr_041_58e3:
    ldh a, [$2e]
    inc l
    scf
    inc h

jr_041_58e8:
    ldh a, [rNR51]
    inc l
    dec [hl]
    daa
    ldh a, [$2f]

jr_041_58ef:
    jr c, jr_041_5917

    ld l, $f0
    ld h, $2b
    inc l
    inc sp

jr_041_58f7:
    ldh a, [$33]
    inc h
    dec [hl]
    ld l, $f0
    dec hl

jr_041_58fe:
    jr z, jr_041_592e

    inc a
    ldh a, [$35]
    inc h
    add hl, sp

jr_041_5905:
    jr z, jr_041_58f7

    scf
    ld [hl-], a
    ld sp, $f03c
    dec [hl]
    inc h
    daa
    inc a
    ldh a, [rNR52]
    jr c, jr_041_5942

    inc a
    ldh a, [rNR52]

jr_041_5917:
    ld [hl-], a
    ld [hl-], a
    ldh a, [$2d]
    ld [hl-], a
    daa
    inc a
    ldh a, [rNR51]
    ld [hl-], a
    ld sp, $f03c
    jr nc, @+$2e

    ld [hl], $24
    ldh a, [$30]
    jr z, @+$2c

    ldh a, [$2e]

jr_041_592e:
    jr z, jr_041_595f

    inc a
    ldh a, [$29]
    jr z, jr_041_5971

    ldh a, [rNR51]
    ld [hl-], a
    ld sp, $f03d
    dec a
    ld [hl-], a
    ld [hl-], a
    cpl
    ldh a, [rNR51]
    inc h

jr_041_5942:
    dec h
    inc h
    ldh a, [$30]
    inc l
    scf
    inc a
    ldh a, [$2b]
    ld [hl-], a
    cpl
    inc a
    ldh a, [$2e]
    inc l
    ld sp, $f03c
    cpl
    jr c, @+$32

    inc sp
    ldh a, [$36]
    inc l
    ld [hl-], a
    ld sp, $28f0

jr_041_595f:
    add hl, sp
    jr z, @-$0e

    cpl
    ld [hl-], a
    scf
    ld [hl], $f0
    dec [hl]
    ld [hl-], a
    ld [hl], $28
    ldh a, [rNR52]
    jr c, jr_041_599e

    ldh a, [$2d]

jr_041_5971:
    inc l
    cpl
    cpl
    ldh a, [rNR51]
    jr z, jr_041_599e

    ld l, $f0
    ld [hl], $2b
    inc a
    ldh a, [$29]
    jr c, jr_041_59b6

    ldh a, [$2e]
    inc l
    ld h, $36
    ldh a, [$2d]
    ld [hl-], a
    dec hl

jr_041_598a:
    ld sp, $35f0
    inc l
    jr nc, jr_041_59c3

    ldh a, [$33]
    jr z, @+$2a

    scf
    ldh a, [$2a]
    dec [hl]
    jr c, jr_041_598a

    dec h
    dec [hl]
    jr c, @+$39

jr_041_599e:
    ldh a, [$37]
    ld [hl-], a
    inc sp
    inc a
    ldh a, [$36]
    scf
    inc l
    ld l, $f0
    jr nc, @+$26

    dec [hl]
    inc a
    ldh a, [$2f]
    inc a
    ld sp, $f031
    dec h
    jr z, jr_041_59ed

jr_041_59b6:
    inc a
    ldh a, [$2b]
    ld [hl-], a
    ld sp, $f03c
    inc sp
    ld [hl-], a
    cpl
    inc a
    ldh a, [rNR52]

jr_041_59c3:
    ld [hl-], a
    ld [hl-], a
    cpl
    ldh a, [$2b]
    inc h
    ld sp, $f024
    ld [hl], $38
    ld sp, $30f0
    jr z, jr_041_59fc

    inc a
    ldh a, [rNR51]
    jr z, jr_041_5a0d

    ld a, [hl+]
    ldh a, [$30]
    jr z, jr_041_5a12

    jr z, @-$0e

    dec h
    inc h
    dec [hl]
    scf

jr_041_59e3:
    ldh a, [rNR51]
    dec [hl]
    jr c, jr_041_5a19

    ldh a, [rNR51]
    ld [hl-], a
    cpl
    daa

jr_041_59ed:
    ldh a, [$2f]
    jr c, jr_041_5a1f

    jr z, jr_041_59e3

    inc h
    jr nc, jr_041_5a28

    ld [hl], $f0
    ld [hl], $24
    cpl
    inc h

jr_041_59fc:
    ldh a, [$33]
    ld [hl-], a
    cpl
    inc h
    ldh a, [$2d]
    jr c, jr_041_5a2c

    inc a
    ldh a, [$39]
    inc l
    add hl, sp
    inc l
    ldh a, [$29]

jr_041_5a0d:
    cpl
    ld [hl-], a
    dec [hl]
    ldh a, [$36]

jr_041_5a12:
    inc h
    daa
    inc a
    ldh a, [rNR50]
    jr nc, @+$3e

jr_041_5a19:
    ldh a, [$35]
    ld [hl-], a
    ld sp, $f024

jr_041_5a1f:
    jr nc, jr_041_5a4d

    cpl
    ldh a, [$3a]
    inc l
    cpl
    ldh a, [$37]

jr_041_5a28:
    ld [hl-], a
    ld [hl-], a
    ldh a, [$31]

jr_041_5a2c:
    jr z, jr_041_5a5c

    ldh a, [$37]
    jr z, jr_041_5a60

    ldh a, [$37]
    ld [hl-], a
    scf
    ld [hl-], a
    ldh a, [$39]
    ld [hl-], a
    jr nc, @+$2e

    ldh a, [$2f]
    inc l
    cpl
    inc l
    ldh a, [rNR51]
    jr z, @+$31

    inc a
    ldh a, [$2d]
    jr z, @+$33

    inc a
    ldh a, [$29]

jr_041_5a4d:
    dec [hl]
    inc h
    ld sp, $27f0
    ld [hl-], a
    dec [hl]
    ldh a, [$37]
    ld a, [hl-]
    jr z, jr_041_5a81

    ldh a, [$2e]
    inc h

jr_041_5a5c:
    ld sp, $f024
    dec [hl]

jr_041_5a60:
    inc h
    inc a
    ldh a, [$2d]
    jr z, @+$38

    inc a
    ldh a, [$31]
    inc l
    scf
    dec [hl]
    ldh a, [$33]
    jr z, @+$35

    ldh a, [$35]
    ld [hl-], a
    ld l, $3c
    ldh a, [$30]
    jr z, @+$2c

    inc h
    ldh a, [$29]
    ld [hl-], a
    scf
    ldh a, [$39]
    inc l

jr_041_5a81:
    ld sp, $f03c
    dec h
    ld [hl-], a
    dec h
    ldh a, [$35]
    ld [hl-], a
    dec h
    ldh a, [$2d]
    jr z, jr_041_5abe

    ldh a, [$35]
    jr c, @+$27

    inc a
    ldh a, [$33]
    inc h
    dec [hl]
    cpl
    ldh a, [rNR50]
    jr nc, jr_041_5ac5

    scf
    ldh a, [$33]
    inc l
    inc h
    ldh a, [$37]
    inc l
    inc h
    ldh a, [$36]
    jr z, jr_041_5adf

    inc h
    ldh a, [$35]
    jr z, @+$29

    inc h
    ldh a, [$27]
    dec [hl]
    inc h
    ld sp, $33f0
    jr c, jr_041_5aec

    ld [hl], $f0
    ld h, $24
    dec [hl]

jr_041_5abe:
    cpl
    ldh a, [$3d]
    jr z, jr_041_5aeb

    ld l, $f0

jr_041_5ac5:
    ld h, $35
    inc l
    ld [hl], $f0
    ld a, [hl+]
    ld [hl-], a
    cpl
    daa
    ldh a, [$2a]
    inc l
    ld a, [hl+]
    inc h
    ldh a, [rNR52]
    jr z, @+$33

    scf
    ldh a, [$30]
    inc h
    dec [hl]
    inc l
    ldh a, [rNR50]

jr_041_5adf:
    ld sp, $2431
    ldh a, [$28]
    cpl
    cpl
    inc a
    ldh a, [$2f]
    inc l
    dec a

jr_041_5aeb:
    inc h

jr_041_5aec:
    ldh a, [rNR51]
    jr z, jr_041_5b1f

    inc h
    ldh a, [$2f]
    inc l
    cpl
    inc a
    ldh a, [rNR50]
    ld sp, $f031
    dec h
    inc h
    dec [hl]
    dec h
    ldh a, [$30]
    inc h
    dec [hl]
    inc l
    ldh a, [rNR50]
    ld sp, $2431
    ldh a, [rNR10]
    ldh a, [rNR11]
    ldh a, [rNR12]
    ldh a, [rNR13]
    ldh a, [rNR14]
    ldh a, [$15]
    ldh a, [rNR21]
    ldh a, [rNR22]
    ldh a, [rNR23]
    ldh a, [rNR24]
    ldh a, [$f0]


; ---------------------------------------------------------------
; Monster Name Strings ($5B1F)
; $F0 terminated, charmap encoded
; ---------------------------------------------------------------

jr_041_5b1f:
MonsterNameStrings:
MonsterName_000_DrakSlime: db "DrakSlime", $F0
MonsterName_001_SpotSlime: db "SpotSlime", $F0
MonsterName_002_WingSlime: db "WingSlime", $F0
MonsterName_003_TreeSlime: db "TreeSlime", $F0
MonsterName_004_Snaily: db "Snaily", $F0
MonsterName_005_SlimeNite: db "SlimeNite", $F0
MonsterName_006_Babble: db "Babble", $F0
MonsterName_007_BoxSlime: db "BoxSlime", $F0
MonsterName_008_Slime: db "Slime", $F0
MonsterName_009_Healer: db "Healer", $F0
MonsterName_010_FangSlime: db "FangSlime", $F0
MonsterName_011_RockSlime: db "RockSlime", $F0
MonsterName_012_SlimeBorg: db "SlimeBorg", $F0
MonsterName_013_Slabbit: db "Slabbit", $F0
MonsterName_014_SpotKing: db "SpotKing", $F0
MonsterName_015_KingSlime: db "KingSlime", $F0
MonsterName_016_Metaly: db "Metaly", $F0
MonsterName_017_Metabble: db "Metabble", $F0
MonsterName_018_MetalKing: db "MetalKing", $F0
MonsterName_019_GoldSlime: db "GoldSlime", $F0
MonsterName_020_DragonKid: db "DragonKid", $F0
MonsterName_021_Tortragon: db "Tortragon", $F0
MonsterName_022_Pteranod: db "Pteranod", $F0
MonsterName_023_Gasgon: db "Gasgon", $F0
MonsterName_024_FairyDrak: db "FairyDrak", $F0
MonsterName_025_LizardMan: db "LizardMan", $F0
MonsterName_026_Poisongon: db "Poisongon", $F0
MonsterName_027_Swordgon: db "Swordgon", $F0
MonsterName_028_Dragon: db "Dragon", $F0
MonsterName_029_MiniDrak: db "MiniDrak", $F0
MonsterName_030_MadDragon: db "MadDragon", $F0
MonsterName_031_Rayburn: db "Rayburn", $F0
MonsterName_032_Chamelgon: db "Chamelgon", $F0
MonsterName_033_LizardFly: db "LizardFly", $F0
MonsterName_034_Andreal: db "Andreal", $F0
MonsterName_035_KingCobra: db "KingCobra", $F0
MonsterName_036_Spikerous: db "Spikerous", $F0
MonsterName_037_GreatDrak: db "GreatDrak", $F0
MonsterName_038_Crestpent: db "Crestpent", $F0
MonsterName_039_WingSnake: db "WingSnake", $F0
MonsterName_040_Coatol: db "Coatol", $F0
MonsterName_041_Orochi: db "Orochi", $F0
MonsterName_042_BattleRex: db "BattleRex", $F0
MonsterName_043_SkyDragon: db "SkyDragon", $F0
MonsterName_044_Divinegon: db "Divinegon", $F0
MonsterName_045_Tonguella: db "Tonguella", $F0
MonsterName_046_Almiraj: db "Almiraj", $F0
MonsterName_047_CatFly: db "CatFly", $F0
MonsterName_048_PillowRat: db "PillowRat", $F0
MonsterName_049_Saccer: db "Saccer", $F0
MonsterName_050_GulpBeast: db "GulpBeast", $F0
MonsterName_051_Skullroo: db "Skullroo", $F0
MonsterName_052_WindBeast: db "WindBeast", $F0
MonsterName_053_Anteater: db "Anteater", $F0
MonsterName_054_SuperTen: db "SuperTen", $F0
MonsterName_055_IronTurt: db "IronTurt", $F0
MonsterName_056_Mommonja: db "Mommonja", $F0
MonsterName_057_HammerMan: db "HammerMan", $F0
MonsterName_058_Grizzly: db "Grizzly", $F0
MonsterName_059_Yeti: db "Yeti", $F0
MonsterName_060_MadGopher: db "MadGopher", $F0
MonsterName_061_FairyRat: db "FairyRat", $F0
MonsterName_062_Unicorn: db "Unicorn", $F0
MonsterName_063_Goategon: db "Goategon", $F0
MonsterName_064_WildApe: db "WildApe", $F0
MonsterName_065_Trumpeter: db "Trumpeter", $F0
MonsterName_066_KingLeo: db "KingLeo", $F0
MonsterName_067_DarkHorn: db "DarkHorn", $F0
MonsterName_068_MadCat: db "MadCat", $F0
MonsterName_069_BigEye: db "BigEye", $F0
MonsterName_070_Picky: db "Picky", $F0
MonsterName_071_Wyvern: db "Wyvern", $F0
MonsterName_072_BullBird: db "BullBird", $F0
MonsterName_073_Florajay: db "Florajay", $F0
MonsterName_074_DuckKite: db "DuckKite", $F0
MonsterName_075_MadPecker: db "MadPecker", $F0
MonsterName_076_MadRaven: db "MadRaven", $F0
MonsterName_077_MistyWing: db "MistyWing", $F0
MonsterName_078_Dracky: db "Dracky", $F0
MonsterName_079_BigRoost: db "BigRoost", $F0
MonsterName_080_StubBird: db "StubBird", $F0
MonsterName_081_LandOwl: db "LandOwl", $F0
MonsterName_082_MadGoose: db "MadGoose", $F0
MonsterName_083_MadCondor: db "MadCondor", $F0
MonsterName_084_Blizzardy: db "Blizzardy", $F0
MonsterName_085_Phoenix: db "Phoenix", $F0
MonsterName_086_ZapBird: db "ZapBird", $F0
MonsterName_087_WhipBird: db "WhipBird", $F0
MonsterName_088_FunkyBird: db "FunkyBird", $F0
MonsterName_089_RainHawk: db "RainHawk", $F0
MonsterName_090_MadPlant: db "MadPlant", $F0
MonsterName_091_FireWeed: db "FireWeed", $F0
MonsterName_092_FloraMan: db "FloraMan", $F0
MonsterName_093_WingTree: db "WingTree", $F0
MonsterName_094_CactiBall: db "CactiBall", $F0
MonsterName_095_Gulpple: db "Gulpple", $F0
MonsterName_096_Toadstool: db "Toadstool", $F0
MonsterName_097_AmberWeed: db "AmberWeed", $F0
MonsterName_098_Stubsuck: db "Stubsuck", $F0
MonsterName_099_Oniono: db "Oniono", $F0
MonsterName_100_DanceVegi: db "DanceVegi", $F0
MonsterName_101_TreeBoy: db "TreeBoy", $F0
MonsterName_102_FaceTree: db "FaceTree", $F0
MonsterName_103_HerbMan: db "HerbMan", $F0
MonsterName_104_BeanMan: db "BeanMan", $F0
MonsterName_105_EvilSeed: db "EvilSeed", $F0
MonsterName_106_ManEater: db "ManEater", $F0
MonsterName_107_Snapper: db "Snapper", $F0
MonsterName_108_Rosevine: db "Rosevine", $F0
MonsterName_109_Watabou: db "Watabou", $F0
MonsterName_110_GiantSlug: db "GiantSlug", $F0
MonsterName_111_Catapila: db "Catapila", $F0
MonsterName_112_Gophecada: db "Gophecada", $F0
MonsterName_113_Butterfly: db "Butterfly", $F0
MonsterName_114_WeedBug: db "WeedBug", $F0
MonsterName_115_GiantWorm: db "GiantWorm", $F0
MonsterName_116_Lipsy: db "Lipsy", $F0
MonsterName_117_StagBug: db "StagBug", $F0
MonsterName_118_ArmyAnt: db "ArmyAnt", $F0
MonsterName_119_GoHopper: db "GoHopper", $F0
MonsterName_120_TailEater: db "TailEater", $F0
MonsterName_121_ArmorPede: db "ArmorPede", $F0
MonsterName_122_Eyeder: db "Eyeder", $F0
MonsterName_123_GiantMoth: db "GiantMoth", $F0
MonsterName_124_Droll: db "Droll", $F0
MonsterName_125_ArmyCrab: db "ArmyCrab", $F0
MonsterName_126_MadHornet: db "MadHornet", $F0
MonsterName_127_HornBeet: db "HornBeet", $F0
MonsterName_128_Armorpion: db "Armorpion", $F0
MonsterName_129_Digster: db "Digster", $F0
MonsterName_130_Pixy: db "Pixy", $F0
MonsterName_131_ArcDemon: db "ArcDemon", $F0
MonsterName_132_AgDevil: db "AgDevil", $F0
MonsterName_133_Demonite: db "Demonite", $F0
MonsterName_134_DarkEye: db "DarkEye", $F0
MonsterName_135_EyeBall: db "EyeBall", $F0
MonsterName_136_SkulRider: db "SkulRider", $F0
MonsterName_137_EvilBeast: db "EvilBeast", $F0
MonsterName_138_1EyeClown: db "1EyeClown", $F0
MonsterName_139_Gremlin: db "Gremlin", $F0
MonsterName_140_MedusaEye: db "MedusaEye", $F0
MonsterName_141_Lionex: db "Lionex", $F0
MonsterName_142_GoatHorn: db "GoatHorn", $F0
MonsterName_143_Orc: db "Orc", $F0
MonsterName_144_Ogre: db "Ogre", $F0
MonsterName_145_GateGuard: db "GateGuard", $F0
MonsterName_146_ChopClown: db "ChopClown", $F0
MonsterName_147_Grendal: db "Grendal", $F0
MonsterName_148_Akubar: db "Akubar", $F0
MonsterName_149_MadKnight: db "MadKnight", $F0
MonsterName_150_Gigantes: db "Gigantes", $F0
MonsterName_151_Centasaur: db "Centasaur", $F0
MonsterName_152_EvilArmor: db "EvilArmor", $F0
MonsterName_153_Jamirus: db "Jamirus", $F0
MonsterName_154_Durran: db "Durran", $F0
MonsterName_155_Spooky: db "Spooky", $F0
MonsterName_156_Skullgon: db "Skullgon", $F0
MonsterName_157_Putrepup: db "Putrepup", $F0
MonsterName_158_RotRaven: db "RotRaven", $F0
MonsterName_159_Mummy: db "Mummy", $F0
MonsterName_160_DarkCrab: db "DarkCrab", $F0
MonsterName_161_DeadNite: db "DeadNite", $F0
MonsterName_162_Shadow: db "Shadow", $F0
MonsterName_163_Hork: db "Hork", $F0
MonsterName_164_Mudron: db "Mudron", $F0
MonsterName_165_NiteWhip: db "NiteWhip", $F0
MonsterName_166_MadSpirit: db "MadSpirit", $F0
MonsterName_167_WindMerge: db "WindMerge", $F0
MonsterName_168_Reaper: db "Reaper", $F0
MonsterName_169_DeadNoble: db "DeadNoble", $F0
MonsterName_170_WhiteKing: db "WhiteKing", $F0
MonsterName_171_BoneSlave: db "BoneSlave", $F0
MonsterName_172_Skeletor: db "Skeletor", $F0
MonsterName_173_Servant: db "Servant", $F0
MonsterName_174_Copycat: db "Copycat", $F0
MonsterName_175_JewelBag: db "JewelBag", $F0
MonsterName_176_EvilWand: db "EvilWand", $F0
MonsterName_177_MadCandle: db "MadCandle", $F0
MonsterName_178_CoilBird: db "CoilBird", $F0
MonsterName_179_Facer: db "Facer", $F0
MonsterName_180_SpikyBoy: db "SpikyBoy", $F0
MonsterName_181_MadMirror: db "MadMirror", $F0
MonsterName_182_RogueNite: db "RogueNite", $F0
MonsterName_183_Goopi: db "Goopi", $F0
MonsterName_184_Voodoll: db "Voodoll", $F0
MonsterName_185_MetalDrak: db "MetalDrak", $F0
MonsterName_186_Balzak: db "Balzak", $F0
MonsterName_187_SabreMan: db "SabreMan", $F0
MonsterName_188_CurseLamp: db "CurseLamp", $F0
MonsterName_189_Roboster: db "Roboster", $F0
MonsterName_190_EvilPot: db "EvilPot", $F0
MonsterName_191_Gismo: db "Gismo", $F0
MonsterName_192_LavaMan: db "LavaMan", $F0
MonsterName_193_IceMan: db "IceMan", $F0
MonsterName_194_Mimic: db "Mimic", $F0
MonsterName_195_MudDoll: db "MudDoll", $F0
MonsterName_196_Golem: db "Golem", $F0
MonsterName_197_StoneMan: db "StoneMan", $F0
MonsterName_198_BombCrag: db "BombCrag", $F0
MonsterName_199_GoldGolem: db "GoldGolem", $F0
MonsterName_200_DracoLord: db "DracoLord", $F0
MonsterName_201_DracoLord: db "DracoLord", $F0
MonsterName_202_Hargon: db "Hargon", $F0
MonsterName_203_Sidoh: db "Sidoh", $F0
MonsterName_204_Baramos: db "Baramos", $F0
MonsterName_205_Zoma: db "Zoma", $F0
MonsterName_206_Pizzaro: db "Pizzaro", $F0
MonsterName_207_Esterk: db "Esterk", $F0
MonsterName_208_Mirudraas: db "Mirudraas", $F0
MonsterName_209_Mirudraas: db "Mirudraas", $F0
MonsterName_210_Mudou: db "Mudou", $F0
MonsterName_211_DeathMore: db "DeathMore", $F0
MonsterName_212_DeathMore: db "DeathMore", $F0
MonsterName_213_DeathMore: db "DeathMore", $F0
MonsterName_214_Darkdrium: db "Darkdrium", $F0
MonsterName_215_TERRY: db "TERRY?", $F0
MonsterName_216_Tatsu: db "Tatsu", $F0
MonsterName_217_Diago: db "Diago", $F0
MonsterName_218_Samsi: db "Samsi", $F0
MonsterName_219_Bazoo: db "Bazoo", $F0
MonsterName_220_Unused_220: db $F0
MonsterName_225_Unused_225: db "?????", $F0

; ---------------------------------------------------------------
; Skill Name Strings ($628E)
; 256 entries, $F0 terminated, charmap encoded
; ---------------------------------------------------------------

SkillNameStrings:
SkillName_000_Blaze: db "Blaze", $F0
SkillName_001_Blazemore: db "Blazemore", $F0
SkillName_002_Blazemost: db "Blazemost", $F0
SkillName_003_Firebal: db "Firebal", $F0
SkillName_004_Firebane: db "Firebane", $F0
SkillName_005_Firebolt: db "Firebolt", $F0
SkillName_006_Bang: db "Bang", $F0
SkillName_007_Boom: db "Boom", $F0
SkillName_008_Explodet: db "Explodet", $F0
SkillName_009_Infernos: db "Infernos", $F0
SkillName_010_Infermore: db "Infermore", $F0
SkillName_011_Infermost: db "Infermost", $F0
SkillName_012_IceBolt: db "IceBolt", $F0
SkillName_013_SnowStorm: db "SnowStorm", $F0
SkillName_014_Blizzard: db "Blizzard", $F0
SkillName_015_Bolt: db "Bolt", $F0
SkillName_016_Zap: db "Zap", $F0
SkillName_017_Thordain: db "Thordain", $F0
SkillName_018_Beat: db "Beat", $F0
SkillName_019_Defeat: db "Defeat", $F0
SkillName_020_Sacrifice: db "Sacrifice", $F0
SkillName_021_Sleep: db "Sleep", $F0
SkillName_022_SleepAll: db "SleepAll", $F0
SkillName_023_StopSpell: db "StopSpell", $F0
SkillName_024_Surround: db "Surround", $F0
SkillName_025_PanicAll: db "PanicAll", $F0
SkillName_026_RobMagic: db "RobMagic", $F0
SkillName_027_TakeMagic: db "TakeMagic", $F0
SkillName_028_Sap: db "Sap", $F0
SkillName_029_Defence: db "Defence", $F0
SkillName_030_Upper: db "Upper", $F0
SkillName_031_Increase: db "Increase", $F0
SkillName_032_Slow: db "Slow", $F0
SkillName_033_SlowAll: db "SlowAll", $F0
SkillName_034_Speed: db "Speed", $F0
SkillName_035_SpeedUp: db "SpeedUp", $F0
SkillName_036_Barrier: db "Barrier", $F0
SkillName_037_TwinHits: db "TwinHits", $F0
SkillName_038_MagicWall: db "MagicWall", $F0
SkillName_039_MagicBack: db "MagicBack", $F0
SkillName_040_Bounce: db "Bounce", $F0
SkillName_041_Transform: db "Transform", $F0
SkillName_042_Ironize: db "Ironize", $F0
SkillName_043_Heal: db "Heal", $F0
SkillName_044_HealMore: db "HealMore", $F0
SkillName_045_HealAll: db "HealAll", $F0
SkillName_046_HealUs: db "HealUs", $F0
SkillName_047_HealUsAll: db "HealUsAll", $F0
SkillName_048_Vivify: db "Vivify", $F0
SkillName_049_Revive: db "Revive", $F0
SkillName_050_Farewell: db "Farewell", $F0
SkillName_051_Antidote: db "Antidote", $F0
SkillName_052_NumbOff: db "NumbOff", $F0
SkillName_053_DeChaos: db "DeChaos", $F0
SkillName_054_CurseOff: db "CurseOff", $F0
SkillName_055_StepGuard: db "StepGuard", $F0
SkillName_056_MapMagic: db "MapMagic", $F0
SkillName_057_Chance: db "Chance", $F0
SkillName_058_Attack: db "Attack", $F0
SkillName_059_TwinSlash: db "TwinSlash", $F0
SkillName_060_Ramming: db "Ramming", $F0
SkillName_061_Beserker: db "Beserker", $F0
SkillName_062_Kamikaze: db "Kamikaze", $F0
SkillName_063_Massacre: db "Massacre", $F0
SkillName_064_EvilSlash: db "EvilSlash", $F0
SkillName_065_ChargeUP: db "ChargeUP", $F0
SkillName_066_HighJump: db "HighJump", $F0
SkillName_067_SuckAir: db "SuckAir", $F0
SkillName_068_FireSlash: db "FireSlash", $F0
SkillName_069_BoltSlash: db "BoltSlash", $F0
SkillName_070_VacuSlash: db "VacuSlash", $F0
SkillName_071_IceSlash: db "IceSlash", $F0
SkillName_072_MetalCut: db "MetalCut", $F0
SkillName_073_DrakSlash: db "DrakSlash", $F0
SkillName_074_BeastCut: db "BeastCut", $F0
SkillName_075_BirdBlow: db "BirdBlow", $F0
SkillName_076_DevilCut: db "DevilCut", $F0
SkillName_077_ZombieCut: db "ZombieCut", $F0
SkillName_078_CleanCut: db "CleanCut", $F0
SkillName_079_MultiCut: db "MultiCut", $F0
SkillName_080_BiAttack: db "BiAttack", $F0
SkillName_081_QuadHits: db "QuadHits", $F0
SkillName_082_CallHelp: db "CallHelp", $F0
SkillName_083_YellHelp: db "YellHelp", $F0
SkillName_084_Focus: db "Focus", $F0
SkillName_085_SquallHit: db "SquallHit", $F0
SkillName_086_PsycheUp: db "PsycheUp", $F0
SkillName_087_RainSlash: db "RainSlash", $F0
SkillName_088_WindBeast: db "WindBeast", $F0
SkillName_089_Vacuum: db "Vacuum", $F0
SkillName_090_Lightning: db "Lightning", $F0
SkillName_091_RockThrow: db "RockThrow", $F0
SkillName_092_FireAir: db "FireAir", $F0
SkillName_093_BlazeAir: db "BlazeAir", $F0
SkillName_094_Scorching: db "Scorching", $F0
SkillName_095_WhiteFire: db "WhiteFire", $F0
SkillName_096_FrigidAir: db "FrigidAir", $F0
SkillName_097_IceAir: db "IceAir", $F0
SkillName_098_IceStorm: db "IceStorm", $F0
SkillName_099_WhiteAir: db "WhiteAir", $F0
SkillName_100_Hellblast: db "Hellblast", $F0
SkillName_101_BigBang: db "BigBang", $F0
SkillName_102_MegaMagic: db "MegaMagic", $F0
SkillName_103_PoisonHit: db "PoisonHit", $F0
SkillName_104_NapAttack: db "NapAttack", $F0
SkillName_105_Paralyze: db "Paralyze", $F0
SkillName_106_SleepAir: db "SleepAir", $F0
SkillName_107_PalsyAir: db "PalsyAir", $F0
SkillName_108_PoisonGas: db "PoisonGas", $F0
SkillName_109_PoisonAir: db "PoisonAir", $F0
SkillName_110_PaniDance: db "PaniDance", $F0
SkillName_111_Curse: db "Curse", $F0
SkillName_112_Ahhh: db "Ahhh", $F0
SkillName_113_KODance: db "K.O.Dance", $F0
SkillName_114_SandStorm: db "SandStorm", $F0
SkillName_115_Radiant: db "Radiant", $F0
SkillName_116_EerieLite: db "EerieLite", $F0
SkillName_117_OddDance: db "OddDance", $F0
SkillName_118_RobDance: db "RobDance", $F0
SkillName_119_SideStep: db "SideStep", $F0
SkillName_120_LureDance: db "LureDance", $F0
SkillName_121_LushLicks: db "LushLicks", $F0
SkillName_122_SickLick: db "SickLick", $F0
SkillName_123_LegSweep: db "LegSweep", $F0
SkillName_124_BigTrip: db "BigTrip", $F0
SkillName_125_WarCry: db "WarCry", $F0
SkillName_126_Whistle: db "Whistle", $F0
SkillName_127_Imitate: db "Imitate", $F0
SkillName_128_DeMagic: db "DeMagic", $F0
SkillName_129_Surge: db "Surge", $F0
SkillName_130_UltraDown: db "UltraDown", $F0
SkillName_131_ThickFog: db "ThickFog", $F0
SkillName_132_TatsuCall: db "TatsuCall", $F0
SkillName_133_DiagoCall: db "DiagoCall", $F0
SkillName_134_SamsiCall: db "SamsiCall", $F0
SkillName_135_BazooCall: db "BazooCall", $F0
SkillName_136_Cover: db "Cover", $F0
SkillName_137_Guardian: db "Guardian", $F0
SkillName_138_TailWind: db "TailWind", $F0
SkillName_139_StormWind: db "StormWind", $F0
SkillName_140_Dodge: db "Dodge", $F0
SkillName_141_Defence: db "Defence", $F0
SkillName_142_StrongD: db "StrongD", $F0
SkillName_143_SuckAll: db "SuckAll", $F0
SkillName_144_BladeD: db "BladeD", $F0
SkillName_145_DanceShut: db "DanceShut", $F0
SkillName_146_MouthShut: db "MouthShut", $F0
SkillName_147_Meditate: db "Meditate", $F0
SkillName_148_Hustle: db "Hustle", $F0
SkillName_149_LifeSong: db "LifeSong", $F0
SkillName_150_LifeDance: db "LifeDance", $F0
SkillName_151_Run: db "Run", $F0
SkillName_152_Daze: db "Daze", $F0
SkillName_153_HitAlly: db "HitAlly", $F0
SkillName_154_HitEnemy: db "HitEnemy", $F0
SkillName_155_HitRandom: db "HitRandom", $F0
SkillName_156_Scared: db "Scared", $F0
SkillName_157_Dance: db "Dance", $F0
SkillName_158_Trip: db "Trip", $F0
SkillName_159_Paralyze: db "Paralyze", $F0
SkillName_160_CANTMOVE: db "CANTMOVE", $F0
SkillName_161_RUN: db "RUN", $F0
SkillName_162_CALLHOROR: db "CALLHOROR", $F0
SkillName_163_HealUsAll: db "HealUsAll", $F0
SkillName_164_Smashed: db "Smashed", $F0
SkillName_165_FILTHZONE: db "FILTHZONE", $F0
SkillName_166_ALLCHANGE: db "ALLCHANGE", $F0
SkillName_167_BIGSLEEP: db "BIGSLEEP", $F0
SkillName_168_MP0: db "MP0", $F0
SkillName_169_ECHO: db "ECHO", $F0
SkillName_170_CHGDRAGON: db "CHGDRAGON", $F0
SkillName_171_CALLEVIL: db "CALLEVIL", $F0
SkillName_172_FREEZY: db "FREEZY", $F0
SkillName_173_ALLREVIVE: db "ALLREVIVE", $F0
SkillName_174_RESTOREMP: db "RESTOREMP", $F0
SkillName_175_METEOR: db "METEOR", $F0
SkillName_176_HERB: db "HERB", $F0
SkillName_177_HEALWATER: db "HEALWATER", $F0
SkillName_178_SAGESTONE: db "SAGESTONE", $F0
SkillName_179_WARLDDEW: db "WARLDDEW", $F0
SkillName_180_POTION: db "POTION", $F0
SkillName_181_ELFWATER: db "ELFWATER", $F0
SkillName_182_ANTIDOTE: db "ANTIDOTE", $F0
SkillName_183_MOONHERB: db "MOONHERB", $F0
SkillName_184_SKYBELL: db "SKYBELL", $F0
SkillName_185_LAUREL: db "LAUREL", $F0
SkillName_186_AWAKESAND: db "AWAKESAND", $F0
SkillName_187_WARLDLEAF: db "WARLDLEAF", $F0
SkillName_188_LIFEACORN: db "LIFEACORN", $F0
SkillName_189_MYSTICNUT: db "MYSTICNUT", $F0
SkillName_190_PWRSEED: db "PWRSEED", $F0
SkillName_191_DEFSEED: db "DEFSEED", $F0
SkillName_192_AGILSEED: db "AGILSEED", $F0
SkillName_193_INTSEED: db "INTSEED", $F0
SkillName_194_FEEDMEAT: db "FEEDMEAT", $F0
SkillName_195_BEFFJERKY: db "BEFFJERKY", $F0
SkillName_196_PORKCHOP: db "PORKCHOP", $F0
SkillName_197_BADMEAT: db "BADMEAT", $F0
SkillName_198_SIRLOIN: db "SIRLOIN", $F0
SkillName_199_BOLTSTAFF: db "BOLTSTAFF", $F0
SkillName_200_STAFF: db "STAFF", $F0
SkillName_201_BLOKSTAFF: db "BLOKSTAFF", $F0
SkillName_202_LAVASTAFF: db "LAVASTAFF", $F0
SkillName_203_SNOWSTAFF: db "SNOWSTAFF", $F0
SkillName_204_FIRESTAFF: db "FIRESTAFF", $F0
SkillName_205_WARPWING: db "WARPWING", $F0
SkillName_206_TINYMEDAL: db "TINYMEDAL", $F0
SkillName_207_QuestBk: db "QuestBk", $F0
SkillName_208_HORRORBK: db "HORRORBK", $F0
SkillName_209_BENICEBK: db "BENICEBK", $F0
SkillName_210_CHEATERBK: db "CHEATERBK", $F0
SkillName_211_SMARTBK: db "SMARTBK", $F0
SkillName_212_COMEDYBK: db "COMEDYBK", $F0
SkillName_213_BeDragon: db "BeDragon", $F0
SkillName_214_Smashlime: db "Smashlime", $F0
SkillName_215_Sheldodge: db "Sheldodge", $F0
SkillName_216_Branching: db "Branching", $F0
SkillName_217_GigaSlash: db "GigaSlash", $F0
SkillName_218_LIFE: db "LIFE", $F0
SkillName_219_RUN: db "RUN", $F0
SkillName_220_IRONIZE: db "IRONIZE", $F0
SkillName_221_Ahhh: db "Ahhh", $F0
SkillName_222_Unused_222: db $F0
SkillName_223_DS: db "DS", $F0
SkillName_224_SP: db "SP", $F0
SkillName_225_WS: db "WS", $F0
SkillName_226_TS: db "TS", $F0
SkillName_227_SN: db "SN", $F0
SkillName_228_KN: db "KN", $F0
SkillName_229_BB: db "BB", $F0
SkillName_230_BX: db "BX", $F0
SkillName_231_SL: db "SL", $F0
SkillName_232_HL: db "HL", $F0
SkillName_233_FS: db "FS", $F0
SkillName_234_RS: db "RS", $F0
SkillName_235_SB: db "SB", $F0
SkillName_236_ST: db "ST", $F0
SkillName_237_SK: db "SK", $F0
SkillName_238_KS: db "KS", $F0
SkillName_239_MK: db "MK", $F0
SkillName_240_MB: db "MB", $F0
SkillName_241_MT: db "MT", $F0
SkillName_242_GS: db "GS", $F0
SkillName_243_DK: db "DK", $F0
SkillName_244_TG: db "TG", $F0
SkillName_245_PT: db "PT", $F0
SkillName_246_BG: db "BG", $F0
SkillName_247_BD: db "BD", $F0
SkillName_248_LM: db "LM", $F0
SkillName_249_PG: db "PG", $F0
SkillName_250_SD: db "SD", $F0
SkillName_251_DR: db "DR", $F0
SkillName_252_MD: db "MD", $F0
SkillName_253_DK: db "DK", $F0
SkillName_254_RB: db "RB", $F0
SkillName_255_CH: db "CH", $F0

; Unknown string data ($6A55-$6A83)
    db $2F, $29, $F0, $24, $27, $F0, $2F, $26, $F0, $36, $36, $F0, $2A, $27, $F0, $26  ; $6A55
    db $33, $F0, $3A, $36, $F0, $26, $37, $F0, $32, $35, $F0, $25, $35, $F0, $36, $27  ; $6A65
    db $F0, $27, $2A, $F0, $37, $2A, $F0, $2B, $25, $F0, $26, $29, $F0, $33, $35  ; $6A75

jr_041_6a84:
    ldh a, [$36]
    ld h, $f0
    ld a, [hl+]
    dec h
    ldh a, [$36]
    cpl

jr_041_6a8d:
    ldh a, [$3a]
    dec h

jr_041_6a90:
    ldh a, [rNR50]
    jr z, jr_041_6a84

    ld [hl], $37
    ldh a, [$2c]
    scf
    ldh a, [$30]
    jr nc, jr_041_6a8d

    dec hl
    jr nc, jr_041_6a90

    ld a, [hl+]
    dec a
    ldh a, [$3c]
    scf
    ldh a, [$30]
    ld a, [hl+]
    ldh a, [$29]
    dec [hl]
    ldh a, [$38]
    ld h, $f0
    ld a, [hl+]
    ld a, [hl+]
    ldh a, [$2e]
    inc h

jr_041_6ab4:
    ldh a, [$37]
    inc sp
    ldh a, [$2e]
    cpl
    ldh a, [$27]
    dec hl
    ldh a, [$30]
    ld h, $f0
    dec h
    jr z, jr_041_6ab4

    inc sp
    ld l, $f0
    ld a, [hl-]
    add hl, sp
    ldh a, [rNR51]
    dec h
    ldh a, [$29]
    dec l
    ldh a, [$27]
    ld l, $f0
    jr nc, @+$35

    ldh a, [$30]
    dec [hl]
    ldh a, [$30]
    ld a, [hl-]
    ldh a, [$27]
    ld l, $f0
    dec h
    dec [hl]
    ldh a, [$36]
    dec h
    ldh a, [$2f]
    ld [hl-], a
    ldh a, [$30]
    ld a, [hl+]
    ldh a, [$30]
    ld h, $f0
    dec h
    dec a
    ldh a, [$33]
    ld sp, $37f0
    dec hl
    ldh a, [$3a]
    dec hl

jr_041_6af9:
    ldh a, [$29]
    dec h
    ldh a, [$35]
    dec h
    ldh a, [$30]
    inc sp
    ldh a, [$29]
    ld a, [hl-]
    ldh a, [$29]
    jr nc, jr_041_6af9

    ld a, [hl-]
    scf
    ldh a, [rNR52]
    dec h
    ldh a, [$2a]
    inc sp
    ldh a, [$29]
    ld a, [hl+]
    ldh a, [rNR50]
    ld a, [hl-]
    ldh a, [$36]
    ld [hl], $f0
    ld [hl-], a
    ld sp, $27f0
    add hl, sp
    ldh a, [$37]
    dec h

jr_041_6b23:
    ldh a, [$29]
    scf
    ldh a, [$2b]
    jr nc, @-$0e

    dec h
    jr nc, @-$0e

    jr z, @+$38

    ldh a, [$30]
    jr z, jr_041_6b23

    ld [hl], $33
    ldh a, [$32]
    add hl, sp
    ldh a, [$3a]
    scf
    ldh a, [$2a]
    ld [hl], $f0
    ld h, $33
    ldh a, [$2a]
    ld h, $f0
    dec h
    add hl, hl
    ldh a, [$3a]
    dec h
    ldh a, [$2a]
    ld a, [hl-]

jr_041_6b4d:
    ldh a, [$2f]
    inc sp
    ldh a, [$36]
    dec h
    ldh a, [rNR50]
    inc h

jr_041_6b56:
    ldh a, [$2a]
    dec hl
    ldh a, [$37]
    jr z, jr_041_6b4d

    inc h
    inc sp
    ldh a, [$28]
    daa
    ldh a, [$2a]
    jr nc, jr_041_6b56

    daa
    dec [hl]
    ldh a, [rNR50]
    ld h, $f0
    jr nc, @+$2d

    ldh a, [$2b]
    dec h
    ldh a, [rNR50]
    inc sp

jr_041_6b74:
    ldh a, [$27]
    ld a, [hl+]

jr_041_6b77:
    ldh a, [$33]
    dec sp
    ldh a, [rNR50]
    daa
    ldh a, [rNR50]
    daa
    ldh a, [$27]
    jr nc, jr_041_6b74

    daa
    jr z, jr_041_6b77

    jr z, @+$27

    ldh a, [rNR51]
    dec [hl]
    ldh a, [$28]
    dec h
    ldh a, [rSB]
    jr z, @-$0e

    ld a, [hl+]
    dec [hl]
    ldh a, [$30]
    daa
    ldh a, [$2f]
    dec sp
    ldh a, [$2a]
    dec hl
    ldh a, [$32]
    ld h, $f0
    ld [hl-], a
    ld a, [hl+]
    ldh a, [$2a]
    ld a, [hl+]
    ldh a, [rNR52]
    ld h, $f0
    ld a, [hl+]
    dec [hl]
    ldh a, [rNR50]
    ld l, $f0
    jr nc, @+$30

    ldh a, [$2a]
    ld a, [hl+]
    ldh a, [rNR52]
    ld [hl], $f0
    jr z, jr_041_6be0

    ldh a, [$2d]
    inc h
    ldh a, [$27]
    dec [hl]

jr_041_6bc2:
    ldh a, [$36]
    inc sp
    ldh a, [$36]
    ld l, $f0
    daa
    dec a
    ldh a, [$35]
    dec [hl]
    ldh a, [$30]
    jr nc, jr_041_6bc2

    daa
    ld h, $f0
    daa
    ld sp, $36f0
    dec hl

jr_041_6bda:
    ldh a, [$33]
    scf
    ldh a, [$30]
    daa

jr_041_6be0:
    ldh a, [$31]
    ld a, [hl-]
    ldh a, [$28]
    ld [hl], $f0
    ld a, [hl-]
    jr nc, jr_041_6bda

    ld [hl], $37
    ldh a, [$27]
    ld sp, $2cf0
    ld l, $f0
    dec h
    ld [hl], $f0
    ld [hl], $2e
    ldh a, [$36]
    add hl, sp
    ldh a, [rNR52]
    ld h, $f0
    dec l
    dec h
    ldh a, [$28]
    ld a, [hl-]

jr_041_6c04:
    ldh a, [$30]
    ld h, $f0
    ld h, $25
    ldh a, [$30]
    ld l, $f0
    ld [hl], $25

jr_041_6c10:
    ldh a, [$30]
    jr nc, jr_041_6c04

    dec [hl]
    inc h

jr_041_6c16:
    ldh a, [$30]
    dec hl
    ldh a, [$39]
    daa
    ldh a, [$27]
    jr nc, jr_041_6c10

    dec h
    dec a
    ldh a, [$36]
    jr nc, jr_041_6c16

    ld h, $2f
    ldh a, [$2e]
    dec h
    ldh a, [$28]
    inc sp
    ldh a, [$2a]
    dec a
    ldh a, [$2f]
    jr nc, @-$0e

    inc l
    ld h, $f0
    jr nc, jr_041_6c6a

    ldh a, [$30]
    daa
    ldh a, [$2a]
    cpl
    ldh a, [$30]
    ld [hl], $f0
    dec h
    ld h, $f0
    ld a, [hl+]
    ld a, [hl+]

jr_041_6c49:
    ldh a, [$27]
    cpl

jr_041_6c4c:
    ldh a, [$27]
    cpl
    ldh a, [$2b]
    ld a, [hl+]
    ldh a, [$36]
    daa
    ldh a, [rNR51]
    jr nc, jr_041_6c49

    dec a
    jr nc, jr_041_6c4c

    inc sp
    dec a

jr_041_6c5e:
    ldh a, [$28]
    ld [hl], $f0
    jr nc, jr_041_6c8b

jr_041_6c64:
    ldh a, [$30]
    daa
    ldh a, [$30]
    daa

jr_041_6c6a:
    ldh a, [$27]
    jr nc, jr_041_6c5e

    daa
    jr nc, @-$0e

    daa
    jr nc, jr_041_6c64

    daa
    daa
    ldh a, [$f0]
    dec hl
    ld b, d
    ld c, a
    ccf
    ldh a, [$2f]
    ld c, h
    ld d, e
    ld b, d
    ld d, h
    ld a, $51
    ld b, d
    ld c, a
    ldh a, [$36]
    ld a, $44
    ld b, d

jr_041_6c8b:
    ld [hl], $51
    ld c, h
    ld c, e
    ld b, d
    ldh a, [$3a]
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    daa
    ld b, d
    ld d, h
    ldh a, [$33]
    ld c, h
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ldh a, [$28]
    ld c, c
    ld b, e
    ld a, [hl-]
    ld a, $51
    ld b, d
    ld c, a
    ldh a, [rNR50]
    ld c, e
    ld d, c
    ld b, [hl]
    ld b, c
    ld c, h
    ld d, c
    ld b, d
    ldh a, [$30]
    ld c, h
    ld c, h
    ld c, e
    dec hl
    ld b, d
    ld c, a
    ccf
    ldh a, [$36]
    ld c, b
    ld d, [hl]
    dec h
    ld b, d
    ld c, c
    ld c, c
    ldh a, [$2f]
    ld a, $52
    ld c, a
    ld b, d
    ld c, c
    ldh a, [rNR50]
    ld d, h
    ld a, $48
    ld b, d
    ld [hl], $3e
    ld c, e
    ld b, c
    ldh a, [$3a]
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    cpl
    ld b, d
    ld a, $43
    ldh a, [$2f]
    ld b, [hl]
    ld b, e
    ld b, d
    inc h
    ld b, b
    ld c, h
    ld c, a
    ld c, e
    ldh a, [$30]
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld sp, $5152
    ldh a, [rNR50]
    scf
    ld l, $50
    ld b, d
    ld b, d
    ld b, c
    ldh a, [$27]
    jr z, jr_041_6d27

    ld d, b
    ld b, d
    ld b, d
    ld b, c
    ldh a, [rNR50]
    ld a, [hl+]
    cpl
    ld d, b
    ld b, d
    ld b, d
    ld b, c
    ldh a, [$2c]
    ld sp, $5037
    ld b, d
    ld b, d
    ld b, c
    ldh a, [rNR51]
    ld b, d
    ld b, d
    ld b, e
    dec l
    ld b, d
    ld c, a
    ld c, b
    ld d, [hl]
    ldh a, [$33]
    ld c, h
    ld c, a
    ld c, b
    ld h, $45
    ld c, h
    ld c, l
    ldh a, [$35]

jr_041_6d27:
    ld b, [hl]
    ccf
    ldh a, [rNR51]
    ld a, $41
    jr nc, jr_041_6d71

    ld a, $51
    ldh a, [$36]
    ld b, [hl]
    ld c, a
    ld c, c
    ld c, h
    ld b, [hl]
    ld c, e
    ldh a, [rNR51]
    ld c, h
    ld c, c
    ld d, c
    ld [hl], $51
    ld a, $43
    ld b, e
    ldh a, [$3a]
    ld b, [hl]
    ld c, e
    ld b, c
    ld [hl], $51
    ld a, $43
    ld b, e
    ldh a, [$30]
    ld b, [hl]
    ld d, b
    ld d, c
    ld [hl], $51
    ld a, $43
    ld b, e
    ldh a, [$2f]
    ld a, $53
    ld a, $36
    ld d, c
    ld a, $43
    ld b, e
    ldh a, [$36]
    ld c, e
    ld c, h
    ld d, h
    ld [hl], $51
    ld a, $43
    ld b, e
    ldh a, [$3a]
    ld a, $4f
    ld c, l
    ld a, [hl-]

jr_041_6d71:
    ld b, [hl]
    ld c, e
    ld b, h
    ldh a, [$37]
    ld b, [hl]
    ld c, e
    ld d, [hl]
    jr nc, jr_041_6dbd

    ld b, c
    ld a, $49
    ldh a, [$34]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    dec h
    ld c, b
    ldh a, [$2b]
    ld c, h
    ld c, a
    ld c, a
    ld c, h
    ld c, a
    dec h
    ld l, $f0
    dec h
    ld b, d
    ld sp, $4046
    ld b, d
    dec h
    ld l, $f0
    ld h, $45
    ld b, d
    ld a, $51
    ld b, d
    ld c, a
    dec h
    ld l, $f0
    ld [hl], $4a
    ld a, $4f
    ld d, c
    dec h
    ld l, $f0
    ld h, $4c
    ld c, d
    ld b, d
    ld b, c
    ld d, [hl]
    dec h
    ld l, $f0
    add hl, hl
    ld b, [hl]
    ld c, a
    ld b, d
    ld [hl], $51
    ld a, $43
    ld b, e

jr_041_6dbd:
    ldh a, [rNR51]
    ld b, d
    ld a, $50
    ld d, c
    scf
    ld a, $46
    ld c, c
    ldh a, [$3a]
    ld a, $4f
    ld c, l
    ld [hl], $51
    ld a, $43
    ld b, e
    ldh a, [$35]
    ld b, d
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld b, d
    ld c, e
    ld d, c
    ldh a, [$36]
    ld b, l
    ld b, [hl]
    ld c, e
    ld d, [hl]
    dec hl
    ld a, $4f
    ld c, l
    ldh a, [$30]
    ld a, $4d
    dec hl
    ld b, d
    ld c, a
    ccf
    ldh a, [rNR51]
    ld c, h
    ld c, h
    ld c, b
    jr nc, @+$40

    ld c, a
    ld c, b
    ldh a, [$f0]
    dec [hl]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, h
    ld b, d
    ld b, d
    ld c, e
    pop af
    inc bc
    nop
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    inc b
    nop
    ld h, d
    dec hl
    inc sp
    ldh a, [$35]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, h
    ld b, d
    ld b, d
    ld c, e
    pop af
    ld b, $00
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    rlca
    nop
    ld h, d
    dec hl
    inc sp
    ldh a, [$35]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld b, $00
    ld h, d
    ld d, c
    ld c, h
    pop af
    rlca
    nop
    ld h, d
    dec hl
    inc sp
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld a, $49
    ld c, c
    ldh a, [$35]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    pop af
    ld c, d
    ld a, $55
    ld h, d
    dec hl
    inc sp
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld a, $49
    ld c, c
    ldh a, [$35]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, h
    ld b, d
    ld b, d
    ld c, e
    pop af
    ld [bc], a
    nop
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    inc bc
    nop
    ld h, d
    jr nc, jr_041_6eb6

    ldh a, [$35]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    jr nc, jr_041_6ec2

    ld h, d
    ld d, c
    ld c, h
    pop af
    ld c, d
    ld a, $55
    ldh a, [rNR52]
    ld d, d
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    pop af
    ldh a, [rNR52]
    ld d, d
    ld c, a
    ld b, d
    ld d, b
    pop af
    ld c, l
    ld a, $4f
    ld a, $49
    ld d, [hl]
    ld d, b
    ld b, [hl]
    ld d, b
    ldh a, [rNR52]

jr_041_6eb6:
    ld d, d
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld b, e
    ld d, d
    ld d, b
    ld b, [hl]

jr_041_6ec2:
    ld c, h
    ld c, e
    pop af
    ldh a, [rNR51]
    ld c, a
    ld b, d
    ld a, $48
    ld d, b
    ld h, d
    ld a, $62
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ldh a, [$3a]
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ldh a, [$35]
    ld b, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ldh a, [$2c]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    ld h, d
    ld c, d
    ld a, $55
    ld h, d
    dec hl
    inc sp
    pop af
    ccf
    ld d, [hl]
    ld h, d
    dec b
    ldh a, [$2c]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    ld h, d
    ld c, d
    ld a, $55
    ld h, d
    jr nc, jr_041_6f4f

    pop af
    ccf
    ld d, [hl]
    ld h, d
    dec b
    ldh a, [$2c]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    ld h, d
    inc h
    scf
    scf
    inc h
    ld h, $2e
    pop af
    inc sp
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    inc bc
    ldh a, [$2c]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    ld h, d
    daa
    jr z, jr_041_6f74

    jr z, jr_041_6f7e

    ld [hl], $28

jr_041_6f4f:
    pop af
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    inc bc
    ldh a, [$2c]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    ld h, d
    inc h
    ld a, [hl+]
    inc l
    cpl
    inc l
    scf
    inc a
    ld h, d
    pop af
    ccf
    ld d, [hl]
    ld h, d
    inc bc
    ldh a, [$2c]

jr_041_6f74:
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    pop af
    inc l

jr_041_6f7e:
    ld sp, $2837
    cpl
    cpl
    inc l
    ld a, [hl+]
    jr z, jr_041_6fb8

    ld h, $28
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    inc bc
    ldh a, [$37]
    ld a, $4a
    ld b, d
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    pop af
    ldh a, [$30]
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld a, $62
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c

jr_041_6fb8:
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld c, h
    ld c, c
    ld d, c
    ldh a, [$30]
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld a, $62
    ld d, e
    ld a, $40
    ld d, d
    ld d, d
    ld c, d
    ldh a, [rNR51]
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld d, b
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    pop af
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, c
    ldh a, [$30]
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld c, d
    ld a, $44
    ld c, d
    ld a, $f0
    jr nc, jr_041_704f

    ld c, b
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld a, $62
    ld d, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld c, d
    ldh a, [$3a]
    ld a, $4f
    ld c, l
    ld d, b
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld b, b
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld d, c
    ld a, $4b
    ld d, c
    ld c, c
    ld d, [hl]
    ldh a, [rNR52]
    ld c, h

jr_041_704f:
    ld c, c
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld b, d
    ld d, l
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ldh a, [rNR52]
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld l, b
    pop af
    inc sp
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, $49
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ldh a, [rNR51]
    ld d, d
    ld c, a
    ld c, e
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld a, $62
    ld c, d
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld d, [hl]
    ld h, d
    ccf
    ld c, c
    ld a, $57
    ld b, d
    ldh a, [$33]
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld a, $56
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld a, $62
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ldh a, [$3a]
    ld a, $4f
    ld c, l
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $f1
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ldh a, [$35]
    ld b, d
    ld c, l
    ld b, d
    ld c, c
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ldh a, [rNR50]
    ld d, c
    ld d, c
    ld c, a
    ld a, $40
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    pop af
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld b, d
    ld c, c
    ld c, h
    ld b, c
    ld d, [hl]
    ldh a, [$2f]
    ld b, d
    ld d, c
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, a
    ld b, d
    ld h, d
    ld c, c
    ld a, $4b
    ld b, c
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ldh a, [$35]
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld b, h
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ldh a, [$2b]
    ld [hl-], a
    scf
    dec h
    cpl
    ld [hl-], a
    ld [hl-], a
    daa
    ldh a, [$27]
    inc h
    dec [hl]
    inc l
    ld sp, $f02a
    daa
    inc h
    dec [hl]
    jr z, jr_041_7195

    jr z, @+$3b

    inc l
    cpl
    ldh a, [$2f]
    ld [hl-], a
    ld sp, $6228
    ld a, [hl-]
    ld [hl-], a
    cpl
    add hl, hl
    ldh a, [$39]
    inc h
    inc l
    ld sp, $28f0
    dec a
    ld h, d
    ld a, [hl+]
    ld [hl-], a
    inc l
    ld sp, $f02a
    ld [hl], $30
    jr c, jr_041_71b9

    ldh a, [$36]
    ld sp, $2532
    dec h

jr_041_7195:
    inc a
    ldh a, [$35]
    jr z, jr_041_71c0

jr_041_719a:
    ld l, $2f
    jr z, jr_041_71d4

    ld [hl], $f0
    ld h, $32
    ld [hl-], a
    cpl
    sbc [hl]
    ld h, $24
    cpl
    jr nc, jr_041_719a

    ld a, [hl-]
    dec hl
    inc l
    jr nc, @+$38

    inc a
    ldh a, [$31]
    ld [hl-], a
    ld [hl], $3c
    ldh a, [$3a]
    dec hl
    inc l

jr_041_71b9:
    dec a
    ld h, d
    ld l, $2c
    daa
    ldh a, [$32]

jr_041_71c0:
    dec [hl]
    daa
    inc l
    ld sp, $3524
    inc a
    ldh a, [$2b]
    inc h
    ld [hl], $37
    inc a
    ldh a, [$36]
    scf
    jr c, jr_041_71f7

    dec h
    ld [hl-], a

jr_041_71d4:
    dec [hl]
    ld sp, $35f0
    jr z, jr_041_71ff

    jr z, @+$31

    ldh a, [$36]
    inc sp
    ld [hl-], a
    inc l
    cpl
    jr z, @+$29

    ldh a, [$2b]
    jr c, @+$32

    inc h
    ld sp, $f028
    jr c, jr_041_721f

    ld h, $28
    dec [hl]
    scf
    inc h
    inc l
    ld sp, $26f0

jr_041_71f7:
    inc h
    dec [hl]
    jr z, jr_041_722a

    jr z, jr_041_7233

    ld [hl], $f0

jr_041_71ff:
    ld [hl], $2b
    dec [hl]
    jr z, jr_041_723e

    jr z, jr_041_722d

    ldh a, [rNR52]
    inc h

jr_041_7209:
    dec [hl]
    jr z, jr_041_7235

    dec [hl]
    jr z, @+$2a

    ldh a, [$2a]
    jr c, @+$31

    cpl
    inc l
    dec h
    cpl
    jr z, jr_041_7209

    ld [hl], $2f
    inc a
    ldh a, [rNR52]
    ld [hl-], a

jr_041_721f:
    ld a, [hl-]
    inc h

jr_041_7221:
    dec [hl]
    daa
    ldh a, [$2f]
    inc h
    dec a
    inc a
    ldh a, [rNR52]

jr_041_722a:
    dec hl
    inc h
    dec [hl]

jr_041_722d:
    ld a, [hl+]
    jr z, jr_041_7221

    jr nc, @+$2e

    dec sp

jr_041_7233:
    jr z, jr_041_725c

jr_041_7235:
    pop af
    ld h, $24
    jr c, jr_041_7271

    inc l
    ld [hl-], a
    jr c, jr_041_7274

jr_041_723e:
    pop af
    ld h, $32
    jr nc, jr_041_7273

    inc h
    ld sp, $f027
    ld sp, hl
    nop
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    cpl
    add hl, sp
    ld h, d
    ld sp, hl
    db $10

jr_041_725c:
    ld h, e
    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d

jr_041_7271:
    cpl
    add hl, sp

jr_041_7273:
    ld h, d

jr_041_7274:
    ld sp, hl
    db $10
    ld a, [$f2f7]
    ld a, $4b
    ld b, c
    ld h, d
    ld c, c
    ld b, d
    ld a, $4f
    ld c, e
    ld b, d
    ld b, c

jr_041_7284:
    pop af
    ld sp, hl
    jr nz, jr_041_72eb

    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    ld l, b
    ld h, d
    ld sp, hl
    jr nc, jr_041_7284

    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    jr nz, jr_041_7301

    ld a, [$f0f7]
    db $ed
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld sp, hl
    nop
    pop af
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld a, [$f2f7]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, e
    pop af
    ld a, [$f2f7]
    di
    db $ed
    add hl, hl
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    pop af
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, h
    ld a, [$f0f7]
    db $ed
    ld [hl-], a
    ld l, $62
    ld d, c
    ld c, h

jr_041_72eb:
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    pop af
    ld sp, hl
    nop
    ld h, h
    ldh a, [$ed]
    add hl, hl
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld d, b
    ld h, d
    ld sp, hl

jr_041_7301:
    nop
    ld h, e
    ld a, [$f0f7]
    db $ed
    add hl, hl
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    pop af
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, h
    ld a, [$f0f7]
    jr z, jr_041_7372

    ld b, d
    ld c, a
    ld d, [hl]
    ld c, h
    ld c, e
    ld b, d
    pop af
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld a, $51
    ld h, d
    ld a, $62
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    ldh a, [$3a]
    ld b, l
    ld c, h
    ld h, d
    jr c, @+$52

    ld h, d
    scf
    ld b, l
    ld c, d
    ldh a, [$3a]
    dec hl
    ld [hl-], a
    ld [hl], $37
    dec [hl]
    ld [hl-], a
    ld l, $f0
    add hl, hl
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ldh a, [rNR13]
    rst $18
    ld [de], a
    adc l
    db $10
    ld e, $11
    db $10
    adc l
    pop de
    adc l
    db $10
    adc l
    ld h, a
    ldh a, [$ed]
    or $62
    ld c, a
    ld b, d
    ld b, b
    ld b, d
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    nop
    ld h, d
    jr z, jr_041_73c4

    ld c, l
    ld h, d
    ld c, l

jr_041_7372:
    ld d, c
    ld d, b
    ld h, e
    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, b
    ld b, d
    ld e, [hl]
    pop af
    ld c, a
    ld b, d
    ld b, b
    ld a, $49

jr_041_738c:
    ld c, c
    ld d, b
    ld h, d
    ld sp, hl
    jr nz, jr_041_738c

    rst $30
    ld a, [c]
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld b, d
    ld c, d
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, e
    pop af
    ld a, [$f0f7]
    db $ed
    ld a, [hl-]
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    ld sp, hl
    nop
    pop af
    ld b, h
    ld c, h
    ld d, c
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$f2f7]
    ld c, c
    ld c, h
    ld c, h

jr_041_73c4:
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $51
    ld h, d
    ld d, d
    ld d, b
    ld h, e
    pop af
    ld a, [$f2f7]
    db $ed
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    pop af
    ld sp, hl
    nop
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld a, [$f2f7]
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $4f
    ld d, c
    ld d, [hl]
    ld h, h
    pop af
    ldh a, [$ed]
    ld h, $3e
    ld c, e
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    pop af
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    ld a, [$f2f7]
    db $ed
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ccf
    ld d, [hl]
    ld b, d
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$f2f7]
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    pop af
    ld a, $62
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, h
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    pop af
    ld d, b
    ld a, $41
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    ld d, b
    ld e, a
    ld a, [$f0f7]
    db $ed
    ld h, $45
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld e, a
    ldh a, [$ed]
    dec [hl]
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld d, b
    ld h, d
    ld sp, hl
    nop
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld e, a
    ld a, [$f0f7]
    db $ed
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    pop af
    ld sp, hl
    nop
    ld a, [$f2f7]
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, h
    ld c, e
    pop af
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld h, h
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, l
    ld b, d
    ld a, $41
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    ld a, [$f0f7]
    db $ed
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    pop af
    ld sp, hl
    nop
    ld e, a
    ld a, [$f0f7]
    db $ed
    ld h, $45
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    pop af
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, l
    ld b, d
    ld a, $41
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    ld a, [$f0f7]
    db $ed
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$62]
    ld h, d
    ld h, d
    ld h, d
    jr nc, jr_041_7585

    ld sp, $2a28
    ld a, [hl+]
    inc l
    ld sp, $3229
    ldh a, [$ed]
    ld sp, $624c
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    ld e, a
    ld a, [$f0f7]
    db $ed
    dec [hl]
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h

jr_041_7581:
    ld b, [hl]
    ld c, c
    ld b, c
    ld e, a

jr_041_7585:
    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    jr nc, @+$40

    ld d, l
    ld h, d
    dec hl
    inc sp
    ld h, d
    and d
    ld sp, hl
    jr nz, jr_041_7581

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $3e30
    ld d, l

jr_041_75a5:
    ld h, d
    jr nc, jr_041_75db

    ld h, d
    and d
    ld sp, hl
    inc h
    ld a, [$f2f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    inc h
    scf
    ld l, $62
    and d
    ld sp, hl
    jr z, jr_041_75a5

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $2827
    add hl, hl
    ld h, d
    and d
    ld sp, hl
    inc l
    ld a, [$f2f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    inc h
    ld a, [hl+]
    cpl
    ld h, d
    and d

jr_041_75db:
    ld sp, hl
    jr nc, @-$16

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $312c
    scf

jr_041_75ea:
    ld h, d
    and d
    ld sp, hl
    inc [hl]
    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    jr nc, @+$40

    ld d, l
    ld h, d
    dec hl
    inc sp
    ld h, d
    sbc h
    ld sp, hl
    jr nz, jr_041_75ea

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $3e30
    ld d, l

jr_041_760e:
    ld h, d
    jr nc, jr_041_7644

    ld h, d
    sbc h
    ld sp, hl
    inc h
    ld a, [$f2f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    inc h
    scf
    ld l, $62
    sbc h
    ld sp, hl
    jr z, jr_041_760e

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $2827
    add hl, hl
    ld h, d
    sbc h
    ld sp, hl
    inc l
    ld a, [$f2f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    inc h
    ld a, [hl+]
    cpl
    ld h, d
    sbc h

jr_041_7644:
    ld sp, hl
    jr nc, @-$16

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $312c
    scf
    ld h, d
    sbc h
    ld sp, hl
    inc [hl]
    ld a, [$f0f7]
    db $ed
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, l
    ld a, $50
    pop af
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    pop af
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld d, b
    rst $30
    ld a, [c]
    ld sp, hl
    db $10
    ld h, e
    pop af
    ld a, [$f0f7]
    db $ed
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $4b
    pop af
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld a, $54
    ld a, $56
    ld e, a
    ldh a, [$ed]
    or $62
    ld c, a
    ld b, d
    ld b, b
    ld b, d
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    nop
    ld h, d
    jr z, jr_041_7719

    ld c, l
    ld h, d
    ld c, l
    ld d, c
    ld d, b
    ld e, a
    ld a, [$f0f7]
    db $ed
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $4f
    ld d, c
    ld d, [hl]
    ld e, a
    pop af
    ld a, [$f0f7]
    db $ed
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    ld d, b
    pop af
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d

jr_041_7719:
    ld c, e
    ld c, h
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    ld a, [$f2f7]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    pop af
    ld b, c
    ld b, [hl]
    ld d, b
    ld a, $4d

jr_041_7731:
    ld c, l
    ld b, d
    ld a, $4f
    ld d, b
    ld h, e
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    jr nz, jr_041_7731

    ld b, e
    ld a, $49
    ld c, c
    ld d, b
    ld h, d
    ld a, $4d
    ld a, $4f
    ld d, c
    ld h, e
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d

jr_041_7754:
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    jr nz, jr_041_7754

    ld a, [c]
    ld a, $50
    ld h, d
    ld a, $62
    ld d, c
    ld c, h
    ld c, h
    ld c, c
    ld e, a
    pop af
    rst $30
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld b, l
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld bc, $f962
    jr nz, jr_041_77f0

    ld c, h
    ld c, e
    rst $30
    ld a, [c]
    ld sp, hl
    db $10
    ld e, a
    pop af
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld [hl], $3e
    ld b, h
    ld b, d
    ld [hl], $51
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$f2f7]
    ld d, b
    ld c, b
    ld d, [hl]
    ld h, e
    pop af
    rst $30
    ldh a, [$f9]
    nop
    pop af
    ld d, b
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld c, b
    ld c, c
    ld b, d
    ld d, b
    rst $30
    ld a, [c]
    ld sp, hl
    jr nz, jr_041_7845

    pop af
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    pop af
    jr nc, jr_041_781e

    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h

jr_041_77f0:
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld b, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    pop af
    ld c, l
    ld a, $4f
    ld a, $49
    ld d, [hl]
    ld d, b
    ld b, [hl]
    ld d, b
    rst $30
    ld a, [c]
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld b, d
    ld b, c
    ld h, e
    pop af

jr_041_781e:
    rst $30
    ldh a, [$f9]
    db $10
    pop af
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    pop af
    ld sp, hl
    db $10
    rst $30
    ld a, [c]
    ld b, [hl]

jr_041_7845:
    ld d, b
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld c, b
    ld b, d
    ld c, e
    ld h, e
    pop af
    rst $30
    ldh a, [$f9]
    db $10
    pop af
    ld d, h
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    pop af
    ld c, a
    ld b, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    ld c, d
    ld a, $55
    ld h, d
    dec hl
    inc sp
    pop af
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_78e8

    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    ld c, d
    ld a, $55
    ld h, d
    jr nc, jr_041_78c4

    pop af
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_7903

    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    inc h
    scf
    ld l, $f1
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_791b

    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    daa
    jr z, @+$2b

    pop af
    ld b, h
    ld c, h

jr_041_78c4:
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_7933

    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    inc h
    ld a, [hl+]
    cpl
    pop af
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_794b

jr_041_78e8:
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    inc l
    ld sp, $f137
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_7963

    rst $30
    ldh a, [$f9]

jr_041_7903:
    nop
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld e, [hl]
    rst $30
    ld a, [c]
    ld a, $62
    ld sp, hl
    jr nz, jr_041_7978

    pop af
    rst $30
    ldh a, [$f9]
    db $10
    ld h, d

jr_041_791b:
    ld b, d
    ld a, $51
    ld d, b
    pop af
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, e
    rst $30
    ld a, [c]
    ld sp, hl
    db $10
    ld h, d
    ccf
    ld b, d
    ld b, h

jr_041_7933:
    ld b, [hl]
    ld c, e
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    or $63
    rst $30
    ldh a, [$f9]
    db $10
    ld h, d
    ld b, d
    ld a, $51
    ld d, b
    pop af

jr_041_794b:
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, b
    ld a, $52
    ld d, c
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld c, c
    ld d, [hl]
    ld h, e
    rst $30
    ld a, [c]
    ld sp, hl
    db $10
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, c
    ld c, h

jr_041_7963:
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld a, $56
    rst $30
    ld a, [c]
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d

jr_041_7978:
    ld a, $62
    ld b, e
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    pop af
    rst $30
    ld a, [c]
    ld sp, hl
    db $10
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    ld b, d
    ld b, c
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, c

jr_041_799b:
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld sp, hl
    jr nz, jr_041_799b

    ld a, [c]
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld d, [hl]
    ld h, e
    pop af
    rst $30
    ldh a, [rNR50]
    ld h, d
    ld d, c
    ld b, l
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld c, h
    ld c, c
    ld d, c
    pop af
    ld c, c
    ld b, d
    ld a, $4d
    ld d, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $30
    ld a, [c]
    ld d, c
    ld b, [hl]
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $43
    ld b, e
    ld h, e
    pop af
    rst $30
    ldh a, [rNR50]
    ld h, d
    ld d, e
    ld a, $40
    ld d, d
    ld d, d
    ld c, d
    ld h, d
    ld d, b
    ld d, h
    ld b, [hl]
    ld c, a
    ld c, c
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [rNR50]
    ld h, d
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, c
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld a, $63
    rst $30
    ldh a, [$2f]
    ld a, $53
    ld a, $62
    ld c, h
    ld c, h
    ld d, a
    ld b, d
    ld d, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, e
    rst $30
    ldh a, [rNR50]
    ld h, d
    ccf
    ld c, c
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld b, c
    pop af
    ld d, b
    ld d, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld d, b
    ld h, d
    ld a, $40
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, h
    ld d, b
    pop af
    ld a, $62
    ld sp, hl
    jr nz, jr_041_7ad0

    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    jr nz, jr_041_7ae1

    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld d, b
    pop af
    ld a, $62
    ld sp, hl
    jr nz, jr_041_7af0

    ld d, c
    ld c, h
    ld a, [$f2f7]
    ld sp, hl
    db $10
    ld e, a
    pop af
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld d, l
    ld b, b
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    pop af
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    db $10
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
    ccf
    ld c, a
    ld a, $53
    ld b, d
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l

jr_041_7ad0:
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, a
    ld b, [hl]
    ld b, e
    ld d, [hl]
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld d, b
    ld d, c
    ld c, h
    ld c, a

jr_041_7ae1:
    ld d, [hl]
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld a, [$f2f7]
    ld sp, hl
    db $10
    ld h, d
    ld b, [hl]
    ld c, e

jr_041_7af0:
    ld d, c
    ld c, h
    pop af
    ld a, $62
    ld b, b
    ld c, h
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld a, [$f2f7]
    ld sp, hl
    db $10
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    pop af
    ld a, $62
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld d, c
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    pop af
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    db $10
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
    ld d, b
    ld b, l
    ld c, a
    ld b, d
    ld d, h
    ld b, c
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    pop af
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    db $10
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
    ld d, b
    ld c, d
    ld a, $4f
    ld d, c
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld c, e
    ld c, e
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    pop af
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    db $10
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
    ld c, e
    ld a, $46
    ld d, e
    ld b, d
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$29]
    ld c, c
    ld a, $4a
    ld b, d
    ld d, b
    ld h, d
    ld c, c
    ld b, d
    ld a, $4d
    ld d, b
    pop af
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, l
    rst $30
    ld a, [c]
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $43
    ld b, e
    ld e, a
    pop af
    rst $30
    ldh a, [$f9]
    jr nc, jr_041_7c5c

    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ldh a, [$f9]
    jr nc, jr_041_7c6e

    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ld a, [c]
    ld sp, hl
    ld b, b
    ld l, b
    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ldh a, [$f9]
    jr nc, @+$6a

    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ld a, [c]
    ld sp, hl
    ld b, b
    ld l, b
    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ld a, [c]
    ld sp, hl
    ld d, b
    ld l, b
    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30

jr_041_7c5c:
    ldh a, [$f9]
    jr nz, jr_041_7cc2

    ld c, l
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld d, b
    pop af
    ld sp, hl
    jr nc, jr_041_7cc9

    rst $30
    ldh a, [$37]
    ld b, l

jr_041_7c6e:
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    pop af
    ld d, b
    ld b, [hl]
    ld b, h
    ld c, e
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld c, l
    ld c, c
    ld a, $56
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    jr nz, jr_041_7d05

    rst $30
    ldh a, [$36]
    ld d, c
    ld a, $4f
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, a
    ld b, d
    ld h, d
    ld c, d
    ld a, $4d
    ld h, e
    rst $30

jr_041_7cc2:
    ldh a, [$3a]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c

jr_041_7cc9:
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, h
    and $f0
    dec [hl]
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld d, b

jr_041_7d05:
    pop af
    ld sp, hl
    jr nz, @+$65

    rst $30
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld b, l
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld d, b
    ld h, e
    rst $30
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_041_7d65

    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    pop af
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, a
    ld b, d

jr_041_7d65:
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld e, a
    rst $30
    ldh a, [$f9]
    db $10
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, b
    ld d, d
    ld c, a
    ld b, d
    ld b, c
    ld e, a
    rst $30
    ldh a, [rNR52]
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld b, [hl]
    ld d, b
    rst $30
    ld a, [c]
    ccf
    ld c, a
    ld c, h
    ld c, b
    ld b, d
    ld c, e
    ld h, e
    pop af
    rst $30
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, e
    ld a, $4b
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld d, b
    pop af
    ld b, c
    ld d, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $f7
    ld a, [c]
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, b
    ld b, d
    ld h, e
    pop af
    rst $30
    ldh a, [$f9]
    nop
    pop af
    ld d, h
    ld b, l
    ld b, [hl]
    ld d, b
    ld d, c
    ld c, c
    ld b, d
    ld d, b
    ld h, e
    rst $30
    ldh a, [rNR52]
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld e, a
    rst $30
    ldh a, [rNR52]
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    pop af
    ld c, h
    ld b, e
    ld h, d
    ld a, $62
    ld c, b
    ld c, e
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    rst $30
    ld a, [c]
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    pop af
    rst $30
    ldh a, [rP1]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
