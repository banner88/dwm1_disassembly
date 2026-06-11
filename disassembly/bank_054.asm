; =============================================================================
; BANK $54 — POST-BATTLE PROCESSING, MONSTER JOIN SYSTEM
; =============================================================================
; Contains:
;   - Post-battle EXP distribution and level-up (entries 0-6)
;   - Monster join decision (entry 7 → JoinDecision at $55BB)
;   - Join probability calculation
;
; JOIN SYSTEM (entry 7, $55BB):
;   1. Generates RNG seed
;   2. Reads $DD61 (defeated monster slot, 0 = none)
;   3. Checks $DB85+slot (joinability flag): $07 = non-joinable, else = recruitable
;   4. Reads monster species from $DC3C+slot
;   5. Checks party capacity via Call_000_267E
;   6. Calls join probability handler (Call_054_560E or LoadB54_5655)
;   7. If join succeeds: LoadB54_5683 processes the join
;   8. If join fails: increments $D9EC to advance post-battle state
;
; KEY RAM:
;   $DB85+N: Per-enemy joinability ($07=non-joinable, $00-$06=joinable tiers)
;   $DB4D:   Current join tier (copied from $DB85+slot)
;   $DB4C:   Party capacity flag
;   $DC3C+N: Enemy species ID per battle slot
;   $DD61:   Defeated monster slot for join check (0 = no candidate)
;   $D9EC:   Post-battle state machine index
;   $CA94:   Party/storage count
;
; Sources: DISCOVERIES_v2 watchpoint analysis, disassembly trace
; =============================================================================

; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $054", ROMX[$4000], BANK[$54]

    db $54 ; Bank number

    ; Cross-bank dispatch table (231 entries)
    ; Called via: ld hl, $54XX / rst $10
    dw LoadB54_5249                  ; Entry 0
    dw LoadB54_526e                  ; Entry 1
    dw $5298                          ; Entry 2
    dw $52C7                          ; Entry 3
    dw $5313                          ; Entry 4
    dw $535F                          ; Entry 5
    dw $53AC                          ; Entry 6
    dw $55BB                          ; Entry 7
    dw $5405                          ; Entry 8
    dw $41CF                          ; Entry 9
    dw $41E2                          ; Entry 10
    dw $41F5                          ; Entry 11
    dw $4208                          ; Entry 12
    dw $421B                          ; Entry 13
    dw $422E                          ; Entry 14
    dw $4241                          ; Entry 15
    dw $4254                          ; Entry 16
    dw $4267                          ; Entry 17
    dw $427A                          ; Entry 18
    dw $428D                          ; Entry 19
    dw $42A0                          ; Entry 20
    dw $42B3                          ; Entry 21
    dw $42C6                          ; Entry 22
    dw $42D9                          ; Entry 23
    dw $42EC                          ; Entry 24
    dw $42FF                          ; Entry 25
    dw $4312                          ; Entry 26
    dw jr_054_4325                    ; Entry 27
    dw $4338                          ; Entry 28
    dw $434B                          ; Entry 29
    dw $435E                          ; Entry 30
    dw $4371                          ; Entry 31
    dw $4384                          ; Entry 32
    dw $4397                          ; Entry 33
    dw $43AA                          ; Entry 34
    dw $43BD                          ; Entry 35
    dw $43D0                          ; Entry 36
    dw $43E3                          ; Entry 37
    dw $43F6                          ; Entry 38
    dw $4409                          ; Entry 39
    dw $441C                          ; Entry 40
    dw $442F                          ; Entry 41
    dw $4442                          ; Entry 42
    dw $4455                          ; Entry 43
    dw $4468                          ; Entry 44
    dw $447B                          ; Entry 45
    dw $448E                          ; Entry 46
    dw $44A1                          ; Entry 47
    dw $44B4                          ; Entry 48
    dw $44C7                          ; Entry 49
    dw $44DA                          ; Entry 50
    dw $44ED                          ; Entry 51
    dw $4500                          ; Entry 52
    dw $4513                          ; Entry 53
    dw $4526                          ; Entry 54
    dw $4539                          ; Entry 55
    dw $454C                          ; Entry 56
    dw $455F                          ; Entry 57
    dw $4572                          ; Entry 58
    dw $4585                          ; Entry 59
    dw $4598                          ; Entry 60
    dw $45AB                          ; Entry 61
    dw $45BE                          ; Entry 62
    dw $45D1                          ; Entry 63
    dw $45E4                          ; Entry 64
    dw $45F7                          ; Entry 65
    dw $460A                          ; Entry 66
    dw $461D                          ; Entry 67
    dw $4630                          ; Entry 68
    dw $4643                          ; Entry 69
    dw $4656                          ; Entry 70
    dw $4669                          ; Entry 71
    dw $467C                          ; Entry 72
    dw $468F                          ; Entry 73
    dw $46A2                          ; Entry 74
    dw $46B5                          ; Entry 75
    dw $46C8                          ; Entry 76
    dw $46DB                          ; Entry 77
    dw $46EE                          ; Entry 78
    dw $4701                          ; Entry 79
    dw $4714                          ; Entry 80
    dw $4727                          ; Entry 81
    dw $473A                          ; Entry 82
    dw $474D                          ; Entry 83
    dw $4760                          ; Entry 84
    dw $4773                          ; Entry 85
    dw $4786                          ; Entry 86
    dw $4799                          ; Entry 87
    dw $47AC                          ; Entry 88
    dw $47BF                          ; Entry 89
    dw $47D2                          ; Entry 90
    dw $47E5                          ; Entry 91
    dw $47F8                          ; Entry 92
    dw $480B                          ; Entry 93
    dw $481E                          ; Entry 94
    dw $4831                          ; Entry 95
    dw $4844                          ; Entry 96
    dw $4857                          ; Entry 97
    dw $486A                          ; Entry 98
    dw $487D                          ; Entry 99
    dw $4890                          ; Entry 100
    dw $48A3                          ; Entry 101
    dw $48B6                          ; Entry 102
    dw $48C9                          ; Entry 103
    dw $48DC                          ; Entry 104
    dw $48EF                          ; Entry 105
    dw $4902                          ; Entry 106
    dw $4915                          ; Entry 107
    dw $4928                          ; Entry 108
    dw jr_054_493b                    ; Entry 109
    dw $494E                          ; Entry 110
    dw $4961                          ; Entry 111
    dw $4974                          ; Entry 112
    dw $4987                          ; Entry 113
    dw $499A                          ; Entry 114
    dw $49AD                          ; Entry 115
    dw $49C0                          ; Entry 116
    dw $49D3                          ; Entry 117
    dw $49E6                          ; Entry 118
    dw $49F9                          ; Entry 119
    dw $4A0C                          ; Entry 120
    dw $4A1F                          ; Entry 121
    dw $4A32                          ; Entry 122
    dw $4A45                          ; Entry 123
    dw $4A58                          ; Entry 124
    dw $4A6B                          ; Entry 125
    dw $4A7E                          ; Entry 126
    dw $4A91                          ; Entry 127
    dw $4AA4                          ; Entry 128
    dw $4AB7                          ; Entry 129
    dw $4ACA                          ; Entry 130
    dw $4ADD                          ; Entry 131
    dw $4AF0                          ; Entry 132
    dw $4B03                          ; Entry 133
    dw $4B16                          ; Entry 134
    dw $4B29                          ; Entry 135
    dw $4B3C                          ; Entry 136
    dw $4B4F                          ; Entry 137
    dw $4B62                          ; Entry 138
    dw $4B75                          ; Entry 139
    dw $4B88                          ; Entry 140
    dw $4B9B                          ; Entry 141
    dw $4BAE                          ; Entry 142
    dw $4BC1                          ; Entry 143
    dw $4BD4                          ; Entry 144
    dw $4BE7                          ; Entry 145
    dw $4BFA                          ; Entry 146
    dw $4C0D                          ; Entry 147
    dw $4C20                          ; Entry 148
    dw $4C33                          ; Entry 149
    dw $4C46                          ; Entry 150
    dw $4C59                          ; Entry 151
    dw $4C6C                          ; Entry 152
    dw $4C7F                          ; Entry 153
    dw $4C92                          ; Entry 154
    dw $4CA5                          ; Entry 155
    dw $4CB8                          ; Entry 156
    dw $4CCB                          ; Entry 157
    dw $4CDE                          ; Entry 158
    dw $4CF1                          ; Entry 159
    dw $4D04                          ; Entry 160
    dw $4D17                          ; Entry 161
    dw $4D2A                          ; Entry 162
    dw $4D3D                          ; Entry 163
    dw $4D50                          ; Entry 164
    dw $4D63                          ; Entry 165
    dw $4D76                          ; Entry 166
    dw $4D89                          ; Entry 167
    dw $4D9C                          ; Entry 168
    dw $4DAF                          ; Entry 169
    dw $4DC2                          ; Entry 170
    dw $4DD5                          ; Entry 171
    dw $4DE8                          ; Entry 172
    dw $4DFB                          ; Entry 173
    dw $4E0E                          ; Entry 174
    dw $4E21                          ; Entry 175
    dw $4E34                          ; Entry 176
    dw $4E47                          ; Entry 177
    dw $4E5A                          ; Entry 178
    dw $4E6D                          ; Entry 179
    dw $4E80                          ; Entry 180
    dw $4E93                          ; Entry 181
    dw $4EA6                          ; Entry 182
    dw $4EB9                          ; Entry 183
    dw $4ECC                          ; Entry 184
    dw $4EDF                          ; Entry 185
    dw $4EF2                          ; Entry 186
    dw $4F05                          ; Entry 187
    dw $4F18                          ; Entry 188
    dw $4F2B                          ; Entry 189
    dw $4F3E                          ; Entry 190
    dw $4F51                          ; Entry 191
    dw $4F64                          ; Entry 192
    dw $4F77                          ; Entry 193
    dw $4F8A                          ; Entry 194
    dw $4F9D                          ; Entry 195
    dw $4FB0                          ; Entry 196
    dw $4FC3                          ; Entry 197
    dw $4FD6                          ; Entry 198
    dw $4FE9                          ; Entry 199
    dw $4FFC                          ; Entry 200
    dw $500F                          ; Entry 201
    dw $5022                          ; Entry 202
    dw $5035                          ; Entry 203
    dw $5048                          ; Entry 204
    dw $505B                          ; Entry 205
    dw $506E                          ; Entry 206
    dw $5081                          ; Entry 207
    dw $5094                          ; Entry 208
    dw $50A7                          ; Entry 209
    dw $50BA                          ; Entry 210
    dw $50CD                          ; Entry 211
    dw $50E0                          ; Entry 212
    dw $50F3                          ; Entry 213
    dw $5106                          ; Entry 214
    dw $5119                          ; Entry 215
    dw $512C                          ; Entry 216
    dw $513F                          ; Entry 217
    dw $5152                          ; Entry 218
    dw $5165                          ; Entry 219
    dw $5178                          ; Entry 220
    dw $518B                          ; Entry 221
    dw $519E                          ; Entry 222
    dw $51B1                          ; Entry 223
    dw $51C4                          ; Entry 224
    dw $51D7                          ; Entry 225
    dw $51EA                          ; Entry 226
    dw $51FD                          ; Entry 227
    dw $5210                          ; Entry 228
    dw $5223                          ; Entry 229
    dw $5236                          ; Entry 230

; --- Dispatch entry 0 ($5249) ---
DispatchEntry_54_0:
    nop
    inc de
    ld de, $0214
    ld bc, $4104
    rlca
    rla
    ld [bc], a
    inc c
    nop
    inc bc
    nop
    rlca
    nop
    dec b
    nop
    nop
    inc de
    ld de, $0414
    ld bc, $4104
    rlca
    rla
    ld [bc], a
    ld b, [hl]
    nop
    inc d
    nop
    ld e, $00
    inc c
    nop
    nop
    inc de
    ld de, $0a14
    ld bc, $4104
    rlca
    rla
    ld [bc], a
    or h
    nop
    inc d
    nop
    ld h, h
    nop
    inc d
    nop
    ld bc, $1213
    ld a, [bc]
    inc b
    ld [bc], a
    inc b
    ld b, c
    rlca
    rla
    ld [bc], a
    stop
    ld [$0a00], sp
    nop
    ld [$0100], sp
    inc de
    ld [de], a
    inc c
    ld b, $02
    inc b
    ld b, c
    rlca
    rla
    ld [bc], a
    ld e, $00
    inc c
    nop
    ld d, $00
    inc c
    nop
    ld bc, $1213
    ld c, $0a
    ld [bc], a
    inc b
    ld b, c
    rlca
    rla
    ld [bc], a
    ld e, b
    nop
    jr jr_054_423d

jr_054_423d:
    inc a
    nop
    inc d
    nop
    ld [bc], a
    inc de
    ld [de], a
    dec bc
    dec b
    inc bc
    inc b
    ld b, c
    rlca
    rla
    ld [bc], a
    inc d
    nop
    ld a, [bc]
    nop
    rrca
    nop
    dec b
    nop
    ld [bc], a
    inc de
    ld [de], a
    dec c
    ld [$0403], sp
    ld b, c
    rlca
    rla
    ld [bc], a
    inc [hl]
    nop
    stop
    inc hl
    nop
    ld a, [bc]
    nop
    ld [bc], a
    inc de
    ld [de], a
    db $10
    rrca
    inc bc
    inc b
    ld b, c
    rlca
    rla
    ld [bc], a
    add d
    nop
    inc d
    nop
    ld e, a
    nop
    inc d
    nop
    inc bc
    inc de
    ld [de], a
    ld a, [bc]
    ld [bc], a
    inc b
    inc b
    ld b, c
    rlca
    rla
    ld [bc], a
    ld [$1000], sp
    nop
    ld b, $00
    inc c
    nop
    inc bc
    inc de
    ld [de], a
    inc c
    inc b
    inc b
    inc b
    ld b, c
    rlca
    rla
    ld [bc], a
    add hl, de
    nop
    ld e, $00
    ld c, $00
    inc d
    nop
    inc bc
    inc de
    ld [de], a
    rrca
    ld [$0404], sp
    ld b, c
    rlca
    rla
    ld [bc], a
    ld d, b
    nop
    ld h, h
    nop
    jr z, jr_054_42b1

jr_054_42b1:
    scf
    nop
    inc b
    inc de
    ld [de], a
    dec bc
    inc bc
    ld b, $04
    ld b, c
    rlca
    rla
    ld [bc], a
    add hl, de
    nop
    ld a, [bc]
    nop
    inc c
    nop
    ld [$0400], sp
    inc de
    ld [de], a
    inc c
    dec b
    ld b, $04
    ld b, c
    rlca
    rla
    ld [bc], a
    ld a, [hl+]
    nop
    stop
    ld e, $00
    ld a, [bc]
    nop
    inc b
    inc de
    ld [de], a
    ld c, $0c
    ld b, $04
    ld b, c
    rlca
    rla
    ld [bc], a
    ld d, b
    nop
    jr jr_054_42e8

jr_054_42e8:
    inc a
    nop
    ld a, [bc]
    nop
    dec b
    inc de
    ld [de], a
    inc c
    dec b
    dec b
    inc b
    ld b, c
    rlca
    rla
    ld [bc], a
    inc hl
    nop
    rrca
    nop
    inc d
    nop
    ld a, [bc]
    nop
    dec b
    inc de
    ld [de], a
    dec c
    ld a, [bc]
    dec b
    inc b
    ld b, c
    rlca
    rla
    ld [bc], a
    ld b, [hl]
    nop
    inc d
    nop
    dec l
    nop
    ld e, $00
    dec b
    inc de
    ld [de], a
    db $10
    rrca
    dec b
    inc b
    ld b, c
    rlca
    rla
    ld [bc], a
    xor a
    nop
    ld [hl-], a
    nop
    ld a, b
    nop
    jr z, jr_054_4325

jr_054_4325:
    ld b, $13
    ld de, $0414
    add hl, bc
    inc bc
    ld b, b
    rlca
    ld [de], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld b, $13
    ld [de], a
    ld a, [bc]
    rlca
    add hl, bc
    inc bc
    ld b, b
    rlca
    ld [de], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rlca
    inc de
    ld de, $0100
    rrca
    ld bc, $0740
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld [$1123], sp
    ld a, [bc]
    inc bc
    ld [$4000], sp
    rlca
    ld d, e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld [$1223], sp
    inc c
    dec b
    ld [$4003], sp
    rlca
    ld d, e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    add hl, bc
    inc hl
    ld [de], a
    rrca
    inc bc
    dec bc
    nop
    ld b, b
    rlca
    ld d, e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld a, [bc]
    inc hl
    ld [de], a
    rrca
    inc bc
    rlca
    nop
    ld b, b
    rlca
    ld d, a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec bc
    ld [hl+], a
    ld [de], a
    rrca
    dec b
    inc c
    inc bc
    ld b, b
    rlca
    ld d, e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc c
    inc hl
    ld de, $000a
    ld a, [bc]
    nop
    ld b, b
    rlca
    ld [de], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec c
    inc hl
    ld b, c
    inc c
    ld [bc], a
    nop
    nop
    ld b, b
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld c, $23
    ld de, $030a
    dec c
    nop
    ld b, b
    rlca
    ld d, a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld c, $23
    ld [de], a
    inc c
    inc b
    dec c
    nop
    ld b, b
    rlca
    ld d, a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rrca
    inc hl
    ld hl, $020a
    nop
    nop
    ld b, b
    inc b
    ld d, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rrca
    inc hl
    ld [hl+], a
    rrca
    inc bc
    nop
    nop
    ld b, b
    inc b
    ld d, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    db $10
    inc hl
    ld de, $030a
    ld c, $00
    ld b, b
    rlca
    ld d, a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    db $10
    inc hl
    ld [de], a
    rrca
    inc b
    ld c, $00
    ld b, b
    rlca
    ld d, a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld de, $2123
    ld a, [bc]
    ld [bc], a
    nop
    nop
    ld b, b
    inc b
    ld d, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld de, $2223
    rrca
    inc bc
    nop
    nop
    ld b, b
    inc b
    ld d, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld [de], a
    inc hl
    ld hl, $0310
    nop
    nop
    ld b, b
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc de
    inc hl
    ld hl, $0610
    nop
    nop
    ld b, b
    inc b
    ld d, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc d
    inc hl
    ld hl, $030a
    nop
    nop
    ld b, b
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec d
    inc hl
    ld b, c
    ld a, [bc]
    inc b
    nop
    nop
    ld b, b
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec d
    inc hl
    ld b, c
    db $10
    inc b
    nop
    nop
    ld b, b
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld d, $23
    ld de, $050a
    nop
    nop
    ld b, b
    nop
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rla
    inc sp
    ld hl, $0200
    nop
    nop
    ld c, b
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    jr jr_054_4535

    ld hl, $0214
    nop
    nop
    ld b, b
    inc b
    ld [de], a
    inc bc
    ld e, $00
    ld a, [bc]
    nop
    ld e, $00
    ld a, [bc]
    nop
    jr jr_054_4548

    ld hl, $0514
    nop
    nop
    ld b, b
    inc b
    ld [de], a
    inc bc
    ld c, e
    nop
    rrca
    nop
    ld c, e
    nop
    rrca
    nop
    jr jr_054_455b

    ld hl, $0714
    nop
    nop
    ld b, b
    inc b
    ld [de], a
    inc bc
    rst $20
    inc bc
    nop
    nop

jr_054_4535:
    rst $20
    inc bc
    nop
    nop
    add hl, de
    inc sp
    ld [hl+], a
    ld a, [bc]
    ld [de], a
    nop
    nop
    ld b, b
    inc b
    ld [de], a
    inc bc
    ld e, d
    nop
    ld e, $00

jr_054_4548:
    ld b, [hl]
    nop
    ld e, $00
    add hl, de
    inc sp
    ld [hl+], a
    ld a, [bc]
    inc h
    nop
    nop
    ld b, b
    inc b
    ld [bc], a
    inc bc
    rst $20
    inc bc
    nop
    nop

jr_054_455b:
    rst $20
    inc bc
    nop
    nop
    ld a, [de]
    inc sp
    ld hl, $0a0f
    nop
    nop
    ld b, b
    inc b
    ld [de], a
    inc bc
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld a, [de]
    inc sp
    ld hl, $1414
    nop
    nop
    ld b, b
    inc b
    ld [de], a
    inc bc
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec de
    inc sp
    ld hl, $0100
    nop
    nop
    ld b, b
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc e
    inc sp
    ld hl, $0214
    nop
    nop
    ld b, b
    inc b
    ld [de], a
    inc bc
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec e
    inc sp
    ld [hl+], a
    inc d
    ld [bc], a
    nop
    nop
    ld b, b
    inc b
    ld a, [bc]
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld e, $33
    ld [hl+], a
    inc d
    ld [bc], a
    nop
    nop
    ld b, b
    inc b
    ld a, [bc]
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rra
    inc sp
    ld [hl+], a
    inc d
    ld [bc], a
    nop
    nop
    ld b, b
    inc b
    ld [bc], a
    inc bc
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc hl
    inc de
    ld de, $0014
    nop
    nop
    add e
    cp $3e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc hl
    inc de
    ld de, $0014
    nop
    nop
    add e
    cp $3e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld [hl+], a
    inc hl
    nop
    inc d
    inc d
    nop
    nop
    ld b, b
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc hl
    inc de
    ld de, $0014
    nop
    nop
    add e
    cp $3e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc h
    inc de
    ld de, $020a
    nop
    nop
    add e
    adc [hl]
    ccf
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec h
    inc de
    ld de, $0100
    rrca
    inc b
    add e
    adc [hl]
    dec sp
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, $13
    ld de, $010a
    nop
    inc b
    add e
    adc [hl]
    dec sp
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    daa
    inc de
    ld de, $0100
    rrca
    inc b
    add d
    adc [hl]
    dec hl
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    jr z, jr_054_4691

    ld de, $030a
    nop
    nop
    add e
    adc [hl]
    ccf
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    add hl, hl
    inc de

jr_054_4691:
    ld de, $030a
    nop
    nop
    add e
    adc [hl]
    ccf
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld a, [hl+]
    inc hl
    ld b, c
    rrca
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec hl
    inc de
    ld de, $050a
    nop
    nop
    add e
    adc [hl]
    inc bc
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc l
    inc hl
    ld b, c
    inc d
    nop
    nop
    nop
    db $10
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec l
    inc de
    ld de, $030a
    ld bc, $8306
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld l, $13
    ld de, $030a
    dec b
    ld b, $83
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    cpl
    inc de
    ld de, $030a
    inc b
    ld b, $83
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    jr nc, @+$15

    ld de, $030a
    ld b, $06
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld sp, $1113
    ld a, [bc]
    inc bc
    nop
    nop
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld [hl-], a
    inc de
    ld de, $030a
    nop
    nop
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc sp
    inc de
    ld de, $030a
    nop
    nop
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc [hl]
    inc de
    ld de, $030a
    nop
    nop
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec [hl]
    inc de
    ld de, $030a
    nop
    nop
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld [hl], $13
    ld de, $030a
    nop
    nop
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    scf
    inc de
    ld de, $030a
    nop
    nop
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    jr c, jr_054_47c1

    ld [de], a
    db $10
    inc d
    inc b
    dec b
    ld bc, $1706
    ld [bc], a
    or h
    nop
    ld e, $00
    ld e, d
    nop
    ld [hl-], a
    nop
    add hl, sp
    inc de

jr_054_47c1:
    ld de, $030c
    nop
    nop
    add e
    cp $3a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    add hl, sp
    inc de
    ld de, $060e
    nop
    nop
    add e
    cp $3a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld a, [hl-]
    inc de
    ld de, $040c
    add hl, de
    inc b
    ld bc, $3a0e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld a, [hl-]
    inc de
    ld de, $080e
    add hl, de
    inc b
    ld bc, $3a0e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec sp
    inc hl
    ld b, c
    inc d
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc a
    inc de
    ld de, $020c
    nop
    nop
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec a
    inc de
    ld de, $0314
    nop
    nop
    add e
    adc [hl]
    ccf
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld a, $13
    ld [de], a
    ld a, [bc]
    dec b
    nop
    inc b
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ccf
    inc de
    ld de, $0314
    inc b
    inc b
    ld bc, $1f06
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ccf
    inc de
    ld [de], a
    dec c
    ld b, $04
    inc b
    ld bc, $1706
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld b, b
    inc de
    ld [de], a
    inc c
    inc bc
    dec b
    inc b
    ld bc, $1706
    ld [bc], a
    jr z, jr_054_488a

jr_054_488a:
    inc d
    nop
    add hl, de
    nop
    rrca
    nop
    ld b, c
    inc de
    ld [de], a
    ld c, $05
    add hl, de
    inc b
    ld bc, $3f06
    ld [bc], a
    ld e, d
    nop
    jr z, jr_054_489f

jr_054_489f:
    jr z, jr_054_48a1

jr_054_48a1:
    ld e, $00
    ld b, d
    inc de
    ld [de], a
    ld a, [bc]
    ld [bc], a
    ld de, $1505
    ld b, $17
    ld [bc], a
    ld c, $00
    ld [$0a00], sp
    nop
    ld b, $00
    ld b, d
    inc de
    ld [de], a
    inc c
    inc b
    ld de, $1505
    ld b, $17
    ld [bc], a
    jr nz, jr_054_48c3

jr_054_48c3:
    stop
    inc d
    nop
    stop
    ld b, d
    inc de
    ld [de], a
    ld c, $08
    ld de, $1505
    ld b, $17
    ld [bc], a
    ld c, e
    nop
    add hl, de
    nop
    dec l
    nop
    add hl, de
    nop
    ld b, d
    inc de
    ld [de], a
    db $10
    db $10
    ld de, $1505
    ld b, $17
    ld [bc], a
    sub [hl]
    nop
    inc d
    nop
    ld d, l
    nop
    inc hl
    nop
    ld b, e
    inc de
    ld [de], a
    ld a, [bc]
    ld [bc], a
    ld [de], a
    dec b
    dec d
    ld b, $17
    ld [bc], a
    stop
    ld [$0e00], sp
    nop
    inc b
    nop
    ld b, e
    inc de
    ld [de], a
    inc c
    inc b
    ld [de], a
    dec b
    dec d
    ld b, $17
    ld [bc], a
    ld a, [hl+]
    nop
    inc c
    nop
    add hl, de
    nop
    rrca
    nop
    ld b, e
    inc de
    ld [de], a
    ld c, $08
    ld [de], a
    dec b
    dec d
    ld b, $17
    ld [bc], a
    ld d, d
    nop
    ld e, $00
    ld [hl-], a
    nop
    ld e, $00
    ld b, e
    inc de
    ld [de], a
    db $10
    db $10
    ld [de], a
    dec b
    dec d
    ld b, $17
    ld [bc], a
    and b
    nop
    inc d
    nop
    ld e, d
    nop
    jr z, jr_054_493b

jr_054_493b:
    ld b, h
    inc de
    ld [de], a
    db $10
    add hl, de
    dec b
    nop
    ld bc, $1706
    ld [bc], a
    jp nc, $5000

    nop
    xor d
    nop
    ld e, $00
    ld b, l
    inc de
    ld [de], a
    db $10
    ld e, $01
    dec b
    ld bc, $1706
    ld [bc], a
    inc l
    ld bc, $0064
    ldh a, [rP1]
    inc a
    nop
    ld b, [hl]
    ld [de], a
    ld [de], a
    nop
    ld bc, $0510
    ld bc, $0206
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld b, a
    inc de
    ld de, $020a
    inc de
    inc bc
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld c, b
    inc de
    ld de, $020a
    ld [$8303], sp
    cp $33
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld c, c
    inc de
    ld de, $030a
    inc d
    inc bc
    add e
    cp $3b
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld c, d
    inc hl
    ld [de], a
    inc c
    inc bc
    ld [$1003], sp
    ld b, $33
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld c, e
    inc hl
    ld [de], a
    db $10
    inc b
    inc d
    inc bc
    db $10
    ld b, $33
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld c, h
    inc hl
    ld [de], a
    inc c
    inc bc
    inc de
    inc bc
    db $10
    ld b, $37
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld c, h
    inc hl
    ld [de], a
    db $10
    inc b
    inc de
    inc bc
    db $10
    ld b, $37
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld c, l
    inc hl
    ld [de], a
    rrca
    inc b
    inc c
    inc b
    jr nz, jr_054_4a08

    inc sp
    ld [bc], a
    nop
    nop
    nop
    nop

jr_054_4a08:
    nop
    nop
    nop
    nop
    ld c, [hl]
    inc hl
    ld [de], a
    db $10
    inc bc
    dec d
    inc b
    nop
    ld b, $37
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld c, a
    inc hl
    ld de, $010a
    ld d, $00
    nop
    ld b, $33
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld d, b
    inc de
    ld [de], a
    ld a, [bc]
    ld b, $09
    inc bc
    jr nz, jr_054_4a41

    ld [de], a
    ld [bc], a
    nop
    nop
    nop
    nop

jr_054_4a41:
    nop
    nop
    nop
    nop
    ld d, c
    inc hl
    ld [de], a
    inc c
    ld [bc], a
    rlca
    ld [bc], a
    nop
    ld b, $37
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld d, d
    inc hl
    ld [de], a
    inc c
    ld [bc], a
    rlca
    nop
    nop
    ld b, $37
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld d, e
    inc hl
    ld [de], a
    inc c
    ld [bc], a
    add hl, bc
    nop
    nop
    ld b, $37
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld d, h
    inc hl
    ld de, $000a
    ld a, [bc]
    nop
    jr nz, jr_054_4a8d

    ld [hl], $02
    nop
    nop
    nop
    nop

jr_054_4a8d:
    nop
    nop
    nop
    nop
    ld d, h
    inc hl
    ld de, $000f
    ld a, [bc]
    nop
    jr nz, jr_054_4aa0

    ld [hl], $02
    nop
    nop
    nop
    nop

jr_054_4aa0:
    nop
    nop
    nop
    nop
    ld d, l
    inc hl
    ld b, c
    inc c
    ld bc, $0000
    jr nz, jr_054_4ab3

    ld h, d
    ld [bc], a
    nop
    nop
    nop
    nop

jr_054_4ab3:
    nop
    nop
    nop
    nop
    ld d, [hl]
    inc hl
    ld [de], a
    inc c
    ld [bc], a
    ld d, $00
    jr nz, jr_054_4ac6

    inc sp
    ld [bc], a
    nop
    nop
    nop
    nop

jr_054_4ac6:
    nop
    nop
    nop
    nop
    ld d, a
    inc hl
    ld de, $020a
    ld d, $00
    nop
    ld b, $33
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld d, a
    inc hl
    ld de, $040a
    dec c
    nop
    nop
    ld b, $73
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld e, b
    inc hl
    ld de, $010a
    ld d, $00
    nop
    ld b, $33
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld e, b
    inc hl
    ld [de], a
    inc c
    inc bc
    ld d, $03
    nop
    ld b, $33
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld e, c
    inc hl
    ld [de], a
    rrca
    inc bc
    ld d, $03
    nop
    ld b, $33
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc hl
    inc de
    ld de, $0014
    nop
    nop
    add e
    cp $3e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld e, e
    ld hl, $0a41
    inc b
    nop
    nop
    ld [$4204], sp
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld e, h
    inc hl
    ld de, $070a
    nop
    nop
    nop
    nop
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld e, l
    inc sp
    ld [hl+], a
    inc d
    rlca
    nop
    nop
    nop
    inc b
    ld a, [bc]
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld e, [hl]
    inc hl
    ld de, $070a
    add hl, bc
    ld [bc], a
    nop
    inc b
    ld d, a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld e, a
    inc hl
    ld bc, $0800
    nop
    nop
    nop
    nop
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, b
    inc hl
    ld hl, $1414
    nop
    nop
    nop
    inc b
    ld d, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, b
    inc hl
    ld hl, $1414
    nop
    nop
    nop
    inc b
    ld d, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, b
    inc hl
    ld hl, $1414
    nop
    nop
    nop
    inc b
    ld d, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, b
    inc hl
    ld hl, $1414
    nop
    nop
    nop
    inc b
    ld d, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, c
    inc sp
    ld hl, $020a
    nop
    nop
    ld [$0204], sp
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, c
    inc sp
    ld hl, $040a
    nop
    nop
    ld [$0204], sp
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, d
    inc hl
    ld b, c
    inc c
    ld b, $00
    nop
    nop
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, d
    inc hl
    ld hl, $0a10
    nop
    nop
    nop
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, e
    inc sp
    ld b, c
    db $10
    inc b
    nop
    nop
    ld [$0204], sp
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, h
    inc sp
    ld b, c
    nop
    nop
    nop
    nop
    ld [$0204], sp
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, l
    inc sp
    ld b, c
    db $10
    inc bc
    nop
    nop
    ld [$0204], sp
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, [hl]
    inc sp
    ld hl, $020a
    nop
    nop
    jr jr_054_4c79

    ld b, d
    ld [bc], a
    nop
    nop

jr_054_4c79:
    nop
    nop
    nop
    nop
    nop
    nop
    ld h, a
    inc sp
    ld b, c
    inc c
    inc bc
    nop
    nop
    ld [$4204], sp
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld l, b
    inc hl
    ld [de], a
    rrca
    ld b, $17
    nop
    jr nz, jr_054_4ca1

    ld d, e
    ld [bc], a
    nop
    nop
    nop
    nop

jr_054_4ca1:
    nop
    nop
    nop
    nop
    ld l, c
    inc hl
    ld de, $060f
    jr jr_054_4cac

jr_054_4cac:
    nop
    ld b, $57
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld l, d
    inc sp
    ld b, c
    inc d
    ld [$0000], sp
    nop
    inc b
    ld [de], a
    ld [bc], a
    db $f4
    ld bc, $0000
    db $f4
    ld bc, $0000
    ld l, e
    inc sp
    ld [hl+], a
    inc d
    inc c
    nop
    nop
    jr nz, jr_054_4cd8

    ld [de], a
    ld [bc], a
    ld b, [hl]
    nop

jr_054_4cd8:
    ld a, [bc]
    nop
    ld b, [hl]
    nop
    ld a, [bc]
    nop
    ld l, h
    inc sp
    ld hl, $140a
    nop
    nop
    nop
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld l, l
    inc sp
    ld hl, $0100
    nop
    nop
    jr nz, jr_054_4cfe

    ld [bc], a
    ld [bc], a
    nop
    nop

jr_054_4cfe:
    nop
    nop
    nop
    nop
    nop
    nop
    ld l, [hl]
    ld b, d
    ld [hl+], a
    nop
    nop
    nop
    nop
    nop
    inc b
    nop
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld l, a
    ld b, c
    ld b, c
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld d, e
    ld hl, $0000
    nop
    nop
    add e
    xor [hl]
    ld a, [de]
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld d, e
    ld de, $0000
    nop
    nop
    add e
    cp [hl]
    ld e, $02
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld d, e
    ld b, c
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld d, e
    ld b, c
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld d, c
    ld b, c
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld d, e
    ld b, c
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld d, c
    ld b, c
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld d, c
    ld b, c
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld d, c
    ld b, c
    nop
    nop
    nop
    nop
    nop
    inc b
    nop
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld h, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    inc b
    nop
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld h, e
    ld [hl+], a
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    rst $20
    inc bc
    nop
    nop
    rst $20
    inc bc
    nop
    nop
    rst $38
    ld h, d
    ld [de], a
    nop
    nop
    nop
    nop
    nop
    inc b
    nop
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld h, e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    ld b, b
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld h, e
    ld hl, $0000
    nop
    nop
    nop
    inc b
    ld b, b
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld h, e
    ld bc, $0000
    nop
    nop
    nop
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld h, e
    ld bc, $0000
    nop
    nop
    nop
    inc b
    nop
    ld [bc], a
    rst $20
    inc bc
    nop
    nop
    rst $20
    inc bc
    nop
    nop
    rst $38
    ld h, e
    ld b, c
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld h, e
    ld b, c
    nop
    nop
    nop
    nop
    nop
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld h, e
    ld [de], a
    nop
    nop
    nop
    nop
    add e
    adc [hl]
    ld a, [bc]
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld h, e
    ld [de], a
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld h, e
    ld [hl+], a
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    ld h, e
    ld [hl+], a
    nop
    nop
    nop
    nop
    nop
    inc b
    ld [bc], a
    ld [bc], a
    rst $20
    inc bc
    nop
    nop
    rst $20
    inc bc
    nop
    nop
    rst $38
    ld h, e
    ld bc, $0000
    nop
    nop
    nop
    inc b
    nop
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    ld e, $00
    ld a, [bc]
    nop
    ld e, $00
    ld a, [bc]
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    inc a
    nop
    ld a, [bc]
    nop
    inc a
    nop
    ld a, [bc]
    nop
    rst $38
    add h
    ld [hl-], a
    nop
    nop
    nop
    nop
    nop
    inc b
    inc hl
    ld [bc], a
    dec l
    nop
    ld a, [bc]
    nop
    dec l
    nop
    ld a, [bc]
    nop
    rst $38
    add h
    ld [hl-], a
    nop
    nop
    nop
    nop
    nop
    inc b
    inc hl
    ld [bc], a
    rst $20
    inc bc
    nop
    nop
    rst $20
    inc bc
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    inc d
    nop
    ld a, [bc]
    nop
    inc d
    nop
    ld a, [bc]
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    rst $20
    inc bc
    nop
    nop
    rst $20
    inc bc
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    dec b
    nop
    nop
    nop
    ld a, [bc]
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    ld a, [bc]
    nop
    nop
    nop
    ld e, $00
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    inc d
    nop
    nop
    nop
    ld h, h
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    dec b
    nop
    nop
    nop
    dec b
    nop
    nop
    nop
    rst $38
    add h
    ld sp, $0000
    nop
    nop
    nop
    inc b
    inc hl
    inc bc
    ld h, h
    nop
    nop
    nop
    sub b
    ld bc, $0000
    rst $38
    add h
    ld [de], a
    nop
    nop
    dec b
    nop
    ld bc, $2306
    ld [bc], a
    inc hl
    nop
    rrca
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld [de], a
    nop
    nop
    inc b
    nop
    ld bc, $2306
    ld [bc], a
    ld [$1000], sp
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld [de], a
    nop
    nop
    rlca
    nop
    ld bc, $6306
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld [de], a
    nop
    nop
    ld [bc], a
    nop
    ld bc, $2306
    ld [bc], a
    ld e, $00
    inc c
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld [de], a
    nop
    nop
    ld [de], a
    nop
    ld bc, $2306
    ld [bc], a
    ld d, b
    nop
    ld e, $00
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld [hl+], a
    nop
    nop
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld hl, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld hl, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld hl, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld hl, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld hl, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld hl, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld hl, $0000
    nop
    nop
    nop
    inc b
    inc hl
    ld bc, $0000
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    add h
    ld de, $0000
    ld bc, $0100
    ld b, $23
    ld [bc], a
    adc h
    nop
    ld e, $00
    nop
    nop
    nop
    nop
    ld [hl], b
    ld [hl+], a
    ld b, c
    inc d
    add hl, bc
    nop
    nop
    ld b, b
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld [hl], c
    inc de
    ld de, $030a
    nop
    nop
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld [hl], d
    inc de
    ld de, $030a
    nop
    nop
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld [hl], e
    inc de
    ld de, $030a
    nop
    nop
    add e
    cp $3f
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld [hl], h
    inc de
    ld de, $1410
    ld a, [de]
    inc b
    add e
    adc [hl]
    ccf
    ld [bc], a
    ld e, [hl]
    ld bc, $003c
    ld c, $01
    ld [hl-], a
    nop
    ld [hl], l
    ld hl, $0a11
    dec b
    inc c
    inc bc
    ld b, b
    rlca
    ld d, e
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    db $76
    ld sp, $2841
    nop
    nop
    nop
    nop
    inc b
    nop
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld [hl], a
    ld sp, $0a41
    ld [bc], a
    nop
    nop
    ld c, b
    inc b
    ld b, d
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld a, b
    inc de
    ld de, $020a
    nop
    nop
    add e
    sbc [hl]
    inc de
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

LoadB54_5249:
    ld a, [$db4c]
    ld c, a
    ld a, [$db4d]
    ld b, a
    ld hl, $4013
    add hl, bc
    add hl, bc
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [$db4e]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, c
    ld [$db4c], a
    ld a, b
    ld [$db4d], a
    ret


LoadB54_526e:
    ld a, [$db4c]
    ld c, a
    ld a, [$db4d]
    ld b, a
    ld hl, $4013
    add hl, bc
    add hl, bc
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [$db4e]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    inc hl
    ld a, [hl]
    ld [$db4e], a
    ld a, c
    ld [$db4c], a
    ld a, b
    ld [$db4d], a
    ret


    ld a, [$db8a]
    ld c, a
    ld b, $00
    ld hl, $4013
    add hl, bc
    add hl, bc
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, $02
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$dcfc], a
    ld a, $05
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$dcfd], a
    ld a, [hl+]
    ld [$dcfe], a
    ld a, [hl]
    ld [$dcff], a
    ret


    ld a, [$db8a]
    ld [$db4c], a
    ld a, $00
    ld [$db4d], a
    ld a, [wBattleAttackerIdx]
    bit 2, a
    jr z, jr_054_52e0

    ld a, $0f
    ld [$db4e], a
    jr jr_054_52e5

jr_054_52e0:
    ld a, $0b
    ld [$db4e], a

jr_054_52e5:
    call LoadB54_526e
    ld a, [$db4c]
    ld c, a
    ld a, [$db4d]
    ld b, a
    ld a, [wBattleAttackerIdx]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $02
    jr z, jr_054_530a

    ld a, [$db4e]
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a

jr_054_530a:
    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a
    ret


    ld a, [$db8a]
    ld [$db4c], a
    ld a, $00
    ld [$db4d], a
    ld a, [wBattleAttackerIdx]
    bit 2, a
    jr z, jr_054_532c

    ld a, $0f
    ld [$db4e], a
    jr jr_054_5331

jr_054_532c:
    ld a, $0b
    ld [$db4e], a

jr_054_5331:
    call LoadB54_526e
    ld a, [$db4c]
    ld c, a
    ld a, [$db4d]
    ld b, a
    ld a, [wBattleAttackerIdx]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $02
    jr z, jr_054_5356

    ld a, [$db4e]
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a

jr_054_5356:
    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a
    ret


    ld a, [$db4c]
    cp $d5
    jr z, jr_054_539d

    jr nc, jr_054_53a6

    ld a, $00
    ld [$db4d], a
    ld a, $0a
    ld [$db4e], a
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    push hl
    call LoadB54_5249
    pop hl
    ld a, [$db4c]
    cp $01
    jr z, jr_054_53a6

    ld a, l
    ld [$db4c], a
    ld a, h
    ld [$db4d], a
    push hl
    ld a, $02
    ld [$db4e], a
    call LoadB54_5249
    pop hl
    ld a, l
    ld [$db4d], a
    ret


jr_054_539d:
    ld [$db4d], a
    ld a, $12
    ld [$db4c], a
    ret


jr_054_53a6:
    ld a, $00
    ld [$db4c], a
    ret


    xor a
    ld [$db53], a
    ld a, [wPLAN_selection]
    add a
    add a
    ld b, a
    ld a, [wOPTN_and_Item_selection]
    and $7f
    add b
    ld a, a
    ld [$db4c], a
    ld hl, wInventory
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$da5e], a
    ld hl, $0302
    rst $10
    ld a, [$db4c]
    ld [$da5f], a
    ld hl, $0308
    rst $10
    ld a, [$da5e]
    cp $ff
    jr nz, jr_054_53f5

    ld a, [$da65]
    cp $64
    jr z, jr_054_53f5

    ld a, $01
    ld [$db53], a
    call LoadB54_53f6
    ld hl, $5008
    rst $10

jr_054_53f5:
    ret


LoadB54_53f6:
    ld a, [$db8a]
    sub $af
    ld l, a
    ld h, $08
    ld de, $c190
    call SetupVRAMParams
    ret


    ld a, [$d9ee]
    rst $00
    dec d
    ld d, h
    jr nc, jr_054_5461

    ld d, [hl]
    ld d, h
    and a
    ld d, h
    ld [$7755], sp
    ld d, l
    ld a, [$c825]
    or a
    ret nz

    ld a, $04
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4c00
    rst $10
    call LoadB54_55a0
    ld hl, $d9ee
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$da33]
    or a
    jr z, jr_054_5440

    dec a
    ld [$da33], a
    ret


jr_054_5440:
    ld a, $04
    ld [$c822], a
    ld a, $01
    ld [$c823], a
    ld hl, $4c00
    rst $10
    call LoadB54_5591
    ld hl, $d9ee
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$da33]
    or a
    jr z, jr_054_5466

jr_054_5461:
    dec a
    ld [$da33], a
    ret


jr_054_5466:
    ld a, $04
    call CheckMonsterSlot
    jr c, jr_054_54a2

    ld de, $c180
    ld a, e
    ld [$db5e], a
    ld a, d
    ld [$db5f], a
    ld a, [$dc40]
    ld l, a
    ld h, $05
    call SetupVRAMParams
    ld a, [$dc40]
    ld [$d9ef], a
    ld hl, $ca94
    call TestBitInArray
    ld a, $02
    jr nz, jr_054_5493

    ld a, $03

jr_054_5493:
    ld [$c823], a
    ld a, $04
    ld [$c822], a
    ld hl, $4c00
    rst $10
    call LoadB54_5591

jr_054_54a2:
    ld hl, $d9ee
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$da33]
    or a
    jr z, jr_054_54b7

    dec a
    ld [$da33], a
    ret


jr_054_54b7:
    ld a, $05
    call CheckMonsterSlot
    jr c, jr_054_5503

    ld de, $c180
    ld a, e
    ld [$db5e], a
    ld a, d
    ld [$db5f], a
    ld a, [$dc41]
    ld l, a
    ld h, $05
    call SetupVRAMParams
    ld a, [$dc41]
    ld hl, $dc40
    cp [hl]
    jr nz, jr_054_54e2

    ld a, $04
    call CheckMonsterSlot
    jr nc, jr_054_5503

jr_054_54e2:
    ld [$d9f0], a
    ld a, [$dc41]
    ld hl, $ca94
    call TestBitInArray
    ld a, $02
    jr nz, jr_054_54f4

    ld a, $03

jr_054_54f4:
    ld [$c823], a
    ld a, $04
    ld [$c822], a
    ld hl, $4c00
    rst $10
    call LoadB54_5591

jr_054_5503:
    ld hl, $d9ee
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$da33]
    or a
    jr z, jr_054_5518

    dec a
    ld [$da33], a
    ret


jr_054_5518:
    ld a, $06
    call CheckMonsterSlot
    jr c, jr_054_5572

    ld de, $c180
    ld a, e
    ld [$db5e], a
    ld a, d
    ld [$db5f], a
    ld a, [$dc42]
    ld l, a
    ld h, $05
    call SetupVRAMParams
    ld a, [$dc42]
    ld hl, $dc40
    cp [hl]
    jr nz, jr_054_5543

    ld a, $04
    call CheckMonsterSlot
    jr nc, jr_054_5572

jr_054_5543:
    ld a, [$dc42]
    inc hl
    cp [hl]
    jr nz, jr_054_5551

    ld a, $05
    call CheckMonsterSlot
    jr nc, jr_054_5572

jr_054_5551:
    ld [$d9f1], a
    ld a, [$dc42]
    ld hl, $ca94
    call TestBitInArray
    ld a, $02
    jr nz, jr_054_5563

    ld a, $03

jr_054_5563:
    ld [$c823], a
    ld a, $04
    ld [$c822], a
    ld hl, $4c00
    rst $10
    call LoadB54_5591

jr_054_5572:
    ld hl, $d9ee
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$da33]
    or a
    jr z, jr_054_5587

    dec a
    ld [$da33], a
    ret


jr_054_5587:
    ld a, $0d
    ld [$d9ed], a
    xor a
    ld [$d9ee], a
    ret


LoadB54_5591:
    ld a, [wTextSpeed]
    cp $07
    jr z, jr_054_55b6

    inc a
    ld b, a
    ld a, $00
    ld c, $0a
    jr jr_054_55b0

LoadB54_55a0:
    ld a, [wTextSpeed]
    cp $07
    jr z, jr_054_55b6

    inc a
    ld b, a
    ld a, $20
    dec b
    jr z, jr_054_55b7

    ld c, $0a

jr_054_55b0:
    add c
    dec b
    jr nz, jr_054_55b0

    jr jr_054_55b7

jr_054_55b6:
    xor a

jr_054_55b7:
    ld [$da33], a
    ret


; JoinDecision — Entry 7: Determine if defeated monster joins party
; Called from post-battle state $0D in bank $50
    call GenerateRNG
    ld a, [$dd61]            ; defeated monster slot (0=none)
    or a
    jr z, jr_054_5609        ; no candidate → skip

    and $03                  ; slot index 0-3
    ld hl, wJoinability             ; per-enemy joinability table
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]               ; A = joinability flag for this slot
    ld [$db4d], a            ; save join tier
    cp $07                   ; $07 = non-joinable
    jr z, jr_054_5609        ; non-joinable → skip

    ld a, [$dd61]            ; get slot again
    ld hl, $dc3c             ; per-enemy species table
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]               ; A = species ID
    ld hl, $ca94             ; party/storage count
    call TestBitInArray        ; check capacity
    push af
    pop bc
    ld a, c
    ld [$db4c], a            ; save capacity flag
    push bc
    ld a, [$db83]            ; join RNG parameter low
    ld l, a
    ld a, [$db84]            ; join RNG parameter high
    ld h, a
    pop af
    jr nz, jr_054_5601       ; if party not full → standard join check

    call LoadB54_560e        ; party full → different join probability
    jr jr_054_5604

jr_054_5601:
    call LoadB54_5655        ; standard join probability check

jr_054_5604:
    call LoadB54_5683        ; process join result
    jr c, jr_054_560d        ; carry = joined successfully

jr_054_5609:
    ld hl, $d9ec             ; advance post-battle state
    inc [hl]

jr_054_560d:
    ret


LoadB54_560e:
    ld a, [$db4d]
    ld d, h
    ld e, l
    cp $01
    jr z, jr_054_562d

    cp $02
    jr z, jr_054_5632

    cp $03
    jr z, jr_054_5635

    cp $04
    jr z, jr_054_5637

    cp $05
    jr z, jr_054_563d

    cp $06
    jr z, jr_054_5644

    jr jr_054_5654

jr_054_562d:
    add hl, hl
    add hl, hl
    add hl, de
    jr jr_054_5654

jr_054_5632:
    add hl, hl
    jr jr_054_5654

jr_054_5635:
    jr jr_054_5654

jr_054_5637:
    srl h
    rr l
    jr jr_054_5654

jr_054_563d:
    ld a, $05
    call Div16x8To16
    jr jr_054_5654

jr_054_5644:
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l

jr_054_5654:
    ret


LoadB54_5655:
    ld a, [$db4d]
    or a
    jr z, jr_054_5682

    cp $03
    jr c, jr_054_566c

    cp $06
    jr c, jr_054_5676

    jr nz, jr_054_5682

    ld a, $14
    call Div16x8To16
    jr jr_054_5682

jr_054_566c:
    srl h
    rr l
    srl h
    rr l
    jr jr_054_5682

jr_054_5676:
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l

jr_054_5682:
    ret


LoadB54_5683:
    ld a, [$db4d]
    or a
    jr z, jr_054_56c5

    cp $07
    jr z, jr_054_56c7

    push hl
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, $5b
    call Div16x8To16
    add $0a
    ld c, a
    ld b, $00
    pop hl
    call CmpHLvsBC
    jr c, jr_054_56c7

    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, $64
    call Div16x8To16
    inc a
    ld c, a
    ld b, $00
    ld hl, $005a
    call CmpHLvsBC
    jr c, jr_054_56c7

jr_054_56c5:
    scf
    ret


jr_054_56c7:
    scf
    ccf
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
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
