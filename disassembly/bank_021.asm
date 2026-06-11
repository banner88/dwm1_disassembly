; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $021", ROMX[$4000], BANK[$21]

    db $21 ; Bank number

    ; Cross-bank dispatch table (120 entries)
    ; Called via: ld hl, $21XX / rst $10
    dw SetAnim21_40f1                  ; Entry 0
    dw $40F8                          ; Entry 1
    dw $40FF                          ; Entry 2
    dw $4009                          ; Entry 3
    dw $4106                          ; Entry 4
    dw $420F                          ; Entry 5
    dw $4248                          ; Entry 6
    dw $42E8                          ; Entry 7
    dw $4349                          ; Entry 8
    dw $43D8                          ; Entry 9
    dw $4411                          ; Entry 10
    dw $44A2                          ; Entry 11
    dw $44CC                          ; Entry 12
    dw $4553                          ; Entry 13
    dw $462C                          ; Entry 14
    dw $46FF                          ; Entry 15
    dw $47D9                          ; Entry 16
    dw $480E                          ; Entry 17
    dw $483B                          ; Entry 18
    dw $489E                          ; Entry 19
    dw $48FE                          ; Entry 20
    dw $49C1                          ; Entry 21
    dw $4A4F                          ; Entry 22
    dw $4AB3                          ; Entry 23
    dw $4C01                          ; Entry 24
    dw $4C7C                          ; Entry 25
    dw $4E38                          ; Entry 26
    dw $4E88                          ; Entry 27
    dw $4F4F                          ; Entry 28
    dw $4FF7                          ; Entry 29
    dw $5046                          ; Entry 30
    dw $507A                          ; Entry 31
    dw $5154                          ; Entry 32
    dw $51C0                          ; Entry 33
    dw $5205                          ; Entry 34
    dw $529E                          ; Entry 35
    dw $5307                          ; Entry 36
    dw $5379                          ; Entry 37
    dw $5407                          ; Entry 38
    dw $5441                          ; Entry 39
    dw $5495                          ; Entry 40
    dw $54C0                          ; Entry 41
    dw $5554                          ; Entry 42
    dw $55B9                          ; Entry 43
    dw $5622                          ; Entry 44
    dw $565C                          ; Entry 45
    dw $56D6                          ; Entry 46
    dw $56F9                          ; Entry 47
    dw $5753                          ; Entry 48
    dw $5769                          ; Entry 49
    dw $57DD                          ; Entry 50
    dw $5873                          ; Entry 51
    dw $5931                          ; Entry 52
    dw $59A6                          ; Entry 53
    dw $59DB                          ; Entry 54
    dw $5A81                          ; Entry 55
    dw $5B31                          ; Entry 56
    dw $5B77                          ; Entry 57
    dw $5C3A                          ; Entry 58
    dw $5C97                          ; Entry 59
    dw $5CBC                          ; Entry 60
    dw $5CFD                          ; Entry 61
    dw $5DF4                          ; Entry 62
    dw $5E89                          ; Entry 63
    dw $5F0F                          ; Entry 64
    dw $5FDC                          ; Entry 65
    dw $60A1                          ; Entry 66
    dw $612D                          ; Entry 67
    dw $61A1                          ; Entry 68
    dw $6203                          ; Entry 69
    dw $6274                          ; Entry 70
    dw $62AC                          ; Entry 71
    dw $62DD                          ; Entry 72
    dw $6343                          ; Entry 73
    dw $6379                          ; Entry 74
    dw $64C7                          ; Entry 75
    dw $64F5                          ; Entry 76
    dw $652F                          ; Entry 77
    dw $658C                          ; Entry 78
    dw $66A6                          ; Entry 79
    dw $6713                          ; Entry 80
    dw $6744                          ; Entry 81
    dw $67B0                          ; Entry 82
    dw $688B                          ; Entry 83
    dw $690E                          ; Entry 84
    dw $6988                          ; Entry 85
    dw $69E3                          ; Entry 86
    dw $6A46                          ; Entry 87
    dw $6A6F                          ; Entry 88
    dw $6AEB                          ; Entry 89
    dw $6B91                          ; Entry 90
    dw $6C55                          ; Entry 91
    dw $6C97                          ; Entry 92
    dw $6CED                          ; Entry 93
    dw $6D0B                          ; Entry 94
    dw $6D41                          ; Entry 95
    dw $6D68                          ; Entry 96
    dw $6E5F                          ; Entry 97
    dw $6EA2                          ; Entry 98
    dw $6EDB                          ; Entry 99
    dw $6F2F                          ; Entry 100
    dw $6FAC                          ; Entry 101
    dw $704B                          ; Entry 102
    dw $7084                          ; Entry 103
    dw $717C                          ; Entry 104
    dw $71A8                          ; Entry 105
    dw $721E                          ; Entry 106
    dw $7305                          ; Entry 107
    dw $7346                          ; Entry 108
    dw $744D                          ; Entry 109
    dw $7520                          ; Entry 110
    dw $75B6                          ; Entry 111
    dw $76D3                          ; Entry 112
    dw $7709                          ; Entry 113
    dw $7849                          ; Entry 114
    dw $787C                          ; Entry 115
    dw $78E1                          ; Entry 116
    dw $7914                          ; Entry 117
    dw $7A4E                          ; Entry 118
    dw $7B4D                          ; Entry 119

SetAnim21_40f1:
    ld de, $4007
    call CallTextEngine
    ret


    ld de, $4007
    call RunTextHandler
    ret


    call SetAnim21_40f1
    call RequestScreenUpdate
    ret


    ld [$a39f], a
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld a, $62
    ld c, a
    ld d, d
    ld c, d
    ld c, h
    ld c, a
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    ld d, c
    ld b, d
    ld c, a
    ld c, a
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    ld b, d
    ld b, c
    rst $28
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld b, e

jr_021_4154:
    ld c, h
    ld c, a
    ld b, d
    ld b, [hl]
    ld b, h
    ld c, e
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
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
    ld a, [$eff7]
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    rst $28
    xor $3f
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ccf
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld b, [hl]
    ld b, d
    ld d, b
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $52
    ld c, e
    ccf
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld a, $3f
    ld c, c
    ld b, d
    rst $28
    xor $50
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $44
    ld c, h
    ld c, e
    ld c, e
    ld a, $62
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $50
    ld d, c
    ld a, $56
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld a, $49
    ld c, c
    rst $28
    xor $4b
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    dec a
    ld d, a
    ld d, a
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, b
    ld b, d
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4d
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    cpl
    ld b, d
    ld c, d
    ld c, d
    ld b, d
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld a, $ef
    xor $36
    ld d, c
    ld c, h
    ld c, e
    ld b, d
    jr nc, @+$40

    ld c, e
    ld e, a
    ld h, d
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld b, b
    ld b, b
    ld b, d
    ld c, l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $36
    ld d, c
    ld c, h
    ld c, e
    ld b, d
    jr nc, @+$40

    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $43
    ld a, $4f
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    rst $28
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $51
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    rst $28
    xor $4a
    ld a, $4b
    ld d, [hl]
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
    ld a, [$eff7]
    xor $9f
    and e
    ld h, $3e
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $44
    ld b, d
    ld d, c
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
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
    ld h, h
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    rst $28
    xor $2c
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4a
    ld b, [hl]
    ld c, e
    ld b, c
    ld e, [hl]
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_021_446c

    ld h, d
    ld [hl], $51
    ld c, h
    ld c, e
    ld b, d
    jr nc, jr_021_445c

    ld c, e
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $52
    ld d, b
    ld b, d
    ld h, d
    inc h
    ld b, l
    ld b, l
    ld b, l
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld c, h
    ld d, [hl]
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
    ld b, b
    ld a, $4b
    rst $28
    xor $52
    ld d, b
    ld b, d
    ld h, d
    inc h
    ld b, l
    ld b, l
    ld b, l
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $36
    ld d, c
    ld c, a
    ld a, $4b

jr_021_445c:
    ld b, h
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28

jr_021_446c:
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld l, c
    ld b, d
    ld h, d
    ld a, $49
    ld c, c
    rst $28
    xor $45
    ld a, $4f
    ld b, c
    ld b, b
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld [hl], $fa
    rst $30
    rst $28
    xor $40
    ld c, c
    ld a, $50
    ld d, b
    ld e, a
    ld h, d
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    rst $28
    xor $f6
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $ef
    xor $2f
    ld b, [hl]
    ld b, e
    ld b, d
    inc h
    ld b, b
    ld c, h
    ld c, a
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $38
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, d
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $2f
    ld a, $3f
    ld d, [hl]
    ld c, a
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, l
    ld h, d
    or [hl]
    rst $28
    xor $2d
    ld d, d
    ld b, c
    ld b, h
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    dec l
    ld d, d
    ld b, c
    ld b, h
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $2f
    ld b, d
    ld b, e
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    cpl
    ld a, $3f
    ld d, [hl]
    ld c, a
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, l
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld l, b
    rst $28
    xor $3e
    ccf
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    jr z, jr_021_45e7

    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    rst $28
    xor $45
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $42
    ld c, e
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_021_45fd

    ld d, c
    ld a, $49
    ld d, [hl]
    ld d, b
    rst $28
    xor $4e
    ld d, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld d, c
    ld b, d
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28

jr_021_45e7:
    xor $51
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h

jr_021_45fd:
    ld e, a
    ld h, d
    ld [hl-], a
    ld b, e
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    rst $28
    xor $2c
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld d, e
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc sp
    ld b, d
    ld c, a
    ld b, e
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $3e
    ccf
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, e
    ld c, h
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, jr_021_46ba

    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    rst $28
    xor $45
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $42
    ld c, e
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_021_46d0

    ld d, c
    ld a, $49
    ld d, [hl]
    ld d, b
    rst $28
    xor $4e
    ld d, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld d, c
    ld b, d
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28

jr_021_46ba:
    xor $51
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h

jr_021_46d0:
    ld e, a
    ld [hl-], a
    ld b, e
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld e, [hl]
    rst $28
    xor $2c
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld d, e
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld h, $4c
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4d
    ld a, $4f
    ld d, c
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld c, l
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $46
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, a
    ld l, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, e
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld d, h
    ld c, h
    ld h, d
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, c
    sbc h
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld a, [$eff7]
    xor $41
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld d, b
    ld e, [hl]
    ld h, d
    ld a, $ef
    xor $41
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, d
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld c, a
    ld c, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld d, c
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, e
    ld h, d
    jr nc, jr_021_4831

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $63
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld a, $4a
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, e
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr z, jr_021_4866

    ld b, d
    ld c, e
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, h
    ld h, d
    inc l
    ld l, d
    ld a, [$eff7]
    xor $51
    ld c, h

jr_021_4831:
    ld d, d
    ld b, b
    ld b, l
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    dec h
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld d, h
    ld c, h
    rst $28
    xor $40
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, c
    sbc h
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld b, c
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld d, b
    ld a, [$eff7]
    xor $40
    ld c, a
    ld b, d
    ld a, $51

jr_021_4866:
    ld b, d
    ld d, b
    ld h, d
    ld a, $ef
    xor $41
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, d
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld d, h
    ld c, e
    ld d, b
    ld h, d
    ld b, l
    ld d, d
    ld d, b
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, [hl]
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld d, c
    ld a, $46
    ld c, e
    ld a, [$eff7]
    xor $4d
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    or $63
    ld h, d
    inc h
    ld d, c
    rst $28
    xor $49
    ld a, $50
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld a, $49
    ld h, d
    ld c, d
    ld a, $51
    ld b, b
    ld b, l
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld l, h
    ld b, d
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
    ld b, d
    ld b, c
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, c
    ld a, $56
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    add hl, hl
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld c, h
    ld c, e
    ld e, [hl]
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld a, $49
    ld c, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $26
    ld b, l
    ld a, $4a
    ccf
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $37
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $2b
    ld c, h
    ld d, h
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, [hl]
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $2c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $3e
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $36
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    daa
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $50
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, [hl]
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld a, [$eff7]
    xor $50
    ld a, $4f
    ld b, b
    ld a, $50
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld a, $50
    rst $28
    xor $3e
    ld c, c
    ld d, h
    ld a, $56
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld a, $4b
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $4c
    ld d, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $32
    ld b, l
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $4b
    ld c, h
    ld d, c
    ld b, [hl]
    ld b, b
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $2c
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, a
    ld a, $4b
    ld b, [hl]
    ld d, c
    ld c, h
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld a, $49
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld a, [$eff7]
    xor $45
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $35
    ld d, d
    ld c, d
    ld c, h
    ld c, a
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $4c
    ld d, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2a
    ld b, d
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, [hl]
    ld b, c
    ld b, d
    ld a, $5f
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $2b
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
    ld a, [$eff7]
    xor $2c
    ld l, d
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld d, h
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $2b
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
    ld h, e
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    dec hl
    ld d, d
    ld b, e
    ld b, e
    ld h, e
    rst $28
    xor $3a
    ld b, l
    ld a, $51
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, e
    ld h, d
    dec hl
    ld b, d
    ld a, [$eff7]
    xor $41
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    or $5e
    rst $28
    xor $4d
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, d
    ld a, $49
    ld d, h
    ld a, $56
    ld d, b
    ld a, [$eff7]
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $51
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, h
    ld c, h
    rst $28
    xor $3f
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld a, $4b
    ld h, d
    ld c, d
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld [hl], $42
    ld b, d
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld a, $4b
    ld h, d
    ld a, $40
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, d
    ld b, d
    ld b, d
    ld d, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld b, e
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld c, h
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld a, $56
    rst $28
    xor $4b
    ld c, h
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, b
    ld d, [hl]
    ld h, e
    ld h, d
    dec h
    ld d, d
    ld d, b
    ld d, [hl]
    ld h, e
    rst $28
    xor $25
    ld d, d
    ld d, b
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    jr nc, jr_021_4e8c

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $63
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld b, l
    ld a, $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, [hl]
    ld d, d
    ld a, $48
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld d, c
    ld a, $4f
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l

jr_021_4e8c:
    ld h, d
    ld a, $50
    ld d, b
    ld d, d
    ld c, d
    ld b, d
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $42
    ld c, e
    ld b, b
    ld c, h
    ld d, d
    ld c, a
    ld a, $44
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $51
    ld c, h
    ld c, h
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    jr nc, jr_021_4f08

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $f6
    ld h, e
    ld h, d
    ld a, [hl+]
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld h, $45
    ld a, $4a
    ccf
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $37
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l

jr_021_4f08:
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $49
    ld c, h
    ld b, b
    ld a, $51
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld b, d
    ld a, $4f
    ld d, b
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $5f
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, d
    ld a, $50
    ld b, d
    rst $28
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    dec [hl]
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4c
    ld d, h
    ld c, e
    ld h, d
    ld b, d
    ld d, [hl]
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    daa
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
    ld c, d
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $49
    ld b, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    dec h
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    rst $28
    xor $3f
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    dec [hl]
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    add hl, hl
    ld a, $4f
    ld h, d
    ccf
    ld b, d
    ld d, [hl]
    ld c, h
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld e, [hl]
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
    ld c, h
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $51
    ld c, a
    ld d, d
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld e, [hl]
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, e
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    ld c, [hl]
    ld d, d
    ld c, h
    ld d, c
    ld b, d
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $47
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $47
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld a, $ef
    xor $49
    ld b, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld a, $4f
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, [hl]
    ld h, d
    jr nc, jr_021_518b

    ld c, a
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl], $4c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $4a
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld l, d

jr_021_518b:
    ld h, d
    ld a, $4a
    ld a, $57
    ld b, d
    ld b, c
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld b, l
    ld a, $4f
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld d, d
    ld c, e
    ld d, [hl]
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld h, d
    scf
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $50
    ld d, c
    ld a, $4f
    ld d, c
    ld h, d
    ld d, b
    ld c, h
    ld c, h
    ld c, e
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld h, e
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $4a
    ld a, $57
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec l
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld b, c
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec l
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    scf
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld d, b
    ld b, [hl]
    ld b, h
    ld c, e
    ld b, [hl]
    ld b, e
    ld b, [hl]
    ld b, b
    ld a, $4b
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, e
    ld a, $4b
    ld d, c
    ld a, $50
    ld d, c
    ld b, [hl]
    ld b, b
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_021_534a

    ld c, e
    ld d, [hl]
    ld h, d
    ld c, l
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $45
    ld b, d
    ld a, $41
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d

FuncAnim21_5344:
    ld b, l
    ld c, h
    ld d, h
    rst $28
    xor $4a

jr_021_534a:
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, l
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, e
    ld b, d
    ld b, d
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld b, [hl]
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ccf
    ld d, d
    ld d, c
    ld h, d
    or $68
    rst $28
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $42
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld a, $57
    ld a, $3e
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $30
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec [hl]
    ld b, d
    ld c, l
    ld h, h
    ld h, d
    inc h
    ld h, d
    ld c, b
    ld b, [hl]
    ld b, c
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    ld h, d
    cpl
    ld b, [hl]
    ld a, $4f
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld c, c
    ld c, c
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld h, e
    ld h, d
    ld a, [hl-]
    ld a, $48
    ld b, d
    ld d, [hl]
    ld e, [hl]
    rst $28
    xor $54
    ld a, $48
    ld b, d
    ld b, d
    ld b, d
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $36
    ld d, c
    ld c, h
    ld c, l
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_021_54d8

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $63
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $25
    ld a, $57
    ld a, $3e
    ld c, a
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld d, b
    ld h, d

jr_021_54d8:
    ld a, $49
    ld c, d
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld a, $4a
    ld h, d
    ld d, b
    ld c, h
    ld c, h
    ld c, h
    ld h, d
    ld b, d
    ld d, l
    ld b, b
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld c, a
    ld b, b
    ld b, l
    ld a, $4b
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $4b
    ld a, [$eff7]
    xor $3e
    ld d, c
    ld d, c
    ld b, [hl]
    ld d, c
    ld d, d
    ld b, c
    ld b, d
    ld h, d
    ld b, l
    ld a, $50
    rst $28
    xor $51
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld a, $62
    ld c, e
    ld b, d
    ld d, h
    ld a, [$eff7]
    xor $49
    ld b, d
    ld a, $43
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    add hl, hl
    ld c, h
    ld c, a
    ld h, d
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    cpl
    ld a, $62
    ld c, c
    ld a, $62
    ld c, c
    ld a, $62
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    rst $28
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    or $68
    ld a, [$eff7]
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr z, jr_021_5611

    ld b, d
    ld c, a
    ld d, [hl]
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4d
    ld a, $4f
    ld d, c
    ld d, [hl]
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld a, [$eff7]
    xor $46
    ld d, c
    ld l, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    rst $28
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_021_565d

    ld e, a
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2b
    ld d, d
    ld c, a

jr_021_5611:
    ld c, a
    ld a, $56
    ld h, e
    ld h, d
    dec hl
    ld d, d
    ld c, a
    ld c, a
    ld a, $56
    rst $28
    xor $f6
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    jr z, jr_021_5669

    ld c, b
    ld h, d
    ld b, d
    ld b, d
    ld c, b
    ld h, d
    ld b, d
    ld b, d
    ld c, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_021_5681

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $ef
    xor $3f
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, e
    rst $30
    ldh a, [$ea]

jr_021_565d:
    sbc a
    and e
    add hl, hl
    ld b, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld d, e
    ld a, $49
    ld d, b
    ld h, d

jr_021_5669:
    ld a, $4f
    ld b, d
    rst $28
    xor $43
    ld d, d
    ld c, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c

jr_021_5681:
    ld b, d
    ld a, $4f
    ld c, e
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld a, [$eff7]
    xor $50
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, h
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    rst $28
    xor $3e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ccf
    ld c, a
    ld a, $4f
    ld d, [hl]
    ld e, a
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld e, a
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    ld b, h
    ld c, c
    ld c, h
    ld c, h
    ld c, d
    ld d, [hl]
    rst $28
    xor $43
    ld a, $40
    ld b, d
    ld e, a
    ld h, d
    ld a, [hl-]
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld c, d
    ld b, [hl]
    ld c, c
    ld b, d
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld c, b
    ld a, $56
    ld e, a
    rst $28
    xor $2a
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, [hl]
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    rst $28
    xor $5f
    ld e, a
    ld e, a
    ld h, d
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, [hl]
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $9f
    and e
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, [hl]
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    rst $28
    xor $51
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, [hl]
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld sp, $544c
    ld e, [hl]
    ld h, d
    ld a, $62
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld a, $62
    ld d, b
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld b, a
    ld c, h
    ld d, [hl]
    ld h, e
    rst $28
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld c, a
    ld b, b
    ld b, l
    ld a, $4b
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld a, [$eff7]
    xor $51
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld a, $62
    ld c, e
    ld b, d
    ld d, h
    rst $28
    xor $49
    ld b, d
    ld a, $43
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld d, d
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld b, d
    ld c, c
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, h
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld a, $49
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld a, $62
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld l, d
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, d
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $49
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, l
    ld b, [hl]
    ld b, b
    ld c, b
    ld d, [hl]
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, b
    ld d, d
    ld d, b
    ld d, c
    ld c, h
    ld c, d
    ld b, d
    ld c, a
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, e
    ld h, d
    inc l
    ld l, h
    ld b, d
    rst $28
    xor $40
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, e
    ld h, d
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld a, $56
    rst $28
    xor $2c
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld h, $4c
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld b, l
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld a, $46
    ld b, c
    ld h, d
    ld c, e
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $37
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    cpl
    ld b, d
    ld c, d
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3e
    ld h, d
    ld d, b
    ld b, b
    ld a, $4f
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld l, b
    ld h, d
    ld a, $62
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld b, [hl]
    ld b, h
    ld c, e
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, d
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $41
    ld d, b
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld a, $4b
    ld h, d
    ld [hl-], a
    ld c, a
    ld c, h
    ld b, b
    ld b, l
    ld b, [hl]
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld b, l
    ld a, $46
    ld c, a
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $30
    ld b, d
    ld b, c
    ld d, d
    ld d, b
    ld a, $28
    ld d, [hl]
    ld b, d
    ld l, b
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld d, d
    ld d, c
    ld b, l
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $26
    ld c, h
    ld b, [hl]
    ld c, c
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld l, b
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld b, l
    ld h, e
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    rst $28
    xor $4f
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, a
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $3a
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $50
    ld a, $56
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld a, [$eff7]
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $54
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld a, $4b
    ld c, e
    ld a, $62
    ccf
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $3e
    ld d, c
    ld h, h
    rst $28
    xor $01
    nop
    nop
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld d, b
    ld a, $4b
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $44
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    or $64
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld a, $4b
    ld b, d
    ld h, e
    ld h, h
    rst $28
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ccf
    ld b, [hl]
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld e, a
    ld e, a
    ld h, e
    ld h, d
    ld a, [hl-]
    ld a, $46
    ld d, c
    ld h, d
    ld a, $ef
    xor $4a
    ld b, [hl]
    ld c, e
    ld d, d
    ld d, c
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $24
    ld c, a
    ld b, d
    ld c, e
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $f6
    ld h, e
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc sp
    ld a, $4f
    ld d, c
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld c, l
    ld a, $4b
    ld d, c
    ld d, b
    rst $28
    xor $40
    ld a, $4b
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld e, a
    ld h, d
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ccf
    ld c, c
    ld d, d
    ld b, e
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    jr nc, @+$58

    ld h, d
    ld b, h
    ld c, h
    ld b, c
    ld e, [hl]
    ld h, d
    ld d, d
    ld c, l
    rst $28
    xor $40
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    or $63
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc sp
    ld a, $4f
    ld d, c
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld c, l
    ld a, $4b
    ld d, c
    ld d, b
    rst $28
    xor $40
    ld a, $4b
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr z, jr_021_5cdd

    ld b, b
    ld d, d
    ld d, d
    ld d, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
    xor $27
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ccf
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld a, [hl-]
    ld a, [hl-]
    dec [hl]
    dec [hl]
    dec [hl]
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld l, b
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    ld h, e
    ld h, d
    ld [hl-], a
    ld b, e
    ld a, [$eff7]
    xor $40

jr_021_5cdd:
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $50
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld [hl], $62
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $24
    ld c, c
    ld c, c
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $2d
    ld c, h
    ld d, [hl]
    ld h, d
    or [hl]
    ld h, d
    ld a, [hl-]
    ld b, [hl]
    ld d, b
    ld b, c
    ld c, h
    ld c, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $42
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $36
    ld d, c
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ld h, d
    or [hl]
    ld h, d
    inc h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec [hl]
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $33
    ld b, d
    ld a, $40
    ld b, d
    ld h, d
    or [hl]
    ld h, d
    dec h
    ld c, a
    ld a, $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld e, a
    rst $28
    xor $37
    ld b, l
    ld b, d
    ld h, d
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3f
    ld b, d
    ld c, c
    ld c, h
    ld d, h
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld d, d
    ld c, e
    ld b, e
    ld c, h
    ld c, a
    ld d, c
    ld d, d
    ld c, e
    ld a, $51
    ld b, d
    rst $28
    xor $3f
    ld d, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, h
    ld b, d
    ld a, $48
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    dec [hl]
    ld a, $46
    ld d, b
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4c
    ld d, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    add hl, sp
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    ld c, a
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $37
    ld a, $49
    ld b, [hl]
    ld d, b
    ld c, d
    ld a, $4b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec [hl]
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    jr nc, jr_021_5f1d

    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $b6
    ld h, d
    dec h
    ld b, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    jr nc, jr_021_5f42

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $f6
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld d, c
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d

jr_021_5f1d:
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_021_5f6a

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, e
    ld h, e

jr_021_5f42:
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    cpl
    ld a, $3f
    ld d, [hl]
    ld c, a
    ld b, [hl]
    ld c, e
    ld d, c

jr_021_5f6a:
    ld b, l
    ld a, [$eff7]
    xor $b6
    ld h, d
    dec l
    ld d, d
    ld b, c
    ld b, h
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    ld h, d
    ld h, $42
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec [hl]
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    dec hl
    ld a, $4d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld a, [$eff7]
    xor $b6
    ld h, d
    scf
    ld b, d
    ld c, d
    ld c, l
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $63
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    cpl
    ld a, $3f
    ld d, [hl]
    ld c, a
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $b6
    ld h, d
    dec l
    ld d, d
    ld b, c
    ld b, h
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    rst $28
    xor $26
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    dec [hl]
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec [hl]
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    dec hl
    ld a, $4d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld a, [$eff7]
    xor $b6
    ld h, d
    scf
    ld b, d
    ld c, d
    ld c, l
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld c, l
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    rst $28
    xor $50
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    dec [hl]
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld sp, $624c
    ld c, d
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    or $62
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    or $62
    ld b, [hl]
    ld d, b
    rst $28
    xor $f6
    ld h, e
    rst $30
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    ld a, [hl-]
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld a, $62
    ld b, e
    ld a, $53
    ld c, h
    ld c, a
    ld h, h
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $62
    ld b, h
    ld c, h
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    or $5f
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    scf
    ld a, $48
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, e
    ld h, d
    inc sp
    ld c, c
    ld b, d
    ld b, d
    ld b, d
    ld a, $50
    ld b, d
    ld h, e
    rst $38
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld b, h
    ld d, d
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $52
    ld d, b
    ld b, d
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $4b
    ld c, h
    ld d, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, c
    ld e, [hl]
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $48
    ld c, e
    ld c, h
    ld d, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    or $5e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, d
    ld c, d
    ld a, $4b
    ld d, [hl]
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    scf
    ld a, $49
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $3e
    ld b, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, c
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    scf
    ld b, l
    ld a, $4b
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $f6
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $54
    ld a, $46
    ld d, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, e
    ld h, e
    rst $30
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    or $63
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $51
    ld a, $48
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    rst $28
    xor $2c
    ld l, d
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld h, e
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, h
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
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
    xor $48
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $43
    ld a, $4f
    ld c, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    inc h
    ld d, b
    ld h, d
    ld c, d
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $42
    ld d, l
    ld c, l
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    or $63
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld b, e
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, c
    ld c, a
    ld c, h
    ld c, l
    rst $28
    xor $4c
    ld b, e
    ld b, e
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld bc, $fa09
    rst $30
    rst $28
    xor $4a
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
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, [hl]
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $44
    ld b, d
    ld d, c
    ld h, d
    ld a, $62
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ccf
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld b, d
    ld d, l
    ld c, l
    ld b, d
    ld c, a
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    rst $28
    xor $42
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    ld a, [$eff7]
    xor $51
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
    ld d, b
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $4c
    ccf
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec [hl]
    ld b, d
    ld c, d
    ld b, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld e, [hl]
    rst $28
    xor $50
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld a, [$eff7]
    xor $9f
    and e
    ld e, a
    ld e, a
    ld e, a
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld a, $4b
    ld d, [hl]
    rst $28
    xor $42
    ld d, l
    ld c, l
    ld b, d
    ld c, a
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    daa
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
    xor $48
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $43
    ld a, $4f
    ld c, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    rst $28
    xor $25
    ld b, [hl]
    ld c, a
    ld b, c
    dec h
    ld c, c
    ld c, h
    ld d, h
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld h, $4c
    ld c, l
    ld d, [hl]
    ld b, b
    ld c, h
    ld c, l
    ld d, [hl]
    ld e, a
    ld h, d
    inc l
    rst $28
    xor $54
    ld a, $4b
    ld c, e
    ld a, $62
    ld b, b
    ld c, h
    ld c, l
    ld d, [hl]
    ld b, b
    ld c, h
    ld c, l
    ld d, [hl]
    ld a, [$eff7]
    xor $25
    ld a, $49
    ld d, a
    ld a, $48
    ld h, d
    ld d, c
    ld c, h
    ld b, c
    ld a, $56
    ld e, a
    rst $28
    xor $26
    ld c, h
    ld c, l
    ld d, [hl]
    ld b, b
    ld c, h
    ld c, l
    ld d, [hl]
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr z, jr_021_65c7

    ld c, l
    ld c, c
    ld c, h
    ld b, c
    ld b, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $3d
    ld a, $4d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, d
    ld c, c
    ld c, c
    ld c, h
    ld h, e
    rst $28
    xor $2c
    ld l, d
    ld h, d
    dec hl
    ld b, d
    ld c, c
    ld c, h
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_021_65fc

    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $54
    ld a, $4b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld c, h

jr_021_65c7:
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, b
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld b, l
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld a, $49
    ld c, c
    ld d, [hl]
    rst $28
    xor $42
    ld d, l
    ld d, c
    ld b, d
    ld c, e
    ld b, c
    ld b, d
    ld b, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld d, b

jr_021_65fc:
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $44
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
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
    ld d, b
    rst $28
    xor $49
    ld c, h
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld c, h
    ld h, d
    ld a, $40
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld b, [hl]
    ld d, b
    ld b, l
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld e, [hl]
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld c, b
    ld a, [$eff7]
    xor $54
    ld b, d
    ld a, $48
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
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $45
    ld b, [hl]
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4c
    ld c, d
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    rst $28
    xor $4c
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2b
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    ld h, d
    ld c, d
    ld a, $4b
    ld d, [hl]
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld e, a
    ld e, a
    dec hl
    ld e, a
    ld e, a
    dec hl
    ld b, d
    ld c, c
    ld c, c
    ld c, h
    ld h, e
    rst $28
    xor $30
    ld e, a
    ld e, a
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $37
    ld e, a
    ld e, a
    scf
    ld e, a
    ld e, a
    scf
    ld b, d
    ld d, c
    ld c, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    daa
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
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
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    daa
    ld c, h
    ld h, d
    ld d, [hl]
    ld a, $62
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $2a
    ld b, [hl]
    ld b, h
    ld a, $36
    ld c, c
    ld a, $50
    ld b, l
    ld h, h
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    ld e, a
    rst $28
    xor $28
    jr z, jr_021_6767

    jr z, @+$4a

    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $62
    ld b, [hl]
    ld d, b
    rst $28
    xor $40
    ld d, d
    ld c, a
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld c, c
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]

jr_021_6767:
    xor $4d
    ld c, a
    ld b, d
    ld c, l
    ld a, $4f
    ld b, d
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr c, jr_021_67c6

    ld d, c
    ld b, [hl]
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $4f
    ld b, d
    ld a, $41
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld d, c
    ld c, a
    ld a, $46
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $30
    ld a, $47
    ld b, d
    ld d, b
    ld d, c

jr_021_67c6:
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $25
    ld b, d
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $35
    ld b, d
    ld b, e
    ld b, d
    ld c, c
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $25
    ld b, d
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld h, d
    or $5e
    rst $28
    xor $26
    ld c, h
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, h
    ld b, l
    ld a, $51
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, c
    ld c, h
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
    ld h, d
    inc a
    ld b, d
    ld d, c
    ld b, [hl]
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    rst $28
    xor $37
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $3a
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld c, l
    ld c, a
    ld a, $56
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $f6
    ld l, b
    ld h, d
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld e, [hl]
    ld h, d
    ld c, h
    ccf
    ld b, d
    ld d, [hl]
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    rst $28
    xor $3e
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3a
    ld b, [hl]
    ld c, c
    ld b, c
    inc h
    ld c, l
    ld b, d
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $25
    ld b, d
    ld a, $50
    ld d, c
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld b, [hl]
    ld b, h
    ld a, $4b
    ld d, c
    ld b, d
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $44
    ld b, [hl]
    ld b, h
    ld a, $4b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld d, c
    ld b, d
    ld d, b
    ld d, c
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld d, d
    ld d, [hl]
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $42
    ld c, e
    ld d, c
    ld c, a
    ld a, $4b
    ld b, b
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld d, b
    ld d, c
    ld a, $52
    ld c, a
    ld a, $4b
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $4f
    ld b, [hl]
    ld d, e
    ld a, $49
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, h
    ld h, d
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $4f
    ld a, $46
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, e
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_021_6b46

    ld h, d
    ld c, a
    ld b, [hl]
    ld d, e
    ld a, $49
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $54
    ld a, $51
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld d, d
    ld c, a
    ld b, d
    rst $28
    xor $4c
    ld d, d
    ld d, c
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    inc l
    ld l, d
    ld a, [$eff7]
    xor $4f
    ld a, $46
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28

jr_021_6b46:
    xor $9f
    and e
    jr z, @+$55

    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld a, $62
    ld c, d
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld b, d
    ld a, $51
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    ld b, l
    ld a, $62
    ld b, l
    ld a, $5f
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, h
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    rst $28
    xor $51
    ld c, a
    ld a, $46
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $25
    ld c, h
    ld c, d
    ccf
    ld h, $4f
    ld a, $44
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld d, d
    ld c, e
    rst $28
    xor $3e
    ld d, h
    ld a, $56
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld l, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld c, a
    ld c, h
    ld d, d
    ccf
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $35
    ld b, d
    ld b, b
    ld b, d
    ld c, e
    ld d, c
    ld c, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld b, l
    ld b, d
    ld l, b
    ld a, [$eff7]
    xor $49
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld c, h
    ld d, c
    ld b, [hl]
    ld d, e
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld b, h
    ld d, d
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld l, b
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld b, d
    ld l, b
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    rst $28
    xor $41
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld c, a
    ld d, d
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $3e
    ld d, h
    ld a, $56
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $40
    ld d, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld a, $54
    ld a, $56
    rst $28
    xor $36
    ld b, b
    ld d, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld a, $54
    ld a, $56
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld b, d
    ld a, $50
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4f
    ld d, d
    ld c, e
    ld h, e
    ld h, d
    dec hl
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, d
    ld h, e
    ld h, d
    inc a
    ld c, h
    rst $28
    xor $41
    ld d, d
    ld b, c
    ld b, d
    ld e, a
    ld h, d
    ld a, [hl-]
    ld a, $4b
    ld c, e
    ld a, $62
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    rst $28
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, d
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld d, d
    ld c, e
    ld c, e
    ld c, h
    rst $28
    xor $42
    ld b, [hl]
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $26
    ld l, d
    ld c, h
    ld c, e
    ld h, d
    dec h
    ld b, d
    ccf
    ld b, d
    ld e, [hl]
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld b, d
    ld a, $51
    ld a, [$eff7]
    xor $3e
    ld b, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    jr nc, jr_021_6d99

    ld h, d
    ld c, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld b, h
    ld a, $51
    ld b, l
    ld b, d
    ld c, a
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f

jr_021_6d99:
    and e
    inc h
    ld d, c
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld e, a
    ld a, [$eff7]
    xor $26
    ld c, h
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld l, h
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    rst $28
    xor $3f
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld b, d
    ld b, [hl]
    ld b, h
    ld c, e
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld l, l
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $50
    ld d, c
    ld a, $56
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld b, d
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    inc l
    rst $28
    xor $41
    ld c, h
    ld h, h
    ld h, d
    scf
    ld b, l
    ld a, $51
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld a, [$eff7]
    xor $4b
    ld b, [hl]
    ld b, b
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    rst $28
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
    ld h, d
    inc l
    rst $28
    xor $4a
    ld a, $41
    ld b, d
    ld h, d
    ld a, [hl+]
    ld b, [hl]
    ld b, h
    ld a, $4b
    ld d, c
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld h, d
    ld d, d
    ld c, e
    ld b, b
    ld b, d
    ld c, a
    ld d, c
    ld a, $46
    ld c, e
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, e
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3f
    ld d, d
    ld c, a
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld b, [hl]
    ld d, a
    ld d, a
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $ef
    xor $3a
    ld b, [hl]
    ld c, c
    ld b, c
    inc h
    ld c, l
    ld b, d
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld c, b
    ld b, d
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld d, b
    ld c, h
    ld c, h
    ld c, h
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    ld h, d
    add hl, hl
    ld c, h
    ld c, a
    rst $28
    xor $3f
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $2c
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $ef
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld a, $62
    ld c, a
    ld d, d
    ld c, d
    ld c, h
    ld c, a
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $54
    ld b, e
    ld d, d
    ld c, c
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld b, d
    ld b, d
    rst $28
    xor $42
    ld d, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $45
    ld a, $46
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, e
    ld a, $40
    ld b, d
    ld h, e
    ld h, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $40
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld h, e
    ld a, [$eff7]
    xor $2a
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    rst $28
    xor $44
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld b, d
    ld d, c
    ld e, a
    ld e, a
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $56
    ld b, d
    ld d, c
    ld h, e
    ld h, d
    dec hl
    ld b, [hl]
    ld b, b
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    or $5f
    rst $28
    xor $2f
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, l
    ld d, d
    ld d, c
    ld h, d
    ld a, $ef
    xor $4a
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
    ld a, [$eff7]
    xor $41
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $3e
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld b, [hl]
    ld b, h
    ld h, d
    ld b, l
    ld a, $4a
    ld c, d
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    or $63
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $3e
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $4c
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    ld h, e
    rst $28
    xor $2c
    ld l, d
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld d, h
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $ef
    xor $24
    scf
    ld l, $50
    ld b, d
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $38
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, d
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ccf
    ld b, d
    ld d, [hl]
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $2b
    ld c, h
    ld c, a
    ld c, e
    dec h
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $25
    ld d, d
    ld b, h
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld c, h
    ld c, a
    ld c, e
    dec h
    ld b, d
    ld b, d
    ld d, c
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld b, d
    ld b, d
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $45
    ld c, h
    ld c, a
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $4a
    ld a, $57
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $54
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $62
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, [hl]
    ld h, d
    ld a, $ef
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld c, e
    ld h, a
    rst $28
    xor $47
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld a, $62
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld a, $46
    ld d, b
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
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
    ld a, [$eff7]
    xor $51
    ld c, h
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl], $3e
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    rst $28
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $46
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, a
    ld a, $44
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    add hl, hl
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $46
    ld c, e
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $49
    ld c, h
    ld d, d
    ld b, c
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $3e
    ld h, d
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
    ld a, $fa
    rst $30
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $ef
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    daa
    ld c, a
    ld a, $5f
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    jr nc, jr_021_743b

    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3f
    ld c, h
    ld c, a
    ld c, e
    ld h, e
    ld a, [$eff7]
    xor $24
    ld c, d
    ld a, $57
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld d, d
    ld b, l
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld a, [$eff7]
    xor $40

jr_021_743b:
    ld c, c
    ld b, d
    ld a, $4f
    ld c, c
    ld d, [hl]
    ld h, h
    ld h, d
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $49
    ld c, h
    ld d, d
    ld b, c
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $3e
    ld h, d
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
    ld a, $fa
    rst $30
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $ef
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    daa
    ld c, a
    ld a, $5f
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    jr nc, @+$44

    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $40
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $24
    ld c, d
    ld a, $57
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld d, d
    ld b, l
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld a, [$eff7]
    xor $40
    ld c, c
    ld b, d
    ld a, $4f
    ld c, c
    ld d, [hl]
    ld h, h
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    rst $28
    xor $50
    ld a, $56
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, c
    ld c, h
    ld d, d
    ld b, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $33
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    cpl
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld e, a
    ld e, a
    ld e, a
    ld c, e
    ld c, h
    rst $28
    xor $2c
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    ld e, a
    ld h, d
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $50
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld c, h
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld b, b
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld e, [hl]
    rst $28
    xor $4b
    ld c, h
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $50
    ld a, [$eff7]
    xor $50
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld a, $49
    ld c, d
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld a, [$eff7]
    xor $46
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    rst $28
    xor $54
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, c
    ld b, d
    ld d, e
    ld a, $50
    ld d, c
    ld a, $51
    ld b, d
    ld b, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld d, h
    ld c, h
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld c, e
    ld a, $62
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $44
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    rst $28
    xor $3f
    ld d, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld d, c
    ld b, d
    ld c, a
    ld c, a
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld e, a
    ld e, a
    ld e, a
    inc l
    ld h, d
    ld a, $44
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld e, a
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld d, b
    ld c, h
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $48
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld c, h
    ld h, h
    ld h, d
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $44
    ld d, d
    ld a, $4f
    ld b, c
    ld b, [hl]
    ld a, $4b
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $28
    xor $30
    ld d, [hl]
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    dec hl
    ld c, d
    ld c, d
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, d
    ld d, [hl]
    ld b, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld b, e
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    cpl
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    rst $28
    xor $45
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $4c
    ld d, d
    ld d, c
    ld h, e
    ld h, d
    jr nc, jr_021_7893

    ld h, d
    ld d, b
    ld b, d
    ld c, a
    ld d, e
    ld a, $4b
    ld d, c
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    dec hl
    ld b, d
    ld c, a
    ld b, d
    ld e, [hl]
    rst $28
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $45
    ld b, d
    ld a, $4f
    ld d, c
    ld l, b
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    dec hl
    ld c, d
    ld c, d
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld a, $4a
    ld b, d
    ld h, d

jr_021_7893:
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $29
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $50
    ld b, d
    ld c, a
    ld d, e
    ld a, $4b
    ld d, c
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $4c
    ld d, d
    ld d, c
    ld h, e
    ld h, d
    jr nc, jr_021_792b

    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    dec hl
    ld b, d
    ld c, a
    ld b, d
    ld e, [hl]
    rst $28
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $45
    ld b, d
    ld a, $4f
    ld d, c
    ld l, b
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    dec hl
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d

jr_021_792b:
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, d
    ld a, $50
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    add hl, hl
    ld c, h
    ld c, a
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, l
    ld a, $53
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $54
    ld b, d
    ld a, $48
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    rst $28
    xor $4c
    ld c, e
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld a, [$eff7]
    xor $51
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $ef
    xor $50
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld c, d
    ld a, $4b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $54
    ld a, $4b
    ld b, c
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld h, d
    ld a, $4b
    ld b, c
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld a, $51
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    rst $28
    xor $40
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    cpl
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $46
    ld c, e
    ld d, c
    ld c, a
    ld c, h
    ld b, c
    ld d, d
    ld b, b
    ld b, d
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld e, a
    ld h, d
    dec hl
    ld b, d
    ld l, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld b, c
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, b
    ld a, $51
    ld b, d
    ld b, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $50
    ld c, h
    ld d, d
    ld c, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld l, b
    ld h, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $3e
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld e, [hl]
    rst $28
    xor $f6
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, e
    rst $28
    xor $f6
    ld h, e
    ld e, [hl]
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld d, c
    ld l, b
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld [hl], $45
    ld c, h
    ld d, h
    rst $28
    xor $45
    ld b, [hl]
    ld c, d
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    dec hl
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    inc a
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
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    ld h, h
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld a, $62
    ld c, a
    ld b, d
    ld a, $49
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ld b, c
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, b
    ld a, $51
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld c, h
    ld d, d
    ld c, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld e, [hl]
    rst $28
    xor $26
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    ld h, d
    or $63
    rst $30
    ldh a, [$f0]
    ld h, $60
    ldh [$f8], a
    inc h
    ld h, b
    ldh [rP1], a
    ld [hl+], a
    ld h, b
    ldh [$08], a
    jr nz, @+$62

    ldh [rNR10], a
    ld e, $60
    ldh a, [$e8]
    inc e
    ld h, b
    ldh a, [$f0]
    ld a, [de]
    ld h, b
    ldh a, [$f8]
    jr jr_021_7c78

    ldh a, [rP1]
    ld d, $60
    ldh a, [$08]
    inc d
    ld h, b
    ldh a, [rNR10]
    ld [de], a
    ld h, b
    add b
    db $e4
    ld [$005a], sp
    db $e3
    add sp, $4c
    nop
    ldh a, [rP1]
    ld e, b
    nop
    ldh a, [$f8]
    ld d, [hl]
    nop
    ldh a, [$f0]
    ld d, h
    nop
    ldh [rP1], a
    ld d, d
    nop
    ldh [$f8], a
    ld d, b
    nop
    ldh [$f0], a
    ld c, [hl]
    nop
    add b
    db $ed
    ld [$604c], sp
    db $ec
    add sp, $5a
    ld h, b
    ldh [$f0], a
    ld e, b
    ld h, b
    ldh [$f8], a
    ld d, [hl]
    ld h, b
    ldh [rP1], a
    ld d, h
    ld h, b
    ldh a, [$f0]
    ld d, d
    ld h, b
    ldh a, [$f8]
    ld d, b
    ld h, b
    ldh a, [rP1]
    ld c, [hl]
    ld h, b
    add b
    ldh a, [rNR23]
    ld b, b
    nop
    ldh a, [rNR10]
    ld a, $00
    ldh [$08], a
    ld b, b
    nop
    ldh [rP1], a
    ld a, $00
    ret nc

jr_021_7c78:
    ld hl, sp+$40
    nop
    ret nc

    ldh a, [$3e]
    nop
    ret nc

    add sp, $3c
    nop
    ret nc

    ldh [$3a], a
    nop
    add b
    ldh [$e8], a
    ld b, h
    nop
    ldh [$e0], a
    ld b, d
    nop
    ldh a, [$f8]
    ld b, h
    nop
    ldh a, [$f0]
    ld b, d
    nop
    nop
    jr jr_021_7ce3

    nop
    nop
    db $10
    ld b, [hl]
    nop
    nop
    ld [$0044], sp
    nop
    nop
    ld b, d
    nop
    add b
    ldh a, [rNR41]
    ld [hl], d
    nop
    ldh a, [$d8]
    ld h, b
    nop
    ldh a, [rNR23]
    ld [hl], b
    nop
    ldh a, [rNR10]
    ld l, [hl]
    nop
    ldh a, [$08]
    ld l, h
    nop
    ldh a, [rP1]
    ld l, d
    nop
    ldh a, [$f8]
    ld l, b
    nop
    ldh a, [$f0]
    ld h, [hl]
    nop
    ldh a, [$e8]
    ld h, h
    nop
    ldh a, [$e0]
    ld h, d
    nop
    add b
    add hl, bc
    ld b, b
    ld [$da40], sp
    ld a, h
    rst $28
    ld a, h
    ldh a, [$f0]
    ld a, [bc]
    nop
    ldh a, [$e8]
    ld [$f000], sp

jr_021_7ce3:
    ldh [rTMA], a
    nop
    ldh a, [rNR23]
    ld c, $00
    ldh a, [rNR10]
    inc c
    nop
    add b
    ldh a, [rNR23]
    ld [de], a
    nop
    ldh a, [rNR10]
    stop
    ldh a, [$f0]
    inc b
    nop
    ldh a, [$e8]
    ld [bc], a
    nop
    ldh a, [$e0]
    nop
    nop
    add b
    ld bc, $0040
    ld b, b
    ld a, $01
    ldh [rVBK], a
    ld hl, $7a45
    ld bc, $9c00
    ld a, $21
    ld [$c6a1], a
    call BitComplementAndBranch
    xor a
    ldh [rVBK], a
    ld hl, $78f7
    ld bc, $9c00
    call BitComplementAndBranch
    ld hl, $59d6
    ld a, $22
    ld [$c6a1], a
    call WriteRotatedBytesDown
    ld hl, $5a16
    call $2df1
    ret


    ld hl, $4000
    ld bc, $9c00
    ld a, $3f
    ld [$c6a1], a
    call BitComplementAndBranch
    ldh a, [$fe]
    and a
    ret z

    ld a, $01
    ldh [rVBK], a
    ld hl, $4179
    ld bc, $9c00
    call BitComplementAndBranch
    xor a
    ldh [rVBK], a
    ld a, $02
    ld [$c6a1], a
    ld hl, $4000
    call WriteRotatedBytesDown
    ld hl, $4040
    call $2df1
    ret


    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
