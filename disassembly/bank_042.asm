; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $042", ROMX[$4000], BANK[$42]

    db $42 ; Bank number

    ; Cross-bank dispatch table (117 entries)
    ; Called via: ld hl, $42XX / rst $10
    dw LoadB42_40eb                  ; Entry 0
    dw $4108                          ; Entry 1
    dw $4125                          ; Entry 2
    dw $4009                          ; Entry 3
    dw $4142                          ; Entry 4
    dw $4244                          ; Entry 5
    dw $4259                          ; Entry 6
    dw $42D0                          ; Entry 7
    dw $4323                          ; Entry 8
    dw $43B0                          ; Entry 9
    dw $4431                          ; Entry 10
    dw $4473                          ; Entry 11
    dw $44BA                          ; Entry 12
    dw $4590                          ; Entry 13
    dw $45C1                          ; Entry 14
    dw $476A                          ; Entry 15
    dw $47BF                          ; Entry 16
    dw $47FB                          ; Entry 17
    dw $483B                          ; Entry 18
    dw $48B2                          ; Entry 19
    dw $49CF                          ; Entry 20
    dw $4A3E                          ; Entry 21
    dw $4A77                          ; Entry 22
    dw $4AAC                          ; Entry 23
    dw $4AE0                          ; Entry 24
    dw $4B06                          ; Entry 25
    dw $4B9C                          ; Entry 26
    dw $4BD7                          ; Entry 27
    dw $4BF7                          ; Entry 28
    dw $4C22                          ; Entry 29
    dw $4C3F                          ; Entry 30
    dw $4C50                          ; Entry 31
    dw $4C6E                          ; Entry 32
    dw $4C85                          ; Entry 33
    dw $4CEA                          ; Entry 34
    dw $4D08                          ; Entry 35
    dw $4D34                          ; Entry 36
    dw $4D91                          ; Entry 37
    dw $517B                          ; Entry 38
    dw $51DB                          ; Entry 39
    dw $522C                          ; Entry 40
    dw $5285                          ; Entry 41
    dw $53F1                          ; Entry 42
    dw $541E                          ; Entry 43
    dw $5474                          ; Entry 44
    dw $55D7                          ; Entry 45
    dw $5608                          ; Entry 46
    dw $5677                          ; Entry 47
    dw $56FD                          ; Entry 48
    dw $58B2                          ; Entry 49
    dw $58EC                          ; Entry 50
    dw $5A53                          ; Entry 51
    dw $5B00                          ; Entry 52
    dw $5B3C                          ; Entry 53
    dw $5B99                          ; Entry 54
    dw $5C54                          ; Entry 55
    dw $5C7A                          ; Entry 56
    dw $5CC2                          ; Entry 57
    dw $5CE6                          ; Entry 58
    dw $5D55                          ; Entry 59
    dw $5E08                          ; Entry 60
    dw $5E3E                          ; Entry 61
    dw $5ED1                          ; Entry 62
    dw $5EEB                          ; Entry 63
    dw $5F28                          ; Entry 64
    dw $5F5F                          ; Entry 65
    dw $6007                          ; Entry 66
    dw $602C                          ; Entry 67
    dw $6159                          ; Entry 68
    dw $61BD                          ; Entry 69
    dw $6437                          ; Entry 70
    dw $6466                          ; Entry 71
    dw $6492                          ; Entry 72
    dw $64B4                          ; Entry 73
    dw $65B6                          ; Entry 74
    dw $65E5                          ; Entry 75
    dw $6612                          ; Entry 76
    dw $6651                          ; Entry 77
    dw $66CC                          ; Entry 78
    dw $6791                          ; Entry 79
    dw $67D1                          ; Entry 80
    dw $68DF                          ; Entry 81
    dw $6966                          ; Entry 82
    dw $69A4                          ; Entry 83
    dw $6ABA                          ; Entry 84
    dw $6B5B                          ; Entry 85
    dw $6BA3                          ; Entry 86
    dw $6BD9                          ; Entry 87
    dw $6DC6                          ; Entry 88
    dw $6E72                          ; Entry 89
    dw $6F1C                          ; Entry 90
    dw $6F60                          ; Entry 91
    dw $6FFE                          ; Entry 92
    dw $7092                          ; Entry 93
    dw $70BB                          ; Entry 94
    dw $71FE                          ; Entry 95
    dw $7236                          ; Entry 96
    dw $7314                          ; Entry 97
    dw $736B                          ; Entry 98
    dw $73FE                          ; Entry 99
    dw $7430                          ; Entry 100
    dw $749A                          ; Entry 101
    dw $74CA                          ; Entry 102
    dw $7527                          ; Entry 103
    dw $756F                          ; Entry 104
    dw $75F1                          ; Entry 105
    dw $7779                          ; Entry 106
    dw $77B7                          ; Entry 107
    dw $78FC                          ; Entry 108
    dw $7A31                          ; Entry 109
    dw $7A53                          ; Entry 110
    dw $7A6A                          ; Entry 111
    dw $7AAF                          ; Entry 112
    dw $7B2F                          ; Entry 113
    dw $7C00                          ; Entry 114
    dw $7C16                          ; Entry 115
    dw $7CC6                          ; Entry 116

LoadB42_40eb:
    ld a, [$c823]
    cp $71
    jr c, jr_042_4101

    sub $71
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1a00
    rst $10
    ret


jr_042_4101:
    ld de, $4007
    call CallTextEngine
    ret


    ld a, [$c823]
    cp $71
    jr c, jr_042_411e

    sub $71
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1a01
    rst $10
    ret


jr_042_411e:
    ld de, $4007
    call RunTextHandler
    ret


    ld a, [$c823]
    cp $71
    jr c, jr_042_413b

    sub $71
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1a02
    rst $10
    ret


jr_042_413b:
    call LoadB42_40eb
    call RequestScreenUpdate
    ret


    db $eb
    jr nc, jr_042_418b

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    scf
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, e
    rst $28
    xor $3a
    ld a, $46
    ld d, c
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ccf
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    daa
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld h, d

jr_042_418b:
    ld d, h
    ld b, l
    ld a, $51
    ld h, d
    jr nc, jr_042_41de

    ld c, d
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    daa
    ld a, $41
    ld h, d
    ld d, c
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld d, d
    ld d, b
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld [hl], $51
    ld a, $56
    ld h, d
    ld d, d
    ld c, l
    rst $28
    xor $51
    ld c, h
    ld c, h
    ld h, d
    ld c, c
    ld a, $51
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld c, a

jr_042_41de:
    ld b, [hl]
    ld b, d
    ld b, c
    rst $28
    xor $3e
    ld d, h
    ld a, $56
    ld h, d
    ccf
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
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
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
    xor $54
    ld a, $4b
    ld c, e
    ld a, $62
    ld c, d
    ld b, d
    ld b, d
    ld d, c
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, h
    rst $28
    xor $27
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, [hl]
    ld e, [hl]
    ld a, [$eff7]
    xor $44
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    jr nc, @+$48

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld d, a
    ld d, a
    ld d, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld a, $51
    rst $28
    xor $3e
    ld h, d
    ld d, b
    ld d, c
    ld d, d
    ld b, e
    ld b, e
    ld b, d
    ld b, c
    ld h, d
    ld a, $4b
    ld b, [hl]
    ld c, d
    ld a, $49
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $54
    ld c, a
    ld b, [hl]
    ld d, c
    ld d, c
    ld b, d
    ld c, e
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, [hl]
    ld c, e
    ld d, [hl]
    ld h, d
    ld b, b
    ld d, d
    ld d, c
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc sp
    ld c, a
    ld c, h
    ld c, l
    ld b, d
    ld c, a
    ld d, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    rst $30
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
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
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $24
    ld h, d
    ld b, e
    ld c, c
    ld a, $4a
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld a, $4f
    ld c, b
    ld c, c
    ld b, d
    ld d, b
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, e
    ld a, $4b
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, $46
    ld c, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    ld a, [$eff7]
    xor $a3
    inc h
    ld h, d
    add hl, hl
    ld a, $46
    ld c, a
    ld d, [hl]
    ld h, d
    scf
    ld a, $49
    ld b, d
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f3
    and e
    ld [hl-], a
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    ld d, d
    ld c, l
    ld c, h
    ld c, e
    ld h, d
    ld a, $62
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $49
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld d, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $ef
    xor $49
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $53
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    ld a, [$eff7]
    xor $a3
    daa
    ld b, [hl]
    ld a, $4f
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    jr nc, jr_042_4425

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    dec hl
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld a, $49
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    ld h, d
    dec hl
    ld c, h
    ld c, l
    ld b, d
    ld a, [$eff7]
    xor $4b
    ld c, h
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, a
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b

jr_042_4425:
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld e, a
    rst $30
    ldh a, [$e9]
    ld h, b
    scf
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld d, b
    ld e, a
    rst $30
    ldh a, [$e9]
    ld h, b
    scf
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    ld l, b
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    jr nc, jr_042_450d

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld c, d
    ld e, [hl]
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    ld l, b
    ld h, d
    ld a, $62
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e

jr_042_450d:
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $37
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld a, [$eff7]
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
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
    ld h, d
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    rst $28
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    and e
    daa
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld d, d
    ld b, l
    ld h, h
    ld h, d
    rst $28
    xor $3a
    ld b, l
    ld a, $51
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, h
    ld a, [$eff7]
    xor $3a
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    jr nc, jr_042_45fd

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    ld h, h
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld a, $48
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld a, $49
    ld c, b
    ld a, [$eff7]
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $30
    ld b, [hl]
    ld c, c

jr_042_45fd:
    ld a, $56
    ld c, h
    ld d, d
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld a, $48
    ld b, d
    ld c, e
    ld h, d
    ld a, $54
    ld a, $56
    ld h, e
    ld h, h
    rst $28
    xor $32
    ld b, l
    ld h, d
    ld c, e
    ld c, h
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld a, [$eff7]
    xor $49
    ld a, $51
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    ld h, h
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld a, $4a
    ld h, d
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld d, h
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
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $46
    ld d, b
    ld h, h
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    rst $28
    xor $43
    ld c, h
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld h, d
    jr nc, @+$40

    ld d, [hl]
    ccf
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    inc l
    ld h, d
    ld b, l
    ld c, h
    ld c, l
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
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, l
    ld a, $51
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld d, c
    ld a, $49
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld b, e
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld c, h
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    ld a, [$eff7]
    xor $a3
    jr z, jr_042_47da

    ld b, b
    ld d, [hl]
    ld b, b
    ld c, c
    ld c, h
    ld c, l
    ld b, d
    ld b, c
    ld b, [hl]
    ld a, $ef
    xor $4c
    ld b, e
    ld h, d
    jr nc, jr_042_47ec

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld a, [$eff7]
    xor $24
    ld d, d
    ld d, c
    ld b, l
    ld c, h
    ld c, a
    ld e, a
    ld e, a
    jr c, jr_042_47ff

    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld b, l

jr_042_47da:
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    ld a, [$eff7]
    xor $37
    ld c, h
    ld c, h
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, [hl]
    ld b, b

jr_042_47ec:
    ld d, d
    ld c, c
    ld d, c
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld h, e
    rst $30
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a

jr_042_47ff:
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $43
    ld c, a
    ld c, h
    ld c, e
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld d, b
    rst $28
    xor $4a
    ld b, [hl]
    ld b, c
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld a, $51
    rst $28
    xor $3e
    ld h, d
    ld d, b
    ld d, c
    ld d, d
    ld b, e
    ld b, e
    ld b, d
    ld b, c
    ld h, d
    ld a, $4b
    ld b, [hl]
    ld c, d
    ld a, $49
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $54
    ld c, a
    ld b, [hl]
    ld d, c
    ld d, c
    ld b, d
    ld c, e
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, [hl]
    ld c, e
    ld d, [hl]
    ld h, d
    ld b, b
    ld d, d
    ld d, c
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc sp
    ld c, a
    ld c, h
    ld c, l
    ld b, d
    ld c, a
    ld d, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ccf
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
    ld e, a
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld b, l
    ld a, $41
    rst $28
    xor $3e
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld c, l
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
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
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $48
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, [$eff7]
    xor $3e
    ld c, a
    ld b, d
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
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
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    rst $28
    xor $3f
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    cpl
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $3a
    ld b, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, l
    ld a, $56
    rst $28
    xor $4c
    ld d, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
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
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, c
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
    ld a, [hl-]
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld c, h
    ld d, c
    ld d, c
    ld c, h
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, l
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
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld b, d
    ld d, h
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, c
    ld b, d
    ld b, d
    ld b, c
    ld e, [hl]
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $51
    ld a, $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ld a, $51
    rst $28
    xor $51
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
    ld a, [$eff7]
    xor $37
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
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $544c
    ld h, d
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $44
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $24
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, [hl]
    ld d, b
    ld h, d
    jr nc, jr_042_4b90

    ld b, a
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $50
    rst $28
    xor $3e
    ld h, d
    ld b, e
    ld a, $53
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $50
    ld c, b
    ld h, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $45
    ld b, [hl]

jr_042_4b90:
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld d, b
    ld h, d
    jr nc, jr_042_4be3

    ld b, a
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $46
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
    ld a, [$eff7]
    xor $33
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld d, e
    ld b, [hl]
    ld b, c
    ld b, d
    rst $28
    xor $52
    ld d, b
    ld h, d
    ld a, $46
    ld b, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]

jr_042_4be3:
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld e, a
    rst $30
    ldh a, [$ea]
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
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
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld d, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, e
    ld h, d
    ld a, [hl+]
    ld c, h
    rst $28
    xor $50
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld a, $ef
    xor $51
    ld c, a
    ld b, d
    ld a, $50
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    ld a, [$f0f7]
    or $62
    ld c, l
    ld b, [hl]
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld d, d
    ld c, l
    rst $28
    xor $3e
    ld c, e
    ld h, d
    dec hl
    ld b, d
    ld c, a
    ccf
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld b, e
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    rst $28
    xor $3e
    ld c, e
    ld h, d
    dec hl
    ld b, d
    ld c, a
    ccf
    ld e, a
    ld a, [$eff7]
    xor $25
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
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $f6
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec hl
    ld b, d
    ld c, a
    ccf
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, a
    ld b, d
    ld a, $50
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld a, $ef
    xor $51
    ld c, a
    ld b, d
    ld a, $50
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
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
    inc l
    ld h, d
    ld a, $4a
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $48
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
    and e
    inc l
    ld b, c
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld b, e
    ld d, [hl]
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld e, [hl]
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
    ld h, d
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    or $63
    rst $28
    xor $3a
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
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
    jr nc, jr_042_4e21

    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    add hl, hl
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4d
    ld a, $4f
    ld d, c
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld c, l
    ld a, $51
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
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
    rst $28
    xor $4c
    ld b, e

jr_042_4e21:
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
    ld a, $51
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld a, $56
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $4f
    ld a, $51
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $48
    ld b, [hl]
    ld b, c
    ld c, e
    ld a, $4d
    ld c, l
    ld b, d
    ld b, c
    ld h, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    daa
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld c, a
    ld b, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    dec hl
    ld c, d
    rst $28
    xor $5f
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    dec hl
    ld c, d
    ld c, d
    ld c, d
    ld c, d
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    ld h, d
    dec hl
    ld c, h
    ld d, h
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld e, [hl]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $4b
    ld a, [$eff7]
    xor $42
    ld a, $50
    ld b, [hl]
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld a, $56
    ld h, d
    ld d, c
    ld b, l
    ld a, $4b
    rst $28
    xor $50
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $45
    ld b, d
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
    and e
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
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
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    cpl
    ld b, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
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
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $51
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
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld a, $4b
    ld d, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
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
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $43
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld a, $4b
    ld d, c
    ld b, d
    ld b, c
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
    scf
    ld b, l
    ld a, $51
    ld h, d
    ld d, h
    ld a, $56
    ld h, d
    ld d, h
    ld b, d
    rst $28
    xor $3f
    ld c, h
    ld d, c
    ld b, l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    jr nc, @+$44

    ld a, $4b
    ld d, h
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, d
    ld e, [hl]
    rst $28
    xor $50
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $50
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $4d
    ld c, a
    ld b, d
    ld c, l
    ld a, $4f
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
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
    and e
    dec hl
    ld b, d
    ld c, a
    ld b, d
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld d, b
    ld b, l
    ld a, $49
    ld c, c
    rst $28
    xor $44
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
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
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld a, [hl-]
    ld b, [hl]
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld a, $4b
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
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $40
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, b
    ld b, d
    ld c, a
    ld d, e
    ld b, d
    rst $28
    xor $3e
    ld d, b
    ld h, d
    ld a, $62
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
    and e
    scf
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
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $52
    ld c, l
    ld c, l
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
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
    ld a, [hl+]
    ld c, h
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $50
    ld c, b
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
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
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr z, jr_042_51d3

    ld b, d
    ld c, a
    ld d, [hl]
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld b, l
    ld a, $4a
    ld c, l
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $36
    ld d, c
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

jr_042_51d3:
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld a, $ef
    xor $43
    ld b, d
    ld b, d
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
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
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $50
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
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
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld c, h
    ld c, h
    ld c, b
    ld h, h
    rst $38
    ldh a, [$a3]
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld h, d
    ccf
    ld d, d
    ld b, [hl]
    ld c, c
    ld d, c
    ld a, [$eff7]
    xor $46
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld a, $62
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    ld [hl-], a
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld a, $49
    ld d, b
    ld c, h
    ld h, d
    ccf
    ld d, d
    ld b, [hl]
    ld c, c
    ld d, c
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld d, b
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $40
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    dec h
    ld b, d
    ld d, [hl]
    ld c, h
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
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
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
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld a, [hl-]
    ld b, l
    ld b, d
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
    rst $28
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
    ld a, [$eff7]
    xor $4b
    ld b, d
    ld a, $4f
    ld d, b
    ld e, [hl]
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    rst $28
    xor $51
    ld c, a
    ld b, d
    ld c, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld d, b
    ld b, [hl]
    ld b, h
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld a, [hl+]
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
    xor $44
    ld c, a
    ld c, h
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    jr nc, @+$40

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld c, h
    ld c, h
    ld c, b
    ld h, h
    rst $38
    ldh a, [$a3]
    inc sp
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    rst $28
    xor $52
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $51
    ld a, $49
    ld c, b
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $3f
    ld c, c
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $43
    ld b, d
    ld d, h
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $40
    ld a, $4b
    ld h, d
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld a, $4a
    ld b, d
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
    xor $a3
    inc l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, d
    ld c, l
    ld c, h
    ld c, a
    ld d, c
    ld a, $4b
    ld d, c
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $52
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    rst $28
    xor $3f
    ld d, d
    ld d, c
    ld h, d
    ld a, $49
    ld d, b
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    rst $28
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $a3
    ld a, $4b
    ld b, c
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ccf
    ld d, [hl]
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
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
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $62
    ccf
    ld b, d
    ld h, d
    ld a, $ef
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $3a
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
    ld h, d
    ld b, c
    ld c, h
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    scf
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
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $52
    ld c, l
    ld c, l
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
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
    ld a, [hl+]
    ld c, h
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $50
    ld c, b
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld d, c
    ld c, h
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
    ld d, b
    ld c, h
    ld c, d
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
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_042_56d2

    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    rst $28
    xor $45
    ld a, $50
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
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
    rst $28
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, h
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d

jr_042_56d2:
    ld b, l
    ld c, h
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
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
    xor $3a
    ld b, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, e
    ld h, d
    rst $30
    ldh a, [$eb]
    sbc a
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
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
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
    ld c, c
    ld b, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $4c
    ld b, e
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
    ld a, [$eff7]
    xor $9f
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
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $04
    rlca
    ld d, c
    ld b, l
    ld h, d
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld h, d
    ld c, d
    ld c, h
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld d, d
    ld c, e
    ld b, c
    ld c, a
    ld b, d
    ld b, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld c, h
    ld d, d
    ld d, b
    ld a, $4b
    ld b, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld a, [$eff7]
    xor $9f
    and e
    ld b, e
    ld a, $49
    ld c, c
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld c, a
    ld a, $44
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $49
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld b, l
    ld a, $51
    ld l, b
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
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $50
    ld b, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f3
    sbc a
    and e
    scf
    ld c, h
    ld h, d
    ld b, b
    ld b, d
    ld c, c
    ld b, d
    ccf
    ld c, a
    ld a, $51
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, [hl]
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
    rst $28
    xor $45
    ld b, d
    ld c, c
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
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
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl], $45
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld b, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, c
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
    ld a, [$eff7]
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
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
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $04
    rlca
    ld d, c
    ld b, l
    ld h, d
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld h, d
    ld c, d
    ld c, h
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl-], a
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, [hl]
    rst $28
    xor $4a
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld h, d
    ld d, c
    ld d, d
    ld c, d
    ccf
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $3e
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld a, $4b
    ld b, b
    ld b, [hl]
    ld b, d
    ld c, e
    ld d, c
    rst $28
    xor $4d
    ld c, h
    ld b, d
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld a, $46
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $49
    ld b, [hl]
    ld b, e
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld c, h
    ld h, d
    ld b, b
    ld b, d
    ld c, c
    ld b, d
    ccf
    ld c, a
    ld a, $51
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld a, $62
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
    ld b, l
    ld b, d
    ld c, c
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
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
    ld a, [$eff7]
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
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    scf
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
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld b, c
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld c, l
    ld c, a
    ld b, d
    ld d, b
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
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
    add hl, hl
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $44
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld d, b
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
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
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
    xor $43
    ld a, $4f
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, e
    ld d, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, h
    ld d, d
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr c, jr_042_5b8e

    ld c, l
    ld b, d
    ld c, a
    ld h, d
    ld b, e
    ld c, c
    ld c, h
    ld c, h
    ld c, a
    ld e, [hl]
    rst $28
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
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    rst $28
    xor $4c
    ld b, e
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
    ld a, [$eff7]
    xor $4c
    ld c, e
    ld h, d
    ld d, c
    ld b, l

jr_042_5b8e:
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    rst $28
    xor $52
    ld d, b
    ld h, d
    ld b, b
    ld a, $4d
    ld a, $3f
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld a, $50
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
    dec hl
    ld c, d
    ld c, d
    ld e, a
    ld h, d
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
    xor $54
    ld b, [hl]
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
    xor $51
    ld c, h
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    rst $28
    xor $48
    ld b, [hl]
    ld b, c
    ld c, e
    ld a, $4d
    ld c, l
    ld b, d
    ld b, c
    ld h, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld b, d
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
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, c
    ld a, $4b
    ld b, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
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
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    inc l
    rst $28
    xor $40
    ld a, $4b
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld b, [hl]
    ld b, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $a3
    daa
    ld a, $4b
    ld b, h
    ld b, d
    ld c, a
    ld e, [hl]
    ld h, d
    daa
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $4f
    ld d, d
    ld d, b
    ld b, l
    ld e, a
    ld h, d
    ld a, [hl+]
    ld c, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, a
    ld a, $44
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $634c
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $45
    ld d, d
    ld c, a
    ld d, c
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld a, $49
    ld c, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld b, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld c, e
    ld c, h
    ld d, c
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
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, c
    ld b, d
    ld a, $4f
    rst $28
    xor $2f
    ld b, [hl]
    ld c, l
    ld d, b
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    rst $28
    xor $56
    ld b, d
    ld d, c
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld b, b
    ld b, l
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld b, [hl]
    ld b, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
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
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    rst $28
    xor $51
    ld c, a
    ld b, d
    ld c, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $42
    ld d, e
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld l, b
    rst $28
    xor $44
    ld c, a
    ld c, h
    ld d, h
    ld d, c
    ld b, l
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    rst $28
    xor $51
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, a
    ld d, b
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
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
    ld a, $51
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld e, [hl]
    ld h, d
    jr nc, jr_042_5e97

    ld e, a
    jr nc, jr_042_5e97

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
    xor $54
    ld b, l
    ld a, $51
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $40
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, l
    ld d, d
    ld d, c
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $40
    ld a, $51
    ld b, b
    ld b, l

jr_042_5e97:
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, a
    ld a, $4f
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $40
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
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
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, a
    ld a, $4f
    ld e, a
    ld a, [$f0f7]
    or $62
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, a
    ld a, $4f
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, a
    ld a, $4f
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, h
    ld a, $4f
    ccf
    ld a, $44
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $50
    ld d, c
    ld b, d
    ld a, $49
    ld h, d
    ld c, d
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
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    ld h, $6a
    ld c, h
    ld c, e
    ld e, [hl]
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld a, $62
    ccf
    ld b, d
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, e
    ld b, [hl]
    ld b, e
    ld b, e
    ld h, d
    ld d, b
    ld c, e
    ld b, [hl]
    ld b, e
    ld b, e
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
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
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $50
    ld b, b
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld a, $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $fa
    rst $30
    rst $28
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $44
    ld b, d
    ld d, c
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
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    rst $28
    xor $2c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
    scf
    ld a, $48
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    rst $28
    xor $3e
    ld b, b
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld h, d
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ccf
    ld e, a
    rst $28
    xor $2c
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $43
    ld a, $53
    ld c, h
    ld c, a
    ld b, [hl]
    ld d, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $49
    ld a, $50
    ld d, c
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld h, $45
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    rst $28
    xor $96
    inc sp
    inc l
    ld h, $2e
    ld h, d
    jr c, jr_042_6170

    sub a
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
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
    ld e, a
    rst $28
    xor $f0
    db $eb
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, h
    ld e, a
    ld h, d
    inc l
    ld h, d
    rst $28
    xor $3e
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d

jr_042_6170:
    ld b, h
    ld c, a
    ld a, $4b
    ld b, c
    ld d, b
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld a, $4b
    ld b, c
    ld c, l
    ld a, $62
    ld [hl], $49
    ld b, [hl]
    ccf
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
    daa
    ld l, e
    ld a, $62
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $ef
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
    ld [hl], $49
    ld b, [hl]
    ld c, h
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
    rst $28
    xor $42
    ld b, h
    ld b, h
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    scf
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
    xor $40
    ld a, $4b
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld d, b
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
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
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
    dec h
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
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $44
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld d, b
    rst $28
    xor $46
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld a, [$eff7]
    xor $54
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
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $4f
    ld b, d
    ld a, $40
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld d, c
    ld e, [hl]
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld [hl], $49
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, l
    ld d, d
    ld d, c
    rst $28
    xor $3e
    ld c, c
    ld c, c
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
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $ef
    xor $41
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $41
    ld c, a
    ld c, h
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    ld h, d
    ld bc, $6209
    ld c, d
    ld c, h
    ld c, a
    ld b, d
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
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld a, $4f
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc h
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $4f
    ld b, d
    ld a, $40
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, l
    ld a, $4f
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $50
    ld c, h
    ld c, d
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
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    rst $28
    xor $51
    ld a, $48
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    ld a, [$eff7]
    xor $54
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
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, c
    ld c, a
    ld c, h
    ld c, l
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    dec [hl]
    ld a, $46
    ld d, b
    ld b, d
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
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $4d
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    daa
    ld l, e
    ld a, $62
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $ef
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
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $51
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
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
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
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld c, d
    ld b, d
    ld c, a
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld l, b
    ld e, a
    ld e, a
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
    or $63
    ld h, d
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    rst $28
    xor $41
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $41
    ld c, h
    ld c, l
    ld d, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
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
    dec hl
    ld d, d
    ld b, l
    ld h, h
    ld h, d
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $37
    ld b, l
    ld a, $51
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, e
    ld h, e
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
    dec hl
    ld b, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld l, h
    ld b, d
    rst $28
    xor $49
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
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
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
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
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, e
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, e
    rst $28
    xor $25
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc a
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $30
    ld a, $47
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld c, l
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld e, [hl]
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    rst $28
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld d, b
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld h, h
    rst $28
    xor $f7
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    jr nc, jr_042_665e

    ld b, a
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    rst $28
    xor $4d
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld c, h
    ld c, h
    ld e, a
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    inc h
    ld c, a
    ld c, a
    ld b, h
    ld b, l
    ld h, e
    ld h, d

jr_042_665e:
    inc a
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $4d
    ld c, a
    ld b, d
    ld b, b
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    rst $28
    xor $42
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $52
    ld c, e
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld b, [hl]
    ld d, e
    ld a, $3f
    ld c, c
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $37
    ld b, l
    ld c, a
    ld c, h
    ld d, h
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld d, d
    ld c, e
    ld b, h
    ld b, d
    ld c, h
    ld c, e
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld a, $56
    ld h, h
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $40
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $43
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, b
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    jr c, jr_042_67ac

    ld c, d
    ld c, d
    ld e, a
    ld e, a
    ld e, a
    ld [hl], $4c
    ld d, d
    ld c, e
    ld b, c
    ld d, b
    rst $28
    xor $46
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $4a
    ld a, $56
    ld h, d
    ld d, c
    ld c, a
    ld d, [hl]
    ld h, d
    or $5f
    rst $28
    xor $f7
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    jr nc, jr_042_67d8

    ld b, a
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    ld e, [hl]
    rst $28
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d

jr_042_67ac:
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    inc l

jr_042_67d8:
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld e, a
    ld h, d
    ld sp, $544c
    rst $28
    xor $f6
    ld e, [hl]
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld b, b
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld e, [hl]
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, l
    ld a, $4f
    ld b, c
    ld c, h
    ld c, e
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    scf
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
    rst $28
    xor $40
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4b
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4b
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc h
    ld d, b
    ld c, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $41
    ld b, [hl]
    ld d, b
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, b
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    dec h
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
    dec hl
    ld b, [hl]
    ld d, b
    ld h, d
    jr nc, jr_042_6926

    ld b, a
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    rst $28
    xor $50
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, d
    ld c, l
    ld d, b
    ld b, d
    ld d, c
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
    ld c, l
    ld c, a
    ld c, h
    ld b, b
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l

jr_042_6926:
    ld b, d
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld a, [$eff7]
    xor $2a
    ld a, $51
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    or $5e
    rst $28
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, a
    ld a, $44
    ld b, d
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $f6
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
    rst $28
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
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld h, $45
    ld a, $4a
    ccf
    ld b, d
    ld c, a
    rst $28
    xor $4c
    ld b, e
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld a, [$eff7]
    xor $2a
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld b, d
    ld d, l
    ld b, [hl]
    ld d, b
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld a, $49
    ld d, b
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
    ld b, h
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4a
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld d, b
    ld a, [$eff7]
    xor $51
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld b, c
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
    xor $49
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
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
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld a, [$eff7]
    xor $2a
    ld a, $51
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    or $5e
    rst $28
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, e
    ld a, $52
    ld c, c
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld e, [hl]
    rst $28
    xor $49
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
    ld a, $62
    ld a, $fa
    rst $30
    rst $28
    xor $52
    ld d, b
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
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
    ld a, [$eff7]
    xor $52
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec l
    ld [hl-], a
    jr c, jr_042_6b7a

    ld sp, $2f24
    rst $28
    xor $52
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl-], a
    inc sp
    scf
    ld sp, $f75f
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld d, b
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    rst $28
    xor $3f
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c

jr_042_6b7a:
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $26
    ld b, l
    ld a, $4a
    ccf
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld a, $50
    ld h, d
    ld d, b
    ld c, h
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $3e
    ld d, b
    ld h, d
    ld c, l
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
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
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld a, [$eff7]
    xor $2a
    ld a, $51
    ld b, d
    ld d, b
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $50
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $49
    ld b, [hl]
    ld b, d
    ld c, e
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
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
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $4a
    ld a, $44
    ld b, [hl]
    ld b, b
    ld a, $49
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, h
    ld a, $4f
    ld c, l
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    ld a, [$eff7]
    xor $49
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
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
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
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
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld a, [$eff7]
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    rst $28
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
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $49
    ld a, $50
    ld d, c
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
    ld d, d
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3e
    ld b, c
    ld d, e
    ld b, d
    ld c, e
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld b, e
    ld a, [$eff7]
    xor $56
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
    ld d, b
    ld b, d
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $4d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld l, h
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld c, l
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $36
    jr z, jr_042_6dac

    jr z, jr_042_6da5

    scf
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld d, c
    ld c, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ld d, b
    rst $28
    xor $4c
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]

jr_042_6da5:
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $3e

jr_042_6dac:
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    rst $28
    xor $46
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld d, b
    ld b, b
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3e
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr c, @+$52

    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, e
    ld d, d
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $3e
    ld b, c
    ld d, e
    ld b, d
    ld c, e
    ld d, c
    ld d, d
    ld c, a
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
    ld b, b
    ld a, $4b
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    rst $28
    xor $40
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld [bc], a
    nop
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld a, $49
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld b, l
    ld b, d
    ld c, a
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld c, l
    ld b, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
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
    ld b, [hl]
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, a
    ld d, d
    ld c, e
    rst $28
    xor $3e
    ld d, h
    ld a, $56
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4f
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $4c
    ld c, l
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
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
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
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
    ld e, [hl]
    rst $28
    xor $49
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $51
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
    xor $37
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld a, $56
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    dec hl
    ld a, $49
    ld b, d
    ld h, d
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld l, c
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, [hl]
    or $63
    rst $30
    ldh a, [$eb]
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
    ld h, d
    ld b, c
    ld c, h
    ld e, a
    rst $28
    xor $2c
    ld l, d
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3f
    ld c, h
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $54
    ld a, $4b
    ld c, e
    ld a, $62
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, [hl]
    ld a, [$eff7]
    xor $f6
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    or $63
    rst $28
    xor $27
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    ld h, e
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
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    rst $28
    xor $50
    ld a, $46
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld e, a
    ld e, a
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld a, $46
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $4f
    ld a, $51
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld b, a
    ld c, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
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
    dec hl
    ld c, d
    ld c, d
    ld e, a
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld e, a
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
    dec hl
    ld c, d
    ld c, d
    and h
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
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
    rst $28
    xor $3a
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld l, d
    ld h, d
    ld c, l
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4d
    ld b, d
    ld c, a
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld a, $4b
    ld b, b
    ld b, d
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld a, [$eff7]
    xor $44
    ld c, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
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
    ld sp, $544c
    ld h, d
    inc l
    ld a, [$eff7]
    xor $40
    ld a, $4b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $43
    ld a, $4f
    ld c, d
    ld h, e
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    or $5f
    rst $28
    xor $2a
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $5f
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, a
    ld b, [hl]
    ld d, e
    ld a, $49
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
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
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $5f
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
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, d
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
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
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
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $41
    ld b, [hl]
    ld d, b
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, b
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    dec h
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
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    or $63
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
    ld a, [$eff7]
    xor $4c
    ld c, e
    ld h, d
    ld d, [hl]
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
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld a, [hl+]
    ld c, a
    ld a, $4b
    ld b, c
    ld c, l
    ld a, $62
    ld [hl], $49
    ld b, [hl]
    ccf
    rst $28
    xor $54
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld d, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld c, h
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld c, e
    ld a, $5e
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld a, $46
    ld b, h
    ld b, l
    ld d, c
    ld a, [$eff7]
    xor $4c
    ld d, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $5e
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, d
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
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld d, b
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    rst $28
    xor $52
    ld c, l
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
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
    xor $f3
    sbc a
    and e
    add hl, hl
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    rst $28
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
    ld e, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld a, [$eff7]
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ccf
    ld c, h
    ld d, [hl]
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld b, c
    ld a, $4b
    ld b, h
    ld b, d
    ld c, a
    ld c, h
    ld d, d
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $32
    ld b, l
    ld e, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld h, e
    rst $28
    xor $f7
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $53
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
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
    xor $f3
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
    xor $4c
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    add hl, hl
    ld b, l
    ld b, d
    ld d, h
    ld h, e
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld b, h
    ld c, c
    ld a, $41
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld a, [$eff7]
    xor $45
    ld d, d
    ld c, a
    ld d, c
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $4a
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    or $5e
    rst $28
    xor $46
    ld d, c
    ld l, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld a, $4a
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, c
    ld b, c
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
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    rst $28
    xor $50
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    ld h, d
    ld b, l
    ld d, d
    ld c, a
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
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
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $64
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
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    inc l
    ld h, d
    ld c, l
    ld b, [hl]
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld d, d
    ld c, l
    rst $28
    xor $3e
    ld h, d
    scf
    ld b, [hl]
    ld c, e
    ld d, [hl]
    jr nc, jr_042_7650

    ld b, c
    ld a, $49
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld a, $62
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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

jr_042_7650:
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    cpl
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    rst $28
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
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $52
    ld d, b
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
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
    ld e, [hl]
    ld a, [$eff7]
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $43
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, b
    ld c, d
    ld a, $49
    ld c, c
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
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
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $2d
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
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
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld d, [hl]
    ld c, h
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
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
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
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, b
    ld d, c
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
    ld b, b
    ld a, $4b
    ld h, d
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
    ld a, [$eff7]
    xor $4c
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    rst $28
    xor $4a
    ld a, $51
    ld b, b
    ld b, l
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $5f
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
    ld d, c
    ld b, l
    ld a, $51
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
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
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
    rst $28
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
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld a, $50
    ld d, c
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
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
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld e, [hl]
    rst $28
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $62
    ld c, d
    ld a, $51
    ld b, b
    ld b, l
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld d, c
    ld c, a
    ld a, $46
    ld c, e
    ld b, d
    ld b, c
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
    ld c, a
    ld h, d
    ld a, $41
    ld b, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $4b
    ld b, d
    ld d, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_042_794d

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $4d
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, $49
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld b, d
    ld d, b

jr_042_791b:
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    daa
    ld b, d
    ld c, l
    ld b, d
    ld c, e
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $33
    cpl
    inc h
    ld sp, $5262
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $3f
    ld a, $51
    ld d, c
    ld c, c

jr_042_794d:
    ld b, d
    ld d, b
    ld e, [hl]
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    rst $28
    xor $4d
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, $49
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $40
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    sub [hl]
    ld h, $2b
    inc h
    dec [hl]
    ld a, [hl+]
    jr z, jr_042_791b

    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld c, e
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld a, $53
    ld b, d
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
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
    sub [hl]
    jr nc, jr_042_79ec

    dec sp
    jr z, jr_042_79ea

    sub a
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld c, e
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld b, e
    ld d, d

jr_042_79ea:
    ld c, c
    ld e, a

jr_042_79ec:
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    rst $28
    xor $96
    ld h, $24
    jr c, jr_042_7a3a

    inc l
    ld [hl-], a
    jr c, jr_042_7a3d

    sub a
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $40
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, a
    ld a, $51
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, d
    jr nc, jr_042_7a78

jr_042_7a3a:
    ld d, b
    ld d, c
    ld b, d

jr_042_7a3d:
    ld c, a
    ld h, e
    ld h, d
    daa
    ld l, e
    ld a, $ef
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, h
    rst $38
    ldh a, [$36]
    ld c, l
    ld c, c
    ld a, $51
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $33
    ld c, h
    ld c, h
    ld c, l
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, c
    ld h, d
    or $5f
    rst $30
    ldh a, [$37]
    ld b, l
    ld d, h
    ld a, $40
    ld c, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f3

jr_042_7a78:
    inc l
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $3e
    ld h, d
    ld [hl], $48
    ld d, [hl]
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $45
    ld b, [hl]
    ld d, c
    ld h, d
    or $68
    rst $28
    xor $45
    ld b, d
    ld a, $41
    ld h, e
    ld h, e
    rst $30
    ldh a, [$f6]
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $42
    ld b, h
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $36
    ld c, b
    ld d, [hl]
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $25
    ld d, d
    ld d, c
    ld e, [hl]
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    ld h, d
    ld a, $4f
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $43
    ld a, $4f
    ld c, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [rNR52]
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, b
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $42
    ld b, h
    ld b, h
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, d
    ld c, d
    ld a, $4b
    ld d, [hl]
    rst $28
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
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, c
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    rst $28
    xor $3e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    rst $28
    xor $40
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $40
    ld a, $4f
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $26
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    rst $28
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld b, e
    ld c, h
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
    ld e, a
    rst $28
    xor $f7
    ldh a, [$36]
    ld c, l
    ld c, c
    ld a, $50
    ld b, l
    ld h, e
    rst $28
    xor $33
    ld c, h
    ld c, h
    ld c, l
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, c
    ld h, d
    or $5f
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld h, e
    rst $28
    xor $25
    ld b, d
    ld b, d
    ld b, e
    dec l
    ld b, d
    ld c, a
    ld c, b
    ld d, [hl]
    ld e, [hl]
    ld a, [$eff7]
    xor $33
    ld c, h
    ld c, a
    ld c, b
    ld h, $45
    ld c, h
    ld c, l
    ld e, [hl]
    rst $28
    xor $35
    ld b, [hl]
    ccf
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld b, d
    ld b, d
    ld b, e
    dec l
    ld b, d
    ld c, a
    ld c, b
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $50
    ld d, c
    ld h, d
    ld d, c
    ld a, $50
    ld d, c
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec [hl]
    ld b, [hl]
    ccf
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $51
    ld b, l
    ld a, $4b
    ld h, d
    inc sp
    ld c, h
    ld c, a
    ld c, b
    ld h, $45
    ld c, h
    ld c, l
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld [hl], $46
    ld c, a
    ld c, c
    ld c, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld a, $50
    ld h, d
    ld d, [hl]
    ld d, d
    ld c, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $3e
    ld d, b
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
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
    ld c, e
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
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld b, l
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld a, [$eff7]
    xor $3e
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, [hl]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
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
    ld e, [hl]
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $4f
    ld b, d
    ld b, d
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld b, l
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $f7
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
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
