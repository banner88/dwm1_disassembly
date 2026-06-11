; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $046", ROMX[$4000], BANK[$46]

    db $46 ; Bank number

    ; Cross-bank dispatch table (148 entries)
    ; Called via: ld hl, $46XX / rst $10
    dw LoadB46_4129                  ; Entry 0
    dw $4146                          ; Entry 1
    dw $4163                          ; Entry 2
    dw $4009                          ; Entry 3
    dw $4180                          ; Entry 4
    dw $41BB                          ; Entry 5
    dw $41F5                          ; Entry 6
    dw $4231                          ; Entry 7
    dw $4292                          ; Entry 8
    dw $42D5                          ; Entry 9
    dw $4308                          ; Entry 10
    dw $4359                          ; Entry 11
    dw $43A5                          ; Entry 12
    dw $43D9                          ; Entry 13
    dw $442A                          ; Entry 14
    dw $44A4                          ; Entry 15
    dw $44D1                          ; Entry 16
    dw $456E                          ; Entry 17
    dw $45BD                          ; Entry 18
    dw $4671                          ; Entry 19
    dw $4760                          ; Entry 20
    dw $47D2                          ; Entry 21
    dw $4835                          ; Entry 22
    dw $4859                          ; Entry 23
    dw $487F                          ; Entry 24
    dw $4937                          ; Entry 25
    dw $4988                          ; Entry 26
    dw $499D                          ; Entry 27
    dw $49CF                          ; Entry 28
    dw $4B14                          ; Entry 29
    dw $4B2E                          ; Entry 30
    dw $4C3E                          ; Entry 31
    dw $4C7B                          ; Entry 32
    dw $4D47                          ; Entry 33
    dw $4DAA                          ; Entry 34
    dw $4E3D                          ; Entry 35
    dw $4F14                          ; Entry 36
    dw $4F38                          ; Entry 37
    dw $4F85                          ; Entry 38
    dw $4FCF                          ; Entry 39
    dw $500E                          ; Entry 40
    dw $504E                          ; Entry 41
    dw $5064                          ; Entry 42
    dw $5083                          ; Entry 43
    dw $50D1                          ; Entry 44
    dw $50F1                          ; Entry 45
    dw $5126                          ; Entry 46
    dw $517C                          ; Entry 47
    dw $5191                          ; Entry 48
    dw $5250                          ; Entry 49
    dw $530C                          ; Entry 50
    dw $53A3                          ; Entry 51
    dw $53BF                          ; Entry 52
    dw $5410                          ; Entry 53
    dw $5462                          ; Entry 54
    dw $548F                          ; Entry 55
    dw $5531                          ; Entry 56
    dw $5562                          ; Entry 57
    dw $55C4                          ; Entry 58
    dw $5667                          ; Entry 59
    dw $5717                          ; Entry 60
    dw $5738                          ; Entry 61
    dw $579D                          ; Entry 62
    dw $5802                          ; Entry 63
    dw $5888                          ; Entry 64
    dw $58CD                          ; Entry 65
    dw $5994                          ; Entry 66
    dw $5A12                          ; Entry 67
    dw $5A9F                          ; Entry 68
    dw $5AF2                          ; Entry 69
    dw $5BA3                          ; Entry 70
    dw $5C74                          ; Entry 71
    dw $5CBD                          ; Entry 72
    dw $5D21                          ; Entry 73
    dw $5D41                          ; Entry 74
    dw $5DC6                          ; Entry 75
    dw $5E21                          ; Entry 76
    dw $5E4B                          ; Entry 77
    dw $5E7A                          ; Entry 78
    dw $5EDB                          ; Entry 79
    dw $5F05                          ; Entry 80
    dw $5F3E                          ; Entry 81
    dw $5FA0                          ; Entry 82
    dw $5FF3                          ; Entry 83
    dw $60E5                          ; Entry 84
    dw $6188                          ; Entry 85
    dw $61B1                          ; Entry 86
    dw $61F9                          ; Entry 87
    dw $62E7                          ; Entry 88
    dw $632D                          ; Entry 89
    dw $6365                          ; Entry 90
    dw $639D                          ; Entry 91
    dw $63D6                          ; Entry 92
    dw $6432                          ; Entry 93
    dw $648D                          ; Entry 94
    dw $64FC                          ; Entry 95
    dw $6521                          ; Entry 96
    dw $6597                          ; Entry 97
    dw $6609                          ; Entry 98
    dw $6677                          ; Entry 99
    dw $66A8                          ; Entry 100
    dw $6718                          ; Entry 101
    dw $6746                          ; Entry 102
    dw $680E                          ; Entry 103
    dw $6846                          ; Entry 104
    dw $6902                          ; Entry 105
    dw $69C7                          ; Entry 106
    dw $6A2F                          ; Entry 107
    dw $6AAD                          ; Entry 108
    dw $6B0B                          ; Entry 109
    dw $6BA1                          ; Entry 110
    dw $6C63                          ; Entry 111
    dw $6CC8                          ; Entry 112
    dw $6D33                          ; Entry 113
    dw $6D7B                          ; Entry 114
    dw $6DED                          ; Entry 115
    dw $6E26                          ; Entry 116
    dw $6E9B                          ; Entry 117
    dw $6F0B                          ; Entry 118
    dw $6F4B                          ; Entry 119
    dw $6FAF                          ; Entry 120
    dw $701C                          ; Entry 121
    dw $7081                          ; Entry 122
    dw $70E1                          ; Entry 123
    dw $711A                          ; Entry 124
    dw $728B                          ; Entry 125
    dw $72C5                          ; Entry 126
    dw $7350                          ; Entry 127
    dw $7443                          ; Entry 128
    dw $747D                          ; Entry 129
    dw $74EB                          ; Entry 130
    dw $751F                          ; Entry 131
    dw $758F                          ; Entry 132
    dw $75F9                          ; Entry 133
    dw $7659                          ; Entry 134
    dw $7708                          ; Entry 135
    dw $7840                          ; Entry 136
    dw $78AB                          ; Entry 137
    dw $78FF                          ; Entry 138
    dw $7984                          ; Entry 139
    dw $79FA                          ; Entry 140
    dw $7B1B                          ; Entry 141
    dw $7BB4                          ; Entry 142
    dw $7BC4                          ; Entry 143
    dw $7C70                          ; Entry 144
    dw $7CE5                          ; Entry 145
    dw $7D26                          ; Entry 146
    dw $7D5E                          ; Entry 147

LoadB46_4129:
    ld a, [$c823]
    cp $90
    jr c, jr_046_413f

    sub $90
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    ld hl, $1b00
    rst $10
    ret


jr_046_413f:
    ld de, $4007
    call CallTextEngine
    ret


    ld a, [$c823]
    cp $90
    jr c, jr_046_415c

    sub $90
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    ld hl, $1b01
    rst $10
    ret


jr_046_415c:
    ld de, $4007
    call RunTextHandler
    ret


    ld a, [$c823]
    cp $90
    jr c, jr_046_4179

    sub $90
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    ld hl, $1b02
    rst $10
    ret


jr_046_4179:
    call LoadB46_4129
    call RequestScreenUpdate
    ret


    db $eb
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld b, d
    ld b, e
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld a, [$eff7]
    xor $46
    ld d, c
    ld l, b
    ld h, d
    ld c, l
    ld a, $50
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $3f
    ld b, d
    ld b, c
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld c, e
    ld d, d
    ld b, b
    ld c, b
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld a, [$eff7]
    xor $2c
    ld l, d
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld a, $52
    ld d, c
    ld b, [hl]
    ld b, e
    ld d, d
    ld c, c
    rst $28
    xor $4f
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
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
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    rst $28
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
    ld d, h
    ld b, l
    ld c, h
    ld l, b
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld a, $4d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld b, d
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
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, l
    ld a, $53
    ld b, d
    ld a, [$eff7]
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
    rst $28
    xor $49
    ld a, $41
    ld b, [hl]
    ld b, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, c
    ld b, d
    ld a, $40
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld d, c
    ld h, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    jr z, jr_046_42d9

    ld b, d
    ld c, b
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $50
    ld d, c
    ld a, $4b
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld l, d
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld c, e
    ld a, $62
    ld d, c
    ld b, d
    ld a, $40
    ld b, l
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld a, $62
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld c, h
    ld c, e
    ld h, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a

jr_046_42d9:
    ld c, h
    ld d, d
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, e
    ld h, h
    rst $28
    xor $2c
    ld l, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld c, e
    ld a, $fa
    rst $30
    rst $28
    xor $44
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
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
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $62
    ccf
    ld a, $41
    ld h, d
    ld b, h
    ld d, d
    ld d, [hl]
    ld a, [$eff7]
    xor $3e
    ld b, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $49
    ld c, c
    ld e, a
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $3f
    ld b, d
    ld b, h
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
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
    inc l
    ld d, c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld h, e
    rst $28
    xor $30
    ld d, [hl]
    ld h, d
    dec h
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $40
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    rst $28
    xor $3e
    ld h, d
    ld h, $4c
    ld c, l
    ld d, [hl]
    ld h, $3e
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $31
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $3e
    ld b, b
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld h, $4c
    ld c, l
    ld d, [hl]
    ld h, $3e
    ld d, c
    ld h, e
    rst $28
    xor $31
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
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
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld c, e
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
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
    ld b, b
    ld a, $4b
    ld h, a
    rst $28
    xor $42
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ccf
    ld b, d
    ld a, $51
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $3f
    ld c, a
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld d, b
    ld h, h
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
    ld c, e
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld a, $ef
    xor $49
    ld c, h
    ld d, b
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    ld a, [$eff7]
    xor $26
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld c, c
    ld a, $51
    ld b, d
    ld c, a
    rst $28
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec [hl]
    ld b, d
    ld a, $41
    ld d, [hl]
    ld h, e
    rst $28
    xor $35
    ld c, h
    ld b, b
    ld c, b
    sbc h
    inc sp
    ld a, $4d
    ld b, d
    ld c, a
    sbc h
    ld a, [$eff7]
    xor $36
    ld b, b
    ld b, [hl]
    ld d, b
    ld d, b
    ld c, h
    ld c, a
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld a, [hl+]
    ld c, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld e, a
    ld e, a
    ld e, a
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $4c
    ld c, e
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld c, b
    ld b, [hl]
    ld b, c
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld c, b
    ld a, $56
    ld e, a
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld c, e
    ld a, $ef
    xor $44
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $62
    ld c, l
    ld c, a
    ld b, [hl]
    ld d, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
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
    ld c, d
    ld d, [hl]
    rst $28
    xor $3f
    ld c, a
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4c
    ld c, d
    ld b, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld a, $63
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
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
    ld c, d
    ld d, [hl]
    rst $28
    xor $3f
    ld c, a
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld d, b
    ld h, e
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
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld a, $63
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_046_4600

    ld d, [hl]
    ld h, d
    inc l
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
    xor $f6
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $4f
    ld d, d
    ld c, d
    ld c, h
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
    ld d, c
    ld b, d
    ld c, a
    ld c, a
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    rst $28
    xor $4a
    ld a, $50
    ld d, c

jr_046_4600:
    ld b, d
    ld c, a
    ld h, d
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld c, a
    ld d, [hl]
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
    ld h, e
    ld a, [$eff7]
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
    ld h, d
    ld b, l
    ld a, $50
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
    ld a, $51
    ld h, d
    ld c, e
    ld c, h
    ld a, [$eff7]
    xor $4c
    ld c, e
    ld b, d
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, e
    rst $28
    xor $3f
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    add hl, hl
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
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld c, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld d, b
    ld a, [$eff7]
    xor $4c
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
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld d, b
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $50
    rst $28
    xor $25
    ld c, c
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld b, c
    ld d, [hl]
    ld e, [hl]
    ld a, [$eff7]
    xor $2f
    ld a, $53
    ld a, $30
    ld a, $4b
    ld e, [hl]
    ld h, d
    inc l
    ld b, b
    ld b, d
    jr nc, jr_046_470f

    ld c, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc sp
    ld b, l
    ld c, h
    ld b, d
    ld c, e
    ld b, [hl]
    ld d, l
    ld e, [hl]
    ld h, d
    daa
    ld b, [hl]
    ld b, h
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $25
    ld c, h
    ld c, d
    ccf
    ld h, $4f
    ld a, $44
    ld e, [hl]
    ld h, d
    ld [hl-], a
    ld c, a
    ld c, h
    ld b, b
    ld b, l
    ld b, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    dec [hl]
    ld b, d
    ld d, l
    ld e, [hl]
    rst $28
    xor $26

jr_046_470f:
    ld b, l
    ld c, h
    ld c, l
    ld h, $49
    ld c, h
    ld d, h
    ld c, e
    ld e, [hl]
    ld a, [$eff7]
    xor $2a
    ld a, $51
    ld b, d
    ld a, [hl+]
    ld d, d
    ld a, $4f
    ld b, c
    ld e, [hl]
    rst $28
    xor $37
    ld c, a
    ld d, d
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
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
    rst $28
    xor $30
    ld b, d
    ld d, c
    ld a, $3f
    ccf
    ld c, c
    ld b, d
    ld e, [hl]
    ld h, d
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    ld l, $46
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $f7
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
    ld h, h
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
    jr nc, jr_046_47be

    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld c, e
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
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
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
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c

jr_046_47be:
    ld b, l
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
    ld h, d
    dec [hl]
    ld a, $56
    ccf
    ld d, d
    ld c, a
    ld c, e
    ld h, h
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, l
    ld d, d
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2c
    ld d, c
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ld h, e
    rst $28
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld c, b
    ld b, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld d, b
    ld c, e
    ld a, $4d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, h
    ld c, a
    ld b, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    inc bc
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
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
    ld b, [hl]
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, l
    ld d, d
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld b, d
    ld c, c
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $50
    ld c, l
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld a, $9c
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld l, $3e
    sbc h
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld b, d
    ld c, c
    ld d, b
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, l
    ld e, a
    ld a, [$eff7]
    xor $03
    ld h, d
    jr nc, @+$44

    ld d, c
    ld a, $49
    ld d, [hl]
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $46
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld d, b
    ld d, h
    ld b, d
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    ld a, [$eff7]
    xor $2d
    ld b, [hl]
    ld c, e
    ld b, h
    ld c, c
    ld b, d
    ld h, e
    ld h, d
    dec l
    ld b, [hl]
    ld c, e
    ld b, h
    ld c, c
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f6
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    ld h, d
    ld bc, $0000
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, [hl+]
    ld c, h
    ld c, c
    ld b, c
    ld h, e
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, l
    ld d, d
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    rst $28
    xor $51
    ld d, d
    ld c, a
    ld c, e
    ld e, a
    ld h, d
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld c, a
    ld d, d
    ld d, b
    ld d, c
    ld b, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [$2c]
    ld d, c
    ld l, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, h
    ld c, a
    ld b, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$03]
    ld h, d
    jr nc, jr_046_49e3

    ld d, c
    ld a, $49
    ld d, [hl]
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $50
    ld d, h
    ld b, d
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, l
    ld d, d
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld c, d
    ld h, d
    ld c, h
    ld b, e

jr_046_49e3:
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld b, d
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld c, l
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld a, [$eff7]
    xor $40
    ld c, a
    ld a, $57
    ld d, [hl]
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $5f
    ld e, a
    ld e, a
    ld h, d
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $2e
    sbc h
    ld b, b
    ld b, l
    ld d, d
    ld c, e
    ld c, b
    ld h, e
    ld h, d
    ld l, $9c
    ld b, b
    ld b, l
    ld d, d
    ld c, e
    ld c, b
    ld h, e
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld b, d
    ld c, c
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, l
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $31
    ld c, h
    ld e, [hl]
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, l
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2a
    ld d, h
    ld a, $9c
    ld h, $45
    ld d, d
    ld c, e
    ld c, b
    ld h, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f6
    ld h, d
    ccf
    ld a, $4b
    ld b, h
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2e
    sbc h
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld l, $9c
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld d, c
    ld d, b
    rst $28
    xor $4c
    ld d, d
    ld d, c
    ld h, d
    ld b, b
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, b
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $f6
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    ld h, d
    ld [bc], a
    nop
    nop
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, [hl+]
    ld c, h
    ld c, c
    ld b, c
    ld h, e
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld b, d
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld c, l
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, l
    ld d, d
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld b, d
    ld c, c
    ld d, b
    rst $28
    xor $50
    ld c, l
    ld b, [hl]
    ld c, e
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld b, d
    ld d, c
    ld c, c
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, l
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $36
    ld c, l
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $f6
    ld l, b
    ld h, d
    ld b, d
    ld d, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $50
    ld c, c
    ld c, h
    ld d, h
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $52
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, l
    ld a, $40
    ld h, d
    ld d, b
    ld c, l
    ld c, h
    ld b, b
    ld h, d
    ld d, b
    ld c, l
    ld a, $40
    ld h, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f6
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $47
    ld a, $40
    ld c, b
    ld c, l
    ld c, h
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $2d
    ld b, [hl]
    ld c, e
    ld b, h
    ld c, c
    ld b, d
    ld h, d
    dec l
    ld b, [hl]
    ld c, e
    ld b, h
    ld c, c
    ld b, d
    rst $28
    xor $2d
    ld b, [hl]
    ld c, e
    ld b, h
    ld c, c
    ld b, d
    ld h, d
    dec l
    ld b, [hl]
    ld c, e
    ld b, h
    ld c, c
    ld b, d
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $3a
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    or $62
    ld b, h
    ld c, h
    ld d, c
    ld h, d
    dec b
    nop
    nop
    rst $28
    xor $46
    ld c, e
    ld h, d
    jr nc, jr_046_4c7c

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, [hl+]
    ld c, h
    ld c, c
    ld b, c
    ld h, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld a, $56
    ld h, h
    rst $28
    xor $3a
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
    ld a, [$eff7]
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
    rst $28
    xor $35
    ld a, $56
    ccf
    ld d, d
    ld c, a
    ld c, e
    ld h, h
    ldh a, [$eb]

jr_046_4c7c:
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ld d, c
    ld c, a
    ld d, [hl]
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4d
    ld b, [hl]
    ld b, b
    ld c, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $46
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, h
    ld b, d
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
    inc h
    ld c, e
    ld b, c
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld b, l
    ld c, h
    ld d, h
    ld e, [hl]
    rst $28
    xor $2c
    ld h, d
    ld c, b
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld c, d
    ld b, d
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, [hl]
    ld d, b
    ld b, l
    ld c, h
    ld c, l
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
    daa
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    rst $28
    xor $45
    ld b, d
    ld c, c
    ld c, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc l
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
    ld a, [$eff7]
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
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
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
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld d, [hl]
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld e, a
    ld a, [$eff7]
    xor $9f
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
    jr nc, @+$44

    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld a, $4f
    ld b, c
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld d, [hl]
    rst $28
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, e
    rst $30
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
    xor $34
    ld d, d
    ld b, d
    ld b, d
    ld c, e
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
    inc h
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld b, h
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld e, [hl]
    rst $28
    xor $30
    ld b, d
    ld b, c
    ld a, $49
    ld h, d
    jr nc, jr_046_4e2c

    ld c, e
    ld e, a
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
    xor $34
    ld d, d
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, e
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    rst $28
    xor $49

jr_046_4e2c:
    ld b, [hl]
    ld c, b
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
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    jr nc, @+$44

    ld b, c
    ld a, $49
    ld h, d
    jr nc, jr_046_4e89

    ld c, e
    ld e, [hl]
    rst $28
    xor $47
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld a, $62
    ld c, l
    ld a, $50
    ld d, b
    ld b, d
    ld c, a
    sbc h
    ccf
    ld d, [hl]
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
    inc l
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]

jr_046_4e89:
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
    dec h
    ld d, d
    ld d, c
    ld e, [hl]
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
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
    ccf
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld e, [hl]
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
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
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
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
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $27
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, h
    rst $28
    xor $ff
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
    xor $4f
    ld b, d
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld d, b
    ld d, c
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld h, e
    ld h, d
    inc h
    ld d, b
    ld h, d
    inc l
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld c, d
    ld b, [hl]
    ld d, b
    ld b, d
    ld b, c
    ld e, [hl]
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    add hl, hl
    ld a, $4b
    ld b, h
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld d, b
    ld b, [hl]
    ld b, h
    ld c, e
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld sp, $624c
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld d, b
    ld b, [hl]
    ld b, h
    ld c, e
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld sp, $624c
    ld c, l
    ld c, a
    ld c, h
    ld b, e
    ld b, d
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, h
    ld c, e
    ld a, $49
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
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
    ld a, $50
    ld b, [hl]
    ld c, e
    ld c, h
    ld h, e
    ld a, [$eff7]
    xor $2a
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    rst $28
    xor $43
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
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld c, h
    ld d, h
    ld l, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, h
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld c, e
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    rst $28
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld a, $51
    ld h, d
    ld b, b
    ld d, d
    ld d, b
    ld d, c
    ld c, h
    ld c, d
    ld b, d
    ld c, a
    rst $28
    xor $45
    ld a, $50
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $51
    ld d, c
    ld b, [hl]
    ld d, c
    ld d, d
    ld b, c
    ld b, d
    ld h, e
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
    ld b, c
    ld c, h
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
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $46
    ld d, c
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $624c
    ld d, e
    ld b, [hl]
    ld c, h
    ld c, c
    ld b, d
    ld c, e
    ld b, b
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
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld d, h
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld e, a
    ld e, a
    rst $28
    xor $37
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ld b, h
    ld a, $53
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld d, h
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld e, a
    ld e, a
    rst $28
    xor $3a
    ld b, l
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4c
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld d, [hl]
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl+]
    ld b, [hl]
    ld c, d
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, h
    ld c, h
    ld c, c
    ld b, c
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $51
    ld c, a
    ld d, d
    ld d, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld c, d
    ld b, d
    ld e, [hl]
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
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
    rst $28
    xor $3e
    ld b, c
    ld d, e
    ld b, [hl]
    ld b, b
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_046_5216

    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $ef
    xor $4d
    ld c, a
    ld b, d
    ld b, b
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
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
    ld a, [hl+]
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

jr_046_5216:
    ld b, d
    ld h, d
    ld a, $51
    ld a, [$eff7]
    xor $51
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $54
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_046_5297

    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $ef
    xor $4d
    ld c, a
    ld b, d
    ld b, b
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
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
    ld a, [hl+]
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

jr_046_5297:
    ld b, d
    ld h, d
    ld a, $51
    ld a, [$eff7]
    xor $51
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $54
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, e
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
    rst $28
    xor $4d
    ld c, a
    ld c, h
    ccf
    ld c, c
    ld b, d
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld a, $51
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    or $63
    ld h, d
    scf
    ld b, l
    ld a, $4b
    ld c, b
    ld d, b
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, b
    ld a, $53
    ld b, [hl]
    ld c, e
    ld b, h
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
    inc h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
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
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld [hl], $51
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld a, $4b
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    rst $28
    xor $4a
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    or $63
    rst $30
    ldh a, [$ea]
    sbc a
    dec hl
    ld b, d
    ld c, c
    ld c, c
    ld c, h
    ld h, d
    or $63
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $42
    ld d, l
    ld c, l
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    inc l
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    rst $28
    xor $4b
    ld b, d
    ld c, a
    ld d, e
    ld c, h
    ld d, d
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $49
    ld b, d
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld b, h
    ld b, [hl]
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
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
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    cpl
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld b, h
    ld b, [hl]
    ld c, e
    rst $28
    xor $3f
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    inc l
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld a, [$eff7]
    xor $3f
    ld d, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    ld b, e
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, e
    ld h, e
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
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld c, h
    ld b, e
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
    xor $3a
    ld b, [hl]
    ld d, b
    ld b, c
    ld c, h
    ld c, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
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
    xor $4a
    ld b, d
    ld b, d
    ld d, c
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
    ld e, [hl]
    ld a, [$eff7]
    xor $56
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
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $46
    ld d, c
    ld d, b
    ld h, d
    ld b, l
    ld a, $3f
    ld b, [hl]
    ld d, c
    ld d, b
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
    xor $35
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
    ld a, [$eff7]
    xor $2d
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
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
    jr nc, jr_046_5568

    ld c, a
    ld d, [hl]
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
    xor $2d
    ld c, h
    ld d, [hl]
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    inc h
    ld h, d
    ccf

jr_046_5568:
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, e
    ld d, b
    rst $28
    xor $3e
    ld h, d
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld d, c
    ld a, $44
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld c, l
    ld c, h
    ld b, d
    ld c, d
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld b, l
    ld b, [hl]
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
    ld b, d
    ld d, l
    ld c, h
    ld d, c
    ld b, [hl]
    ld b, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc h
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
    rst $28
    xor $50
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $4a
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
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
    ld d, b
    rst $28
    xor $49
    ld b, [hl]
    ld d, e
    ld b, d
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $45
    ld b, d
    ld a, $4f
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
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
    xor $41
    ld b, [hl]
    ld a, $4f
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $62
    ld c, c
    ld c, h
    ld b, h
    ld b, h
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
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
    ld e, [hl]
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
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
    ld a, [$eff7]
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
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $4c
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $62
    ld b, b
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, d
    ld c, e
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    rst $28
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
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    scf
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $f6
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld d, b
    ld h, d
    ld d, b
    ld c, d
    ld a, $4f
    ld d, c
    ld h, d
    ld a, $50
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld d, h
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, h
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, l
    ld a, $49
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld a, $51
    ld h, d
    ld c, d
    ld a, $4b
    ld h, d
    ld a, $49
    ld d, h
    ld a, $56
    ld d, b
    rst $28
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld d, d
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
    dec hl
    ld b, d
    ld l, b
    ld h, d
    ld a, $40
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    rst $28
    xor $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $2c
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
    ld d, [hl]
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
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
    ld e, [hl]
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
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
    rst $28
    xor $29
    ld d, d
    ld c, e
    ld c, b
    ld d, [hl]
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    add hl, hl
    ld d, d
    ld c, e
    ld c, b
    ld d, [hl]
    ld h, d
    or $fa
    rst $30
    rst $28
    xor $43
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
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
    ld e, [hl]
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
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
    rst $28
    xor $27
    ld b, [hl]
    ld b, h
    ld d, b
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
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $45
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld a, $62
    ld d, e
    ld c, h
    ld b, [hl]
    ld b, b
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, h
    ld c, b
    ld a, $56
    ld h, h
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
    ld d, d
    ld c, d
    ld c, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $45
    ld b, d
    ld a, $41
    ld h, h
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
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
    ld d, h
    ld c, h
    ld c, e
    rst $28
    xor $26
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, h
    ld h, d
    ld [hl], $45
    ld c, h
    ld c, h
    ld e, [hl]
    ld a, [$eff7]
    xor $50
    ld b, l
    ld c, h
    ld c, h
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld c, e
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld e, a
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
    ld h, $62
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $2a
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
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, d
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
    ld [hl-], a
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
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
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    dec h
    ld c, a
    ld a, $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    ld d, c
    ld a, $62
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    ld h, $52
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld h, d
    jr nc, jr_046_5a01

    ld d, c
    ld a, $49
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $49
    ld b, d
    ld a, $4f
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    ld a, [$eff7]
    xor $35
    ld c, h
    ld d, d
    ld b, h
    ld b, d
    ld sp, $5146
    ld b, d
    ld e, [hl]
    rst $28
    xor $25
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    dec [hl]
    ld b, d
    ld d, l
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e

jr_046_5a01:
    ld a, $4b
    ld b, c
    ld h, d
    inc h
    ld c, e
    ld d, c
    ld b, d
    ld a, $51
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f7
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
    xor $51
    ld b, d
    ld b, b
    ld b, l
    ld c, e
    ld b, [hl]
    ld c, [hl]
    ld d, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, b
    ld a, $4b
    ld a, [$eff7]
    xor $4d
    ld a, $4f
    ld a, $49
    ld d, [hl]
    ld d, a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $3e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld d, b
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $45
    ld a, $4a
    ld b, d
    ld c, c
    ld b, h
    ld c, h
    ld c, e
    ld e, [hl]
    rst $28
    xor $26
    ld a, $40
    ld d, c
    ld b, [hl]
    dec h
    ld a, $49
    ld c, c
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $30
    ld d, d
    ld c, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld a, $4b
    ld b, h
    ld b, d
    ld e, a
    rst $28
    xor $30
    ld d, [hl]
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    inc h
    ld b, [hl]
    ld c, a
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
    jr nc, jr_046_5b15

    ld d, [hl]
    ccf
    ld b, d
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $44
    ld b, d
    ld d, c
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, d
    ld c, h
    ld c, c
    ld b, c
    ld h, e
    ld h, h
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
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld b, c
    ld h, d
    dec h
    ld h, d
    ld b, b
    ld c, c
    ld a, $50

jr_046_5b15:
    ld d, b
    ld h, e
    ld a, [$eff7]
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
    ld a, [$eff7]
    xor $2b
    ld a, $4d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    or [hl]
    rst $28
    xor $37
    ld b, d
    ld c, d
    ld c, l
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
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
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
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
    ld d, h
    ld a, $46
    ld d, c
    ld d, b
    ld h, d
    ld d, [hl]
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
    ld c, c
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld b, c
    ld h, d
    dec h
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, e
    ld a, [$eff7]
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
    ld a, [$eff7]
    xor $2b
    ld a, $4d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    or [hl]
    rst $28
    xor $37
    ld b, d
    ld c, d
    ld c, l
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
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
    rst $28
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
    ld a, [$eff7]
    xor $43
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
    ld d, h
    ld a, $46
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $30
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
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld c, d
    ld a, $4b
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld a, $52
    ld c, a
    ld a, $4b
    ld d, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    or $63
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld a, $56
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    ld e, a
    ld h, d
    ld [hl], $3e
    ld d, [hl]
    ld e, [hl]
    rst $28
    xor $2f
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
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
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $28
    ld d, [hl]
    ld b, d
    ld b, c
    ld b, d
    ld c, a
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    inc l
    ld l, d
    ld h, d
    ld d, c
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
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $624c
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld b, c
    ld a, $56
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld e, [hl]
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
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, [hl+]
    ld c, h
    ld c, c
    ld b, c
    ld e, a
    rst $28
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld e, a
    ld e, a
    ld e, a
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
    ld a, $4a
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $49
    ld c, c
    ld h, e
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
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
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld a, $62
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld b, [hl]
    ld c, e
    ld c, h
    ld h, h
    rst $28
    xor $37
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
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
    ld e, a
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
    ld a, $63
    rst $28
    xor $2c
    ld h, d
    ld c, d
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
    xor $50
    ld c, d
    ld d, d
    ld b, h
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
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld d, h
    ld a, $56
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
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $ef
    xor $26
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    cpl
    ld a, $4a
    ld c, l
    ld h, e
    ld h, d
    ld sp, $503e
    ld d, c
    ld d, [hl]
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
    ld h, d
    ld b, e
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
    ld e, a
    ld a, [$eff7]
    xor $2b
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    ld a, [$f0f7]
    db $eb
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $ef
    xor $27
    jr z, jr_046_5f13

    ld d, b
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
    inc l
    ld l, d
    ld h, d
    ld d, b
    ld a, $51
    ld b, [hl]
    ld d, b
    ld b, e
    ld b, [hl]
    ld b, d

jr_046_5f13:
    ld b, c
    ld e, a
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
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $44
    ld b, d
    ld d, c
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    scf
    ld b, l
    ld a, $51
    ld l, b
    rst $28
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, e
    ld h, d
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld d, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld d, [hl]
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
    ld h, d
    ld b, e
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
    ld e, a
    ld a, [$eff7]
    xor $2b
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    ld a, [$f0f7]
    or $62
    ld c, a
    ld b, d
    ld a, $41
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld c, c
    ld a, $40
    ld c, b
    ccf
    ld c, h
    ld a, $4f
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, b
    ld b, [hl]
    ld c, l
    ld a, $49
    rst $28
    xor $45
    ld b, [hl]
    ld b, c
    ld b, d
    ld d, b
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld a, $49
    ld b, c
    ld a, [$eff7]
    xor $45
    ld b, d
    ld a, $41
    ld h, d
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $45
    ld a, $51
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld d, h
    ld c, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld a, $4a
    ld b, d
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
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
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld a, $4a
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, [hl]
    rst $28
    xor $4f
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    inc l
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
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
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
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
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ccf
    ld c, h
    ld c, a
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld b, h
    ld d, d
    ld b, d
    ld d, b
    ld d, b
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
    ld b, d
    ld d, l
    ld b, b
    ld b, d
    ld c, l
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    ld h, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    inc [hl]
    ld d, d
    ld b, d
    ld b, d
    ld c, e
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
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
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
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
    xor $9f
    and e
    inc l
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
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
    ld b, b
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3a
    ld b, [hl]
    ld c, e
    ld b, h
    ld [hl], $49
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
    dec h
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $4b
    rst $28
    xor $32
    ld c, a
    ld b, b
    ld h, d
    ld c, h
    ld c, a
    ld h, d
    inc sp
    ld c, h
    ld c, a
    ld c, b
    ld h, h
    ld a, [$eff7]
    xor $29
    ld d, d
    ld c, e
    ld c, e
    ld d, [hl]
    ld h, h
    rst $28
    xor $f7
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
    ld e, [hl]
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
    ld c, h
    ld h, d
    ld d, [hl]
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
    ld b, [hl]
    ld c, e
    ld h, d
    dec h
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, h
    rst $38
    ldh a, [$ea]
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
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $4b
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
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld a, $52
    ld c, a
    ld a, $4b
    ld d, c
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
    ld a, $ef
    xor $30
    ld a, $41
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $51
    ld d, h
    ld c, h
    ld h, d
    inc h
    ld c, a
    ld c, d
    ld d, [hl]
    ld h, $4f
    ld a, $3f
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
    rst $28
    xor $30
    ld a, $41
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $40
    ld c, a
    ld a, $57
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    rst $28
    xor $3e
    ld h, d
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $2b
    inc sp
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld b, [hl]
    ld b, h
    dec h
    ld a, $4b
    ld b, h
    ld e, [hl]
    rst $28
    xor $2b
    ld b, d
    ld c, c
    ld c, c
    ccf
    ld c, c
    ld a, $50
    ld d, c
    ld a, [$eff7]
    xor $30
    ld d, d
    ld c, c
    ld d, c
    ld b, [hl]
    ld h, $52
    ld d, c
    ld e, a
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
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $54
    ld b, l
    ld a, $51
    ld h, d
    inc l
    ld h, d
    ld c, d
    ld b, d
    ld a, $4b
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld e, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, h
    ld b, d
    rst $28
    xor $44
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $4f
    ld b, d
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld d, c
    ld a, $3f
    ld c, c
    ld b, d
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld c, h
    ld h, d
    ld b, l
    ld c, h
    ld h, d
    ld b, l
    ld c, h
    ld h, e
    ld h, e
    rst $28
    xor $37
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $50
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld a, $49
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr z, jr_046_63f5

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
    ld d, h
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    dec hl
    ld c, h
    ld c, a
    ld c, b
    ld d, b
    ld e, [hl]
    ld h, d
    ld d, h
    ld b, d
    ld a, [$eff7]
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $25
    ld a, $41
    jr nc, jr_046_6413

    ld a, $51
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    dec hl
    ld c, d
    ld e, a
    ld h, d
    inc h
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $4b
    ld a, $4a
    ld b, d
    ld b, c
    ld h, d
    ld [hl], $3e
    ld c, e
    ld e, a
    ld e, a

jr_046_63f5:
    ld e, a
    ld a, [$eff7]
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
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f

jr_046_6413:
    and e
    ld d, c
    ld c, h
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld h, d
    ld a, $62
    ld c, e
    ld b, d
    ld d, h
    rst $28
    xor $44
    ld a, $51
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld a, $ef
    xor $3a
    ld b, [hl]
    ld c, e
    ld b, h
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, e
    ld h, d
    ld h, $52
    ld d, c
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld c, h
    ld c, a
    ld h, d
    ccf
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
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld e, a
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
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    ccf
    ld d, d
    ld d, c
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
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld b, b
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl+]
    ld b, d
    ld d, c
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, c
    ld h, d
    ld c, h
    ld b, e
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
    ld a, $4b
    ld b, c
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    ld c, c
    ld a, $51
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld [hl], $46
    ld c, a
    ld c, c
    ld c, h
    ld b, [hl]
    ld c, e
    ld e, a
    rst $28
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
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld e, [hl]
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
    xor $4a
    ld d, [hl]
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
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
    ld l, $46
    ld c, e
    ld b, h
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    rst $28
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $44
    ld b, [hl]
    ld a, $4b
    ld d, c
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
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
    xor $2d
    ld c, h
    ld d, [hl]
    ld h, d
    ld a, $4b
    ld b, c
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
    ld a, [hl-]
    ld b, [hl]
    ld d, b
    ld b, c
    ld c, h
    ld c, d
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
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    dec l
    ld c, h
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld c, h
    ld c, h
    ld c, h
    ld h, e
    ld h, d
    inc h
    ld b, l
    ld b, l
    ld b, l
    ld b, l
    ld h, e
    rst $28
    xor $3a
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4a
    ld h, d
    inc l
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    scf
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $64
    rst $28
    xor $3a
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, c
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld c, e
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $3e
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, l
    ld a, $40
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
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
    ld a, $44
    ld a, $46
    ld c, e
    ld h, h
    rst $28
    xor $2c
    ld h, d
    ld b, l
    ld c, h
    ld c, l
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    or $5e
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    rst $28
    xor $41
    ld c, h
    ld c, e
    ld h, a
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
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld a, $57
    ld a, $3e
    ld c, a
    ld h, d
    or [hl]
    ld h, d
    rst $28
    xor $36
    ld d, c
    ld a, $3f
    ld c, c
    ld b, d
    ld h, h
    ld a, [$eff7]
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
    ld b, e
    ld d, d
    ld c, e
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
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    daa
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
    ld h, d
    ld c, h
    ld b, e
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
    xor $2b
    ld a, $4d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, h
    rst $28
    xor $ff
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
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c

FuncB46_6755:
    ld c, h
    ld c, d
    rst $28
    xor $2c
    ld h, d
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $54
    ld a, $50
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
    xor $44
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $62
    ld d, b
    ld c, l
    ld b, d
    ld b, d
    ld b, b
    ld b, l
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $4c
    ld d, e
    ld b, d
    ld c, a
    ld d, h
    ld b, l
    ld b, d
    ld c, c
    ld c, d
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld a, [$eff7]
    xor $4d
    ld a, $50
    ld d, b
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld a, $49
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, [hl]
    ld d, c
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
    xor $3e
    ld c, e
    ld c, h
    ld c, e
    ld d, [hl]
    ld c, d
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld a, $62
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
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
    ld a, [$eff7]
    xor $4c
    ld b, e
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
    ld c, c
    ld b, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    cpl
    ld b, [hl]
    ld b, e
    ld b, d
    ld b, b
    ld c, h
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
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    rst $28
    xor $50
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld [hl], $42
    ld c, a
    ld d, e
    ld a, $4b
    ld d, c
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
    ccf
    ld c, h
    ld d, h
    ld b, d
    ld c, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $45
    ld b, d
    ld c, c
    ld c, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld d, c
    ld c, h
    ld h, d
    ld b, d
    ld c, e
    ld d, b
    ld c, c
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld d, d
    ld c, a
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $32
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $62
    ld c, d
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld c, h
    rst $28
    xor $40
    ld a, $4b
    ld h, d
    ld d, b
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld h, $45
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $32
    ld c, e
    ld b, d
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
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
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
    ld [hl], $54
    ld b, d
    ld b, d
    ld d, c
    ld a, [$eff7]
    xor $36
    ld c, d
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    ld e, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $49
    ld a, $50
    ld d, c
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
    cpl
    ld b, [hl]
    ld c, l
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
    ld b, d
    ld c, c
    ld c, l
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    cpl
    ld c, h
    ld d, b
    ld d, c
    ld e, a
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
    dec l
    ld a, $4a
    ld b, [hl]
    ld c, a
    ld d, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
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
    ld e, [hl]
    ld h, d
    ld b, e
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld c, d
    ld b, d
    ld a, $51
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, c
    ld a, $4a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    or $5e
    rst $28
    xor $24
    ld d, c
    ld h, d
    ld b, d
    ld a, $50
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $46
    ld b, c
    ld b, d
    ld a, $62
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $49
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $4d
    ld b, d
    ld c, h
    ld c, l
    ld c, c
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
    ld l, c
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
    ld e, a
    ld e, a
    ld e, a
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
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld b, d
    ld c, l
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld b, [hl]
    ld d, b
    ld d, c
    ld h, e
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
    ld b, [hl]
    ld b, c
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    ld h, e
    rst $28
    xor $2b
    ld b, d
    ld c, a
    ld b, d
    ld l, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    ld h, d
    sbc a
    ld l, $46
    ld d, b
    ld d, b
    sbc a
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
    ld [hl], $42
    ld c, a
    ld d, e
    ld a, $4b
    ld d, c
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
    ld c, a
    ld b, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, d
    ld c, d
    ld c, l
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $54
    ld b, d
    ld c, a
    ld b, d
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
    ld c, a
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld d, c
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld a, $50
    ld h, d
    ld c, l
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $50
    ld a, [$eff7]
    xor $30
    ld b, d
    ld b, h
    ld a, $30
    ld a, $44
    ld b, [hl]
    ld b, b
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
    ld e, [hl]
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
    ld [hl-], a
    ld c, a
    ld c, h
    ld b, b
    ld b, l
    ld b, [hl]
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
    ld c, d
    ld b, d
    ld a, $4b
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld l, h
    ld b, d
    ld h, d
    ld a, $49
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, c
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld bc, $0000
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
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    scf
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $f6
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld a, $50
    ld h, d
    inc l
    rst $28
    xor $45
    ld c, h
    ld c, l
    ld b, d
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld h, $4c
    ld c, c
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    rst $28
    xor $4a
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld d, [hl]
    ld c, l
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $4c
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
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
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $50
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld l, b
    rst $28
    xor $3e
    ld c, e
    ld b, b
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld l, b
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $52
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, c
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
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld e, [hl]
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
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $2a
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    cpl
    ld d, d
    ld b, b
    ld c, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    rst $28
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld d, b
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $49
    ld d, b
    ld c, h
    ld a, [$eff7]
    xor $4f
    ld c, h
    ld c, h
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
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
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $4f
    ld b, d
    ld c, c
    ld a, $51
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
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
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $25
    ld b, [hl]
    ld b, h
    scf
    ld c, a
    ld d, d
    ld c, e
    ld c, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld c, h
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $51
    ld c, a
    ld d, d
    ld d, c
    ld b, l
    ld e, [hl]
    ld h, d
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $45
    ld a, $50
    ld c, e
    ld h, a
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $52
    ld d, b
    ld h, d
    ld a, $5f
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    ld b, c
    ld b, d
    ld b, b
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, [hl]
    ld b, d
    ld a, $4f
    ld d, b
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld l, c
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
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    dec h
    ld a, $57
    ld a, $3e
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4f
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    ld h, d
    inc h
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, a
    ld b, c
    ld a, [$eff7]
    xor $50
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld a, $49
    ld d, h
    ld a, $56
    ld d, b
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld a, $62
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $3a
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld d, h
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    ld a, [$eff7]
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
    ld d, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ccf
    ld c, a
    ld a, $46
    ld c, e
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, d
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
    ld h, e
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, e
    ld h, d
    daa
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    rst $28
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
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
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $2a
    ld c, h
    ld c, h
    ld c, l
    ld b, [hl]
    ld e, [hl]
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
    xor $4f
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
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
    xor $25
    ld a, $57
    ld a, $3e
    ld c, a
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
    ld a, [$eff7]
    xor $4a
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
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    rst $28
    xor $4b
    ld c, h
    ld d, h
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld c, c
    ld c, h
    ld d, e
    ld b, d
    rst $28
    xor $43
    ld b, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld d, e
    ld a, $49
    ld d, b
    ld h, e
    ld h, d
    inc l
    ld l, d
    ld a, [$eff7]
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld d, h
    ld a, $4f
    ld b, c
    rst $28
    xor $51
    ld c, h
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
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, b
    ld a, $54
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    rst $28
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
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
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    rst $28
    xor $46
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
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
    rst $28
    xor $46
    ld d, c
    ld l, l
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $3f
    ld d, d
    ld d, b
    ld d, [hl]
    ld h, d
    ld b, e
    ld c, h
    ld c, a
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
    rst $30
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
    ld a, $51
    rst $28
    xor $54
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld d, b
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
    rst $28
    xor $40
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
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld b, l
    ld a, $50
    rst $28
    xor $4b
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c

FuncB46_707b:
    ld c, a
    ld d, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $5442
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $4c
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
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
    ld d, h
    ld b, l
    ld a, $51
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $644c
    ld h, e
    ld h, d
    inc a
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
    xor $3e
    ld h, d
    ld b, l
    ld b, d
    ld b, b
    ld c, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $62
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld c, e
    ld c, h
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $46
    ld c, a
    ld c, c
    ld c, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $51
    ld a, $50
    ld d, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld a, $51
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
    ld b, b
    ld a, $49
    ld c, c
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
    ld d, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld [hl], $45
    ld b, [hl]
    ld c, e
    ld d, [hl]
    dec hl
    ld a, $4f
    ld c, l
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
    ld h, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    ld h, d
    ld b, d
    ld b, e
    ld b, e
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld a, $50
    ld a, [$eff7]
    xor $50
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld a, $49
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld e, a
    rst $28
    xor $37
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld c, h
    ld c, c
    ld d, c
    ld [hl], $51
    ld a, $43
    ld b, e
    ld h, d
    or [hl]
    rst $28
    xor $25
    ld c, h
    ld c, c
    ld d, c
    ld e, [hl]
    ld a, [$eff7]
    xor $3a
    ld b, [hl]
    ld c, e
    ld b, c
    ld [hl], $51
    ld a, $43
    ld b, e
    ld h, d
    or [hl]
    rst $28
    xor $3a
    ld b, l
    ld b, [hl]
    ld c, a
    ld c, c
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $9f
    and e
    cpl
    ld a, $53
    ld a, $36
    ld d, c
    ld a, $43
    ld b, e
    or [hl]
    rst $28
    xor $29
    ld b, [hl]
    ld c, a
    ld b, d
    ccf
    ld a, $4b
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $36
    ld c, e
    ld c, h
    ld d, h
    ld [hl], $51
    ld a, $43
    ld b, e
    ld h, d
    or [hl]
    rst $28
    xor $2c
    ld b, b
    ld b, d
    ld [hl], $51
    ld c, h
    ld c, a
    ld c, d
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld b, [hl]
    ld c, a
    ld b, d
    ld [hl], $51
    ld a, $43
    ld b, e
    ld h, d
    or [hl]
    rst $28
    xor $25
    ld c, c
    ld a, $57
    ld b, d
    ld c, d
    ld c, h
    ld d, b
    ld d, c
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
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld a, $ef
    xor $50
    ld d, c
    ld a, $43
    ld b, e
    ld h, d
    ld d, b
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld a, $49
    ld a, [$eff7]
    xor $51
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, c
    rst $28
    xor $46
    ld d, c
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld a, $48
    ld d, b
    ld e, a
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
    rst $28
    xor $4c
    ld d, d
    ld d, c
    ld h, d
    ld d, c
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
    ld a, [$eff7]
    xor $40
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld c, d
    ld e, a
    ld e, a
    ld h, d
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld a, $49
    ld a, [$eff7]
    xor $45
    ld b, [hl]
    ld b, c
    ld b, c
    ld b, d
    ld c, e
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
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
    rst $28
    xor $54
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, a
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
    inc l
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, d
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
    dec [hl]
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
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    ld h, d
    ld c, c
    ld b, d
    ld a, $41
    ld d, b
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
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $2b
    ld a, $4d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $37
    ld b, d
    ld c, d
    ld c, l
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
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
    xor $2b
    ld a, $4d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $37
    ld b, d
    ld c, d
    ld c, l
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
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
    ld h, e
    rst $28
    xor $2b
    ld a, $53
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $43
    ld c, h
    ld d, d
    ld c, e
    ld b, c
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
    ld h, h
    ld a, [$eff7]
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
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $3f
    ld c, c
    ld b, d
    ld h, d
    ld b, b
    ld a, $4b
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
    ld a, $62
    ld c, c
    ld c, h
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$36]
    jr nc, jr_046_7512

    ld h, $2e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
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
    ld b, l
    ld b, [hl]
    ld d, c
    rst $28
    xor $f6
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $3f
    ld c, h
    ld d, d

jr_046_7512:
    ld c, e
    ld b, b
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
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
    xor $3f
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, l
    ld b, d
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
    xor $4b
    ld b, d
    ld a, $4f
    ld d, b
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld a, $4f
    ld d, b
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, d
    ld d, b
    ld a, [$eff7]
    xor $4d
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, h
    rst $28
    xor $f7
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
    ld a, [$eff7]
    xor $3e
    ld c, d
    ld a, $57
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, e
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
    ld c, d
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
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
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $50
    ld c, b
    ld h, d
    ld a, $51
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $3f
    ld c, c
    ld b, d
    ld h, e
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
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
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
    ld b, l
    ld a, $51
    ld h, d
    ld b, b
    ld a, $4b
    ld a, [$eff7]
    xor $40
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld h, d
    ld c, h
    ld d, d
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
    rst $28
    xor $3e
    ld h, d
    dec h
    ld c, h
    ld c, h
    ld c, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld c, c
    ld c, c
    ld c, h
    ld e, a
    ld h, d
    scf
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld a, $3f
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld h, d
    dec h
    ld c, c
    ld b, d
    ld a, $51
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
    jr nc, jr_046_76e1

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $3f
    ld c, c
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
    jr nc, jr_046_7718

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld d, b

jr_046_76e1:
    ld a, [$eff7]
    xor $54
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, d
    ld a, $40
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
    xor $49
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld e, a
    ld h, d
    dec h
    ld c, c
    ld b, d
    ld a, $51
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld a, $53
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld c, e
    ld d, b

jr_046_7718:
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $4f
    ld b, d
    ld a, $41
    ld h, d
    ld a, $62
    inc [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    dec h
    ld c, b
    ld a, [$eff7]
    xor $4a
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ccf
    ld c, a
    ld a, $53
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld a, $53
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    rst $28
    xor $2b
    ld c, h
    ld c, a
    ld c, a
    ld c, h
    ld c, a
    dec h
    ld c, b
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
    ld b, b
    ld c, h
    ld d, h
    ld a, $4f
    ld b, c
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld b, d
    ld sp, $4046
    ld b, d
    dec h
    ld c, b
    rst $28
    xor $4a
    ld a, $48
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, h
    ld b, d
    ld c, e
    ld d, c
    ld c, c
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld h, $45
    ld b, d
    ld a, $51
    ld b, d
    ld c, a
    dec h
    ld c, b
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, b
    ld c, h
    ld c, c
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4a
    ld a, $4f
    ld d, c
    dec h
    ld c, b
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    ld b, l
    ld a, $4f
    ld b, c
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld b, c
    ld d, [hl]
    dec h
    ld c, b
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, e
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, d
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, b
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $4c
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld d, [hl]
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr nc, @+$58

    ld h, d
    ld c, l
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld e, h
    rst $28
    xor $3e
    ld c, e
    ld b, b
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld a, $62
    ld c, c
    ld c, h
    ld d, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld b, l
    ld a, $4b
    ld c, b
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld e, [hl]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld h, d
    ld c, d
    ld d, d
    ld b, b
    ld b, l
    rst $28
    xor $3e
    ld h, d
    ld b, b
    ld c, h
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $54
    ld a, $50
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, h
    ld a, $56
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $3f
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    daa
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld c, h
    ld d, h
    ld e, [hl]
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
    ld d, c
    ld a, $42
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $37
    ld b, d
    ld c, d
    ld c, l
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, [hl]
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
    ld b, b
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $27
    ld a, $4f
    ld c, b
    jr z, jr_046_79a2

    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
    ld a, $4f
    ld c, b
    jr z, jr_046_79b8

    ld b, d
    ld h, d
    ld b, l
    ld a, $50
    rst $28
    xor $33
    ld a, $49
    ld d, b
    ld d, [hl]
    inc h
    ld b, [hl]
    ld c, a
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    ld h, $52
    ld d, c
    ld h, e
    rst $28
    xor $f7
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

jr_046_79a2:
    ld a, [$eff7]
    xor $27
    ld b, d
    ld a, $41
    ld sp, $5146
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, l
    ld d, [hl]
    ld b, b
    ld c, h
    ld c, l
    ld d, [hl]
    ld e, a

jr_046_79b8:
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld b, d
    ld a, $49
    ld e, [hl]
    ld h, d
    daa
    ld b, d
    ld h, $45
    ld a, $4c
    ld d, b
    rst $28
    xor $b6
    ld h, d
    ld h, $52
    ld c, a
    ld d, b
    ld b, d
    ld [hl-], a
    ld b, e
    ld b, e
    ld e, a
    ld a, [$eff7]
    xor $35
    ld b, d
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $50
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld a, $49
    ld d, c
    ld d, [hl]
    ld h, e
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
    ld h, d
    ld a, $4a
    ld h, d
    dec hl
    ld b, d
    ld c, c
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_046_7a6d

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
    ld d, c
    ld c, h
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld a, [$eff7]
    xor $45
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
    ld d, b
    ld h, d
    ld d, b
    ld c, h
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

jr_046_7a6d:
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld b, h
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
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
    ld b, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld e, [hl]
    ld h, d
    ld b, l
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
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
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
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
    ld h, d
    ld b, l
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld h, d
    dec hl
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    rst $28
    xor $4a
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld b, c
    ld b, d
    ld a, $50
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    inc bc
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld e, [hl]
    rst $28
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    ld b, b
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $5f
    ld e, a
    ld e, a
    ld e, a
    ld d, a
    ld d, a
    ld d, a
    ld e, a
    ld e, a
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
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld d, c
    ld d, h
    ld b, [hl]
    ld b, b
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $5f
    ld e, a
    ld e, a
    ld e, a
    ld d, a
    ld d, a
    ld d, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
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
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld b, c
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld a, [$eff7]
    xor $49
    ld c, h
    ld d, b
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $5f
    ld e, a
    ld e, a
    ld e, a
    ld d, a
    ld d, a
    ld d, a
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    ld d, a
    ld d, a
    ld d, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld c, d
    ld a, $4b
    rst $28
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld b, b
    ld c, h
    ld c, c
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    ld a, [$eff7]
    xor $4a
    ld b, d
    ld b, c
    ld a, $49
    ld d, b
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
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld a, $62
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld h, d
    ld c, e
    ld b, d
    ld a, $4f
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld c, a
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
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    rst $28
    xor $4a
    ld b, d
    ld b, c
    ld a, $49
    ld d, b
    ld e, [hl]
    ld h, d
    ld b, l
    ld b, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $56
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
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld b, e
    ld b, d
    ld b, d
    ld c, c
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
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, b
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $41
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ccf
    ld c, a
    ld a, $4f
    ld d, [hl]
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
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld b, l
    ld b, d
    ld b, b
    ld c, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, h
    rst $30
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
    rst $28
    xor $46
    ld c, d
    ld c, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld a, $51
    ld b, d
    ld c, c
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
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
    xor $4a
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    daa
    ld a, $4f
    ld c, b
    dec hl
    ld c, h
    ld c, a
    ld c, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    jr nc, @+$58

    ld h, d
    ld b, l
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
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
    xor $37
    ld b, d
    ld c, d
    ld c, l
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld a, $53
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $27
    ld a, $4f
    ld c, b
    dec hl
    ld c, h
    ld c, a
    ld c, e
    ld h, d
    ld b, c
    ld b, d
    ld b, d
    ld c, l
    ld a, [$eff7]
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
    rst $28
    xor $4a
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
    ld b, b
    ld a, $53
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, c
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    rst $28
    xor $51
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
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    daa
    ld a, $4f
    ld c, b
    dec hl
    ld c, h
    ld c, a
    ld c, e
    ld e, a
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
