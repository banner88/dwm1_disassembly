; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $058", ROMX[$4000], BANK[$58]

    db $58 ; Bank number

    ; Cross-bank dispatch table (245 entries)
    ; Called via: ld hl, $58XX / rst $10
    dw $53CF                          ; Entry 0
    dw $5749                          ; Entry 1
    dw ClrBtlFX_5955                  ; Entry 2
    dw $59DC                          ; Entry 3
    dw $6379                          ; Entry 4
    dw LoadBtlFX_642c                  ; Entry 5
    dw $57C5                          ; Entry 6
    dw $57A4                          ; Entry 7
    dw LoadBtlFX_5498                  ; Entry 8
    dw $591E                          ; Entry 9
    dw $41E9                          ; Entry 10
    dw $67BA                          ; Entry 11
    dw $5C48                          ; Entry 12
    dw $6737                          ; Entry 13
    dw $5069                          ; Entry 14
    dw $5069                          ; Entry 15
    dw $5069                          ; Entry 16
    dw Jump_058_62bf                  ; Entry 17
    dw Jump_058_62bf                  ; Entry 18
    dw Jump_058_62bf                  ; Entry 19
    dw Jump_058_62bf                  ; Entry 20
    dw Jump_058_62bf                  ; Entry 21
    dw Jump_058_62bf                  ; Entry 22
    dw Jump_058_62bf                  ; Entry 23
    dw Jump_058_62bf                  ; Entry 24
    dw Jump_058_62bf                  ; Entry 25
    dw Jump_058_62bf                  ; Entry 26
    dw Jump_058_62bf                  ; Entry 27
    dw Jump_058_62bf                  ; Entry 28
    dw Jump_058_62bf                  ; Entry 29
    dw Jump_058_62bf                  ; Entry 30
    dw Jump_058_62bf                  ; Entry 31
    dw $4FD2                          ; Entry 32
    dw Jump_058_62bf                  ; Entry 33
    dw Jump_058_62bf                  ; Entry 34
    dw $5211                          ; Entry 35
    dw Jump_058_62bf                  ; Entry 36
    dw Jump_058_62bf                  ; Entry 37
    dw Jump_058_62bf                  ; Entry 38
    dw Jump_058_62bf                  ; Entry 39
    dw $52A9                          ; Entry 40
    dw $6367                          ; Entry 41
    dw $4854                          ; Entry 42
    dw Jump_058_62bf                  ; Entry 43
    dw $474B                          ; Entry 44
    dw $62CD                          ; Entry 45
    dw $48AB                          ; Entry 46
    dw Jump_058_62bf                  ; Entry 47
    dw $490E                          ; Entry 48
    dw $62CD                          ; Entry 49
    dw $62CD                          ; Entry 50
    dw $470B                          ; Entry 51
    dw $62CD                          ; Entry 52
    dw $6367                          ; Entry 53
    dw $6367                          ; Entry 54
    dw $4ED8                          ; Entry 55
    dw $62CD                          ; Entry 56
    dw $44F7                          ; Entry 57
    dw $44F7                          ; Entry 58
    dw $44F7                          ; Entry 59
    dw $62CD                          ; Entry 60
    dw $62CD                          ; Entry 61
    dw $469E                          ; Entry 62
    dw $469E                          ; Entry 63
    dw $635F                          ; Entry 64
    dw $46C7                          ; Entry 65
    dw $62CD                          ; Entry 66
    dw $62CD                          ; Entry 67
    dw $62CD                          ; Entry 68
    dw $41E9                          ; Entry 69
    dw $41E9                          ; Entry 70
    dw $63D6                          ; Entry 71
    dw $41E9                          ; Entry 72
    dw $41E9                          ; Entry 73
    dw $5100                          ; Entry 74
    dw $41E9                          ; Entry 75
    dw $5100                          ; Entry 76
    dw $6379                          ; Entry 77
    dw $41E9                          ; Entry 78
    dw $6367                          ; Entry 79
    dw LoadBtlFX_642c                  ; Entry 80
    dw $6367                          ; Entry 81
    dw $5339                          ; Entry 82
    dw $5352                          ; Entry 83
    dw $536B                          ; Entry 84
    dw $5384                          ; Entry 85
    dw $4D1A                          ; Entry 86
    dw $4D5D                          ; Entry 87
    dw $4D6D                          ; Entry 88
    dw $4D7D                          ; Entry 89
    dw $4D8D                          ; Entry 90
    dw $4D9D                          ; Entry 91
    dw $4DAD                          ; Entry 92
    dw Jump_058_62bf                  ; Entry 93
    dw $41E9                          ; Entry 94
    dw LoadBtlFX_642c                  ; Entry 95
    dw LoadBtlFX_642c                  ; Entry 96
    dw LoadBtlFX_642c                  ; Entry 97
    dw $63D6                          ; Entry 98
    dw $41E9                          ; Entry 99
    dw $41E9                          ; Entry 100
    dw Jump_058_62bf                  ; Entry 101
    dw $539D                          ; Entry 102
    dw Jump_058_62bf                  ; Entry 103
    dw Jump_058_62bf                  ; Entry 104
    dw Jump_058_62bf                  ; Entry 105
    dw Jump_058_62bf                  ; Entry 106
    dw Jump_058_62bf                  ; Entry 107
    dw Jump_058_62bf                  ; Entry 108
    dw Jump_058_62bf                  ; Entry 109
    dw Jump_058_62bf                  ; Entry 110
    dw Jump_058_62bf                  ; Entry 111
    dw Jump_058_62bf                  ; Entry 112
    dw Jump_058_62bf                  ; Entry 113
    dw Jump_058_62bf                  ; Entry 114
    dw Jump_058_62bf                  ; Entry 115
    dw Jump_058_62bf                  ; Entry 116
    dw $4DED                          ; Entry 117
    dw $4C85                          ; Entry 118
    dw $4E39                          ; Entry 119
    dw Jump_058_62bf                  ; Entry 120
    dw Jump_058_62bf                  ; Entry 121
    dw Jump_058_62bf                  ; Entry 122
    dw Jump_058_62bf                  ; Entry 123
    dw Jump_058_62bf                  ; Entry 124
    dw Jump_058_62bf                  ; Entry 125
    dw $4E85                          ; Entry 126
    dw Jump_058_62bf                  ; Entry 127
    dw Jump_058_62bf                  ; Entry 128
    dw Jump_058_62bf                  ; Entry 129
    dw Jump_058_62bf                  ; Entry 130
    dw $4CD1                          ; Entry 131
    dw $4CD1                          ; Entry 132
    dw $6367                          ; Entry 133
    dw Jump_058_62bf                  ; Entry 134
    dw $4E85                          ; Entry 135
    dw $4B74                          ; Entry 136
    dw $4C24                          ; Entry 137
    dw Jump_058_62bf                  ; Entry 138
    dw Jump_058_62bf                  ; Entry 139
    dw $41E9                          ; Entry 140
    dw $6367                          ; Entry 141
    dw Jump_058_62bf                  ; Entry 142
    dw $62CD                          ; Entry 143
    dw $4A21                          ; Entry 144
    dw $62FD                          ; Entry 145
    dw $63D6                          ; Entry 146
    dw $63D6                          ; Entry 147
    dw $63D6                          ; Entry 148
    dw $63D6                          ; Entry 149
    dw $4ABA                          ; Entry 150
    dw $62CD                          ; Entry 151
    dw $6367                          ; Entry 152
    dw $62CD                          ; Entry 153
    dw $6367                          ; Entry 154
    dw $6367                          ; Entry 155
    dw $6367                          ; Entry 156
    dw $62CD                          ; Entry 157
    dw $6367                          ; Entry 158
    dw Jump_058_62bf                  ; Entry 159
    dw $4B26                          ; Entry 160
    dw $6367                          ; Entry 161
    dw $62CD                          ; Entry 162
    dw $635F                          ; Entry 163
    dw $635F                          ; Entry 164
    dw $6367                          ; Entry 165
    dw $6367                          ; Entry 166
    dw LoadBtlFX_6479                  ; Entry 167
    dw LoadBtlFX_642c                  ; Entry 168
    dw $6367                          ; Entry 169
    dw $6367                          ; Entry 170
    dw $6367                          ; Entry 171
    dw LoadBtlFX_642c                  ; Entry 172
    dw $6367                          ; Entry 173
    dw $6367                          ; Entry 174
    dw $6367                          ; Entry 175
    dw $62FD                          ; Entry 176
    dw $62CD                          ; Entry 177
    dw Jump_058_62bf                  ; Entry 178
    dw $62FD                          ; Entry 179
    dw $62CD                          ; Entry 180
    dw Jump_058_62bf                  ; Entry 181
    dw Jump_058_62bf                  ; Entry 182
    dw $6367                          ; Entry 183
    dw $6367                          ; Entry 184
    dw Jump_058_62bf                  ; Entry 185
    dw Jump_058_62bf                  ; Entry 186
    dw $635F                          ; Entry 187
    dw $62CD                          ; Entry 188
    dw Jump_058_62bf                  ; Entry 189
    dw $63D6                          ; Entry 190
    dw $63D6                          ; Entry 191
    dw $63D6                          ; Entry 192
    dw $63D6                          ; Entry 193
    dw $63D6                          ; Entry 194
    dw $63D6                          ; Entry 195
    dw $63D6                          ; Entry 196
    dw $63D6                          ; Entry 197
    dw $63D6                          ; Entry 198
    dw $63D6                          ; Entry 199
    dw $63D6                          ; Entry 200
    dw $63D6                          ; Entry 201
    dw $63D6                          ; Entry 202
    dw $63D6                          ; Entry 203
    dw $63D6                          ; Entry 204
    dw $63D6                          ; Entry 205
    dw $63D6                          ; Entry 206
    dw $63D6                          ; Entry 207
    dw $63D6                          ; Entry 208
    dw $63D6                          ; Entry 209
    dw $63D6                          ; Entry 210
    dw $63D6                          ; Entry 211
    dw $63D6                          ; Entry 212
    dw $63D6                          ; Entry 213
    dw $63D6                          ; Entry 214
    dw $63D6                          ; Entry 215
    dw $63D6                          ; Entry 216
    dw $63D6                          ; Entry 217
    dw $63D6                          ; Entry 218
    dw $63D6                          ; Entry 219
    dw $63D6                          ; Entry 220
    dw $63D6                          ; Entry 221
    dw $63D6                          ; Entry 222
    dw $63D6                          ; Entry 223
    dw $63D6                          ; Entry 224
    dw $63D6                          ; Entry 225
    dw $63D6                          ; Entry 226
    dw $6367                          ; Entry 227
    dw $4DBD                          ; Entry 228
    dw $4DCD                          ; Entry 229
    dw $4DDD                          ; Entry 230
    dw $53B6                          ; Entry 231
    dw $5164                          ; Entry 232
    dw $6367                          ; Entry 233
    dw $6367                          ; Entry 234
    dw $41E9                          ; Entry 235
    dw $6367                          ; Entry 236
    dw $6367                          ; Entry 237
    dw $6367                          ; Entry 238
    dw $6367                          ; Entry 239
    dw $6367                          ; Entry 240
    dw $6367                          ; Entry 241
    dw $6367                          ; Entry 242
    dw $6367                          ; Entry 243
    ; NOTE: last 1 entry/entries (2B) merged into following instruction

    ld hl, $db56
    ld bc, $0008
    xor a
    call FillNBytesWithRegA
    call CallBtlFX_654d
    ret z

    ld a, [$c86c]
    or a
    jp nz, Jump_058_4206

    ld a, [wBattleAttackerIdx]
    cp $04
    jp nc, Jump_058_441b

Jump_058_4206:
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld [wBattleTargetIdx], a
    ld b, $03
    ld c, a

jr_058_4213:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_421e

    call SaveBtlFX_660d
    jr c, jr_058_4228

jr_058_421e:
    inc c
    dec b
    jr nz, jr_058_4213

    call LoadBtlFX_432c
    jp Jump_058_431a


jr_058_4228:
    ld b, $03
    ld a, [wBattleTargetIdx]
    ld c, a

jr_058_422e:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_4239

    call SetBtlFX_43ea
    jr z, jr_058_4243

jr_058_4239:
    inc c
    dec b
    jr nz, jr_058_422e

    call LoadBtlFX_4384
    jp Jump_058_431a


jr_058_4243:
    ld a, [wBattleAttackerIdx]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $02
    jr nz, jr_058_4270

    ld b, $03
    ld a, [wBattleTargetIdx]
    ld c, a

jr_058_425a:
    ld a, c
    call SetBtlFX_43ea
    jr nz, jr_058_4266

    ld a, c
    call GetMonsterSlotInfo
    jr nc, jr_058_42c6

jr_058_4266:
    inc c
    dec b
    jr nz, jr_058_425a

    call LoadBtlFX_4384
    jp Jump_058_431a


jr_058_4270:
    ld b, $03
    ld a, [wBattleTargetIdx]
    ld c, a

jr_058_4276:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_42a6

    call SetBtlFX_43ea
    jr nz, jr_058_42a6

    call SaveBtlFX_43ff
    ld a, c
    call GetCombatantHP
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    jr nc, jr_058_429c

    ld hl, $0000

jr_058_429c:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    jr jr_058_42ae

jr_058_42a6:
    ld a, $ff
    ld [$db56], a
    ld [$db57], a

jr_058_42ae:
    pop bc
    call LoadBtlFX_4fa7
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call LoadBtlFX_43d7
    inc c
    dec b
    jr nz, jr_058_4276

    call LoadBtlFX_433e
    jr jr_058_431a

jr_058_42c6:
    ld b, $03
    ld a, [wBattleTargetIdx]
    ld c, a

jr_058_42cc:
    push bc
    ld a, c
    call GetMonsterSlotInfo
    jr c, jr_058_42fc

    call SetBtlFX_43ea
    jr nz, jr_058_42fc

    call SaveBtlFX_43ff
    ld a, c
    call GetCombatantHP
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    jr nc, jr_058_42f2

    ld hl, $0000

jr_058_42f2:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    jr jr_058_4304

jr_058_42fc:
    ld a, $ff
    ld [$db56], a
    ld [$db57], a

jr_058_4304:
    pop bc
    call LoadBtlFX_4fa7
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call LoadBtlFX_43d7
    inc c
    dec b
    jr nz, jr_058_42cc

    call LoadBtlFX_433e

Jump_058_431a:
jr_058_431a:
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


LoadBtlFX_432c:
    ld a, $00
    ld [$db63], a
    ld b, $03
    ld a, [wBattleTargetIdx]
    ld c, a

jr_058_4337:
    call LoadBtlFX_43aa
    inc c
    dec b
    jr nz, jr_058_4337

LoadBtlFX_433e:
    ld a, $00
    ld [$db61], a
    ld a, [$db58]
    ld c, a
    ld a, [$db59]
    ld b, a
    ld de, $0201

jr_058_434e:
    ld a, e
    ld hl, $db58
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    jr z, jr_058_436b

    jr nc, jr_058_4375

jr_058_4363:
    ld b, h
    ld c, l
    ld a, e
    ld [$db61], a
    jr jr_058_4375

jr_058_436b:
    call LoadBtlFX_5c3e
    ld a, [wRNG1]
    bit 1, a
    jr z, jr_058_4363

jr_058_4375:
    inc e
    dec d
    jr nz, jr_058_434e

    ld hl, wBattleTargetIdx
    ld a, [$db61]
    add [hl]
    ld [wBattleTargetIdx], a
    ret


LoadBtlFX_4384:
    ld a, $01
    ld [$db63], a
    ld b, $03
    ld a, [wBattleTargetIdx]
    ld c, a

jr_058_438f:
    ld a, c
    ld hl, $db06
    call HL_AddA_x8
    bit 2, [hl]
    jr nz, jr_058_439f

    call LoadBtlFX_43aa
    jr jr_058_43a2

jr_058_439f:
    call SetBtlFX_43d4

jr_058_43a2:
    inc c
    dec b
    jr nz, jr_058_438f

    call LoadBtlFX_433e
    ret


LoadBtlFX_43aa:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_43d4

    call GetCombatantHP
    push hl
    ld a, c
    call GetCombatantDEF
    ld a, [$db63]
    or a
    jr z, jr_058_43d0

    push hl
    ld a, c
    ld hl, $db08
    call HL_AddA_x8
    ld a, [hl]
    pop hl
    bit 2, a
    jr z, jr_058_43d0

    srl h
    rr l

jr_058_43d0:
    pop de
    add hl, de
    jr jr_058_43d7

SetBtlFX_43d4:
jr_058_43d4:
    ld hl, $ffff

LoadBtlFX_43d7:
jr_058_43d7:
    ld a, c
    and $03
    add a
    ld de, $db58
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, l
    ld [de], a
    inc de
    ld a, h
    ld [de], a
    ret


SetBtlFX_43ea:
    ld hl, $db06
    call HL_AddA_x8
    bit 2, [hl]
    jr nz, jr_058_43fe

    inc hl
    inc hl
    ld a, [hl+]
    and $20
    jr nz, jr_058_43fe

    ld a, [hl]
    and $07

jr_058_43fe:
    ret


SaveBtlFX_43ff:
    push bc
    ld a, [$db8a]
    cp $37
    jr c, jr_058_4415

    cp $d9
    jr z, jr_058_4415

    cp $dd
    jr z, jr_058_4415

    ld hl, $5203
    rst $10
    jr jr_058_4419

jr_058_4415:
    ld hl, $5403
    rst $10

jr_058_4419:
    pop bc
    ret


CallBtlFX_441b:
Jump_058_441b:
    call CallBtlFX_654d
    ret z

    ld a, [wBattleAttackerIdx]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $02
    jr z, jr_058_448a

    call CallBtlFX_5e5b
    call SetBtlFX_5e75

ClrBtlFX_4436:
    xor a
    ld [wBattleTargetIdx], a

jr_058_443a:
    ld a, d
    dec a
    rst $00
    ld h, e
    ld b, h
    ld d, e
    ld b, h
    ld b, e
    ld b, h
    push bc
    call LoadBtlFX_5c3e
    pop bc
    ld a, [wRNG1]
    cp $80
    jr c, jr_058_4463

    ld hl, wBattleTargetIdx
    inc [hl]
    push bc
    call LoadBtlFX_5c3e
    pop bc
    ld a, [wRNG1]
    cp $aa
    jr c, jr_058_4463

    ld hl, wBattleTargetIdx
    inc [hl]

jr_058_4463:
    ld hl, $db4c
    ld a, [wBattleTargetIdx]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [wBattleTargetIdx], a
    call CheckMonsterSlot
    jr c, jr_058_443a

    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


jr_058_448a:
    call SetBtlFX_5e19

jr_058_448d:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_44b2

    ld a, c
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld a, c
    call GetCombatantDEF
    srl h
    rr l
    srl d
    rr e
    add hl, de
    ld d, h
    ld e, l
    jr jr_058_44b5

jr_058_44b2:
    ld de, $ffff

jr_058_44b5:
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ld a, l
    ld [$db5e], a
    ld a, h
    ld [$db5f], a
    inc c
    dec b
    jr nz, jr_058_448d

    call CallBtlFX_5e5b
    call SetBtlFX_5e75
    ld a, d
    cp $02
    jr c, jr_058_44f3

    push af
    push bc
    push de
    push hl
    call ClrBtlFX_5e81
    pop hl
    pop de
    pop bc
    pop af
    ld a, d
    cp $03
    jr c, jr_058_44f3

    push af
    push bc
    push de
    push hl
    call CallBtlFX_5ebf
    pop hl
    pop de
    pop bc
    pop af

jr_058_44f3:
    call ClrBtlFX_4436
    ret


    call CallBtlFX_6556
    ret z

    ld a, [wBattleAttackerIdx]
    and $04
    ld e, a
    ld d, $03
    ld a, [wBattleAttackerIdx]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $02
    jp z, Jump_058_4591

Jump_058_4515:
jr_058_4515:
    ld a, e
    ld [$db4f], a
    ld a, d
    ld [$db50], a
    ld a, e
    call CheckMonsterSlot
    jr nc, jr_058_452b

    ld bc, $0000
    ld hl, $0000
    jr jr_058_454d

jr_058_452b:
    ld a, e
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, e
    call GetCombatantMaxHP
    call CmpHLvsBC
    jr nz, jr_058_454a

    ld bc, $0001
    ld hl, $0000
    jr jr_058_454d

jr_058_454a:
    call Div16x16To16

jr_058_454d:
    push hl
    ld a, [$db4f]
    ld e, a
    ld a, [$db50]
    ld d, a
    ld a, $03
    sub d
    ld hl, $db61
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, c
    ld [hl+], a
    ld [hl], b
    pop hl
    ld b, h
    ld c, l
    ld a, [$db4f]
    ld e, a
    ld a, [$db50]
    ld d, a
    ld a, $03
    sub d
    ld hl, $db58
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [$db4f]
    ld e, a
    ld a, [$db50]
    ld d, a
    inc e
    dec d
    jr nz, jr_058_4515

    call LoadBtlFX_665a
    ret


Jump_058_4591:
    xor a
    ld [$db4c], a
    ld b, d
    ld c, e
    xor a
    ld hl, $db51
    ld [hl+], a
    ld [hl+], a
    ld [hl], a

jr_058_459e:
    ld a, c
    ld [$db4f], a
    ld a, b
    ld [$db50], a
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_45e1

    ld hl, $db4c
    inc [hl]
    ld a, c
    call GetCombatantMaxHP
    ld a, c
    ld de, $db8b
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    bit 0, a
    jr z, jr_058_45ca

    ld a, $1e
    call Mul16x8To24
    jr jr_058_45cc

jr_058_45ca:
    ld e, $00

jr_058_45cc:
    ld a, [$db51]
    add l
    ld [$db51], a
    ld a, [$db52]
    adc h
    ld [$db52], a
    ld a, [$db53]
    adc e
    ld [$db53], a

jr_058_45e1:
    ld a, [$db4f]
    ld c, a
    ld a, [$db50]
    ld b, a
    inc c
    dec b
    jr nz, jr_058_459e

    ld a, [$db51]
    ld l, a
    ld a, [$db52]
    ld h, a
    ld a, [$db53]
    ld e, a
    ld a, [$db4c]
    call Div24x8To16
    ld a, [$db4c]
    call Div24x8To16
    ld a, l
    ld [$db61], a
    ld a, h
    ld [$db62], a
    ld a, [wBattleAttackerIdx]
    and $04
    ld e, a
    ld d, $03
    ld a, $ff
    ld [$db4e], a

jr_058_461a:
    ld a, e
    ld [$db4c], a
    ld a, d
    ld [$db4d], a
    ld a, e
    call CheckMonsterSlot
    jr c, jr_058_466e

    ld a, e
    ld hl, wBattleMaxHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, e
    call GetCombatantHP
    call CmpHLvsBC
    jr z, jr_058_466e

    ld a, [$db61]
    ld c, a
    ld a, [$db62]
    ld b, a
    call CmpHLvsBC
    jr z, jr_058_465e

    jr nc, jr_058_466e

    ld a, l
    ld [$db61], a
    ld a, h
    ld [$db62], a
    ld a, [$db4c]
    ld [$db4e], a
    jr jr_058_466e

jr_058_465e:
    call LoadBtlFX_5c3e
    ld a, [wRNG1]
    cp $80
    jr c, jr_058_466e

    ld a, [$db4c]
    ld [$db4e], a

jr_058_466e:
    ld a, [$db4c]
    ld e, a
    ld a, [$db4d]
    ld d, a
    inc e
    dec d
    jr nz, jr_058_461a

    ld a, [$db4e]
    cp $ff
    jr z, jr_058_4693

    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$db4e]
    ld [hl], a
    ret


jr_058_4693:
    ld a, [wBattleAttackerIdx]
    and $04
    ld e, a
    ld d, $03
    jp Jump_058_4515


    ld a, [wBattleAttackerIdx]
    and $04
    or $02
    ld c, a
    ld b, $03

jr_058_46a8:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_058_46b0

    jr nz, jr_058_46b8

jr_058_46b0:
    dec c
    dec b
    jr nz, jr_058_46a8

    ld a, [wBattleAttackerIdx]
    ld c, a

jr_058_46b8:
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], c
    ret


    call CallBtlFX_6556
    ret z

    ld a, [wBattleAttackerIdx]
    and $04
    or $02
    ld c, a
    ld [wBattleTargetIdx], a
    ld b, $03

jr_058_46d8:
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 1, [hl]
    jr nz, jr_058_46fc

    dec c
    dec b
    jr nz, jr_058_46d8

    ld a, [wBattleTargetIdx]
    ld c, a
    ld b, $02

jr_058_46ed:
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 0, [hl]
    jr nz, jr_058_46fc

    dec c
    dec b
    jr nz, jr_058_46ed

jr_058_46fc:
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], c
    ret


    call CallBtlFX_6556
    ret z

    call SetBtlFX_627c
    ld a, c
    xor $04
    ld c, a

jr_058_4716:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_473a

    ld de, $0001
    ld a, c
    ld hl, $db03
    call HL_AddA_x8
    bit 2, [hl]
    jr nz, jr_058_473d

    ld a, c
    ld hl, wBattleATK
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    jr jr_058_473d

jr_058_473a:
    ld de, $0000

jr_058_473d:
    call LoadBtlFX_6292
    inc c
    dec b
    jr nz, jr_058_4716

    call SetBtlFX_619a
    call LoadBtlFX_6188
    ret


    call CallBtlFX_6556
    ret z

    ld hl, $db61
    ld a, l
    ld [$db4c], a
    ld a, h
    ld [$db4d], a
    ld a, [wBattleAttackerIdx]
    and $04
    ld [$db4e], a
    ld b, $03

jr_058_4764:
    push bc
    ld a, [$db4e]
    call CheckMonsterSlot
    jr c, jr_058_47ad

    ld a, [$db4e]
    call SaveBtlFX_5c96
    ld a, [$db4e]
    call GetCombatantDEF
    ld a, [$c86c]
    or a
    jr nz, jr_058_4786

    ld a, [wBattleAttackerIdx]
    cp $04
    jr nc, jr_058_4795

jr_058_4786:
    ld a, [$db4e]
    and $03
    cp $03
    cp $03
    jr z, jr_058_4795

    sla c
    rl b

jr_058_4795:
    sla c
    rl b
    call CmpHLvsBC
    jr nc, jr_058_47a8

    ld bc, $03e7
    call CmpHLvsBC
    jr nc, jr_058_47a8

    jr jr_058_47b0

jr_058_47a8:
    ld hl, $fffe
    jr jr_058_47b0

jr_058_47ad:
    ld hl, $ffff

jr_058_47b0:
    push hl
    pop de
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    ld [hl], e
    inc hl
    ld [hl], d
    inc hl
    ld a, l
    ld [$db4c], a
    ld a, h
    ld [$db4d], a
    pop bc
    ld hl, $db4e
    inc [hl]
    dec b
    jr nz, jr_058_4764

    ld hl, $db61
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $db63
    ld a, l
    ld [$db4c], a
    ld a, h
    ld [$db4d], a
    ld a, [wBattleAttackerIdx]
    and $04
    ld [$db4e], a
    inc a
    ld [$db4f], a
    ld a, $02
    ld [$db50], a

jr_058_47f0:
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    jr c, jr_058_4814

    jr nz, jr_058_481c

    push af
    push bc
    push de
    push hl
    call LoadBtlFX_5c3e
    pop hl
    pop de
    pop bc
    pop af
    ld a, [wRNG1]
    cp $80
    jr c, jr_058_481c

jr_058_4814:
    push hl
    pop bc
    ld a, [$db4f]
    ld [$db4e], a

jr_058_481c:
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    inc hl
    inc hl
    ld a, l
    ld [$db4c], a
    ld a, h
    ld [$db4d], a
    ld hl, $db4f
    inc [hl]
    ld hl, $db50
    dec [hl]
    ld a, [$db50]
    or a
    jr nz, jr_058_47f0

    ld a, [$db4e]
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c

jr_058_485b:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_489c

    ld de, $0001
    ld a, c
    call GetCombatantDEF
    cp $01
    jr c, jr_058_489f

    jr nz, jr_058_4873

    ld a, h
    or a
    jr z, jr_058_489f

jr_058_4873:
    inc de
    push hl
    ld a, c
    ld hl, $db04
    call HL_AddA_x8
    ld a, [hl]
    pop hl
    and $22
    jr nz, jr_058_489f

    push hl
    ld a, $03
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    ld a, [$db4c]
    xor $30
    and $30
    pop de
    or d
    ld d, a
    jr jr_058_489f

jr_058_489c:
    ld de, $0000

jr_058_489f:
    call LoadBtlFX_6292
    pop bc
    inc c
    dec b
    jr nz, jr_058_485b

    call SetBtlFX_619a
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c

jr_058_48b2:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_48ff

    ld de, $0001
    ld a, c
    ld hl, wBattleAGL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    cp $01
    jr c, jr_058_4902

    jr nz, jr_058_48d4

    ld h, a
    or a
    jr z, jr_058_4902

jr_058_48d4:
    inc de
    push hl
    ld a, c
    ld hl, $db04
    call HL_AddA_x8
    ld a, [hl]
    pop hl
    and $22
    jr nz, jr_058_4902

    push hl
    ld a, $03
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    ld a, [$db4c]
    rlca
    rlca
    xor $30
    and $30
    pop de
    or d
    ld d, a
    jr jr_058_4902

jr_058_48ff:
    ld de, $0000

jr_058_4902:
    call LoadBtlFX_6292
    pop bc
    inc c
    dec b
    jr nz, jr_058_48b2

    call SetBtlFX_619a
    ret


    call CallBtlFX_6556
    ret z

    ld hl, $db61
    ld a, l
    ld [$db4c], a
    ld a, h
    ld [$db4d], a
    ld a, [wBattleAttackerIdx]
    and $04
    ld [$db4e], a
    ld b, $03

jr_058_4927:
    push bc
    ld a, [$db4e]
    call CheckMonsterSlot
    jr c, jr_058_497a

    ld a, [$db4e]
    call SaveBtlFX_60f3
    ld a, [$db4e]
    ld hl, wBattleAGL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push bc
    ld bc, $01ff
    call CmpHLvsBC
    pop bc
    jr nc, jr_058_4975

    ld a, [$c86c]
    or a
    jr nz, jr_058_495d

    ld a, [wBattleAttackerIdx]
    cp $04
    jr nc, jr_058_496a

jr_058_495d:
    ld a, [$db4e]
    and $03
    cp $03
    jr z, jr_058_496a

    sla c
    rl b

jr_058_496a:
    sla c
    rl b
    call CmpHLvsBC
    jr nc, jr_058_4975

    jr jr_058_497d

jr_058_4975:
    ld hl, $fffe
    jr jr_058_497d

jr_058_497a:
    ld hl, $ffff

jr_058_497d:
    push hl
    pop de
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    ld [hl], e
    inc hl
    ld [hl], d
    inc hl
    ld a, l
    ld [$db4c], a
    ld a, h
    ld [$db4d], a
    pop bc
    ld hl, $db4e
    inc [hl]
    dec b
    jr nz, jr_058_4927

    ld hl, $db61
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $db63
    ld a, l
    ld [$db4c], a
    ld a, h
    ld [$db4d], a
    ld a, [wBattleAttackerIdx]
    and $04
    ld [$db4e], a
    inc a
    ld [$db4f], a
    ld a, $02
    ld [$db50], a

jr_058_49bd:
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    jr c, jr_058_49e1

    jr nz, jr_058_49e9

    push af
    push bc
    push de
    push hl
    call LoadBtlFX_5c3e
    pop hl
    pop de
    pop bc
    pop af
    ld a, [wRNG1]
    cp $80
    jr c, jr_058_49e9

jr_058_49e1:
    push hl
    pop bc
    ld a, [$db4f]
    ld [$db4e], a

jr_058_49e9:
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    inc hl
    inc hl
    ld a, l
    ld [$db4c], a
    ld a, h
    ld [$db4d], a
    ld hl, $db4f
    inc [hl]
    ld hl, $db50
    dec [hl]
    ld a, [$db50]
    or a
    jr nz, jr_058_49bd

    ld a, [$db4e]
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


    call CallBtlFX_654d
    ret z

    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a
    ld b, $03
    push bc
    xor a
    ld hl, $db50
    ld [hl+], a
    ld [hl+], a
    ld [hl], a

jr_058_4a37:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_4a8d

    ld a, c
    ld hl, wBattleAGL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call LoadBtlFX_60e0
    jr c, jr_058_4a7c

    ld a, c
    call GetCombatantDEF
    call LoadBtlFX_60e0
    jr c, jr_058_4a7c

    push bc
    ld a, $02
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$db4c]
    and $30
    ld [hl], a
    jr jr_058_4a9c

jr_058_4a7c:
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fe
    ld [hl], a
    jr jr_058_4a9c

jr_058_4a8d:
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    ld [hl], a

jr_058_4a9c:
    inc c
    dec b
    jr nz, jr_058_4a37

    pop bc
    ld a, c
    ld [$db4c], a
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$db4d], a
    inc c
    dec b
    call LoadBtlFX_5f0c
    ret


    call CallBtlFX_6556
    ret z

    ld a, [wBattleAttackerIdx]
    and $04
    ld [wBattleTargetIdx], a
    ld c, a
    ld b, $03

jr_058_4ac9:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_4af0

    ld a, [wBattleAttackerIdx]
    cp c
    jr z, jr_058_4af0

    ld a, c
    call GetCombatantHP
    push hl
    ld a, c
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 0, [hl]
    pop hl
    jr z, jr_058_4af3

    ld bc, $0200
    add hl, bc
    jr jr_058_4af3

jr_058_4af0:
    ld hl, $ffff

jr_058_4af3:
    ld d, h
    ld e, l
    pop bc
    ld a, c
    and $03
    ld hl, $db58
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, e
    ld [hl+], a
    ld [hl], d
    inc c
    dec b
    jr nz, jr_058_4ac9

    call LoadBtlFX_6224
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    push hl
    call CheckMonsterSlot
    pop hl
    ret nc

    ld a, [wBattleAttackerIdx]
    ld [hl], a
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c

jr_058_4b2d:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_4b65

    ld de, $0001
    ld a, c
    call SetBtlFX_656e
    jr nc, jr_058_4b68

    ld a, c
    ld hl, $db03
    call HL_AddA_x8
    bit 7, [hl]
    jr nz, jr_058_4b68

    ld de, $00ff
    push de
    ld a, $06
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    ld a, [$db4c]
    xor $c0
    and $c0
    pop de
    or d
    ld d, a
    jr jr_058_4b68

jr_058_4b65:
    ld de, $0000

jr_058_4b68:
    call LoadBtlFX_6292
    pop bc
    inc c
    dec b
    jr nz, jr_058_4b2d

    call SetBtlFX_619a
    ret


    call CallBtlFX_654d
    ret z

    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a
    ld b, $03
    push bc
    xor a
    ld hl, $db50
    ld [hl+], a
    ld [hl+], a
    ld [hl], a

Jump_058_4b8a:
    push bc
    ld a, c
    call CheckMonsterSlot
    pop bc
    jr c, jr_058_4bf8

    ld a, c
    call GetCombatantDEF
    cp $01
    jr c, jr_058_4bd6

    jr nz, jr_058_4ba0

    ld a, h
    or a
    jr z, jr_058_4bd6

jr_058_4ba0:
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl+]
    and $c0
    jr nz, jr_058_4be7

    inc hl
    inc hl
    ld a, [hl]
    and $3f
    jr nz, jr_058_4be7

    push bc
    ld a, $03
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$db4c]
    and $30
    ld [hl], a
    jr jr_058_4c07

jr_058_4bd6:
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fd
    ld [hl], a
    jr jr_058_4c07

jr_058_4be7:
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fe
    ld [hl], a
    jr jr_058_4c07

jr_058_4bf8:
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    ld [hl], a

jr_058_4c07:
    inc c
    dec b
    jp nz, Jump_058_4b8a

    pop bc
    ld a, c
    ld [$db4c], a
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$db4d], a
    call LoadBtlFX_5f0c
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c

jr_058_4c2b:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_4c76

    ld de, $0001
    ld a, c
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 4, [hl]
    jr nz, jr_058_4c79

    ld de, $0002
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl+]
    and $d0
    jr nz, jr_058_4c79

    inc hl
    inc hl
    ld a, [hl]
    and $3f
    jr nz, jr_058_4c79

    ld de, $00ff
    push de
    ld a, $05
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    ld a, [$db4c]
    xor $0c
    and $0c
    pop de
    or d
    ld d, a
    jr jr_058_4c79

jr_058_4c76:
    ld de, $0000

jr_058_4c79:
    call LoadBtlFX_6292
    pop bc
    inc c
    dec b
    jr nz, jr_058_4c2b

    call SetBtlFX_619a
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_627c

jr_058_4c90:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_4cc2

    ld de, $0001
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 7, [hl]
    jr nz, jr_058_4cc5

    ld hl, $00ff
    push hl
    ld a, $02
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    ld a, [$db4c]
    xor $c0
    and $c0
    pop de
    or d
    ld d, a
    jr jr_058_4cc5

jr_058_4cc2:
    ld de, $0000

jr_058_4cc5:
    call LoadBtlFX_6292
    pop bc
    inc c
    dec b
    jr nz, jr_058_4c90

    call SetBtlFX_619a
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c

jr_058_4cd8:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_4d0b

    ld a, c
    ld hl, wBattleMP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    or [hl]
    jr z, jr_058_4d0b

    ld a, $02
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    ld de, $0001
    ld a, [$db4c]
    rlca
    rlca
    xor $30
    and $30
    or d
    ld d, a
    jr jr_058_4d0e

jr_058_4d0b:
    ld de, $0000

jr_058_4d0e:
    call LoadBtlFX_6292
    pop bc
    inc c
    dec b
    jr nz, jr_058_4cd8

    call SetBtlFX_619a
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c

jr_058_4d21:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_4d4e

    ld de, $0001
    ld a, c
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 0, [hl]
    jr z, jr_058_4d51

    ld a, c
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    xor $ff
    ld e, a
    ld a, [hl]
    xor $ff
    ld d, a
    jr jr_058_4d51

jr_058_4d4e:
    ld de, $0000

jr_058_4d51:
    call LoadBtlFX_6292
    pop bc
    inc c
    dec b
    jr nz, jr_058_4d21

    call SetBtlFX_619a
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c
    ld a, $01
    ld [$db4c], a
    call SaveBtlFX_64fc
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c
    ld a, $02
    ld [$db4c], a
    call SaveBtlFX_64fc
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c
    ld a, $03
    ld [$db4c], a
    call SaveBtlFX_64fc
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c
    ld a, $06
    ld [$db4c], a
    call SaveBtlFX_64fc
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c
    ld a, $07
    ld [$db4c], a
    call SaveBtlFX_64fc
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c
    ld a, $08
    ld [$db4c], a
    call SaveBtlFX_64fc
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c
    ld a, $00
    ld [$db4c], a
    call SaveBtlFX_64fc
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c
    ld a, $05
    ld [$db4c], a
    call SaveBtlFX_64fc
    ret


    call CallBtlFX_654d
    ret z

    call SetBtlFX_627c
    ld a, $04
    ld [$db4c], a
    call SaveBtlFX_64fc
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_627c

jr_058_4df8:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_4e2a

    ld de, $0001
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    and $03
    jr nz, jr_058_4e2d

    ld de, $00ff
    push de
    ld a, $04
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    ld a, [$db4c]
    and $03
    xor $03
    pop de
    ld d, a
    jr jr_058_4e2d

jr_058_4e2a:
    ld de, $0000

jr_058_4e2d:
    call LoadBtlFX_6292
    pop bc
    inc c
    dec b
    jr nz, jr_058_4df8

    call SetBtlFX_619a
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_627c

jr_058_4e44:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_4e76

    ld de, $0001
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    and $cc
    jr nz, jr_058_4e79

    ld de, $00ff
    push de
    ld a, $05
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    ld a, [$db4c]
    and $c0
    xor $c0
    pop de
    ld d, a
    jr jr_058_4e79

jr_058_4e76:
    ld de, $0000

jr_058_4e79:
    call LoadBtlFX_6292
    pop bc
    inc c
    dec b
    jr nz, jr_058_4e44

    call SetBtlFX_619a
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_627c

jr_058_4e90:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_4ec9

    ld de, $0001
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl+]
    and $d0
    jr nz, jr_058_4ecc

    inc hl
    inc hl
    ld a, [hl]
    and $3f
    jr nz, jr_058_4ecc

    ld de, $00ff
    push de
    ld a, $05
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    ld a, [$db4c]
    and $0c
    xor $0c
    pop de
    ld d, a
    jr jr_058_4ecc

jr_058_4ec9:
    ld de, $0000

jr_058_4ecc:
    call LoadBtlFX_6292
    pop bc
    inc c
    dec b
    jr nz, jr_058_4e90

    call SetBtlFX_619a
    ret


    call CallBtlFX_654d
    ret z

    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld [$db4c], a
    inc a
    ld [$db4d], a
    ld a, $02
    ld [$db4e], a
    ld a, [$db4c]
    call CheckMonsterSlot
    jr c, jr_058_4f1c

    ld hl, wBattleMaxHP
    ld a, [$db4c]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, wBattleMaxMP
    ld a, [$db4c]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    call LoadBtlFX_5f01
    jr jr_058_4f21

jr_058_4f1c:
    ld bc, $0000
    ld e, $00

jr_058_4f21:
    ld hl, $db56
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ld a, e
    ld [hl], a

Jump_058_4f2a:
    ld a, [$db4d]
    call CheckMonsterSlot
    jr c, jr_058_4f57

    ld hl, wBattleMaxHP
    ld a, [$db4d]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, wBattleMaxMP
    ld a, [$db4d]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    call LoadBtlFX_5f01
    jr jr_058_4f5c

jr_058_4f57:
    ld bc, $0000
    ld e, $00

jr_058_4f5c:
    ld hl, $db58
    ld a, e
    cp [hl]
    jr c, jr_058_4f80

    jr nz, jr_058_4f71

    dec hl
    ld a, b
    cp [hl]
    jr c, jr_058_4f80

    jr nz, jr_058_4f71

    dec hl
    ld a, c
    cp [hl]
    jr c, jr_058_4f80

jr_058_4f71:
    ld hl, $db56
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ld a, e
    ld [hl], a
    ld a, [$db4d]
    ld [$db4c], a

jr_058_4f80:
    ld hl, $db4d
    inc [hl]
    ld hl, $db4e
    dec [hl]
    ld a, [$db4e]
    or a
    jp nz, Jump_058_4f2a

    ld a, [$db4c]
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


LoadBtlFX_4fa7:
    ld a, c
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 0, [hl]
    ret z

    push af
    push bc
    push de
    push hl
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    ld a, $32
    call Mul16x8To24
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    pop hl
    pop de
    pop bc
    pop af
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_5e19

Jump_058_4fdd:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_501e

    ld a, $02
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    push bc
    ld a, c
    and $03
    ld de, $db50
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [$db4c]
    and $30
    ld [de], a
    push de
    call LoadBtlFX_5e2f
    pop hl
    jr z, jr_058_500e

    set 6, [hl]

jr_058_500e:
    ld a, c
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    jr jr_058_5030

jr_058_501e:
    ld a, c
    and $03
    ld de, $db50
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, $ff
    ld [de], a
    ld de, $0000

jr_058_5030:
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl], a
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    pop bc
    inc c
    dec b
    jp nz, Jump_058_4fdd

    call SetBtlFX_5d86
    call LoadBtlFX_5e3a
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_5e19

Jump_058_5074:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_50b5

    ld a, $00
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    push bc
    ld a, c
    and $03
    ld de, $db50
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [$db4c]
    and $30
    ld [de], a
    push de
    call LoadBtlFX_5e2f
    pop hl
    jr z, jr_058_50a5

    set 6, [hl]

jr_058_50a5:
    ld a, c
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    jr jr_058_50c7

jr_058_50b5:
    ld a, c
    and $03
    ld de, $db50
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, $ff
    ld [de], a
    ld de, $ffff

jr_058_50c7:
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl], a
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    pop bc
    inc c
    dec b
    jp nz, Jump_058_5074

    call SetBtlFX_5cef
    call LoadBtlFX_5e3a
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_5e19
    xor a
    ld [$db50], a
    ld [$db51], a
    ld [$db52], a
    ld [$db53], a

jr_058_5118:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_5142

    ld de, $0001
    ld a, c
    ld hl, $db08
    call HL_AddA_x8
    bit 5, [hl]
    jr nz, jr_058_5145

    inc hl
    ld a, [hl]
    and $05
    jr nz, jr_058_5145

    ld a, c
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    jr jr_058_5145

jr_058_5142:
    ld de, $0000

jr_058_5145:
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld [hl], e
    inc hl
    ld [hl], d
    inc hl
    ld a, l
    ld [$db5e], a
    ld a, h
    ld [$db5f], a
    inc c
    dec b
    jr nz, jr_058_5118

    call SetBtlFX_5d86
    call LoadBtlFX_5e3a
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    ld a, [$c86c]
    or a
    jp nz, Jump_058_62bf

    ld a, [wBattleAttackerIdx]
    cp $04
    jp c, Jump_058_62bf

    call SetBtlFX_5e19
    ld a, c
    ld [$db60], a
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_51ac

    ld d, $fe
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 4, [hl]
    jr nz, jr_058_51ae

    push bc
    ld a, $03
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    ld a, [$db4c]
    and $c0
    ld d, a
    jr jr_058_51ae

jr_058_51ac:
    ld d, $ff

jr_058_51ae:
    ld a, d
    ld [$db50], a
    ld a, c
    ld [$db60], a
    inc c
    dec b

Jump_058_51b8:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_51e3

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 4, [hl]
    jr nz, jr_058_51df

    push bc
    ld a, $03
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    ld a, [$db4c]
    and $c0
    jr jr_058_51e5

jr_058_51df:
    ld a, $fe
    jr jr_058_51e5

jr_058_51e3:
    ld a, $ff

jr_058_51e5:
    ld d, a
    ld hl, $db50
    cp [hl]
    jr c, jr_058_5200

    jr nz, jr_058_5208

    push af
    push bc
    push de
    push hl
    call LoadBtlFX_5c3e
    pop hl
    pop de
    pop bc
    pop af
    ld a, [wRNG1]
    cp $80
    jr c, jr_058_5208

jr_058_5200:
    ld a, d
    ld [$db50], a
    ld a, c
    ld [$db60], a

jr_058_5208:
    inc c
    dec b
    jp nz, Jump_058_51b8

    call LoadBtlFX_5e3a
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a
    ld b, $03
    push bc
    xor a
    ld hl, $db50
    ld [hl+], a
    ld [hl+], a
    ld [hl], a

jr_058_522b:
    push bc
    ld a, c
    call CheckMonsterSlot
    pop bc
    jr c, jr_058_527e

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl+]
    and $c0
    jr nz, jr_058_526d

    inc hl
    ld a, [hl+]
    and $22
    jr nz, jr_058_526d

    ld a, [hl]
    and $3f
    jr nz, jr_058_526d

    push bc
    ld a, $02
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$db4c]
    and $c0
    ld [hl], a
    jr jr_058_528d

jr_058_526d:
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fe
    ld [hl], a
    jr jr_058_528d

jr_058_527e:
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    ld [hl], a

jr_058_528d:
    inc c
    dec b
    jr nz, jr_058_522b

    pop bc
    ld a, c
    ld [$db4c], a
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$db4d], a
    call LoadBtlFX_5f0c
    ret


    call CallBtlFX_654d
    ret z

    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a
    ld b, $03
    push bc
    xor a
    ld hl, $db50
    ld [hl+], a
    ld [hl+], a
    ld [hl], a

jr_058_52bf:
    push bc
    ld a, c
    call CheckMonsterSlot
    pop bc
    jr c, jr_058_530e

    ld a, c
    call GetCombatantMP
    or h
    jr z, jr_058_530e

    ld a, c
    ld hl, $db04
    call HL_AddA_x8
    ld a, [hl]
    and $22
    jr nz, jr_058_52fd

    push bc
    ld a, $02
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$db4c]
    and $0c
    ld [hl], a
    jr jr_058_531d

jr_058_52fd:
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $fe
    ld [hl], a
    jr jr_058_531d

jr_058_530e:
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    ld [hl], a

jr_058_531d:
    inc c
    dec b
    jr nz, jr_058_52bf

    pop bc
    ld a, c
    ld [$db4c], a
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$db4d], a
    call LoadBtlFX_5f0c
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_5e19
    ld a, $00
    ld [$db4e], a
    ld a, $c0
    ld [$db4f], a
    call LoadBtlFX_5fa6
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_5e19
    ld a, $01
    ld [$db4e], a
    ld a, $30
    ld [$db4f], a
    call LoadBtlFX_5fa6
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_5e19
    ld a, $01
    ld [$db4e], a
    ld a, $c0
    ld [$db4f], a
    call LoadBtlFX_5fa6
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_5e19
    ld a, $01
    ld [$db4e], a
    ld a, $0c
    ld [$db4f], a
    call LoadBtlFX_5fa6
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_5e19
    ld a, $01
    ld [$db4e], a
    ld a, $c0
    ld [$db4f], a
    call LoadBtlFX_6043
    ret


    call CallBtlFX_654d
    ret z

    call LoadBtlFX_6629
    ret z

    call SetBtlFX_5e19
    ld a, $06
    ld [$db4e], a
    ld a, $0c
    ld [$db4f], a
    call LoadBtlFX_6043
    ret


    ld a, [$d9ed]
    rst $00
    rst $18
    ld d, e
    ld e, $54
    daa
    ld d, h
    pop de
    ld d, h
    jp nz, $0755

    ld d, a

Jump_058_53df:
    ld a, [$c86c]
    or a
    call nz, SaveBtlFX_5c18
    ld a, [wBattleAttackerIdx]
    cp $08
    jr z, jr_058_5411

    ld e, a
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $01
    jr z, jr_058_5403

    inc e
    ld a, e
    ld [wBattleAttackerIdx], a
    jr jr_058_541d

jr_058_5403:
    ld a, e
    ld [wBattleAttackerIdx], a
    ld hl, $d9ed
    inc [hl]
    xor a
    ld [$d9ee], a
    jr jr_058_541d

jr_058_5411:
    ld hl, $d9ed
    inc [hl]
    ld hl, $d9ed
    inc [hl]
    ld hl, $d9ed
    inc [hl]

jr_058_541d:
    ret


    ld hl, $5700
    rst $10
    ret


    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp hl


    xor a
    ld [$dd69], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr nz, jr_058_5478

    ld a, [wBattleAttackerIdx]
    call GetMonsterSlotInfo
    jr nc, jr_058_545b

    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $3a
    ld [hl+], a
    ld a, [wBattleAttackerIdx]
    ld [hl], a
    jr jr_058_5478

jr_058_545b:
    ld a, [$c88b]
    or a
    call nz, CallBtlFX_5a20
    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    call z, WriteBtlFX_54ce
    call LoadBtlFX_5498

jr_058_5478:
    call LoadBtlFX_5a40
    call LoadBtlFX_5ba1
    ld a, [wBattleAttackerIdx]
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $02
    ld [hl], a
    xor a
    ld [$d9ed], a
    ld hl, wBattleAttackerIdx
    inc [hl]
    jp Jump_058_53df


LoadBtlFX_5498:
    ld a, [$d9ed]
    cp $16
    jr c, jr_058_54b1

    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    ld [hl-], a
    jr jr_058_54be

jr_058_54b1:
    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a

jr_058_54be:
    ld a, [hl]
    ld [$db8a], a
    ld hl, $401d
    ld c, a
    ld b, $00
    add hl, bc
    add hl, bc
    call RST_08
    ret


WriteBtlFX_54ce:
    ld [hl], $3a
    ret


    ld hl, $db79
    ld bc, $0009
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $db4c
    ld bc, $0009
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $db61
    ld bc, $0010
    ld a, $00
    call FillNBytesWithRegA
    xor a
    ld [$db82], a
    ld [wBattlePostFlag], a
    ld hl, $db61
    ld a, l
    ld [$db5e], a
    ld a, h
    ld [$db5f], a
    ld de, $0800

Jump_058_5507:
    push de
    ld a, [$c86c]
    or a
    call nz, SaveBtlFX_5c18
    pop de
    ld a, e
    call CheckMonsterSlot
    jr c, jr_058_5587

    ld a, e
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $02
    jr nz, jr_058_5587

    ld a, e
    ld hl, wBattleAGL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, e
    call SaveBtlFX_5662
    ld a, b
    or a
    jr nz, jr_058_5543

    ld a, c
    cp $02
    jr nc, jr_058_5543

    ld bc, $0002

jr_058_5543:
    ld a, e
    call SetBtlFX_56cf
    jr c, jr_058_5561

    ld a, e
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $55
    call z, LoadBtlFX_55b9
    cp $56
    call z, SetBtlFX_55be
    jr jr_058_5565

jr_058_5561:
    ld a, b
    add $06
    ld b, a

jr_058_5565:
    ld hl, $db5e
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [wBattlePostFlag]
    ld hl, $db4c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], e
    ld hl, wBattlePostFlag
    inc [hl]
    ld hl, $db5e
    inc [hl]
    ld hl, $db5e
    inc [hl]

jr_058_5587:
    inc e
    dec d
    jp nz, Jump_058_5507

    ld a, [$c86c]
    or a
    jr nz, jr_058_55b3

    ld a, [$db77]
    cp $ff
    jr z, jr_058_55b3

    ld bc, $0200
    ld hl, $db5e
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [wBattlePostFlag]
    ld hl, $db4c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $10

jr_058_55b3:
    ld hl, $d9ed
    inc [hl]
    jr jr_058_55c2

LoadBtlFX_55b9:
    ld a, b
    add $02
    ld b, a
    ret


SetBtlFX_55be:
    ld bc, $0001
    ret


jr_058_55c2:
    ld d, $08

jr_058_55c4:
    ld hl, $db61
    ld a, l
    ld [$db5e], a
    ld a, h
    ld [$db5f], a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $db63
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld e, $00

jr_058_55da:
    call CmpHLvsBC
    jr c, jr_058_5615

    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld a, c
    ld [$db58], a
    ld a, b
    ld [$db59], a
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld a, [$db56]
    ld [hl+], a
    ld a, [$db57]
    ld [hl+], a
    ld a, [$db58]
    ld [hl+], a
    ld a, [$db59]
    ld [hl], a
    ld a, e
    ld hl, $db4c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld [hl-], a
    ld [hl], b

jr_058_5615:
    inc e
    ld a, e
    cp d
    jr z, jr_058_5635

    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    inc hl
    inc hl
    ld a, l
    ld [$db5e], a
    ld a, h
    ld [$db5f], a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jr jr_058_55da

jr_058_5635:
    dec d
    jr nz, jr_058_55c4

    ld a, [$db82]
    ld de, $db79
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [$db82]
    ld hl, $db4c
    ld b, $08

jr_058_564c:
    ld a, [hl+]
    cp $ff
    jr z, jr_058_5656

    ld [de], a
    inc de
    dec b
    jr nz, jr_058_564c

jr_058_5656:
    ld a, $00
    ld [$db82], a
    ld hl, $d9ed
    inc [hl]
    jp Jump_058_5707


SaveBtlFX_5662:
    push hl
    push de
    push af
    push bc
    call LoadBtlFX_5c3e
    ld hl, $0001
    pop bc
    ld a, b
    or c
    jr nz, jr_058_5674

    ld bc, $0001

jr_058_5674:
    ld d, b
    ld e, c
    srl b
    rr c
    srl b
    rr c
    add hl, bc
    srl b
    rr c
    srl b
    rr c
    add hl, bc
    ld a, e
    sub l
    ld e, a
    ld a, d
    sbc h
    ld d, a
    ld b, h
    ld c, l
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, h
    and $03
    ld h, a

jr_058_569c:
    call CmpHLvsBC
    jr z, jr_058_56ab

    jr c, jr_058_56ab

    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    jr jr_058_569c

jr_058_56ab:
    add hl, de
    ld b, h
    ld c, l
    pop af
    ld e, a
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $55
    jr nz, jr_058_56c5

    ld a, b
    add $02
    ld b, a
    jr jr_058_56cc

jr_058_56c5:
    cp $56
    jr nz, jr_058_56cc

    ld bc, $0000

jr_058_56cc:
    pop de
    pop hl
    ret


SetBtlFX_56cf:
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $2a
    jr z, jr_058_5705

    cp $7f
    jr z, jr_058_5705

    cp $88
    jr z, jr_058_5705

    cp $89
    jr z, jr_058_5705

    cp $8c
    jr z, jr_058_5705

    cp $8d
    jr z, jr_058_5705

    cp $8e
    jr z, jr_058_5705

    cp $8f
    jr z, jr_058_5705

    cp $90
    jr z, jr_058_5705

    cp $dc
    jr z, jr_058_5705

    xor a
    jr jr_058_5706

jr_058_5705:
    scf

jr_058_5706:
    ret


Jump_058_5707:
    xor a
    ld [$d9ed], a
    ld [$db82], a
    ld [wBattleAttackerIdx], a
    ld [wBattleTargetIdx], a
    ld [$db8a], a
    ld hl, $d9ec
    inc [hl]
    ret


    push hl
    ld a, [wBattleAttackerIdx]
    ld hl, $dc65
    swap a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld b, h
    ld c, l
    ld a, [wRNG1]
    and $07
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr nz, jr_058_5745

    ld a, [bc]
    cp $ff
    jr nz, jr_058_5745

    ld a, $3a

jr_058_5745:
    ld c, a
    pop hl
    ld [hl], c
    ret


    ld a, $02
    ld [$d9f0], a
    ld a, [$c86c]
    or a
    jr z, jr_058_5766

    ld a, [$c863]
    bit 1, a
    jr z, jr_058_5766

    ld a, [wBattleTargetIdx]
    bit 2, a
    ret nz

    ld a, [wBattleTargetIdx]
    jr jr_058_5771

jr_058_5766:
    ld a, [wBattleTargetIdx]
    bit 2, a
    ret z

    ld a, [wBattleTargetIdx]
    sub $04

jr_058_5771:
    cp $02
    jr z, jr_058_5783

    cp $01
    jr z, jr_058_577e

    ld hl, $9000
    jr jr_058_5786

jr_058_577e:
    ld hl, $9240
    jr jr_058_5786

jr_058_5783:
    ld hl, $9480

jr_058_5786:
    ld c, $24

jr_058_5788:
    ld b, $08

jr_058_578a:
    di

jr_058_578b:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, jr_058_578b

    ld a, $ff
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ei
    dec b
    jr nz, jr_058_578a

    dec c
    jr nz, jr_058_5788

    ld a, $05
    ld [$d9ed], a
    ret


    ld a, [$db78]
    cp $c2
    jr c, jr_058_57e6

    cp $c7
    jr nc, jr_058_57e6

    ld b, a
    ld a, $01
    ld [$c822], a
    ld a, [$db77]
    cp $04
    jr nc, jr_058_57c2

    call LoadBtlFX_59cf
    jp Jump_058_58f8


jr_058_57c2:
    jp Jump_058_58e8


    ld a, [wBattleAttackerIdx]
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl]
    and $0c
    jr nz, jr_058_57f4

    inc hl
    bit 4, [hl]
    jr nz, jr_058_57fa

    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]

jr_058_57e6:
    ld hl, $5806
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$db4c], a
    ret


jr_058_57f4:
    ld a, $33
    ld [$db4c], a
    ret


jr_058_57fa:
    ld a, $4f
    ld [$db4c], a
    ret


    ld a, $ff
    ld [$db4c], a
    ret


    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    ld [hl+], a
    ld [hl+], a
    inc hl
    ld [hl+], a
    dec hl
    inc l
    dec l
    ld l, $2f
    jr nc, jr_058_5879

    ld [hl-], a
    inc [hl]
    inc h
    inc h
    inc h
    inc h
    inc h
    inc h
    inc h
    inc h
    inc h
    inc h
    inc h
    dec [hl]
    inc h
    inc h
    ld [hl], $37
    jr c, jr_058_5895

    ld a, [hl-]
    inc h
    inc h
    dec sp
    inc a
    dec a
    dec h
    dec h
    dec h
    dec h
    dec h
    dec h
    dec h
    dec h
    ld a, $3f
    ld b, b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    dec h
    dec h
    dec h
    dec h
    ld h, $41
    ld b, h
    ld h, $42

jr_058_5879:
    inc h
    inc h
    ld h, $26
    ld b, e
    ld h, $45
    ld b, l
    ld b, [hl]
    inc h
    ld c, b
    ld [hl+], a
    ld d, b
    daa
    daa
    daa
    ld [hl], b
    ld c, c
    ld c, c
    ld c, c
    ld c, c
    ld d, c
    ld d, d
    ld c, d
    ld c, e
    ld d, e
    jr z, @+$56

jr_058_5895:
    ld d, [hl]
    ld d, l
    ld h, $4c
    ld c, l
    ld h, $4e
    ld h, $2a
    jr jr_058_58c2

    ld [hl+], a
    ld d, a
    ld e, b
    ld e, h
    ld e, c
    ld e, d
    ld e, e
    add hl, hl
    ld l, a
    rst $38
    rst $38
    ld [hl], b
    ld [hl], c
    rst $38
    rst $38
    ld [hl], e
    rst $38
    ld [hl], h
    ld [hl], l
    rst $38
    rst $38
    ld [hl], a
    ld e, l
    ld e, l
    ld e, a
    ld h, b
    ld e, l
    ld e, l
    ld e, l
    ld e, l
    ld e, l
    ld e, l
    ld e, l
    ld e, l

jr_058_58c2:
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    ld e, [hl]
    ld e, [hl]
    ld e, [hl]
    ld e, [hl]
    ld e, [hl]
    ld h, c
    ld h, d
    ld h, e
    ld h, h
    ld h, l
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    ld h, [hl]
    inc hl
    inc h
    inc h
    inc h
    inc h
    inc hl
    add hl, hl
    inc hl
    ld b, h
    ld h, a
    ld l, b
    rst $38
    ld l, d

Jump_058_58e8:
    ld a, [wBattleTargetIdx]
    push af
    ld a, $04
    ld [wBattleTargetIdx], a
    call ClrBtlFX_5955
    pop af
    ld [wBattleTargetIdx], a

Jump_058_58f8:
    ld a, [$db78]
    cp $c5
    jr nz, jr_058_5907

    ld a, [$dd72]
    add $03
    ld [$dd72], a

jr_058_5907:
    ld a, [$dd72]
    ld hl, $5918
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$db4c], a
    ret


    nop
    ld bc, $0002
    ld bc, $cd02
    dec bc
    ld e, h
    cp $04
    call nc, SetBtlFX_593d
    ld a, [$dd72]
    ld hl, $5937
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$c823], a
    ret


    inc bc
    dec b
    rlca
    inc b
    ld b, $08

SetBtlFX_593d:
    ld hl, $c180
    jr jr_058_5945

SetBtlFX_5942:
    ld hl, $c1a0

jr_058_5945:
    ld a, [hl]
    cp $f0
    jr z, jr_058_594d

    inc hl
    jr jr_058_5945

jr_058_594d:
    dec hl
    ld a, [hl]
    cp $24
    ret nc

    ld [hl], $f0
    ret


ClrBtlFX_5955:
    xor a
    ld [$dd72], a
    ld [$dd73], a
    ld a, [wBattleTargetIdx]
    and $04
    ld c, a
    ld b, $03
    ld a, [$c86c]
    or a
    jr nz, jr_058_596f

    ld a, c
    cp $04
    jr nc, jr_058_5988

jr_058_596f:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_5979

    ld hl, $dd72
    inc [hl]

jr_058_5979:
    inc c
    dec b
    jr nz, jr_058_596f

    ld a, [$dd72]
    dec a
    or a
    jr z, jr_058_59d8

    ld a, $01
    jr jr_058_59d8

jr_058_5988:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_59b9

    ld hl, $dd72
    inc [hl]
    ld hl, $dd73
    ld a, [hl]
    or a
    jr nz, jr_058_59a8

    ld a, c
    ld de, $dc3c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld d, a
    inc [hl]
    jr jr_058_59b9

jr_058_59a8:
    push bc
    ld a, c
    ld bc, $dc3c
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    ld a, [bc]
    pop bc
    cp d
    jr z, jr_058_59b9

    inc [hl]

jr_058_59b9:
    inc c
    dec b
    jr nz, jr_058_5988

    ld a, [$dd72]
    cp $01
    jr z, jr_058_59cf

    ld a, [$dd73]
    cp $01
    jr z, jr_058_59d3

    ld a, $02
    jr jr_058_59d8

LoadBtlFX_59cf:
jr_058_59cf:
    ld a, $00
    jr jr_058_59d8

jr_058_59d3:
    call SetBtlFX_5942
    ld a, $01

jr_058_59d8:
    ld [$dd72], a
    ret


    ld hl, $c180
    ld a, [$c86c]
    or a
    jr nz, jr_058_59f1

    ld a, [wBattleTargetIdx]
    cp $03
    jr c, jr_058_59f1

    call FuncBtlFX_5a02
    jr jr_058_59fe

jr_058_59f1:
    push hl
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    pop hl
    call Copy4Bytes

jr_058_59fe:
    call ClrBtlFX_5955
    ret


FuncBtlFX_5a02:
    ld [$db60], a
    push hl
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld l, a
    ld h, $05
    pop de
    ld a, e
    ld [$db5e], a
    ld a, d
    ld [$db5f], a
    call SetupVRAMParams
    ret


CallBtlFX_5a20:
    call LoadBtlFX_5c3e
    ld a, [$c88c]
    or a
    jr z, jr_058_5a2e

    ld hl, wRNG1
    cp [hl]
    ret c

jr_058_5a2e:
    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$c88d]
    ld [hl], a
    ret


LoadBtlFX_5a40:
    ld a, [wBattleAttackerIdx]
    call GetMonsterSlotInfo
    ret c

    ld a, [$c86c]
    or a
    jr z, jr_058_5a5a

    call SaveBtlFX_5c18
    ld a, [wBattleAttackerIdx]
    and $03
    cp $03
    ret z

    jr jr_058_5a63

jr_058_5a5a:
    ld a, [wBattleAttackerIdx]
    cp $03
    ret nc

    call LoadBtlFX_5c3e

jr_058_5a63:
    ld a, [wBattleAttackerIdx]
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl+]
    and $0c
    ret nz

    ld a, [hl]
    and $0c
    jp nz, Jump_058_5b1e

    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $12
    ret c

    cp $14
    ret z

    cp $1b
    ret z

    cp $1e
    jr c, jr_058_5afb

    cp $20
    jr z, jr_058_5afb

    cp $21
    jr z, jr_058_5afb

    cp $2b
    ret c

    cp $32
    ret z

    cp $37
    jr c, jr_058_5b09

    cp $3a
    jr z, jr_058_5aed

    cp $44
    ret c

    cp $4f
    ret z

    cp $52
    jr c, jr_058_5aed

    cp $55
    jr z, jr_058_5aed

    cp $67
    ret c

    cp $6a
    jr c, jr_058_5aed

    cp $77
    jr z, jr_058_5b1e

    cp $7e
    jr c, jr_058_5afb

    cp $81
    jr z, jr_058_5b09

    cp $82
    jr z, jr_058_5afb

    cp $8c
    jr z, jr_058_5b10

    cp $8d
    jr z, jr_058_5af4

    cp $8e
    jr z, jr_058_5af4

    cp $90
    jr z, jr_058_5af4

    ret c

    cp $93
    jr c, jr_058_5afb

    cp $96
    jr c, jr_058_5b09

    cp $d6
    ret c

    cp $d9
    jr c, jr_058_5aed

    ret


jr_058_5aed:
    ld hl, $dc44
    ld d, $01
    jr jr_058_5b25

jr_058_5af4:
    ld hl, $dc44
    ld d, $02
    jr jr_058_5b63

jr_058_5afb:
    ld hl, $dc4c
    ld d, $04
    jr jr_058_5b25

SetBtlFX_5b02:
    ld hl, $dc4c
    ld d, $08
    jr jr_058_5b63

jr_058_5b09:
    ld hl, $dc54
    ld d, $10
    jr jr_058_5b25

jr_058_5b10:
    ld hl, $dc54
    ld d, $20
    jr jr_058_5b63

SetBtlFX_5b17:
    ld hl, $dc5c
    ld d, $40
    jr jr_058_5b25

Jump_058_5b1e:
jr_058_5b1e:
    ld hl, $dc5c
    ld d, $80
    jr jr_058_5b63

jr_058_5b25:
    ld a, [wBattleAttackerIdx]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $81
    ret c

    cp $a2
    jr c, jr_058_5b40

    cp $c3
    jr c, jr_058_5b44

    cp $e4
    jr c, jr_058_5b48

    jr jr_058_5b4c

jr_058_5b40:
    ld b, $01
    jr jr_058_5b4e

jr_058_5b44:
    ld b, $02
    jr jr_058_5b4e

jr_058_5b48:
    ld b, $04
    jr jr_058_5b4e

jr_058_5b4c:
    ld b, $08

jr_058_5b4e:
    ld a, [wRNG1]
    cp b
    ret nc

    ld a, [wBattleAttackerIdx]
    ld hl, $db42
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    or d
    ld [hl], a
    ret


jr_058_5b63:
    ld a, [wBattleAttackerIdx]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $80
    ret nc

    cp $60
    jr nc, jr_058_5b7e

    cp $3f
    jr nc, jr_058_5b82

    cp $1e
    jr nc, jr_058_5b86

    jr jr_058_5b8a

jr_058_5b7e:
    ld b, $02
    jr jr_058_5b8c

jr_058_5b82:
    ld b, $04
    jr jr_058_5b8c

jr_058_5b86:
    ld b, $08
    jr jr_058_5b8c

jr_058_5b8a:
    ld b, $10

jr_058_5b8c:
    ld a, [wRNG1]
    cp b
    ret nc

    ld a, [wBattleAttackerIdx]
    ld hl, $db42
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    or d
    ld [hl], a
    ret


LoadBtlFX_5ba1:
    ld a, [wBattleAttackerIdx]
    call GetMonsterSlotInfo
    ret c

    ld a, [$c86c]
    or a
    jr z, jr_058_5bbb

    call SaveBtlFX_5c18
    ld a, [wBattleAttackerIdx]
    and $03
    cp $03
    ret z

    jr jr_058_5bc4

jr_058_5bbb:
    ld a, [wBattleAttackerIdx]
    cp $03
    ret nc

    call LoadBtlFX_5c3e

jr_058_5bc4:
    ld a, [wBattleAttackerIdx]
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl+]
    and $0c
    ret nz

    ld a, [hl]
    and $0c
    ret nz

    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $90
    jr z, jr_058_5c07

    cp $12
    jr c, jr_058_5c03

    cp $3a
    jr z, jr_058_5c03

    cp $44
    ret c

    cp $52
    jr c, jr_058_5c03

    cp $55
    ret c

    cp $6a
    jr c, jr_058_5c03

    cp $d6
    ret c

    cp $da
    ret nc

jr_058_5c03:
    call SetBtlFX_5b17
    ret


jr_058_5c07:
    call SetBtlFX_5b02
    ret


    ld a, [$c863]
    bit 1, a
    ld a, [wBattleTargetIdx]
    ret z

    ld a, [wBattleAttackerIdx]
    ret


SaveBtlFX_5c18:
jr_058_5c18:
    push hl
    ld a, [$c1ed]
    ld l, a
    ld a, [$c1ee]
    ld h, a
    ld a, l
    ld [wRNG1], a
    ld a, h
    ld [wRNG2], a
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, l
    ld [$c1ed], a
    ld a, h
    ld [$c1ee], a
    pop hl
    ret


LoadBtlFX_5c3e:
    ld a, [$c86c]
    or a
    jr nz, jr_058_5c18

    call GenerateRNG
    ret


    call LoadBtlFX_5498
    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$db8a], a
    ld a, [hl]
    ld [wBattleTargetIdx], a
    ld a, [$d9ed]
    cp $17
    jr z, jr_058_5c6e

    ld a, $02
    ld [$d9ef], a
    jr jr_058_5c73

jr_058_5c6e:
    ld a, $01
    ld [$d9ef], a

jr_058_5c73:
    xor a
    ld [$d9ed], a
    ld a, $02
    ld [$d9ee], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $02
    ret nz

    ld a, [$dd72]
    or a
    ret nz

    ld hl, $d9ee
    inc [hl]
    ret


SaveBtlFX_5c96:
    push hl
    ld b, a
    ld a, [$c86c]
    or a
    jr nz, jr_058_5ccf

    ld a, b
    cp $03
    jr c, jr_058_5cd6

    and $03
    cp $03
    jr z, jr_058_5cde

    ld a, b
    sub $04
    ld hl, wTempEnemyId1
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a

jr_058_5cb9:
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    ld hl, $1401
    rst $10
    ld a, [$da23]
    ld c, a
    ld a, [$da24]
    ld b, a
    jr jr_058_5ced

jr_058_5ccf:
    ld a, b
    and $03
    cp $03
    jr z, jr_058_5cde

jr_058_5cd6:
    ld hl, $cb1b
    call ReadMonsterWord
    jr jr_058_5ced

jr_058_5cde:
    ld a, b
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $01
    jr jr_058_5cb9

jr_058_5ced:
    pop hl
    ret


SetBtlFX_5cef:
    ld hl, $db58
    ld a, l
    ld [$db5e], a
    ld a, h
    ld [$db5f], a
    ld a, $00
    ld [$db60], a
    ld hl, $db56
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld de, $0201

jr_058_5d08:
    push hl
    push de
    push bc
    call LoadBtlFX_5c3e
    ld a, [$db60]
    ld hl, $db50
    and $03
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld b, a
    ld a, e
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp b
    pop bc
    pop de
    pop hl
    jr c, jr_058_5d50

    jr nz, jr_058_5d61

    push hl
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    pop hl
    call CmpHLvsBC
    jr c, jr_058_5d61

    jr nz, jr_058_5d5b

    ld a, [wRNG1]
    cp $80
    jr c, jr_058_5d61

    jr jr_058_5d5b

jr_058_5d50:
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a

jr_058_5d5b:
    ld h, b
    ld l, c
    ld a, e
    ld [$db60], a

jr_058_5d61:
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    inc e
    dec d
    jr nz, jr_058_5d08

    ret


SetBtlFX_5d86:
    ld hl, $db58
    ld a, l
    ld [$db5e], a
    ld a, h
    ld [$db5f], a
    ld a, $00
    ld [$db60], a
    ld hl, $db56
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld de, $0201

jr_058_5d9f:
    push hl
    push de
    push bc
    call LoadBtlFX_5c3e
    ld a, [$db60]
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld b, a
    ld a, e
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp b
    pop bc
    pop de
    pop hl
    jr c, jr_058_5de3

    jr nz, jr_058_5df4

    push hl
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    pop hl
    call CmpHLvsBC
    jr c, jr_058_5dee

    jr nz, jr_058_5df4

    ld a, [wRNG1]
    cp $80
    jr c, jr_058_5df4

    jr jr_058_5dee

jr_058_5de3:
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a

jr_058_5dee:
    ld h, b
    ld l, c
    ld a, e
    ld [$db60], a

jr_058_5df4:
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    inc e
    dec d
    jr nz, jr_058_5d9f

    ret


SetBtlFX_5e19:
    ld hl, $db56
    ld a, l
    ld [$db5e], a
    ld a, h
    ld [$db5f], a
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a
    ld b, $03
    ret


LoadBtlFX_5e2f:
    ld a, c
    ld hl, $db04
    call HL_AddA_x8
    ld a, [hl]
    and $22
    ret


LoadBtlFX_5e3a:
    ld a, [$db60]
    ld c, a
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    add c
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


CallBtlFX_5e5b:
    call SetBtlFX_5e75
    ld b, $03
    ld d, $00

jr_058_5e62:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_5e6d

    ld a, c
    ld [hl+], a
    inc d
    jr jr_058_5e70

jr_058_5e6d:
    call SaveBtlFX_66e7

jr_058_5e70:
    inc c
    dec b
    jr nz, jr_058_5e62

    ret


SetBtlFX_5e75:
    ld hl, $db4c
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a
    ret


ClrBtlFX_5e81:
    xor a
    ld hl, $db50
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    call SetBtlFX_5cef
    ld a, [$db60]
    ld hl, $db4c
    ld de, $db4c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld b, a
    ld a, [hl]
    ld [de], a
    ld a, b
    ld [hl], a
    ld hl, $db56
    ld a, [$db60]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    push hl
    ld e, a
    ld hl, $db56
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, d
    ld [hl-], a
    ld [hl], e
    pop hl
    ld a, b
    ld [hl-], a
    ld [hl], c
    ret


CallBtlFX_5ebf:
    call SetBtlFX_5d86
    ld a, [$db60]
    ld hl, $db4e
    ld de, $db4c
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld b, a
    ld a, [hl]
    ld [de], a
    ld a, b
    ld [hl], a
    ld hl, $db56
    ld a, [$db60]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    push hl
    ld e, a
    ld hl, $db5a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, d
    ld [hl-], a
    ld [hl], e
    pop hl
    ld a, b
    ld [hl-], a
    ld [hl], c
    ret


    ld a, l
    add c
    ld l, a
    ld a, h
    adc b
    ld h, a
    xor a
    adc $00
    ld c, a
    ret


LoadBtlFX_5f01:
    ld a, c
    add e
    ld c, a
    ld a, b
    adc d
    ld b, a
    xor a
    adc $00
    ld e, a
    ret


LoadBtlFX_5f0c:
jr_058_5f0c:
    ld a, c
    and $03
    ld hl, $db50
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld d, [hl]
    ld a, [$db4d]
    cp d
    jr c, jr_058_5f3b

    jr nz, jr_058_5f33

    push af
    push bc
    push de
    push hl
    call LoadBtlFX_5c3e
    pop hl
    pop de
    pop bc
    pop af
    ld a, [wRNG1]
    cp $80
    jr c, jr_058_5f3b

jr_058_5f33:
    ld a, c
    ld [$db4c], a
    ld a, d
    ld [$db4d], a

jr_058_5f3b:
    inc c
    dec b
    jr nz, jr_058_5f0c

    ld a, [$db4c]
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


SaveBtlFX_5f57:
    push hl
    push bc
    ld a, c
    call CheckMonsterSlot
    pop bc
    jr c, jr_058_5f77

    ld a, c
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld a, c
    call GetCombatantDEF
    add hl, de
    jr nc, jr_058_5f7f

    jr jr_058_5f7c

jr_058_5f77:
    ld a, $ff
    ld [$db4c], a

jr_058_5f7c:
    ld hl, $ffff

jr_058_5f7f:
    ld d, h
    ld e, l
    pop hl
    ret


SaveBtlFX_5f83:
    push hl
    push bc
    ld a, c
    call CheckMonsterSlot
    pop bc
    jr c, jr_058_5f9c

    ld a, c
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    jr jr_058_5fa4

jr_058_5f9c:
    ld a, $ff
    ld [$db4c], a
    ld de, $ffff

jr_058_5fa4:
    pop hl
    ret


LoadBtlFX_5fa6:
    ld a, c
    ld [$db60], a
    push bc
    ld a, [$db4e]
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    call SaveBtlFX_5f57
    ld a, [$db4c]
    ld hl, $db4f
    and [hl]
    ld [$db50], a
    ld hl, $db56
    ld a, e
    ld [hl+], a
    ld [hl], d
    inc c
    dec b

jr_058_5fcf:
    push bc
    ld a, [$db4e]
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    call SaveBtlFX_5f57
    ld a, [$db4c]
    ld hl, $db4f
    and [hl]
    ld h, a
    ld a, [$db50]
    cp h
    jr c, jr_058_6027

    jr nz, jr_058_6013

    ld hl, $db57
    ld a, [hl-]
    cp d
    jr c, jr_058_6027

    jr nz, jr_058_6013

    ld a, [hl]
    cp e
    jr c, jr_058_6027

    jr nz, jr_058_6013

    push af
    push bc
    push de
    push hl
    call LoadBtlFX_5c3e
    pop hl
    pop de
    pop bc
    pop af
    ld a, [wRNG1]
    cp $80
    jr c, jr_058_6027

jr_058_6013:
    ld a, [$db4c]
    ld hl, $db4f
    and [hl]
    ld [$db50], a
    ld hl, $db56
    ld a, e
    ld [hl+], a
    ld [hl], d
    ld a, c
    ld [$db60], a

jr_058_6027:
    inc c
    dec b
    jr nz, jr_058_5fcf

    ld a, [$db60]
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


LoadBtlFX_6043:
    ld a, c
    ld [$db60], a
    push bc
    ld a, [$db4e]
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    call SaveBtlFX_5f83
    ld a, [$db4c]
    ld hl, $db4f
    and [hl]
    ld [$db50], a
    ld hl, $db56
    ld a, e
    ld [hl+], a
    ld [hl], d
    inc c
    dec b

jr_058_606c:
    push bc
    ld a, [$db4e]
    ld [$db4c], a
    ld a, c
    ld [wBattleTargetIdx], a
    ld hl, $5206
    rst $10
    pop bc
    call SaveBtlFX_5f83
    ld a, [$db4c]
    ld hl, $db4f
    and [hl]
    ld h, a
    ld a, [$db50]
    cp h
    jr c, jr_058_60c4

    jr nz, jr_058_60b0

    ld hl, $db57
    ld a, [hl-]
    cp d
    jr c, jr_058_60c4

    jr nz, jr_058_60b0

    ld a, [hl]
    cp e
    jr c, jr_058_60c4

    jr nz, jr_058_60b0

    push af
    push bc
    push de
    push hl
    call LoadBtlFX_5c3e
    pop hl
    pop de
    pop bc
    pop af
    ld a, [wRNG1]
    cp $80
    jr c, jr_058_60c4

jr_058_60b0:
    ld a, [$db4c]
    ld hl, $db4f
    and [hl]
    ld [$db50], a
    ld hl, $db56
    ld a, e
    ld [hl+], a
    ld [hl], d
    ld a, c
    ld [$db60], a

jr_058_60c4:
    inc c
    dec b
    jr nz, jr_058_606c

    ld a, [$db60]
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


LoadBtlFX_60e0:
    ld a, h
    or a
    jr nz, jr_058_60ee

    ld a, l
    or a
    jr z, jr_058_60ec

    cp $01
    jr nz, jr_058_60ee

jr_058_60ec:
    scf
    ret


jr_058_60ee:
    ld a, $02
    cp $01
    ret


SaveBtlFX_60f3:
    push hl
    ld b, a
    ld a, [$c86c]
    or a
    jr nz, jr_058_612c

    ld a, b
    cp $03
    jr c, jr_058_6132

    and $03
    cp $03
    jr z, jr_058_613a

    ld a, b
    sub $04
    ld hl, wTempEnemyId1
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a

jr_058_6116:
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    ld hl, $1401
    rst $10
    ld a, [$da25]
    ld c, a
    ld a, [$da26]
    ld b, a
    jr jr_058_6149

jr_058_612c:
    and $03
    cp $03
    jr z, jr_058_613a

jr_058_6132:
    ld hl, $cb1d
    call ReadMonsterWord
    jr jr_058_6149

jr_058_613a:
    ld a, b
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $01
    jr jr_058_6116

jr_058_6149:
    pop hl
    ret


    push hl
    ld bc, $0000
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld e, a
    ld d, $03
    xor a
    ld [$db50], a

jr_058_615d:
    ld a, e
    call CheckMonsterSlot
    jr c, jr_058_6178

    ld a, e
    ld hl, wBattleAGL
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    add hl, bc
    ld b, h
    ld c, l
    ld hl, $db50
    inc [hl]

jr_058_6178:
    inc e
    dec d
    jr nz, jr_058_615d

    ld a, [$db50]
    ld h, b
    ld l, c
    call Div16x8To16
    ld b, h
    ld c, l
    pop hl
    ret


LoadBtlFX_6188:
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    xor $04
    ld [hl], a
    ret


SetBtlFX_619a:
    ld hl, $db58
    ld a, l
    ld [$db5e], a
    ld a, h
    ld [$db5f], a
    ld a, $00
    ld [$db60], a
    ld hl, $db56
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld de, $0201

jr_058_61b3:
    push hl
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    pop hl
    call CmpHLvsBC
    jr c, jr_058_61d9

    jr nz, jr_058_61df

    push af
    push bc
    push de
    push hl
    call LoadBtlFX_5c3e
    pop hl
    pop de
    pop bc
    pop af
    ld a, [wRNG1]
    cp $80
    jr c, jr_058_61df

jr_058_61d9:
    ld h, b
    ld l, c
    ld a, e
    ld [$db60], a

jr_058_61df:
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    inc e
    dec d
    jr nz, jr_058_61b3

    ld a, [$db60]
    ld c, a
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    add c
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


LoadBtlFX_6224:
    ld a, $00
    ld [$db60], a
    ld a, [$db58]
    ld l, a
    ld a, [$db59]
    ld h, a
    ld a, [$db5a]
    ld c, a
    ld a, [$db5b]
    ld b, a
    call CmpHLvsBC
    jr c, jr_058_624b

    ld a, $01
    ld [$db60], a
    ld a, [$db5a]
    ld l, a
    ld a, [$db5b]
    ld h, a

jr_058_624b:
    ld a, [$db5c]
    ld c, a
    ld a, [$db5d]
    ld b, a
    call CmpHLvsBC
    jr c, jr_058_625d

    ld a, $02
    ld [$db60], a

jr_058_625d:
    ld a, [$db60]
    ld c, a
    ld a, [wBattleAttackerIdx]
    and $04
    add c
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


SetBtlFX_627c:
    ld hl, $db56
    ld a, l
    ld [$db5e], a
    ld a, h
    ld [$db5f], a
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a
    ld b, $03
    ret


LoadBtlFX_6292:
    ld a, [$db5e]
    ld l, a
    ld a, [$db5f]
    ld h, a
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl], a
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    ld a, [$db5e]
    add $01
    ld [$db5e], a
    ld a, [$db5f]
    adc $00
    ld [$db5f], a
    ret


Jump_058_62bf:
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld [$db4c], a
    call LoadBtlFX_62d9
    ret


    ld a, [wBattleAttackerIdx]
    and $04
    ld [$db4c], a
    call LoadBtlFX_62d9
    ret


LoadBtlFX_62d9:
    ld a, [$db4c]
    ld c, a
    ld b, $03

jr_058_62df:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_058_62ed

    inc c
    dec b
    jr nz, jr_058_62df

    ld a, [$db4c]
    ld c, a

jr_058_62ed:
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, c
    ld [hl], a
    ret


    ld a, [$dd69]
    or a
    jr nz, jr_058_632a

    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a

jr_058_630b:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_058_631b

    ld a, c
    and $03
    cp $03
    jr z, jr_058_632a

    inc c
    jr jr_058_630b

jr_058_631b:
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], c
    ret


jr_058_632a:
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld c, a
    ld a, c
    and $03
    cp $03
    jr c, jr_058_634f

    ld a, c
    and $04
    xor $04
    ld b, a
    ld a, [wBattleAttackerIdx]
    and $04
    cp b
    ret nz

    ld [hl], b
    ret


jr_058_634f:
    inc c

jr_058_6350:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_058_631b

    ld a, c
    and $03
    cp $03
    ret z

    inc c
    jr jr_058_6350

    ld a, [wBattleAttackerIdx]
    and $04
    ld c, a
    jr jr_058_62ed

    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleAttackerIdx]
    ld [hl], a
    ret


    ld a, [wRNG1]
    ld c, a
    and $07
    call CheckMonsterSlot
    jr nc, jr_058_63b4

    ld a, [wRNG2]
    ld b, a
    and $07
    call CheckMonsterSlot
    jr nc, jr_058_63b7

    or c
    and $07
    call CheckMonsterSlot
    ld c, a
    jr nc, jr_058_63b4

    or b
    and $07
    call CheckMonsterSlot
    jr nc, jr_058_63ba

    ld a, b
    add c
    and $07
    call CheckMonsterSlot
    jr nc, jr_058_63be

jr_058_63a9:
    dec b
    ld a, b
    and $07
    call CheckMonsterSlot
    jr c, jr_058_63a9

    jr jr_058_63b7

jr_058_63b4:
    ld a, c
    jr jr_058_63c0

jr_058_63b7:
    ld a, b
    jr jr_058_63c0

jr_058_63ba:
    ld a, c
    or b
    jr jr_058_63c0

jr_058_63be:
    ld a, b
    add c

jr_058_63c0:
    and $07
    ld c, a
    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$db8a], a
    ld [hl], c
    ret


    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$db8a], a
    ld a, [wBattleAttackerIdx]
    ld [hl], a
    ret


FuncBtlFX_63ec:
    ld c, e
    ld b, $03
    ld d, $00

jr_058_63f1:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_63f8

    inc d

jr_058_63f8:
    inc c
    dec b
    jr nz, jr_058_63f1

    ret


CallBtlFX_63fd:
    call LoadBtlFX_5c3e
    ld a, [wRNG1]
    ld b, a
    ld a, d
    push de
    call Div8x8
    pop bc
    inc a
    ld e, a

jr_058_640c:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_058_6415

jr_058_6412:
    inc c
    jr jr_058_640c

jr_058_6415:
    dec e
    jr nz, jr_058_6412

    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$db8a], a
    ld a, c
    ld [hl], a
    ret


LoadBtlFX_642c:
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld e, a
    call FuncBtlFX_63ec
    call CallBtlFX_63fd
    ret


    call LoadBtlFX_5c3e
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld b, a
    ld a, [wRNG1]
    and $03
    or b
    ld c, a

jr_058_644d:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_058_6462

    ld a, c
    sub $01
    ld c, a
    jr c, jr_058_645c

    cp b
    jr nc, jr_058_644d

jr_058_645c:
    ld a, b
    or $03
    ld c, a
    jr jr_058_644d

jr_058_6462:
    ld a, b
    or c
    ld c, a
    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$db8a], a
    ld a, c
    ld [hl], a
    ret


LoadBtlFX_6479:
    ld a, [wBattleAttackerIdx]
    and $04
    ld e, a
    call FuncBtlFX_63ec
    call CallBtlFX_63fd
    ret


    ld a, [wBattleAttackerIdx]
    and $04
    ld b, a
    ld a, [wRNG1]
    and $03
    or b
    ld c, a
    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $30
    jr z, jr_058_64ac

    cp $31
    jr z, jr_058_64ac

    ld a, c
    jr jr_058_64cb

jr_058_64ac:
    ld a, c

jr_058_64ad:
    ld c, a
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr nz, jr_058_64e1

    ld a, c
    sub $01
    jr c, jr_058_64c4

    cp b
    jr nc, jr_058_64ad

jr_058_64c4:
    ld a, [wBattleAttackerIdx]
    or $03
    jr jr_058_64ad

jr_058_64cb:
    ld c, a
    call CheckMonsterSlot
    jr nc, jr_058_64e1

    ld a, c
    sub $01
    ld c, a
    jr c, jr_058_64da

    cp b
    jr nc, jr_058_64cb

jr_058_64da:
    ld a, [wBattleAttackerIdx]
    or $03
    jr jr_058_64cb

jr_058_64e1:
    ld a, [wBattleAttackerIdx]
    and $04
    or c
    ld c, a
    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$db8a], a
    ld a, c
    ld [hl], a
    ret


SaveBtlFX_64fc:
jr_058_64fc:
    push bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_651f

    call LoadBtlFX_6533
    jr nz, jr_058_6524

    pop bc
    push bc
    ld a, c
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    xor $ff
    ld e, a
    ld a, [hl]
    xor $ff
    ld d, a
    jr jr_058_6527

jr_058_651f:
    ld de, $0000
    jr jr_058_6527

jr_058_6524:
    ld de, $0001

jr_058_6527:
    call LoadBtlFX_6292
    pop bc
    inc c
    dec b
    jr nz, jr_058_64fc

    call SetBtlFX_619a
    ret


LoadBtlFX_6533:
    ld a, c
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld a, [$da33]
    ld hl, $db4c
    cp [hl]
    ret


CallBtlFX_654d:
    call LoadBtlFX_655f
    ret nz

    call LoadBtlFX_642c
    xor a
    ret


CallBtlFX_6556:
    call LoadBtlFX_655f
    ret nz

    call LoadBtlFX_6479
    xor a
    ret


LoadBtlFX_655f:
    ld a, [wBattleAttackerIdx]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    or a
    ret


SetBtlFX_656e:
    ld hl, $dc65
    swap a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld b, $08

jr_058_657b:
    ld a, [hl]
    cp $43
    jr z, jr_058_659b

    cp $5c
    jr c, jr_058_6594

    cp $64
    jr c, jr_058_659b

    cp $6a
    jr c, jr_058_6594

    cp $6e
    jr c, jr_058_659b

    cp $8f
    jr z, jr_058_659b

jr_058_6594:
    inc hl
    inc hl
    dec b
    jr nz, jr_058_657b

    xor a
    ret


jr_058_659b:
    scf
    ret


    push bc
    push de
    push hl
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a
    ld b, $03
    ld e, $00
    ld d, $00

jr_058_65ae:
    ld a, c
    push de
    call CheckMonsterSlot
    pop de
    jr c, jr_058_65cf

    inc e
    ld a, c
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl+]
    and $0c
    jr nz, jr_058_65ce

    inc hl
    ld a, [hl+]
    and $28
    jr nz, jr_058_65ce

    ld a, [hl]
    and $07
    jr z, jr_058_65cf

jr_058_65ce:
    inc d

jr_058_65cf:
    inc c
    dec b
    jr nz, jr_058_65ae

    ld a, d
    cp e
    jr z, jr_058_65da

    scf
    jr jr_058_65de

jr_058_65da:
    ld a, $0a
    cp $01

jr_058_65de:
    pop hl
    pop de
    pop bc
    ret


    push hl
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_058_6607

    ld a, [wBattleTargetIdx]
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl+]
    and $0c
    jr nz, jr_058_6607

    inc hl
    ld a, [hl+]
    and $28
    jr nz, jr_058_6607

    ld a, [hl]
    and $07
    jr nz, jr_058_6607

    scf
    jr jr_058_660b

jr_058_6607:
    ld a, $0a
    cp $01

jr_058_660b:
    pop hl
    ret


SaveBtlFX_660d:
    push hl
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_6623

    ld a, c
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl]
    and $0c
    jr nz, jr_058_6623

    scf
    jr jr_058_6627

jr_058_6623:
    ld a, $0a
    cp $01

jr_058_6627:
    pop hl
    ret


LoadBtlFX_6629:
    ld a, [wBattleAttackerIdx]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $02
    jr z, jr_058_6656

    ld a, [wBattleAttackerIdx]
    and $03
    cp $03
    jr z, jr_058_6650

    ld a, [$c86c]
    or a
    jr nz, jr_058_6656

    ld a, [wBattleAttackerIdx]
    cp $04
    jr c, jr_058_6656

jr_058_6650:
    call CallBtlFX_441b
    xor a
    or a
    ret


jr_058_6656:
    ld a, $01
    or a
    ret


LoadBtlFX_665a:
    ld a, $00
    ld [$db5e], a
    ld a, $01
    ld [$db5f], a
    ld a, $02
    ld [$db60], a

jr_058_6669:
    ld a, [$db5f]
    ld hl, $db58
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, [$db5e]
    ld hl, $db58
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    jr c, jr_058_66b5

    jr nz, jr_058_66bb

    ld a, [$db5f]
    ld hl, $db61
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, [$db5e]
    ld hl, $db61
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    jr nc, jr_058_66bb

jr_058_66b5:
    ld a, [$db5f]
    ld [$db5e], a

jr_058_66bb:
    ld hl, $db5f
    inc [hl]
    ld a, [$db60]
    dec a
    ld [$db60], a
    jr nz, jr_058_6669

    ld a, [$db5e]
    ld c, a
    ld a, [wBattleAttackerIdx]
    and $04
    add c
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


SaveBtlFX_66e7:
    push hl
    push de
    ld a, c
    and $03
    cp $02
    jr z, jr_058_6734

    cp $01
    jr z, jr_058_6714

    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    ld a, [$db58]
    ld e, a
    ld a, [$db59]
    ld d, a
    ld a, l
    ld [$db58], a
    ld a, h
    ld [$db59], a
    ld a, e
    ld [$db56], a
    ld a, d
    ld [$db57], a

jr_058_6714:
    ld a, [$db58]
    ld l, a
    ld a, [$db59]
    ld h, a
    ld a, [$db5a]
    ld e, a
    ld a, [$db5b]
    ld d, a
    ld a, l
    ld [$db5a], a
    ld a, h
    ld [$db5b], a
    ld a, e
    ld [$db58], a
    ld a, d
    ld [$db59], a

jr_058_6734:
    pop de
    pop hl
    ret


    ld a, [wBattleAttackerIdx]
    cp $10
    jr z, jr_058_6750

    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$db4c], a
    call LoadBtlFX_6794
    ret


jr_058_6750:
    ld hl, $db78
    ld a, [hl-]
    ld [$db4c], a
    cp $c2
    jr c, jr_058_6794

    cp $c7
    jr nc, jr_058_6794

    ld a, [hl]
    cp $04

FuncBtlFX_6762:
    ret c

    and $04
    ld c, a
    ld b, $03
    ld d, $ff

jr_058_676a:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_058_677b

jr_058_6770:
    inc c
    dec b
    jr nz, jr_058_676a

    ld a, d
    cp $ff
    ret z

    ld c, d
    jr jr_058_678d

jr_058_677b:
    ld a, d
    cp $ff
    call z, FuncBtlFX_6792
    ld a, c
    ld hl, $db07
    call HL_AddA_x8
    ld a, [hl]
    and $c0
    jr nz, jr_058_6770

jr_058_678d:
    ld hl, $db77
    ld [hl], c
    ret


FuncBtlFX_6792:
    ld d, c
    ret


LoadBtlFX_6794:
jr_058_6794:
    ld a, $00
    ld [$db4d], a
    ld a, $02
    ld [$db4e], a
    push hl
    ld hl, $5400
    rst $10
    pop hl
    ld a, [$db4c]
    and $03
    cp $01
    ret z

jr_058_67ac:
    ld a, [hl]
    call CheckMonsterSlot
    ret nc

    ld a, [hl]
    and $03
    cp $02
    ret z

    inc [hl]
    jr jr_058_67ac

    ld a, $14
    ld [$dd26], a
    call LoadBtlFX_68a5
    ld a, [wBattleAttackerIdx]
    call GetCombatantATK
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    call CmpHLvsBC
    jp c, Jump_058_6859

    ld hl, $dd26
    ld b, $0a
    call ReadBtlFX_6918
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    srl b
    rr c
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    add hl, bc
    push hl
    ld a, [wBattleAttackerIdx]
    call GetCombatantATK
    pop bc
    call CmpHLvsBC
    jr c, jr_058_6859

    ld hl, $dd26
    ld b, $0a
    call ReadBtlFX_6918
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    add hl, bc
    push hl
    ld a, [wBattleAttackerIdx]
    call GetCombatantATK
    pop bc
    call CmpHLvsBC
    jr c, jr_058_6859

    ld hl, $dd26
    ld b, $0a
    call ReadBtlFX_6918
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    add hl, hl
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    srl b
    rr c
    add hl, bc
    push hl
    ld a, [wBattleAttackerIdx]
    call GetCombatantATK
    pop bc
    call CmpHLvsBC
    jr c, jr_058_6859

    ld hl, $dd26
    ld b, $0a
    call ReadBtlFX_6918

Jump_058_6859:
jr_058_6859:
    ld a, [wBattleAttackerIdx]
    ld hl, $db03
    call HL_AddA_x8
    ld a, [hl+]
    and $0c
    jr nz, jr_058_686e

    inc hl
    inc hl
    ld a, [hl]
    and $03
    jr z, jr_058_6876

jr_058_686e:
    ld hl, $dd26
    ld b, $1e
    call ReadBtlFX_6918

jr_058_6876:
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a
    ld b, $03

jr_058_6880:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_689b

    ld a, c
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl+]
    and $0c
    jr nz, jr_058_689b

    inc hl
    bit 5, [hl]
    jr nz, jr_058_689b

    inc hl
    bit 2, [hl]
    ret z

jr_058_689b:
    inc c
    dec b
    jr nz, jr_058_6880

    ld a, $01
    ld [$dd26], a
    ret


LoadBtlFX_68a5:
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a
    ld b, $03

jr_058_68af:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_058_68c5

    ld a, c
    ld hl, wBattleDEF
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    jr jr_058_68c8

jr_058_68c5:
    ld de, $ffff

jr_058_68c8:
    ld a, $03
    sub b
    ld hl, $db58
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], e
    inc hl
    ld [hl], d
    inc c
    dec b
    jr nz, jr_058_68af

    ld a, [$db58]
    ld l, a
    ld a, [$db59]
    ld h, a
    ld a, [$db5a]
    ld c, a
    ld a, [$db5b]
    ld b, a
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    call CmpHLvsBC
    jr c, jr_058_6903

    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a
    ld h, b
    ld l, c

jr_058_6903:
    ld a, [$db5c]
    ld c, a
    ld a, [$db5d]
    ld b, a
    call CmpHLvsBC
    ret c

    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a
    ret


ReadBtlFX_6918:
    ld a, [hl]
    add b
    ld [hl], a
    ret nc

    ld a, $ff
    ld [hl], a
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
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

DataBtlFX_7959:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
