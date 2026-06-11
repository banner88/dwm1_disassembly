; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $01b", ROMX[$4000], BANK[$1b]

    db $1B ; Bank number

    ; Cross-bank dispatch table (136 entries)
    ; Called via: ld hl, $1BXX / rst $10
    dw $4111                          ; Entry 0
    dw $4118                          ; Entry 1
    dw $411F                          ; Entry 2
    dw $400D                          ; Entry 3
    dw $4019                          ; Entry 4
    dw $40A1                          ; Entry 5
    dw $4126                          ; Entry 6
    dw $417B                          ; Entry 7
    dw $41AD                          ; Entry 8
    dw $41DF                          ; Entry 9
    dw $4248                          ; Entry 10
    dw $4282                          ; Entry 11
    dw $430E                          ; Entry 12
    dw $4344                          ; Entry 13
    dw $43A2                          ; Entry 14
    dw $4417                          ; Entry 15
    dw $444A                          ; Entry 16
    dw $4486                          ; Entry 17
    dw $44A7                          ; Entry 18
    dw $44E7                          ; Entry 19
    dw $4555                          ; Entry 20
    dw $45C3                          ; Entry 21
    dw $4616                          ; Entry 22
    dw $4665                          ; Entry 23
    dw $46CF                          ; Entry 24
    dw $4754                          ; Entry 25
    dw $4799                          ; Entry 26
    dw $482E                          ; Entry 27
    dw $485B                          ; Entry 28
    dw $487C                          ; Entry 29
    dw $4962                          ; Entry 30
    dw $497D                          ; Entry 31
    dw $4999                          ; Entry 32
    dw $49AF                          ; Entry 33
    dw $4A27                          ; Entry 34
    dw $4A41                          ; Entry 35
    dw $4AD5                          ; Entry 36
    dw $4B78                          ; Entry 37
    dw $4BB2                          ; Entry 38
    dw $4C40                          ; Entry 39
    dw $4C88                          ; Entry 40
    dw $4CB5                          ; Entry 41
    dw $4D34                          ; Entry 42
    dw $4D95                          ; Entry 43
    dw $4E33                          ; Entry 44
    dw $4E68                          ; Entry 45
    dw $4E77                          ; Entry 46
    dw $4EA4                          ; Entry 47
    dw $4EB1                          ; Entry 48
    dw $4EDE                          ; Entry 49
    dw $4F33                          ; Entry 50
    dw $4F6B                          ; Entry 51
    dw $4FD9                          ; Entry 52
    dw $4FF4                          ; Entry 53
    dw $5027                          ; Entry 54
    dw $5091                          ; Entry 55
    dw $50DB                          ; Entry 56
    dw $5192                          ; Entry 57
    dw $51AD                          ; Entry 58
    dw $526E                          ; Entry 59
    dw $530D                          ; Entry 60
    dw $53C2                          ; Entry 61
    dw $5433                          ; Entry 62
    dw $5493                          ; Entry 63
    dw $55A7                          ; Entry 64
    dw $55E0                          ; Entry 65
    dw $560F                          ; Entry 66
    dw $56DF                          ; Entry 67
    dw $5724                          ; Entry 68
    dw $576C                          ; Entry 69
    dw $57D1                          ; Entry 70
    dw $583C                          ; Entry 71
    dw $593F                          ; Entry 72
    dw $5997                          ; Entry 73
    dw $59FB                          ; Entry 74
    dw $5A1E                          ; Entry 75
    dw $5A37                          ; Entry 76
    dw $5AC0                          ; Entry 77
    dw $5ADB                          ; Entry 78
    dw $5AF9                          ; Entry 79
    dw $5B37                          ; Entry 80
    dw $5B78                          ; Entry 81
    dw $5BED                          ; Entry 82
    dw $5C2B                          ; Entry 83
    dw $5C44                          ; Entry 84
    dw $5C5F                          ; Entry 85
    dw $5C9A                          ; Entry 86
    dw $5CFC                          ; Entry 87
    dw $5D1D                          ; Entry 88
    dw $5D4C                          ; Entry 89
    dw $5DB6                          ; Entry 90
    dw $5DD7                          ; Entry 91
    dw $5DF9                          ; Entry 92
    dw $5E32                          ; Entry 93
    dw $5E46                          ; Entry 94
    dw $5EAB                          ; Entry 95
    dw $5F47                          ; Entry 96
    dw $603C                          ; Entry 97
    dw $60DE                          ; Entry 98
    dw $6133                          ; Entry 99
    dw $61EE                          ; Entry 100
    dw $620E                          ; Entry 101
    dw $6225                          ; Entry 102
    dw $6302                          ; Entry 103
    dw $63F1                          ; Entry 104
    dw $646D                          ; Entry 105
    dw $64E6                          ; Entry 106
    dw $6530                          ; Entry 107
    dw $6620                          ; Entry 108
    dw $6681                          ; Entry 109
    dw $66AA                          ; Entry 110
    dw $66E9                          ; Entry 111
    dw $672C                          ; Entry 112
    dw $680F                          ; Entry 113
    dw $689C                          ; Entry 114
    dw $68D2                          ; Entry 115
    dw $6962                          ; Entry 116
    dw $69F5                          ; Entry 117
    dw $6A5A                          ; Entry 118
    dw $6AC5                          ; Entry 119
    dw $6B6C                          ; Entry 120
    dw $6C01                          ; Entry 121
    dw $6C78                          ; Entry 122
    dw $6C91                          ; Entry 123
    dw $6D41                          ; Entry 124
    dw $6DF4                          ; Entry 125
    dw $6EA6                          ; Entry 126
    dw $6F55                          ; Entry 127
    dw $7005                          ; Entry 128
    dw $70B2                          ; Entry 129
    dw $715D                          ; Entry 130
    dw $720E                          ; Entry 131
    dw $72BC                          ; Entry 132
    dw $736C                          ; Entry 133
    dw $741B                          ; Entry 134
    ; NOTE: last 1 entry/entries (2B) merged into following instruction

    db $cc, $74, $11
    rlca
    ld b, b
    call CallTextEngine
    ret


    ld de, $4007
    call RunTextHandler
    ret


    call $4111
    call RequestScreenUpdate
    ret


    db $eb
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld a, $4a
    ld b, d

jr_01b_413e:
    ld h, d
    ld c, h
    ld b, e

jr_01b_4141:
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
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
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3a
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    ld h, h
    rst $28
    xor $2b
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld d, h
    ld b, d
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld b, h
    ld c, h
    ld d, b
    ld b, l
    ld h, e
    ld h, d
    inc l
    rst $28
    xor $54
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
    ld a, $51
    ld a, [$eff7]
    xor $49
    ld a, $41
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld c, b
    ld a, $56
    ld h, h
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, d
    ld c, h
    ld b, e
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
    cpl
    ld c, h
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3a
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
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
    ld b, l
    ld b, d
    ld h, d
    or [hl]
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $51
    ld b, d
    ld a, [$eff7]
    xor $42
    ld a, $40
    ld b, l
    ld h, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld c, e
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    inc l
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
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
    rst $28
    xor $44
    ld c, a
    ld c, h
    ld d, h
    ld d, b
    ld e, [hl]
    ld h, d
    ld b, l
    ld d, d
    ld b, h
    ld b, d
    ld a, [$eff7]
    xor $42
    ld a, $4f
    ld d, c
    ld b, l
    ld c, [hl]
    ld d, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld b, b
    ld b, b
    ld d, d
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
    rst $28
    xor $4a
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld d, b
    ld h, d
    ld a, $51
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
    ld d, h
    ld b, l
    ld b, d
    ld c, e
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
    ld a, [$eff7]
    xor $3f
    ld b, [hl]
    ld b, h
    ld b, h
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld l, $42
    ld b, d
    ld c, l
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    rst $28
    xor $2e
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $2c
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
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, h
    ld b, h
    ld a, $4f
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld b, e
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
    rst $28
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    ld a, [$eff7]
    xor $45
    ld b, d
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    rst $28
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, e
    rst $28
    xor $37
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld l, b
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
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld b, d
    ld c, a
    ld d, e
    ld b, d
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $52
    ld c, e
    ld a, $53
    ld c, h
    ld b, [hl]
    ld b, c
    ld a, $3f
    ld c, c
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
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
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
    xor $4b
    ld c, h
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld l, b
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $62
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $42
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld d, c
    ld a, $46
    ld c, e
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    rst $30
    ldh a, [$2e]
    sbc h
    ld d, c
    ld b, l
    ld d, d
    ld c, d
    ld c, l
    ld h, e
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
    ld a, [$eff7]
    xor $45
    ld b, [hl]
    ld d, c
    ld h, d
    or $5f
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
    ld l, b
    ld h, d
    ld a, $ef
    xor $4d
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $42
    ld d, e
    ld a, $49
    ld d, d
    ld a, $51
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld a, $51
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
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld a, $41
    jr nc, @+$44

    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld a, $41
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    ld c, h
    ld d, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    dec h
    ld a, $41
    jr nc, jr_01b_4559

    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld b, d
    ld a, $51
    ld e, a
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld a, $62
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    inc l
    rst $28
    xor $42
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]

jr_01b_4559:
    ld b, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld d, b
    ld c, h
    ccf
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    rst $28
    xor $54
    ld b, d
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld a, $4b
    ld h, d
    ld d, d
    ld c, e
    ld d, h
    ld a, $4b
    ld d, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $40
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
    ld a, [hl-]
    ld b, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld c, d
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4d
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, $49
    ld b, [hl]
    ld d, c
    ld d, [hl]
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
    ld a, $4f
    ld b, d
    ld h, d
    ld b, b
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, e
    ld d, b
    rst $28
    xor $54
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld a, [$eff7]
    xor $47
    ld d, d
    ld c, d
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_01b_4670

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $36
    ld d, c
    ld a, $3f
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
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
    scf
    ld a, $49
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld e, a
    rst $28
    xor $2b
    ld a, $53
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld c, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld h, e
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b

jr_01b_4670:
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $51
    ld b, b
    ld b, l
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
    ld c, c
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    rst $28
    xor $3e
    ld c, c
    ld c, c
    ld h, d
    ld b, a
    ld d, d
    ld c, e
    ld c, b
    ld d, b
    ld h, d
    ld b, b
    ld a, $52
    ld b, h
    ld b, l
    ld d, c
    ld a, [$eff7]
    xor $4c
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    add hl, hl
    ld a, $4f
    ld c, d
    ld e, a
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
    xor $50
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld [hl], $51
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
    daa
    ld c, a
    ld c, h
    ld c, l
    ld c, l
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld b, e
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
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
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
    ld a, $4f
    ld b, d
    ld h, d
    ld b, l
    ld b, [hl]
    ld b, c
    ld b, c
    ld b, d
    ld c, e
    ld a, [$eff7]
    xor $42
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
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
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld h, d
    jr nc, jr_01b_47df

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $27
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
    ld a, [$eff7]
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    ld h, $52
    ld d, c
    ld h, h
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
    xor $46
    ld d, c
    ld d, b
    ld h, d
    ld a, $62
    ld d, b
    ld d, d
    ld c, l

jr_01b_47df:
    ld b, d
    ld c, a
    ccf
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld b, l
    ld a, $4f
    ld b, c
    sbc h
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld c, c
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld c, e
    ld d, c
    ld b, d
    ld a, $51
    ld b, d
    ld c, a
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $49
    ld b, d
    ld a, $4f
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld e, [hl]
    rst $28
    xor $2c
    ld l, d
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $2f
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
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
    sbc a
    and e
    dec h
    ld b, [hl]
    ld b, h
    jr z, @+$58

    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    rst $28
    xor $3e
    ld d, c
    ld h, d
    inc l
    ld b, b
    ld b, d
    dec h
    ld c, h
    ld c, c
    ld d, c
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, h
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $3e
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4c
    ld h, d
    inc l
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $42
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $29
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
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_01b_491d

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
    xor $49
    ld a, $4f
    ld b, h
    ld b, d
    ld c, a
    ld h, d
    and d
    ld h, d
    ld c, e
    ld d, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld b, c
    ld b, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    rst $28
    xor $4b
    ld a, $4a
    ld b, d
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld c, a

jr_01b_491d:
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld a, $4b
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
    ld d, c
    ld d, [hl]
    ld c, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $49
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    and d
    ld h, d
    ld c, e
    ld d, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld h, $45
    ld c, h
    ld c, d
    ld c, l
    rst $28
    xor $40
    ld b, l
    ld c, h
    ld c, d
    ld c, l
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld h, $4f
    ld d, d
    ld c, e
    ld b, b
    ld b, l
    rst $28
    xor $40
    ld c, a
    ld d, d
    ld c, e
    ld b, b
    ld b, l
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld a, [hl-]
    ld a, $4b
    ld d, c
    rst $28
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld h, h
    rst $38
    ldh a, [$f6]
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    rst $28
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f6
    rst $28
    xor $50
    ld d, c
    ld a, $4f
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld b, d
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f6
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $42
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    ld d, c
    ld a, $ef
    xor $54
    ld b, [hl]
    ld c, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld sp, $624c
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $50
    ld d, c
    ld a, $56
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    inc h
    ld b, [hl]
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, jr_01b_4acb

    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld a, $49
    ld c, c
    ld d, [hl]
    ld e, [hl]
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
    ld b, [hl]
    ld c, e
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
    ld a, $4b
    ld b, c
    ld h, d
    dec h
    ld b, d
    ld a, $50
    ld d, c
    rst $28
    xor $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, e
    ld a, $49
    ld c, c
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d

jr_01b_4acb:
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec a
    ld d, a
    ld d, a
    ld e, a
    ld e, a
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld [hl], $51
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
    ld h, $52
    ld c, a
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld c, c
    ld d, [hl]
    rst $28
    xor $50
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    ld d, a
    ld d, a
    ld e, a
    ld a, [$eff7]
    xor $31
    ld c, h
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
    xor $4d
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld d, b
    ld h, d
    ld e, a
    ld e, a
    ld e, a
    ld d, a
    ld d, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld sp, $3f4c
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    rst $28
    xor $52
    ld c, l
    ld e, a
    ld e, a
    ld e, a
    ld d, a
    ld d, a
    ld e, a
    ld a, [$eff7]
    xor $31
    ld c, h
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld e, a
    ld e, a
    ld d, a
    ld d, a
    ld e, a
    ld h, d
    ld d, a
    ld d, a
    ld d, a
    ld e, a
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
    xor $27
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld c, h
    ld d, d
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
    xor $4a
    ld b, d
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
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
    ld a, [$eff7]
    xor $30
    ld a, $41
    ld l, $4b
    ld b, [hl]
    ld b, h
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
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $43
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    jr nc, jr_01b_4c4e

    ld b, c
    ld l, $4b
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $49
    ld c, d
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld a, $50
    rst $28
    xor $40
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld a, $50
    ld h, d
    inc l
    ld h, d
    ld a, $4a
    ld e, a
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
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c

jr_01b_4c4e:
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
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld h, d
    ld d, b
    ld c, d
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $36
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    inc h
    ld b, [hl]
    ld c, a
    ld h, d
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, b
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
    xor $27
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    jr nc, jr_01b_4d0a

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
    or $5f
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
    rst $28
    xor $29
    ld c, h
    ld c, a
    ld h, d
    ld d, b
    ld d, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $27
    ld h, d
    ld b, b
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
    ld l, $46
    ld c, e

jr_01b_4d0a:
    ld b, h
    ld h, d
    ld c, e
    ld b, d
    ld b, d
    ld b, c
    ld d, b
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld e, a
    ld h, d
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld a, $56
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl], $46
    ld c, a
    ld h, d
    jr nc, jr_01b_4d83

    ld b, b
    ld c, b
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    inc [hl]
    ld d, d
    ld b, d
    ld b, d
    ld c, e
    ld l, b
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $9f
    and e
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4c
    ld c, l
    ld c, l
    ld c, h
    ld c, e
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $49
    ld a, $50
    ld d, c
    ld h, d
    ld c, d
    ld a, $51

jr_01b_4d83:
    ld b, b
    ld b, l
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $27
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld d, b
    ld c, h
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld c, a
    ld d, d
    ld b, c
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld a, $4b
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    rst $28
    xor $40
    ld b, l
    ld a, $4b
    ld b, b
    ld b, d
    ld h, e
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
    ld d, h
    ld b, d
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
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
    ld e, [hl]
    ld h, d
    or $64
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    inc l
    ld b, b
    ld b, d
    jr nc, jr_01b_4e50

    ld c, e
    ld e, a
    rst $28
    xor $26
    ld l, d
    ld c, h
    ld c, e
    ld e, [hl]
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, b
    ld b, d
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

jr_01b_4e50:
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, b
    ld a, $53
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, h
    rst $38
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
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
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
    ld a, [$eff7]
    xor $40
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    sbc a
    ld d, b
    ld b, [hl]
    ld b, h
    ld b, l
    sbc a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
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
    ld a, [$eff7]
    xor $40
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld d, b
    ld c, h
    rst $28
    xor $45
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $9f
    ccf
    ld c, c
    ld d, d
    ld d, b
    ld b, l
    sbc a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, l
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld c, a
    ld d, [hl]
    rst $28
    xor $4a
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
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
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4d
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, b
    ld b, d
    ld d, b
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, e
    ld a, $46
    ld c, e
    ld h, e
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
    ld c, h
    ld c, b
    ld a, $56
    ld e, a
    rst $28
    xor $3c
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
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld d, c
    ld d, c
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
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    ld d, [hl]
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
    ld b, b
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    rst $28
    xor $4e
    ld d, d
    ld b, [hl]
    ld b, d
    ld d, c
    ld c, c
    ld d, [hl]
    ld e, a
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    rst $28
    xor $4e
    ld d, d
    ld b, [hl]
    ld b, d
    ld d, c
    ld c, c
    ld d, [hl]
    ld e, a
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld a, $62
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $45
    ld b, d
    ld c, a
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld a, $53
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
    xor $2c
    ld b, b
    ld b, d
    jr nc, jr_01b_508c

    ld c, e
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
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
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, d
    ld a, $56
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, d
    ld c, l
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
    ld h, d
    cpl
    ld a, $53
    ld a, $30
    ld a, $4b
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h

jr_01b_508c:
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, c
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $51
    ld c, h
    ld h, d
    ccf
    ld c, h
    ld a, $50
    ld d, c
    ld h, d
    ld d, b
    ld c, h
    ld a, [$eff7]
    xor $4a
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld sp, $4046
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $f6
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_01b_512c

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
    xor $49
    ld b, d
    ld a, $4f
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld b, d
    ld b, d
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
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, h
    ld b, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    rst $28
    xor $49
    ld b, d
    ld a, $4f
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld a, [$eff7]

jr_01b_512c:
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, h
    ld b, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $49
    ld c, h
    ld d, h
    ld h, d
    jr nc, jr_01b_5174

    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, h
    ld b, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $51
    ld c, a
    ld c, h
    ld d, d
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $4f
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, [hl]
    ld a, [$eff7]

jr_01b_5174:
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
    ld b, l
    ld b, d
    rst $28
    xor $54
    ld a, $56
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    jr z, jr_01b_51ed

    ld b, d
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $2b
    ld a, $63
    ld h, d
    dec hl
    ld a, $63
    rst $30
    ldh a, [$ea]
    sbc a
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
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $4d
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, $49
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, c
    rst $28
    xor $30
    ld b, [hl]
    ld b, b
    ld c, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    ld a, [$eff7]

jr_01b_51ed:
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
    ld [hl-], a
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
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
    inc h
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $2f
    ld b, [hl]
    ld d, a
    ld a, $4f
    ld b, c
    jr nc, jr_01b_5265

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
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    jr nc, jr_01b_5284

    ld b, b
    ld c, b
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
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, e

jr_01b_5265:
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f7
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
    ld a, $51
    ld d, d
    ld b, d
    ld d, b
    rst $28
    xor $50
    ld d, c
    ld a, $4b

jr_01b_5284:
    ld b, c
    ld h, d
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4d
    ld c, a
    ld c, h
    ld d, c
    ld b, d
    ld b, b
    ld d, c
    ld c, h
    ld c, a
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
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $3e
    ld h, d
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld h, d
    ld a, $4b
    ld a, [$eff7]
    xor $42
    ld c, e
    ld d, c
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2d
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld d, b
    ld c, d
    ld a, $4f
    ld d, c
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_01b_535e

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld c, e
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $42
    ld b, c
    ld d, d
    ld b, b
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
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
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $42
    ld a, $50
    ld b, [hl]
    ld b, d
    ld c, a
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
    xor $54
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, d
    ld h, d
    ld d, c

jr_01b_535e:
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld c, c
    ld b, c
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld b, l
    ld d, d
    ld c, d
    ld a, $4b
    ld d, b
    ld h, d
    or [hl]
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
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld h, d
    ld b, l
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
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld l, b
    ld a, [$eff7]
    xor $50
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_01b_548e

    ld h, d
    ld c, a
    ld b, [hl]
    ld d, e
    ld a, $49
    ld h, d
    ld b, [hl]
    ld d, b
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
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld a, $50
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld a, $50
    rst $28
    xor $2c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $25
    ld c, h
    ld c, e
    ld b, d
    ld [hl], $49
    ld a, $53
    ld b, d
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld a, $51

jr_01b_548e:
    ld b, d
    ld c, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld c, h
    ld c, e
    rst $28
    xor $50
    ld b, d
    ld c, e
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $25
    ld b, d
    ld a, $50
    ld d, c
    scf
    ld a, $46
    ld c, c
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $47
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld c, c
    ld d, b
    ld c, h
    ld h, d
    jr nc, jr_01b_551c

    ld c, l
    dec hl
    ld b, d
    ld c, a
    ccf
    ld h, d
    or [hl]
    rst $28
    xor $3a
    ld a, $4f
    ld c, l
    ld [hl], $51
    ld a, $43
    ld b, e
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $45
    ld b, d
    ld c, c
    ld c, l
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, @+$40

    ld c, l
    dec hl
    ld b, d
    ld c, a
    ccf
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld d, b
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d

jr_01b_551c:
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $42
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, a
    ld b, d
    ld h, d
    ld c, d
    ld a, $4d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld a, $4f
    ld c, l
    ld [hl], $51
    ld a, $43
    ld b, e
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $51
    ld a, $48
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
    ld d, h
    ld a, $4f
    ld c, l
    ld a, [$eff7]
    xor $45
    ld c, h
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
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, jr_01b_55ca

    ld b, b
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, h
    ld a, $51
    ld b, b
    ld b, l
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
    ld h, d
    ld c, c
    ld a, $57
    ld d, [hl]
    ld h, d
    dec h
    ld c, h
    ld c, d
    ccf
    ld h, $4f
    ld a, $44
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld h, d
    ld b, l
    ld c, h
    ld h, e
    ld h, d
    dec hl
    ld b, [hl]
    ld h, d
    ld b, l
    ld c, h
    ld h, e
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
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld b, c
    ld c, h

jr_01b_55ca:
    ld h, d
    inc l
    rst $28
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld a, $4b
    ld c, e
    ld a, $62
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, h
    ld c, l
    ld c, l
    ld c, h
    ld c, e
    ld b, d
    ld c, e
    ld d, c
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    daa
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
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
    ld c, a
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
    xor $46
    ld c, e
    ld h, d
    daa
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    jr nc, @+$48

    ld b, b
    ld c, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
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
    ld a, $4f
    ld b, d
    rst $28
    xor $3e
    ld h, d
    dec [hl]
    ld c, h
    ld b, h
    ld d, d
    ld b, d
    ld sp, $5146
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld [bc], a
    ld a, [$eff7]
    xor $30
    ld a, $41
    ld h, $3e
    ld d, c
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_01b_56c2

    ld b, c
    ld h, $3e
    ld d, c
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    rst $28
    xor $36
    ld c, [hl]
    ld d, d
    ld a, $49
    ld c, c
    dec hl
    ld b, [hl]
    ld d, c
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
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld a, [$eff7]

jr_01b_56c2:
    xor $50
    ld d, c
    ld a, $4a
    ld b, [hl]
    ld c, e
    ld a, $5e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, [hl]
    ld c, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, $50
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
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $62
    ld c, l
    ld a, $46
    ld c, a
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld b, l
    ld a, $50
    ld b, l
    ld b, [hl]
    ld d, b
    ld e, a
    ld h, d
    dec h
    ld b, d
    ccf
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $35
    ld b, d
    ld c, l
    ld b, d
    ld a, $51
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $26
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, b
    ld c, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld b, l
    ld a, $50
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, h
    ld h, d
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld a, [$eff7]
    xor $40
    ld a, $4b
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, d
    ld c, l
    ld c, c
    ld d, [hl]
    rst $28
    xor $50
    ld a, $56
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, l
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld d, b
    ld h, e
    ld h, h
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
    ld b, l
    ld c, h
    ld d, h
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
    jr nc, jr_01b_57d6

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
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld d, b
    ld h, h
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
    ld c, h
    ld b, e
    ld b, e
    sbc h
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $4d
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld d, b
    ld c, d
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld d, b
    ld b, l
    ld d, [hl]
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l

jr_01b_57d6:
    ld b, d
    ld h, d
    ld c, d
    ld a, $4b
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3e
    ld c, c
    ld d, h
    ld a, $56
    ld d, b
    ld h, d
    ld c, l
    ld a, $40
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $3e
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
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
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld d, b
    ld a, $41
    ld h, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld a, [$eff7]
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld b, e
    ld b, d
    ld h, d
    ld b, l
    ld a, $50
    rst $28
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld b, h
    ld c, e
    ld b, [hl]
    ld d, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld d, d
    ld c, l
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
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
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
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
    xor $4f
    ld b, d
    ld d, e
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $3e
    ld c, e
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
    ld c, d
    ld b, d
    rst $28
    xor $4c
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
    ld a, $ef
    xor $51
    ld b, l
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, h
    ld a, [$eff7]
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
    ld h, d
    inc l
    ld h, [hl]
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
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $4c
    ld c, c
    ld b, c
    ld h, d
    ld a, $50
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld a, $4b
    ld d, c
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld h, e
    rst $30
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
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $43
    ld b, [hl]
    ld c, e
    ld b, c
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
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld d, c
    ld b, l
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    rst $28
    xor $50
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld e, [hl]
    ld h, d
    ld c, l
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
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
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $35
    ld b, d
    ld c, d
    ld b, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld e, [hl]
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    rst $28
    xor $2a
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $3e
    ld d, b
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld a, $4b
    ld d, c
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3f
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld e, a
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
    ccf
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $4c
    ld c, e
    ld b, d
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, d
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    ld h, $3e
    ld c, e
    ld h, d
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $f9
    nop
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $544c
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, b
    ld a, $4f
    ld c, a
    ld d, [hl]
    rst $28
    xor $4c
    ld d, d
    ld d, c
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, d
    ld d, l
    ld c, l
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $37
    ld b, l
    ld a, $4b
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    or $63
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
    ld c, d
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld d, d
    ld b, b
    ld b, b
    ld b, d
    ld d, b
    ld d, b
    ld b, e
    ld d, d
    ld c, c
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $40
    ld a, $4b
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $3e
    ld d, b
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld a, $4b
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $4b
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $544c
    ld e, [hl]
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld sp, hl
    nop
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    daa
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
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld d, c
    ld b, l
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
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
    inc l
    rst $28
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
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3e
    ld c, c
    ld d, h
    ld a, $56
    ld d, b
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld a, $49
    ld c, b
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_01b_5c00

    ld d, [hl]
    ccf
    ld b, d
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $44
    ld b, [hl]
    ccf
    ccf
    ld b, d
    ld c, a
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    dec hl
    inc h
    ld [hl], $fa
    rst $30
    rst $28
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld a, $4b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    dec h
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

jr_01b_5c00:
    xor $4c
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
    ld e, [hl]
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
    ld c, c
    ld c, h
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, d
    ld d, b
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    and e
    ld h, $45
    ld c, h
    ld c, d
    ld c, l
    rst $28
    xor $40
    ld b, l
    ld c, h
    ld c, d
    ld c, l
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    and e
    ld h, $4f
    ld d, d
    ld c, e
    ld b, b
    ld b, l
    rst $28
    xor $40
    ld c, a
    ld d, d
    ld c, e
    ld b, b
    ld b, l
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $51
    ld h, h
    ld a, [$eff7]
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, h
    rst $28
    xor $ff
    ldh a, [$f6]
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    rst $28
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld a, [$eff7]
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    dec h
    ld a, $41
    jr nc, jr_01b_5d0c

    ld a, $51
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f6
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    rst $28
    xor $3e
    ld d, c
    ld h, d
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld b, e
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    and e
    dec hl
    ld a, $63
    rst $28
    xor $36
    ld b, d

jr_01b_5d0c:
    ld c, a
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $30
    ldh a, [$ea]
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    rst $28
    xor $27
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $fa
    rst $30
    rst $28
    xor $42
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, h
    rst $28
    xor $ff
    ldh a, [$f6]
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    rst $28
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $3a
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    dec h
    ld a, $41
    jr nc, jr_01b_5dbe

    ld a, $51
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f6
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
    xor $3a
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $43
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld a, $40
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d

jr_01b_5dbe:
    and e
    dec hl
    ld a, $63
    rst $28
    xor $36
    ld b, d
    ld c, a
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld c, l
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, c
    ld c, h
    rst $28
    xor $26
    ld a, $49
    ld c, c
    ld e, a
    ld h, d
    jr z, jr_01b_5e35

    ld b, d
    ld b, d
    ld c, b
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
    xor $24
    ld h, d
    ld c, e
    ld a, $50
    ld d, c
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $51
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld b, h

jr_01b_5e35:
    ld c, h
    ld d, c
    ld h, d
    ld a, $ef
    xor $3a
    ld a, $4f
    ld c, l
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$29]
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld a, $62
    ld a, [hl-]
    ld a, $4f
    ld c, l
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld b, h
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
    ld a, [hl-]
    ld a, $4f
    ld c, l
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld b, h
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
    inc h
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
    xor $2f
    ld a, $3f
    ld d, [hl]
    ld c, a
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, l
    rst $28
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
    ld a, [$eff7]
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
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld d, b
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
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
    ld a, $54
    ld a, $46
    ld d, c
    ld h, e
    rst $28
    xor $f7
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
    inc h
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld e, a
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
    ld d, b
    ld h, d
    ld c, h
    ld b, e
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
    ld e, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
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
    scf
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
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
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
    ld a, $54
    ld a, $46
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
    ld l, c
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
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, l
    ld h, d
    ld [bc], a
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld b, d
    ld d, b
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
    inc h
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld e, a
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
    ld d, b
    ld h, d
    ld c, h
    ld b, e
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
    ld e, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
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
    ld h, d
    ld sp, $5442
    ld h, d
    ld b, h
    ld a, $51
    ld b, d
    ld d, b
    rst $28
    xor $3e
    ld d, h
    ld a, $46
    ld d, c
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
    xor $4c
    ld b, e
    ld h, d
    inc h
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
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
    ccf
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $30
    ld a, $56
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
    xor $4f
    ld b, d
    ld d, b
    ld d, c
    ld a, $52
    ld c, a
    ld a, $4b
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
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
    ld b, l
    ld b, d
    rst $28
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
    ld d, b
    ld a, [$eff7]
    xor $40
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
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
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $9f
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
    ld h, d
    inc h
    rst $28
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
    xor $54
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
    ld d, b
    ld a, [$eff7]
    xor $40
    ld c, a
    ld b, d
    ld a, $51
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
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, l
    ld b, l
    ld b, h
    ld h, d
    ld b, l
    ld b, l
    ld b, l
    ld b, h
    ld e, a
    rst $28
    xor $39
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld b, e
    ld d, [hl]
    ld e, [hl]
    ld h, d
    add hl, sp
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld b, e
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_01b_6251

    ld b, c
    dec [hl]
    ld a, $53
    ld b, d
    ld c, e
    ld h, d
    dec hl
    ld b, d
    ld a, $53
    ld b, d
    ld c, e
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
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
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $3e
    ld h, d
    ccf
    ld a, $41
    ld h, d
    ld c, l
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, $49
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, b
    ld c, h

jr_01b_6251:
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld a, $4b
    rst $28
    xor $4c
    ccf
    ld d, b
    ld d, c
    ld a, $40
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $fa
    rst $30

Jump_01b_6268:
    rst $28
    xor $53
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
    dec h
    ld d, d
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
    ld a, $62
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld a, [$eff7]
    xor $4d
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, $49
    ld b, [hl]
    ld d, c
    ld d, [hl]
    rst $28
    xor $3e
    ld b, b
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld c, d
    ld a, $4f
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $44
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld a, $4b
    ld a, [$eff7]
    xor $46
    ld d, c
    ld b, d
    ld c, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    ld a, [$eff7]
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
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld c, c
    ld b, d
    ld a, $4f
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld a, $62
    ld c, e
    ld b, d
    ld d, h
    rst $28
    xor $50
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld b, [hl]
    ld d, b
    ld b, l
    ld c, h
    ld c, l
    ld h, d
    inc l
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, d
    rst $28
    xor $2b
    ld b, d
    ld a, $49
    jr c, jr_01b_639a

    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $2b
    ld b, d
    ld a, $49
    ld b, d
    ld c, a
    ld h, d
    or [hl]
    ld h, d
    cpl
    ld b, [hl]
    ld c, h
    ld c, e
    ld b, d
    ld d, l
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    add hl, sp
    ld b, [hl]
    ld d, e
    ld h, d
    add hl, sp
    ld b, [hl]
    ld d, e
    rst $28
    xor $39
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld b, e
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
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
    ld c, d
    ld b, d
    ld h, d
    or [hl]
    rst $28
    xor $38
    ld c, e

jr_01b_639a:
    ld b, [hl]
    ld b, b
    ld c, h
    ld c, a
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld c, h
    ld c, l
    ld h, d
    ld [hl], $51
    ld b, d
    ld c, l
    rst $28
    xor $36
    ld d, c
    ld b, d
    ld c, l
    ld a, [hl+]
    ld d, d
    ld a, $4f
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $27
    ld c, a
    ld c, h
    ld c, c
    ld c, c
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $30
    ld a, $4d
    jr nc, @+$40

    ld b, h
    ld b, [hl]
    ld b, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $28
    ld d, e
    ld b, [hl]
    ld c, c
    ld a, [hl-]
    ld a, $4b
    ld b, c
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
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld l, b
    ld h, d
    ld c, c
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
    ld d, c
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $40
    ld a, $4b
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    jr nc, jr_01b_64b4

    ld c, c
    ld d, c
    ld b, [hl]
    ld h, $52
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_01b_64c8

    ld h, d
    ld c, a
    ld b, [hl]
    ld d, e
    ld a, $49
    ld h, d
    ld b, [hl]
    ld d, b
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
    ld a, [$eff7]
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld e, a
    ld e, a
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
    inc l
    ld h, d
    ld b, l
    ld a, $41
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
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $fa

jr_01b_64b4:
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
    rst $28
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld c, h

jr_01b_64c8:
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, e
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
    ld e, a
    ld h, d
    inc a
    ld c, h
    rst $28
    xor $41
    ld d, d
    ld b, c
    ld b, d
    ld h, e
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
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $24
    ld h, d
    ld b, b
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
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld c, e
    ld h, d
    inc h
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    jr nc, jr_01b_659e

    ld d, [hl]
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
    xor $4f
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
    ld [hl], $45
    ld b, d
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld a, $62
    cpl
    ld b, [hl]
    ld c, l
    ld d, b
    ld d, [hl]
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld d, h
    ld c, h
    ld a, [$eff7]
    xor $37
    ld c, h
    ld a, $41
    ld d, b

jr_01b_659e:
    ld d, c
    ld c, h
    ld c, h
    ld c, c
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    ld d, a
    ld d, a
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld b, d
    ld b, b
    ld c, h
    ld c, e
    ld b, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $47
    ld d, d
    ld c, d
    ld c, l
    ld h, d
    ld b, c
    ld b, [hl]
    ld c, a
    ld b, d
    ld b, b
    ld d, c
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $51
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    ld a, $ef
    xor $3f
    ld b, [hl]
    ld b, h
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
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
    ld a, $ef
    xor $4a
    ld d, d
    ld d, b
    ld d, c
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc h
    ld c, d
    ld a, $57
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld l, b
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
    ld h, e
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
    rst $28
    xor $3e
    ld h, d
    ld c, a
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $4b
    rst $28
    xor $2c
    ld sp, $5037
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
    ld a, $ef
    xor $4a
    ld b, d
    ld b, c
    ld a, $4a
    ld a, $9c
    ld d, [hl]
    ld a, $48
    ld b, [hl]
    ld a, [$eff7]
    xor $25
    ld b, d
    ccf
    ld b, d
    ld h, e
    ld h, d
    dec [hl]
    ld b, d
    ld c, l
    ld b, d
    ld a, $51
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $4a
    ld b, d
    ld e, a
    ld h, d
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, b
    ld c, b
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3e
    ld h, d
    ld c, d
    ld b, d
    ld b, c
    ld a, $4a
    ld a, $9c
    ld d, [hl]
    ld a, $48
    ld b, [hl]
    ld h, e
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $3e
    ld h, d
    ld b, e
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, h
    ld a, $51
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    rst $28
    xor $50
    ld b, d
    ld b, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
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
    ld e, [hl]
    rst $28
    xor $3e
    ld h, d
    ld c, e
    ld d, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    and d
    ld bc, $f7fa
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $ef
    xor $4a
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
    scf
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld b, h
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld d, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    and d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
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
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld a, $4d
    ld a, $3f
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld a, $41
    ld b, c
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl], $4d
    ld c, c
    ld a, $50
    ld b, l
    ld h, d
    ld d, b
    ld c, l
    ld c, c
    ld a, $50
    ld b, l
    ld h, e
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
    ld a, $63
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
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, a
    ld c, e
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld b, d
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
    rst $28
    xor $3f
    ld c, a
    ld b, d
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
    ld a, [$eff7]
    xor $48
    ld b, [hl]
    ld c, e
    ld b, c
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
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld b, c
    ld b, c
    ld b, [hl]
    ld b, b
    ld d, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, l
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
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
    ld h, e
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
    xor $27
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld b, d
    ld d, c
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
    xor $41
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
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, b
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
    ld d, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ccf
    ld c, a
    ld a, $4f
    ld d, [hl]
    ld h, h
    ld a, [$eff7]
    xor $2c
    ld b, e
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
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ccf
    ld c, a
    ld a, $4f
    ld d, [hl]
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, h
    ld b, d
    ld d, c
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
    ld h, d
    ld c, h
    ld c, e
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
    ld d, c
    ld b, l
    ld a, $51
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
    ld b, e
    ld c, a
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, c
    ld d, b
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
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
    ld c, l
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, d
    ld a, $62
    ld c, c
    ld c, h
    ld d, c
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, e
    ld c, h
    ld b, [hl]
    ld b, b
    ld b, d
    rst $28
    xor $50
    ld d, d
    ld b, b
    ld c, b
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
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
    ld l, b
    ld h, d
    ld b, b
    ld c, a
    ld d, [hl]
    ld h, e
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
    or $ef
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld a, $51
    ld h, d
    ld a, [hl+]
    ld b, [hl]
    ld b, h
    ld a, $4b
    ld d, c
    ld b, d
    ld d, b
    ld h, e
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
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    rst $28
    xor $2a
    ld b, [hl]
    ld b, h
    ld a, $4b
    ld d, c
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $49
    ld c, c
    ld a, [$eff7]
    xor $4d
    ld c, h
    ld d, h
    ld b, d
    ld c, a
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
    ld a, $4b
    ld b, c
    ld h, d
    ld c, e
    ld c, h
    rst $28
    xor $3f
    ld c, a
    ld a, $46
    ld c, e
    ld h, e
    rst $30
    ldh a, [$a3]
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
    jr nc, jr_01b_6b29

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
    ld [bc], a
    ld a, [$eff7]
    xor $a3
    jr nc, jr_01b_6b3e

    ld h, d
    ccf
    ld a, $3f
    ld d, [hl]
    ld h, d
    ld c, c
    ld b, d
    ld a, $4f
    ld c, e
    ld b, d
    ld b, c
    rst $28
    xor $45
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld a, $48
    ld e, a
    ld a, [$eff7]
    xor $36
    ld b, l
    ld b, d
    ld l, b
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4e
    ld d, d
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $a3
    inc l
    ld l, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a

jr_01b_6b29:
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld d, b
    ld b, l
    ld b, d
    ld l, b
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld b, [hl]

jr_01b_6b3e:
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $52
    ld c, l
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, d
    ld b, e
    ld a, $50
    ld d, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
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
    jr nc, jr_01b_6bd0

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
    inc bc
    ld a, [$eff7]
    xor $a3
    dec [hl]
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $51
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $4a
    ld a, $46
    ld c, e
    ld d, c
    ld a, $46
    ld c, e
    rst $28
    xor $41
    ld b, [hl]
    ld d, b
    ld b, b
    ld b, [hl]
    ld c, l
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld h, h
    ld a, [$eff7]
    xor $a3
    ld [hl-], a
    ld c, h
    ld c, l
    ld d, b
    ld h, e
    ld h, d

jr_01b_6bd0:
    inc l
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $4f
    ld b, d
    ld a, $41
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $4f
    ld a, $46
    ld d, b
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
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld c, h
    ld c, c
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    rst $28
    xor $4a
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld a, $4b
    ld h, d
    ld bc, $0000
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
    ld a, $50
    rst $28
    xor $4d
    ld a, $49
    ld d, b
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
    ld a, $62
    ld b, l
    ld a, $4f
    ld b, c
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, b
    ld b, d
    ld c, a
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld c, l
    ld a, $50
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    sbc a
    ld c, b
    ld b, [hl]
    ld d, b
    ld d, b
    sbc a
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
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld d, b
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
    jr z, jr_01b_6d06

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld h, d
    jr nc, @+$40

    ld b, c
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld a, $41
    ld b, d
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e

jr_01b_6d06:
    ld b, h
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld a, [hl+]
    ld a, $50
    ld b, h
    ld c, h
    ld c, e
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
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec h
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
    jr z, jr_01b_6db6

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld h, d
    ld [hl], $4d
    ld b, [hl]
    ld c, b
    ld b, d
    ld c, a
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld a, $41
    ld b, d
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e

jr_01b_6db6:
    ld b, h
    ld h, d
    ld a, $fa
    rst $30
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
    ld c, h
    ld c, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    daa
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
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    inc h
    ld c, a
    ld c, d
    ld d, [hl]
    ld h, $4f
    ld a, $3f
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
    jr z, jr_01b_6e69

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld h, d
    inc l
    ld c, a
    ld c, h
    ld c, e
    scf
    ld d, d
    ld c, a
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld a, $41
    ld b, d
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h

jr_01b_6e69:
    ld h, d
    ld a, $fa
    rst $30
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
    ld c, h
    ld c, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld b, d
    ld a, $50
    ld d, c
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    scf
    ld c, h
    ld c, a
    ld d, c
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
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
    jr z, jr_01b_6f1b

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld h, d
    ld [hl], $52
    ld c, l
    ld b, d
    ld c, a
    scf
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld a, $41
    ld b, d
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h

jr_01b_6f1b:
    ld h, d
    ld a, $fa
    rst $30
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
    ld c, h
    ld c, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld b, d
    ld a, $50
    ld d, c
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    jr nc, jr_01b_6f9e

    ld b, c
    ld c, a
    ld c, h
    ld c, e
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
    jr z, jr_01b_6fca

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ccf
    ld c, a
    ld b, d

jr_01b_6f9e:
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld h, d
    cpl
    ld a, $4b
    ld b, c
    ld [hl-], a
    ld d, h
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    rst $28
    xor $3f
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d

jr_01b_6fca:
    ld a, $fa
    rst $30
    rst $28
    xor $25
    ld d, d
    ld c, c
    ld c, c
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
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
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec h
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
    jr z, jr_01b_707a

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld h, d
    jr nc, jr_01b_709d

    ld b, c
    ld a, [hl+]
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld a, $41
    ld b, d
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h

jr_01b_707a:
    ld h, d
    ld a, $fa
    rst $30
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
    ld c, h
    ld c, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]

jr_01b_709d:
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    daa
    ld c, a
    ld c, h
    ld c, c
    ld c, c
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
    jr z, jr_01b_7127

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld h, d
    scf
    ld c, a
    ld b, d
    ld b, d
    dec h
    ld c, h
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    rst $28
    xor $3f
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d

jr_01b_7127:
    ld a, $fa
    rst $30
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
    ld c, h
    ld c, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    inc sp
    ld c, c
    ld a, $4b
    ld d, c
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    inc sp
    ld b, [hl]
    ld d, l
    ld d, [hl]
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
    jr z, jr_01b_71d2

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld c, e
    ld h, d
    ld [hl-], a
    ld c, e
    ld b, [hl]
    ld c, h
    ld c, e
    ld c, h
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    rst $28
    xor $3f
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d

jr_01b_71d2:
    ld a, $fa
    rst $30
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
    ld c, h
    ld c, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    inc sp
    ld c, c
    ld a, $4b
    ld d, c
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld a, [hl+]
    ld c, h
    ld c, l
    ld b, l
    ld b, d
    ld b, b
    ld a, $41
    ld a, $5f
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
    jr z, jr_01b_7283

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld h, d
    ld a, [hl+]
    ld b, [hl]
    ld a, $4b
    ld d, c
    jr nc, jr_01b_72b9

    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld a, $41
    ld b, d
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e

jr_01b_7283:
    ld b, h
    ld h, d
    ld a, $fa
    rst $30
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
    ld c, h
    ld c, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld d, d
    ld b, h
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld [hl], $3e
    ld b, b
    ld b, b
    ld b, d
    ld c, a
    ld e, a
    rst $28

jr_01b_72b9:
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
    jr z, jr_01b_7331

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld c, e
    ld h, d
    inc h
    ld c, a
    ld c, d
    ld d, [hl]
    ld h, $4f
    ld a, $3f
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld a, $41
    ld b, d
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e

jr_01b_7331:
    ld b, h
    ld h, d
    ld a, $fa
    rst $30
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
    ld c, h
    ld c, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld d, d
    ld b, h
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    daa
    ld a, $4f
    ld c, b
    ld h, $4f
    ld a, $3f
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
    jr z, jr_01b_73e1

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld c, e
    ld h, d
    ld [hl-], a
    ld b, h
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    rst $28
    xor $3f
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $fa

jr_01b_73e1:
    rst $30
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
    ld c, h
    ld c, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    daa
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
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    dec hl
    ld a, $4a
    ld c, d
    ld b, d
    ld c, a
    jr nc, jr_01b_7453

    ld c, e
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
    jr z, jr_01b_7490

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d

jr_01b_7453:
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld h, d
    ld a, [hl+]
    ld c, h
    ld a, $51
    dec hl
    ld c, h
    ld c, a
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld a, $41
    ld b, d
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h

jr_01b_7490:
    ld h, d
    ld a, $fa
    rst $30
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
    ld c, h
    ld c, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    daa
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
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
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
    jr z, @+$55

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
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld h, d
    jr nc, jr_01b_7578

    ld b, c
    ld c, a
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    rst $28
    xor $3f
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $fa
    rst $30
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
    ld c, h
    ld c, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec a
    ld c, h
    ld c, d
    ccf
    ld b, [hl]
    ld b, d
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld a, [hl+]
    ld b, [hl]
    ld a, $4b
    ld d, c
    ld [hl], $49
    ld d, d
    ld b, h

jr_01b_7578:
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
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
