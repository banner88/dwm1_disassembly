; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $044", ROMX[$4000], BANK[$44]

    db $44 ; Bank number

    ; Cross-bank dispatch table (102 entries)
    ; Called via: ld hl, $44XX / rst $10
    dw LoadB44_40cd                  ; Entry 0
    dw $40FB                          ; Entry 1
    dw $4129                          ; Entry 2
    dw $4009                          ; Entry 3
    dw $4157                          ; Entry 4
    dw $41AE                          ; Entry 5
    dw $4328                          ; Entry 6
    dw $44C6                          ; Entry 7
    dw $45A4                          ; Entry 8
    dw $45EE                          ; Entry 9
    dw $4645                          ; Entry 10
    dw $46DB                          ; Entry 11
    dw $474D                          ; Entry 12
    dw $477B                          ; Entry 13
    dw $47F5                          ; Entry 14
    dw $488A                          ; Entry 15
    dw $48D8                          ; Entry 16
    dw $49EC                          ; Entry 17
    dw $4A22                          ; Entry 18
    dw $4ADD                          ; Entry 19
    dw $4B13                          ; Entry 20
    dw $4BD6                          ; Entry 21
    dw $4C0C                          ; Entry 22
    dw $4C98                          ; Entry 23
    dw $4D24                          ; Entry 24
    dw $4E34                          ; Entry 25
    dw $4F10                          ; Entry 26
    dw $4FA7                          ; Entry 27
    dw $5005                          ; Entry 28
    dw $50F1                          ; Entry 29
    dw $513D                          ; Entry 30
    dw $51AF                          ; Entry 31
    dw $521A                          ; Entry 32
    dw $5325                          ; Entry 33
    dw $539B                          ; Entry 34
    dw $5457                          ; Entry 35
    dw $5512                          ; Entry 36
    dw $5558                          ; Entry 37
    dw $55D8                          ; Entry 38
    dw $570B                          ; Entry 39
    dw $572F                          ; Entry 40
    dw $577E                          ; Entry 41
    dw $589C                          ; Entry 42
    dw $5A5D                          ; Entry 43
    dw $5CA5                          ; Entry 44
    dw $5E5D                          ; Entry 45
    dw $5EEA                          ; Entry 46
    dw $6055                          ; Entry 47
    dw $60FD                          ; Entry 48
    dw $61D0                          ; Entry 49
    dw $6238                          ; Entry 50
    dw $62F4                          ; Entry 51
    dw $6413                          ; Entry 52
    dw $65A2                          ; Entry 53
    dw $6655                          ; Entry 54
    dw $6762                          ; Entry 55
    dw $6859                          ; Entry 56
    dw $687C                          ; Entry 57
    dw $68F6                          ; Entry 58
    dw $692F                          ; Entry 59
    dw $6983                          ; Entry 60
    dw $69E8                          ; Entry 61
    dw $6A0F                          ; Entry 62
    dw $6A75                          ; Entry 63
    dw $6AA6                          ; Entry 64
    dw $6B3C                          ; Entry 65
    dw $6BAB                          ; Entry 66
    dw $6BF9                          ; Entry 67
    dw $6CF0                          ; Entry 68
    dw $6D60                          ; Entry 69
    dw $6DDB                          ; Entry 70
    dw $6E1D                          ; Entry 71
    dw $6E39                          ; Entry 72
    dw $6F3E                          ; Entry 73
    dw $7035                          ; Entry 74
    dw $7103                          ; Entry 75
    dw $713F                          ; Entry 76
    dw $7206                          ; Entry 77
    dw $7283                          ; Entry 78
    dw $7309                          ; Entry 79
    dw $734D                          ; Entry 80
    dw $7364                          ; Entry 81
    dw $738A                          ; Entry 82
    dw $748B                          ; Entry 83
    dw $74BC                          ; Entry 84
    dw $751E                          ; Entry 85
    dw $7635                          ; Entry 86
    dw $7698                          ; Entry 87
    dw $7717                          ; Entry 88
    dw $774C                          ; Entry 89
    dw $77C9                          ; Entry 90
    dw $77FA                          ; Entry 91
    dw $78A6                          ; Entry 92
    dw $78E4                          ; Entry 93
    dw $79A6                          ; Entry 94
    dw $7B2C                          ; Entry 95
    dw $7B7C                          ; Entry 96
    dw $7C1E                          ; Entry 97
    dw $7D92                          ; Entry 98
    dw $7E4A                          ; Entry 99
    dw $7E9F                          ; Entry 100
    dw $7F05                          ; Entry 101

LoadB44_40cd:
    ld a, [$c822]
    cp $01
    jr nz, jr_044_40de

    ld a, $01
    ld [$c822], a
    ld hl, $1b00
    rst $10
    ret


jr_044_40de:
    ld a, [$c823]
    cp $62
    jr c, jr_044_40f4

    sub $62
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1b00
    rst $10
    ret


jr_044_40f4:
    ld de, $4007
    call CallTextEngine
    ret


    ld a, [$c822]
    cp $01
    jr nz, jr_044_410c

    ld a, $01
    ld [$c822], a
    ld hl, $1b01
    rst $10
    ret


jr_044_410c:
    ld a, [$c823]
    cp $62
    jr c, jr_044_4122

    sub $62
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1b01
    rst $10
    ret


jr_044_4122:
    ld de, $4007
    call RunTextHandler
    ret


    ld a, [$c822]
    cp $01
    jr nz, jr_044_413a

    ld a, $01
    ld [$c822], a
    ld hl, $1b02
    rst $10
    ret


jr_044_413a:
    ld a, [$c823]
    cp $62
    jr c, jr_044_4150

    sub $62
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1b02
    rst $10
    ret


jr_044_4150:
    call LoadB44_40cd
    call RequestScreenUpdate
    ret


    db $eb
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $32
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, c
    ld a, $56
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld l, d
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $50
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld a, $4b
    ld d, c
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld b, e
    ld b, d
    ld d, b
    ld d, b
    ld c, h
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $2b
    ld b, d
    ld b, d
    ld h, d
    dec hl
    ld b, d
    ld b, d
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
    jr nc, jr_044_4226

    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld c, e
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
    xor $a3
    jr z, jr_044_422e

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
    rst $28
    xor $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld a, [$eff7]
    xor $40
    ld b, l
    ld a, $4f
    ld a, $40
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    add hl, hl

jr_044_4226:
    ld c, h
    ld c, a
    ld h, d
    ld b, d
    ld d, l
    ld a, $4a
    ld c, l

jr_044_422e:
    ld c, c
    ld b, d
    ld e, [hl]
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld b, d
    ld a, $50
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $46
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    rst $28
    xor $3e
    ld b, h
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    rst $28
    xor $4f
    ld b, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld a, $4b
    ld b, b
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $50
    ld d, d
    ld c, l
    ld c, l
    ld c, h
    ld c, a
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    rst $28
    xor $50
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $50
    ld h, d
    ld [hl], $49
    ld c, h
    ld d, h
    inc h
    ld c, c
    ld c, c
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $36
    ld a, $4d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    daa
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld d, b
    ld h, d
    or [hl]
    ld h, d
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, b
    ld b, d
    ld a, [$eff7]
    xor $40
    ld b, l
    ld a, $4f
    ld a, $40
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld d, b
    ld h, e
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
    ld d, b
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld d, c
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
    xor $a3
    ld sp, $514c
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
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
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $3e
    ld c, c
    ld d, b
    ld c, h
    ld h, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld a, [$eff7]
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
    rst $28
    xor $3f
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld b, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld c, a
    ld b, d
    ld b, d
    ld d, b
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $41
    ld b, [hl]
    ld b, d
    ld e, a
    ld h, d
    scf
    ld b, l
    ld d, d
    ld d, b
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ld a, $62
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld a, $4b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $51
    ld c, a
    ld b, d
    ld b, d
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
    xor $a3
    scf
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
    ld e, [hl]
    rst $28
    xor $3e
    ld c, l
    ld c, l
    ld c, a
    ld c, h
    ld c, l
    ld c, a
    ld b, [hl]
    ld a, $51
    ld b, d
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $4b
    ld a, $4a
    ld b, d
    ld b, c
    ld e, [hl]
    ld h, d
    daa
    ld b, d
    ld a, $41
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, [hl]
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld a, $49
    ld c, d
    ld c, h
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld d, b
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, d
    ld e, [hl]
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    rst $28
    xor $4c
    ld c, e
    ld b, d
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $a3
    dec hl
    ld c, h
    ld d, h
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    rst $28
    xor $4a
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld b, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld c, h
    ld c, a
    ld c, e
    ld h, d
    ld c, h
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
    jr nc, @+$40

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    scf
    ld a, $4a
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $a3
    inc h
    ld c, e
    ld h, d
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld c, d
    ld a, $4b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld d, b
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $3f
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, d
    ld b, c
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
    ld e, a
    ld a, [$eff7]
    xor $a3
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
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
    ld h, h
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld h, e
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
    xor $2c
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $62
    ld b, c
    ld b, d
    ld c, e
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    rst $28
    xor $40
    ld a, $50
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld a, $4b
    ld h, d
    ld c, h
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, d
    ld a, $4b
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
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld c, b
    ld b, d
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $5f
    ld e, a
    ld e, a
    ld [hl], $4c
    ld c, d
    ld b, d
    ld h, d
    ld d, d
    ld c, e
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld c, e
    rst $28
    xor $49
    ld b, [hl]
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $b6
    ld h, d
    ccf
    ld d, d
    ccf
    ccf
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
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
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld [hl], $40
    ld b, l
    ld c, h
    ld c, h
    ld c, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    or $63
    ld h, d
    inc l
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $3e
    ld c, e
    ld h, d
    ld b, d
    ld d, l
    ld b, b
    ld b, d
    ld c, c
    ld c, c
    ld b, d
    ld c, e
    ld d, c
    ld a, [$eff7]
    xor $43
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
    scf
    ld c, h
    ld b, c
    ld a, $56
    ld l, b
    ld h, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $50
    ld c, e
    ld a, $4f
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
    ld e, a
    rst $28
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $49
    ld d, h
    ld a, $56
    ld d, b
    rst $28
    xor $3f
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $3a
    ld a, $4f
    ld c, l
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld b, h
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
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $40
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld e, a
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, d
    ld a, $40
    ld b, l
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld c, a
    ld b, d
    ld l, b
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
    ld a, [$eff7]
    xor $b6
    ld h, d
    scf
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
    ld a, [hl+]
    ld c, h
    ld h, d
    ld d, d
    ld c, l
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
    add hl, sp
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $4c
    ld c, a
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
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
    scf
    ld a, $49
    ld b, [hl]
    ld d, b
    ld c, d
    ld a, $4b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld b, c
    ld d, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $50
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld d, c
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld a, [$eff7]
    xor $3e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld d, c
    ld d, c
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld c, e
    ld b, c
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld a, $62
    ld d, b
    ld d, d
    ld c, l
    ld b, d
    ld c, a
    rst $28
    xor $51
    ld c, h
    ld c, l
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
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
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, e
    ld h, d
    scf
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld a, $48
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $62
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld a, $62
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $4f
    ld b, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    rst $28
    xor $f7
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
    ld d, b
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    add hl, hl
    ld a, [$eff7]
    xor $40
    ld c, c
    ld a, $50
    ld d, b
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
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $30
    ld b, d
    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $25
    ld b, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $4c
    ld c, l
    ld b, d
    ld c, e
    ld h, d
    ld a, $50
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4d
    ld c, a
    ld b, [hl]
    ld d, a
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    rst $28
    xor $4c
    ld b, e
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
    xor $43
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
    ld h, d
    or [hl]
    rst $28
    xor $45
    ld a, $51
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
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
    ld b, [hl]
    ld d, c
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
    ld b, h
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $53
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
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
    xor $26
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, h
    ld c, h
    ld a, [$eff7]
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
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
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld a, $4f
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
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
    xor $25
    ld b, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld b, d
    ld c, a
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_044_4a7d

    ld h, d
    ld d, [hl]
    ld b, d
    ld a, $4f
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $4f
    ld b, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld h, d
    ld c, c
    ld b, d
    ld a, $41
    ld h, d
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld e, a
    ld e, a
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
    rst $28
    xor $4a
    ld d, d
    ld d, b
    ld b, l
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
    ld e, [hl]
    ld h, d
    ld c, a
    ld c, h
    ld b, b
    ld c, b
    ld d, b
    ld a, [$eff7]

jr_044_4a7d:
    xor $b6
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, e
    ld a, $40
    ld b, d
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, a
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld c, h
    ld c, a
    ld d, c
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $41
    ld b, [hl]
    ld c, a
    ld b, d
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $49
    ld b, [hl]
    ccf
    ld c, a
    ld a, $4f
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$eb]
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
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld a, $4f
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
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
    xor $30
    ld b, d
    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    inc h
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
    rst $28
    xor $49
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, c
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $40
    ld a, $53
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
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $50
    ld b, b
    ld c, a
    ld b, d
    ld a, $4a
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $4d
    ld b, d
    ld b, b
    ld d, d
    ld c, c
    ld b, [hl]
    ld a, $4f
    ld h, d
    ld d, e
    ld c, h
    ld b, [hl]
    ld b, b
    ld b, d
    ld h, d
    ld a, $50
    rst $28
    xor $46
    ld b, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $50
    ld c, h
    ld c, d
    ld b, d
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
    add hl, hl
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    rst $28
    xor $41
    ld b, [hl]
    ld a, $4f
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
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
    ld a, $4f
    ld d, [hl]
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld a, $4f
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
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
    ld h, d
    ld d, c
    ld c, h
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
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $27
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    rst $28
    xor $50
    ld b, d
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $51
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, a
    ld d, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
    ld d, b
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld a, $62
    ld b, h
    ld d, d
    ld a, $4f
    ld b, c
    ld b, [hl]
    ld a, $4b
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld d, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld e, a
    ld e, a
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
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    rst $28
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld d, h
    ld c, e
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
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld a, $51
    ld h, d
    jr nc, jr_044_4cee

    ld b, c
    ld h, $3e
    ld d, c
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
    ld d, [hl]
    ld h, d
    ld d, b
    ld a, $56
    rst $28
    xor $30
    ld a, $41
    ld h, $3e
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld b, h
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $54
    ld b, [hl]
    ld c, e
    ld b, c

jr_044_4cee:
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
    ld c, a
    ld h, d
    ld a, $44
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    rst $28
    xor $4a
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $51
    ld c, h
    ld c, a
    ld c, e
    ld a, $41
    ld c, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    inc l
    ld d, c
    ld h, d
    ld c, a
    ld b, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, c
    ld d, b
    rst $28
    xor $4a
    ld b, d
    ld e, a
    ld h, d
    dec hl
    ld a, $53
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld a, [$eff7]
    xor $44
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $36
    ld b, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
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
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
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
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    jr nc, jr_044_4dd4

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
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
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $3f
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    dec h
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    rst $28

jr_044_4dd4:
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld a, [$eff7]
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
    sbc a
    and e
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
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $4a
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld a, $4a
    ld c, h
    ld c, e
    ld b, h
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld b, d
    ld d, b
    ld d, c
    ld a, $4b
    ld d, c
    ld d, b
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    xor $3e
    ld c, a
    ld b, d
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
    xor $4c
    ld b, e
    ld h, d
    dec h
    ld b, [hl]
    ld b, h
    scf
    ld c, a
    ld d, d
    ld c, e
    ld c, b
    ld e, [hl]
    ld a, [$eff7]
    xor $27
    ld b, d
    ld a, $41
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    or [hl]
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
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
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld d, b
    ld b, d
    ld h, d
    inc bc
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld h, e
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
    xor $3c
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
    ld a, [$eff7]
    xor $29
    ld a, $40
    ld b, d
    scf
    ld c, a
    ld b, d
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
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    rst $28
    xor $29
    ld a, $40
    ld b, d
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld d, b
    ld a, [$eff7]
    xor $40
    ld d, d
    ld c, a
    ld d, b
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
    xor $40
    ld a, $50
    ld d, c
    ld h, d
    ld a, $62
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld a, [$eff7]
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
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    rst $28
    xor $3f
    ld b, d
    ld c, c
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ccf
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld c, l
    ld a, $51
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld b, c
    ld h, d
    ld a, $54
    ld a, $56
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl], $45
    ld b, d
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $50
    ld b, d
    ld b, d
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
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
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
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
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
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $54
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld d, b
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    ld a, [$eff7]
    xor $46
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld e, [hl]
    rst $28
    xor $54
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
    ld c, a
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ccf
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
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    jr nc, jr_044_5104

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    scf
    ld a, $4a
    ld b, d
    ld c, a
    ld h, h
    ld a, [$eff7]
    xor $2b
    ld b, d
    ld l, b
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld c, h
    ld d, h
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
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    rst $28

jr_044_5104:
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    inc l
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld d, h
    ld h, e
    ld h, d
    inc h
    ld d, c
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    rst $28
    xor $54
    ld b, d
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
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
    ld d, c
    ld d, c
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
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld c, h
    ld d, h
    rst $28
    xor $49
    ld b, d
    ld a, $41
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld [hl], $51
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
    jr nc, jr_044_51f6

    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld c, d
    ld a, $4b
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_044_5231

    ld b, d
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l

jr_044_51f6:
    ld b, [hl]
    ld c, d
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
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
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d

jr_044_5231:
    ld h, d
    ld h, $45
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
    xor $9f
    and e
    scf
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
    rst $28
    xor $30
    ld b, d
    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $25
    ld b, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $4b
    ld c, h
    ld d, h
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld a, $49
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $45
    ld b, d
    ld a, $49
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
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    rst $28
    xor $27
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, h
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    jr nc, jr_044_532b

    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld b, [hl]
    ld d, c
    ld h, d
    ccf
    ld d, [hl]
    ld a, [$eff7]
    xor $3f
    ld b, [hl]
    ld d, c
    ld h, d
    ld a, $50
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $49
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d

jr_044_532b:
    ld h, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $45
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    ld h, h
    ld a, [$eff7]
    xor $31
    ld c, h
    ld d, h
    ld h, d
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld c, d
    ld b, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl], $5f
    ld d, c
    ld e, a
    ld a, $5f
    ld c, a
    ld e, a
    ld c, a
    ld e, a
    ld d, [hl]
    rst $28
    xor $36
    ld e, a
    ld b, l
    ld e, a
    ld c, a
    ld e, a
    ld b, [hl]
    ld e, a
    ld c, e
    ld e, a
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
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
    ldh a, [$ea]
    sbc a
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
    rst $28
    xor $3c
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
    ld b, c
    ld a, [$eff7]
    xor $28
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
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
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
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
    inc sp
    ld b, d
    ld a, $40
    ld b, d
    ld a, [$eff7]
    xor $b6
    ld h, d
    dec h
    ld c, a
    ld a, $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_044_5458

    ld c, a
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
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]

jr_044_5458:
    sbc a
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
    rst $28
    xor $3c
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
    ld b, c
    ld a, [$eff7]
    xor $28
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
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
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
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
    inc sp
    ld b, d
    ld a, $40
    ld b, d
    ld a, [$eff7]
    xor $b6
    ld h, d
    dec h
    ld c, a
    ld a, $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, @+$44

    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    or [hl]
    rst $28
    xor $25
    ld b, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld sp, $5442
    ld h, d
    ld a, $41
    ld d, e
    ld b, d
    ld c, e
    ld d, c
    ld d, d
    ld c, a
    ld b, d
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
    ld c, c
    ld a, $50
    ld d, c
    ld h, d
    ld c, d
    ld a, $51
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
    jr z, jr_044_5590

    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, @+$40

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    scf
    ld b, d
    ld d, c
    ld c, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $5f
    ld e, a
    ld e, a
    rst $28
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    jr z, jr_044_55d0

    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld e, a
    ld h, d
    inc l
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
    jr z, @+$64

    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28

jr_044_5590:
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $46
    ld c, e
    ld h, d
    add hl, hl
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    ld h, $3e
    ld c, c
    ld c, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    jr nc, jr_044_55fd

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $37
    ld b, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld c, e

jr_044_55d0:
    ld c, h
    ld d, h
    ld h, d
    ld c, h
    ld c, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, [hl]
    ld d, b
    ld b, l
    ld c, h
    ld c, l
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
    ld d, c
    ld a, $52
    ld b, h
    ld b, l
    ld d, c
    ld a, [$eff7]
    xor $4a

jr_044_55fd:
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld c, h
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl], $51
    ld b, d
    ld c, l
    ld a, [hl+]
    ld d, d
    ld a, $4f
    ld b, c
    ld l, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $30
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld b, b
    ld e, [hl]
    ld h, d
    daa
    ld a, $4f
    ld c, b
    ld h, $4f
    ld a, $3f
    ld e, [hl]
    ld a, [$eff7]
    xor $27
    ld c, a
    ld c, h
    ld c, c
    ld c, c
    ld e, [hl]
    ld h, d
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld b, h
    scf
    ld c, a
    ld b, d
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld a, [hl+]
    ld b, [hl]
    ld a, $4b
    ld d, c
    ld a, [hl-]
    ld c, h
    ld c, a
    ld c, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_044_5699

    ld c, l
    jr nc, jr_044_569c

    ld b, h
    ld b, [hl]
    ld b, b
    ld l, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $30
    ld a, $41
    jr nc, jr_044_56b3

    ld c, a
    ld c, a
    ld c, h
    ld c, a
    ld e, [hl]
    ld h, d
    jr z, jr_044_56cb

    ld b, d
    ld b, c
    ld b, d
    ld c, a
    ld e, [hl]
    ld a, [$eff7]
    xor $25
    ld b, d
    ld a, $4b
    jr nc, @+$40

    ld c, e
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $28
    ld d, e
    ld b, [hl]
    ld c, c
    ld a, [hl-]
    ld a, $4b
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $9f

jr_044_5699:
    and e
    add hl, sp
    ld b, [hl]

jr_044_569c:
    ld d, e
    ld b, [hl]
    ld b, e
    ld d, [hl]
    ld l, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $32
    ld c, a
    ld b, b
    ld e, [hl]
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld [hl], $49
    ld b, [hl]

jr_044_56b3:
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $38
    ld c, e
    ld b, [hl]
    ld b, b
    ld c, h
    ld c, a
    ld c, e
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $30
    ld d, d
    ld b, c
    ld c, a
    ld c, h

jr_044_56cb:
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld a, $49
    jr c, jr_044_572b

    inc h
    ld c, c
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $2b
    ld b, d
    ld a, $49
    ld b, d
    ld c, a
    ld e, [hl]
    ld h, d
    cpl
    ld b, [hl]
    ld c, h
    ld c, e
    ld b, d
    ld d, l
    ld e, [hl]
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    daa
    ld b, d
    ld a, $41
    ld sp, $5146
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld b, [hl]
    ld b, h
    dec [hl]
    ld c, h
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4f
    ld c, h
    ld a, $50
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d

jr_044_572b:
    ld b, d
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
    daa
    ld d, d
    ld b, c
    ld b, d
    ld h, e
    rst $28
    xor $3a
    ld a, $4b
    ld c, e
    ld a, $62
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld c, e
    ld a, $ef
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

jr_044_576b:
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    jr z, jr_044_576b

    rst $30
    rst $28
    xor $40
    ld c, c
    ld a, $50
    ld d, b
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, d
    ld d, c
    ld c, h
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $54
    ld a, $46
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld b, [hl]
    ld c, e
    ld a, $49
    ld h, d
    ld c, d
    ld a, $51
    ld b, b
    ld b, l

jr_044_57c0:
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    jr z, jr_044_57c0

    rst $30
    rst $28
    xor $40
    ld c, c
    ld a, $50
    ld d, b
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
    ld b, h
    ld d, d
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $50
    rst $28
    xor $24
    ld c, a
    ld c, d
    ld c, h
    ld c, a
    inc sp
    ld b, d
    ld b, c
    ld b, d
    ld h, d
    or [hl]
    ld h, d
    ld d, c
    ld d, h
    ld c, h
    ld a, [$eff7]
    xor $36
    ld c, e
    ld a, $46
    ld c, c
    ld d, [hl]
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
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
    rst $28
    xor $33
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    ld b, h
    ld c, h
    ld c, e
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $50
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld b, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld h, d
    ld c, d
    ld a, $51
    ld b, b
    ld b, l
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $33
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    dec hl
    ld b, [hl]
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld c, e
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $24
    ld c, e
    ld d, c
    ld b, [hl]
    ld b, c
    ld c, h
    ld d, c
    ld b, d
    ld h, d
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld a, $62
    ld b, l
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
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
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    rst $28
    xor $50
    ld b, d
    ld b, d
    ld h, e
    ld h, d
    dec [hl]
    ld b, d
    ld c, d
    ld b, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, c
    ld b, c
    rst $28
    xor $4a
    ld a, $4b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $51
    ld c, h
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
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $40
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, [hl+]
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
    inc sp
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_044_598a

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $37
    ld a, $4a
    ld b, d
    ld c, a
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
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $36
    ld b, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
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
    ld h, d
    inc l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4d
    ld c, c

jr_044_598a:
    ld a, $40
    ld b, d
    ld h, d
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
    ld a, $4b
    ld b, c
    rst $28
    xor $45
    ld a, $51
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
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
    ld b, [hl]
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, d
    ld b, c
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
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
    xor $54
    ld b, d
    ld b, c
    ld e, [hl]
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ld c, c
    ld a, $46
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, jr_044_5a64

    ld b, h
    ld d, b
    ld h, d
    ld b, l
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
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
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld c, h
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld b, c
    ld a, $56
    ld h, h
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, e

jr_044_5a64:
    ld h, d
    rst $28
    xor $2f
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
    ld a, $5f
    ld h, d
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
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld b, e
    ld b, [hl]
    ld c, a
    ld d, b
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
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
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
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld a, $50
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld c, a
    ld b, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc sp
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld c, a
    ld b, d
    ld b, d
    ld d, b
    ld h, d
    or [hl]
    rst $28
    xor $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld e, a
    ld e, a
    ld h, d
    inc l
    ld d, c
    ld d, b
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, l
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
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
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4c
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $ef
    xor $40
    ld c, a
    ld b, d
    ld a, $51
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
    ld a, [$eff7]
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    rst $28
    xor $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld b, e
    ld b, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, h
    ld d, b
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
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld c, a
    ld b, d
    ld b, d
    ld h, e
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
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $ef
    xor $40
    ld c, a
    ld b, d
    ld a, $51
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
    ld a, [$eff7]
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    rst $28
    xor $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld b, e
    ld b, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, h
    ld d, b
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
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $27
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld c, a
    ld b, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld a, $3f
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld c, c
    ld a, $4f
    ld a, [$eff7]
    xor $40
    ld b, l
    ld a, $4f
    ld a, $40
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld d, b
    rst $28
    xor $3e
    ld d, b
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
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc h
    ld b, e
    ld d, c
    ld b, d
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
    ld e, [hl]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld a, $4f
    ld b, d
    ld c, e
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
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, h
    ld c, h
    rst $28
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
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
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, l
    ld a, $50
    ld d, b
    ld b, d
    ld b, c
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, b
    ld b, [hl]
    ld b, c
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld c, h
    ld c, a
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld d, l
    ld a, $4a
    ld c, l
    ld c, c
    ld b, d
    ld e, [hl]
    rst $28
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld a, $62
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
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
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4d
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    dec hl
    ld b, d
    ld a, $49
    ld b, d
    ld c, a
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, $62
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld l, $46
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $40
    ld a, $4b
    ld h, d
    ld c, c
    ld b, d
    ld a, $4f
    ld c, e
    ld h, d
    dec hl
    ld b, d
    ld a, $49
    ld b, d
    ld c, a
    ld l, b
    ld a, [$eff7]
    xor $50
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $3f
    ld c, h
    ld c, a
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
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
    xor $27
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld l, $46
    ld b, c
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $3e
    ld c, e
    ld c, h
    ld d, c
    ld b, l
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
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld a, $4b
    ld d, [hl]
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
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $54
    ld a, $56
    ld h, e
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
    jr z, jr_044_5ed2

    ld b, d
    ld c, a
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
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
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld a, [$eff7]
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
    rst $28
    xor $3f
    ld d, [hl]
    ld h, d
    jr nc, jr_044_5ef3

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_044_5f08

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $37
    ld a, $4a
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a

jr_044_5ed2:
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
    dec h
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h

jr_044_5ef3:
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $54
    ld b, d
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
    ld e, a

jr_044_5f08:
    ld a, [$eff7]
    xor $a3
    inc h
    ld b, e
    ld d, c
    ld b, d
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
    ld e, [hl]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld a, $4f
    ld b, d
    ld c, e
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
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, h
    ld c, h
    rst $28
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
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
    ld a, [$eff7]
    xor $a3
    inc h
    ld c, e
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld b, b
    ld a, $4d
    ld a, $3f
    ld c, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $49
    ld b, d
    ld a, $4f
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld a, [$eff7]
    xor $4d
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld e, h
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    rst $28
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld b, l
    ld a, $51
    ld b, b
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld h, d
    ld c, c
    ld a, $46
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld d, b
    ld d, d
    ld c, c
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
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
    ld a, [$eff7]
    xor $a3
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $52
    ld c, e
    ld b, c
    ld c, h
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
    ld a, [$eff7]
    xor $36
    ld c, h
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
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    scf
    ld d, d
    ld c, a
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    rst $28
    xor $46
    ld c, e
    ld d, c
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
    ccf
    ld d, [hl]
    ld a, [$eff7]
    xor $45
    ld a, $51
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
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
    ld [hl], $3e
    ld d, [hl]
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $41
    ld a, $56
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld b, [hl]
    ld b, h
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $49
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4d
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $45
    ld b, [hl]
    ld b, h
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [$eff7]
    xor $3e
    ccf
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, c
    ld h, e
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
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$a3]
    jr nc, jr_044_614c

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    rst $28
    xor $3f
    ld d, [hl]
    ld h, d
    jr nc, jr_044_6152

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_044_6167

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $37
    ld a, $4a
    ld b, d
    ld c, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    or $62
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $ef
    xor $4d
    ld c, a
    ld c, h
    ld c, d
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, b
    ld b, [hl]
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $a3
    inc l

jr_044_614c:
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c

jr_044_6152:
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $53
    ld b, d
    ld b, c
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d

jr_044_6167:
    ld h, d
    ccf
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $51
    ld b, l
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $41
    ld d, d
    ld c, e
    ld b, h
    ld b, d
    ld c, h
    ld c, e
    ld h, e
    ld a, [$eff7]
    xor $a3
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld b, d
    rst $28
    xor $41
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld a, [$eff7]
    xor $42
    ld d, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $3e
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_044_6213

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_044_6228

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $37
    ld a, $4a
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld a, $40
    ld c, b
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
    ld b, h
    ld c, h
    rst $28
    xor $52
    ld c, l
    ld h, d
    ld d, c

jr_044_6213:
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld a, [$eff7]
    xor $40
    ld c, c
    ld b, [hl]
    ld c, d
    ccf

jr_044_6228:
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, e
    ld d, [hl]
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
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $ef
    xor $4b
    ld b, d
    ld d, h
    ccf
    ld c, h
    ld c, a
    ld c, e
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
    ld a, $49
    ld d, h
    ld a, $56
    ld d, b
    ld h, d
    ld bc, $ef5f
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld c, a
    ld c, h
    ld d, d
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld a, $49
    ld c, c
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
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld h, d
    ld bc, $fa5f
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    rst $28
    xor $4f
    ld b, [hl]
    ld d, b
    ld c, b
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld b, e
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
    ld a, [$eff7]
    xor $4c
    ld c, e
    ld b, d
    ld h, d
    ld c, l
    ld a, $46
    ld c, a
    ld h, d
    ld a, $51
    ld h, d
    ld a, $ef
    xor $51
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, c
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld c, d
    ld a, $49
    ld b, d
    ld d, b
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld b, e
    ld b, d
    ld c, d
    ld a, $49
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $40
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
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
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $4a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $41
    ld b, [hl]
    ld d, b
    ld a, $4d
    ld c, l
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, h
    ld b, d
    ld c, e
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
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3e
    ld c, e
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, b
    ld d, d
    ld c, c
    ld d, c
    ld a, $4b
    ld d, c
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
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $45
    ld b, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld a, [$eff7]
    xor $46
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    ld b, b
    ld d, d
    ld d, c
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
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
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
    ld l, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4b
    ld a, $4a
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $f6
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $f6
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld d, b
    ld d, d
    ld c, c
    ld d, c
    ld a, $4b
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $31
    ld b, [hl]
    ld b, b
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld h, l
    ld b, d
    ld d, e
    ld a, $49
    ld d, d
    ld a, $51
    ld b, d
    ld h, l
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld a, $51
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $4d
    ld c, c
    ld a, $40
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
    ld c, e
    ld b, c
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    rst $28
    xor $4c
    ld d, d
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
    ld d, h
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $48
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ccf
    ld a, $3f
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_044_6586

    ld h, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld b, a
    ld c, h
    ccf
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld h, l
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, l
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
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
    xor $9f
    and e
    ld a, [hl+]
    ld c, h

jr_044_6586:
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, h
    ld h, d
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld b, b
    ld a, $4b
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
    ld a, [hl+]
    ld b, d
    ld c, e
    ld b, c
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
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    rst $28
    xor $3f
    ld c, h
    ld d, [hl]
    ld h, d
    ccf
    ld a, $3f
    ld b, [hl]
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $a3
    ld a, $4b
    ld b, c
    ld h, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    rst $28
    xor $44
    ld b, [hl]
    ld c, a
    ld c, c
    ld h, d
    ccf
    ld a, $3f
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $a3
    ld [hl], $42
    ld b, d
    ld e, [hl]
    ld h, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $2c
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
    ld h, e
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
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    daa
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, d
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld b, d
    ld d, b
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, d
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld d, c
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
    rst $28
    xor $49
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, b
    ld c, c
    ld c, h
    ld d, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld a, $51
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4f
    ld b, d
    ld a, $40
    ld b, l
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
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
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, c
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
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
    ld h, e
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
    ld [hl], $48
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
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
    ld a, [$eff7]
    xor $a3
    ld l, $46
    ld b, c
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld b, d
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    ld a, [$eff7]
    xor $4d
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    scf
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld d, c
    ld c, h
    ld h, d
    ld c, l
    ld b, [hl]
    ld b, b
    ld c, b
    ld h, d
    ld c, l
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld a, $4b
    ld b, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    ld c, l
    ld b, [hl]
    ld b, b
    ld c, b
    ld h, d
    ld d, c
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
    ld c, a
    rst $28
    xor $4c
    ld c, e
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
    xor $4d
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld e, [hl]
    ld h, d
    ld b, c
    ld c, h
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
    xor $4a
    ld d, [hl]
    ld h, d
    ld b, c
    ld a, $52
    ld b, h
    ld b, l
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, e
    ld h, h
    rst $28
    xor $36
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $62
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld e, [hl]
    ld a, [$eff7]
    xor $44
    ld b, d
    ld c, e
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    or [hl]
    ld h, d
    ld b, h
    ld c, a
    ld a, $40
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    rst $28
    xor $44
    ld b, [hl]
    ld c, a
    ld c, c
    ld h, e
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $45
    ld b, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $4d
    ld c, c
    ld a, $56
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $3c
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
    ld b, h
    ld c, h
    rst $28
    xor $50
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $42
    ld b, d
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld d, b
    ld b, l
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld a, [$eff7]
    xor $46
    ld c, e
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
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4d
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $4b
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
    ld h, d
    ld c, d
    ld a, $4b
    ld h, d
    ld c, h
    ld c, a
    ld h, d
    ld a, $62
    ld d, h
    ld c, h
    ld c, d
    ld a, $4b
    rst $28
    xor $32
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld c, h
    ld c, e
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
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
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld d, c
    ld d, d
    ccf
    ccf
    ld c, h
    ld c, a
    ld c, e
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, e
    rst $30
    ldh a, [$e9]
    ld h, b
    or $62
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    rst $28
    xor $46
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $41
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$3a]
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    inc h
    ld h, d
    scf
    ld b, [hl]
    ld c, e
    ld d, [hl]
    jr nc, jr_044_6a5e

    ld b, c
    ld a, $49
    ld h, e
    rst $28
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
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
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
    scf
    ld b, [hl]
    ld c, e
    ld d, [hl]
    jr nc, jr_044_6a9d

    ld b, c
    ld a, $49

jr_044_6a5e:
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
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
    rst $28
    xor $f7
    ldh a, [$37]
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
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $43
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
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld l, b
    ld a, [$eff7]
    xor $41
    ld c, a
    ld b, d

jr_044_6a9d:
    ld d, b
    ld d, b
    ld b, d
    ld d, b
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
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    jr nc, jr_044_6b29

    rst $28
    xor $25
    ld a, $3f
    ld d, [hl]
    ld e, [hl]
    ld h, d
    inc sp
    ld a, $4f
    ld d, c
    ld h, d
    ld bc, $f7fa
    rst $28
    xor $a3
    jr nc, jr_044_6b3e

    ld h, d
    ccf
    ld a, $3f
    ld d, [hl]
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    rst $28
    xor $54
    ld a, $50
    ld h, d
    ccf
    ld c, h
    ld c, a
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld [hl], $45
    ld b, d
    ld l, b
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld e, [hl]
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $37

jr_044_6b29:
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, e
    ld d, d
    ld b, d
    ld b, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d

jr_044_6b3e:
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
    xor $36
    ld c, h
    ld c, d
    ld b, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    ld a, $51
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    ld a, $ef
    xor $4f
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
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $f6
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $54
    ld a, $51
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld b, d
    ld d, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $44
    ld c, h
    ld c, e
    ld c, e
    ld a, $62
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $25
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $4b
    ld d, [hl]
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    dec h
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $24
    ld c, l
    ld c, l
    ld b, d
    ld a, $4f
    ld a, $4b
    ld b, b
    ld b, d
    ld d, b
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld b, [hl]
    ld d, b
    ld c, c
    ld b, d
    ld a, $41
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld a, $56
    ld e, [hl]
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $41
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $62
    ld c, a
    ld b, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld a, [$eff7]
    xor $4c
    ld c, e
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
    xor $9f
    and e
    inc l
    ld l, d
    ld h, d
    ld a, $49
    ld d, b
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $ef
    xor $4f
    ld b, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld h, d
    ld c, h
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
    inc l
    ld h, d
    ld b, b
    ld a, $4b
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
    ld a, [$eff7]
    xor $50
    ld d, c
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld e, a
    ld h, d
    ld h, $4c
    ld c, d
    ld b, d
    rst $28
    xor $53
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_044_6d4b

    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld b, e
    ld b, d
    ld d, b
    ld d, b
    ld c, h
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3e
    ld h, d
    ld b, h
    ld b, d
    ld c, e
    ld b, [hl]
    ld d, d
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $45
    ld a, $4b
    ld b, c
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld b, e
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
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $49
    ld b, d
    ld b, b
    ld d, c
    ld d, d

jr_044_6d4b:
    ld c, a
    ld b, d
    ld e, [hl]
    rst $28
    xor $50
    ld d, c
    ld c, h
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, e
    rst $30
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
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld [hl], $40
    ld b, l
    ld c, h
    ld c, h
    ld c, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld c, h
    ld b, c
    ld a, $56
    ld l, b
    ld h, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    rst $28
    xor $46
    ld d, b
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
    xor $40
    ld b, l
    ld a, $4f
    ld a, $40
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld d, b
    ld h, d
    ld c, h
    ld b, e
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
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, d
    ld d, b
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld a, $51
    ld b, b
    ld b, l
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
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, h
    rst $38
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
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $46
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld h, e
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld b, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld a, [hl+]
    ld b, [hl]
    ld d, e
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
    rst $28
    xor $4a
    ld b, d
    ld a, $51
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, d
    ld a, $50
    ld b, [hl]
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld a, $4a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    rst $28
    xor $42
    ld d, l
    ld c, l
    ld b, d
    ld c, e
    ld d, b
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, a
    ld b, d
    ld a, $51
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $46
    ld d, c
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    inc l
    ld b, e
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $42
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld e, [hl]
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld a, [$eff7]
    xor $51
    ld d, h
    ld c, h
    ld h, d
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc l
    ld c, d
    ld c, l
    ld c, h
    ld c, a
    ld d, c
    ld a, $4b
    ld d, c
    ld h, e
    rst $28
    xor $2e
    ld c, e
    ld c, h
    ld b, b
    ld c, b
    ld h, d
    ld c, h
    ld d, d
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
    xor $49
    ld a, $50
    ld d, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    rst $28
    xor $4f
    ld b, d
    ld b, b
    ld b, d
    ld d, b
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
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
    ld a, [$eff7]
    xor $2a
    ld a, $51
    ld b, d
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
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld b, h
    ld a, $51
    ld b, d
    ld d, b
    rst $28
    xor $42
    ld d, l
    ld b, [hl]
    ld d, b
    ld d, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
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
    xor $9f
    and e
    jr z, jr_044_701c

    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $4a
    ld a, $56
    ccf
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld e, a
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
    ld b, d
    ld a, $50
    ld b, [hl]
    ld c, c
    ld d, [hl]
    rst $28
    xor $43
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
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $4a
    ld b, [hl]
    ld d, b
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c

jr_044_701c:
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $43
    ld c, a
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, c
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
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
    ld a, [$eff7]
    xor $54
    ld b, l
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
    ld e, a
    ld e, a
    ld e, a
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4d
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $5f
    ld e, a
    ld e, a
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld c, h
    ld d, c
    ld d, b
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld c, d
    ld b, d
    ld a, $51
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
    ld e, a
    ld e, a
    ld e, a
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $5f
    ld e, a
    ld e, a
    ld b, [hl]
    ld c, d
    ld c, l
    ld c, a
    ld c, h
    ld d, e
    ld b, d
    ld h, d
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
    ld b, [hl]
    ld b, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, b
    ld b, d
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $44
    ld d, d
    ld a, $4f
    ld b, c
    ld b, [hl]
    ld a, $4b
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $54
    ld a, $46
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
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
    ld a, $51
    ld h, d
    ld b, h
    ld a, $51
    ld b, d
    ld h, h
    rst $30
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
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld d, d
    ld b, h
    ld d, b
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $3e
    ld c, a
    ld b, d
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
    xor $44
    ld a, $51
    ld b, d
    ld e, a
    ld a, [$eff7]
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
    ld b, d
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $41
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $44
    ld d, d
    ld a, $4f
    ld b, c
    ld b, [hl]
    ld a, $4b
    ld e, a
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
    xor $27
    ld b, d
    ld c, d
    ld c, h
    ld c, c
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, h
    rst $38
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
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    jr nc, jr_044_7262

    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $25
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
    dec h
    ld b, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]

jr_044_7262:
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
    jr nc, jr_044_72bc

    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, d
    or $5f
    rst $28
    xor $3a
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    jr nc, jr_044_72e1

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $37
    ld b, d
    ld d, c
    ld c, h
    ld e, a
    ld h, d
    daa
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, [hl]

jr_044_72bc:
    ld c, e
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld h, d
    ld c, d
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63

jr_044_72e1:
    rst $28
    xor $27
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld h, d
    ccf
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, e
    rst $30
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
    ccf
    ld a, $40
    ld c, b
    ld e, a
    rst $28
    xor $27
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $49
    ld c, h
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    ld h, d
    dec l
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld d, c
    ld c, a
    ld d, [hl]
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ccf
    ld b, d
    ld d, b
    ld d, c
    ld h, e
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
    ld e, a
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld l, c
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld d, b
    ld d, c
    ld d, b
    ld e, a
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
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
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $40
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4d
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld c, h
    ld c, a
    ld h, d
    ld b, d
    ld d, l
    ld a, $4a
    ld c, l
    ld c, c
    ld b, d
    ld e, [hl]
    rst $28
    xor $40
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $62
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $3e
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    or [hl]
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, d
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
    xor $4c
    ld d, c
    ld b, l
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
    jr nc, jr_044_7488

    ld c, b
    ld b, d
    ld d, b
    ld h, d
    ld a, $ef
    xor $27
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld l, $46
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $2a
    ld c, h
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $42
    ld d, l
    ld b, b
    ld b, d
    ld c, l
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b

jr_044_7488:
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
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
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
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
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    add hl, sp
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $62
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $3e
    ld c, c
    ld c, c
    ld c, h
    ld d, h
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
    ld b, [hl]
    ld c, e
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
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
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
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    ld a, [$eff7]
    xor $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld c, h
    ld b, h
    ld b, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $62
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
    ld c, c
    ld c, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, a
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld a, $4a
    ld b, d
    ld h, d
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4d
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld c, a
    ld b, d
    ld b, d
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
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $2b
    ld b, d
    ld a, $49
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
    inc h
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $3f
    ld c, h
    ld c, a
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld c, c
    ld b, d
    ld a, $4f
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld a, $49
    ld d, h
    ld a, $56
    ld d, b
    ld a, [$eff7]
    xor $42
    ld d, l
    ld b, b
    ld b, d
    ld c, l
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    ld e, a
    rst $28
    xor $f7
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
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e

jr_044_7651:
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    jr z, jr_044_7651

    rst $30
    rst $28
    xor $40
    ld c, c
    ld a, $50
    ld d, b
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
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
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
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    or $63
    rst $28
    xor $27
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, l
    ld d, d
    ld b, l
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    scf
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
    rst $28
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
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
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
    rst $28
    xor $30
    ld b, d
    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $25
    ld b, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $4f
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
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
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld a, $4f
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
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
    xor $25
    ld c, a
    ld a, $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    daa
    ld b, d
    ld d, b
    ld c, l
    ld a, $46
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $ef
    xor $4d
    ld a, $4f
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, l
    ld c, h
    ld c, l
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2b
    ld c, h
    ld c, l
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, d
    ld c, d
    ccf
    ld b, d
    ld b, c
    ld b, c
    ld b, d
    ld b, c
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld b, c
    ld b, d
    ld d, b
    ld c, l
    ld a, $46
    ld c, a
    ld h, e
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
    rst $28
    xor $2b
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld h, d
    ld a, [hl-]
    ld a, $56
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $32
    ld d, e
    ld b, d
    ld c, a
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $27
    ld b, d
    ld d, b
    ld c, l
    ld a, $46
    ld c, a
    ld e, a
    rst $30
    ldh a, [$eb]
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld a, $4f
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
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
    xor $33
    ld b, d
    ld a, $40
    ld b, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    daa
    ld b, [hl]
    ld d, b
    ld b, b
    ld c, a
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, h
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
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $4f
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $53
    ld a, $49
    ld c, h
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
    ld a, $4b
    ld b, h
    ld b, d
    ld c, a
    ld h, e
    ld h, d
    daa
    ld c, h
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $51
    ld a, $49
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $48
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4a
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld b, d
    ld d, [hl]
    ld h, e
    ld h, e
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
    rst $28
    xor $30
    ld a, $48
    ld b, d
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    jr nc, jr_044_78e2

    ld c, e
    ld b, d
    ld d, [hl]
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld c, h
    ld d, h
    ld e, a
    rst $28
    xor $f7
    ldh a, [$e9]
    ld h, b
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
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, l
    ld a, $40
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $41
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    ld b, d
    ld d, b
    ld h, e

jr_044_78e2:
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld c, e
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld c, a
    ld c, d
    ld c, h
    ld d, d
    ld d, b
    rst $28
    xor $52
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld b, h
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $41
    ld d, d
    ld c, e
    ld b, h
    ld b, d
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld b, e
    ld b, d
    ld a, $4f
    ld h, d
    ld c, l
    ld b, [hl]
    ld d, c
    ld b, e
    ld a, $49
    ld c, c
    ld d, b
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld b, d
    ld c, l
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    inc l
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    rst $28
    xor $4a
    ld a, $48
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, h
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
    ld c, l
    ld b, [hl]
    ld b, d
    ld b, b
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $24
    ld h, d
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $2f
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, c
    ld c, b
    ld b, [hl]
    ld a, $5f
    rst $30
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
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld a, $51
    ld h, d
    dec h
    ld b, [hl]
    ld b, h
    jr z, @+$58

    ld b, d
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
    xor $25
    ld b, [hl]
    ld b, h
    jr z, jr_044_7a2e

    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld b, e
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $49
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
    ld [hl-], a
    ld b, l
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld a, [$eff7]
    xor $45
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
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
    ld h, d
    ld b, e

jr_044_7a2e:
    ld c, h
    ld c, a
    ld b, h
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $3f
    ld c, h
    ld d, b
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
    rst $28
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, e
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
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
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $49
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
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
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    rst $28
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
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
    ld [hl], $4c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, h
    ld a, $50
    ld d, c
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
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
    rst $28
    xor $50
    ld a, $53
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, h
    ld c, h
    ld c, c
    ld b, c
    ld h, e
    ld h, e
    rst $30
    ldh a, [$f6]
    ld h, d
    ld b, b
    ld b, l
    ld b, d
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld d, d
    ld b, e
    ld b, e
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, [hl]
    ld c, d
    ld a, $49
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $37
    ld b, l
    ld b, d
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
    rst $28
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld a, $4f
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
    or $ef
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld a, $51
    ld a, [$eff7]
    xor $29
    ld a, $4b
    ld b, h
    ld [hl], $49
    ld b, [hl]
    ld c, d
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
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld b, [hl]
    ld c, e
    ld c, h
    ld h, h
    ld h, d
    daa
    ld b, [hl]
    ld b, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
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
    jr nc, jr_044_7c3a

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $2a
    ld c, h
    ld c, c
    ld b, c
    ld h, h
    ld h, d
    inc l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, a
    ld d, c
    ld b, l
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld l, b
    ld h, d
    ld a, $ef
    xor $4f
    ld b, d
    ld a, $50
    ld c, h
    ld c, e
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c

jr_044_7c3a:
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
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $49
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    cpl
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld a, $44
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $24
    ld c, e
    ld h, d
    ld a, $4b
    ld b, b
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
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
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
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
    xor $51
    ld c, h
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld d, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld b, l
    ld d, d
    ld c, d
    ld a, $4b
    ld d, b
    rst $28
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld d, d
    ld c, a
    ld h, d
    ld a, $4b
    ld b, b
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, b
    rst $28
    xor $41
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $45
    ld b, d
    ld c, c
    ld b, c
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
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
    inc l
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
    ld h, d
    ld b, [hl]
    ld b, e
    rst $28
    xor $46
    ld d, c
    ld l, b
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    ld e, a
    ld h, d
    dec h
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, d
    rst $28
    xor $45
    ld c, h
    ld c, c
    ld b, c
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
    xor $f7
    ldh a, [$ea]
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
    rst $28
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
    ld e, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld e, [hl]
    ld a, [$eff7]
    xor $44
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
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
    xor $53
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, d
    ld c, l
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld a, $4f
    ld d, b
    ld h, d
    ld c, h
    ld c, e
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
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $54
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld a, [hl+]
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
    cpl
    ld c, h
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, h
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    rst $28
    xor $3f
    ld a, $3f
    ld b, [hl]
    ld b, d
    ld b, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld h, $3e
    ld c, e
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld a, [$eff7]
    xor $46
    ld d, c
    ld h, d
    ld d, c
    ld c, h
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
    ld h, h
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
