; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $05f", ROMX[$4000], BANK[$5f]

    db $5F ; Bank number

    ; Cross-bank dispatch table (11 entries)
    ; Called via: ld hl, $5FXX / rst $10
    dw $4017                          ; Entry 0
    dw $40F7                          ; Entry 1
    dw $441C                          ; Entry 2
    dw $4619                          ; Entry 3
    dw HitReactionArm                  ; Entry 4
    dw $4B1B                          ; Entry 5
    dw $52F0                          ; Entry 6 = skill VISUAL-anim dispatch by skill id $db8a (S2c): -> per-skill anim-index $5f:$58dd/$59c3/$5aa9 -> routine ptr table $5f:$58bd. See BATTLE_SKILL_SYSTEM.md S9.
    dw AnimSelectCmd                  ; Entry 7
    dw $5BB7                          ; Entry 8
    dw $5C8D                          ; Entry 9
    dw $6251                          ; Entry 10

; --- Dispatch entry 0 ($4017) ---
DispatchEntry_5F_0:
    call ClearSTATMode
    ld hl, $c817
    ld [hl], $00
    inc hl
    ld [hl], $00
    ld hl, $0801
    rst $10
    ld hl, $9800
    ld bc, $0400
    ld a, $e0
    call FillNBytesWithRegA
    ld a, [$c88b]
    rst $00
    add hl, sp
    ld b, b
    sub l
    ld b, b
    ld hl, $8000
    ld bc, $0c00
    call WriteFldUI_40eb
    ld hl, $8b00
    ld de, $1202
    call SetupVRAMCopy
    ld de, $2e00
    ld hl, $8d00
    call WaitLCDTransfer
    ld de, $66b3
    ld hl, $9800
    ld bc, TextCursorAdvance
    call SaveFldUI_424a
    xor a
    ld hl, $c0d8
    ld bc, $0028

jr_05f_4067:
    call FillNBytesWithRegA
    call LoadFldUI_439d
    call LoadFldUI_43ba
    ld a, $fc
    call SetGBCPalette
    ld a, $21
    call SetBGM
    xor a
    ldh [$b7], a
    xor a
    ldh [$bb], a
    xor a
    ld [$c8a4], a
    ld [$c8a5], a
    xor a
    ld [$c892], a
    ld a, $11
    ld [$c8a1], a
    ld a, $01
    jp EnableLCDAndInterrupts


    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld hl, $8800
    ld bc, $0800
    call WriteFldUI_40eb
    ld de, $42cf
    ld hl, $99a0
    ld bc, $1404
    call SaveFldUI_424a
    ld de, $2e00
    ld hl, $8d00
    call WaitLCDTransfer
    ld hl, $8b00
    ld de, $1202
    call SetupVRAMCopy
    ld a, $fc
    call SetGBCPalette
    ld a, $31
    call SetBGM
    xor a
    ldh [$b7], a
    xor a
    ldh [$bb], a
    xor a
    ld [$c8a4], a
    ld [$c8a5], a
    xor a
    ld [$c892], a
    ld a, $01
    ld [$c8a1], a
    ld a, $01
    jp EnableLCDAndInterrupts


WriteFldUI_40eb:
jr_05f_40eb:
    ld [hl], $ff
    inc hl
    ld [hl], $00
    inc hl
    dec bc
    ld a, b
    or c
    jr nz, jr_05f_40eb

    ret


    ld a, [$c850]
    or a
    ret nz

    ld a, [$c88b]
    rst $00
    inc b
    ld b, c
    ld [de], a
    ld b, c
    ld a, [$c0d8]
    rst $00
    jr nz, @+$43

    ld b, b
    ld b, c
    ld d, l
    ld b, c
    ld h, e
    ld b, c
    ld a, b
    ld b, c
    ld a, [$c0d8]
    rst $00
    jp c, $ed41

    ld b, c
    or $41
    db $10
    ld b, d
    ld b, h
    ld b, d
    ld hl, $c0da
    inc [hl]
    ld a, [hl]
    cp $3c
    ret c

    ld a, $00
    ld [hl+], a
    inc [hl]
    ld a, [hl]
    cp $05
    ret c

    ld [hl], $00
    ld hl, $c0d8
    inc [hl]
    ld hl, $c88f
    inc [hl]
    ld a, $04
    call SetGBCPalette
    ret


    ld hl, $c0d9
    inc [hl]
    ld a, [hl]
    cp $1a
    call z, $440f
    call LoadFldUI_439d
    call LoadFldUI_43ba
    ld hl, $c0d8
    inc [hl]
    ret


    ld hl, $0802
    rst $10
    ld a, $fc
    call SetGBCPalette
    ld hl, $c0d8
    inc [hl]
    ret


    xor a
    ld [$c88f], a
    ld a, [$c0d9]
    cp $1a
    jr z, jr_05f_4173

    xor a
    ld [$c0d8], a
    ret


jr_05f_4173:
    ld hl, $c0d8
    inc [hl]
    ret


    ld hl, $c0da
    inc [hl]
    ld a, [hl]
    cp $3c
    ret c

    ld a, $00
    ld [hl+], a
    inc [hl]
    ld a, [hl]
    cp $05
    ret c

    ld [hl], $00
    ld hl, $002f
    ld a, l
    ld [wWarpGateId], a
    ld a, h
    ld [wWarpFlag], a
    ld hl, $0038
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $00c8
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ld a, $01
    ld [wIsPlayerChangingMaps], a
    xor a
    ldh [$90], a
    xor a
    ld [wScriptStateFlags], a
    ld hl, wGameState
    res 0, [hl]
    ld a, $01
    ld [wGameMode], a
    ld a, $00
    ld [$c88b], a
    ld a, $00
    ld [$c88c], a
    ld a, $00
    ld [$c88d], a
    ld hl, $c88e
    inc [hl]
    ld a, $04
    call SetGBCPalette
    ret


    ld a, $07
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4c02
    rst $10
    ld hl, $c0d8
    inc [hl]
    ret


    xor a
    ld [$c88f], a
    ld hl, $c0d8
    inc [hl]
    ret


    ld a, [wJoypad_current_frame]
    and $0f
    ret z

    ld hl, $0256
    call SetupTilemapTransfer
    ld de, $2e07
    ld hl, $9800
    call LoadFldUI_4298
    ld hl, $c0d8
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$c83c]
    or a
    ld hl, $0258
    jr nz, jr_05f_423c

    xor a
    ldh [$90], a
    xor a
    ld [wScriptStateFlags], a
    ld a, $01
    ld [$c8ea], a
    ld hl, wGameState
    res 0, [hl]
    di
    call SaveGameState
    ei
    ld a, $59
    call PlaySoundEffect
    ld hl, $0257

jr_05f_423c:
    call SetupTilemapTransfer
    ld hl, $c0d8
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ret


SaveFldUI_424a:
jr_05f_424a:
    push bc
    push hl

jr_05f_424c:
    ld a, [de]
    call Write_gfx_tile
    inc hl
    inc de
    dec b
    jr nz, jr_05f_424c

    pop hl
    pop bc
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec c
    jr nz, jr_05f_424a

    ret


LoadFldUI_4263:
    ld a, [de]
    inc de
    ld c, a
    ld a, [de]
    inc de
    ld b, a
    add hl, bc
    ld a, l
    ld [$c0fe], a
    ld a, h
    ld [$c0ff], a

jr_05f_4272:
    ld a, [de]
    inc de
    cp $d8
    jr z, jr_05f_427e

    cp $d9
    ret z

    ld [hl+], a
    jr jr_05f_4272

jr_05f_427e:
    ld a, [$c0fe]
    ld l, a
    ld a, [$c0ff]
    ld h, a
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ld [$c0fe], a
    ld a, h
    ld [$c0ff], a
    jr jr_05f_4272

LoadFldUI_4298:
    ld a, [de]
    inc de
    ld c, a
    ld a, [de]
    inc de
    ld b, a
    add hl, bc
    ld a, l
    ld [$c0fe], a
    ld a, h
    ld [$c0ff], a

jr_05f_42a7:
    ld a, [de]
    inc de
    cp $d8
    jr z, jr_05f_42b5

    cp $d9
    ret z

    call Write_gfx_tile_and_inc_HL
    jr jr_05f_42a7

jr_05f_42b5:
    ld a, [$c0fe]
    ld l, a
    ld a, [$c0ff]
    ld h, a
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ld [$c0fe], a
    ld a, h
    ld [$c0ff], a
    jr jr_05f_42a7

    ldh [$e0], a
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
    ei
    ldh [$e0], a
    cp $b0
    or c
    or d
    ldh [$b3], a
    or h
    ldh [$b5], a
    or [hl]
    or a
    cp b
    cp c
    cp d
    cp e
    cp h
    cp l
    rst $38
    ldh [$e0], a
    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ldh [$e0], a
    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd

LoadFldUI_431f:
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
    ld hl, $8000
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld de, $1402
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld hl, $4c02
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c828], a
    ld a, d
    ld [$c829], a
    ret


LoadFldUI_435e:
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
    ld hl, $8260
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld de, $0b0c
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld hl, $4c02
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c828], a
    ld a, d
    ld [$c829], a
    ret


LoadFldUI_439d:
    ld a, [$c0d9]
    ld [$c823], a
    ld a, $05
    ld [$c822], a
    call LoadFldUI_431f
    ld a, [$c0d9]
    ld [$c823], a
    ld a, $06
    ld [$c822], a
    call LoadFldUI_435e
    ret


LoadFldUI_43ba:
    ld a, [$c0d9]
    ld hl, $43f4
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    ret z

    ld [$c0de], a
    ld [$c81e], a
    ld a, $04
    ld [$c81f], a
    ld hl, $016d
    ld a, l
    ld [$c820], a
    ld a, h
    ld [$c821], a
    ld hl, $8aa0
    ld a, l
    ld [$c0dc], a
    ld a, h
    ld [$c0dd], a
    ld hl, $5111
    rst $10
    ld hl, $1706
    rst $10
    ret


    ld l, l
    inc de
    ld e, c
    ld c, c
    ld b, d
    ld a, [bc]
    and h
    dec de
    add c
    add h
    rst $00
    sub l
    sub [hl]
    sub a
    ld b, h
    ld a, a
    jp nz, $9a91

    inc l
    ld l, l
    inc de
    ld e, c
    ld c, c
    ld b, d
    ld a, [bc]
    ld [$1b11], sp
    ld l, b
    ld hl, $9800
    ld bc, ClearHRAMTimers
    call SaveFldUI_424a
    ret


    ld a, [$c88c]
    rst $00
    ld l, $44
    jr nz, jr_05f_4469

    jr nz, @+$47

    jr nz, @+$47

    ld [hl], d
    ld b, l
    jr nz, @+$47

    ret nz

    ld b, l
    ld a, [$c88d]
    rst $00
    add hl, sp
    ld b, h
    add [hl]
    ld b, h
    db $d3
    ld b, h
    ret


    ld a, $02
    call SetColorMode
    call DisableSRAM
    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $560e
    ld hl, $9000
    call WaitLCDTransfer
    ld de, $669d
    ld hl, $9800
    call LoadFldUI_4263
    ld a, $00

jr_05f_4469:
    ld [$c81e], a
    ld hl, $170b
    rst $10
    ld de, $3f00
    ld a, $01
    ldh [rVBK], a
    ld hl, $9800
    ld a, [wIsGBC]
    or a
    call nz, WaitLCDTransfer
    ld a, $00
    ldh [rVBK], a
    ret


    ld a, $02
    call SetColorMode
    call DisableSRAM
    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $560c
    ld hl, $9000
    call WaitLCDTransfer
    ld de, $666e
    ld hl, $9800
    call LoadFldUI_4263
    ld a, $00
    ld [$c81e], a
    ld hl, $170b
    rst $10
    ld de, $3f00
    ld a, $01
    ldh [rVBK], a
    ld hl, $9800
    ld a, [wIsGBC]
    or a
    call nz, WaitLCDTransfer
    ld a, $00
    ldh [rVBK], a
    ret


    ld a, $02
    call SetColorMode
    call DisableSRAM
    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $5b1f
    ld hl, $9000
    call WaitLCDTransfer
    ld de, $6457
    ld hl, $9800
    call LoadFldUI_4263
    ld a, $00
    ld [$c81e], a
    ld hl, $170b
    rst $10
    ld de, $3f00
    ld a, $01
    ldh [rVBK], a
    ld hl, $9800
    ld a, [wIsGBC]
    or a
    call nz, WaitLCDTransfer
    ld a, $00
    ldh [rVBK], a
    ret


    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    ld a, $ff
    ld hl, $9000
    ld bc, $0010
    call FillNBytesWithRegA
    ld de, $5b18
    ld hl, $8000
    call WaitDMATransfer
    ld de, $5b19
    ld hl, $8040
    call WaitDMATransfer
    ld a, $00
    ld [$c81e], a
    ld hl, $170b
    rst $10
    ld a, $00
    ld [$c81e], a
    ld hl, $170c
    rst $10
    ld a, $01
    ldh [rVBK], a
    xor a
    ld hl, $9800
    ld bc, $0400
    ld a, [wIsGBC]
    or a
    ld a, $00
    call nz, FillNBytesWithRegA
    ld a, $00
    ldh [rVBK], a
    ret


    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $5b20
    ld hl, $9000
    call WaitLCDTransfer
    ld de, $5b21
    ld hl, $8800
    call WaitLCDTransfer
    ld de, $64f1
    ld hl, $9800
    call LoadFldUI_4263
    ld a, $01
    ld [$c81e], a
    ld hl, $170b
    rst $10
    ld de, $3f02
    ld a, $01
    ldh [rVBK], a
    ld hl, $9800
    ld a, [wIsGBC]
    or a
    call nz, WaitLCDTransfer
    ld a, $00
    ldh [rVBK], a
    ret


    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $5b20
    ld hl, $9000
    call WaitDMATransfer
    ld de, $5b21
    ld hl, $8800
    call WaitDMATransfer
    ld de, $6583
    ld hl, $9800
    call LoadFldUI_4263
    ld a, $06
    call SetBGM
    ld a, $01
    ld [$c81e], a
    ld hl, $170b
    rst $10
    ld a, $01
    ldh [rVBK], a
    ld hl, $9800
    ld a, [wIsGBC]
    or a
    jr nz, jr_05f_460c

    jr jr_05f_4614

jr_05f_460c:
    ld a, $05
    ld [hl+], a
    ld a, h
    cp $9b
    jr nz, jr_05f_460c

jr_05f_4614:
    ld a, $00
    ldh [rVBK], a
    ret


    ld a, $f4
    call SerialTransfer
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr nz, jr_05f_463f

    bit 1, a
    jr nz, jr_05f_463f

    bit 3, a
    jr nz, jr_05f_463f

    ld a, [$c88c]
    rst $00
    and [hl]
    ld b, [hl]
    ld a, [de]
    ld b, a
    or b
    ld b, a
    ld b, c
    ld c, b
    push de
    ld c, b
    ld [$b349], sp
    ld c, c

jr_05f_463f:
    ld a, [$c88c]
    cp $06
    jr nc, jr_05f_4663

    cp $00
    jr z, jr_05f_467c

Jump_05f_464a:
    ld a, $04
    call SetGBCPalette
    ld a, $00
    ld [$c88b], a
    ld a, $06
    ld [$c88c], a
    ld a, $00
    ld [$c88d], a
    ld hl, $c88e
    inc [hl]
    ret


jr_05f_4663:
    ld a, $04
    call SetGBCPalette
    ld a, $01
    ld [$c88b], a
    ld a, $00
    ld [$c88c], a
    ld a, $00
    ld [$c88d], a
    ld hl, $c88e
    inc [hl]
    ret


jr_05f_467c:
    ld a, [$c88d]
    cp $00
    jp nz, Jump_05f_4685

    ret


Jump_05f_4685:
    ld a, [$c88d]
    cp $01
    jp nz, Jump_05f_464a

    ld a, $04
    call SetGBCPalette
    ld a, $00
    ld [$c88b], a
    ld a, $00
    ld [$c88c], a
    ld a, $02
    ld [$c88d], a
    ld hl, $c88e
    inc [hl]
    ret


    ld a, [$c88d]
    rst $00
    or c
    ld b, [hl]
    jp nc, $f346

    ld b, [hl]
    ret


    ld a, [$c850]
    or a
    ret nz

    ld hl, $c0d8
    inc [hl]
    ld a, [$c0d8]
    cp $3c
    ret nz

    ld a, $04
    call SetGBCPalette
    xor a
    ld [$c0d8], a
    ld hl, $c88d
    inc [hl]
    ld hl, $c88e
    inc [hl]
    ret


    ld a, [$c850]
    or a
    ret nz

    ld hl, $c0d8
    inc [hl]
    ld a, [$c0d8]
    cp $b4
    ret nz

    ld a, $04
    call SetGBCPalette
    xor a
    ld [$c0d8], a
    ld hl, $c88d
    inc [hl]
    ld hl, $c88e
    inc [hl]
    ret


    ld a, [$c850]
    or a
    ret nz

    ld hl, $c0d8
    inc [hl]
    ld a, [$c0d8]
    cp $b4
    ret nz

    ld a, $04
    call SetGBCPalette
    xor a
    ld [$c0d8], a
    ld hl, $c88c
    inc [hl]
    ld hl, $c88e
    inc [hl]
    ld hl, $c0dc
    call LoadFldUI_49cc
    ret


    ld a, [$c850]
    or a
    ret nz

    ld a, [$c0d8]
    or a
    jr nz, jr_05f_472a

    ld a, $5d
    call PlaySoundEffect

jr_05f_472a:
    ld a, $01
    ld [$c0d8], a
    ld a, [$c0dc]
    or a
    jr nz, jr_05f_4777

    ld a, $00
    ldh [$c7], a
    ld a, $00
    ldh [$c9], a
    ld a, $00
    ldh [$ca], a
    ld hl, $c0dc
    ld a, l
    ld [$c0fc], a
    ld a, h
    ld [$c0fd], a
    ld hl, $0204
    rst $10
    ld hl, $c0dd
    dec [hl]
    ld hl, $c0dd
    dec [hl]
    ld hl, $c0de
    inc [hl]
    ld hl, $c0de
    inc [hl]
    ld a, [$c0dd]
    cp $40
    jr z, jr_05f_4772

    cp $e0
    jr nz, jr_05f_4777

    ld a, $01
    ld [$c0dc], a
    jr jr_05f_4777

jr_05f_4772:
    ld a, $00
    ld [$c0e2], a

jr_05f_4777:
    ld a, [$c0e2]
    or a
    ret nz

    ld a, $01
    ldh [$c7], a
    ld a, $04
    ldh [$c9], a
    ld a, $00
    ldh [$ca], a
    ld hl, $c0e2
    ld a, l
    ld [$c0fc], a
    ld a, h
    ld [$c0fd], a
    ld hl, $0204
    rst $10
    ld a, [$c0e2]
    or a
    ret z

    ld a, [$c0dc]
    or a
    ret z

    xor a
    ld [$c0d8], a
    ld hl, $c88c
    inc [hl]
    ld hl, $c0dc
    call LoadFldUI_49f1
    ret


    ld a, [$c0d8]
    or a
    jr nz, jr_05f_47bb

    ld a, $5d
    call PlaySoundEffect

jr_05f_47bb:
    ld a, $01
    ld [$c0d8], a
    ld a, [$c0dc]
    or a
    jr nz, jr_05f_4808

    ld a, $00
    ldh [$c7], a
    ld a, $00
    ldh [$c9], a
    ld a, $00
    ldh [$ca], a
    ld hl, $c0dc
    ld a, l
    ld [$c0fc], a
    ld a, h
    ld [$c0fd], a
    ld hl, $0204
    rst $10
    ld hl, $c0dd
    dec [hl]
    ld hl, $c0dd
    dec [hl]
    ld hl, $c0de
    inc [hl]
    ld hl, $c0de
    inc [hl]
    ld a, [$c0dd]
    cp $10
    jr z, jr_05f_4803

    cp $e0
    jr nz, jr_05f_4808

    ld a, $01
    ld [$c0dc], a
    jr jr_05f_4808

jr_05f_4803:
    ld a, $00
    ld [$c0e2], a

jr_05f_4808:
    ld a, [$c0e2]
    or a
    ret nz

    ld a, $01
    ldh [$c7], a
    ld a, $04
    ldh [$c9], a
    ld a, $00
    ldh [$ca], a
    ld hl, $c0e2
    ld a, l
    ld [$c0fc], a
    ld a, h
    ld [$c0fd], a
    ld hl, $0204
    rst $10
    ld a, [$c0e2]
    or a
    ret z

    ld a, [$c0dc]
    or a
    ret z

    xor a
    ld [$c0d8], a
    ld hl, $c88c
    inc [hl]
    ld hl, $c0dc
    call LoadFldUI_4a16
    ret


    ld a, [$c0d8]
    or a
    jr nz, jr_05f_484c

    ld a, $5d
    call PlaySoundEffect

jr_05f_484c:
    ld a, $01
    ld [$c0d8], a
    ld a, [$c0dc]
    or a
    jr nz, jr_05f_4899

    ld a, $00
    ldh [$c7], a
    ld a, $00
    ldh [$c9], a
    ld a, $00
    ldh [$ca], a
    ld hl, $c0dc
    ld a, l
    ld [$c0fc], a
    ld a, h
    ld [$c0fd], a
    ld hl, $0204
    rst $10
    ld hl, $c0dd
    dec [hl]
    ld hl, $c0dd
    dec [hl]
    ld hl, $c0de
    inc [hl]
    ld hl, $c0de
    inc [hl]
    ld a, [$c0dd]
    cp $70
    jr z, jr_05f_4894

    cp $20
    jr nz, jr_05f_4899

    ld a, $01
    ld [$c0dc], a
    jr jr_05f_4899

jr_05f_4894:
    ld a, $00
    ld [$c0e2], a

jr_05f_4899:
    ld a, [$c0e2]
    or a
    ret nz

    ld a, $01
    ldh [$c7], a
    ld a, $04
    ldh [$c9], a
    ld a, $00
    ldh [$ca], a
    ld hl, $c0e2
    ld a, l
    ld [$c0fc], a
    ld a, h
    ld [$c0fd], a
    ld hl, $0204
    rst $10
    ld a, [$c0e2]
    or a
    ret z

    ld a, [$c0dc]
    or a
    ret z

    ld a, $04
    call SetGBCPalette
    xor a
    ld [$c0d8], a
    ld hl, $c88c
    inc [hl]
    ld hl, $c88e
    inc [hl]
    ret


    ld a, [$c850]
    or a
    ret nz

    ld hl, $c0d8
    inc [hl]
    ld a, [$c0d8]
    cp $78
    ret nz

    ld a, $04
    call SetGBCPalette
    xor a
    ld [$c0d8], a
    ld hl, $c88c
    inc [hl]
    ld hl, $c88e
    inc [hl]
    xor a
    ld [$c0e8], a
    xor a
    ld [$c0e9], a
    xor a
    ld [$c0ea], a
    ld hl, $c0dc
    call LoadFldUI_4a3b
    ret


    ld a, [$c850]
    or a
    ret nz

    ld a, [$c0d8]
    or a
    jr nz, jr_05f_4918

    ld a, $5d
    call PlaySoundEffect

jr_05f_4918:
    ld a, $01
    ld [$c0d8], a
    ld a, [$c0dc]
    or a
    jr nz, jr_05f_495a

    ld a, $00
    ldh [$c7], a
    ld a, $00
    ldh [$c9], a
    ld a, $00
    ldh [$ca], a
    ld hl, $c0dc
    ld a, l
    ld [$c0fc], a
    ld a, h
    ld [$c0fd], a
    ld hl, $0204
    rst $10
    ld hl, $c0dd
    dec [hl]
    ld hl, $c0dd
    dec [hl]
    ld hl, $c0de
    inc [hl]
    ld hl, $c0de
    inc [hl]
    ld a, [$c0dd]
    cp $36
    jr nz, jr_05f_495a

    ld a, $01
    ld [$c0dc], a

jr_05f_495a:
    ld a, [$c0e2]
    or a
    jr nz, jr_05f_4997

    ld a, $00
    ldh [$c7], a
    ld a, $00
    ldh [$c9], a
    ld a, $00
    ldh [$ca], a
    ld hl, $c0e2
    ld a, l
    ld [$c0fc], a
    ld a, h
    ld [$c0fd], a
    ld hl, $0204
    rst $10
    ld hl, $c0e3
    dec [hl]
    ld hl, $c0e3
    dec [hl]
    ld hl, $c0e4
    inc [hl]
    ld hl, $c0e4
    inc [hl]
    ld a, [$c0e3]
    cp $59
    jr nz, jr_05f_4997

    ld a, $01
    ld [$c0e2], a

jr_05f_4997:
    ld a, [$c0e2]
    or a
    ret z

    ld a, [$c0dc]
    or a
    ret z

    ld a, $04
    call SetGBCPalette
    xor a
    ld [$c0d8], a
    ld hl, $c88c
    inc [hl]
    ld hl, $c88e
    inc [hl]
    ret


    ld a, [$ddb4]
    ld hl, $ddce
    and [hl]
    ld hl, $dde8
    and [hl]
    ld hl, $de02
    and [hl]
    cp $ff
    ret nz

    ld a, $06
    di
    call SetBGM
    ret


LoadFldUI_49cc:
    ld a, $00
    ld [hl+], a
    ld a, $80
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, $50
    ld [hl+], a
    ld a, $30
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ret


LoadFldUI_49f1:
    ld a, $00
    ld [hl+], a
    ld a, $40
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, $20
    ld [hl+], a
    ld a, $20
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ret


LoadFldUI_4a16:
    ld a, $00
    ld [hl+], a
    ld a, $a0
    ld [hl+], a
    ld a, $30
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, $80
    ld [hl+], a
    ld a, $50
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ret


LoadFldUI_4a3b:
    ld a, $00
    ld [hl+], a
    ld a, $86
    ld [hl+], a
    ld a, $fe
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $a9
    ld [hl+], a
    ld a, $04
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ret


HitReactionArm:
    ld a, [$db8a]
    cp $12
    jp c, Jump_05f_4ae8

    cp $39
    jr z, jr_05f_4ae8

    cp $37
    ret c

    cp $41
    jr c, jr_05f_4ae8

    cp $42
    ret c

    cp $43
    jr c, jr_05f_4ae8

    cp $44
    ret c

    cp $54
    jr c, jr_05f_4ae8

    cp $55
    ret c

    cp $6a
    jr c, jr_05f_4ae8

    cp $73
    ret c

    cp $75
    jr c, jr_05f_4ae8

    cp $7d
    ret c

    cp $7f
    jr c, jr_05f_4ae8

    cp $81
    ret c

    cp $84
    jr c, jr_05f_4ae8

    cp $88
    jr c, jr_05f_4b0b

    cp $99
    ret c

    cp $9c
    jr c, jr_05f_4ae8

    cp $a5
    ret c

    cp $a6
    jr c, jr_05f_4ae8

    cp $ab
    ret c

    cp $ac
    jr c, jr_05f_4ae8

    cp $af
    ret c

    cp $b0
    jr c, jr_05f_4ae8

    cp $c7
    ret c

    cp $c9
    jr c, jr_05f_4ae8

    cp $ca
    ret c

    cp $cc
    jr c, jr_05f_4ae8

    cp $d4
    ret c

    cp $d5
    jr c, jr_05f_4ae8

    cp $d6
    ret c

    cp $da
    jr c, jr_05f_4ae8

    cp $dd
    ret c

    cp $de
    jr c, jr_05f_4ae8

    cp $df
    ret c

    cp $e0
    jr c, jr_05f_4ae8

    ret


Jump_05f_4ae8:
jr_05f_4ae8:
    xor a
    ld hl, $da82
    ld bc, $0006
    call FillNBytesWithRegA
    ld b, $03
    ld a, [$c863]
    bit 1, a
    jr z, jr_05f_4afd

    ld b, $02

jr_05f_4afd:
    ld a, [wBattleTargetIdx]
    cp $04
    ld a, b
    jr c, jr_05f_4b07

    xor $01

jr_05f_4b07:
    ld [$da83], a
    ret


jr_05f_4b0b:
    xor a
    ld hl, $da82
    ld bc, $0006
    call FillNBytesWithRegA
    ld a, $04
    ld [$da83], a
    ret


    ld a, [$da34]
    inc a
    cp $05
    ld [$da34], a
    ret c

    xor a
    ld [$da34], a
    ld a, [$da82]
    or a
    ret nz

    ld a, [$db54]
    cp $80
    jr nz, jr_05f_4b40

    ld a, $6c
    call PlaySoundEffect
    ld a, $ff
    ld [$db54], a
    ret


jr_05f_4b40:
    ld a, [$da83]
    rst $00
    ld h, b
    ld c, e
    ld h, b
    ld c, e
    ld l, d
    ld c, e
    ld [bc], a
    ld c, h
    ld c, d
    ld c, h
    adc c
    ld c, h
    ret c

    ld c, h
    inc d
    ld c, l
    ld l, c
    ld c, l
    add [hl]
    ld c, l
    xor c
    ld c, l
    ld hl, sp+$4d
    and c
    ld d, c
    ld b, [hl]
    ld d, d
    ld a, $01
    ld [$da82], a
    xor a
    ld [$da84], a
    ret


    ld a, [$c863]
    ld b, a
    ld a, [wBattleTargetIdx]
    and $03
    cp $03
    jr z, jr_05f_4bf4

    ld a, [wBattleTargetIdx]
    bit 1, b
    jr nz, jr_05f_4b84

    cp $04
    jr c, jr_05f_4bf4

    jr jr_05f_4b88

jr_05f_4b84:
    cp $04
    jr nc, jr_05f_4bf4

jr_05f_4b88:
    ld a, [$d9ed]
    cp $0a
    jr z, jr_05f_4b97

    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_05f_4bf4

jr_05f_4b97:
    ld a, [$da84]
    rst $00
    and l
    ld c, e
    bit 1, e
    and l
    ld c, e
    bit 1, e
    db $f4
    ld c, e
    ld a, $06
    ld [$da85], a
    call LoadFldUI_4e3c
    ld hl, $50ff
    call CalcFldUI_50f4
    ld de, $9800
    add hl, de
    ld e, l
    ld d, h
    ld a, $03
    ld hl, $5109
    call CalcFldUI_50f4
    ld c, $06
    call SaveFldUI_4e1f
    ld hl, $da84
    inc [hl]
    ret


    ld a, $06
    ld [$da85], a
    call LoadFldUI_4e3c
    ld hl, $50ff
    call CalcFldUI_50f4
    ld de, $9800
    add hl, de
    ld e, l
    ld d, h
    ld a, [wBattleTargetIdx]
    and $03
    ld hl, $5109
    call CalcFldUI_50f4
    ld c, $06
    call SaveFldUI_4e1f
    ld hl, $da84
    inc [hl]
    ret


jr_05f_4bf4:
    ld a, $01
    ld [$da82], a
    xor a
    ld [$da84], a
    xor a
    ld [$da85], a
    ret


    ld a, [$db8a]
    cp $81
    jr z, jr_05f_4c3a

    ld a, [$da84]
    rst $00
    dec d
    ld c, h
    cpl
    ld c, h
    dec d
    ld c, h
    ld a, [hl-]
    ld c, h
    ld a, $02
    ldh [$bb], a
    ld a, $00
    ldh [$b7], a
    ld hl, $da84
    inc [hl]
    ret


    ld a, $00
    ldh [$bb], a
    ld a, $01
    ldh [$b7], a
    ld hl, $da84
    inc [hl]
    ret


    xor a
    ldh [$bb], a
    xor a
    ldh [$b7], a
    ld hl, $da84
    inc [hl]
    ret


jr_05f_4c3a:
    ld a, $01
    ld [$da82], a
    xor a
    ldh [$bb], a
    xor a
    ldh [$b7], a
    xor a
    ld [$da84], a
    ret


    ld a, [$da84]
    rst $00
    ld e, h
    ld c, h
    ld l, h
    ld c, h
    ld e, h
    ld c, h
    ld l, h
    ld c, h
    ld e, h
    ld c, h
    ld l, h
    ld c, h
    ld a, h
    ld c, h
    ld hl, wBGPalette
    ld [hl], $00
    inc hl
    ld [hl], $00
    inc hl
    ld [hl], $00
    ld hl, $da84
    inc [hl]
    ret


SetFldUI_4c6c:
    ld hl, wBGPalette
    ld [hl], $d2
    inc hl
    ld [hl], $d2
    inc hl
    ld [hl], $e2
    ld hl, $da84
    inc [hl]
    ret


    call SetFldUI_4c6c
    ld a, $01
    ld [$da82], a
    xor a
    ld [$da84], a
    ret


    ld a, [$da84]
    rst $00
    sub l
    ld c, h
    xor e
    ld c, h
    cp [hl]
    ld c, h
    adc $4c
    call ClrFldUI_506e
    ld a, [$da87]
    cp $04
    ret c

    xor a
    ld [$da86], a
    xor a
    ld [$da87], a
    ld hl, $da84
    inc [hl]
    ret


    ld hl, $da85
    inc [hl]
    ld a, [$da85]
    cp $0a
    ret nz

    ld hl, $da84
    inc [hl]
    xor a
    ld [$da85], a
    ret


    ld hl, wBGPalette
    ld [hl], $d2
    inc hl
    ld [hl], $d2
    inc hl
    ld [hl], $e2
    ld hl, $da84
    inc [hl]
    ret


    ld a, $01
    ld [$da82], a
    xor a
    ld [$da84], a
    ret


    ld a, [$da84]
    rst $00
    or $4c
    or $4c
    or $4c
    or $4c
    or $4c
    or $4c
    or $4c
    or $4c
    or $4c
    or $4c
    or $4c
    or $4c
    ld a, [bc]
    ld c, l
    ld hl, wBGPalette
    ld a, [hl]
    xor $ff
    ld [hl+], a
    ld a, [hl]
    xor $ff
    ld [hl+], a
    ld a, [hl]
    xor $ff
    ld [hl], a
    ld hl, $da84
    inc [hl]
    ret


    ld a, $01
    ld [$da82], a
    xor a
    ld [$da84], a
    ret


    ld a, [$da84]
    rst $00
    ld h, $4d
    inc a
    ld c, l
    ld c, a
    ld c, l
    ld h, $4d
    inc a
    ld c, l
    ld c, a
    ld c, l
    ld e, a
    ld c, l
    call ClrFldUI_506e
    ld a, [$da87]
    cp $04
    ret c

    xor a
    ld [$da86], a
    xor a
    ld [$da87], a
    ld hl, $da84
    inc [hl]
    ret


    ld hl, $da85
    inc [hl]
    ld a, [$da85]
    cp $05
    ret nz

    ld hl, $da84
    inc [hl]
    xor a
    ld [$da85], a
    ret


    ld hl, wBGPalette
    ld [hl], $d2
    inc hl
    ld [hl], $d2
    inc hl
    ld [hl], $e2
    ld hl, $da84
    inc [hl]
    ret


    ld a, $01
    ld [$da82], a
    xor a
    ld [$da84], a
    ret


    ld a, [$da84]
    or a
    call z, LoadFldUI_4ed5
    call LoadFldUI_4f49
    ld a, [$da84]
    or a
    ret z

    ld a, $01
    ld [$da82], a
    xor a
    ld [$da84], a
    xor a
    ld [$da85], a
    ret


    ld a, [$da87]
    or a
    jr nz, jr_05f_4da1

    ld hl, $da87
    inc [hl]
    xor a
    ld [$c905], a
    xor a
    ld [$c906], a
    xor a
    ld [$c907], a
    xor a
    ld [$c908], a
    ret


jr_05f_4da1:
    call LoadFldUI_4f9b
    ld hl, $da87
    inc [hl]
    ret


    ld a, [$da84]
    rst $00
    or l
    ld c, l
    bit 1, l
    sbc $4d
    xor $4d
    call ClrFldUI_50b5
    ld a, [$da87]
    cp $04
    ret c

    xor a
    ld [$da86], a
    xor a
    ld [$da87], a
    ld hl, $da84
    inc [hl]
    ret


    ld hl, $da85
    inc [hl]
    ld a, [$da85]
    cp $0a
    ret nz

    ld hl, $da84
    inc [hl]
    xor a
    ld [$da85], a
    ret


    ld hl, wBGPalette
    ld [hl], $d2
    inc hl
    ld [hl], $d2
    inc hl
    ld [hl], $e2
    ld hl, $da84
    inc [hl]
    ret


    ld a, $01
    ld [$da82], a
    xor a
    ld [$da84], a
    ret


    ld a, [$da84]
    rst $00
    ld e, h
    ld c, h
    ld l, h
    ld c, h
    ld e, h
    ld c, h
    ld l, h
    ld c, h
    ld e, h
    ld c, h
    ld l, h
    ld c, h
    ld e, h
    ld c, h
    ld l, h
    ld c, h
    ld e, h
    ld c, h
    ld l, h
    ld c, h
    ld e, h
    ld c, h
    ld l, h
    ld c, h
    ld e, h
    ld c, h
    ld l, h
    ld c, h
    ld e, h
    ld c, h
    ld l, h
    ld c, h
    ld a, h
    ld c, h
    ret


SaveFldUI_4e1f:
jr_05f_4e1f:
    push de
    ld a, [$da85]
    ld b, a

jr_05f_4e24:
    di
    call WaitVRAM
    ld a, [hl+]
    ld [de], a
    ei
    inc de
    dec b
    jr nz, jr_05f_4e24

    pop de
    dec c
    ret z

    ld a, $20
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    jr jr_05f_4e1f

LoadFldUI_4e3c:
    ld a, [$c86c]
    or a
    jr z, jr_05f_4e4e

    ld a, [$c863]
    bit 1, a
    jr z, jr_05f_4e4e

    ld a, [$db74]
    jr jr_05f_4e51

jr_05f_4e4e:
    ld a, [$db75]

jr_05f_4e51:
    cp $01
    jr z, jr_05f_4e7d

    cp $02
    jr z, jr_05f_4e6c

    ld a, [wBattleTargetIdx]
    and $03
    cp $01
    jr z, jr_05f_4e7d

    jr c, jr_05f_4e68

    ld a, $04
    jr jr_05f_4e7f

jr_05f_4e68:
    ld a, $03
    jr jr_05f_4e7f

jr_05f_4e6c:
    ld a, [wBattleTargetIdx]
    and $03
    cp $01
    jr z, jr_05f_4e79

    ld a, $01
    jr jr_05f_4e7f

jr_05f_4e79:
    ld a, $02
    jr jr_05f_4e7f

jr_05f_4e7d:
    ld a, $00

jr_05f_4e7f:
    ret


LoadFldUI_4e80:
    ld a, [$c86c]
    or a
    jr z, jr_05f_4ea3

    call LoadFldUI_52d6
    jr nz, jr_05f_4e97

    ld a, [$c863]
    bit 1, a
    jr z, jr_05f_4ea3

    ld a, [$db74]
    jr jr_05f_4ea6

jr_05f_4e97:
    ld a, [$c863]
    bit 1, a
    jr nz, jr_05f_4ea3

    ld a, [$db74]
    jr jr_05f_4ea6

jr_05f_4ea3:
    ld a, [$db75]

jr_05f_4ea6:
    cp $01
    jr z, jr_05f_4ed2

    cp $02
    jr z, jr_05f_4ec1

    ld a, [wBattleAttackerIdx]
    and $03
    cp $01
    jr z, jr_05f_4ed2

    jr c, jr_05f_4ebd

    ld a, $04
    jr jr_05f_4ed4

jr_05f_4ebd:
    ld a, $03
    jr jr_05f_4ed4

jr_05f_4ec1:
    ld a, [wBattleAttackerIdx]
    and $03
    cp $01
    jr z, jr_05f_4ece

    ld a, $01
    jr jr_05f_4ed4

jr_05f_4ece:
    ld a, $02
    jr jr_05f_4ed4

jr_05f_4ed2:
    ld a, $00

jr_05f_4ed4:
    ret


LoadFldUI_4ed5:
    ld a, [$da84]
    or a
    ret nz

    ld a, [$da85]
    rst $00
    inc d
    ld c, a
    ld l, $4f
    ld hl, $2e4f
    ld c, a
    inc d
    ld c, a
    ld l, $4f
    ld hl, $2e4f
    ld c, a
    inc d
    ld c, a
    ld l, $4f
    ld hl, $144f
    ld c, a
    ld l, $4f
    ld hl, $2e4f
    ld c, a
    inc d
    ld c, a
    ld l, $4f
    ld hl, $2e4f
    ld c, a
    inc d
    ld c, a
    ld l, $4f
    ld hl, $2e4f
    ld c, a
    inc d
    ld c, a
    ld l, $4f
    ld hl, AudioWritePort
    ld c, a
    ld a, $04
    ldh [$bb], a
    ld a, $00
    ldh [$b7], a
    ld hl, $da85
    inc [hl]
    ret


    ld a, $00
    ldh [$bb], a
    ld a, $03
    ldh [$b7], a
    ld hl, $da85
    inc [hl]
    ret


    xor a
    ldh [$bb], a
    xor a
    ldh [$b7], a
    ld hl, $da85
    inc [hl]
    ret


    ld a, $01
    ld [$da84], a
    xor a
    ldh [$bb], a
    xor a
    ldh [$b7], a
    xor a
    ld [$da85], a
    ret


LoadFldUI_4f49:
    ld a, [$da85]
    rst $00
    adc a
    ld c, a
    adc a
    ld c, a
    adc a
    ld c, a
    adc a
    ld c, a
    adc a
    ld c, a
    adc a
    ld c, a
    adc a
    ld c, a
    adc a
    ld c, a
    adc a
    ld c, a
    add e
    ld c, a
    adc a
    ld c, a
    add e
    ld c, a
    adc a
    ld c, a
    add e
    ld c, a
    adc a
    ld c, a
    add e
    ld c, a
    adc a
    ld c, a
    add e
    ld c, a
    adc a
    ld c, a
    add e
    ld c, a
    adc a
    ld c, a
    add e
    ld c, a
    adc a
    ld c, a
    add e
    ld c, a
    adc a
    ld c, a
    add e
    ld c, a
    adc a
    ld c, a
    ld hl, wBGPalette
    ld [hl], $00
    inc hl
    ld [hl], $00
    inc hl
    ld [hl], $00
    ret


    ld hl, wBGPalette
    ld [hl], $d2
    inc hl
    ld [hl], $d2
    inc hl
    ld [hl], $e2
    ret


LoadFldUI_4f9b:
    ld a, [$c905]
    rst $00
    and a
    ld c, a
    push bc
    ld c, a
    dec [hl]
    ld d, b
    ld c, a
    ld d, b
    ld hl, $c905
    inc [hl]
    ld hl, $c100
    ld b, $80

jr_05f_4fb0:
    ldh a, [$b7]
    ld [hl+], a
    dec b
    jr nz, jr_05f_4fb0

    ld a, $01
    ld [$c907], a
    ld a, $02
    ldh [rLYC], a
    ld a, $02
    ld [$c892], a
    ret


    ld a, [$da87]
    and $07
    jr nz, jr_05f_4fe8

    ld a, [$c907]
    swap a
    and $0f
    inc a
    ld b, a
    ld a, [$c907]
    add b
    ld [$c907], a
    cp $1c
    jr c, jr_05f_4fe8

    ld hl, $c905
    inc [hl]
    xor a
    ld [$c908], a

LoadFldUI_4fe8:
jr_05f_4fe8:
    ld a, [$c907]
    ldh [$d5], a
    ld a, [$da87]
    rra
    rra
    and $0f
    ld e, a
    ld d, $00
    ld bc, $c12e
    ld a, $66
    ldh [$d6], a

jr_05f_4ffe:
    inc e
    ld a, e
    and $0f
    ld e, a
    ld hl, $5025
    add hl, de
    push bc
    ld c, [hl]
    ldh a, [$d5]
    call Mul8x8To16
    pop bc
    bit 3, e
    jr z, jr_05f_5018

    ldh a, [$b7]
    sub h
    jr jr_05f_501b

jr_05f_5018:
    ldh a, [$b7]
    add h

jr_05f_501b:
    ld [bc], a
    inc c
    ld [bc], a
    inc c
    ldh a, [$d6]
    cp c
    jr nz, jr_05f_4ffe

    ret


    nop
    jr nc, @+$5d

    db $76
    ld a, a
    db $76
    ld e, e
    jr nc, jr_05f_502e

jr_05f_502e:
    jr nc, jr_05f_508b

jr_05f_5030:
    db $76
    ld a, a
    db $76
    ld e, e
    jr nc, jr_05f_5030

    add a
    db $da, $e6, $0f

    jr nz, jr_05f_504b

    ld a, [$c908]
    inc a
    ld [$c908], a
    cp $04
    jr nz, jr_05f_504b

    ld hl, $c905
    inc [hl]

jr_05f_504b:
    call LoadFldUI_4fe8
    ret


    ld a, $00
    ld [$c892], a
    ld a, $01
    ld [$da82], a
    xor a
    ld [$da87], a
    xor a
    ld [$c905], a
    xor a
    ld [$c906], a
    xor a
    ld [$c907], a
    xor a
    ld [$c908], a
    ret


ClrFldUI_506e:
    xor a
    ld [$da86], a
    ld hl, $da87
    inc [hl]
    ld b, $03
    ld c, $00
    ld hl, wBGPalette

jr_05f_507d:
    ld a, [hl]
    and $03
    add $01
    cp $04
    jr c, jr_05f_5088

    ld a, $03

jr_05f_5088:
    or c
    ld c, a
    ld a, [hl]

jr_05f_508b:
    and $0c
    add $04
    cp $0d
    jr c, jr_05f_5095

    ld a, $0c

jr_05f_5095:
    or c
    ld c, a
    ld a, [hl]
    and $30
    add $10
    cp $31
    jr c, jr_05f_50a2

    ld a, $30

jr_05f_50a2:
    or c
    ld c, a
    ld a, [hl]
    and $c0
    add $40
    cp $c1
    jr c, jr_05f_50af

    ld a, $c0

jr_05f_50af:
    or c
    ld [hl+], a
    dec b
    jr nz, jr_05f_507d

    ret


ClrFldUI_50b5:
    xor a
    ld [$da86], a
    ld hl, $da87
    inc [hl]
    ld b, $03
    ld c, $00
    ld hl, wBGPalette

jr_05f_50c4:
    ld a, [hl]
    and $03
    cp $00
    jr z, jr_05f_50cd

    sub $01

jr_05f_50cd:
    or c
    ld c, a
    ld a, [hl]
    and $0c
    cp $00
    jr z, jr_05f_50d8

    sub $04

jr_05f_50d8:
    or c
    ld c, a
    ld a, [hl]
    and $30
    cp $00
    jr z, jr_05f_50e3

    sub $10

jr_05f_50e3:
    or c
    ld c, a
    ld a, [hl]
    and $c0
    cp $00
    jr z, jr_05f_50ee

    sub $40

jr_05f_50ee:
    or c
    ld [hl+], a
    dec b
    jr nz, jr_05f_50c4

    ret


CalcFldUI_50f4:
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ret


    rst $00
    nop
    call nz, $ca00
    nop
    pop bc
    nop
    db $cd, $00, $11
    ld d, c
    dec [hl]
    ld d, c
    ld e, c
    ld d, c
    ld a, l
    ld d, c
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
    db $10
    ld de, $1312
    inc d
    dec d
    ld d, $17
    jr jr_05f_5144

    ld a, [de]
    dec de
    inc e
    dec e
    ld e, $1f
    jr nz, jr_05f_5154

    ld [hl+], a
    inc hl
    inc h
    dec h
    ld h, $27
    jr z, jr_05f_5164

    ld a, [hl+]
    dec hl
    inc l
    dec l
    ld l, $2f
    jr nc, jr_05f_5174

    ld [hl-], a

jr_05f_5144:
    inc sp
    inc [hl]
    dec [hl]
    ld [hl], $37
    jr c, @+$3b

    ld a, [hl-]
    dec sp
    inc a
    dec a
    ld a, $3f
    ld b, b
    ld b, c
    ld b, d

jr_05f_5154:
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
    ld d, b
    ld d, c
    ld d, d

jr_05f_5164:
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
    ld h, b
    ld h, c
    ld h, d

jr_05f_5174:
    ld h, e
    ld h, h
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ld a, [$da84]
    rst $00
    rst $20
    ld d, c
    db $dd
    ld d, c
    ldh a, [rHDMA1]
    db $dd
    ld d, c
    ld sp, hl
    ld d, c
    db $dd
    ld d, c
    ld [bc], a
    ld d, d
    db $dd
    ld d, c
    dec bc
    ld d, d
    db $dd
    ld d, c
    inc d
    ld d, d
    db $dd
    ld d, c
    dec e
    ld d, d
    db $dd
    ld d, c
    ld a, [hl+]
    ld d, d
    db $dd
    ld d, c
    dec e
    ld d, d
    db $dd
    ld d, c
    ld a, [hl+]
    ld d, d
    db $dd
    ld d, c
    dec e
    ld d, d
    db $dd
    ld d, c
    ld a, [hl+]
    ld d, d
    db $dd
    ld d, c
    dec e
    ld d, d
    db $dd
    ld d, c
    ld a, [hl+]
    ld d, d
    scf
    ld d, d
    xor a
    ldh [$b7], a
    ldh [$bb], a
    ld hl, $da84
    inc [hl]
    ret


    ld a, $fe
    ldh [$b7], a
    ld hl, $da84
    inc [hl]
    ret


    ld a, $02
    ldh [$b7], a
    ld hl, $da84
    inc [hl]
    ret


    ld a, $fc
    ldh [$b7], a
    ld hl, $da84
    inc [hl]
    ret


    ld a, $04
    ldh [$b7], a
    ld hl, $da84
    inc [hl]
    ret


    ld a, $f8
    ldh [$b7], a
    ld hl, $da84
    inc [hl]
    ret


    ld a, $08
    ldh [$b7], a
    ld hl, $da84
    inc [hl]
    ret


    ld a, $f8
    ldh [$b7], a
    ld a, $02
    ldh [$bb], a
    ld hl, $da84
    inc [hl]
    ret


    ld a, $08
    ldh [$b7], a
    ld a, $02
    ldh [$bb], a
    ld hl, $da84
    inc [hl]
    ret


    xor a
    ldh [$b7], a
    ldh [$bb], a
    ld a, $01
    ld [$da82], a
    xor a
    ld [$da84], a
    ret


    ld a, [$c863]
    ld b, a
    ld a, [wBattleAttackerIdx]
    cp $07
    jr nc, jr_05f_52c8

    cp $03
    jr z, jr_05f_52c8

    bit 1, b
    jr nz, jr_05f_525f

    cp $04
    jr c, jr_05f_52c8

    jr jr_05f_5263

jr_05f_525f:
    cp $04
    jr nc, jr_05f_52c8

jr_05f_5263:
    ld a, [wBattleAttackerIdx]
    call CheckMonsterSlot
    jr c, jr_05f_52c8

    ld a, [$da84]
    rst $00
    ld a, c
    ld d, d
    sbc a
    ld d, d
    ld a, c
    ld d, d
    sbc a
    ld d, d
    ret z

    ld d, d
    ld a, $06
    ld [$da85], a
    call LoadFldUI_4e80
    ld hl, $50ff
    call CalcFldUI_50f4
    ld de, $9800
    add hl, de
    ld e, l
    ld d, h
    ld a, $03
    ld hl, $5109
    call CalcFldUI_50f4
    ld c, $06
    call SaveFldUI_4e1f
    ld hl, $da84
    inc [hl]
    ret


    ld a, $06
    ld [$da85], a
    call LoadFldUI_4e80
    ld hl, $50ff
    call CalcFldUI_50f4
    ld de, $9800
    add hl, de
    ld e, l
    ld d, h
    ld a, [wBattleAttackerIdx]
    and $03
    ld hl, $5109
    call CalcFldUI_50f4
    ld c, $06
    call SaveFldUI_4e1f
    ld hl, $da84
    inc [hl]
    ret


jr_05f_52c8:
    ld a, $01
    ld [$da82], a
    xor a
    ld [$da84], a
    xor a
    ld [$da85], a
    ret


LoadFldUI_52d6:
    ld a, [$db8a]
    cp $3b
    jr z, jr_05f_52e4

    cp $3c
    jr z, jr_05f_52e4

    cp $3e
    ret nz

jr_05f_52e4:
    ld a, [$d9ec]
    cp $07
    ret nz

    ld a, [$d9ed]
    cp $04
    ret


; bank $5F entry 6: per skill-id range, WHEN (which action phase) the skill's routine runs; then the side's AnimRoutineIdx table -> AnimRunRoutine (S112)
AnimSkillVisual:
    ld a, [$db8a]
    cp $15
    jp c, Jump_05f_53a4

    cp $24
    jp c, Jump_05f_5382

    cp $25
    jp c, Jump_05f_53a4

    cp $2a
    jp z, Jump_05f_53a4

    cp $37
    jr c, jr_05f_5382

    cp $3b
    jp z, Jump_05f_53be

    cp $3c
    jp z, Jump_05f_53be

    cp $3e
    jp z, Jump_05f_53be

    cp $67
    jp c, Jump_05f_53a4

    cp $6a
    jp c, Jump_05f_53be

    cp $71
    jr z, jr_05f_53a4

    cp $73
    jr c, jr_05f_5382

    cp $75
    jr c, jr_05f_53a4

    cp $77
    jr c, jr_05f_5382

    cp $78
    jr c, jr_05f_53a4

    cp $7b
    jr c, jr_05f_5382

    cp $80
    jr z, jr_05f_5382

    cp $84
    jr c, jr_05f_53a4

    cp $88
    jr c, jr_05f_5382

    cp $91
    jr c, jr_05f_53a4

    cp $95
    jr z, jr_05f_53a4

    cp $97
    jr c, jr_05f_5382

    cp $a3
    jr z, jr_05f_5382

    cp $a4
    jr c, jr_05f_53a4

    cp $a7
    jr c, jr_05f_53a4

    cp $a9
    jr z, jr_05f_53a4

    cp $ab
    jr c, jr_05f_5382

    cp $ae
    jr z, jr_05f_5382

    cp $b0
    jr c, jr_05f_53a4

    cp $c7
    jr c, jr_05f_5382

    cp $c9
    jr z, jr_05f_5382

    cp $d5
    jr c, jr_05f_53cd

    cp $d5
    jr z, jr_05f_5382

    jr jr_05f_53a4

Jump_05f_5382:
jr_05f_5382:
    ld a, [$db8a]
    cp $80
    jp z, Jump_05f_53e9

    ld a, [$d9ec]
    cp $07
    jr nz, jr_05f_53e9

    ld a, [$d9ed]
    cp $0a
    jr z, jr_05f_53e3

    cp $01
    jr nz, jr_05f_53e9

    ld a, [$d9ee]
    cp $0e
    jr nc, jr_05f_53e9

    ret


Jump_05f_53a4:
jr_05f_53a4:
    ld a, [$d9ec]
    cp $07
    jr nz, jr_05f_53e9

    ld a, [$d9ed]
    cp $0a
    jr z, jr_05f_53e3

    cp $01
    jr nz, jr_05f_53e9

    ld a, [$d9ee]
    cp $05
    jr z, jr_05f_53e9

    ret


Jump_05f_53be:
    ld a, [$d9ec]
    cp $07
    jr nz, jr_05f_53e9

    ld a, [$d9ed]
    cp $04
    jr z, jr_05f_53e9

    ret


jr_05f_53cd:
    ld a, [$d9ec]
    cp $07
    jr nz, jr_05f_53e9

    ld a, [$d9ed]
    cp $0a
    jr nz, jr_05f_53e9

    ld a, [$d9ef]
    cp $04
    jr nz, jr_05f_53e9

    ret


jr_05f_53e3:
    ld a, [$d9ef]
    cp $01
    ret z

Jump_05f_53e9:
jr_05f_53e9:
    ld a, [wBattleAttackerIdx]
    cp $10
    jr z, jr_05f_5409

    ld a, [$c863]
    bit 1, a
    jr nz, jr_05f_5400

    ld a, [wBattleAttackerIdx]
    cp $04
    jr c, jr_05f_540d

    jr jr_05f_5412

jr_05f_5400:
    ld a, [wBattleAttackerIdx]
    cp $04
    jr c, jr_05f_5412

    jr jr_05f_540d

jr_05f_5409:
    call IsTargetPartySide
    ret c

jr_05f_540d:
    ld hl, $58dd
    jr jr_05f_5433

jr_05f_5412:
    ld hl, $59c3
    ld a, [$c86c]
    or a
    jr z, jr_05f_5433

    ld a, [$d9ec]
    cp $07
    jr nz, jr_05f_5433

    ld a, [$d9ed]
    cp $01
    jr nz, jr_05f_5433

    ld a, [$d9ee]
    cp $05
    jr nz, jr_05f_5433

    ld hl, $5aa9

jr_05f_5433:
    ld a, [$db8a]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    call AnimRunRoutine
    ret


; === Layer-1 SPRITE-ANIMATION routine dispatch (BATTLE_SKILL_SYSTEM.md §11.1) ===
; A = per-skill animation routine index (from $5f:$58dd/$59c3/$5aa9 [skill id $db8a],
; side-selected by $c863 bit1). Indexes the routine table at $58bd and JP [hl]s to it
; (via RST_08 = $00:$0008). Index $0d -> $55cc = bare `ret` = NO VISUAL (the "no animation"
; sentinel; e.g. HealMore/Increase party-cast). EMULATOR-VERIFIED: Zap A=$02, HealMore A=$0d.
AnimRunRoutine:
    ld c, a
    ld b, $00
    ld hl, $58bd
    add hl, bc
    add hl, bc
    call RST_08
    ret


    jp hl


AnimTargetSlot:
    ld a, [$db8a]
    cp $1a
    jr c, jr_05f_54c3

    cp $1c
    jr c, jr_05f_5461

    cp $29
    jr z, jr_05f_5461

    cp $76
    jr nz, jr_05f_54c3

jr_05f_5461:
    call IsAttackerPartySide
    jr c, jr_05f_54c3

    ld hl, $db74
    ld a, [$c863]
    and $02
    srl a
    xor $01
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$db53], a
    ld a, [hl]
    cp $01
    jr z, jr_05f_54b3

    cp $02
    jr z, jr_05f_549d

    ld a, [wBattleAttackerIdx]
    and $03
    cp $01
    jr z, jr_05f_54b3

    jr c, jr_05f_5499

    cp $03
    jp nc, Jump_05f_5523

    ld a, $06
    jr jr_05f_54bf

jr_05f_5499:
    ld a, $04
    jr jr_05f_54bf

jr_05f_549d:
    ld a, [wBattleAttackerIdx]
    and $03
    cp $03
    jp nc, Jump_05f_5523

    cp $01
    jr z, jr_05f_54af

    ld a, $02
    jr jr_05f_54bf

jr_05f_54af:
    ld a, $03
    jr jr_05f_54bf

jr_05f_54b3:
    ld a, [wBattleAttackerIdx]
    and $03
    cp $03
    jp nc, Jump_05f_5523

    ld a, $01

jr_05f_54bf:
    ld [$db54], a
    ret


jr_05f_54c3:
    call IsAttackerPartySide
    jr nc, jr_05f_5529

jr_05f_54c8:
    ld hl, $db74
    ld a, [$c863]
    and $02
    srl a
    xor $01
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$db53], a
    ld a, [hl]
    cp $01
    jr z, jr_05f_5513

    cp $02
    jr z, jr_05f_54fe

    ld a, [wBattleTargetIdx]
    and $03
    cp $01
    jr z, jr_05f_5513

    jr c, jr_05f_54fa

    cp $03
    jr nc, jr_05f_5523

    ld a, $06
    jr jr_05f_551f

jr_05f_54fa:
    ld a, $04
    jr jr_05f_551f

jr_05f_54fe:
    ld a, [wBattleTargetIdx]
    and $03
    cp $01
    jr z, jr_05f_550f

    cp $03
    jr nc, jr_05f_5523

    ld a, $02
    jr jr_05f_551f

jr_05f_550f:
    ld a, $03
    jr jr_05f_551f

jr_05f_5513:
    ld a, [wBattleTargetIdx]
    and $03
    cp $03
    jp nc, Jump_05f_5523

    ld a, $01

jr_05f_551f:
    ld [$db54], a
    ret


Jump_05f_5523:
jr_05f_5523:
    ld a, $08
    ld [$db54], a
    ret


jr_05f_5529:
    ld a, [wBattleTargetIdx]
    and $03
    cp $03
    jr nc, jr_05f_5523

    call IsTargetPartySide
    jr nc, jr_05f_54c8

    ld hl, $db74
    ld a, [$c863]
    and $02
    srl a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$db53], a
    ld a, [hl]
    cp $01
    jr z, jr_05f_5583

    cp $02
    jr z, jr_05f_556d

    ld a, [wBattleAttackerIdx]
    and $03
    cp $01
    jr z, jr_05f_5583

    jr c, jr_05f_5569

    and $03
    cp $03
    jr nc, jr_05f_5523

    ld a, $06
    jr jr_05f_551f

jr_05f_5569:
    ld a, $04
    jr jr_05f_551f

jr_05f_556d:
    ld a, [wBattleAttackerIdx]
    and $03
    cp $01
    jr z, jr_05f_557f

    cp $03
    jp nc, Jump_05f_5523

    ld a, $02
    jr jr_05f_551f

jr_05f_557f:
    ld a, $03
    jr jr_05f_551f

jr_05f_5583:
    ld a, [wBattleAttackerIdx]
    and $03
    cp $03
    jp nc, Jump_05f_5523

    ld a, $01
    jr jr_05f_551f

; AnimRoutineTable[0] — at the target (S112)
AnimRoutine_AtTarget:
    call AnimTargetSlot
    ld a, $01
    ld [$dd68], a
    jr jr_05f_55bb

; AnimRoutineTable[1] — in the middle of the foes (S112)
AnimRoutine_Middle:
    ld a, $01
    ld [$db54], a
    ld a, $01
    ld [$dd68], a
    jr jr_05f_55bb

; AnimRoutineTable[2] — on each target in turn (S112)
AnimRoutine_EachTarget:
    call AnimTargetSlot
    ld a, $02
    ld [$dd68], a
    jr jr_05f_55bb

; AnimRoutineTable[3] — flies across from the left (S112)
AnimRoutine_FlyAcross:
    ld a, $00
    ld [$db54], a
    ld a, $00
    ld [$dd68], a

; routines 0-3 end here: select the animation number, start its timeline + renderer, [$da80] = 1 (bank $50 loads tiles + palette next frame) — S112
AnimStartAnimation:
jr_05f_55bb:
    call AnimSelectCmd
    cp $ff
    ret z

    call AnimStartTimeline
    call AnimStartRenderer
    ld a, $01
    ld [$da80], a
; AnimRoutineTable[13] — nothing (the bare ret; S112)
AnimRoutine_None:
    ret


; AnimRoutineTable[4] — screen blinks (Radiant, the summons) (S112)
AnimRoutine_Screen04:
    call HitReactionArm
    ld a, $04
    ld [$da83], a
    ret


; AnimRoutineTable[5] — screen fades dark and back (UltraDown, ThickFog) (S112)
AnimRoutine_Screen05:
    call HitReactionArm
    ld a, $05
    ld [$da83], a
    ret


; AnimRoutineTable[6] — screen effect of Chance (S112)
AnimRoutine_Screen06:
    call HitReactionArm
    ld a, $06
    ld [$da83], a
    ret


; AnimRoutineTable[7] — screen fades dark twice (S112)
AnimRoutine_Screen07:
    call HitReactionArm
    ld a, $07
    ld [$da83], a
    ret


; AnimRoutineTable[8] — link-battle effect of Explodet / BigBang / MegaMagic (S112)
AnimRoutine_Screen08:
    call HitReactionArm
    ld a, $08
    ld [$da83], a
    ret


; AnimRoutineTable[9] — screen effect 9 (no skill uses it) (S112)
AnimRoutine_Screen09:
    call HitReactionArm
    ld a, $09
    ld [$da83], a
    ret


; AnimRoutineTable[10] — link-battle effect of Lightning / WhiteAir (S112)
AnimRoutine_Screen10:
    call HitReactionArm
    ld a, $0a
    ld [$da83], a
    ret


; AnimRoutineTable[11] — link-battle effect of Firebal / IceBolt (S112)
AnimRoutine_Screen11:
    call HitReactionArm
    ld a, $0b
    ld [$da83], a
    ret


; AnimRoutineTable[12] — link-battle effect of Infermore / Vacuum (S112)
AnimRoutine_Screen12:
    call HitReactionArm
    ld a, $0c
    ld [$da83], a
    ret


; AnimRoutineTable[14] — screen shakes (TwinSlash, Ramming, Kamikaze) (S112)
AnimRoutine_Screen14:
    call HitReactionArm
    ld a, $03
    ld [$da83], a
    ret


; AnimRoutineTable[15] — screen effect of an enemy TwinSlash (S112)
AnimRoutine_Screen15:
    call HitReactionArm
    ld a, $0d
    ld [$da83], a
    ret


AnimSelectCmd:
    ld a, [wBattleAttackerIdx]
    cp $10
    jr z, jr_05f_5649

    call IsAttackerPartySide
    jr c, jr_05f_563e

    jr jr_05f_565f

jr_05f_563e:
    call IsTargetPartySide
    jr nc, jr_05f_564e

    ld a, $ff
    ld [$da81], a
    ret


jr_05f_5649:
    call IsTargetPartySide
    jr c, jr_05f_5690

jr_05f_564e:
; [S2d] PRESENTATION SKILL-ID read. This `ld a,[$db8a]` (and the 11 other $db8a reads in
; this bank: $4a60 $4c02 $52d6 $52f0 $5382 $5433 $544e $564e $565f $567f $56cb $56dc) is the
; surface that selects per-skill animation/flash/SFX. $56ed/$57d5 are per-skill anim-command
; tables (-> $da81); custom ids ($E0+) overshoot them -> hang. patches/bank_05f.asm forks ALL
; of these to `call GetPresentId` (identity for stock ids; a per-skill PROXY id for custom
; ids, from CustomProxyTable in $5f free space), so a custom skill borrows a real skill's whole
; animation script -> no hang, hit-flash + cast-SFX restored. See BATTLE_SKILL_SYSTEM.md §13.2.
    ld a, [$db8a]
    ld de, $56ed                      ; $56ed = per-skill anim-command table 1 (indexed by skill id)
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [$da81], a
    ret


jr_05f_565f:
    ld a, [$db8a]
    cp $1a
    jr z, jr_05f_567f

    cp $1b
    jr z, jr_05f_567f

    cp $80
    jr z, jr_05f_567f

    cp $29
    jr z, jr_05f_567f

    cp $d5
    jr z, jr_05f_567f

    cp $aa
    jr z, jr_05f_567f

    call IsTargetPartySide
    jr c, jr_05f_5690

jr_05f_567f:
    ld a, [$db8a]
    ld de, $57d5
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [$da81], a
    ret


jr_05f_5690:
    ld a, $ff
    ld [$da81], a
    ret


AnimStartTimeline:
    call AnimSelectCmdInit
    ld a, [$daa4]
    ld [$dd64], a
    ld a, $60
    ld [$dd63], a
    ld a, $00
    ld [$dd62], a
    ld hl, $dd62
    ld a, l
    ld [$d7b4], a
    ld a, h
    ld [$d7b5], a
    ld hl, $0200
    rst $10
    ret


AnimSelectCmdInit:
    ld a, [wBattleAttackerIdx]
    cp $10
    jr z, jr_05f_56c7

    call IsAttackerPartySide
    jr c, jr_05f_56c7

    jr jr_05f_56dc

jr_05f_56c7:
    call IsTargetPartySide
    ret c

    ld a, [$db8a]
    ld hl, $56ed
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$daa4], a
    ret


jr_05f_56dc:
    ld a, [$db8a]
    ld hl, $57d5
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$daa4], a
    ret


AnimCmdTableFoe:
    ; ANIMATION NUMBER per skill id when a PARTY monster acts on the ENEMY
    ; side (AnimSelectCmd, through GetPresentId in the patched build);
    ; $FF = no animation. 232 rows (ids $00-$E7; only < $DE are skills).
    ; Re-sectioned S112 (was mgbdis fake code; BATTLE_SKILL_SYSTEM §11).
    db $00   ; [  0] Blaze
    db $01   ; [  1] Blazemore
    db $02   ; [  2] Blazemost
    db $03   ; [  3] Firebal
    db $04   ; [  4] Firebane
    db $05   ; [  5] Firebolt
    db $06   ; [  6] Bang
    db $07   ; [  7] Boom
    db $08   ; [  8] Explodet
    db $09   ; [  9] Infernos
    db $0a   ; [ 10] Infermore
    db $0b   ; [ 11] Infermost
    db $0c   ; [ 12] IceBolt
    db $0d   ; [ 13] SnowStorm
    db $0e   ; [ 14] Blizzard
    db $0f   ; [ 15] Bolt
    db $10   ; [ 16] Zap
    db $11   ; [ 17] Thordain
    db $ff   ; [ 18] Beat
    db $ff   ; [ 19] Defeat
    db $ff   ; [ 20] Sacrifice
    db $15   ; [ 21] Sleep
    db $15   ; [ 22] SleepAll
    db $12   ; [ 23] StopSpell
    db $17   ; [ 24] Surround
    db $16   ; [ 25] PanicAll
    db $12   ; [ 26] RobMagic
    db $ff   ; [ 27] TakeMagic
    db $12   ; [ 28] Sap
    db $12   ; [ 29] Defence
    db $ff   ; [ 30] Upper
    db $ff   ; [ 31] Increase
    db $12   ; [ 32] Slow
    db $12   ; [ 33] SlowAll
    db $ff   ; [ 34] Speed
    db $ff   ; [ 35] SpeedUp
    db $ff   ; [ 36] Barrier
    db $ff   ; [ 37] TwinHits
    db $ff   ; [ 38] MagicWall
    db $ff   ; [ 39] MagicBack
    db $ff   ; [ 40] Bounce
    db $ff   ; [ 41] Transform
    db $ff   ; [ 42] Ironize
    db $ff   ; [ 43] Heal
    db $ff   ; [ 44] HealMore
    db $ff   ; [ 45] HealAll
    db $ff   ; [ 46] HealUs
    db $ff   ; [ 47] HealUsAll
    db $ff   ; [ 48] Vivify
    db $ff   ; [ 49] Revive
    db $ff   ; [ 50] Farewell
    db $ff   ; [ 51] Antidote
    db $ff   ; [ 52] NumbOff
    db $ff   ; [ 53] DeChaos
    db $ff   ; [ 54] CurseOff
    db $ff   ; [ 55] StepGuard
    db $ff   ; [ 56] MapMagic
    db $ff   ; [ 57] Chance
    db $ff   ; [ 58] Attack
    db $1d   ; [ 59] TwinSlash
    db $ff   ; [ 60] Ramming
    db $ff   ; [ 61] Beserker
    db $ff   ; [ 62] Kamikaze
    db $1d   ; [ 63] Massacre
    db $1d   ; [ 64] EvilSlash
    db $ff   ; [ 65] ChargeUP
    db $ff   ; [ 66] HighJump
    db $ff   ; [ 67] SuckAir
    db $1e   ; [ 68] FireSlash
    db $1f   ; [ 69] BoltSlash
    db $20   ; [ 70] VacuSlash
    db $21   ; [ 71] IceSlash
    db $25   ; [ 72] MetalCut
    db $1d   ; [ 73] DrakSlash
    db $1d   ; [ 74] BeastCut
    db $23   ; [ 75] BirdBlow
    db $24   ; [ 76] DevilCut
    db $24   ; [ 77] ZombieCut
    db $25   ; [ 78] CleanCut
    db $27   ; [ 79] MultiCut
    db $ff   ; [ 80] BiAttack
    db $ff   ; [ 81] QuadHits
    db $ff   ; [ 82] CallHelp
    db $ff   ; [ 83] YellHelp
    db $ff   ; [ 84] Focus
    db $1d   ; [ 85] SquallHit
    db $ff   ; [ 86] PsycheUp
    db $1d   ; [ 87] RainSlash
    db $09   ; [ 88] WindBeast
    db $0b   ; [ 89] Vacuum
    db $0f   ; [ 90] Lightning
    db $1b   ; [ 91] RockThrow
    db $03   ; [ 92] FireAir
    db $04   ; [ 93] BlazeAir
    db $05   ; [ 94] Scorching
    db $1c   ; [ 95] WhiteFire
    db $0c   ; [ 96] FrigidAir
    db $0d   ; [ 97] IceAir
    db $0e   ; [ 98] IceStorm
    db $1a   ; [ 99] WhiteAir
    db $28   ; [100] Hellblast
    db $29   ; [101] BigBang
    db $2a   ; [102] MegaMagic
    db $15   ; [103] PoisonHit
    db $15   ; [104] NapAttack
    db $15   ; [105] Paralyze
    db $15   ; [106] SleepAir
    db $15   ; [107] PalsyAir
    db $15   ; [108] PoisonGas
    db $15   ; [109] PoisonAir
    db $16   ; [110] PaniDance
    db $16   ; [111] Curse
    db $16   ; [112] Ahhh
    db $ff   ; [113] K.O.Dance
    db $17   ; [114] SandStorm
    db $ff   ; [115] Radiant
    db $ff   ; [116] EerieLite
    db $12   ; [117] OddDance
    db $12   ; [118] RobDance
    db $ff   ; [119] SideStep
    db $16   ; [120] LureDance
    db $15   ; [121] LushLicks
    db $15   ; [122] SickLick
    db $ff   ; [123] LegSweep
    db $ff   ; [124] BigTrip
    db $ff   ; [125] WarCry
    db $ff   ; [126] Whistle
    db $ff   ; [127] Imitate
    db $2b   ; [128] DeMagic
    db $ff   ; [129] Surge
    db $ff   ; [130] UltraDown
    db $ff   ; [131] ThickFog
    db $ff   ; [132] TatsuCall
    db $ff   ; [133] DiagoCall
    db $ff   ; [134] SamsiCall
    db $ff   ; [135] BazooCall
    db $ff   ; [136] Cover
    db $ff   ; [137] Guardian
    db $ff   ; [138] TailWind
    db $ff   ; [139] StormWind
    db $ff   ; [140] Dodge
    db $ff   ; [141] Defence
    db $ff   ; [142] StrongD
    db $ff   ; [143] SuckAll
    db $ff   ; [144] BladeD
    db $12   ; [145] DanceShut
    db $12   ; [146] MouthShut
    db $ff   ; [147] Meditate
    db $ff   ; [148] Hustle
    db $ff   ; [149] LifeSong
    db $ff   ; [150] LifeDance
    db $ff   ; [151] Run
    db $ff   ; [152] Daze
    db $ff   ; [153] HitAlly
    db $ff   ; [154] HitEnemy
    db $ff   ; [155] HitRandom
    db $ff   ; [156] Scared
    db $ff   ; [157] Dance
    db $ff   ; [158] Trip
    db $ff   ; [159] Paralyze
    db $ff   ; [160] CANTMOVE
    db $ff   ; [161] RUN
    db $ff   ; [162] CALLHOROR
    db $14   ; [163] HealUsAll
    db $ff   ; [164] Smashed
    db $ff   ; [165] FILTHZONE
    db $ff   ; [166] ALLCHANGE
    db $15   ; [167] BIGSLEEP
    db $ff   ; [168] MP0
    db $ff   ; [169] ECHO
    db $ff   ; [170] CHGDRAGON
    db $ff   ; [171] CALLEVIL
    db $ff   ; [172] FREEZY
    db $ff   ; [173] ALLREVIVE
    db $ff   ; [174] RESTOREMP
    db $ff   ; [175] METEOR
    db $14   ; [176] HERB
    db $14   ; [177] HEALWATER
    db $14   ; [178] SAGESTONE
    db $14   ; [179] WARLDDEW
    db $14   ; [180] POTION
    db $14   ; [181] ELFWATER
    db $14   ; [182] ANTIDOTE
    db $14   ; [183] MOONHERB
    db $14   ; [184] SKYBELL
    db $14   ; [185] LAUREL
    db $14   ; [186] AWAKESAND
    db $ff   ; [187] WARLDLEAF
    db $ff   ; [188] LIFEACORN
    db $ff   ; [189] MYSTICNUT
    db $ff   ; [190] PWRSEED
    db $ff   ; [191] DEFSEED
    db $ff   ; [192] AGILSEED
    db $ff   ; [193] INTSEED
    db $2c   ; [194] FEEDMEAT
    db $2c   ; [195] BEFFJERKY
    db $2c   ; [196] PORKCHOP
    db $15   ; [197] BADMEAT
    db $2c   ; [198] SIRLOIN
    db $0f   ; [199] BOLTSTAFF
    db $09   ; [200] STAFF
    db $12   ; [201] BLOKSTAFF
    db $04   ; [202] LAVASTAFF
    db $0e   ; [203] SNOWSTAFF
    db $ff   ; [204] FIRESTAFF
    db $ff   ; [205] WARPWING
    db $ff   ; [206] TINYMEDAL
    db $ff   ; [207] QuestBk
    db $ff   ; [208] HORRORBK
    db $ff   ; [209] BENICEBK
    db $ff   ; [210] CHEATERBK
    db $ff   ; [211] SMARTBK
    db $02   ; [212] COMEDYBK
    db $ff   ; [213] BeDragon
    db $22   ; [214] Smashlime
    db $22   ; [215] Sheldodge
    db $1d   ; [216] Branching
    db $26   ; [217] GigaSlash
    db $ff   ; [218] LIFE
    db $ff   ; [219] RUN
    db $ff   ; [220] IRONIZE
    db $ff   ; [221] Ahhh
    db $ff   ; [222] 
    db $ff   ; [223] 
    db $ff   ; [224] 
    db $ff   ; [225] 
    db $ff   ; [226] 
    db $ff   ; [227] 
    db $ff   ; [228] 
    db $ff   ; [229] 
    db $ff   ; [230] 
    db $ff   ; [231] 
AnimCmdTableOwn:
    ; ANIMATION NUMBER per skill id when an ENEMY acts on its OWN side
    ; (heals, buffs) — and for $1A/$1B/$29/$80/$AA/$D5 whoever acts
    ; (AnimSelectCmd); a target on the party side never gets sprites.
    db $ff   ; [  0] Blaze
    db $ff   ; [  1] Blazemore
    db $ff   ; [  2] Blazemost
    db $ff   ; [  3] Firebal
    db $ff   ; [  4] Firebane
    db $ff   ; [  5] Firebolt
    db $ff   ; [  6] Bang
    db $ff   ; [  7] Boom
    db $ff   ; [  8] Explodet
    db $ff   ; [  9] Infernos
    db $ff   ; [ 10] Infermore
    db $ff   ; [ 11] Infermost
    db $ff   ; [ 12] IceBolt
    db $ff   ; [ 13] SnowStorm
    db $ff   ; [ 14] Blizzard
    db $ff   ; [ 15] Bolt
    db $ff   ; [ 16] Zap
    db $ff   ; [ 17] Thordain
    db $ff   ; [ 18] Beat
    db $ff   ; [ 19] Defeat
    db $ff   ; [ 20] Sacrifice
    db $ff   ; [ 21] Sleep
    db $ff   ; [ 22] SleepAll
    db $ff   ; [ 23] StopSpell
    db $ff   ; [ 24] Surround
    db $ff   ; [ 25] PanicAll
    db $13   ; [ 26] RobMagic
    db $13   ; [ 27] TakeMagic
    db $ff   ; [ 28] Sap
    db $ff   ; [ 29] Defence
    db $13   ; [ 30] Upper
    db $13   ; [ 31] Increase
    db $ff   ; [ 32] Slow
    db $ff   ; [ 33] SlowAll
    db $13   ; [ 34] Speed
    db $13   ; [ 35] SpeedUp
    db $ff   ; [ 36] Barrier
    db $13   ; [ 37] TwinHits
    db $ff   ; [ 38] MagicWall
    db $19   ; [ 39] MagicBack
    db $19   ; [ 40] Bounce
    db $18   ; [ 41] Transform
    db $ff   ; [ 42] Ironize
    db $14   ; [ 43] Heal
    db $14   ; [ 44] HealMore
    db $14   ; [ 45] HealAll
    db $14   ; [ 46] HealUs
    db $14   ; [ 47] HealUsAll
    db $ff   ; [ 48] Vivify
    db $ff   ; [ 49] Revive
    db $14   ; [ 50] Farewell
    db $14   ; [ 51] Antidote
    db $14   ; [ 52] NumbOff
    db $14   ; [ 53] DeChaos
    db $14   ; [ 54] CurseOff
    db $ff   ; [ 55] StepGuard
    db $ff   ; [ 56] MapMagic
    db $ff   ; [ 57] Chance
    db $ff   ; [ 58] Attack
    db $ff   ; [ 59] TwinSlash
    db $ff   ; [ 60] Ramming
    db $ff   ; [ 61] Beserker
    db $ff   ; [ 62] Kamikaze
    db $ff   ; [ 63] Massacre
    db $ff   ; [ 64] EvilSlash
    db $ff   ; [ 65] ChargeUP
    db $ff   ; [ 66] HighJump
    db $ff   ; [ 67] SuckAir
    db $ff   ; [ 68] FireSlash
    db $ff   ; [ 69] BoltSlash
    db $ff   ; [ 70] VacuSlash
    db $ff   ; [ 71] IceSlash
    db $ff   ; [ 72] MetalCut
    db $ff   ; [ 73] DrakSlash
    db $ff   ; [ 74] BeastCut
    db $ff   ; [ 75] BirdBlow
    db $ff   ; [ 76] DevilCut
    db $ff   ; [ 77] ZombieCut
    db $ff   ; [ 78] CleanCut
    db $ff   ; [ 79] MultiCut
    db $ff   ; [ 80] BiAttack
    db $ff   ; [ 81] QuadHits
    db $ff   ; [ 82] CallHelp
    db $ff   ; [ 83] YellHelp
    db $ff   ; [ 84] Focus
    db $ff   ; [ 85] SquallHit
    db $ff   ; [ 86] PsycheUp
    db $ff   ; [ 87] RainSlash
    db $ff   ; [ 88] WindBeast
    db $ff   ; [ 89] Vacuum
    db $ff   ; [ 90] Lightning
    db $ff   ; [ 91] RockThrow
    db $ff   ; [ 92] FireAir
    db $ff   ; [ 93] BlazeAir
    db $ff   ; [ 94] Scorching
    db $ff   ; [ 95] WhiteFire
    db $ff   ; [ 96] FrigidAir
    db $ff   ; [ 97] IceAir
    db $ff   ; [ 98] IceStorm
    db $ff   ; [ 99] WhiteAir
    db $ff   ; [100] Hellblast
    db $ff   ; [101] BigBang
    db $ff   ; [102] MegaMagic
    db $ff   ; [103] PoisonHit
    db $ff   ; [104] NapAttack
    db $ff   ; [105] Paralyze
    db $ff   ; [106] SleepAir
    db $ff   ; [107] PalsyAir
    db $ff   ; [108] PoisonGas
    db $ff   ; [109] PoisonAir
    db $ff   ; [110] PaniDance
    db $ff   ; [111] Curse
    db $ff   ; [112] Ahhh
    db $ff   ; [113] K.O.Dance
    db $ff   ; [114] SandStorm
    db $ff   ; [115] Radiant
    db $ff   ; [116] EerieLite
    db $ff   ; [117] OddDance
    db $13   ; [118] RobDance
    db $ff   ; [119] SideStep
    db $ff   ; [120] LureDance
    db $ff   ; [121] LushLicks
    db $ff   ; [122] SickLick
    db $ff   ; [123] LegSweep
    db $ff   ; [124] BigTrip
    db $ff   ; [125] WarCry
    db $ff   ; [126] Whistle
    db $ff   ; [127] Imitate
    db $2b   ; [128] DeMagic
    db $ff   ; [129] Surge
    db $ff   ; [130] UltraDown
    db $ff   ; [131] ThickFog
    db $ff   ; [132] TatsuCall
    db $ff   ; [133] DiagoCall
    db $ff   ; [134] SamsiCall
    db $ff   ; [135] BazooCall
    db $ff   ; [136] Cover
    db $ff   ; [137] Guardian
    db $ff   ; [138] TailWind
    db $ff   ; [139] StormWind
    db $ff   ; [140] Dodge
    db $ff   ; [141] Defence
    db $ff   ; [142] StrongD
    db $ff   ; [143] SuckAll
    db $ff   ; [144] BladeD
    db $ff   ; [145] DanceShut
    db $ff   ; [146] MouthShut
    db $14   ; [147] Meditate
    db $14   ; [148] Hustle
    db $ff   ; [149] LifeSong
    db $14   ; [150] LifeDance
    db $ff   ; [151] Run
    db $ff   ; [152] Daze
    db $ff   ; [153] HitAlly
    db $ff   ; [154] HitEnemy
    db $ff   ; [155] HitRandom
    db $ff   ; [156] Scared
    db $ff   ; [157] Dance
    db $ff   ; [158] Trip
    db $ff   ; [159] Paralyze
    db $ff   ; [160] CANTMOVE
    db $ff   ; [161] RUN
    db $ff   ; [162] CALLHOROR
    db $14   ; [163] HealUsAll
    db $ff   ; [164] Smashed
    db $ff   ; [165] FILTHZONE
    db $ff   ; [166] ALLCHANGE
    db $15   ; [167] BIGSLEEP
    db $12   ; [168] MP0
    db $ff   ; [169] ECHO
    db $18   ; [170] CHGDRAGON
    db $ff   ; [171] CALLEVIL
    db $ff   ; [172] FREEZY
    db $ff   ; [173] ALLREVIVE
    db $14   ; [174] RESTOREMP
    db $ff   ; [175] METEOR
    db $ff   ; [176] HERB
    db $ff   ; [177] HEALWATER
    db $ff   ; [178] SAGESTONE
    db $ff   ; [179] WARLDDEW
    db $ff   ; [180] POTION
    db $ff   ; [181] ELFWATER
    db $ff   ; [182] ANTIDOTE
    db $ff   ; [183] MOONHERB
    db $ff   ; [184] SKYBELL
    db $ff   ; [185] LAUREL
    db $ff   ; [186] AWAKESAND
    db $ff   ; [187] WARLDLEAF
    db $ff   ; [188] LIFEACORN
    db $ff   ; [189] MYSTICNUT
    db $ff   ; [190] PWRSEED
    db $ff   ; [191] DEFSEED
    db $ff   ; [192] AGILSEED
    db $ff   ; [193] INTSEED
    db $ff   ; [194] FEEDMEAT
    db $ff   ; [195] BEFFJERKY
    db $ff   ; [196] PORKCHOP
    db $ff   ; [197] BADMEAT
    db $ff   ; [198] SIRLOIN
    db $ff   ; [199] BOLTSTAFF
    db $ff   ; [200] STAFF
    db $ff   ; [201] BLOKSTAFF
    db $ff   ; [202] LAVASTAFF
    db $ff   ; [203] SNOWSTAFF
    db $ff   ; [204] FIRESTAFF
    db $ff   ; [205] WARPWING
    db $ff   ; [206] TINYMEDAL
    db $ff   ; [207] QuestBk
    db $ff   ; [208] HORRORBK
    db $ff   ; [209] BENICEBK
    db $ff   ; [210] CHEATERBK
    db $ff   ; [211] SMARTBK
    db $ff   ; [212] COMEDYBK
    db $18   ; [213] BeDragon
    db $ff   ; [214] Smashlime
    db $ff   ; [215] Sheldodge
    db $ff   ; [216] Branching
    db $ff   ; [217] GigaSlash
    db $ff   ; [218] LIFE
    db $ff   ; [219] RUN
    db $ff   ; [220] IRONIZE
    db $ff   ; [221] Ahhh
    db $ff   ; [222] 
    db $ff   ; [223] 
    db $ff   ; [224] 
    db $ff   ; [225] 
    db $ff   ; [226] 
    db $ff   ; [227] 
    db $ff   ; [228] 
    db $ff   ; [229] 
    db $ff   ; [230] 
    db $ff   ; [231] 
AnimRoutineTable:
    ; the 16 per-skill presentation ROUTINES (AnimRunRoutine; index from
    ; the AnimRoutineIdx tables): 0-3 start the skill's animation with a
    ; MOTION, 4-12 / 14 / 15 run a SCREEN EFFECT (bank $5F entry 5 phase
    ; [$da83]) instead, 13 = nothing (MEASURED S112, PyBoy).
    dw AnimRoutine_AtTarget      ; [ 0] at the target
    dw AnimRoutine_Middle        ; [ 1] in the middle of the foes
    dw AnimRoutine_EachTarget    ; [ 2] on each target in turn
    dw AnimRoutine_FlyAcross     ; [ 3] flies across from the left
    dw AnimRoutine_Screen04      ; [ 4] screen blinks (Radiant, the summons)
    dw AnimRoutine_Screen05      ; [ 5] screen fades dark and back (UltraDown, ThickFog)
    dw AnimRoutine_Screen06      ; [ 6] screen effect of Chance
    dw AnimRoutine_Screen07      ; [ 7] screen fades dark twice
    dw AnimRoutine_Screen08      ; [ 8] link-battle effect of Explodet / BigBang / MegaMagic
    dw AnimRoutine_Screen09      ; [ 9] screen effect 9 (no skill uses it)
    dw AnimRoutine_Screen10      ; [10] link-battle effect of Lightning / WhiteAir
    dw AnimRoutine_Screen11      ; [11] link-battle effect of Firebal / IceBolt
    dw AnimRoutine_Screen12      ; [12] link-battle effect of Infermore / Vacuum
    dw AnimRoutine_None          ; [13] nothing
    dw AnimRoutine_Screen14      ; [14] screen shakes (TwinSlash, Ramming, Kamikaze)
    dw AnimRoutine_Screen15      ; [15] screen effect of an enemy TwinSlash
AnimRoutineIdxParty:
    ; ROUTINE index per skill id when a PARTY monster acts (230 rows; AnimSkillVisual).
    db $00   ; [  0] Blaze
    db $00   ; [  1] Blazemore
    db $00   ; [  2] Blazemost
    db $03   ; [  3] Firebal
    db $03   ; [  4] Firebane
    db $01   ; [  5] Firebolt
    db $02   ; [  6] Bang
    db $02   ; [  7] Boom
    db $01   ; [  8] Explodet
    db $02   ; [  9] Infernos
    db $03   ; [ 10] Infermore
    db $01   ; [ 11] Infermost
    db $03   ; [ 12] IceBolt
    db $02   ; [ 13] SnowStorm
    db $01   ; [ 14] Blizzard
    db $02   ; [ 15] Bolt
    db $02   ; [ 16] Zap
    db $01   ; [ 17] Thordain
    db $0d   ; [ 18] Beat
    db $0d   ; [ 19] Defeat
    db $0d   ; [ 20] Sacrifice
    db $00   ; [ 21] Sleep
    db $00   ; [ 22] SleepAll
    db $00   ; [ 23] StopSpell
    db $00   ; [ 24] Surround
    db $00   ; [ 25] PanicAll
    db $00   ; [ 26] RobMagic
    db $0d   ; [ 27] TakeMagic
    db $00   ; [ 28] Sap
    db $00   ; [ 29] Defence
    db $0d   ; [ 30] Upper
    db $0d   ; [ 31] Increase
    db $00   ; [ 32] Slow
    db $00   ; [ 33] SlowAll
    db $0d   ; [ 34] Speed
    db $0d   ; [ 35] SpeedUp
    db $0d   ; [ 36] Barrier
    db $0d   ; [ 37] TwinHits
    db $0d   ; [ 38] MagicWall
    db $0d   ; [ 39] MagicBack
    db $0d   ; [ 40] Bounce
    db $0d   ; [ 41] Transform
    db $0d   ; [ 42] Ironize
    db $0d   ; [ 43] Heal
    db $0d   ; [ 44] HealMore
    db $0d   ; [ 45] HealAll
    db $0d   ; [ 46] HealUs
    db $0d   ; [ 47] HealUsAll
    db $0d   ; [ 48] Vivify
    db $0d   ; [ 49] Revive
    db $0d   ; [ 50] Farewell
    db $0d   ; [ 51] Antidote
    db $0d   ; [ 52] NumbOff
    db $0d   ; [ 53] DeChaos
    db $0d   ; [ 54] CurseOff
    db $0d   ; [ 55] StepGuard
    db $0d   ; [ 56] MapMagic
    db $06   ; [ 57] Chance
    db $0d   ; [ 58] Attack
    db $0e   ; [ 59] TwinSlash
    db $0e   ; [ 60] Ramming
    db $0d   ; [ 61] Beserker
    db $0e   ; [ 62] Kamikaze
    db $00   ; [ 63] Massacre
    db $00   ; [ 64] EvilSlash
    db $0d   ; [ 65] ChargeUP
    db $0d   ; [ 66] HighJump
    db $0d   ; [ 67] SuckAir
    db $00   ; [ 68] FireSlash
    db $00   ; [ 69] BoltSlash
    db $00   ; [ 70] VacuSlash
    db $00   ; [ 71] IceSlash
    db $00   ; [ 72] MetalCut
    db $00   ; [ 73] DrakSlash
    db $00   ; [ 74] BeastCut
    db $00   ; [ 75] BirdBlow
    db $00   ; [ 76] DevilCut
    db $00   ; [ 77] ZombieCut
    db $00   ; [ 78] CleanCut
    db $01   ; [ 79] MultiCut
    db $0d   ; [ 80] BiAttack
    db $0d   ; [ 81] QuadHits
    db $0d   ; [ 82] CallHelp
    db $0d   ; [ 83] YellHelp
    db $0d   ; [ 84] Focus
    db $00   ; [ 85] SquallHit
    db $0d   ; [ 86] PsycheUp
    db $02   ; [ 87] RainSlash
    db $00   ; [ 88] WindBeast
    db $01   ; [ 89] Vacuum
    db $02   ; [ 90] Lightning
    db $02   ; [ 91] RockThrow
    db $03   ; [ 92] FireAir
    db $03   ; [ 93] BlazeAir
    db $01   ; [ 94] Scorching
    db $01   ; [ 95] WhiteFire
    db $03   ; [ 96] FrigidAir
    db $02   ; [ 97] IceAir
    db $01   ; [ 98] IceStorm
    db $01   ; [ 99] WhiteAir
    db $02   ; [100] Hellblast
    db $01   ; [101] BigBang
    db $01   ; [102] MegaMagic
    db $00   ; [103] PoisonHit
    db $00   ; [104] NapAttack
    db $00   ; [105] Paralyze
    db $00   ; [106] SleepAir
    db $00   ; [107] PalsyAir
    db $00   ; [108] PoisonGas
    db $00   ; [109] PoisonAir
    db $00   ; [110] PaniDance
    db $00   ; [111] Curse
    db $00   ; [112] Ahhh
    db $0d   ; [113] K.O.Dance
    db $00   ; [114] SandStorm
    db $04   ; [115] Radiant
    db $04   ; [116] EerieLite
    db $00   ; [117] OddDance
    db $00   ; [118] RobDance
    db $0d   ; [119] SideStep
    db $00   ; [120] LureDance
    db $00   ; [121] LushLicks
    db $00   ; [122] SickLick
    db $0d   ; [123] LegSweep
    db $0d   ; [124] BigTrip
    db $0d   ; [125] WarCry
    db $0d   ; [126] Whistle
    db $0d   ; [127] Imitate
    db $01   ; [128] DeMagic
    db $04   ; [129] Surge
    db $05   ; [130] UltraDown
    db $05   ; [131] ThickFog
    db $04   ; [132] TatsuCall
    db $04   ; [133] DiagoCall
    db $04   ; [134] SamsiCall
    db $04   ; [135] BazooCall
    db $0d   ; [136] Cover
    db $0d   ; [137] Guardian
    db $0d   ; [138] TailWind
    db $0d   ; [139] StormWind
    db $0d   ; [140] Dodge
    db $0d   ; [141] Defence
    db $0d   ; [142] StrongD
    db $0d   ; [143] SuckAll
    db $0d   ; [144] BladeD
    db $00   ; [145] DanceShut
    db $00   ; [146] MouthShut
    db $0d   ; [147] Meditate
    db $0d   ; [148] Hustle
    db $0d   ; [149] LifeSong
    db $0d   ; [150] LifeDance
    db $0d   ; [151] Run
    db $0d   ; [152] Daze
    db $0d   ; [153] HitAlly
    db $0d   ; [154] HitEnemy
    db $0d   ; [155] HitRandom
    db $0d   ; [156] Scared
    db $0d   ; [157] Dance
    db $0d   ; [158] Trip
    db $0d   ; [159] Paralyze
    db $0d   ; [160] CANTMOVE
    db $0d   ; [161] RUN
    db $0d   ; [162] CALLHOROR
    db $00   ; [163] HealUsAll
    db $0d   ; [164] Smashed
    db $05   ; [165] FILTHZONE
    db $0d   ; [166] ALLCHANGE
    db $00   ; [167] BIGSLEEP
    db $0d   ; [168] MP0
    db $0d   ; [169] ECHO
    db $0d   ; [170] CHGDRAGON
    db $0d   ; [171] CALLEVIL
    db $0d   ; [172] FREEZY
    db $0d   ; [173] ALLREVIVE
    db $0d   ; [174] RESTOREMP
    db $0d   ; [175] METEOR
    db $00   ; [176] HERB
    db $00   ; [177] HEALWATER
    db $00   ; [178] SAGESTONE
    db $00   ; [179] WARLDDEW
    db $00   ; [180] POTION
    db $00   ; [181] ELFWATER
    db $00   ; [182] ANTIDOTE
    db $00   ; [183] MOONHERB
    db $00   ; [184] SKYBELL
    db $00   ; [185] LAUREL
    db $00   ; [186] AWAKESAND
    db $0d   ; [187] WARLDLEAF
    db $0d   ; [188] LIFEACORN
    db $0d   ; [189] MYSTICNUT
    db $0d   ; [190] PWRSEED
    db $0d   ; [191] DEFSEED
    db $0d   ; [192] AGILSEED
    db $0d   ; [193] INTSEED
    db $00   ; [194] FEEDMEAT
    db $00   ; [195] BEFFJERKY
    db $00   ; [196] PORKCHOP
    db $00   ; [197] BADMEAT
    db $00   ; [198] SIRLOIN
    db $02   ; [199] BOLTSTAFF
    db $02   ; [200] STAFF
    db $00   ; [201] BLOKSTAFF
    db $03   ; [202] LAVASTAFF
    db $01   ; [203] SNOWSTAFF
    db $0d   ; [204] FIRESTAFF
    db $0d   ; [205] WARPWING
    db $0d   ; [206] TINYMEDAL
    db $0d   ; [207] QuestBk
    db $0d   ; [208] HORRORBK
    db $0d   ; [209] BENICEBK
    db $0d   ; [210] CHEATERBK
    db $0d   ; [211] SMARTBK
    db $00   ; [212] COMEDYBK
    db $0d   ; [213] BeDragon
    db $00   ; [214] Smashlime
    db $00   ; [215] Sheldodge
    db $00   ; [216] Branching
    db $00   ; [217] GigaSlash
    db $0d   ; [218] LIFE
    db $0d   ; [219] RUN
    db $0d   ; [220] IRONIZE
    db $0d   ; [221] Ahhh
    db $0d   ; [222] 
    db $0d   ; [223] 
    db $0d   ; [224] 
    db $0d   ; [225] 
    db $0d   ; [226] 
    db $0d   ; [227] 
    db $0d   ; [228] 
    db $0d   ; [229] 
AnimRoutineIdxEnemy:
    ; ROUTINE index per skill id when an ENEMY acts (230 rows; AnimSkillVisual).
    db $0d   ; [  0] Blaze
    db $0d   ; [  1] Blazemore
    db $0d   ; [  2] Blazemost
    db $0d   ; [  3] Firebal
    db $0d   ; [  4] Firebane
    db $0d   ; [  5] Firebolt
    db $0d   ; [  6] Bang
    db $0d   ; [  7] Boom
    db $0d   ; [  8] Explodet
    db $0d   ; [  9] Infernos
    db $0d   ; [ 10] Infermore
    db $0d   ; [ 11] Infermost
    db $0d   ; [ 12] IceBolt
    db $0d   ; [ 13] SnowStorm
    db $0d   ; [ 14] Blizzard
    db $0d   ; [ 15] Bolt
    db $0d   ; [ 16] Zap
    db $0d   ; [ 17] Thordain
    db $0d   ; [ 18] Beat
    db $0d   ; [ 19] Defeat
    db $0d   ; [ 20] Sacrifice
    db $0d   ; [ 21] Sleep
    db $0d   ; [ 22] SleepAll
    db $0d   ; [ 23] StopSpell
    db $0d   ; [ 24] Surround
    db $0d   ; [ 25] PanicAll
    db $00   ; [ 26] RobMagic
    db $00   ; [ 27] TakeMagic
    db $0d   ; [ 28] Sap
    db $0d   ; [ 29] Defence
    db $00   ; [ 30] Upper
    db $00   ; [ 31] Increase
    db $0d   ; [ 32] Slow
    db $0d   ; [ 33] SlowAll
    db $00   ; [ 34] Speed
    db $00   ; [ 35] SpeedUp
    db $0d   ; [ 36] Barrier
    db $00   ; [ 37] TwinHits
    db $02   ; [ 38] MagicWall
    db $00   ; [ 39] MagicBack
    db $00   ; [ 40] Bounce
    db $00   ; [ 41] Transform
    db $0d   ; [ 42] Ironize
    db $00   ; [ 43] Heal
    db $00   ; [ 44] HealMore
    db $00   ; [ 45] HealAll
    db $00   ; [ 46] HealUs
    db $00   ; [ 47] HealUsAll
    db $0d   ; [ 48] Vivify
    db $0d   ; [ 49] Revive
    db $00   ; [ 50] Farewell
    db $00   ; [ 51] Antidote
    db $00   ; [ 52] NumbOff
    db $00   ; [ 53] DeChaos
    db $00   ; [ 54] CurseOff
    db $0d   ; [ 55] StepGuard
    db $0d   ; [ 56] MapMagic
    db $06   ; [ 57] Chance
    db $0d   ; [ 58] Attack
    db $0f   ; [ 59] TwinSlash
    db $0f   ; [ 60] Ramming
    db $0d   ; [ 61] Beserker
    db $0f   ; [ 62] Kamikaze
    db $0d   ; [ 63] Massacre
    db $0d   ; [ 64] EvilSlash
    db $0d   ; [ 65] ChargeUP
    db $0d   ; [ 66] HighJump
    db $0d   ; [ 67] SuckAir
    db $0d   ; [ 68] FireSlash
    db $0d   ; [ 69] BoltSlash
    db $0d   ; [ 70] VacuSlash
    db $0d   ; [ 71] IceSlash
    db $0d   ; [ 72] MetalCut
    db $0d   ; [ 73] DrakSlash
    db $0d   ; [ 74] BeastCut
    db $0d   ; [ 75] BirdBlow
    db $0d   ; [ 76] DevilCut
    db $0d   ; [ 77] ZombieCut
    db $0d   ; [ 78] CleanCut
    db $0d   ; [ 79] MultiCut
    db $0d   ; [ 80] BiAttack
    db $0d   ; [ 81] QuadHits
    db $0d   ; [ 82] CallHelp
    db $0d   ; [ 83] YellHelp
    db $0d   ; [ 84] Focus
    db $0d   ; [ 85] SquallHit
    db $0d   ; [ 86] PsycheUp
    db $0d   ; [ 87] RainSlash
    db $0d   ; [ 88] WindBeast
    db $0d   ; [ 89] Vacuum
    db $0d   ; [ 90] Lightning
    db $0d   ; [ 91] RockThrow
    db $0d   ; [ 92] FireAir
    db $0d   ; [ 93] BlazeAir
    db $0d   ; [ 94] Scorching
    db $0d   ; [ 95] WhiteFire
    db $0d   ; [ 96] FrigidAir
    db $0d   ; [ 97] IceAir
    db $0d   ; [ 98] IceStorm
    db $0d   ; [ 99] WhiteAir
    db $0d   ; [100] Hellblast
    db $0d   ; [101] BigBang
    db $0d   ; [102] MegaMagic
    db $0d   ; [103] PoisonHit
    db $0d   ; [104] NapAttack
    db $0d   ; [105] Paralyze
    db $0d   ; [106] SleepAir
    db $0d   ; [107] PalsyAir
    db $0d   ; [108] PoisonGas
    db $0d   ; [109] PoisonAir
    db $0d   ; [110] PaniDance
    db $0d   ; [111] Curse
    db $0d   ; [112] Ahhh
    db $0d   ; [113] K.O.Dance
    db $0d   ; [114] SandStorm
    db $04   ; [115] Radiant
    db $04   ; [116] EerieLite
    db $0d   ; [117] OddDance
    db $00   ; [118] RobDance
    db $0d   ; [119] SideStep
    db $0d   ; [120] LureDance
    db $0d   ; [121] LushLicks
    db $0d   ; [122] SickLick
    db $0d   ; [123] LegSweep
    db $0d   ; [124] BigTrip
    db $0d   ; [125] WarCry
    db $0d   ; [126] Whistle
    db $0d   ; [127] Imitate
    db $01   ; [128] DeMagic
    db $04   ; [129] Surge
    db $05   ; [130] UltraDown
    db $05   ; [131] ThickFog
    db $04   ; [132] TatsuCall
    db $04   ; [133] DiagoCall
    db $04   ; [134] SamsiCall
    db $04   ; [135] BazooCall
    db $0d   ; [136] Cover
    db $0d   ; [137] Guardian
    db $0d   ; [138] TailWind
    db $0d   ; [139] StormWind
    db $0d   ; [140] Dodge
    db $0d   ; [141] Defence
    db $0d   ; [142] StrongD
    db $0d   ; [143] SuckAll
    db $0d   ; [144] BladeD
    db $0d   ; [145] DanceShut
    db $0d   ; [146] MouthShut
    db $00   ; [147] Meditate
    db $00   ; [148] Hustle
    db $0d   ; [149] LifeSong
    db $00   ; [150] LifeDance
    db $0d   ; [151] Run
    db $0d   ; [152] Daze
    db $0d   ; [153] HitAlly
    db $0d   ; [154] HitEnemy
    db $0d   ; [155] HitRandom
    db $0d   ; [156] Scared
    db $0d   ; [157] Dance
    db $0d   ; [158] Trip
    db $0d   ; [159] Paralyze
    db $0d   ; [160] CANTMOVE
    db $0d   ; [161] RUN
    db $0d   ; [162] CALLHOROR
    db $00   ; [163] HealUsAll
    db $0d   ; [164] Smashed
    db $05   ; [165] FILTHZONE
    db $0d   ; [166] ALLCHANGE
    db $00   ; [167] BIGSLEEP
    db $00   ; [168] MP0
    db $0d   ; [169] ECHO
    db $00   ; [170] CHGDRAGON
    db $0d   ; [171] CALLEVIL
    db $0d   ; [172] FREEZY
    db $0d   ; [173] ALLREVIVE
    db $00   ; [174] RESTOREMP
    db $0d   ; [175] METEOR
    db $0d   ; [176] HERB
    db $0d   ; [177] HEALWATER
    db $0d   ; [178] SAGESTONE
    db $0d   ; [179] WARLDDEW
    db $0d   ; [180] POTION
    db $0d   ; [181] ELFWATER
    db $0d   ; [182] ANTIDOTE
    db $0d   ; [183] MOONHERB
    db $0d   ; [184] SKYBELL
    db $0d   ; [185] LAUREL
    db $0d   ; [186] AWAKESAND
    db $0d   ; [187] WARLDLEAF
    db $0d   ; [188] LIFEACORN
    db $0d   ; [189] MYSTICNUT
    db $0d   ; [190] PWRSEED
    db $0d   ; [191] DEFSEED
    db $0d   ; [192] AGILSEED
    db $0d   ; [193] INTSEED
    db $0d   ; [194] FEEDMEAT
    db $0d   ; [195] BEFFJERKY
    db $0d   ; [196] PORKCHOP
    db $0d   ; [197] BADMEAT
    db $0d   ; [198] SIRLOIN
    db $0d   ; [199] BOLTSTAFF
    db $0d   ; [200] STAFF
    db $0d   ; [201] BLOKSTAFF
    db $0d   ; [202] LAVASTAFF
    db $0d   ; [203] SNOWSTAFF
    db $0d   ; [204] FIRESTAFF
    db $0d   ; [205] WARPWING
    db $0d   ; [206] TINYMEDAL
    db $0d   ; [207] QuestBk
    db $0d   ; [208] HORRORBK
    db $0d   ; [209] BENICEBK
    db $0d   ; [210] CHEATERBK
    db $0d   ; [211] SMARTBK
    db $0d   ; [212] COMEDYBK
    db $00   ; [213] BeDragon
    db $0d   ; [214] Smashlime
    db $0d   ; [215] Sheldodge
    db $0d   ; [216] Branching
    db $0d   ; [217] GigaSlash
    db $0d   ; [218] LIFE
    db $0d   ; [219] RUN
    db $0d   ; [220] IRONIZE
    db $0d   ; [221] Ahhh
    db $0d   ; [222] 
    db $0d   ; [223] 
    db $0d   ; [224] 
    db $0d   ; [225] 
    db $0d   ; [226] 
    db $0d   ; [227] 
    db $0d   ; [228] 
    db $0d   ; [229] 
AnimRoutineIdxLink:
    ; ROUTINE index per skill id when the link battle's second side (d9ee = 5) (230 rows; AnimSkillVisual).
    db $0d   ; [  0] Blaze
    db $0d   ; [  1] Blazemore
    db $0d   ; [  2] Blazemost
    db $0b   ; [  3] Firebal
    db $0b   ; [  4] Firebane
    db $0b   ; [  5] Firebolt
    db $04   ; [  6] Bang
    db $04   ; [  7] Boom
    db $08   ; [  8] Explodet
    db $0d   ; [  9] Infernos
    db $0c   ; [ 10] Infermore
    db $0c   ; [ 11] Infermost
    db $0b   ; [ 12] IceBolt
    db $04   ; [ 13] SnowStorm
    db $0b   ; [ 14] Blizzard
    db $04   ; [ 15] Bolt
    db $04   ; [ 16] Zap
    db $08   ; [ 17] Thordain
    db $0d   ; [ 18] Beat
    db $0d   ; [ 19] Defeat
    db $0d   ; [ 20] Sacrifice
    db $0d   ; [ 21] Sleep
    db $0d   ; [ 22] SleepAll
    db $0d   ; [ 23] StopSpell
    db $0d   ; [ 24] Surround
    db $0d   ; [ 25] PanicAll
    db $0d   ; [ 26] RobMagic
    db $0d   ; [ 27] TakeMagic
    db $0d   ; [ 28] Sap
    db $0d   ; [ 29] Defence
    db $0d   ; [ 30] Upper
    db $0d   ; [ 31] Increase
    db $0d   ; [ 32] Slow
    db $0d   ; [ 33] SlowAll
    db $0d   ; [ 34] Speed
    db $0d   ; [ 35] SpeedUp
    db $0d   ; [ 36] Barrier
    db $0d   ; [ 37] TwinHits
    db $0d   ; [ 38] MagicWall
    db $0d   ; [ 39] MagicBack
    db $0d   ; [ 40] Bounce
    db $0d   ; [ 41] Transform
    db $0d   ; [ 42] Ironize
    db $0d   ; [ 43] Heal
    db $0d   ; [ 44] HealMore
    db $0d   ; [ 45] HealAll
    db $0d   ; [ 46] HealUs
    db $0d   ; [ 47] HealUsAll
    db $0d   ; [ 48] Vivify
    db $0d   ; [ 49] Revive
    db $0d   ; [ 50] Farewell
    db $0d   ; [ 51] Antidote
    db $0d   ; [ 52] NumbOff
    db $0d   ; [ 53] DeChaos
    db $0d   ; [ 54] CurseOff
    db $0d   ; [ 55] StepGuard
    db $0d   ; [ 56] MapMagic
    db $06   ; [ 57] Chance
    db $0d   ; [ 58] Attack
    db $0d   ; [ 59] TwinSlash
    db $0d   ; [ 60] Ramming
    db $0d   ; [ 61] Beserker
    db $0d   ; [ 62] Kamikaze
    db $0d   ; [ 63] Massacre
    db $0d   ; [ 64] EvilSlash
    db $0d   ; [ 65] ChargeUP
    db $0d   ; [ 66] HighJump
    db $0d   ; [ 67] SuckAir
    db $0d   ; [ 68] FireSlash
    db $0d   ; [ 69] BoltSlash
    db $0d   ; [ 70] VacuSlash
    db $0d   ; [ 71] IceSlash
    db $0d   ; [ 72] MetalCut
    db $0d   ; [ 73] DrakSlash
    db $0d   ; [ 74] BeastCut
    db $0d   ; [ 75] BirdBlow
    db $0d   ; [ 76] DevilCut
    db $0d   ; [ 77] ZombieCut
    db $0d   ; [ 78] CleanCut
    db $0a   ; [ 79] MultiCut
    db $0d   ; [ 80] BiAttack
    db $0d   ; [ 81] QuadHits
    db $0d   ; [ 82] CallHelp
    db $0d   ; [ 83] YellHelp
    db $0d   ; [ 84] Focus
    db $0d   ; [ 85] SquallHit
    db $0d   ; [ 86] PsycheUp
    db $0d   ; [ 87] RainSlash
    db $0d   ; [ 88] WindBeast
    db $0c   ; [ 89] Vacuum
    db $0a   ; [ 90] Lightning
    db $0d   ; [ 91] RockThrow
    db $0b   ; [ 92] FireAir
    db $0b   ; [ 93] BlazeAir
    db $0b   ; [ 94] Scorching
    db $0a   ; [ 95] WhiteFire
    db $0b   ; [ 96] FrigidAir
    db $04   ; [ 97] IceAir
    db $0b   ; [ 98] IceStorm
    db $0a   ; [ 99] WhiteAir
    db $06   ; [100] Hellblast
    db $08   ; [101] BigBang
    db $08   ; [102] MegaMagic
    db $0d   ; [103] PoisonHit
    db $0d   ; [104] NapAttack
    db $0d   ; [105] Paralyze
    db $0d   ; [106] SleepAir
    db $0d   ; [107] PalsyAir
    db $0d   ; [108] PoisonGas
    db $0d   ; [109] PoisonAir
    db $0d   ; [110] PaniDance
    db $0d   ; [111] Curse
    db $0d   ; [112] Ahhh
    db $0d   ; [113] K.O.Dance
    db $0d   ; [114] SandStorm
    db $04   ; [115] Radiant
    db $04   ; [116] EerieLite
    db $0d   ; [117] OddDance
    db $0d   ; [118] RobDance
    db $0d   ; [119] SideStep
    db $0d   ; [120] LureDance
    db $0d   ; [121] LushLicks
    db $0d   ; [122] SickLick
    db $0d   ; [123] LegSweep
    db $0d   ; [124] BigTrip
    db $0d   ; [125] WarCry
    db $0d   ; [126] Whistle
    db $0d   ; [127] Imitate
    db $01   ; [128] DeMagic
    db $04   ; [129] Surge
    db $05   ; [130] UltraDown
    db $05   ; [131] ThickFog
    db $0d   ; [132] TatsuCall
    db $0d   ; [133] DiagoCall
    db $0d   ; [134] SamsiCall
    db $0d   ; [135] BazooCall
    db $0d   ; [136] Cover
    db $0d   ; [137] Guardian
    db $0d   ; [138] TailWind
    db $0d   ; [139] StormWind
    db $0d   ; [140] Dodge
    db $0d   ; [141] Defence
    db $0d   ; [142] StrongD
    db $0d   ; [143] SuckAll
    db $0d   ; [144] BladeD
    db $0d   ; [145] DanceShut
    db $0d   ; [146] MouthShut
    db $0d   ; [147] Meditate
    db $0d   ; [148] Hustle
    db $0d   ; [149] LifeSong
    db $0d   ; [150] LifeDance
    db $0d   ; [151] Run
    db $0d   ; [152] Daze
    db $0d   ; [153] HitAlly
    db $0d   ; [154] HitEnemy
    db $0d   ; [155] HitRandom
    db $0d   ; [156] Scared
    db $0d   ; [157] Dance
    db $0d   ; [158] Trip
    db $0d   ; [159] Paralyze
    db $0d   ; [160] CANTMOVE
    db $0d   ; [161] RUN
    db $0d   ; [162] CALLHOROR
    db $0d   ; [163] HealUsAll
    db $0d   ; [164] Smashed
    db $05   ; [165] FILTHZONE
    db $0d   ; [166] ALLCHANGE
    db $0d   ; [167] BIGSLEEP
    db $0d   ; [168] MP0
    db $0d   ; [169] ECHO
    db $0d   ; [170] CHGDRAGON
    db $0d   ; [171] CALLEVIL
    db $0d   ; [172] FREEZY
    db $0d   ; [173] ALLREVIVE
    db $0d   ; [174] RESTOREMP
    db $0d   ; [175] METEOR
    db $0d   ; [176] HERB
    db $0d   ; [177] HEALWATER
    db $0d   ; [178] SAGESTONE
    db $0d   ; [179] WARLDDEW
    db $0d   ; [180] POTION
    db $0d   ; [181] ELFWATER
    db $0d   ; [182] ANTIDOTE
    db $0d   ; [183] MOONHERB
    db $0d   ; [184] SKYBELL
    db $0d   ; [185] LAUREL
    db $0d   ; [186] AWAKESAND
    db $0d   ; [187] WARLDLEAF
    db $0d   ; [188] LIFEACORN
    db $0d   ; [189] MYSTICNUT
    db $0d   ; [190] PWRSEED
    db $0d   ; [191] DEFSEED
    db $0d   ; [192] AGILSEED
    db $0d   ; [193] INTSEED
    db $0d   ; [194] FEEDMEAT
    db $0d   ; [195] BEFFJERKY
    db $0d   ; [196] PORKCHOP
    db $0d   ; [197] BADMEAT
    db $0d   ; [198] SIRLOIN
    db $0d   ; [199] BOLTSTAFF
    db $0d   ; [200] STAFF
    db $0d   ; [201] BLOKSTAFF
    db $0d   ; [202] LAVASTAFF
    db $0d   ; [203] SNOWSTAFF
    db $0d   ; [204] FIRESTAFF
    db $0d   ; [205] WARPWING
    db $0d   ; [206] TINYMEDAL
    db $0d   ; [207] QuestBk
    db $0d   ; [208] HORRORBK
    db $0d   ; [209] BENICEBK
    db $0d   ; [210] CHEATERBK
    db $0d   ; [211] SMARTBK
    db $0d   ; [212] COMEDYBK
    db $0d   ; [213] BeDragon
    db $0d   ; [214] Smashlime
    db $0d   ; [215] Sheldodge
    db $0d   ; [216] Branching
    db $0d   ; [217] GigaSlash
    db $0d   ; [218] LIFE
    db $0d   ; [219] RUN
    db $0d   ; [220] IRONIZE
    db $0d   ; [221] Ahhh
    db $0d   ; [222] 
    db $0d   ; [223] 
    db $0d   ; [224] 
    db $0d   ; [225] 
    db $0d   ; [226] 
    db $0d   ; [227] 
    db $0d   ; [228] 
    db $0d   ; [229] 
; NOTE: unreferenced fake-decode labels removed with this block: jr_05f_5756, jr_05f_577c
IsAttackerPartySide:
    ld a, [$c863]
    bit 1, a
    jr nz, jr_05f_5b9c

    ld a, [wBattleAttackerIdx]
    cp $04
    ret


jr_05f_5b9c:
    ld a, [wBattleAttackerIdx]
    cp $04
    ccf
    ret


IsTargetPartySide:
    ld a, [$c863]
    bit 1, a
    jr nz, jr_05f_5bb0

    ld a, [wBattleTargetIdx]
    cp $04
    ret


jr_05f_5bb0:
    ld a, [wBattleTargetIdx]
    cp $04
    ccf
    ret


; bank $5F entry 8 = game mode 5 init: the developers' "Effect" animation debugger (S112)
EffectDebuggerInit:
    xor a
    ld hl, wMenu_selection
    ld bc, $0008
    call FillNBytesWithRegA
    xor a
    ld hl, $c827
    ld bc, $0012
    call FillNBytesWithRegA
    call ClearSTATMode
    ld hl, $c817
    ld [hl], $00
    inc hl
    ld [hl], $00
    ld hl, $0801
    rst $10
    ld a, $e0
    ld hl, $c500
    ld bc, $0240
    call FillNBytesWithRegA
    xor a
    ld hl, $da82
    ld bc, $0006
    call FillNBytesWithRegA
    ld de, $ff00
    ld hl, $9000
    ld bc, $0120
    call IntFldUI_5ecc
    ld de, $6093
    ld hl, $c500
    call LoadFldUI_4263
    ld de, $60fe
    ld hl, $c500
    call LoadFldUI_4263
    ld de, $6169
    ld hl, $c500
    call LoadFldUI_4263
    ld de, $2e00
    ld hl, $8d00
    call WaitLCDTransfer
    ld hl, $6195
    ld de, $8b90
    call ReadFldUI_5f58
    ld hl, $61ad
    ld de, $8ab0
    call ReadFldUI_5f58
    call SetFldUI_5f86
    call SetFldUI_5fa5
    call SetFldUI_5fbc
    call SetFldUI_5fdb
    ld a, $fc
    call SetGBCPalette
    ld hl, $9800
    ld a, l
    ld [$d9f8], a
    ld a, h
    ld [$d9f9], a
    ld hl, $5005
    rst $10
    ld a, $01
    ld [$dd68], a
    ld a, $01
    ld [$db54], a
    ld a, $01
    ld [$da82], a
    ld a, $03
    ld [wMenu_selection], a
    ld a, $07
    ldh [$b5], a
    ld a, $ff
    ldh [$b6], a
    ld a, $00
    ldh [$bb], a
    ld a, $00
    ldh [$b7], a
    xor a
    ld [$c8a4], a
    ld [$c8a5], a
    xor a
    ld [$c892], a
    ld a, $03
    ld [$c8a1], a
    call EnableLYCInterrupt
    ld a, $03
    jp EnableLCDAndInterrupts


; bank $5F entry 9 = game mode 5 per frame: rows 0 animation (A plays it) / 1 / 2 / 3 screen effects; tools/census_battle_anims.py drives it (S112)
EffectDebuggerFrame:
    ld a, [$da83]
    cp $09
    jr nz, jr_05f_5c9b

    ld a, [$da82]
    or a
    jp z, Jump_05f_5ec1

jr_05f_5c9b:
    ld a, [$c850]
    or a
    ret nz

    ld a, [$dd62]
    or a
    jp nz, Jump_05f_5ea3

    ld a, [wMenu_selection]
    rst $00
    or e
    ld e, h
    db $d3
    ld e, h
    rst $28
    ld e, h
    ld a, [bc]
    ld e, l
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp nz, Jump_05f_5dd7

    bit 1, a
    jp nz, Jump_05f_5e3e

    bit 6, a
    jp nz, Jump_05f_5d75

    bit 7, a
    jp nz, Jump_05f_5d61

    bit 5, a
    jr nz, jr_05f_5d4c

    bit 4, a
    jr nz, jr_05f_5d36

    ret


    ld a, [wJoypad_current_frame]
    bit 1, a
    jp nz, Jump_05f_5e3e

    bit 6, a
    jp nz, Jump_05f_5d75

    bit 7, a
    jr nz, jr_05f_5d61

    bit 5, a
    jp nz, Jump_05f_5d91

    bit 4, a
    jp nz, Jump_05f_5d91

    ret


    ld a, [wJoypad_current_frame]
    bit 1, a
    jp nz, Jump_05f_5e3e

    bit 6, a
    jr nz, jr_05f_5d75

    bit 7, a
    jr nz, jr_05f_5d61

    bit 5, a
    jp nz, Jump_05f_5dc2

    bit 4, a
    jp nz, Jump_05f_5da4

    ret


    ld a, [$da82]
    or a
    jr z, jr_05f_5d30

    ld a, [wJoypad_current_frame]
    bit 0, a
    jp nz, Jump_05f_5e87

    bit 1, a
    jp nz, Jump_05f_5e3e

    bit 6, a
    jr nz, jr_05f_5d75

    bit 7, a
    jr nz, jr_05f_5d61

    bit 5, a
    jp nz, Jump_05f_5e72

    bit 4, a
    jp nz, Jump_05f_5e5c

    ret


jr_05f_5d30:
    call SetFldUI_5e27
    jp Jump_05f_5ec1


jr_05f_5d36:
    ld a, [wOPTN_and_Item_selection]
    inc a
    ld [wOPTN_and_Item_selection], a
    ld a, [wOPTN_and_Item_selection]
    cp $2d
    jr c, jr_05f_5d48

    xor a
    ld [wOPTN_and_Item_selection], a

jr_05f_5d48:
    call SetFldUI_5f86
    ret


jr_05f_5d4c:
    ld a, [wOPTN_and_Item_selection]
    dec a
    ld [wOPTN_and_Item_selection], a
    ld a, [wOPTN_and_Item_selection]
    cp $2d
    jr c, jr_05f_5d48

    ld a, $2c
    ld [wOPTN_and_Item_selection], a
    jr jr_05f_5d48

Jump_05f_5d61:
jr_05f_5d61:
    ld a, [wMenu_selection]
    inc a
    ld [wMenu_selection], a
    ld a, [wMenu_selection]
    cp $04
    jr c, jr_05f_5d88

    xor a
    ld [wMenu_selection], a
    jr jr_05f_5d88

Jump_05f_5d75:
jr_05f_5d75:
    ld a, [wMenu_selection]
    dec a
    ld [wMenu_selection], a
    ld a, [wMenu_selection]
    cp $04
    jr c, jr_05f_5d88

    ld a, $03
    ld [wMenu_selection], a

jr_05f_5d88:
    rst $00
    ldh [$5e], a
    db $f4
    ld e, [hl]
    dec bc
    ld e, a
    rra
    ld e, a

Jump_05f_5d91:
    ld a, [wPLAN_selection]
    xor $01
    ld [wPLAN_selection], a
    call SetFldUI_5fa5
    ld a, [wPLAN_selection]
    rst $00
    ld l, l
    ld h, b
    ld a, d
    ld h, b

Jump_05f_5da4:
    ld a, [$c8dd]
    inc a
    ld [$c8dd], a
    ld a, [$c8dd]
    cp $d8
    jr c, jr_05f_5db6

    xor a
    ld [$c8dd], a

jr_05f_5db6:
    call SetFldUI_5fbc
    ld a, [wPLAN_selection]
    or a
    ret z

    call LoadFldUI_607a
    ret


Jump_05f_5dc2:
    ld a, [$c8dd]
    dec a
    ld [$c8dd], a
    ld a, [$c8dd]
    cp $d8
    jr c, jr_05f_5db6

    ld a, $d7
    ld [$c8dd], a
    jr jr_05f_5db6

Jump_05f_5dd7:
    ld a, [wOPTN_and_Item_selection]
    ld hl, $61ee
    ld c, a
    ld b, $00
    add hl, bc
    add hl, bc
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld hl, $8000
    call WaitDMATransfer
    ld a, [wOPTN_and_Item_selection]
    ld [$c81e], a
    ld hl, $170d
    rst $10
    ld hl, $1708
    rst $10
    ld a, [wOPTN_and_Item_selection]
    ld [$daa4], a
    ld a, [wOPTN_and_Item_selection]
    ld [$da81], a
    ld a, [$daa4]
    ld [$dd64], a
    ld a, $60
    ld [$dd63], a
    ld a, $00
    ld [$dd62], a
    ld hl, $dd62
    ld a, l
    ld [$d7b4], a
    ld a, h
    ld [$d7b5], a
    ld hl, $0200
    rst $10
    call SetFldUI_6014

SetFldUI_5e27:
jr_05f_5e27:
    ld hl, $c6cd
    call IntFldUI_5f36
    call IntFldUI_5f36
    call IntFldUI_5f36
    ld hl, $c56d
    call IntFldUI_5f36
    ld hl, $5005
    rst $10
    ret


Jump_05f_5e3e:
    ld a, $04
    call SetGBCPalette
    ld a, $07
    ld [wGameMode], a
    ld a, $00
    ld [$c88b], a
    ld a, $00
    ld [$c88c], a
    ld a, $00
    ld [$c88d], a
    ld hl, $c88e
    inc [hl]
    ret


Jump_05f_5e5c:
    ld a, [$c8e1]
    inc a
    ld [$c8e1], a
    ld a, [$c8e1]
    cp $0d
    jr c, jr_05f_5e6e

    xor a
    ld [$c8e1], a

jr_05f_5e6e:
    call SetFldUI_5fdb
    ret


Jump_05f_5e72:
    ld a, [$c8e1]
    dec a
    ld [$c8e1], a
    ld a, [$c8e1]
    cp $0d
    jr c, jr_05f_5e6e

    ld a, $0c
    ld [$c8e1], a
    jr jr_05f_5e6e

Jump_05f_5e87:
    ld a, $04
    ld [wBattleTargetIdx], a
    ld a, $01
    ld [$db75], a
    xor a
    ld hl, $da82
    ld bc, $0006
    call FillNBytesWithRegA
    ld a, [$c8e1]
    ld [$da83], a
    jr jr_05f_5e27

Jump_05f_5ea3:
    ld a, [$dd62]
    or a
    jr z, jr_05f_5eb5

    call LoadFldUI_5ffa
    ld hl, $0200
    rst $10
    ld a, [$dd62]
    or a
    ret nz

jr_05f_5eb5:
    ld a, [wMenu_selection]
    rst $00
    ldh [$5e], a
    db $f4
    ld e, [hl]
    dec bc
    ld e, a
    rra
    ld e, a

Jump_05f_5ec1:
    ld hl, $5f05
    rst $10
    ld a, [$da82]
    or a
    ret z

    jr jr_05f_5f1f

IntFldUI_5ecc:
jr_05f_5ecc:
    di
    call WaitVRAM
    ld a, d
    ld [hl+], a
    ei
    di
    call WaitVRAM
    ld a, e
    ld [hl+], a
    ei
    dec bc
    ld a, b
    or c
    jr nz, jr_05f_5ecc

    ret


    ld hl, $c6cd
    call IntFldUI_5f47
    call CallFldUI_5f33
    ld hl, $c56d
    call IntFldUI_5f36
    ld hl, $5005
    rst $10
    ret


    ld hl, $c6cd
    call IntFldUI_5f36
    call IntFldUI_5f47
    call IntFldUI_5f36
    ld hl, $c56d
    call IntFldUI_5f36
    ld hl, $5005
    rst $10
    ret


    ld hl, $c6cd
    call CallFldUI_5f33
    call IntFldUI_5f47
    ld hl, $c56d
    call IntFldUI_5f36
    ld hl, $5005
    rst $10
    ret


jr_05f_5f1f:
    ld hl, $c6cd
    call IntFldUI_5f36
    call CallFldUI_5f33
    ld hl, $c56d
    call IntFldUI_5f47
    ld hl, $5005
    rst $10
    ret


CallFldUI_5f33:
    call IntFldUI_5f36

IntFldUI_5f36:
    di
    call WaitVRAM
    ld a, $e0
    ld [hl], a
    ei
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ret


IntFldUI_5f47:
    di
    call WaitVRAM
    ld a, $e8
    ld [hl], a
    ei
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ret


ReadFldUI_5f58:
jr_05f_5f58:
    ld a, [hl+]
    cp $ff
    ret z

    push hl
    push de
    ld hl, $c180
    push de
    call PushHLSetupL
    pop de
    ld hl, $c180
    call FuncFldUI_5f78
    pop de
    pop hl
    ld a, $10
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    jr jr_05f_5f58

FuncFldUI_5f78:
    ld b, $10

jr_05f_5f7a:
    di
    call WaitVRAM
    ld a, [hl+]
    ld [de], a
    ei
    inc de
    dec b
    jr nz, jr_05f_5f7a

    ret


SetFldUI_5f86:
    ld hl, $c8de
    ld a, [wOPTN_and_Item_selection]
    and $f0
    call FuncFldUI_6248
    ld [hl+], a
    ld a, [wOPTN_and_Item_selection]
    and $0f
    ld [hl+], a
    ld a, $ff
    ld [hl], a
    ld de, $8b40
    ld hl, $c8de
    call ReadFldUI_5f58
    ret


SetFldUI_5fa5:
    ld hl, $61b5
    ld a, [wPLAN_selection]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld de, $8b60
    call ReadFldUI_5f58
    ret


SetFldUI_5fbc:
    ld hl, $c8de
    ld a, [$c8dd]
    and $f0
    call FuncFldUI_6248
    ld [hl+], a
    ld a, [$c8dd]
    and $0f
    ld [hl+], a
    ld a, $ff
    ld [hl], a
    ld de, $8b20
    ld hl, $c8de
    call ReadFldUI_5f58
    ret


SetFldUI_5fdb:
    ld hl, $c8de
    ld a, [$c8e1]
    and $f0
    call FuncFldUI_6248
    ld [hl+], a
    ld a, [$c8e1]
    and $0f
    ld [hl+], a
    ld a, $ff
    ld [hl], a
    ld de, $8a90
    ld hl, $c8de
    call ReadFldUI_5f58
    ret


LoadFldUI_5ffa:
    ld a, [wOPTN_and_Item_selection]
    cp $0e
    jr c, jr_05f_600a

    cp $21
    jr c, jr_05f_600f

    ld hl, $5e00
    rst $10
    ret


jr_05f_600a:
    ld hl, $5c00
    rst $10
    ret


jr_05f_600f:
    ld hl, $5d00
    rst $10
    ret


SetFldUI_6014:
    ld hl, wBGPalette
    inc hl
    ld a, $d0
    ld [hl+], a
    ld a, $e0
    ld [hl], a
    ld hl, EffectDebugShadeTable        ; [S112] the debugger's shade copy
    ld a, [wOPTN_and_Item_selection]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [wObj1Palette], a
    ld a, [wOPTN_and_Item_selection]
    cp $03
    jr z, jr_05f_6049

    cp $04
    jr z, jr_05f_6049

    cp $0a
    jr z, jr_05f_6049

    ld a, $01
    ld [$dd68], a
    ld a, $01
    ld [$db54], a
    jr jr_05f_6053

jr_05f_6049:
    ld a, $00
    ld [$dd68], a
    ld a, $00
    ld [$db54], a

jr_05f_6053:
    ld a, [wOPTN_and_Item_selection]
    cp $0e
    jr c, jr_05f_6063

    cp $21
    jr c, jr_05f_6068

    ld hl, $5e01
    rst $10
    ret


jr_05f_6063:
    ld hl, $5c01
    rst $10
    ret


jr_05f_6068:
    ld hl, $5d01
    rst $10
    ret


    ld de, $ff00
    ld hl, $9000
    ld bc, $0120
    call IntFldUI_5ecc
    ret


LoadFldUI_607a:
    ld a, [$c8dd]
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
    ld hl, $9000
    call WaitDMATransfer
    ret


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
    call nz, $c6c5
    ldh [$c7], a
    ret z

    ldh [$e0], a
    ldh [$e0], a
    or h
    or l
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ret


    jp z, $cccb

    call $cfce
    ldh [$e0], a
    ldh [$b6], a
    or a
    cp b
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
    or d
    or e
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
    cp c
    cp d
    cp e
    cp h
    cp l
    cp [hl]
    ldh [$bf], a
    ret nz

    pop bc
    jp nz, $e0c3

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
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    xor e
    xor h
    xor l
    xor [hl]
    xor a
    ldh [$b0], a
    or c
    ldh [$e8], a
    xor c
    xor d
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


    rst $00
    nop
    nop
    ld bc, $0302
    inc b
    dec b
    ret c

    ld b, $07
    ld [$0a09], sp
    dec bc
    ret c

    inc c
    dec c
    ld c, $0f
    db $10
    ld de, $12d8
    inc de
    inc d
    dec d
    ld d, $17
    ret c

    jr jr_05f_61a2

    ld a, [de]
    dec de
    inc e
    dec e
    ret c

    ld e, $1f
    jr nz, jr_05f_61b3

    ld [hl+], a
    inc hl
    reti


    dec bc
    ld a, [bc]
    dec e
    dec e
    dec d
    ld c, $0e
    rrca
    ld c, $0c
    dec e
    jr jr_05f_61ad

jr_05f_61a2:
    inc de
    rla
    jr jr_05f_61bc

    jr jr_05f_61bf

    inc e
    dec e
    ld c, $1b
    rst $38

jr_05f_61ad:
    ld c, $0f
    ld c, $0c
    dec e
    rla

jr_05f_61b3:
    jr @+$01

    cp c
    ld h, c
    cp l
    ld h, c
    jr jr_05f_61ca

    rrca

jr_05f_61bc:
    rst $38
    jr jr_05f_61d6

jr_05f_61bf:
    sub b
    rst $38
    ; [S112] $61C1-$61ED = EffectDebugShadeTable: the Effect debugger's copy of
    ; ROM0 AnimObjShadeTable (45 B, wObj1Palette per animation, read by
    ; SetFldUI_6014; byte-identical to $00:$3141). The jr_05f_61xx labels here and
    ; above are mgbdis artefacts of the debugger's menu text (kept: the bogus
    ; jr operands before them reference them).
EffectDebugShadeTable:
    db $e0, $e0, $e0, $e0, $e0, $e0, $d0, $d0, $d0
jr_05f_61ca:
    db $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0
jr_05f_61d6:
    db $d0, $d0, $e0, $e0, $e0, $e0, $e0, $d0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $e0, $d0
AnimGfxTableDebug:
    ; the Effect debugger's copy of AnimGfxTable (45 dw; game mode 5,
    ; EffectDebuggerFrame: A on row 0 plays animation [wOPTN_and_Item_selection]).
    dw $5a00   ; [$00] Blaze
    dw $5a01   ; [$01] Blazemore
    dw $5a02   ; [$02] Blazemost, COMEDYBK
    dw $5a03   ; [$03] Firebal, FireAir
    dw $5a04   ; [$04] Firebane, BlazeAir, LAVASTAFF
    dw $5a05   ; [$05] Firebolt, Scorching
    dw $5a06   ; [$06] Bang
    dw $5a07   ; [$07] Boom
    dw $5a08   ; [$08] Explodet
    dw $5a09   ; [$09] Infernos, WindBeast, STAFF
    dw $5a0a   ; [$0a] Infermore
    dw $5a0b   ; [$0b] Infermost, Vacuum
    dw $5a0c   ; [$0c] IceBolt, FrigidAir
    dw $5a0d   ; [$0d] SnowStorm, IceAir
    dw $5a0e   ; [$0e] Blizzard, IceStorm, SNOWSTAFF
    dw $5a0f   ; [$0f] Bolt, Lightning, BOLTSTAFF
    dw $5a10   ; [$10] Zap
    dw $5a11   ; [$11] Thordain
    dw $5a12   ; [$12] StopSpell, RobMagic, Sap, Defence, Slow, SlowAll (+6)
    dw $5a13   ; [$13] RobMagic, TakeMagic, Upper, Increase, Speed, SpeedUp (+2)
    dw $5a14   ; [$14] Heal, HealMore, HealAll, HealUs, HealUsAll, Farewell (+20)
    dw $5a15   ; [$15] Sleep, SleepAll, PoisonHit, NapAttack, Paralyze, SleepAir (+7)
    dw $5a16   ; [$16] PanicAll, PaniDance, Curse, Ahhh, LureDance
    dw $5a17   ; [$17] Surround, SandStorm
    dw $5a18   ; [$18] Transform, CHGDRAGON, BeDragon
    dw $5a19   ; [$19] MagicBack, Bounce
    dw $5a1a   ; [$1a] WhiteAir
    dw $5a1b   ; [$1b] RockThrow
    dw $5a1c   ; [$1c] WhiteFire
    dw $5a1d   ; [$1d] TwinSlash, Massacre, EvilSlash, DrakSlash, BeastCut, SquallHit (+2)
    dw $5a1e   ; [$1e] FireSlash
    dw $5a1f   ; [$1f] BoltSlash
    dw $5b0a   ; [$20] VacuSlash
    dw $5b0b   ; [$21] IceSlash
    dw $5b0c   ; [$22] Smashlime, Sheldodge
    dw $5b0d   ; [$23] BirdBlow
    dw $5b0e   ; [$24] DevilCut, ZombieCut
    dw $5b0f   ; [$25] MetalCut, CleanCut
    dw $5b10   ; [$26] GigaSlash
    dw $5b11   ; [$27] MultiCut
    dw $5b12   ; [$28] Hellblast
    dw $5b13   ; [$29] BigBang
    dw $5b14   ; [$2a] MegaMagic
    dw $5b15   ; [$2b] DeMagic
    dw $5b16   ; [$2c] FEEDMEAT, BEFFJERKY, PORKCHOP, SIRLOIN
FuncFldUI_6248:
    srl a
    srl a
    srl a
    srl a
    ret


    ld a, [wMenu_selection]
    bit 7, a
    ret nz

    ld a, [$da88]
    or a
    jr nz, jr_05f_62d7

    ld a, [wJoypad_current_frame]
    bit 2, a
    ret z

    ld a, $01
    ld [$da88], a
    ld hl, $6452
    ld de, $8860
    call ReadFldUI_5f58
    ld de, $63b0
    ld hl, $c500
    call LoadFldUI_4263

jr_05f_627a:
    ld a, [$c863]
    and $02
    rlca
    ld [$db4c], a
    inc a
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, l
    ld [$db4d], a
    ld a, h
    ld [$db4e], a
    call CallFldUI_62e5
    ld a, [$db4d]
    ld l, a
    ld a, [$db4e]
    ld h, a
    ld a, [hl]
    cp $ff
    jr z, jr_05f_62d2

    inc hl
    ld a, l
    ld [$db4d], a
    ld a, h
    ld [$db4e], a
    ld hl, $db4c
    inc [hl]
    call CallFldUI_62e5
    ld a, [$db4d]
    ld l, a
    ld a, [$db4e]
    ld h, a
    ld a, [hl]
    cp $ff
    jr z, jr_05f_62d2

    inc hl
    ld a, l
    ld [$db4d], a
    ld a, h
    ld [$db4e], a
    ld hl, $db4c
    inc [hl]
    call CallFldUI_62e5

jr_05f_62d2:
    ld hl, $5005
    rst $10
    ret


jr_05f_62d7:
    ld a, [wJoypad_current_frame]
    bit 2, a
    ret z

    xor a
    ld [$da88], a
    ld [wEventStateMachineIndex], a
    ret


CallFldUI_62e5:
    call ClrFldUI_633d
    ld a, [$db4c]
    ld hl, $dc44
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call FuncFldUI_6348
    ld hl, $643a
    call LoadFldUI_6360
    ld a, [$db4c]
    ld hl, $dc54
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call FuncFldUI_6348
    ld hl, $6440
    call LoadFldUI_6360
    ld a, [$db4c]
    ld hl, $dc4c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call FuncFldUI_6348
    ld hl, $6446
    call LoadFldUI_6360
    ld a, [$db4c]
    ld hl, $dc5c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call FuncFldUI_6348
    ld hl, $644c
    call LoadFldUI_6360
    ret


ClrFldUI_633d:
    xor a
    ld hl, $db4f
    ld bc, $0003
    call FillNBytesWithRegA
    ret


FuncFldUI_6348:
    ld b, [hl]
    ld a, $64
    call Div8x8
    ld hl, $db4f
    ld [hl], b
    ld b, a
    ld a, $0a
    call Div8x8
    ld hl, $db50
    ld [hl], b
    ld [$db51], a
    ret


LoadFldUI_6360:
    ld a, [$db4c]
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
    ld de, $c500
    add hl, de
    ld c, $00
    ld a, [$db4f]
    or c
    jr z, jr_05f_638a

    inc c
    ld a, [$db4f]
    ld de, $6430
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [hl], a

jr_05f_638a:
    inc hl
    ld a, [$db50]
    or c
    jr z, jr_05f_63a0

    inc c
    ld a, [$db50]
    ld de, $6430
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [hl], a

jr_05f_63a0:
    inc hl
    ld a, [$db51]
    ld de, $6430
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [hl], a
    ret


    add b
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

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    add [hl]
    ldh [$e0], a
    ldh [$e0], a
    ldh [$86], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    add a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$87], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    adc b
    ldh [$e0], a
    ldh [$e0], a
    ldh [$88], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    adc c
    ldh [$e0], a
    ldh [$e0], a
    ldh [$89], a
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
    xor $ee
    xor $ee
    db $fd
    reti


    ldh a, [$f1]
    ld a, [c]
    di
    db $f4
    push af
    or $f7
    ld hl, sp-$07
    and d
    ld bc, $01a8
    xor [hl]
    ld bc, $01c2
    ret z

    ld bc, $01ce
    ld [c], a
    ld bc, $01e8
    xor $01
    ld [bc], a
    ld [bc], a
    ld [$0e02], sp
    ld [bc], a
    ld c, d
    jr z, jr_05f_6484

    ld c, b
    rst $38
    add b
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld bc, $0302
    inc b
    dec b
    ret c

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld b, $07
    ld [$0a09], sp
    dec bc
    inc c
    ret c

    nop
    nop
    nop
    nop
    nop
    nop
    dec c
    ld c, $0f
    db $10
    ld de, $1312

jr_05f_6484:
    inc d
    ret c

    nop
    nop
    nop
    nop
    nop
    nop
    dec d

jr_05f_648d:
    ld d, $17
    jr jr_05f_64aa

    ld a, [de]
    dec de
    inc e
    ret c

    nop
    nop
    nop
    nop
    nop
    dec e
    ld e, $1f
    jr nz, jr_05f_64c0

    ld [hl+], a
    inc hl
    inc h
    dec h
    ld h, $d8
    nop
    nop
    nop
    nop
    nop

jr_05f_64aa:
    daa
    jr z, jr_05f_64d6

    ld a, [hl+]
    dec hl
    inc l
    dec l
    ld l, $2f
    jr nc, jr_05f_648d

    nop
    nop
    nop
    nop
    nop
    nop
    ld sp, $3332
    inc [hl]
    dec [hl]

jr_05f_64c0:
    ld [hl], $00
    jr c, @-$26

    nop
    nop
    nop
    nop
    nop
    nop
    add hl, sp
    ld a, [hl-]
    dec sp
    inc a
    dec a
    ld a, $3f
    ld b, b
    ret c

    nop
    nop
    nop

jr_05f_64d6:
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
    ret c

    nop
    nop
    nop
    nop
    nop
    nop
    ld c, c
    ld c, d
    ld c, e
    ld c, h
    ld c, l
    ld c, [hl]
    ld c, a
    scf
    reti


    and b
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ret c

    nop
    ld l, d
    ld l, e
    ld l, h
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld l, l
    ld l, [hl]
    ld l, a
    nop
    ret c

    nop
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    nop
    nop
    nop
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ld a, h
    ld a, l
    ld a, [hl]
    nop
    ret c

    nop
    nop
    ld a, a
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
    nop
    ret c

    nop
    nop
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
    and b
    nop
    ret c

    nop
    nop
    and c
    and d
    and e
    and h
    ld h, c
    ld h, d
    ld h, e
    ld h, h
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    xor [hl]
    xor a
    cp [hl]
    nop
    nop
    ret c

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    reti


    and b
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ret c

    nop
    ld l, d
    ld l, e
    ld l, h
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld l, l
    ld l, [hl]
    ld l, a
    nop
    ret c

    nop
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    nop
    nop
    nop
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ld a, h
    ld a, l
    ld a, [hl]
    nop
    ret c

    nop
    nop
    ld a, a
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
    nop
    ret c

    nop
    nop
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
    and b
    nop
    ret c

    nop
    nop
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
    cp [hl]
    nop
    nop
    ret c

    nop
    nop
    nop
    nop
    nop
    nop
    cp a
    call $cfce
    ret nc

    pop de
    jp nc, $d4d3

    nop
    nop
    nop
    ret nz

    nop
    ret c

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ret c

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ret c

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ret c

    nop
    nop
    nop
    cp d
    cp e
    cp h
    cp l
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
    nop
    nop
    nop
    ret c

    nop
    nop
    nop
    nop
    pop bc
    jp nz, $c4c3

    push bc
    add $c7
    ret z

    ret


    jp z, $cccb

    nop
    nop
    nop
    nop
    reti


    inc bc
    ld bc, $0201
    inc bc
    inc b
    dec b
    ld b, $07
    ld [$0a09], sp
    dec bc
    inc c
    dec c
    ld c, $d8
    rrca
    db $10
    ld de, $1312
    inc d
    dec d
    ld d, $17
    jr jr_05f_66a3

    ld a, [de]
    dec de
    inc e
    ret c

    dec e
    ld e, $1f
    jr nz, @+$23

    ld [hl+], a
    inc hl
    inc h
    dec h
    ld h, $27
    jr z, @+$2b

    ld a, [hl+]
    reti


    nop
    ld bc, Boot
    ld [bc], a
    inc bc

jr_05f_66a3:
    inc b
    dec b
    ld b, $07
    ld [$0a09], sp
    dec bc
    inc c
    dec c
    ld c, $0f
    db $10
    ld de, $d912
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rP1], a
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
    ld de, $e012
    ldh [rNR14], a
    dec d
    ld d, $17
    jr @+$1b

    ld a, [de]
    dec de
    inc e
    dec e
    ld e, $1f
    jr nz, jr_05f_6720

    ld [hl+], a
    inc hl
    inc h
    dec h
    ldh [$e0], a

jr_05f_6705:
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ld h, $27
    jr z, jr_05f_6746

    ld a, [hl+]
    dec hl
    inc l

jr_05f_6720:
    dec l
    ld l, $2f
    jr nc, jr_05f_6705

    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ld sp, $3332
    inc [hl]
    dec [hl]
    ld [hl], $37
    jr c, jr_05f_676f

    ld a, [hl-]
    dec sp
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$3c], a
    dec a
    ld a, $3f
    ld b, b

jr_05f_6746:
    ld b, c
    ld b, d
    ld b, e
    ld b, h
    ld b, l
    ld b, [hl]
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ld b, a
    ld c, b
    ld c, c
    ld c, d
    ld c, e
    ld c, h
    ld c, l
    ld c, [hl]
    ld c, a
    ld d, b
    ld d, c
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ld d, d
    ld d, e
    ld d, h
    ld d, l
    ld d, [hl]
    ld d, a

jr_05f_676f:
    ld e, b
    ld e, c
    ld e, d
    ld e, e
    ld e, h
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
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
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    ld l, l
    ld l, [hl]
    ld l, a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    xor d
    xor e
    xor h
    xor l
    xor [hl]
    xor a
    ldh [$e0], a
    ldh [$73], a
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ldh [$e0], a
    or b
    or c
    or d
    or e
    or h
    or l
    ldh [$e0], a
    ldh [$7e], a
    ld a, a
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    or [hl]
    or a
    cp b
    cp c
    cp d
    cp e
    ldh [$e0], a
    ldh [$e0], a
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    sub d
    cp h
    cp l
    cp [hl]
    cp a
    ret nz

    pop bc
    ldh [$e0], a
    ldh [$94], a
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
    jp nz, $c4c3

    push bc
    add $c7
    ldh [$e0], a
    ldh [$e0], a
    sbc a
    and b
    and c
    and d
    and e
    and h
    and l
    and [hl]
    and a
    ldh [$c8], a
    ret


    jp z, $cccb

    call $e0e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
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
    db $10
    ld de, $e012
    ldh [rNR14], a
    ldh [$15], a
    ld d, $17
    jr jr_05f_6879

    ld a, [de]
    dec de
    inc e
    dec e
    ld e, $1f
    jr nz, jr_05f_6889

    ld [hl+], a
    inc hl
    inc h
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a

jr_05f_6879:
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a

jr_05f_6889:
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rNR52], a
    daa
    jr z, jr_05f_68c1

    ld a, [hl+]
    dec hl
    inc l
    dec l
    ld l, $2f
    jr nc, jr_05f_68d1

    ld [hl-], a
    inc sp
    inc [hl]
    dec [hl]
    ld [hl], $37
    jr c, @-$1e

    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    inc a
    dec a
    ld a, $3f
    ld b, b

jr_05f_68c1:
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
    ldh [$e0], a

jr_05f_68d1:
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rHDMA2], a
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
    ld h, b
    ld h, c
    ld h, d
    ld h, e
    ld h, h
    ldh [$e0], a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    ld l, l
    ld l, [hl]
    ld l, a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    xor d
    xor e
    xor h
    xor l
    xor [hl]
    xor a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$73], a
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    or b
    or c
    or d
    or e
    or h
    or l
    ldh [$e0], a
    ldh [$7e], a
    ld a, a
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    or [hl]
    or a
    cp b
    cp c
    cp d
    cp e
    ldh [$e0], a
    ldh [$e0], a
    ldh [$89], a
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    cp h
    cp l
    cp [hl]
    cp a
    ret nz

    pop bc
    ldh [$e0], a
    ldh [$94], a
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
    jp nz, $c4c3

    push bc
    add $c7
    ldh [$e0], a
    ldh [$e0], a
    ldh [$9f], a
    and b
    and c
    and d
    and e
    and h
    and l
    and [hl]
    and a
    ret z

    ret


    jp z, $cccb

    call $e0e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rP1], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
